CREATE OR REPLACE VIEW inbota.view_agenda_consolidada AS
SELECT
    'task' as item_type,
    t.id, t.user_id, t.title, t.status, t.due_at as scheduled_at,
    f.name as flag_name, f.color as flag_color,
    sf.name as subflag_name, f.color as subflag_color
FROM inbota.tasks t
LEFT JOIN inbota.flags f ON t.flag_id = f.id
LEFT JOIN inbota.subflags sf ON t.subflag_id = sf.id
WHERE t.due_at IS NOT NULL
UNION ALL
SELECT
    'reminder' as item_type,
    r.id, r.user_id, r.title, r.status, r.remind_at as scheduled_at,
    f.name as flag_name, f.color as flag_color,
    sf.name as subflag_name, f.color as subflag_color
FROM inbota.reminders r
LEFT JOIN inbota.flags f ON r.flag_id = f.id
LEFT JOIN inbota.subflags sf ON r.subflag_id = sf.id
WHERE r.remind_at IS NOT NULL
UNION ALL
SELECT
    'event' as item_type,
    e.id, e.user_id, e.title, 'OPEN' as status, e.start_at as scheduled_at,
    f.name as flag_name, f.color as flag_color,
    sf.name as subflag_name, f.color as subflag_color
FROM inbota.events e
LEFT JOIN inbota.flags f ON e.flag_id = f.id
LEFT JOIN inbota.subflags sf ON e.subflag_id = sf.id
WHERE e.start_at IS NOT NULL;
