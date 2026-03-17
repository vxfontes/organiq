package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type ContextRuleRepository interface {
	Create(ctx context.Context, rule domain.ContextRule) (domain.ContextRule, error)
	Update(ctx context.Context, rule domain.ContextRule) (domain.ContextRule, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.ContextRule, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.ContextRule, *string, error)
}
