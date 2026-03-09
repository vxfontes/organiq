package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type DeviceTokenRepository interface {
	Upsert(ctx context.Context, token domain.DeviceToken) error
	Delete(ctx context.Context, token, userID string) error
	ListByUserID(ctx context.Context, userID string) ([]domain.DeviceToken, error)
	Deactivate(ctx context.Context, token string) error
}
