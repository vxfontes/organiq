
ALTER TABLE organiq.tasks
    ADD COLUMN IF NOT EXISTS notification_title TEXT,
    ADD COLUMN IF NOT EXISTS notification_body TEXT;

ALTER TABLE organiq.reminders
    ADD COLUMN IF NOT EXISTS notification_title TEXT,
    ADD COLUMN IF NOT EXISTS notification_body TEXT;

ALTER TABLE organiq.events
    ADD COLUMN IF NOT EXISTS notification_title TEXT,
    ADD COLUMN IF NOT EXISTS notification_body TEXT;

ALTER TABLE organiq.routines
    ADD COLUMN IF NOT EXISTS notification_title TEXT,
    ADD COLUMN IF NOT EXISTS notification_body TEXT;

commit;
