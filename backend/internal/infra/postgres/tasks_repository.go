package postgres

import (
	"context"
	"database/sql"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type TaskRepository struct {
	db dbtx
}

func NewTaskRepository(db *DB) *TaskRepository {
	return &TaskRepository{db: db}
}

func NewTaskRepositoryTx(tx *sql.Tx) *TaskRepository {
	return &TaskRepository{db: tx}
}

func (r *TaskRepository) Create(ctx context.Context, task domain.Task) (domain.Task, error) {
	if task.Status == "" {
		task.Status = domain.TaskStatusOpen
	}

	row := r.db.QueryRowContext(ctx, `
		INSERT INTO organiq.tasks (user_id, title, description, status, due_at, flag_id, subflag_id, source_inbox_item_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at, updated_at
	`, task.UserID, task.Title, task.Description, string(task.Status), task.DueAt, task.FlagID, task.SubflagID, task.SourceInboxItemID)

	if err := row.Scan(&task.ID, &task.CreatedAt, &task.UpdatedAt); err != nil {
		return domain.Task{}, err
	}
	return task, nil
}

func (r *TaskRepository) Update(ctx context.Context, task domain.Task) (domain.Task, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE organiq.tasks
		SET title = $1, description = $2, status = $3, due_at = $4, flag_id = $5, subflag_id = $6, updated_at = now()
		WHERE id = $7 AND user_id = $8
		RETURNING created_at, updated_at
	`, task.Title, task.Description, string(task.Status), task.DueAt, task.FlagID, task.SubflagID, task.ID, task.UserID)

	if err := row.Scan(&task.CreatedAt, &task.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Task{}, ErrNotFound
		}
		return domain.Task{}, err
	}
	return task, nil
}

func (r *TaskRepository) Delete(ctx context.Context, userID, id string) error {
	result, err := r.db.ExecContext(ctx, `
		DELETE FROM organiq.tasks
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

func (r *TaskRepository) Get(ctx context.Context, userID, id string) (domain.Task, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, title, description, status, due_at, notification_title, notification_body, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM organiq.tasks
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var description sql.NullString
	var dueAt sql.NullTime
	var notifTitle, notifBody sql.NullString
	var flagID sql.NullString
	var subflagID sql.NullString
	var sourceInboxID sql.NullString
	var status string
	var task domain.Task
	if err := row.Scan(&task.ID, &task.UserID, &task.Title, &description, &status, &dueAt, &notifTitle, &notifBody, &flagID, &subflagID, &sourceInboxID, &task.CreatedAt, &task.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.Task{}, ErrNotFound
		}
		return domain.Task{}, err
	}
	task.Description = stringPtrFromNull(description)
	task.Status = domain.TaskStatus(status)
	task.DueAt = timePtrFromNull(dueAt)
	task.NotificationTitle = stringPtrFromNull(notifTitle)
	task.NotificationBody = stringPtrFromNull(notifBody)
	task.FlagID = stringPtrFromNull(flagID)
	task.SubflagID = stringPtrFromNull(subflagID)
	task.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
	return task, nil
}

func (r *TaskRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Task, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, description, status, due_at, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM organiq.tasks
		WHERE user_id = $1
		ORDER BY due_at NULLS LAST, created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.Task, 0)
	for rows.Next() {
		var description sql.NullString
		var dueAt sql.NullTime
		var flagID sql.NullString
		var subflagID sql.NullString
		var sourceInboxID sql.NullString
		var status string
		var task domain.Task
		if err := rows.Scan(&task.ID, &task.UserID, &task.Title, &description, &status, &dueAt, &flagID, &subflagID, &sourceInboxID, &task.CreatedAt, &task.UpdatedAt); err != nil {
			return nil, nil, err
		}
		task.Description = stringPtrFromNull(description)
		task.Status = domain.TaskStatus(status)
		task.DueAt = timePtrFromNull(dueAt)
		task.FlagID = stringPtrFromNull(flagID)
		task.SubflagID = stringPtrFromNull(subflagID)
		task.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
		items = append(items, task)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}

func (r *TaskRepository) ListUpcoming(ctx context.Context, start, end time.Time) ([]domain.Task, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, title, description, status, due_at, flag_id, subflag_id, source_inbox_item_id, created_at, updated_at
		FROM organiq.tasks
		WHERE status = 'OPEN' AND due_at >= $1 AND due_at <= $2
	`, start, end)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.Task, 0)
	for rows.Next() {
		var description sql.NullString
		var dueAt sql.NullTime
		var flagID sql.NullString
		var subflagID sql.NullString
		var sourceInboxID sql.NullString
		var status string
		var task domain.Task
		if err := rows.Scan(&task.ID, &task.UserID, &task.Title, &description, &status, &dueAt, &flagID, &subflagID, &sourceInboxID, &task.CreatedAt, &task.UpdatedAt); err != nil {
			return nil, err
		}
		task.Description = stringPtrFromNull(description)
		task.Status = domain.TaskStatus(status)
		task.DueAt = timePtrFromNull(dueAt)
		task.FlagID = stringPtrFromNull(flagID)
		task.SubflagID = stringPtrFromNull(subflagID)
		task.SourceInboxItemID = stringPtrFromNull(sourceInboxID)
		items = append(items, task)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

func (r *TaskRepository) UpdateNotificationCopy(ctx context.Context, id, title, body string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE organiq.tasks 
		SET notification_title = $1, notification_body = $2, updated_at = now() 
		WHERE id = $3
	`, title, body, id)
	return err
}
