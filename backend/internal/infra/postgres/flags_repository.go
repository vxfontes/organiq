package postgres

import (
	"context"
	"database/sql"

	"github.com/lib/pq"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type FlagRepository struct {
	db dbtx
}

func NewFlagRepository(db *DB) *FlagRepository {
	return &FlagRepository{db: db}
}

func NewFlagRepositoryTx(tx *sql.Tx) *FlagRepository {
	return &FlagRepository{db: tx}
}

func (r *FlagRepository) Create(ctx context.Context, flag domain.Flag) (domain.Flag, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.flags (user_id, name, color, sort_order)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, updated_at
	`, flag.UserID, flag.Name, flag.Color, flag.SortOrder)

	if err := row.Scan(&flag.ID, &flag.CreatedAt, &flag.UpdatedAt); err != nil {
		return domain.Flag{}, err
	}
	return flag, nil
}

func (r *FlagRepository) Update(ctx context.Context, flag domain.Flag) (domain.Flag, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE organiq.flags
		SET name = $1, color = $2, sort_order = $3, updated_at = now()
		WHERE id = $4 AND user_id = $5
		RETURNING created_at, updated_at
	`, flag.Name, flag.Color, flag.SortOrder, flag.ID, flag.UserID)

	if err := row.Scan(&flag.CreatedAt, &flag.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Flag{}, ErrNotFound
		}
		return domain.Flag{}, err
	}
	return flag, nil
}

func (r *FlagRepository) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM organiq.flags
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

func (r *FlagRepository) Get(ctx context.Context, userID, id string) (domain.Flag, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, name, color, sort_order, created_at, updated_at
		FROM organiq.flags
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var color sql.NullString
	var flag domain.Flag
	if err := row.Scan(&flag.ID, &flag.UserID, &flag.Name, &color, &flag.SortOrder, &flag.CreatedAt, &flag.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Flag{}, ErrNotFound
		}
		return domain.Flag{}, err
	}
	flag.Color = stringPtrFromNull(color)
	return flag, nil
}

func (r *FlagRepository) GetByIDs(ctx context.Context, userID string, ids []string) ([]domain.Flag, error) {
	if len(ids) == 0 {
		return []domain.Flag{}, nil
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, name, color, sort_order, created_at, updated_at
		FROM organiq.flags
		WHERE user_id = $1 AND id = ANY($2)
	`, userID, pq.Array(ids))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	flags := make([]domain.Flag, 0)
	for rows.Next() {
		var color sql.NullString
		var flag domain.Flag
		if err := rows.Scan(&flag.ID, &flag.UserID, &flag.Name, &color, &flag.SortOrder, &flag.CreatedAt, &flag.UpdatedAt); err != nil {
			return nil, err
		}
		flag.Color = stringPtrFromNull(color)
		flags = append(flags, flag)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return flags, nil
}

func (r *FlagRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Flag, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, name, color, sort_order, created_at, updated_at
		FROM organiq.flags
		WHERE user_id = $1
		ORDER BY sort_order ASC, created_at ASC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	flags := make([]domain.Flag, 0)
	for rows.Next() {
		var color sql.NullString
		var flag domain.Flag
		if err := rows.Scan(&flag.ID, &flag.UserID, &flag.Name, &color, &flag.SortOrder, &flag.CreatedAt, &flag.UpdatedAt); err != nil {
			return nil, nil, err
		}
		flag.Color = stringPtrFromNull(color)
		flags = append(flags, flag)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(flags), limit)
	return flags, next, nil
}
