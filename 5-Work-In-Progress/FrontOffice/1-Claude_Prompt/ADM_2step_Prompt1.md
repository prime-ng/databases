# ADM — Admission Management Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **ADM (Admission Management)** module using `ADM_Admission_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `ADM_FeatureSpec.md` — Feature Specification
2. `ADM_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `ADM_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**Module:** AdmissionMgmt — Complete pre-enrollment lifecycle management for Indian K-12 schools.
Tables: `adm_*` (20 tables covering cycle config, seat capacity, enquiries, applications, documents, entrance tests, merit lists, allotments, withdrawals, enrollment, promotions, alumni/TC, behavior incidents).

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = ADM
MODULE            = Admission
MODULE_DIR        = Modules/Admission/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = C                              # Admissions & Student Lifecycle in RBS v4.0
DB_TABLE_PREFIX   = adm_                           # Single prefix — all tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/FrontOffice/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/ADM_Admission_Requirement.md

FEATURE_FILE      = ADM_FeatureSpec.md
DDL_FILE_NAME     = ADM_DDL_v1.sql
DEV_PLAN_FILE     = ADM_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — ADM (ADMISSION MANAGEMENT) MODULE

### What This Module Does

The Admission module provides a **complete pre-enrollment lifecycle management system** for Indian K-12 schools on the Prime-AI SaaS platform. It replaces paper registers and manual admission processes — covering the full pipeline from the first point of contact (enquiry/lead) through online/offline application, document verification, entrance assessment, quota-based merit list, seat allotment, offer letter, online payment, final enrollment (which writes to StudentProfile), and post-enrollment features (promotion wizard, alumni/TC, behavior incidents).

**Phase 1 — Cycle Setup + Enquiry + Application:**
- Admission Cycle Configuration: annual cycle with open/close dates, fee, public form slug, refund policy, age rules
- Seat Capacity Management: per-class per-quota seat budget with allotted/enrolled tracking
- Document Checklist: configurable mandatory/optional document requirements per cycle/class
- Quota Configuration: General/Government/Management/RTE/NRI/Staff_Ward/Sibling/EWS with fee waiver support
- Lead Capture & Enquiry: ENQ-YYYY-NNNNN, sibling auto-detect, counselor assignment (round-robin), duplicate detection, public URL form (unauthenticated, rate-limited)
- Application Form: multi-step wizard (student → guardian → prev school → documents → fee), APP-YYYY-NNNNN, draft resume, application status public tracker

**Phase 2 — Verification + Entrance Test + Merit + Allotment:**
- Document Verification: per-document Verified/Rejected, application return-for-correction, bulk approval actions
- Interview Scheduling: slot, venue, interviewer, score entry
- Entrance Test Management: candidate list generation, hall ticket PDF (DomPDF), mark entry, NEP 2020 warning for Classes 1–2
- Merit List Generation: composite score (entrance %, interview %, academic %), sibling +5 bonus, tie-break by date/DOB, Shortlisted/Waitlisted/Rejected
- Seat Allotment: quota capacity guard, offer letter PDF (DomPDF), offer FSM (Offered → Accepted/Declined/Expired)
- Waitlist Auto-Promotion: scheduled daily job promotes next waitlisted when seat is freed

**Phase 3 — Offer Letter + Payment:**
- Admission Fee Invoice: generated via FIN module (`fin_invoices`)
- Online Payment: Razorpay/PayU webhook confirmation; idempotent re-delivery; signature verification
- Offer acceptance: parent confirms online or staff marks confirmed

**Phase 4 — Enrollment Conversion:**
- Atomic Enrollment Transaction: `sys_users` + `std_students` + `std_student_academic_sessions` in single `DB::transaction()`
- Sibling linking on enrollment via `std_siblings_jnt`
- Auto-balance section assignment; roll number assignment
- Bulk enrollment from queue
- Enrolled student immediately visible in ATT, Timetable, FIN modules

**Phase 5 — Withdrawal + Refund:**
- Withdrawal recording with reason; refund computed per `refund_policy_json` (% tiers by days)
- Refund instruction passed to FIN; `adm_withdrawals.refund_status` tracked

**Phase 6 — Promotion + Alumni + TC:**
- Promotion Wizard: preview/dry-run → confirm; cross-reference LmsExam results; detained/promoted/left classification
- Alumni Management: mark leaving, disable login, close academic records
- Transfer Certificate: fee-clearance check via FIN, DomPDF with QR code, TC-YYYY-NNN unique per year

**Phase 7 — Behavior + Analytics:**
- Behavior Incident Log: severity-based (Low/Medium/High/Critical), Critical auto-notifies principal+parent, corrective actions, repeat offender detection (≥3 incidents/term)
- Admission Analytics Funnel: Enquiry → Applied → Verified → Shortlisted → Allotted → Enrolled funnel, source attribution, quota fill, counselor performance

### Architecture Decisions
- **Single Laravel module** (`Modules\Admission`) — all 7 phases in one module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `admission/` | Route name prefix: `adm.`
- Enrollment integration: `EnrollmentService::enrollStudent()` WRITES to `std_students`, `sys_users`, `std_student_academic_sessions` — ADM module is the authoritative source for new student creation
- FIN integration: `AdmissionPipelineService::confirmAdmissionFee()` uses FIN module invoice; `TransferCertificateService` calls FIN for fee-clearance check
- PAY integration: payment webhook route excluded from `auth:sanctum` middleware; signature-verified only; idempotent processing
- NTF integration: event-driven notifications at every key stage transition (enquiry welcome, submission, verified, shortlisted, offer, enrollment, TC)
- LmsExam integration: `PromotionService` reads `exm_*` tables to cross-reference pass/fail criteria
- Public routes: `/apply/{slug}`, `/apply/status/{app_no}` — rate-limited (10/hour per IP), no auth required
- Offer letter + Hall ticket + TC: DomPDF; stored in `sys_media`
- Aadhar numbers: encrypted at rest per tenant policy; restricted role access; partial UNIQUE index (nullable)

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | 14 |
| Models | 20 |
| Services | 6 |
| FormRequests | 12 |
| adm_* tables | 20 |
| Blade views (estimated) | ~55 |
| Seeders | 2 (document checklist defaults + quota defaults) + 1 runner |

### Complete Table Inventory

**Configuration (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `adm_admission_cycles` | Annual cycle config | UNIQUE `(cycle_code)`; one Active per academic session |
| 2 | `adm_document_checklist` | Required docs per cycle/class | Index `(admission_cycle_id, class_id)` |
| 3 | `adm_quota_config` | Quota settings per class | Index `(admission_cycle_id, class_id, quota_type)` |
| 4 | `adm_seat_capacity` | Per-class per-quota seat budget | UNIQUE `(admission_cycle_id, class_id, quota_type)` |

**Enquiry & CRM (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 5 | `adm_enquiries` | Raw leads | UNIQUE `(enquiry_no)`; Index `(contact_mobile, admission_cycle_id)` |
| 6 | `adm_follow_ups` | Follow-up activity log | Index `(enquiry_id, scheduled_at)` |

**Application Pipeline (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 7 | `adm_applications` | Full application records | UNIQUE `(application_no)`; Partial UNIQUE `(aadhar_no)` where NOT NULL |
| 8 | `adm_application_documents` | Uploaded docs per application | UNIQUE `(application_id, checklist_item_id)` |
| 9 | `adm_application_stages` | Stage audit trail | Index `(application_id, changed_at)` |
| 10 | `adm_withdrawals` | Withdrawal + refund tracking | Index `(application_id)`; `refund_status` ENUM |

**Entrance Test (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 11 | `adm_entrance_tests` | Test sessions per class per cycle | Index `(admission_cycle_id, class_id, test_date)` |
| 12 | `adm_entrance_test_candidates` | Candidate results | UNIQUE `(entrance_test_id, application_id)` |

**Merit & Allotment (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 13 | `adm_merit_lists` | Merit list per cycle+class+quota | Index `(admission_cycle_id, class_id, quota_type)` |
| 14 | `adm_merit_list_entries` | Ranked applicant entries | Index `(merit_list_id, merit_rank)`; Index `(application_id)` |
| 15 | `adm_allotments` | Seat allotment record | UNIQUE `(admission_no)` nullable; `enrolled_student_id` FK→std_students |

**Promotion (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 16 | `adm_promotion_batches` | Year-end promotion batch | Index `(from_session_id, from_class_id, status)` |
| 17 | `adm_promotion_records` | Per-student promotion decision | Index `(promotion_batch_id, student_id)` |

**Alumni & TC (1 table):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 18 | `adm_transfer_certificates` | TC issuance log | UNIQUE `(tc_number)`; self-ref `original_tc_id` for duplicates |

**Behavior (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 19 | `adm_behavior_incidents` | Disciplinary incident log | Index `(student_id, incident_date, severity)` |
| 20 | `adm_behavior_actions` | Corrective actions per incident | Index `(incident_id)` |

**Existing Tables REUSED (ADM reads from and WRITES TO on enrollment):**
| Table | Source | ADM Usage |
|---|---|---|
| `sys_users` | System | WRITTEN ON ENROLLMENT (student login); also staff/counselor lookups |
| `sys_media` | System | Application documents, offer letter, hall ticket, TC PDF |
| `sys_activity_logs` | System | Audit trail for enrollment, TC issuance, promotion |
| `sch_classes` | SchoolSetup (SCH) | Class selection, seat capacity, entrance test |
| `sch_sections` | SchoolSetup (SCH) | Section assignment on enrollment |
| `sch_class_section_jnt` | SchoolSetup (SCH) | Promotion records source/dest |
| `sch_org_academic_sessions_jnt` | SchoolSetup (SCH) | Admission cycle academic year, promotion session |
| `std_students` | StudentProfile (STD) | WRITTEN ON ENROLLMENT; sibling detection |
| `std_student_academic_sessions` | StudentProfile (STD) | WRITTEN ON ENROLLMENT and PROMOTION |
| `std_guardians` | StudentProfile (STD) | Sibling auto-detect: match contact_mobile against guardian phone |
| `std_siblings_jnt` | StudentProfile (STD) | WRITTEN ON ENROLLMENT for sibling links |
| `fin_invoices` | StudentFee (FIN) | Application fee and admission fee invoice generation |
| `exm_*` | LmsExam (EXM) | Promotion criteria: cross-reference pass/fail exam results |
| `ntf_notifications` | Notification (NTF) | Stage notifications, follow-up reminders, offer alerts |

### Key Integration Events
```
On Enrollment:
  DB::transaction():
    Create sys_users (role=Student)
    Create std_students
    Create std_student_academic_sessions (is_current=1)
    Update adm_allotments.status = Enrolled; set enrolled_student_id
    If is_sibling=1: create std_siblings_jnt record
  → NTF: student login credentials + welcome notification to parent

On Offer Created:
  → DomPDF: offer letter PDF → sys_media
  → NTF: email+SMS to parent with offer details and joining date

On Waitlist Auto-Promotion (daily job):
  → Find adm_allotments where status=Declined OR (status=Offered AND offer_expires_at < TODAY)
  → AdmissionPipelineService::promoteWaitlisted(merit_list_id)
  → Next rank in adm_merit_list_entries (status=Waitlisted) → promoted to Shortlisted
  → New allotment record created → NTF dispatched

On Payment Webhook (PAY module):
  → Signature verified; idempotent check (already marked paid?)
  → adm_applications.application_fee_paid = 1 OR adm_allotments.admission_fee_paid = 1
  → NTF confirmation dispatched

On TC Issuance:
  → FIN fee-clearance check (block if outstanding)
  → DomPDF: TC PDF with QR code → sys_media
  → Unique TC number TC-YYYY-NNN assigned
  → std_students.current_status_id → Alumni; login disabled

On Critical Behavior Incident:
  → NTF auto-dispatched to principal + parent
  → adm_behavior_incidents.parent_notified = 1
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — ADM v2 requirement (15 FRs, Sections 1–15)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: sch_classes, sch_sections, sch_class_section_jnt, sch_org_academic_sessions_jnt, std_students, std_student_academic_sessions, std_guardians, std_siblings_jnt, sys_users, sys_media, fin_invoices (use exact column names in spec)

### Phase 1 Task — Generate `ADM_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix, module type
- In-scope feature groups (all 15 FRs from req v2 Section 2.2 / Phases 1–7)
- Out-of-scope items (fee collection managed by FIN; online payment gateway keys managed by PAY; behavior module is in ADM but flagged as future extraction candidate per req Section 14)
- Module is the authoritative CREATE source for `std_students` and `sys_users` on enrollment
- Module scale table (controller / model / service / FormRequest / table counts)

#### Section 2 — Entity Inventory (All 20 Tables)
For each `adm_*` table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Configuration** (adm_admission_cycles, adm_document_checklist, adm_quota_config, adm_seat_capacity)
- **Enquiry & CRM** (adm_enquiries, adm_follow_ups)
- **Application Pipeline** (adm_applications, adm_application_documents, adm_application_stages, adm_withdrawals)
- **Entrance Test** (adm_entrance_tests, adm_entrance_test_candidates)
- **Merit & Allotment** (adm_merit_lists, adm_merit_list_entries, adm_allotments)
- **Promotion** (adm_promotion_batches, adm_promotion_records)
- **Alumni & TC** (adm_transfer_certificates)
- **Behavior** (adm_behavior_incidents, adm_behavior_actions)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 20 tables grouped by layer (adm_* vs cross-module reads/writes to std_*/sch_*/sys_*/fin_*/exm_*).
Use `→` for FK direction (child → parent). Mark WRITE relationships explicitly.

Critical cross-module FKs to highlight:
- `adm_enquiries.sibling_student_id → std_students.id` (nullable — auto-detected)
- `adm_applications.sibling_student_id → std_students.id` (nullable — staff confirmed)
- `adm_allotments.enrolled_student_id → std_students.id` (nullable — set on enrollment)
- `adm_allotments.offer_letter_media_id → sys_media.id` (INT UNSIGNED — sys_media uses INT)
- `adm_application_documents.media_id → sys_media.id` (INT UNSIGNED)
- `adm_transfer_certificates.media_id → sys_media.id` (INT UNSIGNED)
- `adm_transfer_certificates.original_tc_id → adm_transfer_certificates.id` (self-ref, nullable — duplicate TC)
- `adm_admission_cycles.academic_session_id → sch_org_academic_sessions_jnt.id` (exact table name to verify in DDL)
- `adm_promotion_batches.from_class_section_id → sch_class_section_jnt.id` (verify exact table name)

#### Section 4 — Business Rules (15 rules)
For each rule, state:
- Rule ID (BR-ADM-001 to BR-ADM-015)
- Rule text (from req v2 Section 8)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event` | `scheduled_job` | `policy`

Critical rules to emphasise:
- BR-ADM-002: Enrollment is atomic — `DB::transaction()` wraps sys_users + std_students + std_student_academic_sessions + allotment update; partial rollback on failure
- BR-ADM-004: TC only after all outstanding fees cleared — `TransferCertificateService` calls FIN module
- BR-ADM-007: All mandatory documents must be uploaded before application can move Submitted → Verified — `AdmissionPipelineService::verifyApplication()` checks mandatory docs
- BR-ADM-011: NEP 2020 — entrance tests not allowed for Classes 1–2 — validation warning (non-blocking)
- BR-ADM-012: Aadhar number optional but unique when provided — partial UNIQUE index where NOT NULL
- BR-ADM-013: Seat capacity guard — allotment blocked if `seats_allotted >= total_seats` for selected quota
- BR-ADM-014: Offer expires after N days — scheduled daily job `adm:expire-offers` promotes next waitlisted
- BR-ADM-015: Sibling priority — staff must confirm (`is_sibling=1`) for merit bonus to apply; auto-detect alone insufficient

#### Section 5 — Workflow State Machines (5 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, NTF dispatched)

FSMs to document:
1. **Application Lifecycle FSM** — `Draft → Submitted → Verified/Returned → Shortlisted/Rejected/Waitlisted/Allotted → Enrolled | Withdrawn`
   Side effects: each transition logged to `adm_application_stages`; NTF dispatched at Submitted, Verified, Shortlisted, Allotted, Enrolled
   On Enrolled: atomic DB transaction (sys_users + std_students + std_student_academic_sessions)
2. **Enquiry Lead FSM** — `New → Assigned → Contacted → Interested/Not_Interested/Callback/Converted | Duplicate`
   Side effect on Converted: `AdmissionPipelineService::convertToApplication()` creates `adm_applications` pre-filled from enquiry
3. **Allotment Offer FSM** — `Offered → Accepted → Enrolled | Declined/Expired`
   Side effect on Declined or Expired: `AdmissionPipelineService::promoteWaitlisted()` runs; next waitlisted promoted and notified
4. **Promotion Batch FSM** — `Draft → Confirmed`
   On Confirmed: new `std_student_academic_sessions` created for all students in batch; old records set `is_current=0`; idempotent re-run guard
5. **Withdrawal & Refund FSM** — `Not_Eligible → Pending → Approved → Paid | Not_Eligible`
   Refund amount computed from `adm_admission_cycles.refund_policy_json` at withdrawal time; instruction passed to FIN

#### Section 6 — Functional Requirements Summary (15 FRs)
For each FR-ADM-01 to FR-ADM-15:
| FR ID | Name | Phase | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Group by implementation phase (Phase 1–7 per req v2 Section 11.3).

#### Section 7 — Permission Matrix
| Permission String | Admin | Counselor | Front Office | Principal | Finance Staff | Class Teacher |
|---|---|---|---|---|---|---|

Derive permissions from req v2 Section 3 (Stakeholders & Roles). Include:
- `admission.cycle.*` (CRUD cycle config)
- `admission.enquiry.*`
- `admission.enquiry.assign`
- `admission.application.*`
- `admission.application.verify`
- `admission.application.approve`
- `admission.application.reject`
- `admission.entrance-test.*`
- `admission.merit-list.*`
- `admission.merit-list.publish`
- `admission.allotment.*`
- `admission.enrollment.store`
- `admission.enrollment.bulk`
- `admission.promotion.*`
- `admission.alumni.tc`
- `admission.behavior.*`
- `admission.analytics.view`
- `admission.fee.confirm`

#### Section 8 — Service Architecture (6 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\Admission\app\Services
Depends on:  [other services it calls]
Fires:       [events or NTF dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. **AdmissionPipelineService** — activateCycle (guard: one Active per session); convertToApplication (copy enquiry fields to adm_applications); verifyApplication (mandatory doc check BR-ADM-007); submitApplication (transition Draft→Submitted, log stage, NTF); withdrawApplication (compute refund per policy, create adm_withdrawals, update application status); promoteWaitlisted (find next Waitlisted in merit list, create allotment, dispatch NTF); confirmAdmissionFee (mark paid, move to enrollment queue); `adm:expire-offers` support
2. **MeritListService** — generateMeritList (composite score = test_pct × entrance + interview_pct × interview + academic_pct × prev_marks; apply sibling +5 bonus if is_sibling=1 and confirmed; tie-break: earlier application date → older DOB; classify Shortlisted/Waitlisted/Rejected per seat count); allotSeat (quota capacity guard BR-ADM-013; create adm_allotments); computeCompositeScore (accepts criteria_json, applies sibling bonus)
3. **EnrollmentService** — enrollStudent (atomic DB::transaction: create sys_users role=Student, create std_students, create std_student_academic_sessions is_current=1, update adm_allotments enrolled_student_id + status=Enrolled, link sibling if is_sibling=1); autoAssignSection (pick section with lowest current enrollment count); assignRollNumber (sequential within class_section + session); bulkEnroll (per-student success/failure report); withdraw (close std_student_academic_sessions, disable sys_users account)
4. **TransferCertificateService** — issueTc (FIN fee-clearance check BR-ADM-004; generate TC-YYYY-NNN unique per school-year; render DomPDF with QR code; store in sys_media; mark std_students alumni; disable sys_users); generateQrCode (public verification URL encoded as QR); getNextTcNumber(year)
5. **PromotionService** — createBatch (load students from std_student_academic_sessions); applyPromotionCriteria (cross-reference exm_* pass/fail); override (record manual change with reason); preview (dry-run: count promoted/detained/left without DB write); confirmBatch (idempotent create std_student_academic_sessions for next session; old records is_current=0); assignRollNumbers (sequential per new class_section + session)
6. **AdmissionAnalyticsService** — computeFunnel (count per stage per cycle); computeLeadSourceBreakdown; computeQuotaFillReport; computeCounselorPerformance; computeClassCapacity; computeBehaviorScore (per student: sum severity deductions; reset at new session start); export (fputcsv for CSV; DomPDF for summary PDF)

#### Section 9 — Integration Contracts (6 integrations)
For each integration:
| Integration | ADM Action | External Module | How | Payload | Failure Handling |
|---|---|---|---|---|---|
- `STD enrollment write` → EnrollmentService → std_students + std_student_academic_sessions CREATED → DB transaction rollback on failure
- `FIN application fee` → AdmissionPipelineService → fin_invoices created for application fee → NTF confirmation
- `FIN admission fee + TC fee clearance` → EnrollmentService + TransferCertificateService → FIN balance check service → block if outstanding
- `PAY webhook` → AllotmentController@paymentWebhook → idempotent fee confirmation → webhook signature verified; no auth:sanctum
- `NTF notifications` → AdmissionPipelineService at each stage transition → NTF email+SMS channels → queue retry on failure
- `LmsExam promotion criteria` → PromotionService::applyPromotionCriteria() → exm_* read-only → mock for tests if EXM not ready

#### Section 10 — Non-Functional Requirements
From req v2 Section 10. For each NFR add an "Implementation Note" column:
- Public enquiry form < 2s — no auth overhead; minimal validation; Bootstrap 5 responsive
- Enrollment transaction < 5s — DB::transaction with indexed writes; avoid N+1 in batch
- Merit list for 1,000 applicants < 10s — chunked computation + indexed composite score
- Application documents: private storage (not publicly accessible) — Laravel Storage::disk('private')
- Aadhar encrypted at rest — AES-256 per tenant policy; restricted access via policy
- Public form rate-limited: 10 submissions/hour/IP — `throttle:10,1` middleware
- Payment webhook: idempotent (re-delivery safe) — check `application_fee_paid` before processing
- Payment webhook: 3 auto-retry attempts on delivery failure
- All stage transitions logged in `adm_application_stages` — model observer or service-layer explicit log
- Promotion: idempotent (re-run on Confirmed batch does not duplicate records) — `firstOrCreate` guard
- WCAG 2.1 AA public form — Bootstrap 5 + aria attributes + keyboard-navigable wizard
- Parent consent checkbox on public form — PDPB compliance flag stored on application

#### Section 11 — Test Plan Outline
From req v2 Section 12:

**Feature Tests (Pest) — test files:**
| File | Key Scenarios |
|---|---|
(List all test files for all 25 test scenarios in req v2 Section 12 with scenario descriptions)

**Unit Tests (PHPUnit) — test files:**
| File | Key Scenarios |
|---|---|
(Unit tests covering BR-ADM-013 seat capacity guard, BR-ADM-015 sibling bonus, composite score calculation, refund computation, auto-section balance, TC number uniqueness, roll number assignment)

**Test Data:**
- Required seeders for test database: `AdmissionDocumentChecklistSeeder`, `AdmissionQuotaSeeder`
- Required factories: EnquiryFactory, ApplicationFactory, MeritListFactory, AllotmentFactory
- Mock strategy: `DB::transaction()` rollback test for enrollment; `Event::fake()` for NTF dispatch; `Queue::fake()` for `WaitlistPromotionJob` and `OfferExpiryJob`; `Storage::fake()` for DomPDF documents; FIN fee service mock for TC and withdrawal tests; LmsExam mock for promotion criteria tests

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `ADM_FeatureSpec.md` | `{OUTPUT_DIR}/ADM_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 20 adm_* tables appear in Section 2 entity inventory
- [ ] All 15 FRs (ADM-01 to ADM-15) appear in Section 6
- [ ] All 15 business rules (BR-ADM-001 to BR-ADM-015) in Section 4 with enforcement point
- [ ] All 5 FSMs documented with ASCII state diagram and side effects
- [ ] All 6 services listed with key method signatures in Section 8
- [ ] All 6 integration contracts documented in Section 9
- [ ] BR-ADM-002 (enrollment atomic transaction) enforcement point: service_layer DB::transaction
- [ ] BR-ADM-004 (TC fee-clearance) enforcement point: TransferCertificateService
- [ ] BR-ADM-007 (mandatory doc check) enforcement point: AdmissionPipelineService::verifyApplication
- [ ] BR-ADM-011 (NEP 2020 Classes 1–2 warning) noted as non-blocking warning
- [ ] BR-ADM-012 (Aadhar partial unique) noted as partial UNIQUE index where NOT NULL
- [ ] BR-ADM-013 (seat capacity guard) enforcement: MeritListService::allotSeat
- [ ] BR-ADM-014 (offer expiry + waitlist promotion) enforcement: scheduled daily job
- [ ] BR-ADM-015 (sibling — staff confirm required) noted explicitly
- [ ] `adm_allotments.enrolled_student_id → std_students.id` noted (set on enrollment)
- [ ] EnrollmentService noted as WRITING to sys_users + std_students + std_student_academic_sessions
- [ ] Payment webhook idempotency (re-delivery safe) documented
- [ ] `offer_letter_media_id`, `media_id` → `INT UNSIGNED` (sys_media uses INT not BIGINT)
- [ ] **No `tenant_id` column** mentioned anywhere in any table definition
- [ ] All cross-module column names verified against tenant_db_v2.sql (use EXACT names from DDL)
- [ ] Public routes `/apply/{slug}` and `/apply/status/{app_no}` flagged as no-auth + rate-limited

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/ADM_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/ADM_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 5 (canonical column definitions for all 20 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify referenced table column names and data types; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`ADM_DDL_v1.sql`)

Generate CREATE TABLE statements for all 20 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**
1. Table prefix: `adm_` for all tables — no exceptions
2. Every table MUST include: `id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `updated_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Junction/bridge tables: use suffix `_jnt` (none in this module — all tables carry business data)
5. JSON columns: suffix `_json` (e.g., `criteria_json`, `refund_policy_json`, `age_rules_json`, `subjects_json`, `witnesses_json`)
6. Boolean flag columns: prefix `is_` or `has_`
7. All IDs and FK references: `BIGINT UNSIGNED` (consistency with tenant_db convention). Exception: `offer_letter_media_id`, `media_id` (all sys_media FKs) → `INT UNSIGNED`; `student_id`, `class_id`, `section_id`, `class_section_id`, `academic_session_id` → `INT UNSIGNED` (matching existing schema)
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_adm_{tableshort}_{column}` (e.g., `fk_adm_enq_cycle_id`, `fk_adm_app_enquiry_id`)
12. **Do NOT recreate std_*, sch_*, sys_*, fin_*, exm_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. `adm_allotments.admission_no`: `VARCHAR(50) NULL UNIQUE` — nullable until offer letter; UNIQUE allows NULL
    `adm_applications.aadhar_no`: `VARCHAR(20) NULL` — partial UNIQUE enforced at application layer (not DB-level UNIQUE due to MySQL limitations with partial indexes; use service-layer check)

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No adm_* dependencies (may reference sys_*/sch_* only):
  `adm_admission_cycles` (→ sch_org_academic_sessions_jnt + sys_users)

Layer 2 — Depends on Layer 1:
  `adm_document_checklist` (→ adm_admission_cycles + sch_classes nullable),
  `adm_quota_config` (→ adm_admission_cycles + sch_classes),
  `adm_seat_capacity` (→ adm_admission_cycles + sch_classes),
  `adm_entrance_tests` (→ adm_admission_cycles + sch_classes)

Layer 3 — Depends on Layer 2 + cross-module:
  `adm_enquiries` (→ adm_admission_cycles + sch_classes + sys_users nullable + std_students nullable),
  `adm_merit_lists` (→ adm_admission_cycles + sch_classes + sys_users nullable)

Layer 4 — Depends on Layer 3:
  `adm_follow_ups` (→ adm_enquiries + sys_users nullable),
  `adm_applications` (→ adm_admission_cycles + adm_enquiries nullable + sch_classes + sys_users nullable + std_students nullable)

Layer 5 — Depends on Layer 4:
  `adm_application_documents` (→ adm_applications + adm_document_checklist + sys_media + sys_users nullable),
  `adm_application_stages` (→ adm_applications + sys_users nullable),
  `adm_entrance_test_candidates` (→ adm_entrance_tests + adm_applications),
  `adm_merit_list_entries` (→ adm_merit_lists + adm_applications)

Layer 6 — Depends on Layer 5:
  `adm_allotments` (→ adm_merit_list_entries + adm_applications + sch_classes + sch_sections nullable + sys_media nullable + std_students nullable),
  `adm_promotion_batches` (→ sch_org_academic_sessions_jnt × 2 + sch_classes × 2 + sys_users nullable)

Layer 7 — Depends on Layer 6:
  `adm_withdrawals` (→ adm_applications + adm_allotments nullable + sys_users nullable),
  `adm_promotion_records` (→ adm_promotion_batches + std_students + sch_class_section_jnt × 2 nullable)

Layer 8 — Depends on cross-module std_students (may be installed in parallel):
  `adm_transfer_certificates` (→ std_students + sys_media nullable + sys_users nullable + adm_transfer_certificates self-ref nullable),
  `adm_behavior_incidents` (→ std_students + sys_users nullable)

Layer 9 — Depends on Layer 8:
  `adm_behavior_actions` (→ adm_behavior_incidents + sys_users nullable)

**Critical unique constraints to include:**
```sql
-- adm_admission_cycles
UNIQUE KEY uq_adm_cyc_code (cycle_code)

-- adm_seat_capacity
UNIQUE KEY uq_adm_sc_cycle_class_quota (admission_cycle_id, class_id, quota_type)

-- adm_enquiries
UNIQUE KEY uq_adm_enq_no (enquiry_no)

-- adm_applications
UNIQUE KEY uq_adm_app_no (application_no)
-- Note: aadhar_no partial unique enforced at service layer; no DB-level UNIQUE

-- adm_application_documents
UNIQUE KEY uq_adm_doc_app_checklist (application_id, checklist_item_id)

-- adm_entrance_test_candidates
UNIQUE KEY uq_adm_etc_test_app (entrance_test_id, application_id)

-- adm_allotments
UNIQUE KEY uq_adm_allot_admission_no (admission_no)    -- nullable; allows multiple NULLs

-- adm_transfer_certificates
UNIQUE KEY uq_adm_tc_number (tc_number)
```

**ENUM values (exact, to match application code):**
```
adm_admission_cycles.status:                     'Draft','Active','Closed','Archived'
adm_seat_capacity.quota_type:                    'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
adm_quota_config.quota_type:                     'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
adm_enquiries.student_gender:                    'Male','Female','Transgender','Other'
adm_enquiries.lead_source:                       'Website','Walk-in','Campaign','Referral','Social_Media','Phone','Other'
adm_enquiries.status:                            'New','Assigned','Contacted','Interested','Not_Interested','Callback','Converted','Duplicate'
adm_follow_ups.follow_up_type:                   'Call','Meeting','Email','SMS','Walk-in'
adm_follow_ups.outcome:                          'Pending','Interested','Not_Interested','Callback','Converted'
adm_applications.quota_type:                     'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
adm_applications.student_gender:                 'Male','Female','Transgender','Prefer Not to Say'
adm_applications.student_caste_category:         'General','OBC','SC','ST','EWS','Other'
adm_applications.blood_group:                    'A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown'
adm_applications.status:                         'Draft','Submitted','Under_Review','Verified','Shortlisted','Rejected','Waitlisted','Allotted','Enrolled','Withdrawn'
adm_application_documents.verification_status:  'Pending','Verified','Rejected'
adm_entrance_tests.status:                       'Scheduled','Completed','Cancelled'
adm_entrance_test_candidates.result:             'Pass','Fail','Absent','Pending'
adm_merit_lists.status:                          'Draft','Published','Finalized'
adm_merit_lists.quota_type:                      'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
adm_merit_list_entries.merit_status:             'Shortlisted','Waitlisted','Rejected'
adm_allotments.status:                           'Offered','Accepted','Declined','Expired','Enrolled','Withdrawn'
adm_withdrawals.reason:                          'Personal','Financial','Relocation','School_Change','Medical','Other'
adm_withdrawals.refund_status:                   'Not_Eligible','Pending','Approved','Paid'
adm_promotion_batches.status:                    'Draft','Confirmed'
adm_promotion_records.result:                    'Promoted','Detained','Transferred','Alumni','Left'
adm_transfer_certificates.conduct:              'Excellent','Good','Satisfactory','Poor'
adm_behavior_incidents.incident_type:           'Bullying','Cheating','Disruption','Absenteeism','Vandalism','Violence','Misconduct','Other'
adm_behavior_incidents.severity:                'Low','Medium','High','Critical'
adm_behavior_incidents.status:                  'Open','Action_Taken','Closed','Escalated'
adm_behavior_actions.action_type:               'Warning','Detention','Suspension','Expulsion','Parent_Meeting','Counseling','Community_Service'
```

**Critical columns to get right:**
- `adm_allotments.admission_no`: `VARCHAR(50) NULL UNIQUE` — nullable until offer letter issued; assigned per cycle's `admission_no_format`
- `adm_allotments.enrolled_student_id`: `INT UNSIGNED NULL` — set on enrollment; FK→std_students
- `adm_allotments.offer_letter_media_id`: `INT UNSIGNED NULL` — FK→sys_media (INT not BIGINT)
- `adm_allotments.offer_expires_at`: `DATE NULL` — deadline for parent response; checked by daily job
- `adm_applications.aadhar_no`: `VARCHAR(20) NULL` — service-layer uniqueness check only (not DB UNIQUE)
- `adm_transfer_certificates.original_tc_id`: `BIGINT UNSIGNED NULL` — self-referencing FK for duplicate TC
- `adm_transfer_certificates.media_id`: `INT UNSIGNED NULL` — FK→sys_media (INT not BIGINT)
- `adm_promotion_batches`: `from_session_id`, `to_session_id` → `INT UNSIGNED` (FK→sch_org_academic_sessions_jnt)
- `adm_promotion_records.from_class_section_id`, `to_class_section_id` → `INT UNSIGNED` (FK→sch_class_section_jnt; nullable for detained/leaving students)
- `adm_behavior_incidents.behavior_score_impact`: `TINYINT NOT NULL DEFAULT 0` — negative value for score deduction (use TINYINT not TINYINT UNSIGNED — must allow negative)

**File header comment to include:**
```sql
-- =============================================================================
-- ADM — Admission Management Module DDL
-- Module: Admission (Modules\Admission)
-- Table Prefix: adm_* (20 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: ADM_Admission_Requirement.md v2
-- Sub-Modules: Configuration, Enquiry & CRM, Application Pipeline,
--              Entrance Test, Merit & Allotment, Promotion,
--              Alumni & TC, Behavior Incidents
-- IMPORTANT: EnrollmentService WRITES to sys_users, std_students,
--            std_student_academic_sessions, std_siblings_jnt on enrollment.
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`ADM_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_adm_tables.php`.
- `up()`: creates all 20 tables in Layer 1 → Layer 9 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 9 → Layer 1)
- Use `Blueprint` column helpers; ENUM with `->enum()`; JSON with `->json()`; decimal with `->decimal(10, 2)`
- All FK constraints added in `up()` using `$table->foreign()`
- `adm_behavior_incidents.behavior_score_impact`: use `->tinyInteger()` (signed — allows negative values)
- `adm_allotments.admission_no`: use `->string('admission_no', 50)->nullable()->unique()`

### Phase 2C Task — Generate Seeders (2 seeders + 1 runner)

Namespace: `Modules\Admission\Database\Seeders`

**1. `AdmissionDocumentChecklistSeeder.php`** — default document checklist items (seeded as templates, `is_system=1`; cycle_id = NULL means global defaults):

Note: These are cycle-independent template defaults. When an admin creates a new admission cycle, these defaults are cloned into `adm_document_checklist` for that cycle. Seeder creates the master templates.
```
Birth Certificate      | code: BIRTH_CERT    | mandatory: 1 | formats: pdf,jpg,png | max: 5120 KB
Aadhar Card            | code: AADHAR_CARD   | mandatory: 0 | formats: pdf,jpg,png | max: 5120 KB
Passport Photo         | code: PASSPORT_PHOTO| mandatory: 1 | formats: jpg,png     | max: 2048 KB
Previous School TC     | code: PREV_TC       | mandatory: 0 | formats: pdf,jpg,png | max: 5120 KB
Previous Report Card   | code: REPORT_CARD   | mandatory: 0 | formats: pdf,jpg,png | max: 5120 KB
Caste Certificate      | code: CASTE_CERT    | mandatory: 0 | formats: pdf,jpg,png | max: 5120 KB
Address Proof          | code: ADDRESS_PROOF | mandatory: 0 | formats: pdf,jpg,png | max: 5120 KB
Income Certificate     | code: INCOME_CERT   | mandatory: 0 | formats: pdf,jpg,png | max: 5120 KB
```
Note: `admission_cycle_id` and `class_id` = NULL for template rows; use `is_system=1` flag to mark seeders.

**2. `AdmissionQuotaSeeder.php`** — default quota type reference data (no cycle_id — informational seeder for reference; actual `adm_quota_config` rows are created per cycle by admin):
This seeder seeds a `sys_dropdown` or reference table if applicable, OR inserts into a quota reference table. If no such table exists, this seeder is informational and documents the 8 quota types for the developer.
```
General      | code: GENERAL   | fee_waiver: 0
Government   | code: GOVT      | fee_waiver: 0
Management   | code: MGMT      | fee_waiver: 0
RTE          | code: RTE       | fee_waiver: 1
NRI          | code: NRI       | fee_waiver: 0
Staff_Ward   | code: STAFF_WD  | fee_waiver: 0
Sibling      | code: SIBLING   | fee_waiver: 0
EWS          | code: EWS       | fee_waiver: 1
```

**3. `AdmissionSeederRunner.php`** (Master seeder):
```php
$this->call([
    AdmissionDocumentChecklistSeeder::class,   // no dependencies
    AdmissionQuotaSeeder::class,               // no dependencies
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `ADM_DDL_v1.sql` | `{OUTPUT_DIR}/ADM_DDL_v1.sql` |
| `ADM_Migration.php` | `{OUTPUT_DIR}/ADM_Migration.php` |
| `ADM_TableSummary.md` | `{OUTPUT_DIR}/ADM_TableSummary.md` |
| `Seeders/AdmissionDocumentChecklistSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/AdmissionQuotaSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/AdmissionSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 20 adm_* tables exist in DDL (4 config + 2 CRM + 4 app pipeline + 2 entrance test + 3 merit/allotment + 2 promotion + 1 TC + 2 behavior = 20 ✓)
- [ ] Standard columns (id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) on ALL 20 tables
- [ ] `adm_allotments.admission_no` is NULLABLE UNIQUE — not NOT NULL
- [ ] `adm_allotments.enrolled_student_id` is `INT UNSIGNED NULL` (FK→std_students; set on enrollment)
- [ ] `adm_allotments.offer_expires_at` is `DATE NULL` (daily expiry job checks this)
- [ ] `adm_allotments.offer_letter_media_id` is `INT UNSIGNED NULL` (sys_media uses INT)
- [ ] `adm_transfer_certificates.media_id` is `INT UNSIGNED NULL` (sys_media uses INT)
- [ ] `adm_application_documents.media_id` is `INT UNSIGNED NULL` (sys_media uses INT)
- [ ] `adm_behavior_incidents.behavior_score_impact` is signed `TINYINT` (not UNSIGNED — allows negative)
- [ ] `adm_transfer_certificates.original_tc_id` is self-referencing nullable FK
- [ ] `adm_applications.aadhar_no` is NOT UNIQUE in DDL (partial unique enforced at service layer)
- [ ] **No `tenant_id` column** on any table
- [ ] All unique constraints listed above are present
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] `adm_seat_capacity.seats_allotted` and `seats_enrolled` default to 0 (incremented by services)
- [ ] `adm_admission_cycles.sibling_bonus_score` present with default 5
- [ ] `adm_merit_list_entries.sibling_bonus_applied` TINYINT(1) present
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_adm_` convention throughout
- [ ] `AdmissionDocumentChecklistSeeder` has all 8 default documents with correct `is_mandatory` flags
- [ ] `AdmissionSeederRunner` calls both seeders
- [ ] `ADM_TableSummary.md` has one-line description for all 20 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `ADM_DDL_v1.sql` + Migration + 3 seeder files. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/ADM_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 6 (routes), Section 7 (UI screens), Section 11 (implementation phases), Section 2.4 (file structure)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (naming conventions)

### Phase 3 Task — Generate `ADM_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

Derive controllers from req v2 Section 6 (routes). For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

Controllers to define (14 total, from req v2 Section 2.4 file structure):
1. `AdmissionDashboardController` — index (Kanban pipeline, funnel chart, seat fill meters, today's follow-ups)
2. `EnquiryController` — index, create, store, show, update, assign, convert (→ application); publicStore (no auth — public walk-in form)
3. `FollowUpController` — store, update (mark outcome, reschedule)
4. `ApplicationController` — index, store, show, update, submit, verify, approve, reject, scheduleInterview; publicForm (no auth), publicSubmit (no auth), trackStatus (no auth)
5. `ApplicationDocumentController` — store, verify, destroy
6. `WithdrawalController` — store (compute refund, record withdrawal)
7. `EntranceTestController` — index, store, update, generateCandidates, enterMarks, downloadHallTicket
8. `MeritListController` — index, generate, publish
9. `AllotmentController` — index, store, generateOffer, confirmFee, paymentWebhook (no auth:sanctum — PAY webhook)
10. `EnrollmentController` — index, enroll, bulkEnroll
11. `PromotionController` — index, preview, confirm
12. `AlumniController` — index, markAlumni, issueTc, downloadTc
13. `BehaviorIncidentController` — index, store, addAction, report
14. `AdmissionAnalyticsController` — funnel, sourceBreakdown, quotaFill, counselorPerformance, capacityReport, behaviorReport, export

#### Section 2 — Service Inventory (6 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Events/NTF dispatched
- Other services called (dependency graph)

Include the enrollment execution sequence as inline pseudocode in `EnrollmentService`:
```
enrollStudent(Allotment $allotment, array $options): Student
  Step 1: Verify allotment.admission_fee_paid = 1 (pre-condition)
  Step 2: Verify no existing enrollment for same session (BR-ADM-010)
  Step 3: DB::transaction() begins
  Step 4: Create sys_users: name, email (parent), password (generated), role = Student
  Step 5: Create std_students: link to sys_users; copy from adm_applications; set admission_no
  Step 6: Determine section: if options.section_id provided → use it; else autoAssignSection()
  Step 7: Assign roll number: sequential within (class_section + academic_session)
  Step 8: Create std_student_academic_sessions: student_id, academic_session_id, class_section_id, roll_no, is_current=1
  Step 9: Update adm_allotments: enrolled_student_id = student.id, status = Enrolled
  Step 10: Update adm_applications: status = Enrolled
  Step 11: If application.is_sibling = 1: create std_siblings_jnt record
  Step 12: DB::transaction() commits
  Step 13: Dispatch NTF: student login credentials + welcome message to parent
  Step 14: Update adm_seat_capacity.seats_enrolled += 1
```

Include the merit list generation sequence as inline pseudocode in `MeritListService`:
```
generateMeritList(MeritList $meritList): void
  Step 1: Load all Verified applications for the cycle+class+quota
  Step 2: For each application:
            entrance_score = entrance_test_marks × criteria_json.test_pct / 100
            interview_score = application.interview_score × criteria_json.interview_pct / 100
            academic_score = application.prev_marks_percent × criteria_json.academic_pct / 100
            raw_score = entrance_score + interview_score + academic_score
            if application.is_sibling = 1 (confirmed): composite = raw + merit_list.sibling_bonus_score
            else: composite = raw_score
  Step 3: Sort by composite DESC; tie-break: earlier created_at; then older student_dob
  Step 4: Classify: rank ≤ seat_count → Shortlisted; beyond seat_count → Waitlisted
            if composite < cutoff_score → Rejected
  Step 5: Create adm_merit_list_entries rows with merit_rank, composite_score, sibling_bonus_applied
  Step 6: Update adm_merit_lists.generated_at, generated_by
```

#### Section 3 — FormRequest Inventory (12 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

12 total (from req v2 Section 2.4 and FR requirements):
- `StoreEnquiryRequest` — student_name required, contact_mobile required, class_sought_id exists in sch_classes, admission_cycle_id active cycle, lead_source valid ENUM; age eligibility warning check (non-blocking)
- `StoreApplicationRequest` — student_first_name required, student_dob required, student_gender valid ENUM, quota_type valid ENUM, father_mobile or mother_mobile or guardian_mobile required (at least one); aadhar_no service-layer uniqueness check; application_fee_paid check before submit
- `SubmitApplicationRequest` — application must be in Draft status; all mandatory checklist documents uploaded
- `VerifyDocumentRequest` — verification_status valid ENUM, verification_remarks required if Rejected
- `ScheduleInterviewRequest` — interview_scheduled_at future datetime, interview_venue required, with_user_id (interviewer) exists in sys_users
- `StoreEntranceTestRequest` — test_date required, start_time < end_time, max_marks > 0, class_id check: warning if class is 1 or 2 (BR-ADM-011)
- `EnterMarksRequest` — marks_obtained ≤ max_marks per candidate, subject_marks_json sum ≤ max_marks if provided
- `GenerateMeritListRequest` — criteria_json weightages must sum to 100 (BR per FR-ADM-06.1), quota_type valid ENUM
- `StoreAllotmentRequest` — merit_list_entry_id exists and status=Shortlisted, allotted_class_id exists, seat capacity guard check (BR-ADM-013)
- `ConfirmFeeRequest` — amount required, payment_mode valid (Cash/DD/Cheque/Online), receipt_number required if mode != Online
- `StoreWithdrawalRequest` — reason valid ENUM, withdrawal_date required; application must not already be Withdrawn or Enrolled
- `PromotionConfirmRequest` — from_session_id and to_session_id valid, from_class_id != to_class_id for promotion; idempotent: batch not already Confirmed

#### Section 4 — Blade View Inventory (~55 views)

List all blade views grouped by feature group. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Feature groups and screen counts (from req v2 Section 7 — 25 screens):
- Dashboard: 1 view (Kanban pipeline + funnel chart + seat fill meters)
- Enquiries (list, create, show/timeline, public form): 4 views
- Application Status Tracker (public): 1 view
- Applications (list, show/review, interview scheduler): 3 views
- Entrance Tests (list, mark entry, hall ticket): 3 views
- Merit List (ranked list with score breakdown): 1 view
- Seat Allotment (allotment list, offer letter preview): 2 views
- Withdrawal (form with computed refund): 1 view
- Enrollment (queue, confirm form with class/section/roll): 2 views
- Promotion Wizard (step 1 select, step 2 preview, step 3 confirm): 3 views
- Alumni (list, TC issuance form): 2 views
- Behavior (incidents list, report): 2 views
- Analytics Funnel (full dashboard): 1 view
- Settings (cycle config, seat capacity, document checklist, quota config): 4 views
- Shared partials: ~5 (pipeline stage badge, merit score card, seat fill gauge, document status, export buttons)

For key screens document:
- Public application form — multi-step wizard (Bootstrap 5 stepper); progress saved after each step; mobile-responsive; WCAG 2.1 AA; parent consent checkbox
- Application status tracker — parent enters APP number; stage badge + description + next steps shown; no login
- Merit list — ranked table with score breakdown columns (entrance/interview/academic/bonus); sibling badge; quota tab filter; publish button with confirmation
- Enrollment confirm — class/section picker with fill count shown; roll number auto-suggested (sequential); confirmation checklist
- Promotion wizard Step 2 — student table with Promoted/Detained/Left radio per row; summary counts (auto-update); manual override note field
- Allotment offer letter preview — DomPDF preview iframe; email/download buttons; send confirmation modal

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 6 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by feature area (web routes + public routes + API routes). Count total routes at end (target ~65 web + ~20 API, total ~85 routes).
Middleware on authenticated web routes: `['auth', 'tenant', 'EnsureTenantHasModule:Admission']`
Middleware on API routes: `['auth:sanctum', 'tenant']`

Special routes (no or minimal auth):
- `GET /apply/{slug}` — no auth; rate-limit 10/min
- `POST /apply/{slug}` — no auth; rate-limit 10/min; CSRF
- `GET /apply/status/{application_no}` — no auth; rate-limit 10/min
- `POST /api/v1/admission/payment/webhook` — no auth:sanctum; signature-verified only

#### Section 6 — Implementation Phases (7 phases per req v2 Section 11.3)

For each phase, provide a detailed sprint plan:

**Phase 1 — Cycle Config + Enquiry + Application** (prerequisites: SYS, SCH, GLB done):
FRs: ADM-01, ADM-02, ADM-03, ADM-15
Files to create:
- Controllers: AdmissionDashboardController, EnquiryController, FollowUpController, ApplicationController (basic CRUD only), ApplicationDocumentController, WithdrawalController (basic)
- Services: AdmissionPipelineService (activateCycle, convertToApplication, submitApplication, withdrawApplication)
- Models: AdmissionCycle, DocumentChecklist, QuotaConfig, SeatCapacity, Enquiry, FollowUp, Application, ApplicationDocument, ApplicationStage, Withdrawal
- FormRequests: StoreEnquiryRequest, StoreApplicationRequest, SubmitApplicationRequest, StoreWithdrawalRequest
- Seeders: AdmissionDocumentChecklistSeeder, AdmissionQuotaSeeder, AdmissionSeederRunner
- Views: ~10 views (dashboard placeholder + enquiry × 3 + public form + status tracker + application × 2 + settings × 2)
- Tests: EnquiryCreationTest, AgeEligibilityWarningTest, SiblingAutoDetectTest, DuplicateMobileEnquiryTest, PublicFormSubmissionTest, ApplicationNumberGenerationTest, DocumentUploadTest, ApplicationStatusTransitionTest

**Phase 2 — Verification + Entrance Test + Merit + Allotment** (Phase 1 done):
FRs: ADM-04, ADM-05, ADM-06
Files to create:
- Controllers: ApplicationController (verify/approve/reject/scheduleInterview), EntranceTestController, MeritListController, AllotmentController (basic + offer letter)
- Services: MeritListService (generateMeritList, allotSeat, computeCompositeScore), partial AdmissionPipelineService::promoteWaitlisted()
- Models: EntranceTest, EntranceTestCandidate, MeritList, MeritListEntry, Allotment
- FormRequests: VerifyDocumentRequest, ScheduleInterviewRequest, StoreEntranceTestRequest, EnterMarksRequest, GenerateMeritListRequest, StoreAllotmentRequest
- Jobs: WaitlistPromotionJob (3 retries), OfferExpiryJob (daily)
- Views: ~8 views (application review + interview + entrance test × 2 + merit list + allotment + offer letter preview + withdrawal form)
- Artisan: `adm:expire-offers` (daily)
- Tests: MandatoryDocumentBlockTest, MeritListGenerationTest, QuotaSeatCapacityGuardTest, WaitlistAutoPromotionTest, OfferExpiryJobTest

**Phase 3 — Offer Letter + Payment** (PAY module available; Phase 2 done):
FRs: ADM-07
Files to create:
- Controllers: AllotmentController@confirmFee + paymentWebhook
- Services: AdmissionPipelineService::confirmAdmissionFee(); payment webhook handler
- Views: ~2 views (fee confirmation form + payment result)
- Tests: PaymentWebhookIdempotencyTest

**Phase 4 — Enrollment Conversion** (STD module ready; Phase 3 done):
FRs: ADM-09, ADM-14
Files to create:
- Controllers: EnrollmentController (index, enroll, bulkEnroll)
- Services: EnrollmentService (enrollStudent atomic transaction, autoAssignSection, assignRollNumber, bulkEnroll)
- FormRequests: — (enrollment uses allotment data; minimal form)
- Views: ~2 views (enrollment queue + confirm form)
- Tests: EnrollmentAtomicTest, EnrollmentRollbackTest, DuplicateEnrollmentTest, AutoSectionBalanceTest

**Phase 5 — Withdrawal + Refund** (FIN module available; Phase 4 done):
FRs: ADM-08
Files to create:
- Controllers: WithdrawalController (full — compute refund, integrate FIN)
- Services: AdmissionPipelineService::withdrawApplication() (refund compute + FIN instruction)
- FormRequests: StoreWithdrawalRequest (full validation)
- Views: ~1 view (withdrawal form with refund estimate)
- Tests: WithdrawalRefundComputeTest

**Phase 6 — Promotion + Alumni + TC** (LmsExam available; Phase 4 done):
FRs: ADM-10, ADM-11
Files to create:
- Controllers: PromotionController (3-step wizard), AlumniController (markAlumni, issueTc, downloadTc)
- Services: PromotionService (createBatch, applyPromotionCriteria, preview, confirmBatch, assignRollNumbers), TransferCertificateService (issueTc, generateQrCode, getNextTcNumber)
- FormRequests: PromotionConfirmRequest
- Views: ~5 views (promotion wizard × 3 + alumni list + TC issuance)
- Tests: BulkPromotionTest, DetainedStudentTest, TransferCertificateTest, TCOutstandingFeeBlockTest

**Phase 7 — Behavior + Analytics** (Phase 4 done):
FRs: ADM-12, ADM-13
Files to create:
- Controllers: BehaviorIncidentController (index, store, addAction, report), AdmissionAnalyticsController (funnel, sourceBreakdown, quotaFill, counselorPerformance, export)
- Services: AdmissionAnalyticsService (computeFunnel, computeLeadSourceBreakdown, computeQuotaFillReport, computeCounselorPerformance, computeBehaviorScore, export)
- Views: ~3 views (behavior list + behavior report + analytics funnel)
- Tests: BehaviorIncidentCriticalTest

#### Section 7 — Seeder Execution Order

```
php artisan module:seed Admission --class=AdmissionSeederRunner
  ↓ AdmissionDocumentChecklistSeeder    (no dependencies)
  ↓ AdmissionQuotaSeeder                (no dependencies)
```

Artisan scheduled commands (register in `routes/console.php`):
```
adm:expire-offers    → daily midnight (find Offered allotments past offer_expires_at → Expired; promote next waitlisted)
```

For test runs: use `AdmissionDocumentChecklistSeeder` as minimum required seeder.
For Phase 6+ tests: use `AdmissionDocumentChecklistSeeder` + `AdmissionQuotaSeeder`.

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// EnrollmentService atomic: DB::transaction() rollback test — use DB::shouldReceive() or actual txn
// FIN fee service: mock with Mockery for TC issuance and withdrawal refund tests
// LmsExam: mock PromotionService criteria reads for Phase 6 promotion tests
// Event::fake() for NTF dispatch at each stage transition
// Queue::fake() for WaitlistPromotionJob and OfferExpiryJob
// Storage::fake() for DomPDF offer letter, hall ticket, TC PDF generation
// PAY webhook: use direct HTTP call to paymentWebhook endpoint; verify idempotency by sending twice
```

**Minimum Test Coverage Targets:**
- BR-ADM-002 (enrollment atomic): EnrollmentRollbackTest — DB error mid-transaction → no partial records
- BR-ADM-004 (TC fee clearance): TCOutstandingFeeBlockTest
- BR-ADM-007 (mandatory doc block): MandatoryDocumentBlockTest
- BR-ADM-012 (Aadhar uniqueness): DuplicateAadharTest — service-layer check (not DB constraint)
- BR-ADM-013 (seat capacity guard): QuotaSeatCapacityGuardTest — allot beyond capacity → error
- BR-ADM-014 (offer expiry + waitlist): OfferExpiryJobTest — scheduled job advances expired offers
- BR-ADM-015 (sibling bonus requires confirmation): MeritListGenerationTest — auto-detect alone does not apply bonus; is_sibling=1 required
- Payment webhook idempotency: PaymentWebhookIdempotencyTest — second delivery does not double-credit
- Promotion idempotency: BulkPromotionTest re-run — no duplicate std_student_academic_sessions

**Feature Test File Summary (from req v2 Section 12):**
List all test files with file path, test count, and key scenarios covering all 25 test scenarios.

**Factory Requirements:**
```
EnquiryFactory          — generates enquiry_no (ENQ-YYYY-NNNNN), status=New, admission_cycle_id
ApplicationFactory      — generates application_no (APP-YYYY-NNNNN), status=Draft, all student fields
MeritListFactory        — generates merit list for cycle+class+quota with criteria_json
AllotmentFactory        — generates allotment linked to merit_list_entry, status=Offered
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `ADM_Dev_Plan.md` | `{OUTPUT_DIR}/ADM_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 14 controllers listed with all methods
- [ ] All 6 services listed with at minimum 3 key method signatures each
- [ ] EnrollmentService pseudocode present (14-step atomic enrollment transaction)
- [ ] MeritListService pseudocode present (merit list generation + sibling bonus + tie-break logic)
- [ ] All 12 FormRequests listed with their key validation rules
- [ ] All 15 FRs (ADM-01 to ADM-15) appear in at least one implementation phase
- [ ] All 7 implementation phases have: FRs covered, files to create, test count
- [ ] Seeder execution order documented
- [ ] `adm:expire-offers` Artisan command listed with daily midnight schedule
- [ ] Route list consolidated with middleware (~65 web + ~20 API, total ~85 routes)
- [ ] View count per feature group totals approximately 55
- [ ] Test strategy includes DB::transaction() rollback test for BR-ADM-002
- [ ] BR-ADM-013 (seat capacity guard) test explicitly referenced
- [ ] BR-ADM-015 (sibling auto-detect alone insufficient) test referenced in MeritListGenerationTest
- [ ] Payment webhook route noted as `withoutMiddleware(['auth:sanctum'])` — signature-verified only
- [ ] Public routes noted as `throttle:10,1` — rate-limited
- [ ] WaitlistPromotionJob documented with 3 retries
- [ ] EnrollmentService writes to sys_users + std_students + std_student_academic_sessions noted
- [ ] `adm_allotments.seats_enrolled` auto-increment after enrollment confirmed
- [ ] Promotion idempotency (re-run guard) documented in PromotionService

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `ADM_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/ADM_FeatureSpec.md`
2. `{OUTPUT_DIR}/ADM_DDL_v1.sql` + Migration + 3 Seeders
3. `{OUTPUT_DIR}/ADM_Dev_Plan.md`
Development lifecycle for ADM (Admission Management) module is ready to begin."

---

## QUICK REFERENCE — ADM Module Tables vs Controllers vs Services

| Domain | adm_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Cycle Config | adm_admission_cycles, adm_document_checklist, adm_quota_config, adm_seat_capacity | AdmissionDashboardController (settings tab) | AdmissionPipelineService (activateCycle) |
| Enquiry & CRM | adm_enquiries, adm_follow_ups | EnquiryController, FollowUpController | AdmissionPipelineService (convertToApplication) |
| Application | adm_applications, adm_application_documents, adm_application_stages | ApplicationController, ApplicationDocumentController | AdmissionPipelineService (submit, verify, withdraw) |
| Withdrawal | adm_withdrawals | WithdrawalController | AdmissionPipelineService (withdrawApplication) |
| Entrance Test | adm_entrance_tests, adm_entrance_test_candidates | EntranceTestController | MeritListService (computeCompositeScore uses marks) |
| Merit & Allotment | adm_merit_lists, adm_merit_list_entries, adm_allotments | MeritListController, AllotmentController | MeritListService (generate, allotSeat, promoteWaitlisted) |
| Enrollment | WRITES std_students, std_student_academic_sessions | EnrollmentController | EnrollmentService (enrollStudent atomic txn) |
| Promotion | adm_promotion_batches, adm_promotion_records | PromotionController | PromotionService |
| Alumni & TC | adm_transfer_certificates | AlumniController | TransferCertificateService |
| Behavior | adm_behavior_incidents, adm_behavior_actions | BehaviorIncidentController | AdmissionAnalyticsService (computeBehaviorScore) |
| Analytics | reads all adm_* | AdmissionAnalyticsController | AdmissionAnalyticsService |
| Dashboard | — | AdmissionDashboardController | AdmissionAnalyticsService (funnel counts) |
