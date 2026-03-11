# Release v0.2.0

Data: 2026-03-11

## Visão Geral
A versão 0.2.0 traz um salto significativo na estética e na precisão temporal do Inbota. Introduzimos um cabeçalho dinâmico e imersivo para a Home, além de uma arquitetura robusta de fuso horário (Timezone) que resolve definitivamente inconsistências entre o dispositivo do usuário e o processamento da IA no backend.

## Features
- **Header Dinâmico e Imersivo:** Implementação de `CustomPainters` exclusivos para o cabeçalho da Home. O fundo agora é visualmente reativo, exibindo artes de céu personalizadas para Manhã, Tarde e Noite que se adaptam conforme o horário local do usuário.
- **Serviço Global de Timezone:** Nova arquitetura de detecção e sincronização automática de fuso horário (`user_timezone_service`). O app agora captura o timezone do dispositivo e o sincroniza com o backend durante o Login, Cadastro e inicialização (Splash).
- **Gestão Proativa de Horário Local:** Validação periódica do fuso horário em background. Se o usuário viajar ou mudar o horário do sistema, o Inbota detecta e ajusta o Command Center e as notificações em tempo real.
- **Visualização de Cronograma Refatorada:** Substituição da lista vertical de histórico por um **Activity Strip** horizontal compacto (últimos 7 dias). O modal de detalhes agora é mais visual, unificando Progresso e Streak em uma interface de alta densidade de informação.

## Fixes
- **Estabilização de Horários na Home:** Correção de inconsistências que forçavam horários em UTC na Timeline. Agora, há um fallback garantido para o fuso de Brasília (`America/Sao_Paulo`) quando as preferências do usuário não estão disponíveis.
- **Ajustes de Acentuação e String:** Refinamento no backend para garantir a integridade de caracteres especiais e acentuação em todas as comunicações e telas.
- **Navegação de Retorno (Pop):** Correção no `AppNavigation.pop` que impedia o retorno de dados em Bottom Sheets quando o `context` era fornecido. Isso corrigiu falhas na criação de Flags, Subflags e confirmações de exclusão no módulo de configurações.
- **Persistência de Subflags no Cronograma:** Correção de bug no backend onde as subflags não eram carregadas na listagem por dia da semana.
- **Inteligência de Streak:** Refatoração completa do cálculo de sequências (streaks). O sistema agora diferencia "dias consecutivos" de "semanas consecutivas" baseando-se na frequência da rotina (ex: rotinas diárias/frequentes mostram dias, rotinas semanais mostram semanas), além de considerar corretamente o cronograma específico de cada hábito.
