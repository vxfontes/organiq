package service

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

var ErrAIProviderNotConfigured = errors.New("ai_provider_not_configured")
var ErrAIInvalidResponse = errors.New("ai_invalid_response")

// AIClient performs LLM requests.
type AIClient interface {
	Complete(ctx context.Context, prompt string) (AICompletion, error)
}

type AIClientWithFallback interface {
	AIClient
	CompleteWithModel(ctx context.Context, prompt, model string) (AICompletion, error)
	FallbackModel() string
	FallbackOnNeedsReview() bool
}

// AICompletion holds the raw text returned by the provider.
type AICompletion struct {
	Content string
	Model   string
	Raw     json.RawMessage
}

type AIClientConfig struct {
	Provider              string
	BaseURL               string
	APIKey                string
	FallbackAPIKey        string
	Model                 string
	FallbackModel         string
	FallbackOnNeedsReview bool
	Timeout               time.Duration
	MaxRetries            int
}

type HTTPAIClient struct {
	provider              string
	baseURL               string
	apiKeys               []string
	model                 string
	fallbackModel         string
	fallbackOnNeedsReview bool
	maxRetries            int
	client                *http.Client
}

func NewHTTPAIClient(cfg AIClientConfig) (*HTTPAIClient, error) {
	if cfg.BaseURL == "" {
		return nil, ErrAIProviderNotConfigured
	}
	apiKeys := uniqueNonEmptyStrings(cfg.APIKey, cfg.FallbackAPIKey)
	if len(apiKeys) == 0 {
		return nil, ErrAIProviderNotConfigured
	}
	if cfg.Model == "" {
		return nil, errors.New("ai_model_required")
	}
	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = 15 * time.Second
	}
	maxRetries := cfg.MaxRetries
	if maxRetries < 0 {
		maxRetries = 0
	}
	return &HTTPAIClient{
		provider:              cfg.Provider,
		baseURL:               cfg.BaseURL,
		apiKeys:               apiKeys,
		model:                 cfg.Model,
		fallbackModel:         strings.TrimSpace(cfg.FallbackModel),
		fallbackOnNeedsReview: cfg.FallbackOnNeedsReview,
		maxRetries:            maxRetries,
		client:                &http.Client{Timeout: timeout},
	}, nil
}

func (c *HTTPAIClient) Complete(ctx context.Context, prompt string) (AICompletion, error) {
	return c.complete(ctx, prompt, c.model)
}

func (c *HTTPAIClient) CompleteWithModel(ctx context.Context, prompt, model string) (AICompletion, error) {
	model = strings.TrimSpace(model)
	if model == "" {
		model = c.model
	}
	return c.complete(ctx, prompt, model)
}

func (c *HTTPAIClient) FallbackModel() string {
	return c.fallbackModel
}

func (c *HTTPAIClient) FallbackOnNeedsReview() bool {
	return c.fallbackOnNeedsReview
}

func (c *HTTPAIClient) complete(ctx context.Context, prompt, model string) (AICompletion, error) {
	var lastErr error
	for _, apiKey := range c.apiKeys {
		completion, err := c.completeWithAPIKey(ctx, prompt, model, apiKey)
		if err == nil {
			return completion, nil
		}
		lastErr = err
		// If caller context is done, do not keep trying secondary keys.
		if ctx.Err() != nil {
			return AICompletion{}, err
		}
	}

	if lastErr == nil {
		lastErr = ErrAIInvalidResponse
	}
	return AICompletion{}, lastErr
}

func (c *HTTPAIClient) completeWithAPIKey(ctx context.Context, prompt, model, apiKey string) (AICompletion, error) {
	payload := chatCompletionRequest{
		Model: model,
		Messages: []chatMessage{
			{
				Role: "system",
				Content: "You are a strict JSON extractor. " +
					"Reply with only valid JSON (object or array) and no extra text.",
			},
			{Role: "user", Content: prompt},
		},
		Temperature: 0,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return AICompletion{}, err
	}

	var lastErr error
	for attempt := 0; attempt <= c.maxRetries; attempt++ {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL, bytes.NewReader(body))
		if err != nil {
			return AICompletion{}, err
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+apiKey)

		resp, err := c.client.Do(req)
		if err != nil {
			lastErr = err
			if attempt < c.maxRetries {
				backoff(attempt)
				continue
			}
			return AICompletion{}, err
		}

		respBody, readErr := io.ReadAll(resp.Body)
		_ = resp.Body.Close()
		if readErr != nil {
			lastErr = readErr
			if attempt < c.maxRetries {
				backoff(attempt)
				continue
			}
			return AICompletion{}, readErr
		}

		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			lastErr = fmt.Errorf("ai_http_status_%d", resp.StatusCode)
			if attempt < c.maxRetries && resp.StatusCode >= 500 {
				backoff(attempt)
				continue
			}
			return AICompletion{}, lastErr
		}

		completion, err := decodeChatCompletion(respBody)
		if err != nil {
			return AICompletion{}, err
		}
		return completion, nil
	}

	if lastErr == nil {
		lastErr = ErrAIInvalidResponse
	}
	return AICompletion{}, lastErr
}

func uniqueNonEmptyStrings(values ...string) []string {
	if len(values) == 0 {
		return nil
	}
	seen := make(map[string]struct{}, len(values))
	out := make([]string, 0, len(values))
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		if _, ok := seen[trimmed]; ok {
			continue
		}
		seen[trimmed] = struct{}{}
		out = append(out, trimmed)
	}
	return out
}

type chatCompletionRequest struct {
	Model       string        `json:"model"`
	Messages    []chatMessage `json:"messages"`
	Temperature float64       `json:"temperature"`
}

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatCompletionResponse struct {
	Model   string `json:"model"`
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

func decodeChatCompletion(raw []byte) (AICompletion, error) {
	var resp chatCompletionResponse
	if err := json.Unmarshal(raw, &resp); err != nil {
		return AICompletion{}, err
	}
	if len(resp.Choices) == 0 {
		return AICompletion{}, ErrAIInvalidResponse
	}
	content := resp.Choices[0].Message.Content
	if content == "" {
		return AICompletion{}, ErrAIInvalidResponse
	}
	return AICompletion{Content: content, Model: resp.Model, Raw: raw}, nil
}

func backoff(attempt int) {
	if attempt <= 0 {
		return
	}
	base := 200 * time.Millisecond
	sleep := time.Duration(attempt*attempt) * base
	if sleep > 2*time.Second {
		sleep = 2 * time.Second
	}
	time.Sleep(sleep)
}
