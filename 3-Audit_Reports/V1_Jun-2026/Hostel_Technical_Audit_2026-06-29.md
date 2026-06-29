# Technical Audit — Hostel (HST) — 2026-06-29

| Field | Value |
|-------|-------|
| Module | Hostel |
| Code / Prefix | HST / `hst_` |
| Mode | A — Standard Deep 12-Layer Audit (read-only) |
| Live tree audited | `/Users/bkwork/Herd/prime_ai/Modules/Hostel/` |
| Migrations audited | `/Users/bkwork/Herd/prime_ai/database/migrations/tenant/*hst_*` |
| FRD baseline | `4-Requirement_Module_wise/0-FRD_Documents/HST_FRD_2026-06-29.md` (29 REQ / 54 BR) |
| Auditor | Technical Auditor |
| Priority layers | 6, 8, 2, 5, 10 (per task) |

---

## Executive Summary

The Hostel module is large and substantially built (53 controllers, 41 models, 22 services, 41 tenant migrations) with a correct per-module tenancy stack on web routes and DB-backed status masters. **The headline defect is a P0 data-integrity hole: the two STORED generated columns that the entire allotment concurrency strategy depends on (`gen_active_bed_id`, `gen_active_student_id`) were written into the Laravel migration as inert plain `nullable bigInteger` columns — never generated, never written by code — so their `UNIQUE` indexes enforce nothing and BR-HST-001/002 (one active allotment per bed / per student) are silently unenforced; combined with zero row locks, concurrent allotment double-books a bed or a student.** A sibling migration defect makes `hst_mess_bills.total_amount` a plain NOT-NULL column instead of the GENERATED column the model and BR-HST-025 assume. Overall health is **39/100 with the P0 cap applied (≤40)** — not deployable for boarding operations until the generated-column migrations and occupancy concurrency are fixed.

---

## Audit Mode(s) Run
Mode A (full 12-layer), with depth concentrated on Layers 6, 8, 2, 5, 10 per the task. Cross-referenced against `HST_FRD_2026-06-29.md`, `decisions.md` (D34 Hostel, D29, D30, D17), and `module-knowledge/HST_Hostel.md`.

## Health Score

**39 / 100 — P0 CAP APPLIED (capped at ≤ 40).**
Raw weighted index = 39 (already below the cap). One confirmed P0 (DAT-HST-001) independently forces "not healthy".

| Layer | Wt | Score | Note |
|-------|----|-------|------|
| 6 Tenancy | 15 | Amber 0.5 | Web stack correct (Init/Prevent/EnsureActive/auth/verified). `mapApiRoutes()` has no tenancy/auth (latent; api.php empty). Scheduler runs central (see L10). |
| 5 Authorization | 14 | Amber 0.5 | CRUD controllers gated + 20 policies; but 7 report controllers ungated (SEC-HST-001/002/003), 35/38 FormRequests `return true`, 1 commented gate. |
| 8 Data Integrity/Tx | 13 | **Red 0.0** | Defeated UNIQUE (P0), non-atomic occupancy counters (P1), mess-bill column (P1), zero `lockForUpdate`. |
| 7 Validation/Mass-assign | 11 | Amber 0.5 | No `$request->all()` into models (good); but D30 systemic (35/38 true); BR-HST-015 soft. |
| 12 Deployment | 10 | Amber 0.5 | No new HST-specific deploy blocker; inherits platform P0s (queue/Horizon, committed env) — out of module scope. |
| 2 Migration↔Model↔DDL | 9 | **Red 0.0** | Generated columns dropped to plain columns ×3; D29 enums; FK typing. |
| 1 DDL Schema | 7 | Amber 0.5 | 29 enum migrations; `created_by/updated_by` bigint vs `sys_users.id` INT. |
| 9 Performance | 7 | Amber 0.5 | `Schema::hasTable()` feature-flags; report N+1 (PERF-HST-001/002); 13 service calls/page. |
| 10 Queue/Job | 6 | Amber 0.5 | Scheduler central (no `tenants:run`); notification job is a Log stub. |
| 4 Code Quality | 4 | Amber 0.5 | Duplicate models, commented blocks, integration stubs. |
| 3 ORM | 2 | Amber 0.5 | Duplicate model→table; MessBill cast on a non-generated column. |
| 11 Frontend | 2 | Amber 0.5 | 278 views — not deeply scanned (out of priority scope); no `{!! $userField !!}` found in spot checks. |

Weighted Σ = 7.5+7+0+5.5+5+0+3.5+3.5+3+2+1+1 = **39**.

---

## Issue Code Allocation (continuing from current max per prefix)

Existing maxes in `known-issues.md`: SEC-HST-003, BUG-HST-005, PERF-HST-002, VAL-HST-001, DEAD-HST-001. New prefixes (DAT/MIG/JOB/ORM/TEN) start at 001.

| New Code | Sev | Title | File:Line |
|----------|-----|-------|-----------|
| DAT-HST-001 | P0 | Generated unique columns are inert plain columns → BR-HST-001/002 unenforced; concurrent double-allotment | `database/migrations/tenant/2026_06_15_153428_create_hst_allotments_table.php:23-24,44-45` + `AllotmentService.php` |
| MIG-HST-001 | P1 | `hst_mess_bills.total_amount` plain NOT-NULL not GENERATED → insert fails / BR-HST-025 unenforced | `…create_hst_mess_bills_table.php:29` + `Models/MessBill.php:16-46` |
| JOB-HST-001 | P1 | `hst:escalate-complaints` scheduled as bare central command; no per-tenant `tenants:run` → SLA escalation never runs per tenant | `Providers/HostelServiceProvider.php:150-160`, `Console/Commands/EscalateComplaintsCommand.php`, `Jobs/SendHstComplaintEscalationJob.php` |
| BUG-HST-006 | P1 | Parent-notification delivery is a stub — `SendHstNotificationJob::handle()` only `Log::info()`; 0 listeners | `Jobs/SendHstNotificationJob.php:40-46` |
| PERF-HST-003 | P1 | `Schema::hasTable()` used as runtime feature-flags (information_schema per request) | `Services/HostelFeeService.php:108,211,225`, `LeavePassService.php:209,260`, `HstAttendanceService.php:145`, `IncidentService.php:178` |
| SEC-HST-004 | P1 | 35 / 38 FormRequest `authorize()` return bare `true` (D30) | `app/Http/Requests/` (35 files) |
| DAT-HST-002 | P1 | Room/hostel occupancy counters use non-atomic read-modify-write, no lock → counter drift + missed `full` flip (BR-HST-010) | `Services/AllotmentService.php` (`create`/`transfer`/`vacate`) |
| VAL-HST-002 | P2 | BR-HST-015 (fee structure must exist before allotment) implemented as soft `Log::info`, not a hard block | `Services/HostelFeeService.php` (`validateFeeStructureExists`) |
| ORM-HST-001 | P2 | Duplicate model→table binding: `BedType` + `HstBedType` both → `hst_bed_types`, both live via different controllers | `Models/BedType.php:13`, `Models/HstBedType.php:14` |
| MIG-HST-002 | P2 | D29: 29 hst migrations use `->enum()` (~35 calls) instead of `sys_dropdown_table`/`hst_dynamic_status_masters` FK | `…create_hst_allotments_table.php:21`, `…create_hst_mess_bills_table.php:17` et al. |
| TEN-HST-001 | P2 | `RouteServiceProvider::mapApiRoutes()` registers api.php with only `api` middleware — no tenancy, no auth (latent; api.php empty) | `Providers/RouteServiceProvider.php:46` |
| BUG-HST-007 | P2 | `forwardToStudentFee()` hardcoded `return null` → fee demands computed/stored locally but never pushed to StudentFee (REQ-HST-019 integration stub) | `Services/HostelFeeService.php` (`forwardToStudentFee`) |
| DEAD-HST-002 | P3 | Commented-out Gate in `AuditLogController` (compounds DEAD-HST-001 / BUG-HST-005) | `Http/Controllers/AuditLogController.php:112` |

Counts (new this audit): **P0 = 1, P1 = 6, P2 = 5, P3 = 1.** Carried-open (already registered, re-confirmed live): SEC-HST-001/002/003, BUG-HST-001…005, PERF-HST-001/002, VAL-HST-001, DEAD-HST-001.

---

## P0 Findings

### DAT-HST-001 — Severity: P0 — Generated-column uniqueness silently defeated → concurrent double-allotment
- **Location:** `database/migrations/tenant/2026_06_15_153428_create_hst_allotments_table.php:23-24,44-45`; consumed by `Modules/Hostel/app/Services/AllotmentService.php`
- **Evidence (migration — columns are plain, not generated):**
  ```php
  $table->bigInteger('gen_active_bed_id')->nullable();
  $table->bigInteger('gen_active_student_id')->nullable();
  ...
  $table->unique('gen_active_bed_id', 'uq_hst_allot_active_bed');
  $table->unique('gen_active_student_id', 'uq_hst_allot_active_student');
  ```
- **Evidence (service believes the DB enforces it):**
  ```php
  // AllotmentService docblock:
  // Concurrency safety: relies on UNIQUE(gen_active_bed_id) and
  // UNIQUE(gen_active_student_id) generated columns on hst_allotments to
  // prevent double-allotment race conditions.
  ```
- **Confirmed:** No `storedAs`/`virtualAs`/`GENERATED ALWAYS` exists in ANY `hst_*` migration (grep returned 0). `AllotmentService` never assigns `gen_active_bed_id`/`gen_active_student_id` (only the docblock mentions them), and `Allotment.php` has no boot/saving hook. The columns are therefore permanently `NULL`. MySQL treats multiple `NULL`s as distinct, so both `UNIQUE` indexes enforce nothing.
- **Why it's a risk:** The DDL/D34 intent is `gen_active_bed_id = IF(is_alloted=1, bed_id, NULL)` STORED + UNIQUE — the DB-level guarantee for BR-HST-001 (one active allotment per bed) and BR-HST-002 (one active allotment per student). With the generated expression dropped, that guarantee is gone. There is also **no `lockForUpdate` anywhere in the module** (grep = 0), and the only app-level guard (`checkBedAvailability` reads `bed.statusMaster` before the transaction without a lock). Two concurrent allotments (two wardens / a double-submit) both read the bed as `available`, both insert, both commit → two students in one bed, or one student holding two beds. `translateDuplicateError()` waits for a MySQL 1062 that can never fire.
- **Fix:** Replace the two columns with STORED generated columns matching the DDL — `ALTER TABLE hst_allotments ADD gen_active_bed_id BIGINT GENERATED ALWAYS AS (IF(is_alloted=1 AND deleted_at IS NULL, bed_id, NULL)) STORED` (same for student) — via an additive tenant migration, keeping the existing UNIQUE index names. Add a defense-in-depth `lockForUpdate()` on the target bed row inside `AllotmentService::create()/transfer()` and re-check `is_alloted`. Verify the generated expression also nulls out soft-deleted rows.
- **Confidence:** High — defeated-constraint mechanism is provable from migration source + absence of any writer.
- **Systemic?:** Layer 2 (Migration↔DDL divergence); same root cause as MIG-HST-001. Candidate platform decision: "Laravel migrations dropped MySQL generated-column expressions present in the DDL masters."

---

## P1 Findings

### MIG-HST-001 — `hst_mess_bills.total_amount` is a plain NOT-NULL column, not GENERATED
- **Location:** `…create_hst_mess_bills_table.php:29`; `Modules/Hostel/app/Models/MessBill.php:16-46`
- **Evidence:**
  ```php
  // migration
  $table->decimal('total_amount', 10, 2);          // NOT NULL, no default, NOT generated
  // model — total_amount is in $casts but NOT in $fillable:
  'total_amount'  => 'decimal:2',
  ```
- **Why it's a risk:** D34 decision #3 and BR-HST-025 require `total_amount = base_charge + special_diet_charge − leave_credit − opt_out_credit + manual_adjustment` as `GENERATED ALWAYS`. The model deliberately omits it from `$fillable` (treats it as generated, never writes it). But the column is a `NOT NULL` plain decimal with no default, so any `MessBill::create([...])` without `total_amount` fails with SQLSTATE 1364 *"Field 'total_amount' doesn't have a default value"* under strict mode. And because it is not generated, BR-HST-025 ("system-computed, cannot be manually overwritten") is unenforced.
- **Fix:** Make it `decimal GENERATED ALWAYS AS (base_charge + special_diet_charge - leave_credit - opt_out_credit + manual_adjustment) STORED` in an additive migration. Keep it out of `$fillable`.
- **Confidence:** High (schema). The runtime INSERT failure is conditional on a mess-bill create path executing (a billing-compute path was not located in this pass).
- **Systemic?:** Same root cause as DAT-HST-001.

### JOB-HST-001 — Complaint SLA escalation scheduled in central context, never runs per tenant
- **Location:** `Providers/HostelServiceProvider.php:150-160`; `Console/Commands/EscalateComplaintsCommand.php`; `Jobs/SendHstComplaintEscalationJob.php`
- **Evidence:**
  ```php
  $schedule->command('hst:escalate-complaints')->hourly()
           ->withoutOverlapping(60)->onOneServer()->name('hst-escalate-complaints');
  ```
  The command's default mode runs `HstComplaintService::checkSlaBreaches()` **inline** (no `--queue`), querying tenant `hst_complaints`. Neither the command, the job, nor the schedule re-initialises tenancy.
- **Why it's a risk:** Run from the central scheduler, the sweep executes once against central context (no `hst_complaints` there) — BR-HST-020 SLA auto-escalation never fires for any tenant. The code's own docblocks acknowledge it "must be invoked via `tenants:artisan`" / wrapped with `tenants:run`, but the registered schedule does not do this. (Idempotency flags `withoutOverlapping`/`onOneServer` are correct.)
- **Fix:** Schedule via a per-tenant wrapper (`tenants:run hst:escalate-complaints` or the platform tenant-scheduler), or move scheduling into a tenant-aware scheduler. `SendHstComplaintEscalationJob` should also accept a `$tenantId` and re-init tenancy in `handle()`; add `$backoff`.
- **Confidence:** High.
- **Systemic?:** Layer 10.2 (matches the auditor's documented Hostel example).

### BUG-HST-006 — Parent-notification delivery is a logging stub (core safety value not delivered)
- **Location:** `Jobs/SendHstNotificationJob.php:40-46`
- **Evidence:**
  ```php
  public function handle(): void {
      // Phase 5 will replace this with NotificationService::trigger()...
      Log::info('[SendHstNotificationJob stub]', [ 'event' => $this->eventCode, 'context' => $this->context ]);
  }
  ```
- **Why it's a risk:** All 7 domain events fire (`LeavePassApproved::dispatch`, `HostelAbsenceDetected::dispatch`, `HostelIncidentRecorded::dispatch`, `SickBayAdmissionRecorded::dispatch`, etc.) and route to this single job, which only writes a log line. There is **no `Listeners/` directory** and `EventServiceProvider::$listen = []`, so nothing else consumes the events. The module's central value proposition — parent alerts for absence (BR-HST-017), overdue return (BR-HST-031), moderate/serious incidents (BR-HST-008), and sick-bay admission/discharge (BR-HST-049) — is non-functional. The job *is* otherwise well-configured (`$tries=3,$backoff=10,$timeout=60`).
- **Fix:** Implement `handle()` against `Modules\Notification`'s `NotificationService::trigger()`; add tenancy re-init (constructor `$tenantId`) since this is a queued tenant job. Track as the Phase-5 completion gate.
- **Confidence:** High. (By-design "Phase 5" stub — still a real release blocker for go-live.)
- **Systemic?:** Module-local; intersects Layer 10 tenancy (job has `tenancy=0`).

### PERF-HST-003 — `Schema::hasTable()` used as runtime feature-flags
- **Location:** `Services/HostelFeeService.php:108,211,225`; `LeavePassService.php:209,260`; `HstAttendanceService.php:145`; `IncidentService.php:178`
- **Evidence:** `if (! \Schema::hasTable('hst_fee_demands')) { return; }` etc.
- **Why it's a risk:** Each call hits `information_schema` per request, per tenant — on the fee-push, leave-approval, attendance and incident hot paths. All referenced tables (`hst_fee_demands`, `hst_fee_structures`, `hst_mess_attendance`, `hst_incidents`, `hst_leave_passes`) already ship as migrations, so the guards are dead introspection cost.
- **Fix:** Replace with a cached config/feature flag or remove (the tables exist). Matches the auditor's documented Hostel example verbatim.
- **Confidence:** High.
- **Systemic?:** Layer 9.4 platform pattern (Hostel, Dashboard, Marksheet).

### SEC-HST-004 — 35 of 38 FormRequests `authorize()` return bare `true` (D30)
- **Location:** `Modules/Hostel/app/Http/Requests/` (35 of 38 files)
- **Why it's a risk:** Defense-in-depth collapses to controller gates only. Where a controller forgets/comments a gate (already happening — `AuditLogController:112`, DEAD-HST-002), the FormRequest provides zero fallback. This is the platform norm (baseline 437/485) — report as systemic, but it escalates to P0 for any specific request whose controller action is also ungated.
- **Fix:** Each `authorize()` returns `Gate::allows('tenant.hostel.<entity>.<action>')` matching the route; keep controller gates too.
- **Confidence:** High.
- **Systemic?:** D30.

### DAT-HST-002 — Non-atomic occupancy counters (room/hostel) with no lock
- **Location:** `Services/AllotmentService.php` — `create()`, `transfer()`, `vacate()`
- **Evidence:**
  ```php
  $newOccupancy = $room->current_occupancy + 1;   // read
  $roomUpdate   = ['current_occupancy' => $newOccupancy];
  if ($newOccupancy >= $room->capacity) { $roomUpdate['status'] = $fullRoomStatusId; }
  $room->update($roomUpdate);                       // write (lost-update race)
  ```
- **Why it's a risk:** Read-modify-write on `hst_rooms.current_occupancy` (and the same pattern on vacate/transfer) is not atomic and not locked. Two concurrent allotments into different beds of the same room both read N, both write N+1 → counter drifts low and the room may never flip to `full` (BR-HST-010), surfacing a "free" capacity that does not exist. (`hst_hostels` correctly uses atomic `increment()/decrement()` — only the room counter is unsafe.)
- **Fix:** Use atomic `$room->increment('current_occupancy')` and compute `full` from a re-read inside a `lockForUpdate()`, or recompute occupancy from `COUNT(is_alloted=1)` like `bulkVacate()` already does for the hostel total.
- **Confidence:** High.
- **Systemic?:** Layer 8.2 (locking-gap class noted for Hostel in the agent doc).

---

## P2 Findings

### VAL-HST-002 — BR-HST-015 fee-structure check is a soft log, not a hard block
- **Location:** `Services/HostelFeeService.php` — `validateFeeStructureExists()`
- **Evidence:** `if (! $this->lookupFeeStructure(...)) { Log::info('… no structure found …'); }` — returns void, never throws.
- **Why it's a risk:** FRD REQ-HST-008 AC#3 and BR-HST-015 (Validation) require allotment to be **blocked** when no fee structure exists for the room-type+meal-plan. As implemented it logs and proceeds, so allotments without a fee basis are created. (The dev plan calls it advisory — but the FRD/BR classify it Validation; this is a documented BR-enforcement gap.)
- **Fix:** Throw a domain exception (or make hard/soft configurable per `sys_settings`) so the allotment transaction aborts.
- **Confidence:** High.

### ORM-HST-001 — Duplicate model→table binding (`BedType` + `HstBedType` → `hst_bed_types`)
- **Location:** `Models/BedType.php:13`, `Models/HstBedType.php:14`
- **Evidence:** both `protected $table = 'hst_bed_types';`. `BedType` is used by `HostelSetupController`, `BedTypeController`; `HstBedType` is used by the `Bed` model relationship (`beds()` on FK `bed_type`) and `BedController`. Both are live, via different screens.
- **Why it's a risk:** Two CRUD entry points and two model identities for one table; only `HstBedType` carries the `beds()` relationship and the `Bed.bed_type` FK mapping. Future fillable/casts edits to one will silently not apply to the other.
- **Fix:** Keep `HstBedType` (it owns the relationship), make `BedType` a deprecated alias or delete it and repoint `HostelSetupController`/`BedTypeController`.
- **Confidence:** High.
- **Systemic?:** Known gap G3; the agent doc's canonical duplicate-binding example.

### MIG-HST-002 — D29: 29 hst migrations use `->enum()`
- **Location:** 29 files, e.g. `…create_hst_allotments_table.php:21` (`vacation_reason`), `…create_hst_mess_bills_table.php:17` (`meal_plan`)
- **Why it's a risk:** ENUM locks option sets at DDL level against the platform's own `sys_dropdown_table`/`hst_dynamic_status_masters` pattern; schools can't extend without a per-tenant migration. Hostel is the platform's top enum offender (~35 calls).
- **Fix:** Migrate `vacation_reason`, `meal_plan`, and other pick-lists to `_id` FK → `hst_dynamic_status_masters`/`sys_dropdown_table`. (Deferred-to-v4 item in D34.)
- **Confidence:** High.
- **Systemic?:** D29.

### TEN-HST-001 — API route group registered without tenancy or auth (latent)
- **Location:** `Providers/RouteServiceProvider.php:46`
- **Evidence:** `Route::middleware('api')->prefix('api')->name('api.')->group(.../routes/api.php);`
- **Why it's a risk:** Unlike `mapWebRoutes()` (which has the full `InitializeTenancyByDomain`/`PreventAccessFromCentralDomains`/`EnsureTenantIsActive`/`auth`/`verified` stack), the API group has only `api`. `api.php` is currently empty so there is no exploit today, but the Phase-7 dashboard/attendance endpoints reserved there would be unauthenticated and tenancy-less if added as-is.
- **Fix:** Add the tenancy + `auth:sanctum` stack to `mapApiRoutes()` before any route lands in `api.php`.
- **Confidence:** High (latent).

### BUG-HST-007 — Fee demands never forwarded to StudentFee (integration stub)
- **Location:** `Services/HostelFeeService.php` — `forwardToStudentFee()`
- **Evidence:** method body hardcodes `return null;` ("Phase 7 will pass the right payload").
- **Why it's a risk:** REQ-HST-019 requires hostel charges (rent/mess/electricity/laundry/deposit, room-change differential, vacating refund, damage) to be pushed to the fee system. They are computed and persisted in `hst_fee_demands` but never reach `StudentFee`, so no hostel charge is ever actually billed. Local-only audit means reconciliation must be done by hand.
- **Fix:** Wire `FeeInvoiceService` integration; until then surface the pending demands in an admin reconciliation screen.
- **Confidence:** High. (By-design Phase-7 gap — release blocker for fee operations.)

---

## P3 Findings

### DEAD-HST-002 — Commented-out Gate in AuditLogController
- **Location:** `Http/Controllers/AuditLogController.php:112`
- **Evidence:** `//     Gate::authorize('tenant.hostel.viewAny');`
- **Why it's a risk:** Compounds DEAD-HST-001 (50+ lines of commented code) and BUG-HST-005 (missing `destroy` behind a resource DELETE route). Dead/commented protection signals incomplete work on an audit-log surface.
- **Fix:** Remove the commented block; restore the gate if the action is live.
- **Confidence:** High.

---

## Layer Health Summary

| Layer | RAG | Key finding |
|-------|-----|-------------|
| 1 DDL Schema | Amber | 29 enum migrations; created_by/updated_by bigint vs sys_users INT. |
| 2 Migration↔Model↔DDL | **Red** | DAT-HST-001 (gen columns inert), MIG-HST-001 (mess_bills total_amount). |
| 3 Model/ORM | Amber | ORM-HST-001 duplicate model; MessBill cast on non-generated col. |
| 4 Code Quality | Amber | Commented blocks (DEAD-HST-001/002), integration stubs (BUG-HST-006/007). |
| 5 Authorization | Amber | 7 ungated report controllers (SEC-HST-001/002/003); D30 (SEC-HST-004); commented gate. |
| 6 Multi-Tenancy | Amber | Web stack correct; api group lacks tenancy/auth (TEN-HST-001, latent); scheduler central. |
| 7 Validation/Mass-assign | Amber | No `$request->all()`; 35/38 FormRequests true; BR-HST-015 soft. |
| 8 Data Integrity/Tx | **Red** | DAT-HST-001 (P0), DAT-HST-002, no `lockForUpdate`. |
| 9 Performance | Amber | PERF-HST-003 Schema flags; PERF-HST-001/002 report N+1. |
| 10 Queue/Job | Amber | JOB-HST-001 central scheduler; BUG-HST-006 notification stub. |
| 11 Frontend | Amber | 278 views not deeply scanned; no raw user-string output found in spot checks. |
| 12 Deployment | Amber | No new HST-specific blocker; inherits platform queue/Horizon + committed-env P0s. |

---

## FRD / Business-Rule cross-reference (selected)

| BR | Intent | Status | Evidence |
|----|--------|--------|----------|
| BR-HST-001/002 | One active allotment per bed / per student | **MISSING (DB) / partial (app)** | Generated-UNIQUE inert (DAT-HST-001); only a non-locked status pre-check. |
| BR-HST-010 | Room auto Full/Available on occupancy | PARTIAL | Counter non-atomic (DAT-HST-002). |
| BR-HST-011 | Prorated fee = rate/30 × remaining days | ENFORCED | `HostelFeeService::calculateProratedAmount()` matches. |
| BR-HST-015 | Fee structure must exist before allotment | PARTIAL | Soft log only (VAL-HST-002). |
| BR-HST-020 | Complaint SLA auto-escalation | PARTIAL | Logic exists but scheduled central (JOB-HST-001). |
| BR-HST-025 | Mess bill total system-computed, not overwritable | MISSING (DB) | Column not GENERATED (MIG-HST-001). |
| BR-HST-008/017/031/049 | Parent notifications | MISSING (delivery) | Job is a Log stub (BUG-HST-006). |

---

## vs Platform Baseline

| Metric | Platform | Hostel | Verdict |
|--------|----------|--------|---------|
| FormRequests `return true` | 90% | 35/38 (92%) | Typical (systemic). |
| `$request->all()` into models | 24 sites | **0** | Better than norm. |
| `->enum()` in migrations | hst = 28 | **29 files / ~35 calls** | Top offender (as documented). |
| Duplicate model→table | Hostel BedType/HstBedType | Confirmed | The canonical example. |
| Jobs missing tenancy init | Hostel flagged | 2/2 jobs tenancy=0 | As documented. |
| Defeated generated-column UNIQUE | — | **New (DAT-HST-001)** | Above baseline — module-specific P0. |

---

## Recommended Fix Order

1. **DAT-HST-001 (P0)** — additive migration converting `gen_active_bed_id`/`gen_active_student_id` to STORED generated columns; add `lockForUpdate` in `AllotmentService`. Unblocks the core safety invariant.
2. **MIG-HST-001 (P1)** — make `hst_mess_bills.total_amount` GENERATED. Unblocks mess billing.
3. **DAT-HST-002 (P1)** — atomic room occupancy counters.
4. **BUG-HST-006 + JOB-HST-001 (P1)** — implement notification delivery + per-tenant scheduling (the module's safety + SLA promises).
5. **PERF-HST-003 / SEC-HST-004 (P1)** — drop Schema-flag introspection; harden FormRequest `authorize()`.
6. **P2 batch** — VAL-HST-002 hard block, ORM-HST-001 dedup, MIG-HST-002 enum→FK, TEN-HST-001 api middleware, BUG-HST-007 StudentFee wiring.
7. **DEAD-HST-002 (P3)** — cleanup alongside existing DEAD-HST-001 / BUG-HST-005.

> Owner handoff: P0/P1 schema → **DB Architect** (generated-column migrations); P1 app logic → **Developer** (locks, notification, scheduler); completeness scoring → **Status_Analyzer** using `HST_FRD_2026-06-29.md` as denominator.

---
*Read-only audit. No application code modified. Findings registered for orchestrator consolidation into `known-issues.md` (not written here per parallel-run protocol).*
