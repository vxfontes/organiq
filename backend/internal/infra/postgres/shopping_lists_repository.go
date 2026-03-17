package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type ShoppingListRepository struct {
	db dbtx
}

func NewShoppingListRepository(db *DB) *ShoppingListRepository {
	return &ShoppingListRepository{db: db}
}

func NewShoppingListRepositoryTx(tx *sql.Tx) *ShoppingListRepository {
	return &ShoppingListRepository{db: tx}
}

func (r *ShoppingListRepository) Create(ctx context.Context, list domain.ShoppingList) (domain.ShoppingList, error) {
	if list.Status == "" {
		list.Status = domain.ShoppingListStatusOpen
	}

	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.shopping_lists (user_id, title, status, source_inbox_item_id)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, updated_at
	`, list.UserID, list.Title, string(list.Status), list.SourceInboxItemID)

	if err := row.Scan(&list.ID, &list.CreatedAt, &list.UpdatedAt); err != nil {
		return domain.ShoppingList{}, err
	}
	return list, nil
}

func (r *ShoppingListRepository) Update(ctx context.Context, list domain.ShoppingList) (domain.ShoppingList, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE organiq.shopping_lists
		SET title = $1, status = $2, updated_at = now()
		WHERE id = $3 AND user_id = $4
		RETURNING created_at, updated_at
	`, list.Title, string(list.Status), list.ID, list.UserID)

	if err := row.Scan(&list.CreatedAt, &list.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.ShoppingList{}, ErrNotFound
		}
		return domain.ShoppingList{}, err
	}
	return list, nil
}

func (r *ShoppingListRepository) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM organiq.shopping_lists
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

func (r *ShoppingListRepository) Get(ctx context.Context, userID, id string) (domain.ShoppingList, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, title, status, source_inbox_item_id, created_at, updated_at
		FROM organiq.shopping_lists
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var sourceInboxID sql.NullString
	var status string
	var list domain.ShoppingList
	if err := row.Scan(&list.ID, &list.UserID, &list.Title, &status, &sourceInboxID, &list.CreatedAt, &list.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.ShoppingList{}, ErrNotFound
		}
		return domain.ShoppingList{}, err
	}
	list.Status = domain.ShoppingListStatus(status)
	list.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
	return list, nil
}

func (r *ShoppingListRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.ShoppingList, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, status, source_inbox_item_id, created_at, updated_at
		FROM organiq.shopping_lists
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.ShoppingList, 0)
	for rows.Next() {
		var sourceInboxID sql.NullString
		var status string
		var list domain.ShoppingList
		if err := rows.Scan(&list.ID, &list.UserID, &list.Title, &status, &sourceInboxID, &list.CreatedAt, &list.UpdatedAt); err != nil {
			return nil, nil, err
		}
		list.Status = domain.ShoppingListStatus(status)
		list.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
		items = append(items, list)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}
