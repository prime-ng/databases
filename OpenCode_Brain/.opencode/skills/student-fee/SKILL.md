---
name: StudentFee Rules
description: StudentFee module rules — fee tables, business rules, missing features, and known bugs.
---

# StudentFee Rules

Use when working on the StudentFee module (`Modules/StudentFee/**`) or fee/fin migrations.

## Workflow

1. Read `instructions/student-fee.md` — the full rule set for this module — and follow it.
2. Resolve every `{VARIABLE}` via `config/paths.md`.
3. If a `module-knowledge/<CODE>_<Name>.md` file exists for this module, read it before making
   any claim about counts, completion, or gaps (seeded snapshots can be stale — verify against
   the live tree).
