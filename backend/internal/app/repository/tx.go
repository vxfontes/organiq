package repository

import "context"

// TxRepositories bundles repositories bound to a transaction.
type TxRepositories struct {
	Inbox         InboxRepository
	Suggestions   AiSuggestionRepository
	Tasks         TaskRepository
	Reminders     ReminderRepository
	Events        EventRepository
	ShoppingLists ShoppingListRepository
	ShoppingItems ShoppingItemRepository
	Routines      RoutineRepository
}

// TxRunner executes functions inside a transaction.
type TxRunner interface {
	WithTx(ctx context.Context, fn func(tx TxRepositories) error) error
}
