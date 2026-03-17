package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type ContextRuleRepository struct {
	db dbtx
}

func NewContextRuleRepository(db *DB) *ContextRuleRepository {
	return &ContextRuleRepository{db: db}
}

func NewContextRuleRepositoryTx(tx *sql.Tx) *ContextRuleRepository {
	return &ContextRuleRepository{db: tx}
}

func (r *ContextRuleRepository) Create(ctx context.Context, rule domain.ContextRule) (domain.ContextRule, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.context_rules (user_id, keyword, flag_id, subflag_id)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, updated_at
	`, rule.UserID, rule.Keyword, rule.FlagID, rule.SubflagID)

	if err := row.Scan(&rule.ID, &rule.CreatedAt, &rule.UpdatedAt); err != nil {
		return domain.ContextRule{}, err
	}
	return rule, nil
}

func (r *ContextRuleRepository) Update(ctx context.Context, rule domain.ContextRule) (domain.ContextRule, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE organiq.context_rules
		SET keyword = $1, flag_id = $2, subflag_id = $3, updated_at = now()
		WHERE id = $4 AND user_id = $5
		RETURNING created_at, updated_at
	`, rule.Keyword, rule.FlagID, rule.SubflagID, rule.ID, rule.UserID)

	if err := row.Scan(&rule.CreatedAt, &rule.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.ContextRule{}, ErrNotFound
		}
		return domain.ContextRule{}, err
	}
	return rule, nil
}

func (r *ContextRuleRepository) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM organiq.context_rules
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

func (r *ContextRuleRepository) Get(ctx context.Context, userID, id string) (domain.ContextRule, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, keyword, flag_id, subflag_id, created_at, updated_at
		FROM organiq.context_rules
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var subflagID sql.NullString
	var rule domain.ContextRule
	if err := row.Scan(&rule.ID, &rule.UserID, &rule.Keyword, &rule.FlagID, &subflagID, &rule.CreatedAt, &rule.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.ContextRule{}, ErrNotFound
		}
		return domain.ContextRule{}, err
	}
	rule.SubflagID = stringPtrFromNull(subflagID)
	return rule, nil
}

func (r *ContextRuleRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.ContextRule, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, keyword, flag_id, subflag_id, created_at, updated_at
		FROM organiq.context_rules
		WHERE user_id = $1
		ORDER BY keyword ASC, created_at ASC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	rules := make([]domain.ContextRule, 0)
	for rows.Next() {
		var subflagID sql.NullString
		var rule domain.ContextRule
		if err := rows.Scan(&rule.ID, &rule.UserID, &rule.Keyword, &rule.FlagID, &subflagID, &rule.CreatedAt, &rule.UpdatedAt); err != nil {
			return nil, nil, err
		}
		rule.SubflagID = stringPtrFromNull(subflagID)
		rules = append(rules, rule)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(rules), limit)
	return rules, next, nil
}
