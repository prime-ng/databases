# ADM — Admission Management Module

## Module Identity

| Attribute | Value |
|-----------|-------|
| Module Code | ADM |
| Laravel Namespace | `Modules\Admission` |
| Module Directory | `Modules/Admission/` |
| Route Prefix | `admission/` |
| Route Name Prefix | `adm.` |
| DB Table Prefix | `adm_` |
| Database | `tenant_db` (DB per tenant, no `tenant_id` column) |
| Module Type | Tenant-scoped |
| RBS Module Code | C (Admissions & Student Lifecycle) |
| Implementation Status | 0% — Greenfield |

## Module Scale

| Artifact | Count |
|----------|-------|
| Controllers | 14 |
| Models | 20 |
| Services | 6 |
| FormRequests | 12 |
| `adm_*` Tables | 20 |
| Blade Views (estimated) | ~55 |
| Seeders | 2 + 1 runner |
| Jobs | 2 (WaitlistPromotionJob, OfferExpiryJob) |

## Scope

**In-Scope Features (15 FRs across 7 Phases):**
- **Phase 1**: Admission Cycle Config, Seat Capacity, Document Checklist, Quota Config, Lead Capture & Enquiry Management, Follow-up CRM, Online Application Form
- **Phase 2**: Document Verification, Interview Scheduling, Entrance Test Management, Merit List Generation, Quota-based Seat Allotment, Waitlist Auto-Promotion
- **Phase 3**: Offer Letter, Admission Fee Invoice, Online Payment Webhook Confirmation
- **Phase 4**: Final Enrollment Conversion (WRITES `sys_users` + `std_students` + `std_student_academic_sessions`), Sibling Linking, Auto-Section Assignment, Bulk Enrollment
- **Phase 5**: Withdrawal Recording, Refund Computation
- **Phase 6**: Promotion Wizard, Alumni Management, Transfer Certificate (TC) with QR
- **Phase 7**: Behavior Incident Management, Admission Analytics Funnel

**Authoritative Source:** ADM module is the ONLY source that creates new student records via `EnrollmentService::enrollStudent()`.

## Requirement Files

| # | File | Phase | Key Tables | Summary |
|---|------|-------|------------|---------|
| 1 | [Requirements/admission-cycles.md](Requirements/admission-cycles.md) | 1 | `adm_admission_cycles`, `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity` | Annual cycle configuration, seat budgets, document requirements, quota settings |
| 2 | [Requirements/enquiries.md](Requirements/enquiries.md) | 1 | `adm_enquiries`, `adm_follow_ups` | Lead capture from web/walk-in/campaign, CRM follow-ups, sibling detection |
| 3 | [Requirements/applications.md](Requirements/applications.md) | 1-2 | `adm_applications`, `adm_application_documents`, `adm_application_stages` | Multi-step application form, document upload & verification, interview scheduling, status FSM |
| 4 | [Requirements/entrance-tests.md](Requirements/entrance-tests.md) | 2 | `adm_entrance_tests`, `adm_entrance_test_candidates` | Test session management, candidate registration, marks entry |
| 5 | [Requirements/merit-allotment.md](Requirements/merit-allotment.md) | 2 | `adm_merit_lists`, `adm_merit_list_entries`, `adm_allotments` | Merit list generation, seat allotment with capacity guard, waitlist auto-promotion |
| 6 | [Requirements/offer-enrollment.md](Requirements/offer-enrollment.md) | 3-4 | `adm_allotments` (offer/enrollment logic) | Offer letter (DomPDF + QR), admission fee payment, atomic enrollment conversion |
| 7 | [Requirements/withdrawals.md](Requirements/withdrawals.md) | 5 | `adm_withdrawals` | Withdrawal recording, refund computation per cycle policy, post-enrollment withdrawal |
| 8 | [Requirements/promotion.md](Requirements/promotion.md) | 6 | `adm_promotion_batches`, `adm_promotion_records` | Year-end promotion wizard with exam pass/fail, manual overrides, batch confirmation |
| 9 | [Requirements/alumni-tc.md](Requirements/alumni-tc.md) | 6 | `adm_transfer_certificates` | TC issuance with QR code, FIN fee clearance check, alumni status management |
| 10 | [Requirements/behavior.md](Requirements/behavior.md) | 7 | `adm_behavior_incidents`, `adm_behavior_actions` | Disciplinary incident tracking, corrective actions, behavior scoring |
| 11 | [Requirements/analytics-dashboard.md](Requirements/analytics-dashboard.md) | 7 | Reads all `adm_*` tables | Admission funnel, lead source breakdown, quota fill, counselor performance, behavior score |

## Business Rules (15)

| ID | Rule | Enforcement |
|----|------|-------------|
| BR-ADM-001 | Age eligibility (configurable per class, non-blocking warning) | Form validation |
| BR-ADM-002 | Enrollment is atomic (DB::transaction — all-or-nothing) | Service layer |
| BR-ADM-003 | Admission number unique within school-year | DB UNIQUE + service |
| BR-ADM-004 | TC only after FIN fee clearance | Service layer |
| BR-ADM-005 | RTE quota: 25% Class 1 reserved; fee waived | Service layer |
| BR-ADM-006 | Application fee non-refundable by default | Service layer |
| BR-ADM-007 | All mandatory docs must be Verified before advancing | Service layer |
| BR-ADM-008 | Roll numbers unique within class section per session | DB UNIQUE + service |
| BR-ADM-009 | Promotion appends new records; old is_current=0 | Service layer |
| BR-ADM-010 | One enrollment per student per session | DB UNIQUE + service |
| BR-ADM-011 | NEP 2020: no entrance tests for Class 1-2 (non-blocking warning) | Form validation |
| BR-ADM-012 | Aadhar unique when provided (service layer only) | Service layer |
| BR-ADM-013 | Seat capacity guard (allot blocked if full) | Service layer |
| BR-ADM-014 | Offer expiry auto-triggers waitlist promotion | Scheduled job |
| BR-ADM-015 | Sibling bonus requires staff-confirmed is_sibling=1 | Service layer |

## Services Architecture (6)

| Service | Responsibility |
|---------|---------------|
| `AdmissionPipelineService` | Cycle activation, enquiry→application conversion, application submission/verification, withdrawal/refund, waitlist promotion, fee confirmation |
| `MeritListService` | Merit list generation (composite scoring, ranking, classification), seat allotment |
| `EnrollmentService` | Atomic student enrollment (sys_users + std_students + std_student_academic_sessions), auto-section assignment, roll number assignment, bulk enrollment |
| `TransferCertificateService` | TC issuance (FIN check, DomPDF, QR code, student status update) |
| `PromotionService` | Batch creation, exam criteria application, manual override, preview, batch confirmation |
| `AdmissionAnalyticsService` | Funnel analysis, lead source breakdown, quota fill report, counselor performance, behavior score |

## Integration Contracts (6)

| Integration | ADM Action | External Module |
|-------------|-----------|-----------------|
| STD enrollment write | Create student records inside DB::transaction() | StudentProfile |
| FIN application fee invoice | Trigger invoice for application fee | StudentFee |
| FIN fee clearance check | Balance check before TC issuance | StudentFee |
| PAY webhook | Confirm fee payment (idempotent) | Payment |
| NTF notifications | Dispatch at each stage transition | Notification |
| LmsExam promotion criteria | Read exam results for pass/fail | LmsExam |

## Public Routes (No Auth)
- `GET /apply/{slug}` — Public application form
- `GET /apply/status/{app_no}` — Application status check
- `POST /api/v1/admission/payment/webhook` — Payment confirmation

## Dependencies
- SchoolSetup (SCH) — Classes, sections, academic sessions (READ)
- System (SYS) — Users, media (READ + WRITE)
- StudentProfile (STD) — Students, guardians, siblings (READ + WRITE on enrollment)
- Finance (FIN) — Fee invoices, balance checks (service call)
- Payment (PAY) — Payment webhook processing
- Notification (NTF) — Email/SMS dispatch
- LmsExam (EXM) — Exam results for promotion (READ, graceful fallback)

## Key Paths
- **DDL:** `AdmissionMgmt/DDL/ADM_DDL_v1.sql`
- **Feature Spec:** `AdmissionMgmt/Design/ADM_FeatureSpec.md`
- **Table Summary:** `AdmissionMgmt/Design/ADM_TableSummary.md`
- **Migration Stub:** `AdmissionMgmt/Design/ADM_Migration.php`
- **Full Requirement:** `9-Support/Project_Requirement/V2/ADM_Admission_Requirement.md`
- **Per-Feature Requirements:** `AdmissionMgmt/Requirements/*.md`
