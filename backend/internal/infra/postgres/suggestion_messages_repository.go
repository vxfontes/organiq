package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
)

type SuggestionMessageRepository struct {
	db dbtx
}

func NewSuggestionMessageRepository(db *DB) *SuggestionMessageRepository {
	return &SuggestionMessageRepository{db: db}
}

func NewSuggestionMessageRepositoryTx(tx *sql.Tx) *SuggestionMessageRepository {
	return &SuggestionMessageRepository{db: tx}
}

func (r *SuggestionMessageRepository) Create(ctx context.Context, message domain.SuggestionMessage) (domain.SuggestionMessage, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.suggestion_messages (conversation_id, role, content, structured_blocks)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`, message.ConversationID, string(message.Role), message.Content, nullableRawJSON(message.StructuredBlocks))

	if err := row.Scan(&message.ID, &message.CreatedAt); err != nil {
		return domain.SuggestionMessage{}, err
	}
	return message, nil
}

func (r *SuggestionMessageRepository) ListByConversation(ctx context.Context, userID, conversationID string) ([]domain.SuggestionMessage, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT m.id, m.conversation_id, m.role, m.content, m.structured_blocks, m.created_at
		FROM organiq.suggestion_messages m
		INNER JOIN organiq.suggestion_conversations c ON c.id = m.conversation_id
		WHERE m.conversation_id = $1 AND c.user_id = $2
		ORDER BY m.created_at ASC
	`, conversationID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.SuggestionMessage, 0)
	for rows.Next() {
		msg, err := scanSuggestionMessage(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, msg)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *SuggestionMessageRepository) ListRecentByConversation(ctx context.Context, userID, conversationID string, limit int) ([]domain.SuggestionMessage, error) {
	if limit <= 0 {
		limit = 20
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT m.id, m.conversation_id, m.role, m.content, m.structured_blocks, m.created_at
		FROM organiq.suggestion_messages m
		INNER JOIN organiq.suggestion_conversations c ON c.id = m.conversation_id
		WHERE m.conversation_id = $1 AND c.user_id = $2
		ORDER BY m.created_at DESC
		LIMIT $3
	`, conversationID, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.SuggestionMessage, 0)
	for rows.Next() {
		msg, err := scanSuggestionMessage(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, msg)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// The query is DESC by created_at to cheaply get the tail.
	for left, right := 0, len(items)-1; left < right; left, right = left+1, right-1 {
		items[left], items[right] = items[right], items[left]
	}

	return items, nil
}

type suggestionMessageScanner interface {
	Scan(dest ...any) error
}

func scanSuggestionMessage(scanner suggestionMessageScanner) (domain.SuggestionMessage, error) {
	var message domain.SuggestionMessage
	var role string
	var structuredBlocks []byte

	if err := scanner.Scan(&message.ID, &message.ConversationID, &role, &message.Content, &structuredBlocks, &message.CreatedAt); err != nil {
		return domain.SuggestionMessage{}, err
	}

	message.Role = domain.SuggestionMessageRole(role)
	if len(structuredBlocks) > 0 {
		message.StructuredBlocks = structuredBlocks
	}

	return message, nil
}

func nullableRawJSON(raw []byte) any {
	if len(raw) == 0 {
		return nil
	}
	// structured_blocks is a JSONB column; passing []byte would be sent as
	// bytea by the driver. Cast to string so Postgres can coerce text → jsonb.
	return string(raw)
}
