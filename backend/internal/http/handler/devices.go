package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type DevicesHandler struct {
	Usecase *usecase.DeviceTokenUsecase
}

func NewDevicesHandler(uc *usecase.DeviceTokenUsecase) *DevicesHandler {
	return &DevicesHandler{Usecase: uc}
}

// RegisterToken registers or updates a device token.
// @Summary Registrar token de dispositivo
// @Tags Devices
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.RegisterTokenRequest true "Register token request"
// @Success 200 {object} map[string]string
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

	err := h.Usecase.RegisterToken(c.Request.Context(), userID, req.Token, req.Platform, deviceName, appVersion)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// UnregisterToken removes a device token.
// @Summary Remover token de dispositivo
// @Tags Devices
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.RegisterTokenRequest true "Unregister token request (only token needed)"
// @Success 200 {object} map[string]string
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/devices/token [delete]
func (h *DevicesHandler) UnregisterToken(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.RegisterTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	err := h.Usecase.UnregisterToken(c.Request.Context(), req.Token, userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}
