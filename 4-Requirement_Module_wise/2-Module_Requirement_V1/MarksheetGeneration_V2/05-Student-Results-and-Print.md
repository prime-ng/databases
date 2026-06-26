# Business Requirements Document (BRD)
## Module: Marksheet Generation
### Screen: Student Results & Print

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
This is the final output. The **Student Result** sub-module houses the computed marks (Subject-wise, IA-wise, Co-Scholastic) and provides mechanisms to export them to Excel or print them via dynamic HTML-to-PDF templates.

### 1.2 Why is this necessary? (Business Justification)
- **Deliverable:** The entire point of the module is to produce a printable or downloadable Report Card that complies with the school's format.

---

## 2. Document Scope
- **In-Scope:** `StudentResult`, `StudentSubjectResult`, `StudentIaMark`, Excel Export, and PDF Template Printing.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Result Storage & Aggregation
- **Student Result:** The master record representing one student's overall performance for a specific Schedule.
- **Relations:** 
  - `subjectResults`: The aggregated marks per scholastic subject.
  - `coscholasticResults`: Grades for non-academic areas.
  - `StudentSubjectExamMark`: Raw marks pulled from `LmsExam`.
  - `StudentIaMark`: Manual marks entered by teachers for notebooks, etc.
  - `StudentAttendance`: Attendance percentage fetched for the term.

### FR-02: Result Review & Overrides
- **System Behavior:** Handled by `StudentResultReviewService`. If a student was absent or caught cheating, admins can withhold their result or manually override the aggregated grade.

### FR-03: Export & Print Engine
- **Excel Export:** `Maatwebsite\Excel` is used via `StudentResultExport` to dump the raw matrix of a student's marks into `.xlsx`.
- **PDF Print Engine:** The system calls `Modules\Template\Facades\Template::render('MARKSHEET_PRINT', ...)` passing the `subjectId`, `classId`, `sessionId`, and `studentId`.
  - This dynamically generates an HTML payload based on the school's custom template design, which is then served as a Print view or a PDF download.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Printing a Generated Marksheet
**As a** Class Teacher,
**I want to** click "Print Marksheet" on a student's result page,
**So that** I can hand over the physical Report Card during the Parent-Teacher Meeting.

**Acceptance Criteria:**
- **Given** a Student Result exists, **When** I click Print, **Then** the `Template::render` engine fetches the `MARKSHEET_PRINT` template, binds the student's marks, and returns a formatted HTML/PDF view.
