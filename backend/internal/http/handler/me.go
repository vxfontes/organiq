package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type MeHandler struct {
	Users *usecase.AuthUsecase
}

func NewMeHandler(users *usecase.AuthUsecase) *MeHandler {
	return &MeHandler{Users: users}
}

// Me returns the current user profile from the JWT subject.
// @Summary Obter perfil do usuario logado
// @Tags Me
// @Security BearerAuth
// @Produce json
// @Success 200 {object} dto.AuthResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/me [get]
func (h *MeHandler) Me(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	if h.Users == nil || h.Users.Users == nil {
		writeError(c, http.StatusInternalServerError, "dependency_missing")
		return
	}

	user, err := h.Users.Users.Get(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var resp dto.AuthResponse
	resp.User.ID = user.ID
	resp.User.Email = user.Email
	resp.User.DisplayName = user.DisplayName
	resp.User.Locale = user.Locale
	resp.User.Timezone = user.Timezone
	c.JSON(http.StatusOK, resp)
}
