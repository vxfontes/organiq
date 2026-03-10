package postgres

import (
	"context"
	"database/sql"

	"github.com/lib/pq"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type RoutineRepositoryImpl struct {
	db dbtx
}

func NewRoutineRepository(db *DB) *RoutineRepositoryImpl {
	return &RoutineRepositoryImpl{db: db}
}

func NewRoutineRepositoryTx(tx *sql.Tx) *RoutineRepositoryImpl {
	return &RoutineRepositoryImpl{db: tx}
}

func (r *RoutineRepositoryImpl) Create(ctx context.Context, routine domain.Routine) (domain.Routine, error) {
	if routine.RecurrenceType == "" {
		routine.RecurrenceType = "weekly"
	}

	row := r.db.QueryRowContext(ctx, `
		INSERT INTO inbota.routines (user_id, title, description, recurrence_type, weekdays, start_time, end_time, week_of_month, starts_on, ends_on, color, is_active, flag_id, subflag_id, source_inbox_item_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
		RETURNING id, created_at, updated_at
	`, routine.UserID, routine.Title, routine.Description, routine.RecurrenceType, pq.Array(routine.Weekdays), routine.StartTime, nullStringFromStr(routine.EndTime), routine.WeekOfMonth, routine.StartsOn, routine.EndsOn, routine.Color, routine.IsActive, routine.FlagID, routine.SubflagID, routine.SourceInboxItemID)

	if err := row.Scan(&routine.ID, &routine.CreatedAt, &routine.UpdatedAt); err != nil {
		return domain.Routine{}, err
	}
	return routine, nil
}

func (r *RoutineRepositoryImpl) Update(ctx context.Context, routine domain.Routine) (domain.Routine, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE inbota.routines
		SET title = $1, description = $2, recurrence_type = $3, weekdays = $4, start_time = $5, end_time = $6, week_of_month = $7, starts_on = $8, ends_on = $9, color = $10, is_active = $11, flag_id = $12, subflag_id = $13, updated_at = now()
		WHERE id = $14 AND user_id = $15
		RETURNING created_at, updated_at
	`, routine.Title, routine.Description, routine.RecurrenceType, pq.Array(routine.Weekdays), routine.StartTime, nullStringFromStr(routine.EndTime), routine.WeekOfMonth, routine.StartsOn, routine.EndsOn, routine.Color, routine.IsActive, routine.FlagID, routine.SubflagID, routine.ID, routine.UserID)

	if err := row.Scan(&routine.CreatedAt, &routine.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Routine{}, ErrNotFound
		}
		return domain.Routine{}, err
	}
	return routine, nil
}

func (r *RoutineRepositoryImpl) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM inbota.routines
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

func (r *RoutineRepositoryImpl) Get(ctx context.Context, userID, id string) (domain.Routine, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, title, description, recurrence_type, weekdays,
			to_char(start_time, 'HH24:MI') as start_time,
			to_char(end_time, 'HH24:MI') as end_time,
			week_of_month, starts_on, ends_on, color, is_active, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM inbota.routines
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var routine domain.Routine
	var description, endTime, endsOn, color, flagID, subflagID, sourceInboxItemID sql.NullString
	var weekOfMonth sql.NullInt64
	var weekdays pq.Int64Array

	if err := row.Scan(&routine.ID, &routine.UserID, &routine.Title, &description, &routine.RecurrenceType, &weekdays, &routine.StartTime, &endTime, &weekOfMonth, &routine.StartsOn, &endsOn, &color, &routine.IsActive, &flagID, &subflagID, &sourceInboxItemID, &routine.CreatedAt, &routine.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Routine{}, ErrNotFound
		}
		return domain.Routine{}, err
	}

	routine.Description = stringPtrFromNull(description)
	if endTime.Valid {
		routine.EndTime = endTime.String
	} else {
		routine.EndTime = routine.StartTime
	}
	if weekOfMonth.Valid {
		v := int(weekOfMonth.Int64)
		routine.WeekOfMonth = &v
	}
	routine.EndsOn = stringPtrFromNull(endsOn)
	routine.Color = stringPtrFromNull(color)
	routine.FlagID = stringPtrFromNull(flagID)
	routine.SubflagID = stringPtrFromNull(subflagID)
	routine.SourceInboxItemID = stringPtrFromNull(sourceInboxItemID)

	if len(weekdays) > 0 {
		routine.Weekdays = make([]int, len(weekdays))
		for i, v := range weekdays {
			routine.Weekdays[i] = int(v)
		}
	}

	return routine, nil
}

func (r *RoutineRepositoryImpl) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Routine, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, description, recurrence_type, weekdays,
			to_char(start_time, 'HH24:MI') as start_time,
			to_char(end_time, 'HH24:MI') as end_time,
			week_of_month, starts_on, ends_on, color, is_active, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM inbota.routines
		WHERE user_id = $1 AND is_active = true
		ORDER BY start_time, created_at
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.Routine, 0)
	for rows.Next() {
		var routine domain.Routine
		var description, endTime, endsOn, color, flagID, subflagID, sourceInboxItemID sql.NullString
		var weekOfMonth sql.NullInt64
		var weekdays pq.Int64Array

		if err := rows.Scan(&routine.ID, &routine.UserID, &routine.Title, &description, &routine.RecurrenceType, &weekdays, &routine.StartTime, &endTime, &weekOfMonth, &routine.StartsOn, &endsOn, &color, &routine.IsActive, &flagID, &subflagID, &sourceInboxItemID, &routine.CreatedAt, &routine.UpdatedAt); err != nil {
			return nil, nil, err
		}

		routine.Description = stringPtrFromNull(description)
		if endTime.Valid {
			routine.EndTime = endTime.String
		} else {
			routine.EndTime = routine.StartTime
		}
		if weekOfMonth.Valid {
			v := int(weekOfMonth.Int64)
			routine.WeekOfMonth = &v
		}
		routine.EndsOn = stringPtrFromNull(endsOn)
		routine.Color = stringPtrFromNull(color)
		routine.FlagID = stringPtrFromNull(flagID)
		routine.SubflagID = stringPtrFromNull(subflagID)
		routine.SourceInboxItemID = stringPtrFromNull(sourceInboxItemID)

		if len(weekdays) > 0 {
			routine.Weekdays = make([]int, len(weekdays))
			for i, v := range weekdays {
				routine.Weekdays[i] = int(v)
			}
		}

		items = append(items, routine)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}

func (r *RoutineRepositoryImpl) ListByWeekday(ctx context.Context, userID string, weekday int) ([]domain.Routine, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, description, recurrence_type, weekdays,
			to_char(start_time, 'HH24:MI') as start_time,
			to_char(end_time, 'HH24:MI') as end_time,
			week_of_month, starts_on, ends_on, color, is_active, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM inbota.routines
		WHERE user_id = $1 AND is_active = true AND $2 = ANY(weekdays)
		ORDER BY start_time, created_at
	`, userID, weekday)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.Routine, 0)
	for rows.Next() {
		var routine domain.Routine
		var description, endTime, endsOn, color, flagID, subflagID, sourceInboxItemID sql.NullString
		var weekOfMonth sql.NullInt64
		var weekdays pq.Int64Array

		if err := rows.Scan(&routine.ID, &routine.UserID, &routine.Title, &description, &routine.RecurrenceType, &weekdays, &routine.StartTime, &endTime, &weekOfMonth, &routine.StartsOn, &endsOn, &color, &routine.IsActive, &flagID, &subflagID, &sourceInboxItemID, &routine.CreatedAt, &routine.UpdatedAt); err != nil {
			return nil, err
		}

		routine.Description = stringPtrFromNull(description)
		if endTime.Valid {
			routine.EndTime = endTime.String
		} else {
			routine.EndTime = routine.StartTime
		}
		if weekOfMonth.Valid {
			v := int(weekOfMonth.Int64)
			routine.WeekOfMonth = &v
		}
		routine.EndsOn = stringPtrFromNull(endsOn)
		routine.Color = stringPtrFromNull(color)
		routine.FlagID = stringPtrFromNull(flagID)
		routine.SubflagID = stringPtrFromNull(subflagID)
		routine.SourceInboxItemID = stringPtrFromNull(sourceInboxItemID)

		if len(weekdays) > 0 {
			routine.Weekdays = make([]int, len(weekdays))
			for i, v := range weekdays {
				routine.Weekdays[i] = int(v)
			}
		}

		items = append(items, routine)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *RoutineRepositoryImpl) ListDailyStatus(ctx context.Context, userID string, weekday int, date string) ([]repository.RoutineDailyStatus, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, description, recurrence_type, weekdays,
			start_time, end_time,
			week_of_month, starts_on, ends_on, color, is_active, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at,
			completed_at, is_completed, exception_action
		FROM inbota.fnc_routine_daily_status($1, $2, $3::date)
	`, userID, weekday, date)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]repository.RoutineDailyStatus, 0)
	for rows.Next() {
		var item repository.RoutineDailyStatus
		var description, endTime, endsOn, color, flagID, subflagID, sourceInboxItemID sql.NullString
		var weekOfMonth sql.NullInt64
		var weekdays pq.Int64Array
		var completedAt, exceptionAction sql.NullString

		if err := rows.Scan(
			&item.ID, &item.UserID, &item.Title, &description, &item.RecurrenceType, &weekdays, &item.StartTime, &endTime, &weekOfMonth, &item.StartsOn, &endsOn, &color, &item.IsActive, &flagID, &subflagID, &sourceInboxItemID, &item.CreatedAt, &item.UpdatedAt,
			&completedAt, &item.IsCompleted, &exceptionAction,
		); err != nil {
			return nil, err
		}

		item.Description = stringPtrFromNull(description)
		if endTime.Valid {
			item.EndTime = endTime.String
		} else {
			item.EndTime = item.StartTime
		}
		if weekOfMonth.Valid {
			v := int(weekOfMonth.Int64)
			item.WeekOfMonth = &v
		}
		item.EndsOn = stringPtrFromNull(endsOn)
		item.Color = stringPtrFromNull(color)
		item.FlagID = stringPtrFromNull(flagID)
		item.SubflagID = stringPtrFromNull(subflagID)
		item.SourceInboxItemID = stringPtrFromNull(sourceInboxItemID)
		item.CompletedAt = stringPtrFromNull(completedAt)
		item.ExceptionAction = stringPtrFromNull(exceptionAction)

		if len(weekdays) > 0 {
			item.Weekdays = make([]int, len(weekdays))
			for i, v := range weekdays {
				item.Weekdays[i] = int(v)
			}
		}

		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *RoutineRepositoryImpl) CheckOverlap(ctx context.Context, userID string, weekdays []int, startTime, endTime string, excludeID *string) (bool, error) {
	var overlap bool
	err := r.db.QueryRowContext(ctx, `
		SELECT inbota.fnc_check_routine_overlap($1, $2, $3::TIME, $4::TIME, $5::UUID)
	`, userID, pq.Array(weekdays), startTime, endTime, excludeID).Scan(&overlap)

	return overlap, err
}

func (r *RoutineRepositoryImpl) Toggle(ctx context.Context, userID, id string, isActive bool) error {
	result, err := r.db.ExecContext(ctx, `
		UPDATE inbota.routines
		SET is_active = $1, updated_at = now()
		WHERE id = $2 AND user_id = $3
	`, isActive, id, userID)
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

type RoutineExceptionRepositoryImpl struct {
	db dbtx
}

func NewRoutineExceptionRepository(db *DB) *RoutineExceptionRepositoryImpl {
	return &RoutineExceptionRepositoryImpl{db: db}
}

func NewRoutineExceptionRepositoryTx(tx *sql.Tx) *RoutineExceptionRepositoryImpl {
	return &RoutineExceptionRepositoryImpl{db: tx}
}

func (r *RoutineExceptionRepositoryImpl) Create(ctx context.Context, userID string, exception domain.RoutineException) (domain.RoutineException, error) {
	if exception.Action == "" {
		exception.Action = "skip"
	}

	row := r.db.QueryRowContext(ctx, `
		INSERT INTO inbota.routine_exceptions (routine_id, exception_date, action, new_start_time, new_end_time, reason)
		SELECT $1, $2, $3, $4, $5, $6
		WHERE EXISTS (SELECT 1 FROM inbota.routines WHERE id = $1 AND user_id = $7)
		RETURNING id, created_at
	`, exception.RoutineID, exception.ExceptionDate, exception.Action, exception.NewStartTime, exception.NewEndTime, exception.Reason, userID)

	if err := row.Scan(&exception.ID, &exception.CreatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.RoutineException{}, ErrNotFound
		}
		return domain.RoutineException{}, err
	}
	return exception, nil
}

func (r *RoutineExceptionRepositoryImpl) Delete(ctx context.Context, userID, routineID, exceptionDate string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM inbota.routine_exceptions
		WHERE routine_id = $1 AND exception_date = $2
		AND EXISTS (SELECT 1 FROM inbota.routines WHERE id = $1 AND user_id = $3)
	`, routineID, exceptionDate, userID)
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

func (r *RoutineExceptionRepositoryImpl) GetByRoutine(ctx context.Context, userID, routineID string) ([]domain.RoutineException, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, routine_id, exception_date, action, new_start_time, new_end_time, reason, created_at
		FROM inbota.routine_exceptions
		WHERE routine_id = $1 AND EXISTS (SELECT 1 FROM inbota.routines WHERE id = $1 AND user_id = $2)
		ORDER BY exception_date DESC
	`, routineID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.RoutineException, 0)
	for rows.Next() {
		var exception domain.RoutineException
		var newStartTime, newEndTime, reason sql.NullString

		if err := rows.Scan(&exception.ID, &exception.RoutineID, &exception.ExceptionDate, &exception.Action, &newStartTime, &newEndTime, &reason, &exception.CreatedAt); err != nil {
			return nil, err
		}

		exception.NewStartTime = stringPtrFromNull(newStartTime)
		exception.NewEndTime = stringPtrFromNull(newEndTime)
		exception.Reason = stringPtrFromNull(reason)

		items = append(items, exception)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *RoutineExceptionRepositoryImpl) GetForDate(ctx context.Context, userID, routineID, date string) (*domain.RoutineException, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, routine_id, exception_date, action, new_start_time, new_end_time, reason, created_at
		FROM inbota.routine_exceptions
		WHERE routine_id = $1 AND exception_date = $2 AND EXISTS (SELECT 1 FROM inbota.routines WHERE id = $1 AND user_id = $3)
	`, routineID, date, userID)

	var exception domain.RoutineException
	var newStartTime, newEndTime, reason sql.NullString

	if err := row.Scan(&exception.ID, &exception.RoutineID, &exception.ExceptionDate, &exception.Action, &newStartTime, &newEndTime, &reason, &exception.CreatedAt); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	exception.NewStartTime = stringPtrFromNull(newStartTime)
	exception.NewEndTime = stringPtrFromNull(newEndTime)
	exception.Reason = stringPtrFromNull(reason)

	return &exception, nil
}

type RoutineCompletionRepositoryImpl struct {
	db dbtx
}

func NewRoutineCompletionRepository(db *DB) *RoutineCompletionRepositoryImpl {
	return &RoutineCompletionRepositoryImpl{db: db}
}

func NewRoutineCompletionRepositoryTx(tx *sql.Tx) *RoutineCompletionRepositoryImpl {
	return &RoutineCompletionRepositoryImpl{db: tx}
}

func (r *RoutineCompletionRepositoryImpl) Create(ctx context.Context, userID string, completion domain.RoutineCompletion) (domain.RoutineCompletion, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO inbota.routine_completions (routine_id, completed_on)
		SELECT $1, $2
		WHERE EXISTS (SELECT 1 FROM inbota.routines WHERE id = $1 AND user_id = $3)
		RETURNING id, completed_at
	`, completion.RoutineID, completion.CompletedOn, userID)

	if err := row.Scan(&completion.ID, &completion.CompletedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.RoutineCompletion{}, ErrNotFound
		}
		return domain.RoutineCompletion{}, err
	}
	return completion, nil
}

func (r *RoutineCompletionRepositoryImpl) Delete(ctx context.Context, userID, routineID, completedOn string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM inbota.routine_completions
		WHERE routine_id = $1 AND completed_on = $2
		AND EXISTS (SELECT 1 FROM inbota.routines WHERE id = $1 AND user_id = $3)
	`, routineID, completedOn, userID)
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

func (r *RoutineCompletionRepositoryImpl) GetByRoutine(ctx context.Context, userID, routineID string) ([]domain.RoutineCompletion, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, routine_id, completed_on, completed_at
		FROM inbota.routine_completions
		WHERE routine_id = $1 AND EXISTS (SELECT 1 FROM inbota.routines WHERE id = $1 AND user_id = $2)
		ORDER BY completed_on DESC
	`, routineID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.RoutineCompletion, 0)
	for rows.Next() {
		var completion domain.RoutineCompletion
		if err := rows.Scan(&completion.ID, &completion.RoutineID, &completion.CompletedOn, &completion.CompletedAt); err != nil {
			return nil, err
		}
		items = append(items, completion)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *RoutineCompletionRepositoryImpl) GetByDate(ctx context.Context, userID, date string) ([]domain.RoutineCompletion, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, routine_id, completed_on, completed_at
		FROM inbota.routine_completions
		WHERE completed_on = $1 AND EXISTS (SELECT 1 FROM inbota.routines WHERE id = routine_id AND user_id = $2)
	`, date, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.RoutineCompletion, 0)
	for rows.Next() {
		var completion domain.RoutineCompletion
		if err := rows.Scan(&completion.ID, &completion.RoutineID, &completion.CompletedOn, &completion.CompletedAt); err != nil {
			return nil, err
		}
		items = append(items, completion)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *RoutineCompletionRepositoryImpl) GetStreak(ctx context.Context, userID, routineID string) (int, int, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT current_streak, total_completions
		FROM inbota.fnc_get_routine_streak($1)
		WHERE EXISTS (SELECT 1 FROM inbota.routines WHERE id = $1 AND user_id = $2)
	`, routineID, userID)

	var currentStreak, totalCompletions int
	if err := row.Scan(&currentStreak, &totalCompletions); err != nil {
		if err == sql.ErrNoRows {
			return 0, 0, nil
		}
		return 0, 0, err
	}

	return currentStreak, totalCompletions, nil
}

func (r *RoutineRepositoryImpl) ListAllByWeekday(ctx context.Context, weekday int) ([]domain.Routine, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, description, recurrence_type, weekdays,
			to_char(start_time, 'HH24:MI') as start_time,
			to_char(end_time, 'HH24:MI') as end_time,
			week_of_month, starts_on, ends_on, color, is_active, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM inbota.routines
		WHERE is_active = true AND $1 = ANY(weekdays)
		ORDER BY start_time, created_at
	`, weekday)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.Routine, 0)
	for rows.Next() {
		var routine domain.Routine
		var description, endTime, endsOn, color, flagID, subflagID, sourceInboxItemID sql.NullString
		var weekOfMonth sql.NullInt64
		var weekdays pq.Int64Array

		if err := rows.Scan(&routine.ID, &routine.UserID, &routine.Title, &description, &routine.RecurrenceType, &weekdays, &routine.StartTime, &endTime, &weekOfMonth, &routine.StartsOn, &endsOn, &color, &routine.IsActive, &flagID, &subflagID, &sourceInboxItemID, &routine.CreatedAt, &routine.UpdatedAt); err != nil {
			return nil, err
		}

		routine.Description = stringPtrFromNull(description)
		if endTime.Valid {
			routine.EndTime = endTime.String
		} else {
			routine.EndTime = routine.StartTime
		}
		if weekOfMonth.Valid {
			v := int(weekOfMonth.Int64)
			routine.WeekOfMonth = &v
		}
		routine.EndsOn = stringPtrFromNull(endsOn)
		routine.Color = stringPtrFromNull(color)
		routine.FlagID = stringPtrFromNull(flagID)
		routine.SubflagID = stringPtrFromNull(subflagID)
		routine.SourceInboxItemID = stringPtrFromNull(sourceInboxItemID)

		if len(weekdays) > 0 {
			routine.Weekdays = make([]int, len(weekdays))
			for i, v := range weekdays {
				routine.Weekdays[i] = int(v)
			}
		}

		items = append(items, routine)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}
