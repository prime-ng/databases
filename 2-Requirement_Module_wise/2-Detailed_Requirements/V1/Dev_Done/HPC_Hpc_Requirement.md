# Hpc Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** HPC | **Module Path:** `Modules/Hpc`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `hpc_*` | **Processing Mode:** FULL
**RBS Reference:** Module I — Examination & Gradebook (HPC sections)

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Business Context & NEP 2020 Alignment](#2-business-context--nep-2020-alignment)
3. [Architecture Overview](#3-architecture-overview)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model — All `hpc_*` Tables](#5-data-model--all-hpc_-tables)
6. [Controllers & Services Inventory](#6-controllers--services-inventory)
7. [Routes Inventory](#7-routes-inventory)
8. [Form Requests & Validation](#8-form-requests--validation)
9. [Workflows](#9-workflows)
10. [Integration Points](#10-integration-points)
11. [PDF Generation Architecture](#11-pdf-generation-architecture)
12. [Multi-Actor Data Collection Architecture](#12-multi-actor-data-collection-architecture)
13. [Security & Authorization](#13-security--authorization)
14. [Known Issues & Technical Debt](#14-known-issues--technical-debt)
15. [Implementation Status & Gap Analysis](#15-implementation-status--gap-analysis)

---

## 1. Module Overview

### 1.1 Purpose

The Hpc (Holistic Progress Card) module implements India's NEP 2020 PARAKH-aligned assessment framework for K-12 schools. It replaces traditional mark-sheet report cards with a comprehensive, multi-dimensional holistic progress card that captures academic performance, life skills, social-emotional development, co-curricular activities, and parent/peer observations.

### 1.2 Scope

- Generation of 4 differentiated PDF report card templates mapped to grade ranges
- Multi-actor data collection from teachers, students, parents, and peers
- Template-driven data entry with 138 pages of data-mapped HTML form fields
- Approval workflow from draft to published
- Email distribution of signed-URL report links to guardians
- Integration with Syllabus (competencies, Bloom taxonomy), LMS (exam/quiz/homework), and Attendance modules
- NEP/NCrF (National Credit Framework) credit calculation per grade

### 1.3 Key Stakeholders

| Actor | Role in HPC |
|-------|------------|
| Class Teacher | Primary data entry; reviews student/parent/peer submissions |
| Student | Self-assessment sections (Templates 3 & 4 especially) |
| Parent/Guardian | Home observation sections (Templates 1, 2, 3) |
| Peer (classmate) | Peer evaluation sections (Templates 3 & 4) |
| Principal | Reviews and approves reports before publishing |
| School Admin | Publishes approved reports; triggers bulk email distribution |

### 1.4 Implementation Status

| Dimension | Status | Completeness |
|-----------|--------|-------------|
| Template Structure (4 templates, 138 pages) | Done | 95% |
| Report Save / Load Pipeline | Done | 90% |
| PDF Generation (4 DomPDF templates) | Done | 90% |
| Teacher Data Entry Web Form | Done | 85% |
| Approval Workflow (state machine) | Done — code complete | 80% |
| Email Distribution (Job + Mail) | Done | 85% |
| CRUD Modules (15 sub-screens) | Done | 80% |
| LMS Auto-Feed Integration | Partial — service exists, graceful fallback | 30% |
| Credit Calculator (NCrF) | Done | 80% |
| Parent Input Collection | Infrastructure done; views not confirmed | 40% |
| Student Self-Assessment Portal | Infrastructure done; views not confirmed | 35% |
| Peer Assessment Workflow | Infrastructure done; views not confirmed | 30% |
| Role-Based Section Locking | Done — `HpcSectionRoleService` | 70% |
| Attendance Manager | Done | 75% |
| Security / Authorization | Partial — public PDF route; missing middleware | 30% |
| **Overall** | | **~59%** |

---

## 2. Business Context & NEP 2020 Alignment

### 2.1 NEP 2020 Background

India's National Education Policy 2020 mandates a shift away from high-stakes summative examinations toward competency-based, holistic assessment. PARAKH (Performance Assessment, Review, and Analysis of Knowledge for Holistic Development) — the national assessment body — has published template HPC formats for each school stage.

The four stages map to Prime-AI templates as follows:

| NEP Stage | Grades | Prime-AI Template | Approx Pages |
|-----------|--------|------------------|-------------|
| Foundational | Pre-primary to Grade 2 | Template 1 | ~5 pages |
| Preparatory | Grades 3–5 | Template 2 | ~8 pages |
| Middle | Grades 6–8 | Template 3 | ~8 pages |
| Secondary | Grades 9–12 | Template 4 | ~44 pages |

### 2.2 Data Ownership by Template

#### Template 1 (Pre-primary)
- **Teacher sections:** Developmental milestones, observations (3 pages)
- **Parent sections:** Home observations, comments (2 pages)

#### Template 2 (Grades 1–5)
- **Teacher sections:** Subject assessments, co-curricular (5 pages)
- **Parent sections:** Home resources, feedback Q1–Q10, support plan (3 pages)

#### Template 3 (Grades 6–8)
- **Teacher sections:** Subject rubrics, social-emotional (4 pages)
- **Student sections:** Self-reflection (2 pages)
- **Parent sections:** Home resources, self-evaluation, feedback (2 pages)

#### Template 4 (Grades 9–12, 44 pages)
- **Teacher sections:** Stage assessment matrix (pages 13–15, 21, 23, 25, 29–32, 38–40, 42) — ~22 pages
- **Student sections:** Self-evaluation, goals, time management, future planning, reflections (pages 2–12, 16, 19–20, 22, 24, 26, 34) — ~20 pages
- **Peer sections:** Peer feedback (pages 16, 17, 27, 33, 35) — ~5 pages
- **System sections:** Attendance aggregation, static reference (pages 1, 41) — ~2 pages

### 2.3 NCrF Credit Framework

The National Credit Framework assigns credits per grade/domain. The HPC module calculates and prints these on credit pages. Credits are calculated from `hpc_student_evaluation` data using `HpcCreditCalculatorService`. Default NCrF levels: BV1=0.05 through Gr12=4.5.

---

## 3. Architecture Overview

### 3.1 Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   TEMPLATE DEFINITION LAYER                 │
│  hpc_templates → hpc_template_parts → hpc_template_sections │
│  → hpc_template_rubrics → hpc_template_rubric_items         │
│  → hpc_template_section_items → hpc_template_section_table  │
└─────────────────────────────────────────────────────────────┘
                          ↓ drives
┌─────────────────────────────────────────────────────────────┐
│                   DATA COLLECTION LAYER                     │
│  Teacher: HpcController.formStore() → HpcReportService      │
│  Student: StudentHpcFormController → HpcReportItem upsert   │
│  Parent:  ParentHpcFormController → token-based POST        │
│  Peer:    PeerHpcFormController → PeerResponse storage      │
└─────────────────────────────────────────────────────────────┘
                          ↓ stored in
┌─────────────────────────────────────────────────────────────┐
│                   REPORT STORAGE LAYER                      │
│  hpc_reports → hpc_report_items → hpc_report_table          │
└─────────────────────────────────────────────────────────────┘
                          ↓ rendered by
┌─────────────────────────────────────────────────────────────┐
│                   PDF GENERATION LAYER                      │
│  HpcReportService → DomPDF v3.1 → 4 Blade view templates    │
│  → ZipArchive (bulk export) → signed-URL email delivery     │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 $hpcData Pattern (Architecture Decision D18)

The PDF templates use a `$hpcData` variable populated by `HpcReportService::getSavedValues()`. This returns:
- `$savedValues` — array keyed by `html_object_name` (lowercased) mapping to stored values
- `$savedTableData` — array of grid/table cell values

All Blade view templates reference fields via `$savedValues['field_name']`, enabling template-agnostic PDF rendering without hard-coded field lookups.

### 3.3 Module File Structure

```
Modules/Hpc/
├── app/
│   ├── Http/
│   │   ├── Controllers/      22 controllers
│   │   ├── Requests/         14 FormRequest classes
│   │   └── Traits/           HpcIndexDataTrait
│   ├── Jobs/                 SendHpcReportEmail
│   ├── Mail/                 HpcReportMail
│   ├── Models/               32 models
│   ├── Providers/            RouteServiceProvider, EventServiceProvider
│   └── Services/             10 services
├── database/
├── resources/
│   └── views/                48+ Blade templates
├── routes/
└── tests/
```

---

## 4. Functional Requirements

### FR-HPC-001 — Template Management

**Description:** The system shall provide CRUD management for 4 HPC template hierarchies, each consisting of pages (parts), sections, rubrics, and rubric items. Templates are data-driven; no hardcoded HTML field definitions exist in PHP.

**Sub-requirements:**
- FR-HPC-001.1: Manage `hpc_templates` — code, version, title, applicable grade (JSON), is_active
- FR-HPC-001.2: Manage `hpc_template_parts` (pages) — page_no, display_order, help_file, has_items flag
- FR-HPC-001.3: Manage `hpc_template_sections` — code, display_order, has_items flag; sections belong to parts
- FR-HPC-001.4: Manage `hpc_template_rubrics` — code, mandatory, visible, print flags; rubrics belong to sections
- FR-HPC-001.5: Manage `hpc_template_rubric_items` — html_object_name (unique per rubric), input_type (Descriptor / Numeric / Grade / Text / Boolean / Image / Json), weight, input/output level labels
- FR-HPC-001.6: Manage `hpc_template_section_items` — html_object_name, section_type (Text/Image/Table)
- FR-HPC-001.7: Manage `hpc_template_section_table` — cell definitions (section_id, row_id, column_id, html_object_name)
- FR-HPC-001.8: Support soft delete, restore, force-delete, toggle-status on all template entities

**Current Status:** Done — Controllers for all 5 template entities exist with full CRUD + soft delete. The shared tabbed template index (`hpcTemplates()` method) loads 4 paginated queries simultaneously causing 15+ queries per page load.

---

### FR-HPC-002 — HPC Parameter Configuration

**Description:** The system shall manage reference data used in rubric scoring — ability parameters (Awareness, Sensitivity, Creativity) and performance descriptors (Beginner, Proficient, Advanced). These map to NEP's 3-dimensional assessment framework.

**Sub-requirements:**
- FR-HPC-002.1: `hpc_ability_parameters` — code (AWARENESS, SENSITIVITY, CREATIVITY), name, description
- FR-HPC-002.2: `hpc_performance_descriptors` — code (BEGINNER, PROFICIENT, ADVANCED), ordinal, description
- FR-HPC-002.3: CRUD management accessible to Admin role only
- FR-HPC-002.4: Toggle-status and soft delete support

**RBS Reference:** F.I6.1 — Report Generation (grading scheme); F.I5.1 — Grade Calculation

**Current Status:** Done — `HpcParametersController` and `HpcPerformanceDescriptorController` with full CRUD.

---

### FR-HPC-003 — Circular Goals & Competency Mapping

**Description:** The system shall allow management of NEP curricular goals per class, mapped to syllabus competencies.

**Sub-requirements:**
- FR-HPC-003.1: `hpc_circular_goals` — code, name, class_id (FK sch_classes), NEP reference
- FR-HPC-003.2: `hpc_circular_goal_competency_jnt` — many-to-many between circular goals and `slb_competencies`; is_primary flag
- FR-HPC-003.3: Full CRUD with soft delete, restore, force-delete, toggle-status

**Current Status:** Done — `CircularGoalsController` with full CRUD.

---

### FR-HPC-004 — Learning Outcomes & Question Mapping

**Description:** The system shall manage learning outcomes with Bloom taxonomy classification, entity mappings (subject/lesson/topic), and question bank linkages.

**Sub-requirements:**
- FR-HPC-004.1: `hpc_learning_outcomes` — code, description, domain (FK sys_dropdown), bloom_id (FK slb_bloom_taxonomy), level
- FR-HPC-004.2: `hpc_outcome_entity_jnt` — outcome mapped to class + entity (Subject/Lesson/Topic by entity_type + entity_id)
- FR-HPC-004.3: `hpc_outcome_question_jnt` — outcome mapped to question (FK qns_questions_bank) with weightage
- FR-HPC-004.4: CRUD for all three — `LearningOutcomesController`, `QuestionMappingController`

**RBS Reference:** F.I1.1 — Exam Types; F.I5.1 — Grade Calculation

**Current Status:** Done — `LearningOutcomesController` (304 lines) and `QuestionMappingController` (195 lines) with full CRUD.

---

### FR-HPC-005 — Learning Activities

**Description:** The system shall manage learning activities per topic with activity type classification. Activities serve as evidence sources for HPC evaluation.

**Sub-requirements:**
- FR-HPC-005.1: `hpc_learning_activities` — topic_id (FK slb_topics), activity_type_id, description, expected_outcome
- FR-HPC-005.2: `hpc_learning_activity_type` — code (PROJECT, OBSERVATION, FIELD_WORK, GROUP_WORK, ART, SPORT, DISCUSSION), name, description
- FR-HPC-005.3: CRUD with soft delete support

**Current Status:** Done — `LearningActivitiesController` (263 lines).

---

### FR-HPC-006 — Curriculum Analytics Tools

**Description:** The system shall provide knowledge graph validation, topic equivalency, and syllabus coverage snapshot management for curriculum integrity.

**Sub-requirements:**
- FR-HPC-006.1: `hpc_knowledge_graph_validation` — topic integrity checks (NO_COMPETENCY, NO_OUTCOME, NO_WEIGHTAGE, ORPHAN_NODE), severity, resolved flag. `KnowledgeGraphValidationController`.
- FR-HPC-006.2: `hpc_topic_equivalency` — cross-syllabus mapping (FULL/PARTIAL/PREREQUISITE between `slb_topics`). `TopicEquivalencyController`.
- FR-HPC-006.3: `hpc_syllabus_coverage_snapshot` — percentage coverage by academic_session + class + subject + snapshot_date. `SyllabusCoverageSnapshotController`.

**Current Status:** Done — All 3 controllers with CRUD. However, none of these tables are connected to HPC report auto-generation. They exist as standalone analytics stores.

---

### FR-HPC-007 — Student HPC Evaluation (ASC Framework)

**Description:** Per-student, per-subject evaluation based on NEP's three ability parameters (Awareness, Sensitivity, Creativity) and three performance descriptors (Beginner, Proficient, Advanced). This is the primary teacher-entered rubric evaluation, distinct from the HPC report form.

**Sub-requirements:**
- FR-HPC-007.1: `hpc_student_evaluation` — stores one row per (student, subject, competency, ability_parameter) per academic session
- FR-HPC-007.2: Fields: academic_session_id, student_id, subject_id, competency_id, hpc_ability_parameter_id, hpc_performance_descriptor_id, evidence_type (FK sys_dropdown), evidence_id, remarks, assessed_by, assessed_at
- FR-HPC-007.3: CRUD via `StudentHpcEvaluationController` (353 lines)
- FR-HPC-007.4: Auto-feed into HPC report fields via `HpcDataMappingService::mapEvaluationToReport()` when teacher opens the HPC form for a student

**RBS Reference:** F.I3.1 — Marks Entry; F.I5.1 — Grade Calculation

**Current Status:** CRUD done. `HpcDataMappingService` feeds evaluation data into `$savedValues` when form opens. Direct DB linkage to report output is partial — service exists but mapping completeness is ~40%.

---

### FR-HPC-008 — Teacher Data Entry (HPC Form)

**Description:** The system shall provide a multi-page, tabbed web form where class teachers fill in all teacher-owned sections of the HPC report card for each student.

**Sub-requirements:**
- FR-HPC-008.1: Page-by-page tabbed navigation, driven entirely by `hpc_template_parts` data
- FR-HPC-008.2: Support all 7 input types: Descriptor (radio/select), Numeric, Grade, Text, Boolean/Checkbox, Image upload, Json
- FR-HPC-008.3: Pre-fill with existing saved values on form load (from `hpc_report_items` via `HpcReportService::getSavedValues()`)
- FR-HPC-008.4: Auto-feed from `hpc_student_evaluation` via `HpcDataMappingService::mapEvaluationToReport()`
- FR-HPC-008.5: Auto-feed LMS data (exam scores, quiz results, homework completion) via `HpcLmsIntegrationService::getAllLmsData()`
- FR-HPC-008.6: Auto-feed NCrF credit points via `HpcCreditCalculatorService::calculateCredits()`
- FR-HPC-008.7: Attendance data auto-aggregated from `std_student_attendance` using 2 queries (not 24) with April–March academic year grouping
- FR-HPC-008.8: Save draft on POST /hpc/form/store; status defaults to 'draft'
- FR-HPC-008.9: 4 separate Blade form views: `first_form`, `second_form`, `third_form`, `fourth_form`, selected by template_id
- FR-HPC-008.10: File upload support via Spatie MediaLibrary (`hpc_report_files` collection on HpcReport model)

**Route:** `GET /hpc/hpc-form/{student_id?}` → `HpcController::hpc_form()`
**Store Route:** `POST /hpc/form/store` → `HpcController::formStore()`

**Current Status:** Done — Core form working. The `formStore()` method handles all 8+ field patterns documented in a mapping table within the code.

---

### FR-HPC-009 — Student Self-Assessment Portal

**Description:** The system shall provide an authenticated student-facing dashboard and form where students fill in sections of the HPC report designated for self-reflection.

**Sub-requirements:**
- FR-HPC-009.1: Student dashboard — list pending HPC reports needing student input, with progress percentage
- FR-HPC-009.2: Student form — shows only student-owned pages (filtered by `HpcSectionRoleService::filterPayloadByRole(..., 'student')`)
- FR-HPC-009.3: Prevent student from submitting non-student fields; log warnings on unauthorized field attempt
- FR-HPC-009.4: Progress tracking via `StudentHpcFormService::updateProgress()` per page
- FR-HPC-009.5: Final submission via `POST /hpc/student/submit/{report_id}` marks `hpc_reports.student_sections_complete = true`
- FR-HPC-009.6: `student_form_submissions` table tracks per-page progress for student submissions
- FR-HPC-009.7: Goals & Aspirations wizard for Template 4 via `StudentGoalsController`

**Routes:**
- `GET /hpc/student/dashboard` — dashboard
- `GET /hpc/student/form/{report_id}` — form view
- `POST /hpc/student/form/{report_id}` — save progress
- `POST /hpc/student/submit/{report_id}` — final submission

**Gate:** `tenant.hpc-student.view`, `tenant.hpc-student.submit`

**Current Status:** Controllers and services done (`StudentHpcFormController`, `StudentHpcFormService`). Blade views not confirmed as complete. Student must be authenticated and linked via `Student::where('user_id', $user->id)`.

---

### FR-HPC-010 — Parent Input Collection

**Description:** The system shall allow teachers to generate token-based links for guardians. Guardians access a public form via the token to fill parent-owned sections, without requiring system login.

**Sub-requirements:**
- FR-HPC-010.1: Teacher generates parent link: `POST /hpc/teacher/generate-parent-link/{report_id}` — creates `parent_form_tokens` record, returns URL valid for 7 days
- FR-HPC-010.2: `hpc_parent_form_tokens` (model: `ParentFormToken`) — stores report_id, student_id, guardian_id, token (UUID), expires_at, completed_at
- FR-HPC-010.3: Parent form accessible at `GET /hpc/parent/form/{token}` (no auth middleware) — validates token, shows expired/thank-you views on invalid/completed token
- FR-HPC-010.4: Parent submits data via `POST /hpc/parent/form/{token}` — filtered through `HpcSectionRoleService::filterPayloadByRole(..., 'parent')` before saving
- FR-HPC-010.5: Final submission marks `hpc_reports.parent_sections_complete = true`
- FR-HPC-010.6: Parent dashboard at `GET /hpc/parent/dashboard/{token}` — shows report status, comments
- FR-HPC-010.7: Bidirectional comment system — parent posts comments; teacher replies; comments stored in `hpc_report_comments`
- FR-HPC-010.8: Teacher checks completion status: `GET /hpc/teacher/parent-status/{report_id}`

**Current Status:** `ParentHpcFormController` (303 lines) and `ParentHpcFormService` done. Parent portal routes defined outside auth middleware. Blade views (parent.form, parent.dashboard, parent.expired, parent.thank-you) not confirmed as complete.

---

### FR-HPC-011 — Peer Assessment Workflow

**Description:** The system shall allow teachers to assign classmates as peer reviewers. Students fill peer-evaluation sections for their assigned peers.

**Sub-requirements:**
- FR-HPC-011.1: Auto-assignment: `POST /hpc/teacher/assign-peers/{report_id}` — uses `PeerAssignmentService::autoAssignPeers()` with shuffled, random peer selection
  - Template 2: 2 peers per student (no cycles)
  - Templates 3 & 4: 1 peer per activity cycle (9 cycles for T3, 8 for T4)
- FR-HPC-011.2: `hpc_peer_assignments` (model: `PeerAssignment`) — report_id, student_id (subject), peer_student_id (reviewer), template_id, cycle_number, peer_number, status (pending/in_progress/completed), assigned_by
- FR-HPC-011.3: `hpc_peer_responses` (model: `PeerResponse`) — stores individual field values from peer review
- FR-HPC-011.4: Peer reviewer form: `GET /hpc/student/peer-review/{assignment_id}` — shows only peer-owned pages via `PeerAssignmentService::getPeerPages()`
- FR-HPC-011.5: Saves responses via `PeerAssignmentService::saveResponses()`, marks complete via `completeReview()`
- FR-HPC-011.6: Completion matrix: `GET /hpc/teacher/peer-status/{report_id}` — overview of all peer review statuses in a class

**Current Status:** `PeerHpcFormController` (171 lines) and `PeerAssignmentService` (275 lines) done. Views (`student.peer-review`) not confirmed as complete.

---

### FR-HPC-012 — PDF Report Generation

**Description:** The system shall generate multi-page PDF report cards for individual students or in bulk, using DomPDF v3.1 with 4 separate Blade templates.

**Sub-requirements:**
- FR-HPC-012.1: Single student PDF: `GET /hpc/hpc-single/{student_id?}` → `generateSingleStudentPdf()`
- FR-HPC-012.2: Bulk PDF generation: `POST /hpc/generate-report` → `generateReportPdf()` — processes multiple students, collects generated PDFs
- FR-HPC-012.3: Bulk ZIP export: Generated PDFs are archived into a ZIP file stored at `storage/app/public/hpc-reports/zip/`
- FR-HPC-012.4: ZIP download: `GET /hpc/download-zip/{filename}` — sanitizes filename, serves with `deleteFileAfterSend(true)`
- FR-HPC-012.5: Template selection based on student's class ordinal, resolved by `HpcReportService::resolveTemplateId()`
- FR-HPC-012.6: PDF content fed from `HpcReportService::getSavedValues()` via `$savedValues` and `$savedTableData` variables
- FR-HPC-012.7: Attendance data re-computed at PDF generation time from `std_student_attendance`
- FR-HPC-012.8: PDF view page (web, not PDF): `GET /hpc/hpc-view/{student_id?}` — `viewPdfPage()` — supports both encrypted (public) and plain (authenticated) student_id

**Current Status:** Done — DomPDF integration complete. 4 Blade view templates implemented. ZIP export working.

---

### FR-HPC-013 — Approval Workflow

**Description:** The system shall enforce a linear approval state machine on HPC reports from initial draft through final publishing.

**Workflow States:**
```
draft → submitted → under_review → final → published → archived
                  ↘ (send-back) ↙
```

**State Constants (HpcReport model):**
- `STATUS_DRAFT = 'draft'`
- `STATUS_SUBMITTED = 'submitted'`
- `STATUS_UNDER_REVIEW = 'under_review'`
- `STATUS_FINAL = 'final'`
- `STATUS_PUBLISHED = 'published'`
- `STATUS_ARCHIVED = 'archived'`

**Sub-requirements:**
- FR-HPC-013.1: Teacher submits draft: `POST /hpc/workflow/{report}/submit` → `HpcWorkflowService::submit()` — sets `submitted_at`
- FR-HPC-013.2: Principal starts review: `POST /hpc/workflow/{report}/review` → `startReview()` — requires `tenant.hpc.review` gate
- FR-HPC-013.3: Principal approves: `POST /hpc/workflow/{report}/approve` — sets `reviewed_by`, `reviewed_at`, optional `review_comments`
- FR-HPC-013.4: Principal sends back: `POST /hpc/workflow/{report}/send-back` — requires comment; transitions back to submitted or draft
- FR-HPC-013.5: Admin publishes: `POST /hpc/workflow/{report}/publish` — requires `tenant.hpc.publish` gate; sets `published_at`, `published_by`
- FR-HPC-013.6: Archive: `POST /hpc/workflow/{report}/archive` — final state, no exit
- FR-HPC-013.7: Workflow status: `GET /hpc/workflow/{report}/status` — returns JSON with all timestamp/user audit data and allowed next transitions
- FR-HPC-013.8: Invalid transitions return HTTP 422 with descriptive message

**Current Status:** `HpcWorkflowService` fully implemented (163 lines). `HpcReport::TRANSITIONS` constant drives guard logic. Notifications on state change are TODOs (event hooks stubbed in comments).

---

### FR-HPC-014 — Email Distribution

**Description:** The system shall queue email delivery of report view links (not PDF attachments) to guardians.

**Sub-requirements:**
- FR-HPC-014.1: Single student email: `POST /hpc/send-report-email` — validates student, template, and guardian emails before dispatch
- FR-HPC-014.2: Bulk email: `POST /hpc/send-bulk-report-email` — processes array of student_ids; returns count + per-student warnings
- FR-HPC-014.3: `SendHpcReportEmail` job (queued, ShouldQueue, 3 retries, 120s timeout) — dispatched with studentId, academicTermId, tenantId
- FR-HPC-014.4: Job initializes tenancy context via `tenancy()->initialize($this->tenantId)`, finalizes in finally block
- FR-HPC-014.5: Encrypted URL generation: `Crypt::encryptString($studentId)` → `route('hpc.hpc-form.view', ['student_id' => $encryptedId])`
- FR-HPC-014.6: Access code generated as: `HPC-{studentId}-{guardianId}-{sha1_8chars}` — included in email for phone/SMS fallback
- FR-HPC-014.7: Link expires 30 days after dispatch (displayed in email, not enforced in URL)
- FR-HPC-014.8: Guardian email validation — skips guardians with null or empty email; logs warning
- FR-HPC-014.9: Tenant domain resolution for URL generation: resolves `tenant()->domains()->first()->domain` before calling `URL::forceRootUrl()`

**Architecture Decision D22:** Email sends a signed URL link, NOT a PDF attachment. This avoids attachment size limits, allows the guardian to see the live (possibly updated) report, and keeps storage costs low.

**Current Status:** Done — `SendHpcReportEmail` job, `HpcReportMail` mailable, and single/bulk dispatch endpoints all implemented.

---

### FR-HPC-015 — Student HPC Snapshot

**Description:** The system shall store periodic point-in-time snapshots of student HPC data for trend analysis.

**Sub-requirements:**
- FR-HPC-015.1: `hpc_student_hpc_snapshot` — academic_session_id, student_id, snapshot_json (full report state), generated_at
- FR-HPC-015.2: Unique per (academic_session_id, student_id)

**Current Status:** Table defined in DDL; model `StudentHpcSnapshot` exists (48 lines). No controller or route for snapshot management yet.

---

### FR-HPC-016 — Attendance Management

**Description:** The system shall provide a dedicated attendance configuration interface for HPC, allowing schools to configure working days per month.

**Sub-requirements:**
- FR-HPC-016.1: Attendance config: `GET/POST /hpc/attendance/config` — reads/writes `sys_settings` key `hpc_working_days_per_month` (JSON array of 12 values)
- FR-HPC-016.2: Attendance summary: `GET /hpc/attendance/summary` — aggregate view
- FR-HPC-016.3: `HpcAttendanceService` — `MONTH_ORDER` constant (APR→MAR), `REASON_CATEGORIES` (medical, family, weather, holiday), `getWorkingDaysPerMonth()` with DB fallback
- FR-HPC-016.4: Absence reason categorization via keyword matching

**Current Status:** `HpcAttendanceController` and `HpcAttendanceService` (211 lines) implemented.

---

### FR-HPC-017 — NCrF Credit Configuration

**Description:** The system shall allow schools to configure credit points per grade level and subject domain, aligned with the National Credit Framework.

**Sub-requirements:**
- FR-HPC-017.1: `GET /hpc/credit-config/` — view current configuration
- FR-HPC-017.2: `POST /hpc/credit-config/` — save configuration
- FR-HPC-017.3: `GET /hpc/credit-config/calculate` — calculate credits for a student
- FR-HPC-017.4: `hpc_credit_config` table — stores per-grade credit weights
- FR-HPC-017.5: Default NCrF levels: BV1=0.05, BV2=0.1 ... Gr12=4.5
- FR-HPC-017.6: `HpcCreditCalculatorService::calculateCredits()` → `mapToFormFields()` auto-fills credit pages on form load

**Current Status:** `HpcCreditConfigController` and `HpcCreditCalculatorService` (227 lines) implemented.

---

### FR-HPC-018 — Activity Assessment View

**Description:** Consolidated view showing all actor contributions (teacher, student, peer) for a single report's activity assessment sections.

**Sub-requirements:**
- FR-HPC-018.1: `GET /hpc/activity-assessment/{report_id}` → `HpcActivityAssessmentController::index()`
- FR-HPC-018.2: Shows completion status per actor type

**Current Status:** `HpcActivityAssessmentController` exists; implementation depth not confirmed.

---

## 5. Data Model — All `hpc_*` Tables

### 5.1 Template Definition Tables

#### `hpc_templates`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| code | VARCHAR(50) NOT NULL | Template code (e.g., HPC-FOUND, HPC-PREP) |
| version | TINYINT UNSIGNED DEFAULT 1 | |
| title | VARCHAR(255) NOT NULL | |
| description | VARCHAR(512) NULL | |
| applicable_to_grade | JSON NULL | Array of grade codes (BV1, Gr1, Gr2 ... Gr12) |
| is_active | TINYINT(1) DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | Soft delete |

UNIQUE: `(code, version)`

#### `hpc_template_parts`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| template_id | INT UNSIGNED NOT NULL | FK → hpc_templates |
| code | VARCHAR(50) NOT NULL | |
| description | VARCHAR(512) NULL | |
| help_file | VARCHAR(255) NULL | URL to help doc for this page |
| display_order | TINYINT UNSIGNED | |
| page_no | TINYINT UNSIGNED NOT NULL | Page number in template |
| display_page_number | TINYINT(1) DEFAULT 1 | |
| has_items | TINYINT(1) DEFAULT 1 | 1=use hpc_template_parts_items; 0=section container only |
| is_active | TINYINT(1) DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | Soft delete |

UNIQUE: `(template_id, code)`, `(template_id, page_no)`

#### `hpc_template_parts_items`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| part_id | INT UNSIGNED NOT NULL | FK → hpc_template_parts |
| ordinal | TINYINT UNSIGNED | |
| html_object_name | VARCHAR(50) NOT NULL | HTML field name |
| level_display | VARCHAR(150) NOT NULL | Label on screen |
| level_print | VARCHAR(150) NOT NULL | Label on PDF |
| visible | TINYINT(1) DEFAULT 1 | |
| print | TINYINT(1) DEFAULT 1 | |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(part_id, ordinal)`

#### `hpc_template_sections`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| template_id | INT UNSIGNED NOT NULL | FK → hpc_templates |
| part_id | INT UNSIGNED NOT NULL | FK → hpc_template_parts |
| code | VARCHAR(50) NOT NULL | Used for special handling (e.g., 'ATTENDANCE') |
| description | VARCHAR(512) NULL | |
| display_order | TINYINT UNSIGNED | |
| has_items | TINYINT(1) DEFAULT 1 | |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(part_id, code)`, `(part_id, display_order)`

#### `hpc_template_section_items`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| section_id | INT UNSIGNED NOT NULL | FK → hpc_template_sections |
| html_object_name | VARCHAR(50) NOT NULL | |
| ordinal | TINYINT UNSIGNED | |
| level_display | VARCHAR(150) NOT NULL | |
| level_print | VARCHAR(150) NOT NULL | |
| section_type | ENUM('Text','Image','Table') | |
| visible, print, is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(section_id, ordinal)`
Note: If `section_type = 'Table'`, only `hpc_template_section_table` is used.

#### `hpc_template_section_table`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| section_id | INT UNSIGNED NOT NULL | FK → hpc_template_sections |
| section_item_id | INT UNSIGNED NOT NULL | FK → hpc_template_section_items |
| html_object_name | VARCHAR(50) NOT NULL | |
| row_id | TINYINT UNSIGNED NOT NULL | |
| column_id | TINYINT UNSIGNED NOT NULL | |
| value | VARCHAR(255) NOT NULL | |
| visible, print, is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(section_id, row_id, column_id)`

#### `hpc_template_rubrics`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| template_id | INT UNSIGNED NOT NULL | FK → hpc_templates |
| part_id | INT UNSIGNED NOT NULL | FK → hpc_template_parts |
| section_id | INT UNSIGNED NULL | FK → hpc_template_sections |
| display_order | SMALLINT UNSIGNED | |
| code | VARCHAR(50) NULL | |
| description | VARCHAR(512) NULL | |
| mandatory | TINYINT(1) DEFAULT 0 | |
| visible, print, is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(section_id, display_order)`

#### `hpc_template_rubric_items`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| rubric_id | INT UNSIGNED NOT NULL | FK → hpc_template_rubrics |
| html_object_name | VARCHAR(50) NOT NULL | Unique field identifier |
| ordinal | TINYINT UNSIGNED | |
| input_required | TINYINT(1) DEFAULT 1 | |
| input_type | ENUM | 'Descriptor', 'Numeric', 'Grade', 'Text', 'Boolean', 'Image', 'Json' |
| output_type | ENUM | Same options as input_type |
| input_level | VARCHAR(255) NOT NULL | Display label (e.g., "Excellent") |
| output_level | VARCHAR(255) NOT NULL | PDF print label |
| input_level_numeric | INT UNSIGNED NULL | Numeric equivalent |
| output_level_numeric | INT UNSIGNED NULL | |
| display_input_label | TINYINT(1) DEFAULT 0 | |
| print_output_label | TINYINT(1) DEFAULT 0 | |
| weight | DECIMAL(8,3) NULL | Rubric weightage |
| description | VARCHAR(255) NULL | |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(rubric_id, input_level)`

---

### 5.2 Report Storage Tables

#### `hpc_reports`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| academic_session_id | INT UNSIGNED NOT NULL | FK → std_student_academic_sessions |
| term_id | INT UNSIGNED NOT NULL | FK → sch_academic_term |
| student_id | INT UNSIGNED NOT NULL | FK → std_students |
| class_id | INT UNSIGNED NOT NULL | FK → sch_classes |
| section_id | INT UNSIGNED NOT NULL | FK → sch_sections |
| template_id | INT UNSIGNED NOT NULL | FK → hpc_templates |
| prepared_by | INT UNSIGNED NULL | FK → sys_users (teacher) |
| report_date | DATE NOT NULL | |
| status | ENUM | 'draft', 'submitted', 'under_review', 'final', 'published', 'archived' |
| submitted_at | DATETIME NULL | |
| reviewed_by | INT UNSIGNED NULL | FK → sys_users (principal) |
| reviewed_at | DATETIME NULL | |
| review_comments | TEXT NULL | |
| published_by | INT UNSIGNED NULL | FK → sys_users |
| published_at | DATETIME NULL | |
| student_sections_complete | BOOLEAN DEFAULT 0 | |
| parent_sections_complete | BOOLEAN DEFAULT 0 | |
| created_by, created_at, updated_at, deleted_at | | |

UNIQUE: `(academic_session_id, term_id, student_id)`
Note: Uses Spatie MediaLibrary (`hpc_report_files` collection).

#### `hpc_report_items`
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT AUTO_INCREMENT PK | |
| report_id | INT UNSIGNED NOT NULL | FK → hpc_reports |
| template_id | INT UNSIGNED NOT NULL | FK → hpc_templates |
| rubric_id | INT UNSIGNED NOT NULL | FK → hpc_template_rubrics |
| rubric_item_id | INT UNSIGNED NULL | FK → hpc_template_rubric_items |
| html_object_name | VARCHAR(50) | Field identifier (denormalized from rubric_item) |
| in_numeric_value | DECIMAL(10,3) NULL | For Numeric input type |
| in_text_value | VARCHAR(512) NULL | For Text, tel, email, date, pincode |
| in_boolean_value | TINYINT(1) NULL | For Boolean, checkbox, interest_*, resources_* |
| in_selected_value | VARCHAR(100) NULL | For Descriptor (yes/sometimes/no) and Grade |
| in_image_path | VARCHAR(255) NULL | Image URL |
| in_filename | VARCHAR(100) NULL | Original filename |
| in_filepath | VARCHAR(255) NULL | Storage path |
| in_json_value | JSON NULL | JSON arrays, curricular goals |
| out_numeric_value through out_json_value | | Mirror columns for output |
| remark | TEXT NULL | For textarea, observational notes, writeup_* |
| assessed_by | INT UNSIGNED NULL | FK → sys_users |
| assessed_at | TIMESTAMP NULL | |
| created_at, updated_at, deleted_at | | |

**Column-to-input-type mapping (HpcReportService):**
- `in_numeric_value` ← number, integer, decimal, float, percentage, phone
- `in_text_value` ← text, tel, email, date, pincode, udise, any (max 512)
- `in_boolean_value` ← boolean, checkbox, interest_*, resources_*, grade_*
- `in_selected_value` ← descriptor, grade value (max 100)
- `in_image_path` ← image URL
- `in_filename` / `in_filepath` ← file upload
- `in_json_value` ← json, curricular_goals, strengths[], barriers[]
- `remark` ← textarea, observational_notes, writeup_*, comments

#### `hpc_report_table`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| report_id | INT UNSIGNED NOT NULL | FK → hpc_reports |
| section_id | INT UNSIGNED NOT NULL | FK → hpc_template_sections |
| row_id | TINYINT UNSIGNED | Grid row |
| column_id | TINYINT UNSIGNED | Grid column |
| value | VARCHAR(255) NOT NULL | Cell value |
| visible, print, is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(report_id, section_id, row_id, column_id)`

#### `hpc_report_comments`
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| report_id | INT UNSIGNED NOT NULL | FK → hpc_reports |
| parent_token_id | INT UNSIGNED NULL | FK → hpc_parent_form_tokens (if from parent) |
| user_id | INT UNSIGNED NULL | FK → sys_users (if from teacher) |
| author_type | ENUM | 'parent', 'teacher' |
| message | TEXT NOT NULL | |
| is_read | BOOLEAN DEFAULT 0 | |
| is_active, created_at, updated_at, deleted_at | | |

---

### 5.3 Data Collection & Configuration Tables

#### `hpc_circular_goals`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| code | VARCHAR(50) NOT NULL | UNIQUE |
| name | VARCHAR(150) NOT NULL | |
| class_id | INT UNSIGNED NOT NULL | FK → sch_classes |
| description | TEXT | |
| nep_reference | VARCHAR(100) | |
| is_active, created_at, updated_at, deleted_at | | |

#### `hpc_circular_goal_competency_jnt`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| circular_goal_id | INT UNSIGNED NOT NULL | FK → hpc_circular_goals |
| competency_id | INT UNSIGNED NOT NULL | FK → slb_competencies |
| is_primary | TINYINT(1) DEFAULT 0 | |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(circular_goal_id, competency_id)`

#### `hpc_learning_outcomes`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| code | VARCHAR(50) NOT NULL | UNIQUE |
| description | VARCHAR(255) NOT NULL | |
| domain | INT UNSIGNED NOT NULL | FK → sys_dropdown (COGNITIVE / AFFECTIVE / PSYCHOMOTOR) |
| bloom_id | INT UNSIGNED NULL | FK → slb_bloom_taxonomy |
| level | TINYINT UNSIGNED DEFAULT 1 | |
| is_active, created_at, updated_at, deleted_at | | |

#### `hpc_outcome_entity_jnt`
Maps outcomes to subjects, lessons, or topics.
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| outcome_id | INT UNSIGNED NOT NULL | FK → hpc_learning_outcomes |
| class_id | INT UNSIGNED NOT NULL | FK → sch_classes |
| entity_type | ENUM | 'SUBJECT', 'LESSON', 'TOPIC' |
| entity_id | INT UNSIGNED NOT NULL | Polymorphic FK |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(outcome_id, entity_type, entity_id)`

#### `hpc_outcome_question_jnt`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| outcome_id | INT UNSIGNED NOT NULL | FK → hpc_learning_outcomes |
| question_id | INT UNSIGNED NOT NULL | FK → qns_questions_bank |
| weightage | DECIMAL(5,2) NULL | |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(outcome_id, question_id)`

#### `hpc_ability_parameters`
Reference table: Awareness / Sensitivity / Creativity
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| code | VARCHAR(20) NOT NULL | UNIQUE (AWARENESS, SENSITIVITY, CREATIVITY) |
| name | VARCHAR(100) NOT NULL | |
| description | VARCHAR(500) NULL | |
| is_active, created_at, updated_at, deleted_at | | |

#### `hpc_performance_descriptors`
Reference table: Beginner / Proficient / Advanced
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| code | VARCHAR(20) NOT NULL | UNIQUE (BEGINNER, PROFICIENT, ADVANCED) |
| ordinal | TINYINT UNSIGNED NOT NULL | |
| description | VARCHAR(500) NULL | |
| is_active, created_at, updated_at, deleted_at | | |

#### `hpc_student_evaluation`
Teacher evaluation of student per subject/competency/parameter.
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| academic_session_id | INT UNSIGNED NOT NULL | FK → std_student_academic_sessions |
| student_id | INT UNSIGNED NOT NULL | FK → std_students |
| subject_id | INT UNSIGNED NOT NULL | FK → sch_subjects |
| competency_id | INT UNSIGNED NOT NULL | FK → slb_competencies |
| hpc_ability_parameter_id | INT UNSIGNED NOT NULL | FK → hpc_ability_parameters |
| hpc_performance_descriptor_id | INT UNSIGNED NOT NULL | FK → hpc_performance_descriptors |
| evidence_type | INT UNSIGNED NOT NULL | FK → sys_dropdown (ACTIVITY / ASSESSMENT / OBSERVATION) |
| evidence_id | INT UNSIGNED NULL | FK → slb_activities (optional) |
| remarks | VARCHAR(500) NULL | |
| assessed_by | INT UNSIGNED NULL | FK → sys_users |
| assessed_at | TIMESTAMP | |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(academic_session_id, student_id, subject_id, competency_id, hpc_ability_parameter_id)`

#### `hpc_learning_activities`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| topic_id | INT UNSIGNED NOT NULL | FK → slb_topics |
| activity_type_id | INT UNSIGNED NOT NULL | FK → hpc_learning_activity_type |
| description | TEXT NOT NULL | |
| expected_outcome | TEXT NULL | |
| is_active, created_at, updated_at, deleted_at | | |

#### `hpc_learning_activity_type`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| code | VARCHAR(30) NOT NULL | UNIQUE (PROJECT, OBSERVATION, FIELD_WORK, GROUP_WORK, ART, SPORT, DISCUSSION) |
| name | VARCHAR(100) NOT NULL | |
| description | VARCHAR(255) NOT NULL | |
| is_active, created_at, updated_at, deleted_at | | |

#### `hpc_knowledge_graph_validation`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| topic_id | INT UNSIGNED NOT NULL | FK → slb_topics |
| issue_type | ENUM | NO_COMPETENCY, NO_OUTCOME, NO_WEIGHTAGE, ORPHAN_NODE |
| severity | ENUM | LOW, MEDIUM, HIGH, CRITICAL |
| detected_at | TIMESTAMP | |
| is_resolved | TINYINT(1) DEFAULT 0 | |
| resolved_at | TIMESTAMP NULL | |
| is_active, created_at, updated_at, deleted_at | | |

#### `hpc_topic_equivalency`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| source_topic_id | INT UNSIGNED NOT NULL | FK → slb_topics |
| target_topic_id | INT UNSIGNED NOT NULL | FK → slb_topics |
| equivalency_type | ENUM | FULL, PARTIAL, PREREQUISITE |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(source_topic_id, target_topic_id)`

#### `hpc_syllabus_coverage_snapshot`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| academic_session_id | INT UNSIGNED NOT NULL | FK → slb_academic_sessions |
| class_id | INT UNSIGNED NOT NULL | FK → sch_classes |
| subject_id | INT UNSIGNED NOT NULL | FK → sch_subjects |
| coverage_percentage | DECIMAL(5,2) NOT NULL | |
| snapshot_date | DATE NOT NULL | |
| is_active, created_at, updated_at, deleted_at | | |

---

### 5.4 Multi-Actor Collection Tables (newer additions)

#### `hpc_parent_form_tokens` (model: `ParentFormToken`)
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| report_id | INT UNSIGNED NOT NULL | FK → hpc_reports |
| student_id | INT UNSIGNED NOT NULL | FK → std_students |
| guardian_id | INT UNSIGNED NULL | FK → std_guardians (optional) |
| token | VARCHAR(100) NOT NULL | UUID token for URL |
| expires_at | DATETIME NOT NULL | 7 days from creation |
| completed_at | DATETIME NULL | Set when parent submits final |
| created_by | INT UNSIGNED NULL | Teacher who generated |
| is_active, created_at, updated_at | | |

#### `hpc_peer_assignments` (model: `PeerAssignment`)
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| report_id | INT UNSIGNED NOT NULL | FK → hpc_reports |
| student_id | INT UNSIGNED NOT NULL | Subject of peer review |
| peer_student_id | INT UNSIGNED NOT NULL | Reviewer |
| template_id | INT NOT NULL | 1–4 |
| cycle_number | INT NULL | NULL for T2; 1–9 for T3; 1–8 for T4 |
| peer_number | INT NULL | For T2 (up to 2 peers) |
| status | ENUM | pending, in_progress, completed |
| assigned_by | INT UNSIGNED | Teacher user ID |
| created_by, is_active, created_at, updated_at | | |

UNIQUE: `(report_id, peer_student_id, cycle_number, peer_number)`

#### `hpc_peer_responses` (model: `PeerResponse`)
Stores individual field responses from peer reviewers.
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| assignment_id | INT UNSIGNED NOT NULL | FK → hpc_peer_assignments |
| html_object_name | VARCHAR(50) NOT NULL | Field name |
| value | TEXT | Field value |
| created_at, updated_at | | |

#### `student_form_submissions` (model: `StudentFormSubmission`)
Tracks student's progress through HPC form pages.
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| report_id | INT UNSIGNED NOT NULL | FK → hpc_reports |
| student_id | INT UNSIGNED NOT NULL | FK → std_students |
| page_id | INT NOT NULL | Template page number |
| fields_filled | INT DEFAULT 0 | Count of fields submitted for this page |
| submitted_at | DATETIME NULL | |
| is_active, created_at, updated_at | | |

#### `hpc_credit_config` (model: `HpcCreditConfig`)
NCrF credit configuration per school.
| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT PK | |
| grade_code | VARCHAR(10) NOT NULL | BV1, BV2, Gr1 ... Gr12 |
| credit_value | DECIMAL(5,2) NOT NULL | Default from NCrF standard |
| is_active, created_at, updated_at | | |

#### `hpc_student_hpc_snapshot` (model: `StudentHpcSnapshot`)
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| academic_session_id | INT UNSIGNED NOT NULL | FK → std_student_academic_sessions |
| student_id | INT UNSIGNED NOT NULL | FK → std_students |
| snapshot_json | JSON NOT NULL | Full serialized report state |
| generated_at | TIMESTAMP | |
| is_active, created_at, updated_at, deleted_at | | |

UNIQUE: `(academic_session_id, student_id)`

#### `hpc_curriculum_change_request`
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED AUTO_INCREMENT PK | |
| entity_type | ENUM | SUBJECT, LESSON, TOPIC, COMPETENCY |
| entity_id | INT UNSIGNED NOT NULL | |
| change_type | ENUM | ADD, UPDATE, DELETE |
| change_summary | VARCHAR(500) | |
| impact_analysis | JSON | |
| status | ENUM DEFAULT 'DRAFT' | DRAFT, SUBMITTED, APPROVED, REJECTED |
| requested_by | INT UNSIGNED | FK → sys_users |
| requested_at | TIMESTAMP | |
| is_active, created_at, updated_at, deleted_at | | |

Note: Model and controller for this table are not yet implemented.

---

## 6. Controllers & Services Inventory

### 6.1 Controllers (22 total)

| Controller | Lines | Purpose | Status |
|------------|-------|---------|--------|
| `HpcController` | 2,610 | God controller: index, form, formStore, PDF gen, email, workflow | Active (needs refactor) |
| `StudentHpcFormController` | 233 | Student self-assessment portal | Done |
| `ParentHpcFormController` | 303 | Parent token-based form + comments | Done |
| `PeerHpcFormController` | 171 | Peer assignment + review form | Done |
| `StudentHpcEvaluationController` | 353 | Teacher evaluates student per subject | Done |
| `LearningOutcomesController` | 304 | CRUD for learning outcomes | Done |
| `LearningActivitiesController` | 263 | CRUD for learning activities | Done |
| `CircularGoalsController` | 283 | CRUD for NEP circular goals | Done |
| `HpcParametersController` | 235 | CRUD for ability parameters | Done |
| `HpcPerformanceDescriptorController` | 243 | CRUD for performance descriptors | Done |
| `HpcTemplatesController` | 162 | CRUD for templates | Done |
| `HpcTemplatePartsController` | 174 | CRUD for template pages | Done |
| `HpcTemplateSectionsController` | 220 | CRUD for template sections | Done |
| `HpcTemplateRubricsController` | 217 | CRUD for rubrics | Done |
| `HpcTemplatePartsController` | 174 | CRUD for template parts | Done |
| `KnowledgeGraphValidationController` | ~150 | CRUD for knowledge graph issues | Done |
| `TopicEquivalencyController` | 296 | CRUD for topic equivalency | Done |
| `SyllabusCoverageSnapshotController` | 275 | CRUD for coverage snapshots | Done |
| `QuestionMappingController` | 195 | CRUD for outcome-question mapping | Done |
| `StudentGoalsController` | 205 | Goals & aspirations wizard (T4) | Done |
| `HpcCreditConfigController` | ~100 | NCrF credit configuration | Done |
| `HpcAttendanceController` | ~120 | Attendance configuration view | Done |
| `HpcActivityAssessmentController` | ~80 | Multi-actor activity view | Partial |

### 6.2 Services (10 total)

| Service | Lines | Purpose |
|---------|-------|---------|
| `HpcReportService` | 870 | Core save/load pipeline; getSavedValues(); saveReport(); resolveTemplateId() |
| `PeerAssignmentService` | 275 | Auto-assign peers; save/complete peer responses; completion matrix |
| `HpcLmsIntegrationService` | 234 | Auto-feed homework/exam/quiz data into report fields |
| `HpcCreditCalculatorService` | 227 | NCrF credit calculation and form field mapping |
| `HpcAttendanceService` | 211 | Working days config; reason categorization; month grouping |
| `HpcWorkflowService` | 163 | State machine: submit/review/approve/sendBack/publish/archive |
| `StudentHpcFormService` | 167 | Student page filtering; progress tracking; markComplete |
| `HpcSectionRoleService` | ~150 | Role-based field filtering (teacher/student/parent/peer) |
| `HpcDataMappingService` | ~130 | Map hpc_student_evaluation data to report form fields |
| `ParentHpcFormService` | ~120 | Token generation/validation; parent response storage; completion |

### 6.3 Models (32 total)

| Model | Table | Key Relations |
|-------|-------|--------------|
| `HpcReport` | hpc_reports | student, template, academicSession, term, class, section, reportItems, reportTables; Spatie MediaLibrary |
| `HpcReportItem` | hpc_report_items | report, rubric, rubricItem |
| `HpcReportTable` | hpc_report_table | report, section |
| `HpcReportComment` | hpc_report_comments | report, parentToken |
| `HpcTemplates` | hpc_templates | parts, sections, rubrics |
| `HpcTemplateParts` | hpc_template_parts | template, sections, items |
| `HpcTemplateSections` | hpc_template_sections | part, rubrics, items |
| `HpcTemplateRubrics` | hpc_template_rubrics | template, part, section, items |
| `HpcTemplateRubricItems` | hpc_template_rubric_items | rubric |
| `HpcTemplateSectionItems` | hpc_template_section_items | section |
| `HpcTemplatePartsItems` | hpc_template_parts_items | part |
| `HpcTemplateSectionTable` | hpc_template_section_table | section, sectionItem |
| `HpcParameters` | hpc_ability_parameters | |
| `HpcPerformanceDescriptor` | hpc_performance_descriptors | |
| `HpcLevels` | hpc_levels (legacy?) | |
| `HpcCreditConfig` | hpc_credit_config | |
| `CircularGoals` | hpc_circular_goals | class, competencies (via junction) |
| `CircularGoalCompetencyJnt` | hpc_circular_goal_competency_jnt | |
| `LearningOutcomes` | hpc_learning_outcomes | bloom, entities, questions |
| `OutcomesEntityJnt` | hpc_outcome_entity_jnt | |
| `OutcomesQuestionJnt` | hpc_outcome_question_jnt | |
| `LearningActivities` | hpc_learning_activities | topic, activityType |
| `LearningActivityType` | hpc_learning_activity_type | |
| `StudentHpcEvaluation` | hpc_student_evaluation | student, subject, competency, parameter, descriptor |
| `KnowledgeGraphValidation` | hpc_knowledge_graph_validation | |
| `TopicEquivalency` | hpc_topic_equivalency | |
| `SyllabusCoverageSnapshot` | hpc_syllabus_coverage_snapshot | |
| `ParentFormToken` | hpc_parent_form_tokens | report, student, guardian |
| `PeerAssignment` | hpc_peer_assignments | report, student, peer, responses |
| `PeerResponse` | hpc_peer_responses | assignment |
| `StudentFormSubmission` | student_form_submissions | report, student |
| `StudentHpcSnapshot` | hpc_student_hpc_snapshot | |

### 6.4 Jobs & Mail

| Class | Purpose |
|-------|---------|
| `SendHpcReportEmail` | ShouldQueue; dispatched with (studentId, academicTermId, tenantId); 3 tries, 120s timeout; generates encrypted URL, sends HpcReportMail |
| `HpcReportMail` | Mailable; renders link + access code + expiry date |

---

## 7. Routes Inventory

### 7.1 Public Routes (no authentication)

| Method | URI | Controller@Method | Name |
|--------|-----|-------------------|------|
| GET | `/hpc/hpc-view/{student_id?}` | `HpcController@viewPdfPage` | `hpc.hpc-form.view` |
| GET | `/hpc/parent/dashboard/{token}` | `ParentHpcFormController@dashboard` | `hpc.parent.dashboard` |
| GET | `/hpc/parent/form/{token}` | `ParentHpcFormController@form` | `hpc.parent.form` |
| POST | `/hpc/parent/form/{token}` | `ParentHpcFormController@save` | `hpc.parent.form.save` |
| POST | `/hpc/parent/comment/{token}` | `ParentHpcFormController@postComment` | `hpc.parent.comment` |

**Security Note:** The `hpc-form.view` route accepts an encrypted student_id via Crypt. Without encryption (plain integer), it requires `tenant.hpc.view` gate. However, the route is defined OUTSIDE the auth middleware group — an unauthenticated request with an encrypted ID will bypass authentication entirely.

### 7.2 Authenticated Routes (auth + verified middleware)

#### Main HPC

| Method | URI | Controller@Method | Name |
|--------|-----|-------------------|------|
| GET | `/hpc/hpc` | `HpcController@index` | `hpc.hpc.index` |
| GET | `/hpc/templates` | `HpcController@hpcTemplates` | `hpc.hpc.templates` |
| GET | `/hpc/download-zip/{filename}` | `HpcController@downloadZip` | `hpc.download.zip` |
| GET | `/hpc/hpc-form/{student_id?}` | `HpcController@hpc_form` | `hpc.hpc-form` |
| GET | `/hpc/hpc-single/{student_id?}` | `HpcController@generateSingleStudentPdf` | `hpc.hpc-form.single` |
| POST | `/hpc/generate-report` | `HpcController@generateReportPdf` | `hpc.generate-report` |
| POST | `/hpc/send-report-email` | `HpcController@sendReportEmail` | `hpc.send-report-email` |
| POST | `/hpc/send-bulk-report-email` | `HpcController@sendBulkReportEmail` | `hpc.send-bulk-report-email` |
| POST | `/hpc/form/store` | `HpcController@formStore` | `hpc.form.store` |

#### Workflow

| Method | URI | Name |
|--------|-----|------|
| GET | `/hpc/workflow/{report}/status` | `hpc.workflow.status` |
| POST | `/hpc/workflow/{report}/submit` | `hpc.workflow.submit` |
| POST | `/hpc/workflow/{report}/review` | `hpc.workflow.review` |
| POST | `/hpc/workflow/{report}/approve` | `hpc.workflow.approve` |
| POST | `/hpc/workflow/{report}/send-back` | `hpc.workflow.send-back` |
| POST | `/hpc/workflow/{report}/publish` | `hpc.workflow.publish` |
| POST | `/hpc/workflow/{report}/archive` | `hpc.workflow.archive` |

#### Student Portal

| Method | URI | Controller@Method |
|--------|-----|-------------------|
| GET | `/hpc/student/dashboard` | `StudentHpcFormController@dashboard` |
| GET | `/hpc/student/form/{report_id}` | `StudentHpcFormController@form` |
| POST | `/hpc/student/form/{report_id}` | `StudentHpcFormController@save` |
| POST | `/hpc/student/submit/{report_id}` | `StudentHpcFormController@submit` |
| GET | `/hpc/student/peer-review/{assignment_id}` | `PeerHpcFormController@form` |
| POST | `/hpc/student/peer-review/{assignment_id}` | `PeerHpcFormController@save` |
| GET | `/hpc/student/goals/{report_id}` | `StudentGoalsController@index` |
| POST | `/hpc/student/goals/{report_id}` | `StudentGoalsController@save` |

#### Teacher Management

| Method | URI | Purpose |
|--------|-----|---------|
| POST | `/hpc/teacher/generate-parent-link/{report_id}` | Generate parent token |
| GET | `/hpc/teacher/parent-status/{report_id}` | Check parent completion |
| POST | `/hpc/teacher/comment/{report_id}` | Reply to parent comment |
| GET | `/hpc/teacher/comments/{report_id}` | View all comments |
| POST | `/hpc/teacher/assign-peers/{report_id}` | Auto-assign peer reviewers |
| GET | `/hpc/teacher/peer-status/{report_id}` | View peer completion matrix |

#### Credit, Attendance, Activity

| Method | URI | Purpose |
|--------|-----|---------|
| GET/POST | `/hpc/credit-config/` | NCrF credit configuration |
| GET | `/hpc/credit-config/calculate` | Calculate student credits |
| GET | `/hpc/activity-assessment/{report_id}` | Multi-actor activity view |
| GET | `/hpc/attendance/` | Attendance summary |
| GET/POST | `/hpc/attendance/config` | Working days configuration |
| GET | `/hpc/attendance/summary` | Attendance summary |

#### CRUD Sub-Modules (each with resource + trash/restore/force-delete/toggle-status)

circular-goals, learning-outcomes, question-mapping, knowledge-graph-validation, topic-equivalency, syllabus-coverage-snapshot, hpc-parameters, hpc-performance-descriptor, student-hpc-evaluation, learning-activities, hpc-templates, hpc-template-parts, hpc-template-sections, hpc-template-rubrics

---

## 8. Form Requests & Validation

### 8.1 Existing FormRequests (14)

| FormRequest | Used By | Key Validation |
|------------|---------|----------------|
| `CircularGoalsRequest` | CircularGoalsController | code, name, class_id |
| `HpcParametersRequest` | HpcParametersController | code, name |
| `HpcPerformanceDescriptorRequest` | HpcPerformanceDescriptorController | code, ordinal |
| `HpcTemplatePartsRequest` | HpcTemplatePartsController | template_id, code, page_no |
| `HpcTemplatesRequest` | HpcTemplatesController | code, version, title |
| `HpcTemplateRubricsRequest` | HpcTemplateRubricsController | template_id, part_id, section_id |
| `HpcTemplateSectionsRequest` | HpcTemplateSectionsController | template_id, part_id, code |
| `KnowledgeGraphValidationRequest` | KnowledgeGraphValidationController | topic_id, issue_type, severity |
| `LearningActivitiesRequest` | LearningActivitiesController | topic_id, activity_type_id, description |
| `LearningOutcomesRequest` | LearningOutcomesController | code, description, domain, bloom_id |
| `QuestionMappingRequest` | QuestionMappingController | outcome_id, question_id |
| `StudentHpcEvaluationRequest` | StudentHpcEvaluationController | student_id, subject_id, competency_id, parameter_id, descriptor_id |
| `SyllabusCoverageSnapshotRequest` | SyllabusCoverageSnapshotController | academic_session_id, class_id, subject_id, coverage_percentage |
| `TopicEquivalencyRequest` | TopicEquivalencyController | source_topic_id, target_topic_id |

### 8.2 Missing FormRequests (9 identified)

The following controller actions use inline `$request->validate()` calls instead of dedicated FormRequest classes:

| Controller | Method | Fields Validated Inline |
|------------|--------|------------------------|
| `HpcController` | `formStore()` | student_id, template_id, academic_session_id, term_id, class_id, section_id |
| `HpcController` | `sendReportEmail()` | student_id, academic_term_id |
| `HpcController` | `sendBulkReportEmail()` | student_ids[], academic_term_id |
| `HpcController` | `approveReport()` | comments (nullable) |
| `HpcController` | `sendBackReport()` | comments (required) |
| `ParentHpcFormController` | `generateParentLink()` | guardian_id (nullable) |
| `ParentHpcFormController` | `postComment()` | message (string, max:1000) |
| `ParentHpcFormController` | `teacherComment()` | message (string, max:1000) |
| `PeerHpcFormController` | `assignPeers()` | class_section_id, template_id |

---

## 9. Workflows

### 9.1 HPC Report Creation Workflow

```
1. Admin/Teacher selects student from index (filter by class/section/term)
   GET /hpc/hpc?class_id=X&section_id=Y

2. Teacher opens HPC form for student
   GET /hpc/hpc-form/{student_id}?template_id=4&tab=page-1
   → HpcController::hpc_form()
   → Load template hierarchy (5 eager-loaded relations)
   → Auto-aggregate attendance (2 DB queries, upsert batch to hpc_template_section_table)
   → Pre-fill from hpc_report_items (getSavedValues)
   → Auto-feed from hpc_student_evaluation (HpcDataMappingService)
   → Auto-feed from LMS (HpcLmsIntegrationService, graceful fallback)
   → Auto-calculate NCrF credits (HpcCreditCalculatorService)
   → Render Blade form view (first_form / second_form / third_form / fourth_form)

3. Teacher fills form page by page (tabbed navigation)
   → Each tab = one page_no from hpc_template_parts

4. Teacher saves draft
   POST /hpc/form/store
   → HpcController::formStore()
   → Validates 6 required fields
   → Loads template with 5 eager-load chains
   → Builds 4 mapping arrays: fieldMapping, globalRubricMapping, tableCellMapping, tableMapping
   → Routes each submitted field to correct storage table and column
   → HpcReportService::saveReport() → hpc_reports (updateOrCreate), hpc_report_items, hpc_report_table
   → Status = 'draft'

5. Teacher submits for review
   POST /hpc/workflow/{report}/submit
   → HpcWorkflowService::submit() → status = 'submitted', submitted_at = now()

6. Principal reviews
   POST /hpc/workflow/{report}/review
   → status = 'under_review', reviewed_by = userId

7a. Principal approves
    POST /hpc/workflow/{report}/approve
    → status = 'final', reviewed_at = now()

7b. Principal sends back (with comment)
    POST /hpc/workflow/{report}/send-back
    → status = 'submitted' (from under_review) or 'draft' (from submitted)

8. Admin publishes
   POST /hpc/workflow/{report}/publish
   → status = 'published', published_at = now(), published_by = userId

9. Admin archives (optional)
   POST /hpc/workflow/{report}/archive
   → status = 'archived' (terminal state)
```

### 9.2 PDF Generation Workflow

```
1. Teacher/Admin selects students for PDF generation
   POST /hpc/generate-report
   Body: { student_ids: [...], template_id: X, academic_term_id: Y }

2. HpcController::generateReportPdf()
   → For each student:
     a. Resolve template from student's class (resolveTemplateId)
     b. Load template hierarchy
     c. Load saved values (getSavedValues)
     d. Re-compute attendance data
     e. Initialize DomPDF instance
     f. Render Blade view to HTML string
     g. DomPDF::loadHtml() → render() → output()
     h. Collect PDF binary

3. Archive into ZIP
   ZipArchive: storage/app/public/hpc-reports/zip/{timestamp}.zip
   Each file named: HPC_{studentName}_{date}.pdf

4. Return JSON response:
   { success: true, zip_url: "...", pdf_urls: [...], message: "N report(s) generated." }

5. Admin downloads ZIP
   GET /hpc/download-zip/{filename}
   → Sanitize filename (alphanumeric + underscore + hyphen + dot only)
   → Stream with deleteFileAfterSend(true)
```

### 9.3 Email Distribution Workflow

```
1. Admin selects student(s) and clicks "Send Email"
   POST /hpc/send-report-email (single) or /hpc/send-bulk-report-email (bulk)

2. Pre-dispatch validation:
   → Verify student exists
   → Verify template mapped for student's class
   → Verify guardians exist with email addresses

3. Dispatch SendHpcReportEmail job (queued)
   Job payload: studentId, academicTermId, tenantId

4. Job executes:
   → tenancy()->initialize($tenantId)   // Re-enter tenant context
   → Load student + guardians with email
   → For each guardian:
     a. Resolve tenant domain
     b. url()->forceRootUrl($rootUrl)
     c. Crypt::encryptString($studentId) → encrypted token
     d. Generate route URL: /hpc/hpc-view/{encryptedStudentId}
     e. Generate access code: HPC-{studentId}-{guardianId}-{sha1_8chars}
     f. Mail::to($guardian->email)->send(new HpcReportMail(...))
   → tenancy()->end() in finally block

5. Guardian receives email with:
   → Report view URL (link, not attachment)
   → Access code for phone/SMS verification fallback
   → Expiry date (30 days from dispatch, display-only)
```

### 9.4 Parent Input Workflow

```
1. Teacher generates parent link
   POST /hpc/teacher/generate-parent-link/{report_id}
   → ParentHpcFormService::generateToken() → hpc_parent_form_tokens record
   → Returns: { url, token, expires_at }

2. Teacher shares link with parent (via WhatsApp / email / printout)

3. Parent opens link
   GET /hpc/parent/form/{token}
   → ParentHpcFormService::validateToken() → null if expired/invalid
   → If null: show hpc::parent.expired view
   → If completed: show hpc::parent.thank-you view
   → Otherwise: show hpc::parent.form with parent-owned pages only
     (filtered by HpcSectionRoleService::filterPayloadByRole(..., 'parent'))

4. Parent fills form (saves progress)
   POST /hpc/parent/form/{token}
   → Validate token
   → Filter payload to parent-owned fields only
   → ParentHpcFormService::saveResponses()

5. Parent submits final
   POST /hpc/parent/form/{token} with submit_final=1
   → ParentHpcFormService::markComplete() → sets completed_at
   → hpc_reports.parent_sections_complete = true
   → Redirect to thank-you page

6. Parent views dashboard (optional)
   GET /hpc/parent/dashboard/{token}
   → Shows report status, teacher comments, whether PDF available

7. Bidirectional comments
   Parent posts: POST /hpc/parent/comment/{token}
   Teacher replies: POST /hpc/teacher/comment/{report_id} (authenticated)
   Teacher views all: GET /hpc/teacher/comments/{report_id}
```

### 9.5 Peer Assessment Workflow

```
1. Teacher assigns peers
   POST /hpc/teacher/assign-peers/{report_id}
   Body: { class_section_id: X, template_id: Y }
   → PeerAssignmentService::autoAssignPeers()
   → Shuffled random assignment (no self-assignment)
   → T2: 2 peers/student; T3/T4: 1 peer/cycle

2. Student (as peer reviewer) sees pending peer reviews on dashboard
   GET /hpc/student/dashboard → includes PeerAssignment records

3. Peer opens form
   GET /hpc/student/peer-review/{assignment_id}
   → Validates assignment.peer_student_id == authenticated student
   → Loads only peer-owned pages via PeerAssignmentService::getPeerPages()

4. Peer saves/submits
   POST /hpc/student/peer-review/{assignment_id}
   → HpcSectionRoleService::filterPayloadByRole(..., 'peer')
   → PeerAssignmentService::saveResponses()
   → On submit_final=true: completeReview() → status='completed'

5. Teacher views completion matrix
   GET /hpc/teacher/peer-status/{report_id}
   → Returns grid: [student_id][cycle_number] → status
```

---

## 10. Integration Points

### 10.1 Modules Consumed by HPC

| Source Module | Data Used | Integration Method |
|--------------|-----------|-------------------|
| StudentProfile (`std_students`) | Student demographics, sibling data, current class/section | Eloquent `Student::with([...])` |
| StudentProfile (`std_student_attendance`) | Monthly presence/absence data for attendance section | Direct query with group-by |
| StudentProfile (`std_guardians`, `std_student_guardian_jnt`) | Guardian emails for report distribution | Eloquent relation |
| SchoolSetup (`sch_classes`, `sch_sections`, `sch_academic_term`) | Class/section context, template mapping by class ordinal | FK lookups |
| SmartTimetable (`sch_academic_term`) | Academic term for report scoping | FK lookup |
| Syllabus (`slb_competencies`, `slb_bloom_taxonomy`, `slb_topics`, `slb_lessons`) | Competency-goal mapping, outcome domain | FK references in DDL |
| QuestionBank (`qns_questions_bank`) | Outcome-to-question linkage | FK via hpc_outcome_question_jnt |
| LMS Exam | Exam scores for HPC performance fields | `HpcLmsIntegrationService` (graceful fallback) |
| LMS Quiz | Quiz results for competency indicators | `HpcLmsIntegrationService` (graceful fallback) |
| LMS Homework | Homework completion for activity tracking | `HpcLmsIntegrationService` (graceful fallback) |

### 10.2 Modules That Consume HPC Data

Currently none — HPC is a terminal reporting module. Analytical Reports module (pending) will consume HPC published data.

### 10.3 System Service Dependencies

| Service | Usage |
|---------|-------|
| DomPDF v3.1 | PDF rendering |
| Spatie MediaLibrary v11 | File uploads in HPC form (hpc_report_files collection) |
| Spatie Permission v6.21 | Gate checks (tenant.hpc.*) |
| stancl/tenancy v3.9 | `tenancy()->initialize()` in SendHpcReportEmail job |
| Laravel Queue | Async email dispatch |
| ZipArchive (PHP built-in) | Bulk PDF export |
| Laravel Crypt | Student ID encryption for public report URL |

---

## 11. PDF Generation Architecture

### 11.1 Template Selection Logic

`HpcReportService::resolveTemplateId($student)`:
- Reads student's class ordinal (grade number)
- Maps ordinal to template: Pre-primary → T1, Gr1-5 → T2, Gr6-8 → T3, Gr9-12 → T4
- Returns null if no template mapped (triggers warning to admin)

### 11.2 DomPDF Configuration

- Paper size: A4 portrait
- DPI: 96
- Unicode support enabled
- Font subsetting enabled
- Remote image loading enabled (for school logo, student photo)

### 11.3 Data Flow to PDF

```
HpcController::renderStudentReportView($studentId)
  ↓
HpcReportService::getSavedValues($reportId)
  ↓ returns:
  $savedValues    = [html_object_name => value]   (from hpc_report_items)
  $savedTableData = [section_id][row_id][col_id]  (from hpc_report_table)
  ↓
Select Blade view: first_form / second_form / third_form / fourth_form
  ↓
Blade renders: @foreach $template->parts as $part → sections → rubrics → items
  → {{ $savedValues[strtolower($item->html_object_name)] ?? '' }}
  ↓
DomPDF::loadHtml($html)->render()->output() → PDF binary
```

### 11.4 PDF File Storage

- Path: `storage/app/public/hpc-reports/{studentName}_{date}.pdf`
- ZIP: `storage/app/public/hpc-reports/zip/{timestamp}.zip`
- Files served via `response()->download(...)->deleteFileAfterSend(true)` (one-time download)

---

## 12. Multi-Actor Data Collection Architecture

### 12.1 Role-Based Field Ownership

`HpcSectionRoleService` controls which sections belong to which actor. Each `hpc_template_sections` or `hpc_template_rubrics` record has a role designation (teacher / student / parent / peer).

`filterPayloadByRole($payload, $templateId, $role)` returns:
- `[$filteredPayload, $rejectedFields]` — only fields owned by the specified role pass through

### 12.2 Token-Based Authentication for Parents

Parents do not have system accounts. Access is via one-time tokens:
- `hpc_parent_form_tokens` stores the token UUID, expiry, and completion status
- `ParentHpcFormService::validateToken()` returns null if expired or not found
- Token valid for 7 days from generation; no hard enforcement on URL (soft expiry)

### 12.3 Student Authentication

Students access their portal via normal Laravel auth (`tenant.hpc-student.view` gate). The system resolves `Student::where('user_id', auth()->user()->id)` to find the linked student record.

### 12.4 Peer Authentication

Peers (classmates) are also authenticated students. `PeerAssignment::where('peer_student_id', $studentId)` validates that the authenticated student is the assigned reviewer.

### 12.5 Field Merge Strategy

All actor contributions (teacher, student, parent, peer) are stored in the same `hpc_report_items` table under the same `report_id`. The `assessed_by` column tracks which user made each entry. This means later entries overwrite earlier ones for the same `html_object_name` — there is no explicit locking to prevent overwrites across actors.

---

## 13. Security & Authorization

### 13.1 Gate Permissions Used

| Gate | Assigned To | Used In |
|------|-------------|---------|
| `tenant.hpc.viewAny` | Teacher+ | index, templates view, email dispatch |
| `tenant.hpc.view` | Teacher+ | hpc_form load, viewPdfPage (authenticated path) |
| `tenant.hpc.create` | Teacher+ | create/store stubs |
| `tenant.hpc.update` | Teacher+ | formStore, workflow submit, generate parent link |
| `tenant.hpc.review` | Principal+ | workflow review/approve/send-back |
| `tenant.hpc.publish` | Admin | workflow publish |
| `tenant.hpc.delete` | Admin | destroy stub |
| `tenant.hpc-student.view` | Student | student dashboard/form/peer-review |
| `tenant.hpc-student.submit` | Student | student form save/submit, peer review save |

### 13.2 Known Security Gaps

**CRITICAL — Public PDF Route Without Proper Auth:**
The route `GET /hpc/hpc-view/{student_id?}` is defined OUTSIDE the auth middleware group. When an encrypted `student_id` is passed, the system sets `$publicAccess = true` and skips the gate check entirely. Any user with a valid encrypted student_id can view the report — Crypt provides security, not authentication. This is intentional for guardian email links but means the URL must remain secret.

**Issue:** The encrypted URL is sent via unencrypted email and stored as `route()` output in logs. If exposed, anyone can view the report.

**Missing Middleware:**
- `EnsureTenantHasModule` middleware is not applied to any HPC routes. A school that hasn't subscribed to HPC can still access all endpoints.

**Workflow Gates Inconsistency:**
- `publishReport()` uses `tenant.hpc.publish`
- `archiveReport()` uses `tenant.hpc.update` (should be `tenant.hpc.publish` or a dedicated `tenant.hpc.archive`)

**Missing CSRF on Parent Public Routes:**
Parent form POST routes are outside auth middleware. Laravel's CSRF middleware (VerifyCsrfToken) should still apply — verify that parent POST routes either use the `web` middleware group (with CSRF) or are explicitly excluded from CSRF.

---

## 14. Known Issues & Technical Debt

### TD-001 — God Controller (CRITICAL)

**File:** `HpcController.php` — 2,610 lines

The controller handles 22+ distinct responsibilities: index, form load, form store, PDF generation (single + bulk), ZIP download, email dispatch (single + bulk), all 7 workflow steps, view PDF page, and private helper methods. This violates the Single Responsibility Principle and makes maintenance, testing, and extension extremely difficult.

**Recommended Refactor:**
- `HpcFormController` — form load + formStore
- `HpcPdfController` — single/bulk PDF generation, ZIP download
- `HpcEmailController` — single/bulk email dispatch
- Workflow methods already separated into `HpcWorkflowService` — add `HpcWorkflowController`
- `HpcIndexController` — index + templates view

### TD-002 — Shared Tabbed Index Causes Multiple Paginated Queries

`hpcTemplates()` method loads 4 separate paginated queries (templates, parts, sections, rubrics) simultaneously to power a tabbed index view. This causes 15+ queries per page load and prevents independent pagination.

**Recommended Fix:** Use AJAX/lazy-load per tab, loading each sub-resource only when its tab is activated.

### TD-003 — Missing EnsureTenantHasModule Middleware

All HPC routes lack `EnsureTenantHasModule` middleware. Schools without HPC subscription have full API access.

**Fix:** Add middleware to the HPC route group:
```php
Route::middleware(['auth', 'verified', 'tenant.module:HPC'])->prefix('hpc')...
```

### TD-004 — Public PDF Route — Encrypted ID Only Defense

The `hpc-form.view` route uses `Crypt::encryptString($studentId)` as the only security layer for guardian access. While Crypt provides tamper-proof encoding, the same URL is:
- Stored in application logs (plaintext)
- Sent via potentially unencrypted email
- Valid indefinitely (no expiry enforcement)

**Recommended Fix:** Implement time-limited signed URLs using `URL::temporarySignedRoute()` instead of Crypt encryption.

### TD-005 — formStore() Lacks FormRequest

The 2,610-line HpcController::formStore() uses an inline `$request->validate()` with only 6 required fields. The actual form submits dozens of dynamic fields (html_object_name values) with no validation beyond existence.

**Fix:** Create `HpcFormStoreRequest` with validation for fixed fields; dynamic fields validate by html_object_name existence in the template.

### TD-006 — No Field-Level Write Locking Across Actors

Multiple actors can write to the same `html_object_name` in `hpc_report_items`. A teacher can overwrite student entries and vice versa. The `assessed_by` column is present but not used for enforcement.

**Fix:** `HpcSectionRoleService` already exists for filtering — extend it to also reject writes to fields owned by other roles.

### TD-007 — LMS Integration Service Has Graceful Fallback Only

`HpcLmsIntegrationService` wraps all DB queries in try/catch and returns empty arrays on failure. While this prevents errors, it means LMS data silently disappears if any table is missing or module inactive.

**Fix:** Add logging for fallback cases; surface to admin when LMS integration fails.

### TD-008 — Workflow Notifications Are Stubs

`HpcWorkflowService` has `// TODO: Trigger event/notification` comments on submit, sendBack, and publish. No actual notifications reach the relevant parties.

**Fix:** Implement `HpcReportSubmitted`, `HpcReportSentBack`, `HpcReportPublished` events with listener-based email/notification dispatch.

### TD-009 — formStore() Duplicate Logic with viewPdfPage()

Attendance aggregation code (querying `std_student_attendance`, grouping by month, keyword-matching absence reasons) is duplicated verbatim in `formStore()` (lines ~345–490) and `renderStudentReportView()` (lines ~2100–2175). The `HpcAttendanceService` class exists but is only partially used for configuration, not for this aggregation.

**Fix:** Move attendance aggregation into `HpcAttendanceService::aggregateForReport($studentId, $templateId)` and call it from both methods.

### TD-010 — Missing Tests for Core Workflows

Current tests (7 unit + 1 feature):
- Unit: `HpcAttendanceServiceTest`, `HpcCreditCalculatorTest`, `HpcDataMappingServiceTest`, `HpcReportServiceTest`, `HpcSectionRoleServiceTest`, `HpcWorkflowServiceTest`
- Feature: `HpcAuthorizationTest` (10 route access tests + 4 parent public route tests)
- Browser: `HpcParametersCrudTest`

Missing critical test coverage:
- No test for `formStore()` field routing logic
- No test for PDF generation correctness
- No test for email job queue behavior
- No test for token expiry in parent workflow
- No test for peer assignment algorithm
- No integration test for multi-actor data collection

---

## 15. Implementation Status & Gap Analysis

### 15.1 Feature Completion by Area

| Feature Area | Completion | Blocking Gap |
|-------------|------------|-------------|
| Template structure (4 templates, data-driven) | 95% | Minor: HpcLevels model appears legacy |
| Report save/load pipeline | 90% | formStore has N+1 potential on bulk ops |
| PDF generation (4 DomPDF templates) | 90% | No page-break control for very long pages |
| Teacher data entry form | 85% | Section role locking not enforced server-side |
| Attendance aggregation | 80% | Working days not configured by default; illness counting heuristic |
| Approval workflow | 80% | Notifications not implemented (TODO stubs only) |
| Email distribution (queued job) | 85% | URL expiry not enforced; logs contain plaintext encrypted IDs |
| CRUD sub-modules (15 screens) | 80% | hpc_curriculum_change_request has no controller |
| LMS auto-feed | 30% | Service gracefully falls back to empty; no feedback to admin |
| NCrF credit calculator | 80% | Config screen exists; auto-feed to form works; edge cases untested |
| Parent input collection | 40% | Service/controller done; Blade views status uncertain |
| Student self-assessment | 35% | Service/controller done; Blade views status uncertain; student auth not integrated with StudentPortal module |
| Peer assessment | 30% | Service/controller done; Blade views status uncertain |
| Knowledge graph / analytics | 20% | Tables and CRUD exist but not connected to report pipeline |
| Student HPC snapshot | 5% | Model only; no controller or generation trigger |
| Security hardening | 30% | Missing tenant module check; public route vulnerabilities; 9 missing FormRequests |
| Test coverage | 25% | Only 8 tests (7 unit + 1 feature); missing integration tests |

### 15.2 RBS Module I Coverage

| RBS Feature | HPC Coverage | Notes |
|------------|-------------|-------|
| I1 — Exam Structure & Scheme | Indirect | Via LMS integration; not primary HPC function |
| I2 — Exam Timetable | None | Separate Exam module |
| I3 — Marks Entry | Partial | hpc_student_evaluation covers holistic marks; raw marks in Exam module |
| I4 — Moderation Workflow | None | HPC approval workflow is different concept |
| I5 — Gradebook Calculation | Partial | NCrF credits; no percentage/GPA calculation |
| I6 — Report Cards & Publishing | Full | Core HPC function; 4 templates, DomPDF, publish workflow |
| I7 — Promotion Rules | None | Separate module |
| I8 — Board Pattern Support | Partial | CBSE-aligned; no ICSE/IB/Cambridge templates |
| I9 — Custom Report Card Designer | None | Templates are code-defined, not drag-and-drop |
| I10 — AI-Based Analytics | None | Planned in Analytical Reports module |

### 15.3 Priority Development Items

**P1 — Critical for production use:**
1. Apply `EnsureTenantHasModule` middleware to all HPC routes
2. Replace Crypt URL with `URL::temporarySignedRoute()` for guardian access (TD-004)
3. Refactor HpcController (2,610 lines) into focused controllers (TD-001)
4. Implement workflow notifications (TD-008)

**P2 — Required for complete multi-actor collection:**
5. Confirm and complete Blade views for student.form, parent.form, student.peer-review
6. Connect student portal to StudentPortal module authentication
7. Implement field-level write locking across actors (TD-006)

**P3 — Quality & completeness:**
8. Extract duplicate attendance aggregation into HpcAttendanceService (TD-009)
9. Create the 9 missing FormRequests (TD-005 + Section 8.2)
10. Add missing tests: formStore routing, PDF output, email job, token expiry
11. Connect hpc_student_evaluation auto-feed to report pages 29-30, 36-37 (GAP-7)
12. Implement `hpc_curriculum_change_request` CRUD controller
13. Add student snapshot trigger on report publish

---

*Document generated from code analysis of:*
- `/Users/bkwork/Herd/prime_ai/Modules/Hpc/` — 22 controllers, 32 models, 10 services, 14 FormRequests
- `/Users/bkwork/Herd/prime_ai/routes/tenant.php` — lines 2683–2918
- `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/63-HPC/DDL/` — 3 DDL files
- `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/63-HPC/Claude_Prompt/2026Mar14_HPC_Gap_Analysis.md`
- RBS: Module I lines 2592–2708
