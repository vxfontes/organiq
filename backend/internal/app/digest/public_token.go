package digest

import (
	"context"
	"fmt"
	"strings"

	"inbota/backend/internal/infra/postgres"
)

func (s *DigestService) ResolveUserIDByDailySummaryToken(ctx context.Context, token string) (string, error) {
	token = strings.TrimSpace(token)
	if token == "" {
		return "", fmt.Errorf("missing_token")
	}

	userID, err := s.notifPrefsRepo.FindUserIDByDailySummaryToken(ctx, token)
	if err != nil {
		if err == postgres.ErrNotFound {
			return "", postgres.ErrNotFound
		}
		return "", err
	}
	return userID, nil
}
