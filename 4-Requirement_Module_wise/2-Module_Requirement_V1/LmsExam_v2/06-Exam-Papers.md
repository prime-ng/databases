# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Creation & Allocation 
### Screen: Exam Papers (Tab 2)

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
While the parent "Exam" sets the timeframe, the **Exam Papers** screen defines the actual subject-level assessment rules. It is a 2-Tab wizard distinguishing between **Online** and **Offline** modes, enforcing proctoring rules, and defining detailed parameters.

### 1.2 Why is this necessary? (Business Justification)
- **Mode Distinctions:** An Online exam requires strict rules (Browser lock, AI proctoring, strict timers) which an Offline exam does not. This wizard separates the academic information from the technical configuration to reduce cognitive load.

---

## 2. Document Scope
- **In-Scope:** The 2-Tab UI structure (`Basic Information` and `Paper Configuration`). Javascript-driven visibility for Offline parameters and Difficulty toggles. Advanced security switches.
- **Out-of-Scope:** Taking the actual exam.

---

## 3. User Personas
1. **Subject Head / Teacher:** Defines the rules for their specific subject's paper.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Tab 1 - Basic Information (`?tab=basic-info`)
- **Action:** Open the create page. Tab 1 is active.
- **Fields & Validations:**
  - **Exam:** Dropdown to select the parent Exam.
  - **Class:** Read-only. When an `Exam` is selected, an AJAX call fetches the class linked to that Exam and locks it here to prevent mismatch.
  - **Subject:** Dropdown. Selecting the Class triggers AJAX to load applicable Subjects.
  - **Paper Code & Title:** Text fields.
  - **Exam Mode:** Dropdown (`ONLINE` or `OFFLINE`). This choice heavily influences Tab 2.
  - **Status:** Dropdown (DRAFT, etc.).
  - **Instructions:** Textarea.
- **Interactivity:** A "Next: Configuration" button switches the view to Tab 2 programmatically.

### FR-02: Tab 2 - Paper Configuration (`?tab=paper-config`)
- **Action:** Navigate to configure technical rules.
- **Numerical Boundaries:**
  - `total_marks`, `passing_percentage`, `total_questions`, `negative_marks`, `duration_minutes`.
- **Difficulty & Offline Logic (JS Behavior):**
  - **Difficulty Config:** A dropdown for difficulty matrix. If the user checks the `ignore_difficulty_config` switch (in advanced settings), JS disables this dropdown and greys it out (`bg-light`).
  - **Offline Entry Section:** This block is **hidden entirely** unless the Mode selected in Tab 1 was `OFFLINE`.
    - Contains `offline_entry_mode` (`BULK_TOTAL` or `QUESTION_WISE`).
    - Contains `is_ques_wise_file_upload` toggle. If `BULK_TOTAL` is selected, JS hides and forcefully unchecks this toggle, as file proof per question is meaningless without question-wise marks.

### FR-03: The 14 Advanced Exam Settings (Toggle Switches)
Tab 2 contains a massive grid of 14 boolean switches controlling the exam's behavior:
1. **Proctored Exam:** Enables basic camera proctoring.
2. **AI Proctoring:** Enables advanced face-tracking and anomaly detection.
3. **Fullscreen Req:** Forces the browser into F11 fullscreen.
4. **Browser Lock:** Prevents switching tabs (disables right-click, blur events).
5. **Shuffle Questions:** Randomizes question order per student.
6. **Unused Questions:** Filters out questions already attempted by the class.
7. **Authorised Qs:** Pulls only approved questions from the bank.
8. **Allow Calculator:** Enables an on-screen calculator during the exam.
9. **Show Marks/Q:** Displays the weightage of each question to the student.
10. **Randomize Qs:** System-generated random selection.
11. **Shuffle Options:** Randomizes MCQ A/B/C/D order.
12. **Enforce Timer:** Mandates the `duration_minutes` countdown.
13. **Ignore Difficulty Config:** Disables the strict Easy/Medium/Hard validation.
14. **Is Active:** Master soft-deactivation toggle.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Intelligent Offline Mode Hiding
**As a** Subject Head configuring an Online test,
**I want the** UI to hide offline data entry options,
**So that** I don't accidentally fill out irrelevant fields.

**Acceptance Criteria:**
- **Given** I select `ONLINE` as the Exam Mode on Tab 1, **When** I click "Next: Configuration", **Then** the "Offline Entry Mode" dropdown and "Enable Q-Wise File Upload" toggle are completely hidden from the screen.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_exams`, `sch_classes`, `sch_subjects`, `lms_difficulty_distribution_configs`.
- **Outgoing Dependencies:** `lms_exam_paper_sets`, `lms_exam_scopes`. Altering the `offline_entry_mode` after marks are entered will corrupt the assessment data.
