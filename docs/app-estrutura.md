# Estrutura do App (Flutter)

Este documento descreve a estrutura do app baseada em Clean Architecture, adaptada para as pastas `lib/presentation`, `lib/shared` e `lib/modules`.

## Objetivo
Separar UI, regras de negocio e acesso a dados para escalar o app sem virar um monolito dificil de manter.

## Visao geral
Estrutura proposta (resumida):
- `lib/presentation`: tudo que aparece em tela e controle de estado de UI.
- `lib/modules`: dominio + dados (usecases, repositories, models, datasources, API).
- `lib/shared`: itens compartilhados (tema, components base, utilitarios, config).

## Camadas (Clean Architecture)
- Presentation Layer: UI + State Management (OQState/Controllers).
- Domain Layer: regras de negocio puras e usecases.
- Data Layer: acesso a API/DB, mappers e repositorios concretos.

## Convencao atual do projeto (OQState + Controller)
- Pages (`StatefulWidget` em `presentation/screens/.../pages`) devem ficar declarativas:
  - montar UI
  - delegar acao para o controller
  - evitar regra de negocio na page
- Controllers (classes que implementam `OQController`) concentram:
  - regras de fluxo
  - transformacao de estado para a UI
  - timers/efeitos de exibicao (quando houver)
- Exemplo atual: no modulo de lembretes, o controller decide quando itens `DONE` aparecem/somem na lista visivel de To-dos.

## Mapeamento para as pastas do projeto

### `lib/presentation/`
Finalidade: telas, componentes de UI e gerenciamento de estado da interface.

Sugestao de subpastas:
- `screens/`: paginas e fluxos (ex.: `login_screen.dart`).
- `state/`: cubits/blocs e seus states/events.
- `routes/`: definicoes de rotas e navegacao.

### `lib/modules/`
Finalidade: codigo de negocio e integracoes, separado por feature.

Sugestao de organizacao por feature:
- `modules/<feature>/domain/`:
  - `usecases/`: casos de uso.
  - `repositories/`: contratos (interfaces).
- `modules/<feature>/data/`:
  - `models/`: DTOs e mapeamento.
  - `repositories/`: implementacoes concretas.

Convencao de models:
- Conversoes de payload (`fromJson`, `fromDynamic`, `toJson`) ficam no model.
- Repositories apenas chamam os models e tratam status/erros HTTP.
 - Todos os models devem ser `json_serializable`.

Isso ajuda a manter `domain`, `data` e `presentation` isolados por feature.

### `lib/shared/`
Finalidade: itens comuns a todo o app (nao dependem de uma feature).

Sugestao de subpastas:
- `theme/`: cores, tipografia, ThemeData.
- `components/`: componentes globais (botao, chip, card base).
- `utils/`: helpers gerais.
- `config/`: constantes, env, urls base.
- `errors/`: erros comuns e mapeamentos.

## Exemplo de estrutura (adaptada)
```
lib/
  main.dart
  presentation/
    screens/
      login_module/
      x_module/
      ...
    routes/
  modules/
    auth/
      domain/
        usecases/
        repositories/
      data/
        models/
        repositories/
    flags/
      domain/
      data/
    inbox/
      domain/
      data/
  shared/
    theme/
    state/
    components/
    utils/
    config/
    errors/
```
