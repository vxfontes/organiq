package repository

import "context"

// DailySummaryTokenRepo groups operations related to the public daily-summary token.
// Implemented by NotificationPreferencesRepository.
//
// We keep it here as explicit methods to avoid leaking full prefs where not needed.
type DailySummaryTokenRepo interface {
	GetDailySummaryTokenByUserID(ctx context.Context, userID string) (string, error)
	RotateDailySummaryToken(ctx context.Context, userID string) (string, error)
	FindUserIDByDailySummaryToken(ctx context.Context, token string) (string, error)
}
