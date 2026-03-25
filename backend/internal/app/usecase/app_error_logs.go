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

const (
	maxAppErrorUserIDLen        = 64
	maxAppErrorSessionIDLen     = 128
	maxAppErrorScreenNameLen    = 120
	maxAppErrorRoutePathLen     = 256
	maxAppErrorErrorCodeLen     = 120
	maxAppErrorMessageLen       = 2000
	maxAppErrorStackTraceLen    = 16000
	maxAppErrorRequestIDLen     = 120
	maxAppErrorRequestPathLen   = 256
	maxAppErrorRequestMethodLen = 16
	maxAppErrorMetadataBytes    = 4096
	maxAppErrorMetadataInput    = 32768
	maxAppErrorAgeWindow        = 30 * 24 * time.Hour
	maxAppErrorFutureWindow     = 5 * time.Minute
)

func (uc *AppErrorLogUsecase) Create(
	ctx context.Context,
	userID *string,
	input AppErrorLogInput,
) (domain.AppErrorLog, error) {
	if uc.Logs == nil {
		return domain.AppErrorLog{}, ErrDependencyMissing
	}

	normalizedUserID := normalizeOptionalStringWithLimit(userID, maxAppErrorUserIDLen)
	sessionID := normalizeOptionalStringWithLimit(input.SessionID, maxAppErrorSessionIDLen)
	if normalizedUserID == nil && sessionID == nil {
		return domain.AppErrorLog{}, ErrMissingRequiredFields
	}

	message := normalizeStringWithLimit(input.Message, maxAppErrorMessageLen)
	source := strings.ToLower(normalizeString(input.Source))
	if message == "" || source == "" {
		return domain.AppErrorLog{}, ErrMissingRequiredFields
	}
	if _, ok := allowedAppErrorSources[source]; !ok {
		return domain.AppErrorLog{}, ErrInvalidSource
	}
	if input.HTTPStatus != nil &&
		(*input.HTTPStatus < 100 || *input.HTTPStatus > 599) {
		return domain.AppErrorLog{}, ErrInvalidPayload
	}

	metadata, err := normalizeAppErrorMetadata(input.Metadata)
	if err != nil {
		return domain.AppErrorLog{}, err
	}

	now := time.Now().UTC()
	occurredAt := now
	if input.OccurredAt != nil {
		next := input.OccurredAt.UTC()
		if next.Before(now.Add(-maxAppErrorAgeWindow)) ||
			next.After(now.Add(maxAppErrorFutureWindow)) {
			return domain.AppErrorLog{}, ErrInvalidPayload
		}
		occurredAt = next
	}

	requestMethod := normalizeOptionalStringWithLimit(
		input.RequestMethod,
		maxAppErrorRequestMethodLen,
	)
	if requestMethod != nil {
		method := strings.ToUpper(*requestMethod)
		requestMethod = &method
	}

	log := domain.AppErrorLog{
		UserID:        normalizedUserID,
		SessionID:     sessionID,
		ScreenName:    normalizeOptionalStringWithLimit(input.ScreenName, maxAppErrorScreenNameLen),
		RoutePath:     normalizeOptionalStringWithLimit(input.RoutePath, maxAppErrorRoutePathLen),
		Source:        source,
		ErrorCode:     normalizeOptionalStringWithLimit(input.ErrorCode, maxAppErrorErrorCodeLen),
		Message:       message,
		StackTrace:    normalizeOptionalStringWithLimit(input.StackTrace, maxAppErrorStackTraceLen),
		RequestID:     normalizeOptionalStringWithLimit(input.RequestID, maxAppErrorRequestIDLen),
		RequestPath:   normalizeOptionalStringWithLimit(input.RequestPath, maxAppErrorRequestPathLen),
		RequestMethod: requestMethod,
		HTTPStatus:    input.HTTPStatus,
		Metadata:      metadata,
		OccurredAt:    occurredAt,
	}

	return uc.Logs.Create(ctx, log)
}

func normalizeStringWithLimit(value string, maxLen int) string {
	normalized := normalizeString(value)
	if normalized == "" || maxLen <= 0 {
		return normalized
	}

	runes := []rune(normalized)
	if len(runes) <= maxLen {
		return normalized
	}
	return string(runes[:maxLen])
}

func normalizeOptionalStringWithLimit(value *string, maxLen int) *string {
	normalized := normalizeOptionalString(value)
	if normalized == nil {
		return nil
	}
	limited := normalizeStringWithLimit(*normalized, maxLen)
	if limited == "" {
		return nil
	}
	return &limited
}

func normalizeAppErrorMetadata(raw json.RawMessage) (json.RawMessage, error) {
	if len(raw) == 0 {
		return nil, nil
	}
	if len(raw) > maxAppErrorMetadataInput {
		return nil, ErrInvalidPayload
	}

	var payload any
	if err := json.Unmarshal(raw, &payload); err != nil {
		return nil, ErrInvalidPayload
	}

	normalized, err := json.Marshal(payload)
	if err != nil {
		return nil, ErrInvalidPayload
	}
	if len(normalized) > maxAppErrorMetadataBytes {
		return nil, ErrInvalidPayload
	}

	return normalized, nil
}
