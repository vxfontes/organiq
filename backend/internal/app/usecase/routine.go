package usecase

import (
	"context"
	"errors"
	"fmt"
	"strings"
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
	EndTime        string
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

	if input.StartTime == "" || input.EndTime == "" {
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

	resolvedFlagID, resolvedSubflagID, err := uc.ResolveFlagAndSubflag(ctx, userID, input.FlagID, input.SubflagID)
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

	if err := uc.Validate(ctx, routine); err != nil {
		return domain.Routine{}, err
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
		if *input.StartTime == "" {
			return domain.Routine{}, ErrMissingRequiredFields
		}
		routine.StartTime = *input.StartTime
	}

	if input.EndTime != nil {
		if *input.EndTime == "" {
			return domain.Routine{}, ErrMissingRequiredFields
		}
		routine.EndTime = *input.EndTime
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
		resolvedFlagID, resolvedSubflagID, err := uc.ResolveFlagAndSubflag(ctx, userID, nextFlagID, nextSubflagID)
		if err != nil {
			return domain.Routine{}, err
		}
		routine.FlagID = resolvedFlagID
		routine.SubflagID = resolvedSubflagID
	}

	if err := uc.checkOverlap(ctx, userID, id, routine.Weekdays, routine.StartTime, routine.EndTime); err != nil {
		return domain.Routine{}, err
	}

	return uc.Routines.Update(ctx, routine)
}

func (uc *RoutineUsecase) Validate(ctx context.Context, routine domain.Routine) error {
	if routine.UserID == "" || routine.Title == "" {
		return ErrMissingRequiredFields
	}

	if len(routine.Weekdays) == 0 {
		return ErrMissingRequiredFields
	}

	if routine.StartTime == "" || routine.EndTime == "" {
		return ErrMissingRequiredFields
	}

	validRecurrenceTypes := map[string]bool{
		"weekly":       true,
		"biweekly":     true,
		"triweekly":    true,
		"monthly_week": true,
	}
	recurrenceType := routine.RecurrenceType
	if recurrenceType == "" {
		recurrenceType = "weekly"
	}
	if !validRecurrenceTypes[recurrenceType] {
		return ErrInvalidPayload
	}

	if recurrenceType == "monthly_week" && routine.WeekOfMonth == nil {
		return ErrInvalidPayload
	}

	return uc.checkOverlap(ctx, routine.UserID, routine.ID, routine.Weekdays, routine.StartTime, routine.EndTime)
}

func (uc *RoutineUsecase) checkOverlap(ctx context.Context, userID, excludeID string, weekdays []int, startTime string, endTime string) error {
	if timeToMinutes(endTime) <= timeToMinutes(startTime) {
		return ErrInvalidTimeRange
	}

	var excludeIDPtr *string
	if excludeID != "" {
		excludeIDPtr = &excludeID
	}

	overlap, err := uc.Routines.CheckOverlap(ctx, userID, weekdays, startTime, endTime, excludeIDPtr)
	if err != nil {
		return err
	}
	if overlap {
		return ErrRoutineOverlap
	}

	return nil
}

func timeToMinutes(t string) int {
	parts := strings.Split(t, ":")
	if len(parts) < 2 {
		return 0
	}
	var h, m int
	fmt.Sscanf(parts[0], "%d", &h)
	fmt.Sscanf(parts[1], "%d", &m)
	return h*60 + m
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

func (uc *RoutineUsecase) ListByWeekday(ctx context.Context, userID string, weekday int, date string) ([]domain.Routine, error) {
	if userID == "" {
		return nil, ErrMissingRequiredFields
	}

	nowStr := time.Now().Format("2006-01-02")
	isToday := date == "" || date == nowStr

	if isToday {
		routines, err := uc.Routines.ListDailyStatus(ctx, userID, weekday)
		if err != nil {
			return nil, err
		}

		targetDate := time.Now()
		filtered := make([]domain.Routine, 0, len(routines))
		for _, r := range routines {
			if shouldShowRoutineForDate(r.Routine, targetDate) {
				r.Routine.IsCompletedToday = r.IsCompleted
				filtered = append(filtered, r.Routine)
			}
		}
		return filtered, nil
	}

	// Fallback para datas que não sejam hoje
	routines, err := uc.Routines.ListByWeekday(ctx, userID, weekday)
	if err != nil {
		return nil, err
	}

	completions := make(map[string]bool)
	if date != "" {
		comps, err := uc.Completions.GetByDate(ctx, userID, date)
		if err == nil {
			for _, c := range comps {
				completions[c.RoutineID] = true
			}
		}
	}

	targetDate := time.Now()
	if date != "" {
		if t, err := time.Parse("2006-01-02", date); err == nil {
			targetDate = t
		}
	}

	filtered := make([]domain.Routine, 0, len(routines))
	for _, r := range routines {
		if shouldShowRoutineForDate(r, targetDate) {
			r.IsCompletedToday = completions[r.ID]
			filtered = append(filtered, r)
		}
	}
	return filtered, nil
}

func shouldShowRoutineForDate(r domain.Routine, targetDate time.Time) bool {
	if r.RecurrenceType == "weekly" || r.RecurrenceType == "" {
		return true
	}

	startsOnStr := r.StartsOn
	if len(startsOnStr) > 10 {
		startsOnStr = startsOnStr[:10]
	}
	startsOn, err := time.Parse("2006-01-02", startsOnStr)
	if err != nil {
		return true
	}

	startsOnMonday := mondayOf(startsOn)
	targetMonday := mondayOf(targetDate)

	if targetMonday.Before(startsOnMonday) {
		return false
	}

	weeksDiff := int(targetMonday.Sub(startsOnMonday).Hours()) / (24 * 7)

	switch r.RecurrenceType {
	case "biweekly":
		return weeksDiff%2 == 0
	case "triweekly":
		return weeksDiff%3 == 0
	case "monthly_week":
		if r.WeekOfMonth == nil {
			return true
		}
		// Week of month: 1st, 2nd, 3rd, 4th, 5th
		// Logic: (day-1)/7 + 1
		targetWeek := (targetDate.Day()-1)/7 + 1
		return targetWeek == *r.WeekOfMonth
	default:
		return true
	}
}

func mondayOf(t time.Time) time.Time {
	weekday := int(t.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	monday := t.AddDate(0, 0, -(weekday - 1))
	return time.Date(monday.Year(), monday.Month(), monday.Day(), 0, 0, 0, 0, time.UTC)
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

	return uc.Completions.Create(ctx, userID, completion)
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

	return uc.Exceptions.Create(ctx, userID, exception)
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

	now := time.Now()
	weekday := int(now.Weekday())
	routines, err := uc.Routines.ListDailyStatus(ctx, userID, weekday)
	if err != nil {
		return 0, 0, err
	}

	total := 0
	completed := 0
	for _, r := range routines {
		if !shouldShowRoutineForDate(r.Routine, now) {
			continue
		}
		if r.ExceptionAction != nil && *r.ExceptionAction == "skip" {
			continue
		}
		total++
		if r.IsCompleted {
			completed++
		}
	}

	return total, completed, nil
}

func (uc *RoutineUsecase) ResolveFlagAndSubflag(ctx context.Context, userID string, flagID *string, subflagID *string) (*string, *string, error) {
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
