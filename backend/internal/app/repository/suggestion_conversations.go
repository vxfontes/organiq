package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type SuggestionConversationRepository interface {
	Create(ctx context.Context, conversation domain.SuggestionConversation) (domain.SuggestionConversation, error)
	Get(ctx context.Context, userID, id string) (domain.SuggestionConversation, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.SuggestionConversation, *string, error)
	Touch(ctx context.Context, userID, id string) error
}
