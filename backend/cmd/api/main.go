// @title Inbota API
// @version 0.1
// @description API do MVP Inbota.
// @BasePath /
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Formato: Bearer <token>
package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"

	_ "inbota/backend/docs"
	"inbota/backend/internal/app/digest"
	"inbota/backend/internal/app/service"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/config"
	inbotahttp "inbota/backend/internal/http"
	"inbota/backend/internal/http/handler"
	"inbota/backend/internal/infra/ai"
	"inbota/backend/internal/infra/mailer"
	"inbota/backend/internal/infra/postgres"
	"inbota/backend/internal/infra/push"
	"inbota/backend/internal/observability"
	"inbota/backend/internal/scheduler"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, "config_load_error:", err.Error())
		os.Exit(1)
	}

	log := observability.NewLogger(cfg.LogLevel)
	slog.SetDefault(log)

	if cfg.Env == "prod" {
		gin.SetMode(gin.ReleaseMode)
	}

	ctx := context.Background()
	var db *postgres.DB
	if cfg.DatabaseURL != "" {
		var err error
		db, err = postgres.NewDB(ctx, cfg.DatabaseURL)
		if err != nil {
			log.Error("db_connect_error", slog.String("error", err.Error()))
			os.Exit(1)
		}
		log.Info("db_connected")
	}

	var authHandler *handler.AuthHandler
	var apiHandlers *handler.APIHandlers
	if db != nil {
		if cfg.JWTSecret == "" {
			log.Error("jwt_secret_missing")
			os.Exit(1)
		}
		userRepo := postgres.NewUserRepository(db)
		authSvc := service.NewAuthService(cfg.JWTSecret, usecase.DefaultTokenTTL)

		deviceTokenRepo := postgres.NewDeviceTokenRepository(db)
		notificationPrefsRepo := postgres.NewNotificationPreferencesRepository(db)
		notificationLogRepo := postgres.NewNotificationLogRepository(db)
		notificationTemplateRepo := postgres.NewNotificationTemplateRepository(db)
		appConfigRepo := postgres.NewAppConfigRepository(db)
		emailDigestRepo := postgres.NewEmailDigestRepository(db)

		authUC := &usecase.AuthUsecase{
			Users:             userRepo,
			Auth:              authSvc,
			NotificationPrefs: notificationPrefsRepo,
		}
		authHandler = handler.NewAuthHandler(authUC)

		flagRepo := postgres.NewFlagRepository(db)
		subflagRepo := postgres.NewSubflagRepository(db)
		ruleRepo := postgres.NewContextRuleRepository(db)
		inboxRepo := postgres.NewInboxRepository(db)
		suggestionRepo := postgres.NewAiSuggestionRepository(db)
		taskRepo := postgres.NewTaskRepository(db)
		reminderRepo := postgres.NewReminderRepository(db)
		eventRepo := postgres.NewEventRepository(db)
		shoppingListRepo := postgres.NewShoppingListRepository(db)
		shoppingItemRepo := postgres.NewShoppingItemRepository(db)
		routineRepo := postgres.NewRoutineRepository(db)
		routineExceptionRepo := postgres.NewRoutineExceptionRepository(db)
		routineCompletionRepo := postgres.NewRoutineCompletionRepository(db)
		agendaRepo := postgres.NewAgendaRepository(db)
		homeRepo := postgres.NewHomeRepository(db)

		flagUC := &usecase.FlagUsecase{Flags: flagRepo}
		subflagUC := &usecase.SubflagUsecase{Subflags: subflagRepo, Flags: flagRepo}
		ruleUC := &usecase.ContextRuleUsecase{Rules: ruleRepo, Flags: flagRepo, Subflags: subflagRepo}
		taskUC := &usecase.TaskUsecase{Tasks: taskRepo, Flags: flagRepo, Subflags: subflagRepo}
		reminderUC := &usecase.ReminderUsecase{
			Reminders: reminderRepo,
			Flags:     flagRepo,
			Subflags:  subflagRepo,
		}
		eventUC := &usecase.EventUsecase{
			Events:   eventRepo,
			Flags:    flagRepo,
			Subflags: subflagRepo,
		}
		shoppingListUC := &usecase.ShoppingListUsecase{Lists: shoppingListRepo}
		shoppingItemUC := &usecase.ShoppingItemUsecase{Items: shoppingItemRepo}
		routineUC := &usecase.RoutineUsecase{
			Routines:    routineRepo,
			Exceptions:  routineExceptionRepo,
			Completions: routineCompletionRepo,
			Users:       userRepo,
			Flags:       flagRepo,
			Subflags:    subflagRepo,
		}
		agendaUC := usecase.NewAgendaUsecase(agendaRepo)
		homeUC := &usecase.HomeUsecase{
			Home:     homeRepo,
			Agenda:   agendaRepo,
			Routines: routineUC,
			Users:    userRepo,
		}
		deviceTokenUC := &usecase.DeviceTokenUsecase{DeviceTokens: deviceTokenRepo}
		txRunner := postgres.NewTxRunner(db)

		var aiClient service.AIClient
		if cfg.AIAPIKey != "" || cfg.AIBaseURL != "" || cfg.AIModel != "" || cfg.AIProvider != "" {
			client, err := ai.NewClient(cfg)
			if err != nil {
				log.Error("ai_client_error", slog.String("error", err.Error()))
			} else {
				aiClient = client
				provider := cfg.AIProvider
				if provider == "" {
					provider = ai.ProviderGroq
				}
				log.Info("ai_client_ready", slog.String("provider", provider), slog.String("model", cfg.AIModel))
			}
		}

		inboxUC := &usecase.InboxUsecase{
			Users:           userRepo,
			Inbox:           inboxRepo,
			Suggestions:     suggestionRepo,
			Flags:           flagRepo,
			Subflags:        subflagRepo,
			ContextRules:    ruleRepo,
			Tasks:           taskRepo,
			Reminders:       reminderRepo,
			Events:          eventRepo,
			ShoppingLists:   shoppingListRepo,
			ShoppingItems:   shoppingItemRepo,
			RoutinesUsecase: routineUC,
			PromptBuilder:   service.NewPromptBuilder(),
			AIClient:        aiClient,
			SchemaValidator: service.NewAiSchemaValidator(),
			RuleMatcher:     service.NewContextRuleMatcher(),
			TxRunner:        txRunner,
		}

		// ntfy.sh client
		ntfyClient := push.NewNtfyClient("") // default baseURL: https://ntfy.sh
		log.Info("ntfy_client_ready")

		notificationUC := &usecase.NotificationUsecase{
			Prefs:  notificationPrefsRepo,
			Log:    notificationLogRepo,
			Tokens: deviceTokenRepo,
			Config: appConfigRepo,
			Ntfy:   ntfyClient,
		}

		var digestHandler *handler.DigestHandler
		resendMailer := mailer.NewResendMailer(cfg.ResendAPIKey, cfg.ResendFrom)
		digestSvc, err := digest.NewDigestService(
			userRepo,
			notificationPrefsRepo,
			emailDigestRepo,
			routineUC,
			agendaRepo,
			taskRepo,
			shoppingListRepo,
			shoppingItemRepo,
			flagRepo,
			subflagRepo,
			resendMailer,
		)
		if err != nil {
			log.Error("digest_service_init_error", slog.String("error", err.Error()))
		} else {
			digestSvc.SetLogger(log)
			digestHandler = handler.NewDigestHandler(digestSvc)

			// Digest Scheduler (every configured interval)
			go func() {
				ticker := time.NewTicker(cfg.DigestJobInterval)
				defer ticker.Stop()

				log.Info("running_daily_digest_job")
				if err := digestSvc.ProcessPendingDigests(ctx); err != nil {
					log.Error("daily_digest_job_error", slog.String("error", err.Error()))
				}

				for {
					select {
					case <-ctx.Done():
						return
					case <-ticker.C:
						log.Info("running_daily_digest_job")
						if err := digestSvc.ProcessPendingDigests(ctx); err != nil {
							log.Error("daily_digest_job_error", slog.String("error", err.Error()))
						}
					}
				}
			}()
		}

		notifScheduler := &scheduler.NotificationScheduler{
			Prefs:     notificationPrefsRepo,
			Log:       notificationLogRepo,
			Tokens:    deviceTokenRepo,
			Users:     userRepo,
			Reminders: reminderRepo,
			Events:    eventRepo,
			Tasks:     taskRepo,
			Routines:  routineRepo,
			Templates: notificationTemplateRepo,
			Config:    appConfigRepo,
			Ntfy:      ntfyClient,
			Logger:    log,
		}
		go notifScheduler.Run(ctx)

		apiHandlers = &handler.APIHandlers{
			Me:            handler.NewMeHandler(authUC),
			Flags:         handler.NewFlagsHandler(flagUC),
			Subflags:      handler.NewSubflagsHandler(subflagUC, flagUC),
			ContextRules:  handler.NewContextRulesHandler(ruleUC, flagUC, subflagUC),
			Inbox:         handler.NewInboxHandler(inboxUC, flagUC, subflagUC),
			Agenda:        handler.NewAgendaHandler(agendaUC),
			Home:          handler.NewHomeHandler(homeUC),
			Tasks:         handler.NewTasksHandler(taskUC, inboxUC, flagUC, subflagUC),
			Reminders:     handler.NewRemindersHandler(reminderUC, inboxUC, flagUC, subflagUC),
			Events:        handler.NewEventsHandler(eventUC, inboxUC, flagUC, subflagUC),
			ShoppingLists: handler.NewShoppingListsHandler(shoppingListUC, inboxUC),
			ShoppingItems: handler.NewShoppingItemsHandler(shoppingItemUC, shoppingListUC),
			Routines:      handler.NewRoutinesHandler(routineUC, flagUC, subflagUC),
			Devices:       handler.NewDevicesHandler(deviceTokenUC),
			Notifications: handler.NewNotificationsHandler(notificationUC),
			Digest:        digestHandler,
		}
	}

	router := inbotahttp.NewRouter(cfg, log, authHandler, apiHandlers, db)

	srv := &http.Server{
		Addr:         cfg.Addr(),
		Handler:      router,
		ReadTimeout:  cfg.ReadTimeout,
		WriteTimeout: cfg.WriteTimeout,
		IdleTimeout:  cfg.IdleTimeout,
	}

	go func() {
		log.Info("server_start", slog.String("addr", cfg.Addr()))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Error("server_error", slog.String("error", err.Error()))
		}
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGINT, syscall.SIGTERM)
	<-shutdown

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	log.Info("server_shutdown")
	if err := srv.Shutdown(ctx); err != nil {
		log.Error("server_shutdown_error", slog.String("error", err.Error()))
	}
	if db != nil {
		_ = db.Close()
	}
}
