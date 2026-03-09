package digest

import (
	"bytes"
	"context"
	"fmt"
	htmltemplate "html/template"
	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/infra/mailer"
	"log/slog"
	"sort"
	"strconv"
	"strings"
	texttemplate "text/template"
	"time"
)

const (
	digestTypeDaily      = "daily_digest"
	maxDigestPageSize    = 200
	defaultDigestSubject = "Seu dia no Inbota"
)

type RoutineWeekdayLister interface {
	ListByWeekday(ctx context.Context, userID string, weekday int, date string) ([]domain.Routine, error)
}

type DigestService struct {
	userRepo         repository.UserRepository
	notifPrefsRepo   repository.NotificationPreferencesRepository
	emailDigestRepo  repository.EmailDigestRepository
	routineLister    RoutineWeekdayLister
	agendaRepo       repository.AgendaRepository
	taskRepo         repository.TaskRepository
	shoppingListRepo repository.ShoppingListRepository
	shoppingItemRepo repository.ShoppingItemRepository
	flagRepo         repository.FlagRepository
	subflagRepo      repository.SubflagRepository
	mailer           mailer.Mailer
	htmlTemplate     *htmltemplate.Template
	textTemplate     *texttemplate.Template
	now              func() time.Time
	log              *slog.Logger
}

func NewDigestService(
	userRepo repository.UserRepository,
	notifPrefsRepo repository.NotificationPreferencesRepository,
	emailDigestRepo repository.EmailDigestRepository,
	routineLister RoutineWeekdayLister,
	agendaRepo repository.AgendaRepository,
	taskRepo repository.TaskRepository,
	shoppingListRepo repository.ShoppingListRepository,
	shoppingItemRepo repository.ShoppingItemRepository,
	flagRepo repository.FlagRepository,
	subflagRepo repository.SubflagRepository,
	mailClient mailer.Mailer,
) (*DigestService, error) {
	htmlTmpl, textTmpl, err := mailer.ParseDailyDigestTemplates()
	if err != nil {
		return nil, fmt.Errorf("parse digest templates: %w", err)
	}

	return &DigestService{
		userRepo:         userRepo,
		notifPrefsRepo:   notifPrefsRepo,
		emailDigestRepo:  emailDigestRepo,
		routineLister:    routineLister,
		agendaRepo:       agendaRepo,
		taskRepo:         taskRepo,
		shoppingListRepo: shoppingListRepo,
		shoppingItemRepo: shoppingItemRepo,
		flagRepo:         flagRepo,
		subflagRepo:      subflagRepo,
		mailer:           mailClient,
		htmlTemplate:     htmlTmpl,
		textTemplate:     textTmpl,
		now:              time.Now,
		log:              slog.Default(),
	}, nil
}

type DigestData struct {
	Date             string             `json:"date"`
	Detail           DigestDetail       `json:"detail"`
	HasSchedule      bool               `json:"hasSchedule"`
	Schedule         []ScheduleItemData `json:"schedule"`
	HasAgenda        bool               `json:"hasAgenda"`
	Agenda           []AgendaItemData   `json:"agenda"`
	HasReminders     bool               `json:"hasReminders"`
	Reminders        []ReminderItemData `json:"reminders"`
	HasTasks         bool               `json:"hasTasks"`
	Tasks            []TaskItemData     `json:"tasks"`
	HasOpenTasks     bool               `json:"hasOpenTasks"`
	OpenTasks        []TaskItemData     `json:"openTasks"`
	HasShoppingLists bool               `json:"hasShoppingLists"`
	ShoppingLists    []ShoppingListData `json:"shoppingLists"`
}

type DigestDetail struct {
	Purpose       string `json:"purpose"`
	Schedule      string `json:"schedule"`
	Agenda        string `json:"agenda"`
	Reminders     string `json:"reminders"`
	Tasks         string `json:"tasks"`
	OpenTasks     string `json:"openTasks"`
	ShoppingLists string `json:"shoppingLists"`
	Flags         string `json:"flags"`
}

type ScheduleItemData struct {
	Time        string `json:"time"`
	Title       string `json:"title"`
	Recurrence  string `json:"recurrence"`
	Context     string `json:"context"`
	IsCompleted bool   `json:"isCompleted"`
}

type AgendaItemData struct {
	Time    string `json:"time"`
	Type    string `json:"type"`
	TypeKey string `json:"typeKey"`
	Title   string `json:"title"`
	Context string `json:"context"`
}

type ReminderItemData struct {
	Time  string `json:"time"`
	Title string `json:"title"`
}

type TaskItemData struct {
	DueTime string `json:"dueTime"`
	Title   string `json:"title"`
}

type ShoppingListData struct {
	Title        string   `json:"title"`
	PendingCount int      `json:"pendingCount"`
	PendingItems []string `json:"pendingItems"`
}

func (s *DigestService) SetNow(nowFn func() time.Time) {
	if nowFn != nil {
		s.now = nowFn
	}
}

func (s *DigestService) SetLogger(logger *slog.Logger) {
	if logger != nil {
		s.log = logger
	}
}

func (s *DigestService) BuildDigestData(ctx context.Context, userID string, targetDate time.Time) (DigestData, error) {
	if targetDate.IsZero() {
		targetDate = s.now()
	}
	loc := targetDate.Location()

	data := DigestData{
		Date:   targetDate.Format("02/01/2006"),
		Detail: defaultDigestDetail(),
	}

	startOfDay := time.Date(targetDate.Year(), targetDate.Month(), targetDate.Day(), 0, 0, 0, 0, loc)
	endOfDay := startOfDay.Add(24 * time.Hour)

	scheduleItems, err := s.buildScheduleItems(ctx, userID, targetDate)
	if err != nil {
		return DigestData{}, err
	}
	data.Schedule = scheduleItems

	agendaItems, err := s.agendaRepo.List(ctx, userID, repository.ListOptions{
		Limit:   maxDigestPageSize,
		StartAt: &startOfDay,
		EndAt:   &endOfDay,
	})
	if err != nil {
		return DigestData{}, fmt.Errorf("list agenda: %w", err)
	}

	for _, item := range agendaItems {
		scheduledAt := item.ScheduledAt.In(loc)
		if scheduledAt.Before(startOfDay) || !scheduledAt.Before(endOfDay) {
			continue
		}
		typeLabel, typeKey := agendaType(item.ItemType)
		contextLabel := contextPath(item.FlagName, item.SubflagName)

		data.Agenda = append(data.Agenda, AgendaItemData{
			Time:    agendaTimeLabel(item, scheduledAt),
			Type:    typeLabel,
			TypeKey: typeKey,
			Title:   item.Title,
			Context: contextLabel,
		})

		if item.ItemType == "reminder" {
			data.Reminders = append(data.Reminders, ReminderItemData{
				Time:  agendaTimeLabel(item, scheduledAt),
				Title: item.Title,
			})
		}
	}

	tasks, err := s.listAllTasks(ctx, userID)
	if err != nil {
		return DigestData{}, fmt.Errorf("list tasks: %w", err)
	}

	for _, t := range tasks {
		if t.Status != domain.TaskStatusOpen {
			continue
		}
		if t.DueAt == nil {
			data.OpenTasks = append(data.OpenTasks, TaskItemData{Title: t.Title})
			continue
		}
		dueAt := t.DueAt.In(loc)
		if dueAt.Before(startOfDay) || !dueAt.Before(endOfDay) {
			continue
		}
		data.Tasks = append(data.Tasks, TaskItemData{
			DueTime: dueAt.Format("15:04"),
			Title:   t.Title,
		})
	}

	lists, err := s.listAllShoppingLists(ctx, userID)
	if err != nil {
		return DigestData{}, fmt.Errorf("list shopping lists: %w", err)
	}

	for _, list := range lists {
		if list.Status != domain.ShoppingListStatusOpen {
			continue
		}

		items, err := s.listAllShoppingItems(ctx, userID, list.ID)
		if err != nil {
			return DigestData{}, fmt.Errorf("list shopping items for list %s: %w", list.ID, err)
		}

		pendingItems := make([]string, 0)
		for _, item := range items {
			if !item.Checked {
				pendingItems = append(pendingItems, shoppingItemLabel(item))
			}
		}
		if len(pendingItems) == 0 {
			continue
		}

		data.ShoppingLists = append(data.ShoppingLists, ShoppingListData{
			Title:        list.Title,
			PendingCount: len(pendingItems),
			PendingItems: pendingItems,
		})
	}

	sort.Slice(data.Tasks, func(i, j int) bool {
		return data.Tasks[i].DueTime < data.Tasks[j].DueTime
	})
	sort.Slice(data.Reminders, func(i, j int) bool {
		return data.Reminders[i].Time < data.Reminders[j].Time
	})

	data.HasSchedule = len(data.Schedule) > 0
	data.HasAgenda = len(data.Agenda) > 0
	data.HasReminders = len(data.Reminders) > 0
	data.HasTasks = len(data.Tasks) > 0
	data.HasOpenTasks = len(data.OpenTasks) > 0
	data.HasShoppingLists = len(data.ShoppingLists) > 0

	return data, nil
}

func defaultDigestDetail() DigestDetail {
	return DigestDetail{
		Purpose:       "Resumo consolidado do dia do usuario para exibicao e interpretacao por IA.",
		Schedule:      "Itens de rotina planejados para hoje (habitos/rotinas recorrentes), com janela de horario, recorrencia, contexto e status de conclusao.",
		Agenda:        "Linha do tempo dos compromissos do dia (eventos, lembretes e outros itens com horario), com tipo, titulo e contexto.",
		Reminders:     "Subconjunto da agenda contendo apenas lembretes com horario e titulo, util para destaque rapido.",
		Tasks:         "Tarefas abertas com prazo para hoje, incluindo horario limite (dueTime) quando disponivel.",
		OpenTasks:     "Tarefas abertas sem prazo definido (backlog), priorize por relevancia/contexto na exibicao.",
		ShoppingLists: "Listas de compras abertas com contagem de itens pendentes e nomes dos itens ainda nao marcados.",
		Flags:         "Campos booleanos 'has*' indicam se cada secao possui dados para permitir renderizacao condicional na interface.",
	}
}

func (s *DigestService) ValidateUser(ctx context.Context, userID, email string) (bool, error) {
	user, err := s.userRepo.Get(ctx, userID)
	if err != nil {
		return false, err
	}
	if user.ID == "" {
		return false, nil
	}
	return strings.EqualFold(user.Email, strings.TrimSpace(email)), nil
}

func (s *DigestService) buildScheduleItems(ctx context.Context, userID string, targetDate time.Time) ([]ScheduleItemData, error) {
	if s.routineLister == nil {
		return nil, nil
	}

	weekday := int(targetDate.Weekday())
	date := targetDate.Format("2006-01-02")

	routines, err := s.routineLister.ListByWeekday(ctx, userID, weekday, date)
	if err != nil {
		return nil, fmt.Errorf("list routines: %w", err)
	}
	if len(routines) == 0 {
		return nil, nil
	}

	flagNames, subflagNames := s.loadRoutineContextMaps(ctx, userID, routines)

	items := make([]ScheduleItemData, 0, len(routines))
	for _, routine := range routines {
		items = append(items, ScheduleItemData{
			Time:        routineTimeLabel(routine.StartTime, routine.EndTime),
			Title:       routine.Title,
			Recurrence:  routineRecurrenceLabel(routine.RecurrenceType),
			Context:     routineContextPath(routine.FlagID, routine.SubflagID, flagNames, subflagNames),
			IsCompleted: routine.IsCompletedToday,
		})
	}

	return items, nil
}

func (s *DigestService) loadRoutineContextMaps(ctx context.Context, userID string, routines []domain.Routine) (map[string]string, map[string]string) {
	flagNames := make(map[string]string)
	subflagNames := make(map[string]string)

	if s.flagRepo != nil {
		flagIDs := collectIDs(routines, func(r domain.Routine) *string { return r.FlagID })
		if len(flagIDs) > 0 {
			flags, err := s.flagRepo.GetByIDs(ctx, userID, flagIDs)
			if err != nil {
				s.log.Warn("digest_flag_lookup_failed", slog.String("user_id", userID), slog.String("error", err.Error()))
			} else {
				for _, flag := range flags {
					flagNames[flag.ID] = flag.Name
				}
			}
		}
	}

	if s.subflagRepo != nil {
		subflagIDs := collectIDs(routines, func(r domain.Routine) *string { return r.SubflagID })
		if len(subflagIDs) > 0 {
			subflags, err := s.subflagRepo.GetByIDs(ctx, userID, subflagIDs)
			if err != nil {
				s.log.Warn("digest_subflag_lookup_failed", slog.String("user_id", userID), slog.String("error", err.Error()))
			} else {
				for _, subflag := range subflags {
					subflagNames[subflag.ID] = subflag.Name
				}
			}
		}
	}

	return flagNames, subflagNames
}

func collectIDs(routines []domain.Routine, selector func(domain.Routine) *string) []string {
	unique := make(map[string]struct{})
	ids := make([]string, 0)
	for _, routine := range routines {
		id := strings.TrimSpace(derefString(selector(routine)))
		if id == "" {
			continue
		}
		if _, ok := unique[id]; ok {
			continue
		}
		unique[id] = struct{}{}
		ids = append(ids, id)
	}
	return ids
}

func routineTimeLabel(startTime, endTime string) string {
	start := normalizeClock(startTime)
	end := normalizeClock(endTime)

	switch {
	case start == "" && end == "":
		return "Dia todo"
	case start == "":
		return end
	case end == "" || end == start:
		return start
	default:
		return fmt.Sprintf("%s - %s", start, end)
	}
}

func normalizeClock(raw string) string {
	value := strings.TrimSpace(raw)
	if value == "" {
		return ""
	}

	parts := strings.Split(value, ":")
	if len(parts) < 2 {
		return value
	}

	hour, errHour := strconv.Atoi(parts[0])
	minute, errMinute := strconv.Atoi(parts[1])
	if errHour != nil || errMinute != nil {
		return value
	}

	return fmt.Sprintf("%02d:%02d", hour, minute)
}

func routineRecurrenceLabel(recurrenceType string) string {
	switch recurrenceType {
	case "", "weekly":
		return "Semanal"
	case "biweekly":
		return "Quinzenal"
	case "triweekly":
		return "A cada 3 semanas"
	case "monthly_week":
		return "Mensal"
	default:
		return recurrenceType
	}
}

func routineContextPath(flagID, subflagID *string, flagNames, subflagNames map[string]string) string {
	flag := strings.TrimSpace(flagNames[derefString(flagID)])
	subflag := strings.TrimSpace(subflagNames[derefString(subflagID)])

	switch {
	case flag != "" && subflag != "":
		return flag + " > " + subflag
	case flag != "":
		return flag
	case subflag != "":
		return subflag
	default:
		return ""
	}
}

func agendaType(itemType string) (string, string) {
	switch itemType {
	case "event":
		return "Evento", "event"
	case "task":
		return "Task", "task"
	case "reminder":
		return "Lembrete", "reminder"
	default:
		return "Item", "item"
	}
}

func contextPath(flagName, subflagName *string) string {
	flag := strings.TrimSpace(derefString(flagName))
	subflag := strings.TrimSpace(derefString(subflagName))

	switch {
	case flag != "" && subflag != "":
		return flag + " > " + subflag
	case flag != "":
		return flag
	case subflag != "":
		return subflag
	default:
		return ""
	}
}

func agendaTimeLabel(item repository.AgendaItem, scheduledAt time.Time) string {
	if item.ItemType == "event" && item.AllDay != nil && *item.AllDay {
		return "Dia inteiro"
	}
	if item.ItemType == "event" && item.EndAt != nil {
		endAt := item.EndAt.In(scheduledAt.Location())
		start := scheduledAt.Format("15:04")
		end := endAt.Format("15:04")
		if start != end {
			return fmt.Sprintf("%s - %s", start, end)
		}
	}
	return scheduledAt.Format("15:04")
}

func shoppingItemLabel(item domain.ShoppingItem) string {
	title := strings.TrimSpace(item.Title)
	if item.Quantity != nil {
		qty := strings.TrimSpace(*item.Quantity)
		if qty != "" {
			return fmt.Sprintf("%s (%s)", title, qty)
		}
	}
	return title
}

func derefString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func (s *DigestService) ProcessPendingDigests(ctx context.Context) error {
	prefs, err := s.notifPrefsRepo.ListEnabled(ctx)
	if err != nil {
		return err
	}

	nowUTC := s.now().UTC()

	for _, p := range prefs {
		if p.DailyDigestHour < 0 || p.DailyDigestHour > 23 {
			s.log.Warn("invalid_daily_digest_hour", slog.String("user_id", p.UserID), slog.Int("hour", p.DailyDigestHour))
			continue
		}

		user, err := s.userRepo.Get(ctx, p.UserID)
		if err != nil {
			s.log.Error("digest_user_load_failed", slog.String("user_id", p.UserID), slog.String("error", err.Error()))
			continue
		}

		tz, err := time.LoadLocation(user.Timezone)
		if err != nil {
			s.log.Warn("digest_invalid_user_timezone", slog.String("user_id", user.ID), slog.String("timezone", user.Timezone))
			tz = time.UTC
		}

		userNow := nowUTC.In(tz)
		if userNow.Hour() < p.DailyDigestHour {
			continue
		}

		if err := s.SendDigest(ctx, user, userNow); err != nil {
			s.log.Error("digest_send_failed", slog.String("user_id", user.ID), slog.String("error", err.Error()))
		}
	}

	return nil
}

func (s *DigestService) SendDigest(ctx context.Context, user domain.User, date time.Time) error {
	return s.sendDigest(ctx, user, date, true)
}

func (s *DigestService) SendTestDigest(ctx context.Context, user domain.User, date time.Time) error {
	return s.sendDigest(ctx, user, date, false)
}

func (s *DigestService) SendTestDigestForUserID(ctx context.Context, userID string) error {
	if strings.TrimSpace(userID) == "" {
		return fmt.Errorf("user id is empty")
	}

	user, err := s.userRepo.Get(ctx, userID)
	if err != nil {
		return err
	}

	tz, err := time.LoadLocation(user.Timezone)
	if err != nil {
		tz = time.UTC
	}

	return s.SendTestDigest(ctx, user, s.now().In(tz))
}

func (s *DigestService) sendDigest(ctx context.Context, user domain.User, date time.Time, trackDelivery bool) error {
	email := strings.TrimSpace(user.Email)
	if email == "" {
		return fmt.Errorf("user email is empty")
	}
	if date.IsZero() {
		date = s.now()
	}

	var digestRecord *domain.EmailDigest
	if trackDelivery {
		digestRecord = &domain.EmailDigest{
			UserID:     user.ID,
			DigestDate: date,
			Type:       digestTypeDaily,
			Status:     domain.EmailDigestStatusPending,
		}

		created, err := s.emailDigestRepo.Create(ctx, digestRecord)
		if err != nil {
			return err
		}
		if !created {
			return nil
		}
	}

	data, err := s.BuildDigestData(ctx, user.ID, date)
	if err != nil {
		return s.failDigest(ctx, digestRecord, err)
	}

	htmlBody, textBody, err := s.renderDigest(data)
	if err != nil {
		return s.failDigest(ctx, digestRecord, err)
	}

	msgID, err := s.mailer.Send(ctx, mailer.SendRequest{
		To:      []string{email},
		Subject: buildDigestSubject(date),
		Html:    htmlBody,
		Text:    textBody,
	})
	if err != nil {
		return s.failDigest(ctx, digestRecord, err)
	}

	if digestRecord == nil {
		return nil
	}

	sentAt := s.now().UTC()
	digestRecord.Status = domain.EmailDigestStatusSuccess
	digestRecord.SentAt = &sentAt
	digestRecord.ProviderID = &msgID
	return s.emailDigestRepo.Update(ctx, digestRecord)
}

func (s *DigestService) renderDigest(data DigestData) (string, string, error) {
	var html bytes.Buffer
	if err := s.htmlTemplate.Execute(&html, data); err != nil {
		return "", "", fmt.Errorf("render digest html: %w", err)
	}

	var text bytes.Buffer
	if err := s.textTemplate.Execute(&text, data); err != nil {
		return "", "", fmt.Errorf("render digest text: %w", err)
	}

	return html.String(), text.String(), nil
}

func (s *DigestService) failDigest(ctx context.Context, digestRecord *domain.EmailDigest, cause error) error {
	if digestRecord == nil {
		return cause
	}

	digestRecord.Status = domain.EmailDigestStatusFailed
	msg := cause.Error()
	digestRecord.ErrorMsg = &msg

	if err := s.emailDigestRepo.Update(ctx, digestRecord); err != nil {
		return fmt.Errorf("%w (and failed to persist digest error: %v)", cause, err)
	}
	return cause
}

func (s *DigestService) listAllTasks(ctx context.Context, userID string) ([]domain.Task, error) {
	cursor := ""
	all := make([]domain.Task, 0)

	for {
		items, next, err := s.taskRepo.List(ctx, userID, repository.ListOptions{Limit: maxDigestPageSize, Cursor: cursor})
		if err != nil {
			return nil, err
		}
		all = append(all, items...)

		if next == nil || *next == "" {
			return all, nil
		}
		cursor = *next
	}
}

func (s *DigestService) listAllShoppingLists(ctx context.Context, userID string) ([]domain.ShoppingList, error) {
	cursor := ""
	all := make([]domain.ShoppingList, 0)

	for {
		items, next, err := s.shoppingListRepo.List(ctx, userID, repository.ListOptions{Limit: maxDigestPageSize, Cursor: cursor})
		if err != nil {
			return nil, err
		}
		all = append(all, items...)

		if next == nil || *next == "" {
			return all, nil
		}
		cursor = *next
	}
}

func (s *DigestService) listAllShoppingItems(ctx context.Context, userID, listID string) ([]domain.ShoppingItem, error) {
	cursor := ""
	all := make([]domain.ShoppingItem, 0)

	for {
		items, next, err := s.shoppingItemRepo.ListByList(ctx, userID, listID, repository.ListOptions{Limit: maxDigestPageSize, Cursor: cursor})
		if err != nil {
			return nil, err
		}
		all = append(all, items...)

		if next == nil || *next == "" {
			return all, nil
		}
		cursor = *next
	}
}

func buildDigestSubject(date time.Time) string {
	if date.IsZero() {
		return defaultDigestSubject
	}
	return fmt.Sprintf("%s — %s (%s)", defaultDigestSubject, date.Format("02/01"), weekdayPTBR(date.Weekday()))
}

func weekdayPTBR(w time.Weekday) string {
	switch w {
	case time.Monday:
		return "Segunda"
	case time.Tuesday:
		return "Terça"
	case time.Wednesday:
		return "Quarta"
	case time.Thursday:
		return "Quinta"
	case time.Friday:
		return "Sexta"
	case time.Saturday:
		return "Sábado"
	case time.Sunday:
		return "Domingo"
	default:
		return ""
	}
}
