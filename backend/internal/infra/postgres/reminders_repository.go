package postgres

import (
	"context"
	"database/sql"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type ReminderRepository struct {
	db dbtx
}

func NewReminderRepository(db *DB) *ReminderRepository {
	return &ReminderRepository{db: db}
}

func NewReminderRepositoryTx(tx *sql.Tx) *ReminderRepository {
	return &ReminderRepository{db: tx}
}

func (r *ReminderRepository) Create(ctx context.Context, reminder domain.Reminder) (domain.Reminder, error) {
	if reminder.Status == "" {
		reminder.Status = domain.ReminderStatusOpen
	}

	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.reminders (user_id, title, status, remind_at, flag_id, subflag_id, source_inbox_item_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`, reminder.UserID, reminder.Title, string(reminder.Status), reminder.RemindAt, reminder.FlagID, reminder.SubflagID, reminder.SourceInboxItemID)

	if err := row.Scan(&reminder.ID, &reminder.CreatedAt, &reminder.UpdatedAt); err != nil {
		return domain.Reminder{}, err
	}
	return reminder, nil
}

func (r *ReminderRepository) Update(ctx context.Context, reminder domain.Reminder) (domain.Reminder, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE organiq.reminders
		SET title = $1, status = $2, remind_at = $3, flag_id = $4, subflag_id = $5, updated_at = now()
		WHERE id = $6 AND user_id = $7
		RETURNING created_at, updated_at
	`, reminder.Title, string(reminder.Status), reminder.RemindAt, reminder.FlagID, reminder.SubflagID, reminder.ID, reminder.UserID)

	if err := row.Scan(&reminder.CreatedAt, &reminder.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Reminder{}, ErrNotFound
		}
		return domain.Reminder{}, err
	}
	return reminder, nil
}

func (r *ReminderRepository) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM organiq.reminders
		WHERE id = $1 AND user_id = $2
	`, id, userID)
	if err != nil {
		return err
	}

	affected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if affected == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *ReminderRepository) Get(ctx context.Context, userID, id string) (domain.Reminder, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, title, status, remind_at, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM organiq.reminders
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var remindAt sql.NullTime
	var flagID sql.NullString
	var subflagID sql.NullString
	var sourceInboxID sql.NullString
	var status string
	var reminder domain.Reminder
	if err := row.Scan(&reminder.ID, &reminder.UserID, &reminder.Title, &status, &remindAt, &flagID, &subflagID, &sourceInboxID, &reminder.CreatedAt, &reminder.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Reminder{}, ErrNotFound
		}
		return domain.Reminder{}, err
	}
	reminder.Status = domain.ReminderStatus(status)
	reminder.RemindAt = timePtrFromNull(remindAt)
	reminder.FlagID = stringPtrFromNull(flagID)
	reminder.SubflagID = stringPtrFromNull(subflagID)
	reminder.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
	return reminder, nil
}

func (r *ReminderRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Reminder, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, status, remind_at, notification_title, notification_body, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM organiq.reminders
		WHERE user_id = $1
		ORDER BY remind_at NULLS LAST, created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.Reminder, 0)
	for rows.Next() {
		var remindAt sql.NullTime
		var notifTitle, notifBody sql.NullString
		var flagID sql.NullString
		var subflagID sql.NullString
		var sourceInboxID sql.NullString
		var status string
		var reminder domain.Reminder
		if err := rows.Scan(&reminder.ID, &reminder.UserID, &reminder.Title, &status, &remindAt, &notifTitle, &notifBody, &flagID, &subflagID, &sourceInboxID, &reminder.CreatedAt, &reminder.UpdatedAt); err != nil {
			return nil, nil, err
		}
		reminder.Status = domain.ReminderStatus(status)
		reminder.RemindAt = timePtrFromNull(remindAt)
		reminder.NotificationTitle = stringPtrFromNull(notifTitle)
		reminder.NotificationBody = stringPtrFromNull(notifBody)
		reminder.FlagID = stringPtrFromNull(flagID)
		reminder.SubflagID = stringPtrFromNull(subflagID)
		reminder.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
		items = append(items, reminder)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}

func (r *ReminderRepository) ListUpcoming(ctx context.Context, start, end time.Time) ([]domain.Reminder, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, status, remind_at, notification_title, notification_body, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM organiq.reminders
		WHERE status = 'OPEN' AND remind_at >= $1 AND remind_at <= $2
	`, start, end)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.Reminder, 0)
	for rows.Next() {
		var remindAt sql.NullTime
		var notifTitle sql.NullString
		var notifBody sql.NullString
		var flagID sql.NullString
		var subflagID sql.NullString
		var sourceInboxID sql.NullString
		var status string
		var reminder domain.Reminder
		if err := rows.Scan(&reminder.ID, &reminder.UserID, &reminder.Title, &status, &remindAt, &notifTitle, &notifBody, &flagID, &subflagID, &sourceInboxID, &reminder.CreatedAt, &reminder.UpdatedAt); err != nil {
			return nil, err
		}
		reminder.Status = domain.ReminderStatus(status)
		reminder.RemindAt = timePtrFromNull(remindAt)
		reminder.NotificationTitle = stringPtrFromNull(notifTitle)
		reminder.NotificationBody = stringPtrFromNull(notifBody)
		reminder.FlagID = stringPtrFromNull(flagID)
		reminder.SubflagID = stringPtrFromNull(subflagID)
		reminder.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
		items = append(items, reminder)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

func (r *ReminderRepository) UpdateNotificationCopy(ctx context.Context, id, title, body string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE organiq.reminders 
		SET notification_title = $1, notification_body = $2, updated_at = now() 
		WHERE id = $3
	`, title, body, id)
	return err
}
