package usecase

import (
	"context"
	"crypto/sha256"
	"fmt"
	"regexp"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type DeviceTokenUsecase struct {
	DeviceTokens repository.DeviceTokenRepository
}

func (uc *DeviceTokenUsecase) RegisterToken(ctx context.Context, userID, deviceID, platform, deviceName, appVersion string) (string, error) {
	// Regra de geração do tópico: Prefixo + Hash estável do DeviceID
	// Isso garante que a regra de "como o tópico é gerado" fique só no backend.
	topic := uc.generateTopic(deviceID)

	dt := domain.DeviceToken{
		UserID:     userID,
		DeviceID:   deviceID,
		Topic:      topic,
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

	if err := uc.DeviceTokens.Upsert(ctx, dt); err != nil {
		return "", err
	}

	return topic, nil
}

func (uc *DeviceTokenUsecase) UnregisterToken(ctx context.Context, deviceID, userID string) error {
	return uc.DeviceTokens.Delete(ctx, deviceID, userID)
}

func (uc *DeviceTokenUsecase) generateTopic(deviceID string) string {
	// Remove caracteres não alfanuméricos para segurança
	reg := regexp.MustCompile("[^a-zA-Z0-9]+")
	cleanID := reg.ReplaceAllString(deviceID, "")

	// Hash para evitar tópicos previsíveis caso o deviceID seja algo simples
	hash := sha256.Sum256([]byte(cleanID + "inbota_salt_2024"))
	return fmt.Sprintf("inbota_%x", hash[:12]) // 24 caracteres hex
}
