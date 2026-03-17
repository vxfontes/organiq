package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/usecase"
)

type AuthHandler struct {
	Usecase *usecase.AuthUsecase
}

type AuthRequest struct {
	Email       string `json:"email" binding:"required"`
	Password    string `json:"password" binding:"required"`
	DisplayName string `json:"displayName" binding:"required"`
	Locale      string `json:"locale" binding:"required"`
	Timezone    string `json:"timezone" binding:"required"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type AuthResponse struct {
	Token string `json:"token"`
	User  struct {
		ID          string `json:"id"`
		Email       string `json:"email"`
		DisplayName string `json:"displayName"`
		Locale      string `json:"locale"`
		Timezone    string `json:"timezone"`
	} `json:"user"`
}

func NewAuthHandler(uc *usecase.AuthUsecase) *AuthHandler {
	return &AuthHandler{Usecase: uc}
}

// Signup creates a new account.
// @Summary Criar conta
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body AuthRequest true "Auth request"
// @Success 201 {object} AuthResponse
// @Failure 400 {object} map[string]string
// @Router /v1/auth/signup [post]
func (h *AuthHandler) Signup(c *gin.Context) {
	var req AuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	user, token, err := h.Usecase.Signup(c.Request.Context(), req.Email, req.Password, req.DisplayName, req.Locale, req.Timezone)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	resp := toAuthResponse(user, token)
	c.JSON(http.StatusCreated, resp)
}

// Login with email and password.
// @Summary Login
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body LoginRequest true "Login request"
// @Success 200 {object} AuthResponse
// @Failure 401 {object} map[string]string
// @Router /v1/auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	user, token, err := h.Usecase.Login(c.Request.Context(), req.Email, req.Password)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	resp := toAuthResponse(user, token)
	c.JSON(http.StatusOK, resp)
}

func toAuthResponse(user domain.User, token string) AuthResponse {
	var resp AuthResponse
	resp.Token = token
	resp.User.ID = user.ID
	resp.User.Email = user.Email
	resp.User.DisplayName = user.DisplayName
	resp.User.Locale = user.Locale
	resp.User.Timezone = user.Timezone
	return resp
}
