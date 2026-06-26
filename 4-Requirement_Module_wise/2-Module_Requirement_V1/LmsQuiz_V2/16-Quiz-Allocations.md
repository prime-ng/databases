# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Quiz Creation
### Screen: Quiz Allocations

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quiz Allocation** screen maps a completed Quiz to its target audience (a specific class, section, group, or individual student) and defines the exact time window for the attempt.

### 1.2 Why is this necessary? (Business Justification)
- **Targeted Deployment:** Allows teachers to assign remedial quizzes to specific underperforming students without broadcasting it to the entire class.

---

## 2. Document Scope
- **In-Scope:** Target resolution via UI logic (`CLASS`, `SECTION`, `GROUP`, `STUDENT`). Scheduling limits. Auto-publish toggle logic.
- **Out-of-Scope:** Student portal rendering.

---

## 3. User Personas
1. **Teacher:** Schedules the quiz for their students.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Quiz Context & Unused Filter
- **Quiz Dropdown:** Lists available quizzes.
- **"Unused Quiz" Toggle (`filter_unallocated`):** If checked (default), JS filters the Quiz dropdown to hide any quizzes that have already been allocated, preventing accidental double-assignment.

### FR-02: Target Resolution
- **Allocation Type Dropdown:** `CLASS`, `SECTION`, `GROUP`, `STUDENT`.
  - **If CLASS:** Automatically locks the target to the Quiz's parent class.
  - **If SECTION:** Displays a Section dropdown.
  - **If GROUP:** Displays a Group dropdown.
  - **If STUDENT:** Displays a Section filter dropdown AND a Student dropdown (AJAX loaded based on class/section).

### FR-03: Scheduling & Visibility
- **Published At (Visible From):** Datetime. If left empty, it publishes immediately.
- **Due Date:** Required Datetime. The standard deadline.
- **Cut-off Date:** Optional Datetime. The absolute hard deadline after which submissions are physically blocked by the system.

### FR-04: Auto Publish Result Logic (JS Toggle)
- **Auto Publish Result (`is_auto_publish_result`):** A boolean switch.
- **Result Publish Date Container:** 
  - **System Behavior (JS):** If "Auto Publish Result" is checked, JS displays the `result_publish_date` datetime input field. If unchecked, the field is hidden. This dictates exactly when the student can see their final score.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Specific Student Retest
**As a** Teacher,
**I want to** assign a Quiz specifically to John Doe,
**So that** he can make up for being absent on the original quiz date.

**Acceptance Criteria:**
- **Given** I select "STUDENT" as Allocation Type, **When** I do so, **Then** the Section filter and Student dropdown appear, forcing me to select a specific `target_id` corresponding to John Doe.

#### Story 2: Delayed Result Publishing
**As a** Teacher,
**I want to** schedule the results to publish 2 days after the cut-off date,
**So that** I have time to manually review any short-answer questions.

**Acceptance Criteria:**
- **Given** I toggle `is_auto_publish_result` to ON, **When** the `result_publish_date` field appears, **Then** I can select a datetime 2 days in the future.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Target Resolution** | `target_id` validation varies dynamically based on `allocation_type`. |
| **Dates** | `due_date` must be >= `published_at`. `cut_off_date` must be >= `due_date`. |

---

## 7. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_quizzes`, `sch_classes`, `sch_sections`, `lms_student_groups`, `std_students`.
- **Outgoing Dependencies:** `lms_quiz_allocations` signals the Student Portal dashboard to display the quiz at the scheduled `published_at` time.
