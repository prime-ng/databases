# Trigger Events — Requirement Document

## 1. Screen Purpose & Overview

The **Trigger Events** screen is a configuration interface where administrators define the system events that can hook into the recommendation engine. 

When a student completes an assessment (e.g., a quiz or a quest), the system fires a corresponding event hook (such as `ON_ASSESSMENT_RESULT`). By defining these trigger nodes, the application knows when to evaluate the recommendation rules.

---

## 2. Common Business Use Cases

1. **Standardizing Automated Workflows**: Registering the default `ON_ASSESSMENT_RESULT` trigger event so that the background recommendation engine evaluates rules whenever a quiz score is posted.
2. **Custom Milestone Recommendations**: Registering an `ON_ACADEMIC_PROMOTION` event to recommend bridge courses for students moving to the next class grade.
3. **Deactivating Old Triggers**: Temporarily disabling a trigger (like `ON_HOMEWORK_SUBMISSION`) when revision rules are being updated by the academic head.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `rec_trigger_events`
*   **Primary Key**: `id` (bigint, auto-increment)
*   **Tenant Scope**: Scoped implicitly by Laravel Tenancy at the database level.

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `event_name` | `varchar(50)` | No | N/A | Unique, short identifier of the event. Has a unique DB index. |
| `description` | `text` | Yes | `NULL` | Background details on what conditions trigger this event. |
| `is_active` | `boolean` | No | `1` (True) | Operational status. Inactive triggers do not evaluate rules. |
| `created_by` | `bigint` | Yes | `NULL` | Foreign key referencing the creator (`sys_users.id`). |
| `updated_by` | `bigint` | Yes | `NULL` | Foreign key referencing the updater (`sys_users.id`). |
| `created_at` | `timestamp` | Yes | `NULL` | Timestamp of creation. |
| `updated_at` | `timestamp` | Yes | `NULL` | Timestamp of last modification. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Timestamp for soft-delete operations. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Event Name** | Text Input | Yes | Must be a string. Max length: 50 characters. Must be unique in the `rec_trigger_events` table (checked on create). | None |
| **Description** | Text Area | No | Optional. Free text format. | None |
| **Active Status** | Checkbox | No | Boolean. Present in request body means true (`1`), absent means false (`0`). | Checked (True) |

---

## 5. Business Logic & Validation Policies

1. **Uniqueness Constraints**:
   * **On Create**: The `event_name` must not exist in `rec_trigger_events` (including soft-deleted records if using unique database constraints, though standard validator checks active tenant scope). If a duplicate is submitted, it fails validation with: *"The event name has already been taken."*
   * **On Update**: The uniqueness check is bypassed if the name remains unchanged for that record.
2. **Deactivation & Soft-Delete Cascade**:
   * Before a record is soft-deleted, the controller automatically sets `is_active = false` in the database.
   * Recommendation rules that reference a deleted or deactivated trigger event will ignore rule evaluation checks.
3. **Audit Trails**:
   * Every write action (Create, Update, Delete, Restore, Force Delete, Toggle Status) must log an audit entry in the activity log.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Curriculum Manager.
* Navigate to `/recommendation/recommendation-mgt` and click the **Trigger Events** tab.

### Scenario A: Happy Path Create
1. Click the **"Add New Trigger Event"** button.
2. Enter Event Name: `ON_TEST_COMPLETION`.
3. Enter Description: `Triggered when a class test score is posted`.
4. Keep the **"Active"** checkbox checked.
5. Click **"Add Assessment Type"** (Submit button).
6. **Expected Result**: 
   * Page redirects back to `/recommendation/recommendation-mgt`.
   * A success flash message appears: *"Trigger Event saved successfully."*
   * The new event `ON_TEST_COMPLETION` appears in the listing table.
   * Database check: Query the `rec_trigger_events` table and confirm the row is added with `is_active = 1`.

### Scenario B: Validation Failures
1. Click **"Add New Trigger Event"**.
2. Leave the **Event Name** field completely empty.
3. Click Submit.
4. **Expected Result**: The form fails to submit, highlighting the Event Name input with an error: *"The event name field is required."*
5. Now, type a name longer than 50 characters: `ON_STUDENT_COMPLETES_WEEKLY_MATH_ASSESSMENT_WITH_CRITICAL_LOW_SCORE`.
6. Click Submit.
7. **Expected Result**: Validation fails with: *"The event name must not be greater than 50 characters."*

### Scenario C: AJAX Status Toggling
1. In the Trigger Events listing table, locate `ON_TEST_COMPLETION`.
2. Click the status switch in its row.
3. **Expected Result**:
   * The switch toggles visually.
   * An AJAX `POST` request is sent to `/recommendation/trigger-events/{id}/toggle-status`.
   * A toast notification pops up indicating success: *"Status updated successfully."*
   * Database check: Query the row in `rec_trigger_events` and confirm `is_active` has flipped to `0`.

### Scenario D: Soft Delete & Recovery
1. Locate `ON_TEST_COMPLETION` in the listing table.
2. Click the **"Delete"** icon.
3. A SweetAlert2 confirmation dialog appears. Click **"Yes, delete it!"**.
4. **Expected Result**:
   * Page redirects back to `/recommendation/recommendation-mgt` with a success message.
   * The record is removed from the active listing table.
   * Database check: Confirm `deleted_at` timestamp is set, and `is_active` is automatically set to `0`.
5. Navigate to the Trash View at `/recommendation/trigger-events/trash/view`.
6. Click **"Restore"** on the deleted record, and confirm the SweetAlert dialog.
7. **Expected Result**: The record is restored, `deleted_at` becomes null, and it reappears in the main listing.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/recommendation-mgt`
* **Target Tab ID**: `#events-pane` (Trigger Events Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/trigger-events/create')
            ->type('event_name', 'TEST_EVENT_HOOK')
            ->type('description', 'Remedial evaluation hook')
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
            ->visit('/recommendation/trigger-events/create')
            ->type('event_name', '') // Leave empty
            ->press('Add Assessment Type')
            ->assertSee('required')
            ->assertPathIsNot('/recommendation/recommendation-mgt');
});
```
