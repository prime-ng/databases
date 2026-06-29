# Module Knowledge: BehaviouralAssessment (BA / BHA)
# Last Updated: 2026-06-29 (BA Complete Analysis Pack run — counts re-verified, **prefix corrected bha_→ba_**, migrations discovered, FRD + Complete FRD produced)
# Completion Status: ~55–60% (16 models + 16 tenant migrations + 12 controllers + 17 policies + 65 views all present; core score service done; 0 tests; events/listeners + queued recompute job NOT wired; 3 critical FormRequests missing)

---

## ⚠️ CRITICAL CORRECTION — Table Prefix is `ba_`, NOT `bha_`

The single most important correction from the 2026-06-29 verification:

| Claim source | Prefix used | Authoritative? |
|--------------|-------------|----------------|
| Live tenant **migrations** (`database/migrations/tenant/…create_ba_*`) | `ba_` | **YES (rank 1–2)** |
| Live **Eloquent models** (all 16 `protected $table = 'ba_*'`) | `ba_` | **YES (rank 1–2)** |
| **V1 screen specs** (`BehaviouralAssessment_v2/00-Module-Overview.md`) | `ba_` | YES (rank 4) |
| Module DDL doc `2-DDL_Tenant_Consolidated/BehaviouralAssess_DDL_v2.sql` | `bha_` | **NO — divergent / stale** |
| Project `CLAUDE.md` prefix table | (does not list BA) | n/a |
| Prior versions of THIS knowledge file | `bha_` | **WRONG — corrected** |

**Resolution (per source-precedence ladder):** code + migrations beat the DDL doc for *what exists*. The deployed schema uses **`ba_`**. Every table reference below uses `ba_`. The `BehaviouralAssess_DDL_v2.sql` file (Apr 2026, `bha_`) is **out of sync with the live `ba_` migrations (16 Jun 2026)** and should be regenerated or retired by the DB Architect. Structures otherwise match column-for-column.

The master `0-DDL_Masters/tenant_db_v4.sql` contains **0** BA tables (neither `ba_` nor `bha_`); the BA schema lives only in the module's tenant migrations.

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix (LIVE) | **`ba_*`** (16 tables) |
| Table prefix (stale DDL doc) | `bha_*` — do not trust |
| Module path | `Modules/BehaviouralAssessment/` |
| Database | `tenant_db` (database-per-tenant; no `tenant_id` column) |
| Schema source (LIVE) | **16 tenant migrations** at `database/migrations/tenant/2026_06_16_1306xx_create_ba_*` |
| DDL doc (reference, stale prefix) | `2-DDL_Tenant_Consolidated/BehaviouralAssess_DDL_v2.sql` (16 `CREATE TABLE`, `bha_`) |
| Consolidated V2 Req | **Not present** in `4-Initial_Requirements/V2/` |
| Detailed Screen Specs | `2-Module_Requirement_V1/BehaviouralAssessment_v2/` — 24 screen files **(primary requirement source)** |
| Controllers | **12** (verified 2026-06-29) |
| Models | **16** (verified — matches table count exactly) |
| Services | **1** — `BehaviouralScoreService` only |
| FormRequests | **5** (covers 5 of 12 controllers) |
| Policies | **17** (in module's own `app/Policies/`) |
| Tests | **0** (`tests/Feature` + `tests/Unit` contain only `.gitkeep`) |
| Blade Views | **65** |
| Routes | `web.php` (113 lines) + `api.php` (1 apiResource, sanctum) |
| Jobs | **0** — `ComputeSchoolScoresJob` referenced in design but NOT created |
| Events / Listeners | **0** — `EventServiceProvider.$listen = []`; no `AssessmentApproved`/`IncidentCreated` dispatched |
| Observers | **0** — audit logging is done inline in controllers, not via an Eloquent Observer |
| Migrations | **16 tenant migrations** (prior knowledge said "0 migrations" — WRONG) |
| Seeders | **5** — `BaCategorySeeder`, `BaInterventionSeeder`, `BaRatingScaleSeeder`, `BaDemoSeeder`, `BehaviouralAssessmentDatabaseSeeder` |
| FRD | **Generated 2026-06-29** → `0-FRD_Documents/BHA_FRD_Complete_2026-06-29.md` (Complete Analysis Pack) |

**Service inventory (1):**
| Service | Covers |
|---------|--------|
| `BehaviouralScoreService` | `computeForPeriod()`, `computeStudentScore()` (multi-teacher avg, polarity inversion, weighted category + overall, grade mapping), `getStudentScore()`, `getBulkScores()` (pull-based result integration). Called **synchronously** — no queued job. |

**FormRequest coverage map:**
| Controller | FormRequest | Status |
|------------|-------------|--------|
| BaRatingScaleController | BaRatingScaleRequest | ✅ |
| BaCategoryController | BaCategoryRequest | ✅ |
| BaInterventionController | BaInterventionRequest | ✅ |
| BaAssessmentPeriodController | BaAssessmentPeriodRequest | ✅ |
| BaConfigController | BaConfigRequest | ✅ |
| BaAssessmentController | — | ❌ Missing (core rating entry / submit / approve / send-back) |
| BaIncidentController | — | ❌ Missing (incident creation/update/follow-up) |
| BaClassCategoryController | — | ❌ Missing (class-category mapping) |
| BaDashboardController / BaReportController / BaAuditLogController / BehaviouralAssessmentController | — | N/A (read-only / navigation) |

---

## DDL Table Inventory (16 tables — 6 Dependency Layers) — LIVE `ba_` prefix

### Layer 1 — Foundation
| Table | Purpose |
|-------|---------|
| `ba_rating_scales` | Configurable scales; `code`, `grade_type`, `min_rating`/`max_rating` drive normalisation + negative-polarity inversion; `is_default`, soft-delete |
| `ba_categories` | Categories with `polarity` (positive/negative ENUM) + proportional `weight`; self-ref `parent_id` (ON DELETE SET NULL) |
| `ba_interventions` | Master interventions; `intervention_type` ENUM(reward/corrective/counselling) |

### Layer 2 — Detail
| Table | Purpose |
|-------|---------|
| `ba_rating_levels` | Levels within a scale; `numeric_value`; UNIQUE(rating_scale_id, sort_order); CASCADE from scale |
| `ba_criteria` | Observable criteria within a category; proportional `weight`; CASCADE from category; ratings RESTRICT delete |

### Layer 3 — Configuration
| Table | Purpose |
|-------|---------|
| `ba_class_category_jnt` | Maps categories → `sch_classes` (grade level). UNIQUE(class_id, category_id). Permissive default: no mapping ⇒ all categories apply |
| `ba_assessment_periods` | Data-entry windows; lifecycle `open → closed → locked`; REQUIRED `academic_session_id`, OPTIONAL `academic_term_id` |
| `ba_config` | One row per academic session (UNIQUE); active rating scale, `is_result_integration_enabled` (default 0), `weightage_percent` (5–20), `aggregation_method`, `parent_notification_threshold` (severity) |

### Layer 4 — Transaction Headers
| Table | Purpose |
|-------|---------|
| `ba_assessments` | Header per teacher × class-section × period; UNIQUE(teacher_id, class_section_id, period_id); FSM `draft → submitted → reviewed → locked` + send-back |
| `ba_audit_log` | **IMMUTABLE** (`$timestamps=false`, no `updated_at`/`deleted_at`); polymorphic `entity_type`(assessment_rating/assessment/incident)+`entity_id`; CBSE/ICSE CCE compliance |

### Layer 5 — Core Transaction Data
| Table | Purpose |
|-------|---------|
| `ba_assessment_ratings` | **Core fact table** — one row per student × criterion × assessment; `rating_level_id` NULL = not rated; auto-save ~30s; UNIQUE(assessment_id, student_id, criterion_id) |
| `ba_student_remarks` | Overall teacher remark per student per assessment (distinct from per-criterion `remark`); UNIQUE(assessment_id, student_id) |
| `ba_computed_scores` | **Materialised score cache** per student × category × period; overall stored on first category row; UPSERT on recompute; read by Exam/Result via `getBulkScores()` |
| `ba_incidents` | Ad-hoc positive/negative events; `severity` (negative only), 8 `location`s, `attachments_json`; core fields immutable; follow-up fields appendable |

### Layer 6 — Junction
| Table | Purpose |
|-------|---------|
| `ba_incident_witnesses_jnt` | Polymorphic witnesses (student/staff) — NO DB FK on `witness_id`, app-enforced |
| `ba_incident_intervention_jnt` | N:M incidents ↔ interventions, per-application `notes`; RESTRICT delete on intervention |

---

## Architecture Decisions (embedded in schema + code)

- **D1 — Polarity inversion** for negative categories: `inverted = (max_rating + 1) − raw`; at service layer.
- **D2 — Weighted-average computation**: ratings → AVG across teachers per criterion → invert negatives → weighted-avg per category → weighted-avg overall (per `aggregation_method`) → grade map → UPSERT `ba_computed_scores`. Implemented in `BehaviouralScoreService::computeStudentScore()`.
- **D3 — Score cache**: scores never computed at query time; materialised in `ba_computed_scores`. **Recompute is synchronous** (no `ComputeSchoolScoresJob`, no event). GAP.
- **D4 — Result integration is pull-based**: Exam/Result calls `BehaviouralScoreService::getBulkScores()`; gated by `ba_config.is_result_integration_enabled` (default OFF). BA never writes `exm_*`.
- **D5 — Period vs Term**: `ba_assessment_periods.academic_term_id → sch_academic_term` optional; NULL ⇒ independent review cycle.
- **D6 — Incident immutability**: core fields (student/date/type/severity/description/location) immutable after creation; only follow-up fields mutable. App-layer enforced (no DB trigger).
- **D7 — `ba_class_category_jnt` maps `sch_classes`** (grade level), NOT `sch_class_groups_jnt` (Timetable subject junction).
- **D8 — `ba_audit_log` immutable** — model has `$timestamps=false`, no soft-delete; insert-only.

---

## Seeded Data (tenant onboarding)
- 1 rating scale "5-Point Behavioural Scale" (code `5_POINT`, min 1.0 / max 5.0) + 5 levels (Outstanding 5 → Unsatisfactory 1).
- 9 categories (5 positive + 4 negative) + 58 criteria.
- 9 interventions (3 reward, 4 corrective, 2 counselling).
- `ba_config` **NOT seeded** — auto-created with defaults on first access; result integration OFF.

**9 Categories:** Positive(5): Classroom Engagement(8), Respect & Responsibility(8), Cooperation & Collaboration(7), Emotional & Social Development(6), Leadership & Initiative(6). Negative(4): Disruptive Behaviours(7), Aggressive/Bullying(6), Academic Misconduct(6), Health & Safety Violations(4).

---

## FSMs
- **Assessment:** `draft → submitted → reviewed → locked` (send-back: submitted/reviewed → draft with reviewer remarks). Migration enum: draft, submitted, reviewed, locked.
- **Assessment Period:** `open → closed → locked` (reopen: closed → open). Migration enum: open, closed, locked.

---

## V1 Screen Inventory (24 screens — `BehaviouralAssessment_v2/`)
Dashboard(01); Masters: Rating-Scales(02), Categories(03), Interventions(04); Setup: Class-Mapping(05), Periods(06), Configuration(07); Assessments: My-Assessments(08), Ratings(09), Remarks(10), Review-Queue(11); Incidents: Incident-Log(12), Witnesses(13), Interventions-Applied(14); Reports Hub: Reports-Hub(15), Student-Scores(16), Category-Summary(17), Period-Report(18), Audit-Trail(19); Standalone: Student-Report(20), Class-Analysis(21), Period-Progress(22), Category-Performance(23), Incident-Report(24). Overview(00).

---

## Known Gaps & Open Issues

| Priority | Gap | Detail |
|----------|-----|--------|
| P0 | **DDL doc / live schema prefix divergence** | `BehaviouralAssess_DDL_v2.sql` uses `bha_`; live migrations + models use `ba_`. Regenerate the DDL doc from the `ba_` migrations (DB Architect) so downstream audits don't chase phantom `bha_` tables. |
| P1 | **0 tests** | Immutable audit log, polarity inversion, weighted-avg, FSM transitions, incident immutability — all high-risk, zero coverage. |
| P1 | **Missing `BaAssessmentRequest`** | Core rating entry + submit/approve/send-back unvalidated at request layer. |
| P1 | **Missing `BaIncidentRequest`** | Incident create/update/follow-up unvalidated (severity-required-when-negative rule not enforced at request layer). |
| P1 | **`ComputeSchoolScoresJob` absent + recompute synchronous** | School-wide recompute runs in-request; risk of timeout for large schools. No `Jobs/` dir. |
| P1 | **Events/Listeners not wired** | `EventServiceProvider.$listen = []`; `AssessmentApproved` / `IncidentCreated` not dispatched ⇒ parent-notification + auto-recompute flows depend on inline controller calls; verify they actually fire. |
| P2 | **Only 1 service (fat-controller risk)** | No `AssessmentService` / `IncidentService` / `ReportService`; logic likely in controllers. |
| P2 | **Missing `BaClassCategoryRequest`** | Class-category mapping unvalidated. |
| P2 | **`ba_config` not seeded** | Auto-created on first access; result integration OFF — needs onboarding doc. |
| P2 | **V1 intent not in schema** | V1 Configuration screen describes a *count-based* "Incident Escalation Threshold (default 3)" and a multi-checkbox notification set (Email HOD / Daily Digest to Principal). Live `ba_config` only has a *severity-based* `parent_notification_threshold`. → ENH-BA-001/002. |
| P3 | **No consolidated V2 req** | FRD built from 24 V1 screens + migrations/DDL. |

### Technical-Auditor Mode X findings (2026-06-29) — see `3-Audit_Reports/V1_Jun-2026/BehaviouralAssessment_Complete_Audit_2026-06-29.md`
Health **57/100 Amber**, Deploy **GO (conditional)**, **no P0**. Web routes ARE protected (RSP full tenancy+auth+verified stack) — prior `SEC-BEH-002` is a FALSE POSITIVE, retired. Clean on D17/D24/D25/6.2/cross-DB-FK; D36 N/A (no GENERATED cols).

| Priority | Gap | Code |
|----------|-----|------|
| P1 | Ratings editable after submit/approve/lock; period-lock never cascades to assessments → published scores diverge | BUG-BA-001 |
| P1 | Period FSM broken: open→locked allowed, locked→closed allowed, no `close()` action (open→closed unreachable) | BUG-BA-002 |
| P1 | Severe-incident parent notification ENTIRELY ABSENT (REQ-BA-015/BR-BA-013) — no Notification/event anywhere; `is_notified` never set | SEC-BA-001 |
| P1 | BR-BA-029 scale-lock-after-ratings not enforced | DATA-BA-001 |
| P2 | BR-BA-006/030/005 delete guards + cascade missing; BR-BA-009 permissive default missing (empty grid); BR-BA-028 multi-default scale; follow-up notes overwritten | BUG-BA-004..009 |
| P2 | Level value not range-checked; duplicate student-witness 500s; no incident transaction; soft-delete+unique 500 | VAL-BA-002, DATA-BA-003/004 |

**Mode C:** 30 BR → 15 ENFORCED · 6 PARTIAL · 9 MISSING (BR-005,006,009,012,013,025,028,029,030). **BR-BA-025 (auto-publish when approval workflow disabled) is NOT implemented** — there is no config flag/branch. Formula (inversion + multi-teacher avg + weighted category/overall) is CORRECT in `BehaviouralScoreService`. Incident core-field immutability (INC-2) and severity-required (INC-1) ARE enforced.

---

## Cross-Module Dependencies (all read-only — BA never writes external tables)

| Dependency | Table | Usage |
|------------|-------|-------|
| StudentProfile | `std_students` (INT UNSIGNED) | Student assessed / incident subject / witness |
| SchoolSetup | `sch_employees` (INT UNSIGNED) | Teacher (assessor), reviewer, incident reporter |
| SchoolSetup | `sch_class_section_jnt` (INT UNSIGNED) | Class+section scope of an assessment |
| SchoolSetup | `sch_classes` (INT UNSIGNED) | Class–category applicability mapping |
| SchoolSetup | `sch_org_academic_sessions_jnt` (SMALLINT) | Session scoping for periods + config |
| SchoolSetup | `sch_academic_term` (SMALLINT) | Optional period→term link |
| LmsExam/Result | (consumer) | Calls `BehaviouralScoreService::getBulkScores()` for weighted result integration |
| Notification | (consumer) | Severe-incident parent alert (when wired) |

---

## Lessons Learned
- [2026-06-29 | Business Analyst] **Never trust a module DDL doc's prefix over the live migrations.** BA's `BehaviouralAssess_DDL_v2.sql` says `bha_`, but all 16 tenant migrations, all 16 models, and the V1 screen specs say `ba_`. The prior knowledge file propagated `bha_` everywhere. Always `grep "protected \$table"` across models and `ls database/migrations/tenant | grep create_<prefix>` before recording a prefix.
- [2026-06-29 | Business Analyst] Prior file claimed "0 migrations — uses DDL directly." False — 16 tenant migrations exist (`2026_06_16_1306xx`). Verify migration presence, don't assume DDL-only.
- [2026-06-29 | Business Analyst] V1 Configuration screen's "escalation threshold (count of 3 incidents)" and multi-channel notification checkboxes are **business intent not present in the live schema**; logged as ENH rather than REQ to avoid implying they exist.
- [2026-06-29 | Technical Auditor] **`SEC-BEH-002` was a false positive.** Web routes ARE auth/tenancy-protected — the stack lives in the module `RouteServiceProvider::map()` (`web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified`), NOT in `web.php`. Before flagging "no middleware on routes", always read the module's `RouteServiceProvider`, not just the route file.
- [2026-06-29 | Technical Auditor] **The real risk surface here is workflow/data-integrity, not security.** The lock/read-only guard checks only `assessment.status==='locked'`, but NO code ever sets that status — period `lock()` updates only the *period* row. Net effect: "locked" periods don't actually freeze ratings, and approved scores can be silently edited out of sync with the cache + audit trail (BUG-BA-001). When auditing FSM modules, trace every terminal-state guard back to the code that is supposed to SET that state.
- [2026-06-29 | Technical Auditor] **Severe-incident parent notification is entirely absent** (not merely "events unwired"): `grep -rn "Notification|notify|dispatch|event(" app/` returns zero. `parent_notification_threshold` is dead config and `is_notified` is never written. A "P0 requirement exists in the FRD" does not mean any code implements it — verify with a grep, not by reading the schema.

---

## FRD Summary
- **File:** `0-FRD_Documents/BHA_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — FRD + RTM + BR register + conditions + validation + flows + FSM + data dictionary + dependency map + NFR + risk + prioritization + estimation + user stories + reporting/KPI).
- **Counts:** 18 REQ · 30 BR · 10 RPT · 4 ENH · 2 FSM · 6 workflows · 12 NFR · 8 RISK · 18 user stories.
- **REQ priority split:** P0 = 10, P1 = 8, P2 = 0 (the 4 ENH are the P2 backlog).
- **Stable IDs assigned (do not renumber):** REQ-BA-001…018, BR-BA-001…030, RPT-BA-001…010, ENH-BA-001…004.

---

## Pending Next Steps
- [ ] DB Architect: regenerate `BehaviouralAssess_DDL` from live `ba_` migrations (retire `bha_` doc).
- [ ] Technical Auditor (Mode B/C, FRD-driven): confirm where recompute + parent-notification actually fire; verify incident immutability + audit-log inserts; fat-controller check.
- [ ] Create missing FormRequests: `BaAssessmentRequest`, `BaIncidentRequest`, `BaClassCategoryRequest`.
- [ ] Build `ComputeSchoolScoresJob` (queued) + wire `AssessmentApproved` / `IncidentCreated` events.
- [ ] Testing Architect: cover polarity inversion, weighted avg, immutable audit, FSM, incident immutability (0 tests today).

---

## Version History
| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Seeded from DDL v2 (16 tables) + 24 V1 screen specs. Recorded prefix as `bha_` (later found WRONG). |
| 2026-06-27 | Business Analyst | Re-seed: file counts re-verified; services corrected 4→1; added 65 views, 111 route lines, 0 jobs, FormRequest map; completion ~50–55%. Still recorded `bha_`, claimed 0 migrations. |
| 2026-06-29 | Business Analyst | **Complete Analysis Pack run.** CORRECTED prefix `bha_`→`ba_` (migrations + models + V1 authoritative). Discovered 16 tenant migrations (not "0"). Found EventServiceProvider empty, no observers, no jobs, recompute synchronous, 5 seeders. Logged DDL-doc divergence as P0. Produced FRD Complete with 18 REQ / 30 BR / 10 RPT / 4 ENH. |
| 2026-06-29 | Technical Auditor | **Mode X Complete Audit** (A+B+C+G+scoped-D) → `3-Audit_Reports/V1_Jun-2026/BehaviouralAssessment_Complete_Audit_2026-06-29.md`. Health 57/100 Amber, Deploy GO (conditional), no P0. Assigned `*-BA-*` codes (BUG-BA-001..012, SEC-BA-001..003, DATA-BA-001..004, VAL-BA-001..003, MIG-BA-001, DEAD-BA-001, DOC-BA-001). Retired SEC-BEH-002 (false positive — RSP carries tenancy+auth). Mode C: 30 BR → 15 ENFORCED / 6 PARTIAL / 9 MISSING. Confirmed clean on D17/D24/D25/6.2/cross-DB-FK; D36 N/A. |
</content>
</invoke>
