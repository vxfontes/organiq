package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type TasksHandler struct {
	Usecase  *usecase.TaskUsecase
	Inbox    *usecase.InboxUsecase
	Flags    *usecase.FlagUsecase
	Subflags *usecase.SubflagUsecase
}

func NewTasksHandler(uc *usecase.TaskUsecase, inbox *usecase.InboxUsecase, flags *usecase.FlagUsecase, subflags *usecase.SubflagUsecase) *TasksHandler {
	return &TasksHandler{Usecase: uc, Inbox: inbox, Flags: flags, Subflags: subflags}
}

// List tasks.
// @Summary Listar tarefas
// @Tags Tasks
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListTasksResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/tasks [get]
func (h *TasksHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	tasks, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	sourceIDs := make([]string, 0)
	for _, task := range tasks {
		if task.SourceInboxItemID != nil {
			sourceIDs = append(sourceIDs, *task.SourceInboxItemID)
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
	for _, task := range tasks {
		if task.SubflagID != nil {
			subflagIDs = append(subflagIDs, *task.SubflagID)
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
	for _, task := range tasks {
		if task.FlagID != nil {
			flagIDs = append(flagIDs, *task.FlagID)
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

	items := make([]dto.TaskResponse, 0, len(tasks))
	for _, task := range tasks {
		var source *domain.InboxItem
		if task.SourceInboxItemID != nil {
			if item, ok := sourcesByID[*task.SourceInboxItemID]; ok {
				source = &item
			}
		}
		var flag *domain.Flag
		if task.FlagID != nil {
			if f, ok := flagsByID[*task.FlagID]; ok {
				flag = &f
			}
		}
		var subflag *domain.Subflag
		if task.SubflagID != nil {
			if sf, ok := subflagsByID[*task.SubflagID]; ok {
				subflag = &sf
			}
		}
		if flag == nil && subflag != nil {
			if f, ok := flagsByID[subflag.FlagID]; ok {
				flag = &f
			}
		}
		items = append(items, toTaskResponse(task, source, flag, subflag))
	}

	c.JSON(http.StatusOK, dto.ListTasksResponse{Items: items, NextCursor: next})
}

// Create task.
// @Summary Criar tarefa
// @Tags Tasks
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateTaskRequest true "Task payload"
// @Success 201 {object} dto.TaskResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/tasks [post]
func (h *TasksHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	task, err := h.Usecase.Create(c.Request.Context(), userID, req.Title, req.Description, req.Status, req.DueAt, req.FlagID, req.SubflagID, nil)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var flag *domain.Flag
	var subflag *domain.Subflag
	if h.Flags != nil && task.FlagID != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, *task.FlagID); err == nil {
			flag = &f
		} else {
			writeUsecaseError(c, err)
			return
		}
	}
	if h.Subflags != nil && task.SubflagID != nil {
		if sf, err := h.Subflags.Get(c.Request.Context(), userID, *task.SubflagID); err == nil {
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

	c.JSON(http.StatusCreated, toTaskResponse(task, nil, flag, subflag))
}

// Update task.
// @Summary Atualizar tarefa
// @Tags Tasks
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Task ID"
// @Param body body dto.UpdateTaskRequest true "Task payload"
// @Success 200 {object} dto.TaskResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/tasks/{id} [patch]
func (h *TasksHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	task, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.TaskUpdateInput{
		Title:       req.Title,
		Description: req.Description,
		Status:      req.Status,
		DueAt:       req.DueAt,
		FlagID:      req.FlagID,
		SubflagID:   req.SubflagID,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var source *domain.InboxItem
	if h.Inbox != nil && task.SourceInboxItemID != nil {
		res, err := h.Inbox.GetInboxItem(c.Request.Context(), userID, *task.SourceInboxItemID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		source = &res.Item
	}
	var flag *domain.Flag
	var subflag *domain.Subflag
	if h.Flags != nil && task.FlagID != nil {
		if f, err := h.Flags.Get(c.Request.Context(), userID, *task.FlagID); err == nil {
			flag = &f
		} else {
			writeUsecaseError(c, err)
			return
		}
	}
	if h.Subflags != nil && task.SubflagID != nil {
		if sf, err := h.Subflags.Get(c.Request.Context(), userID, *task.SubflagID); err == nil {
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

	c.JSON(http.StatusOK, toTaskResponse(task, source, flag, subflag))
}

// Delete task.
// @Summary Excluir tarefa
// @Tags Tasks
// @Security BearerAuth
// @Param id path string true "Task ID"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/tasks/{id} [delete]
func (h *TasksHandler) Delete(c *gin.Context) {
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
