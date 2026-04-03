package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
)

type NotificationCopyService struct {
	ai AIClient
}

func NewNotificationCopyService(ai AIClient) *NotificationCopyService {
	return &NotificationCopyService{
		ai: ai,
	}
}

type notificationCopyResult struct {
	Title string `json:"notification_title"`
	Body  string `json:"notification_body"`
}

// GenerateCopy calls the LLM to generate a customized, friendly title and body.
func (s *NotificationCopyService) GenerateCopy(ctx context.Context, itemType, title, description string) (string, string, error) {
	if s.ai == nil {
		return "", "", ErrAIProviderNotConfigured
	}

	descText := ""
	if description != "" {
		descText = fmt.Sprintf("Descrição: %s\n", description)
	}

	prompt := fmt.Sprintf(`Você é um redator de notificações push experiente, focado em escrita criativa e natural (UX Writing).
Sua missão é transformar um item de produtividade em uma frase curta, humana e engajadora.

DADOS DO ITEM:
Tipo: %s
Título Original: %s
%s

REGRAS CRÍTICAS:
1. PROIBIDO o uso de emojis. Use apenas texto.
2. PROIBIDO usar frases prontas ou fixas como "Hora de focar", "Inicie sua rotina" ou "Chegou a hora".
3. Crie frases VARIADAS e NATURAIS. O texto deve soar como um lembrete que um amigo ou um assistente pessoal inteligente daria.
4. O "notification_title" deve ser o ponto central (ex: um chamado ou uma pergunta curta).
5. O "notification_body" deve ser uma frase que complementa o título de forma fluida.
6. Se o item for uma "Routine", foque na consistência. Se for "Task", foque na conclusão. Se for "Event", foque na presença.
7. Não inclua informações de tempo (como "em 15 minutos").
8. Retorne apenas o JSON:
{
  "notification_title": "...",
  "notification_body": "..."
}`, itemType, title, descText)

	completion, err := s.ai.Complete(ctx, prompt)
	if err != nil {
		slog.Error("notification_copy_service_llm_error", slog.String("error", err.Error()))
		return "", "", err
	}

	var result notificationCopyResult
	if err := json.Unmarshal([]byte(completion.Content), &result); err != nil {
		slog.Error("notification_copy_service_unmarshal_error", slog.String("error", err.Error()), slog.String("content", completion.Content))
		return "", "", err
	}

	return result.Title, result.Body, nil
}
