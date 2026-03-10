# Release 0.1.0

Data: 2026-03-10

## Visão Geral
Esta versão foca na consistência temporal e precisão dos dados, especialmente no que diz respeito ao cálculo de rotinas e status diários, além de entregar uma **refatoração total da tela inicial (Home)** para um Command Center contextual, tempo-consciente e orientado a ação.

## Features
### Refatoração Total da Home (Command Center)
- **Novo Layout Modular:** Implementação da estrutura baseada em zonas (Header Dinâmico, Week Strip, Timeline Horizontal, Bento Row e Foco).
- **Header Dinâmico:** Saudação temporal automática (Manhã, Tarde, Noite).
- **Quick Add Bar:** Atalho inteligente para criação rápida de itens processados pela IA.
- **Timeline Horizontal ("A Seguir"):** Carrossel unificado que mescla eventos, lembretes, rotinas e tarefas com horário marcado, priorizando o que vem a seguir.
- **Bento Row (Dashboard diário):** 
    - **Progress Card:** Ring visual de conclusão diária ("Fechar o anel") integrando rotinas e tarefas.
    - **Shopping Banner:** Atalho inteligente para acesso rápido às listas de compras ativas.
    - **Insights Inteligentes:** Card dinâmico com dicas e resumos sobre o planejamento do dia.
- **Lista de Foco e Prioridades:** Visualização vertical simplificada de tarefas críticas e atrasadas com checkbox inline.\

## Fixes
- **Forçamento de Timezone (America/Sao_Paulo):** Configuração global em nível de banco de dados para garantir que todas as sessões do PostgreSQL operem no fuso horário de Brasília.
- **Ajuste de Versão de Banco:** Migração da estrutura de banco para a versão `0.1.0`, consolidando os ajustes de esquema.
- **Centralização do Status Diário:** Refatoração da lógica de consulta de status de rotinas para a função SQL.
- **Ajustes de UI:** Refinamento no `expanded` das listas de to-do e ajustes finos nos componentes de lembretes.
- **Ajustes nas compras:** Troca do botão de concluir
- **Ajustes nas notificações:** Notificações filtradas para exibir apenas os itens relevantes para o dia atual e passadas.
