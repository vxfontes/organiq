# Release v0.2.2 (fixes)

Hotfix do fluxo de Inbox/IA para múltiplos itens por texto, com resposta consistente entre backend e app.

## Fixes
- **Inbox/Reprocess:** resposta agora inclui `suggestions[]` (detecções) e `confirmed[]` (entidades criadas com IDs).
- **Create (itens por linha):** cada detecção vira um card separado (ex.: 2 cronogramas = 2 cards).
- **Resumo da Create:** contagem corrigida para múltiplos itens na mesma linha.
- **Lixeira restaurada:** cards auto-confirmados voltam a exibir excluir quando houver `entityType/entityId` vindos de `confirmed[]`.
