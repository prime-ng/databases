# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Offline Marks & Descriptive Uploads 
### Screen: Upload Answer Sheets -> Tab 1: Descriptive Ques (Online Exam)

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Descriptive Ques (Online Exam)** tab provides a highly specialized interface for teachers to review and manage descriptive (subjective) answers submitted by students during an **Online Exam**. It allows teachers to upload their own annotated files (like a checked PDF) back to the student.

### 1.2 Why is this necessary? (Business Justification)
- **Teacher Feedback:** When a student types a long essay answer online, the teacher might want to download it, highlight mistakes in red, and upload the corrected PDF back to the system. This tab facilitates that exact "Evidence/Feedback Upload" process.

---

## 2. Document Scope
- **In-Scope:** Filtering online exam attempts, viewing descriptive questions, and uploading teacher-annotated feedback files per question.
- **Out-of-Scope:** Grading the question (Grading happens in the Assessment tab).

---

## 3. User Personas
1. **Subject Teacher / Evaluator:** Wants to provide rich, file-based feedback on specific subjective answers.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Advanced Search & Filtering
- **Action:** User filters to find a specific paper's attempts.
- **UI/JS Logic:** 
  - **Cascading Dropdowns:** Selecting a `Class` triggers AJAX calls to populate `Sections`, `Subjects`, `Exams`, and `Students`. Selecting an `Exam` populates `Papers`. Selecting a `Paper` populates `Paper Sets`.
  - **Select2 Integration:** The Student dropdown is searchable (`select2`) for quick lookups.

### FR-02: Descriptive Question Fetching
- **Action:** Teacher clicks the "Question Wise Assessment" button (File-Pen icon) for a specific student.
- **UI/JS Logic:** 
  - Triggers an AJAX GET to `lms-exam.exam.question-wise.data` passing `mode: 'ONLINE'`.
  - System specifically filters and returns **ONLY** descriptive questions (Short/Long answers). MCQs are completely ignored here.

### FR-03: Per-Question File Upload
- **Action:** Inside the modal, the teacher uploads a PDF/Image against Q1.
- **System Behavior:** 
  - The UI displays the Question Type and a tooltip for the Question Text.
  - If a file was already uploaded by the teacher, a "View" badge is shown.
  - On Save, a `FormData` object bundles the files and sends a POST to `lms-exam.exam.question-wise.save`.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Uploading Annotated Feedback
**As a** Teacher,
**I want to** upload a PDF with my corrections for Question 4 of John's online exam,
**So that** John can download it and see why marks were deducted.

**Acceptance Criteria:**
- **Given** I open the Descriptive Upload modal, **When** I select a PDF for Q4 and click Save, **Then** the file is stored in `Prime\Models\Media` and linked to John's specific `lms_exam_attempt_answers` record.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Attachments** | Must be valid file types (PDF, Images). The DOM enforces `accept="application/pdf,image/*"`. |

---

## 7. Exception & Error Handling Scenarios
- **Scenario:** The online paper has only MCQs, no descriptive questions.
  - *Response:* The modal opens but displays: "No descriptive questions found for this student."
- **Scenario:** File upload fails due to size limits.
  - *Response:* SweetAlert shows an error message returned from the server.

---

## 8. Dependency & Impact Mapping
### 8.1 Incoming Dependencies
- `lms_exam_attempts` (must exist and not be `NOT_STARTED`).
- `lms_exam_attempt_answers` (the specific answers to attach files to).

### 8.2 Outgoing Dependencies
- **Student Portal:** The uploaded files will become visible to the student when they view their results/feedback.
