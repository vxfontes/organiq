package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type RoutineDailyStatus struct {
	domain.Routine
	CompletedAt     *string `db:"completed_at"`
	IsCompleted     bool    `db:"is_completed"`
	ExceptionAction *string `db:"exception_action"`
}

type RoutineRepository interface {
	Create(ctx context.Context, routine domain.Routine) (domain.Routine, error)
	Update(ctx context.Context, routine domain.Routine) (domain.Routine, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.Routine, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.Routine, *string, error)
	ListByWeekday(ctx context.Context, userID string, weekday int) ([]domain.Routine, error)
	ListAllByWeekday(ctx context.Context, weekday int) ([]domain.Routine, error)
	ListDailyStatus(ctx context.Context, userID string, weekday int) ([]RoutineDailyStatus, error)
	Toggle(ctx context.Context, userID, id string, isActive bool) error
	CheckOverlap(ctx context.Context, userID string, weekdays []int, startTime, endTime string, excludeID *string) (bool, error)
}

type RoutineExceptionRepository interface {
	Create(ctx context.Context, userID string, exception domain.RoutineException) (domain.RoutineException, error)
	Delete(ctx context.Context, userID, routineID, exceptionDate string) error
	GetByRoutine(ctx context.Context, userID, routineID string) ([]domain.RoutineException, error)
	GetForDate(ctx context.Context, userID, routineID, date string) (*domain.RoutineException, error)
}

type RoutineCompletionRepository interface {
	Create(ctx context.Context, userID string, completion domain.RoutineCompletion) (domain.RoutineCompletion, error)
	Delete(ctx context.Context, userID, routineID, completedOn string) error
	GetByRoutine(ctx context.Context, userID, routineID string) ([]domain.RoutineCompletion, error)
	GetByDate(ctx context.Context, userID, date string) ([]domain.RoutineCompletion, error)
	GetStreak(ctx context.Context, userID, routineID string) (int, int, error)
}
