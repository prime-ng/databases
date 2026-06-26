# LMS Homework Templates — Requirement Document

## 1. Screen Purpose & Overview

The **Homework Creation & Management** screen allows teachers to define, edit, and publish homework templates. A homework template registers the syllabus alignment, submission parameters, grading limits, scheduling dates, and conditional release mechanisms.

Saving homework places it in a `DRAFT` status. Clicking **"Publish"** changes its state to `PUBLISHED` and bulk-generates individual student assignment tracking records (`lms_homework_assignment`).

---

## 2. Common Business Use Cases

1. **Creating Graded Homework:** A teacher drafts an Algebra homework assigned to Class 10-A, setting it to gradable with $\text{max\_marks} = 50.00$ and $\text{passing\_marks} = 20.00$.
2. **Scheduling Topic Release:** Configuring homework with a release condition of `ON_TOPIC_COMPLETE` and binding it to a syllabus topic schedule. The homework automatically releases when the teacher marks that topic completed.
3. **Allowing Late Submissions:** Drafting a hybrid submission assignment that allows late submissions, alerting the student but permitting file uploads past the due date.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `lms_homework`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `academic_session_id` | `int unsigned` | No | N/A | Foreign key to `sch_org_academic_sessions_jnt.id`. |
| `class_id` | `int unsigned` | No | N/A | Foreign key to `sch_classes.id`. |
| `section_id` | `int unsigned` | Yes | `NULL` | Foreign key to `sch_sections.id`. NULL means it applies to all sections of the class. |
| `subject_id` | `int unsigned` | No | N/A | Foreign key to `sch_subjects.id`. |
| `lesson_id` | `int unsigned` | Yes | `NULL` | Foreign key to `slb_lessons.id`. |
| `topic_id` | `int unsigned` | Yes | `NULL` | Foreign key to `slb_topics.id`. |
| `schedule_id` | `int unsigned` | Yes | `NULL` | Foreign key to `slb_syllabus_schedule.id`. Used when release condition is topic-based. |
| `title` | `varchar(255)` | No | N/A | Title of the homework. |
| `description` | `longtext` | No | N/A | Multi-line text block supporting HTML/Markdown. |
| `hw_attachment_media_id`| `json` | Yes | `NULL` | JSON structure carrying metadata of uploaded reference documents. |
| `submission_type_id` | `int unsigned` | No | N/A | Foreign key to `sys_dropdown_table.id` (`TEXT`, `FILE`, `HYBRID`, `OFFLINE_CHECK`). |
| `is_gradable` | `tinyint(1)` | No | `1` | Evaluation flag (0 = Not gradable, 1 = Gradable). |
| `max_marks` | `decimal(5,2)` | Yes | `NULL` | Maximum score. Required if `is_gradable = 1`. |
| `passing_marks` | `decimal(5,2)` | Yes | `NULL` | Minimum passing score. Required if `is_gradable = 1`. |
| `difficulty_level_id` | `int unsigned` | Yes | `NULL` | Foreign key to `slb_complexity_level.id` (`EASY`, `MEDIUM`, `HARD`). |
| `auto_publish_score` | `tinyint(1)` | No | `0` | Toggle to auto-release scores to student portal on grading. |
| `assign_date` | `datetime` | No | N/A | Date/time homework is scheduled to become active. |
| `due_date` | `datetime` | No | N/A | Homework deadline. Must satisfy $\text{due\_date} \ge \text{assign\_date}$. |
| `allow_late_submission` | `tinyint(1)` | No | `0` | Default policy for late submissions. |
| `realease_condition` | `enum` | No | `ON_TOPIC_COMPLETE` | Release trigger modes (`IMMEDIATE`, `ON_TOPIC_COMPLETE`, `ON_SCHEDULED_DATE`). **Note database spelling.** |
| `release_scheduled_date`| `datetime` | Yes | `NULL` | Scheduled release date. Required if release condition is date-based. |
| `status_id` | `int unsigned` | No | N/A | Foreign key to `sys_dropdown_table.id` (`DRAFT`, `PUBLISHED`, `ARCHIVED`). |
| `is_active` | `tinyint(1)` | No | `1` | Operational status indicator. |
| `created_by` | `int unsigned` | No | N/A | Foreign key to `sys_users.id` (Teacher ID). |
| `updated_by` | `int unsigned` | Yes | `NULL` | Foreign key to `sys_users.id`. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Modification timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Homework Title** | Text Input | Yes | Max 255 characters. | None |
| **Description** | Rich Text Editor | Yes | Support HTML tags and Markdown. Longtext. | None |
| **Class** | Dropdown | Yes | Select active class from `sch_classes`. | None |
| **Section** | Dropdown | No | Select section from `sch_sections`. Empty = All. | None |
| **Subject** | Dropdown | Yes | Select active subject associated with the class. | None |
| **Lesson** | Dropdown | No | Filtered list based on class/subject. | None |
| **Topic** | Dropdown | No | Filtered list based on lesson. | None |
| **Submission Type** | Select Dropdown | Yes | Maps to dropdown IDs (`TEXT`, `FILE`, `HYBRID`, `OFFLINE`). | None |
| **Is Gradable** | Checkbox | No | Boolean toggle. | Checked (1) |
| **Max Marks** | Numeric Input | Yes (if Gradable) | Positive decimal ($\text{max\_marks} > 0.00$). | None |
| **Passing Marks** | Numeric Input | Yes (if Gradable) | Decimal. Must satisfy $0.00 < \text{passing\_marks} \le \text{max\_marks}$. | None |
| **Assign Date** | Date/Time Picker| Yes | Standard datetime. | Current Date |
| **Due Date** | Date/Time Picker| Yes | Must satisfy $\text{due\_date} \ge \text{assign\_date}$. | Current Date + 7 Days |
| **Allow Late Submission**| Checkbox | No | Boolean toggle. | Unchecked (0) |
| **Release Condition** | Radio Buttons | Yes | `IMMEDIATE` \| `ON_TOPIC_COMPLETE` \| `ON_SCHEDULED_DATE`. | `ON_TOPIC_COMPLETE` |
| **Syllabus Schedule** | Dropdown select | Yes (if Topic) | Required if Release Condition is `ON_TOPIC_COMPLETE`. | None |
| **Release Date** | Date/Time Picker| Yes (if Date) | Required if Release Condition is `ON_SCHEDULED_DATE`. | None |
| **Difficulty Level** | Dropdown select | No | Maps to `EASY`, `MEDIUM`, `HARD` dropdowns. | None |
| **Auto Publish Score** | Checkbox | No | Boolean toggle. | Unchecked (0) |

---

## 5. Business Logic & Validation Policies

1. **Grading Configurations**:
   * If `is_gradable = 1`, both `max_marks` and `passing_marks` must be set. If either is missing, validation returns: *"The max marks and passing marks fields are required when homework is gradable."*
   * The inequality $\text{passing\_marks} \le \text{max\_marks}$ must hold. A violation triggers: *"Passing marks cannot exceed maximum marks."*
2. **Release Scheduling Constraints**:
   * If `realease_condition = 'ON_SCHEDULED_DATE'`, `release_scheduled_date` is mandatory.
   * If `realease_condition = 'ON_TOPIC_COMPLETE'`, `schedule_id` is mandatory.
3. **Locking Policy**:
   * While status is `DRAFT`, teachers can update or delete templates.
   * When the status transitions to `PUBLISHED`, the template is locked. Updates or deletions return a 403 authorization/business restriction.
4. **Publish Bulk Action**:
   * Publishing initiates a database transaction. The system fetches all active student enrollments matching `class_id` and `section_id` (or all sections if null) for the current `academic_session_id`.
   * For each student, it creates an `lms_homework_assignment` record. If the release condition is `IMMEDIATE`, the assignment sets `is_released = 1`, `released_at = NOW()`, and status to `ASSIGNED`. Otherwise, it sets `is_released = 0` and status to `PENDING_RELEASE`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher.
* Navigate to LMS Homework portal and click **"Create Homework"**.

### Scenario A: Happy Path Create Draft
1. Enter Title: `Quadratic Equations Practice`.
2. Enter Description: `Complete problems 1 through 10 on the worksheet. Upload steps.`
3. Select Class: `Class 10`, Section: `Section A`, Subject: `Mathematics`.
4. Select Submission Type: `FILE`.
5. Keep **"Is Gradable"** checked. Enter Max Marks: `50` and Passing Marks: `20`.
6. Select Release Condition: `IMMEDIATE`.
7. Set Assign Date: Current time. Set Due Date: Current time + 3 days.
8. Click **"Save Draft"**.
9. **Expected Result**: Redirects to homework dashboard. Flash alert displays: *"Homework draft saved successfully."* Status shows `DRAFT`.

### Scenario B: Marks and Date Validations
1. Open the created DRAFT homework in Edit mode.
2. Change Passing Marks to `60` (exceeding Max Marks of 50).
3. Change Due Date to a time before Assign Date.
4. Click **"Update"**.
5. **Expected Result**: Form submission fails, displaying:
   * *"Passing marks cannot exceed maximum marks."*
   * *"The due date must be a date after or equal to the assign date."*

### Scenario C: Publishing Homework
1. Locate `Quadratic Equations Practice` on the dashboard.
2. Click the **"Publish"** icon/button.
3. Confirm the modal prompt: *"Are you sure you want to publish? This will lock the homework and notify students."*
4. **Expected Result**: Dashboard shows status changed to `PUBLISHED`. Edit and Delete buttons for this homework are disabled. In the background, `lms_homework_assignment` records are created for all students enrolled in Class 10-A.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/lms-home-work/home-works/create`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/lms-home-work/home-works/create')
            ->type('title', 'Dusk Math Homework')
            ->type('description', 'Solve all exercises')
            ->select('class_id', $this->classId)
            ->select('subject_id', $this->subjectId)
            ->select('submission_type_id', $this->fileSubmissionId)
            ->type('max_marks', '100')
            ->type('passing_marks', '40')
            ->select('realease_condition', 'IMMEDIATE')
            ->press('@save-draft-btn')
            ->assertSee('saved successfully');
});
```

### 3. Publishing Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/lms-home-work/home-works')
            ->click('@publish-btn-' . $this->draftHomeworkId)
            ->acceptDialog()
            ->assertSee('published successfully')
            ->assertMissing('@edit-btn-' . $this->draftHomeworkId);
});
```
