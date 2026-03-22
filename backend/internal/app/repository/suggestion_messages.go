package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type SuggestionMessageRepository interface {
	Create(ctx context.Context, message domain.SuggestionMessage) (domain.SuggestionMessage, error)
	ListByConversation(ctx context.Context, userID, conversationID string) ([]domain.SuggestionMessage, error)
	ListRecentByConversation(ctx context.Context, userID, conversationID string, limit int) ([]domain.SuggestionMessage, error)
}
