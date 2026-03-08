-- Pre-migration for v0.0.1 (beta)
-- Creates extensions/schemas needed before tables.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE DATABASE inbota;

-- Base schema namespace (optional)
CREATE SCHEMA IF NOT EXISTS inbota;


-- Main tables, relations, and indexes.
CREATE TABLE IF NOT EXISTS inbota.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text,
  display_name text,
  password text,
  locale text,
  timezone text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  color text,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.subflags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  flag_id uuid NOT NULL REFERENCES inbota.flags(id) ON DELETE CASCADE,
  name text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.context_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  keyword text NOT NULL,
  flag_id uuid NOT NULL REFERENCES inbota.flags(id) ON DELETE CASCADE,
  subflag_id uuid REFERENCES inbota.subflags(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.inbox_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  source text NOT NULL,
  raw_text text NOT NULL,
  raw_media_url text,
  status text NOT NULL,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.ai_suggestions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  inbox_item_id uuid NOT NULL REFERENCES inbota.inbox_items(id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  confidence double precision,
  flag_id uuid REFERENCES inbota.flags(id) ON DELETE SET NULL,
  subflag_id uuid REFERENCES inbota.subflags(id) ON DELETE SET NULL,
  needs_review boolean NOT NULL DEFAULT false,
  payload_json jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'OPEN',
  due_at timestamptz,
  flag_id uuid REFERENCES inbota.flags(id) ON DELETE SET NULL,
  subflag_id uuid REFERENCES inbota.subflags(id) ON DELETE SET NULL,
  source_inbox_item_id uuid REFERENCES inbota.inbox_items(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  remind_at timestamptz,
  flag_id uuid REFERENCES inbota.flags(id) ON DELETE SET NULL,
  subflag_id uuid REFERENCES inbota.subflags(id) ON DELETE SET NULL,
  source_inbox_item_id uuid REFERENCES inbota.inbox_items(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  start_at timestamptz,
  end_at timestamptz,
  all_day boolean NOT NULL DEFAULT false,
  location text,
  flag_id uuid REFERENCES inbota.flags(id) ON DELETE SET NULL,
  subflag_id uuid REFERENCES inbota.subflags(id) ON DELETE SET NULL,
  source_inbox_item_id uuid REFERENCES inbota.inbox_items(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.shopping_lists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  source_inbox_item_id uuid REFERENCES inbota.inbox_items(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inbota.shopping_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES inbota.users(id) ON DELETE CASCADE,
  list_id uuid NOT NULL REFERENCES inbota.shopping_lists(id) ON DELETE CASCADE,
  title text NOT NULL,
  quantity text,
  checked boolean NOT NULL DEFAULT false,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_flags_user_order ON inbota.flags (user_id, sort_order);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON inbota.users (email);
CREATE INDEX IF NOT EXISTS idx_subflags_user_flag_order ON inbota.subflags (user_id, flag_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_context_rules_user_keyword ON inbota.context_rules (user_id, keyword);
CREATE INDEX IF NOT EXISTS idx_inbox_user_status_created ON inbota.inbox_items (user_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_inbox ON inbota.ai_suggestions (inbox_item_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_user_due ON inbota.tasks (user_id, status, due_at);
CREATE INDEX IF NOT EXISTS idx_reminders_user_remind ON inbota.reminders (user_id, status, remind_at);
CREATE INDEX IF NOT EXISTS idx_events_user_start ON inbota.events (user_id, start_at);
CREATE INDEX IF NOT EXISTS idx_lists_user_status ON inbota.shopping_lists (user_id, status);
CREATE INDEX IF NOT EXISTS idx_items_list_checked ON inbota.shopping_items (list_id, checked, sort_order);
commit;