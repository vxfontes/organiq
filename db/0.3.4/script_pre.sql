-- Ajusta deduplicacao para permitir notificacoes recorrentes em datas diferentes.
-- Chave de unicidade: tipo + referencia + lead_mins + scheduled_for.

DROP INDEX IF EXISTS organiq.idx_notification_log_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_notification_log_unique
    ON organiq.notification_log(type, reference_id, COALESCE(lead_mins, -1), scheduled_for)
    WHERE status IN ('pending', 'sent', 'delivered');

commit;
