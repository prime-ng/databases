# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Quiz Management
### Screen: Quiz Advanced Reports

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quiz Reports** screen is a centralized analytics hub offering 6 distinct perspectives on quiz performance, ranging from macro-level class metrics to micro-level student analytics.

### 1.2 Why is this necessary? (Business Justification)
- **Data-Driven Decisions:** Academic Heads need aggregate data to evaluate teacher effectiveness, while teachers need granular data to identify weak students.

---

## 2. Document Scope
- **In-Scope:** The 6-Tab navigation structure and the general routing to partial report views.
- **Out-of-Scope:** The raw SQL queries powering the analytics.

---

## 3. User Personas
1. **Academic Head:** Views macro class and teacher performance.
2. **Teacher:** Views their specific class and student analytics.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Modular Tab Navigation
- **System Behavior:** The screen uses a `nav-tab` component to switch between 6 specialized reports. Each tab is protected by a specific tenant permission flag.
- **The 6 Reports:**
  1. **Class Performance Report (`tenant.class-performance-report.view`):** Aggregates scores across an entire class.
  2. **Teacher Monthly Report (`tenant.teacher-monthly-report.view`):** Evaluates how many quizzes a teacher conducted and the average passing rate.
  3. **Student Performance Summary (`tenant.student-performance-summary.view`):** A high-level overview of a specific student's aggregate quiz grades.
  4. **Student Detailed Assessment (`tenant.student-detailed-assessment.view`):** A granular breakdown of a student's performance question-by-question across quizzes.
  5. **Periodic Detail Report (`tenant.periodic-detail-report.view`):** Examines score trends over a specific date range (e.g., Mid-terms vs Finals).
  6. **Current Class Performance (`tenant.current-class-performance.view`):** A real-time snapshot of the currently active academic term.

### FR-02: Access Control
- **System Behavior:** The Blade template uses `@can` directives to physically omit the HTML/PHP includes for any report the current user is not authorized to see, ensuring data security.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Teacher Access Restriction
**As a** System Admin,
**I want** teachers to only see Student and Class reports, but NOT the Teacher Monthly Report,
**So that** they cannot see the comparative analytics of other teachers.

**Acceptance Criteria:**
- **Given** a Teacher role without `tenant.teacher-monthly-report.view`, **When** they load the Reports screen, **Then** the "Teacher Monthly Report" tab is completely hidden from the UI.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** Massive data aggregation from `lms_quizzes`, `lms_quiz_allocations`, `lms_quiz_attempts`, `lms_quiz_attempt_answers`.
- **Outgoing Dependencies:** N/A (End-point for data consumption).
