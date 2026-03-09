CREATE OR REPLACE VIEW inbota.view_routine_daily_status AS
SELECT
    r.*,
    c.completed_at,
    (c.id IS NOT NULL) as is_completed,
    e.action as exception_action
FROM inbota.routines r
LEFT JOIN inbota.routine_completions c ON r.id = c.routine_id AND c.completed_on = CURRENT_DATE
LEFT JOIN inbota.routine_exceptions e ON r.id = e.routine_id AND e.exception_date = CURRENT_DATE
WHERE r.is_active = true;
