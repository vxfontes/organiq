package usecase

import (
	"context"

	"inbota/backend/internal/app/repository"
)

type AgendaUsecase struct {
	Repo repository.AgendaRepository
}

func NewAgendaUsecase(repo repository.AgendaRepository) *AgendaUsecase {
	return &AgendaUsecase{Repo: repo}
}

func (uc *AgendaUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]repository.AgendaItem, error) {
	return uc.Repo.List(ctx, userID, opts)
}
