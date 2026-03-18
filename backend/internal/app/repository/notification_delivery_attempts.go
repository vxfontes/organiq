package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type NotificationDeliveryAttemptRepository interface {
	Create(ctx context.Context, attempt domain.NotificationDeliveryAttempt) (domain.NotificationDeliveryAttempt, error)
	ListByUserID(ctx context.Context, userID string, notificationLogID *string, limit, offset int) ([]domain.NotificationDeliveryAttempt, error)
}
