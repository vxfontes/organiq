package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"regexp"
	"strings"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/app/service"
)

type InboxUsecase struct {
	Users           repository.UserRepository
	Inbox           repository.InboxRepository
	Suggestions     repository.AiSuggestionRepository
	Flags           repository.FlagRepository
	Subflags        repository.SubflagRepository
	ContextRules    repository.ContextRuleRepository
	Tasks           repository.TaskRepository
	Reminders       repository.ReminderRepository
	Events          repository.EventRepository
	ShoppingLists   repository.ShoppingListRepository
	ShoppingItems   repository.ShoppingItemRepository
	RoutinesUsecase *RoutineUsecase
	PromptBuilder   *service.PromptBuilder
	AIClient        service.AIClient
	SchemaValidator *service.AiSchemaValidator
	RuleMatcher     *service.ContextRuleMatcher
	TxRunner        repository.TxRunner
	Now             func() time.Time
}

type InboxListInput struct {
	Status *string
	Source *string
}

type InboxItemResult struct {
	Item       domain.InboxItem
	Suggestion *domain.AiSuggestion
}

type ConfirmInboxInput struct {
	Type      string
	Title     string
	FlagID    *string
	SubflagID *string
	Payload   json.RawMessage
}

type ConfirmResult struct {
	Type          domain.AiSuggestionType
	Task          *domain.Task
	Reminder      *domain.Reminder
	Event         *domain.Event
	ShoppingList  *domain.ShoppingList
	ShoppingItems []domain.ShoppingItem
	Routine       *domain.Routine
}

func (uc *InboxUsecase) CreateInboxItem(ctx context.Context, userID string, source *string, rawText string, rawMediaURL *string) (domain.InboxItem, error) {
	rawText = normalizeString(rawText)
	if userID == "" || rawText == "" {
		return domain.InboxItem{}, ErrMissingRequiredFields
	}

	item := domain.InboxItem{
		UserID:      userID,
		RawText:     rawText,
		RawMediaURL: normalizeOptionalString(rawMediaURL),
		Status:      domain.InboxStatusNew,
		Source:      domain.InboxSourceManual,
	}
	if source != nil && strings.TrimSpace(*source) != "" {
		parsed, ok := parseInboxSource(*source)
		if !ok {
			return domain.InboxItem{}, ErrInvalidSource
		}
		item.Source = parsed
	}

	return uc.Inbox.Create(ctx, item)
}

func (uc *InboxUsecase) ListInboxItems(ctx context.Context, userID string, input InboxListInput, opts repository.ListOptions) ([]InboxItemResult, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}

	filter := repository.InboxListFilter{}
	if input.Status != nil && strings.TrimSpace(*input.Status) != "" {
		parsed, ok := parseInboxStatus(*input.Status)
		if !ok {
			return nil, nil, ErrInvalidStatus
		}
		filter.Status = &parsed
	}
	if input.Source != nil && strings.TrimSpace(*input.Source) != "" {
		parsed, ok := parseInboxSource(*input.Source)
		if !ok {
			return nil, nil, ErrInvalidSource
		}
		filter.Source = &parsed
	}

	items, next, err := uc.Inbox.ListWithSuggestion(ctx, userID, filter, opts)
	if err != nil {
		return nil, nil, err
	}

	results := make([]InboxItemResult, 0, len(items))
	for _, item := range items {
		var suggestion *domain.AiSuggestion
		if item.SuggestionID != nil {
			suggestion = &domain.AiSuggestion{
				ID:          *item.SuggestionID,
				UserID:      item.UserID,
				InboxItemID: item.ID,
				Type:        domain.AiSuggestionType(*item.SuggestionType),
				Title:       *item.SuggestionTitle,
				Confidence:  item.SuggestionConfidence,
				FlagID:      item.SuggestionFlagID,
				SubflagID:   item.SuggestionSubflagID,
				PayloadJSON: item.PayloadJSON,
			}
			if item.SuggestionNeedsReview != nil {
				suggestion.NeedsReview = *item.SuggestionNeedsReview
			}
			if item.SuggestionCreatedAt != nil {
				suggestion.CreatedAt = *item.SuggestionCreatedAt
			}
		}
		results = append(results, InboxItemResult{Item: item.InboxItem, Suggestion: suggestion})
	}

	return results, next, nil
}

func (uc *InboxUsecase) GetInboxItem(ctx context.Context, userID, id string) (InboxItemResult, error) {
	if userID == "" || id == "" {
		return InboxItemResult{}, ErrMissingRequiredFields
	}
	item, err := uc.Inbox.GetWithSuggestion(ctx, userID, id)
	if err != nil {
		return InboxItemResult{}, err
	}

	var suggestion *domain.AiSuggestion
	if item.SuggestionID != nil {
		suggestion = &domain.AiSuggestion{
			ID:          *item.SuggestionID,
			UserID:      item.UserID,
			InboxItemID: item.ID,
			Type:        domain.AiSuggestionType(*item.SuggestionType),
			Title:       *item.SuggestionTitle,
			Confidence:  item.SuggestionConfidence,
			FlagID:      item.SuggestionFlagID,
			SubflagID:   item.SuggestionSubflagID,
			PayloadJSON: item.PayloadJSON,
		}
		if item.SuggestionNeedsReview != nil {
			suggestion.NeedsReview = *item.SuggestionNeedsReview
		}
		if item.SuggestionCreatedAt != nil {
			suggestion.CreatedAt = *item.SuggestionCreatedAt
		}
	}

	return InboxItemResult{Item: item.InboxItem, Suggestion: suggestion}, nil
}

func (uc *InboxUsecase) GetInboxItemsByIDs(ctx context.Context, userID string, ids []string) (map[string]domain.InboxItem, error) {
	if userID == "" {
		return nil, ErrMissingRequiredFields
	}
	if len(ids) == 0 {
		return map[string]domain.InboxItem{}, nil
	}
	items, err := uc.Inbox.GetByIDs(ctx, userID, ids)
	if err != nil {
		return nil, err
	}
	out := make(map[string]domain.InboxItem, len(items))
	for _, item := range items {
		out[item.ID] = item
	}
	return out, nil
}

func (uc *InboxUsecase) ReprocessInboxItem(ctx context.Context, userID, id string) (InboxItemResult, error) {
	if userID == "" || id == "" {
		return InboxItemResult{}, ErrMissingRequiredFields
	}
	if uc.Inbox == nil || uc.AIClient == nil {
		return InboxItemResult{}, ErrDependencyMissing
	}
	if uc.PromptBuilder == nil || uc.SchemaValidator == nil {
		return InboxItemResult{}, ErrDependencyMissing
	}
	if uc.Users == nil || uc.Flags == nil || uc.Subflags == nil || uc.ContextRules == nil {
		return InboxItemResult{}, ErrDependencyMissing
	}

	item, err := uc.Inbox.Get(ctx, userID, id)
	if err != nil {
		return InboxItemResult{}, err
	}
	if item.Status == domain.InboxStatusConfirmed || item.Status == domain.InboxStatusDismissed {
		return InboxItemResult{}, ErrInvalidStatus
	}

	item.Status = domain.InboxStatusProcessing
	item.LastError = nil
	item, err = uc.Inbox.Update(ctx, item)
	if err != nil {
		return InboxItemResult{}, err
	}

	user, err := uc.Users.Get(ctx, userID)
	if err != nil {
		return InboxItemResult{}, err
	}

	now := time.Now()
	if uc.Now != nil {
		now = uc.Now()
	}

	// Default fallback: Brazil timezone.
	fallbackLoc, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		fallbackLoc = now.Location()
	}

	if tz := strings.TrimSpace(user.Timezone); tz != "" {
		if loc, err := time.LoadLocation(tz); err == nil {
			now = now.In(loc)
		} else {
			now = now.In(fallbackLoc)
		}
	} else {
		now = now.In(fallbackLoc)
	}

	flags, err := listAllFlags(ctx, uc.Flags, userID)
	if err != nil {
		return InboxItemResult{}, err
	}
	subflagsByFlag := make(map[string][]domain.Subflag, len(flags))
	for _, flag := range flags {
		subflags, err := listAllSubflags(ctx, uc.Subflags, userID, flag.ID)
		if err != nil {
			return InboxItemResult{}, err
		}
		subflagsByFlag[flag.ID] = subflags
	}
	rules, err := listAllContextRules(ctx, uc.ContextRules, userID)
	if err != nil {
		return InboxItemResult{}, err
	}

	contexts := make([]service.ContextItem, 0)
	for _, flag := range flags {
		flagName := flag.Name
		contexts = append(contexts, service.ContextItem{
			FlagID:   flag.ID,
			FlagName: flagName,
		})
		for _, sub := range subflagsByFlag[flag.ID] {
			subID := sub.ID
			subName := sub.Name
			contexts = append(contexts, service.ContextItem{
				FlagID:      flag.ID,
				FlagName:    flagName,
				SubflagID:   &subID,
				SubflagName: &subName,
			})
		}
	}

	ruleItems := make([]service.RuleItem, 0, len(rules))
	for _, rule := range rules {
		ruleItems = append(ruleItems, service.RuleItem{
			Keyword:   rule.Keyword,
			FlagID:    rule.FlagID,
			SubflagID: rule.SubflagID,
		})
	}

	var hint *service.ContextHint
	matcher := uc.RuleMatcher
	if matcher != nil {
		if match := matcher.Match(item.RawText, rules); match != nil {
			reason := "keyword:" + match.Keyword
			hint = &service.ContextHint{
				FlagID:    match.FlagID,
				SubflagID: match.SubflagID,
				Reason:    reason,
			}
		}
	}

	prompt := uc.PromptBuilder.Build(service.PromptInput{
		RawText:  item.RawText,
		Locale:   strings.TrimSpace(user.Locale),
		Timezone: strings.TrimSpace(user.Timezone),
		Now:      now,
		Contexts: contexts,
		Rules:    ruleItems,
		Hint:     hint,
	})

	completion, err := uc.AIClient.Complete(ctx, prompt)
	if err != nil {
		return uc.failInboxProcessing(ctx, item, err)
	}

	usedHardFallback := false
	validated, err := uc.SchemaValidator.Validate([]byte(completion.Content))
	if err != nil {
		if !errors.Is(err, service.ErrAISchemaInvalid) {
			return uc.failInboxProcessing(ctx, item, err)
		}

		if fallbackClient, ok := uc.AIClient.(service.AIClientWithFallback); ok {
			fallbackModel := strings.TrimSpace(fallbackClient.FallbackModel())
			if fallbackModel != "" && !strings.EqualFold(strings.TrimSpace(completion.Model), fallbackModel) {
				fallbackCompletion, fallbackErr := fallbackClient.CompleteWithModel(ctx, prompt, fallbackModel)
				if fallbackErr == nil {
					if fallbackValidated, fallbackValErr := uc.SchemaValidator.Validate([]byte(fallbackCompletion.Content)); fallbackValErr == nil {
						completion = fallbackCompletion
						validated = fallbackValidated
						err = nil
					}
				}
			}
		}

		if err == nil {
			goto validatedOutputReady
		}

		var fallbackContext *service.AIContext
		if hint != nil {
			flagID := strings.TrimSpace(hint.FlagID)
			var flagIDPtr *string
			if flagID != "" {
				flagIDCopy := flagID
				flagIDPtr = &flagIDCopy
			}
			var subflagIDPtr *string
			if hint.SubflagID != nil {
				subflagID := strings.TrimSpace(*hint.SubflagID)
				if subflagID != "" {
					subflagIDCopy := subflagID
					subflagIDPtr = &subflagIDCopy
				}
			}
			fallbackContext = &service.AIContext{
				FlagID:    flagIDPtr,
				SubflagID: subflagIDPtr,
			}
		}

		validated = service.BuildFallbackTaskOutput(item.RawText, fallbackContext)
		usedHardFallback = true
	}

validatedOutputReady:
	if !usedHardFallback && validated.Output.NeedsReview {
		if fallbackClient, ok := uc.AIClient.(service.AIClientWithFallback); ok && fallbackClient.FallbackOnNeedsReview() {
			fallbackModel := strings.TrimSpace(fallbackClient.FallbackModel())
			if fallbackModel != "" && !strings.EqualFold(strings.TrimSpace(completion.Model), fallbackModel) {
				fallbackCompletion, fallbackErr := fallbackClient.CompleteWithModel(ctx, prompt, fallbackModel)
				if fallbackErr == nil {
					if fallbackValidated, fallbackValErr := uc.SchemaValidator.Validate([]byte(fallbackCompletion.Content)); fallbackValErr == nil {
						completion = fallbackCompletion
						validated = fallbackValidated
					}
				}
			}
		}
	}

	suggestion := domain.AiSuggestion{
		UserID:      userID,
		InboxItemID: item.ID,
		Type:        domain.AiSuggestionType(validated.Output.Type),
		Title:       validated.Output.Title,
		Confidence:  validated.Output.Confidence,
		NeedsReview: validated.Output.NeedsReview,
		PayloadJSON: validated.Output.Payload,
	}
	if validated.Output.Context != nil {
		suggestion.FlagID = normalizeOptionalString(validated.Output.Context.FlagID)
		suggestion.SubflagID = normalizeOptionalString(validated.Output.Context.SubflagID)
	}

	if uc.TxRunner != nil {
		if err := uc.TxRunner.WithTx(ctx, func(tx repository.TxRepositories) error {
			if tx.Suggestions == nil || tx.Inbox == nil {
				return ErrDependencyMissing
			}
			var err error
			suggestion, err = tx.Suggestions.Create(ctx, suggestion)
			if err != nil {
				return err
			}
			if suggestion.NeedsReview {
				item.Status = domain.InboxStatusNeedsReview
			} else {
				item.Status = domain.InboxStatusSuggested
			}
			item.LastError = nil
			item, err = tx.Inbox.Update(ctx, item)
			if err != nil {
				return err
			}
			return nil
		}); err != nil {
			return InboxItemResult{}, err
		}
	} else {
		if uc.Suggestions == nil {
			return InboxItemResult{}, ErrDependencyMissing
		}
		suggestion, err = uc.Suggestions.Create(ctx, suggestion)
		if err != nil {
			return InboxItemResult{}, err
		}

		if suggestion.NeedsReview {
			item.Status = domain.InboxStatusNeedsReview
		} else {
			item.Status = domain.InboxStatusSuggested
		}
		item.LastError = nil
		item, err = uc.Inbox.Update(ctx, item)
		if err != nil {
			return InboxItemResult{}, err
		}
	}

	return InboxItemResult{Item: item, Suggestion: &suggestion}, nil
}

func (uc *InboxUsecase) ConfirmInboxItem(ctx context.Context, userID, id string, input ConfirmInboxInput) (ConfirmResult, error) {
	title := normalizeString(input.Title)
	if userID == "" || id == "" || title == "" || input.Type == "" {
		return ConfirmResult{}, ErrMissingRequiredFields
	}
	if uc.SchemaValidator == nil || uc.Inbox == nil {
		return ConfirmResult{}, ErrDependencyMissing
	}

	typ, ok := parseSuggestionType(input.Type)
	if !ok || typ == domain.AiSuggestionTypeNote {
		return ConfirmResult{}, ErrInvalidType
	}

	item, err := uc.Inbox.Get(ctx, userID, id)
	if err != nil {
		return ConfirmResult{}, err
	}
	if item.Status == domain.InboxStatusConfirmed || item.Status == domain.InboxStatusDismissed {
		return ConfirmResult{}, ErrInvalidStatus
	}

	hintFlagID := normalizeOptionalString(input.FlagID)
	hintSubflagID := normalizeOptionalString(input.SubflagID)
	var ctxHint *service.AIContext
	if hintFlagID != nil || hintSubflagID != nil {
		ctxHint = &service.AIContext{
			FlagID:    hintFlagID,
			SubflagID: hintSubflagID,
		}
	}

	payload := input.Payload
	if len(payload) == 0 {
		return ConfirmResult{}, ErrMissingRequiredFields
	}
	output := service.AIOutput{
		Type:        string(typ),
		Title:       title,
		NeedsReview: false,
		Context:     ctxHint,
		Payload:     payload,
	}
	raw, err := json.Marshal(output)
	if err != nil {
		return ConfirmResult{}, err
	}
	validated, err := uc.SchemaValidator.Validate(raw)
	if err != nil {
		return ConfirmResult{}, err
	}

	result := ConfirmResult{Type: typ}
	var flagID *string
	var subflagID *string
	if validated.Output.Context != nil {
		rawFlagID := normalizeOptionalString(validated.Output.Context.FlagID)
		rawSubflagID := normalizeOptionalString(validated.Output.Context.SubflagID)

		if uc.RoutinesUsecase != nil {
			var err error
			flagID, subflagID, err = uc.RoutinesUsecase.ResolveFlagAndSubflag(ctx, userID, rawFlagID, rawSubflagID)
			if err != nil {
				return ConfirmResult{}, err
			}
		} else {
			flagID = rawFlagID
			subflagID = rawSubflagID
		}
	}

	// Get current time in user timezone for weekday guardrail.
	now := time.Now()
	if uc.Now != nil {
		now = uc.Now()
	}
	fallbackLoc, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		fallbackLoc = now.Location()
	}
	if uc.Users != nil {
		user, err := uc.Users.Get(ctx, userID)
		if err == nil {
			if tz := strings.TrimSpace(user.Timezone); tz != "" {
				if loc, err := time.LoadLocation(tz); err == nil {
					now = now.In(loc)
				} else {
					now = now.In(fallbackLoc)
				}
			} else {
				now = now.In(fallbackLoc)
			}
		} else {
			now = now.In(fallbackLoc)
		}
	} else {
		now = now.In(fallbackLoc)
	}

	if uc.TxRunner != nil {
		if err := uc.TxRunner.WithTx(ctx, func(tx repository.TxRepositories) error {
			if tx.Inbox == nil {
				return ErrDependencyMissing
			}
			switch typ {
			case domain.AiSuggestionTypeTask:
				if tx.Tasks == nil {
					return ErrDependencyMissing
				}
				taskPayload, ok := validated.Payload.(service.TaskPayload)
				if !ok {
					return ErrInvalidPayload
				}
				task := domain.Task{
					UserID:            userID,
					Title:             title,
					DueAt:             taskPayload.DueAt,
					FlagID:            flagID,
					SubflagID:         subflagID,
					SourceInboxItemID: &item.ID,
				}
				created, err := tx.Tasks.Create(ctx, task)
				if err != nil {
					return err
				}
				result.Task = &created
			case domain.AiSuggestionTypeReminder:
				if tx.Reminders == nil {
					return ErrDependencyMissing
				}
				reminderPayload, ok := validated.Payload.(service.ReminderPayload)
				if !ok {
					return ErrInvalidPayload
				}

				fixWeekdayMismatch(&reminderPayload.At, nil, item.RawText, now)

				reminder := domain.Reminder{
					UserID:            userID,
					Title:             title,
					RemindAt:          &reminderPayload.At,
					FlagID:            flagID,
					SubflagID:         subflagID,
					SourceInboxItemID: &item.ID,
				}
				created, err := tx.Reminders.Create(ctx, reminder)
				if err != nil {
					return err
				}
				result.Reminder = &created
			case domain.AiSuggestionTypeEvent:
				if tx.Events == nil {
					return ErrDependencyMissing
				}
				eventPayload, ok := validated.Payload.(service.EventPayload)
				if !ok {
					return ErrInvalidPayload
				}

				// Guardrail: if the user explicitly mentioned a weekday (e.g. "sexta") and the
				// model returned a different weekday (e.g. sábado), fix it deterministically.
				fixWeekdayMismatch(&eventPayload.Start, eventPayload.End, item.RawText, now)

				event := domain.Event{
					UserID:            userID,
					Title:             title,
					StartAt:           &eventPayload.Start,
					EndAt:             eventPayload.End,
					AllDay:            eventPayload.AllDay,
					FlagID:            flagID,
					SubflagID:         subflagID,
					SourceInboxItemID: &item.ID,
				}
				created, err := tx.Events.Create(ctx, event)
				if err != nil {
					return err
				}
				result.Event = &created
			case domain.AiSuggestionTypeShopping:
				if tx.ShoppingLists == nil || tx.ShoppingItems == nil {
					return ErrDependencyMissing
				}
				shopPayload, ok := validated.Payload.(service.ShoppingPayload)
				if !ok {
					return ErrInvalidPayload
				}
				list := domain.ShoppingList{
					UserID:            userID,
					Title:             title,
					SourceInboxItemID: &item.ID,
				}
				createdList, err := tx.ShoppingLists.Create(ctx, list)
				if err != nil {
					return err
				}
				result.ShoppingList = &createdList

				items := make([]domain.ShoppingItem, 0, len(shopPayload.Items))
				for idx, shopItem := range shopPayload.Items {
					item := domain.ShoppingItem{
						UserID:    userID,
						ListID:    createdList.ID,
						Title:     shopItem.Title,
						Quantity:  shopItem.Quantity,
						Checked:   false,
						SortOrder: idx,
					}
					created, err := tx.ShoppingItems.Create(ctx, item)
					if err != nil {
						return err
					}
					items = append(items, created)
				}
				result.ShoppingItems = items
			case domain.AiSuggestionTypeRoutine:
				if tx.Routines == nil {
					return ErrDependencyMissing
				}
				routinePayload, ok := validated.Payload.(service.RoutinePayload)
				if !ok {
					return ErrInvalidPayload
				}
				startsOn := time.Now().Format("2006-01-02")
				if routinePayload.StartsOn != nil {
					startsOn = *routinePayload.StartsOn
				}
				routine := domain.Routine{
					UserID:            userID,
					Title:             title,
					RecurrenceType:    routinePayload.RecurrenceType,
					Weekdays:          routinePayload.Weekdays,
					StartTime:         routinePayload.StartTime,
					EndTime:           routinePayload.EndTime,
					WeekOfMonth:       routinePayload.WeekOfMonth,
					StartsOn:          startsOn,
					EndsOn:            routinePayload.EndsOn,
					IsActive:          true,
					FlagID:            flagID,
					SubflagID:         subflagID,
					SourceInboxItemID: &item.ID,
				}
				if uc.RoutinesUsecase != nil {
					if err := uc.RoutinesUsecase.Validate(ctx, routine); err != nil {
						return err
					}
				}
				created, err := tx.Routines.Create(ctx, routine)
				if err != nil {
					return err
				}
				result.Routine = &created
			default:
				return ErrInvalidType
			}

			item.Status = domain.InboxStatusConfirmed
			item.LastError = nil
			if _, err := tx.Inbox.Update(ctx, item); err != nil {
				return err
			}
			return nil
		}); err != nil {
			return ConfirmResult{}, err
		}
	} else {
		switch typ {
		case domain.AiSuggestionTypeTask:
			if uc.Tasks == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			taskPayload, ok := validated.Payload.(service.TaskPayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			task := domain.Task{
				UserID:            userID,
				Title:             title,
				DueAt:             taskPayload.DueAt,
				FlagID:            flagID,
				SubflagID:         subflagID,
				SourceInboxItemID: &item.ID,
			}
			created, err := uc.Tasks.Create(ctx, task)
			if err != nil {
				return ConfirmResult{}, err
			}
			result.Task = &created
		case domain.AiSuggestionTypeReminder:
			if uc.Reminders == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			reminderPayload, ok := validated.Payload.(service.ReminderPayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			reminder := domain.Reminder{
				UserID:            userID,
				Title:             title,
				RemindAt:          &reminderPayload.At,
				FlagID:            flagID,
				SubflagID:         subflagID,
				SourceInboxItemID: &item.ID,
			}
			created, err := uc.Reminders.Create(ctx, reminder)
			if err != nil {
				return ConfirmResult{}, err
			}
			result.Reminder = &created
		case domain.AiSuggestionTypeEvent:
			if uc.Events == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			eventPayload, ok := validated.Payload.(service.EventPayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			event := domain.Event{
				UserID:            userID,
				Title:             title,
				StartAt:           &eventPayload.Start,
				EndAt:             eventPayload.End,
				AllDay:            eventPayload.AllDay,
				FlagID:            flagID,
				SubflagID:         subflagID,
				SourceInboxItemID: &item.ID,
			}
			created, err := uc.Events.Create(ctx, event)
			if err != nil {
				return ConfirmResult{}, err
			}
			result.Event = &created
		case domain.AiSuggestionTypeShopping:
			if uc.ShoppingLists == nil || uc.ShoppingItems == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			shopPayload, ok := validated.Payload.(service.ShoppingPayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			list := domain.ShoppingList{
				UserID:            userID,
				Title:             title,
				SourceInboxItemID: &item.ID,
			}
			createdList, err := uc.ShoppingLists.Create(ctx, list)
			if err != nil {
				return ConfirmResult{}, err
			}
			result.ShoppingList = &createdList

			items := make([]domain.ShoppingItem, 0, len(shopPayload.Items))
			for idx, shopItem := range shopPayload.Items {
				item := domain.ShoppingItem{
					UserID:    userID,
					ListID:    createdList.ID,
					Title:     shopItem.Title,
					Quantity:  shopItem.Quantity,
					Checked:   false,
					SortOrder: idx,
				}
				created, err := uc.ShoppingItems.Create(ctx, item)
				if err != nil {
					return ConfirmResult{}, err
				}
				items = append(items, created)
			}
			result.ShoppingItems = items
		case domain.AiSuggestionTypeRoutine:
			if uc.RoutinesUsecase == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			routinePayload, ok := validated.Payload.(service.RoutinePayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			startsOn := time.Now().Format("2006-01-02")
			if routinePayload.StartsOn != nil {
				startsOn = *routinePayload.StartsOn
			}
			routine := domain.Routine{
				UserID:            userID,
				Title:             title,
				RecurrenceType:    routinePayload.RecurrenceType,
				Weekdays:          routinePayload.Weekdays,
				StartTime:         routinePayload.StartTime,
				EndTime:           routinePayload.EndTime,
				WeekOfMonth:       routinePayload.WeekOfMonth,
				StartsOn:          startsOn,
				EndsOn:            routinePayload.EndsOn,
				IsActive:          true,
				FlagID:            flagID,
				SubflagID:         subflagID,
				SourceInboxItemID: &item.ID,
			}
			if uc.RoutinesUsecase != nil {
				if err := uc.RoutinesUsecase.Validate(ctx, routine); err != nil {
					return ConfirmResult{}, err
				}
				created, err := uc.RoutinesUsecase.Routines.Create(ctx, routine)
				if err != nil {
					return ConfirmResult{}, err
				}
				result.Routine = &created
			} else {
				return ConfirmResult{}, ErrDependencyMissing
			}
		default:
			return ConfirmResult{}, ErrInvalidType
		}

		item.Status = domain.InboxStatusConfirmed
		item.LastError = nil
		if _, err := uc.Inbox.Update(ctx, item); err != nil {
			return ConfirmResult{}, err
		}
	}

	return result, nil
}

func (uc *InboxUsecase) DismissInboxItem(ctx context.Context, userID, id string) (domain.InboxItem, error) {
	if userID == "" || id == "" {
		return domain.InboxItem{}, ErrMissingRequiredFields
	}
	item, err := uc.Inbox.Get(ctx, userID, id)
	if err != nil {
		return domain.InboxItem{}, err
	}
	if item.Status == domain.InboxStatusConfirmed {
		return domain.InboxItem{}, ErrInvalidStatus
	}
	item.Status = domain.InboxStatusDismissed
	item.LastError = nil
	return uc.Inbox.Update(ctx, item)
}

func (uc *InboxUsecase) failInboxProcessing(ctx context.Context, item domain.InboxItem, cause error) (InboxItemResult, error) {
	errText := cause.Error()
	if len(errText) > 500 {
		errText = errText[:500]
	}
	item.Status = domain.InboxStatusNeedsReview
	item.LastError = &errText
	updated, err := uc.Inbox.Update(ctx, item)
	if err != nil {
		return InboxItemResult{}, err
	}
	return InboxItemResult{Item: updated}, nil
}

func fixWeekdayMismatch(start *time.Time, end *time.Time, rawText string, now time.Time) {
	if start == nil {
		return
	}
	if hasExplicitDate(rawText) {
		return
	}

	weekday, ok := detectSingleWeekdayMention(rawText)
	if !ok {
		return
	}

	loc := now.Location()
	startLocal := start.In(loc)
	if startLocal.Weekday() == weekday {
		return
	}

	// Build the next occurrence for the requested weekday.
	nextDate := nextOccurrenceOfWeekday(now, weekday)

	fixedStart := time.Date(
		nextDate.Year(), nextDate.Month(), nextDate.Day(),
		startLocal.Hour(), startLocal.Minute(), startLocal.Second(), startLocal.Nanosecond(),
		loc,
	)

	// Preserve duration if we have an end.
	if end != nil {
		endLocal := end.In(loc)
		dur := endLocal.Sub(startLocal)
		fixedEnd := fixedStart.Add(dur)
		*end = fixedEnd
	}

	*start = fixedStart
}

func hasExplicitDate(text string) bool {
	lower := strings.ToLower(text)
	// very lightweight checks
	if regexp.MustCompile(`\b\d{4}-\d{2}-\d{2}\b`).FindStringIndex(lower) != nil {
		return true
	}
	if regexp.MustCompile(`\b\d{1,2}/\d{1,2}(?:/\d{2,4})?\b`).FindStringIndex(lower) != nil {
		return true
	}
	return false
}

func detectSingleWeekdayMention(text string) (time.Weekday, bool) {
	lower := strings.ToLower(text)
	// Map of portuguese weekday tokens.
	tokens := map[time.Weekday][]string{
		time.Sunday:    {"domingo"},
		time.Monday:    {"segunda"},
		time.Tuesday:   {"terça", "terca"},
		time.Wednesday: {"quarta"},
		time.Thursday:  {"quinta"},
		time.Friday:    {"sexta"},
		time.Saturday:  {"sábado", "sabado"},
	}

	found := []time.Weekday{}
	for wd, list := range tokens {
		for _, t := range list {
			if regexp.MustCompile(`\b`+regexp.QuoteMeta(t)+`(\-feira)?\b`).FindStringIndex(lower) != nil {
				found = append(found, wd)
				break
			}
		}
	}

	if len(found) != 1 {
		return time.Sunday, false
	}
	return found[0], true
}

func nextOccurrenceOfWeekday(now time.Time, target time.Weekday) time.Time {
	start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	nowWd := start.Weekday()
	delta := (int(target) - int(nowWd) + 7) % 7
	// If it's today, keep today only if the time hasn't passed. We'll handle this by
	// allowing today and letting the fixedStart use the AI time.
	if delta == 0 {
		return start
	}
	return start.AddDate(0, 0, delta)
}
