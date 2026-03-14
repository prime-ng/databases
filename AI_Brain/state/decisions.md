# Architectural Decisions Log

## Confirmed Decisions

### D1: Multi-Tenancy — stancl/tenancy v3.9 with Database-per-Tenant
- **Why:** Complete data isolation for each school. Regulatory compliance for Indian schools (data sovereignty). Simpler backup/restore per tenant. No risk of cross-tenant data leakage.
- **Trade-off:** Higher infrastructure cost (one DB per school), more complex migration management.
- **Alternative considered:** Shared DB with `tenant_id` column — rejected due to data isolation requirements.

### D2: Modular Architecture — nwidart/laravel-modules v12.0
- **Why:** ~40 planned modules. Each module is self-contained with its own models, controllers, routes, migrations. Enables independent development and testing. Clear separation of concerns.
- **Trade-off:** Slightly more boilerplate per module, module interdependency management needed.

### D3: 3-Layer Database Architecture
- **Why:** Separation of shared reference data (global_db), SaaS management (prime_db), and school data (tenant_db). Global masters shared without duplication. Central billing independent of tenant databases.
- **global_db:** Countries, states, boards, languages, menus, modules
- **prime_db:** Tenants, plans, billing, central users/roles
- **tenant_db:** Per-school everything (students, teachers, timetable, fees, etc.)

### D4: RBAC — Spatie Laravel Permission v6.21
- **Why:** Mature, well-documented, polymorphic role/permission assignment. Supports both central and tenant-scoped roles. Gate and middleware integration.
- **Implementation:** Roles and permissions exist in BOTH central (prime_db) and tenant (tenant_db) databases.

### D5: UUID-based Tenant Identification
- **Why:** Prevents enumeration attacks, globally unique across all environments, no conflicts during tenant migration.
- **Generator:** `Stancl\Tenancy\UUIDGenerator`

### D6: Domain-based Tenant Routing
- **Why:** Each school gets its own subdomain (e.g., `schoolname.prime-ai.com`). Clean URL structure, easy to manage with DNS.
- **Middleware:** `InitializeTenancyByDomain`

### D7: Table Prefix Convention
- **Why:** With 368+ tables in tenant_db, prefixes provide immediate module identification. `tt_` for timetable, `std_` for students, `sch_` for school setup, etc.
- **Junction tables:** Suffixed with `_jnt` for easy identification.

### D8: Soft Deletes Everywhere
- **Why:** Audit trail requirements. Schools need to recover accidentally deleted records. Regulatory compliance for attendance and exam records.
- **Implementation:** `is_active` boolean + `deleted_at` timestamp on every table.

### D9: DomPDF for PDF Generation
- **Why:** No external service dependency, works server-side, sufficient for report cards, fee receipts, and HPC documents.
- **Package:** `barryvdh/laravel-dompdf` v3.1

### D10: Razorpay for Payment Processing
- **Why:** Most popular payment gateway in India. Supports UPI, cards, net banking, wallets. Well-documented PHP SDK.
- **Package:** `razorpay/razorpay` v2.9

### D11: SmartTimetable — FET-inspired Solver
- **Why:** FET (Free Timetabling Software) algorithm is proven for school timetabling. CSP backtracking with greedy fallback, rescue pass, and forced placement. Handles complex constraints.
- **Architecture:** Activity-based scheduling with 10-stage implementation plan.

### D13: HPC PDF — Merged Single-File DomPDF Template Pattern
- **Why:** DomPDF cannot resolve Blade components (`<x-hpc-form.*>`), Bootstrap classes, flexbox/grid, or JavaScript. A single self-contained Blade file with all logic inlined is required.
- **Pattern:** One merged `*_pdf.blade.php` per HPC template form. Contains: `$css` array, helper closures (`$getStudentValue`, `$shouldCheckGrade`, `$renderItem`), full `<!DOCTYPE html>` document, `@foreach($sortedParts as $part)` main loop, per-page `@if($part->page_no == N)` blocks, page breaks via `<div style="{{ $css['page'] }}"></div>`.
- **Components location:** `resources/views/components/hpc-form/` (6 components: activity-tab, student-self-reflection, peer-feedback, tab-eight-teacher-feedback, performance-card, self-assessment)
- **Emoji:** `asset('emoji/happy.png')`, `asset('emoji/no.png')`, `asset('emoji/not_sure.png')`, `asset('emoji/sometimes.png')` — local public folder files
- **Layout rule:** Use `<table>` for all multi-column layouts (no flexbox/grid in DomPDF)
- **Files created:** first_pdf (Template 1, Grades 3-5), second_pdf (Template 2, Grades 3-5 variant), third_pdf (Template 3, Grades 6-8, 46 pages)

### D15: DB Schema — v2 Enhanced DDLs as Single Source of Truth
- **Why:** Original DDLs had syntax errors, missing FKs, inconsistent naming, duplicate columns. Engineering audit identified 51+ issues in tenant_db alone. Consolidated + corrected into 3 v2 files.
- **Canonical files:** `global_db_v2.sql`, `prime_db_v2.sql`, `tenant_db_v2.sql` in `1-master_dbs/1-DDLs/`
- **NEVER use:** Any other DDL file — `Old_DDLs/`, `2-Prime_Modules/`, `2-Tenant_Modules/`, `Working/`, or non-v2 root files
- **CHANGELOG:** `1-master_dbs/1-DDLs/CHANGELOG.md` documents all changes from v1 → v2

### D14: SmartTimetable Parallel Periods — Anchor-Based Solver Pattern
- **Why:** Activities across sections (Hobby, Skill, Optional) must run simultaneously. FETSolver needs to treat these as atomic units.
- **Pattern:** One activity in the group is the "anchor" (`is_anchor=1` in `tt_parallel_group_activity`). When the anchor is placed during backtracking, all non-anchor siblings are immediately placed at the same day+period. Non-anchor members encountered in the ordering are skipped until their anchor is placed (force-assigned to anchor's slot).
- **Tables:** `tt_parallel_group` (group config) + `tt_parallel_group_activity` (junction with `is_anchor` flag)
- **Solver changes:** `orderActivitiesByDifficulty()` boosts parallel members +20000 (anchors +5000 extra); `backtrack()` handles anchor→sibling atomic placement with rollback; `generateGreedySolution()` places siblings immediately after anchor.
- **Full implementation complete (2026-03-14):** Constraint Engine (ParallelPeriodConstraint, ConstraintFactory, ConstraintTypeSeeder), Pre-Gen Validation in SmartTimetableController, Post-Gen Verification + session key `generated_parallel_violations`, soft constraint wiring (see D18), bug fix in TimetableSolution::remove(), 9 unit tests passing.

### D18: SmartTimetable — Soft Constraint Wiring in FETSolver
- **Why:** `ConstraintManager::evaluateSoftConstraints()` was fully implemented but never called — soft preferences (preferred times, preferred rooms, etc.) had zero effect on slot scoring.
- **Pattern:** Called inside `scoreSlotForActivity()` after all spread/distribution logic. Returns 0–100 sum of satisfied soft constraint weights. Applied at 0.5× multiplier (`$score += (int) round($softScore * 0.5)`) so soft constraints influence but never dominate the existing [-50, +40] hard score range.
- **Safety:** Wrapped in `try/catch(\Throwable)` so any ConstraintManager exception degrades gracefully (logs warning, skips contribution). Verbose-logged when `$verboseLogging` is enabled.
- **File:** `FETSolver::scoreSlotForActivity()` (after spread_evenly block, before `return $score`).

### D12: Database Queue Driver (Current)
- **Why:** Simpler infrastructure for initial deployment. No Redis dependency needed.
- **Future:** Will migrate to Redis queue driver when scaling requires it.

### D17: SmartTimetable Constraint Model/Migration Mismatches — Audit & Fix Strategy
- **Mismatch A:** `ConstraintCategory::$table` pointed to `tt_constraint_categories` and `ConstraintScope::$table` pointed to `tt_constraint_scopes` — neither table exists. The actual migration created one shared table `tt_constraint_category_scope` with a `type` ENUM. **Fix:** Both models now point to `tt_constraint_category_scope` with `addGlobalScope` filtering by `type`. `ConstraintCategoryScope` model remains as the raw combined-table model.
- **Mismatch B:** `ConstraintType` model had `is_hard_capable`, `is_soft_capable`, `parameter_schema`, `applicable_target_types`, `constraint_level` in fillable — none existed in DB. **Fix:** Migration 1 adds these columns additively. Model unchanged (already correct for post-migration state). Old columns `is_hard_constraint` and `param_schema` kept.
- **Mismatch C:** `Constraint` model had `academic_term_id`/`effective_from_date`/`effective_to_date`/`applicable_days_json`/`target_type_id` — DB has `academic_session_id`/`effective_from`/`effective_to`/`applies_to_days_json`/`target_type`. **Fix (model-side):** Updated model fillable/casts/scopes/helpers to use actual DB column names. Migration 2 adds the original model-named alias columns for backward compat.
- **Rule:** All corrective migrations are additive only (no drops, no renames) to protect existing tenant data.

### D16: SmartTimetable Constraint Management — Full CRUD with Category-Specific Views (UPDATED)
- **Why:** Constraint management page shows live DB data per category. All configurable constraints write to one table `tt_constraints`, differentiated by `constraintType.category.code` relationship chain.
- **Index pattern:** `constraintManagement()` runs 6 paginated queries (teacher/class/room/db/global/inter-activity), each filtered by `whereHas('constraintType.category', code)`. Activity tab shows Activity records (`$activityConstraintSummary`), not Constraint records.
- **CRUD routing:** Two extra routes before `Route::resource('constraint', ...)`: `GET /constraint/category/{categoryCode}/create` → `createByCategory()`, `GET /constraint/{constraint}/category-edit` → `editByCategory()`. These must come BEFORE the resource to avoid route conflicts.
- **Category-specific views:** `createByCategory()` / `editByCategory()` resolve view via `match($categoryCode)` → `constraint-management/{slug}/create|edit.blade.php`. Each view loads category-relevant dropdowns (teachers/classes/rooms/activities). All store/update goes to same `ConstraintController::store()` / `update()` endpoint.
- **Hidden fields pattern:** All category forms pass `<input type="hidden" name="category_code" value="...">` and `<input type="hidden" name="target_type" value="...">` so the controller knows which anchor to redirect to and which target validation to apply.
- **PHP Class column (db-constraints tab):** Badge `Registered` (bg-primary) if `constraintType->parameter_schema` is non-null; `Not wired` (bg-warning) otherwise.
- **Engine rules tab:** Info alert + no Add/Trash/Action buttons — always-on hardcoded rules.
- **Activity constraints tab:** Read-only list (link to activity edit) — fields on `tt_activities`, not separate constraint records.
- **Redirect anchors:** After store/update, redirect to `constraint-management#{category}-pane` using `match($category_code)` anchor map.

---

## Future Decisions (Pending)

### Pending: Event Engine Architecture
- Need to decide: Event-driven vs scheduled polling for cross-module communication
- Status: Module at 20% completion

### Pending: Analytics Pipeline
- Need to decide: Real-time vs batch processing for student analytics
- Options: Laravel Jobs + Cache vs dedicated analytics service

### Pending: Student/Parent Portal
- Need to decide: Same Laravel app with role-based views vs separate SPA
- Options: Blade views vs Vue.js/React SPA

### Pending: Accounting Module
- Need to decide: Build custom vs integrate with existing accounting software
- Double-entry bookkeeping requirements

### Pending: Redis Migration
- When to move queue, cache, and session drivers from database to Redis
- Dependent on production traffic patterns
