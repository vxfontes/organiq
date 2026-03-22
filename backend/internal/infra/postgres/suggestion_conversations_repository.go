package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type SuggestionConversationRepository struct {
	db dbtx
}

func NewSuggestionConversationRepository(db *DB) *SuggestionConversationRepository {
	return &SuggestionConversationRepository{db: db}
}

func NewSuggestionConversationRepositoryTx(tx *sql.Tx) *SuggestionConversationRepository {
	return &SuggestionConversationRepository{db: tx}
}

func (r *SuggestionConversationRepository) Create(ctx context.Context, conversation domain.SuggestionConversation) (domain.SuggestionConversation, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.suggestion_conversations (user_id)
		VALUES ($1)
		RETURNING id, created_at, updated_at
	`, conversation.UserID)

	if err := row.Scan(&conversation.ID, &conversation.CreatedAt, &conversation.UpdatedAt); err != nil {
		return domain.SuggestionConversation{}, err
	}
	return conversation, nil
}

func (r *SuggestionConversationRepository) Get(ctx context.Context, userID, id string) (domain.SuggestionConversation, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, created_at, updated_at
		FROM organiq.suggestion_conversations
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var conversation domain.SuggestionConversation
	if err := row.Scan(&conversation.ID, &conversation.UserID, &conversation.CreatedAt, &conversation.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.SuggestionConversation{}, ErrNotFound
		}
		return domain.SuggestionConversation{}, err
	}
	return conversation, nil
}

func (r *SuggestionConversationRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.SuggestionConversation, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, created_at, updated_at
		FROM organiq.suggestion_conversations
		WHERE user_id = $1
		ORDER BY updated_at DESC, created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.SuggestionConversation, 0)
	for rows.Next() {
		var item domain.SuggestionConversation
		if err := rows.Scan(&item.ID, &item.UserID, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, nil, err
		}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}

func (r *SuggestionConversationRepository) Touch(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		UPDATE organiq.suggestion_conversations
		SET updated_at = now()
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
