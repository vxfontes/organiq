package usecase

import (
	"context"
	"errors"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/infra/postgres"
)

type FlagUsecase struct {
	Flags repository.FlagRepository
}

func (uc *FlagUsecase) Create(ctx context.Context, userID, name string, color *string, sortOrder *int) (domain.Flag, error) {
	name = normalizeString(name)
	if userID == "" || name == "" {
		return domain.Flag{}, ErrMissingRequiredFields
	}
	order := 0
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.Flag{}, ErrInvalidPayload
		}
		order = *sortOrder
	}

	flag := domain.Flag{
		UserID:    userID,
		Name:      name,
		Color:     normalizeOptionalString(color),
		SortOrder: order,
	}
	return uc.Flags.Create(ctx, flag)
}

func (uc *FlagUsecase) Update(ctx context.Context, userID, id string, name *string, color *string, sortOrder *int) (domain.Flag, error) {
	if userID == "" || id == "" {
		return domain.Flag{}, ErrMissingRequiredFields
	}
	flag, err := uc.Flags.Get(ctx, userID, id)
	if err != nil {
		return domain.Flag{}, err
	}

	if name != nil {
		trimmed := normalizeString(*name)
		if trimmed == "" {
			return domain.Flag{}, ErrMissingRequiredFields
		}
		flag.Name = trimmed
	}
	if color != nil {
		flag.Color = normalizeOptionalString(color)
	}
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.Flag{}, ErrInvalidPayload
		}
		flag.SortOrder = *sortOrder
	}

	return uc.Flags.Update(ctx, flag)
}

func (uc *FlagUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Flags.Delete(ctx, userID, id)
}

func (uc *FlagUsecase) Get(ctx context.Context, userID, id string) (domain.Flag, error) {
	if userID == "" || id == "" {
		return domain.Flag{}, ErrMissingRequiredFields
	}
	return uc.Flags.Get(ctx, userID, id)
}

func (uc *FlagUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Flag, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Flags.List(ctx, userID, opts)
}

func (uc *FlagUsecase) GetByIDs(ctx context.Context, userID string, ids []string) (map[string]domain.Flag, error) {
	if userID == "" {
		return nil, ErrMissingRequiredFields
	}
	if len(ids) == 0 {
		return map[string]domain.Flag{}, nil
	}
	flags, err := uc.Flags.GetByIDs(ctx, userID, ids)
	if err != nil {
		return nil, err
	}
	out := make(map[string]domain.Flag, len(flags))
	for _, flag := range flags {
		out[flag.ID] = flag
	}
	return out, nil
}

type SubflagUsecase struct {
	Subflags repository.SubflagRepository
	Flags    repository.FlagRepository
}

func (uc *SubflagUsecase) Create(ctx context.Context, userID, flagID, name string, sortOrder *int) (domain.Subflag, error) {
	name = normalizeString(name)
	if userID == "" || flagID == "" || name == "" {
		return domain.Subflag{}, ErrMissingRequiredFields
	}
	if uc.Flags == nil {
		return domain.Subflag{}, ErrDependencyMissing
	}
	if _, err := uc.Flags.Get(ctx, userID, flagID); err != nil {
		if errors.Is(err, postgres.ErrNotFound) {
			return domain.Subflag{}, ErrInvalidPayload
		}
		return domain.Subflag{}, err
	}
	order := 0
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.Subflag{}, ErrInvalidPayload
		}
		order = *sortOrder
	}

	subflag := domain.Subflag{
		UserID:    userID,
		FlagID:    flagID,
		Name:      name,
		SortOrder: order,
	}
	return uc.Subflags.Create(ctx, subflag)
}

func (uc *SubflagUsecase) Update(ctx context.Context, userID, id string, name *string, sortOrder *int) (domain.Subflag, error) {
	if userID == "" || id == "" {
		return domain.Subflag{}, ErrMissingRequiredFields
	}
	subflag, err := uc.Subflags.Get(ctx, userID, id)
	if err != nil {
		return domain.Subflag{}, err
	}

	if name != nil {
		trimmed := normalizeString(*name)
		if trimmed == "" {
			return domain.Subflag{}, ErrMissingRequiredFields
		}
		subflag.Name = trimmed
	}
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.Subflag{}, ErrInvalidPayload
		}
		subflag.SortOrder = *sortOrder
	}

	return uc.Subflags.Update(ctx, subflag)
}

func (uc *SubflagUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Subflags.Delete(ctx, userID, id)
}

func (uc *SubflagUsecase) Get(ctx context.Context, userID, id string) (domain.Subflag, error) {
	if userID == "" || id == "" {
		return domain.Subflag{}, ErrMissingRequiredFields
	}
	return uc.Subflags.Get(ctx, userID, id)
}

func (uc *SubflagUsecase) ListByFlag(ctx context.Context, userID, flagID string, opts repository.ListOptions) ([]domain.Subflag, *string, error) {
	if userID == "" || flagID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Subflags.ListByFlag(ctx, userID, flagID, opts)
}

func (uc *SubflagUsecase) GetByIDs(ctx context.Context, userID string, ids []string) (map[string]domain.Subflag, error) {
	if userID == "" {
		return nil, ErrMissingRequiredFields
	}
	if len(ids) == 0 {
		return map[string]domain.Subflag{}, nil
	}
	subflags, err := uc.Subflags.GetByIDs(ctx, userID, ids)
	if err != nil {
		return nil, err
	}
	out := make(map[string]domain.Subflag, len(subflags))
	for _, subflag := range subflags {
		out[subflag.ID] = subflag
	}
	return out, nil
}

type ContextRuleUsecase struct {
	Rules    repository.ContextRuleRepository
	Flags    repository.FlagRepository
	Subflags repository.SubflagRepository
}

func (uc *ContextRuleUsecase) Create(ctx context.Context, userID, keyword, flagID string, subflagID *string) (domain.ContextRule, error) {
	keyword = normalizeString(keyword)
	if userID == "" || keyword == "" || flagID == "" {
		return domain.ContextRule{}, ErrMissingRequiredFields
	}
	if err := uc.validateFlag(ctx, userID, flagID); err != nil {
		return domain.ContextRule{}, err
	}
	if err := uc.validateSubflag(ctx, userID, flagID, subflagID); err != nil {
		return domain.ContextRule{}, err
	}

	rule := domain.ContextRule{
		UserID:    userID,
		Keyword:   keyword,
		FlagID:    flagID,
		SubflagID: normalizeOptionalString(subflagID),
	}
	return uc.Rules.Create(ctx, rule)
}

func (uc *ContextRuleUsecase) Update(ctx context.Context, userID, id string, keyword *string, flagID *string, subflagID *string) (domain.ContextRule, error) {
	if userID == "" || id == "" {
		return domain.ContextRule{}, ErrMissingRequiredFields
	}
	rule, err := uc.Rules.Get(ctx, userID, id)
	if err != nil {
		return domain.ContextRule{}, err
	}

	if keyword != nil {
		trimmed := normalizeString(*keyword)
		if trimmed == "" {
			return domain.ContextRule{}, ErrMissingRequiredFields
		}
		rule.Keyword = trimmed
	}
	nextFlagID := rule.FlagID
	if flagID != nil {
		if normalizeString(*flagID) == "" {
			return domain.ContextRule{}, ErrMissingRequiredFields
		}
		nextFlagID = normalizeString(*flagID)
		if err := uc.validateFlag(ctx, userID, nextFlagID); err != nil {
			return domain.ContextRule{}, err
		}
		rule.FlagID = nextFlagID
	}
	if subflagID != nil {
		if err := uc.validateSubflag(ctx, userID, nextFlagID, subflagID); err != nil {
			return domain.ContextRule{}, err
		}
		rule.SubflagID = normalizeOptionalString(subflagID)
	}

	return uc.Rules.Update(ctx, rule)
}

func (uc *ContextRuleUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Rules.Delete(ctx, userID, id)
}

func (uc *ContextRuleUsecase) Get(ctx context.Context, userID, id string) (domain.ContextRule, error) {
	if userID == "" || id == "" {
		return domain.ContextRule{}, ErrMissingRequiredFields
	}
	return uc.Rules.Get(ctx, userID, id)
}

func (uc *ContextRuleUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.ContextRule, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Rules.List(ctx, userID, opts)
}

func (uc *ContextRuleUsecase) validateFlag(ctx context.Context, userID, flagID string) error {
	if uc.Flags == nil {
		return ErrDependencyMissing
	}
	if _, err := uc.Flags.Get(ctx, userID, flagID); err != nil {
		if errors.Is(err, postgres.ErrNotFound) {
			return ErrInvalidPayload
		}
		return err
	}
	return nil
}

func (uc *ContextRuleUsecase) validateSubflag(ctx context.Context, userID, flagID string, subflagID *string) error {
	if subflagID == nil {
		return nil
	}
	if uc.Subflags == nil {
		return ErrDependencyMissing
	}
	subflag, err := uc.Subflags.Get(ctx, userID, *subflagID)
	if err != nil {
		if errors.Is(err, postgres.ErrNotFound) {
			return ErrInvalidPayload
		}
		return err
	}
	if flagID != "" && subflag.FlagID != flagID {
		return ErrInvalidPayload
	}
	return nil
}
