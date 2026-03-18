# Organiq Web (Next.js)

Frontend web do Organiq com App Router, TypeScript e tokens visuais alinhados ao app Flutter.

## Requisitos
- Node.js 20+

## Ambiente
Crie `web/.env.local` (ou use `.env.example`):

```bash
NEXT_PUBLIC_API_HOST=http://localhost:8080
```

Se não informar, o frontend usa fallback para `https://inbota-api.onrender.com`.

## Rodar local
```bash
cd web
npm run dev
```

Aplicação: [http://localhost:3000](http://localhost:3000)

## O que já está implementado
- Base de tokens OQ (paleta clara + tipografia Manrope)
- Bootstrap de sessão (`/v1/healthz` + `/v1/me`)
- Fluxo de autenticação:
  - `/auth`
  - `/auth/login`
  - `/auth/signup`
- Shell autenticado responsivo com navegação principal
- Home funcional (`/app/home`) com:
  - `GET /v1/home/dashboard`
  - Quick Add atômico (`create -> reprocess -> confirm`)
  - Toggle de tarefas foco (`PATCH /v1/tasks/:id`)
- Páginas base para os demais módulos (`schedule`, `reminders`, `create`, `shopping`, `events`, `settings/*`, `notification-history`)

## Scripts
```bash
npm run dev
npm run lint
npm run build
npm run start
```
