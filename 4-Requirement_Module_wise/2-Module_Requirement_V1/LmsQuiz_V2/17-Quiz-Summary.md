# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Quiz Management
### Screen: Quiz Summary

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quiz Summary** screen serves as the central operational dashboard for teachers to monitor the execution of quizzes they have allocated. It provides a bird's-eye view of how many students were assigned a quiz versus how many have actually submitted it.

### 1.2 Why is this necessary? (Business Justification)
- **Tracking & Follow-up:** Teachers need a quick way to see if there are "Pending" students who haven't attempted an active quiz before the deadline.

---

## 2. Document Scope
- **In-Scope:** The main datagrid, the top filtering mechanism, and the computed progress statistics (Assigned vs Attempted vs Pending).
- **Out-of-Scope:** The detailed individual report (accessed via the Report action button).

---

## 3. User Personas
1. **Teacher:** Tracks their own assigned quizzes.
2. **Academic Admin:** Can view the progress of all quizzes across the school.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Advanced Filtering Mechanism
- **System Behavior:** Above the datagrid, a form allows filtering the summary view.
- **Filter Fields:**
  - **Class/Section:** Joint dropdown (e.g., `Class 10 - A`).
  - **Subject:** Dropdown.
  - **Published Date Range:** Daterangepicker mapping to `date_from` and `date_to`.
  - **Search:** Text input to search by Quiz Name or Code.

### FR-02: Computed Summary Datagrid
- **Action:** View the filtered list of allocations.
- **Columns & Logic:**
  - **Quiz Details:** Shows Quiz Title and Quiz Code.
  - **Allocation Target:** Displays the `allocation_type` (e.g., CLASS, STUDENT) and the specific target name.
  - **Subject / Study Form:** Fetched via relationships.
  - **Due Date:** If the current date is past the Due Date, the text turns bold red (`text-danger fw-bold`).
  - **Publish Date:** Datetime display.
  - **# Assigned To:** Integer count of total students bound to this allocation.
  - **Attempt Status (Computed):**
    - **Done (Submitted):** Count of students who completed the quiz. Green badge.
    - **Pending:** Auto-calculated (`Assigned - Attempted`). Yellow badge. Only shows if `Pending > 0`.
  - **Action:** A "Report" button linking to `lms-quize.quize.report` to view granular student-by-student scores.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Tracking Pending Submissions
**As a** Teacher,
**I want to** see exactly how many students have not yet taken my Weekly Math Quiz,
**So that** I can send them a reminder before the Due Date.

**Acceptance Criteria:**
- **Given** I assigned the quiz to 30 students and 20 completed it, **When** I look at the Attempt Status column, **Then** I see a green badge saying "20 Done" and a yellow badge saying "10 Pending".

---

## 6. Business Data Dictionary & Validations
| Computed Field | Calculation Logic |
|----------------|-------------------|
| **Pending Count** | `max(0, total_assigned - total_attempt_count)` |

---

## 7. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_quiz_allocations`, `lms_quiz_attempts` (aggregations).
- **Outgoing Dependencies:** Links directly to the Detailed Report screen.
