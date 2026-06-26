# Certificate Templates — Requirement Document

## 1. Screen Purpose & Overview

The **Certificate Templates** tab provides a visual template constructor where admins design the layout of issued certificates using HTML/CSS. 

The screen integrates with a real-time DomPDF preview and allows admins to map database values using placeholders like `{{student_name}}` and `{{class_section}}`. It handles version archiving, enabling rollback to previous saves, and enforces standard print settings like paper sizing and default options per type.

---

## 2. Common Business Use Cases

1. **Designing a Standard Layout**: Creating a Bonafide Certificate template using custom CSS, school logos, and signature blocks, and mapping placeholders.
2. **Reverting Broken Edits**: Restoring version 3 of a template after an administrator accidentally breaks the HTML layout in version 4.
3. **Switching Defaults**: Registering a new, modern Transfer Certificate template and setting it as the active default for the type.

---

## 3. Database Schema & Data Dictionary

*   **Primary Tables**: `crt_templates` (soft-deleted), `crt_template_versions` (immutable snapshots)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

### Table: `crt_templates`
| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `certificate_type_id` | `int unsigned` | No | N/A | Foreign key referencing `crt_certificate_types.id` (ON DELETE CASCADE). |
| `name` | `varchar(150)` | No | N/A | Unique label identifying the template. |
| `template_content` | `longtext` | No | N/A | Full HTML and CSS styles containing placeholders. |
| `variables_json` | `json` | No | N/A | Array of merge fields referenced inside the HTML content. |
| `page_size` | `enum` | No | `'a4'` | Options: `'a4'`, `'a5'`, `'letter'`, `'custom'`. |
| `orientation` | `enum` | No | `'portrait'` | Options: `'portrait'`, `'landscape'`. |
| `is_default` | `tinyint(1)` | No | `0` | Flag setting this template as default for its type. Only one can be true. |
| `signature_placement_json` | `json` | Yes | `NULL` | Stores `{x, y, w, h}` coordinates for digital signature block. |
| `version_no` | `smallint unsigned`| No | `1` | Tracks the active revision sequence number. |
| Standard audit cols | | | | Includes `deleted_at`. |

### Table: `crt_template_versions` (Archive, NO `deleted_at`)
| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `template_id` | `int unsigned` | No | N/A | Foreign key referencing `crt_templates.id` (ON DELETE CASCADE). |
| `version_no` | `smallint unsigned`| No | N/A | Historical version number. |
| `template_content` | `longtext` | No | N/A | Snapshotted HTML string. |
| `variables_json` | `json` | No | N/A | Snapshotted variables array. |
| `saved_by` | `int unsigned` | No | N/A | User who saved this version (`sys_users.id` RESTRICT). |
| `saved_at` | `timestamp` | No | N/A | Creation date of this snapshot. |
| Audit cols | | | | `created_by`, `updated_by`, `created_at`, `updated_at` (no soft deletes). |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Associated Type** | Dropdown | Yes | Must reference active ID in `crt_certificate_types`. | None |
| **Template Name** | Text Input | Yes | String. Max: 150 characters. | None |
| **HTML/CSS Editor** | Code Area | Yes | Plaintext. Must not contain PHP code or illegal script tags. | Basic template skeleton |
| **Declared Placeholders**| Tag Input | Yes | Array of strings. Every tag must map to a `{{placeholder}}` in the HTML editor. | None |
| **Page Size** | Dropdown | Yes | Options: A4, A5, Letter, Custom. | A4 |
| **Orientation** | Radio group | Yes | Choice: Portrait, Landscape. | Portrait |
| **Signature Coordinates** | Coordinates | No | X, Y, Width, Height positive floats. | None |
| **Set as Default** | Checkbox | No | Boolean. Checked = default. | Unchecked (False) |

---

## 5. Business Logic & Validation Policies

1. **Placeholder Match Validation**:
   * Custom Rule (`VariablesMatchPlaceholders`): When saving, the backend parses the HTML content using regex `\{\{([a-zA-Z0-9_]+)\}\}`. All extracted terms must exist in the `variables_json` payload, and vice versa. If they mismatch, validation fails: *"The declared variables do not match placeholders found in the HTML content."*
2. **Single Default Enforcer**:
   * Wrap in a DB transaction: if the template is saved with `is_default = true`, the system executes `UPDATE crt_templates SET is_default = 0 WHERE certificate_type_id = ?` before saving the current template.
3. **Version Snapshots**:
   * Before updating an existing template record, copy current database values into a new row in `crt_template_versions`, setting the version number. Increment the template's active `version_no`.
4. **Hard Delete Block**:
   * A database foreign key constraint (`ON DELETE RESTRICT`) on `crt_issued_certificates.template_id` prevents templates from being deleted if they have active issued certificates.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/certificate/templates`.

### Scenario A: Happy Path Save with Variables
1. Click **"New Template"**.
2. Select Associated Type: `Bonafide Certificate`. Enter Name: `Standard Bonafide V1`.
3. Set editor contents:
   ```html
   <div class="cert">This certifies that {{student_name}} is in {{class_section}}.</div>
   ```
4. Enter Declared Placeholders: `student_name`, `class_section`.
5. Check "Set as Default" and click **"Save Template"**.
6. **Expected Result**: 
   * Redirects to index, success alert displays.
   * `is_default` toggles successfully. Previous templates for Bonafide reset to non-default.
   * Database check: `crt_templates` contains the new row, and `version_no` equals `1`.

### Scenario B: Variables Validation Error
1. In the editor, add a new placeholder `{{dob}}` to the HTML.
2. Do NOT add `dob` to the Declared Placeholders list. Click Save.
3. **Expected Result**: Validation stops form submission: *"The declared variables do not match placeholders found in the HTML content."*

### Scenario C: Version History Restore
1. Edit the template and change orientation to Landscape. Save (creates version 1 snapshot).
2. Go to the Template Version History view. Locate Version 1. Click **"Restore Version"**.
3. **Expected Result**: The template switches back to Portrait orientation. The template's active `version_no` increments to `3`, and a snapshot of the landscape version is archived in the history.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/templates/create`
* **Edit Route**: `/certificate/templates/{id}/edit`
* **Preview Route**: `/certificate/templates/{id}/preview`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/templates/create')
            ->select('certificate_type_id', '1') // e.g. BON
            ->type('name', 'Classic Bonafide Layout')
            ->type('template_content', '<div>Name: {{student_name}}</div>')
            ->type('variables_json[]', 'student_name') // tag input simulated
            ->select('page_size', 'a4')
            ->radio('orientation', 'portrait')
            ->check('is_default')
            ->press('Save Template')
            ->assertPathIs('/certificate/templates')
            ->assertSee('Template saved successfully');
});
```

### 3. Placeholders Mismatch Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/templates/create')
            ->select('certificate_type_id', '1')
            ->type('name', 'Invalid Template')
            ->type('template_content', '<div>Name: {{student_name}} and Age: {{age}}</div>')
            ->type('variables_json[]', 'student_name') // Missing 'age'
            ->press('Save Template')
            ->assertSee('do not match placeholders');
});
```
