package service

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

var ErrAISchemaInvalid = errors.New("ai_schema_invalid")

// AIOutput is the expected structure from the LLM.
type AIOutput struct {
	Type        string          `json:"type"`
	Title       string          `json:"title"`
	Confidence  *float64        `json:"confidence,omitempty"`
	Context     *AIContext      `json:"context,omitempty"`
	NeedsReview bool            `json:"needs_review"`
	Payload     json.RawMessage `json:"payload"`
}

type AIContext struct {
	FlagID    *string `json:"flagId,omitempty"`
	SubflagID *string `json:"subflagId,omitempty"`
}

type TaskPayload struct {
	DueAt *time.Time
}

type ReminderPayload struct {
	At time.Time
}

type EventPayload struct {
	Start  time.Time
	End    *time.Time
	AllDay bool
}

type ShoppingItemPayload struct {
	Title    string
	Quantity *string
}

type ShoppingPayload struct {
	Items []ShoppingItemPayload
}

type NotePayload struct {
	Content string
}

type RoutinePayload struct {
	Weekdays       []int   `json:"weekdays"`
	StartTime      string  `json:"startTime"`
	EndTime        string  `json:"endTime"`
	RecurrenceType string  `json:"recurrenceType"`
	WeekOfMonth    *int    `json:"weekOfMonth,omitempty"`
	StartsOn       *string `json:"startsOn,omitempty"`
	EndsOn         *string `json:"endsOn,omitempty"`
}

type ValidatedOutput struct {
	Output  AIOutput
	Payload any
}

type AiSchemaValidator struct{}

func NewAiSchemaValidator() *AiSchemaValidator {
	return &AiSchemaValidator{}
}

// Validate accepts either a single item object or an array of item objects.
// For backward compatibility, it returns the first item when an array is provided.
func (v *AiSchemaValidator) Validate(raw []byte) (ValidatedOutput, error) {
	outs, err := v.ValidateMany(raw)
	if err != nil {
		return ValidatedOutput{}, err
	}
	if len(outs) == 0 {
		return ValidatedOutput{}, fmt.Errorf("%w: empty_output", ErrAISchemaInvalid)
	}
	return outs[0], nil
}

func (v *AiSchemaValidator) ValidateMany(raw []byte) ([]ValidatedOutput, error) {
	outputs, err := decodeStrictOutputs(raw)
	if err != nil {
		return nil, err
	}

	validated := make([]ValidatedOutput, 0, len(outputs))
	for _, output := range outputs {
		if output.Title == "" {
			return nil, fmt.Errorf("%w: title_required", ErrAISchemaInvalid)
		}
		if output.Confidence != nil {
			if *output.Confidence < 0 || *output.Confidence > 1 {
				return nil, fmt.Errorf("%w: confidence_out_of_range", ErrAISchemaInvalid)
			}
		}

		payload, err := v.validatePayload(output.Type, output.Payload)
		if err != nil {
			return nil, err
		}
		validated = append(validated, ValidatedOutput{Output: output, Payload: payload})
	}

	return validated, nil
}

func decodeStrictOutputs(raw []byte) ([]AIOutput, error) {
	normalized := normalizeJSONPayload(raw)
	normalized = normalizeOutputAliases(normalized)

	// Accept either an object or an array at root.
	var anyRoot any
	if err := json.Unmarshal(normalized, &anyRoot); err != nil {
		return nil, fmt.Errorf("%w: %s", ErrAISchemaInvalid, err.Error())
	}

	if _, ok := anyRoot.([]any); ok {
		var rawArr []json.RawMessage
		if err := json.Unmarshal(normalized, &rawArr); err != nil {
			return nil, fmt.Errorf("%w: %s", ErrAISchemaInvalid, err.Error())
		}
		outs := make([]AIOutput, 0, len(rawArr))
		for _, elem := range rawArr {
			out, err := decodeStrictOutput(elem)
			if err != nil {
				return nil, err
			}
			outs = append(outs, out)
		}
		return outs, nil
	}

	out, err := decodeStrictOutput(normalized)
	if err != nil {
		return nil, err
	}
	return []AIOutput{out}, nil
}

func decodeStrictOutput(raw []byte) (AIOutput, error) {
	normalized := normalizeJSONPayload(raw)
	normalized = normalizeOutputAliases(normalized)

	var rawMap map[string]json.RawMessage
	if err := json.Unmarshal(normalized, &rawMap); err != nil {
		return AIOutput{}, fmt.Errorf("%w: %s", ErrAISchemaInvalid, err.Error())
	}
	if _, ok := rawMap["type"]; !ok {
		return AIOutput{}, fmt.Errorf("%w: type_required", ErrAISchemaInvalid)
	}
	if _, ok := rawMap["title"]; !ok {
		return AIOutput{}, fmt.Errorf("%w: title_required", ErrAISchemaInvalid)
	}
	if _, ok := rawMap["needs_review"]; !ok {
		return AIOutput{}, fmt.Errorf("%w: needs_review_required", ErrAISchemaInvalid)
	}
	if _, ok := rawMap["payload"]; !ok {
		return AIOutput{}, fmt.Errorf("%w: payload_required", ErrAISchemaInvalid)
	}

	dec := json.NewDecoder(bytes.NewReader(normalized))
	dec.DisallowUnknownFields()
	var output AIOutput
	if err := dec.Decode(&output); err != nil {
		return AIOutput{}, fmt.Errorf("%w: %s", ErrAISchemaInvalid, err.Error())
	}
	if output.Type == "" {
		return AIOutput{}, fmt.Errorf("%w: type_required", ErrAISchemaInvalid)
	}
	return output, nil
}

func normalizeOutputAliases(raw []byte) []byte {
	var generic map[string]any
	if err := json.Unmarshal(raw, &generic); err != nil {
		return raw
	}

	renameKey(generic, "needsReview", "needs_review")
	renameKey(generic, "needsreview", "needs_review")

	if contextValue, ok := generic["context"]; ok {
		if contextMap, ok := contextValue.(map[string]any); ok {
			renameKey(contextMap, "flag_id", "flagId")
			renameKey(contextMap, "subflag_id", "subflagId")
		}
	}

	typ, _ := generic["type"].(string)
	payloadMap, hasPayload := generic["payload"].(map[string]any)
	if hasPayload {
		switch strings.ToLower(strings.TrimSpace(typ)) {
		case "task":
			renameKey(payloadMap, "due_at", "dueAt")
		case "reminder":
			renameKey(payloadMap, "remindAt", "at")
			renameKey(payloadMap, "reminderAt", "at")
			renameKey(payloadMap, "when", "at")
		case "event":
			renameKey(payloadMap, "startAt", "start")
			renameKey(payloadMap, "endAt", "end")
		case "routine":
			renameKey(payloadMap, "start_time", "startTime")
			renameKey(payloadMap, "end_time", "endTime")
			renameKey(payloadMap, "recurrence_type", "recurrenceType")
			renameKey(payloadMap, "week_of_month", "weekOfMonth")
			renameKey(payloadMap, "starts_on", "startsOn")
			renameKey(payloadMap, "ends_on", "endsOn")
		}
	}

	normalized, err := json.Marshal(generic)
	if err != nil {
		return raw
	}
	return normalized
}

func renameKey(target map[string]any, from, to string) {
	if target == nil || from == "" || to == "" || from == to {
		return
	}
	if _, exists := target[to]; exists {
		return
	}
	value, ok := target[from]
	if !ok {
		return
	}
	target[to] = value
	delete(target, from)
}

func normalizeJSONPayload(raw []byte) []byte {
	trimmed := bytes.TrimSpace(raw)
	if len(trimmed) == 0 {
		return trimmed
	}

	// Fast path for already valid object bodies.
	if trimmed[0] == '{' && trimmed[len(trimmed)-1] == '}' {
		return trimmed
	}

	// LLMs can return prose/markdown around the JSON body.
	if extracted, ok := extractFirstJSONObject(trimmed); ok {
		return extracted
	}

	return trimmed
}

func extractFirstJSONObject(raw []byte) ([]byte, bool) {
	start := -1
	depth := 0
	inString := false
	escaped := false

	for i, ch := range raw {
		if inString {
			if escaped {
				escaped = false
				continue
			}
			if ch == '\\' {
				escaped = true
				continue
			}
			if ch == '"' {
				inString = false
			}
			continue
		}

		switch ch {
		case '"':
			inString = true
		case '{':
			if depth == 0 {
				start = i
			}
			depth++
		case '}':
			if depth == 0 {
				continue
			}
			depth--
			if depth == 0 && start >= 0 {
				return raw[start : i+1], true
			}
		}
	}

	return nil, false
}

func BuildFallbackTaskOutput(rawText string, context *AIContext) ValidatedOutput {
	payload := json.RawMessage(`{"dueAt":null}`)
	return ValidatedOutput{
		Output: AIOutput{
			Type:        "task",
			Title:       fallbackTaskTitle(rawText),
			NeedsReview: true,
			Context:     context,
			Payload:     payload,
		},
		Payload: TaskPayload{DueAt: nil},
	}
}

func fallbackTaskTitle(rawText string) string {
	clean := strings.Join(strings.Fields(strings.TrimSpace(rawText)), " ")
	if clean == "" {
		return "Nova tarefa"
	}

	for _, sep := range []string{".", ";", ",", "\n"} {
		if idx := strings.Index(clean, sep); idx > 0 {
			clean = strings.TrimSpace(clean[:idx])
			break
		}
	}

	const maxLen = 120
	runes := []rune(clean)
	if len(runes) > maxLen {
		return string(runes[:maxLen-3]) + "..."
	}
	return clean
}

func (v *AiSchemaValidator) validatePayload(typ string, payload json.RawMessage) (any, error) {
	switch typ {
	case "task":
		return parseTaskPayload(payload)
	case "reminder":
		return parseReminderPayload(payload)
	case "event":
		return parseEventPayload(payload)
	case "shopping":
		return parseShoppingPayload(payload)
	case "note":
		return parseNotePayload(payload)
	case "routine":
		return parseRoutinePayload(payload)
	default:
		return nil, fmt.Errorf("%w: invalid_type", ErrAISchemaInvalid)
	}
}

func parseTaskPayload(payload json.RawMessage) (TaskPayload, error) {
	var raw struct {
		DueAt *string `json:"dueAt"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return TaskPayload{}, err
	}

	var dueAt *time.Time
	if raw.DueAt != nil {
		parsed, err := parseRFC3339(*raw.DueAt)
		if err != nil {
			return TaskPayload{}, err
		}
		dueAt = &parsed
	}
	return TaskPayload{DueAt: dueAt}, nil
}

func parseReminderPayload(payload json.RawMessage) (ReminderPayload, error) {
	var raw struct {
		At *string `json:"at"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return ReminderPayload{}, err
	}
	if raw.At == nil || strings.TrimSpace(*raw.At) == "" {
		return ReminderPayload{}, fmt.Errorf("%w: reminder_at_required", ErrAISchemaInvalid)
	}
	parsed, err := parseRFC3339(*raw.At)
	if err != nil {
		return ReminderPayload{}, err
	}
	return ReminderPayload{At: parsed}, nil
}

func parseEventPayload(payload json.RawMessage) (EventPayload, error) {
	var raw struct {
		Start  *string `json:"start"`
		End    *string `json:"end"`
		AllDay *bool   `json:"allDay"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return EventPayload{}, err
	}
	if raw.Start == nil || strings.TrimSpace(*raw.Start) == "" {
		return EventPayload{}, fmt.Errorf("%w: event_start_required", ErrAISchemaInvalid)
	}
	start, err := parseRFC3339(*raw.Start)
	if err != nil {
		return EventPayload{}, err
	}
	var endPtr *time.Time
	if raw.End != nil && strings.TrimSpace(*raw.End) != "" {
		end, err := parseRFC3339(*raw.End)
		if err != nil {
			return EventPayload{}, err
		}
		if end.Before(start) {
			return EventPayload{}, fmt.Errorf("%w: event_end_before_start", ErrAISchemaInvalid)
		}
		endPtr = &end
	}

	allDay := false
	if raw.AllDay != nil {
		allDay = *raw.AllDay
	}
	return EventPayload{Start: start, End: endPtr, AllDay: allDay}, nil
}

func parseShoppingPayload(payload json.RawMessage) (ShoppingPayload, error) {
	var raw struct {
		Items []struct {
			Title    string  `json:"title"`
			Quantity *string `json:"quantity"`
		} `json:"items"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return ShoppingPayload{}, err
	}
	if len(raw.Items) == 0 {
		return ShoppingPayload{}, fmt.Errorf("%w: shopping_items_required", ErrAISchemaInvalid)
	}

	items := make([]ShoppingItemPayload, 0, len(raw.Items))
	for _, item := range raw.Items {
		if strings.TrimSpace(item.Title) == "" {
			return ShoppingPayload{}, fmt.Errorf("%w: shopping_item_title_required", ErrAISchemaInvalid)
		}
		items = append(items, ShoppingItemPayload{Title: item.Title, Quantity: item.Quantity})
	}

	return ShoppingPayload{Items: items}, nil
}

func parseNotePayload(payload json.RawMessage) (NotePayload, error) {
	var raw struct {
		Content string `json:"content"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return NotePayload{}, err
	}
	if strings.TrimSpace(raw.Content) == "" {
		return NotePayload{}, fmt.Errorf("%w: note_content_required", ErrAISchemaInvalid)
	}
	return NotePayload{Content: raw.Content}, nil
}

func parseRoutinePayload(payload json.RawMessage) (RoutinePayload, error) {
	var raw struct {
		Weekdays       []int   `json:"weekdays"`
		StartTime      string  `json:"startTime"`
		EndTime        string  `json:"endTime"`
		RecurrenceType string  `json:"recurrenceType"`
		WeekOfMonth    *int    `json:"weekOfMonth"`
		StartsOn       *string `json:"startsOn"`
		EndsOn         *string `json:"endsOn"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return RoutinePayload{}, err
	}

	if len(raw.Weekdays) == 0 {
		return RoutinePayload{}, fmt.Errorf("%w: routine_weekdays_required", ErrAISchemaInvalid)
	}
	if raw.StartTime == "" {
		return RoutinePayload{}, fmt.Errorf("%w: routine_start_time_required", ErrAISchemaInvalid)
	}
	if raw.EndTime == "" {
		return RoutinePayload{}, fmt.Errorf("%w: routine_end_time_required", ErrAISchemaInvalid)
	}

	validRecurrenceTypes := map[string]bool{
		"weekly":       true,
		"biweekly":     true,
		"triweekly":    true,
		"monthly_week": true,
	}
	if raw.RecurrenceType == "" {
		raw.RecurrenceType = "weekly"
	}
	if !validRecurrenceTypes[raw.RecurrenceType] {
		return RoutinePayload{}, fmt.Errorf("%w: routine_invalid_recurrence_type", ErrAISchemaInvalid)
	}

	return RoutinePayload{
		Weekdays:       raw.Weekdays,
		StartTime:      raw.StartTime,
		EndTime:        raw.EndTime,
		RecurrenceType: raw.RecurrenceType,
		WeekOfMonth:    raw.WeekOfMonth,
		StartsOn:       raw.StartsOn,
		EndsOn:         raw.EndsOn,
	}, nil
}

func decodeStrict(payload json.RawMessage, target any) error {
	dec := json.NewDecoder(bytes.NewReader(payload))
	dec.DisallowUnknownFields()
	if err := dec.Decode(target); err != nil {
		return fmt.Errorf("%w: %s", ErrAISchemaInvalid, err.Error())
	}
	return nil
}

func parseRFC3339(value string) (time.Time, error) {
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		if parsedNano, errNano := time.Parse(time.RFC3339Nano, value); errNano == nil {
			return parsedNano, nil
		}
		return time.Time{}, fmt.Errorf("%w: invalid_timestamp", ErrAISchemaInvalid)
	}
	return parsed, nil
}
