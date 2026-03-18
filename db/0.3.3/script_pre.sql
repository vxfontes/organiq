CREATE TABLE IF NOT EXISTS organiq.notification_delivery_attempts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_log_id UUID REFERENCES organiq.notification_log(id) ON DELETE SET NULL,
    user_id             UUID NOT NULL REFERENCES organiq.users(id) ON DELETE CASCADE,
    device_id           TEXT NOT NULL,
    provider            TEXT NOT NULL,
    attempt_no          INT NOT NULL DEFAULT 1,
    status              TEXT NOT NULL CHECK (status IN ('success', 'failed')),
    error_code          TEXT,
    error_message       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_attempts_user_created
    ON organiq.notification_delivery_attempts(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_attempts_log_created
    ON organiq.notification_delivery_attempts(notification_log_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_attempts_status_created
    ON organiq.notification_delivery_attempts(status, created_at DESC);

commit;