# std_LeaveType — Test Case List & Business Conditions

**Module:** StudentProfile (CODE `STD`, prefix `std_`) · **Feature:** Leave Type Master (CRUD + Trash + Toggle Status)
**DB scope:** TENANT-side (`std_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `std_leave_types` · **Module URL prefix:** `/student-profile`
**Test file:** `std_StudentLeaveType_TestCas.php`
**Checklists applied:** `Gaurav_list.md` + `Shailesh_list.md`

Routes:
- `GET     /student-profile/student-leave-types` — StudentLeaveTypeController@index (redirects to leave tab)
- `GET     /student-profile/student-leave-types/create` — StudentLeaveTypeController@create
- `POST    /student-profile/student-leave-types` — StudentLeaveTypeController@store
- `GET     /student-profile/student-leave-types/{student_leave_type}` — StudentLeaveTypeController@show
- `GET     /student-profile/student-leave-types/{student_leave_type}/edit` — StudentLeaveTypeController@edit
- `PUT     /student-profile/student-leave-types/{student_leave_type}` — StudentLeaveTypeController@update
- `DELETE  /student-profile/student-leave-types/{student_leave_type}` — StudentLeaveTypeController@destroy
- `GET     /student-profile/student-leave-types/trash` — StudentLeaveTypeController@trashed
- `GET     /student-profile/student-leave-types/{id}/restore` — StudentLeaveTypeController@restore
- `DELETE  /student-profile/student-leave-types/{id}/force-delete` — StudentLeaveTypeController@forceDelete
- `POST    /student-profile/student-leave-types/{studentLeaveType}/toggle-status` — StudentLeaveTypeController@toggleStatus

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `std_leave_types` exists with columns: id, code, name, description, max_days_per_application, max_days_per_year, requires_document, allow_half_day, advance_notice_days, is_active, created_by, deleted_at, created_at, updated_at | DDL |
| BC-DB-02 | Model `LeaveType`: table `std_leave_types`, SoftDeletes, fillable includes 10 fields | LeaveType.php:12-29 |
| BC-DB-03 | Casts: requires_document, allow_half_day, is_active (boolean); max_days_per_application, max_days_per_year, advance_notice_days (integer) | LeaveType.php:31-38 |
| BC-DB-04 | Relationships: leaveApplications (hasMany), createdBy (belongsTo User) | LeaveType.php:48-56 |

### BC-VAL — Validation (Source: `StudentLeaveTypeRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `code` required string max:30 unique:std_leave_types (ignore soft-deleted, ignore self on update) | Request:26-33 |
| BC-VAL-02 | `name` required string max:100 | Request:34 |
| BC-VAL-03 | `description` nullable string max:255 | Request:35 |
| BC-VAL-04 | `max_days_per_application` required integer min:0 max:255 (default 30) | Request:36,66 |
| BC-VAL-05 | `max_days_per_year` required integer min:0 max:65535 (default 0) | Request:37,67 |
| BC-VAL-06 | `requires_document` nullable boolean (default false) | Request:38,69 |
| BC-VAL-07 | `allow_half_day` nullable boolean (default true) | Request:39,70 |
| BC-VAL-08 | `advance_notice_days` required integer min:0 max:255 (default 0) | Request:40,68 |
| BC-VAL-09 | `is_active` required boolean (default true) | Request:41,71 |
| BC-VAL-10 | `code` unique rule uses `whereNull('deleted_at')` — soft-deleted codes are reusable | Request:30-32 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | create()/store() gate `tenant.leave-type.create` | Ctrl:36,46 |
| BC-AUTH-02 | show() gate `tenant.leave-type.view` | Ctrl:62 |
| BC-AUTH-03 | edit()/update() gate `tenant.leave-type.update` | Ctrl:74,86 |
| BC-AUTH-04 | destroy() gate `tenant.leave-type.delete` | Ctrl:115 |
| BC-AUTH-05 | trashed()/restore() gate `tenant.leave-type.restore` | Ctrl:103,132 |
| BC-AUTH-06 | forceDelete() gate `tenant.leave-type.forceDelete` | Ctrl:148 |
| BC-AUTH-07 | toggleStatus() gate `tenant.leave-type.update` | Ctrl:165 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index() redirects to `student-profile.student-leave.index` with `tab=leave-type` | Ctrl:25-28 |
| BC-BIZ-02 | store() uses LeaveService::createLeaveType(), logs 'Created' activity | Ctrl:48-50 |
| BC-BIZ-03 | update() uses LeaveService::updateLeaveType(), logs 'Updated' activity | Ctrl:88-91 |
| BC-BIZ-04 | destroy() soft-deletes, logs 'Deleted' activity | Ctrl:117-120 |
| BC-BIZ-05 | restore() recovers soft-deleted record, logs 'Restored' | Ctrl:134-136 |
| BC-BIZ-06 | forceDelete() permanently removes, logs 'Force Deleted' | Ctrl:150-153 |
| BC-BIZ-07 | toggleStatus() toggles is_active, logs 'Toggled', returns JSON | Ctrl:167-175 |
| BC-BIZ-08 | prepareForValidation sets defaults for max_days_per_application (30), max_days_per_year (0), advance_notice_days (0), requires_document (false), allow_half_day (true), is_active (true) | Request:63-72 |
| BC-BIZ-09 | All redirects go to `student-leave.index?tab=leave-type` with success flash | Ctrl:52-54,93-95,122-124,139-141,156-158 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing id for show/edit/update/destroy/restore → 404 (findOrFail / service throws) | Ctrl |
| BC-EDG-02 | Force-delete on non-trashed record → 404 (service: onlyTrashed findOrFail) | Ctrl:149 |
| BC-EDG-03 | Soft-deleted code can be reused for a new leave type (unique ignores deleted_at) | Request:30-32 |
| BC-EDG-04 | Leave type referenced by leave applications cannot be force-deleted | test_41 |

---

## 2. Test Case List

### Screen 1: Index (GET /student-leave-types)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P10 | Positive | Ctrl | Index redirects to leave tab with `tab=leave-type` | Redirect | test_leave_type_10 | Automated |
| TC-LT-P60 | Positive | View | Index tab lists existing leave types | Listed | test_leave_type_60 | Automated |
| TC-LT-P65 | Positive | View | Search/filter works on the leave type listing | Filtered | test_leave_type_65 | Automated |

### Screen 2: Create Form (GET /student-leave-types/create)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P61 | Positive | View | Create page renders all form fields | Fields rendered | test_leave_type_61 | Automated |

### Screen 3: Store (POST /student-leave-types)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P11 | Positive | Ctrl | Valid store creates leave type with all fields | Row created | test_leave_type_11 | Automated |
| TC-LT-P12 | Positive | Ctrl | created_by defaults to current authenticated user | Set to current user | test_leave_type_12 | Automated |
| TC-LT-P13 | Positive | Ctrl | Store writes 'Created' activity log | Log entry | test_leave_type_13 | Automated |
| TC-LT-P18 | Positive | Ctrl | prepareForValidation defaults applied when fields omitted | Defaults saved | test_leave_type_18 | Automated |
| TC-LT-N30 | Negative | Ctrl | code required → rejected | 422 | test_leave_type_30 | Automated |
| TC-LT-N31 | Negative | Ctrl | name required → rejected | 422 | test_leave_type_31 | Automated |
| TC-LT-N32 | Negative | Ctrl | Duplicate code (non-deleted) → rejected | 422 | test_leave_type_32 | Automated |
| TC-LT-N33 | Negative | Ctrl | code exceeds 30 chars → rejected | 422 | test_leave_type_33 | Automated |
| TC-LT-N34 | Negative | Ctrl | name exceeds 100 chars → rejected | 422 | test_leave_type_34 | Automated |
| TC-LT-N35 | Negative | Ctrl | description exceeds 255 chars → rejected | 422 | test_leave_type_35 | Automated |
| TC-LT-N36 | Negative | Ctrl | max_days_per_application out of 0-255 range → rejected | 422 | test_leave_type_36 | Automated |
| TC-LT-N37 | Negative | Ctrl | max_days_per_year out of 0-65535 range → rejected | 422 | test_leave_type_37 | Automated |
| TC-LT-N38 | Negative | Ctrl | advance_notice_days out of 0-255 range → rejected | 422 | test_leave_type_38 | Automated |
| TC-LT-N39 | Negative | Ctrl | Negative numeric values for integer fields → rejected | 422 | test_leave_type_39 | Automated |
| TC-LT-P72 | Positive | Ctrl | Boundary maximum values accepted (max_days_per_application=255, max_days_per_year=65535, advance_notice_days=255) | Accepted | test_leave_type_72 | Automated |

### Screen 4: Show (GET /student-leave-types/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P63 | Positive | View | Show page displays leave type details | All fields shown | test_leave_type_63 | Automated |
| TC-LT-N70 | Negative | Ctrl | Invalid id → 404 | 404 | test_leave_type_70 | Automated |

### Screen 5: Edit (GET /student-leave-types/{id}/edit)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P62 | Positive | View | Edit page pre-fills with existing values | Pre-filled | test_leave_type_62 | Automated |
| TC-LT-N71 | Negative | Ctrl | Invalid id → 404 | 404 | test_leave_type_71 | Automated |

### Screen 6: Update (PUT /student-leave-types/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P14 | Positive | Ctrl | Update modifies record and logs 'Updated' activity | Updated + log | test_leave_type_14 | Automated |

### Screen 7: Destroy (DELETE /student-leave-types/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P15 | Positive | Ctrl | Destroy soft-deletes and deactivates | Soft-deleted | test_leave_type_15 | Automated |

### Screen 8: Trash (GET /student-leave-types/trash)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P64 | Positive | View | Trash page lists soft-deleted leave types | Listed | test_leave_type_64 | Automated |

### Screen 9: Restore (GET /student-leave-types/{id}/restore)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P16 | Positive | Ctrl | Restore recovers record and logs 'Restored' | Restored + log | test_leave_type_16 | Automated |

### Screen 10: Force Delete (DELETE /student-leave-types/{id}/force-delete)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P17 | Positive | Ctrl | Force delete permanently removes and logs 'Force Deleted' | Deleted + log | test_leave_type_17 | Automated |
| TC-LT-N41 | Negative | Ctrl | Force delete restricted when leave type is referenced by applications | Blocked | test_leave_type_41 | Automated |

### Screen 11: Toggle Status (POST /student-leave-types/{id}/toggle-status)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P20 | Positive | Ctrl | Toggle active → inactive | is_active=false | test_leave_type_20 | Automated |
| TC-LT-P21 | Positive | Ctrl | Toggle inactive → active | is_active=true | test_leave_type_21 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy, Security

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-LT-P01 | Schema | DDL/Model | Migration, model, table, fillable, casts, SoftDeletes, request file | All pass | test_leave_type_01 | Automated |
| TC-LT-P02 | Schema | Routes | Resource routes registered | All present | test_leave_type_02 | Automated |
| TC-LT-P40 | Integrity | Ctrl | Soft-deleted code reusable for new leave type | Reusable | test_leave_type_40 | Automated |
| TC-LT-D42 | Integrity | Model | Leave applications relationship exists | HasMany | test_leave_type_42 | Automated |
| TC-LT-P50 | Auth | Middleware | Guest redirected to /login | /login | test_leave_type_50 | Automated |
| TC-LT-P51 | Auth | Policy | Policy permission mapping is correct | Mapped | test_leave_type_51 | Automated |
| TC-LT-P52 | Auth | Ctrl | Controller gate authorization present on all methods | Gates present | test_leave_type_52 | Automated |
| TC-LT-N53 | Auth | Ctrl | Limited user denied create (403) | 403 | test_leave_type_53 | Automated |
| TC-LT-T90 | Tenancy | Tenant | Leave type records scoped to current tenant | Scoped | test_leave_type_90 | Automated |
| TC-LT-P91 | Security | View | Stored XSS in name/description escaped on render | Escaped | test_leave_type_91 | Automated |
| TC-LT-P92 | Security | Ctrl | created_by not spoofable via request body | Ignored | test_leave_type_92 | Automated |

---

## 3. Test Method Index

### File: `std_StudentLeaveType_TestCas.php` (42 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_leave_type_01_migration_model_and_request_configuration_are_correct | TC-LT-P01 | Schema | 01-09 |
| 2 | test_leave_type_02_resource_routes_are_registered | TC-LT-P02 | Schema | 01-09 |
| 3 | test_leave_type_10_index_redirects_to_leave_tab | TC-LT-P10 | Biz | 10-19 |
| 4 | test_leave_type_11_store_creates_leave_type | TC-LT-P11 | Biz | 10-19 |
| 5 | test_leave_type_12_created_by_defaults_to_current_user | TC-LT-P12 | Biz | 10-19 |
| 6 | test_leave_type_13_store_writes_activity_log_created | TC-LT-P13 | Biz | 10-19 |
| 7 | test_leave_type_14_update_modifies_and_logs_updated | TC-LT-P14 | Biz | 10-19 |
| 8 | test_leave_type_15_destroy_soft_deletes_and_deactivates | TC-LT-P15 | Biz | 10-19 |
| 9 | test_leave_type_16_restore_recovers_and_logs | TC-LT-P16 | Biz | 10-19 |
| 10 | test_leave_type_17_force_delete_permanently_removes_and_logs | TC-LT-P17 | Biz | 10-19 |
| 11 | test_leave_type_18_prepare_for_validation_defaults_applied | TC-LT-P18 | Biz | 10-19 |
| 12 | test_leave_type_20_toggle_active_to_inactive | TC-LT-P20 | Toggle | 20-29 |
| 13 | test_leave_type_21_toggle_inactive_to_active | TC-LT-P21 | Toggle | 20-29 |
| 14 | test_leave_type_30_code_is_required | TC-LT-N30 | Val | 30-39 |
| 15 | test_leave_type_31_name_is_required | TC-LT-N31 | Val | 30-39 |
| 16 | test_leave_type_32_duplicate_code_rejected | TC-LT-N32 | Val | 30-39 |
| 17 | test_leave_type_33_code_max_length_enforced | TC-LT-N33 | Val | 30-39 |
| 18 | test_leave_type_34_name_max_length_enforced | TC-LT-N34 | Val | 30-39 |
| 19 | test_leave_type_35_description_max_length_enforced | TC-LT-N35 | Val | 30-39 |
| 20 | test_leave_type_36_max_days_per_application_range_enforced | TC-LT-N36 | Val | 30-39 |
| 21 | test_leave_type_37_max_days_per_year_range_enforced | TC-LT-N37 | Val | 30-39 |
| 22 | test_leave_type_38_advance_notice_days_range_enforced | TC-LT-N38 | Val | 30-39 |
| 23 | test_leave_type_39_negative_numeric_rejected | TC-LT-N39 | Val | 30-39 |
| 24 | test_leave_type_40_code_reusable_after_soft_delete | TC-LT-P40 | FK | 40-49 |
| 25 | test_leave_type_41_force_delete_restricted_when_referenced | TC-LT-N41 | FK | 40-49 |
| 26 | test_leave_type_42_leave_applications_relationship | TC-LT-D42 | FK | 40-49 |
| 27 | test_leave_type_50_guest_redirected_to_login | TC-LT-P50 | Auth | 50-59 |
| 28 | test_leave_type_51_policy_permission_mapping_is_correct | TC-LT-P51 | Auth | 50-59 |
| 29 | test_leave_type_52_controller_gate_authorization_is_present | TC-LT-P52 | Auth | 50-59 |
| 30 | test_leave_type_53_limited_user_denied_create | TC-LT-N53 | Auth | 50-59 |
| 31 | test_leave_type_60_index_tab_lists_existing_type | TC-LT-P60 | UI | 60-69 |
| 32 | test_leave_type_61_create_page_renders_fields | TC-LT-P61 | UI | 60-69 |
| 33 | test_leave_type_62_edit_page_prefills_values | TC-LT-P62 | UI | 60-69 |
| 34 | test_leave_type_63_show_page_displays_details | TC-LT-P63 | UI | 60-69 |
| 35 | test_leave_type_64_trash_page_lists_deleted | TC-LT-P64 | UI | 60-69 |
| 36 | test_leave_type_65_search_filters_listing | TC-LT-P65 | UI | 60-69 |
| 37 | test_leave_type_70_show_invalid_id_returns_404 | TC-LT-N70 | Edge | 70-79 |
| 38 | test_leave_type_71_edit_invalid_id_returns_404 | TC-LT-N71 | Edge | 70-79 |
| 39 | test_leave_type_72_boundary_maxima_accepted | TC-LT-P72 | Edge | 70-79 |
| 40 | test_leave_type_90_records_are_tenant_scoped | TC-LT-T90 | Tenancy | 90-99 |
| 41 | test_leave_type_91_stored_xss_is_escaped_on_render | TC-LT-P91 | Security | 90-99 |
| 42 | test_leave_type_92_created_by_not_spoofable_via_request | TC-LT-P92 | Security | 90-99 |

**Total: 42 methods (42 Automated, 0 Planned).**
