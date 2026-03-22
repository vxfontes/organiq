package service

import (
	"fmt"
	"strings"
	"time"
)

type SuggestionPromptMessage struct {
	Role    string
	Content string
}

type SuggestionPromptTask struct {
	Title string
	DueAt *time.Time
}

type SuggestionPromptReminder struct {
	Title    string
	RemindAt *time.Time
}

type SuggestionPromptEvent struct {
	Title   string
	StartAt *time.Time
	EndAt   *time.Time
}

type SuggestionPromptRoutine struct {
	Title          string
	RecurrenceType string
	Weekdays       []int
	StartTime      string
	EndTime        string
}

type SuggestionPromptSubflag struct {
	SubflagID string
	Name      string
}

type SuggestionPromptFlag struct {
	FlagID   string
	Name     string
	Subflags []SuggestionPromptSubflag
}

type SuggestionPromptInput struct {
	Locale          string
	Timezone        string
	Now             time.Time
	IncomingMessage string
	Messages        []SuggestionPromptMessage
	Tasks           []SuggestionPromptTask
	Reminders       []SuggestionPromptReminder
	Events          []SuggestionPromptEvent
	Routines        []SuggestionPromptRoutine
	Flags           []SuggestionPromptFlag
}

type SuggestionPromptBuilder struct{}

func NewSuggestionPromptBuilder() *SuggestionPromptBuilder {
	return &SuggestionPromptBuilder{}
}

func (b *SuggestionPromptBuilder) Build(input SuggestionPromptInput) string {
	var sb strings.Builder

	writeLine(&sb, "You are a planning assistant for a personal productivity app.")
	writeLine(&sb, "Reply with ONLY valid JSON, no markdown and no extra text.")
	writeLine(&sb, "Output schema:")
	writeLine(&sb, `{"text":"string","blocks":[{"type":"task|event|routine","title":"string","rationale":"string","startsAt":"RFC3339|null","endsAt":"RFC3339|null","weekdays":[0-6]|null,"recurrenceType":"weekly|biweekly|triweekly|monthly_week|monthly_day|null","flagId":"uuid|null","subflagId":"uuid|null"}]}`)
	writeLine(&sb, "Rules:")
	writeLine(&sb, "- text is always required and must be clear and concise.")
	writeLine(&sb, "- blocks is optional. Return [] when no concrete suggestion fits.")
	writeLine(&sb, "- Do not include reminders, shopping lists or notes in blocks.")
	writeLine(&sb, "- Use provided timezone and locale for temporal reasoning.")
	writeLine(&sb, "- Avoid suggesting blocks that overlap existing events/routines when possible.")
	writeLine(&sb, "- Never invent flagId/subflagId. Use null when uncertain.")

	writeLine(&sb, fmt.Sprintf("Locale: %s", strings.TrimSpace(input.Locale)))
	writeLine(&sb, fmt.Sprintf("Timezone: %s", strings.TrimSpace(input.Timezone)))
	if !input.Now.IsZero() {
		writeLine(&sb, fmt.Sprintf("Now (local): %s", input.Now.Format(time.RFC3339)))
	}

	writeLine(&sb, "Incoming user message:")
	writeLine(&sb, quoteBlock(input.IncomingMessage))

	if len(input.Messages) > 0 {
		writeLine(&sb, "Conversation history (most recent messages):")
		for _, msg := range input.Messages {
			role := strings.ToLower(strings.TrimSpace(msg.Role))
			if role == "" {
				role = "user"
			}
			writeLine(&sb, fmt.Sprintf("- %s: %s", role, strings.TrimSpace(msg.Content)))
		}
	}

	if len(input.Tasks) > 0 {
		writeLine(&sb, "Open tasks:")
		for _, task := range input.Tasks {
			dueAt := "null"
			if task.DueAt != nil {
				dueAt = task.DueAt.Format(time.RFC3339)
			}
			writeLine(&sb, fmt.Sprintf("- title=%q dueAt=%s", task.Title, dueAt))
		}
	}

	if len(input.Reminders) > 0 {
		writeLine(&sb, "Open reminders:")
		for _, reminder := range input.Reminders {
			remindAt := "null"
			if reminder.RemindAt != nil {
				remindAt = reminder.RemindAt.Format(time.RFC3339)
			}
			writeLine(&sb, fmt.Sprintf("- title=%q remindAt=%s", reminder.Title, remindAt))
		}
	}

	if len(input.Events) > 0 {
		writeLine(&sb, "Upcoming events:")
		for _, event := range input.Events {
			start := "null"
			end := "null"
			if event.StartAt != nil {
				start = event.StartAt.Format(time.RFC3339)
			}
			if event.EndAt != nil {
				end = event.EndAt.Format(time.RFC3339)
			}
			writeLine(&sb, fmt.Sprintf("- title=%q startAt=%s endAt=%s", event.Title, start, end))
		}
	}

	if len(input.Routines) > 0 {
		writeLine(&sb, "Active routines:")
		for _, routine := range input.Routines {
			writeLine(&sb, fmt.Sprintf("- title=%q recurrenceType=%s weekdays=%v startTime=%s endTime=%s",
				routine.Title,
				routine.RecurrenceType,
				routine.Weekdays,
				routine.StartTime,
				routine.EndTime,
			))
		}
	}

	if len(input.Flags) > 0 {
		writeLine(&sb, "Available contexts:")
		for _, flag := range input.Flags {
			writeLine(&sb, fmt.Sprintf("- flagId=%s name=%q", flag.FlagID, flag.Name))
			for _, subflag := range flag.Subflags {
				writeLine(&sb, fmt.Sprintf("  - subflagId=%s name=%q", subflag.SubflagID, subflag.Name))
			}
		}
	}

	return sb.String()
}
