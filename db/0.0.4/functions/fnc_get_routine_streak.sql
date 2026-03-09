CREATE OR REPLACE FUNCTION inbota.fnc_get_routine_streak(p_routine_id UUID)
RETURNS TABLE (current_streak INT, total_completions INT) AS $$
BEGIN
    RETURN QUERY
    WITH dates AS (
        SELECT completed_on
        FROM inbota.routine_completions
        WHERE routine_id = p_routine_id
        ORDER BY completed_on ASC
    ),
    streaks AS (
        SELECT completed_on,
               completed_on - (ROW_NUMBER() OVER (ORDER BY completed_on ASC) * INTERVAL '1 day') as grp
        FROM dates
    )
    SELECT
        (
            SELECT COUNT(*)::INT
            FROM streaks
            WHERE grp = (
                SELECT grp
                FROM streaks
                ORDER BY completed_on DESC
                LIMIT 1
            )
        ) as current_streak,
        (SELECT COUNT(*)::INT FROM dates) as total_completions;
END;
$$ LANGUAGE plpgsql;
