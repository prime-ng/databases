# PROMPT: Remove Orphan LearningActivityController Import — HPC Module
**Task ID:** P1_13
**Issue IDs:** BUG-HPC-008
**Priority:** P1-High
**Estimated Effort:** 5 minutes
**Prerequisites:** None

---

## CONFIGURATION
```
ROUTES_FILE    = /Users/bkwork/Herd/prime_ai/routes/tenant.php
```

---

## CONTEXT

`tenant.php` (line ~19) imports `Modules\Hpc\Http\Controllers\LearningActivityController` (singular) but the actual file is `LearningActivitiesController` (plural). The orphan import may cause a fatal autoload error during `php artisan route:cache`.

---

## PRE-READ (Mandatory)

1. `{ROUTES_FILE}` — Search for `LearningActivityController` (singular) in imports

---

## STEPS

1. Find and remove: `use Modules\Hpc\Http\Controllers\LearningActivityController;`
2. Verify `use Modules\Hpc\Http\Controllers\LearningActivitiesController;` (plural) already exists
3. Run `php artisan route:cache` to confirm no errors

---

## ACCEPTANCE CRITERIA

- Orphan `LearningActivityController` import removed
- `LearningActivitiesController` import remains
- `php artisan route:cache` succeeds

---

## DO NOT

- Do NOT rename any controller files
- Do NOT modify routes
