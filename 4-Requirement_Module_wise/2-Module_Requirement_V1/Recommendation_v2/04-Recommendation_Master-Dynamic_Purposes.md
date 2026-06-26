# Dynamic Purposes — Requirement Document

## 1. Screen Purpose & Overview

The **Dynamic Purposes** screen manages the targeted objective categories of recommendations (e.g., `Remedial`, `Enrichment`, `Revision`, `Homework Help`). 

By categorizing objectives, teachers can specify the purpose of remedial materials, and the recommendation engine can intelligently match rules (e.g., triggering a `Remedial` purpose material when a student scores below 40%, or an `Enrichment` purpose material when a student scores above 85%).

---

## 2. Common Business Use Cases

1. **Supporting Weak Students**: Registering a `Remedial` purpose to serve basic review packages to struggling students.
2. **Encouraging High Performers**: Registering an `Enrichment` purpose to assign advanced research papers or optional tasks to top-performing students.
3. **Weekly Practice**: Registering a `Homework Help` purpose to link textbook hints for weekly homework review.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `rec_dynamic_purposes`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `purpose_name` | `varchar(50)` | No | N/A | Code name representing the educational purpose (e.g., `Remedial`). Has a unique DB index. |
| `description` | `text` | Yes | `NULL` | Explanation of the educational purpose. |
| `is_active` | `boolean` | No | `1` (True) | Operational availability toggle. |
| `created_by` | `bigint` | Yes | `NULL` | User ID of the creator (`sys_users.id`). |
| `updated_by` | `bigint` | Yes | `NULL` | User ID of the updater (`sys_users.id`). |
| `created_at` | `timestamp` | Yes | `NULL` | Timestamp of creation. |
| `updated_at` | `timestamp` | Yes | `NULL` | Timestamp of last modification. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Timestamp for soft-delete. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Purpose Name** | Text Input | Yes | Must be a string. Max length: 50 characters. Must be unique in the `rec_dynamic_purposes` table. | None |
| **Description** | Text Area | No | Optional. Free text format. | None |
| **Active Status** | Checkbox | No | Boolean. Present in request body means true (`1`), absent means false (`0`). | Checked (True) |

---

## 5. Business Logic & Validation Policies

1. **Uniqueness Constraints**:
   * **On Create**: The `purpose_name` must be unique. Duplicate submissions fail with: *"The purpose name has already been taken."*
   * **On Update**: Bypassed if the name remains unchanged.
2. **Deactivation & Soft-Delete Cascade**:
   * Before a record is soft-deleted, the controller automatically sets `is_active = false` in the database.
   * Recommendation rules or materials referencing a deleted/deactivated purpose will ignore active evaluations.
3. **AJAX Status Toggling**:
   * Unlike material types, toggling status for dynamic purposes expects the target state to be passed in the request body as `is_active` (`0` or `1`).
   * The toggle gate is `recommendation.dynamic_purposes.update` (not `tenant.`).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Curriculum Manager.
* Navigate to `/recommendation/recommendation-mgt` and click the **Dynamic Purposes** tab.

### Scenario A: Happy Path Create
1. Click the **"Add New Dynamic Purpose"** button.
2. Enter Purpose Name: `Exam Prep`.
3. Enter Description: `Mock papers and review sheets before term exams`.
4. Keep the **"Active"** checkbox checked.
5. Click **"Add Dynamic Purpose"** (Submit button).
6. **Expected Result**: 
   * Page redirects back to `/recommendation/recommendation-mgt`.
   * A success flash message appears: *"Dynamic Purpose saved successfully."*
   * The new purpose `Exam Prep` appears in the listing table under the Dynamic Purposes tab.
   * Database check: Query `rec_dynamic_purposes` and confirm the row is added with `is_active = 1`.

### Scenario B: Validation Failures
1. Click **"Add New Dynamic Purpose"**.
2. Leave the **Purpose Name** field completely empty.
3. Click Submit.
4. **Expected Result**: The form fails to submit, highlighting the input with: *"The purpose name field is required."*
5. Now, type a name longer than 50 characters: `REMEDIAL_PRACTICE_FOR_STUDENTS_WHO_FAILED_WEEKLY_TESTS_MULTIPLE_TIMES`.
6. Click Submit.
7. **Expected Result**: Validation fails with: *"The purpose name must not be greater than 50 characters."*

### Scenario C: AJAX Status Toggling
1. In the Dynamic Purposes listing table, locate `Exam Prep`.
2. Click the status switch in its row.
3. **Expected Result**:
   * The switch toggles visually.
   * An AJAX `POST` request is sent to `/recommendation/dynamic-purposes/{id}/toggle-status` sending `is_active = 0` in the request body.
   * A toast notification pops up indicating success: *"Status updated successfully."*
   * Database check: Query the row and confirm `is_active` has flipped to `0`.

### Scenario D: Soft Delete & Recovery
1. Locate `Exam Prep` in the listing table.
2. Click the **"Delete"** icon.
3. Confirm the SweetAlert2 dialog.
4. **Expected Result**:
   * Page redirects back to `/recommendation/recommendation-mgt` with a success message.
   * The record is removed from the active listing table.
   * Database check: Confirm `deleted_at` timestamp is set, and `is_active` is automatically set to `0`.
5. Navigate to the Trash View at `/recommendation/dynamic-purposes/trash/view`.
6. Click **"Restore"** on the deleted record, and confirm the SweetAlert dialog.
7. **Expected Result**: The record is restored, `deleted_at` becomes null, and it reappears in the main listing.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/recommendation-mgt`
* **Target Tab ID**: `#dynamic-purposes-pane` (Dynamic Purposes Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/dynamic-purposes/create')
            ->type('purpose_name', 'EXAM_PREP')
            ->type('description', 'Remedial review format')
            ->check('is_active')
            ->press('Add Dynamic Purpose')
            ->assertPathIs('/recommendation/recommendation-mgt')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/dynamic-purposes/create')
            ->type('purpose_name', '') // Leave empty
            ->press('Add Dynamic Purpose')
            ->assertSee('required')
            ->assertPathIsNot('/recommendation/recommendation-mgt');
});
```
