package usecase

import (
	"context"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/app/service"
)

func (uc *InboxUsecase) applyValidatedSuggestionTx(ctx context.Context, tx repository.TxRepositories, userID string, item domain.InboxItem, vout service.ValidatedOutput) error {
	typ, ok := parseSuggestionType(vout.Output.Type)
	if !ok || typ == domain.AiSuggestionTypeNote {
		return ErrInvalidType
	}

	switch typ {
	case domain.AiSuggestionTypeTask:
		if tx.Tasks == nil || uc.TasksUsecase == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.TaskPayload)
		if !ok {
			return ErrInvalidPayload
		}
		taskUC := *uc.TasksUsecase
		taskUC.Tasks = tx.Tasks
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		_, err := taskUC.Create(ctx, userID, vout.Output.Title, nil, nil, p.DueAt, fID, sfID, &item.ID)
		return err

	case domain.AiSuggestionTypeReminder:
		if tx.Reminders == nil || uc.RemindersUsecase == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.ReminderPayload)
		if !ok {
			return ErrInvalidPayload
		}
		remUC := *uc.RemindersUsecase
		remUC.Reminders = tx.Reminders
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		_, err := remUC.Create(ctx, userID, vout.Output.Title, nil, &p.At, fID, sfID, &item.ID)
		return err

	case domain.AiSuggestionTypeEvent:
		if tx.Events == nil || uc.EventsUsecase == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.EventPayload)
		if !ok {
			return ErrInvalidPayload
		}
		eventUC := *uc.EventsUsecase
		eventUC.Events = tx.Events
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		_, err := eventUC.Create(ctx, userID, vout.Output.Title, &p.Start, p.End, &p.AllDay, nil, fID, sfID, &item.ID)
		return err

	case domain.AiSuggestionTypeRoutine:
		if uc.RoutinesUsecase == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.RoutinePayload)
		if !ok {
			return ErrInvalidPayload
		}
		routineUC := *uc.RoutinesUsecase
		routineUC.Routines = tx.Routines
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		_, err := routineUC.Create(ctx, userID, RoutineInput{
			Title:             vout.Output.Title,
			RecurrenceType:    p.RecurrenceType,
			Weekdays:          p.Weekdays,
			StartTime:         p.StartTime,
			EndTime:           p.EndTime,
			WeekOfMonth:       p.WeekOfMonth,
			StartsOn:          p.StartsOn,
			EndsOn:            p.EndsOn,
			FlagID:            fID,
			SubflagID:         sfID,
			SourceInboxItemID: &item.ID,
		})
		return err

	case domain.AiSuggestionTypeShopping:
		// Shopping stays repo-level.
		if tx.ShoppingLists == nil || tx.ShoppingItems == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.ShoppingPayload)
		if !ok {
			return ErrInvalidPayload
		}
		list := domain.ShoppingList{UserID: userID, Title: vout.Output.Title, SourceInboxItemID: &item.ID}
		createdList, err := tx.ShoppingLists.Create(ctx, list)
		if err != nil {
			return err
		}
		for idx, shopItem := range p.Items {
			si := domain.ShoppingItem{UserID: userID, ListID: createdList.ID, Title: shopItem.Title, Quantity: shopItem.Quantity, Checked: false, SortOrder: idx}
			if _, err := tx.ShoppingItems.Create(ctx, si); err != nil {
				return err
			}
		}
		return nil
	default:
		return ErrInvalidType
	}
}

func (uc *InboxUsecase) applyValidatedSuggestionNoTx(ctx context.Context, userID string, item domain.InboxItem, vout service.ValidatedOutput) error {
	// Best-effort fallback. In production, TxRunner should be configured.
	typ, ok := parseSuggestionType(vout.Output.Type)
	if !ok || typ == domain.AiSuggestionTypeNote {
		return ErrInvalidType
	}

	switch typ {
	case domain.AiSuggestionTypeTask:
		if uc.TasksUsecase == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.TaskPayload)
		if !ok {
			return ErrInvalidPayload
		}
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		_, err := uc.TasksUsecase.Create(ctx, userID, vout.Output.Title, nil, nil, p.DueAt, fID, sfID, &item.ID)
		return err
	case domain.AiSuggestionTypeReminder:
		if uc.RemindersUsecase == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.ReminderPayload)
		if !ok {
			return ErrInvalidPayload
		}
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		_, err := uc.RemindersUsecase.Create(ctx, userID, vout.Output.Title, nil, &p.At, fID, sfID, &item.ID)
		return err
	case domain.AiSuggestionTypeEvent:
		if uc.EventsUsecase == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.EventPayload)
		if !ok {
			return ErrInvalidPayload
		}
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		_, err := uc.EventsUsecase.Create(ctx, userID, vout.Output.Title, &p.Start, p.End, &p.AllDay, nil, fID, sfID, &item.ID)
		return err
	case domain.AiSuggestionTypeRoutine:
		if uc.RoutinesUsecase == nil {
			return ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.RoutinePayload)
		if !ok {
			return ErrInvalidPayload
		}
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		_, err := uc.RoutinesUsecase.Create(ctx, userID, RoutineInput{
			Title:             vout.Output.Title,
			RecurrenceType:    p.RecurrenceType,
			Weekdays:          p.Weekdays,
			StartTime:         p.StartTime,
			EndTime:           p.EndTime,
			WeekOfMonth:       p.WeekOfMonth,
			StartsOn:          p.StartsOn,
			EndsOn:            p.EndsOn,
			FlagID:            fID,
			SubflagID:         sfID,
			SourceInboxItemID: &item.ID,
		})
		return err
	case domain.AiSuggestionTypeShopping:
		// Keep existing non-tx behavior.
		return ErrDependencyMissing
	default:
		return ErrInvalidType
	}
}
