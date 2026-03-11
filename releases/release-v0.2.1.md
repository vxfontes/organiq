# Release v0.2.1

Hotfix de rotinas recorrentes (quinzenal / a cada 3 semanas): a rotina agora sempre começa na **próxima ocorrência futura** do weekday selecionado, em vez de ancorar na semana atual e cair no passado.

## Fixes
- **Rotinas (StartsOn)**: Ao criar rotina sem `startsOn` explícito, o backend calcula o `startsOn` como a próxima ocorrência de um dos `weekdays` (no timezone do usuário).
- **Listagem/Scheduler**: Rotinas não são exibidas/notificadas em datas anteriores ao `startsOn`.
