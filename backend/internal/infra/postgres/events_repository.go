package postgres

import (
	"context"
	"database/sql"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type EventRepository struct {
	db dbtx
}

func NewEventRepository(db *DB) *EventRepository {
	return &EventRepository{db: db}
}

func NewEventRepositoryTx(tx *sql.Tx) *EventRepository {
	return &EventRepository{db: tx}
}

func (r *EventRepository) Create(ctx context.Context, event domain.Event) (domain.Event, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO inbota.events (user_id, title, start_at, end_at, all_day, location, flag_id, subflag_id, source_inbox_item_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, created_at, updated_at
	`, event.UserID, event.Title, event.StartAt, event.EndAt, event.AllDay, event.Location, event.FlagID, event.SubflagID, event.SourceInboxItemID)

	if err := row.Scan(&event.ID, &event.CreatedAt, &event.UpdatedAt); err != nil {
		return domain.Event{}, err
	}
	return event, nil
}

func (r *EventRepository) Update(ctx context.Context, event domain.Event) (domain.Event, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE inbota.events
		SET title = $1, start_at = $2, end_at = $3, all_day = $4, location = $5, flag_id = $6, subflag_id = $7, updated_at = now()
		WHERE id = $8 AND user_id = $9
		RETURNING created_at, updated_at
	`, event.Title, event.StartAt, event.EndAt, event.AllDay, event.Location, event.FlagID, event.SubflagID, event.ID, event.UserID)

	if err := row.Scan(&event.CreatedAt, &event.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Event{}, ErrNotFound
		}
		return domain.Event{}, err
	}
	return event, nil
}

func (r *EventRepository) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM inbota.events
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

func (r *EventRepository) Get(ctx context.Context, userID, id string) (domain.Event, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, title, start_at, end_at, all_day, location, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM inbota.events
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var startAt sql.NullTime
	var endAt sql.NullTime
	var location sql.NullString
	var flagID sql.NullString
	var subflagID sql.NullString
	var sourceInboxID sql.NullString
	var event domain.Event
	if err := row.Scan(&event.ID, &event.UserID, &event.Title, &startAt, &endAt, &event.AllDay, &location, &flagID, &subflagID, &sourceInboxID, &event.CreatedAt, &event.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Event{}, ErrNotFound
		}
		return domain.Event{}, err
	}
	event.StartAt = timePtrFromNull(startAt)
	event.EndAt = timePtrFromNull(endAt)
	event.Location = stringPtrFromNull(location)
	event.FlagID = stringPtrFromNull(flagID)
	event.SubflagID = stringPtrFromNull(subflagID)
	event.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
	return event, nil
}

func (r *EventRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Event, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, start_at, end_at, all_day, location, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM inbota.events
		WHERE user_id = $1
		ORDER BY start_at NULLS LAST, created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.Event, 0)
	for rows.Next() {
		var startAt sql.NullTime
		var endAt sql.NullTime
		var location sql.NullString
		var flagID sql.NullString
		var subflagID sql.NullString
		var sourceInboxID sql.NullString
		var event domain.Event
		if err := rows.Scan(&event.ID, &event.UserID, &event.Title, &startAt, &endAt, &event.AllDay, &location, &flagID, &subflagID, &sourceInboxID, &event.CreatedAt, &event.UpdatedAt); err != nil {
			return nil, nil, err
		}
		event.StartAt = timePtrFromNull(startAt)
		event.EndAt = timePtrFromNull(endAt)
		event.Location = stringPtrFromNull(location)
		event.FlagID = stringPtrFromNull(flagID)
		event.SubflagID = stringPtrFromNull(subflagID)
		event.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
		items = append(items, event)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}

func (r *EventRepository) ListUpcoming(ctx context.Context, start, end time.Time) ([]domain.Event, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, start_at, end_at, all_day, location, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM inbota.events
		WHERE start_at >= $1 AND start_at <= $2
	`, start, end)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.Event, 0)
	for rows.Next() {
		var startAt sql.NullTime
		var endAt sql.NullTime
		var location sql.NullString
		var flagID sql.NullString
		var subflagID sql.NullString
		var sourceInboxID sql.NullString
		var event domain.Event
		if err := rows.Scan(&event.ID, &event.UserID, &event.Title, &startAt, &endAt, &event.AllDay, &location, &flagID, &subflagID, &sourceInboxID, &event.CreatedAt, &event.UpdatedAt); err != nil {
			return nil, err
		}
		event.StartAt = timePtrFromNull(startAt)
		event.EndAt = timePtrFromNull(endAt)
		event.Location = stringPtrFromNull(location)
		event.FlagID = stringPtrFromNull(flagID)
		event.SubflagID = stringPtrFromNull(subflagID)
		event.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
		items = append(items, event)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}
