package usecase

import (
	"context"
	"fmt"
	"log/slog"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/infra/push"
)

type NotificationUsecase struct {
	Prefs   repository.NotificationPreferencesRepository
	Log     repository.NotificationLogRepository
	Tokens  repository.DeviceTokenRepository
	Config  repository.AppConfigRepository
	Ntfy    *push.NtfyClient
}

func (uc *NotificationUsecase) GetDailySummaryToken(ctx context.Context, userID string) (string, error) {
	return uc.Prefs.GetDailySummaryTokenByUserID(ctx, userID)
}

func (uc *NotificationUsecase) RotateDailySummaryToken(ctx context.Context, userID string) (string, error) {
	return uc.Prefs.RotateDailySummaryToken(ctx, userID)
}

func (uc *NotificationUsecase) GetPreferences(ctx context.Context, userID string) (domain.NotificationPreferences, error) {
	return uc.Prefs.GetByUserID(ctx, userID)
}

func (uc *NotificationUsecase) UpdatePreferences(ctx context.Context, userID string, updateFn func(*domain.NotificationPreferences)) error {
	prefs, err := uc.Prefs.GetByUserID(ctx, userID)
	if err != nil {
		return err
	}
	updateFn(&prefs)
	return uc.Prefs.Upsert(ctx, prefs)
}

func (uc *NotificationUsecase) ListNotifications(ctx context.Context, userID string, limit, offset int) ([]domain.NotificationLog, error) {
	return uc.Log.ListByUserID(ctx, userID, limit, offset)
}

func (uc *NotificationUsecase) MarkAsRead(ctx context.Context, id, userID string) error {
	return uc.Log.MarkAsRead(ctx, id, userID)
}

func (uc *NotificationUsecase) MarkAllAsRead(ctx context.Context, userID string) error {
	return uc.Log.MarkAllAsRead(ctx, userID)
}

func (uc *NotificationUsecase) SendTestNotification(ctx context.Context, userID string) error {
	if uc.Ntfy == nil {
		return fmt.Errorf("ntfy_not_initialized")
	}

	tokens, err := uc.Tokens.ListByUserID(ctx, userID)
	if err != nil {
		return err
	}

	if len(tokens) == 0 {
		return fmt.Errorf("no_active_devices")
	}

	title := "Teste de Notificação"
	body := "Isso é um teste do Inbota via ntfy.sh! 🎉"
	
	data := map[string]string{"type": "test"}
	var lastErr error
	for _, t := range tokens {
		if err := uc.Ntfy.Send(ctx, t.Topic, title, body, data); err != nil {
			slog.Error("ntfy_test_send_error",
				slog.String("error", err.Error()),
				slog.String("topic", t.Topic),
			)
			lastErr = fmt.Errorf("ntfy_send_failed: %w", err)
		}
	}

	return lastErr
}
