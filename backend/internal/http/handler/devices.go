package handler

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type DevicesHandler struct {
	Usecase *usecase.DeviceTokenUsecase
}

func NewDevicesHandler(uc *usecase.DeviceTokenUsecase) *DevicesHandler {
	return &DevicesHandler{Usecase: uc}
}

// RegisterToken registers or updates a device push token.
// @Summary Registrar dispositivo
// @Tags Devices
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.RegisterTokenRequest true "Register device request"
// @Success 200 {object} dto.RegisterTokenResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/devices/token [post]
func (h *DevicesHandler) RegisterToken(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.RegisterTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	deviceName := ""
	if req.DeviceName != nil {
		deviceName = *req.DeviceName
	}
	appVersion := ""
	if req.AppVersion != nil {
		appVersion = *req.AppVersion
	}

	err := h.Usecase.RegisterToken(
		c.Request.Context(),
		userID,
		req.DeviceID,
		req.PushToken,
		req.Platform,
		deviceName,
		appVersion,
	)
	if err != nil {
		slog.Warn("device_token_register_failed",
			slog.String("user_id", userID),
			slog.String("device_id", req.DeviceID),
			slog.String("platform", req.Platform),
			slog.String("error", err.Error()),
		)
		writeUsecaseError(c, err)
		return
	}

	slog.Info("device_token_registered",
		slog.String("user_id", userID),
		slog.String("device_id", req.DeviceID),
		slog.String("platform", req.Platform),
		slog.String("app_version", appVersion),
	)

	c.JSON(http.StatusOK, dto.RegisterTokenResponse{Status: "ok"})
}

// UnregisterToken removes a device subscription.
// @Summary Remover dispositivo
// @Tags Devices
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.UnregisterTokenRequest true "Unregister device request"
// @Success 200 {object} map[string]string
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/devices/token [delete]
func (h *DevicesHandler) UnregisterToken(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.UnregisterTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	err := h.Usecase.UnregisterToken(c.Request.Context(), req.DeviceID, userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}
