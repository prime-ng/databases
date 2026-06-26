# Template Types — Requirement Document

## 1. Screen Purpose & Overview

The **Template Types** tab is a configuration interface where administrators define and manage visual categories (types) of templates supported by the system. 

Common types (like Marksheet, Student ID Card, Fee Receipt) are seeded by default. Defining these categories scopes variable configurations and groups designs logically in templates listing pages.

---

## 2. Common Business Use Cases

1. **Adding Custom Category**: Setting up a new category `VISITOR_PASS` to design layout cards for visitor management.
2. **Deactivating Template Category**: Deactivating a type like `STAFF_ID_CARD` when staff details are managed by a third-party vendor, temporarily hiding related templates from active views.
3. **Updating Description**: Editing metadata description details to clarify when a layout category is used by academic staff.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `tmp_templates_type`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `name` | `varchar(30)` | No | N/A | Display name/code (e.g. `MARKSHEET`, `ADMIT_CARD`). UNIQUE index. |
| `description` | `varchar(255)`| Yes | `NULL` | Explanation of category layout target. |
| `is_active` | `tinyint(1)` | No | `0` | Status flag. Inactive types block associated designs. UNIQUE index. |
| Standard audit cols | | | | Includes `deleted_at`. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Type Name** | Text Input | Yes | String. Max: 30 characters. Unique in `tmp_templates_type`. | None |
| **Description** | Text Area | No | String. Max: 255 characters. | None |
| **Active Status** | Checkbox | No | Boolean. Checked = active (`1`), unchecked = inactive (`0`). | Unchecked (Inactive) |

---

## 5. Business Logic & Validation Policies

1. **Uniqueness Validation**:
   * Name checks must run case-insensitive comparison against existing rows. If a duplicate is submitted, returns: *"The template type name has already been taken."*
2. **Deletion Block (Soft & Permanent)**:
   * If a template type is associated with one or more templates (active or soft-deleted), deletion (both soft-delete and force-delete) is blocked. The application checks for existing relationships and returns an error: *"Cannot delete template type because it is being used by one or more templates."*
3. **Seeded System Lock**:
   * System-seeded types (e.g., `MARKSHEET`, `STUDENT_ID_CARD`, `TRANSFER_CERTIFICATE`) are flagged as protected. Delete operations against seeded records are blocked, returning: *"System protected template types cannot be deleted."*

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/template/templates-tabs` and select **Template Types** tab.

### Scenario A: Happy Path Create
1. Click **"New Template Type"**.
2. Enter Name: `ADMIT_CARD`.
3. Enter Description: `Exam admit card layout template categories`.
4. Check **"Active"**. Click Save.
5. **Expected Result**: 
   * Redirects to index grid, displays success alert: *"Template type saved successfully."*
   * Row `ADMIT_CARD` is active in the list.

### Scenario B: Deleting Seeded Type Block
1. Locate the default seeded row `MARKSHEET`.
2. Click **"Delete"**.
3. **Expected Result**: Confirmation dialog appears. Clicking confirm throws error: *"System protected template types cannot be deleted."*

### Scenario C: Deletion Block when Associated with Templates
1. Locate a template type (e.g., `MARKSHEET`) that is actively used in one or more templates.
2. Trigger the delete action.
3. **Expected Result**: 
   * The action is blocked, redirecting back to `/template/templates-tabs` with an error message: *"Cannot delete template type because it is being used by one or more templates."*
   * Database check: Verify the row remains in `tmp_templates_type` (not soft-deleted or force-deleted).

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/template/templates-tabs` (select `#types-pane`)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Template Types')
            ->press('New Template Type')
            ->type('name', 'VISITOR_PASS')
            ->type('description', 'Visitor badges layouts')
            ->check('is_active')
            ->press('Save Type')
            ->assertSee('Template type saved successfully');
});
```

### 3. Duplicate Validation Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Template Types')
            ->press('New Template Type')
            ->type('name', 'MARKSHEET') // Seeded type name
            ->press('Save Type')
            ->assertSee('already been taken');
});
```
