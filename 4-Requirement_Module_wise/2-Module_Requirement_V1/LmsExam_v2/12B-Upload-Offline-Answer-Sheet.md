# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Offline Marks & Descriptive Uploads 
### Screen: Upload Answer Sheets -> Tab 2: Answer Sheet Upload (Offline Exam)

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Answer Sheet Upload (Offline Exam)** tab is the primary digitization engine for physical pen-and-paper exams. It handles both bulk (total score) and highly granular question-wise (OMR-style or descriptive) offline data entry.

### 1.2 Why is this necessary? (Business Justification)
- **Data Digitization:** Schools conducting physical exams need those marks in the LMS to generate automated report cards.
- **OMR Simulation:** The system allows teachers to manually punch in a student's MCQ choices (A, B, C, D) from a physical paper, letting the system auto-grade it, OR directly enter marks for subjective questions.

---

## 2. Document Scope
- **In-Scope:** `BULK_TOTAL` uploads (single file, single score) and `QUESTION_WISE` uploads (OMR-style MCQ punching, file evidence per question).
- **Out-of-Scope:** Final result publishing (handled in Assessment tab).

---

## 3. User Personas
1. **Data Entry Operator / Teacher:** Looks at physical answer sheets and types the data into the system.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Advanced Search & Filtering
- **Action:** User filters for an Offline Exam Paper.
- **UI/JS Logic:** Identical cascading dropdowns (`Class -> Sections/Subjects -> Exams -> Papers -> Sets -> Students`) as the Online tab, powered by AJAX.

### FR-02: Mode-Based Routing (Bulk vs Q-Wise)
- **Action:** Teacher clicks the Upload button (Upload Icon) for a student.
- **UI/JS Logic:** 
  - The blade reads the Paper's `offline_entry_mode` and `is_ques_wise_file_upload` settings.
  - If `QUESTION_WISE` is true (or file upload is true), Javascript routes the user to `proceedToQuestionWise()`.
  - If `BULK_TOTAL`, Javascript routes to `proceedToBulk()`.

### FR-03: Bulk Total Modal
- **Action:** `proceedToBulk()` executes.
- **System Behavior:** 
  - Opens a simple modal asking for a single PDF upload (`answer_sheet`). 
  - Notes: "Marks can be entered later after checking the paper." 
  - Submits via AJAX to `lms-exam.marks.bulk-upload`.

### FR-04: Question-Wise Modal (OMR & Descriptive)
- **Action:** `proceedToQuestionWise()` executes.
- **System Behavior:** 
  - Triggers AJAX to fetch ALL questions in the paper set.
  - **MCQ / MSQ Rendering:** If the question is an MCQ, the JS generates A, B, C, D radio buttons (or checkboxes for MSQ). The teacher literally clicks what the student marked on the physical paper!
  - **Descriptive Rendering:** If non-MCQ, it provides a file upload input (`.qw-file`) for evidence.
  - Submits via AJAX to `lms-exam.exam.question-wise.save`.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Simulating OMR Entry
**As a** Data Entry Operator,
**I want to** look at John's physical MCQ answer sheet and quickly click A, B, D, C on the screen,
**So that** the LMS can auto-grade the physical exam just like an online exam.

**Acceptance Criteria:**
- **Given** I open the Q-Wise modal for an MCQ paper, **When** I click the generated A/B/C/D radio buttons and save, **Then** the `option_id` array is sent to the server to simulate an online attempt.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **File Formats** | Bulk expects `application/pdf`. Q-Wise expects `application/pdf,image/*`. |
| **Radio/Checkbox Arrays** | The JS dynamically constructs `questions[qid][option_id]` arrays based on single (radio) or multi (checkbox) selections. |

---

## 7. Exception & Error Handling Scenarios
- **Scenario:** Teacher forgets to select a Paper Set before clicking "View Questions" icon.
  - *Response:* SweetAlert warning: "Please select a Paper Set first."

---

## 8. Dependency & Impact Mapping
### 8.1 Incoming Dependencies
- `lms_exam_papers.offline_entry_mode`: Directly dictates which JavaScript modal logic (`Bulk` vs `Q-Wise`) is executed.

### 8.2 Outgoing Dependencies
- **`lms_exam_results` / `lms_offline_exam_upload_marks`:** The data entered here feeds the entire assessment and result generation pipeline.
