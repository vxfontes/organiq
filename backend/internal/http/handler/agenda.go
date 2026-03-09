package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type AgendaHandler struct {
	Agenda *usecase.AgendaUsecase
}

func NewAgendaHandler(
	agenda *usecase.AgendaUsecase,
) *AgendaHandler {
	return &AgendaHandler{
		Agenda: agenda,
	}
}

// List agenda items.
// @Summary Listar agenda consolidada
// @Tags Agenda
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite de itens. Max 200."
// @Success 200 {object} dto.AgendaResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/agenda [get]
func (h *AgendaHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	if h.Agenda == nil {
		writeUsecaseError(c, usecase.ErrDependencyMissing)
		return
	}

	limit := 200
	if limitStr := c.Query("limit"); limitStr != "" {
		parsed, err := strconv.Atoi(limitStr)
		if err != nil || parsed < 0 {
			writeError(c, http.StatusBadRequest, "invalid_limit")
			return
		}
		limit = parsed
	}
	opts := repository.ListOptions{Limit: limit}

	items, err := h.Agenda.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	eventItems := make([]dto.EventResponse, 0)
	taskItems := make([]dto.TaskResponse, 0)
	reminderItems := make([]dto.ReminderResponse, 0)

	for _, item := range items {
		var flag *dto.FlagObject
		if item.FlagName != nil {
			flag = &dto.FlagObject{
				ID:    "",
				Name:  *item.FlagName,
				Color: item.FlagColor,
			}
			if item.ResolvedFlagID != nil {
				flag.ID = *item.ResolvedFlagID
			} else if item.FlagID != nil {
				flag.ID = *item.FlagID
			}
		}

		var subflag *dto.SubflagObject
		if item.SubflagName != nil {
			subflag = &dto.SubflagObject{
				ID:    "",
				Name:  *item.SubflagName,
				Color: item.SubflagColor,
			}
			if item.SubflagID != nil {
				subflag.ID = *item.SubflagID
			}
		}

		switch item.ItemType {
		case "event":
			startAt := item.StartAt
			if startAt == nil {
				v := item.ScheduledAt
				startAt = &v
			}

			allDay := false
			if item.AllDay != nil {
				allDay = *item.AllDay
			}

			eventItems = append(eventItems, dto.EventResponse{
				ID:        item.ID,
				Title:     item.Title,
				StartAt:   startAt,
				EndAt:     item.EndAt,
				AllDay:    allDay,
				Location:  item.Location,
				Flag:      flag,
				Subflag:   subflag,
				CreatedAt: item.CreatedAt,
				UpdatedAt: item.UpdatedAt,
			})
		case "task":
			taskItems = append(taskItems, dto.TaskResponse{
				ID:          item.ID,
				Title:       item.Title,
				Description: item.Description,
				Status:      item.Status,
				DueAt:       item.DueAt,
				Flag:        flag,
				Subflag:     subflag,
				CreatedAt:   item.CreatedAt,
				UpdatedAt:   item.UpdatedAt,
			})
		case "reminder":
			reminderItems = append(reminderItems, dto.ReminderResponse{
				ID:        item.ID,
				Title:     item.Title,
				Status:    item.Status,
				RemindAt:  item.RemindAt,
				Flag:      flag,
				Subflag:   subflag,
				CreatedAt: item.CreatedAt,
				UpdatedAt: item.UpdatedAt,
			})
		}
	}

	c.JSON(http.StatusOK, dto.AgendaResponse{
		Events:    eventItems,
		Tasks:     taskItems,
		Reminders: reminderItems,
	})
}
