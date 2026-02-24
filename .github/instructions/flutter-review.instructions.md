---
applyTo: "app/lib/**/*.dart,app/test/**/*.dart"
excludeAgent: "coding-agent"
---

# Flutter/Dart Code Review Instructions

Review pull requests as a Flutter reviewer and prioritize correctness, UX regressions, and maintainability.

## Inbota-specific review checks

- Keep app architecture consistent with project convention:
  - Pages should stay declarative (`StatefulWidget` UI composition only).
  - Flow logic, timers, and orchestration should stay in controllers (`IBController` / `IBState` pattern).
  - Avoid moving business rules into widgets.
- Preserve core MVP navigation/flow:
  - Auth -> Inbox -> review (`reprocess`/`confirm`) -> final entities (`tasks`, `reminders`, `events`, `shopping`).
  - Prevent dead-ends in main tabs (Home/Inbox, Lembretes, Compras, Eventos, Config).
- Preserve API integration contract expected by app:
  - Send `Authorization: Bearer <token>` on protected routes.
  - Handle standard error payload `{"error":"code","requestId":"<id>"}`.
  - Respect cursor pagination (`limit`, `cursor`, `nextCursor`) in list screens.
  - Map expanded objects (`flag`, `subflag`, `sourceInboxItem`, `list`) and avoid regressions that assume ID-only responses.
- Preserve context UX rules:
  - Context remains two-level (`flag > subflag`).
  - Keep using `IBFlagsField` for context selection in forms.
  - Keep using `IBColorPicker` for flag color (avoid manual hex text input flows).
- Preserve current reminders/todos behavior:
  - Items marked `DONE` remain visible for about 2 seconds before leaving visible todo list.
  - This behavior belongs in controller/state logic, not directly in page widgets.
- For forms and shared UI, prefer existing shared components over one-off replacements:
  - `IBBottomSheet`, `IBDateField`, `IBFlagsField`, `IBCard`, `IBChip`, `IBEmptyState`, `IBLoader`, `IBTextField`.
- Preserve resilience to backend atomic operations:
  - If `reprocess`/`confirm` fails, do not leave optimistic UI in impossible partial states.

## General focus areas

- Validate widget state flows (no stale state, proper lifecycle handling, no setState-after-dispose issues).
- Check null-safety and runtime error risks (`!` misuse, unchecked casts, async error handling).
- Flag architecture regressions in state management, service boundaries, and dependency flow.
- Check performance hotspots (expensive rebuilds, missing const constructors where safe, unbounded list rendering).
- Verify navigation and form behavior (validation, loading/error states, back-stack correctness).
- Highlight accessibility and UI consistency regressions (semantics, tap targets, text scaling, overflow risks).
- Prefer actionable findings with concrete fix suggestions and avoid style-only noise.

## Testing expectations

- Request widget/unit tests for behavior changes in controllers, services, and critical UI flows.
- Ask for regression tests when fixing bugs in async state, parsing, or user input handling.
- Expect tests for:
  - controller-driven flow logic (especially timers and post-action UI state),
  - API mapper compatibility with expanded response objects,
  - pagination and error-state handling in list screens.
