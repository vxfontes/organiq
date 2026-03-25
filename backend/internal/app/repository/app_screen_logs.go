package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type AppScreenLogRepository interface {
	Create(ctx context.Context, log domain.AppScreenLog) (domain.AppScreenLog, error)
}
