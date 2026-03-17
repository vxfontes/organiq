package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type AiSuggestionRepository interface {
	Create(ctx context.Context, suggestion domain.AiSuggestion) (domain.AiSuggestion, error)
	GetLatestByInboxItem(ctx context.Context, userID, inboxItemID string) (domain.AiSuggestion, error)
	ListByInboxItem(ctx context.Context, userID, inboxItemID string, opts ListOptions) ([]domain.AiSuggestion, *string, error)
}
