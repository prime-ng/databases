# REC — Recommendation Module
## Requirement Document v1.0

**Module Code:** REC
**Module Type:** Tenant Module (per-school)
**Table Prefix:** `rec_*`
**RBS Reference:** Module U — Predictive Analytics & ML Engine (sub-tasks U1–U9)
**Completion Status:** ~39%
**Document Date:** 2026-03-25

---

## 1. Module Overview

The Recommendation module is the personalized learning guidance engine of Prime-AI. It analyzes student assessment results, attendance patterns, and learning history to surface targeted content recommendations — pointing each student toward the right material at the right time. The module operates in two modes: automated rule-based triggering (system fires recommendations based on events like exam result submission) and manual teacher assignment (teacher selects and pushes material to a specific student).

The module is tightly integrated with LMS modules (Homework, Quiz, Exam), Syllabus, and QuestionBank. It is a consumer of data produced by those modules but does not itself produce grades or attendance data.

**Core Value Proposition:** When a student scores poorly in a topic, the system automatically recommends a remedial video, PDF, or practice quiz without teacher intervention. The teacher can also manually override or supplement the automated recommendations.

---

## 2. Business Context

Indian K-12 schools typically lack any systematic mechanism to close learning gaps. Teachers identify weak students informally and may suggest materials through WhatsApp groups. Prime-AI's Recommendation engine formalizes this by:

- Maintaining a curated content library (materials and bundles)
- Defining rule conditions (which performance triggers what content)
- Automatically dispatching recommendations to student dashboards
- Tracking whether the student viewed, completed, or skipped the material
- Collecting feedback via star ratings

This directly supports RBS Module U requirements for student performance prediction (U1), skill gap analysis (U4), and AI dashboards (U7).

---

## 3. Module Scope

### In Scope
- Recommendation master configuration (trigger events, modes, material types, purposes, assessment types)
- Content library management (materials with files/text/links, bundles of materials)
- Rule engine (WHEN + WHO + WHAT logic for automated recommendations)
- Student recommendation lifecycle (assign → view → in-progress → complete/skip/expire)
- Status tracking and outcome recording (score achieved, star rating, feedback)
- Trash/restore/force-delete for all entities

### Out of Scope (Current Phase)
- ML-based predictive analytics (RBS U1–U3: risk prediction, attendance forecasting, fee default prediction)
- Transport route optimization (RBS U5)
- Institutional benchmarking (RBS U9)
- Sentiment analysis on feedback text (RBS U8)
- Parent portal view of student recommendations
- Push notifications to student devices when new recommendation is assigned

---

## 4. Database Schema

### 4.1 Master / Lookup Tables

| Table | Purpose | Key Columns |
|---|---|---|
| `rec_trigger_events` | When to fire a recommendation (e.g., ON_ASSESSMENT_RESULT, MANUAL_RUN, SCHEDULED_WEEKLY) | `event_name` (unique VARCHAR 50) |
| `rec_recommendation_modes` | How the recommendation is fulfilled (SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY) | `mode_name` (unique VARCHAR 50) |
| `rec_dynamic_material_types` | For dynamic mode: what type of content to find (ANY_BEST_FIT, VIDEO, QUIZ, PDF) | `type_name` (unique VARCHAR 50) |
| `rec_dynamic_purposes` | For dynamic mode: what learning purpose (REMEDIAL, ENRICHMENT, PRACTICE) | `purpose_name` (unique VARCHAR 50) |
| `rec_assessment_types` | Which exam type triggers the rule (ALL, QUIZ, WEEKLY_TEST, TERM_EXAM, FINAL_EXAM) | `type_name` (unique VARCHAR 50) |

All five lookup tables follow the same structure: `id, name, description, is_active, created_at, updated_at, deleted_at`.

### 4.2 Content Tables

**`rec_recommendation_materials`** — The content bank. Stores individual learning materials that can be recommended to students.

Key columns:
- `title` (VARCHAR 255, required)
- `material_type` (FK to `sys_dropdown_table`) — TEXT, VIDEO, PDF, AUDIO, QUIZ, ASSIGNMENT, LINK, INTERACTIVE
- `purpose` (FK to `sys_dropdown_table`) — REVISION, PRACTICE, REMEDIAL, ADVANCED, ENRICHMENT
- `complexity_level` (FK to `slb_complexity_level`)
- `content_source` (FK to `sys_dropdown_table`) — INTERNAL_EDITOR, UPLOADED_FILE, EXTERNAL_LINK, LMS_MODULE, QUESTION_BANK
- `content_text` (LONGTEXT) — HTML content or notes
- `file_url` (VARCHAR 500) — for uploaded files/PDFs/videos
- `external_url` (VARCHAR 500) — YouTube, Khan Academy, etc.
- `media_id` (FK to `qns_media_store`)
- `subject_id` (FK to `sch_subjects`), `class_id` (FK to `sch_classes`), `topic_id` (FK to `slb_topics`)
- `competency_code` (VARCHAR 50) — links to competency framework
- `duration_seconds` (INT), `language_code` (VARCHAR 10, default 'en')
- `tags` (JSON) — search/filter tags

**`rec_material_bundles`** — Groups of materials packaged as a learning kit (e.g., "Week 1 Algebra Revision Kit").

Key columns: `title`, `description`, `school_id` (FK to `sch_organizations`), `created_by`, `is_active`

**`rec_bundle_materials_jnt`** — Junction connecting bundles to materials.

Key columns: `bundle_id`, `material_id`, `sequence_order`, `is_mandatory`

### 4.3 Rules Engine Table

**`rec_recommendation_rules`** — The IF-THEN logic: WHEN [trigger] + IF [condition] THEN [recommend X].

Key columns:
- `name` (VARCHAR 150) — descriptive label
- `is_automated` (TINYINT) — 1 = system fires it, 0 = manual helper
- `trigger_event_id` (FK to `rec_trigger_events`, required)
- **Scope conditions:** `class_id`, `subject_id`, `topic_id`, `performance_category_id` (FK to `slb_performance_categories`)
- **Score range:** `min_score_pct`, `max_score_pct` (DECIMAL 5,2)
- `assessment_type_id` — only apply if the result was from this exam type
- `recommendation_mode_id` (FK to `rec_recommendation_modes`, required)
- **Action targets:** `target_material_id`, `target_bundle_id`, `dynamic_material_type_id`, `dynamic_purpose_id`
- `priority` (INT, default 10) — higher priority rules win conflicts

### 4.4 Student Recommendation Table

**`rec_student_recommendations`** — The actual recommendation records dispatched to students.

Key columns:
- `uuid` (BINARY 16) — unique public tracking identifier (auto-generated on create)
- `student_id` (FK to `std_students`)
- `rule_id` (FK to `rec_recommendation_rules`, nullable — NULL = manual)
- `triggered_by_result_id` — link to exam result that triggered this
- `manual_assigned_by` (FK to `sch_teachers`) — teacher who manually assigned
- `material_id` or `bundle_id` — one must be set
- `recommendation_reason` (VARCHAR 255) — e.g., "Scored 32% in Algebra Quiz"
- `priority` ENUM('LOW','MEDIUM','HIGH','CRITICAL')
- `due_date` (DATE)
- `status` ENUM('PENDING','VIEWED','IN_PROGRESS','COMPLETED','SKIPPED','EXPIRED')
- Timestamps: `assigned_at`, `first_viewed_at`, `completed_at`
- Outcomes: `score_achieved` (DECIMAL 5,2), `student_rating` (TINYINT 1-5), `student_feedback`

---

## 5. Functional Requirements

### 5.1 Recommendation Masters Screen (Tab-based UI)

**Tab 1: Configuration Masters**

| Feature | Description |
|---|---|
| Trigger Events CRUD | Create/edit/delete trigger event types (e.g., ON_ASSESSMENT_RESULT). Full lifecycle: trash, restore, force-delete, status toggle. |
| Recommendation Modes CRUD | Manage delivery modes (SPECIFIC_MATERIAL, DYNAMIC_BY_TOPIC, etc.). |
| Dynamic Material Types CRUD | Lookup values for dynamic mode material type filter. |
| Dynamic Purposes CRUD | Lookup values for dynamic mode purpose filter. |
| Assessment Types CRUD | Lookup values for which exam type triggers a rule. |

**Tab 2: Content and Rules**

| Feature | Description |
|---|---|
| Recommendation Materials CRUD | Full lifecycle management of content items. Supports file URL, external URL, and embedded media via `qns_media_store`. Tag-based search. Academic mapping to class/subject/topic. |
| Material Bundles CRUD | Create bundles of ordered materials. Manage bundle-material junction with sequence order and mandatory flags. School-scoped. |
| Recommendation Rules CRUD | Define rule conditions and target actions. Supports both static (specific material/bundle) and dynamic (find best-fit by type+purpose) modes. |
| Student Recommendations CRUD | Manual assignment flow: select student, select rule/material/bundle, set priority and due date, track status. |

### 5.2 Recommendation Rule Engine (Core Logic — Not Yet Implemented)

The rule engine is the automated trigger that should run as a scheduled or event-driven job:

1. When an exam result is submitted (trigger_event = ON_ASSESSMENT_RESULT), the engine queries all active `rec_recommendation_rules` where:
   - `trigger_event_id` matches the event type
   - `assessment_type_id` matches the exam type (or is NULL = any)
   - `class_id` matches the student's class (or is NULL = any class)
   - `subject_id` matches the exam subject (or is NULL = any subject)
   - `topic_id` matches the exam topic (or is NULL = any topic)
   - Student's score falls within `min_score_pct` to `max_score_pct`
   - `performance_category_id` matches the student's performance bucket
2. For matching rules, the engine resolves the content to recommend based on `recommendation_mode_id`:
   - SPECIFIC_MATERIAL: assign `target_material_id`
   - SPECIFIC_BUNDLE: assign `target_bundle_id`
   - DYNAMIC_BY_TOPIC: find best materials matching student's weak topic + dynamic_material_type + dynamic_purpose
   - DYNAMIC_BY_COMPETENCY: find materials by competency_code gap
3. Create a `rec_student_recommendations` record for each student-material match
4. Higher `priority` rules override when multiple rules match the same student+subject+topic scope

**Gap:** No service class exists for the rule engine. `RecommendationController::store()` and `update()` are empty stubs.

### 5.3 Student Recommendation Lifecycle

| Status | Trigger | Method |
|---|---|---|
| PENDING | Created by rule engine or manual assignment | Default on create |
| VIEWED | Student opens the material | `markAsViewed()` — sets `first_viewed_at` if not already set |
| IN_PROGRESS | Student begins consuming content | `markAsInProgress()` |
| COMPLETED | Student finishes the material | `markAsCompleted($score)` — sets `completed_at`, optionally records score |
| SKIPPED | Student dismisses the recommendation | `markAsSkipped()` |
| EXPIRED | Due date passed without completion | `markAsExpired()` — should run via scheduled job |

**Overdue detection:** `is_overdue` accessor returns true when `due_date < now()` AND status is PENDING or IN_PROGRESS.

**Rating:** After completion (or any time), student can add 1–5 star rating with optional text feedback via `addRating($rating, $feedback)`.

---

## 6. Non-Functional Requirements

| Requirement | Specification |
|---|---|
| Authentication | All routes behind `auth, verified` middleware |
| Authorization | Gate-based per-action (viewAny, create, update, delete, restore, forceDelete) |
| Soft Deletes | All models use SoftDeletes; trash/restore flow required |
| Audit Trail | `activityLog()` called on all create/update/delete operations |
| Pagination | All list views paginated (10 per page) |
| Transactions | MaterialBundle store/update uses DB::transaction for bundle-material sync |

---

## 7. Controllers and Routes

### 7.1 Controller Inventory

| Controller | Methods | Status |
|---|---|---|
| `RecommendationController` | `tabIndex()`, `tabIndex_2()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()` | store/update/destroy are **empty stubs** |
| `RecommendationRuleController` | Full CRUD + trash/restore/forceDelete/toggleStatus | Complete |
| `RecommendationMaterialController` | Full CRUD + trash/restore/forceDelete/toggleStatus | Complete (uses manual Validator, not FormRequest) |
| `MaterialBundleController` | Full CRUD + trash/restore/forceDelete/toggleStatus + bundle-material sync | Complete |
| `StudentRecommendationController` | Full CRUD + trash/restore/forceDelete + markAsCompleted + updateStatus + addRating | Complete (wrong permission on edit/destroy — uses `.create` instead of `.update`/`.delete`) |
| `DynamicMaterialTypeController` | Full CRUD + trash/restore/forceDelete/toggleStatus | Complete |
| `DynamicPurposeController` | Full CRUD + trash/restore/forceDelete/toggleStatus | Complete |
| `RecAssessmentTypeController` | Full CRUD + trash/restore/forceDelete/toggleStatus | Complete (inconsistent permission naming) |
| `RecommendationModeController` | Full CRUD + trash/restore/forceDelete/toggleStatus | Complete |
| `RecTriggerEventController` | Full CRUD + trash/restore/forceDelete/toggleStatus | Complete |

### 7.2 Route Structure

All tenant recommendation routes are prefixed with `/recommendation` and named `recommendation.*`:

| Route Name | HTTP | URI |
|---|---|---|
| `recommendation.recommendation-mgt` | GET | `/recommendation/recommendation-mgt` |
| `recommendation.rec-material` | GET | `/recommendation/rec-material` |
| `recommendation.recommendation-rules.*` | Resource | `/recommendation/recommendation-rules` |
| `recommendation.recommendation-materials.*` | Resource | `/recommendation/recommendation-materials` |
| `recommendation.material-bundles.*` | Resource | `/recommendation/material-bundles` |
| `recommendation.student-recommendations.*` | Resource | `/recommendation/student-recommendations` |
| `recommendation.trigger-events.*` | Resource | `/recommendation/trigger-events` |
| `recommendation.recommendation-modes.*` | Resource | `/recommendation/recommendation-modes` |
| `recommendation.dynamic-material-types.*` | Resource | `/recommendation/dynamic-material-types` |
| `recommendation.dynamic-purposes.*` | Resource | `/recommendation/dynamic-purposes` |
| `recommendation.assessment-types.*` | Resource | `/recommendation/assessment-types` |

---

## 8. Models Inventory

| Model | Table | Key Relationships | Notes |
|---|---|---|---|
| `RecommendationRule` | `rec_recommendation_rules` | BelongsTo: RecTriggerEvent, RecommendationMode, SchoolClass, Subject, Topic, PerformanceCategory, RecAssessmentType, RecommendationMaterial (target), MaterialBundle (target), DynamicMaterialType, DynamicPurpose | Full SoftDeletes |
| `RecommendationMaterial` | `rec_recommendation_materials` | BelongsTo: Subject, SchoolClass, Topic, QuestionMediaStore (media), Dropdown (type/purpose/source), ComplexityLevel | Full SoftDeletes |
| `MaterialBundle` | `rec_material_bundles` | BelongsTo: Organization, User (creator). BelongsToMany: RecommendationMaterial via `rec_bundle_materials_jnt` | Full SoftDeletes |
| `BundleMaterialJnt` | `rec_bundle_materials_jnt` | Pivot: bundle_id, material_id, sequence_order, is_mandatory | Junction model |
| `StudentRecommendation` | `rec_student_recommendations` | BelongsTo: User (student), RecommendationRule, RecommendationMaterial, MaterialBundle, User (assignedBy) | Full SoftDeletes; UUID auto-generation on create; status lifecycle methods |
| `RecTriggerEvent` | `rec_trigger_events` | BelongsTo: User (creator), User (updater) | SoftDeletes |
| `RecommendationMode` | `rec_recommendation_modes` | Simple master | SoftDeletes |
| `DynamicMaterialType` | `rec_dynamic_material_types` | Simple master | SoftDeletes |
| `DynamicPurpose` | `rec_dynamic_purposes` | Simple master | SoftDeletes |
| `RecAssessmentType` | `rec_assessment_types` | Simple master | SoftDeletes |
| `PerformanceSnapshot` | (table unconfirmed) | Orphan model — no controller referencing it | Likely for future analytics |

---

## 9. Cross-Module Dependencies

| Dependency | Direction | Purpose |
|---|---|---|
| `SchoolSetup.SchoolClass` (`sch_classes`) | Consumed | Scope rules and materials to a class level |
| `SchoolSetup.Subject` (`sch_subjects`) | Consumed | Scope rules and materials to a subject |
| `Syllabus.Topic` (`slb_topics`) | Consumed | Scope rules and materials to a topic |
| `Syllabus.PerformanceCategory` (`slb_performance_categories`) | Consumed | Map performance bucket (POOR, AVERAGE, GOOD) to trigger rule |
| `Syllabus.ComplexityLevel` (`slb_complexity_levels`) | Consumed | Tag material difficulty |
| `QuestionBank.QuestionMediaStore` (`qns_media_store`) | Consumed | Store uploaded media files for materials |
| `LMS-Exam / LMS-Quiz` | Triggers | Exam/quiz result submission event fires rule engine |
| `StudentManagement.Student` (`std_students`) | Consumed | Recommendations are assigned to students |
| `GlobalMaster.Dropdown` (`sys_dropdown_table`) | Consumed | Material type, purpose, content source dropdowns |

---

## 10. Identified Gaps and Issues

### 10.1 Critical Issues

| Issue | Location | Impact |
|---|---|---|
| `Gate::any()` on `RecommendationController::tabIndex()` does not call `abort(403)` on failure — Gate::any returns boolean, not exception | `RecommendationController.php` | Users without any listed permission can still access the view |
| `StudentRecommendationController` uses `tenant.student-recommendation.create` permission on `edit()`, `update()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()` instead of the correct `.update` / `.delete` / `.restore` permissions | `StudentRecommendationController.php` | Any user with create permission can delete and restore recommendations |
| `RecommendationController::store()`, `update()`, `destroy()` are empty method bodies | `RecommendationController.php` | The main RecommendationController (dashboard entry point) cannot create/update/delete |
| `RecommendationMaterialController` has no `Gate::authorize()` on `create()`, `edit()`, `update()` methods | `RecommendationMaterialController.php` | Material creation and editing are unprotected |

### 10.2 Architecture Gaps

| Gap | Description | Priority |
|---|---|---|
| Zero service classes | All business logic inline in controllers. Rule engine, dynamic material resolution, and expiry job have no service layer | HIGH |
| Zero FormRequests | Only `StudentRecommendationController` and `RecommendationRuleController` use inline `$request->validate()`. `RecommendationMaterialController` uses a manual `Validator::make()` call. No FormRequest classes exist for any controller | HIGH |
| No rule engine service | The automated trigger pipeline (exam result → match rules → create student recommendations) is not implemented | HIGH |
| No expiry job | `rec_student_recommendations` with past `due_date` are never automatically marked EXPIRED | MEDIUM |
| Inconsistent permission naming | 4 different patterns used across controllers: `tenant.assessment-type.*`, `recommendation.tenant.assessment-type.*`, `recommendation.recommendation_materials.*`, `recommendation.material_bundles.*` | MEDIUM |
| `PerformanceSnapshot` model is an orphan | Model exists in `/Models/PerformanceSnapshot.php` but no controller or route references it | LOW |
| `MaterialBundle.school_id` discrepancy | DDL v1.4 does not define `school_id` on `rec_material_bundles`, but model and controller use it | LOW |

### 10.3 Missing Features (Not Yet Started)

| Feature | RBS Reference | Priority |
|---|---|---|
| Automated rule engine service (event-driven material dispatch) | U4 — Skill Gap Analysis | HIGH |
| Student portal view (see my recommendations) | U4.1.2, Student Portal | HIGH |
| Recommendation analytics dashboard (completion rates, popular materials) | U7.1 — AI Dashboards | MEDIUM |
| Batch expiry job (mark overdue recommendations as EXPIRED) | System Health | MEDIUM |
| Integration with LMS-Exam result event | U1.1.1 | HIGH |
| What-if scenario modeling | U7.2 | LOW |
| NLP sentiment analysis on student feedback text | U8 | LOW |

---

## 11. Permission Naming Convention (Target State)

All permissions in this module should follow the pattern `tenant.{resource}.{action}`:

```
tenant.recommendation-material.viewAny
tenant.recommendation-material.view
tenant.recommendation-material.create
tenant.recommendation-material.update
tenant.recommendation-material.delete
tenant.recommendation-material.restore
tenant.recommendation-material.forceDelete
tenant.material-bundle.viewAny
tenant.material-bundle.view
tenant.material-bundle.create
tenant.material-bundle.update
tenant.material-bundle.delete
tenant.material-bundle.restore
tenant.material-bundle.forceDelete
tenant.recommendation-rule.viewAny
tenant.recommendation-rule.view
tenant.recommendation-rule.create
tenant.recommendation-rule.update
tenant.recommendation-rule.delete
tenant.recommendation-rule.restore
tenant.recommendation-rule.forceDelete
tenant.student-recommendation.viewAny
tenant.student-recommendation.view
tenant.student-recommendation.create
tenant.student-recommendation.update
tenant.student-recommendation.delete
tenant.student-recommendation.restore
tenant.student-recommendation.forceDelete
tenant.trigger-event.viewAny
tenant.trigger-event.create
tenant.trigger-event.update
tenant.trigger-event.delete
tenant.trigger-event.restore
tenant.trigger-event.forceDelete
tenant.recommendation-mode.viewAny
tenant.recommendation-mode.create
tenant.recommendation-mode.update
tenant.recommendation-mode.delete
tenant.dynamic-material-type.viewAny
tenant.dynamic-material-type.create
tenant.dynamic-material-type.update
tenant.dynamic-material-type.delete
tenant.dynamic-purpose.viewAny
tenant.dynamic-purpose.create
tenant.dynamic-purpose.update
tenant.dynamic-purpose.delete
tenant.assessment-type.viewAny
tenant.assessment-type.create
tenant.assessment-type.update
tenant.assessment-type.delete
```

---

## 12. UI Screen Map

| Screen | URL Pattern | Controller Method |
|---|---|---|
| Recommendation Masters (Tab 1) | `/recommendation/recommendation-mgt` | `RecommendationController::tabIndex()` |
| Content & Rules (Tab 2) | `/recommendation/rec-material` | `RecommendationController::tabIndex_2()` |
| Materials Index | `/recommendation/recommendation-materials` | `RecommendationMaterialController::index()` |
| Materials Create | `/recommendation/recommendation-materials/create` | `RecommendationMaterialController::create()` |
| Bundle Index | `/recommendation/material-bundles` | `MaterialBundleController::index()` |
| Bundle Create | `/recommendation/material-bundles/create` | `MaterialBundleController::create()` |
| Rules Index | `/recommendation/recommendation-rules` | `RecommendationRuleController::index()` |
| Rules Create | `/recommendation/recommendation-rules/create` | `RecommendationRuleController::create()` |
| Student Recs Index | `/recommendation/student-recommendations` | `StudentRecommendationController::index()` |
| Student Recs Create | `/recommendation/student-recommendations/create` | `StudentRecommendationController::create()` |
| Trigger Events | `/recommendation/trigger-events` | `RecTriggerEventController::index()` |
| Modes | `/recommendation/recommendation-modes` | `RecommendationModeController::index()` |

---

## 13. Development Work Remaining

### Priority 1 — Security Fixes
1. Fix `Gate::any()` pattern in `RecommendationController::tabIndex()` — append `|| abort(403)`
2. Fix `StudentRecommendationController` permission strings (edit/update/destroy use `.create` incorrectly)
3. Add `Gate::authorize()` to `RecommendationMaterialController::create()`, `edit()`, `update()`
4. Standardize all permission names to `tenant.{resource}.{action}` convention

### Priority 2 — Architecture
5. Create `RecommendationService` with methods:
   - `processResult(ExamResult $result): Collection` — rule matching pipeline
   - `dispatchRecommendation(Student $student, Rule $rule, ExamResult $result): StudentRecommendation`
   - `resolveContent(Rule $rule, Student $student): array` — dynamic content resolution
   - `expireOverdue(): int` — batch mark expired
6. Create FormRequest classes:
   - `StoreRecommendationMaterialRequest`
   - `UpdateRecommendationMaterialRequest`
   - `StoreMaterialBundleRequest`
   - `UpdateMaterialBundleRequest`
7. Implement `RecommendationController::store()/update()/destroy()`

### Priority 3 — Features
8. Connect rule engine to LMS-Exam result submission event listener
9. Create `ExpireRecommendationsJob` (daily scheduled, marks overdue as EXPIRED)
10. Implement student portal view (student sees their pending recommendations)
11. Create recommendation analytics dashboard (completion %, popular materials, rule effectiveness)

---

## 14. Testing Requirements

### Unit Tests Needed
- `RecommendationRuleMatcherTest` — given a student score + trigger, correct rules are matched
- `DynamicContentResolverTest` — dynamic mode resolves correct materials by type/purpose/topic
- `StudentRecommendationLifecycleTest` — status transitions (viewed, in-progress, completed, expired)
- `OverdueDetectionTest` — is_overdue accessor returns correct values

### Feature Tests Needed
- Create recommendation rule → verify it is returned in correct rule queries
- Submit exam result → verify rule engine creates student recommendations
- Student views recommendation → verify `first_viewed_at` is set and status changes to VIEWED
- Expired batch job → verify overdue recommendations transition to EXPIRED

---

## 15. Completion Criteria

The module is considered complete when:

1. All CRUD operations for all 10 entities work correctly with proper auth
2. Permission naming is consistent across all controllers
3. Rule engine service processes exam results and dispatches recommendations automatically
4. Student portal shows pending/active recommendations with status update capability
5. Star rating and feedback can be submitted by students
6. Overdue expiry job runs nightly
7. Analytics dashboard shows: total assigned, completion rate, most recommended materials, rule trigger frequency
8. All FormRequest classes are implemented for input validation
9. Minimum 20 unit/feature tests covering core business logic
10. Zero empty stub methods in any controller
