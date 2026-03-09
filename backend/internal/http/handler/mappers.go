package handler

import (
	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/http/dto"
)

func toFlagResponse(flag domain.Flag) dto.FlagResponse {
	return dto.FlagResponse{
		ID:        flag.ID,
		Name:      flag.Name,
		Color:     flag.Color,
		SortOrder: flag.SortOrder,
		CreatedAt: flag.CreatedAt,
		UpdatedAt: flag.UpdatedAt,
	}
}

func toFlagObject(flag domain.Flag) dto.FlagObject {
	return dto.FlagObject{
		ID:    flag.ID,
		Name:  flag.Name,
		Color: flag.Color,
	}
}

func toSubflagObject(subflag domain.Subflag, flag *domain.Flag) dto.SubflagObject {
	var color *string
	if flag != nil {
		color = flag.Color
	}
	return dto.SubflagObject{
		ID:    subflag.ID,
		Name:  subflag.Name,
		Color: color,
	}
}

func toSubflagResponse(subflag domain.Subflag, flag *domain.Flag) dto.SubflagResponse {
	var flagObj *dto.FlagObject
	if flag != nil {
		obj := toFlagObject(*flag)
		flagObj = &obj
	}
	var color *string
	if flag != nil {
		color = flag.Color
	}
	return dto.SubflagResponse{
		ID:        subflag.ID,
		Flag:      flagObj,
		Name:      subflag.Name,
		Color:     color,
		SortOrder: subflag.SortOrder,
		CreatedAt: subflag.CreatedAt,
		UpdatedAt: subflag.UpdatedAt,
	}
}

func toContextRuleResponse(rule domain.ContextRule, flag *domain.Flag, subflag *domain.Subflag) dto.ContextRuleResponse {
	var flagObj *dto.FlagObject
	if flag != nil {
		obj := toFlagObject(*flag)
		flagObj = &obj
	}
	var subflagObj *dto.SubflagObject
	if subflag != nil {
		obj := toSubflagObject(*subflag, flag)
		subflagObj = &obj
	}
	return dto.ContextRuleResponse{
		ID:        rule.ID,
		Keyword:   rule.Keyword,
		Flag:      flagObj,
		Subflag:   subflagObj,
		CreatedAt: rule.CreatedAt,
		UpdatedAt: rule.UpdatedAt,
	}
}

func toSuggestionResponse(suggestion domain.AiSuggestion, flag *domain.Flag, subflag *domain.Subflag) dto.AiSuggestionResponse {
	var flagObj *dto.FlagObject
	if flag != nil {
		obj := toFlagObject(*flag)
		flagObj = &obj
	}
	var subflagObj *dto.SubflagObject
	if subflag != nil {
		obj := toSubflagObject(*subflag, flag)
		subflagObj = &obj
	}
	return dto.AiSuggestionResponse{
		ID:          suggestion.ID,
		Type:        string(suggestion.Type),
		Title:       suggestion.Title,
		Confidence:  suggestion.Confidence,
		Flag:        flagObj,
		Subflag:     subflagObj,
		NeedsReview: suggestion.NeedsReview,
		Payload:     suggestion.PayloadJSON,
		CreatedAt:   suggestion.CreatedAt,
	}
}

func toInboxItemResponse(item domain.InboxItem, suggestion *dto.AiSuggestionResponse) dto.InboxItemResponse {
	return dto.InboxItemResponse{
		ID:          item.ID,
		Source:      string(item.Source),
		RawText:     item.RawText,
		RawMediaURL: item.RawMediaURL,
		Status:      string(item.Status),
		LastError:   item.LastError,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
		Suggestion:  suggestion,
	}
}

func toInboxItemObject(item domain.InboxItem) dto.InboxItemObject {
	return dto.InboxItemObject{
		ID:          item.ID,
		Source:      string(item.Source),
		RawText:     item.RawText,
		RawMediaURL: item.RawMediaURL,
		Status:      string(item.Status),
		LastError:   item.LastError,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
	}
}

func toTaskResponse(task domain.Task, source *domain.InboxItem, flag *domain.Flag, subflag *domain.Subflag) dto.TaskResponse {
	var sourceObj *dto.InboxItemObject
	if source != nil {
		obj := toInboxItemObject(*source)
		sourceObj = &obj
	}
	var flagObj *dto.FlagObject
	if flag != nil {
		obj := toFlagObject(*flag)
		flagObj = &obj
	}
	var subflagObj *dto.SubflagObject
	if subflag != nil {
		obj := toSubflagObject(*subflag, flag)
		subflagObj = &obj
	}
	return dto.TaskResponse{
		ID:              task.ID,
		Title:           task.Title,
		Description:     task.Description,
		Status:          string(task.Status),
		DueAt:           task.DueAt,
		Flag:            flagObj,
		Subflag:         subflagObj,
		SourceInboxItem: sourceObj,
		CreatedAt:       task.CreatedAt,
		UpdatedAt:       task.UpdatedAt,
	}
}

func toReminderResponse(reminder domain.Reminder, source *domain.InboxItem, flag *domain.Flag, subflag *domain.Subflag) dto.ReminderResponse {
	var sourceObj *dto.InboxItemObject
	if source != nil {
		obj := toInboxItemObject(*source)
		sourceObj = &obj
	}
	var flagObj *dto.FlagObject
	if flag != nil {
		obj := toFlagObject(*flag)
		flagObj = &obj
	}
	var subflagObj *dto.SubflagObject
	if subflag != nil {
		obj := toSubflagObject(*subflag, flag)
		subflagObj = &obj
	}
	return dto.ReminderResponse{
		ID:              reminder.ID,
		Title:           reminder.Title,
		Status:          string(reminder.Status),
		RemindAt:        reminder.RemindAt,
		Flag:            flagObj,
		Subflag:         subflagObj,
		SourceInboxItem: sourceObj,
		CreatedAt:       reminder.CreatedAt,
		UpdatedAt:       reminder.UpdatedAt,
	}
}

func toEventResponse(event domain.Event, source *domain.InboxItem, flag *domain.Flag, subflag *domain.Subflag) dto.EventResponse {
	var sourceObj *dto.InboxItemObject
	if source != nil {
		obj := toInboxItemObject(*source)
		sourceObj = &obj
	}
	var flagObj *dto.FlagObject
	if flag != nil {
		obj := toFlagObject(*flag)
		flagObj = &obj
	}
	var subflagObj *dto.SubflagObject
	if subflag != nil {
		obj := toSubflagObject(*subflag, flag)
		subflagObj = &obj
	}
	return dto.EventResponse{
		ID:              event.ID,
		Title:           event.Title,
		StartAt:         event.StartAt,
		EndAt:           event.EndAt,
		AllDay:          event.AllDay,
		Location:        event.Location,
		Flag:            flagObj,
		Subflag:         subflagObj,
		SourceInboxItem: sourceObj,
		CreatedAt:       event.CreatedAt,
		UpdatedAt:       event.UpdatedAt,
	}
}

func toShoppingListObject(list domain.ShoppingList) dto.ShoppingListObject {
	return dto.ShoppingListObject{
		ID:     list.ID,
		Title:  list.Title,
		Status: string(list.Status),
	}
}

func toShoppingListResponse(list domain.ShoppingList, source *domain.InboxItem) dto.ShoppingListResponse {
	var sourceObj *dto.InboxItemObject
	if source != nil {
		obj := toInboxItemObject(*source)
		sourceObj = &obj
	}
	return dto.ShoppingListResponse{
		ID:              list.ID,
		Title:           list.Title,
		Status:          string(list.Status),
		SourceInboxItem: sourceObj,
		CreatedAt:       list.CreatedAt,
		UpdatedAt:       list.UpdatedAt,
	}
}

func toShoppingItemResponse(item domain.ShoppingItem, list *domain.ShoppingList) dto.ShoppingItemResponse {
	var listObj *dto.ShoppingListObject
	if list != nil {
		obj := toShoppingListObject(*list)
		listObj = &obj
	}
	return dto.ShoppingItemResponse{
		ID:        item.ID,
		List:      listObj,
		Title:     item.Title,
		Quantity:  item.Quantity,
		Checked:   item.Checked,
		SortOrder: item.SortOrder,
		CreatedAt: item.CreatedAt,
		UpdatedAt: item.UpdatedAt,
	}
}

func toRoutineResponse(routine domain.Routine, flag *domain.Flag, subflag *domain.Subflag) dto.RoutineResponse {
	var flagObj *dto.FlagObject
	if flag != nil {
		obj := toFlagObject(*flag)
		flagObj = &obj
	}
	var subflagObj *dto.SubflagObject
	if subflag != nil {
		obj := toSubflagObject(*subflag, flag)
		subflagObj = &obj
	}
	return dto.RoutineResponse{
		ID:               routine.ID,
		Title:            routine.Title,
		Description:      routine.Description,
		RecurrenceType:   routine.RecurrenceType,
		Weekdays:         routine.Weekdays,
		StartTime:        routine.StartTime,
		EndTime:          routine.EndTime,
		WeekOfMonth:      routine.WeekOfMonth,
		StartsOn:         routine.StartsOn,
		EndsOn:           routine.EndsOn,
		Color:            routine.Color,
		IsActive:         routine.IsActive,
		IsCompletedToday: routine.IsCompletedToday,
		Flag:             flagObj,
		Subflag:          subflagObj,
		CreatedAt:        routine.CreatedAt,
		UpdatedAt:        routine.UpdatedAt,
	}
}
