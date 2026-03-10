package http

import (
	"log/slog"

	"github.com/gin-gonic/gin"
	ginSwagger "github.com/swaggo/gin-swagger"
	swaggerFiles "github.com/tylfin/gin-swagger-files"

	"inbota/backend/internal/config"
	"inbota/backend/internal/http/handler"
	"inbota/backend/internal/http/middleware"
)

// NewRouter wires handlers and middleware.
func NewRouter(cfg config.Config, log *slog.Logger, authHandler *handler.AuthHandler, apiHandlers *handler.APIHandlers, readinessCheckers ...handler.Checker) *gin.Engine {
	engine := gin.New()
	engine.Use(gin.Recovery())
	engine.Use(middleware.RequestID(cfg.RequestIDHeader))
	engine.Use(middleware.Logging(log))

	engine.GET("/healthz", handler.HealthHandler)
	engine.GET("/readyz", handler.ReadinessHandler(readinessCheckers...))
	engine.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	v1 := engine.Group("/v1")

	v1.GET("/healthz", handler.HealthHandler)

	// Public daily summary endpoint (token-based, no JWT)
	if apiHandlers != nil && apiHandlers.Digest != nil {
		v1.GET("/daily-summary", apiHandlers.Digest.GetDailySummary)
	}
	if authHandler != nil {
		v1.POST("/auth/signup", authHandler.Signup)
		v1.POST("/auth/login", authHandler.Login)
	}

	authGroup := v1.Group("", middleware.Auth(cfg.JWTSecret))
	if apiHandlers != nil {
		if apiHandlers.Me != nil {
			authGroup.GET("/me", apiHandlers.Me.Me)
		}
		if apiHandlers.Flags != nil {
			authGroup.GET("/flags", apiHandlers.Flags.List)
			authGroup.POST("/flags", apiHandlers.Flags.Create)
			authGroup.PATCH("/flags/:id", apiHandlers.Flags.Update)
			authGroup.DELETE("/flags/:id", apiHandlers.Flags.Delete)
		}
		if apiHandlers.Subflags != nil {
			authGroup.GET("/flags/:id/subflags", apiHandlers.Subflags.ListByFlag)
			authGroup.POST("/flags/:id/subflags", apiHandlers.Subflags.Create)
			authGroup.PATCH("/subflags/:id", apiHandlers.Subflags.Update)
			authGroup.DELETE("/subflags/:id", apiHandlers.Subflags.Delete)
		}
		if apiHandlers.ContextRules != nil {
			authGroup.GET("/context-rules", apiHandlers.ContextRules.List)
			authGroup.POST("/context-rules", apiHandlers.ContextRules.Create)
			authGroup.PATCH("/context-rules/:id", apiHandlers.ContextRules.Update)
			authGroup.DELETE("/context-rules/:id", apiHandlers.ContextRules.Delete)
		}
		if apiHandlers.Inbox != nil {
			authGroup.GET("/inbox-items", apiHandlers.Inbox.List)
			authGroup.POST("/inbox-items", apiHandlers.Inbox.Create)
			authGroup.GET("/inbox-items/:id", apiHandlers.Inbox.Get)
			authGroup.POST("/inbox-items/:id/reprocess", apiHandlers.Inbox.Reprocess)
			authGroup.POST("/inbox-items/:id/confirm", apiHandlers.Inbox.Confirm)
			authGroup.POST("/inbox-items/:id/dismiss", apiHandlers.Inbox.Dismiss)
		}
		if apiHandlers.Agenda != nil {
			authGroup.GET("/agenda", apiHandlers.Agenda.List)
		}
		if apiHandlers.Home != nil {
			authGroup.GET("/home/dashboard", apiHandlers.Home.GetDashboard)
		}
		if apiHandlers.Tasks != nil {
			authGroup.GET("/tasks", apiHandlers.Tasks.List)
			authGroup.POST("/tasks", apiHandlers.Tasks.Create)
			authGroup.PATCH("/tasks/:id", apiHandlers.Tasks.Update)
			authGroup.DELETE("/tasks/:id", apiHandlers.Tasks.Delete)
		}
		if apiHandlers.Reminders != nil {
			authGroup.GET("/reminders", apiHandlers.Reminders.List)
			authGroup.POST("/reminders", apiHandlers.Reminders.Create)
			authGroup.PATCH("/reminders/:id", apiHandlers.Reminders.Update)
			authGroup.DELETE("/reminders/:id", apiHandlers.Reminders.Delete)
		}
		if apiHandlers.Events != nil {
			authGroup.GET("/events", apiHandlers.Events.List)
			authGroup.POST("/events", apiHandlers.Events.Create)
			authGroup.PATCH("/events/:id", apiHandlers.Events.Update)
			authGroup.DELETE("/events/:id", apiHandlers.Events.Delete)
		}
		if apiHandlers.ShoppingLists != nil {
			authGroup.GET("/shopping-lists", apiHandlers.ShoppingLists.List)
			authGroup.POST("/shopping-lists", apiHandlers.ShoppingLists.Create)
			authGroup.PATCH("/shopping-lists/:id", apiHandlers.ShoppingLists.Update)
			authGroup.DELETE("/shopping-lists/:id", apiHandlers.ShoppingLists.Delete)
		}
		if apiHandlers.ShoppingItems != nil {
			authGroup.GET("/shopping-lists/:id/items", apiHandlers.ShoppingItems.ListByList)
			authGroup.POST("/shopping-lists/:id/items", apiHandlers.ShoppingItems.Create)
			authGroup.PATCH("/shopping-items/:id", apiHandlers.ShoppingItems.Update)
			authGroup.DELETE("/shopping-items/:id", apiHandlers.ShoppingItems.Delete)
		}
		if apiHandlers.Routines != nil {
			authGroup.GET("/routines", apiHandlers.Routines.List)
			authGroup.GET("/routines/day/:weekday", apiHandlers.Routines.ListByWeekday)
			authGroup.GET("/routines/today/summary", apiHandlers.Routines.GetTodaySummary)
			authGroup.GET("/routines/:id", apiHandlers.Routines.Get)
			authGroup.POST("/routines", apiHandlers.Routines.Create)
			authGroup.PATCH("/routines/:id", apiHandlers.Routines.Update)
			authGroup.DELETE("/routines/:id", apiHandlers.Routines.Delete)
			authGroup.PATCH("/routines/:id/toggle", apiHandlers.Routines.Toggle)
			authGroup.POST("/routines/:id/complete", apiHandlers.Routines.Complete)
			authGroup.DELETE("/routines/:id/complete/:date", apiHandlers.Routines.Uncomplete)
			authGroup.GET("/routines/:id/history", apiHandlers.Routines.GetHistory)
			authGroup.GET("/routines/:id/streak", apiHandlers.Routines.GetStreak)
			authGroup.POST("/routines/:id/exceptions", apiHandlers.Routines.CreateException)
			authGroup.DELETE("/routines/:id/exceptions/:date", apiHandlers.Routines.DeleteException)
		}
		if apiHandlers.Devices != nil {
			authGroup.POST("/devices/token", apiHandlers.Devices.RegisterToken)
			authGroup.DELETE("/devices/token", apiHandlers.Devices.UnregisterToken)
		}
		if apiHandlers.Notifications != nil {
			authGroup.GET("/notification-preferences", apiHandlers.Notifications.GetPreferences)
			authGroup.PUT("/notification-preferences", apiHandlers.Notifications.UpdatePreferences)
			authGroup.GET("/notification-preferences/daily-summary-token", apiHandlers.Notifications.GetDailySummaryToken)
			authGroup.POST("/notification-preferences/daily-summary-token/rotate", apiHandlers.Notifications.RotateDailySummaryToken)
			authGroup.GET("/notifications", apiHandlers.Notifications.ListNotifications)
			authGroup.POST("/notifications/test", apiHandlers.Notifications.SendTestNotification)
			authGroup.PATCH("/notifications/:id/read", apiHandlers.Notifications.MarkAsRead)
			authGroup.PATCH("/notifications/read-all", apiHandlers.Notifications.MarkAllAsRead)
		}
		if apiHandlers.Digest != nil {
			authGroup.POST("/digest/test", apiHandlers.Digest.SendTestEmail)
		}
	}

	return engine
}
