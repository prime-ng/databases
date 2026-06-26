# Template Variables — Requirement Document

## 1. Screen Purpose & Overview

The **Template Variables** tab manages the master register of placeholders (variables) available for specific template categories (types). 

Variables represent merge fields in output documents. From this screen, admins define whether variables resolve automatically from specific database tables (Automated Mode) or must be supplied by the calling system code (Manual Mode).

---

## 2. Common Business Use Cases

1. **Mapping Student Photo Placeholder**: Registering variable `student_photo` scoped to category `STUDENT_ID_CARD`. Setting database mappings to `tenant_db`, `sys_media`, and `file_path`.
2. **Setting Manual Marksheet Columns**: Registering variable `result_status` scoped to `MARKSHEET` without database mappings, because the grading engine calculates results at runtime.
3. **Reusing Variables**: Creating general variables like `school_name` and mapping it to type `MARKSHEET` and `FEE_RECEIPT`.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `tmp_template_variables`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `template_type_id` | `int unsigned` | No | N/A | FK referencing `tmp_templates_type.id` (RESTRICT). |
| `name` | `varchar(50)` | No | N/A | Variable placeholder name (e.g. `father_name`). UNIQUE index. |
| `description` | `varchar(255)`| Yes | `NULL` | Tooltip details for the visual editor canvas. |
| `db_name` | `varchar(60)` | Yes | `NULL` | Database name if auto-resolved (e.g. `tenant_db`). |
| `table_name` | `varchar(60)` | Yes | `NULL` | Table name containing source field (e.g. `std_students`). |
| `field_name` | `varchar(60)` | Yes | `NULL` | Source column name (e.g. `father_name`). |
| `is_active` | `tinyint(1)` | No | `1` | Operational status of lookup. |
| Standard audit cols | | | | Includes `deleted_at`. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Variable Name** | Text Input | Yes | String. Max: 50. Must contain only alphanumeric and underscores. Unique in `tmp_template_variables`. | None |
| **Associated Type** | Dropdown | Yes | Reference ID from `tmp_templates_type`. | None |
| **Source Database** | Text Input | No | String. Max: 60 characters. | None |
| **Source Table** | Text Input | No | String. Max: 60 characters. Required if Source Column is provided. | None |
| **Source Column** | Text Input | No | String. Max: 60 characters. Required if Source Table is provided. | None |
| **Description** | Text Area | No | String. Max: 255 characters. | None |

---

## 5. Business Logic & Validation Policies

1. **Resolution Mode Validation**:
   * If either `table_name` or `field_name` is set, **both** must be set. Form validation rejects partial mappings: *"Both source table and source column are required to configure database auto-resolution."*
2. **Variable Naming Standard**:
   * Variable names must not contain spaces or special characters (only `[a-z0-9_]`). Mismatches return: *"The variable name must contain only lowercase alphanumeric characters and underscores."*
3. **Soft Delete Cascade**:
   * Deleting a variable cascades to remove links in `tmp_templates_variables_jnt` junction records.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/template/templates-tabs` and select **Template Variables** tab.

### Scenario A: Create Automated Variable
1. Click **"New Variable"**.
2. Enter Name: `father_name`.
3. Select Type: `MARKSHEET`.
4. Enter Source Database: `tenant_db`.
5. Enter Source Table: `std_students`.
6. Enter Source Column: `father_name`. Click Save.
7. **Expected Result**:
   * Success toast: *"Template variable saved successfully."*
   * Row `father_name` appears in grid with database source listed.

### Scenario B: Create Manual Variable
1. Click **"New Variable"**.
2. Enter Name: `total_marks`. Select Type: `MARKSHEET`.
3. Leave database fields completely empty. Click Save.
4. **Expected Result**:
   * Success toast.
   * Row `total_marks` appears with database source listed as `Manual Resolution`.

### Scenario C: Partial Mapping Error
1. Click **"New Variable"**.
2. Enter Name: `roll_number`. Select Type: `MARKSHEET`.
3. Enter Source Table: `std_students`. Leave Source Column blank. Click Save.
4. **Expected Result**: Form rejects: *"Both source table and source column are required to configure database auto-resolution."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/template/templates-tabs` (select `#variables-pane`)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Template Variables')
            ->press('New Variable')
            ->type('name', 'father_name')
            ->select('template_type_id', '1') // MARKSHEET
            ->type('db_name', 'tenant_db')
            ->type('table_name', 'std_students')
            ->type('field_name', 'father_name')
            ->press('Save Variable')
            ->assertSee('Template variable saved successfully');
});
```

### 3. Partial Fields Validation Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Template Variables')
            ->press('New Variable')
            ->type('name', 'roll_number')
            ->select('template_type_id', '1')
            ->type('table_name', 'std_students') // Column blank
            ->press('Save Variable')
            ->assertSee('Both source table and source column are required');
});
```
