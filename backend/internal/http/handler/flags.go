package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type FlagsHandler struct {
	Usecase *usecase.FlagUsecase
}

func NewFlagsHandler(uc *usecase.FlagUsecase) *FlagsHandler {
	return &FlagsHandler{Usecase: uc}
}

// List flags.
// @Summary Listar flags
// @Tags Flags
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListFlagsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/flags [get]
func (h *FlagsHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	flags, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	items := make([]dto.FlagResponse, 0, len(flags))
	for _, flag := range flags {
		items = append(items, toFlagResponse(flag))
	}

	c.JSON(http.StatusOK, dto.ListFlagsResponse{Items: items, NextCursor: next})
}

// Create flag.
// @Summary Criar flag
// @Tags Flags
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateFlagRequest true "Flag payload"
// @Success 201 {object} dto.FlagResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/flags [post]
func (h *FlagsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateFlagRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	flag, err := h.Usecase.Create(c.Request.Context(), userID, req.Name, req.Color, req.SortOrder)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toFlagResponse(flag))
}

// Update flag.
// @Summary Atualizar flag
// @Tags Flags
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Flag ID"
// @Param body body dto.UpdateFlagRequest true "Flag payload"
// @Success 200 {object} dto.FlagResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/flags/{id} [patch]
func (h *FlagsHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateFlagRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	flag, err := h.Usecase.Update(c.Request.Context(), userID, id, req.Name, req.Color, req.SortOrder)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toFlagResponse(flag))
}

// Delete flag.
// @Summary Remover flag
// @Tags Flags
// @Security BearerAuth
// @Param id path string true "Flag ID"
// @Success 204 {object} nil
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/flags/{id} [delete]
func (h *FlagsHandler) Delete(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	if err := h.Usecase.Delete(c.Request.Context(), userID, id); err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}
