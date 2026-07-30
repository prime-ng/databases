# std_StudentCreate — Test Case List & Business Conditions

**Module:** StudentProfile (CODE `STD`, prefix `std_`) · **Feature:** Student Create (multi-tab onboarding wizard)
**DB scope:** TENANT-side (`std_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `std_students` (DDL `StudentProfile_DDL_v1.6.sql`, `Database: tenant_db`) · **Module URL prefix:** `/student-profile`
**Test file:** `std_StudentCreate_TestCas.php`
**Checklists applied:** `Gaurav_list.md` + `Shailesh_list.md`

Wizard tabs → controller create methods (all in `StudentController`):
`createStudentLogin` (Registration) → `createStudentDetails` (Student Detail + Profile + Address) →
`createParentDetails` (Parents/Guardians) → `createStudentSession` (Session) →
`createStudentPrevEduDetails` (Previous Education) → `createStudentMedicalDetails` (Health/Vaccination).

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
| BC-DB-06 | `std_students` columns: id, user_id, admission_no, admission_date, student_qr_code, student_id_card_type, smart_card_id, aadhar_id, apaar_id, birth_cert_no, first_name, middle_name, last_name, gender, dob, current_status_id, is_active, note, deleted_at | DDL-std_students |
| BC-DB-07 | `student_id_card_type ENUM('QR','RFID','NFC','Barcode') DEFAULT 'QR'` | DDL-std_students |
| BC-DB-08 | Model: table `std_students`, `SoftDeletes`, `aadhar_id` cast `encrypted`, fillable includes `admission_no/student_qr_code/aadhar_id`, `full_name` accessor | Student.php:28-57,208 |

### BC-VAL — Validation (Source: inline `$request->validate` / `Validator::make` in `StudentController`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | Login: `name` req max255; `short_name` req unique `sys_users`; `email` req email unique; `password` req min8 confirmed; `status` req in `ACTIVE,INVITED,DISABLED` | Ctrl:594-605 |
| BC-VAL-02 | Details: `user_id` req exists `sys_users`; `admission_no` req max50 unique `std_students`; `admission_date` req date; `first_name` req max100; `dob` req date; `current_status_id` req integer; `apaar_id` nullable string max100 | Ctrl:778-809 |
| BC-VAL-03 | Details aadhar uniqueness enforced on `aadhar_id_hash` (blind index), not raw value | Ctrl:784 |
| BC-VAL-04 | Parent: `student_id` req exists; `guardians`/`relationships` req arrays; new guardian requires `first_name,gender,mobile_no,short_name,password(min8)` | Ctrl:1375-1388 |
| BC-VAL-05 | Health: `blood_group` in `A+,A-,B+,B-,AB+,AB-,O+,O-`; height_cm 0–300, weight_kg 0–300 (medical tab); measurement_date nullable date | Ctrl:2708-2731 |
| BC-VAL-06 | Vaccination: `next_due_date.*` `after_or_equal:date_administered.*` | Ctrl:2731 |
| BC-VAL-07 | New-guardian duplicate mobile → error `Mobile number already registered to another guardian.` | Ctrl:1483 |
| BC-VAL-08 | Details tab: height_cm min:30 max:300, weight_kg min:1 max:500, measurement_date required_with height/weight (FRD BR-STD-007); medical tab has looser 0-300 bounds and no required_with — **inconsistent** | Ctrl:820-822 vs 2729-2731 |
| BC-VAL-09 | Guardian completeness: at least one guardian required per student (BR-STD-010) — enforced in controller | Ctrl:1574 |
| BC-VAL-10 | APAAR ID: validation is `nullable|string|max:100` only — **missing** exact 12-digit rule per BR-STD-005 (gap) | Ctrl:799 |
| BC-VAL-11 | Session: `academic_session_id` req; `class_section_id` req; `session_status_id` req; `opted_subjects` nullable array; `opted_subjects.*.subject_id` req exists `sch_subjects`; `study_format_id` req; `is_core` req boolean | Ctrl:1798-1814 |
| BC-VAL-12 | Documents: `documents` nullable array; `documents.*.document_name` nullable string max100; `documents.*.document_type_id` nullable exists `sys_dropdown_table`; `documents.*.issue_date` nullable date; `documents.*.expiry_date` nullable date after_or_equal:issue_date; `documents.*.is_verified` nullable boolean; `documents.*.verified_by` nullable exists `sys_users`; `documents.*.verification_date` nullable date; `documents.*.student_document` nullable file mimes:pdf,jpg,jpeg,png,doc,docx max:2048 | Ctrl:2091-2103 |
| BC-VAL-13 | Document verification: `verified_by` and `verification_date` are nullable even when `is_verified=1` — **missing required_if** (gap) | Ctrl:2098-2100 |
| BC-VAL-14 | Document uniqueness: no validation preventing duplicate `document_name` + `document_type_id` per student — **missing** (gap) | Ctrl:2137-2169 |
| BC-VAL-15 | Vaccination uniqueness: no validation preventing duplicate `vaccine_name` per student — **missing** (gap) | Ctrl:2806-2832 |

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
| BC-BIZ-05 | Session creates `std_student_academic_sessions` row; opted subjects saved and linked to session | Ctrl:1830-1875 |
| BC-BIZ-06 | Documents created in foreach loop; file upload via media library; old documents deleted if removed from DOM | Ctrl:2136-2170 |
| BC-BIZ-07 | Previous education record created | Ctrl:2044 |

### BC-INT / BC-REF — Integration / Related-Data Display
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `std_students.user_id` → `sys_users` ON DELETE CASCADE | DDL-std_students |
| BC-INT-01 | Student model reverse-couples `StudentFee`, `Transport`, `StudentPortal` (ARCH-STD-13) | Student.php:13,16,18 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-03 | Session missing required fields → rejected with 422 | Ctrl:1798-1803 |
| BC-EDG-04 | Document file upload invalid MIME type → rejected | Ctrl:2103 |
| BC-EDG-05 | Invalid subject_id in opted_subjects → rejected | Ctrl:1811 |

### BC-SEC — Security
| ID | Condition | Source |
|----|-----------|--------|
| BC-SEC-01 | All routes tenant-module guarded (`module:STUDENT`) | web.php:12 |
| BC-SEC-04 | QR Code payload must not contain raw Admission Number (BR-STD-006) — currently uses `emp_code` = `STD-YYYY-NNNNNN`; distinct from admission_no but predictable sequential | Ctrl:572-588 |
| BC-SEC-05 | Fee payer flag: at most one guardian with Is Fee Payer = Yes per student (BR-STD-012) — **not enforced** (gap) | Ctrl:1562 |
| BC-SEC-06 | XSS: `<script>` payload in `name` → escaped in Blade output | View |
| BC-SEC-07 | `is_super_admin` toggle should NOT appear anywhere on tenant views | View |

### Known Source Defects (audit-mapped)
| ID | Finding | Current state | Proving test |
|----|---------|--------------|--------------|
| SEC-STD-01 | `is_super_admin` mass-assignment escalation via login | **REMEDIATED** in controller (field no longer whitelisted); **view toggle should be absent** (confirmed removed) | test_92, test_93 |
| SEC-STD-02 | Wrong Gate prefix `school-setup.student.*` | **REMEDIATED** — no such prefix remains; create-flow uses `tenant.*` | test_09 |
| SEC-STD-03 | Aadhar plaintext | **REMEDIATED** — `aadhar_id` `encrypted` cast + `aadhar_id_hash` blind index | test_05 |
| GAP-STD-05 | Zero FormRequests for student create routes | **CONFIRMED** — inline validation only | test_06 |
| BUG-STD-11 | `current_flag` not GENERATED STORED | **CONFIRMED** — migration creates plain nullable INT | test_07 |
| ARCH-STD-13 | Student model imports downstream modules | **CONFIRMED** — Student.php couples Fee, Transport, Portal | test_08 |
| DDL-STD-12 | SoftDeletes missing from 4 tables | **REMEDIATED at table level** (`deleted_at` added by migrations); **models lack trait** (residual) | test_04 |
| DEV-STD-CRE-01 | `first_name` validation max:100 vs DDL `VARCHAR(50)` | CONFIRMED mismatch (truncation risk) | test_38 |

---

## 2. Test Case List

### Step 1: Registration (Tab 1 — createStudentLogin)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P10 | BC-AUTH-03 | View | Wizard entry page loads | `#student-login` present | test_studentcreate_10 | Automated |
| TC-P11 | BC-VAL-01 | View | Registration form fields present | 4 inputs present | test_studentcreate_11 | Automated |
| TC-P12 | BC-BIZ-01 | Ctrl | Valid login creates STUDENT user + emp_code | `STD-YYYY-NNNNNN` | test_studentcreate_12 | Automated |
| TC-N30 | BC-VAL-01 | Ctrl | Login empty fields → rejected | 422/302 | test_studentcreate_30 | Automated |
| TC-N31 | BC-VAL-01 | Ctrl | Login duplicate email → rejected | 422/302 | test_studentcreate_31 | Automated |
| TC-N32 | BC-VAL-01 | Ctrl | Password min8/confirmed enforced | 422/302 | test_studentcreate_32 | Automated |
| TC-N33 | BC-VAL-01 | Ctrl | Invalid status enum → rejected | 422/302 | test_studentcreate_33 | Automated |
| TC-S09 | SEC-STD-02 | Audit | All gates use `tenant.*` prefix (no `school-setup.*`) | No stale prefix | test_studentcreate_09 | Automated |
| TC-AUTH51 | BC-AUTH-01 | Ctrl | Gate strings present on create flow methods | tenant.student.create | test_studentcreate_51 | Automated |
| TC-S92 | SEC-STD-01 | Audit | `is_super_admin` not escalated via login creation | Value not stored as 1 | test_studentcreate_92 | Automated |
| TC-S93 | SEC-STD-01 | Audit | `is_super_admin` toggle should NOT appear on tenant views | Toggle absent | test_studentcreate_93 | Automated |
| TC-S94 | BC-SEC-06 | View | XSS: `<script>` in name field escaped in output | Not rendered as HTML | test_studentcreate_94 | Automated |

### Step 2: Student Details + Address (Tab 2 — createStudentDetails)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P13 | BC-BIZ-02 | Ctrl | Valid details creates student+profile+address | 3 rows created | test_studentcreate_13 | Automated |
| TC-S05 | SEC-STD-03 | Audit | Aadhar encrypted cast + blind index present | Cast=encrypted, hash column | test_studentcreate_05 | Automated |
| TC-N34 | BC-VAL-02 | Ctrl | Details missing required → rejected | 422/302 | test_studentcreate_34 | Automated |
| TC-N35 | BC-VAL-02 | Ctrl | Duplicate admission_no → rejected | 422/302 | test_studentcreate_35 | Automated |
| TC-N38 | DEV-STD-CRE-01 | Cross-ref | first_name max100 vs DDL col50 | Mismatch proven | test_studentcreate_38 | Automated |
| TC-N40 | BC-VAL-02 | Ctrl | Invalid user_id → rejected | 422/302 | test_studentcreate_40 | Automated |
| TC-D41 | BC-REF-01 | DDL | Student.user_id FK → sys_users ON DELETE CASCADE | CASCADE | test_studentcreate_41 | Automated |

### Step 3: Parents / Guardians (Tab 3 — createParentDetails)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-D17 | BC-BIZ-04 | Ctrl | Existing guardian links via junction | Junction record created | test_studentcreate_17 | Automated |
| TC-P18 | BC-BIZ-04 | Ctrl | New guardian creates guardian row + portal user | Guardian + user rows | test_studentcreate_18 | Automated |
| TC-D42 | BC-DB-04 | DDL | Junction UNIQUE index on (student_id, guardian_id) | Index present | test_studentcreate_42 | Automated |
| TC-N51 | BC-VAL-09 | Ctrl | Guardian completeness: at least one guardian required | Exception thrown | test_studentcreate_51 | Planned |

### Step 4: Session + Optional Subjects (Tab 4 — createStudentSession)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P19 | BC-BIZ-05, BC-VAL-11 | Ctrl | Valid session created with academic_year, class_section, roll_no, status | Session row created | Planned |
| TC-P20 | BC-BIZ-05 | Ctrl | Optional subjects can be selected and saved with session | opted_subjects saved | Planned |
| TC-P21 | BC-BIZ-05 | Ctrl | Each opted subject stores subject_id, study_format_id, is_core | All fields saved | Planned |
| TC-D07 | BUG-STD-11 | Audit | `current_flag` is plain INT, not GENERATED STORED | Not generated | test_studentcreate_07 | Automated |
| TC-N52 | BC-EDG-03 | Ctrl | Session missing required fields (academic_session_id, class_section_id, session_status_id) → rejected | 422/302 | Planned |
| TC-N53 | BC-EDG-05 | Ctrl | Invalid subject_id in opted_subjects → rejected | 422 | Planned |

### Step 5: Previous Education (Tab 5 — createStudentPrevEduDetails)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P14 | BC-BIZ-07 | Ctrl | Valid previous education record created | Row created | test_studentcreate_14 | Automated |

### Step 6: Documents (Tab 6 — create/update student documents)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P22 | BC-BIZ-06 | Ctrl | Multiple documents can be added for one student | 2+ document rows created | Planned |
| TC-P23 | BC-BIZ-06 | Ctrl | Document saved with document_name, document_type_id, issue_date, expiry_date, file upload | All fields stored | Planned |
| TC-N54 | BC-VAL-14 | Ctrl | Duplicate document_name + document_type_id for same student → rejected | Uniqueness enforced | Planned |
| TC-N55 | BC-VAL-13 | Ctrl | `is_verified=true` but `verified_by` and `verification_date` missing → should be required | required_if enforced | Planned |
| TC-N57 | BC-VAL-12 | Ctrl | Invalid document_type_id (not in sys_dropdown_table) → rejected | 422 | Planned |
| TC-N56 | BC-EDG-04 | Ctrl | File upload invalid MIME type (not pdf/jpg/png/doc) → rejected | 422 | Planned |

### Step 7: Health Profile + Vaccination (Tab 7 — createStudentMedicalDetails)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P15 | BC-BIZ-03 | Ctrl | Health profile created with blood_group | blood_group=O+ | test_studentcreate_15 | Automated |
| TC-P16 | BC-BIZ-03 | Ctrl | Vaccination row created | Row created | test_studentcreate_16 | Automated |
| TC-P17 | BC-BIZ-03 | Ctrl | Multiple vaccination records can be added for same student | 2+ vaccine rows | Planned |
| TC-N36 | BC-VAL-05 | Ctrl | Invalid blood_group → rejected | 422/302 | test_studentcreate_36 | Automated |
| TC-N37 | BC-VAL-06 | Ctrl | Vaccination date order: next_due >= administered → enforced | 422/302 | test_studentcreate_37 | Automated |
| TC-N39 | BC-VAL-08 | Ctrl | height_cm/weight_kg range mismatch: details tab (30-300/1-500) vs medical tab (0-300/0-300); medical missing required_with | Inconsistency proven | Planned |
| TC-N58 | BC-VAL-15 | Ctrl | Duplicate vaccine_name for same student → should be rejected | Uniqueness enforced | Planned |

### Cross-Cutting (applies to all steps)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/02/03/04/06/07/08 | DDL/Model | Schema, tables, columns, model config correct | All asserts pass | test_studentcreate_01 | Automated |
| TC-P02 | BC-DB-01 | Migration | Create migration files exist | Found | test_studentcreate_02 | Automated |
| TC-P03 | BC-DB-02/03 | Model | Models: tables, traits, fillable match DDL | Match | test_studentcreate_03 | Automated |
| TC-D04 | DDL-STD-12 | Audit | deleted_at present on 4 tables; models lack trait | Proven | test_studentcreate_04 | Automated |
| TC-D08 | ARCH-STD-13 | Audit | Student model imports downstream modules | Present | test_studentcreate_08 | Automated |
| TC-N06 | GAP-STD-05 | Audit | No FormRequest for create routes (inline validation only) | Classes absent | test_studentcreate_06 | Automated |
| TC-N50 | BC-AUTH-04 | Middleware | Guest redirected to /login | `/login` | test_studentcreate_50 | Automated |
| TC-T90 | BC-AUTH-03 | Tenancy | Created student scoped to current tenant | Resolvable | test_studentcreate_90 | Automated |
| TC-T91 | — | Tenancy | Cross-tenant isolation | Skip if single | test_studentcreate_91 | Automated |
| TC-N43 | BC-VAL-10 | Audit | APAAR ID validation missing exact 12-digit rule (gap) | Gap documented | Planned |
| TC-S95 | BC-SEC-04 | Audit | QR code payload = emp_code (sequential, partial BR-STD-006) | Payload analysis | Planned |
| TC-S96 | BC-SEC-05 | Audit | Fee payer at-most-one not enforced (BR-STD-012 gap) | Gap documented | Planned |

---

## 3. Test Method Index

### File: `std_StudentCreate_TestCas.php` (37 methods)
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

**Total: 37 methods.**

### Planned Additions (not yet automated)
| Planned Method | Maps To | Priority | Notes |
|----------------|---------|----------|-------|
| test_studentcreate_19_session_create | TC-P19 | Medium | Session create with academic_year, class_section, roll_no, status |
| test_studentcreate_20_optional_subjects_save | TC-P20 | Medium | Optional subjects selected and saved with session |
| test_studentcreate_21_opted_subject_fields | TC-P21 | Medium | Each opted subject: subject_id, study_format_id, is_core |
| test_studentcreate_22_document_create_multiple | TC-P22 | Medium | Multiple documents added for one student |
| test_studentcreate_23_document_fields_stored | TC-P23 | Medium | Document saved with name, type_id, issue_date, expiry_date, file |
| test_studentcreate_39_height_weight_range_inconsistency | TC-N39 | Medium | Details tab min:30/max:300 vs medical tab min:0/max:300; medical missing required_with |
| test_studentcreate_43_apaar_id_missing_12_digit_validation | TC-N43 | Low | Validation is `nullable\|string\|max:100` only; BR-STD-005 requires exactly 12 digits |
| test_studentcreate_51_guardian_completeness_enforced | TC-N51 | Medium | Ctrl:1574 enforces at least 1 guardian |
| test_studentcreate_52_session_missing_required | TC-N52 | Medium | Session missing academic_session_id, class_section_id, session_status_id → 422 |
| test_studentcreate_53_invalid_subject_id | TC-N53 | Medium | Invalid subject_id in opted_subjects → 422 |
| test_studentcreate_54_document_duplicate | TC-N54 | Medium | Duplicate document_name + document_type_id → rejected |
| test_studentcreate_55_document_verification_required_if | TC-N55 | Medium | is_verified=true requires verified_by + verification_date |
| test_studentcreate_56_document_invalid_mime | TC-N56 | Medium | File with invalid MIME type → 422 |
| test_studentcreate_57_document_invalid_type_id | TC-N57 | Medium | Invalid document_type_id → 422 |
| test_studentcreate_17_multiple_vaccination_records | TC-P17 | Medium | 2+ vaccination records for same student |
| test_studentcreate_58_vaccination_duplicate | TC-N58 | Low | Duplicate vaccine_name for same student → rejected |
| test_studentcreate_95_qr_code_payload_analysis | TC-S95 | Low | QR payload = emp_code (sequential, not admission_no) — partial BR-STD-006 |
| test_studentcreate_96_fee_payer_at_most_one_not_enforced | TC-S96 | Low | BR-STD-012 at-most-one fee payer not enforced |

---

*Generated per Gaurav_list.md (Model, Controller, FormRequests, Migration, Routes, Policy & Permission, Views) + Shailesh_list.md (Model, Controller, Form Requests, Migration, Routes, Policy & Permission, Views, Services, Requirements, Scheduler/Cron, Queue, Notifications) checklist standards. Scoped to `std_StudentCreate_TestCas.php` only.*
