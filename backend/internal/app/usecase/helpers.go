package usecase

import (
	"context"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

const defaultListAllLimit = 200

func listAllFlags(ctx context.Context, repo repository.FlagRepository, userID string) ([]domain.Flag, error) {
	opts := repository.ListOptions{Limit: defaultListAllLimit}
	out := make([]domain.Flag, 0)
	for {
		items, next, err := repo.List(ctx, userID, opts)
		if err != nil {
			return nil, err
		}
		out = append(out, items...)
		if next == nil || *next == "" {
			return out, nil
		}
		opts.Cursor = *next
	}
}

func listAllSubflags(ctx context.Context, repo repository.SubflagRepository, userID, flagID string) ([]domain.Subflag, error) {
	opts := repository.ListOptions{Limit: defaultListAllLimit}
	out := make([]domain.Subflag, 0)
	for {
		items, next, err := repo.ListByFlag(ctx, userID, flagID, opts)
		if err != nil {
			return nil, err
		}
		out = append(out, items...)
		if next == nil || *next == "" {
			return out, nil
		}
		opts.Cursor = *next
	}
}

func listAllContextRules(ctx context.Context, repo repository.ContextRuleRepository, userID string) ([]domain.ContextRule, error) {
	opts := repository.ListOptions{Limit: defaultListAllLimit}
	out := make([]domain.ContextRule, 0)
	for {
		items, next, err := repo.List(ctx, userID, opts)
		if err != nil {
			return nil, err
		}
		out = append(out, items...)
		if next == nil || *next == "" {
			return out, nil
		}
		opts.Cursor = *next
	}
}
