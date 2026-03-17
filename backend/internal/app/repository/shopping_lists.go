package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type ShoppingListRepository interface {
	Create(ctx context.Context, list domain.ShoppingList) (domain.ShoppingList, error)
	Update(ctx context.Context, list domain.ShoppingList) (domain.ShoppingList, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.ShoppingList, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.ShoppingList, *string, error)
}
