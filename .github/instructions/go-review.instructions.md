---
applyTo: "backend/**/*.go"
excludeAgent: "coding-agent"
---

# Go Code Review Instructions

Review pull requests as a Go backend reviewer and prioritize issues that can break behavior, security, or reliability.

## Inbota-specific review checks

- Keep architecture boundaries clear: `handler -> usecase -> repository/service -> infra`.
- Keep protected routes under JWT auth and preserve open health endpoints (`/healthz`, `/readyz`) and auth endpoints.
- Enforce multi-tenant safety: repository operations must always scope by `user_id` and avoid cross-user data leaks.
- Preserve request tracing and error shape consistency:
  - `X-Request-Id` in responses.
  - Error payload format `{"error":"code","requestId":"<id>"}`.
- Preserve API contract behavior used by the Flutter app:
  - Responses should return expanded objects where expected (`flag`, `subflag`, `sourceInboxItem`, `list`) instead of only IDs.
  - `tasks` create/update requests may accept `flagId`/`subflagId`, while responses should include expanded context objects.
  - `subflag.color` should follow parent flag color behavior.
- Preserve Inbox transactional semantics:
  - `reprocess`: suggestion creation and inbox status update must succeed/fail together.
  - `confirm`: final entity creation and inbox `CONFIRMED` update must succeed/fail together.
  - Prefer `TxRunner.WithTx(...)` and reject partial-write regressions.
- Guard core flow and statuses:
  - Inbox: `NEW|PROCESSING|SUGGESTED|NEEDS_REVIEW|CONFIRMED|DISMISSED`.
  - Task/Reminder: `OPEN|DONE`.
  - Shopping list: `OPEN|DONE|ARCHIVED`.
- Watch performance regressions in list endpoints (`inbox`, `tasks`, `reminders`, `events`, `shopping`) and flag N+1 query patterns; prefer batch-fetch patterns (`GetByIDs`-style).
- Preserve endpoint behavior around AI dependency: if AI client is not configured, `reprocess` should return `dependency_missing`.
- Keep `GET /v1/agenda` semantics coherent (`events + tasks + reminders`) when touching aggregation code.
- There is ongoing evolution around shopping item quantity in docs/contracts; flag additions/removals that change public API without synchronized backend/app/docs/test updates.

## General focus areas

- Validate HTTP handlers for correct status codes, request validation, and response consistency.
- Check error handling paths: no swallowed errors, no panic-prone code, and clear error propagation.
- Flag context misuse (missing `context.Context` propagation, blocking calls without timeouts, goroutine leaks).
- Flag SQL/data access risks (injection, unsafe dynamic queries, unbounded result sets, missing transactions when needed).
- Highlight auth and security regressions (JWT validation, authorization checks, sensitive data leakage in logs).
- Check concurrency safety (shared mutable state, races, non-thread-safe caches/maps).
- Prefer actionable findings with concrete fix suggestions and minimal noise.

## Testing expectations

- Request tests for behavior changes in handlers, services, repositories, or auth flows.
- For bug-prone logic, suggest table-driven tests and edge-case coverage.
- Expect regression tests for:
  - transactional rollback behavior in `confirm` and `reprocess`,
  - auth and user isolation (`user_id` scoping),
  - API response shapes consumed by app mappers.
