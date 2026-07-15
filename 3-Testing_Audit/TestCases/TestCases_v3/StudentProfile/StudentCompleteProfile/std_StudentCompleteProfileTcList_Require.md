# std_StudentCompleteProfile — Test Case List & Business Conditions

**Module:** StudentProfile (CODE `STD`, prefix `std_`) · **Feature:** StudentCompleteProfile (read/composite screen)
**Primary table:** `std_students` (DDL `StudentProfile_DDL_v1.6.sql`, `Database: tenant_db`) · **DB scope:** TENANT
**Controller:** `Modules\StudentProfile\Http\Controllers\StudentController`
**URL prefix:** `/student-profile` · **Test style:** Browser Dusk (`extends DuskTestCase`), mirrors committed sibling `spr_StudentCompleteProfile_TestCas.php`
**Test file:** `std_StudentCompleteProfile_TestCas.php` (ONE file, 27 methods)

> Feature scope = the student **complete-profile resume redirect** + **show()** composite view + **printIdCard()** + **export()** + **sendCredentials()** + **getFilterDependencies()**. No create/edit/delete matrix — those live in StudentCreate / StudentEdit.

---

## 1. Business Conditions

### BC-DB (schema truth — `DDL-std_students`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-1 | `std_students` PK `id`, columns `user_id, admission_no, admission_date, student_qr_code, student_id_card_type, smart_card_id, aadhar_id, apaar_id, birth_cert_no, first_name, middle_name, last_name, gender, dob, current_status_id, is_active, note, deleted_at` | DDL-std_students:46 |
| BC-DB-2 | Unique keys: `admission_no`, `user_id`, `aadhar_id`; FK `user_id → sys_users ON DELETE CASCADE` | DDL-std_students |
| BC-DB-3 | `student_qr_code VARCHAR(20)` — DDL comment: *"saved as emp_code in sys_users"* | DDL-std_students |
| BC-DB-4 | `student_id_card_type ENUM('QR','RFID','NFC','Barcode') DEFAULT 'QR'` | DDL-std_students |
| BC-DB-5 | Composite-read dependency tables exist: `std_student_profiles, std_student_addresses, std_guardians, std_student_guardian_jnt, std_student_academic_sessions, std_previous_education, std_student_documents, std_health_profiles` | DDL |
| BC-DB-6 | Model: table `std_students`, `SoftDeletes`, `aadhar_id` cast `encrypted`, fillable includes `admission_no/student_qr_code/aadhar_id`, `full_name` accessor | Student.php:28-57,208 |

### BC-BIZ (business rules — resume ladder, `getNextIncompleteTabForCreate`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-1 | No `user_id`/user OR missing `admission_no`/`first_name`/`dob` → resume `student_details` (login-only) / `student_login_details` | Controller:4030 / Screen-BR |
| BC-BIZ-2 | Details complete, no guardians → `parent_details` | Controller:4040 |
| BC-BIZ-3 | Has guardians, no session → `session_details` | Controller:4044 |
| BC-BIZ-4 | Has session, no previous education → `student_previous_education` | Controller:4048 |
| BC-BIZ-5 | Has prev-edu, no health profile → `student_health` | Controller:4052 |
| BC-BIZ-6 | Fully complete → fallback `student_login_details` | Controller:4056 |
| BC-BIZ-7 | `completeProfile()` redirects to `editStudentDetails` with `student_id` + `user_id` + `activeTab` | Controller:4017 |
| BC-BIZ-8 | Flow must not throw 500 for missing related records | Screen-Stability |
| BC-BIZ-9 | `show()` eager-loads composite relation set (guardians.user, healthProfile, previousEducations, documents.documentType, addresses.city, sessions.*) | Controller:283 |

### BC-VAL (validation)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-1 | `sendCredentials`: `students` required array, `students.*` exists:sys_users, `password_option` required in `existing,reset,custom`, `custom_password` required_if custom min:6 | Controller:3623 |
| BC-VAL-2 | `export($type)` default branch returns `Invalid export type` for unknown type | Controller:4162 |

### BC-AUTH (authorization)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-1 | `show()`/`printIdCard()` gate `tenant.student.view`; `completeProfile()`/`sendCredentials()` gate `tenant.student.update`; `export()` gate `tenant.student.export` | Controller:281,319,4019,3621,4061 |
| BC-AUTH-2 | `StudentPolicy::view()` = `tenant.student.view` OR own student record OR linked parent's child | StudentPolicy:21 |
| BC-AUTH-3 | Guest → redirect `/login`; all routes wrapped in `module:STUDENT` guard | web.php:12 |

### BC-INT (integration / related-data display)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-1 | `show()` renders Profile Overview with `admission_no` | show.blade.php:14-16 |
| BC-INT-2 | `show()` renders 7 tabs: `#basic #profile #parent #academic #address #medical #documents` | show.blade.php:186-263 |
| BC-INT-3 | `printIdCard()` renders id-card shell (`#id-card-content`, toolbar) via `Template::render('STUDENT_ID_CARD')` | printIdCard:334 / id-card.blade.php:80 |

### BC-EDG (edge)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-1 | Non-existent student id → 404 (route-model binding), never a 200 profile | Route binding |
| BC-EDG-2 | `printIdCard()` catches `\Exception` → redirect index with `Cannot generate ID card` | printIdCard:341 |

### BC-SEC / TC-T (tenancy & security — mandatory P0/P1)
| ID | Condition | Source |
|----|-----------|--------|
| BC-SEC-1 | All routes tenant-module guarded (`module:STUDENT`) | web.php:12 |
| BC-SEC-2 | Cross-tenant / foreign student id on `printIdCard` must not return 200 (IDOR) | Route binding |
| BC-SEC-3 | Export `search` term is not reflected unescaped (reflected-XSS smoke) | export:4063 |

### Known Source Defects (audit-mapped)
| ID | Finding | Proof method | Current-source note |
|----|---------|--------------|---------------------|
| GAP-STD-25 | ID-card exposes `admission_no` (and `aadhar_id`, `student_qr_code`) as **raw plaintext** template variables — no hash/UUID | `test_80` | `StudentIdCardDataProvider::provide()` builds raw keys (`admission_no`, `aadhar_id`, `student_qr_code`) with no hashing/UUID; QR value = user `emp_code` |
| PERF-STD-10 | Synchronous export memory/timeout risk on large datasets | `test_81` | **Partly remediated:** excel/csv now `Excel::queue` + `StudentsExport implements ShouldQueue`; the **PDF** branch is still synchronous (`->get()` full-load + inline `->download()`) |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-1..6 | DDL/Model | Schema, model config, relations, routes all correct | All asserts pass | `test_..._01` | Ready |
| TC-P10 | BC-BIZ-1 | Screen-BR | Login-only student resumes `student_details` | `activeTab=student_details` | `test_..._10` | Ready |
| TC-P11 | BC-BIZ-2 | Screen-BR | No guardians → `parent_details` | `activeTab=parent_details` | `test_..._11` | Ready |
| TC-P12 | BC-BIZ-3 | Screen-BR | No session → `session_details` | `activeTab=session_details` | `test_..._12` | Ready |
| TC-P13 | BC-BIZ-4 | Screen-BR | No prev-edu → `student_previous_education` | matches | `test_..._13` | Ready |
| TC-P14 | BC-BIZ-5 | Screen-BR | No health → `student_health` | matches | `test_..._14` | Ready |
| TC-P15 | BC-BIZ-6 | Screen-BR | Fully complete → `student_login_details` | matches | `test_..._15` | Ready |
| TC-P16 | BC-BIZ-7 | Controller | Redirect URL carries `student_id`/`user_id` | present in URL | `test_..._16` | Ready |
| TC-P17 | BC-BIZ-8 | Stability | No 500 across 8 students | no `Whoops` | `test_..._17` | Ready |
| TC-P40 | BC-INT-1 | Blade | show() renders overview + admission_no | present | `test_..._40` | Ready |
| TC-P41 | BC-INT-2 | Blade | show() exposes 7 detail tabs | all present | `test_..._41` | Ready |
| TC-P42 | BC-BIZ-9 | Controller | show() eager-loads composite relations | all present | `test_..._42` | Ready |
| TC-P50 | BC-AUTH-1 | Controller | Actions gated by correct abilities | all present | `test_..._50` | Ready |
| TC-P60 | BC-UIX | Blade | Index exposes row actions/export | present | `test_..._60` | Ready |
| TC-P61 | BC-INT-3 | Blade | printIdCard renders card shell | present | `test_..._61` | Ready |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N30 | BC-VAL-1 | Controller | sendCredentials missing password_option | 422 (or 403/404 gated) | `test_..._30` | Ready |
| TC-N31 | BC-VAL-2 | Controller | export invalid type rejected | default `Invalid export type` | `test_..._31` | Ready |
| TC-N51 | BC-AUTH-2 | Policy | Policy view() scopes to owner/parent | asserts | `test_..._51` | Ready |
| TC-N52 | BC-AUTH-3 | web.php | Guest redirected to /login | `/login` | `test_..._52` | Ready |
| TC-N62 | BC-EDG-2 | Controller | printIdCard fails soft on template error | redirect + error | `test_..._62` | Ready |

### Edge / Dependency (TC-E)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-E70 | BC-EDG-1 | Binding | Missing student id → 404 | not 200 | `test_..._70` | Ready |
| TC-E71 | BC-BIZ-1..6 | Controller | Resume ladder covers all 6 states | all present | `test_..._71` | Ready |

### Defects (audit-mapped)
| TC ID | Defect | Description | Expected | Method | Status |
|-------|--------|-------------|----------|--------|--------|
| TC-S80 | GAP-STD-25 | id-card exposes raw admission_no/aadhar/qr | raw keys, no hash/uuid | `test_..._80` | Ready |
| TC-N81 | PERF-STD-10 | export sync(pdf) vs queue(excel/csv) | ShouldQueue + queue + pdf download | `test_..._81` | Ready |

### Tenancy / Security (TC-T / TC-S)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-T90 | BC-SEC-1 | web.php | Routes tenant-module guarded | `module:STUDENT` | `test_..._90` | Ready |
| TC-T91 | BC-SEC-2 | Binding | Cross-tenant id-card not leaked (IDOR) | not 200 | `test_..._91` | Ready |
| TC-S92 | BC-SEC-3 | export | Export search not reflected unescaped | payload absent | `test_..._92` | Ready |

---

## 3. Test Method Index (semantic bands)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_complete_profile_01_schema_model_and_routes_are_correct` | TC-P01 | Schema/config | 01-09 |
| 2 | `test_complete_profile_10_login_only_redirects_to_student_details` | TC-P10 | Business rule | 10-19 |
| 3 | `test_complete_profile_11_no_guardians_redirects_to_parent_details` | TC-P11 | Business rule | 10-19 |
| 4 | `test_complete_profile_12_no_session_redirects_to_session_details` | TC-P12 | Business rule | 10-19 |
| 5 | `test_complete_profile_13_no_prev_edu_redirects_to_prev_edu` | TC-P13 | Business rule | 10-19 |
| 6 | `test_complete_profile_14_no_health_redirects_to_health` | TC-P14 | Business rule | 10-19 |
| 7 | `test_complete_profile_15_all_complete_redirects_to_login_tab` | TC-P15 | Business rule | 10-19 |
| 8 | `test_complete_profile_16_redirect_url_has_student_and_user_ids` | TC-P16 | Business rule | 10-19 |
| 9 | `test_complete_profile_17_no_500_for_any_state` | TC-P17 | Business rule | 10-19 |
| 10 | `test_complete_profile_30_send_credentials_requires_password_option` | TC-N30 | Validation | 30-39 |
| 11 | `test_complete_profile_31_export_invalid_type_is_rejected` | TC-N31 | Validation | 30-39 |
| 12 | `test_complete_profile_40_show_renders_profile_overview` | TC-P40 | Integration | 40-49 |
| 13 | `test_complete_profile_41_show_exposes_all_detail_tabs` | TC-P41 | Integration | 40-49 |
| 14 | `test_complete_profile_42_show_eager_loads_composite_relations` | TC-P42 | Integration | 40-49 |
| 15 | `test_complete_profile_50_actions_are_gated_by_correct_abilities` | TC-P50 | Permissions | 50-59 |
| 16 | `test_complete_profile_51_policy_view_scopes_to_owner_and_parent` | TC-N51 | Permissions | 50-59 |
| 17 | `test_complete_profile_52_guest_is_redirected_to_login` | TC-N52 | Permissions | 50-59 |
| 18 | `test_complete_profile_60_index_exposes_row_actions` | TC-P60 | UI/UX | 60-69 |
| 19 | `test_complete_profile_61_print_id_card_renders_card_shell` | TC-P61 | UI/UX | 60-69 |
| 20 | `test_complete_profile_62_print_id_card_fails_soft_on_template_error` | TC-N62 | UI/UX | 60-69 |
| 21 | `test_complete_profile_70_missing_student_returns_404` | TC-E70 | Edge | 70-79 |
| 22 | `test_complete_profile_71_next_tab_ladder_covers_all_states` | TC-E71 | Edge | 70-79 |
| 23 | `test_complete_profile_80_id_card_exposes_raw_admission_no_defect` | TC-S80 / GAP-STD-25 | Defect | 80-89 |
| 24 | `test_complete_profile_81_export_sync_vs_queue_behaviour_defect` | TC-N81 / PERF-STD-10 | Defect | 80-89 |
| 25 | `test_complete_profile_90_routes_are_tenant_module_guarded` | TC-T90 | Tenancy | 90-99 |
| 26 | `test_complete_profile_91_cross_tenant_show_is_not_leaked` | TC-T91 | Tenancy/IDOR | 90-99 |
| 27 | `test_complete_profile_92_export_search_is_not_reflected_unescaped` | TC-S92 | Security/XSS | 90-99 |
