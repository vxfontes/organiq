-- Pre-migration for v0.0.3
-- Adds routines, routine_exceptions, and routine_completions tables.

-- recurrence_type values:
--   'weekly'       → every week on the same weekdays
--   'biweekly'     → every 2 weeks
--   'triweekly'    → every 3 weeks
--   'monthly_week' → e.g. "every first Monday of the month"

CREATE TABLE IF NOT EXISTS inbota.routines (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  title                text NOT NULL,
  description          text,
  recurrence_type      text NOT NULL DEFAULT 'weekly',
  weekdays             int[] NOT NULL,        -- 0=sun, 1=mon, ..., 6=sat
  start_time           time NOT NULL,
  end_time             time NOT NULL,
  week_of_month        int,                   -- only for recurrence_type = 'monthly_week' (1–5)
  starts_on            date NOT NULL DEFAULT CURRENT_DATE,
  ends_on              date,
  color                text,
  is_active            boolean NOT NULL DEFAULT true,
  flag_id              uuid REFERENCES inbota.flags(id) ON DELETE SET NULL,
  subflag_id           uuid REFERENCES inbota.subflags(id) ON DELETE SET NULL,
  source_inbox_item_id uuid REFERENCES inbota.inbox_items(id) ON DELETE SET NULL,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

-- Ensure time columns are stored as TIME (safety for older schemas)
ALTER TABLE inbota.routines
  ALTER COLUMN start_time TYPE time USING start_time::time;

ALTER TABLE inbota.routines
  ALTER COLUMN end_time TYPE time USING end_time::time;

-- action values: 'skip' | 'reschedule'
CREATE TABLE IF NOT EXISTS inbota.routine_exceptions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id     uuid NOT NULL REFERENCES inbota.routines(id) ON DELETE CASCADE,
  exception_date date NOT NULL,
  action         text NOT NULL DEFAULT 'skip',
  new_start_time time,
  new_end_time   time,
  reason         text,
  created_at     timestamptz NOT NULL DEFAULT now(),

  UNIQUE (routine_id, exception_date)
);

CREATE TABLE IF NOT EXISTS inbota.routine_completions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id   uuid NOT NULL REFERENCES inbota.routines(id) ON DELETE CASCADE,
  completed_on date NOT NULL,
  completed_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (routine_id, completed_on)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_routines_user_active      ON inbota.routines (user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_routines_weekdays         ON inbota.routines USING GIN (weekdays);
CREATE INDEX IF NOT EXISTS idx_routine_exceptions_lookup ON inbota.routine_exceptions (routine_id, exception_date);
CREATE INDEX IF NOT EXISTS idx_routine_completions_date  ON inbota.routine_completions (routine_id, completed_on DESC);
commit;
