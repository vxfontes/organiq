package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
)

type SuggestionsHandler struct {
	Usecase *usecase.SuggestionUsecase
}

func NewSuggestionsHandler(uc *usecase.SuggestionUsecase) *SuggestionsHandler {
	return &SuggestionsHandler{Usecase: uc}
}

// Chat sends a user message and receives assistant response.
// @Summary Enviar mensagem de sugestao
// @Tags Suggestions
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.SendSuggestionMessageRequest true "Mensagem"
// @Success 200 {object} dto.SuggestionMessageResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/suggestions/chat [post]
func (h *SuggestionsHandler) Chat(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.SendSuggestionMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	result, err := h.Usecase.SendMessage(c.Request.Context(), userID, usecase.SendSuggestionMessageInput{
		ConversationID: req.ConversationID,
		Message:        req.Message,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, dto.SuggestionMessageResponse{
		ConversationID: result.Conversation.ID,
		MessageID:      result.Message.Message.ID,
		Text:           result.Message.Message.Content,
		Blocks:         toSuggestionBlocksDTO(result.Message.Blocks),
	})
}

// Accept creates an entity from a suggestion block.
// @Summary Aceitar bloco sugerido
// @Tags Suggestions
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.AcceptSuggestionBlockRequest true "Bloco"
// @Success 200 {object} dto.AcceptSuggestionBlockResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/suggestions/accept [post]
func (h *SuggestionsHandler) Accept(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.AcceptSuggestionBlockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	result, err := h.Usecase.AcceptBlock(c.Request.Context(), userID, usecase.AcceptSuggestionBlockInput{
		Type:           req.Type,
		Title:          req.Title,
		Rationale:      req.Rationale,
		StartsAt:       req.StartsAt,
		EndsAt:         req.EndsAt,
		Weekdays:       req.Weekdays,
		RecurrenceType: req.RecurrenceType,
		FlagID:         req.FlagID,
		SubflagID:      req.SubflagID,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, dto.AcceptSuggestionBlockResponse{
		Type:     result.Type,
		EntityID: result.EntityID,
		Title:    result.Title,
	})
}

// ListConversations lists user suggestion conversations.
// @Summary Listar conversas de sugestao
// @Tags Suggestions
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListSuggestionConversationsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/suggestions/conversations [get]
func (h *SuggestionsHandler) ListConversations(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	items, next, err := h.Usecase.ListConversations(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	respItems := make([]dto.SuggestionConversationResponse, 0, len(items))
	for _, item := range items {
		respItems = append(respItems, dto.SuggestionConversationResponse{
			ID:        item.ID,
			CreatedAt: item.CreatedAt,
			UpdatedAt: item.UpdatedAt,
		})
	}

	c.JSON(http.StatusOK, dto.ListSuggestionConversationsResponse{
		Items:      respItems,
		NextCursor: next,
	})
}

// GetConversation returns one conversation and all messages.
// @Summary Obter conversa de sugestao
// @Tags Suggestions
// @Security BearerAuth
// @Produce json
// @Param id path string true "Conversation ID"
// @Success 200 {object} dto.SuggestionConversationDetailResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/suggestions/conversations/{id} [get]
func (h *SuggestionsHandler) GetConversation(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	result, err := h.Usecase.GetConversation(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	messages := make([]dto.SuggestionConversationMessage, 0, len(result.Messages))
	for _, item := range result.Messages {
		messages = append(messages, dto.SuggestionConversationMessage{
			ID:        item.Message.ID,
			Role:      string(item.Message.Role),
			Content:   item.Message.Content,
			Blocks:    toSuggestionBlocksDTO(item.Blocks),
			CreatedAt: item.Message.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, dto.SuggestionConversationDetailResponse{
		ID:        result.Conversation.ID,
		CreatedAt: result.Conversation.CreatedAt,
		UpdatedAt: result.Conversation.UpdatedAt,
		Messages:  messages,
	})
}

func toSuggestionBlocksDTO(blocks []usecase.SuggestionBlock) []dto.SuggestionBlock {
	if len(blocks) == 0 {
		return nil
	}

	out := make([]dto.SuggestionBlock, 0, len(blocks))
	for _, block := range blocks {
		out = append(out, dto.SuggestionBlock{
			ID:             block.ID,
			Type:           block.Type,
			Title:          block.Title,
			Rationale:      block.Rationale,
			StartsAt:       block.StartsAt,
			EndsAt:         block.EndsAt,
			Weekdays:       block.Weekdays,
			RecurrenceType: block.RecurrenceType,
			FlagID:         block.FlagID,
			SubflagID:      block.SubflagID,
		})
	}
	return out
}
