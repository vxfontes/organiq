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
	Users       repository.UserRepository
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

	now := uc.nowInUserTimezone(ctx, userID)
	nowStr := now.Format("2006-01-02")
	isToday := date == "" || date == nowStr

	if isToday {
		weekday = int(now.Weekday())
		routines, err := uc.Routines.ListDailyStatus(ctx, userID, weekday, nowStr)
		if err != nil {
			return nil, err
		}

		targetDate := now
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

func (uc *RoutineUsecase) GetStreak(ctx context.Context, userID, routineID string) (int, int, string, []domain.RoutineActivityDay, error) {
	if userID == "" || routineID == "" {
		return 0, 0, "", nil, ErrMissingRequiredFields
	}

	routine, err := uc.Routines.Get(ctx, userID, routineID)
	if err != nil {
		return 0, 0, "", nil, err
	}

	completions, err := uc.Completions.GetByRoutine(ctx, userID, routineID)
	if err != nil {
		completions = []domain.RoutineCompletion{}
	}

	exceptions, err := uc.Exceptions.GetByRoutine(ctx, userID, routineID)
	if err != nil {
		exceptions = []domain.RoutineException{}
	}

	completionMap := make(map[string]bool)
	for _, c := range completions {
		completionMap[c.CompletedOn] = true
	}

	exceptionMap := make(map[string]string)
	for _, e := range exceptions {
		exceptionMap[e.ExceptionDate] = e.Action
	}

	now := uc.nowInUserTimezone(ctx, userID)
	todayStr := now.Format("2006-01-02")
	
	currentStreak := 0
	checkDate := now
	if !completionMap[todayStr] && exceptionMap[todayStr] != "skip" {
		checkDate = now.AddDate(0, 0, -1)
	}

	for i := 0; i < 730; i++ {
		dateStr := checkDate.Format("2006-01-02")
		if dateStr < routine.StartsOn {
			break
		}
		if uc.isScheduledOn(routine, checkDate) {
			if completionMap[dateStr] {
				currentStreak++
			//} else if exceptionMap[dateStr] == "skip" { -> não pula, quebra o streak
			} else {
				break
			}
		}
		checkDate = checkDate.AddDate(0, 0, -1)
	}

	startsOn, err := time.Parse("2006-01-02", routine.StartsOn)
	if err != nil {
		startsOn = now.AddDate(0, 0, -6) // Fallback de 7 dias
	}

	sDay := time.Date(startsOn.Year(), startsOn.Month(), startsOn.Day(), 0, 0, 0, 0, now.Location())
	nDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	
	daysSinceStart := int(nDay.Sub(sDay).Hours() / 24)
	if daysSinceStart < 6 {
		daysSinceStart = 6
	}
	if daysSinceStart > 365 {
		daysSinceStart = 365 // Safety limit of 1 year
	}

	activity := make([]domain.RoutineActivityDay, 0, daysSinceStart+1)
	weekdayNames := []string{"D", "S", "T", "Q", "Q", "S", "S"}

	for i := daysSinceStart; i >= 0; i-- {
		d := now.AddDate(0, 0, -i)
		dStr := d.Format("2006-01-02")
		activity = append(activity, domain.RoutineActivityDay{
			Date:         dStr,
			IsCompleted:  completionMap[dStr],
			IsScheduled:  uc.isScheduledOn(routine, d),
			IsToday:      dStr == todayStr,
			IsSkipped:    exceptionMap[dStr] == "skip",
			WeekdayLabel: weekdayNames[int(d.Weekday())],
		})
	}

	totalCompletions := len(completions)
	unit := "semana"
	if routine.RecurrenceType == "weekly" && len(routine.Weekdays) >= 3 {
		unit = "dia"
	}
	
	streakText := ""
	if currentStreak == 1 {
		if unit == "dia" {
			streakText = "1 dia consecutivo"
		} else {
			streakText = "1 semana consecutiva"
		}
	} else if currentStreak > 1 {
		if unit == "dia" {
			streakText = fmt.Sprintf("%d dias consecutivos", currentStreak)
		} else {
			streakText = fmt.Sprintf("%d semanas consecutivas", currentStreak)
		}
	} else {
		streakText = "Inicie sua sequência!"
	}

	return currentStreak, totalCompletions, streakText, activity, nil
}

func (uc *RoutineUsecase) isScheduledOn(r domain.Routine, date time.Time) bool {
	if !r.IsActive {
		return false
	}

	weekday := int(date.Weekday())
	found := false
	for _, wd := range r.Weekdays {
		if wd == weekday {
			found = true
			break
		}
	}
	if !found {
		return false
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
	targetMonday := mondayOf(date)

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
		targetWeek := (date.Day()-1)/7 + 1
		return targetWeek == *r.WeekOfMonth
	default:
		return true
	}
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

func (uc *RoutineUsecase) nowInUserTimezone(ctx context.Context, userID string) time.Time {
	now := time.Now()

	fallbackLoc, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		fallbackLoc = now.Location()
	}

	if uc.Users == nil || userID == "" {
		return now.In(fallbackLoc)
	}
	user, err := uc.Users.Get(ctx, userID)
	if err != nil {
		return now.In(fallbackLoc)
	}
	if user.Timezone == "" {
		return now.In(fallbackLoc)
	}
	loc, err := time.LoadLocation(user.Timezone)
	if err != nil {
		return now.In(fallbackLoc)
	}
	return now.In(loc)
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

	now := uc.nowInUserTimezone(ctx, userID)
	weekday := int(now.Weekday())
	date := now.Format("2006-01-02")
	routines, err := uc.Routines.ListDailyStatus(ctx, userID, weekday, date)
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
