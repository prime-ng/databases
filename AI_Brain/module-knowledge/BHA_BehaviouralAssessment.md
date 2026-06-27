# Module Knowledge: BehaviouralAssessment (BHA)
# Last Updated: 2026-06-27 (re-seeded — file counts re-verified, DDL + screen specs re-confirmed)
# Completion Status: ~50–55% (models/controllers/policies all present; 65 views; core service done; 0 tests critical; ComputeSchoolScoresJob missing; FormRequest coverage incomplete)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `bha_*` |
| Module path | `Modules/BehaviouralAssessment/` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/BehaviouralAssess_DDL_v2.sql` — 16 tables |
| Consolidated V2 Req | Not present in `4-Initial_Requirements/V2/` |
| Detailed Screen Specs | `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/` — 24 screen files **(primary req source)** |
| Database | `tenant_db` |
| Controllers | **12** (re-verified 2026-06-27) |
| Models | **16** (re-verified 2026-06-27 — matches DDL table count exactly) |
| Services | **1** (re-verified 2026-06-27 — **corrected from prior 4**; only `BehaviouralScoreService.php` exists) |
| FormRequests | **5** (re-verified 2026-06-27 — covers 5 of 12 controllers; assessment + incident entry unvalidated) |
| Policies | **17** (re-verified 2026-06-27) |
| Tests | **0** (re-verified 2026-06-27) |
| Blade Views | **65** (re-verified 2026-06-27 — not recorded at seeding) |
| Routes | **111 lines** in `web.php` (not recorded at seeding) |
| Jobs | **0** — `ComputeSchoolScoresJob` referenced in D3 but not created |
| Migrations | **0** — module uses DDL directly |
| FRD | Not yet generated |

**Service inventory (all 1):**
| Service | Covers |
|---------|--------|
| `BehaviouralScoreService` | Core score computation (polarity inversion, weighted avg, grade mapping); `getBulkScores()` for pull-based result integration |

**FormRequest coverage map:**
| Controller | FormRequest | Status |
|------------|-------------|--------|
| BaRatingScaleController | BaRatingScaleRequest | ✅ |
| BaCategoryController | BaCategoryRequest | ✅ |
| BaInterventionController | BaInterventionRequest | ✅ |
| BaAssessmentPeriodController | BaAssessmentPeriodRequest | ✅ |
| BaConfigController | BaConfigRequest | ✅ |
| BaAssessmentController | — | ❌ Missing (core rating entry) |
| BaIncidentController | — | ❌ Missing (incident creation/update) |
| BaClassCategoryController | — | ❌ Missing (class-category mapping) |
| BaDashboardController | — | N/A (read-only) |
| BaReportController | — | N/A (read-only) |
| BaAuditLogController | — | N/A (read-only) |
| BehaviouralAssessmentController | — | N/A (base/navigation) |

**Note:** No consolidated V2 requirement file exists for this module. The 24 screen-spec files in `2-Module_Requirement_V1/BehaviouralAssessment_v2/` are the primary requirement source. The DDL (BehaviouralAssess_DDL_v2.sql, April 2026) is well-documented with per-table comments and a full dependency architecture diagram. Test coverage is zero — critical gap for a module with an immutable audit trail requirement.

---

## DDL Table Inventory (16 tables — 6 Dependency Layers)

### Layer 1 — Foundation (no deps on other bha_* tables)
| Table | Purpose |
|-------|---------|
| `bha_rating_scales` | Configurable rating scales (5-Point, 3-Point, etc.); `min_rating`/`max_rating` drive score normalisation and negative polarity inversion |
| `bha_categories` | Behavioural categories with `polarity` (positive/negative) and `weight`; 9 seeded (5 positive, 4 negative); supports self-referencing hierarchy |
| `bha_interventions` | Master list of 9 predefined interventions: 3 reward, 4 corrective, 2 counselling |

### Layer 2 — Detail (depends on Layer 1)
| Table | Purpose |
|-------|---------|
| `bha_rating_levels` | Individual levels within a scale (e.g., Outstanding=5, Good=3); `numeric_value` feeds score computation |
| `bha_criteria` | Observable behavioural criteria within categories; 58 seeded across 9 categories; `weight` determines contribution to category score |

### Layer 3 — Configuration (depends on sch_* + Layer 1)
| Table | Purpose |
|-------|---------|
| `bha_class_category_jnt` | Maps which categories apply to which classes (`sch_classes`); permissive default (all categories if no mapping) |
| `bha_assessment_periods` | Time windows for teacher data entry; lifecycle: `open → closed → locked`; optional link to `sch_academic_term` |
| `bha_config` | One record per academic session; active rating scale, result integration toggle (default OFF), weightage % (5–20%), aggregation method, parent notification threshold |

### Layer 4 — Transaction Headers (depends on Layer 3 + sch_*)
| Table | Purpose |
|-------|---------|
| `bha_assessments` | Assessment header per teacher per class-section per period; UNIQUE(teacher_id, class_section_id, period_id); workflow: `draft → submitted → reviewed → locked` with send-back |
| `bha_audit_log` | **Immutable** audit trail for rating changes and status transitions; no `updated_at`, no `deleted_at`; required for CBSE/ICSE CCE compliance |

### Layer 5 — Core Transaction Data (depends on Layer 4 + Layer 2 + sch_*)
| Table | Purpose |
|-------|---------|
| `bha_assessment_ratings` | **Core fact table** — one row per student per criterion per assessment; `rating_level_id` NULL = not yet rated; auto-saved every 30s; UNIQUE(assessment_id, student_id, criterion_id) |
| `bha_student_remarks` | Overall teacher remarks per student per assessment (separate from per-criterion remarks); appears on report card |
| `bha_computed_scores` | **Materialised score cache** — computed scores per student per category per period; UPSERT on recomputation; consumed by Exam/Result module via `BehaviouralScoreService::getBulkScores()` |
| `bha_incidents` | Ad-hoc positive/negative behavioural events; core fields immutable after creation; location tracking (8 locations); severity: minor/moderate/major/critical; attachments via `attachments_json` JSON column |

### Layer 6 — Junction Tables (depends on Layer 5 + Layer 1)
| Table | Purpose |
|-------|---------|
| `bha_incident_witnesses_jnt` | Polymorphic witnesses (student or staff) for incidents; no DB-level FK — app-layer enforced |
| `bha_incident_intervention_jnt` | N:M mapping of incidents to interventions applied; per-application `notes` field |

---

## Architecture Decisions

### D1 — Polarity Inversion for Negative Categories
Negative categories (e.g., "Disruptive Behaviours", "Bullying") score inversely: `inverted_score = (max_scale_value + 1) - raw_rating`. So a student rated 5 (worst) on "Bullying" gets inverted score of 1. Handled at service layer, not DB.

### D2 — Weighted Average Score Computation Flow
```
bha_assessment_ratings (raw ratings per student per criterion)
  → GROUP BY criterion → AVG across all teachers (multi-teacher averaging)
  → For negative polarity criteria: invert
  → GROUP criteria BY category → WEIGHTED_AVG(criterion.weight) → category_score
  → WEIGHTED_AVG(category.weight, per aggregation_method) → overall_score
  → Map to grade via bha_rating_scales min/max boundaries
  → UPSERT to bha_computed_scores
```

### D3 — Computed Score Cache (`bha_computed_scores`)
Scores are never computed at query time. They are materialised into `bha_computed_scores` and served from there. Triggers: `AssessmentApproved` event (per class-section) or manual "Recompute" → `ComputeSchoolScoresJob`.

### D4 — Result Integration is Pull-Based
The Exam/Result module calls `BehaviouralScoreService::getBulkScores()` — the BA module never writes to `exm_*` tables. Integration is gated by `bha_config.is_result_integration_enabled` (default OFF).

### D5 — Assessment Period vs Academic Term
`bha_assessment_periods` has optional `academic_term_id → sch_academic_term`. When linked, behavioural scores appear alongside term-wise exam results. If NULL, period is independent (e.g., monthly review).

### D6 — Incident Immutability (BR-BA-008)
Core incident fields (student_id, date, type, severity, description, location) CANNOT be modified after creation. Only `follow_up_notes`, `follow_up_date`, `is_follow_up_required`, `is_notified` can be updated. Enforced at service layer.

### D7 — `bha_class_category_jnt` Maps to `sch_classes` Not `sch_class_groups_jnt`
`sch_class_groups_jnt` is a class+section+subject+studyFormat junction for Timetable — NOT a primary/secondary grouping. The correct table for grade-level mapping is `sch_classes`.

### D8 — `bha_audit_log` is Immutable
No `updated_at`, no `deleted_at`. Once a row is inserted it is never modified. Required for CBSE/ICSE CCE compliance.

---

## Seeded Data (provisioned on tenant onboarding)

| Data | Detail |
|------|--------|
| Rating scale | 1 scale: "5-Point Behavioural Scale" (code: 5_POINT); min 1.0, max 5.0 |
| Rating levels | 5 levels: Outstanding(5), Very Good(4), Good(3), Needs Improvement(2), Unsatisfactory(1) |
| Categories | 9 total: 5 positive + 4 negative (see below) |
| Criteria | 58 total across 9 categories |
| Interventions | 9: 3 reward (Award/Certificate, Public Recognition, Extra Privileges), 4 corrective (Verbal Warning, Written Warning, Detention, Suspension), 2 counselling (Parent Meeting, Counselling Referral) |
| bha_config | **NOT seeded** — auto-created with defaults on first access |

**9 Categories:**
- Positive (5): Classroom Engagement (8 criteria), Respect & Responsibility (8), Cooperation & Collaboration (7), Emotional & Social Development (6), Leadership & Initiative (6)
- Negative (4): Disruptive Behaviours (7), Aggressive/Bullying (6), Academic Misconduct (6), Health & Safety Violations (4)

---

## Assessment Workflow FSMs

**Assessment:** `draft → submitted → reviewed → locked` (send-back: reviewed/submitted → draft with remarks)

**Assessment Period:** `open → closed → locked` (reopen: closed → open)

---

## V1 Screen Inventory (24 screens — in BehaviouralAssessment_v2/ folder)

| File | Screen |
|------|--------|
| 00-Module-Overview.md | Module overview |
| 01-Dashboard.md | Dashboard |
| 02-Rating-Scales.md | Rating scale management |
| 03-Categories.md | Category management |
| 04-Interventions.md | Intervention master |
| 05-Class-Mapping.md | Class-category mapping |
| 06-Periods.md | Assessment period management |
| 07-Configuration.md | Module configuration |
| 08-My-Assessments.md | Teacher's assessment list |
| 09-Ratings.md | Rating grid (core data entry) |
| 10-Remarks.md | Student remarks |
| 11-Review-Queue.md | Principal/HOD review queue |
| 12-Incident-Log.md | Incident log |
| 13-Witnesses.md | Witness management |
| 14-Interventions-Applied.md | Intervention application |
| 15-Reports-Hub.md | Reports hub |
| 16-Student-Scores-Report.md | Student scores report |
| 17-Category-Summary.md | Category summary |
| 18-Period-Report.md | Period report |
| 19-Audit-Trail.md | Audit trail view |
| 20-Student-Report.md | Student report card |
| 21-Class-Analysis.md | Class-level analysis |
| 22-Period-Progress.md | Period progress tracker |
| 23-Category-Performance.md | Category performance report |
| 24-Incident-Report.md | Incident analytics report |

---

## Known Gaps & Open Issues

| Priority | Gap | Detail |
|----------|-----|--------|
| P1 | **0 tests** | No test files in `tests/`. Immutable `bha_audit_log` (CBSE/ICSE CCE compliance), polarity inversion, weighted avg computation, and FSM transitions are all high-risk without coverage. |
| P1 | **Missing `BaAssessmentRequest`** | Core data entry (rating grid) has no FormRequest — no server-side validation on assessment submissions. |
| P1 | **Missing `BaIncidentRequest`** | Incident creation/update has no FormRequest — severity, student, date unvalidated at request layer. |
| P1 | **`ComputeSchoolScoresJob` not created** | D3 describes this job (`AssessmentApproved` event or manual "Recompute" → job). No Jobs directory exists. Score recomputation may be called synchronously from a controller — needs audit. |
| P2 | **Only 1 service** | `BehaviouralScoreService` is the only service file. No dedicated `AssessmentService`, `IncidentService`, or `ReportService` — business logic likely in controllers (fat controller risk). |
| P2 | **Missing `BaClassCategoryRequest`** | Class-category mapping (which categories apply to which class) has no FormRequest. |
| P2 | **`bha_config` not seeded** | Config is auto-created on first access; result integration is OFF by default. Must be explicitly enabled per school per session — needs documentation for school onboarding. |
| P3 | **No consolidated V2 req** | No `BHA_BehaviouralAssessment_Requirement.md` in `4-Initial_Requirements/V2/`. FRD generation must read all 24 files in `2-Module_Requirement_V1/BehaviouralAssessment_v2/` + DDL. |
| P3 | **Events/Listeners missing** | D3 references `AssessmentApproved` event. No `Events/` or `Listeners/` directory found — event may be dispatched differently or not at all. |

---

## Design Decisions Made

(No session-level decisions recorded yet — seeded from DDL v2 comments and V1 screen specs. See Architecture Decisions D1–D8 above for design decisions embedded in the DDL.)

---

## Cross-Module Dependencies

| Dependency | Table | PK Type | BA Usage |
|------------|-------|---------|---------|
| StudentProfile (STD) | `std_students` | INT UNSIGNED | Student being assessed/incident subject |
| SchoolSetup (SCE) | `sch_employees` | INT UNSIGNED | Teacher (assessor), reviewer, incident reporter |
| SchoolSetup (SCC) | `sch_class_section_jnt` | INT UNSIGNED | Class+section scope for assessments |
| SchoolSetup (SCO) | `sch_classes` | INT UNSIGNED | Category applicability mapping |
| SchoolSetup (SCO) | `sch_org_academic_sessions_jnt` | SMALLINT UNSIGNED | Session scoping for periods + config |
| SchoolSetup (SCO) | `sch_academic_term` | SMALLINT UNSIGNED | Optional link from assessment periods to exam terms |
| LmsExam (EXM) | (read-only consumer) | — | Exam/Result module calls BehaviouralScoreService for result integration |
| Notification (NTF) | (event consumer) | — | `IncidentCreated` event → parent notification when severity ≥ threshold |

**All BA dependencies are read-only — BA never writes to external module tables.**

---

## Lessons Learned

(Empty — no session work yet. Will populate after FRD or audit sessions.)

---

## Pending Next Steps

- [ ] Generate FRD → `act as Business Analyst` → "create an FRD for BehaviouralAssessment"
- [ ] Code Gap Analysis → `act as Technical Auditor` — verify if controller logic is in controllers or nowhere (fat controller risk), confirm how/where `ComputeSchoolScoresJob` is triggered, check if `AssessmentApproved` event is dispatched
- [ ] Create missing FormRequests: `BaAssessmentRequest`, `BaIncidentRequest`, `BaClassCategoryRequest`
- [ ] Create `ComputeSchoolScoresJob` (queued, triggered on `AssessmentApproved` or manual recompute)
- [ ] Test Coverage → `act as Testing Architect` — 0 tests is critical; priority: polarity inversion logic, weighted avg computation, immutable audit log enforcement, Assessment FSM transitions
- [ ] Decide on service extraction: `AssessmentService` (rating grid save, FSM), `IncidentService` (create/update + witness/intervention linking) — currently only `BehaviouralScoreService` exists

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from BehaviouralAssess_DDL_v2.sql (16 tables) + detailed screen specs in `2-Module_Requirement_V1/BehaviouralAssessment_v2/` (24 screens). No consolidated V2 requirement file. File counts recorded as: 12 ctrl, 16 models, 4 services (later corrected), 5 FormRequests, 17 policies, 0 tests. Initial seeding had wrong requirement path (fixed in business-analyst.md). |
| 2026-06-27 | Business Analyst | Re-seed pass: re-verified all file counts against prime_ai/Modules/BehaviouralAssessment/. Corrections: services = 1 (not 4 — only BehaviouralScoreService exists). Added: 65 blade views, 111 route lines, 0 jobs. Added FormRequest coverage map (3 critical FormRequests missing). Added ComputeSchoolScoresJob as P1 gap. Completion estimate set to ~50–55%. |
