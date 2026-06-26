# Assessment Types — Requirement Document

## 1. Screen Purpose & Overview

The **Assessment Types** screen manages the categories of tests or assessments that can act as recommendation sources (e.g., `QUIZ`, `QUEST`, `EXAM`, `ALL`). 

By classifying assessment types, the system allows recommendation rules to be filtered by evaluation format (e.g., triggering a rule only when a student fails a *Quiz*, but not when they fail a *Quest* or *Final Exam*).

---

## 2. Common Business Use Cases

1. **Quiz-Specific Remediation**: Restricting basic rules to weekly `QUIZ` events only so students don't get flooded with materials after formal exams.
2. **Comprehensive Exam Support**: Defining a rule targeting `EXAM` evaluations to assign deep-review packages.
3. **Deactivating Old Types**: Toggling active states of assessment types during syllabus transitions.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `rec_assessment_types`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `type_name` | `varchar(50)` | No | N/A | Code name representing the assessment format (e.g., `QUIZ`, `QUEST`). Has a unique DB index. |
| `description` | `text` | Yes | `NULL` | Explanation of the assessment type. |
| `is_active` | `boolean` | No | `1` (True) | Operational status. Inactive types ignore rule evaluations. |
| `created_by` | `bigint` | Yes | `NULL` | User ID of the creator (`sys_users.id`). |
| `updated_by` | `bigint` | Yes | `NULL` | User ID of the updater (`sys_users.id`). |
| `created_at` | `timestamp` | Yes | `NULL` | Timestamp of creation. |
| `updated_at` | `timestamp` | Yes | `NULL` | Timestamp of last modification. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Timestamp for soft-delete. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Assessment Type Name** | Text Input | Yes | Must be a string. Max length: 50 characters. Must be unique in the `rec_assessment_types` table. | None |
| **Description** | Text Area | No | Optional. Free text format. | None |
| **Active Status** | Checkbox | No | Boolean. Present in request body means true (`1`), absent means false (`0`). | Checked (True) |

---

## 5. Business Logic & Validation Policies

1. **Uniqueness Constraints**:
   * **On Create**: The `type_name` must be unique. Duplicate submissions fail with: *"The type name has already been taken."*
   * **On Update**: Bypassed if the name remains unchanged.
2. **Deactivation & Soft-Delete Cascade**:
   * Before a record is soft-deleted, the controller automatically sets `is_active = false` in the database.
   * Recommendation rules referencing a deleted/deactivated assessment type will fail to trigger.
3. **AJAX Status Toggling**:
   * Expects the target state to be passed in the request body as `is_active` (`0` or `1`).
   * The toggle gate is `recommendation.assessment_types.update`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Curriculum Manager.
* Navigate to `/recommendation/recommendation-mgt` and click the **Assessment Type** tab.

### Scenario A: Happy Path Create
1. Click the **"Add New Assessment Type"** button.
2. Enter Type Name: `CLASS_TEST`.
3. Enter Description: `Subject class tests conducted by teachers`.
4. Keep the **"Active"** checkbox checked.
5. Click **"Add Assessment Type"** (Submit button).
6. **Expected Result**: 
   * Page redirects back to `/recommendation/recommendation-mgt`.
   * A success flash message appears: *"Assessment Type saved successfully."*
   * The new type `CLASS_TEST` appears in the listing table under the Assessment Type tab.
   * Database check: Query `rec_assessment_types` and confirm the row is added with `is_active = 1`.

### Scenario B: Validation Failures
1. Click **"Add New Assessment Type"**.
2. Leave the **Assessment Type Name** field completely empty.
3. Click Submit.
4. **Expected Result**: The form fails to submit, highlighting the input with: *"The type name field is required."*
5. Now, type a name longer than 50 characters: `CLASS_EVALUATIONS_CONDUCTED_BY_EXTERNAL_TUTORS_ON_WEEKENDS`.
6. Click Submit.
7. **Expected Result**: Validation fails with: *"The type name must not be greater than 50 characters."*

### Scenario C: AJAX Status Toggling
1. In the Assessment Type listing table, locate `CLASS_TEST`.
2. Click the status switch in its row.
3. **Expected Result**:
   * The switch toggles visually.
   * An AJAX `POST` request is sent to `/recommendation/assessment-types/{id}/toggle-status` sending `is_active = 0` in the request body.
   * A toast notification pops up indicating success: *"Status updated successfully."*
   * Database check: Query the row and confirm `is_active` has flipped to `0`.

### Scenario D: Soft Delete & Recovery
1. Locate `CLASS_TEST` in the listing table.
2. Click the **"Delete"** icon.
3. Confirm the SweetAlert2 dialog.
4. **Expected Result**:
   * Page redirects back to `/recommendation/recommendation-mgt` with a success message.
   * The record is removed from the active listing table.
   * Database check: Confirm `deleted_at` timestamp is set, and `is_active` is automatically set to `0`.
5. Navigate to the Trash View at `/recommendation/assessment-types/trash/view`.
6. Click **"Restore"** on the deleted record, and confirm the SweetAlert dialog.
7. **Expected Result**: The record is restored, `deleted_at` becomes null, and it reappears in the main listing.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/recommendation-mgt`
* **Target Tab ID**: `#assesment-type-pane` (Assessment Type Tab — note: typo in code has one 's' in `assesment`)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/assessment-types/create')
            ->type('type_name', 'CLASS_EVAL')
            ->type('description', 'Remedial assessment format')
            ->check('is_active')
            ->press('Add Assessment Type')
            ->assertPathIs('/recommendation/recommendation-mgt')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/assessment-types/create')
            ->type('type_name', '') // Leave empty
            ->press('Add Assessment Type')
            ->assertSee('required')
            ->assertPathIsNot('/recommendation/recommendation-mgt');
});
```
