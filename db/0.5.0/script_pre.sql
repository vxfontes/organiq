ALTER TABLE organiq.routines
    ADD COLUMN IF NOT EXISTS day_of_month INT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_routines_day_of_month_range'
          AND connamespace = 'organiq'::regnamespace
    ) THEN
        ALTER TABLE organiq.routines
            ADD CONSTRAINT chk_routines_day_of_month_range
                CHECK (day_of_month IS NULL OR (day_of_month BETWEEN 1 AND 31));
    END IF;
END
$$;

DROP FUNCTION IF EXISTS organiq.fnc_routine_daily_status(uuid, int, date);

CREATE FUNCTION organiq.fnc_routine_daily_status(
    p_user_id uuid,
    p_weekday int,
    p_date date
)
    RETURNS TABLE (
                      id uuid,
                      user_id uuid,
                      title text,
                      description text,
                      recurrence_type text,
                      weekdays int[],
                      start_time text,
                      end_time text,
                      week_of_month int,
                      day_of_month int,
                      starts_on date,
                      ends_on date,
                      color text,
                      is_active boolean,
                      flag_id uuid,
                      subflag_id uuid,
                      source_inbox_item_id uuid,
                      created_at timestamptz,
                      updated_at timestamptz,
                      completed_at text,
                      is_completed boolean,
                      exception_action text
                  )
    LANGUAGE sql
    STABLE
AS $$
SELECT
    r.id,
    r.user_id,
    r.title,
    r.description,
    r.recurrence_type,
    r.weekdays,
    to_char(r.start_time, 'HH24:MI') as start_time,
    to_char(r.end_time, 'HH24:MI') as end_time,
    r.week_of_month,
    r.day_of_month,
    r.starts_on,
    r.ends_on,
    r.color,
    r.is_active,
    r.flag_id,
    r.subflag_id,
    r.source_inbox_item_id,
    r.created_at,
    r.updated_at,
    c.completed_at::text as completed_at,
    (c.id IS NOT NULL) as is_completed,
    e.action as exception_action
FROM organiq.routines r
         LEFT JOIN organiq.routine_completions c
                   ON r.id = c.routine_id
                       AND c.completed_on = p_date
         LEFT JOIN organiq.routine_exceptions e
                   ON r.id = e.routine_id
                       AND e.exception_date = p_date
WHERE r.user_id = p_user_id
  AND r.is_active = true
  AND (
    p_weekday = ANY(r.weekdays)
        OR (
        r.recurrence_type = 'monthly_day'
            AND r.day_of_month = EXTRACT(DAY FROM p_date)::int
        )
    )
ORDER BY r.start_time, r.created_at;
$$;

commit;


-- coluna nova existe?
select column_name
from information_schema.columns
where table_schema='organiq' and table_name='routines' and column_name='day_of_month';

-- função foi recriada com monthly_day?
select pg_get_functiondef('organiq.fnc_routine_daily_status(uuid,int,date)'::regprocedure);
