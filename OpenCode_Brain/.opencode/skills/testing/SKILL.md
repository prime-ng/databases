---
name: Testing Rules
description: Testing rules — Pest 4.x, the 3 test types (Unit, Central Feature, Tenant Feature), and run commands.
---

# Testing Rules

Use when writing or running tests (`tests/**`, `Modules/*/tests/**`).

## Workflow

1. Read `instructions/testing.md` — the full rule set for this module — and follow it.
2. Resolve every `{VARIABLE}` via `config/paths.md`.
3. If a `module-knowledge/<CODE>_<Name>.md` file exists for this module, read it before making
   any claim about counts, completion, or gaps (seeded snapshots can be stale — verify against
   the live tree).
