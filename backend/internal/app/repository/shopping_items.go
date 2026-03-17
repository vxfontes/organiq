package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type ShoppingItemRepository interface {
	Create(ctx context.Context, item domain.ShoppingItem) (domain.ShoppingItem, error)
	Update(ctx context.Context, item domain.ShoppingItem) (domain.ShoppingItem, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.ShoppingItem, error)
	ListByList(ctx context.Context, userID, listID string, opts ListOptions) ([]domain.ShoppingItem, *string, error)
}
