# BehaviouralAssessment — Feature Inventory (FINAL delivered state)

**Module:** BehaviouralAssessment  ·  **Code:** BHA  ·  **File-prefix:** `bha_`  ·  **Live-table prefix:** `ba_`
**FRD:** BHA  ·  **DDL:** `BehaviouralAssess_DDL_v2.sql`  ·  **DB scope:** Tenant-side (all features)
**Requirement source:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/` (25 screen files; `00-Module-Overview.md` is a non-screen doc → **skipped**)
**Delivered:** 24 features · **each 7/7 artifacts** · every `_TestCas.php` `php -l` clean · **976 total test methods**
**Last refreshed:** 2026-Jul-14

> **PREFIX REALITY (DOC-BA-001).** The DDL doc names tables `bha_*`; the **live migrations/models/FormRequests use `ba_*`**. Standard applied across the module: **filenames keep the `bha_` prefix** (matches the inventory + on-disk folders) while **test bodies assert the real `ba_*` tables**. "Code wins" — confirmed by audit finding DOC-BA-001.

---

## 1. Delivered Features (24) — final state

| # | Screen file (`_v2`) | Feature | Live table(s) | Controller | Screen type / depth | Methods | Status |
|---|---------------------|---------|---------------|------------|---------------------|:------:|:------:|
| 02 | 02-Rating-Scales | **RatingScale** | `ba_rating_scales`, `ba_rating_levels` | `BaRatingScaleController` | Master CRUD (Deep) | 49 | 7/7 ✅ |
| 03 | 03-Categories | **Category** | `ba_categories`, `ba_criteria` | `BaCategoryController` | Master CRUD + nested criteria (Deep) | 55 | 7/7 ✅ |
| 07 | 07-Configuration | **Configuration** | `ba_config` | `BaConfigController` | Full CRUD + trash/restore + JSON toggle (Deep) | 51 | 7/7 ✅ |
| 05 | 05-Class-Mapping | **ClassMapping** | `ba_class_category_jnt` | `BaClassCategoryController` (list via `BaDashboardController::setup`) | Junction: create/toggle/delete (no edit) | 44 | 7/7 ✅ |
| 04 | 04-Interventions | **Intervention** | `ba_interventions` | `BaInterventionController` | Master CRUD (Deep) | 48 | 7/7 ✅ |
| 06 | 06-Periods | **AssessmentPeriod** | `ba_assessment_periods` | `BaAssessmentPeriodController` | Full CRUD + FSM (open→locked→closed) (Deep) | 59 | 7/7 ✅ |
| 08 | 08-My-Assessments | **MyAssessments** | `ba_assessments` | `BaAssessmentController` (page via `BaDashboardController::assessmentsPage`) | CRUD-transactional + FSM (Deep) | 49 | 7/7 ✅ |
| 09 | 09-Ratings | **Rating** | `ba_assessment_ratings` | `BaAssessmentController` | Transactional grid (upsert per cell) (Deep) | 42 | 7/7 ✅ |
| 11 | 11-Review-Queue | **ReviewQueue** | `ba_assessments` | `BaAssessmentController` (`reviewIndex`/`reviewShow`/`approve`/`sendBack`) | Approval workflow / FSM (Deep) | 47 | 7/7 ✅ |
| 12 | 12-Incident-Log | **Incident** | `ba_incidents` | `BaIncidentController` | Full CRUD-transactional + follow-up + lifecycle (Deep) | 49 | 7/7 ✅ |
| 13 | 13-Witnesses | **Witness** | `ba_incident_witnesses_jnt` | `BaIncidentController` (`store`/`update`/`show`) | Attach/sync junction (polymorphic) | 40 | 7/7 ✅ |
| 14 | 14-Interventions-Applied | **InterventionApplied** | `ba_incident_intervention_jnt` | `BaIncidentController` (`addIntervention`/`removeIntervention`) | Junction link/unlink | 48 | 7/7 ✅ |
| 10 | 10-Remarks | **StudentRemark** | `ba_student_remarks` | `BaAssessmentController` | Transactional child of assessment | 41 | 7/7 ✅ |
| 01 | 01-Dashboard | **Dashboard** | reads `ba_computed_scores`, `ba_assessments`, `ba_incidents`… | `BaDashboardController::index` | Read-only dashboard (Light) | 37 | 7/7 ✅ |
| 15 | 15-Reports-Hub | **ReportsHub** | nav hub (aggregates) | `BaReportController::index` | Read-only navigation hub (Light) | 27 | 7/7 ✅ |
| 19 | 19-Audit-Trail | **AuditTrail** | `ba_audit_log` | `BaAuditLogController::index` | Read-only immutable ledger (Light) | 30 | 7/7 ✅ |
| 16 | 16-Student-Scores-Report | **StudentScoresReport** | `ba_computed_scores`, `ba_assessments` | `BaReportController::byClass` (+ `BaDashboardController::reportsPage`) | Read-only report (Light) | 33 | 7/7 ✅ |
| 17 | 17-Category-Summary | **CategorySummary** | `ba_computed_scores` | `BaReportController::categories()` | Read-only report (Light) | 32 | 7/7 ✅ |
| 18 | 18-Period-Report | **PeriodReport** | `ba_assessment_periods`, `ba_assessments`, `ba_student_remarks` | `BaReportController::period()` | Read-only report (Light) | 32 | 7/7 ✅ |
| 20 | 20-Student-Report | **StudentReport** | `ba_computed_scores`, `ba_incidents`, `ba_student_remarks` | `BaReportController::student()` | Read-only report (Light) | 33 | 7/7 ✅ |
| 21 | 21-Class-Analysis | **ClassAnalysis** | `ba_computed_scores` | `BaReportController::byClass()` | Read-only report / viz (Light) | 29 | 7/7 ✅ |
| 22 | 22-Period-Progress | **PeriodProgress** | `ba_computed_scores` | `BaReportController` — **no `progress()` action (screen unbuilt)** | Read-only report (Light, unimplemented) | 26 | 7/7 ✅ |
| 23 | 23-Category-Performance | **CategoryPerformance** | `ba_computed_scores` | `BaReportController::categories()` (shared w/ 17 → DOC-BA-002) | Read-only report (Light) | 37 | 7/7 ✅ |
| 24 | 24-Incident-Report | **IncidentReport** | `ba_incidents`, `ba_interventions`, `ba_categories` | `BaReportController::incidents()` | Read-only report (Light) | 38 | 7/7 ✅ |

**Screen `00-Module-Overview.md`** — non-screen doc, intentionally not a feature (skipped; noted here per convention).

---

## 2. Grouping & delivery batches

| Group | Theme | Features | Methods |
|-------|-------|----------|:------:|
| **A** | Masters / Config | RatingScale, Category, Configuration, ClassMapping, Intervention, AssessmentPeriod | 306 |
| **B** | Transactional | MyAssessments, Rating, ReviewQueue, Incident, Witness, InterventionApplied, StudentRemark | 316 |
| **C** | Dashboards / Reports | Dashboard, ReportsHub, AuditTrail, StudentScoresReport, CategorySummary, PeriodReport, StudentReport, ClassAnalysis, PeriodProgress, CategoryPerformance, IncidentReport | 354 |
| | **Module total** | **24 features** | **976** |

---

## 3. Notes on module truth

- **Test style:** browser Dusk (`extends DuskTestCase`) with authenticated in-page `fetch` for JSON/status assertions — matches the module's established pattern; tenant context initialised in `setUp`/`tearDown` (all features are tenant-side).
- **Activity log:** the BHA CRUD controllers write **no `activityLog()`** and the models have **no observers** — a *documented absence*, not an omission in testing (asserted per feature). The module's real audit surface is the append-only `ba_audit_log` ledger (AuditTrail feature), written via `BaAuditLog::log()` for grade/rating changes only.
- **Authorization:** every `FormRequest::authorize()` returns bare `true` (**SEC-BA-002**); the real guard is the controller `Gate::authorize('tenant.behavioural-assessment.*')` — asserted module-wide.
- **Report engine:** screens 16–24 are served by a single `BaReportController`; `export()` is a live `abort(501)` stub (**BUG-BA-011**); several requirement widgets/filters are unbuilt (proven as documented gaps, not test holes).
- **Prefix:** `bha_` (filenames) vs `ba_` (live) — DOC-BA-001, applied uniformly.
