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
	provider := strings.ToLower(strings.TrimSpace(cfg.AIProvider))
	if provider == "" {
		provider = ProviderGroq
	}

	switch provider {
	case ProviderGroq:
		baseURL := normalizeBaseURL(cfg.AIBaseURL)
		if baseURL == "" {
			baseURL = defaultGroqBaseURL
		}
		return service.NewHTTPAIClient(service.AIClientConfig{
			Provider:              provider,
			BaseURL:               baseURL,
			APIKey:                cfg.AIAPIKey,
			Model:                 cfg.AIModel,
			FallbackModel:         cfg.AIFallbackModel,
			FallbackOnNeedsReview: cfg.AIFallbackOnNeedsReview,
			Timeout:               cfg.AITimeout,
			MaxRetries:            cfg.AIMaxRetries,
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
