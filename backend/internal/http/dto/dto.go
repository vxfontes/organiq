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
	ID             string         `json:"id"`
	Title          string         `json:"title"`
	Description    *string        `json:"description,omitempty"`
	RecurrenceType string         `json:"recurrenceType"`
	Weekdays       []int          `json:"weekdays"`
	StartTime      string         `json:"startTime"`
	EndTime        *string        `json:"endTime,omitempty"`
	WeekOfMonth    *int           `json:"weekOfMonth,omitempty"`
	StartsOn       string         `json:"startsOn"`
	EndsOn         *string        `json:"endsOn,omitempty"`
	Color          *string        `json:"color,omitempty"`
	IsActive       bool           `json:"isActive"`
	IsCompletedToday bool         `json:"isCompletedToday"`
	Flag           *FlagObject    `json:"flag,omitempty"`
	Subflag        *SubflagObject `json:"subflag,omitempty"`
	CreatedAt      time.Time      `json:"createdAt"`
	UpdatedAt      time.Time      `json:"updatedAt"`
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
	EndTime        *string `json:"endTime,omitempty"`
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

type RoutineStreakResponse struct {
	CurrentStreak    int `json:"currentStreak"`
	TotalCompletions int `json:"totalCompletions"`
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
