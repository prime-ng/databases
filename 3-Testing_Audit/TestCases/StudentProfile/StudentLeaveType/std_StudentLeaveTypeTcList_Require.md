# Student Leave Type — Test Case List & Business Conditions

**Module:** StudentProfile (`std_`) · **Feature/Screen:** StudentLeaveType (`std_leave_types`)
**DB scope:** TENANT-side · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Test file:** `std_StudentLeaveType_TestCas.php` (single comprehensive suite — no V1/V2)
**Primary requirement source:** `4-Requirement_Module_wise/2-Module_Requirement_V1/StudentProfile_v2/BRD-05_Student_Leave_Management.md`
**Audit:** `3-Audit_Reports/V1_Jun-2026/StudentProfile_Complete_Audit_2026-06-30.md`

---

## 1. Business Conditions

### BC-DB (schema — DDL `std_leave_types` v1.6 + migration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `std_leave_types` exists with columns id, code, name, description, max_days_per_application, max_days_per_year, requires_document, allow_half_day, advance_notice_days, is_active, created_by, timestamps, deleted_at | DDL-std_leave_types |
| BC-DB-02 | `code` VARCHAR(30) NOT NULL | DDL-std_leave_types |
| BC-DB-03 | `name` VARCHAR(100) NOT NULL | DDL-std_leave_types |
| BC-DB-04 | `description` VARCHAR(255) NULL | DDL-std_leave_types |
| BC-DB-05 | `max_days_per_application` TINYINT UNSIGNED NOT NULL DEFAULT 30 (0–255) | DDL-std_leave_types |
| BC-DB-06 | `max_days_per_year` SMALLINT UNSIGNED NOT NULL DEFAULT 0 (0–65535) | DDL-std_leave_types |
| BC-DB-07 | `advance_notice_days` TINYINT UNSIGNED NOT NULL DEFAULT 0 (0–255) | DDL-std_leave_types |
| BC-DB-08 | `requires_document`, `allow_half_day`, `is_active` TINYINT(1) (boolean cast) | DDL-std_leave_types |
| BC-DB-09 | UNIQUE `uq_leave_type_code` on (`code`,`deleted_at`) — code reusable after soft-delete | DDL-std_leave_types |
| BC-DB-10 | INDEX `idx_leave_type_active` on `is_active` | DDL-std_leave_types |
| BC-DB-11 | Model uses `SoftDeletes`; table `std_leave_types`; fillable/casts as declared | Model-LeaveType |

### BC-VAL (validation — `StudentLeaveTypeRequest`)
| ID | Rule | Message/behaviour | Source |
|----|------|-------------------|--------|
| BC-VAL-01 | `code` required, string, max:30, unique(std_leave_types,code) whereNull deleted_at ignore(id) | Reject blank / >30 / active-duplicate | Screen-VR / Request |
| BC-VAL-02 | `name` required, string, max:100 | Reject blank / >100 | Request |
| BC-VAL-03 | `description` nullable, string, max:255 | Reject >255 | Request |
| BC-VAL-04 | `max_days_per_application` required, integer, min:0, max:255 | Reject <0 / >255 | Request |
| BC-VAL-05 | `max_days_per_year` required, integer, min:0, max:65535 | Reject <0 / >65535 | Request |
| BC-VAL-06 | `advance_notice_days` required, integer, min:0, max:255 | Reject <0 / >255 | Request |
| BC-VAL-07 | `is_active` required, boolean | | Request |
| BC-VAL-08 | `prepareForValidation` defaults: mdpa=30, mdpy=0, notice=0, requires_document=false, allow_half_day=true, is_active=true; checkbox→boolean coercion | Request |

### BC-AUTH (authorization — `LeaveTypePolicy` + controller `Gate::authorize`)
| ID | Ability → permission | Source |
|----|----------------------|--------|
| BC-AUTH-01 | create/store → `tenant.leave-type.create` | Controller/Policy |
| BC-AUTH-02 | show → `tenant.leave-type.view` | Controller/Policy |
| BC-AUTH-03 | edit/update/toggleStatus → `tenant.leave-type.update` | Controller/Policy |
| BC-AUTH-04 | destroy → `tenant.leave-type.delete` | Controller/Policy |
| BC-AUTH-05 | trashed/restore → `tenant.leave-type.restore` | Controller/Policy |
| BC-AUTH-06 | forceDelete → `tenant.leave-type.forceDelete` | Controller/Policy |
| BC-AUTH-07 | viewAny → `tenant.leave-type.viewAny` (policy defined; **index() gate commented out** — see DEV-STD-LT-01) | Policy |
| BC-AUTH-08 | Guest is redirected to `/login` | Auth middleware |

### BC-BIZ (business logic / activity log — Controller + `LeaveService`)
| ID | Behaviour | Source |
|----|-----------|--------|
| BC-BIZ-01 | `index()` redirects to `student-profile.student-leave.index?tab=leave-type` (query preserved) | Controller |
| BC-BIZ-02 | store → `LeaveService::createLeaveType`; `created_by` defaults to `auth()->id()` if absent | Service |
| BC-BIZ-03 | store logs event **`Created`**; success toast "Student leave type created successfully" | Controller |
| BC-BIZ-04 | update logs event **`Updated`**; toast "…updated successfully" | Controller |
| BC-BIZ-05 | destroy sets `is_active=false` then soft-deletes; logs **`Deleted`** | Service/Controller |
| BC-BIZ-06 | restore recovers row; logs **`Restored`** | Controller |
| BC-BIZ-07 | forceDelete permanently removes; logs **`Force Deleted`** | Controller |
| BC-BIZ-08 | getLeaveTypes search on code/name/description; status filter on is_active | Service |
| BC-BIZ-09 | Activity sink = tenant `activity_logs` (`Modules\GlobalMaster\Models\ActivityLog`) | Helper (constraint #25) |

### BC-SM (state machine — is_active toggle)
| ID | State → Trigger → Next | Source |
|----|------------------------|--------|
| BC-SM-01 | active → toggleStatus → inactive; JSON `{success,is_active,message:"Status updated successfully"}`; event **`Toggled`** | Controller |
| BC-SM-02 | inactive → toggleStatus → active | Controller/Service |

### BC-REF / BC-INT (referential integrity)
| ID | FK / integration | Source |
|----|------------------|--------|
| BC-REF-01 | `std_leave_applications.leave_type_id` → `std_leave_types.id` ON DELETE **RESTRICT** (force-delete blocked while referenced) | DDL |
| BC-REF-02 | `created_by` → sys_users (nullable) | DDL / Model createdBy() |
| BC-INT-01 | `leaveApplications()` hasMany LeaveApplication via leave_type_id | Model |

### BC-EDG
| ID | Edge | Source |
|----|------|--------|
| BC-EDG-01 | code reusable after soft-delete (composite unique) | DDL |
| BC-EDG-02 | boundary maxima (255/65535/255) accepted | DDL/Request |
| BC-EDG-03 | unknown id on show/edit → 404 | Route-model / findOrFail |
| BC-EDG-04 | stored XSS in name rendered escaped by Blade | Output security |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-* | DDL | Schema/model/request config truth | All asserts pass | `_01_migration_model_and_request_configuration_are_correct` | Automated |
| TC-P02 | BC-DB | Routes | Resource + extra routes registered | 11 route names exist | `_02_resource_routes_are_registered` | Automated |
| TC-P10 | BC-BIZ-01 | Controller | index redirects to leave-type tab | lands on student-leave | `_10_index_redirects_to_leave_tab` | Automated |
| TC-P11 | BC-BIZ-02 | Service | store creates row | row persisted | `_11_store_creates_leave_type` | Automated |
| TC-P12 | BC-BIZ-02 | Service | created_by auto-set | created_by not null | `_12_created_by_defaults_to_current_user` | Automated |
| TC-P13 | BC-BIZ-03 | Controller | store logs Created | activity_logs row | `_13_store_writes_activity_log_created` | Automated |
| TC-P14 | BC-BIZ-04 | Controller | update logs Updated | name changed + log | `_14_update_modifies_and_logs_updated` | Automated |
| TC-P15 | BC-BIZ-05 | Service | destroy soft-deletes + deactivates | trashed, is_active=0, Deleted log | `_15_destroy_soft_deletes_and_deactivates` | Automated |
| TC-P16 | BC-BIZ-06 | Controller | restore recovers + logs | not trashed, Restored log | `_16_restore_recovers_and_logs` | Automated |
| TC-P17 | BC-BIZ-07 | Controller | force delete + logs | gone, Force Deleted log | `_17_force_delete_permanently_removes_and_logs` | Automated |
| TC-P18 | BC-VAL-08 | Request | defaults applied | mdpa=30, half_day=1, active=1 | `_18_prepare_for_validation_defaults_applied` | Automated |
| TC-P60 | BC-BIZ-08 | View | tab lists existing type | code visible | `_60_index_tab_lists_existing_type` | Automated |
| TC-P61 | — | View | create page fields render | inputs present | `_61_create_page_renders_fields` | Automated |
| TC-P62 | — | View | edit page prefills | code/name prefilled | `_62_edit_page_prefills_values` | Automated |
| TC-P63 | — | View | show page details | code/name visible | `_63_show_page_displays_details` | Automated |
| TC-P64 | BC-BIZ | View | trash page lists deleted | code visible | `_64_trash_page_lists_deleted` | Automated |
| TC-P65 | BC-BIZ-08 | Service | search filters listing | matching code visible | `_65_search_filters_listing` | Automated |
| TC-S20 | BC-SM-01 | Controller | toggle active→inactive JSON | is_active=0 + JSON + Toggled | `_20_toggle_active_to_inactive` | Automated |
| TC-S21 | BC-SM-02 | Controller | toggle inactive→active | is_active=1 | `_21_toggle_inactive_to_active` | Automated |
| TC-P72 | BC-EDG-02 | DDL | boundary maxima accepted | 255/65535 persisted | `_72_boundary_maxima_accepted` | Automated |
| TC-T90 | BC-DB | Tenancy | tenant-scoped visibility | row visible in tenant | `_90_records_are_tenant_scoped` | Automated |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N30 | BC-VAL-01 | Request | code required | 422/302 | `_30_code_is_required` | Automated |
| TC-N31 | BC-VAL-02 | Request | name required | 422/302 | `_31_name_is_required` | Automated |
| TC-N32 | BC-VAL-01 | Request | duplicate active code | 422/302 | `_32_duplicate_code_rejected` | Automated |
| TC-N33 | BC-VAL-01 | Request | code >30 | 422/302 | `_33_code_max_length_enforced` | Automated |
| TC-N34 | BC-VAL-02 | Request | name >100 | 422/302 | `_34_name_max_length_enforced` | Automated |
| TC-N35 | BC-VAL-03 | Request | description >255 | 422/302 | `_35_description_max_length_enforced` | Automated |
| TC-N36 | BC-VAL-04 | Request | mdpa >255 | 422/302 | `_36_max_days_per_application_range_enforced` | Automated |
| TC-N37 | BC-VAL-05 | Request | mdpy >65535 | 422/302 | `_37_max_days_per_year_range_enforced` | Automated |
| TC-N38 | BC-VAL-06 | Request | notice >255 | 422/302 | `_38_advance_notice_days_range_enforced` | Automated |
| TC-N39 | BC-VAL-04/05 | Request | negative numeric | 422/302 | `_39_negative_numeric_rejected` | Automated |
| TC-N50 | BC-AUTH-08 | Auth | guest → login | redirect /login | `_50_guest_redirected_to_login` | Automated |
| TC-N70 | BC-EDG-03 | Route | show unknown id | 404 | `_70_show_invalid_id_returns_404` | Automated |
| TC-N71 | BC-EDG-03 | Route | edit unknown id | 404 | `_71_edit_invalid_id_returns_404` | Automated |
| TC-S92 | BC-VAL / SEC | Security | created_by not spoofable | created_by ≠ attacker value | `_92_created_by_not_spoofable_via_request` | Automated |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D40 | G | BC-EDG-01 | DDL | code reuse after soft-delete | new row created | `_40_code_reusable_after_soft_delete` | Automated |
| TC-D41 | C | BC-REF-01 | DDL | force-delete blocked by RESTRICT | blocked / skip | `_41_force_delete_restricted_when_referenced` | Automated (defensive) |
| TC-D42 | — | BC-INT-01 | Model | leaveApplications relation | HasMany, FK leave_type_id | `_42_leave_applications_relationship` | Automated |
| TC-D15 | B | BC-BIZ-05 | Service | soft-delete preservation | withTrashed recoverable | (covered by `_15`,`_16`) | Automated |

### Authorization (TC-AUTH / config)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-AUTH51 | BC-AUTH-01..07 | Policy | policy→permission mapping correct | 7 keys present | `_51_policy_permission_mapping_is_correct` | Automated |
| TC-AUTH52 | BC-AUTH-01..06 | Controller | Gate::authorize present per action | 6 gate strings present | `_52_controller_gate_authorization_is_present` | Automated |
| TC-AUTH53 | BC-AUTH-01 | Auth | limited user denied create | blocked / skip | `_53_limited_user_denied_create` | Automated (defensive) |

### Security (TC-S)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S91 | BC-EDG-04 | Output | stored XSS escaped on render | no raw `<script>` | `_91_stored_xss_is_escaped_on_render` | Automated |

### Known Source Defects (audit-equivalent)
| ID | Description | Severity | Proving test / note |
|----|-------------|----------|---------------------|
| DEV-STD-LT-01 | `StudentLeaveTypeController::index()` has its `Gate::authorize('prime.department.viewAny')` **commented out** AND the string uses the wrong prefix (`prime.department.*` not `tenant.leave-type.viewAny`). `viewAny` is therefore unenforced on the resource index route (mitigated: index only redirects to the tab list rendered by `StdLeaveController`). | P3 (low) | Documented; `_51` proves the Policy defines the correct `viewAny` key that the index route fails to call. |

> Note on GAP-STD-08 (audit "5 missing policies"): **LeaveTypePolicy EXISTS** and maps all abilities to `tenant.leave-type.*` (verified in `_51`). GAP-STD-08 does **not** apply to this feature.

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `_01_migration_model_and_request_configuration_are_correct` | TC-P01 | Schema | 01–09 |
| 2 | `_02_resource_routes_are_registered` | TC-P02 | Schema | 01–09 |
| 3 | `_10_index_redirects_to_leave_tab` | TC-P10 | Business | 10–19 |
| 4 | `_11_store_creates_leave_type` | TC-P11 | Business | 10–19 |
| 5 | `_12_created_by_defaults_to_current_user` | TC-P12 | Business | 10–19 |
| 6 | `_13_store_writes_activity_log_created` | TC-P13 | Business | 10–19 |
| 7 | `_14_update_modifies_and_logs_updated` | TC-P14 | Business | 10–19 |
| 8 | `_15_destroy_soft_deletes_and_deactivates` | TC-P15 / TC-D15 | Business/Dep | 10–19 |
| 9 | `_16_restore_recovers_and_logs` | TC-P16 | Business | 10–19 |
| 10 | `_17_force_delete_permanently_removes_and_logs` | TC-P17 | Business | 10–19 |
| 11 | `_18_prepare_for_validation_defaults_applied` | TC-P18 | Business | 10–19 |
| 12 | `_20_toggle_active_to_inactive` | TC-S20 | State machine | 20–29 |
| 13 | `_21_toggle_inactive_to_active` | TC-S21 | State machine | 20–29 |
| 14 | `_30_code_is_required` | TC-N30 | Validation | 30–39 |
| 15 | `_31_name_is_required` | TC-N31 | Validation | 30–39 |
| 16 | `_32_duplicate_code_rejected` | TC-N32 | Validation | 30–39 |
| 17 | `_33_code_max_length_enforced` | TC-N33 | Validation | 30–39 |
| 18 | `_34_name_max_length_enforced` | TC-N34 | Validation | 30–39 |
| 19 | `_35_description_max_length_enforced` | TC-N35 | Validation | 30–39 |
| 20 | `_36_max_days_per_application_range_enforced` | TC-N36 | Validation | 30–39 |
| 21 | `_37_max_days_per_year_range_enforced` | TC-N37 | Validation | 30–39 |
| 22 | `_38_advance_notice_days_range_enforced` | TC-N38 | Validation | 30–39 |
| 23 | `_39_negative_numeric_rejected` | TC-N39 | Validation | 30–39 |
| 24 | `_40_code_reusable_after_soft_delete` | TC-D40 | Dependency | 40–49 |
| 25 | `_41_force_delete_restricted_when_referenced` | TC-D41 | Dependency | 40–49 |
| 26 | `_42_leave_applications_relationship` | TC-D42 | Dependency | 40–49 |
| 27 | `_50_guest_redirected_to_login` | TC-N50 | Permissions | 50–59 |
| 28 | `_51_policy_permission_mapping_is_correct` | TC-AUTH51 | Permissions | 50–59 |
| 29 | `_52_controller_gate_authorization_is_present` | TC-AUTH52 | Permissions | 50–59 |
| 30 | `_53_limited_user_denied_create` | TC-AUTH53 | Permissions | 50–59 |
| 31 | `_60_index_tab_lists_existing_type` | TC-P60 | UI/UX | 60–69 |
| 32 | `_61_create_page_renders_fields` | TC-P61 | UI/UX | 60–69 |
| 33 | `_62_edit_page_prefills_values` | TC-P62 | UI/UX | 60–69 |
| 34 | `_63_show_page_displays_details` | TC-P63 | UI/UX | 60–69 |
| 35 | `_64_trash_page_lists_deleted` | TC-P64 | UI/UX | 60–69 |
| 36 | `_65_search_filters_listing` | TC-P65 | UI/UX | 60–69 |
| 37 | `_70_show_invalid_id_returns_404` | TC-N70 | Edge | 70–79 |
| 38 | `_71_edit_invalid_id_returns_404` | TC-N71 | Edge | 70–79 |
| 39 | `_72_boundary_maxima_accepted` | TC-P72 | Edge | 70–79 |
| 40 | `_90_records_are_tenant_scoped` | TC-T90 | Tenancy | 90–99 |
| 41 | `_91_stored_xss_is_escaped_on_render` | TC-S91 | Security | 90–99 |
| 42 | `_92_created_by_not_spoofable_via_request` | TC-S92 | Security | 90–99 |

**Total: 42 test methods.**
