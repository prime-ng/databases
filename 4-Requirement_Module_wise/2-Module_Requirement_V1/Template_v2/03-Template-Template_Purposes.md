# Template Purposes — Requirement Document

## 1. Screen Purpose & Overview

The **Template Purposes** tab acts as a functional registry mapping output purposes a template can serve in the ERP. 

Administrators define lookup codes (like `MARKSHEET_PRINT`, `STUDENT_ID_CARD`) and specify whether they operate at a class-specific targeting scope (`CLASS_SCOPED`) or apply universally school-wide (`SCHOOL_WIDE`). This designation determines which fields are shown during template assignment workflows.

---

## 2. Common Business Use Cases

1. **Mapping Class Scoped Purposes**: Registering `Exam Admit Card` with scope `CLASS_SCOPED`, allowing teachers to assign different layout templates for primary and secondary sections.
2. **Mapping School Wide Purposes**: Registering `Fee Receipt` with scope `SCHOOL_WIDE`, ensuring that all classes print the same layout template.
3. **Ordering Lists**: Re-arranging purposes on display screens to place high-frequency targets at the top.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `tmp_template_purposes`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `code` | `varchar(30)` | No | N/A | Unique machine key (e.g. `MARKSHEET_PRINT`). UNIQUE DB index. |
| `name` | `varchar(100)` | No | N/A | Display label of the purpose. |
| `description` | `varchar(255)`| Yes | `NULL` | Explanation of where the purpose is used in the ERP. |
| `scope_type_id` | `int unsigned` | No | N/A | FK referencing `sys_dropdowns.id` (RESTRICT) for scope types. |
| `display_order` | `smallint unsigned`| No | `1` | Sorting rank in dropdown lists. |
| `is_system` | `tinyint(1)` | No | `0` | Flag for seeded records. `1` = system protected, `0` = custom. |
| `is_active` | `tinyint(1)` | No | `1` | Operational status of lookup. |
| Standard audit cols | | | | Includes `deleted_at`. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Purpose Name** | Text Input | Yes | String. Max: 100 characters. | None |
| **Unique Code** | Text Input | Yes | Alphanumeric/Underscore. Max: 30 characters. Unique in `tmp_template_purposes`. | None |
| **Target Scope** | Dropdown | Yes | Reference ID from `sys_dropdowns` (CLASS_SCOPED or SCHOOL_WIDE). | CLASS_SCOPED |
| **Display Order** | Number Input | Yes | Integer. Minimum: 1. | 1 |
| **Description** | Text Area | No | String. Max: 255 characters. | None |

---

## 5. Business Logic & Validation Policies

1. **Seeding Dependencies**:
   * Before saving a purpose, the system verifies `scope_type_id` exists in `sys_dropdowns` where `key = 'tmp_template_purposes.scope_type_id'`.
2. **System Protected Rules**:
   * Seeded purposes (e.g. `MARKSHEET_PRINT`, `STUDENT_ID_CARD`, `TRANSFER_CERT`, `CHARACTER_CERT`, `ADMIT_CARD`, `FEE_RECEIPT`) are marked `is_system = 1`. Any update to change their `code` or `scope_type_id`, or delete actions, are blocked: *"System protected purposes cannot be modified or deleted."*
3. **Casacade Deactivation**:
   * If a custom purpose is soft-deleted, related assignments in `tmp_template_assignments` are cascading-marked `is_active = 0`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/template/templates-tabs` and select **Template Purposes** tab.

### Scenario A: Save Custom Purpose
1. Click **"Add Purpose"**.
2. Enter Name: `Library Card Layout`.
3. Enter Code: `LIBRARY_CARD`.
4. Select Scope: `CLASS_SCOPED`.
5. Enter Display Order: `10`. Click Save.
6. **Expected Result**:
   * Success toast: *"Template purpose saved successfully."*
   * Row `LIBRARY_CARD` is active in the list.

### Scenario B: Modifying System Purpose Code
1. Locate row `MARKSHEET_PRINT` (`is_system = 1`). Click Edit.
2. Change Code to: `MARKSHEET_PRINT_NEW`. Click Save.
3. **Expected Result**: Validation fails: *"System protected purposes cannot be modified or deleted."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/template/templates-tabs` (select `#purposes-pane`)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Template Purposes')
            ->press('Add Purpose')
            ->type('name', 'Library Card Layout')
            ->type('code', 'LIBRARY_CARD')
            ->select('scope_type_id', '1') // CLASS_SCOPED ID
            ->type('display_order', '10')
            ->press('Save Purpose')
            ->assertSee('Template purpose saved successfully');
});
```

### 3. Duplicate Code Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Template Purposes')
            ->press('Add Purpose')
            ->type('name', 'Duplicate Marksheet')
            ->type('code', 'MARKSHEET_PRINT') // Seeded duplicate code
            ->press('Save Purpose')
            ->assertSee('already been taken');
});
```
