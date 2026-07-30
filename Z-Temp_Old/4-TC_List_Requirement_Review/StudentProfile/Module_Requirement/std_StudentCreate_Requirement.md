# std_StudentCreate — Business Requirements

## What This Screen Does

The Student Create wizard is a 7-step multi-tab onboarding interface for adding a new student record into the school ERP system. It orchestrates the complete lifecycle of student data entry — from creating login credentials and capturing personal details to recording academic sessions, previous education, health profiles, and document uploads — across 11 database tables in a tenant-scoped architecture.

This wizard is the single entry point for all new student registrations. Without completing all mandatory steps, a student cannot be considered fully enrolled in the system. The wizard enforces step-by-step progression where each tab creates or links records in the underlying schema before the user proceeds to the next step.

---

## When This Screen Is Used

- **New Admission** when a student joins the school for the first time and all registration data must be captured in a structured sequence
- **Mid-Year Transfer** when a student transfers from another school and requires previous education records, health details, and document uploads alongside standard registration
- **Bulk Onboarding Preparation** when an administrator needs to understand the data requirements per student before performing bulk imports
- **Admission Enquiry Conversion** when a prospective student's enquiry is converted into a full registration requiring guardian linkage and academic session assignment

## Default Data Load

This screen is accessed via the route prefix `/student-profile/student` and is served by `StudentController`. The wizard loads as a single-page interface with 7 tabbed steps. Each tab loads independently when the user navigates to it. No initial data is pre-populated except for dropdown options:
- `sys_dropdown_table` entries for `current_status_id`, `student_id_card_type`, `blood_group`, `document_type_id`, `session_status_id`, `study_format_id`
- `sch_subjects` for opted subject selection
- `sch_academic_sessions` and `sch_class_sections` for session assignment
- Existing guardians (`std_guardians`) list for parent linkage

---

## Key Fields at a Glance

**Tab 1 — Registration (createStudentLogin)**
The Registration tab captures the student's system login identity. `name` is the full display name. `short_name` becomes the unique username in `sys_users` and is validated for uniqueness across all users. `email` must be a valid, unique email address serving as the primary communication channel. `password` is set with a minimum 8-character requirement and must be confirmed. `status` selects the initial account state from `ACTIVE`, `INVITED`, or `DISABLED`.

**Tab 2 — Student Detail + Profile + Address (createStudentDetails)**
This tab creates three records in a single transaction. The `user_id` links back to the login created in Step 1. `admission_no` is a unique identifier for the student's admission. `first_name`, `middle_name`, `last_name` form the student's legal name. `gender` and `dob` capture demographic data. `aadhar_id` is encrypted at rest with a blind-index hash for uniqueness lookups. `apaar_id` is a nullable APAAR identifier. `student_id_card_type` selects from `QR`, `RFID`, `NFC`, or `Barcode`. `admission_date` records the date of admission. `current_status_id` links to a status dropdown. Student profile fields include height, weight, blood group, and measurement date. Address fields capture the student's residential address data.

**Tab 3 — Parent/Guardian Details (createParentDetails)**
Guardians are either selected from existing records in `std_guardians` or created as new entries. Each guardian requires `first_name`, `gender`, and `mobile_no`. New guardians additionally require `short_name` and `password` (min 8 characters) to create their portal login. `relationship` defines the guardian's relation to the student. The `is_fee_payer` flag designates the primary financial responsible party — at most one guardian per student should hold this flag. At least one guardian is mandatory per student.

**Tab 4 — Academic Session (createStudentSession)**
This tab assigns the student to an academic session. `academic_session_id` selects the session year. `class_section_id` assigns the student to a specific class-section. `session_status_id` indicates enrollment status. `roll_no` is the class roll number. `study_format_id` defines the study mode. `opted_subjects` is an array of subjects where each entry includes `subject_id`, `study_format_id`, and `is_core` boolean. The `current_flag` column (intended as GENERATED STORED per spec) marks the current active session.

**Tab 5 — Previous Education (createStudentPrevEduDetails)**
Records the student's educational history before joining the current school. Fields capture school name, board, year of attendance, class, percentage/grade, and any transfer certificate details.

**Tab 6 — Health/Vaccination (createStudentMedicalDetails)**
The health profile stores `blood_group` (validated against allowed types), `height_cm` (0–300), `weight_kg` (0–300), and `measurement_date`. Vaccination records capture `vaccine_name`, `date_administered`, `next_due_date` (must be after or equal to administered date), and `remarks`. Multiple vaccinations can be recorded per student.

**Tab 7 — Documents (upload student documents)**
Each document record includes `document_name`, `document_type_id` (FK to `sys_dropdown_table`), `issue_date`, `expiry_date` (must be after or equal to issue date), a file upload (`mimes:pdf,jpg,jpeg,png,doc,docx`, max 2048 KB), and optional verification fields: `is_verified`, `verified_by` (FK to `sys_users`), `verification_date`.

---

## Business Rules and Conditions

**Sequential Step Dependency**
Each tab depends on the previous tab's successful completion. The `user_id` from Step 1 is required to create the student record in Step 2. The `student_id` from Step 2 is required for Steps 3 through 7. A student cannot skip tabs — the wizard enforces forward progression.

**Transactional Integrity per Tab**
Data is committed per tab. Step 2 creates `std_students`, `std_student_profiles`, and `std_student_addresses` in a single database transaction. If any of these three inserts fail, the entire Step 2 transaction is rolled back. Other steps similarly group related inserts (e.g., Step 6 updates or creates health profile and vaccination records together).

**Uniqueness Constraints**
`admission_no` is unique across all students in the tenant. `aadhar_id` is unique (enforced via encrypted blind-index hash). `short_name` (username) and `email` are unique in `sys_users`. The junction table `std_student_guardian_jnt` enforces uniqueness on `(student_id, guardian_id)`. The `current_flag` column in `std_student_academic_sessions` has a unique index.

**Guardian Completeness**
Every student must have at least one guardian linked via the junction table. The system rejects the save if no guardian is associated.

**Fee Payer At-Most-One**
At most one guardian per student can be marked as `is_fee_payer = Yes`. This rule is currently not enforced in the controller — it is a known gap.

**Health Data Conditional Save**
Health profile data is saved only when at least one health field is present. The controller uses `updateOrCreate` on `student_id`. Vaccination rows are appended independently.

**Document Verification Dependency**
When `is_verified = true`, the fields `verified_by` and `verification_date` should be required. This validation is currently missing (`required_if` not applied) — it is a known gap.

**Emp Code Auto-Generation**
When a student user is created, an employee code is auto-generated in the format `STD-YYYY-NNNNNN` via `generateStudentEmpCode()`. This code is distinct from the admission number but is sequentially predictable.

---

## Workflow Steps

**Onboarding a New Student**
The administrator navigates to the Student Create wizard via `/student-profile/student/create`. The wizard loads with Tab 1 (Registration) active. The administrator fills in the student's name, username, email, password, and status, then clicks Save & Next. The system creates a `sys_users` record with `user_type = 'STUDENT'` and auto-generates the employee code. The wizard advances to Tab 2.

On Tab 2, the administrator enters the student's personal details (admission number, name, gender, DOB, Aadhar, etc.), profile data (height, weight), and address. On save, three rows are created: `std_students`, `std_student_profiles`, `std_student_addresses`. The wizard advances to Tab 3.

On Tab 3, the administrator either selects an existing guardian or creates a new one by entering their details. On save, guardian records are created or linked via `std_student_guardian_jnt`. The wizard advances to Tab 4.

On Tab 4, the administrator selects the academic session, class-section, and optionally assigns subjects. On save, a row is created in `std_student_academic_sessions` and opted subjects are saved. The wizard advances to Tab 5.

On Tab 5, the administrator enters previous education details. On save, a record is created in `std_previous_education`. The wizard advances to Tab 6.

On Tab 6, the administrator enters health profile data and vaccination records. On save, the health profile is created/updated and vaccination rows are appended. The wizard advances to Tab 7.

On Tab 7, the administrator uploads student documents with metadata. On save, document records are created and files are uploaded via the media library. The wizard displays a completion confirmation.

---

## Example Scenario

A new student named Aarav Sharma joins the school at the start of the academic year.

The Admission Counsellor logs into the ERP system and navigates to the Student Create wizard. On Tab 1, they enter Aarav's name, create a username `aarav.sharma`, register `aarav@email.com`, set a temporary password, and select status `INVITED`. The system creates the login and returns the `user_id`.

On Tab 2, the counsellor enters Aarav's admission number `ADM-2026-001`, first name "Aarav", last name "Sharma", gender "Male", DOB "2014-05-12", Aadhar ID, and selects status "Active". They enter height 120 cm, weight 25 kg, and the home address. The system creates the student record and profile.

On Tab 3, the counsellor searches for Aarav's father "Rajesh Sharma" — finding him as an existing guardian — and selects him with relationship "Father". They also add Aarav's mother "Priya Sharma" as a new guardian, entering her details and creating her portal login. The system links both guardians.

On Tab 4, the counsellor selects academic session "2026-27", class-section "5-A", study format "Regular", and opts for core subjects: Mathematics, Science, English, Hindi, and Social Studies. The system saves the academic session and opted subjects.

On Tab 5, the counsellor enters Aarav's previous school "Sunrise Public School", Class 4, with 85% marks. The system saves the previous education record.

On Tab 6, the counsellor enters blood group "O+", height 120 cm, weight 25 kg, and records vaccinations: "Polio" (administered 2024-01-15, next due 2026-01-15) and "MMR" (administered 2024-06-10). The system saves the health profile and vaccination records.

On Tab 7, the counsellor uploads Aarav's birth certificate, previous report card, and a passport-size photograph. The system saves the document records and uploads the files.

Aarav is now fully registered in the system with all 11 related tables populated across 7 wizard steps.

---

## Related Screens

- **Student List** — The main listing screen where created students are viewed, searched, and managed
- **Student View** — The detailed view screen showing all captured student data across tabs in read-only mode
- **Student Edit** — The edit screen allowing modification of student data after creation
- **Bulk Student Import** — An alternative entry point for mass student creation via CSV/Excel upload
- **Guardian Management** — Standalone screen for managing guardian records independent of student creation
- **Academic Session Management** — Screen for configuring academic sessions, class-sections, and subjects used in the wizard
- **Document Verification** — Screen where uploaded documents can be verified by authorized staff

---

## Requirements

- The system MUST expose 7 controller methods in `StudentController` for each wizard step: `createStudentLogin`, `createStudentDetails`, `createParentDetails`, `createStudentSession`, `createStudentPrevEduDetails`, `createStudentMedicalDetails`, and the document upload method.
- The system MUST route all wizard endpoints under the URL prefix `/student-profile/student` (module URL prefix `/student-profile`).
- The system MUST wrap all routes with `module:STUDENT` middleware — if the module is disabled, the system returns HTTP 404.
- The system MUST authorize each step via `Gate::authorize()`:
  - `createStudentLogin`, `createStudentDetails`, `createStudentSession`, `createStudentPrevEduDetails`, `createStudentMedicalDetails` → `tenant.student.create`
  - `createParentDetails` → `tenant.guardian.create`
- The system MUST apply inline validation per tab using `$request->validate()` or `Validator::make()` — no FormRequest classes are used for create routes.
- The system MUST enforce validation rules per tab:
  - **Registration**: `name` required max:255, `short_name` required unique `sys_users`, `email` required email unique, `password` required min:8 confirmed, `status` required in `ACTIVE,INVITED,DISABLED`
  - **Details**: `user_id` required exists `sys_users`, `admission_no` required max:50 unique `std_students`, `admission_date` required date, `first_name` required max:100, `dob` required date, `current_status_id` required integer, `gender` required, `aadhar_id` nullable encrypted with blind-index hash, `apaar_id` nullable string max:100
  - **Parent**: `student_id` required exists, `guardians`/`relationships` required arrays, new guardian requires `first_name`, `gender`, `mobile_no`, `short_name`, `password` min:8
  - **Session**: `academic_session_id` required, `class_section_id` required, `session_status_id` required, `opted_subjects` nullable array, `opted_subjects.*.subject_id` required exists `sch_subjects`, `study_format_id` required, `is_core` required boolean
  - **Health**: `blood_group` in `A+,A-,B+,B-,AB+,AB-,O+,O-`, `height_cm` numeric 0–300, `weight_kg` numeric 0–300, `measurement_date` nullable date
  - **Vaccination**: `next_due_date.*` after_or_equal:`date_administered.*`
  - **Documents**: `documents` nullable array, `documents.*.document_name` nullable string max:100, `documents.*.document_type_id` nullable exists `sys_dropdown_table`, `documents.*.issue_date` nullable date, `documents.*.expiry_date` nullable date after_or_equal:issue_date, `documents.*.is_verified` nullable boolean, `documents.*.verified_by` nullable exists `sys_users`, `documents.*.verification_date` nullable date, `documents.*.student_document` nullable file mimes:pdf,jpg,jpeg,png,doc,docx max:2048
- The system MUST create `sys_users` with `user_type = 'STUDENT'` and auto-generated `emp_code` (`STD-YYYY-NNNNNN`) on registration step.
- The system MUST hash the password before storing it in `sys_users`.
- The system MUST encrypt `aadhar_id` via Laravel's `encrypted` cast and maintain a `aadhar_id_hash` column for blind-index uniqueness lookups.
- The system MUST create Step 2 data (`std_students`, `std_student_profiles`, `std_student_addresses`) in a single database transaction.
- The system MUST use `updateOrCreate` for health profiles keyed on `student_id`.
- The system MUST handle file uploads via the media library for student documents in Step 7.
- The system MUST support soft deletes on `std_students` via the `SoftDeletes` trait.
- The system MUST paginate and list entities where applicable (e.g., existing guardians lookup).

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.student.create` + `tenant.guardian.create` (all permissions) | Full 7-step wizard access |
| Admission Counsellor | `tenant.student.create` + `tenant.guardian.create` | Create new students and guardians |
| Academic Administrator | `tenant.student.create` | Create student records (excluding guardian step) |
| Teacher | No explicit permission | No access |
| Guest (unauthenticated) | None | Redirected to `/login` |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the Student Create wizard at `/student-profile/student/create`. The `module:STUDENT` middleware checks that the Student Profile module is enabled (returns 404 if disabled). Authentication middleware redirects guests to the login page.
2. `Gate::authorize()` checks whether the user has the `tenant.student.create` permission. If not, HTTP 403 is returned.
3. The wizard loads with Tab 1 (Registration) active. The user fills in the login form fields and clicks Save & Next.
4. The inline validation checks all registration rules. If any rule fails, the system returns HTTP 422 with validation error messages and the form remains open for correction.
5. If valid, the system creates a `sys_users` record with `user_type = 'STUDENT'`, auto-generates the employee code (`STD-YYYY-NNNNNN`), hashes the password, and returns the new `user_id`.
6. The wizard advances to Tab 2. The `user_id` is passed forward. The user fills in student details, profile, and address fields and clicks Save & Next.
7. The inline validation checks all details rules. If valid, the system creates `std_students`, `std_student_profiles`, and `std_student_addresses` in a single transaction. The new `student_id` is returned.
8. Steps 3 through 7 follow the same pattern: each tab collects data, validates inline, and creates/updates the relevant database records. The `student_id` is carried forward through all remaining steps.
9. On Tab 3 (Parents), the user can either search and select existing guardians or create new ones. At least one guardian is required. New guardians get their own portal user created automatically.
10. On Tab 4 (Session), the user selects the academic session, class-section, and optional subjects. The `current_flag` is set for the active session.
11. On Tab 5 (Previous Education), the user enters prior schooling details.
12. On Tab 6 (Health/Vaccination), the user enters health metrics and vaccination records. Vaccination date order is enforced (next due ≥ administered).
13. On Tab 7 (Documents), the user uploads files with metadata. Each file is stored via the media library. Old documents are removed if removed from the DOM by the user.
14. After the final tab is saved, the wizard displays a success message confirming the student has been created.

---

## Validate Before Save (Multiple Conditions)

**Tab 1 — Registration**
1. **Name Required** — `name` must not be empty. Error: "The name field is required."
2. **Name Max Length** — `name` must not exceed 255 characters. Error: "The name must not be greater than 255 characters."
3. **Short Name Required** — `short_name` must not be empty. Error: "The short name field is required."
4. **Short Name Unique** — `short_name` must be unique in `sys_users`. Error: "The short name has already been taken."
5. **Email Required** — `email` must not be empty. Error: "The email field is required."
6. **Email Valid Format** — `email` must be a valid email address. Error: "The email must be a valid email address."
7. **Email Unique** — `email` must be unique in `sys_users`. Error: "The email has already been taken."
8. **Password Required** — `password` must not be empty. Error: "The password field is required."
9. **Password Min Length** — `password` must be at least 8 characters. Error: "The password must be at least 8 characters."
10. **Password Confirmed** — `password` must match `password_confirmation`. Error: "The password confirmation does not match."
11. **Status Required** — `status` must not be empty. Error: "The status field is required."
12. **Status Valid Enum** — `status` must be one of `ACTIVE, INVITED, DISABLED`. Error: "The selected status is invalid."

**Tab 2 — Student Details + Profile + Address**
13. **User ID Required** — `user_id` must not be empty. Error: "The user id field is required."
14. **User ID Exists** — `user_id` must reference an existing record in `sys_users`. Error: "The selected user id is invalid."
15. **Admission No Required** — `admission_no` must not be empty. Error: "The admission no field is required."
16. **Admission No Max Length** — `admission_no` must not exceed 50 characters. Error: "The admission no must not be greater than 50 characters."
17. **Admission No Unique** — `admission_no` must be unique in `std_students`. Error: "The admission no has already been taken."
18. **Admission Date Required** — `admission_date` must not be empty. Error: "The admission date field is required."
19. **Admission Date Valid Date** — `admission_date` must be a valid date. Error: "The admission date is not a valid date."
20. **First Name Required** — `first_name` must not be empty. Error: "The first name field is required."
21. **First Name Max Length** — `first_name` must not exceed 100 characters. Error: "The first name must not be greater than 100 characters."
22. **DOB Required** — `dob` must not be empty. Error: "The dob field is required."
23. **DOB Valid Date** — `dob` must be a valid date. Error: "The dob is not a valid date."
24. **Current Status ID Required** — `current_status_id` must not be empty. Error: "The current status id field is required."
25. **Current Status ID Integer** — `current_status_id` must be an integer. Error: "The current status id must be an integer."
26. **Aadhar ID Unique (via blind index)** — Duplicate `aadhar_id` is detected via `aadhar_id_hash` and rejected.
27. **APAAR ID Max Length** — `apaar_id` must not exceed 100 characters. Error: "The apaar id must not be greater than 100 characters."

**Tab 3 — Parents/Guardians**
28. **Student ID Required** — `student_id` must not be empty. Error: "The student id field is required."
29. **Student ID Exists** — `student_id` must reference an existing record in `std_students`. Error: "The selected student id is invalid."
30. **Guardians Required Array** — `guardians` must be a non-empty array. Error: "The guardians field is required."
31. **Guardian Fields** — New guardian requires `first_name` (required), `gender` (required), `mobile_no` (required), `short_name` (required), `password` (required, min:8).
32. **Duplicate Mobile** — New guardian mobile must not already be registered. Error: "Mobile number already registered to another guardian."
33. **At Least One Guardian** — At least one guardian must be linked to the student. Error: thrown at controller level.

**Tab 4 — Academic Session**
34. **Academic Session ID Required** — `academic_session_id` must not be empty. Error: "The academic session id field is required."
35. **Class Section ID Required** — `class_section_id` must not be empty. Error: "The class section id field is required."
36. **Session Status ID Required** — `session_status_id` must not be empty. Error: "The session status id field is required."
37. **Subject ID Exists** — `opted_subjects.*.subject_id` must reference an existing record in `sch_subjects`. Error: "The selected opted_subjects.0.subject_id is invalid."

**Tab 5 — Previous Education**
38. Previous education fields validated as required per business rules (school name, year, class, percentage).

**Tab 6 — Health/Vaccination**
39. **Blood Group Valid Enum** — `blood_group` must be one of `A+, A-, B+, B-, AB+, AB-, O+, O-`. Error: "The selected blood group is invalid."
40. **Height Range** — `height_cm` must be between 0 and 300. Error: "The height cm must be between 0 and 300."
41. **Weight Range** — `weight_kg` must be between 0 and 300. Error: "The weight kg must be between 0 and 300."
42. **Vaccination Date Order** — `next_due_date.*` must be after or equal to `date_administered.*`. Error: "The next due date must be a date after or equal to date administered."

**Tab 7 — Documents**
43. **Document Type ID Exists** — `documents.*.document_type_id` must reference an existing record in `sys_dropdown_table`. Error: "The selected documents.0.document_type_id is invalid."
44. **Expiry Date Order** — `documents.*.expiry_date` must be a date after or equal to `documents.*.issue_date`. Error: "The documents.0.expiry date must be a date after or equal to issue date."
45. **File MIME Types** — Uploaded file must be one of `pdf, jpg, jpeg, png, doc, docx`. Error: "The documents.0.student document must be a file of type: pdf, jpg, jpeg, png, doc, docx."
46. **File Max Size** — Uploaded file must not exceed 2048 KB. Error: "The documents.0.student document must not be greater than 2048 kilobytes."
47. **Document Verification Required If** — When `is_verified = true`, `verified_by` and `verification_date` should be required (currently a known gap).

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Registration: name is empty | "The name field is required." | 422 |
| Registration: name exceeds 255 chars | "The name must not be greater than 255 characters." | 422 |
| Registration: short_name is empty | "The short name field is required." | 422 |
| Registration: duplicate short_name | "The short name has already been taken." | 422 |
| Registration: invalid email format | "The email must be a valid email address." | 422 |
| Registration: duplicate email | "The email has already been taken." | 422 |
| Registration: password less than 8 chars | "The password must be at least 8 characters." | 422 |
| Registration: password confirmation mismatch | "The password confirmation does not match." | 422 |
| Registration: invalid status value | "The selected status is invalid." | 422 |
| Details: user_id not found in sys_users | "The selected user id is invalid." | 422 |
| Details: duplicate admission_no | "The admission no has already been taken." | 422 |
| Details: first_name exceeds 100 chars | "The first name must not be greater than 100 characters." | 422 |
| Details: duplicate aadhar_id | "The aadhar id has already been taken." | 422 |
| Parent: duplicate guardian mobile | "Mobile number already registered to another guardian." | 422 |
| Parent: no guardian selected | At least one guardian is required | 422 |
| Session: invalid subject_id | "The selected opted_subjects.0.subject_id is invalid." | 422 |
| Health: invalid blood_group | "The selected blood group is invalid." | 422 |
| Health: height out of range (0–300) | "The height cm must be between 0 and 300." | 422 |
| Vaccination: next_due before administered | "The next due date must be a date after or equal to date administered." | 422 |
| Document: invalid document_type_id | "The selected documents.0.document_type_id is invalid." | 422 |
| Document: expiry before issue date | "The documents.0.expiry date must be a date after or equal to issue date." | 422 |
| Document: invalid file MIME type | "The documents.0.student document must be a file of type: pdf, jpg, jpeg, png, doc, docx." | 422 |
| Document: file exceeds 2048 KB | "The documents.0.student document must not be greater than 2048 kilobytes." | 422 |
| Unauthorized (missing permission) | "This action is unauthorized." | 403 |
| Module disabled | 404 Not Found | 404 |
| Guest access (unauthenticated) | Redirect to /login | 302 |

---

## Success Scenarios

**SC-001: Full Student Onboarding Through All 7 Steps**
1. Admin navigates to Student Create wizard.
2. Tab 1: Enters name "Aarav Sharma", username "aarav.sharma2026", email "aarav@school.edu", password "Secret@123" (confirmed), status "ACTIVE". Saves. System creates `sys_users` with emp_code `STD-2026-000001`.
3. Tab 2: Enters admission_no "ADM-2026-001", first_name "Aarav", last_name "Sharma", gender "Male", dob "2014-05-12", current_status_id 1, aadhar_id, height 120 cm, weight 25 kg, address fields. Saves. System creates `std_students`, `std_student_profiles`, `std_student_addresses`.
4. Tab 3: Selects an existing guardian (father) and creates a new guardian (mother). Saves. System links both via junction table.
5. Tab 4: Selects session "2026-27", class "5-A", session status "Active", opts for 5 core subjects. Saves. System creates academic session and opted subject records.
6. Tab 5: Enters previous school details. Saves. System creates previous education record.
7. Tab 6: Enters blood group "O+", height 120 cm, weight 25 kg, and two vaccination records. Saves. System creates/updates health profile and vaccination records.
8. Tab 7: Uploads 3 documents with metadata. Saves. System creates document records and uploads files via media library.
9. Wizard displays success message. All 11 tables populated correctly.

**SC-002: Guardian-Link-Only Student Creation (Existing Guardian)**
1. Admin creates student login and details in Tabs 1-2.
2. On Tab 3, admin searches and selects an existing guardian record — no new guardian creation needed.
3. Admin completes remaining tabs. The system correctly links the existing guardian to the new student via the junction table without creating duplicate guardian records.

**SC-003: Creating a Student with No Previous Education or Medical Data**
1. Admin creates student through Tabs 1-4 normally.
2. On Tab 5 (Previous Education), admin leaves all fields empty — the system saves an empty or null record.
3. On Tab 6 (Health/Vaccination), admin enters no health data — the system skips the health profile creation entirely (conditional save).
4. On Tab 7, admin uploads documents as needed.
5. Student is created successfully with optional sections gracefully handled.

---

## Failure Scenarios

**FC-001: Duplicate Admission Number Rejected**
1. Admin completes Tab 1 successfully and proceeds to Tab 2.
2. Admin enters an admission_no that already exists in `std_students`.
3. System validation fails with error: "The admission no has already been taken."
4. Record is not saved. The form remains open with the entered data preserved for correction.

**FC-002: Vaccination Date Order Violation**
1. Admin reaches Tab 6 (Health/Vaccination) and enters a vaccination record.
2. Admin sets `date_administered` to "2026-06-15" and `next_due_date` to "2026-01-10" (earlier than administered).
3. System validation fails with error: "The next due date must be a date after or equal to date administered."
4. Vaccination record is not saved. Admin must correct the next due date to be on or after the administered date.

**FC-003: Unauthorized Access by Invalid Role**
1. A Teacher (who lacks `tenant.student.create` and `tenant.guardian.create` permissions) navigates to `/student-profile/student/create`.
2. Authentication middleware passes (user is logged in), but `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."
4. The wizard does not load. The Teacher must request access from the Super Admin.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `sys_users` | `id`, `name`, `short_name` UNIQUE, `email` UNIQUE, `password`, `user_type` ('STUDENT'), `emp_code`, `status`, `created_at`, `updated_at`, `deleted_at` |
| Primary Table | `std_students` | `id`, `user_id` FK→`sys_users.id` ON DELETE CASCADE UNIQUE, `admission_no` UNIQUE, `admission_date`, `student_qr_code`, `student_id_card_type` ENUM('QR','RFID','NFC','Barcode'), `smart_card_id`, `aadhar_id` (encrypted), `aadhar_id_hash` UNIQUE, `apaar_id`, `birth_cert_no`, `first_name`, `middle_name`, `last_name`, `gender`, `dob`, `current_status_id`, `is_active`, `note`, `deleted_at` (SoftDeletes) |
| Related Table | `std_student_profiles` | `id`, `student_id` FK→`std_students.id`, `height_cm`, `weight_kg`, `blood_group`, `measurement_date`, `created_at`, `updated_at` |
| Related Table | `std_student_addresses` | `id`, `student_id` FK→`std_students.id`, address fields, `created_at`, `updated_at` |
| Related Table | `std_guardians` | `id`, `first_name`, `middle_name`, `last_name`, `gender`, `mobile_no`, `email`, `short_name`, `password`, `created_at`, `updated_at` |
| Related Table | `std_student_guardian_jnt` | `id`, `student_id` FK→`std_students.id`, `guardian_id` FK→`std_guardians.id`, `relationship`, `is_fee_payer`, UNIQUE(`student_id`, `guardian_id`) |
| Related Table | `std_student_academic_sessions` | `id`, `student_id` FK→`std_students.id`, `academic_session_id`, `class_section_id`, `roll_no`, `session_status_id`, `current_flag` (intended GENERATED STORED), `created_at`, `updated_at` |
| Related Table | `std_student_opted_subjects` | `id`, `student_academic_session_id` FK→`std_student_academic_sessions.id`, `subject_id` FK→`sch_subjects.id`, `study_format_id`, `is_core`, `created_at`, `updated_at` |
| Related Table | `std_previous_education` | `id`, `student_id` FK→`std_students.id`, school details, year, class, percentage, `created_at`, `updated_at` |
| Related Table | `std_health_profiles` | `id`, `student_id` FK→`std_students.id` UNIQUE, `blood_group`, `height_cm`, `weight_kg`, `measurement_date`, `created_at`, `updated_at` |
| Related Table | `std_vaccination_records` | `id`, `student_id` FK→`std_students.id`, `vaccine_name`, `date_administered`, `next_due_date`, `remarks`, `created_at`, `updated_at` |
| Related Table | `std_student_documents` | `id`, `student_id` FK→`std_students.id`, `document_name`, `document_type_id` FK→`sys_dropdown_table.id`, `issue_date`, `expiry_date`, `file_path`, `is_verified`, `verified_by` FK→`sys_users.id`, `verification_date`, `created_at`, `updated_at` |
| Module Dependency | StudentProfile Module | Core module providing all student management functionality via `/student-profile` prefix |
| Module Dependency | User & Permission Module | Authentication, authorization (`sys_users`), and gates (`tenant.student.*`, `tenant.guardian.*`) |
| Module Dependency | Syllabus Module | Provides `sch_subjects`, `sch_academic_sessions`, `sch_class_sections` for session and subject assignment |
| Module Dependency | System Configuration Module | Provides `sys_dropdown_table` for dropdown-based field type references |
| Module Dependency | Media Library | Handles file uploads and storage for student documents in Tab 7 |
| Module Dependency | Student Portal | New guardians created with portal login access; Student model reverse-couples `StudentPortal` |
| Module Dependency | Fee Module | Student model reverse-couples `StudentFee` for fee management |
| Module Dependency | Transport Module | Student model reverse-couples `Transport` for transport management |
