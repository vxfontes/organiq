package usecase

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/app/service"
)

const (
	suggestionPromptHistoryLimit = 20
	suggestionContextCap         = 200
	suggestionContextWindowDays  = 14
)

type SuggestionUsecase struct {
	Users         repository.UserRepository
	Conversations repository.SuggestionConversationRepository
	Messages      repository.SuggestionMessageRepository
	Tasks         repository.TaskRepository
	Reminders     repository.ReminderRepository
	Events        repository.EventRepository
	Routines      repository.RoutineRepository
	Flags         repository.FlagRepository
	Subflags      repository.SubflagRepository

	TasksUsecase    *TaskUsecase
	EventsUsecase   *EventUsecase
	RoutinesUsecase *RoutineUsecase

	PromptBuilder *service.SuggestionPromptBuilder
	AIClient      service.AIClient
	Now           func() time.Time
}

type SendSuggestionMessageInput struct {
	ConversationID *string
	Message        string
}

type SuggestionBlock struct {
	ID             string     `json:"id,omitempty"`
	Type           string     `json:"type"`
	Title          string     `json:"title"`
	Rationale      string     `json:"rationale,omitempty"`
	StartsAt       *time.Time `json:"startsAt,omitempty"`
	EndsAt         *time.Time `json:"endsAt,omitempty"`
	Weekdays       []int      `json:"weekdays,omitempty"`
	RecurrenceType *string    `json:"recurrenceType,omitempty"`
	FlagID         *string    `json:"flagId,omitempty"`
	SubflagID      *string    `json:"subflagId,omitempty"`
}

type SuggestionMessageResult struct {
	Message domain.SuggestionMessage
	Blocks  []SuggestionBlock
}

type SendSuggestionMessageResult struct {
	Conversation domain.SuggestionConversation
	Message      SuggestionMessageResult
}

type GetSuggestionConversationResult struct {
	Conversation domain.SuggestionConversation
	Messages     []SuggestionMessageResult
}

type AcceptSuggestionBlockInput struct {
	Type           string
	Title          string
	Rationale      *string
	StartsAt       *time.Time
	EndsAt         *time.Time
	Weekdays       []int
	RecurrenceType *string
	FlagID         *string
	SubflagID      *string
}

type AcceptSuggestionBlockResult struct {
	Type     string
	EntityID string
	Title    string
}

func (uc *SuggestionUsecase) SendMessage(ctx context.Context, userID string, input SendSuggestionMessageInput) (SendSuggestionMessageResult, error) {
	userID = normalizeString(userID)
	message := normalizeString(input.Message)
	if userID == "" || message == "" {
		return SendSuggestionMessageResult{}, ErrMissingRequiredFields
	}
	if uc.Conversations == nil || uc.Messages == nil {
		return SendSuggestionMessageResult{}, ErrDependencyMissing
	}

	conversation, err := uc.resolveConversation(ctx, userID, input.ConversationID)
	if err != nil {
		return SendSuggestionMessageResult{}, err
	}

	userMessage := domain.SuggestionMessage{
		ConversationID: conversation.ID,
		Role:           domain.SuggestionMessageRoleUser,
		Content:        message,
	}
	if _, err := uc.Messages.Create(ctx, userMessage); err != nil {
		return SendSuggestionMessageResult{}, err
	}
	if err := uc.Conversations.Touch(ctx, userID, conversation.ID); err != nil {
		return SendSuggestionMessageResult{}, err
	}

	recentMessages, err := uc.Messages.ListRecentByConversation(ctx, userID, conversation.ID, suggestionPromptHistoryLimit)
	if err != nil {
		return SendSuggestionMessageResult{}, err
	}

	promptInput, err := uc.buildPromptInput(ctx, userID, message, recentMessages)
	if err != nil {
		return SendSuggestionMessageResult{}, err
	}
	text, blocks := uc.generateAssistantReply(ctx, promptInput)

	blocksJSON, err := marshalSuggestionBlocks(blocks)
	if err != nil {
		return SendSuggestionMessageResult{}, err
	}

	assistantMessage := domain.SuggestionMessage{
		ConversationID:   conversation.ID,
		Role:             domain.SuggestionMessageRoleAssistant,
		Content:          text,
		StructuredBlocks: blocksJSON,
	}
	assistantMessage, err = uc.Messages.Create(ctx, assistantMessage)
	if err != nil {
		return SendSuggestionMessageResult{}, err
	}
	if err := uc.Conversations.Touch(ctx, userID, conversation.ID); err != nil {
		return SendSuggestionMessageResult{}, err
	}

	conversation, err = uc.Conversations.Get(ctx, userID, conversation.ID)
	if err != nil {
		return SendSuggestionMessageResult{}, err
	}

	return SendSuggestionMessageResult{
		Conversation: conversation,
		Message: SuggestionMessageResult{
			Message: assistantMessage,
			Blocks:  blocks,
		},
	}, nil
}

func (uc *SuggestionUsecase) AcceptBlock(ctx context.Context, userID string, input AcceptSuggestionBlockInput) (AcceptSuggestionBlockResult, error) {
	userID = normalizeString(userID)
	title := normalizeString(input.Title)
	blockType := strings.ToLower(strings.TrimSpace(input.Type))
	if userID == "" || title == "" || blockType == "" {
		return AcceptSuggestionBlockResult{}, ErrMissingRequiredFields
	}

	flagID := normalizeOptionalString(input.FlagID)
	subflagID := normalizeOptionalString(input.SubflagID)

	switch blockType {
	case "task":
		if uc.TasksUsecase == nil {
			return AcceptSuggestionBlockResult{}, ErrDependencyMissing
		}
		var dueAt *time.Time
		if input.EndsAt != nil {
			dueAt = input.EndsAt
		} else {
			dueAt = input.StartsAt
		}
		task, err := uc.TasksUsecase.Create(ctx, userID, title, nil, nil, dueAt, flagID, subflagID, nil)
		if err != nil {
			return AcceptSuggestionBlockResult{}, err
		}
		return AcceptSuggestionBlockResult{Type: blockType, EntityID: task.ID, Title: task.Title}, nil
	case "event":
		if uc.EventsUsecase == nil {
			return AcceptSuggestionBlockResult{}, ErrDependencyMissing
		}
		if input.StartsAt == nil {
			return AcceptSuggestionBlockResult{}, ErrMissingRequiredFields
		}
		event, err := uc.EventsUsecase.Create(ctx, userID, title, input.StartsAt, input.EndsAt, nil, nil, flagID, subflagID, nil)
		if err != nil {
			return AcceptSuggestionBlockResult{}, err
		}
		return AcceptSuggestionBlockResult{Type: blockType, EntityID: event.ID, Title: event.Title}, nil
	case "routine":
		if uc.RoutinesUsecase == nil {
			return AcceptSuggestionBlockResult{}, ErrDependencyMissing
		}
		if input.StartsAt == nil {
			return AcceptSuggestionBlockResult{}, ErrMissingRequiredFields
		}

		weekdays := normalizeWeekdays(input.Weekdays)
		if len(weekdays) == 0 {
			weekdays = []int{int(input.StartsAt.Weekday())}
		}

		recurrenceType := "weekly"
		if input.RecurrenceType != nil && strings.TrimSpace(*input.RecurrenceType) != "" {
			recurrenceType = strings.ToLower(strings.TrimSpace(*input.RecurrenceType))
		}

		startTime := input.StartsAt.Format("15:04")
		endTime := startTime
		if input.EndsAt != nil {
			endTime = input.EndsAt.Format("15:04")
		}
		startsOn := input.StartsAt.Format("2006-01-02")

		routine, err := uc.RoutinesUsecase.Create(ctx, userID, usecaseRoutineInputFromSuggestion(
			title,
			recurrenceType,
			weekdays,
			startTime,
			endTime,
			startsOn,
			flagID,
			subflagID,
		))
		if err != nil {
			return AcceptSuggestionBlockResult{}, err
		}
		return AcceptSuggestionBlockResult{Type: blockType, EntityID: routine.ID, Title: routine.Title}, nil
	default:
		return AcceptSuggestionBlockResult{}, ErrInvalidType
	}
}

func (uc *SuggestionUsecase) ListConversations(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.SuggestionConversation, *string, error) {
	userID = normalizeString(userID)
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	if uc.Conversations == nil {
		return nil, nil, ErrDependencyMissing
	}
	return uc.Conversations.List(ctx, userID, opts)
}

func (uc *SuggestionUsecase) GetConversation(ctx context.Context, userID, conversationID string) (GetSuggestionConversationResult, error) {
	userID = normalizeString(userID)
	conversationID = normalizeString(conversationID)
	if userID == "" || conversationID == "" {
		return GetSuggestionConversationResult{}, ErrMissingRequiredFields
	}
	if uc.Conversations == nil || uc.Messages == nil {
		return GetSuggestionConversationResult{}, ErrDependencyMissing
	}

	conversation, err := uc.Conversations.Get(ctx, userID, conversationID)
	if err != nil {
		return GetSuggestionConversationResult{}, err
	}

	messages, err := uc.Messages.ListByConversation(ctx, userID, conversationID)
	if err != nil {
		return GetSuggestionConversationResult{}, err
	}

	messageResults := make([]SuggestionMessageResult, 0, len(messages))
	for _, message := range messages {
		blocks := parseStoredSuggestionBlocks(message.StructuredBlocks)
		messageResults = append(messageResults, SuggestionMessageResult{
			Message: message,
			Blocks:  blocks,
		})
	}

	return GetSuggestionConversationResult{
		Conversation: conversation,
		Messages:     messageResults,
	}, nil
}

func (uc *SuggestionUsecase) resolveConversation(ctx context.Context, userID string, conversationID *string) (domain.SuggestionConversation, error) {
	if conversationID == nil || strings.TrimSpace(*conversationID) == "" {
		return uc.Conversations.Create(ctx, domain.SuggestionConversation{UserID: userID})
	}
	return uc.Conversations.Get(ctx, userID, strings.TrimSpace(*conversationID))
}

func (uc *SuggestionUsecase) buildPromptInput(ctx context.Context, userID, incomingMessage string, history []domain.SuggestionMessage) (service.SuggestionPromptInput, error) {
	var (
		locale   string
		timezone string
	)
	if uc.Users != nil {
		user, err := uc.Users.Get(ctx, userID)
		if err != nil {
			return service.SuggestionPromptInput{}, err
		}
		locale = strings.TrimSpace(user.Locale)
		timezone = strings.TrimSpace(user.Timezone)
	}

	now := time.Now()
	if uc.Now != nil {
		now = uc.Now()
	}
	if timezone != "" {
		if loc, err := time.LoadLocation(timezone); err == nil {
			now = now.In(loc)
		}
	}
	windowEnd := now.AddDate(0, 0, suggestionContextWindowDays)

	tasks, err := uc.loadTaskContext(ctx, userID, windowEnd)
	if err != nil {
		return service.SuggestionPromptInput{}, err
	}
	reminders, err := uc.loadReminderContext(ctx, userID, windowEnd)
	if err != nil {
		return service.SuggestionPromptInput{}, err
	}
	events, err := uc.loadEventContext(ctx, userID, windowEnd)
	if err != nil {
		return service.SuggestionPromptInput{}, err
	}
	routines, err := uc.loadRoutineContext(ctx, userID)
	if err != nil {
		return service.SuggestionPromptInput{}, err
	}
	flags, err := uc.loadFlagContext(ctx, userID)
	if err != nil {
		return service.SuggestionPromptInput{}, err
	}

	msgHistory := make([]service.SuggestionPromptMessage, 0, len(history))
	for _, item := range history {
		msgHistory = append(msgHistory, service.SuggestionPromptMessage{
			Role:    string(item.Role),
			Content: item.Content,
		})
	}

	return service.SuggestionPromptInput{
		Locale:          locale,
		Timezone:        timezone,
		Now:             now,
		IncomingMessage: incomingMessage,
		Messages:        msgHistory,
		Tasks:           tasks,
		Reminders:       reminders,
		Events:          events,
		Routines:        routines,
		Flags:           flags,
	}, nil
}

func (uc *SuggestionUsecase) loadTaskContext(ctx context.Context, userID string, end time.Time) ([]service.SuggestionPromptTask, error) {
	if uc.Tasks == nil {
		return nil, nil
	}

	items, err := listAllTasks(ctx, uc.Tasks, userID)
	if err != nil {
		return nil, err
	}

	out := make([]service.SuggestionPromptTask, 0)
	for _, item := range items {
		if item.Status != domain.TaskStatusOpen {
			continue
		}
		if item.DueAt != nil && item.DueAt.After(end) {
			continue
		}
		out = append(out, service.SuggestionPromptTask{
			Title: item.Title,
			DueAt: item.DueAt,
		})
		if len(out) >= suggestionContextCap {
			break
		}
	}
	return out, nil
}

func (uc *SuggestionUsecase) loadReminderContext(ctx context.Context, userID string, end time.Time) ([]service.SuggestionPromptReminder, error) {
	if uc.Reminders == nil {
		return nil, nil
	}

	items, err := listAllReminders(ctx, uc.Reminders, userID)
	if err != nil {
		return nil, err
	}

	out := make([]service.SuggestionPromptReminder, 0)
	for _, item := range items {
		if item.Status != domain.ReminderStatusOpen {
			continue
		}
		if item.RemindAt == nil || item.RemindAt.After(end) {
			continue
		}
		out = append(out, service.SuggestionPromptReminder{
			Title:    item.Title,
			RemindAt: item.RemindAt,
		})
		if len(out) >= suggestionContextCap {
			break
		}
	}
	return out, nil
}

func (uc *SuggestionUsecase) loadEventContext(ctx context.Context, userID string, end time.Time) ([]service.SuggestionPromptEvent, error) {
	if uc.Events == nil {
		return nil, nil
	}

	items, err := listAllEvents(ctx, uc.Events, userID)
	if err != nil {
		return nil, err
	}

	out := make([]service.SuggestionPromptEvent, 0)
	for _, item := range items {
		if item.StartAt == nil || item.StartAt.After(end) {
			continue
		}
		out = append(out, service.SuggestionPromptEvent{
			Title:   item.Title,
			StartAt: item.StartAt,
			EndAt:   item.EndAt,
		})
		if len(out) >= suggestionContextCap {
			break
		}
	}
	return out, nil
}

func (uc *SuggestionUsecase) loadRoutineContext(ctx context.Context, userID string) ([]service.SuggestionPromptRoutine, error) {
	if uc.Routines == nil {
		return nil, nil
	}

	items, err := listAllRoutines(ctx, uc.Routines, userID)
	if err != nil {
		return nil, err
	}

	out := make([]service.SuggestionPromptRoutine, 0)
	for _, item := range items {
		out = append(out, service.SuggestionPromptRoutine{
			Title:          item.Title,
			RecurrenceType: item.RecurrenceType,
			Weekdays:       item.Weekdays,
			StartTime:      item.StartTime,
			EndTime:        item.EndTime,
		})
		if len(out) >= suggestionContextCap {
			break
		}
	}
	return out, nil
}

func (uc *SuggestionUsecase) loadFlagContext(ctx context.Context, userID string) ([]service.SuggestionPromptFlag, error) {
	if uc.Flags == nil {
		return nil, nil
	}

	flags, err := listAllFlags(ctx, uc.Flags, userID)
	if err != nil {
		return nil, err
	}

	out := make([]service.SuggestionPromptFlag, 0, len(flags))
	for _, flag := range flags {
		item := service.SuggestionPromptFlag{
			FlagID: flag.ID,
			Name:   flag.Name,
		}

		if uc.Subflags != nil {
			subflags, err := listAllSubflags(ctx, uc.Subflags, userID, flag.ID)
			if err != nil {
				return nil, err
			}
			item.Subflags = make([]service.SuggestionPromptSubflag, 0, len(subflags))
			for _, subflag := range subflags {
				item.Subflags = append(item.Subflags, service.SuggestionPromptSubflag{
					SubflagID: subflag.ID,
					Name:      subflag.Name,
				})
			}
		}

		out = append(out, item)
	}
	return out, nil
}

func (uc *SuggestionUsecase) generateAssistantReply(ctx context.Context, promptInput service.SuggestionPromptInput) (string, []SuggestionBlock) {
	if uc.PromptBuilder == nil || uc.AIClient == nil {
		return fallbackSuggestionText(promptInput.IncomingMessage), nil
	}

	prompt := uc.PromptBuilder.Build(promptInput)
	completion, err := uc.AIClient.Complete(ctx, prompt)
	if err != nil {
		return fallbackSuggestionText(promptInput.IncomingMessage), nil
	}

	text, blocks, err := parseSuggestionAIContent(completion.Content)
	if err != nil {
		return fallbackSuggestionText(promptInput.IncomingMessage), nil
	}
	return text, blocks
}

func listAllTasks(ctx context.Context, repo repository.TaskRepository, userID string) ([]domain.Task, error) {
	opts := repository.ListOptions{Limit: defaultListAllLimit}
	out := make([]domain.Task, 0)
	for {
		items, next, err := repo.List(ctx, userID, opts)
		if err != nil {
			return nil, err
		}
		out = append(out, items...)
		if len(out) >= suggestionContextCap || next == nil || *next == "" {
			break
		}
		opts.Cursor = *next
	}
	if len(out) > suggestionContextCap {
		out = out[:suggestionContextCap]
	}
	return out, nil
}

func listAllReminders(ctx context.Context, repo repository.ReminderRepository, userID string) ([]domain.Reminder, error) {
	opts := repository.ListOptions{Limit: defaultListAllLimit}
	out := make([]domain.Reminder, 0)
	for {
		items, next, err := repo.List(ctx, userID, opts)
		if err != nil {
			return nil, err
		}
		out = append(out, items...)
		if len(out) >= suggestionContextCap || next == nil || *next == "" {
			break
		}
		opts.Cursor = *next
	}
	if len(out) > suggestionContextCap {
		out = out[:suggestionContextCap]
	}
	return out, nil
}

func listAllEvents(ctx context.Context, repo repository.EventRepository, userID string) ([]domain.Event, error) {
	opts := repository.ListOptions{Limit: defaultListAllLimit}
	out := make([]domain.Event, 0)
	for {
		items, next, err := repo.List(ctx, userID, opts)
		if err != nil {
			return nil, err
		}
		out = append(out, items...)
		if len(out) >= suggestionContextCap || next == nil || *next == "" {
			break
		}
		opts.Cursor = *next
	}
	if len(out) > suggestionContextCap {
		out = out[:suggestionContextCap]
	}
	return out, nil
}

func listAllRoutines(ctx context.Context, repo repository.RoutineRepository, userID string) ([]domain.Routine, error) {
	opts := repository.ListOptions{Limit: defaultListAllLimit}
	out := make([]domain.Routine, 0)
	for {
		items, next, err := repo.List(ctx, userID, opts)
		if err != nil {
			return nil, err
		}
		out = append(out, items...)
		if len(out) >= suggestionContextCap || next == nil || *next == "" {
			break
		}
		opts.Cursor = *next
	}
	if len(out) > suggestionContextCap {
		out = out[:suggestionContextCap]
	}
	return out, nil
}

func usecaseRoutineInputFromSuggestion(
	title string,
	recurrenceType string,
	weekdays []int,
	startTime string,
	endTime string,
	startsOn string,
	flagID *string,
	subflagID *string,
) RoutineInput {
	return RoutineInput{
		Title:          title,
		RecurrenceType: recurrenceType,
		Weekdays:       weekdays,
		StartTime:      startTime,
		EndTime:        endTime,
		StartsOn:       &startsOn,
		FlagID:         flagID,
		SubflagID:      subflagID,
	}
}

func parseSuggestionAIContent(raw string) (string, []SuggestionBlock, error) {
	type response struct {
		Text   string            `json:"text"`
		Blocks []SuggestionBlock `json:"blocks"`
	}

	payload := strings.TrimSpace(raw)
	if payload == "" {
		return "", nil, fmt.Errorf("empty_ai_content")
	}

	var parsed response
	if err := json.Unmarshal([]byte(payload), &parsed); err != nil {
		object, ok := extractFirstJSONObject([]byte(payload))
		if !ok {
			return "", nil, err
		}
		if err := json.Unmarshal(object, &parsed); err != nil {
			return "", nil, err
		}
	}

	text := normalizeString(parsed.Text)
	if text == "" {
		return "", nil, fmt.Errorf("missing_text")
	}

	blocks := normalizeSuggestionBlocks(parsed.Blocks)
	return text, blocks, nil
}

func normalizeSuggestionBlocks(blocks []SuggestionBlock) []SuggestionBlock {
	if len(blocks) == 0 {
		return nil
	}

	out := make([]SuggestionBlock, 0, len(blocks))
	for i, block := range blocks {
		normalized, ok := normalizeSuggestionBlock(block)
		if !ok {
			continue
		}
		if normalized.ID == "" {
			normalized.ID = fmt.Sprintf("block-%d", i+1)
		}
		out = append(out, normalized)
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

func normalizeSuggestionBlock(block SuggestionBlock) (SuggestionBlock, bool) {
	block.Type = strings.ToLower(strings.TrimSpace(block.Type))
	block.Title = normalizeString(block.Title)
	block.Rationale = normalizeString(block.Rationale)
	block.FlagID = normalizeOptionalString(block.FlagID)
	block.SubflagID = normalizeOptionalString(block.SubflagID)
	block.ID = normalizeString(block.ID)

	if block.Title == "" {
		return SuggestionBlock{}, false
	}

	switch block.Type {
	case "task":
		block.Weekdays = nil
		block.RecurrenceType = nil
	case "event":
		if block.StartsAt == nil {
			return SuggestionBlock{}, false
		}
		block.Weekdays = nil
		block.RecurrenceType = nil
	case "routine":
		block.Weekdays = normalizeWeekdays(block.Weekdays)
		if block.RecurrenceType != nil {
			value := strings.ToLower(normalizeString(*block.RecurrenceType))
			if value == "" {
				block.RecurrenceType = nil
			} else {
				block.RecurrenceType = &value
			}
		}
	default:
		return SuggestionBlock{}, false
	}

	if block.StartsAt != nil && block.EndsAt != nil && block.EndsAt.Before(*block.StartsAt) {
		return SuggestionBlock{}, false
	}

	return block, true
}

func normalizeWeekdays(input []int) []int {
	if len(input) == 0 {
		return nil
	}
	seen := map[int]struct{}{}
	out := make([]int, 0, len(input))
	for _, weekday := range input {
		if weekday < 0 || weekday > 6 {
			continue
		}
		if _, ok := seen[weekday]; ok {
			continue
		}
		seen[weekday] = struct{}{}
		out = append(out, weekday)
	}
	return out
}

func marshalSuggestionBlocks(blocks []SuggestionBlock) (json.RawMessage, error) {
	if len(blocks) == 0 {
		return nil, nil
	}
	raw, err := json.Marshal(blocks)
	if err != nil {
		return nil, err
	}
	return raw, nil
}

func parseStoredSuggestionBlocks(raw json.RawMessage) []SuggestionBlock {
	if len(raw) == 0 {
		return nil
	}
	var blocks []SuggestionBlock
	if err := json.Unmarshal(raw, &blocks); err != nil {
		return nil
	}
	return normalizeSuggestionBlocks(blocks)
}

func fallbackSuggestionText(message string) string {
	trimmed := normalizeString(message)
	if trimmed == "" {
		return "Posso te ajudar a montar um plano para os próximos dias."
	}
	return "Entendi. Posso montar um plano objetivo para isso em blocos de tempo, se você me confirmar os melhores horários."
}

func extractFirstJSONObject(raw []byte) ([]byte, bool) {
	start := -1
	depth := 0
	inString := false
	escaped := false

	for i, ch := range raw {
		if inString {
			if escaped {
				escaped = false
				continue
			}
			if ch == '\\' {
				escaped = true
				continue
			}
			if ch == '"' {
				inString = false
			}
			continue
		}

		switch ch {
		case '"':
			inString = true
		case '{':
			if depth == 0 {
				start = i
			}
			depth++
		case '}':
			if depth == 0 {
				continue
			}
			depth--
			if depth == 0 && start >= 0 {
				return bytes.TrimSpace(raw[start : i+1]), true
			}
		}
	}

	return nil, false
}
