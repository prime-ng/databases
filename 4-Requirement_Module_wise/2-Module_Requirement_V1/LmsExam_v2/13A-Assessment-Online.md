# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Assessment & Marks 
### Screen: Assessment -> Tab 1: Online Assessment

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Online Assessment** tab serves as the high-level executive dashboard for tracking the evaluation progress of all Online Exams. It summarizes data at the **Paper Level** rather than the individual student level.

### 1.2 Why is this necessary? (Business Justification)
- **Bird's-Eye View:** A Principal or Head of Department needs to know: "For the Class 10 Math Online Exam, how many students were assigned? How many have submitted? How many papers has the teacher actually checked?"
- **Gateway to Grading:** It acts as the gateway. From here, the teacher clicks "Check" to dive into the detailed student-by-student grading interface.

---

## 2. Document Scope
- **In-Scope:** Summary aggregation of online exam attempts. Date range filtering. Routing to detailed paper checking interfaces.
- **Out-of-Scope:** The actual grading mechanism (which happens on a separate page after clicking 'Check').

---

## 3. User Personas
1. **Teacher / Evaluator:** Uses the dashboard to find their pending exams and start grading.
2. **Academic Admin:** Monitors the "Assigned vs Submitted vs Checked" ratios to ensure teachers are grading on time.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Advanced Filtering & Date Ranges
- **Action:** Filter the summary grid.
- **UI/JS Logic:**
  - Integrates a complex `daterangepicker` (Today, Yesterday, Last 7 Days, This Month, etc.). Changing the date range instantly auto-submits the form.
  - Features cascading AJAX dropdowns: `Class/Section -> Subject -> Exam -> Paper -> Set`.

### FR-02: Summary Aggregation Grid
- **Action:** View the data.
- **System Behavior:** Displays a table with aggregated statistics:
  - **Assigned:** Count of students in `lms_exam_allocations`.
  - **Submitted:** Count of attempts in `lms_exam_attempts` where status is `SUBMITTED`, `EVALUATION_PENDING`, `EVALUATED`, or `RESULT_PUBLISHED`.
  - **Checked:** Count of attempts where status is `EVALUATED` or `RESULT_PUBLISHED`.

### FR-03: Action Routing
- **Action:** Click buttons in the Action column.
- **System Behavior:**
  - **Report Button:** Redirects to `lms-exam.exam.report` (Detailed analytics).
  - **Check Button:** Redirects to `lms-exam.exam.paper-check` for online papers.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Tracking Evaluation Progress
**As an** Academic Coordinator,
**I want to** see the "Submitted" vs "Checked" numbers for the Mid-Term English Exam,
**So that** I can remind the English teacher to finish grading the 15 pending papers before the deadline.

**Acceptance Criteria:**
- **Given** I am on the Online Assessment tab, **When** I look at the English paper row, **Then** I should see Assigned: 50, Submitted: 48, Checked: 33.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Data Scope** | The grid strictly forces `mode = ONLINE` behind the scenes via a hidden input to ensure data isolation from the Offline tab. |

---

## 7. Exception & Error Handling Scenarios
- **Scenario:** No exams match the selected date range.
  - *Response:* The table gracefully falls back to: "No exams found for the selected filters."

---

## 8. Dependency & Impact Mapping
### 8.1 Incoming Dependencies
- `lms_exam_papers`, `lms_exam_allocations`, `lms_exam_attempts`.

### 8.2 Outgoing Dependencies
- Provides entry points to the actual Assessment Grading screen and the Analytics Report screen.
