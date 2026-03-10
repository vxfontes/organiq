package postgres

import (
	"context"
	"time"

	"inbota/backend/internal/app/domain"
)

type NotificationLogRepository struct {
	db *DB
}

func NewNotificationLogRepository(db *DB) *NotificationLogRepository {
	return &NotificationLogRepository{db: db}
}

func (r *NotificationLogRepository) Create(ctx context.Context, log domain.NotificationLog) (domain.NotificationLog, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO inbota.notification_log (user_id, type, reference_id, title, body, lead_mins, status, scheduled_for)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at
	`, log.UserID, log.Type, log.ReferenceID, log.Title, log.Body, log.LeadMins, log.Status, log.ScheduledFor)

	if err := row.Scan(&log.ID, &log.CreatedAt); err != nil {
		return domain.NotificationLog{}, err
	}
	return log, nil
}

func (r *NotificationLogRepository) ListPending(ctx context.Context, scheduledBefore time.Time) ([]domain.NotificationLog, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, type, reference_id, title, body, lead_mins, status, scheduled_for, sent_at, read_at, error_msg, created_at
		FROM inbota.notification_log
		WHERE status = 'pending' AND scheduled_for <= $1
	`, scheduledBefore)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var logs []domain.NotificationLog
	for rows.Next() {
		var l domain.NotificationLog
		if err := rows.Scan(&l.ID, &l.UserID, &l.Type, &l.ReferenceID, &l.Title, &l.Body, &l.LeadMins, &l.Status, &l.ScheduledFor, &l.SentAt, &l.ReadAt, &l.ErrorMsg, &l.CreatedAt); err != nil {
			return nil, err
		}
		logs = append(logs, l)
	}
	return logs, rows.Err()
}

func (r *NotificationLogRepository) UpdateStatus(ctx context.Context, id string, status domain.NotificationStatus, errorMsg *string) error {
	var sentAt *time.Time
	if status == domain.NotificationStatusSent {
		now := time.Now()
		sentAt = &now
	}
	_, err := r.db.ExecContext(ctx, `
		UPDATE inbota.notification_log
		SET status = $1, error_msg = $2, sent_at = $3
		WHERE id = $4
	`, status, errorMsg, sentAt, id)
	return err
}

func (r *NotificationLogRepository) ListByUserID(ctx context.Context, userID string, limit, offset int) ([]domain.NotificationLog, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, type, reference_id, title, body, lead_mins, status, scheduled_for, sent_at, read_at, error_msg, created_at
		FROM inbota.notification_log
		WHERE user_id = $1
		  AND status IN ('sent', 'delivered', 'read')
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var logs []domain.NotificationLog
	for rows.Next() {
		var l domain.NotificationLog
		if err := rows.Scan(&l.ID, &l.UserID, &l.Type, &l.ReferenceID, &l.Title, &l.Body, &l.LeadMins, &l.Status, &l.ScheduledFor, &l.SentAt, &l.ReadAt, &l.ErrorMsg, &l.CreatedAt); err != nil {
			return nil, err
		}
		logs = append(logs, l)
	}
	return logs, nil
}

func (r *NotificationLogRepository) MarkAsRead(ctx context.Context, id, userID string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE inbota.notification_log
		SET read_at = now(), status = 'read'
		WHERE id = $1 AND user_id = $2
	`, id, userID)
	return err
}

func (r *NotificationLogRepository) MarkAllAsRead(ctx context.Context, userID string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE inbota.notification_log
		SET read_at = now(), status = 'read'
		WHERE user_id = $1 AND read_at IS NULL
	`, userID)
	return err
}

func (r *NotificationLogRepository) Exists(ctx context.Context, referenceID string, leadMins *int) (bool, error) {
	var exists bool
	err := r.db.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM inbota.notification_log
			WHERE reference_id = $1 AND (lead_mins = $2 OR (lead_mins IS NULL AND $2 IS NULL))
			AND status IN ('pending', 'sent', 'delivered')
		)
	`, referenceID, leadMins).Scan(&exists)
	return exists, err
}

func (r *NotificationLogRepository) UpdateScheduledFor(ctx context.Context, id string, scheduledFor time.Time) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE inbota.notification_log
		SET scheduled_for = $1, status = 'pending'
		WHERE id = $2
	`, scheduledFor, id)
	return err
}
