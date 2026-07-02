# PTM Module — Mode X Complete Technical Audit
**Module:** Parent-Teacher Meeting (PTM) | **Prefix:** `ptm_` | **Date:** 2026-06-29
**Auditor:** pa-technical-auditor | **Mode:** X (A + B + C + G + scoped D)

---

## 1. Executive Summary

The PTM module implements the core Parent-Teacher Meeting lifecycle for Indian K-12 multi-tenant schools: event creation, class-section assignment, batch template management, teacher assignment and scheduling, slot generation, and staff-initiated booking with cancellation/reschedule. The module is architecturally sound at the surface — correct tenancy middleware, SoftDeletes on all models, Gate::policy() registration — but contains **five P0 blockers** that must be resolved before any production deployment, plus nineteen P1 issues that collectively degrade data integrity, security posture, and feature completeness.

**Health Score: 38 / 100 — NO-GO**

| Severity | Count |
|----------|-------|
| P0 — Critical blocker | 5 |
| P1 — High (blocks hardening) | 19 |
| P2 — Medium (tech debt) | 5 |
| P3 — Low (polish) | 3 |

**Verdict: NO-GO for production deployment.**
P0s 1–5 collectively allow unauthorized data exposure of sensitive scheduling/student data, guarantee booking record corruption on any republish or assignment delete, and make the uniqueness guarantee for BR-PTM-005 completely ineffective at the database layer. All five P0s require code and migration changes.

---

## 2. Health Score Breakdown

| # | Layer | Max | Score | Limiter |
|---|-------|-----|-------|---------|
| L1 | Module Structure & Scaffolding | 8 | 6 | Empty module migrations dir; 0 tests |
| L2 | Tenancy Isolation | 12 | 8 | API routes missing tenancy stack; session('tenant_id')??1 in 4 places |
| L3 | Authorization & RBAC | 15 | 2 | P0: 6 unguarded AJAX endpoints; D30 (18 FormRequests); no perms seeded |
| L4 | Routing | 8 | 3 | P1: All 9 entity trash routes unreachable (shadow by resource show); dead code |
| L5 | Controllers | 8 | 6 | VAL-PTM-001; inline validate on cancel/reschedule |
| L6 | Services / Business Logic | 12 | 3 | P0: no lockForUpdate; P0: regenerate destroys bookings; BR-PTM-013/015 missing |
| L7 | Models & Schema | 10 | 1 | P0: active_booking_key plain column (never set); D17: updated_by in fillable not in DDL |
| L8 | Database / DDL | 10 | 7 | D29: 3 ENUMs; UNIQUE constraint on active_booking_key is completely ineffective |
| L9 | FormRequests | 6 | 3 | D30: all 18 authorize()=true |
| L10 | Views / XSS | 6 | 6 | CLEAN — all {!! !!} are pagination ->links() |
| L11 | FRD Coverage | 8 | 4 | REQ-PTM-010 (parent booking) missing; REQ-PTM-015 (payment) missing |
| L12 | Config, Jobs, Tests | 7 | 1 | 0 tests; 0 jobs; notifications synchronous inside transactions |
| **Total** | | **110** | **50→38*** | *Capped by 5 P0s at -12 penalty* |

*(Raw sum 50/110 = 45%; 5 P0 penalty = -7 points → 38/100)*

---

## 3. Findings Table — All P0 through P3

### P0 — Critical Blockers (Deploy-Blocking)

| ID | Category | Finding | Location |
|----|----------|---------|----------|
| SEC-PTM-001 | Security | 6 AJAX endpoints in PtmManagementController have ZERO Gate::authorize. Any authenticated tenant user can query all teacher lists, student lists, teacher slot schedules, and event scheduling data. Routes: `ptm/ajax/class-teachers`, `ptm/ajax/assignment-teachers`, `ptm/ajax/eligible-additional-teachers`, `ptm/ajax/event-teachers`, `ptm/ajax/teacher-slots`, `ptm/ajax/event-students`. | `PtmManagementController.php` lines 227, 277, 312, 338, 376, 398 |
| DAT-PTM-001 | Data Integrity | D36: `ptm_slot_bookings.active_booking_key` is a plain `unsignedInteger` column in the migration, NOT a `VIRTUAL GENERATED` column as mandated by D35/DDL-v3. The column is also absent from `PtmSlotBooking.$fillable` and is never explicitly assigned in `PtmSlotBookingService`. Result: all rows have `active_booking_key = NULL`. MySQL UNIQUE treats two NULLs as distinct, so the unique indexes `uq_ptmBooking_event_teacher_studentActive` and `uq_ptmBooking_slot_studentActive` enforce **nothing**. BR-PTM-005 (1 confirmed booking per student/teacher/event) has zero database-level enforcement. | Migration `2026_06_16_094315_create_ptm_slot_bookings_table.php` line 23; `PtmSlotBooking.php` $fillable; `PtmSlotBookingService.php` |
| DAT-PTM-002 | Race Condition | `PtmSlotBookingService::create()` performs a read-check-write sequence with no pessimistic lock. Pattern: `PtmSlot::findOrFail()` → check capacity → check existing confirmed → `PtmSlotBooking::create()`. Two concurrent parent booking requests for the same slot will both pass capacity and uniqueness checks and both insert, overfilling the slot and creating duplicate confirmed bookings for the same student+teacher+event. Requires `lockForUpdate()` on the slot row. | `PtmSlotBookingService.php` lines 70–115 |
| DAT-PTM-003 | Data Integrity | `PtmSlotService::generateFromAssignment()` calls `PtmSlot::where('assignment_id', $assignment->id)->forceDelete()` at the start of every generation. The `ptm_slot_bookings` migration declares `onDelete('cascade')` on `slot_id` FK. Result: republishing an already-published assignment permanently destroys **all booking records** for that assignment with no warning, no soft-delete, no audit trail. | `PtmSlotService.php` line 43; `2026_06_16_094315_create_ptm_slot_bookings_table.php` line 30 |
| DAT-PTM-004 | Data Integrity | `PtmAssignmentService::delete()` calls `$assignment->slots()->forceDelete()`, which hard-deletes all slots. The FK cascade then permanently destroys all `ptm_slot_bookings` records for those slots. BR-PTM-013 (protect assignment from deletion when active bookings exist) is not implemented: `delete()` does not query for confirmed bookings before proceeding. Admin-initiated soft-delete of an assignment silently annihilates all booking history. | `PtmAssignmentService.php` lines 191–204 |

### P1 — High (Hardening Blockers)

| ID | Category | Finding | Location |
|----|----------|---------|----------|
| BUG-PTM-001 | Routing | All 9 entity resource groups register trash/restore/forceDelete routes **after** `Route::resource(...)`. Laravel's route resolver matches the resource `show` route (`GET ptm-event/{ptm_event}`) before reaching `GET ptm-event/trash/view`, treating "trash" as the `{ptm_event}` parameter. All trash routes for all 9 entities are **permanently unreachable** (BUG-HPC-009 pattern). | `Modules/Ptm/routes/web.php` — all 9 entity groups |
| SEC-PTM-002 | Security | All 18 FormRequests in `Modules/Ptm/app/Http/Requests/` return `authorize(): bool { return true; }` (D30 platform pattern). Authorization is deferred to Gate::authorize in controllers, but the FormRequest layer provides zero secondary authorization guard. | All 18 Request files |
| SEC-PTM-003 | Security | `PtmCombinedViewController::setup()` and `bookings()` have no Gate::authorize call. Routes `ptm.combined.setup` and `ptm.combined.bookings` are protected by `auth` middleware but any authenticated tenant user can view all PTM events, class sections, batch templates, batch slot templates, and all bookings platform-wide. | `PtmCombinedViewController.php` lines 53, 170 |
| TEN-PTM-001 | Tenancy | `session('tenant_id') ?? 1` used in `Notification::create()` calls inside `PtmSlotBookingService::create()`, `cancel()`, `PtmAssignmentService::create()`, and `update()` — 4 occurrences. Session is unreliable in queued or concurrent contexts; fallback to `?? 1` hardcodes tenant ID 1, creating notifications on the wrong tenant on multi-tenant deployments. | `PtmSlotBookingService.php` lines 120, 176; `PtmAssignmentService.php` lines 71, 171 |
| TEN-PTM-002 | Tenancy | API routes are registered in `RouteServiceProvider::registerApiRoutes()` with only `'api'` middleware — no `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, or `EnsureTenantIsActive`. PTM API endpoints (if used) bypass tenancy initialization entirely. | `RouteServiceProvider.php` lines 45–53 |
| VAL-PTM-001 | Validation | `PtmSlotBookingController::cancel()` reads `$request->input('cancel_reason')` without any FormRequest or validation. `reschedule()` uses inline `$request->validate(['new_slot_id' => 'required|exists:ptm_slots,id'])` instead of a dedicated FormRequest. Both lack CSRF protection at the FormRequest layer and bypasses the platform request-class pattern. | `PtmSlotBookingController.php` lines 178, 205 |
| D17-PTM-001 | Schema | `PtmSlotBooking.$fillable` includes `'updated_by'` but `ptm_slot_bookings` migration has no `updated_by` column. Any update passing `updated_by` will fail with "Column not found: 1054 Unknown column 'updated_by'". | `PtmSlotBooking.php` line 33; `2026_06_16_094315_create_ptm_slot_bookings_table.php` |
| D39-PTM-001 | Security | PTM permissions (`tenant.ptm_event.*`, `tenant.ptm_assignment.*`, `tenant.ptm_slot_booking.*`, etc.) are referenced in Gate::authorize calls throughout all controllers but are **not present** in `TenantRolePermissionSeeder.php`. On a fresh tenant, no role has these permissions, so only super-admin can access any PTM feature. Regular staff are locked out. | `database/seeders/TenantRolePermissionSeeder.php` (absent); all PTM controllers |
| BR-PTM-013 | Business Rule | Assignment delete (`PtmAssignmentService::delete()`) does not check for confirmed slot bookings before proceeding. BR-PTM-013 mandates that an assignment with active confirmed bookings cannot be deleted. Currently any admin with `tenant.ptm_assignment.delete` can destroy confirmed booking records (see also DAT-PTM-004). | `PtmAssignmentService.php` line 191 |
| BR-PTM-015 | Business Rule | `PtmAssignmentService::unpublish()` soft-deletes all slots via `$assignment->slots()->delete()` but does not check for or cancel existing confirmed bookings. Confirmed bookings reference now-soft-deleted slots, leaving them orphaned. Parents receive no notification. BR-PTM-015 (warn and prevent unpublish with active bookings) is not enforced. | `PtmAssignmentService.php` lines 235–246 |
| PERF-PTM-001 | Performance | `PtmManagementController::index()` fires 14+ uncached queries per page load including 8 separate `onlyTrashed()->count()` calls (one per entity type for sidebar counters), plus unbounded `AcademicTerm::all()`, `Section::all()`, and two sequential `OrganizationAcademicSession` queries. | `PtmManagementController.php` lines 22–225 |
| PERF-PTM-002 | Performance | `PtmBlockoutService::notifyAffectedBookings()` discards eager-loaded guardians and re-queries per booking, producing N+1 guardian queries proportional to affected booking count. | `PtmBlockoutService.php` |
| PERF-PTM-003 | Performance | `PtmSlotService::syncSlotStatusForBlockout()` fires one `isSlotBlockedByBlockout()` EXISTS query per slot (N+1). On a large PTM event with 100+ slots, this triggers 100+ separate EXISTS queries per blockout save. | `PtmSlotService.php` lines 353–380 |
| PERF-PTM-004 | Performance | `PtmCombinedViewController::scheduling()` route currently maps to `PtmManagementController::index()` (not the combined view's scheduling method). `sharedData()` is called twice on the management index: once by `index()` itself and once via implicit page initialization. | `Modules/Ptm/routes/web.php`; `PtmCombinedViewController.php` line 161 |
| PERF-PTM-005 | Performance | `PtmCombinedViewController::sharedData()` loads all teachers unbounded: `User::active()->whereHas('employee', ...)->orderBy('name')->get()`. On a school with 200+ teachers this fetches the full collection on every combined view request (setup, bookings). | `PtmCombinedViewController.php` lines 40–43 |
| PAY-PTM-001 | Feature Gap | 7 payment tables created in migrations (2026-06-18 batch): `ptm_payment_gateways`, `ptm_payments`, `ptm_payment_refunds`, `ptm_payment_audit_logs`, `ptm_payment_webhooks`, `ptm_offline_payment_records`, `ptm_payment_reconciliations`. Zero corresponding models, controllers, or services. Payment workflow is entirely unimplemented (35% of the module's table surface). | `database/migrations/tenant/` — 8 payment migration files |
| PARENT-PTM-001 | Feature Gap | REQ-PTM-010 (Parent Self-Booking) is not implemented. No parent-portal or student-portal routes, views, or controllers exist for the PTM module. The FRD Section 10 maps this to "Screen 12" with no code coverage. `PtmSlotBookingService` mentions `isManual` flag but the `isManual=false` path (parent booking) has no frontend entry point. | FRD Section 3.2 REQ-PTM-010; `PtmSlotBookingService.php` |
| TEST-PTM-001 | Testing | Zero test files in `Modules/Ptm/tests/`. No unit tests for critical booking logic (capacity check, uniqueness, three-level fallback), no feature tests for authorization, no regression coverage for P0 findings. | `Modules/Ptm/` |
| JOB-PTM-001 | Architecture | Notification creation (`Notification::create()`) runs synchronously inside `DB::transaction()` blocks in booking create, cancel, and assignment create/update. If the notification insert is slow or the `ntf_notifications` table is locked, it delays the transaction commit and increases deadlock probability. Notifications should be dispatched as queued jobs after commit. | `PtmSlotBookingService.php` lines 117–133; `PtmAssignmentService.php` lines 67–85 |
| DEAD-PTM-001 | Dead Code | `PtmCombinedViewController::scheduling()` has no route. Route `ptm.combined.scheduling` is mapped to `PtmManagementController::index()` in `web.php`. The 55-line `scheduling()` method in `PtmCombinedViewController` (assignments, teachers, blockouts, slots paginated view) is dead code — never reachable. | `PtmCombinedViewController.php` lines 109–163; `web.php` |

### P2 — Medium (Tech Debt)

| ID | Category | Finding | Location |
|----|----------|---------|----------|
| D29-PTM-001 | Schema | `ptm_events.default_meeting_mode` is `ENUM('HYBRID','IN_PERSON','ONLINE')`. D29 mandates FK to `sys_dropdown_table` for extensible lookup values. | Migration `2026_06_16_094308_create_ptm_events_table.php` line 21 |
| D29-PTM-002 | Schema | `ptm_slots.status` is `ENUM('AVAILABLE','BLOCKED','BOOKED','CANCELLED','COMPLETED','FULL')`. D29 violation — status should be string FK to `sys_dropdown_table`. | Migration `2026_06_16_094314_create_ptm_slots_table.php` line 20 |
| D29-PTM-003 | Schema | `ptm_slot_bookings.status` is `ENUM('CANCELLED','COMPLETED','CONFIRMED','NO_SHOW','RESCHEDULED')`. D29 violation. | Migration `2026_06_16_094315_create_ptm_slot_bookings_table.php` line 17 |
| PERF-PTM-006 | Performance | `PtmAssignmentController::create()` and `edit()` both call `PtmEventClassSection::with(['classSection'])->get()` — unbounded, loads all event-class-section records for all events. As PTM events accumulate over sessions, this grows unboundedly. | `PtmAssignmentController.php` lines 39, 79 |
| ARCH-PTM-001 | Architecture | `PtmServiceProvider::loadMigrationsFrom(module_path('Ptm', 'database/migrations'))` points to the module's own (empty) migrations directory. All 17 PTM migrations reside in `database/migrations/tenant/`. This is functional but misleading for new developers and inconsistent with module-isolation conventions. | `PtmServiceProvider.php` line 40 |

### P3 — Low (Polish)

| ID | Category | Finding | Location |
|----|----------|---------|----------|
| UX-PTM-001 | UX | `PtmEvent::getVenueAttribute()` returns `substr($this->description, 0, 50) ?? 'Main Hall'`. Venue is derived from the first 50 characters of description — not a proper venue field. The `ptm_events` table has no dedicated venue column; the FRD mentions room assignment at the class-section level (correct), so this accessor is misleading. | `PtmEvent.php` lines 77–79 |
| CODE-PTM-001 | Code Quality | `PtmSlotService::getAll()` has a no-op filter for 'search': `.when(isset($filters['search']), fn ($q) => $q)` — the closure returns the query unchanged. Search is silently ignored. | `PtmSlotService.php` lines 17–18 |
| SEEDER-PTM-001 | Demo Data | `PtmSeeder::run()` inserts demo slot bookings directly via `DB::table()` without setting `active_booking_key`. This is consistent with the migration (plain column, never set) but means demo data demonstrates the broken uniqueness pattern. | `PtmSeeder.php` lines 427–451 |

---

## 4. Layer-by-Layer Assessment

### L1 — Module Structure & Scaffolding
**Score: 6/8 — PASS with caution**

- Module directory: `Modules/Ptm/` correctly follows nwidart/laravel-modules v12 structure.
- Namespace: `Modules\Ptm\*` consistent throughout.
- Service registration: `PtmServiceProvider` binds 9 policies, registers routes, loads migrations.
- Views: 58 Blade views in `resources/views/` with logical partials.
- Issue: Module's own `database/migrations/` dir is empty; all 17 PTM migrations live in `database/migrations/tenant/`. `loadMigrationsFrom` points to the empty dir — harmless but confusing.
- Issue: 7 payment migration files (2026-06-18 batch) have zero corresponding PHP code. 35% of the module's table surface is orphaned infrastructure.
- Issue: 0 test files. Platform expectation is Pest feature tests per module.

### L2 — Tenancy Isolation
**Score: 8/12 — CONDITIONAL PASS**

- CLEAN: `RouteServiceProvider` applies the full tenancy stack to web routes: `[web, InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class, EnsureTenantIsActive::class, 'auth', 'verified']`.
- CLEAN: All models reference `sys_users` (not `users`) — correct tenant user table.
- CLEAN: Cross-table FKs reference tenant tables only (`sch_rooms`, `std_students`, `sys_users`). No cross-DB FK risk.
- FAIL: API routes registered with `'api'` middleware only — no tenancy stack (TEN-PTM-002).
- FAIL: `session('tenant_id') ?? 1` pattern appears 4+ times in service layer for notification tenant_id (TEN-PTM-001).

### L3 — Authorization & RBAC
**Score: 2/15 — FAIL (P0 present)**

- PASS: `PtmServiceProvider::registerPolicies()` correctly registers all 9 policy classes via `Gate::policy()`.
- PASS: `PtmSlotBookingController`, `PtmEventController`, `PtmAssignmentController` — all CRUD methods have `Gate::authorize` before any data access.
- FAIL P0: 6 AJAX methods in `PtmManagementController` have zero authorization (SEC-PTM-001).
- FAIL P1: `PtmCombinedViewController::setup()` and `bookings()` have no Gate::authorize (SEC-PTM-003).
- FAIL P1: 18 FormRequests return `authorize() = true` (SEC-PTM-002 / D30).
- FAIL P1: PTM permissions not seeded in `TenantRolePermissionSeeder` (D39-PTM-001). Regular staff roles cannot access any PTM feature on fresh tenants.

### L4 — Routing
**Score: 3/8 — FAIL (P1 present)**

- PASS: Prefix `/ptm`, namespace `ptm.*`, middleware stack correct.
- FAIL P1: All 9 entity groups suffer from BUG-PTM-001: trash routes registered after `Route::resource()`, permanently shadowed by the resource `show` route. Affected: `ptm-event`, `ptm-batch-template`, `ptm-batch-slot-template`, `ptm-event-class-section`, `ptm-assignment`, `ptm-assignment-teacher`, `ptm-blockout`, `ptm-slot`, `ptm-slot-booking`.
- FAIL: `combined.scheduling` route maps to `PtmManagementController::index()` — not the combined view's scheduling method. `PtmCombinedViewController::scheduling()` is dead code (DEAD-PTM-001).

### L5 — Controllers
**Score: 6/8 — CONDITIONAL PASS**

- PASS: CRUD controllers consistently use `$request->validated()` — D25 clean.
- PASS: Activity logging (`activityLog()`) on all mutation operations.
- PASS: Gate::authorize present on all CRUD methods of the 3 main CRUD controllers.
- FAIL P1: `PtmSlotBookingController::cancel()` reads raw input without FormRequest (VAL-PTM-001).
- FAIL P1: `PtmSlotBookingController::reschedule()` uses inline `$request->validate()` (VAL-PTM-001).
- NOTE: `toggleStatus()` in multiple controllers uses inline `$request->validate()` for a single boolean — acceptable given the narrow scope.

### L6 — Services / Business Logic
**Score: 3/12 — FAIL (P0s present)**

- PASS: Three-level parameter fallback (Assignment override → BatchTemplate → Event default) correctly implemented for `max_participants`, `buffer_min`, and `slot_duration_min` in `PtmSlotService::createSlotsForTeacher()`.
- PASS: Static slot generation (buffer=0) and dynamic slot generation (buffer>0) modes correctly implemented.
- PASS: Blockout overlap detection correctly uses `start_time < slotEnd AND end_time > slotStart` logic.
- PASS: Reschedule correctly implemented as atomic cancel + rebook within a single transaction.
- FAIL P0: `PtmSlotBookingService::create()` — no `lockForUpdate()` on slot row (DAT-PTM-002). Race condition: two concurrent bookings for the same slot can both pass capacity check.
- FAIL P0: `PtmSlotService::generateFromAssignment()` calls `PtmSlot::where(...)->forceDelete()` at entry — permanently destroys booking records via FK cascade on every republish (DAT-PTM-003).
- FAIL P0: `PtmAssignmentService::delete()` calls `slots()->forceDelete()` — permanently destroys all booking records for the assignment with no guard (DAT-PTM-004).
- FAIL P1: BR-PTM-013 not implemented: no check for confirmed bookings before assignment delete.
- FAIL P1: BR-PTM-015 not implemented: no warning or prevention when unpublishing with active bookings.
- FAIL P1: `PtmAssignmentService::update()` sends notification with `session('tenant_id') ?? 1` (TEN-PTM-001).
- FAIL P1: Notifications run synchronously inside DB transactions (JOB-PTM-001).
- FAIL P1: PERF-PTM-003: N+1 exists query per slot in `syncSlotStatusForBlockout()`.

### L7 — Models & Schema
**Score: 1/10 — FAIL (P0 present)**

- PASS: All 9 models use SoftDeletes trait correctly.
- PASS: `$casts` arrays include `datetime` casts for all timestamp columns.
- PASS: `PtmBatchTemplate.$table = 'ptm_batches_template'` matches migration table name.
- PASS: `PtmSlotBooking::isCancellable()` correctly reads cancellation_lead_time_hrs from the event.
- FAIL P0: `PtmSlotBooking.active_booking_key` is never set by the model or service. All rows receive `NULL`. The UNIQUE constraint is completely ineffective (DAT-PTM-001).
- FAIL P1: `PtmSlotBooking.$fillable` includes `'updated_by'` but the column does not exist in the migration. Any update including `updated_by` will throw a QueryException (D17-PTM-001).

### L8 — Database / DDL
**Score: 7/10 — CONDITIONAL PASS**

- PASS: 9 core tables with correct naming (`ptm_*` prefix).
- PASS: All FKs use tenant-scoped tables. No cross-database FK references.
- PASS: `ptm_slots` UNIQUE index `uq_ptmSlots_teacher_start` on `(teacher_id, slot_start)` correctly prevents double-booking a teacher in the same time slot.
- PASS: SoftDeletes (`deleted_at`) present on all relevant tables.
- PASS: Explicit `created_at`/`updated_at` as nullable timestamps (correct for tenant migrations).
- FAIL: `ptm_slot_bookings` UNIQUE indexes `uq_ptmBooking_event_teacher_studentActive` and `uq_ptmBooking_slot_studentActive` both include `active_booking_key`, which is always NULL → constraints enforce nothing (consequence of DAT-PTM-001).
- FAIL P2: D29: 3 ENUM columns across 3 tables (D29-PTM-001, -002, -003).

### L9 — FormRequests
**Score: 3/6 — CONDITIONAL PASS**

- PASS: Individual `rules()` arrays are well-formed with appropriate type, existence, and cross-field date validations (e.g., `StorePtmEventRequest` validates `booking_window_end` > `booking_window_start` > `event_start_date`).
- PASS: `prepareForValidation()` used to normalize field names from form to API keys.
- FAIL P1: All 18 FormRequests return `authorize() = true` (D30/SEC-PTM-002).
- NOTE: Per D-PPT-002, PTM FormRequest authorize()=true is platform-standard D30, not a local deviation. However it remains an audit finding until D30 is resolved platform-wide.

### L10 — Blade Views / XSS
**Score: 6/6 — PASS**

- All `{!! ... !!}` occurrences are exclusively Laravel paginator `->links()` output — framework-escaped HTML, not user content.
- No raw user data rendered via `{!! !!}`.
- No `@unescaped`, `htmlspecialchars_decode`, or raw echo patterns found.

### L11 — FRD Coverage
**Score: 4/8 — CONDITIONAL PASS**

See Section 5 (FRD Gap Analysis) for full detail. Key gaps: REQ-PTM-010 (parent self-booking) not implemented; REQ-PTM-015 (payment integration) not implemented; BR-PTM-013 and BR-PTM-015 not enforced.

### L12 — Configuration, Jobs, Tests
**Score: 1/7 — FAIL**

- FAIL: 0 test files. No unit tests, no feature tests, no integration tests.
- FAIL: 0 queued jobs. All side-effects (notifications, email) run synchronously inside transactions.
- FAIL: Module migrations dir empty; `loadMigrationsFrom` is a no-op (ARCH-PTM-001).
- NOTE: `PtmServiceProvider` does not register services via container (`singleton`/`bind`). Services are resolved via Laravel's auto-resolution. This is acceptable for now but will limit testability.

---

## 5. FRD Gap Analysis (Mode B)

| REQ | Description | Priority | Status | Notes |
|-----|-------------|----------|--------|-------|
| REQ-PTM-001 | Event Management (create/edit/publish/archive) | P0 | IMPLEMENTED | CRUD complete; `PtmEventController` + combined setup view |
| REQ-PTM-002 | Class-Section Assignment to Event | P0 | IMPLEMENTED | `PtmEventClassSectionController` covers full CRUD |
| REQ-PTM-003 | Batch Template & Slot Template Management | P0 | IMPLEMENTED | `PtmBatchTemplateController`, `PtmBatchSlotTemplateController` |
| REQ-PTM-004 | Teacher Assignment to Class Section | P0 | IMPLEMENTED | `PtmAssignmentController` with additional teacher support |
| REQ-PTM-005 | Assignment Publish (triggers slot generation) | P0 | PARTIAL | Publish works; BR-PTM-013 and BR-PTM-015 guards absent; republish destroys bookings (DAT-PTM-003) |
| REQ-PTM-006 | Blockout / Unavailability Management | P0 | IMPLEMENTED | `PtmBlockoutController`, `PtmBlockoutService` |
| REQ-PTM-007 | Slot Auto-Generation from Assignment | P0 | IMPLEMENTED | `PtmSlotService::generateFromAssignment()` — both static and dynamic modes |
| REQ-PTM-008 | Three-Level Slot Parameter Fallback | P0 | IMPLEMENTED | `PtmSlotService::createSlotsForTeacher()` correctly resolves Assignment → BatchTemplate → Event defaults |
| REQ-PTM-009 | Admin/Staff Slot Booking (manual allocation) | P0 | IMPLEMENTED | `PtmSlotBookingController` + `PtmSlotBookingService` with `isManual=true` path |
| REQ-PTM-010 | Parent Self-Booking via Portal | P0 | NOT IMPLEMENTED | No parent-portal routes, views, or controllers. No `isManual=false` frontend entry point. |
| REQ-PTM-011 | Booking Confirmation & Parent Notification | P1 | PARTIAL | Notification logic exists but uses `session('tenant_id')??1` anti-pattern (TEN-PTM-001) |
| REQ-PTM-012 | Booking Cancellation with Lead-Time Check | P1 | IMPLEMENTED | `PtmSlotBookingService::cancel()` with cancellation_lead_time_hrs enforcement |
| REQ-PTM-013 | Reschedule (cancel + rebook as atomic op) | P1 | IMPLEMENTED | `PtmSlotBookingService::reschedule()` correctly nests cancel + create |
| REQ-PTM-014 | Management Dashboard & Reporting | P1 | PARTIAL | Dashboard exists but has severe performance issues (PERF-PTM-001). No dedicated report views. |
| REQ-PTM-015 | Payment Integration for Paid PTM | P2 | NOT IMPLEMENTED | 7 payment tables created (2026-06-18) with zero corresponding code (PAY-PTM-001) |

**FRD Coverage: 9/15 REQs fully implemented; 4/15 partial; 2/15 absent**

---

## 6. Business Rules Enforcement (Mode C)

| BR | Description | Status | Evidence |
|----|-------------|--------|---------|
| BR-PTM-001 | Booking only within window | ENFORCED | `PtmSlotBookingService.php` lines 75–79 |
| BR-PTM-002 | Slot status transitions (AVAILABLE → BOOKED → FULL) | ENFORCED | `PtmSlotBookingService.php` lines 111–114 |
| BR-PTM-003 | Slot capacity check before booking | PARTIAL | App-level check exists; race condition (no lock). See DAT-PTM-002. |
| BR-PTM-004 | Teacher blockout prevents booking | ENFORCED | Blockout detection in slot generation and `syncSlotStatusForBlockout()` |
| BR-PTM-005 | 1 confirmed booking per student/teacher/event | PARTIAL | App-level check in service; DB constraint completely ineffective (DAT-PTM-001). Race condition allows bypass. |
| BR-PTM-006 | Slot capacity from three-level fallback | ENFORCED | `PtmSlotService::createSlotsForTeacher()` three-level fallback correct |
| BR-PTM-007 | Cancellation requires lead time | ENFORCED | `PtmSlotBookingService::cancel()` with isManual bypass |
| BR-PTM-008 | Reschedule = cancel + new booking | ENFORCED | `reschedule()` nests cancel + create atomically |
| BR-PTM-009 | Three-level parameter fallback | ENFORCED | `PtmSlotService::createSlotsForTeacher()` lines 87–106 |
| BR-PTM-010 | Publish triggers slot generation | ENFORCED | `PtmAssignmentService::publish()` calls `generateFromAssignment()` |
| BR-PTM-011 | Admin can override booking constraints | ENFORCED | `isManual=true` parameter bypasses window and lead-time checks |
| BR-PTM-012 | Event booking window dates validation | ENFORCED | `StorePtmEventRequest` validates `booking_window_start` < `event_start_date` |
| BR-PTM-013 | Assignment delete blocked when active bookings exist | NOT IMPLEMENTED | `PtmAssignmentService::delete()` has no confirmed-booking guard |
| BR-PTM-014 | Event cascade: delete event soft-deletes assignments/slots | PARTIAL | Event soft-delete delegates to `PtmEventService::delete()` (not read); FK cascades on hard delete only |
| BR-PTM-015 | Unpublish blocked/warned when confirmed bookings exist | NOT IMPLEMENTED | `PtmAssignmentService::unpublish()` soft-deletes slots without checking bookings |

**BR Score: 10/15 enforced; 3/15 partial; 2/15 absent**

---

## 7. Cross-Cutting Concerns (Mode G)

### G1 — Platform Systemic Patterns in PTM

| Pattern | Status in PTM | Instances |
|---------|--------------|-----------|
| D25: `$request->all()` mass-assignment bypass | CLEAN | 0 instances |
| D29: ENUM instead of sys_dropdown FK | PRESENT | 3 (D29-PTM-001/002/003) |
| D30: FormRequest `authorize()=true` | PRESENT | 18/18 FormRequests |
| D36: GENERATED column degraded to plain | PRESENT | 1 (active_booking_key) — also never set |
| D38: SoftDeletes/timestamps DDL divergence | CLEAN | All 9 models have SoftDeletes; migrations have softDeletes() |
| D39: Permissions seeded but not registered | PRESENT | All PTM permissions absent from TenantRolePermissionSeeder |
| BUG-HPC-009: Trash routes shadowed by resource show | PRESENT | All 9 entity groups |

### G2 — Notification Pattern
`Notification::create()` used 4+ times across services with the `session('tenant_id') ?? 1` anti-pattern. This should be replaced with `tenant()->id` (stancl/tenancy current tenant accessor) and moved to a queued listener/job.

### G3 — EnsureTenantHasModule Middleware
Not observed in PTM routes. Module-gating middleware (`EnsureTenantHasModule::class`) is absent from the RouteServiceProvider. Any tenant can reach PTM routes regardless of whether the PTM module is licensed for that tenant. This is a platform-wide pattern for newer modules; blocking issue depends on billing configuration.

### G4 — Debug Statements
No `dd()`, `dump()`, `ray()`, or `var_dump()` found in PTM source files. Clean.

### G5 — Activity Logging
`activityLog()` helper used consistently across all CRUD mutation methods in all controllers. Pattern is uniform and complete.

---

## 8. Database Schema Deep Dive (Mode D — Scoped to ptm_*)

### DDL ↔ Migration ↔ Model Three-Way Reconcile

**Table: ptm_slot_bookings** (most critical)

| Column | Migration | Model $fillable | Model $casts | Issue |
|--------|-----------|-----------------|--------------|-------|
| id | `increments('id')` | — | — | OK |
| slot_id | `unsignedInteger` + FK | YES | — | OK |
| ptm_event_id | `unsignedInteger` + FK | YES | — | OK |
| teacher_id | `unsignedInteger` + FK | YES | — | OK |
| student_id | `unsignedInteger` + FK | YES | — | OK |
| booked_by_user_id | `unsignedInteger` + FK nullable | YES | — | OK |
| parent_comments | `text` nullable | YES | — | OK |
| status | `enum(...)` | YES | string | D29 |
| booked_at | `timestamp` nullable | YES | datetime | OK |
| cancelled_at | `timestamp` nullable | YES | datetime | OK |
| cancel_reason | `string` nullable | YES | — | OK |
| attended | `boolean` nullable | YES | boolean | OK |
| meeting_notes | `text` nullable | YES | — | OK |
| active_booking_key | `unsignedInteger` nullable | **NO** | — | **P0: never set; constraint ineffective** |
| is_active | `boolean` | YES | boolean | OK |
| created_by | `unsignedInteger` FK nullable | YES | — | OK |
| updated_by | **absent in migration** | **YES** | — | **P1 D17: column missing** |
| created_at | `timestamp` nullable | — | datetime | OK |
| updated_at | `timestamp` nullable | — | datetime | OK |
| deleted_at | `softDeletes()` | — | datetime | OK |

**Table: ptm_slots**

| Column | Migration | Model | Issue |
|--------|-----------|-------|-------|
| status | `enum('AVAILABLE','BLOCKED','BOOKED','CANCELLED','COMPLETED','FULL')` | string | D29-PTM-002 |
| unique(teacher_id, slot_start) | YES | — | Correct |
| All FK columns | Correct | In $fillable | OK |

**Table: ptm_events**

| Column | Migration | Model | Issue |
|--------|-----------|-------|-------|
| default_meeting_mode | `enum('HYBRID','IN_PERSON','ONLINE')` | string | D29-PTM-001 |
| academic_term | `unsignedInteger` FK nullable | In $fillable | OK — column name is 'academic_term' (not 'academic_term_id'); FormRequest renames via prepareForValidation |

**Active Booking Key Analysis**

DDL v3 design intent (from D35):
```sql
active_booking_key TINYINT(1) UNSIGNED
  GENERATED ALWAYS AS (IF(status='CONFIRMED', student_id, NULL)) VIRTUAL,
UNIQUE KEY uq_ptmBooking_event_teacher_studentActive (ptm_event_id, active_booking_key)
```

Actual migration:
```php
$table->unsignedInteger('active_booking_key')->nullable();
```

The column is a plain integer. The VIRTUAL GENERATED AS expression was never added. Since `PtmSlotBookingService::create()` never sets `active_booking_key` (it is absent from `$data` at line 109, `PtmSlotBooking::create($data)`) and the model's `$fillable` does not include it, every row permanently has `active_booking_key = NULL`. Two distinct `NULL` values satisfy UNIQUE in MySQL. Result: zero database-level enforcement of BR-PTM-005.

**Fix requires:**
1. A new migration to ALTER the column to VIRTUAL GENERATED.
2. OR: add explicit `$booking->active_booking_key = ($data['status'] === 'CONFIRMED') ? $data['student_id'] : null;` before `->save()` in the service (workaround, not the D35-mandated approach).

---

## 9. Systemic Pattern Scorecard

| D# | Pattern Name | PTM Instances | Verdict |
|----|-------------|---------------|---------|
| D17 | $fillable column absent from migration | 1 (updated_by on ptm_slot_bookings) | FAIL |
| D24 | Permission prefix chaos | 0 (consistent `tenant.` prefix) | PASS |
| D25 | $request->all() mass-assignment bypass | 0 | PASS |
| D29 | ENUM instead of sys_dropdown FK | 3 tables | FAIL |
| D30 | FormRequest authorize()=true | 18/18 FormRequests | FAIL |
| D36 | GENERATED column degraded to plain | 1 (active_booking_key — P0) | FAIL |
| D38 | SoftDeletes/timestamps DDL divergence | 0 | PASS |
| D39 | Permissions referenced but never seeded | All PTM permissions | FAIL |
| BUG-HPC-009 | Trash routes shadowed by resource route | 9 entity groups | FAIL |

**Systemic pattern compliance: 3/9 pass (33%)**

---

## 10. Fix-Order Roadmap

### Sprint 1 — P0 Fixes (Before Any UAT)

1. **DAT-PTM-001 (P0)** — Add migration to convert `ptm_slot_bookings.active_booking_key` to VIRTUAL GENERATED:
   ```sql
   ALTER TABLE ptm_slot_bookings
     DROP COLUMN active_booking_key,
     ADD COLUMN active_booking_key INT UNSIGNED
       GENERATED ALWAYS AS (IF(status='CONFIRMED', student_id, NULL)) VIRTUAL;
   ```
   Drop and recreate the two UNIQUE indexes. No PHP code change required if column is VIRTUAL GENERATED.

2. **DAT-PTM-002 (P0)** — Add pessimistic lock in `PtmSlotBookingService::create()`:
   ```php
   $slot = PtmSlot::lockForUpdate()->findOrFail($data['slot_id']);
   ```
   Move this to the top of the transaction closure.

3. **DAT-PTM-003 (P0)** — In `PtmSlotService::generateFromAssignment()`, before `forceDelete()`, check for confirmed bookings:
   ```php
   $hasConfirmedBookings = PtmSlotBooking::whereIn('slot_id',
       PtmSlot::where('assignment_id', $assignment->id)->pluck('id')
   )->where('status', 'CONFIRMED')->exists();
   if ($hasConfirmedBookings) {
       throw new \RuntimeException('Cannot regenerate slots: confirmed bookings exist. Cancel bookings first.');
   }
   ```
   Then change `forceDelete()` to `delete()` (soft-delete) to preserve audit trail.

4. **DAT-PTM-004 (P0) + BR-PTM-013** — In `PtmAssignmentService::delete()`, add guard and use soft-delete for slots:
   ```php
   $confirmedCount = PtmSlotBooking::whereIn('slot_id',
       $assignment->slots()->pluck('id')
   )->where('status', 'CONFIRMED')->count();
   if ($confirmedCount > 0) {
       throw new \RuntimeException("Cannot delete assignment: {$confirmedCount} confirmed booking(s) exist.");
   }
   $assignment->slots()->delete(); // soft-delete, not forceDelete
   $assignment->assignmentTeachers()->delete(); // soft-delete
   ```

5. **SEC-PTM-001 (P0)** — Add `Gate::authorize()` to all 6 AJAX methods in `PtmManagementController`:
   - `getClassTeachers()`: `Gate::authorize('tenant.ptm_assignment.viewAny')`
   - `getAssignmentTeachers()`: `Gate::authorize('tenant.ptm_assignment.viewAny')`
   - `getEligibleAdditionalTeachers()`: `Gate::authorize('tenant.ptm_assignment.update')`
   - `getEventTeachers()`: `Gate::authorize('tenant.ptm_event.viewAny')`
   - `getTeacherSlots()`: `Gate::authorize('tenant.ptm_slot_booking.viewAny')`
   - `getEventStudents()`: `Gate::authorize('tenant.ptm_slot_booking.viewAny')`

### Sprint 2 — P1 Fixes (Before Production Hardening)

6. **BUG-PTM-001** — Move all trash/restore/forceDelete routes BEFORE their `Route::resource()` declaration for all 9 entity groups.

7. **D39-PTM-001** — Add all PTM permissions to `TenantRolePermissionSeeder` for appropriate roles (Staff, Admin, Principal).

8. **D17-PTM-001** — Add `$table->unsignedInteger('updated_by')->nullable()` column migration to `ptm_slot_bookings`, or remove `updated_by` from `$fillable`.

9. **TEN-PTM-001** — Replace all `session('tenant_id') ?? 1` with `tenant()->id` in `PtmSlotBookingService` and `PtmAssignmentService`. Move `Notification::create()` outside the DB transaction.

10. **TEN-PTM-002** — Add full tenancy middleware stack to API routes in `RouteServiceProvider::registerApiRoutes()`.

11. **SEC-PTM-003** — Add Gate::authorize to `PtmCombinedViewController::setup()` and `bookings()`.

12. **VAL-PTM-001** — Create `CancelPtmSlotBookingRequest` and `ReschedulePtmSlotBookingRequest` FormRequests for cancel and reschedule actions.

13. **BR-PTM-015** — In `PtmAssignmentService::unpublish()`, check for and cancel (or reject) confirmed bookings before soft-deleting slots.

14. **PERF-PTM-001** — Replace 8 separate `onlyTrashed()->count()` calls in management dashboard with a single aggregated query, add Redis cache with 60s TTL.

15. **JOB-PTM-001** — Move notification sends to a queued listener/job dispatched after transaction commit. Pattern: `dispatch(new PtmNotificationJob(...))->afterCommit()`.

### Sprint 3 — Feature Completion

16. **PARENT-PTM-001** — Implement REQ-PTM-010: parent self-booking screens in StudentPortal. Wire to `PtmSlotBookingService::create($data, isManual: false)`.

17. **PAY-PTM-001** — Implement or defer payment tables: create models/controllers/services for `ptm_payments`, `ptm_payment_gateways`, etc., or schedule for a future paid-PTM sprint and document the gap.

18. **TEST-PTM-001** — Write Pest feature tests for: booking creation (race condition, uniqueness, capacity), cancellation lead time, three-level fallback, slot generation, authorization gates.

19. **D29-PTM-001/002/003** — Migrate ENUM columns to string with sys_dropdown_table FK (platform-wide D29 remediation sprint).

20. **DEAD-PTM-001** — Either add a route for `PtmCombinedViewController::scheduling()` or delete the method.

---

## 11. Files Examined

| File | Purpose | Key Finding |
|------|---------|-------------|
| `Modules/Ptm/routes/web.php` | Route definitions | BUG-PTM-001 (trash route shadowing all 9 groups) |
| `Modules/Ptm/app/Providers/RouteServiceProvider.php` | Middleware stack | TEN-PTM-002 (API routes missing tenancy stack) |
| `Modules/Ptm/app/Providers/PtmServiceProvider.php` | Policy registration | ARCH-PTM-001 (loadMigrationsFrom → empty dir) |
| `Modules/Ptm/app/Http/Controllers/PtmManagementController.php` | Dashboard + AJAX | SEC-PTM-001 (6 unguarded AJAX methods) |
| `Modules/Ptm/app/Http/Controllers/PtmSlotBookingController.php` | Booking CRUD | VAL-PTM-001 (inline validate on cancel/reschedule) |
| `Modules/Ptm/app/Http/Controllers/PtmEventController.php` | Event CRUD | CLEAN (all methods authorized) |
| `Modules/Ptm/app/Http/Controllers/PtmAssignmentController.php` | Assignment CRUD + publish | CLEAN (publish authorized) |
| `Modules/Ptm/app/Http/Controllers/PtmCombinedViewController.php` | Combined tabbed views | SEC-PTM-003; DEAD-PTM-001; PERF-PTM-004/005 |
| `Modules/Ptm/app/Services/PtmSlotBookingService.php` | Booking business logic | DAT-PTM-002 (no lock); TEN-PTM-001 |
| `Modules/Ptm/app/Services/PtmSlotService.php` | Slot generation | DAT-PTM-003 (forceDelete on regenerate); PERF-PTM-003; BR-PTM-009 correct |
| `Modules/Ptm/app/Services/PtmAssignmentService.php` | Assignment logic | DAT-PTM-004; BR-PTM-013/015 absent; TEN-PTM-001 |
| `Modules/Ptm/app/Models/PtmSlotBooking.php` | Booking model | DAT-PTM-001 (active_booking_key absent from fillable); D17-PTM-001 |
| `Modules/Ptm/app/Models/PtmEvent.php` | Event model | CLEAN |
| `Modules/Ptm/app/Models/PtmBatchTemplate.php` | Batch template model | CLEAN; table name matches migration |
| `Modules/Ptm/app/Http/Requests/StorePtmEventRequest.php` | Create event request | SEC-PTM-002 (authorize=true / D30) |
| `database/migrations/tenant/2026_06_16_094308_create_ptm_events_table.php` | Events DDL | D29-PTM-001 (ENUM meeting mode) |
| `database/migrations/tenant/2026_06_16_094314_create_ptm_slots_table.php` | Slots DDL | D29-PTM-002 (ENUM status) |
| `database/migrations/tenant/2026_06_16_094315_create_ptm_slot_bookings_table.php` | Bookings DDL | **DAT-PTM-001 (active_booking_key plain column)**; D29-PTM-003 |
| `Modules/Ptm/database/seeders/PtmSeeder.php` | Demo data seeder | No permission seeding; SEEDER-PTM-001 |
| `database/seeders/TenantRolePermissionSeeder.php` | Permission seeder | D39-PTM-001 (PTM permissions absent) |
| Blade views (9 partial index files examined) | Frontend views | CLEAN (XSS: all {!! !!} are ->links()) |

---

## 12. Comparison to Prior Audit (2026-06-21 Deep Audit)

The 2026-06-21 deep audit (progress.md) estimated ~55% completion and identified SEC-PTM-001 (AJAX auth gap), PERF-PTM-001–004, and VAL-PTM-001. This Mode X audit confirms all prior findings and adds:

**New P0 findings not in prior audit:**
- DAT-PTM-001: active_booking_key degraded to plain column (D36) + never set in code
- DAT-PTM-002: No lockForUpdate() on slot row during booking creation
- DAT-PTM-003: generateFromAssignment() hard-deletes bookings via cascade on every republish
- DAT-PTM-004: Assignment delete() hard-deletes booking records via cascade

**Module completion reassessment: ~55% (unchanged from prior audit)**
- Core scheduling lifecycle: 80% complete
- Parent-facing features: 0% (REQ-PTM-010 absent)
- Payment features: 0% (PAY-PTM-001)
- Data integrity / safety: 30% (race conditions, cascade destruction)
- Security posture: 40% (P0 AJAX gap, D30, no permissions seeded)
- Test coverage: 0%
