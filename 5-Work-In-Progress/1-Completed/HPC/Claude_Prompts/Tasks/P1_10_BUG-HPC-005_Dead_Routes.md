# PROMPT: Remove 3 Dead Routes — HPC Module
**Task ID:** P1_10
**Issue IDs:** BUG-HPC-005
**Priority:** P1-High
**Estimated Effort:** 15 minutes
**Prerequisites:** P0_03

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
```

---

## CONTEXT

Three routes in tenant.php point to non-existent HpcController methods: `hpcSecondForm`, `hpcThredForm`, `hpcFourthForm`. These always return 500 (BadMethodCallException). The routes appear to be leftovers from when there were separate form pages per template — now all templates use `hpc_form()`.

---

## PRE-READ (Mandatory)

1. `{ROUTES_FILE}` — Search for `hpcSecondForm`, `hpcThredForm`, `hpcFourthForm` (around lines 2508-2510)

---

## STEPS

1. Find and remove the 3 dead route registrations:
   - `GET /hpc/hpc-second-form` → `hpcSecondForm`
   - `GET /hpc/hpc-thred-form` → `hpcThredForm`
   - `GET /hpc/hpc-four-form` → `hpcFourthForm`
2. Verify no blade templates link to these URLs (search for `hpc-second-form`, `hpc-thred-form`, `hpc-four-form` in HPC views)

---

## ACCEPTANCE CRITERIA

- 3 dead routes removed from tenant.php
- No blade templates reference these URLs
- `php artisan route:cache` runs without errors

---

## DO NOT

- Do NOT add replacement routes
- Do NOT modify HpcController
