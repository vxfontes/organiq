package postgres

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type DeviceTokenRepository struct {
	db *DB
}

func NewDeviceTokenRepository(db *DB) *DeviceTokenRepository {
	return &DeviceTokenRepository{db: db}
}

func (r *DeviceTokenRepository) Upsert(ctx context.Context, dt domain.DeviceToken) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO inbota.device_tokens (user_id, device_id, ntfy_topic, platform, device_name, app_version, is_active, last_seen_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, now())
		ON CONFLICT (device_id) DO UPDATE SET
			user_id = EXCLUDED.user_id,
			ntfy_topic = EXCLUDED.ntfy_topic,
			platform = EXCLUDED.platform,
			device_name = EXCLUDED.device_name,
			app_version = EXCLUDED.app_version,
			is_active = EXCLUDED.is_active,
			last_seen_at = now()
	`, dt.UserID, dt.DeviceID, dt.Topic, dt.Platform, dt.DeviceName, dt.AppVersion, dt.IsActive)
	return err
}

func (r *DeviceTokenRepository) Delete(ctx context.Context, deviceID, userID string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM inbota.device_tokens WHERE device_id = $1 AND user_id = $2`, deviceID, userID)
	return err
}

func (r *DeviceTokenRepository) ListByUserID(ctx context.Context, userID string) ([]domain.DeviceToken, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, device_id, ntfy_topic, platform, device_name, app_version, is_active, last_seen_at, created_at
		FROM inbota.device_tokens
		WHERE user_id = $1 AND is_active = true
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []domain.DeviceToken
	for rows.Next() {
		var t domain.DeviceToken
		if err := rows.Scan(&t.ID, &t.UserID, &t.DeviceID, &t.Topic, &t.Platform, &t.DeviceName, &t.AppVersion, &t.IsActive, &t.LastSeenAt, &t.CreatedAt); err != nil {
			return nil, err
		}
		tokens = append(tokens, t)
	}
	return tokens, rows.Err()
}

func (r *DeviceTokenRepository) Deactivate(ctx context.Context, topic string) error {
	_, err := r.db.ExecContext(ctx, `UPDATE inbota.device_tokens SET is_active = false WHERE ntfy_topic = $1`, topic)
	return err
}
