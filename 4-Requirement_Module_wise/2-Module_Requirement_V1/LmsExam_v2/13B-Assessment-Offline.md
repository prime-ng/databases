# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Assessment & Marks 
### Screen: Assessment -> Tab 2: Offline Assessment

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Offline Assessment** tab provides an identical executive dashboard experience to the Online tab, but is strictly filtered to display **Offline Exams**. It directs teachers to the specific offline grading interfaces (`Bulk` or `Question Wise`).

### 1.2 Why is this necessary? (Business Justification)
- **Workflow Segregation:** Offline exams have fundamentally different grading mechanics (Bulk vs Q-Wise file uploads). Keeping them in a separate tab prevents UI clutter and confusion.

---

## 2. Document Scope
- **In-Scope:** Summary aggregation of offline exam records. Routing to offline-specific checking interfaces based on the paper's configuration.
- **Out-of-Scope:** The actual grading mechanism.

---

## 3. User Personas
1. **Teacher / Data Entry Operator:** Monitors which offline batches have been uploaded and which are pending verification.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Advanced Filtering
- **Action:** Filter the summary grid.
- **UI/JS Logic:** Exactly identical to the Online tab. `daterangepicker` integration with auto-submit, plus cascading AJAX dropdowns.

### FR-02: Summary Aggregation Grid
- **Action:** View the data.
- **System Behavior:**
  - Filters strictly by `mode = OFFLINE`.
  - Displays a special UI badge showing whether the paper is configured for **Bulk** or **Question Wise** entry.
  - Calculates "Submitted" based on whether offline data entry has occurred.

### FR-03: Conditional Action Routing
- **Action:** Click the "Check" button.
- **System Behavior (Crucial Logic):** 
  - If the paper's `is_ques_wise_file_upload` is true, the button routes to `lms-exam.exam.paper-check-offline` (Detailed Q-wise checking).
  - Otherwise, it routes to `lms-exam.exam.paper-check.bulk` (Bulk total checking/verification).

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Navigating to the Correct Grading UI
**As a** Teacher,
**I want to** click "Check" on my Offline History Exam,
**So that** the system automatically takes me to the Bulk upload screen because that's how I configured the paper.

**Acceptance Criteria:**
- **Given** the History paper is `BULK_TOTAL` and `is_ques_wise_file_upload` is 0, **When** I click Check, **Then** I am routed to the `.bulk` endpoint.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Data Scope** | The grid strictly forces `mode = OFFLINE` behind the scenes. |
| **Routing Flag** | `is_ques_wise_file_upload == '1'` is the explicit condition used in the Blade template to determine the URL of the Check button. |

---

## 7. Exception & Error Handling Scenarios
- **Scenario:** A paper was mistakenly created as Offline instead of Online.
  - *Response:* It will appear in this tab. The teacher must go back to Exam Creation to fix it; they cannot change the mode from the summary screen.

---

## 8. Dependency & Impact Mapping
### 8.1 Incoming Dependencies
- `lms_exam_papers.is_ques_wise_file_upload` (dictates the route).
- `lms_exam_papers`, `lms_exam_allocations`.

### 8.2 Outgoing Dependencies
- Connects to the Offline Paper Checking controllers.
