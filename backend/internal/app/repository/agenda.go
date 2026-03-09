package repository

import (
	"context"
	"time"
)

type AgendaItem struct {
	ItemType    string    `db:"item_type"`
	ID          string    `db:"id"`
	UserID      string    `db:"user_id"`
	Title       string    `db:"title"`
	Description *string   `db:"description"`
	Status      string    `db:"status"`
	ScheduledAt time.Time `db:"scheduled_at"`

	DueAt    *time.Time `db:"due_at"`
	RemindAt *time.Time `db:"remind_at"`
	StartAt  *time.Time `db:"start_at"`
	EndAt    *time.Time `db:"end_at"`
	AllDay   *bool      `db:"all_day"`
	Location *string    `db:"location"`

	FlagID         *string `db:"flag_id"`
	SubflagID      *string `db:"subflag_id"`
	ResolvedFlagID *string `db:"resolved_flag_id"`
	FlagName       *string `db:"flag_name"`
	FlagColor      *string `db:"flag_color"`
	SubflagName    *string `db:"subflag_name"`
	SubflagColor   *string `db:"subflag_color"`

	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
}

type AgendaRepository interface {
	List(ctx context.Context, userID string, opts ListOptions) ([]AgendaItem, error)
}
