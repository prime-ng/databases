# LMS Module - Comprehensive Requirement Document (v1)

**Version:** 1.0  
**Status:** Work In Progress  
**Author:** Business Analyst GPT  
**Date:** 2026-01-14

---

## Overview

This document acts as the definitive source for the **Learning Management System (LMS)** module requirements for the School ERP. It has been synthesized from standard industry requirements (Moodle, Canvas, Blackboard) and specific user needs. It is designed to be **AI-Readable** for subsequent Database Design (DDL) generation.

**Core Principles:**
1.  **Granularity:** Requirements are broken down into Modules > Sub-Modules > Functionalities.
2.  **Context:** Each functionality defines *Who* (Actor), *What* (Description), *Why* (Benefit), and *How* (Process).
3.  **Technical Readiness:** Each item includes preliminary SQL schema hints, JSON payloads, or API signatures.

---

## 1. Syllabus & Content Management

**Goal:** Centralized management of academic curriculum, digital assets, and learning paths.

### 1.1 Syllabus Structure Setup
**Description:** Defining the backbone of the curriculum (Year > Class > Subject > Chapter > Topic).

#### 1.1.1 Subject & Curriculum Mapping
*   **Description:** Map subjects to classes and define the curriculum type (e.g., CBSE, IGCSE, State Board).
*   **Who:** Academic Coordinator / Admin
*   **How:** Admin selects a Class (e.g., Grade 10) and assigns Subjects (Math, Science) with specific curriculum codes.
*   **Use Case:** Ensures Grade 10 students see the correct "CBSE Math" syllabus vs "IGCSE Math".
*   **Technical Spec (SQL):**
    ```sql
    -- sch_class_subjects_jnt (Existing) linkage
    SELECT * FROM sch_class_subjects_jnt WHERE class_id = 10 AND curriculum_code = 'CBSE';
    ```

#### 1.1.2 Hierarchical Topic Management
*   **Description:** A multi-level hierarchy for organizing content: Unit -> Chapter -> Lesson > Topic -> Sub-topic.
*   **Who:** HOD / Subject Teacher
*   **How:** Teacher creates a tree structure. e.g., Math > Algebra > Quadtratic Equations > Solving by Factoring.
*   **Use Case:** Allows granular tracking of progress. "Student has completed 4/5 topics in Algebra".
*   **Technical Spec (SQL):**
    ```sql
    CREATE TABLE `slb_topics` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `parent_id` BIGINT UNSIGNED NULL, -- Adjacency List for hierarchy
      `name` VARCHAR(255) NOT NULL,
      `level_depth` TINYINT DEFAULT 0, -- 0=Unit, 1=Chapter, etc.
      `weightage_pct` DECIMAL(5,2) -- Importance of tracking
    );
    ```

### 1.2 Content Repository (Digital Library)
**Description:** Storage and management of all learning resources linked to the syllabus.

#### 1.2.1 Resource Upload & Tagging
*   **Description:** Upload support for PDF, Video (MP4/Link), Audio, PPT, SCORM packages.
*   **Who:** Teacher / Content Creator
*   **How:** User uploads a file, adds metadata (Title, Description, Duration), and tags it to a Topic.
*   **Use Case:** Attaching a "Photosynthesis Explanation Video" to the "Plant Life" chapter.
*   **Technical Spec (JSON Payload):**
    ```json
    {
      "title": "Introduction to Kinetics",
      "resource_type": "VIDEO_EXTERNAL",
      "url": "https://vimeo.com/123456",
      "topic_map_id": 501,
      "tags": ["Physics", "Mechanics", "Grade-11"],
      "visibility": "PUBLISHED"
    }
    ```

#### 1.2.2 Book & Publication Management
*   **Description:** Digital twin of physical textbooks with chapter mappings.
*   **Who:** Librarian
*   **How:** Map physical book pages to digital syllabus topics. "Chapter 5 in NCERT Book corresponds to Topic ID 405".
*   **Use Case:** "Read pages 45-50" assignment links directly to the relevant syllabus topic.
*   **Technical Spec (SQL):**
    ```sql
    CREATE TABLE `slb_book_mappings` (
      `book_id` BIGINT UNSIGNED,
      `topic_id` BIGINT UNSIGNED,
      `page_start` INT,
      `page_end` INT
    );
    ```

---

## 2. Question Bank & Assessment Management

**Goal:** Robust creation, banking, and delivery of assessments (Formative & Summative).

### 2.1 Question Banking
**Description:** A versioned, categorized repository of questions.

#### 2.1.1 Question Authoring
*   **Description:** Create questions with support for Rich Text, Equations (LaTeX), Images, and multiple types (MCQ, MMA, True/False, Short Answer, Essay).
*   **Who:** Subject Experts
*   **How:** Teacher drafts a question, sets the correct answer/rubric, assigns difficulty, and links to a Topic.
*   **Use Case:** Creating a repository for end-of-year randomization.
*   **Technical Spec (JSON):**
    ```json
    {
      "q_text": "Solve for x: <math>2x^2 + 4 = 0</math>",
      "q_type": "MCQ",
      "difficulty": "HARD",
      "bloom_taxonomy": "APPLYING",
      "options": [
        {"id": 1, "text": "2i", "is_correct": true},
        {"id": 2, "text": "4", "is_correct": false}
      ]
    }
    ```

#### 2.1.2 Bulk Import & Export
*   **Description:** Upload questions via CSV/Excel or export banks for offline review.
*   **Who:** Admin / HOD
*   **How:** Upload standard template Excel file -> System parses and validates -> Ingests into Bank.
*   **Use Case:** Migrating questions from a legacy system or publisher CD.
*   **Technical Spec (cURL):**
    ```bash
    curl -F "file=@question_bank_math_v1.csv" -X POST /api/qbank/import
    ```

### 2.2 Quiz & Online Assessment
**Description:** Computer Based Testing (CBT) engine.

#### 2.2.1 Dynamic Quiz Generation
*   **Description:** Create quizzes manually or auto-generate based on blueprints (e.g., "Give me 10 Easy, 5 Hard questions from Topic A").
*   **Who:** Teacher
*   **How:** Define rules -> System fetches randomized questions -> Publishes to students.
*   **Use Case:** Weekly personalized practice tests where every student gets a unique set of questions.
*   **Technical Spec (SQL):**
    ```sql
    CREATE TABLE `exm_exam_blueprints` (
      `id` BIGINT UNSIGNED PRIMARY KEY,
      `exam_id` BIGINT UNSIGNED,
      `topic_id` BIGINT UNSIGNED,
      `difficulty_level` ENUM('EASY','MEDIUM','HARD'),
      `question_count` INT
    );
    ```

#### 2.2.2 Proctoring & Security
*   **Description:** Anti-cheating measures (Browser lock, Tab switch tracking, Cam snapshots).
*   **Who:** Student (Subject)
*   **How:** Frontend prevents clipboard usage; Backend logs "blur" events when user switches tabs.
*   **Use Case:** Ensuring integrity of online semester exams.
*   **Technical Spec (SQL):**
    ```sql
    CREATE TABLE `exm_proctor_logs` (
      `attempt_id` BIGINT UNSIGNED,
      `event_type` ENUM('TAB_SWITCH', 'FULLSCREEN_EXIT', 'MULTIPLE_FACES'),
      `evidence_url` VARCHAR(500), -- Snapshot
      `timestamp` DATETIME
    );
    ```

### 2.3 Offline Assessment Management
**Description:** Managing traditional pen-and-paper exams workflows.

#### 2.3.1 Paper Generation
*   **Description:** Generate PDF question papers from the bank ready for printing.
*   **Who:** Exam Controller
*   **How:** Select Exam -> "Generate PDF" -> System layouts questions with header/footer/instructions.
*   **Use Case:** Printing papers for the final onsite exam.

#### 2.3.2 Marks Entry
*   **Description:** Digital entry of marks from physical answer sheets.
*   **Who:** Teacher
*   **How:** Grid view of students -> Rapid entry of scores per question or total.
*   **Use Case:** Digitizing results for report card generation.

---

## 3. Recommendation & Remedial Engine

**Goal:** AI-driven personalized learning interventions.

### 3.1 Recommendation Logic
**Description:** The "Brain" that decides what a student needs learning.

#### 3.1.1 Rule-Based Triggers
*   **Description:** Configure IF-THEN rules based on performance or behavioral triggers.
*   **Who:** Academic Head
*   **How:** "IF Score < 40% in 'Algebra' THEN Recommend 'Basic Algebra Video' + 'Worksheet 1'".
*   **Use Case:** Automated remedial assignment immediately after a quiz result.
*   **Technical Spec (SQL):**
    ```sql
    CREATE TABLE `rec_rules` (
      `trigger_condition` JSON, -- {"metric": "SCORE", "operator": "<", "value": 40}
      `action_resource_id` BIGINT UNSIGNED
    );
    ```

### 3.2 Personalized Feed
**Description:** Student-facing view of recommended content.

#### 3.2.1 Student Learning Feed
*   **Description:** A dynamic dashboard showing "Required", "Recommended", and "Enrichment" content.
*   **Who:** Student
*   **How:** System queries active recommendations linked to the student ID.
*   **Use Case:** Student logs in and sees "Focus on Geometry - Watch this 5 min video" at the top.

---

## 4. Student Progress & Performance Analytics

**Goal:** Visualizing the learning journey.

### 4.1 Progress Tracking
**Description:** Tracking completion of the syllabus.

#### 4.1.1 Syllabus Coverage Trackers
*   **Description:** Track % of topics covered in class vs % topics learned by student.
*   **Who:** Principal (Class view), Student (Self view)
*   **How:** "Class 10A has completed 80% of Math Syllabus". "Student John has viewed 90% of resources".
*   **Technical Spec (SQL):**
    ```sql
    SELECT topic_id, status FROM std_syllabus_progress 
    WHERE student_id = 101 AND subject_id = 5; 
    -- Status: NOT_STARTED, IN_PROGRESS, COMPLETED
    ```

### 4.2 Performance Analytics
**Description:** Deep dive into scores and outcomes.

#### 4.2.1 Skill/Topic Strength Analysis
*   **Description:** Heatmap showing strong/weak areas (e.g., Good in Calculation, Weak in Theory).
*   **Who:** Teacher / Parent
*   **How:** Aggregating question-level tags (e.g., "Calculus") from all exams to find average performance.
*   **Use Case:** Parent Teacher Meeting discussion based on data not just total marks.
*   **Technical Spec (JSON Data):**
    ```json
    {
      "student_id": 101,
      "skill_breakdown": {
        "Algebra": "85%",
        "Geometry": "45%",
        "Trigonometry": "60%"
      }
    }
    ```

---

## 5. Behavior & Gamification

**Goal:** Driving engagement and tracking non-academic discipline.

### 5.1 Behavior Tracking
**Description:** Digital ledger of student conduct.

#### 5.1.1 Incident Logging
*   **Description:** Log positive (Merits) and negative (Demerits) behaviors with points.
*   **Who:** Teacher
*   **How:** Select Student -> Select Behavior (e.g., "Late Assignment") -> Add Note.
*   **Use Case:** Creating a behavior profile for the term end report.
*   **Technical Spec (SQL):**
    ```sql
    CREATE TABLE `beh_incidents` (
      `student_id` BIGINT UNSIGNED,
      `behavior_category_id` INT, -- Linked to points table (+10, -5)
      `incident_date` DATE,
      `remarks` TEXT
    );
    ```

### 5.2 Gamification
**Description:** Motivation through rewards.

#### 5.2.1 Badges & Leaderboards
*   **Description:** Auto-award badges (e.g., "Homework Hero", "Full Attendance") and show class rankings.
*   **Who:** System (Auto) / Teacher (Manual)
*   **How:** Jobs run nightly to check criteria (e.g., 100% attendance in a month) -> Insert Badge.
*   **Use Case:** Motivating students to log in daily and complete tasks.

---

## 6. Communication & Collaboration

**Goal:** Facilitating learning beyond the classroom.

### 6.1 Forums & Discussions
**Description:** Contextual discussion threads linked to topics/courses.

#### 6.1.1 Topic Discussions
*   **Description:** Q&A threads attached to specific chapters/topics.
*   **Who:** Student / Teacher
*   **How:** Student posts query on "Topic 4 Node" -> Teacher/Peers reply.
*   **Use Case:** Clarifying doubts asynchronously.

### 6.2 Announcements
**Description:** One-to-many broadcasting.

#### 6.2.1 Course Announcements
*   **Description:** Push notifications for homework, exam dates, or material updates.
*   **Who:** Teacher
*   **How:** Teacher posts "Exam on Friday" -> All enrolled students get App Notification/Email.
*   **Technical Spec (SQL):**
    ```sql
    CREATE TABLE `com_announcements` (
      `target_audience_type` ENUM('CLASS','SECTION','INDIVIDUAL'),
      `target_id` BIGINT UNSIGNED,
      `message_body` TEXT,
      `priority` ENUM('NORMAL','URGENT')
    );
    ```

---

## 7. Attendance Management

**Goal:** Linking physical/digital presence to learning.

### 7.1 Integrated Attendance
**Description:** Unifying daily attendance with subject-wise attendance.

#### 7.1.1 Session-Based Attendance
*   **Description:** Mark attendance per lecture/period.
*   **Who:** Subject Teacher
*   **How:** Mobile App view of Class grid -> Tap to mark Absent -> Syncs to Analytics.
*   **Use Case:** Identifying if a student is bunking specific subjects only.

---

## 8. Integration & Scalability

**Goal:** Ensuring the LMS plays well with the ecosystem.

### 8.1 Zoom/Meet Integration
*   **Description:** Launch live classes from within the LMS.
*   **Use Case:** "Join Class" button appears 5 mins before schedule.
*   **Technical Spec:** Store `meeting_link` and `host_key` in `slb_schedule_table`.

### 8.2 SIS Sync
*   **Description:** Nightly sync of Student Rosters, Parent details, and Staff from the core ERP.
*   **Use Case:** New student admitted in ERP automatically appears in LMS Class 9A.
