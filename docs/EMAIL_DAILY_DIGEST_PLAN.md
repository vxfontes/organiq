# Inbota — Daily Digest por e-mail (planejamento)

Objetivo: enviar um e-mail diário (ex.: **04:00 BRT**) com um resumo do dia do usuário: **Agenda**, **Reminders**, **Tasks** e **Listas de compra**.

Este documento descreve: provedor de e-mail recomendado, modelo de dados, regras de seleção de itens, job/agendamento, e rollout.

---

## 1) Envio de e-mail é “de graça”?

**Quase nunca é 100% grátis**. O que existe é **free tier** (cotas) ou custos muito baixos.

O custo depende principalmente de:
- volume de envios (usuários × 1 e-mail/dia)
- reputação/aquecimento de domínio
- validação de domínio (SPF/DKIM/DMARC)

### Estimativa rápida
Se você tiver **1.000 usuários** ativos com digest habilitado:
- 1.000 e-mails/dia ≈ 30.000 e-mails/mês

Isso pode entrar em free tiers (dependendo do provedor) ou custar pouco, mas **não dá pra contar como “sempre grátis”**.

---

## 2) Provedores recomendados (ordem prática)

### Opção A (recomendada): **Resend** (API simples)
- Prós: API muito simples, ótima DX, entrega boa, templates fáceis.
- Contras: free tier limitado; depois paga por volume.
- Bom para: MVP e iteração rápida.

### Opção B: **Amazon SES** (mais barato em escala)
- Prós: custo baixo/estável; bom para volume.
- Contras: configuração mais chata (AWS + reputação + warmup); DX pior.
- Bom para: quando crescer e quiser custo mínimo.

### Opção C: **Mailgun / SendGrid**
- Prós: bem conhecidos, ferramentas maduras.
- Contras: painel/config às vezes mais “pesado”; planos mudam.

### Critério de escolha
Para o Inbota agora: **Resend** primeiro (mais rápido), e deixar SES como caminho de migração quando escalar.

---

## 3) Regras do Daily Digest (conteúdo)

### 3.1 Agenda (cronograma do dia)
**Fonte**: endpoint/uso-caso existente de agenda consolidada (ou query direta por tipos).

**Ordenação**: horário ascendente.

**Campos**:
- horário
- título
- tipo (task/reminder/event)
- status
- flag/subflag (nome/cor)

### 3.2 Reminders
- Incluir reminders **com RemindAt no dia**.
- Separar por: manhã / tarde / noite (opcional).

### 3.3 Tasks
- Incluir tasks com `due_at` no dia.
- Incluir tasks **abertas sem data** (em seção separada, como você pediu).

### 3.4 Listas de compra
- Incluir listas abertas (status OPEN) e/ou itens não marcados.
- Ex.: “Lista X: 5 itens pendentes”.

### 3.5 Timezone
Como o produto é focado no Brasil, o **default** pode ser `America/Sao_Paulo`.
Mesmo assim:
- se o usuário tiver timezone diferente, o digest deve usar o timezone do usuário.

---

## 4) Preferências do usuário (opt-in)

Criar/usar uma configuração de notificações com pelo menos:
- `dailyDigestEnabled: bool`
- `dailyDigestHour: int` (default 4)
- `dailyDigestTimezone: string` (default `America/Sao_Paulo`, ou usar `User.Timezone`)

Recomendação: **usar `User.Timezone`** como fonte de verdade e guardar só `dailyDigestHour`.

---

## 5) Job no backend (agendamento)

### Opção recomendada: job recorrente + janela de envio
Rodar um job a cada 5 minutos (ou 10 min) e enviar para quem estiver na janela.

Exemplo:
- Job roda 04:00, 04:05, 04:10...
- Para cada usuário com digest ativo:
  - calcular o horário local (`now` no timezone)
  - se estiver dentro da janela do envio e ainda não enviado para a data local → envia.

Isso evita “um cron por timezone”.

### Idempotência (evitar duplicado)
Criar tabela `email_digests`:
- `id uuid`
- `user_id uuid`
- `digest_date date` (data local do usuário)
- `type text` (ex: `daily_digest`)
- `sent_at timestamptz`
- `provider_message_id text` (opcional)
- unique (`user_id`, `digest_date`, `type`)

Fluxo:
1) antes de enviar: tentar inserir o registro
2) se conflito (já existe): não enviar
3) se envio falhar: atualizar erro e permitir retry (opcional)

---

## 6) Template do e-mail

### Assunto (exemplos)
- `Seu dia no Inbota — 09/03 (Segunda)`

### Corpo (HTML)
- header curto
- seção “Agenda de hoje” (tabela)
- seção “Reminders”
- seção “Tasks (com data)”
- seção “Tasks abertas (sem data)”
- seção “Listas de compra”

### Texto puro
Gerar versão text/plain para clientes simples.

---

## 7) Implementação (passos sugeridos / PRs)

1) **DB**: tabela `email_digests` (+ migração)
2) **Config**: endpoint e persistência de preferências do usuário
3) **Query**: função `BuildDailyDigest(userID, date, tz)`
4) **Mailer**: client do provedor (Resend primeiro)
5) **Job**: scheduler (cron interno / worker)
6) **Observabilidade**:
   - logs por usuário
   - métrica: enviados/erro por execução

---

## 8) Rollout e segurança
- Começar com opt-in (como você quer)
- Rate limit por execução (evitar ban do provedor)
- Guardar segredos (API key) só em env/secret manager

---

## 9) Perguntas em aberto (para decidir antes de codar)
- Horário default: 04:00 BRT ok?
- Digest inclui itens “passados” do mesmo dia (ex: reminder 08:00, mas job roda 10:00)?
- Quando não existir nada no dia, manda e-mail mesmo assim?
- Idiomas: pt-BR apenas?
