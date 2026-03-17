package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type RemindersHandler struct {
	Usecase  *usecase.ReminderUsecase
	Inbox    *usecase.InboxUsecase
	Flags    *usecase.FlagUsecase
	Subflags *usecase.SubflagUsecase
}

func NewRemindersHandler(uc *usecase.ReminderUsecase, inbox *usecase.InboxUsecase, flags *usecase.FlagUsecase, subflags *usecase.SubflagUsecase) *RemindersHandler {
	return &RemindersHandler{Usecase: uc, Inbox: inbox, Flags: flags, Subflags: subflags}
}

// List reminders.
// @Summary Listar lembretes
// @Tags Reminders
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListRemindersResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/reminders [get]
func (h *RemindersHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	reminders, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	sourceIDs := make([]string, 0)
	for _, reminder := range reminders {
		if reminder.SourceInboxItemID != nil {
			sourceIDs = append(sourceIDs, *reminder.SourceInboxItemID)
		}
	}

	sourcesByID := make(map[string]domain.InboxItem)
	if h.Inbox != nil {
		ids := uniqueStrings(sourceIDs)
		if len(ids) > 0 {
			items, err := h.Inbox.GetInboxItemsByIDs(c.Request.Context(), userID, ids)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			sourcesByID = items
		}
	}

	subflagIDs := make([]string, 0)
	for _, reminder := range reminders {
		if reminder.SubflagID != nil {
			subflagIDs = append(subflagIDs, *reminder.SubflagID)
		}
	}

	subflagsByID := make(map[string]domain.Subflag)
	if h.Subflags != nil {
		ids := uniqueStrings(subflagIDs)
		if len(ids) > 0 {
			subflags, err := h.Subflags.GetByIDs(c.Request.Context(), userID, ids)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			subflagsByID = subflags
		}
	}

	flagIDs := make([]string, 0)
	for _, reminder := range reminders {
		if reminder.FlagID != nil {
			flagIDs = append(flagIDs, *reminder.FlagID)
		}
	}
	for _, subflag := range subflagsByID {
		flagIDs = append(flagIDs, subflag.FlagID)
	}

	flagsByID := make(map[string]domain.Flag)
	if h.Flags != nil {
		ids := uniqueStrings(flagIDs)
		if len(ids) > 0 {
			flags, err := h.Flags.GetByIDs(c.Request.Context(), userID, ids)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			flagsByID = flags
		}
	}

	items := make([]dto.ReminderResponse, 0, len(reminders))
	for _, reminder := range reminders {
		var source *domain.InboxItem
		if reminder.SourceInboxItemID != nil {
			if item, ok := sourcesByID[*reminder.SourceInboxItemID]; ok {
				source = &item
			}
		}
		var flag *domain.Flag
		if reminder.FlagID != nil {
			if f, ok := flagsByID[*reminder.FlagID]; ok {
				flag = &f
			}
		}
		var subflag *domain.Subflag
		if reminder.SubflagID != nil {
			if sf, ok := subflagsByID[*reminder.SubflagID]; ok {
				subflag = &sf
			}
		}
		if flag == nil && subflag != nil {
			if f, ok := flagsByID[subflag.FlagID]; ok {
				flag = &f
			}
		}
		items = append(items, toReminderResponse(reminder, source, flag, subflag))
	}

	c.JSON(http.StatusOK, dto.ListRemindersResponse{Items: items, NextCursor: next})
}

// Create reminder.
// @Summary Criar lembrete
// @Tags Reminders
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateReminderRequest true "Reminder payload"
// @Success 201 {object} dto.ReminderResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/reminders [post]
func (h *RemindersHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	reminder, err := h.Usecase.Create(c.Request.Context(), userID, req.Title, req.Status, req.RemindAt, req.FlagID, req.SubflagID, nil)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	var subflag *domain.Subflag
	if h.Flags != nil && reminder.FlagID != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, *reminder.FlagID); err == nil {
			flag = &f
		} else {
			writeUsecaseError(c, err)
			return
		}
	}
	if h.Subflags != nil && reminder.SubflagID != nil {
		if sf, err := h.Subflags.Get(c.Request.Context(), userID, *reminder.SubflagID); err == nil {
			subflag = &sf
		} else {
			writeUsecaseError(c, err)
			return
		}
	}
	if flag == nil && subflag != nil && h.Flags != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, subflag.FlagID); err == nil {
			flag = &f
		} else {
			writeUsecaseError(c, err)
			return
		}
	}

	c.JSON(http.StatusCreated, toReminderResponse(reminder, nil, flag, subflag))
}

// Update reminder.
// @Summary Atualizar lembrete
// @Tags Reminders
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Reminder ID"
// @Param body body dto.UpdateReminderRequest true "Reminder payload"
// @Success 200 {object} dto.ReminderResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/reminders/{id} [patch]
func (h *RemindersHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	reminder, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.ReminderUpdateInput{
		Title:     req.Title,
		Status:    req.Status,
		RemindAt:  req.RemindAt,
		FlagID:    req.FlagID,
		SubflagID: req.SubflagID,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var source *domain.InboxItem
	if h.Inbox != nil && reminder.SourceInboxItemID != nil {
		res, err := h.Inbox.GetInboxItem(c.Request.Context(), userID, *reminder.SourceInboxItemID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		source = &res.Item
	}

	var flag *domain.Flag
	var subflag *domain.Subflag
	if h.Flags != nil && reminder.FlagID != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, *reminder.FlagID); err == nil {
			flag = &f
		} else {
			writeUsecaseError(c, err)
			return
		}
	}
	if h.Subflags != nil && reminder.SubflagID != nil {
		if sf, err := h.Subflags.Get(c.Request.Context(), userID, *reminder.SubflagID); err == nil {
			subflag = &sf
		} else {
			writeUsecaseError(c, err)
			return
		}
	}
	if flag == nil && subflag != nil && h.Flags != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, subflag.FlagID); err == nil {
			flag = &f
		} else {
			writeUsecaseError(c, err)
			return
		}
	}

	c.JSON(http.StatusOK, toReminderResponse(reminder, source, flag, subflag))
}

// Delete reminder.
// @Summary Excluir lembrete
// @Tags Reminders
// @Security BearerAuth
// @Param id path string true "Reminder ID"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/reminders/{id} [delete]
func (h *RemindersHandler) Delete(c *gin.Context) {
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
