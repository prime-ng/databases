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
