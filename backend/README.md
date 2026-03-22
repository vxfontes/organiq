# Organiq Backend (Go + Gin)

API do MVP usando Go e Gin para as rotas.

## Requisitos
- Go 1.25+

## Configuracao
Copie os exemplos de env e preencha as credenciais:
- Arquivo base: `backend/.env.example`
- Variaveis chave:
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `AI_PROVIDER`
  - `AI_API_KEY`
  - `AI_FALLBACK_API_KEY`
  - `SUGGESTION_AI_API_KEY`
  - `SUGGESTION_AI_FALLBACK_API_KEY`
  - `AI_BASE_URL`
  - `AI_MODEL`
  - `AI_TIMEOUT`
  - `AI_MAX_RETRIES`

## Rodar local
```bash
cd backend
go run ./cmd/api
```

## Seed (dados iniciais)
```bash
cd backend
go run ./cmd/seed
docker compose run --rm api go run ./cmd/seed
```

## Rodar com Docker (API + Postgres)
Dentro de `backend/`:
```bash
docker compose up --build
```

## Hot reload (Docker)
Com o `docker compose up`, a API usa `air` e recarrega ao salvar arquivos Go.

## Endpoints basicos
- `GET /healthz`
- `GET /readyz`
- `GET /swagger-ui/index.html`
- `GET /v1/agenda` (autenticado, feed combinado)

## Swagger (gerar docs)
```bash
cd backend
swag init -g cmd/api/main.go --parseInternal -o ./docs
```
Se o `swag` nao estiver instalado:
```bash
go install github.com/swaggo/swag/cmd/swag@latest
```
Se estiver rodando via Docker, reinicie o container da API para recarregar a nova doc:
```bash
docker compose restart api
```

## Observacoes
- O roteamento usa Gin (`github.com/gin-gonic/gin`).
- Em `APP_ENV=prod`, o Gin roda em `ReleaseMode`.
- Se for a primeira vez rodando, pode ser necessario baixar deps: `go mod download`.
