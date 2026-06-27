# Module Knowledge: HPC (Holistic Progress Card)
# Last Updated: 2026-06-27
# Completion Status: ~59% — Active implementation (core form, PDF, workflow done; multi-actor views partial)

---

## Module Facts

| Item | Value |
|------|-------|
| Full name | Holistic Progress Card |
| Module code | HPC |
| Table prefix | `hpc_*` |
| DDL (canonical v2) | `2-DDL_Tenant_Consolidated/HPC_DDL_v2.sql` — 11 tables (Template + Report layers only) |
| DDL (HPC extensions) | `1-DDL_Modules/HPC/Old_DDL/syllabus_HPC_v1.1.sql` — 14 additional tables (Curriculum Analytics + ASC + Snapshot layers) |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/HPC_Hpc_Requirement.md` |
| Scope | Tenant (database-per-tenant; no tenant_id columns) |
| Framework alignment | NEP 2020 / PARAKH-compliant holistic assessment |
| Controllers | 22 (HpcController is 2,610-line god controller — split required) |
| Models | 32 (including 6 with DDL missing) |
| Services | 10 implemented |
| FormRequests | 14 existing; 9 missing (GAP-FR-001 through GAP-FR-009) |
| Functional Requirements | 19 (FR-HPC-001 through FR-HPC-019) |
| Business Rules | 12 (BR-HPC-001 through BR-HPC-012) |
| FRD status | Not yet generated |
| Overall completion | ~59% |
| NEP grade bands covered | 4 (Foundational, Preparatory, Middle, Secondary) |
| PDF templates | 4 Blade views (first_form/second_form/third_form/fourth_form) via DomPDF v3.1 |

---

## DDL Layer Structure

The HPC DDL spans two files — the v2 consolidated file (core HPC) and the `syllabus_HPC_v1.1.sql` extension file (curriculum analytics + ASC + snapshot). Together they define 25 tables in DDL (plus 7 missing from DDL but used in code).

| Layer | Tables | Source File |
|-------|--------|-------------|
| Layer 1 — Template Masters (no hpc_* deps) | `hpc_templates`, `hpc_ability_parameters`, `hpc_performance_descriptors`, `hpc_learning_activity_type`, `hpc_circular_goals` | HPC_DDL_v2.sql + syllabus_HPC_v1.1.sql |
| Layer 2 — Template Structure (dep Layer 1) | `hpc_template_parts`, `hpc_template_sections`, `hpc_template_rubrics`, `hpc_learning_outcomes`, `hpc_topic_equivalency`, `hpc_syllabus_coverage_snapshot` | HPC_DDL_v2.sql + syllabus_HPC_v1.1.sql |
| Layer 3 — Template Detail (dep Layer 2) | `hpc_template_parts_items`, `hpc_template_section_items`, `hpc_template_rubrics` (section_id FK), `hpc_circular_goal_competency_jnt`, `hpc_outcome_entity_jnt`, `hpc_knowledge_graph_validation`, `hpc_learning_activities` | HPC_DDL_v2.sql + syllabus_HPC_v1.1.sql |
| Layer 4 — Template Leaf (dep Layer 3) | `hpc_template_section_table`, `hpc_template_rubric_items`, `hpc_outcome_question_jnt` | HPC_DDL_v2.sql + syllabus_HPC_v1.1.sql |
| Layer 5 — Report Base (dep Layer 1 + cross-module) | `hpc_reports`, `hpc_student_evaluation`, `hpc_student_hpc_snapshot` | HPC_DDL_v2.sql + syllabus_HPC_v1.1.sql |
| Layer 6 — Report Detail (dep Layer 5) | `hpc_report_items`, `hpc_report_table` | HPC_DDL_v2.sql |
| Missing from DDL (models + code exist) | `hpc_credit_config`, `hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses`, `hpc_report_comments`, `student_form_submissions` | — DDL GAP — |
| Isolated / orphaned (in Syllabus DDL) | `hpc_curriculum_change_request`, `hpc_lesson_version_control` | `2-DDL_Tenant_Consolidated/Syllabus_DDL_v1.1.sql` |

---

## Feature Groups

| FR | Feature | Tables | Priority |
|----|---------|--------|----------|
| FR-HPC-001 | Template Management (CRUD for 4 hierarchy levels) | `hpc_templates`, `hpc_template_parts`, `hpc_template_sections`, `hpc_template_rubrics`, `hpc_template_rubric_items`, `hpc_template_section_items`, `hpc_template_section_table`, `hpc_template_parts_items` | Critical |
| FR-HPC-002 | HPC Parameter Configuration (ASC ability + BPD descriptors) | `hpc_ability_parameters`, `hpc_performance_descriptors` | Critical |
| FR-HPC-003 | Circular Goals & Competency Mapping | `hpc_circular_goals`, `hpc_circular_goal_competency_jnt` | High |
| FR-HPC-004 | Learning Outcomes & Question Mapping | `hpc_learning_outcomes`, `hpc_outcome_entity_jnt`, `hpc_outcome_question_jnt` | High |
| FR-HPC-005 | Learning Activities | `hpc_learning_activities`, `hpc_learning_activity_type` | High |
| FR-HPC-006 | Curriculum Analytics (graph validation, topic equivalency, coverage) | `hpc_knowledge_graph_validation`, `hpc_topic_equivalency`, `hpc_syllabus_coverage_snapshot` | Medium |
| FR-HPC-007 | Student HPC Evaluation (ASC Framework) | `hpc_student_evaluation` | Critical |
| FR-HPC-008 | Teacher Data Entry Form (multi-page, 7 input types) | `hpc_reports`, `hpc_report_items`, `hpc_report_table` | Critical |
| FR-HPC-009 | Student Self-Assessment Portal | `hpc_reports` (student_sections_complete), `student_form_submissions` | High |
| FR-HPC-010 | Parent Input Collection (token-based) | `hpc_parent_form_tokens`, `hpc_report_comments`, `hpc_reports` (parent_sections_complete) | High |
| FR-HPC-011 | Peer Assessment Workflow | `hpc_peer_assignments`, `hpc_peer_responses` | High |
| FR-HPC-012 | PDF Report Generation (DomPDF, 4 templates, bulk ZIP) | `hpc_report_items`, `hpc_report_table`, `hpc_reports` | Critical |
| FR-HPC-013 | Approval Workflow (6-state machine) | `hpc_reports` (status + audit timestamps) | Critical |
| FR-HPC-014 | Email Distribution (queued job, URL link, not PDF attachment) | `hpc_reports` | High |
| FR-HPC-015 | Student HPC Snapshot | `hpc_student_hpc_snapshot` | Medium |
| FR-HPC-016 | Attendance Configuration (working days per month) | `sys_settings` key `hpc_working_days_per_month` | High |
| FR-HPC-017 | NCrF Credit Configuration | `hpc_credit_config` (DDL MISSING) | High |
| FR-HPC-018 | Activity Assessment Overview | `hpc_reports`, `hpc_peer_assignments`, `hpc_parent_form_tokens` | Medium |
| FR-HPC-019 | Curriculum Change Request Workflow | `hpc_curriculum_change_request` (isolated in Syllabus DDL) | Low |

---

## DDL Gaps

Tables referenced in the requirement but NOT defined in `HPC_DDL_v2.sql` or `syllabus_HPC_v1.1.sql`:

| Table | Severity | Gap ID | Models / Code Using It | Notes |
|-------|----------|--------|------------------------|-------|
| `hpc_credit_config` | P0 | GAP-DB-002 | `HpcCreditConfig`, `HpcCreditConfigController`, `HpcCreditCalculatorService` | Controller and service are production-active; DDL migration required immediately |
| `hpc_report_comments` | P0 | GAP-DB-004a | `HpcReportComment` model, `ParentHpcFormController` | Bidirectional parent-teacher comment thread; blocks FR-HPC-010.7 |
| `hpc_parent_form_tokens` | P0 | GAP-DB-004b | `ParentFormToken`, `ParentHpcFormController`, `ParentHpcFormService` | Token-based parent access is actively used in production |
| `hpc_peer_assignments` | P0 | GAP-DB-004c | `PeerAssignment`, `PeerHpcFormController`, `PeerAssignmentService` | Peer review workflow cannot function without this table |
| `hpc_peer_responses` | P0 | GAP-DB-004d | `PeerResponse`, `PeerHpcFormController` | Peer reviewer answers stored here; missing from all DDL files |
| `student_form_submissions` | P1 | GAP-DB-005 | `StudentFormSubmission`, `StudentHpcFormService` | Missing `hpc_` prefix AND missing from DDL; should be renamed `hpc_student_form_submissions` |

Additional DDL issues in existing tables:

| Table | Issue | Gap ID | Severity |
|-------|-------|--------|----------|
| `hpc_reports.status` | DDL ENUM has only 4 values ('Draft','Final','Published','Archived'); model uses 6 ('draft','submitted','under_review','final','published','archived') | GAP-DB-003 | P0 |
| `hpc_reports` FK `term_id` | DDL references `cbse_terms(id)` — legacy table; should reference `sch_academic_term(id)` | DDL-CORR-001 | P0 |
| `hpc_circular_goal_competency_jnt` FK | References `slb_circular_goals(id)` — wrong table; should be `hpc_circular_goals(id)` | DDL-CORR-002 | P1 |
| `hpc_outcome_entity_jnt` | FK `fk_outcome_entity_outcome` references `slb_learning_outcomes(id)` — should be `hpc_learning_outcomes(id)` | DDL-CORR-003 | P1 |
| `hpc_outcome_question_jnt` | FK references `slb_learning_outcomes(id)` — should be `hpc_learning_outcomes(id)` | DDL-CORR-004 | P1 |
| `hpc_student_evaluation` | FKs reference `slb_academic_sessions`, `slb_students`, `slb_subjects`, `slb_users` — all should be `std_*` / `sch_*` / `sys_*` equivalents | DDL-CORR-005 | P0 |
| `hpc_syllabus_coverage_snapshot` | FK references `slb_academic_sessions(id)` — should be `sch_org_academic_sessions_jnt(id)` (SMALLINT UNSIGNED PK) | DDL-CORR-006 | P0 |
| `hpc_student_hpc_snapshot` | FK references `slb_academic_sessions(id)` — should be `sch_org_academic_sessions_jnt(id)` | DDL-CORR-007 | P0 |
| `hpc_report_items.id` | Defined as `BIGINT AUTO_INCREMENT` — platform standard is `INT UNSIGNED AUTO_INCREMENT`; correct to INT | DDL-CORR-008 | P1 |
| `hpc_curriculum_change_request`, `hpc_lesson_version_control` | Defined in Syllabus DDL (`Syllabus_DDL_v1.1.sql`), not in HPC DDL; should be moved to HPC DDL | GAP-DB-001 | P1 |

---

## DDL Corrections & Platform Deviations

| # | Table.Column | DDL Value | Correct Value | Reason |
|---|-------------|-----------|---------------|--------|
| 1 | `hpc_reports.term_id` FK | `cbse_terms(id)` | `sch_academic_term(id)` | `cbse_terms` is a legacy table not in current schema |
| 2 | `hpc_reports.status` ENUM | `'Draft','Final','Published','Archived'` | `'draft','submitted','under_review','final','published','archived'` | Model uses 6 states; DDL is out of sync; casing also wrong (lowercase per PHP model convention) |
| 3 | `hpc_reports.prepared_by` FK | `sys_users(id)` | `sys_users(id)` — correct | No change needed here |
| 4 | `hpc_report_items.id` | `BIGINT AUTO_INCREMENT` | `INT UNSIGNED AUTO_INCREMENT` | Platform standard is INT UNSIGNED for all PKs/FKs (verified against tenant_db) |
| 5 | `hpc_circular_goal_competency_jnt.circular_goal_id` FK | `slb_circular_goals(id)` | `hpc_circular_goals(id)` | FK must point to HPC's own goals table, not Syllabus module's non-existent `slb_circular_goals` |
| 6 | `hpc_outcome_entity_jnt.outcome_id` FK | `slb_learning_outcomes(id)` | `hpc_learning_outcomes(id)` | Outcome is defined in HPC, not in Syllabus module |
| 7 | `hpc_outcome_question_jnt.outcome_id` FK | `slb_learning_outcomes(id)` | `hpc_learning_outcomes(id)` | Same issue as above |
| 8 | `hpc_student_evaluation.academic_session_id` FK | `slb_academic_sessions(id)` | `sch_org_academic_sessions_jnt(id)` (SMALLINT UNSIGNED) | Platform uses `sch_org_academic_sessions_jnt` for academic session reference; `slb_academic_sessions` does not exist |
| 9 | `hpc_student_evaluation.student_id` FK | `slb_students(id)` | `std_students(id)` | Students are in `std_students`, not `slb_students` |
| 10 | `hpc_student_evaluation.assessed_by` FK | `slb_users(id)` | `sys_users(id)` | Platform user table is `sys_users` |
| 11 | `hpc_syllabus_coverage_snapshot.academic_session_id` FK | `slb_academic_sessions(id)` | `sch_org_academic_sessions_jnt(id)` | Same platform correction as #8 |
| 12 | `hpc_student_hpc_snapshot.academic_session_id` FK | `slb_academic_sessions(id)` | `sch_org_academic_sessions_jnt(id)` | Same platform correction |
| 13 | `hpc_student_evaluation` (multiple FKs) | Reference `slb_subjects`, `slb_competencies` | `sch_subjects(id)`, `slb_competencies(id)` | Subjects in `sch_subjects` not `slb_subjects` |
| 14 | `hpc_learning_outcomes.domain` FK | `sys_dropdown_table(id)` | `sys_dropdown_table(id)` — correct type, but missing comma before CONSTRAINT in DDL syntax | Syntax error — missing comma before CONSTRAINT `fk_lo_domain` |
| 15 | `hpc_reports` — missing columns | DDL lacks: `submitted_at`, `reviewed_by`, `reviewed_at`, `review_comments`, `published_by`, `published_at`, `student_sections_complete`, `parent_sections_complete` | Add all 8 columns | Required by approval workflow and multi-actor tracking |

---

## Key Design Decisions

1. **$hpcData pattern (Decision D18)**: PDF Blade templates consume `$hpcData` containing `$savedValues` (keyed by `html_object_name`, lowercased) and `$savedTableData` (grid cell values). This makes all 4 PDF templates template-agnostic — no hard-coded field lookups in PHP. `html_object_name` is the universal key across form HTML, storage, and PDF rendering.

2. **Report storage in separate tables, not in `hpc_reports`**: `hpc_reports` stores only the header (student, session, term, template, status, audit timestamps). All field values go to `hpc_report_items` (key-value with typed columns) or `hpc_report_table` (grid cells). This allows any template to work without DDL changes.

3. **7-input-type storage pattern in `hpc_report_items`**: Each row stores one field's input AND output values across 8 typed column pairs (numeric, text, boolean, selected, image, filename, filepath, json) plus `remark`. The correct column is selected by the `input_type` of the associated `hpc_template_rubric_items` record. The pair approach enables auditable before/after comparison.

4. **Email sends URL link, not PDF attachment (Decision D22)**: `SendHpcReportEmail` job sends a web view URL (`hpc.hpc-form.view` route with encrypted student_id) plus an access code (`HPC-{studentId}-{guardianId}-{sha1_8chars}`). This reduces email size, allows live report viewing, and avoids attachment storage overhead.

5. **Parent access via UUID token, not login**: `hpc_parent_form_tokens` stores a UUID with `expires_at` (7-day TTL) and `completed_at`. Parent routes sit outside the auth middleware group intentionally. Token expiry and replay prevention must be validated server-side on every request (GET and POST).

6. **Tenant job re-initialization**: `SendHpcReportEmail` (ShouldQueue) calls `tenancy()->initialize($this->tenantId)` on handle and `tenancy()->end()` in a `finally` block to re-enter the correct tenant database context after queue worker picks up the job.

7. **Attendance computed twice**: Attendance data from `std_student_attendance` is aggregated on form load (pre-fill) AND re-computed at PDF generation time. This ensures accuracy even if attendance was updated after the form was last saved. `HpcAttendanceService::MONTH_ORDER` uses April-to-March Indian academic year ordering.

8. **Template hierarchy drives the form**: The teacher data entry form is entirely data-driven from `hpc_template_parts` (pages/tabs), `hpc_template_sections` (content blocks), and `hpc_template_rubrics` (scored fields). No page structure is hard-coded in PHP. Each tab = one `page_no` from `hpc_template_parts`.

9. **`updateOrCreate()` on form save**: `HpcReportService::saveReport()` calls `updateOrCreate` with the UNIQUE key `(academic_session_id, term_id, student_id)` to ensure one report per student per term. This enforces BR-HPC-002 at the application layer, with the database UNIQUE constraint as a safety net.

10. **Encrypted student_id for public PDF view**: `GET /hpc/hpc-view/{student_id?}` accepts both `Crypt::encryptString($studentId)` (email link, public route) and plain integer (authenticated teacher preview). This dual-mode access creates the SEC-HPC-002 vulnerability — encrypted-ID-only is insufficient protection.

11. **Peer assignment constraint algorithm**: `PeerAssignmentService::autoAssignPeers()` uses shuffled selection with two hard constraints: no self-review (`peer_student_id != student_id`), no review cycles (if A reviews B, B must not review A in the same cycle). Template 2 assigns 2 peers per student; Templates 3 and 4 assign 1 peer per activity cycle (9 cycles T3; 8 cycles T4).

12. **NCrF credit defaults as code constants**: If no `hpc_credit_config` records exist for a school, `HpcCreditCalculatorService` uses national defaults built into the service as constants (BV1=0.05 through Gr12=4.5). School-specific overrides in `hpc_credit_config` override per grade code.

13. **`has_items` flag drives storage routing**: Both `hpc_template_parts` and `hpc_template_sections` have a `has_items` flag. When `has_items=1` on a part, `hpc_template_parts_items` is used. When `has_items=0`, the part is a container for sections only. Sections can have both items AND rubrics simultaneously.

14. **4 separate Blade form views**: Template selection maps to `first_form`, `second_form`, `third_form`, `fourth_form` Blade views (not one generic view). `HpcReportService::resolveTemplateId()` maps student class ordinal to template ID. PDF generation has a parallel 4-template if/elseif chain that should be refactored to `HpcPdfFactory::getView(int $templateId)`.

15. **Bulk PDF is synchronous with 50-student hard limit**: Current implementation loops synchronously. Until `GenerateHpcReportsBulkJob` (FR-HPC-012.9) is implemented, a hard limit of 50 students per request (BR-HPC-009) must be enforced to prevent PHP 30s timeout.

16. **ZIP streaming with deleteFileAfterSend(true)**: Bulk PDF ZIP files are written to `storage/app/public/hpc-reports/zip/` then streamed with `deleteFileAfterSend(true)` — the file is deleted after download. The `downloadZip()` endpoint must sanitize the filename parameter to alphanumeric + underscore + hyphen + dot only (BR-HPC-011).

---

## Business Rules

| BR ID | Rule Summary | Enforcement Point |
|-------|-------------|-------------------|
| BR-HPC-001 | Template-to-grade assignment is resolved by `HpcReportService::resolveTemplateId()` from student's class ordinal; changing class mid-term does not auto-change template | `HpcReportService::resolveTemplateId()` |
| BR-HPC-002 | At most one HPC report per student per academic term; UNIQUE on `(academic_session_id, term_id, student_id)` | DB UNIQUE constraint + `updateOrCreate()` in `HpcReportService::saveReport()` |
| BR-HPC-003 | Each template section/rubric has an implicit actor owner (teacher/student/parent/peer); submitted fields not belonging to the actor's role are stripped and logged | `HpcSectionRoleService::filterPayloadByRole()` in all actor form controllers |
| BR-HPC-004 | `HpcReport::TRANSITIONS` defines all valid state transitions; invalid transitions return HTTP 422; published and archived are terminal states with no rollback | `HpcWorkflowService` — all transition methods |
| BR-HPC-005 | Parent form tokens expire 7 days after creation; every request (GET + POST) must verify token not expired AND not previously completed (`completed_at` is null); completed tokens cannot be reused | `ParentHpcFormController` / `ParentHpcFormService` |
| BR-HPC-006 | Peer assignment must prevent self-review and avoid A→B + B→A cycles in the same cycle; auto-assignment uses shuffled selection | `PeerAssignmentService::autoAssignPeers()` |
| BR-HPC-007 | Attendance aggregated April-to-March (Indian academic year); `HpcAttendanceService::MONTH_ORDER` defines this; re-computed at both form load and PDF generation | `HpcAttendanceService::aggregateAttendance()` |
| BR-HPC-008 | LMS data feed (`HpcLmsIntegrationService::getAllLmsData()`) must use try/catch with graceful fallback; if LMS modules absent or have no data, form opens with empty LMS sections (no exception) | `HpcLmsIntegrationService::getAllLmsData()` |
| BR-HPC-009 | Bulk PDF generation hard limit: 50 students per request until queue job (FR-HPC-012.9) implemented; enforce via FormRequest validation | `HpcGeneratePdfRequest` (to be created) |
| BR-HPC-010 | Guardian emails receive a view URL, not a PDF attachment; access code format: `HPC-{studentId}-{guardianId}-{sha1_8chars}`; 30-day expiry is display-only, not enforced in URL | `SendHpcReportEmail` job |
| BR-HPC-011 | `downloadZip()` must sanitize filename: allow only alphanumeric, underscore, hyphen, dot; any other character causes 400 error | `HpcController::downloadZip()` (or future `HpcPdfController`) |
| BR-HPC-012 | If no school-specific `hpc_credit_config` rows exist, `HpcCreditCalculatorService` uses national NCrF defaults (BV1=0.05 … Gr12=4.5); school values override per grade code | `HpcCreditCalculatorService::calculateCredits()` |

---

## State Machine Summaries

| FSM | States | Terminal States |
|-----|--------|-----------------|
| HPC Report Approval (`hpc_reports.status`) | `draft` → `submitted` → `under_review` → `final` → `published` → `archived`; from `under_review` principal can send back to `submitted` or `draft` | `published`, `archived` |
| Parent Form Token | `pending` (token created, `completed_at` null) → `expired` (past `expires_at`) / `completed` (`completed_at` set); completed tokens are permanently locked | `expired`, `completed` |
| Peer Assignment (`hpc_peer_assignments.status`) | `pending` → `in_progress` → `completed` | `completed` |
| Student Section Completion (`hpc_reports.student_sections_complete`) | `false` (default) → `true` (set by `StudentHpcFormController::submit()`); Boolean flag, not a multi-state FSM | `true` |
| Parent Section Completion (`hpc_reports.parent_sections_complete`) | `false` (default) → `true` (set on parent final submission); Boolean flag | `true` |
| Curriculum Change Request (`hpc_curriculum_change_request.status`) | `DRAFT` → `SUBMITTED` → `APPROVED` / `REJECTED` | `APPROVED`, `REJECTED` |

---

## Cross-Module Dependencies

### Inbound (HPC reads from)

| Module | Tables / Channels | Data Used by HPC |
|--------|------------------|------------------|
| SchoolSetup (SCH) | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_academic_term`, `sch_org_academic_sessions_jnt` | Student class/section resolution, template mapping, term scoping |
| StudentProfile (STD) | `std_students`, `std_student_academic_sessions`, `std_student_attendance` | Student lookup, academic session FK, attendance aggregation |
| Syllabus (SLB) | `slb_competencies`, `slb_bloom_taxonomy`, `slb_topics`, `slb_lessons` | Circular goal competency mapping, learning outcome Bloom classification, topic-based activities |
| QuestionBank (QNS) | `qns_questions_bank` | Outcome-to-question weightage mapping (FR-HPC-004.3) |
| SystemConfig (SYS) | `sys_users`, `sys_dropdown_table`, `sys_settings` | Auth FKs (`created_by`, `assessed_by`, `prepared_by`), domain enums (evidence_type, entity_type), attendance working days config |
| LMS-Exam (EXM) | Auto-feed via `HpcLmsIntegrationService` | Exam scores pre-filled in report form fields; graceful fallback if absent |
| LMS-Quiz (QUZ) | Auto-feed via `HpcLmsIntegrationService` | Quiz results pre-filled; graceful fallback |
| LMS-Homework (HMW) | Auto-feed via `HpcLmsIntegrationService` | Homework completion pre-filled; graceful fallback |

### Outbound (What HPC writes / triggers)

| Module | What HPC Produces |
|--------|------------------|
| Email subsystem | `SendHpcReportEmail` job dispatches guardian emails with view link via Laravel Queue |
| Spatie MediaLibrary | File uploads on `HpcReport` model (`hpc_report_files` collection) |
| ZIP storage | Bulk PDF ZIPs written to `storage/app/public/hpc-reports/zip/` then deleted after download |
| Student Portal | Student self-assessment form (`StudentHpcFormController`) writes back to `hpc_report_items` |
| Parent Portal (token-based) | Parent form (`ParentHpcFormController`) writes to `hpc_report_items` and `hpc_report_comments` |

---

## Technology Stack Notes

| Package | Version | Usage in HPC |
|---------|---------|--------------|
| `barryvdh/laravel-dompdf` | ^3.1 | PDF generation for all 4 HPC template types (Blade → HTML → PDF) |
| `spatie/laravel-medialibrary` | Latest | File uploads attached to `HpcReport` model (`hpc_report_files` collection) |
| `stancl/tenancy` | v3.9 | Database-per-tenant isolation; `SendHpcReportEmail` job re-initializes tenancy context |
| `nwidart/laravel-modules` | v12 | Module structure for HPC |
| `ZipArchive` (PHP built-in) | — | Bulk PDF packaging to ZIP for download |
| `Crypt::encryptString()` (Laravel) | — | Encrypted student_id in emailed report view URLs |
| Laravel Queue | Database driver | `SendHpcReportEmail` job (3 retries, 120s timeout) |

**Key service dependencies:**
- `HpcReportService` (870 lines) — core pipeline: `getSavedValues()`, `saveReport()`, `resolveTemplateId()`
- `HpcWorkflowService` (163 lines) — state machine for 6-state approval workflow
- `HpcAttendanceService` (211 lines) — April-March working days aggregation
- `HpcCreditCalculatorService` (227 lines) — NCrF credit auto-calculation
- `HpcLmsIntegrationService` (234 lines) — LMS data feed with graceful fallback
- `PeerAssignmentService` (275 lines) — auto-assign + save + completion matrix
- `HpcSectionRoleService` (~150 lines) — role-based field filtering
- `HpcDataMappingService` (~130 lines) — evaluation-to-report field mapping
- `StudentHpcFormService` (167 lines) — student page filtering + progress tracking
- `ParentHpcFormService` (~120 lines) — token generation/validation + parent response

**Sys settings used:**
- `hpc_working_days_per_month` — JSON array of 12 integers (Apr–Mar); stored in `sys_settings`

---

## Implementation Blockers / Prerequisites

| # | Prerequisite | Owner Module | Blocks |
|---|-------------|-------------|--------|
| 1 | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_academic_term` complete | SchoolSetup (SCH) | FR-HPC-001 (template mapping), FR-HPC-003, FR-HPC-008 (form load) |
| 2 | `std_students`, `std_student_academic_sessions` complete | StudentProfile (STD) | FR-HPC-008 (form), FR-HPC-009 (student portal), FR-HPC-012 (PDF) |
| 3 | `std_student_attendance` complete and populated | StudentProfile (STD) | FR-HPC-008.7 and FR-HPC-016 (attendance auto-feed) |
| 4 | `sys_users` complete (INT UNSIGNED PK) | System (SYS) | All `created_by`, `assessed_by`, `prepared_by`, `reviewed_by`, `published_by` FKs |
| 5 | `slb_competencies`, `slb_topics`, `slb_lessons` complete | Syllabus (SLB) | FR-HPC-003, FR-HPC-004, FR-HPC-005, FR-HPC-006 |
| 6 | `qns_questions_bank` available | QuestionBank (QNS) | FR-HPC-004.3 (outcome-question mapping) — soft dependency |
| 7 | LMS-Exam, LMS-Quiz, LMS-Homework tables populated | LMS (EXM, QUZ, HMW) | FR-HPC-008.5 (LMS auto-feed) — soft dependency with graceful fallback |
| 8 | SEC-HPC-001 fix: Add `EnsureTenantHasModule:HPC` middleware | HPC (internal) | ALL authenticated HPC routes — P0 security blocker |
| 9 | GAP-DB-003 fix: Alter `hpc_reports.status` ENUM to 6 values + add 8 missing columns | HPC (internal DDL migration) | FR-HPC-009, FR-HPC-010, FR-HPC-013 (workflow logic references missing columns) |
| 10 | GAP-DB-004 fix: Create `hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses`, `hpc_report_comments` | HPC (internal DDL migration) | FR-HPC-010 (parent), FR-HPC-011 (peer) |
| 11 | GAP-DB-002 fix: Create `hpc_credit_config` | HPC (internal DDL migration) | FR-HPC-017 (NCrF credits) |
| 12 | Laravel Queue configured (database driver minimum) | DevOps / SYS | FR-HPC-014 (email dispatch) |

---

## Implementation Sequence

| Phase | Components | Notes |
|-------|-----------|-------|
| Phase 0 — DDL Corrections | Fix all P0 DDL corrections (FK corrections, status ENUM expansion, missing columns on `hpc_reports`); create 6 missing tables via migrations | Must happen before any feature development |
| Phase 1 — Security Fixes | Add `EnsureTenantHasModule:HPC` middleware (SEC-HPC-001); fix PDF view route (SEC-HPC-002); add student ownership check (SEC-HPC-004) | P0 — must fix before production |
| Phase 2 — Masters | `hpc_ability_parameters`, `hpc_performance_descriptors`, `hpc_learning_activity_type`, `hpc_templates` hierarchy (FR-HPC-001, FR-HPC-002) | Seeds for all subsequent work |
| Phase 3 — Curriculum Layer | `hpc_circular_goals`, `hpc_learning_outcomes`, `hpc_learning_activities`, `hpc_outcome_entity_jnt`, `hpc_outcome_question_jnt` (FR-HPC-003, FR-HPC-004, FR-HPC-005) | Requires SLB module complete |
| Phase 4 — Student Evaluation | `hpc_student_evaluation` CRUD (FR-HPC-007); fix `HpcDataMappingService` mapping completeness (~40% → 100%) | Feeds into teacher form |
| Phase 5 — Teacher Form | Multi-page teacher data entry form, form save pipeline, LMS auto-feed, NCrF credit calculation, attendance aggregation (FR-HPC-008) | Core HPC feature; depends on Phase 2–4 |
| Phase 6 — Approval Workflow | State machine already done; add 8 missing columns to `hpc_reports`; notification stubs (FR-HPC-013.9) | Fix DDL gap first |
| Phase 7 — PDF Generation | PDF already working; move bulk to queue job (FR-HPC-012.9); implement `HpcPdfFactory` | Performance improvement |
| Phase 8 — Multi-Actor | Parent token form (FR-HPC-010), student self-assessment (FR-HPC-009), peer assessment (FR-HPC-011); complete Blade views | Views not confirmed complete |
| Phase 9 — Email Distribution | Already working; add rate limiting (FR-HPC-014.9) | P1 security hardening |
| Phase 10 — Controller Split | Decompose `HpcController` into `HpcDashboardController`, `HpcFormController`, `HpcPdfController`, `HpcEmailController` (NFR-HPC-03) | Refactoring; 15-20h effort |
| Phase 11 — Test Coverage | Create 9 missing FormRequests; write 60+ feature test scenarios; minimum 60% service coverage (NFR-HPC-07, NFR-HPC-08) | Quality gate before release |
| Phase 12 — Analytics | `hpc_knowledge_graph_validation`, `hpc_topic_equivalency`, `hpc_syllabus_coverage_snapshot` (FR-HPC-006); snapshot controller (FR-HPC-015.3) | Lower priority analytics features |
| Phase 13 — Curriculum Change Request | Implement controller + approval workflow for `hpc_curriculum_change_request` (FR-HPC-019) | Table exists in Syllabus DDL; model and controller missing |

---

## Immutable / Special Records

| Table | Special Property | Reason |
|-------|-----------------|--------|
| `hpc_student_evaluation` | No `deleted_at` in old DDL (has `deleted_at` in extended DDL) | Assessment record — soft-delete via `is_active` flag only in old version |
| `hpc_student_hpc_snapshot` | `generated_at` is the primary timestamp; no `updated_at` semantic | Point-in-time snapshot — once generated, content should not be overwritten; UNIQUE on `(academic_session_id, student_id)` |
| `hpc_report_items` | Has `assessed_by` + `assessed_at` audit fields | Assessment records with auditor identity — should not be silently deleted |
| `hpc_parent_form_tokens` (missing from DDL) | `completed_at` set once and must not be cleared | Replay prevention — completed tokens are permanently locked |
| `hpc_knowledge_graph_validation` | `detected_at` is auto-set; `resolved_at` is set once on resolution | Audit trail for curriculum integrity issues |

---

## Security Findings (All Critical / High)

| ID | Severity | Issue | Fix |
|----|----------|-------|-----|
| SEC-HPC-001 | CRITICAL | No `EnsureTenantHasModule` middleware on HPC route group — any tenant can access HPC | Add `EnsureTenantHasModule:HPC` to route group in `routes/tenant.php` (30 min effort) |
| SEC-HPC-002 | HIGH | `GET /hpc/hpc-view/{student_id?}` is publicly accessible; encrypted ID is the only protection | Move behind auth middleware OR add Gate check + rate limiting (2-4h effort) |
| SEC-HPC-003 | HIGH | Parent routes rely solely on token — expiry and revocation must be enforced server-side on every request | Validate `expires_at` and `completed_at` checks in `ParentHpcFormController` middleware |
| SEC-HPC-004 | MEDIUM | `student_id` in HPC form is a guessable integer — no ownership check verifying teacher is class teacher | Add `Gate::authorize('tenant.hpc.form', $student)` check in `hpc_form()` |
| SEC-HPC-005 | MEDIUM | Bulk email endpoint has no rate limiting | Add `throttle:1,10` to bulk email route; max 100 students per request |
| SEC-HPC-006 | MEDIUM | Download ZIP `filename` parameter has potential path traversal | Validate: only `[a-zA-Z0-9_\-.]` allowed; return 400 otherwise |

---

## Pending Next Steps

- [ ] P0: Fix `hpc_reports` DDL — add 8 missing columns (`submitted_at`, `reviewed_by`, `reviewed_at`, `review_comments`, `published_by`, `published_at`, `student_sections_complete`, `parent_sections_complete`) and expand `status` ENUM to 6 values (lowercase)
- [ ] P0: Create 6 missing DDL migrations: `hpc_credit_config`, `hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses`, `hpc_report_comments`, `hpc_student_form_submissions` (renamed from `student_form_submissions`)
- [ ] P0: Fix FK: `hpc_reports.term_id` → `sch_academic_term(id)` (drop `cbse_terms` reference)
- [ ] P0: Fix FK: `hpc_circular_goal_competency_jnt.circular_goal_id` → `hpc_circular_goals(id)` (not `slb_circular_goals`)
- [ ] P0: Fix FKs in `hpc_student_evaluation` — replace all `slb_*` references with correct `std_*` / `sch_*` / `sys_*` equivalents
- [ ] P0: Fix FKs in `hpc_syllabus_coverage_snapshot` and `hpc_student_hpc_snapshot` — `slb_academic_sessions` → `sch_org_academic_sessions_jnt`
- [ ] P0: Correct `hpc_report_items.id` from `BIGINT` to `INT UNSIGNED`
- [ ] P0: Fix syntax error in `hpc_learning_outcomes` — add missing comma before `CONSTRAINT fk_lo_domain`
- [ ] P0: Add `EnsureTenantHasModule:HPC` middleware to HPC route group (SEC-HPC-001)
- [ ] P0: Secure `hpc-view/{student_id?}` route (SEC-HPC-002)
- [ ] P1: Move `hpc_curriculum_change_request` and `hpc_lesson_version_control` from Syllabus DDL to HPC DDL
- [ ] P1: Create 9 missing FormRequests (GAP-FR-001 through GAP-FR-009) — see Section 14.3 of requirement
- [ ] P1: Add 5 missing Policies — `HpcFormPolicy`, `HpcPdfPolicy`, `HpcWorkflowPolicy`, `StudentHpcFormPolicy`, `PeerAssignmentPolicy`
- [ ] P1: Add rate limiting to bulk email (`throttle:1,10`) and bulk PDF (`throttle:3,1`) routes
- [ ] P1: Complete missing Blade views — parent form, student self-assessment, peer review forms
- [ ] P1: Complete `HpcDataMappingService` evaluation-to-report field mapping (currently ~40%)
- [ ] P1: Implement workflow state change notifications (FR-HPC-013.9 — currently TODO stubs)
- [ ] P2: Decompose `HpcController` (2,610 lines) into 4 focused controllers (15-20h effort)
- [ ] P2: Move bulk PDF generation to `GenerateHpcReportsBulkJob` queued job (FR-HPC-012.9)
- [ ] P2: Implement `HpcPdfFactory::getView(int $templateId)` to replace 4-template if/elseif chains
- [ ] P2: Cache template hierarchies: `Cache::remember('hpc_template_{id}', 86400, ...)` (NFR-HPC-05)
- [ ] P2: Implement `SnapshotController` for `hpc_student_hpc_snapshot` (FR-HPC-015.3)
- [ ] P2: Implement `hpc_curriculum_change_request` model and workflow controller (FR-HPC-019)
- [ ] P2: Write 60+ feature test scenarios (TS-HPC-001 through TS-HPC-012) (NFR-HPC-07)
- [ ] P3: Translate Hindi comment at `HpcController` line 171 to English
- [ ] P3: Remove any `dd()` / `var_dump()` calls from production code
- [ ] P3: Implement or stub-out `HpcController::store()`, `update()`, `destroy()` empty methods (405 response)
- [ ] P3: Cache `Organization::first()` call during PDF generation (PERF-HPC-006)
- [ ] Generate FRD → `act as Business Analyst` → "create an FRD for HPC"

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (`HPC_Hpc_Requirement.md` v2) + DDL (`HPC_DDL_v2.sql` 295 lines + `syllabus_HPC_v1.1.sql` 297 lines). Identified 7 DDL gaps (6 missing tables + 1 status ENUM mismatch), 15 DDL corrections (FK type errors, wrong table references, platform deviations), 6 security findings, 32 models, 22 controllers, 10 services, 12 business rules, 5 FSMs, 13 implementation phases. |
