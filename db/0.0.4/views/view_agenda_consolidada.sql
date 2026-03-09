CREATE OR REPLACE VIEW inbota.view_agenda_consolidada AS
SELECT
    'task' as item_type,
    t.id,
    t.user_id,
    t.title,
    t.description,
    t.status,
    t.due_at as scheduled_at,
    t.due_at as due_at,
    NULL::TIMESTAMPTZ as remind_at,
    NULL::TIMESTAMPTZ as start_at,
    NULL::TIMESTAMPTZ as end_at,
    NULL::BOOLEAN as all_day,
    NULL::TEXT as location,
    t.flag_id,
    t.subflag_id,
    f.id as resolved_flag_id,
    f.name as flag_name,
    f.color as flag_color,
    sf.name as subflag_name,
    f.color as subflag_color,
    t.created_at,
    t.updated_at
FROM inbota.tasks t
LEFT JOIN inbota.subflags sf ON t.subflag_id = sf.id
LEFT JOIN inbota.flags f ON COALESCE(t.flag_id, sf.flag_id) = f.id
WHERE t.due_at IS NOT NULL
UNION ALL
SELECT
    'reminder' as item_type,
    r.id,
    r.user_id,
    r.title,
    NULL::TEXT as description,
    r.status,
    r.remind_at as scheduled_at,
    NULL::TIMESTAMPTZ as due_at,
    r.remind_at as remind_at,
    NULL::TIMESTAMPTZ as start_at,
    NULL::TIMESTAMPTZ as end_at,
    NULL::BOOLEAN as all_day,
    NULL::TEXT as location,
    r.flag_id,
    r.subflag_id,
    f.id as resolved_flag_id,
    f.name as flag_name,
    f.color as flag_color,
    sf.name as subflag_name,
    f.color as subflag_color,
    r.created_at,
    r.updated_at
FROM inbota.reminders r
LEFT JOIN inbota.subflags sf ON r.subflag_id = sf.id
LEFT JOIN inbota.flags f ON COALESCE(r.flag_id, sf.flag_id) = f.id
WHERE r.remind_at IS NOT NULL
UNION ALL
SELECT
    'event' as item_type,
    e.id,
    e.user_id,
    e.title,
    NULL::TEXT as description,
    'OPEN' as status,
    e.start_at as scheduled_at,
    NULL::TIMESTAMPTZ as due_at,
    NULL::TIMESTAMPTZ as remind_at,
    e.start_at as start_at,
    e.end_at as end_at,
    e.all_day as all_day,
    e.location as location,
    e.flag_id,
    e.subflag_id,
    f.id as resolved_flag_id,
    f.name as flag_name,
    f.color as flag_color,
    sf.name as subflag_name,
    f.color as subflag_color,
    e.created_at,
    e.updated_at
FROM inbota.events e
LEFT JOIN inbota.subflags sf ON e.subflag_id = sf.id
LEFT JOIN inbota.flags f ON COALESCE(e.flag_id, sf.flag_id) = f.id
WHERE e.start_at IS NOT NULL;
