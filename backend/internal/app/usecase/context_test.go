package usecase

import (
	"context"
	"errors"
	"testing"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/infra/postgres"
)

type flagRepoStub struct {
	getFn func(ctx context.Context, userID, id string) (domain.Flag, error)
}

func (s flagRepoStub) Create(context.Context, domain.Flag) (domain.Flag, error) {
	panic("unexpected Create")
}
func (s flagRepoStub) Update(context.Context, domain.Flag) (domain.Flag, error) {
	panic("unexpected Update")
}
func (s flagRepoStub) Delete(context.Context, string, string) error {
	panic("unexpected Delete")
}
func (s flagRepoStub) Get(ctx context.Context, userID, id string) (domain.Flag, error) {
	if s.getFn != nil {
		return s.getFn(ctx, userID, id)
	}
	panic("unexpected Get")
}
func (s flagRepoStub) GetByIDs(context.Context, string, []string) ([]domain.Flag, error) {
	panic("unexpected GetByIDs")
}
func (s flagRepoStub) List(context.Context, string, repository.ListOptions) ([]domain.Flag, *string, error) {
	panic("unexpected List")
}

type subflagRepoStub struct {
	getFn    func(ctx context.Context, userID, id string) (domain.Subflag, error)
	createFn func(ctx context.Context, subflag domain.Subflag) (domain.Subflag, error)
}

func (s subflagRepoStub) Create(ctx context.Context, subflag domain.Subflag) (domain.Subflag, error) {
	if s.createFn != nil {
		return s.createFn(ctx, subflag)
	}
	panic("unexpected Create")
}
func (s subflagRepoStub) Update(context.Context, domain.Subflag) (domain.Subflag, error) {
	panic("unexpected Update")
}
func (s subflagRepoStub) Delete(context.Context, string, string) error {
	panic("unexpected Delete")
}
func (s subflagRepoStub) Get(ctx context.Context, userID, id string) (domain.Subflag, error) {
	if s.getFn != nil {
		return s.getFn(ctx, userID, id)
	}
	panic("unexpected Get")
}
func (s subflagRepoStub) GetByIDs(context.Context, string, []string) ([]domain.Subflag, error) {
	panic("unexpected GetByIDs")
}
func (s subflagRepoStub) ListByFlag(context.Context, string, string, repository.ListOptions) ([]domain.Subflag, *string, error) {
	panic("unexpected ListByFlag")
}

type contextRuleRepoStub struct{}

func (contextRuleRepoStub) Create(context.Context, domain.ContextRule) (domain.ContextRule, error) {
	panic("unexpected Create")
}
func (contextRuleRepoStub) Update(context.Context, domain.ContextRule) (domain.ContextRule, error) {
	panic("unexpected Update")
}
func (contextRuleRepoStub) Delete(context.Context, string, string) error {
	panic("unexpected Delete")
}
func (contextRuleRepoStub) Get(context.Context, string, string) (domain.ContextRule, error) {
	panic("unexpected Get")
}
func (contextRuleRepoStub) List(context.Context, string, repository.ListOptions) ([]domain.ContextRule, *string, error) {
	panic("unexpected List")
}

func TestSubflagCreateRejectsMissingFlag(t *testing.T) {
	uc := &SubflagUsecase{
		Flags: flagRepoStub{
			getFn: func(context.Context, string, string) (domain.Flag, error) {
				return domain.Flag{}, postgres.ErrNotFound
			},
		},
		Subflags: subflagRepoStub{
			createFn: func(context.Context, domain.Subflag) (domain.Subflag, error) {
				t.Fatal("unexpected create")
				return domain.Subflag{}, nil
			},
		},
	}

	_, err := uc.Create(context.Background(), "user", "flag", "nome", nil)
	if !errors.Is(err, ErrInvalidPayload) {
		t.Fatalf("expected ErrInvalidPayload, got %v", err)
	}
}

func TestContextRuleCreateRejectsSubflagFromOtherFlag(t *testing.T) {
	uc := &ContextRuleUsecase{
		Rules: contextRuleRepoStub{},
		Flags: flagRepoStub{
			getFn: func(context.Context, string, string) (domain.Flag, error) {
				return domain.Flag{ID: "flag-1"}, nil
			},
		},
		Subflags: subflagRepoStub{
			getFn: func(context.Context, string, string) (domain.Subflag, error) {
				return domain.Subflag{ID: "sub-1", FlagID: "flag-2"}, nil
			},
		},
	}

	subflagID := "sub-1"
	_, err := uc.Create(context.Background(), "user", "keyword", "flag-1", &subflagID)
	if !errors.Is(err, ErrInvalidPayload) {
		t.Fatalf("expected ErrInvalidPayload, got %v", err)
	}
}
