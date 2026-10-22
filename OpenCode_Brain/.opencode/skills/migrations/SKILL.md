---
name: Migration Rules
description: Database migration rules — central vs tenant paths, required columns, additive-only changes, and table prefixes.
---

# Migration Rules

Use when creating or reviewing database migrations (`database/migrations/**`).

## Workflow

1. Read `instructions/migrations.md` — the full rule set for this module — and follow it.
2. Resolve every `{VARIABLE}` via `config/paths.md`.
3. If a `module-knowledge/<CODE>_<Name>.md` file exists for this module, read it before making
   any claim about counts, completion, or gaps (seeded snapshots can be stale — verify against
   the live tree).
