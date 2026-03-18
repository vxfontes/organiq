# Planejamento de Frontend Web em React (baseado no codigo atual)

## 1. Base usada neste planejamento
Este plano foi montado a partir do codigo atual do monorepo:
- App Flutter: `app/lib/presentation`, `app/lib/modules`, `app/lib/shared`
- Backend Go: `backend/internal/http/router.go` e handlers
- Contrato HTTP: `docs/api.md`
- Design tokens/componentes: `app/lib/shared/theme/*`, `app/lib/shared/components/oq_lib/*`, `docs/oq_components.md`

Arquivos chave analisados para mapear escopo real:
- `app/lib/presentation/routes/app_routes.dart`
- `app/lib/presentation/screens/*`
- `app/lib/shared/services/http/app_path.dart`
- `app/lib/modules/*/data/repositories/*`
- `backend/internal/http/router.go`

## 2. Objetivo
Construir uma versao web em React com paridade funcional com o app Flutter atual, consumindo o mesmo backend Go (`/v1`) e sem quebrar os fluxos de negocio ja existentes.

Objetivos de produto para a web:
- Login, sessao e navegacao autenticada
- Fluxos principais (Home, Cronograma, IA/Create, Compras, Agenda, Lembretes/Tarefas)
- Configuracoes (Conta, Contextos, Notificacoes)
- Historico de notificacoes

## 3. Diagnostico do produto atual (estado real)

### 3.1 Rotas atuais no Flutter
Rotas publicas:
- `/` (splash)
- `/auth`
- `/auth/login`
- `/auth/signup`

Rotas autenticadas:
- `/root/home`
- `/root/schedule`
- `/root/reminders`
- `/root/create`
- `/root/shopping`
- `/root/events`
- `/settings`
- `/settings/account`
- `/settings/contexts`
- `/settings/notifications`
- `/notification-history`

### 3.2 Modulos de dominio ja implementados
- `auth`
- `home`
- `inbox`
- `tasks`
- `reminders`
- `events`
- `routines`
- `shopping`
- `flags` (contextos)
- `notifications`
- `splash`

### 3.3 Integracoes especiais existentes no app mobile
- Push notifications (FCM mobile) via `PushNotificationService`
- Transcricao de voz via `speech_to_text`
- Widget bridge iOS via `MethodChannel`

Impacto na versao web:
- Widget iOS/macOS nao entra no frontend web
- Voz pode ser portada com Web Speech API (fase posterior)
- Push web exige service worker e configuracao FCM Web (nao pronto hoje)

## 4. Decisoes de arquitetura recomendadas para o frontend web

### 4.1 Stack
- React + Next.js (App Router) + TypeScript estrito
- TanStack Query para estado de servidor/cache
- React Hook Form + Zod para formularios/validacao
- Zustand (ou Context + reducer) para estado de UI local
- CSS variables + Tailwind (ou CSS Modules) para Design System OQ
- Vitest + Testing Library + Playwright para testes

### 4.2 Principios de implementacao
- Reusar contrato HTTP atual sem criar backend paralelo
- Manter separacao por feature (similar ao `modules/*` do Flutter)
- Centralizar cliente HTTP, tratamento de erros e mapeamento de codigos
- Renderizar UI orientada a estados: `loading`, `empty`, `error`, `ready`

## 5. Estrutura de pastas sugerida (web)

```text
web/
  src/
    app/
      (public)/
        auth/
          page.tsx
          login/page.tsx
          signup/page.tsx
      (protected)/
        app/
          home/page.tsx
          schedule/page.tsx
          reminders/page.tsx
          create/page.tsx
          shopping/page.tsx
          events/page.tsx
        settings/
          page.tsx
          account/page.tsx
          contexts/page.tsx
          notifications/page.tsx
        notification-history/page.tsx
      layout.tsx
      providers.tsx
    features/
      auth/
      home/
      schedule/
      reminders/
      create/
      shopping/
      events/
      settings/
      notifications/
      contexts/
    shared/
      api/
        http-client.ts
        error-mapper.ts
        auth-interceptor.ts
      config/
        env.ts
      ui/
        oq-design-system/
      utils/
      types/
    tests/
      e2e/
      integration/
```

## 6. Requisitos tecnicos obrigatorios

### 6.1 Backend (Go) para suportar web sem friccao
1. Adicionar CORS no backend (origens do frontend web, headers e metodos permitidos).
2. Garantir preflight `OPTIONS` para endpoints protegidos.
3. Expor `X-Request-Id` para diagnostico no frontend.
4. Validar limites/paginacao de listas em chamadas web de alto volume.
5. Definir politica para auth no web:
- Fase 1: manter JWT Bearer em header (igual mobile).
- Fase 2 (recomendado): migrar para cookie `HttpOnly` + `SameSite` para reduzir risco de XSS.

### 6.2 Frontend
1. Config de ambiente por `.env`:
- `NEXT_PUBLIC_API_HOST=https://...`
2. Cliente HTTP com:
- base URL `${API_HOST}/v1`
- injecao de `Authorization: Bearer <token>`
- suporte a `limit`/`cursor`
- erro padrao mapeado por codigo (`invalid_credentials`, `not_found`, etc)
3. Guardas de rota por sessao valida (`GET /v1/me`).
4. Timezone e locale baseados em usuario + navegador.

## 7. Mapa de funcionalidades que o frontend React precisa ter

### 7.1 Auth e sessao
Obrigatorio:
- Pagina pre-login (`/auth`)
- Login (`/auth/login`)
- Signup (`/auth/signup`)
- Persistencia de token
- Bootstrap de sessao no carregamento (`/healthz` + `/me`)
- Logout limpo

Paridade de validacoes:
- Email valido
- Senha minima
- Nome minimo
- Captura de `locale` e `timezone` no cadastro

### 7.2 Shell autenticado
Obrigatorio:
- Layout com topbar e navegação principal
- Acesso para: Home, Cronograma, Create, Compras, Agenda
- Acesso para Settings e Historico de notificacoes
- Responsivo desktop e mobile

### 7.3 Home (`/app/home`)
Obrigatorio:
- Carregar dashboard (`GET /v1/home/dashboard`)
- Header dinamico + week strip
- Next actions timeline
- Cards de progresso diario e insights
- Lista de tarefas foco
- Quick Add atomico:
  - `POST /v1/inbox-items`
  - `POST /v1/inbox-items/{id}/reprocess`
  - `POST /v1/inbox-items/{id}/confirm`
- Marcar item da timeline como concluido (task/reminder/routine)

### 7.4 Cronograma (`/app/schedule`)
Obrigatorio:
- Visao diaria e semanal
- CRUD de rotinas
- Toggle de ativo/inativo
- Completar e desfazer conclusao por data
- Pular rotina no dia (exceptions)
- Excluir rotina
- Detalhes: historico e streak
- Vinculo com flag/subflag

### 7.5 Lembretes e tarefas (`/app/reminders`)
Obrigatorio:
- Lista de tarefas com toggle `OPEN/DONE`
- Regra visual de done com grace period (2s) antes de sumir da lista ativa
- Criar tarefa (titulo, descricao, dueAt, flag)
- Excluir tarefa
- Lista de lembretes do dia e proximos dias
- Criar lembrete (titulo, remindAt, flag, subflag)

### 7.6 Create IA (`/app/create`)
Obrigatorio:
- Fluxo por fases: input -> processing -> review -> confirming -> done
- Entrada multiline de texto
- Processamento por linha (create/reprocess)
- Revisao de sugestoes
- Edicao de sugestao (titulo, tipo, payload, flag, subflag)
- Confirmacao em lote
- Resultado por linha com contadores (tasks/reminders/events/shopping/routines)
- Excluir item criado a partir da tela de resultado

Opcional fase 2:
- Captura de voz via Web Speech API

### 7.7 Compras (`/app/shopping`)
Obrigatorio:
- Listar listas abertas
- Carregar itens por lista
- Criar lista
- Criar item
- Toggle checked
- Excluir item
- Concluir lista quando todos itens estiverem checked
- Excluir lista

### 7.8 Agenda (`/app/events`)
Obrigatorio:
- Calendario horizontal por dia
- Filtros: todos/eventos/tarefas/lembretes
- Feed por dia usando `GET /v1/agenda`
- Criar evento
- Excluir item visivel (event/todo/reminder)

### 7.9 Configuracoes (`/settings/*`)
Obrigatorio:
- `settings`: menu + logout
- `settings/account`: dados do usuario (`/me`)
- `settings/contexts`:
  - CRUD de flags
  - CRUD de subflags
- `settings/notifications`:
  - preferencias por modulo
  - quiet hours
  - daily digest
  - daily summary token (consultar e rotacionar)
  - enviar teste de email digest

### 7.10 Historico de notificacoes (`/notification-history`)
Obrigatorio:
- Listar notificacoes
- Marcar individual como lida
- Marcar todas como lidas

## 8. Matriz de endpoints usados pelo frontend web

Auth e sessao:
- `GET /healthz`
- `POST /v1/auth/signup`
- `POST /v1/auth/login`
- `GET /v1/me`

Home e IA:
- `GET /v1/home/dashboard`
- `POST /v1/inbox-items`
- `POST /v1/inbox-items/:id/reprocess`
- `POST /v1/inbox-items/:id/confirm`

Tasks/Reminders/Events:
- `GET/POST/PATCH/DELETE /v1/tasks`
- `GET/POST/PATCH/DELETE /v1/reminders`
- `GET/POST/PATCH/DELETE /v1/events`
- `GET /v1/agenda`

Routines:
- `GET /v1/routines`
- `GET /v1/routines/day/:weekday`
- `GET /v1/routines/today/summary`
- `GET /v1/routines/:id`
- `POST /v1/routines`
- `PATCH /v1/routines/:id`
- `DELETE /v1/routines/:id`
- `PATCH /v1/routines/:id/toggle`
- `POST /v1/routines/:id/complete`
- `DELETE /v1/routines/:id/complete/:date`
- `GET /v1/routines/:id/history`
- `GET /v1/routines/:id/streak`
- `POST /v1/routines/:id/exceptions`
- `DELETE /v1/routines/:id/exceptions/:date`

Shopping:
- `GET/POST/PATCH/DELETE /v1/shopping-lists`
- `GET/POST /v1/shopping-lists/:id/items`
- `PATCH/DELETE /v1/shopping-items/:id`

Contextos:
- `GET/POST/PATCH/DELETE /v1/flags`
- `GET/POST /v1/flags/:id/subflags`
- `PATCH/DELETE /v1/subflags/:id`

Notificacoes:
- `GET/PUT /v1/notification-preferences`
- `GET /v1/notification-preferences/daily-summary-token`
- `POST /v1/notification-preferences/daily-summary-token/rotate`
- `GET /v1/notifications`
- `PATCH /v1/notifications/:id/read`
- `PATCH /v1/notifications/read-all`
- `POST /v1/notifications/test` (opcional na UI web)
- `POST /v1/digest/test`

## 9. Design System OQ no React (paridade visual)
Componentes base que precisam existir no web:
- AppBar / LightAppBar
- BottomNav (ou SideNav responsiva)
- Button (primary/secondary/ghost)
- Card
- Chip e ChipGroup
- ColorPicker
- DateField e TimeField
- EmptyState
- Loader
- Snackbar/Toast
- TodoList / ItemCard / TagChip

Tokens que devem ser portadaos de `AppColors`:
- Background/surface/border/text
- Primaria teal (`primary700`, `primary600`, `primary500`, `primary200`)
- Acentos (`ai600`, `warning500`, `danger600`, `success600`)
- Tipografia Manrope

## 10. Estado, cache e sincronizacao

Padrao recomendado:
- TanStack Query para dados remotos por feature
- Mutations com invalidacao de chaves afetadas
- Optimistic update apenas onde ja existe comportamento claro no Flutter
- Query keys padrao:
  - `['me']`
  - `['home-dashboard']`
  - `['tasks', filters]`
  - `['reminders', filters]`
  - `['agenda', filters]`
  - `['shopping-lists']`
  - `['shopping-items', listId]`
  - `['routines', filters]`
  - `['flags']`
  - `['subflags', flagId]`
  - `['notification-prefs']`
  - `['notifications']`

## 11. Qualidade obrigatoria

### 11.1 Testes
- Unit tests para utilitarios, mappers e validadores
- Integration tests para hooks e formulários por feature
- E2E para fluxos criticos:
  - signup/login/logout
  - quick add completo (inbox -> reprocess -> confirm)
  - criar e concluir rotina
  - criar tarefa/lembrete/evento
  - criar e concluir lista de compras
  - CRUD de flags/subflags

### 11.2 Acessibilidade
- Navegacao por teclado
- Foco visivel em controles
- Labels corretos em inputs e botoes
- Contraste minimo WCAG AA
- Estados de erro e loading anunciaveis

### 11.3 Performance
- Code splitting por rota/feature
- Lazy loading para modais pesados
- Evitar waterfalls de requests
- Cache de listas com stale times adequados

## 12. Plano de execucao por fases

### Fase 0 - Fundacao (infra) [3 a 5 dias]
- Setup `web/` com Next + TS
- ESLint/Prettier/CI
- Cliente HTTP + auth + error mapper
- Providers globais (QueryClient, Toast, Session)
- Layout base publico/protegido

### Fase 1 - Auth + bootstrap [3 a 5 dias]
- Splash check (`/healthz` + `/me`)
- Paginas auth
- Persistencia de token e guardas de rota
- Logout

### Fase 2 - Home + Quick Add [5 a 7 dias]
- Home dashboard
- Timeline e acoes de conclusao
- Quick Add atomico completo

### Fase 3 - Agenda operacional [7 a 10 dias]
- Schedule (rotinas)
- Reminders/Tasks
- Events/Agenda

### Fase 4 - Create IA + Shopping [5 a 8 dias]
- Fluxo multi-fase de Create
- Shopping lists/items

### Fase 5 - Settings + Notifications [4 a 6 dias]
- Account
- Contextos (flags/subflags)
- Notificacoes e token diario
- Historico de notificacoes

### Fase 6 - Hardening e Go-live [4 a 6 dias]
- A11y
- Performance
- E2E full suite
- Monitoracao e rollout gradual

## 13. Checklist de Definition of Done

Checklist funcional:
- Paridade dos fluxos principais entregue
- Todos endpoints criticos validados em ambiente real
- Tratamento de erro consistente por codigo da API

Checklist tecnico:
- Sem secrets em codigo
- Env vars por ambiente funcionando
- CORS validado para producao
- Logs com `X-Request-Id` visiveis no frontend

Checklist de qualidade:
- E2E de fluxos criticos passando
- Sem regressao visual grave em desktop/mobile
- Sem erros de console bloqueantes

## 14. Riscos e mitigacoes

Risco 1: backend sem CORS hoje.
- Mitigacao: implementar middleware CORS antes da fase 1.

Risco 2: JWT em localStorage (seguranca).
- Mitigacao: fase 1 com hardening de CSP; planejar migracao para cookie HttpOnly.

Risco 3: diferenca de comportamento de voz e push entre mobile e web.
- Mitigacao: marcar como opcional na v1 web e entregar fallback textual.

Risco 4: muitos requests em telas compostas (ex.: shopping por lista).
- Mitigacao: paralelizar fetches, usar cache agressivo e avaliar endpoint agregado no backend.

Risco 5: divergencia visual entre Flutter e React.
- Mitigacao: criar Design System OQ web antes de construir telas complexas.

## 15. Entregavel imediato recomendado
1. Criar pasta `web/` com estrutura base e providers.
2. Implementar auth/splash web com API real.
3. Subir Home com `GET /v1/home/dashboard` e quick add.

Com isso, o projeto ja abre com um vertical slice completo (login -> home -> criar item via IA), reduzindo risco cedo.
