package usecase

import (
	"context"
	"errors"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/infra/postgres"
)

type RoutineUsecase struct {
	Routines    repository.RoutineRepository
	Exceptions  repository.RoutineExceptionRepository
	Completions repository.RoutineCompletionRepository
	Flags       repository.FlagRepository
	Subflags    repository.SubflagRepository
}

type RoutineInput struct {
	Title          string
	Description    *string
	RecurrenceType string
	Weekdays       []int
	StartTime      string
	EndTime        *string
	WeekOfMonth    *int
	StartsOn       *string
	EndsOn         *string
	Color          *string
	FlagID         *string
	SubflagID      *string
}

type RoutineUpdateInput struct {
	Title          *string
	Description    *string
	RecurrenceType *string
	Weekdays       *[]int
	StartTime      *string
	EndTime        *string
	WeekOfMonth    *int
	StartsOn       *string
	EndsOn         *string
	Color          *string
	FlagID         *string
	SubflagID      *string
}

func (uc *RoutineUsecase) Create(ctx context.Context, userID string, input RoutineInput) (domain.Routine, error) {
	userID = normalizeString(userID)
	title := normalizeString(input.Title)

	if userID == "" || title == "" {
		return domain.Routine{}, ErrMissingRequiredFields
	}

	if len(input.Weekdays) == 0 {
		return domain.Routine{}, ErrMissingRequiredFields
	}

	if input.StartTime == "" {
		return domain.Routine{}, ErrMissingRequiredFields
	}

	validRecurrenceTypes := map[string]bool{
		"weekly":       true,
		"biweekly":     true,
		"triweekly":    true,
		"monthly_week": true,
	}
	if input.RecurrenceType == "" {
		input.RecurrenceType = "weekly"
	}
	if !validRecurrenceTypes[input.RecurrenceType] {
		return domain.Routine{}, ErrInvalidPayload
	}

	resolvedFlagID, resolvedSubflagID, err := uc.resolveFlagAndSubflag(ctx, userID, input.FlagID, input.SubflagID)
	if err != nil {
		return domain.Routine{}, err
	}

	startsOn := time.Now().Format("2006-01-02")
	if input.StartsOn != nil {
		startsOn = *input.StartsOn
	}

	routine := domain.Routine{
		UserID:         userID,
		Title:          title,
		Description:    input.Description,
		RecurrenceType: input.RecurrenceType,
		Weekdays:       input.Weekdays,
		StartTime:      input.StartTime,
		EndTime:        input.EndTime,
		WeekOfMonth:    input.WeekOfMonth,
		StartsOn:       startsOn,
		EndsOn:         input.EndsOn,
		Color:          input.Color,
		IsActive:       true,
		FlagID:         resolvedFlagID,
		SubflagID:      resolvedSubflagID,
	}

	return uc.Routines.Create(ctx, routine)
}

func (uc *RoutineUsecase) Update(ctx context.Context, userID, id string, input RoutineUpdateInput) (domain.Routine, error) {
	if userID == "" || id == "" {
		return domain.Routine{}, ErrMissingRequiredFields
	}

	routine, err := uc.Routines.Get(ctx, userID, id)
	if err != nil {
		return domain.Routine{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.Routine{}, ErrMissingRequiredFields
		}
		routine.Title = trimmed
	}

	if input.Description != nil {
		routine.Description = input.Description
	}

	if input.RecurrenceType != nil {
		validRecurrenceTypes := map[string]bool{
			"weekly":       true,
			"biweekly":     true,
			"triweekly":    true,
			"monthly_week": true,
		}
		if !validRecurrenceTypes[*input.RecurrenceType] {
			return domain.Routine{}, ErrInvalidPayload
		}
		routine.RecurrenceType = *input.RecurrenceType
	}

	if input.Weekdays != nil {
		if len(*input.Weekdays) == 0 {
			return domain.Routine{}, ErrMissingRequiredFields
		}
		routine.Weekdays = *input.Weekdays
	}

	if input.StartTime != nil {
		routine.StartTime = *input.StartTime
	}

	if input.EndTime != nil {
		routine.EndTime = input.EndTime
	}

	if input.WeekOfMonth != nil {
		routine.WeekOfMonth = input.WeekOfMonth
	}

	if input.StartsOn != nil {
		routine.StartsOn = *input.StartsOn
	}

	if input.EndsOn != nil {
		routine.EndsOn = input.EndsOn
	}

	if input.Color != nil {
		routine.Color = input.Color
	}

	if input.FlagID != nil || input.SubflagID != nil {
		nextFlagID := routine.FlagID
		nextSubflagID := routine.SubflagID
		if input.FlagID != nil {
			nextFlagID = normalizeOptionalString(input.FlagID)
		}
		if input.SubflagID != nil {
			nextSubflagID = normalizeOptionalString(input.SubflagID)
		}
		resolvedFlagID, resolvedSubflagID, err := uc.resolveFlagAndSubflag(ctx, userID, nextFlagID, nextSubflagID)
		if err != nil {
			return domain.Routine{}, err
		}
		routine.FlagID = resolvedFlagID
		routine.SubflagID = resolvedSubflagID
	}

	return uc.Routines.Update(ctx, routine)
}

func (uc *RoutineUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Routines.Delete(ctx, userID, id)
}

func (uc *RoutineUsecase) Get(ctx context.Context, userID, id string) (domain.Routine, error) {
	if userID == "" || id == "" {
		return domain.Routine{}, ErrMissingRequiredFields
	}
	return uc.Routines.Get(ctx, userID, id)
}

func (uc *RoutineUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Routine, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Routines.List(ctx, userID, opts)
}

func (uc *RoutineUsecase) ListByWeekday(ctx context.Context, userID string, weekday int) ([]domain.Routine, error) {
	if userID == "" {
		return nil, ErrMissingRequiredFields
	}
	return uc.Routines.ListByWeekday(ctx, userID, weekday)
}

func (uc *RoutineUsecase) Toggle(ctx context.Context, userID, id string, isActive bool) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Routines.Toggle(ctx, userID, id, isActive)
}

func (uc *RoutineUsecase) Complete(ctx context.Context, userID, routineID, date string) (domain.RoutineCompletion, error) {
	if userID == "" || routineID == "" {
		return domain.RoutineCompletion{}, ErrMissingRequiredFields
	}

	_, err := uc.Routines.Get(ctx, userID, routineID)
	if err != nil {
		return domain.RoutineCompletion{}, err
	}

	if date == "" {
		date = time.Now().Format("2006-01-02")
	}

	completion := domain.RoutineCompletion{
		RoutineID:   routineID,
		CompletedOn: date,
	}

	return uc.Completions.Create(ctx, completion)
}

func (uc *RoutineUsecase) Uncomplete(ctx context.Context, userID, routineID, date string) error {
	if userID == "" || routineID == "" {
		return ErrMissingRequiredFields
	}

	if date == "" {
		date = time.Now().Format("2006-01-02")
	}

	return uc.Completions.Delete(ctx, userID, routineID, date)
}

func (uc *RoutineUsecase) GetCompletions(ctx context.Context, userID, routineID string) ([]domain.RoutineCompletion, error) {
	if userID == "" || routineID == "" {
		return nil, ErrMissingRequiredFields
	}
	return uc.Completions.GetByRoutine(ctx, userID, routineID)
}

func (uc *RoutineUsecase) GetStreak(ctx context.Context, userID, routineID string) (int, int, error) {
	if userID == "" || routineID == "" {
		return 0, 0, ErrMissingRequiredFields
	}
	return uc.Completions.GetStreak(ctx, userID, routineID)
}

func (uc *RoutineUsecase) CreateException(ctx context.Context, userID, routineID, date, action string, newStartTime, newEndTime, reason *string) (domain.RoutineException, error) {
	if userID == "" || routineID == "" || date == "" {
		return domain.RoutineException{}, ErrMissingRequiredFields
	}

	_, err := uc.Routines.Get(ctx, userID, routineID)
	if err != nil {
		return domain.RoutineException{}, err
	}

	if action == "" {
		action = "skip"
	}

	exception := domain.RoutineException{
		RoutineID:     routineID,
		ExceptionDate: date,
		Action:        action,
		NewStartTime:  newStartTime,
		NewEndTime:    newEndTime,
		Reason:        reason,
	}

	return uc.Exceptions.Create(ctx, exception)
}

func (uc *RoutineUsecase) DeleteException(ctx context.Context, userID, routineID, date string) error {
	if userID == "" || routineID == "" || date == "" {
		return ErrMissingRequiredFields
	}
	return uc.Exceptions.Delete(ctx, userID, routineID, date)
}

func (uc *RoutineUsecase) GetExceptions(ctx context.Context, userID, routineID string) ([]domain.RoutineException, error) {
	if userID == "" || routineID == "" {
		return nil, ErrMissingRequiredFields
	}
	return uc.Exceptions.GetByRoutine(ctx, userID, routineID)
}

func (uc *RoutineUsecase) GetTodaySummary(ctx context.Context, userID string) (int, int, error) {
	if userID == "" {
		return 0, 0, ErrMissingRequiredFields
	}

	weekday := int(time.Now().Weekday())
	routines, err := uc.Routines.ListByWeekday(ctx, userID, weekday)
	if err != nil {
		return 0, 0, err
	}

	date := time.Now().Format("2006-01-02")
	completions, err := uc.Completions.GetByDate(ctx, userID, date)
	if err != nil {
		return 0, 0, err
	}

	completedMap := make(map[string]bool)
	for _, c := range completions {
		completedMap[c.RoutineID] = true
	}

	total := 0
	completed := 0
	for _, r := range routines {
		exception, _ := uc.Exceptions.GetForDate(ctx, userID, r.ID, date)
		if exception != nil && exception.Action == "skip" {
			continue
		}
		total++
		if completedMap[r.ID] {
			completed++
		}
	}

	return total, completed, nil
}

func (uc *RoutineUsecase) resolveFlagAndSubflag(ctx context.Context, userID string, flagID *string, subflagID *string) (*string, *string, error) {
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
