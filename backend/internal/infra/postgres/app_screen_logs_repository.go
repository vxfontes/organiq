package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
)

type AppScreenLogRepository struct {
	db dbtx
}

func NewAppScreenLogRepository(db *DB) *AppScreenLogRepository {
	return &AppScreenLogRepository{db: db}
}

func NewAppScreenLogRepositoryTx(tx *sql.Tx) *AppScreenLogRepository {
	return &AppScreenLogRepository{db: tx}
}

func (r *AppScreenLogRepository) Create(
	ctx context.Context,
	log domain.AppScreenLog,
) (domain.AppScreenLog, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.app_screen_logs
			(user_id, session_id, screen_name, route_path, previous_route_path, event_name, platform, app_version, metadata, occurred_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, created_at
	`, log.UserID, log.SessionID, log.ScreenName, log.RoutePath, log.PreviousRoutePath, log.EventName, log.Platform, log.AppVersion, log.Metadata, log.OccurredAt)

	if err := row.Scan(&log.ID, &log.CreatedAt); err != nil {
		return domain.AppScreenLog{}, err
	}
	return log, nil
}
