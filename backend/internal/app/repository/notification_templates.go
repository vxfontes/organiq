package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type NotificationTemplateRepository interface {
	GetAll(ctx context.Context) ([]domain.NotificationTemplate, error)
}
