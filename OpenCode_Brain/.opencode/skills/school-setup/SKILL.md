---
name: SchoolSetup Rules
description: SchoolSetup module rules — core entities, cross-module dependencies, known issues, and academic-session resolution.
---

# SchoolSetup Rules

Use when working on the SchoolSetup module (`Modules/SchoolSetup/**`) or school/class/section/subject/teacher/room migrations.

## Workflow

1. Read `instructions/school-setup.md` — the full rule set for this module — and follow it.
2. Resolve every `{VARIABLE}` via `config/paths.md`.
3. If a `module-knowledge/<CODE>_<Name>.md` file exists for this module, read it before making
   any claim about counts, completion, or gaps (seeded snapshots can be stale — verify against
   the live tree).
