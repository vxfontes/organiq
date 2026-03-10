package digest

import (
	"context"
	"fmt"
	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/infra/mailer"
	"testing"
	"time"
)

type fakeUserRepo struct {
	users map[string]domain.User
}

func (f *fakeUserRepo) Create(ctx context.Context, user domain.User) (domain.User, error) {
	return domain.User{}, fmt.Errorf("not implemented")
}

func (f *fakeUserRepo) Get(ctx context.Context, id string) (domain.User, error) {
	user, ok := f.users[id]
	if !ok {
		return domain.User{}, fmt.Errorf("not found")
	}
	return user, nil
}

func (f *fakeUserRepo) FindByEmail(ctx context.Context, email string) (domain.User, error) {
	return domain.User{}, fmt.Errorf("not implemented")
}

type fakePrefsRepo struct {
	prefs []domain.NotificationPreferences
}

func (f *fakePrefsRepo) GetByUserID(ctx context.Context, userID string) (domain.NotificationPreferences, error) {
	return domain.NotificationPreferences{}, fmt.Errorf("not implemented")
}

func (f *fakePrefsRepo) Upsert(ctx context.Context, prefs domain.NotificationPreferences) error {
	return fmt.Errorf("not implemented")
}

func (f *fakePrefsRepo) ListEnabled(ctx context.Context) ([]domain.NotificationPreferences, error) {
	return f.prefs, nil
}

func (f *fakePrefsRepo) GetDailySummaryTokenByUserID(ctx context.Context, userID string) (string, error) {
	return "", fmt.Errorf("not implemented")
}

func (f *fakePrefsRepo) RotateDailySummaryToken(ctx context.Context, userID string) (string, error) {
	return "", fmt.Errorf("not implemented")
}

func (f *fakePrefsRepo) FindUserIDByDailySummaryToken(ctx context.Context, token string) (string, error) {
	return "", fmt.Errorf("not implemented")
}

type fakeEmailDigestRepo struct {
	createResult bool
	createCalls  int
	updateCalls  int
	lastUpdated  *domain.EmailDigest
}

func (f *fakeEmailDigestRepo) Create(ctx context.Context, digest *domain.EmailDigest) (bool, error) {
	f.createCalls++
	if f.createResult {
		digest.ID = "digest-id"
	}
	return f.createResult, nil
}

func (f *fakeEmailDigestRepo) Update(ctx context.Context, digest *domain.EmailDigest) error {
	f.updateCalls++
	copy := *digest
	f.lastUpdated = &copy
	return nil
}

type fakeAgendaRepo struct {
	items []repository.AgendaItem
}

func (f *fakeAgendaRepo) List(ctx context.Context, userID string, opts repository.ListOptions) ([]repository.AgendaItem, error) {
	return f.items, nil
}

type fakeRoutineLister struct {
	items       []domain.Routine
	callCount   int
	lastWeekday int
	lastDate    string
}

func (f *fakeRoutineLister) ListByWeekday(ctx context.Context, userID string, weekday int, date string) ([]domain.Routine, error) {
	f.callCount++
	f.lastWeekday = weekday
	f.lastDate = date
	return f.items, nil
}

type fakeTaskRepo struct {
	items []domain.Task
}

func (f *fakeTaskRepo) Create(ctx context.Context, task domain.Task) (domain.Task, error) {
	return domain.Task{}, fmt.Errorf("not implemented")
}

func (f *fakeTaskRepo) Update(ctx context.Context, task domain.Task) (domain.Task, error) {
	return domain.Task{}, fmt.Errorf("not implemented")
}

func (f *fakeTaskRepo) Delete(ctx context.Context, userID, id string) error {
	return fmt.Errorf("not implemented")
}

func (f *fakeTaskRepo) Get(ctx context.Context, userID, id string) (domain.Task, error) {
	return domain.Task{}, fmt.Errorf("not implemented")
}

func (f *fakeTaskRepo) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Task, *string, error) {
	return f.items, nil, nil
}

func (f *fakeTaskRepo) ListUpcoming(ctx context.Context, start, end time.Time) ([]domain.Task, error) {
	return nil, fmt.Errorf("not implemented")
}

type fakeShoppingListRepo struct {
	items []domain.ShoppingList
}

func (f *fakeShoppingListRepo) Create(ctx context.Context, list domain.ShoppingList) (domain.ShoppingList, error) {
	return domain.ShoppingList{}, fmt.Errorf("not implemented")
}

func (f *fakeShoppingListRepo) Update(ctx context.Context, list domain.ShoppingList) (domain.ShoppingList, error) {
	return domain.ShoppingList{}, fmt.Errorf("not implemented")
}

func (f *fakeShoppingListRepo) Delete(ctx context.Context, userID, id string) error {
	return fmt.Errorf("not implemented")
}

func (f *fakeShoppingListRepo) Get(ctx context.Context, userID, id string) (domain.ShoppingList, error) {
	return domain.ShoppingList{}, fmt.Errorf("not implemented")
}

func (f *fakeShoppingListRepo) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.ShoppingList, *string, error) {
	return f.items, nil, nil
}

type fakeShoppingItemRepo struct {
	itemsByList map[string][]domain.ShoppingItem
}

func (f *fakeShoppingItemRepo) Create(ctx context.Context, item domain.ShoppingItem) (domain.ShoppingItem, error) {
	return domain.ShoppingItem{}, fmt.Errorf("not implemented")
}

func (f *fakeShoppingItemRepo) Update(ctx context.Context, item domain.ShoppingItem) (domain.ShoppingItem, error) {
	return domain.ShoppingItem{}, fmt.Errorf("not implemented")
}

func (f *fakeShoppingItemRepo) Delete(ctx context.Context, userID, id string) error {
	return fmt.Errorf("not implemented")
}

func (f *fakeShoppingItemRepo) Get(ctx context.Context, userID, id string) (domain.ShoppingItem, error) {
	return domain.ShoppingItem{}, fmt.Errorf("not implemented")
}

func (f *fakeShoppingItemRepo) ListByList(ctx context.Context, userID, listID string, opts repository.ListOptions) ([]domain.ShoppingItem, *string, error) {
	return f.itemsByList[listID], nil, nil
}

type fakeMailer struct {
	sendCalls int
}

func (f *fakeMailer) Send(ctx context.Context, req mailer.SendRequest) (string, error) {
	f.sendCalls++
	return "message-id", nil
}

func TestBuildDigestData(t *testing.T) {
	loc := time.FixedZone("BRT", -3*3600)
	target := time.Date(2026, 3, 9, 4, 0, 0, 0, loc)
	routines := &fakeRoutineLister{items: []domain.Routine{
		{Title: "Treino", StartTime: "06:30", EndTime: "07:30", RecurrenceType: "weekly"},
		{Title: "Planejamento", StartTime: "19:00", EndTime: "19:30", RecurrenceType: "biweekly"},
	}}

	agenda := &fakeAgendaRepo{items: []repository.AgendaItem{
		{
			ItemType:    "event",
			Title:       "Reunião",
			ScheduledAt: time.Date(2026, 3, 9, 10, 0, 0, 0, loc),
			EndAt:       ptrTime(time.Date(2026, 3, 9, 11, 30, 0, 0, loc)),
		},
		{ItemType: "reminder", Title: "Tomar água", ScheduledAt: time.Date(2026, 3, 9, 9, 0, 0, 0, loc)},
		{ItemType: "event", Title: "Ontem", ScheduledAt: time.Date(2026, 3, 8, 22, 0, 0, 0, loc)},
	}}

	tasks := &fakeTaskRepo{items: []domain.Task{
		{Title: "Sem data", Status: domain.TaskStatusOpen},
		{Title: "Com due hoje", Status: domain.TaskStatusOpen, DueAt: ptrTime(time.Date(2026, 3, 9, 11, 0, 0, 0, loc))},
		{Title: "Concluída", Status: domain.TaskStatusDone, DueAt: ptrTime(time.Date(2026, 3, 9, 12, 0, 0, 0, loc))},
	}}

	listID := "list-open"
	lists := &fakeShoppingListRepo{items: []domain.ShoppingList{
		{ID: listID, Title: "Mercado", Status: domain.ShoppingListStatusOpen},
		{ID: "list-done", Title: "Finalizada", Status: domain.ShoppingListStatusDone},
	}}
	items := &fakeShoppingItemRepo{itemsByList: map[string][]domain.ShoppingItem{
		listID: []domain.ShoppingItem{
			{Title: "Arroz", Checked: false},
			{Title: "Feijão", Checked: true},
		},
	}}

	svc, err := NewDigestService(
		&fakeUserRepo{},
		&fakePrefsRepo{},
		&fakeEmailDigestRepo{},
		routines,
		agenda,
		tasks,
		lists,
		items,
		nil,
		nil,
		&fakeMailer{},
	)
	if err != nil {
		t.Fatalf("new digest service: %v", err)
	}

	data, err := svc.BuildDigestData(context.Background(), "u1", target)
	if err != nil {
		t.Fatalf("build digest data: %v", err)
	}

	if !data.HasAgenda || len(data.Agenda) != 2 {
		t.Fatalf("expected agenda with 2 items, got hasAgenda=%v len=%d", data.HasAgenda, len(data.Agenda))
	}
	if !data.HasSchedule || len(data.Schedule) != 2 {
		t.Fatalf("expected schedule with 2 routines, got hasSchedule=%v len=%d", data.HasSchedule, len(data.Schedule))
	}
	if routines.callCount != 1 || routines.lastWeekday != 1 || routines.lastDate != "2026-03-09" {
		t.Fatalf("expected routines fetched for weekday/date target, got calls=%d weekday=%d date=%s", routines.callCount, routines.lastWeekday, routines.lastDate)
	}
	if data.Schedule[0].Recurrence == "" || data.Schedule[1].Recurrence == "" {
		t.Fatalf("expected recurrence labels in schedule items, got %+v", data.Schedule)
	}
	if data.Agenda[0].Type == "" || data.Agenda[1].Type == "" {
		t.Fatalf("expected agenda items with type labels, got %+v", data.Agenda)
	}
	if data.Agenda[0].Time != "10:00 - 11:30" {
		t.Fatalf("expected event range time in agenda, got %q", data.Agenda[0].Time)
	}
	if !data.HasReminders || len(data.Reminders) != 1 {
		t.Fatalf("expected 1 reminder, got hasReminders=%v len=%d", data.HasReminders, len(data.Reminders))
	}
	if !data.HasTasks || len(data.Tasks) != 1 {
		t.Fatalf("expected 1 due task, got hasTasks=%v len=%d", data.HasTasks, len(data.Tasks))
	}
	if !data.HasOpenTasks || len(data.OpenTasks) != 1 {
		t.Fatalf("expected 1 open task, got hasOpenTasks=%v len=%d", data.HasOpenTasks, len(data.OpenTasks))
	}
	if !data.HasShoppingLists || len(data.ShoppingLists) != 1 || data.ShoppingLists[0].PendingCount != 1 {
		t.Fatalf("expected 1 shopping list with 1 pending item, got %+v", data.ShoppingLists)
	}
	if len(data.ShoppingLists[0].PendingItems) != 1 {
		t.Fatalf("expected pending items listed, got %+v", data.ShoppingLists[0].PendingItems)
	}
}

func TestSendDigestSkipsWhenAlreadyReserved(t *testing.T) {
	mail := &fakeMailer{}
	digests := &fakeEmailDigestRepo{createResult: false}

	svc, err := NewDigestService(
		&fakeUserRepo{},
		&fakePrefsRepo{},
		digests,
		&fakeRoutineLister{},
		&fakeAgendaRepo{},
		&fakeTaskRepo{},
		&fakeShoppingListRepo{},
		&fakeShoppingItemRepo{itemsByList: map[string][]domain.ShoppingItem{}},
		nil,
		nil,
		mail,
	)
	if err != nil {
		t.Fatalf("new digest service: %v", err)
	}

	err = svc.SendDigest(context.Background(), domain.User{ID: "u1", Email: "u1@example.com"}, time.Now())
	if err != nil {
		t.Fatalf("send digest: %v", err)
	}
	if mail.sendCalls != 0 {
		t.Fatalf("expected no e-mail send when digest already exists, got %d", mail.sendCalls)
	}
	if digests.createCalls != 1 {
		t.Fatalf("expected one create call, got %d", digests.createCalls)
	}
}

func TestSendTestDigestBypassesTracking(t *testing.T) {
	mail := &fakeMailer{}
	digests := &fakeEmailDigestRepo{createResult: false}

	svc, err := NewDigestService(
		&fakeUserRepo{},
		&fakePrefsRepo{},
		digests,
		&fakeRoutineLister{},
		&fakeAgendaRepo{},
		&fakeTaskRepo{},
		&fakeShoppingListRepo{},
		&fakeShoppingItemRepo{itemsByList: map[string][]domain.ShoppingItem{}},
		nil,
		nil,
		mail,
	)
	if err != nil {
		t.Fatalf("new digest service: %v", err)
	}

	err = svc.SendTestDigest(context.Background(), domain.User{ID: "u1", Email: "u1@example.com"}, time.Now())
	if err != nil {
		t.Fatalf("send test digest: %v", err)
	}
	if digests.createCalls != 0 {
		t.Fatalf("expected no digest tracking in test send, got %d create calls", digests.createCalls)
	}
	if mail.sendCalls != 1 {
		t.Fatalf("expected one test e-mail send, got %d", mail.sendCalls)
	}
}

func TestProcessPendingDigestsRespectsHour(t *testing.T) {
	mail := &fakeMailer{}
	digests := &fakeEmailDigestRepo{createResult: true}
	prefs := &fakePrefsRepo{prefs: []domain.NotificationPreferences{
		{UserID: "u-due", DailyDigestEnabled: true, DailyDigestHour: 4},
		{UserID: "u-late", DailyDigestEnabled: true, DailyDigestHour: 8},
	}}
	users := &fakeUserRepo{users: map[string]domain.User{
		"u-due":  {ID: "u-due", Email: "due@example.com", Timezone: "America/Sao_Paulo"},
		"u-late": {ID: "u-late", Email: "late@example.com", Timezone: "America/Sao_Paulo"},
	}}

	svc, err := NewDigestService(
		users,
		prefs,
		digests,
		&fakeRoutineLister{},
		&fakeAgendaRepo{},
		&fakeTaskRepo{},
		&fakeShoppingListRepo{},
		&fakeShoppingItemRepo{itemsByList: map[string][]domain.ShoppingItem{}},
		nil,
		nil,
		mail,
	)
	if err != nil {
		t.Fatalf("new digest service: %v", err)
	}

	svc.SetNow(func() time.Time {
		return time.Date(2026, 3, 9, 9, 0, 0, 0, time.UTC) // 06:00 em America/Sao_Paulo
	})

	err = svc.ProcessPendingDigests(context.Background())
	if err != nil {
		t.Fatalf("process pending digests: %v", err)
	}

	if mail.sendCalls != 1 {
		t.Fatalf("expected only one digest send, got %d", mail.sendCalls)
	}
	if digests.updateCalls != 1 || digests.lastUpdated == nil || digests.lastUpdated.Status != domain.EmailDigestStatusSuccess {
		t.Fatalf("expected successful digest update, got updateCalls=%d status=%v", digests.updateCalls, digests.lastUpdated)
	}
}

func ptrTime(t time.Time) *time.Time {
	return &t
}
