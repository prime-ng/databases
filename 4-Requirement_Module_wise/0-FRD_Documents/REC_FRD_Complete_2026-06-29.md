# Recommendation Module — Complete Analysis Pack
**Module:** Recommendation (REC) | **Date:** 2026-06-29 | **Author:** pa-business-analyst
**Sources:** V2 Requirement Doc (2026-03-26) + V1 screen specs (9 files) + Live migrations (11 files) + Live code (`Modules/Recommendation/`) + modules-map.md

---

## Index / Table of Contents

| Section | Content |
|---------|---------|
| A | Functional Requirements Document (FRD) — 10 sections |
| B | Requirements Traceability Matrix (RTM) |
| C | Business Rules Register + Conditions Catalog + Validation Catalog |
| D | Process Flows + State Machine (FSM) Catalog |
| E | Data Dictionary + Cross-Module Dependency Map |
| F | Non-Functional Requirements Catalog + Risk Register |
| G | Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks |
| H | User Stories + Acceptance Criteria + Reporting & KPI Spec |
| I | Feature Specification (Screen-by-Screen) |

---

---

# SECTION A — Functional Requirements Document (FRD)

## 1. Module Overview

### 1.1 Purpose

The Recommendation module is Prime-AI's personalized learning guidance engine for Indian K-12 schools. It connects student performance data from LMS assessments (Quizzes and Quests) to a curated content library through a configurable rules engine, automatically surfacing the right learning material to the right student at the right time. Teachers can also manually assign recommendations regardless of system rules.

The module delivers a closed-loop remediation cycle: assessment taken → performance analysed → learning gap identified → targeted content assigned → student progresses → teacher reviews completion rates.

### 1.2 Business Value

- Replaces ad-hoc WhatsApp/verbal suggestions with a formal, trackable remediation process
- Reduces teacher effort in identifying and communicating follow-up actions after assessments
- Provides Counselors and Academic Coordinators with quantified data on which students are falling behind and how effectively recommended content is being completed
- Enables schools to build and reuse a structured content library aligned to Syllabus topics and performance categories

### 1.3 Scope

**In Scope:**
- Configuration of five lookup master tables (Trigger Events, Recommendation Modes, Material Types, Purposes, Assessment Types)
- A curated content library of individual learning materials (videos, PDFs, quiz links, HTML notes)
- Material bundles — ordered collections of materials as learning kits
- IF-THEN recommendation rules that map trigger conditions to content delivery
- Manual recommendation assignment by teachers
- Automated rule evaluation triggered by Quiz and Quest result publication events
- Full lifecycle tracking for each student-recommendation assignment (PENDING → COMPLETED/SKIPPED/EXPIRED)
- Student rating and feedback on completed recommendations
- Analytics dashboard for Counselors, Academic Coordinators, and Principals
- Nightly batch expiry of overdue recommendations
- Data isolated per school tenant (stancl/tenancy v3.9 database-per-tenant)
- Academic-year context: materials and rules scoped to class/subject/topic

**Out of Scope:**
- LmsExam (offline exam) result integration — engine currently triggers on Quiz/Quest only; Exam integration is future scope
- Attendance-based trigger (ON_ATTENDANCE_LOW defined in lookup but engine not wired to Attendance module)
- Parent Portal recommendation viewing (future)
- Gamification or point/badge system for completing recommendations
- Student Portal API endpoints (built separately in StudentPortal module; REC provides data)
- External content platform integrations (Google Classroom, Moodle LTI) — material URLs stored but no LTI launch
- PredictiveAnalytics (PAN) feed — future integration

### 1.4 Terminology

| Business Term | Meaning |
|---------------|---------|
| Trigger Event | A system event or schedule condition that activates the rule engine (e.g., "Assessment Result Submitted") |
| Recommendation Rule | An IF-THEN business logic record: WHEN [trigger] + IF [conditions: class/subject/topic/score range] THEN [recommend content] |
| Recommendation Mode | How content is selected: by a specific item, by a specific bundle, or dynamically by topic or competency |
| Learning Material | A single content item — video URL, PDF file, quiz link, HTML notes, or interactive resource |
| Material Bundle | An ordered, reusable collection of materials packaged as a single learning kit |
| Student Recommendation | The dispatched assignment record linking a specific student to specific content, with full lifecycle tracking |
| Performance Category | A score-band defined in the Syllabus module (e.g., Poor, Average, Good); used as a rule condition |
| Deduplication Window | A 30-day rolling period during which the same material is not recommended to the same student twice |
| Priority Bands | Content urgency computed from wrong-answer difficulty statistics: High (failed easy questions), Medium (failed moderate), Low (failed hard-only) |
| Expiry | Automatic transition to Expired status when a due date passes without the student completing or skipping |

---

## 2. User Roles and Access

### 2.1 Actors

| Actor | Description |
|-------|-------------|
| School Admin | Platform administrator for the school; configures all lookup masters; can view all recommendations |
| Subject Teacher | Creates and manages materials, bundles, and rules for their subjects; assigns manual recommendations; monitors their students' completion |
| Academic Coordinator / Counselor | Read-only or analytical view; monitors at-risk students; views analytics dashboard |
| Student | Views assigned recommendations; updates own status (viewed/in-progress/completed/skipped); submits star rating |
| System (Automated) | Event listener triggered by Quiz/Quest results; batch expiry job |

### 2.2 Role-Feature Matrix

| Feature | School Admin | Subject Teacher | Coordinator | Student |
|---------|:---:|:---:|:---:|:---:|
| Configure Trigger Events | Manage | View | View | — |
| Configure Recommendation Modes | Manage | View | View | — |
| Configure Material Types / Purposes / Assessment Types | Manage | View | View | — |
| Create / Edit Learning Materials | Manage | Manage (own) | View | — |
| Create / Edit Material Bundles | Manage | Manage | View | — |
| Author Recommendation Rules | Manage | Manage | View | — |
| Assign Recommendation Manually | Yes | Yes | — | — |
| View All Student Recommendations | Yes | Own class | Yes | Own only |
| Update Recommendation Status | Yes | Yes | — | Yes (own) |
| Submit Rating and Feedback | — | — | — | Yes |
| View Analytics Dashboard | Yes | Yes | Yes | — |
| Export Analytics CSV | Yes | — | Yes | — |
| Restore / Force-Delete Records | Yes | — | — | — |

---

## 3. Functional Requirements

### REQ-REC-001 — Configuration Masters Management
**Priority:** Core (P0) | **Tags:** [CONFIGURATION]
**Description:** School Admins manage five lookup master tables that control how the recommendation engine operates. Each master follows the same pattern: create, edit, soft-delete, restore, force-delete, and toggle active/inactive status. Unique name constraints prevent duplicate entries.

The five masters are:
- **Trigger Events** — event types that activate rule evaluation (seeded: Assessment Result Submitted, Topic Completed, Low Attendance, Manual Run, Scheduled Weekly)
- **Recommendation Modes** — delivery strategies (seeded: Specific Material, Specific Bundle, Dynamic by Topic, Dynamic by Competency)
- **Dynamic Material Types** — content format categories used in dynamic mode (seeded: Any Best Fit, Video, Quiz, PDF, Audio, Interactive)
- **Dynamic Purposes** — learning intent for dynamic mode (seeded: Remedial, Enrichment, Practice, Revision)
- **Assessment Types** — assessment filter categories for rules (seeded: All, Quiz, Weekly Test, Term Exam, Final Exam)

**Actors:** Initiates: School Admin | Processes: System | Views: Teacher, Coordinator
**Business Rules:** BR-REC-021 (unique name per master)
**Acceptance Criteria:**
- A new Trigger Event with duplicate name is rejected with a validation error
- Deactivated master entries no longer appear in rule creation dropdowns but retain historical data
- Soft-deleted entries appear in the Trash view and can be restored or permanently deleted
- Seeded values exist in every new tenant database after schema migration

---

### REQ-REC-002 — Learning Material Library
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY]
**Description:** Teachers and Admins build and maintain a library of learning content items. Each material is associated with a Class, Subject, and Topic (the academic scope), a Material Type (format), a Purpose (learning intent), and a Complexity Level. Content may be an uploaded file (PDF, video), an external URL (YouTube, Khan Academy), an HTML text note, or a reference to a stored media item.

Materials support tag-based discovery: a JSON tag field enables keyword searches that cut across the class/subject/topic hierarchy.

Full lifecycle: create, view, edit, soft-delete (Trash), restore, force-delete, toggle active/inactive.

**Actors:** Initiates: Teacher, Admin | Views: Teacher, Admin, Coordinator
**Business Rules:** BR-REC-022 (complexity level table name singular), BR-REC-023 (authorized create/edit)
**Acceptance Criteria:**
- A material must have at least a title, class, subject, and topic before it can be saved
- Complexity level dropdown draws from Syllabus module's complexity level list
- Material type dropdown draws from Dynamic Material Types master (not a global dropdown table)
- Purpose dropdown draws from Dynamic Purposes master
- Content source dropdown draws from system global dropdown (Internal Editor, Uploaded File, External Link, LMS Module, Question Bank)
- An inactive material is excluded from rule content resolution at dispatch time
- Soft-deleted materials appear in Trash; cascade-delete removes all bundle-material junction rows
- AJAX endpoints allow cascading Class → Subject → Topic selection in the form

---

### REQ-REC-003 — Material Bundle Management
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY]
**Description:** Teachers group individual materials into ordered, reusable bundles (learning kits). Each material in a bundle has a sequence position and a mandatory/optional flag. When a rule's delivery mode is "Specific Bundle", the entire bundle is recommended as a single unit.

Bundle-material assignments are managed atomically — adding or removing materials from a bundle executes inside a database transaction, with an AJAX endpoint to retrieve the current material list for display.

Full lifecycle: create, view, edit, soft-delete, restore, force-delete, toggle active/inactive.

**Actors:** Initiates: Teacher, Admin | Views: Teacher, Admin, Coordinator
**Business Rules:** BR-REC-015 (no duplicate material in bundle), BR-REC-016 (transaction wraps sync)
**Acceptance Criteria:**
- A bundle requires a title; description is optional
- Adding the same material to a bundle twice is rejected (unique bundle_id + material_id constraint)
- Removing a material from a bundle does not delete the material itself
- Sequence order is adjustable; materials display in sequence order when a student views the bundle
- Soft-deleting a bundle soft-deletes the junction rows but leaves the materials in the library

---

### REQ-REC-004 — Recommendation Rule Authoring
**Priority:** Core (P0) | **Tags:** [CONFIGURATION][WORKFLOW]
**Description:** Teachers and Admins define IF-THEN rules that control when and what content the system automatically recommends. Each rule specifies:
- **Trigger:** which trigger event activates it (e.g., Assessment Result Submitted)
- **Scope conditions (all optional = wildcard):** Class, Subject, Topic
- **Performance conditions (optional):** minimum score percentage, maximum score percentage, performance category
- **Assessment type filter (optional):** which type of assessment the result must be from (Quiz, Weekly Test, etc.)
- **Delivery:** Recommendation Mode + target content (specific material, specific bundle, or dynamic selection criteria)
- **Priority:** integer; when multiple rules match the same student+scope, the highest-priority rule fires first
- **Automated flag:** if unchecked, the rule is available for manual-assist only and never auto-fires

Full lifecycle: create, view, edit, soft-delete, restore, force-delete, toggle active/inactive. AJAX cascade for Class → Subject → Topic selection.

**Actors:** Initiates: Teacher, Admin | Views: Teacher, Coordinator
**Business Rules:** BR-REC-001 through BR-REC-009 (rule evaluation logic)
**Acceptance Criteria:**
- A rule with no scope conditions (all NULL) matches any student assessment
- A rule with min_score 0% and max_score 40% fires only when a student scores ≤ 40%
- Two rules matching the same scope: the higher-priority rule's content is dispatched first
- A rule with is_automated unchecked never appears in the automated engine's output
- Delivery mode "Dynamic by Topic" requires dynamic_material_type and dynamic_purpose fields
- Delivery mode "Specific Material" requires a target material selection
- Delivery mode "Specific Bundle" requires a target bundle selection

---

### REQ-REC-005 — Manual Recommendation Assignment
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY][WORKFLOW]
**Description:** A Teacher or Admin manually assigns a specific material or bundle to a specific student without waiting for an automated trigger. Manual assignments capture the assigning teacher, an optional reason, a priority level (Critical/High/Medium/Low), an optional due date, and whether the assignment links to an existing rule.

The assignment creates a Student Recommendation record with status PENDING and a system-generated UUID.

Full lifecycle: create, view, edit, soft-delete (Trash), restore, force-delete. Status can also be updated manually by teachers and admins (AJAX endpoint). Rating submitted by student.

**Actors:** Initiates: Teacher, Admin | Views: Teacher, Coordinator, Admin
**Business Rules:** BR-REC-011 (material OR bundle required), BR-REC-019 (UUID auto-generated), BR-REC-020 (permissions per action)
**Acceptance Criteria:**
- Saving a recommendation without selecting either a material or a bundle returns a validation error
- UUID is auto-generated on create and cannot be edited
- manual_assigned_by is set to the authenticated teacher's ID on store; NULL for automated
- Priority field defaults to Medium; all four levels (Critical/High/Medium/Low) are selectable
- Due date must be today or a future date
- Student dropdown shows only active students

---

### REQ-REC-006 — Recommendation Status Lifecycle
**Priority:** Core (P0) | **Tags:** [WORKFLOW]
**Description:** Each student recommendation moves through a defined status workflow. Students update their own recommendations via the Student Portal; teachers and admins update via the backend AJAX endpoint. The system auto-transitions PENDING/IN_PROGRESS records to EXPIRED when the due date passes.

Status sequence: Pending → Viewed → In Progress → Completed (or Skipped or Expired)
Administrative statuses: Cancelled (admin can cancel at any stage)

Key tracking fields:
- First Viewed At: timestamp set exactly once (on first PENDING → VIEWED transition)
- Completed At: timestamp set on COMPLETED transition
- Score Achieved: optional numeric score if the material was a quiz

**Actors:** Initiates: Student, Teacher, Admin, System | Processes: System
**Business Rules:** BR-REC-002 through BR-REC-010 (full FSM)
**Acceptance Criteria:**
- A COMPLETED recommendation cannot be moved to PENDING by any user
- first_viewed_at is set only once — subsequent VIEWED calls leave it unchanged
- Calling updateStatus() returns a JSON response (success + new status) for AJAX consumers
- A CANCELLED record is excluded from completion-rate calculations in the analytics dashboard
- Status badge colour changes in the UI to reflect current status

---

### REQ-REC-007 — Student Rating and Feedback
**Priority:** Standard (P1) | **Tags:** [DATA_ENTRY]
**Description:** After completing (or at any time for) a recommendation, a student submits a 1–5 star rating with optional text feedback. This data feeds the material effectiveness analytics.

**Actors:** Initiates: Student | Processes: System | Views: Teacher, Coordinator
**Business Rules:** BR-REC-017 (rating 1–5 required)
**Acceptance Criteria:**
- Rating below 1 or above 5 is rejected with a validation error
- Feedback is optional; max 255 characters
- Submitting a rating does not change the recommendation status
- A teacher can see the aggregate average rating per material on the analytics dashboard

---

### REQ-REC-008 — Tab Dashboard Views
**Priority:** Core (P0) | **Tags:** [DASHBOARD]
**Description:** Two aggregated dashboard pages provide at-a-glance access to all module data:
- **Masters Tab** — Trigger Events, Recommendation Modes, Material Types, Purposes, Assessment Types, and Rules Summary, all paginated (10 per page) with search and status filter
- **Content & Rules Tab** — Materials, Bundles, Rules, and Student Recommendations, all paginated with search and status filter; includes student and teacher filter dropdowns

Both tabs have a combined permission check: the user must hold at least one of the relevant viewAny permissions to access. The check must abort with a 403 if no permission is held.

**Actors:** Initiates: Teacher, Admin, Coordinator | Views: Same
**Business Rules:** BR-REC-018 (abort_unless Gate::any pattern)
**Acceptance Criteria:**
- A user with no recommendation permissions receives HTTP 403 on both tab pages
- Search field applies across all sub-tables on the active tab
- Status filter (Active/Inactive) applies across all sub-tables
- Paginated results on each sub-table maintain their own page state independently

---

### REQ-REC-009 — Automated Rule Evaluation Engine
**Priority:** Core (P0) | **Tags:** [WORKFLOW][INTEGRATION]
**Description:** When a Quiz or Quest result is published, the system automatically evaluates all active automated rules against the result and dispatches matching recommendations. The engine pipeline:

1. Identify the ON_ASSESSMENT_RESULT trigger event record
2. Resolve the assessment's class, subject, and representative topic (from first question's question bank entry)
3. Load wrong answers joined with question statistics (difficulty_index, discrimination_index)
4. Compute wrong-answer difficulty bands (Easy/Moderate/Hard) for priority scoring
5. Query matching active automated rules filtered by: trigger event, assessment type (or ALL), class/subject/topic (NULL = wildcard), score range, performance category
6. Post-filter: rules with a difficulty_band condition only fire if that band is present in wrong answers
7. For each matching rule (sorted by priority DESC): resolve content by mode; check deduplication; create Student Recommendation record

**Actors:** Initiates: System (event) | Processes: System | Views: Teacher, Coordinator
**Business Rules:** BR-REC-001 through BR-REC-009, BR-REC-012, BR-REC-013, BR-REC-014
**Acceptance Criteria:**
- Submitting a quiz result fires a QuizQuestResultPublished event that triggers rule evaluation
- A rule with NULL class_id matches students from any class
- When a student scores 35% and a rule has min_score 0% max_score 40%, the rule fires
- When a student scores 45% and a rule has min_score 0% max_score 40%, the rule does not fire
- Two rules matching the same scope: the higher-priority rule's content is dispatched first
- Deduplication: no second recommendation for the same student+material+quiz combination
- If target material is inactive at dispatch time, the rule is skipped

---

### REQ-REC-010 — Quiz and Quest Result Event Integration
**Priority:** Core (P0) | **Tags:** [INTEGRATION]
**Description:** The engine is wired to the `QuizQuestResultPublished` event. The event listener (`GenerateRecommendationsListener`) is registered in the module's EventServiceProvider. The listener calls the Recommendation Engine Service and logs outcomes. Errors in recommendation generation must never propagate to break the result-publication flow.

**Actors:** Initiates: System | Processes: System
**Business Rules:** BR-REC-025 (error isolation), BR-REC-026 (async requirement)
**Acceptance Criteria:**
- If rule evaluation throws an exception, it is caught and logged; the quiz/quest result publication succeeds regardless
- Recommendation records created include: student_id, rule_id, triggered_by_quiz_id or triggered_by_quest_id, material_id or bundle_id
- Log entry confirms how many recommendations were created per result event

---

### REQ-REC-011 — Batch Recommendation Expiry
**Priority:** Standard (P1) | **Tags:** [SCHEDULED]
**Description:** An Artisan command (`rec:expire-recommendations`) runs nightly (02:00 AM school timezone) and transitions all recommendations where due_date < today AND status IN (PENDING, IN_PROGRESS) to EXPIRED status. The command is idempotent (safe to run multiple times).

**Actors:** Initiates: System scheduler | Processes: System
**Business Rules:** BR-REC-027 (idempotency)
**Acceptance Criteria:**
- Running the command twice on the same day does not double-expire records
- Expired recommendations are excluded from the student's active recommendation list
- Command returns the count of records transitioned and logs it
- Command is registered in the Laravel task scheduler to run daily

---

### REQ-REC-012 — Recommendation Analytics Dashboard
**Priority:** Standard (P1) | **Tags:** [DASHBOARD][REPORT]
**Description:** A dedicated analytics page provides staff with aggregate insight into recommendation effectiveness. Metrics include: total assigned (all time / this month), completion rate (% COMPLETED of non-EXPIRED/CANCELLED), average student rating, top 10 most-assigned materials, rule effectiveness (trigger count → completion rate), and at-risk students (0 completions in last 30 days). Filters: date range, class, subject, teacher. Export to CSV.

**Actors:** Initiates: Admin, Coordinator | Views: Admin, Coordinator, Teacher
**Business Rules:** BR-REC-028 (CANCELLED excluded from completion rate)
**Acceptance Criteria:**
- Completion rate = (COMPLETED count / (total − EXPIRED − CANCELLED)) × 100
- At-risk list shows students with zero COMPLETED recommendations in the rolling 30-day window
- Filter by class narrows all metrics to that class's students
- CSV export includes all visible rows with headers

---

### REQ-REC-013 — Content Library Search and Filtering
**Priority:** Standard (P1) | **Tags:** [DATA_ENTRY]
**Description:** Materials and bundles can be searched by keyword (title, description, tags) and filtered by class, subject, topic, material type, and active/inactive status. Rules can be filtered by trigger event, class, subject, and active status.

**Actors:** Initiates: Teacher, Admin | Views: Same
**Acceptance Criteria:**
- Search by tag value returns materials whose JSON tags array contains the term
- Empty search returns all records (paginated)
- Inactive materials are excluded from rule-authoring dropdowns by default but visible when status filter = Inactive

---

### REQ-REC-014 — Authorization and Permission Enforcement
**Priority:** Core (P0) | **Tags:** [CONFIGURATION]
**Description:** Every controller action requires an explicit permission check using `tenant.{resource}.{action}` naming. The EnsureTenantHasModule:REC middleware must be applied to the route group. The Gate::any() pattern on tab index pages must abort with 403 if no permission is held. All mutations use validated request data from FormRequest classes.

Permission register (per resource: viewAny, view, create, update, delete, restore, forceDelete):
- trigger-event, recommendation-mode, dynamic-material-type, dynamic-purpose, assessment-type
- recommendation-material, material-bundle, recommendation-rule, student-recommendation
- recommendation-analytics (viewAny only)

**Actors:** Initiates: All authenticated users | Processes: System
**Business Rules:** BR-REC-018, BR-REC-019, BR-REC-023, BR-REC-024
**Acceptance Criteria:**
- A user without tenant.recommendation-material.create receives HTTP 403 on the material create form
- A user without tenant.student-recommendation.delete cannot soft-delete a recommendation
- A user without any recommendation permission receives HTTP 403 on both tab index pages
- The recommendation route group returns 403 if the tenant's plan does not include the REC module

---

## 4. Business Rules Register

| BR ID | Rule | Type | Trigger | Enforcement Point |
|-------|------|------|---------|-------------------|
| BR-REC-001 | When multiple rules match the same student+scope, the rule with the highest priority value fires first | Workflow | Rule engine evaluation | RecommendationEngineService — sort by priority DESC |
| BR-REC-002 | Only rules with Active status are evaluated by the engine | Validation | Rule query | Engine where is_active = true |
| BR-REC-003 | Only rules with the Automated flag enabled fire from the event system | Workflow | Rule query | Engine where is_automated = true |
| BR-REC-004 | NULL class, subject, or topic on a rule means the rule matches any value of that dimension | Workflow | Rule query | Engine whereNull OR where($column, $value) |
| BR-REC-005 | NULL assessment_type_id on a rule means the rule applies to any assessment type | Workflow | Rule query | Engine whereNull OR whereIn($assessmentTypeIds) |
| BR-REC-006 | Assessment Type "All" matches any assessment type in rule evaluation | Workflow | Assessment type resolution | Engine includes 'ALL' in the matching ID set |
| BR-REC-007 | Skip creating a recommendation if an identical (student + material/bundle + quiz/quest) combination already exists, regardless of status | Concurrency | Dispatch | Engine idempotency check before StudentRecommendation::create() |
| BR-REC-008 | Skip dispatch if the rule's target material is inactive at dispatch time | Validation | Dispatch | Engine pre-checks is_active on target material |
| BR-REC-009 | Each rule evaluation must complete within a DB transaction | Concurrency | Dispatch | DB::transaction() wraps all StudentRecommendation creates for one result |
| BR-REC-010 | PENDING is the only allowed initial status for a newly created recommendation | Validation | Store | Store controller defaults status = PENDING |
| BR-REC-011 | A Student Recommendation requires either a material or a bundle — both cannot be null | Validation | Store, Update | Controller validation + DB nullable FKs |
| BR-REC-012 | COMPLETED is a terminal status — no further status transitions are permitted | Workflow | Status update | updateStatus() must reject transitions from COMPLETED |
| BR-REC-013 | EXPIRED is a terminal status — no further transitions permitted | Workflow | Status update | updateStatus() must reject transitions from EXPIRED |
| BR-REC-014 | SKIPPED can be reopened to PENDING by an Admin only | Permission / Workflow | Status update | Gate check for admin-level permission before reopen |
| BR-REC-015 | first_viewed_at is set on the first PENDING → VIEWED transition only; immutable after | Calculation | markAsViewed() | Model method checks if first_viewed_at is null before setting |
| BR-REC-016 | completed_at is set on the COMPLETED transition and is immutable | Calculation | markAsCompleted() | Model method |
| BR-REC-017 | is_overdue = true when due_date < today AND status IN (PENDING, IN_PROGRESS) | Calculation | Computed accessor | StudentRecommendation model `is_overdue` accessor |
| BR-REC-018 | Student rating must be an integer from 1 to 5 inclusive; feedback is optional (max 255 chars) | Validation | addRating() | Controller validation / FormRequest |
| BR-REC-019 | Gate::any() return value must never be silently discarded — must be wrapped with abort_unless() | Permission | Tab index pages | RecommendationController tabIndex / tabIndex_2 |
| BR-REC-020 | All state-mutating controller methods must use $request->validated() from a FormRequest class, never $request->all() | Validation | All store/update methods | FormRequest authorize() + rules() |
| BR-REC-021 | Name fields on all five lookup master tables must be unique within the tenant | Validation | Master store/update | Database UNIQUE constraint + FormRequest unique rule |
| BR-REC-022 | A duplicate material in a bundle is rejected (unique constraint on bundle_id + material_id) | Validation | Bundle sync | DB unique index `uq_recBundleMat_rel` |
| BR-REC-023 | Bundle-material sync (add/remove/reorder materials in a bundle) must execute inside a DB transaction | Concurrency | Bundle store/update | MaterialBundleController DB::transaction() |
| BR-REC-024 | UUID is auto-generated by the system on StudentRecommendation creation; users cannot supply it | Calculation | Create | Model boot / Service::create() always supplies Str::uuid() |
| BR-REC-025 | Errors in recommendation generation must be caught and logged; they must never abort the triggering event (quiz result publication) | Workflow | GenerateRecommendationsListener | try/catch in listener handle(); error logged to Laravel Log |
| BR-REC-026 | The event listener should dispatch async (queued job) to avoid blocking the HTTP response [P1 open item — currently synchronous] | Performance | GenerateRecommendationsListener | [inferred from NFR-REC-07; not yet implemented] |
| BR-REC-027 | ExpireRecommendationsCommand must be idempotent — running it multiple times per day produces the same result | Reliability | Artisan command | Command queries status IN (PENDING, IN_PROGRESS) AND due_date < today; EXPIRED records skipped |
| BR-REC-028 | CANCELLED recommendations are excluded from completion-rate calculations | Calculation | Analytics queries | Dashboard queries exclude status = CANCELLED from denominators |
| BR-REC-029 | Priority computed from wrong-answer difficulty bands: failed Easy questions → High; failed Moderate → Medium; failed Hard only → Low; no statistics → Medium default | Calculation | RecommendationEngineService.computePriority() | Uses qns_question_statistics.difficulty_index: EASY ≥ 70, MODERATE 30–69, HARD < 30 |
| BR-REC-030 | Mis-keyed questions (discrimination_index < 0) are excluded from priority and difficulty-band computation | Calculation | RecommendationEngineService | Skip any answer row where discrimination_index < 0 |

---

## 5. Data Requirements

### 5.1 Entities and Privacy Classification

| Entity (Business Name) | Table | Key Fields | Privacy |
|------------------------|-------|------------|---------|
| Trigger Event | `rec_trigger_events` | event_name, description, is_active | Internal |
| Recommendation Mode | `rec_recommendation_modes` | mode_name, description, is_active | Internal |
| Dynamic Material Type | `rec_dynamic_material_types` | type_name, description, is_active | Internal |
| Dynamic Purpose | `rec_dynamic_purposes` | purpose_name, description, is_active | Internal |
| Assessment Type | `rec_assessment_types` | type_name, description, is_active | Internal |
| Learning Material | `rec_recommendation_materials` | title, description, material_type FK, purpose FK, complexity_level FK, content_source FK, content_text (HTML), file_url, external_url, media_id FK, subject_id, class_id, topic_id, competency_id, tags JSON, duration_seconds, language_code, created_by | Internal |
| Material Bundle | `rec_material_bundles` | title, description, is_active, created_by | Internal |
| Bundle-Material Junction | `rec_bundle_materials_jnt` | bundle_id, material_id, sequence_order, is_mandatory | Internal |
| Recommendation Rule | `rec_recommendation_rules` | name, trigger_event_id, class_id, subject_id, topic_id, performance_category_id, min_score_pct, max_score_pct, assessment_type_id, recommendation_mode_id, target_material_id, target_bundle_id, dynamic_material_type_id, dynamic_purpose_id, priority, is_automated, is_active | Internal |
| Student Recommendation | `rec_student_recommendations` | uuid, student_id, rule_id, triggered_by_quiz_id, triggered_by_quest_id, manual_assigned_by, material_id, bundle_id, recommendation_reason, priority, due_date, status, assigned_date, assigned_at, first_viewed_at, completed_at, score_achieved, student_rating, student_feedback, reassigned_quiz, reassigned_quiz_id | Confidential (student performance PII) |

**PII note:** `student_rating` and `student_feedback` are student-provided opinions about content quality — treat as Confidential per student data policy. `score_achieved` reflects individual performance — Confidential.

### 5.2 Academic-Year Scoping

Materials and rules are scoped via `class_id` and `subject_id` FKs into the school's current class/subject structure. Rules are authored per academic context. Student Recommendations carry `assigned_date` for time-based filtering. Counselors should filter the analytics dashboard by academic year via date range (no explicit academic_year_id column on recommendation tables — date filtering is the proxy).

### 5.3 Multi-Tenancy

All `rec_*` tables exist in each school's isolated tenant database. No `tenant_id` column is present or needed — the stancl/tenancy v3.9 bootstrapper switches the DB connection on every request. Cross-tenant data access is architecturally impossible.

---

## 6. Workflows

### Workflow 1 — Automated Recommendation Pipeline

**Trigger:** LMS module publishes a quiz or quest result
**End States:** Recommendations created (Student Recommendation records with status PENDING); or no action (no matching rules, or deduplication blocked)
**Actors:** System (event listener, engine service)

**Steps:**
1. [LMS Quiz/Quest] Teacher publishes result → `QuizQuestResultPublished` event fired with result record and publishRecommendation flag
2. [System] `GenerateRecommendationsListener::handle()` called → invokes `RecommendationEngineService::processResult()`
3. [System] Engine resolves student_id, assessment type, and assessment scope (class, subject, topic from first question)
4. [System] Engine loads wrong-answer records joined with question statistics (difficulty_index, discrimination_index)
5. [System] Engine computes wrong-answer difficulty bands; computes priority level
6. [System] Engine queries `rec_trigger_events` for ON_ASSESSMENT_RESULT trigger ID
7. [System] Engine queries matching active automated rules with scope and performance filters applied
8. [System] Engine post-filters: rules with difficulty_band set only fire if that band appears in wrong answers
9. [System] For each matching rule (priority DESC): resolve content by mode (Specific Material / Specific Bundle / Dynamic by Topic / Dynamic by Competency)
10. [System] Deduplication check: if (student + rule + quiz/quest) combination already exists, skip
11. [System] If target material is inactive, skip rule
12. [System] Create `rec_student_recommendations` record — status PENDING, priority from step 5
13. [System] Log how many recommendations were created; errors caught and logged without aborting

**Exception Paths:**
- ON_ASSESSMENT_RESULT trigger event not seeded → engine logs warning and returns empty (no crash)
- Rule matches but no content resolvable in Dynamic mode (no matching material in library) → rule skipped, logged
- DB insert fails → transaction rolls back; error logged; publishing flow unaffected

**Notifications Triggered:** None (future: NewRecommendationAssigned to student)

---

### Workflow 2 — Manual Recommendation Assignment

**Trigger:** Teacher navigates to Student Recommendations → Create
**End States:** Recommendation record created (status PENDING); or form returned with validation error
**Actors:** Teacher or Admin (Initiator), System (Processor)

**Steps:**
1. [Teacher] Navigates to Student Recommendations → Create
2. [System] Verifies tenant.student-recommendation.create permission → 403 if absent
3. [Teacher] Selects: Student, optional Rule, Material OR Bundle, Priority, optional Due Date, optional Reason, optional triggering Quiz/Quest
4. [System] FormRequest validates: student_id exists in std_students; material_id OR bundle_id required; priority valid; due_date ≥ today
5. [System] Creates StudentRecommendation with assigned_at = now(), manual_assigned_by = Auth ID, status = PENDING, uuid = Str::uuid()
6. [System] Calls activityLog() with created record and field details
7. [Teacher] Redirected to Content & Rules tab with success flash

**Exception Paths:**
- Neither material nor bundle selected → redirect back with "Either Material or Bundle must be selected" error on material_id field

---

### Workflow 3 — Student Recommendation Lifecycle

**Trigger:** Student views their pending recommendations (Student Portal or backend)
**End States:** COMPLETED (with optional score and rating); SKIPPED; EXPIRED (batch); CANCELLED (admin)
**Actors:** Student (status updater), System (expiry), Admin (cancel/reopen), Teacher (monitoring)

**Steps:**
1. [Student] Opens recommendation list → PENDING items visible
2. [Student/System] Opens a material → Teacher or student triggers VIEWED: first_viewed_at set (once only); status → VIEWED
3. [Student] Begins work on material → status → IN_PROGRESS
4. [Student] Finishes material → status → COMPLETED; completed_at set; optional score_achieved recorded
5. [Student] Optionally submits 1–5 star rating and text feedback → student_rating and student_feedback set; status unchanged
**OR**
4b. [Student] Dismisses without completing → status → SKIPPED
**OR**
4c. [System batch job] due_date < today AND status IN (PENDING, IN_PROGRESS) → status → EXPIRED

**Exception Paths:**
- Attempt to transition COMPLETED to any other status → rejected with 422 (invalid transition)
- Attempt to transition EXPIRED to any other status → rejected with 422

---

### Workflow 4 — Batch Expiry Job

**Trigger:** Nightly Laravel scheduler (02:00 AM)
**End States:** Overdue PENDING and IN_PROGRESS recommendations transitioned to EXPIRED
**Actors:** System

**Steps:**
1. [Scheduler] Triggers `rec:expire-recommendations` Artisan command
2. [System] Queries: status IN (PENDING, IN_PROGRESS) AND due_date < today AND deleted_at IS NULL
3. [System] For each record: calls markAsExpired(); calls activityLog()
4. [System] Logs "Expired {N} recommendations"; returns count

**Exception Paths:**
- No overdue records → command returns 0 without error
- DB error on update → logs error, continues to next record (partial run acceptable)

---

## 7. Reporting and Analytics

### RPT-REC-001 — Recommendation Analytics Dashboard
**Purpose:** Provide Counselors and Principals with an overall view of recommendation effectiveness
**Audience:** School Admin, Academic Coordinator, Counselor
**Frequency:** On demand
**Contents:** Total assigned (all time / this month), Completion Rate %, Average Student Rating, Top 10 Materials by Assignment Count, Rule Effectiveness table (rule name, trigger count, completion %), At-Risk Students list (0 completions in 30 days)
**Filters:** Date range (from/to), Class, Subject, Teacher
**Export:** CSV (all visible rows)
**Rules:** CANCELLED excluded from completion rate denominator; EXPIRED excluded from denominator; numerator = COMPLETED count

### RPT-REC-002 — At-Risk Student Report (sub-report of RPT-001)
**Purpose:** Identify students who have received recommendations but completed none in the past 30 days
**Audience:** Counselor, Admin
**Contents:** Student name, Class, Section, Count of pending recommendations, Count of overdue recommendations, Teacher assigned
**Filters:** Class, Section

### RPT-REC-003 — Rule Effectiveness Summary
**Purpose:** Show which rules are generating completions and which are being skipped or expired
**Audience:** Admin, Teacher (rule authors)
**Contents:** Rule name, trigger event, total recommendations fired, completion rate, skip rate, expiry rate, average rating of completed
**Filters:** Date range, trigger event type

### RPT-REC-004 — Material Popularity Report
**Purpose:** Show which materials are most frequently recommended and most highly rated
**Audience:** Admin, Coordinator
**Contents:** Material title, type, subject, class, assignment count, completion count, average rating, completion rate
**Export:** CSV

### RPT-REC-005 — Individual Student Recommendation History
**Purpose:** Show a single student's full recommendation timeline
**Audience:** Teacher, Admin, Counselor
**Contents:** Date assigned, material/bundle title, triggering event, rule name, priority, status, first viewed date, completed date, rating submitted
**Filters:** Student selection, date range, status

---

## 8. Future Enhancement Log

| ENH ID | Enhancement | Rationale | Target REQ |
|--------|-------------|-----------|-----------|
| ENH-REC-001 | Scheduled Weekly Batch Recommendations — weekly Artisan job evaluates ON_SCHEDULED_WEEKLY rules against rolling 4-week performance data per student | Proactive remediation without waiting for a specific assessment | REQ-REC-009 extension |
| ENH-REC-002 | Performance Snapshots table (`rec_performance_snapshots`) — pre-computed rolling average scores per student/subject/topic for DYNAMIC_BY_COMPETENCY mode | Full competency-gap resolution requires historical window | REQ-REC-009 |
| ENH-REC-003 | Notification integration — fire `NewRecommendationAssigned` event → NTF module sends in-app / SMS / email to student with material title, due date, priority | Student awareness without portal login | REQ-REC-005 |
| ENH-REC-004 | Bulk Recommendation Assignment — teacher selects multiple students from a class, assigns same material/bundle in one action | Post-exam class-wide remediation efficiency | REQ-REC-005 extension |
| ENH-REC-005 | Student Portal REST API — `GET /api/v1/recommendations`, `PATCH /api/v1/recommendations/{uuid}/status`, `POST /api/v1/recommendations/{uuid}/rate` | Enables Student Portal and Mobile apps to consume recommendations | REQ-REC-006 |
| ENH-REC-006 | Parent Portal read-only view of child's recommendations | Parent oversight of learning gap remediation | Cross-module |
| ENH-REC-007 | Content preview pane in material form — live HTML preview for content_text; iframe thumbnail for external_url | Improves teacher UX when authoring content | REQ-REC-002 |
| ENH-REC-008 | PredictiveAnalytics (PAN) feed integration — REC at-risk list populated from PAN risk scores instead of just 30-day inactivity | Predictive rather than reactive gap identification | REQ-REC-012 |

---

## 9. Non-Functional Requirements

### 9.1 Performance
- All list views paginated at 10 per page (default); both tab indexes load ≥5 paginated queries simultaneously — lazy tab loading recommended to avoid simultaneous DB hits
- Rule evaluation uses indexed queries: `idx_recRule_trigger` (trigger_event_id), `idx_recMat_scope` (class_id, subject_id, topic_id)
- The event listener must not block the HTTP response; dispatch as a queued job (currently synchronous — P1 gap)

### 9.2 Security
- All routes protected by EnsureTenantHasModule:REC middleware (currently missing — P0 gap)
- Every controller method has an explicit Gate::authorize() or abort_unless(Gate::any()) call
- Gate::any() return value must never be silently discarded
- All mutations use $request->validated() — never $request->all()
- Student Recommendation permanent deletion (forceDelete) restricted to Admin; cannot be triggered by anyone holding only CREATE permission

### 9.3 Usability
- AJAX cascade dropdowns: Class → Subject → Topic in material and rule forms avoid page reloads
- Status badges use colour coding: PENDING (grey), VIEWED (blue), IN_PROGRESS (yellow), COMPLETED (green), SKIPPED (orange), EXPIRED (red), CANCELLED (dark grey)
- Teachers see only materials relevant to their subjects (future: scope by teacher assignments)

---

## 10. Gap Analysis Readiness Index

### 10.1 Coverage Table

| REQ ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|--------|---------|----------|------|--------------------|---------------|-----------|---------------------|-----------------|
| REQ-REC-001 | Configuration Masters | P0 | [CONFIGURATION] | No (exists) | Yes | No | No | Yes |
| REQ-REC-002 | Learning Material Library | P0 | [DATA_ENTRY] | No (exists) | Yes | No | No | Yes |
| REQ-REC-003 | Material Bundle Management | P0 | [DATA_ENTRY] | No (exists) | Yes | No | No | Yes |
| REQ-REC-004 | Recommendation Rule Authoring | P0 | [CONFIGURATION][WORKFLOW] | No (exists) | Yes | No | No | Yes |
| REQ-REC-005 | Manual Assignment | P0 | [DATA_ENTRY][WORKFLOW] | No (exists) | Yes | No | No | Yes |
| REQ-REC-006 | Status Lifecycle | P0 | [WORKFLOW] | No (exists) | Yes | No | No | Yes |
| REQ-REC-007 | Student Rating & Feedback | P1 | [DATA_ENTRY] | No (exists) | Yes | No | No | Yes |
| REQ-REC-008 | Tab Dashboard Views | P0 | [DASHBOARD] | No (exists) | Yes | No | No | Yes |
| REQ-REC-009 | Automated Rule Engine | P0 | [WORKFLOW][INTEGRATION] | No (exists) | No | No | No | Yes |
| REQ-REC-010 | Event Integration | P0 | [INTEGRATION] | No (migration gaps) | No | No | No | Yes |
| REQ-REC-011 | Batch Expiry | P1 | [SCHEDULED] | No (exists) | No | No | No | Yes |
| REQ-REC-012 | Analytics Dashboard | P1 | [DASHBOARD][REPORT] | No | Yes | No | No | Yes |
| REQ-REC-013 | Content Search & Filtering | P1 | [DATA_ENTRY] | No | Yes | No | No | Yes |
| REQ-REC-014 | Authorization Enforcement | P0 | [CONFIGURATION] | No | No | No | No | Yes |

### 10.2 Business Rule Coverage

| BR ID | Implemented in Code | Gap Status |
|-------|---------------------|------------|
| BR-REC-001 | Yes — engine sorts by priority DESC | Done |
| BR-REC-002 | Yes — engine where is_active = true | Done |
| BR-REC-003 | Yes — engine where is_automated = true | Done |
| BR-REC-004 | Yes — whereNull OR where pattern | Done |
| BR-REC-005 | Yes — whereNull OR whereIn assessmentTypeIds | Done |
| BR-REC-006 | Yes — 'ALL' included in matching type IDs | Done |
| BR-REC-007 | Partial — deduplicates on (student+rule+quiz/quest); does NOT check material-level 30-day window | Gap |
| BR-REC-008 | Yes — engine checks is_active on target material | Done |
| BR-REC-009 | Yes — DB::transaction() wraps inserts | Done |
| BR-REC-010 | Yes — status defaults to PENDING on create | Done |
| BR-REC-011 | Yes — controller validates material_id OR bundle_id | Done |
| BR-REC-012 | Not implemented — no transition guard in updateStatus() | Gap (P1) |
| BR-REC-013 | Not implemented — no transition guard | Gap (P1) |
| BR-REC-014 | Not implemented — Admin reopen from SKIPPED | Gap (P2) |
| BR-REC-015 | Yes — markAsViewed() checks first_viewed_at null | Done |
| BR-REC-016 | Yes — markAsCompleted() sets completed_at | Done |
| BR-REC-017 | Yes — model accessor | Done |
| BR-REC-018 | Yes — controller validates 1–5 | Done |
| BR-REC-019 | Not fixed — Gate::any() return still discarded | Gap (P0) |
| BR-REC-020 | Partial — 18 FormRequests exist but some controllers re-validate inline | Gap (P1) |
| BR-REC-021 | Yes — DB UNIQUE constraints | Done |
| BR-REC-022 | Yes — DB UNIQUE on (bundle_id, material_id) | Done |
| BR-REC-023 | Yes — MaterialBundleController uses DB::transaction | Done |
| BR-REC-024 | Yes — engine/service sets Str::uuid() on create | Done |
| BR-REC-025 | Yes — listener wraps engine call in try/catch | Done |
| BR-REC-026 | Not implemented — listener is synchronous | Gap (P1) |
| BR-REC-027 | Not implemented — command not yet built | Gap (P1) |
| BR-REC-028 | Not implemented — dashboard not yet built | Gap (P1) |
| BR-REC-029 | Yes — computePriority() in RecommendationEngineService | Done |
| BR-REC-030 | Yes — mis-keyed check in computeWrongBands() and computePriority() | Done |

### 10.3 Report Coverage

| RPT ID | Report | Built | Gap |
|--------|--------|-------|-----|
| RPT-REC-001 | Analytics Dashboard | No | P1 gap |
| RPT-REC-002 | At-Risk Student Report | No | P1 gap |
| RPT-REC-003 | Rule Effectiveness | No | P1 gap |
| RPT-REC-004 | Material Popularity | No | P1 gap |
| RPT-REC-005 | Student Recommendation History | Partial (show view exists) | P1 gap — no aggregated report |

### 10.4 Totals

| Type | Count |
|------|-------|
| Functional Requirements (REQ-REC-) | 14 |
| Business Rules (BR-REC-) | 30 |
| Reports (RPT-REC-) | 5 |
| Enhancements (ENH-REC-) | 8 |
| P0 (Core / Must) | 10 REQs |
| P1 (Standard / Should) | 4 REQs |
| P2 (Enhanced / Could) | 0 REQs |

---

---

# SECTION B — Requirements Traceability Matrix (RTM)

| REQ ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | Code Status | P0 Security Gap |
|--------|---------|---------|-----------|----------|-----------|-------------|-----------------|
| REQ-REC-001 | Configuration Masters | BR-021 | SCR-01 to SCR-05 (masters sub-tabs) | — | — | PARTIAL (assessment-type permissions gap) | Yes — RecAssessmentTypePolicy missing |
| REQ-REC-002 | Learning Material Library | BR-022, BR-023 | SCR-06 (index), SCR-07 (create), SCR-08 (edit) | — | RPT-004 | PARTIAL (create/edit missing Gate::authorize) | Yes |
| REQ-REC-003 | Material Bundle Management | BR-015, BR-016 | SCR-09, SCR-10, SCR-11 | — | — | DONE | No |
| REQ-REC-004 | Recommendation Rule Authoring | BR-001 to BR-009 | SCR-12, SCR-13, SCR-14 | Wf-2 related | RPT-003 | DONE | No |
| REQ-REC-005 | Manual Assignment | BR-011, BR-019, BR-020 | SCR-15, SCR-16, SCR-17 | Workflow 2 | RPT-005 | PARTIAL (wrong permissions on 10 methods) | Yes — SEC-REC-002 |
| REQ-REC-006 | Status Lifecycle | BR-010 to BR-017 | SCR-16 (status AJAX), SCR-18 (trash) | Workflow 3 | RPT-005 | PARTIAL (no transition guard) | No |
| REQ-REC-007 | Student Rating | BR-018 | SCR-19 | — | RPT-001 | DONE | No |
| REQ-REC-008 | Tab Dashboard Views | BR-018, BR-019 | SCR-20 (tab 1), SCR-21 (tab 2) | — | — | PARTIAL (Gate::any discarded) | Yes — SEC-REC-001 |
| REQ-REC-009 | Automated Engine | BR-001 to BR-009, BR-012, BR-013, BR-014 | None (backend) | Workflow 1 | RPT-001, RPT-003 | DONE (engine fully built) | No |
| REQ-REC-010 | Event Integration | BR-025, BR-026 | None | Workflow 1 | — | PARTIAL (synchronous listener) | No |
| REQ-REC-011 | Batch Expiry | BR-027 | None | Workflow 4 | — | NOT BUILT | No |
| REQ-REC-012 | Analytics Dashboard | BR-028 | SCR-22 | — | RPT-001 to RPT-004 | NOT BUILT | No |
| REQ-REC-013 | Content Search | — | SCR-06, SCR-09, SCR-12, SCR-21 | — | — | PARTIAL (text search only; tag search limited) | No |
| REQ-REC-014 | Authorization | BR-018, BR-019, BR-020, BR-023, BR-024 | All screens | — | — | PARTIAL (multiple permission gaps) | Yes (multiple) |

---

---

# SECTION C — Business Rules Register + Conditions Catalog + Validation Catalog

## C.1 Conditions Catalog

(Reuses BR- IDs; each row = one enforceable condition)

| Condition (BR-) | Entity / Field | Condition Statement (Business) | Type | On-Violation |
|-----------------|----------------|-------------------------------|------|--------------|
| BR-REC-002 | Recommendation Rule / is_active | Only Active rules participate in automated evaluation | Workflow | Rule excluded from engine query |
| BR-REC-003 | Recommendation Rule / is_automated | Only Automated rules fire from events; non-automated rules are manual-assist only | Workflow | Rule excluded from engine query |
| BR-REC-007 | Student Recommendation | No duplicate (student + rule + quiz/quest) combination — skip dispatch | Concurrency | Record not created; engine continues to next rule |
| BR-REC-008 | Recommendation Rule / target_material_id | Target material must be Active at dispatch time | Validation | Rule skipped; logged |
| BR-REC-010 | Student Recommendation / status | Initial status must be PENDING | Validation | Store rejected if invalid status provided |
| BR-REC-011 | Student Recommendation / material_id + bundle_id | At least one of material or bundle must be selected | Validation | HTTP 302 back with error on material_id field |
| BR-REC-012 | Student Recommendation / status = COMPLETED | No further status transitions permitted | Workflow | 422 returned from updateStatus() |
| BR-REC-013 | Student Recommendation / status = EXPIRED | No further status transitions permitted | Workflow | 422 returned from updateStatus() |
| BR-REC-018 | Student Recommendation / student_rating | Rating must be integer 1–5 | Validation | 422 validation error |
| BR-REC-019 | RecommendationController / Gate::any() | Permission check result must never be silently discarded | Permission | 403 abort_unless() |
| BR-REC-021 | All master tables / name field | Name must be unique within the tenant | Validation | 422 with "already taken" error |
| BR-REC-022 | Bundle-Material Junction | Same material cannot appear in the same bundle more than once | Validation | DB unique constraint violation → 422 |
| BR-REC-029 | Student Recommendation / priority | Priority is computed from wrong-answer difficulty bands; teachers cannot override on automated dispatch | Calculation | System sets priority; manual creation allows override |

## C.2 Validation Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty/Null | Concurrency Case |
|---|---|---|---|---|---|
| trigger_event.event_name | "ON_ASSESSMENT_RESULT" | "ON ASSESSMENT RESULT" (spaces) | 50 chars max | Required — error | Two admins create same name → second rejected by UNIQUE constraint |
| recommendation_rule.min_score_pct | 0.00 | -1.00 | 0.00 and 100.00 | NULL = no lower bound | — |
| recommendation_rule.max_score_pct | 40.00 | 101.00 | 100.00 | NULL = no upper bound | — |
| recommendation_rule.priority | 10 | -1 or 0 | 1 minimum | Required, default 10 | — |
| recommendation_material.title | "Grade 5 Maths – Fractions Video" | Empty string | 255 chars | Required — error | — |
| recommendation_material.file_url | "https://cdn.school.com/file.pdf" | "ftp://files" | 500 chars | Nullable | — |
| recommendation_material.tags | `["fractions","grade5"]` | Non-JSON string | Any valid JSON array | Nullable | — |
| student_recommendation.due_date | Today + 7 days | Yesterday | Today (= valid) | Nullable | — |
| student_recommendation.student_rating | 3 | 0, 6, 3.5 | 1 and 5 | Nullable | Two rating submissions: last write wins |
| student_recommendation.status (update) | VIEWED from PENDING | PENDING from COMPLETED | — | Required | Two concurrent status updates: last write wins (no lock) |
| bundle_material junction | bundle_id=5, material_id=3 | Duplicate: bundle_id=5, material_id=3 again | — | Both FKs required | Concurrent add of same material: UNIQUE constraint rejects second |

---

---

# SECTION D — Process Flows + State Machine Catalog

## D.1 Process Flows

(Detailed step-by-step flows in Section A.6 Workflows — referenced here by name)

| Flow | Trigger | Sections |
|------|---------|---------|
| Automated Recommendation Pipeline | QuizQuestResultPublished event | A.6 Workflow 1 |
| Manual Recommendation Assignment | Teacher creates manual recommendation | A.6 Workflow 2 |
| Student Recommendation Lifecycle | Student opens/progresses through material | A.6 Workflow 3 |
| Batch Expiry Job | Nightly scheduler | A.6 Workflow 4 |

## D.2 State Machine Catalog — Student Recommendation Status

**Entity:** Student Recommendation (`rec_student_recommendations.status`)
**Backing:** ENUM column: CANCELLED, COMPLETED, EXPIRED, IN_PROGRESS, PENDING, SKIPPED, VIEWED

| From State | Event / Action | Guard (Condition) | To State | Side-Effects |
|------------|---------------|-------------------|----------|--------------|
| (New) | System dispatch or teacher assigns | — | PENDING | assigned_at set; UUID generated; activityLog |
| PENDING | Student opens material | first_viewed_at IS NULL | VIEWED | first_viewed_at = now(); activityLog |
| PENDING | Student dismisses | — | SKIPPED | activityLog |
| PENDING | due_date < today (batch job) | status in PENDING | EXPIRED | activityLog |
| PENDING | Admin cancels | Admin permission | CANCELLED | activityLog |
| VIEWED | Student begins work | — | IN_PROGRESS | activityLog |
| VIEWED | Student dismisses | — | SKIPPED | activityLog |
| VIEWED | due_date < today | status in IN_PROGRESS... (wrong — VIEWED not in batch guard) | EXPIRED [inferred] | activityLog |
| IN_PROGRESS | Student finishes | — | COMPLETED | completed_at = now(); optional score_achieved; activityLog |
| IN_PROGRESS | Student dismisses | — | SKIPPED | activityLog |
| IN_PROGRESS | due_date < today (batch job) | status in IN_PROGRESS | EXPIRED | activityLog |
| IN_PROGRESS | Admin cancels | Admin permission | CANCELLED | activityLog |
| COMPLETED | Student submits rating | — | COMPLETED (unchanged) | student_rating, student_feedback set |
| SKIPPED | Admin reopens | Admin permission | PENDING | activityLog |
| COMPLETED | Any transition attempt | — | REJECTED (422) | Terminal state |
| EXPIRED | Any transition attempt | — | REJECTED (422) | Terminal state |

**Terminal States:** COMPLETED, EXPIRED
**Illegal Transitions (must be blocked):** COMPLETED → any; EXPIRED → any
**Notes:**
- The live `updateStatus()` controller does not currently enforce terminal state blocking — this is Gap BR-REC-012/013 (P1)
- CANCELLED status is administrative; distinct from SKIPPED (student-initiated)

---

---

# SECTION E — Data Dictionary + Cross-Module Dependency Map

## E.1 Data Dictionary (Business View)

### Learning Material

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|
| Title | Short descriptive name for the material | Text (255) | Yes | Any | No |
| Description | Longer explanation of what the material covers | Text | No | Any | No |
| Material Type | Format of the content | Lookup → Dynamic Material Type | No | Video, PDF, Quiz, Audio, Interactive, Any Best Fit | No |
| Purpose | Learning intent of the material | Lookup → Dynamic Purpose | No | Remedial, Enrichment, Practice, Revision | No |
| Complexity Level | Difficulty relative to topic | Lookup → Syllabus complexity level | No | School-defined levels | No |
| Content Source | Where the content lives | Lookup → sys_dropdowns | No | Internal Editor, Uploaded File, External Link, LMS Module, Question Bank | No |
| Content Text | HTML-formatted notes or article | Long Text | No | Any HTML | No |
| File URL | Path to uploaded file (PDF, video) | URL (500) | No | Valid URL | No |
| External URL | External resource link | URL (500) | No | Valid URL | No |
| Media Reference | Stored media in Question Bank media store | Reference | No | Must exist in media store | No |
| Class | Target school class for this material | Lookup → School Class | Yes | Active school classes | No |
| Subject | Target subject | Lookup → School Subject | Yes | Active subjects | No |
| Topic | Syllabus topic this material addresses | Lookup → Syllabus topic | Yes | Active topics | No |
| Competency | Competency this material develops | Lookup → Syllabus competency | No | Active competencies | No |
| Duration (seconds) | Estimated time to consume material | Number | No | Positive integer | No |
| Language | Content language code | Code (10) | No | Default: en | No |
| Tags | Search/filter keywords | Tag list (JSON) | No | Any | No |
| Active | Whether material is available for rules and dispatch | Toggle | Yes | Active / Inactive | No |
| Created By | Staff member who created the material | Reference | No | System user | No |

### Student Recommendation

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|
| Student | The student receiving the recommendation | Reference | Yes | Active students | Yes |
| Assigned Date | Calendar date the recommendation was created | Date | Yes | Any date | No |
| Rule | The recommendation rule that generated this (null = manual) | Reference | No | Active rules | No |
| Material | The single content item recommended (or bundle below) | Reference | Conditional | Active materials | No |
| Bundle | The content bundle recommended (or material above) | Reference | Conditional | Active bundles | No |
| Reason | Why the recommendation was made | Text (255) | No | Any | No |
| Priority | Urgency level | Dropdown | Yes | Critical / High / Medium / Low | No |
| Due Date | Date by which the student should complete | Date | No | Today or future | No |
| Status | Current lifecycle position | Status | Yes | Pending / Viewed / In Progress / Completed / Skipped / Expired / Cancelled | No |
| Assigned By (Teacher) | Teacher who manually assigned (null if automated) | Reference | No | Active teachers | No |
| Triggered by Quiz | The quiz whose result triggered this (if automated) | Reference | No | LMS Quizzes | No |
| Triggered by Quest | The quest whose result triggered this (if automated) | Reference | No | LMS Quests | No |
| Reassigned Quiz | Whether a quiz was re-assigned as part of this recommendation | Toggle | No | Yes / No | No |
| First Viewed At | When student first opened the material | Timestamp | No | System-set | No |
| Completed At | When student marked as completed | Timestamp | No | System-set | No |
| Score Achieved | Student's score if material was a quiz | Decimal (%) | No | 0–100 | Yes |
| Student Rating | Student's 1–5 star rating | Integer | No | 1–5 | Yes |
| Student Feedback | Student's text comment on the material | Text (255) | No | Any | Yes |

## E.2 Cross-Module Dependency Map

### Inbound Dependencies (REC reads from)

| Source Module | Table(s) Consumed | Purpose |
|---|---|---|
| SchoolSetup | `sch_classes`, `sch_subjects`, `sch_teachers` | Scope rules and materials; manual_assigned_by teacher FK |
| Syllabus | `slb_topics`, `slb_performance_categories`, `slb_complexity_level`, `slb_competency_types` | Topic and competency scoping for materials and rules; performance-category triggers |
| QuestionBank | `qns_media_store`, `qns_question_statistics`, `qns_questions_bank`, `lms_quiz_quest_attempt_answers` | Media references; wrong-answer difficulty analysis (D31 statistics pattern) |
| StudentProfile | `std_students` | student_id FK for dispatched recommendations |
| LmsQuiz | `lms_quizzes`, `lms_quiz_questions`, `lms_quiz_quest_results`, `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers` | Trigger event source; quiz scope resolution; wrong-answer loading |
| LmsQuests | `lms_quests`, `lms_quest_questions` | Same as LmsQuiz for quest-type assessments |
| SystemConfig | `sys_dropdowns` | content_source dropdown values for materials |

### Outbound Dependencies (modules that consume REC data)

| Target Module | Data / Mechanism | What Is Provided |
|---|---|---|
| StudentPortal | `rec_student_recommendations` (direct table read + future API) | Student's pending, active, completed recommendations |
| ParentPortal | `rec_student_recommendations` (future) | Parent view of child's recommendations |
| Dashboard | Aggregate query on rec tables | Completion-rate widgets |
| Notification (NTF) | Future: `NewRecommendationAssigned` event | Push/email/SMS to student on assignment |

### Event Architecture

```
LmsQuiz / LmsQuests
    ↓  fires QuizQuestResultPublished (carries QuizQuestResult model + publishRecommendation flag)
Modules\Recommendation\Listeners\GenerateRecommendationsListener (synchronous — queued job needed)
    ↓  calls
Modules\Recommendation\Services\RecommendationEngineService::processResult()
    ↓  reads qns_question_statistics (D31)
    ↓  creates rec_student_recommendations rows
```

---

---

# SECTION F — NFR Catalog + Risk Register

## F.1 NFR Catalog

| NFR ID | Category | Requirement | Acceptance Threshold |
|--------|----------|-------------|----------------------|
| NFR-REC-001 | Security | All recommendation routes protected by EnsureTenantHasModule:REC middleware | 100% of routes; verified by HTTP 403 when module not licensed |
| NFR-REC-002 | Security | Every controller method has explicit Gate::authorize() or abort_unless(Gate::any()) | 0 methods without auth check |
| NFR-REC-003 | Security | Gate::any() return must never be silently discarded — always abort_unless() | 0 discarded return values |
| NFR-REC-004 | Security | All mutations use $request->validated() via FormRequest — never $request->all() | 0 unvalidated $request->all() in controller mutations |
| NFR-REC-005 | Performance | All list views paginated; default page size 10 | No unbounded queries in list views |
| NFR-REC-006 | Performance | Rule evaluation uses DB indexes: `idx_recRule_trigger`, `idx_recMat_scope` | EXPLAIN confirms index hit for engine queries on data set > 1000 rules |
| NFR-REC-007 | Performance | Event listener dispatches async (queued job) — must not block HTTP response | Listener converts to queued job; rule evaluation median < 50 ms offline |
| NFR-REC-008 | Reliability | ExpireRecommendationsCommand is idempotent — safe to run multiple times | Running twice in one day produces same result set |
| NFR-REC-009 | Reliability | DB::transaction() wraps bundle-material sync and recommendation insert loops | Zero partial-write states |
| NFR-REC-010 | Audit | activityLog() called on every create/update/delete/restore/forceDelete | 100% of mutating controller methods call activityLog() |
| NFR-REC-011 | Data Integrity | UUID auto-generated on StudentRecommendation creation; unique constraint enforced | Zero null or duplicate UUIDs |
| NFR-REC-012 | Maintainability | PerformanceSnapshot model absent from codebase if table not created | No orphan model files |
| NFR-REC-013 | Multi-Tenancy | All queries execute in the current tenant's DB context via stancl/tenancy v3.9 | Zero cross-tenant data leaks verified by tenancy bootstrapper |
| NFR-REC-014 | Usability | AJAX cascade dropdowns (Class → Subject → Topic) used in material and rule forms | Page-reload-free form selection verified by browser test |

## F.2 Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---------|------|----------|-----------|--------|-----------|-------|
| RISK-REC-001 | Gate::any() bypass allows any authenticated user to view all configuration and student recommendations | Security | H | H | Replace with abort_unless(); add test | Developer |
| RISK-REC-002 | Student Recommendation permanent delete accessible to anyone with CREATE permission — data destruction risk | Security | H | H | Fix permission string in all 10 methods immediately | Developer |
| RISK-REC-003 | Missing EnsureTenantHasModule:REC — schools that haven't licensed REC can access all its data | Security | M | H | Add middleware to route group | Developer |
| RISK-REC-004 | `triggered_by_result_id` and `is_published` silently dropped — audit trail incomplete | Data Integrity | H | M | Add columns via migration | DB Architect |
| RISK-REC-005 | Synchronous event listener blocks quiz result publish response for large rule sets | Performance | M | M | Convert to queued Job | Developer |
| RISK-REC-006 | No batch expiry command — overdue recommendations accumulate in PENDING/IN_PROGRESS permanently | Reliability | H | M | Build ExpireRecommendationsCommand | Developer |
| RISK-REC-007 | No status transition guard — COMPLETED → PENDING transition possible by anyone | Data Integrity | L | M | Add guard in updateStatus() | Developer |
| RISK-REC-008 | rec_material_bundles.school_id referenced in code but absent from DDL — silent data corruption | Data Integrity | M | L | Decide: add column or remove references | Developer |
| RISK-REC-009 | RecAssessmentTypePolicy missing — assessment-type resource has no policy enforcement | Security | M | M | Create policy class and register | Developer |
| RISK-REC-010 | 0 automated tests — security regressions and engine logic bugs will go undetected | Quality | H | H | Write 20+ unit + feature tests | Testing Architect |

---

---

# SECTION G — Prioritization + Effort Estimation & Sprint Tasks

## G.1 MoSCoW Prioritization

### Must (P0 — Production Blockers)
| REQ / Item | Rationale |
|------------|-----------|
| REQ-REC-001 Configuration Masters | Module cannot function without seeded masters |
| REQ-REC-002 Learning Material Library | Core content store |
| REQ-REC-003 Material Bundle Management | Required for SPECIFIC_BUNDLE mode |
| REQ-REC-004 Recommendation Rule Authoring | Engine depends on rules |
| REQ-REC-005 Manual Assignment | Primary teacher workflow |
| REQ-REC-006 Status Lifecycle | Student engagement tracking |
| REQ-REC-008 Tab Dashboard Views | Main entry point (with auth fix) |
| REQ-REC-009 Automated Engine | Core module value |
| REQ-REC-010 Event Integration | Trigger pipeline |
| REQ-REC-014 Authorization Enforcement | P0 security requirement |
| SEC-REC-001 Fix Gate::any() bypass | CRITICAL — any user can access |
| SEC-REC-002 Fix StudentRec wrong permissions | CRITICAL — create grants permanent delete |
| SEC-REC-003 Add EnsureTenantHasModule | HIGH — module unguarded |
| BUG-REC-001/002/003 Schema migrations | HIGH — silent data loss in engine |

### Should (P1 — High Business Value, Not Blocking)
| REQ / Item | Rationale |
|------------|-----------|
| REQ-REC-007 Student Rating | Closes the feedback loop |
| REQ-REC-011 Batch Expiry | Operational hygiene |
| REQ-REC-012 Analytics Dashboard | Counselor and coordinator value |
| REQ-REC-013 Content Search | UX quality |
| BR-REC-012/013 Status transition guards | Data integrity |
| BR-REC-026 Async listener | Performance |
| GAP-REC-001 RecAssessmentTypePolicy | Security |

### Could (P2 — Valuable but Deferrable)
| ENH / Item | Rationale |
|------------|-----------|
| ENH-REC-001 Scheduled weekly batch | Long-term personalization |
| ENH-REC-002 Performance snapshots | DYNAMIC_BY_COMPETENCY full support |
| ENH-REC-004 Bulk assignment | Teacher efficiency |
| ENH-REC-007 Content preview pane | Author UX |

### Won't (this release)
- ENH-REC-006 Parent Portal view
- ENH-REC-008 PAN integration
- LmsExam result trigger integration
- Attendance-based trigger (ON_ATTENDANCE_LOW wired)

## G.2 Effort Estimation & Sprint Task Breakdown

| # | Task | Type | REQ refs | Effort (h) | Depends on | Sprint |
|---|------|------|----------|-----------|------------|--------|
| T01 | Add schema columns to rec_student_recommendations: triggered_by_result_id, is_published, created_at | Schema | REQ-010 | 2 | — | Sprint 1 |
| T02 | Fix Gate::any() bypass in RecommendationController tabIndex + tabIndex_2 | Backend | REQ-014 | 2 | — | Sprint 1 |
| T03 | Fix StudentRecommendationController — 10 methods use wrong permission string | Backend | REQ-014 | 3 | — | Sprint 1 |
| T04 | Add EnsureTenantHasModule:REC to route group in RouteServiceProvider or web.php | Backend | REQ-014 | 1 | — | Sprint 1 |
| T05 | Create RecAssessmentTypePolicy; register in module ServiceProvider | Backend | REQ-001, REQ-014 | 2 | — | Sprint 1 |
| T06 | Add Gate::authorize() to RecommendationMaterialController create() and edit() methods | Backend | REQ-002, REQ-014 | 1 | — | Sprint 1 |
| T07 | Resolve rec_material_bundles.school_id: add migration or remove model/controller references | Schema + Backend | REQ-003 | 2 | T01 | Sprint 1 |
| T08 | Add status transition guard in StudentRecommendationController::updateStatus() (reject COMPLETED/EXPIRED → anything) | Backend | REQ-006 | 3 | T03 | Sprint 1 |
| T09 | Convert GenerateRecommendationsListener to dispatch a queued Job | Backend | REQ-010 | 4 | — | Sprint 2 |
| T10 | Write Artisan command `rec:expire-recommendations` and register in scheduler | Backend | REQ-011 | 6 | T01 | Sprint 2 |
| T11 | Build RecommendationAnalyticsController + dashboard view | Backend + Frontend | REQ-012 | 20 | T01, T08 | Sprint 3 |
| T12 | Build CSV export for analytics dashboard | Backend | REQ-012, RPT-001 | 4 | T11 | Sprint 3 |
| T13 | Build at-risk student list report sub-view | Frontend | RPT-002 | 4 | T11 | Sprint 3 |
| T14 | Build rule effectiveness sub-table | Frontend | RPT-003 | 3 | T11 | Sprint 3 |
| T15 | Write 10+ Pest unit tests: engine rule matching, priority computation, deduplication, lifecycle methods | Testing | REQ-009, REQ-006 | 12 | T01, T08 | Sprint 2 |
| T16 | Write 12+ Pest feature tests: auth (403), CRUD, bundle sync, expiry command, event dispatch | Testing | REQ-014, REQ-003, REQ-011 | 14 | T01 to T10 | Sprint 3 |
| T17 | Student Portal API endpoints (GET list, GET show, PATCH status, POST rate) | Backend | ENH-005 | 8 | T08 | Sprint 4 |
| T18 | Add tag-based JSON search to material index query | Backend | REQ-013 | 3 | — | Sprint 2 |
| T19 | Seed permission records (RecPermissionSeeder): all tenant.{resource}.{action} | Backend | REQ-014 | 3 | — | Sprint 1 |

**Sprint Summary:**
- Sprint 1 (P0 security + schema fixes): T01–T07, T19 — ~16 h
- Sprint 2 (engine hardening + tests): T08, T09, T10, T15, T18 — ~28 h
- Sprint 3 (analytics + tests): T11–T14, T16 — ~53 h
- Sprint 4 (enhancements): T17 and ENH items — variable

**Total estimated (P0 + P1):** ~97 h

---

---

# SECTION H — User Stories + Acceptance Criteria + Reporting & KPI Spec

## H.1 User Stories

### US-REC-001 | Priority: P0 | REQ ref: REQ-REC-009
**As a Subject Teacher**, I want the system to automatically recommend a remedial material to a student who scores below 40% in a topic quiz, so that I don't need to manually identify and communicate follow-up actions after every assessment.

**Acceptance Criteria:**
```
Scenario: Rule fires on low quiz score
  Given a rule: trigger=ON_ASSESSMENT_RESULT, subject=Mathematics, topic=Fractions, max_score=40%, mode=SPECIFIC_MATERIAL, target=Fractions Remedial PDF
  When a student scores 35% in a quiz on topic Fractions in Mathematics
  Then a Student Recommendation is created for that student with status PENDING and material = Fractions Remedial PDF

Scenario: Rule does not fire when score is above the threshold
  Given the same rule with max_score=40%
  When a student scores 45% in the same quiz
  Then no Student Recommendation is created

Scenario: Higher-priority rule wins
  Given two rules matching the same student+quiz+topic: Rule A (priority=20, material=X), Rule B (priority=5, material=Y)
  When the student scores 30%
  Then Rule A's material (X) is dispatched; Rule B is also dispatched (both fire independently)

Scenario: No matching rule
  Given no active automated rule matches the student's quiz scope
  When the quiz result is published
  Then zero Student Recommendations are created

Scenario: Deduplication
  Given a recommendation for student+rule+quiz already exists
  When the engine processes the same result again
  Then no duplicate recommendation is created
```

---

### US-REC-002 | Priority: P0 | REQ ref: REQ-REC-005
**As a Subject Teacher**, I want to manually assign a specific learning material to a struggling student, so that I can provide targeted support outside of the automated system.

**Acceptance Criteria:**
```
Scenario: Manual assignment success
  Given I hold the tenant.student-recommendation.create permission
  When I create a recommendation for Student A with material B, priority HIGH, due date 7 days from today
  Then a Student Recommendation record exists with status PENDING, manual_assigned_by = my teacher ID

Scenario: Missing material and bundle
  Given I submit the manual assignment form without selecting a material or bundle
  Then the form is returned with the error "Either Material or Bundle must be selected"

Scenario: Permission denied
  Given a user without tenant.student-recommendation.create
  When they navigate to the manual assignment form
  Then they receive HTTP 403
```

---

### US-REC-003 | Priority: P0 | REQ ref: REQ-REC-006
**As a Student** (via Student Portal), I want to mark a recommended material as completed, so that my teacher can see I have addressed the learning gap.

**Acceptance Criteria:**
```
Scenario: Student completes a recommendation
  Given my recommendation is in IN_PROGRESS status
  When I call the mark-completed action
  Then status changes to COMPLETED, completed_at is set to now, and first_viewed_at remains unchanged

Scenario: Terminal state block
  Given my recommendation is COMPLETED
  When the update-status endpoint is called with status=PENDING
  Then HTTP 422 is returned with an error "Cannot transition from COMPLETED status"

Scenario: first_viewed_at immutability
  Given first_viewed_at is already set
  When markAsViewed() is called again
  Then first_viewed_at is unchanged
```

---

### US-REC-004 | Priority: P0 | REQ ref: REQ-REC-014
**As a School Admin**, I want all recommendation actions to require the correct permission, so that teachers cannot permanently delete records they are only allowed to view.

**Acceptance Criteria:**
```
Scenario: Create permission does not grant delete
  Given a user holds only tenant.student-recommendation.create
  When they attempt to force-delete a Student Recommendation
  Then HTTP 403 is returned

Scenario: Gate::any bypass is closed
  Given a user holds no recommendation permissions
  When they navigate to the Masters tab dashboard
  Then HTTP 403 is returned

Scenario: Module middleware
  Given the school's plan does not include the REC module
  When any recommendation URL is accessed
  Then HTTP 403 is returned
```

---

### US-REC-005 | Priority: P1 | REQ ref: REQ-REC-012
**As a Counselor**, I want to view a dashboard showing which students have completed zero recommendations in the past 30 days, so that I can follow up with their teachers.

**Acceptance Criteria:**
```
Scenario: At-risk student list
  Given Student X has 5 PENDING recommendations in the last 30 days and 0 COMPLETED
  When I open the Analytics Dashboard and view the At-Risk Students panel
  Then Student X appears in the list with count of pending recommendations

Scenario: Completion rate
  Given 100 recommendations total, 20 EXPIRED, 5 CANCELLED, 30 COMPLETED
  When I view the completion rate metric
  Then completion rate = 30 / (100 - 20 - 5) × 100 = 40%

Scenario: CSV export
  When I click Export CSV on the analytics dashboard
  Then a CSV file downloads with all visible rows and column headers
```

---

### US-REC-006 | Priority: P1 | REQ ref: REQ-REC-007
**As a Student**, I want to rate a completed recommendation with 1–5 stars, so that teachers know whether the material was helpful.

**Acceptance Criteria:**
```
Scenario: Valid rating
  Given my recommendation is COMPLETED
  When I submit a rating of 4 stars with feedback "Very helpful"
  Then student_rating = 4, student_feedback = "Very helpful", status unchanged

Scenario: Invalid rating value
  When I submit a rating of 0 or 6
  Then HTTP 422 validation error returned

Scenario: Rating without feedback
  When I submit a rating of 3 with no feedback
  Then rating is saved; feedback field remains null
```

---

## H.2 Reporting and KPI Spec

| KPI | Definition / Formula | Source Data | Target | Cadence |
|-----|----------------------|-------------|--------|---------|
| Recommendation Completion Rate | COMPLETED count / (total − EXPIRED − CANCELLED) × 100 | rec_student_recommendations | ≥ 60% | Weekly |
| Average Student Rating | SUM(student_rating) / COUNT(rated records) | rec_student_recommendations where student_rating IS NOT NULL | ≥ 3.5 stars | Monthly |
| Time to First View (median) | MEDIAN(first_viewed_at − assigned_at) in hours | rec_student_recommendations where first_viewed_at IS NOT NULL | ≤ 48 hours | Weekly |
| At-Risk Student Rate | Students with 0 COMPLETED recs in last 30 days / total students with ≥ 1 recommendation × 100 | rec_student_recommendations joined std_students | ≤ 15% | Monthly |
| Rule Firing Rate | Count of automated dispatches / Count of quiz/quest results published | rec_student_recommendations where rule_id IS NOT NULL | Track trend | Weekly |
| Material Completion Rate (per material) | COMPLETED count for material / total assigned for material × 100 | Per material aggregation | Track per material | Monthly |

---

---

# SECTION I — Feature Specification (Screen-by-Screen)

## Screen SCR-01 — Masters Tab Dashboard (`/recommendation/recommendation-mgt`)

**Purpose:** Single-page view of all five lookup master tables + recommendation rules summary
**Controller Method:** `RecommendationController::tabIndex()`
**Permission:** abort_unless(Gate::any(['tenant.assessment-type.viewAny', 'tenant.dynamic-material.viewAny', 'tenant.dynamic-purpose.viewAny', 'tenant.recommendation-mode.viewAny', 'tenant.trigger-events.viewAny']), 403)
**Layout:** Tabbed or accordion; each master in its own card; rules in a summary card

| # | Field / Element | Type | Notes |
|---|---|---|---|
| 1 | Search box | Text | Applies to currently active master tab |
| 2 | Status filter | Dropdown: Active / Inactive / All | Applies to current master |
| 3 | Trigger Events table | Paginated list (10/page) | event_name, description, is_active badge, actions |
| 4 | Recommendation Modes table | Paginated list | mode_name, description, is_active badge, actions |
| 5 | Dynamic Material Types table | Paginated list | type_name, description, is_active badge, actions |
| 6 | Dynamic Purposes table | Paginated list | purpose_name, description, is_active badge, actions |
| 7 | Assessment Types table | Paginated list | type_name, description, is_active badge, actions |
| 8 | Rules summary table | Paginated list | rule name, trigger event, mode, is_active |

**Actions per master row:** View, Edit, Toggle Active, Soft-Delete
**Empty state:** "No [Master Name] configured yet. Create the first one."

---

## Screen SCR-06 — Learning Materials Index

**Purpose:** Browse and manage the content library
**Controller Method:** `RecommendationMaterialController::index()`
**Permission:** `tenant.recommendation-material.viewAny`

| # | Field | Type | Notes |
|---|---|---|---|
| 1 | Search | Text | Searches title, description |
| 2 | Class filter | Dropdown | Cascades to Subject |
| 3 | Subject filter | Dropdown | Cascades to Topic |
| 4 | Topic filter | Dropdown | |
| 5 | Material Type filter | Dropdown | From Dynamic Material Types |
| 6 | Status filter | Dropdown | Active / Inactive |
| 7 | Materials table | Paginated (10/page) | Title, Class, Subject, Topic, Type, Purpose, Active badge, Duration |
| 8 | Create Material button | Button | → SCR-07 |
| 9 | Trash link | Link | → trash view |

---

## Screen SCR-07 — Material Create / Edit

**Purpose:** Author a new learning content item
**Permission:** `tenant.recommendation-material.create` / `.update`

| # | Field (Business Label) | Type | Required | Validation | Notes |
|---|---|---|---|---|---|
| 1 | Title | Text (255) | Yes | Max 255 | — |
| 2 | Description | Textarea | No | — | — |
| 3 | Class | Dropdown (AJAX) | Yes | Exists in sch_classes | Triggers Subject AJAX load |
| 4 | Subject | Dropdown (AJAX) | Yes | Exists in sch_subjects | Triggers Topic AJAX load |
| 5 | Topic | Dropdown (AJAX) | Yes | Exists in slb_topics | — |
| 6 | Material Type | Dropdown | No | Exists in rec_dynamic_material_types | — |
| 7 | Purpose | Dropdown | No | Exists in rec_dynamic_purposes | — |
| 8 | Complexity Level | Dropdown | No | Exists in slb_complexity_level (singular) | — |
| 9 | Content Source | Dropdown | No | Exists in sys_dropdowns | Internal Editor, Uploaded File, External Link, LMS Module, Question Bank |
| 10 | Content Text | Rich Text (HTML) | No | — | Shown when source = Internal Editor |
| 11 | File URL | Text (500) | No | Valid URL | Shown when source = Uploaded File |
| 12 | External URL | Text (500) | No | Valid URL | Shown when source = External Link |
| 13 | Duration (minutes) | Number | No | Positive | Stored in seconds internally |
| 14 | Language | Text (10) | No | Default en | — |
| 15 | Tags | Tag input | No | JSON array | Comma-separated; stored as JSON |
| 16 | Active | Toggle | No | Boolean | Default on |

**Actions:** Save, Cancel
**Success redirect:** Materials index with success flash

---

## Screen SCR-09 — Material Bundle Index / SCR-10 — Bundle Create / SCR-11 — Bundle Edit

**Purpose:** Manage ordered collections of materials
**Permission:** `tenant.material-bundle.viewAny` / `.create` / `.update`

Bundle form fields:
| # | Field | Type | Required | Validation |
|---|---|---|---|---|
| 1 | Title | Text (255) | Yes | Max 255 |
| 2 | Description | Textarea | No | — |
| 3 | Active | Toggle | No | Boolean |
| 4 | Materials in Bundle | Multi-select with sequence order | Conditional | At least 0 materials (bundle can be empty initially) |
| 5 | Mandatory flag per material | Checkbox | No | Per row |

AJAX endpoint: `/recommendation/ajax-recommendation-materials` — returns active materials for selection.

---

## Screen SCR-12 — Rules Index / SCR-13 — Rule Create / SCR-14 — Rule Edit

**Purpose:** Author IF-THEN recommendation rules
**Permission:** `tenant.recommendation-rule.viewAny` / `.create` / `.update`

Rule form fields (key fields):
| # | Field | Type | Required | Validation | Notes |
|---|---|---|---|---|---|
| 1 | Rule Name | Text (150) | Yes | Max 150 | — |
| 2 | Trigger Event | Dropdown | Yes | Exists in rec_trigger_events | — |
| 3 | Automated | Toggle | No | Boolean | Default on |
| 4 | Class | Dropdown (AJAX) | No | Exists in sch_classes | NULL = any |
| 5 | Subject | Dropdown (AJAX) | No | Exists in sch_subjects | NULL = any |
| 6 | Topic | Dropdown (AJAX, from Lessons) | No | Exists in slb_topics | NULL = any |
| 7 | Minimum Score % | Decimal | No | 0–100 | NULL = no lower bound |
| 8 | Maximum Score % | Decimal | No | 0–100 | NULL = no upper bound |
| 9 | Performance Category | Dropdown | No | Exists in slb_performance_categories | NULL = any |
| 10 | Assessment Type | Dropdown | No | Exists in rec_assessment_types | NULL = any |
| 11 | Priority | Number | No | Positive integer | Default 10 |
| 12 | Recommendation Mode | Dropdown | Yes | Exists in rec_recommendation_modes | Controls which target fields are shown |
| 13 | Target Material | Dropdown | Conditional | Exists in rec_recommendation_materials | Shown when mode=SPECIFIC_MATERIAL |
| 14 | Target Bundle | Dropdown | Conditional | Exists in rec_material_bundles | Shown when mode=SPECIFIC_BUNDLE |
| 15 | Dynamic Material Type | Dropdown | Conditional | Exists in rec_dynamic_material_types | Shown when mode=DYNAMIC_BY_TOPIC or BY_COMPETENCY |
| 16 | Dynamic Purpose | Dropdown | Conditional | Exists in rec_dynamic_purposes | Shown when mode=DYNAMIC_BY_TOPIC or BY_COMPETENCY |
| 17 | Active | Toggle | No | Boolean | Default on |

---

## Screen SCR-15 — Student Recommendations Index / SCR-16 — Create / SCR-17 — Show

**Purpose:** Manual recommendation management
**Permission:** `tenant.student-recommendation.viewAny` / `.create` / `.view`

(Index redirects to Content & Rules tab with `?tab=student-recommendations` query parameter.)

Create form key fields:
| # | Field | Type | Required | Validation |
|---|---|---|---|---|
| 1 | Student | Dropdown | Yes | Exists in std_students, is_active |
| 2 | Rule (optional) | Dropdown | No | Exists in rec_recommendation_rules |
| 3 | Material OR Bundle | Two dropdowns | Conditional | At least one required |
| 4 | Assigned Date | Date | Yes | Valid date |
| 5 | Priority | Dropdown | Yes | Critical / High / Medium / Low |
| 6 | Due Date | Date | No | ≥ today |
| 7 | Reason | Text (255) | No | — |
| 8 | Manual Assigned By | Dropdown | No | sch_teachers |
| 9 | Status | Dropdown | Yes | Default PENDING |

---

## Screen SCR-22 — Analytics Dashboard (`/recommendation/analytics`)

**Purpose:** Recommendation effectiveness overview for Counselors and Admins
**Permission:** `tenant.recommendation-analytics.viewAny`
**Status:** NOT BUILT (P1 gap)

Proposed layout:
- KPI cards row: Total Assigned (this month), Completion Rate %, Average Rating, At-Risk Student Count
- Date range + Class + Subject + Teacher filters
- Materials table: Top 10 by assignment count + completion rate + average rating
- Rule effectiveness table: rule name, fires, completion %
- At-Risk Students list: paginated, sortable by pending count
- Export CSV button

---

*End of Complete Analysis Pack for Recommendation (REC)*
*File: REC_FRD_Complete_2026-06-29.md*
*Module Knowledge: AI_Brain/module-knowledge/REC_Recommendation.md*
