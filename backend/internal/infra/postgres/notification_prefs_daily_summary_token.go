package postgres

import (
	"context"
	"database/sql"
	"errors"
	"strings"
)

func (r *NotificationPreferencesRepository) GetDailySummaryTokenByUserID(ctx context.Context, userID string) (string, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT daily_summary_token
		FROM organiq.notification_preferences
		WHERE user_id = $1
		LIMIT 1
	`, userID)

	var token string
	if err := row.Scan(&token); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", ErrNotFound
		}
		return "", err
	}
	return token, nil
}

func (r *NotificationPreferencesRepository) RotateDailySummaryToken(ctx context.Context, userID string) (string, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE organiq.notification_preferences
		SET daily_summary_token = gen_random_uuid()::text, updated_at = now()
		WHERE user_id = $1
		RETURNING daily_summary_token
	`, userID)

	var token string
	if err := row.Scan(&token); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", ErrNotFound
		}
		return "", err
	}
	return token, nil
}

func (r *NotificationPreferencesRepository) FindUserIDByDailySummaryToken(ctx context.Context, token string) (string, error) {
	token = strings.TrimSpace(token)
	if token == "" {
		return "", ErrNotFound
	}

	row := r.db.QueryRowContext(ctx, `
		SELECT user_id
		FROM organiq.notification_preferences
		WHERE daily_summary_token = $1
		LIMIT 1
	`, token)

	var userID string
	if err := row.Scan(&userID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", ErrNotFound
		}
		return "", err
	}
	return userID, nil
}
