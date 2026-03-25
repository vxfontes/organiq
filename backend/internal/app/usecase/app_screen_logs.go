package usecase

import (
	"context"
	"encoding/json"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type AppScreenLogUsecase struct {
	Logs repository.AppScreenLogRepository
}

type AppScreenLogInput struct {
	SessionID         *string
	ScreenName        string
	RoutePath         string
	PreviousRoutePath *string
	EventName         *string
	Platform          *string
	AppVersion        *string
	Metadata          json.RawMessage
	OccurredAt        *time.Time
}

func (uc *AppScreenLogUsecase) Create(
	ctx context.Context,
	userID string,
	input AppScreenLogInput,
) (domain.AppScreenLog, error) {
	if uc.Logs == nil {
		return domain.AppScreenLog{}, ErrDependencyMissing
	}

	userID = normalizeString(userID)
	screenName := normalizeString(input.ScreenName)
	routePath := normalizeString(input.RoutePath)
	if userID == "" || screenName == "" || routePath == "" {
		return domain.AppScreenLog{}, ErrMissingRequiredFields
	}

	eventName := "screen_view"
	if input.EventName != nil {
		next := normalizeString(*input.EventName)
		if next != "" {
			eventName = next
		}
	}

	log := domain.AppScreenLog{
		UserID:            userID,
		SessionID:         normalizeOptionalString(input.SessionID),
		ScreenName:        screenName,
		RoutePath:         routePath,
		PreviousRoutePath: normalizeOptionalString(input.PreviousRoutePath),
		EventName:         eventName,
		Platform:          normalizeOptionalString(input.Platform),
		AppVersion:        normalizeOptionalString(input.AppVersion),
		Metadata:          nil,
		OccurredAt:        time.Now().UTC(),
	}
	if len(input.Metadata) > 0 {
		log.Metadata = input.Metadata
	}
	if input.OccurredAt != nil {
		log.OccurredAt = input.OccurredAt.UTC()
	}

	return uc.Logs.Create(ctx, log)
}
