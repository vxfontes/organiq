package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type ShoppingListsHandler struct {
	Usecase *usecase.ShoppingListUsecase
	Inbox   *usecase.InboxUsecase
}

type ShoppingItemsHandler struct {
	Usecase *usecase.ShoppingItemUsecase
	Lists   *usecase.ShoppingListUsecase
}

func NewShoppingListsHandler(uc *usecase.ShoppingListUsecase, inbox *usecase.InboxUsecase) *ShoppingListsHandler {
	return &ShoppingListsHandler{Usecase: uc, Inbox: inbox}
}

func NewShoppingItemsHandler(uc *usecase.ShoppingItemUsecase, lists *usecase.ShoppingListUsecase) *ShoppingItemsHandler {
	return &ShoppingItemsHandler{Usecase: uc, Lists: lists}
}

// List shopping lists.
// @Summary Listar listas de compras
// @Tags ShoppingLists
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListShoppingListsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/shopping-lists [get]
func (h *ShoppingListsHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	lists, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	sourceIDs := make([]string, 0)
	for _, list := range lists {
		if list.SourceInboxItemID != nil {
			sourceIDs = append(sourceIDs, *list.SourceInboxItemID)
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

	items := make([]dto.ShoppingListResponse, 0, len(lists))
	for _, list := range lists {
		var source *domain.InboxItem
		if list.SourceInboxItemID != nil {
			if item, ok := sourcesByID[*list.SourceInboxItemID]; ok {
				source = &item
			}
		}
		items = append(items, toShoppingListResponse(list, source))
	}

	c.JSON(http.StatusOK, dto.ListShoppingListsResponse{Items: items, NextCursor: next})
}

// Create shopping list.
// @Summary Criar lista de compras
// @Tags ShoppingLists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateShoppingListRequest true "Shopping list payload"
// @Success 201 {object} dto.ShoppingListResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/shopping-lists [post]
func (h *ShoppingListsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateShoppingListRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	list, err := h.Usecase.Create(c.Request.Context(), userID, req.Title, req.Status)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toShoppingListResponse(list, nil))
}

// Update shopping list.
// @Summary Atualizar lista de compras
// @Tags ShoppingLists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Shopping list ID"
// @Param body body dto.UpdateShoppingListRequest true "Shopping list payload"
// @Success 200 {object} dto.ShoppingListResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/shopping-lists/{id} [patch]
func (h *ShoppingListsHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateShoppingListRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	list, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.ShoppingListUpdateInput{
		Title:  req.Title,
		Status: req.Status,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var source *domain.InboxItem
	if h.Inbox != nil && list.SourceInboxItemID != nil {
		res, err := h.Inbox.GetInboxItem(c.Request.Context(), userID, *list.SourceInboxItemID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		source = &res.Item
	}

	c.JSON(http.StatusOK, toShoppingListResponse(list, source))
}

// Delete shopping list.
// @Summary Excluir lista de compras
// @Tags ShoppingLists
// @Security BearerAuth
// @Param id path string true "Shopping list ID"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/shopping-lists/{id} [delete]
func (h *ShoppingListsHandler) Delete(c *gin.Context) {
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

// List shopping items by list.
// @Summary Listar itens da lista
// @Tags ShoppingItems
// @Security BearerAuth
// @Produce json
// @Param id path string true "Shopping list ID"
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListShoppingItemsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/shopping-lists/{id}/items [get]
func (h *ShoppingItemsHandler) ListByList(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	listID := c.Param("id")
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	items, next, err := h.Usecase.ListByList(c.Request.Context(), userID, listID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var list *domain.ShoppingList
	if h.Lists != nil {
		l, err := h.Lists.Get(c.Request.Context(), userID, listID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		list = &l
	}

	respItems := make([]dto.ShoppingItemResponse, 0, len(items))
	for _, item := range items {
		respItems = append(respItems, toShoppingItemResponse(item, list))
	}

	c.JSON(http.StatusOK, dto.ListShoppingItemsResponse{Items: respItems, NextCursor: next})
}

// Create shopping item.
// @Summary Criar item de compra
// @Tags ShoppingItems
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Shopping list ID"
// @Param body body dto.CreateShoppingItemRequest true "Shopping item payload"
// @Success 201 {object} dto.ShoppingItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/shopping-lists/{id}/items [post]
func (h *ShoppingItemsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	listID := c.Param("id")

	var req dto.CreateShoppingItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	item, err := h.Usecase.Create(c.Request.Context(), userID, listID, req.Title, req.Quantity, req.Checked, req.SortOrder)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var list *domain.ShoppingList
	if h.Lists != nil {
		l, err := h.Lists.Get(c.Request.Context(), userID, item.ListID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		list = &l
	}

	c.JSON(http.StatusCreated, toShoppingItemResponse(item, list))
}

// Update shopping item.
// @Summary Atualizar item de compra
// @Tags ShoppingItems
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Shopping item ID"
// @Param body body dto.UpdateShoppingItemRequest true "Shopping item payload"
// @Success 200 {object} dto.ShoppingItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/shopping-items/{id} [patch]
func (h *ShoppingItemsHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateShoppingItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	item, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.ShoppingItemUpdateInput{
		Title:     req.Title,
		Quantity:  req.Quantity,
		Checked:   req.Checked,
		SortOrder: req.SortOrder,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var list *domain.ShoppingList
	if h.Lists != nil {
		l, err := h.Lists.Get(c.Request.Context(), userID, item.ListID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		list = &l
	}

	c.JSON(http.StatusOK, toShoppingItemResponse(item, list))
}

// Delete shopping item.
// @Summary Excluir item de compra
// @Tags ShoppingItems
// @Security BearerAuth
// @Param id path string true "Shopping item ID"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/shopping-items/{id} [delete]
func (h *ShoppingItemsHandler) Delete(c *gin.Context) {
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
