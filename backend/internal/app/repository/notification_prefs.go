package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type NotificationPreferencesRepository interface {
	GetByUserID(ctx context.Context, userID string) (domain.NotificationPreferences, error)
	Upsert(ctx context.Context, prefs domain.NotificationPreferences) error
	ListEnabled(ctx context.Context) ([]domain.NotificationPreferences, error)

	// Public daily-summary token helpers
	GetDailySummaryTokenByUserID(ctx context.Context, userID string) (string, error)
	RotateDailySummaryToken(ctx context.Context, userID string) (string, error)
	FindUserIDByDailySummaryToken(ctx context.Context, token string) (string, error)
}
