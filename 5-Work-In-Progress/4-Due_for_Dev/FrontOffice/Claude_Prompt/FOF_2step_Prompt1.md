# FOF — Front Office Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **FOF (FrontOffice)** module using `FOF_FrontOffice_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `FOF_FeatureSpec.md` — Feature Specification
2. `FOF_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `FOF_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**Module:** FrontOffice — Complete reception and front-desk management for Indian K-12 schools.
Tables: `fof_*` (22 tables covering visitor register, gate pass, early departure, phone diary, postal/dispatch, circulars, notice board, appointments, lost & found, key register, emergency contacts, certificates, complaints, feedback, communication, school events).

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
MODULE_CODE       = FOF
MODULE            = FrontOffice
MODULE_DIR        = Modules/FrontOffice/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = D                              # Front Office & Communication in RBS v4.0
DB_TABLE_PREFIX   = fof_                           # Single prefix — all tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/FrontOffice/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/FOF_FrontOffice_Requirement.md

FEATURE_FILE      = FOF_FeatureSpec.md
DDL_FILE_NAME     = FOF_DDL_v1.sql
DEV_PLAN_FILE     = FOF_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — FOF (FRONT OFFICE) MODULE

### What This Module Does

The FrontOffice module provides a **complete reception and front-desk management system** for Indian K-12 schools on the Prime-AI SaaS platform. It digitizes all paper-based registers used at the school reception — replacing visitor books, phone diaries, dak registers, dispatch registers, notice boards, and key registers with a centralized digital system that provides real-time visibility, full audit trails, and regulatory compliance during CBSE/State Board inspections.

**Phase 1 — Core Registers (High Priority):**
- Visitor Management: digital register with photo capture, pass number auto-generation (VP-YYYYMMDD-NNN), overstay auto-flag
- Gate Pass: student/staff early exit with approval workflow (Pending_Approval → Approved → Exited → Returned)
- Student Early Departure: parent mid-day pickup linked to ATT module for absent marking
- Phone Diary: incoming/outgoing calls with action-required flag and follow-up tracking
- Postal/Courier Register: inward (IN-YYYY-NNNN) and outward (OUT-YYYY-NNNN) mail with acknowledgement lock
- Dispatch Register: official outgoing correspondence log (DSP-YYYY-NNNN)

**Phase 2 — Communication:**
- Circular Management: Draft → Pending_Approval → Approved → Distributed; audience targeting (Parents/Staff/Both/Class/Section); NTF email+SMS distribution
- Digital Notice Board: active/archived notices with pinning, emergency bypass, display date control
- School Calendar Events: public-facing events (Sports Day, PTM, Annual Function) with NTF blast

**Phase 3 — Certificates & Complaints:**
- Certificate Request & Issuance: Bonafide/Character/TC/Migration with multi-stage approval, DomPDF generation, unique cert numbers per type per year
- Complaint Handling: front-office level intake with CMP module escalation linkage

**Phase 4 — Support Features:**
- Appointment Scheduling: book principal/teacher meetings with slot availability check
- Lost and Found Register: item registration, claim matching, retention flag, disposition
- Key Management Register: key issue/return with overdue flag
- Emergency Contact Directory: hospital, police, fire, transport contacts

**Phase 5 — Feedback & Communication:**
- Feedback Collection: custom forms with MCQ/rating/text questions; public token URL (no auth); anonymous support
- Bulk Email/SMS: composition UI + template management + per-recipient delivery tracking via NTF

### Architecture Decisions
- **Single Laravel module** (`Modules\FrontOffice`) — all 5 phases in one module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `front-office/` | Route name prefix: `fof.`
- ATT integration: service call `EarlyDepartureService::syncAttendance()` — FOF calls ATT service; ATT owns absence records; retry-on-failure with front desk alert
- NTF integration: FOF fires events/dispatches notifications via NTF channels; FOF never writes to `ntf_*` tables directly
- CMP integration: `fof_complaints.cmp_complaint_id` FK linkage when escalated; CMP module owns the escalated complaint
- VSM integration: `fof_visitors.vsm_visitor_id` FK — pre-registered VSM visitors auto-populate FOF registration form
- StudentFee integration: `CertificateIssuanceService` calls FIN fee-clearance check before issuing TC/Migration certs
- Print slips: visitor pass, gate pass, early departure — CSS `@media print` optimized (no PDF download)
- Certificates: DomPDF for PDF generation; stored in `sys_media`
- Aadhar masking: last 4 digits only in UI; full number stored per tenant encryption policy

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | 18 |
| Models | 22 |
| Services | 5 |
| FormRequests | 10 |
| fof_* tables | 22 |
| Blade views (estimated) | ~60 |
| Seeders | 1 (visitor purposes) + 1 runner |

### Complete Table Inventory

**Core Registers (8 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `fof_visitor_purposes` | Lookup master | UNIQUE `(code)`; seeded 8 purposes |
| 2 | `fof_visitors` | Visitor register | UNIQUE `(pass_number)`; `status` ENUM In/Out/Overstay |
| 3 | `fof_gate_passes` | Student/staff exit pass | UNIQUE `(pass_number)`; multi-state FSM |
| 4 | `fof_early_departures` | Mid-day parent pickup | UNIQUE `(departure_number)`; ATT sync status |
| 5 | `fof_phone_diary` | Call log | Index `(call_date, call_type)` |
| 6 | `fof_postal_register` | Inward/outward mail | UNIQUE `(postal_number)`; lock after acknowledgement |
| 7 | `fof_dispatch_register` | Outgoing official correspondence | UNIQUE `(dispatch_number)` |
| 8 | `fof_emergency_contacts` | External emergency directory | Index `(contact_type)` |

**Communication (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 9 | `fof_circulars` | School circulars | UNIQUE `(circular_number)`; approval + distribution FSM |
| 10 | `fof_circular_distributions` | Per-recipient distribution log | INDEX `(circular_id, recipient_user_id)` |
| 11 | `fof_notices` | Digital notice board | Index `(display_from, display_until, status)` |
| 12 | `fof_school_events` | Public school calendar events | Index `(start_date, event_type)` |

**Appointments & Support (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 13 | `fof_appointments` | Meeting scheduling | UNIQUE `(appointment_number)`; slot conflict check |
| 14 | `fof_lost_found` | Lost and found items | UNIQUE `(item_number)` |
| 15 | `fof_key_register` | Physical key issue/return | Index `(status, issued_to_user_id)` |
| 16 | `fof_certificate_requests` | Certificate request + issuance | UNIQUE `(request_number)`, UNIQUE `(cert_number)` |

**Complaints & Feedback (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 17 | `fof_complaints` | Front-office complaint intake | Index `(status, urgency)` |
| 18 | `fof_feedback_forms` | Feedback form definitions | Index `(is_active)` |
| 19 | `fof_feedback_responses` | Form responses | Index `(feedback_form_id)` |

**Communication Logs (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 20 | `fof_email_templates` | Reusable email templates | Index `(is_active)` |
| 21 | `fof_communication_logs` | Bulk email/SMS audit log | Index `(created_at)` |
| 22 | `fof_sms_logs` | Per-recipient SMS delivery | Index `(communication_log_id)` |

**Existing Tables REUSED (FOF reads from; never modifies schema):**
| Table | Source | FOF Usage |
|---|---|---|
| `sys_users` | System | All `created_by`, `approved_by`, `issued_to`, etc. |
| `sys_media` | System | Visitor photo, circular attachment, notice attachment, certificate PDF |
| `sys_activity_logs` | System | Audit trail (write-only) for certs, circulars, government visits |
| `std_students` | StudentProfile (STD) | Gate pass student_id, early departure student_id, certificate student_id |
| `vsm_visitors` | VSM | Visitor pre-registration handoff |
| `cmp_complaints` | Complaint (CMP) | Escalation FK: `fof_complaints.cmp_complaint_id` |
| `ntf_notifications` | Notification (NTF) | Gate pass alerts, circular distribution, certificate notifications |

### Cross-Module Integration
```
On EarlyDeparture saved:
  → EarlyDepartureService::syncAttendance()
    → ATT service call: mark student absent for remaining periods
    → att_sync_status updated to Synced or Failed
    → On failure: front desk alert raised + retry queued

On Circular Distributed:
  → CircularService::distribute()
    → NTF email + optional SMS per resolved recipient
    → fof_circular_distributions rows created
    → fof_circulars.status → Distributed

On CertificateRequest TC_Copy or Migration:
  → CertificateIssuanceService
    → FIN fee-clearance check before proceeding
    → If outstanding fees exist: block issuance

On GatePass (student) created:
  → NTF parent notification auto-dispatched

On Visitor overstay:
  → fof:flag-overstay Artisan command (scheduled at school closing time)
  → Sets status = Overstay for all visitors with out_time = NULL

On FOF Complaint escalated:
  → CMP complaint created with linked cmp_complaint_id
  → fof_complaints.status → Escalated
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — FOF v2 requirement (17 FRs, Sections 1–15)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: std_students, sys_users, sys_media, vsm_visitors, cmp_complaints (use exact column names in spec)

### Phase 1 Task — Generate `FOF_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix, module type
- In-scope feature groups (Phase 1–5 — all 17 FRs from req v2 Section 2.3)
- Out-of-scope items (admission inquiry handled by ADM module; biometric/vehicle log handled by VSM; full HR leave handled by HRS)
- Distinction from VSM: FOF = receptionist inside campus; VSM = security guard at gate
- Module scale table (controller / model / service / FormRequest / table counts)

#### Section 2 — Entity Inventory (All 22 Tables)
For each `fof_*` table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Core Registers** (fof_visitor_purposes, fof_visitors, fof_gate_passes, fof_early_departures, fof_phone_diary, fof_postal_register, fof_dispatch_register, fof_emergency_contacts)
- **Communication** (fof_circulars, fof_circular_distributions, fof_notices, fof_school_events)
- **Appointments & Support** (fof_appointments, fof_lost_found, fof_key_register, fof_certificate_requests)
- **Complaints & Feedback** (fof_complaints, fof_feedback_forms, fof_feedback_responses)
- **Communication Logs** (fof_email_templates, fof_communication_logs, fof_sms_logs)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 22 tables grouped by layer (fof_* vs cross-module reads from std_*/sys_*/vsm_*/cmp_*).
Use `→` for FK direction (child → parent).

Critical cross-module FKs to highlight:
- `fof_visitors.vsm_visitor_id → vsm_visitors.id` (nullable — pre-registered handoff)
- `fof_visitors.photo_media_id → sys_media.id` (nullable)
- `fof_gate_passes.student_id → std_students.id` (nullable — student passes only)
- `fof_early_departures.student_id → std_students.id` (NOT NULL)
- `fof_certificate_requests.student_id → std_students.id` (NOT NULL)
- `fof_complaints.cmp_complaint_id → cmp_complaints.id` (nullable — set on escalation)
- `fof_circular_distributions.circular_id → fof_circulars.id` (NOT NULL)
- `fof_certificate_requests.cert_number` UNIQUE — enforces BR-FOF-006

#### Section 4 — Business Rules (15 rules)
For each rule, state:
- Rule ID (BR-FOF-001 to BR-FOF-015)
- Rule text (from req v2 Section 8)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event` | `policy` | `scheduled_command`

Critical rules to emphasise:
- BR-FOF-002: Visitors not checked out by closing time auto-flagged Overstay — `fof:flag-overstay` scheduled command
- BR-FOF-003: Student gate pass dispatches parent NTF before exit — `GatePassService` dispatches NTF
- BR-FOF-004: One active gate pass per student at a time — `IssueGatePassRequest` validation query
- BR-FOF-005: TC_Copy and Migration certificate require no outstanding fees — `CertificateIssuanceService` calls FIN
- BR-FOF-006: Certificate numbers unique per type per school-year — UNIQUE constraint on `cert_number`
- BR-FOF-007: Government inspection visit records cannot be deleted — `VisitorPolicy::delete()` blocked when `purpose.is_government_visit = 1`
- BR-FOF-008: Approved circular cannot be edited — `CircularController::update()` blocked on Approved/Distributed status
- BR-FOF-009: Postal register entries locked after acknowledgement — update blocked when `acknowledged_at` is set
- BR-FOF-010: Anonymous feedback: respondent_user_id must be NULL — `FeedbackController::publicSubmit()` enforces this
- BR-FOF-013: Early departure ATT sync must surface failure — silent failure not acceptable
- BR-FOF-015: Aadhar number last 4 digits only in UI — Blade masking; full number stored encrypted

#### Section 5 — Workflow State Machines (5 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, NTF dispatched)

FSMs to document:
1. **Visitor Lifecycle** — `In → Out` (checkout) | `In → Overstay` (scheduled command at closing)
   Side effect on registration: pass_number generated, in_time = NOW()
2. **Gate Pass FSM** — `Pending_Approval → Approved/Rejected` → `Exited` → `Returned`
   Side effect on create: parent NTF dispatched; on Approved: front desk notified
3. **Circular FSM** — `Draft → Pending_Approval → Approved → Distributed | Recalled`
   Side effect on Distributed: `fof_circular_distributions` rows created + NTF email/SMS per recipient
4. **Certificate Request FSM** — `Pending_Approval → Approved → Issued | Rejected | Cancelled`
   Side effect on Issued: DomPDF generated, cert_number assigned, stored in sys_media
   Pre-condition for TC/Migration: FIN fee clearance check
5. **Appointment FSM** — `Pending → Confirmed → Completed | No_Show | Cancelled`
   Side effect on Confirmed: NTF reminder scheduled; on No_Show: auto-flagged

#### Section 6 — Functional Requirements Summary (17 FRs)
For each FR-FOF-01 to FR-FOF-17:
| FR ID | Name | Phase | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Group by implementation phase (Phase 1–5 per req v2 Section 11.3).

#### Section 7 — Permission Matrix
| Permission String | Admin | Front Office Staff | Principal | Communication Mgr | Teacher | Student/Parent |
|---|---|---|---|---|---|---|

Derive permissions from req v2 Section 3 (Stakeholders & Roles). Include:
- `frontoffice.visitor.*` (CRUD)
- `frontoffice.gate-pass.*`
- `frontoffice.gate-pass.approve`
- `frontoffice.early-departure.*`
- `frontoffice.circular.*`
- `frontoffice.circular.approve`
- `frontoffice.circular.distribute`
- `frontoffice.notice.*`
- `frontoffice.certificate-request.*`
- `frontoffice.certificate-request.approve`
- `frontoffice.certificate-request.issue`
- `frontoffice.complaint.*`
- `frontoffice.feedback.*`
- `frontoffice.communication.email`
- `frontoffice.communication.sms`
- `frontoffice.emergency-contact.*`

#### Section 8 — Service Architecture (5 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\FrontOffice\app\Services
Depends on:  [other services it calls]
Fires:       [events or NTF dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. **VisitorService** — createVisitor (generate pass_number VP-YYYYMMDD-NNN, set in_time); checkoutVisitor (set out_time, status = Out); flagOverstay (batch update unchecked visitors to Overstay at closing time)
2. **GatePassService** — createPass (generate GP-YYYYMMDD-NNN, dispatch parent NTF for students, enforce BR-FOF-004 one-active-pass rule); approvePass (notify front desk); markExited; markReturned
3. **CircularService** — createCircular (generate CIR-YYYY-NNNN); submitForApproval; approve (record approver+timestamp, lock edits); distribute (resolve recipients from audience config, dispatch NTF per recipient, create fof_circular_distributions rows); recall
4. **CertificateIssuanceService** — requestCertificate (generate CERT-YYYY-NNNNN); approve; issue (check fee clearance via FIN for TC/Migration, call DomPDF to generate PDF, assign cert_number per type format, store in sys_media); reject; getNextCertNumber(type, year)
5. **EarlyDepartureService** — logDeparture (generate ED-YYYYMMDD-NNN, dispatch parent NTF); syncAttendance (call ATT service to mark student absent for remaining periods; update att_sync_status; on failure: alert front desk + queue retry via EarlyDepartureAttSyncJob)

#### Section 9 — Integration Contracts (5 integrations)
For each integration:
| Integration | FOF Action | External Module | How | Payload | Failure Handling |
|---|---|---|---|---|---|
- `ATT sync` → Early departure → ATT service call → mark absent for remaining periods → retry job on failure
- `NTF circular` → CircularService::distribute() → NTF email+SMS channels → fof_circular_distributions log
- `NTF gate pass` → GatePassService::createPass() → NTF parent notification → log in fof_communication_logs
- `FIN fee check` → CertificateIssuanceService::issue() → FIN balance check service → block if outstanding
- `CMP escalation` → ComplaintController::escalate() → CMP complaint created → fof_complaints.cmp_complaint_id set

#### Section 10 — Non-Functional Requirements
From req v2 Section 10. For each NFR add an "Implementation Note" column:
- Visitor registration < 1 second — minimal validation, pass_number generated in service layer
- Visitor list load < 2 seconds — indexed on DATE(in_time) + status; paginated 25/page
- 300+ visitor registrations/day per tenant — composite index on in_time; optimised queries
- Print slips: `@media print` CSS only (no PDF) — visitor pass, gate pass, early departure slip
- Certificate PDF: DomPDF with school letterhead template per cert type
- ATT sync: retry-on-failure with front desk alert (silent failure NOT acceptable per NFR)
- NTF graceful degrade: queue retry mechanism if NTF channel unavailable
- Government visit records: permanent retention, no deletion (BR-FOF-007, VisitorPolicy)
- Aadhar masking: Blade helper masks number to last 4 digits (full number never sent to browser)
- Tablet support: responsive layout for visitor/early departure forms (receptionist device)

#### Section 11 — Test Plan Outline
From req v2 Section 12:

**Feature Tests (Pest) — test files:**
| File | Key Scenarios |
|---|---|
(List all test files from req v2 Section 12 with scenario descriptions)

**Unit Tests (PHPUnit) — test files:**
| File | Key Scenarios |
|---|---|
(List unit test files covering BR-FOF-006 cert number uniqueness, BR-FOF-010 anonymous feedback, emergency notice bypass, multi-SMS unit calc)

**Test Data:**
- Required seeders for test database: `FofVisitorPurposeSeeder`
- Required factories: VisitorFactory, GatePassFactory, CircularFactory, CertificateRequestFactory
- Mock strategy: `Event::fake()` for NTF dispatch tests; `Queue::fake()` for `EarlyDepartureAttSyncJob`; ATT service mock for early departure tests; FIN fee service mock for certificate tests

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `FOF_FeatureSpec.md` | `{OUTPUT_DIR}/FOF_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 22 fof_* tables appear in Section 2 entity inventory
- [ ] All 17 FRs (FOF-01 to FOF-17) appear in Section 6
- [ ] All 15 business rules (BR-FOF-001 to BR-FOF-015) in Section 4 with enforcement point
- [ ] All 5 FSMs documented with ASCII state diagram and side effects
- [ ] All 5 services listed with key method signatures in Section 8
- [ ] All 5 integration contracts documented in Section 9
- [ ] `fof_visitors.vsm_visitor_id → vsm_visitors.id` noted as nullable (pre-reg handoff only)
- [ ] `fof_complaints.cmp_complaint_id → cmp_complaints.id` noted as nullable (escalation only)
- [ ] `fof_certificate_requests.cert_number` UNIQUE constraint noted (BR-FOF-006)
- [ ] **No `tenant_id` column** mentioned anywhere in any table definition
- [ ] BR-FOF-007 (government visit delete block) enforcement point: policy
- [ ] BR-FOF-008 (approved circular edit block) enforcement point: service_layer/controller
- [ ] BR-FOF-013 (ATT sync failure = front desk alert, not silent) explicitly noted
- [ ] Permission matrix covers Admin / Front Office Staff / Principal / Communication Mgr / Teacher / Student
- [ ] Distinction between FOF (receptionist) and VSM (security guard) stated in Section 1
- [ ] All cross-module column names verified against tenant_db_v2.sql (use EXACT names from DDL)

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/FOF_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/FOF_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 5 (canonical column definitions for all 22 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify referenced table column names and data types; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`FOF_DDL_v1.sql`)

Generate CREATE TABLE statements for all 22 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**
1. Table prefix: `fof_` for all tables — no exceptions
2. Every table MUST include: `id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `updated_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
   Exception: `fof_circular_distributions` omits `deleted_at` and `updated_by` (immutable distribution log — no soft delete)
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. No junction suffix needed (no pure bridge tables in FOF — all tables carry business data)
5. JSON columns: suffix `_json` (e.g., `audience_filter_json`, `stages_json`, `params_json`)
6. Boolean flag columns: prefix `is_` or `has_`
7. All IDs and FK references: `BIGINT UNSIGNED` (consistency with tenant_db convention). Exception: `photo_media_id`, `attachment_media_id`, `media_id` → `INT UNSIGNED` (sys_media uses INT)
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_fof_{tableshort}_{column}` (e.g., `fk_fof_vis_purpose_id`)
12. **Do NOT recreate std_*, sys_*, vsm_*, cmp_*, ntf_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. `fof_circular_distributions` is an append-only distribution log — no `deleted_at`; no UPDATE routes

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No fof_* dependencies (may reference sys_*/std_*/vsm_* only):
  `fof_visitor_purposes` (no fof deps),
  `fof_emergency_contacts` (no fof deps),
  `fof_notices` (no fof deps),
  `fof_school_events` (no fof deps),
  `fof_email_templates` (no fof deps),
  `fof_feedback_forms` (no fof deps),
  `fof_key_register` (no fof deps → sys_users)

Layer 2 — Depends on Layer 1 + cross-module:
  `fof_visitors` (→ fof_visitor_purposes + vsm_visitors nullable + sys_media nullable),
  `fof_gate_passes` (→ std_students nullable + sys_users),
  `fof_early_departures` (→ std_students),
  `fof_phone_diary` (→ sys_users nullable),
  `fof_postal_register` (→ sys_users nullable),
  `fof_dispatch_register` (→ sys_users nullable),
  `fof_appointments` (→ sys_users),
  `fof_lost_found` (→ sys_media nullable + sys_users nullable),
  `fof_certificate_requests` (→ std_students + sys_users nullable + sys_media nullable),
  `fof_complaints` (→ cmp_complaints nullable)

Layer 3 — Depends on Layer 2:
  `fof_circulars` (→ sys_media nullable + sys_users nullable),
  `fof_feedback_responses` (→ fof_feedback_forms)

Layer 4 — Depends on Layer 3:
  `fof_circular_distributions` (→ fof_circulars + sys_users),
  `fof_communication_logs` (→ fof_email_templates nullable),
  `fof_sms_logs` (→ fof_communication_logs)

**Critical unique constraints to include:**
```sql
-- fof_visitor_purposes
UNIQUE KEY uq_fof_vp_code (code)

-- fof_visitors
UNIQUE KEY uq_fof_vis_pass_number (pass_number)

-- fof_gate_passes
UNIQUE KEY uq_fof_gp_pass_number (pass_number)

-- fof_early_departures
UNIQUE KEY uq_fof_ed_departure_number (departure_number)

-- fof_postal_register
UNIQUE KEY uq_fof_pr_postal_number (postal_number)

-- fof_dispatch_register
UNIQUE KEY uq_fof_dr_dispatch_number (dispatch_number)

-- fof_circulars
UNIQUE KEY uq_fof_cir_circular_number (circular_number)

-- fof_appointments
UNIQUE KEY uq_fof_apt_appointment_number (appointment_number)

-- fof_lost_found
UNIQUE KEY uq_fof_lf_item_number (item_number)

-- fof_certificate_requests
UNIQUE KEY uq_fof_cr_request_number (request_number)
UNIQUE KEY uq_fof_cr_cert_number (cert_number)      -- nullable, allows multiple NULLs
```

**ENUM values (exact, to match application code):**
```
fof_visitors.id_proof_type:           'Aadhar','Driving_License','Passport','Voter_ID','PAN','Employee_ID','Other'
fof_visitors.status:                  'In','Out','Overstay'
fof_gate_passes.person_type:          'Student','Staff'
fof_gate_passes.purpose:              'Medical','Personal','Official','Sports','Family_Emergency','Other'
fof_gate_passes.status:               'Pending_Approval','Approved','Rejected','Exited','Returned','Cancelled'
fof_early_departures.reason:          'Medical','Family_Emergency','Event','Bereavement','Other'
fof_early_departures.collecting_person_relation: 'Father','Mother','Guardian','Sibling','Other'
fof_early_departures.att_sync_status: 'Pending','Synced','Failed'
fof_phone_diary.call_type:            'Incoming','Outgoing'
fof_postal_register.postal_type:      'Inward','Outward'
fof_postal_register.document_type:    'Letter','Courier','Parcel','Government_Notice','Cheque','Legal','Other'
fof_dispatch_register.document_type:  'Letter','Notice','Legal','Certificate','Report','Circular','Other'
fof_dispatch_register.dispatch_mode:  'Hand','Post','Courier','Email','Fax'
fof_circulars.audience:               'Parents','Staff','Both','Specific_Class','Specific_Section'
fof_circulars.status:                 'Draft','Pending_Approval','Approved','Distributed','Recalled'
fof_notices.category:                 'Academic','Administrative','Sports','Cultural','Holiday','Emergency','Other'
fof_notices.audience:                 'All','Students','Staff','Parents'
fof_notices.status:                   'Active','Archived'
fof_appointments.appointment_type:    'Parent_Teacher_Meeting','Principal_Meeting','Grievance','Admission_Enquiry','Other'
fof_appointments.status:              'Pending','Confirmed','Completed','Cancelled','No_Show'
fof_lost_found.category:              'Electronics','Clothing','Stationery','ID_Card','Money','Jewellery','Books','Sports','Other'
fof_lost_found.status:                'Unclaimed','Claimed','Disposed','Returned_to_Authority'
fof_key_register.key_type:            'Room','Lab','Vehicle','Cabinet','Store','Other'
fof_key_register.status:              'Available','Issued','Overdue','Lost'
fof_certificate_requests.cert_type:   'Bonafide','Character','Fee_Paid','Study','TC_Copy','Migration','Conduct','Other'
fof_certificate_requests.status:      'Pending_Approval','Approved','Rejected','Issued','Cancelled'
fof_emergency_contacts.contact_type:  'Hospital','Police','Fire','Ambulance','Transport','Utility','Parent_Emergency','Government','Other'
fof_circular_distributions.channel:  'Email','SMS','Push'
fof_circular_distributions.status:   'Queued','Sent','Delivered','Failed'
fof_school_events.event_type:         'Academic','Sports','Cultural','PTM','Holiday','Exam','Admission','Other'
fof_school_events.audience:           'All','Students','Staff','Parents'
```

**Critical columns to get right:**
- `fof_visitors.vsm_visitor_id`: `BIGINT UNSIGNED NULL` — nullable, optional VSM handoff only
- `fof_gate_passes.student_id`: `INT UNSIGNED NULL` — nullable (staff passes have no student)
- `fof_gate_passes.staff_user_id`: `BIGINT UNSIGNED NULL` — nullable (student passes have no staff)
- `fof_complaints.cmp_complaint_id`: `BIGINT UNSIGNED NULL` — nullable, set only on escalation
- `fof_certificate_requests.cert_number`: `VARCHAR(30) NULL UNIQUE` — null until issued; UNIQUE constraint allows multiple NULLs
- `fof_certificate_requests.stages_json`: `JSON NULL` — multi-stage approval history array
- `fof_circulars.audience_filter_json`: `JSON NULL` — class/section IDs array when audience is Specific_Class/Section
- `fof_circular_distributions`: NO `deleted_at`, NO `updated_by` — immutable append-only log
- `photo_media_id`, `attachment_media_id`, `media_id`: `INT UNSIGNED NULL` — sys_media uses INT not BIGINT

**File header comment to include:**
```sql
-- =============================================================================
-- FOF — Front Office Module DDL
-- Module: FrontOffice (Modules\FrontOffice)
-- Table Prefix: fof_* (22 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: FOF_FrontOffice_Requirement.md v2
-- Sub-Modules: Core Registers, Communication, Appointments & Support,
--              Complaints & Feedback, Communication Logs
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`FOF_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_fof_tables.php`.
- `up()`: creates all 22 tables in Layer 1 → Layer 4 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 4 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, JSON with `->json()`
- All FK constraints added in `up()` using `$table->foreign()`
- `fof_circular_distributions`: use `->timestamps()` only (no `softDeletes()`, no `updated_by`)

### Phase 2C Task — Generate Seeders (1 seeder + 1 runner)

Namespace: `Modules\FrontOffice\Database\Seeders`

**1. `FofVisitorPurposeSeeder.php`** — 8 seeded purposes (`is_active=1`):
```
Parent Meeting           | code: PARENT_MTG          | is_government_visit: 0 | sort_order: 1
Government Inspection    | code: GOVT_INSPECTION      | is_government_visit: 1 | sort_order: 2
Job Interview            | code: JOB_INTERVIEW        | is_government_visit: 0 | sort_order: 3
Delivery / Courier       | code: DELIVERY             | is_government_visit: 0 | sort_order: 4
Sales Visit              | code: SALES_VISIT          | is_government_visit: 0 | sort_order: 5
Alumni Visit             | code: ALUMNI               | is_government_visit: 0 | sort_order: 6
Emergency                | code: EMERGENCY            | is_government_visit: 0 | sort_order: 7
Other                    | code: OTHER                | is_government_visit: 0 | sort_order: 99
```

**2. `FofSeederRunner.php`** (Master seeder):
```php
$this->call([
    FofVisitorPurposeSeeder::class,   // no dependencies
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `FOF_DDL_v1.sql` | `{OUTPUT_DIR}/FOF_DDL_v1.sql` |
| `FOF_Migration.php` | `{OUTPUT_DIR}/FOF_Migration.php` |
| `FOF_TableSummary.md` | `{OUTPUT_DIR}/FOF_TableSummary.md` |
| `Seeders/FofVisitorPurposeSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/FofSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 22 fof_* tables exist in DDL (8 core registers + 4 communication + 4 appointments/support + 3 complaints/feedback + 3 comm logs = 22 ✓)
- [ ] Standard columns (id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) on all tables EXCEPT `fof_circular_distributions` (append-only — no deleted_at, no updated_by)
- [ ] `fof_circular_distributions` has only id, fk columns, channel, status, timestamps — verified as append-only
- [ ] `fof_visitors.vsm_visitor_id` is `BIGINT UNSIGNED NULL`
- [ ] `fof_gate_passes.student_id` is `INT UNSIGNED NULL` (nullable for staff passes)
- [ ] `fof_complaints.cmp_complaint_id` is `BIGINT UNSIGNED NULL`
- [ ] `fof_certificate_requests.cert_number` is NULLABLE UNIQUE — allows NULL before issuance
- [ ] `photo_media_id`, `attachment_media_id`, `media_id` columns use `INT UNSIGNED` (not BIGINT)
- [ ] **No `tenant_id` column** on any table
- [ ] All unique constraints listed above are present
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] `fof_visitor_purposes.is_government_visit` flag present — used by BR-FOF-007 policy
- [ ] `fof_early_departures.att_sync_status` ENUM present with Pending/Synced/Failed
- [ ] `fof_certificate_requests.stages_json` JSON column present for multi-stage approval history
- [ ] `fof_circulars.audience_filter_json` JSON column present for class/section targeting
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_fof_` convention throughout
- [ ] `FofVisitorPurposeSeeder` has all 8 purposes with correct code and is_government_visit values
- [ ] `Government Inspection` purpose seeded with `is_government_visit = 1`
- [ ] `FOF_TableSummary.md` has one-line description for all 22 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `FOF_DDL_v1.sql` + Migration + 2 seeder files. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/FOF_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 6 (routes), Section 7 (UI screens), Section 11 (implementation order), Appendix C (file structure)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (naming conventions)

### Phase 3 Task — Generate `FOF_Dev_Plan.md`

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

Controllers to define (18 total, from req v2 Appendix C file structure):
1. `FrontOfficeDashboardController` — index (today's snapshot: visitor count, pending gate passes, pending certs, active keys out)
2. `VisitorController` — index, create, store, show, checkout, pass (print view)
3. `GatePassController` — index, create, store, approve, reject, markReturned
4. `EarlyDepartureController` — index, create, store
5. `PhoneDiaryController` — index, store, update (mark action completed)
6. `PostalRegisterController` — index, store, acknowledge
7. `DispatchRegisterController` — index, store
8. `CircularController` — index, create, store, show, approve, distribute
9. `NoticeBoardController` — index, store, update, destroy
10. `AppointmentController` — index, calendar, store, confirm, cancel
11. `LostFoundController` — index, store, claim
12. `KeyRegisterController` — index, store (create key master), issue, return
13. `EmergencyContactController` — index, store, update, destroy
14. `CertificateRequestController` — index, store, show, approve, reject, issue, download, log
15. `ComplaintController` — index, store, show, resolve, escalate
16. `FeedbackController` — index, store, report, publicForm, publicSubmit
17. `CommunicationController` — emailCompose, emailSend, templates*, smsSend, smsLogs
18. `SchoolEventController` — index, store, update

#### Section 2 — Service Inventory (5 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Events/NTF dispatched
- Other services called (dependency graph)

Include the early departure sync sequence as inline pseudocode in `EarlyDepartureService`:
```
syncAttendance(EarlyDeparture $departure): void
  Step 1: Resolve student and departure time
  Step 2: Call ATT service: markAbsentFromPeriod(student_id, date, departure_time)
  Step 3: If success: update att_sync_status = Synced, att_synced_at = NOW()
  Step 4: If failure: update att_sync_status = Failed
            dispatch EarlyDepartureAttSyncJob (3 retries, 60s delay)
            flash alert to front desk session (BR-FOF-013 — silent failure not acceptable)
```

Include the circular distribution sequence as inline pseudocode in `CircularService`:
```
distribute(Circular $circular): void
  Step 1: Validate status = Approved (pre-condition)
  Step 2: Resolve recipient list from audience config
          - Parents/Both: all parent users with students in target classes
          - Staff/Both: all staff users
          - Specific_Class/Section: filter by audience_filter_json
  Step 3: DB transaction begins
  Step 4: For each recipient:
            Create fof_circular_distributions row (status = Queued)
            Dispatch NTF email job
            If SMS enabled: dispatch NTF SMS job
  Step 5: Update fof_circulars.status = Distributed, distributed_at = NOW()
  Step 6: DB transaction commits
```

Include the certificate issuance sequence as inline pseudocode in `CertificateIssuanceService`:
```
issue(CertificateRequest $request, string $issuedTo): void
  Step 1: Verify status = Approved (pre-condition)
  Step 2: If cert_type in [TC_Copy, Migration]:
            FIN fee-clearance check — block if outstanding fees exist (BR-FOF-005)
  Step 3: Generate cert_number: {PREFIX}-{YYYY}-{NNN} per type mapping
  Step 4: Load student data + school branding
  Step 5: Render DomPDF using template for cert_type
  Step 6: Store PDF in sys_media → set media_id
  Step 7: Update: cert_number, issued_at, issued_by, issued_to, status = Issued
  Step 8: Dispatch NTF to student/parent: certificate ready

Cert number prefix mapping:
  Bonafide → BON | Character → CHAR | Fee_Paid → FEE | Study → STD
  TC_Copy → TC | Migration → MIG | Conduct → COND | Other → CERT
```

#### Section 3 — FormRequest Inventory (10 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

10 total (from req v2 Appendix C Requests/ folder):
- `RegisterVisitorRequest` — visitor_name required, visitor_mobile required, id_proof_type valid ENUM, purpose_id exists in fof_visitor_purposes
- `IssueGatePassRequest` — person_type valid ENUM, student_id or staff_user_id required per type, purpose valid ENUM, expected_return_time after now; custom rule: no active gate pass for student (BR-FOF-004)
- `EarlyDepartureRequest` — student_id exists in std_students, departure_time required, reason valid ENUM, collecting_person_name required, collecting_person_relation valid ENUM
- `StoreCircularRequest` — title required, subject required, body required, audience valid ENUM, effective_date required, audience_filter_json required when audience is Specific_Class/Section
- `StoreNoticeRequest` — title required, content required, category valid ENUM, audience valid ENUM, display_from required, display_until after display_from if provided
- `BookAppointmentRequest` — appointment_type valid ENUM, with_user_id exists in sys_users, appointment_date required, start_time and end_time required, end_time after start_time; custom rule: no slot conflict for same staff at same time
- `IssueCertificateRequest` — issued_to required, cert_type valid ENUM
- `RequestCertificateRequest` — student_id exists in std_students, cert_type valid ENUM, purpose required, copies_requested between 1–5
- `SendBulkEmailRequest` — subject required, body required, recipient_group valid ENUM; template_id exists in fof_email_templates if provided
- `SendBulkSmsRequest` — message required, max:320 (2 SMS units), recipient_group valid ENUM; custom rule: show multi-SMS unit count warning

#### Section 4 — Blade View Inventory (~60 views)

List all blade views grouped by feature group. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Feature groups and screen counts (from req v2 Section 7 — 28 screens):
- Dashboard: 1 view
- Visitors (register, list, pass print): 3 views
- Gate Pass (list with approval, issue form): 2 views
- Early Departure (form, today's list): 2 views
- Phone Diary (log, register): 2 views
- Postal Register (inward/outward tabs): 1 view
- Dispatch Register (log): 1 view
- Circulars (list, editor, show/distribute): 3 views
- Notice Board (active/archived, create/edit form): 2 views
- Appointments (calendar, book form): 2 views
- Lost & Found (register, list): 2 views
- Key Register (list, issue form): 2 views
- Emergency Contacts (directory): 1 view
- Certificates (queue, show/issue, issuance log): 3 views
- Complaints (register list, show): 2 views
- Feedback (forms list, public response form): 2 views
- Email/SMS compose + logs: 4 views
- School Events: 1 view
- Shared partials: ~5 (pagination, modals, print-slip, status badges, approval buttons)

For key screens document:
- Visitor pass — print-optimized A6 `@media print` CSS, no PDF; school logo, pass number, in-time, valid-until
- Gate pass list — Tabs: Pending Approvals / Active / History; approve/reject inline with Alpine.js
- Circular editor — rich text editor (Quill or TinyMCE), audience picker, attachment upload
- Certificate issue — PDF preview panel + receiver name input + issue confirmation
- Feedback public form — token URL, no auth, anonymous checkbox, MCQ/rating/text question types
- Appointment calendar — day/week view colour-coded by type using FullCalendar.js or custom

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 6 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by feature group (web routes + API routes). Count total routes at end (target ~75 web + ~12 API).
Middleware on all web routes: `['auth', 'tenant', 'EnsureTenantHasModule:FrontOffice']`
Middleware on API routes: `['auth:sanctum', 'tenant']`

Special routes requiring no auth:
- `GET /feedback/{token}` — `FeedbackController@publicForm` — no auth middleware
- `POST /feedback/{token}` — `FeedbackController@publicSubmit` — no auth middleware

#### Section 6 — Implementation Phases (5 phases per req v2 Section 11.3)

For each phase, provide a detailed sprint plan:

**Phase 1 — Core Registers** (no complex cross-module deps beyond sys_*, std_*):
FRs: FOF-01, FOF-02, FOF-03, FOF-04, FOF-05, FOF-06
Files to create:
- Controllers: FrontOfficeDashboardController, VisitorController, GatePassController, EarlyDepartureController, PhoneDiaryController, PostalRegisterController, DispatchRegisterController, EmergencyContactController
- Services: VisitorService (createVisitor, checkoutVisitor, flagOverstay), GatePassService (createPass, approve, markExited, markReturned), EarlyDepartureService (logDeparture, syncAttendance)
- Models: VisitorPurpose, Visitor, GatePass, EarlyDeparture, PhoneDiary, PostalRegister, DispatchRegister, EmergencyContact
- FormRequests: RegisterVisitorRequest, IssueGatePassRequest, EarlyDepartureRequest
- Seeders: FofVisitorPurposeSeeder, FofSeederRunner
- Views: ~13 views (dashboard + visitor × 3 + gate pass × 2 + early dep × 2 + phone × 2 + postal × 1 + dispatch × 1 + emergency × 1)
- Artisan: `fof:flag-overstay` scheduled at school closing time
- Jobs: EarlyDepartureAttSyncJob (3 retries, 60s delay)
- Tests: VisitorRegistrationTest, VisitorCheckoutTest, OverstayFlagTest, GovtVisitDeleteBlockTest, GatePassCreateTest, DuplicateGatePassTest, GatePassApprovalTest, GatePassLifecycleTest, EarlyDepartureAttSyncTest, EarlyDepartureAttFailTest, PostalAcknowledgeLockTest

**Phase 2 — Communication** (requires NTF module):
FRs: FOF-07, FOF-08, FOF-17
Files to create:
- Controllers: CircularController, NoticeBoardController, SchoolEventController
- Services: CircularService (createCircular, submitForApproval, approve, distribute, recall)
- Models: Circular, CircularDistribution, Notice, SchoolEvent
- FormRequests: StoreCircularRequest, StoreNoticeRequest
- Views: ~6 views (circular × 3 + notice × 2 + events × 1)
- Tests: CircularDraftApproveTest, CircularEditBlockTest, CircularDistributionTest, CircularAudienceFilterTest, NoticeEmergencyBypassTest

**Phase 3 — Certificates & Complaints** (requires STD, FIN for TC/Migration certs, CMP for escalation):
FRs: FOF-13, FOF-14
Files to create:
- Controllers: CertificateRequestController, ComplaintController
- Services: CertificateIssuanceService (requestCertificate, approve, issue, reject, getNextCertNumber)
- Models: CertificateRequest, FofComplaint
- FormRequests: RequestCertificateRequest, IssueCertificateRequest
- Views: ~5 views (cert queue + show/issue + log + complaint list + show)
- Tests: CertificateRequestTest, CertificateFeesBlockTest, CertificateIssuanceTest, CertificateNumberUniqueTest, ComplaintEscalateTest

**Phase 4 — Appointments, Lost & Found, Key Management**:
FRs: FOF-09, FOF-10, FOF-11, FOF-12
Files to create:
- Controllers: AppointmentController, LostFoundController, KeyRegisterController
- Models: Appointment, LostFound, KeyRegister
- FormRequests: BookAppointmentRequest
- Views: ~7 views (appt calendar + book + lost found × 2 + key register × 2 + emergency contacts)
- Tests: AppointmentDoubleBookTest, KeyDoubleIssueTest

**Phase 5 — Feedback & Bulk Communication**:
FRs: FOF-15, FOF-16
Files to create:
- Controllers: FeedbackController, CommunicationController
- Models: FeedbackForm, FeedbackResponse, CommunicationLog, EmailTemplate, SmsLog
- FormRequests: SendBulkEmailRequest, SendBulkSmsRequest
- Views: ~6 views (feedback forms list + public form + email compose + templates + SMS compose + SMS logs)
- Tests: FeedbackAnonymousTest, FeedbackPublicTokenTest, BulkEmailSendTest, SmsMultiPartTest

#### Section 7 — Seeder Execution Order

```
php artisan module:seed FrontOffice --class=FofSeederRunner
  ↓ FofVisitorPurposeSeeder    (no dependencies)
```

Artisan scheduled commands (register in `routes/console.php`):
```
fof:flag-overstay    → daily at school closing time (configurable, default 17:00)
```

Artisan for test runs: use `FofVisitorPurposeSeeder` as minimum required seeder.

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// ATT service: mock with Mockery for early departure tests (ATT module may not be ready)
// FIN fee service: mock for certificate TC/Migration tests
// Event::fake() in circular distribution tests
// Queue::fake() for EarlyDepartureAttSyncJob tests
// Storage::fake() for certificate PDF generation tests (DomPDF)
```

**Minimum Test Coverage Targets:**
- Visitor FSM: In → Out (checkout) + Overstay flag (BR-FOF-002)
- BR-FOF-004 (one active gate pass per student): DuplicateGatePassTest
- BR-FOF-005 (fee clearance for TC/Migration): CertificateFeesBlockTest
- BR-FOF-006 (cert number uniqueness): CertificateNumberUniqueTest
- BR-FOF-007 (govt visit delete block): GovtVisitDeleteBlockTest
- BR-FOF-008 (approved circular edit block): CircularEditBlockTest
- BR-FOF-013 (ATT sync failure = alert): EarlyDepartureAttFailTest — verify att_sync_status = Failed AND front desk alert session message set
- BR-FOF-010 (anonymous feedback NULL user): FeedbackAnonymousTest
- Circular audience filter: CircularAudienceFilterTest — Class 5 circular sends to Class 5 parents only

**Test File Summary (from req v2 Section 12):**
List all test files with file path, test count, and key scenarios covering all 28 test scenarios in req v2 Section 12.

**Factory Requirements:**
```
VisitorFactory              — generates pass_number (VP-YYYYMMDD-NNN), in_time, status=In
GatePassFactory             — generates pass_number (GP-YYYYMMDD-NNN), person_type, status=Pending_Approval
CircularFactory             — generates circular_number (CIR-YYYY-NNNN), status=Draft
CertificateRequestFactory   — generates request_number (CERT-YYYY-NNNNN), cert_type, status=Pending_Approval
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `FOF_Dev_Plan.md` | `{OUTPUT_DIR}/FOF_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 18 controllers listed with all methods
- [ ] All 5 services listed with at minimum 3 key method signatures each
- [ ] EarlyDepartureService::syncAttendance() pseudocode present (failure = alert, not silent)
- [ ] CircularService::distribute() pseudocode present (recipient resolution + fof_circular_distributions creation)
- [ ] CertificateIssuanceService::issue() pseudocode present (fee check + DomPDF + cert_number format)
- [ ] All 10 FormRequests listed with their key validation rules
- [ ] All 17 FRs (FOF-01 to FOF-17) appear in at least one implementation phase
- [ ] All 5 implementation phases have: FRs covered, files to create, test count
- [ ] Seeder execution order documented
- [ ] `fof:flag-overstay` Artisan command listed with schedule
- [ ] Route list consolidated with middleware (~75 web + ~12 API, total ~87 routes)
- [ ] View count per feature group totals approximately 60
- [ ] Test strategy includes ATT service mock + FIN fee service mock + Event::fake() for circulars
- [ ] BR-FOF-004 (duplicate gate pass) test explicitly referenced
- [ ] BR-FOF-013 (ATT sync failure alert) test explicitly referenced
- [ ] Public feedback routes noted as NO auth middleware
- [ ] `fof_circular_distributions` noted as append-only (no delete routes)
- [ ] EarlyDepartureAttSyncJob documented with 3 retries + 60s delay

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `FOF_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/FOF_FeatureSpec.md`
2. `{OUTPUT_DIR}/FOF_DDL_v1.sql` + Migration + 2 Seeders
3. `{OUTPUT_DIR}/FOF_Dev_Plan.md`
Development lifecycle for FOF (FrontOffice) module is ready to begin."

---

## QUICK REFERENCE — FOF Module Tables vs Controllers vs Services

| Domain | fof_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Visitor Register | fof_visitor_purposes, fof_visitors | VisitorController | VisitorService |
| Gate Pass | fof_gate_passes | GatePassController | GatePassService |
| Early Departure | fof_early_departures | EarlyDepartureController | EarlyDepartureService |
| Phone Diary | fof_phone_diary | PhoneDiaryController | — |
| Postal / Dispatch | fof_postal_register, fof_dispatch_register | PostalRegisterController, DispatchRegisterController | — |
| Emergency Contacts | fof_emergency_contacts | EmergencyContactController | — |
| Circulars | fof_circulars, fof_circular_distributions | CircularController | CircularService |
| Notice Board | fof_notices | NoticeBoardController | — |
| School Events | fof_school_events | SchoolEventController | — |
| Appointments | fof_appointments | AppointmentController | — |
| Lost & Found | fof_lost_found | LostFoundController | — |
| Key Register | fof_key_register | KeyRegisterController | — |
| Certificates | fof_certificate_requests | CertificateRequestController | CertificateIssuanceService |
| Complaints | fof_complaints | ComplaintController | — |
| Feedback | fof_feedback_forms, fof_feedback_responses | FeedbackController | — |
| Communication | fof_email_templates, fof_communication_logs, fof_sms_logs | CommunicationController | — |
| Dashboard | — | FrontOfficeDashboardController | — |
