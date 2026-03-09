package postgres

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type NotificationTemplateRepository struct {
	db *DB
}

func NewNotificationTemplateRepository(db *DB) *NotificationTemplateRepository {
	return &NotificationTemplateRepository{db: db}
}

func (r *NotificationTemplateRepository) GetAll(ctx context.Context) ([]domain.NotificationTemplate, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, type, trigger_key, title_template, body_template, is_active, created_at, updated_at
		FROM inbota.notification_templates
		WHERE is_active = true
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var templates []domain.NotificationTemplate
	for rows.Next() {
		var t domain.NotificationTemplate
		if err := rows.Scan(&t.ID, &t.Type, &t.TriggerKey, &t.TitleTemplate, &t.BodyTemplate, &t.IsActive, &t.CreatedAt, &t.UpdatedAt); err != nil {
			return nil, err
		}
		templates = append(templates, t)
	}
	return templates, rows.Err()
}
