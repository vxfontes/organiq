package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type DeviceTokenRepository interface {
	Upsert(ctx context.Context, dt domain.DeviceToken) error
	Delete(ctx context.Context, deviceID, userID string) error
	ListByUserID(ctx context.Context, userID string) ([]domain.DeviceToken, error)
	Deactivate(ctx context.Context, topic string) error
}
