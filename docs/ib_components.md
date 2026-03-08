# IB Components

## Base
- IBAppBar: App bar com gradiente, icone e titulo/subtitulo.
- IBLightAppBar: App bar clara com curvatura e sombra suave.
- IBBottomNav: Bottom bar flutuante com acao central.
- IBBottomSheet: Bottom sheet padronizado com suporte a titulo/subtitulo, conteudo, acoes primary/secondary, modo adaptativo e altura fixa.
- IBButton: Botao com variantes `primary`, `secondary` e `ghost`.
- IBCard: Container com padding e borda padrao.
- IBChip: Tag/label com cor configuravel.
- IBColorPicker: Seletor visual de cor com paleta e opcao "sem cor".
- IBDateField: Campo visual de data com acao principal e limpar.
- IBEmptyState: Estado vazio com icone e textos.
- IBFlagsField: Campo de selecao de flags (single select) com chips.
- IBLoader: Indicador de carregamento com label opcional.
- IBScaffold: Scaffold base com padding e bottom bar.
- IBSnackBar: Helper para exibir feedbacks rápidos (erro/sucesso) de forma flutuante e não intrusiva.
- IBText: Helper de texto com variacoes (titulo, subtitulo, body, muted, caption, label).
- IBTextField: Input padronizado (suporta `minLines` e `maxLines`).
- IBTimeField: Campo visual de horário com seletor nativo estilizado (estilo IBDateField).
- IBHugeIcon: Enum helper para icones do HugeIcons.
- IBIcon: Wrapper para icones do Material (padroniza tamanho/cor e opcionalmente fundo).
  - Variantes: use `IBIcon.<nome>` no lugar de `Icons.<nome>` (todos os icones usados no app estao mapeados aqui).

## Cards e listas (overview)
- IBMenuCard: Lista de itens em card com separadores e seta de navegacao.
- IBStatCard: Card compacto com valor/metricas e barra de acento.
- IBOverviewCard: Card de resumo com titulo, subtitulo e chips.
- IBInboxItemCard: Card de item do inbox com status e tags.
- IBItemCard: Card generico de item (lista de eventos/agenda/tarefas).
- IBTodoList: Lista de tarefas clicaveis com risco (usa IBTodoItemData).
- IBReminderRow: Linha simples para lembretes (titulo + horario).
- IBTagChip: Tag discreta para contexto/subflag.

## Estado e arquitetura
- IBController: Contrato base para controllers injetados com `Modular.get`, exigindo `dispose()`.
- IBState<T, C>: State base para telas stateful; resolve `controller` via modular no `initState` e chama `controller.dispose()` no `dispose`.
- IBUsecase: Helper base para encapsular regras de negocio/casos de uso.

## Tipos auxiliares
- IBTodoItemData: Modelo usado pelo `IBTodoList` para renderizar tarefa e status.
- IBMenuItem: Modelo de item usado pelo `IBMenuCard`.
- IBFlagsFieldOption: Modelo de opcao usado pelo `IBFlagsField`.

## Notas de uso
- IBTodoList e IBTodoItemData sao ideais para tarefas criticas no topo da Home.
- IBIcon pode ser usado sozinho ou com `backgroundColor` e `padding` para virar um “icone em bolha”.
- Para filtros e classificacao por contexto em formularios, prefira `IBFlagsField` em vez de montar chips locais na tela.
- Para selecao de data em formularios, prefira `IBDateField` em vez de construir layouts locais repetidos.
- Para selecao de horario em formularios, prefira `IBTimeField`.
- Para selecao de cor (flags/subflags), prefira `IBColorPicker` em vez de inputs manuais de hex.
- Para feedbacks globais (erros de API, validacoes de negocio ou sucesso de acoes), prefira `IBSnackBar` em vez de textos inline que empurram o layout.
