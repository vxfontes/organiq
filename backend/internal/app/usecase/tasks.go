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

type TaskUsecase struct {
	Tasks            repository.TaskRepository
	Flags            repository.FlagRepository
	Subflags         repository.SubflagRepository
	NotificationLog  repository.NotificationLogRepository
	NotificationCopy *service.NotificationCopyService
}

type TaskUpdateInput struct {
	Title       *string
	Description *string
	Status      *string
	DueAt       *time.Time
	FlagID      *string
	SubflagID   *string
}

func (uc *TaskUsecase) Create(ctx context.Context, userID, title string, description *string, status *string, dueAt *time.Time, flagID *string, subflagID *string, sourceInboxItemID *string) (domain.Task, error) {
	title = normalizeString(title)
	if userID == "" || title == "" {
		return domain.Task{}, ErrMissingRequiredFields
	}

	resolvedFlagID, resolvedSubflagID, err := uc.resolveFlagAndSubflag(ctx, userID, flagID, subflagID)
	if err != nil {
		return domain.Task{}, err
	}

	task := domain.Task{
		UserID:            userID,
		Title:             title,
		Description:       description,
		FlagID:            resolvedFlagID,
		SubflagID:         resolvedSubflagID,
		SourceInboxItemID: normalizeOptionalString(sourceInboxItemID),
	}

	if status != nil {
		parsed, ok := parseTaskStatus(*status)
		if !ok {
			return domain.Task{}, ErrInvalidStatus
		}
		task.Status = parsed
	}
	task.DueAt = dueAt

	item, err := uc.Tasks.Create(ctx, task)
	if err != nil {
		return domain.Task{}, err
	}

	if uc.NotificationCopy != nil {
		desc := ""
		if description != nil {
			desc = *description
		}
		go func(id, title, desc string) {
			ctxBg, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			nTitle, nBody, err := uc.NotificationCopy.GenerateCopy(ctxBg, "Task", title, desc)
			if err == nil && nTitle != "" {
				_ = uc.Tasks.UpdateNotificationCopy(ctxBg, id, nTitle, nBody)
			}
		}(item.ID, item.Title, desc)
	}

	return item, nil
}

func (uc *TaskUsecase) Update(ctx context.Context, userID, id string, input TaskUpdateInput) (domain.Task, error) {
	if userID == "" || id == "" {
		return domain.Task{}, ErrMissingRequiredFields
	}
	task, err := uc.Tasks.Get(ctx, userID, id)
	if err != nil {
		return domain.Task{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.Task{}, ErrMissingRequiredFields
		}
		task.Title = trimmed
	}
	if input.Description != nil {
		task.Description = input.Description
	}
	if input.Status != nil {
		parsed, ok := parseTaskStatus(*input.Status)
		if !ok {
			return domain.Task{}, ErrInvalidStatus
		}
		task.Status = parsed
	}
	if input.DueAt != nil {
		task.DueAt = input.DueAt
	}
	if input.FlagID != nil || input.SubflagID != nil {
		nextFlagID := task.FlagID
		nextSubflagID := task.SubflagID
		if input.FlagID != nil {
			nextFlagID = normalizeOptionalString(input.FlagID)
		}
		if input.SubflagID != nil {
			nextSubflagID = normalizeOptionalString(input.SubflagID)
		}
		resolvedFlagID, resolvedSubflagID, err := uc.resolveFlagAndSubflag(ctx, userID, nextFlagID, nextSubflagID)
		if err != nil {
			return domain.Task{}, err
		}
		task.FlagID = resolvedFlagID
		task.SubflagID = resolvedSubflagID
	}

	item, err := uc.Tasks.Update(ctx, task)
	if err != nil {
		return domain.Task{}, err
	}

	if uc.NotificationCopy != nil {
		desc := ""
		if item.Description != nil {
			desc = *item.Description
		}
		go func(id, title, desc string) {
			ctxBg, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			nTitle, nBody, err := uc.NotificationCopy.GenerateCopy(ctxBg, "Task", title, desc)
			if err == nil && nTitle != "" {
				_ = uc.Tasks.UpdateNotificationCopy(ctxBg, id, nTitle, nBody)
			}
		}(item.ID, item.Title, desc)
	}

	return item, nil
}

func (uc *TaskUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	if err := uc.Tasks.Delete(ctx, userID, id); err != nil {
		return err
	}
	// Cancel pending notifications for this task
	if uc.NotificationLog != nil {
		_ = uc.NotificationLog.CancelPendingByReferenceID(ctx, id)
	}
	return nil
}

func (uc *TaskUsecase) Get(ctx context.Context, userID, id string) (domain.Task, error) {
	if userID == "" || id == "" {
		return domain.Task{}, ErrMissingRequiredFields
	}
	return uc.Tasks.Get(ctx, userID, id)
}

func (uc *TaskUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Task, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Tasks.List(ctx, userID, opts)
}

func (uc *TaskUsecase) resolveFlagAndSubflag(ctx context.Context, userID string, flagID *string, subflagID *string) (*string, *string, error) {
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
