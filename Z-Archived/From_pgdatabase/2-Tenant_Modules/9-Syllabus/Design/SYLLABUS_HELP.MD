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
