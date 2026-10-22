---
name: SmartTimetable Rules
description: SmartTimetable module rules — FET-inspired solver, constraint engine, parallel periods, and coding constraints for Modules/SmartTimetable.
---

# SmartTimetable Rules

Use when working on the SmartTimetable module (`Modules/SmartTimetable/**`) or its timetable migrations.

## Workflow

1. Read `instructions/smart-timetable.md` — the full rule set for this module — and follow it.
2. Resolve every `{VARIABLE}` via `config/paths.md`.
3. If a `module-knowledge/<CODE>_<Name>.md` file exists for this module, read it before making
   any claim about counts, completion, or gaps (seeded snapshots can be stale — verify against
   the live tree).
