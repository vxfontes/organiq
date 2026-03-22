package ai

import (
	"errors"
	"strings"

	"organiq/backend/internal/app/service"
	"organiq/backend/internal/config"
)

const (
	ProviderGroq       = "groq"
	defaultGroqBaseURL = "https://api.groq.com/openai/v1/chat/completions"
)

var ErrUnsupportedProvider = errors.New("ai_provider_unsupported")

// NewClient builds an AI client based on config.
func NewClient(cfg config.Config) (service.AIClient, error) {
	return newClient(service.AIClientConfig{
		Provider:              cfg.AIProvider,
		BaseURL:               cfg.AIBaseURL,
		APIKey:                cfg.AIAPIKey,
		Model:                 cfg.AIModel,
		FallbackModel:         cfg.AIFallbackModel,
		FallbackOnNeedsReview: cfg.AIFallbackOnNeedsReview,
		Timeout:               cfg.AITimeout,
		MaxRetries:            cfg.AIMaxRetries,
	})
}

// NewSuggestionClient builds the dedicated AI client for conversational suggestions.
func NewSuggestionClient(cfg config.Config) (service.AIClient, error) {
	return newClient(service.AIClientConfig{
		Provider:              cfg.SuggestionAIProvider,
		BaseURL:               cfg.SuggestionAIBaseURL,
		APIKey:                cfg.SuggestionAIAPIKey,
		Model:                 cfg.SuggestionAIModel,
		FallbackModel:         cfg.SuggestionAIFallbackModel,
		FallbackOnNeedsReview: cfg.SuggestionAIFallbackOnReview,
		Timeout:               cfg.SuggestionAITimeout,
		MaxRetries:            cfg.SuggestionAIMaxRetries,
	})
}

func newClient(clientCfg service.AIClientConfig) (service.AIClient, error) {
	provider := strings.ToLower(strings.TrimSpace(clientCfg.Provider))
	if provider == "" {
		provider = ProviderGroq
	}

	switch provider {
	case ProviderGroq:
		baseURL := normalizeBaseURL(clientCfg.BaseURL)
		if baseURL == "" {
			baseURL = defaultGroqBaseURL
		}
		return service.NewHTTPAIClient(service.AIClientConfig{
			Provider:              provider,
			BaseURL:               baseURL,
			APIKey:                clientCfg.APIKey,
			Model:                 clientCfg.Model,
			FallbackModel:         clientCfg.FallbackModel,
			FallbackOnNeedsReview: clientCfg.FallbackOnNeedsReview,
			Timeout:               clientCfg.Timeout,
			MaxRetries:            clientCfg.MaxRetries,
		})
	default:
		return nil, ErrUnsupportedProvider
	}
}

func normalizeBaseURL(value string) string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return ""
	}
	trimmed = strings.TrimRight(trimmed, "/")
	if strings.HasSuffix(trimmed, "/chat/completions") {
		return trimmed
	}
	if strings.HasSuffix(trimmed, "/openai/v1") || strings.HasSuffix(trimmed, "/v1") {
		return trimmed + "/chat/completions"
	}
	return trimmed
}
