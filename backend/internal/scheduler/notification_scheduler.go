package scheduler

import (
	"context"
	"fmt"
	"log/slog"
	"strconv"
	"strings"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/infra/push"
)

type NotificationScheduler struct {
	Prefs     repository.NotificationPreferencesRepository
	Log       repository.NotificationLogRepository
	Tokens    repository.DeviceTokenRepository
	Users     repository.UserRepository
	Reminders repository.ReminderRepository
	Events    repository.EventRepository
	Tasks     repository.TaskRepository
	Routines  repository.RoutineRepository
	Templates repository.NotificationTemplateRepository
	Config    repository.AppConfigRepository
	Ntfy      *push.NtfyClient
	Logger    *slog.Logger

	// carregados em memória no startup
	templates map[string]domain.NotificationTemplate // "type_triggerKey" -> template
	config    map[string]string
}

func (s *NotificationScheduler) Run(ctx context.Context) {
	if err := s.loadCache(ctx); err != nil {
		s.Logger.Warn("scheduler_cache_load_failed", slog.String("error", err.Error()))
	}

	ticker := time.NewTicker(s.tickerInterval())
	defer ticker.Stop()

	s.Logger.Info("notification_scheduler_started")

	for {
		select {
		case <-ticker.C:
			s.scheduleUpcoming(ctx)
			s.dispatch(ctx)
		case <-ctx.Done():
			return
		}
	}
}

// loadCache carrega templates e configs do banco para memória.
func (s *NotificationScheduler) loadCache(ctx context.Context) error {
	tmpls, err := s.Templates.GetAll(ctx)
	if err != nil {
		return fmt.Errorf("load templates: %w", err)
	}
	s.templates = make(map[string]domain.NotificationTemplate, len(tmpls))
	for _, t := range tmpls {
		s.templates[string(t.Type)+"_"+t.TriggerKey] = t
	}

	cfg, err := s.Config.GetAll(ctx)
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}
	s.config = cfg
	return nil
}

func (s *NotificationScheduler) tickerInterval() time.Duration {
	secs := s.configInt("scheduler.ticker_interval_seconds", 60)
	return time.Duration(secs) * time.Second
}

func (s *NotificationScheduler) configInt(key string, defaultVal int) int {
	if s.config == nil {
		return defaultVal
	}
	v, ok := s.config[key]
	if !ok {
		return defaultVal
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return defaultVal
	}
	return n
}

func (s *NotificationScheduler) configStr(key, defaultVal string) string {
	if s.config == nil {
		return defaultVal
	}
	v, ok := s.config[key]
	if !ok {
		return defaultVal
	}
	return v
}

// renderTemplate substitui placeholders {{key}} com os valores fornecidos.
func (s *NotificationScheduler) renderTemplate(tpl string, vars map[string]string) string {
	for k, v := range vars {
		tpl = strings.ReplaceAll(tpl, "{{"+k+"}}", v)
	}
	return tpl
}

// buildMessage retorna (title, body) para o tipo e gatilho especificados.
// Fallback para strings fixas caso o template não exista no cache.
func (s *NotificationScheduler) buildMessage(nType domain.NotificationType, triggerKey, itemTitle string, vars map[string]string) (title, body string) {
	if vars == nil {
		vars = map[string]string{}
	}

	cacheKey := string(nType) + "_" + triggerKey
	vars["title"] = itemTitle

	if tpl, ok := s.templates[cacheKey]; ok {
		title = s.renderTemplate(tpl.TitleTemplate, vars)
		body = s.renderTemplate(tpl.BodyTemplate, vars)
		if isLeadTemplateInvalid(triggerKey, title, body, vars) {
			return defaultNotificationMessage(nType, triggerKey, itemTitle, vars)
		}
		return
	}

	return defaultNotificationMessage(nType, triggerKey, itemTitle, vars)
}

func (s *NotificationScheduler) scheduleUpcoming(ctx context.Context) {
	now := time.Now()
	nowMinute := now.Truncate(time.Minute)
	nowUTCMinute := now.UTC().Truncate(time.Minute)
	dayThreshold := s.configInt("scheduler.day_threshold_mins", 1440)
	reminderLookahead := time.Duration(s.configInt("scheduler.reminder_lookahead_hours", 2)) * time.Hour
	eventLookahead := time.Duration(s.configInt("scheduler.event_lookahead_hours", 24)) * time.Hour
	taskLookahead := time.Duration(s.configInt("scheduler.task_lookahead_hours", 24)) * time.Hour

	// 1. Reminders
	reminders, err := s.Reminders.ListUpcoming(ctx, now, now.Add(reminderLookahead))
	if err != nil {
		s.Logger.Error("scheduler_list_reminders_error", slog.String("error", err.Error()))
	} else {
		for _, r := range reminders {
			prefs, err := s.Prefs.GetByUserID(ctx, r.UserID)
			if err != nil || !prefs.RemindersEnabled {
				continue
			}

			if prefs.ReminderAtTime {
				title, body := s.buildMessage(domain.NotificationTypeReminder, "at_time", r.Title, map[string]string{})
				s.scheduleItem(ctx, r.UserID, domain.NotificationTypeReminder, r.ID, title, body, r.RemindAt, nil)
			}

			for _, mins := range prefs.ReminderLeadMins {
				scheduledFor := r.RemindAt.Add(time.Duration(-mins) * time.Minute)
				if !scheduledFor.Before(nowMinute) {
					title, body := s.buildMessage(domain.NotificationTypeReminder, "lead_time", r.Title, map[string]string{
						"lead_mins": strconv.Itoa(mins),
					})
					s.scheduleItem(ctx, r.UserID, domain.NotificationTypeReminder, r.ID, title, body, &scheduledFor, &mins)
				}
			}
		}
	}

	// 2. Events
	events, err := s.Events.ListUpcoming(ctx, now, now.Add(eventLookahead))
	if err != nil {
		s.Logger.Error("scheduler_list_events_error", slog.String("error", err.Error()))
	} else {
		for _, e := range events {
			prefs, err := s.Prefs.GetByUserID(ctx, e.UserID)
			if err != nil || !prefs.EventsEnabled {
				continue
			}

			if prefs.EventAtTime {
				title, body := s.buildMessage(domain.NotificationTypeEvent, "at_time", e.Title, map[string]string{})
				s.scheduleItem(ctx, e.UserID, domain.NotificationTypeEvent, e.ID, title, body, e.StartAt, nil)
			}

			for _, mins := range prefs.EventLeadMins {
				scheduledFor := e.StartAt.Add(time.Duration(-mins) * time.Minute)
				if !scheduledFor.Before(nowMinute) {
					triggerKey := "lead_time"
					if mins >= dayThreshold {
						triggerKey = "lead_time_day"
					}
					title, body := s.buildMessage(domain.NotificationTypeEvent, triggerKey, e.Title, map[string]string{
						"lead_mins": strconv.Itoa(mins),
					})
					s.scheduleItem(ctx, e.UserID, domain.NotificationTypeEvent, e.ID, title, body, &scheduledFor, &mins)
				}
			}
		}
	}

	// 3. Tasks
	tasks, err := s.Tasks.ListUpcoming(ctx, now, now.Add(taskLookahead))
	if err != nil {
		s.Logger.Error("scheduler_list_tasks_error", slog.String("error", err.Error()))
	} else {
		for _, t := range tasks {
			prefs, err := s.Prefs.GetByUserID(ctx, t.UserID)
			if err != nil || !prefs.TasksEnabled {
				continue
			}

			if prefs.TaskAtTime {
				title, body := s.buildMessage(domain.NotificationTypeTask, "at_time", t.Title, map[string]string{})
				s.scheduleItem(ctx, t.UserID, domain.NotificationTypeTask, t.ID, title, body, t.DueAt, nil)
			}

			for _, mins := range prefs.TaskLeadMins {
				scheduledFor := t.DueAt.Add(time.Duration(-mins) * time.Minute)
				if !scheduledFor.Before(nowMinute) {
					triggerKey := "lead_time"
					if mins >= dayThreshold {
						triggerKey = "lead_time_day"
					}
					title, body := s.buildMessage(domain.NotificationTypeTask, triggerKey, t.Title, map[string]string{
						"lead_mins": strconv.Itoa(mins),
					})
					s.scheduleItem(ctx, t.UserID, domain.NotificationTypeTask, t.ID, title, body, &scheduledFor, &mins)
				}
			}
		}
	}

	// 4. Routines (considerando timezone do usuário e recorrência)
	candidateWeekdays := schedulerCandidateWeekdays(now)
	routinesByID := make(map[string]domain.Routine)
	for _, weekday := range candidateWeekdays {
		routines, err := s.Routines.ListAllByWeekday(ctx, weekday)
		if err != nil {
			s.Logger.Error("scheduler_list_routines_error", slog.String("error", err.Error()), slog.Int("weekday", weekday))
			continue
		}
		for _, routine := range routines {
			routinesByID[routine.ID] = routine
		}
	}

	userCache := make(map[string]domain.User)
	locCache := make(map[string]*time.Location)
	for _, r := range routinesByID {
		prefs, err := s.Prefs.GetByUserID(ctx, r.UserID)
		if err != nil || !prefs.RoutinesEnabled {
			continue
		}

		user, ok := userCache[r.UserID]
		if !ok {
			loadedUser, err := s.Users.Get(ctx, r.UserID)
			if err != nil {
				continue
			}
			user = loadedUser
			userCache[r.UserID] = user
		}

		loc := timezoneLocation(user.Timezone, locCache)
		userNow := now.In(loc)

		if !routineHasWeekday(r.Weekdays, int(userNow.Weekday())) {
			continue
		}
		if !shouldShowRoutineForDate(r, userNow) {
			continue
		}

		startTime, err := time.Parse("15:04", r.StartTime)
		if err != nil {
			continue
		}

		scheduledForLocal := time.Date(userNow.Year(), userNow.Month(), userNow.Day(), startTime.Hour(), startTime.Minute(), 0, 0, loc)
		scheduledForUTC := scheduledForLocal.UTC()

		if prefs.RoutineAtTime && !scheduledForUTC.Before(nowUTCMinute) {
			title, body := s.buildMessage(domain.NotificationTypeRoutine, "at_time", r.Title, map[string]string{})
			s.scheduleItem(ctx, r.UserID, domain.NotificationTypeRoutine, r.ID, title, body, &scheduledForUTC, nil)
		}

		for _, mins := range prefs.RoutineLeadMins {
			if mins <= 0 {
				continue
			}
			leadScheduledForUTC := scheduledForUTC.Add(time.Duration(-mins) * time.Minute)
			if !leadScheduledForUTC.Before(nowUTCMinute) {
				title, body := s.buildMessage(domain.NotificationTypeRoutine, "lead_time", r.Title, map[string]string{
					"lead_mins": strconv.Itoa(mins),
				})
				s.scheduleItem(ctx, r.UserID, domain.NotificationTypeRoutine, r.ID, title, body, &leadScheduledForUTC, &mins)
			}
		}
	}
}

func (s *NotificationScheduler) scheduleItem(ctx context.Context, userID string, nType domain.NotificationType, refID string, title, body string, scheduledFor *time.Time, leadMins *int) {
	if scheduledFor == nil {
		return
	}

	exists, err := s.Log.Exists(ctx, refID, leadMins)
	if err != nil || exists {
		return
	}

	_, err = s.Log.Create(ctx, domain.NotificationLog{
		UserID:       userID,
		Type:         nType,
		ReferenceID:  refID,
		Title:        title,
		Body:         body,
		LeadMins:     leadMins,
		Status:       domain.NotificationStatusPending,
		ScheduledFor: *scheduledFor,
	})
	if err != nil {
		s.Logger.Error("schedule_item_error", slog.String("error", err.Error()), slog.String("ref_id", refID))
	}
}

func isLeadTemplateInvalid(triggerKey, title, body string, vars map[string]string) bool {
	combined := strings.ToLower(strings.TrimSpace(title + " " + body))
	switch triggerKey {
	case "lead_time":
		lead := strings.TrimSpace(vars["lead_mins"])
		if lead == "" {
			return false
		}
		if strings.Contains(combined, "agora") {
			return true
		}
		return !strings.Contains(combined, lead)
	case "lead_time_day":
		return !strings.Contains(combined, "amanh")
	default:
		return false
	}
}

func defaultNotificationMessage(nType domain.NotificationType, triggerKey, itemTitle string, vars map[string]string) (string, string) {
	lead := strings.TrimSpace(vars["lead_mins"])
	leadLabel := humanLeadLabel(lead)

	switch nType {
	case domain.NotificationTypeReminder:
		switch triggerKey {
		case "at_time":
			return "Lembrete agora", itemTitle
		case "lead_time":
			return "Lembrete em " + leadLabel, itemTitle
		case "lead_time_day":
			return "Lembrete amanhã", itemTitle
		}
	case domain.NotificationTypeEvent:
		switch triggerKey {
		case "at_time":
			return "Evento começando", itemTitle + " começa agora."
		case "lead_time":
			return "Evento em " + leadLabel, itemTitle + " começa em " + leadLabel + "."
		case "lead_time_day":
			return "Evento amanhã", itemTitle + " começa amanhã."
		}
	case domain.NotificationTypeTask:
		switch triggerKey {
		case "at_time":
			return "Prazo agora", itemTitle + " vence agora."
		case "lead_time":
			return "Prazo em " + leadLabel, itemTitle + " vence em " + leadLabel + "."
		case "lead_time_day":
			return "Prazo amanhã", itemTitle + " vence amanhã."
		}
	case domain.NotificationTypeRoutine:
		switch triggerKey {
		case "at_time":
			return "Hora da rotina", itemTitle + " começa agora."
		case "lead_time":
			return "Rotina em " + leadLabel, itemTitle + " começa em " + leadLabel + "."
		case "lead_time_day":
			return "Rotina amanhã", itemTitle + " começa amanhã."
		}
	}

	// fallback final
	switch triggerKey {
	case "at_time":
		return itemTitle, "Agora"
	case "lead_time":
		return itemTitle, "Em " + leadLabel
	case "lead_time_day":
		return itemTitle, "Amanhã"
	default:
		return itemTitle, ""
	}
}

func humanLeadLabel(raw string) string {
	mins, err := strconv.Atoi(raw)
	if err != nil || mins <= 0 {
		return "breve"
	}
	if mins == 1 {
		return "1 minuto"
	}
	return strconv.Itoa(mins) + " minutos"
}

func schedulerCandidateWeekdays(now time.Time) []int {
	values := []int{
		int(now.Add(-24 * time.Hour).Weekday()),
		int(now.Weekday()),
		int(now.Add(24 * time.Hour).Weekday()),
	}
	seen := make(map[int]struct{})
	result := make([]int, 0, len(values))
	for _, value := range values {
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func timezoneLocation(timezone string, cache map[string]*time.Location) *time.Location {
	tz := strings.TrimSpace(timezone)
	if tz == "" {
		return time.UTC
	}
	if loc, ok := cache[tz]; ok {
		return loc
	}
	loc, err := time.LoadLocation(tz)
	if err != nil {
		cache[tz] = time.UTC
		return time.UTC
	}
	cache[tz] = loc
	return loc
}

func routineHasWeekday(weekdays []int, weekday int) bool {
	for _, w := range weekdays {
		if w == weekday {
			return true
		}
	}
	return false
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

func (s *NotificationScheduler) dispatch(ctx context.Context) {
	now := time.Now()
	pending, err := s.Log.ListPending(ctx, now)
	if err != nil {
		s.Logger.Error("scheduler_list_pending_error", slog.String("error", err.Error()))
		return
	}

	for _, l := range pending {
		s.dispatchOne(ctx, l)
	}
}

func (s *NotificationScheduler) dispatchOne(ctx context.Context, l domain.NotificationLog) {
	// 1. Busca tópicos do usuário
	tokens, err := s.Tokens.ListByUserID(ctx, l.UserID)
	if err != nil || len(tokens) == 0 {
		return
	}

	// 2. Verifica quiet hours
	prefs, err := s.Prefs.GetByUserID(ctx, l.UserID)
	if err == nil && prefs.QuietHoursEnabled && prefs.QuietStart != nil && prefs.QuietEnd != nil {
		user, err := s.Users.Get(ctx, l.UserID)
		if err == nil {
			loc, err := time.LoadLocation(user.Timezone)
			if err == nil {
				nowUser := time.Now().In(loc)
				if s.isInsideQuietHours(nowUser, *prefs.QuietStart, *prefs.QuietEnd) {
					s.postpone(ctx, l, *prefs.QuietEnd, loc)
					return
				}
			}
		}
	}

	// 3. Envia via ntfy.sh
	data := map[string]string{
		"type":                string(l.Type),
		"reference_id":        l.ReferenceID,
		"notification_log_id": l.ID,
		"click_url":           s.generateClickURL(l),
	}
	if l.LeadMins != nil {
		data["lead_mins"] = strconv.Itoa(*l.LeadMins)
	}

	success := false
	for _, t := range tokens {
		if s.Ntfy != nil {
			err := s.Ntfy.Send(ctx, t.Topic, l.Title, l.Body, data)
			if err == nil {
				success = true
			} else {
				s.Logger.Warn("ntfy_send_error", slog.String("error", err.Error()), slog.String("topic", t.Topic))
			}
		}
	}

	if success {
		if err := s.Log.UpdateStatus(ctx, l.ID, domain.NotificationStatusSent, nil); err != nil {
			s.Logger.Error("update_status_sent_error", slog.String("error", err.Error()))
		}
	} else {
		msg := "failed to send to all devices via ntfy"
		if err := s.Log.UpdateStatus(ctx, l.ID, domain.NotificationStatusFailed, &msg); err != nil {
			s.Logger.Error("update_status_failed_error", slog.String("error", err.Error()))
		}
	}
}

func (s *NotificationScheduler) generateClickURL(l domain.NotificationLog) string {
	switch l.Type {
	case domain.NotificationTypeReminder:
		return "/reminders?id=" + l.ReferenceID
	case domain.NotificationTypeEvent:
		return "/events?id=" + l.ReferenceID
	case domain.NotificationTypeTask:
		return "/home?id=" + l.ReferenceID
	case domain.NotificationTypeRoutine:
		return "/schedule"
	default:
		return "/"
	}
}

func (s *NotificationScheduler) isInsideQuietHours(t time.Time, start, end string) bool {
	startTime, err := time.Parse("15:04", start)
	if err != nil {
		s.Logger.Warn("quiet_hours_parse_start_error", slog.String("value", start), slog.String("error", err.Error()))
		return false
	}
	endTime, err := time.Parse("15:04", end)
	if err != nil {
		s.Logger.Warn("quiet_hours_parse_end_error", slog.String("value", end), slog.String("error", err.Error()))
		return false
	}

	nowMinutes := t.Hour()*60 + t.Minute()
	startMinutes := startTime.Hour()*60 + startTime.Minute()
	endMinutes := endTime.Hour()*60 + endTime.Minute()

	if startMinutes < endMinutes {
		return nowMinutes >= startMinutes && nowMinutes < endMinutes
	}
	// Passa da meia-noite
	return nowMinutes >= startMinutes || nowMinutes < endMinutes
}

func (s *NotificationScheduler) postpone(ctx context.Context, l domain.NotificationLog, quietEnd string, loc *time.Location) {
	endTime, err := time.Parse("15:04", quietEnd)
	if err != nil {
		s.Logger.Warn("postpone_parse_error", slog.String("value", quietEnd), slog.String("error", err.Error()))
		return
	}
	now := time.Now().In(loc)
	scheduledFor := time.Date(now.Year(), now.Month(), now.Day(), endTime.Hour(), endTime.Minute(), 0, 0, loc)
	if scheduledFor.Before(now) {
		scheduledFor = scheduledFor.Add(24 * time.Hour)
	}

	if err := s.Log.UpdateScheduledFor(ctx, l.ID, scheduledFor.UTC()); err != nil {
		s.Logger.Error("postpone_update_error", slog.String("error", err.Error()))
		return
	}
	s.Logger.Info("notification_postponed", slog.String("id", l.ID), slog.Time("new_scheduled_for", scheduledFor))
}
