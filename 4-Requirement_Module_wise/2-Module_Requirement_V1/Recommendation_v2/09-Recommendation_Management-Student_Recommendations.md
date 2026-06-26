# Student Recommendations — Requirement Document

## 1. Screen Purpose & Overview

The **Student Recommendations** screen manages personalized learning assignments generated for individual students. 

Teachers use this screen to manually allocate remedial learning tracks (materials or bundles), review recommendations triggered automatically by rules, track student progress statuses, and analyze completion rates and student-submitted feedback.

---

## 2. Common Business Use Cases

1. **Manual Remedial Assignment**: A teacher assigns a geometry revision worksheet to a student who scored poorly on a class assignment.
2. **Monitoring Student Progress**: Reviewing active recommendation statuses (`PENDING`, `VIEWED`, `IN_PROGRESS`, `COMPLETED`, `EXPIRED`, `SKIPPED`).
3. **Evaluating Student Feedback**: Reviewing the 5-star rating and written comments submitted by a student upon completing an assigned packet.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `rec_student_recommendations`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `uuid` | `char(36)` | No | Auto-generated | Unique transaction code (UUID v4) generated via model boot methods. |
| `student_id` | `bigint` | No | N/A | Target student recipient (`std_students.id` or `sys_users.id` depending on schema). |
| `assigned_date` | `date` | Yes | Today's Date | Date when the recommendation was created. |
| `rule_id` | `bigint` | Yes | `NULL` | Mapped automated rule ID (`rec_recommendation_rules.id`). SET NULL on delete. |
| `triggered_by_quiz_id` | `bigint` | Yes | `NULL` | Quiz ID that triggered this recommendation (`lms_quizzes.id`). |
| `triggered_by_quest_id` | `bigint` | Yes | `NULL` | Quest ID that triggered this recommendation (`lms_quests.id`). |
| `manual_assigned_by` | `bigint` | Yes | `NULL` | ID of the teacher who manually assigned it (`sys_users.id` or `sch_teachers.id`). |
| `material_id` | `bigint` | Yes | `NULL` | Target material recommended (`rec_recommendation_materials.id`). CASCADE on delete. |
| `bundle_id` | `bigint` | Yes | `NULL` | Target bundle recommended (`rec_material_bundles.id`). CASCADE on delete. |
| `recommendation_reason`| `varchar(255)`| Yes | `NULL` | Explanation of why this content was recommended. |
| `priority` | `varchar(20)` | No | `'MEDIUM'` | Urgency classification. Enum: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`. |
| `due_date` | `date` | Yes | `NULL` | Completion deadline. Must be $\ge \text{today}$. |
| `status` | `varchar(20)` | No | `'PENDING'` | Progress status. Enum: `PENDING`, `VIEWED`, `IN_PROGRESS`, `COMPLETED`, `SKIPPED`, `EXPIRED`. |
| `assigned_at` | `datetime` | Yes | `now()` | Date and time when the recommendation was issued. |
| `first_viewed_at` | `datetime` | Yes | `NULL` | Recorded timestamp when student first opens the recommendation. |
| `completed_at` | `datetime` | Yes | `NULL` | Recorded timestamp when student completes the recommendation tasks. |
| `score_achieved` | `decimal(5,2)`| Yes | `NULL` | Assessment score achieved upon retaking/completing tasks (0 to 100). |
| `student_rating` | `integer` | Yes | `NULL` | Quality rating submitted by student (1 to 5 stars). |
| `student_feedback` | `text` | Yes | `NULL` | Review comments submitted by the student. |
| `is_published` | `boolean` | No | `1` (True) | Visibility switch for the student portal. |
| `is_active` | `boolean` | No | `1` (True) | Operational status toggle. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Last updated timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Student** | Dropdown | Yes | Must exist in `std_students.id` (or equivalent). | None |
| **Material** | Dropdown | No | Must exist in `rec_recommendation_materials.id`. | None |
| **Bundle** | Dropdown | No | Must exist in `rec_material_bundles.id`. | None |
| **Priority** | Dropdown | Yes | Must be one of: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`. | `'MEDIUM'` |
| **Status** | Dropdown | Yes | Must be one of: `PENDING`, `VIEWED`, `IN_PROGRESS`, `COMPLETED`, `SKIPPED`, `EXPIRED`. | `'PENDING'` |
| **Due Date** | Date Input | No | Must be a date after or equal to today's date (`after_or_equal:today`). | None |
| **Recommendation Reason**| Text Input | No | Optional. Max length: 255 characters. | None |
| **Score Achieved** | Number Input | No | Numeric decimal between 0 and 100. | None |
| **Student Rating** | Dropdown | No | Integer between 1 and 5. | None |
| **Active Status** | Checkbox | No | Boolean. Present in request means true, absent means false. | Checked (True) |

*   **Enforcement Rule (Controller-Level)**: Either `material_id` or `bundle_id` must be selected. Submitting with both fields empty fails with: *"Either Material or Bundle must be selected."* (This check is processed in the controller, not the request form).

---

## 5. Business Logic & Validation Policies

1. **Model Accessors & Badges**:
   * **`is_overdue`**: Returns true if `due_date` is in the past and status is `PENDING` or `IN_PROGRESS`. Renders as an "Overdue" warning badge in the list.
   * **`status_badge_class`**: Mapped CSS badge styling per status (e.g., PENDING $\rightarrow$ `badge bg-warning`, COMPLETED $\rightarrow$ `badge bg-success`).
   * **`star_rating`**: Formats the integer rating as stars (e.g., `3` $\rightarrow$ `★★★☆☆`, `null` $\rightarrow$ `"Not rated"`).
2. **Model Methods & AJAX hooks**:
   * **`markAsViewed()`**: Executed via AJAX when the student first opens the material. Sets `first_viewed_at = now()` and status from PENDING to VIEWED. (Subsequent opens do not overwrite `first_viewed_at`).
   * **`markAsCompleted($score)`**: Sets status to `COMPLETED`, saves `score_achieved`, and records `completed_at = now()`.
   * **`addRating($rating, $feedback)`**: Saves star rating (1–5) and feedback comments, then redirects to the dashboard with a success message.
3. **Database Cascades**:
   * Removing a student, material, or bundle will trigger database foreign key cascades and delete associated recommendations.
   * Deleting a rule sets `rule_id` to null.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher.
* Navigate to `/recommendation/rec-material` and click the **Student Recommendations** tab.

### Scenario A: Happy Path Create
1. Click the **"Add Recommendation"** button.
2. Select Student: `Aarav Patel`.
3. Select Priority: `HIGH`. Select Status: `PENDING`.
4. Select Material: `Calculus Worksheet`.
5. Enter Due Date: `Next Friday` (a future date).
6. Enter Reason: `Concept check for weekly worksheet`.
7. Click **"Create"** (Submit button).
8. **Expected Result**:
   * Page redirects back to `/recommendation/rec-material`.
   * Success flash message appears.
   * New recommendation appears in the listing showing the student's name, material title badge, and reason.
   * Database check: Query `rec_student_recommendations`. Verify `uuid` contains a valid auto-generated UUID v4, and `assigned_at` is populated.

### Scenario B: Validation Failures
1. Click **"Add Recommendation"**.
2. Select Student: `Aarav Patel`.
3. Leave both **Material** and **Bundle** fields empty.
4. Click **"Create"**.
5. **Expected Result**: Validation fails. Error message is displayed: *"Either Material or Bundle must be selected."*
6. Enter a past due date: `2020-01-01` and submit.
7. **Expected Result**: Validation fails: *"The due date must be a date after or equal to today."*

### Scenario C: AJAX Status Updates
1. Navigate to a student portal simulation. Open the assigned recommendation.
2. **Expected Result**:
   * System triggers AJAX request to `POST /recommendation/student-recommendations/{id}/update-status` sending `status = VIEWED`.
   * Database check: Verify `first_viewed_at` timestamp is written.
3. Mark the recommendation completed from the portal.
4. **Expected Result**:
   * AJAX request updates status to `COMPLETED` and sets `completed_at`.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/rec-material`
* **Target Tab ID**: `#student-recommendations-pane` (Student Recommendations Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/recommendation/student-recommendations/create')
            ->select('student_id', '1') // Target Student ID
            ->select('priority', 'MEDIUM')
            ->select('status', 'PENDING')
            ->select('material_id', '1') // Target Material ID
            ->type('due_date', '2026-12-31') // Future date
            ->press('Create')
            ->assertPathIs('/recommendation/rec-material')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/recommendation/student-recommendations/create')
            ->select('student_id', '') // Clear student
            ->press('Create')
            ->assertSee('required')
            ->assertPathIsNot('/recommendation/rec-material');
});
```
