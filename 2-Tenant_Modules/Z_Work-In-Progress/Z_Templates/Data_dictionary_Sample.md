# Syllabus Module v1.4 - Data Dictionary

**Version:** 1.4  
**Created:** December 22, 2025  
**Module Prefix:** `slb_` (Syllabus Base), `sch_` (School-specific)

---

## Table of Contents

1. [Book & Publication Management](#1-book--publication-management)
2. [Performance Categories](#2-performance-categories)
3. [Study Materials & Recommendations](#3-study-materials--recommendations)
4. [Topic Dependencies](#4-topic-dependencies)
5. [Teaching Status & Scheduling](#5-teaching-status--scheduling)
6. [Teacher Assignments](#6-teacher-assignments)
7. [Question Ownership](#7-question-ownership)
8. [Quiz Auto-Assignment](#8-quiz-auto-assignment)
9. [Offline Exam Support](#9-offline-exam-support)
10. [Behavioral Analytics](#10-behavioral-analytics)
11. [Student Performance Tracking](#11-student-performance-tracking)
12. [Recommendations Engine](#12-recommendations-engine)
13. [Aggregation Tables](#13-aggregation-tables)
14. [Modified Tables (from v1.3)](#14-modified-tables)

---

## 1. Book & Publication Management

### 1.1 `slb_books`
**Purpose:** Master table for all textbooks and reference books used across schools.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| uuid | CHAR(36) | NO | UQ | Unique identifier for API/analytics |
| isbn | VARCHAR(20) | YES | UQ | International Standard Book Number |
| title | VARCHAR(255) | NO | IDX | Book title |
| subtitle | VARCHAR(255) | YES | | Additional title information |
| edition | VARCHAR(50) | YES | | Edition info (e.g., '5th Edition') |
| publication_year | YEAR | YES | IDX | Year of publication |
| publisher_name | VARCHAR(150) | YES | IDX | Publisher (NCERT, S.Chand, etc.) |
| language | VARCHAR(50) | YES | | Primary language (default: English) |
| total_pages | INT UNSIGNED | YES | | Total page count |
| cover_image_url | VARCHAR(500) | YES | | URL to cover image |
| description | TEXT | YES | | Book description/synopsis |
| tags | JSON | YES | | Searchable tags array |
| is_ncert | TINYINT(1) | YES | | Flag for NCERT publications |
| is_cbse_recommended | TINYINT(1) | YES | | CBSE recommended flag |
| is_active | TINYINT(1) | NO | | Active status (default: 1) |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |
| deleted_at | TIMESTAMP | YES | | Soft delete timestamp |

**Why Needed:** Enables tracking which books are used for which topics, facilitates question alignment with specific textbooks, and allows reuse across multiple schools.

---

### 1.2 `slb_book_authors`
**Purpose:** Stores author information for books.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| name | VARCHAR(150) | NO | UQ | Author's full name |
| qualification | VARCHAR(200) | YES | | Academic qualifications |
| bio | TEXT | YES | | Author biography |
| is_active | TINYINT(1) | NO | | Active status |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

---

### 1.3 `slb_book_author_jnt`
**Purpose:** Many-to-many junction between books and authors.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| book_id | BIGINT UNSIGNED | NO | PK,FK | Reference to slb_books |
| author_id | BIGINT UNSIGNED | NO | PK,FK | Reference to slb_book_authors |
| author_role | ENUM | YES | | PRIMARY/CO_AUTHOR/EDITOR/CONTRIBUTOR |
| ordinal | TINYINT UNSIGNED | YES | | Display order of authors |

---

### 1.4 `slb_book_class_subject_jnt`
**Purpose:** Links books to specific class-subject combinations per academic session.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| book_id | BIGINT UNSIGNED | NO | FK,UQ | Reference to slb_books |
| class_id | INT UNSIGNED | NO | FK,UQ | Reference to sch_classes |
| subject_id | BIGINT UNSIGNED | NO | FK,UQ | Reference to sch_subjects |
| academic_session_id | BIGINT UNSIGNED | NO | FK,UQ | Reference to academic session |
| is_primary | TINYINT(1) | YES | | Primary textbook vs reference |
| is_mandatory | TINYINT(1) | YES | | Mandatory or optional reading |
| remarks | VARCHAR(255) | YES | | Additional notes |
| is_active | TINYINT(1) | NO | | Active status |
| created_at | TIMESTAMP | YES | | Record creation timestamp |

**Why Needed:** Different schools may use different books for the same class/subject. This allows flexibility while maintaining the book-topic mapping.

---

### 1.5 `slb_book_topic_mapping`
**Purpose:** Granular mapping between book chapters/sections and syllabus topics.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| book_id | BIGINT UNSIGNED | NO | FK,IDX | Reference to slb_books |
| topic_id | BIGINT UNSIGNED | NO | FK,IDX | Reference to slb_topics (any level) |
| chapter_number | VARCHAR(20) | YES | | Chapter number (e.g., '1', '1.2') |
| chapter_title | VARCHAR(255) | YES | | Chapter/section title |
| page_start | INT UNSIGNED | YES | | Starting page number |
| page_end | INT UNSIGNED | YES | | Ending page number |
| section_reference | VARCHAR(100) | YES | | Specific section reference |
| remarks | VARCHAR(255) | YES | | Additional notes |
| is_active | TINYINT(1) | NO | | Active status |
| created_at | TIMESTAMP | YES | | Record creation timestamp |

**Why Needed:** Enables precise alignment of questions with book content, helping students reference exact pages for revision.

---

## 2. Performance Categories

### 2.1 `slb_performance_categories`
**Purpose:** Configurable performance bands for categorizing student achievement.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | INT UNSIGNED | NO | PK | Auto-increment primary key |
| uuid | CHAR(36) | NO | UQ | Unique identifier |
| code | VARCHAR(30) | NO | UQ | Category code (BASIC, AVERAGE, etc.) |
| name | VARCHAR(100) | NO | | Display name |
| description | VARCHAR(255) | YES | | Category description |
| min_percentage | DECIMAL(5,2) | NO | | Minimum score for this category |
| max_percentage | DECIMAL(5,2) | NO | | Maximum score for this category |
| color_code | VARCHAR(10) | YES | | Hex color code for UI |
| icon | VARCHAR(50) | YES | | Icon identifier |
| ordinal | TINYINT UNSIGNED | NO | IDX | Display order |
| is_system | TINYINT(1) | YES | | System-defined (global) flag |
| is_active | TINYINT(1) | NO | | Active status |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

**Why Needed:** Schools can define their own performance bands (some use 5 levels, others 3). This enables customized study material recommendations per performance level.

---

## 3. Study Materials & Recommendations

### 3.1 `slb_study_material_types`
**Purpose:** Reference table for types of study materials.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | INT UNSIGNED | NO | PK | Auto-increment primary key |
| code | VARCHAR(30) | NO | UQ | Type code (VIDEO, PDF, etc.) |
| name | VARCHAR(100) | NO | | Display name |
| icon | VARCHAR(50) | YES | | Icon identifier |
| is_active | TINYINT(1) | NO | | Active status |

---

### 3.2 `slb_study_materials`
**Purpose:** Store study resources aligned with topics and performance levels.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| uuid | CHAR(36) | NO | UQ | Unique identifier |
| topic_id | BIGINT UNSIGNED | NO | FK,IDX | Reference to slb_topics |
| material_type_id | INT UNSIGNED | NO | FK,IDX | Reference to material type |
| performance_category_id | INT UNSIGNED | YES | FK,IDX | Target performance level (NULL=all) |
| title | VARCHAR(255) | NO | | Material title |
| description | TEXT | YES | | Detailed description |
| url | VARCHAR(500) | YES | | External URL or internal path |
| media_id | BIGINT UNSIGNED | YES | FK | Reference to sys_media |
| duration_minutes | INT UNSIGNED | YES | | Duration for video/audio |
| difficulty_level | ENUM | YES | | BASIC/INTERMEDIATE/ADVANCED |
| language | VARCHAR(50) | YES | | Content language |
| source | VARCHAR(150) | YES | | Source (Khan Academy, NCERT, etc.) |
| tags | JSON | YES | | Searchable tags |
| view_count | INT UNSIGNED | YES | | View counter |
| avg_rating | DECIMAL(3,2) | YES | | Average user rating |
| is_premium | TINYINT(1) | YES | | Premium content flag |
| is_active | TINYINT(1) | NO | | Active status |
| created_by | BIGINT UNSIGNED | YES | FK | Creator user ID |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |
| deleted_at | TIMESTAMP | YES | | Soft delete timestamp |

**Why Needed:** Students at different performance levels need different study materials. A struggling student needs basic explanatory videos, while an advanced student needs challenge problems.

---

## 4. Topic Dependencies

### 4.1 `slb_topic_dependencies`
**Purpose:** Maps prerequisite relationships between topics (including cross-class).

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| topic_id | BIGINT UNSIGNED | NO | FK,UQ | Current topic |
| prerequisite_topic_id | BIGINT UNSIGNED | NO | FK,UQ,IDX | Required base topic |
| dependency_type | ENUM | NO | | PREREQUISITE/FOUNDATION/RELATED/EXTENSION |
| strength | ENUM | YES | | WEAK/MODERATE/STRONG |
| description | VARCHAR(255) | YES | | Dependency explanation |
| is_active | TINYINT(1) | NO | | Active status |
| created_at | TIMESTAMP | YES | | Record creation timestamp |

**Why Needed:** Critical for root cause analysis. If a student struggles with "Quadratic Equations" in Grade 10, the system can identify that they're weak in "Linear Equations" from Grade 9 and recommend remedial content.

---

## 5. Teaching Status & Scheduling

### 5.1 `slb_teaching_status`
**Purpose:** Tracks syllabus completion status per class/section/subject/topic.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| academic_session_id | BIGINT UNSIGNED | NO | FK,UQ | Academic session |
| class_id | INT UNSIGNED | NO | FK,UQ | Class reference |
| section_id | INT UNSIGNED | NO | FK,UQ | Section reference |
| subject_id | BIGINT UNSIGNED | NO | FK,UQ | Subject reference |
| topic_id | BIGINT UNSIGNED | NO | FK,UQ | Topic at any hierarchy level |
| teacher_id | BIGINT UNSIGNED | NO | FK,IDX | Teacher who marked status |
| status | ENUM | NO | IDX | NOT_STARTED/IN_PROGRESS/COMPLETED/REVISION/SKIPPED |
| completion_percentage | DECIMAL(5,2) | YES | | Progress percentage |
| started_date | DATE | YES | | When teaching started |
| completed_date | DATE | YES | | When topic was completed |
| planned_periods | SMALLINT UNSIGNED | YES | | Planned period count |
| actual_periods | SMALLINT UNSIGNED | YES | | Actual periods taken |
| remarks | VARCHAR(500) | YES | | Teacher notes |
| trigger_quiz | TINYINT(1) | YES | | Auto-trigger quiz flag |
| quiz_triggered_at | TIMESTAMP | YES | | When quiz was triggered |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

**Why Needed:** Core table for syllabus completion tracking. When a teacher marks a topic as complete, this triggers automatic quiz assignment to the class.

---

### 5.2 `slb_syllabus_schedule`
**Purpose:** Planned schedule for teaching topics throughout the academic year.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| academic_session_id | BIGINT UNSIGNED | NO | FK | Academic session |
| class_id | INT UNSIGNED | NO | FK,IDX | Class reference |
| section_id | INT UNSIGNED | YES | FK | Section (NULL=all sections) |
| subject_id | BIGINT UNSIGNED | NO | FK,IDX | Subject reference |
| topic_id | BIGINT UNSIGNED | NO | FK | Topic reference |
| scheduled_start_date | DATE | NO | IDX | Planned start date |
| scheduled_end_date | DATE | NO | IDX | Planned end date |
| assigned_teacher_id | BIGINT UNSIGNED | YES | FK | Assigned teacher |
| planned_periods | SMALLINT UNSIGNED | YES | | Planned periods |
| priority | ENUM | YES | | HIGH/MEDIUM/LOW |
| notes | VARCHAR(500) | YES | | Schedule notes |
| is_active | TINYINT(1) | NO | | Active status |
| created_by | BIGINT UNSIGNED | YES | FK | Creator |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

**Why Needed:** Enables academic planning, tracking schedule adherence, and comparing planned vs actual progress.

---

## 6. Teacher Assignments

### 6.1 `slb_teacher_subject_assignment`
**Purpose:** Assigns teachers to specific class/section/subject combinations.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| academic_session_id | BIGINT UNSIGNED | NO | FK,UQ | Academic session |
| teacher_id | BIGINT UNSIGNED | NO | FK,UQ,IDX | Teacher reference |
| class_id | INT UNSIGNED | NO | FK,UQ,IDX | Class reference |
| section_id | INT UNSIGNED | NO | FK,UQ | Section reference |
| subject_id | BIGINT UNSIGNED | NO | FK,UQ | Subject reference |
| effective_from | DATE | NO | UQ | Assignment start date |
| effective_to | DATE | YES | | Assignment end date |
| periods_per_week | TINYINT UNSIGNED | YES | | Weekly periods |
| is_primary | TINYINT(1) | YES | | Primary vs substitute |
| timetable_slot_ids | JSON | YES | | Linked timetable slots |
| is_active | TINYINT(1) | NO | | Active status |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

**Why Needed:** Links teachers to their class responsibilities, enables timetable integration, and supports substitute teacher management.

---

## 7. Question Ownership

### 7.1 `sch_question_ownership`
**Purpose:** Tracks question ownership and visibility per school.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| question_id | BIGINT UNSIGNED | NO | FK,UQ | Reference to sch_questions |
| ownership_type | ENUM | NO | | GLOBAL/SCHOOL_CUSTOM/TEACHER_PRIVATE |
| created_by_teacher_id | BIGINT UNSIGNED | YES | FK | Creator teacher |
| is_shareable | TINYINT(1) | YES | | Can be shared flag |
| approved_for_sharing | TINYINT(1) | YES | | Approved for sharing |
| approved_by | BIGINT UNSIGNED | YES | FK | Approver |
| approved_at | TIMESTAMP | YES | | Approval timestamp |
| created_at | TIMESTAMP | YES | | Record creation timestamp |

**Why Needed:** Schools can create their own custom questions that remain private to that school, while global questions are shared across all schools using the same book/curriculum.

---

## 8. Quiz Auto-Assignment

### 8.1 `sch_quiz_topic_jnt`
**Purpose:** Links quizzes to topics for auto-assignment on topic completion.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| quiz_id | BIGINT UNSIGNED | NO | FK,UQ | Reference to sch_quizzes |
| topic_id | BIGINT UNSIGNED | NO | FK,UQ | Reference to slb_topics |
| auto_assign_on_completion | TINYINT(1) | YES | | Auto-assign flag |
| created_at | TIMESTAMP | YES | | Record creation timestamp |

---

### 8.2 `sch_quiz_auto_assignments`
**Purpose:** Logs automatic quiz assignments triggered by topic completion.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| quiz_id | BIGINT UNSIGNED | NO | FK,IDX | Reference to sch_quizzes |
| teaching_status_id | BIGINT UNSIGNED | NO | FK | Trigger teaching status |
| class_id | INT UNSIGNED | NO | FK,IDX | Class reference |
| section_id | INT UNSIGNED | NO | FK | Section reference |
| assigned_at | TIMESTAMP | NO | | Assignment timestamp |
| due_date | DATE | YES | | Due date |
| status | ENUM | YES | | PENDING/ACTIVE/COMPLETED/CANCELLED |
| total_students | INT UNSIGNED | YES | | Total students count |
| completed_count | INT UNSIGNED | YES | | Completed count |

**Why Needed:** Automates the quiz assignment workflow. When a teacher marks a topic complete, the pre-configured quiz is automatically assigned to all students in that class/section.

---

## 9. Offline Exam Support

### 9.1 `sch_offline_exams`
**Purpose:** Extends exam table with offline-specific settings.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| exam_id | BIGINT UNSIGNED | NO | FK,UQ | Reference to sch_exams |
| exam_mode | ENUM | NO | | ONLINE/OFFLINE_QB/OFFLINE_CUSTOM |
| question_paper_generated | TINYINT(1) | YES | | Paper generated flag |
| question_paper_url | VARCHAR(500) | YES | | Generated paper URL |
| answer_key_url | VARCHAR(500) | YES | | Answer key URL |
| marking_scheme_url | VARCHAR(500) | YES | | Marking scheme URL |
| manual_entry_enabled | TINYINT(1) | YES | | Manual marks entry |
| analytics_depth | ENUM | YES | | FULL/PARTIAL/MARKS_ONLY |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

**Why Needed:** Supports both Question Bank-based offline exams (full analytics) and teacher-created custom papers (limited analytics).

---

### 9.2 `sch_offline_exam_marks`
**Purpose:** Stores manually entered marks for offline exams.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| exam_id | BIGINT UNSIGNED | NO | FK,UQ | Reference to sch_exams |
| student_id | BIGINT UNSIGNED | NO | FK,UQ,IDX | Student reference |
| question_id | BIGINT UNSIGNED | YES | FK | Question (for QB exams) |
| question_number | VARCHAR(20) | YES | UQ | Question number (e.g., '1a') |
| max_marks | DECIMAL(6,2) | NO | | Maximum marks |
| marks_obtained | DECIMAL(6,2) | YES | | Marks obtained |
| evaluated_by | BIGINT UNSIGNED | YES | FK | Evaluator teacher |
| evaluated_at | TIMESTAMP | YES | | Evaluation timestamp |
| remarks | VARCHAR(255) | YES | | Evaluator remarks |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

---

## 10. Behavioral Analytics

### 10.1 `sch_attempt_behavior_log`
**Purpose:** Captures detailed behavioral data during quiz/exam attempts.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| attempt_id | BIGINT UNSIGNED | NO | FK,IDX | Reference to sch_attempts |
| question_id | BIGINT UNSIGNED | NO | FK,IDX | Question being answered |
| event_type | ENUM | NO | IDX | VIEW/ANSWER/CHANGE/SKIP/BOOKMARK/REVIEW/SUBMIT |
| event_timestamp | TIMESTAMP | NO | | Event time |
| time_spent_seconds | INT UNSIGNED | YES | | Time on this question |
| answer_changes_count | TINYINT UNSIGNED | YES | | Number of answer changes |
| confidence_indicator | ENUM | YES | | LOW/MEDIUM/HIGH (derived) |
| hesitation_detected | TINYINT(1) | YES | | Long pause flag |
| device_info | JSON | YES | | Browser/device details |
| ip_address | VARCHAR(45) | YES | | IP address |

**Why Needed:** Enables confidence level detection, hesitation analysis, and behavioral pattern recognition for understanding student learning challenges.

---

## 11. Student Performance Tracking

### 11.1 `sch_student_topic_performance`
**Purpose:** Aggregated performance summary per student per topic.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| student_id | BIGINT UNSIGNED | NO | FK,UQ,IDX | Student reference |
| topic_id | BIGINT UNSIGNED | NO | FK,UQ,IDX | Topic reference |
| academic_session_id | BIGINT UNSIGNED | NO | FK,UQ | Academic session |
| total_questions_attempted | INT UNSIGNED | YES | | Total attempts |
| correct_answers | INT UNSIGNED | YES | | Correct count |
| accuracy_percentage | DECIMAL(5,2) | YES | | Accuracy % |
| avg_time_per_question | INT UNSIGNED | YES | | Average time (seconds) |
| performance_category_id | INT UNSIGNED | YES | FK,IDX | Performance level |
| confidence_score | DECIMAL(5,2) | YES | | Derived confidence (0-100) |
| needs_revision | TINYINT(1) | YES | | Revision needed flag |
| last_assessed_date | DATE | YES | | Last assessment date |
| trend | ENUM | YES | | IMPROVING/STABLE/DECLINING |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

---

### 11.2 `sch_student_weak_areas`
**Purpose:** Identifies and tracks student weak areas with root cause analysis.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| student_id | BIGINT UNSIGNED | NO | FK,IDX | Student reference |
| academic_session_id | BIGINT UNSIGNED | NO | FK | Academic session |
| topic_id | BIGINT UNSIGNED | NO | FK,IDX | Weak topic |
| weakness_severity | ENUM | NO | | MILD/MODERATE/SEVERE |
| root_cause_topic_id | BIGINT UNSIGNED | YES | FK | Base topic causing weakness |
| identified_date | DATE | NO | | When identified |
| addressed | TINYINT(1) | YES | | Addressed flag |
| addressed_date | DATE | YES | | When addressed |
| remarks | VARCHAR(500) | YES | | Notes |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

**Why Needed:** Core table for gap analysis. Links current weaknesses to their root causes in prerequisite topics, enabling targeted remediation.

---

## 12. Recommendations Engine

### 12.1 `sch_student_recommendations`
**Purpose:** Stores personalized recommendations for students.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| student_id | BIGINT UNSIGNED | NO | FK,IDX | Student reference |
| recommendation_type | ENUM | NO | IDX | TOPIC_FOCUS/STUDY_MATERIAL/PRACTICE/REVISION/REMEDIAL |
| priority | ENUM | YES | | HIGH/MEDIUM/LOW |
| title | VARCHAR(255) | NO | | Recommendation title |
| description | TEXT | YES | | Detailed description |
| topic_id | BIGINT UNSIGNED | YES | FK | Related topic |
| study_material_id | BIGINT UNSIGNED | YES | FK | Recommended material |
| related_quiz_id | BIGINT UNSIGNED | YES | FK | Recommended quiz |
| status | ENUM | YES | IDX | PENDING/VIEWED/IN_PROGRESS/COMPLETED/DISMISSED |
| generated_at | TIMESTAMP | NO | | Generation time |
| viewed_at | TIMESTAMP | YES | | When viewed |
| completed_at | TIMESTAMP | YES | | When completed |
| expires_at | DATE | YES | | Expiry date |
| generated_by | ENUM | YES | | SYSTEM/TEACHER |

---

### 12.2 `sch_teacher_recommendations`
**Purpose:** Recommendations for teachers about students/classes needing attention.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| teacher_id | BIGINT UNSIGNED | NO | FK,IDX | Teacher reference |
| class_id | INT UNSIGNED | NO | FK,IDX | Class reference |
| section_id | INT UNSIGNED | NO | FK | Section reference |
| recommendation_type | ENUM | NO | | CLASS_FOCUS/STUDENT_ATTENTION/TOPIC_REVISION/ASSESSMENT_ADJUST |
| priority | ENUM | YES | | HIGH/MEDIUM/LOW |
| title | VARCHAR(255) | NO | | Recommendation title |
| description | TEXT | YES | | Details |
| affected_students_count | INT UNSIGNED | YES | | Count of affected students |
| affected_student_ids | JSON | YES | | Array of student IDs |
| topic_id | BIGINT UNSIGNED | YES | FK | Related topic |
| status | ENUM | YES | | PENDING/VIEWED/ACTIONED/DISMISSED |
| generated_at | TIMESTAMP | NO | | Generation time |
| actioned_at | TIMESTAMP | YES | | Action timestamp |
| action_notes | TEXT | YES | | Notes on action taken |

---

## 13. Aggregation Tables

### 13.1 `sch_daily_performance_summary`
**Purpose:** Daily aggregated performance data for efficient reporting.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| summary_date | DATE | NO | UQ,IDX | Summary date |
| academic_session_id | BIGINT UNSIGNED | NO | UQ | Academic session |
| class_id | INT UNSIGNED | NO | UQ,IDX | Class reference |
| section_id | INT UNSIGNED | YES | UQ | Section (NULL=all) |
| subject_id | BIGINT UNSIGNED | NO | UQ,IDX | Subject reference |
| topic_id | BIGINT UNSIGNED | YES | UQ | Topic (NULL=all topics) |
| total_students | INT UNSIGNED | YES | | Total eligible students |
| students_attempted | INT UNSIGNED | YES | | Students who attempted |
| avg_score_percentage | DECIMAL(5,2) | YES | | Average score % |
| pass_count | INT UNSIGNED | YES | | Students who passed |
| fail_count | INT UNSIGNED | YES | | Students who failed |
| high_performers | INT UNSIGNED | YES | | Above 80% count |
| low_performers | INT UNSIGNED | YES | | Below 40% count |
| created_at | TIMESTAMP | YES | | Record creation timestamp |

**Why Needed:** Enables fast dashboard queries without real-time aggregation of large attempt tables.

---

### 13.2 `sch_monthly_performance_agg`
**Purpose:** Monthly aggregated data for city/state level reporting.

| Column | Type | Null | Key | Description |
|--------|------|------|-----|-------------|
| id | BIGINT UNSIGNED | NO | PK | Auto-increment primary key |
| year_month | CHAR(7) | NO | UQ,IDX | YYYY-MM format |
| academic_session_id | BIGINT UNSIGNED | NO | UQ | Academic session |
| class_id | INT UNSIGNED | NO | UQ,IDX | Class reference |
| subject_id | BIGINT UNSIGNED | NO | UQ,IDX | Subject reference |
| topic_id | BIGINT UNSIGNED | YES | UQ | Topic (NULL=all) |
| total_assessments | INT UNSIGNED | YES | | Assessment count |
| total_students | INT UNSIGNED | YES | | Student count |
| total_attempts | INT UNSIGNED | YES | | Attempt count |
| avg_score_percentage | DECIMAL(5,2) | YES | | Average score % |
| median_score | DECIMAL(5,2) | YES | | Median score |
| std_deviation | DECIMAL(5,2) | YES | | Standard deviation |
| pass_rate | DECIMAL(5,2) | YES | | Pass rate % |
| created_at | TIMESTAMP | YES | | Record creation timestamp |
| updated_at | TIMESTAMP | YES | | Last update timestamp |

---

## 14. Modified Tables

### Columns added to `slb_lessons`:
- `book_chapter_ref` - Reference to book chapter
- `scheduled_month` - Planned teaching month

### Columns added to `slb_topics`:
- `base_topic_id` - Primary prerequisite from previous class
- `is_assessable` - Can be assessed flag

### Columns added to `sch_questions`:
- `is_school_specific` - School-specific flag
- `visibility` - GLOBAL/SCHOOL_ONLY/PRIVATE
- `book_id` - Reference to slb_books
- `book_page_ref` - Page reference

### Columns added to `sch_quizzes`:
- `auto_assign_on_topic_completion` - Auto-assignment flag
- `objective_only` - Objective questions only flag

### Columns added to `sch_assessments`:
- `can_attempt_at_home` - Home attempt allowed
- `requires_proctoring` - Proctoring required flag

### Columns added to `sch_exams`:
- `exam_mode` - ONLINE/OFFLINE/HYBRID

### Columns added to `sch_attempts`:
- `confidence_level` - Derived confidence score
- `performance_category_id` - Performance category reference

---

## Summary Statistics

| Category | New Tables | Modified Tables |
|----------|------------|-----------------|
| Book Management | 5 | 1 |
| Performance Categories | 1 | - |
| Study Materials | 2 | - |
| Topic Dependencies | 1 | 1 |
| Teaching Status | 2 | - |
| Teacher Assignments | 1 | - |
| Question Ownership | 1 | 1 |
| Quiz Auto-Assignment | 2 | 1 |
| Offline Exam | 2 | 1 |
| Behavioral Analytics | 1 | - |
| Performance Tracking | 2 | 1 |
| Recommendations | 2 | - |
| Aggregation | 2 | - |
| **Total** | **24** | **6** |

---

**End of Data Dictionary**
