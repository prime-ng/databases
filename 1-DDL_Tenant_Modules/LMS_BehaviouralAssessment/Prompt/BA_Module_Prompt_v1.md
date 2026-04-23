# BA — Behavioural Assessment Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **BA (BehaviouralAssessment)** module using `BehaviouralAssessment_v1.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `BA_FeatureSpec.md` — Feature Specification
2. `BA_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `BA_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**v1 Note:** New module. Table prefix: `ba_*` (16 tables). Covers behavioural category/criteria definition, teacher assessments, incident logging, score computation, and report card integration.

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = BA
MODULE            = BehaviouralAssessment
MODULE_DIR        = Modules/BehaviouralAssessment/
BRANCH            = behavioural-assessment
RBS_MODULE_CODE   = T                              # Tenant module
DB_TABLE_PREFIX   = ba_                             # Single prefix
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/2-In-Progress/BehaviouralAssessment/Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = /Users/bkwork/WorkFolder/3-Local_Workspace/8-Requirement/BehaviouralAssessment_v1.md

FEATURE_FILE      = BA_FeatureSpec.md
DDL_FILE_NAME     = BA_DDL_v1.sql
DEV_PLAN_FILE     = BA_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — BA (BEHAVIOURAL ASSESSMENT) MODULE

### What This Module Does

BehaviouralAssessment is the **student behavioural competency tracking and assessment engine** for Prime-AI. It is a single Laravel module (`Modules\BehaviouralAssessment`) enabling Indian K-12 schools to systematically define, track, assess, and report on student behavioural competencies across the academic lifecycle.

**Core Capabilities:**
- **Category & Criteria Management** — Schools define behavioural categories (e.g., Classroom Engagement, Respect & Responsibility) with specific observable criteria within each. 9 default categories (5 Positive + 4 Negative) with 60+ criteria seeded at onboarding
- **Rating Scale Configuration** — Configurable rating scales (e.g., 5-point: Outstanding/Very Good/Good/Needs Improvement/Unsatisfactory) with numeric values and grade mapping
- **Assessment Workflow** — Class/subject teachers record per-student, per-criterion ratings via grid interface during defined assessment periods, with Draft → Submitted → Reviewed → Locked status workflow
- **Incident Logging** — Teachers log individual positive/negative behavioural events at any time with severity, evidence, witnesses, intervention, and follow-up tracking
- **Score Computation** — Weighted aggregation at criterion → category → overall level with configurable weights, multi-teacher averaging, and grade mapping
- **Report Card Integration** — Optional weighted contribution of behavioural score to final academic result (configurable 5–20% weightage)
- **Reporting & Analytics** — Student reports, class heatmaps, school-level trends, incident frequency analysis, and parent portal views

### Architecture Decisions
- **Single Laravel module** (`Modules\BehaviouralAssessment`) — self-contained tenant module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `behavioural-assessment/` | Route name prefix: `behavioural-assessment.`
- Result integration: loose coupling via `BehaviouralScoreService` — Exam/Result module calls service to pull behavioural scores. BA module never writes to `exm_*` tables directly
- Assessment-teacher assignment: derives from existing class-teacher and subject-teacher assignments in SchoolSetup — **NO separate teacher assignment table** in BA module
- Multi-teacher averaging: when multiple teachers assess the same student on the same criterion, the system averages their ratings automatically
- Incident immutability: once submitted, incidents cannot be edited — only follow-up notes can be appended

### Module Scale
| Artifact | Count |
|---|---|
| Controllers | ~11 |
| Models | 16 |
| Services | 5 |
| FormRequests | ~17 |
| Policies | ~9 |
| Livewire Components | 9 |
| ba_* tables | **16** |
| Blade views (estimated) | ~55 |

### Complete Table Inventory

**ba_* Tables (16):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `ba_rating_scales` | Configuration | — |
| 2 | `ba_rating_levels` | Configuration | FK → ba_rating_scales |
| 3 | `ba_categories` | Configuration | Self-ref parent_id; ENUM polarity |
| 4 | `ba_criteria` | Configuration | FK → ba_categories |
| 5 | `ba_class_group_category_jnt` | Configuration | Junction: class groups ↔ categories |
| 6 | `ba_assessment_periods` | Assessment | FK → academic_sessions; nullable exam_term FK |
| 7 | `ba_assessments` | Assessment | UNIQUE (teacher_id, class_section_id, period_id) |
| 8 | `ba_assessment_ratings` | Assessment | UNIQUE (assessment_id, student_id, criterion_id) — core fact table |
| 9 | `ba_student_remarks` | Assessment | FK → ba_assessments, students |
| 10 | `ba_computed_scores` | Computation | UNIQUE (student_id, category_id, period_id) — cached scores |
| 11 | `ba_incidents` | Incident | FK → students, staff, ba_categories, ba_criteria |
| 12 | `ba_incident_witnesses_jnt` | Incident | Junction: incidents ↔ witnesses (student/staff) |
| 13 | `ba_interventions` | Master Data | Predefined intervention types |
| 14 | `ba_incident_intervention_jnt` | Incident | Junction: incidents ↔ interventions |
| 15 | `ba_config` | Configuration | UNIQUE (academic_session_id) — one config per session |
| 16 | `ba_audit_log` | Audit | Rating change audit trail |

**Existing Tables REUSED (BA reads from; never modifies schema):**
| Table | Source | BA Usage |
|---|---|---|
| `std_students` | StudentProfile | Student master — base record for assessments & incidents |
| `sch_class_sections` / `sch_class_section_jnt` | SchoolSetup | Class-section assignments for assessment scope |
| `sch_classes` / `sch_class_groups` | SchoolSetup | Class group mapping for category applicability |
| `sch_employees` | SchoolSetup | Teacher/staff reference for assessments & incident reporting |
| `sch_academic_sessions` | SchoolSetup | Session scoping for periods and config |
| `exm_exam_terms` | LmsExam | Optional link for assessment period alignment |
| `sys_activity_logs` | System | Audit trail (write-only) |
| `ntf_notifications` | Notification | Incident alerts, assessment publication notifications |

### Cross-Module Integration (Result Integration)
```
When ba_config.is_result_integration_enabled = true:

  BehaviouralScoreService::getStudentScore(studentId, periodId)
    → Returns { numeric_score, grade, category_scores[] }
    → Consumed by Exam/Result module during report card generation

  Final Result = (Academic Score × (1 - weightage)) + (Behavioural Score normalised to 100 × weightage)

  Example (10% weightage):
    Final Result = (Academic Score × 0.90) + (Normalised Behavioural Score × 0.10)

Note: BA module exposes the service. Exam/Result module calls it during report generation.
BA module never writes to exm_* tables.
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — BA v1 requirement (Sections 1–13)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: std_students, sch_class_sections,
   sch_class_section_jnt, sch_classes, sch_class_groups, sch_employees, sch_academic_sessions,
   exm_exam_terms (use exact column names in spec)

### Phase 1 Task — Generate `BA_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix, module type
- In-scope items (verbatim from req v1 Section 1.2)
- Out-of-scope items (derive from context — e.g., no attendance integration, no counsellor module, no POCSO reporting)
- Module scale table (controller / model / service / FormRequest / policy / Livewire component / table counts)

#### Section 2 — Entity Inventory (All 16 Tables)
For each ba_* table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus any other frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Rating Configuration** (ba_rating_scales, ba_rating_levels)
- **Category & Criteria** (ba_categories, ba_criteria, ba_class_group_category_jnt)
- **Assessment Periods** (ba_assessment_periods)
- **Assessment Entry** (ba_assessments, ba_assessment_ratings, ba_student_remarks)
- **Score Computation** (ba_computed_scores)
- **Incidents** (ba_incidents, ba_incident_witnesses_jnt, ba_interventions, ba_incident_intervention_jnt)
- **Configuration** (ba_config)
- **Audit** (ba_audit_log)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 16 tables grouped by domain.
Use `→` for FK direction (child → parent).
Include cross-module FKs to std_*, sch_*, exm_* tables.

#### Section 4 — Business Rules (20 rules)
For each rule, state:
- Rule ID (BR-BA-001 to BR-BA-020)
- Rule text (derived from req v1 Sections 4, 5, 6)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event`

Critical rules to emphasise:
- BR-BA-001: Rating entry unique per (assessment_id, student_id, criterion_id) — DB constraint
- BR-BA-002: One assessment record per teacher per class-section per period — DB constraint
- BR-BA-003: Locked assessment period prevents ALL edits — service-layer guard, not DB-only
- BR-BA-004: Multi-teacher ratings averaged when computing criterion score — service_layer
- BR-BA-005: Category score = weighted average of criterion scores — service_layer
- BR-BA-006: Overall behavioural score = weighted average of category scores — service_layer
- BR-BA-007: Result integration formula: Final = (Academic × (1-w)) + (Behavioural_normalised × w) — service_layer
- BR-BA-008: Incidents immutable once submitted — only follow-up notes appendable — service_layer
- BR-BA-009: All rating changes logged in ba_audit_log (old_value, new_value, changed_by, changed_at) — model_event
- BR-BA-010: Class teachers assess ALL categories; subject teachers assess ONLY mapped categories — service_layer
- BR-BA-011: Config unique per academic_session_id — DB constraint
- BR-BA-012: Computed scores unique per (student_id, category_id, period_id) — DB constraint
- BR-BA-013: Default seed data provisioned during tenant onboarding — seeder
- BR-BA-014: Assessment grid auto-saves draft every 30 seconds — frontend
- BR-BA-015: Parent notification threshold configurable (e.g., only for severity ≥ moderate) — service_layer + ba_config
- BR-BA-016: Grade boundaries configurable per rating scale — service_layer
- BR-BA-017: Category weights within a group must be configurable — service_layer
- BR-BA-018: Assessment period can optionally link to exam term or remain independent — form_validation
- BR-BA-019: Criterion polarity (Positive/Negative) determines scoring direction — service_layer
- BR-BA-020: Soft delete on all major entities; audit columns (created_by, updated_by) on all tables — db_constraint

#### Section 5 — Workflow State Machines (2 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, score computation triggers)

FSMs to document:
1. **Assessment Workflow** — `draft → submitted → reviewed → locked`
   Pre-conditions before SUBMITTED: all required criterion ratings filled for all students
   On SUBMITTED: notification to Principal/HOD for review
   On REVIEWED (approved): `AssessmentApproved` event, triggers score recomputation
   On REVIEWED (sent back): status reverts to `draft`, notification to teacher with remarks
   On LOCKED: no further edits allowed; scores finalised for report card consumption

2. **Assessment Period Lifecycle** — `open → closed → locked`
   OPEN: teachers can enter/edit assessments
   CLOSED: deadline passed, no new assessments; existing submitted assessments can still be reviewed
   LOCKED: all assessments finalised, scores computed and cached, available for report card

#### Section 6 — Functional Requirements Summary (~15 FRs)
For each FR-BA-001 to FR-BA-015:
| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Derive FRs from req v1 Section 4:
- FR-BA-001: Rating Scale Configuration (4.1.1)
- FR-BA-002: Category & Criteria Management (4.1.2)
- FR-BA-003: Assessment Period Configuration (4.1.3)
- FR-BA-004: Result Integration Configuration (4.1.4)
- FR-BA-005: Teacher-Class Assignment Resolution (4.2.1)
- FR-BA-006: Rating Entry / Assessment Grid (4.2.2)
- FR-BA-007: Incident Logging (4.2.3)
- FR-BA-008: Assessment Review & Approval (4.3)
- FR-BA-009: Per-Student Score Calculation (4.4.1)
- FR-BA-010: Grade Mapping (4.4.2)
- FR-BA-011: Result Integration Computation (4.4.3)
- FR-BA-012: Student Behavioural Report (4.5.1)
- FR-BA-013: Class-Level Dashboard (4.5.2)
- FR-BA-014: School-Level Analytics (4.5.3)
- FR-BA-015: Parent Portal View (4.5.4)

#### Section 7 — Permission Matrix
| Permission String | Super Admin | Principal | HOD/Coordinator | Class Teacher | Subject Teacher | Parent | Student |
|---|---|---|---|---|---|---|---|

Include:
- `ba.config.*` — configuration permissions
- `ba.category.*` — category/criteria CRUD
- `ba.period.*` — assessment period management
- `ba.assessment.*` — assessment entry, submit
- `ba.review.*` — review, approve, send back
- `ba.incident.*` — incident logging
- `ba.report.*` — report viewing (student/class/school)
- `ba.score.*` — score computation trigger
- Which controller method checks each permission
- Which Policy class enforces it

#### Section 8 — Service Architecture (5 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\BehaviouralAssessment\app\Services
Depends on:  [other services it calls]
Fires:       [events it dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. **BehaviouralAssessmentService** — assessment lifecycle: create, save ratings, submit, send back, lock; auto-save draft; bulk rating; teacher assignment resolution from SchoolSetup
2. **BehaviouralScoreService** — score computation engine: criterion → category → overall weighted aggregation; multi-teacher averaging; grade mapping; cache to ba_computed_scores; public API for Exam/Result module (`getStudentScore`, `getStudentCategoryScores`, `getBulkScores`, `computeAndCacheScores`)
3. **BehaviouralIncidentService** — incident CRUD; witness management; intervention mapping; follow-up tracking; parent notification dispatch; timeline retrieval with filters
4. **BehaviouralConfigService** — config CRUD per academic session; rating scale assignment; aggregation method selection; weightage configuration; notification threshold
5. **BehaviouralReportService** — student report generation (per-category, per-criterion, trend, remarks); class heatmap; school-level analytics; incident frequency analysis; PDF export (DomPDF); data for parent portal view

#### Section 9 — Integration Contracts (5 events)
For each event:
| Event | Fired By (service + when) | Listener | Payload | Action |
|---|---|---|---|---|
- AssessmentSubmitted → NotificationService → Principal/HOD notification
- AssessmentApproved → BehaviouralScoreService → Trigger score recomputation for the class-section-period
- AssessmentSentBack → NotificationService → Teacher notification with reviewer remarks
- IncidentCreated → NotificationService → Parent notification (if severity ≥ threshold from ba_config)
- ScoresComputed → available for Exam/Result module consumption (no direct listener — pull-based via service)

#### Section 10 — Non-Functional Requirements
From req v1 Section 5 (NFR-001 to NFR-010+).
For each NFR, add an "Implementation Note" column explaining HOW it will be met in code:
- NFR-BA-001 (multi-tenancy): No tenant_id column — database-per-tenant via stancl/tenancy
- NFR-BA-002 (grid performance ≤2s): Eager load relationships; paginate if >80 students; use `select()` to limit columns
- NFR-BA-003 (school-wide computation ≤30s): Queue job with chunked processing (50 students/chunk)
- NFR-BA-004 (cacheable reports): Redis cache with configurable TTL; cache key includes period_id + class_section_id
- NFR-BA-005 (RBAC): Laravel Policies on each model; Gate checks in controllers
- NFR-BA-006 (audit trail): Observer on `BaAssessmentRating` model auto-writes to `ba_audit_log`
- NFR-BA-007 (incident immutability): Service-layer guard; no update route exposed post-submission
- NFR-BA-008 (data retention): Soft deletes; configurable purge per school (default 5 sessions)
- NFR-BA-009 (localisation): All labels support Hindi/English; `__()` helper on all user-facing strings
- NFR-BA-010 (auto-save): Livewire wire:model.lazy + debounced save endpoint (30s interval)

#### Section 11 — Test Plan Outline

**Feature Tests (Pest) — ~8 test files, ~40 tests total:**
| File | Count | Key Scenarios |
|---|---|---|
(Derive from acceptance criteria in req v1 Section 12)

Key test files:
1. `RatingScaleTest` — CRUD, scale with levels, deletion cascade
2. `CategoryCriterionTest` — CRUD, reorder, activate/deactivate, class-group mapping
3. `AssessmentPeriodTest` — CRUD, lock/unlock, deadline enforcement
4. `AssessmentEntryTest` — rating entry, bulk rating, draft save, submit, unique constraint
5. `AssessmentReviewTest` — approve, send back, lock, permission checks
6. `IncidentTest` — CRUD, witness, intervention, follow-up append, immutability
7. `ScoreComputationTest` — weighted average, multi-teacher, grade mapping, cache
8. `ReportTest` — student report, class heatmap, PDF generation

**Unit Tests — ~4 test files, ~15 tests total:**
| File | Count | Key Scenarios |
|---|---|---|
1. `ScoreCalculatorTest` — weighted average math, edge cases (no ratings, single criterion)
2. `GradeMappingTest` — boundary conditions for grade assignment
3. `TeacherAssignmentResolverTest` — class teacher vs subject teacher permission logic
4. `ResultIntegrationFormulaTest` — final score computation with different weightages

**Test Data:**
- Required seeders for test database
- Required factories: RatingScaleFactory, CategoryFactory, CriterionFactory, AssessmentFactory, AssessmentRatingFactory, IncidentFactory
- Mock strategy: SchoolSetup relationships (classes, teachers) via factories; `Event::fake()` for notification tests; `Cache::fake()` for score caching tests

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `BA_FeatureSpec.md` | `{OUTPUT_DIR}/BA_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 16 ba_* tables appear in Section 2 entity inventory
- [ ] All ~15 FRs (BA-001 to BA-015) appear in Section 6
- [ ] All 20 business rules (BR-BA-001 to BR-BA-020) in Section 4 with enforcement point
- [ ] Both FSMs documented with ASCII state diagram and side effects
- [ ] All 5 services listed with key method signatures in Section 8
- [ ] All 5 integration events documented with payload in Section 9
- [ ] Cross-module FKs to std_students, sch_employees, sch_class_sections, sch_academic_sessions correctly noted
- [ ] **No `tenant_id` column** on any table
- [ ] **No `exm_*` FK references** in ba_* tables (result integration is pull-based via service, not FK)
- [ ] Permission matrix covers all 7 roles from req v1 Section 5.3
- [ ] All sch_* and std_* column names verified against tenant_db_v2.sql (use EXACT names from DDL)
- [ ] 9 default behavioural categories (5 Positive + 4 Negative) listed with all ~60 criteria
- [ ] Assessment status workflow: Draft → Submitted → Reviewed → Locked correctly documented

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/BA_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/BA_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 6 (canonical data model and relationships)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify std_*/sch_* table column names and data types; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`BA_DDL_v1.sql`)

Generate CREATE TABLE statements for all 16 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**
1. Table prefix: `ba_` for ALL tables — single prefix
2. Every table MUST include: `id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `updated_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Junction/bridge tables: use suffix `_jnt` (ba_class_group_category_jnt, ba_incident_witnesses_jnt, ba_incident_intervention_jnt)
5. JSON columns: suffix `_json` (e.g., attachments_json, details_json, grade_boundaries_json)
6. Boolean flag columns: prefix `is_` or `has_` (e.g., is_locked, is_active, is_follow_up_required, is_result_integration_enabled)
7. All IDs and FK references: `BIGINT UNSIGNED` (consistency with tenant_db convention)
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_ba_{tableshort}_{column}` (e.g., `fk_ba_criteria_category_id`)
12. **Do NOT recreate std_*, sch_*, exm_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. **ba_audit_log** is append-only — no `updated_at`, no `deleted_at` on this table (immutable audit records)

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No dependencies on other ba_* tables:
  ba_rating_scales, ba_categories, ba_interventions

Layer 2 — Depends on Layer 1:
  ba_rating_levels (→ ba_rating_scales),
  ba_criteria (→ ba_categories)

Layer 3 — Depends on sch_* + Layer 1:
  ba_class_group_category_jnt (→ ba_categories + sch_class_groups),
  ba_assessment_periods (→ sch_academic_sessions, exm_exam_terms nullable),
  ba_config (→ ba_rating_scales + sch_academic_sessions)

Layer 4 — Depends on Layer 3 + sch_*:
  ba_assessments (→ ba_assessment_periods + sch_employees + sch_class_sections),
  ba_audit_log (no FK deps, but logically after assessment tables)

Layer 5 — Depends on Layer 4 + Layer 2:
  ba_assessment_ratings (→ ba_assessments + std_students + ba_criteria + ba_rating_levels),
  ba_student_remarks (→ ba_assessments + std_students),
  ba_computed_scores (→ std_students + ba_categories + ba_assessment_periods),
  ba_incidents (→ std_students + sch_employees + ba_categories + ba_criteria)

Layer 6 — Depends on Layer 5 + Layer 1:
  ba_incident_witnesses_jnt (→ ba_incidents),
  ba_incident_intervention_jnt (→ ba_incidents + ba_interventions)

**Critical unique constraints to include:**
```sql
-- ba_assessment_ratings
UNIQUE KEY uq_ba_rating (assessment_id, student_id, criterion_id)

-- ba_assessments
UNIQUE KEY uq_ba_assessment (teacher_id, class_section_id, period_id)

-- ba_computed_scores
UNIQUE KEY uq_ba_score (student_id, category_id, period_id)

-- ba_config
UNIQUE KEY uq_ba_config_session (academic_session_id)

-- ba_rating_levels (one level per sort_order per scale)
UNIQUE KEY uq_ba_level (rating_scale_id, sort_order)
```

**ENUM values (exact, to match application code):**
```
ba_categories.polarity: 'positive','negative'
ba_assessments.status: 'draft','submitted','reviewed','locked'
ba_assessment_periods.status: 'open','closed','locked'
ba_incidents.incident_type: 'positive_reinforcement','negative_incident'
ba_incidents.severity: 'minor','moderate','major','critical'
ba_incidents.location: 'classroom','playground','corridor','lab','transport','canteen','library','other'
ba_incident_witnesses_jnt.witness_type: 'student','staff'
ba_interventions.intervention_type: 'reward','corrective','counselling'
ba_config.aggregation_method: 'average','weighted_average','separate_display'
ba_audit_log.entity_type: 'assessment_rating','assessment','incident'
```

**File header comment to include:**
```sql
-- =============================================================================
-- BA — Behavioural Assessment Module DDL
-- Module: BehaviouralAssessment (Modules\BehaviouralAssessment)
-- Table Prefix: ba_* (16 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: BehaviouralAssessment_v1.md
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`BA_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_ba_tables.php`.
- `up()`: creates all 16 tables in Layer 1 → Layer 6 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 6 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, JSON with `->json()`
- All FK constraints added in `up()` using `$table->foreign()`

### Phase 2C Task — Generate Seeders (4 files)

Namespace: `Modules\BehaviouralAssessment\Database\Seeders`

**1. `BaRatingScaleSeeder.php`** — 1 default scale + 5 levels:
```
Scale: "5-Point Behavioural Scale"

Levels (sort_order, label, numeric_value, description):
  1  Unsatisfactory   1  "Rarely meets expectations"
  2  Needs Improvement 2  "Occasionally meets expectations"
  3  Good             3  "Meets expectations consistently"
  4  Very Good        4  "Frequently exceeds expectations"
  5  Outstanding      5  "Consistently exceeds expectations"

Grade Boundaries (stored as grade_boundaries_json on scale):
  A+  4.50 – 5.00
  A   3.50 – 4.49
  B+  2.50 – 3.49
  B   1.50 – 2.49
  C   1.00 – 1.49
```

**2. `BaCategorySeeder.php`** — 9 categories + all criteria:
```
POSITIVE CATEGORIES (5):
  1. Classroom Engagement          — 8 criteria  (polarity: positive)
  2. Respect and Responsibility    — 8 criteria  (polarity: positive)
  3. Cooperation and Collaboration — 7 criteria  (polarity: positive)
  4. Emotional and Social Dev.     — 6 criteria  (polarity: positive)
  5. Leadership and Initiative     — 6 criteria  (polarity: positive)

NEGATIVE CATEGORIES (4):
  6. Disruptive Behaviours         — 7 criteria  (polarity: negative)
  7. Aggressive or Bullying        — 6 criteria  (polarity: negative)
  8. Academic Misconduct           — 6 criteria  (polarity: negative)
  9. Health and Safety Violations  — 4 criteria  (polarity: negative)

Total: 9 categories, 58 criteria
All criteria text from req v1 Section 3 (verbatim).
All is_active = true.
Equal default weights within each category (100 / criteria_count per category).
```

**3. `BaInterventionSeeder.php`** — 9 predefined interventions:
```
REWARD:
  1. Award/Certificate        (intervention_type: reward)
  2. Public Recognition       (intervention_type: reward)
  3. Extra Privileges          (intervention_type: reward)

CORRECTIVE:
  4. Verbal Warning            (intervention_type: corrective)
  5. Written Warning           (intervention_type: corrective)
  6. Detention                 (intervention_type: corrective)
  7. Suspension                (intervention_type: corrective)

COUNSELLING:
  8. Parent Meeting            (intervention_type: counselling)
  9. Counselling Referral      (intervention_type: counselling)
```

**4. `BaSeederRunner.php`** (Master seeder, calls all in order):
```php
$this->call([
    BaRatingScaleSeeder::class,    // no dependencies
    BaCategorySeeder::class,       // no dependencies
    BaInterventionSeeder::class,   // no dependencies
]);
```
Note: No dependency between the 3 seeders — order is arbitrary but consistent.
`ba_config` is NOT seeded — school must explicitly configure (default: `is_result_integration_enabled = false` set at application level when first accessed).

### Phase 2 Output Files
| File | Location |
|---|---|
| `BA_DDL_v1.sql` | `{OUTPUT_DIR}/BA_DDL_v1.sql` |
| `BA_Migration.php` | `{OUTPUT_DIR}/BA_Migration.php` |
| `BA_TableSummary.md` | `{OUTPUT_DIR}/BA_TableSummary.md` |
| `Seeders/BaRatingScaleSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/BaCategorySeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/BaInterventionSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/BaSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 16 ba_* tables exist in DDL
- [ ] Standard columns (id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) on ALL 16 tables (except ba_audit_log — no updated_at, no deleted_at)
- [ ] **No `tenant_id` column** on any table
- [ ] All unique constraints from the constraint list are present
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_ba_` convention
- [ ] `ba_assessment_ratings` has UNIQUE on `(assessment_id, student_id, criterion_id)`
- [ ] `ba_assessments` has UNIQUE on `(teacher_id, class_section_id, period_id)`
- [ ] `ba_computed_scores` has UNIQUE on `(student_id, category_id, period_id)`
- [ ] `ba_config` has UNIQUE on `(academic_session_id)`
- [ ] `ba_incidents.attachments_json` uses JSON type with `_json` suffix
- [ ] `ba_incidents` has index on `(student_id, date)` for timeline queries
- [ ] `ba_assessment_ratings` has composite index on `(student_id, criterion_id, assessment_id)`
- [ ] Junction tables use `_jnt` suffix: ba_class_group_category_jnt, ba_incident_witnesses_jnt, ba_incident_intervention_jnt
- [ ] BaCategorySeeder has all 9 categories and 58 criteria (verbatim from req v1 Section 3)
- [ ] BaRatingScaleSeeder creates 1 scale + 5 levels + grade boundaries JSON
- [ ] BaInterventionSeeder has all 9 interventions across 3 types
- [ ] `BaSeederRunner.php` calls all 3 seeders
- [ ] `BA_TableSummary.md` has one-line description for all 16 tables
- [ ] **No cross-module FK to exm_* tables** (assessment period link to exam term is optional — nullable column, no FK constraint)
- [ ] All std_*/sch_* column names verified against tenant_db_v2.sql

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `BA_DDL_v1.sql` + Migration + 4 seeders. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/BA_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 7 (UI/UX), Section 8 (integrations), Section 10 (services), Section 12 (acceptance criteria)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (especially naming conventions)

### Phase 3 Task — Generate `BA_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

Controllers to define:
1. `RatingScaleController` — index, store, show, update, destroy (manages scales + levels together)
2. `CategoryController` — index, store, show, update, destroy, reorder (categories)
3. `CriterionController` — index, store, show, update, destroy, reorder (criteria within a category)
4. `ClassGroupCategoryController` — index, store, destroy (maps categories to class groups)
5. `AssessmentPeriodController` — index, store, show, update, destroy, lock, unlock
6. `ConfigController` — show, update
7. `AssessmentController` — index, create, store (save ratings), show, submit, bulkRate, autoSave
8. `AssessmentReviewController` — index, show, approve, sendBack
9. `IncidentController` — index, store, show, update, timeline, addFollowUp
10. `InterventionController` — index, store, show, update, destroy
11. `ReportController` — studentReport, classReport, schoolAnalytics, exportPdf, parentView

For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

#### Section 2 — Service Inventory (5 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Events fired
- Other services called (dependency graph)

Include the score computation sequence as inline pseudocode in `BehaviouralScoreService`:
```
computeStudentScore(Student $student, AssessmentPeriod $period): ComputedScore
  Step 1: Get all ba_assessment_ratings for student + period (across all teacher assessments)
  Step 2: Group ratings by criterion_id
  Step 3: For each criterion: average all teacher ratings → criterion_score
  Step 4: Group criteria by category_id
  Step 5: For each category: weighted_avg(criterion_scores, criterion.weight) → category_score
  Step 6: Overall score: weighted_avg(category_scores, category.weight) → overall_score
  Step 7: Map overall_score to grade via grade_boundaries_json
  Step 8: Upsert ba_computed_scores (student_id, category_id, period_id, numeric_score, grade)
  Return: ComputedScore { numeric_score, grade, category_scores[] }
```

#### Section 3 — FormRequest Inventory (~17 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

Group by controller. Key FormRequests to detail:
- `StoreRatingScaleRequest` — name required, levels array with label + numeric_value
- `StoreCategoryRequest` — name required, polarity enum, unique name within tenant
- `StoreCriterionRequest` — name required, category_id exists, weight 0–100
- `StoreAssessmentPeriodRequest` — name required, start_date < end_date, deadline ≥ end_date
- `StoreAssessmentRatingRequest` — ratings array validation: student_id exists, criterion_id exists, rating_level_id exists
- `SubmitAssessmentRequest` — all required criteria must have ratings for all students
- `ReviewAssessmentRequest` — action enum (approve/send_back), remarks required for send_back
- `StoreIncidentRequest` — student_id required, incident_type enum, severity enum (required for negative), description required

#### Section 4 — Blade View & Livewire Component Inventory (~55 views + 9 components)

List all blade views grouped by sub-module. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Sub-modules and approximate view counts:
- Rating Scale: ~4 views (index, create/edit modal)
- Category & Criteria: ~6 views (index with nested criteria, create/edit modals)
- Assessment Period: ~4 views (index, create/edit modal, show with status)
- Config: ~2 views (show/edit panel)
- Assessment Entry: ~8 views (index/list, grid entry, student detail, bulk action, draft status)
- Review: ~4 views (index, review grid, approval modal)
- Incidents: ~8 views (index, create form, show/detail, timeline, follow-up form)
- Interventions: ~3 views (index, create/edit modal)
- Reports: ~8 views (student report, class heatmap, school analytics, PDF template)
- Dashboard: ~3 views (teacher, principal/HOD, parent)
- Shared partials: ~5 (modals, grid headers, pagination, status badges)

**Livewire Components (9 from req v1 Section 7.4):**
| Component | Purpose | Key Features |
|---|---|---|
| `BehaviouralAssessmentGrid` | Main assessment entry | Students × criteria grid, dropdown ratings, auto-save, bulk actions |
| `IncidentLogForm` | Create/edit incident | Auto-suggest student, category/criterion dropdowns, attachment upload |
| `IncidentTimeline` | Student incident history | Filterable timeline, severity colour-coding, follow-up indicators |
| `BehaviouralReportCard` | Student report view | Category breakdown, trend chart, remarks, incident summary |
| `BehaviouralDashboard` | Role-aware dashboard | Pending assessments, deadlines, flagged students, incident stats |
| `CategoryCriteriaManager` | Admin CRUD | Drag-and-drop reorder, inline edit, activate/deactivate toggles |
| `RatingScaleManager` | Admin CRUD | Scale + levels management, grade boundary configuration |
| `AssessmentPeriodManager` | Admin CRUD | Period CRUD, lock/unlock, exam term linking |
| `BehaviouralConfigPanel` | Admin settings | Result integration toggle, weightage slider, aggregation method selector |

Key UI patterns to document:
- Assessment grid: sticky header row + first column for large grids; keyboard Tab navigation; colour-coded ratings (green → red)
- Auto-save: Livewire `wire:model.lazy` with 30-second debounced save; visible draft indicator
- Incident auto-suggest: Student name search with recent incident count badge
- Heatmap: colour-gradient table showing score distribution per student per category

#### Section 5 — Complete Route List

Consolidate ALL routes into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Middleware on all routes: `['auth', 'tenant', 'EnsureTenantHasModule:BehaviouralAssessment']`

Group by controller. Count total routes at the end.

#### Section 6 — Implementation Phases

For each phase, provide a detailed sprint plan:

**Phase 1 — Configuration Foundation (Sprint 1)**
FRs: BA-001, BA-002, BA-003, BA-004
Files to create:
- Controllers: RatingScaleController, CategoryController, CriterionController, ClassGroupCategoryController, AssessmentPeriodController, ConfigController
- Services: BehaviouralConfigService
- Models: RatingScale, RatingLevel, Category, Criterion, ClassGroupCategory, AssessmentPeriod, Config
- Livewire: RatingScaleManager, CategoryCriteriaManager, AssessmentPeriodManager, BehaviouralConfigPanel
- FormRequests: 8 (Store/Update pairs for scale, category, criterion, period)
- Seeders: BaRatingScaleSeeder, BaCategorySeeder, BaInterventionSeeder, BaSeederRunner
- Views: ~16 blade views
- Tests: RatingScaleTest, CategoryCriterionTest, AssessmentPeriodTest (~12 tests)

**Phase 2 — Assessment Workflow (Sprint 2–3)**
FRs: BA-005, BA-006, BA-008
Files to create:
- Controllers: AssessmentController, AssessmentReviewController
- Services: BehaviouralAssessmentService
- Models: Assessment, AssessmentRating, StudentRemark, AuditLog
- Livewire: BehaviouralAssessmentGrid
- FormRequests: 4 (StoreRating, Submit, Review, BulkRate)
- Views: ~12 blade views
- Tests: AssessmentEntryTest, AssessmentReviewTest (~12 tests)

**Phase 3 — Incident Management (Sprint 4)**
FRs: BA-007
Files to create:
- Controllers: IncidentController, InterventionController
- Services: BehaviouralIncidentService
- Models: Incident, IncidentWitness, Intervention, IncidentIntervention
- Livewire: IncidentLogForm, IncidentTimeline
- FormRequests: 4 (Store/Update for incident and intervention)
- Views: ~11 blade views
- Tests: IncidentTest (~8 tests)

**Phase 4 — Score Computation & Reports (Sprint 5–6)**
FRs: BA-009, BA-010, BA-011, BA-012, BA-013, BA-014, BA-015
Files to create:
- Controllers: ReportController
- Services: BehaviouralScoreService, BehaviouralReportService
- Models: ComputedScore
- Livewire: BehaviouralReportCard, BehaviouralDashboard
- Jobs: ComputeSchoolScoresJob
- Views: ~16 blade views (reports + dashboards + PDF template)
- Tests: ScoreComputationTest, ReportTest, ResultIntegrationTest (~15 tests)

#### Section 7 — Seeder Execution Order

```
php artisan module:seed BehaviouralAssessment --class=BaSeederRunner
  ↓ BaRatingScaleSeeder        (no dependencies)
  ↓ BaCategorySeeder           (no dependencies)
  ↓ BaInterventionSeeder       (no dependencies)
```

For test runs: use `BaRatingScaleSeeder` + `BaCategorySeeder` as minimum required seeders.

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; Pest (unit style) for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TenantTestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// SchoolSetup relationships: use factories for classes, sections, teachers, students
// Events: Event::fake() for notification tests
// Cache: Cache::fake() for score caching tests
```

**Minimum Test Coverage Targets:**
- Assessment workflow: 100% of FSM transitions tested (each valid transition + each invalid transition blocked)
- Score computation: each computation step tested individually (unit) + full computation tested (feature)
- Assessment FSM: all 4 states tested, BR-BA-003 (locked period prevents edits) explicitly tested
- Multi-teacher averaging: edge case with 1, 2, 3 teachers rating same criterion
- Incident immutability: verify update rejected after submission (BR-BA-008)
- Result integration formula: verify with weightages 5%, 10%, 15%, 20%

**Feature Test File Summary:**
List all ~8 test files with file path, test count, and key scenarios.

**Unit Test File Summary:**
List all ~4 unit test files with file path, test count, and scenarios.

**Factory Requirements:**
```
RatingScaleFactory         — generates scale with 5 levels
CategoryFactory            — generates category with polarity
CriterionFactory           — generates criterion with weight, links to category
AssessmentFactory          — generates assessment with status, links to period/teacher/class-section
AssessmentRatingFactory    — generates rating with level, links to assessment/student/criterion
IncidentFactory            — generates incident with type, severity, description
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `BA_Dev_Plan.md` | `{OUTPUT_DIR}/BA_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 11 controllers listed with all methods
- [ ] All 5 services listed with at minimum 3 key method signatures each
- [ ] All ~17 FormRequests listed with their key validation rules
- [ ] All ~15 FRs (BA-001 to BA-015) appear in at least one implementation phase
- [ ] All 4 implementation phases have: FRs covered, files to create, test count
- [ ] Score computation pseudocode present in Section 2 (BehaviouralScoreService)
- [ ] Seeder execution order documented
- [ ] 9 Livewire components documented with purpose and key features
- [ ] Route list consolidated with middleware and FR reference
- [ ] View count per sub-module totals approximately 55
- [ ] Test strategy includes Event::fake() and Cache::fake() guidance
- [ ] BR-BA-003 (locked period prevents edits) test explicitly referenced
- [ ] BR-BA-008 (incident immutability) test explicitly referenced
- [ ] Result integration formula test with multiple weightage values explicitly referenced

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `BA_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/BA_FeatureSpec.md`
2. `{OUTPUT_DIR}/BA_DDL_v1.sql` + Migration + 4 Seeders
3. `{OUTPUT_DIR}/BA_Dev_Plan.md`
Development lifecycle for BA module is ready to begin."

---

## QUICK REFERENCE — BA Module Tables vs Controllers vs Services

| Domain | ba_* Tables | Controller | Service(s) |
|---|---|---|---|
| Rating Config | ba_rating_scales, ba_rating_levels | RatingScaleController | BehaviouralConfigService |
| Categories | ba_categories, ba_criteria, ba_class_group_category_jnt | CategoryController, CriterionController, ClassGroupCategoryController | — (direct CRUD) |
| Assessment Periods | ba_assessment_periods | AssessmentPeriodController | BehaviouralConfigService |
| Assessment Entry | ba_assessments, ba_assessment_ratings, ba_student_remarks | AssessmentController | BehaviouralAssessmentService |
| Review | (reads ba_assessments, ba_assessment_ratings) | AssessmentReviewController | BehaviouralAssessmentService |
| Score Computation | ba_computed_scores | — (triggered by service) | BehaviouralScoreService |
| Incidents | ba_incidents, ba_incident_witnesses_jnt, ba_incident_intervention_jnt | IncidentController | BehaviouralIncidentService |
| Interventions | ba_interventions | InterventionController | — (direct CRUD) |
| Config | ba_config | ConfigController | BehaviouralConfigService |
| Audit | ba_audit_log | — (auto-populated via Observer) | — (model event) |
| Reports | (reads ba_computed_scores, ba_incidents, ba_assessments) | ReportController | BehaviouralReportService |
