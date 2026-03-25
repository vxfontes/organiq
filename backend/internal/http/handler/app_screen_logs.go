package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type AppScreenLogsHandler struct {
	Usecase *usecase.AppScreenLogUsecase
}

func NewAppScreenLogsHandler(uc *usecase.AppScreenLogUsecase) *AppScreenLogsHandler {
	return &AppScreenLogsHandler{Usecase: uc}
}

// Create screen/app interaction log.
// @Summary Registrar log de tela
// @Tags App Logs
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateAppScreenLogRequest true "Screen log payload"
// @Success 201 {object} dto.AppScreenLogResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/app-logs/screens [post]
func (h *AppScreenLogsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateAppScreenLogRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	log, err := h.Usecase.Create(c.Request.Context(), userID, usecase.AppScreenLogInput{
		SessionID:         req.SessionID,
		ScreenName:        req.ScreenName,
		RoutePath:         req.RoutePath,
		PreviousRoutePath: req.PreviousRoutePath,
		EventName:         req.EventName,
		Platform:          req.Platform,
		AppVersion:        req.AppVersion,
		Metadata:          req.Metadata,
		OccurredAt:        req.OccurredAt,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toAppScreenLogResponse(log))
}

func toAppScreenLogResponse(log domain.AppScreenLog) dto.AppScreenLogResponse {
	return dto.AppScreenLogResponse{
		ID:                log.ID,
		SessionID:         log.SessionID,
		ScreenName:        log.ScreenName,
		RoutePath:         log.RoutePath,
		PreviousRoutePath: log.PreviousRoutePath,
		EventName:         log.EventName,
		Platform:          log.Platform,
		AppVersion:        log.AppVersion,
		Metadata:          log.Metadata,
		OccurredAt:        log.OccurredAt,
		CreatedAt:         log.CreatedAt,
	}
}
