package postgres

import (
	"context"
	"database/sql"
	"time"

	"github.com/lib/pq"

	"inbota/backend/internal/app/repository"
)

type HomeRepository struct {
	db dbtx
}

func NewHomeRepository(db *DB) *HomeRepository {
	return &HomeRepository{db: db}
}

func (r *HomeRepository) ListInsightTemplates(ctx context.Context) ([]repository.HomeInsightTemplate, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, category, title_template, summary_template, footer_template,
		       is_focus, min_gap_minutes, priority
		FROM inbota.home_insight_templates
		ORDER BY priority DESC, COALESCE(min_gap_minutes, 0) DESC, created_at
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]repository.HomeInsightTemplate, 0)
	for rows.Next() {
		var item repository.HomeInsightTemplate
		var minGap sql.NullInt64
		if err := rows.Scan(
			&item.ID,
			&item.Category,
			&item.TitleTemplate,
			&item.SummaryTemplate,
			&item.FooterTemplate,
			&item.IsFocus,
			&minGap,
			&item.Priority,
		); err != nil {
			return nil, err
		}

		if minGap.Valid {
			v := int(minGap.Int64)
			item.MinGapMinutes = &v
		}

		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *HomeRepository) ListShoppingPreview(ctx context.Context, userID string, limit int) ([]repository.HomeShoppingPreview, error) {
	if limit <= 0 {
		limit = 3
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT
			sl.id,
			sl.title,
			COUNT(si.id) AS total_items,
			COUNT(si.id) FILTER (WHERE si.checked = false) AS pending_items,
			COALESCE(
				ARRAY_AGG(si.title ORDER BY si.sort_order ASC, si.created_at ASC)
				FILTER (WHERE si.checked = false),
				'{}'
			) AS preview_items
		FROM inbota.shopping_lists sl
		LEFT JOIN inbota.shopping_items si
			ON sl.id = si.list_id
			AND sl.user_id = si.user_id
		WHERE sl.user_id = $1
		  AND sl.status = 'OPEN'
		GROUP BY sl.id, sl.title
		ORDER BY pending_items DESC, LOWER(sl.title)
		LIMIT $2
	`, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]repository.HomeShoppingPreview, 0)
	for rows.Next() {
		var item repository.HomeShoppingPreview
		var previewItems []string
		if err := rows.Scan(
			&item.ID,
			&item.Title,
			&item.TotalItems,
			&item.PendingItems,
			pq.Array(&previewItems),
		); err != nil {
			return nil, err
		}
		item.PreviewItems = previewItems
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *HomeRepository) ListFocusTasks(ctx context.Context, userID string, limit int) ([]repository.HomeFocusTask, error) {
	if limit <= 0 {
		limit = 200
	}
	if limit > 500 {
		limit = 500
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, title, description, status, due_at, created_at, updated_at
		FROM inbota.tasks
		WHERE user_id = $1
		  AND status = 'OPEN'
		ORDER BY due_at NULLS LAST, created_at DESC
		LIMIT $2
	`, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]repository.HomeFocusTask, 0)
	for rows.Next() {
		var item repository.HomeFocusTask
		var description sql.NullString
		var dueAt sql.NullTime
		if err := rows.Scan(
			&item.ID,
			&item.Title,
			&description,
			&item.Status,
			&dueAt,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, err
		}
		item.Description = stringPtrFromNull(description)
		item.DueAt = timePtrFromNull(dueAt)
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *HomeRepository) ListWeekOccurrences(ctx context.Context, userID string, start, end time.Time) ([]time.Time, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT t.dt
		FROM (
			SELECT start_at AS dt FROM inbota.events WHERE user_id = $1
			UNION ALL
			SELECT due_at AS dt FROM inbota.tasks WHERE user_id = $1
			UNION ALL
			SELECT remind_at AS dt FROM inbota.reminders WHERE user_id = $1
		) t
		WHERE t.dt IS NOT NULL
		  AND t.dt >= $2
		  AND t.dt < $3
	`, userID, start, end)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]time.Time, 0)
	for rows.Next() {
		var at time.Time
		if err := rows.Scan(&at); err != nil {
			return nil, err
		}
		items = append(items, at)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *HomeRepository) CountOverdue(ctx context.Context, userID string, now time.Time) (int, int, error) {
	var overdueTasks int
	var overdueReminders int
	if err := r.db.QueryRowContext(ctx, `
		SELECT
			(SELECT COUNT(*)
			 FROM inbota.tasks
			 WHERE user_id = $1
			   AND status = 'OPEN'
			   AND due_at IS NOT NULL
			   AND due_at < $2),
			(SELECT COUNT(*)
			 FROM inbota.reminders
			 WHERE user_id = $1
			   AND status = 'OPEN'
			   AND remind_at IS NOT NULL
			   AND remind_at < $2)
	`, userID, now).Scan(&overdueTasks, &overdueReminders); err != nil {
		return 0, 0, err
	}

	return overdueTasks, overdueReminders, nil
}
