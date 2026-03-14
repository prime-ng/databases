# Data Dictionary: Syllabus & Exam Management Module (v1.3)

**File:** `sch_syllabus_ddl_v1.3.sql`
**Version:** 1.3
**Prefix:** `slb_` / `sch_`

This document details the database schema for the Syllabus Module, explaining the purpose and requirement of each field.

---

## 1. Table: `slb_lessons`
**Purpose:** Stores the high-level units (Chapters/Lessons) of a subject for a specific class and academic session.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `id` | BIGINT UNSIGNED | No | Primary Key. |
| `uuid` | CHAR(36) | No | Unique immutable identifier for analytics. |
| `academic_session_id` | BIGINT UNSIGNED | No | Links lesson to a specific academic year. |
| `class_id` | INT UNSIGNED | No | Identifies the class (Grade). |
| `subject_id` | BIGINT UNSIGNED | No | Identifies the subject. |
| `code` | VARCHAR(20) | No | Unique code (Class+Subject+LessonOrdinal). |
| `name` | VARCHAR(150) | No | Lesson Name. |
| `ordinal` | SMALLINT UNSIGNED | No | Sequence order. |

## 2. Table: `slb_topics`
**Purpose:** Hierarchical structure of content (Topics > Sub-topics). Uses Materialized Path.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `id` | BIGINT UNSIGNED | No | PK. |
| `uuid` | CHAR(36) | No | Unique analytics ID. |
| `path` | VARCHAR(500) | No | Materialized path for hierarchy. |
| `level` | TINYINT | No | Depth level (0=Topic, 1=Sub...). |
| `code` | VARCHAR(60) | No | Unique hierarchical code. |

## 3. Table: `slb_competency_types`
**Purpose:** Master list of competency domains (Knowledge, Skill).

## 4. Table: `slb_competencies`
**Purpose:** Stores specific competencies (NEP/NCF).

## 5. Table: `slb_topic_competency_jnt`
**Purpose:** Links Topics to Competencies.

## 6. Table: `slb_bloom_taxonomy`
**Purpose:** Reference table for Bloom's Taxonomy.

## 7. Table: `slb_question_types`
**Purpose:** Defines question types (MCQ, Descriptive).

---
**NEW TABLES (Assessment Engine)**
---

## 8. Table: `sch_questions`
**Purpose:** The central repository for all questions (Question Bank).

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `id` | BIGINT | No | PK. |
| `stem` | TEXT | No | The actual question text. |
| `question_type_id` | INT | No | FK to Type (MCQ, etc). |
| `topic_id` | BIGINT | Yes | Links question to specific syllabus topic. |
| `competency_id` | BIGINT | Yes | Links question to specific competency. |
| `complexity_level_id`| INT | Yes | Difficulty level (Easy, Med, Hard). |
| `bloom_id` | INT | Yes | Bloom's level (Remember, Apply). |
| `marks` | DECIMAL | Yes | Default marks for this question. |
| `version` | INT | No | Version number for change tracking. |

## 9. Table: `sch_question_options`
**Purpose:** Stores options for MCQ/MSQ questions.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `question_id` | BIGINT | No | Parent Question. |
| `option_text` | TEXT | No | The option content. |
| `is_correct` | BOOL | No | Marks this option as correct. |
| `feedback` | TEXT | Yes | Explanation shown if student selects this. |

## 10. Table: `sch_question_media`
**Purpose:** Stores images/audio/video associated with questions.

## 11. Table: `sch_question_tags` & `sch_question_tag_jnt`
**Purpose:** Tagging system for flexible question filtering.

## 12. Table: `sch_question_versions`
**Purpose:** Stores history of changes to questions (audit/rollback).

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `question_id` | BIGINT | No | The question changed. |
| `version` | INT | No | Version number. |
| `data` | JSON | No | Full snapshot of question state. |

## 13. Table: `sch_question_pools` & `_questions`
**Purpose:** Groups questions for random selection in exams.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `complexity_filter` | JSON | Yes | Rules for auto-populating pool. |
| `min_questions` | INT | Yes | Minimum size of pool. |

## 14. Table: `sch_quizzes`
**Purpose:** Lightweight assessments (Practice/Daily).

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `quiz_type` | ENUM | Yes | Practice, Diagnostic, etc. |
| `shuffle_questions` | BOOL | Yes | Randomizes order per student. |

## 15. Table: `sch_assessments`
**Purpose:** Formal assessments (Formative/Summative).

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `type` | ENUM | No | Formative, Summative, Term. |
| `academic_session_id`| BIGINT | Yes | Links to academic year. |
| `start_datetime` | DATETIME | Yes | Evaluation window start. |
| `end_datetime` | DATETIME | Yes | Evaluation window end. |

## 16. Table: `sch_exams`
**Purpose:** High-stakes exams (Mid-term, Final, Board).

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `exam_type` | ENUM | No | Unit, Midterm, Final, Board. |
| `scheduled_date` | DATE | No | Fixed date for the exam. |
| `start_time` | TIME | No | Fixed start time. |

## 17. Table: `sch_assessment_sections`
**Purpose:** Divides an assessment into logical sections (Part A, Part B).

## 18. Table: `sch_assessment_items`
**Purpose:** Links Questions to Assessments (Manual Selection).

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `assessment_id` | BIGINT | No | Parent Assessment. |
| `question_id` | BIGINT | No | The Question. |
| `marks` | DECIMAL | Yes | Override marks for this exam. |

## 19. Table: `sch_exam_items`
**Purpose:** Links Questions to Exams.

## 20. Table: `sch_quiz_assessment_map`
**Purpose:** Maps a Quiz to an Assessment entry.

## 21. Table: `sch_assessment_assignments`
**Purpose:** Assigns assessments to targets (Students/Sections).

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `assigned_to_type` | ENUM | No | Student, Class_Section, Group. |
| `assigned_to_id` | BIGINT | No | ID of the target. |
| `available_from` | DATETIME | Yes | Individualized start time. |

## 22. Table: `sch_assessment_assignment_rules`
**Purpose:** Rules for taking the assessment (IP restriction, etc).

## 23. Table: `sch_attempts`
**Purpose:** Records a student's session of taking an assessment.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `student_id` | BIGINT | No | The student. |
| `status` | ENUM | No | In-Progress, Submitted. |
| `total_marks_obtained`| DECIMAL | Yes | Score achieved. |
| `ip_address` | VARCHAR | Yes | For integrity audit. |

## 24. Table: `sch_attempt_answers`
**Purpose:** Stores the specific answer given by a student for a question.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `selected_option_ids`| JSON | Yes | For MCQs. |
| `answer_text` | TEXT | Yes | For Descriptive/Numeric. |
| `marks_awarded` | DECIMAL | Yes | Score for this specific question. |

## 25. Table: `sch_student_learning_outcomes`
**Purpose:** Tracks student mastery of competencies based on assessment results.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `student_id` | BIGINT | No | The student. |
| `competency_id` | BIGINT | No | The competency tracked. |
| `mastery_status` | ENUM | Yes | Proficient, Mastered, etc. |

## 26. Table: `sch_question_analytics`
**Purpose:** Aggregated stats for Question Quality Analysis.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `difficulty_index` | DECIMAL | Yes | How hard is this question? |
| `discrimination_index`| DECIMAL | Yes | Does it distinguish good students? |

## 27. Table: `sch_exam_analytics`
**Purpose:** Aggregated stats for Exam Performance.

| Column | Type | Nullable | Why Required? |
| :--- | :--- | :---: | :--- |
| `pass_percentage` | DECIMAL | Yes | % of students passed. |
| `avg_score_percent` | DECIMAL | Yes | Average class score. |

## 28. Table: `sch_audit_log`
**Purpose:** System-wide audit for sensitive changes (Grades, Publishing).

## 29. Table: `sch_question_index`
**Purpose:** Materialized view for fast searching/filtering of questions.
