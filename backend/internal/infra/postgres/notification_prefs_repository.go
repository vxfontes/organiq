package postgres

import (
	"context"
	"database/sql"
	"errors"

	"github.com/lib/pq"

	"inbota/backend/internal/app/domain"
)

type NotificationPreferencesRepository struct {
	db *DB
}

func NewNotificationPreferencesRepository(db *DB) *NotificationPreferencesRepository {
	return &NotificationPreferencesRepository{db: db}
}

func (r *NotificationPreferencesRepository) GetByUserID(ctx context.Context, userID string) (domain.NotificationPreferences, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, reminders_enabled, reminder_at_time, reminder_lead_mins,
			events_enabled, event_at_time, event_lead_mins,
			tasks_enabled, task_at_time, task_lead_mins,
			routines_enabled, routine_at_time, routine_lead_mins,
			quiet_hours_enabled, to_char(quiet_start, 'HH24:MI'), to_char(quiet_end, 'HH24:MI'),
			daily_digest_enabled, daily_digest_hour, daily_summary_token,
			created_at, updated_at
		FROM inbota.notification_preferences
		WHERE user_id = $1
		LIMIT 1
	`, userID)

	var prefs domain.NotificationPreferences
	var reminderLeadMins, eventLeadMins, taskLeadMins, routineLeadMins pq.Int64Array
	var quietStart, quietEnd sql.NullString

	err := row.Scan(
		&prefs.ID, &prefs.UserID, &prefs.RemindersEnabled, &prefs.ReminderAtTime, &reminderLeadMins,
		&prefs.EventsEnabled, &prefs.EventAtTime, &eventLeadMins,
		&prefs.TasksEnabled, &prefs.TaskAtTime, &taskLeadMins,
		&prefs.RoutinesEnabled, &prefs.RoutineAtTime, &routineLeadMins,
		&prefs.QuietHoursEnabled, &quietStart, &quietEnd,
		&prefs.DailyDigestEnabled, &prefs.DailyDigestHour, &prefs.DailySummaryToken,
		&prefs.CreatedAt, &prefs.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return domain.NotificationPreferences{}, ErrNotFound
		}
		return domain.NotificationPreferences{}, err
	}

	prefs.ReminderLeadMins = intArrayFromInt64Array(reminderLeadMins)
	prefs.EventLeadMins = intArrayFromInt64Array(eventLeadMins)
	prefs.TaskLeadMins = intArrayFromInt64Array(taskLeadMins)
	prefs.RoutineLeadMins = intArrayFromInt64Array(routineLeadMins)

	if quietStart.Valid {
		prefs.QuietStart = &quietStart.String
	}
	if quietEnd.Valid {
		prefs.QuietEnd = &quietEnd.String
	}

	return prefs, nil
}

func (r *NotificationPreferencesRepository) Upsert(ctx context.Context, prefs domain.NotificationPreferences) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO inbota.notification_preferences (
			user_id, reminders_enabled, reminder_at_time, reminder_lead_mins,
			events_enabled, event_at_time, event_lead_mins,
			tasks_enabled, task_at_time, task_lead_mins,
			routines_enabled, routine_at_time, routine_lead_mins,
			quiet_hours_enabled, quiet_start, quiet_end,
			daily_digest_enabled, daily_digest_hour, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, now())
		ON CONFLICT (user_id) DO UPDATE SET
			reminders_enabled = EXCLUDED.reminders_enabled,
			reminder_at_time = EXCLUDED.reminder_at_time,
			reminder_lead_mins = EXCLUDED.reminder_lead_mins,
			events_enabled = EXCLUDED.events_enabled,
			event_at_time = EXCLUDED.event_at_time,
			event_lead_mins = EXCLUDED.event_lead_mins,
			tasks_enabled = EXCLUDED.tasks_enabled,
			task_at_time = EXCLUDED.task_at_time,
			task_lead_mins = EXCLUDED.task_lead_mins,
			routines_enabled = EXCLUDED.routines_enabled,
			routine_at_time = EXCLUDED.routine_at_time,
			routine_lead_mins = EXCLUDED.routine_lead_mins,
			quiet_hours_enabled = EXCLUDED.quiet_hours_enabled,
			quiet_start = EXCLUDED.quiet_start,
			quiet_end = EXCLUDED.quiet_end,
			daily_digest_enabled = EXCLUDED.daily_digest_enabled,
			daily_digest_hour = EXCLUDED.daily_digest_hour,
			updated_at = now()
	`,
		prefs.UserID, prefs.RemindersEnabled, prefs.ReminderAtTime, pq.Array(prefs.ReminderLeadMins),
		prefs.EventsEnabled, prefs.EventAtTime, pq.Array(prefs.EventLeadMins),
		prefs.TasksEnabled, prefs.TaskAtTime, pq.Array(prefs.TaskLeadMins),
		prefs.RoutinesEnabled, prefs.RoutineAtTime, pq.Array(prefs.RoutineLeadMins),
		prefs.QuietHoursEnabled, prefs.QuietStart, prefs.QuietEnd,
		prefs.DailyDigestEnabled, prefs.DailyDigestHour,
	)
	return err
}

func (r *NotificationPreferencesRepository) ListEnabled(ctx context.Context) ([]domain.NotificationPreferences, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, reminders_enabled, reminder_at_time, reminder_lead_mins,
			events_enabled, event_at_time, event_lead_mins,
			tasks_enabled, task_at_time, task_lead_mins,
			routines_enabled, routine_at_time, routine_lead_mins,
			quiet_hours_enabled, to_char(quiet_start, 'HH24:MI'), to_char(quiet_end, 'HH24:MI'),
			daily_digest_enabled, daily_digest_hour, daily_summary_token,
			created_at, updated_at
		FROM inbota.notification_preferences
		WHERE daily_digest_enabled = true
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []domain.NotificationPreferences
	for rows.Next() {
		var prefs domain.NotificationPreferences
		var reminderLeadMins, eventLeadMins, taskLeadMins, routineLeadMins pq.Int64Array
		var quietStart, quietEnd sql.NullString

		err := rows.Scan(
			&prefs.ID, &prefs.UserID, &prefs.RemindersEnabled, &prefs.ReminderAtTime, &reminderLeadMins,
			&prefs.EventsEnabled, &prefs.EventAtTime, &eventLeadMins,
			&prefs.TasksEnabled, &prefs.TaskAtTime, &taskLeadMins,
			&prefs.RoutinesEnabled, &prefs.RoutineAtTime, &routineLeadMins,
			&prefs.QuietHoursEnabled, &quietStart, &quietEnd,
			&prefs.DailyDigestEnabled, &prefs.DailyDigestHour, &prefs.DailySummaryToken,
			&prefs.CreatedAt, &prefs.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		prefs.ReminderLeadMins = intArrayFromInt64Array(reminderLeadMins)
		prefs.EventLeadMins = intArrayFromInt64Array(eventLeadMins)
		prefs.TaskLeadMins = intArrayFromInt64Array(taskLeadMins)
		prefs.RoutineLeadMins = intArrayFromInt64Array(routineLeadMins)

		if quietStart.Valid {
			prefs.QuietStart = &quietStart.String
		}
		if quietEnd.Valid {
			prefs.QuietEnd = &quietEnd.String
		}
		results = append(results, prefs)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return results, nil
}

func intArrayFromInt64Array(a pq.Int64Array) []int {
	res := make([]int, len(a))
	for i, v := range a {
		res[i] = int(v)
	}
	return res
}
