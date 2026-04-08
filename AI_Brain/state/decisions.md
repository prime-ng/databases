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
- **Files created:** first_pdf (Template 1, Grades 3-5 — DomPDF-fixed R1+R2 2026-03-14/15), second_pdf (Template 2, Grades 3-5 variant — DomPDF-fixed R1+R2 2026-03-14/15), third_pdf (Template 3, Grades 6-8, 46 pages — DomPDF-fixed 2026-03-14), fourth_pdf (Template 4, Grades 9-12, 44 pages — DomPDF-fixed 2026-03-14)
- **HPC shared tabbed index pattern:** All 15 HPC controllers render the same `hpc::hpc.index` view with different active tabs. Each controller's `index()` loads data for ALL tabs (~15 queries per request). This is an intentional design choice for the tab-based UI but causes significant performance overhead. Should be refactored to AJAX-loaded tabs.
- **HPC report save pattern:** `HpcReportService::saveReport()` uses a delete-then-reinsert strategy inside a DB transaction — it force-deletes ALL existing HpcReportItem and HpcReportTable rows for a report, then bulk-inserts fresh rows from form data (batches of 200 with per-row retry). This is intentional to avoid complex merge logic but means partial saves are all-or-nothing.

**DomPDF Hard Constraints (enforced — do NOT violate in any `*_pdf.blade.php`):**
1. **CRASH** — `display:inline` on `<table>` → *"Min/max width is undefined for table rows"*. Remove it; use parent `<td style="text-align:right">` for alignment.
2. **CRASH** — Nested `<table>` without `width="100%"` HTML attribute inside `<td>` → same crash. Every `<table>` must have `<table width="100%" ...>`.
3. **CRASH** — Wrong closing tag (`</div>` where `</td>` expected) inside `<table><tr>` → *"Parent table not found for table cell"*. Always verify table cell closing tags.
4. **STRUCTURAL** — `<div class="page-container">` opened in `@foreach` but never closed before `@endforeach` → all pages nest. Must add `</div>{{-- close page-container --}}` before `@endforeach`.
5. **STRUCTURAL** — Duplicate `@if($part->page_no == N)` blocks (orphan outside loop) → page renders twice. Search for all occurrences before writing any new page block.
6. **IMAGE** — `getFirstMediaUrl()` / `tenant_asset()` / HTTP URLs in `<img src>` → blank (DomPDF blocks remote). Must use base64 data URIs via `file_get_contents(getPath())`.
7. **LAYOUT** — `overflow:hidden` on `<div>` → silently ignored or mis-clips. Remove from all containers; use padding instead.
8. **LAYOUT** — `display:inline-block` on `<div>` → silently ignored. Use `<table>` for side-by-side layouts.
9. **LAYOUT** — `<ol>/<ul>` inside `<td>` → unreliable markers/overflow. Replace with manual `{{ $idx+1 }}. {{ $item }}` divs or inner `<table width="100%">`.
10. **LAYOUT** — `page-break-inside:avoid` on containers taller than one page → overridden by DomPDF. Only use on small atomic units; remove from full-section wrappers.
11. **JAVASCRIPT** — Any `<script>` block in the template is ignored by DomPDF. Remove `window.onload` / `window.print()` scripts.

### D15: DB Schema — v2 Enhanced DDLs as Single Source of Truth
- **Why:** Original DDLs had syntax errors, missing FKs, inconsistent naming, duplicate columns. Engineering audit identified 51+ issues in tenant_db alone. Consolidated + corrected into 3 v2 files.
- **Canonical files:** `global_db_v2.sql`, `prime_db_v2.sql`, `tenant_db_v2.sql` in `{DDL_DIR}/`
- **NEVER use:** Any other DDL file — `Old_DDLs/`, `2-Prime_Modules/`, `2-Tenant_Modules/`, `Working/`, or non-v2 root files
- **CHANGELOG:** Was in `{DDL_DIR}/CHANGELOG.md` (now archived) — documented all changes from v1 → v2

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

### D19: SmartTimetable — Full Constraint Architecture (P09–P13, 2026-03-17)
- **Why:** Previous constraint system had only 13 PHP classes and ~30/155 rules enforced. FETSolver scored slots with only spread/distribution heuristics. No registry, no evaluator, no formal context.
- **Architecture (implemented in P01–P21):**
  - `ConstraintRegistry` — plugin system for registering constraint classes by code. Three-step resolution: Registry → CONSTRAINT_CLASS_MAP → infer → Generic fallback.
  - `ConstraintEvaluator` — parallel evaluation engine with group support (MUTEX/CONCURRENT/ORDERED). **WARNING:** Not yet wired into generation path — `FETSolver` still uses `ConstraintManager` directly.
  - `ConstraintContext` — value object for evaluation context (occupied, teacherOccupied, periods, days). **WARNING:** Only used in `FETConstraintBridge`, not in actual `ConstraintManager` calls which use raw `\stdClass`.
  - `ConstraintFactory` — creates constraint instances from DB records with JSON parameter validation.
  - `TimetableConstraint` interface — `passes(Slot, Activity, $context): bool`, `getDescription()`, `getWeight()`, `isRelevant()`.
  - 22 Hard constraint classes in `Constraints/Hard/` (teacher, class, room, activity, global, inter-activity).
  - 55+ Soft constraint classes in `Constraints/Soft/` (teacher, class, room, inter-activity preferences).
  - `SmartTimetableServiceProvider` registers all constraints via `registerConstraints()` method.
  - `ConstraintTypeSeeder` expanded to 212 entries with full parameter schemas.
- **Known issues:** FETConstraintBridge passes bare context (BUG-TT-002); gap calculations mix period_id/index (BUG-TT-003); ConstraintManager and ConstraintEvaluator duplicate logic (CODE-TT-002); legacy interfaces orphaned (CODE-TT-001).

### D20: SmartTimetable — Service Layer Decomposition (P14–P17, 2026-03-17)
- **Why:** SmartTimetableController was 3037 lines. New dedicated services and controllers extract analytics, refinement, substitution, and API concerns.
- **Pattern:** Each feature area gets its own Controller+Service pair. Controllers handle auth (Gate::authorize) and validation. Services contain business logic.
  - `AnalyticsController` + `AnalyticsService` — workload, utilization, violations, CSV exports
  - `RefinementController` + `RefinementService` — swap/move/lock cells, impact analysis, change logs
  - `SubstitutionController` + `SubstitutionService` — absence reporting, candidate scoring, auto-assignment
  - `TimetableApiController` — REST API (auth:sanctum) for external integrations
  - `GenerateTimetableJob` — async generation with status polling
  - `RoomChangeTrackingService` — room/building change violation detection
- **Known issues:** SubstitutionService crashes (BUG-TT-004/005), Job missing tenant context (BUG-TT-006), API zero auth (BUG-TT-001).

### D21: SmartTimetable — Comprehensive Reverse-Engineering Documentation (2026-03-31)
- **Why:** Module had grown to 449 files across 20 controllers, 63 models, 108 services, and 176 views with no centralized documentation. New developers and AI agents needed a complete reference to understand the module without reading source code.
- **Output:** `5-Work-In-Progress/2-In-Progress/SmartTimetable/SmartTimetable_Module_Documentation.md` — 4,621 lines, 31 sections covering: terminology (30+ terms), design intent (from 19 design docs), file inventory, routes (60+ web + 11 API), user workflow (11 phases), screen walkthroughs (15 screens), database schema (43+ tables with column details), data flows (24 operations), FET algorithm (complete pseudocode), constraint engine (24 hard + 60 soft classes), conflict detection, refinement, substitution, gap analysis.
- **Key findings:** Module at ~60% completion. 125/155 designed constraints not yet implemented. 17/20 controllers lack authorization. Phases 6-8 (Analytics/Publish/Substitution) mostly unstarted. 0 module-level tests.
- **Reference:** Generated from DDL v7.6 + 19 design documents + full code read of all 449 module files.

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

---

## Architectural Issues Discovered — Deep Audit 2026-04-02

### D22: Route Registration Architecture — Module-Owned Routes (RESOLVED 2026-04-02)
- **Discovery (2026-04-02):** 3 routing layers overlapped: `routes/tenant.php` (tenancy middleware), module `routes/web.php` (loaded by module RSP, often without tenancy middleware), central `routes/web.php`.
- **Resolution:** Migration prompt `databases/5-Work-In-Progress/1-Completed/Update_Route_Permission_AllModules/migrate-module-routes-policies_v2.md` executed on `prime_ai_shailesh` 2026-04-02.
- **New canonical architecture:**
  - **Tenant module routes:** `Modules/{ModuleName}/routes/web.php` — each module owns its routes entirely
  - **Gate policies:** `Modules/{ModuleName}/app/Providers/{ModuleName}ServiceProvider.php` → `registerPolicies()` method
  - **`routes/tenant.php`** (224 lines): auth routes only + 1 cross-module route + seeder routes (still P0 SEC-RTG-001) + tenancy middleware wrapper
  - **`AppServiceProvider.php`** (127 lines): module policy blocks removed; cross-module-only policies remain
- **Status:** ✅ RESOLVED in `prime_ai_shailesh`. Remaining risk: module RSP tenancy middleware (D23 still open).

### D23: RSP Tenancy Middleware — 2 Modules Missing Entirely
- **Discovery:** Scheduler and EventEngine RSPs apply only `Route::middleware('web')` — no `InitializeTenancyByDomain`, no `PreventAccessFromCentralDomains`. SmartTimetable RSP missing tenancy on ParallelGroupController.
- **Impact:** All routes served by these RSPs operate without tenant DB context — queries hit central database or fail.
- **Decision needed:** Add full tenancy middleware stack (`InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`) to all tenant module RSPs.
- **Status:** Identified, not yet fixed.

### D24: Permission Naming Taxonomy — 5 Conflicting Prefixes
- **Discovery:** Five different Gate permission prefixes coexist: `tenant.*` (standard), `prime.*` (Notification module — wrong context), `global-master.*` (GlobalMaster Language), `vendor.*` (VndUsageLog/VendorPayment), `transport.*` (TripController). Additionally, `tested.*` in Transport AttendanceDevice is a typo.
- **Impact:** Policies defined under one prefix are invisible to Gates checking another. Auth silently fails (403) or silently passes depending on how `Gate::authorize()` handles missing policies.
- **Decision needed:** Standardize to `tenant.*` for all tenant-scoped modules and `prime.*` for all central modules. No exceptions.
- **Status:** Identified, not yet fixed.

### D25: $request->all() vs $request->validated() — Systemic Pattern
- **Discovery:** 30+ controllers across 12+ modules inject FormRequest classes but call `$request->all()` instead of `$request->validated()`, bypassing the validation result entirely. This is the single most widespread vulnerability pattern.
- **Impact:** Extra fields submitted in the request body bypass validation rules and flow directly into `Model::create()` / `->update()`, enabling mass-assignment attacks even with FormRequests in place.
- **Decision needed:** Project-wide find-and-replace of `$request->all()` with `$request->validated()` in all controllers that inject FormRequest types. Add a custom PHPStan/Larastan rule to flag this pattern.
- **Status:** Identified, not yet fixed.
