-- Returns routine daily status (completion + exception) for a given user/week day/date.
-- This is a "parameterized view" replacement for view_routine_daily_status, avoiding CURRENT_DATE.

CREATE OR REPLACE FUNCTION inbota.fnc_routine_daily_status(
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
  FROM inbota.routines r
  LEFT JOIN inbota.routine_completions c
    ON r.id = c.routine_id
    AND c.completed_on = p_date
  LEFT JOIN inbota.routine_exceptions e
    ON r.id = e.routine_id
    AND e.exception_date = p_date
  WHERE r.user_id = p_user_id
    AND r.is_active = true
    AND p_weekday = ANY(r.weekdays)
  ORDER BY r.start_time, r.created_at;
$$;
