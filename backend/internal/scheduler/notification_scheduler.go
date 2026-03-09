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
	cacheKey := string(nType) + "_" + triggerKey
	vars["title"] = itemTitle

	if tpl, ok := s.templates[cacheKey]; ok {
		title = s.renderTemplate(tpl.TitleTemplate, vars)
		body = s.renderTemplate(tpl.BodyTemplate, vars)
		return
	}

	// fallback
	title = itemTitle
	switch triggerKey {
	case "at_time":
		body = string(nType) + " agora"
	case "lead_time":
		body = string(nType) + " em " + vars["lead_mins"] + " minutos"
	case "lead_time_day":
		body = string(nType) + " amanhã"
	}
	return
}

func (s *NotificationScheduler) scheduleUpcoming(ctx context.Context) {
	now := time.Now()
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
				if scheduledFor.After(now) {
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
				if scheduledFor.After(now) {
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
				if scheduledFor.After(now) {
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

	// 4. Routines
	weekday := int(now.Weekday())
	routines, err := s.Routines.ListAllByWeekday(ctx, weekday)
	if err != nil {
		s.Logger.Error("scheduler_list_routines_error", slog.String("error", err.Error()))
	} else {
		for _, r := range routines {
			prefs, err := s.Prefs.GetByUserID(ctx, r.UserID)
			if err != nil || !prefs.RoutinesEnabled {
				continue
			}

			startTime, err := time.Parse("15:04", r.StartTime)
			if err != nil {
				continue
			}
			scheduledFor := time.Date(now.Year(), now.Month(), now.Day(), startTime.Hour(), startTime.Minute(), 0, 0, now.Location())

			if prefs.RoutineAtTime {
				title, body := s.buildMessage(domain.NotificationTypeRoutine, "at_time", r.Title, map[string]string{})
				s.scheduleItem(ctx, r.UserID, domain.NotificationTypeRoutine, r.ID, title, body, &scheduledFor, nil)
			}

			for _, mins := range prefs.RoutineLeadMins {
				leadScheduledFor := scheduledFor.Add(time.Duration(-mins) * time.Minute)
				if leadScheduledFor.After(now) {
					title, body := s.buildMessage(domain.NotificationTypeRoutine, "lead_time", r.Title, map[string]string{
						"lead_mins": strconv.Itoa(mins),
					})
					s.scheduleItem(ctx, r.UserID, domain.NotificationTypeRoutine, r.ID, title, body, &leadScheduledFor, &mins)
				}
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
