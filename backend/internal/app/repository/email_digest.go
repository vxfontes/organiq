package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type EmailDigestRepository interface {
	Create(ctx context.Context, digest *domain.EmailDigest) (created bool, err error)
	Update(ctx context.Context, digest *domain.EmailDigest) error
}
