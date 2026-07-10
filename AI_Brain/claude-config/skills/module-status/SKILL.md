---
name: module-status
description: Show status report for a specific module or all modules
user_invocable: true
---

# /module-status — Module Status Report

Show comprehensive status for a module.

## Usage
- `/module-status` — Overview of all modules
- `/module-status ModuleName` — Detailed report for one module

## For All Modules
1. Read `AI_Brain/memory/modules-map.md`
2. Read `AI_Brain/state/progress.md`
3. Show table: Module | Controllers | Models | Services | Tests | Status

## For Specific Module
1. Count files:
   ```bash
   find Modules/{Module}/app/Http/Controllers -name "*.php" | wc -l
   find Modules/{Module}/app/Models -name "*.php" | wc -l
   find Modules/{Module}/app/Services -name "*.php" | wc -l
   find Modules/{Module}/tests -name "*.php" | wc -l
   ```

2. List routes: `php artisan route:list --name={module-prefix}`

3. Check `AI_Brain/lessons/known-issues.md` and `AI_Brain/memory/known-bugs-and-roadmap.md`

4. Report: file counts, routes, known issues, completion %, missing components

## Scored 10-Dimension Report (recommended)
This skill gives a fast count-based snapshot. For the **reliable, evidence-anchored,
stage-by-stage percentage report** (Requirement Doc, DDL, Dev Coverage, Security, Coding
Standard, Bug-Fix, Tests, Deployment Readiness, Performance — each as its own module-wise %),
invoke the **Status_Analyzer agent** which follows `AI_Brain/config/completion-formula-v2.md`:

- Full analysis: "Act as Status_Analyzer. Full analysis of {Module}."
- Scoped: name specific dimensions, e.g. "Status_Analyzer: Security + Deployment readiness only."

The agent produces the Completeness Dashboard + Evidence Ledger + Deployment Verdict and can
update `progress.md`.
