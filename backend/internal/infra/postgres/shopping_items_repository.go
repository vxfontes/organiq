package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type ShoppingItemRepository struct {
	db dbtx
}

func NewShoppingItemRepository(db *DB) *ShoppingItemRepository {
	return &ShoppingItemRepository{db: db}
}

func NewShoppingItemRepositoryTx(tx *sql.Tx) *ShoppingItemRepository {
	return &ShoppingItemRepository{db: tx}
}

func (r *ShoppingItemRepository) Create(ctx context.Context, item domain.ShoppingItem) (domain.ShoppingItem, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.shopping_items (user_id, list_id, title, quantity, checked, sort_order)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`, item.UserID, item.ListID, item.Title, item.Quantity, item.Checked, item.SortOrder)

	if err := row.Scan(&item.ID, &item.CreatedAt, &item.UpdatedAt); err != nil {
		return domain.ShoppingItem{}, err
	}
	return item, nil
}

func (r *ShoppingItemRepository) Update(ctx context.Context, item domain.ShoppingItem) (domain.ShoppingItem, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE organiq.shopping_items
		SET title = $1, quantity = $2, checked = $3, sort_order = $4, updated_at = now()
		WHERE id = $5 AND user_id = $6
		RETURNING created_at, updated_at
	`, item.Title, item.Quantity, item.Checked, item.SortOrder, item.ID, item.UserID)

	if err := row.Scan(&item.CreatedAt, &item.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.ShoppingItem{}, ErrNotFound
		}
		return domain.ShoppingItem{}, err
	}
	return item, nil
}

func (r *ShoppingItemRepository) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM organiq.shopping_items
		WHERE id = $1 AND user_id = $2
	`, id, userID)
	if err != nil {
		return err
	}

	affected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if affected == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *ShoppingItemRepository) Get(ctx context.Context, userID, id string) (domain.ShoppingItem, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, list_id, title, quantity, checked, sort_order, created_at, updated_at
		FROM organiq.shopping_items
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var quantity sql.NullString
	var item domain.ShoppingItem
	if err := row.Scan(&item.ID, &item.UserID, &item.ListID, &item.Title, &quantity, &item.Checked, &item.SortOrder, &item.CreatedAt, &item.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.ShoppingItem{}, ErrNotFound
		}
		return domain.ShoppingItem{}, err
	}
	item.Quantity = stringPtrFromNull(quantity)
	return item, nil
}

func (r *ShoppingItemRepository) ListByList(ctx context.Context, userID, listID string, opts repository.ListOptions) ([]domain.ShoppingItem, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, list_id, title, quantity, checked, sort_order, created_at, updated_at
		FROM organiq.shopping_items
		WHERE user_id = $1 AND list_id = $2
		ORDER BY sort_order ASC, created_at ASC
		LIMIT $3 OFFSET $4
	`, userID, listID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.ShoppingItem, 0)
	for rows.Next() {
		var quantity sql.NullString
		var item domain.ShoppingItem
		if err := rows.Scan(&item.ID, &item.UserID, &item.ListID, &item.Title, &quantity, &item.Checked, &item.SortOrder, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, nil, err
		}
		item.Quantity = stringPtrFromNull(quantity)
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}
