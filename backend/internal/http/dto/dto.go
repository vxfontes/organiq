package dto

import (
	"encoding/json"
	"time"
)

// Common responses.
type ErrorResponse struct {
	Error     string `json:"error"`
	RequestID string `json:"requestId,omitempty"`
}

// Auth

type AuthRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"displayName"`
	Locale      string `json:"locale"`
	Timezone    string `json:"timezone"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token string `json:"token"`
	User  struct {
		ID          string `json:"id"`
		Email       string `json:"email"`
		DisplayName string `json:"displayName"`
		Locale      string `json:"locale"`
		Timezone    string `json:"timezone"`
	} `json:"user"`
}

// Flags

type FlagResponse struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Color     *string   `json:"color,omitempty"`
	SortOrder int       `json:"sortOrder"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

type FlagObject struct {
	ID    string  `json:"id"`
	Name  string  `json:"name"`
	Color *string `json:"color,omitempty"`
}

type ListFlagsResponse struct {
	Items      []FlagResponse `json:"items"`
	NextCursor *string        `json:"nextCursor,omitempty"`
}

type CreateFlagRequest struct {
	Name      string  `json:"name"`
	Color     *string `json:"color,omitempty"`
	SortOrder *int    `json:"sortOrder,omitempty"`
}

type UpdateFlagRequest struct {
	Name      *string `json:"name,omitempty"`
	Color     *string `json:"color,omitempty"`
	SortOrder *int    `json:"sortOrder,omitempty"`
}

// Subflags

type SubflagResponse struct {
	ID        string      `json:"id"`
	Flag      *FlagObject `json:"flag,omitempty"`
	Name      string      `json:"name"`
	Color     *string     `json:"color,omitempty"`
	SortOrder int         `json:"sortOrder"`
	CreatedAt time.Time   `json:"createdAt"`
	UpdatedAt time.Time   `json:"updatedAt"`
}

type SubflagObject struct {
	ID    string  `json:"id"`
	Name  string  `json:"name"`
	Color *string `json:"color,omitempty"`
}

type ListSubflagsResponse struct {
	Items      []SubflagResponse `json:"items"`
	NextCursor *string           `json:"nextCursor,omitempty"`
}

type CreateSubflagRequest struct {
	Name      string `json:"name"`
	SortOrder *int   `json:"sortOrder,omitempty"`
}

type UpdateSubflagRequest struct {
	Name      *string `json:"name,omitempty"`
	SortOrder *int    `json:"sortOrder,omitempty"`
}

// Context rules

type ContextRuleResponse struct {
	ID        string         `json:"id"`
	Keyword   string         `json:"keyword"`
	Flag      *FlagObject    `json:"flag,omitempty"`
	Subflag   *SubflagObject `json:"subflag,omitempty"`
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
}

type ListContextRulesResponse struct {
	Items      []ContextRuleResponse `json:"items"`
	NextCursor *string               `json:"nextCursor,omitempty"`
}

type CreateContextRuleRequest struct {
	Keyword   string  `json:"keyword"`
	FlagID    string  `json:"flagId"`
	SubflagID *string `json:"subflagId,omitempty"`
}

type UpdateContextRuleRequest struct {
	Keyword   *string `json:"keyword,omitempty"`
	FlagID    *string `json:"flagId,omitempty"`
	SubflagID *string `json:"subflagId,omitempty"`
}

// Inbox

type AiSuggestionResponse struct {
	ID          string          `json:"id"`
	Type        string          `json:"type"`
	Title       string          `json:"title"`
	Confidence  *float64        `json:"confidence,omitempty"`
	Flag        *FlagObject     `json:"flag,omitempty"`
	Subflag     *SubflagObject  `json:"subflag,omitempty"`
	NeedsReview bool            `json:"needsReview"`
	Payload     json.RawMessage `json:"payload" swaggertype:"object"`
	CreatedAt   time.Time       `json:"createdAt"`
}

type InboxItemResponse struct {
	ID          string                `json:"id"`
	Source      string                `json:"source"`
	RawText     string                `json:"rawText"`
	RawMediaURL *string               `json:"rawMediaUrl,omitempty"`
	Status      string                `json:"status"`
	LastError   *string               `json:"lastError,omitempty"`
	CreatedAt   time.Time             `json:"createdAt"`
	UpdatedAt   time.Time             `json:"updatedAt"`
	Suggestion  *AiSuggestionResponse `json:"suggestion,omitempty"`
}

type ListInboxItemsResponse struct {
	Items      []InboxItemResponse `json:"items"`
	NextCursor *string             `json:"nextCursor,omitempty"`
}

type CreateInboxItemRequest struct {
	Source      string  `json:"source,omitempty"`
	RawText     string  `json:"rawText"`
	RawMediaURL *string `json:"rawMediaUrl,omitempty"`
}

type ConfirmInboxItemRequest struct {
	Type      string          `json:"type"`
	Title     string          `json:"title"`
	FlagID    *string         `json:"flagId,omitempty"`
	SubflagID *string         `json:"subflagId,omitempty"`
	Payload   json.RawMessage `json:"payload" swaggertype:"object"`
}

type ConfirmInboxItemResponse struct {
	Type          string                 `json:"type"`
	Task          *TaskResponse          `json:"task,omitempty"`
	Reminder      *ReminderResponse      `json:"reminder,omitempty"`
	Event         *EventResponse         `json:"event,omitempty"`
	ShoppingList  *ShoppingListResponse  `json:"shoppingList,omitempty"`
	ShoppingItems []ShoppingItemResponse `json:"shoppingItems,omitempty"`
	Routine       *RoutineResponse       `json:"routine,omitempty"`
}

// Tasks

type TaskResponse struct {
	ID              string           `json:"id"`
	Title           string           `json:"title"`
	Description     *string          `json:"description,omitempty"`
	Status          string           `json:"status"`
	DueAt           *time.Time       `json:"dueAt,omitempty"`
	Flag            *FlagObject      `json:"flag,omitempty"`
	Subflag         *SubflagObject   `json:"subflag,omitempty"`
	SourceInboxItem *InboxItemObject `json:"sourceInboxItem,omitempty"`
	CreatedAt       time.Time        `json:"createdAt"`
	UpdatedAt       time.Time        `json:"updatedAt"`
}

type ListTasksResponse struct {
	Items      []TaskResponse `json:"items"`
	NextCursor *string        `json:"nextCursor,omitempty"`
}

type CreateTaskRequest struct {
	Title       string     `json:"title"`
	Description *string    `json:"description,omitempty"`
	Status      *string    `json:"status,omitempty"`
	DueAt       *time.Time `json:"dueAt,omitempty"`
	FlagID      *string    `json:"flagId,omitempty"`
	SubflagID   *string    `json:"subflagId,omitempty"`
}

type UpdateTaskRequest struct {
	Title       *string    `json:"title,omitempty"`
	Description *string    `json:"description,omitempty"`
	Status      *string    `json:"status,omitempty"`
	DueAt       *time.Time `json:"dueAt,omitempty"`
	FlagID      *string    `json:"flagId,omitempty"`
	SubflagID   *string    `json:"subflagId,omitempty"`
}

// Reminders

type ReminderResponse struct {
	ID              string           `json:"id"`
	Title           string           `json:"title"`
	Status          string           `json:"status"`
	RemindAt        *time.Time       `json:"remindAt,omitempty"`
	Flag            *FlagObject      `json:"flag,omitempty"`
	Subflag         *SubflagObject   `json:"subflag,omitempty"`
	SourceInboxItem *InboxItemObject `json:"sourceInboxItem,omitempty"`
	CreatedAt       time.Time        `json:"createdAt"`
	UpdatedAt       time.Time        `json:"updatedAt"`
}

type ListRemindersResponse struct {
	Items      []ReminderResponse `json:"items"`
	NextCursor *string            `json:"nextCursor,omitempty"`
}

type CreateReminderRequest struct {
	Title     string     `json:"title"`
	Status    *string    `json:"status,omitempty"`
	RemindAt  *time.Time `json:"remindAt,omitempty"`
	FlagID    *string    `json:"flagId,omitempty"`
	SubflagID *string    `json:"subflagId,omitempty"`
}

type UpdateReminderRequest struct {
	Title     *string    `json:"title,omitempty"`
	Status    *string    `json:"status,omitempty"`
	RemindAt  *time.Time `json:"remindAt,omitempty"`
	FlagID    *string    `json:"flagId,omitempty"`
	SubflagID *string    `json:"subflagId,omitempty"`
}

// Events

type EventResponse struct {
	ID              string           `json:"id"`
	Title           string           `json:"title"`
	StartAt         *time.Time       `json:"startAt,omitempty"`
	EndAt           *time.Time       `json:"endAt,omitempty"`
	AllDay          bool             `json:"allDay"`
	Location        *string          `json:"location,omitempty"`
	Flag            *FlagObject      `json:"flag,omitempty"`
	Subflag         *SubflagObject   `json:"subflag,omitempty"`
	SourceInboxItem *InboxItemObject `json:"sourceInboxItem,omitempty"`
	CreatedAt       time.Time        `json:"createdAt"`
	UpdatedAt       time.Time        `json:"updatedAt"`
}

type ListEventsResponse struct {
	Items      []EventResponse `json:"items"`
	NextCursor *string         `json:"nextCursor,omitempty"`
}

type AgendaResponse struct {
	Events    []EventResponse    `json:"events"`
	Tasks     []TaskResponse     `json:"tasks"`
	Reminders []ReminderResponse `json:"reminders"`
}

// Home

type HomeDayProgressResponse struct {
	RoutinesDone    int     `json:"routines_done"`
	RoutinesTotal   int     `json:"routines_total"`
	TasksDone       int     `json:"tasks_done"`
	TasksTotal      int     `json:"tasks_total"`
	ProgressPercent float64 `json:"progress_percent"`
}

type HomeInsightResponse struct {
	Title   string `json:"title"`
	Summary string `json:"summary"`
	Footer  string `json:"footer"`
	IsFocus bool   `json:"is_focus"`
}

type HomeTimelineItemResponse struct {
	ID               string     `json:"id"`
	ItemType         string     `json:"item_type"`
	Title            string     `json:"title"`
	Subtitle         *string    `json:"subtitle,omitempty"`
	ScheduledTime    time.Time  `json:"scheduled_time"`
	EndScheduledTime *time.Time `json:"end_scheduled_time,omitempty"`
	IsCompleted      bool       `json:"is_completed"`
	IsOverdue        bool       `json:"is_overdue"`
}

type HomeShoppingPreviewResponse struct {
	ID           string   `json:"id"`
	Title        string   `json:"title"`
	TotalItems   int      `json:"total_items"`
	PendingItems int      `json:"pending_items"`
	PreviewItems []string `json:"preview_items"`
}

type HomeDashboardResponse struct {
	DayProgress         HomeDayProgressResponse       `json:"day_progress"`
	Insight             *HomeInsightResponse          `json:"insight,omitempty"`
	Timeline            []HomeTimelineItemResponse    `json:"timeline"`
	ShoppingPreview     []HomeShoppingPreviewResponse `json:"shopping_preview"`
	WeekDensity         map[string]int                `json:"week_density"`
	FocusTasks          []TaskResponse                `json:"focus_tasks,omitempty"`
	EventsTodayCount    int                           `json:"events_today_count"`
	RemindersTodayCount int                           `json:"reminders_today_count"`
}

type CreateEventRequest struct {
	Title     string     `json:"title"`
	StartAt   *time.Time `json:"startAt,omitempty"`
	EndAt     *time.Time `json:"endAt,omitempty"`
	AllDay    *bool      `json:"allDay,omitempty"`
	Location  *string    `json:"location,omitempty"`
	FlagID    *string    `json:"flagId,omitempty"`
	SubflagID *string    `json:"subflagId,omitempty"`
}

type UpdateEventRequest struct {
	Title     *string    `json:"title,omitempty"`
	StartAt   *time.Time `json:"startAt,omitempty"`
	EndAt     *time.Time `json:"endAt,omitempty"`
	AllDay    *bool      `json:"allDay,omitempty"`
	Location  *string    `json:"location,omitempty"`
	FlagID    *string    `json:"flagId,omitempty"`
	SubflagID *string    `json:"subflagId,omitempty"`
}

// Shopping

type ShoppingListResponse struct {
	ID              string           `json:"id"`
	Title           string           `json:"title"`
	Status          string           `json:"status"`
	SourceInboxItem *InboxItemObject `json:"sourceInboxItem,omitempty"`
	CreatedAt       time.Time        `json:"createdAt"`
	UpdatedAt       time.Time        `json:"updatedAt"`
}

type ShoppingListObject struct {
	ID     string `json:"id"`
	Title  string `json:"title"`
	Status string `json:"status"`
}

type ListShoppingListsResponse struct {
	Items      []ShoppingListResponse `json:"items"`
	NextCursor *string                `json:"nextCursor,omitempty"`
}

type CreateShoppingListRequest struct {
	Title  string  `json:"title"`
	Status *string `json:"status,omitempty"`
}

type UpdateShoppingListRequest struct {
	Title  *string `json:"title,omitempty"`
	Status *string `json:"status,omitempty"`
}

type ShoppingItemResponse struct {
	ID        string              `json:"id"`
	List      *ShoppingListObject `json:"list,omitempty"`
	Title     string              `json:"title"`
	Quantity  *string             `json:"quantity,omitempty"`
	Checked   bool                `json:"checked"`
	SortOrder int                 `json:"sortOrder"`
	CreatedAt time.Time           `json:"createdAt"`
	UpdatedAt time.Time           `json:"updatedAt"`
}

type InboxItemObject struct {
	ID          string    `json:"id"`
	Source      string    `json:"source"`
	RawText     string    `json:"rawText"`
	RawMediaURL *string   `json:"rawMediaUrl,omitempty"`
	Status      string    `json:"status"`
	LastError   *string   `json:"lastError,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

type ListShoppingItemsResponse struct {
	Items      []ShoppingItemResponse `json:"items"`
	NextCursor *string                `json:"nextCursor,omitempty"`
}

type CreateShoppingItemRequest struct {
	Title     string  `json:"title"`
	Quantity  *string `json:"quantity,omitempty"`
	Checked   *bool   `json:"checked,omitempty"`
	SortOrder *int    `json:"sortOrder,omitempty"`
}

type UpdateShoppingItemRequest struct {
	Title     *string `json:"title,omitempty"`
	Quantity  *string `json:"quantity,omitempty"`
	Checked   *bool   `json:"checked,omitempty"`
	SortOrder *int    `json:"sortOrder,omitempty"`
}

// Routines

type RoutineResponse struct {
	ID               string         `json:"id"`
	Title            string         `json:"title"`
	Description      *string        `json:"description,omitempty"`
	RecurrenceType   string         `json:"recurrenceType"`
	Weekdays         []int          `json:"weekdays"`
	StartTime        string         `json:"startTime"`
	EndTime          string         `json:"endTime"`
	WeekOfMonth      *int           `json:"weekOfMonth,omitempty"`
	StartsOn         string         `json:"startsOn"`
	EndsOn           *string        `json:"endsOn,omitempty"`
	Color            *string        `json:"color,omitempty"`
	IsActive         bool           `json:"isActive"`
	IsCompletedToday bool           `json:"isCompletedToday"`
	Flag             *FlagObject    `json:"flag,omitempty"`
	Subflag          *SubflagObject `json:"subflag,omitempty"`
	CreatedAt        time.Time      `json:"createdAt"`
	UpdatedAt        time.Time      `json:"updatedAt"`
}

type ListRoutinesResponse struct {
	Items      []RoutineResponse `json:"items"`
	NextCursor *string           `json:"nextCursor,omitempty"`
}

type CreateRoutineRequest struct {
	Title          string  `json:"title"`
	Description    *string `json:"description,omitempty"`
	RecurrenceType *string `json:"recurrenceType,omitempty"`
	Weekdays       []int   `json:"weekdays"`
	StartTime      string  `json:"startTime"`
	EndTime        string  `json:"endTime"`
	WeekOfMonth    *int    `json:"weekOfMonth,omitempty"`
	StartsOn       *string `json:"startsOn,omitempty"`
	EndsOn         *string `json:"endsOn,omitempty"`
	Color          *string `json:"color,omitempty"`
	FlagID         *string `json:"flagId,omitempty"`
	SubflagID      *string `json:"subflagId,omitempty"`
}

type UpdateRoutineRequest struct {
	Title          *string `json:"title,omitempty"`
	Description    *string `json:"description,omitempty"`
	RecurrenceType *string `json:"recurrenceType,omitempty"`
	Weekdays       *[]int  `json:"weekdays,omitempty"`
	StartTime      *string `json:"startTime,omitempty"`
	EndTime        *string `json:"endTime,omitempty"`
	WeekOfMonth    *int    `json:"weekOfMonth,omitempty"`
	StartsOn       *string `json:"startsOn,omitempty"`
	EndsOn         *string `json:"endsOn,omitempty"`
	Color          *string `json:"color,omitempty"`
	FlagID         *string `json:"flagId,omitempty"`
	SubflagID      *string `json:"subflagId,omitempty"`
}

type RoutineExceptionResponse struct {
	ID            string    `json:"id"`
	RoutineID     string    `json:"routineId"`
	ExceptionDate string    `json:"exceptionDate"`
	Action        string    `json:"action"`
	NewStartTime  *string   `json:"newStartTime,omitempty"`
	NewEndTime    *string   `json:"newEndTime,omitempty"`
	Reason        *string   `json:"reason,omitempty"`
	CreatedAt     time.Time `json:"createdAt"`
}

type RoutineCompletionResponse struct {
	ID          string    `json:"id"`
	RoutineID   string    `json:"routineId"`
	CompletedOn string    `json:"completedOn"`
	CompletedAt time.Time `json:"completedAt"`
}

type CreateRoutineExceptionRequest struct {
	ExceptionDate string  `json:"exceptionDate"`
	Action        *string `json:"action,omitempty"`
	NewStartTime  *string `json:"newStartTime,omitempty"`
	NewEndTime    *string `json:"newEndTime,omitempty"`
	Reason        *string `json:"reason,omitempty"`
}

type RoutineActivityDay struct {
	Date         string `json:"date"`
	IsCompleted  bool   `json:"isCompleted"`
	IsScheduled  bool   `json:"isScheduled"`
	IsToday      bool   `json:"isToday"`
	IsSkipped    bool   `json:"isSkipped"`
	WeekdayLabel string `json:"weekdayLabel"`
}

type RoutineStreakResponse struct {
	CurrentStreak    int                  `json:"currentStreak"`
	TotalCompletions int                  `json:"totalCompletions"`
	StreakText       string               `json:"streakText"`
	Activity         []RoutineActivityDay `json:"activity"`
}

type RoutineTodaySummaryResponse struct {
	Total     int `json:"total"`
	Completed int `json:"completed"`
}

type ToggleRoutineRequest struct {
	IsActive bool `json:"isActive"`
}

type CompleteRoutineRequest struct {
	Date string `json:"date,omitempty"`
}

// Devices

type RegisterTokenRequest struct {
	DeviceID   string  `json:"deviceId" binding:"required"`
	Platform   string  `json:"platform" binding:"required"` // ios | android
	DeviceName *string `json:"deviceName,omitempty"`
	AppVersion *string `json:"appVersion,omitempty"`
}

type RegisterTokenResponse struct {
	Topic string `json:"topic"`
}

type UnregisterTokenRequest struct {
	DeviceID string `json:"deviceId" binding:"required"`
}

// Notifications

type NotificationPreferencesResponse struct {
	RemindersEnabled   bool      `json:"remindersEnabled"`
	ReminderAtTime     bool      `json:"reminderAtTime"`
	ReminderLeadMins   []int     `json:"reminderLeadMins"`
	EventsEnabled      bool      `json:"eventsEnabled"`
	EventAtTime        bool      `json:"eventAtTime"`
	EventLeadMins      []int     `json:"eventLeadMins"`
	TasksEnabled       bool      `json:"tasksEnabled"`
	TaskAtTime         bool      `json:"taskAtTime"`
	TaskLeadMins       []int     `json:"taskLeadMins"`
	RoutinesEnabled    bool      `json:"routinesEnabled"`
	RoutineAtTime      bool      `json:"routineAtTime"`
	RoutineLeadMins    []int     `json:"routineLeadMins"`
	QuietHoursEnabled  bool      `json:"quietHoursEnabled"`
	QuietStart         *string   `json:"quietStart,omitempty"` // "HH:MM"
	QuietEnd           *string   `json:"quietEnd,omitempty"`   // "HH:MM"
	DailyDigestEnabled bool      `json:"dailyDigestEnabled"`
	DailyDigestHour    int       `json:"dailyDigestHour"`
	UpdatedAt          time.Time `json:"updatedAt"`
}

type DailySummaryTokenResponse struct {
	Token string `json:"token"`
	Url   string `json:"url"`
}

type UpdateNotificationPreferencesRequest struct {
	RemindersEnabled   *bool   `json:"remindersEnabled,omitempty"`
	ReminderAtTime     *bool   `json:"reminderAtTime,omitempty"`
	ReminderLeadMins   *[]int  `json:"reminderLeadMins,omitempty"`
	EventsEnabled      *bool   `json:"eventsEnabled,omitempty"`
	EventAtTime        *bool   `json:"eventAtTime,omitempty"`
	EventLeadMins      *[]int  `json:"eventLeadMins,omitempty"`
	TasksEnabled       *bool   `json:"tasksEnabled,omitempty"`
	TaskAtTime         *bool   `json:"taskAtTime,omitempty"`
	TaskLeadMins       *[]int  `json:"taskLeadMins,omitempty"`
	RoutinesEnabled    *bool   `json:"routinesEnabled,omitempty"`
	RoutineAtTime      *bool   `json:"routineAtTime,omitempty"`
	RoutineLeadMins    *[]int  `json:"routineLeadMins,omitempty"`
	QuietHoursEnabled  *bool   `json:"quietHoursEnabled,omitempty"`
	QuietStart         *string `json:"quietStart,omitempty"`
	QuietEnd           *string `json:"quietEnd,omitempty"`
	DailyDigestEnabled *bool   `json:"dailyDigestEnabled,omitempty"`
	DailyDigestHour    *int    `json:"dailyDigestHour,omitempty"`
}

type NotificationLogResponse struct {
	ID           string     `json:"id"`
	Type         string     `json:"type"`
	ReferenceID  string     `json:"referenceId"`
	Title        string     `json:"title"`
	Body         string     `json:"body"`
	LeadMins     *int       `json:"leadMins,omitempty"`
	Status       string     `json:"status"`
	ScheduledFor time.Time  `json:"scheduledFor"`
	SentAt       *time.Time `json:"sentAt,omitempty"`
	ReadAt       *time.Time `json:"readAt,omitempty"`
	CreatedAt    time.Time  `json:"createdAt"`
}

type ListNotificationsResponse struct {
	Items      []NotificationLogResponse `json:"items"`
	NextCursor *string                   `json:"nextCursor,omitempty"`
}
