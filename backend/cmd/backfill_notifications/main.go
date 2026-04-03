package main

import (
	"bufio"
	"context"
	"database/sql"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"time"

	_ "github.com/lib/pq"
	"organiq/backend/internal/app/service"
	"organiq/backend/internal/config"
	"organiq/backend/internal/infra/ai"
	"organiq/backend/internal/infra/postgres"
)

func main() {
	loadEnvFile()
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", slog.String("error", err.Error()))
		os.Exit(1)
	}

	if cfg.DatabaseURL == "" {
		slog.Error("DATABASE_URL is required")
		os.Exit(1)
	}

	ctx := context.Background()
	db, err := postgres.NewDB(ctx, cfg.DatabaseURL)
	if err != nil {
		slog.Error("failed to open db", slog.String("error", err.Error()))
		os.Exit(1)
	}
	defer db.Close()

	// AI Client
	aiClient, err := ai.NewClient(cfg)
	if err != nil {
		slog.Error("failed to init ai client", slog.String("error", err.Error()))
		os.Exit(1)
	}

	copySvc := service.NewNotificationCopyService(aiClient)

	// Repositories
	taskRepo := postgres.NewTaskRepository(db)
	eventRepo := postgres.NewEventRepository(db)
	reminderRepo := postgres.NewReminderRepository(db)
	routineRepo := postgres.NewRoutineRepository(db)

	fmt.Println("🚀 Iniciando Backfill de Notificações...")

	// 1. Tasks
	processTasks(ctx, db, taskRepo, copySvc)
	// 2. Events
	processEvents(ctx, db, eventRepo, copySvc)
	// 3. Reminders
	processReminders(ctx, db, reminderRepo, copySvc)
	// 4. Routines
	processRoutines(ctx, db, routineRepo, copySvc)

	fmt.Println("✅ Backfill finalizado com sucesso!")
}

func loadEnvFile() {
	f, err := os.Open(".env")
	if err != nil {
		return
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			value := strings.Trim(strings.TrimSpace(parts[1]), "\"'")
			if os.Getenv(key) == "" {
				os.Setenv(key, value)
			}
		}
	}
}

func processTasks(ctx context.Context, db *postgres.DB, repo *postgres.TaskRepository, svc *service.NotificationCopyService) {
	rows, err := db.QueryContext(ctx, "SELECT id, title, description FROM organiq.tasks WHERE notification_title IS NULL")
	if err != nil {
		slog.Error("error listing tasks", slog.String("error", err.Error()))
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var id, title string
		var desc sql.NullString
		if err := rows.Scan(&id, &title, &desc); err != nil {
			continue
		}
		
		fmt.Printf("Generating copy for Task: %s\n", title)
		t, b, err := svc.GenerateCopy(ctx, "Task", title, desc.String)
		if err == nil {
			_ = repo.UpdateNotificationCopy(ctx, id, t, b)
			count++
			time.Sleep(200 * time.Millisecond) // avoid rate limits
		}
	}
	fmt.Printf("✓ Tasks processadas: %d\n", count)
}

func processEvents(ctx context.Context, db *postgres.DB, repo *postgres.EventRepository, svc *service.NotificationCopyService) {
	rows, err := db.QueryContext(ctx, "SELECT id, title FROM organiq.events WHERE notification_title IS NULL")
	if err != nil {
		slog.Error("error listing events", slog.String("error", err.Error()))
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var id, title string
		if err := rows.Scan(&id, &title); err != nil {
			continue
		}
		
		fmt.Printf("Generating copy for Event: %s\n", title)
		t, b, err := svc.GenerateCopy(ctx, "Event", title, "")
		if err == nil {
			_ = repo.UpdateNotificationCopy(ctx, id, t, b)
			count++
			time.Sleep(200 * time.Millisecond)
		}
	}
	fmt.Printf("✓ Events processados: %d\n", count)
}

func processReminders(ctx context.Context, db *postgres.DB, repo *postgres.ReminderRepository, svc *service.NotificationCopyService) {
	rows, err := db.QueryContext(ctx, "SELECT id, title FROM organiq.reminders WHERE notification_title IS NULL")
	if err != nil {
		slog.Error("error listing reminders", slog.String("error", err.Error()))
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var id, title string
		if err := rows.Scan(&id, &title); err != nil {
			continue
		}
		
		fmt.Printf("Generating copy for Reminder: %s\n", title)
		t, b, err := svc.GenerateCopy(ctx, "Reminder", title, "")
		if err == nil {
			_ = repo.UpdateNotificationCopy(ctx, id, t, b)
			count++
			time.Sleep(200 * time.Millisecond)
		}
	}
	fmt.Printf("✓ Reminders processados: %d\n", count)
}

func processRoutines(ctx context.Context, db *postgres.DB, repo *postgres.RoutineRepositoryImpl, svc *service.NotificationCopyService) {
	rows, err := db.QueryContext(ctx, "SELECT id, title, description FROM organiq.routines WHERE notification_title IS NULL")
	if err != nil {
		slog.Error("error listing routines", slog.String("error", err.Error()))
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var id, title string
		var desc sql.NullString
		if err := rows.Scan(&id, &title, &desc); err != nil {
			continue
		}
		
		fmt.Printf("Generating copy for Routine: %s\n", title)
		t, b, err := svc.GenerateCopy(ctx, "Routine", title, desc.String)
		if err == nil {
			_ = repo.UpdateNotificationCopy(ctx, id, t, b)
			count++
			time.Sleep(200 * time.Millisecond)
		}
	}
	fmt.Printf("✓ Routines processadas: %d\n", count)
}
