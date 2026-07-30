# slb_Author — Test Case List & Business Conditions

**Module:** SyllabusBooks (CODE `SLB`, prefix `slb_`) · **Feature:** Author Master (CRUD + Trash + Toggle Status)
**DB scope:** TENANT-side (`slb_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `slb_book_authors` · **Module URL prefix:** `/syllabus-books`
**Test file:** `slb_Author_TestCas.php`
**Tabs:** Author (first CRUD tab of the Syllabus Books module)

Routes:
- `GET     /syllabus-books?tab=author` — SyllabusBooksController@index (master tabbed view)
- `GET     /syllabus-books/authors` — AuthorController@index (redirects to master tab)
- `GET     /syllabus-books/authors/create` — AuthorController@create
- `POST    /syllabus-books/authors` — AuthorController@store
- `GET     /syllabus-books/authors/{author}` — AuthorController@show
- `GET     /syllabus-books/authors/{author}/edit` — AuthorController@edit
- `PUT     /syllabus-books/authors/{author}` — AuthorController@update
- `DELETE  /syllabus-books/authors/{author}` — AuthorController@destroy
- `GET     /syllabus-books/authors/trash/view` — AuthorController@trashedAuthor
- `GET     /syllabus-books/authors/{id}/restore` — AuthorController@restore
- `DELETE  /syllabus-books/authors/{id}/force-delete` — AuthorController@forceDelete
- `POST    /syllabus-books/authors/{author}/toggle-status` — AuthorController@toggleStatus

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `slb_book_authors` exists with columns: id (INT PK AI), name (VARCHAR 150 NOT NULL UNIQUE), qualification (VARCHAR 200 NULLABLE), bio (TEXT NULLABLE), is_active (BOOLEAN DEFAULT 1), created_at, updated_at, deleted_at | Migration:14-23 |
| BC-DB-02 | Unique index `uq_author_name` on `name` column | Migration:21 |
| BC-DB-03 | Model `BookAuthors`: table `slb_book_authors`, SoftDeletes, fillable: [name, qualification, bio, is_active] | BookAuthors.php:13-20 |
| BC-DB-04 | Casts: `is_active` → boolean | BookAuthors.php:22-24 |
| BC-DB-05 | Relationship: books() belongsToMany via `slb_book_author_jnt` with pivot `author_role` | BookAuthors.php:27-30 |
| BC-DB-06 | Pivot table `slb_book_author_jnt`: columns book_id, author_id, author_role (ENUM: CONTRIBUTOR,CO_AUTHOR,EDITOR,PRIMARY), ordinal (TINYINT), composite PK (book_id, author_id) | Migration |

### BC-VAL — Validation (Source: `AuthorRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:150 unique:slb_book_authors (ignore self on update) | AuthorRequest:12-18 |
| BC-VAL-02 | `qualification` nullable string max:200 | AuthorRequest:20 |
| BC-VAL-03 | `bio` nullable string | AuthorRequest:22 |
| BC-VAL-04 | `is_active` required boolean (force 0 via prepareForValidation when checkbox unchecked) | AuthorRequest:24,34-36 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `tenant.author.viewAny` | Ctrl:20 |
| BC-AUTH-02 | create()/store() gate `tenant.author.create` | Ctrl:30,38 |
| BC-AUTH-03 | show() gate `tenant.author.view` | Ctrl:64 |
| BC-AUTH-04 | edit()/update() gate `tenant.author.update` | Ctrl:72,78 |
| BC-AUTH-05 | destroy() gate `tenant.author.delete` | Ctrl:99 |
| BC-AUTH-06 | trashedAuthor()/restore() gate `tenant.author.restore` | Ctrl:95,111 |
| BC-AUTH-07 | forceDelete() gate `tenant.author.forceDelete` | Ctrl:118 |
| BC-AUTH-08 | toggleStatus() gate `tenant.author.update` | Ctrl:155 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index() redirects to `syllabus-books.index?tab=author` | Ctrl:23-24 |
| BC-BIZ-02 | Master index query: filters by search (name/bio LIKE), qualification (LIKE), status (exact 0/1), ordered by name ASC, paginated 10, withCount('books') | SyllabusBooksCtrl:53-65 |
| BC-BIZ-03 | store() uses AuthorRequest, catches QueryException 23000 for duplicate name, logs 'Created' activity | Ctrl:40-53 |
| BC-BIZ-04 | update() same pattern with duplicate catch, logs 'Updated' activity | Ctrl:80-91 |
| BC-BIZ-05 | destroy() sets is_active=false, calls delete(), logs 'Trashed' activity | Ctrl:100-105 |
| BC-BIZ-06 | restore() uses withTrashed()->findOrFail, logs 'Restored' activity | Ctrl:112-116 |
| BC-BIZ-07 | forceDelete() deletes pivot rows first, then force-deletes, logs 'Deleted' activity; catches FK 23000 | Ctrl:119-151 |
| BC-BIZ-08 | toggleStatus() flips is_active, logs 'Toggled', returns JSON `{success, is_active, message}` | Ctrl:156-165 |
| BC-BIZ-09 | All CRUD redirects go to syllabus-books.index with tab=author (except restore/forceDelete go to trashed view) | Ctrl:47,86,107,115,146 |
| BC-BIZ-10 | prepareForValidation forces is_active=0 when checkbox is not present in request | AuthorRequest:34-36 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing id for show/edit/update/destroy → 404 (findOrFail) | Ctrl |
| BC-EDG-02 | WithTrashed for restore/forceDelete → 404 if not in trash | Ctrl:112,122 |
| BC-EDG-03 | Duplicate name on store → 23000 caught, redirects back with error | Ctrl:49-52 |
| BC-EDG-04 | Duplicate name on update → same as store | Ctrl:87-90 |
| BC-EDG-05 | Force delete on author referenced by books → 23000 caught, redirects with error | Ctrl:146-149 |
| BC-EDG-06 | name NULL → validation failure (required) | BC-VAL-01 |
| BC-EDG-07 | name exceeds 150 chars → validation failure (max:150) | BC-VAL-01 |
| BC-EDG-08 | qualification exceeds 200 chars → validation failure (max:200) | BC-VAL-02 |
| BC-EDG-09 | Empty list on index → "Not Data Found" message displayed | View:87-88 |

---

## 2. Test Case List

### Screen 1: Index (GET /syllabus-books?tab=author)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P10 | Positive | Ctrl | Author tab renders with search, qualification, status filters and results table | Page rendered | test_author_10 | Automated |
| TC-AU-P11 | Positive | Ctrl | Search by name (LIKE) filters results | Filtered | test_author_11 | Automated |
| TC-AU-P12 | Positive | Ctrl | Search by bio (LIKE) filters results | Filtered | test_author_12 | Automated |
| TC-AU-P13 | Positive | Ctrl | Filter by qualification (LIKE) narrows results | Filtered | test_author_13 | Automated |
| TC-AU-P14 | Positive | Ctrl | Filter by status (Active=1 / Inactive=0) narrows results | Filtered | test_author_14 | Automated |
| TC-AU-P15 | Positive | Ctrl | Combined filters (search + qualification + status) work together | Filtered | test_author_15 | Automated |
| TC-AU-P16 | Positive | Ctrl | Result set is paginated (default 10 per page, `authors_page` param) | Paginated | test_author_16 | Automated |
| TC-AU-P17 | Positive | View | Each row displays: Name, Qualification, Status toggle, Action buttons | All columns visible | test_author_17 | Automated |
| TC-AU-P18 | Positive | View | Action buttons per row: View, Edit, Delete (permission-gated) | 3 buttons visible | test_author_18 | Automated |
| TC-AU-P19 | Positive | View | Status toggle switch present on every row (permission-gated) | Toggle present | test_author_19 | Automated |
| TC-AU-P20 | Positive | View | Table is ordered by name ascending | Sorted | test_author_20 | Automated |
| TC-AU-P21 | Positive | View | Records count badge visible (withCount('books')) | Count visible | test_author_21 | Planned |
| TC-AU-P22 | Positive | View | Empty data message: "Not Data Found" when no records match filters | Empty state | test_author_22 | Automated |
| TC-AU-P23 | Positive | View | Refresh/reset button clears all filters | Filters cleared | test_author_23 | Planned |

### Screen 2: Create Form (GET /syllabus-books/authors/create)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P30 | Positive | View | Create page renders all form fields: name, qualification, bio (textarea), status switch | Fields rendered | test_author_30 | Automated |

### Screen 3: Store (POST /syllabus-books/authors)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P40 | Positive | Ctrl | Valid store creates author with all fields | Row created | test_author_40 | Automated |
| TC-AU-P41 | Positive | Ctrl | is_active defaults to true when checkbox is checked | is_active=1 | test_author_41 | Automated |
| TC-AU-P42 | Positive | Ctrl | is_active forced to 0 when checkbox is unchecked (prepareForValidation) | is_active=0 | test_author_42 | Automated |
| TC-AU-P43 | Positive | Ctrl | Store writes 'Created' activity log | Log entry | test_author_43 | Automated |
| TC-AU-P44 | Positive | Ctrl | Store redirects to syllabus-books.index?tab=author with success flash | Redirect + flash | test_author_44 | Automated |
| TC-AU-P45 | Positive | Ctrl | bio can be null/omitted → saved as NULL | bio=NULL | test_author_45 | Automated |
| TC-AU-P46 | Positive | Ctrl | qualification can be null/omitted → saved as NULL | qualification=NULL | test_author_46 | Automated |
| TC-AU-N50 | Negative | Ctrl | name required (empty) → rejected | 422 | test_author_50 | Automated |
| TC-AU-N51 | Negative | Ctrl | name exceeds 150 chars → rejected | 422 | test_author_51 | Automated |
| TC-AU-N52 | Negative | Ctrl | Duplicate name → caught as 23000, redirect back with error | Error flash | test_author_52 | Automated |
| TC-AU-N53 | Negative | Ctrl | qualification exceeds 200 chars → rejected | 422 | test_author_53 | Automated |
| TC-AU-N54 | Negative | Ctrl | is_active not boolean (string) → rejected | 422 | test_author_54 | Automated |

### Screen 4: Show (GET /syllabus-books/authors/{author})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P60 | Positive | View | Show page displays: Name, Qualification, Bio, Status badge, Created At, Updated At, Number of Books | All fields displayed | test_author_60 | Automated |
| TC-AU-P61 | Positive | View | Show page shows hyphen for null qualification/bio | Dash shown | test_author_61 | Automated |
| TC-AU-P62 | Positive | View | Sidebar has Back to List and Edit Author buttons (permission-gated) | 2 buttons | test_author_62 | Automated |
| TC-AU-N70 | Negative | Ctrl | Invalid id → 404 | 404 | test_author_70 | Automated |
| TC-AU-N71 | Negative | Ctrl | Soft-deleted id → 404 (no withTrashed in show) | 404 | test_author_71 | Automated |

### Screen 5: Edit (GET /syllabus-books/authors/{author}/edit)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P80 | Positive | View | Edit page pre-fills with existing values for all fields | Pre-filled | test_author_80 | Automated |
| TC-AU-P81 | Positive | View | Status switch reflects current is_active value | Correct toggle | test_author_81 | Automated |
| TC-AU-N82 | Negative | Ctrl | Invalid id → 404 | 404 | test_author_82 | Automated |

### Screen 6: Update (PUT /syllabus-books/authors/{author})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P90 | Positive | Ctrl | Update modifies record and logs 'Updated' activity | Updated + log | test_author_90 | Automated |
| TC-AU-P91 | Positive | Ctrl | Update changes is_active from 1 to 0 | Inactivated | test_author_91 | Automated |
| TC-AU-P92 | Positive | Ctrl | Update can clear qualification to NULL | qualification=NULL | test_author_92 | Automated |
| TC-AU-P93 | Positive | Ctrl | Update redirects to syllabus-books.index?tab=author with success flash | Redirect + flash | test_author_93 | Automated |
| TC-AU-N94 | Negative | Ctrl | Duplicate name on update (change to existing name) → caught as 23000, redirect back with error | Error flash | test_author_94 | Automated |
| TC-AU-N95 | Negative | Ctrl | name empty on update → rejected | 422 | test_author_95 | Automated |

### Screen 7: Destroy (DELETE /syllabus-books/authors/{author})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P100 | Positive | Ctrl | Destroy soft-deletes and sets is_active=false | Soft-deleted + inactive | test_author_100 | Automated |
| TC-AU-P101 | Positive | Ctrl | Destroy logs 'Trashed' activity activity | Log entry | test_author_101 | Automated |
| TC-AU-P102 | Positive | Ctrl | Destroy redirects to syllabus-books.index with success flash | Redirect + flash | test_author_102 | Automated |
| TC-AU-N103 | Negative | Ctrl | Destroy on non-existing id → 404 | 404 | test_author_103 | Automated |

### Screen 8: Trash (GET /syllabus-books/authors/trash/view)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P110 | Positive | View | Trash page lists soft-deleted authors | Listed | test_author_110 | Automated |
| TC-AU-P111 | Positive | View | Each trashed row has Restore and Force Delete action buttons | 2 buttons | test_author_111 | Automated |
| TC-AU-P112 | Positive | View | Trash page is paginated (10 per page) | Paginated | test_author_112 | Planned |

### Screen 9: Restore (GET /syllabus-books/authors/{id}/restore)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P120 | Positive | Ctrl | Restore recovers record (deleted_at=NULL), logs 'Restored' activity | Restored + log | test_author_120 | Automated |
| TC-AU-P121 | Positive | Ctrl | Restore redirects to trashed view with success flash | Redirect + flash | test_author_121 | Automated |
| TC-AU-N122 | Negative | Ctrl | Restore on non-trashed/non-existing id → 404 | 404 | test_author_122 | Automated |

### Screen 10: Force Delete (DELETE /syllabus-books/authors/{id}/force-delete)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P130 | Positive | Ctrl | Force delete permanently removes author and pivot rows, logs 'Deleted' activity | Deleted + log | test_author_130 | Automated |
| TC-AU-P131 | Positive | Ctrl | Force delete redirects to trashed view with success flash | Redirect + flash | test_author_131 | Automated |
| TC-AU-N132 | Negative | Ctrl | Force delete on non-trashed id → 404 (withTrashed findOrFail) | 404 | test_author_132 | Automated |
| TC-AU-N133 | Negative | Ctrl | Force delete on author with books linked via pivot → 23000 caught, error flash | Error flash | test_author_133 | Planned |

### Screen 11: Toggle Status (POST /syllabus-books/authors/{author}/toggle-status)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P140 | Positive | Ctrl | Toggle active → inactive (is_active flips to false) | is_active=false | test_author_140 | Automated |
| TC-AU-P141 | Positive | Ctrl | Toggle inactive → active (is_active flips to true) | is_active=true | test_author_141 | Automated |
| TC-AU-P142 | Positive | Ctrl | Toggle returns JSON response {success: true, is_active, message} | JSON response | test_author_142 | Automated |
| TC-AU-P143 | Positive | Ctrl | Toggle logs 'Toggled' activity | Log entry | test_author_143 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy, Security

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-AU-P01 | Schema | DDL/Model | Migration, model, table, fillable, casts, SoftDeletes, unique index | All pass | test_author_01 | Automated |
| TC-AU-P02 | Schema | Routes | Resource + extra routes registered | All present | test_author_02 | Automated |
| TC-AU-P03 | Schema | Pivot | slb_book_author_jnt exists with correct FK columns and composite PK | Present | test_author_03 | Planned |
| TC-AU-P05 | Auth | Middleware | Guest redirected to /login | /login | test_author_05 | Automated |
| TC-AU-P06 | Auth | Policy | Policy permission mapping is correct for all 7 gates | Mapped | test_author_06 | Automated |
| TC-AU-P07 | Auth | Ctrl | Controller gate authorization present on all methods | Gates present | test_author_07 | Automated |
| TC-AU-N08 | Auth | Ctrl | User without tenant.author.viewAny → 403 on index | 403 | test_author_08 | Automated |
| TC-AU-N09 | Auth | Ctrl | User without tenant.author.create → 403 on create/store | 403 | test_author_09 | Automated |
| TC-AU-N10 | Auth | Ctrl | User without tenant.author.view → 403 on show | 403 | test_author_10 | Automated |
| TC-AU-N11 | Auth | Ctrl | User without tenant.author.update → 403 on edit/update/toggleStatus | 403 | test_author_11 | Automated |
| TC-AU-N12 | Auth | Ctrl | User without tenant.author.delete → 403 on destroy | 403 | test_author_12 | Automated |
| TC-AU-N13 | Auth | Ctrl | User without tenant.author.restore → 403 on trashed/restore | 403 | test_author_13 | Automated |
| TC-AU-N14 | Auth | Ctrl | User without tenant.author.forceDelete → 403 on forceDelete | 403 | test_author_14 | Automated |
| TC-AU-T90 | Tenancy | Tenant | Author records scoped to current tenant | Scoped | test_author_90 | Automated |
| TC-AU-P91 | Security | View | Stored XSS in name/qualification/bio escaped on render | Escaped | test_author_91 | Automated |

---

## 3. Test Method Index

### File: `slb_Author_TestCas.php` (66 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_author_01_migration_model_and_schema | TC-AU-P01 | Schema | 01-04 |
| 2 | test_author_02_resource_routes_are_registered | TC-AU-P02 | Schema | 01-04 |
| 3 | test_author_03_pivot_table_exists | TC-AU-P03 | Schema | 01-04 |
| 4 | test_author_05_guest_redirected_to_login | TC-AU-P05 | Auth | 05-09 |
| 5 | test_author_06_policy_permission_mapping_is_correct | TC-AU-P06 | Auth | 05-09 |
| 6 | test_author_07_controller_gate_authorization_is_present | TC-AU-P07 | Auth | 05-09 |
| 7 | test_author_08_user_without_viewAny_permission_gets_403 | TC-AU-N08 | Auth | 05-09 |
| 8 | test_author_09_user_without_create_permission_gets_403 | TC-AU-N09 | Auth | 05-09 |
| 9 | test_author_10_user_without_view_permission_gets_403 | TC-AU-N10 | Auth | 05-09 |
| 10 | test_author_11_user_without_update_permission_gets_403 | TC-AU-N11 | Auth | 05-09 |
| 11 | test_author_12_user_without_delete_permission_gets_403 | TC-AU-N12 | Auth | 05-09 |
| 12 | test_author_13_user_without_restore_permission_gets_403 | TC-AU-N13 | Auth | 05-09 |
| 13 | test_author_14_user_without_forceDelete_permission_gets_403 | TC-AU-N14 | Auth | 05-09 |
| 14 | test_author_10_author_tab_renders_with_filters | TC-AU-P10 | List | 10-29 |
| 15 | test_author_11_search_by_name_filters_results | TC-AU-P11 | List | 10-29 |
| 16 | test_author_12_search_by_bio_filters_results | TC-AU-P12 | List | 10-29 |
| 17 | test_author_13_filter_by_qualification_filters_results | TC-AU-P13 | List | 10-29 |
| 18 | test_author_14_filter_by_status_filters_results | TC-AU-P14 | List | 10-29 |
| 19 | test_author_15_combined_filters_work_together | TC-AU-P15 | List | 10-29 |
| 20 | test_author_16_results_are_paginated | TC-AU-P16 | List | 10-29 |
| 21 | test_author_17_table_displays_all_columns | TC-AU-P17 | List | 10-29 |
| 22 | test_author_18_action_buttons_per_row | TC-AU-P18 | List | 10-29 |
| 23 | test_author_19_status_toggle_on_every_row | TC-AU-P19 | List | 10-29 |
| 24 | test_author_20_records_ordered_by_name_asc | TC-AU-P20 | List | 10-29 |
| 25 | test_author_21_books_count_badge_displayed | TC-AU-P21 | List | 10-29 |
| 26 | test_author_22_empty_state_when_no_records | TC-AU-P22 | List | 10-29 |
| 27 | test_author_23_clear_filter_resets | TC-AU-P23 | List | 10-29 |
| 28 | test_author_30_create_page_renders_fields | TC-AU-P30 | Create | 30-39 |
| 29 | test_author_40_store_creates_author | TC-AU-P40 | Store | 40-49 |
| 30 | test_author_41_is_active_defaults_to_true | TC-AU-P41 | Store | 40-49 |
| 31 | test_author_42_is_active_forced_to_0_when_unchecked | TC-AU-P42 | Store | 40-49 |
| 32 | test_author_43_store_logs_created_activity | TC-AU-P43 | Store | 40-49 |
| 33 | test_author_44_store_redirects_with_success | TC-AU-P44 | Store | 40-49 |
| 34 | test_author_45_bio_nullable_saved_as_null | TC-AU-P45 | Store | 40-49 |
| 35 | test_author_46_qualification_nullable_saved_as_null | TC-AU-P46 | Store | 40-49 |
| 36 | test_author_50_name_required_rejected | TC-AU-N50 | Val | 50-59 |
| 37 | test_author_51_name_max_length_enforced | TC-AU-N51 | Val | 50-59 |
| 38 | test_author_52_duplicate_name_rejected | TC-AU-N52 | Val | 50-59 |
| 39 | test_author_53_qualification_max_length_enforced | TC-AU-N53 | Val | 50-59 |
| 40 | test_author_54_is_active_non_boolean_rejected | TC-AU-N54 | Val | 50-59 |
| 41 | test_author_60_show_page_displays_all_fields | TC-AU-P60 | Show | 60-69 |
| 42 | test_author_61_show_shows_dash_for_null_fields | TC-AU-P61 | Show | 60-69 |
| 43 | test_author_62_show_sidebar_has_back_and_edit_buttons | TC-AU-P62 | Show | 60-69 |
| 44 | test_author_70_show_invalid_id_returns_404 | TC-AU-N70 | Show | 60-69 |
| 45 | test_author_71_show_soft_deleted_id_returns_404 | TC-AU-N71 | Show | 60-69 |
| 46 | test_author_80_edit_page_prefills_values | TC-AU-P80 | Edit | 80-89 |
| 47 | test_author_81_edit_status_switch_reflects_current | TC-AU-P81 | Edit | 80-89 |
| 48 | test_author_82_edit_invalid_id_returns_404 | TC-AU-N82 | Edit | 80-89 |
| 49 | test_author_90_update_modifies_and_logs | TC-AU-P90 | Update | 90-99 |
| 50 | test_author_91_update_changes_is_active | TC-AU-P91 | Update | 90-99 |
| 51 | test_author_92_update_clears_qualification_to_null | TC-AU-P92 | Update | 90-99 |
| 52 | test_author_93_update_redirects_with_success | TC-AU-P93 | Update | 90-99 |
| 53 | test_author_94_duplicate_name_on_update_rejected | TC-AU-N94 | Update | 90-99 |
| 54 | test_author_95_name_empty_on_update_rejected | TC-AU-N95 | Update | 90-99 |
| 55 | test_author_100_destroy_soft_deletes_and_deactivates | TC-AU-P100 | Destroy | 100-109 |
| 56 | test_author_101_destroy_logs_trashed_activity | TC-AU-P101 | Destroy | 100-109 |
| 57 | test_author_102_destroy_redirects_with_success | TC-AU-P102 | Destroy | 100-109 |
| 58 | test_author_103_destroy_non_existing_404 | TC-AU-N103 | Destroy | 100-109 |
| 59 | test_author_110_trash_lists_soft_deleted | TC-AU-P110 | Trash | 110-119 |
| 60 | test_author_111_trash_has_restore_and_force_delete_buttons | TC-AU-P111 | Trash | 110-119 |
| 61 | test_author_112_trash_paginated | TC-AU-P112 | Trash | 110-119 |
| 62 | test_author_120_restore_recovers_and_logs | TC-AU-P120 | Restore | 120-129 |
| 63 | test_author_121_restore_redirects_with_success | TC-AU-P121 | Restore | 120-129 |
| 64 | test_author_122_restore_non_trashed_404 | TC-AU-N122 | Restore | 120-129 |
| 65 | test_author_130_force_delete_permanently_removes | TC-AU-P130 | ForceDel | 130-139 |
| 66 | test_author_131_force_delete_redirects_with_success | TC-AU-P131 | ForceDel | 130-139 |
| 67 | test_author_132_force_delete_non_trashed_404 | TC-AU-N132 | ForceDel | 130-139 |
| 68 | test_author_133_force_delete_referenced_author_blocked | TC-AU-N133 | ForceDel | 130-139 |
| 69 | test_author_140_toggle_active_to_inactive | TC-AU-P140 | Toggle | 140-149 |
| 70 | test_author_141_toggle_inactive_to_active | TC-AU-P141 | Toggle | 140-149 |
| 71 | test_author_142_toggle_returns_json_response | TC-AU-P142 | Toggle | 140-149 |
| 72 | test_author_143_toggle_logs_activity | TC-AU-P143 | Toggle | 140-149 |
| 73 | test_author_90_records_are_tenant_scoped | TC-AU-T90 | Tenancy | 90-99 |
| 74 | test_author_91_stored_xss_is_escaped_on_render | TC-AU-P91 | Security | 90-99 |

**Total: 74 methods (71 Automated, 3 Planned).**
