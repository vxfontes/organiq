# API Organiq (MVP)

Guia detalhado da API HTTP do Organiq. Este documento complementa o Swagger.

**Base URL**
- Local: `http://localhost:8080`

**Auth**
- Header obrigatorio nas rotas protegidas: `Authorization: Bearer <token>`
- Para ambiente MVP com JWT local:
  - `POST /v1/auth/signup`
  - `POST /v1/auth/login`
- `GET /v1/me` retorna o perfil do usuario do token.

**Request Id**
- Header de resposta: `X-Request-Id` (configuravel)
- Envie o header em chamadas para rastrear requisições.

**Erros**
- Formato:
```json
{"error":"codigo","requestId":"<id>"}
```
- Codigos comuns:
  - `missing_required_fields`
  - `connection_refused`
  - `timeout`
  - `invalid_status`
  - `invalid_source`
  - `invalid_type`
  - `invalid_payload`
  - `invalid_time_range`
  - `invalid_email`
  - `invalid_password`
  - `invalid_display_name`
  - `invalid_credentials`
  - `invalid_limit`
  - `invalid_cursor`
  - `not_found`
  - `dependency_missing`
  - `invalid_auth_header`
  - `invalid_token`
  - `unauthorized`
  - `internal_error`

**Paginacao**
- Query params: `limit`, `cursor`
- Response: `nextCursor`

**Observacao sobre cores**
- `flag.color` vem do proprio flag.
- `subflag.color` usa a cor do flag pai (subflag nao tem cor propria no schema).

**Compatibilidade de payload (mudanca recente)**
- As respostas agora retornam objetos completos em vez de IDs puros.
- Exemplos:
  - `flagId` -> `flag` (com `id`, `name`, `color`)
  - `subflagId` -> `subflag` (com `id`, `name`, `color`)
  - `sourceInboxItemId` -> `sourceInboxItem` (objeto completo)
  - `listId` -> `list` (objeto com `id`, `title`, `status`)
- Tasks: `POST/PATCH /v1/tasks` aceita `flagId`/`subflagId` e as respostas retornam `flag`/`subflag` quando definidos.
- Se o app esperava apenas IDs, ajuste os mappers.

**Limitacoes atuais**
- `POST /v1/inbox-items/{id}/reprocess` exige AI client configurado (se nao, retorna `dependency_missing`).
- Worker in-process (processamento automatico de `InboxItem` NEW) ainda nao foi implementado.

**Notas recentes**
- Signup/Login agora retornam erros no formato padrao da API (`ErrorResponse`).
- `reprocess` e `confirm` sao executados de forma atomica quando o banco esta habilitado.
  - Isso significa que as etapas internas (ex.: criar sugestao + atualizar status do inbox, ou criar entidade final + marcar inbox como CONFIRMED) rodam dentro de uma **transacao**.
  - Se alguma etapa falhar, nenhuma alteracao parcial fica salva no banco.
  - O resultado e um estado mais consistente, evitando sugestoes “orfãs” ou listas/tarefas criadas sem confirmar o inbox.

**Configuracao de IA (Groq)**
- Variaveis:
  - `AI_PROVIDER=groq`
  - `AI_API_KEY=<sua_api_key>`
  - `AI_BASE_URL=https://api.groq.com/openai/v1/chat/completions`
  - `AI_MODEL=llama-3.3-70b-versatile` (exemplo)
  - `AI_TIMEOUT=15s`
  - `AI_MAX_RETRIES=2`
- O endpoint usado segue o formato OpenAI compat (chat completions).

**Fluxo E2E sugerido (MVP)**
1. `POST /v1/auth/signup` ou `POST /v1/auth/login`
2. `POST /v1/flags` e `POST /v1/flags/{id}/subflags`
3. `POST /v1/context-rules`
4. `POST /v1/inbox-items`
5. `POST /v1/inbox-items/{id}/reprocess` (ou processar manualmente)
6. `POST /v1/inbox-items/{id}/confirm`
7. Listar entidade final (`GET /v1/tasks` ou `GET /v1/reminders` etc.)

## Modelos (JSON)

**FlagObject**
```json
{"id":"uuid","name":"string","color":"#AABBCC"}
```

**SubflagObject**
```json
{"id":"uuid","name":"string","color":"#AABBCC"}
```

**InboxItemObject**
```json
{
  "id":"uuid",
  "source":"manual|share|ocr",
  "rawText":"string",
  "rawMediaUrl":"string|null",
  "status":"NEW|PROCESSING|SUGGESTED|NEEDS_REVIEW|CONFIRMED|DISMISSED",
  "lastError":"string|null",
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**AiSuggestionResponse**
```json
{
  "id":"uuid",
  "type":"task|reminder|event|shopping|note",
  "title":"string",
  "confidence":0.0,
  "flag":{"id":"uuid","name":"string","color":"#AABBCC"},
  "subflag":{"id":"uuid","name":"string","color":"#AABBCC"},
  "needsReview":true,
  "payload":{},
  "createdAt":"RFC3339"
}
```

**InboxItemResponse**
```json
{
  "id":"uuid",
  "source":"manual|share|ocr",
  "rawText":"string",
  "rawMediaUrl":"string|null",
  "status":"NEW|PROCESSING|SUGGESTED|NEEDS_REVIEW|CONFIRMED|DISMISSED",
  "lastError":"string|null",
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339",
  "suggestion": { ...AiSuggestionResponse }
}
```

**TaskResponse**
```json
{
  "id":"uuid",
  "title":"string",
  "description":"string|null",
  "status":"OPEN|DONE",
  "dueAt":"RFC3339|null",
  "flag": { ...FlagObject },
  "subflag": { ...SubflagObject },
  "sourceInboxItem": { ...InboxItemObject },
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**ReminderResponse**
```json
{
  "id":"uuid",
  "title":"string",
  "status":"OPEN|DONE",
  "remindAt":"RFC3339|null",
  "flag": { ...FlagObject },
  "subflag": { ...SubflagObject },
  "sourceInboxItem": { ...InboxItemObject },
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**EventResponse**
```json
{
  "id":"uuid",
  "title":"string",
  "startAt":"RFC3339|null",
  "endAt":"RFC3339|null",
  "allDay":false,
  "location":"string|null",
  "flag": { ...FlagObject },
  "subflag": { ...SubflagObject },
  "sourceInboxItem": { ...InboxItemObject },
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**ShoppingListObject**
```json
{"id":"uuid","title":"string","status":"OPEN|DONE|ARCHIVED"}
```

**ShoppingListResponse**
```json
{
  "id":"uuid",
  "title":"string",
  "status":"OPEN|DONE|ARCHIVED",
  "sourceInboxItem": { ...InboxItemObject },
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**ShoppingItemResponse**
```json
{
  "id":"uuid",
  "list": { ...ShoppingListObject },
  "title":"string",
  "quantity":"string|null",
  "checked":false,
  "sortOrder":0,
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

## Endpoints

**Health**
- `GET /healthz`
- `GET /readyz`

**Auth (JWT local)**
- `POST /v1/auth/signup`
  - Body: `email`, `password`, `displayName`, `locale`, `timezone`
  - Validacoes:
    - `email`: formato valido
    - `password`: 8 a 72 caracteres
    - `displayName`: 2 a 60 caracteres
  - Response: `AuthResponse` (token + user)
- `POST /v1/auth/login`
  - Body: `email`, `password`
  - Response: `AuthResponse`

**Me**
- `GET /v1/me`
  - Header: `Authorization: Bearer <token>`
  - Response: `AuthResponse` (sem token)

**Flags**
- `GET /v1/flags`
- `POST /v1/flags` (name required, color optional, sortOrder optional)
- `PATCH /v1/flags/{id}` (name/color/sortOrder)
- `DELETE /v1/flags/{id}`

**Subflags**
- `GET /v1/flags/{id}/subflags`
- `POST /v1/flags/{id}/subflags` (name required, sortOrder optional)
- `PATCH /v1/subflags/{id}` (name/sortOrder)
- `DELETE /v1/subflags/{id}`

**Context Rules**
- `GET /v1/context-rules`
- `POST /v1/context-rules` (keyword, flagId required, subflagId optional)
- `PATCH /v1/context-rules/{id}` (keyword/flagId/subflagId)
- `DELETE /v1/context-rules/{id}`

**Inbox**
- `GET /v1/inbox-items` (filters: `status`, `source`)
- `POST /v1/inbox-items` (rawText required, source optional)
- `GET /v1/inbox-items/{id}`
- `POST /v1/inbox-items/{id}/reprocess`
- `POST /v1/inbox-items/{id}/confirm`
- `POST /v1/inbox-items/{id}/dismiss`

**Agenda**
- `GET /v1/agenda` (retorna `events`, `tasks` e `reminders` em uma chamada)

**Entidades finais**
- Tasks:
  - `GET /v1/tasks`
  - `POST /v1/tasks`
  - `PATCH /v1/tasks/{id}`
  - `DELETE /v1/tasks/{id}`
- Reminders:
  - `GET /v1/reminders`
  - `POST /v1/reminders`
  - `PATCH /v1/reminders/{id}`
  - `DELETE /v1/reminders/{id}`
- Events:
  - `GET /v1/events`
  - `POST /v1/events`
  - `PATCH /v1/events/{id}`
  - `DELETE /v1/events/{id}`
- Shopping lists:
  - `GET /v1/shopping-lists`
  - `POST /v1/shopping-lists`
  - `PATCH /v1/shopping-lists/{id}`
  - `DELETE /v1/shopping-lists/{id}`
- Shopping items:
  - `GET /v1/shopping-lists/{id}/items`
  - `POST /v1/shopping-lists/{id}/items`
  - `PATCH /v1/shopping-items/{id}`
  - `DELETE /v1/shopping-items/{id}`

## Exemplos de resposta

`POST /v1/auth/signup` ou `POST /v1/auth/login`
```json
{
  "token":"<jwt>",
  "user":{
    "id":"c8449ed8-eb49-4b99-a77e-0be27d3bdab3",
    "email":"vanessa@email.com",
    "displayName":"Vanessa",
    "locale":"pt-BR",
    "timezone":"America/Sao_Paulo"
  }
}
```

`GET /v1/me`
```json
{
  "token":"",
  "user":{
    "id":"c8449ed8-eb49-4b99-a77e-0be27d3bdab3",
    "email":"vanessa@email.com",
    "displayName":"Vanessa",
    "locale":"pt-BR",
    "timezone":"America/Sao_Paulo"
  }
}
```

`GET /v1/flags`
```json
{
  "items":[
    {
      "id":"3c36bb23-7dfb-4f01-9c65-8b80c4ee22e4",
      "name":"Financas",
      "color":"#4A90E2",
      "sortOrder":0,
      "createdAt":"2026-02-10T17:35:12Z",
      "updatedAt":"2026-02-10T17:35:12Z"
    }
  ],
  "nextCursor":null
}
```

`POST /v1/flags`
```json
{
  "id":"3c36bb23-7dfb-4f01-9c65-8b80c4ee22e4",
  "name":"Financas",
  "color":"#4A90E2",
  "sortOrder":0,
  "createdAt":"2026-02-10T17:35:12Z",
  "updatedAt":"2026-02-10T17:35:12Z"
}
```

`GET /v1/flags/{id}/subflags`
```json
{
  "items":[
    {
      "id":"c2a3e3b1-0f87-4c7e-b5e7-5a64ec0e4d8b",
      "flag":{"id":"3c36bb23-7dfb-4f01-9c65-8b80c4ee22e4","name":"Financas","color":"#4A90E2"},
      "name":"Pix",
      "color":"#4A90E2",
      "sortOrder":0,
      "createdAt":"2026-02-10T17:36:02Z",
      "updatedAt":"2026-02-10T17:36:02Z"
    }
  ],
  "nextCursor":null
}
```

`GET /v1/context-rules`
```json
{
  "items":[
    {
      "id":"ab3d2c2a-2d9b-4b7d-9f0b-1b0c8d6cf2ce",
      "keyword":"pix",
      "flag":{"id":"3c36bb23-7dfb-4f01-9c65-8b80c4ee22e4","name":"Financas","color":"#4A90E2"},
      "subflag":{"id":"c2a3e3b1-0f87-4c7e-b5e7-5a64ec0e4d8b","name":"Pix","color":"#4A90E2"},
      "createdAt":"2026-02-10T17:37:11Z",
      "updatedAt":"2026-02-10T17:37:11Z"
    }
  ],
  "nextCursor":null
}
```

`GET /v1/inbox-items`
```json
{
  "items":[
    {
      "id":"1f6553c4-56c1-4aa7-8c8a-4e8f1b3e2af8",
      "source":"manual",
      "rawText":"Pagar aluguel dia 05",
      "rawMediaUrl":null,
      "status":"SUGGESTED",
      "lastError":null,
      "createdAt":"2026-02-10T17:40:00Z",
      "updatedAt":"2026-02-10T17:40:05Z",
      "suggestion":{
        "id":"e6c03c8e-98b5-4a16-bb62-7ed7c6f6c2d1",
        "type":"reminder",
        "title":"Pagar aluguel",
        "confidence":0.82,
        "flag":{"id":"3c36bb23-7dfb-4f01-9c65-8b80c4ee22e4","name":"Financas","color":"#4A90E2"},
        "subflag":{"id":"c2a3e3b1-0f87-4c7e-b5e7-5a64ec0e4d8b","name":"Pix","color":"#4A90E2"},
        "needsReview":false,
        "payload":{"at":"2026-03-05T12:00:00Z"},
        "createdAt":"2026-02-10T17:40:05Z"
      }
    }
  ],
  "nextCursor":null
}
```

`POST /v1/inbox-items`
```json
{
  "id":"1f6553c4-56c1-4aa7-8c8a-4e8f1b3e2af8",
  "source":"manual",
  "rawText":"Pagar aluguel dia 05",
  "rawMediaUrl":null,
  "status":"NEW",
  "lastError":null,
  "createdAt":"2026-02-10T17:40:00Z",
  "updatedAt":"2026-02-10T17:40:00Z",
  "suggestion":null
}
```

`POST /v1/inbox-items/{id}/confirm` (exemplo task)
```json
{
  "type":"task",
  "task":{
    "id":"6e2cf5b6-0cbe-4d8f-88f5-36e3c8d965db",
    "title":"Pagar aluguel",
    "description":null,
    "status":"OPEN",
    "dueAt":"2026-03-05T12:00:00Z",
    "flag":{"id":"3c36bb23-7dfb-4f01-9c65-8b80c4ee22e4","name":"Financas","color":"#4A90E2"},
    "subflag":{"id":"c2a3e3b1-0f87-4c7e-b5e7-5a64ec0e4d8b","name":"Pix","color":"#4A90E2"},
    "sourceInboxItem":{
      "id":"1f6553c4-56c1-4aa7-8c8a-4e8f1b3e2af8",
      "source":"manual",
      "rawText":"Pagar aluguel dia 05",
      "rawMediaUrl":null,
      "status":"CONFIRMED",
      "lastError":null,
      "createdAt":"2026-02-10T17:40:00Z",
      "updatedAt":"2026-02-10T17:40:10Z"
    },
    "createdAt":"2026-02-10T17:40:10Z",
    "updatedAt":"2026-02-10T17:40:10Z"
  }
}
```

`GET /v1/tasks`
```json
{
  "items":[
    {
      "id":"6e2cf5b6-0cbe-4d8f-88f5-36e3c8d965db",
      "title":"Pagar aluguel",
      "description":null,
      "status":"OPEN",
      "dueAt":"2026-03-05T12:00:00Z",
      "flag":{"id":"3c36bb23-7dfb-4f01-9c65-8b80c4ee22e4","name":"Financas","color":"#4A90E2"},
      "subflag":{"id":"c2a3e3b1-0f87-4c7e-b5e7-5a64ec0e4d8b","name":"Pix","color":"#4A90E2"},
      "sourceInboxItem":{
        "id":"1f6553c4-56c1-4aa7-8c8a-4e8f1b3e2af8",
        "source":"manual",
        "rawText":"Pagar aluguel dia 05",
        "rawMediaUrl":null,
        "status":"CONFIRMED",
        "lastError":null,
        "createdAt":"2026-02-10T17:40:00Z",
        "updatedAt":"2026-02-10T17:40:10Z"
      },
      "createdAt":"2026-02-10T17:40:10Z",
      "updatedAt":"2026-02-10T17:40:10Z"
    }
  ],
  "nextCursor":null
}
```

`GET /v1/reminders`
```json
{
  "items":[
    {
      "id":"f00a0d2c-4e3c-4f62-9fd4-2f0f8e8829f8",
      "title":"Pagar aluguel",
      "status":"OPEN",
      "remindAt":"2026-03-05T12:00:00Z",
      "sourceInboxItem":null,
      "createdAt":"2026-02-10T17:41:01Z",
      "updatedAt":"2026-02-10T17:41:01Z"
    }
  ],
  "nextCursor":null
}
```

`GET /v1/events`
```json
{
  "items":[
    {
      "id":"9a1f1a3c-7a4f-4b31-9e25-21f7b0f3c8ae",
      "title":"Reuniao time",
      "startAt":"2026-03-01T14:00:00Z",
      "endAt":"2026-03-01T15:00:00Z",
      "allDay":false,
      "location":"Sala 2",
      "sourceInboxItem":null,
      "createdAt":"2026-02-10T17:42:12Z",
      "updatedAt":"2026-02-10T17:42:12Z"
    }
  ],
  "nextCursor":null
}
```

`GET /v1/shopping-lists`
```json
{
  "items":[
    {
      "id":"2b03b7ae-7a6f-4b0b-9c86-7b594d146ff5",
      "title":"Mercado",
      "status":"OPEN",
      "sourceInboxItem":null,
      "createdAt":"2026-02-10T17:43:30Z",
      "updatedAt":"2026-02-10T17:43:30Z"
    }
  ],
  "nextCursor":null
}
```

`GET /v1/shopping-lists/{id}/items`
```json
{
  "items":[
    {
      "id":"f4d9c2b7-9b5c-43ef-9b91-7b7b1e5f13bf",
      "list":{"id":"2b03b7ae-7a6f-4b0b-9c86-7b594d146ff5","title":"Mercado","status":"OPEN"},
      "title":"Leite",
      "quantity":"2",
      "checked":false,
      "sortOrder":0,
      "createdAt":"2026-02-10T17:43:45Z",
      "updatedAt":"2026-02-10T17:43:45Z"
    }
  ],
  "nextCursor":null
}
```

`PATCH /v1/shopping-items/{id}`
```json
{
  "id":"f4d9c2b7-9b5c-43ef-9b91-7b7b1e5f13bf",
  "list":{"id":"2b03b7ae-7a6f-4b0b-9c86-7b594d146ff5","title":"Mercado","status":"OPEN"},
  "title":"Leite",
  "quantity":"2",
  "checked":true,
  "sortOrder":0,
  "createdAt":"2026-02-10T17:43:45Z",
  "updatedAt":"2026-02-10T17:44:10Z"
}
```

`DELETE` (qualquer recurso)
```json
<204 No Content>
```

## Confirm Inbox Payload (AI)

O endpoint `POST /v1/inbox-items/{id}/confirm` exige:
```json
{
  "type":"task|reminder|event|shopping",
  "title":"string",
  "flagId":"uuid|null",
  "subflagId":"uuid|null",
  "payload": { ... }
}
```

Payload por tipo:
- `task`: `{"dueAt":"RFC3339|null"}`
- `reminder`: `{"at":"RFC3339"}`
- `event`: `{"start":"RFC3339","end":"RFC3339|null","allDay":true}`
- `shopping`: `{"items":[{"title":"string","quantity":"string|null"}]}`

Validacoes:
- `reminder.at` obrigatorio.
- `event.end` nao pode ser menor que `event.start`.
- `shopping.items` nao pode ser vazio.

## Swagger

Gerar a doc:
```bash
cd backend
swag init -g cmd/api/main.go --parseInternal -o ./docs
```

Rodando via Docker, reinicie a API:
```bash
docker compose restart api
```

No Swagger UI use:
- `Authorize` -> `Bearer <token>`
