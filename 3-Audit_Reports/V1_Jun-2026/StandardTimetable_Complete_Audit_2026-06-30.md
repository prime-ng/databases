# Mode X Complete Technical Audit — StandardTimetable Module
**Date:** 2026-06-30
**Auditor:** pa-technical-auditor (AI Brain v3)
**Audit Mode:** X (A + B + C + G + scoped D)
**Module:** StandardTimetable (`Modules/StandardTimetable/`) | Code: TTS
**Table prefix:** `tt_*` (TTS writes NO exclusive tables; shares the namespace with TimetableFoundation and SmartTimetable)
**Platform:** PHP 8.2 / Laravel 12 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12

---

## Executive Summary

StandardTimetable is the manual timetable construction interface — the drag-and-drop grid editor that lets a Timetable Coordinator place subject-teacher assignments into a school week. It depends entirely on TimetableFoundation (TTF) models and writes to shared `tt_*` tables using `generation_method = 'MANUAL'` and `source = 'MANUAL'` as discriminators.

This audit found **2 P0 issues** and **15 P1+ issues** that collectively mean:

1. Every write endpoint (place cell, remove cell, create timetable, delete timetable) is protected by a single `standard-timetable.viewAny` gate that is never seeded — module is super-admin-only or exposes write operations to any user with view access.
2. `createTimetable()` writes a global-DB academic session ID into a tenant-DB foreign key, causing an FK violation (errno 1452) for every tenant where `glb_academic_sessions.id` does not match a row in `sch_org_academic_sessions_jnt`.
3. Teacher conflict detection silently produces empty results for all teacher-type conflicts due to a wrong column name in the filter predicate (`id` vs `teacher_id`).
4. `removeCell()` uses an incomplete lookup key that can silently delete the wrong class's cell in multi-class timetables.
5. 80%+ of the FRD (read views, publishing workflow, cell locking, copy timetable, batch validate) is entirely unbuilt.

**Deploy Gate: NO-GO**
**Health Score: 30 / 100 (P0-capped; raw weighted 30.75)**

---

## Module Inventory (Verified from `find Modules/StandardTimetable -type f`)

| Asset Type | Count | Notes |
|---|---|---|
| Controllers | 1 | `StandardTimetableController.php` — 513 lines, 6 public methods |
| Models | 0 | Uses TTF models directly; no own model classes |
| Services | 0 | All business logic in controller |
| FormRequests | 0 | 3 methods use inline `$request->validate()` |
| Policies | 0 | No policy class; not registered anywhere |
| Routes (module web.php) | 6 | GET /, GET /manual-placement, POST /place-cell, POST /remove-cell, POST /create-timetable, DELETE /delete-timetable/{id} |
| Routes (tenant.php) | 0 active | Lines 229-231 are a dead empty group |
| Views | 3 | master.blade.php, index.blade.php, manual-placement.blade.php (730 lines) |
| Seeders | 1 | Empty stub — no permissions, no roles |
| Tests | 0 | Feature/ and Unit/ both contain only .gitkeep |
| Tenant migrations | 0 | Module `database/migrations/` contains only .gitkeep; all tt_* migrations are in root `database/migrations/tenant/` owned by TTF |

---

## Part A — 12-Layer Technical Audit

### Layer 1: Multi-Tenancy Isolation

**Finding TEN-TTS-001 (P0) — Cross-Layer AcademicSession Import: FK Violation on createTimetable**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:13` (import) and `:346` (call site)
- **Pattern:** SEC-PLATFORM-007 (TTS instance)

`createTimetable()` calls `AcademicSession::current()->first()` where `AcademicSession` resolves to `Modules\Prime\Models\AcademicSession`. That model declares:
```php
protected $connection = 'global_master_mysql';  // global_db
protected $table     = 'glb_academic_sessions';
```

The returned `id` (e.g., `3`) is stored in `tt_timetables.academic_session_id`. The migration defines a hard FK:
```sql
FOREIGN KEY (academic_session_id) REFERENCES sch_org_academic_sessions_jnt(id)
```
`sch_org_academic_sessions_jnt` is a **tenant-db table** with its own independent auto-increment sequence. A `glb_academic_sessions.id = 3` almost certainly does not match any row in the tenant's `sch_org_academic_sessions_jnt`, causing `errno: 1452 Cannot add or update a child row: a foreign key constraint fails` on every `createTimetable()` call for most tenants.

**Fix:** Replace `use Modules\Prime\Models\AcademicSession;` with `use Modules\SchoolSetup\Models\OrganizationAcademicSession;` (which uses `tenant_mysql` and resolves to `sch_org_academic_sessions_jnt`). Update the call to `OrganizationAcademicSession::current()->first()`.

---

**Finding TEN-TTS-002 (P2) — Dead Placeholder Route Group in tenant.php Lacks Tenancy Middleware**
- **File:** `routes/tenant.php:229-231`

Lines 229-231 define an empty middleware group that uses only `auth` and `verified` — missing the tenancy initialization chain entirely. This is dead code (no routes inside), but its presence risks a developer inadvertently adding routes to it and bypassing tenant isolation.

```php
Route::middleware(['auth', 'verified'])->prefix('standard-timetable')->name('standard-timetable.')->group(function () {
    // EMPTY
});
```

**Fix:** Remove the empty group. Add a comment: `// StandardTimetable routes → Modules/StandardTimetable/routes/web.php`.

---

**Tenancy Stack Verdict (module RSP):** PASS for the active route group. `RouteServiceProvider.php` correctly applies `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, `auth`, `verified`. D23 satisfied. `EnsureTenantHasModule` absent (see Layer 4 below).

---

### Layer 2: Controller Quality

**Finding BUG-TTS-002 (P1) — removeCell() Missing class_group_id in Cell Lookup**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:280-283`

```php
$cell = TimetableCell::where('timetable_id', $validated['timetable_id'])
    ->where('day_of_week', $validated['day_of_week'])
    ->where('period_ord', $validated['period_ord'])
    ->first();
```

The unique constraint on `tt_timetable_cells` is `(timetable_id, day_of_week, period_ord, class_group_id, class_subgroup_id)`. A timetable covering multiple class groups has cells from different classes at the same day+period combination. The lookup above has no `class_group_id` filter — `.first()` returns whichever cell MySQL returns first (not necessarily the caller's class), silently deleting the wrong class's placed activity.

**Fix:** Add `->where('class_group_id', $validated['class_group_id'])` to the chain. Also add `class_group_id` to the `removeCell` validation rules (currently absent).

---

**Finding BUG-TTS-003 (P1) — deleteTimetable() Status Guard Incomplete: GENERATED Status Deletable**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:379`

```php
if ($timetable->status === 'PUBLISHED') {
    return response()->json(['success' => false, 'message' => 'Cannot delete a published timetable.'], 422);
}
```

BR-TTS-006 specifies: "Deletion is permitted only for DRAFT manual timetables." The current guard allows deletion of GENERATED (submitted for approval, awaiting Principal sign-off) and ARCHIVED statuses. A Coordinator can delete a timetable that is already in the approval pipeline.

**Fix:** Change the guard to: `if ($timetable->status !== 'DRAFT') { return response()->json([...], 422); }`.

---

**Finding BUG-TTS-004 (P1) — No Published Immutability Check in placeCell() or removeCell()**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:173` (placeCell), `:270` (removeCell)

BR-TTS-004 requires PUBLISHED timetables to be immutable — all placement, removal, and lock calls must be rejected. Neither `placeCell` nor `removeCell` checks `$timetable->status`. A PUBLISHED timetable silently accepts cell mutations.

**Fix:** Add at the start of both methods (after fetching `$timetable`):
```php
if ($timetable->status === 'PUBLISHED') {
    return response()->json(['success' => false, 'message' => 'Published timetables are immutable.'], 422);
}
```

---

**Finding BUG-TTS-005 (P1) — No Break-Period Rejection in placeCell()**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php` (placeCell body)

BR-TTS-014 states break periods must hard-reject placement requests with HTTP 422. `placeCell` does not check `tt_period_type.is_break`. Break/lunch periods silently accept cell placements.

**Fix:** After resolving the period, add:
```php
$periodType = $period->periodType; // via TTF relation
if ($periodType && $periodType->is_break) {
    return response()->json(['success' => false, 'message' => 'Cannot place an activity in a break period.'], 422);
}
```

---

**Finding DAT-TTS-001 (P2) — Non-Transactional Teacher Assignment in placeCell()**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:218-228`

`placeCell()` calls `TimetableCell::updateOrCreate(...)` to create/update the cell record, then in a separate non-transactional `DB::table('tt_timetable_cell_teachers')->insert([...])` to assign teachers. If the teacher insert fails (e.g., duplicate key, constraint violation), the cell record exists without any teacher assignment — orphaned cell with no subject teacher.

**Fix:** Wrap both operations in `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()`, consistent with the `deleteTimetable()` pattern already in the same controller.

---

**Finding PERF-TTS-001 (P2) — N+1 Query in index() Dashboard**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:51-64`

`index()` fetches `$recentTimetables` (up to 5 records) and then calls `TimetableCell::where('timetable_id', $tt->id)->count()` inside a foreach loop — firing 1 additional query per iteration. The `$recentTimetables` collection is already built with a standard query; using `->withCount('cells')` on the original query would collapse this to a single subquery.

**Fix:** Add `->withCount('cells')` to the `$recentTimetables` query builder chain and replace `TimetableCell::where(...)->count()` with `$tt->cells_count` in the loop.

---

### Layer 3: Service Layer

**Finding ARCH-TTS-001 (P1) — Zero Service Layer: All Business Logic in 513-Line Controller**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php` (entire file)

The controller contains: conflict detection (`checkConflicts()` — ~150 lines), cell CRUD with teacher pivot management, statistics aggregation, timetable creation, and deletion. No `ManualTimetableService` or equivalent exists. This violates the platform service-extraction pattern and makes unit testing, reuse, and refactoring prohibitively difficult.

**Fix:** Extract `Modules/StandardTimetable/app/Services/ManualTimetableService.php` containing:
- `placeCell(array $data): array` — cell updateOrCreate + teacher insert + conflict check (in transaction)
- `removeCell(array $data): array` — locked-cell guard + delete
- `checkConflicts(TimetableCell $cell, array $teacherIds, int|null $roomId): array`

The controller becomes thin: validate → delegate to service → return JSON.

---

### Layer 4: Authentication & Authorization

**Finding SEC-TTS-001 (P0) — Blanket viewAny Gate on All 6 Methods Including Destructive Endpoints**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:33, 85, 175, 272, 322, 375`
- **Pattern:** D39 (permissions unreferenced → super-admin only)

Every controller method — index, manualPlacement, placeCell, removeCell, createTimetable, deleteTimetable — begins with:
```php
Gate::authorize('standard-timetable.viewAny');
```

There is no `StandardTimetablePolicy` class. No `Gate::define()` or `Gate::policy()` registration exists in any ServiceProvider. The permission string `standard-timetable.viewAny` is never seeded to `sys_permissions`. Consequence:
- Super-admin: passes silently (Laravel default behavior — super-admin bypasses all gates).
- Any other role: gate resolves against an undefined permission → denies all access (module entirely unusable for non-super-admin).
- A view-only user who is granted `viewAny` will be able to call `deleteTimetable` with the same gate.

**Fix (3 steps):**
1. Create `Modules/StandardTimetable/app/Policies/StandardTimetablePolicy.php` with abilities: `viewAny`, `viewClass`, `viewTeacher`, `viewRoom`, `manualPlace`, `publish`, `export`.
2. Register in `StandardTimetableServiceProvider::registerPolicies()`: `Gate::policy(Timetable::class, StandardTimetablePolicy::class)`.
3. Implement `StandardTimetableDatabaseSeeder` to seed 7 permissions into `sys_permissions`. Replace the blanket gate calls: read methods use `viewAny`, mutating methods use `manualPlace`, publish endpoints use `publish`.

---

**Finding SEC-TTS-002 (P2) — EnsureTenantHasModule Absent from Route Middleware**
- **File:** `Modules/StandardTimetable/app/Providers/RouteServiceProvider.php`
- **Pattern:** SEC-PLATFORM-003 (TTS instance)

The module RSP middleware stack is:
```php
['web', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class,
 EnsureTenantIsActive::class, 'auth', 'verified']
```

`EnsureTenantHasModule` is absent. A school without the StandardTimetable module in their subscription can access all 6 routes.

**Fix:** Add `EnsureTenantHasModule:StandardTimetable` immediately after `EnsureTenantIsActive::class`. Module slug must match the `glb_modules.slug` value registered for this module.

---

### Layer 5: FormRequest Validation

**Finding VAL-TTS-001 (P1) — No FormRequests; Missing class_group_id Validation; IDOR on activity_id**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:177` (placeCell), `:274` (removeCell), `:323` (createTimetable)

All three mutating methods use inline `$request->validate()`. None of the validation rules include `class_group_id` (despite it being required by the unique constraint). Additionally, `placeCell` accepts any `activity_id` without verifying it belongs to the `class_group_id` selected — a user can supply an activity from a different class section.

**Fix:** Create `PlaceCellRequest`, `RemoveCellRequest`, `CreateTimetableRequest`. Add `class_group_id` to `placeCell` and `removeCell` rules. Add `Rule::exists('tt_activities', 'id')->where('class_group_id', $this->class_group_id)` to `placeCell` for `activity_id` ownership validation.

---

### Layer 6: Eloquent Models & ORM

**Finding ORM-TTS-001 (P1) — Timetable::academicSession() Relationship Uses Wrong Database**
- **File:** `Modules/TimetableFoundation/app/Models/Timetable.php` (TTF-owned model; TTS runtime impact)

The `Timetable` model's `academicSession()` relationship resolves to `Modules\Prime\Models\AcademicSession` (global_master_mysql, `glb_academic_sessions`). Any eager-load of this relationship from a tenant context queries the wrong database. This is the model-layer companion to TEN-TTS-001: TTS triggers the write bug; any TTF code that eager-loads `academicSession` in tenant context has the same cross-DB problem.

This finding is logged here because TTS is the only current caller of `AcademicSession::current()` in tenant context. The TTF model must be fixed at the same time as TEN-TTS-001.

**Fix:** Change the `academicSession()` relationship target to `Modules\SchoolSetup\Models\OrganizationAcademicSession`.

---

**Finding ORM-TTS-002 (P3) — uuid Silently Discarded: Not in $fillable, Not in Migration**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:349`

```php
'uuid' => Uuid::uuid4()->getBytes(),
```

`Timetable::$fillable` does not include `uuid`. The `tt_timetables` migration has no `uuid` column. This value is silently discarded by mass-assignment guard. Dead code.

**Fix:** Either add `uuid` to the migration and `$fillable`, or remove the import and the line.

---

### Layer 7: Migrations & DDL

**Finding MIG-TTS-001 (P2) — ENUM Columns in tt_timetables Migration (D29 Systemic)**
- **File:** `database/migrations/tenant/2026_06_16_152627_create_tt_timetable_table.php`

`generation_method` ENUM('FULL_AUTO', 'MANUAL', 'SEMI_AUTO') and `status` ENUM('ARCHIVED', 'DRAFT', 'GENERATED', 'GENERATING', 'PUBLISHED') violate decision D29 (all ENUM values must be managed via `sys_dropdowns`). Baseline: 20 `tt_*` ENUM columns across the tt migrations. Changing ENUM values in production requires `ALTER TABLE` (metadata lock, full table copy on large datasets).

**Fix:** Per D29, replace ENUM with `TINYINT UNSIGNED NOT NULL` + FK → `sys_dropdown_values(id)`. Seed `sys_dropdowns` with `generation_method` and `timetable_status` groups.

---

**Finding MIG-TTS-002 (P2) — ENUM Column in tt_timetable_cells Migration (D29 Systemic)**
- **File:** `database/migrations/tenant/2026_06_16_152645_create_tt_timetable_cell_table.php`

`source` ENUM('AUTO', 'LOCK', 'MANUAL', 'SWAP') — same D29 violation.

---

**Finding MIG-TTS-003 (P2) — Table Name Drift: Migration Creates tt_conflict_detections (Plural) vs DDL tt_conflict_detection (Singular)**
- **File:** `database/migrations/tenant/2026_06_16_152633_create_tt_conflict_detection_table.php`
- **DDL Reference:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated/Timetable_DDL_v7.8.sql`

Migration creates table `tt_conflict_detections` (plural). DDL defines `tt_conflict_detection` (singular). Eloquent models referencing the canonical DDL name will fail at runtime with `Table 'tenant_db.tt_conflict_detection' doesn't exist`.

**Fix:** Create a corrective migration: `Schema::rename('tt_conflict_detections', 'tt_conflict_detection')`. Update TTF model `$table = 'tt_conflict_detection'` to match canonical DDL.

---

**Finding MIG-TTS-004 (P2) — academic_session_id Type Mismatch: DDL=INT UNSIGNED, Migration=unsignedSmallInteger**
- **File:** `database/migrations/tenant/2026_06_16_152627_create_tt_timetable_table.php`

DDL defines `academic_session_id INT UNSIGNED NOT NULL` (4 bytes, up to 4,294,967,295). Migration uses `->unsignedSmallInteger('academic_session_id')` (2 bytes, max 65,535). A school with more than 65,535 academic sessions — implausible in practice but a schema correctness issue — would hit overflow. More critically, a FK from `tt_timetables` (SMALLINT UNSIGNED) to `sch_org_academic_sessions_jnt.id` (INT UNSIGNED) is a column type mismatch that MySQL rejects in strict mode.

**Fix:** Change to `->unsignedInteger('academic_session_id')`.

---

**Finding MIG-TTS-005 (P3) — No Module-Level Migrations: Module database/migrations/ Contains Only .gitkeep**
- **File:** `Modules/StandardTimetable/database/migrations/` (directory)

The module directory contains only a `.gitkeep`. All `tt_*` migrations sit in `database/migrations/tenant/` (root), owned by TimetableFoundation. This is intentional by design (TTS owns no exclusive tables), but it means the module cannot be independently installed or re-migrated. Document this dependency explicitly in the module's README or `module.json`.

---

### Layer 8: Route Architecture

**Finding DEAD-TTS-001 (P1) — Read Views Absent: No class-wise, teacher-wise, or room-wise Routes**
- **File:** `Modules/StandardTimetable/routes/web.php`

REQ-TTS-008 (standard read views) is 0% implemented. No routes, no controller methods, no Blade views exist for `classView`, `teacherView`, or `roomView`. These are the primary consumer-facing outputs of the timetable module — Class Teachers and Subject Teachers have no way to view published timetables.

---

**Finding DEAD-TTS-002 (P1) — Cell Lock/Unlock Endpoints Absent**
- **File:** `Modules/StandardTimetable/routes/web.php`

REQ-TTS-010 (cell locking) is 0% implemented. `lockCell`, `unlockCell`, `lockAll` routes do not exist. The only lock-aware behavior is a guard in `removeCell()` that rejects locked cells — but there is no endpoint to SET a cell as locked. `is_locked` can never be set to 1 via the UI.

---

**Finding DEAD-TTS-003 (P1) — Publishing Workflow Absent**
- **File:** `Modules/StandardTimetable/routes/web.php`

REQ-TTS-011 (publishing workflow) is 0% implemented. No `submitForApproval`, `approve`, or `publish` routes exist. All manual timetables remain in DRAFT status indefinitely and are invisible in read views. The GENERATED → PUBLISHED state transition has no triggering endpoint.

---

**Finding DEAD-TTS-004 (P1) — Copy Timetable Absent**
- **File:** `Modules/StandardTimetable/routes/web.php`

REQ-TTS-002 (copy timetable) is 0% implemented. No `copyTimetable` route, controller method, or service exists. Schools cannot re-use prior-term timetables.

---

**Finding DEAD-TTS-005 (P1) — Conflict Persistence and Batch Validate Absent**
- **File:** `Modules/StandardTimetable/routes/web.php`

REQ-TTS-007 (conflict log persistence to `tt_conflict_detection`) and the batch validate endpoint are 0% implemented. `checkConflicts()` builds conflict arrays per cell placement AJAX call but writes nothing to `tt_conflict_detection`. Conflict history is ephemeral.

---

### Layer 9: Blade Views & Frontend

The 3 views (`index.blade.php`, `manual-placement.blade.php` — 730 lines, `master.blade.php`) were inspected for security issues.

**Verdict:** No unescaped `{!! !!}` output found. CSRF token correctly injected as a PHP-rendered JS constant (`const CSRF_TOKEN = '{{ csrf_token() }}'`). All cell HTML built from JavaScript template literals populated by AJAX JSON responses — no server-side HTML injection vectors found.

**Finding DEAD-TTS-006 (P2) — Drag-and-Drop JS Integration Unconfirmed**
- **File:** `Modules/StandardTimetable/resources/views/pages/manual-placement.blade.php`

FR-TTS-02.5 requires SortableJS or interact.js for drag-and-drop. The 730-line Blade view uses native DOM event listeners (`dragstart`, `dragover`, `drop`) but does not import an external drag-and-drop library via `vite.config.js` or `package.json`. Native HTML5 drag-and-drop may be insufficient for the multi-grid timetable layout (sub-grid rows, activity sidebar). Functional verification required.

---

### Layer 10: Events & Listeners

**Verdict:** `EventServiceProvider.php` exists but contains no registered listeners. No events are dispatched in any controller method. No event-driven side effects to audit. TTS does not use the event system at all — this is consistent with its early development state.

---

### Layer 11: Tests

**Verdict: 0 test files (0/10 on test coverage layer)**

`tests/Feature/` and `tests/Unit/` both contain only `.gitkeep`. There are no automated tests for any of the 6 controller methods. Highest-priority test gaps:
- `ManualPlacementTest` — place/remove cell happy paths and rejection cases
- `ConflictDetectionTest` (unit) — regression for BUG-TTS-001 (wrong column in teacher filter)
- `AuthorizationTest` — 7 permissions × 5 roles matrix
- `TimetableLifecycleTest` — DRAFT-only deletion guard

---

### Layer 12: Code Quality & Conventions

**Finding QUAL-TTS-001 (P3) — activityLog() Calls Absent from All Mutating Methods**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:173-512`

Platform convention requires `activityLog()` on all CRUD mutations. `placeCell`, `removeCell`, `createTimetable`, and `deleteTimetable` write to the database but call no `activityLog()`. The change trail for timetable operations is entirely absent (also noted in the module knowledge file).

**Fix:** Add `activityLog('placed', $cell)`, `activityLog('removed', $cell)`, `activityLog('created', $timetable)`, `activityLog('deleted', $timetable)` inside the success branch of each method. This is separate from the `tt_change_log` table write (REQ-TTS-014), which is a domain-level audit trail.

---

**Finding QUAL-TTS-002 (P2) — createTimetable() Has No try/catch**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:319-367`

`deleteTimetable()` correctly wraps operations in `DB::beginTransaction()` + try/catch. `createTimetable()` has no try/catch at all. An unhandled `QueryException` (e.g., duplicate code race condition, FK violation from TEN-TTS-001) returns a 500 with full stack trace to the browser.

**Fix:** Wrap `Timetable::create(...)` and all subsequent operations in `try { DB::beginTransaction(); ... DB::commit(); } catch (\Exception $e) { DB::rollBack(); return response()->json(['success' => false, 'message' => 'Failed to create timetable.'], 500); }`.

---

**Finding QUAL-TTS-003 (P2) — Cross-TT Conflict Check Has No Academic Term Scope**
- **File:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:431-451`

`checkConflicts()` queries ALL active timetables for the same `day_of_week + period_ord` when checking TEACHER_CROSS_TT and ROOM_CROSS_TT. This includes timetables from prior academic years, generating false-positive cross-timetable conflicts for teachers who taught the same slot last year.

**Fix:** Add a filter to restrict cross-TT checks to timetables within the current academic term: `.whereHas('academicTerm', fn($q) => $q->where('is_current', true))` or filter by `academic_term_id IN (current term IDs)`.

---

## Part B — FRD Gap Analysis (REQ coverage)

**FRD Source:** `TTS_FRD_2026-06-30.md` (14 REQs: P0=5, P1=7, P2=2) + `TTS_FRD_Complete_2026-06-30.md`

### REQ Coverage Matrix

| REQ | Title | Status | Gap Codes |
|-----|-------|--------|-----------|
| REQ-TTS-001 | Manual Timetable Creation | 60% | BUG-TTS-003 (deletion guard), TEN-TTS-001 (session FK), missing copy |
| REQ-TTS-002 | Copy Timetable | 0% | DEAD-TTS-004 |
| REQ-TTS-003 | Period Set Validation | 80% | Minor UI gaps |
| REQ-TTS-004 | Activity Palette | 70% | BUG-TTS-005 (break check); palette counter logic present |
| REQ-TTS-005 | Manual Cell Placement | 55% | BUG-TTS-002 (wrong cell lookup), BUG-TTS-004 (immutability), VAL-TTS-001 (class_group_id missing) |
| REQ-TTS-006 | Manual Cell Removal | 45% | BUG-TTS-002, BUG-TTS-004, DAT-TTS-001 (non-transactional) |
| REQ-TTS-007 | Conflict Detection | 55% | BUG-TTS-001 (teacher column), DEAD-TTS-005 (no persistence), QUAL-TTS-003 (no term scope) |
| REQ-TTS-008 | Standard Read Views | 0% | DEAD-TTS-001 |
| REQ-TTS-009 | Timetable Selector | 30% | Read view selectors not built |
| REQ-TTS-010 | Cell Lock/Unlock | 15% | DEAD-TTS-002 (lock endpoints missing; only removeCell rejects locked cells) |
| REQ-TTS-011 | Publishing Workflow | 0% | DEAD-TTS-003 |
| REQ-TTS-012 | Dashboard Stats | 65% | PERF-TTS-001 (N+1), blanket auth gate |
| REQ-TTS-013 | Authorization & Permissions | 0% | SEC-TTS-001 (entire auth system missing) |
| REQ-TTS-014 | Cell Change Log | 0% | No tt_change_log writes anywhere |

**Overall REQ coverage: ~30% (weighted by P priority)**

---

## Part C — Business Rule Enforcement

| BR | Rule | Enforced? | Finding |
|----|------|-----------|---------|
| BR-TTS-001 | Only MANUAL timetables accept TTS cell operations | Partial | deleteTimetable filters MANUAL; placeCell/removeCell do not verify |
| BR-TTS-002 | Only PUBLISHED timetables in read views | Not enforced | Read views not built |
| BR-TTS-003 | Locked cells reject removeCell (HTTP 422) | YES | Lines 288-291 |
| BR-TTS-004 | PUBLISHED timetable is immutable | Not enforced | BUG-TTS-004 |
| BR-TTS-005 | One PUBLISHED per type+term | Not enforced | Publish not built |
| BR-TTS-006 | Delete only DRAFT manual timetables | Partial | BUG-TTS-003 (GENERATED deletable) |
| BR-TTS-007 | 5 conflict types detected | Partial | BUG-TTS-001 (teacher names wrong) |
| BR-TTS-008 | Conflicts are warnings; break periods hard-reject | Partial | BUG-TTS-005 (no break check) |
| BR-TTS-009 | Every cell mutation writes tt_change_log | Not enforced | QUAL-TTS-001 |
| BR-TTS-010 | Activity palette recalculated after place/remove | YES | placedCount query after each mutation |
| BR-TTS-011 | Copy creates new DRAFT; source unchanged | Not enforced | Feature not built |
| BR-TTS-012 | All data scoped to tenant DB | Partial | TEN-TTS-001 (session FK crosses DB) |
| BR-TTS-013 | Teacher-role user scoped to own teacher_id in teacher view | Not enforced | View not built |
| BR-TTS-014 | Break periods hard-reject placement (HTTP 422) | Not enforced | BUG-TTS-005 |
| BR-TTS-015 | Correct teacher column in conflict filter | Not enforced | BUG-TTS-001 |

**BR coverage: 3/15 full, 3/15 partial, 9/15 missing**

---

## Part G — Pre-Deployment Gate

### Gate Checklist

| Gate Item | Status | Detail |
|-----------|--------|--------|
| P0 issues resolved | FAIL | SEC-TTS-001 + TEN-TTS-001 open |
| Authorization system functional for all target roles | FAIL | No policy, no seeded permissions; super-admin only |
| createTimetable() does not throw FK error | FAIL | TEN-TTS-001: errno 1452 for most tenants |
| Teacher conflict detection returns correct names | FAIL | BUG-TTS-001 unresolved |
| removeCell() deletes correct cell | FAIL | BUG-TTS-002 unresolved |
| EnsureTenantHasModule present | FAIL | SEC-TTS-002 |
| Read views functional (class/teacher/room) | FAIL | 0% built |
| Publishing workflow functional | FAIL | 0% built |
| FormRequests with class_group_id validation | FAIL | VAL-TTS-001 |
| Test coverage >= 1 test | FAIL | 0 tests |
| activityLog() on all mutations | FAIL | QUAL-TTS-001 |
| No unescaped Blade output | PASS | All `{{ }}` verified |
| Tenancy stack correct in RSP | PASS | D23 satisfied |
| CSRF protection on POST/DELETE | PASS | CSRF_TOKEN present in JS |

**Deploy Gate: NO-GO (14 FAIL / 3 PASS)**

---

## Part D — Systemic Pattern Scorecard (scoped to TTS)

| Pattern | TTS Status | Baseline |
|---------|-----------|----------|
| D39: Permissions unreferenced → super-admin only | CONFIRMED (6/6 methods) | 13/13 modules |
| SEC-PLATFORM-003: EnsureTenantHasModule absent | CONFIRMED | 13/13 modules |
| SEC-PLATFORM-007: Cross-layer AcademicSession import | CONFIRMED (new FK violation variant) | SLK + TTS confirmed |
| D30: FormRequest authorize() true | N/A (no FormRequests exist) | 90% platform |
| D29: ENUM columns in migrations | CONFIRMED (3 migrations, 6 ENUM usages) | ~476 platform |
| D25: $request->all() mass-assign | NOT FOUND | 24 platform |
| D17: $fillable lists non-existent column | CONFIRMED (uuid in controller, not in $fillable or migration) | 66 models platform |
| D36: Generated columns degraded | NOT FOUND in TTS scope (present in TTF-owned migrations) | Scoped to TTF/STT |
| Zero test coverage | CONFIRMED | Most tenant modules |

---

## Health Score

| Layer | Weight | Raw Score | Weighted |
|-------|--------|-----------|----------|
| Tenancy Isolation | 15% | 45 | 6.75 |
| Authorization / Policy | 20% | 0 | 0.00 |
| FormRequest Validation | 10% | 0 | 0.00 |
| Service Layer | 5% | 0 | 0.00 |
| Eloquent / ORM | 10% | 55 | 5.50 |
| Migrations / DDL | 10% | 50 | 5.00 |
| Routes | 5% | 40 | 2.00 |
| Controller Quality | 10% | 35 | 3.50 |
| Views / Blade | 5% | 70 | 3.50 |
| Events / Listeners | 5% | 50 | 2.50 |
| Tests | 5% | 0 | 0.00 |
| Code Quality | 5% | 40 | 2.00 |
| **Raw Total** | | | **30.75** |
| **P0 hard cap (ceiling 40)** | | | **cap applied** |
| **Final Health Score** | | | **30 / 100** |

> P0 cap applied: SEC-TTS-001 (auth system entirely non-functional) + TEN-TTS-001 (createTimetable FK violation) are both P0. Platform rule: any confirmed P0 caps the score at 40. Raw score 30.75 is below the cap, so the final score is **30/100**.

---

## Consolidated Finding Register

### P0 — Critical (Blockers: deploy gate FAIL)

| Code | Title | File | Line(s) | Severity |
|------|-------|------|---------|----------|
| SEC-TTS-001 | Blanket `viewAny` gate on ALL 6 methods; no policy; no permissions seeded | StandardTimetableController.php | 33, 85, 175, 272, 322, 375 | P0 |
| TEN-TTS-001 | `AcademicSession` (global_master_mysql) ID stored in `tt_timetables.academic_session_id` FK (tenant_db) → errno 1452 on createTimetable | StandardTimetableController.php | 13, 346 | P0 |

### P1 — High (Must Fix Before User-Facing Rollout)

| Code | Title | File | Line(s) |
|------|-------|------|---------|
| BUG-TTS-001 | `->whereIn('id', $teacherIds)` should be `->whereIn('teacher_id', $teacherIds)` — teacher conflict detection silent failure | StandardTimetableController.php | 420, 442 |
| BUG-TTS-002 | `removeCell()` missing `class_group_id` in cell lookup — wrong cell may be deleted in multi-class timetables | StandardTimetableController.php | 280-283 |
| BUG-TTS-003 | `deleteTimetable()` only blocks PUBLISHED; GENERATED status deletable — BR-TTS-006 violation | StandardTimetableController.php | 379 |
| BUG-TTS-004 | No published immutability check in `placeCell()` / `removeCell()` — BR-TTS-004 not enforced | StandardTimetableController.php | 173, 270 |
| BUG-TTS-005 | No break-period rejection in `placeCell()` — BR-TTS-014 not enforced | StandardTimetableController.php | placeCell body |
| ORM-TTS-001 | `Timetable::academicSession()` relation targets wrong DB (global_master_mysql) | TimetableFoundation/Models/Timetable.php | academicSession() |
| VAL-TTS-001 | No FormRequests; `class_group_id` absent from removeCell/placeCell validation; activity_id ownership not checked | StandardTimetableController.php | 177, 274, 323 |
| ARCH-TTS-001 | Zero service layer — 513-line controller holds all business logic | StandardTimetableController.php | (entire) |
| DEAD-TTS-001 | Read views (class-wise, teacher-wise, room-wise) — 0% built | routes/web.php | — |
| DEAD-TTS-002 | Cell lock/unlock endpoints — 0% built; `is_locked` can never be set to 1 via UI | routes/web.php | — |
| DEAD-TTS-003 | Publishing workflow (submit/approve/publish) — 0% built; all timetables stay DRAFT forever | routes/web.php | — |
| DEAD-TTS-004 | Copy timetable — 0% built | routes/web.php | — |
| DEAD-TTS-005 | Conflict persistence to `tt_conflict_detection` + batch validate — 0% built | StandardTimetableController.php | checkConflicts() |

### P2 — Medium

| Code | Title | File | Line(s) |
|------|-------|------|---------|
| SEC-TTS-002 | `EnsureTenantHasModule` absent from RSP middleware | RouteServiceProvider.php | boot() |
| MIG-TTS-001 | ENUM `generation_method` + `status` in tt_timetables migration (D29) | 2026_06_16_152627_create_tt_timetable_table.php | enum lines |
| MIG-TTS-002 | ENUM `source` in tt_timetable_cells migration (D29) | 2026_06_16_152645_create_tt_timetable_cell_table.php | enum line |
| MIG-TTS-003 | Table name drift: migration creates `tt_conflict_detections`, DDL defines `tt_conflict_detection` | 2026_06_16_152633_create_tt_conflict_detection_table.php | Schema::create |
| MIG-TTS-004 | `academic_session_id` type: DDL=INT UNSIGNED, migration=unsignedSmallInteger | 2026_06_16_152627_create_tt_timetable_table.php | column definition |
| DAT-TTS-001 | Non-transactional teacher assignment in `placeCell()` — orphaned cell if insert fails | StandardTimetableController.php | 218-228 |
| QUAL-TTS-002 | `createTimetable()` has no try/catch — unhandled exceptions return stack trace | StandardTimetableController.php | 319-367 |
| QUAL-TTS-003 | Cross-TT conflict check has no academic term scope — false positives from prior years | StandardTimetableController.php | 431-451 |
| PERF-TTS-001 | N+1 query in `index()` dashboard — TimetableCell count queried in foreach | StandardTimetableController.php | 51-64 |
| DEAD-TTS-006 | Drag-and-drop JS library integration unconfirmed — FR-TTS-02.5 may not be functional | manual-placement.blade.php | — |

### P3 — Low / Backlog

| Code | Title |
|------|-------|
| ORM-TTS-002 | `uuid` silently discarded — not in $fillable, not in migration |
| TEN-TTS-002 | Dead empty route group in `tenant.php` (lines 229-231) — lacks tenancy middleware |
| QUAL-TTS-001 | `activityLog()` absent from all 4 mutating methods |
| TEST-TTS-001 | Zero test coverage — 0 Feature tests, 0 Unit tests |
| DEAD-TTS-007 | `tt_change_log` writes absent from all cell mutations — REQ-TTS-014 not started |

---

## Priority Fix Order (Minimal Path to Production)

**Sprint 0 — P0 gate unblocking (8-12 hours)**
1. Fix TEN-TTS-001: replace `AcademicSession` import with `OrganizationAcademicSession` at controller line 13 and model relation in Timetable.php
2. Fix SEC-TTS-001: create `StandardTimetablePolicy` with 7 abilities; register in ServiceProvider; implement seeder; replace blanket gate calls
3. Fix BUG-TTS-001: change `->whereIn('id', $teacherIds)` to `->whereIn('teacher_id', $teacherIds)` at lines 420, 442
4. Fix BUG-TTS-002: add `->where('class_group_id', $validated['class_group_id'])` to removeCell cell lookup at line 283
5. Add `EnsureTenantHasModule:StandardTimetable` to RSP middleware (SEC-TTS-002)
6. Wrap createTimetable() in try/catch with DB transaction (QUAL-TTS-002)

**Sprint 1 — Business rule enforcement (15-20 hours)**
7. Fix BUG-TTS-003: change deleteTimetable guard to `!== 'DRAFT'`
8. Fix BUG-TTS-004: add PUBLISHED immutability guard to placeCell and removeCell
9. Fix BUG-TTS-005: add break-period check to placeCell
10. Fix QUAL-TTS-003: scope cross-TT conflict check to current academic term
11. Fix DAT-TTS-001: wrap cell + teacher insert in DB::transaction in placeCell
12. Create `PlaceCellRequest`, `RemoveCellRequest`, `CreateTimetableRequest` with class_group_id validation
13. Extract `ManualTimetableService`; add activityLog() calls

**Sprint 2 — Read views and locking (25-35 hours)**
14. Build class-wise, teacher-wise, room-wise read views (DEAD-TTS-001)
15. Build cell lock/unlock/lockAll endpoints (DEAD-TTS-002)
16. Build conflict persistence to tt_conflict_detection (DEAD-TTS-005)

**Sprint 3 — Publishing, copy, tests (20-30 hours)**
17. Build publishing workflow: submit → GENERATED → approve → PUBLISHED (DEAD-TTS-003)
18. Build copy timetable endpoint in DB transaction (DEAD-TTS-004)
19. Write ManualPlacementTest, ConflictDetectionTest, AuthorizationTest, TimetableLifecycleTest

---

## Appendix: False-Positive / Refuted Findings

**None.** All P0 and P1 findings were verified against live code in `Modules/StandardTimetable/` and the root migration files in `database/migrations/tenant/`. No BA FRD annotations were refuted.

---

## Cross-References

- **FRD:** `TTS_FRD_2026-06-30.md` | `TTS_FRD_Complete_2026-06-30.md`
- **Module Knowledge:** `AI_Brain/module-knowledge/STA_StandardTimetable.md`
- **Related Audits:** `TimetableFoundation_Complete_Audit_2026-06-30.md` (TTF P0s include 19 dead policies and API tenancy gap; TTS depends on TTF fixes first)
- **Platform Patterns:** `AI_Brain/lessons/known-issues.md` (SEC-PLATFORM-003, SEC-PLATFORM-007)
- **Decisions:** `AI_Brain/state/decisions.md` (D29, D30, D36, D39)
