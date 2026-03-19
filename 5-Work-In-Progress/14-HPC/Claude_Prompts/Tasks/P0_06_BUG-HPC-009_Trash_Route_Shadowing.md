# PROMPT: Fix Trash Route Shadowing by Resource Routes — HPC Module
**Task ID:** P0_06
**Issue IDs:** BUG-HPC-009
**Priority:** P0-Critical
**Estimated Effort:** 30 minutes
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
```

---

## CONTEXT

All 10 HPC resource controllers have trash/view routes (e.g., `GET /hpc/circular-goals/trash/view`) registered AFTER `Route::resource()`. The resource `show` route (`GET {resource}/{id}`) matches `trash` as the `{id}` parameter first, making all trash routes unreachable. This affects: circular-goals, question-mapping, learning-activities, learning-outcomes, knowledge-graph-validation, syllabus-coverage-snapshot, topic-equivalency, student-hpc-evaluation, hpc-parameters, hpc-performance-descriptor.

---

## PRE-READ (Mandatory)

1. `{ROUTES_FILE}` — Search for all HPC resource route registrations and their associated trash routes

---

## STEPS

1. Read tenant.php and identify ALL 10 HPC resource routes and their associated trash/trashed routes
2. For each resource, move the trash-related routes (GET trash/view, POST restore, DELETE force-delete) to BEFORE the `Route::resource()` registration
3. Alternatively, register the resource route with `->except(['show'])` and add the show route explicitly after trash routes
4. Verify the pattern is consistent across all 10 resources

---

## ACCEPTANCE CRITERIA

- All 10 trash/view routes are reachable (not shadowed by resource show route)
- All 10 resource CRUD routes still work correctly
- `php artisan route:list --path=hpc` shows trash routes with correct controller methods
- `php artisan route:cache` runs without errors

---

## DO NOT

- Do NOT change controller methods — only route registration order
- Do NOT remove any routes
- Do NOT add new routes
