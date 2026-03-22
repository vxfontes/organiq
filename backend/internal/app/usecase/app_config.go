package usecase

import (
	"context"
	"strings"

	"organiq/backend/internal/app/repository"
)

const (
	appConfigKeyAICreateEnabled     = "ai.create.enabled"
	appConfigKeyAISuggestionEnabled = "ai.suggestion.enabled"
)

type AIConfig struct {
	CreateEnabled     bool
	SuggestionEnabled bool
}

type AppConfigUsecase struct {
	Config repository.AppConfigRepository
}

func (uc *AppConfigUsecase) GetAIConfig(ctx context.Context) (AIConfig, error) {
	if uc == nil || uc.Config == nil {
		return AIConfig{}, ErrDependencyMissing
	}

	values, err := uc.Config.GetAll(ctx)
	if err != nil {
		return AIConfig{}, err
	}

	return AIConfig{
		CreateEnabled:     parseConfigBool(values[appConfigKeyAICreateEnabled], true),
		SuggestionEnabled: parseConfigBool(values[appConfigKeyAISuggestionEnabled], true),
	}, nil
}

func parseConfigBool(raw string, fallback bool) bool {
	value := strings.ToLower(strings.TrimSpace(raw))
	switch value {
	case "1", "true", "yes", "y", "on":
		return true
	case "0", "false", "no", "n", "off":
		return false
	default:
		return fallback
	}
}
