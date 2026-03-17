package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type SubflagRepository interface {
	Create(ctx context.Context, subflag domain.Subflag) (domain.Subflag, error)
	Update(ctx context.Context, subflag domain.Subflag) (domain.Subflag, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.Subflag, error)
	GetByIDs(ctx context.Context, userID string, ids []string) ([]domain.Subflag, error)
	ListByFlag(ctx context.Context, userID, flagID string, opts ListOptions) ([]domain.Subflag, *string, error)
}
