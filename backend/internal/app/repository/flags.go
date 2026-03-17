package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type FlagRepository interface {
	Create(ctx context.Context, flag domain.Flag) (domain.Flag, error)
	Update(ctx context.Context, flag domain.Flag) (domain.Flag, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.Flag, error)
	GetByIDs(ctx context.Context, userID string, ids []string) ([]domain.Flag, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.Flag, *string, error)
}
