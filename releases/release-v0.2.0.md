# Release v0.2.0

Data: 2026-03-11

## Visão Geral
A versão 0.2.0 traz um salto significativo na estética e na precisão temporal do Inbota. Introduzimos um cabeçalho dinâmico e imersivo para a Home, além de uma arquitetura robusta de fuso horário (Timezone) que resolve definitivamente inconsistências entre o dispositivo do usuário e o processamento da IA no backend.

## Features
- **Header Dinâmico e Imersivo:** Implementação de `CustomPainters` exclusivos para o cabeçalho da Home. O fundo agora é visualmente reativo, exibindo artes de céu personalizadas para Manhã, Tarde e Noite que se adaptam conforme o horário local do usuário.
- **Serviço Global de Timezone:** Nova arquitetura de detecção e sincronização automática de fuso horário (`user_timezone_service`). O app agora captura o timezone do dispositivo e o sincroniza com o backend durante o Login, Cadastro e inicialização (Splash).
- **Gestão Proativa de Horário Local:** Validação periódica do fuso horário em background. Se o usuário viajar ou mudar o horário do sistema, o Inbota detecta e ajusta o Command Center e as notificações em tempo real.

## Fixes
- **Estabilização de Horários na Home:** Correção de inconsistências que forçavam horários em UTC na Timeline. Agora, há um fallback garantido para o fuso de Brasília (`America/Sao_Paulo`) quando as preferências do usuário não estão disponíveis.
- **Ajustes de Acentuação e String:** Refinamento no backend para garantir a integridade de caracteres especiais e acentuação em todas as comunicações e telas.
