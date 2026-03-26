# PredictiveAnalytics Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** PAN | **Module Path:** `Modules/PredictiveAnalytics`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `pan_*` | **Processing Mode:** RBS_ONLY (Greenfield)
**RBS Reference:** Module U — Predictive Analytics & ML Engine (lines 4038-4162)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The PredictiveAnalytics (PAN) module is Prime-AI's intelligence layer — it aggregates data from all operational modules (attendance, exams, fees, behavior, transport, LXP engagement) and applies ML-driven models and statistical analysis to predict future outcomes, identify at-risk students, expose institutional inefficiencies, and enable proactive interventions. While the Recommendation module (`rec_*`) handles rule-based, reactive content suggestions, PAN handles forward-looking, probabilistic predictions and multi-dimensional school KPI analytics.

The module serves three primary user personas: the **Principal/Admin** (school KPI health, early warning system, benchmarking), the **Teacher** (class-level performance predictions, skill gap analysis, drop-off risks), and the **System** (automated early warning triggers that feed notifications and Recommendation module updates).

### 1.2 Scope

This module covers:
- **U1 — Student Performance Prediction:** ML-driven score prediction for end-of-term exams based on attendance, mid-term scores, quiz performance, and LXP engagement
- **U2 — Attendance Forecasting:** Absence probability prediction using historical patterns and anomaly detection
- **U3 — Fee Default Prediction:** Fee payment default risk assessment based on payment history and parent segmentation
- **U4 — Skill Gap Analysis:** Competency gap identification per student and per class using LXP skill scores
- **U5 — Transport Route Optimization:** Analytics on GPS/route data for efficiency recommendations
- **U6 — Resource Allocation Optimization:** Teacher workload balancing and room utilization analytics
- **U7 — AI Dashboards & Visualization:** Interactive school KPI dashboard, what-if scenario modeling, custom report builder
- **U8 — Sentiment & Feedback Analysis:** NLP-based analysis of survey comments, complaints, and forum posts
- **U9 — Institutional Benchmarking:** KPI comparison against anonymized peer group data with gap analysis

Out of scope for v1: real-time streaming analytics (events processed in batch via scheduled jobs), external ML API integration (Python/scikit-learn microservices — all models are PHP-implemented heuristics and statistical models in v1 with architecture to swap to external ML later), direct DigiLocker/government API integration, cross-tenant benchmarking requiring GDPR-equivalent consent flows (v1 uses aggregate anonymized data only).

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| RBS Features (F.U*) | 22 (U1–U9) |
| RBS Tasks | 33 |
| RBS Sub-tasks | 51 |
| Proposed DB Tables (pan_*) | 12 |
| Proposed Named Routes | ~60 |
| Proposed Blade Views | ~35 |
| Proposed Controllers | 9 |
| Proposed Models | 12 |
| Proposed Services | 6 |
| Proposed Jobs | 4 (one per prediction model type) |
| Proposed Console Commands | 4 (scheduled model runs) |

### 1.4 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ❌ Not Started | 12 tables proposed |
| Models | ❌ Not Started | 12 models proposed |
| Controllers | ❌ Not Started | 9 controllers proposed |
| Services | ❌ Not Started | 6 services proposed |
| Jobs / Commands | ❌ Not Started | 4 queue jobs + 4 Artisan commands |
| Blade Views | ❌ Not Started | ~35 views proposed |
| Routes | ❌ Not Started | tenant.php additions required |
| Tests | ❌ Not Started | Feature + Unit tests proposed |

**Overall Implementation: 0% — Greenfield**

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

Indian school management faces three persistent blind spots: they don't know which students will fail before they fail, they don't know which students will stop attending before they stop attending, and they don't know which fee payers will default before they default. By the time these outcomes occur, the window for intervention has closed.

PAN solves these blind spots by:

1. **Performance prediction** — combine attendance rate, mid-term exam percentile, quiz consistency, and homework submission rate into a regression model that predicts each student's end-of-term score with a confidence interval. Students predicted to score below the pass mark (35% for most CBSE subjects) are flagged weeks in advance.
2. **Attendance forecasting** — analyze each student's historical attendance by day-of-week, month, and surrounding events to predict which students are likely to absent themselves next week. Class teachers can intervene proactively.
3. **Fee default prediction** — classify parents into payment behavior clusters and flag those with deteriorating patterns before the term fee deadline.
4. **Skill gap identification** — using LXP skill scores, identify the specific competencies where a student (or an entire class) is below grade-level expectation. These gaps are automatically forwarded to the Recommendation module as trigger events.
5. **Institutional KPI dashboard** — principals see enrollment growth trend, average attendance, exam pass rate, fee collection ratio, teacher retention — all in one view with YoY comparison.
6. **Sentiment monitoring** — NLP processing of open-ended feedback, complaint descriptions, and forum posts surfaces emerging concerns (a sudden spike in negative sentiment about a particular teacher, or infrastructure issues) before they become formal complaints.
7. **Transport optimization** — analyze GPS and ridership data to suggest route merges or stops consolidation that reduce fuel costs.
8. **Benchmarking** — compare the school's KPIs against an anonymized cohort of similar schools on the Prime-AI platform.

### 2.2 Key Features Summary

| Feature Area | Description | RBS Ref | Status |
|---|---|---|---|
| Student Performance Prediction | End-of-term score prediction + risk scoring | U1 | ❌ Not Started |
| Early Warning System | Automated alerts for high-risk students | U1.F.U1.2 | ❌ Not Started |
| Attendance Forecasting | Absence probability + anomaly detection | U2 | ❌ Not Started |
| Fee Default Prediction | Payment risk scoring + parent segmentation | U3 | ❌ Not Started |
| Skill Gap Analysis | Student + class-level competency gap identification | U4 | ❌ Not Started |
| Transport Route Optimization | Route efficiency analytics + simulation | U5 | ❌ Not Started |
| Resource Allocation | Teacher workload + room utilization analytics | U6 | ❌ Not Started |
| AI Dashboards | KPI dashboard, what-if modeling, insights feed | U7 | ❌ Not Started |
| Custom Report Builder | Drag-and-drop cross-module report builder | U7.F.U7.3 | ❌ Not Started |
| Sentiment Analysis | NLP categorization of feedback and complaints | U8 | ❌ Not Started |
| Institutional Benchmarking | Anonymized KPI comparison vs peer group | U9 | ❌ Not Started |

### 2.3 Menu Navigation Path

```
School Admin / Teacher Panel
└── Analytics [/analytics]
    ├── Dashboard                [/analytics/dashboard]          (KPI overview)
    ├── Early Warnings           [/analytics/early-warnings]
    ├── Student Predictions
    │   ├── Performance          [/analytics/predictions/performance]
    │   ├── Attendance Risk      [/analytics/predictions/attendance]
    │   └── Fee Default Risk     [/analytics/predictions/fee-default]
    ├── Skill Gaps               [/analytics/skill-gaps]
    ├── Transport Analytics      [/analytics/transport]
    ├── Resource Allocation      [/analytics/resources]
    ├── Sentiment Analysis       [/analytics/sentiment]
    ├── Benchmarking             [/analytics/benchmarking]
    ├── What-If Scenarios        [/analytics/what-if]
    ├── Custom Reports           [/analytics/custom-reports]
    └── Model Management         [/analytics/models]             (admin only)
```

### 2.4 Proposed Module Architecture

```
Modules/PredictiveAnalytics/
├── app/
│   ├── Console/Commands/
│   │   ├── RunPerformancePredictions.php   # Scheduled: weekly
│   │   ├── RunAttendanceForecasts.php      # Scheduled: daily
│   │   ├── RunFeeDefaultPredictions.php    # Scheduled: weekly
│   │   └── RunSentimentAnalysis.php        # Scheduled: daily
│   ├── Http/Controllers/
│   │   ├── PanDashboardController.php      # KPI dashboard + insights
│   │   ├── EarlyWarningController.php      # Warning management + acknowledgment
│   │   ├── PerformancePredictionController.php  # Student score predictions
│   │   ├── AttendanceForecastController.php     # Absence forecasts
│   │   ├── FeeDefaultController.php             # Fee risk + parent segments
│   │   ├── SkillGapController.php               # Gap analysis views
│   │   ├── TransportAnalyticsController.php     # Route optimization
│   │   ├── SentimentController.php              # NLP sentiment views
│   │   ├── BenchmarkingController.php           # KPI benchmarks
│   │   └── CustomReportController.php           # Report builder
│   ├── Jobs/
│   │   ├── GeneratePerformancePredictionsJob.php
│   │   ├── GenerateAttendanceForecastsJob.php
│   │   ├── GenerateFeeDefaultPredictionsJob.php
│   │   └── RunSentimentAnalysisJob.php
│   ├── Models/
│   │   ├── PanPredictionModel.php
│   │   ├── PanStudentPrediction.php
│   │   ├── PanEarlyWarning.php
│   │   ├── PanKpiSnapshot.php
│   │   ├── PanCohortAnalysis.php
│   │   ├── PanFeeRiskProfile.php
│   │   ├── PanSkillGapSummary.php
│   │   ├── PanSentimentRecord.php
│   │   ├── PanBenchmarkKpi.php
│   │   ├── PanTransportAnalysis.php
│   │   ├── PanCustomReport.php
│   │   └── PanWhatIfScenario.php
│   ├── Policies/ (4 policies)
│   ├── Providers/
│   │   ├── PredictiveAnalyticsServiceProvider.php
│   │   └── RouteServiceProvider.php
│   └── Services/
│       ├── PerformancePredictionService.php   # Score regression model
│       ├── AttendanceForecastService.php      # Absence probability model
│       ├── FeeDefaultPredictionService.php    # Payment risk classification
│       ├── SkillGapAnalysisService.php        # Competency gap identification
│       ├── SentimentAnalysisService.php       # Rule-based NLP categorization
│       └── KpiSnapshotService.php             # KPI computation + snapshot storage
├── database/migrations/ (12 migrations)
├── resources/views/analytics/
│   ├── dashboard/             # KPI overview, insights
│   ├── early-warnings/        # Warning list, detail, acknowledgment
│   ├── predictions/           # Performance, attendance, fee default views
│   ├── skill-gaps/            # Student gap, class gap, heatmap
│   ├── transport/             # Route analysis, simulation
│   ├── sentiment/             # Sentiment trend, category breakdown
│   ├── benchmarking/          # KPI comparison, gap report
│   ├── what-if/               # Scenario builder, result display
│   └── custom-reports/        # Builder UI, saved reports, export
└── routes/
    ├── api.php
    └── web.php
```

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role in PAN Module | Permissions |
|---|---|---|
| School Admin | Full access: run models, configure KPIs, view all predictions, manage benchmarks, build custom reports | All permissions |
| Principal | View all KPI dashboards, early warnings, cohort analysis, sentiment trends, benchmarking | view-all, analytics.view |
| Teacher | View predictions for their assigned students/classes; view skill gaps; see drop-off analytics | class-scoped predictions, skill-gap.view |
| Accounts Staff | View fee default risk profiles and parent segments | fee-risk.view |
| Transport Coordinator | View transport analytics and route optimization suggestions | transport.analytics.view |
| System (Scheduler) | Runs prediction jobs via cron; generates KPI snapshots; triggers early warnings | system actor |
| Parent | Not directly; receives notifications generated by Early Warning System | notification recipient |
| Student | Not directly; benefits from interventions triggered by PAN outputs | indirect beneficiary |

---

## 4. FUNCTIONAL REQUIREMENTS

---

### FR-PAN-001: Student Performance Prediction

**RBS Reference:** F.U1.1 — Risk Prediction Models, F.U1.2 — Performance Insights
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `pan_prediction_models`, `pan_student_predictions`

#### Requirements

**REQ-PAN-001.1: Performance Prediction Model**
| Attribute | Detail |
|---|---|
| Description | For each student in each subject, predict their end-of-term exam score using a weighted multi-factor model. Input features: attendance rate (weight 0.25), mid-term score percentile (weight 0.40), quiz average score (weight 0.20), homework submission rate (weight 0.10), LXP engagement score (weight 0.05). Output: predicted score (0–100), confidence interval (±N points), and risk level. |
| Actors | System (scheduled), Admin (manual trigger) |
| Preconditions | At least 4 weeks of data in current academic session; mid-term exam results entered |
| Input | academic_session_id, class_id (optional — run for all if null) |
| Processing | For each active student-subject pair: query attendance rate from `std_attendance`; query mid-term scores from `exm_*`; query quiz averages from `quz_*`; query homework submission rate; query LXP engagement from `lxp_engagement_logs` (if LXP module active); apply weighted formula; compute risk_level (predicted < 35% → critical; 35-50% → high; 50-60% → medium; > 60% → low); insert/update `pan_student_predictions` |
| Output | Predictions created/updated; high-risk students trigger Early Warning System |
| Status | 📐 Proposed |

**REQ-PAN-001.2: Performance Prediction View**
| Attribute | Detail |
|---|---|
| Description | Teacher or admin views predictions for a class in a filterable table: student name, subject, predicted score, current actual score (if available), risk level badge, trend indicator (improving/declining). Includes option to view per-student factor breakdown (which factors are dragging the prediction down). |
| Processing | Query `pan_student_predictions` with join to std_students, sch_subjects, sch_classes; filter by class/section/subject/risk_level |
| Output | Table + optional bar chart of predicted score distribution |
| Status | 📐 Proposed |

**REQ-PAN-001.3: Weak Concept Identification**
| Attribute | Detail |
|---|---|
| Description | Beyond overall score prediction, identify specific syllabus topics or skills where the student's performance is weakest. Uses LXP skill scores and past quiz topic-wise analysis. |
| Addresses | ST.U1.2.1.1 — Identify weak concepts; ST.U1.2.1.2 — Highlight performance trends |
| Processing | For each student: join `lxp_student_skills` skill scores with skills mapped to the subject; identify skills with score < 50%; list these as "weak areas" in the prediction detail view |
| Output | "Weak Areas" list per student in prediction detail; these link to the Recommendation module to trigger targeted content |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.U1.1.1.1 — Model analyzes attendance, marks, and engagement as input factors
- [ ] ST.U1.1.1.2 — Risk score generated per student per subject
- [ ] ST.U1.1.1.3 — Subjects with potential failure identified
- [ ] ST.U1.1.2.1 — High-risk students trigger early warning alerts
- [ ] ST.U1.1.2.2 — Alert recommendations sent to class teacher
- [ ] ST.U1.2.1.1 — Weak concepts listed per student
- [ ] ST.U1.2.1.2 — Performance trend (improving/declining) indicated

**Proposed Test Cases:**
| # | Scenario | Type | Priority |
|---|---|---|---|
| 1 | Student with 40% attendance, 30% mid-term score → predicted score < 35%, risk=critical | Unit | High |
| 2 | Model runs for entire class; all students have predictions generated | Feature | High |
| 3 | High-risk student prediction triggers early warning creation | Feature | High |
| 4 | Factor breakdown correctly identifies attendance as primary risk driver | Unit | Medium |

---

### FR-PAN-002: Dropout Risk Assessment

**RBS Reference:** FR-PAN-002 (platform specification combining U1 early warning + U2 attendance)
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `pan_student_predictions`, `pan_early_warnings`

#### Requirements

**REQ-PAN-002.1: Composite Dropout Risk Score**
| Attribute | Detail |
|---|---|
| Description | A composite dropout risk score (0–100) computed per student by combining: attendance decline trend (weight 0.35), performance risk level (weight 0.25), fee payment delay pattern (weight 0.20), behavioral incidents count (weight 0.10), engagement decline in LXP (weight 0.10). Students with score > 70 are flagged as HIGH dropout risk. |
| Processing | Aggregate signals from `std_attendance`, `pan_student_predictions`, `fin_fee_transactions`, `beh_*` (behavioral incidents), `lxp_engagement_logs`; compute composite score; store in `pan_student_predictions` with prediction_type='dropout_risk'; generate early warning if score > 70 |
| Status | 📐 Proposed |

**REQ-PAN-002.2: Dropout Risk Dashboard**
| Attribute | Detail |
|---|---|
| Description | Dedicated view showing all students with dropout risk score > 50, sorted by risk score descending. Includes risk factor breakdown, days-since-last-engagement, and intervention history. |
| Processing | Query `pan_student_predictions` where prediction_type='dropout_risk' ORDER BY predicted_value DESC; join early warnings and intervention notes |
| Output | Risk ranked student list with factor breakdown |
| Status | 📐 Proposed |

---

### FR-PAN-003: Learning Gap Analysis

**RBS Reference:** F.U4 — Skill Gap Analysis
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `pan_skill_gap_summaries`

#### Requirements

**REQ-PAN-003.1: Student-Level Learning Gap Report**
| Attribute | Detail |
|---|---|
| Description | For a selected student and subject, generate a detailed gap analysis showing: which competencies are below grade-level expectation (expected score by curriculum vs actual LXP skill score), gap magnitude (points below expected), and recommended remedial actions. |
| Addresses | ST.U4.1.1.1 — Compare skills vs course outcomes; ST.U4.1.1.2 — Identify competencies needing improvement |
| Processing | For each skill mapped to the subject (from `lxp_skill_content_jnt`): compare `lxp_student_skills.skill_score` to `expected_grade_level_score` (configurable per skill, default 60%); gaps where skill_score < expected → insert `pan_skill_gap_summaries` record; sort by gap_magnitude DESC |
| Output | Gap report with top 5 most urgent gaps; "Recommended Action" links to `rec_student_recommendations` |
| Status | 📐 Proposed |

**REQ-PAN-003.2: Class-Level Skill Gap Heatmap**
| Attribute | Detail |
|---|---|
| Description | For a teacher, show a heatmap where rows = skills and columns = students in a class section. Cell color represents skill score (red < 40, yellow 40-70, green > 70). This allows teacher to identify class-wide weak spots in one view. |
| Addresses | ST.U4.3.1.1 — Identify weakest skills per class/section; ST.U4.3.1.2 — Compare across batches |
| Processing | Pivot query on `lxp_student_skills` grouped by skill_id and student_id for the class section; render as color-coded HTML grid |
| Output | Skill heatmap view for teacher |
| Status | 📐 Proposed |

**REQ-PAN-003.3: Personalized Remedial Action Trigger**
| Attribute | Detail |
|---|---|
| Description | When a gap is identified, PAN automatically triggers a Recommendation module event to create a `rec_student_recommendations` record for targeted remedial content. |
| Addresses | ST.U4.1.2.1 — Recommend additional content; ST.U4.1.2.2 — Suggest remedial classes |
| Processing | On gap identification: if gap_magnitude > 20: create `rec_student_recommendations` via RecommendationService::createFromGap(); set trigger_source='pan_gap_analysis' |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.U4.1.1.1 — Skills compared against expected grade-level scores
- [ ] ST.U4.1.1.2 — Competencies below threshold listed with gap magnitude
- [ ] ST.U4.1.2.1 — Recommendation triggered for top 3 largest gaps
- [ ] ST.U4.1.2.2 — Remedial class suggestion appears in teacher alert
- [ ] ST.U4.3.1.1 — Class heatmap identifies class-wide weak skills
- [ ] ST.U4.3.1.2 — Heatmap filterable by academic year for trend comparison

---

### FR-PAN-004: Teacher Effectiveness Analytics

**RBS Reference:** U6 — Resource Allocation (teacher workload); extended to teacher outcomes
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `pan_kpi_snapshots`

#### Requirements

**REQ-PAN-004.1: Teacher Performance Metrics**
| Attribute | Detail |
|---|---|
| Description | Analyze student outcomes correlated to teacher assignment. For each teacher: average class exam score in their subjects, year-over-year improvement rate, homework completion rate in their classes, quiz average, student attendance in their periods. Note: this is purely analytical (no direct HR evaluation output) — for school admin use only. |
| Input | academic_session_id, teacher_id (optional — all teachers if null) |
| Processing | Aggregate from `exm_*` exam results grouped by class → join timetable → identify teacher per class-subject; compute mean score, YoY delta (compare to previous session), attendance rate in that teacher's periods |
| Output | Teacher effectiveness table; sortable by each metric |
| Status | 📐 Proposed |

**REQ-PAN-004.2: Optimal Teacher-Workload Distribution**
| Attribute | Detail |
|---|---|
| Description | Show current teaching hour distribution per teacher vs recommended maximum. Flag teachers with > 30 periods/week as overloaded. Recommend redistribution where applicable. |
| Addresses | ST.U6.1.1.1 — Recommend optimal teacher distribution; ST.U6.1.1.2 — Balance teaching hours |
| Processing | Count periods from timetable; compare to `tt_config.max_periods_per_day × working_days` per teacher; flag overloaded teachers; suggest redistribution |
| Output | Workload balance chart; overloaded teachers highlighted |
| Status | 📐 Proposed |

---

### FR-PAN-005: School KPI Dashboard

**RBS Reference:** F.U7.1 — AI Dashboards
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `pan_kpi_snapshots`, `pan_cohort_analyses`

#### Requirements

**REQ-PAN-005.1: KPI Snapshot Computation**
| Attribute | Detail |
|---|---|
| Description | `KpiSnapshotService` runs daily (via scheduled job) to compute and store school-wide KPIs as time-series snapshots. KPIs computed: total active enrollment, attendance rate (%, daily), exam pass rate (% students passing in latest exam), fee collection ratio (collected / expected × 100), new admissions this month, number of open complaints, teacher retention rate (for current year). |
| Processing | For each KPI: query the relevant source tables; compute value; insert `pan_kpi_snapshots` record with snapshot_date = today; compute trend by comparing to 7-days-ago and 30-days-ago values |
| Output | KPI snapshots stored for dashboard display |
| Status | 📐 Proposed |

**REQ-PAN-005.2: KPI Dashboard View**
| Attribute | Detail |
|---|---|
| Description | Principal/Admin sees a visual dashboard with KPI cards (current value + trend arrow + % change from last month), trend line charts (30-day rolling), and a "School Health Score" composite index. |
| Processing | Read from `pan_kpi_snapshots` for the last 30 days; compute composite score as weighted average of normalized KPI values |
| Output | Dashboard with KPI cards, trend charts, health score |
| Status | 📐 Proposed |

**REQ-PAN-005.3: Cohort Analysis**
| Attribute | Detail |
|---|---|
| Description | Compare the performance of the current academic cohort against previous years for the same class level. E.g., "Class X 2025-26 vs Class X 2024-25 vs Class X 2023-24" on metrics: exam pass %, average score, attendance rate. Stored as reusable named analyses. |
| Addresses | ST (cohort analysis — comparing class performance across years) |
| Input | name, base_session_id, comparison_session_ids (array), metric_type ENUM('exam_pass_rate','avg_score','attendance','fee_collection'), class_id (optional) |
| Processing | Compute metric for base + each comparison session; store comparison_results_json; generate percentage change between cohorts |
| Output | Multi-line chart; tabular comparison; stored as `pan_cohort_analyses` record for reuse |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] KPI snapshot runs daily without manual trigger
- [ ] Dashboard shows trend direction (up/down/stable) correctly
- [ ] Cohort analysis shows multiple academic year comparison on same chart
- [ ] School Health Score is recalculated on each snapshot

---

### FR-PAN-006: Early Warning System

**RBS Reference:** F.U1.1.2 — Early Warning Alerts, F.U2.1.2 — Suggest Interventions
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `pan_early_warnings`

#### Requirements

**REQ-PAN-006.1: Warning Generation**
| Attribute | Detail |
|---|---|
| Description | Automatic early warning creation for students meeting risk thresholds. Warning types: ATTENDANCE (< 75% in last 2 weeks), PERFORMANCE (predicted score < 35%), FEE (payment overdue > 30 days), BEHAVIOUR (3+ incidents in a week), ENGAGEMENT (no LXP activity in 14 days). Each warning has a severity level. |
| Actors | System (automated), Admin (manual create for ad-hoc warnings) |
| Processing | Triggered at end of each prediction/forecast job run; also triggerable via webhook from source modules; `pan_early_warnings` created with warning_type, severity, student_id, message auto-constructed from template |
| Output | Warning record created; notification sent to class teacher; push notification to admin |
| Status | 📐 Proposed |

**REQ-PAN-006.2: Warning Management and Acknowledgment**
| Attribute | Detail |
|---|---|
| Description | Class teacher or admin reviews warnings for their students, acknowledges each warning, and records the intervention taken. Acknowledged warnings are removed from the active queue. Unacknowledged critical warnings escalate to admin after 48 hours. |
| Input | warning_id, is_acknowledged = true, intervention_notes TEXT, next_action ENUM('parent_call','counseling','study_plan','none') |
| Processing | Update `pan_early_warnings.is_acknowledged = 1`; record `acknowledged_by` + `acknowledged_at`; log intervention in `sys_activity_logs`; if critical and unacknowledged after 48h: escalate |
| Output | Warning removed from active queue; intervention logged |
| Status | 📐 Proposed |

**REQ-PAN-006.3: Warning History**
| Attribute | Detail |
|---|---|
| Description | Full history of all warnings for a student — useful for counseling sessions and parent meetings to show a pattern of risk signals over time |
| Processing | Query all `pan_early_warnings` for student_id regardless of `is_acknowledged`; include intervention notes |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] Attendance warning created when student drops below 75% in last 2 weeks
- [ ] Performance warning created for predicted score < 35%
- [ ] Class teacher receives notification on warning creation
- [ ] Unacknowledged critical warnings escalate to admin after 48h
- [ ] Intervention notes are recorded per warning

---

### FR-PAN-007: Cohort Analysis

**RBS Reference:** Covered in FR-PAN-005.3 above (linked to `pan_cohort_analyses`)
**Priority:** 🟡 High — see FR-PAN-005.3

---

### FR-PAN-008: Subject Difficulty Analysis

**RBS Reference:** U4 — Skill Gap (institutional view), U7 — AI Dashboards
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `pan_kpi_snapshots`

#### Requirements

**REQ-PAN-008.1: Topic-Level Failure Analysis**
| Attribute | Detail |
|---|---|
| Description | Identify which syllabus topics and subject areas cause the most student failures. Uses exam and quiz question-level performance data. Topics where > 40% of students score < 40% on related questions are flagged as "High Difficulty" topics warranting curriculum review or additional teaching time. |
| Processing | Aggregate question-level scores from `quz_*` (if question-topic mapping exists) or exam sub-section scores from `exm_*`; group by syllabus topic; compute failure rate; flag topics > 40% failure rate |
| Output | Subject difficulty report; sortable by failure rate; downloadable CSV |
| Status | 📐 Proposed |

---

### FR-PAN-009: Recommendation Trigger Integration

**RBS Reference:** ST.U4.1.2 — Generate Personalized Actions
**Priority:** 🔴 Critical (architecture integration point)
**Status:** ❌ Not Started

#### Requirements

**REQ-PAN-009.1: PAN-to-Recommendation Pipeline**
| Attribute | Detail |
|---|---|
| Description | When PAN identifies a learning gap, dropout risk, or performance risk for a student, it automatically creates a recommendation trigger in the Recommendation module. This closes the loop: PAN detects → Recommendation module suggests intervention → LXP executes the intervention via learning path update. |
| Processing | On gap identification (gap_magnitude > 20) or performance risk (predicted < 40%): call `RecommendationService::createFromPan(student_id, trigger_type, context_data)`; this creates a `rec_student_recommendations` record with the appropriate material targeting the identified weakness; the LXP PathSuggestionService picks this up in next path generation cycle |
| Output | `rec_student_recommendations` record created; LXP path updated at next generation cycle |
| Status | 📐 Proposed |

---

### FR-PAN-010: ML Model Management

**RBS Reference:** U7 — AI Dashboards (model management)
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `pan_prediction_models`

#### Requirements

**REQ-PAN-010.1: Model Configuration**
| Attribute | Detail |
|---|---|
| Description | Admin configures each prediction model's parameters: which input features to include, their relative weights, threshold values for risk level classification, and whether the model is active (runs in scheduled jobs). |
| Input | model_name, model_type ENUM('performance','dropout','learning_gap','attendance_forecast','fee_default','sentiment'), version, feature_weights_json (e.g., `{"attendance":0.25,"mid_term_score":0.40,...}`), threshold_config_json (risk level thresholds), is_active |
| Processing | Create/update `pan_prediction_models`; the scheduled jobs read `is_active=true` models of the relevant type when running |
| Output | Model saved; next scheduled run uses updated configuration |
| Status | 📐 Proposed |

**REQ-PAN-010.2: Model Accuracy Tracking**
| Attribute | Detail |
|---|---|
| Description | After actual results are available (e.g., after final exams), the system compares predicted scores with actual scores and computes Mean Absolute Error (MAE) for the performance model. This accuracy metric is stored in `pan_prediction_models.accuracy_score` to track model quality over time. |
| Processing | After end-of-term exam scores entered: join `pan_student_predictions` (predicted) with `exm_*` (actual); compute MAE; update `pan_prediction_models.accuracy_score`; store validation_results_json |
| Output | Accuracy score updated; admin alerted if accuracy degrades below 70% threshold |
| Status | 📐 Proposed |

---

### FR-PAN-011: Attendance Forecasting

**RBS Reference:** F.U2 — Attendance Forecasting
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `pan_student_predictions`

#### Requirements

**REQ-PAN-011.1: Absence Probability Prediction**
| Attribute | Detail |
|---|---|
| Description | For each student, compute the probability of absence for each day in the coming week. Uses: historical absence rate by day-of-week (Monday absences vs Friday absences), absence clusters (students who tend to miss consecutive days), seasonal patterns (absences spike around harvest season/festivals in rural schools). |
| Addresses | ST.U2.1.1.1 — Analyze past attendance & patterns; ST.U2.1.1.2 — Predict likelihood of absence |
| Processing | Query 90-day attendance history per student; compute absence probability by day-of-week; compute seasonal adjustment factor; store weekly forecast in `pan_student_predictions` with prediction_type='attendance_forecast', prediction_window='week' |
| Output | Probability forecast per student per day; students with > 60% absence probability on any upcoming day flagged to class teacher |
| Status | 📐 Proposed |

**REQ-PAN-011.2: Attendance Trend Visualization**
| Attribute | Detail |
|---|---|
| Description | Interactive chart showing weekly/monthly attendance patterns for a class or student with anomaly spikes highlighted. Admin can drill down to identify what happened on high-absence days. |
| Addresses | ST.U2.2.1.1 — Plot weekly/monthly patterns; ST.U2.2.1.2 — Highlight anomaly spikes |
| Processing | Compute class-level daily attendance rate from `std_attendance`; calculate rolling 7-day average; flag days where attendance drops > 2 standard deviations below the rolling average as anomalies |
| Output | Line chart with anomaly markers; tooltip shows absence count on hover |
| Status | 📐 Proposed |

---

### FR-PAN-012: Fee Default Prediction

**RBS Reference:** F.U3 — Fee Default Prediction
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `pan_fee_risk_profiles`

#### Requirements

**REQ-PAN-012.1: Fee Default Risk Scoring**
| Attribute | Detail |
|---|---|
| Description | Score each parent/guardian for fee default risk based on: number of overdue payments in last 2 years (weight 0.40), average days overdue (weight 0.30), total outstanding amount (weight 0.20), sibling count in school (weight 0.10). |
| Addresses | ST.U3.1.1.1 — Analyze payment history; ST.U3.1.1.2 — Identify chronic late payers |
| Processing | Query `fin_fee_transactions` and `fin_fee_dues` for each guardian; compute risk score; classify as low/medium/high; store in `pan_fee_risk_profiles`; trigger automated reminder via notification module for high-risk accounts |
| Output | Risk profiles created; accounts department view updated |
| Status | 📐 Proposed |

**REQ-PAN-012.2: Parent Segmentation**
| Attribute | Detail |
|---|---|
| Description | Cluster parents into behavioral segments: "On-Time Payers", "Occasional Late Payers", "Chronic Late Payers", "Default Risk". Each segment has tailored communication strategies. |
| Addresses | ST.U3.2.1.1 — Group parents by payment behavior; ST.U3.2.1.2 — Identify risk clusters |
| Processing | Apply K-means style classification (3–4 clusters) based on payment_delay_days and overdue_count; assign segment_label; store in `pan_fee_risk_profiles.segment_label` |
| Output | Segment distribution chart; exportable parent list per segment |
| Status | 📐 Proposed |

---

### FR-PAN-013: Transport Route Optimization Analytics

**RBS Reference:** F.U5 — Transport Route Optimization
**Priority:** 🟢 Medium
**Status:** ❌ Not Started
**Table(s):** `pan_transport_analyses`

#### Requirements

**REQ-PAN-013.1: Route Efficiency Analysis**
| Attribute | Detail |
|---|---|
| Description | Analyze transport routes using ridership data and stop utilization from the Transport module (`tpt_*`). Identify: under-utilized stops (< 3 students at any stop), routes with excessive travel time, opportunities to merge two low-ridership routes. |
| Addresses | ST.U5.1.1.1 — Analyze GPS, traffic & stop data; ST.U5.1.1.2 — Suggest shortest-time routes |
| Processing | Query `tpt_routes`, `tpt_stops`, `tpt_student_routes_jnt`; compute occupancy rate per route; compute stop utilization; flag inefficiencies; compute estimated fuel savings for each optimization suggestion |
| Output | Route efficiency report; optimization suggestions list with estimated savings |
| Status | 📐 Proposed |

**REQ-PAN-013.2: Route Simulation**
| Attribute | Detail |
|---|---|
| Description | Admin can run a simulation of merging two routes or removing low-utilization stops and see the impact on: affected students, estimated travel time change, estimated fuel saving. |
| Addresses | ST.U5.2.1.1 — Test alternate route plans; ST.U5.2.1.2 — Generate comparison reports |
| Processing | Compute simulation results based on current ridership data without actually modifying any transport records; display as comparison table: "Current" vs "Proposed" |
| Status | 📐 Proposed |

---

### FR-PAN-014: Sentiment Analysis

**RBS Reference:** F.U8 — Sentiment & Feedback Analysis
**Priority:** 🟢 Medium
**Status:** ❌ Not Started
**Table(s):** `pan_sentiment_records`

#### Requirements

**REQ-PAN-014.1: Open-Ended Feedback NLP Processing**
| Attribute | Detail |
|---|---|
| Description | Process text from: complaint descriptions (`cmp_complaints.description`), survey open-ended responses (if survey module exists), LXP forum posts (`lxp_forum_threads`). Classify each text as Positive/Neutral/Negative and extract key themes using a rule-based keyword categorization approach (not ML in v1). |
| Addresses | ST.U8.1.1.1 — Process survey comments, complaint descriptions, forum posts; ST.U8.1.1.2 — Categorize sentiment and identify key themes |
| Processing | `SentimentAnalysisService::analyze(text, source_type)` — keyword matching against positive/negative word dictionaries (Hindi + English for Indian context); theme extraction using topic keyword clusters (teaching_quality, facilities, transport, food, safety); store result in `pan_sentiment_records` |
| Output | Sentiment label + confidence score; theme tags assigned |
| Status | 📐 Proposed |

**REQ-PAN-014.2: Sentiment Trend Monitoring**
| Attribute | Detail |
|---|---|
| Description | Track sentiment over time for specific themes. Alert when negative sentiment for a topic spikes (> 3× the weekly average). |
| Addresses | ST.U8.2.1.1 — Track sentiment changes over time; ST.U8.2.1.2 — Trigger alerts for negative spikes |
| Processing | Daily aggregation of sentiment_label counts per theme; compute rolling 7-day average; detect spikes; create `pan_early_warnings` with warning_type='sentiment_spike' when detected |
| Output | Sentiment trend chart; spike alerts in admin notification feed |
| Status | 📐 Proposed |

---

### FR-PAN-015: Institutional Benchmarking

**RBS Reference:** F.U9 — Institutional Benchmarking
**Priority:** 🟢 Medium
**Status:** ❌ Not Started
**Table(s):** `pan_benchmark_kpis`

#### Requirements

**REQ-PAN-015.1: KPI Definition and Benchmarking**
| Attribute | Detail |
|---|---|
| Description | Admin selects KPIs to benchmark and compares the school's values against anonymized peer group data aggregated from all Prime-AI tenant schools of similar type (e.g., CBSE-affiliated, enrollment 500-1000 students). Peer data is computed from `prime_db` aggregate tables — individual tenant data is never exposed. |
| Addresses | ST.U9.1.1.1 — Select metrics; ST.U9.1.1.2 — Set targets; ST.U9.1.2.1 — Compare against peer group; ST.U9.1.2.2 — Gap analysis report |
| Input | kpi_types (multi-select), target_values_json, peer_group_filter (school_type, enrollment_range, board_affiliation) |
| Processing | Fetch school's own KPI values from `pan_kpi_snapshots`; fetch peer group aggregate (median, P25, P75) from prime_db anonymized benchmarks; compute gap; generate gap analysis report |
| Output | Benchmark comparison table; radar chart (own vs peer median); gap analysis narrative |
| Status | 📐 Proposed |

---

### FR-PAN-016: What-If Scenario Modeling

**RBS Reference:** F.U7.2 — What-If Analysis
**Priority:** 🟢 Medium
**Status:** ❌ Not Started
**Table(s):** `pan_what_if_scenarios`

#### Requirements

**REQ-PAN-016.1: Scenario Simulation**
| Attribute | Detail |
|---|---|
| Description | Admin defines hypothetical scenarios and the system predicts the outcome impact. Example scenarios: "If we improve attendance by 10%, how many students move from high-risk to medium-risk?"; "If we run 2 additional remedial sessions per week for Math, what is the predicted improvement in Math pass rate?"; "If we reduce fee amount by 5%, by how much does default risk reduce?" |
| Addresses | ST.U7.2.1.1 — Simulate academic/attendance changes; ST.U7.2.1.2 — Predict outcome impact |
| Input | scenario_type, input_parameter_changes_json, base_academic_session_id |
| Processing | Clone current prediction data; apply parameter changes; rerun simplified prediction model with modified inputs; compare outputs; store in `pan_what_if_scenarios` |
| Output | Side-by-side comparison: "Current State" vs "Projected State" with delta values |
| Status | 📐 Proposed |

---

### FR-PAN-017: Custom Report Builder

**RBS Reference:** F.U7.3 — Self-Service Analytics
**Priority:** 🟢 Medium
**Status:** ❌ Not Started
**Table(s):** `pan_custom_reports`

#### Requirements

**REQ-PAN-017.1: Drag-and-Drop Report Builder**
| Attribute | Detail |
|---|---|
| Description | Admin or principal can build custom analytical reports by selecting data fields from available modules, applying filters, choosing chart type, and saving the report. Reports can be shared with other admin/teacher accounts. |
| Addresses | ST.U7.3.1.1 — Drag-and-drop interface with data fields; ST.U7.3.1.2 — Save and share custom reports |
| Input | report_name, field_selections_json (selected data fields + source modules), filter_config_json, chart_type ENUM('table','bar','line','pie','scatter'), group_by, order_by |
| Processing | Build dynamic query from field_selections_json restricted to safe pre-defined field catalog (no raw SQL injection); execute query; render chart/table; save report config in `pan_custom_reports` |
| Output | Report rendered; saveable + shareable via link |
| Status | 📐 Proposed |

---

## 5. PROPOSED DATABASE SCHEMA

### 5.1 Table: `pan_prediction_models`

```sql
CREATE TABLE `pan_prediction_models` (
  `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `model_name`        VARCHAR(200) NOT NULL,
  `model_type`        ENUM('performance','dropout','learning_gap','attendance_forecast','fee_default','sentiment','resource_allocation') NOT NULL,
  `version`           VARCHAR(20) NOT NULL DEFAULT '1.0',
  `accuracy_score`    DECIMAL(5,2) NULL COMMENT 'MAE-based accuracy 0-100',
  `last_run_at`       TIMESTAMP NULL,
  `trained_at`        TIMESTAMP NULL,
  `feature_weights_json` JSON NOT NULL COMMENT 'Input factor weights, e.g. {"attendance":0.25,...}',
  `threshold_config_json` JSON NOT NULL COMMENT 'Risk level thresholds, e.g. {"critical":35,"high":50,"medium":60}',
  `validation_results_json` JSON NULL COMMENT 'Post-actual-results accuracy validation',
  `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`        BIGINT UNSIGNED NULL,
  `created_at`        TIMESTAMP NULL,
  `updated_at`        TIMESTAMP NULL,
  `deleted_at`        TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pan_model_type_version` (`model_type`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.2 Table: `pan_student_predictions`

```sql
CREATE TABLE `pan_student_predictions` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`            INT UNSIGNED NOT NULL COMMENT 'FK → std_students',
  `model_id`              INT UNSIGNED NOT NULL COMMENT 'FK → pan_prediction_models',
  `academic_session_id`   INT UNSIGNED NOT NULL,
  `subject_id`            INT UNSIGNED NULL COMMENT 'NULL for cross-subject predictions (dropout)',
  `prediction_type`       ENUM('performance','dropout_risk','attendance_forecast','skill_gap') NOT NULL,
  `predicted_value`       DECIMAL(10,2) NOT NULL COMMENT 'Score/probability/risk_score depending on type',
  `confidence_interval`   DECIMAL(5,2) NULL COMMENT 'Plus/minus value',
  `risk_level`            ENUM('low','medium','high','critical') NOT NULL DEFAULT 'low',
  `factors_json`          JSON NULL COMMENT 'Factor breakdown: {attendance:0.40, mid_term:0.35, ...}',
  `prediction_window`     VARCHAR(30) NULL COMMENT 'E.g. "end_of_term", "next_week", "30_days"',
  `generated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at`            TIMESTAMP NULL,
  `actual_value`          DECIMAL(10,2) NULL COMMENT 'Filled post-actuals for accuracy validation',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pan_pred_student_type_session` (`student_id`,`prediction_type`,`academic_session_id`),
  CONSTRAINT `fk_panPred_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_panPred_model` FOREIGN KEY (`model_id`) REFERENCES `pan_prediction_models` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.3 Table: `pan_early_warnings`

```sql
CREATE TABLE `pan_early_warnings` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`            INT UNSIGNED NOT NULL COMMENT 'FK → std_students',
  `warning_type`          ENUM('attendance','performance','fee','behaviour','engagement','sentiment_spike') NOT NULL,
  `severity`              ENUM('info','warning','critical') NOT NULL DEFAULT 'warning',
  `triggered_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `message`               TEXT NOT NULL,
  `trigger_source`        VARCHAR(100) NULL COMMENT 'Which job/service triggered this warning',
  `reference_prediction_id` INT UNSIGNED NULL COMMENT 'FK → pan_student_predictions',
  `is_acknowledged`       TINYINT(1) NOT NULL DEFAULT 0,
  `acknowledged_by`       BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
  `acknowledged_at`       TIMESTAMP NULL,
  `intervention_notes`    TEXT NULL,
  `next_action`           ENUM('parent_call','counseling','study_plan','fee_reminder','none') NULL,
  `escalated_at`          TIMESTAMP NULL COMMENT 'Timestamp when critical warning escalated to admin',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pan_warn_student_type` (`student_id`,`warning_type`,`is_acknowledged`),
  CONSTRAINT `fk_panWarn_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.4 Table: `pan_kpi_snapshots`

```sql
CREATE TABLE `pan_kpi_snapshots` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `snapshot_date`         DATE NOT NULL,
  `kpi_type`              ENUM('enrollment','attendance_rate','exam_pass_rate','fee_collection_ratio','new_admissions','open_complaints','teacher_retention','avg_exam_score') NOT NULL,
  `category`              VARCHAR(100) NULL COMMENT 'Sub-category, e.g. subject name, class name',
  `value`                 DECIMAL(15,4) NOT NULL,
  `comparison_value_7d`   DECIMAL(15,4) NULL COMMENT 'Value 7 days ago for trend',
  `comparison_value_30d`  DECIMAL(15,4) NULL COMMENT 'Value 30 days ago for trend',
  `trend`                 ENUM('up','down','stable') NOT NULL DEFAULT 'stable',
  `metadata_json`         JSON NULL COMMENT 'Additional context for the KPI value',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pan_kpi_date_type_cat` (`snapshot_date`,`kpi_type`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.5 Table: `pan_cohort_analyses`

```sql
CREATE TABLE `pan_cohort_analyses` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`                      VARCHAR(200) NOT NULL,
  `base_session_id`           INT UNSIGNED NOT NULL COMMENT 'Academic session being analyzed',
  `comparison_sessions_json`  JSON NOT NULL COMMENT 'Array of academic session IDs for comparison',
  `class_id`                  INT UNSIGNED NULL COMMENT 'NULL = school-wide; specific class if set',
  `metric_type`               ENUM('exam_pass_rate','avg_score','attendance_rate','fee_collection') NOT NULL,
  `results_json`              JSON NOT NULL COMMENT 'Computed results per session for chart rendering',
  `generated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `generated_by`              BIGINT UNSIGNED NULL,
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                BIGINT UNSIGNED NULL,
  `created_at`                TIMESTAMP NULL,
  `updated_at`                TIMESTAMP NULL,
  `deleted_at`                TIMESTAMP NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.6 Table: `pan_fee_risk_profiles`

```sql
CREATE TABLE `pan_fee_risk_profiles` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guardian_id`           BIGINT UNSIGNED NOT NULL COMMENT 'FK → sys_users (parent/guardian)',
  `student_id`            INT UNSIGNED NOT NULL COMMENT 'FK → std_students (primary ward)',
  `risk_score`            DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Risk score 0-100',
  `risk_level`            ENUM('low','medium','high') NOT NULL DEFAULT 'low',
  `segment_label`         ENUM('on_time_payer','occasional_late','chronic_late','default_risk') NULL,
  `overdue_payments_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `avg_days_overdue`      DECIMAL(6,2) NOT NULL DEFAULT 0.00,
  `total_outstanding`     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `last_payment_date`     DATE NULL,
  `factors_json`          JSON NULL,
  `computed_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pan_fee_risk_guardian_student` (`guardian_id`,`student_id`),
  CONSTRAINT `fk_panFeeRisk_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.7 Table: `pan_skill_gap_summaries`

```sql
CREATE TABLE `pan_skill_gap_summaries` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`                INT UNSIGNED NOT NULL,
  `skill_id`                  INT UNSIGNED NOT NULL COMMENT 'FK → lxp_skills',
  `subject_id`                INT UNSIGNED NULL,
  `academic_session_id`       INT UNSIGNED NOT NULL,
  `current_skill_score`       DECIMAL(5,2) NOT NULL,
  `expected_skill_score`      DECIMAL(5,2) NOT NULL DEFAULT 60.00,
  `gap_magnitude`             DECIMAL(5,2) GENERATED ALWAYS AS (`expected_skill_score` - `current_skill_score`) VIRTUAL,
  `recommendation_triggered`  TINYINT(1) NOT NULL DEFAULT 0,
  `computed_at`               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                BIGINT UNSIGNED NULL,
  `created_at`                TIMESTAMP NULL,
  `updated_at`                TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pan_gap_student_skill_session` (`student_id`,`skill_id`,`academic_session_id`),
  CONSTRAINT `fk_panGap_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.8 Table: `pan_sentiment_records`

```sql
CREATE TABLE `pan_sentiment_records` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `source_type`           ENUM('complaint','forum_post','survey_response','feedback') NOT NULL,
  `source_ref_id`         INT UNSIGNED NOT NULL,
  `raw_text`              TEXT NOT NULL,
  `sentiment_label`       ENUM('positive','neutral','negative') NOT NULL,
  `confidence_score`      DECIMAL(4,3) NOT NULL DEFAULT 0.000 COMMENT 'Confidence 0-1',
  `theme_tags`            JSON NULL COMMENT 'Extracted themes e.g. ["teaching_quality","facilities"]',
  `processed_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pan_sentiment_source` (`source_type`,`source_ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.9 Table: `pan_benchmark_kpis`

```sql
CREATE TABLE `pan_benchmark_kpis` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `benchmark_date`        DATE NOT NULL,
  `kpi_type`              ENUM('exam_pass_rate','avg_attendance','fee_collection_ratio','teacher_retention','enrollment_growth') NOT NULL,
  `own_value`             DECIMAL(10,4) NOT NULL,
  `peer_median`           DECIMAL(10,4) NULL COMMENT 'Anonymized peer group median from prime_db',
  `peer_p25`              DECIMAL(10,4) NULL COMMENT 'Peer group 25th percentile',
  `peer_p75`              DECIMAL(10,4) NULL COMMENT 'Peer group 75th percentile',
  `gap_from_median`       DECIMAL(10,4) GENERATED ALWAYS AS (`own_value` - `peer_median`) VIRTUAL,
  `target_value`          DECIMAL(10,4) NULL COMMENT 'Admin-set target',
  `peer_group_filter_json` JSON NULL COMMENT 'Peer group criteria used',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pan_benchmark_date_kpi` (`benchmark_date`,`kpi_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.10 Table: `pan_transport_analyses`

```sql
CREATE TABLE `pan_transport_analyses` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `analysis_date`         DATE NOT NULL,
  `analysis_type`         ENUM('route_efficiency','stop_utilization','fuel_savings','simulation') NOT NULL,
  `route_id`              INT UNSIGNED NULL COMMENT 'FK → tpt_routes; NULL for school-wide analysis',
  `findings_json`         JSON NOT NULL COMMENT 'Detailed findings and recommendations',
  `estimated_savings`     DECIMAL(10,2) NULL COMMENT 'Estimated INR savings per month',
  `is_simulation`         TINYINT(1) NOT NULL DEFAULT 0,
  `simulation_params_json` JSON NULL,
  `generated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.11 Table: `pan_what_if_scenarios`

```sql
CREATE TABLE `pan_what_if_scenarios` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`                      VARCHAR(200) NOT NULL,
  `scenario_type`             ENUM('attendance_improvement','fee_reduction','remedial_sessions','teacher_redistribution') NOT NULL,
  `base_session_id`           INT UNSIGNED NOT NULL,
  `input_changes_json`        JSON NOT NULL COMMENT 'Parameter modifications applied in simulation',
  `current_state_json`        JSON NOT NULL COMMENT 'Snapshot of current state metrics',
  `projected_state_json`      JSON NOT NULL COMMENT 'Projected state after changes applied',
  `delta_json`                JSON NOT NULL COMMENT 'Computed differences',
  `generated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `generated_by`              BIGINT UNSIGNED NULL,
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                BIGINT UNSIGNED NULL,
  `created_at`                TIMESTAMP NULL,
  `updated_at`                TIMESTAMP NULL,
  `deleted_at`                TIMESTAMP NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.12 Table: `pan_custom_reports`

```sql
CREATE TABLE `pan_custom_reports` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_name`           VARCHAR(200) NOT NULL,
  `description`           TEXT NULL,
  `field_selections_json` JSON NOT NULL COMMENT 'Selected data fields from field catalog',
  `filter_config_json`    JSON NULL COMMENT 'Applied filters',
  `chart_type`            ENUM('table','bar','line','pie','scatter','heatmap') NOT NULL DEFAULT 'table',
  `group_by`              VARCHAR(100) NULL,
  `order_by`              VARCHAR(100) NULL,
  `is_shared`             TINYINT(1) NOT NULL DEFAULT 0,
  `shared_with_json`      JSON NULL COMMENT 'Array of user_ids report is shared with',
  `last_run_at`           TIMESTAMP NULL,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 6. PROPOSED ROUTES

```
Route Group: prefix='analytics', middleware=['auth','verified','tenant']

Dashboard
  GET  /analytics/dashboard                        → PanDashboardController@index
  GET  /analytics/dashboard/health-score           → PanDashboardController@healthScore (AJAX)

Early Warnings
  GET  /analytics/early-warnings                   → EarlyWarningController@index
  GET  /analytics/early-warnings/{warning}         → EarlyWarningController@show
  POST /analytics/early-warnings/{warning}/acknowledge → EarlyWarningController@acknowledge
  GET  /analytics/early-warnings/student/{student} → EarlyWarningController@studentHistory

Performance Predictions
  GET  /analytics/predictions/performance          → PerformancePredictionController@index
  GET  /analytics/predictions/performance/{student} → PerformancePredictionController@show
  POST /analytics/predictions/performance/run      → PerformancePredictionController@runModel
  GET  /analytics/predictions/dropout              → PerformancePredictionController@dropout

Attendance Forecasts
  GET  /analytics/predictions/attendance           → AttendanceForecastController@index
  GET  /analytics/predictions/attendance/trends    → AttendanceForecastController@trends

Fee Default Risk
  GET  /analytics/predictions/fee-default          → FeeDefaultController@index
  GET  /analytics/predictions/fee-default/segments → FeeDefaultController@segments

Skill Gaps
  GET  /analytics/skill-gaps                       → SkillGapController@index
  GET  /analytics/skill-gaps/{student}             → SkillGapController@studentGaps
  GET  /analytics/skill-gaps/class-heatmap         → SkillGapController@classHeatmap

Transport
  GET  /analytics/transport                        → TransportAnalyticsController@index
  POST /analytics/transport/simulate               → TransportAnalyticsController@simulate

Sentiment
  GET  /analytics/sentiment                        → SentimentController@index
  GET  /analytics/sentiment/trends                 → SentimentController@trends

Benchmarking
  GET  /analytics/benchmarking                     → BenchmarkingController@index
  POST /analytics/benchmarking/run                 → BenchmarkingController@run

What-If
  GET  /analytics/what-if                          → WhatIfController@index (via PanDashboardController)
  POST /analytics/what-if                          → WhatIfController@run
  GET  /analytics/what-if/{scenario}               → WhatIfController@show

Custom Reports
  GET  /analytics/custom-reports                   → CustomReportController@index
  GET  /analytics/custom-reports/create            → CustomReportController@create
  POST /analytics/custom-reports                   → CustomReportController@store
  GET  /analytics/custom-reports/{report}/run      → CustomReportController@run
  GET  /analytics/custom-reports/{report}/export   → CustomReportController@export

Model Management (Admin Only)
  GET  /analytics/models                           → PanDashboardController@models
  POST /analytics/models/{model}/run               → PanDashboardController@runModel
```

---

## 7. PROPOSED BLADE VIEWS

| View Path | Purpose |
|---|---|
| `analytics/dashboard/index.blade.php` | KPI overview cards, trend charts, health score |
| `analytics/early-warnings/index.blade.php` | Active warning queue with severity filters |
| `analytics/early-warnings/show.blade.php` | Warning detail + acknowledge form |
| `analytics/early-warnings/history.blade.php` | Full warning history per student |
| `analytics/predictions/performance/index.blade.php` | Class-level performance prediction table |
| `analytics/predictions/performance/show.blade.php` | Per-student factor breakdown |
| `analytics/predictions/dropout.blade.php` | Dropout risk ranked list |
| `analytics/predictions/attendance/index.blade.php` | Absence forecast table + trend chart |
| `analytics/predictions/fee-default/index.blade.php` | Fee risk table + segment chart |
| `analytics/skill-gaps/index.blade.php` | School-wide gap summary |
| `analytics/skill-gaps/student.blade.php` | Per-student gap list with recommended actions |
| `analytics/skill-gaps/heatmap.blade.php` | Class skill heatmap grid |
| `analytics/transport/index.blade.php` | Route efficiency analysis |
| `analytics/transport/simulate.blade.php` | Simulation builder + results |
| `analytics/sentiment/index.blade.php` | Sentiment overview + theme breakdown |
| `analytics/sentiment/trends.blade.php` | Time-series sentiment trend chart |
| `analytics/benchmarking/index.blade.php` | KPI benchmark comparison + radar chart |
| `analytics/what-if/index.blade.php` | Scenario builder form |
| `analytics/what-if/show.blade.php` | Current vs projected state comparison |
| `analytics/custom-reports/index.blade.php` | Saved reports list |
| `analytics/custom-reports/create.blade.php` | Report builder drag-and-drop UI |
| `analytics/custom-reports/show.blade.php` | Report run results |
| `analytics/cohort/index.blade.php` | Cohort analysis list |
| `analytics/cohort/show.blade.php` | Multi-year comparison chart |

---

## 8. PROPOSED SERVICES

### 8.1 `PerformancePredictionService`
- `runForSession(int $sessionId, ?int $classId = null): void` — batch run for all students
- `predictForStudent(int $studentId, int $subjectId, int $sessionId): array` — returns `{predicted_score, confidence, risk_level, factors}`
- `validateAccuracy(int $sessionId): array` — post-actuals comparison; updates model accuracy_score

### 8.2 `AttendanceForecastService`
- `forecastForStudent(int $studentId): array` — per-day probability for next 7 days
- `detectAnomalies(int $classId, int $sessionId): array` — class-level anomaly detection
- `runWeeklyForecasts(int $sessionId): void` — batch run triggered by Artisan command

### 8.3 `FeeDefaultPredictionService`
- `scoreGuardian(int $guardianId, int $studentId): PanFeeRiskProfile`
- `runSegmentation(int $sessionId): void` — classifies all guardians into segments
- `triggerReminders(array $highRiskGuardianIds): void` — creates notification triggers

### 8.4 `SkillGapAnalysisService`
- `analyzeStudent(int $studentId, int $sessionId): Collection` — returns gaps ordered by magnitude
- `analyzeClass(int $classId, int $sectionId, int $sessionId): array` — returns heatmap matrix data
- `triggerRecommendations(PanSkillGapSummary $gap): void` — creates rec_student_recommendations

### 8.5 `SentimentAnalysisService`
- `analyze(string $text, string $sourceType): array` — returns `{sentiment_label, confidence, themes}`
- `processComplaintsBatch(int $sessionId): void` — processes all unanalyzed complaints
- `detectSpikes(string $theme, int $lookbackDays = 7): bool` — spike detection for alerts

### 8.6 `KpiSnapshotService`
- `computeDailySnapshots(): void` — computes all KPI types and upserts `pan_kpi_snapshots`
- `computeHealthScore(): float` — composite school health score from normalized KPIs
- `getKpiTrend(string $kpiType, int $days = 30): array` — time series data for chart

---

## 9. PROPOSED ARTISAN COMMANDS

| Command | Schedule | Purpose |
|---|---|---|
| `analytics:run-performance-predictions` | Weekly (Sunday 2 AM) | Batch performance predictions for active session |
| `analytics:run-attendance-forecasts` | Daily (5 AM) | Weekly absence forecasts for all active students |
| `analytics:run-fee-default-predictions` | Weekly (Monday 6 AM) | Fee default scoring before weekly reminder cycle |
| `analytics:run-sentiment-analysis` | Daily (3 AM) | Process new complaints/posts through sentiment engine |
| `analytics:compute-kpi-snapshots` | Daily (1 AM) | KPI snapshot computation |
| `analytics:escalate-warnings` | Hourly | Escalate unacknowledged critical warnings after 48h |

---

## 10. EXTERNAL DEPENDENCIES

| Dependency | Version | Usage |
|---|---|---|
| LXP Module (`lxp_*`) | Planned | Primary source of skill scores and engagement signals for predictions |
| Recommendation Module (`rec_*`) | Existing | Target of gap-triggered recommendation creation |
| Attendance Module (`std_attendance`) | Existing | Primary input for attendance forecasting and dropout risk |
| Exam Module (`exm_*`) | Existing | Exam scores as primary performance prediction input |
| Finance Module (`fin_*`) | Existing | Fee payment data for default prediction |
| Transport Module (`tpt_*`) | Existing | Route and ridership data for transport analytics |
| Complaint Module (`cmp_*`) | Existing | Complaint text for sentiment analysis |
| Laravel Scheduler | built-in | Cron-based scheduled prediction runs |
| Laravel Queue | built-in | Async job dispatch for heavy prediction batch runs |
| stancl/tenancy | v3.9 | Tenant isolation for all queries and snapshots |

---

## 11. BUSINESS RULES

| Rule ID | Rule | Source |
|---|---|---|
| BR-PAN-001 | Prediction models only run when at least 4 weeks of data exists in the current academic session | Statistical validity |
| BR-PAN-002 | Early warnings are insert-only; never deleted. Acknowledged warnings move to 'historical' view. | Audit trail |
| BR-PAN-003 | KPI snapshots are immutable once created (no updates, only new records). | Time-series integrity |
| BR-PAN-004 | Sentiment analysis does NOT store the raw text permanently after analysis — raw_text is stored 90 days then nullified | Privacy |
| BR-PAN-005 | Benchmarking data from peer group must use anonymized aggregates from `prime_db` — individual tenant data is never accessible from another tenant | Multi-tenant privacy |
| BR-PAN-006 | Custom report builder must restrict queries to a pre-defined field catalog — no raw SQL input accepted | Security (SQL injection prevention) |
| BR-PAN-007 | Prediction `actual_value` can only be populated by the system after official exam results are published (status='published' in exm_*) — not manually editable | Data integrity |
| BR-PAN-008 | Fee default predictions must NOT be visible to teachers — only to accounts staff and admin | Privacy / RBAC |
| BR-PAN-009 | What-if simulations do not modify any live data — they operate on cloned snapshots only | Safety |
| BR-PAN-010 | An early warning of type 'critical' must generate a system notification to admin within 1 hour of creation | SLA |

---

## 12. NON-FUNCTIONAL REQUIREMENTS

| Requirement | Target | Notes |
|---|---|---|
| Prediction Job Duration | < 5 minutes per session (for up to 1000 students) | Queue-based async job |
| KPI Dashboard Load | < 3 seconds | Reads from pre-computed `pan_kpi_snapshots` |
| Skill Heatmap Query | < 2 seconds for 50 students × 20 skills | Optimized pivot query with indexes |
| Sentiment Batch Processing | < 100 records/minute | Rule-based NLP; no external API calls |
| Custom Report Execution | < 10 seconds | Field catalog restricts query complexity |
| Early Warning Escalation | Within 1 hour for critical warnings | Artisan command runs hourly |
| Data Retention | Predictions retained 2 academic sessions; KPI snapshots retained indefinitely | Storage policy |
| Soft Delete | All major tables support `deleted_at` | Standard pattern |
| Audit | All model configuration changes logged via `sys_activity_logs` | Standard pattern |

---

## 13. INTEGRATION POINTS

| Module | Integration Type | Direction | Description |
|---|---|---|---|
| LXP (`lxp_*`) | Data Read | PAN reads LXP | Skill scores from `lxp_student_skills`; engagement from `lxp_engagement_logs` for dropout and performance models |
| Recommendation (`rec_*`) | Data Write | PAN writes REC | Gap-triggered recommendation creation via `rec_student_recommendations` insert |
| Attendance (`std_attendance`) | Data Read | PAN reads STD | Attendance records for forecasting and dropout risk |
| Exam (`exm_*`) | Data Read | PAN reads EXM | Exam scores for performance prediction; actual results for model accuracy validation |
| Finance (`fin_*`) | Data Read | PAN reads FIN | Fee payment records for default prediction |
| Transport (`tpt_*`) | Data Read | PAN reads TPT | Route and ridership data for transport optimization |
| Complaint (`cmp_*`) | Data Read | PAN reads CMP | Complaint text for sentiment analysis batch processing |
| Forum Posts (`lxp_forum_threads`) | Data Read | PAN reads LXP | Forum post text for sentiment analysis |
| Notification System | Outbound trigger | PAN triggers | Early warnings → teacher/admin notifications |
| SmartTimetable (`tt_*`) | Data Read | PAN reads TT | Teaching period counts per teacher for workload analytics |
| prime_db (cross-tenant) | Data Read (anonymized) | PAN reads PRIME | Anonymized peer group KPI aggregates for benchmarking (read from prime_db aggregate tables — no individual tenant data) |

---

## 14. PROPOSED TEST CASES

| # | Test Case | Type | FR Reference | Priority |
|---|---|---|---|---|
| 1 | Student with 40% attendance + 30% mid-term → predicted score < 35%, risk_level=critical | Unit | FR-PAN-001 | High |
| 2 | Performance prediction batch runs for 100 students without timeout | Feature | FR-PAN-001 | High |
| 3 | Critical-risk student triggers early warning creation automatically | Feature | FR-PAN-006 | High |
| 4 | Unacknowledged critical warning escalates after 48h | Feature | FR-PAN-006 | High |
| 5 | Warning acknowledged; intervention notes saved; removed from active queue | Browser | FR-PAN-006 | High |
| 6 | KPI snapshot computed daily; enrollment KPI matches std_students active count | Feature | FR-PAN-005 | High |
| 7 | Cohort analysis correctly compares two academic year exam pass rates | Feature | FR-PAN-005 | High |
| 8 | Skill gap analysis: student with skill_score=30, expected=60 → gap_magnitude=30 | Unit | FR-PAN-003 | High |
| 9 | Gap magnitude > 20 triggers recommendation in rec_student_recommendations | Feature | FR-PAN-009 | High |
| 10 | Class skill heatmap renders correctly for 40-student class × 15 skills | Browser | FR-PAN-003 | Medium |
| 11 | Fee default scoring correctly classifies chronic late payer in high risk segment | Unit | FR-PAN-012 | Medium |
| 12 | Sentiment analysis labels complaint with "teaching_quality" theme and "negative" label | Unit | FR-PAN-014 | Medium |
| 13 | Sentiment spike (3× weekly avg) triggers pan_early_warnings creation | Feature | FR-PAN-014 | Medium |
| 14 | Custom report builder rejects queries using fields not in pre-defined catalog | Feature | FR-PAN-017 | High |
| 15 | What-if simulation does not modify live data; original prediction data unchanged after run | Feature | FR-PAN-016 | High |
| 16 | Dropout risk score correctly weights all 5 factors | Unit | FR-PAN-002 | Medium |
| 17 | Benchmarking does not expose individual tenant data; only anonymized aggregates | Feature | BR-PAN-005 | High |
| 18 | Model accuracy score updates correctly after actual exam results published | Feature | FR-PAN-010 | Medium |
| 19 | Transport route simulation returns comparison without modifying tpt_* tables | Feature | FR-PAN-013 | Low |
| 20 | Teacher effectiveness table shows correct student outcome correlation per teacher | Browser | FR-PAN-004 | Medium |
