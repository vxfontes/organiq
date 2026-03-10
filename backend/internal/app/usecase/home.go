package usecase

import (
	"context"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type HomeUsecase struct {
	Home     repository.HomeRepository
	Agenda   repository.AgendaRepository
	Routines *RoutineUsecase
	Users    repository.UserRepository
}

type HomeDashboard struct {
	DayProgress         HomeDayProgress
	Insight             *HomeInsight
	Timeline            []HomeTimelineItem
	ShoppingPreview     []repository.HomeShoppingPreview
	WeekDensity         map[string]int
	FocusTasks          []domain.Task
	EventsTodayCount    int
	RemindersTodayCount int
}

type HomeDayProgress struct {
	RoutinesDone    int
	RoutinesTotal   int
	TasksDone       int
	TasksTotal      int
	ProgressPercent float64
}

type HomeInsight struct {
	Title   string
	Summary string
	Footer  string
	IsFocus bool
}

type HomeTimelineItem struct {
	ID               string
	ItemType         string
	Title            string
	Subtitle         *string
	ScheduledTime    time.Time
	EndScheduledTime *time.Time
	IsCompleted      bool
	IsOverdue        bool
}

type timeRange struct {
	start time.Time
	end   time.Time
}

func (uc *HomeUsecase) GetDashboard(ctx context.Context, userID string) (HomeDashboard, error) {
	if strings.TrimSpace(userID) == "" {
		return HomeDashboard{}, ErrMissingRequiredFields
	}
	if uc.Home == nil || uc.Agenda == nil || uc.Routines == nil {
		return HomeDashboard{}, ErrDependencyMissing
	}

	now, loc := uc.nowInUserTimezone(ctx, userID)
	todayStartLocal := startOfDay(now)
	todayEndLocal := todayStartLocal.Add(24 * time.Hour)
	todayStartUTC := todayStartLocal.UTC()
	todayEndUTC := todayEndLocal.UTC()

	agendaToday, err := uc.Agenda.List(ctx, userID, repository.ListOptions{
		Limit:   200,
		StartAt: &todayStartUTC,
		EndAt:   &todayEndUTC,
	})
	if err != nil {
		return HomeDashboard{}, err
	}

	dateStr := now.Format("2006-01-02")
	weekday := int(now.Weekday())
	routinesToday, err := uc.Routines.ListByWeekday(ctx, userID, weekday, dateStr)
	if err != nil {
		return HomeDashboard{}, err
	}

	routinesTotal, routinesDone, err := uc.Routines.GetTodaySummary(ctx, userID)
	if err != nil {
		return HomeDashboard{}, err
	}

	focusTaskRows, err := uc.Home.ListFocusTasks(ctx, userID, 200)
	if err != nil {
		return HomeDashboard{}, err
	}
	focusTasksAll := homeFocusRowsToDomainTasks(focusTaskRows)
	focusTasks := selectFocusTasks(focusTasksAll, now)

	shoppingPreview, err := uc.Home.ListShoppingPreview(ctx, userID, 3)
	if err != nil {
		return HomeDashboard{}, err
	}

	weekDensity, err := uc.buildWeekDensity(ctx, userID, now, loc)
	if err != nil {
		return HomeDashboard{}, err
	}

	templates, err := uc.Home.ListInsightTemplates(ctx)
	if err != nil {
		return HomeDashboard{}, err
	}

	timeline, eventsTodayCount, remindersTodayCount, tasksTodayTotal, tasksTodayDone :=
		buildAgendaTimeline(agendaToday, now, loc)
	timeline = append(timeline, buildRoutineTimeline(routinesToday, now, loc)...)
	sortTimeline(timeline)

	slots := make([]timeRange, 0, len(timeline))
	for _, item := range timeline {
		rangeEnd := item.EndScheduledTime
		if rangeEnd == nil || !rangeEnd.After(item.ScheduledTime) {
			end := item.ScheduledTime.Add(45 * time.Minute)
			rangeEnd = &end
		}
		slots = append(slots, timeRange{start: item.ScheduledTime, end: *rangeEnd})
	}

	commitmentsCount := eventsTodayCount + remindersTodayCount + tasksTodayTotal + routinesTotal
	untimedCount := commitmentsCount - len(slots)
	if untimedCount < 0 {
		untimedCount = 0
	}

	insight := buildHomeInsight(templates, slots, commitmentsCount, untimedCount, now)

	dayProgress := HomeDayProgress{
		RoutinesDone:    routinesDone,
		RoutinesTotal:   routinesTotal,
		TasksDone:       tasksTodayDone,
		TasksTotal:      tasksTodayTotal,
		ProgressPercent: 0,
	}
	if total := routinesTotal + tasksTodayTotal; total > 0 {
		dayProgress.ProgressPercent = clamp01(float64(routinesDone+tasksTodayDone) / float64(total))
	}

	return HomeDashboard{
		DayProgress:         dayProgress,
		Insight:             insight,
		Timeline:            timeline,
		ShoppingPreview:     shoppingPreview,
		WeekDensity:         weekDensity,
		FocusTasks:          focusTasks,
		EventsTodayCount:    eventsTodayCount,
		RemindersTodayCount: remindersTodayCount,
	}, nil
}

func homeFocusRowsToDomainTasks(rows []repository.HomeFocusTask) []domain.Task {
	items := make([]domain.Task, 0, len(rows))
	for _, row := range rows {
		items = append(items, domain.Task{
			ID:          row.ID,
			Title:       row.Title,
			Description: row.Description,
			Status:      domain.TaskStatus(row.Status),
			DueAt:       row.DueAt,
			CreatedAt:   row.CreatedAt,
			UpdatedAt:   row.UpdatedAt,
		})
	}
	return items
}

func selectFocusTasks(tasks []domain.Task, now time.Time) []domain.Task {
	dayStart := startOfDay(now)
	dayEnd := dayStart.Add(24 * time.Hour)

	filtered := make([]domain.Task, 0, len(tasks))
	for _, task := range tasks {
		dueLocal := toLocalPtr(task.DueAt, now.Location())
		if dueLocal == nil || dueLocal.Before(dayEnd) {
			filtered = append(filtered, task)
		}
	}

	sort.Slice(filtered, func(i, j int) bool {
		a := filtered[i]
		b := filtered[j]
		aDue := toLocalPtr(a.DueAt, now.Location())
		bDue := toLocalPtr(b.DueAt, now.Location())

		aPriority := focusPriority(aDue, dayStart, dayEnd)
		bPriority := focusPriority(bDue, dayStart, dayEnd)
		if aPriority != bPriority {
			return aPriority < bPriority
		}

		if aPriority == 0 || aPriority == 1 {
			if aDue != nil && bDue != nil {
				if !aDue.Equal(*bDue) {
					return aDue.Before(*bDue)
				}
			}
		}

		if aPriority == 2 {
			aCreated := a.CreatedAt
			bCreated := b.CreatedAt
			if !aCreated.Equal(bCreated) {
				return bCreated.Before(aCreated)
			}
		}

		return strings.ToLower(a.Title) < strings.ToLower(b.Title)
	})

	if len(filtered) > 5 {
		return filtered[:5]
	}
	return filtered
}

func focusPriority(dueAt *time.Time, dayStart, dayEnd time.Time) int {
	if dueAt == nil {
		return 2
	}
	if dueAt.Before(dayStart) {
		return 0
	}
	if dueAt.Before(dayEnd) {
		return 1
	}
	return 3
}

func buildAgendaTimeline(items []repository.AgendaItem, now time.Time, loc *time.Location) ([]HomeTimelineItem, int, int, int, int) {
	timeline := make([]HomeTimelineItem, 0)
	eventsTodayCount := 0
	remindersTodayCount := 0
	tasksTodayTotal := 0
	tasksTodayDone := 0

	for _, item := range items {
		scheduledLocal := item.ScheduledAt.In(loc)

		switch item.ItemType {
		case "event":
			eventsTodayCount++
		case "reminder":
			if !strings.EqualFold(item.Status, "DONE") {
				remindersTodayCount++
			}
		case "task":
			tasksTodayTotal++
			if strings.EqualFold(item.Status, "DONE") {
				tasksTodayDone++
			}
		}

		if !hasDefinedTime(scheduledLocal) {
			continue
		}

		var subtitle *string
		switch item.ItemType {
		case "task":
			subtitle = trimPtr(item.Description)
		case "event":
			subtitle = trimPtr(item.Location)
		}

		var isCompleted bool
		switch item.ItemType {
		case "task", "reminder":
			isCompleted = strings.EqualFold(item.Status, "DONE")
		default:
			isCompleted = false
		}

		var endScheduled *time.Time
		if item.ItemType == "event" && item.EndAt != nil {
			endLocal := item.EndAt.In(loc)
			if endLocal.After(scheduledLocal) {
				endScheduled = &endLocal
			}
		}

		isOverdue := scheduledLocal.Before(now)
		if item.ItemType == "task" || item.ItemType == "reminder" {
			isOverdue = isOverdue && !isCompleted
		}

		timeline = append(timeline, HomeTimelineItem{
			ID:               item.ID,
			ItemType:         item.ItemType,
			Title:            item.Title,
			Subtitle:         subtitle,
			ScheduledTime:    scheduledLocal,
			EndScheduledTime: endScheduled,
			IsCompleted:      isCompleted,
			IsOverdue:        isOverdue,
		})
	}

	return timeline, eventsTodayCount, remindersTodayCount, tasksTodayTotal, tasksTodayDone
}

func buildRoutineTimeline(routines []domain.Routine, now time.Time, loc *time.Location) []HomeTimelineItem {
	baseDay := startOfDay(now)
	items := make([]HomeTimelineItem, 0, len(routines))

	for _, routine := range routines {
		startLocal, ok := parseRoutineTimeForDay(routine.StartTime, baseDay)
		if !ok {
			continue
		}

		var endLocalPtr *time.Time
		if endLocal, ok := parseRoutineTimeForDay(routine.EndTime, baseDay); ok && endLocal.After(startLocal) {
			end := endLocal
			endLocalPtr = &end
		}

		startWithLoc := time.Date(
			startLocal.Year(),
			startLocal.Month(),
			startLocal.Day(),
			startLocal.Hour(),
			startLocal.Minute(),
			startLocal.Second(),
			startLocal.Nanosecond(),
			loc,
		)

		if endLocalPtr != nil {
			end := time.Date(
				endLocalPtr.Year(),
				endLocalPtr.Month(),
				endLocalPtr.Day(),
				endLocalPtr.Hour(),
				endLocalPtr.Minute(),
				endLocalPtr.Second(),
				endLocalPtr.Nanosecond(),
				loc,
			)
			endLocalPtr = &end
		}

		subtitleText := normalizeText(weekdaysLabel(routine.Weekdays))
		var subtitle *string
		if subtitleText != "" {
			subtitle = &subtitleText
		}

		items = append(items, HomeTimelineItem{
			ID:               routine.ID,
			ItemType:         "routine",
			Title:            routine.Title,
			Subtitle:         subtitle,
			ScheduledTime:    startWithLoc,
			EndScheduledTime: endLocalPtr,
			IsCompleted:      routine.IsCompletedToday,
			IsOverdue:        startWithLoc.Before(now) && !routine.IsCompletedToday,
		})
	}

	return items
}

func sortTimeline(items []HomeTimelineItem) {
	sort.Slice(items, func(i, j int) bool {
		if !items[i].ScheduledTime.Equal(items[j].ScheduledTime) {
			return items[i].ScheduledTime.Before(items[j].ScheduledTime)
		}
		return strings.ToLower(items[i].Title) < strings.ToLower(items[j].Title)
	})
}

func buildHomeInsight(
	templates []repository.HomeInsightTemplate,
	slots []timeRange,
	commitmentsCount int,
	untimedCount int,
	now time.Time,
) *HomeInsight {
	base := now
	dayStart := time.Date(base.Year(), base.Month(), base.Day(), 8, 0, 0, 0, base.Location())
	dayEnd := time.Date(base.Year(), base.Month(), base.Day(), 22, 0, 0, 0, base.Location())

	if latest := latestSlotEnd(slots); latest != nil && latest.After(dayEnd) {
		dayEnd = *latest
	}

	from := dayStart
	if base.After(dayStart) {
		from = base
	}

	if !from.Before(dayEnd) {
		return renderInsightTemplate(templates, "END_OF_DAY", 0, map[string]string{}, defaultInsight("END_OF_DAY"))
	}

	if untimedCount > 0 && len(slots) == 0 {
		vars := map[string]string{
			"untimed_count": strconv.Itoa(untimedCount),
		}
		return renderInsightTemplate(templates, "PENDING_TIMES", 0, vars, defaultInsight("PENDING_TIMES"))
	}

	busyRanges := buildBusyRanges(slots, from, dayEnd)
	bestGap := findLargestGap(busyRanges, from, dayEnd)
	bestGapMinutes := int(bestGap.end.Sub(bestGap.start).Minutes())

	hasAgenda := commitmentsCount > 0
	hasTimedSlots := len(slots) > 0
	untimedDominant := untimedCount >= (len(slots) + 1)

	vars := map[string]string{
		"start":          formatHM(bestGap.start),
		"end":            formatHM(bestGap.end),
		"duration":       strconv.Itoa(bestGapMinutes),
		"untimed_count":  strconv.Itoa(untimedCount),
		"footer_dynamic": "Aproveitar tempo com menos interrupcoes.",
	}

	if untimedCount > 0 {
		vars["footer_dynamic"] = fmt.Sprintf("Aproveite e veja %d tarefa(s) sem horario.", untimedCount)
	}

	if untimedCount > 0 && (!hasTimedSlots || untimedDominant) {
		return renderInsightTemplate(templates, "MISSING_TIMES", bestGapMinutes, vars, defaultInsight("MISSING_TIMES"))
	}

	if !hasAgenda {
		return renderInsightTemplate(templates, "FREE_TIME", bestGapMinutes, vars, defaultInsight("FREE_TIME"))
	}

	if bestGapMinutes >= 120 {
		return renderInsightTemplate(templates, "MELHOR_MOMENTO", bestGapMinutes, vars, defaultInsight("MELHOR_MOMENTO"))
	}

	if bestGapMinutes >= 45 {
		return renderInsightTemplate(templates, "GOOD_FREE_TIME", bestGapMinutes, vars, defaultInsight("GOOD_FREE_TIME"))
	}

	return renderInsightTemplate(templates, "BUSY", bestGapMinutes, vars, defaultInsight("BUSY"))
}

func renderInsightTemplate(
	templates []repository.HomeInsightTemplate,
	category string,
	gapMinutes int,
	vars map[string]string,
	fallback HomeInsight,
) *HomeInsight {
	tpl := selectTemplate(templates, category, gapMinutes)
	if tpl == nil {
		fallback.Title = applyTemplateVars(fallback.Title, vars)
		fallback.Summary = applyTemplateVars(fallback.Summary, vars)
		fallback.Footer = applyTemplateVars(fallback.Footer, vars)
		return &fallback
	}

	return &HomeInsight{
		Title:   applyTemplateVars(tpl.TitleTemplate, vars),
		Summary: applyTemplateVars(tpl.SummaryTemplate, vars),
		Footer:  applyTemplateVars(tpl.FooterTemplate, vars),
		IsFocus: tpl.IsFocus,
	}
}

func selectTemplate(templates []repository.HomeInsightTemplate, category string, gapMinutes int) *repository.HomeInsightTemplate {
	var selected *repository.HomeInsightTemplate
	for i := range templates {
		tpl := &templates[i]
		if !strings.EqualFold(tpl.Category, category) {
			continue
		}
		if tpl.MinGapMinutes != nil && gapMinutes < *tpl.MinGapMinutes {
			continue
		}

		if selected == nil {
			selected = tpl
			continue
		}

		if tpl.Priority > selected.Priority {
			selected = tpl
			continue
		}

		selectedGap := 0
		if selected.MinGapMinutes != nil {
			selectedGap = *selected.MinGapMinutes
		}
		tplGap := 0
		if tpl.MinGapMinutes != nil {
			tplGap = *tpl.MinGapMinutes
		}
		if tpl.Priority == selected.Priority && tplGap > selectedGap {
			selected = tpl
		}
	}
	return selected
}

func defaultInsight(category string) HomeInsight {
	switch strings.ToUpper(category) {
	case "END_OF_DAY":
		return HomeInsight{
			Title:   "Dia encerrando",
			Summary: "Hoje ja nao ha muito tempo livre.",
			Footer:  "Planeje o comeco de amanha.",
			IsFocus: false,
		}
	case "PENDING_TIMES":
		return HomeInsight{
			Title:   "Horarios pendentes",
			Summary: "{{untimed_count}} ainda sem horario.",
			Footer:  "Defina os horarios para se organizar melhor",
			IsFocus: false,
		}
	case "MISSING_TIMES":
		return HomeInsight{
			Title:   "Faltam horarios",
			Summary: "{{untimed_count}} compromisso(s) ainda sem horario.",
			Footer:  "Defina os horarios para organizar melhor.",
			IsFocus: false,
		}
	case "MELHOR_MOMENTO":
		return HomeInsight{
			Title:   "Melhor momento",
			Summary: "{{start}} - {{end}} para fazer algo em paz.",
			Footer:  "{{footer_dynamic}}",
			IsFocus: true,
		}
	case "GOOD_FREE_TIME":
		return HomeInsight{
			Title:   "Bom tempo livre",
			Summary: "{{start}} - {{end}} esta disponivel.",
			Footer:  "Da para resolver algo importante.",
			IsFocus: true,
		}
	case "FREE_TIME":
		return HomeInsight{
			Title:   "Tempo livre",
			Summary: "{{start}} - {{end}} ({{duration}} min livres).",
			Footer:  "Que tal adiantar algo as {{start}}?",
			IsFocus: true,
		}
	default:
		return HomeInsight{
			Title:   "Dia mais corrido",
			Summary: "Maior tempo livre hoje e {{start}} - {{end}}.",
			Footer:  "Tente aproveitar pequenas pausas.",
			IsFocus: false,
		}
	}
}

func applyTemplateVars(template string, vars map[string]string) string {
	out := template
	for key, value := range vars {
		out = strings.ReplaceAll(out, "{{"+key+"}}", value)
	}
	return out
}

func latestSlotEnd(slots []timeRange) *time.Time {
	if len(slots) == 0 {
		return nil
	}
	latest := slots[0].end
	for i := 1; i < len(slots); i++ {
		if slots[i].end.After(latest) {
			latest = slots[i].end
		}
	}
	return &latest
}

func buildBusyRanges(slots []timeRange, from, until time.Time) []timeRange {
	ranges := make([]timeRange, 0, len(slots))
	for _, slot := range slots {
		start := slot.start
		end := slot.end
		if !end.After(start) {
			continue
		}
		if start.Before(from) {
			start = from
		}
		if end.After(until) {
			end = until
		}
		if !end.After(start) {
			continue
		}
		ranges = append(ranges, timeRange{start: start, end: end})
	}

	sort.Slice(ranges, func(i, j int) bool {
		return ranges[i].start.Before(ranges[j].start)
	})

	if len(ranges) == 0 {
		return ranges
	}

	merged := make([]timeRange, 0, len(ranges))
	merged = append(merged, ranges[0])
	for i := 1; i < len(ranges); i++ {
		last := merged[len(merged)-1]
		current := ranges[i]
		if !current.start.After(last.end) {
			if current.end.After(last.end) {
				merged[len(merged)-1].end = current.end
			}
			continue
		}
		merged = append(merged, current)
	}
	return merged
}

func findLargestGap(busyRanges []timeRange, from, until time.Time) timeRange {
	best := timeRange{start: from, end: from}
	if len(busyRanges) == 0 {
		return timeRange{start: from, end: until}
	}

	cursor := from
	for _, r := range busyRanges {
		if r.start.After(cursor) {
			gap := timeRange{start: cursor, end: r.start}
			if gap.end.Sub(gap.start) > best.end.Sub(best.start) {
				best = gap
			}
		}
		if r.end.After(cursor) {
			cursor = r.end
		}
	}

	if until.After(cursor) {
		tail := timeRange{start: cursor, end: until}
		if tail.end.Sub(tail.start) > best.end.Sub(best.start) {
			best = tail
		}
	}

	return best
}

func (uc *HomeUsecase) buildWeekDensity(ctx context.Context, userID string, now time.Time, loc *time.Location) (map[string]int, error) {
	today := startOfDay(now)
	weekday := int(today.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	startOfWeek := today.AddDate(0, 0, -(weekday - 1))
	endOfWeek := startOfWeek.AddDate(0, 0, 7)

	density := make(map[string]int, 7)
	for i := 0; i < 7; i++ {
		day := startOfWeek.AddDate(0, 0, i)
		density[day.Format("2006-01-02")] = 0
	}

	occurrences, err := uc.Home.ListWeekOccurrences(ctx, userID, startOfWeek.UTC(), endOfWeek.UTC())
	if err != nil {
		return nil, err
	}

	for _, at := range occurrences {
		local := at.In(loc)
		day := startOfDay(local)
		if day.Before(startOfWeek) || !day.Before(endOfWeek) {
			continue
		}
		key := day.Format("2006-01-02")
		density[key] = density[key] + 1
	}

	return density, nil
}

func (uc *HomeUsecase) nowInUserTimezone(ctx context.Context, userID string) (time.Time, *time.Location) {
	now := time.Now()
	if uc.Users == nil || userID == "" {
		return now, now.Location()
	}

	user, err := uc.Users.Get(ctx, userID)
	if err != nil {
		return now, now.Location()
	}
	if user.Timezone == "" {
		return now, now.Location()
	}

	loc, err := time.LoadLocation(user.Timezone)
	if err != nil {
		return now, now.Location()
	}

	return now.In(loc), loc
}

func parseRoutineTimeForDay(raw string, base time.Time) (time.Time, bool) {
	value := strings.TrimSpace(raw)
	if value == "" {
		return time.Time{}, false
	}

	parts := strings.Split(value, ":")
	if len(parts) < 2 {
		return time.Time{}, false
	}

	hour, err := strconv.Atoi(parts[0])
	if err != nil {
		return time.Time{}, false
	}
	minute, err := strconv.Atoi(parts[1])
	if err != nil {
		return time.Time{}, false
	}
	if hour < 0 || hour > 23 || minute < 0 || minute > 59 {
		return time.Time{}, false
	}

	return time.Date(base.Year(), base.Month(), base.Day(), hour, minute, 0, 0, base.Location()), true
}

func weekdaysLabel(weekdays []int) string {
	if len(weekdays) == 0 {
		return ""
	}
	if len(weekdays) == 7 {
		return "Todo dia"
	}

	has := make(map[int]bool, len(weekdays))
	for _, d := range weekdays {
		has[d] = true
	}

	if len(weekdays) == 5 && has[1] && has[2] && has[3] && has[4] && has[5] {
		return "Seg-Sex"
	}
	if len(weekdays) == 2 && has[0] && has[6] {
		return "Final de semana"
	}

	dayNames := map[int]string{
		0: "Dom",
		1: "Seg",
		2: "Ter",
		3: "Qua",
		4: "Qui",
		5: "Sex",
		6: "Sab",
	}

	sorted := make([]int, 0, len(weekdays))
	for _, d := range weekdays {
		sorted = append(sorted, d)
	}
	sort.Ints(sorted)

	labels := make([]string, 0, len(sorted))
	for _, d := range sorted {
		if name, ok := dayNames[d]; ok {
			labels = append(labels, name)
		}
	}
	return strings.Join(labels, "-")
}

func normalizeText(value string) string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return ""
	}
	return trimmed
}

func trimPtr(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func toLocalPtr(value *time.Time, loc *time.Location) *time.Time {
	if value == nil {
		return nil
	}
	v := value.In(loc)
	return &v
}

func startOfDay(value time.Time) time.Time {
	return time.Date(value.Year(), value.Month(), value.Day(), 0, 0, 0, 0, value.Location())
}

func hasDefinedTime(value time.Time) bool {
	return value.Hour() != 0 || value.Minute() != 0 || value.Second() != 0 || value.Nanosecond() != 0
}

func clamp01(value float64) float64 {
	if value < 0 {
		return 0
	}
	if value > 1 {
		return 1
	}
	return value
}

func formatHM(value time.Time) string {
	return value.Format("15:04")
}
