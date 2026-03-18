package usecase

import (
	"context"
	"fmt"
	"log/slog"
	"strings"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/infra/push"
)

type NotificationUsecase struct {
	Prefs    repository.NotificationPreferencesRepository
	Log      repository.NotificationLogRepository
	Tokens   repository.DeviceTokenRepository
	Attempts repository.NotificationDeliveryAttemptRepository
	Config   repository.AppConfigRepository
	Push     *push.FCMClient
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

func (uc *NotificationUsecase) ListDeliveryAttempts(
	ctx context.Context,
	userID, notificationLogID string,
	limit, offset int,
) ([]domain.NotificationDeliveryAttempt, error) {
	if uc.Attempts == nil {
		return nil, ErrDependencyMissing
	}

	var filterID *string
	trimmed := strings.TrimSpace(notificationLogID)
	if trimmed != "" {
		filterID = &trimmed
	}

	return uc.Attempts.ListByUserID(ctx, userID, filterID, limit, offset)
}

func (uc *NotificationUsecase) SendTestNotification(ctx context.Context, userID string) error {
	if uc.Push == nil {
		return fmt.Errorf("push_not_initialized")
	}

	tokens, err := uc.Tokens.ListByUserID(ctx, userID)
	if err != nil {
		return err
	}

	if len(tokens) == 0 {
		return fmt.Errorf("no_active_devices")
	}

	title := "Teste de Notificação"
	body := "Isso e um teste do Organiq via push notification!"

	data := map[string]string{
		"type":      "test",
		"click_url": "/settings/notifications",
	}
	var (
		lastErr  error
		success  bool
		attempts int
	)
	for i, t := range tokens {
		attempts++
		if err := uc.Push.Send(ctx, t.PushToken, title, body, data); err != nil {
			errCode := push.ErrorCode(err)
			errMsg := err.Error()
			uc.recordDeliveryAttempt(
				ctx,
				nil,
				userID,
				t.DeviceID,
				i+1,
				domain.NotificationDeliveryStatusFailed,
				&errCode,
				&errMsg,
			)

			if push.IsInvalidTokenError(err) {
				if deactivateErr := uc.Tokens.Deactivate(ctx, t.PushToken); deactivateErr != nil {
					slog.Error("push_test_deactivate_invalid_token_error",
						slog.String("error", deactivateErr.Error()),
						slog.String("device_id", t.DeviceID),
					)
				}
			}
			slog.Error("push_test_send_error",
				slog.String("error", err.Error()),
				slog.String("device_id", t.DeviceID),
			)
			lastErr = fmt.Errorf("push_send_failed: %w", err)
			continue
		}

		uc.recordDeliveryAttempt(
			ctx,
			nil,
			userID,
			t.DeviceID,
			i+1,
			domain.NotificationDeliveryStatusSuccess,
			nil,
			nil,
		)
		success = true
	}

	if success {
		return nil
	}
	if attempts == 0 {
		return fmt.Errorf("no_active_devices")
	}
	return lastErr
}

func (uc *NotificationUsecase) recordDeliveryAttempt(
	ctx context.Context,
	notificationLogID *string,
	userID, deviceID string,
	attemptNo int,
	status domain.NotificationDeliveryStatus,
	errorCode, errorMessage *string,
) {
	if uc.Attempts == nil {
		return
	}

	_, err := uc.Attempts.Create(ctx, domain.NotificationDeliveryAttempt{
		NotificationLogID: notificationLogID,
		UserID:            userID,
		DeviceID:          deviceID,
		Provider:          "fcm",
		AttemptNo:         attemptNo,
		Status:            status,
		ErrorCode:         errorCode,
		ErrorMessage:      errorMessage,
	})
	if err != nil {
		slog.Warn("push_delivery_attempt_log_error",
			slog.String("error", err.Error()),
			slog.String("device_id", deviceID),
		)
	}
}
