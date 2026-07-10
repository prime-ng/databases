# std_ Medical Incident — Test Case List & Business Conditions

**Module:** StudentProfile · **Feature/Screen:** MedicalIncident · **Prefix:** `std_` (primary table `std_medical_incidents`)
**DB scope:** TENANT (`std_*`, Database: tenant_db) · **Test style:** Browser Dusk (`extends DuskTestCase`, `Tests\Browser`)
**Controller:** `Modules\StudentProfile\Http\Controllers\MedicalIncidentController` · **Model:** `Modules\StudentProfile\Models\MedicalIncident`
**Policy:** `Modules\StudentProfile\Policies\MedicalIncidentPolicy` (EXISTS) · **URL prefix:** `/student-profile` (name prefix `student-profile.`)
**Test file:** `std_MedicalIncident_TestCas.php` (ONE file, 53 methods) · **Source of truth read:** DDL v1.6, migrations, controller, model, policy, routes/web.php, RouteServiceProvider, all 5 blades.

---

## 1. Business Conditions

### BC-DB (schema) — Source: DDL-std_medical_incidents / create migration
| ID | Fact | Source |
|----|------|--------|
| BC-DB-01 | Table `std_medical_incidents` exists (PK `id` INT UNSIGNED) | DDL-std_medical_incidents |
| BC-DB-02 | Columns: student_id, incident_date, incident_type_id, location, description, first_aid_given, action_taken, reported_by, parent_notified, closure_date, follow_up_required, timestamps, deleted_at | DDL |
| BC-DB-03 | `incident_date` DATETIME NOT NULL; model cast `datetime` | DDL / Model |
| BC-DB-04 | `closure_date` DATE nullable; model cast `date` | DDL / Model |
| BC-DB-05 | `parent_notified` TINYINT(1) DEFAULT 0; cast `boolean` | DDL / Model |
| BC-DB-06 | `follow_up_required` TINYINT(1) DEFAULT 0; cast `boolean` | DDL / Model |
| BC-DB-07 | `location` VARCHAR(100) nullable | DDL |
| BC-DB-08 | `action_taken` VARCHAR(255) nullable | DDL |
| BC-DB-09 | `first_aid_given` TEXT nullable | DDL |
| BC-DB-10 | `deleted_at` exists (SoftDeletes) — create migration `softDeletes()` + follow-up add-column migration | migrations |

### BC-REF (FK / onDelete) — Source: DDL / create migration
| ID | FK | References | onDelete | Source |
|----|-----|-----------|----------|--------|
| BC-REF-01 | `student_id` | `std_students.id` | CASCADE | DDL fk_med_inc_student |
| BC-REF-02 | `reported_by` | `sys_users.id` | SET NULL | DDL fk_med_inc_reporter |
| BC-REF-03 | `incident_type_id` | (no DB FK) validated `exists:sys_dropdown_table,id` | — | Controller rules |

### BC-VAL (validation) — Source: Controller::store / update rules
| ID | Rule | Store | Update | Source |
|----|------|-------|--------|--------|
| BC-VAL-01 | student_id required, exists:std_students,id | ✓ | ✓ | store/update |
| BC-VAL-02 | incident_date required, date | ✓ | ✓ | store/update |
| BC-VAL-03 | incident_type_id required, exists:sys_dropdown_table,id | ✓ | ✓ | store/update |
| BC-VAL-04 | location required, string, max:255 | ✓ | ✓ | store/update |
| BC-VAL-05 | description required, string | ✓ | ✓ | store/update |
| BC-VAL-06 | first_aid_given nullable, string, max:512 | ✓ | ✓ | store/update |
| BC-VAL-07 | action_taken nullable, string, max:512 | ✓ | ✓ | store/update |
| BC-VAL-08 | reported_by required, exists:**sys_users**,id (store) / exists:**users**,id (update) | ✓ | ⚠ | store/update — table mismatch → DEV-MI-03 |
| BC-VAL-09 | parent_notified boolean | ✓ | ✓ | store/update |
| BC-VAL-10 | closure_date nullable, date, after_or_equal:incident_date | ✓ | ✓ | store/update |
| BC-VAL-11 | follow_up_required boolean | ✓ | ✓ | store/update |
| BC-VAL-12 | toggleFollowUp: follow_up_required required|boolean | — | — | Controller::toggleFollowUp |
| BC-VAL-13 | toggleParentNotified: parent_notified required|boolean | — | — | Controller::toggleParentNotified |

### BC-AUTH (gates) — Source: Controller `Gate::authorize` / Policy
| ID | Gate | Method | Source |
|----|------|--------|--------|
| BC-AUTH-01 | tenant.medical-incident.viewAny | index | Controller:24 |
| BC-AUTH-02 | tenant.medical-incident.create | create | Controller:40 |
| BC-AUTH-03 | tenant.medical-incident.store | store | Controller:87 |
| BC-AUTH-04 | tenant.medical-incident.view | show / ajaxGetStudents | Controller:61,115 |
| BC-AUTH-05 | tenant.medical-incident.update | edit / update / toggleFollowUp / toggleParentNotified | Controller:135,155,278,304 |
| BC-AUTH-06 | tenant.medical-incident.delete | destroy | Controller:202 |
| BC-AUTH-07 | tenant.medical-incident.restore | trashed / restore | Controller:221,240 |
| BC-AUTH-08 | tenant.medical-incident.forceDelete | forceDelete | Controller:259 |

### BC-BIZ (business logic / activity-log events) — Source: Controller
| ID | Fact | Event string | Source |
|----|------|--------------|--------|
| BC-BIZ-01 | store() creates record, NO activity log, redirects to `student-profile.attendance.bulk` | — | Controller::store (DEV-MI-07 redirect anomaly) |
| BC-BIZ-02 | update() logs activity, redirects to `student-profile.medical-incidents.index` | `Updated` | Controller::update |
| BC-BIZ-03 | destroy() soft-deletes, logs activity, redirects to `student-profile.attendance.bulk` | `Deleted` | Controller::destroy |
| BC-BIZ-04 | restore() (GET) restores, logs activity, redirects to trashed | `Restored` | Controller::restore |
| BC-BIZ-05 | forceDelete() permanently deletes trashed, logs activity | `Force Deleted` | Controller::forceDelete |
| BC-BIZ-06 | toggleFollowUp() saves flag, returns JSON `{success, follow_up_required, message}`, logs activity | `Toggled` | Controller::toggleFollowUp |
| BC-BIZ-07 | toggleParentNotified() saves flag, returns JSON `{success, parent_notified, message}`, logs activity | `Toggled` | Controller::toggleParentNotified |
| BC-BIZ-08 | Create form defaults: parent_notified checked (true), follow_up_required unchecked (false) | — | create.blade `old(...,true/false)` |
| BC-BIZ-09 | Submit buttons: create "Save Medical Details", edit "Update Medical Details" | — | create/edit blade |
| BC-BIZ-10 | Listing badges: parent_notified true→bg-success "Yes"/false→bg-secondary "No"; follow_up true→bg-warning "Required"/false→bg-info "Not Required" | — | index.blade |
| BC-BIZ-11 | Listing location truncated to 30 chars (Str::limit) | — | index.blade |
| BC-BIZ-12 | View action opens `#incidentModal` via AJAX fetch into `#incidentDetails` | — | index.blade script |
| BC-BIZ-13 | Show page status badge: closure_date set→"Closed" else "Open" | — | show.blade |

### BC-INT (integration) — Source: Screen-IP / DDL
| ID | Fact | Source |
|----|------|--------|
| BC-INT-01 | Depends on `std_students` (student picker + FK cascade) | DDL / create.blade |
| BC-INT-02 | Depends on `sys_dropdown_table` type `MEDICAL_INCIDENT_TYPE` (incident type) | Controller / rules |
| BC-INT-03 | Depends on `sys_users` (reported_by picker + FK set null) | DDL / create.blade |
| BC-INT-04 | ajaxGetStudents filters students by class_section via currentAcademicSession | Controller::ajaxGetStudents |

### BC-EDG (edge / DDL-vs-validation defects) — Source: cross-layer scan
| ID | Fact | Source |
|----|------|--------|
| BC-EDG-01 | location rule max:255 but column VARCHAR(100) — DEV-MI-01 | rules vs DDL |
| BC-EDG-02 | action_taken rule max:512 but column VARCHAR(255) — DEV-MI-02 | rules vs DDL |
| BC-EDG-03 | update reported_by rule `exists:users,id` — `users` table absent in tenant — DEV-MI-03 | update rules vs schema |
| BC-EDG-04 | incident_type_id has no DB FK constraint (validation-only) — DEV-MI-04 | migration vs DDL comment |
| BC-EDG-05 | create() filters `Student::where('is_active','true')` (literal string) vs scope `is_active=1` — DEV-MI-05 | Controller vs Model scope |
| BC-EDG-06 | index() ignores search/student_id/incident_type_id and omits `$students`/`$incidentTypes` — filters non-functional — DEV-MI-06 | Controller::index vs index.blade |
| BC-EDG-07 | Multiple incidents allowed per student (no unique constraint) | DDL |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|-----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-* | DDL | Schema/model/migration config truth | All asserts pass | test_01 | ✅ |
| TC-P02 | BC-REF, BC-DB-05/06 | DDL | FK metadata + boolean defaults | Defaults 0 | test_02 | ✅ |
| TC-P03 | BC-DB-10 | Model | SoftDeletes query scoping | Excluded/withTrashed | test_03 | ✅ |
| TC-P04 | BC-BIZ, BC-VAL | store | Create required-only saves; optionals null | Saved, parent true/follow false | test_10 | ✅ |
| TC-P05 | BC-BIZ | store | Create all optional fields | Saved | test_11 | ✅ |
| TC-P06 | BC-BIZ-08 | create.blade | parent_notified default checked | checked | test_12 | ✅ |
| TC-P07 | BC-BIZ-08 | create.blade | follow_up default unchecked | unchecked | test_13 | ✅ |
| TC-P08 | BC-BIZ-09 | create.blade | Create button text | "Save Medical Details" | test_14 | ✅ |
| TC-P09 | BC-BIZ-09 | edit.blade | Edit button text | "Update Medical Details" | test_15 | ✅ |
| TC-P10 | BC-BIZ-01 | store | store redirects to attendance.bulk | redirect bulk | test_16 | ✅ |
| TC-P11 | BC-BIZ-02 | update | Update saves + logs 'Updated' | Saved + log | test_17 | ✅ |
| TC-P12 | BC-VAL-10 | update | Update clears closure_date | null | test_18 | ✅ |
| TC-P13 | BC-BIZ-06 | toggle | toggleFollowUp false→true + log 'Toggled' | JSON + DB + log | test_20 | ✅ |
| TC-P14 | BC-BIZ-06 | toggle | toggleFollowUp true→false | DB false | test_21 | ✅ |
| TC-P15 | BC-BIZ-07 | toggle | toggleParentNotified true→false + log 'Toggled' | JSON + DB + log | test_22 | ✅ |
| TC-P16 | BC-BIZ-07 | toggle | toggleParentNotified false→true | DB true | test_23 | ✅ |
| TC-P17 | BC-BIZ-10 | index.blade | parent_notified badges | bg-success/bg-secondary | test_61 | ✅ |
| TC-P18 | BC-BIZ-10 | index.blade | follow_up badges | bg-warning/bg-info | test_62 | ✅ |
| TC-P19 | BC-BIZ-11 | index.blade | location truncated 30 | prefix shown | test_64 | ✅ |
| TC-P20 | BC-BIZ-12 | index.blade | view modal loads details | content present | test_65 | ✅ |
| TC-P21 | BC-BIZ-13 | show.blade | show page fields + Open status | rendered | test_66 | ✅ |
| TC-P22 | BC-BIZ | edit.blade | edit prefilled | values present | test_67 | ✅ |
| TC-P23 | BC-BIZ | index.blade | listing renders row | location shown | test_60 | ✅ |
| TC-P24 | BC-DB-04 | index.blade | closure dash when null | row renders | test_63 | ✅ |
| TC-P25 | BC-BIZ-03/04/05 | lifecycle | delete→restore→forceDelete + logs | all events | test_25 | ✅ |
| TC-P26 | BC-DB-10 | trashed | trash page lists soft-deleted | present | test_68 | ✅ |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|-----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01 | store | student_id required | 422 | test_30 | ✅ |
| TC-N02 | BC-VAL-02 | store | incident_date required | 422 | test_31 | ✅ |
| TC-N03 | BC-VAL-03 | store | incident_type_id required | 422 | test_32 | ✅ |
| TC-N04 | BC-VAL-04 | store | location required + max:255 | 422 ×2 | test_33 | ✅ |
| TC-N05 | BC-VAL-05 | store | description required | 422 | test_34 | ✅ |
| TC-N06 | BC-VAL-08 | store | reported_by required | 422 | test_35 | ✅ |
| TC-N07 | BC-VAL-06 | store | first_aid_given max:512 | 422 | test_36 | ✅ |
| TC-N08 | BC-VAL-07 | store | action_taken max:512 | 422 | test_37 | ✅ |
| TC-N09 | BC-VAL-10 | store | closure_date after_or_equal (before fails, same passes) | 422/success | test_38 | ✅ |
| TC-N10 | BC-VAL-12/13 | toggle | toggle missing field | 422 ×2 | test_39 | ✅ |
| TC-N11 | BC-VAL-01 | store | student_id must exist (invalid id) | 422 | test_40 | ✅ |
| TC-N12 | BC-VAL-03 | store | incident_type_id must exist | 422 | test_41 | ✅ |
| TC-N13 | BC-INT | show/edit | invalid id → 404 | 404 ×2 | test_44 | ✅ |
| TC-N14 | BC-BIZ-05 | forceDelete | force-delete non-trashed → 404 | 404 | test_45 | ✅ |
| TC-N15 | BC-AUTH | guest | guest redirected to /login | /login | test_50 | ✅ |
| TC-N16 | BC-AUTH-03 | store | store forbidden w/o permission | 403 | test_51 | ✅ |
| TC-N17 | BC-AUTH-07 | restore | restore forbidden w/o permission | 403 | test_52 | ✅ |
| TC-N18 | BC-AUTH-08 | forceDelete | forceDelete forbidden w/o permission | 403 | test_53 | ✅ |
| TC-N19 | BC-AUTH-05 | toggle | toggle forbidden w/o permission | 403 | test_54 | ✅ |
| TC-N20 | BC-EDG-06 | index | filters ignored (DEV proof) | row still shows | test_69 | ✅ |
| TC-N21 | BC-EDG-01 | store | location > column width (DEV proof) | truncate/reject | test_70 | ✅ |
| TC-N22 | BC-EDG-02 | store | action_taken > column width (DEV proof) | truncate/reject | test_71 | ✅ |
| TC-N23 | BC-EDG-03 | update | reported_by rule table mismatch (DEV proof) | documents `users` absence | test_43 | ✅ |
| TC-N24 | BC-BIZ | show | stored XSS in description escaped | no script exec | test_90 | ✅ |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|-----|--------|-------------|----------|--------|--------|
| TC-D01 | B/F | BC-DB-10 | Model | Soft-delete scoping | excluded/withTrashed | test_03 | ✅ |
| TC-D02 | D | BC-REF-02 | DDL | reported_by null on reporter delete | reported_by null | test_42 | ✅ |
| TC-D03 | F | BC-BIZ-03/04/05 | lifecycle | create→delete→restore→forceDelete | events + gone | test_25 | ✅ |
| TC-D04 | B | BC-BIZ-05 | forceDelete | non-trashed force-delete 404 | 404 | test_45 | ✅ |
| TC-D05 | E | BC-INT-02 | rules | incident_type exists cross-table | 422 invalid | test_41 | ✅ |
| TC-D06 | G | BC-EDG-07 | DDL | multiple incidents per student | coexist | test_72 | ✅ |
| TC-D07 | E | BC-INT | tenancy | cross-tenant isolation | not visible | test_91 | ✅ (defensive) |

---

## 3. Test Method Index (bands)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_medical_incident_01_schema_migration_and_model_configuration | TC-P01 | Schema | 01 |
| 2 | test_medical_incident_02_foreign_keys_and_column_defaults | TC-P02 | Schema | 02 |
| 3 | test_medical_incident_03_soft_delete_query_scoping | TC-P03/TC-D01 | Schema | 03 |
| 4 | test_medical_incident_10_create_required_fields_saves_correctly | TC-P04 | Biz | 10 |
| 5 | test_medical_incident_11_create_with_all_optional_fields | TC-P05 | Biz | 11 |
| 6 | test_medical_incident_12_parent_notified_default_checked_on_create | TC-P06 | Biz | 12 |
| 7 | test_medical_incident_13_follow_up_default_unchecked_on_create | TC-P07 | Biz | 13 |
| 8 | test_medical_incident_14_create_submit_button_text | TC-P08 | Biz | 14 |
| 9 | test_medical_incident_15_edit_submit_button_text | TC-P09 | Biz | 15 |
| 10 | test_medical_incident_16_store_redirects_to_attendance_bulk | TC-P10 | Biz | 16 |
| 11 | test_medical_incident_17_update_saves_and_logs_updated | TC-P11 | Biz | 17 |
| 12 | test_medical_incident_18_update_can_clear_closure_date | TC-P12 | Biz | 18 |
| 13 | test_medical_incident_20_toggle_follow_up_false_to_true | TC-P13 | Toggle | 20 |
| 14 | test_medical_incident_21_toggle_follow_up_true_to_false | TC-P14 | Toggle | 21 |
| 15 | test_medical_incident_22_toggle_parent_notified_true_to_false | TC-P15 | Toggle | 22 |
| 16 | test_medical_incident_23_toggle_parent_notified_false_to_true | TC-P16 | Toggle | 23 |
| 17 | test_medical_incident_25_full_lifecycle_delete_restore_force_delete | TC-P25/TC-D03 | Lifecycle | 25 |
| 18 | test_medical_incident_30_validation_student_id_required | TC-N01 | Validation | 30 |
| 19 | test_medical_incident_31_validation_incident_date_required | TC-N02 | Validation | 31 |
| 20 | test_medical_incident_32_validation_incident_type_required | TC-N03 | Validation | 32 |
| 21 | test_medical_incident_33_validation_location_required_and_max | TC-N04 | Validation | 33 |
| 22 | test_medical_incident_34_validation_description_required | TC-N05 | Validation | 34 |
| 23 | test_medical_incident_35_validation_reported_by_required | TC-N06 | Validation | 35 |
| 24 | test_medical_incident_36_validation_first_aid_max_512 | TC-N07 | Validation | 36 |
| 25 | test_medical_incident_37_validation_action_taken_max_512 | TC-N08 | Validation | 37 |
| 26 | test_medical_incident_38_validation_closure_after_or_equal_incident | TC-N09 | Validation | 38 |
| 27 | test_medical_incident_39_toggle_missing_field_returns_422 | TC-N10 | Validation | 39 |
| 28 | test_medical_incident_40_student_must_exist | TC-N11 | Integration | 40 |
| 29 | test_medical_incident_41_incident_type_must_exist | TC-N12/TC-D05 | Integration | 41 |
| 30 | test_medical_incident_42_reported_by_null_on_reporter_delete | TC-D02 | Integration | 42 |
| 31 | test_medical_incident_43_update_reported_by_rule_table_dev | TC-N23 | Integration/DEV | 43 |
| 32 | test_medical_incident_44_invalid_id_returns_404 | TC-N13 | Integration | 44 |
| 33 | test_medical_incident_45_force_delete_non_trashed_404 | TC-N14/TC-D04 | Integration | 45 |
| 34 | test_medical_incident_50_guest_redirected_to_login | TC-N15 | Permissions | 50 |
| 35 | test_medical_incident_51_store_forbidden_without_permission | TC-N16 | Permissions | 51 |
| 36 | test_medical_incident_52_restore_forbidden_without_permission | TC-N17 | Permissions | 52 |
| 37 | test_medical_incident_53_force_delete_forbidden_without_permission | TC-N18 | Permissions | 53 |
| 38 | test_medical_incident_54_toggle_forbidden_without_permission | TC-N19 | Permissions | 54 |
| 39 | test_medical_incident_60_index_listing_shows_row | TC-P23 | UI/UX | 60 |
| 40 | test_medical_incident_61_parent_notified_badges | TC-P17 | UI/UX | 61 |
| 41 | test_medical_incident_62_follow_up_badges | TC-P18 | UI/UX | 62 |
| 42 | test_medical_incident_63_closure_date_dash_when_null | TC-P24 | UI/UX | 63 |
| 43 | test_medical_incident_64_location_truncated_in_listing | TC-P19 | UI/UX | 64 |
| 44 | test_medical_incident_65_view_modal_loads_details | TC-P20 | UI/UX | 65 |
| 45 | test_medical_incident_66_show_page_displays_fields | TC-P21 | UI/UX | 66 |
| 46 | test_medical_incident_67_edit_page_prefilled | TC-P22 | UI/UX | 67 |
| 47 | test_medical_incident_68_trash_page_shows_soft_deleted | TC-P26 | UI/UX | 68 |
| 48 | test_medical_incident_69_index_filters_are_not_applied_dev | TC-N20 | UI/UX/DEV | 69 |
| 49 | test_medical_incident_70_location_exceeds_column_width_dev | TC-N21 | Edge/DEV | 70 |
| 50 | test_medical_incident_71_action_taken_exceeds_column_width_dev | TC-N22 | Edge/DEV | 71 |
| 51 | test_medical_incident_72_multiple_incidents_per_student_allowed | TC-D06 | Edge | 72 |
| 52 | test_medical_incident_90_stored_xss_description_escaped | TC-N24 | Security | 90 |
| 53 | test_medical_incident_91_cross_tenant_isolation | TC-D07 | Tenancy | 91 |

---

## 4. Known Source Defects (DEV-###)

| DEV ID | Severity | Description | Proving test |
|--------|----------|-------------|--------------|
| DEV-MI-01 | Medium | `location` rule `max:255` but column `VARCHAR(100)` — 101-255 char values pass validation, truncate/reject at DB | test_70 |
| DEV-MI-02 | Medium | `action_taken` rule `max:512` but column `VARCHAR(255)` — 256-512 char values pass validation, truncate/reject at DB | test_71 |
| DEV-MI-03 | High | `update()` validates `reported_by` as `exists:users,id` while `store()` uses `exists:sys_users,id`; tenant has no `users` table → update reported_by validation may always fail | test_43 |
| DEV-MI-04 | Low | `incident_type_id` has no DB FK constraint (validation-only); DDL comment implies FK to `sys_dropdown_table` | test_41 (validation), noted in Gap |
| DEV-MI-05 | Medium | `create()` filters `Student::where('is_active','true')` (literal string 'true') vs model scope `is_active=1` — create student picker may be empty/wrong | Gap analysis (noted) |
| DEV-MI-06 | Medium | `index()` ignores `search`/`student_id`/`incident_type_id` and omits `$students`/`$incidentTypes` → filter form non-functional | test_69 |
| DEV-MI-07 | Low | `store()` and `destroy()` redirect to `student-profile.attendance.bulk` instead of the medical-incidents index (inconsistent UX) | test_16 |

> **GAP-STD-08 note:** The V1 audit lists `MedicalIncidentPolicy` among "missing" policies. VERIFIED FALSE for this resource — `Modules/StudentProfile/app/Policies/MedicalIncidentPolicy.php` exists with all 8 ability methods. The controller nonetheless authorizes via `Gate::authorize('tenant.medical-incident.*')` string abilities (Spatie permission gates), so the Policy class is not invoked per-object. See Gap Analysis Cross-Reference #3/#10.
