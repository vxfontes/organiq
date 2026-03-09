CREATE OR REPLACE VIEW inbota.view_inbox_with_latest_suggestion AS
WITH latest_suggestions AS (
    SELECT DISTINCT ON (inbox_item_id) *
    FROM inbota.ai_suggestions
    ORDER BY inbox_item_id, created_at DESC
)
SELECT
    i.*,
    s.id as suggestion_id,
    s.type as suggestion_type,
    s.title as suggestion_title,
    s.confidence as suggestion_confidence,
    s.payload_json,
    s.needs_review as suggestion_needs_review,
    s.created_at as suggestion_created_at,
    s.flag_id as suggestion_flag_id,
    s.subflag_id as suggestion_subflag_id
FROM inbota.inbox_items i
LEFT JOIN latest_suggestions s ON i.id = s.inbox_item_id;
