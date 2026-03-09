package handler

import (
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/digest"
	"inbota/backend/internal/infra/postgres"
)

type DigestHandler struct {
	digestService *digest.DigestService
}

func NewDigestHandler(digestService *digest.DigestService) *DigestHandler {
	return &DigestHandler{digestService: digestService}
}

// GetDailySummary returns a consolidated daily summary for the user.
// @Summary Resumo diário público
// @Description Retorna o resumo consolidado do dia do usuário (rotinas, agenda, tarefas, compras).
// @Tags Digest
// @Produce json
// @Param token query string true "Daily summary token"
// @Success 200 {object} digest.DigestData
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 500 {object} dto.ErrorResponse
// @Router /v1/daily-summary [get]
func (h *DigestHandler) GetDailySummary(c *gin.Context) {

	token := c.Query("token")
	if token == "" {
		writeError(c, http.StatusBadRequest, "missing_token")
		return
	}

	userID, err := h.digestService.ResolveUserIDByDailySummaryToken(c.Request.Context(), token)
	if err != nil {
		if errors.Is(err, postgres.ErrNotFound) {
			writeError(c, http.StatusUnauthorized, "invalid_token")
			return
		}
		writeUsecaseError(c, err)
		return
	}

	// We'll use a fixed time for "today" in the user's local day,
	// but BuildDigestData handles time.Now() if we pass zero time or we can pass it explicitly.
	// For simplicity and since it's a "daily summary", we use the current time.
	data, err := h.digestService.BuildDigestData(c.Request.Context(), userID, time.Now())
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *DigestHandler) SendTestEmail(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	err := h.digestService.SendTestDigestForUserID(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}
