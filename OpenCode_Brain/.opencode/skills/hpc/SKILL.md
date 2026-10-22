---
name: HPC Module Rules
description: HPC (Holistic Progress Card) module rules — the DomPDF template pattern, template coverage, and open data-provider gaps.
---

# HPC Module Rules

Use when working on the HPC module (`Modules/Hpc/**`) or HPC PDF templates.

## Workflow

1. Read `instructions/hpc.md` — the full rule set for this module — and follow it.
2. Resolve every `{VARIABLE}` via `config/paths.md`.
3. If a `module-knowledge/<CODE>_<Name>.md` file exists for this module, read it before making
   any claim about counts, completion, or gaps (seeded snapshots can be stale — verify against
   the live tree).
