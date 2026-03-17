package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/service"
	"organiq/backend/internal/infra/postgres"
)

type seedConfig struct {
	Email       string
	Password    string
	DisplayName string
	Locale      string
	Timezone    string
}

type seedFlag struct {
	Name      string
	Color     *string
	SortOrder int
	Subflags  []seedSubflag
}

type seedSubflag struct {
	Name      string
	SortOrder int
}

type seedRule struct {
	Keyword string
	Flag    string
	Subflag *string
}

func main() {
	cfg := loadSeedConfig()

	dsn := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	if dsn == "" {
		log.Fatal("DATABASE_URL is required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	db, err := postgres.NewDB(ctx, dsn)
	if err != nil {
		log.Fatalf("db_connect_error: %v", err)
	}
	defer func() {
		_ = db.Close()
	}()

	user, created, err := ensureUser(ctx, db, cfg)
	if err != nil {
		log.Fatalf("seed_user_error: %v", err)
	}
	if created {
		log.Printf("user created: %s", user.Email)
	} else {
		log.Printf("user exists: %s", user.Email)
	}

	flagIDs, subflagIDs, err := seedContexts(ctx, db, user.ID)
	if err != nil {
		log.Fatalf("seed_contexts_error: %v", err)
	}

	rules := defaultRules()
	createdRules, updatedRules := 0, 0
	for _, rule := range rules {
		flagID, ok := flagIDs[rule.Flag]
		if !ok {
			log.Printf("skip rule %q: flag %q not found", rule.Keyword, rule.Flag)
			continue
		}
		var subflagID *string
		if rule.Subflag != nil {
			key := flagSubflagKey(rule.Flag, *rule.Subflag)
			id, ok := subflagIDs[key]
			if !ok {
				log.Printf("skip rule %q: subflag %q not found", rule.Keyword, *rule.Subflag)
				continue
			}
			subflagID = &id
		}

		_, created, err := ensureContextRule(ctx, db, user.ID, strings.ToLower(rule.Keyword), flagID, subflagID)
		if err != nil {
			log.Fatalf("seed_rule_error: %v", err)
		}
		if created {
			createdRules++
		} else {
			updatedRules++
		}
	}

	log.Printf("rules: created=%d updated=%d", createdRules, updatedRules)

	if err := seedEntities(ctx, db, user.ID, flagIDs, subflagIDs); err != nil {
		log.Fatalf("seed_entities_error: %v", err)
	}
}

func loadSeedConfig() seedConfig {
	return seedConfig{
		Email:       getEnv("SEED_EMAIL", "demo@organiq.dev"),
		Password:    getEnv("SEED_PASSWORD", "abc123"),
		DisplayName: getEnv("SEED_DISPLAY_NAME", "Demo"),
		Locale:      getEnv("SEED_LOCALE", "pt-BR"),
		Timezone:    getEnv("SEED_TIMEZONE", "America/Sao_Paulo"),
	}
}

func getEnv(key, def string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return def
}

func ensureUser(ctx context.Context, db *postgres.DB, cfg seedConfig) (domain.User, bool, error) {
	row := db.QueryRowContext(ctx, `
		SELECT id, email, display_name, password, locale, timezone, created_at, updated_at
		FROM organiq.users
		WHERE email = $1
		LIMIT 1
	`, cfg.Email)

	var user domain.User
	if err := row.Scan(&user.ID, &user.Email, &user.DisplayName, &user.Password, &user.Locale, &user.Timezone, &user.CreatedAt, &user.UpdatedAt); err == nil {
		return user, false, nil
	} else if err != sql.ErrNoRows {
		return domain.User{}, false, err
	}

	auth := service.NewAuthService("", 0)
	hash, err := auth.HashPassword(cfg.Password)
	if err != nil {
		return domain.User{}, false, err
	}

	user = domain.User{
		Email:       cfg.Email,
		DisplayName: cfg.DisplayName,
		Password:    hash,
		Locale:      cfg.Locale,
		Timezone:    cfg.Timezone,
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.users (email, display_name, password, locale, timezone)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`, user.Email, user.DisplayName, user.Password, user.Locale, user.Timezone)

	if err := row.Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt); err != nil {
		return domain.User{}, false, err
	}
	return user, true, nil
}

func seedContexts(ctx context.Context, db *postgres.DB, userID string) (map[string]string, map[string]string, error) {
	flags := defaultFlags()
	flagIDs := make(map[string]string)
	subflagIDs := make(map[string]string)

	for _, flag := range flags {
		id, created, err := ensureFlag(ctx, db, userID, flag)
		if err != nil {
			return nil, nil, err
		}
		flagIDs[flag.Name] = id
		if created {
			log.Printf("flag created: %s", flag.Name)
		}

		for _, sub := range flag.Subflags {
			subID, subCreated, err := ensureSubflag(ctx, db, userID, id, sub)
			if err != nil {
				return nil, nil, err
			}
			key := flagSubflagKey(flag.Name, sub.Name)
			subflagIDs[key] = subID
			if subCreated {
				log.Printf("subflag created: %s > %s", flag.Name, sub.Name)
			}
		}
	}

	return flagIDs, subflagIDs, nil
}

func ensureFlag(ctx context.Context, db *postgres.DB, userID string, flag seedFlag) (string, bool, error) {
	var id string
	row := db.QueryRowContext(ctx, `
		SELECT id FROM organiq.flags
		WHERE user_id = $1 AND name = $2
		LIMIT 1
	`, userID, flag.Name)
	if err := row.Scan(&id); err == nil {
		return id, false, nil
	} else if err != sql.ErrNoRows {
		return "", false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.flags (user_id, name, color, sort_order)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, userID, flag.Name, flag.Color, flag.SortOrder)
	if err := row.Scan(&id); err != nil {
		return "", false, err
	}
	return id, true, nil
}

func ensureSubflag(ctx context.Context, db *postgres.DB, userID, flagID string, sub seedSubflag) (string, bool, error) {
	var id string
	row := db.QueryRowContext(ctx, `
		SELECT id FROM organiq.subflags
		WHERE user_id = $1 AND flag_id = $2 AND name = $3
		LIMIT 1
	`, userID, flagID, sub.Name)
	if err := row.Scan(&id); err == nil {
		return id, false, nil
	} else if err != sql.ErrNoRows {
		return "", false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.subflags (user_id, flag_id, name, sort_order)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, userID, flagID, sub.Name, sub.SortOrder)
	if err := row.Scan(&id); err != nil {
		return "", false, err
	}
	return id, true, nil
}

func ensureContextRule(ctx context.Context, db *postgres.DB, userID, keyword, flagID string, subflagID *string) (string, bool, error) {
	var id string
	row := db.QueryRowContext(ctx, `
		SELECT id FROM organiq.context_rules
		WHERE user_id = $1 AND keyword = $2
		LIMIT 1
	`, userID, keyword)
	if err := row.Scan(&id); err == nil {
		_, err = db.ExecContext(ctx, `
			UPDATE organiq.context_rules
			SET flag_id = $1, subflag_id = $2, updated_at = now()
			WHERE id = $3 AND user_id = $4
		`, flagID, subflagID, id, userID)
		if err != nil {
			return "", false, err
		}
		return id, false, nil
	} else if err != sql.ErrNoRows {
		return "", false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.context_rules (user_id, keyword, flag_id, subflag_id)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, userID, keyword, flagID, subflagID)
	if err := row.Scan(&id); err != nil {
		return "", false, err
	}
	return id, true, nil
}

func defaultFlags() []seedFlag {
	green := "#22c55e"
	blue := "#2563eb"
	amber := "#f59e0b"
	cyan := "#06b6d4"
	red := "#ef4444"
	violet := "#8b5cf6"

	return []seedFlag{
		{
			Name:      "Pessoal",
			Color:     &green,
			SortOrder: 1,
			Subflags: []seedSubflag{
				{Name: "Familia", SortOrder: 1},
				{Name: "Amigos", SortOrder: 2},
			},
		},
		{
			Name:      "Trabalho",
			Color:     &blue,
			SortOrder: 2,
			Subflags: []seedSubflag{
				{Name: "Reunioes", SortOrder: 1},
				{Name: "Projetos", SortOrder: 2},
			},
		},
		{
			Name:      "Estudos",
			Color:     &amber,
			SortOrder: 3,
			Subflags: []seedSubflag{
				{Name: "TCC", SortOrder: 1},
				{Name: "Cursos", SortOrder: 2},
			},
		},
		{
			Name:      "Casa",
			Color:     &cyan,
			SortOrder: 4,
			Subflags: []seedSubflag{
				{Name: "Limpeza", SortOrder: 1},
				{Name: "Manutencao", SortOrder: 2},
			},
		},
		{
			Name:      "Saude",
			Color:     &red,
			SortOrder: 5,
			Subflags: []seedSubflag{
				{Name: "Exames", SortOrder: 1},
				{Name: "Consultas", SortOrder: 2},
			},
		},
		{
			Name:      "Financas",
			Color:     &violet,
			SortOrder: 6,
			Subflags: []seedSubflag{
				{Name: "Cartao", SortOrder: 1},
				{Name: "Boletos", SortOrder: 2},
			},
		},
	}
}

func defaultRules() []seedRule {
	reunioes := "Reunioes"
	tcc := "TCC"
	cartao := "Cartao"
	exames := "Exames"
	limpeza := "Limpeza"

	return []seedRule{
		{Keyword: "reuniao", Flag: "Trabalho", Subflag: &reunioes},
		{Keyword: "tcc", Flag: "Estudos", Subflag: &tcc},
		{Keyword: "pix", Flag: "Financas", Subflag: nil},
		{Keyword: "cartao", Flag: "Financas", Subflag: &cartao},
		{Keyword: "exame", Flag: "Saude", Subflag: &exames},
		{Keyword: "faxina", Flag: "Casa", Subflag: &limpeza},
	}
}

func flagSubflagKey(flagName, subflagName string) string {
	return fmt.Sprintf("%s::%s", flagName, subflagName)
}

func seedEntities(ctx context.Context, db *postgres.DB, userID string, flagIDs, subflagIDs map[string]string) error {
	now := time.Now().UTC().Truncate(time.Second)

	flagPessoal, err := requireFlag(flagIDs, "Pessoal")
	if err != nil {
		return err
	}
	flagFinancas, err := requireFlag(flagIDs, "Financas")
	if err != nil {
		return err
	}
	flagSaude, err := requireFlag(flagIDs, "Saude")
	if err != nil {
		return err
	}
	flagCasa, err := requireFlag(flagIDs, "Casa")
	if err != nil {
		return err
	}

	subFamilia, err := requireSubflag(subflagIDs, "Pessoal", "Familia")
	if err != nil {
		return err
	}
	subBoletos, err := requireSubflag(subflagIDs, "Financas", "Boletos")
	if err != nil {
		return err
	}
	subConsultas, err := requireSubflag(subflagIDs, "Saude", "Consultas")
	if err != nil {
		return err
	}

	taskDue := now.Add(48 * time.Hour).Truncate(time.Minute)
	remindAt := now.Add(6 * time.Hour).Truncate(time.Minute)
	eventStart := now.Add(72 * time.Hour).Truncate(time.Minute)
	eventEnd := eventStart.Add(90 * time.Minute).Truncate(time.Minute)
	needsReviewAt := now.Add(7 * 24 * time.Hour).Truncate(time.Minute)

	inboxTask, _, err := ensureInboxItem(ctx, db, domain.InboxItem{
		UserID:  userID,
		Source:  domain.InboxSourceManual,
		RawText: "[seed] Ligar para mae amanha",
		Status:  domain.InboxStatusConfirmed,
	})
	if err != nil {
		return err
	}

	inboxReminder, _, err := ensureInboxItem(ctx, db, domain.InboxItem{
		UserID:  userID,
		Source:  domain.InboxSourceManual,
		RawText: "[seed] Pagar internet dia 12",
		Status:  domain.InboxStatusConfirmed,
	})
	if err != nil {
		return err
	}

	inboxEvent, _, err := ensureInboxItem(ctx, db, domain.InboxItem{
		UserID:  userID,
		Source:  domain.InboxSourceManual,
		RawText: "[seed] Consulta medica terca 14h",
		Status:  domain.InboxStatusConfirmed,
	})
	if err != nil {
		return err
	}

	inboxShopping, _, err := ensureInboxItem(ctx, db, domain.InboxItem{
		UserID:  userID,
		Source:  domain.InboxSourceManual,
		RawText: "[seed] Comprar arroz, feijao e detergente",
		Status:  domain.InboxStatusConfirmed,
	})
	if err != nil {
		return err
	}

	noteMediaURL := "https://example.com/seed.png"
	inboxNote, _, err := ensureInboxItem(ctx, db, domain.InboxItem{
		UserID:      userID,
		Source:      domain.InboxSourceOCR,
		RawText:     "[seed] Senha do wifi: organiq123",
		RawMediaURL: &noteMediaURL,
		Status:      domain.InboxStatusSuggested,
	})
	if err != nil {
		return err
	}

	lastError := "low_confidence"
	inboxNeedsReview, _, err := ensureInboxItem(ctx, db, domain.InboxItem{
		UserID:    userID,
		Source:    domain.InboxSourceManual,
		RawText:   "[seed] Lembrar de algo na proxima semana",
		Status:    domain.InboxStatusNeedsReview,
		LastError: &lastError,
	})
	if err != nil {
		return err
	}

	_, _, err = ensureInboxItem(ctx, db, domain.InboxItem{
		UserID:  userID,
		Source:  domain.InboxSourceManual,
		RawText: "[seed] Ideia para projeto de estudo",
		Status:  domain.InboxStatusNew,
	})
	if err != nil {
		return err
	}

	_, _, err = ensureInboxItem(ctx, db, domain.InboxItem{
		UserID:  userID,
		Source:  domain.InboxSourceShare,
		RawText: "[seed] Mensagem descartada",
		Status:  domain.InboxStatusDismissed,
	})
	if err != nil {
		return err
	}

	taskPayload, err := jsonPayload(map[string]any{
		"dueAt": taskDue.Format(time.RFC3339),
	})
	if err != nil {
		return err
	}
	_, _, err = ensureAiSuggestion(ctx, db, domain.AiSuggestion{
		UserID:      userID,
		InboxItemID: inboxTask.ID,
		Type:        domain.AiSuggestionTypeTask,
		Title:       "[seed] Ligar para mae",
		Confidence:  floatPtr(0.82),
		FlagID:      strPtr(flagPessoal),
		SubflagID:   strPtr(subFamilia),
		NeedsReview: false,
		PayloadJSON: taskPayload,
	})
	if err != nil {
		return err
	}

	reminderPayload, err := jsonPayload(map[string]any{
		"at": remindAt.Format(time.RFC3339),
	})
	if err != nil {
		return err
	}
	_, _, err = ensureAiSuggestion(ctx, db, domain.AiSuggestion{
		UserID:      userID,
		InboxItemID: inboxReminder.ID,
		Type:        domain.AiSuggestionTypeReminder,
		Title:       "[seed] Pagar internet",
		Confidence:  floatPtr(0.9),
		FlagID:      strPtr(flagFinancas),
		SubflagID:   strPtr(subBoletos),
		NeedsReview: false,
		PayloadJSON: reminderPayload,
	})
	if err != nil {
		return err
	}

	eventPayload, err := jsonPayload(map[string]any{
		"start":  eventStart.Format(time.RFC3339),
		"end":    eventEnd.Format(time.RFC3339),
		"allDay": false,
	})
	if err != nil {
		return err
	}
	_, _, err = ensureAiSuggestion(ctx, db, domain.AiSuggestion{
		UserID:      userID,
		InboxItemID: inboxEvent.ID,
		Type:        domain.AiSuggestionTypeEvent,
		Title:       "[seed] Consulta medica",
		Confidence:  floatPtr(0.86),
		FlagID:      strPtr(flagSaude),
		SubflagID:   strPtr(subConsultas),
		NeedsReview: false,
		PayloadJSON: eventPayload,
	})
	if err != nil {
		return err
	}

	shoppingPayload, err := jsonPayload(map[string]any{
		"items": []map[string]any{
			{"title": "Arroz", "quantity": "2kg"},
			{"title": "Feijao", "quantity": "1kg"},
			{"title": "Detergente", "quantity": nil},
		},
	})
	if err != nil {
		return err
	}
	_, _, err = ensureAiSuggestion(ctx, db, domain.AiSuggestion{
		UserID:      userID,
		InboxItemID: inboxShopping.ID,
		Type:        domain.AiSuggestionTypeShopping,
		Title:       "[seed] Compras da semana",
		Confidence:  floatPtr(0.8),
		FlagID:      strPtr(flagCasa),
		NeedsReview: false,
		PayloadJSON: shoppingPayload,
	})
	if err != nil {
		return err
	}

	notePayload, err := jsonPayload(map[string]any{
		"content": "Senha do wifi: organiq123",
	})
	if err != nil {
		return err
	}
	_, _, err = ensureAiSuggestion(ctx, db, domain.AiSuggestion{
		UserID:      userID,
		InboxItemID: inboxNote.ID,
		Type:        domain.AiSuggestionTypeNote,
		Title:       "[seed] Senha do wifi",
		Confidence:  floatPtr(0.6),
		FlagID:      strPtr(flagCasa),
		NeedsReview: false,
		PayloadJSON: notePayload,
	})
	if err != nil {
		return err
	}

	needsReviewPayload, err := jsonPayload(map[string]any{
		"at": needsReviewAt.Format(time.RFC3339),
	})
	if err != nil {
		return err
	}
	_, _, err = ensureAiSuggestion(ctx, db, domain.AiSuggestion{
		UserID:      userID,
		InboxItemID: inboxNeedsReview.ID,
		Type:        domain.AiSuggestionTypeReminder,
		Title:       "[seed] Lembrete pendente",
		Confidence:  floatPtr(0.3),
		FlagID:      strPtr(flagPessoal),
		NeedsReview: true,
		PayloadJSON: needsReviewPayload,
	})
	if err != nil {
		return err
	}

	description := "Falar sobre a viagem"
	_, _, err = ensureTask(ctx, db, domain.Task{
		UserID:            userID,
		Title:             "[seed] Ligar para mae",
		Description:       &description,
		Status:            domain.TaskStatusOpen,
		DueAt:             &taskDue,
		SourceInboxItemID: strPtr(inboxTask.ID),
	})
	if err != nil {
		return err
	}

	_, _, err = ensureReminder(ctx, db, domain.Reminder{
		UserID:            userID,
		Title:             "[seed] Pagar internet",
		Status:            domain.ReminderStatusOpen,
		RemindAt:          &remindAt,
		SourceInboxItemID: strPtr(inboxReminder.ID),
	})
	if err != nil {
		return err
	}

	location := "Clinica Central"
	_, _, err = ensureEvent(ctx, db, domain.Event{
		UserID:            userID,
		Title:             "[seed] Consulta medica",
		StartAt:           &eventStart,
		EndAt:             &eventEnd,
		AllDay:            false,
		Location:          &location,
		SourceInboxItemID: strPtr(inboxEvent.ID),
	})
	if err != nil {
		return err
	}

	shoppingList, _, err := ensureShoppingList(ctx, db, domain.ShoppingList{
		UserID:            userID,
		Title:             "[seed] Compras da semana",
		Status:            domain.ShoppingListStatusOpen,
		SourceInboxItemID: strPtr(inboxShopping.ID),
	})
	if err != nil {
		return err
	}

	_, _, err = ensureShoppingItem(ctx, db, domain.ShoppingItem{
		UserID:    userID,
		ListID:    shoppingList.ID,
		Title:     "Arroz",
		Quantity:  strPtr("2kg"),
		Checked:   false,
		SortOrder: 1,
	})
	if err != nil {
		return err
	}

	_, _, err = ensureShoppingItem(ctx, db, domain.ShoppingItem{
		UserID:    userID,
		ListID:    shoppingList.ID,
		Title:     "Feijao",
		Quantity:  strPtr("1kg"),
		Checked:   false,
		SortOrder: 2,
	})
	if err != nil {
		return err
	}

	_, _, err = ensureShoppingItem(ctx, db, domain.ShoppingItem{
		UserID:    userID,
		ListID:    shoppingList.ID,
		Title:     "Detergente",
		Quantity:  nil,
		Checked:   false,
		SortOrder: 3,
	})
	if err != nil {
		return err
	}

	return nil
}

func requireFlag(flagIDs map[string]string, name string) (string, error) {
	if id, ok := flagIDs[name]; ok {
		return id, nil
	}
	return "", fmt.Errorf("flag_not_found: %s", name)
}

func requireSubflag(subflagIDs map[string]string, flagName, subflagName string) (string, error) {
	key := flagSubflagKey(flagName, subflagName)
	if id, ok := subflagIDs[key]; ok {
		return id, nil
	}
	return "", fmt.Errorf("subflag_not_found: %s", key)
}

func jsonPayload(value any) (json.RawMessage, error) {
	raw, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	return raw, nil
}

func strPtr(value string) *string {
	v := value
	return &v
}

func floatPtr(value float64) *float64 {
	v := value
	return &v
}

func ensureInboxItem(ctx context.Context, db *postgres.DB, item domain.InboxItem) (domain.InboxItem, bool, error) {
	row := db.QueryRowContext(ctx, `
		SELECT id, created_at, updated_at
		FROM organiq.inbox_items
		WHERE user_id = $1 AND raw_text = $2
		LIMIT 1
	`, item.UserID, item.RawText)

	if err := row.Scan(&item.ID, &item.CreatedAt, &item.UpdatedAt); err == nil {
		row = db.QueryRowContext(ctx, `
			UPDATE organiq.inbox_items
			SET source = $1, raw_text = $2, raw_media_url = $3, status = $4, last_error = $5, updated_at = now()
			WHERE id = $6 AND user_id = $7
			RETURNING created_at, updated_at
		`, string(item.Source), item.RawText, item.RawMediaURL, string(item.Status), item.LastError, item.ID, item.UserID)
		if err := row.Scan(&item.CreatedAt, &item.UpdatedAt); err != nil {
			return domain.InboxItem{}, false, err
		}
		return item, false, nil
	} else if err != sql.ErrNoRows {
		return domain.InboxItem{}, false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.inbox_items (user_id, source, raw_text, raw_media_url, status, last_error)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`, item.UserID, string(item.Source), item.RawText, item.RawMediaURL, string(item.Status), item.LastError)
	if err := row.Scan(&item.ID, &item.CreatedAt, &item.UpdatedAt); err != nil {
		return domain.InboxItem{}, false, err
	}
	return item, true, nil
}

func ensureAiSuggestion(ctx context.Context, db *postgres.DB, suggestion domain.AiSuggestion) (domain.AiSuggestion, bool, error) {
	row := db.QueryRowContext(ctx, `
		SELECT id, created_at
		FROM organiq.ai_suggestions
		WHERE user_id = $1 AND inbox_item_id = $2 AND type = $3
		ORDER BY created_at DESC
		LIMIT 1
	`, suggestion.UserID, suggestion.InboxItemID, string(suggestion.Type))

	if err := row.Scan(&suggestion.ID, &suggestion.CreatedAt); err == nil {
		_, err := db.ExecContext(ctx, `
			UPDATE organiq.ai_suggestions
			SET title = $1, confidence = $2, flag_id = $3, subflag_id = $4, needs_review = $5, payload_json = $6
			WHERE id = $7 AND user_id = $8
		`, suggestion.Title, suggestion.Confidence, suggestion.FlagID, suggestion.SubflagID, suggestion.NeedsReview, suggestion.PayloadJSON, suggestion.ID, suggestion.UserID)
		if err != nil {
			return domain.AiSuggestion{}, false, err
		}
		return suggestion, false, nil
	} else if err != sql.ErrNoRows {
		return domain.AiSuggestion{}, false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.ai_suggestions
		(user_id, inbox_item_id, type, title, confidence, flag_id, subflag_id, needs_review, payload_json)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, created_at
	`, suggestion.UserID, suggestion.InboxItemID, string(suggestion.Type), suggestion.Title, suggestion.Confidence, suggestion.FlagID, suggestion.SubflagID, suggestion.NeedsReview, suggestion.PayloadJSON)
	if err := row.Scan(&suggestion.ID, &suggestion.CreatedAt); err != nil {
		return domain.AiSuggestion{}, false, err
	}
	return suggestion, true, nil
}

func ensureTask(ctx context.Context, db *postgres.DB, task domain.Task) (domain.Task, bool, error) {
	row := db.QueryRowContext(ctx, `
		SELECT id, created_at, updated_at
		FROM organiq.tasks
		WHERE user_id = $1 AND title = $2
		LIMIT 1
	`, task.UserID, task.Title)

	if err := row.Scan(&task.ID, &task.CreatedAt, &task.UpdatedAt); err == nil {
		row = db.QueryRowContext(ctx, `
			UPDATE organiq.tasks
			SET title = $1, description = $2, status = $3, due_at = $4, flag_id = $5, subflag_id = $6, source_inbox_item_id = $7, updated_at = now()
			WHERE id = $8 AND user_id = $9
			RETURNING created_at, updated_at
		`, task.Title, task.Description, string(task.Status), task.DueAt, task.FlagID, task.SubflagID, task.SourceInboxItemID, task.ID, task.UserID)
		if err := row.Scan(&task.CreatedAt, &task.UpdatedAt); err != nil {
			return domain.Task{}, false, err
		}
		return task, false, nil
	} else if err != sql.ErrNoRows {
		return domain.Task{}, false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.tasks (user_id, title, description, status, due_at, flag_id, subflag_id, source_inbox_item_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at, updated_at
	`, task.UserID, task.Title, task.Description, string(task.Status), task.DueAt, task.FlagID, task.SubflagID, task.SourceInboxItemID)
	if err := row.Scan(&task.ID, &task.CreatedAt, &task.UpdatedAt); err != nil {
		return domain.Task{}, false, err
	}
	return task, true, nil
}

func ensureReminder(ctx context.Context, db *postgres.DB, reminder domain.Reminder) (domain.Reminder, bool, error) {
	row := db.QueryRowContext(ctx, `
		SELECT id, created_at, updated_at
		FROM organiq.reminders
		WHERE user_id = $1 AND title = $2
		LIMIT 1
	`, reminder.UserID, reminder.Title)

	if err := row.Scan(&reminder.ID, &reminder.CreatedAt, &reminder.UpdatedAt); err == nil {
		row = db.QueryRowContext(ctx, `
			UPDATE organiq.reminders
			SET title = $1, status = $2, remind_at = $3, source_inbox_item_id = $4, updated_at = now()
			WHERE id = $5 AND user_id = $6
			RETURNING created_at, updated_at
		`, reminder.Title, string(reminder.Status), reminder.RemindAt, reminder.SourceInboxItemID, reminder.ID, reminder.UserID)
		if err := row.Scan(&reminder.CreatedAt, &reminder.UpdatedAt); err != nil {
			return domain.Reminder{}, false, err
		}
		return reminder, false, nil
	} else if err != sql.ErrNoRows {
		return domain.Reminder{}, false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.reminders (user_id, title, status, remind_at, source_inbox_item_id)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`, reminder.UserID, reminder.Title, string(reminder.Status), reminder.RemindAt, reminder.SourceInboxItemID)
	if err := row.Scan(&reminder.ID, &reminder.CreatedAt, &reminder.UpdatedAt); err != nil {
		return domain.Reminder{}, false, err
	}
	return reminder, true, nil
}

func ensureEvent(ctx context.Context, db *postgres.DB, event domain.Event) (domain.Event, bool, error) {
	row := db.QueryRowContext(ctx, `
		SELECT id, created_at, updated_at
		FROM organiq.events
		WHERE user_id = $1 AND title = $2
		LIMIT 1
	`, event.UserID, event.Title)

	if err := row.Scan(&event.ID, &event.CreatedAt, &event.UpdatedAt); err == nil {
		row = db.QueryRowContext(ctx, `
			UPDATE organiq.events
			SET title = $1, start_at = $2, end_at = $3, all_day = $4, location = $5, source_inbox_item_id = $6, updated_at = now()
			WHERE id = $7 AND user_id = $8
			RETURNING created_at, updated_at
		`, event.Title, event.StartAt, event.EndAt, event.AllDay, event.Location, event.SourceInboxItemID, event.ID, event.UserID)
		if err := row.Scan(&event.CreatedAt, &event.UpdatedAt); err != nil {
			return domain.Event{}, false, err
		}
		return event, false, nil
	} else if err != sql.ErrNoRows {
		return domain.Event{}, false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.events (user_id, title, start_at, end_at, all_day, location, source_inbox_item_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`, event.UserID, event.Title, event.StartAt, event.EndAt, event.AllDay, event.Location, event.SourceInboxItemID)
	if err := row.Scan(&event.ID, &event.CreatedAt, &event.UpdatedAt); err != nil {
		return domain.Event{}, false, err
	}
	return event, true, nil
}

func ensureShoppingList(ctx context.Context, db *postgres.DB, list domain.ShoppingList) (domain.ShoppingList, bool, error) {
	row := db.QueryRowContext(ctx, `
		SELECT id, created_at, updated_at
		FROM organiq.shopping_lists
		WHERE user_id = $1 AND title = $2
		LIMIT 1
	`, list.UserID, list.Title)

	if err := row.Scan(&list.ID, &list.CreatedAt, &list.UpdatedAt); err == nil {
		row = db.QueryRowContext(ctx, `
			UPDATE organiq.shopping_lists
			SET title = $1, status = $2, source_inbox_item_id = $3, updated_at = now()
			WHERE id = $4 AND user_id = $5
			RETURNING created_at, updated_at
		`, list.Title, string(list.Status), list.SourceInboxItemID, list.ID, list.UserID)
		if err := row.Scan(&list.CreatedAt, &list.UpdatedAt); err != nil {
			return domain.ShoppingList{}, false, err
		}
		return list, false, nil
	} else if err != sql.ErrNoRows {
		return domain.ShoppingList{}, false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.shopping_lists (user_id, title, status, source_inbox_item_id)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, updated_at
	`, list.UserID, list.Title, string(list.Status), list.SourceInboxItemID)
	if err := row.Scan(&list.ID, &list.CreatedAt, &list.UpdatedAt); err != nil {
		return domain.ShoppingList{}, false, err
	}
	return list, true, nil
}

func ensureShoppingItem(ctx context.Context, db *postgres.DB, item domain.ShoppingItem) (domain.ShoppingItem, bool, error) {
	row := db.QueryRowContext(ctx, `
		SELECT id, created_at, updated_at
		FROM organiq.shopping_items
		WHERE user_id = $1 AND list_id = $2 AND title = $3
		LIMIT 1
	`, item.UserID, item.ListID, item.Title)

	if err := row.Scan(&item.ID, &item.CreatedAt, &item.UpdatedAt); err == nil {
		row = db.QueryRowContext(ctx, `
			UPDATE organiq.shopping_items
			SET title = $1, quantity = $2, checked = $3, sort_order = $4, updated_at = now()
			WHERE id = $5 AND user_id = $6
			RETURNING created_at, updated_at
		`, item.Title, item.Quantity, item.Checked, item.SortOrder, item.ID, item.UserID)
		if err := row.Scan(&item.CreatedAt, &item.UpdatedAt); err != nil {
			return domain.ShoppingItem{}, false, err
		}
		return item, false, nil
	} else if err != sql.ErrNoRows {
		return domain.ShoppingItem{}, false, err
	}

	row = db.QueryRowContext(ctx, `
		INSERT INTO organiq.shopping_items (user_id, list_id, title, quantity, checked, sort_order)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`, item.UserID, item.ListID, item.Title, item.Quantity, item.Checked, item.SortOrder)
	if err := row.Scan(&item.ID, &item.CreatedAt, &item.UpdatedAt); err != nil {
		return domain.ShoppingItem{}, false, err
	}
	return item, true, nil
}
