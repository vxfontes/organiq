package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type SubflagsHandler struct {
	Usecase *usecase.SubflagUsecase
	Flags   *usecase.FlagUsecase
}

func NewSubflagsHandler(uc *usecase.SubflagUsecase, flags *usecase.FlagUsecase) *SubflagsHandler {
	return &SubflagsHandler{Usecase: uc, Flags: flags}
}

// List subflags by flag.
// @Summary Listar subflags por flag
// @Tags Subflags
// @Security BearerAuth
// @Produce json
// @Param id path string true "Flag ID"
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListSubflagsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/flags/{id}/subflags [get]
func (h *SubflagsHandler) ListByFlag(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	flagID := c.Param("id")
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	subflags, next, err := h.Usecase.ListByFlag(c.Request.Context(), userID, flagID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	if h.Flags != nil {
		f, err := h.Flags.Get(c.Request.Context(), userID, flagID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		flag = &f
	}

	items := make([]dto.SubflagResponse, 0, len(subflags))
	for _, subflag := range subflags {
		items = append(items, toSubflagResponse(subflag, flag))
	}

	c.JSON(http.StatusOK, dto.ListSubflagsResponse{Items: items, NextCursor: next})
}

// Create subflag.
// @Summary Criar subflag
// @Tags Subflags
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Flag ID"
// @Param body body dto.CreateSubflagRequest true "Subflag payload"
// @Success 201 {object} dto.SubflagResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/flags/{id}/subflags [post]
func (h *SubflagsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	flagID := c.Param("id")

	var req dto.CreateSubflagRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	subflag, err := h.Usecase.Create(c.Request.Context(), userID, flagID, req.Name, req.SortOrder)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	if h.Flags != nil {
		f, err := h.Flags.Get(c.Request.Context(), userID, subflag.FlagID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		flag = &f
	}

	c.JSON(http.StatusCreated, toSubflagResponse(subflag, flag))
}

// Update subflag.
// @Summary Atualizar subflag
// @Tags Subflags
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Subflag ID"
// @Param body body dto.UpdateSubflagRequest true "Subflag payload"
// @Success 200 {object} dto.SubflagResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/subflags/{id} [patch]
func (h *SubflagsHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateSubflagRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	subflag, err := h.Usecase.Update(c.Request.Context(), userID, id, req.Name, req.SortOrder)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	if h.Flags != nil {
		f, err := h.Flags.Get(c.Request.Context(), userID, subflag.FlagID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		flag = &f
	}

	c.JSON(http.StatusOK, toSubflagResponse(subflag, flag))
}

// Delete subflag.
// @Summary Remover subflag
// @Tags Subflags
// @Security BearerAuth
// @Param id path string true "Subflag ID"
// @Success 204 {object} nil
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/subflags/{id} [delete]
func (h *SubflagsHandler) Delete(c *gin.Context) {
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
