# Release v0.3.5 (hotfix)

Hotfix: cancelamento automático de notificações ao deletar entidades.

## Fixes
- **Notificações:** ao deletar evento, lembrete, tarefa ou rotina, todas as notificações pendentes são canceladas automaticamente (status='cancelled'), evitando que o usuário receba notificações de itens deletados.
