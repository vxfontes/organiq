package repository

import (
	"context"
	"time"

	"organiq/backend/internal/app/domain"
)

type NotificationLogRepository interface {
	Create(ctx context.Context, log domain.NotificationLog) (domain.NotificationLog, error)
	ListPending(ctx context.Context, scheduledBefore time.Time) ([]domain.NotificationLog, error)
	UpdateStatus(ctx context.Context, id string, status domain.NotificationStatus, errorMsg *string) error
	ListByUserID(ctx context.Context, userID string, limit, offset int) ([]domain.NotificationLog, error)
	MarkAsRead(ctx context.Context, id, userID string) error
	MarkAllAsRead(ctx context.Context, userID string) error
	Exists(ctx context.Context, referenceID string, leadMins *int) (bool, error)
	UpdateScheduledFor(ctx context.Context, id string, scheduledFor time.Time) error
}
