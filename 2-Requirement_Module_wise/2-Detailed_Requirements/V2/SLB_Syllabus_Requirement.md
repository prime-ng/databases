# SLB — Syllabus Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** SLB | **Scope:** Tenant (Per-School) | **Table Prefix:** `slb_`
**Laravel Module:** `Modules/Syllabus` | **Namespace:** `Modules\Syllabus`
**Completion:** ~55% | **Estimated Fix Effort:** 8–10 developer days

---

## 1. Executive Summary

The Syllabus module is the **academic content management backbone** of the Prime-AI platform. It organises curriculum into a hierarchy of Lessons → Topics → Sub-Topics (configurable depth up to level 9), maps content to NEP 2020 competencies and Bloom's Taxonomy, and tracks how much of the syllabus has been taught during an academic session. It directly powers the LMS-Quiz, LMS-Exam, Question Bank, HPC, and Recommendation modules by supplying the topic-competency-taxonomy graph used for question selection, assessment quality, and AI-driven interventions.

**V2 key additions over V1:**
- Formalises all critical security gaps as P0 fix requirements with acceptance criteria
- Proposes rename from `Competencie` (typo) to `Competency / Competencies` throughout
- Documents `EnsureTenantHasModule` middleware omission as a critical gap
- Adds service-layer design specifications (SyllabusService, CompetencyMappingService, CoverageAnalyticsService)
- Adds syllabus coverage analytics and dashboard screen specifications
- Adds study material upload feature specification (models exist, zero UI)
- Adds test scenario inventory covering auth, hierarchy, soft delete, and coverage logic
- Corrects V1 error: TopicController DOES have `Gate::authorize()` on index/destroy (partial auth); remaining methods still lack auth

---

## 2. Module Overview

### 2.1 Purpose

- Organise school curriculum into Board-aligned lesson and topic hierarchies
- Support NEP 2020, CBSE, ICSE, and State Board alignment codes on every lesson/topic
- Enable per-topic competency tagging using the KNOWLEDGE / SKILL / ATTITUDE framework
- Provide Bloom's Taxonomy and cognitive skill classification for exam engine consumption
- Track syllabus delivery progress (which teacher taught which topic on which date)
- Supply reference data (question types, complexity levels, performance categories, grade divisions) consumed by downstream assessment modules

### 2.2 Module Characteristics

| Attribute | Value |
|-----------|-------|
| Laravel Module | `nwidart/laravel-modules` v12, name `Syllabus` |
| Namespace | `Modules\Syllabus` |
| DB Connection | `tenant_mysql` (tenant_{uuid}) |
| Table Prefix | `slb_*` |
| Auth | Spatie Permission v6.21 via `Gate::authorize()` / `Gate::any()` |
| Frontend | Bootstrap 5 + AdminLTE 4 |
| Controllers | 15 (including 1 empty stub: `SyllabusController`) |
| Models | 22 |
| Services | 1 (`TopicReleaseControlService` — partial; 0 business-logic services) |
| FormRequests | 14 |
| Tests | 0 |
| RBS Reference | Module H — Academics Management (H1, H2, H6) |

### 2.3 Sub-Modules / Feature Areas

| # | Feature Area | Status |
|---|-------------|--------|
| 1 | Lesson Management | 🟡 90% — minor auth gaps |
| 2 | Topic Hierarchy (multi-level tree) | 🟡 85% — forceDelete in destroy(); auth partial |
| 3 | Competency Framework (NEP 2020) | 🟡 70% — ZERO auth; `$request->all()`; no SoftDeletes |
| 4 | Bloom's Taxonomy | ✅ 95% — fully implemented |
| 5 | Cognitive Skills | ✅ 95% — fully implemented |
| 6 | Question Type / Specificity / Complexity | ✅ 95% — reference data complete |
| 7 | Syllabus Schedule | 🟡 90% — has auth; coverage % not computed |
| 8 | Performance Categories | 🟡 65% — CRUD present; AI severity UI missing |
| 9 | Grade Divisions | 🟡 60% — basic CRUD only |
| 10 | Study Materials | ❌ 10% — models exist; zero controller/routes/UI |
| 11 | Coverage Analytics / Dashboard | ❌ 0% — not started |
| 12 | Service Layer | ❌ 0% — no business-logic services |
| 13 | Test Coverage | ❌ 0% — zero tests |
| 14 | SyllabusController (main nav hub) | ❌ 0% — empty stub |

---

## 3. Stakeholders & Roles

### 3.1 Primary Actors

| Actor | Description | Access Level |
|-------|-------------|--------------|
| School Admin | Tenant administrator | Full CRUD on all SLB entities |
| Academic Coordinator | Manages curriculum and lesson plans | Full CRUD on lessons, topics, schedule |
| Subject Teacher | Creates lessons, maps topics for their subjects | Create/Edit own; view others |
| Class Teacher | Views syllabus coverage and schedule | ViewAny only |
| Student | Reads published lesson objectives | Read-only via student portal |
| Parent | Views coverage progress | Read-only via parent portal |

### 3.2 Permission Naming Convention

Permissions follow `tenant.<resource>.<action>`:

| Resource | Permissions Required |
|----------|---------------------|
| lesson | `tenant.lesson.viewAny`, `tenant.lesson.view`, `tenant.lesson.create`, `tenant.lesson.update`, `tenant.lesson.delete` |
| topic | `tenant.topic.view`, `tenant.topic.create`, `tenant.topic.update`, `tenant.topic.delete` |
| competencies | `tenant.competencies.viewAny`, `tenant.competencies.create`, `tenant.competencies.update`, `tenant.competencies.delete` |
| competency-type | `tenant.competency-type.viewAny`, `tenant.competency-type.create`, `tenant.competency-type.update`, `tenant.competency-type.delete` |
| syllabus-schedule | `tenant.syllabus-schedule.viewAny`, `tenant.syllabus-schedule.create`, `tenant.syllabus-schedule.update`, `tenant.syllabus-schedule.delete` |
| performance-category | `tenant.performance-category.viewAny`, `tenant.performance-category.update` |
| grade-division | `tenant.grade-division.viewAny`, `tenant.grade-division.create`, `tenant.grade-division.update`, `tenant.grade-division.delete` |

---

## 4. Functional Requirements

### FR-SLB-01: Lesson Management
**Status:** 🟡 Partial (90%)

**FR-SLB-01.1 — Create Lesson** ✅
- System shall allow creation of a lesson linked to Academic Session + Class + Subject + Book (`bok_books_id` mandatory FK)
- Auto-generate `code` as `<CLASS_CODE>_<SUBJECT_CODE>_L<NN>` (unique system-wide)
- Fields: `name`, `short_name`, `ordinal`, `description`, `learning_objectives` (JSON array), `prerequisites` (JSON array of lesson IDs), `estimated_periods`, `weightage_in_subject`, `nep_alignment`, `resources_json` (array of `{type, url, title}`), `book_chapter_ref`, `scheduled_year_week` (YYYYWW format)
- UUID (BINARY 16) auto-assigned on creation for analytics

**FR-SLB-01.2 — Lesson Ordering** ✅
- Ordered by `ordinal` within class+subject scope; drag-and-drop via `updateOrder` endpoint
- `ordinal` is unique per class+subject

**FR-SLB-01.3 — Bulk Import** ✅
- XLSX/CSV two-step flow: (1) `validateImportFile` returns text error report; (2) `startImport` commits if validation passed
- Uses `Maatwebsite\Excel` (`LessonImport` class)

**FR-SLB-01.4 — Soft Delete Lifecycle** ✅
- Soft delete → Trash view → Restore or Force-Delete
- `is_active` toggle hides lessons from student/parent views without deleting

**FR-SLB-01.5 — Duplicate Check** ✅
- `checkDuplicate` AJAX endpoint verifies name uniqueness within class+subject scope before submission

**FR-SLB-01.6 — Version Control** ❌ Not Started
- `hpc_lesson_version_control` table exists in DDL; tracks `curriculum_authority` (NCERT/CBSE/ICSE/STATE_BOARD), `is_editable`, `is_system_defined`
- System-defined lessons (`is_system_defined = 1`) shall be locked (`is_editable = 0`); schools cannot modify them
- Implementation: no model, controller, or routes exist yet

### FR-SLB-02: Topic Hierarchy Management
**Status:** 🟡 Partial (85%)

**FR-SLB-02.1 — Configurable Hierarchy Depth** ✅
- Depth controlled by `slb_topic_level_types`; default levels 0–4 (Topic, Sub-Topic, Mini Topic, Sub-Mini Topic, Micro Topic); expandable to level 9
- Level names are configured per school via `TopicLevelTypeController`

**FR-SLB-02.2 — Create / Update Topic** ✅
- Fields: `name`, `short_name`, `level_id` (FK to `slb_topic_level_types`), `parent_id`, `lesson_id`, `class_id`, `subject_id`, `description`, `duration_minutes`, `weightage_in_lesson`, `learning_objectives` (JSON), `keywords` (JSON), `prerequisite_topic_ids` (JSON), `ordinal`, `is_assessable`
- Auto-computed on create: `code` (hierarchical: `CLASS_SUBJ_LES_TOP01_SUB02...`), `analytics_code` (same value, immutable), `path` (materialized path `/1/5/23/`), `path_names` (breadcrumb string)
- UUID (BINARY 16) auto-assigned

**FR-SLB-02.3 — Parent-Level Validation** ✅
- Level 0 topics must have `parent_id = NULL`
- Level N must have parent at level N−1 within the same lesson
- Cannot change `level` when children exist (HTTP 422)
- Circular parent blocked in controller (direct parent check) and by FK `ON DELETE CASCADE`

**FR-SLB-02.4 — Topic Tree & Navigation** ✅
- `getTopicsByLesson`: returns full recursive tree via eager-loaded `childrenRecursive`
- `updateHierarchy`: accepts serialised JSON tree for drag-and-drop persistence; wrapped in DB transaction
- `getParentTopics`, `getChildTopics`, `getSubTopics`, `getMiniTopics`, `getGrandChildTopics`: level-specific navigation endpoints
- `ancestors()`, `descendants()`, `siblings()` query methods on the `Topic` model using materialized path

**FR-SLB-02.5 — Bulk Import** ✅
- Same two-step validate-then-commit flow as lessons
- Import class: `TopicImport`

**FR-SLB-02.6 — Release Flags** ✅
- `release_quiz_on_completion`: auto-triggers quiz release when topic marked complete (via `TopicReleaseControlService`)
- `release_quest_on_completion`: auto-triggers question release on completion
- `can_use_for_syllabus_status`: controls whether topic counts toward coverage percentage

**FR-SLB-02.7 — Soft Delete (CRITICAL FIX REQUIRED)** ❌ Gap
- Current: `TopicController::destroy()` calls `forceDelete()` (line 525) — permanent data loss
- Required: Change to `delete()` (soft delete); add trash/restore lifecycle for topics
- Force-delete route already exists (`/topic/{id}/force-delete`) and should remain as explicit permanent deletion
- Pre-delete checks: quizzes assigned to topic ✅ already checked; syllabus schedule references ❌ not checked

### FR-SLB-03: Competency Framework
**Status:** 🟡 Partial (70%) — CRITICAL security issues

**FR-SLB-03.1 — Competency Types** ✅
- Master types: KNOWLEDGE, SKILL, ATTITUDE (configurable)
- Full CRUD + soft delete via `CompetencyTypeController` with proper auth

**FR-SLB-03.2 — Competency CRUD** 🟡 (CRITICAL FIXES REQUIRED)
- Hierarchical competency tree (self-referential `parent_id`)
- Fields: `uuid`, `code`, `name`, `short_name`, `description`, `class_id`, `subject_id`, `parent_id`, `competency_type_id`, `domain` (COGNITIVE/AFFECTIVE/PSYCHOMOTOR), `nep_framework_ref`, `ncf_alignment`, `learning_outcome_code`, `path`, `level`, `is_active`
- Auto-computed on create: `uuid`, `code` (slugified from name), `level` (parent.level + 1), `path` (materialized)
- CRITICAL FIX 1: Add `Gate::authorize()` to ALL 9 methods in `CompetencieController`
- CRITICAL FIX 2: Replace `$request->all()` with `$request->validated()` in `store()` (lines 137, 146)
- CRITICAL FIX 3: Add `SoftDeletes` trait to `Competencie` model; add `deleted_at` to `$casts`; add `created_by` to `$fillable`

**FR-SLB-03.3 — Naming Typo Remediation** 📐 Proposed
- The V1 codebase uses `Competencie` (missing final 's') throughout — class name, controller name, route name, table alias comments
- Proposed: rename to `Competency` (model) / `Competencies` (plural/controller) in a single migration PR
- Route name `competencies.` is already correct; only PHP class names and internal references need fixing
- Impact: `CompetencieController.php` → `CompetencyController.php`; `Competencie.php` → `Competency.php`; update all `use` imports

**FR-SLB-03.4 — Topic-Competency Mapping** 🟡
- Each topic may link to multiple competencies via `slb_topic_competency_jnt`
- Each mapping carries: `weightage` (topic's contribution to the competency), `is_primary` flag
- Unique constraint: `UNIQUE(topic_id, competency_id)` — one mapping per pair
- Managed via `TopicCompetencyController`
- Missing: auth audit (status unknown per gap analysis); activity logging absent

### FR-SLB-04: Bloom's Taxonomy & Assessment Reference Data
**Status:** ✅ 95% Complete

**FR-SLB-04.1 — Bloom's Taxonomy** ✅
- 6 levels: REMEMBERING (1), UNDERSTANDING (2), APPLYING (3), ANALYZING (4), EVALUATING (5), CREATING (6)
- LOT (Lower Order Thinking): levels 1–3; HOT (Higher Order Thinking): levels 4–6
- Full CRUD + soft delete via `BloomTaxonomyController`

**FR-SLB-04.2 — Cognitive Skills** ✅
- Each cognitive skill links to a parent `bloom_id`
- Examples: COG-KNOWLEDGE, COG-UNDERSTANDING, COG-SKILL
- Used for question tagging in Question Bank and automated paper generation

**FR-SLB-04.3 — Question Type Specificity** ✅
- Links to `cognitive_skill_id`; context types: IN_CLASS, HOMEWORK, SUMMATIVE, FORMATIVE
- Controls which question types are appropriate in which assessment context

**FR-SLB-04.4 — Complexity Levels** ✅
- EASY (1), MEDIUM (2), DIFFICULT (3)
- Used to balance question paper difficulty in LMS-Exam and Question Bank

**FR-SLB-04.5 — Question Types** ✅
- Types: MCQ_SINGLE, MCQ_MULTI, SHORT_ANSWER, LONG_ANSWER, MATCH, NUMERIC, FILL_BLANK, CODING
- `has_options` and `auto_gradable` flags drive exam engine behaviour

### FR-SLB-05: Syllabus Schedule
**Status:** 🟡 Partial (90%)

**FR-SLB-05.1 — Schedule a Topic** ✅
- Assign a topic to a date range (`scheduled_start_date`, `scheduled_end_date`) per class/section/subject
- Fields: `academic_session_id`, `class_id`, `section_id`, `subject_id`, `lesson_id`, `topic_id`, `topic_level_type_id`, `assigned_teacher_id`, `taught_by_teacher_id`, `planned_periods`, `priority` (HIGH/MEDIUM/LOW), `notes`
- Full CRUD + soft delete via `SyllabusScheduleController`

**FR-SLB-05.2 — Delivery Tracking** 🟡
- `taught_by_teacher_id` records the actual teacher who taught the topic
- `can_use_for_syllabus_status` flag on topic determines inclusion in coverage calculation
- Coverage % = (topics with `taught_by_teacher_id` SET AND `can_use_for_syllabus_status = 1`) / (total topics with `can_use_for_syllabus_status = 1`) × 100
- MISSING: No endpoint or service computes this percentage; no dashboard displays it

**FR-SLB-05.3 — Planning Date Updates** ✅
- `SyllabusController::updatePlanningDates()` route exists (though SyllabusController is a stub)

### FR-SLB-06: Performance Categories & Grade Divisions
**Status:** 🟡 Partial (60–65%)

**FR-SLB-06.1 — Performance Categories** 🟡
- Bands: TOPPER, EXCELLENT, GOOD, AVERAGE, BELOW_AVERAGE, NEED_IMPROVEMENT, POOR (configurable)
- Per band: `min_percentage`, `max_percentage`, `ai_severity` (LOW/MEDIUM/HIGH/CRITICAL), `ai_default_action` (ACCELERATE/PROGRESS/PRACTICE/REMEDIATE/ESCALATE), `color_code`, `icon_code`, `display_order`
- Scope: SCHOOL-wide or CLASS-specific override
- `is_system_defined = 1` locks the record from school edits
- `auto_retest_required`: triggers automatic retest creation when student falls in this band
- Application layer MUST prevent overlapping `min/max_percentage` ranges within same scope

**FR-SLB-06.2 — Grade Division Master** 🟡
- Two grading types: GRADE (A+/A/B) or DIVISION (1st/2nd/3rd)
- Scopes: SCHOOL, BOARD, CLASS — enables classes 1–8 to use GRADE system while 9–12 use DIVISION
- `board_code` (CBSE/ICSE/STATE) for board-specific definitions
- `is_locked` becomes true after result publishing — prevents retroactive changes
- Application layer must prevent overlapping ranges within same scope+grading_type

### FR-SLB-07: Study Material Management
**Status:** ❌ Not Started (models exist, zero UI)

**FR-SLB-07.1 — Study Material Types** 📐 Proposed
- `StudyMaterialType` model exists (table TBD); types: VIDEO, PDF, LINK, PRESENTATION, AUDIO
- CRUD via new `StudyMaterialTypeController`

**FR-SLB-07.2 — Upload Study Material** 📐 Proposed
- `StudyMaterial` model exists; needs FK to either `slb_lessons.id` or `slb_topics.id` (polymorphic or separate FKs)
- File uploads stored via `sys_media` polymorphic storage (DomPDF/S3 compatible)
- Fields: `title`, `type_id`, `file_url`, `description`, `is_active`, `sort_order`
- New `StudyMaterialController` required with routes under `/syllabus/study-material/`
- Access: Subject Teacher (own lessons), Academic Coordinator (all)

### FR-SLB-08: Coverage Analytics & Dashboard
**Status:** ❌ Not Started

**FR-SLB-08.1 — SyllabusController Dashboard** 📐 Proposed
- `SyllabusController` is a complete stub (store/update/destroy are empty)
- Required views (routes already registered at lines 1000–1003 of tenant.php):
  - `syllabus.master.index` → master data dashboard (lesson/topic counts, competency counts)
  - `syllabus.bloom.index` → Bloom's distribution chart per class/subject
  - `syllabus.planning.index` → Gantt-style view of schedule vs actual delivery
  - `syllabus.report.index` → Coverage report by class/subject/teacher

**FR-SLB-08.2 — Coverage Calculation Service** 📐 Proposed
- New `CoverageAnalyticsService` with methods:
  - `getCoverageByClassSubject(int $classId, int $subjectId, int $sessionId): float`
  - `getCoverageByTeacher(int $teacherId, int $sessionId): array`
  - `getOverallCoverage(int $sessionId): array` — returns array per class+subject
  - `getBloomDistribution(int $classId, int $subjectId): array` — returns bloom level counts
- Returns data as arrays for blade rendering and JSON API consumption

### FR-SLB-09: Module Route Guard
**Status:** ❌ Gap (CRITICAL)

**FR-SLB-09.1 — EnsureTenantHasModule Middleware** ❌
- The Syllabus route group at `tenant.php` line 999 uses only `['auth', 'verified']`
- Missing: `EnsureTenantHasModule` middleware
- Impact: Any authenticated user in any tenant can access all 80+ Syllabus routes even if tenant has not subscribed to the Syllabus module
- Fix: Add `EnsureTenantHasModule:SLB` (or equivalent module code) to the middleware array for the entire Syllabus route group

---

## 5. Data Model

### 5.1 Primary Tables (14 tables)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `slb_topic_level_types` | Names/config for each level (0–9) | `level`, `code` (TOP/SBT/MIN/SMN/MIC), `name`, `can_be_used_for_*_release` flags |
| `slb_lessons` | Lesson/chapter master per class-subject | `uuid`, `academic_session_id`, `class_id`, `subject_id`, `bok_books_id`, `code`, `ordinal`, `learning_objectives` JSON, `prerequisites` JSON, `resources_json`, `scheduled_year_week` (YYYYWW) |
| `slb_topics` | Hierarchical topic tree (self-ref) | `uuid`, `parent_id`, `lesson_id`, `class_id`, `subject_id`, `level_id` (FK→`slb_topic_level_types`), `path`, `path_names`, `code`, `analytics_code`, `ordinal`, `duration_minutes`, `is_assessable`, `can_use_for_syllabus_status`, `release_quiz_on_completion`, `release_quest_on_completion` |
| `slb_competency_types` | Competency domain types | `code`, `name`, `description` |
| `slb_competencies` | NEP-aligned competency tree (self-ref) | `uuid`, `parent_id`, `code`, `competency_type_id`, `domain` ENUM(COGNITIVE/AFFECTIVE/PSYCHOMOTOR), `nep_framework_ref`, `ncf_alignment`, `learning_outcome_code`, `path`, `level` |
| `slb_topic_competency_jnt` | Topic ↔ Competency mapping | `topic_id`, `competency_id`, `weightage`, `is_primary`, UNIQUE(`topic_id`,`competency_id`) |
| `slb_bloom_taxonomy` | Bloom's 6 levels | `code`, `bloom_level` (1–6), `name` |
| `slb_cognitive_skill` | Cognitive skills linked to Bloom | `bloom_id`, `code`, `name` |
| `slb_ques_type_specificity` | Question usage context | `cognitive_skill_id`, `code` (IN_CLASS/HOMEWORK/SUMMATIVE/FORMATIVE) |
| `slb_complexity_level` | Question difficulty levels | `code`, `complexity_level` (1=EASY/2=MEDIUM/3=DIFFICULT) |
| `slb_question_types` | Question format types | `code`, `has_options`, `auto_gradable` |
| `slb_performance_categories` | Score band definitions | `code`, `level`, `min/max_percentage`, `ai_severity`, `ai_default_action`, `scope` ENUM(SCHOOL/CLASS), `is_system_defined`, `auto_retest_required` |
| `slb_grade_division_master` | Grade band master (GRADE or DIVISION) | `code`, `grading_type` ENUM(GRADE/DIVISION), `min/max_percentage`, `board_code`, `scope` ENUM(SCHOOL/BOARD/CLASS), `class_id`, `is_locked` |
| `slb_syllabus_schedule` | Topic scheduling calendar | `academic_session_id`, `class_id`, `section_id`, `lesson_id`, `topic_id`, `topic_level_type_id`, `scheduled_start/end_date`, `assigned_teacher_id`, `taught_by_teacher_id`, `planned_periods`, `priority` ENUM(HIGH/MEDIUM/LOW) |

### 5.2 Relationships

```
slb_lessons (1) ──── (N) slb_topics                    [FK: fk_topic_lesson, ON DELETE CASCADE]
slb_topics (1) ──── (N) slb_topics [parent_id self-ref] [FK: fk_topic_parent, ON DELETE CASCADE]
slb_topics (N) ──── (N) slb_competencies               [via slb_topic_competency_jnt]
slb_competencies (1) ── (N) slb_competencies [self-ref] [FK: fk_competency_parent, ON DELETE CASCADE]
slb_bloom_taxonomy (1) ─ (N) slb_cognitive_skill        [FK: fk_cog_bloom, ON DELETE SET NULL]
slb_cognitive_skill (1) ─ (N) slb_ques_type_specificity [FK: fk_quesTypeSps_cognitive, ON DELETE SET NULL]
slb_lessons (1) ──── (N) slb_syllabus_schedule          [via lesson_id]
slb_topics (1) ──── (N) slb_syllabus_schedule           [FK: fk_sylsched_topic, ON DELETE CASCADE]
slb_topic_level_types (1) ─ (N) slb_topics              [FK: fk_topic_level, ON DELETE RESTRICT]
```

### 5.3 External FK Dependencies

| Column | References | On Delete |
|--------|------------|-----------|
| `slb_lessons.academic_session_id` | `sch_org_academic_sessions_jnt.id` | RESTRICT |
| `slb_lessons.class_id` | `sch_classes.id` | CASCADE |
| `slb_lessons.subject_id` | `sch_subjects.id` | CASCADE |
| `slb_lessons.bok_books_id` | `bok_books.id` (SyllabusBooks module) | (implicit) |
| `slb_topics.class_id` | `sch_classes.id` | CASCADE |
| `slb_topics.subject_id` | `sch_subjects.id` | CASCADE |
| `slb_competencies.class_id` | `sch_classes.id` | CASCADE |
| `slb_competencies.subject_id` | `sch_subjects.id` | CASCADE |
| `slb_syllabus_schedule.assigned_teacher_id` | `sch_teachers.id` | SET NULL |
| `slb_syllabus_schedule.section_id` | `sch_sections.id` | CASCADE |

### 5.4 Model Audit Summary

| Model File | SoftDeletes | created_by in $fillable | Issues |
|-----------|------------|------------------------|--------|
| `Competencie.php` | NO (CRITICAL) | NO | Missing SoftDeletes trait; missing `deleted_at` cast; missing `created_by` in `$fillable`; class name is a typo |
| `Topic.php` | YES | NO | Missing `created_by`; `is_assessable` missing from `$fillable` |
| `Lesson.php` | YES | NO | Missing `created_by` |
| `BloomTaxonomy.php` | YES | YES | OK |
| `CompetencyType.php` | YES | YES | OK |
| `SyllabusSchedule.php` | YES | YES | OK |
| `TopicLevelType.php` | YES | YES | OK |
| `StudyMaterial.php` | Unknown | Unknown | No controller/routes |
| `StudyMaterialType.php` | Unknown | Unknown | No controller/routes |

---

## 6. API Endpoints & Routes

### 6.1 Route Group Configuration

```
File: routes/tenant.php (line 999)
Prefix: syllabus
Name prefix: syllabus.
Middleware: ['auth', 'verified']   ← MISSING: EnsureTenantHasModule
```

### 6.2 Lesson Routes

| Method | Route | Controller Method | Auth | Status |
|--------|-------|------------------|------|--------|
| GET | `syllabus/lesson` | `LessonController@index` | Gate::any() | ✅ |
| POST | `syllabus/lesson` | `LessonController@store` | Gate (partial) | 🟡 |
| GET | `syllabus/lesson/{id}` | `LessonController@show` | Gate (partial) | 🟡 |
| PUT | `syllabus/lesson/{id}` | `LessonController@update` | Gate (partial) | 🟡 |
| DELETE | `syllabus/lesson/{id}` | `LessonController@destroy` | Gate (partial) | 🟡 |
| GET | `syllabus/lesson/view/{id}` | `LessonController@view` | Gate (partial) | 🟡 |
| GET | `syllabus/lesson/trash/view` | `LessonController@trashed` | Gate (partial) | 🟡 |
| GET | `syllabus/lesson/{id}/restore` | `LessonController@restore` | Gate (partial) | 🟡 |
| DELETE | `syllabus/lesson/{id}/force-delete` | `LessonController@forceDelete` | Gate (partial) | 🟡 |
| POST | `syllabus/lesson/{lesson}/toggle-status` | `LessonController@toggleStatus` | Gate (partial) | 🟡 |
| POST | `syllabus/lessons/check-duplicate` | `LessonController@checkDuplicate` | — | 🟡 |
| POST | `syllabus/lessons/update-order` | `LessonController@updateOrder` | — | 🟡 |
| POST | `syllabus/lesson/validate-file` | `LessonController@validateImportFile` | — | ✅ |
| POST | `syllabus/lesson/start-import` | `LessonController@startImport` | — | ✅ |
| GET | `syllabus/get-subject` | `LessonController@getSubject` | — | ✅ |
| GET | `syllabus/get-teachers` | `LessonController@getClassTeachers` | — | ✅ |
| GET | `syllabus/get/books` | `LessonController@getBooks` | — | ✅ |

### 6.3 Topic Routes

| Method | Route | Controller Method | Auth | Status |
|--------|-------|------------------|------|--------|
| GET | `syllabus/topic` | `TopicController@index` | Gate::authorize('tenant.topic.view') | ✅ |
| POST | `syllabus/topic` | `TopicController@store` | ❌ None | ❌ |
| GET | `syllabus/topic/{id}` (show) | `TopicController@show` | ❌ None | ❌ |
| PUT | `syllabus/topic/{id}` | `TopicController@update` | ❌ None | ❌ |
| DELETE | `syllabus/topic/{id}` | `TopicController@destroy` | Gate::authorize('tenant.topic.delete') | 🟡 forceDelete |
| POST | `syllabus/update-hierarchy` | `TopicController@updateHierarchy` | Gate::authorize('tenant.topic.update') | ✅ |
| GET | `syllabus/topic/view/{id}` | `TopicController@view` | ❌ None | ❌ |
| GET | `syllabus/topic/trash/view` | `TopicController@trashed` | ❌ None | ❌ |
| GET | `syllabus/topic/{id}/restore` | `TopicController@restore` | ❌ None | ❌ |
| POST | `syllabus/topics/check-duplicate` | `TopicController@checkDuplicate` | ❌ None | ❌ |
| POST | `syllabus/topic/{topic}/toggle-status` | `TopicController@toggleStatus` | ❌ None | ❌ |
| GET | `syllabus/topic-levels` | `TopicController@getTopicLevels` | ❌ None | ❌ |

### 6.4 Competency Routes

| Method | Route | Controller Method | Auth | Status |
|--------|-------|------------------|------|--------|
| GET | `syllabus/competencies` | `CompetencieController@index` | ❌ ZERO | ❌ |
| POST | `syllabus/competencies` | `CompetencieController@store` | ❌ ZERO | ❌ |
| GET | `syllabus/competencies/{id}` | `CompetencieController@show` | ❌ ZERO | ❌ |
| PUT | `syllabus/competencies/{id}` | `CompetencieController@update` | ❌ ZERO | ❌ |
| DELETE | `syllabus/competencies/{id}` | `CompetencieController@destroy` | ❌ ZERO | ❌ |
| GET | `syllabus/competencies/parents/data` | `CompetencieController@getParentCompetencies` | ❌ ZERO | ❌ |
| GET | `syllabus/competencies/by/filter` | `CompetencieController@getByFilter` | ❌ ZERO | ❌ |
| POST | `syllabus/competencies/update/hierarchy` | `CompetencieController@updateHierarchy` | ❌ ZERO | ❌ |

### 6.5 Schedule & Reference Data Routes

| Resource | Controller | Auth Status |
|----------|-----------|-------------|
| `syllabus-schedule` | `SyllabusScheduleController` | ✅ Has auth |
| `competency-type` | `CompetencyTypeController` | ✅ Has auth |
| `topic-competency` | `TopicCompetencyController` | 🟡 Partial |
| `bloom-taxonomy` | `BloomTaxonomyController` | ✅ Has auth |
| `cognitive-skill` | `CognitiveSkillController` | ✅ Has auth |
| `question-type` | `QuestionTypeController` | ✅ Has auth |
| `question-type-specificity` | `QuestionTypeSpecificityController` | ✅ Has auth |
| `complexity-level` | `ComplexityLevelController` | ✅ Has auth |
| `performance-category` | `PerformanceCategoryController` | 🟡 Unknown |
| `grade-division` | `GradeDivisionController` | 🟡 Unknown |

### 6.6 SyllabusController Navigation Routes (Stub — Empty)

| Method | Route | Name | Status |
|--------|-------|------|--------|
| GET | `syllabus/master` | `syllabus.master.index` | ❌ Empty stub |
| GET | `syllabus/bloom` | `syllabus.bloom.index` | ❌ Empty stub |
| GET | `syllabus/planning` | `syllabus.planning.index` | ❌ Empty stub |
| GET | `syllabus/report` | `syllabus.report.index` | ❌ Empty stub |
| POST | `syllabus/planning/update-dates/{id}` | `syllabus.lesson.updatePlanningDates` | ❌ Empty stub |

---

## 7. UI Screens

### SCR-SLB-01: Lesson Management Page ✅
- Filter bar: Academic Session, Class, Subject
- Data table: code, name, ordinal, estimated_periods, weightage, status, actions
- Actions: Edit (modal), View Detail, Soft-Delete, Restore (from trash), Force-Delete
- Import panel: file upload → validate → preview errors → confirm import
- Drag-and-drop ordinal reordering via sortable JS

### SCR-SLB-02: Topic Hierarchy Page ✅
- Left panel: Lesson selector (Class → Subject → Lesson cascade dropdowns)
- Right panel: Nestable drag-and-drop tree (jqTree/SortableJS) showing topic hierarchy
- Add topic: slide-in form with level selector, parent selector, name, duration, objectives
- Edit: inline or modal
- Colour-coded level badges; `duration_minutes` and `weightage_in_lesson` visible inline
- Release flags toggle: release_quiz_on_completion, release_quest_on_completion

### SCR-SLB-03: Competency Framework Page 🟡
- Same tree structure as topics
- Filter by Class and Subject (cascade dropdowns)
- Competency type badge (KNOWLEDGE/SKILL/ATTITUDE) with domain colour
- NEP ref and NCF alignment displayed in expand row
- Add/Edit via modal with `CompetencyRequest` validation

### SCR-SLB-04: Topic-Competency Mapping Page 🟡
- Left: Topic tree (filtered by lesson)
- Right: Competency assignment panel — multi-select competencies with weightage field
- Primary competency radio selector
- Save updates `slb_topic_competency_jnt`

### SCR-SLB-05: Syllabus Schedule / Planning Page ❌ (stub exists)
- Gantt-chart view: X-axis = dates, Y-axis = topics
- Colour bands: scheduled (blue), in-progress (orange), completed (green), overdue (red)
- Filter: Class, Section, Subject, Teacher
- Click topic cell: open update modal to set `taught_by_teacher_id` and mark as delivered
- Coverage percentage badge per class+subject in header

### SCR-SLB-06: Coverage Report Page ❌ (stub exists)
- Summary cards: Overall coverage %, Taught topics count, Pending topics count
- Table: Class | Subject | Total Topics | Taught | Remaining | Coverage %
- Drill-down: click row to see topic-level breakdown
- Export to Excel/PDF

### SCR-SLB-07: Bloom's Distribution Dashboard ❌ (stub exists)
- Bar chart per class/subject: how many topics at each Bloom level
- LOT vs HOT ratio indicator
- Filter: Class, Subject

### SCR-SLB-08: Master Data Hub ❌ (stub exists)
- Tabbed layout: Bloom Taxonomy | Cognitive Skills | Question Types | Complexity Levels | Performance Categories | Grade Divisions
- Quick-edit modals for reference data
- Counts and status indicators per category

### SCR-SLB-09: Performance Categories & Grade Divisions Page 🟡
- Two sub-sections: Performance Categories and Grade Divisions
- Performance: band list with colour swatches, min/max sliders, AI severity dropdown
- Overlap detection: real-time validation prevents conflicting ranges
- Grade Division: toggle GRADE/DIVISION system per class group
- `is_locked` indicator after result publication

---

## 8. Business Rules

**BR-SLB-01:** A lesson `code` must be globally unique (`UNIQUE KEY uq_lesson_code`). Auto-generation follows `<CLASS_CODE>_<SUBJECT_CODE>_L<NN>` (zero-padded sequential per class+subject).

**BR-SLB-02:** A topic's `level` must equal `parent.topicLevelType.level + 1`. A topic with `level = 0` must have `parent_id = NULL`.

**BR-SLB-03:** A topic that has existing child topics cannot have its `level_id` changed. The system must return HTTP 422 with the message "Cannot change level of a topic that has children."

**BR-SLB-04:** Circular competency parent assignments are blocked: a competency cannot be its own parent, and a direct parent-child swap is blocked. Deep circular detection (e.g., A→B→C→A) must be handled in a proposed `CompetencyService::detectCircularParent()` method (currently only 1-level check exists).

**BR-SLB-05:** Topics linked to active quizzes (`lms_quizzes.scope_topic_id`) cannot be force-deleted. Soft delete is permitted. ✅ Quiz check exists; ❌ Schedule check is missing.

**BR-SLB-06:** `slb_topic_competency_jnt` enforces `UNIQUE(topic_id, competency_id)` — a competency can only be mapped to a topic once.

**BR-SLB-07:** Performance category `min_percentage` and `max_percentage` ranges must not overlap within the same `scope + class_id` combination. Validation must be enforced at the application/service layer (the DB schema does not enforce this — documented in DDL comments).

**BR-SLB-08:** Bloom taxonomy levels 1–3 are Lower Order Thinking (LOT); levels 4–6 are Higher Order Thinking (HOT). The ratio is used by the LMS-Exam engine for paper balancing.

**BR-SLB-09:** Every lesson must be linked to a textbook (`bok_books_id` is NOT NULL FK). Lessons without a book reference cannot be created.

**BR-SLB-10:** System-defined lessons (`is_system_defined = 1` in `hpc_lesson_version_control`) have `is_editable = 0` and cannot be modified by school staff.

**BR-SLB-11:** `slb_grade_division_master.is_locked` is set to `1` after results are published for the academic session. Once locked, grade division records cannot be edited or deleted.

**BR-SLB-12:** `slb_topics.analytics_code` is set once on creation (mirrors `code`) and is never updated — it is the stable identifier for cross-year analytics.

**BR-SLB-13:** The `scheduled_year_week` on lessons uses MySQL's `YEARWEEK()` format (YYYYWW). Week 1 of 2026 = `202601`.

**BR-SLB-14:** The `path` field on topics is a materialized path (`/parentId/grandParentId/`) enabling efficient subtree queries without recursive CTEs. The `path` is updated automatically in the `Topic::booted() static::created()` hook by replacing the `TEMP/` placeholder.

**BR-SLB-15:** The `CompetencieController::store()` currently uses `$request->all()` instead of `$request->validated()`. This MUST be treated as a P0 security defect — it bypasses the `CompetencyRequest` FormRequest's validated output even though the FormRequest is injected and runs correctly.

---

## 9. Workflows

### WF-SLB-01: Curriculum Setup Workflow (Happy Path)

```
1. Admin configures topic level types (SCR-SLB-08)
2. Admin/Coordinator creates lessons for Class + Subject + Book
3. Teacher creates root topics (level 0) under each lesson
4. Teacher adds sub-topics (level 1+) under each topic
5. Teacher maps competencies to each assessable topic
6. Academic Coordinator publishes lesson schedule (assigns dates in slb_syllabus_schedule)
7. Teacher marks topics as taught (sets taught_by_teacher_id)
8. System computes coverage % per class/subject
9. Reports available to Admin, Coordinator, Parents
```

### WF-SLB-02: Competency Deletion Safety Check

```
1. DELETE /syllabus/competencies/{id}
2. Controller checks: competency.children().exists() → if yes, return 422
3. (PROPOSED) Controller checks: topic_competency_jnt where competency_id = id → if active links, return 422
4. Soft delete (sets deleted_at)
5. Activity log entry created
6. JSON success response
```

### WF-SLB-03: Topic Release on Completion

```
1. Teacher marks topic as taught in slb_syllabus_schedule
2. TopicReleaseControlService::checkAndRelease(topic_id) called
3. If topic.release_quiz_on_completion = 1 → trigger LmsQuiz activation
4. If topic.release_quest_on_completion = 1 → trigger LmsQuest activation
5. Notification dispatched to enrolled students
```

### WF-SLB-04: Bulk Lesson/Topic Import

```
1. User uploads XLSX/CSV via import form
2. POST /syllabus/lesson/validate-file (or /topic/validate-file)
3. LessonImport / TopicImport dry-run validates each row
4. Returns text file listing errors with row numbers
5. User reviews errors, fixes file if needed
6. User confirms: POST /syllabus/lesson/start-import
7. Session-stored file path retrieved and full import committed
8. Success count and error count returned as JSON
```

---

## 10. Non-Functional Requirements

### 10.1 Performance

| Metric | Target | Notes |
|--------|--------|-------|
| Topic tree load (`getTopicsByLesson`) | < 500ms | For lessons with ≤200 topics using materialized path |
| Lesson page load (`index`) | < 1,000ms | Current: 20+ queries on every load (PERF-04); must be refactored |
| Bulk import (500 lessons) | < 30 seconds | Chunked via `Maatwebsite\Excel` |
| Competency tree (3 levels) | < 300ms | Currently unbounded recursive query (PERF-05) |
| Coverage calculation | < 2,000ms | For schools with up to 2,000 scheduled topics |

### 10.2 Scalability

- `slb_topics.path` (materialized path) enables efficient subtree queries without recursive CTEs — existing index `idx_topic_parent` supports this
- Composite indexes `(class_id, subject_id)` on both lessons and topics support filtered queries
- `analytics_code` on topics is unique and indexed for cross-module analytics lookups
- `TopicController::getDescendantIds()` must have a depth limit (currently unbounded, PERF-05)

### 10.3 Data Integrity

- UUID on `slb_lessons` and `slb_topics` for cross-database analytics tracking (BINARY 16)
- Cascade delete: topic children auto-deleted when parent is deleted via FK `ON DELETE CASCADE`
- Lesson cascade: topics auto-deleted when lesson is deleted (`ON DELETE CASCADE`)
- Soft delete `deleted_at` column exists on ALL tables (but `Competencie` model does NOT use the SoftDeletes trait — critical gap)
- `UNIQUE KEY uq_topic_analytics_code (analytics_code)` prevents duplicate analytics identifiers

### 10.4 Security

| Requirement | Status |
|-------------|--------|
| All tenant routes require `['auth', 'verified']` middleware (route-level) | ✅ |
| `EnsureTenantHasModule` middleware on Syllabus route group | ❌ MISSING |
| `Gate::authorize()` on all CompetencieController methods | ❌ ZERO |
| `Gate::authorize()` on all TopicController non-index methods | ❌ Partial |
| `$request->validated()` used (not `$request->all()`) in all store/update | ❌ CompetencieController uses `$request->all()` |
| CSRF protection on all POST/PUT/DELETE routes | ✅ (Laravel default) |
| Rate limiting on import endpoints | ❌ Missing |
| Error messages sanitised (no internal details exposed) | ❌ `$e->getMessage()` in TopicController line 359 |

### 10.5 Maintainability

- Service layer required: `SyllabusService`, `CompetencyMappingService`, `CoverageAnalyticsService`
- Fat controller issue: `LessonController::index()` loads 20+ variables including full `Topic::get()` and `Competencie::all()` on every page load — must be paginated/lazy-loaded
- Zero test coverage means all future changes carry high regression risk

---

## 11. Dependencies

### 11.1 Inbound Dependencies (What SLB consumes)

| Module | Dependency | Tables/Models |
|--------|-----------|---------------|
| SchoolSetup | FK dependency | `sch_classes`, `sch_subjects`, `sch_teachers`, `sch_sections` |
| SyllabusBooks | FK dependency | `bok_books.id` referenced by `slb_lessons.bok_books_id` |
| SchoolSetup | Session reference | `sch_org_academic_sessions_jnt.id` |

### 11.2 Outbound Dependencies (What consumes SLB)

| Module | Consumes | Description |
|--------|---------|-------------|
| LmsQuiz | `slb_topics` | `lms_quizzes.scope_topic_id` references topics |
| LmsExam | `slb_topics`, `slb_competencies` | Exam papers reference topics and competencies for question selection |
| QuestionBank | `slb_topics`, `slb_competencies`, `slb_bloom_taxonomy`, `slb_cognitive_skill` | All question tagging uses SLB reference data |
| Recommendation | `slb_topics`, `slb_performance_categories` | Recommendation rules reference topics and performance bands |
| HPC (Health Profile Card) | `slb_competencies`, `slb_topic_competency_jnt` | Student competency progress from topic-competency mappings |
| LmsHomework | `slb_topics`, `slb_lessons` | Homework assignments linked to syllabus topics |
| SmartTimetable | `slb_syllabus_schedule` | Period allocation context from syllabus schedule |
| Auth | Spatie Permission | RBAC gates access to all SLB operations |

---

## 12. Test Scenarios

### 12.1 Lesson Controller Tests

| Test ID | Type | Scenario | Expected |
|---------|------|---------|----------|
| T-SLB-L01 | Feature | Unauthenticated GET /syllabus/lesson | Redirect to login (401) |
| T-SLB-L02 | Feature | POST lesson without `class_id` | HTTP 422 with validation error |
| T-SLB-L03 | Feature | POST duplicate lesson `code` | HTTP 422 unique constraint error |
| T-SLB-L04 | Feature | DELETE active lesson → GET trashed → restore | Soft delete and restore lifecycle |
| T-SLB-L05 | Feature | POST /lesson/validate-file with malformed XLSX | Returns text error report without committing |
| T-SLB-L06 | Feature | toggleStatus sets is_active=0 | Lesson excluded from student view queries |

### 12.2 Topic Controller Tests

| Test ID | Type | Scenario | Expected |
|---------|------|---------|----------|
| T-SLB-T01 | Feature | POST topic with level=1 and null parent_id | HTTP 422 parent required |
| T-SLB-T02 | Feature | POST topic with level=0 and valid parent_id | HTTP 422 root topics cannot have parent |
| T-SLB-T03 | Feature | DELETE topic with active quiz linked | HTTP 422 "quizzes are assigned" |
| T-SLB-T04 | Feature | DELETE topic with children | HTTP 422 "has child topics" |
| T-SLB-T05 | Feature | DELETE topic (no children, no quiz) | After fix: soft delete (not forceDelete) |
| T-SLB-T06 | Feature | POST update-hierarchy with valid nested JSON | Returns 200; parent_id updated in DB |
| T-SLB-T07 | Unit | Topic::generateHierarchicalCode for level 0 | Returns `CLASSCODE_SUBJCODE_LESCODE_TOP01` |
| T-SLB-T08 | Unit | Topic::ancestors() returns ordered list | Returns topics sorted by level ASC |
| T-SLB-T09 | Feature | Store topic without auth | After fix: HTTP 403 |

### 12.3 Competency Controller Tests

| Test ID | Type | Scenario | Expected |
|---------|------|---------|----------|
| T-SLB-C01 | Feature | GET /syllabus/competencies unauthenticated | After fix: HTTP 401 |
| T-SLB-C02 | Feature | POST competency with valid data | After fix: HTTP 201 using $request->validated() |
| T-SLB-C03 | Feature | POST competency with parent_id = own id | HTTP 422 "cannot be its own parent" |
| T-SLB-C04 | Feature | DELETE competency with children | HTTP 422 "has child competencies" |
| T-SLB-C05 | Feature | DELETE competency (no children) | After fix: soft delete; deleted_at populated |
| T-SLB-C06 | Feature | POST competency with arbitrary unknown field | After fix: unknown field ignored (validated) |
| T-SLB-C07 | Feature | POST update/hierarchy with valid tree JSON | Returns 200; parent_id values updated |

### 12.4 Coverage Analytics Tests

| Test ID | Type | Scenario | Expected |
|---------|------|---------|----------|
| T-SLB-A01 | Unit | Coverage = 0 when no topics taught | getCoverageByClassSubject returns 0.0 |
| T-SLB-A02 | Unit | Coverage = 100 when all assessable topics taught | Returns 100.0 |
| T-SLB-A03 | Unit | Topics with can_use_for_syllabus_status=0 excluded | Not counted in denominator or numerator |
| T-SLB-A04 | Feature | GET /syllabus/report → shows coverage table | Page renders with correct percentages |

### 12.5 Business Rule Tests

| Test ID | Type | Scenario | Expected |
|---------|------|---------|----------|
| T-SLB-B01 | Unit | Performance category ranges overlap on same scope | Service rejects insert with error |
| T-SLB-B02 | Unit | Grade division is_locked after result publish | Update returns 422 |
| T-SLB-B03 | Feature | Create lesson without bok_books_id | HTTP 422 book required |
| T-SLB-B04 | Feature | Topic-competency mapping with duplicate pair | HTTP 422 unique constraint |
| T-SLB-B05 | Feature | EnsureTenantHasModule: tenant without SLB module | After fix: HTTP 403 on all syllabus routes |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Lesson | A chapter or unit of study. Top-level curriculum unit linked to a textbook chapter. Also called a "Chapter" in school contexts. |
| Topic | A sub-unit of a lesson. Can be hierarchically nested (Topic → Sub-Topic → Mini Topic etc.) |
| Materialized Path | Storage pattern where each node in a tree stores the IDs of all its ancestors (e.g., `/1/5/23/`), enabling efficient subtree queries without recursion. |
| Competency | A measurable skill or knowledge element aligned to NEP 2020 and National Curriculum Framework (NCF). |
| NEP 2020 | National Education Policy 2020 — India's educational framework governing curriculum, assessment, and competency standards. |
| NCF | National Curriculum Framework — the detailed curriculum document derived from NEP 2020. |
| Bloom's Taxonomy | A classification of cognitive learning objectives into six hierarchical levels: Remember, Understand, Apply, Analyse, Evaluate, Create. |
| LOT | Lower Order Thinking — Bloom's levels 1–3 (Remember, Understand, Apply). |
| HOT | Higher Order Thinking — Bloom's levels 4–6 (Analyse, Evaluate, Create). |
| Syllabus Coverage | The percentage of scheduled, assessable topics that have been marked as taught by a teacher. |
| Performance Category | A score band definition (e.g., TOPPER = 90–100%) with AI action recommendation (ACCELERATE, REMEDIATE etc.). |
| Grade Division | A pass/grade classification system (GRADE: A/B/C or DIVISION: First/Second/Third) applied per class group. |
| analytics_code | An immutable unique code on each topic, set at creation, used as a stable cross-year analytics identifier. |
| Topic Level Type | Configuration record that names each level in the topic hierarchy (e.g., level 0 = "Topic", level 1 = "Sub-Topic"). |
| Competencie (typo) | The misspelled class/model name in V1 code. Proposed to rename to `Competency` in V2. |
| EnsureTenantHasModule | Laravel middleware class that verifies the current tenant has an active subscription to the requested module before allowing access. |

---

## 14. Suggestions & Proposed Improvements

### 14.1 P0 — Critical (Fix Before Any Release)

**SUG-SLB-P0-01: Add Gate::authorize() to ALL CompetencieController methods**
- File: `Modules/Syllabus/app/Http/Controllers/CompetencieController.php`
- Add at top of each method: `Gate::authorize('tenant.competencies.<action>')`
- Methods affected: index, store, show, update, destroy, getParentCompetencies, getCompetencyTree, getByFilter, updateHierarchy

**SUG-SLB-P0-02: Replace $request->all() with $request->validated() in CompetencieController::store()**
- Lines 137 and 146: `$request->all()` → `$request->validated()`
- The `CompetencyRequest` FormRequest is already injected and validated; the fix is a 2-character change

**SUG-SLB-P0-03: Add SoftDeletes to Competencie model**
- File: `Modules/Syllabus/app/Models/Competencie.php`
- Add `use SoftDeletes;` trait
- Add `'deleted_at' => 'datetime'` to `$casts`
- Add `'created_by'` to `$fillable`

**SUG-SLB-P0-04: Fix TopicController::destroy() to use soft delete**
- Line 525: `Topic::findOrFail($id)->forceDelete()` → `Topic::findOrFail($id)->delete()`
- The existing force-delete route `/topic/{id}/force-delete` already handles explicit permanent deletion

**SUG-SLB-P0-05: Add EnsureTenantHasModule middleware to Syllabus route group**
- File: `routes/tenant.php` line 999
- Change: `Route::middleware(['auth', 'verified'])` → `Route::middleware(['auth', 'verified', EnsureTenantHasModule::class . ':SLB'])`

### 14.2 P1 — High (Fix Before Production Release)

**SUG-SLB-P1-01: Add Gate::authorize() to remaining TopicController methods**
- Methods without auth: store, show, update, view, trashed, restore, toggleStatus, checkDuplicate, getTopicLevels, getTopicsByLevelFilter, validateImportFile, startImport

**SUG-SLB-P1-02: Add activity logging to CompetencieController and TopicController**
- All CRUD mutations (store, update, destroy) must call `activityLog()` matching the pattern used in BloomTaxonomyController

**SUG-SLB-P1-03: Create CoverageAnalyticsService and implement SyllabusController**
- New service: `Modules/Syllabus/app/Services/CoverageAnalyticsService.php`
- Implement `SyllabusController@master`, `@bloom`, `@planning`, `@report` methods
- Routes are already registered; only implementation is missing

**SUG-SLB-P1-04: Add syllabus schedule reference check before topic delete**
- In `TopicController::destroy()`: before soft delete, check `SyllabusSchedule::where('topic_id', $id)->exists()` → if true, warn user (do not block; soft delete is safe, but UI should inform)

**SUG-SLB-P1-05: Fix LessonController::index() over-fetching**
- Remove `Topic::get()` and `Competencie::all()` from index (PERF-01/02)
- Replace with paginated AJAX calls from the view (topic and competency dropdowns should use the existing AJAX endpoints)

**SUG-SLB-P1-06: Add created_by to Competencie, Topic, and Lesson models $fillable**

### 14.3 P2 — Medium (Fix Soon)

**SUG-SLB-P2-01: Add depth limit to recursive getDescendantIds()**
- TopicController line 595: add `if ($depth > 9) return $ids;` guard

**SUG-SLB-P2-02: Replace session-based import with signed URLs**
- TopicController startImport() (lines 244–272) uses session state to locate the validated file
- Concurrent requests can collide; replace with signed temporary URL to the validated file

**SUG-SLB-P2-03: Add rate limiting to import endpoints**
- `throttle:10,1` (10 requests per minute) on validate-file and start-import routes

**SUG-SLB-P2-04: Sanitise error messages in catch blocks**
- TopicController line 359: replace `$e->getMessage()` with a generic error message; log internally

**SUG-SLB-P2-05: Implement StudyMaterialController and views**
- Models `StudyMaterial` and `StudyMaterialType` exist; build CRUD with `sys_media` polymorphic upload

**SUG-SLB-P2-06: Wrap CompetencieController::store() and updateHierarchy() in DB::transaction()**

### 14.4 P3 — Low (Backlog)

**SUG-SLB-P3-01: Rename Competencie → Competency throughout**
- Single PR: rename model file, controller file, update all use statements and route model bindings
- Route `competencies.` is already correct; only PHP class names need updating
- Coordinate with any views referencing the old class name

**SUG-SLB-P3-02: Build CompetencyMappingService**
- Encapsulate: `mapTopicToCompetency()`, `unmapTopicFromCompetency()`, `getTopicCompetencyMap()`, `detectCircularParent()`

**SUG-SLB-P3-03: Implement Lesson Version Control (hpc_lesson_version_control)**
- Table already defined in DDL; build model, controller, and routes
- Lock system-defined lessons from school edits

**SUG-SLB-P3-04: Write Feature and Unit tests**
- Minimum: 5 tests per controller, covering auth, validation, CRUD, and edge cases
- Priority order: CompetencyTest → TopicHierarchyTest → LessonTest → CoverageAnalyticsTest

**SUG-SLB-P3-05: Add REST API endpoints for Student/Parent Portal consumption**
- `GET /api/v1/syllabus/lessons?class_id=&subject_id=` — published lessons list
- `GET /api/v1/syllabus/topics/{lesson_id}` — topic tree for a lesson
- `GET /api/v1/syllabus/coverage?class_id=&subject_id=&session_id=` — coverage percentage
- All API endpoints: `auth:sanctum` + `EnsureTenantHasModule` middleware

---

## 15. Appendices

### 15.1 Controller Method Count

| Controller | Methods | Auth Coverage |
|-----------|---------|---------------|
| LessonController | 18 | 🟡 ~50% of methods |
| TopicController | 25+ | 🟡 ~20% of methods (index, destroy, updateHierarchy) |
| CompetencieController | 9 | ❌ 0% |
| CompetencyTypeController | 8 | ✅ ~90% |
| BloomTaxonomyController | 8 | ✅ ~90% |
| CognitiveSkillController | 8 | ✅ ~90% |
| QuestionTypeController | 8 | ✅ ~90% |
| QuestionTypeSpecificityController | 8 | ✅ ~90% |
| ComplexityLevelController | 8 | ✅ ~90% |
| SyllabusController | 7 | ❌ 0% (all empty stubs) |
| SyllabusScheduleController | 8 | ✅ ~90% |
| TopicCompetencyController | 8 | 🟡 ~60% |
| TopicLevelTypeController | 6 | ✅ ~80% |
| PerformanceCategoryController | 6 | 🟡 Unknown |
| GradeDivisionController | 6 | 🟡 Unknown |

### 15.2 Model File → Table Mapping

| Model File | Table | SoftDeletes |
|-----------|-------|-------------|
| `Lesson.php` | `slb_lessons` | YES |
| `Topic.php` | `slb_topics` | YES |
| `Competencie.php` | `slb_competencies` | NO (CRITICAL) |
| `CompetencyType.php` | `slb_competency_types` | YES |
| `TopicCompetency.php` | `slb_topic_competency_jnt` | YES |
| `BloomTaxonomy.php` | `slb_bloom_taxonomy` | YES |
| `CognitiveSkill.php` | `slb_cognitive_skill` | YES |
| `QueTypeSpecifity.php` | `slb_ques_type_specificity` | YES (note filename typo: Specifity) |
| `ComplexityLevel.php` | `slb_complexity_level` | YES |
| `QuestionType.php` | `slb_question_types` | YES |
| `PerformanceCategory.php` | `slb_performance_categories` | YES |
| `GradeDivisionMaster.php` | `slb_grade_division_master` | YES |
| `SyllabusSchedule.php` | `slb_syllabus_schedule` | YES |
| `TopicLevelType.php` | `slb_topic_level_types` | YES |
| `TopicDependencies.php` | (unknown — likely `slb_topic_dependencies`) | Unknown |
| `StudyMaterial.php` | (TBD) | Unknown |
| `StudyMaterialType.php` | (TBD) | Unknown |
| `Book.php` | `bok_books` (SLK module) | YES |
| `BookAuthor.php` | `slb_book_authors` | YES |
| `AuthorBook.php` | `slb_book_author_jnt` | YES |
| `BookClassSubject.php` | `slb_book_class_subject_jnt` | YES |
| `BookTopicMapping.php` | (junction table) | YES |

### 15.3 FormRequest Inventory

| FormRequest | Used By | Notes |
|------------|---------|-------|
| `LessonRequest` | LessonController | OK |
| `TopicRequest` | TopicController | OK |
| `CompetencyRequest` | CompetencieController | EXISTS but store() ignores it (uses $request->all()) |
| `CompetencyTypeRequest` | CompetencyTypeController | OK |
| `TopicCompetencyRequest` | TopicCompetencyController | OK |
| `BloomTaxonomyRequest` | BloomTaxonomyController | OK |
| `CognitiveSkillRequest` | CognitiveSkillController | OK |
| `QuestionTypeRequest` | QuestionTypeController | OK |
| `QuestionTypeSpecificityRequest` | QuestionTypeSpecificityController | OK |
| `ComplexityLevelRequest` | ComplexityLevelController | OK |
| `SyllabusScheduleRequest` | SyllabusScheduleController | OK |
| `PerformanceCategoryRequest` | PerformanceCategoryController | OK |
| `GradeDivisionRequest` | GradeDivisionController | OK |
| `TopicLevelTypeRequest` | TopicLevelTypeController | OK |

### 15.4 Security Issue Register (from Gap Analysis)

| SEC-ID | Severity | Issue | Location |
|--------|---------|-------|---------|
| SEC-01 | CRITICAL | ZERO authorization on all CompetencieController methods | CompetencieController, all methods |
| SEC-02 | CRITICAL | ZERO authorization on all TopicController non-index methods | TopicController, ~22 methods |
| SEC-03 | CRITICAL | `$request->all()` mass assignment in store() | CompetencieController lines 137, 146 |
| SEC-04 | CRITICAL | Missing EnsureTenantHasModule on entire Syllabus route group | tenant.php line 999 |
| SEC-05 | HIGH | forceDelete() in TopicController::destroy() | TopicController line 525 |
| SEC-06 | HIGH | No activity logging on CompetencieController or TopicController | All CRUD methods |
| SEC-07 | HIGH | SyllabusController entirely empty — routes registered but dead | SyllabusController |
| SEC-08 | MEDIUM | Session-based import file retrieval is race-condition-prone | TopicController startImport() |
| SEC-09 | MEDIUM | No rate limiting on import endpoints | tenant.php |
| SEC-10 | MEDIUM | `$e->getMessage()` exposes internal exception details to client | TopicController line 359 |
| SEC-11 | LOW | `\Log::info('Duplicate Check:', $request->all())` leaks all input to log | LessonController ~line 701 |

---

## 16. V1 → V2 Delta

### 16.1 Corrections to V1

| V1 Claim | V2 Correction |
|----------|---------------|
| "TopicController has NO authentication checks in any method" | CORRECTED: TopicController DOES have `Gate::authorize('tenant.topic.view')` in `index()` and `Gate::authorize('tenant.topic.delete')` in `destroy()`, and `Gate::authorize('tenant.topic.update')` in `updateHierarchy()`. ~3 of 25+ methods have auth. |
| V1 listed 15 controllers without noting SyllabusController is empty | CLARIFIED: SyllabusController is 100% empty stub with registered routes pointing to it |
| V1 did not document TopicReleaseControlService | ADDED: Service exists at `Modules/Syllabus/app/Services/TopicReleaseControlService.php`; injected via TopicController constructor |
| V1 stated route prefix is `syllabus` | CONFIRMED from actual tenant.php: prefix = `syllabus`, name prefix = `syllabus.` |
| V1 did not document `getCompetencyTree` method | ADDED: method exists in CompetencieController; uses inline `$request->validate()` instead of FormRequest (medium issue) |

### 16.2 New Content in V2

| Section | New Content |
|---------|------------|
| FR-SLB-07 | Study Material Management specification (P2 feature) |
| FR-SLB-08 | Coverage Analytics & Dashboard specification |
| FR-SLB-09 | EnsureTenantHasModule middleware gap (CRITICAL) |
| Section 6 | Full route table with per-route auth status |
| Section 8 | BR-SLB-11 through BR-SLB-15 (5 new business rules) |
| Section 9 | WF-SLB-02 through WF-SLB-04 (3 new workflows) |
| Section 12 | Full test scenario inventory (25 test cases across 5 areas) |
| Section 14 | Structured P0/P1/P2/P3 fix plan with file paths and line references |
| Section 15.4 | Security issue register (11 issues with severity) |
| FR-SLB-03.3 | Competencie typo rename proposal with impact analysis |

### 16.3 Status Changes from V1 to V2

| Feature | V1 Status | V2 Status | Reason |
|---------|----------|----------|--------|
| Topic Delete | HIGH issue | CRITICAL fix (P0) | Confirmed: forceDelete() at line 525 |
| Competency Auth | CRITICAL | CRITICAL (confirmed) | Verified against actual code |
| TopicController Auth | "ZERO auth" | "Partial auth (~12%)" | index/destroy/updateHierarchy have auth |
| SyllabusController | "Unknown/likely stub" | "Confirmed empty stub" | All 5 methods are empty |
| TopicReleaseControlService | Not mentioned | Added to model section | Service is injected in constructor |

---

*Document generated from source: V1 requirement + gap analysis (2026-03-22) + code scan of `Modules/Syllabus/` + DDL `syllabus_ddl_v1.1.sql`*
*Next review: After P0 fixes are implemented — estimated 2026-04-05*
