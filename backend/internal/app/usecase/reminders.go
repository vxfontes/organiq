package usecase

import (
	"context"
	"errors"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/infra/postgres"
)

type ReminderUsecase struct {
	Reminders repository.ReminderRepository
	Flags     repository.FlagRepository
	Subflags  repository.SubflagRepository
}

type ReminderUpdateInput struct {
	Title     *string
	Status    *string
	RemindAt  *time.Time
	FlagID    *string
	SubflagID *string
}

func (uc *ReminderUsecase) Create(ctx context.Context, userID, title string, status *string, remindAt *time.Time, flagID *string, subflagID *string, sourceInboxItemID *string) (domain.Reminder, error) {
	title = normalizeString(title)
	if userID == "" || title == "" {
		return domain.Reminder{}, ErrMissingRequiredFields
	}

	resolvedFlagID, resolvedSubflagID, err := uc.resolveFlagAndSubflag(ctx, userID, flagID, subflagID)
	if err != nil {
		return domain.Reminder{}, err
	}

	reminder := domain.Reminder{
		UserID:            userID,
		Title:             title,
		RemindAt:          remindAt,
		FlagID:            resolvedFlagID,
		SubflagID:         resolvedSubflagID,
		SourceInboxItemID: normalizeOptionalString(sourceInboxItemID),
	}

	if status != nil {
		parsed, ok := parseReminderStatus(*status)
		if !ok {
			return domain.Reminder{}, ErrInvalidStatus
		}
		reminder.Status = parsed
	}

	return uc.Reminders.Create(ctx, reminder)
}

func (uc *ReminderUsecase) Update(ctx context.Context, userID, id string, input ReminderUpdateInput) (domain.Reminder, error) {
	if userID == "" || id == "" {
		return domain.Reminder{}, ErrMissingRequiredFields
	}
	reminder, err := uc.Reminders.Get(ctx, userID, id)
	if err != nil {
		return domain.Reminder{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.Reminder{}, ErrMissingRequiredFields
		}
		reminder.Title = trimmed
	}
	if input.Status != nil {
		parsed, ok := parseReminderStatus(*input.Status)
		if !ok {
			return domain.Reminder{}, ErrInvalidStatus
		}
		reminder.Status = parsed
	}
	if input.RemindAt != nil {
		reminder.RemindAt = input.RemindAt
	}
	if input.FlagID != nil || input.SubflagID != nil {
		nextFlagID := reminder.FlagID
		nextSubflagID := reminder.SubflagID
		if input.FlagID != nil {
			nextFlagID = normalizeOptionalString(input.FlagID)
		}
		if input.SubflagID != nil {
			nextSubflagID = normalizeOptionalString(input.SubflagID)
		}
		resolvedFlagID, resolvedSubflagID, err := uc.resolveFlagAndSubflag(ctx, userID, nextFlagID, nextSubflagID)
		if err != nil {
			return domain.Reminder{}, err
		}
		reminder.FlagID = resolvedFlagID
		reminder.SubflagID = resolvedSubflagID
	}

	return uc.Reminders.Update(ctx, reminder)
}

func (uc *ReminderUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Reminders.Delete(ctx, userID, id)
}

func (uc *ReminderUsecase) Get(ctx context.Context, userID, id string) (domain.Reminder, error) {
	if userID == "" || id == "" {
		return domain.Reminder{}, ErrMissingRequiredFields
	}
	return uc.Reminders.Get(ctx, userID, id)
}

func (uc *ReminderUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Reminder, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Reminders.List(ctx, userID, opts)
}

func (uc *ReminderUsecase) resolveFlagAndSubflag(ctx context.Context, userID string, flagID *string, subflagID *string) (*string, *string, error) {
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
