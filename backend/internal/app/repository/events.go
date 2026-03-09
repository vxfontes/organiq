package repository

import (
	"context"
	"time"

	"inbota/backend/internal/app/domain"
)

type EventRepository interface {
	Create(ctx context.Context, event domain.Event) (domain.Event, error)
	Update(ctx context.Context, event domain.Event) (domain.Event, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.Event, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.Event, *string, error)
	ListUpcoming(ctx context.Context, start, end time.Time) ([]domain.Event, error)
}
