# Module Knowledge Summary: BehaviouralAssessment (BHA)

**Date:** 2026-06-27
**Agent:** Business Analyst
**Source Files:**
- `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/` — **24 screen-spec files** (primary requirement source — NO consolidated V2 req file exists)
- `2-DDL_Tenant_Consolidated/BehaviouralAssess_DDL_v2.sql` (16 tables, April 2026, well-commented with architecture diagram)
- `Herd/prime_ai/Modules/BehaviouralAssessment/` (live filesystem verification — two passes: seeding + re-seed)

**Knowledge File:** `AI_Brain/module-knowledge/BHA_BehaviouralAssessment.md`

---

## 1. Module Identity

| Item | Finding |
|------|---------|
| Module Code | `BHA` |
| Table Prefix | `bha_*` |
| Database | `tenant_db` (per-school, no `tenant_id` columns) |
| Laravel Path | `Modules/BehaviouralAssessment/` |
| DDL Version | v2 (April 2026, 16 tables, 6 dependency layers) |
| Consolidated V2 Requirement | **Does not exist** — no `BHA_BehaviouralAssessment_Requirement.md` in `4-Initial_Requirements/V2/` |
| Primary Req Source | 24 screen-spec files in `2-Module_Requirement_V1/BehaviouralAssessment_v2/` |
| FRD Status | Not yet generated |
| Compliance Scope | CBSE/ICSE CCE — behavioural assessment and immutable audit trail |

**Key Discovery:** BHA is the only module in the audit where there is NO consolidated V2 requirement file. The DDL v2 is well-commented with architecture decisions and is effectively co-primary with the 24 screen specs. Any FRD must synthesise both — do not search for `BHA_*` in `4-Initial_Requirements/V2/`.

---

## 2. Actual vs. Baseline Comparison

BHA was seeded on 2026-06-27 from screen specs + DDL only, then immediately re-verified via filesystem. The seeding pass had an error in service count.

| Metric | Initial Seeding (2026-06-27) | Re-Verified Actual | Change |
|--------|-----------------------------|--------------------|--------|
| Controllers | 12 | **12** | No change |
| Models | 16 | **16** | Exact match (one per DDL table) |
| Services | **4** (incorrect) | **1** (BehaviouralScoreService only) | Corrected −3 |
| FormRequests | 5 | **5** | No change |
| Policies | 17 | **17** | No change |
| Tests | 0 | **0** | Critical gap |
| Blade Views | Not recorded | **65** | Added from re-seed |
| Route Lines | Not recorded | **111 lines** in web.php | Added from re-seed |
| Jobs | Not checked | **0** | Gap confirmed |
| Migrations | Not checked | **0** | Gap confirmed |
| Completion % | Unknown | **~50–55%** | First estimate |

**Key Error:** Service count was recorded as 4 at seeding — carried forward from architectural descriptions in the DDL comments (D3 references `ComputeSchoolScoresJob`, D6 describes incident immutability, etc.). Actual directory had only 1 service file. **Requirement-described or DDL-referenced services are not the same as implemented service files.**

---

## 3. DDL Architecture: 16 Tables Across 6 Dependency Layers

The DDL v2 is exceptionally well-documented with per-table comments and an explicit dependency architecture diagram. This is the authoritative source for BHA's design intent.

| Layer | Tables | Role |
|-------|--------|------|
| 1 — Foundation | `bha_rating_scales`, `bha_categories`, `bha_interventions` | Configuration masters; seeded on tenant creation |
| 2 — Detail | `bha_rating_levels`, `bha_criteria` | Sub-items of Layer 1 masters; 58 criteria seeded |
| 3 — Configuration | `bha_class_category_jnt`, `bha_assessment_periods`, `bha_config` | School-session config; maps classes to categories |
| 4 — Transaction Headers | `bha_assessments`, `bha_audit_log` | Assessment header per teacher per class-section per period; immutable audit trail |
| 5 — Core Data | `bha_assessment_ratings`, `bha_student_remarks`, `bha_computed_scores`, `bha_incidents` | Core fact rows; scores materialised into `bha_computed_scores` |
| 6 — Junctions | `bha_incident_witnesses_jnt`, `bha_incident_intervention_jnt` | N:M links for witnesses and applied interventions |

---

## 4. Score Computation Architecture (Most Complex Logic in Module)

The core scoring pipeline is implemented entirely in `BehaviouralScoreService` and operates as follows:

```
bha_assessment_ratings (raw ratings per student per criterion)
  → GROUP BY criterion → AVG across all teachers (multi-teacher averaging)
  → For negative polarity criteria: inverted_score = (max_scale + 1) − raw_rating
  → GROUP criteria BY category → WEIGHTED_AVG(criterion.weight) → category_score
  → WEIGHTED_AVG(category.weight, per aggregation_method) → overall_score
  → Map overall_score to grade via bha_rating_scales min/max boundaries
  → UPSERT into bha_computed_scores
```

**Why polarity inversion matters:** Negative categories (e.g., "Bullying", "Disruptive Behaviours") score inversely — a student rated 5/5 on "Bullying" (worst behaviour) must produce a score of 1 after inversion, not 5. A bug here would silently reward bad behaviour on report cards. This is the highest-risk computation in the module and has 0 tests.

**Materialised cache design:** Scores are never computed at query time. All results are materialised into `bha_computed_scores` and served from there. The Exam/Result module calls `BehaviouralScoreService::getBulkScores()` — BA never writes to `exm_*` tables. This is a **pull-based integration**, gated by `bha_config.is_result_integration_enabled` (default OFF per school per session).

---

## 5. Critical Architecture Decisions Found in DDL Comments

Unlike most modules where architecture decisions are implicit in the code, BHA's DDL v2 has explicit decisions documented in comments. These supersede any screen-spec interpretations.

| Decision | Summary | Risk if Missed |
|----------|---------|---------------|
| D1 — Polarity Inversion | Negative categories invert raw ratings at service layer; `inverted = (max+1) − raw` | Silent correctness bug on report cards |
| D2 — Weighted Average Flow | Criterion → category → overall score with separate weight fields at each level | Incorrect weights produce wrong grades |
| D3 — Materialised Score Cache | Scores UPSERT into `bha_computed_scores`; triggered by `AssessmentApproved` event or `ComputeSchoolScoresJob` | Without the job, stale scores are served to Exam module |
| D4 — Pull-Based Result Integration | Exam module calls `getBulkScores()` — BA never writes to `exm_*` | Integration config must be ON; default is OFF |
| D5 — Period ↔ Term Link | `bha_assessment_periods.academic_term_id` is optional; when set, BA scores appear alongside term exam results | NULL = independent review cycle (monthly, etc.) |
| D6 — Incident Immutability | Core incident fields immutable after creation; only follow-up fields editable | Any UPDATE on core fields violates BR-BA-008 |
| D7 — Class Mapping to sch_classes | `bha_class_category_jnt` maps to `sch_classes`, not `sch_class_groups_jnt` (Timetable-specific table) | Wrong join gives empty mapping for all classes |
| D8 — Immutable Audit Log | `bha_audit_log` has no `updated_at`, no `deleted_at`; insert-only for CBSE/ICSE CCE compliance | Any soft-delete or update on audit rows breaks compliance |

---

## 6. Two Critical Immutability Requirements

BHA has two distinct immutability patterns, both required for CCE compliance:

### 6.1 — Audit Log Immutability (`bha_audit_log`)
- No `updated_at` column, no `deleted_at` column
- Once a row is inserted it is never modified or soft-deleted
- Purpose: CBSE/ICSE CCE requires a tamper-proof history of all rating changes and status transitions
- **Status:** Table exists in DDL; `BaAuditLogController` (read-only) exists; 0 tests confirm immutability

### 6.2 — Incident Core Field Immutability (BR-BA-008)
- `bha_incidents` core fields (student_id, date, type, severity, description, location) cannot be modified after creation
- Only `follow_up_notes`, `follow_up_date`, `is_follow_up_required`, `is_notified` are editable post-creation
- Enforced at service layer only — no DB-level constraint
- **Gap:** `BaIncidentRequest` (FormRequest for incident creation) is missing → no server-side validation at request layer

---

## 7. No Consolidated V2 Requirement — Unique Seeding Challenge

BHA is the only module where there is no `BHA_*_Requirement.md` in `4-Initial_Requirements/V2/`. This creates specific risks:

| Risk | Detail |
|------|--------|
| FRD generation complexity | Must read all 24 screen files + DDL v2 together — no single document captures both |
| Business rule discovery | BRs are distributed across 24 screen files (not in a consolidated BR table) — easy to miss edge cases |
| Agent path confusion | Searching `4-Initial_Requirements/V2/BHA_*` returns nothing — agents must know to look in `2-Module_Requirement_V1/BehaviouralAssessment_v2/` instead |
| Seeding quality | Prior seeding recorded wrong service count (4 instead of 1) partly because architectural intent from DDL comments was mistaken for implemented files |

**Rule established:** For BHA, always use `2-Module_Requirement_V1/BehaviouralAssessment_v2/` as the req source. If any agent references a "V2 BHA requirement file" in the consolidated V2 folder, that file does not exist.

---

## 8. FormRequest Coverage Gap (3 Critical Missing)

Only 5 of 12 controllers have FormRequests — and the 3 missing ones cover the highest-risk operations:

| Controller | FormRequest | Status | Risk |
|-----------|-------------|--------|------|
| `BaRatingScaleController` | `BaRatingScaleRequest` | ✅ Present | Low risk |
| `BaCategoryController` | `BaCategoryRequest` | ✅ Present | Low risk |
| `BaInterventionController` | `BaInterventionRequest` | ✅ Present | Low risk |
| `BaAssessmentPeriodController` | `BaAssessmentPeriodRequest` | ✅ Present | Low risk |
| `BaConfigController` | `BaConfigRequest` | ✅ Present | Low risk |
| **`BaAssessmentController`** | **Missing** | ❌ **P1 GAP** | Core rating grid — unvalidated submissions |
| **`BaIncidentController`** | **Missing** | ❌ **P1 GAP** | Incident creation — severity/date unvalidated |
| **`BaClassCategoryController`** | **Missing** | ❌ **P2 GAP** | Class-category mapping — unvalidated |
| `BaDashboardController` | N/A | Read-only | No FormRequest needed |
| `BaReportController` | N/A | Read-only | No FormRequest needed |
| `BaAuditLogController` | N/A | Read-only | No FormRequest needed |
| `BehaviouralAssessmentController` | N/A | Base/navigation | No FormRequest needed |

The pattern is clear: config/master FormRequests were created; transaction FormRequests were not.

---

## 9. ComputeSchoolScoresJob — Designed but Never Created

Architecture Decision D3 describes `ComputeSchoolScoresJob` as the mechanism for materialising scores into `bha_computed_scores`. It is referenced in the DDL comments as if it exists.

**Actual state:** No `Jobs/` directory in `Modules/BehaviouralAssessment/`. The job was never created.

**Impact:** Without the job, one of these is happening:
1. Score computation is called synchronously from a controller (blocking HTTP request during period close)
2. `AssessmentApproved` event dispatches a different job that was not found in this pass
3. Scores are never materialised — `bha_computed_scores` is always empty

**Risk:** If the Exam module calls `getBulkScores()` and `bha_computed_scores` is empty (because no job ever ran), all students show zero behavioural scores on report cards — a silent data quality failure.

---

## 10. Seeded Master Data (Provisioned on Tenant Onboarding)

BHA is the most seed-heavy module in the audit to date. All this data must be present before teachers can begin assessments:

| Data Set | Count | Detail |
|----------|-------|--------|
| Rating Scale | 1 | "5-Point Behavioural Scale" (code: 5_POINT); min 1.0, max 5.0 |
| Rating Levels | 5 | Outstanding(5), Very Good(4), Good(3), Needs Improvement(2), Unsatisfactory(1) |
| Categories | 9 | 5 positive + 4 negative (see below) |
| Criteria | **58** | Distributed across 9 categories |
| Interventions | 9 | 3 reward, 4 corrective, 2 counselling |
| `bha_config` | **NOT seeded** | Auto-created on first access with defaults (result integration OFF) |

**Category breakdown:**
- Positive (5): Classroom Engagement (8 criteria), Respect & Responsibility (8), Cooperation & Collaboration (7), Emotional & Social Development (6), Leadership & Initiative (6)
- Negative (4): Disruptive Behaviours (7), Aggressive/Bullying (6), Academic Misconduct (6), Health & Safety Violations (4)

**`bha_config` not being seeded is a school-onboarding risk.** Result integration is OFF by default. Without explicit activation per school per academic session, behavioural scores will never appear in report cards — and no error is raised. School onboarding checklist must include enabling this config.

---

## 11. Open Gaps & Recommended Actions

### P1 — Critical

| Gap | Recommended Action |
|-----|-------------------|
| **0 test files** | Polarity inversion, weighted avg computation, immutable audit log enforcement, and Assessment FSM transitions are all high-risk untested paths. Especially: a polarity inversion bug silently corrupts report card grades. |
| **`BaAssessmentRequest` missing** | Core rating grid (the most-used screen in the module) accepts unvalidated submissions. At minimum: rating_level_id must be from bha_rating_levels, student_id must belong to the class-section, criterion_id must be mapped to the class. |
| **`BaIncidentRequest` missing** | Incident creation accepts unvalidated severity, date, student, type fields. Incidents are immutable after creation — a bad input is permanently locked in. |
| **`ComputeSchoolScoresJob` never created** | Score materialisation trigger is missing. Determine: is scoring synchronous in the controller? Is `bha_computed_scores` populated at all? Exam module integration depends on this. |

### P2 — Architecture Risk

| Gap | Recommended Action |
|-----|-------------------|
| Only 1 service (`BehaviouralScoreService`) | Assessment save logic, incident lifecycle, and report generation are likely in controllers. Extract `AssessmentService` (rating save, FSM) and `IncidentService` (create + witness/intervention linking). |
| `BaClassCategoryRequest` missing | Class-category mapping has no validation — any class_id / category_id combination is accepted. |
| `bha_config` not seeded + result integration OFF by default | School onboarding step needed. Document explicit activation requirement. |
| Events/Listeners directory missing | D3 references `AssessmentApproved` event. No Events/ or Listeners/ found — event may be dispatched directly from controller or not at all. Audit needed. |

### P3 — Process

| Gap | Action |
|-----|--------|
| No consolidated V2 requirement | FRD must synthesise 24 screen files + DDL v2 — longer process than single-file modules. Allocate additional time. |
| `bha_class_category_jnt` permissive default | If no mapping exists, all categories apply to all classes. Permissive default could overwhelm teachers with irrelevant criteria. Consider making mapping mandatory before period open. |

---

## 12. Cross-Module Dependency Map

**All BHA dependencies are read-only. BHA never writes to any external module table.**

| Module | Direction | Integration |
|--------|-----------|------------|
| StudentProfile (STD) | BHA reads | `std_students` — student being assessed or incident subject |
| SchoolSetup (SCE) | BHA reads | `sch_employees` — teacher/reviewer/reporter; `sch_class_section_jnt` — scope; `sch_classes` — category mapping; `sch_org_academic_sessions_jnt` — session; `sch_academic_term` — optional period link |
| LmsExam (EXM) | EXM reads BHA | Exam module calls `BehaviouralScoreService::getBulkScores()` — pull-based, gated by `bha_config.is_result_integration_enabled` |
| Notification (NTF) | BHA triggers NTF | `IncidentCreated` event → parent notification when incident severity ≥ threshold configured in `bha_config` |

---

## 13. Assessment Workflow FSMs

### Assessment FSM (4 states)
```
draft → submitted → reviewed → locked
              ↑         │
              └─────────┘ (send-back: reviewed/submitted → draft with reviewer remarks)
```
- `UNIQUE(teacher_id, class_section_id, period_id)` — one assessment per teacher per class-section per period
- Locked state is terminal — no further changes allowed

### Assessment Period FSM (3 states)
```
open → closed → locked
  ↑       │
  └───────┘ (reopen: closed → open; locked is terminal)
```

---

## 14. Key Lessons Learned

1. **Service count from DDL architecture comments is NOT the same as implemented service count.** BHA's DDL v2 has rich architecture commentary describing `ComputeSchoolScoresJob`, `AssessmentApproved` event, and scoring pipeline — all described as if implemented. The actual service directory had 1 file. Always `ls app/Services/` regardless of what documentation says.

2. **"No consolidated V2 requirement" is a seeding process risk.** When there is no `{CODE}_Requirement.md` in `4-Initial_Requirements/V2/`, the seeding process must use the screen-spec folder as primary. The business-analyst.md agent guide must explicitly handle this fallback path — and any seeding done without it will miss or miscount requirement artifacts.

3. **The most seed-heavy modules have the most school-onboarding risk.** BHA provisions 58 criteria across 9 categories on tenant creation, but `bha_config` is NOT seeded. A school that never explicitly enables result integration will silently have 0 behavioural scores on all report cards. Onboarding checklists must call this out.

4. **Immutable-by-design tables require test coverage before any code goes to production.** `bha_audit_log` (CCE compliance) and `bha_incidents` (BR-BA-008 immutability) cannot be trusted without tests that verify: (a) no UPDATE reaches these tables, and (b) soft-delete calls are blocked. 0 tests means this is unverifiable today.

5. **Polarity inversion is the highest single-bug-impact computation in the module.** A reversal of the inversion formula would make the worst-behaved students score highest on behavioural assessments — a correctness failure that would be visible on CCE report cards. This is P1 test priority, not P2.

6. **Views significantly exceed screen count even for relatively small modules.** BHA has 24 screen specs but 65 blade views — 2.7× the screen count. This is consistent with other modules (ADM: 84 views vs 25 screens). Screen count is a poor proxy for blade file count.

---

## 15. Recommended Next Steps

| Priority | Action | Agent |
|----------|--------|-------|
| 1 | Create `BaAssessmentRequest` and `BaIncidentRequest` FormRequests — P1 validation gaps | Developer |
| 2 | Audit `BaAssessmentController` and `BaIncidentController` — verify if score materialisation and incident creation are in controller or service layer | Technical Auditor |
| 3 | Create `ComputeSchoolScoresJob` (queued, triggered on `AssessmentApproved` event or manual "Recompute" action) | Developer |
| 4 | Add tests: polarity inversion (highest priority), weighted avg computation, immutable audit log enforcement, Assessment FSM state transitions | Testing Architect |
| 5 | Generate FRD — must synthesise all 24 screen files + DDL v2 + 8 architecture decisions; no consolidated req file available | Business Analyst → "create an FRD for BehaviouralAssessment" |
| 6 | Create `AssessmentService` and `IncidentService` to extract controller logic | Developer (after audit confirms fat-controller state) |
| 7 | Document `bha_config` activation in school onboarding checklist | Business Analyst |
| 8 | Create tenant migrations for all 16 BHA tables (6-layer order) | Developer |
