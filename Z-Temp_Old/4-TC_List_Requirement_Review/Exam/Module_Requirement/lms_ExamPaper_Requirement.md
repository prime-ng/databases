# [Exam Papers] Creation & Allocation Tab Screen

---

## What Does This Screen Do?

The Exam Paper screen is where an administrator creates individual subject papers within an exam. Every exam can have multiple papers — one per subject. For example, the "Annual Exam 2025-26" for Class 10 can have separate papers for Mathematics (Online), Science (Offline), English (Online), Hindi (Online), and Social Science (Offline).

A paper is the most detailed configuration object in the exam module. It defines:
- **Which subject** the paper is for
- **What mode** the exam is conducted in — ONLINE (digital, students answer on computer/tablet) or OFFLINE (physical answer sheets)
- **How many marks** total and what the passing percentage is
- **How long** the exam lasts (duration), how many questions, negative marking
- **Online-specific settings** like proctoring, randomization, calculator, fullscreen, browser lock
- **Offline-specific settings** like how marks are entered (per-question or as a bulk total)
- **Question source settings** like whether to use only unused or authorized questions
- **Status** — the lifecycle stage (linked to Exam Status Events with `event_type=PAPER`)

---

## Real-Life Example

The Annual Exam for Class 10 is being set up. The Exam Coordinator, Mrs. Rao, has already created the exam "Annual 2025-26" with exam type "ANNUAL." Now she needs to add papers for each subject.

She opens the Creation & Allocation tab, clicks the "Exam Papers" sub-tab (second tab), and clicks "Add Exam Paper."

For Mathematics:
- Exam: Annual 2025-26
- Class: 10
- Subject: Mathematics
- Paper Code: ANNUAL_2025_MTH_ON (unique within this exam)
- Title: Annual 2025-26 - Mathematics - Online
- Mode: ONLINE
- Total Marks: 100
- Passing Percentage: 35
- Duration: 180 minutes
- Total Questions: 40
- Online Settings: Proctored ON, Shuffle Questions ON, Timer Enforced ON, Calculator ON

For Science (which has a practical component conducted offline):
- Mode: OFFLINE
- Offline Entry Mode: QUESTION_WISE (teachers enter marks per question)
- Question-wise File Upload: Yes (teachers can upload scanned answer sheets)

Each paper is now ready for further configuration: question sets, blueprints, scopes, and allocation to students.

---

## How the List Page Works

The Exam Papers index is the second sub-tab inside the Creation & Allocation tab (`active_tab=exam_paper`). It loads a paginated list of all papers, 10 per page, newest first.

### How Data Is Loaded
The papers data is fetched via the Exam Query Service's `examPapersQuery()` method. This service builds a filtered query with relationships (exam, class, subject, status) and can be called from either the `ExamPaperController@index()` (standalone page) or the `LmsExamController@creationAllocation()` (tab-based view).

### Filters Available
- **Exam** — Filter by parent exam (dropdown of all active exams)
- **Class** — Filter by class (dropdown of all active classes)
- **Subject** — Filter by subject (dropdown of all active subjects)
- **Mode** — Filter by ONLINE or OFFLINE
- **Status** — Filter by paper status (dropdown of all active status events)
- **Active Status** — Show only active or inactive papers
- **Search** — Free-text search across paper code, title, instructions, exam title, exam code, subject name, subject code

### What Each Row Shows
- **Paper Code** — Unique code for the paper within its exam
- **Title** — Display title
- **Exam** — Parent exam name
- **Class** — Associated class
- **Subject** — Associated subject
- **Mode** — ONLINE / OFFLINE badge
- **Total Marks** — Maximum marks
- **Status** — Current lifecycle status
- **Active** — Toggle switch (AJAX)
- **Actions** — View, Edit, Delete

### Pagination
10 rows per page. Uses `exam_paper_page` as the page name parameter.

### Trash Page
A separate page showing soft-deleted papers. From here you can Restore or Force Delete.

---

## How to Create

**Step 1:** Open the Creation & Allocation tab, click "Exam Papers" sub-tab, then click "Add Exam Paper."

**Step 2:** Fill in the form. Here are all the fields, grouped by category:

### Core Fields
- **Exam** (Required) — Select the parent exam from the dropdown of all active exams.
- **Class** (Required) — Select the class this paper is for. Must exist in sch_classes.
- **Subject** (Required) — Select the subject this paper tests.
- **Paper Code** (Required) — A unique code within the exam. For example, if the exam is "Annual 2025" and the subject is "Mathematics Online," you might use `ANNUAL_2025_MTH_ON`. Max 50 characters. The system validates that this code is unique within the same exam — you cannot have two papers with code `MTH_ON` in the same exam, but you can have it in different exams.
- **Title** (Required) — Human-readable title (max 150 characters).
- **Mode** (Required) — Choose ONLINE or OFFLINE. This determines which settings below are applicable.
- **Total Marks** (Required) — Maximum marks for this paper (numeric, up to 999,999.99).
- **Passing Percentage** (Required) — The percentage of total marks needed to pass (0-100).
- **Total Questions** (Optional) — Number of questions. Used for validation against blueprints and scopes.
- **Duration Minutes** (Optional) — Duration in minutes (1-1440). Relevant for online exams.
- **Instructions** (Optional) — Free-text instructions displayed to students before the exam starts.
- **Negative Marks** (Optional) — Marks deducted for wrong answers (default 0).

### Online-Specific Settings (all are boolean toggles)
These only apply when Mode = ONLINE:
- **Is Proctored** — Teacher can monitor students' screens during the exam
- **Is AI Proctored** — AI automatically flags suspicious activity
- **Fullscreen Required** — Forces the browser into fullscreen mode
- **Browser Lock Required** — Prevents students from switching tabs or opening new windows
- **Shuffle Questions** — Randomize the order of questions for each student
- **Shuffle Options** — Randomize the order of answer options for each student
- **Timer Enforced** — The timer auto-submits when time runs out
- **Allow Calculator** — Shows a built-in calculator
- **Show Marks Per Question** — Display marks for each question to the student
- **Is Randomized** — Randomize the set of questions shown (if multiple sets exist)

All online boolean fields default to false (unchecked) except `timer_enforced` which defaults to true (checked).

### Offline-Specific Settings
These only apply when Mode = OFFLINE:
- **Offline Entry Mode** (Required if Mode=OFFLINE) — Choose how marks are entered:
  - `BULK_TOTAL` — Teacher enters a single total marks for all questions combined
  - `QUESTION_WISE` — Teacher enters marks per individual question
- **Question-Wise File Upload** (Optional) — Whether teachers can upload scanned answer sheets per question

### Question Source Settings
- **Only Unused Questions** — If checked, only questions that have NOT been used in any previous exam can be selected for this paper
- **Only Authorised Questions** — If checked, only questions marked as `for_quiz=1` can be selected
- **Difficulty Config** — An optional difficulty distribution configuration that enforces a specific mix of easy/medium/hard questions
- **Ignore Difficulty Config** — If checked, the difficulty config is treated as a suggestion (warnings only) rather than a strict requirement

### Status
- **Status** (Required) — The current lifecycle stage. The dropdown shows only status events with `event_type=PAPER` (NOT exam statuses). Options include: NOT_STARTED, IN_PROGRESS, SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED, ABSENT, CANCELLED.

### Active
- **Active** — Checked by default. Controls visibility.

**Step 3:** Click "Create Exam Paper." The system:
1. Validates all fields (via `ExamPaperRequest`)
2. Converts all checkbox values to booleans via `prepareForValidation`
3. Creates the record and logs: "A new exam paper was created."
4. Redirects to the Creation & Allocation tab with success

### Form Request Details
The `ExamPaperRequest` has extensive validation:
- `exam_id`, `class_id`, `subject_id` — required, must exist in respective tables
- `paper_code` — required, string, max:50, **unique within exam** (`unique` rule scoped by `exam_id`)
- `title` — required, max:150
- `mode` — required, must be ONLINE or OFFLINE
- `total_marks` — required, numeric, min:0, max:999999.99
- `passing_percentage` — required, numeric, min:0, max:100
- `total_questions` — nullable, integer, min:0
- `duration_minutes` — nullable, integer, min:1, max:1440
- `offline_entry_mode` — required_if:mode,OFFLINE, must be BULK_TOTAL or QUESTION_WISE
- `status_id` — required, must exist in lms_exam_status_events
- All boolean fields are validated as boolean

The `prepareForValidation` method converts ALL checkbox/toggle fields from HTML form values to proper booleans: `is_proctored`, `is_ai_proctored`, `fullscreen_required`, `browser_lock_required`, `shuffle_questions`, `is_active`, `only_unused_questions`, `only_authorised_questions`, `ignore_difficulty_config`, `allow_calculator`, `show_marks_per_question`, `is_randomized`, `shuffle_options`, `timer_enforced`, `is_ques_wise_file_upload`.

---

## How to Edit/Delete

### Editing
Click Edit → The system checks usage BEFORE opening the edit form.

**Usage Check Logic (Critical — Broader than stated in original requirements):**
The `ExamPaperUsageCheckService` checks FIVE different tables, not just allocations and attempts:
1. **Exam Allocations** (`lms_exam_allocations`) — Has this paper been assigned to students?
2. **Paper Sets** (`lms_exam_paper_sets`) — Does this paper have question sets defined?
3. **Blueprints** (`lms_exam_blueprints`) — Does this paper have blueprints?
4. **Exam Results** (`lms_exam_results`) — Are there any computed results for this paper?
5. **Student Attempts** (`lms_exam_attempts`) — Have students attempted this paper?

If ANY of these exist, editing and deletion are blocked: "Cannot edit/update/delete/restore this exam paper because it is allocated or has student attempts."

**This means:** The moment you create a paper set or blueprint for a paper, it is already "in use" and cannot be edited — even before any student has been allocated or attempted it. This is stricter than what was previously documented.

If allowed: The edit form opens with current values and all the same dropdowns (exams, classes, subjects, statuses filtered to PAPER type, difficulty configs).

After saving: Old/new value comparisons are logged.

### Deleting (Soft Delete)
Same check → If blocked, error shown. If allowed:
1. Sets `is_active = false` (deactivates)
2. Soft-deletes (`deleted_at = now`)
3. Logs: "Exam paper was deactivated and trashed."

### Restoring from Trash
Same check → If the paper STILL has allocations, sets, blueprints, results, or attempts (these foreign keys persist in the database even after soft-delete), restore is blocked. If allowed:
1. Restores (`deleted_at = null`)
2. Sets `is_active = true`
3. Logs and redirects

### Force Delete (Permanent)
Same check → If passed, removes permanently.

### Toggle Active Status (AJAX)
Toggle the active/inactive state. **No usage check** — always allowed. Returns JSON success.

---

## Business Rules Summary

| # | Rule | Details |
|---|------|---------|
| 1 | **Paper Code Unique Per Exam** | The combination of `exam_id` + `paper_code` must be unique. You can have `MTH_ON` in Exam A and `MTH_ON` in Exam B, but not twice in Exam A. |
| 2 | **Usage Check Blocks Edit/Delete/Restore/ForceDelete** | Blocked if ANY of these exist: allocations, paper sets, blueprints, results, OR attempts. This is broader than just "allocations or attempts." |
| 3 | **Usage Check NOT on Toggle** | Status toggle is always allowed. |
| 4 | **Status Dropdown Filtered to PAPER Type** | When creating/editing, the status dropdown only shows status events with `event_type=PAPER`. |
| 5 | **Mode Determines Available Settings** | ONLINE mode shows proctoring, randomization, etc. OFFLINE mode shows entry mode and file upload. |
| 6 | **Offline Entry Mode Required for OFFLINE** | If mode is OFFLINE, `offline_entry_mode` is required (BULK_TOTAL or QUESTION_WISE). |
| 7 | **Deactivation on Delete** | Soft-delete sets `is_active = false` before `deleted_at`. |
| 8 | **Reactivation on Restore** | Restore sets `is_active = true` after removing `deleted_at`. |
| 9 | **All Booleans Converted** | All checkbox fields are explicitly converted to booleans in `prepareForValidation`. |
| 10 | **Difficulty Config Is Optional** | `difficulty_config_id` is nullable and only checked if provided. |
| 11 | **Duration Has Constraints** | Duration must be between 1 minute and 1440 minutes (24 hours). |
| 12 | **Total Marks Has Upper Limit** | Total marks cannot exceed 999,999.99. |
| 13 | **Paper Existence Check in Upload** | The upload tab validates that the selected paper's mode matches (ONLINE paper for online upload, OFFLINE paper for offline upload). |
| 14 | **Create Form Loads Difficulty Configs** | The create form also loads active `DifficultyDistributionConfig` options for selection. |

### In Plain English: When Is a Paper "In Use"?
A paper is "in use" as soon as ANY of these happen:
- Someone creates an **allocation** (assigns even one student to this paper)
- Someone creates a **paper set** (defines a question set for this paper)
- Someone creates a **blueprint** (defines the structure of questions)
- Someone computes a **result** for this paper
- A student makes an **attempt** (starts or submits the exam)

The most common "gotcha" is that creating a paper set or blueprint immediately locks the paper from editing — you can't go back and change paper settings like total marks or mode after sets are created, even if no students have been assigned yet.

---

## Validation & Error Messages

| Scenario | Message | Source |
|----------|---------|--------|
| Exam missing | "Exam is required" | FormRequest |
| Class missing | "Class is required" | FormRequest |
| Subject missing | "Subject is required" | FormRequest |
| Paper code missing | "Paper code is required" | FormRequest |
| Duplicate paper code in exam | "This paper code already exists for this exam" | FormRequest (unique scoped by exam_id) |
| Title missing | "Paper title is required" | FormRequest |
| Mode missing | "Exam mode is required" | FormRequest |
| Total marks missing | "Total marks are required" | FormRequest |
| Passing percentage missing | "Passing percentage is required" | FormRequest |
| Offline entry mode missing | "Entry mode is required for offline exams" | FormRequest (required_if) |
| Status missing | "Status is required" | FormRequest |
| Edit blocked (in use) | "Cannot edit this exam paper because it is allocated or has student attempts." | Controller usage check |
| Update blocked (in use) | "Cannot update this exam paper because it is allocated or has student attempts." | Controller usage check |
| Delete blocked (in use) | "Cannot delete this exam paper because it is allocated or has student attempts." | Controller usage check |
| Restore blocked (in use) | "Cannot restore this exam paper because it is allocated or has student attempts." | Controller usage check |
| Force delete blocked (in use) | "Cannot permanently delete this exam paper because it is allocated or has student attempts." | Controller usage check |
| DB failure on create | "Failed to create exam paper. Please try again." | Exception catch |
| DB failure on update | "Failed to update exam paper. Please try again." | Exception catch |
| DB failure on delete/restore/force | "Failed to [action] exam paper. Please try again." | Exception catch |
| Toggle failure | "Failed to update status." | AJAX error |

---

## Activity Log Messages

| Action | Log Message |
|--------|-------------|
| Create | "A new exam paper was created." |
| Update | "Exam paper updated with changes: {\"field\":{\"old\":\"X\",\"new\":\"Y\"}}" |
| Soft Delete | "Exam paper was deactivated and trashed." |
| Restore | "Exam paper was restored." |
| Force Delete | "Exam paper was permanently deleted." |
| Toggle | "Exam paper status was updated." |

---

## AJAX Endpoints

| Endpoint | Purpose |
|----------|---------|
| `toggleStatus` | Toggle active/inactive via AJAX |
| `getPapersByExam` | Get papers for a specific exam (used in dependent dropdowns) |
| `getSetsByPaper` | Get paper sets for a specific paper (used in answer sheet upload) |

---

## Permissions

| Gate | Methods |
|------|---------|
| `tenant.exam-paper.viewAny` | index() |
| `tenant.exam-paper.view` | show() |
| `tenant.exam-paper.create` | create(), store() |
| `tenant.exam-paper.update` | edit(), update(), toggleStatus() |
| `tenant.exam-paper.delete` | destroy() |
| `tenant.exam-paper.restore` | trashed(), restore() |
| `tenant.exam-paper.forceDelete` | forceDelete() |

---

## Related Screens

- **Exam Creation (Creation & Allocation tab)** — The parent exam is created here first
- **Paper Sets** — Question sets are created for a paper after it exists
- **Paper Set Questions** — Individual questions are assigned to paper sets
- **Exam Blueprints** — Structure definition for question types in the paper
- **Exam Scopes** — Topic coverage configuration for the paper
- **Exam Allocation** — Student assignment to papers
- **Answer Sheet Upload** — Both online and offline upload screens reference papers
- **Evaluation/Paper Check** — Teachers evaluate student attempts for this paper
