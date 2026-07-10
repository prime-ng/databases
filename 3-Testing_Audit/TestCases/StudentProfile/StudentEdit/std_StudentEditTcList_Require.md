# std_StudentEdit — Test Case List & Requirements

**Module:** StudentProfile (`std_`, primary table `std_students`) · **DB scope:** TENANT
**Feature/Screen:** StudentEdit — edit page + per-tab updates + student lifecycle
**Test style:** Browser Dusk (`extends DuskTestCase`, `Tests\Browser`, tenant init via `Modules\Prime\Models\Domain`)
**Test file:** `std_StudentEdit_TestCas.php` (class `std_StudentEdit_TestCas`) — **ONE file, 54 methods**
**URL prefix:** `/student-profile` · **Controller:** `Modules\StudentProfile\Http\Controllers\StudentController`
**Primary requirement source:** `prime_testing/tests/Browser/Modules/StudentProfile/requirements/spr_StudentEdit_Require.md`

> **Current-source verification (2026-Jul):** several audit defects are **remediated** in the live code. Per HARD RULE 10/11 and `05_` golden principle, tests assert **current behaviour** and document the remediation; genuinely-present defects get proving tests.

---

## 1. Business Conditions

### BC-DB (schema — `StudentProfile_DDL_v1.6.sql` + live tenant DB)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `std_students` has `id, user_id, admission_no, admission_date, student_id_card_type, aadhar_id, first_name, middle_name, last_name, gender, dob, current_status_id, is_active, note, deleted_at` | DDL-std_students |
| BC-DB-02 | `admission_no`, `user_id`, `aadhar_id` are UNIQUE | DDL-std_students |
| BC-DB-03 | FK `std_students.user_id` → `sys_users.id` `ON DELETE CASCADE` | DDL-std_students |
| BC-DB-04 | `Student` uses `SoftDeletes`; `deleted_at` present | DDL + Model |
| BC-DB-05 | `Guardian` uses `SoftDeletes`; `StudentAcademicSession` does **NOT** (session delete = hard delete) | Model / DDL-STD-12 |
| BC-DB-06 | `StudentHealthProfile` table = `std_health_profiles` (not `std_student_health_profiles`) | Model |
| BC-DB-07 | Runtime `std_students` may carry `aadhar_id_hash` / `tc_issued` beyond the consolidated DDL | Model booted() / migration |

### BC-VAL (validation — inline `$request->validate()`; **no FormRequest** for these routes)
| ID | Rule | Route/Method | Source |
|----|------|--------------|--------|
| BC-VAL-01 | `updateStudentDetails`: `user_id` exists, `admission_no` req+unique, `admission_date` date, `first_name` req, `dob` req+date, `current_status_id` req | `updateStudentDetails` | Controller:942 |
| BC-VAL-02 | `updateLogin`: `name`/`short_name`/`emp_code`/`email` req+unique(self), `password` nullable min:8 confirmed | `updateLogin` | Controller:676 |
| BC-VAL-03 | `updateProfile`: dropdown FKs `exists:sys_dropdown_table,id` | `updateProfile` | Controller:1085 |
| BC-VAL-04 | `updateStudentAddress`: `address_type` req in-set, `address` req | `updateStudentAddress` | Controller:1207 |
| BC-VAL-05 | `updateStudentSession`: `academic_session_id`, `class_section_id`, `session_status_id`, `house`, `dis_note` req | `updateStudentSession` | Controller:1905 |
| BC-VAL-06 | `createStudentMedicalDetails`: `blood_group in:A+,A-,B+,B-,AB+,AB-,O+,O-`; `next_due_date.* >= date_administered.*` | `createStudentMedicalDetails` | Controller:2708 |
| BC-VAL-07 | `updateStudentDocument`: `expiry_date after_or_equal issue_date` | `updateStudentDocument` | Controller:2550 |
| BC-VAL-08 | `updateParentDetails`: `first_name`, `gender` in-set, `mobile_no`, `relation_type` req | `updateParentDetails` | Controller:1661 |
| BC-VAL-09 | `updateHealthProfile` performs **no `validate()`** (only sets present fields) | `updateHealthProfile` | Controller:2872 (finding) |

### BC-AUTH (permission gates — all `tenant.student.*`, **SEC-STD-02 remediated**)
| ID | Gate | Method | Source |
|----|------|--------|--------|
| BC-AUTH-01 | `tenant.student.update` | edit, updateLogin, updateStudentDetails, updateProfile, updateStudentAddress, updateParentDetails, updateStudentSession, deleteStudentSession, updatePreviousEducation, updateStudentDocument, updateHealthProfile, toggleStatus | Controller |
| BC-AUTH-02 | `tenant.student.delete` | destroy | Controller:3845 |
| BC-AUTH-03 | `tenant.student.restore` | trashed, restore | Controller:3888/3907 |
| BC-AUTH-04 | `tenant.student.forceDelete` | forceDelete | Controller:3951 |
| BC-AUTH-05 | `tenant.student-document.delete` | deleteStudentDocument (non-standard key) | Controller:2661 |
| BC-AUTH-06 | `deletePreviousEducation` has **NO Gate** (authz gap) | deletePreviousEducation | Controller:2507 (finding) |

### BC-BIZ (business logic / activity log)
| ID | Behaviour | Source |
|----|-----------|--------|
| BC-BIZ-01 | Blank password on `updateLogin` does not overwrite the hash | Controller:696 |
| BC-BIZ-02 | `ensureSinglePrimaryAddress` keeps at most one primary address | Controller:1061 |
| BC-BIZ-03 | Only one session may be `is_current` per student after update | Controller:1939 |
| BC-BIZ-04 | `destroy/restore/forceDelete` write `activityLog` events `Deleted`/`Restored`/`Force Deleted` (**AUD-STD-04 remediated**) | Controller:3871/3934/3996 |
| BC-BIZ-05 | `Student::saving` writes `activityLog 'pii_aadhar_updated'` + HMAC hash when `aadhar_id` dirty | Model:59 |
| BC-BIZ-06 | `toggleStatus` returns JSON `{success,is_active,message}` | Controller:1335 |

### BC-SM (state machine — student lifecycle)
| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | Active → destroy → Trashed (soft-deleted, `is_active=0`) | Controller:3843 |
| BC-SM-02 | Trashed → restore → Active | Controller:3905 |
| BC-SM-03 | Trashed → forceDelete → Removed (permanent; may be blocked by FK/media) | Controller:3949 |
| BC-SM-04 | Active ↔ toggleStatus → Inactive/Active | Controller:1335 |
| BC-SM-05 | Session non-current → set is_current → all sibling sessions cleared | Controller:1939 |

### BC-REF / BC-INT (referential / cross-module)
| ID | Reference | onDelete | Source |
|----|-----------|----------|--------|
| BC-REF-01 | `std_students.user_id` → `sys_users.id` | CASCADE | DDL |
| BC-INT-01 | `Student` imports `StudentFee`/`Transport`/`StudentPortal` models (reverse coupling ARCH-STD-13) | — | Model:13-18 |

### BC-EDG / BC-CFG (edge / config-driven defects)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Edit page must not 500 with missing guardians/session/health/prev-ed | Req §"Must Not Throw" |
| BC-EDG-02 | Whitespace-only `note` must not crash the update | DDL VARCHAR(255) |
| BC-CFG-01 | **SEC-STD-01** `is_super_admin` toggle removed from EDIT view + `updateLogin` (residual only in create partial) | Audit + View grep |
| BC-CFG-02 | **GAP-STD-05** only `StudentLeaveTypeRequest` FormRequest exists | Audit + fs |
| BC-CFG-03 | **BUG-STD-P3-02** `resources/views/student/edit.blade.bkp` present | Audit + fs |
| BC-CFG-04 | **SEC-STD-03** `aadhar_id => 'encrypted'` cast + `aadhar_id_hash` blind index | Model:56/63 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-* | DDL | Schema/model/cast/migration truth | All asserts pass | `_01_migration_model_and_request_configuration_are_correct` | ✅ |
| TC-P10 | BC-EDG-01 | Req | Edit loads for complete student | No 500, form present | `_10_page_loads_for_complete_student` | ✅ |
| TC-P11 | BC-EDG-01 | Req | Edit loads w/o optional data | No 500 | `_11_page_loads_without_optional_data` | ✅ |
| TC-P12 | BC-BIZ | Req | Login tab prefill (email) | Email in source | `_12_login_tab_prefill` | ✅ |
| TC-P13 | BC-BIZ | Req | Details tab prefill | admission_no+first_name shown | `_13_details_tab_prefill` | ✅ |
| TC-P14 | BC-BIZ-01 | Ctrl:696 | Blank password preserved | Hash unchanged | `_14_login_update_blank_password_preserved` | ✅ |
| TC-P15 | BC-BIZ | Ctrl:942 | Details update persists note | note saved | `_15_student_details_update_saved` | ✅ |
| TC-P16 | BC-BIZ | Ctrl:1081 | Profile update persists bank_name | bank_name saved | `_16_profile_update_saved` | ✅ |
| TC-P18 | BC-BIZ | Req | Guardian tab prefill | Guardian name shown | `_18_guardian_tab_prefill` | ✅ |
| TC-P19 | BC-BIZ | Ctrl:2872 | Health update persists | `std_health_profiles` row exists | `_19_health_update_persists_record` | ✅ |
| TC-P43 | BC-BIZ | Ctrl:3760 | getSessionData JSON | 200/302 | `_43_get_session_data_json` | ✅ |
| TC-P52 | BC-AUTH-2/3/4 | Ctrl | Lifecycle gate prefix tenant.* | strings present | `_52_lifecycle_gate_prefix_is_tenant` | ✅ |
| TC-P53 | BC-AUTH-01 | Ctrl | Update gate tenant.student.update | string present | `_53_update_gate_prefix_is_tenant` | ✅ |
| TC-P60 | BC-EDG | Req | Edit heading references student | Present | `_60_edit_heading_present` | ✅ |
| TC-P61 | BC-EDG | Req | Tabs don't open new window | ≤1 handle | `_61_tabs_do_not_open_new_window` | ✅ |
| TC-P62 | BC-EDG-01 | Req | Missing prev-ed tab renders | No 500 | `_62_missing_prev_edu_tab_renders` | ✅ |
| TC-P82 | BC-CFG-02 | Audit | GAP-STD-05 no FormRequests | Only LeaveType | `_82_no_form_request_for_student_updates` | ✅ |
| TC-P83 | BC-CFG-03 | Audit | BUG-STD-P3-02 edit.blade.bkp | File present | `_83_backup_blade_file_present` | ✅ |
| TC-P84 | BC-BIZ-04 | Audit | AUD-STD-04 activityLog active | Regex match | `_84_activity_log_active_on_lifecycle` | ✅ |
| TC-P85 | BC-CFG-04 | Model | SEC-STD-03 aadhar encrypted+hash | cast+hash | `_85_aadhar_encrypted_and_hashed` | ✅ |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N30 | BC-VAL-01 | Ctrl | Details missing required | 422/302 | `_30_details_validation_required_fields` | ✅ |
| TC-N31 | BC-VAL-02 | Ctrl | Login duplicate email | 422/302 | `_31_login_update_duplicate_email_rejected` | ✅ |
| TC-N32 | BC-VAL-02 | Ctrl | Login short password | 422/302 | `_32_login_update_short_password_rejected` | ✅ |
| TC-N33 | BC-VAL-06 | Ctrl | Invalid blood_group | 422/302 | `_33_health_invalid_blood_group_rejected` | ✅ |
| TC-N34 | BC-VAL-05 | Ctrl | Session missing required | 422/302 | `_34_session_update_required_fields` | ✅ |
| TC-N35 | BC-VAL-03 | Ctrl | Profile invalid dropdown FK | 422/302 | `_35_profile_update_invalid_dropdown_rejected` | ✅ |
| TC-N36 | BC-VAL-04 | Ctrl | Address missing required | 422/302 | `_36_address_update_required_fields` | ✅ |
| TC-N37 | BC-VAL-06 | Ctrl | Vaccination date order | 422/302 | `_37_vaccination_date_order_rejected` | ✅ |
| TC-N38 | BC-VAL-08 | Ctrl | Parent missing required | 422/302 | `_38_parent_update_required_fields` | ✅ |
| TC-N39 | BC-EDG-02 | DDL | Whitespace note handled | No crash | `_39_whitespace_note_handled` | ✅ |
| TC-N40 | BC-INT | Ctrl | Non-existent student 404 | 404/302/422 | `_40_invalid_student_returns_404` | ✅ |
| TC-N50 | BC-AUTH | — | Guest redirected to login | /login | `_50_guest_redirected_to_login` | ✅ |
| TC-N55 | BC-AUTH-06 | Ctrl:2507 | deletePreviousEducation authz gap | No Gate in body | `_55_delete_previous_education_authz_gap_documented` | ✅ |

### Dependency (TC-D) + State-machine (TC-SM) + Tenancy/Security (TC-T/TC-S)
| TC ID | Cat | BC | Source | Description | Method | Status |
|-------|-----|----|--------|-------------|--------|--------|
| TC-D17-B | B | BC-BIZ-02 | Ctrl:1061 | ≤1 primary address | `_17_exactly_one_primary_address` | ✅ |
| TC-D41-C | C | BC-REF-01 | DDL | user_id FK cascade declared | `_41_student_user_fk_cascade_declared` | ✅ |
| TC-D42-G | G | BC-BIZ | Ctrl | No duplicate guardians on save | `_42_no_duplicate_guardians_on_save` | ✅ |
| TC-D44-E | E | BC-INT-01 | Model | Downstream relations defensive | `_44_downstream_relations_defensive` | ✅ |
| TC-D45-B | B | BC-EDG | Ctrl | Optional fields preserved | `_45_optional_fields_preserved` | ✅ |
| TC-D70-A | A | BC-EDG-01 | Req | No session → no 500 | `_70_missing_session_no_500` | ✅ |
| TC-D71-A | A | BC-EDG-01 | Req | No health → no 500 | `_71_missing_health_no_500` | ✅ |
| TC-SM20 | — | BC-SM-04 | Ctrl:1335 | toggleStatus flips is_active | `_20_toggle_status_updates_is_active` | ✅ |
| TC-SM21 | F | BC-SM-01 | Ctrl:3843 | destroy soft-deletes + log | `_21_destroy_soft_deletes_student` | ✅ |
| TC-P22 | — | BC-SM | Ctrl:3886 | trashed view lists | `_22_trashed_view_lists_soft_deleted` | ✅ |
| TC-SM23 | F | BC-SM-02 | Ctrl:3905 | restore recovers + log | `_23_restore_recovers_student` | ✅ |
| TC-SM24 | B | BC-SM-03 | Ctrl:3949 | forceDelete removes | `_24_force_delete_removes_student` | ✅ |
| TC-SM25 | — | BC-SM-05 | Ctrl:1939 | is_current uniqueness | `_25_session_is_current_unique` | ✅ |
| TC-D26-F | F | BC-DB-05 | Ctrl:2005 | session delete route/hard-delete | `_26_delete_session_removes_row` | ✅ |
| TC-S51 | — | BC-AUTH-01 | Ctrl | Update requires permission (403) | `_51_update_requires_permission` | ✅ |
| TC-S54 | — | BC-CFG | Audit | SEC-STD-02 no school-setup prefix | `_54_no_school_setup_gate_prefix` | ✅ |
| TC-S80 | — | BC-CFG-01 | Audit | SEC-STD-01 edit view no toggle | `_80_edit_login_partial_has_no_super_admin_toggle` | ✅ |
| TC-S81 | — | BC-CFG-01 | Ctrl | SEC-STD-01 updateLogin no assign | `_81_update_login_does_not_assign_super_admin` | ✅ |
| TC-T90 | — | Tenancy | — | Cross-tenant id not leaked (IDOR) | `_90_cross_tenant_id_not_leaked` | ✅ |
| TC-S91 | — | Security | — | Stored XSS in note escaped | `_91_note_xss_escaped` | ✅ |
| TC-S92 | — | BC-CFG-01 | Ctrl | Mass-assignment guard | `_92_mass_assignment_guard` | ✅ |

---

## 3. Test Method Index (bands)
| # | Method (`test_studentedit_…`) | TC Map | Category | Band |
|---|-------------------------------|--------|----------|------|
| 1 | `_01_migration_model_and_request_configuration_are_correct` | TC-P01 | Schema | 01-09 |
| 2 | `_10`..`_19` | TC-P10..19 / TC-D17 | Business rules | 10-19 |
| 3 | `_20`..`_26` | TC-SM20..25 / TC-D26 | Lifecycle/SM | 20-29 |
| 4 | `_30`..`_39` | TC-N30..39 | Validation | 30-39 |
| 5 | `_40`..`_45` | TC-N40 / TC-D41-45 | FK/Integration | 40-49 |
| 6 | `_50`..`_55` | TC-N50/55 / TC-S51/54 / TC-P52/53 | Authorization | 50-59 |
| 7 | `_60`..`_62` | TC-P60-62 | UI/UX | 60-69 |
| 8 | `_70`..`_71` | TC-D70/71 | Edge | 70-79 |
| 9 | `_80`..`_85` | TC-S80/81 / TC-P82-85 | Config/defect proofs | 80-89 |
| 10 | `_90`..`_92` | TC-T90 / TC-S91/92 | Tenancy/Security | 90-99 |

**Total: 54 test methods, one comprehensive file.**

---

## 4. Known Source Defects (audit-equivalent)
| ID | Severity | Status in current source | Proving test |
|----|----------|--------------------------|--------------|
| SEC-STD-01 | P0 | **Remediated** (edit view + updateLogin); residual in create partial | `_80`, `_81`, `_92` |
| SEC-STD-02 | P0 | **Remediated** (all gates `tenant.student.*`) | `_54`, `_52`, `_53` |
| AUD-STD-04 | P1 | **Remediated** (activityLog active) | `_84`, `_21`, `_23`, `_24` |
| SEC-STD-03 | P1 | **Remediated** (encrypted cast + HMAC hash) | `_85` |
| GAP-STD-05 | P1 | **Present** (no student FormRequests) | `_82` |
| BUG-STD-P3-02 | P3 | **Present** (edit.blade.bkp) | `_83` |
| GAP-AUTH (deletePreviousEducation no Gate) | new | **Present** | `_55` |
| BC-VAL-09 (updateHealthProfile no validate) | new | **Present** | documented; covered indirectly by `_33` on create route |
| DDL-STD-12 (session no SoftDeletes) | P2 | **Present** | `_26`, `_01` |
