# OQ Components

## Base
- OQAppBar: App bar com gradiente, icone e titulo/subtitulo.
- OQLightAppBar: App bar clara com curvatura e sombra suave.
- OQBottomNav: Bottom bar flutuante com acao central.
- OQBottomSheet: Bottom sheet padronizado com suporte a titulo/subtitulo, conteudo, acoes primary/secondary, modo adaptativo e altura fixa.
- OQButton: Botao com variantes `primary`, `secondary` e `ghost`.
- OQCard: Container com padding e borda padrao.
- OQChip: Tag/label com cor configuravel.
- OQChipGroup<T>: Grupo de chips selecionaveis (single/multi) com estilos OQ.
- OQColorPicker: Seletor visual de cor com paleta e opcao "sem cor".
- OQDayProgressCard: Card de progresso diario com ring animado e mini-barras por categoria.
- OQDateField: Campo visual de data com acao principal e limpar.
- OQEmptyState: Estado vazio com icone e textos.
- OQFlagsField: Campo de selecao de flags (single select) com chips.
- OQLoader: Indicador de carregamento com label opcional.
- OQNextActionCard: Card compacto para timeline horizontal (hora, tipo, titulo e acao de concluir).
- OQScaffold: Scaffold base com padding e bottom bar.
- OQShoppingBanner: Banner de atalho para Compras com contadores de listas/itens.
- OQSnackBar: Helper para exibir feedbacks rápidos (erro/sucesso) de forma flutuante e não intrusiva.
- OQText: Helper de texto com variacoes (titulo, subtitulo, body, muted, caption, label).
- OQTextField: Input padronizado (suporta `minLines` e `maxLines`).
- OQTimeField: Campo visual de horário com seletor nativo estilizado (estilo OQDateField).
- OQToggle: Bloco com titulo/subtitulo e switch adaptativo, com estilo OQ.
- OQWeekStrip: Faixa semanal horizontal com selecao de dia e pontos de densidade.
- OQHugeIcon: Enum helper para icones do HugeIcons.
- OQIcon: Wrapper para icones do Material (padroniza tamanho/cor e opcionalmente fundo).
  - Variantes: use `OQIcon.<nome>` no lugar de `Icons.<nome>` (todos os icones usados no app estao mapeados aqui).

## Cards e listas (overview)
- OQMenuCard: Lista de itens em card com separadores e seta de navegacao.
- OQStatCard: Card compacto com valor/metricas e barra de acento.
- OQOverviewCard: Card de resumo com titulo, subtitulo e chips.
- OQInboxItemCard: Card de item do inbox com status e tags.
- OQItemCard: Card generico de item (lista de eventos/agenda/tarefas).
- OQTodoList: Lista de tarefas clicaveis com risco (usa OQTodoItemData).
- OQReminderRow: Linha simples para lembretes (titulo + horario).
- OQTagChip: Tag discreta para contexto/subflag.

## Estado e arquitetura
- OQController: Contrato base para controllers injetados com `Modular.get`, exigindo `dispose()`.
- OQState<T, C>: State base para telas stateful; resolve `controller` via modular no `initState` e chama `controller.dispose()` no `dispose`.
- OQUsecase: Helper base para encapsular regras de negocio/casos de uso.

## Tipos auxiliares
- OQTodoItemData: Modelo usado pelo `OQTodoList` para renderizar tarefa e status.
- OQMenuItem: Modelo de item usado pelo `OQMenuCard`.
- OQChipOption<T>: Modelo de opcao usado pelo `OQChipGroup`.
- OQFlagsFieldOption: Modelo de opcao usado pelo `OQFlagsField`.
- OQNextActionItem: Modelo usado pelo `OQNextActionCard`.
- OQNextActionType: Enum de tipo para `OQNextActionCard` (`event`, `reminder`, `routine`, `task`).

## Notas de uso
- OQTodoList e OQTodoItemData sao ideais para tarefas criticas no topo da Home.
- OQIcon pode ser usado sozinho ou com `backgroundColor` e `padding` para virar um “icone em bolha”.
- Para filtros e classificacao por contexto em formularios, prefira `OQFlagsField` em vez de montar chips locais na tela.
- Para selecao multipla ou unica em grupos pequenos de opcoes, prefira `OQChipGroup`.
- Para selecao de data em formularios, prefira `OQDateField` em vez de construir layouts locais repetidos.
- Para selecao de horario em formularios, prefira `OQTimeField`.
- Para selecao de cor (flags/subflags), prefira `OQColorPicker` em vez de inputs manuais de hex.
- Para feedbacks globais (erros de API, validacoes de negocio ou sucesso de acoes), prefira `OQSnackBar` em vez de textos inline que empurram o layout.
