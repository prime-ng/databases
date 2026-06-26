# Material Bundles — Requirement Document

## 1. Screen Purpose & Overview

The **Material Bundles** screen allows teachers to group multiple learning materials into sequential remedial packages. 

A bundle acts as a structured path designed to guide students through multi-concept learning deficits (e.g., studying a reference PDF, watching an application video, and then completing a practice quiz in sequence). Each material within a bundle can be set as either mandatory or optional.

---

## 2. Common Business Use Cases

1. **Structuring a Remedial Guide**: A teacher creates a bundle named `Intro to Derivatives Packet` containing a video link (Sequence: 1, Mandatory: Yes) and a practice sheet (Sequence: 2, Mandatory: Yes).
2. **Sequential Practice**: Reordering materials within a bundle so the student progresses from basic theory to complex practice sheets.
3. **Updating Bundle Metadata**: Modifying the title and description of a bundle based on curriculum updates.

---

## 3. Database Schema & Data Dictionary

*   **Main Table**: `rec_material_bundles`
*   **Pivot/Junction Table**: `rec_bundle_materials_jnt`
*   **Primary Key**: `id` on main table. No primary key or timestamps on pivot table.

### Main Table Schema: `rec_material_bundles`

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `title` | `varchar(255)` | No | N/A | Heading for the bundle. |
| `description` | `text` | Yes | `NULL` | Brief explanation of the bundle. |
| `school_id` | `bigint` | No | N/A | Tenant association key (`sch_organizations.id`). |
| `created_by` | `bigint` | Yes | `NULL` | User ID of the creator (`sys_users.id`). |
| `is_active` | `boolean` | No | `1` (True) | Operational status. Inactive bundles ignore rule evaluations. |
| `created_at` | `timestamp` | Yes | `NULL` | Timestamp of creation. |
| `updated_at` | `timestamp` | Yes | `NULL` | Timestamp of last modification. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

### Pivot Table Schema: `rec_bundle_materials_jnt`

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `bundle_id` | `bigint` | No | N/A | Foreign key referencing `rec_material_bundles.id` with cascade deletion. |
| `material_id` | `bigint` | No | N/A | Foreign key referencing `rec_recommendation_materials.id` with cascade deletion. |
| `sequence_order`| `integer` | No | `1` | Order of material appearance within the bundle. |
| `is_mandatory` | `boolean` | No | `1` (True) | If true, the student must complete this item to finish the bundle. |

---

## 4. Screen Fields & Input Rules

### Create Screen Fields
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Bundle Title** | Text Input | Yes | Must be a string. Max length: 255 characters. | None |
| **School** | Dropdown | Yes | Must exist in `sch_organizations.id`. | None |
| **Description** | Text Area | No | Optional. Free text format. | None |
| **Materials Checklist** | Multi-Select/List | No | Optional array. Each item inputs: `material_id` (FK check), `sequence_order` (integer $\ge 1$), and `is_mandatory` (boolean checkbox). | None |
| **Active Status** | Checkbox | No | Boolean. Present in request means true (`1`), absent means false (`0`). | Checked (True) |

### Edit Screen Fields
*   **Important Limitation**: The School dropdown and Materials checklist are **hidden/disabled** on the Edit screen. Only Title, Description, and Active Status are editable during updates.

---

## 5. Business Logic & Validation Policies

1. **Transaction Integrity**: The creation and update processes are wrapped inside a database transaction block (`DB::transaction`). If any database insert fails (e.g., invalid school ID or pivot foreign key mismatch), both tables roll back.
2. **Junction Management (`sync` vs `attach`)**:
   * **On Create**: Materials are attached to the pivot table using `$bundle->materials()->attach(...)`.
   * **On Update**: Pivot rows are updated or synced. If the materials input is missing during update, standard behavior is to keep the existing pivot records (or clear them if empty arrays are passed, depending on controllers).
3. **Deactivation Cascade**: Before soft-deleting a bundle, `is_active` is automatically set to `0`. Pivot rows are not removed during soft-delete.
4. **Data Integrity Checks**: Pivot table `rec_bundle_materials_jnt` has no timestamps. Soft delete is only applied to the main table.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher.
* Navigate to `/recommendation/rec-material` and click the **Material Bundles** tab.

### Scenario A: Happy Path Create
1. Click the **"Add Bundle"** button.
2. Enter Title: `Intro to Algebra Package`.
3. Select School: `Main Campus School`.
4. Enter Description: `Sequential guide covering linear and quadratic equations`.
5. Select Materials:
   * Select `Algebra Basics Video` (Set Sequence: 1, Check Mandatory).
   * Select `Practice Sheet 1` (Set Sequence: 2, Check Mandatory).
6. Click **"Create Bundle"** (Submit button).
7. **Expected Result**:
   * Page redirects back to `/recommendation/rec-material`.
   * Success flash message appears.
   * New bundle appears in the listing.
   * Database check: Query `rec_material_bundles` and verify `school_id` matches. Query `rec_bundle_materials_jnt` and verify 2 rows exist with correct sequence orders.

### Scenario B: Validation Failures
1. Click **"Add Bundle"**.
2. Leave **Bundle Title** empty.
3. Click **"Create Bundle"**.
4. **Expected Result**: Validation fails. Error message appears: *"The title field is required."*

### Scenario C: AJAX Status Toggling
1. In the Material Bundles listing grid, locate `Intro to Algebra Package`.
2. Click the status switch in its row.
3. **Expected Result**:
   * AJAX request is sent to `/recommendation/material-bundles/{id}/toggle-status`.
   * Toast notification confirms success: *"Status updated successfully."*
   * Database check: Confirm `is_active` has flipped to `0`.

### Scenario D: Soft Delete & Recovery
1. Locate your bundle in the listing grid.
2. Click **"Delete"** and confirm the SweetAlert2 dialog.
3. **Expected Result**:
   * Bundle is removed from the active grid.
   * Database check: Confirm `deleted_at` timestamp is written and `is_active` set to `0`. Junction rows remain intact in `rec_bundle_materials_jnt`.
4. Navigate to `/recommendation/material-bundles/trash/view`, verify it appears in the trash list, click **"Restore"** to recover it, and check that it reappears in the main listing.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/rec-material`
* **Target Tab ID**: `#rec-material-bundle-pane` (Material Bundles Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/recommendation/material-bundles/create')
            ->type('title', 'Remedial Math Bundle')
            ->select('school_id', '1') // Target School ID
            ->type('description', 'Remedial algebra bundle')
            ->check('is_active')
            ->press('Create Bundle')
            ->assertPathIs('/recommendation/rec-material')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/recommendation/material-bundles/create')
            ->type('title', '') // Clear title
            ->press('Create Bundle')
            ->assertSee('required')
            ->assertPathIsNot('/recommendation/rec-material');
});
```
