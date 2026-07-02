# Module Knowledge — TTS: StandardTimetable (Manual)
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

> **Filename note:** This file is named `STA_StandardTimetable.md` per the seeding task spec.
> The canonical module code per the V2 requirement file (`TTS_StandardTimetable_Requirement.md`) is **TTS**.
> All gap IDs in this file use the prefix `STA` for consistency with the filename.

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | StandardTimetable (also referred to as "Manual Timetable") |
| Module Code | **TTS** (per V2 requirement doc) / file prefix STA (see note above) |
| Table Prefix | `tt_*` (shared — StandardTimetable owns NO exclusive tables; shares namespace with TTF and STT) |
| Laravel Module Path | `Modules/StandardTimetable/` |
| Namespace | `Modules\StandardTimetable` |
| DB Layer | **Tenant** — `tenant_mysql` (no `tenant_id` column; isolated by DB connection) |
| Domain Scope | Tenant — Timetable Coordinator, School Admin, Principal, Class Teacher, Subject Teacher |
| V2 Requirement | `TTS_StandardTimetable_Requirement.md` (2026-03-26); V2 estimated ~15-20% complete |
| V1 Screen Specs | 2 files in `StandardTimetable_V2/` |
| RBS Reference | Shared timetable domain (Module code TTS) |
| TTF Dependency | Hard — consumes all TimetableFoundation models; TTF must be configured before TTS is functional |
| STT Dependency | Soft — AnalyticsService and `_grid` partial for read views (not yet built) |

### Verified File Counts (from `find Modules/StandardTimetable -type f` — 2026-06-30)

| Component | Actual | V2 Said | Delta / Notes |
|-----------|--------|---------|---------------|
| Controllers | 1 | 1 | `StandardTimetableController.php` — **513 lines** (V2 said 442), **6 public methods** (V2 said 5; missed `index`) |
| Models | 0 | 0 | Confirmed — uses TimetableFoundation models directly |
| FormRequests | 0 | 0 | 3 methods use inline `$request->validate()` — FormRequests needed but absent |
| Policies | 0 | 0 | No policy class; not registered in AppServiceProvider |
| Services | 0 | 0 | Zero service layer; all logic in controller |
| Tests | 0 | 0 | Feature/ and Unit/ both empty (`.gitkeep` only) |
| Seeders | 1 | 1 | `StandardTimetableDatabaseSeeder.php` — **empty scaffold** (no actual seeding) |
| Views | 3 | 3 | `master.blade.php`, `index.blade.php`, `manual-placement.blade.php` — **730 lines** (V2 said 667) |
| Routes (web.php) | 6 | 5 | V2 missed `GET /` → `index`; confirmed 6 active routes |
| Routes (tenant.php) | 0 active | 0 | Empty route group in `tenant.php` is dead code |

---

## Module Score Summary

| Area | Score | Key Issue |
|------|-------|-----------|
| DB Integrity | N/A | No exclusive tables; reads/writes to shared `tt_*` via TTF |
| Route Integrity | 4/10 | Routes work via module `web.php`; `EnsureTenantHasModule` missing; empty dead group in `tenant.php` |
| Controller Quality | 4/10 | Correct base class; but blanket `viewAny` gate on ALL methods; no granular auth |
| Model Quality | N/A | No own models; TTF models used |
| Service Layer | **0/10** | Zero services — all business logic (conflict detection, cell CRUD, teacher assignment) in controller |
| FormRequest Coverage | **0/10** | Zero FormRequests; 3 of 6 methods use inline `validate()` |
| Policy / Auth | **0/10** | No policy; single blanket `standard-timetable.viewAny` on all 6 methods including destructive AJAX |
| Test Coverage | **0/10** | Zero tests |
| Security | 3/10 | No `EnsureTenantHasModule`; single-permission-for-all-actions; no granular role scoping |
| Conflict Detection | 5/10 | 5 conflict types implemented; BUG on teacher name lookup; no persistence; no batch validate |
| **Overall** | **~15%** | Read views, publishing, copy, authorization, tests all unbuilt |

---

## DDL Table Inventory

### CRITICAL: Table Ownership in the `tt_*` Namespace

StandardTimetable (TTS) **introduces zero new database tables**. It reads from and writes to shared `tt_*`
tables owned by TimetableFoundation (TTF) and SmartTimetable (STT). DDL Section 7
("TIMETABLE MANUAL MODIFICATION") in `tenant_db_v2.sql` is explicitly marked `-- PENDING`.

### Tables Written by TTS (shared with TTF/STT)

| Table | Owner Module | TTS Access | TTS Discriminator | Migration File |
|-------|-------------|-----------|------------------|----------------|
| `tt_timetables` | TTF/STT | R/W | `generation_method = 'MANUAL'` | `2026_06_16_152627_create_tt_timetable_table.php` |
| `tt_timetable_cells` | TTF/STT | R/W | `source = 'MANUAL'` | `2026_06_16_152645_create_tt_timetable_cell_table.php` |
| `tt_timetable_cell_teachers` | TTF/STT | R/W | — (junction table) | `2026_06_16_152648_create_tt_timetable_cell_teacher_table.php` |
| `tt_conflict_detection` | TTF | W (planned) | `detection_type = 'REAL_TIME'` | TTF migration |
| `tt_change_log` | TTF | W (planned) | `change_type = 'CREATE'/'DELETE'/'LOCK'` | TTF migration |

> TTS does NOT own any `tt_*` migrations. All timetable migrations belong to TTF.

### Tables Read-Only by TTS (owned by TTF)

| Table | Purpose |
|-------|---------|
| `tt_activities` | Activity palette — subject, weekly periods, class/section |
| `tt_activity_teachers` | Teacher assignments per activity |
| `tt_period_sets` | Period structure for grid columns |
| `tt_period_set_period_jnt` | Period ordinals, start/end times, period_type |
| `tt_period_types` | Color codes, `is_break` flag |
| `tt_school_days` | Day names, ordinals for grid rows |
| `tt_timetable_types` | Timetable type selector options |
| `tt_timetable_type_jnt` (ClassTimetableType) | Period set lookup per type+term |
| `tt_academic_terms` | Term selector |
| `tt_teacher_workload` | Teacher-wise view analytics (via STT AnalyticsService) |
| `tt_resource_bookings` | Room-wise view analytics (via STT AnalyticsService) |
| `tt_constraint_violations` | Violations panel in Validate All (planned) |
| `tt_generation_runs` | Informational stats header (N/A for MANUAL) |

### Tables Read-Only by TTS (owned by SchoolSetup/Prime)

| Table | Source Module | Purpose |
|-------|--------------|---------|
| `sch_class_sections` | SchoolSetup | ClassSection model for selector |
| `sch_rooms` | SchoolSetup | Room picker |
| `sch_org_academic_sessions_jnt` | Prime/SchoolSetup | Current academic session lookup |

### Key Column References — TTS Discriminators

#### `tt_timetables` — TTS writes with these discriminators
| Column | Type | TTS Value |
|--------|------|-----------|
| `generation_method` | ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') | Always `'MANUAL'` |
| `status` | ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') | Starts `'DRAFT'`; lifecycle to `'PUBLISHED'` (workflow not yet built) |
| `code` | VARCHAR | Auto-generated: `MT_YYYYMMDD_HHiiss_XXXX` |

#### `tt_timetable_cells` — TTS writes with these discriminators
| Column | Type | TTS Value |
|--------|------|-----------|
| `source` | ENUM('AUTO','MANUAL','SWAP','LOCK') | Always `'MANUAL'` |
| `is_locked` | TINYINT(1) | 0 on placement; 1 after lock (lock endpoint not yet built) |
| `has_conflict` | TINYINT(1) | Set from `checkConflicts()` result |
| `conflict_details_json` | JSON | Conflict array persisted on cell; `tt_conflict_detection` persistence NOT implemented |
| `is_active` | TINYINT(1) | Set to 1 on creation |

---

## Known Gaps & Open Issues

### P0 — Critical (Security / Production Blockers)

| ID | Issue | Location | Fix |
|----|-------|---------|-----|
| SEC-STA-01 | **`EnsureTenantHasModule` middleware absent from ALL StandardTimetable routes** — any authenticated user of any tenant can access timetable builder regardless of license | `Modules/StandardTimetable/routes/web.php` (RouteServiceProvider) | Add `EnsureTenantHasModule:StandardTimetable` to the route group middleware stack in `StandardTimetableServiceProvider` or `RouteServiceProvider` |
| GAP-STA-02 | **All 6 controller methods — including destructive AJAX — use a single blanket gate `standard-timetable.viewAny`**. Read and write actions are undifferentiated: `index`, `manualPlacement`, `placeCell`, `removeCell`, `createTimetable`, `deleteTimetable` all require the same `viewAny` check. A view-only user can delete timetables. | `StandardTimetableController.php` — all methods | Create `StandardTimetablePolicy` with granular abilities (`viewAny`, `manualPlace`, `publish`); register in `AppServiceProvider`; replace blanket `viewAny` gate in each method with the correct ability |
| GAP-STA-03 | **No `StandardTimetablePolicy` class exists and none is registered in `AppServiceProvider`** — the permission string `standard-timetable.viewAny` used in the controller is not backed by any Policy or Gate::define() call. Auth checks will silently pass for super-admin but are unenforceable for lower roles. | `app/Providers/AppServiceProvider.php` | Create `Modules/StandardTimetable/app/Policies/StandardTimetablePolicy.php`; register in `AppServiceProvider` |
| GAP-STA-04 | **Permission `standard-timetable.viewAny` is not seeded** — `StandardTimetableDatabaseSeeder::run()` is an empty scaffold (single commented-out line). No permissions, no roles, no module entry are seeded. If seeder is run, the module is unusable for non-super-admin roles. | `Modules/StandardTimetable/database/seeders/StandardTimetableDatabaseSeeder.php` | Implement the seeder: insert 7 permissions per V2 FR-TTS-10.1 into `sys_permissions` |
| GAP-STA-05 | **Zero `activityLog()` calls in any mutating method** — `placeCell`, `removeCell`, `createTimetable`, `deleteTimetable` all mutate the database but call no `activityLog()`. Platform standard requires `activityLog()` on all CRUD mutations. | `StandardTimetableController.php` lines 173–512 | Add `activityLog('created'/'deleted', ...)` inside each mutating method |

### P1 — High

| ID | Issue | Location | Fix |
|----|-------|---------|-----|
| BUG-STA-06 | **`checkConflicts()` uses wrong column for conflict teacher name lookup** — `$cell->teachers->whereIn('id', $teacherIds)` (lines 420, 442) compares the relation's PK (`id`) against `$teacherIds` which contains `teacher_id` FK values. Conflict teacher names displayed in the JSON response will be incorrect (wrong teacher cited, or empty). This is the V2-documented `BUG-TTS-001`. | `StandardTimetableController.php` lines 420 and 442 | Change both occurrences to `->whereIn('teacher_id', $teacherIds)` |
| ARCH-STA-07 | **Zero service layer** — 513-line controller contains all business logic: conflict detection (`checkConflicts()`), cell CRUD, teacher assignment, statistics aggregation. V2 recommends extracting `ManualTimetableService` (conflict detection + cell operations) and `StandardTimetableViewController` (read views). | `StandardTimetableController.php` | Create `Modules/StandardTimetable/app/Services/ManualTimetableService.php`; move `checkConflicts()` + cell/teacher CRUD logic; split view methods into `StandardTimetableViewController` |
| GAP-STA-08 | **Inline `$request->validate()` in 3 methods** (`placeCell` line 177, `removeCell` line 274, `createTimetable` line 323) — no FormRequest classes for authorization pre-check (e.g., "is timetable MANUAL and not PUBLISHED?") or reusable validation rules | `StandardTimetableController.php` | Create `PlaceCellRequest`, `RemoveCellRequest`, `CreateTimetableRequest` with authorization() + rules() |
| BUG-STA-09 | **`createTimetable()` has no try/catch** — unhandled DB exceptions (e.g., duplicate code, FK failure) produce a 500 response with stack trace. V2 FR-TTS-10 notes this explicitly. `deleteTimetable()` correctly uses a transaction+catch; `createTimetable()` does not. | `StandardTimetableController.php` line 319–367 | Wrap `Timetable::create(...)` and subsequent operations in `try/catch` block; return `response()->json(['success'=>false, 'message'=>...], 500)` on failure |
| GAP-STA-10 | **Dead empty route group in `tenant.php`** — Lines 229-231 of `tenant.php` define an empty `middleware(['auth','verified'])->prefix('standard-timetable')` group. This is dead code (actual routes served via `web.php`). Causes confusion during maintenance and may mask future route conflicts. | `routes/tenant.php` lines 229-231 | Remove the empty group; add a comment: `// StandardTimetable routes → Modules/StandardTimetable/routes/web.php` |
| GAP-STA-11 | **Cross-timetable conflict check has no academic term scope** — `checkConflicts()` lines 431-451 query ALL active timetables across ALL academic years for the same `day_of_week` + `period_ord`. Timetables from last year's terms will produce false-positive `TEACHER_CROSS_TT` and `ROOM_CROSS_TT` conflicts. | `StandardTimetableController.php` lines 431-451 | Add `.whereHas('academicTerm', fn($q) => $q->where('is_current', true))` or filter by the current academic session's term IDs |
| GAP-STA-12 | **`deleteTimetable()` deletion guard is incomplete** — The method filters for MANUAL timetables (`generation_method = 'MANUAL'`) but the status guard only blocks PUBLISHED (line 379). GENERATED timetables (submitted for approval, awaiting Principal sign-off) can be deleted. V2 BR-TTS-006 says only DRAFT timetables may be deleted. | `StandardTimetableController.php` line 379 | Change guard to: `if (!in_array($timetable->status, ['DRAFT']))` |

### P2 — Medium

| ID | Issue | Location |
|----|-------|---------|
| GAP-STA-13 | **Standard read views (class-wise, teacher-wise, room-wise) — 0% complete** — FR-TTS-04 not started; no routes, no controller methods, no Blade views. These are the primary consumer-facing output of the timetable system. | All |
| GAP-STA-14 | **Publishing workflow — 0% complete** — FR-TTS-07 not started: no Submit for Approval, no Approve, no Publish endpoint. All manual timetables remain in DRAFT indefinitely and never appear in read views. | All |
| GAP-STA-15 | **Copy timetable — 0% complete** — FR-TTS-08 not started; no route, no method. School reuse of prior-term timetables is blocked. | All |
| GAP-STA-16 | **Cell lock/unlock endpoints missing** — FR-TTS-06.2-06.5 not started: `lockCell`, `unlockCell`, `lockAll` endpoints absent. Only `removeCell` respects `is_locked`; there is no way to set `is_locked = 1` via the UI. | Routes + Controller |
| GAP-STA-17 | **Context menu for placed cells (FR-TTS-02.10, 02.11) — 0% complete** — No right-click context menu; no room-change picker on placed cells. | Frontend |
| GAP-STA-18 | **Conflict persistence to `tt_conflict_detection` not implemented** — `checkConflicts()` builds and returns conflict arrays but writes nothing to `tt_conflict_detection`. Conflict history is lost after AJAX response; conflict badge count is always stale. | `StandardTimetableController.php` `checkConflicts()` |
| GAP-STA-19 | **Break-period placement rejection (BR-TTS-014) not enforced** — `placeCell` does not check `tt_period_type.is_break`. Break periods accept cell placements silently. | `placeCell()` |
| GAP-STA-20 | **`$activity->weekly_periods` fallback ambiguity** — Line 235 tries `required_weekly_periods` then falls back to `weekly_periods`. If neither column exists on the Activity model (e.g., schema change), `$weeklyNeeded` silently becomes 0, breaking palette counters. | `placeCell()` line 235 |
| GAP-STA-21 | **Drag-and-drop JavaScript library not integrated** — `manual-placement.blade.php` is 730 lines of Blade scaffold but drag-and-drop (FR-TTS-02.5) requires SortableJS or interact.js. Current UI may use simulated click-based placement. | `resources/views/pages/manual-placement.blade.php` |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-STA-22 | Zero test coverage — highest priority: ManualPlacementTest (place/remove/conflict), AuthorizationTest (7 permissions), ConflictDetectionTest (unit — BUG-STA-06 regression) |
| GAP-STA-23 | Change log (`tt_change_log` writes) — all cell mutations bypass audit trail; FR-TTS-11 not started |
| GAP-STA-24 | Print and export (FR-TTS-09) — print CSS, CSV export, PDF export (DomPDF) — not started |
| GAP-STA-25 | Activity palette visual completion marker (FR-TTS-02.14) — activities with `remaining <= 0` not visually marked as done |
| GAP-STA-26 | Fully-placed activities should be greyed/checked in palette (FR-TTS-02.14) — AJAX response returns `is_fully_placed` flag but frontend rendering not confirmed |
| GAP-STA-27 | Conflict summary badge on page header (FR-TTS-03.7) — count not maintained |
| GAP-STA-28 | "Validate All" batch scan (FR-TTS-03.8) — not started |

---

## Feature Area Status (as of 2026-06-30)

| # | Feature | FR | Status | Notes |
|---|--------|----|--------|-------|
| 1 | Dashboard Overview | — | 🟡 60% | Stats page and menu cards work; blanket `viewAny` gate; no per-feature auth |
| 2 | Manual Timetable Creation | FR-TTS-01 | 🟡 60% | 01.1-01.3, 01.7 done; copy (01.4), effective dates (01.5), one-published rule (01.6) missing |
| 3 | Drag-and-Drop Grid Editor | FR-TTS-02 | 🟡 45% | 730-line Blade scaffold; placeCell/removeCell AJAX done; drag-drop JS not confirmed integrated; context menu missing; break-period check missing |
| 4 | Conflict Detection | FR-TTS-03 | 🟡 55% | 5 conflict types implemented (03.1-03.5); has BUG-STA-06 (wrong column); no persistence (03.6); no conflict badge (03.7); no Validate All (03.8) |
| 5 | Standard Read Views | FR-TTS-04 | ❌ 0% | class-view, teacher-view, room-view — not started |
| 6 | Timetable Selector | FR-TTS-05 | 🟡 30% | Manual placement page selector done (05.1); read view selectors (05.2-05.4) not started |
| 7 | Cell Lock and Freeze | FR-TTS-06 | 🟡 15% | `removeCell` rejects locked cells (06.1 done); lock/unlock/lockAll endpoints all missing (06.2-06.5) |
| 8 | Publishing Workflow | FR-TTS-07 | ❌ 0% | Submit for Approval, Approve, Publish — not started |
| 9 | Copy Timetable | FR-TTS-08 | ❌ 0% | Not started |
| 10 | Print and Export | FR-TTS-09 | ❌ 0% | Not started |
| 11 | Authorization & Permissions | FR-TTS-10 | ❌ 0% | No policy class; no seeded permissions; blanket `viewAny` on all methods |
| 12 | Change Log | FR-TTS-11 | ❌ 0% | Not started; `tt_change_log` writes never called |
| 13 | EnsureTenantHasModule | — | ❌ 0% | Not applied to any route |
| 14 | Service Layer | — | ❌ 0% | Zero services; ManualTimetableService needed |
| 15 | FormRequest Classes | — | ❌ 0% | Zero FormRequests; 3 methods use inline validate() |
| 16 | activityLog() | — | ❌ 0% | Not called in any of the 4 mutating methods |
| 17 | Test Coverage | — | ❌ 0/10 | Zero tests |

---

## Timetable Grid / Conflict Detection Architecture

### Current Implementation (in `StandardTimetableController::checkConflicts()`)

On every `placeCell` AJAX call, 5 conflict checks run in sequence:

| Check | Type | Query Scope | Result Key |
|-------|------|------------|------------|
| Teacher in same timetable | TEACHER_CONFLICT | `timetable_id` + `day_of_week` + `period_ord` + `whereHas('teachers', whereIn teacher_id)` | Warnings only |
| Teacher in other active timetables | TEACHER_CROSS_TT | All active timetables (no term scope — see GAP-STA-11) | Warnings only |
| Room in same timetable | ROOM_CONFLICT | `timetable_id` + slot + `room_id` | Warnings only |
| Room in other active timetables | ROOM_CROSS_TT | All active timetables + same slot + `room_id` | Warnings only |
| Class double-booking | CLASS_DOUBLE_BOOKING | `timetable_id` + slot + `class_group_id` + different `activity_id` | Warning; cell is REPLACED via `updateOrCreate` |

**Conflict result:** All conflicts are warnings (placement proceeds). The AJAX response includes `has_conflict: true` and `conflicts[]` array. The cell stores `has_conflict` and `conflict_details_json`. **Conflicts are NOT written to `tt_conflict_detection`** (GAP-STA-18).

**Known bug (BUG-STA-06):** Lines 420 and 442 use `$cell->teachers->whereIn('id', $teacherIds)`. The `teachers` relation contains `TimetableCellTeacher` pivot records; the column holding the FK is `teacher_id`, not `id`. This means `$conflictTeachers` collection is always empty when `id` != `teacher_id`, and conflict messages report wrong or missing teacher names. The `whereHas` query (correct: uses `teacher_id`) correctly identifies the conflicting cell; the post-load filter (wrong: uses `id`) fails to extract the teacher name.

### AJAX Response Envelope (established pattern)
```json
{
  "success": true,
  "cell_id": 123,
  "has_conflict": false,
  "conflicts": [],
  "activity": {
    "id": 45,
    "subject": "Mathematics",
    "format": "Lecture",
    "teachers": [{"name": "A. Kumar", "is_primary": true}],
    "weekly_needed": 5,
    "placed_count": 2,
    "remaining": 3,
    "is_fully_placed": false
  },
  "message": "Activity placed successfully."
}
```
All new AJAX endpoints must follow this envelope. Errors: `"success": false` + HTTP 422 (validation) or 500 (server).

### updateOrCreate Key
```php
TimetableCell::updateOrCreate(
    ['timetable_id', 'day_of_week', 'period_ord', 'class_group_id'],   // match
    [...data fields including 'source' => 'MANUAL']                      // fill
)
```
If a cell exists at the same slot for the same class group, it is **replaced** (not blocked). This is the CLASS_DOUBLE_BOOKING warning case.

---

## Permission Architecture

### Required Permissions (per V2 FR-TTS-10.1 — NONE SEEDED AS OF 2026-06-30)

| Permission String | Role Access | Current State |
|------------------|-------------|---------------|
| `standard-timetable.viewAny` | Admin, Coordinator, Principal | Used in code (blanket) but NOT seeded |
| `standard-timetable.viewClass` | Admin, Coordinator, Principal, Class Teacher (own class) | Not seeded |
| `standard-timetable.viewTeacher` | Admin, Coordinator, Principal, Teacher (own schedule) | Not seeded |
| `standard-timetable.viewRoom` | Admin, Coordinator, Principal | Not seeded |
| `standard-timetable.manualPlace` | Admin, Coordinator | Not seeded; NOT guarded separately (uses viewAny) |
| `standard-timetable.publish` | Admin, Principal | Not seeded; NOT guarded (endpoint not built) |
| `standard-timetable.export` | Admin, Coordinator, Principal | Not seeded; NOT guarded (endpoint not built) |

### Policy (Not Yet Created)
Target file: `Modules/StandardTimetable/app/Policies/StandardTimetablePolicy.php`
Register in: `app/Providers/AppServiceProvider.php`

### Role-Based Access Target

| Role | Access Level |
|------|-------------|
| School Admin | Full — all create/edit/place/publish/delete |
| Timetable Coordinator | Full — create, place cells, publish |
| Principal | Read-only — all views; can approve/publish |
| Class Teacher | Class-wise view (own class-section only) |
| Subject Teacher | Teacher-wise view (own teacher_id only) |
| Student / Parent | Future — class-wise read-only via portal |

> Cross-tenant access is impossible via stancl/tenancy DB isolation per platform standard.

---

## Cross-Module Dependencies

### TTS Consumes From

| Source Module | Code | Data / Entity | Import Type | Notes |
|--------------|------|--------------|-------------|-------|
| TimetableFoundation | TTF | `Activity`, `AcademicTerm`, `ClassTimetableType`, `PeriodSet`, `SchoolDay`, `Timetable`, `TimetableCell`, `TimetableType` | Hard compile-time import | All 8 models imported directly in controller header |
| SchoolSetup | SCH | `ClassSection`, `Room` | Hard compile-time | Imported in controller |
| Prime | PRM | `AcademicSession` | Hard compile-time | `AcademicSession::current()->first()` in `createTimetable()` |
| SmartTimetable | STT | `AnalyticsService::getClassReport/getTeacherReport/getRoomReport()`, `smarttimetable::analytics/reports/_grid` partial | Soft (not yet used — read views not built) | Will be required when FR-TTS-04 is implemented |
| Notification | NTF | Approval notification to Principal | Soft (not yet used — publishing not built) | Required for FR-TTS-07.2 |

### TTS Provides To

| Consumer | Data / Mechanism | Notes |
|----------|-----------------|-------|
| SmartTimetable | MANUAL `tt_timetable` rows visible in shared selector | STT analytics dashboard may include MANUAL timetables in its selectors |
| StudentPortal (future) | Class-wise timetable read view via portal | FR-TTS-04.1 scoped to published timetables |

### Hard Import Statements in Controller (runtime coupling risk)
```php
use Modules\Prime\Models\AcademicSession;
use Modules\SchoolSetup\Models\ClassSection;
use Modules\SchoolSetup\Models\Room;
use Modules\TimetableFoundation\Models\Activity;
use Modules\TimetableFoundation\Models\AcademicTerm;
use Modules\TimetableFoundation\Models\ClassTimetableType;
use Modules\TimetableFoundation\Models\PeriodSet;
use Modules\TimetableFoundation\Models\SchoolDay;
use Modules\TimetableFoundation\Models\Timetable;
use Modules\TimetableFoundation\Models\TimetableCell;
use Modules\TimetableFoundation\Models\TimetableType;
```
If TTF, SCH, or Prime modules are disabled, StandardTimetable will throw class-not-found errors. Unlike the VND→Transport coupling (which was an avoidable cross-module import), these TTF imports are intentional and necessary by design.

---

## V1 Screen Spec Inventory (2 files)

| File | Coverage |
|------|---------|
| `01-Standard-Timetable-Dashboard-and-Initialization.md` | Dashboard stats, manual timetable creation, Period Set validation, deletion protection |
| `02-Drag-and-Drop-Grid-and-Validation-Engine.md` | Activity sidebar state management, 5-check conflict engine, cell placement with teacher pivot management |

> V1 specs are BRD-style documents (2 pages each), confirming the core implemented features. Much thinner than typical V1 screen-spec folders (compare: VND has 9 files, TTF has 12 files). V2 requirement adds 7 new FR areas not covered in V1.

---

## Route Registration Pattern

All 6 active routes registered in `Modules/StandardTimetable/routes/web.php` via `StandardTimetableServiceProvider` / `RouteServiceProvider`. Prefix: `standard-timetable`. Middleware applied by RouteServiceProvider: `web`, `tenancy`, `auth`, `verified`.

`EnsureTenantHasModule` is NOT applied anywhere (P0 gap SEC-STA-01).

### Current Routes (Implemented)

| Method | URI | Controller Method | Route Name | Auth |
|--------|-----|------------------|-----------|------|
| GET | `/standard-timetable/` | `index` | `standard-timetable.index` | `viewAny` gate (blanket) |
| GET | `/standard-timetable/manual-placement` | `manualPlacement` | `standard-timetable.menu.manualPlacement` | `viewAny` gate (blanket) |
| POST | `/standard-timetable/place-cell` | `placeCell` | `standard-timetable.placeCell` | `viewAny` gate (blanket — **should be `manualPlace`**) |
| POST | `/standard-timetable/remove-cell` | `removeCell` | `standard-timetable.removeCell` | `viewAny` gate (blanket — **should be `manualPlace`**) |
| POST | `/standard-timetable/create-timetable` | `createTimetable` | `standard-timetable.createTimetable` | `viewAny` gate (blanket — **should be `manualPlace`**) |
| DELETE | `/standard-timetable/delete-timetable/{id}` | `deleteTimetable` | `standard-timetable.deleteTimetable` | `viewAny` gate (blanket — **should be `manualPlace`**) |

### Required Routes (Not Yet Implemented — per V2 FR-TTS-04/06/07/08/09/11)

| Method | URI | Controller Method | Route Name |
|--------|-----|------------------|-----------|
| GET | `/standard-timetable/class-view` | `classView` | `standard-timetable.classView` |
| GET | `/standard-timetable/teacher-view` | `teacherView` | `standard-timetable.teacherView` |
| GET | `/standard-timetable/room-view` | `roomView` | `standard-timetable.roomView` |
| PATCH | `/standard-timetable/lock-cell` | `lockCell` | `standard-timetable.lockCell` |
| PATCH | `/standard-timetable/unlock-cell` | `unlockCell` | `standard-timetable.unlockCell` |
| PATCH | `/standard-timetable/lock-all/{id}` | `lockAll` | `standard-timetable.lockAll` |
| PATCH | `/standard-timetable/update-room` | `updateRoom` | `standard-timetable.updateRoom` |
| POST | `/standard-timetable/submit-approval/{id}` | `submitForApproval` | `standard-timetable.submitApproval` |
| PATCH | `/standard-timetable/publish/{id}` | `publish` | `standard-timetable.publish` |
| POST | `/standard-timetable/copy/{id}` | `copyTimetable` | `standard-timetable.copy` |
| POST | `/standard-timetable/validate/{id}` | `validateTimetable` | `standard-timetable.validate` |
| GET | `/standard-timetable/{id}/change-log` | `changeLog` | `standard-timetable.changeLog` |
| GET | `/standard-timetable/class-view/export-csv` | `exportClassCsv` | `standard-timetable.exportClassCsv` |
| GET | `/standard-timetable/class-view/export-pdf` | `exportClassPdf` | `standard-timetable.exportClassPdf` |
| GET | `/standard-timetable/teacher-view/export-csv` | `exportTeacherCsv` | `standard-timetable.exportTeacherCsv` |

### Dead Code in `tenant.php`
Lines 229-231 define an empty route group that must be removed:
```php
Route::middleware(['auth', 'verified'])->prefix('standard-timetable')->name('standard-timetable.')->group(function () {
    // EMPTY — all routes served via Modules/StandardTimetable/routes/web.php
});
```

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| TTS introduces no exclusive tables | All data goes into shared `tt_*` tables; `generation_method = 'MANUAL'` and `source = 'MANUAL'` are the discriminators. DDL Section 7 marked PENDING in `tenant_db_v2.sql`. | V2 §5.1, V2 §5.4 |
| Routes served via module `web.php`, not `tenant.php` | Consistent with how TTF and STT handle their routes. Confirmed by RouteServiceProvider. The central `tenant.php` empty group is dead code. | Code inspection |
| `updateOrCreate` on class_group_id slot | Same class can have only one activity per slot; dropping a second replaces the first (with CLASS_DOUBLE_BOOKING warning — not a hard block). | V2 FR-TTS-02.6, code line 198 |
| Conflict detection is advisory, not blocking | All 5 conflict types are warnings; placement proceeds regardless. Only `is_locked` cells hard-block removal. Break periods are intended to hard-block (BR-TTS-014) but this is not yet implemented. | V2 BR-TTS-008 + code |
| Hard-delete for timetable deletion | `forceDelete()` on cells + timetable inside `DB::beginTransaction()` — no soft delete for timetable records (cascade is explicit). | `deleteTimetable()` lines 383-393 |
| `MT_YYYYMMDD_HHiiss_XXXX` code scheme | Auto-generated unique code using `'MT_' . now()->format('Ymd_His') . '_' . Str::random(4)`. Collision risk is low (microsecond prefix + 4 random chars) but not impossible under high concurrency. | `createTimetable()` line 350 |
| Controller extends correct base class | `extends App\Http\Controllers\Controller` — correct. Compare VND's SEC-VND-01 bug where VendorInvoiceController extends the wrong base class, bypassing auth helpers. TTS does not share this bug. | Code line 26 |
| Published timetable deletion blocked | `deleteTimetable()` returns HTTP 422 if `status === 'PUBLISHED'`. However GENERATED status can still be deleted — a logic gap (GAP-STA-12). | Code line 379 |

---

## Business Rules (from V2)

| BR ID | Rule | Status |
|-------|------|--------|
| BR-TTS-001 | Only timetables with `generation_method = 'MANUAL'` may have cells placed or removed via TTS endpoints | ✅ Enforced — `deleteTimetable` filters MANUAL; `placeCell` relies on timetable existing |
| BR-TTS-002 | Only PUBLISHED timetables appear in the class/teacher/room read views | ❌ Not enforced — read views not built |
| BR-TTS-003 | A locked cell (`is_locked = 1`) rejects `removeCell` with HTTP 422 | ✅ Enforced in `removeCell()` |
| BR-TTS-004 | A PUBLISHED timetable is immutable — placement/removal/lock calls are rejected | ❌ Not enforced — no immutability check in `placeCell` or `removeCell` |
| BR-TTS-005 | Only one PUBLISHED timetable per `timetable_type_id + academic_term_id` at a time | ❌ Not enforced |
| BR-TTS-006 | Deleting a timetable is permitted only for DRAFT manual timetables | ❌ Partial — PUBLISHED blocked; GENERATED not blocked (GAP-STA-12) |
| BR-TTS-007 | Conflict detection covers 5 types: intra-TT teacher, cross-TT teacher, intra-TT room, cross-TT room, class double-booking | ✅ All 5 implemented; BUG-STA-06 affects teacher name display |
| BR-TTS-008 | Conflicts are warnings, not blockers (except break periods → hard reject) | ✅ Warnings implemented; break-period rejection (❌) not implemented |
| BR-TTS-009 | Every cell mutation writes a `tt_change_log` record | ❌ Not implemented |
| BR-TTS-010 | Activity palette counts recalculated after every place/remove | ✅ Implemented via `placedCount` query |
| BR-TTS-011 | Copy creates new DRAFT (version=1) without modifying source | ❌ Feature not built |
| BR-TTS-012 | All data scoped to tenant database via stancl/tenancy | ✅ Guaranteed by platform infrastructure |
| BR-TTS-013 | Teacher-role user may only request own teacher_id in teacher-wise view | ❌ Not enforced — view not built |
| BR-TTS-014 | Break periods must reject placements (HTTP 422) | ❌ Not implemented |
| BR-TTS-015 | BUG-TTS-001 — wrong column in conflict teacher filter (see BUG-STA-06) | ❌ Bug present at lines 420, 442 |

---

## Publishing Workflow (Target State — Not Built)

```
DRAFT → [Submit for Approval] → GENERATED → [Principal Approves] → PUBLISHED → [New Published] → ARCHIVED

Rules:
- DRAFT: editable (place/remove/lock cells)
- GENERATED: read-only pending approval; notification sent to Principal
- PUBLISHED: immutable; visible in all read views; previous PUBLISHED of same type+term → ARCHIVED
- ARCHIVED: read-only; not in default selectors
- DRAFT hard-delete allowed; GENERATED and PUBLISHED cannot be deleted
```

---

## Effort Estimate (from V2 §15.3)

| Priority | Key Items | Estimated Hours |
|----------|-----------|----------------|
| P0 — Critical | EnsureTenantHasModule, Policy + seeder, activityLog, granular gates, fix `tenant.php` dead group | 8–12 hrs |
| P1 — High | ManualTimetableService, FormRequests, BUG-STA-06 fix, createTimetable try/catch, term-scoped cross-TT conflicts | 15–20 hrs |
| P2 — Medium | Read views (class/teacher/room), publishing workflow, cell lock/unlock endpoints, conflict persistence | 25–35 hrs |
| P3 — Low | Tests, copy timetable, CSV/PDF export, change log, drag-drop JS integration | 20–30 hrs |
| **Total** | | **68–97 hrs remaining** |

---

## Lessons Learned

- [2026-06-30 | Business Analyst] StandardTimetable owns ZERO database tables. This is intentional: TTS is a write-layer over the TTF/STT shared `tt_*` schema, using ENUM discriminators (`generation_method = 'MANUAL'`, `source = 'MANUAL'`) to distinguish its records. When auditing or migrating TTS data, filter by these discriminators rather than expecting a separate `tt_manual_*` schema. DDL Section 7 is marked PENDING for any future exclusive tables.
- [2026-06-30 | Business Analyst] V2 counted 5 controller methods and 5 routes; actual is 6 methods (index was missed) and 6 routes (GET `/` was missed). Always run `grep "^Route::" web.php` and count public methods directly — V2 estimates from code inspection can miss utility/dashboard methods that look minor but are active entry points.
- [2026-06-30 | Business Analyst] BUG-STA-06 (wrong column `id` vs `teacher_id` in conflict teacher filter) is a subtle Eloquent collection filtering error: `->whereIn('id', $teacherIds)` on a pivot model works differently than `->whereIn('teacher_id', $teacherIds)`. The `whereHas()` in the query (which uses `teacher_id` correctly) finds the right CELL; the post-load filter (which uses `id` incorrectly) then fails to name the right TEACHER. The conflict is detected, but the name is wrong. Test: `ConflictDetectionTest` should verify the exact teacher name in the conflicts array, not just `has_conflict: true`.
- [2026-06-30 | Business Analyst] The empty route group in `tenant.php` (lines 229-231) is accompanied by a helpful comment on line 56: `// use Modules\StandardTimetable\Http\Controllers\StandardTimetableController; // not used in tenant.php (empty route group)` — the dev knew it was dead code. This is the cleanest pattern for modules that serve routes via their own RouteServiceProvider; the removal PR should also update line 56's comment.
- [2026-06-30 | Business Analyst] The `createTimetable()` method correctly validates `academic_term_id` against `sch_academic_term` (note singular — maps to `sch_academic_term` table name in Laravel migration). Ensure this exact table name is used in FormRequest validation rules when FormRequests are created.

---

## Pending Next Steps

> Updated 2026-06-30 post Mode X audit. Finding codes now canonical. See full report: `3-Audit_Reports/StandardTimetable_Complete_Audit_2026-06-30.md`.

**Sprint 0 — P0 gate unblocking (8-12 hrs)**
1. **TEN-TTS-001**: Replace `use Modules\Prime\Models\AcademicSession` with `OrganizationAcademicSession` at `StandardTimetableController.php:13` and fix `Timetable::academicSession()` relation in TTF model
2. **SEC-TTS-001**: Create `StandardTimetablePolicy` (7 abilities); register via `Gate::policy()` in ServiceProvider; implement seeder (7 permissions to `sys_permissions`); replace blanket `viewAny` gate in write methods with `manualPlace`
3. **BUG-TTS-001**: Change `->whereIn('id', $teacherIds)` to `->whereIn('teacher_id', $teacherIds)` at lines 420 and 442
4. **BUG-TTS-002**: Add `->where('class_group_id', $validated['class_group_id'])` to `removeCell()` cell lookup at line 283; add `class_group_id` to removeCell validation
5. **SEC-TTS-002**: Add `EnsureTenantHasModule:StandardTimetable` to RSP middleware stack
6. **QUAL-TTS-002**: Wrap `createTimetable()` in `DB::transaction()` + try/catch

**Sprint 1 — Business rule enforcement (15-20 hrs)**
7. **BUG-TTS-003**: Change `deleteTimetable()` guard to `!== 'DRAFT'` (line 379)
8. **BUG-TTS-004**: Add `status === 'PUBLISHED'` immutability guard to `placeCell()` and `removeCell()`
9. **BUG-TTS-005**: Add `is_break` check in `placeCell()` via period type relation
10. **QUAL-TTS-003**: Scope cross-TT conflict queries (lines 431-451) to current academic term
11. **DAT-TTS-001**: Wrap cell `updateOrCreate` + teacher insert in a single `DB::transaction()` in `placeCell()`
12. **VAL-TTS-001**: Create `PlaceCellRequest`, `RemoveCellRequest`, `CreateTimetableRequest` with `class_group_id` and ownership rules
13. **ARCH-TTS-001**: Extract `ManualTimetableService`; add `activityLog()` calls (QUAL-TTS-001) in all 4 mutating methods

**Sprint 2 — Read views and locking (25-35 hrs)**
14. **DEAD-TTS-001**: Build class-wise, teacher-wise, room-wise read views (FR-TTS-04); integrate STT AnalyticsService
15. **DEAD-TTS-002**: Build `lockCell`, `unlockCell`, `lockAll` endpoints (FR-TTS-06.2-06.5)
16. **DEAD-TTS-005**: Implement conflict persistence to `tt_conflict_detection` (FR-TTS-03.6); build batch validate endpoint

**Sprint 3 — Publishing, copy, tests (20-30 hrs)**
17. **DEAD-TTS-003**: Build publishing workflow: `submitForApproval` → GENERATED → `publish` → PUBLISHED (FR-TTS-07); send notification to Principal
18. **DEAD-TTS-004**: Build `copyTimetable` endpoint in DB transaction (FR-TTS-08)
19. **DEAD-TTS-007**: Add `tt_change_log` writes to all cell mutations (FR-TTS-11)
20. **TEST-TTS-001**: Write `ManualPlacementTest`, `ConflictDetectionTest` (BUG-TTS-001 regression), `AuthorizationTest`, `TimetableLifecycleTest`

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement (full read, 1022 lines), V1 screen specs (2 files), controller (513 lines verified), routes (6 verified), AppServiceProvider check, migration check. All 25 gaps catalogued. Module code TTS; file prefix STA per task spec. |
| 1.1 | 2026-06-30 | Business Analyst | Complete Analysis Pack generated. FRD and full pack written (14 REQs, 15 BRs, 4 RPTs, 10 ENHs). RTM, FSMs, Data Dictionary, Dependency Map, NFR Catalog, Risk Register, Prioritization, Sprint Tasks (4 sprints, ~150 h), User Stories, Feature Spec all produced. Conditions Catalog saved. Effort estimate revised upward from V2's 90-125 h to ~150 h. |
| 1.2 | 2026-06-30 | Technical Auditor | Mode X Complete Technical Audit (12-layer A + FRD gap B + BR enforcement C + deploy gate G + systemic D). Health Score: 30/100 (P0-capped). Deploy Gate: NO-GO. 2 P0, 13 P1, 10 P2, 5 P3 findings confirmed from live code. Formal codes assigned: SEC-TTS-001 (blanket viewAny gate on all 6 methods), TEN-TTS-001 (AcademicSession cross-layer FK violation on createTimetable), BUG-TTS-001 (teacher column wrong in conflict filter — pre-registered), BUG-TTS-002 (removeCell missing class_group_id → wrong cell deleted), BUG-TTS-003 (deleteTimetable allows GENERATED deletion), BUG-TTS-004 (no PUBLISHED immutability in placeCell/removeCell), BUG-TTS-005 (no break-period check in placeCell), MIG-TTS-001 through MIG-TTS-004 (ENUM violations, type mismatch, name drift), VAL-TTS-001 (no FormRequests; class_group_id missing; activity_id IDOR), ARCH-TTS-001 (zero service layer), DAT-TTS-001 (non-transactional teacher insert), PERF-TTS-001 (N+1 in index()), QUAL-TTS-001 (activityLog absent), QUAL-TTS-002 (no try/catch in createTimetable), QUAL-TTS-003 (cross-TT conflict lacks term scope), DEAD-TTS-001 through DEAD-TTS-007 (read views, locking, publishing, copy, conflict persistence, change log all 0%). Full report: `3-Audit_Reports/StandardTimetable_Complete_Audit_2026-06-30.md`. Known-issues.md updated. |

---

## FRD Summary

| Attribute | Value |
|-----------|-------|
| FRD File | `TTS_FRD_2026-06-30.md` |
| Complete Analysis Pack | `TTS_FRD_Complete_2026-06-30.md` |
| FRD Date | 2026-06-30 |
| REQ count | 14 (P0=5, P1=7, P2=2) |
| BR count | 15 |
| RPT count | 4 |
| ENH count | 10 |
| Workflow count | 4 (construction, approval/publication, copy, read views) |
| Screen count | 8 (SCR-TTS-01 through SCR-TTS-08) |
| Sprint plan | 4 sprints (~8 weeks, ~150 hours remaining) |
| Overall completion | ~15% (3/15 BRs fully enforced; 0/4 reports built; read views, publishing, copy, authorization, tests all absent) |
| Effort revised | V2 estimated 90-125 h; complete pack revised to ~150 h (service layer, publishing notification workflow, batch validate, 5 test files) |

### Design Decisions Added by Complete Analysis Pack

| ID | Decision |
|----|---------|
| D-TTS-001 | All IDs in this analysis use prefix TTS per V2 requirement doc; module knowledge file named STA per original seeding task spec. Future files should use TTS as canonical prefix. |
| D-TTS-002 | Revised effort estimate: 150 h across 4 sprints. Sprint 1 (32.5 h) is the non-negotiable pre-launch gate — no production launch without P0 auth and security fixes. |
| D-TTS-003 | Conditions Catalog saved separately to `{REQUIREMENT_CONDITIONS}/TTS_Conditions.md` as extracted from the Complete Analysis Pack Section 3B. |
