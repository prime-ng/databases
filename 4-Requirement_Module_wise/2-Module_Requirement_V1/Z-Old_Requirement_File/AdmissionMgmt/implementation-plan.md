# Admission Management Module — Requirements Index

## Purpose
Master index of all per-tab requirement files. Each tab below has its own `.md` file with detailed database fields, business rules, CRUD operations, and permissions.

---

## Module Identity

| Attribute | Value |
|---|---|
| Module Code | ADM |
| Laravel Namespace | `Modules\Admission` |
| Route Prefix | `admission/` |
| Route Name Prefix | `adm.` |
| DB Table Prefix | `adm_*` |
| Database | `tenant_db` (DB per tenant, no `tenant_id` column) |
| Module Type | Tenant-scoped |
| Implementation Status | 0% — Greenfield |

## Tab → Requirement File Map

| Tab | Requirement File | Key Tables | Summary |
|---|---|---|---|
| **Admission Cycles** | `admission-cycles.md` | `adm_admission_cycles`, `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity` | Annual cycle configuration, seat budgets, document requirements, quota settings |
| **Enquiries & CRM** | `enquiries.md` | `adm_enquiries`, `adm_follow_ups` | Lead capture from web/walk-in/campaign, CRM follow-ups, sibling detection |
| **Applications** | `applications.md` | `adm_applications`, `adm_application_documents`, `adm_application_stages` | Multi-step application form, document upload & verification, interview scheduling, status FSM |
| **Entrance Tests** | `entrance-tests.md` | `adm_entrance_tests`, `adm_entrance_test_candidates` | Test session management, candidate registration, marks entry |
| **Merit List & Allotment** | `merit-allotment.md` | `adm_merit_lists`, `adm_merit_list_entries`, `adm_allotments` | Merit list generation, seat allotment with capacity guard, waitlist auto-promotion |
| **Offer Letter & Enrollment** | `offer-enrollment.md` | `adm_allotments` (offer/enrollment logic) | Offer letter (DomPDF + QR), admission fee payment, atomic enrollment conversion |
| **Withdrawals & Refund** | `withdrawals.md` | `adm_withdrawals` | Withdrawal recording, refund computation per cycle policy, post-enrollment withdrawal |
| **Promotion** | `promotion.md` | `adm_promotion_batches`, `adm_promotion_records` | Year-end promotion wizard with exam pass/fail, manual overrides, batch confirmation |
| **Alumni & TC** | `alumni-tc.md` | `adm_transfer_certificates` | TC issuance with QR code, FIN fee clearance check, alumni status management |
| **Behavior Incidents** | `behavior.md` | `adm_behavior_incidents`, `adm_behavior_actions` | Disciplinary incident tracking, corrective actions, behavior scoring |
| **Analytics & Dashboard** | `analytics-dashboard.md` | Reads all `adm_*` tables | Admission funnel, lead source breakdown, quota fill, counselor performance, behavior score |

---

## Entity Summary (20 Tables)

| # | Table | Layer | Domain | Description |
|---|---|---|---|---|
| 1 | `adm_admission_cycles` | L1 | Config | Annual admission campaign configuration |
| 2 | `adm_document_checklist` | L2 | Config | Required document definitions per cycle/class |
| 3 | `adm_quota_config` | L2 | Config | Quota settings per class — seats, RTE reserved, fee waiver |
| 4 | `adm_seat_capacity` | L2 | Config | Running seat counters with allotted/enrolled counters |
| 5 | `adm_enquiries` | L3 | CRM | Inbound leads from web/walk-in/campaign |
| 6 | `adm_follow_ups` | L4 | CRM | Follow-up activity log per enquiry |
| 7 | `adm_entrance_tests` | L2 | Test | Test session schedule and marks configuration |
| 8 | `adm_applications` | L4 | Pipeline | Full application record with multi-step data and status FSM |
| 9 | `adm_application_documents` | L5 | Pipeline | Uploaded documents with verification workflow |
| 10 | `adm_application_stages` | L5 | Pipeline | Immutable audit trail of status transitions |
| 11 | `adm_entrance_test_candidates` | L5 | Test | Candidate registration and marks per test |
| 12 | `adm_merit_lists` | L3 | Merit | Merit list header per cycle/class/quota |
| 13 | `adm_merit_list_entries` | L5 | Merit | Ranked applicant entries with scores |
| 14 | `adm_allotments` | L6 | Allotment | Seat allotment offers with enrollment link |
| 15 | `adm_withdrawals` | L7 | Withdrawal | Withdrawal and refund computation records |
| 16 | `adm_promotion_batches` | L6 | Promotion | Year-end promotion batch header |
| 17 | `adm_promotion_records` | L7 | Promotion | Per-student promotion decisions |
| 18 | `adm_transfer_certificates` | L8 | TC | TC issuance log with QR PDF |
| 19 | `adm_behavior_incidents` | L8 | Behavior | Disciplinary incident log |
| 20 | `adm_behavior_actions` | L9 | Behavior | Corrective actions per incident |

---

## Business Rules Summary (15 Rules)

| ID | Rule | Enforcement |
|---|---|---|
| BR-ADM-001 | Age eligibility (configurable, non-blocking warning) | Form validation |
| BR-ADM-002 | Enrollment is atomic (DB::transaction — all-or-nothing) | Service layer |
| BR-ADM-003 | Admission number unique within school-year | DB UNIQUE + service |
| BR-ADM-004 | TC only after FIN fee clearance | Service layer |
| BR-ADM-005 | RTE quota: 25% Class 1 reserved; fee waived | Service layer |
| BR-ADM-006 | Application fee non-refundable by default | Service layer |
| BR-ADM-007 | All mandatory docs must be Verified before advancing | Service layer |
| BR-ADM-008 | Roll numbers unique within class section per session | DB UNIQUE + service |
| BR-ADM-009 | Promotion appends new records; old is_current=0 | Service layer |
| BR-ADM-010 | One enrollment per student per session | DB UNIQUE + service |
| BR-ADM-011 | NEP 2020: no entrance tests for Class 1-2 (warning) | Form validation |
| BR-ADM-012 | Aadhar unique when provided (service layer only) | Service layer |
| BR-ADM-013 | Seat capacity guard (allot blocked if full) | Service layer |
| BR-ADM-014 | Offer expiry auto-triggers waitlist promotion | Scheduled job |
| BR-ADM-015 | Sibling bonus requires staff-confirmed is_sibling=1 | Service layer |

---

## Services Architecture (6)

| Service | Responsibility |
|---|---|
| `AdmissionPipelineService` | Cycle activation, enquiry→app conversion, application submission/verification, withdrawal/refund, waitlist promotion, fee confirmation |
| `MeritListService` | Merit list generation (composite scoring, ranking, classification), seat allotment |
| `EnrollmentService` | Atomic student enrollment (sys_users + std_students + std_student_academic_sessions), auto-section assignment, roll number assignment, bulk enrollment |
| `TransferCertificateService` | TC issuance (FIN check, DomPDF, QR code, student status update) |
| `PromotionService` | Batch creation, exam criteria application, manual override, preview, batch confirmation |
| `AdmissionAnalyticsService` | Funnel analysis, lead source breakdown, quota fill report, counselor performance, behavior score |

---

## Integration Contracts (6)

| Integration | ADM Action | External Module |
|---|---|---|
| STD enrollment write | Create student records inside DB::transaction() | StudentProfile |
| FIN application fee invoice | Trigger invoice for application fee | StudentFee |
| FIN fee clearance check | Balance check before TC issuance | StudentFee |
| PAY webhook | Confirm fee payment (idempotent) | Payment |
| NTF notifications | Dispatch at each stage transition | Notification |
| LmsExam promotion criteria | Read exam results for pass/fail | LmsExam |

---

## Public Routes (No Auth)

| Route | Purpose |
|---|---|
| `GET /apply/{slug}` | Public application form |
| `GET /apply/status/{app_no}` | Application status check |
| `POST /api/v1/admission/payment/webhook` | Payment confirmation |

---

## Development Phases

| Phase | Focus | FRs Covered | Key Files |
|---|---|---|---|
| 1 | Admission Cycle Config, Enquiry CRM, Online Application | Cycles, Enquiries, Applications | 4 config tables + 2 enquiry/app tables |
| 2 | Document Verification, Entrance Tests, Merit List, Allotment | Entrance Tests, Merit/Allotment | 8 tables (tests, merit, allotment) |
| 3 | Offer Letter, Fee Payment, Enrollment | Offer/Enrollment | Allotment + enrollment service |
| 4 | Bulk Enrollment, Sibling Linking | Enrollment | EnrollmentService |
| 5 | Withdrawal & Refund | Withdrawals | Withdrawals table |
| 6 | Promotion, Alumni, TC | Promotion, Alumni/TC | 4 tables (promotion, TC) |
| 7 | Behavior Incidents, Analytics | Behavior, Dashboard | 2 behavior tables + analytics service |

## Key Architecture Decisions

1. **No `tenant_id` column** — stancl/tenancy v3.9 uses database-per-tenant isolation.
2. **ADM is the ONLY module that creates student records** — `EnrollmentService::enrollStudent()` WRITES to `sys_users`, `std_students`, `std_student_academic_sessions` inside a single `DB::transaction()`.
3. **Result integration is pull-based** — Report/Result modules call `EnrollmentService` / `PromotionService` as needed.
4. **Aadhar has NO DB UNIQUE constraint** — uniqueness enforced at service layer due to MySQL NULL handling.
5. **Admission number format is configurable** per cycle via `admission_no_format` template string.
6. **Seat capacity counters are atomically incremented** — never set directly; `seats_allotted` and `seats_enrolled` are updated by services.
