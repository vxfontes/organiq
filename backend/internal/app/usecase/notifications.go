package usecase

import (
	"context"
	"fmt"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/infra/push"
)

type NotificationUsecase struct {
	Prefs   repository.NotificationPreferencesRepository
	Log     repository.NotificationLogRepository
	Tokens  repository.DeviceTokenRepository
	Config  repository.AppConfigRepository
	FCM     *push.FCMClient
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
	tokens, err := uc.Tokens.ListByUserID(ctx, userID)
	if err != nil {
		return err
	}

	if len(tokens) == 0 {
		return fmt.Errorf("no_active_devices")
	}

	title := "Teste de Notificação"
	body := "Isso é um teste do Inbota! 🎉"
	if uc.Config != nil {
		if cfg, err := uc.Config.GetAll(ctx); err == nil {
			if v := cfg["notification.test_title"]; v != "" {
				title = v
			}
			if v := cfg["notification.test_body"]; v != "" {
				body = v
			}
		}
	}

	data := map[string]string{"type": "test"}
	for _, t := range tokens {
		if uc.FCM != nil {
			_ = uc.FCM.Send(ctx, t.Token, title, body, data)
		}
	}

	return nil
}
