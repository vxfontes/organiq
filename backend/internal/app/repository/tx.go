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

// AuthTxRepositories bundles repositories needed for atomic signup.
type AuthTxRepositories struct {
	Users             UserRepository
	NotificationPrefs NotificationPreferencesRepository
}

// AuthTxRunner executes the signup flow atomically.
type AuthTxRunner interface {
	WithAuthTx(ctx context.Context, fn func(tx AuthTxRepositories) error) error
}
