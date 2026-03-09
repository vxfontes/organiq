package usecase

import (
	"context"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type DeviceTokenUsecase struct {
	DeviceTokens repository.DeviceTokenRepository
}

func (uc *DeviceTokenUsecase) RegisterToken(ctx context.Context, userID, token, platform, deviceName, appVersion string) error {
	dt := domain.DeviceToken{
		UserID:     userID,
		Token:      token,
		Platform:   domain.DevicePlatform(platform),
		DeviceName: &deviceName,
		AppVersion: &appVersion,
		IsActive:   true,
	}
	if deviceName == "" {
		dt.DeviceName = nil
	}
	if appVersion == "" {
		dt.AppVersion = nil
	}
	return uc.DeviceTokens.Upsert(ctx, dt)
}

func (uc *DeviceTokenUsecase) UnregisterToken(ctx context.Context, token, userID string) error {
	return uc.DeviceTokens.Delete(ctx, token, userID)
}
