package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"organiq/backend/internal/app/domain"
)

type appErrorLogRepoStub struct {
	createFn func(ctx context.Context, log domain.AppErrorLog) (domain.AppErrorLog, error)
}

func (s appErrorLogRepoStub) Create(ctx context.Context, log domain.AppErrorLog) (domain.AppErrorLog, error) {
	if s.createFn != nil {
		return s.createFn(ctx, log)
	}
	return domain.AppErrorLog{}, nil
}

func TestAppErrorLogCreateRejectsAnonymousWithoutSession(t *testing.T) {
	uc := &AppErrorLogUsecase{
		Logs: appErrorLogRepoStub{
			createFn: func(context.Context, domain.AppErrorLog) (domain.AppErrorLog, error) {
				t.Fatal("unexpected create")
				return domain.AppErrorLog{}, nil
			},
		},
	}

	_, err := uc.Create(context.Background(), nil, AppErrorLogInput{
		Source:  "flutter",
		Message: "boom",
	})
	if !errors.Is(err, ErrMissingRequiredFields) {
		t.Fatalf("expected ErrMissingRequiredFields, got %v", err)
	}
}

func TestAppErrorLogCreateRejectsOversizedMetadata(t *testing.T) {
	sessionID := "sess_123"
	uc := &AppErrorLogUsecase{
		Logs: appErrorLogRepoStub{
			createFn: func(context.Context, domain.AppErrorLog) (domain.AppErrorLog, error) {
				t.Fatal("unexpected create")
				return domain.AppErrorLog{}, nil
			},
		},
	}

	metadata := map[string]string{
		"blob": strings.Repeat("x", maxAppErrorMetadataBytes),
	}
	raw, err := json.Marshal(metadata)
	if err != nil {
		t.Fatalf("marshal metadata: %v", err)
	}

	_, err = uc.Create(context.Background(), nil, AppErrorLogInput{
		SessionID: &sessionID,
		Source:    "flutter",
		Message:   "boom",
		Metadata:  raw,
	})
	if !errors.Is(err, ErrInvalidPayload) {
		t.Fatalf("expected ErrInvalidPayload, got %v", err)
	}
}

func TestAppErrorLogCreateRejectsOutOfWindowOccurredAt(t *testing.T) {
	sessionID := "sess_123"
	uc := &AppErrorLogUsecase{
		Logs: appErrorLogRepoStub{
			createFn: func(context.Context, domain.AppErrorLog) (domain.AppErrorLog, error) {
				t.Fatal("unexpected create")
				return domain.AppErrorLog{}, nil
			},
		},
	}

	old := time.Now().UTC().Add(-(maxAppErrorAgeWindow + time.Hour))
	_, err := uc.Create(context.Background(), nil, AppErrorLogInput{
		SessionID:  &sessionID,
		Source:     "flutter",
		Message:    "boom",
		OccurredAt: &old,
	})
	if !errors.Is(err, ErrInvalidPayload) {
		t.Fatalf("expected ErrInvalidPayload, got %v", err)
	}
}

func TestAppErrorLogCreateSanitizesInput(t *testing.T) {
	userID := "  user-id  "
	sessionID := strings.Repeat("s", maxAppErrorSessionIDLen+20)
	message := strings.Repeat("m", maxAppErrorMessageLen+200)
	stack := strings.Repeat("t", maxAppErrorStackTraceLen+200)
	method := "post"
	rawMetadata := json.RawMessage(`{ "a": 1 }`)

	var created domain.AppErrorLog
	uc := &AppErrorLogUsecase{
		Logs: appErrorLogRepoStub{
			createFn: func(_ context.Context, log domain.AppErrorLog) (domain.AppErrorLog, error) {
				created = log
				return log, nil
			},
		},
	}

	_, err := uc.Create(context.Background(), &userID, AppErrorLogInput{
		SessionID:     &sessionID,
		Source:        "flutter",
		Message:       message,
		StackTrace:    &stack,
		RequestMethod: &method,
		Metadata:      rawMetadata,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if created.UserID == nil || *created.UserID != "user-id" {
		t.Fatalf("expected trimmed user id, got %+v", created.UserID)
	}
	if created.SessionID == nil || len([]rune(*created.SessionID)) != maxAppErrorSessionIDLen {
		t.Fatalf("expected truncated session id, got len=%d", len([]rune(*created.SessionID)))
	}
	if len([]rune(created.Message)) != maxAppErrorMessageLen {
		t.Fatalf("expected truncated message, got len=%d", len([]rune(created.Message)))
	}
	if created.StackTrace == nil || len([]rune(*created.StackTrace)) != maxAppErrorStackTraceLen {
		t.Fatalf("expected truncated stacktrace, got len=%d", len([]rune(*created.StackTrace)))
	}
	if created.RequestMethod == nil || *created.RequestMethod != "POST" {
		t.Fatalf("expected upper request method, got %+v", created.RequestMethod)
	}
	if string(created.Metadata) != `{"a":1}` {
		t.Fatalf("expected normalized metadata, got %s", string(created.Metadata))
	}
}
