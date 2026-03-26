package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
	"organiq/backend/internal/http/middleware"
)

type AppErrorLogsHandler struct {
	Usecase *usecase.AppErrorLogUsecase
}

func NewAppErrorLogsHandler(uc *usecase.AppErrorLogUsecase) *AppErrorLogsHandler {
	return &AppErrorLogsHandler{Usecase: uc}
}

// Create app error log.
// @Summary Registrar log de erro do app
// @Tags App Logs
// @Accept json
// @Produce json
// @Param body body dto.CreateAppErrorLogRequest true "App error log payload"
// @Success 201 {object} dto.AppErrorLogResponse
// @Failure 400 {object} dto.ErrorResponse
// @Router /v1/app-logs/errors [post]
func (h *AppErrorLogsHandler) Create(c *gin.Context) {
	var req dto.CreateAppErrorLogRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	var userID *string
	if current := middleware.GetUserID(c); current != "" {
		userID = &current
	}

	log, err := h.Usecase.Create(c.Request.Context(), userID, usecase.AppErrorLogInput{
		SessionID:     req.SessionID,
		ScreenName:    req.ScreenName,
		RoutePath:     req.RoutePath,
		Source:        req.Source,
		ErrorCode:     req.ErrorCode,
		Message:       req.Message,
		StackTrace:    req.StackTrace,
		RequestID:     req.RequestID,
		RequestPath:   req.RequestPath,
		RequestMethod: req.RequestMethod,
		HTTPStatus:    req.HTTPStatus,
		Metadata:      req.Metadata,
		OccurredAt:    req.OccurredAt,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toAppErrorLogResponse(log))
}

func toAppErrorLogResponse(log domain.AppErrorLog) dto.AppErrorLogResponse {
	return dto.AppErrorLogResponse{
		ID:            log.ID,
		SessionID:     log.SessionID,
		ScreenName:    log.ScreenName,
		RoutePath:     log.RoutePath,
		Source:        log.Source,
		ErrorCode:     log.ErrorCode,
		Message:       log.Message,
		StackTrace:    log.StackTrace,
		RequestID:     log.RequestID,
		RequestPath:   log.RequestPath,
		RequestMethod: log.RequestMethod,
		HTTPStatus:    log.HTTPStatus,
		Metadata:      log.Metadata,
		OccurredAt:    log.OccurredAt,
		CreatedAt:     log.CreatedAt,
	}
}
