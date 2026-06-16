# PAN — Predictive Analytics
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY

---

## 1. Executive Summary

The PredictiveAnalytics (PAN) module is Prime-AI's intelligence layer. It aggregates data from all operational modules — attendance, exams, fees, LMS/LXP engagement, transport, complaints — and applies ML-driven models and statistical analysis to predict future outcomes, identify at-risk students, expose institutional inefficiencies, and enable proactive interventions. This module closes the three principal blind spots faced by Indian school management: which students will fail before they fail, which students will stop attending before they stop attending, and which fee payers will default before they default.

PAN serves three primary stakeholder personas: the **Principal/Admin** (school KPI health, early warning system, benchmarking), the **Teacher** (class-level performance predictions, skill gap analysis, drop-off risks), and the **System** (automated early warning triggers that feed into the Notification and Recommendation modules).

Since this is a greenfield module (RBS_ONLY mode), all functional requirements are marked as 📐 Proposed and all database tables are new (pan_* prefix).

### 1.1 Module Statistics

| Metric | Count |
|---|---|
| Functional Requirements | 17 (FR-PAN-001 to FR-PAN-017) |
| Proposed DB Tables (pan_*) | 12 |
| Proposed Named Routes | ~55 |
| Proposed Blade Views | ~24 |
| Proposed Controllers | 10 |
| Proposed Models | 12 |
| Proposed Services | 6 |
| Proposed Jobs | 4 |
| Proposed Artisan Commands | 6 |

### 1.2 Implementation Status

| Layer | Status |
|---|---|
| DB Schema / Migrations | ❌ Not Started |
| Models | ❌ Not Started |
| Controllers | ❌ Not Started |
| Services | ❌ Not Started |
| Jobs / Commands | ❌ Not Started |
| Blade Views | ❌ Not Started |
| Routes | ❌ Not Started |
| Tests | ❌ Not Started |

**Overall Implementation: 0% — Greenfield**

---

## 2. Module Overview

### 2.1 Platform Context

| Attribute | Value |
|---|---|
| Module Code | PAN |
| Module Name | Predictive Analytics |
| Laravel Module Path | `Modules/PredictiveAnalytics` |
| Table Prefix | `pan_` |
| DB Scope | tenant_db (per-school isolation) |
| Module Type | Tenant |
| RBS Reference | Module V — AI Analytics & Predictions |
| Priority | P7 |
| Complexity | X-Large |
| Dependencies | ATT (Attendance), EXA (Exam), FIN (Fee), LXP, REC (Recommendation), TPT (Transport), CMP (Complaint) |

### 2.2 Sub-Module Map

| Code | Sub-Module | RBS Ref | Status |
|---|---|---|---|
| PAN-01 | Student Performance Prediction | V1 | 📐 Proposed |
| PAN-02 | Dropout Risk Assessment | V1+V2 | 📐 Proposed |
| PAN-03 | Learning Gap Analysis | V4 | 📐 Proposed |
| PAN-04 | Teacher Effectiveness Analytics | V6 | 📐 Proposed |
| PAN-05 | School KPI Dashboard | V6 | 📐 Proposed |
| PAN-06 | Early Warning System | V1+V2 | 📐 Proposed |
| PAN-07 | Attendance Forecasting | V2 | 📐 Proposed |
| PAN-08 | Fee Default Prediction | V3 | 📐 Proposed |
| PAN-09 | Transport Route Analytics | V4 | 📐 Proposed |
| PAN-10 | Sentiment & Feedback Analysis | V5 | 📐 Proposed |
| PAN-11 | Institutional Benchmarking | V6 | 📐 Proposed |
| PAN-12 | What-If Scenario Modeling | V6 | 📐 Proposed |
| PAN-13 | Custom Report Builder | V6 | 📐 Proposed |
| PAN-14 | ML Model Management | V1 | 📐 Proposed |
| PAN-15 | Cohort Comparison Analysis | V6 | 📐 Proposed |
| PAN-16 | Subject Difficulty Analysis | V4 | 📐 Proposed |
| PAN-17 | PAN-to-Recommendation Pipeline | V1+V4 | 📐 Proposed |

### 2.3 Menu Navigation Path

```
School Admin / Teacher Panel
└── Analytics [/analytics]
    ├── Dashboard                [/analytics/dashboard]
    ├── Early Warnings           [/analytics/early-warnings]
    ├── Predictions
    │   ├── Performance          [/analytics/predictions/performance]
    │   ├── Dropout Risk         [/analytics/predictions/dropout]
    │   ├── Attendance Forecast  [/analytics/predictions/attendance]
    │   └── Fee Default Risk     [/analytics/predictions/fee-default]
    ├── Learning Gaps            [/analytics/skill-gaps]
    ├── Teacher Analytics        [/analytics/teacher-analytics]
    ├── Transport Analytics      [/analytics/transport]
    ├── Sentiment Analysis       [/analytics/sentiment]
    ├── Benchmarking             [/analytics/benchmarking]
    ├── Cohort Analysis          [/analytics/cohort]
    ├── What-If Scenarios        [/analytics/what-if]
    ├── Custom Reports           [/analytics/custom-reports]
    └── Model Management         [/analytics/models]  (admin only)
```

### 2.4 Module Architecture

```
Modules/PredictiveAnalytics/
├── app/
│   ├── Console/Commands/
│   │   ├── RunPerformancePredictions.php   # Weekly
│   │   ├── RunAttendanceForecasts.php      # Daily
│   │   ├── RunFeeDefaultPredictions.php    # Weekly
│   │   ├── RunSentimentAnalysis.php        # Daily
│   │   ├── ComputeKpiSnapshots.php         # Daily
│   │   └── EscalateWarnings.php            # Hourly
│   ├── Http/Controllers/
│   │   ├── PanDashboardController.php
│   │   ├── EarlyWarningController.php
│   │   ├── PerformancePredictionController.php
│   │   ├── AttendanceForecastController.php
│   │   ├── FeeDefaultController.php
│   │   ├── SkillGapController.php
│   │   ├── TeacherAnalyticsController.php
│   │   ├── TransportAnalyticsController.php
│   │   ├── SentimentController.php
│   │   ├── BenchmarkingController.php
│   │   ├── CohortController.php
│   │   ├── WhatIfController.php
│   │   └── CustomReportController.php
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
│   └── Services/
│       ├── PerformancePredictionService.php
│       ├── AttendanceForecastService.php
│       ├── FeeDefaultPredictionService.php
│       ├── SkillGapAnalysisService.php
│       ├── SentimentAnalysisService.php
│       └── KpiSnapshotService.php
├── database/migrations/  (12 migrations)
├── resources/views/analytics/
└── routes/
    ├── api.php
    └── web.php
```

---

## 3. Stakeholders & Roles

| Actor | Role in PAN | Key Permissions |
|---|---|---|
| School Admin | Full access: configure models, trigger runs, view all outputs, manage benchmarks | All PAN permissions |
| Principal | View all KPI dashboards, early warnings, cohort analysis, sentiment, benchmarking | view-all, analytics.view |
| Teacher | Predictions for their classes/students; skill gaps; attendance forecast for their sections | class-scoped predictions, skill-gap.view |
| Accounts Staff | Fee default risk profiles and parent segments only | fee-risk.view |
| Transport Coordinator | Transport analytics and route optimization suggestions | transport.analytics.view |
| System Scheduler | Runs prediction jobs via cron; generates KPI snapshots; triggers early warnings | system actor (no UI) |
| Parent | Indirect — receives notifications generated by Early Warning System | notification recipient |
| Student | Indirect — benefits from interventions triggered by PAN outputs | indirect beneficiary |

---

## 4. Functional Requirements

---

### FR-PAN-001: Student Performance Prediction
**Status:** 📐 Proposed | **Priority:** Critical | **Tables:** `pan_prediction_models`, `pan_student_predictions`

**Description:** For each student in each subject, predict the end-of-term exam score using a weighted multi-factor regression model. Input features: attendance rate (0.25), mid-term score percentile (0.40), quiz average score (0.20), homework submission rate (0.10), LXP engagement score (0.05). Output: predicted score (0–100), confidence interval (±N points), and risk level.

**Acceptance Criteria:**
- AC1: Model analyzes attendance, marks, and engagement as input factors
- AC2: Risk score generated per student per subject (low/medium/high/critical)
- AC3: Subjects with predicted score < 35% are flagged as critical risk
- AC4: High-risk students automatically trigger Early Warning System (FR-PAN-006)
- AC5: Per-student factor breakdown shows which input dragged the prediction down
- AC6: Model requires at least 4 weeks of data in current session before running
- AC7: Weak concepts listed per student using LXP skill score data

---

### FR-PAN-002: Dropout Risk Assessment
**Status:** 📐 Proposed | **Priority:** Critical | **Tables:** `pan_student_predictions`, `pan_early_warnings`

**Description:** Composite dropout risk score (0–100) per student combining five weighted signals: attendance decline trend (0.35), performance risk level (0.25), fee payment delay pattern (0.20), behavioral incidents count (0.10), LXP engagement decline (0.10). Students with score > 70 flagged as HIGH dropout risk.

**Acceptance Criteria:**
- AC1: All five factors correctly weighted in composite score formula
- AC2: Students with score > 70 trigger a critical early warning
- AC3: Dedicated dropout risk dashboard shows all students with score > 50
- AC4: Risk factor breakdown visible per student
- AC5: Days-since-last-engagement and intervention history shown on dashboard

---

### FR-PAN-003: Learning Gap Analysis
**Status:** 📐 Proposed | **Priority:** Critical | **Tables:** `pan_skill_gap_summaries`

**Description:** Compare each student's LXP skill scores against expected grade-level benchmarks (default 60%). Generate gap analysis per student per subject with gap magnitude computed as a generated column. Class-level skill heatmap (rows = skills, columns = students) for teacher view. Gaps with magnitude > 20 automatically trigger recommendation creation.

**Acceptance Criteria:**
- AC1: Skills compared against expected grade-level scores (configurable, default 60%)
- AC2: Competencies below threshold listed with gap magnitude descending
- AC3: Recommendation triggered for top gaps via RecommendationService
- AC4: Class heatmap renders color-coded grid (red < 40, yellow 40–70, green > 70)
- AC5: Heatmap filterable by academic year for trend comparison

---

### FR-PAN-004: Teacher Effectiveness Analytics
**Status:** 📐 Proposed | **Priority:** High | **Tables:** `pan_kpi_snapshots`

**Description:** Analyze student outcomes correlated to teacher assignment. Metrics: average class exam score per subject, YoY improvement rate, homework completion rate, quiz average, student attendance in teacher's periods. Workload distribution: flag teachers with > 30 periods/week as overloaded.

**Acceptance Criteria:**
- AC1: Teacher performance table sortable by each metric
- AC2: YoY delta computed by comparing to previous academic session
- AC3: Teachers with > 30 periods/week flagged as overloaded
- AC4: Redistribution suggestion generated for overloaded teachers
- AC5: Teacher analytics access restricted to admin/principal (not visible to teachers themselves)

---

### FR-PAN-005: School KPI Dashboard
**Status:** 📐 Proposed | **Priority:** Critical | **Tables:** `pan_kpi_snapshots`, `pan_cohort_analyses`

**Description:** Daily automated KPI snapshot computation and storage. KPIs: total active enrollment, daily attendance rate (%), exam pass rate, fee collection ratio, new admissions this month, open complaints count, teacher retention rate. Dashboard shows KPI cards with trend arrows, 30-day trend line charts, and a composite School Health Score.

**Acceptance Criteria:**
- AC1: KPI snapshots computed daily via scheduled job without manual trigger
- AC2: Dashboard shows trend direction (up/down/stable) with percentage change from last month
- AC3: School Health Score is a weighted composite of normalized KPI values
- AC4: Health Score recalculated on each daily snapshot run
- AC5: Dashboard loads from pre-computed snapshots in < 3 seconds

---

### FR-PAN-006: Early Warning System
**Status:** 📐 Proposed | **Priority:** Critical | **Tables:** `pan_early_warnings`

**Description:** Automatic warning creation for students meeting risk thresholds. Warning types: ATTENDANCE (< 75% in last 2 weeks), PERFORMANCE (predicted < 35%), FEE (overdue > 30 days), BEHAVIOUR (3+ incidents in a week), ENGAGEMENT (no LXP activity in 14 days), SENTIMENT_SPIKE. Teacher reviews and acknowledges warnings with intervention notes. Unacknowledged critical warnings escalate to admin after 48 hours.

**Acceptance Criteria:**
- AC1: Attendance warning created when student drops below 75% in last 2 weeks
- AC2: Performance warning created for predicted score < 35%
- AC3: Class teacher receives notification within 1 hour of warning creation
- AC4: Critical warnings generate system notification to admin within 1 hour
- AC5: Unacknowledged critical warnings auto-escalate to admin after 48h
- AC6: Intervention notes (type + free text) recorded per acknowledged warning
- AC7: Warning history viewable per student regardless of acknowledgment status
- AC8: Warnings are insert-only (soft delete via is_active); never hard-deleted

---

### FR-PAN-007: Attendance Forecasting
**Status:** 📐 Proposed | **Priority:** High | **Tables:** `pan_student_predictions`

**Description:** Per-student absence probability forecast for each day in the coming week using 90-day historical patterns (day-of-week tendency, seasonal adjustment, absence cluster patterns). Students with > 60% absence probability on any upcoming day flagged to class teacher. Class-level anomaly detection: flag days where attendance drops > 2 standard deviations below 7-day rolling average.

**Acceptance Criteria:**
- AC1: Weekly forecast generated per student per day (7 probability values)
- AC2: Students with > 60% absence probability on any day flagged to teacher
- AC3: Class-level anomaly spikes detected and highlighted on attendance trend chart
- AC4: Historical patterns use minimum 90 days of attendance data
- AC5: Seasonal adjustment factor applied (festival/harvest season patterns)

---

### FR-PAN-008: Fee Default Prediction
**Status:** 📐 Proposed | **Priority:** High | **Tables:** `pan_fee_risk_profiles`

**Description:** Score each guardian for fee default risk based on: overdue payment count (0.40), average days overdue (0.30), total outstanding amount (0.20), sibling count in school (0.10). Classify parents into segments: On-Time Payers, Occasional Late Payers, Chronic Late Payers, Default Risk. High-risk accounts trigger automated payment reminder via Notification module.

**Acceptance Criteria:**
- AC1: Risk score computed per guardian per student (0–100)
- AC2: Segment label assigned using behavioral clustering
- AC3: High-risk guardians trigger automated fee reminder notification
- AC4: Segment distribution chart available for accounts staff
- AC5: Fee default data restricted to accounts staff and admin (not visible to teachers)

---

### FR-PAN-009: Transport Route Analytics
**Status:** 📐 Proposed | **Priority:** Medium | **Tables:** `pan_transport_analyses`

**Description:** Analyze transport routes using ridership and stop utilization data from the Transport module. Identify: under-utilized stops (< 3 students), routes with excessive travel time, route merge opportunities. Simulation: admin can preview the impact of merging routes or removing stops (affected students, travel time change, estimated fuel savings) without modifying live transport records.

**Acceptance Criteria:**
- AC1: Route efficiency report shows occupancy rate and stop utilization per route
- AC2: Under-utilized stops (< 3 students) flagged with consolidation suggestion
- AC3: Simulation produces comparison table (Current vs Proposed) without modifying tpt_* tables
- AC4: Estimated monthly fuel savings computed per optimization suggestion

---

### FR-PAN-010: Sentiment & Feedback Analysis
**Status:** 📐 Proposed | **Priority:** Medium | **Tables:** `pan_sentiment_records`

**Description:** Rule-based NLP processing of text from: complaint descriptions, survey open-ended responses, LXP forum posts. Classify as Positive/Neutral/Negative and extract key themes (teaching_quality, facilities, transport, food, safety) using Hindi + English keyword dictionaries. Alert when negative sentiment for a theme spikes > 3× the weekly average. Raw text nullified after 90 days for privacy.

**Acceptance Criteria:**
- AC1: Sentiment label and confidence score generated per source text record
- AC2: Theme tags extracted and stored as JSON array
- AC3: Sentiment spike (> 3× weekly avg) creates `pan_early_warnings` with type=sentiment_spike
- AC4: Trend chart shows weekly sentiment distribution per theme
- AC5: Raw text column nullified after 90 days (scheduled cleanup)

---

### FR-PAN-011: Institutional Benchmarking
**Status:** 📐 Proposed | **Priority:** Medium | **Tables:** `pan_benchmark_kpis`

**Description:** Compare school KPIs against anonymized peer group aggregates from prime_db (peer group filtered by school type, enrollment range, board affiliation). Metrics: exam pass rate, avg attendance, fee collection ratio, teacher retention, enrollment growth. Display radar chart and gap analysis report. Individual tenant data is never exposed.

**Acceptance Criteria:**
- AC1: Peer group filter configurable (school type, enrollment range, board affiliation)
- AC2: Comparison shows own value vs peer P25, median, P75
- AC3: Gap analysis narrative generated per KPI
- AC4: Radar chart renders own vs peer median comparison
- AC5: Benchmarking query reads only anonymized aggregates from prime_db; no individual tenant records accessible

---

### FR-PAN-012: What-If Scenario Modeling
**Status:** 📐 Proposed | **Priority:** Medium | **Tables:** `pan_what_if_scenarios`

**Description:** Admin defines hypothetical scenarios (attendance improvement, fee reduction, remedial sessions, teacher redistribution) and the system predicts impact by cloning prediction data and applying parameter changes. Output: side-by-side Current State vs Projected State with delta values. No live data is modified.

**Acceptance Criteria:**
- AC1: At least 4 scenario types supported: attendance_improvement, fee_reduction, remedial_sessions, teacher_redistribution
- AC2: Simulation operates on cloned snapshots; live prediction records unchanged
- AC3: Side-by-side comparison table with delta and percentage change
- AC4: Saved scenarios are reusable and viewable in history

---

### FR-PAN-013: Custom Report Builder
**Status:** 📐 Proposed | **Priority:** Medium | **Tables:** `pan_custom_reports`

**Description:** Admin/Principal builds custom analytical reports by selecting data fields from a pre-defined field catalog, applying filters, choosing chart type, and saving. Reports shareable with other admin/teacher accounts. No raw SQL input accepted — queries restricted to the field catalog.

**Acceptance Criteria:**
- AC1: Field catalog covers data from at least: students, attendance, exams, fees modules
- AC2: Filter configuration supports date range, class, section, subject, risk level
- AC3: Chart types supported: table, bar, line, pie, scatter, heatmap
- AC4: Reports exportable to PDF and Excel
- AC5: Custom report builder rejects any field or filter not in pre-defined catalog (SQL injection prevention)
- AC6: Saved reports shareable via configurable user list

---

### FR-PAN-014: ML Model Management
**Status:** 📐 Proposed | **Priority:** High | **Tables:** `pan_prediction_models`

**Description:** Admin configures each prediction model's parameters: input feature weights, risk level thresholds, active/inactive status. After actual exam results are published, system computes Mean Absolute Error (MAE) between predicted and actual values and updates `accuracy_score`. Admin alerted if accuracy degrades below 70%.

**Acceptance Criteria:**
- AC1: Model config (weights, thresholds) editable via admin UI
- AC2: Only active models are executed in scheduled jobs
- AC3: MAE computed automatically after official exam results published
- AC4: Admin notified if model accuracy drops below 70%
- AC5: Version field maintained; UNIQUE constraint on (model_type, version)

---

### FR-PAN-015: Cohort Comparison Analysis
**Status:** 📐 Proposed | **Priority:** High | **Tables:** `pan_cohort_analyses`

**Description:** Compare current academic cohort performance against previous years for the same class level. Metrics: exam pass %, average score, attendance rate, fee collection rate. Stored as named reusable analyses. Multi-line chart shows all cohorts on the same axis.

**Acceptance Criteria:**
- AC1: Up to 5 academic years comparable in a single cohort analysis
- AC2: Multi-line chart renders each cohort as a separate series
- AC3: Tabular comparison shows absolute values and percentage change per cohort
- AC4: Saved cohort analyses persist and are reusable

---

### FR-PAN-016: Subject Difficulty Analysis
**Status:** 📐 Proposed | **Priority:** High | **Tables:** `pan_kpi_snapshots`

**Description:** Identify syllabus topics and subject areas causing the most student failures. Topics where > 40% of students score < 40% on related quiz questions or exam sub-sections are flagged as High Difficulty. Report downloadable as CSV.

**Acceptance Criteria:**
- AC1: Topics with > 40% student failure rate flagged as High Difficulty
- AC2: Report sortable by failure rate descending
- AC3: Downloadable CSV export of full topic-difficulty table
- AC4: Drilldown available from topic to list of underperforming students

---

### FR-PAN-017: PAN-to-Recommendation Pipeline
**Status:** 📐 Proposed | **Priority:** Critical | **Tables:** `pan_skill_gap_summaries`, `pan_student_predictions`

**Description:** When PAN identifies a learning gap (gap_magnitude > 20) or performance risk (predicted < 40%), it automatically creates a recommendation trigger in the Recommendation module. This closes the detect-suggest-execute loop: PAN detects → REC suggests intervention → LXP executes via learning path update.

**Acceptance Criteria:**
- AC1: Gap magnitude > 20 triggers `RecommendationService::createFromPan()` call
- AC2: Performance risk (predicted < 40%) also triggers recommendation creation
- AC3: `rec_student_recommendations` record created with trigger_source='pan_gap_analysis' or 'pan_performance_risk'
- AC4: LXP path update picks up recommendation at next path generation cycle
- AC5: `recommendation_triggered` flag set to 1 on `pan_skill_gap_summaries` row to prevent duplicate triggers

---

## 5. Data Model

### 5.1 New Tables (pan_* prefix)

| Table | Description | Key Columns |
|---|---|---|
| `pan_prediction_models` 📐 | ML model configurations with weights and thresholds | model_type ENUM, version, feature_weights_json, threshold_config_json, accuracy_score, is_active |
| `pan_student_predictions` 📐 | Per-student per-subject prediction outputs | student_id, model_id, academic_session_id, subject_id, prediction_type ENUM, predicted_value, confidence_interval, risk_level ENUM, factors_json, actual_value |
| `pan_early_warnings` 📐 | Student risk alerts with acknowledgment workflow | student_id, warning_type ENUM, severity ENUM, message, is_acknowledged, acknowledged_by, intervention_notes, next_action ENUM, escalated_at |
| `pan_kpi_snapshots` 📐 | Immutable daily school-wide KPI time-series | snapshot_date, kpi_type ENUM, category, value, comparison_value_7d, comparison_value_30d, trend ENUM |
| `pan_cohort_analyses` 📐 | Named multi-year cohort comparison analyses | name, base_session_id, comparison_sessions_json, class_id, metric_type ENUM, results_json |
| `pan_fee_risk_profiles` 📐 | Guardian fee payment risk scores and segments | guardian_id, student_id, risk_score, risk_level ENUM, segment_label ENUM, overdue_payments_count, avg_days_overdue, total_outstanding |
| `pan_skill_gap_summaries` 📐 | Student competency gap records vs grade-level expectations | student_id, skill_id, subject_id, academic_session_id, current_skill_score, expected_skill_score, gap_magnitude (GENERATED), recommendation_triggered |
| `pan_sentiment_records` 📐 | NLP-classified text records from complaints/feedback/forum | source_type ENUM, source_ref_id, raw_text (nullified after 90d), sentiment_label ENUM, confidence_score, theme_tags JSON |
| `pan_benchmark_kpis` 📐 | School KPI vs anonymized peer group benchmarks | benchmark_date, kpi_type ENUM, own_value, peer_median, peer_p25, peer_p75, gap_from_median (GENERATED), target_value |
| `pan_transport_analyses` 📐 | Route efficiency analysis and simulation results | analysis_date, analysis_type ENUM, route_id, findings_json, estimated_savings, is_simulation, simulation_params_json |
| `pan_what_if_scenarios` 📐 | Saved hypothetical scenario simulations | name, scenario_type ENUM, base_session_id, input_changes_json, current_state_json, projected_state_json, delta_json |
| `pan_custom_reports` 📐 | Saved custom report builder definitions | report_name, field_selections_json, filter_config_json, chart_type ENUM, is_shared, shared_with_json |

### 5.2 Key Column Details

**`pan_prediction_models` — ENUM values:**
- `model_type`: performance, dropout, learning_gap, attendance_forecast, fee_default, sentiment, resource_allocation

**`pan_student_predictions` — ENUM values:**
- `prediction_type`: performance, dropout_risk, attendance_forecast, skill_gap
- `risk_level`: low, medium, high, critical

**`pan_early_warnings` — ENUM values:**
- `warning_type`: attendance, performance, fee, behaviour, engagement, sentiment_spike
- `severity`: info, warning, critical
- `next_action`: parent_call, counseling, study_plan, fee_reminder, none

**`pan_kpi_snapshots` — ENUM values:**
- `kpi_type`: enrollment, attendance_rate, exam_pass_rate, fee_collection_ratio, new_admissions, open_complaints, teacher_retention, avg_exam_score

### 5.3 Relationships

| Parent Table | Child Table | FK Column | Type |
|---|---|---|---|
| `std_students` | `pan_student_predictions` | student_id | HasMany |
| `std_students` | `pan_early_warnings` | student_id | HasMany |
| `std_students` | `pan_fee_risk_profiles` | student_id | HasMany |
| `std_students` | `pan_skill_gap_summaries` | student_id | HasMany |
| `pan_prediction_models` | `pan_student_predictions` | model_id | HasMany |
| `pan_student_predictions` | `pan_early_warnings` | reference_prediction_id | BelongsTo |
| `sys_users` | `pan_early_warnings` | acknowledged_by | BelongsTo |
| `sys_users` | `pan_fee_risk_profiles` | guardian_id | BelongsTo |
| `tpt_routes` | `pan_transport_analyses` | route_id | BelongsTo (nullable) |
| `lxp_skills` | `pan_skill_gap_summaries` | skill_id | BelongsTo |

### 5.4 Generated Columns

| Table | Column | Expression |
|---|---|---|
| `pan_skill_gap_summaries` | `gap_magnitude` | `(expected_skill_score - current_skill_score)` VIRTUAL |
| `pan_benchmark_kpis` | `gap_from_median` | `(own_value - peer_median)` VIRTUAL |

### 5.5 Indexes

| Table | Index Name | Columns | Type |
|---|---|---|---|
| `pan_student_predictions` | idx_pan_pred_student_type_session | student_id, prediction_type, academic_session_id | BTREE |
| `pan_early_warnings` | idx_pan_warn_student_type | student_id, warning_type, is_acknowledged | BTREE |
| `pan_kpi_snapshots` | uq_pan_kpi_date_type_cat | snapshot_date, kpi_type, category | UNIQUE |
| `pan_fee_risk_profiles` | uq_pan_fee_risk_guardian_student | guardian_id, student_id | UNIQUE |
| `pan_skill_gap_summaries` | uq_pan_gap_student_skill_session | student_id, skill_id, academic_session_id | UNIQUE |
| `pan_benchmark_kpis` | uq_pan_benchmark_date_kpi | benchmark_date, kpi_type | UNIQUE |
| `pan_prediction_models` | uq_pan_model_type_version | model_type, version | UNIQUE |
| `pan_sentiment_records` | idx_pan_sentiment_source | source_type, source_ref_id | BTREE |

---

## 6. API Endpoints & Routes

Route group: `prefix='analytics'`, `middleware=['auth','verified','tenant']`, `name='analytics.'`

### 6.1 Dashboard & KPI

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/dashboard | PanDashboardController@index | admin,principal | KPI dashboard with trend cards |
| GET | /analytics/dashboard/health-score | PanDashboardController@healthScore | admin,principal | Composite health score (AJAX) |
| GET | /analytics/dashboard/kpi-trend | PanDashboardController@kpiTrend | admin,principal | KPI time-series data for chart (AJAX) |

### 6.2 Early Warnings

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/early-warnings | EarlyWarningController@index | admin,principal,teacher | Active warning queue |
| GET | /analytics/early-warnings/{warning} | EarlyWarningController@show | admin,principal,teacher | Warning detail |
| POST | /analytics/early-warnings/{warning}/acknowledge | EarlyWarningController@acknowledge | admin,principal,teacher | Acknowledge + record intervention |
| GET | /analytics/early-warnings/student/{student} | EarlyWarningController@studentHistory | admin,principal,teacher | Full warning history per student |

### 6.3 Performance Predictions

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/predictions/performance | PerformancePredictionController@index | admin,principal,teacher | Class-level prediction table |
| GET | /analytics/predictions/performance/{student} | PerformancePredictionController@show | admin,principal,teacher | Per-student factor breakdown |
| POST | /analytics/predictions/performance/run | PerformancePredictionController@runModel | admin | Trigger prediction job manually |
| GET | /analytics/predictions/dropout | PerformancePredictionController@dropout | admin,principal | Dropout risk ranked list |

### 6.4 Attendance Forecasts

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/predictions/attendance | AttendanceForecastController@index | admin,principal,teacher | Weekly absence forecast table |
| GET | /analytics/predictions/attendance/trends | AttendanceForecastController@trends | admin,principal,teacher | Attendance anomaly trend chart |

### 6.5 Fee Default Risk

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/predictions/fee-default | FeeDefaultController@index | admin,accounts | Fee risk table sorted by score |
| GET | /analytics/predictions/fee-default/segments | FeeDefaultController@segments | admin,accounts | Segment distribution chart |

### 6.6 Learning Gaps

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/skill-gaps | SkillGapController@index | admin,principal,teacher | School-wide gap summary |
| GET | /analytics/skill-gaps/{student} | SkillGapController@studentGaps | admin,principal,teacher | Per-student gap list |
| GET | /analytics/skill-gaps/class-heatmap | SkillGapController@classHeatmap | admin,principal,teacher | Class skill heatmap grid |

### 6.7 Teacher Analytics

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/teacher-analytics | TeacherAnalyticsController@index | admin,principal | Teacher effectiveness table |
| GET | /analytics/teacher-analytics/workload | TeacherAnalyticsController@workload | admin,principal | Workload distribution chart |

### 6.8 Transport Analytics

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/transport | TransportAnalyticsController@index | admin,transport_coordinator | Route efficiency analysis |
| POST | /analytics/transport/simulate | TransportAnalyticsController@simulate | admin | Route merge/stop removal simulation |

### 6.9 Sentiment Analysis

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/sentiment | SentimentController@index | admin,principal | Sentiment overview + theme breakdown |
| GET | /analytics/sentiment/trends | SentimentController@trends | admin,principal | Time-series sentiment trend chart |

### 6.10 Benchmarking

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/benchmarking | BenchmarkingController@index | admin,principal | KPI benchmark comparison |
| POST | /analytics/benchmarking/run | BenchmarkingController@run | admin | Trigger benchmark comparison run |

### 6.11 Cohort Analysis

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/cohort | CohortController@index | admin,principal | Saved cohort analyses list |
| GET | /analytics/cohort/create | CohortController@create | admin,principal | Cohort analysis builder |
| POST | /analytics/cohort | CohortController@store | admin,principal | Run and save cohort analysis |
| GET | /analytics/cohort/{cohort} | CohortController@show | admin,principal | Multi-year comparison chart |

### 6.12 What-If Scenarios

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/what-if | WhatIfController@index | admin,principal | Saved scenarios list |
| GET | /analytics/what-if/create | WhatIfController@create | admin,principal | Scenario builder form |
| POST | /analytics/what-if | WhatIfController@store | admin,principal | Run simulation and save |
| GET | /analytics/what-if/{scenario} | WhatIfController@show | admin,principal | Current vs projected comparison |

### 6.13 Custom Reports

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/custom-reports | CustomReportController@index | admin,principal | Saved reports list |
| GET | /analytics/custom-reports/create | CustomReportController@create | admin,principal | Report builder UI |
| POST | /analytics/custom-reports | CustomReportController@store | admin,principal | Save report definition |
| GET | /analytics/custom-reports/{report}/run | CustomReportController@run | admin,principal | Execute and display report |
| GET | /analytics/custom-reports/{report}/export | CustomReportController@export | admin,principal | Export PDF/Excel |
| DELETE | /analytics/custom-reports/{report} | CustomReportController@destroy | admin | Delete saved report |

### 6.14 Model Management

| Method | URI | Controller@Method | Auth Role | Description |
|---|---|---|---|---|
| GET | /analytics/models | PanDashboardController@models | admin | Model list with accuracy scores |
| GET | /analytics/models/{model}/edit | PanDashboardController@editModel | admin | Edit model weights/thresholds |
| PUT | /analytics/models/{model} | PanDashboardController@updateModel | admin | Save model configuration |
| POST | /analytics/models/{model}/run | PanDashboardController@runModel | admin | Manually trigger prediction job |

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Key Elements |
|---|---|---|---|
| PAN-SCR-01 | KPI Dashboard | analytics.dashboard | KPI cards with trend arrows, 30-day chart, health score widget, recent warnings panel |
| PAN-SCR-02 | Early Warning Queue | analytics.early-warnings.index | Severity-filtered list, bulk acknowledge, unacknowledged counter badge |
| PAN-SCR-03 | Warning Detail | analytics.early-warnings.show | Warning info, acknowledge form, intervention type dropdown, notes textarea |
| PAN-SCR-04 | Student Warning History | analytics.early-warnings.student-history | Timeline of all warnings per student |
| PAN-SCR-05 | Performance Prediction (Class) | analytics.predictions.performance | Filterable table: student, subject, predicted score, risk badge, trend indicator |
| PAN-SCR-06 | Performance Prediction (Student) | analytics.predictions.performance.show | Factor breakdown bar chart, weak areas list, link to recommendation |
| PAN-SCR-07 | Dropout Risk Dashboard | analytics.predictions.dropout | Ranked list by dropout score, risk factor heatmap, days-since-engagement |
| PAN-SCR-08 | Attendance Forecast | analytics.predictions.attendance | Weekly probability grid, anomaly trend chart |
| PAN-SCR-09 | Fee Default Risk | analytics.predictions.fee-default | Risk-sorted guardian table, segment donut chart |
| PAN-SCR-10 | Skill Gap Summary | analytics.skill-gaps.index | School-wide top gaps table, subject filter |
| PAN-SCR-11 | Student Skill Gap | analytics.skill-gaps.student | Per-student gap list with magnitude bars, recommended action links |
| PAN-SCR-12 | Class Skill Heatmap | analytics.skill-gaps.class-heatmap | Color-coded grid (skills × students), legend, filter by class/section |
| PAN-SCR-13 | Teacher Effectiveness | analytics.teacher-analytics.index | Sortable metrics table, YoY delta column, overloaded badge |
| PAN-SCR-14 | Teacher Workload | analytics.teacher-analytics.workload | Bar chart of periods/teacher, max threshold line |
| PAN-SCR-15 | Transport Analytics | analytics.transport.index | Route efficiency cards, optimization suggestion list |
| PAN-SCR-16 | Route Simulation | analytics.transport.simulate | Scenario builder, Current vs Proposed side-by-side comparison |
| PAN-SCR-17 | Sentiment Overview | analytics.sentiment.index | Theme breakdown pie/bar chart, recent flagged texts |
| PAN-SCR-18 | Sentiment Trends | analytics.sentiment.trends | Time-series line chart per theme, spike alerts |
| PAN-SCR-19 | Benchmarking | analytics.benchmarking.index | KPI comparison table, radar chart, gap analysis narrative |
| PAN-SCR-20 | Cohort Analysis | analytics.cohort.show | Multi-line chart (one line per academic year), tabular comparison |
| PAN-SCR-21 | What-If Scenario | analytics.what-if.show | Input parameters panel, Current vs Projected comparison table |
| PAN-SCR-22 | Custom Report Builder | analytics.custom-reports.create | Field catalog drag-drop panel, filter builder, chart type selector |
| PAN-SCR-23 | Custom Report Result | analytics.custom-reports.run | Chart/table render, PDF/Excel export buttons |
| PAN-SCR-24 | Model Management | analytics.models.index | Model list with accuracy, last run time, active toggle, manual run button |

---

## 8. Business Rules

| Rule ID | Rule | Rationale |
|---|---|---|
| BR-PAN-001 | Prediction models only run when at least 4 weeks of data exists in the current academic session | Statistical validity — insufficient data produces unreliable predictions |
| BR-PAN-002 | Early warnings are insert-only; never hard-deleted. Acknowledged warnings move to historical view (is_active=0 conceptually via acknowledged flag) | Audit trail — complete warning history preserved |
| BR-PAN-003 | KPI snapshots are immutable once created (no UPDATE; only new INSERT per date/kpi_type) | Time-series integrity — historical trend data must not change |
| BR-PAN-004 | Sentiment analysis raw_text column is nullified after 90 days via scheduled cleanup | Data privacy — minimise personal text retention |
| BR-PAN-005 | Benchmarking reads only anonymized aggregate columns from prime_db — individual tenant identifiers are never returned | Multi-tenant privacy — tenant isolation is inviolable |
| BR-PAN-006 | Custom report builder restricts queries to a pre-defined field catalog; no raw SQL input accepted | Security — prevents SQL injection via report builder |
| BR-PAN-007 | `actual_value` on `pan_student_predictions` populated only after official exam results are published (status='published' in exm_*); not manually editable | Data integrity — predictions validated only against authoritative actuals |
| BR-PAN-008 | Fee default predictions visible only to accounts staff and admin; teachers cannot access `pan_fee_risk_profiles` | Privacy — financial risk data is sensitive |
| BR-PAN-009 | What-if simulations operate on cloned data snapshots; no live table is modified | Safety — simulations must not contaminate operational data |
| BR-PAN-010 | Critical early warning must generate a system notification to admin within 1 hour of creation | SLA — critical student risk requires timely human review |
| BR-PAN-011 | Model accuracy alert triggered if accuracy_score drops below 70% after actuals validation | Model quality gate — degraded models should not silently produce unreliable outputs |
| BR-PAN-012 | `recommendation_triggered` flag prevents duplicate PAN-to-Recommendation triggers for the same gap record | Idempotency — prevents duplicate recommendation creation on re-runs |
| BR-PAN-013 | Teacher effectiveness analytics are read-only for admin/principal; results are analytical only and not integrated with formal HR evaluation | Governance — analytical insights must not substitute HR processes |
| BR-PAN-014 | Dropout risk composite score weights must sum to exactly 1.0; validated on model configuration save | Mathematical correctness of weighted formula |

---

## 9. Workflow Diagrams (FSM Descriptions)

### 9.1 Prediction Job Lifecycle FSM

```
IDLE
  → [scheduled trigger / manual admin run]
VALIDATING_DATA_SUFFICIENCY
  → [< 4 weeks data] → ABORTED (log message; no records created)
  → [≥ 4 weeks data]
RUNNING_MODEL
  → [for each student-subject pair: compute weighted score]
STORING_PREDICTIONS
  → [upsert pan_student_predictions]
EVALUATING_RISK_LEVELS
  → [assign low/medium/high/critical per threshold_config_json]
TRIGGERING_EARLY_WARNINGS
  → [for each critical/high risk: create pan_early_warnings if not already active]
SENDING_NOTIFICATIONS
  → [dispatch notification to class teacher per warning]
COMPLETED
```

### 9.2 Early Warning Acknowledgment FSM

```
CREATED (is_acknowledged=0)
  → [teacher/admin views warning]
VIEWED
  → [teacher selects next_action + enters notes + clicks Acknowledge]
ACKNOWLEDGED (is_acknowledged=1, acknowledged_at=now)
  → [removed from active queue; appears in history]

CREATED (is_acknowledged=0, severity=critical)
  → [48h elapsed, still unacknowledged]
ESCALATED (escalated_at=now, notification sent to admin)
  → [admin acknowledges]
ACKNOWLEDGED
```

### 9.3 KPI Snapshot Daily FSM

```
SCHEDULED (1 AM daily)
  → [KpiSnapshotService::computeDailySnapshots()]
FOR_EACH_KPI_TYPE
  → [query source tables]
  → [compute value]
  → [read 7d and 30d prior snapshot for comparison]
  → [compute trend: up/down/stable]
  → [INSERT into pan_kpi_snapshots (UNIQUE on date+type+category = skip if exists)]
COMPUTE_HEALTH_SCORE
  → [weighted average of normalized KPI values]
COMPLETED
```

### 9.4 PAN-to-Recommendation Pipeline FSM

```
GAP_IDENTIFIED (gap_magnitude > 20 AND recommendation_triggered=0)
  → [SkillGapAnalysisService::triggerRecommendations()]
  → [RecommendationService::createFromPan(student_id, gap_data)]
  → [rec_student_recommendations record created, trigger_source='pan_gap_analysis']
  → [pan_skill_gap_summaries.recommendation_triggered = 1]
RECOMMENDATION_QUEUED
  → [LXP PathSuggestionService picks up at next cycle]
PATH_UPDATED
```

---

## 10. Non-Functional Requirements

| Requirement | Target | Implementation Notes |
|---|---|---|
| Prediction Job Duration | < 5 minutes per session (≤ 1000 students) | Queue-based async job; chunked student processing |
| KPI Dashboard Load Time | < 3 seconds | Reads from pre-computed pan_kpi_snapshots; no live aggregation on page load |
| Skill Heatmap Query | < 2 seconds for 50 students × 20 skills | Optimized pivot query with composite index |
| Sentiment Batch Throughput | ≥ 100 records/minute | Rule-based NLP; no external API calls |
| Custom Report Execution | < 10 seconds | Field catalog constrains query complexity; result cached per report definition |
| Early Warning Escalation Latency | ≤ 1 hour for critical warnings | Hourly Artisan command `analytics:escalate-warnings` |
| Tenant Data Isolation | 100% — no cross-tenant data leakage | stancl/tenancy v3.9; all queries scoped to current tenant DB |
| Data Retention — Predictions | 2 academic sessions then archivable | Configurable per deployment |
| Data Retention — KPI Snapshots | Indefinite (immutable time-series) | Historical trend value; low storage footprint |
| Soft Delete | All pan_* tables with is_active + deleted_at | Standard platform pattern |
| Audit Trail | Model config changes and warning acknowledgments logged to sys_activity_logs | Standard platform pattern |
| PDF Export | DomPDF (already in platform) | Consistent with other modules |
| Excel Export | Laravel Excel (Maatwebsite) or native fputcsv | Consistent with Timetable Analytics module |
| Security — Report Builder | All field references validated against PHP-side catalog before query execution | SQL injection prevention via allowlist |

---

## 11. Module Dependencies

### 11.1 Inbound Data Sources (PAN reads from)

| Module | Table(s) Read | Purpose |
|---|---|---|
| Student Mgmt (STD) | std_students, std_attendance | Student list; attendance records for forecasting and dropout risk |
| Exam (EXA) | exm_results, exm_exam_marks | Exam scores for performance prediction; actuals for accuracy validation |
| Finance / Fee (FIN) | fin_fee_transactions, fin_fee_dues | Fee payment history for default prediction |
| Transport (TPT) | tpt_routes, tpt_stops, tpt_student_routes_jnt | Ridership and route data for transport analytics |
| Complaint (CMP) | cmp_complaints | Complaint text for sentiment analysis |
| LXP | lxp_student_skills, lxp_engagement_logs, lxp_forum_threads | Skill scores, engagement signals, forum text |
| SmartTimetable (TT) | tt_timetable_cells, tt_activities | Teaching period counts per teacher for workload analytics |
| School Setup (SCH) | sch_academic_sessions, sch_classes, sch_sections | Academic context for all models |
| Behavior (BEH) | beh_incidents | Behavioral incident count for dropout risk |
| prime_db (cross-tenant) | Anonymized KPI aggregate tables | Peer group data for benchmarking (anonymized only) |

### 11.2 Outbound Writes (PAN writes to)

| Module | Table(s) Written | Purpose |
|---|---|---|
| Recommendation (REC) | rec_student_recommendations | Gap-triggered and performance-risk-triggered recommendations |
| Notification (NTF) | via NotificationService | Early warning alerts to teachers and admin |
| Activity Log (SYS) | sys_activity_logs | Model configuration changes and acknowledgment audit trail |

### 11.3 Artisan Commands & Schedules

| Command | Schedule | Job Dispatched | Purpose |
|---|---|---|---|
| `analytics:run-performance-predictions` | Weekly (Sun 2 AM) | GeneratePerformancePredictionsJob | Batch performance + dropout predictions |
| `analytics:run-attendance-forecasts` | Daily (5 AM) | GenerateAttendanceForecastsJob | Weekly absence probability forecasts |
| `analytics:run-fee-default-predictions` | Weekly (Mon 6 AM) | GenerateFeeDefaultPredictionsJob | Fee default scoring before reminder cycle |
| `analytics:run-sentiment-analysis` | Daily (3 AM) | RunSentimentAnalysisJob | Process new complaint/post text |
| `analytics:compute-kpi-snapshots` | Daily (1 AM) | Synchronous (KpiSnapshotService) | Compute and store KPI snapshots |
| `analytics:escalate-warnings` | Hourly | Synchronous query | Escalate unacknowledged critical warnings |

### 11.4 Service Contracts

| Service | Key Methods |
|---|---|
| PerformancePredictionService | runForSession(sessionId, ?classId), predictForStudent(studentId, subjectId, sessionId), validateAccuracy(sessionId) |
| AttendanceForecastService | forecastForStudent(studentId), detectAnomalies(classId, sessionId), runWeeklyForecasts(sessionId) |
| FeeDefaultPredictionService | scoreGuardian(guardianId, studentId), runSegmentation(sessionId), triggerReminders(guardianIds[]) |
| SkillGapAnalysisService | analyzeStudent(studentId, sessionId), analyzeClass(classId, sectionId, sessionId), triggerRecommendations(gap) |
| SentimentAnalysisService | analyze(text, sourceType), processComplaintsBatch(sessionId), detectSpikes(theme, lookbackDays) |
| KpiSnapshotService | computeDailySnapshots(), computeHealthScore(), getKpiTrend(kpiType, days) |

---

## 12. Test Scenarios

| # | Test Scenario | Type | FR Reference | Priority |
|---|---|---|---|---|
| T-01 | Student with 40% attendance + 30% mid-term → predicted score < 35%, risk_level = critical | Unit | FR-PAN-001 | High |
| T-02 | Performance prediction batch runs for 100 students without timeout | Feature | FR-PAN-001 | High |
| T-03 | Model skips run when session has < 4 weeks of data; no predictions created | Feature | BR-PAN-001 | High |
| T-04 | Critical-risk student triggers early warning creation automatically post-prediction | Feature | FR-PAN-006 | High |
| T-05 | Unacknowledged critical warning escalated_at populated after 48h by hourly command | Feature | FR-PAN-006 | High |
| T-06 | Warning acknowledged; intervention notes saved; warning removed from active queue | Browser | FR-PAN-006 | High |
| T-07 | Admin notification dispatched within 1 hour of critical warning creation | Feature | BR-PAN-010 | High |
| T-08 | KPI snapshot computed daily; enrollment value matches std_students active count | Feature | FR-PAN-005 | High |
| T-09 | Duplicate snapshot insert skipped via UNIQUE constraint on (date, kpi_type, category) | Unit | BR-PAN-003 | High |
| T-10 | Cohort analysis correctly compares two academic year exam pass rates on multi-line chart | Feature | FR-PAN-015 | High |
| T-11 | Skill gap: student with skill_score=30, expected=60 → gap_magnitude generated column = 30 | Unit | FR-PAN-003 | High |
| T-12 | Gap magnitude > 20 triggers RecommendationService::createFromPan() call | Feature | FR-PAN-017 | High |
| T-13 | recommendation_triggered=1 prevents duplicate trigger on second analysis run | Unit | BR-PAN-012 | High |
| T-14 | Class skill heatmap renders correctly for 50-student × 20-skill matrix in < 2s | Browser | FR-PAN-003 | Medium |
| T-15 | Fee default risk scoring classifies chronic late payer (3 overdue, 45 avg days) as high risk | Unit | FR-PAN-008 | Medium |
| T-16 | Fee default data returns 403 when accessed by teacher role | Feature | BR-PAN-008 | High |
| T-17 | Sentiment analysis labels complaint text with "teaching_quality" theme and "negative" label | Unit | FR-PAN-010 | Medium |
| T-18 | Sentiment spike (daily count > 3× 7-day avg) creates pan_early_warnings record | Feature | FR-PAN-010 | Medium |
| T-19 | Custom report builder rejects field not in pre-defined catalog with validation error | Feature | BR-PAN-006 | High |
| T-20 | What-if simulation produces delta; original pan_student_predictions unchanged | Feature | FR-PAN-012 | High |
| T-21 | Dropout risk score correctly weights all 5 factors and produces score in 0–100 range | Unit | FR-PAN-002 | Medium |
| T-22 | Benchmarking query does not return individual tenant identifier from prime_db | Feature | BR-PAN-005 | High |
| T-23 | Model accuracy score (MAE) updated correctly after exam results published | Feature | FR-PAN-014 | Medium |
| T-24 | Admin alert triggered when accuracy_score drops below 70% | Feature | BR-PAN-011 | Medium |
| T-25 | Transport route simulation returns comparison table without modifying tpt_* records | Feature | FR-PAN-009 | Low |
| T-26 | Teacher effectiveness table shows YoY delta computed from previous academic session | Browser | FR-PAN-004 | Medium |
| T-27 | Raw sentiment text nullified after 90-day cleanup command runs | Feature | BR-PAN-004 | Medium |
| T-28 | Attendance forecast generates 7 daily probability values per student per week | Unit | FR-PAN-007 | Medium |

---

## 13. Glossary

| Term | Definition |
|---|---|
| At-Risk Student | A student whose combined risk signals (attendance, performance, engagement, behavior, fee default) indicate elevated probability of academic failure or dropout |
| Cohort Analysis | Comparison of performance metrics for the same class level across multiple academic years |
| Composite Dropout Risk Score | A weighted aggregate score (0–100) combining attendance decline, performance risk, fee delay, behavioral incidents, and engagement decline |
| Confidence Interval | Plus/minus range around a predicted score, e.g., predicted 55% ± 8 points |
| Field Catalog | Pre-defined allowlist of data fields available in the Custom Report Builder; enforces query safety |
| Gap Magnitude | Numeric difference between expected_skill_score and current_skill_score (computed VIRTUAL column) |
| KPI Snapshot | Immutable daily record of a school-wide key performance indicator value with trend comparison |
| MAE | Mean Absolute Error — average of |predicted - actual| values; used to measure prediction model accuracy |
| NLP | Natural Language Processing — analysis of text to extract sentiment and themes |
| Peer Group | Anonymized cohort of other Prime-AI tenant schools with similar attributes (type, enrollment range, board affiliation) used for benchmarking |
| Risk Level | Categorical risk classification: low, medium, high, critical — derived from predicted values vs threshold_config_json |
| School Health Score | Composite index computed as weighted average of normalized KPI values; single number representing overall school performance |
| Sentiment Spike | Occurrence where daily negative sentiment count for a theme exceeds 3× the 7-day rolling average |
| What-If Scenario | A hypothetical simulation that applies parameter changes to cloned prediction data to project outcome impact without modifying live records |

---

## 14. Suggestions & Improvements (V2 New)

### 14.1 Architecture Suggestions

| # | Suggestion | Rationale |
|---|---|---|
| S-01 | Add a `pan_model_run_logs` table to record each prediction job run: start_time, end_time, records_processed, error_count, triggered_by | Enables model run audit trail and debugging without relying on Laravel logs |
| S-02 | Implement a `pan_alert_thresholds` configuration table per tenant rather than hardcoding thresholds in model config JSON | Allows school admins to tune warning thresholds (e.g., school-specific "at-risk attendance" may be 70% instead of 75%) |
| S-03 | Add `pan_intervention_log` table to track all interventions taken per student over time (extracted from early_warnings.intervention_notes) | Enables intervention effectiveness analysis and student counseling history |
| S-04 | Consider a `pan_ai_insights` table for auto-generated narrative insights (e.g., "Class 10A attendance has improved 12% compared to last month") displayed on the dashboard | Structured insights are more maintainable than free-text generation |

### 14.2 Feature Suggestions

| # | Suggestion | Rationale |
|---|---|---|
| S-05 | Expose prediction data via REST API endpoints (api.php) for mobile app consumption — principals and teachers often need insights on mobile | Aligns with V6 (Dashboard Insights) RBS sub-module; future-proofs for mobile app development |
| S-06 | Add enrollment trend forecasting as a KPI type — project next-year enrollment based on current admission inquiry pipeline and historical churn | High business value for school capacity planning |
| S-07 | Implement configurable notification digest (daily/weekly summary of all warnings) instead of per-warning notifications for teachers | Reduces notification fatigue; teachers often ignore individual alerts |
| S-08 | Add teacher-facing early warning dismissal (separate from admin acknowledgment) — teacher marks "intervention done" independently | Gives teachers agency without requiring admin to close every warning |
| S-09 | Consider integrating Python microservice call for the performance prediction model (Random Forest / XGBoost via Flask/FastAPI) as the RBS specifies — PHP weighted formula is a v1 compromise | Improves prediction accuracy; aligns with RBS technology specification |
| S-10 | Add "intervention effectiveness tracking" — after a warning is acknowledged and intervention recorded, track whether the student's risk score improves in the next prediction cycle | Closes the feedback loop; allows school to evaluate which interventions work |

### 14.3 Data Privacy Suggestions

| # | Suggestion | Rationale |
|---|---|---|
| S-11 | Implement explicit consent tracking in `pan_consent_log` for sentiment analysis of parent/student forum posts | DPDP Act 2023 (India) requires consent for processing personal text data |
| S-12 | Add data subject access request support — export all PAN records for a specific student in JSON/PDF | Compliance with student data rights provisions |

---

## 15. Appendices

### 15.1 Artisan Command Reference

```bash
# Run performance and dropout predictions for active session
php artisan analytics:run-performance-predictions

# Generate weekly attendance forecasts
php artisan analytics:run-attendance-forecasts

# Score all guardians for fee default risk
php artisan analytics:run-fee-default-predictions

# Process unanalyzed complaint/forum text through sentiment engine
php artisan analytics:run-sentiment-analysis

# Compute and store daily KPI snapshots
php artisan analytics:compute-kpi-snapshots

# Escalate unacknowledged critical warnings older than 48h
php artisan analytics:escalate-warnings
```

### 15.2 Kernel Schedule (Proposed)

```php
// In app/Console/Kernel.php or Modules/PredictiveAnalytics ServiceProvider
$schedule->command('analytics:compute-kpi-snapshots')->dailyAt('01:00');
$schedule->command('analytics:run-sentiment-analysis')->dailyAt('03:00');
$schedule->command('analytics:run-attendance-forecasts')->dailyAt('05:00');
$schedule->command('analytics:run-performance-predictions')->weekly()->sundays()->at('02:00');
$schedule->command('analytics:run-fee-default-predictions')->weekly()->mondays()->at('06:00');
$schedule->command('analytics:escalate-warnings')->hourly();
```

### 15.3 Prediction Model — Performance Formula (v1)

```
predicted_score = (attendance_rate × 0.25)
                + (mid_term_score_percentile × 0.40)
                + (quiz_avg_score × 0.20)
                + (homework_submission_rate × 0.10)
                + (lxp_engagement_score × 0.05)

risk_level =
  predicted_score < 35%  → critical
  predicted_score < 50%  → high
  predicted_score < 60%  → medium
  predicted_score ≥ 60%  → low
```

### 15.4 Dropout Risk Score Formula (v1)

```
dropout_score = (attendance_decline_trend × 0.35)
              + (performance_risk_level_normalized × 0.25)
              + (fee_payment_delay_score × 0.20)
              + (behavioral_incidents_normalized × 0.10)
              + (engagement_decline_score × 0.10)

All input factors normalized to 0–100 range before weighting.
Final score range: 0–100.
dropout_score > 70 → HIGH risk → critical early warning
dropout_score > 50 → visible on dropout dashboard
```

### 15.5 Field Catalog (Custom Report Builder — Initial Set)

| Field ID | Display Name | Source Table | Column |
|---|---|---|---|
| student.name | Student Name | std_students | full_name |
| student.class | Class | sch_classes | class_name |
| student.section | Section | sch_sections | section_name |
| attendance.rate | Attendance Rate % | std_attendance | computed |
| exam.latest_score | Latest Exam Score | exm_results | marks_obtained |
| exam.pass_rate | Exam Pass Rate % | exm_results | computed |
| fee.outstanding | Outstanding Fee | fin_fee_dues | balance_amount |
| fee.risk_score | Fee Risk Score | pan_fee_risk_profiles | risk_score |
| prediction.performance | Predicted Performance Score | pan_student_predictions | predicted_value |
| prediction.dropout | Dropout Risk Score | pan_student_predictions | predicted_value |
| gap.skill_gap | Skill Gap Magnitude | pan_skill_gap_summaries | gap_magnitude |

---

## 16. V1 → V2 Delta

### 16.1 What V2 Adds Over V1

| Area | V1 Specification | V2 Change |
|---|---|---|
| Sub-module naming | Used RBS Module V codes (V1–V6) loosely | Aligned to PAN-01 through PAN-17 with explicit FR-PAN-XXX numbering |
| Functional Requirements | 17 FRs defined but grouped inconsistently (FR-PAN-007 was a duplicate reference to FR-PAN-005) | FR-PAN-007 replaced with Cohort Analysis as distinct FR; all FRs are unique and non-overlapping |
| Teacher Analytics | Covered briefly under Resource Allocation (FR-PAN-004) | Promoted to standalone sub-module PAN-04 with dedicated controller (TeacherAnalyticsController) and screen |
| Cohort Analysis | Embedded inside FR-PAN-005 (School KPI Dashboard) | Extracted to FR-PAN-015 with dedicated CohortController, routes, and views for clarity |
| Subject Difficulty | Mentioned in FR-PAN-008 with no dedicated FR | Promoted to FR-PAN-016 with explicit AC and CSV export requirement |
| Routes | Presented as code comments block | Reformatted into typed route tables grouped by feature area; 14 route groups; explicit auth role column |
| UI Screens | Listed as blade view paths | Reformatted as Screen ID table with route name and key UI elements |
| Artisan Commands | Listed 6 commands in a table | Retained; added Kernel schedule code snippet in appendix |
| Business Rules | 10 rules | Expanded to 14 rules; added BR-PAN-011 (model accuracy alert), BR-PAN-012 (idempotent recommendation trigger), BR-PAN-013 (teacher analytics governance), BR-PAN-014 (weight sum validation) |
| Non-Functional Requirements | 9 NFRs | Expanded to 14 NFRs; added PDF/Excel export library references, security NFR for report builder |
| Test Scenarios | 20 test cases | Expanded to 28 test scenarios; added T-03 (4-week data gate), T-07 (1h notification SLA), T-09 (UNIQUE constraint), T-13 (idempotent trigger), T-27 (raw text nullification) |
| Suggestions | None | 10 suggestions added across architecture, features, and data privacy |
| Glossary | None | 14 terms defined |
| Data Privacy | BR-PAN-004 (raw text 90-day nullification) | Added S-11 (DPDP Act consent tracking) and S-12 (data subject access request) in suggestions |
| Status Markers | Mixed ❌ and 📐 usage | All FRs consistently marked 📐 Proposed; all tables marked 📐 new |

### 16.2 What V2 Clarifies

- The distinction between **PAN (predictive, forward-looking, probabilistic)** and **REC (rule-based, reactive, content-suggestion)** modules is now explicitly stated in the executive summary.
- The `pan_skill_gap_summaries.gap_magnitude` GENERATED VIRTUAL column is now documented as a design pattern alongside `pan_benchmark_kpis.gap_from_median`.
- The `recommendation_triggered` flag idempotency mechanism is now a first-class business rule (BR-PAN-012) and test scenario (T-13).
- Fee default data access restriction is now BR-PAN-008 with supporting test T-16.
- The benchmarking cross-tenant privacy guarantee (BR-PAN-005) is now backed by T-22.
- Python microservice pathway (Random Forest / XGBoost via Flask/FastAPI) is acknowledged in suggestion S-09 as the target architecture per RBS, with PHP weighted formula as v1 approximation.

