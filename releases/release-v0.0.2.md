# Release 0.0.2

Data: em andamento

## Features
- Entrada por voz no modulo `Criar`: agora e possivel gravar audio e transcrever para texto antes de enviar para a IA.
- Durante gravacao e transcricao, o campo fica bloqueado para digitacao.
- A digitacao volta apenas depois que a transcricao termina e o texto e preenchido.
- Interface de gravacao com feedback visual: timer e ondas reativas enquanto o microfone esta ativo.
- Indicador de `Transcrevendo audio...` entre o fim da gravacao e a liberacao do campo.
- Widget iOS de tarefas com lista de to-dos e acao para concluir item diretamente no widget (interativo no iOS 17+).
- Sincronizacao entre app e widget via `App Group`: o app publica tarefas abertas no widget.
- Conclusoes feitas no widget sao enfileiradas e aplicadas no backend quando o modulo de lembretes carrega.
- Visual do widget alinhado com a paleta oficial do produto, com tema claro e tokens de texto, borda, primario e sucesso.
- Adicionado fallback global de rota para evitar `RouteNotFoundException` em links inesperados disparados pelo sistema.

## Fixes
- Estabilizado fluxo de voz no iOS com serializacao de `start/stop/cancel` e pequeno tempo de acomodacao do engine para reduzir crash nativo `EXC_BAD_ACCESS` no `speech_to_text`.
