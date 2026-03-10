# Release v0.1.1

Hotfix focado em inconsistências de horário/ordenação que impactavam a Home, notificações e interpretações de datas pela IA.

## Fixes
- **TimeZone**: Corrige bug onde rotina com horário correto. Causa: fallback de timezone (UTC) quando `user.timezone` estava vazio/inválido.
- **Notificações**: Ordenação agora é por mais recentes primeiro.
- **Inbox**: Corrige interpretação de datas relativas por weekday.
