package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/app/service"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
	"inbota/backend/internal/http/middleware"
	"inbota/backend/internal/infra/postgres"
)

func getUserID(c *gin.Context) (string, bool) {
	userID := middleware.GetUserID(c)
	if userID == "" {
		writeError(c, http.StatusUnauthorized, "unauthorized")
		return "", false
	}
	return userID, true
}

func parseListOptions(c *gin.Context) (repository.ListOptions, bool) {
	var opts repository.ListOptions
	if limitStr := c.Query("limit"); limitStr != "" {
		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit < 0 {
			writeError(c, http.StatusBadRequest, "invalid_limit")
			return repository.ListOptions{}, false
		}
		opts.Limit = limit
	}
	opts.Cursor = c.Query("cursor")
	return opts, true
}

func writeError(c *gin.Context, status int, code string) {
	resp := dto.ErrorResponse{
		Error:     code,
		RequestID: middleware.GetRequestID(c),
	}
	c.JSON(status, resp)
}

func writeUsecaseError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, usecase.ErrMissingRequiredFields):
		writeError(c, http.StatusBadRequest, "missing_required_fields")
	case errors.Is(err, usecase.ErrInvalidStatus):
		writeError(c, http.StatusBadRequest, "invalid_status")
	case errors.Is(err, usecase.ErrInvalidType):
		writeError(c, http.StatusBadRequest, "invalid_type")
	case errors.Is(err, usecase.ErrInvalidSource):
		writeError(c, http.StatusBadRequest, "invalid_source")
	case errors.Is(err, usecase.ErrInvalidPayload):
		writeError(c, http.StatusBadRequest, "invalid_payload")
	case errors.Is(err, usecase.ErrInvalidTimeRange):
		writeError(c, http.StatusBadRequest, "invalid_time_range")
	case errors.Is(err, usecase.ErrInvalidEmail):
		writeError(c, http.StatusBadRequest, "invalid_email")
	case errors.Is(err, usecase.ErrInvalidPassword):
		writeError(c, http.StatusBadRequest, "invalid_password")
	case errors.Is(err, usecase.ErrInvalidDisplayName):
		writeError(c, http.StatusBadRequest, "invalid_display_name")
	case errors.Is(err, usecase.ErrRoutineOverlap):
		writeError(c, http.StatusConflict, "routine_overlap")
	case errors.Is(err, usecase.ErrInvalidCredentials):
		writeError(c, http.StatusUnauthorized, "invalid_credentials")
	case errors.Is(err, usecase.ErrDependencyMissing):
		writeError(c, http.StatusInternalServerError, "dependency_missing")
	case errors.Is(err, service.ErrAISchemaInvalid):
		writeError(c, http.StatusBadRequest, "invalid_payload")
	case errors.Is(err, postgres.ErrInvalidCursor):
		writeError(c, http.StatusBadRequest, "invalid_cursor")
	case errors.Is(err, postgres.ErrNotFound):
		writeError(c, http.StatusNotFound, "not_found")
	default:
		writeError(c, http.StatusInternalServerError, "internal_error")
	}
}

func uniqueStrings(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	out := make([]string, 0, len(values))
	for _, v := range values {
		if v == "" {
			continue
		}
		if _, ok := seen[v]; ok {
			continue
		}
		seen[v] = struct{}{}
		out = append(out, v)
	}
	return out
}
