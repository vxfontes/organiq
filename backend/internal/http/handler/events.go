package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type EventsHandler struct {
	Usecase  *usecase.EventUsecase
	Inbox    *usecase.InboxUsecase
	Flags    *usecase.FlagUsecase
	Subflags *usecase.SubflagUsecase
}

func NewEventsHandler(uc *usecase.EventUsecase, inbox *usecase.InboxUsecase, flags *usecase.FlagUsecase, subflags *usecase.SubflagUsecase) *EventsHandler {
	return &EventsHandler{Usecase: uc, Inbox: inbox, Flags: flags, Subflags: subflags}
}

// List events.
// @Summary Listar eventos
// @Tags Events
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListEventsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/events [get]
func (h *EventsHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	events, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	sourceIDs := make([]string, 0)
	for _, event := range events {
		if event.SourceInboxItemID != nil {
			sourceIDs = append(sourceIDs, *event.SourceInboxItemID)
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
	for _, event := range events {
		if event.SubflagID != nil {
			subflagIDs = append(subflagIDs, *event.SubflagID)
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
	for _, event := range events {
		if event.FlagID != nil {
			flagIDs = append(flagIDs, *event.FlagID)
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

	items := make([]dto.EventResponse, 0, len(events))
	for _, event := range events {
		var source *domain.InboxItem
		if event.SourceInboxItemID != nil {
			if item, ok := sourcesByID[*event.SourceInboxItemID]; ok {
				source = &item
			}
		}
		var flag *domain.Flag
		if event.FlagID != nil {
			if f, ok := flagsByID[*event.FlagID]; ok {
				flag = &f
			}
		}
		var subflag *domain.Subflag
		if event.SubflagID != nil {
			if sf, ok := subflagsByID[*event.SubflagID]; ok {
				subflag = &sf
			}
		}
		if flag == nil && subflag != nil {
			if f, ok := flagsByID[subflag.FlagID]; ok {
				flag = &f
			}
		}
		items = append(items, toEventResponse(event, source, flag, subflag))
	}

	c.JSON(http.StatusOK, dto.ListEventsResponse{Items: items, NextCursor: next})
}

// Create event.
// @Summary Criar evento
// @Tags Events
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateEventRequest true "Event payload"
// @Success 201 {object} dto.EventResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/events [post]
func (h *EventsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	event, err := h.Usecase.Create(c.Request.Context(), userID, req.Title, req.StartAt, req.EndAt, req.AllDay, req.Location, req.FlagID, req.SubflagID, nil)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	var subflag *domain.Subflag
	if h.Flags != nil && event.FlagID != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, *event.FlagID); err == nil {
			flag = &f
		} else {
			writeUsecaseError(c, err)
			return
		}
	}
	if h.Subflags != nil && event.SubflagID != nil {
		if sf, err := h.Subflags.Get(c.Request.Context(), userID, *event.SubflagID); err == nil {
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

	c.JSON(http.StatusCreated, toEventResponse(event, nil, flag, subflag))
}

// Update event.
// @Summary Atualizar evento
// @Tags Events
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Event ID"
// @Param body body dto.UpdateEventRequest true "Event payload"
// @Success 200 {object} dto.EventResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/events/{id} [patch]
func (h *EventsHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	event, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.EventUpdateInput{
		Title:     req.Title,
		StartAt:   req.StartAt,
		EndAt:     req.EndAt,
		AllDay:    req.AllDay,
		Location:  req.Location,
		FlagID:    req.FlagID,
		SubflagID: req.SubflagID,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var source *domain.InboxItem
	if h.Inbox != nil && event.SourceInboxItemID != nil {
		res, err := h.Inbox.GetInboxItem(c.Request.Context(), userID, *event.SourceInboxItemID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		source = &res.Item
	}

	var flag *domain.Flag
	var subflag *domain.Subflag
	if h.Flags != nil && event.FlagID != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, *event.FlagID); err == nil {
			flag = &f
		} else {
			writeUsecaseError(c, err)
			return
		}
	}
	if h.Subflags != nil && event.SubflagID != nil {
		if sf, err := h.Subflags.Get(c.Request.Context(), userID, *event.SubflagID); err == nil {
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

	c.JSON(http.StatusOK, toEventResponse(event, source, flag, subflag))
}

// Delete event.
// @Summary Excluir evento
// @Tags Events
// @Security BearerAuth
// @Param id path string true "Event ID"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/events/{id} [delete]
func (h *EventsHandler) Delete(c *gin.Context) {
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
