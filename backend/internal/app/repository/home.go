package repository

import (
	"context"
	"time"
)

type HomeInsightTemplate struct {
	ID              string
	Category        string
	TitleTemplate   string
	SummaryTemplate string
	FooterTemplate  string
	IsFocus         bool
	MinGapMinutes   *int
	Priority        int
}

type HomeShoppingPreview struct {
	ID           string
	Title        string
	TotalItems   int
	PendingItems int
	PreviewItems []string
}

type HomeFocusTask struct {
	ID          string
	Title       string
	Description *string
	Status      string
	DueAt       *time.Time
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type HomeRepository interface {
	ListInsightTemplates(ctx context.Context) ([]HomeInsightTemplate, error)
	ListShoppingPreview(ctx context.Context, userID string, limit int) ([]HomeShoppingPreview, error)
	ListFocusTasks(ctx context.Context, userID string, limit int) ([]HomeFocusTask, error)
	ListWeekOccurrences(ctx context.Context, userID string, start, end time.Time) ([]time.Time, error)
	CountOverdue(ctx context.Context, userID string, now time.Time) (int, int, error)
}
