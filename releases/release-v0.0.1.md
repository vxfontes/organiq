# Release 0.0.1 (MVP)

Data: 2026-02-21

## Visao geral
O Inbota chega na versao 0.0.1 como MVP do inbox com IA. A proposta e transformar texto bruto em itens acionaveis de produtividade, com revisao humana antes de confirmar tarefas, lembretes, eventos ou listas de compras.

## Destaques
- Autenticacao JWT com `signup`, `login` e `me`.
- Fluxo de Inbox com criacao, reprocessamento e confirmacao de itens via IA.
- Entidades finais entregues: tarefas, lembretes, eventos e listas de compras.
- Organizacao por contexto com `flags` e `subflags` e regras por palavra-chave.
- Documentacao da API e Swagger.

## O que foi entregue
- Monorepo com `app` (Flutter), `backend` (Go + Gin), `db` e `docs`.
- CRUD completo de contextos (flags e subflags).
- CRUD das entidades finais (tasks, reminders, events, shopping-lists).
- API local com health checks e rotas protegidas por JWT.
- Pipeline de sugestoes do Inbox com reprocessamento por IA.

## Stack
- App: Flutter 3.35.x + Dart.
- Backend: Go 1.25.x + Gin.
- Banco: PostgreSQL (Supabase).
- IA: Groq (API compatível OpenAI).
- Deploy backend: Render.

## Como rodar local (resumo)
- Backend: `go run ./cmd/api` (com `.env` configurado).
- App: `flutter run --dart-define-from-file=.env` (com `API_HOST`).

## Limitacoes conhecidas / fora do escopo
- Notificacoes e push.
- Entrada por voz, share sheet ou OCR.
- Versoes nativas para macOS e watchOS.
- Widget para macOS e iOS.

## Proximos passos sugeridos
- Melhorar pipeline automatico do Inbox.
- Expandir automacoes por contexto.
- Evoluir UX e testes.

