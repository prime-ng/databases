# std_StudentCreate — Manual Testing Specification

## 1. Feature Information
| Item | Value |
|------|-------|
| Module | StudentProfile (`std_`) |
| Feature / Screen | Student Create — multi-tab onboarding wizard |
| DB scope | TENANT-side (`std_*`) |
| Entry URL | `GET /student-profile/student/edit/student/details?activeTab=student_login_details` |
| Controller | `Modules\StudentProfile\Http\Controllers\StudentController` |
| Create methods | `createStudentLogin`, `createStudentDetails`, `createStudentSession`, `createParentDetails`, `createStudentPrevEduDetails`, `createStudentMedicalDetails` |
| Models | Student, StudentProfile, StudentAddress, Guardian, StudentGuardianJnt, StudentAcademicSession, StudentOptedSubject, PreviousEducation, StudentDocument, StudentHealthProfile, VaccinationRecord |
| Validation | **Inline** (`$request->validate` / `Validator::make`) — GAP-STD-05: no FormRequest exists |
| Migrations | `database/migrations/tenant/*create_std_*` |
| CRUD type | Multi-step create wizard (AJAX/redirect per tab) |
| Soft delete | `std_students` yes; `std_health_profiles`/`std_vaccination_records`/`std_student_documents` have `deleted_at` column but **models lack SoftDeletes trait** (DDL-STD-12 residual) |
| Activity log | Not called on student create; `Student::booted` logs `pii_aadhar_updated` when aadhar changes |
| Prerequisite | Module **STUDENT must be enabled** in `prime_testing/modules_statuses.json` (else 404) |

## 2. Business Conditions (with error messages / flows)
- **Login (Registration tab):** `name`, `short_name` (unique `sys_users.short_name`), `email` (unique), `password` (min 8, confirmed), `status ∈ {ACTIVE,INVITED,DISABLED}` all required. On success: creates `sys_users` (`user_type=STUDENT`, `emp_code=STD-YYYY-NNNNNN`), assigns `Student` role, emails credentials, redirects to Student Detail tab.
- **Student Detail:** `user_id` (exists), `admission_no` (unique `std_students`, max 50), `admission_date`, `first_name` (max **100** in validation but column is `VARCHAR(50)` → DEV-STD-CRE-01), `dob`, `current_status_id` required. Also writes `std_student_profiles` + one/more `std_student_addresses`. Aadhar uniqueness enforced on `aadhar_id_hash`.
- **Parents:** each new guardian requires `first_name`, `gender`, `mobile_no`, `short_name`, `password (min 8)`; duplicate mobile → `Mobile number already registered to another guardian.` Existing guardian links `std_student_guardian_jnt` (UNIQUE `student_id`+`guardian_id`). Gate: `tenant.guardian.create`.
- **Health:** `blood_group ∈ {A+,A-,B+,B-,AB+,AB-,O+,O-}`; height/weight numeric 0–300; `next_due_date ≥ date_administered` per vaccination row.
- **Security truths to verify:** SEC-STD-01 (is_super_admin no longer whitelisted by controller, but the toggle is still in the view), SEC-STD-02 (all create gates use `tenant.*`), SEC-STD-03 (aadhar encrypted at rest).

## 3. Manual Test Cases (Step / Action / Expected)

### MT-01 — Valid student login (TC-P12)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open wizard entry URL as admin | Registration tab renders (`#student-login`) |
| 2 | Fill name/short_name/email/password(x2)/status=ACTIVE; submit | Redirect to Student Detail tab, success flash |
| 3 | `SELECT * FROM sys_users WHERE email=?` | 1 row; `user_type='STUDENT'`; `emp_code` matches `STD-YYYY-NNNNNN`; password hashed |

### MT-02 — Valid student details (TC-P13)
| Step | Action | Expected |
|------|--------|----------|
| 1 | With a valid `user_id`, submit admission_no/date, first_name, dob, current_status_id, one address | Redirect to Parent tab |
| 2 | `SELECT * FROM std_students WHERE admission_no=?` | 1 row |
| 3 | `SELECT * FROM std_student_addresses WHERE student_id=?` | ≥1 row |

### MT-03 — Duplicate admission_no (TC-N35)
| 1 | Submit details reusing an existing `admission_no` | Validation error (422/redirect back); no new `std_students` row |

### MT-04 — Health invalid blood group (TC-N36)
| 1 | Submit health with `blood_group=XYZ` | Rejected (422/redirect); no `std_health_profiles` write |

### MT-05 — Vaccination date order (TC-N37)
| 1 | Submit vaccine with `next_due_date < date_administered` | Rejected (422/redirect) |

### MT-06 — Guest access blocked (TC-N50)
| 1 | Visit wizard URL without login | Redirect to `/login` |

### MT-07 — is_super_admin escalation probe (TC-S92 / SEC-STD-01)
| 1 | POST valid login payload with `is_super_admin=1` | Login may be created |
| 2 | `SELECT is_super_admin FROM sys_users WHERE email=?` | **Must NOT be 1** (controller does not whitelist it) |
| 3 | Inspect `_student-login.blade.php` | Toggle `name="is_super_admin"` still present (residual UI — recommend removal) |

### MT-08 — Aadhar at rest (TC-S05 / SEC-STD-03)
| 1 | Create student with aadhar; read raw DB `std_students.aadhar_id` | Ciphertext (encrypted cast), not plaintext; `aadhar_id_hash` populated |

### MT-09 — current_flag integrity (TC-D07 / BUG-STD-11)
| 1 | `SELECT EXTRA FROM information_schema.COLUMNS WHERE TABLE_NAME='std_student_academic_sessions' AND COLUMN_NAME='current_flag'` | EXTRA does **not** contain `GENERATED` — plain nullable INT; app must maintain it manually |

### MT-10 — Duplicate email (TC-N31)
| 1 | Submit login reusing an existing email | Rejected (422/redirect); no new user |

*(Full step tables for the remaining validation/FK/tenancy cases mirror the automated methods listed in the TcList Test Method Index.)*
