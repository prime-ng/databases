# slb_Settings — Business Requirements

## What This Screen Does

The Settings tab is the module-wide configuration screen for the Syllabus Books module. It is a singleton feature with a single configuration record (`slb_config`, always id=1) that controls all module-level behavior: book upload limits, notes upload limits, student/teacher approval workflows, watermarking, PDF protection, visibility scoping, and active/inactive state.

The screen has two views:
1. **List Tab** (`/syllabus-books?tab=settings`) — A read-only summary table displaying all current configuration values organized into logical groups (Books, Notes, Student Uploads, Approval, Protection, Visibility).
2. **Edit Form** (`/syllabus-books/config`) — A full form where administrators can modify all settings.

---

## When This Screen Is Used

- **Initial Module Setup** when the Syllabus Books module is first enabled — no config record exists, an empty state prompts the admin to initialize defaults
- **Upload Limit Adjustment** when the school needs to change maximum file sizes for book or note uploads
- **Approval Workflow Configuration** when toggling whether student or teacher notes require administrative approval before becoming visible
- **Content Protection Setup** when enabling/disabling watermarking, PDF print prevention, or PDF copy prevention
- **Module Deactivation** when the entire module needs to be temporarily disabled without removing data

## Default Data Load

The settings tab loads the config record via `SyllabusBookConfig::query()->first()`. If no record exists, the tab shows an empty state with an "Initialize defaults" button. The edit form always guarantees a record exists via `SyllabusBookConfig::current()` which calls `firstOrCreate(['id' => 1])`. All config values are cached for 300 seconds using `Cache::remember`, and the cache is flushed on save or delete events.

---

## Key Fields at a Glance

**Books Group:**
- `max_book_size_mb` (SMALLINT, DEFAULT 50): Max book file upload size in MB. Range 1-1024.
- `allowed_book_formats` (ENUM: EPUB/JPG/PDF/PNG): Accepted book file formats.
- `is_book_downloadable` (BOOLEAN, DEFAULT 0): Whether books can be downloaded.

**Notes Group:**
- `max_notes_size_mb` (SMALLINT, DEFAULT 20): Max notes file upload size in MB. Range 1-512.
- `allowed_notes_formats` (ENUM: DOCX/JPG/PDF/PNG): Accepted notes file formats.
- `is_notes_downloadable` (BOOLEAN, DEFAULT 1): Whether notes can be downloaded.

**Student Uploads Group:**
- `allow_student_notes_upload` (BOOLEAN, DEFAULT 1): Whether students can upload notes.
- `student_notes_require_approval` (BOOLEAN, DEFAULT 1): Whether student uploads need approval.
- `student_max_uploads_per_day` (SMALLINT, DEFAULT 5): Daily upload limit per student. 0-1000.
- `student_max_uploads_per_subject` (SMALLINT, NULLABLE): Per-subject upload limit. NULL = unlimited.

**Approval Group:**
- `teacher_notes_require_approval` (BOOLEAN, DEFAULT 0): Whether teacher uploads need approval.

**Protection Group:**
- `watermark_enabled` (BOOLEAN, DEFAULT 0): Enable watermarking on PDFs.
- `watermark_text` (VARCHAR 150, NULLABLE): Custom watermark text.
- `prevent_pdf_print` (BOOLEAN, DEFAULT 0): Block PDF printing.
- `prevent_pdf_copy` (BOOLEAN, DEFAULT 0): Block PDF content copying.

**Visibility Group:**
- `notes_visible_to_other_classes` (BOOLEAN, DEFAULT 0): Whether notes are shared across classes.

**Status:**
- `is_active` (BOOLEAN, DEFAULT 1): Master module active toggle.

---

## Business Rules and Conditions

**Singleton Pattern**
The `slb_config` table always contains exactly one record (id=1). The service layer guarantees this via `firstOrCreate(['id' => 1])`.

**Cache Layer**
Config is cached for 300 seconds using `Cache::remember`. Any update or delete automatically flushes the cache via model boot events (`saved`, `deleted`). This ensures that all downstream features (note approval, upload limits, etc.) reflect the latest settings without delay.

**Boolean Field Handling**
All boolean fields use `prepareForValidation` in `SyllabusBookConfigRequest` to force unchecked checkboxes to `0`. This prevents null values when a checkbox is not present in the request.

**Empty State**
When no config record exists (fresh install), the settings tab displays a "No configuration record yet" message with a link to initialize defaults (navigates to the edit form, which triggers `firstOrCreate`).

---

## Workflow Steps

**Viewing Current Settings**
The administrator navigates to the Settings tab. The summary table displays all settings grouped by category with descriptive badges (Yes/No, On/Off, Required/Auto, Blocked/Allowed, Visible/Hidden).

**Editing Settings**
The administrator clicks the Edit button. The edit form loads pre-filled with current values. The admin modifies any settings and submits. The `SyllabusBookConfigRequest` validates all fields. On success, the config record is updated, cache is flushed, and the admin is redirected back to the settings tab with a success flash.

**Initializing Defaults**
On a fresh installation with no config record, the admin clicks "Initialize defaults." This navigates to the edit form, which auto-creates the record with default values via `firstOrCreate`. The admin can then modify and save.

---

## Example Scenario

The school IT administrator wants to configure the Syllabus Books module for the new academic year. They navigate to the Settings tab. Since no config exists, they see the empty state and click "Initialize defaults."

The system creates the config record with default values. The admin then changes:
- max_book_size_mb: 50 → 100 (allowing larger textbook uploads)
- is_book_downloadable: No → Yes (permitting student downloads)
- student_notes_require_approval: Yes → No (trusting students this year)
- watermark_enabled: No → Yes (adding "© School Name" watermark)
- watermark_text: "© Sunshine International School"

The admin saves. The system validates, updates the record, flushes the cache, and returns to the settings tab with the new values displayed. All downstream features immediately use the updated configuration.

---

## Related Screens

- **Notes Tab** — Approval workflow behavior is determined by config settings
- **Book Create/Edit** — Upload limits and format restrictions enforced per config
- **Student Uploads** — Student upload capabilities controlled by config

---

## Requirements

- The system MUST manage configuration as a singleton record (id=1) in `slb_config`.
- The system MUST expose 2 routes: edit (GET) and update (PUT) under `/syllabus-books/config`.
- The system MUST wrap all routes with `module:SYLLABUS_BOOKS` middleware.
- The system MUST authorize actions via `Gate::authorize()`:
  - `edit` → `tenant.syllabus-book-config.viewAny`
  - `update` → `tenant.syllabus-book-config.update`
- The system MUST validate all 17 config fields via `SyllabusBookConfigRequest`.
- The system MUST force boolean fields to 0 when checkboxes are unchecked (`prepareForValidation`).
- The system MUST cache the config for 300 seconds and flush cache on save/delete events.
- The system MUST auto-initialize the config record via `firstOrCreate(['id' => 1])` when the edit form is accessed.
- The system MUST display an empty state with an "Initialize defaults" link when no config record exists.
- The system MUST display the config summary table on the settings tab with grouped column display.
- The system MUST display badges/indicators for boolean values (Yes/No, On/Off, etc.).
- The system MUST redirect to the edit page with a success flash after a successful update.
- The system MUST support soft deletes on the config record.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.syllabus-book-config.viewAny`, `tenant.syllabus-book-config.update` | Full access |
| IT Administrator | `tenant.syllabus-book-config.viewAny`, `tenant.syllabus-book-config.update` | View and update settings |
| Academic Admin | `tenant.syllabus-book-config.viewAny` | View only |
| Teacher | No explicit permission | No access |
| Guest (unauthenticated) | None | Redirected to `/login` |

---

## Validate Before Save (Multiple Conditions)

1. **max_book_size_mb Required** — Must be between 1 and 1024. Error: "The max book size mb must be between 1 and 1024."
2. **allowed_book_formats Required** — Must be one of PDF, EPUB, JPG, PNG. Error: "The selected allowed book formats is invalid."
3. **max_notes_size_mb Required** — Must be between 1 and 512. Error: "The max notes size mb must be between 1 and 512."
4. **allowed_notes_formats Required** — Must be one of PDF, DOCX, JPG, PNG. Error: "The selected allowed notes formats is invalid."
5. **student_max_uploads_per_day Required** — Must be between 0 and 1000.
6. **watermark_text Max Length** — Must not exceed 150 characters. Error: "The watermark text must not be greater than 150 characters."

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| max_book_size_mb > 1024 | "The max book size mb must not be greater than 1024." | 422 |
| max_book_size_mb < 1 | "The max book size mb must be at least 1." | 422 |
| max_notes_size_mb > 512 | "The max notes size mb must not be greater than 512." | 422 |
| allowed_book_formats invalid | "The selected allowed book formats is invalid." | 422 |
| student_max_uploads_per_day > 1000 | "The student max uploads per day must not be greater than 1000." | 422 |
| watermark_text > 150 | "The watermark text must not be greater than 150 characters." | 422 |
| unauthorized | "This action is unauthorized." | 403 |
| guest access | Redirect to /login | 302 |

---

## Success Scenarios

**SC-001: Initial Configuration Setup**
1. Admin opens Settings tab for the first time. Empty state displayed.
2. Admin clicks "Initialize defaults." Edit form loads with default values.
3. Admin modifies upload limits and watermark settings, saves.
4. Record created with custom values. Cache populated. Redirect with flash.

**SC-002: Update Existing Configuration**
1. Admin modifies max_book_size_mb from 50 to 100 and enables watermarking.
2. Validation passes. Record updated. Cache flushed.
3. Settings tab displays new values immediately.

---

## Failure Scenarios

**FC-001: Invalid Allowed Format**
1. Admin enters an unsupported book format (e.g., "GIF").
2. Validation fails with 422: "The selected allowed book formats is invalid."
3. Form remains open with entered data preserved.

**FC-002: Watermark Text Exceeds Max Length**
1. Admin enters 200 characters for watermark_text.
2. Validation fails with 422: "The watermark text must not be greater than 150 characters."

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Primary Table | `slb_config` | `id` PK AI (always 1), `max_book_size_mb`, `allowed_book_formats` ENUM, `is_book_downloadable` BOOLEAN, `max_notes_size_mb`, `allowed_notes_formats` ENUM, `is_notes_downloadable` BOOLEAN, `allow_student_notes_upload` BOOLEAN, `student_notes_require_approval` BOOLEAN, `student_max_uploads_per_day` SMALLINT, `student_max_uploads_per_subject` SMALLINT NULLABLE, `teacher_notes_require_approval` BOOLEAN, `watermark_enabled` BOOLEAN, `watermark_text` VARCHAR(150) NULLABLE, `prevent_pdf_print` BOOLEAN, `prevent_pdf_copy` BOOLEAN, `notes_visible_to_other_classes` BOOLEAN, `is_active` BOOLEAN, timestamps, soft deletes |
| Module Dependency | SyllabusBooks Module | Core module providing the setting values consumed by all other features |
| Module Dependency | User & Permission Module | Auth and gates |
