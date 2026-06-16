# LMS Modules — Master Requirements Document
**Generated:** 2026-03-19
**Platform:** Prime-AI ERP + LMS + LXP (Multi-Tenant SaaS, Indian K-12 Schools)
**Tech Stack:** PHP 8.2+ / Laravel 12.0 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12.0
**Source:** Code inspection of 6 LMS modules + tenant routes + policies + migrations
**v3 Note:** All inline review comments resolved. Resolution blocks inserted after each comment.
**Excel:** `C:\laragon\www\LMS_Shailesh.xlsx` — Binary XLSX confirmed present; content not extractable without a parser tool. All requirements below are **derived from code** unless noted otherwise.

---

## TABLE OF CONTENTS
1. [Syllabus Module](#1-syllabus-module)
2. [LmsQuiz Module](#2-lmsquiz-module)
3. [LmsQuests Module](#3-lmsquests-module)
4. [LmsExam Module](#4-lmsexam-module)
5. [LmsHomework Module](#5-lmshomework-module)
6. [QuestionBank Module](#6-questionbank-module)
7. [Executive Summary](#executive-summary)
8. [Common Patterns Across Modules](#common-patterns-across-modules)
9. [Common Business Rules](#common-business-rules)
10. [Overall Suggestions](#overall-suggestions)

---

# 1. SYLLABUS MODULE

**Module path:** `Modules/Syllabus/`
**Table prefix:** `slb_*`
**Route prefix:** `/syllabus/*`
**Status:** ~100% complete (derived from code)

## 1.1 Module Purpose
The Syllabus module is the academic content backbone of the platform. It defines the hierarchical curriculum structure — from Class/Subject down to Lesson and multi-level Topic trees. It also manages supporting taxonomies: Bloom's Taxonomy, Cognitive Skills, Competencies, Complexity Levels, Question Types, Question Type Specificities, Performance Categories, Grade Division, and Syllabus Schedules. All other LMS modules (Quiz, Quest, Exam, Homework, QuestionBank) depend on this module for curriculum context.

## 1.2 Scope
- Lesson management per Academic Session, Class, Subject
- Topic tree management (multi-level, materialized-path hierarchy)
- Bloom's Taxonomy CRUD
- Cognitive Skill CRUD
- Competency and Competency Type CRUD
- Complexity Level CRUD
- Question Type and Question Type Specificity CRUD
- Performance Category CRUD
- Grade Division CRUD
- Syllabus Schedule CRUD
- Topic Competency mapping CRUD

## 1.3 Actors / Users
- School Administrator (setup and management)
- Subject Teacher (lesson and topic planning)
- Academic Coordinator (curriculum review)
- System (auto-code generation, hierarchy maintenance)

## 1.4 Entry Points (Routes Found)
All routes registered in `routes/tenant.php` under prefix `syllabus.` with middleware `['auth', 'verified']`.

| Route Name | Method | URI |
|---|---|---|
| syllabus.lesson.* | Resource (CRUD) | /syllabus/lesson |
| syllabus.lesson.trashed | GET | /syllabus/lesson/trash/view |
| syllabus.lesson.restore | GET | /syllabus/lesson/{id}/restore |
| syllabus.lesson.forceDelete | DELETE | /syllabus/lesson/{id}/force-delete |
| syllabus.lesson.toggleStatus | POST | /syllabus/lesson/{lesson}/toggle-status |
| syllabus.topic.* | Resource (CRUD) | /syllabus/topic |
| syllabus.topic.trashed | GET | /syllabus/topic/trash/view |
| syllabus.topic.restore | GET | /syllabus/topic/{id}/restore |
| syllabus.topic.forceDelete | DELETE | /syllabus/topic/{id}/force-delete |
| syllabus.topic.toggleStatus | POST | /syllabus/topic/{section}/toggle-status |
| syllabus.question-type.* | Resource (CRUD) | /syllabus/question-type |
| syllabus.ques-type-specificity.* | Resource (CRUD) | /syllabus/ques-type-specificity |
| syllabus.syllabus-schedule.* | Resource (CRUD) | /syllabus/syllabus-schedule |
| syllabus.bloom-taxonomy.* | Resource (CRUD) | /syllabus/bloom-taxonomy |
| syllabus.cognitive-skill.* | Resource (CRUD) | /syllabus/cognitive-skill |
| syllabus.competency.* | Resource (CRUD) | /syllabus/competency |
| syllabus.performance-category.* | Resource (CRUD) | /syllabus/performance-category |
| syllabus.grade-division.* | Resource (CRUD) | /syllabus/grade-division |

Module's own `routes/web.php` defines only `syllabi` resource (stub), actual routes are in `routes/tenant.php`.

## 1.5 Core Entities (Tables/Models Found)

| Model | Table | Description |
|---|---|---|
| Lesson | `slb_lessons` | Lesson per Session+Class+Subject |
| Topic | `slb_topics` | Multi-level topic tree (materialized path) |
| BloomTaxonomy | `slb_bloom_taxonomy` (inferred) | Bloom's Taxonomy levels |
| CognitiveSkill | `slb_cognitive_skills` (inferred) | Cognitive skill categories |
| Competencie | `slb_competencies` (inferred) | Competencies |
| CompetencyType | `slb_competency_types` (inferred) | Competency type groups |
| ComplexityLevel | `slb_complexity_level` (from migration ref) | Complexity/difficulty levels |
| QuestionType | `slb_question_types` (from migration ref) | Question types |
| QueTypeSpecifity | `slb_ques_type_specificities` (inferred) | Specificity of question types |
| PerformanceCategory | `slb_performance_categories` (inferred) | Performance bands |
| GradeDivisionMaster | `slb_grade_division_master` (from ExamRequest ref) | Grading schemas |
| StudyMaterial | `slb_study_materials` (inferred) | Study material resources |
| SyllabusSchedule | `slb_syllabus_schedule` (from migration 2026_01_15) | Planned delivery schedule |
| TopicCompetency | `slb_topic_competency` (inferred) | Mapping of topic to competency |
| TopicDependencies | `slb_topic_dependencies` (inferred) | Prerequisite topic links |
| TopicLevelType | `slb_topic_level_types` (inferred) | Level type metadata |

## 1.6 Field-Level Requirements

### slb_lessons (Lesson model)
| Field | Type | Required | Notes |
|---|---|---|---|
| uuid | string | auto | Auto-generated |
| academic_session_id | FK | Yes | Exists: `sch_org_academic_sessions_jnt.id` |
| class_id | FK | Yes | Exists: `sch_classes.id` |
| subject_id | FK | Yes | Exists: `sch_subjects.id` |
| bok_books_id | FK | No | Link to book |
| code | string(20) | Yes | Unique globally |
| name | string(150) | Yes | Unique per session+class+subject |
| short_name | string(50) | No | |
| ordinal | integer | Yes | Unique per session+class+subject, min:1 |
| description | string(255) | No | |
| learning_objectives | JSON array | No | Stored as JSON |
| prerequisites | JSON array | No | Stored as JSON |
| estimated_periods | integer | No | min:1 |
| weightage_in_subject | decimal(2) | No | 0-100 |
| nep_alignment | string(100) | No | |
| book_chapter_ref | string(100) | No | |
| scheduled_year_week | integer | No | Format: YYYYWW, range 202001-210052 |
| resources_json | JSON array | No | Types: video,pdf,link,document,image,audio,ppt |
| is_active | boolean | Yes | Default true |

### slb_topics (Topic model)
| Field | Type | Required | Notes |
|---|---|---|---|
| uuid | string(16) | auto | Random 16-char string |
| parent_id | FK self | No | Self-referencing, null = root |
| lesson_id | FK | Yes | Exists: `slb_lessons.id` |
| class_id | FK | Yes | Exists: `sch_classes.id` |
| subject_id | FK | Yes | Exists: `sch_subjects.id` |
| path | string | auto | Materialized path, auto-computed |
| path_names | string | auto | Human-readable breadcrumb, auto-computed |
| level | integer | auto | 0=root, computed from parent.level+1 |
| code | string | auto | Hierarchical code, auto-generated |
| analytics_code | string | auto | Defaults to code |
| name | string(150) | Yes | Unique per lesson+parent |
| short_name | string(50) | No | |
| ordinal | integer | No | Display order, unique per lesson+parent |
| description | text | No | |
| duration_minutes | integer | No | min:1 |
| learning_objectives | JSON array | No | Comma-separated on input |
| keywords | JSON array | No | |
| prerequisite_topic_ids | JSON array | No | |
| weightage_in_lesson | decimal | No | |
| is_active | boolean | Yes | |

## 1.7 Functional Requirements

1. **Lesson Management**: Teachers/admins can create, edit, soft-delete, restore, and force-delete lessons. Lessons are batch-created (multiple in one form submission via `lessons[]` array). (derived from code: `LessonRequest.php`)
2. **Topic Tree**: Topics form a multi-level hierarchy via parent_id, with automatic materialized path computation on create. (derived from code: `Topic.php` booted() method)
3. **Auto-Code Generation**: Topic codes are auto-generated in hierarchical format (e.g. `GR5_MATH_L1_TOP01`, `GR5_MATH_L1_TOP01_SUB01`). Codes are guaranteed unique with retry loop. (derived from code)
4. **Soft Delete + Restore**: All entities support soft delete (deleted_at) and restore. Force-delete routes available. (derived from code: routes in tenant.php)
5. **Status Toggle**: All entities have a `toggle-status` endpoint for activating/deactivating without full edit. (derived from code)
6. **Taxonomy Management**: BloomTaxonomy, CognitiveSkill, Competency, ComplexityLevel, QuestionType, QueTypeSpecificity, PerformanceCategory are independent reference entities managed via full CRUD. (derived from code)
7. **Topic Competency Mapping**: Topics can be mapped to Competencies via `TopicCompetency` entity. (derived from code: model exists)
8. **Resource Attachments on Lessons**: Each lesson can carry a `resources_json` array with typed URLs (video, pdf, link, document, image, audio, ppt). (derived from code: LessonRequest validation)
9. **Syllabus Schedule**: Planned delivery schedule per lesson/topic, supports CRUD + soft delete. (derived from code: migration 2026_01_15 + route)
10. **Grade Division**: Grading schemas used by LmsExam module. (derived from code: `ExamRequest.php` references `slb_grade_division_master`)

## 1.8 Business Rules

1. A Lesson is unique per (academic_session_id + class_id + subject_id + name). (derived from code: LessonRequest custom validator)
2. A Lesson code must be globally unique across all lessons. (derived from code)
3. Lesson ordinal must be unique per (academic_session_id + class_id + subject_id). (derived from code)
4. A Topic name must be unique within the same lesson and same parent. (derived from code: TopicRequest unique rule)
5. Topic level is automatically computed from parent; cannot exceed `TopicLevelType.max(level)`. (derived from code)
6. Topic path is a materialized path rebuilt on creation (TEMP/ placeholder strategy). (derived from code)
7. Lessons accept batch input: multiple lessons submitted as `lessons[]` in one POST. (derived from code)
8. Resource URLs on lessons must be valid URLs (http/https). (derived from code)
9. Resource type must be one of: video, pdf, link, document, image, audio, ppt. (derived from code)
10. `prerequisites` field on lessons stores JSON-encoded array of integer IDs. (derived from code)

## 1.9 Validation Rules

### LessonRequest
| Field | Rule |
|---|---|
| academic_session_id | required, integer, exists:sch_org_academic_sessions_jnt |
| class_id | required, integer, exists:sch_classes |
| subject_id | required, integer, exists:sch_subjects |
| lessons | required, array, min:1 |
| lessons.*.name | required, string, max:150, unique per session+class+subject (custom) |
| lessons.*.code | required, string, max:20, unique globally (custom) |
| lessons.*.ordinal | required, integer, min:1, unique per session+class+subject (custom) |
| lessons.*.short_name | nullable, string, max:50 |
| lessons.*.description | nullable, string, max:255 |
| lessons.*.estimated_periods | nullable, integer, min:1 |
| lessons.*.weightage_in_subject | nullable, numeric, 0-100 |
| lessons.*.scheduled_year_week | nullable, integer, 202001-210052 |
| lessons.*.resources.*.type | required_with_resources, in:video,pdf,link,document,image,audio,ppt |
| lessons.*.resources.*.url | required_with_resources, url, max:500 |

### TopicRequest
| Field | Rule |
|---|---|
| class_id | required, integer, exists:sch_classes |
| subject_id | required, integer, exists:sch_subjects |
| lesson_id | required, integer, exists:slb_lessons |
| parent_id | nullable, integer, exists:slb_topics |
| name | required, string, max:150, unique per lesson+parent (ignoring self on edit) |
| level | nullable, integer, min:0, max:TopicLevelType.max_level |
| duration_minutes | nullable, integer, min:1 |
| is_active | required, boolean |

## 1.10 CRUD Conditions

| Operation | Allowed When | Restricted When |
|---|---|---|
| Create Lesson | Authenticated + permission `syllabus.lesson.create` | - |
| Edit Lesson | Authenticated + permission `syllabus.lesson.update` | - |
| Delete Lesson | Soft delete via policy | Force delete requires separate permission |
| Restore Lesson | Authenticated + permission restore | Only if soft-deleted |
| Create Topic | Authenticated + lesson_id exists | - |
| Edit Topic | Authenticated + permission | - |
| Delete Topic | Soft delete | Children may still exist (no cascade enforced in code found) |

## 1.11 Permission / Access Control Conditions
Policies found: `QuesTypeSpecificityPolicy.php` (named `SyllabusSchedulePolicy.php` — mismatch). Pattern: `tenant.{resource}.{action}`.

| Action | Permission Name |
|---|---|
| View Any | `tenant.ques-type-specificity.viewAny` |
| View | `tenant.ques-type-specificity.view` |
| Create | `tenant.ques-type-specificity.create` |
| Update | `tenant.ques-type-specificity.update` |
| Delete | `tenant.ques-type-specificity.delete` |
| Restore | `tenant.ques-type-specificity.restore` |
| Force Delete | `tenant.ques-type-specificity.forceDelete` |
| Status Toggle | `tenant.ques-type-specificity.status` |

Note: No dedicated Lesson or Topic policy file was found. This is a code review gap (see Section 1.19).

All routes protected by `auth` + `verified` middleware.

## 1.12 Workflow Requirements
- No explicit workflow states found for Lesson or Topic; `is_active` is the only status flag.
- Syllabus Schedule entity may imply a planning workflow but no state machine was found.

## 1.13 Status / Lifecycle Rules
- `is_active` flag: toggled via `toggleStatus` endpoint.
- Soft delete: sets `deleted_at`. Restore: clears `deleted_at`.
- Force delete: permanent removal.

## 1.14 Module Dependencies
| Depends On | Reason |
|---|---|
| SchoolSetup | SchoolClass, Subject, Section, OrganizationAcademicSession |
| SyllabusBooks | BokBook linked on Lesson |
| Prime | AcademicSession, User |

**Depended on by:** LmsQuiz, LmsQuests, LmsExam, LmsHomework, QuestionBank (all reference lessons, topics, question types, complexity levels, bloom taxonomy, cognitive skills, competencies).

## 1.15 Exception / Edge Conditions
1. Topic path uses TEMP placeholder during creation, updated in `created` event. If `saveQuietly` fails, path stays as TEMP. (derived from code)
2. Auto-code generation uses retry loop — could infinite-loop if namespace exhausted (7 levels × 99 siblings = max 693 unique codes per path). (derived from code)
3. Batch lesson submission: if any one lesson in the array fails validation, the entire batch is rejected. (derived from code: LessonRequest array rules)
4. `TopicLevelType::max('level')` query in TopicRequest: if no TopicLevelType records exist, max returns null, defaults to 5. (derived from code)
5. `bok_books_id` on Lesson references `BokBook` (SyllabusBooks module) — no FK migration enforcement found.

## 1.16 Requirements Derived from Excel
N/A — Excel file could not be parsed (binary XLSX format). All requirements derived from code.

## 1.17 Requirements Derived from Code
- All requirements in sections 1.7–1.15 are derived from code.
- Key code files: `Modules/Syllabus/app/Models/Topic.php`, `Modules/Syllabus/app/Models/Lesson.php`, `Modules/Syllabus/app/Http/Requests/TopicRequest.php`, `Modules/Syllabus/app/Http/Requests/LessonRequest.php`, `routes/tenant.php` lines 963-1111.

## 1.18 Final Consolidated Requirements
1. Lesson is the primary teaching unit linked to academic session, class, and subject.
2. Topics form a recursive, ordered, coded tree beneath each lesson.
3. All taxonomy entities (Bloom, Cognitive, Competency, Complexity, QuestionType) are school-level reference data.
4. Soft delete + restore is standard for all entities.
5. Batch lesson creation in a single form submission is a required UX pattern.
6. Resource URL attachments on lessons with type validation are required.
7. Topic auto-code generation with hierarchical naming is required.

## 1.19 Code Review Observations
1. **Policy gap**: No `LessonPolicy` or `TopicPolicy` exists. Routes are protected by `auth` middleware only; no policy-based authorization is applied for lesson/topic CRUD. This is a security gap.
2. **`SyllabusSchedulePolicy.php` is misnamed**: Its class name and model are `QuesTypeSpecificity`, not syllabus schedule.
3. **`Topic.php` `booted()` TEMP path**: If `saveQuietly()` fails after creation, the topic path remains `TEMP/` permanently.
4. **N+1 risk in batch lessons**: `LessonRequest` fires multiple DB queries per lesson in custom validators (unique checks), potentially issuing 6+ queries per lesson row.
5. **`Lesson.php` references `SchAcademicSession::class`** (undefined class in that file's namespace — should be `OrganizationAcademicSession`). Relationship `academicSession()` will fail at runtime.
6. **`ComplexityLevel` migration**: Referenced as `slb_complexity_level` (no trailing `s`) — inconsistency with other table naming.
7. **No migration found** for most `slb_*` tables (only `slb_complexity_levels`, `slb_question_types`, `slb_syllabus_schedule` have visible migrations). Most tables must already exist in `tenant_db_v2.sql`.

## 1.20 Suggestions
1. Create `LessonPolicy` and `TopicPolicy` following the same pattern as `QuizPolicy`.
2. Fix the `Lesson.php` `academicSession()` relationship to use the correct model class.
3. Rename `SyllabusSchedulePolicy.php` to correctly guard Syllabus Schedule, not QuesTypeSpecificity.
4. Add a `cascade_delete_children` check before deleting a topic that has sub-topics.
5. Add a total lessons count / coverage percentage display on the lesson list view.
6. Consider adding a `published_at` field on lessons for publication workflow.

---

## 1.21 Documentation Addendum — Grouped Listing Requirement for Cognitive Skills and Question Type Specificity Tabs

> **New Requirement Added** — UI/Listing behavior for two specific reference-data tabs within the Syllabus module.
> This is a presentation-layer requirement only. No data model change or additional business logic is implied.

### 1.21.1 Overview

The Syllabus module manages several reference-data entities. Two of these — **Cognitive Skills** and **Question Type Specificity** — have a parent-child relationship with other reference entities (BloomTaxonomy and CognitiveSkill respectively). Currently, their index/list pages present records as a flat, undifferentiated list. The requirement below specifies that these two tabs must instead present their records in a **grouped, collapsible accordion-style layout**, organized by their respective parent foreign key.

This requirement applies exclusively to:
- The **Cognitive Skills** tab index/list page
- The **Question Type Specificity** tab index/list page

No other Syllabus tabs are in scope for this change.

---

### 1.21.2 Cognitive Skills Tab — Grouped Listing Requirement

#### Grouping Key
Records in the Cognitive Skills list must be grouped by `bloom_id`.

**Code evidence:** `CognitiveSkill` model (`Modules/Syllabus/app/Models/CognitiveSkill.php`) has a `belongsTo(BloomTaxonomy::class, 'bloom_id')` relationship named `bloomTaxonomy()`. The model table is `slb_cognitive_skill`. The scope `scopeForBloom()` also confirms grouping by `bloom_id` is a natural query pattern for this entity.

#### Group Label
Each group header row must display the readable **Bloom Taxonomy name** (not the raw integer `bloom_id`). The `bloomTaxonomy()` relationship on `CognitiveSkill` must be eager-loaded to avoid N+1 queries. If a record has a `null` bloom_id or the related BloomTaxonomy record is soft-deleted or unavailable, the group must fall back gracefully with a label such as "Uncategorized" rather than breaking.

#### Group Summary Row (Parent Row)
Each group must be represented by a single collapsible summary row, visible by default, containing:
- Readable Bloom Taxonomy name as the group label
- Count of records belonging to that group (e.g., "3 skills")
- An expand/collapse toggle control (chevron icon or equivalent)

#### Child Rows (Expanded State)
When a group is expanded:
- All Cognitive Skill records belonging to that `bloom_id` must be displayed as child rows beneath the group header
- Child rows must show: code, name, description (or existing column set), `is_active` status, and all existing action buttons (edit, delete/soft-delete, restore, status toggle)
- Child rows must be visually indented or otherwise differentiated from group header rows

#### Collapse Behavior
When a group is collapsed, only the group summary row is visible. Child record rows are hidden. The default collapsed/expanded state is left to implementation decision but must be consistent across all groups.

#### Ordering
- Groups must be ordered by a stable criterion (e.g., BloomTaxonomy `name` alphabetically or `id` ascending)
- Within each group, records must be ordered by a stable criterion (e.g., `code` or `name` ascending)

#### Null Group Key Handling
If any Cognitive Skill record has a `null` bloom_id, those records must be grouped together under an "Uncategorized" or "No Bloom Level Assigned" group shown at the end of the list.

#### Filter and Search Compatibility
Existing filter/search behavior must continue to work. If a search or filter is applied, the grouped display must still hold. Records not matching the filter must be excluded; groups with no matching records after filtering must not be shown.

#### Permission Preservation
All existing permission checks (`@can`, policy gates) on individual record actions must be preserved within child rows. The grouped display is purely a presentation change.

#### Pagination Consideration
If pagination is currently applied to the Cognitive Skills list: grouping and pagination are incompatible unless grouping is done server-side per page. Since Cognitive Skills is a reference-data set (expected to be small in count), pagination may be removed in favor of loading all records for this specific tab, with grouping applied in the controller or collection layer. This tradeoff must be confirmed at implementation time.

---

### 1.21.3 Question Type Specificity Tab — Grouped Listing Requirement

#### Grouping Key
Records in the Question Type Specificity list must be grouped by `cognitive_skill_id`.

**Code evidence:** `QueTypeSpecifity` model (`Modules/Syllabus/app/Models/QueTypeSpecifity.php`) has a `belongsTo(CognitiveSkill::class, 'cognitive_skill_id')` relationship named `cognitiveSkill()`. The model table is `slb_ques_type_specificity`. The scope `scopeForCognitiveSkill()` confirms grouping by this field is a natural query pattern.

#### Group Label
Each group header row must display the readable **Cognitive Skill name** (not the raw integer `cognitive_skill_id`). The `cognitiveSkill()` relationship on `QueTypeSpecifity` must be eager-loaded. If a record has a `null` cognitive_skill_id or the related CognitiveSkill record is unavailable, the fallback label "Uncategorized" must be used.

#### Group Summary Row (Parent Row)
Each group must be represented by a single collapsible summary row containing:
- Readable Cognitive Skill name as the group label
- Count of records in that group (e.g., "2 specificity types")
- Expand/collapse toggle control

#### Child Rows (Expanded State)
When a group is expanded:
- All QueTypeSpecifity records with matching `cognitive_skill_id` must appear as child rows
- Child rows must show: code, name, description (or existing column set), `is_active` status, and all existing action buttons
- Child rows must be visually distinguished from group header rows

#### Collapse Behavior
Same as Cognitive Skills tab — consistent across all groups.

#### Ordering
- Groups ordered by Cognitive Skill name alphabetically or id ascending
- Within each group, records ordered by code or name ascending

#### Null Group Key Handling
Records with `null` cognitive_skill_id must be grouped under "Uncategorized" shown at the end.

#### Filter, Search, and Permission Compatibility
All existing search/filter functionality and permission checks must be preserved exactly as for the Cognitive Skills tab.

#### Pagination Consideration
Same tradeoff applies as for Cognitive Skills. QueTypeSpecificity is reference data and expected to have a manageable row count. Pagination removal for this specific tab is acceptable if grouping requires it, subject to implementation confirmation.

---

### 1.21.4 Grouped Listing — Field-Level View Requirements

| Field | Cognitive Skills Group Row | QueTypeSpecificity Group Row |
|---|---|---|
| Group Label | BloomTaxonomy.name (eager-loaded via bloomTaxonomy()) | CognitiveSkill.name (eager-loaded via cognitiveSkill()) |
| Fallback Label | "Uncategorized" if bloom_id is null or BloomTaxonomy not found | "Uncategorized" if cognitive_skill_id is null or CognitiveSkill not found |
| Record Count | Count of CognitiveSkill records per bloom_id | Count of QueTypeSpecifity records per cognitive_skill_id |
| Toggle | Expand/Collapse per group | Expand/Collapse per group |
| Child: code | Shown per record row | Shown per record row |
| Child: name | Shown per record row | Shown per record row |
| Child: description | Shown per record row (if currently shown in flat list) | Shown per record row (if currently shown in flat list) |
| Child: is_active | Shown as status badge per record row | Shown as status badge per record row |
| Child: Actions | Edit / Delete / Status Toggle — same as flat list | Edit / Delete / Status Toggle — same as flat list |

---

### 1.21.5 Grouped Listing — Workflow Steps

#### Cognitive Skills Tab — Grouped Index Load
| Step | Actor | System Behavior |
|---|---|---|
| 1 | User navigates to Syllabus → Cognitive Skills tab | System loads all CognitiveSkill records with eager-loaded bloomTaxonomy() relationship |
| 2 | System groups records by bloom_id | Records with same bloom_id are grouped; null bloom_id records go to Uncategorized group |
| 3 | System orders groups and records within groups | Groups sorted by BloomTaxonomy.name; children sorted by code or name |
| 4 | System renders grouped list | Each group shows as a collapsible summary row with count |
| 5 | User clicks expand on a group | Child rows for that group become visible |
| 6 | User clicks collapse | Child rows hide; summary row remains |
| 7 | User applies filter/search | Matching records shown; groups with no matches hidden |
| 8 | User clicks edit/delete on a child row | Existing CRUD action fires with existing permission check |

#### Question Type Specificity Tab — Grouped Index Load
Identical workflow with substitutions: CognitiveSkill records → QueTypeSpecifity records; bloomTaxonomy() → cognitiveSkill(); bloom_id → cognitive_skill_id; BloomTaxonomy.name → CognitiveSkill.name.

---

### 1.21.6 Grouped Listing — CRUD View Conditions

| Condition | Cognitive Skills | Question Type Specificity |
|---|---|---|
| Group row visibility | Always visible when group has at least 1 record | Always visible when group has at least 1 record |
| Group row expand/collapse | User-controlled; client-side toggle (Bootstrap collapse or equivalent) | Same |
| Child rows visibility | Hidden by default; shown on group expand | Same |
| Empty group display | Groups with 0 records must not be rendered | Same |
| Null group fallback | Rendered as "Uncategorized" group | Same |
| Action buttons on child rows | Conditional on existing permission checks (viewAny, update, delete, status) | Same |
| Filter result — group with 0 matches | Group row must be hidden when no children match filter | Same |
| Search — group with partial match | Group row must show only matching child rows | Same |

---

### 1.21.7 Source Reference
- `Modules/Syllabus/app/Models/CognitiveSkill.php` — `bloom_id` fillable, `bloomTaxonomy()` belongsTo relationship, `scopeForBloom()` scope (derived from code)
- `Modules/Syllabus/app/Models/QueTypeSpecifity.php` — `cognitive_skill_id` fillable, `cognitiveSkill()` belongsTo relationship, `scopeForCognitiveSkill()` scope (derived from code)
- This requirement is a **new UI/listing behavior requirement** — no changes to the data model, business rules, or permission structure are implied.

---

## 1.22 Documentation Addendum — Syllabus Lesson Topic Release Control (Index Screen)

> **New Requirement Added — 2026-03-20**
> Screen Type: Index / List Screen only. This is NOT a full CRUD module.
> The screen is an operational filter-and-toggle screen for managing downstream LMS module release eligibility at the topic level.

---

### 1.22.1 Requirement Title
**Syllabus Lesson Topic Release Control**

---

### 1.22.2 Business Purpose

The Syllabus module manages the academic content hierarchy: Lessons → Topics → Sub-Topics → deeper levels. Once lessons and topics are defined, downstream LMS modules (Quiz, Quest, Exam) need to know which topics are eligible for content release. This screen provides a filtered, consolidated view of lesson-topic records and allows users to update the release eligibility flags (Quiz, Quest, Exam) directly from the index/listing page — without navigating to an individual edit form.

This screen serves as the **syllabus-controlled release eligibility control panel** for LMS downstream modules.

---

### 1.22.3 Screen Type
- **Index / List Screen only**
- No standalone create form
- No standalone edit form
- No standalone delete action
- All updates are **toggle-based, index-level update actions** only

---

### 1.22.4 Required Filters

The following filters must be present on this screen and must control which records are loaded into the listing:

| Filter | Type | Source Table | Notes |
|---|---|---|---|
| Class | Dropdown / Select | `sch_classes` | Required to scope the listing |
| Section | Dropdown / Select | `sch_sections` (via class-section junction) | Depends on selected Class; needs confirmation whether Section is a filter at topic level |
| Subject | Dropdown / Select | `sch_subjects` | Required to scope the listing |

> **Note on Section filter:** `slb_topics` stores `class_id` and `subject_id` but no `section_id` (derived from schema: `slb_topics` DDL). Section may be an indirect filter via `sch_class_sections_jnt`. Whether Section is a filter at the topic listing level **needs business confirmation**.

> **Note on Lesson filter:** An optional Lesson filter may also be useful for narrowing the topic list further. This is inferred from the module's structure and is recommended for task implementation but **needs business confirmation** as a mandatory filter.

---

### 1.22.5 Data Source / Table Reference

| Layer | Table | Purpose |
|---|---|---|
| Lesson records | `slb_lessons` | Parent lesson context |
| Topic records | `slb_topics` | Topic hierarchy with release flags |
| Topic Level Types | `slb_topic_level_types` | Level definitions and module release eligibility rules per level |

**Key schema fields used on this screen:**

From `slb_topics`:
| Column | Type | Purpose |
|---|---|---|
| `id` | PK | Record identity |
| `lesson_id` | FK → `slb_lessons` | Parent lesson |
| `class_id` | FK → `sch_classes` | Denormalized for fast filtering |
| `subject_id` | FK → `sch_subjects` | Denormalized for fast filtering |
| `parent_id` | FK → self | Immediate parent topic (NULL for root topics) |
| `level` | TINYINT | Topic hierarchy depth: 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, etc. |
| `name` | VARCHAR(150) | Topic name |
| `code` | VARCHAR(60) | Auto-generated hierarchical code |
| `path` | VARCHAR(500) | Materialized path e.g. `/1/5/23/` |
| `path_names` | VARCHAR(2000) | Readable path e.g. `Algebra > Linear Equations > Solving Methods` |
| `release_quiz_on_completion` | TINYINT(1) DEFAULT 0 | Quiz release flag — **schema confirmed** |
| `release_quest_on_completion` | TINYINT(1) DEFAULT 0 | Quest release flag — **schema confirmed** |
| `is_active` | TINYINT(1) | Active status |

> **Important schema finding for Exam toggle:** `slb_topics` DDL does **not** contain a `release_exam_on_completion` column (derived from schema: `tenant_db_v2.sql` lines 4791–4792). Only `release_quiz_on_completion` and `release_quest_on_completion` are present in `slb_topics`. However, `slb_topic_level_types` contains `can_be_used_for_exam_release` per level type. Whether a per-topic Exam release flag exists or is planned **needs business confirmation**. The Exam toggle on this screen may require a schema addition (`release_exam_on_completion` column) before implementation.

From `slb_topic_level_types` (release eligibility per level):
| Column | Purpose |
|---|---|
| `can_be_used_for_quiz_release` | Whether topics at this level are allowed to release Quiz |
| `can_be_used_for_quest_release` | Whether topics at this level are allowed to release Quest |
| `can_be_used_for_exam_release` | Whether topics at this level are allowed to release Exam |
| `can_be_used_for_homework_release` | Whether topics at this level are allowed to release Homework |

> These level-type flags act as **master eligibility rules** per topic level. The per-topic toggle (`release_quiz_on_completion` etc.) acts as the **instance-level override**. The interaction between level-type eligibility and per-topic toggle **needs business confirmation** regarding precedence.

---

### 1.22.6 Listing / Table Column Requirements

The index table must display the following columns at minimum:

| Column | Source | Notes |
|---|---|---|
| Lesson | `slb_lessons.name` (via lesson_id join) | Parent lesson name |
| Topic Level | `slb_topic_level_types.name` (via `slb_topics.level`) | Readable level name e.g. Topic, Sub-topic, Mini Topic |
| Parent Topic Level | `slb_topics` self-join via `parent_id` → parent topic name | Immediate parent topic name; shows hierarchy context |
| Topic Name | `slb_topics.name` | The actual topic record name |
| Topic Code | `slb_topics.code` (optional but recommended) | Unique topic code for identification |
| Quiz Toggle | `slb_topics.release_quiz_on_completion` | Toggle control (0 = disabled, 1 = enabled) |
| Quest Toggle | `slb_topics.release_quest_on_completion` | Toggle control (0 = disabled, 1 = enabled) |
| Exam Toggle | Pending — needs schema confirmation (see Section 1.22.5) | Toggle control — schema column may need to be added |

> **Parent Topic Level note:** For root-level topics (`level = 0`, `parent_id = NULL`), the Parent Topic Level column must display a safe fallback such as "— (Root Topic)" or blank. The `path_names` field from `slb_topics` can provide a full breadcrumb if a richer context display is needed.

---

### 1.22.7 Index-Level Actions

This screen provides **toggle-based update actions only** from the listing row:

| Action | Target Column | Type | Notes |
|---|---|---|---|
| Toggle Quiz Release | `slb_topics.release_quiz_on_completion` | Boolean toggle | Updates field inline from listing row |
| Toggle Quest Release | `slb_topics.release_quest_on_completion` | Boolean toggle | Updates field inline from listing row |
| Toggle Exam Release | Pending — needs schema confirmation | Boolean toggle | May require schema addition |

> No create, full edit, or delete actions are available from this screen.
> Toggles are **index-level updates** directly on `slb_topics` records.

---

### 1.22.8 Update Conditions

| Condition | Rule |
|---|---|
| Who can toggle | User must have appropriate syllabus update permission (inferred from module pattern; exact permission name needs confirmation) |
| Level-type eligibility check | Before a toggle is activated, the system should check `slb_topic_level_types.can_be_used_for_*_release` for the topic's level. If the level type disables release for a module, the toggle must be either disabled or show a validation warning (needs business confirmation on enforcement method) |
| Soft-deleted topics | Must not appear in listing |
| Inactive topics | May appear in listing with visual indicator; toggle behavior on inactive topics needs business confirmation |
| Toggle persistence | Change to `release_quiz_on_completion` or `release_quest_on_completion` must persist to `slb_topics` record in the database |
| Exam toggle | Not persisted until schema column confirmed |

---

### 1.22.9 Business Rules

1. Quiz and Quest release eligibility are stored at the **per-topic level** in `slb_topics.release_quiz_on_completion` and `release_quest_on_completion`. (Derived from schema)
2. Topic Level Types (`slb_topic_level_types`) define **master-level eligibility** per level depth for Quiz, Quest, Exam, and Homework release. These are level-wide rules, not per-topic. (Derived from schema)
3. The interaction rule between `slb_topic_level_types` eligibility flag and `slb_topics` per-topic flag is **not confirmed in current schema DDL** and needs business definition.
4. Root-level topics (`level = 0`, `parent_id = NULL`) have no parent context; this must be displayed safely in the Parent Topic Level column.
5. The screen must filter topic records by Class and Subject at minimum; Section filter dependency on topic records needs confirmation.
6. Filters must be applied before the listing is populated; listing must not load all topics across all classes/subjects by default (performance consideration).
7. This screen is a **controlled operational screen**, not a master data CRUD screen.
8. Downstream modules (Quiz, Quest, Exam) are expected to respect these topic-level release flags when allowing content creation or delivery. The exact enforcement mechanism in Quiz/Quest/Exam modules is outside the Syllabus module scope and **needs cross-module confirmation**.

---

### 1.22.10 Validation / Condition Notes

- A topic that is soft-deleted must not be shown in the listing.
- Filters must not return records outside the current academic session unless the screen explicitly allows cross-session view (needs business confirmation).
- Toggle updates must not bypass the standard `auth` + permission middleware.
- If `slb_topic_level_types.can_be_used_for_quiz_release = 0` for the topic's level, the Quiz toggle for that topic should reflect this restriction visually (disabled / greyed out or with a tooltip). Exact enforcement behavior needs business confirmation.

---

### 1.22.11 Workflow Summary

| Step | Actor | System Behavior |
|---|---|---|
| 1 | User navigates to Syllabus → Release Control tab | Screen loads with empty listing; filters visible |
| 2 | User selects Class | Subject dropdown populates based on class (inferred from module UX pattern) |
| 3 | User selects Subject | (Optional: Section filter if implemented) |
| 4 | User applies filters | System queries `slb_topics` joined with `slb_lessons` for matching class_id + subject_id |
| 5 | Listing renders | Rows show: Lesson, Topic Level, Parent Topic Level, Topic Name, Quiz toggle, Quest toggle, Exam toggle |
| 6 | User toggles Quiz release on a topic | System updates `slb_topics.release_quiz_on_completion` for that record |
| 7 | User toggles Quest release on a topic | System updates `slb_topics.release_quest_on_completion` for that record |
| 8 | User toggles Exam release on a topic | System updates pending schema field (needs confirmation) |
| 9 | Toggle updates persist | Downstream LMS modules read these flags to control content eligibility |

---

### 1.22.12 Dependency Notes

| Dependency | Direction | Notes |
|---|---|---|
| `slb_topics` | Source table | `release_quiz_on_completion`, `release_quest_on_completion` columns confirmed in schema |
| `slb_lessons` | Join — parent context | Lesson name display requires join on `slb_lessons.id = slb_topics.lesson_id` |
| `slb_topic_level_types` | Join — level label | Topic level readable name from `slb_topic_level_types.name` via `slb_topics.level` |
| `sch_classes` | Filter source | Class filter |
| `sch_subjects` | Filter source | Subject filter |
| LmsQuiz module | Downstream consumer | Expected to read `release_quiz_on_completion` — cross-module enforcement needs confirmation |
| LmsQuests module | Downstream consumer | Expected to read `release_quest_on_completion` — cross-module enforcement needs confirmation |
| LmsExam module | Downstream consumer | Exam release flag enforcement needs schema + cross-module confirmation |

---

### 1.22.13 Open Questions / Needs Business Confirmation

1. Is Section a required filter for this screen, given that `slb_topics` does not store `section_id` directly?
2. Should the Lesson be an additional filter option (beyond Class and Subject)?
3. What is the precedence rule between `slb_topic_level_types.can_be_used_for_quiz_release` and `slb_topics.release_quiz_on_completion` when the level type disables a module?
4. Is a `release_exam_on_completion` column planned for `slb_topics`, or is Exam release controlled only at the level-type layer?
5. Should inactive topics (`is_active = 0`) appear in this screen or be excluded?
6. Should the screen be academic-session-scoped?
7. How do downstream LMS modules (Quiz/Quest/Exam) currently read or enforce these release flags? Is enforcement present or planned?

---

### 1.22.14 Task Readiness Notes

| Readiness Item | Status |
|---|---|
| Quiz and Quest release columns confirmed in schema | Ready for implementation |
| Exam release column | Schema addition needed — pending business confirmation |
| Lesson, Topic, Level Type joins | Straightforward — documented above |
| Class and Subject filters | Ready — both columns denormalized in `slb_topics` |
| Section filter | Needs business confirmation before implementation |
| Level-type eligibility enforcement on toggle | Behavior rule needs business confirmation |
| Downstream enforcement in Quiz/Quest/Exam | Cross-module task — separate from this screen |
| Permission requirement | Needs exact permission name confirmation |

---

## 1.23 Documentation Addendum — Lesson Planning Date Range (Index Screen)

> **New Requirement Added — 2026-03-20**
> Screen Type: Index / List Screen only. This is NOT a full CRUD module.
> The screen is a planning-oriented listing of lessons with date-range planning filters and index-level update of lesson start and end dates.

---

### 1.23.1 Requirement Title
**Lesson Planning Date Range**

---

### 1.23.2 Business Purpose

Academic lesson planning requires teachers and academic coordinators to define **when** each lesson is planned to be taught — its intended start date and end date within the academic session. This screen provides a planning-focused view of lesson records, supports date-oriented filtering, and allows users to update the planned start and end dates directly from the index/listing page.

This screen acts as a **lesson planning calendar / date-range assignment board** within the Syllabus module.

---

### 1.23.3 Screen Type
- **Index / List Screen only**
- No standalone create form
- No standalone full edit form
- Updates to **Lesson Start Date** and **Lesson End Date** are **index-level update actions** only

---

### 1.23.4 Data Source / Table Reference

Primary table: **`slb_lessons`**

> **Important schema finding:** The current `slb_lessons` DDL (`tenant_db_v2.sql` lines 4720–4753) does **not** contain `start_date` or `end_date` columns. The existing planning-adjacent field is `scheduled_year_week` (INT UNSIGNED, format YYYYWW — e.g., 202401). (Derived from schema)
>
> This means:
> - If `start_date` and `end_date` are required as date-type fields on `slb_lessons`, **a schema migration will be required** to add these columns to `slb_lessons`.
> - Alternatively, if `scheduled_year_week` is considered sufficient for planning, this screen may work with that field instead.
> - The decision between adding explicit date columns vs using `scheduled_year_week` **needs business confirmation** before implementation.

**Existing relevant columns on `slb_lessons`:**

| Column | Type | Purpose |
|---|---|---|
| `id` | PK | Record identity |
| `academic_session_id` | FK → `sch_org_academic_sessions_jnt` | Academic session scoping |
| `class_id` | FK → `sch_classes` | Class filter |
| `subject_id` | FK → `sch_subjects` | Subject filter |
| `name` | VARCHAR(150) | Lesson name |
| `code` | VARCHAR(20) | Auto-generated lesson code |
| `short_name` | VARCHAR(50) | Short lesson name |
| `ordinal` | SMALLINT UNSIGNED | Lesson order within subject |
| `estimated_periods` | SMALLINT UNSIGNED | Number of periods to deliver the lesson |
| `scheduled_year_week` | INT UNSIGNED | Planned week (YYYYWW format) — existing planning field |
| `is_active` | TINYINT(1) | Active status |

**New columns required (pending business confirmation):**

| Proposed Column | Type | Purpose |
|---|---|---|
| `planned_start_date` | DATE | Planned lesson start date (to be added to `slb_lessons`) |
| `planned_end_date` | DATE | Planned lesson end date (to be added to `slb_lessons`) |

> Column names `planned_start_date` / `planned_end_date` are recommended to distinguish from session/term `start_date`/`end_date` fields in other tables. Final naming **needs business confirmation**.

---

### 1.23.5 Listing / Display Requirements

The planning index screen must display lesson records in a planning-oriented layout:

| Column | Source | Notes |
|---|---|---|
| Lesson Name | `slb_lessons.name` | Primary lesson identifier |
| Lesson Code | `slb_lessons.code` | Auto-generated code for reference |
| Subject | `sch_subjects.name` (via subject_id join) | Subject context |
| Class | `sch_classes.name` (via class_id join) | Class context |
| Ordinal / Sequence | `slb_lessons.ordinal` | Lesson order within subject |
| Estimated Periods | `slb_lessons.estimated_periods` | Planning context — helps set realistic date range |
| Scheduled Week | `slb_lessons.scheduled_year_week` | Existing planning field (YYYYWW format) — show as readable week reference |
| Planned Start Date | `slb_lessons.planned_start_date` (pending migration) | Editable inline from index |
| Planned End Date | `slb_lessons.planned_end_date` (pending migration) | Editable inline from index |
| Topics Count | COUNT from `slb_topics` (optional) | Number of topics under this lesson for planning context |

---

### 1.23.6 Filters

The following filters must be supported for the planning screen:

| Filter | Type | Source Table | Notes |
|---|---|---|---|
| Class | Dropdown | `sch_classes` | Required filter |
| Subject | Dropdown | `sch_subjects` | Required filter; scoped by class |
| Section | Dropdown | `sch_sections` (via class-section) | Needs business confirmation — `slb_lessons` does not store `section_id` directly |
| Lesson | Dropdown / Search | `slb_lessons` | Optional — for narrowing to a specific lesson |
| Date Range — Start | Date picker | Planning screen filter | Filter lessons whose planned date range overlaps the selected range |
| Date Range — End | Date picker | Planning screen filter | Used together with start date range filter |
| Academic Session | Auto-resolved | `sch_org_academic_sessions_jnt` | Should default to current session; cross-session view may be optional |

> Date range filter depends on `planned_start_date` and `planned_end_date` columns being available on `slb_lessons`. If only `scheduled_year_week` is used, the date range filter must adapt to work with week-format values.

---

### 1.23.7 Index-Level Actions

| Action | Target Field | Type | Notes |
|---|---|---|---|
| Update Planned Start Date | `slb_lessons.planned_start_date` | Inline date update from listing row | Pending schema confirmation |
| Update Planned End Date | `slb_lessons.planned_end_date` | Inline date update from listing row | Pending schema confirmation |
| Update Scheduled Week | `slb_lessons.scheduled_year_week` | Inline week-field update | Alternative if date columns are not added |

> These are **index-level update actions only**. There is no separate edit-form requirement for this screen.

---

### 1.23.8 Field Requirements

| Field | Type | Validation | Notes |
|---|---|---|---|
| planned_start_date | DATE | Must be a valid date; must not be later than planned_end_date | Required if feature is activated |
| planned_end_date | DATE | Must be a valid date; must not be earlier than planned_start_date | Required if feature is activated |
| scheduled_year_week | INT UNSIGNED | Format: YYYYWW; week in range 1–53; year in reasonable range | Existing field — already used |

---

### 1.23.9 Update Conditions

| Condition | Rule |
|---|---|
| Start date must not be after end date | `planned_start_date <= planned_end_date` — hard validation |
| Date range should fall within academic session | `planned_start_date >= academic_session.start_date` AND `planned_end_date <= academic_session.end_date` (inferred from planning intent; enforcement method needs business confirmation) |
| Who can update | User must have appropriate syllabus lesson update permission (inferred from module pattern; exact permission name needs confirmation) |
| Soft-deleted lessons | Must not appear in listing |
| Inactive lessons | May appear with visual indicator; update eligibility on inactive lessons needs business confirmation |
| Null date scenario | If dates are not yet set (NULL), the planning row must still be visible in the listing with empty date cells — user sets dates from the planning screen |

---

### 1.23.10 Validation Rules

| Rule | Type | Notes |
|---|---|---|
| `planned_start_date` is required when `planned_end_date` is provided | Conditional required | Must enforce as a pair |
| `planned_end_date` is required when `planned_start_date` is provided | Conditional required | Must enforce as a pair |
| `planned_start_date <= planned_end_date` | Date order validation | Hard rule |
| Both dates must be valid calendar dates | Format validation | No invalid dates |
| Dates should fall within academic session window | Advisory or hard validation | Needs business confirmation on enforcement type (warn vs block) |
| `scheduled_year_week` format: YYYYWW | Integer range validation | Already implemented in LessonRequest (derived from code: LessonRequest.php week range 202001–210052) |

---

### 1.23.11 Workflow Summary

| Step | Actor | System Behavior |
|---|---|---|
| 1 | User navigates to Syllabus → Lesson Planning Date Range tab | Screen loads; filters shown; listing empty or pre-filtered by current session |
| 2 | User selects Class and Subject | Listing populates with lessons matching the filters |
| 3 | (Optional) User applies date range filter | Listing narrows to lessons within the selected planning date window |
| 4 | (Optional) User selects a specific Lesson | Listing shows only that lesson |
| 5 | User sets or updates Planned Start Date on a lesson row | System updates `slb_lessons.planned_start_date` inline with validation |
| 6 | User sets or updates Planned End Date on a lesson row | System updates `slb_lessons.planned_end_date` inline; validates start ≤ end |
| 7 | Planning dates are saved | Lesson record reflects the planned delivery window |
| 8 | Other users / modules can read the planning window | Downstream planning or scheduling tools may reference these dates (needs confirmation) |

---

### 1.23.12 Dependency Notes

| Dependency | Direction | Notes |
|---|---|---|
| `slb_lessons` | Primary table | Source of all lesson records; planning date columns to be added |
| `sch_org_academic_sessions_jnt` | Context | Academic session scoping and date boundary validation |
| `sch_classes` | Filter | Class filter and display |
| `sch_subjects` | Filter | Subject filter and display |
| SmartTimetable module | Potential downstream consumer | Timetable module (`tt_*`) manages periods; lesson planning dates may align with timetable start/end — cross-module dependency needs confirmation |
| LmsExam / LmsHomework | Potential downstream consumers | Planned lesson windows may inform exam/homework scheduling — needs business confirmation |

---

### 1.23.13 Open Questions / Needs Business Confirmation

1. Should `planned_start_date` and `planned_end_date` be added to `slb_lessons` as new columns, or should `scheduled_year_week` be used as the primary planning field?
2. If date columns are added, should a new migration be created for `slb_lessons`, or will the DDL schema be updated?
3. Is Section a required filter for this planning screen, given `slb_lessons` does not store `section_id`?
4. Should date validation enforce that lesson dates fall within the academic session window (hard block) or only warn the user?
5. Should academic session be auto-resolved to the current session, or should users be able to switch sessions on this screen?
6. Are planning dates meant to be visible or consumed by SmartTimetable or any scheduling module?
7. Should the planned date range be shown alongside `scheduled_year_week`, or should one replace the other?

---

### 1.23.14 Task Readiness Notes

| Readiness Item | Status |
|---|---|
| `slb_lessons` listing query with class/subject filters | Ready — columns exist |
| `scheduled_year_week` display and update | Ready — column exists, format documented |
| `planned_start_date` and `planned_end_date` update | **Schema migration required** — columns do not exist in current DDL |
| Date validation (start ≤ end) | Logic is standard — ready once columns exist |
| Academic session boundary validation | Depends on session context resolution — needs confirmation |
| Class and Subject filters | Ready — both FKs denormalized on `slb_lessons` |
| Section filter | Needs business confirmation |
| Downstream planning dependency | Separate task scope — needs cross-module discussion |

---

# 2. LMSQUIZ MODULE

**Module path:** `Modules/LmsQuiz/`
**Table prefix:** `lms_*` (quizzes)
**Route prefix:** `/lms-quize/*` (note: typo in route name — "quize" not "quiz")
**Status:** ~90% complete (derived from code)

## 2.1 Module Purpose
Manages formative assessments in quiz format. Teachers create quizzes linked to an academic hierarchy (session → class → subject → lesson → topic), configure question settings, difficulty distribution, and allocate quizzes to classes, sections, groups, or individual students. The module integrates with QuestionBank for question sourcing.

## 2.2 Scope
- Quiz CRUD with academic hierarchy context
- Assessment Type management
- Difficulty Distribution Config management (with detail breakdown)
- Quiz Question management (bulk add from QuestionBank, reorder, mark override)
- Quiz Allocation to CLASS/SECTION/GROUP/STUDENT with timeline controls

## 2.3 Actors / Users
- Teacher (creates and manages quizzes)
- School Administrator (manages assessment types, difficulty configs)
- Student (receives allocated quizzes — frontend out of current scope)

## 2.4 Entry Points (Routes Found)
All under prefix `/lms-quize/` with name prefix `lms-quize.` and middleware `['auth', 'verified']`.

| Route | Method | Description |
|---|---|---|
| lms-quize.quize.* | Resource | Quiz CRUD |
| lms-quize.quize.trashed | GET | Trash view |
| lms-quize.quize.restore | GET | Restore |
| lms-quize.quize.forceDelete | DELETE | Permanent delete |
| lms-quize.quize.toggleStatus | POST | Toggle active |
| lms-quize.get-lessons | POST | AJAX: get lessons by class/subject |
| lms-quize.assessment-type.* | Resource | Assessment Type CRUD |
| lms-quize.difficulty-distribution-config.* | Resource | DDC CRUD |
| lms-quize.quiz-allocation.* | Resource | Quiz Allocation CRUD |
| lms-quize.quiz-question.* | Resource | Quiz Question CRUD |
| lms-quize.difficulty.builder.fetch | POST | Fetch questions per difficulty |
| lms-quize.difficulty.builder.add | POST | Add questions via difficulty builder |
| lms-quize.difficulty.builder.quiz-meta | POST | Get quiz meta for builder |
| lms-quize.quiz-question.get-sections | GET | AJAX: sections |
| lms-quize.get-subject-groups | GET | AJAX: subject groups |
| lms-quize.get-subjects | GET | AJAX: subjects |
| lms-quize.get-topics | GET | AJAX: topics |
| lms-quize.search | GET | Search questions |
| lms-quize.existing | GET | Show existing questions in quiz |
| lms-quize.bulk-store | POST | Bulk add questions |
| lms-quize.bulk-destroy | POST | Bulk remove questions |
| lms-quize.update-ordinal | POST | Reorder questions |
| lms-quize.update-marks | POST | Update question marks |

## 2.5 Core Entities (Tables/Models Found)

| Model | Table | Description |
|---|---|---|
| Quiz | `lms_quizzes` | Main quiz entity |
| AssessmentType | `lms_assessment_types` | Type/category of assessment |
| DifficultyDistributionConfig | `lms_difficulty_distribution_configs` | Distribution profile |
| DifficultyDistributionDetail | (inferred child table) | Per-complexity-level % split |
| QuizAllocation | `lms_quiz_allocations` | Quiz assigned to audience |
| QuizQuestion | `lms_quiz_questions` | Pivot: quiz → question with ordinal/mark override |

## 2.6 Field-Level Requirements

### lms_quizzes (Quiz model)
| Field | Type | Required | Validation |
|---|---|---|---|
| uuid | UUID | auto | Unique |
| quiz_code | string | auto | Auto-generated from hierarchy; unique |
| academic_session_id | FK | Yes | required |
| class_id | FK | Yes | exists:sch_classes |
| subject_id | FK | Yes | exists:sch_subjects |
| lesson_id | FK | Yes | exists:slb_lessons |
| quiz_type_id | FK | Yes | exists:lms_assessment_types |
| scope_topic_id | FK | No | exists:slb_topics |
| title | string(100) | Yes | max:100 |
| description | string(255) | No | |
| instructions | text | No | |
| status | ENUM | Yes | DRAFT/PUBLISHED/ARCHIVED |
| duration_minutes | integer | No | 1-600 |
| total_marks | decimal | Yes | min:0 |
| total_questions | integer | Yes | min:0 |
| passing_percentage | decimal | Yes | 0-100 |
| allow_multiple_attempts | boolean | No | default false |
| max_attempts | integer | conditional | required if allow_multiple_attempts; 1-10 |
| negative_marks | decimal | Yes | 0-99.99 |
| is_randomized | boolean | No | |
| question_marks_shown | boolean | No | |
| show_result_immediately | boolean | No | |
| auto_publish_result | boolean | No | |
| timer_enforced | boolean | No | |
| show_correct_answer | boolean | No | |
| show_explanation | boolean | No | |
| difficulty_config_id | FK | No | exists:lms_difficulty_distribution_configs |
| ignore_difficulty_config | boolean | No | |
| is_system_generated | boolean | No | |
| created_by | FK | No | exists:sys_users |
| is_active | boolean | Yes | default true |

### lms_quiz_allocations (QuizAllocation model)
| Field | Type | Required | Notes |
|---|---|---|---|
| quiz_id | FK | Yes | |
| allocation_type | ENUM | Yes | (inferred from code) |
| target_table_name | string | Yes | Polymorphic morph type |
| target_id | integer | Yes | Polymorphic target ID |
| assigned_by | FK User | No | |
| published_at | datetime | No | When quiz becomes visible |
| due_date | datetime | No | Submission deadline |
| cut_off_date | datetime | No | Last allowed access |
| is_auto_publish_result | boolean | No | |
| result_publish_date | datetime | No | |
| is_active | boolean | Yes | |

## 2.7 Functional Requirements
1. Create, edit, soft-delete, restore, force-delete quizzes. (derived from code)
2. Quiz code auto-generated from session+class+subject+lesson+topic codes + random suffix. (derived from code)
3. Difficulty Distribution Config defines percentage split across complexity levels (Easy/Medium/Hard). (derived from code)
4. Questions added to quiz via bulk-store from QuestionBank, with ordinal and mark override. (derived from code)
5. Quiz questions can be reordered (update-ordinal) and marks overridden per question. (derived from code)
6. Difficulty Builder: fetch questions per difficulty level and add in batch. (derived from code: routes)
7. Allocate quiz to CLASS, SECTION, GROUP, or STUDENT with published_at, due_date, cut_off_date, result_publish_date. (derived from code)
8. AJAX endpoints for cascading dropdowns: sections → subject groups → subjects → topics. (derived from code)
9. Get lessons AJAX: filtered by class+subject. (derived from code)
10. Status toggle: activate/deactivate without full edit. (derived from code)

## 2.8 Business Rules
1. `max_attempts` is required when `allow_multiple_attempts` is true. (derived from code: QuizRequest)
2. Quiz is available for students only when `status = PUBLISHED` and `is_active = true`. (derived from code: `Quiz.isAvailable()`)
3. Quiz code is unique; on creation auto-generated, on edit enforced unique ignoring self. (derived from code)
4. Duration between 1-600 minutes. (derived from code)
5. `negative_marks` range 0-99.99. (derived from code)
6. `passing_percentage` range 0-100. (derived from code)

## 2.9 Validation Rules (QuizRequest)
| Field | Rule |
|---|---|
| academic_session_id | required |
| class_id | required, exists:sch_classes |
| subject_id | required, exists:sch_subjects |
| lesson_id | required, exists:slb_lessons |
| title | required, string, max:100 |
| quiz_type_id | required, exists:lms_assessment_types |
| status | required, in:DRAFT,PUBLISHED,ARCHIVED |
| total_marks | required, numeric, min:0 |
| total_questions | required, integer, min:0 |
| passing_percentage | required, numeric, min:0, max:100 |
| negative_marks | required, numeric, min:0, max:99.99 |
| duration_minutes | nullable, integer, min:1, max:600 |
| max_attempts | required_if:allow_multiple_attempts,true; integer, 1-10 |
| difficulty_config_id | nullable, exists:lms_difficulty_distribution_configs |

Note: `academic_session_id` is `required` but has **no `exists` validation** — a potential integrity gap.

## 2.10 CRUD Conditions

| Operation | Allowed When | Restricted When |
|---|---|---|
| Create Quiz | Authenticated + `tenant.quize.create` | - |
| Edit Quiz | Authenticated + `tenant.quize.update` | Ideally restricted when PUBLISHED (no code enforcement found) |
| Delete (soft) | `tenant.quize.delete` | - |
| Restore | `tenant.quize.restore` | Only if soft-deleted |
| Force Delete | `tenant.quize.forceDelete` | - |
| Toggle Status | `tenant.quize.status` | - |
| Allocate | `tenant.quiz-allocation.*` (inferred) | Quiz must be active |

## 2.11 Permission / Access Control Conditions
Policy file: `app/Policies/QuizPolicy.php`

| Action | Permission |
|---|---|
| viewAny | `tenant.quize.viewAny` |
| view | `tenant.quize.view` |
| create | `tenant.quize.create` |
| update | `tenant.quize.update` |
| delete | `tenant.quize.delete` |
| restore | `tenant.quize.restore` |
| forceDelete | `tenant.quize.forceDelete` |
| status | `tenant.quize.status` |

No separate policy for QuizAllocation or QuizQuestion was found (gap).

## 2.12 Workflow Requirements
- Quiz lifecycle: DRAFT → PUBLISHED → ARCHIVED
- No code enforces transition rules (e.g., cannot un-publish). This is an implementation gap.
- Allocation published_at controls student visibility.

## 2.13 Status / Lifecycle Rules
| Status | Meaning |
|---|---|
| DRAFT | Created, not yet visible to students |
| PUBLISHED | Active and visible to allocated students |
| ARCHIVED | No longer active |

`is_active` flag is separate from status — both must be true for student access.

## 2.14 Module Dependencies
| Depends On | Reason |
|---|---|
| Syllabus | Lesson, Topic, ComplexityLevel |
| SchoolSetup | SchoolClass, Subject, Section, EntityGroup |
| QuestionBank | Questions sourced from qns_questions_bank |
| Prime | AcademicSession, User |
| StudentProfile | Student (for allocation) |

## 2.15 Exception / Edge Conditions
1. `academic_session_id` has no `exists` validation — invalid session IDs accepted silently. (derived from code)
2. `QuizAllocation` uses polymorphic morph (`target_table_name`, `target_id`) — not using Laravel's standard `morphTo` columns (`*_type`, `*_id`), which may break ORM morphTo resolution. (derived from code)
3. Quiz code generation uses `Str::random(4)` suffix — very short, collision probability non-trivial for high-volume schools. (derived from code)
4. Route prefix is `lms-quize` (typo) — this will persist in all URLs and bookmarks. (derived from code)
5. No check that `total_questions` matches actual added questions before PUBLISH. (derived from code — contrast with Quest which has `canPublish()`)

## 2.16 Requirements Derived from Excel
N/A — see note at top.

## 2.17 Requirements Derived from Code
All requirements above derived from code inspection.

## 2.18 Final Consolidated Requirements
1. Quiz is tied to academic hierarchy (session → class → subject → lesson → optional topic).
2. Difficulty configuration controls question selection distribution.
3. Multiple allocation types (class/section/group/student) with timeline controls.
4. Quiz questions are ordered and can have mark overrides.
5. Status must transition DRAFT → PUBLISHED for student visibility.
6. Soft delete + restore is standard.

## 2.19 Code Review Observations
1. **Route typo**: All Quiz routes use `lms-quize` (extra 'e'). This affects all URLs and API calls.
2. **No QuizAllocation policy**: No policy found for `QuizAllocation` or `QuizQuestion`.
3. **`academic_session_id` not validated with exists**: Can accept non-existent session IDs.
4. **No publish guard**: No validation prevents editing a PUBLISHED quiz.
5. **No question count check on publish**: Unlike Quest (which has `canPublish()`), Quiz has no such validation.
6. **Polymorphic allocation**: Uses `target_table_name`/`target_id` instead of Laravel standard `target_type`/`target_id` — `morphTo()` relationship may not work correctly.
7. **Quiz.php boot()**: Eager loads `academicSession`, `class`, `subject`, `lesson`, `topic` via relationship calls during boot — these fire DB queries at model creation time, even in batch operations.
8. **`QuizAllocationPolicy`**: Missing. Any authenticated user can allocate quizzes.

## 2.20 Suggestions
1. Fix route prefix typo `lms-quize` → `lms-quiz` (requires coordinated migration of all URLs).
-> answer  -> not change route please becuse alrady implment so this break so not change

> **📋 REVIEW RESOLUTION**
> **Question:** Suggestion to rename route prefix. Owner says: do NOT change — already implemented throughout, renaming would break existing code.
> **Final Answer:** REJECTED — Route prefix `lms-quize` will remain as-is. This is a confirmed intentional design constraint. No rename.
> **Basis:** Developer instruction (owner decision)
> **Recommendation:** Document as a known permanent quirk. Do not attempt to rename without full frontend/backend coordination.

2. Add `exists` validation for `academic_session_id` in `QuizRequest`.
-> answer  ->   check and i will tell you

> **📋 REVIEW RESOLUTION**
> **Question:** Suggestion to add `exists` validation. Owner says: check and will decide.
> **Final Answer:** PENDING OWNER DECISION. The gap is confirmed — `academic_session_id` in QuizRequest has `required` but no `exists:sch_org_academic_sessions_jnt,id`. Owner will review and confirm.
> **Basis:** Developer instruction
> **Recommendation:** Task card: "Add exists validation for academic_session_id in QuizRequest — trigger: owner confirmation."

3. Create `QuizAllocationPolicy` and `QuizQuestionPolicy`.
-> answer  ->  ok yes

> **📋 REVIEW RESOLUTION**
> **Question:** Suggestion to create missing policies. Owner says: yes, agreed.
> **Final Answer:** ACCEPTED. Owner approves creating QuizAllocationPolicy. Note: `QuizQuestionPolicy.php` already exists in `app/Policies/`. Only `QuizAllocationPolicy` needs to be created. Follow QuizPolicy pattern.
> **Basis:** Developer instruction + code inspection (QuizQuestionPolicy already exists)
> **Recommendation:** Task card: "Create QuizAllocationPolicy in app/Policies/ — register in AppServiceProvider — apply in QuizAllocationController — trigger: owner go-ahead."

4. Add publish guard: prevent status change to PUBLISHED if question count ≠ total_questions.
-> answer  -> ok

> **📋 REVIEW RESOLUTION**
> **Question:** Suggestion to add publish guard. Owner says: ok (approved).
> **Final Answer:** ACCEPTED. Implement `Quiz::canPublish()` mirroring Quest's implementation. Apply in LmsQuizController when status transitions to PUBLISHED.
> **Basis:** Developer instruction
> **Recommendation:** Task card: "Implement Quiz::canPublish() — check question count, settings, academic hierarchy — apply in LmsQuizController publish action."

5. Add lifecycle enforcement: once PUBLISHED, restrict field-level edits.
-> answer  -> ok

> **📋 REVIEW RESOLUTION**
> **Question:** Suggestion to restrict edits on PUBLISHED quiz. Owner says: ok (approved).
> **Final Answer:** ACCEPTED. When a quiz's status is PUBLISHED, edit should be blocked or require explicit un-publish first.
> **Basis:** Developer instruction
> **Recommendation:** Task card: "Add PUBLISHED quiz edit restriction — trigger: owner go-ahead."

6. Use Laravel standard morphTo columns (type/id) for `QuizAllocation`.
-> answer  -> ok

> **📋 REVIEW RESOLUTION**
> **Question:** Suggestion to use standard morphTo. Owner says: ok (approved).
> **Final Answer:** ACCEPTED. Replace `target_table_name`/`target_id` with standard `target_type`/`target_id` and register morphMap aliases.
> **Basis:** Developer instruction
> **Recommendation:** Task card: "Migrate QuizAllocation to standard morphTo — update migration (additive) + model + morphMap registration — trigger: owner go-ahead."
---

# 3. LMSQUESTS MODULE

**Module path:** `Modules/LmsQuests/`
**Table prefix:** `lms_quests*`
**Route prefix:** `/lms-quests/*`
**Status:** ~85% complete (derived from code)

## 3.1 Module Purpose
Manages topic-level mini-assessments called "Quests". Structurally very similar to Quizzes but scoped to lesson level without topic granularity in the main entity. Quests have an additional concept of "Scope" (lesson+topic combinations defining the content boundary) and support the `pending` status flag unique to this module. Includes a `duplicate()` method for cloning quests.

## 3.2 Scope
- Quest CRUD with academic hierarchy
- Quest Scope management (lesson+topic boundaries)
- Quest Question management (bulk add, reorder, mark override)
- Quest Allocation to CLASS/SECTION/GROUP/STUDENT with comprehensive date controls
- Quest duplication

## 3.3 Actors / Users
- Teacher (creates and manages quests)
- School Administrator
- Student (receives quests — frontend not in scope here)

## 3.4 Entry Points (Routes Found)
Under prefix `/lms-quests/` with name prefix `lms-quests.` and middleware `['auth', 'verified']`.

| Route | Description |
|---|---|
| lms-quests.quest.* | Quest CRUD + trash/restore/force-delete/toggle-status |
| lms-quests.quest-scope.* | Quest Scope CRUD + trash/restore/force-delete/toggle-status |
| lms-quests.quest-scope.getTopics | GET AJAX: topics by lesson |
| lms-quests.quest-allocation.* | Quest Allocation CRUD + extras |
| lms-quests.quest-allocation.getTargetOptions | GET AJAX: target options by type |
| lms-quests.quest-question.* | Quest Question CRUD + bulk operations |
| get-sections, get-subject-groups, get-subjects, get-lessons, get-topics | GET AJAX |
| update-ordinal, update-marks | POST |
| search, existing, bulk-store, bulk-destroy, quest-meta | GET/POST |

Note: Quest question routes appear duplicated in tenant.php (two groups at lines 608 and 632-651). This may cause route conflicts.

## 3.5 Core Entities

| Model | Table | Description |
|---|---|---|
| Quest | `lms_quests` | Main quest entity |
| QuestScope | `lms_quest_scopes` (inferred) | Lesson+topic boundary |
| QuestQuestion | `lms_quest_questions` | Pivot: quest → question |
| QuestAllocation | `lms_quest_allocations` (inferred) | Quest allocated to audience |

## 3.6 Field-Level Requirements

### lms_quests (Quest model)
Same core structure as Quiz plus:
| Field | Type | Notes |
|---|---|---|
| quest_code | string | Auto-generated, unique |
| status | ENUM | DRAFT/PUBLISHED/ARCHIVED |
| pending | boolean | Unique to Quest (not in Quiz) |
| published_at | datetime | Set on publish() call |

All other fields mirror Quiz fields (academic_session_id, class_id, subject_id, lesson_id, quest_type_id, difficulty_config_id, duration_minutes, total_marks, total_questions, passing_percentage, allow_multiple_attempts, max_attempts, negative_marks, is_randomized, question_marks_shown, show_result_immediately, auto_publish_result, timer_enforced, show_correct_answer, show_explanation, ignore_difficulty_config, is_system_generated, is_active, created_by).

## 3.7 Functional Requirements
1. Full CRUD for Quest including trash/restore/force-delete. (derived from code)
2. Quest code auto-generated from session+class+subject+lesson codes. (derived from code)
3. Quest Scope defines which lessons and topics are covered (content boundary). (derived from code: QuestScope model)
4. AJAX `getTopics` by lesson for scope definition. (derived from code: route)
5. Quest Question bulk add from QuestionBank, with ordinal and mark override. (derived from code)
6. `quest-meta` endpoint returns quiz/quest metadata for question builder. (derived from code: route)
7. `getTargetOptions` AJAX returns valid target IDs based on allocation type. (derived from code: route)
8. Quest `duplicate()` method clones quest, questions, and scopes, setting status=DRAFT. (derived from code: Quest.php)
9. Quest `canPublish()` validates: has questions, question count matches total_questions, valid settings, complete academic hierarchy. (derived from code: Quest.php)
10. Quest `publish()`, `archive()`, `restoreQuest()` state transition methods. (derived from code: Quest.php)

## 3.8 Business Rules
1. Quest can only be published if `canPublish()` returns true. (derived from code)
2. Duplicate quest sets title += " (Copy)" and status = DRAFT. (derived from code)
3. `pending` flag is unique to Quest (no equivalent in Quiz). (derived from code: QuestRequest)
4. Quest allocation target must be active (`is_active = true`) for CLASS, SECTION, GROUP, STUDENT. (derived from code: QuestAllocationRequest)
5. Due date must be future date (after_or_equal:now). (derived from code: QuestAllocationRequest)
6. Cut-off date must be >= due_date. (derived from code)
7. Result publish date must be >= due_date and only set when `is_auto_publish_result = true`. (derived from code)
8. All dates capped at 2 years in future. (derived from code)

## 3.9 Validation Rules (QuestRequest)
| Field | Rule |
|---|---|
| title | required, string, max:255 |
| quest_type_id | required, exists:lms_assessment_types |
| status | required, in:DRAFT,PUBLISHED,ARCHIVED |
| total_marks | required, numeric, min:0 |
| total_questions | required, integer, min:0 |
| passing_percentage | required, numeric, min:0, max:100 |
| negative_marks | required, numeric, min:0, max:99.99 |
| duration_minutes | nullable, integer, min:1, max:300 (note: Quiz allows 600, Quest only 300) |
| max_attempts | required_if:allow_multiple_attempts,true; integer, 1-10 |
| pending | boolean (unique to Quest) |

Note: `academic_session_id`, `class_id`, `subject_id`, `lesson_id` are `nullable|string` in QuestRequest (no `exists` validation, no `required`). This is a significant gap vs QuizRequest.

### QuestAllocationRequest
| Field | Rule |
|---|---|
| quest_id | required, exists:lms_quests, must be active (custom) |
| allocation_type | required, in:CLASS,SECTION,GROUP,STUDENT |
| target_id | required, integer, min:1, exists in target table (dynamic) |
| due_date | required, date, after_or_equal:now, max 2 years |
| cut_off_date | nullable, date, after_or_equal:due_date, max 2 years |
| is_auto_publish_result | boolean |
| result_publish_date | nullable, after_or_equal:due_date, prohibited_unless:is_auto_publish_result=true |

## 3.10 CRUD Conditions
| Operation | Allowed When | Restricted When |
|---|---|---|
| Create | `tenant.quest.create` | - |
| Update | `tenant.quest.update` | Should be restricted when PUBLISHED |
| Delete | `tenant.quest.delete` | - |
| Restore | `tenant.quest.restore` | Only if soft-deleted |
| Force Delete | `tenant.quest.forceDelete` | - |
| Publish | `tenant.quest.publish` | canPublish() must return true |
| Archive | `tenant.quest.archive` | - |
| Duplicate | `tenant.quest.duplicate` | - |
| Manage Questions | `tenant.quest.manageQuestions` | - |
| Manage Allocations | `tenant.quest.manageAllocations` | - |

## 3.11 Permission / Access Control Conditions
Policy: `app/Policies/QuestPolicy.php`

| Action | Permission |
|---|---|
| viewAny | `tenant.quest.viewAny` |
| view | `tenant.quest.view` |
| create | `tenant.quest.create` |
| update | `tenant.quest.update` |
| delete | `tenant.quest.delete` |
| restore | `tenant.quest.restore` |
| forceDelete | `tenant.quest.forceDelete` |
| status | `tenant.quest.status` |
| duplicate | `tenant.quest.duplicate` |
| publish | `tenant.quest.publish` |
| archive | `tenant.quest.archive` |
| manageQuestions | `tenant.quest.manageQuestions` |
| manageAllocations | `tenant.quest.manageAllocations` |

QuestPolicy is the most comprehensive of all module policies. `QuestAllocationPolicy` and `QuestQuestionPolicy` also exist.

## 3.12 Workflow Requirements
- Lifecycle: DRAFT → PUBLISHED → ARCHIVED
- `canPublish()` is implemented as a model method (richer than Quiz)
- `publish()`, `archive()`, `restoreQuest()` methods on model

## 3.13 Status / Lifecycle Rules
| Status | Meaning |
|---|---|
| DRAFT | Not visible to students |
| PUBLISHED | Active, `published_at` set, visible |
| ARCHIVED | Inactive, `is_active = false` |
| pending flag | In-progress / awaiting action (meaning unclear) |

## 3.14 Module Dependencies
Same as Quiz: Syllabus, SchoolSetup, QuestionBank, Prime, StudentProfile.
Also reuses `lms_assessment_types` and `lms_difficulty_distribution_configs` from LmsQuiz.

## 3.15 Exception / Edge Conditions
1. **Route duplication**: Quest question routes appear twice in tenant.php (around lines 608 and 632). This causes the first group to be shadowed and never matched. (derived from code)
2. `academic_session_id`, `class_id`, `subject_id`, `lesson_id` are nullable in QuestRequest — quests can be created without academic context. (derived from code)
3. `duplicate()` fires individual save() per question/scope — may be slow for large quests. (derived from code)
4. `QuestRequest.duration_minutes` max is 300, but `QuizRequest` allows 600. Inconsistency. (derived from code)

## 3.16 Requirements Derived from Excel
N/A

## 3.17 Requirements Derived from Code
All derived from code.

## 3.18 Final Consolidated Requirements
1. Quest mirrors Quiz with additional scope definition and richer lifecycle methods.
2. Academic context fields should be required (not nullable) for meaningful assessment.
3. Allocation controls (due_date, cut-off, result publish) are well-implemented.
4. QuestPolicy is the most complete policy in the LMS suite.

## 3.19 Code Review Observations
1. **Route duplication in tenant.php**: Quest question routes registered twice. Second registration overrides first silently.
2. **Nullable academic fields in QuestRequest**: `class_id`, `subject_id`, `lesson_id`, `academic_session_id` are nullable — quests without academic context can be saved. This contradicts business logic.
3. **Duration max inconsistency**: Quest 300 min max vs Quiz 600 min max.
4. **`pending` flag**: Purpose/meaning undocumented. No workflow logic tied to it.
5. **`QuestAllocation` table name**: Not confirmed in a migration; referred to as `lms_quest_allocations` (inferred).
6. **`Quest.duplicate()` uses `replicate()`**: Laravel replicate() does not copy media. If media is ever added to quests, duplication will break.

## 3.20 Suggestions
1. Fix route duplication — remove one of the two quest-question route groups.
2. Make academic context fields required in QuestRequest (matching QuizRequest).
3. Standardize duration_minutes max across Quiz and Quest.
4. Document and implement business logic for the `pending` flag.
5. Implement a `QuestDuplicateService` for clean cloning with proper media handling.

---

# 4. LMSEXAM MODULE

**Module path:** `Modules/LmsExam/`
**Table prefix:** `lms_exam*`
**Route prefix:** `/lms-exam/*`
**Status:** ~90% complete (derived from code)

## 4.1 Module Purpose
Manages formal examinations — both online and offline. This is the most complex LMS module with 11 controllers and 11 models. Exams are structured in a 4-level hierarchy: Exam → ExamPaper → PaperSet → PaperSetQuestion. Supports blueprints (section-wise question type breakdown), scope (lesson/topic coverage), student groups, flexible allocation (class/section/group/student), and status events.

## 4.2 Scope
- Exam CRUD (academic session + class + exam type)
- Exam Type management
- Exam Status Event management (lifecycle states)
- Exam Paper CRUD (per exam, per class+subject, mode: ONLINE/OFFLINE)
- Exam Scope (lesson+topic+question_type per paper)
- Exam Blueprint (section-wise marking scheme per paper)
- Exam Paper Set CRUD (a versioned question set)
- Paper Set Question CRUD + bulk add/reorder/mark override
- Exam Student Group CRUD + Group Member management
- Exam Allocation (paper set → audience with time scheduling)

## 4.3 Actors / Users
- School Administrator (exam creation, type and status setup)
- Teacher / Examiner (paper creation, blueprint, question addition)
- Invigilator (allocation scheduling)
- Student (receives exam allocation — not yet implemented)

## 4.4 Entry Points (Routes Found)
Under prefix `/lms-exam/` with name prefix `lms-exam.`, middleware `['auth', 'verified']`.

Key routes (abbreviated):
- `exam.*` — Exam CRUD + trash/restore/force-delete/toggleStatus
- `exam-paper.*` — ExamPaper CRUD + extras
- `exam-scope.*` — ExamScope CRUD
- `exam-blueprint.*` — ExamBlueprint CRUD
- `paper-set.*` — ExamPaperSet CRUD
- `paper-set-question.*` — PaperSetQuestion CRUD + bulk-store/bulk-destroy/update-ordinal/update-marks/update-compulsory + search/existing/getSections/getSubjectGroups/getSubjects/getLessons/getTopics
- `exam-student-group.*` — ExamStudentGroup CRUD
- `exam-group-member.*` — ExamStudentGroupMember CRUD + getGroupDetails
- `exam-type.*` — ExamType CRUD
- `exam-status-event.*` — ExamStatusEvent CRUD
- `exam-allocation.*` — ExamAllocation CRUD + paperSets/sections/examGroups/students AJAX

## 4.5 Core Entities

| Model | Table | Description |
|---|---|---|
| Exam | `lms_exams` | Top-level exam container |
| ExamType | `lms_exam_types` | Type: Unit Test, Term Exam, etc. |
| ExamStatusEvent | `lms_exam_status_events` | Status values: DRAFT/PUBLISHED/CONCLUDED/ARCHIVED |
| ExamPaper | `lms_exam_papers` | Subject-specific paper, ONLINE or OFFLINE |
| ExamScope | `lms_exam_scopes` | Lesson+topic coverage per paper |
| ExamBlueprint | `lms_exam_blueprints` | Section-wise marking scheme per paper |
| ExamPaperSet | `lms_exam_paper_sets` | Versioned question set for a paper |
| PaperSetQuestion | (inferred: `lms_paper_set_questions`) | Question in a paper set |
| ExamStudentGroup | `lms_exam_student_groups` | Custom student grouping |
| ExamStudentGroupMember | (inferred: `lms_exam_student_group_members`) | Student in a group |
| ExamAllocation | `lms_exam_allocations` | Paper set allocated to audience |

## 4.6 Field-Level Requirements

### lms_exams (Exam model)
| Field | Type | Required | Validation |
|---|---|---|---|
| uuid | UUID | auto | |
| academic_session_id | FK | Yes | required (no exists validation) |
| class_id | FK | Yes | required, exists:sch_classes |
| exam_type_id | FK | Yes | required, exists:lms_exam_types, unique per session+class |
| code | string(50) | No | nullable, unique |
| title | string(150) | Yes | required |
| description | text | No | |
| start_date | date | Yes | before_or_equal:end_date |
| end_date | date | Yes | after_or_equal:start_date |
| grading_schema_id | FK | No | exists:slb_grade_division_master |
| status_id | FK | Yes | required, exists:lms_exam_status_events |
| created_by | FK User | auto | set in boot() |
| is_active | boolean | No | |

### lms_exam_papers (ExamPaper model)
| Field | Type | Required | Notes |
|---|---|---|---|
| exam_id | FK | Yes | exists:lms_exams |
| class_id | FK | Yes | exists:sch_classes |
| subject_id | FK | Yes | exists:sch_subjects |
| paper_code | string(50) | Yes | unique per exam |
| title | string(150) | Yes | |
| mode | ENUM | Yes | ONLINE / OFFLINE |
| total_marks | decimal | Yes | min:0, max:999999.99 |
| passing_percentage | decimal | Yes | 0-100 |
| total_questions | integer | No | |
| duration_minutes | integer | No | 1-1440 |
| negative_marks | decimal | No | min:0 |
| is_proctored | boolean | No | |
| is_ai_proctored | boolean | No | |
| fullscreen_required | boolean | No | |
| browser_lock_required | boolean | No | |
| shuffle_questions | boolean | No | |
| show_result_type | ENUM | conditional | required_if:mode=ONLINE; IMMEDIATE/SCHEDULED/MANUAL |
| scheduled_result_at | datetime | conditional | required_if:show_result_type=SCHEDULED; after:now |
| offline_entry_mode | ENUM | conditional | required_if:mode=OFFLINE; BULK_TOTAL/QUESTION_WISE |
| only_unused_questions | boolean | No | |
| only_authorised_questions | boolean | No | |
| difficulty_config_id | FK | No | |
| status_id | FK | Yes | exists:lms_exam_status_events |

### lms_exam_allocations (ExamAllocation model)
| Field | Type | Required | Notes |
|---|---|---|---|
| exam_paper_id | FK | Yes | exists:lms_exam_papers |
| paper_set_id | FK | Yes | exists:lms_exam_paper_sets |
| allocation_type | ENUM | Yes | CLASS/SECTION/EXAM_GROUP/STUDENT |
| class_id | FK | Yes | exists:sch_classes |
| section_id | FK | conditional | required if SECTION |
| exam_group_id | FK | conditional | required if EXAM_GROUP |
| student_id | FK | conditional | required if STUDENT |
| scheduled_date | date | No | |
| scheduled_start_time | time | Yes | H:i format |
| scheduled_end_time | time | Yes | H:i format, after:start |
| location | string(100) | No | |
| is_active | boolean | No | |

## 4.7 Functional Requirements
1. Exam created at session+class level, with unique exam_type per session+class. (derived from code)
2. Exam code auto-generated from session+class+examType+random. (derived from code)
3. Exam status tracked via `ExamStatusEvent` FK (not ENUM directly on exam). (derived from code)
4. Each exam can have multiple papers (per subject). Papers can be ONLINE or OFFLINE. (derived from code)
5. ONLINE papers support proctoring controls (AI proctoring, fullscreen, browser lock, shuffle). (derived from code)
6. OFFLINE papers have entry modes (BULK_TOTAL or QUESTION_WISE). (derived from code)
7. Exam Blueprint defines the marking scheme: sections by question type with marks per question. (derived from code: ExamBlueprint model)
8. Exam Scope defines which lessons and topics to draw questions from, with weightage. (derived from code: ExamScope model)
9. Paper Sets are versioned question sets (a paper may have Set A, Set B). (derived from code)
10. Questions added to paper set via bulk-store with ordinal, marks, compulsory flags. (derived from code: routes)
11. `update-compulsory` endpoint sets individual question as compulsory. (derived from code: route)
12. Exam Student Group allows custom grouping of students across sections. (derived from code)
13. Allocation supports CLASS/SECTION/EXAM_GROUP/STUDENT with precise time scheduling (date, start_time, end_time, location). (derived from code)
14. AJAX endpoints for allocation: paperSets, sections, examGroups, students. (derived from code: routes)
15. Exam statistics computed: total_papers, online/offline split, student_groups, allocations, duration_days. (derived from code: Exam.getStatisticsAttribute)

## 4.8 Business Rules
1. Exam type must be unique per (academic_session + class). One session+class cannot have two "Unit Test 1" exams. (derived from code: ExamRequest unique rule)
2. start_date must be <= end_date. (derived from code: ExamRequest)
3. For ONLINE papers: `show_result_type` is required; if SCHEDULED, `scheduled_result_at` must be after now. (derived from code: ExamPaperRequest)
4. For OFFLINE papers: `offline_entry_mode` is required. (derived from code)
5. Paper code unique within exam. (derived from code: ExamPaperRequest Rule::unique with where exam_id)
6. Allocation end_time must be after start_time. (derived from code)
7. Allocation target varies by type: CLASS → only class_id; SECTION → section_id required; EXAM_GROUP → exam_group_id required; STUDENT → student_id required. (derived from code)
8. Exam status is stored as FK to ExamStatusEvent, not as ENUM. Status transitions through status events. (derived from code)

## 4.9 Validation Rules (Key Requests)

### ExamRequest
| Field | Rule |
|---|---|
| academic_session_id | required (no exists) |
| class_id | required, exists:sch_classes |
| exam_type_id | required, exists:lms_exam_types, unique per session+class (ignore self) |
| title | required, string, max:150 |
| start_date | required, date, before_or_equal:end_date |
| end_date | required, date, after_or_equal:start_date |
| status_id | required, exists:lms_exam_status_events |
| grading_schema_id | nullable, exists:slb_grade_division_master |

### ExamPaperRequest (key conditionals)
| Field | Rule |
|---|---|
| mode | required, in:ONLINE,OFFLINE |
| show_result_type | required_if:mode=ONLINE, in:IMMEDIATE,SCHEDULED,MANUAL |
| scheduled_result_at | nullable, required_if:show_result_type=SCHEDULED, date, after:now |
| offline_entry_mode | required_if:mode=OFFLINE, in:BULK_TOTAL,QUESTION_WISE |
| paper_code | required, unique per exam (ignore self) |

### ExamAllocationRequest (conditional by type)
| Allocation Type | Required Fields |
|---|---|
| CLASS | class_id |
| SECTION | class_id + section_id |
| EXAM_GROUP | class_id + exam_group_id |
| STUDENT | class_id + student_id |

## 4.10 CRUD Conditions
| Operation | Allowed When | Restricted When |
|---|---|---|
| Create Exam | `tenant.exam.create` | - |
| Edit Exam | `tenant.exam.update` | Should be restricted when CONCLUDED/ARCHIVED |
| Delete | `tenant.exam.delete` | Ideally when no allocations exist |
| Restore | `tenant.exam.restore` | Only if soft-deleted |
| Force Delete | `tenant.exam.forceDelete` | - |
| Import | `tenant.exam.import` | - |
| Export | `tenant.exam.export` | - |
| Print | `tenant.exam.print` | - |

## 4.11 Permission / Access Control Conditions
Policy: `app/Policies/ExamPolicy.php`

| Action | Permission |
|---|---|
| viewAny | `tenant.exam.viewAny` |
| view | `tenant.exam.view` |
| status | `tenant.exam.status` |
| create | `tenant.exam.create` |
| update | `tenant.exam.update` |
| delete | `tenant.exam.delete` |
| restore | `tenant.exam.restore` |
| forceDelete | `tenant.exam.forceDelete` |
| import | `tenant.exam.import` |
| export | `tenant.exam.export` |
| print | `tenant.exam.print` |

Separate policies exist for: `ExamAllocationPolicy`, `ExamPaperPolicy`, `ExamPaperSetPolicy`, `ExamStatusEventPolicy`, `ExamStudentGroupPolicy`, `ExamStudentGroupMemberPolicy`, `ExamTypePolicy`, `PaperSetQuestionPolicy`.

## 4.12 Workflow Requirements
Exam status lifecycle managed via ExamStatusEvent:
- DRAFT → PUBLISHED → CONCLUDED → ARCHIVED
- Status stored as FK to `lms_exam_status_events` table (dynamic, configurable)
- No code-enforced state machine transitions found

## 4.13 Status / Lifecycle Rules
| Status Code | Meaning |
|---|---|
| DRAFT | Created, not released |
| PUBLISHED | Released to students |
| CONCLUDED | Exam period over |
| ARCHIVED | Historical record |

Paper-level status also uses `status_id` FK to `lms_exam_status_events`.

## 4.14 Module Dependencies
| Depends On | Reason |
|---|---|
| Syllabus | Lesson, Topic, QuestionType, GradeDivisionMaster |
| SchoolSetup | SchoolClass, Subject, Section |
| QuestionBank | Questions for paper sets |
| LmsQuiz | DifficultyDistributionConfig |
| Prime | AcademicSession, User |
| StudentProfile | Student |

## 4.15 Exception / Edge Conditions
1. `academic_session_id` on Exam has no `exists` validation. (derived from code)
2. `Exam.generateExamCode()` references `AcademicSession::find()` — `$session->code` will throw if session not found; no null-safe operator. (derived from code)
3. `Exam.getStatisticsAttribute()` calls `DB::raw()` — use of facade inside model attribute may cause issues in testing/mocking. (derived from code)
4. `ExamPaper` has no uniqueness constraint on (exam_id + class_id + subject_id) — a paper for the same subject in the same exam can be created multiple times. (derived from code)
5. `scheduled_end_time` validation: `after:scheduled_start_time` uses string H:i format comparison. Cross-midnight scheduling not handled.

## 4.16 Requirements Derived from Excel
N/A

## 4.17 Requirements Derived from Code
All derived from code.

## 4.18 Final Consolidated Requirements
1. Exam is the most feature-rich LMS module with 4-level hierarchy.
2. ONLINE vs OFFLINE mode determines different validation paths.
3. Blueprint and Scope together define what questions should be in the paper.
4. Student group management allows custom allocation beyond standard class/section.
5. All sub-entities support soft delete + restore.
6. Paper codes must be unique per exam.

## 4.19 Code Review Observations
1. **No exists on `academic_session_id`**: Same as Quiz and Quest.
2. **`generateExamCode()` null safety**: `$session->code ?? 'GEN'` — this is safe IF $session is null. But `AcademicSession::find()` returns null on miss, so `$session->code` with no null-safe fails. Wait — code uses `$session->code ?? 'GEN'` which is PHP null-coalescing. If `$session` is null, this throws `TypeError` not `ErrorException`. **Actually**, `null->code` throws in PHP 8+. (derived from code: Exam.php line ~58)
3. **Exam paper duplicate per subject**: No unique constraint in request validation for same subject in same exam.
4. **ExamPolicy import/export/print**: These permission checks exist in policy but likely no controller implementation yet.
5. **`ExamAllocation` uses `scheduled_start_time` / `scheduled_end_time` cast as `datetime`**: But validation rules use `date_format:H:i`. Mismatch may cause casting errors.
6. **Double route prefix `lms-exam` in tenant.php**: The entire exam group is correctly nested. No duplication found (good).
7. **ExamBlueprint ordinal**: No unique constraint in request found — multiple blueprints can have same ordinal.

## 4.20 Suggestions
1. Add null-safe call in `generateExamCode()`: `$session?->code ?? 'GEN'`.
2. Add unique constraint for (exam_id + class_id + subject_id) on ExamPaper.
3. Add `exists` validation for `academic_session_id`.
4. Implement a state machine for exam status transitions.
5. Add `ExamBlueprintRequest` with unique ordinal validation per exam paper.
6. Consider storing `scheduled_start_time` and `scheduled_end_time` as TIME type in DB and VARCHAR in validation, not datetime.

---

# 5. LMSHOMEWORK MODULE

**Module path:** `Modules/LmsHomework/`
**Table prefix:** `lms_homework*`, `lms_rule_engine_configs`, `lms_trigger_events`, `lms_action_type`
**Route prefix:** `/lms-home-work/*`
**Status:** ~80% complete (derived from code)

## 5.1 Module Purpose
Manages homework assignment, submission, grading, and an automated rule engine for actions triggered on homework events. Teachers assign homework to a class/section with due dates; students submit responses (text + file uploads via Spatie Media Library); teachers grade submissions. A rule engine can trigger automated actions (notifications, escalations) based on configurable events.

## 5.2 Scope
- Homework CRUD (assign homework to class/section/subject/topic)
- Homework Submission CRUD (student response with file attachments)
- Homework Submission Review / Grading
- Trigger Event management (events that can trigger rules)
- Action Type management (what action to take)
- Rule Engine Config CRUD (if event X then action Y for class group Z)

## 5.3 Actors / Users
- Teacher (creates homework, reviews/grades submissions)
- Student (views homework, submits responses)
- Administrator (manages trigger events, action types, rule engine)
- System (rule engine automation)

## 5.4 Entry Points (Routes Found)
Under prefix `/lms-home-work/` with name prefix `lms-home-work.`, middleware `['auth', 'verified']`.

| Route | Description |
|---|---|
| lms-home-work.home-works.* | Homework CRUD + trash/restore/force-delete/toggleStatus |
| lms-home-work.trigger-event.* | TriggerEvent CRUD + extras |
| lms-home-work.homework-submission.* | HomeworkSubmission CRUD + extras |
| lms-home-work.homework-submission.review | PUT: review/grade submission |
| lms-home-work.action-types.* | ActionType CRUD + extras |
| lms-home-work.rule-engine-configs.* | RuleEngineConfig CRUD + extras |

## 5.5 Core Entities

| Model | Table | Description |
|---|---|---|
| Homework | `lms_homework` | Assignment per class/section |
| HomeworkSubmission | `lms_homework_submissions` | Student's response |
| TriggerEvent | `lms_trigger_events` | Named event (HOMEWORK_SUBMITTED, etc.) |
| ActionType | `lms_action_type` | Action to take (NOTIFY_TEACHER, etc.) |
| RuleEngineConfig | `lms_rule_engine_configs` | Rule: trigger → action for class group |

## 5.6 Field-Level Requirements

### lms_homework (Homework model)
| Field | Type | Required | Validation |
|---|---|---|---|
| academic_session_id | FK | No | (missing from HomeworkRequest!) |
| class_id | FK | Yes | required, exists:sch_classes |
| section_id | FK | No | nullable, exists:sch_sections |
| subject_id | FK | Yes | required, exists:sch_subjects |
| topic_id | FK | No | nullable, exists:slb_topics |
| lesson_id | FK | No | nullable, exists:slb_lessons |
| title | string(255) | Yes | required |
| description | text | Yes | required |
| submission_type_id | FK Dropdown | Yes | required, exists:sys_dropdowns |
| is_gradable | boolean | No | default false |
| max_marks | decimal | No | nullable, 0-999.99 |
| passing_marks | decimal | No | nullable, 0-999.99, lte:max_marks |
| difficulty_level_id | FK | No | nullable, exists:slb_complexity_level |
| assign_date | datetime | Yes | required, after_or_equal:today (on create) |
| due_date | datetime | Yes | required, after:assign_date |
| allow_late_submission | boolean | No | |
| auto_publish_score | boolean | No | |
| release_condition_id | FK Dropdown | No | nullable, exists:sys_dropdowns |
| status_id | FK Dropdown | Yes | required, exists:sys_dropdowns |
| is_active | boolean | No | |
| created_by | FK | No | |
| updated_by | FK | No | |

### lms_homework_submissions (HomeworkSubmission model)
| Field | Type | Required | Notes |
|---|---|---|---|
| homework_id | FK | Yes | |
| student_id | FK | Yes | |
| submitted_at | datetime | No | |
| submission_text | text | No | |
| status_id | FK Dropdown | No | |
| marks_obtained | decimal(2) | No | |
| teacher_feedback | text | No | |
| graded_by | FK User | No | |
| graded_at | datetime | No | |
| is_late | boolean | No | |
| files | media | No | Via Spatie MediaLibrary |

### lms_rule_engine_configs (RuleEngineConfig model)
| Field | Type | Notes |
|---|---|---|
| rule_code | string | |
| rule_name | string | |
| description | text | |
| trigger_event_id | FK | |
| applicable_class_group_id | FK | |
| logic_config | JSON | Array config |
| action_type_id | FK | |
| is_active | boolean | |

## 5.7 Functional Requirements
1. Create, edit, soft-delete, restore homework assignments. (derived from code)
2. Homework assigned to a class (required) and optionally a section. (derived from code)
3. Assign date must be >= today on creation; can be past on updates. (derived from code: HomeworkRequest)
4. Due date must always be after assign_date. (derived from code)
5. `passing_marks` must be <= `max_marks`. (derived from code: validation `lte:max_marks`)
6. Student submits text response + file uploads (Spatie MediaLibrary). (derived from code: HomeworkSubmission)
7. Submission media stored in collection `homework_submission_files`. (derived from code)
8. Teacher reviews/grades submission via dedicated `review` PUT endpoint. (derived from code: route)
9. `is_late` flag on submission: automatically set if submitted after due_date. (derived from code: model accessor)
10. Rule Engine: trigger events map to actions for class groups. `logic_config` is JSON. (derived from code)
11. TriggerEvent and ActionType are configurable reference entities. (derived from code)
12. `auto_publish_score`: if true, student can see marks immediately on grading. (derived from code: field)
13. Status toggle available for homework. (derived from code: routes)

## 5.8 Business Rules
1. `assign_date` >= today on create. On update, past assign_date allowed. (derived from code)
2. `due_date` > `assign_date`. (derived from code)
3. `passing_marks` <= `max_marks`. (derived from code)
4. Homework is only deletable if `submission_count == 0`. (derived from code: `Homework.isDeletable()`)
5. Homework is only editable when in DRAFT status. (derived from code: `Homework.isEditable()`)
6. `academic_session_id` is in model `fillable` but absent from HomeworkRequest — not validated. (derived from code — gap)
7. Rule engine is scoped to `applicable_class_group_id`, linking to `sch_class_groups_jnt`. (derived from code)

## 5.9 Validation Rules (HomeworkRequest)
| Field | Rule |
|---|---|
| class_id | required, exists:sch_classes |
| section_id | nullable, exists:sch_sections |
| subject_id | required, exists:sch_subjects |
| topic_id | nullable, exists:slb_topics |
| lesson_id | nullable, exists:slb_lessons |
| title | required, string, max:255 |
| description | required, string |
| submission_type_id | required, exists:sys_dropdowns |
| is_gradable | boolean |
| max_marks | nullable, numeric, min:0, max:999.99 |
| passing_marks | nullable, numeric, min:0, max:999.99, lte:max_marks |
| difficulty_level_id | nullable, exists:slb_complexity_level |
| assign_date | required, date, after_or_equal:today (create only) |
| due_date | required, date, after:assign_date |
| status_id | required, exists:sys_dropdowns |

## 5.10 CRUD Conditions
| Operation | Allowed When | Restricted When |
|---|---|---|
| Create | Authenticated | - |
| Edit | `Homework.isEditable()` (status = DRAFT) | Status not DRAFT |
| Delete | `Homework.isDeletable()` (no submissions) | Has submissions |
| Soft Delete | Always (override isDeletable?) | |
| Restore | Only if soft-deleted | |
| Grade Submission | Authenticated teacher | Already graded? No guard found |

## 5.11 Permission / Access Control Conditions
No dedicated `HomeworkPolicy` file found. No `HomeworkSubmissionPolicy` found. This is a significant gap — any authenticated user can access homework endpoints.

## 5.12 Workflow Requirements
Homework lifecycle:
- DRAFT → PUBLISHED → SUBMITTED (by students) → GRADED
- Status stored via `status_id` FK to `sys_dropdowns`
- `isEditable()` checks config `lmshomework.status.draft` — this config key must exist

## 5.13 Status / Lifecycle Rules
| Status | Meaning |
|---|---|
| DRAFT | Not yet visible to students |
| PUBLISHED | Visible, accepting submissions |
| SUBMITTED | Student has submitted |
| GRADED | Teacher has reviewed |

`is_late` on submission: derived from whether `submitted_at > homework.due_date`. (derived from code: model accessor computes this dynamically)

## 5.14 Module Dependencies
| Depends On | Reason |
|---|---|
| Syllabus | Topic, Lesson, ComplexityLevel |
| SchoolSetup | SchoolClass, Section, SchClassGroupsJnt |
| StudentProfile | Student |
| Prime | User, Dropdown |
| GlobalMaster | Dropdown (HomeworkSubmission uses GlobalMaster\Dropdown) |

Note: `Homework` model imports `Modules\Prime\Models\Dropdown` while `HomeworkSubmission` imports `Modules\GlobalMaster\Models\Dropdown`. Inconsistency may cause issues if the two Dropdown models differ.

## 5.15 Exception / Edge Conditions
1. `Homework.academicSession()` relationship uses undefined `SchAcademicSession::class` — same bug as in Lesson.php. (derived from code)
2. **Policy gap**: No `HomeworkPolicy` — any authenticated user can CRUD homework.
3. **Two Dropdown models**: `Prime\Dropdown` (Homework) vs `GlobalMaster\Dropdown` (HomeworkSubmission). This inconsistency may cause runtime errors.
4. **`isEditable()` relies on config**: `config('lmshomework.status.draft')` — if config not set, this returns null, and comparison always fails (homework always appears uneditable). (derived from code)
5. **Spatie MediaLibrary PHP 8.4 deprecation**: Known issue per CLAUDE.md.
6. **Grade endpoint**: `review/{review}` — unclear what `$review` resolves to. If it's HomeworkSubmission ID, model binding name should be `submission`. (derived from code: route definition)

## 5.16 Requirements Derived from Excel
N/A

## 5.17 Requirements Derived from Code
All derived from code.

## 5.18 Final Consolidated Requirements
1. Homework links to class (required), section (optional), subject (required), lesson and topic (optional).
2. Date constraints: assign_date >= today on create; due_date > assign_date always.
3. File uploads on submissions via Spatie MediaLibrary.
4. Teacher grades submissions with feedback and optional marks.
5. Rule engine allows configurable automation on homework events.
6. Submission deletion guard: homework cannot be deleted if submissions exist.

## 5.19 Code Review Observations
1. **No HomeworkPolicy**: Critical security gap.
2. **Dual Dropdown model reference**: Homework uses Prime\Dropdown; HomeworkSubmission uses GlobalMaster\Dropdown.
3. **`Homework.academicSession()` broken**: References undefined class `SchAcademicSession`.
-> comment -> this releteion reletd give me details thei will tell you what you do

> **📋 REVIEW RESOLUTION**
> **Question:** Owner asks for details on the broken academicSession() relationship. Owner will decide what to do after review.
> **Final Answer:** CONFIRMED BUG. `Homework.php` line 71 calls `SchAcademicSession::class` which is not imported anywhere in the file. This causes a PHP fatal error (`Error: Class "SchAcademicSession" not found`) at runtime when any code calls `$homework->academicSession`.
> **Explanation:** The correct class that should be used is `Modules\SchoolSetup\Models\OrganizationAcademicSession`. The fix requires two lines: (1) Add `use Modules\SchoolSetup\Models\OrganizationAcademicSession;` at the top of `Homework.php`. (2) Replace `SchAcademicSession::class` with `OrganizationAcademicSession::class` at line 71. No other code needs to change. This is a minimal, safe, non-breaking fix.
> **Basis:** Derived from code — confirmed in Homework.php line 71
> **Impact:** All features that load homework with academic session data (listing, reports, code generation) will crash until fixed.
> **Recommendation:** Task card: "Fix Homework.php academicSession() — add import + fix class name — 2 lines only — trigger: owner go-ahead." 

4. **`lmshomework.status.draft` config**: If config file missing, isEditable() breaks.
5. **`HomeworkSubmission` `student()` relationship**: Binds to `SysUser::class` not `Student::class` — students are looked up as users, not student entities. This may be intentional (students are users) but needs verification.
6. **Route name `homework-submission.toggleStatus`**: Uses `{trigger_event}` as route parameter instead of `{homework_submission}`. Likely copy-paste error.
7. **`HomeworkRequest` missing `academic_session_id`**: Field in fillable but not in request rules.

## 5.20 Suggestions
1. Create `HomeworkPolicy` and `HomeworkSubmissionPolicy`.
2. Fix `Homework.academicSession()` to use `OrganizationAcademicSession`.
3. Standardize Dropdown model usage (use one consistent model).
4. Add `academic_session_id` to HomeworkRequest with validation.
5. Fix route parameter name from `{trigger_event}` to `{homework_submission}` on toggleStatus.
6. Add a config file `lmshomework.php` with `status.draft` value.
7. Add guard on grade endpoint to prevent re-grading without explicit intent.

---

# 6. QUESTIONBANK MODULE

**Module path:** `Modules/QuestionBank/`
**Table prefix:** `qns_*`
**Route prefix:** `/question-bank/*`
**Status:** ~85% complete (derived from code)

## 6.1 Module Purpose
Central repository for all questions used across Quiz, Quest, and Exam modules. Manages rich question metadata (Bloom's taxonomy, cognitive skill, complexity, question type, specificity), multiple options with correctness flags, media attachments, tagging, versioning, performance category mapping, usage statistics, and AI-powered question generation via ChatGPT/Gemini integration.

## 6.2 Scope
- Question CRUD with full academic and taxonomic metadata
- Question Option management (MCQ choices with is_correct)
- Question Media Store CRUD (file uploads)
- Media linking to questions
- Question Tag CRUD and tagging
- Question Usage Type CRUD
- Question Version CRUD (versioning history)
- Question Statistic tracking
- AI Question Generator (ChatGPT/Gemini)
- CSV import/export of questions
- Question print view

## 6.3 Actors / Users
- Teacher/Content Creator (creates and tags questions)
- School Administrator (manages reference data, usage types)
- AI System (generates questions via external API)
- Quiz/Quest/Exam modules (consume questions)

## 6.4 Entry Points (Routes Found)
Under prefix `/question-bank/` with name prefix `question-bank.`, middleware `['auth', 'verified']`.

| Route | Description |
|---|---|
| question-bank.question-bank.* | QuestionBank CRUD + trash/restore/force-delete/toggleStatus |
| question-bank.question-bank.print | GET: print view |
| question-bank.question-bank.validate-file | POST: CSV import validation |
| question-bank.question-bank.start-import | POST: CSV import start |
| question-bank.question-usage-log.toggleStatus | POST: toggle usage log status |
| question-bank.question-media-store.* | MediaStore CRUD + extras |
| question-bank.question-statistic.* | Statistic CRUD + extras |
| question-bank.question-tag.* | Tag CRUD + extras |
| question-bank.question-usage-type.* | UsageType CRUD + extras |
| question-bank.question-version.* | Version CRUD + extras |
| question-bank.ai-question-generator | GET: AI Generator UI |
| question-bank.getSections | GET AJAX: sections |
| question-bank.getSubjectGroups | GET AJAX: subject groups |
| question-bank.getSubjects | GET AJAX: subjects |
| question-bank.getLessons | GET AJAX: lessons |
| question-bank.getTopics | GET AJAX: topics |
| question-bank.generateQuestions | POST: generate via AI |
| question-bank.saveQuestions | POST: save AI questions |
| question-bank.downloadCSV | POST: download as CSV |
| question-bank.ai-question-generator.getProviders | GET: list AI providers |
| question-bank.ai-provider.status | GET: check provider status |

## 6.5 Core Entities

| Model | Table | Description |
|---|---|---|
| QuestionBank | `qns_questions_bank` | Main question entity |
| QuestionOption | `qns_question_options` (from migration) | MCQ options |
| QuestionMediaStore | `qns_media_store` (from migration) | Uploaded media files |
| QuestionMedia | `qns_question_media_jnt` (from migration) | Link: question ↔ media |
| QuestionTag | (inferred: `qns_question_tags`) | Tags |
| QuestionQuestionTagJnt | (inferred: `qns_question_tag_jnt`) | Question ↔ Tag |
| QuestionTopicJnt | (inferred: `qns_question_topic_jnt`) | Question ↔ Topic (additional) |
| QuestionPerformanceCategoryJnt | (inferred) | Question ↔ PerformanceCategory |
| QuestionStatistic | (inferred: `qns_question_statistics`) | Usage/performance stats |
| QuestionVersion | (inferred: `qns_question_versions`) | Version history |
| QuestionUsageType | (inferred: `qns_question_usage_types`) | Usage classification |
| QuestionUsageLog | (inferred: `qns_question_usage_logs`) | Audit trail |
| QuestionReviewLog | (inferred: `qns_question_review_logs`) | Review history |

## 6.6 Field-Level Requirements

### qns_questions_bank (QuestionBank model)
| Field | Type | Notes |
|---|---|---|
| uuid | binary(16) | UUID stored as bytes; accessor converts BIN_TO_UUID |
| class_id | FK | exists:sch_classes |
| subject_id | FK | exists:sch_subjects |
| lesson_id | FK | exists:slb_lessons |
| topic_id | FK | exists:slb_topics |
| competency_id | FK | exists competencies |
| ques_title | string | Question short title |
| ques_title_display | boolean | Whether to show title |
| question_content | richtext | Full question content (HTML/markdown) |
| content_format | string | HTML/plain/markdown |
| teacher_explanation | text | Explanation for teacher |
| bloom_id | FK | BloomTaxonomy |
| cognitive_skill_id | FK | CognitiveSkill |
| ques_type_specificity_id | FK | QueTypeSpecifity |
| complexity_level_id | FK | ComplexityLevel |
| question_type_id | FK | QuestionType |
| expected_time_to_answer_seconds | integer | Expected time |
| marks | decimal(2) | Default marks |
| negative_marks | decimal(2) | Negative marking |
| current_version | integer | Current version number |
| for_quiz | boolean | Usable in quiz |
| for_assessment | boolean | Usable in assessment/quest |
| for_exam | boolean | Usable in exam |
| ques_owner | string | Owner identifier |
| created_by_AI | boolean | AI-generated flag |
| created_by | FK User | Creator |
| is_school_specific | boolean | Tenant-only availability |
| availability | ENUM | GLOBAL/SCHOOL_ONLY/CLASS_ONLY |
| selected_entity_group_id | FK | When availability=GROUP |
| selected_section_id | FK | When availability=SECTION |
| selected_student_id | FK | When availability=STUDENT |
| book_id | FK | Source book |
| book_page_ref | string | Page reference |
| external_ref | string | External reference |
| reference_material | text | Reference content |
| status | ENUM | DRAFT/PENDING_REVIEW/APPROVED/REJECTED |
| ques_reviewed | boolean | Review flag |
| ques_reviewed_by | FK User | Reviewer |
| ques_reviewed_at | datetime | Review timestamp |
| ques_reviewed_status | ENUM | APPROVED/REJECTED (inferred from scopeApproved) |
| is_active | boolean | |

## 6.7 Functional Requirements
1. Full CRUD with soft delete/restore/force-delete/toggleStatus. (derived from code)
2. Question UUID stored as binary bytes; accessor converts to readable UUID. (derived from code)
3. Questions can be tagged (many-to-many via QuestionQuestionTagJnt). (derived from code)
4. Questions can be linked to additional topics beyond the primary topic (QuestionTopicJnt). (derived from code)
5. Questions can be linked to performance categories (QuestionPerformanceCategoryJnt). (derived from code)
6. Media attached in two ways: (a) stored via QuestionMediaStore, (b) linked via QuestionMedia junction. (derived from code)
7. Question versioning tracked via QuestionVersion. (derived from code)
8. Usage logged via QuestionUsageLog. (derived from code)
9. AI Generator: UI with class → subject-group → subject → lesson → topic cascade dropdowns. (derived from code)
10. AI supports ChatGPT (GPT-4o-mini) and Gemini (gemini-2.0-flash). (derived from code)
11. AI-generated questions can be saved directly to QuestionBank or downloaded as CSV. (derived from code)
12. CSV import: validate-file → start-import two-step process. (derived from code)
13. Print view for questions. (derived from code)
14. Availability control: GLOBAL / SCHOOL_ONLY / CLASS_ONLY with entity/section/student scoping. (derived from code)
15. Usage flags: `for_quiz`, `for_assessment`, `for_exam` control which modules can consume the question. (derived from code)

## 6.8 Business Rules
1. `for_quiz`, `for_assessment`, `for_exam` flags determine where the question appears in search. (derived from code: model scopes)
2. `availability=GLOBAL`: visible to all schools (shared bank). `SCHOOL_ONLY`: tenant-scoped. `CLASS_ONLY`: class-scoped. (derived from code: scopes)
3. `is_school_specific` flags school exclusivity. (derived from code)
4. `created_by_AI = true` marks AI-generated questions. (derived from code)
5. UUID is stored as binary in DB; always returned as readable UUID string via accessor. (derived from code)
6. Review workflow: questions go through approval — `ques_reviewed_status` can be APPROVED or REJECTED. (derived from code: scopeApproved)
7. Only APPROVED questions should appear in quiz/quest/exam question search (inferred from scope, not enforced in routes found).

## 6.9 Validation Rules (QuestionBankRequest)
The full request was saved to external file. Key rules observed:
- `class_id`, `subject_id`, `lesson_id`, `topic_id`: existence checks against respective tables.
- `question_type_id`: required, exists:slb_question_types.
- `complexity_level_id`, `bloom_id`, `cognitive_skill_id`: nullable FK references.
- `marks`: numeric, min:0.
- `availability`: in:GLOBAL,SCHOOL_ONLY,CLASS_ONLY (inferred from scopes).
- `status`: in:DRAFT,PENDING_REVIEW,APPROVED,REJECTED (inferred from model).

## 6.10 CRUD Conditions
| Operation | Allowed When | Restricted When |
|---|---|---|
| Create | `tenant.question-bank.create` | - |
| Edit | `tenant.question-bank.update` | Ideally when APPROVED (reviewed) questions should require re-review |
| Delete | `tenant.question-bank.delete` | |
| Restore | `tenant.question-bank.restore` | |
| Force Delete | `tenant.question-bank.forceDelete` | |
| Toggle Status | `tenant.question-bank.status` | |
| Print | `tenant.question-bank.print` | |
| Import (validate) | Any authenticated (no policy gate found) | |
| AI Generate | Any authenticated (no policy gate found) | |

## 6.11 Permission / Access Control Conditions
Policy: `app/Policies/QuestionBankPolicy.php`

| Action | Permission |
|---|---|
| viewAny | `tenant.question-bank.viewAny` |
| view | `tenant.question-bank.view` |
| create | `tenant.question-bank.create` |
| update | `tenant.question-bank.update` |
| delete | `tenant.question-bank.delete` |
| restore | `tenant.question-bank.restore` |
| forceDelete | `tenant.question-bank.forceDelete` |
| status | `tenant.question-bank.status` |
| print | `tenant.question-bank.print` |

Also: `AIQuestionPolicy`, `AiQuestionGeneratorPolicy`, `QuestionMediaStorePolicy`, `QuestionStatisticPolicy`, `QuestionTagPolicy`, `QuestionUsageLogPolicy`, `QuestionUsageTypePolicy`.

## 6.12 Workflow Requirements
- Question review: DRAFT → PENDING_REVIEW → APPROVED / REJECTED
- `ques_reviewed_at`, `ques_reviewed_by`, `ques_reviewed_status` track review.
- No code-enforced workflow gate found on controllers.

## 6.13 Status / Lifecycle Rules
| Status | Meaning |
|---|---|
| DRAFT | Created, not reviewed |
| PENDING_REVIEW | Submitted for review |
| APPROVED | Verified, usable in assessments |
| REJECTED | Rejected, needs rework |

## 6.14 Module Dependencies
| Depends On | Reason |
|---|---|
| Syllabus | QuestionType, BloomTaxonomy, CognitiveSkill, ComplexityLevel, QueTypeSpecificity, Topic, Lesson, Competencie, PerformanceCategory, Book |
| SchoolSetup | SchoolClass, Subject, Section, EntityGroup |
| StudentProfile | Student |
| Prime | User, AcademicSession |
| SyllabusBooks | Book |

## 6.15 Exception / Edge Conditions
1. **API keys hardcoded**: ChatGPT and Gemini API keys are hardcoded in `AIQuestionGeneratorController.php` as class properties. This is a critical security vulnerability. (derived from code)
2. **Both providers marked `'active' => false`**: Neither AI provider is active by default; the UI shows no providers. (derived from code)
-> comment -> this api key set in db or env file in future so dont worry i noted

> **📋 REVIEW RESOLUTION**
> **Question:** Owner says: API keys will be moved to DB or .env file in future — already noted. No action needed now.
> **Final Answer:** ACCEPTED AS FUTURE TASK. The hardcoded API keys and the inactive provider flags are both acknowledged. Owner plans to move them to `.env` or DB config in a future sprint. No immediate change required.
> **Basis:** Developer instruction
> **Impact:** AI question generation remains non-functional until keys are moved and providers are activated.
> **Recommendation:** Task card: "Move AI API keys to .env/config and activate providers — trigger: when owner instructs." 

3. **UUID binary storage**: `QuestionBank::booted()` sets `uuid = Str::uuid()->getBytes()` (binary). The accessor uses `DB::selectOne('SELECT BIN_TO_UUID(?) ...')` — this works only with MySQL; breaks with SQLite (tests). (derived from code)
4. **Duplicate model**: Both `QuestionStatistic.php` and `QuestionStatistics.php` exist — likely a copy-paste artifact. (derived from code: model listing)
-> comment -> duplicate check proper maxium use and not effcat in other module this vi se chnage and set QuestionStatistic this set

> **📋 REVIEW RESOLUTION**
> **Question:** Owner says: check maximum usage of both files, ensure no other module is affected, then change to use `QuestionStatistic` (singular) and remove the plural file.
> **Final Answer:** CONFIRMED — `QuestionStatistic` (singular) is the canonical model. `QuestionStatistics` (plural) is the redundant file to be removed AFTER full usage audit.
> **Explanation:** Code inspection results: `QuestionStatistic.php` is used in: (1) `QuestionBankController.php` (line 29, 412), (2) `QuestionStatisticController.php` (all methods). `QuestionStatistics.php` is also used in `QuestionBankController.php`. Before deletion, all references to `QuestionStatistics` in `QuestionBankController.php` must be replaced with `QuestionStatistic`. No other module (LmsQuiz, LmsExam, LmsHomework, LmsQuests, Syllabus) references either file. The change is safe and confined to QuestionBank module only.
> **Basis:** Derived from code (grep results confirmed)
> **Impact:** Safe to remove plural file once singular is confirmed everywhere.
> **Recommendation:** Task card: "Audit and remove QuestionStatistics.php — replace all QuestionBankController.php references with QuestionStatistic — verify no other module affected — trigger: owner go-ahead." 

5. **`QuestionUsageLog` model missing**: Referenced in `QuestionUsageLogPolicy` but no model file found in model listing. (derived from code)
6. **CSV import without size/type validation**: `validate-file` and `start-import` routes exist but no `QuestionImportRequest` found; content unknown.

## 6.16 Requirements Derived from Excel
N/A

## 6.17 Requirements Derived from Code
All derived from code.

## 6.18 Final Consolidated Requirements
1. QuestionBank is a shared resource consumed by Quiz, Quest, and Exam.
2. Rich metadata (taxonomy, type, complexity, bloom, cognitive) required for quality assessment.
3. Media attachments supported in two forms: stored and linked.
4. AI generation (ChatGPT + Gemini) with save-to-bank capability.
5. CSV import/export for bulk question management.
6. Availability scoping (GLOBAL / SCHOOL / CLASS) determines cross-tenant visibility.
7. Review workflow ensures question quality before use in assessments.

## 6.19 Code Review Observations
1. **CRITICAL SECURITY**: API keys (ChatGPT, Gemini) hardcoded in controller source code. Must be moved to `.env` / config. (derived from code)
2. **Duplicate model files**: `QuestionStatistic.php` and `QuestionStatistics.php` both exist — unclear which is authoritative.
3. **Both AI providers inactive**: The `active` flags are both `false` — the AI feature is essentially unreachable by default.
4. **UUID binary incompatible with SQLite**: Tests using SQLite will fail on UUID operations.
5. **`QuestionUsageLog` policy without model**: Policy references a model that may not exist in module.
6. **No review workflow enforcement**: Questions can be used in assessments regardless of review status (no code gate on QuestionBank search endpoints).
7. **`QuestionBankController`** likely has 400+ lines of logic (7 controllers for the module, main one handling CRUD + print + import).

## 6.20 Suggestions
1. **Immediately move API keys to .env**: Use `config('questionbank.ai.chatgpt_key')` pattern.
2. Activate at least one AI provider by default, configurable per tenant.
3. Remove duplicate `QuestionStatistics.php` (keep `QuestionStatistic.php`).
-> QuestionStatistics this remove but check in both module proper how much use file then if rmov thenremove model replase

> **📋 REVIEW RESOLUTION**
> **Question:** Owner says: check usage in both modules, if safe to remove then replace all usages with singular model first, then remove the plural file.
> **Final Answer:** CONFIRMED SAFE TO REMOVE after replacing references. Code inspection shows `QuestionStatistics` is only used in `QuestionBankController.php` within the QuestionBank module. No other module uses it. Replace `QuestionStatistics` with `QuestionStatistic` in `QuestionBankController.php`, then delete `QuestionStatistics.php`.
> **Basis:** Derived from code (grep results across all modules)
> **Recommendation:** Task card: "Remove QuestionStatistics.php — replace usage in QuestionBankController.php — trigger: owner go-ahead." 

4. Add `exists` gate on question search: only return APPROVED questions to quiz/quest/exam builders.
5. Add `QuestionUsageLog` model file.
6. Consider switching UUID to char(36) for cross-DB compatibility.
7. Add comprehensive import validation with file size, MIME type, and column structure checks.

---

# EXECUTIVE SUMMARY

## Modules Inspected
| Module | Controllers | Models | Routes | Policies | Status |
|---|---|---|---|---|---|
| Syllabus | 15 | 22 | ~40 routes | 1 (misnamed) | ~100% |
| LmsQuiz | 5 | 6 | ~25 routes | 1 (QuizPolicy) | ~90% |
| LmsQuests | 4 | 4 | ~25 routes | 3 (Quest, Allocation, Question) | ~85% |
| LmsExam | 11 | 11 | ~50 routes | 9 policies | ~90% |
| LmsHomework | 5 | 5 | ~20 routes | 0 (gap!) | ~80% |
| QuestionBank | 7 | 16 | ~30 routes | 7 policies | ~85% |

## Key Findings
1. **Security gap**: No HomeworkPolicy or LessonPolicy found. Any authenticated user can access these endpoints.
2. **Critical security vulnerability**: AI API keys hardcoded in QuestionBank controller.
3. **Route typo**: `/lms-quize/` (Quiz) — "quize" instead of "quiz" affects all URLs.
4. **Route duplication**: Quest question routes registered twice in tenant.php.
5. **Broken model relationship**: Both `Lesson.php` and `Homework.php` reference `SchAcademicSession` (undefined class); correct class is `OrganizationAcademicSession`.
6. **Missing exists validation**: `academic_session_id` not validated with `exists` in Quiz, Quest, and Exam requests.
7. **Dual Dropdown models**: Homework uses `Prime\Dropdown`; HomeworkSubmission uses `GlobalMaster\Dropdown`.
8. **UUID binary incompatible**: QuestionBank UUID as binary breaks SQLite tests.
9. **Duplicate model**: `QuestionStatistic` and `QuestionStatistics` both exist.
10. **QuestRequest weaker than QuizRequest**: Academic hierarchy fields are nullable/string in Quest vs required/exists in Quiz.

---

# COMMON PATTERNS ACROSS MODULES

1. **Soft Delete + Restore + Force Delete**: All entities in all modules follow this pattern uniformly.
2. **Toggle Status**: All entities have a `POST /{resource}/{id}/toggle-status` route.
3. **Trash View**: All entities have a `GET /{resource}/trash/view` route.
4. **AJAX Cascading Dropdowns**: Sections → SubjectGroups → Subjects → Lessons → Topics pattern appears in Quiz, Quest, Exam, AI Generator.
5. **Bulk Store/Destroy**: Question assignment to quizzes, quests, and exam paper sets all use bulk-store/bulk-destroy.
6. **Update Ordinal + Update Marks**: Consistent pattern for reordering questions and overriding marks in Quiz, Quest, Exam.
7. **Auto Code Generation**: Quiz, Quest, Exam all auto-generate codes from academic hierarchy + random suffix.
8. **Status ENUM**: DRAFT / PUBLISHED / ARCHIVED pattern across Quiz, Quest; DRAFT / PUBLISHED / CONCLUDED / ARCHIVED for Exam.
9. **Academic Hierarchy FK**: All modules link to `academic_session_id`, `class_id`, `subject_id`.
10. **Policy naming convention**: `tenant.{resource}.{action}` pattern throughout.
11. **Middleware**: All routes use `['auth', 'verified']` minimum.

---

# COMMON BUSINESS RULES

1. An entity can be soft-deleted and restored independently of its `is_active` state.
2. `is_active = false` + `deleted_at = null` = deactivated but accessible to admin.
3. `deleted_at != null` = soft-deleted, accessible only via trash view.
4. Academic session is the top-level scope for all teaching artifacts.
5. Questions are consumed from QuestionBank into specific quiz/quest/exam paper sets with ordinal and mark overrides.
6. Availability flags control cross-module and cross-tenant access for questions.
7. All allocations support multiple target types (CLASS/SECTION/GROUP/STUDENT).

---

# OVERALL SUGGESTIONS

## Priority 1 (Critical / Security)
1. Move all AI API keys from `AIQuestionGeneratorController.php` to `.env`.
2. Create `HomeworkPolicy`, `LessonPolicy`, `TopicPolicy`.
3. Fix `Lesson.php` and `Homework.php` `academicSession()` relationship (broken class reference).
4. Add `exists` validation for `academic_session_id` in Quiz, Quest, and Exam requests.

## Priority 2 (Data Integrity)
5. Fix route typo `lms-quize` → `lms-quiz`.
6. Remove duplicate quest question route group in `tenant.php`.
7. Make `academic_session_id`, `class_id`, `subject_id`, `lesson_id` required (not nullable) in QuestRequest.
8. Add publish guard in Quiz: cannot PUBLISH if question count ≠ total_questions (implement `canPublish()` like Quest).
9. Add (exam_id + class_id + subject_id) unique constraint to ExamPaper.
10. Fix null safety in `Exam.generateExamCode()` (`$session?->code`).

## Priority 3 (Consistency and Quality)
11. Standardize Dropdown model usage (choose one: Prime or GlobalMaster).
-> dropdwon releted not change directory i will tell you then other vise not

> **📋 REVIEW RESOLUTION**
> **Question:** Owner says: do NOT change Dropdown-related code without explicit instruction. Will provide direction separately.
> **Final Answer:** BLOCKED — No Dropdown model changes will be made. Owner will decide which model is canonical and provide explicit instructions.
> **Basis:** Developer instruction
> **Impact:** The inconsistency (Prime\Dropdown vs GlobalMaster\Dropdown within LmsHomework) remains until owner decides.
> **Recommendation:** Task card: "Standardize Dropdown model in LmsHomework — trigger: ONLY when owner gives explicit direction." 

12. Remove duplicate `QuestionStatistics.php`. but already use this model then this file use is other one same use and replase this remove model 
13. Fix `SyllabusSchedulePolicy.php` naming mismatch.
14. Standardize duration_minutes max (300 in Quest vs 600 in Quiz).
15. Add `QuestionUsageLog` model to QuestionBank.
16. Switch QuestionBank UUID from binary to CHAR(36) for test compatibility.

## Priority 4 (UX and Feature Completeness)
17. Add lifecycle enforcement on Quiz/Exam: restrict edits when PUBLISHED.
18. Implement state machine for exam status transitions.
19. Document and implement business logic for Quest `pending` flag.
20. Enable at least one AI provider by default (configurable per tenant).

---

# ADDENDUM: DIFFICULTY LEVEL ENGINE — ROUND 2 ANALYSIS
**Updated:** 2026-03-19 (Round 2 code inspection)
**Source:** Deep inspection of DifficultyDistributionConfigController, QuizQuestionController, PaperSetQuestionController, ExamPaperController, ExamPaper model, Quiz model, ExamBlueprintController, and related request/view files.

---

## A1. DIFFICULTY ENGINE OVERVIEW

The Difficulty Distribution Engine is a cross-module system that controls **which types and complexity levels of questions** can be added to a Quiz or Exam Paper, and in what proportions. It is implemented in the `LmsQuiz` module and consumed by both `LmsQuiz` and `LmsExam`.

### Key Design Points (derived from code)
- The engine is **NOT enforced at the Question Bank level**. Difficulty attributes (complexity level, bloom, cognitive skill, question type specificity) are stored on each question in `qns_questions_bank`, but the engine only activates when a quiz or exam paper has a `difficulty_config_id` assigned.
- The engine is **optional and can be bypassed** per quiz or exam paper using the `ignore_difficulty_config` boolean flag.
- When `ignore_difficulty_config = true`, the system still shows difficulty analysis to the teacher as a reference panel in the UI, but does NOT block adding questions.
- When `ignore_difficulty_config = false` (strict mode), the system blocks the `bulkStore` API call with a 422 error if distribution rules are violated.
- Difficulty validation happens only at **question-add time** (bulkStore), NOT at quiz/exam publish time. This means a quiz can be published with a violated distribution after the fact.

---

## A2. DIFFICULTY DISTRIBUTION CONFIG — MASTER ENTITY

**Table:** `lms_difficulty_distribution_configs`
**Model:** `Modules/LmsQuiz/app/Models/DifficultyDistributionConfig.php`
**Controller:** `Modules/LmsQuiz/app/Http/Controllers/DifficultyDistributionConfigController.php`
**Routes:** Registered under `lms-quiz` prefix group in `routes/tenant.php`

### Fields (derived from code — model fillable + request validation)
| Field | Type | Rules | Purpose |
|---|---|---|---|
| `code` | string, max:50 | required, globally unique | Machine identifier for this config |
| `name` | string, max:100 | required | Human-readable label |
| `description` | string, max:255 | nullable | Optional explanation |
| `usage_type_id` | FK → `qns_question_usage_type` | required | Links config to a question usage type (quiz, exam, assessment) |
| `is_active` | boolean | optional, default true | Soft toggle |
| `deleted_at` | datetime | SoftDeletes | Standard soft delete |

### Relationships (derived from code)
- `usageType()` → BelongsTo `QuestionUsageType` (from QuestionBank module)
- `distributionDetails()` → HasMany `DifficultyDistributionDetail`
- `quizzes()` → HasMany `Quiz` (via `difficulty_config_id`)

### CRUD Lifecycle (derived from code)
- **Create:** Atomic DB transaction — creates parent config + all rule rows in one commit
- **Update:** Full replacement pattern — `distributionDetails()->forceDelete()` then re-create all rows. This means update history of individual rules is lost.
- **Delete (soft):** Sets `is_active = false` and soft deletes the config. Does NOT cascade soft delete to `DifficultyDistributionDetail` rows.
- **Force Delete:** Blocked if any `Quiz` record references this config (`difficulty_config_id`). Does cascade `forceDelete` to all `DifficultyDistributionDetail` rows.
- **Restore:** Sets `is_active = true` and restores the config record.

### Permissions (derived from code — Gate::authorize calls)
| Permission | Action |
|---|---|
| `tenant.difficulty-config.viewAny` | index() |
| `tenant.difficulty-config.view` | show() |
| `tenant.difficulty-config.create` | store() |
| `tenant.difficulty-config.update` | edit(), update(), toggleStatus() |
| `tenant.difficulty-config.delete` | destroy() |
| `tenant.difficulty-config.restore` | trashed(), restore() |
| `tenant.difficulty-config.forceDelete` | forceDelete() |

---

## A3. DIFFICULTY DISTRIBUTION DETAIL — RULE ROWS

**Table:** `lms_difficulty_distribution_details`
**Model:** `Modules/LmsQuiz/app/Models/DifficultyDistributionDetail.php`

### Fields (derived from code — model fillable)
| Field | Type | Nullable | Purpose |
|---|---|---|---|
| `difficulty_config_id` | FK | No | Parent config |
| `question_type_id` | FK → `slb_question_types` | No | Required: which question type this rule applies to |
| `complexity_level_id` | FK → `slb_complexity_level` | No | Required: which complexity level (Easy/Medium/Hard) |
| `bloom_id` | FK → `slb_bloom_taxonomy` | Yes | Optional: restrict by Bloom's taxonomy level |
| `cognitive_skill_id` | FK → `slb_cognitive_skill` | Yes | Optional: restrict by cognitive skill |
| `ques_type_specificity_id` | FK → `slb_ques_type_specificity` | Yes | Optional: restrict by question type specificity |
| `min_percentage` | decimal:2 | No | Minimum % of total questions this type/complexity must represent |
| `max_percentage` | decimal:2 | No | Maximum % of total questions this type/complexity can represent |
| `marks_per_question` | decimal:2 | Yes | If set, overrides question's own marks when added to quiz/exam |
| `is_active` | boolean | No | Row-level toggle |

### Cross-field Validation (derived from code — DifficultyDistributionConfigRequest)
- `max_percentage` must be >= `min_percentage` (enforced via `withValidator` after-hook)
- Both min and max must be between 0 and 100
- `marks_per_question` is nullable (if null, question's original marks are used)

---

## A4. DIFFICULTY LOGIC IN LMSQUIZ — QUIZ QUESTION BUILDER

**Controller:** `Modules/LmsQuiz/app/Http/Controllers/QuizQuestionController.php`
**Routes:** `/difficulty-builder/questions`, `/difficulty-builder/add`, `/difficulty-builder/quiz-meta`

### Question Search (search endpoint — derived from code)
When a teacher searches for questions to add to a quiz:
1. Filters apply: class_id, section_id, subject_id, topic_id, question_type_id, complexity_level_id, bloom_id, cognitive_skill_id, ques_type_specificity_id
2. Usage filters: `only_unused` excludes questions already in `qns_question_usage_log` with `question_usage_type = QUIZ`; `only_authorised` enforces `for_quiz = 1`
3. If quiz has `scope_topic_id`, questions outside that topic are excluded
4. Questions already in the quiz are excluded
5. Up to 50 questions returned (configurable via `quantity` param)
6. Response includes complexity, bloom, cognitive skill, type specificity labels

### Difficulty Rule Fetch (existing endpoint — derived from code)
When the question builder loads existing questions for a quiz, it also fetches:
- All `DifficultyDistributionDetail` rows for the quiz's `difficulty_config_id`
- Returns: question_type, complexity, bloom, cognitive_skill, type_specificity, min_percent, max_percent, marks_per_question
- Also returns `ignore_difficulty_config` flag in stats
- Frontend renders this as a "Difficulty Distribution Analysis" panel (advisory)

### Difficulty Validation at Add-Time (bulkStore — derived from code)
Sequential checks when teacher clicks "Add Questions":
1. **Unused check:** If `only_unused_questions = true`, blocks any question already in `qns_question_usage_log` for QUIZ context
2. **Authorised check:** If `only_authorised_questions = true`, blocks any question where `for_quiz = 0`
3. **Topic scope check:** If `scope_topic_id` is set, blocks any question outside that topic
4. **Difficulty distribution check** (most complex — step 4):
   - Only runs if quiz has `difficulty_config_id`
   - Calls `validateDifficultyDistribution($quiz, $newQuestions, $configId)`
   - If check fails AND `ignore_difficulty_config = false` → returns 422 JSON error, blocks add
   - If check fails AND `ignore_difficulty_config = true` → allows add but stores warning in response
5. **Total questions limit check:** If `total_questions > 0`, blocks if adding would exceed limit

### validateDifficultyDistribution() Algorithm (derived from code)
```
Input: quiz, newQuestions[], configId
1. Load all active DifficultyDistributionDetail rules for configId
2. If no rules → return success (nothing to validate against)
3. Load existing quiz questions
4. Compute currentTotalCount = existing.count + new.count
5. If currentTotalCount > quiz.total_questions → fail (limit exceeded)
6. Calculate calculationBase = max(quiz.total_questions, currentTotalCount)

TWO PATHS based on whether any rule has optional fields (bloom, cognitive, specificity):

PATH A — Simple rules (type + complexity only, no optional fields):
  For each group of new questions (grouped by question_type_id + complexity_level_id):
    - Find matching rule by type+complexity
    - If no matching rule → fail (no rule defined for this combo)
    - Compute maxAllowed = ceil(calculationBase × rule.max_percentage / 100)
    - Count existing questions with same type+complexity
    - If (existing + new) > maxAllowed → fail

PATH B — Complex rules (any rule has bloom/cognitive/specificity):
  For each existing question → find matching rule → track count per rule ID
  For each new question → find matching rule via findDifficultyRuleMatch():
    - Matches on: type_id AND complexity_id AND (bloom is null OR matches) AND (cognitive is null OR matches) AND (specificity is null OR matches)
    - If no matching rule → fail
  For each rule group of new questions:
    - maxAllowed = ceil(calculationBase × rule.max_percentage / 100)
    - If (existingCount + newCount) > maxAllowed → fail
```

### Marks Override Logic (derived from code)
When a question is added and a matching difficulty rule has `marks_per_question` set:
- The matching rule is found using exact match: type_id + complexity_id + (optional fields if set)
- If matched AND `marks_per_question != null` → that value overrides the question's original marks
- The override is stored in `QuizQuestion.marks_override`
- If no match or marks_per_question is null → original marks used, `marks_override` stays null

### Question Usage Logging (derived from code)
On every successful bulkStore:
- A row is created in `qns_question_usage_log` with `question_usage_type = 'QUIZ'` and `context_id = quiz_id`
- On bulkDestroy, these usage log rows are `forceDelete()`-ed (not soft deleted)

---

## A5. DIFFICULTY LOGIC IN LMSEXAM — EXAM PAPER

**Model:** `Modules/LmsExam/app/Models/ExamPaper.php`
**Controller:** `Modules/LmsExam/app/Http/Controllers/ExamPaperController.php`

### Exam Paper Difficulty Fields (derived from code — ExamPaper fillable + ExamPaperRequest)
| Field | Type | Rule | Purpose |
|---|---|---|---|
| `difficulty_config_id` | FK → `lms_difficulty_distribution_configs` | nullable | Links exam paper to a DifficultyDistributionConfig |
| `ignore_difficulty_config` | boolean | boolean | If true, distribution shown as advisory only |
| `only_unused_questions` | boolean | boolean | Forces exclusion of previously-used questions |
| `only_authorised_questions` | boolean | boolean | Forces `for_exam = 1` filter on questions |

Note: `DifficultyDistributionConfig` model is imported from `Modules\LmsQuiz\Models\DifficultyDistributionConfig` — the config is **shared** from LmsQuiz module, not duplicated.

### Paper Set Question Builder — Difficulty Logic (derived from code — PaperSetQuestionController)
Mirrors the Quiz question builder:
- `search()` endpoint: same filters (class, subject, topic, type, complexity, bloom, cognitive, specificity, unused, authorised)
- `existing()` endpoint: returns difficulty_rules for the exam paper's `difficulty_config_id`
- `bulkStore()`: applies the same 5-step validation chain as Quiz (unused → authorised → difficulty → quantity limit)

Key difference from Quiz: exam paper's `ignore_difficulty_config` flag is read from `$paperSet->examPaper->ignore_difficulty_config`, not directly from the request.

---

## A6. EXAM BLUEPRINT — SECTION-LEVEL PAPER STRUCTURE

**Model:** `Modules/LmsExam/app/Models/ExamBlueprint.php`
**Controller:** `Modules/LmsExam/app/Http/Controllers/ExamBlueprintController.php`
**Table:** `lms_exam_blueprints`

### Purpose (derived from code)
ExamBlueprint is a **section-level structure definition** for an exam paper. It defines paper sections (e.g., Section A, Section B) with a question type, instruction text, total_questions, marks_per_question, and total_marks. It is separate from the DifficultyDistributionConfig — Blueprint is structural, Config is distributional.

### Fields (derived from code — model fillable)
| Field | Type | Rule | Purpose |
|---|---|---|---|
| `exam_paper_id` | FK | required, exists:lms_exam_papers | Parent paper |
| `section_name` | string, max:50 | required | E.g., "Section A — MCQ" |
| `question_type_id` | FK → `slb_question_types` | nullable | Question type for this section |
| `instruction_text` | string | nullable | Section-level instructions |
| `total_questions` | integer, min:0 | required | Target question count for section |
| `marks_per_question` | decimal:2, min:0 | nullable | Default marks per question in this section |
| `total_marks` | decimal:2, min:0 | required | Total marks for this section |
| `ordinal` | integer, min:1 | required | Display ordering |

### CRITICAL GAP (derived from code)
**All `Gate::authorize()` calls in ExamBlueprintController are commented out.** Every action — create, update, delete, restore, forceDelete — runs without any authorization check. Any authenticated tenant user can manipulate exam blueprints.

### Integration Gap (needs confirmation)
The ExamBlueprint defines target counts per question type, but there is **no code found that cross-validates BlueprintSection against PaperSetQuestion**. A teacher could define Section A = 10 MCQs but add only 5 MCQs with no error. The blueprint is a planning tool only — no enforcement.

---

## A7. EXAM SCOPE — TOPIC/LESSON LIMITS PER QUESTION TYPE

**Model:** `Modules/LmsExam/app/Models/ExamScope.php`
**Table:** `lms_exam_scopes`

### Purpose (derived from code)
ExamScope limits how many questions of a given type can come from a specific lesson or topic. It is separate from DifficultyDistributionConfig — scope is curriculum-bounded, config is difficulty-bounded.

### Integration with PaperSetQuestion Builder (derived from code)
The `existing()` endpoint returns `exam_scopes` alongside `difficulty_rules`. The frontend displays both panels. The scope shows `target_count` vs `added_count` per scope row. This is advisory — no server-side blocking found for scope violations in `bulkStore()`.

---

## A8. DIFFICULTY IN LMSHOMEWORK

**Request:** `Modules/LmsHomework/app/Http/Requests/HomeworkRequest.php`
**Table:** `lms_homework`
**Views:** `home-work/create.blade.php`, `home-work/edit.blade.php`, `home-work/show.blade.php`

### Homework Difficulty (derived from code)
Homework uses a **simple difficulty level reference** — a single `difficulty_level_id` FK pointing to `slb_complexity_level` (the Complexity Level master from Syllabus module). This is purely informational/labeling — there is no distribution config, no percentage rules, no marks override logic.

| Field | Type | Rule | Purpose |
|---|---|---|---|
| `difficulty_level_id` | FK → `slb_complexity_level` | nullable, exists:slb_complexity_level | Optional label for the homework difficulty |

The UI shows a dropdown "Select Difficulty Level (Optional)" with all active complexity levels from the Syllabus module.

---

## A9. DIFFICULTY GAPS AND MISSING FEATURES

| # | Gap | Module | Severity | Source |
|---|---|---|---|---|
| D1 | Difficulty validation runs at add-time only, NOT at quiz publish-time | LmsQuiz, LmsExam | HIGH | derived from code |
-> answer ->  give me full exmple details why and if i  need then i will tell you but etxisng code functionlity not change direct first aks me then i will give permmison then

> **📋 REVIEW RESOLUTION**
> **Question:** D1 — Owner asks for full example details of why this is a gap. Owner also says: do NOT change existing code without asking permission first.
> **Final Answer:** EXPLAINED (no code change). Here is the full example:
> **Full Example of D1 Gap:**
> 1. Teacher creates a Quiz with `difficulty_config_id = 5` (config says: max 30% Hard questions). `ignore_difficulty_config = false`.
> 2. Teacher adds 7 Easy, 3 Medium questions via bulkStore. Validation passes (max 30% Hard = 0 Hard added, all good).
> 3. Teacher then removes 4 Easy questions via bulkDestroy. Now the quiz has 3 Easy + 3 Medium = 6 questions. NO validation runs on bulkDestroy.
> 4. Teacher adds 4 Hard questions via bulkStore. Validation runs: `(0 existing Hard + 4 new Hard) / max(10, 10) = 40% > 30%` → BLOCKED. Good.
> 5. BUT: Teacher deletes 4 of the 6 remaining questions, then uses `ignore_difficulty_config = true` to add 8 Hard questions. Gets a warning but NOT blocked.
> 6. Teacher then turns `ignore_difficulty_config` back to `false` (by editing the quiz). The quiz now has Hard > 30% limit but no validation re-runs.
> 7. Teacher publishes the quiz. No difficulty re-check on publish.
> **Result:** A quiz marked as "difficulty-controlled" is published with 80% Hard questions, violating the configured maximum of 30%.
> **Existing code not changed.** If owner wants this fixed, the fix would be: add a difficulty check inside Quiz publish() or canPublish() — this would be additive code only.
> **Basis:** Derived from code (QuizQuestionController.bulkStore + Quiz lifecycle)
> **Recommendation:** Task card: "Add difficulty distribution check at publish-time for Quiz and ExamPaper — additive code only, no existing code changed — trigger: owner explicit approval." 

| D2 | Exam Blueprint gate checks all commented out — no authorization | LmsExam | CRITICAL | derived from code |
| D3 | No cross-validation between ExamBlueprint section counts and actual PaperSetQuestion counts | LmsExam | MEDIUM | derived from code |
| D4 | ExamScope target count shown in UI but not enforced server-side in bulkStore | LmsExam | MEDIUM | derived from code |

| D5 | DifficultyDistributionDetail rows are hard-deleted on config update (no audit trail) | LmsQuiz | MEDIUM | derived from code |
-> answer -> not delete dirctory i will tell you and if need then exmpale why and other implmnetion effact not this type

> **📋 REVIEW RESOLUTION**
> **Question:** D5 — Owner says: do NOT change this behavior. Will instruct if needed. Provide example of why this is a concern and what other implementations it would affect.
> **Final Answer:** ACCEPTED — No change to current forceDelete behavior. Explanation provided below for future reference.
> **Why This Is Flagged (Example):**
> - Config "Balanced Mix" has rules: Easy 30%, Medium 50%, Hard 20%.
> - Teacher builds Quiz A with 30 Easy, 50 Medium, 20 Hard questions using this config.
> - Admin updates Config to: Easy 10%, Hard 90%.
> - All old detail rows (30%, 50%, 20%) are permanently deleted and replaced with (10%, 90%).
> - Quiz A now looks like it was built with "Easy 10%, Hard 90%" rules — but it was actually built with the original balanced config.
> - There is no record of what the config looked like when Quiz A was constructed.
> **Other Implementation Options If Needed in Future:**
> (a) Log old rules to `lms_activity_log` before deleting — lightweight audit trail.
> (b) Version the config — increment a `version` field and create new detail rows with the new version, keeping old rows with old version.
> (c) Add a `config_snapshot_json` column on `lms_quizzes` storing the rules at assignment time.
> **Current behavior preserved.** If owner decides to change, provide this analysis to choose the right approach.
> **Basis:** Developer instruction
> **Recommendation:** Document this design decision. Change only if owner explicitly approves an approach from the options above. 

| D6 | Soft-deleting a DifficultyDistributionConfig does NOT soft-delete its detail rows | LmsQuiz | LOW | derived from code |
-> tell me explain this proper details

> **📋 REVIEW RESOLUTION**
> **Question:** D6 — Owner asks for proper detailed explanation of this issue.
> **Final Answer:** EXPLAINED. When you soft-delete a DifficultyDistributionConfig, its child DifficultyDistributionDetail rows are NOT soft-deleted — they stay in the database as active rows.
> **Detailed Explanation:**
> The `DifficultyDistributionConfig` table has `deleted_at` column (SoftDeletes). When you call `$config->delete()`, only the config record's `deleted_at` is set. The related `lms_difficulty_distribution_details` rows have NO `deleted_at` set — they remain as-is.
>
> **What does this mean practically?**
> - The config is hidden from normal UI queries (because `deleted_at IS NOT NULL` filters it out).
> - But if someone queries `DifficultyDistributionDetail::where('difficulty_config_id', $id)->get()`, they still get all the rule rows — even though the parent config is deleted.
> - On restore (`$config->restore()`), the config comes back and its detail rows are still there unchanged. This is actually fine for restore scenarios.
> - The only scenario where this causes visible issues: if code queries details via `withTrashed()` and then tries to show or apply rules for "deleted" configs, it might incorrectly apply those rules.
>
> **Is this currently causing a problem?** Based on code inspection: NO. The UI filters show only active configs (is_active = 1), and soft-deleted configs are hidden. Detail rows for soft-deleted configs are never fetched in normal operation. This is a theoretical inconsistency, not a practical bug.
>
> **LOW severity** — no action needed unless a specific use case is identified where this causes incorrect behavior.
> **Basis:** Derived from code (DifficultyDistributionConfigController.destroy())
> **Recommendation:** No change needed. Document as known design behavior. 

| D7 | No minimum percentage validation at add-time (only max checked in validateDifficultyDistribution) | LmsQuiz, LmsExam | MEDIUM | derived from code |
| D8 | min_percentage stored and shown in UI but not checked when blocking question add | LmsQuiz | MEDIUM | derived from code |
| D9 | No difficulty validation found in LmsQuests — QuestQuestion builder not inspected | LmsQuests | needs confirmation | inferred from code structure |
| D10 | DifficultyDistributionConfig is defined in LmsQuiz but consumed by LmsExam — cross-module dependency not documented | LmsExam→LmsQuiz | LOW | derived from code |
