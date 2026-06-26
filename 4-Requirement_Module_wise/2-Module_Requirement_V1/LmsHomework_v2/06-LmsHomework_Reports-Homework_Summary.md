# LMS Homework Summary Reports — Requirement Document

## 1. Screen Purpose & Overview

The **Homework Summary** report screen provides a consolidated tabular grid of all student homework assignments. It allows teachers and administrators to view submission statuses, verify student progress, filter by class/section, and check if deadlines are met.

---

## 2. Common Business Use Cases

1. **Reviewing Class Submissions:** A teacher selects Class 10-B and Mathematics, viewing a list of all students and their homework statuses (`SUBMITTED`, `LATE_SUBMITTED`, `OVERDUE`, `GRADED`).
2. **Identifying Delinquent Students:** Filtering the grid to show only `OVERDUE` assignments for a specific topic, identifying students who need follow-up.
3. **Tracking Class Performance:** Reviewing obtained marks across students to calculate the class average score for a specific subject module.

---

## 3. Database Schema & Data Dictionary

*   **Primary Tables**: `lms_homework`, `lms_homework_assignment`, `lms_homework_submissions`
*   **Joins Mapped**:
    *   `lms_homework_assignment` inner join `std_students` on `student_id`
    *   `lms_homework_assignment` left join `lms_homework_submissions` on `assignment_id`
    *   `lms_homework_assignment` inner join `lms_homework` on `homework_id`

| Output Column | Source Table | Source Column | Description / Mapping Logic |
|---|---|---|---|
| **Student Name** | `std_students` | `first_name` & `last_name`| Concatenated full student name. |
| **Homework Title**| `lms_homework` | `title` | Parent homework title. |
| **Class / Section**| `sch_classes`/`sch_sections`| `class_name`/`section_name`| Student's class and section. |
| **Status** | `sys_dropdown_table`| `name` | Current state of assignment (`status_id`). |
| **Due Date** | `lms_homework_assignment`| `due_date` (or parent) | Effective due date. |
| **Submitted At** | `lms_homework_submissions`| `submitted_at` | Actual submission timestamp. |
| **Marks Obtained**| `lms_homework_submissions`| `marks_obtained` | Scored marks. |
| **Max Marks** | `lms_homework` | `max_marks` | Maximum possible score. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Class** | Dropdown | Yes | Select active class from `sch_classes`. | None |
| **Section** | Dropdown | No | Select section from `sch_sections`. | None |
| **Subject** | Dropdown | No | Filtered based on class. | None |
| **Syllabus Topic** | Dropdown | No | Filtered based on subject. | None |
| **Assignment Status** | Select Dropdown | No | Filter by `SUBMITTED`, `OVERDUE`, `GRADED`, `EXEMPTED`. | None |

---

## 5. Business Logic & Validation Policies

1. **Aggregation Formulas**:
   * **Submission Rate** ($\text{Rate}_{\text{sub}}$):
     $$\text{Rate}_{\text{sub}} = \left( \frac{\text{Total Submissions}}{\text{Total Assigned Students}} \right) \times 100\%$$
   * **Average Grade Ratio** ($\text{Ratio}_{\text{avg}}$):
     $$\text{Ratio}_{\text{avg}} = \frac{\sum \text{marks\_obtained}}{\sum \text{max\_marks}}$$
2. **Export Policies**:
   * Summaries are exportable to Excel or PDF format. The system filters data using the active screen query boundaries before generating the file.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher or Administrator.
* Navigate to the LmsHomework dashboard and click the **Summary** tab.

### Scenario A: Filtering Class Summary
1. Select Class: `Class 10`.
2. Select Section: `Section A`.
3. Select Subject: `Science`.
4. Click **"Filter"**.
5. **Expected Result**: The grid reloads to show students enrolled in Class 10-A, their Science homework, effective due dates, and statuses.

### Scenario B: Filtering by Overdue Status
1. Set the **Assignment Status** filter dropdown to `OVERDUE`.
2. Click **"Filter"**.
3. **Expected Result**: The table filters out all graded, submitted, and exempted assignments, displaying only students who have missed their submission deadlines.

### Scenario C: Verification of Summary Aggregations
1. Verify the summary counters at the top of the grid.
2. **Expected Result**: The counts for Total Assigned, Submitted, and Overdue match the sum of corresponding statuses in the filtered dataset.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/lms-home-work/home-works?tab=home_work_summary`

### 2. Summary Filters Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/lms-home-work/home-works?tab=home_work_summary')
            ->select('class_id', $this->classId)
            ->select('section_id', $this->sectionId)
            ->select('status_filter', 'OVERDUE')
            ->press('@filter-btn')
            ->assertSee('Overdue')
            ->assertDontSee('Graded');
});
```
