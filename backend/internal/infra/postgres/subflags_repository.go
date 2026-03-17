package postgres

import (
	"context"
	"database/sql"

	"github.com/lib/pq"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type SubflagRepository struct {
	db dbtx
}

func NewSubflagRepository(db *DB) *SubflagRepository {
	return &SubflagRepository{db: db}
}

func NewSubflagRepositoryTx(tx *sql.Tx) *SubflagRepository {
	return &SubflagRepository{db: tx}
}

func (r *SubflagRepository) Create(ctx context.Context, subflag domain.Subflag) (domain.Subflag, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.subflags (user_id, flag_id, name, sort_order)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, updated_at
	`, subflag.UserID, subflag.FlagID, subflag.Name, subflag.SortOrder)

	if err := row.Scan(&subflag.ID, &subflag.CreatedAt, &subflag.UpdatedAt); err != nil {
		return domain.Subflag{}, err
	}
	return subflag, nil
}

func (r *SubflagRepository) Update(ctx context.Context, subflag domain.Subflag) (domain.Subflag, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE organiq.subflags
		SET name = $1, sort_order = $2, updated_at = now()
		WHERE id = $3 AND user_id = $4
		RETURNING created_at, updated_at
	`, subflag.Name, subflag.SortOrder, subflag.ID, subflag.UserID)

	if err := row.Scan(&subflag.CreatedAt, &subflag.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Subflag{}, ErrNotFound
		}
		return domain.Subflag{}, err
	}
	return subflag, nil
}

func (r *SubflagRepository) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM organiq.subflags
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

func (r *SubflagRepository) Get(ctx context.Context, userID, id string) (domain.Subflag, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, flag_id, name, sort_order, created_at, updated_at
		FROM organiq.subflags
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var subflag domain.Subflag
	if err := row.Scan(&subflag.ID, &subflag.UserID, &subflag.FlagID, &subflag.Name, &subflag.SortOrder, &subflag.CreatedAt, &subflag.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Subflag{}, ErrNotFound
		}
		return domain.Subflag{}, err
	}
	return subflag, nil
}

func (r *SubflagRepository) GetByIDs(ctx context.Context, userID string, ids []string) ([]domain.Subflag, error) {
	if len(ids) == 0 {
		return []domain.Subflag{}, nil
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, flag_id, name, sort_order, created_at, updated_at
		FROM organiq.subflags
		WHERE user_id = $1 AND id = ANY($2)
	`, userID, pq.Array(ids))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	subflags := make([]domain.Subflag, 0)
	for rows.Next() {
		var subflag domain.Subflag
		if err := rows.Scan(&subflag.ID, &subflag.UserID, &subflag.FlagID, &subflag.Name, &subflag.SortOrder, &subflag.CreatedAt, &subflag.UpdatedAt); err != nil {
			return nil, err
		}
		subflags = append(subflags, subflag)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return subflags, nil
}

func (r *SubflagRepository) ListByFlag(ctx context.Context, userID, flagID string, opts repository.ListOptions) ([]domain.Subflag, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, flag_id, name, sort_order, created_at, updated_at
		FROM organiq.subflags
		WHERE user_id = $1 AND flag_id = $2
		ORDER BY sort_order ASC, created_at ASC
		LIMIT $3 OFFSET $4
	`, userID, flagID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	subflags := make([]domain.Subflag, 0)
	for rows.Next() {
		var subflag domain.Subflag
		if err := rows.Scan(&subflag.ID, &subflag.UserID, &subflag.FlagID, &subflag.Name, &subflag.SortOrder, &subflag.CreatedAt, &subflag.UpdatedAt); err != nil {
			return nil, nil, err
		}
		subflags = append(subflags, subflag)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(subflags), limit)
	return subflags, next, nil
}
