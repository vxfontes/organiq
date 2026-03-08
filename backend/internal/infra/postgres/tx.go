package postgres

import (
	"context"

	"inbota/backend/internal/app/repository"
)

// TxRunner executes functions inside a SQL transaction.
type TxRunner struct {
	db *DB
}

func NewTxRunner(db *DB) *TxRunner {
	return &TxRunner{db: db}
}

func (r *TxRunner) WithTx(ctx context.Context, fn func(tx repository.TxRepositories) error) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	repos := repository.TxRepositories{
		Inbox:         NewInboxRepositoryTx(tx),
		Suggestions:   NewAiSuggestionRepositoryTx(tx),
		Tasks:         NewTaskRepositoryTx(tx),
		Reminders:     NewReminderRepositoryTx(tx),
		Events:        NewEventRepositoryTx(tx),
		ShoppingLists: NewShoppingListRepositoryTx(tx),
		ShoppingItems: NewShoppingItemRepositoryTx(tx),
		Routines:      NewRoutineRepositoryTx(tx),
	}

	if err := fn(repos); err != nil {
		_ = tx.Rollback()
		return err
	}

	return tx.Commit()
}
