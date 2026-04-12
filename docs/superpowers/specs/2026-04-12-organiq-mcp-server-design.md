# Design: Organiq MCP Server

**Date:** 2026-04-12  
**Status:** Approved  
**Scope:** MCP server TypeScript para expor a API do Organiq ao Claude Code

---

## Objetivo

Criar um MCP server em TypeScript que permita ao Claude Code interagir com a API do Organiq via tools. O server roda localmente via stdio, sem necessidade de hospedagem, e se autentica automaticamente usando token JWT fixo ou credenciais de login.

---

## Arquitetura

### Localização no monorepo

```
organiq/
├── app/
├── backend/
├── db/
├── docs/
└── mcp/              ← novo
    ├── src/
    │   ├── index.ts
    │   ├── client.ts
    │   ├── types.ts
    │   └── tools/
    │       ├── auth.ts
    │       ├── inbox.ts
    │       ├── tasks.ts
    │       ├── reminders.ts
    │       ├── events.ts
    │       ├── shopping.ts
    │       └── agenda.ts
    ├── package.json
    ├── tsconfig.json
    └── .env.example
```

### Stack

- Runtime: Node.js
- Linguagem: TypeScript
- SDK: `@modelcontextprotocol/sdk` (oficial Anthropic)
- Transporte: stdio
- HTTP client: `fetch` nativo (Node 18+)

---

## Autenticação

**Variáveis de ambiente:**

```bash
ORGANIQ_BASE_URL=http://localhost:8080
ORGANIQ_TOKEN=           # JWT fixo (prioritário)
ORGANIQ_EMAIL=           # usado se TOKEN ausente
ORGANIQ_PASSWORD=        # usado se TOKEN ausente
```

**Lógica em `client.ts`:**

1. Se `ORGANIQ_TOKEN` presente → usa diretamente em todos os requests
2. Se não → faz `POST /v1/auth/login` com `ORGANIQ_EMAIL` + `ORGANIQ_PASSWORD` na inicialização e armazena token em memória
3. Se nenhum dos dois → lança erro descritivo e encerra o processo

Token é adicionado como header `Authorization: Bearer <token>` em todas as chamadas autenticadas.

---

## Tools expostas (27 total)

### Auth (2)

| Tool | Método + Endpoint | Descrição |
|------|-------------------|-----------|
| `auth_me` | `GET /v1/me` | Retorna perfil do usuário autenticado |
| `auth_login` | `POST /v1/auth/login` | Faz login e atualiza token em memória |

### Inbox (6)

| Tool | Método + Endpoint | Descrição |
|------|-------------------|-----------|
| `inbox_list` | `GET /v1/inbox-items` | Lista itens do inbox (filtros: status, source) |
| `inbox_get` | `GET /v1/inbox-items/{id}` | Busca item por ID com sugestão da IA |
| `inbox_create` | `POST /v1/inbox-items` | Cria item bruto no inbox |
| `inbox_reprocess` | `POST /v1/inbox-items/{id}/reprocess` | Reprocessa item com IA |
| `inbox_confirm` | `POST /v1/inbox-items/{id}/confirm` | Confirma e cria entidade final |
| `inbox_dismiss` | `POST /v1/inbox-items/{id}/dismiss` | Descarta item |

**Payloads do `inbox_confirm` por tipo:**
- `task`: `{ type, title, flagId?, subflagId?, payload: { dueAt? } }`
- `reminder`: `{ type, title, flagId?, subflagId?, payload: { at } }`
- `event`: `{ type, title, flagId?, subflagId?, payload: { start, end?, allDay } }`
- `shopping`: `{ type, title, payload: { items: [{ title, quantity? }] } }`

### Tasks (4)

| Tool | Método + Endpoint | Descrição |
|------|-------------------|-----------|
| `tasks_list` | `GET /v1/tasks` | Lista tasks (limit, cursor) |
| `tasks_create` | `POST /v1/tasks` | Cria task diretamente |
| `tasks_update` | `PATCH /v1/tasks/{id}` | Atualiza título, status, dueAt, flagId, subflagId |
| `tasks_delete` | `DELETE /v1/tasks/{id}` | Remove task |

### Reminders (4)

| Tool | Método + Endpoint | Descrição |
|------|-------------------|-----------|
| `reminders_list` | `GET /v1/reminders` | Lista reminders |
| `reminders_create` | `POST /v1/reminders` | Cria reminder |
| `reminders_update` | `PATCH /v1/reminders/{id}` | Atualiza |
| `reminders_delete` | `DELETE /v1/reminders/{id}` | Remove |

### Events (4)

| Tool | Método + Endpoint | Descrição |
|------|-------------------|-----------|
| `events_list` | `GET /v1/events` | Lista eventos |
| `events_create` | `POST /v1/events` | Cria evento |
| `events_update` | `PATCH /v1/events/{id}` | Atualiza |
| `events_delete` | `DELETE /v1/events/{id}` | Remove |

### Shopping (7)

| Tool | Método + Endpoint | Descrição |
|------|-------------------|-----------|
| `shopping_lists_list` | `GET /v1/shopping-lists` | Lista listas de compras |
| `shopping_lists_create` | `POST /v1/shopping-lists` | Cria lista |
| `shopping_lists_update` | `PATCH /v1/shopping-lists/{id}` | Atualiza título/status |
| `shopping_lists_delete` | `DELETE /v1/shopping-lists/{id}` | Remove lista |
| `shopping_items_list` | `GET /v1/shopping-lists/{id}/items` | Lista itens de uma lista |
| `shopping_items_create` | `POST /v1/shopping-lists/{id}/items` | Adiciona item |
| `shopping_items_update` | `PATCH /v1/shopping-items/{id}` | Atualiza item (checked, title, quantity) |
| `shopping_items_delete` | `DELETE /v1/shopping-items/{id}` | Remove item |

### Agenda (1)

| Tool | Método + Endpoint | Descrição |
|------|-------------------|-----------|
| `agenda_get` | `GET /v1/agenda` | View unificada: tasks + reminders + events |

---

## Tratamento de erros

- Erros HTTP 4xx/5xx: extraem campo `error` da resposta JSON e retornam como mensagem descritiva ao Claude
- Erros de rede/timeout: mensagem descritiva sem stacktrace
- Erro de configuração (sem credenciais): encerra na inicialização com mensagem clara
- Formato: `Error: <codigo_erro_da_api> — <detalhes opcionais>`

---

## Configuração no Claude Code

Adicionar ao `~/.claude/claude_desktop_config.json` (ou settings do Claude Code):

```json
{
  "mcpServers": {
    "organiq": {
      "command": "node",
      "args": ["/caminho/absoluto/organiq/mcp/dist/index.js"],
      "env": {
        "ORGANIQ_BASE_URL": "https://sua-api.onrender.com",
        "ORGANIQ_TOKEN": "seu-jwt-aqui"
      }
    }
  }
}
```

O `mcp/README.md` vai incluir instruções de build (`npm run build`) e de configuração.

---

## Fora do escopo (v1)

- Flags e subflags (CRUD não exposto — são dados de configuração)
- Context rules (idem)
- Refresh automático de token expirado
- Testes automatizados
- Mode SSE/HTTP (apenas stdio)
