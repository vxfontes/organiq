# Organiq MCP Server

MCP server that exposes the [Organiq](../README.md) API as tools for Claude Code and other MCP-compatible clients.

Runs locally via stdio — no hosting required.

## Prerequisites

- Node.js 18+
- A running Organiq API (local or production on Render)
- A valid JWT token **or** account credentials

## Setup

### 1. Install dependencies and build

```bash
cd mcp
npm install
npm run build
```

### 2. Configure Claude Code

Add the following to your Claude Code MCP settings.

**Option A — fixed JWT** (`~/.claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "organiq": {
      "command": "node",
      "args": ["/absolute/path/to/organiq/mcp/dist/index.js"],
      "env": {
        "ORGANIQ_BASE_URL": "https://your-api.onrender.com",
        "ORGANIQ_TOKEN": "your-jwt-here"
      }
    }
  }
}
```

**Option B — login with credentials** (auto-login on startup):

```json
{
  "mcpServers": {
    "organiq": {
      "command": "node",
      "args": ["/absolute/path/to/organiq/mcp/dist/index.js"],
      "env": {
        "ORGANIQ_BASE_URL": "https://your-api.onrender.com",
        "ORGANIQ_EMAIL": "you@example.com",
        "ORGANIQ_PASSWORD": "yourpassword"
      }
    }
  }
}
```

### 3. Restart Claude Code

The `organiq` tools will appear in Claude Code's tool list.

## Available Tools (27)

| Group | Tools |
|-------|-------|
| Auth | `auth_me`, `auth_login` |
| Inbox | `inbox_list`, `inbox_get`, `inbox_create`, `inbox_reprocess`, `inbox_confirm`, `inbox_dismiss` |
| Tasks | `tasks_list`, `tasks_create`, `tasks_update`, `tasks_delete` |
| Reminders | `reminders_list`, `reminders_create`, `reminders_update`, `reminders_delete` |
| Events | `events_list`, `events_create`, `events_update`, `events_delete` |
| Shopping | `shopping_lists_list`, `shopping_lists_create`, `shopping_lists_update`, `shopping_lists_delete`, `shopping_items_list`, `shopping_items_create`, `shopping_items_update`, `shopping_items_delete` |
| Agenda | `agenda_get` |

## Development

```bash
cd mcp
npm run dev   # run without building (uses tsx)
npm run build # compile to dist/
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ORGANIQ_BASE_URL` | Yes | API base URL (e.g. `http://localhost:8080`) |
| `ORGANIQ_TOKEN` | One of these two | Fixed JWT token (takes precedence) |
| `ORGANIQ_EMAIL` + `ORGANIQ_PASSWORD` | One of these two | Credentials for auto-login on startup |
