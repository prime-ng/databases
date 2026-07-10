# BehaviouralAssessment — Feature Inventory

**Module:** BehaviouralAssessment
**Table prefix:** `bha_` (verified against `CREATE TABLE bha_rating_scales …` in `BehaviouralAssess_DDL_v2.sql`; DDL header declares "Table Prefix: bha_* (16 tables)")
**Requirement source:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/` (25 screen files)
**Generated:** 2026-07-09 · inventory only
**Output root:** `3-Testing_Audit/TestCases/BehaviouralAssessment/`

> ⚠️ **PREFIX RULE (decided 2026-07-09) — `bha_` filenames, `ba_` table assertions.** The consolidated DDL names tables `bha_*`, but the **running app** (all 16 models + tenant migrations) uses **`ba_*`** (`ba_rating_scales`, `ba_categories`, …) — the DDL doc is stale (audit `DOC-BA-001`). Per user decision (Option 2):
> - **Artifact filenames + PHP class names use the `bha_` prefix** (matching the DDL doc / this inventory).
> - **Every schema/table/FK assertion targets the real `ba_*` tables** so tests pass against the running app.
> - Each feature includes a DOC-BA-001 proving test: `assertTrue(Schema::hasTable('ba_<table>'))` + `assertFalse(Schema::hasTable('bha_<table>'))`.
> - Apply this to **all 24 features** for consistency.
> Controllers group multiple screens: `BaAssessmentController` serves MyAssessments/Rating/StudentRemark/ReviewQueue; `BaIncidentController` serves Incident/Witness/InterventionApplied; `BaReportController` serves all report screens.

**Summary: 25 screen files → 24 features to generate, 1 skipped (`00-Module-Overview.md`).**

---

## Feature Inventory

| # | Screen file | Feature (PascalCase) | Primary table | Controller | Prefix | Type | Suggested depth | Output folder |
|---|-------------|----------------------|---------------|------------|--------|------|-----------------|---------------|
| 00 | 00-Module-Overview.md | — | — | — | — | **SKIP** (module overview, non-screen) | — | — |
| 01 | 01-Dashboard.md | Dashboard | *(none — aggregates)* | BaDashboardController@index | bha_ | Dashboard | Light (render, widgets, filters, permission, empty-state) | TestCases/BehaviouralAssessment/Dashboard/ |
| 02 | 02-Rating-Scales.md | RatingScale | bha_rating_scales (+ bha_rating_levels) | BaRatingScaleController | bha_ | CRUD-master | Full (P/N/D + child levels + toggle + soft/force-delete) | TestCases/BehaviouralAssessment/RatingScale/ |
| 03 | 03-Categories.md | Category | bha_categories (+ bha_criteria) | BaCategoryController | bha_ | CRUD-master | Full (P/N/D + criteria CRUD + reorder + toggle + soft-delete) | TestCases/BehaviouralAssessment/Category/ |
| 04 | 04-Interventions.md | Intervention | bha_interventions | BaInterventionController | bha_ | CRUD-master | Full (P/N/D + toggle + soft/force-delete) | TestCases/BehaviouralAssessment/Intervention/ |
| 05 | 05-Class-Mapping.md | ClassMapping *(app: ClassCategory)* | bha_class_category_jnt | BaClassCategoryController | bha_ | Config (junction) | Medium (store/toggle/destroy, no edit; dep Category + Class) | TestCases/BehaviouralAssessment/ClassMapping/ |
| 06 | 06-Periods.md | AssessmentPeriod *(screen: Period)* | bha_assessment_periods | BaAssessmentPeriodController | bha_ | CRUD-master | Full (P/N/D + lock/unlock lifecycle + toggle + soft-delete) | TestCases/BehaviouralAssessment/AssessmentPeriod/ |
| 07 | 07-Configuration.md | Configuration *(app: Config)* | bha_config | BaConfigController | bha_ | Config | Medium-Full (CRUD + default-scale binding + threshold rules) | TestCases/BehaviouralAssessment/Configuration/ |
| 08 | 08-My-Assessments.md | MyAssessments *(entity: Assessment)* | bha_assessments | BaAssessmentController@index/store/submit | bha_ | CRUD-transactional | Full (create/store/submit, Draft→Submitted, deadline) | TestCases/BehaviouralAssessment/MyAssessments/ |
| 09 | 09-Ratings.md | Rating *(entity: AssessmentRating)* | bha_assessment_ratings | BaAssessmentController@autoSave/bulkRate | bha_ | CRUD-transactional | Full (grid entry, autosave, bulk-rate, level validation) | TestCases/BehaviouralAssessment/Rating/ |
| 10 | 10-Remarks.md | StudentRemark *(alias: Remark)* | bha_student_remarks | BaAssessmentController | bha_ | CRUD-transactional | Medium-Full (per-student narrative, comment-bank) | TestCases/BehaviouralAssessment/StudentRemark/ |
| 11 | 11-Review-Queue.md | ReviewQueue | bha_assessments (status) | BaAssessmentController@reviewIndex/approve/sendBack | bha_ | CRUD-transactional (workflow) | Full (approve/lock, send-back, status guard) | TestCases/BehaviouralAssessment/ReviewQueue/ |
| 12 | 12-Incident-Log.md | Incident *(screen: IncidentLog)* | bha_incidents | BaIncidentController | bha_ | CRUD-transactional | Full (P/N/D + immutability-after-submit + follow-up + timeline) | TestCases/BehaviouralAssessment/Incident/ |
| 13 | 13-Witnesses.md | Witness | bha_incident_witnesses_jnt | BaIncidentController (nested) | bha_ | CRUD-transactional (child) | Medium (add/remove; student|staff polymorphism; dup guard) | TestCases/BehaviouralAssessment/Witness/ |
| 14 | 14-Interventions-Applied.md | InterventionApplied | bha_incident_intervention_jnt | BaIncidentController@addIntervention/removeIntervention | bha_ | CRUD-transactional (junction) | Medium (assign/remove, status, progress notes) | TestCases/BehaviouralAssessment/InterventionApplied/ |
| 15 | 15-Reports-Hub.md | ReportsHub | *(none — hub)* | BaReportController@index | bha_ | Report (hub) | Light (render, filter controls, links, permission) | TestCases/BehaviouralAssessment/ReportsHub/ |
| 16 | 16-Student-Scores-Report.md | StudentScoresReport | bha_computed_scores (read) | BaReportController@byClass | bha_ | Report | Light (render, cohort filter, export, empty-state) | TestCases/BehaviouralAssessment/StudentScoresReport/ |
| 17 | 17-Category-Summary.md | CategorySummary | bha_computed_scores (read) | BaReportController@categories | bha_ | Report | Light (render, aggregates, filter, permission) | TestCases/BehaviouralAssessment/CategorySummary/ |
| 18 | 18-Period-Report.md | PeriodReport | bha_computed_scores (read) | BaReportController@period | bha_ | Report | Light (render, period comparison, filter, export) | TestCases/BehaviouralAssessment/PeriodReport/ |
| 19 | 19-Audit-Trail.md | AuditTrail | bha_audit_log | BaAuditLogController@index | bha_ | Report (read-only log) | Light (render, filter, read-only, permission) | TestCases/BehaviouralAssessment/AuditTrail/ |
| 20 | 20-Student-Report.md | StudentReport | bha_computed_scores + bha_incidents (read) | BaReportController@student | bha_ | Report | Light (render, print-ready dossier, empty-state) | TestCases/BehaviouralAssessment/StudentReport/ |
| 21 | 21-Class-Analysis.md | ClassAnalysis | bha_computed_scores (read) | BaReportController@byClass | bha_ | Dashboard/Report (viz) | Light (render, charts/heatmap, filter) | TestCases/BehaviouralAssessment/ClassAnalysis/ |
| 22 | 22-Period-Progress.md | PeriodProgress | bha_computed_scores (read) | BaReportController@period | bha_ | Dashboard/Report (viz) | Light (render, trend charts, filter) | TestCases/BehaviouralAssessment/PeriodProgress/ |
| 23 | 23-Category-Performance.md | CategoryPerformance | bha_computed_scores (read) | BaReportController@categories | bha_ | Dashboard/Report (viz) | Light (render, stat viz, filter) | TestCases/BehaviouralAssessment/CategoryPerformance/ |
| 24 | 24-Incident-Report.md | IncidentReport | bha_incidents (read) | BaReportController@incidents | bha_ | Report | Light (render, frequency widgets, filter, export) | TestCases/BehaviouralAssessment/IncidentReport/ |

### Screen ↔ App name aliases (carry into each artifact's Feature Information)
- **ClassMapping** — app route/controller `class-categories` / `BaClassCategoryController`; table `bha_class_category_jnt`.
- **AssessmentPeriod** — screen "Periods"; app `assessment-periods` / `BaAssessmentPeriodController`.
- **Configuration** — app `configs` / `BaConfigController`.
- **MyAssessments / Rating / StudentRemark / ReviewQueue** — all under `BaAssessmentController` (one controller, four screens).
- **Witness / InterventionApplied** — nested endpoints under `BaIncidentController` (`incidents/{incident}/interventions`), no standalone resource routes.
- **Report screens 16–18, 20–24** — all `BaReportController`, read from `bha_computed_scores`/`bha_incidents`; none owns a writable table → read-only.

---

## Generation Order (grouped)

**Group A — Masters & Config first (setup dependencies, self-contained CRUD):**
1. RatingScale (foundation for grading; owns child rating-levels)
2. Category (owns child criteria; depended on by ClassMapping, Ratings)
3. Intervention (master; depended on by InterventionApplied)
4. AssessmentPeriod (lifecycle master; depended on by Assessment workflow)
5. Configuration (binds default scale + thresholds)
6. ClassMapping (junction: Category ↔ Class — needs Category first)

**Group B — Transactional workflow (depend on Group A):**
7. MyAssessments → 8. Rating → 9. StudentRemark → 10. ReviewQueue → 11. Incident → 12. Witness → 13. InterventionApplied

**Group C — Dashboards & Reports last (read-only, depend on all data above):**
14. Dashboard → 15. ReportsHub → StudentScoresReport → CategorySummary → PeriodReport → StudentReport → IncidentReport → ClassAnalysis → PeriodProgress → CategoryPerformance → AuditTrail

---

## Audit Defects to Prove

> This module's audit (`BehaviouralAssessment_Complete_Audit_2026-06-29.md`) uses `BUG-BA-###` / `SEC-BA-###` / `DATA-BA-###` / `VAL-BA-###` IDs (no `DEV-###`). Map these as the module's DEV-equivalents in each feature's TcList/Gap Analysis. Deploy gate: **GO (conditional)**.

| ID | Sev | Defect | Prove in feature(s) |
|----|-----|--------|---------------------|
| BUG-BA-001 | P1 | Ratings editable after submit/approve/lock; period lock never freezes assessments | Rating, ReviewQueue, AssessmentPeriod |
| BUG-BA-002 | P1 | Period lifecycle FSM violated; illegal transitions; open→closed unreachable | AssessmentPeriod |
| SEC-BA-001 / BUG-BA-003 | P1 | Severe-incident parent notification (REQ-BA-015) absent; no compare to `bha_config.parent_notification_threshold` | Incident, Configuration |
| DATA-BA-001 | P1 | Active rating scale switchable mid-session after ratings exist (BR-BA-029) | Configuration, RatingScale |
| VAL-BA-001 | P1 | Core write paths lack FormRequests (BaAssessment, BaIncident, BaClassCategory) — inline validation | MyAssessments, Incident, ClassMapping |
| SEC-BA-002 | P1 | All 5 FormRequests `authorize()` return bare `true` | RatingScale, Category, Intervention, AssessmentPeriod, Configuration |
| BUG-BA-004 | P2 | Criterion with ratings still deletable (BR-BA-006) | Category (criteria) |
| BUG-BA-005 | P2 | Intervention linked to incidents still deletable (BR-BA-030) | Intervention (FK RESTRICT) |
| BUG-BA-006 | P2 | Category soft-delete does not cascade to criteria (BR-BA-005) | Category |
| BUG-BA-007 | P2 | Class with no mapping shows empty grid (BR-BA-009 permissive default missing) | ClassMapping, Rating |
| BUG-BA-008 | P2 | Follow-up notes overwritten, not appended | Incident |
| BUG-BA-009 | P2 | Multiple rating scales can be `is_default=true` (BR-BA-028) | RatingScale |
| VAL-BA-002 | P2 | Level value not range-checked (BR-BA-003); duplicate student witness 500s | RatingScale (levels), Witness |
| DATA-BA-003 | P2 | Soft-delete + UNIQUE without `deleted_at` → recreate-after-delete 500 | RatingScale, Category, Intervention |
| DATA-BA-004 | P2 | Incident create not wrapped in a transaction | Incident |
| DEAD-BA-001 | P2 | Empty API resource controller on live sanctum route with no tenancy middleware (`routes/api.php`) | (security/tenancy note) |
| BUG-BA-011 | P2 | Report export is a permanent `abort(501)` stub on a live route (`reports/export`) | ReportsHub, report features |
