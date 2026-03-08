package service

import (
	"fmt"
	"strings"
	"time"
)

type ContextItem struct {
	FlagID      string
	FlagName    string
	SubflagID   *string
	SubflagName *string
}

type RuleItem struct {
	Keyword   string
	FlagID    string
	SubflagID *string
}

type ContextHint struct {
	FlagID    string
	SubflagID *string
	Reason    string
}

type PromptInput struct {
	RawText  string
	Locale   string
	Timezone string
	Now      time.Time
	Contexts []ContextItem
	Rules    []RuleItem
	Hint     *ContextHint
}

type PromptBuilder struct{}

func NewPromptBuilder() *PromptBuilder {
	return &PromptBuilder{}
}

func (b *PromptBuilder) Build(input PromptInput) string {
	var sb strings.Builder
	writeLine(&sb, "You are an information extraction engine.")
	writeLine(&sb, "Return ONLY a valid JSON object. No markdown, no extra text.")
	writeLine(&sb, "Each input must produce exactly ONE actionable item.")
	writeLine(&sb, "Use RFC3339 timestamps.")
	writeLine(&sb, fmt.Sprintf("Locale: %s", strings.TrimSpace(input.Locale)))
	writeLine(&sb, fmt.Sprintf("Timezone: %s", strings.TrimSpace(input.Timezone)))
	if !input.Now.IsZero() {
		now := input.Now
		if tz := strings.TrimSpace(input.Timezone); tz != "" {
			if loc, err := time.LoadLocation(tz); err == nil {
				now = input.Now.In(loc)
			}
		}
		writeLine(&sb, fmt.Sprintf("Now (local): %s", now.Format(time.RFC3339)))
	}
	writeLine(&sb, "Raw text:")
	writeLine(&sb, quoteBlock(input.RawText))

	if len(input.Contexts) > 0 {
		writeLine(&sb, "Available contexts:")
		for _, ctx := range input.Contexts {
			line := fmt.Sprintf("- flagId=%s name=%s", ctx.FlagID, ctx.FlagName)
			if ctx.SubflagID != nil && ctx.SubflagName != nil {
				line += fmt.Sprintf(" subflagId=%s name=%s", *ctx.SubflagID, *ctx.SubflagName)
			}
			writeLine(&sb, line)
		}
	}

	if len(input.Rules) > 0 {
		writeLine(&sb, "Context rules (keyword -> context):")
		for _, rule := range input.Rules {
			line := fmt.Sprintf("- \"%s\" -> flagId=%s", rule.Keyword, rule.FlagID)
			if rule.SubflagID != nil {
				line += fmt.Sprintf(" subflagId=%s", *rule.SubflagID)
			}
			writeLine(&sb, line)
		}
	}

	if input.Hint != nil {
		line := fmt.Sprintf("Hinted context: flagId=%s", input.Hint.FlagID)
		if input.Hint.SubflagID != nil {
			line += fmt.Sprintf(" subflagId=%s", *input.Hint.SubflagID)
		}
		if input.Hint.Reason != "" {
			line += fmt.Sprintf(" (reason: %s)", input.Hint.Reason)
		}
		writeLine(&sb, line)
	}

	writeLine(&sb, "Output JSON schema:")
	writeLine(&sb, `{"type":"task|reminder|event|shopping|note|routine","title":"string","confidence":0.0,"context":{"flagId":"string","subflagId":"string|null"},"needs_review":true,"payload":{...}}`)
	writeLine(&sb, "Payload by type:")
	writeLine(&sb, "- task: {\"dueAt\": \"RFC3339|null\"}")
	writeLine(&sb, "- reminder: {\"at\": \"RFC3339\"}")
	writeLine(&sb, "- event: {\"start\": \"RFC3339\", \"end\": \"RFC3339\", \"allDay\": true}")
	writeLine(&sb, "- shopping: {\"items\": [{\"title\": \"string\", \"quantity\": \"string|null\"}]}")
	writeLine(&sb, "- note: {\"content\": \"string\"}")
	writeLine(&sb, "- routine: {\"weekdays\": [0-6], \"startTime\": \"HH:MM\", \"endTime\": \"HH:MM|null\", \"recurrenceType\": \"weekly|biweekly|triweekly|monthly_week\", \"weekOfMonth\": 1-5|null, \"startsOn\": \"YYYY-MM-DD|null\", \"endsOn\": \"YYYY-MM-DD|null\"}")
	writeLine(&sb, "Rules:")
	writeLine(&sb, "- Always return one item only. Never return arrays at root level.")
	writeLine(&sb, "- If the text has multiple actions, select the single most actionable one and set needs_review=true.")
	writeLine(&sb, "- Use needs_review=true when unsure.")
	writeLine(&sb, "- Interpret relative dates (today, tomorrow, next week) using the provided Timezone and Now (local). Never use UTC for relative dates.")
	writeLine(&sb, "- For weekday phrases (e.g., \"next Tuesday\", \"terca que vem\", \"proxima terca\"), resolve to the next occurrence of that weekday after Now (same week if upcoming, otherwise next week). Do not shift to the day after the weekday.")
	writeLine(&sb, "- If the user says \"next week <weekday>\" or \"<weekday> da semana que vem\", use that weekday in the next calendar week (not the immediate upcoming weekday in the current week).")
	writeLine(&sb, "- Preserve explicit dates and times exactly as stated. Do not shift hours or dates; only format to RFC3339 with the correct timezone offset.")
	writeLine(&sb, "- If a reminder time is not explicit, choose 09:00 in the user's local timezone and set needs_review=true.")
	writeLine(&sb, "- Choose context from Available contexts and Context rules. Use Hinted context when relevant.")
	writeLine(&sb, "- Do not invent flagId or subflagId. If no subflag applies, use null and set needs_review=true if uncertain.")
	writeLine(&sb, "- If type=event then end must be >= start.")
	writeLine(&sb, "- If type=shopping then items must be non-empty.")
	writeLine(&sb, "- If type=reminder then payload.at must exist.")
	writeLine(&sb, "- ROUTINE DETECTION: Detect recurring patterns using keywords: \"toda\", \"todo\", \"sempre\", \"every\", \"a cada\", \"semanalmente\", \"quinzenalmente\", \"de segunda a sexta\"")
	writeLine(&sb, "- ROUTINE RULES:")
	writeLine(&sb, "  - \"Toda semana\" / \"sempre\" → recurrenceType: \"weekly\"")
	writeLine(&sb, "  - \"A cada duas semanas\" / \"quinzenal\" → recurrenceType: \"biweekly\"")
	writeLine(&sb, "  - \"A cada três semanas\" → recurrenceType: \"triweekly\"")
	writeLine(&sb, "  - \"Todo primeiro/segundo/terceiro/último [weekday] do mês\" → recurrenceType: \"monthly_week\"")
	writeLine(&sb, "  - \"De segunda a sexta\" / \"dias úteis\" → weekdays: [1,2,3,4,5]")
	writeLine(&sb, "  - \"Final de semana\" → weekdays: [0,6]")
	writeLine(&sb, "  - \"Todo dia\" → weekdays: [0,1,2,3,4,5,6]")
	writeLine(&sb, "  - Weekday mapping: 0=domingo, 1=segunda, 2=terca, 3=quarta, 4=quinta, 5=sexta, 6=sabado")
	writeLine(&sb, "  - If no explicit end time: endTime = null (do NOT guess duration)")
	writeLine(&sb, "  - If no explicit start date: startsOn = null (means starting now)")
	writeLine(&sb, "  - DIFFERENTIATE routine vs event:")
	writeLine(&sb, "    - \"Reunião toda segunda às 14h\" → routine")
	writeLine(&sb, "    - \"Reunião segunda que vem às 14h\" → event (single occurrence)")
	writeLine(&sb, "    - Key indicators for routine: \"toda/todo\", \"sempre\", \"a cada\", \"semanalmente\"")

	return sb.String()
}

func writeLine(sb *strings.Builder, line string) {
	sb.WriteString(line)
	sb.WriteByte('\n')
}

func quoteBlock(text string) string {
	trimmed := strings.TrimSpace(text)
	if trimmed == "" {
		return "\"\""
	}
	return "\"" + strings.ReplaceAll(trimmed, "\"", "\\\"") + "\""
}
