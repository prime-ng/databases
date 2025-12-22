# Syllabus & Exam Management Module v2.0 - Data Dictionary

## Overview

This document provides a complete breakdown of every table and column in the enhanced Syllabus & Exam Management module. The schema is organized into 6 logical files covering:

1. **Core Hierarchy Structure** - Lessons, Topics with Materialized Path, Competencies
2. **Question Bank** - NEP 2020 compliant question management
3. **Assessment Engine** - Quizzes, Assessments, Exams with auto-assignment
4. **Student Attempts** - Granular behavioral tracking
5. **Analytics & Recommendations** - Learning outcomes and gap analysis
6. **Summary Tables & Views** - Pre-aggregated reporting data

---

## File 1: Core Hierarchy Structure

### Table: `slb_lessons`
**Purpose:** Stores lesson/chapter information for each class-subject combination.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key, auto-increment |
| `uuid` | CHAR(36) | NO | Unique identifier for analytics tracking |
| `academic_session_id` | BIGINT UNSIGNED | NO | FK to sch_org_academic_sessions_jnt |
| `class_id` | INT UNSIGNED | NO | FK to sch_classes |
| `subject_id` | BIGINT UNSIGNED | NO | FK to sch_subjects |
| `code` | VARCHAR(20) | NO | Auto-generated code (e.g., '9TH_SCI_L01') |
| `name` | VARCHAR(150) | NO | Full lesson name (e.g., 'Chapter 1: Matter') |
| `short_name` | VARCHAR(50) | YES | Abbreviated name for display |
| `ordinal` | SMALLINT UNSIGNED | NO | Sequence order within subject |
| `description` | TEXT | YES | Detailed lesson description |
| `learning_objectives` | JSON | YES | Array of learning objectives |
| `prerequisites` | JSON | YES | Array of prerequisite lesson IDs |
| `estimated_periods` | SMALLINT UNSIGNED | YES | Number of periods to complete |
| `weightage_percent` | DECIMAL(5,2) | YES | Weightage in final exam (e.g., 8.5%) |
| `nep_alignment` | VARCHAR(100) | YES | NEP 2020 framework reference code |
| `resources_json` | JSON | YES | Array of [{type, url, title}] |
| `is_active` | TINYINT(1) | NO | Soft active flag (default: 1) |
| `created_by` | BIGINT UNSIGNED | YES | User who created the record |
| `updated_by` | BIGINT UNSIGNED | YES | User who last updated |
| `created_at` | TIMESTAMP | YES | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | Soft delete timestamp |

---

### Table: `slb_topics`
**Purpose:** Hierarchical topics using Materialized Path for unlimited nesting (Topic → Sub-topic → Mini Topic → etc.)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `uuid` | CHAR(36) | NO | Unique analytics identifier |
| `parent_id` | BIGINT UNSIGNED | YES | FK to self (NULL for root topics) |
| `lesson_id` | BIGINT UNSIGNED | NO | FK to syl_lessons |
| `class_id` | INT UNSIGNED | NO | Denormalized for fast queries |
| `subject_id` | BIGINT UNSIGNED | NO | Denormalized for fast queries |
| `path` | VARCHAR(500) | NO | Materialized path (e.g., '/1/5/23/') |
| `path_names` | VARCHAR(2000) | YES | Human-readable path (e.g., 'Algebra > Equations') |
| `level` | TINYINT UNSIGNED | NO | Depth in hierarchy (0=root topic) |
| `level_name` | VARCHAR(50) | NO | Human name ('Topic', 'Sub-topic', etc.) |
| `code` | VARCHAR(30) | NO | Unique code (e.g., '9TH_SCI_L01_T01_ST02') |
| `name` | VARCHAR(200) | NO | Topic name |
| `short_name` | VARCHAR(50) | YES | Abbreviated name |
| `ordinal` | SMALLINT UNSIGNED | NO | Order within parent |
| `description` | VARCHAR(255) | YES | Detailed description |
| `duration_minutes` | INT UNSIGNED | YES | Estimated teaching time |
| `learning_objectives` | JSON | YES | Array of objectives |
| `keywords` | JSON | YES | Search keywords array |
| `prerequisite_topic_ids` | JSON | YES | Dependency tracking |
| `analytics_code` | VARCHAR(60) | NO | Unique code for analytics tracking |
| `is_active` | TINYINT(1) | NO | Active flag |
| `created_by` | BIGINT UNSIGNED | YES | Creator user ID |
| `updated_by` | BIGINT UNSIGNED | YES | Last updater user ID |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |
| `deleted_at` | TIMESTAMP | YES | Soft delete timestamp |

**Materialized Path Usage:**
- Path format: `/ancestor1_id/ancestor2_id/parent_id/`
- To find all descendants of topic ID 5: `WHERE path LIKE '/5/%'`
- To find all ancestors: Parse the path string
- Level 0 = Topic, Level 1 = Sub-topic, Level 2 = Mini Topic, etc.

---

### Table: `slb_competency_types`
**Purpose:** Reference table defining competency types.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | INT UNSIGNED | NO | Primary key |
| `code` | VARCHAR(20) | NO | Code ('TOPIC', 'SUB_TOPIC', etc.) |
| `name` | VARCHAR(100) | NO | Display name |
| `description` | VARCHAR(255) | YES | Level description |
| `is_active` | TINYINT(1) | NO | Active flag |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `slb_competencies`
**Purpose:** NEP 2020 aligned competency framework with hierarchical sub-competencies.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `uuid` | CHAR(36) | NO | Unique identifier |
| `parent_id` | BIGINT UNSIGNED | YES | FK to self for sub-competencies |
| `code` | VARCHAR(50) | NO | Competency code (e.g., 'MATH_PS_01') |
| `name` | VARCHAR(255) | NO | Competency name |
| `short_name` | VARCHAR(50) | YES | Abbreviated name |
| `description` | VARCHAR(255) | YES | Detailed description |
| `class_id` | INT UNSIGNED | YES | NULL = all classes |
| `subject_id` | BIGINT UNSIGNED | YES | NULL = cross-subject |
| `competency_type` | ENUM | NO | KNOWLEDGE, SKILL, ATTITUDE, VALUE, DISPOSITION |
| `domain` | ENUM | NO | COGNITIVE, AFFECTIVE, PSYCHOMOTOR |
| `nep_framework_ref` | VARCHAR(100) | YES | NEP 2020 document reference |
| `ncf_alignment` | VARCHAR(100) | YES | National Curriculum Framework code |
| `learning_outcome_code` | VARCHAR(50) | YES | NCERT Learning Outcome code |
| `path` | VARCHAR(500) | YES | Materialized path for hierarchy |
| `level` | TINYINT UNSIGNED | YES | Hierarchy depth |
| `is_active` | TINYINT(1) | YES | Active flag |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `slb_topic_competency_jnt`
**Purpose:** Many-to-many relationship between topics and competencies.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `topic_id` | BIGINT UNSIGNED | NO | FK to slb_topics |
| `competency_id` | BIGINT UNSIGNED | NO | FK to slb_competencies |
| `weightage` | DECIMAL(5,2) | YES | How much topic contributes to competency |
| `is_primary` | TINYINT(1) | YES | Primary competency for this topic |
| `created_at` | TIMESTAMP | YES | Creation timestamp |

---

### Table: `syl_topic_prerequisites`
**Purpose:** Tracks topic dependencies for learning path and gap analysis.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `topic_id` | BIGINT UNSIGNED | NO | Topic that has prerequisites |
| `prerequisite_topic_id` | BIGINT UNSIGNED | NO | Required prerequisite topic |
| `prerequisite_class_id` | INT UNSIGNED | YES | If prerequisite is from different class |
| `strength` | ENUM | NO | MANDATORY, RECOMMENDED, OPTIONAL |
| `description` | VARCHAR(255) | YES | Why this is a prerequisite |
| `created_at` | TIMESTAMP | YES | Creation timestamp |

---

## File 2: Question Bank (NEP 2020 Compliant)

### Table: `qb_bloom_taxonomy`
**Purpose:** Bloom's Taxonomy reference data (6 levels).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | INT UNSIGNED | NO | Primary key |
| `level` | TINYINT UNSIGNED | NO | 1-6 for revised taxonomy |
| `code` | VARCHAR(20) | NO | REMEMBER, UNDERSTAND, APPLY, ANALYZE, EVALUATE, CREATE |
| `name` | VARCHAR(50) | NO | Display name |
| `description` | TEXT | YES | Level description |
| `keywords` | JSON | YES | Action verbs for this level |
| `cognitive_order` | ENUM | NO | LOWER, MIDDLE, HIGHER |
| `color_code` | VARCHAR(7) | YES | UI color code |

---

### Table: `qb_cognitive_levels`
**Purpose:** Cognitive level groupings (LOT, MOT, HOT).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | INT UNSIGNED | NO | Primary key |
| `code` | VARCHAR(20) | NO | LOT, MOT, HOT |
| `name` | VARCHAR(50) | NO | Lower/Middle/Higher Order Thinking |
| `description` | VARCHAR(255) | YES | Description |
| `bloom_levels` | JSON | NO | Array of Bloom level IDs |
| `weightage_min` | DECIMAL(5,2) | YES | Min % in assessment |
| `weightage_max` | DECIMAL(5,2) | YES | Max % in assessment |

---

### Table: `qb_complexity_levels`
**Purpose:** Question difficulty levels.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | INT UNSIGNED | NO | Primary key |
| `level` | TINYINT UNSIGNED | NO | 1-4 |
| `code` | VARCHAR(20) | NO | EASY, MEDIUM, HARD, CHALLENGE |
| `name` | VARCHAR(50) | NO | Display name |
| `description` | VARCHAR(255) | YES | Description |
| `time_multiplier` | DECIMAL(3,2) | YES | Time estimate multiplier |
| `marks_multiplier` | DECIMAL(3,2) | YES | Marks multiplier |
| `color_code` | VARCHAR(7) | YES | UI color |

---

### Table: `qb_question_types`
**Purpose:** Question format types with grading settings.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | INT UNSIGNED | NO | Primary key |
| `code` | VARCHAR(30) | NO | MCQ_SINGLE, MCQ_MULTI, MSQ, ASSERTION_REASON, CASE_STUDY, etc. |
| `name` | VARCHAR(100) | NO | Display name |
| `category` | ENUM | NO | OBJECTIVE, SUBJECTIVE, PRACTICAL, MIXED |
| `has_options` | TINYINT(1) | NO | Whether question has options |
| `is_auto_gradable` | TINYINT(1) | NO | Can system grade automatically |
| `default_marks` | DECIMAL(5,2) | YES | Default marks |
| `default_time_seconds` | INT UNSIGNED | YES | Default time to solve |
| `description` | TEXT | YES | Description |
| `grading_rubric` | JSON | YES | Grading guidelines |
| `is_active` | TINYINT(1) | NO | Active flag |

---

### Table: `qb_question_contexts`
**Purpose:** Question usage context (when/where used).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | INT UNSIGNED | NO | Primary key |
| `code` | VARCHAR(30) | NO | IN_CLASS, HOMEWORK, FORMATIVE, SUMMATIVE, OLYMPIAD, REMEDIAL, ENRICHMENT |
| `name` | VARCHAR(100) | NO | Display name |
| `description` | VARCHAR(255) | YES | Description |
| `time_limit_factor` | DECIMAL(3,2) | YES | Time adjustment factor |

---

### Table: `qb_questions`
**Purpose:** Main question bank with NEP 2020 categorization.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `uuid` | CHAR(36) | NO | Unique identifier |
| `topic_id` | BIGINT UNSIGNED | NO | FK to syl_topics |
| `competency_id` | BIGINT UNSIGNED | YES | FK to syl_competencies |
| `lesson_id` | BIGINT UNSIGNED | YES | Denormalized |
| `class_id` | INT UNSIGNED | NO | Denormalized |
| `subject_id` | BIGINT UNSIGNED | NO | Denormalized |
| `question_type_id` | INT UNSIGNED | NO | FK to qb_question_types |
| `bloom_id` | INT UNSIGNED | NO | FK to qb_bloom_taxonomy |
| `cognitive_level_id` | INT UNSIGNED | NO | FK to qb_cognitive_levels |
| `complexity_level_id` | INT UNSIGNED | NO | FK to qb_complexity_levels |
| `context_id` | INT UNSIGNED | YES | FK to qb_question_contexts |
| `stem` | TEXT | NO | Question text (HTML/Markdown) |
| `stem_plain` | TEXT | YES | Plain text for search |
| `hint` | TEXT | YES | Optional hint |
| `answer_explanation` | TEXT | YES | Detailed explanation |
| `reference_material` | TEXT | YES | Source/textbook reference |
| `marks` | DECIMAL(5,2) | NO | Marks for correct answer |
| `negative_marks` | DECIMAL(5,2) | YES | Negative marks for wrong |
| `partial_marking` | TINYINT(1) | YES | Allow partial marks |
| `estimated_time_seconds` | INT UNSIGNED | NO | Time to solve |
| `language` | VARCHAR(10) | YES | Language code |
| `difficulty_rating` | DECIMAL(4,2) | YES | Calculated difficulty |
| `tags` | JSON | YES | Array of tags |
| `external_ref` | VARCHAR(100) | YES | External ID mapping |
| `version` | INT UNSIGNED | NO | Version number |
| `parent_question_id` | BIGINT UNSIGNED | YES | For question variations |
| `status` | ENUM | NO | DRAFT, REVIEW, APPROVED, DEPRECATED |
| `is_active` | TINYINT(1) | NO | Active flag |
| `is_public` | TINYINT(1) | NO | Share between tenants |
| `created_by` | BIGINT UNSIGNED | YES | Creator |
| `approved_by` | BIGINT UNSIGNED | YES | Approver |
| `approved_at` | TIMESTAMP | YES | Approval timestamp |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |
| `deleted_at` | TIMESTAMP | YES | Soft delete |

---

### Table: `qb_question_options`
**Purpose:** Answer options for MCQ/MSQ type questions.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `question_id` | BIGINT UNSIGNED | NO | FK to qb_questions |
| `ordinal` | SMALLINT UNSIGNED | NO | Option order |
| `option_label` | CHAR(1) | YES | A, B, C, D |
| `option_text` | TEXT | NO | Option content |
| `is_correct` | TINYINT(1) | NO | Correct answer flag |
| `partial_score` | DECIMAL(5,2) | YES | For partial marking |
| `feedback` | TEXT | YES | Why right/wrong |
| `image_url` | VARCHAR(500) | YES | Option image |
| `created_at` | TIMESTAMP | YES | Creation timestamp |

---

### Table: `qb_question_analytics`
**Purpose:** Psychometric data for question quality analysis.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `question_id` | BIGINT UNSIGNED | NO | Primary key, FK to qb_questions |
| `total_attempts` | INT UNSIGNED | YES | Total times attempted |
| `correct_attempts` | INT UNSIGNED | YES | Times answered correctly |
| `partial_attempts` | INT UNSIGNED | YES | Times partially correct |
| `avg_time_seconds` | INT UNSIGNED | YES | Average time to answer |
| `min_time_seconds` | INT UNSIGNED | YES | Minimum time |
| `max_time_seconds` | INT UNSIGNED | YES | Maximum time |
| `difficulty_index` | DECIMAL(4,3) | YES | correct/total (0.0-1.0) |
| `discrimination_index` | DECIMAL(4,3) | YES | (top27% - bottom27%)/n |
| `point_biserial` | DECIMAL(4,3) | YES | Correlation coefficient |
| `discrimination_status` | ENUM | YES | EXCELLENT, GOOD, FAIR, POOR, REVISE |
| `last_used` | DATE | YES | Last usage date |
| `last_calculated` | TIMESTAMP | YES | Last calculation time |

---

## File 3: Assessment Engine

### Table: `asm_assessments`
**Purpose:** Unified table for Quizzes, Assessments, and Exams.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `uuid` | CHAR(36) | NO | Unique identifier |
| `assessment_type` | ENUM | NO | QUIZ, ASSESSMENT, EXAM |
| `sub_type` | ENUM | NO | PRACTICE, DIAGNOSTIC, FORMATIVE, SUMMATIVE, UNIT, FINAL, etc. |
| `mode` | ENUM | NO | ONLINE, OFFLINE, HYBRID |
| `code` | VARCHAR(30) | NO | Unique code |
| `name` | VARCHAR(255) | NO | Assessment name |
| `short_name` | VARCHAR(50) | YES | Short name |
| `description` | TEXT | YES | Description |
| `instructions` | TEXT | YES | Student instructions |
| `academic_session_id` | BIGINT UNSIGNED | NO | FK to academic session |
| `class_id` | INT UNSIGNED | NO | FK to sch_classes |
| `subject_id` | BIGINT UNSIGNED | NO | FK to sch_subjects |
| `lesson_id` | BIGINT UNSIGNED | YES | If lesson-specific |
| `scheduled_date` | DATE | YES | Scheduled date |
| `start_datetime` | DATETIME | YES | Start time |
| `end_datetime` | DATETIME | YES | End time |
| `duration_minutes` | INT UNSIGNED | NO | Duration |
| `buffer_minutes` | INT UNSIGNED | YES | Extra time for late start |
| `total_marks` | DECIMAL(7,2) | NO | Total marks |
| `passing_marks` | DECIMAL(7,2) | YES | Passing marks |
| `passing_percent` | DECIMAL(5,2) | YES | Passing percentage |
| `negative_marking_enabled` | TINYINT(1) | YES | Enable negative marking |
| `blueprint` | JSON | YES | Bloom/complexity distribution |
| `shuffle_questions` | TINYINT(1) | YES | Randomize question order |
| `shuffle_options` | TINYINT(1) | YES | Randomize option order |
| `show_question_palette` | TINYINT(1) | YES | Show question navigator |
| `allow_navigation` | TINYINT(1) | YES | Allow moving between questions |
| `allow_review_before_submit` | TINYINT(1) | YES | Allow review |
| `show_result_immediately` | TINYINT(1) | YES | Show result on submit |
| `show_answers_after` | ENUM | YES | IMMEDIATE, AFTER_DEADLINE, AFTER_GRADING, NEVER |
| `max_attempts` | INT UNSIGNED | YES | Maximum attempts allowed |
| `cooldown_hours` | INT UNSIGNED | YES | Time between attempts |
| `grade_method` | ENUM | YES | HIGHEST, LATEST, AVERAGE, FIRST |
| `proctoring_enabled` | TINYINT(1) | YES | Enable proctoring |
| `status` | ENUM | NO | DRAFT, READY, PUBLISHED, IN_PROGRESS, COMPLETED, ARCHIVED |
| `is_published` | TINYINT(1) | NO | Published flag |
| `created_by` | BIGINT UNSIGNED | YES | Creator |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |
| `deleted_at` | TIMESTAMP | YES | Soft delete |

---

### Table: `asm_topic_teaching_status`
**Purpose:** Tracks teacher's progress on teaching topics (triggers auto-assignment).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `academic_session_id` | BIGINT UNSIGNED | NO | Academic session |
| `topic_id` | BIGINT UNSIGNED | NO | FK to syl_topics |
| `class_section_id` | INT UNSIGNED | NO | FK to sch_class_section_jnt |
| `teacher_id` | BIGINT UNSIGNED | NO | FK to sch_teachers |
| `status` | ENUM | NO | NOT_STARTED, IN_PROGRESS, COMPLETED, REVISION |
| `completion_percent` | DECIMAL(5,2) | YES | Completion percentage |
| `planned_start_date` | DATE | YES | Planned start |
| `actual_start_date` | DATE | YES | Actual start |
| `planned_end_date` | DATE | YES | Planned end |
| `actual_end_date` | DATE | YES | Actual end |
| `periods_planned` | SMALLINT UNSIGNED | YES | Planned periods |
| `periods_taken` | SMALLINT UNSIGNED | YES | Actual periods taken |
| `notes` | TEXT | YES | Teacher notes |
| `marked_complete_at` | TIMESTAMP | YES | Completion timestamp |
| `marked_complete_by` | BIGINT UNSIGNED | YES | Who marked complete |
| `auto_assign_triggered` | TINYINT(1) | YES | Quiz auto-assigned? |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `asm_topic_assessment_link`
**Purpose:** Links quizzes to topics for auto-assignment when topic is marked complete.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `topic_id` | BIGINT UNSIGNED | NO | FK to syl_topics |
| `assessment_id` | BIGINT UNSIGNED | NO | FK to asm_assessments |
| `trigger_on` | ENUM | NO | TOPIC_COMPLETE, MANUAL, SCHEDULED |
| `delay_hours` | INT UNSIGNED | YES | Delay after trigger |
| `is_active` | TINYINT(1) | YES | Active flag |
| `created_at` | TIMESTAMP | YES | Creation timestamp |

---

### Table: `asm_assignments`
**Purpose:** Assignment of assessments to sections/students.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `assessment_id` | BIGINT UNSIGNED | NO | FK to asm_assessments |
| `assigned_to_type` | ENUM | NO | SECTION, STUDENT, SUBJECT_GROUP, CUSTOM_GROUP |
| `assigned_to_id` | BIGINT UNSIGNED | NO | Target entity ID |
| `available_from` | DATETIME | NO | Start availability |
| `available_to` | DATETIME | NO | End availability |
| `max_attempts` | INT UNSIGNED | YES | Override max attempts |
| `extra_time_minutes` | INT UNSIGNED | YES | Additional time (accommodation) |
| `trigger_type` | ENUM | NO | MANUAL, TOPIC_COMPLETE, SCHEDULED, PREREQUISITE |
| `triggered_by_topic_id` | BIGINT UNSIGNED | YES | Topic that triggered assignment |
| `notification_sent` | TINYINT(1) | YES | Notification sent flag |
| `created_by` | BIGINT UNSIGNED | YES | Assigner |
| `created_at` | TIMESTAMP | YES | Creation timestamp |

---

## File 4: Student Attempts & Behavioral Tracking

### Table: `asm_student_attempts`
**Purpose:** Main record for each student's assessment attempt.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `uuid` | CHAR(36) | NO | Unique identifier |
| `assessment_id` | BIGINT UNSIGNED | NO | FK to asm_assessments |
| `assignment_id` | BIGINT UNSIGNED | YES | FK to asm_assignments |
| `student_id` | BIGINT UNSIGNED | NO | FK to std_students |
| `attempt_number` | INT UNSIGNED | NO | Which attempt (1, 2, 3...) |
| `session_id` | VARCHAR(64) | YES | Browser session ID |
| `ip_address` | VARCHAR(45) | YES | Client IP |
| `user_agent` | VARCHAR(500) | YES | Browser info |
| `device_type` | ENUM | YES | DESKTOP, LAPTOP, TABLET, MOBILE, UNKNOWN |
| `started_at` | DATETIME | NO | Start timestamp |
| `submitted_at` | DATETIME | YES | Submission timestamp |
| `auto_submitted` | TINYINT(1) | YES | System auto-submitted (timeout) |
| `time_allowed_seconds` | INT UNSIGNED | NO | Total time allowed |
| `time_taken_seconds` | INT UNSIGNED | YES | Actual time taken |
| `time_active_seconds` | INT UNSIGNED | YES | Active time (excluding idle) |
| `total_questions` | INT UNSIGNED | NO | Total questions in assessment |
| `questions_attempted` | INT UNSIGNED | YES | Questions answered |
| `questions_skipped` | INT UNSIGNED | YES | Questions skipped |
| `status` | ENUM | NO | IN_PROGRESS, SUBMITTED, GRADING, GRADED, CANCELLED, EXPIRED |
| `marks_obtained` | DECIMAL(8,2) | YES | Total marks obtained |
| `percentage_score` | DECIMAL(5,2) | YES | Percentage score |
| `is_passed` | TINYINT(1) | YES | Pass/fail status |
| `integrity_score` | DECIMAL(5,2) | YES | Integrity % based on behavior |
| `violation_count` | INT UNSIGNED | YES | Number of violations |
| `is_flagged` | TINYINT(1) | YES | Flagged for review |
| `avg_confidence_score` | DECIMAL(5,2) | YES | Average confidence |
| `graded_by` | BIGINT UNSIGNED | YES | Grader user ID |
| `graded_at` | DATETIME | YES | Grading timestamp |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `asm_student_responses`
**Purpose:** Individual question responses with detailed tracking.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `attempt_id` | BIGINT UNSIGNED | NO | FK to asm_student_attempts |
| `assessment_item_id` | BIGINT UNSIGNED | NO | FK to asm_assessment_items |
| `question_id` | BIGINT UNSIGNED | NO | FK to qb_questions |
| `response_type` | ENUM | NO | OPTION, TEXT, NUMERIC, FILE, MULTIPLE, MATCH |
| `selected_option_ids` | JSON | YES | Array of selected option IDs |
| `answer_text` | TEXT | YES | Text answer |
| `answer_numeric` | DECIMAL(20,6) | YES | Numeric answer |
| `first_viewed_at` | DATETIME | YES | First view timestamp |
| `first_answered_at` | DATETIME | YES | First answer timestamp |
| `time_spent_seconds` | INT UNSIGNED | YES | Time on question |
| `view_count` | INT UNSIGNED | YES | Times viewed |
| `answer_change_count` | INT UNSIGNED | YES | Times answer changed |
| `marked_for_review` | TINYINT(1) | YES | Marked for review |
| `was_skipped` | TINYINT(1) | YES | Was initially skipped |
| `is_correct` | TINYINT(1) | YES | Correct/incorrect |
| `is_partially_correct` | TINYINT(1) | YES | Partially correct |
| `marks_awarded` | DECIMAL(6,2) | YES | Marks given |
| `time_ratio` | DECIMAL(5,2) | YES | time_spent/estimated_time |
| `hesitation_score` | DECIMAL(5,2) | YES | Based on answer changes |
| `confidence_indicator` | ENUM | YES | HIGH, MEDIUM, LOW, GUESS |
| `auto_graded` | TINYINT(1) | YES | Auto-graded by system |
| `grader_feedback` | TEXT | YES | Manual grader feedback |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `asm_behavioral_events`
**Purpose:** Captures all behavioral data for analytics and proctoring.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `attempt_id` | BIGINT UNSIGNED | NO | FK to asm_student_attempts |
| `event_type` | ENUM | NO | QUESTION_VIEW, ANSWER_CHANGE, TAB_SWITCH, FOCUS_LOST, COPY_ATTEMPT, etc. |
| `event_timestamp` | DATETIME(3) | NO | Millisecond precision timestamp |
| `event_data` | JSON | YES | Event-specific data |
| `question_id` | BIGINT UNSIGNED | YES | Related question if applicable |
| `severity` | ENUM | YES | INFO, WARNING, CRITICAL |
| `client_timestamp` | DATETIME(3) | YES | Client-side timestamp |

---

### Table: `asm_integrity_violations`
**Purpose:** Tracks proctoring violations and suspicious behavior.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `attempt_id` | BIGINT UNSIGNED | NO | FK to asm_student_attempts |
| `violation_type` | ENUM | NO | TAB_SWITCH, COPY_PASTE, FULLSCREEN_EXIT, MULTIPLE_FACES, etc. |
| `severity` | ENUM | NO | LOW, MEDIUM, HIGH, CRITICAL |
| `penalty_points` | DECIMAL(5,2) | YES | Points deducted |
| `description` | VARCHAR(500) | YES | Description |
| `evidence` | JSON | YES | Screenshot URL, etc. |
| `reviewed` | TINYINT(1) | YES | Reviewed by teacher |
| `reviewed_by` | BIGINT UNSIGNED | YES | Reviewer ID |
| `action_taken` | VARCHAR(255) | YES | Action description |
| `occurred_at` | DATETIME | NO | When violation occurred |
| `created_at` | TIMESTAMP | YES | Record creation time |

---

## File 5: Analytics & Recommendations

### Table: `anl_student_topic_mastery`
**Purpose:** Per-topic performance tracking for each student.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `student_id` | BIGINT UNSIGNED | NO | FK to std_students |
| `topic_id` | BIGINT UNSIGNED | NO | FK to syl_topics |
| `class_id` | INT UNSIGNED | NO | Class ID |
| `subject_id` | BIGINT UNSIGNED | NO | Subject ID |
| `academic_session_id` | BIGINT UNSIGNED | NO | Session ID |
| `total_questions_seen` | INT UNSIGNED | YES | Questions encountered |
| `total_questions_attempted` | INT UNSIGNED | YES | Questions attempted |
| `total_correct` | INT UNSIGNED | YES | Correct answers |
| `avg_score_percent` | DECIMAL(5,2) | YES | Average score |
| `bloom_remember_score` | DECIMAL(5,2) | YES | Remember level score |
| `bloom_understand_score` | DECIMAL(5,2) | YES | Understand level score |
| `bloom_apply_score` | DECIMAL(5,2) | YES | Apply level score |
| `bloom_analyze_score` | DECIMAL(5,2) | YES | Analyze level score |
| `bloom_evaluate_score` | DECIMAL(5,2) | YES | Evaluate level score |
| `bloom_create_score` | DECIMAL(5,2) | YES | Create level score |
| `mastery_level` | ENUM | YES | NOT_STARTED, BEGINNER, DEVELOPING, PROFICIENT, MASTERED |
| `mastery_score` | DECIMAL(5,2) | YES | 0-100 composite score |
| `confidence_level` | ENUM | YES | LOW, MEDIUM, HIGH |
| `trend` | ENUM | YES | IMPROVING, STABLE, DECLINING |
| `is_weak_topic` | TINYINT(1) | YES | Below threshold flag |
| `needs_attention` | TINYINT(1) | YES | Needs help flag |
| `weak_reason` | JSON | YES | Reasons for weakness |
| `last_attempt_date` | DATE | YES | Last activity |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `anl_prerequisite_gaps`
**Purpose:** Identifies foundational gaps affecting current performance.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `student_id` | BIGINT UNSIGNED | NO | FK to std_students |
| `current_topic_id` | BIGINT UNSIGNED | NO | Topic student is struggling with |
| `prerequisite_topic_id` | BIGINT UNSIGNED | NO | Missing foundation topic |
| `prerequisite_class_id` | INT UNSIGNED | YES | Class where prerequisite was taught |
| `gap_severity` | ENUM | NO | LOW, MEDIUM, HIGH, CRITICAL |
| `gap_score` | DECIMAL(5,2) | NO | 0-100 (higher = bigger gap) |
| `correlation_strength` | DECIMAL(4,2) | YES | How strongly prerequisite affects current |
| `current_topic_accuracy` | DECIMAL(5,2) | YES | Current topic score |
| `prerequisite_accuracy` | DECIMAL(5,2) | YES | Prerequisite topic score |
| `pattern_description` | TEXT | YES | Explanation of the gap |
| `is_addressed` | TINYINT(1) | YES | Gap has been addressed |
| `remediation_provided` | TINYINT(1) | YES | Remedial content provided |
| `identified_at` | TIMESTAMP | YES | When gap was identified |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `anl_student_recommendations`
**Purpose:** Personalized recommendations for students.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `student_id` | BIGINT UNSIGNED | NO | FK to std_students |
| `recommendation_type` | ENUM | NO | FOCUS_TOPIC, PREREQUISITE_REVIEW, LEARNING_RESOURCE, etc. |
| `topic_id` | BIGINT UNSIGNED | YES | Related topic |
| `subject_id` | BIGINT UNSIGNED | YES | Related subject |
| `competency_id` | BIGINT UNSIGNED | YES | Related competency |
| `title` | VARCHAR(255) | NO | Recommendation title |
| `description` | TEXT | NO | Detailed description |
| `priority` | ENUM | NO | LOW, MEDIUM, HIGH, URGENT |
| `action_items` | JSON | YES | Specific action steps |
| `resource_type` | ENUM | YES | TEXT, VIDEO, PRACTICE, EXTERNAL_LINK, DOCUMENT |
| `resource_url` | VARCHAR(500) | YES | Resource URL |
| `resource_title` | VARCHAR(255) | YES | Resource title |
| `based_on_assessment_id` | BIGINT UNSIGNED | YES | Triggering assessment |
| `trigger_reason` | VARCHAR(500) | YES | Why recommended |
| `status` | ENUM | YES | PENDING, VIEWED, IN_PROGRESS, COMPLETED, DISMISSED |
| `viewed_at` | DATETIME | YES | When viewed |
| `completed_at` | DATETIME | YES | When completed |
| `feedback` | TEXT | YES | Student feedback |
| `helpful_rating` | TINYINT UNSIGNED | YES | 1-5 rating |
| `valid_from` | DATETIME | NO | Start validity |
| `valid_until` | DATETIME | YES | End validity |
| `is_active` | TINYINT(1) | YES | Active flag |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `anl_teacher_recommendations`
**Purpose:** Recommendations for teachers based on class performance.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `teacher_id` | BIGINT UNSIGNED | NO | FK to sch_teachers |
| `class_section_id` | INT UNSIGNED | YES | Related section |
| `recommendation_type` | ENUM | NO | TOPIC_RETEACH, PACE_ADJUSTMENT, STUDENT_ATTENTION, etc. |
| `topic_id` | BIGINT UNSIGNED | YES | Related topic |
| `subject_id` | BIGINT UNSIGNED | YES | Related subject |
| `student_ids` | JSON | YES | Affected students |
| `title` | VARCHAR(255) | NO | Recommendation title |
| `description` | TEXT | NO | Detailed description |
| `priority` | ENUM | NO | LOW, MEDIUM, HIGH, URGENT |
| `supporting_data` | JSON | YES | Charts, stats |
| `status` | ENUM | YES | PENDING, VIEWED, ACKNOWLEDGED, ACTIONED, DISMISSED |
| `teacher_response` | TEXT | YES | Teacher's response |
| `actioned_at` | DATETIME | YES | When teacher acted |
| `is_active` | TINYINT(1) | YES | Active flag |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

### Table: `anl_learning_resources`
**Purpose:** Library of learning resources (videos, texts, etc.).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `uuid` | CHAR(36) | NO | Unique identifier |
| `topic_id` | BIGINT UNSIGNED | YES | Related topic |
| `competency_id` | BIGINT UNSIGNED | YES | Related competency |
| `subject_id` | BIGINT UNSIGNED | NO | Related subject |
| `class_id` | INT UNSIGNED | YES | Target class |
| `resource_type` | ENUM | NO | VIDEO, TEXT, PDF, INTERACTIVE, SIMULATION, AUDIO, EXTERNAL_LINK |
| `title` | VARCHAR(255) | NO | Resource title |
| `description` | TEXT | YES | Description |
| `url` | VARCHAR(500) | NO | Resource URL |
| `thumbnail_url` | VARCHAR(500) | YES | Thumbnail image |
| `duration_minutes` | INT UNSIGNED | YES | Duration (for video/audio) |
| `difficulty_level` | ENUM | YES | BEGINNER, INTERMEDIATE, ADVANCED |
| `language` | VARCHAR(10) | YES | Language code |
| `source` | VARCHAR(100) | YES | NCERT, Khan Academy, etc. |
| `tags` | JSON | YES | Tag array |
| `avg_rating` | DECIMAL(3,2) | YES | Average rating |
| `view_count` | INT UNSIGNED | YES | Views |
| `completion_rate` | DECIMAL(5,2) | YES | Completion rate |
| `is_active` | TINYINT(1) | YES | Active flag |
| `created_by` | BIGINT UNSIGNED | YES | Creator |
| `created_at` | TIMESTAMP | YES | Creation timestamp |
| `updated_at` | TIMESTAMP | YES | Update timestamp |

---

## File 6: Summary Tables & Views

### Table: `rpt_assessment_summary`
**Purpose:** Pre-aggregated assessment-level analytics.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `assessment_id` | BIGINT UNSIGNED | NO | Primary key, FK to asm_assessments |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `class_id` | INT UNSIGNED | NO | Class ID |
| `subject_id` | BIGINT UNSIGNED | NO | Subject ID |
| `total_assigned` | INT UNSIGNED | YES | Students assigned |
| `total_submitted` | INT UNSIGNED | YES | Students submitted |
| `participation_rate` | DECIMAL(5,2) | YES | Participation % |
| `avg_score_percent` | DECIMAL(5,2) | YES | Average score |
| `median_score_percent` | DECIMAL(5,2) | YES | Median score |
| `pass_count` | INT UNSIGNED | YES | Passed students |
| `fail_count` | INT UNSIGNED | YES | Failed students |
| `pass_rate` | DECIMAL(5,2) | YES | Pass % |
| `bloom_remember_avg` | DECIMAL(5,2) | YES | Avg for Remember level |
| `bloom_understand_avg` | DECIMAL(5,2) | YES | Avg for Understand level |
| `bloom_apply_avg` | DECIMAL(5,2) | YES | Avg for Apply level |
| `bloom_analyze_avg` | DECIMAL(5,2) | YES | Avg for Analyze level |
| `bloom_evaluate_avg` | DECIMAL(5,2) | YES | Avg for Evaluate level |
| `bloom_create_avg` | DECIMAL(5,2) | YES | Avg for Create level |
| `last_calculated` | TIMESTAMP | YES | Last calculation time |

---

### Table: `rpt_topic_performance`
**Purpose:** Pre-aggregated topic-level performance by section.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `academic_session_id` | BIGINT UNSIGNED | NO | Session ID |
| `class_id` | INT UNSIGNED | NO | Class ID |
| `section_id` | INT UNSIGNED | YES | Section ID (NULL for class-wide) |
| `subject_id` | BIGINT UNSIGNED | NO | Subject ID |
| `topic_id` | BIGINT UNSIGNED | NO | Topic ID |
| `student_count` | INT UNSIGNED | YES | Total students |
| `avg_accuracy_percent` | DECIMAL(5,2) | YES | Average accuracy |
| `avg_mastery_score` | DECIMAL(5,2) | YES | Average mastery |
| `mastered_count` | INT UNSIGNED | YES | Students mastered |
| `proficient_count` | INT UNSIGNED | YES | Students proficient |
| `developing_count` | INT UNSIGNED | YES | Students developing |
| `is_weak_topic` | TINYINT(1) | YES | Weak topic flag |
| `needs_reteaching` | TINYINT(1) | YES | Needs reteaching |
| `last_calculated` | TIMESTAMP | YES | Last calculation time |

---

### Table: `rpt_student_performance`
**Purpose:** Pre-aggregated student subject performance summary.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | NO | Primary key |
| `tenant_id` | BIGINT UNSIGNED | NO | Multi-tenant isolation |
| `academic_session_id` | BIGINT UNSIGNED | NO | Session ID |
| `student_id` | BIGINT UNSIGNED | NO | Student ID |
| `subject_id` | BIGINT UNSIGNED | NO | Subject ID |
| `class_id` | INT UNSIGNED | NO | Class ID |
| `assessments_taken` | INT UNSIGNED | YES | Total assessments |
| `avg_assessment_score` | DECIMAL(5,2) | YES | Avg assessment score |
| `quizzes_taken` | INT UNSIGNED | YES | Total quizzes |
| `avg_quiz_score` | DECIMAL(5,2) | YES | Avg quiz score |
| `exams_taken` | INT UNSIGNED | YES | Total exams |
| `avg_exam_score` | DECIMAL(5,2) | YES | Avg exam score |
| `overall_avg_score` | DECIMAL(5,2) | YES | Overall average |
| `class_rank` | INT UNSIGNED | YES | Class rank |
| `section_rank` | INT UNSIGNED | YES | Section rank |
| `percentile` | DECIMAL(5,2) | YES | Percentile |
| `total_topics` | INT UNSIGNED | YES | Total topics |
| `mastered_topics` | INT UNSIGNED | YES | Mastered count |
| `weak_topics` | INT UNSIGNED | YES | Weak count |
| `lot_score` | DECIMAL(5,2) | YES | Lower Order Thinking score |
| `mot_score` | DECIMAL(5,2) | YES | Middle Order Thinking score |
| `hot_score` | DECIMAL(5,2) | YES | Higher Order Thinking score |
| `trend` | ENUM | YES | IMPROVING, STABLE, DECLINING |
| `last_calculated` | TIMESTAMP | YES | Last calculation time |

---

## Views

### View: `vw_topic_hierarchy`
**Purpose:** Flattened topic hierarchy for easy querying with lesson, class, and subject information.

### View: `vw_question_bank`
**Purpose:** Question bank overview with all taxonomies and analytics joined.

### View: `vw_student_gap_analysis`
**Purpose:** Student weak topics with prerequisite gap information for gap analysis reports.

### View: `vw_assessment_analytics`
**Purpose:** Assessment analytics with summary statistics joined.

---

## Reporting Query Examples

### Query: Average Score in "Algebra" for Grade 10 (School-wide)

```sql
SELECT 
  t.name AS topic_name,
  AVG(stm.avg_score_percent) AS avg_score,
  COUNT(DISTINCT stm.student_id) AS student_count
FROM anl_student_topic_mastery stm
JOIN syl_topics t ON stm.topic_id = t.id
JOIN sch_classes c ON stm.class_id = c.id
WHERE c.name = 'Class 10'
  AND t.name LIKE '%Algebra%'
  AND stm.academic_session_id = [current_session_id]
GROUP BY t.id, t.name;
```

### Query: Class Performance by Bloom's Level

```sql
SELECT 
  c.name AS class_name,
  bt.name AS bloom_level,
  AVG(ba.avg_accuracy_percent) AS avg_accuracy,
  SUM(ba.total_questions_asked) AS total_questions
FROM rpt_bloom_aggregation ba
JOIN sch_classes c ON ba.class_id = c.id
JOIN qb_bloom_taxonomy bt ON ba.bloom_id = bt.id
WHERE ba.academic_session_id = [current_session_id]
GROUP BY c.id, c.name, bt.id, bt.name
ORDER BY c.ordinal, bt.level;
```

---

## End of Data Dictionary
