# Copilot Code Review Baseline

When performing pull request code reviews in this repository:

- Prioritize correctness, security, regressions, and missing tests over style-only feedback.
- Keep comments objective and actionable, with clear explanation of risk and a concrete fix path.
- Avoid low-signal comments and duplicate observations.
- Use the path-specific instructions in `.github/instructions` for Go and Flutter details.
- Treat project docs as review context, especially:
  - `docs/api.md`
  - `docs/app-estrutura.md`
  - `docs/backend-go-estrutura.md`
  - `docs/ib_components.md`
- Inbota domain baseline:
  - Product flow is `InboxItem -> AI suggestion -> review -> confirm -> final entity`.
  - Main final entities are `task`, `reminder`, `event`, and `shopping`.
  - Context model is two levels only (`flag > subflag`).
- When a change appears to conflict with documented contracts or flow, flag it explicitly as a potential contract drift and ask for coordinated update (backend + app + docs/tests).
