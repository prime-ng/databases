# Syllabus & Exam Management Module - Schema Help & Usage Guide

**Version:** 1.5
**Document Purpose:** This guide explains the purpose, structure, and application usage for every table and field in the Syllabus & Exam Management Module (v1.5).

---

## 1. Core Syllabus Structure

### `slb_lessons`
**Purpose:** Represents high-level chapters or units in a subject (e.g., "Chapter 1: Real Numbers").
- **Key Fields:**
  - `uuid`: Unique Reference for analytics. *Usage: Tracking lesson progress across sessions.*
  - `code`: Auto-generated code (e.g., `MTH-10-01`). *Usage: System-wide referencing.*
  - `name`: Display name (e.g., "Real Numbers").
  - `ordinal`: Ordering number (1, 2, 3..). *Usage: Sorting chapters in the UI.*
  - `learning_objectives`: JSON array. *Usage: Showing "What you will learn" on the lesson dashboard.*
  - `resources_json`: Links to general chapter resources (PDFs, Videos).
  - `book_chapter_ref`: Links ERP lesson to physical textbook chapter (e.g., "Chapter 2"). *Usage: "Open your Math book to Chapter 2".*
  - `scheduled_year_week`: Planning when this lesson should be taught. *Usage: Academic calendar view.*
- **Application Workflow:**
  - **Admin/Teacher:** Defines the syllabus at the start of the year.
  - **Student:** Sees "Chapter 1" on their dashboard and tracks progress.

### `slb_topics`
**Purpose:** The granular building blocks of the syllabus. Supports unlimited hierarchy (Topic > Sub-topic > Micro-topic).
- **Key Fields:**
  - `parent_id`: Parent topic ID. *Usage: Creating the tree structure.*
  - `path` & `path_names`: Materialized path (e.g., `/1/4/9/`). *Usage: Fast breadcrumb generation "Math > Algebra > Linear Eq".*
  - `level`: Hierarchy depth (0=Root, 1=Sub). *Usage: UI indentation and filtering.*
  - `prerequisite_topic_ids`: JSON array of dependencies. *Usage: Warning "You need to finish Logarithms before starting Calculus".*
  - `is_assessable`: If true, questions can be linked to this topic. *Usage: Preventing questions on abstract containers.*
  - `base_topic_id`: (Removed in v1.5, see `slb_topic_dependencies`).
- **Application Workflow:**
  - **Curriculum Team:** Breaks down chapters into teachable chunks.
  - **Assessment:** Questions are tagged to specific Micro-topics for granular weakness analysis.

---

## 2. Competency Framework (NEP 2020)

### `slb_competency_types`
**Purpose:** Categorizes competencies (e.g., "Knowledge", "Skill", "Attitude").
- **Application Workflow:** Used in reports to show "Skill-based" vs "Knowledge-based" performance.

### `slb_competencies`
**Purpose:** Skills or outcomes a student must master, independent of topics (e.g., "Critical Thinking", "Data Interpretation").
- **Key Fields:**
  - `competency_type_id`: Links to type.
  - `domain`: Educational domain (Cognitive/Psychomotor). *Usage: Analytics grouping.*
  - `nep_framework_ref`: Official NEP code. *Usage: Govt compliance reporting.*
  - `learning_outcome_code`: CBSE/Board specific outcome code.
- **Application Workflow:**
  - **Report Card:** Instead of just "Math: 80%", show "Critical Thinking: A".

### `slb_topic_competency_jnt`
**Purpose:** Maps Topics to Competencies.
- **Key Fields:**
  - `weightage`: How much this topic contributes to the skill.
- **Application Workflow:**
  - **Auto-Calculation:** If you tackle "Linear Equations", you are building "Algebraic Reasoning" competency.

---

## 3. Question Taxonomies & Metadata

### `slb_bloom_taxonomy`
**Purpose:** Classifies questions by cognitive level (Remember, Understand, Apply, etc.).
- **Application Workflow:** Teachers ensure exam papers have a balanced mix (e.g., not just memorization questions).

### `slb_cognitive_skill`
**Purpose:** More detailed skills under Bloom's (e.g., "Recall Details" under Remembering).
- **Application Workflow:** Detailed gap analysis.

### `slb_ques_type_specificity`
**Purpose:** Context for question usage (e.g., "Homework", "In-Class", "Exam").
- **Application Workflow:** Filtering questions when generating a "Homework" sheet vs a "Unit Test".

### `slb_complexity_level`
**Purpose:** Difficulty rating (Easy, Medium, Hard).
- **Application Workflow:** Adaptive testing algorithms use this to serve harder questions if the student answers correctly.

### `slb_question_types`
**Purpose:** Defines the format (MCQ, Fill in Blank, Match Column).
- **Key Fields:**
  - `auto_gradable`: Boolean. *Usage: Tells the system if it can mark this instantly.*
- **Application Workflow:** UI renders different input components (Radio buttons vs Text area) based on this.

### `slb_question_types`
**Purpose:** Defines the format (MCQ, Fill in Blank, Match Column).
- **Key Fields:**
  - `auto_gradable`: Boolean. *Usage: Tells the system if it can mark this instantly.*
- **Application Workflow:** UI renders different input components (Radio buttons vs Text area) based on this.

| Bloom Taxonomy Level	    | Cognitive Skill	        | Question Type Specificity
|---------------------------|---------------------------|---------------------------
| Remembering	            | Recall	                | Direct Recall
|                           |                           | Match the Following
|                           | Interpretation	        | Direct Recall
|                           | Comprehension	            | Direct Recall
|                           |                           | Match the Following
|---------------------------|---------------------------|---------------------------
| Understanding	            | Comprehension	            | Scenario-Based
|                           |                           | Match the Following
|                           | Interpretation	        | Scenario-Based
|                           |                           | Match the Following
|                           | Reasoning	                | Assertion-Reason
|---------------------------|---------------------------|---------------------------
| Applying	                | Application	            | Scenario-Based
|                           |                           | Case-study based
|                           | Problem-solving	        | Scenario-Based
|                           |                           | Case-study based
|                           | Critical Thinking	        | Scenario-Based
|---------------------------|---------------------------|---------------------------
| Analyzing	                | Analysis	                | Case Study Based
|                           |                           | Assertion-Reason
|                           | Interpretation	        | Assertion-Reason
|                           |                           | Scenario-Based
|                           | Critical Thinking	        | Case Study Based
|                           |                           | Assertion-Reason
|---------------------------|---------------------------|---------------------------
| Evaluating	            | Evaluation	            | Assertion-Reason
|                           |                           | Case Study Based
|                           | Reasoning	                | Assertion-Reason
|                           |                           | Scenario-Based
|                           | Critical Thinking	        | Assertion-Reason
|                           |                           | Case Study Based
|---------------------------|---------------------------|---------------------------
| Creating	                | Synthesis	                | Case Study Based
|                           |                           | Scenario-Based
|                           | Problem-solving	        | Case Study Based
|                           | Critical Thinking	        | Case Study Based
|                           |                           | Scenario-Based
|---------------------------|---------------------------|---------------------------

---

## 4. Question Bank Management

### `sch_questions`
**Purpose:** The central repository for all assessment items.
- **Key Fields:**
  - `stem`: The actual question text.
  - `is_school_specific`: If true, only visible to this school. *Usage: Privacy for custom questions.*
  - `visibility`: 'GLOBAL', 'SCHOOL_ONLY', 'PRIVATE'.
  - `book_page_ref`: Links question to a textbook page. *Usage: "Read page 45 to answer this".*
- **Application Workflow:**
  - **Question Bank:** Teachers search/filter these to build quizzes.

### `sch_question_options`
**Purpose:** Choices for MCQ-style questions.
- **Key Fields:**
  - `is_correct`: Boolean.
  - `feedback`: Explanation shown if chosen.
- **Application Workflow:** Displayed as selectable options in the exam interface.

### `sch_question_media`
**Purpose:** Images/Audio/Video attached to questions.
- **Application Workflow:** Displaying a diagram for a Geometry question.

### `sch_question_tags` & `sch_question_tag_jnt`
**Purpose:** Flexible tagging (e.g., "Competitive Exam", "Olympiad").
- **Application Workflow:** Advanced search filters in Question Bank.

### `sch_question_versions`
**Purpose:** Tracks history of changes to a question.
- **Key Fields:**
  - `data`: JSON snapshot.
- **Application Workflow:** If a question had an error during an exam, admins can see exactly what the text was at that time.

### `sch_question_ownership`
**Purpose:** Manages sharing permissions for custom questions.
- **Application Workflow:** A teacher creates a question -> Principal approves it -> It becomes available to the whole school.

### `sch_question_pools` & `sch_question_pool_questions`
**Purpose:** Dynamic groups of questions (e.g., "Grade 10 Algebra Hard Pool").
- **Application Workflow:** An exam can pinpoint a "Pool" instead of specific questions, so every student gets a different random set from that pool.

---

## 5. Assessments, Quizzes & Exams

### `sch_quizzes`
**Purpose:** Low-stakes practice/homework.
- **Key Fields:**
  - `auto_assign_on_topic_completion`: *Usage: Zero-touch homework assignment.*
  - `quiz_type`: Diagnostic/Practice.
- **Application Workflow:** Automatically assigned when a topic is marked "Completed" in class.

### `sch_assessments`
**Purpose:** Structured evaluations (Unit Tests).
- **Key Fields:**
  - `requires_proctoring`: *Usage: Enforce full-screen mode.*
  - `can_attempt_at_home`: Permissions.

### `sch_exams`
**Purpose:** High-stakes formal exams (Mid-term, Finals).
- **Key Fields:**
  - `exam_mode`: ONLINE / OFFLINE_QB / HYBRID.
- **Application Workflow:** The central event for report card generation.

### `sch_assessment_sections`
**Purpose:** Parts of an exam (Part A, Part B).
- **Application Workflow:** Grouping questions logically (e.g., "Reading Comprehension" section).

### `sch_assessment_items` / `sch_exam_items`
**Purpose:** The actual questions inside a specific assessment/exam instance.
- **Key Fields:**
  - `marks`: Override default marks for this specific exam.

### `sch_quiz_assessment_map`
**Purpose:** Linking quizzes to assessments (e.g., a Quiz contributing to Formative Assessment score).

### `sch_assessment_assignments`
**Purpose:** Who takes the test? (Class 10-A, or just 5 specific students).
- **Application Workflow:** Assigning a re-test only to students who failed.

### `sch_assessment_assignment_rules`
**Purpose:** Constraints (e.g., "Must have 75% attendance to take this").

### `sch_offline_exams`
**Purpose:** Setup for paper-based exams.
- **Key Fields:**
  - `question_paper_generated`: Did the system generate the PDF?
  - `manual_entry_enabled`: Can teachers type in marks?
- **Application Workflow:** Teacher prints PDF -> Students write exam -> Teacher enters marks in ERP.

### `sch_offline_exam_marks`
**Purpose:** Storage for manually entered marks.

---

## 6. Student Attempts & Grading

### `sch_attempts`
**Purpose:** A student's session of taking a test.
- **Key Fields:**
  - `status`: IN_PROGRESS / SUBMITTED.
  - `time_taken_seconds`: Duration.
  - `confidence_level`: Self-reported confidence.
- **Application Workflow:** The main record for score calculation.

### `sch_attempt_answers`
**Purpose:** The specific answer given for each question.
- **Application Workflow:** Auto-grading engine checks `option_ids` against `is_correct` logic.

### `sch_attempt_behavior_log`
**Purpose:** Tracking interaction events (Focus lost, Answer changed).
- **Application Workflow:** Detecting cheating or hesitation (guessing).

---

## 7. Performance & Recommendations

### `sch_student_learning_outcomes`
**Purpose:** Aggregated mastery level per competency.
- **Application Workflow:** "Student is Proficient in Algebra but Weak in Geometry".

### `sch_student_topic_performance`
**Purpose:** Aggregated score per topic.
- **Key Fields:**
  - `needs_revision`: Flag triggered by low scores.

### `sch_student_weak_areas`
**Purpose:** Persistent record of gaps.
- **Key Fields:**
  - `root_cause_topic_id`: The fundamental missed concept.
- **Application Workflow:** Recommendation engine reads this to suggest remedial videos.

### `sch_student_recommendations`
**Purpose:** Actionable To-Do list for students.
- **Application Workflow:** Personalized dashboard widget "Recommended for You".

### `sch_teacher_recommendations`
**Purpose:** Insights for teachers.
- **Application Workflow:** "5 students failed Linear Equations - Consider a revision class".

### `sch_daily_performance_summary`
**Purpose:** Pre-calculated dashboard stats.
- **Usage:** Fast loading of Principal's dashboard.

### `sch_monthly_performance_agg`
**Purpose:** Long-term trend data.
- **Usage:** Annual reports and district-level benchmarking.

---

## 8. Book & Publication Management

### `slb_books`
**Purpose:** Library of textbooks.
### `slb_book_authors` / `slb_book_author_jnt`
**Purpose:** Author metadata.
### `slb_book_class_subject_jnt`
**Purpose:** "Which book is used for Class 10 Math?"
### `slb_book_topic_mapping`
**Purpose:** Granular mapping of chapters/pages to syllabus topics.

---

## 9. Teaching Tools

### `slb_study_material_types`
**Purpose:** Categories (Video, PDF).
### `slb_study_materials`
**Purpose:** Actual content files/links.
- **Key Fields:**
  - `performance_category_id`: Different content for different learner levels.
### `slb_topic_dependencies`
**Purpose:** Knowledge graph (Prerequisites).
- **Application Workflow:** Used to traverse back and find "Root Cause" of failure.
### `slb_teaching_status`
**Purpose:** Classroom progress tracker.
### `slb_syllabus_schedule`
**Purpose:** Plan vs Actual timeline.
### `slb_teacher_subject_assignment`
**Purpose:** Mapping teachers to classrooms.

---

## 10. Analytics & Audit

### `sch_question_analytics`
**Purpose:** Stats about the question itself (Is it too hard?).
### `sch_exam_analytics`
**Purpose:** Exam-level stats (Pass rate, bell curve).
### `sch_audit_log`
**Purpose:** Security & Change tracking.
### `sch_question_index`
**Purpose:** Materialized view for fast searching in the Question Bank.

---
**End of Guide**
