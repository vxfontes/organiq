# Organiq

<img src="app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" alt="Organiq App Icon" width="180" />

Inbox com IA para transformar entradas brutas em itens organizados de produtividade.

O Organiq recebe texto (e, no roadmap, compartilhamentos e imagens), gera sugestoes com IA e permite revisao antes de confirmar o item final como tarefa, lembrete, evento ou lista de compras.

## Status

Projeto em desenvolvimento (MVP).

Funcional hoje:
- Monorepo com `app` (Flutter), `backend` (Go + Gin), `db` (scripts SQL) e `docs`.
- Autenticacao JWT (`signup`, `login`, `me`).
- CRUD de contextos (`flags` e `subflags`) e regras de contexto por palavra-chave.
- Fluxo de Inbox (`criar`, `reprocessar`, `confirmar`) com sugestao de IA.
- Entidades finais: tarefas, lembretes, eventos e compras.
- Documentacao de API e Swagger.

## Visao do produto

Objetivo do MVP:
- Centralizar tudo que chega para o usuario em um Inbox unico.
- Classificar automaticamente com IA em tipos acionaveis.
- Permitir revisao humana antes de criar a entidade final.
- Organizar por contexto de vida/trabalho via flags e subflags.

## Arquitetura do repositorio

```text
organiq/
├── app/      # App Flutter
├── backend/  # API Go (Gin)
├── db/       # Scripts e versoes de schema
└── docs/     # Guias tecnicos e produto
```

## Stack

- App: Flutter 3.35.x + Dart
- Backend: Go 1.25.x + Gin
- Banco: PostgreSQL (Supabase)
- IA: Groq (OpenAI-compatible chat completions)
- Deploy API: Render

## Infra e servicos em producao

O projeto esta configurado com os seguintes servicos:

- IA (Groq): classificacao e estruturacao de itens do Inbox para `task`, `reminder`, `event` e `shopping`.
  - Link: [Groq](https://groq.com/)
  - API docs: [Groq OpenAI-compatible API](https://console.groq.com/docs/openai)
- Banco de dados (Supabase): PostgreSQL gerenciado para persistencia de usuarios, inbox, sugestoes e entidades finais.
  - Link: [Supabase](https://supabase.com/)
  - Console: [Supabase Dashboard](https://supabase.com/dashboard)
- API em producao (Render): servico backend Go hospedado no Render.
  - Link: [Render](https://render.com/)
  - Docs: [Render Web Services](https://render.com/docs/web-services)
- Keep-alive com Cron: ping automatico da API a cada 15 minutos para manter o servico ativo.
  - Console: [cron-job.org](https://console.cron-job.org/jobs)
  - Plataforma: [cron-job.org](https://cron-job.org/)
  - Sugestao de endpoint monitorado: `GET /healthz` (ex.: `https://<seu-servico>.onrender.com/healthz`)

## Como rodar local

### 1) Backend

Requisitos:
- Go 1.25+
- Docker (opcional, para banco/API com compose)

Passos:

```bash
cd backend
cp .env.example .env
```

Edite `backend/.env` com os valores minimos:
- `DATABASE_URL`
- `JWT_SECRET`
- `AI_PROVIDER`
- `AI_API_KEY`
- `AI_BASE_URL`
- `AI_MODEL`

Rodar sem Docker:

```bash
cd backend
go run ./cmd/api
```

Rodar com Docker (API + Postgres):

```bash
cd backend
docker compose up --build
```

Endpoints uteis:
- `GET /healthz`
- `GET /readyz`
- `GET /swagger-ui/index.html`

### 2) App Flutter

Requisitos:
- Flutter 3.35.x

Passos:

1. Ajuste a URL da API em `app/lib/shared/services/http/app_service.dart`.
2. Instale as dependencias:

```bash
cd app
flutter pub get
```

3. Configure o Firebase para Android e iOS.

Arquivos esperados:
- `app/android/app/google-services.json`
- `app/ios/Runner/GoogleService-Info.plist`
- `app/lib/firebase_options.dart`

Os arquivos abaixo estao ignorados no git em `app/.gitignore`:
- `/android/app/google-services.json`
- `/ios/Runner/GoogleService-Info.plist`
- `/lib/firebase_options.dart`

Gerar `firebase_options.dart` com FlutterFire CLI:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
export PATH="$PATH:$HOME/.pub-cache/bin"
cd /Users/vanessa/Desktop/coding/personal/organiq/app
flutterfire configure \
  --project=organiq-app \
  --platforms=android,ios \
  --android-package-name=com.vxfontes.organiq \
  --ios-bundle-id=com.vxfontes.organiq \
  --out=lib/firebase_options.dart
```

Observacoes:
- O comando acima gera apenas `app/lib/firebase_options.dart`.
- Ele nao substitui `app/android/app/google-services.json`.
- Ele nao substitui `app/ios/Runner/GoogleService-Info.plist`.
- Para iOS, o arquivo `GoogleService-Info.plist` precisa estar adicionado ao target `Runner`.

4. Rode o app:

```bash
cd app
flutter run
```

## Fluxo principal (MVP)

1. Usuario faz `signup` ou `login`.
2. Cria um item bruto no Inbox (`POST /v1/inbox-items`).
3. Reprocessa com IA quando necessario (`POST /v1/inbox-items/{id}/reprocess`).
4. Revisa e confirma para criar entidade final (`POST /v1/inbox-items/{id}/confirm`).
5. Consulta a entidade nas abas/listas de tarefas, lembretes, eventos ou compras.

## Documentacao

- API detalhada: `docs/api.md`
- Estrutura backend: `docs/backend-go-estrutura.md`
- Schema do banco: `docs/db-schema-v0.0.1.md`

## Roadmap resumido

- Melhorar pipeline automatico de processamento do Inbox.
- Evoluir entrada por compartilhamento e OCR.
- Expandir notificacoes e automacoes por contexto.
- Hardening de observabilidade, testes e UX.
