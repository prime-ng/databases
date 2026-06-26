# LMS Homework Assignments — Requirement Document

## 1. Screen Purpose & Overview

The **Assignment Tracking** screen provides teachers with a tool to monitor the delivery status of published homework for individual students. 

From this panel, teachers can track whether students have viewed the assignment, record views, check notification histories, and manage per-student overrides (such as emergency due-date extensions or custom late submission policies) to handle unique student circumstances without modifying the global homework template.

---

## 2. Common Business Use Cases

1. **Individual Due Date Extension:** Extending the due date for a student who was hospitalized, changing their `due_date` override to a future timestamp.
2. **Late Submission Exemption:** Allowing a student to submit late, overriding `allow_late_submission` to `1` with a logged reason.
3. **Manual Release Override:** Manually releasing a pending assignment (`is_released = 1`, `released_at = NOW()`) for a student who missed the topic completion trigger.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `lms_homework_assignment`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Unique Index**: `uq_hwa_homework_student` (`homework_id`, `student_id`)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `homework_id` | `int unsigned` | No | N/A | Foreign key to `lms_homework.id` (Cascade). |
| `student_id` | `int unsigned` | No | N/A | Foreign key to `std_students.id` (Cascade). |
| `academic_session_id` | `int unsigned` | No | N/A | Cached FK to current session from parent template. |
| `class_id` | `int unsigned` | No | N/A | Cached class ID. |
| `section_id` | `int unsigned` | Yes | `NULL` | Actual class section of the student at assignment time. |
| `subject_id` | `int unsigned` | No | N/A | Cached subject ID. |
| `release_condition` | `enum` | Yes | `ON_TOPIC_COMPLETE`| Mapped release condition (`IMMEDIATE`, `ON_TOPIC_COMPLETE`, `ON_SCHEDULED_DATE`). |
| `release_scheduled_date`| `datetime` | Yes | `NULL` | Student-specific scheduled release timestamp override. |
| `is_released` | `tinyint(1)` | No | `0` | Flag (0 = Hidden from student, 1 = Visible). |
| `released_at` | `datetime` | Yes | `NULL` | Actual timestamp when released. |
| `due_date` | `datetime` | Yes | `NULL` | Override due date (NULL = Inherit from `lms_homework.due_date`). |
| `allow_late_submission` | `tinyint(1)` | Yes | `NULL` | Late policy override (NULL = Inherit, 0 = Deny, 1 = Allow). |
| `late_submission_override_reason` | `varchar(500)`| Yes | `NULL` | Audited reason for the late submission policy override. |
| `late_submission_override_by` | `int unsigned` | Yes | `NULL` | FK referencing the teacher user who authorized the override. |
| `late_submission_override_at` | `datetime` | Yes | `NULL` | Override configuration timestamp. |
| `viewed_at` | `datetime` | Yes | `NULL` | First timestamp student viewed the assignment details. |
| `view_count` | `smallint unsigned`| No | `0` | Total hits / viewed count by student. |
| `student_notified_at` | `datetime` | Yes | `NULL` | Timestamp for student mobile/alert notification dispatch. |
| `parent_notified_at` | `datetime` | Yes | `NULL` | Timestamp for parent notification dispatch. |
| `reminder_sent_at` | `datetime` | Yes | `NULL` | Timestamp of last due-date reminder run. |
| `status_id` | `int unsigned` | No | N/A | FK to dropdowns (`PENDING_RELEASE`, `ASSIGNED`, `VIEWED`, `SUBMITTED`, `GRADED`, `OVERDUE`, `EXEMPTED`). |
| `assigned_by` | `int unsigned` | No | N/A | Foreign key to `sys_users.id` (Teacher ID). |
| `is_active` | `tinyint(1)` | No | `1` | Operational status indicator. |
| `created_by` | `int unsigned` | No | N/A | FK to `sys_users.id` (Audit). |
| `updated_by` | `int unsigned` | Yes | `NULL` | FK to `sys_users.id` (Audit). |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Modification timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Student** | Read-Only Text | N/A | Selected student name. | N/A |
| **Override Due Date** | Date/Time Picker | No | Optional. If set, must satisfy $\text{due\_date} \ge \text{lms\_homework.assign\_date}$. | None |
| **Late Submission override**| Select Dropdown | No | `Inherit Default` \| `Explicitly Allow` \| `Explicitly Deny`. | `Inherit Default` |
| **Override Reason** | Text Area | Yes (if overridden)| Mandatory if Due Date or Late Submission is modified. Max 500 chars. | None |
| **Status Override** | Select Dropdown | Yes | Choice of assignment statuses (e.g., `EXEMPTED`, `ASSIGNED`). | Current Status |

---

## 5. Business Logic & Validation Policies

1. **Override Priority Rules**:
   * The effective due date is calculated as:
     $$\text{Effective Due Date} = \text{COALESCE}(\text{assignment.due\_date}, \text{homework.due\_date})$$
   * The effective late submission policy is calculated as:
     $$\text{Effective Late Policy} = \text{COALESCE}(\text{assignment.allow\_late\_submission}, \text{homework.allow\_late\_submission})$$
2. **Auto-Overdue Scheduler**:
   * A nightly cron job queries all active, released assignments in non-finalized states (`ASSIGNED`, `VIEWED`) where $\text{Effective Due Date} < \text{NOW()}$.
   * These records are updated to `status_id` = `OVERDUE` and trigger notification logs.
3. **Audit Constraints**:
   * Changing any override field triggers the automatic capture of `late_submission_override_by` (authenticated teacher's user ID) and `late_submission_override_at` (current timestamp).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher.
* Locate a published homework template and open the **Assignment Tracking** grid.

### Scenario A: Extending Student Due Date
1. Locate student `Rahul Sharma` in the tracking list.
2. Click **"Override Settings"** for this student.
3. Set **Override Due Date** to a date 5 days past the template's due date.
4. Select Late Submission Override: `Explicitly Allow`.
5. Enter Reason: `Approved extension due to medical leave`.
6. Click **"Save Settings"**.
7. **Expected Result**: Settings update successfully. The tracking grid displays the new custom due date. The override reason is logged in `lms_homework_assignment`.

### Scenario B: Exemption Handling
1. Open settings for student `Aisha Patel`.
2. Change Status to `EXEMPTED`.
3. Enter Reason: `Exempted due to class transfer`.
4. Click **"Save Settings"**.
5. **Expected Result**: Aisha's status transitions to `EXEMPTED`. Aisha's student portal will no longer mark this assignment as outstanding or overdue.

### Scenario C: Scheduled Overdue Verification
1. Manually set a student's `due_date` override to a timestamp 1 hour in the past.
2. Run the console command: `php artisan homework:update-status`.
3. **Expected Result**: The scheduler processes the command. The student's status changes to `OVERDUE`.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/lms-home-work/assignments` (Assignment tracking list)

### 2. Override Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/lms-home-work/assignments')
            ->click('@override-settings-' . $this->assignmentId)
            ->type('due_date', '2026-06-01 12:00:00')
            ->select('allow_late_submission', '1') // Explicitly Allow
            ->type('late_submission_override_reason', 'Special extension')
            ->press('@save-override-btn')
            ->assertSee('override saved successfully');
});
```

### 3. Exemption Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/lms-home-work/assignments')
            ->click('@override-settings-' . $this->assignmentId)
            ->select('status_id', $this->exemptedStatusId)
            ->type('late_submission_override_reason', 'Transfer')
            ->press('@save-override-btn')
            ->assertSee('Exempted');
});
```
