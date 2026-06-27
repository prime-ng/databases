# Module Knowledge: Admission Management (ADM)
# Last Updated: 2026-06-27
# Completion Status: 0% — Greenfield (RBS_ONLY, no implementation started)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `adm_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/AdmissionMgmt_DDL_v1.sql` — 20 tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/ADM_Admission_Requirement.md` |
| Module scope | `tenant_db` — no `tenant_id` columns |
| Implementation status | 0% — All tables 📐 New |
| Functional Requirements | 15 (FR-ADM-01 to FR-ADM-15) |
| Business Rules | 15 (BR-ADM-001 to BR-ADM-015) |
| Controllers | 14 proposed |
| Models | 20 proposed |
| Services | 6 proposed |
| Jobs | 1 proposed (`PromoteExpiredOffersJob`) |
| Web Routes | ~47 + 3 public (unauthenticated) |
| API Routes | ~7 |
| UI Screens | 25 |
| Test Scenarios | 25 |
| FRD | Not yet generated |

---

## DDL Layer Structure (20 tables)

| Layer | Tables |
|-------|--------|
| Layer 1 (no adm_* deps) | `adm_admission_cycles` |
| Layer 2 (+ sch_classes) | `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity`, `adm_entrance_tests` |
| Layer 3 (+ std_students, sys_users) | `adm_enquiries`, `adm_merit_lists` |
| Layer 4 (+ adm_enquiries) | `adm_follow_ups`, `adm_applications` |
| Layer 5 (+ adm_entrance_tests, adm_merit_lists) | `adm_application_documents`, `adm_application_stages`, `adm_entrance_test_candidates`, `adm_merit_list_entries` |
| Layer 6 (+ sch_sections, sch_org_academic_sessions_jnt) | `adm_allotments`, `adm_promotion_batches` |
| Layer 7 (+ sch_class_section_jnt) | `adm_withdrawals`, `adm_promotion_records` |
| Layer 8 (+ std_students cross-module) | `adm_transfer_certificates`, `adm_behavior_incidents` |
| Layer 9 (+ adm_behavior_incidents) | `adm_behavior_actions` |

---

## Feature Groups

| FR | Feature | Tables | Priority |
|----|---------|--------|----------|
| FR-ADM-01 | Admission Cycle & Seat Capacity Configuration | `adm_admission_cycles`, `adm_seat_capacity` | Critical |
| FR-ADM-02 | Lead Capture & Enquiry Management | `adm_enquiries`, `adm_follow_ups` | High |
| FR-ADM-03 | Admission Application Form | `adm_applications`, `adm_application_documents`, `adm_application_stages` | Critical |
| FR-ADM-04 | Application Verification & Interview Scheduling | `adm_applications`, `adm_application_documents`, `adm_application_stages` | High |
| FR-ADM-05 | Entrance Test Management | `adm_entrance_tests`, `adm_entrance_test_candidates` | Medium |
| FR-ADM-06 | Merit List Generation & Quota-based Seat Allotment | `adm_merit_lists`, `adm_merit_list_entries`, `adm_allotments` | Critical |
| FR-ADM-07 | Admission Fee & Payment Confirmation | `adm_allotments` | High |
| FR-ADM-08 | Withdrawal & Refund Workflow 🆕 V2 | `adm_withdrawals` | Medium |
| FR-ADM-09 | Final Enrollment Conversion | `adm_allotments` → writes `sys_users`, `std_students`, `std_student_academic_sessions` | Critical |
| FR-ADM-10 | Student Promotion (Year-end) | `adm_promotion_batches`, `adm_promotion_records` | High |
| FR-ADM-11 | Alumni Management & Transfer Certificate | `adm_transfer_certificates` | Medium |
| FR-ADM-12 | Behavior Incident Management | `adm_behavior_incidents`, `adm_behavior_actions` | Medium |
| FR-ADM-13 | Admission Analytics Funnel 🆕 V2 | Reads all `adm_*` tables | Medium |
| FR-ADM-14 | Sibling Preference Rules 🆕 V2 | `adm_enquiries`, `adm_applications` | Medium |
| FR-ADM-15 | Admission Settings & Configuration | `adm_admission_cycles`, `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity` | High |

---

## Critical DDL Differences from Requirement Doc

### DDL-001 — Aadhar Uniqueness: Service Layer Only (NOT DB UNIQUE)
**Impact: High — affects validation design**
- **Req doc says:** "UNIQUE index on `adm_applications.aadhar_no` (nullable, partial)"
- **DDL says:** `KEY idx_adm_app_aadhar (aadhar_no)` — non-unique index only. DDL comment: "NOT UNIQUE at DB level; service-layer uniqueness check only"
- **Why:** MySQL partial UNIQUE on nullable may cause issues across tenants; uniqueness enforced in `StoreApplicationRequest` instead.
- **Action required:** Do NOT create a UNIQUE constraint on `aadhar_no`. The uniqueness warning must be implemented in `ApplicationService`, not by the database.

### DDL-002 — created_by + updated_by are NOT NULL in DDL
**Impact: Medium — affects model factories and seeder design**
- **Req doc says:** `created_by BIGINT UNSIGNED NULL, FK→sys_users`
- **DDL says:** `created_by BIGINT UNSIGNED NOT NULL` and `updated_by BIGINT UNSIGNED NOT NULL` (both non-nullable, both on every table)
- **DDL is authoritative.** Migrations must have NOT NULL; model factories must provide a valid sys_users ID.

### DDL-003 — adm_merit_lists has extra columns not in req doc
**Impact: Medium — merit list generation logic**
- DDL adds `sibling_bonus_score TINYINT UNSIGNED NOT NULL DEFAULT 5` — copied from cycle at generation time (allows merit list to be self-contained even if cycle config changes later)
- DDL adds `cutoff_score DECIMAL(6,2) NULL` — minimum composite score; below cutoff → Rejected status
- These are not in the req doc's table spec. Both must be present in the `adm_merit_lists` migration.

### DDL-004 — adm_document_checklist.admission_cycle_id is NULLABLE
**Impact: Low — affects seeder design**
- **Req doc says:** NOT NULL
- **DDL says:** `admission_cycle_id BIGINT UNSIGNED NULL` — NULL means global template row (with `is_system = 1`)
- DDL also adds `is_system TINYINT(1) NOT NULL DEFAULT 0` column (not in req doc)
- `AdmissionDocumentChecklistSeeder` should create system default rows with `admission_cycle_id = NULL, is_system = 1`

### DDL-005 — FK type: INT UNSIGNED vs BIGINT UNSIGNED for sys_users references
**Impact: Low — type mismatch bugs at migration time**
- Req doc specifies `BIGINT UNSIGNED` for counselor_id, done_by, processed_by, changed_by, etc.
- DDL uses `INT UNSIGNED` for these columns — matches `sys_users.id = INT UNSIGNED` in tenant_db
- `created_by` and `updated_by` columns remain `BIGINT UNSIGNED` (no FK constraint declared on them — they are audit columns)
- **Rule:** All FK columns that reference `sys_users.id` → INT UNSIGNED. `created_by`/`updated_by` → BIGINT UNSIGNED (no FK).

### DDL-006 — behavior_score_impact is signed TINYINT (not TINYINT UNSIGNED)
**Impact: Low but notable**
- `adm_behavior_incidents.behavior_score_impact TINYINT NOT NULL DEFAULT 0` — signed, allowing negative values
- DDL comment: "negative value = score deduction e.g., -5 for Medium, -15 for Critical"
- Req doc shows `TINYINT` but does not emphasize sign. Model fillable must not cast to unsigned.

---

## Key Business Rules

| Rule | Summary | Enforcement |
|------|---------|-------------|
| BR-ADM-001 | Age eligibility: min/max per class on cut-off date (default June 1); warning not block | `StoreEnquiryRequest`, `StoreApplicationRequest` |
| BR-ADM-002 | Enrollment is atomic: sys_users + std_students + std_student_academic_sessions in single DB::transaction() | `EnrollmentService::enrollStudent()` |
| BR-ADM-003 | Admission number unique per school-year; format configurable per cycle | UNIQUE on `adm_allotments.admission_no` + `std_students.admission_no` |
| BR-ADM-004 | TC blocked if any outstanding fees; FIN module balance check required | `TransferCertificateService` checks FIN |
| BR-ADM-005 | RTE quota: 25% Class 1 seats reserved for EWS; RTE applicants exempt from application fee | `adm_quota_config.application_fee_waiver = 1` for RTE |
| BR-ADM-006 | Application fee non-refundable by default; refund policy in `adm_admission_cycles.refund_policy_json` configures exceptions | `AdmissionPipelineService::withdrawApplication()` |
| BR-ADM-007 | All mandatory docs uploaded before application advances Submitted → Verified | `AdmissionPipelineService::verifyApplication()` |
| BR-ADM-008 | Roll numbers unique within class section per academic session | UNIQUE on `std_student_academic_sessions` (class_section_id, academic_session_id, roll_no) |
| BR-ADM-009 | Promotion creates NEW std_student_academic_sessions for next year; does NOT modify current records | `PromotionService` — append only |
| BR-ADM-010 | One enrollment per student per academic session | UNIQUE on `std_student_academic_sessions` (student_id, academic_session_id) |
| BR-ADM-011 | NEP 2020: entrance tests prohibited for Classes 1–2 | Non-blocking validation warning in `StoreEntranceTestRequest` |
| BR-ADM-012 | Aadhar unique when provided — service layer only (not DB UNIQUE) | Check in `ApplicationService` before insert |
| BR-ADM-013 | Seat capacity guard: allotment blocked if seats_allotted >= total_seats | `MeritListService::allotSeat()` checks `adm_seat_capacity` |
| BR-ADM-014 | Offer expires after N days; daily job auto-promotes next waitlisted | `PromoteExpiredOffersJob` (scheduled daily) |
| BR-ADM-015 | Sibling bonus only if `is_sibling = 1` (staff-confirmed); auto-detect alone insufficient | `adm_applications.is_sibling` must be staff-set to 1 |

---

## State Machines

### Application Lifecycle FSM

```
[Draft]
  ├─(fee paid + submit)──► [Submitted]
  │                              │
  │              ┌───────────────┤
  │              ▼               ▼
  │         (docs OK)     (docs incomplete)
  │        [Verified]     return to [Draft]
  │              │
  │        ┌─────┴──────┐
  │        ▼             ▼
  │  [Shortlisted]   [Rejected]
  │        │
  │   ┌────┴────┐
  │   ▼         ▼
  │ [Allotted] [Waitlisted]
  │   │              │
  │   │     (seat freed)──► [Allotted]
  │   │
  │ (offer accepted + adm fee paid)
  │   │
  │   ▼
  │ [Enrolled] ✅
  │
  └─(any stage before Enrolled)──► [Withdrawn]
```

All transitions logged to `adm_application_stages`.

### Allotment Offer FSM

```
[Offered]
  ├─(parent accepts)──────► [Accepted] → enrollment queue
  ├─(parent declines)─────► [Declined] → next waitlisted promoted
  └─(offer_expires_at past)─► [Expired] → PromoteExpiredOffersJob
```

### Enquiry Lead FSM

```
[New] → [Assigned] → [Contacted]
  ├──► [Interested] ──(form started)──► [Converted] ✅
  ├──► [Not_Interested]
  ├──► [Callback]
  └──► [Duplicate]
```

### Refund FSM (adm_withdrawals)

```
[Not_Eligible] — no fee paid or outside window
[Pending]       — fee paid; refund computed
  ├──► [Approved] ──► [Paid]
  └──► [Not_Eligible] — policy window expired
```

### Promotion Batch FSM

```
[Draft] → [Confirmed] ✅
  (std_student_academic_sessions created for new session; idempotent re-run safe)
```

---

## Cross-Module Dependencies

### Inbound (ADM reads from / integrates with)

| Module | Tables / Channel | Integration Point |
|--------|-----------------|-------------------|
| SystemConfig (SYS) | `sys_users`, `sys_roles`, `sys_media`, `sys_settings` | Auth, RBAC, file uploads, payment gateway keys, audit logs |
| SchoolSetup (SCH) | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_org_academic_sessions_jnt` | Class/section selection, session for enrollment and promotion |
| StudentProfile (STD) | `std_students`, `std_guardians`, `std_siblings_jnt` | Sibling detection (guardian mobile match); enrollment writes here |
| StudentFee (FIN) | `fin_invoices`, `fin_fee_structures` | Application and admission fee invoice generation; TC fee-clearance check |
| Payment (PAY) | Webhook events | Online fee payment for application and admission fee |
| Notification (NTF) | Event-driven dispatch | Stage transitions, hall ticket, offer letter, expiry reminders |
| GlobalMaster (GLB) | `glb_countries`, `glb_states`, `glb_boards` | Address dropdowns; board for previous school |
| LmsExam (EXM) | `exm_*` result tables | Promotion criteria — cross-reference pass/fail results |

### Outbound (Modules that depend on ADM)

| Module | Dependency |
|--------|-----------|
| StudentProfile (STD) | Enrollment seeds `sys_users`, `std_students`, `std_student_academic_sessions` |
| Attendance | Requires enrolled students from `std_student_academic_sessions.is_current = 1` |
| StudentFee (FIN) | Fee assignments depend on enrolled student records |
| LmsExam (EXM) | Exam results feed back into promotion criteria |
| Timetable | Class strength counts from enrolled student count per class section |
| ParentPortal (PPT) | Parent account creation triggered on enrollment by ADM |

### Critical Integration: Enrollment Service

`EnrollmentService::enrollStudent()` makes **cross-module writes** in a single `DB::transaction()`:
1. Create `sys_users` (role=Student)
2. Create `std_students`
3. Create `std_student_academic_sessions`
4. Update `adm_allotments.status = Enrolled` + set `enrolled_student_id`
5. Link sibling in `std_siblings_jnt` if `adm_applications.is_sibling = 1`

If any step fails → full rollback. No partial enrollment records.

---

## Design Decisions Made

1. **Aadhar uniqueness is service-layer only**: `aadhar_no` has only a non-unique index in DDL. Uniqueness check in `ApplicationService` before insert, not via DB UNIQUE constraint. Duplicate Aadhar shows warning, does not block submission.

2. **`adm_document_checklist.admission_cycle_id` is nullable for global templates**: System default checklist items (seeded) have `admission_cycle_id = NULL, is_system = 1`. School-specific overrides have `admission_cycle_id` set. Seeder must create system defaults first.

3. **Merit list is self-contained**: `adm_merit_lists.sibling_bonus_score` and `cutoff_score` are copied from cycle config at generation time. If cycle config changes after generation, the merit list scores remain consistent.

4. **Waitlist auto-promotion is job-based**: `PromoteExpiredOffersJob` runs daily. When an offer expires or is declined, the next waitlisted `adm_merit_list_entries` record is promoted automatically by `AdmissionPipelineService::promoteWaitlisted()`. No real-time promotion trigger.

5. **Public routes are rate-limited**: `/apply/{slug}` and `/apply/status/{app_no}` have no auth middleware. `throttle:10,1` (10 req/min) applied to enquiry/application submission. Status check endpoint is lighter throttle.

6. **`adm_admission_no` is nullable UNIQUE**: Admission number `adm_allotments.admission_no` is NULL until offer letter is issued. MySQL UNIQUE allows multiple NULLs. Number is generated from `adm_admission_cycles.admission_no_format` template at offer letter generation.

7. **Behavior assessment future extraction flagged**: Req doc notes `adm_behavior_*` tables may be extracted into standalone `BEH` module in a future V3 iteration. For now, they are part of ADM. Do not design strong coupling between behavior tables and the rest of ADM.

8. **NEP 2020 warning is non-blocking**: Entrance tests for Classes 1–2 emit a validation warning, not an error. School admin can proceed anyway — warning is advisory only.

9. **Promotion is idempotent**: `PromotionService` uses `firstOrCreate` logic. Re-running a Confirmed batch does not duplicate `std_student_academic_sessions` records.

10. **Payment webhook is idempotency-safe**: `/api/v1/admission/payment/webhook` excludes `auth:sanctum` middleware; payment confirmation uses signature verification. Safe to replay duplicate webhook events (fee marked paid only once).

---

## Auto-Generated Numbers & Sequences

| Field | Format | Where Generated |
|-------|--------|----------------|
| `adm_enquiries.enquiry_no` | `ENQ-YYYY-NNNNN` | `AdmissionPipelineService` on first save |
| `adm_applications.application_no` | `APP-YYYY-NNNNN` | `AdmissionPipelineService` on first save |
| `adm_entrance_test_candidates.roll_no` | Sequential per test | Auto-assigned on candidate list generation |
| `adm_allotments.admission_no` | School-configurable template e.g. `{YEAR}/{SEQ}` | `EnrollmentService` at offer letter generation |
| `adm_transfer_certificates.tc_number` | `TC-YYYY-NNN` | `TransferCertificateService` per school-year |

---

## V2 New Additions vs V1

| Change | Details |
|--------|---------|
| 🆕 `adm_seat_capacity` table | Real-time seat fill counters per class per quota; replaces static `adm_quota_config.total_seats` for runtime tracking |
| 🆕 `adm_withdrawals` table | Full withdrawal + refund workflow missing in V1 |
| 🆕 FR-ADM-08 Withdrawal & Refund | Withdrawal reason, refund policy JSON, refund status lifecycle |
| 🆕 FR-ADM-13 Analytics Funnel | Enquiry → Applied → Verified → Shortlisted → Allotted → Enrolled funnel with conversion rates |
| 🆕 FR-ADM-14 Sibling Preference | Auto-detect at enquiry; staff-confirm at application; +5 merit bonus (configurable) |
| 🆕 Columns in `adm_enquiries` | `is_sibling_lead`, `sibling_student_id`, `is_duplicate` |
| 🆕 Columns in `adm_applications` | `is_sibling`, `sibling_student_id`, `is_staff_ward` |
| 🆕 Columns in `adm_allotments` | `offer_expires_at`, `Withdrawn` enum value |
| 🆕 Columns in `adm_admission_cycles` | `admission_no_format`, `sibling_bonus_score`, `age_rules_json`, `refund_policy_json` |
| 🆕 Column in `adm_merit_list_entries` | `sibling_bonus_applied` |
| 🆕 Column in `adm_transfer_certificates` | `is_duplicate`, `original_tc_id` |
| 🆕 Job | `PromoteExpiredOffersJob` for waitlist auto-promotion |

---

## Implementation Sequence (Recommended)

| Phase | Components | Prerequisites |
|-------|-----------|---------------|
| Phase 1 | `adm_admission_cycles` + `adm_document_checklist` + `adm_quota_config` + `adm_seat_capacity` + `adm_enquiries` + `adm_follow_ups` + `adm_applications` + `adm_application_documents` + `adm_application_stages` | SYS + SCH + GLB done |
| Phase 2 | `adm_entrance_tests` + `adm_entrance_test_candidates` + `adm_merit_lists` + `adm_merit_list_entries` + `adm_allotments` | Phase 1 done |
| Phase 3 | Offer Letter PDF + Admission Fee + PAY webhook | PAY module; Phase 2 done |
| Phase 4 | `EnrollmentService` — writes `std_students` + `std_student_academic_sessions` | STD module ready; Phase 3 done |
| Phase 5 | `adm_withdrawals` + refund workflow | FIN module; Phase 4 done |
| Phase 6 | `adm_promotion_batches` + `adm_promotion_records` + `adm_transfer_certificates` | LmsExam results; Phase 4 done |
| Phase 7 | `adm_behavior_incidents` + `adm_behavior_actions` + Analytics Funnel | Phase 4 done |

---

## Technology Stack Notes

- **PDF Generation**: DomPDF — offer letter, hall ticket, Transfer Certificate (with QR code)
- **QR Code on TC**: Links to public verification endpoint; `SimpleSoftwareIO/simple-qrcode` or similar
- **Payment**: Razorpay/PayU webhook via PAY module pattern; no-auth route; signature verified in service
- **Queues**: Laravel Queue — `PromoteExpiredOffersJob` (daily scheduler), NTF notifications at each stage transition
- **Sibling detection**: Runs synchronously on enquiry save; matches `contact_mobile` vs `std_guardians.mobile_no`
- **Aadhar encryption**: At-rest AES-256 (NFR); model accessor/mutator for encryption/decryption
- **Public form**: Outside `auth` middleware; `throttle:10,1`; CSRF protected; WCAG 2.1 AA required

---

## Pending Next Steps

- [ ] Generate FRD → `act as Business Analyst` → "create an FRD for Admission Mgmt."
- [ ] DDL Gap Analysis → `act as DB Architect` — verify all 20 tables, especially aadhar_no index strategy
- [ ] Confirm `sys_users.id` = INT UNSIGNED before migration to ensure FK types match (DDL-005)
- [ ] Implement `PromoteExpiredOffersJob` as a daily scheduled command
- [ ] Decide on Aadhar encryption strategy before migration (model mutator vs application-level)
- [ ] Validate that `std_student_academic_sessions` UNIQUE constraint exists in STD DDL (roll_no enforcement, BR-ADM-008, BR-ADM-010)

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from ADM_Admission_Requirement.md v2 + AdmissionMgmt_DDL_v1.sql (20 tables). 5 DDL deviations documented. |
