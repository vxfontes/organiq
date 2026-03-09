package mailer

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type ResendMailer struct {
	apiKey  string
	from    string
	baseURL string
	client  *http.Client
}

type resendRequest struct {
	From    string   `json:"from"`
	To      []string `json:"to"`
	Subject string   `json:"subject"`
	Html    string   `json:"html,omitempty"`
	Text    string   `json:"text,omitempty"`
}

type resendResponse struct {
	ID string `json:"id"`
}

type resendErrorResponse struct {
	Message string `json:"message"`
	Error   string `json:"error"`
}

func NewResendMailer(apiKey, from string) *ResendMailer {
	return NewResendMailerWithClient(apiKey, from, &http.Client{Timeout: 10 * time.Second})
}

func NewResendMailerWithClient(apiKey, from string, client *http.Client) *ResendMailer {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &ResendMailer{
		apiKey:  strings.TrimSpace(apiKey),
		from:    strings.TrimSpace(from),
		baseURL: "https://api.resend.com/emails",
		client:  client,
	}
}

func (m *ResendMailer) Send(ctx context.Context, req SendRequest) (string, error) {
	if m.apiKey == "" {
		return "", fmt.Errorf("resend api key is not configured")
	}
	if m.from == "" {
		return "", fmt.Errorf("resend from is not configured")
	}
	if len(req.To) == 0 {
		return "", fmt.Errorf("send request must have at least one recipient")
	}

	payload := resendRequest{
		From:    m.from,
		To:      req.To,
		Subject: req.Subject,
		Html:    req.Html,
		Text:    req.Text,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal resend request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, m.baseURL, bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("failed to create resend request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+m.apiKey)
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Accept", "application/json")

	resp, err := m.client.Do(httpReq)
	if err != nil {
		return "", fmt.Errorf("failed to send email via resend: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
		var apiErr resendErrorResponse
		if err := json.Unmarshal(respBody, &apiErr); err == nil {
			msg := strings.TrimSpace(apiErr.Message)
			if msg == "" {
				msg = strings.TrimSpace(apiErr.Error)
			}
			if msg != "" {
				return "", fmt.Errorf("resend error status=%d message=%s", resp.StatusCode, msg)
			}
		}
		return "", fmt.Errorf("resend error status=%d body=%s", resp.StatusCode, strings.TrimSpace(string(respBody)))
	}

	var res resendResponse
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return "", fmt.Errorf("failed to decode resend response: %w", err)
	}
	if strings.TrimSpace(res.ID) == "" {
		return "", fmt.Errorf("resend response did not include message id")
	}

	return res.ID, nil
}
