# slb_Settings — Test Case List & Business Conditions

**Module:** SyllabusBooks (CODE `SLB`, prefix `slb_`) · **Feature:** Module Configuration (Singleton Settings)
**DB scope:** TENANT-side (`slb_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `slb_config` (singleton, always id=1) · **Module URL prefix:** `/syllabus-books`
**Test file:** `slb_Settings_TestCas.php`
**Tabs:** Settings (read-only list tab + edit form for module-wide config)

Routes:
- `GET     /syllabus-books?tab=settings` — SyllabusBooksController@index (master tabbed view)
- `GET     /syllabus-books/config` — SyllabusBookConfigController@edit
- `PUT     /syllabus-books/config` — SyllabusBookConfigController@update

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `slb_config` is a singleton with id=1. Columns: id (PK AI), max_book_size_mb (SMALLINT DEFAULT 50), allowed_book_formats (ENUM: EPUB/JPG/PDF/PNG), is_book_downloadable (BOOLEAN DEFAULT 0), max_notes_size_mb (SMALLINT DEFAULT 20), allowed_notes_formats (ENUM: DOCX/JPG/PDF/PNG), is_notes_downloadable (BOOLEAN DEFAULT 1), allow_student_notes_upload (BOOLEAN DEFAULT 1), student_notes_require_approval (BOOLEAN DEFAULT 1), student_max_uploads_per_day (SMALLINT DEFAULT 5), student_max_uploads_per_subject (SMALLINT NULLABLE), teacher_notes_require_approval (BOOLEAN DEFAULT 0), watermark_enabled (BOOLEAN DEFAULT 0), watermark_text (VARCHAR 150 NULLABLE), prevent_pdf_print (BOOLEAN DEFAULT 0), prevent_pdf_copy (BOOLEAN DEFAULT 0), notes_visible_to_other_classes (BOOLEAN DEFAULT 0), is_active (BOOLEAN DEFAULT 1), timestamps, soft_deletes | Migration |
| BC-DB-02 | Model `SyllabusBookConfig`: table `slb_config`, SoftDeletes, fillable includes all 17 config fields | Model:14-34 |
| BC-DB-03 | Casts: all boolean and integer fields cast correctly; watermark_text stays string | Model:36-53 |
| BC-DB-04 | Cache: `current()` static uses Cache::remember for 300s; flush on saved/deleted | Model:56-69 |
| BC-DB-05 | Service `current()`: `firstOrCreate(['id' => 1])` — guarantees singleton exists | Service:13 |

### BC-VAL — Validation (Source: `SyllabusBookConfigRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `max_book_size_mb` required integer min:1 max:1024 | Request:14 |
| BC-VAL-02 | `allowed_book_formats` required in: PDF,EPUB,JPG,PNG | Request:15 |
| BC-VAL-03 | `is_book_downloadable` nullable boolean (forced via prepareForValidation) | Request:16 |
| BC-VAL-04 | `max_notes_size_mb` required integer min:1 max:512 | Request:17 |
| BC-VAL-05 | `allowed_notes_formats` required in: PDF,DOCX,JPG,PNG | Request:18 |
| BC-VAL-06 | `is_notes_downloadable` nullable boolean (forced) | Request:19 |
| BC-VAL-07 | `allow_student_notes_upload` nullable boolean (forced) | Request:20 |
| BC-VAL-08 | `student_notes_require_approval` nullable boolean (forced) | Request:21 |
| BC-VAL-09 | `student_max_uploads_per_day` required integer min:0 max:1000 | Request:22 |
| BC-VAL-10 | `student_max_uploads_per_subject` nullable integer min:0 max:1000 | Request:23 |
| BC-VAL-11 | `teacher_notes_require_approval` nullable boolean (forced) | Request:24 |
| BC-VAL-12 | `watermark_enabled` nullable boolean (forced) | Request:25 |
| BC-VAL-13 | `watermark_text` nullable string max:150 | Request:26 |
| BC-VAL-14 | `prevent_pdf_print` nullable boolean (forced) | Request:27 |
| BC-VAL-15 | `prevent_pdf_copy` nullable boolean (forced) | Request:28 |
| BC-VAL-16 | `notes_visible_to_other_classes` nullable boolean (forced) | Request:29 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | edit() gate `tenant.syllabus-book-config.viewAny` | ConfigCtrl:15 |
| BC-AUTH-02 | update() gate `tenant.syllabus-book-config.update` | ConfigCtrl:20 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Settings tab loads config via `SyllabusBookConfig::query()->first()` (null if no record) | SyllabusBooksCtrl:76 |
| BC-BIZ-02 | No config record yet → empty state with "Initialize defaults" link to edit form | View |
| BC-BIZ-03 | edit() uses `SyllabusBookConfigService::get()` → `SyllabusBookConfig::current()` → `firstOrCreate(['id' => 1])` | Service:13 |
| BC-BIZ-04 | update() validates via SyllabusBookConfigRequest, calls service update (fill+save), flushes cache, redirects with flash | ConfigCtrl:21-25 |
| BC-BIZ-05 | All boolean fields forced via prepareForValidation (checkbox unchecked → 0) | Request:36-48 |
| BC-BIZ-06 | Cache auto-flushed on save/delete via booted saved/deleted events | Model:67-69 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | student_max_uploads_per_subject empty/null → stored as NULL (unlimited) | Migration:nullable |
| BC-EDG-02 | watermark_text null → stored as NULL | Migration:nullable |
| BC-EDG-03 | max_book_size_mb > 1024 → rejected (max:1024) | BC-VAL-01 |
| BC-EDG-04 | max_book_size_mb < 1 → rejected (min:1) | BC-VAL-01 |
| BC-EDG-05 | max_notes_size_mb > 512 → rejected (max:512) | BC-VAL-04 |
| BC-EDG-06 | student_max_uploads_per_day > 1000 → rejected | BC-VAL-09 |
| BC-EDG-07 | student_max_uploads_per_subject > 1000 → rejected | BC-VAL-10 |
| BC-EDG-08 | watermark_text > 150 chars → rejected | BC-VAL-13 |
| BC-EDG-09 | allowed_book_formats invalid value → rejected | BC-VAL-02 |
| BC-EDG-10 | allowed_notes_formats invalid value → rejected | BC-VAL-05 |
| BC-EDG-11 | Cache invalidation: update reflects immediately (not stale cache) | Model:56-69 |

---

## 2. Test Case List

### Screen 1: Settings Tab — List (GET /syllabus-books?tab=settings)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-SG-P10 | Positive | View | Settings tab renders the config summary table with all column groups: Books, Notes, Student uploads, Approval, Protection, Visibility, Status, Updated, Action | Page rendered | test_settings_10 | Automated |
| TC-SG-P11 | Positive | View | Books column displays: max size MB, allowed format, downloadable badge (Yes/No) | Books info | test_settings_11 | Automated |
| TC-SG-P12 | Positive | View | Notes column displays: max size MB, allowed format, downloadable badge | Notes info | test_settings_12 | Automated |
| TC-SG-P13 | Positive | View | Student uploads column displays: allowed badge, per-day limit, per-subject limit (or Unlimited) | Uploads info | test_settings_13 | Automated |
| TC-SG-P14 | Positive | View | Approval column displays: student approval (Required/Auto), teacher approval (Required/Auto) | Approval info | test_settings_14 | Automated |
| TC-SG-P15 | Positive | View | Protection column displays: watermark (On/Off), print (Blocked/Allowed), copy (Blocked/Allowed) | Protection info | test_settings_15 | Automated |
| TC-SG-P16 | Positive | View | Visibility column displays cross-class notes badge (Visible/Hidden) | Visibility info | test_settings_16 | Automated |
| TC-SG-P17 | Positive | View | Status badge shows Active/Inactive | Status badge | test_settings_17 | Automated |
| TC-SG-P18 | Positive | View | Updated column shows formatted timestamp | Timestamp | test_settings_18 | Automated |
| TC-SG-P19 | Positive | View | Edit button links to config edit page (permission-gated) | Edit link | test_settings_19 | Automated |
| TC-SG-P20 | Positive | View | Empty state when no config record exists: "No configuration record yet" + "Initialize defaults" button | Empty state | test_settings_20 | Automated |
| TC-SG-P21 | Positive | View | Cache is invalidated after update — list reflects latest values | Fresh data | test_settings_21 | Planned |

### Screen 2: Edit Form (GET /syllabus-books/config)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-SG-P30 | Positive | View | Edit page renders with all form fields: 3 book fields (max size, format, downloadable), 3 notes fields, 4 student upload fields, 1 teacher upload field, 4 content protection fields (watermark toggle + text, print prevent, copy prevent), 1 visibility field | All fields | test_settings_30 | Automated |
| TC-SG-P31 | Positive | View | Existing config values pre-filled in all form fields | Pre-filled | test_settings_31 | Automated |
| TC-SG-P32 | Positive | View | Checkboxes show correct checked/unchecked state matching is_active | Toggle correct | test_settings_32 | Automated |
| TC-SG-P33 | Positive | View | Breadcrumb "Syllabus Books · Settings" rendered | Breadcrumb | test_settings_33 | Automated |
| TC-SG-P34 | Positive | Ctrl | Config initialized via `firstOrCreate(['id' => 1])` when accessing edit form with no record | Auto-created | test_settings_34 | Automated |

### Screen 3: Update (PUT /syllabus-books/config)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-SG-P40 | Positive | Ctrl | Update modifies all book settings (max_book_size_mb, allowed_book_formats, is_book_downloadable) | Books updated | test_settings_40 | Automated |
| TC-SG-P41 | Positive | Ctrl | Update modifies all notes settings | Notes updated | test_settings_41 | Automated |
| TC-SG-P42 | Positive | Ctrl | Update modifies student upload settings (allow_upload, require_approval, per_day_limit, per_subject_limit) | Student updated | test_settings_42 | Automated |
| TC-SG-P43 | Positive | Ctrl | Update modifies teacher_notes_require_approval | Teacher updated | test_settings_43 | Automated |
| TC-SG-P44 | Positive | Ctrl | Update modifies content protection (watermark_enabled, watermark_text, prevent_print, prevent_copy) | Protection updated | test_settings_44 | Automated |
| TC-SG-P45 | Positive | Ctrl | Update modifies notes_visible_to_other_classes | Visibility updated | test_settings_45 | Automated |
| TC-SG-P46 | Positive | Ctrl | Checkbox unchecked → forced to 0 via prepareForValidation | Boolean 0 | test_settings_46 | Automated |
| TC-SG-P47 | Positive | Ctrl | Cache flushed after update — next read returns fresh values | Cache cleared | test_settings_47 | Automated |
| TC-SG-P48 | Positive | Ctrl | Update redirects to config.edit page with success flash | Redirect + flash | test_settings_48 | Automated |
| TC-SG-N50 | Negative | Ctrl | max_book_size_mb empty → 422 | 422 | test_settings_50 | Automated |
| TC-SG-N51 | Negative | Ctrl | max_book_size_mb > 1024 → 422 | 422 | test_settings_51 | Automated |
| TC-SG-N52 | Negative | Ctrl | max_book_size_mb < 1 → 422 | 422 | test_settings_52 | Automated |
| TC-SG-N53 | Negative | Ctrl | allowed_book_formats invalid → 422 | 422 | test_settings_53 | Automated |
| TC-SG-N54 | Negative | Ctrl | max_notes_size_mb empty → 422 | 422 | test_settings_54 | Automated |
| TC-SG-N55 | Negative | Ctrl | max_notes_size_mb > 512 → 422 | 422 | test_settings_55 | Automated |
| TC-SG-N56 | Negative | Ctrl | max_notes_size_mb < 1 → 422 | 422 | test_settings_56 | Automated |
| TC-SG-N57 | Negative | Ctrl | allowed_notes_formats invalid → 422 | 422 | test_settings_57 | Automated |
| TC-SG-N58 | Negative | Ctrl | student_max_uploads_per_day empty → 422 | 422 | test_settings_58 | Automated |
| TC-SG-N59 | Negative | Ctrl | student_max_uploads_per_day > 1000 → 422 | 422 | test_settings_59 | Automated |
| TC-SG-N60 | Negative | Ctrl | student_max_uploads_per_subject > 1000 → 422 | 422 | test_settings_60 | Automated |
| TC-SG-N61 | Negative | Ctrl | watermark_text > 150 chars → 422 | 422 | test_settings_61 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-SG-P01 | Schema | DDL/Model | Migration, model, table, fillable, casts, SoftDeletes, cache layer | All pass | test_settings_01 | Automated |
| TC-SG-P02 | Schema | Routes | Config routes registered (edit, update) | All present | test_settings_02 | Automated |
| TC-SG-P05 | Auth | Middleware | Guest redirected to /login | /login | test_settings_05 | Automated |
| TC-SG-P06 | Auth | Policy | Policy permission mapping for syllable-book-config.viewAny + update | Mapped | test_settings_06 | Automated |
| TC-SG-P07 | Auth | Ctrl | Gate authorization present on edit and update | Gates present | test_settings_07 | Automated |
| TC-SG-N08 | Auth | Ctrl | User without tenant.syllabus-book-config.viewAny → 403 on edit | 403 | test_settings_08 | Automated |
| TC-SG-N09 | Auth | Ctrl | User without tenant.syllabus-book-config.update → 403 on update | 403 | test_settings_09 | Automated |

---

## 3. Test Method Index

### File: `slb_Settings_TestCas.php` (52 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_settings_01_migration_model_and_schema | TC-SG-P01 | Schema | 01-04 |
| 2 | test_settings_02_config_routes_are_registered | TC-SG-P02 | Schema | 01-04 |
| 3 | test_settings_05_guest_redirected_to_login | TC-SG-P05 | Auth | 05-09 |
| 4 | test_settings_06_policy_permission_mapping_is_correct | TC-SG-P06 | Auth | 05-09 |
| 5 | test_settings_07_controller_gate_authorization_is_present | TC-SG-P07 | Auth | 05-09 |
| 6 | test_settings_08_user_without_viewAny_permission_gets_403 | TC-SG-N08 | Auth | 05-09 |
| 7 | test_settings_09_user_without_update_permission_gets_403 | TC-SG-N09 | Auth | 05-09 |
| 8 | test_settings_10_settings_tab_renders_summary_table | TC-SG-P10 | List | 10-29 |
| 9 | test_settings_11_books_column_displays_info | TC-SG-P11 | List | 10-29 |
| 10 | test_settings_12_notes_column_displays_info | TC-SG-P12 | List | 10-29 |
| 11 | test_settings_13_student_uploads_column_displays_info | TC-SG-P13 | List | 10-29 |
| 12 | test_settings_14_approval_column_displays_info | TC-SG-P14 | List | 10-29 |
| 13 | test_settings_15_protection_column_displays_info | TC-SG-P15 | List | 10-29 |
| 14 | test_settings_16_visibility_column_displays_info | TC-SG-P16 | List | 10-29 |
| 15 | test_settings_17_status_badge_active_inactive | TC-SG-P17 | List | 10-29 |
| 16 | test_settings_18_updated_timestamp_displayed | TC-SG-P18 | List | 10-29 |
| 17 | test_settings_19_edit_button_links_to_config_edit | TC-SG-P19 | List | 10-29 |
| 18 | test_settings_20_empty_state_when_no_config | TC-SG-P20 | List | 10-29 |
| 19 | test_settings_21_cache_invalidated_after_update | TC-SG-P21 | List | 10-29 |
| 20 | test_settings_30_edit_form_renders_all_fields | TC-SG-P30 | Edit | 30-39 |
| 21 | test_settings_31_existing_values_pre_filled | TC-SG-P31 | Edit | 30-39 |
| 22 | test_settings_32_checkboxes_show_correct_state | TC-SG-P32 | Edit | 30-39 |
| 23 | test_settings_33_breadcrumb_rendered | TC-SG-P33 | Edit | 30-39 |
| 24 | test_settings_34_config_auto_created_on_first_edit | TC-SG-P34 | Edit | 30-39 |
| 25 | test_settings_40_update_book_settings | TC-SG-P40 | Update | 40-49 |
| 26 | test_settings_41_update_notes_settings | TC-SG-P41 | Update | 40-49 |
| 27 | test_settings_42_update_student_upload_settings | TC-SG-P42 | Update | 40-49 |
| 28 | test_settings_43_update_teacher_approval | TC-SG-P43 | Update | 40-49 |
| 29 | test_settings_44_update_content_protection | TC-SG-P44 | Update | 40-49 |
| 30 | test_settings_45_update_visibility | TC-SG-P45 | Update | 40-49 |
| 31 | test_settings_46_unchecked_checkbox_forced_to_0 | TC-SG-P46 | Update | 40-49 |
| 32 | test_settings_47_cache_flushed_on_update | TC-SG-P47 | Update | 40-49 |
| 33 | test_settings_48_update_redirects_with_flash | TC-SG-P48 | Update | 40-49 |
| 34 | test_settings_50_max_book_size_empty_422 | TC-SG-N50 | Val | 50-69 |
| 35 | test_settings_51_max_book_size_exceeds_1024_422 | TC-SG-N51 | Val | 50-69 |
| 36 | test_settings_52_max_book_size_below_1_422 | TC-SG-N52 | Val | 50-69 |
| 37 | test_settings_53_allowed_book_formats_invalid_422 | TC-SG-N53 | Val | 50-69 |
| 38 | test_settings_54_max_notes_size_empty_422 | TC-SG-N54 | Val | 50-69 |
| 39 | test_settings_55_max_notes_size_exceeds_512_422 | TC-SG-N55 | Val | 50-69 |
| 40 | test_settings_56_max_notes_size_below_1_422 | TC-SG-N56 | Val | 50-69 |
| 41 | test_settings_57_allowed_notes_formats_invalid_422 | TC-SG-N57 | Val | 50-69 |
| 42 | test_settings_58_student_uploads_per_day_empty_422 | TC-SG-N58 | Val | 50-69 |
| 43 | test_settings_59_student_uploads_per_day_exceeds_1000_422 | TC-SG-N59 | Val | 50-69 |
| 44 | test_settings_60_student_uploads_per_subject_exceeds_1000_422 | TC-SG-N60 | Val | 50-69 |
| 45 | test_settings_61_watermark_text_exceeds_150_422 | TC-SG-N61 | Val | 50-69 |
| 46 | test_settings_90_records_are_tenant_scoped | TC-SG-T90 | Tenancy | 90-99 |
| 47 | test_settings_91_stored_xss_in_watermark_text_escaped | TC-SG-P91 | Security | 90-99 |

**Total: 47 methods (46 Automated, 1 Planned).**
