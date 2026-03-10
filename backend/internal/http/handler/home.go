package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type HomeHandler struct {
	Home *usecase.HomeUsecase
}

func NewHomeHandler(home *usecase.HomeUsecase) *HomeHandler {
	return &HomeHandler{Home: home}
}

// GetDashboard returns consolidated home data.
// @Summary Dashboard consolidado da Home
// @Tags Home
// @Security BearerAuth
// @Produce json
// @Success 200 {object} dto.HomeDashboardResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 500 {object} dto.ErrorResponse
// @Router /v1/home/dashboard [get]
func (h *HomeHandler) GetDashboard(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	if h.Home == nil {
		writeUsecaseError(c, usecase.ErrDependencyMissing)
		return
	}

	dashboard, err := h.Home.GetDashboard(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	focusTasks := make([]dto.TaskResponse, 0, len(dashboard.FocusTasks))
	for _, task := range dashboard.FocusTasks {
		focusTasks = append(focusTasks, toTaskResponse(task, nil, nil, nil))
	}

	timeline := make([]dto.HomeTimelineItemResponse, 0, len(dashboard.Timeline))
	for _, item := range dashboard.Timeline {
		timeline = append(timeline, dto.HomeTimelineItemResponse{
			ID:               item.ID,
			ItemType:         item.ItemType,
			Title:            item.Title,
			Subtitle:         item.Subtitle,
			ScheduledTime:    item.ScheduledTime,
			EndScheduledTime: item.EndScheduledTime,
			IsCompleted:      item.IsCompleted,
			IsOverdue:        item.IsOverdue,
		})
	}

	shopping := make([]dto.HomeShoppingPreviewResponse, 0, len(dashboard.ShoppingPreview))
	for _, item := range dashboard.ShoppingPreview {
		shopping = append(shopping, dto.HomeShoppingPreviewResponse{
			ID:           item.ID,
			Title:        item.Title,
			TotalItems:   item.TotalItems,
			PendingItems: item.PendingItems,
			PreviewItems: item.PreviewItems,
		})
	}

	resp := dto.HomeDashboardResponse{
		DayProgress: dto.HomeDayProgressResponse{
			RoutinesDone:    dashboard.DayProgress.RoutinesDone,
			RoutinesTotal:   dashboard.DayProgress.RoutinesTotal,
			TasksDone:       dashboard.DayProgress.TasksDone,
			TasksTotal:      dashboard.DayProgress.TasksTotal,
			ProgressPercent: dashboard.DayProgress.ProgressPercent,
		},
		Timeline:            timeline,
		ShoppingPreview:     shopping,
		WeekDensity:         dashboard.WeekDensity,
		FocusTasks:          focusTasks,
		EventsTodayCount:    dashboard.EventsTodayCount,
		RemindersTodayCount: dashboard.RemindersTodayCount,
	}

	if dashboard.Insight != nil {
		resp.Insight = &dto.HomeInsightResponse{
			Title:   dashboard.Insight.Title,
			Summary: dashboard.Insight.Summary,
			Footer:  dashboard.Insight.Footer,
			IsFocus: dashboard.Insight.IsFocus,
		}
	}

	c.JSON(http.StatusOK, resp)
}
