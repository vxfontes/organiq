package handler

// APIHandlers groups HTTP handlers for the API.
type APIHandlers struct {
	Me            *MeHandler
	Flags         *FlagsHandler
	Subflags      *SubflagsHandler
	ContextRules  *ContextRulesHandler
	Inbox         *InboxHandler
	Agenda        *AgendaHandler
	Home          *HomeHandler
	Tasks         *TasksHandler
	Reminders     *RemindersHandler
	Events        *EventsHandler
	ShoppingLists *ShoppingListsHandler
	ShoppingItems *ShoppingItemsHandler
	Routines      *RoutinesHandler
	Devices       *DevicesHandler
	Notifications *NotificationsHandler
	Digest        *DigestHandler
}
