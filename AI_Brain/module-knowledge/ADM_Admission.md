# Module Knowledge: Admission Management (ADM)
# Last Updated: 2026-06-29 (Phase 1 verify + Phase 2 Complete FRD pass — every count re-checked against live tree)
# Completion Status: ~65–70% (all 20 models + 6 services + 17 domain controllers substantial; 84 views; 5 entity seeders; 0 tests; 0 migrations; PUBLIC PORTAL + PAYMENT WEBHOOK + EXPIRE-OFFERS JOB not built; Aadhar encryption NOT implemented)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `adm_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Admission_DDL_v1.sql` — **20 tables, 927 lines** (NOTE: filename is `Admission_DDL_v1.sql`, NOT `AdmissionMgmt_DDL_v1.sql` as earlier recorded) |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/ADM_Admission_Requirement.md` (15 FRs, 15 BRs, 25 screens, 25 test scenarios) |
| V1 Requirement | `4-Requirement_Module_wise/2-Module_Requirement_V1/Admission_v2/` (folder present) |
| Module scope | `tenant_db` — no `tenant_id` columns (database-per-tenant) |
| Implementation status | ~65–70% (re-verified 2026-06-29) |
| Complete FRD | `0-FRD_Documents/ADM_FRD_Complete_2026-06-29.md` — 21 REQ, 22 BR, 8 RPT, 5 workflows |
| Controllers | **18** actual — 17 substantial domain controllers (200–432 LOC) + 1 **stub** (`AdmissionController`, the `auth:sanctum` apiResource — index/create/show/edit return bare views; store/update/destroy are empty `{}`). Req doc proposed 14. |
| Models | **20** actual (matches DDL table count exactly) |
| Services | **6** actual (1,134 LOC total): AdmissionPipelineService (202), EnrollmentService (216), MeritListService (141), PromotionService (197), TransferCertificateService (154), AdmissionAnalyticsService (224). Matches proposed 6. |
| FormRequests | **24** actual (Store + Update pairs for most entities + EnrollStudentRequest) |
| Policies | **13** actual (in module's own `app/Policies/`, not central) |
| Tests | **0** — `tests/Unit` and `tests/Feature` contain only `.gitkeep`. Critical gap (25 scenarios specified). |
| Blade Views | **84** actual across 20+ view dirs (req doc said 25 screens; combined tabbed "menu" pages + partials inflate the count) |
| Web Routes | **251 lines** in `web.php` — resource routes + trash/restore/forceDelete + FSM actions + analytics AJAX + menu group pages |
| API Routes | **8 lines** in `api.php` — single `auth:sanctum` apiResource on the stub `AdmissionController`. **No public routes. No payment webhook route.** |
| Jobs | **0** — no `Jobs/` dir; `PromoteExpiredOffersJob` / `adm:expire-offers` command NOT created (DDL line 594 references it but it does not exist) |
| Events/Listeners | **0** — `EventServiceProvider::$listen = []`, `$shouldDiscoverEvents = true`, no `Events/` or `Listeners/` dir. NTF dispatch (if any) is fired inline from controllers/services, not event-driven. |
| Console Commands | **0** — no scheduled command exists |
| Migrations | **20** (CORRECTED 2026-06-29 by Technical Auditor — earlier "0" was WRONG). `database/migrations/tenant/2026_06_16_0836*_create_adm_*_table.php` — one per table. Module `database/` dir holds only seeders/factories, but the tenant migrations are CENTRALIZED (platform convention). PK uses `id()` (no INT `increments`); no cross-DB FK to `sys_dropdowns`/`sys_roles`; 29 `->enum()` columns (D29). |
| Seeders | **6** — AdmissionCyclesSeeder, DocumentChecklistSeeder, QuotaConfigSeeder, SeatCapacitySeeder, EntranceTestsSeeder, AdmissionDatabaseSeeder (orchestrator) |

---

## DDL Layer Structure (20 tables — verified against Admission_DDL_v1.sql)

| Layer | Tables |
|-------|--------|
| Layer 1 (no adm_* deps) | `adm_admission_cycles` |
| Layer 2 (+ cycle + sch_classes) | `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity`, `adm_entrance_tests` |
| Layer 3 (+ std_students, sys_users) | `adm_enquiries`, `adm_merit_lists` |
| Layer 4 (+ adm_enquiries) | `adm_follow_ups`, `adm_applications` |
| Layer 5 (+ tests, merit lists) | `adm_application_documents`, `adm_application_stages`, `adm_entrance_test_candidates`, `adm_merit_list_entries` |
| Layer 6 (+ sch_sections, sessions) | `adm_allotments`, `adm_promotion_batches` |
| Layer 7 (+ sch_class_section_jnt) | `adm_withdrawals`, `adm_promotion_records` |
| Layer 8 (+ std_students cross-module) | `adm_transfer_certificates`, `adm_behavior_incidents` |
| Layer 9 (+ adm_behavior_incidents) | `adm_behavior_actions` |

---

## Feature Groups (V2 FR → FRD REQ mapping)

| V2 FR | Feature | FRD REQ(s) | Tables | Priority |
|-------|---------|-----------|--------|----------|
| FR-ADM-01 | Admission Cycle & Seat Capacity Config | REQ-ADM-001, 002 | `adm_admission_cycles`, `adm_seat_capacity`, `adm_quota_config` | P0 |
| FR-ADM-02 | Lead Capture & Enquiry | REQ-ADM-004, 005 | `adm_enquiries`, `adm_follow_ups` | P0/P1 |
| FR-ADM-03 | Admission Application Form | REQ-ADM-006, 007 | `adm_applications`, `adm_application_documents`, `adm_application_stages` | P0 |
| FR-ADM-04 | Verification & Interview | REQ-ADM-008 | `adm_applications`, `adm_application_documents` | P1 |
| FR-ADM-05 | Entrance Test | REQ-ADM-009 | `adm_entrance_tests`, `adm_entrance_test_candidates` | P1 |
| FR-ADM-06 | Merit List & Allotment | REQ-ADM-010, 011 | `adm_merit_lists`, `adm_merit_list_entries`, `adm_allotments` | P0 |
| FR-ADM-07 | Admission Fee & Payment | REQ-ADM-012 | `adm_allotments` | P1 |
| FR-ADM-08 | Withdrawal & Refund 🆕 | REQ-ADM-014 | `adm_withdrawals` | P1 |
| FR-ADM-09 | Final Enrollment | REQ-ADM-015 | `adm_allotments` → `sys_users`, `std_students`, `std_student_academic_sessions` | P0 |
| FR-ADM-10 | Year-End Promotion | REQ-ADM-016 | `adm_promotion_batches`, `adm_promotion_records` | P0 |
| FR-ADM-11 | Alumni & Transfer Certificate | REQ-ADM-017 | `adm_transfer_certificates` | P1 |
| FR-ADM-12 | Behaviour Incident | REQ-ADM-018 | `adm_behavior_incidents`, `adm_behavior_actions` | P2 |
| FR-ADM-13 | Analytics Funnel 🆕 | REQ-ADM-019 | reads all `adm_*` | P2 |
| FR-ADM-14 | Sibling Preference 🆕 | REQ-ADM-020 | `adm_enquiries`, `adm_applications` | P1 |
| FR-ADM-15 | Admission Settings | REQ-ADM-003 + 001/002 | config tables | P1 |
| — (gap) | Public Portal (online form + status tracker + payment) | REQ-ADM-013, 021 | `adm_enquiries`, `adm_applications` | P1 — **NOT BUILT** |

---

## Critical DDL Facts & Differences from Requirement Doc (re-verified 2026-06-29)

### DDL-001 — Aadhar Uniqueness: Service Layer Only (NOT DB UNIQUE)
- Req doc (BR-ADM-012) says "Partial UNIQUE index on `adm_applications.aadhar_no`".
- **DDL is authoritative:** only `KEY idx_adm_app_aadhar (aadhar_no)` — non-unique. DDL comment line 399: "aadhar_no is NOT UNIQUE at DB level; service-layer uniqueness check only".

### DDL-002 — `created_by` + `updated_by` are NOT NULL on every table
- DDL: both `BIGINT UNSIGNED NOT NULL` on all 20 tables, **no FK constraint** (audit columns). Factories/seeders must always supply a valid id.

### DDL-003 — `adm_merit_lists` self-contained scoring columns
- `sibling_bonus_score TINYINT UNSIGNED NOT NULL DEFAULT 5` (copied from cycle at generation) and `cutoff_score DECIMAL(6,2) NULL` (below cutoff → Rejected). `criteria_json` holds weightage `{"test_pct","interview_pct","academic_pct"}` summing to 100.

### DDL-004 — `adm_document_checklist.admission_cycle_id` is NULLABLE
- NULL = global template row with `is_system = 1`. `class_id` also nullable (NULL = all classes). Seeder must create system defaults first.

### DDL-005 — FK type split: INT UNSIGNED vs BIGINT UNSIGNED
- All FKs referencing `sys_users.id`, `std_students.id`, `sch_classes.id`, `sch_sections.id`, `sch_org_academic_sessions_jnt.id`, `sys_media.id` → **INT UNSIGNED** (these parent tables use INT). `created_by`/`updated_by` → BIGINT UNSIGNED (no FK). `sys_media` is INT UNSIGNED (DDL comment lines 438, 592, 802).

### DDL-006 — `behavior_score_impact` is signed TINYINT
- `adm_behavior_incidents.behavior_score_impact TINYINT NOT NULL DEFAULT 0` — signed (negative = deduction, e.g. -5 Medium, -15 Critical). Model must not cast unsigned.

### DDL-007 — `adm_allotments.admission_no` is nullable UNIQUE
- `UNIQUE KEY uq_adm_allot_admission_no` on a NULL-able column (MySQL allows multiple NULLs). NULL until offer letter issued; generated from `adm_admission_cycles.admission_no_format` (default `{YEAR}/{SEQ}`).

### DDL-008 — `adm_application_stages` is an immutable audit trail
- `from_status` / `to_status` are free-text VARCHAR(50) (accommodates future statuses); `changed_by` NULL = system-triggered; `changed_at` DEFAULT CURRENT_TIMESTAMP.

---

## Key Business Rules (see FRD §4 for the authoritative BR-ADM register)

| Rule | Summary | Verified Enforcement Point |
|------|---------|----------------------------|
| BR-ADM-001 | Age eligibility min/max per class on cut-off date (default Jun 1); warning, not block | `StoreEnquiryRequest`, `StoreApplicationRequest` |
| BR-ADM-002 | Enrollment atomic: `sys_users` + `std_students` + `std_student_academic_sessions` (+ `std_siblings_jnt`) in one `DB::transaction()` | `EnrollmentService::enrollStudent()` (confirmed) |
| BR-ADM-003 | Admission number unique per school-year; format from cycle template | UNIQUE on `adm_allotments.admission_no` |
| BR-ADM-004 | TC blocked if outstanding fees | `TransferCertificateService` (FIN check — verify wiring) |
| BR-ADM-005 | RTE quota: 25% Class 1 reserved EWS; RTE exempt application fee | `adm_quota_config.application_fee_waiver` |
| BR-ADM-007 | All mandatory docs uploaded before Submitted → Verified | `AdmissionPipelineService::verifyApplication()` |
| BR-ADM-012 | Aadhar unique when provided — **service layer only** | `ApplicationService` (NOT DB) |
| BR-ADM-013 | Seat capacity guard: allotment blocked if `seats_allotted >= total_seats` | `MeritListService::allotSeat()` |
| BR-ADM-014 | Offer expires after N days; next waitlisted auto-promoted | **NOT IMPLEMENTED** — no daily job exists |
| BR-ADM-015 | Sibling bonus only if `is_sibling = 1` (staff-confirmed) | `adm_applications.is_sibling` |

---

## State Machines (verified against DDL ENUMs + route actions)

- **Application:** Draft → Submitted → Under_Review → Verified → (Shortlisted | Rejected) → (Allotted | Waitlisted) → Enrolled; Withdrawn from any pre-Enrolled state. ENUM has 10 values. All transitions logged to `adm_application_stages`. Route actions: submit/shortlist/select/reject.
- **Allotment Offer:** Offered → (Accepted | Declined | Expired) → Enrolled / Withdrawn. Route actions: accept/decline; Expired requires the missing daily job.
- **Enquiry Lead:** New → Assigned → Contacted → (Interested → Converted | Not_Interested | Callback | Duplicate).
- **Withdrawal/Refund:** Not_Eligible / Pending → Approved → Paid. `processRefund` route exists.
- **Promotion Batch:** Draft → Confirmed (idempotent re-run). Per-student `adm_promotion_records.result`: Promoted/Detained/Transferred/Alumni/Left.

---

## Cross-Module Dependencies (verified)

### Inbound (ADM reads / integrates)
| Module | Tables / Channel | Purpose |
|--------|-----------------|---------|
| SystemConfig (SYS) | `sys_users`, `sys_roles`, `sys_media`, `sys_settings`, `sys_activity_logs` | Auth, RBAC, file uploads, audit |
| SchoolSetup (SCH) | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_org_academic_sessions_jnt` | Class/section/session selection |
| StudentProfile (STD) | `std_students`, `std_student_academic_sessions`, `std_guardians`, `std_siblings_jnt` | Enrollment writes; sibling detection; promotion |
| StudentFee (FIN) | `fin_invoices`, `fin_fee_structures` | App/admission fee invoices; TC fee-clearance |
| Payment (PAY) | Webhook (proposed) | Online fee — **route NOT built** |
| Notification (NTF) | inline dispatch (no events) | Stage transitions, offers, reminders |
| GlobalMaster (GLB) | `glb_countries`, `glb_states`, `glb_boards` | Address dropdowns |
| LmsExam (EXM) | `exm_*` results | Promotion criteria cross-reference |

### Outbound (depend on ADM)
StudentProfile (enrollment seeds records), Attendance, StudentFee, LmsExam, Timetable, ParentPortal.

### Critical Integration — EnrollmentService::enrollStudent()  (confirmed cross-module, single transaction)
Imports `Modules\StudentProfile\Models\Student` + `StudentAcademicSession`. In one `DB::transaction()`: create `sys_users` (Hash password) → `std_students` → `std_student_academic_sessions` → `std_siblings_jnt` (guarded by `Schema::hasTable`) → set `adm_allotments.status=Enrolled` + `enrolled_student_id`. Full rollback on failure.

---

## Design Decisions Made (corrected 2026-06-29)

1. **Aadhar uniqueness is service-layer only** — non-unique DDL index; check in service before insert; duplicate = warning, not block.
2. **`adm_document_checklist.admission_cycle_id` nullable for global templates** (`is_system=1`).
3. **Merit list is self-contained** — `sibling_bonus_score` + `cutoff_score` copied from cycle at generation.
4. **Promotion is idempotent** — `PromotionService` `firstOrCreate`; re-run safe.
5. **`adm_allotments.admission_no` nullable UNIQUE** — generated from cycle template at offer-letter time.
6. **Behaviour tables may be extracted to a future `BEH` module** — avoid strong coupling.
7. **NEP 2020 entrance-test warning (Classes 1–2) is non-blocking** — advisory only.
8. **Soft-delete everywhere** — every table has `deleted_at`; every controller exposes trash/restore/forceDelete routes.
9. **Stub API controller** — `AdmissionController` (apiResource) is an unfinished scaffold; the working surface is web routes + 17 domain controllers.

### ⚠️ Corrections to earlier knowledge (were stated as facts, NOT in live code)
- **Public routes `/apply/{slug}` and `/apply/status/{app_no}` DO NOT EXIST.** `web.php` has no public/unauthenticated routes and no `throttle`. UI screens 5 & 6 (public form, status tracker) are unbuilt.
- **Payment webhook `/api/v1/admission/payment/webhook` DOES NOT EXIST.** `api.php` only has one `auth:sanctum` apiResource (stub). No webhook, no signature verification, no idempotency code.
- **Aadhar encryption is NOT implemented.** `Application` model `$casts` has no `encrypted` cast for `aadhar_no`; it is plain `fillable`. NFR (AES-256 at rest) is a real open gap, not a confirmed feature.

---

## Auto-Generated Numbers & Sequences
| Field | Format | Where |
|-------|--------|-------|
| `adm_enquiries.enquiry_no` | `ENQ-YYYY-NNNNN` | AdmissionPipelineService |
| `adm_applications.application_no` | `APP-YYYY-NNNNN` | AdmissionPipelineService |
| `adm_entrance_test_candidates.roll_no` | sequential per test | candidate list generation |
| `adm_allotments.admission_no` | cycle template `{YEAR}/{SEQ}` | EnrollmentService at offer-letter |
| `adm_transfer_certificates.tc_number` | `TC-YYYY-NNN` | TransferCertificateService |

---

## FRD Summary

| Item | Value |
|------|-------|
| File | `0-FRD_Documents/ADM_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — FRD + RTM + BR register + conditions + validation + workflows + FSM + data dictionary + dependency map + NFR + risk + prioritization + sprint tasks + user stories + reporting) |
| Date | 2026-06-29 |
| REQ count | 21 (REQ-ADM-001 … 021) |
| Priority split | P0 = 9, P1 = 9, P2 = 3 |
| BR count | 22 (BR-ADM-001 … 022) |
| Workflows | 5 (Enquiry, Application, Merit→Allotment→Offer, Enrollment, Promotion) |
| FSMs | 5 |
| Reports | 8 (RPT-ADM-001 … 008) |
| ENH | 4 (ENH-ADM-001 … 004) |
| Risks | 6 (RISK-ADM-001 … 006) |

---

## Known Gaps & Open Issues (as of 2026-06-29)

| Priority | Gap | Notes |
|----------|-----|-------|
| P0 | **Public Admission Portal not built** | UI screens 5 (online form) & 6 (status tracker) absent; no public route, no rate-limit, no parent consent capture. Parent/Public actor cannot self-serve. |
| P0 | **Waitlist auto-promotion job missing** | BR-ADM-014 needs a daily `adm:expire-offers` command; no `Jobs/`/`Console/` exists. Expired offers never auto-promote. |
| P0 | **0 test files** | 25 scenarios specified; none implemented. EnrollmentService (cross-module tx), MeritListService (scoring), FSMs are high-risk untested. |
| P1 | **Payment webhook not built** | No online application/admission fee confirmation endpoint; fee marked paid manually only. NFR idempotency moot. |
| P1 | **Aadhar AES-256 encryption not implemented** | Plain column, no `encrypted` cast. PII/PDPB exposure. |
| P1 | **0 migrations** | Cannot `artisan migrate` a fresh tenant; depends on raw DDL load. |
| P1 | **NTF not event-driven** | No Events/Listeners; notifications (if any) fired inline — fragile, hard to audit. |
| P2 | **Stub `AdmissionController` (apiResource)** | Empty CRUD; either finish or remove from `api.php`. |
| P2 | **TC fee-clearance wiring (BR-ADM-004) unverified** | Confirm `TransferCertificateService` actually queries FIN balance. |
| P3 | **AlumniController scope** | AlumniController also owns TC + behaviour-incident actions (no separate TransferCertificate/BehaviorIncident controllers built). Confirmed by routes — not an overlap bug; one controller fronts the promotions-alumni page. |

---

## Known Gaps & Open Issues — Mode X Complete Audit (2026-06-29, Technical Auditor)

Report: `3-Audit_Reports/V1_Jun-2026/Admission_Complete_Audit_2026-06-29.md`. Health 40/100 (P0 cap). DEPLOY: NO-GO.

| Priority | Code | Gap | Evidence |
|----------|------|-----|----------|
| P0 | BUG-ADM-004 | App FSM transitions to `'Under Review'`/`'Selected'` — NOT in `adm_applications.status` ENUM (which has `Under_Review`, no `Selected`); `'Selected'` is the required pre-state for `Enrolled` → enrolment pipeline (REQ-015) cannot complete | `AdmissionPipelineService.php:18-28,96,120`; migration `...083610...:59`; `EnrollmentService.php:155` |
| P1 | DATA-ADM-001 | Seat over-allotment guard (BR-013) absent; **cited `MeritListService::allotSeat()` DOES NOT EXIST**; `seats_allotted` never incremented; no lock on allotment | `AllotmentController.php:60-74` |
| P1 | BUG-ADM-005 | `admission_no` never generated at offer/allotment (only at enrolment); offer-letter PDF prints NULL | `AllotmentController.php:60-74,150-159` |
| P1 | SEC-ADM-001 | Aadhar/PII plaintext (no `encrypted` cast) — confirmed; copied plaintext to `std_students.aadhar_id` | `Application.php:59,103-114`; `EnrollmentService.php:103` |
| P1 | BUG-ADM-006 | Merit scoring: interview computed but excluded from composite; weights hardcoded 0.40+0.40+0.30 (criteria_json ignored); no cutoff→Rejected, no seat→Waitlist; BR-010c sum-100 not validated | `MeritListService.php:56-103`; `StoreMeritListRequest.php` |
| P1 | BUG-ADM-007 | BR-004 TC fee gate is a STUB — logs warning, issues anyway; no fin_invoices check | `TransferCertificateService.php:38-44` |
| P1 | JOB-ADM-001 | Waitlist auto-promotion / offer-expiry unbuilt; decline doesn't free seat; `promoteWaitlisted()` never called | module-wide |
| P1 | VAL-ADM-001 | Age eligibility (BR-001) NOT enforced; `age_rules_json` never read | requests |
| P1 | VAL-ADM-002 | Aadhar service-layer uniqueness (BR-012) NOT implemented | create path |
| P2 | DATA-ADM-002 | Number generators + enrolment lack row locks (race/double-enrol) | `Application.php:19-38`; `EnrollmentService.php:61-65,185-204` |
| P2 | SEC-ADM-002 | TC PDF to `Storage::disk('local')` un-prefixed (cross-tenant risk); media_id never saved | `TransferCertificateService.php:65-66` |
| P2 | BUG-ADM-008 | Notifications entirely unimplemented (0 usage); EventServiceProvider `$listen=[]` | `EventServiceProvider.php:14` |
| P2 | DATA-ADM-003 / DEAD-ADM-001 / PERF-ADM-001 | 29 enums (D29); stub apiResource on live route; misplaced lock | see report |

**RESOLVED:** BUG-ADM-003 — service now uses `$application->admission_cycle_id` (`:74`).
**Strengths (above platform norm):** correct tenancy stack (RouteServiceProvider full stack), every controller `Gate::authorize('tenant.adm-*')` (no D24 typos), 0 `$request->all()`-into-model, 0 cross-DB FK, PK `id()`.
**Enforced BRs confirmed:** BR-016 (one Active/year, `AdmissionPipelineService:159-168`), BR-009c (test time, `StoreEntranceTestRequest`), BR-002/002b (atomic enrol + fee-first), BR-009b (transition logging), BR-015 (sibling bonus only staff-confirmed), BR-017c (TC duplicate refs original).

## Lessons Learned
- [2026-06-29 | Technical Auditor] The headline ADM risk is **schema-ENUM vs service-FSM divergence**, not the usual platform systemic holes. `AdmissionPipelineService::TRANSITIONS` and `adm_applications.status` ENUM were authored independently and disagree (`Under Review` vs `Under_Review`; `Selected` not in ENUM). Always reconcile the FSM constant against the migration ENUM verbatim.
- [2026-06-29 | Technical Auditor] FRD/knowledge "BR enforced in `MeritListService::allotSeat()`" was unverified — the method does not exist. Seat guard (BR-013) is entirely absent. Confirm cited enforcement points against live code.
- [2026-06-29 | Technical Auditor] "0 migrations" snapshot was wrong: 20 ADM tenant migrations exist. Always re-confirm migration counts in `database/migrations/tenant/` (centralized), not in the module `database/` dir.

## Pending Next Steps
- [ ] Code Gap Analysis → Technical Auditor: confirm BR enforcement (BR-002/007/013/004), Aadhar handling, notification pattern, EnrollmentService transaction safety.
- [ ] Build Public Admission Portal (online form + status tracker + parent consent) and the payment webhook.
- [ ] Implement `adm:expire-offers` daily scheduled command + waitlist promotion.
- [ ] Create tenant migrations for all 20 ADM tables.
- [ ] Add Aadhar `encrypted` cast / encryption service.
- [ ] Add tests: EnrollmentService rollback, MeritListService scoring, Application FSM, Promotion idempotency, refund computation.
- [ ] Finish or remove stub `AdmissionController` apiResource.

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge seeded from ADM_Admission_Requirement.md v2 + DDL (20 tables). 5 DDL deviations documented. Status initially mis-recorded as 0% Greenfield. |
| 2026-06-27 | Business Analyst | Update pass: verified file counts; status corrected to ~60–65%. |
| 2026-06-29 | Technical Auditor | Mode X Complete Audit (A+B+C+G+scoped-D). Health 40/100 (P0 cap), DEPLOY NO-GO. Found P0 BUG-ADM-004 (FSM/ENUM divergence blocks enrolment) + 9 P1 (seat guard, admission_no, Aadhar plaintext, merit scoring, TC fee stub, waitlist job, age, aadhar-uniqueness, D30). Corrected "0 migrations" → 20 exist. Confirmed BUG-ADM-003 resolved. Report at `3-Audit_Reports/V1_Jun-2026/Admission_Complete_Audit_2026-06-29.md`. |
| 2026-06-29 | Business Analyst | Phase 1 re-verify + Phase 2 Complete FRD. Corrected DDL filename (`Admission_DDL_v1.sql`). Confirmed 18 controllers (1 stub), 6 services (1,134 LOC), 24 FormRequests, 13 policies, 84 views, 6 seeders, 0 tests/jobs/events/migrations. **Corrected three earlier false "facts": public `/apply` routes, payment webhook, and Aadhar encryption do NOT exist in code.** Produced ADM_FRD_Complete_2026-06-29.md (21 REQ / 22 BR / 8 RPT / 5 workflows). |
</content>
</invoke>
