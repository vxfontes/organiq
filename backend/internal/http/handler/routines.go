package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type RoutinesHandler struct {
	Usecase  *usecase.RoutineUsecase
	Flags    *usecase.FlagUsecase
	Subflags *usecase.SubflagUsecase
}

func NewRoutinesHandler(uc *usecase.RoutineUsecase, flags *usecase.FlagUsecase, subflags *usecase.SubflagUsecase) *RoutinesHandler {
	return &RoutinesHandler{Usecase: uc, Flags: flags, Subflags: subflags}
}

// List routines.
// @Summary Listar rotinas
// @Tags Routines
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListRoutinesResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/routines [get]
func (h *RoutinesHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	routines, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	flagIDs := make([]string, 0)
	for _, routine := range routines {
		if routine.FlagID != nil {
			flagIDs = append(flagIDs, *routine.FlagID)
		}
	}

	flagsByID := make(map[string]domain.Flag)
	if h.Flags != nil && len(flagIDs) > 0 {
		ids := uniqueStrings(flagIDs)
		flags, err := h.Flags.GetByIDs(c.Request.Context(), userID, ids)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		flagsByID = flags
	}

	subflagsByID := make(map[string]domain.Subflag)
	if h.Subflags != nil {
		subflagIDs := make([]string, 0)
		for _, routine := range routines {
			if routine.SubflagID != nil {
				subflagIDs = append(subflagIDs, *routine.SubflagID)
			}
		}
		if len(subflagIDs) > 0 {
			subflags, err := h.Subflags.GetByIDs(c.Request.Context(), userID, subflagIDs)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			subflagsByID = subflags
		}
	}

	items := make([]dto.RoutineResponse, 0, len(routines))
	for _, routine := range routines {
		var flag *domain.Flag
		if routine.FlagID != nil {
			if f, ok := flagsByID[*routine.FlagID]; ok {
				flag = &f
			}
		}
		var subflag *domain.Subflag
		if routine.SubflagID != nil {
			if sf, ok := subflagsByID[*routine.SubflagID]; ok {
				subflag = &sf
			}
		}
		items = append(items, toRoutineResponse(routine, flag, subflag))
	}

	c.JSON(http.StatusOK, dto.ListRoutinesResponse{Items: items, NextCursor: next})
}

// ListByWeekday routines.
// @Summary Listar rotinas por dia da semana
// @Tags Routines
// @Security BearerAuth
// @Produce json
// @Param weekday path int true "Dia da semana (0-6, 0=domingo)"
// @Success 200 {object} dto.ListRoutinesResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/routines/day/{weekday} [get]
func (h *RoutinesHandler) ListByWeekday(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	weekdayStr := c.Param("weekday")
	weekday, err := strconv.Atoi(weekdayStr)
	if err != nil || weekday < 0 || weekday > 6 {
		writeError(c, http.StatusBadRequest, "invalid_weekday")
		return
	}

	date := c.Query("date")
	routines, err := h.Usecase.ListByWeekday(c.Request.Context(), userID, weekday, date)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	flagIDs := make([]string, 0)
	for _, routine := range routines {
		if routine.FlagID != nil {
			flagIDs = append(flagIDs, *routine.FlagID)
		}
	}

	flagsByID := make(map[string]domain.Flag)
	if h.Flags != nil && len(flagIDs) > 0 {
		ids := uniqueStrings(flagIDs)
		flags, err := h.Flags.GetByIDs(c.Request.Context(), userID, ids)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		flagsByID = flags
	}

	subflagsByID := make(map[string]domain.Subflag)
	if h.Subflags != nil {
		subflagIDs := make([]string, 0)
		for _, routine := range routines {
			if routine.SubflagID != nil {
				subflagIDs = append(subflagIDs, *routine.SubflagID)
			}
		}
		if len(subflagIDs) > 0 {
			subflags, err := h.Subflags.GetByIDs(c.Request.Context(), userID, uniqueStrings(subflagIDs))
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			subflagsByID = subflags
		}
	}

	items := make([]dto.RoutineResponse, 0, len(routines))
	for _, routine := range routines {
		var flag *domain.Flag
		if routine.FlagID != nil {
			if f, ok := flagsByID[*routine.FlagID]; ok {
				flag = &f
			}
		}
		var subflag *domain.Subflag
		if routine.SubflagID != nil {
			if sf, ok := subflagsByID[*routine.SubflagID]; ok {
				subflag = &sf
			}
		}
		items = append(items, toRoutineResponse(routine, flag, subflag))
	}

	c.JSON(http.StatusOK, dto.ListRoutinesResponse{Items: items})
}

// Get routine.
// @Summary Obter rotina
// @Tags Routines
// @Security BearerAuth
// @Produce json
// @Param id path string true "Routine ID"
// @Success 200 {object} dto.RoutineResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id} [get]
func (h *RoutinesHandler) Get(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	routine, err := h.Usecase.Get(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	if h.Flags != nil && routine.FlagID != nil {
		f, err := h.Flags.Get(c.Request.Context(), userID, *routine.FlagID)
		if err == nil {
			flag = &f
		}
	}

	var subflag *domain.Subflag
	if h.Subflags != nil && routine.SubflagID != nil {
		sf, err := h.Subflags.Get(c.Request.Context(), userID, *routine.SubflagID)
		if err == nil {
			subflag = &sf
		}
	}

	c.JSON(http.StatusOK, toRoutineResponse(routine, flag, subflag))
}

// Create routine.
// @Summary Criar rotina
// @Tags Routines
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateRoutineRequest true "Routine payload"
// @Success 201 {object} dto.RoutineResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/routines [post]
func (h *RoutinesHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateRoutineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	routine, err := h.Usecase.Create(c.Request.Context(), userID, usecase.RoutineInput{
		Title:          req.Title,
		Description:    req.Description,
		RecurrenceType: getStringOrDefault(req.RecurrenceType, "weekly"),
		Weekdays:       req.Weekdays,
		StartTime:      req.StartTime,
		EndTime:        req.EndTime,
		WeekOfMonth:    req.WeekOfMonth,
		StartsOn:       req.StartsOn,
		EndsOn:         req.EndsOn,
		Color:          req.Color,
		FlagID:         req.FlagID,
		SubflagID:      req.SubflagID,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	var subflag *domain.Subflag
	if h.Flags != nil && routine.FlagID != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, *routine.FlagID); err == nil {
			flag = &f
		}
	}
	if h.Subflags != nil && routine.SubflagID != nil {
		if sf, err := h.Subflags.Get(c.Request.Context(), userID, *routine.SubflagID); err == nil {
			subflag = &sf
		}
	}

	c.JSON(http.StatusCreated, toRoutineResponse(routine, flag, subflag))
}

// Update routine.
// @Summary Atualizar rotina
// @Tags Routines
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Routine ID"
// @Param body body dto.UpdateRoutineRequest true "Routine payload"
// @Success 200 {object} dto.RoutineResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id} [patch]
func (h *RoutinesHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateRoutineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	routine, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.RoutineUpdateInput{
		Title:          req.Title,
		Description:    req.Description,
		RecurrenceType: req.RecurrenceType,
		Weekdays:       req.Weekdays,
		StartTime:      req.StartTime,
		EndTime:        req.EndTime,
		WeekOfMonth:    req.WeekOfMonth,
		StartsOn:       req.StartsOn,
		EndsOn:         req.EndsOn,
		Color:          req.Color,
		FlagID:         req.FlagID,
		SubflagID:      req.SubflagID,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	var subflag *domain.Subflag
	if h.Flags != nil && routine.FlagID != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, *routine.FlagID); err == nil {
			flag = &f
		}
	}
	if h.Subflags != nil && routine.SubflagID != nil {
		if sf, err := h.Subflags.Get(c.Request.Context(), userID, *routine.SubflagID); err == nil {
			subflag = &sf
		}
	}

	c.JSON(http.StatusOK, toRoutineResponse(routine, flag, subflag))
}

// Delete routine.
// @Summary Excluir rotina
// @Tags Routines
// @Security BearerAuth
// @Param id path string true "Routine ID"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id} [delete]
func (h *RoutinesHandler) Delete(c *gin.Context) {
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

// Toggle routine.
// @Summary Ativar/desativar rotina
// @Tags Routines
// @Security BearerAuth
// @Accept json
// @Param id path string true "Routine ID"
// @Param body body dto.ToggleRoutineRequest true "Toggle payload"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id}/toggle [patch]
func (h *RoutinesHandler) Toggle(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.ToggleRoutineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	if err := h.Usecase.Toggle(c.Request.Context(), userID, id, req.IsActive); err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}

// Complete routine.
// @Summary Marcar rotina como concluída
// @Tags Routines
// @Security BearerAuth
// @Produce json
// @Param id path string true "Routine ID"
// @Param body body dto.CompleteRoutineRequest false "Data (opcional, padrão: hoje)"
// @Success 201 {object} dto.RoutineCompletionResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id}/complete [post]
func (h *RoutinesHandler) Complete(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.CompleteRoutineRequest
	c.ShouldBindJSON(&req)

	completion, err := h.Usecase.Complete(c.Request.Context(), userID, id, req.Date)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, dto.RoutineCompletionResponse{
		ID:          completion.ID,
		RoutineID:   completion.RoutineID,
		CompletedOn: completion.CompletedOn,
		CompletedAt: completion.CompletedAt,
	})
}

// Uncomplete routine.
// @Summary Desmarcar conclusão de rotina
// @Tags Routines
// @Security BearerAuth
// @Param id path string true "Routine ID"
// @Param date path string true "Data da conclusão"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id}/complete/{date} [delete]
func (h *RoutinesHandler) Uncomplete(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")
	date := c.Param("date")

	if err := h.Usecase.Uncomplete(c.Request.Context(), userID, id, date); err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}

// GetHistory routine.
// @Summary Obter histórico de conclusões
// @Tags Routines
// @Security BearerAuth
// @Produce json
// @Param id path string true "Routine ID"
// @Success 200 {array} dto.RoutineCompletionResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id}/history [get]
func (h *RoutinesHandler) GetHistory(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	completions, err := h.Usecase.GetCompletions(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	items := make([]dto.RoutineCompletionResponse, 0, len(completions))
	for _, completion := range completions {
		items = append(items, dto.RoutineCompletionResponse{
			ID:          completion.ID,
			RoutineID:   completion.RoutineID,
			CompletedOn: completion.CompletedOn,
			CompletedAt: completion.CompletedAt,
		})
	}

	c.JSON(http.StatusOK, items)
}

// GetStreak routine.
// @Summary Obter streak da rotina
// @Tags Routines
// @Security BearerAuth
// @Produce json
// @Param id path string true "Routine ID"
// @Success 200 {object} dto.RoutineStreakResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id}/streak [get]
func (h *RoutinesHandler) GetStreak(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	currentStreak, totalCompletions, streakText, activity, err := h.Usecase.GetStreak(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	activityDTO := make([]dto.RoutineActivityDay, 0, len(activity))
	for _, a := range activity {
		activityDTO = append(activityDTO, dto.RoutineActivityDay{
			Date:         a.Date,
			IsCompleted:  a.IsCompleted,
			IsScheduled:  a.IsScheduled,
			IsToday:      a.IsToday,
			IsSkipped:    a.IsSkipped,
			WeekdayLabel: a.WeekdayLabel,
		})
	}

	c.JSON(http.StatusOK, dto.RoutineStreakResponse{
		CurrentStreak:    currentStreak,
		TotalCompletions: totalCompletions,
		StreakText:       streakText,
		Activity:         activityDTO,
	})
}

// CreateException routine.
// @Summary Criar exceção de rotina
// @Tags Routines
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Routine ID"
// @Param body body dto.CreateRoutineExceptionRequest true "Exception payload"
// @Success 201 {object} dto.RoutineExceptionResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id}/exceptions [post]
func (h *RoutinesHandler) CreateException(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.CreateRoutineExceptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	action := "skip"
	if req.Action != nil {
		action = *req.Action
	}

	exception, err := h.Usecase.CreateException(c.Request.Context(), userID, id, req.ExceptionDate, action, req.NewStartTime, req.NewEndTime, req.Reason)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, dto.RoutineExceptionResponse{
		ID:            exception.ID,
		RoutineID:     exception.RoutineID,
		ExceptionDate: exception.ExceptionDate,
		Action:        exception.Action,
		NewStartTime:  exception.NewStartTime,
		NewEndTime:    exception.NewEndTime,
		Reason:        exception.Reason,
		CreatedAt:     exception.CreatedAt,
	})
}

// DeleteException routine.
// @Summary Cancelar exceção de rotina
// @Tags Routines
// @Security BearerAuth
// @Param id path string true "Routine ID"
// @Param date path string true "Data da exceção"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/routines/{id}/exceptions/{date} [delete]
func (h *RoutinesHandler) DeleteException(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")
	date := c.Param("date")

	if err := h.Usecase.DeleteException(c.Request.Context(), userID, id, date); err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}

// GetTodaySummary routine.
// @Summary Resumo do dia
// @Tags Routines
// @Security BearerAuth
// @Produce json
// @Success 200 {object} dto.RoutineTodaySummaryResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/routines/today/summary [get]
func (h *RoutinesHandler) GetTodaySummary(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	total, completed, err := h.Usecase.GetTodaySummary(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, dto.RoutineTodaySummaryResponse{
		Total:     total,
		Completed: completed,
	})
}

func getStringOrDefault(ptr *string, defaultValue string) string {
	if ptr == nil {
		return defaultValue
	}
	return *ptr
}
