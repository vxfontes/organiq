package usecase

import (
	"context"
	"errors"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/app/service"
	"organiq/backend/internal/infra/postgres"
)

type EventUsecase struct {
	Events           repository.EventRepository
	Flags            repository.FlagRepository
	Subflags         repository.SubflagRepository
	NotificationLog  repository.NotificationLogRepository
	NotificationCopy *service.NotificationCopyService
}

type EventUpdateInput struct {
	Title     *string
	StartAt   *time.Time
	EndAt     *time.Time
	AllDay    *bool
	Location  *string
	FlagID    *string
	SubflagID *string
}

func (uc *EventUsecase) Create(ctx context.Context, userID, title string, startAt, endAt *time.Time, allDay *bool, location *string, flagID *string, subflagID *string, sourceInboxItemID *string) (domain.Event, error) {
	title = normalizeString(title)
	if userID == "" || title == "" {
		return domain.Event{}, ErrMissingRequiredFields
	}
	if startAt != nil && endAt != nil && endAt.Before(*startAt) {
		return domain.Event{}, ErrInvalidTimeRange
	}

	resolvedFlagID, resolvedSubflagID, err := uc.resolveFlagAndSubflag(ctx, userID, flagID, subflagID)
	if err != nil {
		return domain.Event{}, err
	}

	event := domain.Event{
		UserID:            userID,
		Title:             title,
		StartAt:           startAt,
		EndAt:             endAt,
		AllDay:            false,
		Location:          normalizeOptionalString(location),
		FlagID:            resolvedFlagID,
		SubflagID:         resolvedSubflagID,
		SourceInboxItemID: normalizeOptionalString(sourceInboxItemID),
	}
	if allDay != nil {
		event.AllDay = *allDay
	}

	item, err := uc.Events.Create(ctx, event)
	if err != nil {
		return domain.Event{}, err
	}

	if uc.NotificationCopy != nil {
		go func(id, title, desc string) {
			ctxBg, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			nTitle, nBody, err := uc.NotificationCopy.GenerateCopy(ctxBg, "Event", title, desc)
			if err == nil && nTitle != "" {
				_ = uc.Events.UpdateNotificationCopy(ctxBg, id, nTitle, nBody)
			}
		}(item.ID, item.Title, "")
	}

	return item, nil
}

func (uc *EventUsecase) Update(ctx context.Context, userID, id string, input EventUpdateInput) (domain.Event, error) {
	if userID == "" || id == "" {
		return domain.Event{}, ErrMissingRequiredFields
	}
	event, err := uc.Events.Get(ctx, userID, id)
	if err != nil {
		return domain.Event{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.Event{}, ErrMissingRequiredFields
		}
		event.Title = trimmed
	}
	if input.StartAt != nil {
		event.StartAt = input.StartAt
	}
	if input.EndAt != nil {
		event.EndAt = input.EndAt
	}
	if event.StartAt != nil && event.EndAt != nil && event.EndAt.Before(*event.StartAt) {
		return domain.Event{}, ErrInvalidTimeRange
	}
	if input.AllDay != nil {
		event.AllDay = *input.AllDay
	}
	if input.Location != nil {
		event.Location = normalizeOptionalString(input.Location)
	}
	if input.FlagID != nil || input.SubflagID != nil {
		nextFlagID := event.FlagID
		nextSubflagID := event.SubflagID
		if input.FlagID != nil {
			nextFlagID = normalizeOptionalString(input.FlagID)
		}
		if input.SubflagID != nil {
			nextSubflagID = normalizeOptionalString(input.SubflagID)
		}
		resolvedFlagID, resolvedSubflagID, err := uc.resolveFlagAndSubflag(ctx, userID, nextFlagID, nextSubflagID)
		if err != nil {
			return domain.Event{}, err
		}
		event.FlagID = resolvedFlagID
		event.SubflagID = resolvedSubflagID
	}

	item, err := uc.Events.Update(ctx, event)
	if err != nil {
		return domain.Event{}, err
	}

	if uc.NotificationCopy != nil {
		go func(id, title, desc string) {
			ctxBg, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			nTitle, nBody, err := uc.NotificationCopy.GenerateCopy(ctxBg, "Event", title, desc)
			if err == nil && nTitle != "" {
				_ = uc.Events.UpdateNotificationCopy(ctxBg, id, nTitle, nBody)
			}
		}(item.ID, item.Title, "")
	}

	return item, nil
}

func (uc *EventUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	if err := uc.Events.Delete(ctx, userID, id); err != nil {
		return err
	}
	// Cancel pending notifications for this event
	if uc.NotificationLog != nil {
		_ = uc.NotificationLog.CancelPendingByReferenceID(ctx, id)
	}
	return nil
}

func (uc *EventUsecase) Get(ctx context.Context, userID, id string) (domain.Event, error) {
	if userID == "" || id == "" {
		return domain.Event{}, ErrMissingRequiredFields
	}
	return uc.Events.Get(ctx, userID, id)
}

func (uc *EventUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Event, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Events.List(ctx, userID, opts)
}

func (uc *EventUsecase) resolveFlagAndSubflag(ctx context.Context, userID string, flagID *string, subflagID *string) (*string, *string, error) {
	resolvedFlagID := normalizeOptionalString(flagID)
	resolvedSubflagID := normalizeOptionalString(subflagID)

	if resolvedFlagID != nil {
		if uc.Flags == nil {
			return nil, nil, ErrDependencyMissing
		}
		if _, err := uc.Flags.Get(ctx, userID, *resolvedFlagID); err != nil {
			if errors.Is(err, postgres.ErrNotFound) {
				return nil, nil, ErrInvalidPayload
			}
			return nil, nil, err
		}
	}

	if resolvedSubflagID != nil {
		if uc.Subflags == nil {
			return nil, nil, ErrDependencyMissing
		}
		subflag, err := uc.Subflags.Get(ctx, userID, *resolvedSubflagID)
		if err != nil {
			if errors.Is(err, postgres.ErrNotFound) {
				return nil, nil, ErrInvalidPayload
			}
			return nil, nil, err
		}
		if resolvedFlagID != nil && subflag.FlagID != *resolvedFlagID {
			return nil, nil, ErrInvalidPayload
		}
		if resolvedFlagID == nil {
			flag := subflag.FlagID
			resolvedFlagID = &flag
		}
	}

	return resolvedFlagID, resolvedSubflagID, nil
}
