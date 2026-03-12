# Release v0.2.2

Hotfix/refactor no fluxo de confirmação do **Inbox/IA** para reduzir divergências de regra entre caminhos diferentes (Inbox vs endpoints diretos).

## Fixes
- **Inbox**: confirmação de sugestões agora delega criação para os *usecases* corretos:
  - Task → `TaskUsecase.Create`
  - Reminder → `ReminderUsecase.Create`
  - Event → `EventUsecase.Create`
  - Routine → `RoutineUsecase.Create`
- **Rotinas via Inbox/IA (StartsOn)**: regra de `startsOn` fica unificada no `RoutineUsecase` (timezone do usuário + próxima ocorrência do weekday), evitando casos onde a rotina começava em UTC/"dia seguinte" ou em weekday incorreto.
- **Inbox/IA — múltiplos itens**: a IA pode retornar um array de atividades; quando nenhum item precisa de review, o backend cria todos em uma transação e marca o inbox como confirmado.

## Notas
- Shopping permanece criando lista + itens direto via repositories dentro da transação.
