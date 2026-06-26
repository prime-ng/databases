# Recommendation Modes — Requirement Document

## 1. Screen Purpose & Overview

The **Recommendation Modes** screen manages the execution formats of recommendations (e.g., `SPECIFIC_MATERIAL`, `SPECIFIC_BUNDLE`, `DYNAMIC_BY_TOPIC`, `DYNAMIC_BY_COMPETENCY`). 

These modes define how remedial content is resolved and dispatched to the student's portal once a recommendation rule fires. By categorizing modes, the system knows whether to push a hardcoded PDF worksheet, an entire learning bundle, or dynamically query the database for materials matching the failed topic.

---

## 2. Common Business Use Cases

1. **Static Content Assignments**: Configuring the `SPECIFIC_MATERIAL` mode to push a specific video link or worksheet directly.
2. **Sequential remedial pathways**: Configuring the `SPECIFIC_BUNDLE` mode to assign a sequential packet of materials (e.g., textbook reading followed by exercises).
3. **Automated Topic Matching**: Utilizing the `DYNAMIC_BY_TOPIC` mode so that the system automatically locates and assigns any active material matching the class, subject, and topic of the failed quiz question.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `rec_recommendation_modes`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `mode_name` | `varchar(50)` | No | N/A | Code name representing the execution mode (e.g., `DYNAMIC_BY_TOPIC`). Has a unique DB index. |
| `description` | `text` | Yes | `NULL` | Explanation of how content is resolved under this mode. |
| `is_active` | `boolean` | No | `1` (True) | Operational availability toggle. |
| `created_by` | `bigint` | Yes | `NULL` | ID of the user who registered the mode (`sys_users.id`). |
| `updated_by` | `bigint` | Yes | `NULL` | ID of the user who updated the mode (`sys_users.id`). |
| `created_at` | `timestamp` | Yes | `NULL` | Timestamp of creation. |
| `updated_at` | `timestamp` | Yes | `NULL` | Timestamp of last modification. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Timestamp for soft-delete. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Mode Name** | Text Input | Yes | Must be a string. Max length: 50 characters. Must be unique in the `rec_recommendation_modes` table. | None |
| **Description** | Text Area | No | Optional. Free text format. | None |
| **Active Status** | Checkbox | No | Boolean. Present in request body means true (`1`), absent means false (`0`). | Checked (True) |

---

## 5. Business Logic & Validation Policies

1. **Uniqueness Constraints**:
   * **On Create**: The `mode_name` must be unique in `rec_recommendation_modes`. If a duplicate is submitted, it fails validation with: *"The mode name has already been taken."*
   * **On Update**: Uniqueness checks are bypassed if the mode name remains unchanged for that record.
2. **Deactivation & Soft-Delete Cascade**:
   * Before a record is soft-deleted, the controller automatically sets `is_active = false` in the database.
   * Recommendation rules that reference a deleted or deactivated recommendation mode will fail rule evaluation because no target content can be resolved.
3. **Audit Trails**:
   * Every write action (Create, Update, Delete, Restore, Force Delete, Toggle Status) must log an audit entry in the activity log.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Curriculum Manager.
* Navigate to `/recommendation/recommendation-mgt` and click the **Recommendation Modes** tab.

### Scenario A: Happy Path Create
1. Click the **"Add New Recommendation Mode"** button.
2. Enter Mode Name: `SPECIFIC_WEBSITE_LINK`.
3. Enter Description: `Recommends an external portal link`.
4. Keep the **"Active"** checkbox checked.
5. Click **"Add Recommendation Mode"** (Submit button).
6. **Expected Result**: 
   * Page redirects back to `/recommendation/recommendation-mgt`.
   * A success flash message appears: *"Recommendation Mode saved successfully."*
   * The new mode `SPECIFIC_WEBSITE_LINK` appears in the listing table.
   * Database check: Query the `rec_recommendation_modes` table and confirm the row is added with `is_active = 1`.

### Scenario B: Validation Failures
1. Click **"Add New Recommendation Mode"**.
2. Leave the **Mode Name** field completely empty.
3. Click Submit.
4. **Expected Result**: The form fails to submit, highlighting the Mode Name input with an error: *"The mode name field is required."*
5. Now, type a name longer than 50 characters: `DYNAMIC_CONTENT_RESOLVER_THAT_SEARCHES_FOR_TOPICS_AND_COMPETENCY_CODES`.
6. Click Submit.
7. **Expected Result**: Validation fails with: *"The mode name must not be greater than 50 characters."*

### Scenario C: AJAX Status Toggling
1. In the Recommendation Modes listing table, locate `SPECIFIC_WEBSITE_LINK`.
2. Click the status switch in its row.
3. **Expected Result**:
   * The switch toggles visually.
   * An AJAX `POST` request is sent to `/recommendation/recommendation-modes/{id}/toggle-status`.
   * A toast notification pops up indicating success: *"Status updated successfully."*
   * Database check: Query the row in `rec_recommendation_modes` and confirm `is_active` has flipped to `0`.

### Scenario D: Soft Delete & Recovery
1. Locate `SPECIFIC_WEBSITE_LINK` in the listing table.
2. Click the **"Delete"** icon.
3. A SweetAlert2 confirmation dialog appears. Click **"Yes, delete it!"**.
4. **Expected Result**:
   * Page redirects back to `/recommendation/recommendation-mgt` with a success message.
   * The record is removed from the active listing table.
   * Database check: Confirm `deleted_at` timestamp is set, and `is_active` is automatically set to `0`.
5. Navigate to the Trash View at `/recommendation/recommendation-modes/trash/view`.
6. Click **"Restore"** on the deleted record, and confirm the SweetAlert dialog.
7. **Expected Result**: The record is restored, `deleted_at` becomes null, and it reappears in the main listing.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/recommendation-mgt`
* **Target Tab ID**: `#modes-pane` (Recommendation Modes Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/recommendation-modes/create')
            ->type('mode_name', 'TEST_MODE')
            ->type('description', 'Remedial delivery mode')
            ->check('is_active')
            ->press('Add Recommendation Mode')
            ->assertPathIs('/recommendation/recommendation-mgt')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/recommendation-modes/create')
            ->type('mode_name', '') // Leave empty
            ->press('Add Recommendation Mode')
            ->assertSee('required')
            ->assertPathIsNot('/recommendation/recommendation-mgt');
});
```
