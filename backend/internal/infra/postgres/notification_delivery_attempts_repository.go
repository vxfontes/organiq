package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/domain"
)

type NotificationDeliveryAttemptRepository struct {
	db *DB
}

func NewNotificationDeliveryAttemptRepository(db *DB) *NotificationDeliveryAttemptRepository {
	return &NotificationDeliveryAttemptRepository{db: db}
}

func (r *NotificationDeliveryAttemptRepository) Create(ctx context.Context, attempt domain.NotificationDeliveryAttempt) (domain.NotificationDeliveryAttempt, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.notification_delivery_attempts (
			notification_log_id, user_id, device_id, provider, attempt_no, status, error_code, error_message
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at
	`,
		attempt.NotificationLogID,
		attempt.UserID,
		attempt.DeviceID,
		attempt.Provider,
		attempt.AttemptNo,
		attempt.Status,
		attempt.ErrorCode,
		attempt.ErrorMessage,
	)

	if err := row.Scan(&attempt.ID, &attempt.CreatedAt); err != nil {
		return domain.NotificationDeliveryAttempt{}, err
	}

	return attempt, nil
}

func (r *NotificationDeliveryAttemptRepository) ListByUserID(
	ctx context.Context,
	userID string,
	notificationLogID *string,
	limit, offset int,
) ([]domain.NotificationDeliveryAttempt, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, notification_log_id, user_id, device_id, provider, attempt_no, status, error_code, error_message, created_at
		FROM organiq.notification_delivery_attempts
		WHERE user_id = $1
		  AND ($2::uuid IS NULL OR notification_log_id = $2::uuid)
		ORDER BY created_at DESC, id DESC
		LIMIT $3 OFFSET $4
	`, userID, notificationLogID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []domain.NotificationDeliveryAttempt
	for rows.Next() {
		var item domain.NotificationDeliveryAttempt
		var notificationLogIDRaw sql.NullString
		var errorCodeRaw sql.NullString
		var errorMessageRaw sql.NullString

		if err := rows.Scan(
			&item.ID,
			&notificationLogIDRaw,
			&item.UserID,
			&item.DeviceID,
			&item.Provider,
			&item.AttemptNo,
			&item.Status,
			&errorCodeRaw,
			&errorMessageRaw,
			&item.CreatedAt,
		); err != nil {
			return nil, err
		}

		if notificationLogIDRaw.Valid {
			item.NotificationLogID = &notificationLogIDRaw.String
		}
		if errorCodeRaw.Valid {
			item.ErrorCode = &errorCodeRaw.String
		}
		if errorMessageRaw.Valid {
			item.ErrorMessage = &errorMessageRaw.String
		}

		out = append(out, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	return out, nil
}
