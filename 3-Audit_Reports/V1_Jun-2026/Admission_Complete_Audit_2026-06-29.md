# Complete Audit — Admission (ADM) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** Admission Management | **Code:** ADM | **Prefix:** `adm_` | **Layer:** Tenant
**App dir:** `/Users/bkwork/Herd/prime_ai/Modules/Admission`
**Baseline (B/C):** `4-Requirement_Module_wise/0-FRD_Documents/ADM_FRD_Complete_2026-06-29.md` (21 REQ / 22 BR / 8 RPT)
**Schema source:** `2-DDL_Tenant_Consolidated/Admission_DDL_v1.sql` (20 tables) + **20 live tenant migrations** (see correction).
**Auditor:** Technical Auditor (pa-technical-auditor, Mode X)

---

## Executive Summary

ADM is feature-broad and architecturally above the platform norm on the two highest-weight layers — **tenancy is correct** (full `InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive → auth → verified` stack in the module `RouteServiceProvider`) and **every domain controller gates its actions** with `Gate::authorize('tenant.adm-*.*')`. The worst finding is a **data-layer / FSM divergence**: `AdmissionPipelineService` transitions applications to `'Under Review'` and `'Selected'`, neither of which exists in the `adm_applications.status` ENUM, and `'Selected'` is the mandatory pre-state for `Enrolled` — so the documented core enrolment pipeline (REQ-ADM-015) cannot complete. Combined with an **unenforced seat-allotment guard** (BR-ADM-013 — over-allotment possible; the cited `MeritListService::allotSeat()` does not exist), **plaintext Aadhar/PII** (NFR-ADM-005), and **broken merit scoring** (interview dropped, weights hardcoded to 110%, no cut-off/waitlist logic), the module is **NOT deployable as-is**. Overall health **40/100 (P0 cap applied)**; **DEPLOY: NO-GO**.

---

## Health Score

| | |
|---|---|
| Weighted layer index (uncapped) | ~63/100 |
| **P0 present** | **Yes → hard cap 40** |
| **Final health** | **40 / 100 (capped)** |

Cap rationale: BUG-ADM-004 (FSM/ENUM divergence blocks enrolment) is a P0-class data/workflow defect.

---

## Deploy Gate Verdict (Mode G)

**NO-GO.** Blocking items:
- **BUG-ADM-004** (P0) — application status FSM writes ENUM values that don't exist → enrolment pipeline broken (runtime `Data truncated for column 'status'` under MySQL strict mode; FSM guard makes `Enrolled` unreachable).
- **SEC-ADM-001** (P1→deploy blocker) — Aadhar PII stored in clear (PDPB/compliance exposure on a production tenant).
- **DATA-ADM-001** (P1→deploy blocker) — seat over-allotment guard absent (oversell of seats).

Non-blocking but required before release: BUG-ADM-005/006/007, VAL-ADM-001/002, JOB-ADM-001.

Deploy-safety items that PASS for this module: tenancy stack present; all web routes behind `auth`+`verified`; API behind `auth:sanctum`; no module-level committed secrets; no `dd()/dump()`; no route closures in module routes; no cross-DB FK (`sys_dropdowns`/`sys_roles`) in ADM migrations; PK uses `id()` (no `increments('id')`).

---

## P0 Findings

### [BUG-ADM-004] Severity: P0 | Application FSM uses status values absent from the `adm_applications.status` ENUM → enrolment pipeline cannot complete
- **Location:** `app/Services/AdmissionPipelineService.php:18-28` (FSM map); consumed by `:96-98` (`startReview`→`'Under Review'`), `:120-123` (`select`→`'Selected'`); `database/migrations/tenant/2026_06_16_083610_create_adm_applications_table.php:59` (ENUM); `app/Services/EnrollmentService.php:155` (`transition(...,'Enrolled')`).
- **Evidence:**
    - Migration ENUM: `enum('status', ['Allotted','Draft','Enrolled','Rejected','Shortlisted','Submitted','Under_Review','Verified','Waitlisted','Withdrawn'])`
    - FSM constant: `'Submitted' => ['Under Review', 'Rejected'], 'Under Review' => [...], 'Shortlisted' => ['Selected', ...], 'Selected' => ['Enrolled','Withdrawn']`
    - `'Under Review'` (space) ≠ ENUM `'Under_Review'` (underscore); `'Selected'` is **not in the ENUM at all**.
- **Why it's a risk:** Transitioning to `'Under Review'`/`'Selected'` writes a value the ENUM rejects → under MySQL strict mode (`STRICT_TRANS_TABLES`, Laravel default) the `UPDATE` throws `SQLSTATE[01000]: Data truncated for column 'status'`; under non-strict it silently stores `''`. Worse, `EnrollmentService::enrollStudent()` calls `transition($application,'Enrolled')`, whose only allowed source is `'Selected'` — a state the FSM can never durably reach — so enrolment (REQ-ADM-015, a P0 requirement) fails inside the `DB::transaction` and rolls back. ENUM values `'Verified'` and `'Allotted'` are never produced by the FSM (dead states).
- **Fix:** Reconcile one source of truth. Align the FSM constants to the exact ENUM tokens (`'Under_Review'`, and replace `'Selected'` with the intended `'Allotted'`/`'Verified'`), or migrate the ENUM (preferably to a `sys_dropdown` FK per D29) to include the FSM's vocabulary. Add a test that drives Draft→…→Enrolled end-to-end.
- **Confidence:** High (ENUM list and FSM map both read verbatim).
- **Systemic?:** Module-local FSM/ENUM divergence (related to D29 ENUM usage); also a Layer-2 three-way mismatch class.

---

## P1 Findings

### [DATA-ADM-001] Severity: P1 | Seat-allotment over-allotment guard (BR-ADM-013) not enforced; cited service method does not exist
- **Location:** `app/Http/Controllers/AllotmentController.php:60-74` (`store`); `app/Services/MeritListService.php` (no `allotSeat()` — only `computeScores`/`publish`).
- **Evidence:** `store()` does `$allotment = Allotment::create($validated)` with no read of `adm_seat_capacity`, no `seats_allotted`/`total_seats` comparison, and no `lockForUpdate`. The FRD/module-knowledge cite enforcement at `MeritListService::allotSeat()`; that method is absent. `seats_allotted` is never incremented anywhere (only `seats_enrolled`, at enrolment).
- **Why it's a risk:** Quota seat budgets can be exceeded (oversell); two concurrent allotments race with no lock. BR-ADM-013 / REQ-ADM-011 acceptance ("allotment refused once allotted seats reach the quota budget") is unmet.
- **Fix:** In `store()` (inside a transaction) `lockForUpdate()` the matching `adm_seat_capacity` row, assert `seats_allotted < total_seats`, increment `seats_allotted` atomically; on decline/withdraw decrement it.
- **Confidence:** High.
- **Systemic?:** Locking-gap class (Layer 8.2).

### [BUG-ADM-005] Severity: P1 | `admission_no` never generated at offer/allotment; offer-letter PDF streams a NULL admission number
- **Location:** `app/Http/Controllers/AllotmentController.php:60-74` (`store`), `:150-159` (`offerLetter` → `"offer-letter-{$allotment->admission_no}.pdf"`); generation lives only in `app/Services/EnrollmentService.php:185-204` (enrolment time).
- **Evidence:** `store()` never sets `admission_no`; there is no `activate`/`issue-offer` action that assigns it. `offerLetter()` builds the filename from `$allotment->admission_no`, which is NULL until enrolment.
- **Why it's a risk:** BR-ADM-003 / REQ-ADM-011 require a unique admission number generated when the offer is issued; today the offer letter carries no admission number and the number is minted only after enrolment.
- **Fix:** Generate `admission_no` (from `cycle.admission_no_format`) when the offer is issued / allotment created, with a uniqueness-safe sequence; reuse it at enrolment.
- **Confidence:** High.

### [SEC-ADM-001] Severity: P1 | Aadhar / sensitive PII stored in plaintext (NFR-ADM-005, NFR-ADM-010, RISK-ADM-004)
- **Location:** `app/Models/Application.php:59` (`aadhar_no` fillable), `:103-114` (`$casts` — no `encrypted`); propagated plaintext at `app/Services/EnrollmentService.php:103` (`'aadhar_id' => $application->aadhar_no`). Other sensitive fields also clear: `student_caste_category`, `blood_group`, `known_allergies`, `student_religion`.
- **Evidence:** `$casts` contains dates/decimals/booleans only — no `'aadhar_no' => 'encrypted'`. DDL/migration store `aadhar_no VARCHAR(20)` plain (`...083610...:29`).
- **Why it's a risk:** PDPB/privacy exposure of Aadhar at rest; any DB read or backup leaks raw identifiers. NFR mandates AES-256 at rest and role-restricted access.
- **Fix:** Add `'aadhar_no' => 'encrypted'` cast (and on `std_students.aadhar_id`); restrict read access by policy; consider a blind-index column for the service-layer uniqueness check (see VAL-ADM-002).
- **Confidence:** High.

### [BUG-ADM-006] Severity: P1 | Merit scoring is incorrect: interview excluded, weights hardcoded to 110%, no cut-off / seat-based waitlist (REQ-ADM-010, BR-ADM-010c, BR-ADM-010d)
- **Location:** `app/Services/MeritListService.php:56-103`.
- **Evidence:**
    - `$interviewScore = ... * 0.30;` (`:68`) is computed and stored to the row but **omitted from** `$composite = round($academicScore + $entranceScore + $siblingBonus, 2);` (`:72`).
    - Weights are hardcoded `0.40 + 0.40 + 0.30 = 1.10`; `cycle->criteria_json` / `MeritList.criteria` (the configurable weights) is never read.
    - Every entry is written `'merit_status' => 'Shortlisted'` (`:83`) regardless of `cutoff_score` or seat count — no Rejected-below-cutoff (BR-ADM-010d) and no seat-based Waitlist (REQ-ADM-010 AC).
- **Why it's a risk:** Ranking is wrong (interview contribution lost; composite can exceed 100) and the legally/operationally significant cut-off and waitlist outcomes are never applied. `StoreMeritListRequest`/`UpdateMeritListRequest` also do not validate weights sum to 100 (BR-ADM-010c).
- **Fix:** Drive weights from `criteria_json`, validate they sum to 100 in the FormRequest, include interview in the composite, and set `merit_status` to Shortlisted/Waitlisted/Rejected by rank-vs-seats and composite-vs-cutoff.
- **Confidence:** High.

### [BUG-ADM-007] Severity: P1 | Transfer-Certificate fee-clearance gate (BR-ADM-004) is a stub — TC issues with outstanding fees
- **Location:** `app/Services/TransferCertificateService.php:38-44`.
- **Evidence:**
    ```php
    if (! $tc->fees_cleared) {
        // TODO: replace with real fin_invoices balance check when StudentFee is complete
        Log::warning("TC issued for student #{$student->id} with fees_cleared=false — manual override.", [...]);
    }
    ```
    Execution continues into the issue transaction regardless. No `fin_invoices` query exists anywhere in the module (only comments).
- **Why it's a risk:** BR-ADM-004 / REQ-ADM-017 require blocking TC issuance while fees are outstanding; the gate is bypassed.
- **Fix:** Replace the warning with `throw_unless($tc->fees_cleared || $finBalance <= 0, ...)`; integrate the StudentFee balance read.
- **Confidence:** High.

### [JOB-ADM-001] Severity: P1 | Waitlist auto-promotion / offer expiry not built (REQ-ADM-013, BR-ADM-014)
- **Location:** No `app/Jobs/`, no `app/Console/`, no scheduled command (`find` returns none). `AdmissionPipelineService::promoteWaitlisted()` exists but is never invoked. `AllotmentController::decline()` (`:124-136`) sets status `Declined` but does not free the seat or promote the next waitlisted candidate.
- **Evidence:** No `adm:expire-offers` command; `offer_expires_at` is never evaluated.
- **Why it's a risk:** Expired/declined offers strand seats; the next candidate is never promoted/notified.
- **Fix:** Add a daily `adm:expire-offers` command (per-tenant via `tenants:run`) that expires past-deadline offers and calls `promoteWaitlisted()`; wire decline to free the seat and trigger promotion.
- **Confidence:** High.

### [VAL-ADM-001] Severity: P1 | Age-eligibility rule (BR-ADM-001) not enforced — claimed Yes, actually absent
- **Location:** `app/Http/Requests/StoreApplicationRequest.php:31` (`student_dob` → `['required','date']`), `StoreEnquiryRequest.php:21` (`['nullable','date']`); `AdmissionCycle` stores `age_rules_json` (`Models/AdmissionCycle.php:28,41`) but it is read nowhere.
- **Evidence:** No `min_age`/`max_age`/`diffInYears`/cut-off-date logic in any request, controller, or service.
- **Why it's a risk:** The FRD lists BR-ADM-001 as "Built" (warning on out-of-range age); no warning or check exists. Out-of-range applicants pass silently.
- **Fix:** Add a `withValidator`/service warning comparing DOB against the class min/max on the cycle cut-off date.
- **Confidence:** High.

### [VAL-ADM-002] Severity: P1 | Aadhar service-layer uniqueness (BR-ADM-012) not implemented
- **Location:** Application create path — `ApplicationController::store`, `AdmissionPipelineService`; no `aadhar` uniqueness query exists (only the plaintext copy at `EnrollmentService.php:103`).
- **Evidence:** DDL intentionally keeps `aadhar_no` non-unique at DB level ("uniqueness enforced at SERVICE LAYER ONLY"), but no service performs the check.
- **Why it's a risk:** Duplicate-Aadhar warning (BR-ADM-012) never fires; the documented compensating control for the non-unique index is missing.
- **Fix:** On application save, query existing `aadhar_no` within the cycle and surface a non-blocking warning (use a blind index if encryption per SEC-ADM-001 is added).
- **Confidence:** High.

### [SEC-ADM-003] Severity: P1 (systemic, D30) | All 24 FormRequests `authorize()` return hardcoded `true`
- **Location:** `app/Http/Requests/*.php` — 24/24 (e.g. `StoreApplicationRequest.php:11-14`, `StoreMeritListRequest.php:11-14`, `StoreEntranceTestRequest.php:11-14`).
- **Evidence:** `public function authorize(): bool { return true; }` in every request.
- **Why it's a risk:** Defense-in-depth gap (D30). **Downgraded from P0** because every consuming controller action does call `Gate::authorize('tenant.adm-*.*')`, so the request-layer `true` is not the sole gate.
- **Fix:** Return `Gate::allows('tenant.adm-<entity>.<action>')` matching the route.
- **Confidence:** High.
- **Systemic?:** D30 (platform baseline 437/485 ≈ 90%).

---

## P2 Findings

### [DATA-ADM-002] Severity: P2 | Number generators and enrolment lack row locks (race → duplicate / double-enrol)
- **Location:** `app/Models/Application.php:19-38` (`boot()` read-max-then-create `application_no`); `app/Services/EnrollmentService.php:185-204` (`generateAdmissionNo` read-max), `:61-65` (`enrolled_student_id===null` guard with no `lockForUpdate` on `$allotment`).
- **Why it's a risk:** Concurrent submissions can mint the same number (unique index then throws), and two concurrent enrol POSTs can both pass the "already enrolled" guard → double student creation.
- **Fix:** `lockForUpdate()` the allotment in `enrollStudent`; use an atomic sequence/`lockForUpdate` for number generation.
- **Confidence:** Medium (race requires concurrency).

### [SEC-ADM-002] Severity: P2 | TC PDF written to `Storage::disk('local')` with an un-prefixed path; `media_id` never persisted
- **Location:** `app/Services/TransferCertificateService.php:65-66` (`Storage::disk('local')->put("tc/tc_{$tc->tc_number}.pdf", ...)`).
- **Why it's a risk:** Explicit `disk('local')` may bypass the tenant filesystem bootstrapper; path is not tenant-prefixed → potential cross-tenant overwrite/leak of TC PDFs. The DDL `media_id` is never written despite the comment.
- **Fix:** Store via the tenant disk / `tenant_asset`, persist the resulting `media_id`.
- **Confidence:** Medium.

### [DATA-ADM-003] Severity: P2 (systemic, D29) | 29 `->enum()` columns in ADM migrations instead of `sys_dropdown` FKs
- **Location:** ADM tenant migrations — `status` ×8, `quota_type` ×4, `result` ×2, `student_gender` ×2, plus `blood_group`, `student_caste_category`, `lead_source`, `follow_up_type`, `outcome`, `merit_status`, `verification_status`, `severity`, `incident_type`, `action_type`, `conduct`, `reason`, `refund_status`.
- **Why it's a risk:** D29 — pick-from-list values hardcoded in schema; not centrally manageable; couples to the FSM-divergence bug (BUG-ADM-004).
- **Fix:** Migrate to `*_id` FK → `sys_dropdown_table` over time.
- **Confidence:** High.
- **Systemic?:** D29 (baseline ~476 platform-wide).

### [BUG-ADM-008] Severity: P2 | Notifications entirely unimplemented; not event-driven (RISK-ADM-005)
- **Location:** Module-wide — zero `Notification`/`Mail`/`notify()` usage; `app/Providers/EventServiceProvider.php:14` `$listen = []`; no `Events/`/`Listeners/`/`Jobs/`.
- **Why it's a risk:** Coverage table marks Notification=Yes for REQ-ADM-004/005/008/011/012/018 (enquiry ack, follow-up reminder, interview schedule, offer letter, fee confirmation, critical-incident alert) — none are dispatched. BR-ADM-018b (Critical incident → parent+principal) and BR-ADM-022 (follow-up reminder once) cannot fire.
- **Fix:** Introduce domain events + listeners dispatching via the Notification module.
- **Confidence:** High.

### [DEAD-ADM-001] Severity: P2 | Stub `AdmissionController` apiResource wired to a live (auth) route
- **Location:** `app/Http/Controllers/AdmissionController.php:29,50,55` (`store`/`update`/`destroy` empty `{}`; `index`/`create`/`show`/`edit` return `admission::index|create|show|edit` views that likely don't exist); `routes/api.php:6-8` (`auth:sanctum` apiResource).
- **Why it's a risk:** Live but non-functional endpoints; write methods silently no-op (HTTP 200, no persistence). Not an auth hole (gated + empty bodies) but misleading dead surface.
- **Fix:** Implement or remove the apiResource.
- **Confidence:** High.

### [PERF-ADM-001] Severity: P2 | Merit-list `lockForUpdate` is on the compute step, not the allotment step
- **Location:** `app/Services/MeritListService.php:46-49` (locks `adm_seat_capacity` during `computeScores`, which does not allot).
- **Why it's a risk:** The lock protects a read-only ranking operation while the actual seat-consuming path (AllotmentController) holds no lock (see DATA-ADM-001) — protection is in the wrong place.
- **Fix:** Move the seat-row lock to the allotment transaction.
- **Confidence:** High.

---

## P3 Findings

- **[DEAD-ADM-002] Comment/behaviour drift in EnrollmentService.** `:165-168` comment says "Decrement seats_filled" but code `increment('seats_enrolled')`; `:158-162` sets merit entry `'merit_status' => 'Shortlisted'` though the docblock (step 11) says set to Enrolled. Confusing but not harmful. Confidence High.
- **0 automated tests (RISK-ADM-006).** `tests/Unit` & `tests/Feature` hold only `.gitkeep`; 25 scenarios specified, none implemented. High-risk untested paths: EnrollmentService cross-module rollback, MeritListService scoring, Application FSM, Promotion idempotency. (Hand to Testing Architect.) Confidence High.

---

## Layer Health Summary

| Layer | Status | Key finding |
|-------|:------:|-------------|
| 1 DDL Schema | Amber | 29 `->enum()` (D29); otherwise conventions OK (PK `id()`, no cross-DB FK) |
| 2 Migration↔Model↔DDL | **Red** | BUG-ADM-004 status-ENUM vs FSM divergence; *correction:* 20 migrations DO exist |
| 3 ORM | Green | Casts/relations sound; no duplicate model→table; boot() number-gen unlocked (P2) |
| 4 Code Quality | Green | No `dd()`/dump; 1 stub apiResource (DEAD-ADM-001); largest controller 432 LOC |
| 5 Authorization | Green | Every domain controller `Gate::authorize('tenant.adm-*.*')`; consistent prefix |
| 6 Tenancy | Green | Full tenancy+auth+verified stack in module RouteServiceProvider (D23 compliant) |
| 7 Validation/Mass-assign | Amber | D30 (24/24 `authorize() true`); missing age (BR-001) & aadhar (BR-012) checks; no `$request->all()` into models |
| 8 Data Integrity/Tx | **Red** | Over-allotment guard absent (DATA-ADM-001); enrolment/number-gen unlocked; TC fee gate stub |
| 9 Performance | Green | Pagination on lists; eager-loads present; misplaced lock (PERF-ADM-001) |
| 10 Queue/Job | Amber | No jobs/scheduler → REQ-ADM-013 waitlist auto-promotion unbuilt |
| 11 Frontend | Green | No obvious raw-output XSS / client secrets observed in module routes/controllers |
| 12 Deployment | Amber | No module secrets / closures; blocked by P0/P1 above → NO-GO |

---

## STEP 1 Reading-Discipline Output (snapshot corrections + reconcile)

| Claim (FRD / module-knowledge) | Live-code reality | Action |
|--------------------------------|-------------------|--------|
| "0 migrations; schema via DDL only" | **20 ADM tenant migrations exist** (`database/migrations/tenant/2026_06_16_0836*_create_adm_*_table.php`) | **Corrected** — knowledge file updated |
| BR-ADM-013 enforced in `MeritListService::allotSeat()` | Method **does not exist**; AllotmentController::store has no guard | Logged as DATA-ADM-001 |
| BUG-ADM-003 (`$application->cycle_id` at AdmissionPipelineService:73) | Now `admission_cycle_id` (`:74`) | **Resolved** — mark closed in known-issues |
| Aadhar encryption a "gap" | Confirmed plaintext (no `encrypted` cast) | SEC-ADM-001 |
| Three-way reconcile | No separate divergence between migration and model for column *names*; the divergence is **schema ENUM tokens vs service FSM tokens** | BUG-ADM-004 |

---

## FRD Gap Summary (Mode B)

| REQ | Built? | Code present | Gap / status |
|-----|:------:|--------------|--------------|
| 001 Cycle config | Yes | AdmissionCycleController + pipeline.activateCycle | BR-016 one-active **ENFORCED** (`:159-168`); BR-017 dates in request |
| 002 Seat/Quota | Partial | Seat/QuotaConfig controllers | Counters not maintained; over-allotment guard absent (DATA-ADM-001) |
| 003 Checklist | Yes | DocumentChecklistController | OK |
| 004 Enquiry | Partial | EnquiryController | Notification ack not sent (BUG-ADM-008) |
| 005 Follow-up | Partial | FollowUpController | Reminder (BR-022) not dispatched |
| 006 Application | Partial | ApplicationController + pipeline | Age (VAL-001) & aadhar-uniqueness (VAL-002) missing; FSM ENUM bug (BUG-004) |
| 007 Doc upload/verify | Yes | Application flow + checklist | OK (verify mandatory-gate at runtime) |
| 008 Verify/Interview | Partial | ApplicationController | Interview-schedule notification absent |
| 009 Entrance test | Yes | EntranceTestController | BR-009c time check **ENFORCED**; NEP advisory present |
| 010 Merit list | **Partial/Broken** | MeritListController + Service | BUG-ADM-006 (scoring/cutoff/waitlist/weights) |
| 011 Allotment/Offer | **Partial/Broken** | AllotmentController | BR-013 unenforced (DATA-001); admission_no not generated (BUG-005) |
| 012 Fee confirmation | Partial | manual flag only | Payment webhook not built (RISK-ADM-002); no NTF |
| 013 Waitlist auto-promo | **No** | none | JOB-ADM-001 |
| 014 Withdrawal/Refund | Yes | WithdrawalController | Verify refund tier math |
| 015 Enrolment | **Blocked** | EnrollmentController + Service | Atomic tx good, but BUG-ADM-004 blocks reaching `Selected`→`Enrolled`; no allotment lock (DATA-002) |
| 016 Promotion | Yes | PromotionController + Service | Idempotent (firstOrCreate) per knowledge |
| 017 TC & Alumni | Partial | AlumniController + TC service | BR-004 fee gate stub (BUG-ADM-007); PDF storage (SEC-002) |
| 018 Behaviour | Partial | AlumniController incidents | BR-018b critical-notify not wired (BUG-ADM-008) |
| 019 Analytics | Yes | AdmissionAnalyticsController/Service | OK |
| 020 Sibling pref | Yes | enquiry/merit flow | Bonus only if `is_sibling` (BR-015 OK) |
| 021 Public portal | **No** | none | No public route/throttle/consent (by design behind auth) |

**Reports (Mode C / RPT):** RPT-001/002/003/004/006/007/008 present; **RPT-005 (hall-ticket PDF) gap**; RPT-004 offer letter present but prints NULL admission_no (BUG-ADM-005).

---

## Business-Rule Enforcement (Mode C)

| BR | Type | Location | Status | Link |
|----|------|----------|:------:|------|
| BR-ADM-001 age warning | Validation | Store/Update App+Enquiry requests | **MISSING** | VAL-ADM-001 |
| BR-ADM-002 atomic enrol | Concurrency | EnrollmentService DB::transaction | ENFORCED | — |
| BR-ADM-002b adm-fee first | Workflow | EnrollmentService:55-59 | ENFORCED | — |
| BR-ADM-003 admission_no unique/format | Validation | EnrollmentService (enrol time only) | **PARTIAL** | BUG-ADM-005 |
| BR-ADM-004 TC fee clearance | Workflow | TransferCertificateService:38-44 | **MISSING (stub)** | BUG-ADM-007 |
| BR-ADM-005 RTE waiver | Calc | quota_config.application_fee_waiver | PARTIAL (column only) | — |
| BR-ADM-006 refund tiers | Calc | Withdrawal flow | VERIFY | — |
| BR-ADM-007 mandatory-doc gate | Workflow | AdmissionPipelineService/verify | VERIFY (no explicit gate seen in pipeline) | — |
| BR-ADM-007b reject remarks | Validation | doc verify form | VERIFY | — |
| BR-ADM-008 roll unique | Validation | std layer | ENFORCED (STD) | — |
| BR-ADM-008b reject reason | Validation | ApplicationController::reject | VERIFY | — |
| BR-ADM-009 append promotion | Workflow | PromotionService | ENFORCED | — |
| BR-ADM-009b transition logged | Workflow | AdmissionPipelineService.transition → ApplicationStage | ENFORCED | — |
| BR-ADM-009c test time | Validation | StoreEntranceTestRequest:23-24 | **ENFORCED** | — |
| BR-ADM-009d one candidate/test | Validation | UNIQUE(test,application) | ENFORCED (DB) | — |
| BR-ADM-009e idempotent confirm | Concurrency | PromotionService firstOrCreate | ENFORCED | — |
| BR-ADM-010 one placement/session | Validation | std unique | ENFORCED (STD) | — |
| BR-ADM-010c weights sum 100 | Validation | StoreMeritListRequest | **MISSING** | BUG-ADM-006 |
| BR-ADM-010d below-cutoff Rejected | Calc | MeritListService | **MISSING** | BUG-ADM-006 |
| BR-ADM-011 NEP 1–2 advisory | Validation | EntranceTest flow | VERIFY | — |
| BR-ADM-012 aadhar uniqueness (service) | Validation | (none) | **MISSING** | VAL-ADM-002 |
| BR-ADM-013 seat guard | Validation/Concurrency | AllotmentController::store | **MISSING** | DATA-ADM-001 |
| BR-ADM-014 offer expiry + auto-promote | Workflow/Scheduled | (none) | **MISSING** | JOB-ADM-001 |
| BR-ADM-014b refund window | Calc | Withdrawal flow | VERIFY | — |
| BR-ADM-015 sibling bonus only staff-confirmed | Calc | MeritListService:70 (`is_sibling`) | ENFORCED | — |
| BR-ADM-016 one Active/year | Workflow | AdmissionPipelineService:159-168 | **ENFORCED** | — |
| BR-ADM-017 cycle dates | Validation | StoreAdmissionCycleRequest | VERIFY (likely) | — |
| BR-ADM-017b TC number unique/yr | Validation | UNIQUE tc_number | ENFORCED (DB) | — |
| BR-ADM-017c duplicate refs original | Workflow | TransferCertificateService.issueDuplicate:135-150 | ENFORCED | — |
| BR-ADM-018 seat-budget unique | Validation | UNIQUE(cycle,class,quota) | ENFORCED (DB) | — |
| BR-ADM-018b critical → notify | Notification | (none) | **MISSING** | BUG-ADM-008 |
| BR-ADM-019 system-default checklist | Config | nullable cycle + is_system | ENFORCED | — |
| BR-ADM-020 sibling auto-detect on mobile | Workflow | enquiry save | VERIFY | — |
| BR-ADM-021 no enquiry without Active cycle | Validation | submitApplication checks cycle Active (`:76-80`); enquiry path VERIFY | PARTIAL | — |
| BR-ADM-021b public rate-limit | Security | (none) | **MISSING** | REQ-021 gap |
| BR-ADM-022 follow-up reminder once | Notification | (none) | **MISSING** | BUG-ADM-008 |

---

## Systemic-Pattern Scorecard (Mode D, scoped to ADM)

| Pattern | Present? | Count | vs Baseline |
|---------|:--------:|------:|-------------|
| D17 fillable→missing column | No (not observed) | 0 | better than norm |
| D24 permission-prefix chaos/typos | No | 0 | all `tenant.adm-*` — consistent |
| D25 `$request->all()` into model | No | 0 (2 `request->all()` are log payloads only) | better than 24-site norm |
| D29 `->enum()` in migrations | **Yes** | 29 | typical (per-module share) |
| D30 `authorize(){return true;}` | **Yes** | 24/24 | matches 90% norm |
| D36 GENERATED column degraded | n/a | 0 | ADM has no generated columns |
| Layer 2.5 cross-DB / missing-FK (`sys_dropdowns`/`sys_roles`) | No | 0 | better than norm |
| Layer 3.3 privilege fields in `$fillable` | No | 0 | clean |
| Layer 6.2 `initialize()` without `end()` | No | 0 | clean |
| Layer 10.1 jobs without tenancy/retry | n/a | 0 jobs | (waitlist job missing — JOB-ADM-001) |
| TEN-RTG-001 module-subscription middleware | Present | — | `EnsureTenantIsActive` in stack |

---

## vs Platform Baseline

ADM is **better than the platform norm** on the riskiest classes: tenancy (correct stack), authorization (every controller gated with a single consistent `tenant.adm-*` prefix — no D24 typos), mass-assignment (0 `$request->all()`-into-model sites vs 24-site norm), no cross-DB FK, no INT-PK `increments('id')`. It is **at the norm** on D30 (24/24 `authorize() true`) and D29 (29 enums). Its distinguishing risks are **module-specific logic defects** (FSM/ENUM divergence, merit scoring, seat guard, TC fee gate) and **unbuilt automation/integration** (notifications, waitlist job, payment webhook, public portal) — not the usual platform systemic holes.

---

## Recommended Fix Order

1. **BUG-ADM-004** — reconcile status ENUM ↔ FSM tokens (unblocks the entire enrolment pipeline). *(Developer + DB Architect)*
2. **DATA-ADM-001** — add seat-budget lock + over-allotment guard at allotment; maintain `seats_allotted`. *(Developer)*
3. **SEC-ADM-001** — encrypt Aadhar at rest + restrict access. *(Developer/Security)*
4. **BUG-ADM-006** — fix merit scoring (weights from criteria_json, include interview, apply cutoff/waitlist) + BR-010c validation. *(Developer)*
5. **BUG-ADM-005** — generate `admission_no` at offer issue. *(Developer)*
6. **BUG-ADM-007 / VAL-ADM-001 / VAL-ADM-002** — TC fee gate, age warning, aadhar uniqueness. *(Developer)*
7. **JOB-ADM-001 + BUG-ADM-008** — waitlist/expiry command + event-driven notifications. *(Developer + Notification)*
8. **DATA-ADM-002 / DEAD-ADM-001 / D29** — locks, remove/finish stub apiResource, enum→dropdown migration. *(next sprint)*
9. **Tests (RISK-ADM-006)** — Pest coverage for enrolment rollback, scoring, FSM, promotion. *(Testing Architect)*

---

## Next Steps
```
Audit complete — Health 40/100 (capped: P0 present). DEPLOY: NO-GO.
1. Fix P0/P1 issues   → act as Developer (start BUG-ADM-004)
2. Schema/ENUM→FK     → act as DB Architect (D29, status ENUM)
3. Completeness score → act as Status_Analyzer
4. Test coverage      → act as Testing Architect (0 tests)
```

*End of ADM Complete Audit — 2026-06-29. Issue codes assigned here are frozen for reuse.*
