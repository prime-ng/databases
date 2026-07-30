# std_MedicalIncidents — Test Case List & Business Conditions

**Module:** StudentProfile (CODE `STD`, prefix `std_`) · **Feature:** Medical Incidents (CRUD + Trash + Toggle Follow-up/Parent Notified)
**DB scope:** TENANT-side (`std_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `std_medical_incidents` · **Module URL prefix:** `/student-profile`
**Test file:** `std_MedicalIncident_TestCas.php`
**Checklists applied:** `Gaurav_list.md` + `Shailesh_list.md`

Routes:
- `GET     /student-profile/medical-incidents` — MedicalIncidentController@index (list with filters)
- `GET     /student-profile/medical-incidents/create` — MedicalIncidentController@create
- `POST    /student-profile/medical-incidents` — MedicalIncidentController@store
- `GET     /student-profile/medical-incidents/{id}` — MedicalIncidentController@show (modal/ page)
- `GET     /student-profile/medical-incidents/{id}/edit` — MedicalIncidentController@edit
- `PUT     /student-profile/medical-incidents/{id}` — MedicalIncidentController@update
- `DELETE  /student-profile/medical-incidents/{id}` — MedicalIncidentController@destroy
- `GET     /student-profile/medical-incidents/trash/view` — MedicalIncidentController@trashed
- `GET     /student-profile/medical-incidents/{id}/restore` — MedicalIncidentController@restore
- `DELETE  /student-profile/medical-incidents/{id}/force-delete` — MedicalIncidentController@forceDelete
- `POST    /student-profile/medical-incidents/{id}/toggle-follow-up` — MedicalIncidentController@toggleFollowUp
- `POST    /student-profile/medical-incidents/{id}/toggle-parent-notified` — MedicalIncidentController@toggleParentNotified
- `GET     /student-profile/ajax/medical-incidents/get-students` — MedicalIncidentController@ajaxGetStudents

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `std_medical_incidents` exists with columns: id, student_id, incident_date, incident_type_id, location, description, first_aid_given, action_taken, reported_by, parent_notified, closure_date, follow_up_required, deleted_at | DDL |
| BC-DB-02 | Model `MedicalIncident`: table `std_medical_incidents`, SoftDeletes, InteractsWithMedia, fillable includes 11 fields | MedicalIncident.php:14-35 |
| BC-DB-03 | Casts: incident_date (datetime), closure_date (date), parent_notified (boolean), follow_up_required (boolean) | MedicalIncident.php:37-42 |
| BC-DB-04 | Media collection `medical_documents` registered (singleFile) | MedicalIncident.php:66 |
| BC-DB-05 | Relationships: student (BelongsTo), reporter (BelongsTo User), incidentType (BelongsTo Dropdown) | MedicalIncident.php:46-58 |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | Store: student_id required exists:std_students,id; incident_date required date; incident_type_id required exists:sys_dropdown_table,id; location required string max:255; description required string; first_aid_given nullable string max:512; action_taken nullable string max:512; reported_by required exists:sys_users,id; parent_notified boolean; closure_date nullable date after_or_equal:incident_date; follow_up_required boolean | Ctrl:89-101 |
| BC-VAL-02 | Update: same rules as Store except reported_by exists:users,id (different table — bug) | Ctrl:160-172 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `tenant.medical-incident.viewAny` | Ctrl:24 |
| BC-AUTH-02 | create() gate `tenant.medical-incident.create` | Ctrl:40 |
| BC-AUTH-03 | store() gate `tenant.medical-incident.store` | Ctrl:87 |
| BC-AUTH-04 | show()/ajaxGetStudents() gate `tenant.medical-incident.view` | Ctrl:61,115 |
| BC-AUTH-05 | edit()/update() gate `tenant.medical-incident.update` | Ctrl:135,155 |
| BC-AUTH-06 | destroy() gate `tenant.medical-incident.delete` | Ctrl:202 |
| BC-AUTH-07 | trashed()/restore() gate `tenant.medical-incident.restore` | Ctrl:221,240 |
| BC-AUTH-08 | forceDelete() gate `tenant.medical-incident.forceDelete` | Ctrl:259 |
| BC-AUTH-09 | toggleFollowUp()/toggleParentNotified() gate `tenant.medical-incident.update` | Ctrl:278,304 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Store redirects to `student-profile.attendance.bulk` with success flash | Ctrl:105-107 |
| BC-BIZ-02 | Update logs 'Updated' activity with field-level changes diff | Ctrl:186-190 |
| BC-BIZ-03 | Destroy soft-deletes the record, logs 'Deleted' activity | Ctrl:204-213 |
| BC-BIZ-04 | Restore restores soft-deleted record, logs 'Restored' | Ctrl:242-251 |
| BC-BIZ-05 | Force delete permanently removes, logs 'Force Deleted' | Ctrl:261-270 |
| BC-BIZ-06 | toggleFollowUp updates boolean, logs 'Toggled', returns JSON | Ctrl:276-297 |
| BC-BIZ-07 | toggleParentNotified updates boolean, logs 'Toggled', returns JSON | Ctrl:302-323 |
| BC-BIZ-08 | Show renders same view for both AJAX and full page requests | Ctrl:123-127 |
| BC-BIZ-09 | create() loads students, incidentTypes, users, classSections for dropdowns | Ctrl:42-53 |
| BC-BIZ-10 | ajaxGetStudents filters students by class_section_id | Ctrl:59-79 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing incident id → 404 (findOrFail) | Ctrl:117,137,204,242,261,284,310 |
| BC-EDG-02 | Force delete on non-trashed record → 404 (onlyTrashed findOrFail) | Ctrl:261 |

### Known Source Defects
| ID | Finding | Current state | Proving test |
|----|---------|--------------|--------------|
| DEV-MI-01 | Index filters (search, student_id, incident_type_id) declared in view but no controller filter logic — filter form presentational only | CONFIRMED | test_medical_incident_69 |
| DEV-MI-02 | Update validation uses `exists:users,id` while Store uses `exists:sys_users,id` — inconsistency | CONFIRMED | test_medical_incident_43 |
| DEV-MI-03 | No store() activity log (other actions log; store does not) | CONFIRMED | — |

---

## 2. Test Case List

### Screen 1: Index Listing (GET /medical-incidents)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P60 | Positive | View | Index listing renders rows with incident data | Row displayed | test_medical_incident_60 | Automated |
| TC-MI-P61 | Positive | View | Parent notified badge shows Yes/No | Badge rendered | test_medical_incident_61 | Automated |
| TC-MI-P62 | Positive | View | Follow-up badge shows Required/Not Required | Badge rendered | test_medical_incident_62 | Automated |
| TC-MI-P63 | Positive | View | Closure date shows dash when null | Dash displayed | test_medical_incident_63 | Automated |
| TC-MI-P64 | Positive | View | Location truncated to 30 chars in listing | Truncated | test_medical_incident_64 | Automated |
| TC-MI-N69 | Negative | Dev | Index filters are not applied (search/student/type — filter logic absent) | Gap documented | test_medical_incident_69 | Automated |

### Screen 3: Store (POST /medical-incidents)

#### Positive — Happy Path
| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P10 | Positive | Ctrl | Create with only required fields (student_id, incident_date, incident_type_id, location, description, reported_by) saves correctly | Row created with defaults for optionals | test_medical_incident_10 | Automated |
| TC-MI-P11 | Positive | Ctrl | Create with all optional fields (first_aid_given, action_taken, closure_date after incident, parent_notified=true, follow_up_required=true) | All optional fields persisted | test_medical_incident_11 | Automated |
| TC-MI-P16 | Positive | Ctrl | Store redirects to attendance bulk page after success | Redirect to bulk | test_medical_incident_16 | Automated |
| TC-MI-P70 | Positive | Ctrl | parent_notified accepts both true and false boolean values | Both persisted | Planned |
| TC-MI-P71 | Positive | Ctrl | follow_up_required accepts both true and false boolean values | Both persisted | Planned |
| TC-MI-P72 | Positive | Ctrl | closure_date equal to incident_date (boundary: after_or_equal) | Accepted | test_medical_incident_72 | Automated |
| TC-MI-P73 | Positive | Ctrl | Multiple incidents can be created for the same student | All saved | test_medical_incident_72 | Automated |

#### Negative — Required Field Validation
| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-N30 | Negative | Ctrl | Empty student_id → rejected | 422 | test_medical_incident_30 | Automated |
| TC-MI-N31 | Negative | Ctrl | Empty incident_date → rejected | 422 | test_medical_incident_31 | Automated |
| TC-MI-N32 | Negative | Ctrl | Empty incident_type_id → rejected | 422 | test_medical_incident_32 | Automated |
| TC-MI-N33 | Negative | Ctrl | Empty location → rejected | 422 | test_medical_incident_33 | Automated |
| TC-MI-N34 | Negative | Ctrl | Empty description → rejected | 422 | test_medical_incident_34 | Automated |
| TC-MI-N35 | Negative | Ctrl | Empty reported_by → rejected | 422 | test_medical_incident_35 | Automated |

#### Negative — Field Format & Boundary Validation
| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-N36 | Negative | Ctrl | first_aid_given exceeds 512 chars → rejected | 422 | test_medical_incident_36 | Automated |
| TC-MI-N37 | Negative | Ctrl | action_taken exceeds 512 chars → rejected | 422 | test_medical_incident_37 | Automated |
| TC-MI-N38 | Negative | Ctrl | closure_date before incident_date (violates after_or_equal) → rejected | 422 | test_medical_incident_38 | Automated |
| TC-MI-N74 | Negative | Ctrl | location exceeds 255 chars → rejected | 422 | Planned |
| TC-MI-N75 | Negative | Ctrl | location empty string (whitespace only) → rejected | 422 | Planned |
| TC-MI-N76 | Negative | Ctrl | incident_date invalid format (not a date) → rejected | 422 | Planned |
| TC-MI-N77 | Negative | Ctrl | closure_date invalid format → rejected | 422 | Planned |

#### Negative — Foreign Key / Existence Validation
| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-N40 | Negative | Ctrl | Non-existing student_id (999999) → rejected | 422/404 | test_medical_incident_40 | Automated |
| TC-MI-N41 | Negative | Ctrl | Non-existing incident_type_id (999999) → rejected | 422 | test_medical_incident_41 | Automated |
| TC-MI-N78 | Negative | Ctrl | Non-existing reported_by (999999) → rejected | 422 | Planned |

#### Negative — Boolean Type Coercion
| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-N79 | Negative | Ctrl | parent_notified = non-boolean string → coerced to true/false or rejected | Safe handling | Planned |
| TC-MI-N80 | Negative | Ctrl | follow_up_required = non-boolean string → coerced to true/false or rejected | Safe handling | Planned |

### Screen 4: Show (GET /medical-incidents/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P65 | Positive | View | View modal loads incident details via AJAX | Details loaded | test_medical_incident_65 | Automated |
| TC-MI-P66 | Positive | View | Show page displays all fields | All displayed | test_medical_incident_66 | Automated |
| TC-MI-N44 | Negative | Ctrl | Invalid id → 404 | 404 | test_medical_incident_44 | Automated |

### Screen 5: Edit (GET /medical-incidents/{id}/edit)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P15 | Positive | View | Edit page pre-filled with existing data | Pre-filled | test_medical_incident_15 | Automated |
| TC-MI-P67 | Positive | View | Edit page loads correctly | Loads | test_medical_incident_67 | Automated |

### Screen 6: Update (PUT /medical-incidents/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P17 | Positive | Ctrl | Update saves changes and logs 'Updated' activity | Updated + log | test_medical_incident_17 | Automated |
| TC-MI-P18 | Positive | Ctrl | Update can clear closure_date (set to null) | Cleared | test_medical_incident_18 | Automated |

### Screen 7: Toggle Follow-up (POST /medical-incidents/{id}/toggle-follow-up)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P20 | Positive | Ctrl | Toggle follow-up false → true | Updated to true | test_medical_incident_20 | Automated |
| TC-MI-P21 | Positive | Ctrl | Toggle follow-up true → false | Updated to false | test_medical_incident_21 | Automated |
| TC-MI-N39 | Negative | Ctrl | Toggle missing follow_up_required field → 422 | 422 | test_medical_incident_39 | Automated |

### Screen 8: Toggle Parent Notified (POST /medical-incidents/{id}/toggle-parent-notified)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P22 | Positive | Ctrl | Toggle parent_notified false → true | Updated to true | test_medical_incident_22 | Automated |
| TC-MI-P23 | Positive | Ctrl | Toggle parent_notified true → false | Updated to false | test_medical_incident_23 | Automated |

### Screen 9: Destroy (DELETE /medical-incidents/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P25 | Positive | Ctrl | Full lifecycle: delete → trash → restore → force delete | All steps pass | test_medical_incident_25 | Automated |

### Screen 10: Trash (GET /medical-incidents/trash/view)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P68 | Positive | View | Trash page shows soft-deleted incidents | Listed | test_medical_incident_68 | Automated |

### Screen 11: Restore (GET /medical-incidents/{id}/restore)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P25 | Positive | Ctrl | Full lifecycle includes restore | Restored | test_medical_incident_25 | Automated |

### Screen 12: Force Delete (DELETE /medical-incidents/{id}/force-delete)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P25 | Positive | Ctrl | Full lifecycle includes force delete | Permanently deleted | test_medical_incident_25 | Automated |
| TC-MI-N45 | Negative | Ctrl | Force delete on non-trashed record → 404 | 404 | test_medical_incident_45 | Automated |

### Database — Foreign Keys

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-D42 | Integrity | DDL | reported_by → sys_users ON DELETE SET NULL | SET NULL | test_medical_incident_42 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy, Defects

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-MI-P01 | Schema | DDL/Model | Table, columns, fillable, casts, SoftDeletes, relationships, migration | All pass | test_medical_incident_01 | Automated |
| TC-MI-P02 | Schema | DDL | Foreign keys and column defaults | Correct | test_medical_incident_02 | Automated |
| TC-MI-P03 | Schema | Model | Soft delete query scoping works | Scoped | test_medical_incident_03 | Automated |
| TC-MI-P50 | Auth | Middleware | Guest redirected to /login | /login | test_medical_incident_50 | Automated |
| TC-MI-N51 | Auth | Ctrl | Store forbidden without permission | 403 | test_medical_incident_51 | Automated |
| TC-MI-N52 | Auth | Ctrl | Restore forbidden without permission | 403 | test_medical_incident_52 | Automated |
| TC-MI-N53 | Auth | Ctrl | Force delete forbidden without permission | 403 | test_medical_incident_53 | Automated |
| TC-MI-N54 | Auth | Ctrl | Toggle forbidden without permission | 403 | test_medical_incident_54 | Automated |
| TC-MI-T90 | Security | Ctrl | XSS in description is escaped | Not executed | test_medical_incident_90 | Automated |
| TC-MI-T91 | Tenancy | Tenant | Cross-tenant isolation | Not leaked | test_medical_incident_91 | Automated |

### Planned Additions (not yet automated)

| TC ID | Type | Source | Description | Expected | Priority |
|-------|------|--------|-------------|----------|----------|
| TC-MI-P72 | Positive | Ctrl | Multiple incidents per student allowed | All saved | Medium |
| TC-MI-N70 | Negative | Dev | location VARCHAR(255) vs DDL col width mismatch proven | Gap documented | Low |
| TC-MI-N71 | Negative | Dev | action_taken VARCHAR(255) vs DDL col width mismatch proven | Gap documented | Low |
| TC-MI-D43 | Integrity | DDL | Update reported_by references `users` table (not `sys_users`) — mismatch | Gap documented | Low |

---

## 3. Test Method Index

### File: `std_MedicalIncident_TestCas.php` (53 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_medical_incident_01_schema_migration_and_model_configuration | TC-MI-P01 | Schema | 01-09 |
| 2 | test_medical_incident_02_foreign_keys_and_column_defaults | TC-MI-P02 | Schema | 01-09 |
| 3 | test_medical_incident_03_soft_delete_query_scoping | TC-MI-P03 | Schema | 01-09 |
| 4 | test_medical_incident_10_create_required_fields_saves_correctly | TC-MI-P10 | Biz | 10-19 |
| 5 | test_medical_incident_11_create_with_all_optional_fields | TC-MI-P11 | Biz | 10-19 |
| 6 | test_medical_incident_12_parent_notified_default_checked_on_create | TC-MI-P12 | UI | 10-19 |
| 7 | test_medical_incident_13_follow_up_default_unchecked_on_create | TC-MI-P13 | UI | 10-19 |
| 8 | test_medical_incident_14_create_submit_button_text | TC-MI-P14 | UI | 10-19 |
| 9 | test_medical_incident_15_edit_submit_button_text | TC-MI-P15 | UI | 10-19 |
| 10 | test_medical_incident_16_store_redirects_to_attendance_bulk | TC-MI-P16 | Biz | 10-19 |
| 11 | test_medical_incident_17_update_saves_and_logs_updated | TC-MI-P17 | Biz | 10-19 |
| 12 | test_medical_incident_18_update_can_clear_closure_date | TC-MI-P18 | Biz | 10-19 |
| 13 | test_medical_incident_20_toggle_follow_up_false_to_true | TC-MI-P20 | Toggle | 20-29 |
| 14 | test_medical_incident_21_toggle_follow_up_true_to_false | TC-MI-P21 | Toggle | 20-29 |
| 15 | test_medical_incident_22_toggle_parent_notified_true_to_false | TC-MI-P22 | Toggle | 20-29 |
| 16 | test_medical_incident_23_toggle_parent_notified_false_to_true | TC-MI-P23 | Toggle | 20-29 |
| 17 | test_medical_incident_25_full_lifecycle_delete_restore_force_delete | TC-MI-P25 | Lifecycle | 20-29 |
| 18 | test_medical_incident_30_validation_student_id_required | TC-MI-N30 | Val | 30-39 |
| 19 | test_medical_incident_31_validation_incident_date_required | TC-MI-N31 | Val | 30-39 |
| 20 | test_medical_incident_32_validation_incident_type_required | TC-MI-N32 | Val | 30-39 |
| 21 | test_medical_incident_33_validation_location_required_and_max | TC-MI-N33 | Val | 30-39 |
| 22 | test_medical_incident_34_validation_description_required | TC-MI-N34 | Val | 30-39 |
| 23 | test_medical_incident_35_validation_reported_by_required | TC-MI-N35 | Val | 30-39 |
| 24 | test_medical_incident_36_validation_first_aid_max_512 | TC-MI-N36 | Val | 30-39 |
| 25 | test_medical_incident_37_validation_action_taken_max_512 | TC-MI-N37 | Val | 30-39 |
| 26 | test_medical_incident_38_validation_closure_after_or_equal_incident | TC-MI-N38 | Val | 30-39 |
| 27 | test_medical_incident_39_toggle_missing_field_returns_422 | TC-MI-N39 | Val | 30-39 |
| 28 | test_medical_incident_40_student_must_exist | TC-MI-N40 | FK | 40-49 |
| 29 | test_medical_incident_41_incident_type_must_exist | TC-MI-N41 | FK | 40-49 |
| 30 | test_medical_incident_42_reported_by_null_on_reporter_delete | TC-MI-D42 | FK | 40-49 |
| 31 | test_medical_incident_43_update_reported_by_rule_table_dev | TC-MI-D43 | FK | 40-49 |
| 32 | test_medical_incident_44_invalid_id_returns_404 | TC-MI-N44 | Edge | 40-49 |
| 33 | test_medical_incident_45_force_delete_non_trashed_404 | TC-MI-N45 | Edge | 40-49 |
| 34 | test_medical_incident_50_guest_redirected_to_login | TC-MI-P50 | Auth | 50-59 |
| 35 | test_medical_incident_51_store_forbidden_without_permission | TC-MI-N51 | Auth | 50-59 |
| 36 | test_medical_incident_52_restore_forbidden_without_permission | TC-MI-N52 | Auth | 50-59 |
| 37 | test_medical_incident_53_force_delete_forbidden_without_permission | TC-MI-N53 | Auth | 50-59 |
| 38 | test_medical_incident_54_toggle_forbidden_without_permission | TC-MI-N54 | Auth | 50-59 |
| 39 | test_medical_incident_60_index_listing_shows_row | TC-MI-P60 | UI | 60-69 |
| 40 | test_medical_incident_61_parent_notified_badges | TC-MI-P61 | UI | 60-69 |
| 41 | test_medical_incident_62_follow_up_badges | TC-MI-P62 | UI | 60-69 |
| 42 | test_medical_incident_63_closure_date_dash_when_null | TC-MI-P63 | UI | 60-69 |
| 43 | test_medical_incident_64_location_truncated_in_listing | TC-MI-P64 | UI | 60-69 |
| 44 | test_medical_incident_65_view_modal_loads_details | TC-MI-P65 | UI | 60-69 |
| 45 | test_medical_incident_66_show_page_displays_fields | TC-MI-P66 | UI | 60-69 |
| 46 | test_medical_incident_67_edit_page_prefilled | TC-MI-P67 | UI | 60-69 |
| 47 | test_medical_incident_68_trash_page_shows_soft_deleted | TC-MI-P68 | UI | 60-69 |
| 48 | test_medical_incident_69_index_filters_are_not_applied_dev | TC-MI-N69 | Dev | 60-69 |
| 49 | test_medical_incident_70_location_exceeds_column_width_dev | TC-MI-N70 | Dev | 70-79 |
| 50 | test_medical_incident_71_action_taken_exceeds_column_width_dev | TC-MI-N71 | Dev | 70-79 |
| 51 | test_medical_incident_72_multiple_incidents_per_student_allowed | TC-MI-P72 | Biz | 70-79 |
| 52 | test_medical_incident_90_stored_xss_description_escaped | TC-MI-T90 | Security | 90-99 |
| 53 | test_medical_incident_91_cross_tenant_isolation | TC-MI-T91 | Tenancy | 90-99 |

**Total: 53 methods (50 Automated, 3 Planned).**
