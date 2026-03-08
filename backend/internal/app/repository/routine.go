package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type RoutineRepository interface {
	Create(ctx context.Context, routine domain.Routine) (domain.Routine, error)
	Update(ctx context.Context, routine domain.Routine) (domain.Routine, error)
	Delete(ctx context.Context, userID, id string) error
	Get(ctx context.Context, userID, id string) (domain.Routine, error)
	List(ctx context.Context, userID string, opts ListOptions) ([]domain.Routine, *string, error)
	ListByWeekday(ctx context.Context, userID string, weekday int) ([]domain.Routine, error)
	Toggle(ctx context.Context, userID, id string, isActive bool) error
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
