package usecase

import (
	"context"
	"encoding/json"
	"strings"

	"organiq/backend/internal/app/repository"
)

const (
	appConfigKeyAICreateEnabled     = "ai.create.enabled"
	appConfigKeyAISuggestionEnabled = "ai.suggestion.enabled"
	appConfigKeySettingsAdminEmails = "settings.notifications.admin_emails"
)

type AIConfig struct {
	CreateEnabled       bool
	SuggestionEnabled   bool
	SettingsAdminEmails []string
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
		CreateEnabled:       parseConfigBool(values[appConfigKeyAICreateEnabled], true),
		SuggestionEnabled:   parseConfigBool(values[appConfigKeyAISuggestionEnabled], true),
		SettingsAdminEmails: parseConfigEmailList(values[appConfigKeySettingsAdminEmails]),
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

func parseConfigEmailList(raw string) []string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return []string{}
	}

	values := make([]string, 0)
	if strings.HasPrefix(trimmed, "[") && strings.HasSuffix(trimmed, "]") {
		var parsed []string
		if err := json.Unmarshal([]byte(trimmed), &parsed); err == nil {
			values = append(values, parsed...)
		}
	}

	if len(values) == 0 {
		normalized := strings.NewReplacer(";", ",", "\n", ",", "\r", ",").Replace(trimmed)
		values = strings.Split(normalized, ",")
	}

	seen := make(map[string]struct{}, len(values))
	out := make([]string, 0, len(values))
	for _, value := range values {
		email := strings.ToLower(strings.TrimSpace(value))
		if email == "" || !strings.Contains(email, "@") {
			continue
		}
		if _, ok := seen[email]; ok {
			continue
		}
		seen[email] = struct{}{}
		out = append(out, email)
	}
	return out
}
