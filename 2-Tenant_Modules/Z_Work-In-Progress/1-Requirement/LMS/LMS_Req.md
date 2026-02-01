# LMS Module - Requirement Document

**Version:** 1.0  
**Status:** Work In Progress  
**Author:** Business Analyst GPT  
**Date:** 2026-01-14

---

## Overview

This document outlines the detailed requirements for the Learning Management System (LMS) module for a School ERP. The requirements are grouped into functional modules and sub-modules, providing detailed descriptions, user roles, and technical specifications (SQL/JSON/cURL) to guide the AI-driven Database Design (DDL) and further development.

---

## 1. Syllabus Management
## 1. Syllabus Management

This module manages the academic curriculum, including subjects, chapters, topics, and question banks.

### 1.1 Syllabus Setup
**Goal:** Define the hierarchical structure of what is taught.
**Actors:** Academic Coordinator, Admin

#### 1.1.1 Subject Setup
*   **Description:** Define subjects offered by the school (e.g., Mathematics, Science, English) and map them to Classes/Grades.
*   **Use Case:** Admin creates "Mathematics" and assigns it to "Class 10".
*   **Technical Spec:**

    ```sql
    -- SQL: sch_subjects already exists. Example query to view subjects for a class
    SELECT s.name, s.code 
    FROM sch_subjects s
    JOIN sch_class_subjects_jnt j ON s.id = j.subject_id
    WHERE j.class_id = 10;
    ```
    ```json
    // JSON: Create Subject Payload
    {
      "name": "Physics",
      "code": "PHY_10",
      "type": "THEORY", 
      "department_id": 5
    }
    ```

#### 1.1.2 Chapter & Sub-Chapter Setup
*   **Description:** Break down subjects into Chapters (Lessons) and Sub-Chapters for granular tracking.
*   **Use Case:** Teacher defines "Chapter 1: Algebra".
*   **Technical Spec:**
    ```sql
    -- SQL: slb_lessons table
    CREATE TABLE IF NOT EXISTS `slb_lessons` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `subject_id` BIGINT UNSIGNED NOT NULL,
      `class_id` INT UNSIGNED NOT NULL,
      `name` VARCHAR(150) NOT NULL,
      `ordinal` INT UNSIGNED DEFAULT 1
    );
    ```

#### 1.1.3 Topic & Sub-Topic Setup
*   **Description:** Further divide chapters into specific teachable Topics and Sub-Topics.
*   **Use Case:** Teacher defines "Topic 1.1: Linear Equations".
*   **Technical Spec:**
    ```sql
    -- SQL: slb_topics table (hierarchical)
    -- Refer to slb_topics in syllabus_ddl_v1.1.sql
    SELECT * FROM slb_topics WHERE lesson_id = 101 ORDER BY ordinal;
    ```

### 1.2 Book/Publication Management
**Goal:** Manage textbooks and reference materials linked to the syllabus.
**Actors:** Librarian, Academic Coordinator

#### 1.2.1 Book & Publication Setup
*   **Description:** Register Books and Publishers in the system.
*   **Use Case:** Librarian adds "NCERT Mathematics Class 10" published by "NCERT".
*   **Technical Spec:**
    ```json
    // JSON: Add Book
    {
      "title": "Concepts of Physics",
      "isbn": "978-8123456789",
      "author": "H.C. Verma",
      "publisher_id": 12
    }
    ```

#### 1.2.2 Book Management
*   **Description:** Map books to specific Subjects and Classes.
*   **Use Case:** Admin maps "Concepts of Physics" to "Class 11 - Physics".
*   **Technical Spec:**
    ```curl
    # cURL: Map Book to Subject
    curl -X POST /api/syllabus/books/map \
      -H "Content-Type: application/json" \
      -d '{"book_id": 55, "class_id": 11, "subject_id": 4}'
    ```

### 1.3 Question Creation & Management
**Goal:** Build a repository of questions for exams and quizzes.
**Actors:** Teachers, Subject Matter Experts

#### 1.3.1 Question Bank Setup
*   **Description:** Create Question Banks categorized by Subject, Class, and Difficulty.
*   **Use Case:** Teacher creates "Grade 10 Math Bank 2024".
*   **Technical Spec:**
    ```sql
    -- SQL: qns_question_banks
    CREATE TABLE `qns_question_banks` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `title` VARCHAR(255) NOT NULL,
      `subject_id` BIGINT UNSIGNED NOT NULL
    );
    ```

#### 1.3.2 Question Creation
*   **Description:** Author questions (MCQ, Descriptive, Fill-in-blanks) with tagging (Topic, Bloom's Taxonomy, Complexity).
*   **Use Case:** Teacher adds an MCQ question about "Photosynthesis" tagged with "Remembering" (Bloom's).
*   **Technical Spec:**
    ```json
    // JSON: Create Question
    {
      "text": "What is the powerhouse of the cell?",
      "type": "MCQ",
      "options": [
        {"text": "Mitochondria", "is_correct": true},
        {"text": "Nucleus", "is_correct": false}
      ],
      "tags": ["Biology", "Cell"],
      "complexity_id": 2, // Medium
      "topic_id": 450
    }
    ```

---

## 2. Exam Management

This module handles the lifecycle of examinations, both Online (CBT) and Offline (Paper-based).

### 2.1 Exam Management (Online)
**Goal:** Conduct Computer Based Tests (CBT).
**Actors:** Exam Controller, Student

#### 2.1.1 Exam Setup
*   **Description:** Define Exam Schedules, Instructions, Proctoring settings, and Eligibility.
*   **Use Case:** Planner sets up "Mid-Term Online Physics Exam" for 14th Jan 10 AM.
*   **Technical Spec:**
    ```sql
    -- SQL: exm_online_exams
    CREATE TABLE `exm_online_exams` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `title` VARCHAR(255),
      `start_time` DATETIME,
      `end_time` DATETIME,
      `duration_minutes` INT,
      `is_proctored` BOOLEAN DEFAULT 0
    );
    ```

#### 2.1.2 Exam Management (Execution)
*   **Description:** Manage student attempts, timer, auto-submission, and real-time monitoring.
*   **Use Case:** Student logs in to take the exam; system records answers and time per question.
*   **Technical Spec:**
    ```curl
    # cURL: Submit Answer
    curl -X POST /api/exams/attempt/answer \
      -H "Authorization: Bearer <token>" \
      -d '{"exam_id": 101, "question_id": 505, "selected_option_id": 2}'
    ```

### 2.2 Exam Management (Offline)
**Goal:** Manage traditional Pen & Paper exams.
**Actors:** Exam Controller

#### 2.2.1 Exam Paper Creation (Question Paper Generator)
*   **Description:** Auto-generate or manually assemble Question Papers from the Question Bank based on blueprints (e.g., 20% Easy, 50% Medium, 30% Hard).
*   **Use Case:** Teacher generates "Class 10 Final Math Paper" using a blueprint.
*   **Technical Spec:**
    ```json
    // JSON: Blueprint for Generation
    {
      "total_marks": 100,
      "sections": [
        {"type": "MCQ", "count": 20, "marks_per_q": 1},
        {"type": "Long Answer", "count": 5, "marks_per_q": 10}
      ],
      "difficulty_distribution": {"easy": 20, "medium": 50, "hard": 30}
    }
    ```

#### 2.2.2 Exam Marks Entry
*   **Description:** Manual entry of marks obtained by students in offline exams.
*   **Use Case:** Teacher enters marks for "Student A": 85/100.
*   **Technical Spec:**
    ```sql
    -- SQL: exm_student_marks
    INSERT INTO exm_student_marks (exam_id, student_id, marks_obtained, max_marks) 
    VALUES (202, 5001, 85.5, 100);
    ```

---

## 3. Quiz & Assessment Management

This module manages smaller, frequent assessments (Formative Assessments).

### 3.1 Quiz & Assessment Cycle
**Goal:** Continuous evaluation of student progress.
**Actors:** Teacher, Student

#### 3.1.1 Quiz Masters & Creation
*   **Description:** Setup Quiz types (Daily, Weekly) and create quizzes.
*   **Use Case:** Teacher creates a "Weekly Science Quiz".
*   **Technical Spec:**
    ```json
    // JSON: Create Quiz
    {
      "title": "Weekly Quiz 5",
      "type": "FORMATIVE",
      "questions": [101, 102, 105, 209] // List of Question IDs
    }
    ```

#### 3.1.2 Assign Questions & Allocation
*   **Description:** Assign specific questions to a quiz and assign the quiz to specific Students or Classes.
*   **Use Case:** Assign "Weekly Quiz 5" to "Class 9A" & "Class 9B".
*   **Technical Spec:**
    ```sql
    -- SQL: quiz_assignments
    INSERT INTO quiz_assignments (quiz_id, target_type, target_id)
    VALUES (55, 'CLASS', 9);
    ```

#### 3.1.3 Results & Analytics
*   **Description:** Auto-grade quizzes and generate instant reports.
*   **Use Case:** Student sees "You scored 8/10". Teacher sees "Class average is 7.5".
*   **Technical Spec:**
    ```sql
    -- SQL: Analysis Query
    SELECT q.title, AVG(r.score) as class_avg
    FROM quiz_results r
    JOIN quiz_master q ON r.quiz_id = q.id
    WHERE q.id = 55;
    ```

---

## 4. Recommendations Module

This module provides personalized content suggestions based on student performance.

### 4.1 Recommendations Setup & Logic
**Goal:** Define rules for when and what to recommend.
**Actors:** Admin, Teacher

#### 4.1.1 Recommendations Setup (Rules Engine)
*   **Description:** Configure Trigger (e.g., Score < 40%), Condition (Topic: Algebra), and Action (Recommend: Video ID 55).
*   **Use Case:** "If student scores < 50% in Linear Equations, recommend 'Basics of Algebra' video."
*   **Technical Spec:**
    ```sql
    -- SQL: rec_recommendation_rules (Refer to DDL)
    SELECT * FROM rec_recommendation_rules WHERE trigger_event = 'ON_ASSESSMENT_RESULT';
    ```

#### 4.1.2 Content Management
*   **Description:** Manage the pool of remedial content (Videos, PDFs, Practice Sheets).
*   **Use Case:** Upload a video "Understanding Photosynthesis".
*   **Technical Spec:**
    ```json
    // JSON: Content Metadata
    {
      "title": "Photosynthesis Basics",
      "type": "VIDEO",
      "url": "https://lms.school.com/video/123.mp4",
      "topics_covered": [45, 46]
    }
    ```

#### 4.1.3 Recommendations Analytics
*   **Description:** Track efficacy of recommendations (Did the student's score improve after watching?).
*   **Use Case:** Report: "80% of students improved scores after watching recommended video."
*   **Technical Spec:**
    ```sql
    -- SQL: Efficacy Check
    SELECT count(*) FROM rec_student_recommendations 
    WHERE status = 'COMPLETED' AND score_improvement > 0;
    ```

---

## 5. Behavior Management

This module tracks student conduct and behavioral points.

### 5.1 Behavior Setup & Tracking
**Goal:** Gamify or track student discipline and soft skills.
**Actors:** Teacher, Disciplinary In-charge

#### 5.1.1 Categories & Points Setup
*   **Description:** Define categories (Discipline, Leadership, Hygiene) and point values (+ve or -ve).
*   **Use Case:** "Late Coming" = -5 points. "Helping Peers" = +10 points.
*   **Technical Spec:**
    ```sql
    -- SQL: beh_categories
    CREATE TABLE `beh_categories` (
      `id` INT AUTO_INCREMENT PRIMARY KEY,
      `name` VARCHAR(100), -- e.g. 'Discipline'
      `is_positive` BOOLEAN
    );
    ```

#### 5.1.2 Behavior Points Entry (History)
*   **Description:** Log incidents/achievements for students.
*   **Use Case:** Teacher assigns +10 points to John for "Class Participation".
*   **Technical Spec:**
    ```curl
    # cURL: Assign Points
    curl -X POST /api/behavior/points \
      -d '{"student_id": 5001, "category_id": 2, "points": 10, "remarks": "Great answer in class"}'
    ```

#### 5.1.3 Behavior Reports
*   **Description:** Generate reports for parents/principals (e.g., Top 10 well-behaved students).
*   **Use Case:** Monthly Behavior Report Card.
*   **Technical Spec:**
    ```sql
    -- SQL: Summary
    SELECT student_id, SUM(points) as total_score 
    FROM beh_student_history 
    GROUP BY student_id 
    ORDER BY total_score DESC;
    ```

---

## 6. Class Performance Management

This module analyzes academic performance at a Class/Section aggregate level.

### 6.1 Setup & Analytics
**Goal:** ID trends across the class.
**Actors:** Class Teacher, Principal

#### 6.1.1 Class Performance Analytics
*   **Description:** Aggregated view of Exam/Quiz data. Heatmaps of weak topics for the whole class.
*   **Use Case:** Teacher sees that 70% of Class 9A failed in "Trigonometry".
*   **Technical Spec:**
    ```sql
    -- SQL: Topic-wise Class Performance
    SELECT topic_id, AVG(marks_obtained) as avg_marks
    FROM exm_student_question_attempts
    WHERE class_id = 9
    GROUP BY topic_id
    HAVING avg_marks < 40;
    ```

---

## 7. Student Performance Management

This module analyzes individual student academic trajectory.

### 7.1 Setup & Analytics
**Goal:** 360-degree academic view of a student.
**Actors:** Student, Parent, Mentor

#### 7.1.1 Student Performance Analytics
*   **Description:** Individual Subject-wise analysis, Rank history, Strength/Weakness analysis.
*   **Use Case:** Parent views "Math Progress Graph" showing improvement from Term 1 to Term 2.
*   **Technical Spec:**
    ```json
    // JSON: Student Dashboard Data
    {
      "student_id": 5001,
      "overall_gpa": 8.5,
      "strongest_subject": "Physics",
      "weakest_subject": "History",
      "recent_exams": [
        {"exam": "Mid-Term", "percentage": 85},
        {"exam": "Unit Test 2", "percentage": 88}
      ]
    }
    ```

---

## 8. Student Progress Management

This module tracks non-academic or syllabus-completion progress.

### 8.1 Tracking Syllabus Completion
**Goal:** Track how much of the syllabus a student has completed (Learning Path).
**Actors:** Student, Teacher

#### 8.1.1 Student Progress Management
*   **Description:** Track topic completion status (Not Started, In Progress, Completed).
*   **Use Case:** Student marks "Topic 1.1" as Completed after reading. System updates progress bar to 15%.
*   **Technical Spec:**
    ```sql
    -- SQL: std_topic_progress
    UPDATE std_topic_progress 
    SET status = 'COMPLETED', completion_date = NOW()
    WHERE student_id = 5001 AND topic_id = 101;
    ```

---

## 9. Student Attendance Management

This module links attendance to academic delivery.

### 9.1 Attendance Setup & Analytics
**Goal:** Correlate attendance with performance.
**Actors:** Teacher, Admin

#### 9.1.1 Attendance Analytics
*   **Description:** Analyze attendance patterns. Integration with Class Performance (e.g., Low attendance => Low scores?).
*   **Use Case:** Alert generated: "Student has < 75% attendance and is failing in 2 subjects."
*   **Technical Spec:**
    ```sql
    -- SQL: Low Attendance Alert
    SELECT student_id, (days_present / total_working_days)*100 as attendance_pct
    FROM std_attendance_summary
    WHERE (days_present / total_working_days)*100 < 75;
    ```
