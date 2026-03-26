package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
)

type AppErrorLogRepository struct {
	db dbtx
}

func NewAppErrorLogRepository(db *DB) *AppErrorLogRepository {
	return &AppErrorLogRepository{db: db}
}

func NewAppErrorLogRepositoryTx(tx *sql.Tx) *AppErrorLogRepository {
	return &AppErrorLogRepository{db: tx}
}

func (r *AppErrorLogRepository) Create(
	ctx context.Context,
	log domain.AppErrorLog,
) (domain.AppErrorLog, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.app_error_logs
			(user_id, session_id, screen_name, route_path, source, error_code, message, stack_trace, request_id, request_path, request_method, http_status, metadata, occurred_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		RETURNING id, created_at
	`, log.UserID, log.SessionID, log.ScreenName, log.RoutePath, log.Source, log.ErrorCode, log.Message, log.StackTrace, log.RequestID, log.RequestPath, log.RequestMethod, log.HTTPStatus, log.Metadata, log.OccurredAt)

	if err := row.Scan(&log.ID, &log.CreatedAt); err != nil {
		return domain.AppErrorLog{}, err
	}
	return log, nil
}
