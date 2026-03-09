CREATE OR REPLACE FUNCTION inbota.fnc_check_routine_overlap(
    p_user_id UUID,
    p_weekdays INT[],
    p_start_time TIME,
    p_end_time TIME,
    p_exclude_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_overlap_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM inbota.routines
        WHERE user_id = p_user_id
          AND is_active = true
          AND (p_exclude_id IS NULL OR id <> p_exclude_id)
          AND weekdays && p_weekdays -- operador nativo de interseção de arrays
          AND (p_start_time < end_time AND start_time < p_end_time)
    ) INTO v_overlap_exists;

    RETURN v_overlap_exists;
END;
$$ LANGUAGE plpgsql;
