package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type AppErrorLogRepository interface {
	Create(ctx context.Context, log domain.AppErrorLog) (domain.AppErrorLog, error)
}
