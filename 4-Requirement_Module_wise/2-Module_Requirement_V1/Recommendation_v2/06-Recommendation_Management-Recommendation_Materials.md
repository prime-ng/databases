# Recommendation Materials — Requirement Document

## 1. Screen Purpose & Overview

The **Recommendation Materials** screen acts as the authoring workshop for remedial learning content. 

Teachers and content creators use this interface to register individual learning assets (such as PDF documents, notes, or YouTube video tutorials) and map them to the curriculum (Class, Subject, and Topic). These materials form the base content that gets recommended to students when they struggle with specific concepts.

---

## 2. Common Business Use Cases

1. **Registering a Practice Sheet**: A mathematics teacher uploads a PDF document named `Quadratic Equations Exercises` and links it to Class 10, Mathematics, Algebra.
2. **Linking Online Tutorials**: An instructor registers an external YouTube video explaining `Photosynthesis Processes` and maps it to Class 8, Biology.
3. **Updating Content Keywords**: Editing keywords (tags) and durations to ensure search queries locate the material easily.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `rec_recommendation_materials`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `title` | `varchar(255)` | No | N/A | Heading of the learning asset. |
| `description` | `text` | Yes | `NULL` | Brief summary of the material. |
| `material_type` | `bigint` | Yes | `NULL` | Foreign key referencing `rec_dynamic_material_types.id`. |
| `purpose` | `bigint` | Yes | `NULL` | Foreign key referencing `rec_dynamic_purposes.id`. |
| `content_source` | `bigint` | Yes | `NULL` | Foreign key referencing `sys_dropdowns.id` (context classification). |
| `complexity_level`| `bigint` | Yes | `NULL` | Foreign key referencing `slb_complexity_level.id`. |
| `content_text` | `text` | Yes | `NULL` | Full-text reading content (alternative to URLs). |
| `file_url` | `varchar(255)` | Yes | `NULL` | Link to uploaded PDF/Doc. Must be a valid URL format. |
| `external_url` | `varchar(255)` | Yes | `NULL` | Link to external video/resource. Must be a valid URL format. |
| `media_id` | `json` | Yes | `NULL` | Array of media files from the media system. |
| `class_id` | `bigint` | Yes | `NULL` | Foreign key referencing `sch_classes.id`. |
| `subject_id` | `bigint` | Yes | `NULL` | Foreign key referencing `sch_subjects.id`. |
| `topic_id` | `bigint` | Yes | `NULL` | Foreign key referencing `slb_topics.id`. |
| `competency_code` | `varchar(50)` | Yes | `NULL` | Target competency indicator. |
| `duration_seconds`| `integer` | Yes | `NULL` | Estimated reading/viewing duration in seconds. Must be $\ge 0$. |
| `language_code` | `varchar(10)` | Yes | `'en'` | Mapped language for localized learning. |
| `tags` | `json` | Yes | `NULL` | Comma-separated tags entered in form, stored as JSON array. |
| `is_active` | `boolean` | No | `1` (True) | Operational status. Inactive materials cannot be recommended. |
| `created_by` | `bigint` | Yes | `NULL` | Creator user ID (`sys_users.id`). |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Last updated timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Material Title** | Text Input | Yes | Must be a string. Max length: 255 characters. | None |
| **Description** | Text Area | No | Optional. Free text format. | None |
| **Material Type** | Dropdown | No | Must exist in `rec_dynamic_material_types.id`. | None |
| **Purpose** | Dropdown | No | Must exist in `rec_dynamic_purposes.id`. | None |
| **Complexity Level** | Dropdown | No | Must exist in `slb_complexity_levels.id` (or equivalent). | None |
| **Content Source** | Dropdown | No | Must exist in `sys_dropdowns.id`. | None |
| **Content Text** | Text Area | No | Optional. Free text format. | None |
| **File URL** | Text Input | No | Optional. Must pass Laravel's `url` validation rule if provided. | None |
| **External URL** | Text Input | No | Optional. Must pass Laravel's `url` validation rule if provided. | None |
| **Class** | Dropdown | No | Must exist in `sch_classes.id`. | None |
| **Subject** | Dropdown | No | Must exist in `sch_subjects.id`. | None |
| **Topic** | Dropdown | No | Must exist in `slb_topics.id`. | None |
| **Duration (Seconds)** | Number Input | No | Must be an integer. Minimum value: 0. | None |
| **Language Code** | Dropdown | No | Default option: `en`. | `'en'` |
| **Tags** | Text Input | No | Input format: comma-separated string (e.g., `algebra, quiz`). Stored as JSON array. | None |
| **Active Status** | Checkbox | No | Boolean. Defaults to true if absent using `$request->boolean('is_active', true)`. | Checked (True) |

---

## 5. Business Logic & Validation Policies

1. **Transaction Wrapping**: Create and Update processes are executed inside a database transaction block (`DB::beginTransaction`). If any part of the save (such as database writes, media associations, or tag mapping) fails, the entire transaction is rolled back.
2. **Tag Processing**: 
   * Comma-separated strings are exploded and trimmed (e.g., `"  algebra,  formulas "` is converted to `["algebra", "formulas"]` and written to the database).
   * If the tags field is empty, the database writes a `NULL` rather than an empty array.
3. **URL Validation Enforcements**: Both `file_url` and `external_url` must pass strict Laravel URL validator checks. Strings lacking `http://` or `https://` will fail validation.
4. **Cascade Soft-Deletes**: Before a material is soft-deleted, `is_active` is automatically set to `0`. Any active student recommendations linking to this material are deleted via database cascades.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher/Instructor.
* Navigate to `/recommendation/rec-material` and click the **Materials** tab.

### Scenario A: Happy Path Create
1. Click the **"Add Material"** button.
2. Enter Title: `Quadratic Equations Practice`.
3. Select Class: `Class 10`, Subject: `Mathematics`, Topic: `Quadratic Equations`.
4. Enter File URL: `https://school-portal.com/files/math-worksheet.pdf`.
5. Enter Duration: `300` seconds.
6. Enter Tags: `algebra, quadratic equations, class 10`.
7. Keep **"Active"** checked.
8. Click **"Create Material"** (Submit button).
9. **Expected Result**:
   * Page redirects back to `/recommendation/rec-material`.
   * Success flash message appears.
   * New material `Quadratic Equations Practice` appears in the listing grid.
   * Database check: Query `rec_recommendation_materials` and confirm `tags` contains `["algebra", "quadratic equations", "class 10"]` and `duration_seconds = 300`.

### Scenario B: Validation Failures
1. Click **"Add Material"**.
2. Leave **Material Title** empty.
3. Enter File URL: `invalid-url-string`.
4. Enter Duration: `-30` (negative value).
5. Click **"Create Material"**.
6. **Expected Result**: Submission fails. Error messages are displayed:
   * *"The title field is required."*
   * *"The file url must be a valid URL."*
   * *"The duration seconds must be at least 0."*

### Scenario C: AJAX Status Toggling
1. In the Materials listing table under `/recommendation/rec-material`, locate your material.
2. Click the status switch in its row.
3. **Expected Result**:
   * The switch toggles visually.
   * AJAX request is sent to `/recommendation/recommendation-materials/{id}/toggle-status` sending `is_active = 0`.
   * Toast notification confirms success: *"Status updated successfully."*
   * Database check: Confirm `is_active` has flipped to `0`.

### Scenario D: Soft Delete & Recovery
1. Locate your material in the listing table.
2. Click **"Delete"** and confirm the SweetAlert2 dialog.
3. **Expected Result**:
   * Material is removed from the active grid.
   * Database check: Confirm `deleted_at` timestamp is written and `is_active` set to `0`.
4. Navigate to `/recommendation/recommendation-materials/trash/view` to verify it appears in the trash list, click **"Restore"** to recover it, and check that it reappears in the main listing.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/rec-material`
* **Target Tab ID**: `#rec-materials-pane` (Materials Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/recommendation/recommendation-materials/create')
            ->type('title', 'Remedial Physics Sheet')
            ->type('file_url', 'https://example.com/physics.pdf')
            ->type('duration_seconds', '600')
            ->type('tags', 'physics, mechanics')
            ->press('Create Material')
            ->assertPathIs('/recommendation/rec-material')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/recommendation/recommendation-materials/create')
            ->type('title', '') // Clear title
            ->type('file_url', 'invalid-url') // Bad URL
            ->press('Create Material')
            ->assertSee('required')
            ->assertSee('must be a valid URL')
            ->assertPathIsNot('/recommendation/rec-material');
});
```
