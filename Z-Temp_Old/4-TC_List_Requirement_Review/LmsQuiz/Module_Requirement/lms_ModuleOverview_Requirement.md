# LmsQuiz Module — Business Requirements Overview

## Module Purpose

The LmsQuiz Module is the complete quiz management engine of the school's LMS platform. It enables teachers and academic coordinators to create, configure, assign, and analyze quizzes across the curriculum hierarchy.

It covers the full quiz lifecycle: defining assessment types and difficulty distribution rules, creating quizzes scoped to specific class-subject-lesson-topic combinations, assigning questions from the question bank, allocating quizzes to students (individually or by class/section/group), tracking student attempts and scores, and generating detailed performance reports.

This module works in tandem with the StudentPortal module (which handles student-facing attempt interfaces) and the QuestionBank module (which supplies the question pool).

## Default Data Load

The main Quiz Management page is a tab-based single-page interface. When the user navigates to `lms-quize/quize`, the `LmsQuizController@index()` method loads all 8 tabs simultaneously:

1. **Dashboard** — BI widgets, recent quizzes, charts (subject breakdown, score distribution, monthly activity)
2. **Difficulty Distribution Config** — Paginated list of difficulty configs with usage type filters
3. **Assessment Types** — Paginated list of assessment type codes with usage type filters
4. **Quiz Creation** — Paginated list of quizzes with search/status/type/topic filters
5. **Quiz Questions** — Paginated list of quiz-question mappings with search/quiz filters
6. **Quiz Allocation** — Paginated list of allocations with quiz/target filters
7. **Quiz Summary** — Per-allocation summary with attempt counts and assigned student counts
8. **Activity Log** — Paginated proctoring/behavioral event log filtered by event type and date range

All tabs are permission-gated. Dashboard stats and dropdowns (class-section, subject, topic, assessment type) are computed fresh on each page load.

A separate Reports page at `lms-quize/quiz-reports` provides 6 additional analytics tabs for deeper performance analysis.

---

## Core Structure — Master Configuration

**Difficulty Distribution Configs**
Rules defining what percentage of questions at each complexity level (Easy/Medium/Hard) and question type should appear in a quiz. Supports system-generated quiz auto-configuration.

**Assessment Types**
Categorization of quizzes into types like Challenge, Enrichment, Practice, Revision, Re-Test, Diagnostic, Remedial — mapped to question usage types (QUIZ, QUEST, ONLINE_EXAM).

---

## Quiz Creation & Management

This section covers the actual quiz creation workflow.

**Quiz Master**
The core entity linking academic hierarchy (session → class → subject → lesson → topic) with quiz settings: duration, total marks, passing percentage, timer enforcement, randomization, multiple attempts, negative marking, difficulty config, and visibility settings (show correct answer, show explanation, show result immediately).

**Quiz Questions**
Junction table linking quizzes to questions from the Question Bank with ordinal positioning and optional marks override. Includes a difficulty builder interface for auto-selecting questions based on distribution rules.

**Quiz Allocations**
Assignment of quizzes to individual students, classes, sections, or entity groups with publish/due/cutoff dates and auto-publish result scheduling.

---

## Analytics — Reports and Dashboards

This section provides performance analysis across multiple dimensions.

**Dashboard**
BI widgets (total quizzes, published, questions, allocations, attempts), charts (score distribution, monthly activity, subject breakdown, status breakdown), and recent quiz list.

**Quiz Summary**
Per-allocation tabular view with submitted/in-progress counts and total assigned students.

**Activity Log**
Immutable audit trail of student behavior events (focus loss, tab switch, etc.) during quiz attempts.

**Reports (6 Tabs)**
- Class Performance Report
- Teacher Monthly Report
- Student Performance Summary
- Student Detailed Assessment
- Periodic Detail Report
- Current Class Performance

---

## Requirements

- The system MUST provide a tab-based single-page interface for quiz management
- The system MUST support creating quizzes scoped to academic session, class, subject, lesson, and topic hierarchy
- The system MUST support multiple assessment types (Challenge, Enrichment, Practice, Revision, Re-Test, Diagnostic, Remedial)
- The system MUST support difficulty distribution configs with per-complexity-level and per-question-type percentage rules
- The system MUST allow assigning questions from the Question Bank with ordinal positioning
- The system MUST support a difficulty builder that auto-selects questions matching distribution rules
- The system MUST support allocating quizzes to classes, sections, student groups, or individual students
- The system MUST enforce timer, randomization, multiple attempts, and negative marking settings
- The system MUST support publishing/unpublishing quizzes and allocations
- The system MUST provide dashboard widgets with quiz stats, score distribution, monthly activity, and subject breakdown
- The system MUST provide six report types: class performance, teacher monthly, student summary, student detailed, periodic detail, current class
- The system MUST maintain an immutable activity log for proctoring events during quiz attempts
- The system MUST support soft-delete and restore for all entities
- The system MUST enforce role-based access control (RBAC) via policies for all quiz operations

---

## Dependencies module and tables

### Primary Tables

| Table Name | Description | Module Area |
|-----------|-------------|-------------|
| `lms_quizzes` | Core quiz master with settings, hierarchy, and status | Quiz Creation |
| `lms_quiz_questions` | Junction: quizzes → questions with ordinal and marks override | Quiz Questions |
| `lms_quiz_allocations` | Quiz assignment to classes/sections/groups/students | Quiz Allocation |
| `lms_assessment_types` | Quiz type categorization (Challenge, Practice, etc.) | Assessment Types |
| `lms_difficulty_distribution_configs` | Difficulty balancing rule headers | Difficulty Config |
| `lms_difficulty_distribution_details` | Per-question-type/complexity percentage rules | Difficulty Config |
| `lms_attempt_activity_logs` | Immutable proctoring event log | Activity Log |
| `lms_attempt_activity_event_types` | Master list of behavioral event types (Focus Lost, Tab Switch, etc.) | Activity Log |
| `lms_quiz_quest_attempts` | Student attempt records (shared with Quests and Exams) | Quiz Summary |
| `lms_quiz_quest_attempt_answers` | Per-question student responses | Quiz Summary |
| `lms_quiz_quest_results` | Final evaluated results for quiz attempts | Quiz Summary |

### External Module Dependencies

| Module | Nature of Dependency |
|--------|---------------------|
| **SchoolSetup** | Required — Provides `Class`, `Subject`, `Section`, `ClassSection`, `AcademicSession` models |
| **Syllabus** | Required — Provides `Lesson`, `Topic`, `TopicLevelType`, `ComplexityLevel`, `QuestionType` models |
| **QuestionBank** | Required — Provides `QuestionBank`, `QuestionUsageType`, `QuestionPerformanceCategoryJnt` models |
| **StudentProfile** | Required — Provides `Student`, `StudentAcademicSession` models |
| **StudentPortal** | Required — Provides `QuizQuestAttempt`, `QuizQuestResult`, `QuizQuestAttemptAnswer`, `AttemptActivityLog`, `AttemptActivityEventType` models |
| **Prime** | Required — Provides `AcademicSession`, `Dropdown`, `User` models |
