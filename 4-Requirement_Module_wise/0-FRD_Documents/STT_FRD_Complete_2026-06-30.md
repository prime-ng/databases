# STT — SmartTimetable
## Complete Analysis Pack
**Version:** 1.0 | **Date:** 2026-06-30 | **Status:** Final
**Module Code:** STT | **Scope:** Tenant | **Table Prefix:** `tt_*`
**FRD Reference:** `STT_FRD_2026-06-30.md` (sibling file, same folder)
**Sources:** Same as FRD — DDL v7.8, V2 Requirement v2.0, V1 screen specs (7 files), live code scan (2026-06-30), STT_SmartTimetable.md v1.0

---

## Table of Contents

1. [Module Summary Card](#1-module-summary-card)
2. [Requirements Traceability Matrix (RTM)](#2-requirements-traceability-matrix-rtm)
3. [Business Rules Register + Conditions Catalog + Validation Catalog](#3-business-rules-register--conditions-catalog--validation-catalog)
4. [Process Flows and FSM Catalog](#4-process-flows-and-fsm-catalog)
5. [Data Dictionary and Cross-Module Dependency Map](#5-data-dictionary-and-cross-module-dependency-map)
6. [NFR Catalog and Risk Register](#6-nfr-catalog-and-risk-register)
7. [MoSCoW Prioritization, Effort Estimation, and Sprint Tasks](#7-moscow-prioritization-effort-estimation-and-sprint-tasks)
8. [User Stories and KPI Catalog](#8-user-stories-and-kpi-catalog)

---

## 1. Module Summary Card

| Attribute | Value |
|-----------|-------|
| Module Name | SmartTimetable |
| Module Code | STT |
| Laravel Module Path | `Modules/SmartTimetable/` |
| Companion Module | TimetableFoundation (TTF) — prerequisite master-data module |
| Standard Module (Planned) | StandardTimetable (STA) — manual drag-and-drop builder, separate module |
| Table Prefix | `tt_*` (shared between STT, TTF, STA) |
| Scope | Tenant (database-per-tenant; no `tenant_id` columns) |
| Completion Estimate | 68% (FRD-based) |
| V2 Requirement Version | v2.0, 2026-03-26 |
| DDL Version | v7.8 (header describes v7.7 changes) |
| FRD Date | 2026-06-30 |
| Module Knowledge File | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/STT_SmartTimetable.md` |
| FRD File | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/STT_FRD_2026-06-30.md` |
| Functional Requirements | 17 (REQ-STT-001 through REQ-STT-017) |
| Business Rules | 26 (BR-STT-001 through BR-STT-026) |
| Reports | 6 (RPT-STT-001 through RPT-STT-006) |
| Enhancements | 6 (ENH-STT-001 through ENH-STT-006) |
| Known Gaps (Critical) | BUG-STT-05 (constraint bridge broken), REQ-011 (approval UI), REQ-016 (standard views), SEC-STT-01 (EnsureTenantHasModule missing), SEC-STT-02 (Gate::authorize absent in Analytics) |
| Est. Remediation Effort | 128 hours (core gaps) |

### 1.1 Implementation Heat Map

| Area | Status | % | Critical Gaps |
|------|:------:|:-:|--------------|
| Foundation Masters (REQ-001) | TTF scope | 90% | None |
| Requirement Definition (REQ-002) | TTF scope | 90% | None |
| Constraint Engine (REQ-003) | Partial | 60% | BUG-STT-05 (DB constraints not wired to solver) |
| Availability Management (REQ-004) | TTF scope | 85% | None |
| Activity Management (REQ-005) | Partial | 90% | Minor: sub-activity prerequisite check |
| Parallel Groups (REQ-006) | Partial | 85% | DDL: pivot table pending |
| Generation Strategy (REQ-007) | Partial | 75% | Missing Activation FormRequest |
| Timetable Creation & Validation (REQ-008) | Partial | 65% | FormRequest missing; inline-only validation |
| Automated Generation Engine (REQ-009) | Partial | 55% | BUG-STT-05; async path not exclusive (GAP-017) |
| Generation Monitoring (REQ-010) | Done | 90% | None |
| Approval Workflow (REQ-011) | Not Done | 30% | Approval UI not built; no authorization |
| Publishing & Versioning (REQ-012) | Partial | 50% | Archive and parent reference incomplete |
| Post-Generation Analytics (REQ-013) | Partial | 85% | SEC-STT-02: no Gate::authorize |
| Manual Refinement (REQ-014) | Partial | 65% | FormRequests missing; no auth; pagination bug |
| Substitution Management (REQ-015) | Partial | 65% | Patterns/recommendations DDL pending; no auth |
| Standard Timetable Views (REQ-016) | Not Done | 0% | Route group empty; controllers not built |
| REST API (REQ-017) | Partial | 70% | Per-endpoint auth missing; no rate limiting |

---

## 2. Requirements Traceability Matrix (RTM)

> Traceability: FRD Requirement → Business Rule → Screen → Controller Method → Service → Test Case → KPI

| REQ ID | Requirement Name | Priority | MoSCoW | BRs Applied | Controller | Service | View / Screen | FormRequest | Test | KPI |
|--------|-----------------|:--------:|:------:|-------------|-----------|---------|---------------|------------|------|-----|
| REQ-STT-001 | Foundation Masters Setup | P0 | Must | BR-001,002,003,004 | (TTF) TtShiftController etc. | (TTF) ShiftService etc. | TTF views | (TTF) | — | KPI-STT-01 |
| REQ-STT-002 | Requirement Definition | P0 | Must | BR-005 | (TTF) ClassReqGroupController etc. | (TTF) | TTF views | (TTF) | — | — |
| REQ-STT-003 | Constraint Engine Configuration | P0 | Must | BR-006,007,008,009 | TtConstraintController, TtConstraintTypeController, TtTeacherUnavailableController, TtRoomUnavailableController | ConstraintManager, ConstraintEvaluator | constraint/*, unavailability/* | (missing) | — | — |
| REQ-STT-004 | Teacher & Room Availability | P0 | Must | BR-010,011 | (TTF) TtTeacherAvailabilityController etc. | (TTF) | TTF views | (TTF) | — | — |
| REQ-STT-005 | Activity Management | P0 | Must | BR-012,013,014 | TtActivityController, TtSubActivityController | ActivityService, ActivityScoreService | activity/* | (partial) | ClassTeacherAutoAssignerTest | KPI-STT-02 |
| REQ-STT-006 | Parallel Period Groups | P0 | Must | BR-015,016 | TtParallelGroupController | ParallelGroupService | parallel-group/* | (missing) | — | — |
| REQ-STT-007 | Generation Strategy Config | P0 | Must | — | TtGenerationStrategyController | — | generation-strategy/* | (missing activation FR) | — | — |
| REQ-STT-008 | Timetable Creation & Pre-Gen Validation | P0 | Must | BR-001,017 | TtTimetableController | ValidationService, TimetableService | timetable/create, timetable/validate | (missing) | — | — |
| REQ-STT-009 | Automated Generation | P0 | Must | BR-006..009,017,018,019 | TtTimetableGenerationController | PrimeSolver, PrimeConstraintBridge, ActivityScoreService | generation/trigger, generation/progress | (missing) | MandatoryFillAuditorTest | KPI-STT-03 |
| REQ-STT-010 | Generation Monitoring | P0 | Must | BR-017 | TtTimetableGenerationController (status methods) | — | generation/progress | — | PreplaceClassTeacherFirstSlotsTest | KPI-STT-03 |
| REQ-STT-011 | Approval Workflow | P0 | Must | BR-020 | TtTimetablePublishController (partial) | ApprovalService (not yet built) | timetable/approve (not built) | (not built) | — | KPI-STT-04 |
| REQ-STT-012 | Publishing & Versioning | P0 | Must | BR-021,022,023 | TtTimetablePublishController | PublishService | timetable/publish | (missing) | — | KPI-STT-04 |
| REQ-STT-013 | Post-Generation Analytics | P0 | Must | — | TtAnalyticsController | WorkloadAnalyticsService, UtilisationAnalyticsService | analytics/* | — | — | KPI-STT-05 |
| REQ-STT-014 | Manual Refinement | P0 | Must | BR-022,023 | TtRefinementController | RefinementService, SwapService | refinement/* | (missing) | — | — |
| REQ-STT-015 | Substitution Management | P0 | Must | BR-024,025,026 | TtSubstitutionController | SubstitutionService | substitution/* | (missing) | — | KPI-STT-06 |
| REQ-STT-016 | Standard Timetable Views | P0 | Must | BR-021 | (not built — StandardTimetable module, STA scope) | — | (not built) | — | — | KPI-STT-07 |
| REQ-STT-017 | REST API | P0 | Must | BR-021 | TtTimetableApiController (16 endpoints) | (reuses domain services) | (API JSON) | — | — | KPI-STT-08 |

### 2.1 RTM Gaps Summary

| Gap Type | Count | IDs |
|----------|------:|-----|
| Missing FormRequests | 8 | REQ-003, REQ-006, REQ-007 (activation), REQ-008, REQ-009, REQ-012, REQ-014, REQ-015 |
| Missing Controller (not built) | 1 | REQ-016 (StandardTimetable views, STA module scope) |
| Missing UI Screen | 2 | REQ-011 (approval screen), REQ-016 (standard views) |
| Missing Test Coverage | 14 | REQ-001 through REQ-010, REQ-012 through REQ-017 (only 3 test files exist) |
| Missing Service | 1 | REQ-011 (ApprovalService not built) |
| Missing Per-Endpoint Auth | 3 | REQ-013, REQ-014, REQ-015 (no Gate::authorize) |
| Missing DDL Tables | 4 | tt_parallel_group_activity (pivot), tt_analytics_daily_snapshots, tt_substitution_patterns, tt_substitution_recommendations |

---

## 3. Business Rules Register + Conditions Catalog + Validation Catalog

### 3.1 Business Rules Register

*(Full rules in FRD §4. Summarised here for cross-reference.)*

| BR ID | Category | Rule Summary | Enforcement | Status |
|-------|----------|-------------|-------------|:------:|
| BR-STT-001 | Prerequisite | Generation requires ≥1 shift, ≥5 school days, ≥1 period set with ≥6 periods, ≥1 timetable type | ValidationService | Done |
| BR-STT-002 | Calculation | Period duration = auto-calculated from start/end times; not user-editable | GENERATED STORED column | Done |
| BR-STT-003 | Validation | No two timetable types overlap in effective date range for same shift | Application-level check | Partial |
| BR-STT-004 | Priority | Class calendar override beats school calendar | Generation engine | Done |
| BR-STT-005 | Data Integrity | Requirement Consolidation: XOR reference (Group OR Subgroup, never both/neither) | DDL CHECK + application | Done |
| BR-STT-006 | Hard Constraint | Hard constraint violations cause generation failure | PrimeSolver backtracking | Partial (BUG-STT-05) |
| BR-STT-007 | Hierarchy | Constraint scope hierarchy: Global > Class > Teacher > Room > Activity | ConstraintEvaluator | Done |
| BR-STT-008 | Override | Per-instance Hard flag overrides type default | ConstraintManager | Done |
| BR-STT-009 | Automation | Unavailability record creates both display and constraint records | TeacherUnavailableController | Partial |
| BR-STT-010 | Prerequisite | Teacher availability records must exist pre-generation | ValidationService | Done |
| BR-STT-011 | Calculation | Teacher readiness flags auto-computed from dates | GENERATED STORED columns | Done |
| BR-STT-012 | Calculation | Activity total_periods = duration × weekly_periods; not user-editable | GENERATED STORED column | Done |
| BR-STT-013 | Prerequisite | Activity with sub-activities flag needs ≥1 sub-activity before generation | ValidationService | Partial |
| BR-STT-014 | Algorithm | Difficulty-first activity placement (activity scoring via 6 factors) | ActivityScoreService | Done |
| BR-STT-015 | Algorithm | Parallel group anchor defines shared slot for all members | ParallelPeriodConstraint (Hard) | Done |
| BR-STT-016 | Algorithm | Parallel group retries if anchor cannot be placed | PrimeSolver backtracking | Done |
| BR-STT-017 | Limits | Max 50,000 iterations, 25s per run, 600s job timeout | PrimeSolver / GenerateTimetableJob | Done |
| BR-STT-018 | Architecture | Generation must be async; web thread must never wait | GenerateTimetableJob dispatch | Partial (sync path present) |
| BR-STT-019 | FSM | Status: Draft→Generating→Generated→Approved→Published→Archived; only Generated→Draft reversal | TimetablePublishController | Partial |
| BR-STT-020 | Approval | Hard violations require override reason before approval | Approval UI | Not Done |
| BR-STT-021 | Permission | Only Published timetable visible to teachers/students | StandardTimetableController / API | Not Done |
| BR-STT-022 | Immutability | Published timetable immutable to swap/move; only substitutions allowed | RefinementController | Partial |
| BR-STT-023 | Audit | All cell modifications logged with type, user, timestamp, reason | ChangeLog model | Done |
| BR-STT-024 | Substitution | Substitute assigned to cell without removing original teacher record | SubstitutionService | Done |
| BR-STT-025 | Substitution | Candidate scoring: subject 40 + pattern 25 + availability 20 + workload 15 = 100 max | SubstitutionService | Done |
| BR-STT-026 | Substitution | Pattern updated via running exponential average only on completion | SubstitutionService.completeSubstitution() | Done |

### 3.2 Conditions Catalog

| COND ID | Condition Name | Expression | Entity | BR Applied |
|---------|---------------|-----------|--------|-----------|
| COND-STT-001 | Generation Prerequisites Met | shifts.count ≥ 1 AND school_days.count ≥ 5 AND period_sets.with_6_periods ≥ 1 AND timetable_types.count ≥ 1 | Timetable | BR-001 |
| COND-STT-002 | Teacher Availability Ready | teacher_availabilities.for_term.count ≥ 1 | Timetable (per term) | BR-010 |
| COND-STT-003 | Activities Exist for Term | activities.for_timetable.count ≥ 1 | Timetable | BR-001 |
| COND-STT-004 | Requirement Consolidation Valid | group_id IS NOT NULL XOR subgroup_id IS NOT NULL | RequirementConsolidation | BR-005 |
| COND-STT-005 | Activity Has Required Teacher | activity_teachers.is_required.count ≥ 1 | Activity | BR-010 |
| COND-STT-006 | Activity Sub-Activity Complete | (has_sub_activities = false) OR (sub_activities.count ≥ 1) | Activity | BR-013 |
| COND-STT-007 | Timetable Is Published | timetables.status = 'PUBLISHED' | Timetable | BR-021 |
| COND-STT-008 | Cell Is Locked | timetable_cells.is_locked = true | TimetableCell | BR-022 |
| COND-STT-009 | Constraint Is Hard | (constraint_types.is_hard = true) OR (constraints.override_as_hard = true) | Constraint | BR-006, BR-008 |
| COND-STT-010 | Substitution Has Eligible Candidate | substitution_candidates.scored.count ≥ 1 | TeacherAbsence (per cell) | BR-025 |
| COND-STT-011 | Teacher Available on Date | teacher_unavailabilities.overlapping_date.count = 0 | TeacherAvailability | BR-009 |
| COND-STT-012 | Timetable Type Dates Non-Overlapping | No two active timetable_types share shift_id AND their date ranges intersect | TimetableType | BR-003 |
| COND-STT-013 | Generation Job Within Timeout | job.wall_time ≤ strategy.timeout_seconds (default 600s) | GenerateTimetableJob | BR-017 |
| COND-STT-014 | Solver Within Iteration Limit | solver.iteration_count ≤ strategy.max_iterations (default 50,000) | PrimeSolver | BR-017 |
| COND-STT-015 | Parallel Group Anchor Placed | parallel_group.anchor_activity.cell IS NOT NULL | ParallelGroup | BR-015 |
| COND-STT-016 | Hard Violations Require Override Reason | timetable.hard_violation_count > 0 AND action = 'APPROVE' | Timetable | BR-020 |
| COND-STT-017 | Approval Override Reason Provided | approval_reason IS NOT NULL AND LENGTH(approval_reason) ≥ 10 | Approval action | BR-020 |

### 3.3 Validation Catalog

| VAL ID | Validation | Layer | Field / Input | Rule | Error Message |
|--------|-----------|-------|---------------|------|---------------|
| VAL-STT-001 | Timetable code uniqueness | DB + App | tt_timetables.code | Unique per tenant | "A timetable with this code already exists for this school year." |
| VAL-STT-002 | Timetable effective date range | App | start_date, end_date | end_date > start_date | "The end date must be after the start date." |
| VAL-STT-003 | Activity weekly periods positive | DB + App | tt_activities.weekly_periods | TINYINT UNSIGNED, min 1 | "Weekly periods must be at least 1." |
| VAL-STT-004 | Activity duration positive | DB + App | tt_activities.duration_periods | TINYINT UNSIGNED, min 1 | "Activity duration must be at least 1 period." |
| VAL-STT-005 | Constraint parameter JSON schema | App | tt_constraints.parameters | Must match constraint_type.parameter_schema structure | "Constraint parameters are invalid: [field] is required." |
| VAL-STT-006 | Timetable type effective dates non-overlapping | App | tt_timetable_types.effective_from, effective_to | No overlap for same shift_id | "A timetable type already covers this date range for the selected shift." |
| VAL-STT-007 | Requirement Consolidation XOR | DB CHECK + App | group_id, subgroup_id | One and only one must be non-null | "A requirement must be linked to either a class group or a subgroup — not both and not neither." |
| VAL-STT-008 | Period set period coverage | App | Period set composition records | from_period_ord < to_period_ord within shift's period grid | "The period set must span at least 1 period within the shift's grid." |
| VAL-STT-009 | Generation strategy max iterations | App | max_iterations | Integer 100–1,000,000 | "Maximum iterations must be between 100 and 1,000,000." |
| VAL-STT-010 | Generation strategy timeout | App | timeout_seconds | Integer 10–600 | "Timeout must be between 10 and 600 seconds." |
| VAL-STT-011 | Substitute must differ from absent teacher | App | substitute_teacher_id | substitute_teacher_id ≠ absent_teacher_id | "The substitute teacher cannot be the same as the absent teacher." |
| VAL-STT-012 | Absence date cannot be in the past (approval) | App | absence.date | date ≥ today OR system flag for retroactive | "Teacher absence cannot be approved for a date more than 7 days in the past." |
| VAL-STT-013 | Parallel group minimum size | App | group members count | ≥ 2 activities per group | "A parallel group must have at least 2 activities." |
| VAL-STT-014 | Room availability period bounds | App | tt_room_unavailabilities.from_period, to_period | from_period ≤ to_period | "The unavailability start period must be before or equal to the end period." |
| VAL-STT-015 | Teacher workload maximum not exceeded | App (soft) | weekly assignments vs. max_periods_per_week | Soft warning; not blocking | "This teacher will be assigned [N] periods, which exceeds their declared maximum of [M] periods." |
| VAL-STT-016 | Approval reason minimum length when required | App | approval_reason (hard violation override) | length ≥ 10 characters | "Please enter a reason of at least 10 characters to override hard violations." |
| VAL-STT-017 | API request authentication | API middleware | Authorization header | Sanctum token present and valid | HTTP 401 Unauthorized |
| VAL-STT-018 | Refinement on Published timetable blocked | App | Refinement action | timetable.status ≠ 'PUBLISHED' | "This timetable has been published. Refinement is not permitted. Revert to Approved status first." |
| VAL-STT-019 | Cell lock enforcement in refinement | App | source/target cell selection | source.is_locked = false AND target.is_locked = false | "Cell [position] is locked and cannot be swapped." |
| VAL-STT-020 | GENERATED column not in fillable | Application convention | Activity.total_periods, etc. | Must not appear in $fillable; DDL computes automatically | Fatal: MassAssignmentException if violated |

---

## 4. Process Flows and FSM Catalog

### 4.1 Timetable Status FSM

```
         ┌────────────────────┐
         │       DRAFT        │◄──────── Reject (from Generated) / Generation Fail
         └────────┬───────────┘◄──────── Revert (from Published/Approved)
                  │ Trigger: Generate action
                  ▼
         ┌────────────────────┐
         │     GENERATING     │  (async job running; no UI operations permitted)
         └────────┬───────────┘
                  │ Job completes successfully
                  ▼
         ┌────────────────────┐
         │     GENERATED      │  (preview + analytics available; refinement allowed)
         └────────┬───────────┘
                  │ Coordinator submits for approval
                  ▼
         ┌────────────────────┐
         │     APPROVED       │  (refinement still permitted; swap/lock allowed)
         └────────┬───────────┘
                  │ Principal approves
                  ▼
         ┌────────────────────┐
         │     PUBLISHED      │  (immutable to swap/move; substitution only)
         └────────┬───────────┘
                  │ New version published (superseded)
                  ▼
         ┌────────────────────┐
         │      ARCHIVED      │  (read-only historical record)
         └────────────────────┘
```

**State Transition Table:**

| From | To | Trigger | Actor | Conditions | BRs |
|------|----|---------|-------|-----------|-----|
| — | DRAFT | Timetable created | Coordinator | None (initial state) | BR-019 |
| DRAFT | GENERATING | Generation triggered | Coordinator | Pre-generation validation passed; COND-001, 002, 003 | BR-001, BR-017, BR-018 |
| GENERATING | GENERATED | GenerateTimetableJob completes successfully | System | All mandatory activities placed; no blocking hard violations | BR-006, BR-019 |
| GENERATING | DRAFT | GenerateTimetableJob fails or times out | System | Any unrecoverable failure | BR-006, BR-017, BR-019 |
| GENERATED | DRAFT | Manual revert (regenerate) | Coordinator | Timetable in GENERATED state | BR-019 |
| GENERATED | APPROVED | Submit for approval | Coordinator | — | BR-019 |
| APPROVED | GENERATED | Reject by Principal | Principal | Must-have permission: smart-timetable.approve | BR-019, BR-020 |
| APPROVED | PUBLISHED | Publish | Coordinator or Principal | No blocking issues; approval recorded | BR-019, BR-021 |
| PUBLISHED | ARCHIVED | New timetable published for same term | System | New timetable transitions to PUBLISHED | BR-019, BR-021 |
| APPROVED | DRAFT | Manual revert | Coordinator | — | BR-019 |

### 4.2 Substitution Flow FSM

```
         ┌────────────────────┐
         │    ABSENCE DRAFT   │  (created by Coordinator; not yet approved)
         └────────┬───────────┘
                  │ Coordinator approves absence
                  ▼
         ┌────────────────────┐
         │  ABSENCE APPROVED  │  (system generates candidate recommendations)
         └────────┬───────────┘
                  │ Coordinator assigns substitute (manual or auto)
                  ▼
         ┌────────────────────┐
         │  SUBSTITUTION      │
         │  ASSIGNED          │  (substitute notified; cell updated with is_substitute flag)
         └────────┬───────────┘
                  │ Teaching period passes; Coordinator marks complete
                  ▼
         ┌────────────────────┐
         │  SUBSTITUTION      │
         │  COMPLETED         │  (pattern record updated via exponential average)
         └────────────────────┘
                  OR
         ┌────────────────────┐
         │  SUBSTITUTION      │  (substitute cannot attend; re-assignment)
         │  CANCELLED         │──────► back to APPROVED
         └────────────────────┘
```

### 4.3 Generation Pipeline Steps

| Step | Name | What Happens | Duration Estimate |
|------|------|-------------|-------------------|
| 1 | Pre-Generation Validation | Re-validates prerequisites (activities, teachers, rooms, constraints); blocks if errors remain | 1–3s |
| 2 | Activity Scoring | ActivityScoreService computes 6-factor difficulty score for all activities; sorts hardest-first | 0.5–2s |
| 3 | Room Pre-Allocation | Matches room type requirements to available rooms; creates tentative room assignments | 0.5–2s |
| 4 | Sub-Activity Decomposition | Expands multi-period activities into ordered sub-activity chains with same-day/consecutive constraints | 0.1–0.5s |
| 5 | CSP Backtracking Solver (PrimeSolver) | Places activities into (day, period) slots; backtracks on hard constraint violations; iterates up to 50,000 times | 1–25s |
| 6 | Post-Optimisation | TabuSearchOptimizer or SimulatedAnnealingOptimizer improves soft score; configurable | 1–10s |
| 7 | Solution Evaluation | Counts hard violations, soft violations, computes overall soft score and quality metrics | 0.2–1s |
| 8 | Atomic DB Storage | All timetable cells and cell-teacher records stored in a single transaction | 0.5–5s |
| 9 | Resource Booking | Creates resource_booking records for every placed activity (room + teacher) | 0.5–3s |
| 10 | Conflict Detection | Scans placed cells for residual conflicts; populates tt_conflict_detections | 0.5–2s |

---

## 5. Data Dictionary and Cross-Module Dependency Map

### 5.1 Core Table Dictionary

*(All tables in tenant DB — `tt_*` prefix. DDL source: Timetable_DDL_v7.8.sql)*

#### Configuration

| Table | Purpose | Key Columns | Notes |
|-------|---------|-------------|-------|
| `tt_configs` | Key-value settings for generation behaviour | `key`, `value`, `value_type` | 14 built-in settings; not user-added |
| `tt_generation_strategies` | Solver algorithm parameters | `algorithm_type` (ENUM: RECURSIVE_BACKTRACKING, GENETIC, SIMULATED_ANNEALING, TABU_SEARCH, HYBRID), `max_iterations`, `timeout_seconds`, `is_active` | One active at a time |

#### Foundation Masters (owned by TimetableFoundation module; consumed by STT)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_shifts` | School shifts (Morning/Evening) | `code`, `name`, `default_start_time`, `default_end_time` |
| `tt_period_configs` | Central period timeslot master (v7.7 change) | `shift_id`, `slot_order`, `start_time`, `end_time`, `duration_minutes` (GENERATED STORED), `is_teaching_slot` |
| `tt_period_sets` | Period group templates for class categories | `shift_id`, `from_period_ord`, `to_period_ord`, `total_period_count`, `teaching_period_count` |
| `tt_period_set_periods_jnt` | Period set composition | `period_set_id`, `period_config_id`, `local_period_code`, `period_type_id`, `duration_minutes` (GENERATED STORED from period_config) |
| `tt_timetable_types` | Timetable type config per shift + date range | `code`, `name`, `shift_id`, `effective_from`, `effective_to`, `is_exam_timetable` |
| `tt_school_days` | School days of the week | `day_of_week` (1–7), `is_school_day` |
| `tt_working_days` | Calendar date-level working day config | `calendar_date`, `day_type_classifications` (up to 4), `is_school_day` |
| `tt_class_working_days_jnt` | Class-level calendar overrides | `class_id`, `date`, `is_exam_day`, `is_ptm_day`, `is_half_day`, `is_holiday` |

#### Requirement

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_class_requirement_groups` | Class+section+subject+study_format scheduling groupings | `class_id`, `section_id`, `subject_id`, `study_format_id`, `eligible_teacher_count` |
| `tt_class_requirement_subgroups` | Shared cross-section group variants | `is_cross_section`, `is_cross_class` |
| `tt_requirement_consolidations` | Master scheduling parameters per term | `group_id XOR subgroup_id`, `required_weekly_periods`, `min_per_day`, `max_per_day`, `must_be_consecutive`, `spread_evenly`, `preferred_periods`, `avoided_periods` |

#### Availability

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_teacher_availabilities` | Teacher availability summary | `teacher_id`, `weekly_max_periods`, `available_for_full_timetable_duration` (GENERATED STORED), `no_of_days_not_available` (GENERATED STORED) |
| `tt_teacher_availability_details` | Per-day-per-period teacher grid | `teacher_availability_id`, `day_of_week`, `period_order`, `status` (ENUM: Available/Unavailable/Assigned/Free_Period) |
| `tt_room_availabilities` | Room availability summary | `room_id`, `room_type_id`, `is_eligible_for_theory`, `is_eligible_for_practical` |
| `tt_room_availability_details` | Per-day-per-period room grid | `room_availability_id`, `day_of_week`, `period_order`, `status` |

#### Preparation (Activities)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_activities` | Core scheduling units | `class_id`, `section_id`, `subject_id`, `study_format_id`, `term_id`, `weekly_periods`, `duration_periods`, `total_periods` (**GENERATED STORED** = duration × weekly — must NOT be in `$fillable`), `difficulty_score`, `status` |
| `tt_sub_activities` | Sub-divisions of multi-period activities | `activity_id`, `duration_periods`, `must_be_consecutive`, `must_be_same_day` |
| `tt_activity_teachers` | Teacher-to-activity mapping | `activity_id`, `teacher_id`, `assignment_role_id`, `is_required`, `priority_order` |
| `tt_priority_configs` | Scoring factor weights | `factor_name`, `weight` |
| `tt_activity_priorities` | Computed activity priority scores | `activity_id`, `priority_score`, `reason` |

#### Parallel Groups

| Table | Purpose | Key Columns | Notes |
|-------|---------|-------------|-------|
| `tt_parallel_group_activity` | Parallel group ↔ activity pivot | `parallel_group_id`, `activity_id`, `is_anchor` | **Migration-only table — no canonical DDL entry; missing from v7.8** |

#### Core Timetable

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_timetables` | Master timetable record | `code`, `name`, `term_id`, `timetable_type_id`, `period_set_id`, `status` (FSM), `soft_score`, `published_at`, `published_by`, `parent_id` |
| `tt_generation_runs` | Per-run metadata for each generation attempt | `timetable_id`, `run_number`, `status`, `algorithm_used`, `activities_total`, `activities_placed`, `hard_violations`, `soft_violations`, `soft_score`, `error_message`, `started_at`, `completed_at` |
| `tt_timetable_cells` | Grid intersections with assigned activity | `timetable_id`, `day_of_week`, `period_order`, `class_id`, `section_id`, `activity_id`, `room_id`, `is_locked`, `source` (ENUM: Auto/Manual/Swap/Lock/Substitution), `has_conflict` |
| `tt_timetable_cell_teachers` | Teacher assignments per cell (multiple per cell) | `cell_id`, `teacher_id`, `assignment_role_id`, `is_substitute` |
| `tt_constraint_violations` | Violations from last generation run | `timetable_id`, `constraint_id`, `violation_type` (Hard/Soft), `violation_count`, `details` |
| `tt_conflict_detections` | Post-generation conflict scan | `timetable_id`, `detection_type`, `conflict_count`, `conflicts_detail`, `resolution_suggestions` |
| `tt_resource_bookings` | Resource usage bookings per period | `resource_type`, `resource_id`, `booking_date`, `period_order`, `booking_purpose` |
| `tt_change_logs` | Cell modification audit trail | `timetable_id`, `cell_id`, `change_type` (ENUM: SWAP/MOVE/LOCK/UNLOCK/ROLLBACK), `old_values`, `new_values`, `reason`, `changed_by`, `changed_at` |

#### Constraint Engine

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_constraint_types` | Catalogue of 86 constraint types (24 hard + 62 soft) | `code`, `name`, `category`, `is_hard`, `parameter_schema` (JSON schema), `scope` |
| `tt_constraints` | User-configured constraint instances | `constraint_type_id`, `scope_type`, `scope_id`, `parameters` (JSON), `override_as_hard` |
| `tt_constraint_category_scopes` | Allowed scopes per constraint category | `category`, `allowed_scopes` |
| `tt_teacher_unavailabilities` | Teacher unavailability display records | `teacher_id`, `pattern_type` (once/weekly/date-range), `day_of_week`, `from_period`, `to_period`, `from_date`, `to_date` |
| `tt_room_unavailabilities` | Room unavailability display records | `room_id`, `day_of_week`, `from_period`, `to_period`, `from_date`, `to_date` |

#### Analytics

| Table | Purpose | Key Columns | Notes |
|-------|---------|-------------|-------|
| `tt_teacher_workloads` | Per-teacher workload analytics | `timetable_id`, `teacher_id`, `assigned_periods`, `max_periods`, `min_periods`, `utilisation_pct`, `gap_periods`, `max_consecutive_periods` | In canonical DDL (Section 8) |
| `tt_analytics_daily_snapshots` | Daily trend snapshots | `timetable_id`, `snapshot_date`, `metrics_json` | **Migration-only — no canonical DDL entry** |

#### Substitution

| Table | Purpose | Key Columns | Notes |
|-------|---------|-------------|-------|
| `tt_teacher_absences` | Teacher absence records | `teacher_id`, `absence_date`, `absence_type`, `from_period`, `to_period`, `status`, `approved_by` | In canonical DDL (Section 10) |
| `tt_substitution_logs` | Substitution assignment history | `absence_id`, `cell_id`, `absent_teacher_id`, `substitute_teacher_id`, `assignment_method`, `status`, `notified_at`, `completed_at` | In canonical DDL (Section 10) |
| `tt_substitution_patterns` | Historical pattern per teacher-day-subject | `teacher_id`, `day_of_week`, `subject_id`, `success_rate`, `confidence` | **Migration-only — no canonical DDL entry** |
| `tt_substitution_recommendations` | Scored candidates per cell | `absence_id`, `cell_id`, `candidate_teacher_id`, `total_score`, `score_breakdown` | **Migration-only — no canonical DDL entry** |

### 5.2 GENERATED STORED Columns — Critical Registry

> These columns must NEVER appear in any Eloquent model's `$fillable` array. The DB computes them; if a developer adds them to `$fillable`, a MassAssignmentException or silent value override occurs (D36 platform pattern).

| Table | Column | Formula | Model |
|-------|--------|---------|-------|
| `tt_period_configs` | `duration_minutes` | `TIMESTAMPDIFF(MINUTE, start_time, end_time)` | TtPeriodConfig |
| `tt_period_set_periods_jnt` | `duration_minutes` | Derived from referenced `tt_period_configs.duration_minutes` | TtPeriodSetPeriodJnt |
| `tt_teacher_availabilities` | `available_for_full_timetable_duration` | `available_from ≤ timetable.start_date` (BOOLEAN) | TtTeacherAvailability |
| `tt_teacher_availabilities` | `no_of_days_not_available` | `DATEDIFF(available_from, timetable.start_date) where result > 0` | TtTeacherAvailability |
| `tt_activities` | `total_periods` | `duration_periods * weekly_periods` | TtActivity |

### 5.3 Migration-Only Tables (No Canonical DDL Entry)

These tables exist in migration files under `database/migrations/tenant/` but are absent from `Timetable_DDL_v7.8.sql`. Their structure must be reconciled:

| Table | Migration File Reference | Action Needed |
|-------|------------------------|---------------|
| `tt_parallel_group_activity` | STT module migrations | Add to DDL; create FK constraints to tt_timetables and tt_activities |
| `tt_analytics_daily_snapshots` | STT module migrations | Add to DDL (Section 8); define JSON column structure |
| `tt_substitution_patterns` | STT module migrations | Add to DDL (Section 10); add index on (teacher_id, day_of_week, subject_id) |
| `tt_substitution_recommendations` | STT module migrations | Add to DDL (Section 10); JSON column for score_breakdown |

### 5.4 Phantom Models (No DDL Backing)

21 model files in `Modules/SmartTimetable/Models/` reference tables with no corresponding DDL entry. Key examples:

| Model | Expected Table | Priority to Resolve |
|-------|---------------|:------------------:|
| TtWhatIfScenario | tt_what_if_scenarios | P2 (ENH-STT-003) |
| TtVersionComparison | tt_version_comparisons | P2 (ENH-STT-004) |
| TtMlModel | tt_ml_models | P2 (ENH-STT-005) |
| TtSubstitutionPattern | tt_substitution_patterns | P1 (REQ-STT-015) |
| TtSubstitutionRecommendation | tt_substitution_recommendations | P1 (REQ-STT-015) |
| TtAnalyticsDailySnapshot | tt_analytics_daily_snapshots | P1 (REQ-STT-013) |

### 5.5 Cross-Module Dependency Map

#### Upstream Dependencies (STT reads from these modules)

| Module | Tables / Data | What STT Uses It For |
|--------|--------------|---------------------|
| SchoolSetup | `sch_academic_term` | Term definition for timetable scope |
| SchoolSetup | `sch_classes`, `sch_sections`, `sch_class_section_jnt` | Class-section groupings for activities |
| SchoolSetup | `sch_subjects`, `sch_study_formats`, `sch_subject_study_format_jnt` | Subject-study format combinations for requirement definition |
| SchoolSetup | `sch_organizations`, `sch_buildings`, `sch_rooms` | Room data for availability and assignment |
| SchoolSetup | `sch_boards`, `sch_board_organization_jnt` | Board-level subject type classification |
| StudentProfile / HrStaff | Teacher profile records (via SchoolSetup bridge) | Teacher eligibility, proficiency, experience for availability and scoring |
| SmartTimetable (self) | `tt_*` tables (own schema) | — |

#### Downstream Dependencies (STT writes data; these modules read it)

| Module | Data STT Provides | How Consumed |
|--------|-------------------|-------------|
| StudentPortal | Published timetable cells via REST API | Student schedule display |
| ParentPortal | Published timetable via REST API | Parent schedule display |
| Mobile App | Published timetable + substitution alerts via REST API | Native app schedule view |
| Notification / EventEngine | Substitution assignment events; timetable published events | Push notification + SMS dispatch |
| Attendance | Published timetable cells (period-teacher mapping) | Auto-populate attendance sheet (planned integration) |

#### Shared Controllers (Cross-Module Pattern — Registered in STT Routes)

| Route Action | Controller | Actual Module Owner | Notes |
|-------------|-----------|-------------------|-------|
| ClassSubjectGroup create/update | SchoolSetup\ClassSubjectGroupController | SchoolSetup | Registered in STT web.php; pattern creates coupling. Should be moved to SchoolSetup routes (GAP-STT-06). |
| GenerationStrategy CRUD | SmartTimetable\TtGenerationStrategyController | SmartTimetable | Registered under TTF routes, not STT routes — route placement inconsistency. |

---

## 6. NFR Catalog and Risk Register

### 6.1 NFR Catalog

*(See FRD §9 for complete NFR table. Extended with implementation notes here.)*

| NFR ID | Category | Requirement | Threshold | Current State | Gap |
|--------|----------|-------------|-----------|--------------|-----|
| NFR-STT-P01 | Performance | Solver timeout | 25s per run | Implemented (GenerateTimetableJob) | None |
| NFR-STT-P02 | Performance | Total job timeout | 600s | Implemented | None |
| NFR-STT-P03 | Performance | Analytics computation | < 5s for 50-teacher school | Not benchmarked | Needs load test |
| NFR-STT-P04 | Performance | API GET response | < 200ms | Not tested | Needs load test |
| NFR-STT-P05 | Performance | Swap impact analysis | < 500ms | Not tested | Needs benchmark |
| NFR-STT-P06 | Performance | Conflict scan batch | < 2s | Not tested | Needs benchmark |
| NFR-STT-P07 | Performance | Refinement grid load (100 cells) | < 500ms | Pagination not verified | Needs fix (GAP-STT-14) |
| NFR-STT-P08 | Performance | Index page query | < 500ms | Not benchmarked | Needs index review |
| NFR-STT-S01 | Security | EnsureTenantHasModule middleware | Applied to all routes | MISSING from both route groups | CRITICAL: SEC-STT-01 |
| NFR-STT-S02 | Security | Gate::authorize on Analytics | All analytics methods | MISSING from AnalyticsController | CRITICAL: SEC-STT-02 |
| NFR-STT-S03 | Security | No Faker in production | All controllers | Faker imported in TtGenerationStrategyController | HIGH |
| NFR-STT-S04 | Security | Soft-delete only | All delete routes | Needs audit per controller | HIGH |
| NFR-STT-S05 | Security | No session storage for large data | Generation state | Timetable grid data must not be in session | HIGH |
| NFR-STT-S06 | Security | Rate limiting | Generation 5/min, API 60/min | Not implemented | MEDIUM |
| NFR-STT-S07 | Security | Error masking | No stack traces to users | Not verified | MEDIUM |
| NFR-STT-S08 | Security | Per-endpoint API auth | Teachers cannot manage | Not enforced per endpoint | MEDIUM |
| NFR-STT-U01 | Usability | Refinement pagination | 100 cells per page | Pagination bug present (GAP-STT-14) | Needs fix |
| NFR-STT-U02 | Usability | Generation auto-poll | Every 3 seconds | Implemented | None |
| NFR-STT-U03 | Usability | Dynamic constraint forms | JSON schema driven | Implemented | None |
| NFR-STT-A01 | Scalability | School scale | 40–120 teachers, 30–100 sections, up to 600 activities | Stress testing required | Needs test |

### 6.2 Risk Register

| RISK ID | Risk | Probability | Impact | Severity | Mitigation |
|---------|------|:-----------:|:------:|:--------:|-----------|
| RISK-STT-01 | BUG-STT-05: DB constraints not wired to solver. Generated timetables may violate Coordinator-configured constraints silently. | HIGH | CRITICAL | P0 | Immediate fix: restore PrimeConstraintBridge.loadFromDatabase() and ConstraintManager.createConstraintManager() DB loading path. |
| RISK-STT-02 | Standard Timetable Views (REQ-016) not built. Teachers, parents, and students cannot view their schedules after publishing. Core business function unavailable at launch. | HIGH | HIGH | P0 | Build StandardTimetable route group controllers in sprint before launch. |
| RISK-STT-03 | Approval UI (REQ-011) not built. No authorization check on approval actions. Any user could trigger approval-equivalent actions. | HIGH | HIGH | P0 | Build approval screen and add Gate::authorize('approve', $timetable) to publish controller. |
| RISK-STT-04 | SEC-STT-01: EnsureTenantHasModule middleware absent. A tenant without SmartTimetable module license can access all timetable endpoints. | HIGH | CRITICAL | P0 | Add middleware to both route groups immediately. |
| RISK-STT-05 | SEC-STT-02: No Gate::authorize in AnalyticsController. Any authenticated user can view all school timetable analytics, including teacher workload data. | HIGH | HIGH | P0 | Add Gate::authorize to every AnalyticsController method. |
| RISK-STT-06 | 4 DDL tables missing from canonical DDL (parallel_group_activity, analytics_daily_snapshots, substitution_patterns, substitution_recommendations). If migration is run in new tenant, tables exist but have no documented schema. | MEDIUM | HIGH | P1 | Add to DDL v7.9; document column structure, indexes, FKs. |
| RISK-STT-07 | BUG-STT-04: Sync generation code path not removed. If queue worker is down, generation may run synchronously and block the web request for up to 25+ seconds. | MEDIUM | HIGH | P1 | Remove sync path; ensure queue worker monitoring; add check that job was dispatched. |
| RISK-STT-08 | 21 phantom models reference tables not in DDL. Model code cannot be tested or trusted without a full DDL-migration reconciliation. | MEDIUM | MEDIUM | P1 | Three-way DDL↔migration↔model reconciliation pass (Technical Auditor Mode A). |
| RISK-STT-09 | Only 3 test files for an 86-constraint-class, 111-service-file module. Any regression in solver or constraint logic goes undetected. | HIGH | HIGH | P0 | Add Pest test suite: at minimum constraint engine, activity scoring, and generation job tests. |
| RISK-STT-10 | GAP-STT-06: SchoolSetup controller methods wired via STT routes. If SchoolSetup module changes its method signatures, STT routes silently break. | LOW | MEDIUM | P2 | Move ClassSubjectGroup routes to SchoolSetup module routes in next architecture cleanup. |
| RISK-STT-11 | Solver performance unknown at scale (120 teachers, 100 sections, 600 activities, 86 constraints). 25s timeout may be insufficient. | MEDIUM | HIGH | P1 | Load test with maximum scale school. Implement constraint class caching and index optimisation on generation tables. |
| RISK-STT-12 | Generation strategy Activation FormRequest missing. Malicious or erroneous requests can activate/deactivate strategies with no input validation. | MEDIUM | MEDIUM | P1 | Add ActivateStrategyRequest FormRequest. |
| RISK-STT-13 | iCal export scaffolded but generates empty files. If promoted as a feature, teachers and parents receive useless calendar imports. | LOW | MEDIUM | P2 | Complete iCal content generation (ENH-STT-002) or remove endpoint from documented features until done. |
| RISK-STT-14 | TenancyServiceProvider::events() has migration pipeline commented out (BUG-004, platform-wide). New tenant databases do not receive timetable tables automatically. | HIGH | CRITICAL | P0 | Platform-level fix required (not STT-specific). Track as platform blocker. |

---

## 7. MoSCoW Prioritization, Effort Estimation, and Sprint Tasks

### 7.1 MoSCoW by Requirement

| REQ ID | Feature | MoSCoW | Justification |
|--------|---------|:------:|--------------|
| REQ-STT-001 | Foundation Masters | Must | Prerequisite for everything |
| REQ-STT-002 | Requirement Definition | Must | Core scheduling input |
| REQ-STT-003 | Constraint Engine | Must | Without constraints, timetable quality is undefined |
| REQ-STT-004 | Availability Management | Must | Solver cannot run without it |
| REQ-STT-005 | Activity Management | Must | Core scheduling unit |
| REQ-STT-006 | Parallel Groups | Must | Required for multi-section shared-subject scheduling |
| REQ-STT-007 | Generation Strategy | Must | Solver requires at least 1 active strategy |
| REQ-STT-008 | Timetable Creation & Validation | Must | Timetable lifecycle starts here |
| REQ-STT-009 | Automated Generation | Must | Core value proposition |
| REQ-STT-010 | Generation Monitoring | Must | Without it, generation is a black box |
| REQ-STT-011 | Approval Workflow | Must | Required governance before publishing |
| REQ-STT-012 | Publishing & Versioning | Must | Cannot share timetable without publishing |
| REQ-STT-013 | Analytics | Must | Schools need workload visibility |
| REQ-STT-014 | Manual Refinement | Must | AI generation rarely perfect; refinement is required |
| REQ-STT-015 | Substitution Management | Must | Daily operational requirement; cannot run school without it |
| REQ-STT-016 | Standard Timetable Views | Must | Teachers and parents must be able to view timetable |
| REQ-STT-017 | REST API | Must | Required for portal integrations |
| ENH-STT-001 | PDF Export | Should | Strong school demand; print timetables |
| ENH-STT-002 | iCal Export (complete) | Should | Modern expectation; calendar sync |
| ENH-STT-003 | What-If Scenario | Could | Planning tool; valuable but not blocking |
| ENH-STT-004 | Version Comparison | Could | Useful for Principal review; not blocking |
| ENH-STT-005 | ML Substitution | Could | Future value; infrastructure exists |
| ENH-STT-006 | Genetic Algorithm | Could | Minor optimisation; backtracking sufficient for most schools |

### 7.2 Effort Estimation (Remediation — Gap Closure Only)

All estimates are for a single mid-senior Laravel developer. Estimates include coding, unit test writing, and code review time.

| Task Group | Gap / Feature | Priority | Hours |
|-----------|---------------|:--------:|------:|
| **CRITICAL SECURITY FIXES** | | | |
| SEC-01 | Add EnsureTenantHasModule to both route groups | P0 | 2 |
| SEC-02 | Add Gate::authorize to AnalyticsController (all methods) | P0 | 4 |
| SEC-03 | Add Gate::authorize to RefinementController (all methods) | P0 | 4 |
| SEC-04 | Add Gate::authorize to SubstitutionController (all methods) | P0 | 4 |
| SEC-05 | Remove Faker import from TtGenerationStrategyController | P0 | 1 |
| SEC-06 | Add rate limiting to generation trigger and API endpoints | P1 | 4 |
| **Subtotal Security** | | | **19** |
| **CRITICAL FUNCTIONAL GAPS** | | | |
| BUG-05 | Fix PrimeConstraintBridge.loadFromDatabase() + ConstraintManager DB loading | P0 | 24 |
| BUG-04 | Remove sync generation code path; enforce async-only | P0 | 4 |
| REQ-011 | Build Approval UI (screen + controller methods + ApprovalService + Policy gate) | P0 | 20 |
| REQ-016 | Build Standard Timetable Views (class/teacher/room grid views + controller) | P0 | 16 |
| **Subtotal Critical Functional** | | | **64** |
| **FORMREQUEST & VALIDATION GAPS** | | | |
| FR-01 | Add FormRequests for Constraint CRUD (StoreConstraintRequest, UpdateConstraintRequest) | P1 | 4 |
| FR-02 | Add FormRequest for Parallel Group (StoreParallelGroupRequest) | P1 | 2 |
| FR-03 | Add FormRequest for Generation Strategy Activation | P1 | 2 |
| FR-04 | Add FormRequests for Timetable create/update | P1 | 3 |
| FR-05 | Add FormRequests for Substitution (StoreAbsenceRequest, AssignSubstituteRequest) | P1 | 3 |
| FR-06 | Add FormRequests for Refinement (SwapRequest, MoveRequest) | P1 | 2 |
| **Subtotal FormRequests** | | | **16** |
| **DDL & DATA MODEL GAPS** | | | |
| DDL-01 | Add 4 missing tables to DDL v7.9 (parallel_group_activity, analytics_daily_snapshots, substitution_patterns, substitution_recommendations) | P1 | 8 |
| DDL-02 | Three-way reconciliation: DDL ↔ migration ↔ model for all 21 phantom models | P1 | 12 |
| **Subtotal DDL / Model** | | | **20** |
| **TESTING GAPS** | | | |
| TEST-01 | Constraint Engine unit tests (hard constraint suite, soft constraint suite) | P0 | 16 |
| TEST-02 | Generation pipeline integration test | P0 | 8 |
| TEST-03 | Substitution candidate scoring unit test | P1 | 4 |
| TEST-04 | Activity scoring unit test | P1 | 4 |
| TEST-05 | API endpoint feature tests (16 endpoints) | P1 | 8 |
| TEST-06 | Approval and publish workflow feature tests | P1 | 6 |
| TEST-07 | Refinement (swap/lock) feature tests | P1 | 6 |
| TEST-08 | Standard Views feature tests | P1 | 4 |
| **Subtotal Testing** | | | **56** |
| **PARTIAL IMPLEMENTATIONS** | | | |
| PART-01 | Complete publishing versioning (archive previous, parent reference) | P0 | 6 |
| PART-02 | Verify/fix teacher unavailability → constraint record creation (BR-009) | P1 | 4 |
| PART-03 | Verify/fix timetable type date overlap check (BR-003) | P1 | 3 |
| PART-04 | Fix refinement grid pagination bug (GAP-STT-14) | P1 | 4 |
| **Subtotal Partial** | | | **17** |
| **TOTAL (Remediation)** | | | **192** |

| Enhancement | Priority | Hours |
|-------------|:--------:|------:|
| ENH-STT-001: PDF Export | Should | 12 |
| ENH-STT-002: iCal Export (complete) | Should | 8 |
| ENH-STT-003: What-If Scenario | Could | 24 |
| ENH-STT-004: Version Comparison | Could | 16 |
| ENH-STT-005: ML Substitution | Could | 40 |
| ENH-STT-006: Genetic Algorithm | Could | 16 |
| **Total Enhancements** | | **116** |

### 7.3 Sprint Task Plan (Core Remediation — 5 Sprints × 2 Weeks)

#### Sprint 1 — Security Hardening + Constraint Fix (40 hrs)
*Goal: The module is safe to use in production for authorised tenants.*

| Task ID | Task | Hours | Requirement |
|---------|------|------:|------------|
| TASK-STT-001 | Add EnsureTenantHasModule to both route groups in web.php | 2 | SEC-01 |
| TASK-STT-002 | Add Gate::authorize to AnalyticsController (all 8 methods) | 4 | SEC-02 |
| TASK-STT-003 | Add Gate::authorize to RefinementController (all swap/move/lock methods) | 4 | SEC-03 |
| TASK-STT-004 | Add Gate::authorize to SubstitutionController (all methods) | 4 | SEC-04 |
| TASK-STT-005 | Remove Faker import from TtGenerationStrategyController | 1 | SEC-05 |
| TASK-STT-006 | Fix PrimeConstraintBridge: restore loadFromDatabase() call chain | 12 | BUG-05 |
| TASK-STT-007 | Fix ConstraintManager: restore createConstraintManager() DB query block | 8 | BUG-05 |
| TASK-STT-008 | Remove sync generation path from GenerationController | 2 | BUG-04 |
| TASK-STT-009 | Write unit tests for hard constraint enforcement (minimum 5 constraint classes) | 3 | TEST-01 |
| **Sprint 1 Total** | | **40** | |

#### Sprint 2 — Approval Workflow + Publishing Completion (40 hrs)
*Goal: Full Approval → Published lifecycle works end-to-end.*

| Task ID | Task | Hours | Requirement |
|---------|------|------:|------------|
| TASK-STT-010 | Design and build ApprovalService (submit, approve, reject actions + reason enforcement) | 8 | REQ-011 |
| TASK-STT-011 | Build approval screen (timetable/approve.blade.php): grid + analytics + hard violation warning modal | 8 | REQ-011 |
| TASK-STT-012 | Add approval actions to TtTimetablePublishController with Gate::authorize | 4 | REQ-011 |
| TASK-STT-013 | Complete publishing: archive previous Published, set parent reference | 6 | REQ-012 |
| TASK-STT-014 | Add publish FormRequest (StorePublishRequest) | 2 | REQ-012 |
| TASK-STT-015 | Write Pest feature tests: approve workflow (approve, reject, override reason) | 6 | TEST-06 |
| TASK-STT-016 | Write Pest feature tests: publish + archive (previous superseded) | 6 | TEST-06 |
| **Sprint 2 Total** | | **40** | |

#### Sprint 3 — Standard Timetable Views + FormRequest Completeness (40 hrs)
*Goal: Teachers, parents, and students can view the published timetable.*

| Task ID | Task | Hours | Requirement |
|---------|------|------:|------------|
| TASK-STT-017 | Build StandardTimetableController (class-view, teacher-view, room-view actions) | 6 | REQ-016 |
| TASK-STT-018 | Build view templates (class-timetable.blade.php, teacher-timetable.blade.php, room-timetable.blade.php) using existing grid partial | 6 | REQ-016 |
| TASK-STT-019 | Register StandardTimetable routes in tenant.php (standard-timetable group with auth+verified+EnsureTenantHasModule) | 2 | REQ-016 |
| TASK-STT-020 | Enforce Published-only display logic in StandardTimetableController | 2 | BR-021 |
| TASK-STT-021 | Add FormRequests: StoreConstraintRequest, UpdateConstraintRequest | 4 | REQ-003 |
| TASK-STT-022 | Add FormRequests: StoreParallelGroupRequest | 2 | REQ-006 |
| TASK-STT-023 | Add FormRequests: ActivateStrategyRequest | 2 | REQ-007 |
| TASK-STT-024 | Add FormRequests: StoreTimetableRequest, UpdateTimetableRequest | 3 | REQ-008 |
| TASK-STT-025 | Fix refinement grid pagination bug (set explicit per-page limit; test with 500 cells) | 4 | REQ-014 |
| TASK-STT-026 | Write Pest feature tests: standard views (class/teacher/room, Published-only filter) | 4 | TEST-08 |
| TASK-STT-027 | Verify teacher unavailability → backing constraint record creation (BR-009) | 2 | BR-009 |
| TASK-STT-028 | Verify and fix timetable type date overlap check (BR-003) | 3 | BR-003 |
| **Sprint 3 Total** | | **40** | |

#### Sprint 4 — DDL Reconciliation + Substitution Completion + API Auth (40 hrs)
*Goal: DDL and models are consistent; substitution is fully functional; API has per-endpoint auth.*

| Task ID | Task | Hours | Requirement |
|---------|------|------:|------------|
| TASK-STT-029 | Add 4 missing tables to DDL v7.9 with indexes and FK constraints | 8 | DDL-01 |
| TASK-STT-030 | Three-way DDL↔migration↔model reconciliation for 21 phantom models (document and resolve each) | 12 | DDL-02 |
| TASK-STT-031 | Add SubstitutionFormRequests: StoreAbsenceRequest, AssignSubstituteRequest | 3 | REQ-015 |
| TASK-STT-032 | Wire tt_substitution_patterns table update in SubstitutionService.completeSubstitution() | 4 | REQ-015, BR-026 |
| TASK-STT-033 | Add per-endpoint authorisation to TtTimetableApiController (16 endpoints) | 6 | REQ-017, NFR-STT-S08 |
| TASK-STT-034 | Add rate limiting: generation 5/min, API 60/min | 4 | NFR-STT-S06 |
| TASK-STT-035 | Write Pest feature tests: substitution flow (absence → candidates → assign → complete) | 3 | TEST-03 |
| **Sprint 4 Total** | | **40** | |

#### Sprint 5 — Test Coverage + Performance + Enhancements (40 hrs)
*Goal: Minimum viable test suite; performance benchmarks pass; two enhancements complete.*

| Task ID | Task | Hours | Requirement |
|---------|------|------:|------------|
| TASK-STT-036 | Generation pipeline integration test (stub queue, verify 10 steps) | 8 | TEST-02 |
| TASK-STT-037 | Constraint Engine unit tests (remaining 19 of 24 hard constraint classes) | 8 | TEST-01 |
| TASK-STT-038 | API feature tests (all 16 endpoints; auth, filter, response shape) | 8 | TEST-05 |
| TASK-STT-039 | Refinement (swap/lock) feature tests | 6 | TEST-07 |
| TASK-STT-040 | Performance benchmark: analytics, API, swap impact (all NFR thresholds) | 4 | NFR-STT-P* |
| TASK-STT-041 | ENH-STT-001: PDF export for class/teacher/room views (DomPDF, pattern from HPC) | 6 | ENH-001 |
| **Sprint 5 Total** | | **40** | |

**Total Sprint Hours: 200 (core gaps: 192 + 8 hrs PDF enhancement)**
**Total Enhancement Hours (remaining, post-sprint 5): 110 hrs (iCal + what-if + version compare + ML + genetic)**

---

## 8. User Stories and KPI Catalog

### 8.1 User Stories

#### Timetable Coordinator

| US ID | Story | Acceptance Criteria | REQ | Priority |
|-------|-------|--------------------|----|:--------:|
| US-STT-001 | As a Timetable Coordinator, I want to define the school's shifts, period timeslots, and period sets so that the scheduler knows when classes can be held. | GIVEN I navigate to Foundation Masters, WHEN I create a shift with name, code, and time, THEN it appears in the generation prerequisites check and I can add period configs to it. | REQ-001 | Must |
| US-STT-002 | As a Timetable Coordinator, I want to auto-generate all teacher availability records from requirement data so that I do not have to create them manually for every teacher. | GIVEN activities exist for the term, WHEN I click "Generate Availability Records", THEN availability records are created for all eligible teachers and I see a count of records created. | REQ-004 | Must |
| US-STT-003 | As a Timetable Coordinator, I want to auto-generate activities for all class sections from requirement consolidation so that I can start the generation process quickly. | GIVEN requirement consolidation records exist, WHEN I click "Generate Activities", THEN activity records with correct weekly periods and difficulty scores are created for each class section. | REQ-005 | Must |
| US-STT-004 | As a Timetable Coordinator, I want the system to validate prerequisites before generation and show me specific errors so that I know exactly what to fix before triggering the solver. | GIVEN some teachers have no availability records, WHEN I run pre-generation validation, THEN I see a tabbed report listing "Teacher [Name]: no availability record" as a blocking error. | REQ-008 | Must |
| US-STT-005 | As a Timetable Coordinator, I want to trigger automated timetable generation and see real-time progress so that I know the system is working and can estimate completion time. | GIVEN I click "Generate", WHEN the job is dispatched, THEN the progress screen shows "Activities placed: X / Y" and updates every 3 seconds without a page reload. | REQ-009, REQ-010 | Must |
| US-STT-006 | As a Timetable Coordinator, I want to swap two timetable cells so that I can fix scheduling clashes or teacher preferences that the algorithm did not account for. | GIVEN I am on the Refinement grid, WHEN I click a source cell then a target cell and confirm the swap, THEN both cells update and the change is recorded in the audit log. | REQ-014 | Must |
| US-STT-007 | As a Timetable Coordinator, I want to lock a timetable cell so that subsequent refinements cannot accidentally change it. | GIVEN I am on the Refinement grid, WHEN I lock a cell, THEN it is visually marked as locked and any swap targeting it is rejected with an error. | REQ-014 | Must |
| US-STT-008 | As a Timetable Coordinator, I want to record a teacher absence and get ranked substitute candidates so that I can assign a substitute within minutes of learning of the absence. | GIVEN I record and approve Teacher A's absence, WHEN I open the candidate list, THEN I see teachers ranked by score (subject match + pattern + availability + workload) with the score breakdown visible. | REQ-015 | Must |
| US-STT-009 | As a Timetable Coordinator, I want to publish an approved timetable so that teachers, parents, and students can see it immediately. | GIVEN the timetable is in Approved status, WHEN I click "Publish", THEN its status changes to Published, the previous Published timetable is archived, and the standard views show the new timetable. | REQ-012 | Must |
| US-STT-010 | As a Timetable Coordinator, I want to export teacher workload analytics as a CSV so that I can share it with the Principal without giving them system access. | GIVEN the analytics have been computed, WHEN I click "Export CSV" on the Teacher Workload page, THEN a CSV file downloads with one row per teacher and columns for assigned periods, utilisation %, and gaps. | REQ-013 | Must |
| US-STT-011 | As a Timetable Coordinator, I want to define teacher unavailability so that the solver does not schedule them during those slots. | GIVEN I record Teacher B's unavailability on Tuesdays 3rd–5th period, WHEN generation runs, THEN Teacher B has no assignments in those slots. | REQ-003 | Must |
| US-STT-012 | As a Timetable Coordinator, I want to create a parallel group so that all sections taking elective subjects are scheduled at the same time. | GIVEN I create a parallel group with Class 9A-French, 9B-French, 9C-German as members, WHEN generation runs, THEN all three activities share the same day and period. | REQ-006 | Must |

#### School Principal

| US ID | Story | Acceptance Criteria | REQ | Priority |
|-------|-------|--------------------|----|:--------:|
| US-STT-013 | As a Principal, I want to review the generated timetable and see its constraint violation count before approving so that I can make an informed approval decision. | GIVEN a timetable is in Generated status, WHEN I open the approval screen, THEN I see the full grid, hard violation count, soft score, and teacher workload summary. | REQ-011 | Must |
| US-STT-014 | As a Principal, I want to be required to enter a reason when approving a timetable with hard violations so that there is an audit record of my override decision. | GIVEN the timetable has 2 hard violations, WHEN I click Approve without entering a reason, THEN the system blocks the action and shows "Please enter a reason of at least 10 characters to override hard violations." | REQ-011, BR-020 | Must |
| US-STT-015 | As a Principal, I want to view the teacher workload analytics after generation so that I can ensure no teacher is overloaded before approving. | GIVEN the timetable is Generated, WHEN I open analytics, THEN I see each teacher's utilisation % and the system flags any teacher over their maximum. | REQ-013 | Must |

#### Teacher (Read-Only)

| US ID | Story | Acceptance Criteria | REQ | Priority |
|-------|-------|--------------------|----|:--------:|
| US-STT-016 | As a Teacher, I want to view my own weekly timetable online so that I know when and where I am teaching each period. | GIVEN the timetable is Published, WHEN I navigate to My Timetable, THEN I see a weekly grid with my subject, class section, and room for each period I am assigned. | REQ-016 | Must |
| US-STT-017 | As a Teacher, I want to receive a notification when I am assigned as a substitute so that I can prepare for the class. | GIVEN I am assigned as substitute for Period 4 on Monday, WHEN the assignment is confirmed, THEN I receive an in-app and SMS notification saying "You have been assigned to substitute for [Subject] — [Class Section] on [Date] Period [N]." | REQ-015, BR-024 | Must |

#### Parent / Student

| US ID | Story | Acceptance Criteria | REQ | Priority |
|-------|-------|--------------------|----|:--------:|
| US-STT-018 | As a Parent, I want to view my child's published timetable via the parent portal so that I know their schedule. | GIVEN the timetable is Published, WHEN I access the parent portal for my child's class, THEN I see the published weekly grid for their class section with subject, teacher name, and room. | REQ-016, REQ-017 | Must |
| US-STT-019 | As a Student, I want to access my class timetable via the REST API from the mobile app so that I can see my schedule when offline (cached). | GIVEN I am authenticated via Sanctum, WHEN I call GET /api/v1/timetable/latest?class_id=X&section_id=Y, THEN the API returns the published timetable cells for my class in JSON format. | REQ-017 | Must |

### 8.2 KPI Catalog

| KPI ID | KPI Name | Formula | Target | Data Source | Owner |
|--------|---------|---------|--------|------------|-------|
| KPI-STT-01 | Prerequisite Setup Completion Rate | (Schools with all prerequisites set / Active schools) × 100 | ≥ 95% before term start | tt_configs, tt_period_sets, tt_timetable_types count per tenant | Timetable Coordinator |
| KPI-STT-02 | Activity Auto-Generation Success Rate | (Activities auto-generated without error / Total activities required) × 100 | ≥ 98% | tt_activities.status ≠ ERROR / tt_requirement_consolidations.count | Timetable Coordinator |
| KPI-STT-03 | Generation Success Rate | (Successful generation runs / Total generation runs) × 100 | ≥ 85% | tt_generation_runs: status = COMPLETED / total | Timetable Coordinator |
| KPI-STT-04 | Activities Placed Rate (per generation) | (activities_placed / activities_total) × 100 per generation run | ≥ 95% | tt_generation_runs.activities_placed / activities_total | Timetable Coordinator |
| KPI-STT-05 | Hard Violations in Approved Timetable | Count of hard violations in any Approved timetable | 0 (target: approve only zero-violation timetables) | tt_constraint_violations WHERE violation_type = 'Hard' | Principal |
| KPI-STT-06 | Teacher Workload Utilisation (per teacher) | (assigned_periods / max_periods_per_week) × 100 | 80%–100% for all teachers | tt_teacher_workloads.utilisation_pct | Principal |
| KPI-STT-07 | Room Utilisation Rate | (assigned_slots / total_available_slots) × 100 | ≥ 70% for specialist rooms; ≥ 80% for general classrooms | tt_teacher_workloads (room variant), tt_room_availabilities | Timetable Coordinator |
| KPI-STT-08 | Substitution Fill Rate | (Absences with a substitute assigned / Total approved absences) × 100 | ≥ 95% | tt_substitution_logs.status = ASSIGNED / tt_teacher_absences.status = APPROVED | Timetable Coordinator |
| KPI-STT-09 | Substitution Assignment Time | Average minutes from absence approval to substitute assignment | ≤ 30 minutes | tt_substitution_logs: approved_at → notified_at | Timetable Coordinator |
| KPI-STT-10 | API Availability | (Successful API responses / Total API requests) × 100 | ≥ 99.5% | API access logs (nginx or Laravel Telescope) | System Admin |
| KPI-STT-11 | Timetable Cycle Time | Days from first draft created to timetable published per term | ≤ 3 days | tt_timetables: created_at → published_at | Principal |
| KPI-STT-12 | Constraint Satisfaction Score | Soft score at Published (lower = better) | < 100 per timetable for a 50-class school | tt_timetables.soft_score | Timetable Coordinator |

---

*Complete Analysis Pack generated by: pa-business-analyst agent | 2026-06-30*
*Companion document: STT_FRD_2026-06-30.md (10-section FRD with full business-language requirements)*
*Sources: DDL v7.8, V2 Requirement v2.0 (2026-03-26), 7 V1 screen spec files, live code scan (Modules/SmartTimetable), STT_SmartTimetable.md v1.0*
*Recommended next steps: Technical Auditor Mode X (Complete Audit) for STT; Status Analyzer scoring (6-dimension) for updated completion %*
