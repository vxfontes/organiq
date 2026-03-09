package postgres

import (
	"context"
	"database/sql"
	"fmt"

	"inbota/backend/internal/app/domain"
)

type EmailDigestRepository struct {
	db *DB
}

func NewEmailDigestRepository(db *DB) *EmailDigestRepository {
	return &EmailDigestRepository{db: db}
}

func (r *EmailDigestRepository) Create(ctx context.Context, digest *domain.EmailDigest) (bool, error) {
	if digest == nil {
		return false, fmt.Errorf("digest is nil")
	}

	const query = `
		INSERT INTO inbota.email_digests (user_id, digest_date, type, status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, now(), now())
		ON CONFLICT (user_id, digest_date, type) DO UPDATE
		SET status = 'pending',
		    sent_at = NULL,
		    error_msg = NULL,
		    provider_id = NULL,
		    updated_at = now()
		WHERE inbota.email_digests.status = 'failed'
		RETURNING id, created_at, updated_at
	`

	err := r.db.QueryRowContext(
		ctx,
		query,
		digest.UserID,
		digest.DigestDate.Format("2006-01-02"),
		digest.Type,
		digest.Status,
	).Scan(&digest.ID, &digest.CreatedAt, &digest.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return false, nil
		}
		return false, fmt.Errorf("create email digest: %w", err)
	}

	return true, nil
}

func (r *EmailDigestRepository) Update(ctx context.Context, digest *domain.EmailDigest) error {
	if digest == nil {
		return fmt.Errorf("digest is nil")
	}
	if digest.ID == "" {
		return fmt.Errorf("digest id is required")
	}

	const query = `
		UPDATE inbota.email_digests
		SET status = $1, sent_at = $2, error_msg = $3, provider_id = $4, updated_at = now()
		WHERE id = $5
	`

	_, err := r.db.ExecContext(ctx, query, digest.Status, digest.SentAt, digest.ErrorMsg, digest.ProviderID, digest.ID)
	if err != nil {
		return fmt.Errorf("update email digest: %w", err)
	}

	return nil
}
