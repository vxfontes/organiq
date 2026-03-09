package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type NotificationsHandler struct {
	Usecase *usecase.NotificationUsecase
}

func NewNotificationsHandler(uc *usecase.NotificationUsecase) *NotificationsHandler {
	return &NotificationsHandler{Usecase: uc}
}

// GetPreferences returns user notification preferences.
// @Summary Buscar preferências de notificação
// @Tags Notifications
// @Security BearerAuth
// @Produce json
// @Success 200 {object} dto.NotificationPreferencesResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/notification-preferences [get]
func (h *NotificationsHandler) GetPreferences(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	prefs, err := h.Usecase.GetPreferences(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toNotificationPreferencesResponse(prefs))
}

// UpdatePreferences updates user notification preferences.
// @Summary Atualizar preferências de notificação
// @Tags Notifications
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.UpdateNotificationPreferencesRequest true "Update preferences request"
// @Success 200 {object} dto.NotificationPreferencesResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/notification-preferences [put]
func (h *NotificationsHandler) GetDailySummaryToken(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	token, err := h.Usecase.GetDailySummaryToken(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	// Keep it relative; client can prepend API_HOST.
	url := "/v1/daily-summary?token=" + token
	c.JSON(http.StatusOK, dto.DailySummaryTokenResponse{Token: token, Url: url})
}

func (h *NotificationsHandler) RotateDailySummaryToken(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	token, err := h.Usecase.RotateDailySummaryToken(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	url := "/v1/daily-summary?token=" + token
	c.JSON(http.StatusOK, dto.DailySummaryTokenResponse{Token: token, Url: url})
}

func (h *NotificationsHandler) UpdatePreferences(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.UpdateNotificationPreferencesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	err := h.Usecase.UpdatePreferences(c.Request.Context(), userID, func(prefs *domain.NotificationPreferences) {
		if req.RemindersEnabled != nil {
			prefs.RemindersEnabled = *req.RemindersEnabled
		}
		if req.ReminderAtTime != nil {
			prefs.ReminderAtTime = *req.ReminderAtTime
		}
		if req.ReminderLeadMins != nil {
			prefs.ReminderLeadMins = *req.ReminderLeadMins
		}
		if req.EventsEnabled != nil {
			prefs.EventsEnabled = *req.EventsEnabled
		}
		if req.EventAtTime != nil {
			prefs.EventAtTime = *req.EventAtTime
		}
		if req.EventLeadMins != nil {
			prefs.EventLeadMins = *req.EventLeadMins
		}
		if req.TasksEnabled != nil {
			prefs.TasksEnabled = *req.TasksEnabled
		}
		if req.TaskAtTime != nil {
			prefs.TaskAtTime = *req.TaskAtTime
		}
		if req.TaskLeadMins != nil {
			prefs.TaskLeadMins = *req.TaskLeadMins
		}
		if req.RoutinesEnabled != nil {
			prefs.RoutinesEnabled = *req.RoutinesEnabled
		}
		if req.RoutineAtTime != nil {
			prefs.RoutineAtTime = *req.RoutineAtTime
		}
		if req.RoutineLeadMins != nil {
			prefs.RoutineLeadMins = *req.RoutineLeadMins
		}
		if req.QuietHoursEnabled != nil {
			prefs.QuietHoursEnabled = *req.QuietHoursEnabled
		}
		if req.QuietStart != nil {
			prefs.QuietStart = req.QuietStart
		}
		if req.QuietEnd != nil {
			prefs.QuietEnd = req.QuietEnd
		}
		if req.DailyDigestEnabled != nil {
			prefs.DailyDigestEnabled = *req.DailyDigestEnabled
		}
		if req.DailyDigestHour != nil {
			prefs.DailyDigestHour = *req.DailyDigestHour
		}
	})

	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	// Fetch updated prefs to return
	prefs, err := h.Usecase.GetPreferences(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toNotificationPreferencesResponse(prefs))
}

// ListNotifications returns user notification log.
// @Summary Listar notificações
// @Tags Notifications
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param offset query int false "Offset"
// @Success 200 {object} dto.ListNotificationsResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/notifications [get]
func (h *NotificationsHandler) ListNotifications(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	if limit < 1 {
		limit = 20
	}
	if limit > 200 {
		limit = 200
	}
	if offset < 0 {
		offset = 0
	}

	logs, err := h.Usecase.ListNotifications(c.Request.Context(), userID, limit, offset)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	items := make([]dto.NotificationLogResponse, len(logs))
	for i, l := range logs {
		items[i] = toNotificationLogResponse(l)
	}

	c.JSON(http.StatusOK, dto.ListNotificationsResponse{
		Items: items,
	})
}

// MarkAsRead marks a notification as read.
// @Summary Marcar notificação como lida
// @Tags Notifications
// @Security BearerAuth
// @Param id path string true "Notification ID"
// @Success 200 {object} map[string]string
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/notifications/{id}/read [patch]
func (h *NotificationsHandler) MarkAsRead(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")
	err := h.Usecase.MarkAsRead(c.Request.Context(), id, userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// MarkAllAsRead marks all user notifications as read.
// @Summary Marcar todas como lidas
// @Tags Notifications
// @Security BearerAuth
// @Success 200 {object} map[string]string
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/notifications/read-all [patch]
func (h *NotificationsHandler) MarkAllAsRead(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	err := h.Usecase.MarkAllAsRead(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// SendTestNotification sends a test push to user devices.
// @Summary Enviar notificação de teste
// @Tags Notifications
// @Security BearerAuth
// @Produce json
// @Success 200 {object} map[string]string
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/notifications/test [post]
func (h *NotificationsHandler) SendTestNotification(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	err := h.Usecase.SendTestNotification(c.Request.Context(), userID)
	if err != nil {
		errMsg := err.Error()
		if errMsg == "no_active_devices" {
			writeError(c, http.StatusBadRequest, "no_active_devices")
			return
		}
		// Log detail server-side; keep client contract stable.
		c.Error(err)
		writeError(c, http.StatusBadGateway, "notification_send_failed")
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func toNotificationPreferencesResponse(p domain.NotificationPreferences) dto.NotificationPreferencesResponse {
	return dto.NotificationPreferencesResponse{
		RemindersEnabled:  p.RemindersEnabled,
		ReminderAtTime:    p.ReminderAtTime,
		ReminderLeadMins:  p.ReminderLeadMins,
		EventsEnabled:     p.EventsEnabled,
		EventAtTime:       p.EventAtTime,
		EventLeadMins:     p.EventLeadMins,
		TasksEnabled:      p.TasksEnabled,
		TaskAtTime:        p.TaskAtTime,
		TaskLeadMins:      p.TaskLeadMins,
		RoutinesEnabled:   p.RoutinesEnabled,
		RoutineAtTime:     p.RoutineAtTime,
		RoutineLeadMins:   p.RoutineLeadMins,
		QuietHoursEnabled: p.QuietHoursEnabled,
		QuietStart:        p.QuietStart,
		QuietEnd:          p.QuietEnd,
		DailyDigestEnabled: p.DailyDigestEnabled,
		DailyDigestHour:    p.DailyDigestHour,
		UpdatedAt:         p.UpdatedAt,
	}
}

func toNotificationLogResponse(l domain.NotificationLog) dto.NotificationLogResponse {
	return dto.NotificationLogResponse{
		ID:           l.ID,
		Type:         string(l.Type),
		ReferenceID:  l.ReferenceID,
		Title:        l.Title,
		Body:         l.Body,
		LeadMins:     l.LeadMins,
		Status:       string(l.Status),
		ScheduledFor: l.ScheduledFor,
		SentAt:       l.SentAt,
		ReadAt:       l.ReadAt,
		CreatedAt:    l.CreatedAt,
	}
}
