# HPC — Holistic Progress Card
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** HPC | **Scope:** Tenant | **Table Prefix:** `hpc_`
**Platform:** Laravel 12 + PHP 8.2 + MySQL 8.x | **Package:** nwidart/laravel-modules v12
**Processing Basis:** V1 doc + Deep Gap Analysis (2026-03-22) + DDL scan + code scan

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Roles](#3-stakeholders--roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [API Endpoints & Routes](#6-api-endpoints--routes)
7. [UI Screens](#7-ui-screens)
8. [Business Rules](#8-business-rules)
9. [Workflows](#9-workflows)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Dependencies](#11-dependencies)
12. [Test Scenarios](#12-test-scenarios)
13. [Glossary](#13-glossary)
14. [Suggestions & Refactoring Priorities](#14-suggestions--refactoring-priorities)
15. [Appendices](#15-appendices)
16. [V1 to V2 Delta](#16-v1-to-v2-delta)

---

## 1. Executive Summary

The HPC (Holistic Progress Card) module implements India's NEP 2020 PARAKH-aligned assessment
framework for K-12 schools. It replaces traditional marks-based report cards with a
multi-dimensional holistic progress card capturing academic performance, life skills,
social-emotional development, co-curricular activities, and observations from teachers,
students, parents, and peers.

### 1.1 Current Completion Status

| Dimension | Status | Completeness |
|-----------|--------|-------------|
| Template Structure (4 templates, 138 pages) | ✅ Done | 95% |
| Report Save / Load Pipeline | ✅ Done | 90% |
| PDF Generation (4 DomPDF templates) | ✅ Done | 90% |
| Teacher Data Entry Web Form | ✅ Done | 85% |
| Approval Workflow (state machine) | ✅ Done | 80% |
| Email Distribution (Job + Mail) | ✅ Done | 85% |
| CRUD Sub-Modules (15 sub-screens) | ✅ Done | 80% |
| Unit Tests (6 files, 393 lines) | 🟡 Partial | 30% |
| LMS Auto-Feed Integration | 🟡 Partial | 30% |
| Parent Input Collection (views) | 🟡 Partial | 40% |
| Student Self-Assessment Portal (views) | 🟡 Partial | 35% |
| Peer Assessment Workflow (views) | 🟡 Partial | 30% |
| Role-Based Section Locking | 🟡 Partial | 70% |
| Security / Authorization | 🟡 Partial | 30% |
| **Overall** | | **~59%** |

### 1.2 Critical Issues (Must Fix Before Production)

| ID | Severity | Issue |
|----|----------|-------|
| SEC-HPC-001 | CRITICAL | No `EnsureTenantHasModule` middleware on HPC route group |
| SEC-HPC-002 | HIGH | `hpc-view/{student_id?}` route publicly accessible — no auth |
| GAP-CTRL-001 | HIGH | `HpcController` is a 2,610-line god controller — needs split |
| GAP-FR-001 | HIGH | 9 controller actions missing FormRequest classes |
| GAP-DB-002 | MEDIUM | `hpc_credit_config` table missing from DDL |
| GAP-DB-004 | MEDIUM | `hpc_peer_assignments` and `hpc_parent_form_tokens` missing from DDL |

---

## 2. Module Overview

### 2.1 Purpose

The HPC module generates and manages the Holistic Progress Card — a PARAKH-compliant assessment
report — for every student across four grade bands. It coordinates data entry from four actor
types (teacher, student, parent, peer), enforces an approval workflow, and distributes finalized
reports to guardians via email.

### 2.2 NEP 2020 Grade Band Mapping

| NEP Stage | Grades | Prime-AI Template | Approx Pages | Key Actors |
|-----------|--------|------------------|-------------|------------|
| Foundational | Pre-primary – Grade 2 | Template 1 | ~5 pages | Teacher, Parent |
| Preparatory | Grades 3–5 | Template 2 | ~8 pages | Teacher, Parent, Peer (2) |
| Middle | Grades 6–8 | Template 3 | ~8 pages | Teacher, Student, Parent, Peer |
| Secondary | Grades 9–12 | Template 4 | ~44 pages | Teacher, Student, Parent, Peer |

### 2.3 Data Ownership by Actor

| Actor | Templates | Owns |
|-------|-----------|------|
| Teacher | 1, 2, 3, 4 | Subject assessments, rubric scores, attendance, NCrF credits |
| Student | 3, 4 | Self-reflection, goals, aspirations, time management |
| Parent | 1, 2, 3 | Home observations, feedback questions, support plan |
| Peer | 2, 3, 4 | Peer evaluation cycles (1–9 per template) |
| System | All | Attendance aggregation, static reference data |

### 2.4 Architecture Layers

```
TEMPLATE DEFINITION LAYER
  hpc_templates → hpc_template_parts → hpc_template_sections
  → hpc_template_rubrics → hpc_template_rubric_items
  → hpc_template_section_items → hpc_template_section_table

DATA COLLECTION LAYER
  Teacher:  HpcFormController → HpcReportService
  Student:  StudentHpcFormController → HpcReportItem upsert
  Parent:   ParentHpcFormController → token-based POST
  Peer:     PeerHpcFormController → PeerResponse storage

REPORT STORAGE LAYER
  hpc_reports → hpc_report_items → hpc_report_table

PDF GENERATION LAYER
  HpcReportService → DomPDF v3.1 → 4 Blade view templates
  → ZipArchive (bulk export) → signed-URL email delivery
```

### 2.5 $hpcData Pattern

PDF templates use `$hpcData` populated by `HpcReportService::getSavedValues()`, returning:
- `$savedValues` — array keyed by `html_object_name` (lowercased) → stored values
- `$savedTableData` — array of grid/table cell values

All Blade templates reference fields via `$savedValues['field_name']` — template-agnostic
rendering without hard-coded field lookups.

---

## 3. Stakeholders & Roles

| Role | System Gate | HPC Permissions |
|------|------------|-----------------|
| Class Teacher | `tenant.hpc.view`, `tenant.hpc.create`, `tenant.hpc.update` | Data entry; submit for review; generate PDF; send email |
| Student | `tenant.hpc-student.view`, `tenant.hpc-student.submit` | Fill self-assessment sections (T3, T4); submit goals |
| Parent/Guardian | Token-based (no login) | Fill parent observation sections via token URL |
| Peer (classmate) | `tenant.hpc-student.view` | Fill peer evaluation sections when assigned |
| Principal | `tenant.hpc.review` | Start review; approve; send back to teacher |
| School Admin | `tenant.hpc.publish` | Publish approved reports; archive; bulk email dispatch |
| System | N/A | Attendance aggregation; NCrF credit auto-calculation |

---

## 4. Functional Requirements

### FR-HPC-001 — Template Management ✅

**Description:** The system shall provide CRUD management for 4 HPC template hierarchies, each
consisting of pages (parts), sections, rubrics, and rubric items. Templates are data-driven;
no hardcoded HTML field definitions exist in PHP.

**Sub-requirements:**
- FR-HPC-001.1: Manage `hpc_templates` — code, version, title, applicable_to_grade (JSON), is_active
- FR-HPC-001.2: Manage `hpc_template_parts` (pages) — page_no, display_order, help_file, has_items flag
- FR-HPC-001.3: Manage `hpc_template_sections` — code, display_order, has_items flag; sections belong to parts
- FR-HPC-001.4: Manage `hpc_template_rubrics` — code, mandatory, visible, print flags
- FR-HPC-001.5: Manage `hpc_template_rubric_items` — html_object_name (unique per rubric), input_type
  (Descriptor / Numeric / Grade / Text / Boolean / Image / Json), weight, input/output level labels
- FR-HPC-001.6: Manage `hpc_template_section_items` — html_object_name, section_type (Text/Image/Table)
- FR-HPC-001.7: Manage `hpc_template_section_table` — cell definitions (section_id, row_id, column_id)
- FR-HPC-001.8: Support soft delete, restore, force-delete, toggle-status on all template entities

**Controllers:** `HpcTemplatesController`, `HpcTemplatePartsController`, `HpcTemplateSectionsController`,
`HpcTemplateRubricsController`
**Status:** ✅ Done — all 5 template CRUD controllers implemented with full soft-delete pattern

---

### FR-HPC-002 — HPC Parameter Configuration ✅

**Description:** Manage reference data for rubric scoring — ability parameters (Awareness, Sensitivity,
Creativity) and performance descriptors (Beginner, Proficient, Advanced).

**Sub-requirements:**
- FR-HPC-002.1: `hpc_ability_parameters` — code (AWARENESS/SENSITIVITY/CREATIVITY), name, description
- FR-HPC-002.2: `hpc_performance_descriptors` — code (BEGINNER/PROFICIENT/ADVANCED), ordinal, description
- FR-HPC-002.3: CRUD accessible to Admin role only; toggle-status; soft delete

**Controllers:** `HpcParametersController`, `HpcPerformanceDescriptorController`
**Status:** ✅ Done

---

### FR-HPC-003 — Circular Goals & Competency Mapping ✅

**Description:** Manage NEP curricular goals per class, mapped to syllabus competencies.

**Sub-requirements:**
- FR-HPC-003.1: `hpc_circular_goals` — code, name, class_id (FK sch_classes), nep_reference
- FR-HPC-003.2: `hpc_circular_goal_competency_jnt` — M:N between circular goals and slb_competencies; is_primary flag
- FR-HPC-003.3: Full CRUD with soft delete, restore, force-delete, toggle-status

**Controller:** `CircularGoalsController`
**Status:** ✅ Done

---

### FR-HPC-004 — Learning Outcomes & Question Mapping ✅

**Description:** Manage learning outcomes with Bloom taxonomy classification, entity mappings
(subject/lesson/topic), and question bank linkages.

**Sub-requirements:**
- FR-HPC-004.1: `hpc_learning_outcomes` — code, description, domain (FK sys_dropdown), bloom_id, level
- FR-HPC-004.2: `hpc_outcome_entity_jnt` — outcome mapped to class + entity (Subject/Lesson/Topic polymorphic)
- FR-HPC-004.3: `hpc_outcome_question_jnt` — outcome mapped to question (FK qns_questions_bank) with weightage

**Controllers:** `LearningOutcomesController` (304 lines), `QuestionMappingController` (195 lines)
**Status:** ✅ Done

---

### FR-HPC-005 — Learning Activities ✅

**Description:** Manage learning activities per topic as evidence sources for HPC evaluation.

**Sub-requirements:**
- FR-HPC-005.1: `hpc_learning_activities` — topic_id, activity_type_id, description, expected_outcome
- FR-HPC-005.2: `hpc_learning_activity_type` — code (PROJECT/OBSERVATION/FIELD_WORK/GROUP_WORK/ART/SPORT/DISCUSSION)

**Controller:** `LearningActivitiesController` (263 lines)
**Status:** ✅ Done

---

### FR-HPC-006 — Curriculum Analytics Tools ✅

**Description:** Knowledge graph validation, topic equivalency, and syllabus coverage snapshots
for curriculum integrity.

**Sub-requirements:**
- FR-HPC-006.1: `hpc_knowledge_graph_validation` — topic integrity issues (NO_COMPETENCY/NO_OUTCOME/
  NO_WEIGHTAGE/ORPHAN_NODE), severity, resolved flag
- FR-HPC-006.2: `hpc_topic_equivalency` — cross-syllabus mapping (FULL/PARTIAL/PREREQUISITE between slb_topics)
- FR-HPC-006.3: `hpc_syllabus_coverage_snapshot` — coverage % by academic_session + class + subject + snapshot_date

**Controllers:** `KnowledgeGraphValidationController`, `TopicEquivalencyController`,
`SyllabusCoverageSnapshotController`
**Status:** ✅ Done — standalone analytics stores; not yet connected to HPC report auto-generation

---

### FR-HPC-007 — Student HPC Evaluation (ASC Framework) 🟡

**Description:** Per-student, per-subject evaluation based on NEP's three ability parameters
(Awareness, Sensitivity, Creativity) and three performance descriptors (Beginner, Proficient,
Advanced).

**Sub-requirements:**
- FR-HPC-007.1: `hpc_student_evaluation` — one row per (student, subject, competency, ability_parameter)
  per academic session
- FR-HPC-007.2: Fields: academic_session_id, student_id, subject_id, competency_id,
  hpc_ability_parameter_id, hpc_performance_descriptor_id, evidence_type, evidence_id, remarks,
  assessed_by, assessed_at
- FR-HPC-007.3: CRUD via `StudentHpcEvaluationController` (353 lines)
- FR-HPC-007.4: Auto-feed into HPC report fields via `HpcDataMappingService::mapEvaluationToReport()`
  when teacher opens HPC form for a student

**Controller:** `StudentHpcEvaluationController`
**Status:** 🟡 CRUD done; `HpcDataMappingService` feeds evaluation data but mapping completeness ~40%

---

### FR-HPC-008 — Teacher Data Entry (HPC Form) ✅

**Description:** Multi-page, tabbed web form where class teachers fill in all teacher-owned sections
of the HPC report card for each student.

**Sub-requirements:**
- FR-HPC-008.1: Page-by-page tabbed navigation driven entirely by `hpc_template_parts` data
- FR-HPC-008.2: Support all 7 input types: Descriptor, Numeric, Grade, Text, Boolean/Checkbox,
  Image upload, Json
- FR-HPC-008.3: Pre-fill with existing saved values from `hpc_report_items` via
  `HpcReportService::getSavedValues()`
- FR-HPC-008.4: Auto-feed from `hpc_student_evaluation` via `HpcDataMappingService`
- FR-HPC-008.5: Auto-feed LMS data (exam/quiz/homework) via `HpcLmsIntegrationService::getAllLmsData()`
  with graceful fallback
- FR-HPC-008.6: Auto-feed NCrF credit points via `HpcCreditCalculatorService::calculateCredits()`
- FR-HPC-008.7: Attendance data auto-aggregated from `std_student_attendance` using 2 queries with
  April–March academic year grouping
- FR-HPC-008.8: Save draft on POST `/hpc/form/store`; status defaults to 'draft'
- FR-HPC-008.9: 4 separate Blade form views: `first_form`, `second_form`, `third_form`, `fourth_form`
- FR-HPC-008.10: File upload via Spatie MediaLibrary (`hpc_report_files` collection on HpcReport)

**Route:** `GET /hpc/hpc-form/{student_id?}` → `HpcController::hpc_form()`
**Store:** `POST /hpc/form/store` → `HpcController::formStore()`
**Status:** ✅ Done — core form working; formStore() handles 8+ field patterns

---

### FR-HPC-009 — Student Self-Assessment Portal 🟡

**Description:** Authenticated student dashboard and form for filling self-reflection sections.

**Sub-requirements:**
- FR-HPC-009.1: Student dashboard — list pending reports needing student input with progress %
- FR-HPC-009.2: Student form — shows only student-owned pages filtered by
  `HpcSectionRoleService::filterPayloadByRole(..., 'student')`
- FR-HPC-009.3: Prevent submission of non-student fields; log warnings on unauthorized attempt
- FR-HPC-009.4: Progress tracking via `StudentHpcFormService::updateProgress()` per page
- FR-HPC-009.5: Final submission marks `hpc_reports.student_sections_complete = true`
- FR-HPC-009.6: `student_form_submissions` table tracks per-page progress
- FR-HPC-009.7: Goals & Aspirations wizard for Template 4 via `StudentGoalsController`

**Gate:** `tenant.hpc-student.view`, `tenant.hpc-student.submit`
**Status:** 🟡 Controllers and services done; Blade views not confirmed complete

---

### FR-HPC-010 — Parent Input Collection 🟡

**Description:** Token-based links for guardians to fill parent-owned sections without system login.

**Sub-requirements:**
- FR-HPC-010.1: Teacher generates parent link: `POST /hpc/teacher/generate-parent-link/{report_id}`
  — creates `hpc_parent_form_tokens` record; valid for 7 days
- FR-HPC-010.2: `hpc_parent_form_tokens` — report_id, student_id, guardian_id, token (UUID),
  expires_at, completed_at, created_by
- FR-HPC-010.3: Parent form at `GET /hpc/parent/form/{token}` (no auth) — validates token;
  shows expired/thank-you views on invalid/completed token
- FR-HPC-010.4: Parent data filtered via `HpcSectionRoleService::filterPayloadByRole(..., 'parent')`
- FR-HPC-010.5: Final submission marks `hpc_reports.parent_sections_complete = true`
- FR-HPC-010.6: Parent dashboard at `GET /hpc/parent/dashboard/{token}` — report status, comments
- FR-HPC-010.7: Bidirectional comment system — parent posts; teacher replies; stored in
  `hpc_report_comments`
- FR-HPC-010.8: Token expiry and revocation must be enforced server-side on every request

**Status:** 🟡 `ParentHpcFormController` and `ParentHpcFormService` done; Blade views not confirmed;
parent routes correctly outside auth middleware (intentional)

---

### FR-HPC-011 — Peer Assessment Workflow 🟡

**Description:** Assign classmates as peer reviewers; students fill peer-evaluation sections
for assigned peers.

**Sub-requirements:**
- FR-HPC-011.1: Auto-assignment: `POST /hpc/teacher/assign-peers/{report_id}` via
  `PeerAssignmentService::autoAssignPeers()` — shuffled, no self-review, no cycles
  - Template 2: 2 peers per student
  - Templates 3 & 4: 1 peer per activity cycle (9 cycles T3; 8 cycles T4)
- FR-HPC-011.2: `hpc_peer_assignments` — report_id, student_id (subject), peer_student_id (reviewer),
  template_id, cycle_number, peer_number, status (pending/in_progress/completed), assigned_by
- FR-HPC-011.3: `hpc_peer_responses` — assignment_id, html_object_name, value
- FR-HPC-011.4: Peer form at `GET /hpc/student/peer-review/{assignment_id}` — shows peer-owned pages
- FR-HPC-011.5: Completion matrix at `GET /hpc/teacher/peer-status/{report_id}`

**Status:** 🟡 `PeerHpcFormController` and `PeerAssignmentService` done; views not confirmed

---

### FR-HPC-012 — PDF Report Generation ✅

**Description:** Multi-page PDF report cards generated for individual students or in bulk using
DomPDF v3.1 with 4 Blade templates.

**Sub-requirements:**
- FR-HPC-012.1: Single student PDF: `GET /hpc/hpc-single/{student_id?}` → `generateSingleStudentPdf()`
- FR-HPC-012.2: Bulk PDF: `POST /hpc/generate-report` — synchronous; processes multiple students
- FR-HPC-012.3: Bulk ZIP export: PDFs archived to `storage/app/public/hpc-reports/zip/`
- FR-HPC-012.4: ZIP download: `GET /hpc/download-zip/{filename}` — sanitized filename;
  `deleteFileAfterSend(true)`
- FR-HPC-012.5: Template selection from student's class ordinal via `HpcReportService::resolveTemplateId()`
- FR-HPC-012.6: PDF fed from `HpcReportService::getSavedValues()` — `$savedValues` + `$savedTableData`
- FR-HPC-012.7: Attendance re-computed at PDF generation time
- FR-HPC-012.8: PDF view page: `GET /hpc/hpc-view/{student_id?}` — supports encrypted (public)
  and plain (authenticated) student_id
- 📐 FR-HPC-012.9 (NEW): Bulk PDF generation should be moved to a queued job to prevent request
  timeout on large classes (30+ students)
- 📐 FR-HPC-012.10 (NEW): `Organization::first()` called on every PDF generation must be cached
  per request

**Status:** ✅ Done — DomPDF integration complete; 4 Blade view templates working

---

### FR-HPC-013 — Approval Workflow ✅

**Description:** Linear state machine on HPC reports from draft through publishing.

**States:**
```
draft → submitted → under_review → final → published → archived
                 ↘ (send-back) ↗
```

**State Constants (HpcReport model):**
- `STATUS_DRAFT = 'draft'` | `STATUS_SUBMITTED = 'submitted'`
- `STATUS_UNDER_REVIEW = 'under_review'` | `STATUS_FINAL = 'final'`
- `STATUS_PUBLISHED = 'published'` | `STATUS_ARCHIVED = 'archived'`

**Sub-requirements:**
- FR-HPC-013.1: Teacher submits: `POST /hpc/workflow/{report}/submit` → sets `submitted_at`
- FR-HPC-013.2: Principal starts review: `POST /hpc/workflow/{report}/review` — requires
  `tenant.hpc.review` gate
- FR-HPC-013.3: Principal approves: `POST /hpc/workflow/{report}/approve` — sets `reviewed_by`,
  `reviewed_at`, optional `review_comments`
- FR-HPC-013.4: Principal sends back: `POST /hpc/workflow/{report}/send-back` — requires comment;
  transitions to submitted or draft
- FR-HPC-013.5: Admin publishes: `POST /hpc/workflow/{report}/publish` — requires
  `tenant.hpc.publish` gate; sets `published_at`, `published_by`
- FR-HPC-013.6: Archive: `POST /hpc/workflow/{report}/archive` — terminal state, no exit
- FR-HPC-013.7: Workflow status: `GET /hpc/workflow/{report}/status` — JSON with all audit data
  and allowed next transitions
- FR-HPC-013.8: Invalid transitions return HTTP 422 with descriptive message
- 📐 FR-HPC-013.9 (NEW): Notification events (email/in-app) on status change — currently TODO stubs

**Service:** `HpcWorkflowService` (163 lines)
**Status:** ✅ Done — state machine fully implemented; notification stubs pending

---

### FR-HPC-014 — Email Distribution ✅

**Description:** Queue email delivery of report view links (not PDF attachments) to guardians.

**Sub-requirements:**
- FR-HPC-014.1: Single email: `POST /hpc/send-report-email` — validates student, template, guardian emails
- FR-HPC-014.2: Bulk email: `POST /hpc/send-bulk-report-email` — array of student_ids; returns
  count + per-student warnings
- FR-HPC-014.3: `SendHpcReportEmail` job — ShouldQueue, 3 retries, 120s timeout
- FR-HPC-014.4: Job re-initializes tenancy context via `tenancy()->initialize($this->tenantId)`
- FR-HPC-014.5: Encrypted URL: `Crypt::encryptString($studentId)` → `route('hpc.hpc-form.view', [...])`
- FR-HPC-014.6: Access code: `HPC-{studentId}-{guardianId}-{sha1_8chars}` — SMS fallback
- FR-HPC-014.7: 30-day link expiry displayed in email (display-only, not enforced in URL)
- FR-HPC-014.8: Skip guardians with null/empty email; log warning
- 📐 FR-HPC-014.9 (NEW): Rate limiting on bulk email endpoint — max 100 students per request,
  throttle 1 bulk dispatch per 10 minutes per tenant

**Architecture Decision D22:** Email sends a signed URL link, not a PDF attachment.
**Status:** ✅ Done

---

### FR-HPC-015 — Student HPC Snapshot ❌

**Description:** Periodic point-in-time snapshots of student HPC data for trend analysis.

**Sub-requirements:**
- FR-HPC-015.1: `hpc_student_hpc_snapshot` — academic_session_id, student_id, snapshot_json,
  generated_at; UNIQUE (academic_session_id, student_id)
- FR-HPC-015.2: Snapshot triggered on report publish or manually by admin
- 📐 FR-HPC-015.3 (NEW): `SnapshotController` with index + generate + compare endpoints
- 📐 FR-HPC-015.4 (NEW): Trend comparison view showing delta between two snapshots

**Model:** `StudentHpcSnapshot` exists (48 lines). No controller or routes implemented.
**Status:** ❌ Table and model exist; no controller, no routes, no views

---

### FR-HPC-016 — Attendance Management ✅

**Description:** Dedicated attendance configuration for HPC; working days per month config.

**Sub-requirements:**
- FR-HPC-016.1: Config: `GET/POST /hpc/attendance/config` — reads/writes `sys_settings` key
  `hpc_working_days_per_month` (JSON array of 12 values)
- FR-HPC-016.2: Attendance summary: `GET /hpc/attendance/summary`
- FR-HPC-016.3: `HpcAttendanceService` — `MONTH_ORDER` (APR→MAR), `REASON_CATEGORIES` (medical/
  family/weather/holiday), `getWorkingDaysPerMonth()` with DB fallback
- FR-HPC-016.4: Absence reason categorization via keyword matching

**Status:** ✅ Done — `HpcAttendanceController` and `HpcAttendanceService` implemented

---

### FR-HPC-017 — NCrF Credit Configuration ✅

**Description:** Configure credit points per grade level aligned with the National Credit Framework.

**Sub-requirements:**
- FR-HPC-017.1: `GET/POST /hpc/credit-config/` — view and save configuration
- FR-HPC-017.2: `GET /hpc/credit-config/calculate` — calculate credits for a student
- FR-HPC-017.3: Default levels: BV1=0.05, BV2=0.1 ... Gr12=4.5
- FR-HPC-017.4: `HpcCreditCalculatorService::calculateCredits()` → `mapToFormFields()` auto-fills
  credit pages on form load

**Note (GAP-DB-002):** `hpc_credit_config` table is missing from DDL v2. Controller exists and saves
config — storage target must be confirmed and DDL updated.
**Status:** ✅ Controller and service done; DDL gap must be resolved

---

### FR-HPC-018 — Activity Assessment View 🟡

**Description:** Consolidated view showing all actor contributions for a single report's activity
assessment sections.

**Sub-requirements:**
- FR-HPC-018.1: `GET /hpc/activity-assessment/{report_id}` — shows completion per actor type
- FR-HPC-018.2: Read-only overview for principal/admin

**Status:** 🟡 `HpcActivityAssessmentController` exists; implementation depth unconfirmed

---

### FR-HPC-019 — Curriculum Change Request ❌ 📐 New in V2

**Description:** Formal workflow for requesting curriculum changes (add/update/delete to
subjects, lessons, topics, competencies) with impact analysis.

**Sub-requirements:**
- FR-HPC-019.1: `hpc_curriculum_change_request` — entity_type, entity_id, change_type,
  change_summary, impact_analysis (JSON), status (DRAFT/SUBMITTED/APPROVED/REJECTED),
  requested_by, requested_at
- FR-HPC-019.2: CRUD workflow controller with approval flow
- FR-HPC-019.3: Impact analysis — auto-populate based on downstream dependencies

**Status:** ❌ Table exists in DDL; model and controller not yet implemented

---

## 5. Data Model

### 5.1 DDL Presence Summary

| Table | DDL Present | Model Present | Notes |
|-------|-------------|---------------|-------|
| `hpc_templates` | ✅ line 6194 | ✅ HpcTemplates | |
| `hpc_template_parts` | ✅ line 6208 | ✅ HpcTemplateParts | |
| `hpc_template_parts_items` | ✅ line 6232 | ✅ HpcTemplatePartsItems | |
| `hpc_template_sections` | ✅ line 6249 | ✅ HpcTemplateSections | |
| `hpc_template_section_items` | ✅ line 6273 | ✅ HpcTemplateSectionItems | |
| `hpc_template_section_table` | ✅ line 6294 | ✅ HpcTemplateSectionTable | |
| `hpc_template_rubrics` | ✅ line 6313 | ✅ HpcTemplateRubrics | |
| `hpc_template_rubric_items` | ✅ line 6338 | ✅ HpcTemplateRubricItems | |
| `hpc_reports` | ✅ line 6368 | ✅ HpcReport | DDL status ENUM differs from model |
| `hpc_report_items` | ✅ line 6393 | ✅ HpcReportItem | |
| `hpc_report_table` | ✅ line 6431 | ✅ HpcReportTable | |
| `hpc_report_comments` | ❌ Missing | ✅ HpcReportComment | Must add to DDL |
| `hpc_circular_goals` | ✅ line 6487 | ✅ CircularGoals | |
| `hpc_circular_goal_competency_jnt` | ✅ line 6503 | ✅ CircularGoalCompetencyJnt | FK references slb_circular_goals — possible typo |
| `hpc_learning_outcomes` | ✅ line 6522 | ✅ LearningOutcomes | |
| `hpc_outcome_entity_jnt` | ✅ line 6539 | ✅ OutcomesEntityJnt | |
| `hpc_outcome_question_jnt` | ✅ line 6561 | ✅ OutcomesQuestionJnt | |
| `hpc_knowledge_graph_validation` | ✅ line 6580 | ✅ KnowledgeGraphValidation | |
| `hpc_topic_equivalency` | ✅ line 6600 | ✅ TopicEquivalency | |
| `hpc_syllabus_coverage_snapshot` | ✅ line 6619 | ✅ SyllabusCoverageSnapshot | |
| `hpc_ability_parameters` | ✅ line 6642 | ✅ HpcParameters | |
| `hpc_performance_descriptors` | ✅ line 6661 | ✅ HpcPerformanceDescriptor | |
| `hpc_student_evaluation` | ✅ line 6680 | ✅ StudentHpcEvaluation | |
| `hpc_learning_activities` | ✅ line 6714 | ✅ LearningActivities | |
| `hpc_learning_activity_type` | ✅ line 6729 | ✅ LearningActivityType | |
| `hpc_student_hpc_snapshot` | ✅ line 6746 | ✅ StudentHpcSnapshot | No controller |
| `hpc_curriculum_change_request` | ✅ line 5185 | ❌ Missing | Isolated from HPC block |
| `hpc_credit_config` | ❌ Missing | ✅ HpcCreditConfig | Controller uses it — DDL gap |
| `hpc_parent_form_tokens` | ❌ Missing | ✅ ParentFormToken | Used by ParentHpcFormController |
| `hpc_peer_assignments` | ❌ Missing | ✅ PeerAssignment | Used by PeerHpcFormController |
| `hpc_peer_responses` | ❌ Missing | ✅ PeerResponse | Used by PeerHpcFormController |
| `student_form_submissions` | ❌ Missing | ✅ StudentFormSubmission | No hpc_ prefix — naming inconsistency |
| `hpc_lesson_version_control` | ✅ line 5185 | ❌ Missing | Isolated, no model or controller |

### 5.2 DDL Discrepancies

**GAP-DB-001:** `hpc_curriculum_change_request` at DDL line 5185 is separated from the main HPC
block (lines 6187-6763). Must be moved or grouped.

**GAP-DB-002:** `hpc_credit_config` table is missing from DDL despite `HpcCreditConfigController`
and `HpcCreditConfig` model being present.

**GAP-DB-003:** `hpc_reports.status` in DDL is `ENUM('Draft','Final','Published','Archived')` but
model uses 6 values: draft, submitted, under_review, final, published, archived. DDL must be
updated to match the model's 6-state enum.

**GAP-DB-004:** `hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses` are missing
from DDL. All three have models and are actively used in controllers.

**GAP-DB-005:** `student_form_submissions` lacks the `hpc_` prefix — naming inconsistency with
all other module tables.

### 5.3 Key Table Definitions

#### `hpc_reports` (corrected schema)

| Column | Type | Notes |
|--------|------|-------|
| id | INT AUTO_INCREMENT PK | |
| academic_session_id | INT UNSIGNED NOT NULL | FK std_student_academic_sessions |
| term_id | INT UNSIGNED NOT NULL | FK sch_academic_term (DDL refs cbse_terms — legacy) |
| student_id | INT UNSIGNED NOT NULL | FK std_students |
| class_id | INT UNSIGNED NOT NULL | FK sch_classes |
| section_id | INT UNSIGNED NOT NULL | FK sch_sections |
| template_id | INT UNSIGNED NOT NULL | FK hpc_templates |
| prepared_by | INT UNSIGNED NULL | FK sys_users |
| report_date | DATE NOT NULL | |
| status | ENUM | draft/submitted/under_review/final/published/archived |
| submitted_at | DATETIME NULL | Set on submit transition |
| reviewed_by | INT UNSIGNED NULL | FK sys_users |
| reviewed_at | DATETIME NULL | |
| review_comments | TEXT NULL | |
| published_by | INT UNSIGNED NULL | FK sys_users |
| published_at | DATETIME NULL | |
| student_sections_complete | BOOLEAN DEFAULT 0 | |
| parent_sections_complete | BOOLEAN DEFAULT 0 | |
| created_by | INT UNSIGNED NULL | |
| created_at, updated_at, deleted_at | TIMESTAMP | Soft delete |

UNIQUE: `(academic_session_id, term_id, student_id)`

#### `hpc_report_items` (column-to-input-type mapping)

| Column | Covers Input Types |
|--------|--------------------|
| `in_numeric_value` | number, integer, decimal, float, percentage, phone |
| `in_text_value` | text, tel, email, date, pincode, udise (max 512) |
| `in_boolean_value` | boolean, checkbox, interest_*, resources_* |
| `in_selected_value` | descriptor, grade value (max 100) |
| `in_image_path` | image URL |
| `in_filename` / `in_filepath` | file upload |
| `in_json_value` | json, curricular_goals, strengths[], barriers[] |
| `remark` | textarea, observational_notes, writeup_*, comments |

---

## 6. API Endpoints & Routes

### 6.1 Public Routes (no authentication)

| Method | URI | Controller@Method | Security Concern |
|--------|-----|-------------------|-----------------|
| GET | `/hpc/hpc-view/{student_id?}` | `HpcController@viewPdfPage` | SEC-HPC-002: No auth; encrypted ID only protection |
| GET | `/hpc/parent/dashboard/{token}` | `ParentHpcFormController@dashboard` | Intentional: token-based |
| GET | `/hpc/parent/form/{token}` | `ParentHpcFormController@form` | Intentional: token-based |
| POST | `/hpc/parent/form/{token}` | `ParentHpcFormController@save` | Must verify token expiry |
| POST | `/hpc/parent/comment/{token}` | `ParentHpcFormController@postComment` | Must verify token |

### 6.2 Authenticated Routes — Core HPC

| Method | URI | Controller@Method | Gate |
|--------|-----|-------------------|------|
| GET | `/hpc/hpc` | `HpcController@index` | `tenant.hpc.view` |
| GET | `/hpc/templates` | `HpcController@hpcTemplates` | `tenant.hpc.view` |
| GET | `/hpc/hpc-form/{student_id?}` | `HpcController@hpc_form` | `tenant.hpc.view` |
| POST | `/hpc/form/store` | `HpcController@formStore` | `tenant.hpc.create` |
| GET | `/hpc/hpc-single/{student_id?}` | `HpcController@generateSingleStudentPdf` | `tenant.hpc.view` |
| POST | `/hpc/generate-report` | `HpcController@generateReportPdf` | `tenant.hpc.view` |
| GET | `/hpc/download-zip/{filename}` | `HpcController@downloadZip` | `tenant.hpc.view` |
| POST | `/hpc/send-report-email` | `HpcController@sendReportEmail` | `tenant.hpc.update` |
| POST | `/hpc/send-bulk-report-email` | `HpcController@sendBulkReportEmail` | `tenant.hpc.update` |

### 6.3 Workflow Routes

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | `/hpc/workflow/{report}/status` | `hpc.workflow.status` | `tenant.hpc.view` |
| POST | `/hpc/workflow/{report}/submit` | `hpc.workflow.submit` | `tenant.hpc.update` |
| POST | `/hpc/workflow/{report}/review` | `hpc.workflow.review` | `tenant.hpc.review` |
| POST | `/hpc/workflow/{report}/approve` | `hpc.workflow.approve` | `tenant.hpc.review` |
| POST | `/hpc/workflow/{report}/send-back` | `hpc.workflow.send-back` | `tenant.hpc.review` |
| POST | `/hpc/workflow/{report}/publish` | `hpc.workflow.publish` | `tenant.hpc.publish` |
| POST | `/hpc/workflow/{report}/archive` | `hpc.workflow.archive` | `tenant.hpc.publish` |

### 6.4 Student Portal Routes

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

### 6.5 Teacher Management Routes

| Method | URI | Purpose |
|--------|-----|---------|
| POST | `/hpc/teacher/generate-parent-link/{report_id}` | Generate token for parent |
| GET | `/hpc/teacher/parent-status/{report_id}` | Check parent completion |
| POST | `/hpc/teacher/comment/{report_id}` | Reply to parent comment |
| GET | `/hpc/teacher/comments/{report_id}` | View all comments |
| POST | `/hpc/teacher/assign-peers/{report_id}` | Auto-assign peer reviewers |
| GET | `/hpc/teacher/peer-status/{report_id}` | Peer completion matrix |

### 6.6 CRUD Sub-Module Routes (each with standard resource + trash/restore/force-delete/toggle-status)

`circular-goals`, `learning-outcomes`, `question-mapping`, `knowledge-graph-validation`,
`topic-equivalency`, `syllabus-coverage-snapshot`, `hpc-parameters`, `hpc-performance-descriptor`,
`student-hpc-evaluation`, `learning-activities`, `hpc-templates`, `hpc-template-parts`,
`hpc-template-sections`, `hpc-template-rubrics`

### 6.7 Missing Middleware — P0 Fix Required

All routes in the `/hpc/` group are missing `EnsureTenantHasModule` middleware (GAP-RT-001).
The fix is to add the middleware to the route group in `routes/tenant.php`:

```php
Route::middleware(['auth', 'verified', 'EnsureTenantHasModule:HPC'])
    ->prefix('hpc')
    ->name('hpc.')
    ->group(function () { ... });
```

---

## 7. UI Screens

### Scr-HPC-01: HPC Index Dashboard

**Route:** `GET /hpc/hpc`
**Controller:** `HpcController@index`
**Status:** ✅ Done
**Description:** Lists all HPC reports for the active academic term. Filterable by class, section,
status. Shows student name, class, template version, status badge, completion indicators for
student/parent sections, and action buttons (View Form, Generate PDF, Send Email, View Workflow).

---

### Scr-HPC-02: Template Management Hub

**Route:** `GET /hpc/templates`
**Controller:** `HpcController@hpcTemplates`
**Status:** ✅ Done
**Description:** Tabbed view showing all 4 templates with their parts, sections, rubrics loaded
simultaneously. Note: 4 paginated queries on load — performance optimization needed (Section 10).

---

### Scr-HPC-03: Teacher HPC Data Entry Form

**Route:** `GET /hpc/hpc-form/{student_id?}`
**Controller:** `HpcController@hpc_form`
**Status:** ✅ Done
**Description:** Multi-page tabbed form. Each tab = one page_no from `hpc_template_parts`.
Pre-populated from saved values + auto-feeds. Supports all 7 field input types.
Template selection: 4 separate Blade views (`first_form`/`second_form`/`third_form`/`fourth_form`).

---

### Scr-HPC-04: Student Self-Assessment Dashboard

**Route:** `GET /hpc/student/dashboard`
**Controller:** `StudentHpcFormController@dashboard`
**Status:** 🟡 Controller done; view status unconfirmed
**Description:** Student sees list of pending HPC reports needing their input, with progress % per
report. Only accessible to authenticated students linked via `Student::where('user_id', $user->id)`.

---

### Scr-HPC-05: Student Self-Assessment Form

**Route:** `GET /hpc/student/form/{report_id}`
**Controller:** `StudentHpcFormController@form`
**Status:** 🟡 Controller done; view status unconfirmed
**Description:** Filtered to show only student-owned pages. Goals & Aspirations wizard available
for Template 4 students.

---

### Scr-HPC-06: Parent Input Form (Token-Based)

**Route:** `GET /hpc/parent/form/{token}`
**Controller:** `ParentHpcFormController@form`
**Status:** 🟡 Controller done; Blade views (form/dashboard/expired/thank-you) status unconfirmed
**Description:** Publicly accessible via UUID token. Expires after 7 days. Shows expired/completed
views on invalid token. Filtered to parent-owned sections only.

---

### Scr-HPC-07: Peer Review Form

**Route:** `GET /hpc/student/peer-review/{assignment_id}`
**Controller:** `PeerHpcFormController@form`
**Status:** 🟡 Controller done; view status unconfirmed
**Description:** Peer reviewer sees peer-owned pages for the assigned student's report.

---

### Scr-HPC-08: PDF View Page

**Route:** `GET /hpc/hpc-view/{student_id?}`
**Controller:** `HpcController@viewPdfPage`
**Status:** ✅ Done (security gap exists — SEC-HPC-002)
**Description:** Renders report as web page for guardian viewing via emailed link. Supports both
encrypted (public link from email) and plain (authenticated teacher preview) student_id.

---

### Scr-HPC-09: Approval Workflow Status

**Route:** `GET /hpc/workflow/{report}/status`
**Controller:** `HpcWorkflowService` via `HpcController`
**Status:** ✅ Done
**Description:** JSON endpoint returning current status, all transition timestamps, reviewer info,
and allowed next actions.

---

### Scr-HPC-10: NCrF Credit Configuration

**Route:** `GET/POST /hpc/credit-config/`
**Controller:** `HpcCreditConfigController`
**Status:** ✅ Done (DDL gap — no `hpc_credit_config` in DDL v2)
**Description:** Grid showing grade codes (BV1–Gr12) with credit values. School can override
NCrF defaults per grade.

---

### Scr-HPC-11: Attendance Configuration

**Route:** `GET/POST /hpc/attendance/config`
**Controller:** `HpcAttendanceController`
**Status:** ✅ Done
**Description:** 12-month working days configuration for HPC attendance reporting.

---

### Scr-HPC-12: Student Evaluation (ASC Framework)

**Route:** `GET /hpc/student-hpc-evaluation`
**Controller:** `StudentHpcEvaluationController`
**Status:** ✅ Done
**Description:** Teacher enters Awareness/Sensitivity/Creativity ratings per student, per subject,
per competency. Evidence type (ACTIVITY/ASSESSMENT/OBSERVATION) and optional evidence ID.

---

### Scr-HPC-13: Activity Assessment Overview

**Route:** `GET /hpc/activity-assessment/{report_id}`
**Controller:** `HpcActivityAssessmentController`
**Status:** 🟡 Controller exists; implementation depth unconfirmed
**Description:** Read-only overview showing completion status of teacher, student, peer, and
parent sections for a single report.

---

## 8. Business Rules

### BR-HPC-001: Template-to-Grade Assignment
A student's applicable HPC template is resolved by `HpcReportService::resolveTemplateId()` based
on the student's class ordinal. This mapping must align with `hpc_templates.applicable_to_grade`
(JSON array of grade codes). Changing a student's class mid-term does not automatically change
their assigned template.

### BR-HPC-002: Unique Report per Term per Student
`hpc_reports` has UNIQUE constraint on `(academic_session_id, term_id, student_id)`. A student
can have at most one HPC report per academic term. `formStore()` uses `updateOrCreate()` to enforce
this.

### BR-HPC-003: Actor Field Ownership
Each section/rubric in the template hierarchy has an implicit owner (teacher/student/parent/peer).
`HpcSectionRoleService::filterPayloadByRole()` strips any submitted fields that do not belong to
the submitting actor's role. Unauthorized field attempts are logged as warnings.

### BR-HPC-004: Workflow State Machine
`HpcReport::TRANSITIONS` constant defines all valid transitions. Any attempt to move to a state
not in the allowed list returns HTTP 422. Published and archived states are terminal (no rollback).

### BR-HPC-005: Token Expiry
Parent form tokens expire 7 days after creation (`expires_at`). On every parent form request
(GET and POST), the system must verify the token has not expired and has not been previously
completed (`completed_at` is null). A completed token cannot be reused.

### BR-HPC-006: Peer Assignment Constraints
Peer assignment must prevent self-review (peer_student_id != student_id) and avoid review cycles
(if A reviews B, B should not be assigned to review A in the same cycle). Auto-assignment uses
shuffled selection.

### BR-HPC-007: Attendance Year Mapping
Attendance is aggregated April–March (Indian academic year). The `HpcAttendanceService::MONTH_ORDER`
constant defines this. Attendance data is re-computed both on form load and at PDF generation time
to ensure accuracy.

### BR-HPC-008: LMS Data Feed Fallback
`HpcLmsIntegrationService::getAllLmsData()` must use try/catch with graceful fallback — if LMS
modules (Exam, Quiz, Homework) are not configured or have no data for the student, the HPC form
opens with empty LMS sections rather than throwing an exception.

### BR-HPC-009: Bulk PDF Size Limit
Bulk PDF generation is currently synchronous. Until FR-HPC-012.9 (queue job) is implemented,
a hard limit of 50 students per bulk request must be enforced to prevent PHP request timeout.

### BR-HPC-010: Email Link vs Attachment
Per Architecture Decision D22, emails to guardians send a report view URL — not a PDF attachment.
This keeps email sizes small, allows guardians to view live reports, and avoids attachment
storage overhead.

### BR-HPC-011: Download ZIP Sanitization
`downloadZip()` must sanitize the filename parameter to allow only alphanumeric characters,
underscores, hyphens, and dots. Any other character must cause a 400 error or redirect.

### BR-HPC-012: NCrF Credit Defaults
If a school has not configured custom credit values, `HpcCreditCalculatorService` uses the
national defaults (BV1=0.05 through Gr12=4.5). Custom values stored in `hpc_credit_config`
override the defaults per grade code.

---

## 9. Workflows

### 9.1 HPC Report Creation Workflow

```
Step 1: Admin/Teacher selects student from index
  GET /hpc/hpc?class_id=X&section_id=Y&term_id=Z

Step 2: Teacher opens HPC form for student
  GET /hpc/hpc-form/{student_id}?template_id=4&tab=page-1
  → HpcController::hpc_form()
  → Resolve template from student's class (resolveTemplateId)
  → Load template hierarchy (5 eager-loaded relations)
  → Auto-aggregate attendance (2 DB queries, April-March grouping)
  → Pre-fill from hpc_report_items (getSavedValues)
  → Auto-feed from hpc_student_evaluation (HpcDataMappingService)
  → Auto-feed from LMS (HpcLmsIntegrationService, graceful fallback)
  → Auto-calculate NCrF credits (HpcCreditCalculatorService)
  → Render Blade form view (first_form/second_form/third_form/fourth_form)

Step 3: Teacher fills form page by page (tabbed navigation)
  Each tab = one page_no from hpc_template_parts

Step 4: Teacher saves draft
  POST /hpc/form/store
  → Validates 6 required fields (student_id, template_id, academic_session_id, term_id, class_id, section_id)
  → Loads template with 5 eager-load chains
  → Builds 4 mapping arrays: fieldMapping, globalRubricMapping, tableCellMapping, tableMapping
  → Routes each submitted field to correct storage table and column
  → HpcReportService::saveReport() → updateOrCreate hpc_reports, upsert hpc_report_items,
    upsert hpc_report_table
  → Status = 'draft'

Step 5: Teacher submits for review
  POST /hpc/workflow/{report}/submit
  → HpcWorkflowService::submit() → status = 'submitted', submitted_at = now()

Step 6: Principal starts review
  POST /hpc/workflow/{report}/review
  → status = 'under_review', reviewed_by = userId

Step 7a: Principal approves
  POST /hpc/workflow/{report}/approve
  → status = 'final', reviewed_at = now(), review_comments optional

Step 7b: Principal sends back (with required comment)
  POST /hpc/workflow/{report}/send-back
  → status = 'submitted' (from under_review) or 'draft' (from submitted)

Step 8: Admin publishes
  POST /hpc/workflow/{report}/publish
  → Requires tenant.hpc.publish gate
  → status = 'published', published_at = now(), published_by = userId

Step 9 (optional): Admin archives
  POST /hpc/workflow/{report}/archive
  → status = 'archived' (terminal state — no exit)
```

### 9.2 PDF Generation Workflow

```
Step 1: Teacher/Admin selects students for PDF generation
  POST /hpc/generate-report
  Body: { student_ids: [...], template_id: X, academic_term_id: Y }

Step 2: HpcController::generateReportPdf()
  → Validate max 50 students per request (BR-HPC-009)
  → For each student:
    a. Resolve template from student's class (resolveTemplateId)
    b. Load template hierarchy
    c. Load saved values (getSavedValues)
    d. Re-compute attendance data
    e. Initialize DomPDF instance
    f. Render Blade view to HTML string
    g. DomPDF::loadHtml() → render() → output()
    h. Collect PDF binary

Step 3: Archive into ZIP
  ZipArchive: storage/app/public/hpc-reports/zip/{timestamp}.zip
  Each file named: HPC_{studentName}_{date}.pdf

Step 4: Return JSON
  { success: true, zip_url: "...", pdf_urls: [...], message: "N report(s) generated." }

Step 5: Admin downloads ZIP
  GET /hpc/download-zip/{filename}
  → Sanitize filename (alphanumeric + underscore + hyphen + dot only)
  → Stream with deleteFileAfterSend(true)
```

### 9.3 Email Distribution Workflow

```
Step 1: Admin selects student(s) and clicks "Send Email"
  POST /hpc/send-report-email (single)
  POST /hpc/send-bulk-report-email (bulk)

Step 2: Pre-dispatch validation
  → Verify student exists
  → Verify template mapped for student's class
  → Verify guardians exist with email addresses

Step 3: Dispatch SendHpcReportEmail job (queued)
  Job payload: studentId, academicTermId, tenantId

Step 4: Job executes
  → tenancy()->initialize($tenantId)   // Re-enter tenant context
  → Load student + guardians with email
  → For each guardian:
    a. Resolve tenant domain
    b. URL::forceRootUrl($rootUrl)
    c. Crypt::encryptString($studentId) → encrypted token
    d. Generate URL: route('hpc.hpc-form.view', ['student_id' => $encryptedId])
    e. Generate access code: HPC-{studentId}-{guardianId}-{sha1_8chars}
    f. Mail::to($guardian->email)->send(new HpcReportMail(...))
  → tenancy()->end() in finally block

Step 5: Guardian receives email with:
  → Report view URL (link, not attachment)
  → Access code for phone/SMS fallback
  → Expiry date (30 days from dispatch — display only, not enforced)
```

### 9.4 Multi-Actor Data Collection Workflow (Template 3 or 4)

```
Step 1: Teacher completes teacher-owned sections (Steps 2-4 of 9.1)

Step 2: Teacher generates parent token
  POST /hpc/teacher/generate-parent-link/{report_id}
  → Creates hpc_parent_form_tokens record (expires in 7 days)
  → Returns token URL for sharing with guardian

Step 3: Teacher assigns peer reviewers
  POST /hpc/teacher/assign-peers/{report_id}
  → PeerAssignmentService::autoAssignPeers()
  → Creates hpc_peer_assignments records

Step 4: Student completes self-assessment (authenticated)
  GET/POST /hpc/student/form/{report_id}
  → StudentHpcFormService tracks progress per page
  POST /hpc/student/submit/{report_id}
  → hpc_reports.student_sections_complete = true

Step 5: Peer reviewer completes peer sections (authenticated)
  GET/POST /hpc/student/peer-review/{assignment_id}
  → PeerAssignmentService::saveResponses()
  → PeerAssignmentService::completeReview() on final submit

Step 6: Parent completes parent sections (token-based, no auth)
  GET /hpc/parent/form/{token}  → validate token, show form
  POST /hpc/parent/form/{token} → HpcSectionRoleService filters to parent fields
  POST /hpc/parent/comment/{token} → bidirectional comment thread
  → hpc_reports.parent_sections_complete = true

Step 7: Teacher reviews all contributions
  GET /hpc/teacher/peer-status/{report_id}     → peer completion matrix
  GET /hpc/teacher/parent-status/{report_id}   → parent completion
  GET /hpc/activity-assessment/{report_id}     → all actor overview

Step 8: Teacher proceeds with approval workflow (Section 9.1 Steps 5-9)
```

---

## 10. Non-Functional Requirements

### NFR-HPC-01: Module Tenant Isolation

**Requirement:** All HPC routes must include `EnsureTenantHasModule:HPC` middleware.
**Current State:** ❌ Missing (GAP-RT-001 / SEC-HPC-001)
**Fix:** Add middleware to HPC route group in `routes/tenant.php`.

### NFR-HPC-02: PDF View Route Security

**Requirement:** The `hpc-view/{student_id?}` route must be moved behind authentication middleware
or, at minimum, must add Gate check `tenant.hpc.view` before rendering. The current public route
with an encrypted ID only is insufficient for student data protection.
**Current State:** ❌ Public route (SEC-HPC-002)
**Proposed Fix:** Move behind auth OR add server-side gate check: if Crypt::decryptString fails
or gate check fails → return 403.

### NFR-HPC-03: God Controller Decomposition

**Requirement:** `HpcController` must be decomposed into focused controllers. See Section 14
for the decomposition plan.
**Current State:** ❌ 2,610 lines (GAP-CTRL-001)

### NFR-HPC-04: Bulk Operation Timeouts

**Requirement:** Bulk PDF generation for more than 10 students must use a queued job
(dispatched via `GenerateHpcReportsJob`) to prevent PHP 30s timeout.
**Current State:** ❌ Synchronous (PERF-HPC-002)

### NFR-HPC-05: Caching for Template Structures

**Requirement:** HPC template hierarchies (parts, sections, rubrics, items) rarely change and must
be cached for 24 hours using `Cache::remember('hpc_template_{id}', 86400, ...)`.
**Current State:** ❌ Not cached (PERF-HPC-005)

### NFR-HPC-06: Query Count on Form Load

**Requirement:** `hpc_form()` and `hpcTemplates()` must not exceed 10 queries per request.
The current multi-query pattern (siblings + attendance + 5 eager loads) should be profiled
and optimized.
**Current State:** 🟡 Needs profiling (PERF-HPC-003)

### NFR-HPC-07: Test Coverage

**Requirement:** Minimum 60% test coverage for all services and 40% for controllers.
**Current State:** 🟡 6 unit test files (393 lines) for services only; 0 controller or feature tests
**Target:**
- Service unit tests: HpcReportService, HpcWorkflowService, HpcAttendanceService,
  HpcCreditCalculatorService, HpcSectionRoleService, HpcDataMappingService ← partially done
- Feature tests needed: form submission pipeline, PDF generation, workflow transitions,
  email dispatch, peer assignment

### NFR-HPC-08: Form Request Coverage

**Requirement:** Every controller action that accepts POST/PUT input must use a dedicated
FormRequest class.
**Current State:** ❌ 9 actions missing (Section 8.2 of V1 / FR list below)

### NFR-HPC-09: Rate Limiting

**Requirement:** Bulk email dispatch (`send-bulk-report-email`) must be throttle-limited:
max 100 students per request; max 1 bulk dispatch per 10 minutes per tenant (SEC-HPC-005).

### NFR-HPC-10: Code Quality

**Requirement:**
- All code comments must be in English; Hindi comments (e.g., line 171 of HpcController) must
  be translated
- No `dd()` or `var_dump()` calls in production code
- Empty stub methods (store, update, destroy at lines 204, 224, 231) must be either implemented
  or removed with 405 Method Not Allowed response

---

## 11. Dependencies

### 11.1 Internal Module Dependencies

| Module | Dependency Type | Used By HPC |
|--------|----------------|-------------|
| SchoolSetup (`sch_*`) | Hard | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_academic_term` |
| StudentProfile (`std_*`) | Hard | `std_students`, `std_student_academic_sessions`, `std_student_attendance` |
| Syllabus (`slb_*`) | Hard | `slb_competencies`, `slb_bloom_taxonomy`, `slb_topics`, `slb_lessons` |
| QuestionBank (`qns_*`) | Soft | `qns_questions_bank` — outcome-question mapping |
| SystemConfig (`sys_*`) | Hard | `sys_users`, `sys_dropdown_table`, `sys_settings` (attendance config) |
| LMS-Exam (`exm_*`) | Soft | Auto-feed exam scores into report fields |
| LMS-Quiz (`quz_*`) | Soft | Auto-feed quiz results into report fields |
| LMS-Homework (`hmw_*`) | Soft | Auto-feed homework completion into report fields |

### 11.2 External Package Dependencies

| Package | Version | Usage |
|---------|---------|-------|
| `barryvdh/laravel-dompdf` | ^3.1 | PDF generation for 4 template types |
| `spatie/laravel-medialibrary` | Latest | File upload on HpcReport (`hpc_report_files` collection) |
| `stancl/tenancy` | v3.9 | Tenant isolation; job re-initialization |
| `nwidart/laravel-modules` | v12 | Module structure |

### 11.3 Integration Points

| Integration | Direction | Mechanism |
|-------------|-----------|-----------|
| Attendance | HPC reads std_attendance | `HpcAttendanceService::aggregateAttendance()` |
| NCrF Credits | HPC calculates from evaluation | `HpcCreditCalculatorService::calculateCredits()` |
| LMS Data | LMS feeds into HPC | `HpcLmsIntegrationService::getAllLmsData()` with fallback |
| Email | HPC dispatches to guardian | `SendHpcReportEmail` queued job → `HpcReportMail` |
| Student Portal | Student accesses HPC form | `StudentHpcFormController` (auth required) |
| Parent Portal | Guardian accesses via token | `ParentHpcFormController` (token, no auth) |

---

## 12. Test Scenarios

### 12.1 Existing Unit Tests (6 files — partially passing)

| Test File | Tests | Coverage Area |
|-----------|-------|---------------|
| `HpcWorkflowServiceTest.php` | 10 | State machine transitions; TRANSITIONS map completeness |
| `HpcReportServiceTest.php` | ~8 | getSavedValues; saveReport; resolveTemplateId |
| `HpcAttendanceServiceTest.php` | ~6 | Month grouping; working days config; reason categorization |
| `HpcCreditCalculatorTest.php` | ~6 | Credit calculation; grade defaults |
| `HpcDataMappingServiceTest.php` | ~6 | Evaluation-to-report field mapping |
| `HpcSectionRoleServiceTest.php` | ~5 | Field filtering by role |

### 12.2 Required Test Scenarios (not yet written)

**TS-HPC-001: Form Save Pipeline**
- Given: student with template 4, teacher fills form with all 7 field types
- When: POST /hpc/form/store
- Then: hpc_reports created/updated; hpc_report_items contain correct column mappings;
  hpc_report_table contains table cells; status = 'draft'

**TS-HPC-002: Workflow Transitions — Happy Path**
- Given: report in 'draft' state
- When: submit → review → approve → publish
- Then: each transition succeeds; timestamps set; gates enforced; archived from published succeeds

**TS-HPC-003: Workflow — Send Back**
- Given: report in 'under_review'
- When: send-back without comment
- Then: 422 error returned
- When: send-back with comment
- Then: status = 'submitted'; review_comments saved

**TS-HPC-004: Parent Token — Expiry**
- Given: parent token with expires_at = now() - 1 day
- When: GET /hpc/parent/form/{token}
- Then: returns expired view; POST to same token returns 403

**TS-HPC-005: Parent Token — Replay Prevention**
- Given: token with completed_at set
- When: POST /hpc/parent/form/{token}
- Then: returns already-completed view; data not overwritten

**TS-HPC-006: Role Filtering**
- Given: parent submits teacher-owned field names
- When: ParentHpcFormController::save()
- Then: teacher-owned fields stripped; warning logged; only parent-owned fields persisted

**TS-HPC-007: Peer Assignment — No Self-Review**
- Given: class of 5 students, template 3
- When: POST /hpc/teacher/assign-peers/{report_id}
- Then: no student assigned to review themselves; no review cycle A→B and B→A in same cycle

**TS-HPC-008: PDF Generation — Single Student**
- Given: student with published report, template 2
- When: GET /hpc/hpc-single/{student_id}
- Then: PDF returned with Content-Type application/pdf; attendance data correct

**TS-HPC-009: Bulk PDF — Size Limit**
- Given: request with 51 student_ids
- When: POST /hpc/generate-report
- Then: 422 returned; no PDFs generated

**TS-HPC-010: Email Dispatch**
- Given: student with 2 guardians (one with email, one without)
- When: POST /hpc/send-report-email
- Then: 1 email queued; guardian without email skipped with warning in response

**TS-HPC-011: Module Gate — No Module Access**
- Given: tenant without HPC module enabled
- When: GET /hpc/hpc
- Then: 403 returned (EnsureTenantHasModule)

**TS-HPC-012: Download ZIP — Path Traversal**
- Given: filename = "../../../etc/passwd"
- When: GET /hpc/download-zip/{filename}
- Then: 400 returned; no file served

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| HPC | Holistic Progress Card — NEP 2020 PARAKH-aligned assessment report |
| PARAKH | Performance Assessment, Review, and Analysis of Knowledge for Holistic Development |
| NEP 2020 | National Education Policy 2020 — mandates competency-based, holistic assessment |
| NCrF | National Credit Framework — assigns credit points per grade/domain |
| ASC Framework | Awareness, Sensitivity, Creativity — three ability parameters for subject evaluation |
| BPD | Beginner, Proficient, Advanced — three performance descriptors |
| Template | One of 4 HPC report designs mapped to NEP's four school stages |
| Part | A single page (page_no) within a template |
| Section | A content block within a part — can contain items, rubrics, or both |
| Rubric | A scored evaluation criterion within a section |
| Rubric Item | Individual field within a rubric — has input_type (Descriptor/Numeric/Grade/Text/Boolean/Image/Json) |
| html_object_name | Unique field identifier used as key in $savedValues and HTML form name attribute |
| $hpcData | PHP variable passed to Blade PDF templates; contains $savedValues and $savedTableData |
| Peer Assignment | Assignment of a classmate to review another student's HPC peer sections |
| Parent Token | UUID token in URL allowing guardian to fill parent-owned sections without login |
| DomPDF | PHP PDF generation library (barryvdh/laravel-dompdf v3.1) used for HPC report cards |
| God Controller | Anti-pattern: single controller exceeding 500 lines with multiple responsibilities |
| EnsureTenantHasModule | Laravel middleware checking tenant's subscription includes specified module |
| Academic Term | Reporting period (term/semester) within an academic session |

---

## 14. Suggestions & Refactoring Priorities

### 14.1 P0 — Critical (Must Fix Before Production)

#### P0-01: Add EnsureTenantHasModule Middleware (SEC-HPC-001)

**File:** `routes/tenant.php` — HPC route group (line ~2688)
**Fix:** Add `EnsureTenantHasModule:HPC` to the middleware array on the main HPC route group.
**Effort:** 30 minutes

#### P0-02: Secure PDF View Route (SEC-HPC-002)

**File:** `routes/tenant.php` line ~2684; `HpcController::viewPdfPage()`
**Fix Options:**
- Option A (preferred): Move route inside auth middleware group; keep encrypted ID support for
  email links; add `tenant.hpc.view` gate check
- Option B: Keep route public but add rate limiting (60 req/min) and encrypted-ID validation —
  return 403 if Crypt::decryptString() throws DecryptException
**Effort:** 2-4 hours

#### P0-03: God Controller Split (GAP-CTRL-001)

See Section 14.2 for full decomposition plan.
**Effort:** 15-20 hours

#### P0-04: Student Ownership Verification (SEC-HPC-004)

**File:** `HpcController::hpc_form()` line ~236
**Fix:** Verify the logged-in teacher is the class teacher for the student's section before
allowing form access: `Gate::authorize('tenant.hpc.form', $student)`.
**Effort:** 2 hours

### 14.2 God Controller Decomposition Plan

The 2,610-line `HpcController` must be split into 4 focused controllers:

#### HpcDashboardController (new)
Responsibilities: index, hpcTemplates, getFilteredStudents
Methods extracted from: HpcController lines ~1-200

```
Routes:
  GET  /hpc/hpc            → HpcDashboardController@index
  GET  /hpc/templates      → HpcDashboardController@hpcTemplates
```

#### HpcFormController (new — replaces HpcController::hpc_form + formStore)
Responsibilities: form load, form save, attendance aggregation
Methods extracted from: HpcController lines ~236-800

```
Routes:
  GET  /hpc/hpc-form/{student_id?}  → HpcFormController@show
  POST /hpc/form/store               → HpcFormController@store
```

Services used: HpcReportService, HpcDataMappingService, HpcLmsIntegrationService,
HpcCreditCalculatorService, HpcAttendanceService

#### HpcPdfController (new — replaces PDF generation methods)
Responsibilities: single PDF, bulk PDF, ZIP download, PDF view page
Methods extracted from: HpcController lines ~800-2610

```
Routes:
  GET  /hpc/hpc-view/{student_id?}   → HpcPdfController@viewPage
  GET  /hpc/hpc-single/{student_id?} → HpcPdfController@generateSingle
  POST /hpc/generate-report           → HpcPdfController@generateBulk
  GET  /hpc/download-zip/{filename}   → HpcPdfController@downloadZip
```

Services used: HpcReportService (extract PDF logic from controller into service)

#### HpcEmailController (new — replaces email dispatch methods)
Responsibilities: single email, bulk email dispatch
Methods extracted from: HpcController lines (sendReportEmail, sendBulkReportEmail)

```
Routes:
  POST /hpc/send-report-email       → HpcEmailController@send
  POST /hpc/send-bulk-report-email  → HpcEmailController@sendBulk
```

### 14.3 P1 — High Priority

#### P1-01: Create 9 Missing FormRequests (GAP-FR-001 through GAP-FR-009)

| FormRequest (new) | Used By | Key Fields |
|-------------------|---------|-----------|
| `HpcFormStoreRequest` | HpcFormController@store | student_id, template_id, academic_session_id, term_id, class_id, section_id |
| `HpcGeneratePdfRequest` | HpcPdfController@generateBulk | student_ids (array, max:50), academic_term_id |
| `HpcSendEmailRequest` | HpcEmailController@send | student_id (required), academic_term_id |
| `HpcBulkEmailRequest` | HpcEmailController@sendBulk | student_ids (array, max:100), academic_term_id |
| `HpcWorkflowApproveRequest` | workflow approve | comments (nullable, max:2000) |
| `HpcWorkflowSendBackRequest` | workflow send-back | comments (required, min:10, max:2000) |
| `ParentLinkGenerateRequest` | teacher generate-parent-link | guardian_id (nullable, integer) |
| `ParentCommentRequest` | parent/teacher comment | message (required, string, max:1000) |
| `PeerAssignRequest` | teacher assign-peers | class_section_id (required), template_id (required, in:1,2,3,4) |

#### P1-02: Add Missing Policies (GAP-POL-001)

12 controllers lack dedicated policies. Priority targets:
- `HpcFormPolicy` — covers HpcFormController (form view/save ownership check)
- `HpcPdfPolicy` — covers HpcPdfController (PDF generation gate)
- `HpcWorkflowPolicy` — covers workflow transitions per role
- `StudentHpcFormPolicy` — covers StudentHpcFormController (student owns report)
- `PeerAssignmentPolicy` — covers PeerHpcFormController (peer is assigned)

#### P1-03: Fix DDL Gaps

Required DDL migrations to create missing tables:

```sql
-- Migration 1: hpc_credit_config
CREATE TABLE IF NOT EXISTS `hpc_credit_config` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `grade_code` VARCHAR(10) NOT NULL,
  `credit_value` DECIMAL(5,2) NOT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Migration 2: hpc_parent_form_tokens
-- Migration 3: hpc_peer_assignments
-- Migration 4: hpc_peer_responses
-- Migration 5: hpc_report_comments
-- Migration 6: ALTER student_form_submissions → RENAME TO hpc_student_form_submissions
-- Migration 7: ALTER hpc_reports.status ENUM — add 'submitted', 'under_review'
```

#### P1-04: Rate Limiting on Bulk Operations

Add `throttle:1,10` (1 request per 10 minutes) to bulk email route.
Add `throttle:3,1` (3 per minute) to bulk PDF route.

### 14.4 P2 — Medium Priority

#### P2-01: Extract PDF Logic from Controller to Service

`HpcReportService` should gain a `generatePdf(HpcReport $report): string` method. The 4-template
if/elseif chain in the controller (lines ~2508-2573) should move to a template factory pattern:

```php
// Proposed pattern
class HpcPdfFactory {
    public static function getView(int $templateId): string {
        return match($templateId) {
            1 => 'hpc::pdf.first_pdf',
            2 => 'hpc::pdf.second_pdf',
            3 => 'hpc::pdf.third_pdf',
            4 => 'hpc::pdf.fourth_pdf',
            default => 'hpc::pdf.default_pdf',
        };
    }
}
```

#### P2-02: Cache Template Hierarchies

Wrap template loads in `Cache::remember('hpc_template_{id}', 86400, fn() => ...)`.
Invalidate cache on template update/delete.

#### P2-03: Queue Bulk PDF Generation

Create `GenerateHpcReportsBulkJob` implementing ShouldQueue. Controller dispatches job and
returns immediate JSON `{ message: "Generation started", job_id: "..." }`. Add status polling
endpoint `GET /hpc/generation-status/{job_id}`.

#### P2-04: Complete Feature Test Suite

Target: 60+ test scenarios covering:
- Form submission pipeline (all 7 field types)
- PDF generation (single + bulk)
- Workflow transitions
- Token expiry and replay prevention
- Role-based field filtering
- Rate limiting

#### P2-05: Fix Empty Stub Methods

`HpcController::store()`, `update()`, and `destroy()` are empty stubs with only a Gate check.
Either implement proper logic or return `abort(405, 'Method Not Allowed')` to prevent silent
no-ops.

### 14.5 P3 — Low Priority

- Translate Hindi comment at HpcController line 171 to English
- Remove any `dd()` / `var_dump()` debug calls in production code
- Optimize illness detection in HpcAttendanceService with compiled regex instead of string loop
- Cache `Organization::first()` call during PDF generation (PERF-HPC-006)
- Consolidate duplicated PDF view selection across `generateSingleStudentPdf()` and
  `generateReportPdf()` using `HpcPdfFactory`

---

## 15. Appendices

### 15.1 Controllers Inventory

| Controller | Lines | Purpose | Status |
|------------|-------|---------|--------|
| `HpcController` | 2,610 | God controller — index, form, PDF, email, workflow | Active (split required) |
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
| `KnowledgeGraphValidationController` | ~150 | CRUD for knowledge graph issues | Done |
| `TopicEquivalencyController` | 296 | CRUD for topic equivalency | Done |
| `SyllabusCoverageSnapshotController` | 275 | CRUD for coverage snapshots | Done |
| `QuestionMappingController` | 195 | CRUD for outcome-question mapping | Done |
| `StudentGoalsController` | 205 | Goals & aspirations wizard (T4) | Done |
| `HpcCreditConfigController` | ~100 | NCrF credit configuration | Done (DDL gap) |
| `HpcAttendanceController` | ~120 | Attendance configuration view | Done |
| `HpcActivityAssessmentController` | ~80 | Multi-actor activity view | Partial |

### 15.2 Services Inventory

| Service | Lines | Purpose |
|---------|-------|---------|
| `HpcReportService` | 870 | Core save/load pipeline; getSavedValues(); saveReport(); resolveTemplateId() |
| `PeerAssignmentService` | 275 | Auto-assign peers; save/complete responses; completion matrix |
| `HpcLmsIntegrationService` | 234 | Auto-feed homework/exam/quiz data into report fields |
| `HpcCreditCalculatorService` | 227 | NCrF credit calculation and form field mapping |
| `HpcAttendanceService` | 211 | Working days config; reason categorization; month grouping |
| `HpcWorkflowService` | 163 | State machine: submit/review/approve/sendBack/publish/archive |
| `StudentHpcFormService` | 167 | Student page filtering; progress tracking; markComplete |
| `HpcSectionRoleService` | ~150 | Role-based field filtering (teacher/student/parent/peer) |
| `HpcDataMappingService` | ~130 | Map hpc_student_evaluation data to report form fields |
| `ParentHpcFormService` | ~120 | Token generation/validation; parent response storage; completion |

### 15.3 Models Inventory (32 total)

| Model | Table | Key Notes |
|-------|-------|-----------|
| `HpcReport` | hpc_reports | 6-state status; Spatie MediaLibrary; TRANSITIONS constant |
| `HpcReportItem` | hpc_report_items | input/output column pairs per field type |
| `HpcReportTable` | hpc_report_table | Grid cell storage for table sections |
| `HpcReportComment` | hpc_report_comments | Parent-teacher bidirectional comments |
| `HpcTemplates` | hpc_templates | applicable_to_grade as JSON |
| `HpcTemplateParts` | hpc_template_parts | page_no; has_items flag |
| `HpcTemplateSections` | hpc_template_sections | has_items flag; special code 'ATTENDANCE' |
| `HpcTemplateRubrics` | hpc_template_rubrics | mandatory/visible/print flags |
| `HpcTemplateRubricItems` | hpc_template_rubric_items | html_object_name; 7 input types |
| `HpcTemplateSectionItems` | hpc_template_section_items | section_type: Text/Image/Table |
| `HpcTemplatePartsItems` | hpc_template_parts_items | part-level items |
| `HpcTemplateSectionTable` | hpc_template_section_table | Grid cell definitions |
| `HpcParameters` | hpc_ability_parameters | AWARENESS/SENSITIVITY/CREATIVITY |
| `HpcPerformanceDescriptor` | hpc_performance_descriptors | BEGINNER/PROFICIENT/ADVANCED |
| `HpcCreditConfig` | hpc_credit_config | NCrF defaults; DDL missing |
| `HpcLevels` | hpc_levels | Legacy table — verify if still used |
| `CircularGoals` | hpc_circular_goals | FK sch_classes |
| `CircularGoalCompetencyJnt` | hpc_circular_goal_competency_jnt | M:N goals ↔ competencies |
| `LearningOutcomes` | hpc_learning_outcomes | Bloom taxonomy; domain |
| `OutcomesEntityJnt` | hpc_outcome_entity_jnt | Polymorphic: SUBJECT/LESSON/TOPIC |
| `OutcomesQuestionJnt` | hpc_outcome_question_jnt | outcome ↔ question bank |
| `LearningActivities` | hpc_learning_activities | Evidence sources for evaluation |
| `LearningActivityType` | hpc_learning_activity_type | PROJECT/OBSERVATION/FIELD_WORK etc. |
| `StudentHpcEvaluation` | hpc_student_evaluation | ASC framework per student/subject |
| `KnowledgeGraphValidation` | hpc_knowledge_graph_validation | Issue severity tracking |
| `TopicEquivalency` | hpc_topic_equivalency | Cross-syllabus topic mapping |
| `SyllabusCoverageSnapshot` | hpc_syllabus_coverage_snapshot | Coverage % per session/class/subject |
| `ParentFormToken` | hpc_parent_form_tokens | UUID token; expires_at; DDL missing |
| `PeerAssignment` | hpc_peer_assignments | Peer reviewer assignments; DDL missing |
| `PeerResponse` | hpc_peer_responses | Peer review field responses; DDL missing |
| `StudentFormSubmission` | student_form_submissions | Student per-page progress; DDL missing |
| `StudentHpcSnapshot` | hpc_student_hpc_snapshot | Point-in-time report snapshots |

### 15.4 Existing FormRequests (14)

| FormRequest | Controller |
|------------|-----------|
| `CircularGoalsRequest` | CircularGoalsController |
| `HpcParametersRequest` | HpcParametersController |
| `HpcPerformanceDescriptorRequest` | HpcPerformanceDescriptorController |
| `HpcTemplatePartsRequest` | HpcTemplatePartsController |
| `HpcTemplatesRequest` | HpcTemplatesController |
| `HpcTemplateRubricsRequest` | HpcTemplateRubricsController |
| `HpcTemplateSectionsRequest` | HpcTemplateSectionsController |
| `KnowledgeGraphValidationRequest` | KnowledgeGraphValidationController |
| `LearningActivitiesRequest` | LearningActivitiesController |
| `LearningOutcomesRequest` | LearningOutcomesController |
| `QuestionMappingRequest` | QuestionMappingController |
| `StudentHpcEvaluationRequest` | StudentHpcEvaluationController |
| `SyllabusCoverageSnapshotRequest` | SyllabusCoverageSnapshotController |
| `TopicEquivalencyRequest` | TopicEquivalencyController |

### 15.5 Jobs & Mail

| Class | Type | Config |
|-------|------|--------|
| `SendHpcReportEmail` | ShouldQueue | 3 retries, 120s timeout; re-initializes tenancy context |
| `HpcReportMail` | Mailable | Renders link + access code + expiry date for guardian |

### 15.6 Security Findings Summary

| ID | Severity | Issue | Fix Priority |
|----|----------|-------|-------------|
| SEC-HPC-001 | CRITICAL | No EnsureTenantHasModule middleware | P0 |
| SEC-HPC-002 | HIGH | hpc-view route publicly accessible | P0 |
| SEC-HPC-003 | HIGH | Parent routes rely solely on token — verify expiry/revocation | P1 |
| SEC-HPC-004 | MEDIUM | student_id guessable integer — no ownership check | P0 |
| SEC-HPC-005 | MEDIUM | Bulk email — no rate limiting | P1 |
| SEC-HPC-006 | MEDIUM | Download ZIP — path traversal protection needed | P1 |
| SEC-HPC-007 | LOW | Debug comments (dd calls) in production code | P3 |

---

## 16. V1 to V2 Delta

### 16.1 New Functional Requirements Added in V2

| FR ID | Title | Rationale |
|-------|-------|-----------|
| FR-HPC-012.9 | Bulk PDF via queue job | Prevent timeout on large classes |
| FR-HPC-012.10 | Cache Organization per request | Performance optimization |
| FR-HPC-013.9 | Workflow state change notifications | Complete TODO stubs |
| FR-HPC-014.9 | Rate limiting on bulk email | Security — prevent email flooding |
| FR-HPC-015.3 | SnapshotController | Implement missing controller for existing table |
| FR-HPC-015.4 | Snapshot trend comparison view | New analytics capability |
| FR-HPC-019 | Curriculum Change Request workflow | Implement existing DDL table |

### 16.2 Issues Identified in V2 Not in V1

| Issue | Source | Severity |
|-------|--------|---------|
| `hpc_reports.status` ENUM in DDL (4 values) != model (6 values) | DDL scan | HIGH |
| `hpc_report_comments` table missing from DDL | DDL scan | HIGH |
| `hpc_circular_goal_competency_jnt` FK references `slb_circular_goals` — likely typo (should be `hpc_circular_goals`) | DDL scan | MEDIUM |
| `student_form_submissions` table lacks `hpc_` prefix | DDL scan | MEDIUM |
| `hpc_lesson_version_control` at DDL line 5185 — isolated from HPC block | DDL scan | LOW |
| `HpcController::store()`, `update()`, `destroy()` are empty stubs | Code scan | MEDIUM |
| Hindi comment in HpcController line 171 | Code scan | LOW |
| `HpcLevels` model references `hpc_levels` — legacy table not in DDL | Code scan | LOW |
| Unit tests at `tests/Unit/Hpc/` (6 files, 393 lines) — V1 gap analysis claimed 0 tests | Code scan | — |

### 16.3 Status Changes from V1

| Dimension | V1 Status | V2 Status | Change |
|-----------|-----------|-----------|--------|
| Unit Tests | 0 (gap analysis) | 6 files, 393 lines | Tests discovered in code |
| Workflow state machine | Done | Done + test-verified | 10 workflow tests confirmed |
| PDF Generation | Done | Done (security fix needed) | Public route identified |
| Overall Completion | ~59% | ~59% | Same — new gaps offset by tests found |

### 16.4 Architecture Decisions Carried Forward

| Decision | Description |
|----------|-------------|
| D18 | $hpcData pattern — `$savedValues` and `$savedTableData` keyed by `html_object_name` |
| D22 | Email sends URL link, not PDF attachment |
| New | HpcPdfFactory proposed for template view selection |
| New | `HpcFormController` + `HpcPdfController` + `HpcEmailController` decomposition proposed |

