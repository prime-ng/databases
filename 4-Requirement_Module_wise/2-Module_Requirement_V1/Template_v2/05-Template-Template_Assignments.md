# Template Assignments — Requirement Document

## 1. Screen Purpose & Overview

The **Template Assignments** tab is the configuration grid where administrators link designed templates to functional purposes for specific academic sessions. 

The screen enforces scoping rules, ensuring that a purpose resolves to exactly one active template for a given session, class, class group, or school fallback.

---

## 2. Common Business Use Cases

1. **Assigning Marksheet Layouts to Primary School**: Assigning layout `Primary Report Card` to purpose `MARKSHEET_PRINT` for the current academic session, scoping it to class group `Primary Group`.
2. **Assigning Class-Specific Marksheet**: Overriding the primary group layout for Grade 5 by creating a direct class assignment of layout `Grade 5 Marksheet` to `MARKSHEET_PRINT`.
3. **Setting School Wide Defaults**: Assigning `Classic Fee Receipt` to `FEE_RECEIPT` without setting class or group, establishing a universal fallback layout.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `tmp_template_assignments`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `template_id` | `int unsigned` | No | N/A | FK referencing `tmp_templates.id` (RESTRICT). |
| `purpose_id` | `int unsigned` | No | N/A | FK referencing `tmp_template_purposes.id` (RESTRICT). |
| `academic_session_id`| `smallint unsigned`| No | N/A | FK referencing `sch_org_academic_sessions_jnt.id` (RESTRICT). |
| `class_id` | `int unsigned` | Yes | `NULL` | FK referencing `sch_classes.id` (RESTRICT). Target override. |
| `class_group_id` | `int unsigned` | Yes | `NULL` | FK referencing `msh_class_groups.id` (RESTRICT). Group override. |
| `scope_hash` | `varchar(80)` | No | Generated| UNIQUE constraint string. Formulated below. |
| `is_active` | `tinyint(1)` | No | `1` | Operational status of assignment. |
| Standard audit cols | | | | Includes `deleted_at`. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Choose Template** | Dropdown | Yes | Reference ID from `tmp_templates` where `is_active = 1`. | None |
| **Associated Purpose** | Dropdown | Yes | Reference ID from `tmp_template_purposes`. | None |
| **Academic Session** | Dropdown | Yes | Reference ID from `sch_org_academic_sessions_jnt`. | Active Session |
| **Scope Level** | Radio group | Yes | Choice: School-Wide, Class Group, Specific Class. | School-Wide |
| **Target Class Group** | Dropdown | Yes (if group) | Reference ID from `msh_class_groups`. | None |
| **Target Class** | Dropdown | Yes (if class) | Reference ID from `sch_classes`. | None |

---

## 5. Business Logic & Validation Policies

1. **Check Constraint (`chk_tmp_ta_scope_target`)**:
   * A template assignment cannot have both `class_id` and `class_group_id` set. Form request validation rejects if both selectors are populated: *"An assignment cannot target both a class and a class group simultaneously."*
2. **Scope Hash Uniqueness Constraint**:
   * The database enforces a unique index on `scope_hash`.
   * **Hash Formulation**: `CONCAT(purpose_id, ':', academic_session_id, ':', COALESCE(CONCAT('C', class_id), CONCAT('G', class_group_id), 'SCHOOL'))`.
   * If a duplicate scope assignment is submitted, validation fails with: *"An active template assignment already exists for this scope."*
3. **Purpose Type Compatibility**:
   * If the chosen purpose is configured as `SCHOOL_WIDE` in `tmp_template_purposes`, the UI **must** disable the class and group selector inputs. The backend rejects any non-null class or group payloads.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/template/templates-tabs` and select **Template Assignments** tab.

### Scenario A: Happy Path Create override
1. Click **"New Assignment"**.
2. Select Template: `Grade 5 Marksheet` (Type: MARKSHEET).
3. Select Purpose: `Marksheet Printing` (`MARKSHEET_PRINT`).
4. Select Session: `2026-2027`.
5. Select Scope Level: `Specific Class`.
6. Select Target Class: `Grade 5 - A`. Click Save.
7. **Expected Result**:
   * Success toast: *"Template assignment saved successfully."*
   * Row appears in listing.
   * Database check: `scope_hash` is generated as `[purpose_id]:[session_id]:C[class_id]`.

### Scenario B: Double Target Scope Rejection
1. Click **"New Assignment"**.
2. Select Template: `Standard Marksheet`. Purpose: `Marksheet Printing`.
3. Select Session: `2026-2027`.
4. Using browser console or post request, submit values for both `class_id` and `class_group_id`.
5. **Expected Result**: Validation fails: *"An assignment cannot target both a class and a class group simultaneously."*

### Scenario C: Duplicate Scope Conflict
1. Click **"New Assignment"**.
2. Try to create the exact same override from Scenario A (Grade 5 - A, Marksheet Printing, session 2026-2027). Click Save.
3. **Expected Result**: Form rejects: *"An active template assignment already exists for this scope."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/template/templates-tabs` (select `#assignments-pane`)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Template Assignments')
            ->press('New Assignment')
            ->select('template_id', '1') // Grade 5 Marksheet ID
            ->select('purpose_id', '1') // MARKSHEET_PRINT
            ->select('academic_session_id', '3') // 2026-27
            ->radio('scope_level', 'class')
            ->select('class_id', '10') // Grade 5 - A
            ->press('Save Assignment')
            ->assertSee('Template assignment saved successfully');
});
```

### 3. Duplicate Scope Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Template Assignments')
            ->press('New Assignment')
            ->select('template_id', '2') // Different template
            ->select('purpose_id', '1')
            ->select('academic_session_id', '3')
            ->radio('scope_level', 'class')
            ->select('class_id', '10') // Same class (Grade 5 - A)
            ->press('Save Assignment')
            ->assertSee('already exists for this scope');
});
```
