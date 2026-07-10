# std_StudentCreate — Test Case List & Business Conditions

**Module:** StudentProfile (`std_`) · **Feature/Screen:** Student Create (multi-tab onboarding wizard)
**DB scope:** TENANT-side (`std_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `std_students` · **Module URL prefix:** `/student-profile`
**Single test file:** `std_StudentCreate_TestCas.php` (class `std_StudentCreate_TestCas`) — ONE file, no V1/V2.

Wizard tabs → controller create methods (all in `StudentController`):
`createStudentLogin` (Registration) → `createStudentDetails` (Student Detail + Profile + Address) →
`createParentDetails` (Parents/Guardians) → `createStudentSession` (Session) →
`createStudentPrevEduDetails` (Previous Education) → `createStudentMedicalDetails` (Health/Vaccination).
Entry: `editStudentDetails` (`GET /student-profile/student/edit/student/details`).

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-StudentProfile_DDL_v1.6`, tenant migrations)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | 11 feature tables exist: `std_students`, `std_student_profiles`, `std_student_addresses`, `std_guardians`, `std_student_guardian_jnt`, `std_student_academic_sessions`, `std_student_opted_subjects`, `std_previous_education`, `std_student_documents`, `std_health_profiles`, `std_vaccination_records` | DDL |
| BC-DB-02 | `std_students`: `admission_no` UNIQUE, `user_id` UNIQUE (FK→`sys_users` ON DELETE CASCADE), `aadhar_id` UNIQUE, SoftDeletes (`deleted_at`) | DDL-std_students |
| BC-DB-03 | Health table is `std_health_profiles` (UNIQUE `student_id`); vaccination `std_vaccination_records` | DDL |
| BC-DB-04 | `std_student_guardian_jnt` UNIQUE (`student_id`,`guardian_id`) | DDL |
| BC-DB-05 | `std_student_academic_sessions.current_flag` UNIQUE index; spec = GENERATED STORED | DDL-line222 |

### BC-VAL — Validation (Source: inline `$request->validate` / `Validator::make` in `StudentController`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | Login: `name` req max255; `short_name` req unique `sys_users`; `email` req email unique; `password` req min8 confirmed; `status` req in `ACTIVE,INVITED,DISABLED` | Ctrl:594-605 |
| BC-VAL-02 | Details: `user_id` req exists `sys_users`; `admission_no` req max50 unique `std_students`; `admission_date` req date; `first_name` req max100; `dob` req date; `current_status_id` req integer | Ctrl:778-809 |
| BC-VAL-03 | Details aadhar uniqueness enforced on `aadhar_id_hash` (blind index), not raw value | Ctrl:784 |
| BC-VAL-04 | Parent: `student_id` req exists; `guardians`/`relationships` req arrays; new guardian requires `first_name,gender,mobile_no,short_name,password(min8)` | Ctrl:1375-1388 |
| BC-VAL-05 | Health: `blood_group` in `A+,A-,B+,B-,AB+,AB-,O+,O-`; height/weight numeric 0–300 | Ctrl:2708-2721 |
| BC-VAL-06 | Vaccination: `next_due_date.*` `after_or_equal:date_administered.*` | Ctrl:2731 |
| BC-VAL-07 | New-guardian duplicate mobile → error `Mobile number already registered to another guardian.` | Ctrl:1483 |

### BC-AUTH — Authorization (Source: `Gate::authorize` in controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `createStudentLogin/Details/Session/PrevEduDetails/MedicalDetails` gate `tenant.student.create` | Ctrl:593,720,1756,2044,2694 |
| BC-AUTH-02 | `createParentDetails` gate `tenant.guardian.create` | Ctrl:1374 |
| BC-AUTH-03 | All routes wrapped by `module:STUDENT` middleware (404 if disabled) | web.php:12 |
| BC-AUTH-04 | Guest is redirected to `/login` | Auth middleware |

### BC-BIZ — Business logic (Source: controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Login creates `sys_users` with `user_type='STUDENT'`, `emp_code` = `STD-YYYY-NNNNNN` (`generateStudentEmpCode`), password hashed | Ctrl:612-624,572-588 |
| BC-BIZ-02 | Details creates `std_students` + `std_student_profiles` + `std_student_addresses` in one transaction | Ctrl:728-764 |
| BC-BIZ-03 | Health saved only when a health field is present; `updateOrCreate` on `student_id`; vaccination rows appended | Ctrl:2742-2811 |
| BC-BIZ-04 | Parent: existing-guardian links junction; new-guardian creates `std_guardians` (+portal user) then junction | Ctrl:1420-1500 |

### BC-INT / BC-REF — Integration / FK
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `std_students.user_id` → `sys_users` ON DELETE CASCADE | DDL-std_students |
| BC-INT-01 | Student model reverse-couples `StudentFee`, `Transport`, `StudentPortal` (ARCH-STD-13) | Student.php:13,16,18 |

### Known Source Defects (audit-equivalent IDs — proven, not assumed)
| ID | Finding | Current state (this run) | Proving test |
|----|---------|--------------------------|--------------|
| SEC-STD-01 | `is_super_admin` mass-assignment escalation via login | **REMEDIATED in controller** (field no longer whitelisted); **view still renders toggle** (residual) | test_92, test_93 |
| SEC-STD-02 | Wrong Gate prefix `school-setup.student.*` | **REMEDIATED** — no such prefix remains; create-flow uses `tenant.*` | test_09 |
| SEC-STD-03 | Aadhar plaintext | **REMEDIATED** — `aadhar_id` `encrypted` cast + `aadhar_id_hash` blind index | test_05 |
| GAP-STD-05 | Zero FormRequests for student create routes | **CONFIRMED** — inline validation only | test_06 |
| BUG-STD-11 | `current_flag` not GENERATED STORED | **CONFIRMED** — migration creates plain nullable INT | test_07 |
| ARCH-STD-13 | Student model imports downstream modules | **CONFIRMED** | test_08 |
| DDL-STD-12 | SoftDeletes missing from 4 tables | **REMEDIATED at table level** (`deleted_at` added by migrations); **models lack trait** (residual) | test_04 |
| DEV-STD-CRE-01 | `first_name` validation max:100 vs DDL `VARCHAR(50)` | CONFIRMED mismatch (truncation risk) | test_38 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01/02/03/04 | DDL | Tables & columns correct | All present | test_01 | Automated |
| TC-P02 | Schema | BC-DB-01 | Migr | Create migrations exist (glob) | Found | test_02 | Automated |
| TC-P03 | Model | BC-DB-02/03 | Model | Tables/traits/fillable | Match | test_03 | Automated |
| TC-P10 | UI | BC-AUTH-03 | View | Wizard entry renders | `#student-login` present | test_10 | Automated |
| TC-P11 | UI | BC-VAL-01 | View | Registration fields present | 4 inputs present | test_11 | Automated |
| TC-P12 | Biz | BC-BIZ-01 | Ctrl | Valid login creates STUDENT user + emp_code | `STD-YYYY-NNNNNN` | test_12 | Automated |
| TC-P13 | Biz | BC-BIZ-02 | Ctrl | Valid details creates student+profile+address | Rows created | test_13 | Automated |
| TC-P14 | Biz | BC-BIZ | Ctrl | Previous education row created | Row created | test_14 | Automated |
| TC-P15 | Biz | BC-BIZ-03 | Ctrl | Health profile created | `blood_group=O+` | test_15 | Automated |
| TC-P16 | Biz | BC-BIZ-03 | Ctrl | Vaccination row created | Row created | test_16 | Automated |
| TC-P18 | Biz | BC-BIZ-04 | Ctrl | New guardian created | Guardian row | test_18 | Automated |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-N06 | Config | GAP-STD-05 | Audit | No FormRequest for create routes | Classes absent | test_06 | Automated |
| TC-N30 | Val | BC-VAL-01 | Ctrl | Login empty → rejected | 422/302 | test_30 | Automated |
| TC-N31 | Val | BC-VAL-01 | Ctrl | Login duplicate email → rejected | 422/302 | test_31 | Automated |
| TC-N32 | Val | BC-VAL-01 | Ctrl | Password min8/confirmed enforced | 422/302 | test_32 | Automated |
| TC-N33 | Val | BC-VAL-01 | Ctrl | Invalid status enum → rejected | 422/302 | test_33 | Automated |
| TC-N34 | Val | BC-VAL-02 | Ctrl | Details missing req → rejected | 422/302/500 | test_34 | Automated |
| TC-N35 | Val | BC-VAL-02 | Ctrl | Duplicate admission_no → rejected | 422/302 | test_35 | Automated |
| TC-N36 | Val | BC-VAL-05 | Ctrl | Invalid blood_group → rejected | 422/302 | test_36 | Automated |
| TC-N37 | Val | BC-VAL-06 | Ctrl | Vacc date order → rejected | 422/302 | test_37 | Automated |
| TC-N38 | Val | DEV-STD-CRE-01 | Cross-ref | first_name max100 vs col50 | Ceiling proven | test_38 | Automated |
| TC-N40 | FK | BC-VAL-02 | Ctrl | Invalid user_id → rejected | 422/302 | test_40 | Automated |
| TC-N50 | Auth | BC-AUTH-04 | Mw | Guest redirected to /login | `/login` | test_50 | Automated |

### Dependency / Security / Tenancy (TC-D / TC-S / TC-T)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-D04 | Soft-del | DDL-STD-12 | Audit | deleted_at present on 4 tables; models lack trait | Proven | test_04 | Automated |
| TC-S05 | Security | SEC-STD-03 | Audit | Aadhar encrypted cast + hash | Present | test_05 | Automated |
| TC-D07 | Integrity | BUG-STD-11 | Audit | current_flag plain INT (not generated) | Not GENERATED | test_07 | Automated |
| TC-D08 | Arch | ARCH-STD-13 | Audit | Downstream imports present | Present | test_08 | Automated |
| TC-S09 | Security | SEC-STD-02 | Audit | Create routes registered, tenant.* gates | No school-setup prefix | test_09 | Automated |
| TC-D17 | Integration | BC-BIZ-04 | Ctrl | Existing guardian link | Accepted status | test_17 | Automated |
| TC-D41 | FK | BC-REF-01 | DDL | user_id FK CASCADE | CASCADE | test_41 | Automated |
| TC-D42 | FK | BC-DB-04 | DDL | junction unique index | Present | test_42 | Automated |
| TC-AUTH51 | Auth | BC-AUTH-01/02 | Ctrl | Create-flow gate strings | Present | test_51 | Automated |
| TC-T90 | Tenancy | BC-AUTH-03 | Tenancy | Student scoped to tenant | Resolvable | test_90 | Automated |
| TC-T91 | Tenancy | — | Tenancy | Cross-tenant isolation | Skip if single | test_91 | Automated |
| TC-S92 | Security | SEC-STD-01 | Audit | is_super_admin not escalated | Not escalated | test_92 | Automated |
| TC-S93 | Security | SEC-STD-01 | Audit | View still renders toggle (residual) | Present | test_93 | Automated |
| TC-S94 | Security | — | XSS | Reflected XSS not echoed | Not present | test_94 | Automated |

---

## 3. Test Method Index (single file: `std_StudentCreate_TestCas.php`)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_studentcreate_01_schema_tables_and_columns_are_correct | TC-P01 | Schema | 01–09 |
| 2 | test_studentcreate_02_create_migration_files_exist | TC-P02 | Schema | 01–09 |
| 3 | test_studentcreate_03_models_tables_traits_and_fillable | TC-P03 | Model | 01–09 |
| 4 | test_studentcreate_04_ddl_std12_softdelete_column_state | TC-D04 | Soft-delete | 01–09 |
| 5 | test_studentcreate_05_sec_std03_aadhar_encrypted_cast_present | TC-S05 | Security | 01–09 |
| 6 | test_studentcreate_06_gap_std05_no_formrequests_for_create_routes | TC-N06 | Config | 01–09 |
| 7 | test_studentcreate_07_bug_std11_current_flag_not_generated | TC-D07 | Integrity | 01–09 |
| 8 | test_studentcreate_08_arch_std13_student_imports_downstream_modules | TC-D08 | Arch | 01–09 |
| 9 | test_studentcreate_09_sec_std02_create_routes_registered_with_tenant_gates | TC-S09 | Security | 01–09 |
| 10 | test_studentcreate_10_create_page_loads_wizard | TC-P10 | UI | 10–19 |
| 11 | test_studentcreate_11_registration_tab_fields_present | TC-P11 | UI | 10–19 |
| 12 | test_studentcreate_12_valid_login_creates_student_user | TC-P12 | Biz | 10–19 |
| 13 | test_studentcreate_13_valid_details_creates_student_profile_address | TC-P13 | Biz | 10–19 |
| 14 | test_studentcreate_14_valid_previous_education_creates_record | TC-P14 | Biz | 10–19 |
| 15 | test_studentcreate_15_valid_health_creates_profile | TC-P15 | Biz | 10–19 |
| 16 | test_studentcreate_16_valid_vaccination_creates_record | TC-P16 | Biz | 10–19 |
| 17 | test_studentcreate_17_parent_existing_guardian_links_jnt | TC-D17 | Integration | 10–19 |
| 18 | test_studentcreate_18_parent_new_guardian_creates_guardian | TC-P18 | Biz | 10–19 |
| 19 | test_studentcreate_30_login_missing_required_rejected | TC-N30 | Val | 30–39 |
| 20 | test_studentcreate_31_login_duplicate_email_rejected | TC-N31 | Val | 30–39 |
| 21 | test_studentcreate_32_login_password_rules_enforced | TC-N32 | Val | 30–39 |
| 22 | test_studentcreate_33_login_invalid_status_rejected | TC-N33 | Val | 30–39 |
| 23 | test_studentcreate_34_details_missing_required_rejected | TC-N34 | Val | 30–39 |
| 24 | test_studentcreate_35_details_duplicate_admission_no_rejected | TC-N35 | Val | 30–39 |
| 25 | test_studentcreate_36_health_invalid_blood_group_rejected | TC-N36 | Val | 30–39 |
| 26 | test_studentcreate_37_vaccination_date_order_enforced | TC-N37 | Val | 30–39 |
| 27 | test_studentcreate_38_first_name_length_vs_ddl_column | TC-N38 | Val | 30–39 |
| 28 | test_studentcreate_40_details_invalid_user_id_rejected | TC-N40 | FK | 40–49 |
| 29 | test_studentcreate_41_student_user_fk_is_cascade | TC-D41 | FK | 40–49 |
| 30 | test_studentcreate_42_guardian_jnt_unique_index_present | TC-D42 | FK | 40–49 |
| 31 | test_studentcreate_50_guest_redirected_to_login | TC-N50 | Auth | 50–59 |
| 32 | test_studentcreate_51_create_flow_gate_strings | TC-AUTH51 | Auth | 50–59 |
| 33 | test_studentcreate_90_created_student_scoped_to_current_tenant | TC-T90 | Tenancy | 90–99 |
| 34 | test_studentcreate_91_cross_tenant_isolation | TC-T91 | Tenancy | 90–99 |
| 35 | test_studentcreate_92_sec_std01_is_super_admin_not_escalated | TC-S92 | Security | 90–99 |
| 36 | test_studentcreate_93_sec_std01_view_still_renders_toggle | TC-S93 | Security | 90–99 |
| 37 | test_studentcreate_94_xss_name_not_reflected_unescaped | TC-S94 | Security | 90–99 |

**Total: 37 methods, one file.**
