package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type InboxHandler struct {
	Usecase  *usecase.InboxUsecase
	Flags    *usecase.FlagUsecase
	Subflags *usecase.SubflagUsecase
}

func NewInboxHandler(uc *usecase.InboxUsecase, flags *usecase.FlagUsecase, subflags *usecase.SubflagUsecase) *InboxHandler {
	return &InboxHandler{Usecase: uc, Flags: flags, Subflags: subflags}
}

// List inbox items.
// @Summary Listar inbox items
// @Tags Inbox
// @Security BearerAuth
// @Produce json
// @Param status query string false "Status"
// @Param source query string false "Source"
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListInboxItemsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/inbox-items [get]
func (h *InboxHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	input := usecase.InboxListInput{
		Status: stringPtr(c.Query("status")),
		Source: stringPtr(c.Query("source")),
	}
	if input.Status != nil && *input.Status == "" {
		input.Status = nil
	}
	if input.Source != nil && *input.Source == "" {
		input.Source = nil
	}

	results, next, err := h.Usecase.ListInboxItems(c.Request.Context(), userID, input, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	subflagIDs := make([]string, 0)
	for _, result := range results {
		if result.Suggestion != nil && result.Suggestion.SubflagID != nil {
			subflagIDs = append(subflagIDs, *result.Suggestion.SubflagID)
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
	for _, result := range results {
		if result.Suggestion != nil && result.Suggestion.FlagID != nil {
			flagIDs = append(flagIDs, *result.Suggestion.FlagID)
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

	items := make([]dto.InboxItemResponse, 0, len(results))
	for _, result := range results {
		var suggestionResp *dto.AiSuggestionResponse
		if result.Suggestion != nil {
			var flag *domain.Flag
			if result.Suggestion.FlagID != nil {
				if f, ok := flagsByID[*result.Suggestion.FlagID]; ok {
					flag = &f
				}
			}
			var subflag *domain.Subflag
			if result.Suggestion.SubflagID != nil {
				if sf, ok := subflagsByID[*result.Suggestion.SubflagID]; ok {
					subflag = &sf
				}
			}
			if flag == nil && subflag != nil {
				if f, ok := flagsByID[subflag.FlagID]; ok {
					flag = &f
				}
			}
			resp := toSuggestionResponse(*result.Suggestion, flag, subflag)
			suggestionResp = &resp
		}

		items = append(items, toInboxItemResponse(result.Item, suggestionResp))
	}

	c.JSON(http.StatusOK, dto.ListInboxItemsResponse{Items: items, NextCursor: next})
}

// Create inbox item.
// @Summary Criar inbox item
// @Tags Inbox
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateInboxItemRequest true "Inbox payload"
// @Success 201 {object} dto.InboxItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/inbox-items [post]
func (h *InboxHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateInboxItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	var source *string
	if req.Source != "" {
		source = &req.Source
	}
	item, err := h.Usecase.CreateInboxItem(c.Request.Context(), userID, source, req.RawText, req.RawMediaURL)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toInboxItemResponse(item, nil))
}

// Get inbox item.
// @Summary Obter inbox item
// @Tags Inbox
// @Security BearerAuth
// @Produce json
// @Param id path string true "Inbox item ID"
// @Success 200 {object} dto.InboxItemResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/inbox-items/{id} [get]
func (h *InboxHandler) Get(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	result, err := h.Usecase.GetInboxItem(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var suggestionResp *dto.AiSuggestionResponse
	if result.Suggestion != nil {
		var flag *domain.Flag
		if h.Flags != nil && result.Suggestion.FlagID != nil {
			f, err := h.Flags.Get(c.Request.Context(), userID, *result.Suggestion.FlagID)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			flag = &f
		}
		var subflag *domain.Subflag
		if h.Subflags != nil && result.Suggestion.SubflagID != nil {
			sf, err := h.Subflags.Get(c.Request.Context(), userID, *result.Suggestion.SubflagID)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			subflag = &sf
		}
		resp := toSuggestionResponse(*result.Suggestion, flag, subflag)
		suggestionResp = &resp
	}

	c.JSON(http.StatusOK, toInboxItemResponse(result.Item, suggestionResp))
}

// Reprocess inbox item.
// @Summary Reprocessar inbox item
// @Tags Inbox
// @Security BearerAuth
// @Produce json
// @Param id path string true "Inbox item ID"
// @Success 200 {object} dto.InboxItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/inbox-items/{id}/reprocess [post]
func (h *InboxHandler) Reprocess(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	result, err := h.Usecase.ReprocessInboxItem(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var suggestionResp *dto.AiSuggestionResponse
	if result.Suggestion != nil {
		var flag *domain.Flag
		if h.Flags != nil && result.Suggestion.FlagID != nil {
			f, err := h.Flags.Get(c.Request.Context(), userID, *result.Suggestion.FlagID)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			flag = &f
		}
		var subflag *domain.Subflag
		if h.Subflags != nil && result.Suggestion.SubflagID != nil {
			sf, err := h.Subflags.Get(c.Request.Context(), userID, *result.Suggestion.SubflagID)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			subflag = &sf
		}
		resp := toSuggestionResponse(*result.Suggestion, flag, subflag)
		suggestionResp = &resp
	}

	c.JSON(http.StatusOK, toInboxItemResponse(result.Item, suggestionResp))
}

// Confirm inbox item.
// @Summary Confirmar inbox item
// @Tags Inbox
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Inbox item ID"
// @Param body body dto.ConfirmInboxItemRequest true "Confirm payload"
// @Success 200 {object} dto.ConfirmInboxItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/inbox-items/{id}/confirm [post]
func (h *InboxHandler) Confirm(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.ConfirmInboxItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	result, err := h.Usecase.ConfirmInboxItem(c.Request.Context(), userID, id, usecase.ConfirmInboxInput{
		Type:      req.Type,
		Title:     req.Title,
		FlagID:    req.FlagID,
		SubflagID: req.SubflagID,
		Payload:   req.Payload,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	resp := dto.ConfirmInboxItemResponse{Type: string(result.Type)}
	if result.Task != nil {
		task := toTaskResponse(*result.Task, nil, nil, nil)
		resp.Task = &task
	}
	if result.Reminder != nil {
		var flag *domain.Flag
		var subflag *domain.Subflag
		if h.Flags != nil && result.Reminder.FlagID != nil {
			if f, err := h.Flags.Get(c.Request.Context(), userID, *result.Reminder.FlagID); err == nil {
				flag = &f
			} else {
				writeUsecaseError(c, err)
				return
			}
		}
		if h.Subflags != nil && result.Reminder.SubflagID != nil {
			if sf, err := h.Subflags.Get(c.Request.Context(), userID, *result.Reminder.SubflagID); err == nil {
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

		reminder := toReminderResponse(*result.Reminder, nil, flag, subflag)
		resp.Reminder = &reminder
	}
	if result.Event != nil {
		var flag *domain.Flag
		var subflag *domain.Subflag
		if h.Flags != nil && result.Event.FlagID != nil {
			if f, err := h.Flags.Get(c.Request.Context(), userID, *result.Event.FlagID); err == nil {
				flag = &f
			} else {
				writeUsecaseError(c, err)
				return
			}
		}
		if h.Subflags != nil && result.Event.SubflagID != nil {
			if sf, err := h.Subflags.Get(c.Request.Context(), userID, *result.Event.SubflagID); err == nil {
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

		event := toEventResponse(*result.Event, nil, flag, subflag)
		resp.Event = &event
	}
	if result.ShoppingList != nil {
		list := toShoppingListResponse(*result.ShoppingList, nil)
		resp.ShoppingList = &list
	}
	if len(result.ShoppingItems) > 0 {
		items := make([]dto.ShoppingItemResponse, 0, len(result.ShoppingItems))
		for _, item := range result.ShoppingItems {
			items = append(items, toShoppingItemResponse(item, result.ShoppingList))
		}
		resp.ShoppingItems = items
	}
	if result.Routine != nil {
		var flag *domain.Flag
		var subflag *domain.Subflag
		if h.Flags != nil && result.Routine.FlagID != nil {
			if f, err := h.Flags.Get(c.Request.Context(), userID, *result.Routine.FlagID); err == nil {
				flag = &f
			}
		}
		if h.Subflags != nil && result.Routine.SubflagID != nil {
			if sf, err := h.Subflags.Get(c.Request.Context(), userID, *result.Routine.SubflagID); err == nil {
				subflag = &sf
			}
		}
		routine := toRoutineResponse(*result.Routine, flag, subflag)
		resp.Routine = &routine
	}

	c.JSON(http.StatusOK, resp)
}

// Dismiss inbox item.
// @Summary Descartar inbox item
// @Tags Inbox
// @Security BearerAuth
// @Produce json
// @Param id path string true "Inbox item ID"
// @Success 200 {object} dto.InboxItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/inbox-items/{id}/dismiss [post]
func (h *InboxHandler) Dismiss(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	item, err := h.Usecase.DismissInboxItem(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toInboxItemResponse(item, nil))
}

func stringPtr(value string) *string {
	return &value
}
