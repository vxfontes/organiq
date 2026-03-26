package usecase

import (
	"context"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type DeviceTokenUsecase struct {
	DeviceTokens repository.DeviceTokenRepository
}

func (uc *DeviceTokenUsecase) RegisterToken(ctx context.Context, userID, deviceID, pushToken, platform, deviceName, appVersion string) error {
	if userID == "" || deviceID == "" || pushToken == "" {
		return ErrMissingRequiredFields
	}

	switch domain.DevicePlatform(platform) {
	case domain.DevicePlatformIOS, domain.DevicePlatformAndroid:
	default:
		return ErrInvalidPlatform
	}

	dt := domain.DeviceToken{
		UserID:     userID,
		DeviceID:   deviceID,
		PushToken:  pushToken,
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

func (uc *DeviceTokenUsecase) UnregisterToken(ctx context.Context, deviceID, userID string) error {
	return uc.DeviceTokens.Delete(ctx, deviceID, userID)
}
