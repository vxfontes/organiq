CREATE TABLE IF NOT EXISTS organiq.suggestion_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES organiq.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organiq.suggestion_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES organiq.suggestion_conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    structured_blocks JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_suggestion_messages_role
        CHECK (role IN ('user', 'assistant'))
);

CREATE INDEX IF NOT EXISTS idx_suggestion_conversations_user_updated
    ON organiq.suggestion_conversations (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_suggestion_messages_conversation_created
    ON organiq.suggestion_messages (conversation_id, created_at ASC);

commit;
