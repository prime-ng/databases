# Syllabus Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** SLB | **Module Path:** `Modules/Syllabus`
**Module Type:** Tenant (Per-School) | **Database:** tenant_{uuid}
**Table Prefix:** `slb_*` | **Processing Mode:** FULL
**RBS Reference:** Module H — Academics Management (H1, H2, H6)

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Module Overview

### 1.1 Purpose

The Syllabus module is the **academic content management backbone** for each tenant school in the Prime-AI platform. It organizes curriculum into a hierarchy of Lessons → Topics → Sub-Topics (up to 5+ levels deep), maps content to NEP 2020 competencies and Bloom's Taxonomy, schedules when each topic is taught, and tracks coverage progress throughout the academic session.

This module directly powers the LMS-Quiz, LMS-Exam, and Question Bank modules by providing the topic-competency-taxonomy graph that governs question selection and assessment quality.

### 1.2 Module Position in the Platform

```
Platform Layer    Module             Database
──────────────────────────────────────────────────
Tenant (Per-School)  Syllabus (SLB)  tenant_{uuid}
                                        slb_lessons
                                        slb_topics
                                        slb_competencies
                                        slb_bloom_taxonomy
                                        slb_cognitive_skill
                                        slb_syllabus_schedule
```

### 1.3 Module Characteristics

| Attribute          | Value                                              |
|--------------------|----------------------------------------------------|
| Laravel Module     | `nwidart/laravel-modules` v12, name `Syllabus`     |
| Namespace          | `Modules\Syllabus`                                 |
| Module Code        | SLB                                                |
| Domain             | Tenant (school-specific subdomain)                 |
| DB Connection      | `tenant_mysql` (tenant_{uuid})                     |
| Table Prefix       | `slb_*`                                            |
| Auth               | Spatie Permission v6.21 via `Gate::any()`          |
| Frontend           | Bootstrap 5 + AdminLTE 4                           |
| Completion Status  | ~55%                                               |
| Controllers        | 15                                                 |
| Models             | 22                                                 |
| Services           | 0 (none yet)                                       |
| FormRequests       | 14                                                 |
| Tests              | 0                                                  |

### 1.4 Sub-Modules / Feature Areas

1. Lesson Management — Create, edit, import, schedule lessons per class/subject
2. Topic Hierarchy — Multi-level tree (Lesson → Topic → Sub-Topic → Mini-Topic → Micro-Topic)
3. Competency Framework — NEP 2020 aligned competency taxonomy (KNOWLEDGE, SKILL, ATTITUDE)
4. Bloom's Taxonomy — 6-level Revised Bloom's (Remember, Understand, Apply, Analyze, Evaluate, Create)
5. Cognitive Skills — LOT/HOT classification linked to Bloom levels
6. Question Taxonomy — Question type specificity, complexity levels, question types
7. Syllabus Schedule — Topic-to-date assignment with teacher tracking
8. Performance Categories — Score band definitions with AI severity tags
9. Grade Division Master — Grade band configuration per class

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Full CRUD + soft-delete lifecycle for lessons, topics, competencies, competency types
- Multi-level hierarchical topic tree with drag-and-drop reordering
- CSV/XLSX bulk import for lessons and topics with validation preview
- Competency mapping: associate one or more competencies to each topic with weightage
- Bloom's taxonomy and cognitive skill classification for assessments
- Syllabus schedule: assign topics to date ranges per class/section/subject
- Topic level type configuration (what each level in the hierarchy is called)
- Performance category and grade division setup used by LMS-Exam
- Question type, question type specificity, and complexity level master data
- Integration with SyllabusBooks: lesson references a `bok_books_id`

### 2.2 Out of Scope

- Actual homework creation and submission (handled in `LmsHomework` module)
- Quiz and exam question creation (handled in `LmsQuiz`, `LmsExam`, `QuestionBank` modules)
- LXP learning path management (handled in `LXP` module)
- Co-curricular activity tracking (different module)
- Study material file uploads (planned, `sys_media` or `StudyMaterial` model exists but upload UI incomplete)

### 2.3 RBS Reference Mapping

| RBS Section | RBS Feature | Syllabus Coverage |
|-------------|-------------|-------------------|
| H1.1 — Academic Session | F.H1.1 (Create Session) | Lessons reference `sch_org_academic_sessions_jnt` |
| H1.2 — Curriculum Mapping | F.H1.2.2 (Define Lesson Units) | `slb_lessons` with chapter structure |
| H2.1 — Lesson Plans | F.H2.1.1 (Create Lesson Plan) | `slb_lessons` with objectives and resources |
| H2.1 — Publish Lesson Plan | F.H2.1.2 (Track Completion) | `slb_syllabus_schedule` completion tracking |
| H2.2 — Digital Content | F.H2.2.1 (Upload Content) | `resources_json` field on lessons/topics |
| H6.1 — Skill Framework | F.H6.1.1 (Add Cognitive Skills) | `slb_cognitive_skill`, `slb_competencies` |
| H6.1 — Assign Skills | F.H6.1.2 (Map Skills to Units) | `slb_topic_competency_jnt` |

---

## 3. Actors and User Roles

### 3.1 Primary Actors

| Actor | Description | Access Level |
|-------|-------------|--------------|
| School Admin | Tenant administrator | Full CRUD on all SLB entities |
| Academic Coordinator | Manages curriculum and lesson plans | Full CRUD on lessons, topics, schedule |
| Subject Teacher | Creates lessons and maps topics for their subjects | Create/Edit own lessons, view others |
| Class Teacher | Views syllabus coverage and schedule | ViewAny only |
| Student | Reads published lesson objectives and schedule | Read-only via student portal |
| Parent | Views syllabus coverage progress | Read-only via parent portal |

### 3.2 Permission Naming Convention

Permissions follow `tenant.<resource>.<action>` pattern:
- `tenant.lesson.viewAny`, `tenant.lesson.create`, `tenant.lesson.update`, `tenant.lesson.delete`
- `tenant.topic.viewAny`, `tenant.topic.create`, `tenant.topic.update`, `tenant.topic.delete`
- `tenant.competencies.viewAny`, `tenant.competencies.create`, `tenant.competencies.update`, `tenant.competencies.delete`

---

## 4. Functional Requirements

### 4.1 Lesson Management (FR-SLB-01)

**FR-SLB-01.1 — Create Lesson**
- System shall allow creation of a lesson linked to Academic Session + Class + Subject + Book
- Lesson code is auto-generated as combination of class code, subject code, and a sequential lesson number (e.g., `9TH_SCI_L01`)
- Fields: name, short_name, ordinal, description, learning_objectives (JSON array), prerequisites (JSON array of lesson IDs), estimated_periods, weightage_in_subject, nep_alignment, resources_json (type/url/title), book_chapter_ref, scheduled_year_week
- UUID (BINARY 16) auto-assigned on creation for analytics tracking

**FR-SLB-01.2 — Lesson Ordering**
- Lessons shall be ordered by `ordinal` within a class-subject combination
- Drag-and-drop reordering available via `updateOrder` endpoint
- Ordinal is unique per class+subject scope

**FR-SLB-01.3 — Lesson Import**
- Bulk import via XLSX/CSV supported with two-step validation-then-import flow
- Validation step returns text file with per-row errors before any data is committed
- Import uses `Maatwebsite\Excel` package (LessonImport class)

**FR-SLB-01.4 — Lesson Soft Delete Lifecycle**
- Soft delete via `deleted_at`; records go to Trash
- Restore from Trash restores to active status
- Force-delete permanently removes record

**FR-SLB-01.5 — Toggle Status**
- `is_active` toggle available on each lesson; inactive lessons are hidden from student/parent views

### 4.2 Topic Hierarchy Management (FR-SLB-02)

**FR-SLB-02.1 — Topic Levels**
- Topics support a configurable hierarchy depth controlled by `slb_topic_level_types`
- Default max level = 4 (0=Topic, 1=Sub-Topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic); expandable to level 9
- Level type names (e.g., "Topic", "Sub-Topic") are configurable per school

**FR-SLB-02.2 — Create Topic**
- Fields: name, short_name, level, parent_id, lesson_id, class_id, subject_id, description, duration_minutes, weightage_in_lesson, learning_objectives (JSON), keywords (JSON), prerequisite_topic_ids (JSON), is_assessable
- Auto-generated fields: code (class+subject+lesson+topic path), analytics_code, path (materialized path e.g. `/1/5/23/`), path_names
- UUID (BINARY 16) auto-assigned

**FR-SLB-02.3 — Parent Validation**
- Level 0 (root) topics must have no parent
- Level N topics must have a parent at level N-1 within the same lesson
- Circular parent assignment is blocked at controller and model level
- Cannot change level of a topic that has existing children

**FR-SLB-02.4 — Topic Tree**
- `getTopicsByLesson` returns full recursive tree (up to 5 levels deep via eager loading `children.children.children.children.children`)
- `updateHierarchy` accepts serialized JSON tree for drag-and-drop persistence
- `getParentOptions` returns available parents for a given level within a lesson

**FR-SLB-02.5 — Topic Import**
- XLSX/CSV import with same two-step validation-then-commit flow as lessons
- Validates: topic_name (required), duration_minutes (numeric, >=0), weightage_in_lesson (0-100), active flag

**FR-SLB-02.6 — Topic Flags**
- `can_use_for_syllabus_status` — whether topic counts toward coverage percentage
- `release_quiz_on_completion` — auto-triggers quiz release when topic marked complete
- `release_quest_on_completion` — auto-triggers question release on completion

### 4.3 Competency Framework (FR-SLB-03)

**FR-SLB-03.1 — Competency Types**
- Master types: KNOWLEDGE, SKILL, ATTITUDE (configurable)
- Full CRUD via `CompetencyTypeController`

**FR-SLB-03.2 — Competency**
- Hierarchical competency tree (parent_id self-reference)
- Fields: code, name, short_name, description, class_id, subject_id, competency_type_id, domain (COGNITIVE/AFFECTIVE/PSYCHOMOTOR), nep_framework_ref, ncf_alignment, learning_outcome_code, path, level
- NEP 2020 and NCF (National Curriculum Framework) alignment codes stored for regulatory reporting
- Materialized path for performance

**FR-SLB-03.3 — Topic-Competency Mapping**
- Each topic may be linked to multiple competencies via `slb_topic_competency_jnt`
- Each mapping carries: weightage (how much the topic contributes to the competency), is_primary flag
- Managed via `TopicCompetencyController`

### 4.4 Bloom's Taxonomy & Cognitive Skills (FR-SLB-04)

**FR-SLB-04.1 — Bloom's Taxonomy**
- 6 levels: REMEMBERING (1), UNDERSTANDING (2), APPLYING (3), ANALYZING (4), EVALUATING (5), CREATING (6)
- `bloom_level` field enables ordering and LOT vs HOT classification
- Managed via `BloomTaxonomyController`

**FR-SLB-04.2 — Cognitive Skills**
- Each cognitive skill links to a parent `bloom_id`
- Examples: COG-KNOWLEDGE, COG-UNDERSTANDING, COG-SKILL
- Used for question tagging in Question Bank and automated paper generation

**FR-SLB-04.3 — Question Type Specificity**
- Links to a parent cognitive_skill_id
- Context types: IN_CLASS, HOMEWORK, SUMMATIVE, FORMATIVE
- Controls which question types are appropriate in which context

**FR-SLB-04.4 — Complexity Levels**
- EASY (1), MEDIUM (2), DIFFICULT (3)
- Used to balance question paper difficulty in LMS-Exam and Question Bank

**FR-SLB-04.5 — Question Types**
- Types: MCQ_SINGLE, MCQ_MULTI, SHORT_ANSWER, LONG_ANSWER, MATCH, NUMERIC, FILL_BLANK, CODING
- `has_options` flag and `auto_gradable` flag drive exam engine behavior

### 4.5 Syllabus Schedule (FR-SLB-05)

**FR-SLB-05.1 — Schedule Topic**
- Assign a topic to a date range (scheduled_start_date, scheduled_end_date) per class/section/subject
- Fields: academic_session_id, class_id, section_id, subject_id, lesson_id, topic_id, topic_level_type_id, assigned_teacher_id, taught_by_teacher_id, planned_periods, priority (HIGH/MEDIUM/LOW), notes

**FR-SLB-05.2 — Coverage Tracking**
- `taught_by_teacher_id` (actual teacher who taught) is set after delivery
- `can_use_for_syllabus_status` flag on topic determines if it counts toward coverage percentage
- Coverage percentage = completed assessable topics / total assessable topics × 100

**FR-SLB-05.3 — Schedule Management**
- Managed via `SyllabusScheduleController`
- Linked to the timetable for period allocation context

### 4.6 Performance Categories & Grade Divisions (FR-SLB-06)

**FR-SLB-06.1 — Performance Categories**
- Bands: TOPPER, EXCELLENT, GOOD, AVERAGE, BELOW_AVERAGE, NEED_IMPROVEMENT, POOR
- Per band: min_percentage, max_percentage, ai_severity (LOW/MEDIUM/HIGH/CRITICAL), ai_default_action (ACCELERATE/PROGRESS/PRACTICE/REMEDIATE/ESCALATE)
- Color code and icon for UI display
- Scope: SCHOOL-wide or CLASS-specific override

**FR-SLB-06.2 — Grade Division Master**
- Grade division defines how marks convert to grades (A+, A, B+, B, C, D, etc.)
- Linked to performance categories for consistency
- Per-class scoping available

---

## 5. Data Model

### 5.1 Primary Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `slb_topic_level_types` | Names for each level in the topic hierarchy | level, code, name, can_be_used_for_* flags |
| `slb_lessons` | Lesson/chapter master per class-subject | academic_session_id, class_id, subject_id, bok_books_id, code, ordinal, learning_objectives JSON, resources_json |
| `slb_topics` | Hierarchical topic tree | parent_id (self-ref), lesson_id, class_id, subject_id, path, path_names, level, code, analytics_code, learning_objectives JSON, keywords JSON, prerequisite_topic_ids JSON |
| `slb_competency_types` | Competency domain types | code, name |
| `slb_competencies` | NEP-aligned competency tree | parent_id, competency_type_id, domain ENUM, nep_framework_ref, ncf_alignment, learning_outcome_code, path |
| `slb_topic_competency_jnt` | Topic ↔ Competency mapping | topic_id, competency_id, weightage, is_primary |
| `slb_bloom_taxonomy` | Bloom's 6 levels | code, bloom_level (1-6) |
| `slb_cognitive_skill` | Cognitive skills linked to Bloom | bloom_id, code |
| `slb_ques_type_specificity` | Question usage context | cognitive_skill_id, code |
| `slb_complexity_level` | Question difficulty levels | code, complexity_level (1-3) |
| `slb_question_types` | Question format types | code, has_options, auto_gradable |
| `slb_performance_categories` | Score band definitions | level, min/max_percentage, ai_severity, ai_default_action, scope ENUM |
| `slb_grade_division_master` | Grade band master | (links to performance_categories) |
| `slb_syllabus_schedule` | Topic scheduling calendar | academic_session_id, class_id, section_id, lesson_id, topic_id, scheduled_start/end_date, taught_by_teacher_id |

### 5.2 Relationships

```
slb_lessons (1) ──── (N) slb_topics
slb_topics (1) ──── (N) slb_topics [parent_id self-ref]
slb_topics (N) ──── (N) slb_competencies [via slb_topic_competency_jnt]
slb_competencies (1) ──── (N) slb_competencies [parent_id self-ref]
slb_bloom_taxonomy (1) ──── (N) slb_cognitive_skill
slb_cognitive_skill (1) ──── (N) slb_ques_type_specificity
slb_lessons (1) ──── (N) slb_syllabus_schedule
slb_topics (1) ──── (N) slb_syllabus_schedule
```

### 5.3 External FK Dependencies

| Column | References |
|--------|------------|
| `slb_lessons.academic_session_id` | `sch_org_academic_sessions_jnt.id` |
| `slb_lessons.class_id` | `sch_classes.id` |
| `slb_lessons.subject_id` | `sch_subjects.id` |
| `slb_lessons.bok_books_id` | `slb_books.id` (SyllabusBooks module) |
| `slb_topics.class_id` | `sch_classes.id` |
| `slb_topics.subject_id` | `sch_subjects.id` |
| `slb_competencies.class_id` | `sch_classes.id` |
| `slb_syllabus_schedule.assigned_teacher_id` | `sch_teachers.id` |

---

## 6. Controller & Route Inventory

### 6.1 Controllers

| Controller | Methods | Auth | Notes |
|-----------|---------|------|-------|
| `LessonController` | index, store, show, update, destroy, view, trashed, restore, forceDelete, toggleStatus, getSubject, getClassTeachers, getBooks, checkDuplicate, updateOrder, validateImportFile, startImport | Gate::any() | Fully implemented |
| `TopicController` | index, store, show, update, destroy, getTopicsByLesson, getParentTopics, getParentOptions, updateHierarchy, getChildTopics, getTopicLevels, getTopicsByLevelFilter, validateImportFile, startImport | None (CRITICAL MISSING) | Hard delete via `forceDelete()` — no soft delete |
| `CompetencieController` | index, store, show, update, destroy, getParentCompetencies, getCompetencyTree, getByFilter, updateHierarchy | ZERO AUTH | Uses `$request->all()` in store — critical security issue |
| `CompetencyTypeController` | index, store, update, destroy, trashed, restore, forceDelete, toggleStatus | Unknown | Standard CRUD |
| `BloomTaxonomyController` | index, store, update, destroy, trashed, restore, forceDelete, toggleStatus | Unknown | Reference data management |
| `CognitiveSkillController` | index, store, update, destroy, trashed, restore, forceDelete, toggleStatus | Unknown | Reference data management |
| `QuestionTypeController` | Full CRUD + lifecycle | Unknown | Reference data management |
| `QuestionTypeSpecificityController` | Full CRUD + lifecycle | Unknown | Linked to cognitive skills |
| `ComplexityLevelController` | Full CRUD + lifecycle | Unknown | EASY/MEDIUM/DIFFICULT |
| `SyllabusController` | Unknown | Unknown | Likely dashboard/overview |
| `SyllabusScheduleController` | Full CRUD | Unknown | Topic scheduling |
| `TopicCompetencyController` | Full CRUD + lifecycle | Unknown | Junction management |
| `TopicLevelTypeController` | Full CRUD | Unknown | Level name configuration |
| `PerformanceCategoryController` | Full CRUD | Unknown | Score band management |
| `GradeDivisionController` | Full CRUD | Unknown | Grade band management |

### 6.2 Routes (tenant.php — prefix: `syllabus`)

All routes are under `Route::middleware(['auth', 'verified'])->prefix('syllabus')->name('syllabus.')`:

- `resource lesson` → full CRUD + named routes
- `/lesson/view/{id}`, `/lesson/trash/view`, `/lesson/{id}/restore`, `/lesson/{id}/force-delete`
- `/lesson/{lesson}/toggle-status`, `/lessons/check-duplicate`, `/lessons/update-order`
- `/lesson/validate-file`, `/lesson/start-import`
- `resource topic` → full CRUD
- `topics-by-lesson`, `parent-topics`, `update-hierarchy`, `/topic/view/{id}`, `/topic/trash/view`
- `/topic/{id}/restore`, `/topic/{id}/force-delete`, `/topic/{topic}/toggle-status`
- `/topic/validate-file`, `/topic/start-import`, `/topic-levels`, `/topics-by-level`
- `resource competencies` → full CRUD
- `competencies/parents/data`, `competencies/by/filter`, `competencies/update/hierarchy`
- `resource topic-competency`, `resource competency-type`, `resource complexity-level`
- Bloom taxonomy, cognitive skill, question type, question type specificity routes
- Syllabus schedule routes
- Performance category and grade division routes

---

## 7. Form Request Validation Rules

### 7.1 LessonRequest
- `academic_session_id`: required, exists:sch_org_academic_sessions_jnt,id
- `class_id`: required, exists:sch_classes,id
- `subject_id`: required, exists:sch_subjects,id
- `name`: required, string, max:150
- `code`: required, string, max:20, unique scoped to class+subject
- `ordinal`: required, integer, min:1
- `estimated_periods`: nullable, integer, min:1
- `weightage_in_subject`: nullable, decimal, 0-100
- `learning_objectives`: nullable, array

### 7.2 TopicRequest
- `lesson_id`: required, exists:slb_lessons,id
- `class_id`: required, exists:sch_classes,id
- `subject_id`: required, exists:sch_subjects,id
- `name`: required, string, max:150
- `level`: required, integer, min:0
- `parent_id`: nullable, exists:slb_topics,id (conditional on level > 0)
- `duration_minutes`: nullable, integer, min:0
- `weightage_in_lesson`: nullable, numeric, min:0, max:100
- `learning_objectives`: nullable, array
- `keywords`: nullable, array
- `prerequisite_topic_ids`: nullable, array

### 7.3 CompetencyRequest
- `name`: required, string, max:150
- `code`: required, string, max:60, unique on slb_competencies
- `competency_type_id`: required, exists:slb_competency_types,id
- `domain`: required, in:COGNITIVE,AFFECTIVE,PSYCHOMOTOR
- `class_id`: nullable, exists:sch_classes,id
- `subject_id`: nullable, exists:sch_subjects,id
- `parent_id`: nullable, exists:slb_competencies,id

### 7.4 BookTopicMappingRequest (in SyllabusBooks)
- `book_id`: required, exists:slb_books,id
- `topic_id`: required, exists:slb_topics,id

---

## 8. Business Rules

**BR-SLB-01:** A lesson code must be unique within the system (UNIQUE KEY on `code` column). Auto-generation follows the pattern `<CLASS_CODE>_<SUBJECT_CODE>_L<NN>`.

**BR-SLB-02:** A topic's level must equal `parent.level + 1`. A topic with `level = 0` must have `parent_id = NULL`.

**BR-SLB-03:** A topic that has child topics cannot have its `level` changed. The system blocks this at the update endpoint with an HTTP 422 response.

**BR-SLB-04:** Circular competency parent assignments are blocked: a competency cannot be its own parent, and a parent's parent cannot be the current competency.

**BR-SLB-05:** Topics linked to quizzes (`lms_quizzes.scope_topic_id`) cannot be force-deleted. The TopicController checks for quiz references before deletion.

**BR-SLB-06:** `slb_topic_competency_jnt` enforces UNIQUE(topic_id, competency_id) — one competency can only be mapped to one topic once.

**BR-SLB-07:** Performance category `min_percentage` and `max_percentage` ranges must not overlap within the same scope (SCHOOL or CLASS).

**BR-SLB-08:** Bloom taxonomy levels 1-3 (REMEMBERING, UNDERSTANDING, APPLYING) are classified as Lower Order Thinking (LOT); levels 4-6 (ANALYZING, EVALUATING, CREATING) as Higher Order Thinking (HOT).

**BR-SLB-09:** `slb_lessons.bok_books_id` is a mandatory FK to `slb_books` — every lesson must be linked to a textbook.

**BR-SLB-10:** The lesson version control table (`hpc_lesson_version_control`) tracks curriculum authority (NCERT/CBSE/ICSE/STATE_BOARD) and immutability status. System-defined lessons (`is_system_defined = 1`) have `is_editable = 0`.

---

## 9. Permission & Authorization Model

### 9.1 Current State

- **LessonController** uses `Gate::any(['tenant.lesson.viewAny'])` in `index()` — partially implemented
- **TopicController** has NO authentication checks in any method — CRITICAL SECURITY GAP
- **CompetencieController** has ZERO authentication on all 9 methods — CRITICAL SECURITY GAP
- Other controllers have unknown/partial auth implementation

### 9.2 Required Permissions (Target State)

| Resource | Permission | Description |
|----------|-----------|-------------|
| Lesson | `tenant.lesson.viewAny` | List all lessons |
| Lesson | `tenant.lesson.create` | Create new lesson |
| Lesson | `tenant.lesson.update` | Edit existing lesson |
| Lesson | `tenant.lesson.delete` | Soft-delete lesson |
| Topic | `tenant.topic.viewAny` | View topic list |
| Topic | `tenant.topic.create` | Create topic |
| Topic | `tenant.topic.update` | Update topic |
| Topic | `tenant.topic.delete` | Delete topic |
| Competency | `tenant.competencies.viewAny` | View competency list |
| Competency | `tenant.competencies.create` | Create competency |
| Competency | `tenant.competencies.update` | Update competency |
| Competency | `tenant.competencies.delete` | Delete competency |
| Schedule | `tenant.syllabus-schedule.viewAny` | View schedule |
| Schedule | `tenant.syllabus-schedule.create` | Create schedule entry |

---

## 10. Tests Inventory

### 10.1 Current State

**Zero tests exist** for the Syllabus module.

### 10.2 Required Tests (Target)

| Test Class | Type | Priority | Test Cases |
|-----------|------|----------|------------|
| `LessonTest` | Feature | HIGH | CRUD operations, auth enforcement, import validation |
| `TopicHierarchyTest` | Feature | HIGH | Level validation, circular parent prevention, tree retrieval |
| `CompetencyTest` | Feature | HIGH | Auth required (currently missing), circular relationship prevention |
| `TopicCompetencyMappingTest` | Feature | MEDIUM | Unique mapping constraint, weightage validation |
| `SyllabusScheduleTest` | Feature | MEDIUM | Date range assignment, teacher tracking |
| `BloomTaxonomyTest` | Unit | LOW | Level ordering, LOT/HOT classification |
| `TopicLevelTypeTest` | Unit | LOW | Dynamic max level calculation |

---

## 11. Known Issues & Technical Debt

### 11.1 Critical Security Gaps

**ISSUE-SLB-01 [CRITICAL]:** `CompetencieController` has ZERO authentication on ALL methods including `store`, `update`, `destroy`. Any unauthenticated HTTP request can create, modify, or delete competency records. The `store` method also uses `$request->all()` (mass assignment without validation whitelisting) which allows injection of arbitrary fields.

**ISSUE-SLB-02 [CRITICAL]:** `TopicController` has NO Gate/permission checks in any method. All topic operations (create, update, delete, hierarchy changes) are accessible to any authenticated user regardless of role.

### 11.2 Data Integrity Issues

**ISSUE-SLB-03 [HIGH]:** `Competencie` model does NOT use `SoftDeletes` trait. Calling `$competency->delete()` in `CompetencieController::destroy()` performs a hard delete, permanently removing competency records even if they are linked to topics via `slb_topic_competency_jnt`. The `deleted_at` column exists in the schema but is never populated.

**ISSUE-SLB-04 [HIGH]:** `TopicController::destroy()` uses `forceDelete()` instead of soft delete. Topics linked to active quizzes are checked, but topics linked to syllabus schedules are not checked before force deletion.

**ISSUE-SLB-05 [MEDIUM]:** `CompetencieController::store()` uses `$request->all()` instead of `$request->validated()`. While `CompetencyRequest` exists and is injected, the unvalidated bag is passed to `Competencie::create()`, bypassing `$fillable` protection only if `$guarded = []` is set.

### 11.3 Missing Functionality

**ISSUE-SLB-06 [MEDIUM]:** No service layer (0 services). Business logic for coverage calculation, Bloom's distribution analysis, and competency coverage is scattered across controllers.

**ISSUE-SLB-07 [MEDIUM]:** Study material upload UI is incomplete. `StudyMaterial` and `StudyMaterialType` models exist but there is no controller or routes for managing study materials (PDFs, videos, links per lesson/topic).

**ISSUE-SLB-08 [LOW]:** `SyllabusController` is present but its full implementation is unknown — likely a dashboard/overview stub.

**ISSUE-SLB-09 [LOW]:** `hpc_lesson_version_control` table exists in the DDL for lesson governance tracking but no corresponding controller, model, or routes exist in the Syllabus module.

---

## 12. API Endpoints

No REST API endpoints exist for the Syllabus module currently. All interactions are via HTML form submissions and AJAX JSON responses from the tenant web routes.

### 12.1 Key JSON AJAX Endpoints (Web Routes, tenant-only)

| Method | Route | Controller Method | Response |
|--------|-------|------------------|----------|
| GET | `/syllabus/topics-by-lesson?lesson_id=` | `getTopicsByLesson` | Recursive topic tree JSON |
| GET | `/syllabus/parent-topics?selected_level=&lesson_id=` | `getParentTopics` | Parent options JSON |
| GET | `/syllabus/topic-levels` | `getTopicLevels` | Level name list JSON |
| GET | `/syllabus/topics-by-level?level=&class_id=&subject_id=` | `getTopicsByLevelFilter` | Topic list JSON |
| GET | `/syllabus/competencies/parents/data` | `getParentCompetencies` | Parent competency list JSON |
| GET | `/syllabus/competencies/by/filter?class_id=&subject_id=` | `getByFilter` | Competency tree JSON |
| POST | `/syllabus/lesson/validate-file` | `validateImportFile` | Text file with validation result |
| POST | `/syllabus/lesson/start-import` | `startImport` | Import result JSON |
| POST | `/syllabus/topic/validate-file` | `validateImportFile` | Text file with validation result |
| POST | `/syllabus/topic/start-import` | `startImport` | Import result JSON |

---

## 13. Non-Functional Requirements

### 13.1 Performance

- Topic tree retrieval (`getTopicsByLesson`) must respond within 500ms for lessons with up to 200 topics
- Bulk import of 500 lessons must complete within 30 seconds
- Competency tree with 3 levels of nesting must load within 300ms

### 13.2 Scalability

- `slb_topics.path` (materialized path) enables efficient subtree queries without recursive CTEs
- Indexes on `(class_id, subject_id)` on both lessons and topics tables support filtered queries
- `analytics_code` on topics is unique and indexed for analytics lookups

### 13.3 Data Integrity

- UUID on `slb_lessons` and `slb_topics` for analytics tracking (BINARY 16)
- Cascade delete: topic children auto-deleted when parent is deleted (FK with ON DELETE CASCADE)
- Lesson cascade: topics auto-deleted when lesson is deleted

### 13.4 Security

- All tenant routes require `['auth', 'verified']` middleware (route-level)
- Each controller method must add `Gate::authorize()` or `Gate::any()` checks (currently missing on Topic and Competency controllers)

---

## 14. Integration Points

| Module | Integration Type | Description |
|--------|-----------------|-------------|
| `SchoolSetup` | FK dependency | `sch_classes`, `sch_subjects`, `sch_teachers`, `sch_sections` |
| `SyllabusBooks` | FK dependency | `slb_books.id` referenced by `slb_lessons.bok_books_id` |
| `LmsQuiz` | Consumer | Quiz scope references `slb_topics` via `scope_topic_id` |
| `LmsExam` | Consumer | Exam papers reference topics and competencies |
| `QuestionBank` | Consumer | Questions tagged with topic_id, competency_id, bloom_id, cognitive_skill_id |
| `Recommendation` | Consumer | Recommendation rules reference `slb_topics` and `slb_performance_categories` |
| `HPC` (Health Profile Card) | Consumer | Student competency progress data from topic-competency mappings |
| `Timetable` | Integration | Syllabus schedule uses period context from timetable |
| `Auth` | RBAC | Spatie permissions gate access to all SLB operations |

---

## 15. Pending Work & Gap Analysis

### 15.1 Completion Status: ~55%

| Feature Area | Status | Gap Description |
|-------------|--------|-----------------|
| Lesson CRUD + Import | 90% | Minor: toggle-status inconsistency |
| Topic Hierarchy CRUD | 85% | Hard delete instead of soft delete; zero auth |
| Competency Framework | 70% | Zero auth, uses `$request->all()`, model missing SoftDeletes |
| Bloom's Taxonomy | 80% | CRUD present; auth status unknown |
| Cognitive Skills | 80% | CRUD present; auth status unknown |
| Syllabus Schedule | 60% | Basic CRUD; coverage % calculation not implemented |
| Performance Categories | 65% | CRUD present; AI severity UI not implemented |
| Grade Divisions | 60% | Basic CRUD present |
| Study Materials | 10% | Models exist; no controller/routes/UI |
| Coverage Analytics | 0% | Coverage % computation not built |
| Service Layer | 0% | No services exist; logic in controllers |
| Test Coverage | 0% | Zero tests |
| Lesson Version Control | 0% | Table defined; no implementation |

### 15.2 Priority Remediation Items

1. **[P0]** Add `Gate::authorize()` to all methods in `CompetencieController` and `TopicController`
2. **[P0]** Replace `$request->all()` with `$request->validated()` in `CompetencieController::store()`
3. **[P0]** Add `SoftDeletes` trait to `Competencie` model and change `destroy()` to use soft delete
4. **[P1]** Change `TopicController::destroy()` to use `delete()` (soft delete) instead of `forceDelete()`
5. **[P1]** Implement syllabus coverage percentage calculation (count of taught vs scheduled topics)
6. **[P1]** Build service layer: `SyllabusService`, `CompetencyMappingService`
7. **[P2]** Build study material upload UI and `StudyMaterialController`
8. **[P2]** Write Feature tests for all controllers
9. **[P3]** Implement `hpc_lesson_version_control` management (governance/audit)
