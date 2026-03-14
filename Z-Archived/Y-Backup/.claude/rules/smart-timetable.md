---
globs: ["Modules/SmartTimetable/**", "database/migrations/tenant/*timetable*", "database/migrations/tenant/*constraint*", "database/migrations/tenant/*parallel*"]
---

# SmartTimetable Module Rules

## Module Context
- 84 models, 27 controllers, 35 services
- Table prefix: `tt_*` (~45 tables)
- FET-inspired solver with CSP backtracking
- Route prefix: `/smart-timetable/*`

## Key Decisions
- **D11:** FET-inspired solver with backtracking + greedy fallback + rescue pass + forced placement
- **D14:** Parallel periods use anchor-based placement (anchor placed first, siblings follow)
- **D16:** Constraint management uses category-specific views, all write to `tt_constraints` differentiated by `constraintType.category.code`
- **D17:** Model/migration mismatches fixed with additive-only migrations

## Architecture
- Activity-based scheduling: `tt_activities` → `tt_sub_activities` → `tt_timetable_cells`
- Constraint engine: `tt_constraints` → `tt_constraint_types` → `tt_constraint_category_scope` (combined table with `type` ENUM)
- Parallel groups: `tt_parallel_group` → `tt_parallel_group_activity` (with `is_anchor` flag)
- Generation: `tt_generation_runs` → FETSolver → `TimetableStorageService` (atomic DB transaction)

## Critical Rules
1. **ConstraintCategory and ConstraintScope** both point to `tt_constraint_category_scope` with global scope filtering by `type` ENUM. Do NOT create separate tables.
2. **Corrective migrations are additive only** — no drops, no renames, to protect existing tenant data.
3. **Constraint model** uses actual DB column names: `academic_session_id` (not `academic_term_id`), `effective_from` (not `effective_from_date`), `applies_to_days_json` (not `applicable_days_json`), `target_type` (not `target_type_id`)
4. **Category-specific CRUD routes** (`createByCategory`, `editByCategory`) must come BEFORE `Route::resource('constraint', ...)` to avoid route conflicts.
5. **Activity constraints tab** shows Activity records, NOT Constraint records. It's read-only.

## Key Files
- Solver: `Modules/SmartTimetable/app/Services/FETSolver.php`
- Storage: `Modules/SmartTimetable/app/Services/TimetableStorageService.php`
- Constraints: `Modules/SmartTimetable/app/Http/Controllers/ConstraintController.php`
- Main controller: `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` (2958 lines — needs splitting)

## Known Issues
- SmartTimetableController has ZERO authorization checks (SEC-009)
- Non-anchor parallel activities must be SKIPPED (not blocked) when anchor hasn't been placed yet
- Sibling classKey must come from sibling activity, not anchor
