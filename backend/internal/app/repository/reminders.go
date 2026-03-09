package repository

import (
	"context"
	"time"

	"inbota/backend/internal/app/domain"
)

type ReminderRepository interface {
	Create(ctx context.Context, reminder domain.Reminder) (domain.Reminder, error)
	Update(ctx context.Context, reminder domain.Reminder) (domain.Reminder, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.Reminder, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.Reminder, *string, error)
	ListUpcoming(ctx context.Context, start, end time.Time) ([]domain.Reminder, error)
}
