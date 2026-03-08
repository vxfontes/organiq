package usecase

import (
	"net/mail"
	"strings"

	"inbota/backend/internal/app/domain"
)

func normalizeString(value string) string {
	return strings.TrimSpace(value)
}

func normalizeOptionalString(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func parseInboxStatus(value string) (domain.InboxStatus, bool) {
	switch strings.ToUpper(strings.TrimSpace(value)) {
	case string(domain.InboxStatusNew):
		return domain.InboxStatusNew, true
	case string(domain.InboxStatusProcessing):
		return domain.InboxStatusProcessing, true
	case string(domain.InboxStatusSuggested):
		return domain.InboxStatusSuggested, true
	case string(domain.InboxStatusNeedsReview):
		return domain.InboxStatusNeedsReview, true
	case string(domain.InboxStatusConfirmed):
		return domain.InboxStatusConfirmed, true
	case string(domain.InboxStatusDismissed):
		return domain.InboxStatusDismissed, true
	default:
		return "", false
	}
}

func parseInboxSource(value string) (domain.InboxSource, bool) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case string(domain.InboxSourceManual):
		return domain.InboxSourceManual, true
	case string(domain.InboxSourceShare):
		return domain.InboxSourceShare, true
	case string(domain.InboxSourceOCR):
		return domain.InboxSourceOCR, true
	default:
		return "", false
	}
}

func parseTaskStatus(value string) (domain.TaskStatus, bool) {
	switch strings.ToUpper(strings.TrimSpace(value)) {
	case string(domain.TaskStatusOpen):
		return domain.TaskStatusOpen, true
	case string(domain.TaskStatusDone):
		return domain.TaskStatusDone, true
	default:
		return "", false
	}
}

func parseReminderStatus(value string) (domain.ReminderStatus, bool) {
	switch strings.ToUpper(strings.TrimSpace(value)) {
	case string(domain.ReminderStatusOpen):
		return domain.ReminderStatusOpen, true
	case string(domain.ReminderStatusDone):
		return domain.ReminderStatusDone, true
	default:
		return "", false
	}
}

func parseShoppingListStatus(value string) (domain.ShoppingListStatus, bool) {
	switch strings.ToUpper(strings.TrimSpace(value)) {
	case string(domain.ShoppingListStatusOpen):
		return domain.ShoppingListStatusOpen, true
	case string(domain.ShoppingListStatusDone):
		return domain.ShoppingListStatusDone, true
	case string(domain.ShoppingListStatusArchived):
		return domain.ShoppingListStatusArchived, true
	default:
		return "", false
	}
}

func parseSuggestionType(value string) (domain.AiSuggestionType, bool) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case string(domain.AiSuggestionTypeTask):
		return domain.AiSuggestionTypeTask, true
	case string(domain.AiSuggestionTypeReminder):
		return domain.AiSuggestionTypeReminder, true
	case string(domain.AiSuggestionTypeEvent):
		return domain.AiSuggestionTypeEvent, true
	case string(domain.AiSuggestionTypeShopping):
		return domain.AiSuggestionTypeShopping, true
	case string(domain.AiSuggestionTypeNote):
		return domain.AiSuggestionTypeNote, true
	case string(domain.AiSuggestionTypeRoutine):
		return domain.AiSuggestionTypeRoutine, true
	default:
		return "", false
	}
}

func validateEmail(value string) bool {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return false
	}
	parsed, err := mail.ParseAddress(trimmed)
	if err != nil {
		return false
	}
	return strings.EqualFold(parsed.Address, trimmed)
}

func validatePassword(value string) bool {
	const minLen = 8
	const maxLen = 72
	length := len(value)
	return length >= minLen && length <= maxLen
}

func validateDisplayName(value string) bool {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return false
	}
	const minLen = 2
	const maxLen = 60
	length := len([]rune(trimmed))
	return length >= minLen && length <= maxLen
}
