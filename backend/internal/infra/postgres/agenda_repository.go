package postgres

import (
	"context"
	"database/sql"

	"organiq/backend/internal/app/repository"
)

type AgendaRepository struct {
	db dbtx
}

func NewAgendaRepository(db *DB) *AgendaRepository {
	return &AgendaRepository{db: db}
}

func (r *AgendaRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]repository.AgendaItem, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, err
	}

	query := `
		SELECT item_type, id, user_id, title, description, status, scheduled_at,
		       due_at, remind_at, start_at, end_at, all_day, location,
		       flag_id, subflag_id, resolved_flag_id, flag_name, flag_color, subflag_name, subflag_color,
		       created_at, updated_at
		FROM organiq.view_agenda_consolidada
		WHERE user_id = $1
		  AND ($2::timestamptz IS NULL OR scheduled_at >= $2::timestamptz)
		  AND ($3::timestamptz IS NULL OR scheduled_at < $3::timestamptz)
		ORDER BY scheduled_at, created_at
		LIMIT $4 OFFSET $5
	`

	rows, err := r.db.QueryContext(ctx, query, userID, opts.StartAt, opts.EndAt, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]repository.AgendaItem, 0)
	for rows.Next() {
		var item repository.AgendaItem
		var description, location sql.NullString
		var dueAt, remindAt, startAt, endAt sql.NullTime
		var allDay sql.NullBool
		var flagID, subflagID, resolvedFlagID sql.NullString
		var flagName, flagColor, subflagName, subflagColor sql.NullString

		if err := rows.Scan(
			&item.ItemType, &item.ID, &item.UserID, &item.Title, &description, &item.Status, &item.ScheduledAt,
			&dueAt, &remindAt, &startAt, &endAt, &allDay, &location,
			&flagID, &subflagID, &resolvedFlagID, &flagName, &flagColor, &subflagName, &subflagColor,
			&item.CreatedAt, &item.UpdatedAt,
		); err != nil {
			return nil, err
		}

		item.Description = stringPtrFromNull(description)
		if dueAt.Valid {
			v := dueAt.Time
			item.DueAt = &v
		}
		if remindAt.Valid {
			v := remindAt.Time
			item.RemindAt = &v
		}
		if startAt.Valid {
			v := startAt.Time
			item.StartAt = &v
		}
		if endAt.Valid {
			v := endAt.Time
			item.EndAt = &v
		}
		if allDay.Valid {
			v := allDay.Bool
			item.AllDay = &v
		}
		item.Location = stringPtrFromNull(location)
		item.FlagID = stringPtrFromNull(flagID)
		item.SubflagID = stringPtrFromNull(subflagID)
		item.ResolvedFlagID = stringPtrFromNull(resolvedFlagID)
		item.FlagName = stringPtrFromNull(flagName)
		item.FlagColor = stringPtrFromNull(flagColor)
		item.SubflagName = stringPtrFromNull(subflagName)
		item.SubflagColor = stringPtrFromNull(subflagColor)

		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}
