package repository

import (
	"context"
	"time"

	"inbota/backend/internal/app/domain"
)

type TaskRepository interface {
	Create(ctx context.Context, task domain.Task) (domain.Task, error)
	Update(ctx context.Context, task domain.Task) (domain.Task, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.Task, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.Task, *string, error)
	ListUpcoming(ctx context.Context, start, end time.Time) ([]domain.Task, error)
}
