# Module Knowledge: HPC (Holistic Progress Card)
# Last Updated: 2026-06-29
# Completion Status: ~45-50% — Core template/form/PDF/workflow/email built; ALL multi-actor (student/parent/peer) and curriculum-analytics features lack database tables and/or implementation

---

## ⚠️ 2026-06-29 Reconciliation Note (READ FIRST)

The prior (2026-06-27) version of this file carried **inflated and partly invented** counts.
Every figure below was re-verified against the live tree (`Modules/Hpc/`), the central tenant
migrations (`database/migrations/tenant/`), and the canonical DDL (`HPC_DDL_v2.sql`). Corrections:

| Item | Old (stale) claim | Live (verified 2026-06-29) |
|------|-------------------|----------------------------|
| Controllers | 22 / 23 | **11** |
| Models | 32 | **16** |
| Services | 10 | **10** (correct) |
| FormRequests | 14 existing | **4** |
| Policies (in module) | "10 registered" / "9 missing" | **0** — no Policy classes exist; no `registerPolicies()` |
| Blade views | "~4 PDF + partial" | **192** blade files |
| Tests | "6 files, 393 lines" | **0** test files in `Modules/Hpc/tests` |
| Jobs | implied | **1** (`SendHpcReportEmail`) + 1 Mailable (`HpcReportMail`) |
| `HpcCreditConfig` model/controller | "production-active" | **does NOT exist** (only `HpcCreditCalculatorService` exists, using code constants) |
| `HpcReportComment` model | "exists" | **does NOT exist** |
| Curriculum-analytics models (ability params, circular goals, learning outcomes, evaluation, knowledge graph) | "exist (FR-002–006 Done)" | **NONE exist** — not built in HPC module code |

---

## Module Facts

| Item | Value |
|------|-------|
| Full name | Holistic Progress Card |
| Module code | HPC |
| Table prefix | `hpc_*` |
| Scope | Tenant (database-per-tenant; no `tenant_id` columns) |
| Framework alignment | NEP 2020 / PARAKH-compliant holistic assessment |
| Canonical DDL | `2-DDL_Tenant_Consolidated/HPC_DDL_v2.sql` — **11 tables** (template + report layers only) |
| Extension DDL (spec only) | `1-DDL_Modules/HPC/Old_DDL/syllabus_HPC_v1.1.sql` — curriculum-analytics/ASC spec; **NOT migrated, no models** |
| Tenant migrations | **16 files** → create **13 tables** (11 from DDL v2 + `hpc_curriculum_change_request` + `hpc_lesson_version_control`) + 3 ALTER migrations |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/HPC_Hpc_Requirement.md` (76 KB) |
| V1 screen specs | `4-Requirement_Module_wise/2-Module_Requirement_V1/HPC_v2/` — 10 tab specs |
| Controllers | **11** (`HpcController` = 2,611-line god controller) |
| Models | **16** |
| Services | **10** |
| FormRequests | **4** (template-CRUD only) |
| Policies | **0** in module (authorization is via inline `Gate::authorize('tenant.hpc.*')` strings, not Policy classes) |
| Jobs / Mail | 1 Job (`SendHpcReportEmail`), 1 Mailable (`HpcReportMail`) |
| Blade views | 192 (`hpc_form` partials dominate: ~150 page partials across 4 form sets) |
| Tests | **0** in module |
| FRD status | **Complete FRD generated 2026-06-29** (`HPC_FRD_Complete_2026-06-29.md`) |
| REQ / BR / RPT counts (FRD) | 19 REQ, 16 BR, 6 RPT |
| Overall completion | **~45-50%** (down from claimed 59% once missing tables for built features are counted) |
| NEP grade bands | 4 (Foundational T1, Preparatory T2, Middle T3, Secondary T4) |
| PDF templates | 4 Blade PDF views (`pdf/first_pdf`…`fourth_pdf`) via DomPDF v3.1 |

---

## Verified Controller Inventory (11)

| Controller | Responsibility | Auth note |
|------------|----------------|-----------|
| `HpcController` (2,611 lines) | God controller: index dashboard, teacher form load/save, PDF (single + bulk ZIP), email (single + bulk), 6-state workflow actions, public PDF view | 21 `Gate::authorize` calls — but see **BUG-HPC-016** |
| `HpcTemplatesController` | Template master CRUD (+ trash/restore/force-delete/toggle) | 10 gate calls |
| `HpcTemplatePartsController` | Template page CRUD | 10 gate calls |
| `HpcTemplateSectionsController` | Template section CRUD | 10 gate calls |
| `HpcTemplateRubricsController` | Template rubric CRUD | 10 gate calls |
| `StudentHpcFormController` | Student self-assessment dashboard + form save/submit | 4 gate calls |
| `StudentGoalsController` | Student goals & aspirations wizard (T4) | 2 gate calls |
| `PeerHpcFormController` | Peer review form + teacher peer-assignment endpoints | 4 gate calls |
| `ParentHpcFormController` | Public token parent form + teacher parent-link endpoints | 2 gate calls (public routes are token-only) |
| `HpcActivityAssessmentController` | Multi-actor activity assessment overview | 1 gate call |
| `HpcAttendanceController` | Working-days config + attendance summary | 4 gate calls |

Trait: `Http/Controllers/Traits/HpcIndexDataTrait.php`.

---

## Verified Model Inventory (16) — and the table-existence reconciliation

| Model | Backing table | Migration? | DDL v2? | Status |
|-------|---------------|-----------|---------|--------|
| `HpcTemplates` | `hpc_templates` | ✅ | ✅ | OK |
| `HpcTemplateParts` | `hpc_template_parts` | ✅ | ✅ | OK |
| `HpcTemplatePartsItems` | `hpc_template_parts_items` | ✅ | ✅ | OK |
| `HpcTemplateSections` | `hpc_template_sections` | ✅ | ✅ | OK |
| `HpcTemplateSectionItems` | `hpc_template_section_items` | ✅ | ✅ | OK |
| `HpcTemplateSectionTable` | `hpc_template_section_table` | ✅ | ✅ | OK |
| `HpcTemplateRubrics` | `hpc_template_rubrics` | ✅ | ✅ | OK |
| `HpcTemplateRubricItems` | `hpc_template_rubric_items` | ✅ (+ALTERs) | ✅ | OK |
| `HpcReport` | `hpc_reports` | ✅ | ✅ | OK (see status-ENUM gap) |
| `HpcReportItem` | `hpc_report_items` | ✅ | ✅ | OK |
| `HpcReportTable` | `hpc_report_table` | ✅ | ✅ | OK |
| `ParentFormToken` | `hpc_parent_form_tokens` | ❌ | ❌ | **NO TABLE — runtime failure** (GAP-DB-004b) |
| `PeerAssignment` | `hpc_peer_assignments` | ❌ | ❌ | **NO TABLE — runtime failure** (GAP-DB-004c) |
| `PeerResponse` | `hpc_peer_responses` | ❌ | ❌ | **NO TABLE — runtime failure** (GAP-DB-004d) |
| `StudentFormSubmission` | `student_form_submissions` (no `hpc_` prefix) | ❌ | ❌ | **NO TABLE — runtime failure** (GAP-DB-005) |
| `StudentHpcSnapshot` | `hpc_student_hpc_snapshot` | ❌ | ❌ | **NO TABLE — feature inert** (GAP-DB-006) |

**Orphan tables** (migration exists, no model/controller, unused by code):
- `hpc_curriculum_change_request` — migration `2026_06_16_132249`
- `hpc_lesson_version_control` — migration `2026_06_16_132300`

**Tables/models that the stale file claimed but DO NOT exist anywhere:** `hpc_credit_config` /
`HpcCreditConfig`, `hpc_report_comments` / `HpcReportComment`, and all curriculum-analytics tables
(`hpc_ability_parameters`, `hpc_performance_descriptors`, `hpc_circular_goals`,
`hpc_learning_outcomes`, `hpc_learning_activities`, `hpc_learning_activity_type`,
`hpc_student_evaluation`, `hpc_knowledge_graph_validation`, `hpc_topic_equivalency`,
`hpc_syllabus_coverage_snapshot`, junctions). These appear only in the `syllabus_HPC_v1.1.sql`
**spec** and the V2 requirement; **no migration, no model, no controller** in the HPC module.

---

## Three-Way Reconciliation Summary (DDL ↔ Migration ↔ Model)

| Bucket | Tables | Meaning |
|--------|--------|---------|
| Fully aligned (DDL + migration + model) | 11 template/report tables | The genuinely working core |
| Migration only (no DDL v2, no model) | `hpc_curriculum_change_request`, `hpc_lesson_version_control` | Created in tenant DB but dead — no code uses them |
| Model only (no migration, no DDL) | `hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses`, `student_form_submissions`, `hpc_student_hpc_snapshot` | **Code references tables that do not exist** → multi-actor features throw on first DB hit |
| Spec only (DDL spec file, never migrated, no model) | all curriculum-analytics / ASC tables | FR-002–006, FR-007 are documentation, not implementation |

**Net:** of the 19 documented features, only ~7 are genuinely end-to-end functional
(Template Mgmt, Teacher Form, PDF, Workflow, Email, Attendance, Activity Overview). Student/Parent/
Peer/Snapshot are coded against missing tables; Curriculum analytics, Evaluation, Credit-config,
and Curriculum-Change-Request are not implemented (or table-orphaned).

---

## Known Issue — BUG-HPC-016 (STILL PRESENT, confirmed 2026-06-29)

`HpcController::generateReportPdf()` — **now at line 1255** (was reported at 1232; shifted, not
fixed). The method jumps straight from signature → `$request->validate([...])` → bulk PDF
generation with **NO `Gate::authorize()` call**. Its sibling `generateSingleStudentPdf()`
(line 2290) *does* call `Gate::authorize('tenant.hpc.view')`. Any authenticated user can therefore
generate (and via the email actions, distribute) PDF reports for arbitrary `student_ids`.
**Status: OPEN / P0.** Fix: add `Gate::authorize('tenant.hpc.view')` (or a dedicated
`tenant.hpc.generate-pdf`) as the first statement of `generateReportPdf()`.

Note: the FormRequest-fallback defence-in-depth (decisions.md D30) does **not** cover this method —
it uses inline `$request->validate()`, not a FormRequest, so there is no authorization layer at all.

---

## Feature → Requirement Map (FRD REQ IDs)

| REQ (FRD) | Feature | Real code status | Backing tables |
|-----------|---------|------------------|----------------|
| REQ-HPC-001 | Template Management (4-level CRUD) | **Built** | template hierarchy (8 tables) |
| REQ-HPC-002 | Assessment Parameter Config (ability/descriptors) | **Not built** | spec only |
| REQ-HPC-003 | Circular Goals & Competency Mapping | **Not built** | spec only |
| REQ-HPC-004 | Learning Outcomes & Question Mapping | **Not built** | spec only |
| REQ-HPC-005 | Learning Activities | **Not built** | spec only |
| REQ-HPC-006 | Curriculum Analytics Tools | **Not built** | spec only |
| REQ-HPC-007 | Student Holistic Evaluation (ASC) | **Not built** | spec only |
| REQ-HPC-008 | Teacher Data Entry Form | **Built** | `hpc_reports`, `hpc_report_items`, `hpc_report_table` |
| REQ-HPC-009 | Student Self-Assessment Portal | **Partial — no table** | `student_form_submissions` (missing) |
| REQ-HPC-010 | Parent Input Collection (token) | **Partial — no table** | `hpc_parent_form_tokens` (missing) |
| REQ-HPC-011 | Peer Assessment Workflow | **Partial — no table** | `hpc_peer_assignments`, `hpc_peer_responses` (missing) |
| REQ-HPC-012 | PDF Report Generation (single + bulk ZIP) | **Built** | report tables |
| REQ-HPC-013 | Approval Workflow (6-state) | **Built** | `hpc_reports.status` + audit cols |
| REQ-HPC-014 | Email Distribution (link, not attachment) | **Built** | `hpc_reports` |
| REQ-HPC-015 | Student HPC Snapshot | **Not built — no table** | `hpc_student_hpc_snapshot` (missing) |
| REQ-HPC-016 | Attendance Configuration & Aggregation | **Built** | `sys_settings` + `std_student_attendance` |
| REQ-HPC-017 | NCrF Credit Configuration & Calculation | **Partial — service only** | no config table |
| REQ-HPC-018 | Activity Assessment Overview | **Partial** | report + (missing) peer/parent tables |
| REQ-HPC-019 | Curriculum Change Request Workflow | **Not built** | `hpc_curriculum_change_request` (orphan table) |

---

## DDL / Schema Gaps (verified)

| Gap ID | Table / Issue | Severity | Evidence |
|--------|---------------|----------|----------|
| GAP-DB-004b | `hpc_parent_form_tokens` missing (model+ctrl+service+views exist) | P0 | no migration; `ParentFormToken` model present |
| GAP-DB-004c | `hpc_peer_assignments` missing | P0 | no migration; `PeerAssignment` model present |
| GAP-DB-004d | `hpc_peer_responses` missing | P0 | no migration; `PeerResponse` model present |
| GAP-DB-005 | `student_form_submissions` missing AND lacks `hpc_` prefix | P0 | no migration; `StudentFormSubmission` model present |
| GAP-DB-006 | `hpc_student_hpc_snapshot` missing | P1 | no migration; `StudentHpcSnapshot` model present |
| GAP-DB-002 | `hpc_credit_config` not built (no table/model/ctrl) | P1 | only `HpcCreditCalculatorService` w/ code constants |
| GAP-DB-003 | `hpc_reports.status` ENUM has 4 values in DDL (`Draft/Final/Published/Archived`) vs 6 lowercase states in model FSM (`draft/submitted/under_review/final/published/archived`); workflow also needs audit cols (`submitted_at`, `reviewed_by/at`, `review_comments`, `published_by/at`, `student_sections_complete`, `parent_sections_complete`) | P0 | DDL vs `HpcReport::TRANSITIONS` — verify against migration `..._create_hpc_reports_table` |
| GAP-DB-001 | `hpc_curriculum_change_request`, `hpc_lesson_version_control` are orphan tables (migrated, no model/controller) | P2 | migrations `2026_06_16_*` exist; no usage |

> Note: the 2026-06-27 file listed 15 "DDL FK corrections" sourced from the `syllabus_HPC_v1.1.sql`
> spec (slb_* references etc.). Those tables are **not migrated and not modelled in HPC**, so the
> corrections are spec-level only and out of scope for the live module until/unless analytics is built.

---

## Security Findings

| ID | Severity | Issue | Status 2026-06-29 |
|----|----------|-------|-------------------|
| BUG-HPC-016 | P0 / CRITICAL | `generateReportPdf()` (line 1255) missing `Gate::authorize()` | **OPEN — confirmed** |
| SEC-HPC-001 | CRITICAL | Verify `EnsureTenantHasModule:HPC` on the HPC route group | needs re-confirm at app `routes/tenant.php` registration (module `web.php` group uses only `auth`,`verified`) |
| SEC-HPC-002 | HIGH | Public route `GET /hpc/hpc-view/{student_id?}` → `viewPdfPage` outside auth; relies on encrypted-ID only | present in module `web.php` (lines 16-18) |
| SEC-HPC-003 | HIGH | Public parent routes token-only; must enforce `expires_at` + `completed_at` server-side every request | present (lines 133-137) |
| SEC-HPC-004 | MEDIUM | No class-teacher ownership check on `hpc_form/{student_id}` | guessable integer student_id |
| SEC-HPC-005 | MEDIUM | Bulk email endpoint no rate-limit | `send-bulk-report-email` route |
| SEC-HPC-006 | MEDIUM | `downloadZip(filename)` path-traversal risk; sanitize to `[A-Za-z0-9_\-.]` | BR-HPC-011 |

> **Technical Auditor corrections (2026-06-29, Mode X):**
> - **SEC-HPC-006 → effectively MITIGATED (P3):** `downloadZip()` already does `preg_replace('/[^A-Za-z0-9_\-\.]/','',$filename)` AND `Gate::authorize('tenant.hpc.viewAny')`. Slashes are stripped → no traversal. Only deviation from FRD: it *strips* rather than *rejects with 400*.
> - **SEC-HPC-003 → REGRESSED:** `EnsureTenantHasModule:Hpc` is NOT applied (module RSP applies only `web,InitializeTenancyByDomain,PreventAccessFromCentralDomains,EnsureTenantIsActive`; `web.php` group adds only `auth,verified`). Prior "FIXED" status is stale.
> - **BR-HPC-009 (50-cap) → NOT ENFORCED:** `generateReportPdf()` validates `student_ids` with `min:1` only, no `max:50`/count guard. The Design-Decisions/BR claim that it is inline-enforced is **wrong** — tracked as VAL-HPC-001 (P2).
> - **`HpcWorkflowService` writes audit columns + lowercase statuses** the `hpc_reports` migration lacks → workflow is non-functional today (DAT-HPC-001 + MIG-HPC-001, both P0). GAP-DB-003 upgraded to a confirmed runtime blocker.

---

## Key Design Decisions (verified still valid)

1. **`$hpcData` template-agnostic rendering** — `HpcReportService::getSavedValues()` returns
   `$savedValues` (keyed by lowercased `html_object_name`) + `$savedTableData`; all 4 PDF Blades
   reference fields generically. `html_object_name` is the universal key across form HTML, storage, PDF.
2. **Header/value separation** — `hpc_reports` stores only header (student, session, term, template,
   status, audit). Field values → `hpc_report_items` (typed key-value), grid cells → `hpc_report_table`.
   Any template works without DDL changes.
3. **Typed-pair storage in `hpc_report_items`** — input + output values across typed column pairs
   (numeric/text/boolean/selected/image/filename/filepath/json) + `remark`; column chosen by
   `input_type` of the rubric item.
4. **Email sends a URL link, not a PDF attachment** — `SendHpcReportEmail` sends `hpc-form.view`
   URL with `Crypt::encryptString(studentId)` + access code `HPC-{studentId}-{guardianId}-{sha1_8}`.
5. **Parent access via UUID token, not login** — token TTL 7 days; public routes outside auth group.
6. **Tenant job re-init** — `SendHpcReportEmail` (ShouldQueue) calls `tenancy()->initialize()` /
   `tenancy()->end()` in finally.
7. **Attendance computed twice** — aggregated on form load and re-computed at PDF time;
   `HpcAttendanceService::MONTH_ORDER` = Apr→Mar.
8. **Template hierarchy drives the form** — pages from `hpc_template_parts`, blocks from
   `hpc_template_sections`, scored fields from `hpc_template_rubrics`; no hard-coded structure.
9. **`updateOrCreate()` on save** — UNIQUE `(academic_session_id, term_id, student_id)` → one report
   per student per term (BR-HPC-002).
10. **4 separate form Blade sets** (`first/second/thread/fourth_form`) + parallel 4-template PDF
    if/elseif — refactor target `HpcPdfFactory::getView(int $templateId)`.
11. **Peer auto-assign constraints** — no self-review, no A↔B cycle; `PeerAssignmentService` —
    *but backing tables do not exist*, so this is presently non-functional.
12. **NCrF credit defaults as code constants** — `HpcCreditCalculatorService` uses national defaults
    (BV1=0.05 … Gr12=4.5); there is **no** `hpc_credit_config` override table.
13. **Bulk PDF synchronous, 50-student cap** (BR-HPC-009) until a queued job exists.
14. **ZIP streamed with `deleteFileAfterSend(true)`**; filename sanitized (BR-HPC-011).

---

## Business Rules (12) — see FRD §4 for canonical wording

| BR ID | Rule | Enforcement |
|-------|------|-------------|
| BR-HPC-001 | Template resolved from student class ordinal; mid-term class change does not auto-reassign | `HpcReportService::resolveTemplateId()` |
| BR-HPC-002 | One report per student per term (UNIQUE) | DB UNIQUE + `updateOrCreate()` |
| BR-HPC-003 | Actor field ownership; non-owned fields stripped + logged | `HpcSectionRoleService::filterPayloadByRole()` |
| BR-HPC-004 | Valid transitions only; invalid → 422; published/archived terminal | `HpcWorkflowService` |
| BR-HPC-005 | Parent token expires 7 days; verify not expired AND not completed on every GET/POST | `ParentHpcFormService` |
| BR-HPC-006 | Peer assignment: no self-review, no A↔B cycle | `PeerAssignmentService::autoAssignPeers()` |
| BR-HPC-007 | Attendance Apr→Mar; recomputed at load + PDF | `HpcAttendanceService` |
| BR-HPC-008 | LMS feed graceful fallback (empty sections, no exception) | `HpcLmsIntegrationService::getAllLmsData()` |
| BR-HPC-009 | Bulk PDF ≤ 50 students/request | inline validation in `generateReportPdf()` |
| BR-HPC-010 | Guardian email = view URL not attachment; access code format fixed | `SendHpcReportEmail` |
| BR-HPC-011 | `downloadZip` filename sanitized to `[A-Za-z0-9_\-.]`, else 400 | `HpcController::downloadZip()` |
| BR-HPC-012 | No `hpc_credit_config` rows → national NCrF defaults | `HpcCreditCalculatorService` |

---

## State Machines

| FSM | States | Terminal |
|-----|--------|----------|
| HPC Report Approval (`hpc_reports.status`) | draft → submitted → under_review → final → published → archived; under_review → (back to) submitted/draft | published, archived |
| Parent Form Token | pending → expired / completed | expired, completed (*table missing*) |
| Peer Assignment | pending → in_progress → completed | completed (*table missing*) |
| Student/Parent section-complete flags | false → true (boolean) | true |
| Curriculum Change Request | DRAFT → SUBMITTED → APPROVED/REJECTED | APPROVED, REJECTED (*orphan table, no code*) |

---

## Cross-Module Dependencies

### Inbound (HPC reads)
| Module | Tables/Channels | Use |
|--------|-----------------|-----|
| SchoolSetup (SCH) | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_academic_term`, `sch_org_academic_sessions_jnt` | class/section/term resolution, template mapping, year scoping |
| StudentProfile (STD) | `std_students`, `std_student_attendance`, guardians/sessions | student lookup, attendance aggregation, guardian email |
| SystemConfig (SYS) | `sys_users`, `sys_dropdown_table`, `sys_settings` | auth FKs, domain enums, `hpc_working_days_per_month` config |
| LMS (EXM/QUZ/HMW) | via `HpcLmsIntegrationService` (soft, graceful fallback) | pre-fill exam/quiz/homework data |
| Syllabus/QuestionBank | spec-level only (analytics not built) | — |

### Outbound (HPC writes/triggers)
| Target | What |
|--------|------|
| Email/Queue | `SendHpcReportEmail` → guardian view-link emails |
| Spatie MediaLibrary | file uploads on `HpcReport` (`hpc_report_files` collection) |
| ZIP storage | bulk PDFs to `storage/app/public/hpc-reports/zip/`, deleted after download |

---

## Services (10, verified)

`HpcReportService` (core save/load/resolveTemplateId), `HpcWorkflowService` (6-state FSM),
`HpcAttendanceService` (Apr–Mar aggregation), `HpcCreditCalculatorService` (NCrF, code constants),
`HpcLmsIntegrationService` (LMS feed + fallback), `PeerAssignmentService` (auto-assign — table
missing), `HpcSectionRoleService` (role field filtering), `HpcDataMappingService` (evaluation→report
mapping, partial), `StudentHpcFormService` (student page filtering), `ParentHpcFormService`
(token gen/validate — table missing).

Sys setting used: `hpc_working_days_per_month` (JSON array of 12 ints, Apr–Mar) in `sys_settings`.

---

## Pending Next Steps (re-prioritised 2026-06-29)

- [ ] **P0 BUG-HPC-016:** add `Gate::authorize()` to `generateReportPdf()` (line 1255)
- [ ] **P0 GAP-DB-004/005:** create migrations for `hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses`, `hpc_student_form_submissions` (rename from `student_form_submissions`) — without these, parent/peer/student-portal features fail at runtime
- [ ] **P1 GAP-DB-006:** create `hpc_student_hpc_snapshot` migration
- [ ] **P0 GAP-DB-003:** reconcile `hpc_reports.status` ENUM (6 lowercase states) + confirm 8 workflow audit columns exist in the migration
- [ ] **P0 SEC-HPC-001/002:** confirm `EnsureTenantHasModule:HPC` is applied at app route registration; secure public `hpc-view` route
- [ ] **P1:** create FormRequests for the 7 inline-validated actions in `HpcController` (form save, generate PDF, email, etc.)
- [ ] **P1:** introduce Policy classes (or document that inline Gate strings are the chosen pattern)
- [ ] **P2:** decide fate of orphan tables `hpc_curriculum_change_request`, `hpc_lesson_version_control` (build FR-019 or drop)
- [ ] **P2:** decompose 2,611-line `HpcController`; `HpcPdfFactory`; move bulk PDF to a queued job
- [ ] **P2/P3:** write feature tests (0 today); curriculum-analytics (FR-002–007) is greenfield if pursued
- [ ] Downstream: run Technical Auditor (Mode B FRD-driven) + Status_Analyzer 6-dim scoring against this FRD

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Seeded from V2 requirement + DDL (counts later found inflated/invented) |
| 2026-06-29 | Business Analyst | **Full live-tree re-verification.** Corrected counts (11 ctrl / 16 mdl / 4 req / 0 policy / 192 views / 0 tests). Three-way DDL↔migration↔model reconcile: 11 aligned, 2 orphan tables, 5 model-only (no table) → multi-actor features inert. Removed invented `HpcCreditConfig`/`HpcReportComment`/curriculum-analytics model claims. **Confirmed BUG-HPC-016 still OPEN** at line 1255. Generated Complete FRD (`HPC_FRD_Complete_2026-06-29.md`): 19 REQ / 16 BR / 6 RPT. Revised completion to ~45-50%. |
| 2026-06-29 | Technical Auditor | **Mode X Complete Audit** → `3-Audit_Reports/V1_Jun-2026/Hpc_Complete_Audit_2026-06-29.md`. Health 40/100 (P0-capped), Deploy NO-GO. 4 P0: BUG-HPC-016 (confirmed); **DAT-HPC-001** (`hpc_reports.status` enum 4-PascalCase vs model 6-lowercase FSM → workflow can't persist); **MIG-HPC-001** (`hpc_reports` missing 9 model columns → `42S22` on every workflow update); **DAT-HPC-002** (5 model-only tables = GAP-DB-004b/c/d,005,006 → `42S02` on live student/parent/peer routes). P1: SEC-HPC-002 still open, QUAL-HPC-001 (2,611-line god ctrl). P2: SEC-HPC-003 **regressed** (no `EnsureTenantHasModule:Hpc`), VAL-HPC-001 (BR-HPC-009 50-cap NOT enforced — prior "enforced" claim was wrong), DEAD-HPC-001. **Refuted/clean:** Layer 6 tenancy, D25, D30 (4 FormRequests gate properly), D24, BR-HPC-011 (downloadZip sanitizes+gates). |
</content>
</invoke>
