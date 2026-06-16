# REC — Recommendation Engine
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## 1. Executive Summary

The Recommendation module is Prime-AI's personalized learning guidance engine. It connects student performance data from LMS modules (Quiz, Exam, Homework) to a curated content library through a configurable rules engine, automatically surfacing the right learning material to the right student at the right time.

**Current State (v1 audit):** ~39% complete. The CRUD scaffolding for all 10 database entities is largely built (controllers, views, models, policies). However, the core value of the module — automated recommendation generation — has zero implementation. There are also 4 critical security vulnerabilities that must be fixed before any deployment.

**V2 Target:** Fix all critical security issues, complete the rule engine service layer, add FormRequests, establish LMS event integration, and deliver an analytics dashboard for counselors and teachers.

| Metric | Current | V2 Target |
|---|---|---|
| DB Tables | 10 (no new needed) | 10 (+ 1 proposed) |
| Controllers | 10 (3 stubs) | 10 (all complete) |
| Services | 0 | 4 |
| FormRequests | 0 | 10 |
| Policies | 8 (1 missing) | 9 |
| Tests | 0 | 20+ |
| Completion | ~39% | ~90% |

---

## 2. Module Overview

### 2.1 Purpose

The Recommendation Engine formalizes learning gap remediation in Indian K-12 schools. Rather than ad-hoc WhatsApp suggestions, it provides:

- A **curated content library** (materials: videos, PDFs, quizzes, links; bundles of materials)
- A **rule engine** (IF student scores below X% on topic Y THEN recommend material Z)
- An **automated dispatch pipeline** (exam result submitted → engine fires → student sees recommendation)
- A **student lifecycle tracker** (PENDING → VIEWED → IN_PROGRESS → COMPLETED/SKIPPED/EXPIRED)
- A **feedback loop** (star ratings, completion scores, material effectiveness analytics)

### 2.2 Operating Modes

| Mode | Description |
|---|---|
| Automated | System fires recommendations based on trigger events (e.g., exam result saved) |
| Manual | Teacher browses content library and assigns material to a specific student |
| Scheduled | Batch job runs weekly to generate recommendations based on cumulative performance |

### 2.3 Key Concepts

- **Trigger Event** — The condition that activates rule evaluation (ON_ASSESSMENT_RESULT, ON_TOPIC_COMPLETION, ON_ATTENDANCE_LOW, MANUAL_RUN, SCHEDULED_WEEKLY)
- **Recommendation Mode** — How content is resolved: SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY
- **Rule** — IF-THEN logic: WHEN [trigger] + IF [conditions: class/subject/topic/score range/performance category] THEN [recommend content]
- **Student Recommendation** — The dispatched record linking student to content, with full lifecycle tracking
- **Material** — A single content item (video URL, PDF file, quiz link, HTML notes, etc.)
- **Bundle** — An ordered collection of materials packaged as a learning kit

---

## 3. Stakeholders & Roles

| Role | Responsibilities in This Module |
|---|---|
| **School Admin** | Configure trigger events, recommendation modes, material types, purposes, assessment types |
| **Subject Teacher** | Create/manage materials and bundles; define recommendation rules; manually assign recommendations to students |
| **Counselor / Academic Coordinator** | Monitor recommendation analytics dashboard; track at-risk student completion rates |
| **Student** | View assigned recommendations; mark as in-progress/completed; submit star rating and feedback |
| **Parent** | (Future scope) Read-only view of child's recommendations on Parent Portal |
| **System (Scheduled Job)** | Batch-expire overdue recommendations; run scheduled recommendation generation |

---

## 4. Functional Requirements

### 4.1 Configuration Masters (Tab 1)

**FR-REC-01 — Trigger Events CRUD** ✅
- Full lifecycle: create, view, edit, delete (soft), restore, force-delete, toggle is_active
- Unique constraint on `event_name`
- Seeded values: ON_ASSESSMENT_RESULT, ON_TOPIC_COMPLETION, ON_ATTENDANCE_LOW, MANUAL_RUN, SCHEDULED_WEEKLY
- Controller: `RecTriggerEventController` | Policy: `TriggerEventPolicy`

**FR-REC-02 — Recommendation Modes CRUD** ✅
- Manage delivery modes: SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY
- Full lifecycle with soft deletes
- Controller: `RecommendationModeController` | Policy: `RecommendationModePolicy`
- **Bug:** `trashed()` method uses `recommendation.recommendation_modes.restore` (wrong pattern); must be standardized to `tenant.recommendation-mode.restore`

**FR-REC-03 — Dynamic Material Types CRUD** ✅
- Lookup values for dynamic mode: ANY_BEST_FIT, VIDEO, QUIZ, PDF
- Controller: `DynamicMaterialTypeController` | Policy: `DynamicMaterialTypePolicy`

**FR-REC-04 — Dynamic Purposes CRUD** ✅
- Lookup values for dynamic mode: REMEDIAL, ENRICHMENT, PRACTICE
- Controller: `DynamicPurposeController` | Policy: `DynamicPurposePolicy`

**FR-REC-05 — Assessment Types CRUD** 🟡
- Lookup values: ALL, QUIZ, WEEKLY_TEST, TERM_EXAM, FINAL_EXAM
- Controller: `RecAssessmentTypeController` — **CRITICAL GAP:** No routes registered for this controller; views exist but are unreachable
- Policy: `RecAssessmentTypePolicy` — **CRITICAL GAP:** Policy file does not exist; import is commented out in `AppServiceProvider.php`
- **V2 Action:** Register routes in `tenant.php`; create `RecAssessmentTypePolicy`; add to AppServiceProvider

### 4.2 Content Library Management (Tab 2)

**FR-REC-06 — Recommendation Materials CRUD** 🟡
- Create/edit/delete individual content items with full metadata
- Fields: title, description, material_type (FK sys_dropdown), purpose (FK sys_dropdown), complexity_level (FK slb_complexity_level), content_source (FK sys_dropdown), content_text (HTML), file_url, external_url, media_id (FK qns_media_store), subject_id, class_id, topic_id, competency_code, duration_seconds, language_code, tags (JSON), is_active
- Tag-based search and filter by class/subject/topic
- Soft deletes + trash/restore/force-delete
- **Critical Bugs:**
  - `create()`, `edit()`, `store()`, `update()` have NO `Gate::authorize()` call — completely unprotected
  - Validation uses `Validator::make($request->all())` — risk of mass assignment; must be replaced with FormRequest
  - `slb_complexity_level` (singular) in `update()` vs `slb_complexity_levels` (plural) in `store()` — table name mismatch
  - Permission naming uses `recommendation.recommendation_materials.*` instead of standard `tenant.recommendation-material.*`
- Controller: `RecommendationMaterialController` | Policy: `RecommendationMaterialPolicy`

**FR-REC-07 — Material Bundles CRUD** ✅
- Create bundles grouping ordered materials into a learning kit
- Bundle-material junction managed via `rec_bundle_materials_jnt` with `sequence_order` and `is_mandatory`
- `DB::transaction` wraps bundle + junction sync on store/update
- Soft deletes + trash/restore/force-delete
- **DDL Gap:** `rec_material_bundles` has no `school_id` column; model and controller reference `school_id` — migration needed or model must remove the reference
- Controller: `MaterialBundleController` | Policy: `MaterialBundlePolicy`

**FR-REC-08 — Recommendation Rules CRUD** ✅
- Define IF-THEN rules: trigger event + scope conditions (class/subject/topic) + performance criteria (score range, performance_category) + assessment type filter + action (recommendation mode + target content)
- `priority` field determines rule precedence when multiple rules match
- `is_automated` flag: 1 = system fires it; 0 = manual helper rule
- Soft deletes + trash/restore/force-delete + toggle is_active
- Controller: `RecommendationRuleController` | Policy: `RecommendationRulePolicy`

### 4.3 Student Recommendation Management

**FR-REC-09 — Manual Student Recommendations CRUD** 🟡
- Teacher manually assigns a material or bundle to a specific student
- Fields: student_id, rule_id (nullable), material_id or bundle_id (at least one required), recommendation_reason, priority (LOW/MEDIUM/HIGH/CRITICAL), due_date, status, manual_assigned_by
- UUID auto-generated on create via model boot
- Soft deletes + trash/restore/force-delete
- **Critical Bugs:**
  - `show()`, `edit()`, `update()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()`, `markAsCompleted()`, `updateStatus()`, `addRating()` — ALL use `.create` permission instead of correct `.view`, `.update`, `.delete`, `.restore`, `.forceDelete` permissions
  - `update()` validates `student_id` against `users` table but `store()` uses `sys_users` — mismatch causes validation failures
  - `manual_assigned_by` validated against `users` instead of `sys_users` in update()
- Controller: `StudentRecommendationController` | Policy: `StudentRecommendationPolicy`

**FR-REC-10 — Student Recommendation Lifecycle** 🟡
- Status transitions managed via model methods; controller `updateStatus()` dispatches to correct method
- Status flow: PENDING → VIEWED → IN_PROGRESS → COMPLETED (or SKIPPED / EXPIRED)
- `markAsViewed()`: sets `first_viewed_at` on first call; updates status to VIEWED only if currently PENDING
- `markAsCompleted($score)`: sets `completed_at`; optionally records `score_achieved`
- `is_overdue` accessor: true when `due_date < now()` AND status in [PENDING, IN_PROGRESS]
- `days_remaining` accessor: positive = days left; negative = days overdue
- `updateStatus()` returns JSON response (used via AJAX in UI)
- **Gap:** No guard against invalid status transitions (e.g., COMPLETED → PENDING)

**FR-REC-11 — Student Rating & Feedback** 🟡
- Student submits 1–5 star rating with optional text after completing (or at any time)
- `addRating($rating, $feedback)` model method persists to `student_rating` and `student_feedback`
- Controller `addRating()` validates rating (required, 1–5) and feedback (optional, max 255)
- **Bug:** `addRating()` uses `tenant.student-recommendation.create` instead of `.update`

### 4.4 Rule Engine (Automated Recommendation Generation)

**FR-REC-12 — Rule Evaluation Service** ❌
- `RecommendationEngineService::processResult(ExamResult $result): Collection`
  - Query all active `rec_recommendation_rules` where trigger_event matches ON_ASSESSMENT_RESULT
  - Apply scope filters: class_id (NULL = any), subject_id (NULL = any), topic_id (NULL = any)
  - Apply performance filters: `min_score_pct <= score <= max_score_pct`; `performance_category_id` match
  - Apply assessment type filter: `assessment_type_id` (NULL = any type)
  - Sort by `priority` DESC; higher priority wins when multiple rules match same scope
  - Return collection of matching rules

**FR-REC-13 — Content Resolution** ❌
- `RecommendationEngineService::resolveContent(Rule $rule, Student $student): array`
  - SPECIFIC_MATERIAL: return `['material_id' => $rule->target_material_id]`
  - SPECIFIC_BUNDLE: return `['bundle_id' => $rule->target_bundle_id]`
  - DYNAMIC_BY_TOPIC: query `rec_recommendation_materials` WHERE topic_id = exam topic AND material_type matches dynamic_material_type AND purpose matches dynamic_purpose, order by relevance, return best match
  - DYNAMIC_BY_COMPETENCY: query materials by `competency_code` gap derived from performance snapshot

**FR-REC-14 — Recommendation Dispatch** ❌
- `RecommendationEngineService::dispatchRecommendation(Student $student, Rule $rule, ExamResult $result): StudentRecommendation`
  - Deduplicate: skip if a non-expired recommendation for same student + material/bundle already exists (within 30 days)
  - Create `rec_student_recommendations` record
  - Set `rule_id`, `triggered_by_result_id`, `recommendation_reason` auto-populated from context
  - Priority inherited from rule or defaulted to MEDIUM

**FR-REC-15 — Trigger Event Listener** ❌
- Register `ExamResultSubmitted` event listener in `EventServiceProvider.php`
- Listener: `HandleExamResultForRecommendations::handle(ExamResultSubmitted $event)`
- Calls `RecommendationEngineService::processResult()` and dispatches recommendations
- Must be async (queued job) to avoid blocking the exam result submission HTTP response

**FR-REC-16 — Batch Expiry Job** ❌
- `ExpireRecommendationsCommand` (Artisan command) or scheduled job
- Query: `rec_student_recommendations` WHERE `due_date < today` AND `status IN (PENDING, IN_PROGRESS)`
- Call `markAsExpired()` on each; write audit log
- Scheduled nightly via `app/Console/Kernel.php` or Laravel scheduler
- Return count of expired records

**FR-REC-17 — Scheduled Batch Recommendations** ❌ 📐
- Weekly scheduled job running ON_SCHEDULED_WEEKLY trigger
- Aggregates performance data over rolling 4-week window per student
- Generates recommendations for students with consistent low performance in any topic
- Uses same `RecommendationEngineService` pipeline

### 4.5 Analytics & Dashboard

**FR-REC-18 — Recommendation Analytics Dashboard** ❌
- Accessible by Admin, Counselor, and Teachers
- Metrics displayed:
  - Total recommendations assigned (all time / this month)
  - Completion rate (% COMPLETED vs total non-EXPIRED)
  - Average student rating (weighted mean across all rated recommendations)
  - Most recommended materials (top 10 by assignment count)
  - Rule effectiveness (rule name → trigger count → completion rate)
  - At-risk students with 0 completed recommendations in last 30 days
- Filter by: date range, class, subject, teacher
- Export to CSV

**FR-REC-19 — Tab Index UI (Main Entry Pages)** 🟡
- `tabIndex()` (Tab 1): Displays 5 lookup tables + rules summary
- `tabIndex_2()` (Tab 2): Displays materials, bundles, rules, student recommendations
- **Critical Bug:** `Gate::any([...])` on both tab index methods returns a boolean — the return value is DISCARDED. Authorization is NOT enforced. Any authenticated user can access these pages regardless of permissions.
- **Fix Required:** Replace `Gate::any([...])` (discarded) with `abort_unless(Gate::any([...]), 403)` or restructure to use individual `Gate::check()` calls per data section

### 4.6 Authorization Architecture

**FR-REC-20 — Permission Naming Standardization** ❌
- All 10 controllers use 4 different permission naming patterns (see Section 8.3)
- V2 standard: ALL permissions must follow `tenant.{resource}.{action}` where action is one of: viewAny, view, create, update, delete, restore, forceDelete
- All permissions must be seeded in `sys_permissions` table via `PermissionSeeder`
- Policies must align with the seeded permission names

**FR-REC-21 — FormRequest Classes** ❌
- Zero FormRequests currently exist; all validation is inline or uses `Validator::make($request->all())`
- 10 FormRequest classes required (see Section 8.4)
- Must use `$this->validated()` in controllers — never `$request->all()`

**FR-REC-22 — EnsureTenantHasModule Middleware** ❌
- Recommendation route group in `tenant.php` has NO `EnsureTenantHasModule` middleware
- Must add: `'middleware' => ['auth', 'verified', 'EnsureTenantHasModule:REC']` to the group

---

## 5. Data Model

### 5.1 Lookup / Master Tables

| Table | Key Column | Values | DDL Line |
|---|---|---|---|
| `rec_trigger_events` | `event_name` VARCHAR(50) UNIQUE | ON_ASSESSMENT_RESULT, ON_TOPIC_COMPLETION, ON_ATTENDANCE_LOW, MANUAL_RUN, SCHEDULED_WEEKLY | 5514 |
| `rec_recommendation_modes` | `mode_name` VARCHAR(50) UNIQUE | SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY | 5527 |
| `rec_dynamic_material_types` | `type_name` VARCHAR(50) UNIQUE | ANY_BEST_FIT, VIDEO, QUIZ, PDF | 5540 |
| `rec_dynamic_purposes` | `purpose_name` VARCHAR(50) UNIQUE | REMEDIAL, ENRICHMENT, PRACTICE | 5553 |
| `rec_assessment_types` | `type_name` VARCHAR(50) UNIQUE | ALL, QUIZ, WEEKLY_TEST, TERM_EXAM, FINAL_EXAM | 5566 |

All lookup tables share structure: `id, [name_col], description, is_active, created_at, updated_at, deleted_at`.

### 5.2 Content Tables

**`rec_recommendation_materials`** (DDL line 5579)

| Column | Type | Constraint | Notes |
|---|---|---|---|
| `id` | INT UNSIGNED | PK | |
| `title` | VARCHAR(255) | NOT NULL | |
| `description` | TEXT | nullable | |
| `material_type` | INT UNSIGNED | FK sys_dropdown_table | TEXT, VIDEO, PDF, AUDIO, QUIZ, ASSIGNMENT, LINK, INTERACTIVE |
| `purpose` | INT UNSIGNED | FK sys_dropdown_table | REVISION, PRACTICE, REMEDIAL, ADVANCED, ENRICHMENT |
| `complexity_level` | INT UNSIGNED | FK slb_complexity_level | DDL confirms singular table name |
| `content_source` | INT UNSIGNED | FK sys_dropdown_table | INTERNAL_EDITOR, UPLOADED_FILE, EXTERNAL_LINK, LMS_MODULE, QUESTION_BANK |
| `content_text` | LONGTEXT | nullable | HTML content or notes |
| `file_url` | VARCHAR(500) | nullable | Uploaded PDFs/videos |
| `external_url` | VARCHAR(500) | nullable | YouTube, Khan Academy, etc. |
| `media_id` | INT UNSIGNED | FK qns_media_store | Stored media reference |
| `subject_id` | INT UNSIGNED | FK sch_subjects | Nullable |
| `class_id` | INT UNSIGNED | FK sch_classes | Nullable |
| `topic_id` | INT UNSIGNED | FK slb_topics | Nullable |
| `competency_code` | VARCHAR(50) | nullable | |
| `duration_seconds` | INT UNSIGNED | nullable | Estimated consumption time |
| `language_code` | VARCHAR(10) | default 'en' | |
| `tags` | JSON | nullable | Search/filter tags |
| `is_active` | TINYINT(1) | NOT NULL, default 1 | |
| `created_by` | INT UNSIGNED | nullable | |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | | Soft delete support |

Indexes: `idx_recMat_type (material_type)`, `idx_recMat_scope (class_id, subject_id, topic_id)`

**`rec_material_bundles`** (DDL line 5622)

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `title` | VARCHAR(255) NOT NULL | |
| `description` | TEXT | nullable |
| `is_active` | TINYINT(1) | default 1 |
| `created_by` | INT UNSIGNED | nullable |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | |

**DDL Note:** No `school_id` column exists in DDL. Model and controller reference `school_id` — this is a gap that must be resolved (either add column via migration or remove from model/controller).

**`rec_bundle_materials_jnt`** (DDL line 5635)

| Column | Type | Notes |
|---|---|---|
| `bundle_id` | INT UNSIGNED | FK rec_material_bundles ON DELETE CASCADE |
| `material_id` | INT UNSIGNED | FK rec_recommendation_materials ON DELETE CASCADE |
| `sequence_order` | INT UNSIGNED | default 1 |
| `is_mandatory` | TINYINT(1) | default 1 |
| UNIQUE | (`bundle_id`, `material_id`) | Prevents duplicate materials in a bundle |

### 5.3 Rules Engine Table

**`rec_recommendation_rules`** (DDL line 5649)

| Column | Type | Notes |
|---|---|---|
| `name` | VARCHAR(150) NOT NULL | Descriptive label |
| `is_automated` | TINYINT(1) | default 1; 1=system fires, 0=manual |
| `trigger_event_id` | INT UNSIGNED NOT NULL | FK rec_trigger_events ON DELETE CASCADE |
| `class_id` | INT UNSIGNED | FK sch_classes ON DELETE SET NULL |
| `subject_id` | INT UNSIGNED | FK sch_subjects ON DELETE SET NULL |
| `topic_id` | INT UNSIGNED | FK slb_topics ON DELETE SET NULL |
| `performance_category_id` | INT UNSIGNED | FK slb_performance_categories ON DELETE SET NULL |
| `min_score_pct` | DECIMAL(5,2) | nullable; lower bound of score range |
| `max_score_pct` | DECIMAL(5,2) | nullable; upper bound of score range |
| `assessment_type_id` | INT UNSIGNED | FK rec_assessment_types ON DELETE SET NULL |
| `recommendation_mode_id` | INT UNSIGNED NOT NULL | FK rec_recommendation_modes ON DELETE CASCADE |
| `target_material_id` | INT UNSIGNED | FK rec_recommendation_materials ON DELETE SET NULL |
| `target_bundle_id` | INT UNSIGNED | FK rec_material_bundles ON DELETE SET NULL |
| `dynamic_material_type_id` | INT UNSIGNED | FK rec_dynamic_material_types ON DELETE SET NULL |
| `dynamic_purpose_id` | INT UNSIGNED | FK rec_dynamic_purposes ON DELETE SET NULL |
| `priority` | INT UNSIGNED | default 10; higher = evaluated first |
| `is_active` | TINYINT(1) | default 1 |

### 5.4 Student Recommendation Table

**`rec_student_recommendations`** (DDL line 5695)

| Column | Type | Notes |
|---|---|---|
| `uuid` | BINARY(16) NOT NULL | UNIQUE; auto-generated on create |
| `student_id` | INT UNSIGNED NOT NULL | FK std_students ON DELETE CASCADE |
| `rule_id` | INT UNSIGNED | FK rec_recommendation_rules ON DELETE SET NULL; NULL = manual |
| `triggered_by_result_id` | INT UNSIGNED | nullable; FK to exam result table |
| `manual_assigned_by` | INT UNSIGNED | FK sch_teachers ON DELETE SET NULL |
| `material_id` | INT UNSIGNED | FK rec_recommendation_materials ON DELETE CASCADE |
| `bundle_id` | INT UNSIGNED | FK rec_material_bundles ON DELETE CASCADE |
| `recommendation_reason` | VARCHAR(255) | nullable |
| `priority` | ENUM(LOW, MEDIUM, HIGH, CRITICAL) | default MEDIUM |
| `due_date` | DATE | nullable |
| `status` | ENUM(PENDING, VIEWED, IN_PROGRESS, COMPLETED, SKIPPED, EXPIRED) | default PENDING |
| `assigned_at` | TIMESTAMP | default CURRENT_TIMESTAMP |
| `first_viewed_at` | TIMESTAMP | nullable |
| `completed_at` | TIMESTAMP | nullable |
| `score_achieved` | DECIMAL(5,2) | nullable; if material was a quiz |
| `student_rating` | TINYINT UNSIGNED | nullable; 1–5 stars |
| `student_feedback` | VARCHAR(255) | nullable |
| `is_active` | TINYINT(1) | default 1 |

Index: `idx_recStud_student (student_id, status)` — supports student portal queries.
**DDL Note:** No `deleted_at` column in DDL; model uses SoftDeletes — migration required to add `deleted_at`.

### 5.5 Proposed New Table (V2)

**`rec_performance_snapshots`** (DDL line: does not exist yet) 📐

Required to support DYNAMIC_BY_COMPETENCY mode and scheduled recommendations.

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `student_id` | INT UNSIGNED NOT NULL | FK std_students |
| `subject_id` | INT UNSIGNED | FK sch_subjects |
| `topic_id` | INT UNSIGNED | FK slb_topics |
| `competency_code` | VARCHAR(50) | nullable |
| `avg_score_pct` | DECIMAL(5,2) | Rolling average |
| `attempt_count` | INT UNSIGNED | default 0 |
| `last_assessment_at` | TIMESTAMP | nullable |
| `snapshot_date` | DATE | The week/period this snapshot represents |
| `academic_term_id` | INT UNSIGNED | nullable; FK |
| `created_at`, `updated_at` | TIMESTAMP | |

---

## 6. API Endpoints & Routes

### 6.1 Web Routes (tenant.php)

All routes require middleware: `['auth', 'verified', 'EnsureTenantHasModule:REC']`

| Route Name | Method | URI | Controller | Status |
|---|---|---|---|---|
| `recommendation.recommendation-mgt` | GET | `/recommendation/recommendation-mgt` | `RecommendationController::tabIndex` | 🟡 Auth broken |
| `recommendation.rec-material` | GET | `/recommendation/rec-material` | `RecommendationController::tabIndex_2` | 🟡 Auth broken |
| `recommendation.recommendation-materials.*` | Resource | `/recommendation/recommendation-materials` | `RecommendationMaterialController` | 🟡 Auth gaps |
| `recommendation.material-bundles.*` | Resource | `/recommendation/material-bundles` | `MaterialBundleController` | ✅ |
| `recommendation.recommendation-rules.*` | Resource | `/recommendation/recommendation-rules` | `RecommendationRuleController` | ✅ |
| `recommendation.student-recommendations.*` | Resource | `/recommendation/student-recommendations` | `StudentRecommendationController` | 🟡 Wrong perms |
| `recommendation.trigger-events.*` | Resource | `/recommendation/trigger-events` | `RecTriggerEventController` | ✅ |
| `recommendation.recommendation-modes.*` | Resource | `/recommendation/recommendation-modes` | `RecommendationModeController` | 🟡 1 wrong perm |
| `recommendation.dynamic-material-types.*` | Resource | `/recommendation/dynamic-material-types` | `DynamicMaterialTypeController` | ✅ |
| `recommendation.dynamic-purposes.*` | Resource | `/recommendation/dynamic-purposes` | `DynamicPurposeController` | ✅ |
| `recommendation.assessment-types.*` | Resource | `/recommendation/assessment-types` | `RecAssessmentTypeController` | ❌ Routes missing |

### 6.2 Additional Non-Resource Routes Required

| Route Name | Method | URI | Controller::Method | Purpose |
|---|---|---|---|---|
| `recommendation.student-recommendations.trashed` | GET | `/recommendation/student-recommendations/trashed` | `StudentRecommendationController::trashed` | View trash |
| `recommendation.student-recommendations.restore` | PATCH | `/recommendation/student-recommendations/{id}/restore` | `StudentRecommendationController::restore` | Restore |
| `recommendation.student-recommendations.force-delete` | DELETE | `/recommendation/student-recommendations/{id}/force-delete` | `StudentRecommendationController::forceDelete` | Permanent delete |
| `recommendation.student-recommendations.mark-completed` | PATCH | `/recommendation/student-recommendations/{id}/mark-completed` | `StudentRecommendationController::markAsCompleted` | Mark done |
| `recommendation.student-recommendations.update-status` | PATCH | `/recommendation/student-recommendations/{id}/update-status` | `StudentRecommendationController::updateStatus` | AJAX status change |
| `recommendation.student-recommendations.add-rating` | POST | `/recommendation/student-recommendations/{id}/add-rating` | `StudentRecommendationController::addRating` | Submit rating |
| `recommendation.analytics` | GET | `/recommendation/analytics` | `RecommendationAnalyticsController::dashboard` | Analytics dashboard |
| `recommendation.analytics.export` | GET | `/recommendation/analytics/export` | `RecommendationAnalyticsController::export` | CSV export |

### 6.3 API Routes (api.php) — Proposed for Student Portal

| Route | Method | URI | Purpose |
|---|---|---|---|
| `api.recommendations.index` | GET | `/api/v1/recommendations` | Student portal: list my recommendations |
| `api.recommendations.show` | GET | `/api/v1/recommendations/{uuid}` | Student portal: view single recommendation |
| `api.recommendations.update-status` | PATCH | `/api/v1/recommendations/{uuid}/status` | Student portal: update status |
| `api.recommendations.rate` | POST | `/api/v1/recommendations/{uuid}/rate` | Student portal: submit rating |

---

## 7. UI Screens

| Screen ID | Screen Name | URL | Controller Method | Status |
|---|---|---|---|---|
| SCR-REC-01 | Masters Tab 1 | `/recommendation/recommendation-mgt` | `tabIndex()` | 🟡 Auth broken |
| SCR-REC-02 | Content & Rules Tab 2 | `/recommendation/rec-material` | `tabIndex_2()` | 🟡 Auth broken |
| SCR-REC-03 | Materials Index | `/recommendation/recommendation-materials` | `index()` | ✅ |
| SCR-REC-04 | Materials Create | `/recommendation/recommendation-materials/create` | `create()` | 🟡 Unprotected |
| SCR-REC-05 | Materials Edit | `/recommendation/recommendation-materials/{id}/edit` | `edit()` | 🟡 Unprotected |
| SCR-REC-06 | Materials Trash | `/recommendation/recommendation-materials/trashed` | `trashed()` | ✅ |
| SCR-REC-07 | Bundle Index | `/recommendation/material-bundles` | `index()` | ✅ |
| SCR-REC-08 | Bundle Create | `/recommendation/material-bundles/create` | `create()` | ✅ |
| SCR-REC-09 | Bundle Edit | `/recommendation/material-bundles/{id}/edit` | `edit()` | ✅ |
| SCR-REC-10 | Rules Index | `/recommendation/recommendation-rules` | `index()` | ✅ |
| SCR-REC-11 | Rules Create | `/recommendation/recommendation-rules/create` | `create()` | ✅ |
| SCR-REC-12 | Rules Edit | `/recommendation/recommendation-rules/{id}/edit` | `edit()` | ✅ |
| SCR-REC-13 | Student Recs Index | `/recommendation/student-recommendations` | `index()` | 🟡 Wrong perms |
| SCR-REC-14 | Student Recs Create | `/recommendation/student-recommendations/create` | `create()` | ✅ |
| SCR-REC-15 | Student Recs Edit | `/recommendation/student-recommendations/{id}/edit` | `edit()` | 🟡 Wrong perm |
| SCR-REC-16 | Student Recs Trash | `/recommendation/student-recommendations/trashed` | `trashed()` | 🟡 Wrong perm |
| SCR-REC-17 | Assessment Types | `/recommendation/assessment-types` | `index()` | ❌ No route |
| SCR-REC-18 | Trigger Events | `/recommendation/trigger-events` | `index()` | ✅ |
| SCR-REC-19 | Recommendation Modes | `/recommendation/recommendation-modes` | `index()` | ✅ |
| SCR-REC-20 | Analytics Dashboard | `/recommendation/analytics` | `dashboard()` | ❌ Not built |
| SCR-REC-21 | Student Portal View | (Student Portal module) | (STP module) | ❌ Not built |

---

## 8. Business Rules

### 8.1 Recommendation Generation Rules

| Rule ID | Rule Description |
|---|---|
| BR-REC-01 | A `rec_student_recommendations` record requires either `material_id` OR `bundle_id` — both cannot be null |
| BR-REC-02 | When multiple rules match the same student+subject+topic scope, the rule with the highest `priority` value wins |
| BR-REC-03 | Deduplication: do not create a new recommendation if an identical (student + material/bundle) recommendation already exists with status NOT IN (COMPLETED, SKIPPED, EXPIRED) within the last 30 days |
| BR-REC-04 | A rule's `assessment_type_id = NULL` means the rule applies to any assessment type |
| BR-REC-05 | A rule's scope columns (`class_id`, `subject_id`, `topic_id`) = NULL means the rule applies to all values of that dimension |
| BR-REC-06 | Rules with `is_automated = 0` are never triggered by the event system — they are available only for manual assignment assistance |
| BR-REC-07 | Only rules with `is_active = 1` are evaluated by the engine |

### 8.2 Status Transition Rules

| Current Status | Allowed Transitions | Method |
|---|---|---|
| PENDING | → VIEWED, SKIPPED, EXPIRED | `markAsViewed()`, `markAsSkipped()`, `markAsExpired()` |
| VIEWED | → IN_PROGRESS, SKIPPED, EXPIRED | `markAsInProgress()`, `markAsSkipped()`, `markAsExpired()` |
| IN_PROGRESS | → COMPLETED, SKIPPED, EXPIRED | `markAsCompleted()`, `markAsSkipped()`, `markAsExpired()` |
| COMPLETED | No further transitions | Terminal state |
| SKIPPED | → PENDING (reopen) | Admin only |
| EXPIRED | No further transitions | Terminal state |

**V2 Action:** Enforce transition validity in `updateStatus()` — reject invalid transitions with 422 error.

### 8.3 Permission Naming Standard (V2 Unified)

All permissions follow `tenant.{resource}.{action}`. The 4 broken patterns found in v1 code must be replaced:

| V1 Broken Pattern | V2 Standard |
|---|---|
| `recommendation.recommendation_materials.viewAny` | `tenant.recommendation-material.viewAny` |
| `recommendation.tenant.assessment-type.create` | `tenant.assessment-type.create` |
| `recommendation.recommendation_modes.restore` | `tenant.recommendation-mode.restore` |
| `tenant.assessment-type.viewAny` | `tenant.assessment-type.viewAny` (correct) |

**Complete V2 Permission Register:**

```
tenant.trigger-event.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.recommendation-mode.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.dynamic-material-type.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.dynamic-purpose.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.assessment-type.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.recommendation-material.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.material-bundle.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.recommendation-rule.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.student-recommendation.viewAny | .view | .create | .update | .delete | .restore | .forceDelete
tenant.recommendation-analytics.viewAny
```

### 8.4 FormRequest Requirements

| FormRequest | Controller | Replaces |
|---|---|---|
| `StoreRecommendationMaterialRequest` | `RecommendationMaterialController::store` | `Validator::make($request->all(), ...)` |
| `UpdateRecommendationMaterialRequest` | `RecommendationMaterialController::update` | `Validator::make($request->all(), ...)` |
| `StoreMaterialBundleRequest` | `MaterialBundleController::store` | inline `$request->validate()` |
| `UpdateMaterialBundleRequest` | `MaterialBundleController::update` | inline `$request->validate()` |
| `StoreRecommendationRuleRequest` | `RecommendationRuleController::store` | inline `$request->validate()` |
| `UpdateRecommendationRuleRequest` | `RecommendationRuleController::update` | inline `$request->validate()` |
| `StoreStudentRecommendationRequest` | `StudentRecommendationController::store` | inline `$request->validate()` |
| `UpdateStudentRecommendationRequest` | `StudentRecommendationController::update` | inline `$request->validate()` |
| `StoreTriggerEventRequest` | `RecTriggerEventController::store` | inline `$request->validate()` |
| `UpdateStatusRequest` | `StudentRecommendationController::updateStatus` | inline `$request->validate()` |

All FormRequests must implement `authorize()` returning `true` (gate check stays in controller) and define `rules()` returning the validation array.

---

## 9. Workflows

### 9.1 Automated Recommendation Pipeline

```
[Exam Module]
    |
    | ExamResultSubmitted event fired after result saved
    v
[HandleExamResultForRecommendations listener] (queued)
    |
    | RecommendationEngineService::processResult($result)
    v
[Query active rules matching trigger=ON_ASSESSMENT_RESULT]
    |
    | Apply scope filters: class_id, subject_id, topic_id (NULL = wildcard)
    | Apply performance filters: min_score_pct <= score <= max_score_pct
    | Apply assessment type filter
    | Sort by priority DESC
    v
[For each matching rule]
    |
    | RecommendationEngineService::resolveContent($rule, $student)
    v
[Mode resolution]
    |-- SPECIFIC_MATERIAL  → use target_material_id directly
    |-- SPECIFIC_BUNDLE    → use target_bundle_id directly
    |-- DYNAMIC_BY_TOPIC   → query materials by topic + type + purpose
    `-- DYNAMIC_BY_COMPETENCY → query materials by competency_code gap
    |
    v
[Deduplication check: active recommendation same student+content within 30d?]
    |-- Yes → skip
    `-- No  → create rec_student_recommendations record
              set rule_id, triggered_by_result_id, reason, priority
              fire NewRecommendationAssigned notification (future)
```

### 9.2 Manual Recommendation Assignment Workflow

```
Teacher navigates to Student Recommendations → Create
    |
    | Selects: student, rule (optional), material OR bundle, priority, due_date
    v
StudentRecommendationController::store() validates via FormRequest
    |
    | Checks: material_id OR bundle_id must be set
    | Sets: assigned_at = now(), manual_assigned_by = Auth::id()
    v
rec_student_recommendations record created with status = PENDING
    |
    v
activityLog() called
Redirect to student recommendations index with success flash
```

### 9.3 Student Recommendation Lifecycle

```
PENDING ──[student opens material]──> VIEWED
         ──[student dismisses]──────> SKIPPED
         ──[due_date passes]────────> EXPIRED (batch job)

VIEWED ──[student begins]──────────> IN_PROGRESS
        ──[student dismisses]───────> SKIPPED
        ──[due_date passes]─────────> EXPIRED (batch job)

IN_PROGRESS ──[student finishes]──> COMPLETED (optional: score_achieved recorded)
             ──[student dismisses]─> SKIPPED
             ──[due_date passes]──> EXPIRED (batch job)

COMPLETED ──[student rates 1-5★]──> (rating + feedback stored, status unchanged)
```

### 9.4 Batch Expiry Job Workflow

```
Scheduled nightly (02:00 AM school timezone)
    |
    v
ExpireRecommendationsCommand::handle()
    |
    | Query: status IN (PENDING, IN_PROGRESS) AND due_date < today()
    v
For each result:
    | $rec->markAsExpired()
    | activityLog($rec, 'AutoExpired', [...])
    v
Log: "Expired {count} recommendations"
Return count
```

---

## 10. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-REC-01 | Security | All routes protected by `EnsureTenantHasModule:REC` middleware |
| NFR-REC-02 | Security | All controller methods have explicit `Gate::authorize()` call with correct `tenant.{resource}.{action}` permission |
| NFR-REC-03 | Security | `Gate::any()` return value must NEVER be discarded — always wrap with `abort_unless()` or check result |
| NFR-REC-04 | Security | All mutations use `$request->validated()` (via FormRequest) — never `$request->all()` |
| NFR-REC-05 | Performance | All list views paginated (default 10 per page, configurable) |
| NFR-REC-06 | Performance | Rule evaluation queries use indexes: `idx_recRule_trigger`, `idx_recMat_scope` |
| NFR-REC-07 | Performance | Event listener dispatches a queued job — must not block HTTP response |
| NFR-REC-08 | Performance | `tabIndex()` and `tabIndex_2()` load 5–6 paginated queries; consider lazy loading on tabs to avoid simultaneous queries |
| NFR-REC-09 | Reliability | `ExpireRecommendationsCommand` must be idempotent — safe to run multiple times per day |
| NFR-REC-10 | Reliability | `DB::transaction` wraps bundle-material sync on store/update |
| NFR-REC-11 | Audit | `activityLog()` called on all create/update/delete/restore/forceDelete operations |
| NFR-REC-12 | Maintainability | All deprecated `materials-old/` views must be deleted |
| NFR-REC-13 | Maintainability | `PerformanceSnapshot` model must either be backed by DDL table or removed |
| NFR-REC-14 | Data Integrity | UUID auto-generated via model boot on `rec_student_recommendations` creation |
| NFR-REC-15 | Multi-tenancy | All queries scoped to current tenant via stancl/tenancy v3.9 tenant context |

---

## 11. Dependencies

### 11.1 Inbound Dependencies (Modules REC Consumes)

| Module | Table(s) Consumed | Purpose |
|---|---|---|
| SchoolSetup | `sch_classes`, `sch_subjects`, `sch_organizations` | Scope rules and materials to class/subject; school context for bundles |
| Syllabus | `slb_topics`, `slb_performance_categories`, `slb_complexity_level` | Topic scoping; performance bucket matching; material difficulty tagging |
| QuestionBank | `qns_media_store` | Upload and reference media files for material content |
| StudentProfile | `std_students` | Target students for recommendations |
| GlobalMaster | `sys_dropdown_table` | Material type, purpose, content source dropdown values |
| LMS-Exam | `exm_results` (proposed) | Trigger event: exam result submitted → fires rule engine |
| LMS-Quiz | `quz_results` (proposed) | Trigger event: quiz result submitted → fires rule engine |
| PredictiveAnalytics (PAN) | `pan_risk_scores` (future) | PAN risk scores feed into at-risk student identification for REC |

### 11.2 Outbound Dependencies (Modules That Consume REC)

| Module | Data Provided | Purpose |
|---|---|---|
| StudentPortal (STP) | `rec_student_recommendations` | Student portal displays pending/active recommendations |
| ParentPortal (PPT) | `rec_student_recommendations` (future) | Parent reads child's recommendations |
| Dashboard (DSH) | Completion stats | Dashboard widgets for recommendation completion rates |
| Notifications (NTF) | Recommendation assigned events (future) | Push notification to student when recommendation assigned |

---

## 12. Test Scenarios

### 12.1 Unit Tests

| Test Class | Method | Scenario |
|---|---|---|
| `RecommendationRuleMatcherTest` | `test_rule_matches_score_in_range` | Score 35% matches rule with min=0 max=40 |
| `RecommendationRuleMatcherTest` | `test_rule_does_not_match_score_above_range` | Score 45% does NOT match rule with min=0 max=40 |
| `RecommendationRuleMatcherTest` | `test_null_class_matches_any_class` | Rule with class_id=NULL matches student from any class |
| `RecommendationRuleMatcherTest` | `test_higher_priority_rule_wins` | Two matching rules: priority 20 returned first |
| `DynamicContentResolverTest` | `test_dynamic_by_topic_returns_best_match` | DYNAMIC_BY_TOPIC mode queries materials by topic+type+purpose |
| `DynamicContentResolverTest` | `test_specific_material_returns_target` | SPECIFIC_MATERIAL mode returns exact `target_material_id` |
| `StudentRecommendationLifecycleTest` | `test_mark_as_viewed_sets_first_viewed_at` | `first_viewed_at` set on first call only |
| `StudentRecommendationLifecycleTest` | `test_mark_as_viewed_only_changes_pending_status` | Calling `markAsViewed` on COMPLETED leaves status unchanged |
| `StudentRecommendationLifecycleTest` | `test_mark_as_completed_sets_completed_at` | `completed_at` timestamp set |
| `StudentRecommendationLifecycleTest` | `test_is_overdue_accessor` | `is_overdue` = true when due_date < now AND status = PENDING |
| `DeduplicationTest` | `test_duplicate_recommendation_not_created` | Same student+material within 30 days → engine skips |
| `DeduplicationTest` | `test_expired_recommendation_allows_new` | After expiry, new recommendation for same material is allowed |

### 12.2 Feature Tests

| Test Class | Scenario | Expected |
|---|---|---|
| `RecommendationRuleCrudTest` | Create rule via POST → verify stored in DB | Rule with correct trigger_event_id saved |
| `RecommendationRuleCrudTest` | Soft delete rule → verify not in index | Rule excluded from active list; in trash list |
| `RecommendationEngineTest` | Submit exam result event → verify student rec created | `rec_student_recommendations` row exists for student |
| `RecommendationEngineTest` | Submit exam result, no matching rule → no rec created | Zero new rows |
| `ManualAssignmentTest` | Teacher creates manual recommendation → student can see it | Record created with `manual_assigned_by` = teacher ID |
| `StatusLifecycleTest` | AJAX update-status from PENDING to VIEWED → JSON response | `success: true`, `status: VIEWED` |
| `RatingTest` | Student submits 4-star rating → stored correctly | `student_rating = 4` in DB |
| `ExpireJobTest` | Run expire command with overdue records → all EXPIRED | Count returned matches; statuses updated |
| `AuthorizationTest` | User without `tenant.recommendation-material.create` attempts POST → 403 | HTTP 403 response |
| `AuthorizationTest` | `Gate::any()` fix: user without any listed permission → 403 on tab index | HTTP 403 response |
| `MaterialBundleSyncTest` | Create bundle with 3 materials → junction table has 3 rows with correct sequence_order | 3 rows in `rec_bundle_materials_jnt` |
| `MaterialBundleSyncTest` | Update bundle removing 1 material → junction table updated correctly | 2 rows remain; deleted row gone |
| `RouteAccessTest` | Assessment types route accessible after registration fix | HTTP 200 on `/recommendation/assessment-types` |
| `DeduplicationFeatureTest` | Engine fires twice for same student+material within 30 days → only 1 rec created | 1 row, not 2 |

---

## 13. Glossary

| Term | Definition |
|---|---|
| **Trigger Event** | A system event or schedule that activates rule evaluation (e.g., exam result saved) |
| **Recommendation Rule** | An IF-THEN business logic record: WHEN [trigger] + IF [conditions] THEN [recommend X] |
| **Recommendation Mode** | How content is resolved: SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY |
| **Dynamic Mode** | Content is auto-selected by the engine by querying materials matching topic/type/purpose criteria |
| **Material** | A single learning content item: video URL, PDF file, quiz link, HTML notes, or interactive resource |
| **Bundle** | An ordered collection of materials packaged as a single learning kit |
| **Student Recommendation** | The dispatched assignment record linking a specific student to a specific material/bundle with tracking metadata |
| **Performance Category** | A bucket defined in Syllabus module (e.g., POOR, AVERAGE, GOOD) used to trigger rules |
| **Rule Engine** | The automated service that evaluates active rules against student performance data and dispatches recommendations |
| **Deduplication** | The check that prevents the same material being recommended to the same student twice within a rolling window |
| **Expiry** | Automatic transition to EXPIRED status when `due_date` passes without COMPLETED or SKIPPED |
| **Gate::any()** | Laravel Gate method returning boolean; must NOT be used without checking return value for authorization |
| **FormRequest** | Laravel class encapsulating validation rules; required for all state-mutating endpoints |

---

## 14. Suggestions (V2 Proposed Improvements)

### 14.1 Critical Security Fixes (P0 — Before Any Production Deploy)

1. **Fix `Gate::any()` authorization bypass** in `RecommendationController::tabIndex()` and `tabIndex_2()`. The current code calls `Gate::any([...])` but discards the boolean return value — authorization is completely bypassed. Fix: `abort_unless(Gate::any([...]), 403)`.

2. **Fix `StudentRecommendationController` mass permission misuse.** 10 distinct methods (`show`, `edit`, `update`, `destroy`, `trashed`, `restore`, `forceDelete`, `markAsCompleted`, `updateStatus`, `addRating`) all use `tenant.student-recommendation.create` instead of their correct permissions. This means any user with CREATE permission can perform permanent deletions.

3. **Add `Gate::authorize()` to 4 unprotected methods** in `RecommendationMaterialController`: `create()`, `edit()`, `store()`, `update()`.

4. **Add `EnsureTenantHasModule:REC` middleware** to the recommendation route group in `tenant.php:828`.

5. **Standardize all permission strings** to `tenant.{resource}.{action}` pattern across all 10 controllers (currently 4 different patterns exist).

### 14.2 Architecture Improvements (P1)

6. **Create `RecommendationEngineService`** as the central rule evaluation and dispatch engine. Extract all recommendation generation logic from controllers. This service should be injected into the event listener, the batch command, and any manual dispatch endpoint.

7. **Replace all inline validation with FormRequests** (10 required). Use `$request->validated()` in controllers — never `$request->all()`.

8. **Fix table name inconsistency**: `slb_complexity_level` (singular) is the actual DDL table name. The `store()` method in `RecommendationMaterialController` uses `slb_complexity_levels` (plural) which will fail validation with `Rule::exists()`.

9. **Fix `rec_student_recommendations` validation table mismatch**: `update()` validates `student_id` against `users` but `store()` correctly uses `sys_users`. Standardize to `sys_users`.

10. **Register `RecAssessmentTypePolicy`** in `AppServiceProvider.php`; create the policy class.

### 14.3 Feature Completions (P2)

11. **Create `rec_performance_snapshots` table** to support DYNAMIC_BY_COMPETENCY mode and scheduled recommendations. The `PerformanceSnapshot` model exists with empty `$fillable` — either back it with a DDL table or remove the model entirely.

12. **Implement `RecommendationEngineService`** with methods: `processResult()`, `resolveContent()`, `dispatchRecommendation()`, `expireOverdue()`.

13. **Create `ExpireRecommendationsCommand`** as a daily scheduled Artisan command. Add to scheduler in `app/Console/Kernel.php`.

14. **Build `RecommendationAnalyticsController`** with dashboard view showing completion rates, popular materials, rule effectiveness, and at-risk student list.

15. **Delete `materials-old/` views directory** (deprecated, unreferenced).

16. **Add `deleted_at` column** to `rec_student_recommendations` via migration (DDL is missing this column but model uses `SoftDeletes`).

### 14.4 Integration Improvements (P3)

17. **Register event listener** in `EventServiceProvider.php`: `ExamResultSubmitted` → `HandleExamResultForRecommendations`. The listener must dispatch a queued job to avoid blocking the HTTP response.

18. **Add quiz result integration**: Also listen for `QuizResultSubmitted` to fire ON_ASSESSMENT_RESULT rules.

19. **Provide API endpoints for Student Portal module**: Student Portal needs REST API endpoints to display a student's pending recommendations. Implement in `routes/api.php` with `auth:sanctum` middleware.

20. **`rec_material_bundles.school_id`**: Either add the column via migration (if bundles should be school-scoped) or remove `school_id` references from `MaterialBundle` model and controller. Current DDL has no `school_id` column but code references it.

21. **Add `deleted_at` to `rec_student_recommendations`**: The DDL for this table has no `deleted_at` column but the model uses the `SoftDeletes` trait. A migration is required: `$table->softDeletes()`. Until this migration runs, `onlyTrashed()` and `withTrashed()` queries will silently fail.

22. **Recommendation notification integration (P4)**: Once the engine is dispatching recommendations, integrate with the Notifications (NTF) module to push an in-app notification or email to the student when a new recommendation is assigned. The payload should include material title, due date, and priority. This requires a `NewRecommendationAssigned` event and a corresponding `NTF` notification class.

23. **Content preview in material form**: The `RecommendationMaterial` create/edit views should render a live preview pane for `content_text` (HTML editor preview) and an iframe/thumbnail for `external_url` entries. This improves teacher UX when building the content library.

24. **Bulk recommendation assignment**: Allow teachers to select multiple students from a class and assign the same material/bundle in one action. This is particularly useful for post-exam remediation where an entire class section needs the same supplemental content. Implement as a separate `BulkAssignController::store()` with a `StoreBulkRecommendationRequest`.

---

## 15. Appendices

### Appendix A — Controller Security Audit Summary

| Controller | Gate::authorize() | FormRequest | Permission Pattern | Status |
|---|---|---|---|---|
| `RecommendationController` | Broken (Gate::any discarded) | None | `tenant.xxx.viewAny` | CRITICAL |
| `StudentRecommendationController` | Wrong permissions (10 methods use .create) | None | `tenant.student-recommendation.*` | CRITICAL |
| `RecommendationMaterialController` | Missing on create/edit/store/update | None (Validator::make) | `recommendation.recommendation_materials.*` | CRITICAL |
| `MaterialBundleController` | Present and correct | None | `tenant.material-bundle.*` | MEDIUM |
| `RecommendationRuleController` | Present and correct | None | `tenant.recommendation-rule.*` | MEDIUM |
| `RecAssessmentTypeController` | Present | None | `recommendation.tenant.assessment-type.*` | HIGH |
| `RecommendationModeController` | Present (1 wrong) | None | `tenant.recommendation-mode.*` | LOW |
| `RecTriggerEventController` | Present and correct | None | `tenant.trigger-event.*` | MEDIUM |
| `DynamicMaterialTypeController` | Present and correct | None | `tenant.dynamic-material-type.*` | MEDIUM |
| `DynamicPurposeController` | Present and correct | None | `tenant.dynamic-purpose.*` | MEDIUM |

### Appendix B — Model Inventory

| Model | Table | SoftDeletes | Key Methods / Accessors |
|---|---|---|---|
| `RecTriggerEvent` | `rec_trigger_events` | Yes | Standard |
| `RecommendationMode` | `rec_recommendation_modes` | Yes | Standard |
| `DynamicMaterialType` | `rec_dynamic_material_types` | Yes | Standard |
| `DynamicPurpose` | `rec_dynamic_purposes` | Yes | Standard |
| `RecAssessmentType` | `rec_assessment_types` | Yes | Standard |
| `RecommendationMaterial` | `rec_recommendation_materials` | Yes | Standard |
| `MaterialBundle` | `rec_material_bundles` | Yes | BelongsToMany materials via junction |
| `BundleMaterialJnt` | `rec_bundle_materials_jnt` | No | Junction pivot |
| `RecommendationRule` | `rec_recommendation_rules` | Yes | BelongsTo 9 related models |
| `StudentRecommendation` | `rec_student_recommendations` | Yes | UUID auto-gen; `markAsViewed/InProgress/Completed/Skipped/Expired/addRating`; accessors: `is_overdue`, `days_remaining`, `status_badge_class`, `priority_badge_class`, `star_rating` |
| `PerformanceSnapshot` | (none) | No | **BROKEN:** `$fillable = []`, no `$table` — unusable orphan model |

### Appendix C — Policies Inventory

| Policy | Covers | Status |
|---|---|---|
| `TriggerEventPolicy` | `RecTriggerEvent` | Registered |
| `RecommendationModePolicy` | `RecommendationMode` | Registered |
| `DynamicMaterialTypePolicy` | `DynamicMaterialType` | Registered |
| `DynamicPurposePolicy` | `DynamicPurpose` | Registered |
| `RecommendationMaterialPolicy` | `RecommendationMaterial` | Registered |
| `MaterialBundlePolicy` | `MaterialBundle` | Registered |
| `RecommendationRulePolicy` | `RecommendationRule` | Registered |
| `StudentRecommendationPolicy` | `StudentRecommendation` | Registered |
| `RecAssessmentTypePolicy` | `RecAssessmentType` | **MISSING** — import commented out in AppServiceProvider; policy file does not exist |

### Appendix E — Seeder Requirements

The following seeders are required for the REC module to function with default data:

| Seeder Class | Target Table | Default Records |
|---|---|---|
| `RecTriggerEventSeeder` | `rec_trigger_events` | ON_ASSESSMENT_RESULT, ON_TOPIC_COMPLETION, ON_ATTENDANCE_LOW, MANUAL_RUN, SCHEDULED_WEEKLY |
| `RecRecommendationModeSeeder` | `rec_recommendation_modes` | SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY |
| `RecDynamicMaterialTypeSeeder` | `rec_dynamic_material_types` | ANY_BEST_FIT, VIDEO, QUIZ, PDF, AUDIO, INTERACTIVE |
| `RecDynamicPurposeSeeder` | `rec_dynamic_purposes` | REMEDIAL, ENRICHMENT, PRACTICE, REVISION |
| `RecAssessmentTypeSeeder` | `rec_assessment_types` | ALL, QUIZ, WEEKLY_TEST, TERM_EXAM, FINAL_EXAM |
| `RecPermissionSeeder` | `sys_permissions` | All `tenant.{resource}.{action}` permissions listed in Section 8.3 |

The existing `RecommendationDatabaseSeeder.php` should call all the above seeders in dependency order. Permissions must be seeded before any policy evaluation occurs.

### Appendix D — Effort Estimate

| Priority | Work Items | Hours |
|---|---|---|
| P0 — Critical Fixes | 5 security items (Gate::any, wrong perms, unprotected methods, middleware, permission standardization) | 15–20 h |
| P1 — Architecture | 10 FormRequests, RecAssessmentType routes+policy, table name fixes, validation fixes, stub implementations | 20–30 h |
| P2 — Engine | RecommendationEngineService, ExpireCommand, event listener, performance_snapshots table+model | 35–45 h |
| P3 — Analytics | Analytics controller + views + CSV export | 15–20 h |
| P4 — Tests | 20+ unit + feature tests | 20–25 h |
| **Total** | | **105–140 h** |

---

## 16. Completion Criteria

The REC module is considered production-ready when ALL of the following are true:

| # | Criterion | Verification |
|---|---|---|
| 1 | All critical security bugs (P0) fixed: `Gate::any()` abort, StudentRecommendation permissions, Material auth guards, middleware | Code review + auth test |
| 2 | Permission naming standardized to `tenant.{resource}.{action}` across all 10 controllers | Permission seeder grep |
| 3 | 10 FormRequest classes created and wired into controllers | File existence + controller usage |
| 4 | `RecAssessmentTypePolicy` created and registered; assessment-type routes added | HTTP 200 on routes |
| 5 | `RecommendationEngineService` implemented: processResult, resolveContent, dispatchRecommendation, expireOverdue | Engine integration test |
| 6 | `ExamResultSubmitted` event listener registered and working end-to-end | Feature test: submit result → rec created |
| 7 | `ExpireRecommendationsCommand` runs nightly and marks overdue records EXPIRED | Scheduler test |
| 8 | Analytics dashboard displays: completion rate, top materials, rule effectiveness, at-risk list | Manual QA |
| 9 | `rec_student_recommendations` has `deleted_at` column (migration applied) | DB schema check |
| 10 | `rec_material_bundles.school_id` discrepancy resolved (migration or model cleanup) | Code + DB alignment |
| 11 | `PerformanceSnapshot` model backed by DDL table OR removed entirely | No orphan model |
| 12 | `materials-old/` views directory deleted | File system |
| 13 | Minimum 22 unit + feature tests passing (0 failures) | `php artisan test --filter Recommendation` |
| 14 | Zero empty stub controller methods | Code review |
| 15 | Student Portal API endpoints returning correct data for student's recommendations | API test |

---

## 17. V1 to V2 Delta

| Section | V1 Coverage | V2 Additions |
|---|---|---|
| Security Bugs | Listed as issues | Documented as FR-REC-19 through FR-REC-22 with exact fix patterns; `abort_unless(Gate::any([...]), 403)` pattern specified |
| Permission Names | Target state listed | Full permission register added to Section 8.3; mapping of all 4 broken patterns to V2 standard |
| FormRequests | Listed as gap | Full table in Section 8.4 with 10 required classes, each mapped to controller method and what it replaces |
| DDL Verification | Based on v1.4 DDL | Verified against `tenant_db_v2.sql`; confirmed `slb_complexity_level` (singular) is correct; confirmed no `school_id` on bundles; confirmed no `deleted_at` on student_recommendations |
| Rule Engine | Described conceptually | FR-REC-12 through FR-REC-17 with specific method signatures; workflow diagram in Section 9.1 |
| Status Transitions | Described | Formal state machine table in Section 8.2; invalid transition enforcement added as V2 action |
| Analytics Dashboard | Listed as missing | FR-REC-18 with full metric list; SCR-REC-20; analytics routes defined |
| API for Student Portal | Out of scope in V1 | FR added in Section 4.4; API routes defined in Section 6.3 |
| `PerformanceSnapshot` | Identified as orphan | Disposition specified: either back with DDL (proposed `rec_performance_snapshots` schema in Section 5.5) or remove model |
| Batch Jobs | Listed as missing | FR-REC-16 and FR-REC-17 with workflow; `ExpireRecommendationsCommand` specified with idempotency requirement |
| Test Scenarios | 8 tests listed | 22 tests across unit and feature (Section 12) with specific assertion patterns |
| New Tables Proposed | None | `rec_performance_snapshots` proposed in Section 5.5 |
| Model Accessors | Partially documented | Full model method/accessor inventory in Appendix B |
