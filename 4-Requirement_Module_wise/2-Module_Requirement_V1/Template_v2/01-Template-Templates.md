# Templates Designer — Requirement Document

## 1. Screen Purpose & Overview

The **Templates** tab is a visual layout constructor interface. Administrators list, search, and edit available layout designs. 

The screen integrates with a canvas designer allowing drag-and-drop element positioning (saved as canvas JSON) and HTML rendering. It also enables mapping specific placeholders (variables) to the template and toggling the active draft status.

---

## 2. Common Business Use Cases

1. **Creating a Visual ID Card Canvas**: An admin opens the canvas editor, sets card dimensions, drags a photo container and student name labels, uploads a background branding image, and clicks save.
2. **Reviewing Layout Drafts**: Setting up a new Marksheet template, checking its design in draft mode (`is_active = 0`) to test print rendering before activating it.
3. **Deactivating Defunct Layouts**: Soft-deleting an outdated fee receipt template so it cannot be selected for future assignments.

---

## 3. Database Schema & Data Dictionary

*   **Primary Tables**: `tmp_templates`, `tmp_templates_variables_jnt` (junction table)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

### Table: `tmp_templates`
| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `code` | `varchar(50)` | No | N/A | Machine-readable identifier. Unique DB index. |
| `name` | `varchar(100)` | No | N/A | Display name of the template. |
| `type_id` | `int unsigned` | Yes | `NULL` | FK referencing `tmp_templates_type.id` (RESTRICT). |
| `description` | `text` | Yes | `NULL` | Explanation of layout scope. |
| `canvas_json` | `json` | Yes | `NULL` | Stores positional coordinate layout array: `[{element_id, x, y, width, font}]`. |
| `html_content` | `longtext` | Yes | `NULL` | Compiled HTML/CSS layout string used by PDF generator. |
| `background_image`| `varchar(255)`| Yes | `NULL` | Absolute path/URL to uploaded background branding image. |
| `is_active` | `tinyint(1)` | No | `0` | Status flag. `0` = Draft (hidden), `1` = Active. |
| Standard audit cols | | | | Includes `deleted_at`. |

### Table: `tmp_templates_variables_jnt`
| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `template_id` | `int unsigned` | No | N/A | FK referencing `tmp_templates.id` (CASCADE). |
| `variable_id` | `int unsigned` | No | N/A | FK referencing `tmp_template_variables.id` (RESTRICT). |
| `display_order` | `smallint unsigned`| No | `0` | Rendering order of variables. |
| `default_value` | `varchar(255)`| Yes | `NULL` | Fallback text value when database returns NULL. |
| `is_active` | `tinyint(1)` | No | `1` | Operational status of mapping. |
| Standard audit cols | | | | Includes `deleted_at`. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Template Name** | Text Input | Yes | String. Max: 100 characters. | None |
| **Unique Code** | Text Input | Yes | Alphanumeric/Underscore. Max: 50. Unique in `tmp_templates`. | None |
| **Template Type** | Dropdown | Yes | Reference ID from `tmp_templates_type`. | None |
| **Canvas Area** | Drag-drop grid | No | Compiles element attributes into JSON payload. | Empty |
| **Background Image**| File Input | No | File. Allowed: JPEG, PNG. Max: 2 MB. | None |
| **Active Status** | Checkbox | No | Boolean. Checked = active (`1`), unchecked = draft (`0`). | Unchecked (Draft) |

---

## 5. Business Logic & Validation Policies

1. **Junction Association Requirements**:
   * Before a template can transition to `is_active = 1` (Active), it must have at least one variable mapped via `tmp_templates_variables_jnt`. If not, return: *"The template must have at least one mapped variable before activation."*
2. **Background Upload Security**:
   * Files must be validated for mime-type: `image/jpeg` or `image/png`. Max size 2MB. Saved under `storage/tenant_{id}/templates/backgrounds/`.
3. **Hard Delete Restriction**:
   * Templates referenced by active assignments in `tmp_template_assignments` cannot be hard deleted. Soft deletion cascade must automatically set related assignments `is_active = 0`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/template/templates-tabs` and select **Templates** tab.

### Scenario A: Save New Template
1. Click **"Add Template"**.
2. Enter Name: `Classic Marksheet V5`.
3. Enter Code: `MSH_CLASSIC_V5`.
4. Select Type: `MARKSHEET`.
5. Upload Background Image: `border.png` (under 2MB).
6. Drag a text container block to coordinates `X: 50, Y: 100` in the visual canvas.
7. Link Variable: `student_name` to the block.
8. Click **"Save Template"**.
9. **Expected Result**: 
   * Redirects to templates grid with success alert.
   * Row `MSH_CLASSIC_V5` appears as Draft.
   * Database check: `tmp_templates` contains row, `canvas_json` has the element coordinates, and `tmp_templates_variables_jnt` has one entry linking variable `student_name`.

### Scenario B: Uniqueness Constraint Failure
1. Click **"Add Template"**.
2. Enter Code: `MSH_CLASSIC_V5` (duplicate). Click Save.
3. **Expected Result**: Validation rejects submission: *"The template code has already been taken."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/template/templates-tabs` (select `#templates-pane`)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->clickLink('Templates')
            ->press('Add Template')
            ->type('name', 'Classic Marksheet V5')
            ->type('code', 'MSH_CLASSIC_V5')
            ->select('type_id', '1') // MARKSHEET
            ->attach('background_image', __DIR__.'/files/border.png')
            ->press('Save Template')
            ->assertSee('Template saved successfully');
});
```

### 3. Duplicate Code Validation Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/template/templates-tabs')
            ->press('Add Template')
            ->type('name', 'New Marksheet')
            ->type('code', 'MSH_CLASSIC_V5') // Duplicate
            ->press('Save Template')
            ->assertSee('already been taken');
});
```
