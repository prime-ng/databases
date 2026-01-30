# LMS Online Exam Module - Data Dictionary
**Version:** 1.0
**Date:** 2026-01-29

## Overview
This module handles the complete lifecycle of Online and Offline exams, including configuration, scheduling, execution, proctoring, evaluation, and result publishing. It integrates with the shared Question Bank and uses a unified Assessment architecture.

## 1. Common Configurations

### `lms_difficulty_distribution_configs`
Defines templates for balancing exam difficulty (e.g., "Standard Balanced" = 30% Easy, 50% Medium, 20% Hard).
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `code` | VARCHAR(50) | Unique code, e.g., 'STD_QUIZ_EASY' |
| `name` | VARCHAR(100) | Display name |
| `description` | VARCHAR(255) | Description of the distribution |
| `usage_type_id` | BIGINT FK | Links to `qns_question_usage_type` |
| `is_active` | TINYINT | 1=Active, 0=Inactive |

### `lms_difficulty_distribution_details`
Breakdown of difficulty rules for a config.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `difficulty_config_id` | BIGINT FK | Parent config |
| `question_type_id` | INT FK | Question type (MCQ, Descriptive) |
| `complexity_level_id` | INT FK | Complexity (Easy, Medium, Hard) |
| `min_percentage` | DECIMAL | Minimum % of total questions/marks |
| `max_percentage` | DECIMAL | Maximum % of total questions/marks |
| `marks_per_question` | DECIMAL | Default marks override for this bucket |

### `lms_assessment_types`
Categorizes exams and assessments (e.g., Half-Yearly, Final, Unit Test).
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `code` | VARCHAR(50) | Unique code (e.g., 'ANNUAL') |
| `name` | VARCHAR(100) | Display name |
| `assessment_usage_type_id` | BIGINT FK | Type context (EXAM, QUIZ) |

## 2. Exam Configuration

### `lms_exams`
The central table for Exam definitions.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `uuid` | BINARY(16) | Global Unique ID |
| `code` | VARCHAR | Exam Code |
| `title` | VARCHAR | Exam Title |
| `exam_mode` | ENUM | 'ONLINE' or 'OFFLINE' |
| `academic_session_id` | BIGINT FK | Session context |
| `total_marks` | DECIMAL | Total maximum marks |
| `passing_percentage` | DECIMAL | Percentage required to pass |
| `duration_minutes` | INT | Time limit in minutes |
| `is_proctored` | TINYINT | Enable proctoring? |
| `browser_lock_required` | TINYINT | Require secure browser? |
| `publish_result_type` | ENUM | 'IMMEDIATE', 'SCHEDULED', 'MANUAL' |
| `status` | ENUM | 'DRAFT', 'PUBLISHED', 'CONCLUDED' |

### `lms_exam_scopes`
Defines the syllabus coverage.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `exam_id` | BIGINT FK | Parent Exam |
| `subject_id` | BIGINT FK | Subject covered |
| `lesson_id` | INT FK | Specific lesson (Optional) |
| `topic_id` | BIGINT FK | Specific topic (Optional) |
| `weightage_percent` | DECIMAL | Contribution to total exam |

### `lms_exam_blueprints`
Structural design of the exam papers (Sections/Parts).
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `exam_id` | BIGINT FK | Parent Exam |
| `section_name` | VARCHAR | Name (e.g., 'Section A') |
| `question_type_group` | ENUM | 'MCQ', 'DESCRIPTIVE', 'MIXED' |
| `total_questions` | INT | Number of questions in this section |
| `total_marks` | DECIMAL | Total marks for this section |

### `lms_exam_questions`
Actual questions linked to the exam.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `exam_id` | BIGINT FK | Parent Exam |
| `blueprint_id` | BIGINT FK | Section/Blueprint linkage |
| `question_id` | BIGINT FK | Link to Question Bank |
| `ordinal` | INT | Sequence number |
| `marks` | DECIMAL | Marks for this specific instance |
| `is_compulsory` | TINYINT | If the question is mandatory |

### `lms_exam_allocations`
Assignments of exams to learners.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `exam_id` | BIGINT FK | Parent Exam |
| `allocation_type` | ENUM | 'CLASS', 'SECTION', 'GROUP', 'STUDENT' |
| `target_id` | BIGINT | ID of the allocated entity |
| `scheduled_start_at` | DATETIME | Override start time |
| `scheduled_end_at` | DATETIME | Override end time |

## 3. Execution & Results

### `lms_student_attempts`
Tracks a student's session.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `uuid` | BINARY(16) | Unique attempt ID |
| `student_id` | BIGINT FK | Student taking the exam |
| `started_at` | DATETIME | Start time |
| `submitted_at` | DATETIME | Submission time |
| `status` | ENUM | 'IN_PROGRESS', 'SUBMITTED', 'EVALUATED' |
| `violation_count` | INT | Number of proctoring flags |
| `offline_paper_uploaded_id`| BIGINT FK | Scanned paper (Offline mode) |

### `lms_exam_answers`
Student responses and evaluation details.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `attempt_id` | BIGINT FK | Parent Attempt |
| `question_id` | BIGINT FK | Question answered |
| `selected_option_id` | BIGINT | Chosen option (MCQ) |
| `descriptive_answer` | TEXT | Written answer |
| `marks_obtained` | DECIMAL | Marks awarded |
| `is_evaluated` | TINYINT | Evaluation status |
| `evaluated_by` | BIGINT FK | Teacher who graded (if manual) |

### `lms_exam_results`
Final report card data.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `exam_id` | BIGINT FK | Parent Exam |
| `student_id` | BIGINT FK | Student |
| `total_marks_obtained` | DECIMAL | Final Score |
| `percentage` | DECIMAL | Percentage Score |
| `grade_obtained` | VARCHAR | Grade (A, B, C...) |
| `result_status` | ENUM | 'PASS', 'FAIL' |
| `is_published` | TINYINT | Visibility to student |

### `lms_exam_grievances`
Dispute resolution for grading.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `exam_result_id` | BIGINT FK | Related Result |
| `question_id` | BIGINT FK | Disputed Question |
| `grievance_text` | TEXT | Student's complaint |
| `status` | ENUM | 'OPEN', 'RESOLVED' |
| `marks_changed` | TINYINT | Did the score change? |
| `new_marks` | DECIMAL | Adjusted marks |

## 4. Analytics

### `lms_attempt_activity_logs`
Security and behavior logs.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique ID |
| `attempt_id` | BIGINT FK | Parent Attempt |
| `activity_type` | ENUM | Event (Focus Lost, etc.) |
| `activity_data` | JSON | Contextual details |
| `occurred_at` | TIMESTAMP | Timestamp of event |
