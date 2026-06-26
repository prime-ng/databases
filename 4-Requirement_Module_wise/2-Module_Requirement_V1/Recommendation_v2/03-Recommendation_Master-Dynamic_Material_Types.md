# Dynamic Material Types — Requirement Document

## 1. Screen Purpose & Overview

The **Dynamic Material Types** screen manages the content format options available in the Recommendation module (e.g., `Video`, `PDF`, `Audio`, `Document`). 

By categorizing content formats, the system helps teachers specify the media type of uploaded remedial materials and allows the recommendation engine to dynamically resolve material matching a requested format (e.g., recommending a *Video* instead of a *PDF* text sheet when a student struggles with visual topics).

---

## 2. Common Business Use Cases

1. **Adding New Learning Formats**: Registering a new format option like `Interactive Simulation` so teachers can tag simulation links for remedial work.
2. **Filtering Material Content**: Allowing teachers to view and filter uploaded materials by their format.
3. **Deactivating Old Formats**: Deactivating legacy formats like `Physical Book Copy` when the school shifts fully to digital materials.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `rec_dynamic_material_types`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `type_name` | `varchar(50)` | No | N/A | Code name representing the material type (e.g., `Video`, `PDF`). Has a unique DB index. |
| `description` | `text` | Yes | `NULL` | Explanation of the content format. |
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
| **Material Type Name** | Text Input | Yes | Must be a string. Max length: 50 characters. Must be unique in the `rec_dynamic_material_types` table. | None |
| **Description** | Text Area | No | Optional. Free text format. | None |
| **Active Status** | Checkbox | No | Boolean. Present in request body means true (`1`), absent means false (`0`). | Checked (True) |

---

## 5. Business Logic & Validation Policies

1. **Uniqueness Constraints**:
   * **On Create**: The `type_name` must be unique in `rec_dynamic_material_types`. Duplicate submissions fail with: *"The type name has already been taken."*
   * **On Update**: Bypassed if the name remains unchanged.
2. **Deactivation & Soft-Delete Cascade**:
   * Before a record is soft-deleted, the controller automatically sets `is_active = false` in the database.
   * Recommendation rules or materials referencing a deleted/deactivated material type will fail schema validation checks.
3. **AJAX Status Flipping**:
   * Unlike trigger events, toggling status for dynamic material types does not send `is_active` in the request body. The controller toggles the value dynamically via `!$model->is_active`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Curriculum Manager.
* Navigate to `/recommendation/recommendation-mgt` and click the **Dynamic Material** tab.

### Scenario A: Happy Path Create
1. Click the **"Add New Dynamic Material Type"** button.
2. Enter Type Name: `Interactive Simulation`.
3. Enter Description: `Web-based laboratory simulation link`.
4. Keep the **"Active"** checkbox checked.
5. Click **"Add Dynamic Material Type"** (Submit button).
6. **Expected Result**: 
   * Page redirects back to `/recommendation/recommendation-mgt`.
   * A success flash message appears: *"Dynamic Material Type saved successfully."*
   * The new type `Interactive Simulation` appears in the listing table under the Dynamic Material tab.
   * Database check: Query `rec_dynamic_material_types` and confirm the row is added with `is_active = 1`.

### Scenario B: Validation Failures
1. Click **"Add New Dynamic Material Type"**.
2. Leave the **Material Type Name** field completely empty.
3. Click Submit.
4. **Expected Result**: The form fails to submit, highlighting the input with: *"The type name field is required."*
5. Now, type a name longer than 50 characters: `INTERACTIVE_LABORATORY_SIMULATIONS_AND_CHEMISTRY_PRACTICALS`.
6. Click Submit.
7. **Expected Result**: Validation fails with: *"The type name must not be greater than 50 characters."*

### Scenario C: AJAX Status Toggling
1. In the Dynamic Material listing table, locate `Interactive Simulation`.
2. Click the status switch in its row.
3. **Expected Result**:
   * The switch toggles visually.
   * An AJAX `POST` request is sent to `/recommendation/dynamic-material-types/{id}/toggle-status`.
   * A toast notification pops up indicating success: *"Status updated successfully."*
   * Database check: Query the row and confirm `is_active` has flipped to `0`.

### Scenario D: Soft Delete & Recovery
1. Locate `Interactive Simulation` in the listing table.
2. Click the **"Delete"** icon.
3. Confirm the SweetAlert2 dialog.
4. **Expected Result**:
   * Page redirects back to `/recommendation/recommendation-mgt` with a success message.
   * The record is removed from the active listing table.
   * Database check: Confirm `deleted_at` timestamp is set, and `is_active` is automatically set to `0`.
5. Navigate to the Trash View at `/recommendation/dynamic-material-types/trash/view`.
6. Click **"Restore"** on the deleted record, and confirm the SweetAlert dialog.
7. **Expected Result**: The record is restored, `deleted_at` becomes null, and it reappears in the main listing.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/recommendation-mgt`
* **Target Tab ID**: `#dynamic-materials-pane` (Dynamic Material Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/dynamic-material-types/create')
            ->type('type_name', 'SIMULATION')
            ->type('description', 'Remedial simulation format')
            ->check('is_active')
            ->press('Add Dynamic Material Type')
            ->assertPathIs('/recommendation/recommendation-mgt')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/recommendation/dynamic-material-types/create')
            ->type('type_name', '') // Leave empty
            ->press('Add Dynamic Material Type')
            ->assertSee('required')
            ->assertPathIsNot('/recommendation/recommendation-mgt');
});
```
