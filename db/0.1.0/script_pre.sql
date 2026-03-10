ALTER DATABASE postgres SET TimeZone TO 'America/Sao_Paulo';

-- Home optimization objects (v0.1.0)

CREATE TABLE IF NOT EXISTS inbota.home_insight_templates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category text NOT NULL,
    title_template text NOT NULL,
    summary_template text NOT NULL,
    footer_template text NOT NULL,
    is_focus boolean NOT NULL DEFAULT false,
    min_gap_minutes int,
    priority int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_home_insight_templates_category_priority
    ON inbota.home_insight_templates (category, priority DESC);
