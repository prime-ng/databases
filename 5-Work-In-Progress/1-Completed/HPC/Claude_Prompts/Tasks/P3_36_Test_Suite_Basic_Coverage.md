# PROMPT: Build Basic Test Suite — HPC Module
**Task ID:** P3_36
**Issue IDs:** Tests
**Priority:** P3-Low
**Estimated Effort:** 5 days
**Prerequisites:** All P2 tasks must be complete

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

HPC module has 0 tests. Need basic coverage for: authorization (all Gate checks work), CRUD operations (all 10 resource controllers), form save/load, PDF generation, email dispatch, and workflow transitions.

---

## PRE-READ (Mandatory)

1. `{LARAVEL_REPO}/tests/` — existing test structure and base classes
2. `{MODULE_PATH}/app/Http/Controllers/` — all 15 controllers
3. Existing test examples from other modules (e.g., SmartTimetable tests)

---

## STEPS

1. Create test directory: `{MODULE_PATH}/tests/Feature/` and `{MODULE_PATH}/tests/Unit/`
2. **Authorization tests** (Feature): verify each Gate permission blocks unauthorized users
3. **CRUD tests** (Feature): test index/store/show/update/destroy for 3-4 resource controllers
4. **Form tests** (Feature): test hpc_form() loads, formStore() saves, data persists
5. **PDF tests** (Unit): test HpcReportService generates PDF without errors
6. **Workflow tests** (Unit): test status transitions (from P2_21)
7. Use Pest 4.x syntax with `Tests\TestCase` base class and `RefreshDatabase`

---

## ACCEPTANCE CRITERIA

- Minimum 30 tests across Feature and Unit
- All authorization Gate checks tested
- CRUD happy path for at least 4 controllers
- Form save/load roundtrip tested
- PDF generation tested (at least "doesn't crash")
- All tests pass: `php artisan test --filter=Hpc`

---

## DO NOT

- Do NOT aim for 100% coverage — focus on critical paths
- Do NOT mock the database (use RefreshDatabase)
- Do NOT test blade view rendering (test HTTP responses only)
