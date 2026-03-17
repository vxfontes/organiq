package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type AiSuggestionRepository struct {
	db dbtx
}

func NewAiSuggestionRepository(db *DB) *AiSuggestionRepository {
	return &AiSuggestionRepository{db: db}
}

func NewAiSuggestionRepositoryTx(tx *sql.Tx) *AiSuggestionRepository {
	return &AiSuggestionRepository{db: tx}
}

func (r *AiSuggestionRepository) Create(ctx context.Context, suggestion domain.AiSuggestion) (domain.AiSuggestion, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.ai_suggestions
		(user_id, inbox_item_id, type, title, confidence, flag_id, subflag_id, needs_review, payload_json)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, created_at
	`, suggestion.UserID, suggestion.InboxItemID, string(suggestion.Type), suggestion.Title, suggestion.Confidence, suggestion.FlagID, suggestion.SubflagID, suggestion.NeedsReview, suggestion.PayloadJSON)

	if err := row.Scan(&suggestion.ID, &suggestion.CreatedAt); err != nil {
		return domain.AiSuggestion{}, err
	}
	return suggestion, nil
}

func (r *AiSuggestionRepository) GetLatestByInboxItem(ctx context.Context, userID, inboxItemID string) (domain.AiSuggestion, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, inbox_item_id, type, title, confidence, flag_id, subflag_id, needs_review, payload_json, created_at
		FROM organiq.ai_suggestions
		WHERE user_id = $1 AND inbox_item_id = $2
		ORDER BY created_at DESC
		LIMIT 1
	`, userID, inboxItemID)

	var suggestion domain.AiSuggestion
	var confidence sql.NullFloat64
	var flagID sql.NullString
	var subflagID sql.NullString
	var payload []byte
	var suggestionType string
	if err := row.Scan(&suggestion.ID, &suggestion.UserID, &suggestion.InboxItemID, &suggestionType, &suggestion.Title, &confidence, &flagID, &subflagID, &suggestion.NeedsReview, &payload, &suggestion.CreatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.AiSuggestion{}, ErrNotFound
		}
		return domain.AiSuggestion{}, err
	}
	suggestion.Type = domain.AiSuggestionType(suggestionType)
	suggestion.Confidence = floatPtrFromNull(confidence)
	suggestion.FlagID = stringPtrFromNull(flagID)
	suggestion.SubflagID = stringPtrFromNull(subflagID)
	suggestion.PayloadJSON = payload
	return suggestion, nil
}

func (r *AiSuggestionRepository) ListByInboxItem(ctx context.Context, userID, inboxItemID string, opts repository.ListOptions) ([]domain.AiSuggestion, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, inbox_item_id, type, title, confidence, flag_id, subflag_id, needs_review, payload_json, created_at
		FROM organiq.ai_suggestions
		WHERE user_id = $1 AND inbox_item_id = $2
		ORDER BY created_at DESC
		LIMIT $3 OFFSET $4
	`, userID, inboxItemID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.AiSuggestion, 0)
	for rows.Next() {
		var suggestion domain.AiSuggestion
		var confidence sql.NullFloat64
		var flagID sql.NullString
		var subflagID sql.NullString
		var payload []byte
		var suggestionType string
		if err := rows.Scan(&suggestion.ID, &suggestion.UserID, &suggestion.InboxItemID, &suggestionType, &suggestion.Title, &confidence, &flagID, &subflagID, &suggestion.NeedsReview, &payload, &suggestion.CreatedAt); err != nil {
			return nil, nil, err
		}
		suggestion.Type = domain.AiSuggestionType(suggestionType)
		suggestion.Confidence = floatPtrFromNull(confidence)
		suggestion.FlagID = stringPtrFromNull(flagID)
		suggestion.SubflagID = stringPtrFromNull(subflagID)
		suggestion.PayloadJSON = payload
		items = append(items, suggestion)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}
