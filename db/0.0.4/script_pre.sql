-- Enum para plataforma do dispositivo
CREATE TYPE inbota.device_platform AS ENUM ('ios', 'android');

-- Enum para status da notificação
CREATE TYPE inbota.notification_status AS ENUM ('pending', 'sent', 'failed', 'delivered', 'read');

-- Enum para tipo de notificação
CREATE TYPE inbota.notification_type AS ENUM ('reminder', 'event', 'task', 'routine');

-- -----------------------------------------------------------------------------
-- device_tokens: tokens FCM por dispositivo/usuário
-- -----------------------------------------------------------------------------
CREATE TABLE inbota.device_tokens (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
    token         TEXT NOT NULL,
    platform      inbota.device_platform NOT NULL,
    device_name   TEXT,                          -- "iPhone de Vanessa", "Pixel 8"
    app_version   TEXT,                          -- "0.0.4"
    is_active     BOOLEAN NOT NULL DEFAULT true,
    last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Um token só pode ter um dono; evita duplicatas entre devices
CREATE UNIQUE INDEX idx_device_tokens_token ON inbota.device_tokens(token);
-- Busca rápida por usuário ativo
CREATE INDEX idx_device_tokens_user ON inbota.device_tokens(user_id, is_active);

-- -----------------------------------------------------------------------------
-- notification_preferences: configurações pessoais de push por usuário
-- -----------------------------------------------------------------------------
CREATE TABLE inbota.notification_preferences (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL UNIQUE REFERENCES inbota.users(id) ON DELETE CASCADE,

    -- Reminders
    reminders_enabled    BOOLEAN NOT NULL DEFAULT true,
    reminder_at_time     BOOLEAN NOT NULL DEFAULT true,   -- alerta na hora exata
    reminder_lead_mins   INT[] NOT NULL DEFAULT '{5,15}', -- minutos antes (ex: 5, 15, 30, 60)

    -- Events
    events_enabled       BOOLEAN NOT NULL DEFAULT true,
    event_at_time        BOOLEAN NOT NULL DEFAULT true,
    event_lead_mins      INT[] NOT NULL DEFAULT '{15,60,1440}', -- 15min, 1h, 1 dia

    -- Tasks (alerta quando o due_at chegar)
    tasks_enabled        BOOLEAN NOT NULL DEFAULT true,
    task_at_time         BOOLEAN NOT NULL DEFAULT true,
    task_lead_mins       INT[] NOT NULL DEFAULT '{60,1440}', -- 1h, 1 dia antes

    -- Routines (alerta no start_time da rotina)
    routines_enabled     BOOLEAN NOT NULL DEFAULT true,
    routine_at_time      BOOLEAN NOT NULL DEFAULT true,
    routine_lead_mins    INT[] NOT NULL DEFAULT '{15}',

    -- Horário de silêncio (quiet hours) — formato HH:MM em UTC, aplicado com timezone do usuário
    quiet_hours_enabled  BOOLEAN NOT NULL DEFAULT false,
    quiet_start          TIME,                             -- ex: '22:00'
    quiet_end            TIME,                             -- ex: '08:00'

    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- notification_log: histórico de notificações enviadas
-- -----------------------------------------------------------------------------
CREATE TABLE inbota.notification_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
    type            inbota.notification_type NOT NULL,
    reference_id    UUID NOT NULL,    -- id do reminder, event, task ou routine
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    lead_mins       INT,              -- NULL = na hora exata; N = N minutos antes
    status          inbota.notification_status NOT NULL DEFAULT 'pending',
    scheduled_for   TIMESTAMPTZ NOT NULL,  -- quando deveria ser enviado
    sent_at         TIMESTAMPTZ,
    read_at         TIMESTAMPTZ,
    error_msg       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Evita enviar a mesma notificação duplicada
CREATE UNIQUE INDEX idx_notification_log_unique
    ON inbota.notification_log(reference_id, lead_mins)
    WHERE status IN ('pending', 'sent', 'delivered');

-- Busca de pendentes pelo scheduler
CREATE INDEX idx_notification_log_pending
    ON inbota.notification_log(scheduled_for, status)
    WHERE status = 'pending';

-- Histórico por usuário
CREATE INDEX idx_notification_log_user
    ON inbota.notification_log(user_id, created_at DESC);