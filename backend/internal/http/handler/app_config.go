package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type AppConfigHandler struct {
	Usecase *usecase.AppConfigUsecase
}

func NewAppConfigHandler(uc *usecase.AppConfigUsecase) *AppConfigHandler {
	return &AppConfigHandler{Usecase: uc}
}

// GetAIConfig returns AI feature flags sourced from app_config table.
// @Summary Obter configuração de IA do app
// @Tags AppConfig
// @Security BearerAuth
// @Produce json
// @Success 200 {object} dto.AppConfigAIResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/app-config/ai [get]
func (h *AppConfigHandler) GetAIConfig(c *gin.Context) {
	if _, ok := getUserID(c); !ok {
		return
	}
	if h.Usecase == nil {
		writeError(c, http.StatusInternalServerError, "dependency_missing")
		return
	}

	cfg, err := h.Usecase.GetAIConfig(c.Request.Context())
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, dto.AppConfigAIResponse{
		CreateAIEnabled:                  cfg.CreateEnabled,
		SuggestionAIEnabled:              cfg.SuggestionEnabled,
		SettingsNotificationsAdminEmails: cfg.SettingsAdminEmails,
	})
}
