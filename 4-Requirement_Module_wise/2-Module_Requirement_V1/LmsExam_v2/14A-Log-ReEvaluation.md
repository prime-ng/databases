# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Logs & Grievance
### Screen: Tab 1: Re-Evaluation Requests

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Re-Evaluation Requests** tab serves as a centralized helpdesk where students' complaints regarding their exam scores (Grievances) are logged, tracked, and resolved by the school administration or teachers.

### 1.2 Why is this necessary? (Business Justification)
- **Transparency & Fairness:** If a student feels a question was out-of-syllabus or mistakenly graded, there must be an official channel to challenge the result without losing track of the request.
- **Audit Trail for Score Changes:** Directly changing marks in the database is risky. Resolving a grievance provides a documented reason ("Marks Revision") for why a score changed post-publication.

---

## 2. Document Scope
- **In-Scope:** Logging new grievances, filtering existing ones, toggling visibility, and resolving them (which can optionally alter marks).
- **Out-of-Scope:** Student portal view of these grievances.

---

## 3. User Personas
1. **Teacher / Exam Coordinator:** Reviews the grievance, checks the paper, and either rejects the claim or approves it and updates the marks.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Advanced Filtering
- **Action:** Filter grievances to find specific complaints.
- **UI/JS Logic:**
  - Cascading AJAX dropdowns: `Class -> Section -> Student`.
  - Additional filters: Status (`OPEN`, `UNDER_REVIEW`, `RESOLVED`, `REJECTED`), Grievance Type (`MARKING_ERROR`, `QUESTION_ERROR`, `OUT_OF_SYLLABUS`, `OTHER`), and Exam.

### FR-02: Logging a New Grievance
- **Action:** Click the "+" button to log a grievance manually.
- **System Behavior:**
  - **Select2 Integration:** User searches for a student via `lms-exam.student-search`.
  - Once a student is selected, an AJAX call (`lms-exam.student-papers`) fetches only the specific papers that this student has actually attempted.
  - The user selects the Grievance Type and enters the complaint details.

### FR-03: Grievance Resolution Workflow
- **Action:** Click the "Resolve" (Checkmark) button.
- **System Behavior:**
  - Opens the `resolveGrievanceModal`.
  - **Dynamic JS Rules (`toggleResolutionFields`):**
    - If status changes to `RESOLVED` or `REJECTED`, the "Resolution Remarks" field becomes **mandatory**.
    - If status is specifically `RESOLVED`, the UI reveals the "Old Marks" (read-only) and "New Marks" input fields, allowing the evaluator to revise the score.
  - A badge "Marks Revised" is displayed in the list if `marks_changed` is true.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Resolving a valid complaint
**As an** Evaluator,
**I want to** resolve John's complaint about Q4 being correct,
**So that** his marks are officially updated from 45 to 50.

**Acceptance Criteria:**
- **Given** I open the Resolve Modal, **When** I set status to `RESOLVED`, enter remarks, set New Marks to 50, and save, **Then** the system updates the `lms_exam_grievances` table and recalculates `lms_exam_results`.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Grievance Types** | ENUM: `MARKING_ERROR`, `QUESTION_ERROR`, `OUT_OF_SYLLABUS`, `OTHER`. |
| **Status Workflow** | ENUM: `OPEN` -> `UNDER_REVIEW` -> `RESOLVED`/`REJECTED`. |
| **Status Toggle** | AJAX toggle on `is_active` field. |

---

## 7. Exception & Error Handling Scenarios
- **Scenario:** User selects a student who hasn't taken any exams.
  - *Response:* The Paper dropdown shows "No attempted papers found".

---

## 8. Dependency & Impact Mapping
### 8.1 Incoming Dependencies
- `lms_exam_attempts` and `lms_exam_results` (Student must have taken the exam to have a grievance).

### 8.2 Outgoing Dependencies
- Resolving a grievance updates the master `total_marks_obtained` in `lms_exam_results`.
