package usecase

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type AppErrorLogUsecase struct {
	Logs repository.AppErrorLogRepository
}

type AppErrorLogInput struct {
	SessionID     *string
	ScreenName    *string
	RoutePath     *string
	Source        string
	ErrorCode     *string
	Message       string
	StackTrace    *string
	RequestID     *string
	RequestPath   *string
	RequestMethod *string
	HTTPStatus    *int
	Metadata      json.RawMessage
	OccurredAt    *time.Time
}

var allowedAppErrorSources = map[string]struct{}{
	"flutter":    {},
	"dio":        {},
	"controller": {},
	"api":        {},
	"bootstrap":  {},
}

func (uc *AppErrorLogUsecase) Create(
	ctx context.Context,
	userID *string,
	input AppErrorLogInput,
) (domain.AppErrorLog, error) {
	if uc.Logs == nil {
		return domain.AppErrorLog{}, ErrDependencyMissing
	}

	message := normalizeString(input.Message)
	source := strings.ToLower(normalizeString(input.Source))
	if message == "" || source == "" {
		return domain.AppErrorLog{}, ErrMissingRequiredFields
	}
	if _, ok := allowedAppErrorSources[source]; !ok {
		return domain.AppErrorLog{}, ErrInvalidSource
	}

	log := domain.AppErrorLog{
		UserID:        normalizeOptionalString(userID),
		SessionID:     normalizeOptionalString(input.SessionID),
		ScreenName:    normalizeOptionalString(input.ScreenName),
		RoutePath:     normalizeOptionalString(input.RoutePath),
		Source:        source,
		ErrorCode:     normalizeOptionalString(input.ErrorCode),
		Message:       message,
		StackTrace:    normalizeOptionalString(input.StackTrace),
		RequestID:     normalizeOptionalString(input.RequestID),
		RequestPath:   normalizeOptionalString(input.RequestPath),
		RequestMethod: normalizeOptionalString(input.RequestMethod),
		HTTPStatus:    input.HTTPStatus,
		Metadata:      nil,
		OccurredAt:    time.Now().UTC(),
	}
	if len(input.Metadata) > 0 {
		log.Metadata = input.Metadata
	}
	if input.OccurredAt != nil {
		log.OccurredAt = input.OccurredAt.UTC()
	}

	return uc.Logs.Create(ctx, log)
}
