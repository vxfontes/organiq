CREATE TABLE IF NOT EXISTS organiq.app_screen_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES organiq.users(id) ON DELETE CASCADE,
    session_id TEXT,
    platform TEXT,
    app_version TEXT,
    screen_name TEXT NOT NULL,
    route_path TEXT NOT NULL,
    previous_route_path TEXT,
    event_name TEXT NOT NULL DEFAULT 'screen_view',
    metadata JSONB,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_screen_logs_user_session_occurred
    ON organiq.app_screen_logs (user_id, session_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_screen_logs_route_event_occurred
    ON organiq.app_screen_logs (route_path, event_name, occurred_at DESC);

CREATE TABLE IF NOT EXISTS organiq.app_error_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES organiq.users(id) ON DELETE CASCADE,
    session_id TEXT,
    screen_name TEXT,
    route_path TEXT,
    source TEXT NOT NULL,
    error_code TEXT,
    message TEXT NOT NULL,
    stack_trace TEXT,
    request_id TEXT,
    request_path TEXT,
    request_method TEXT,
    http_status INTEGER,
    metadata JSONB,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_app_error_logs_source
        CHECK (source IN ('flutter', 'dio', 'controller', 'api', 'bootstrap'))
);

CREATE INDEX IF NOT EXISTS idx_app_error_logs_user_occurred
    ON organiq.app_error_logs (user_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_error_logs_session_occurred
    ON organiq.app_error_logs (session_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_error_logs_route_source_occurred
    ON organiq.app_error_logs (route_path, source, occurred_at DESC);;


commit;
