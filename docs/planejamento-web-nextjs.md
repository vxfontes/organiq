# Organiq Web - Versao Next.js

## Contexto

O Organiq e um app Flutter de produtividade com IA que transforma texto livre em tarefas, lembretes, eventos e listas de compras. Atualmente so existe versao mobile. O objetivo e criar uma **versao web com Next.js** para que o usuario acompanhe suas coisas de forma visual e facil no computador, consumindo a **mesma API backend** (Go, hospedada em Render).

Isso ja estava planejado no roadmap do projeto (`docs/todo-features.md`: "possivel site em react ou next").

O projeto web vivera em `/web` na raiz do monorepo, ao lado de `/app` (Flutter) e `/backend` (Go).

---

## Stack Tecnologica

| Camada | Tecnologia | Justificativa |
|---|---|---|
| Framework | **Next.js 14+ App Router** | Requisito do usuario |
| Linguagem | **TypeScript** (strict) | Tipagem segura |
| Estilo | **Tailwind CSS** | Requisito, tokens do design system mobile |
| Estado servidor | **TanStack React Query v5** | Cache, refetch, optimistic updates |
| Estado cliente | **Zustand** | Leve, para auth e UI state |
| Formularios | **React Hook Form + Zod** | Validacao tipada |
| HTTP | **fetch nativo** com wrapper | Next.js otimiza fetch |
| Toasts | **Sonner** | Substitui OQSnackbar |
| Dialogs | **Radix UI Dialog** | Acessivel, headless |
| Datas | **date-fns** | Leve, tree-shakeable |
| Icones | **Lucide React** | Estetica similar ao HugeIcons do mobile |
| Fonte | **Manrope** via `next/font/google` | Mesma do mobile |
| Testes | **Vitest + RTL + Playwright** | Unit/component/e2e |

---

## Estrutura de Pastas

```
web/
  .env.local                      # NEXT_PUBLIC_API_URL=https://inbota-api.onrender.com/v1
  next.config.ts
  tailwind.config.ts
  tsconfig.json
  package.json
  public/
    favicon.ico
  src/
    middleware.ts                  # Protecao de rotas autenticadas
    app/
      layout.tsx                  # Root: providers, font, metadata
      (auth)/
        layout.tsx                # Layout centralizado sem sidebar
        login/page.tsx
        signup/page.tsx
      (app)/
        layout.tsx                # Layout autenticado: sidebar + topbar
        page.tsx                  # Redirect para /home
        home/page.tsx
        schedule/page.tsx
        create/page.tsx
        reminders/page.tsx
        shopping/page.tsx
        events/page.tsx
        notifications/page.tsx
        settings/
          page.tsx                # Hub de settings
          account/page.tsx
          notifications/page.tsx
          contexts/page.tsx
      api/
        auth/
          login/route.ts          # Proxy: chama API + seta cookie httpOnly
          logout/route.ts         # Deleta cookie
    lib/
      api/
        client.ts                 # Wrapper fetch com JWT, error mapping
        paths.ts                  # Constantes de endpoint (port do AppPath)
        types/                    # Interfaces TS para todos os modelos
          auth.ts
          task.ts
          reminder.ts
          event.ts
          routine.ts
          shopping.ts
          inbox.ts
          suggestion.ts
          home.ts
          notification.ts
          flag.ts
        services/                 # Funcoes por dominio
          auth.service.ts
          task.service.ts
          reminder.service.ts
          event.service.ts
          routine.service.ts
          shopping.service.ts
          inbox.service.ts
          suggestion.service.ts
          home.service.ts
          notification.service.ts
          flag.service.ts
      hooks/                      # React Query hooks por dominio
        use-auth.ts
        use-tasks.ts
        use-reminders.ts
        use-events.ts
        use-routines.ts
        use-shopping.ts
        use-inbox.ts
        use-suggestions.ts
        use-home.ts
        use-notifications.ts
        use-flags.ts
      stores/
        auth.store.ts             # User session (Zustand)
        ui.store.ts               # Sidebar, modais, toasts
      providers/
        query-provider.tsx        # React Query provider
        auth-provider.tsx         # Contexto auth + hydrate user
      utils/
        date.ts                   # Formatacao de datas
        validators.ts             # Schemas Zod
        colors.ts                 # Utilitarios de cor para flags
    components/
      ui/                         # Primitivos do design system
        button.tsx
        card.tsx
        input.tsx
        textarea.tsx
        chip.tsx
        chip-group.tsx
        toggle.tsx
        skeleton.tsx
        empty-state.tsx
        badge.tsx
        dialog.tsx
        dropdown-menu.tsx
        toast.tsx
        progress-ring.tsx         # SVG circular (day progress)
        date-picker.tsx
        time-picker.tsx
        color-picker.tsx
      layout/
        sidebar.tsx               # Navegacao lateral fixa
        top-bar.tsx               # Barra superior: busca, notificacoes, user
        app-shell.tsx             # Sidebar + topbar + content area
      domain/                     # Componentes por feature
        home/
          dynamic-header.tsx
          quick-add-bar.tsx
          week-strip.tsx
          day-progress-card.tsx
          bento-grid.tsx
          timeline-carousel.tsx
          focus-task-list.tsx
          insight-card.tsx
        schedule/
          routine-card.tsx
          routine-day-view.tsx
          routine-week-view.tsx
          routine-form-dialog.tsx
          routine-detail-panel.tsx
          streak-badge.tsx
        create/
          ai-input-panel.tsx
          suggestion-review-list.tsx
          suggestion-card.tsx
          suggestion-chat.tsx
          processing-indicator.tsx
        reminders/
          reminder-list.tsx
          reminder-row.tsx
          reminder-form-dialog.tsx
          todo-section.tsx
          task-form-dialog.tsx
        shopping/
          shopping-list-card.tsx
          shopping-item-row.tsx
          shopping-list-form-dialog.tsx
          shopping-item-form-dialog.tsx
        events/
          event-feed-item.tsx
          event-calendar-strip.tsx
          event-type-filters.tsx
          event-form-dialog.tsx
        settings/
          account-section.tsx
          notification-prefs-section.tsx
          contexts-manager.tsx
          flag-card.tsx
        notifications/
          notification-card.tsx
          notification-list.tsx
```

---

## Autenticacao Web

### Fluxo

1. **Login/Signup**: Form no client submete para **Route Handler** Next.js (`/api/auth/login`)
2. Route Handler faz `POST` para `https://inbota-api.onrender.com/v1/auth/login`
3. Recebe `{ token, user }` da API
4. Seta cookie `oq-token` como `httpOnly`, `secure`, `sameSite: strict`, `path: /`
5. Retorna `user` para o client
6. Zustand `auth.store` armazena o user no client

### Protecao de Rotas

- `middleware.ts` intercepta todas as rotas `/(app)/*`
- Se cookie `oq-token` ausente → redirect para `/login`
- `auth-provider.tsx` chama `GET /me` no mount para validar token e hidratar user
- Em caso de 401 → limpa cookie via Route Handler + redirect para `/login`

### Logout

- Chama `/api/auth/logout` que deleta o cookie
- Limpa Zustand store
- Redirect para `/login`

---

## API Integration Layer

### Camada 1 - HTTP Client (`lib/api/client.ts`)

```typescript
// Wrapper sobre fetch que:
// - Injeta Authorization: Bearer <token> do cookie (server) ou header (client)
// - Parseia JSON, trata erros no formato { error: "codigo", requestId: "..." }
// - Mapeia erros para mensagens em PT-BR (port do ApiErrorMapper)
// - Em 401 → redireciona para login
```

### Camada 2 - Services (`lib/api/services/*.service.ts`)

Funcoes tipadas por dominio. Exemplo:
```typescript
// task.service.ts
export const getTasks = (params?: { limit?: number; cursor?: string }) =>
  client.get<TaskListResponse>(paths.tasks, { params })

export const createTask = (input: CreateTaskInput) =>
  client.post<TaskOutput>(paths.tasks, input)

export const updateTask = (id: string, input: UpdateTaskInput) =>
  client.patch<TaskOutput>(paths.taskById(id), input)

export const deleteTask = (id: string) =>
  client.delete(paths.taskById(id))
```

### Camada 3 - React Query Hooks (`lib/hooks/use-*.ts`)

```typescript
// use-tasks.ts
export const useTasks = (params?) => useQuery({ queryKey: ['tasks', params], queryFn: () => getTasks(params) })
export const useCreateTask = () => useMutation({ mutationFn: createTask, onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tasks'] }) })
```

### Paths (`lib/api/paths.ts`)

Port direto do `AppPath` Dart → TypeScript. Mesmos endpoints:
- Auth: `/auth/login`, `/auth/signup`, `/me`
- Tasks: `/tasks`, `/tasks/{id}`
- Reminders: `/reminders`, `/reminders/{id}`
- Events: `/events`, `/events/{id}`, `/agenda`
- Shopping: `/shopping-lists`, `/shopping-lists/{id}/items`, `/shopping-items/{id}`
- Routines: `/routines`, `/routines/{id}`, `/routines/{id}/toggle`, `/routines/{id}/complete`, `/routines/day/{weekday}`, `/routines/today/summary`, `/routines/{id}/history`, `/routines/{id}/streak`
- Inbox: `/inbox-items`, `/inbox-items/{id}/reprocess`, `/inbox-items/{id}/confirm`, `/inbox-items/{id}/dismiss`
- Suggestions: `/suggestions/chat`, `/suggestions/conversations/{id}`, `/suggestions/accept`
- Flags: `/flags`, `/flags/{id}`, `/flags/{id}/subflags`, `/subflags/{id}`
- Notifications: `/notifications`, `/notifications/{id}/read`, `/notifications/read-all`, `/notification-preferences`
- Home: `/home/dashboard`

---

## Design System Web (Tailwind Config)

### Cores (port exato do `AppColors`)

```javascript
// tailwind.config.ts - theme.extend.colors
{
  background: '#FAFAFA',
  surface: { DEFAULT: '#FFFFFF', soft: '#F8FAFC', '2': '#F3F4F6', warning: '#FFFBEB', ai: '#EEF2FF' },
  border: { DEFAULT: '#E5E7EB', strong: '#D1D5DB' },
  text: { DEFAULT: '#111827', muted: '#6B7280' },
  primary: { 50: '#F0FDFA', 100: '#CCFBF1', 200: '#99F6E4', 500: '#14B8A6', 600: '#0D9488', 700: '#0F766E' },
  ai: { 50: '#EEF2FF', 100: '#E0E7FF', 200: '#C7D2FE', 300: '#A5B4FC', 500: '#6366F1', 600: '#4F46E5', 700: '#4338CA' },
  warning: { 500: '#F59E0B', 600: '#EA580C' },
  danger: { 600: '#DC2626' },
  success: { 600: '#16A34A' },
}
```

### Tipografia

- Fonte: Manrope via `next/font/google`
- Mesmos pesos: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)

### Padroes Visuais

- Border radius: `rounded-xl` (12px) como padrao em cards
- Sombras suaves em cards: `shadow-sm`
- Skeleton loaders em todas as paginas durante loading
- Empty states com icone + mensagem + CTA em todas as listas vazias

---

## Paginas - Detalhamento

### 1. Login/Signup (`(auth)/`)

**Layout**: Card centralizado, fundo com gradiente suave. Desktop: split-screen (esquerda branding com logo + tagline "Sua rotina mais leve", direita formulario).

**Login**:
- Campos: email, password (validacao Zod)
- Submit → Route Handler → API → cookie + redirect `/home`
- Link para signup

**Signup**:
- Campos: displayName, email, password, confirmPassword
- Submit → Route Handler → API → cookie + redirect `/home`
- Link para login

---

### 2. Layout Autenticado (`(app)/layout.tsx`)

**Sidebar** (navegacao principal, substitui bottom nav do mobile):
- Largura: 240px expandida, 64px colapsada
- Itens: Home, Cronograma, Criar, Lembretes, Compras, Eventos
- Separador
- Itens secundarios: Notificacoes (com badge de nao-lidas), Configuracoes
- Rodape: Avatar + nome do usuario + dropdown logout
- Toggle colapso: botao ou `Cmd+B`

**TopBar**:
- Esquerda: Titulo da pagina atual
- Direita: Sino de notificacoes (badge count), menu do usuario

**Content Area**: Ocupa todo o espaco restante com padding consistente.

---

### 3. Home Dashboard (`(app)/home/`)

Dados: `GET /home/dashboard` → `HomeDashboardOutput`

**Layout desktop (3 colunas)**:

**Coluna principal (larga)**:
- **Dynamic Header**: Saudacao com nome do usuario + gradiente baseado no horario:
  - Manha (5h-12h): gradiente `morningStart → morningEnd`
  - Tarde (12h-17h): gradiente `afternoonStart → afternoonEnd`
  - Noite (17h-5h): gradiente `nightStart → nightEnd`
- **Quick Add Bar**: Input persistente no topo. Digita texto → `POST /inbox-items` → mostra sugestao inline para confirmar/dispensar
- **Timeline de proximas acoes**: Cards horizontais scrollaveis dos itens do `timeline`. Itens passados com opacidade reduzida, proximo item destacado. Cada card com botao de completar

**Bento Grid (2x3)**:
- **Day Progress Ring**: SVG circular com `dayProgress.progressPercent`, mostrando routines done/total e tasks done/total
- **Rotinas**: Card com contagem feitas/total do dia
- **Tarefas**: Card com contagem feitas/total
- **Lembretes**: Card com contagem do dia
- **Compras**: Preview com contagem de listas
- **Insight Card**: Texto da IA ou tarefa foco

**Focus Tasks**: Lista de `focusTasks` com checkbox para toggle de conclusao (`PATCH /tasks/{id}`)

**Week Strip**: Seletor horizontal de dias da semana com indicadores de densidade

---

### 4. Cronograma/Rotinas (`(app)/schedule/`)

Dados: `GET /routines/day/{weekday}`, `GET /routines/today/summary`, `GET /routines/{id}/streak`

**Layout desktop: 2 paineis**

**Painel esquerdo (lista)**:
- Toggle Daily/Weekly no topo
- **Daily View**: 7 tabs de dias da semana. Cards de rotinas agrupados por periodo:
  - Manha (05-12h), Tarde (12-17h), Noite (17-21h), Madrugada (21-05h)
  - Cada card: titulo, horario, checkbox de conclusao, badge de cor
  - Checkbox chama `POST /routines/{id}/complete`
- **Weekly View**: Grid 7 colunas mostrando mini-cards de rotinas por dia
- Botao "Nova Rotina" abre dialog

**Painel direito (detalhe)**:
- Aparece ao clicar numa rotina
- Info completa: titulo, descricao, dias, horario, recorrencia
- **Streak badge**: dados de `GET /routines/{id}/streak`
- **Historico**: heatmap de completude de `GET /routines/{id}/history`
- Botoes editar/excluir

**Dialog criar/editar rotina**: titulo, selecao de dias da semana (multi-select chips), horario inicio/fim (time pickers), tipo recorrencia (weekly/biweekly/monthly), flag/subflag (dropdowns)

---

### 5. Criar / Input IA (`(app)/create/`)

Dados: `POST /inbox-items`, `POST /inbox-items/{id}/reprocess`, `POST /inbox-items/{id}/confirm`, `POST /inbox-items/{id}/dismiss`, `POST /suggestions/chat`, `POST /suggestions/accept`

**Layout desktop: area principal + painel lateral**

**Modo 1 - Inbox Rapido** (padrao):
- Textarea grande para multi-linha
- Botao "Processar" envia cada linha como `POST /inbox-items` separado
- **Fase processing**: Indicador de progresso por linha com animacao pulse
- **Fase review**: Cards de sugestao para cada item:
  - Badge de tipo (tarefa/lembrete/evento/compra)
  - Titulo sugerido, data sugerida, flag sugerida
  - Botoes Confirmar (`POST /inbox-items/{id}/confirm`) e Dispensar (`POST /inbox-items/{id}/dismiss`)
- **Fase done**: Resumo dos itens criados com links para suas secoes

**Modo 2 - Chat IA** (Sugestoes):
- Interface de chat no estilo mensageiro
- Input de texto + envio via `POST /suggestions/chat`
- Mensagens do assistente renderizam `SuggestionBlock` como cards interativos
- Botao "Aceitar" chama `POST /suggestions/accept`
- Historico via `GET /suggestions/conversations/{id}`

**Toggle entre modos**: Tabs no topo (Inbox Rapido | Chat IA)

---

### 6. Lembretes e Tarefas (`(app)/reminders/`)

Dados: `GET /tasks`, `GET /reminders`, paginacao cursor-based para tasks

**Layout desktop: 2 colunas**

**Coluna esquerda - Tarefas (To-dos)**:
- Lista de tasks com toggle de status (OPEN/DONE)
- Toggle chama `PATCH /tasks/{id}` com `{ status: "DONE" }` ou `{ status: "OPEN" }`
- Scroll infinito com `useInfiniteQuery` (cursor pagination)
- Botao "Nova Tarefa" abre dialog
- Cada item: titulo, descricao truncada, data, badge de flag com cor

**Coluna direita - Lembretes**:
- Secao "Hoje": lembretes com `remindAt` = hoje
- Secao "Proximos": agrupados por data
- Toggle de conclusao via `PATCH /reminders/{id}`
- Botao "Novo Lembrete" abre dialog

**Dialog nova tarefa**: titulo, descricao (textarea), data (date picker), flag/subflag (selects populados de `GET /flags`)
**Dialog novo lembrete**: titulo, data+hora (date-time picker), flag

---

### 7. Listas de Compras (`(app)/shopping/`)

Dados: `GET /shopping-lists`, `GET /shopping-lists/{id}/items`, `POST /shopping-items`, `PATCH /shopping-items/{id}`

**Layout desktop: grid de cards**

- Grid responsivo de cards de listas (2-3 colunas)
- Cada card mostra: titulo, contagem itens, barra de progresso (checked/total), cor
- **Click no card → expande inline** mostrando checklist de itens
- Cada item: checkbox + nome + botao deletar
- Checkbox chama `PATCH /shopping-items/{id}` com `{ checked: true/false }`
- Input inline no fim da lista para adicionar item rapidamente (`POST /shopping-items`)
- Botao "Nova Lista" abre dialog (titulo + cor via color picker)

---

### 8. Eventos/Atividades (`(app)/events/`)

Dados: `GET /events`, `GET /agenda`

**Layout desktop: 2 paineis**

**Topo**:
- **Calendar strip**: Scroll horizontal de datas, seletor de dia
- **Filtros de tipo**: Chip group (tarefas, lembretes, rotinas, eventos)

**Feed**:
- Lista vertical de cards color-coded por tipo
- Cada card: icone do tipo, titulo, horario, badge de status
- Swipe/botao para deletar eventos

**Botao "Novo Evento"**: Dialog com titulo, data/hora inicio-fim, flag

---

### 9. Configuracoes (`(app)/settings/`)

**Layout desktop: navegacao lateral + painel de conteudo**

**Hub** (`/settings`): Lista de opcoes (Conta, Notificacoes, Contextos)

**Conta** (`/settings/account`):
- Display name, email (readonly), timezone
- Botao logout

**Notificacoes** (`/settings/notifications`):
- Toggles por modulo (lembretes, eventos, tarefas, rotinas)
- Horario silencioso (inicio/fim)
- Resumo diario (toggle + horario)
- Dados de `GET /notification-preferences`

**Contextos/Flags** (`/settings/contexts`):
- Lista de flags com cor + nome
- Expandir flag mostra subflags
- CRUD completo: criar/editar/deletar flags e subflags
- Color picker na criacao/edicao

---

### 10. Historico de Notificacoes (`(app)/notifications/`)

Dados: `GET /notifications`

- Lista de cards de notificacao
- Read/unread visual (bold vs muted)
- Click marca como lida: `POST /notifications/{id}/read`
- Botao "Marcar todas como lidas": `POST /notifications/read-all`

---

## UX Desktop - Diferenciais

| Feature | Mobile | Web |
|---|---|---|
| Navegacao | Bottom nav 5 tabs | Sidebar lateral fixa com 6+ itens |
| Criacao de items | Bottom sheets | Dialogs modais centralizados |
| Layout dashboard | Cards empilhados | Bento grid 3 colunas |
| Rotinas | Lista unica | Split panel: lista + detalhe |
| Lembretes/Tasks | Lista unica | 2 colunas: tasks | reminders |
| Settings | Telas empilhadas | Nav lateral + conteudo |
| Atalhos teclado | N/A | Cmd+K (quick add), Cmd+N (criar), Cmd+1-6 (navegar) |
| Hover states | N/A | Preview em hover, botoes revealed on hover |
| Selecao multipla | N/A | Shift+click para bulk complete/delete |

---

## Fases de Implementacao

### Fase 1 - Fundacao (3 dias)
- [ ] Init Next.js em `/web` com TypeScript + Tailwind + App Router
- [ ] Configurar Tailwind com tokens de cor Organiq + Manrope
- [ ] Criar HTTP client (`client.ts`) + paths (`paths.ts`)
- [ ] Setup React Query provider + Zustand stores
- [ ] Fluxo de auth completo: Route Handlers, middleware, auth provider
- [ ] Paginas de login e signup
- [ ] Testar login funcional contra API real

### Fase 2 - Shell do App (2 dias)
- [ ] Primitivos UI: Button, Card, Input, Dialog, Toast, Skeleton, EmptyState, Badge, Toggle, Chip
- [ ] Componente Sidebar
- [ ] Componente TopBar
- [ ] AppShell (layout autenticado completo)
- [ ] Protecao de rotas funcionando

### Fase 3 - Home Dashboard (3 dias)
- [ ] Types TS para modelos do home (`HomeDashboardOutput`, etc.)
- [ ] Service + hook para `GET /home/dashboard`
- [ ] Dynamic header com gradientes por horario
- [ ] Progress ring SVG
- [ ] Bento grid com stat cards
- [ ] Week strip
- [ ] Timeline carousel
- [ ] Focus task list com toggle
- [ ] Quick add bar com processamento inline

### Fase 4 - Telas CRUD Core (5 dias)
- [ ] **Lembretes & Tarefas**: types, service, hooks, listas, dialogs criar/editar, toggles, paginacao cursor
- [ ] **Listas de Compras**: types, service, hooks, grid cards, checklist items, dialogs
- [ ] **Eventos**: types, service, hooks, calendar strip, filtros, feed cards, dialog criar
- [ ] **Cronograma/Rotinas**: types, service, hooks, day/week views, routine cards, detail panel, streak, dialog criar/editar

### Fase 5 - Features IA (3 dias)
- [ ] Inbox rapido: textarea multi-linha, processamento por linha, review cards, confirm/dismiss
- [ ] Chat IA: interface chat, suggestion blocks, accept flow
- [ ] Toggle entre modos
- [ ] Processing indicator com animacao

### Fase 6 - Settings e Notificacoes (2 dias)
- [ ] Hub de settings com sub-navegacao
- [ ] Pagina de conta
- [ ] Preferencias de notificacao
- [ ] Gerenciamento de contextos/flags (CRUD + color picker)
- [ ] Historico de notificacoes

### Fase 7 - Polish (2 dias)
- [ ] Skeleton loaders em todas as paginas
- [ ] Empty states em todas as listas
- [ ] Error boundaries e estados de erro
- [ ] Toasts para todas as mutations
- [ ] Atalhos de teclado
- [ ] Responsividade tablet
- [ ] Revisao de acessibilidade (ARIA, focus, screen reader)

---

## Verificacao / Como Testar

1. **Auth**: Fazer login com credenciais existentes do app mobile → deve redirecionar para home com dados do usuario
2. **Dashboard**: Verificar que bento grid, timeline e focus tasks carregam com dados reais da API
3. **CRUD completo**: Criar tarefa/lembrete/evento/lista no web → verificar que aparece no mobile (mesma API)
4. **Rotinas**: Marcar rotina como completa no web → verificar streak atualizado
5. **IA**: Enviar texto na pagina de criar → verificar que sugestoes aparecem → confirmar → verificar item criado
6. **Settings**: Alterar preferencias → verificar resposta da API
7. **Cross-device**: Acao feita no mobile deve refletir no web apos refresh (React Query refetch)

---

## Arquivos Criticos para Referencia

| Arquivo Flutter | Proposito |
|---|---|
| `app/lib/shared/services/http/app_path.dart` | Todos os endpoints da API |
| `app/lib/shared/theme/app_colors.dart` | Tokens de cor completos |
| `app/lib/shared/errors/api_error_mapper.dart` | Mapeamento de erros para PT-BR |
| `app/lib/modules/home/data/models/home_dashboard_output.dart` | Modelo mais complexo (dashboard) |
| `app/lib/modules/*/data/models/*.dart` | Todos os modelos de dados |
| `app/lib/presentation/screens/*/pages/*.dart` | Referencia visual de cada tela |
| `docs/api.md` | Documentacao da API |
