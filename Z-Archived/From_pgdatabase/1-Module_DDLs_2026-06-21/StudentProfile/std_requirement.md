# Student Profile Module — Requirements and Specifications

> This document outlines the comprehensive requirements, business logic, and functional specifications for the Student Profile Management Module. It covers all CRUD operations for every sub-feature including Student Login, Core Profile, Family/Guardians, Addresses, Academic Sessions, Previous Education, Documents, Health/Medical, Attendance, Leave Management, Reports, and Dashboard.

---

## Table of Contents

1. [Core Functional Overview](#1-core-functional-overview)
2. [Student Login (User Creation)](#2-student-login-user-creation)
3. [Student Details (Core Profile)](#3-student-details-core-profile)
4. [Family & Guardians](#4-family--guardians)
5. [Addresses](#5-addresses)
6. [Academic Sessions & Subject Options](#6-academic-sessions--subject-options)
7. [Previous Education](#7-previous-education)
8. [Student Documents](#8-student-documents)
9. [Health & Medical](#9-health--medical)
10. [Attendance](#10-attendance)
11. [Student Leave Management](#11-student-leave-management)
12. [Reports & Dashboard](#12-reports--dashboard)

---

## 1. Core Functional Overview

### 1.1 Purpose
The Student Profile Module provides a centralized system for managing the complete student lifecycle — from admission, profile management, family details, academic allocations, attendance tracking, health records, leave management, to alumni/withdrawal. It serves as the single source of truth for all student-related data across the institution.

### 1.2 Key Capabilities
- **Tabbed Admission Workflow** — 8-step guided admission form (Login → Details → Family → Session → Prev Edu → Docs → Health)
- **Guardian Sibling Detection** — auto-links existing guardians via mobile number to prevent duplicates
- **Academic History Tracking** — multi-session promotion/transfer with historical preservation
- **Attendance Management** — daily period-wise marking with correction request workflow
- **Health & Medical Log** — health profiles, vaccination records, and medical incident logging
- **Leave Application FSM** — 8-state finite state machine with teacher-student communication thread
- **ID Card Generation** — template-based student ID card with QR code
- **Role-Based Access** — granular permissions per CRUD operation
- **Soft Deletes & Trash** — full restore/force-delete for all major entities
- **Bulk Operations** — bulk restore, force delete, and empty trash
- **Progress Tracking** — admission form completion percentage with first incomplete tab detection
- **Student Portal Data** — exam attempts, results, and group memberships linked

### 1.3 Database Tables
| Table | Purpose |
|---|---|
| `std_students` | Core student entity linked to `sys_users` for login |
| `std_student_profiles` | Extended personal demographics and bank details |
| `std_guardians` | Parent/guardian master (shared across siblings) |
| `std_student_guardian_jnt` | M:N junction with relationship and permissions |
| `std_student_addresses` | 1:N addresses (Permanent, Correspondence, etc.) |
| `std_student_academic_sessions` | Chronological class/section allocation per session |
| `std_student_opted_subjects` | Per-session optional subject selections |
| `std_previous_education` | Previous school history with TC details |
| `std_student_documents` | Uploaded documents with verification status |
| `std_health_profiles` | Medical profile (blood group, allergies, etc.) |
| `std_vaccination_records` | Vaccination history |
| `std_medical_incidents` | School clinic incident log |
| `std_student_attendance` | Daily period-wise attendance records |
| `std_attendance_corrections` | Parent/student correction requests |
| `std_leave_types` | Leave type master configuration |
| `std_leave_applications` | 8-state FSM leave applications |
| `std_leave_application_documents` | Supporting docs per leave application |
| `std_leave_application_remarks` | Teacher↔Student communication thread + FSM audit log |

### 1.4 Tabbed Admission/Edit View
All management screens are accessed through a tabbed interface. The **Create** flow uses `editStudentDetails` route with these tabs:
- **Student Login Details** — sys_user creation/selection for the student
- **Student Details** — core profile (name, DOB, gender, IDs, photo, demographics, bank)
- **Parent Details** — guardian addition (new/existing), relationship, portal access
- **Session Details** — academic session, class-section, roll no, house, subject group + opted subjects
- **Previous Education** — previous school info + document upload
- **Student Health** — health profile, vaccinations, medical incidents

The **Edit** flow (route: `student/{student}/edit`) uses the same tabs with `completedTabs` / `progressPercentage` tracking and auto-advance to the first incomplete tab.

### 1.5 Student List View
**Route:** `/students` with two sub-tabs:
- **Student Management** — paginated student grid with search, class/section/session/status filters, subject group filter, missing optional subjects detection
- **Document Generate** — student selection for ID card printing, credential sending

---

## 2. Student Login (User Creation)

### 2.1 What It Does
Creates or links a `sys_users` record for the student. Each student must have a unique system user account with `user_type = 'STUDENT'` and Student role assignment. The login can be created before or during the admission process.

### 2.2 Database Fields (sys_users — Student context)

| Field | Type | Conditions |
|---|---|---|
| `name` | VARCHAR | Required. Combined first+middle+last name from student details (max 100). |
| `short_name` | VARCHAR(30) | Required. Unique. Short identifier for the student. |
| `emp_code` | VARCHAR | Auto-generated: `STD-YYYY-NNNNNN`. Unique per year. |
| `email` | VARCHAR | Required. Unique. Student/parent email. |
| `mobile_no` | VARCHAR | Nullable. Student/parent mobile. |
| `phone_no` | VARCHAR | Nullable. |
| `password` | VARCHAR | Required on create. Hashed. Min 8 chars with confirmation. |
| `status` | ENUM | `ACTIVE` / `INVITED` / `DISABLED`. |
| `is_active` | BOOLEAN | Default true. |
| `user_type` | VARCHAR | Auto-set to `'STUDENT'`. |
| `two_factor_auth_enabled` | BOOLEAN | Default false. |
| `is_super_admin` | BOOLEAN | Default false. |
| `user_img` | MEDIA | Optional photo via Spatie Media Library. |

### 2.3 Business Rules

**Emp Code Auto-Generation**
- Format: `STD-YYYY-NNNNNN` (e.g., `STD-2026-000001`)
- Year is the current year of creation
- Sequence increments per year based on last `emp_code` matching `STD-YYYY-%`
- Generated in `generateStudentEmpCode()` method

**Role Assignment**
- On creation, the `Student` role is automatically assigned via `syncRoles`
- Role looked up by `name = 'Student'`

**Email Notification**
- On successful creation, an email is sent to the student's email address with login credentials
- Uses `StudentLoginCreated` Mailable
- Sends both the username (email) and plain-text password

**Duplicate Mobile/Email Checks**
- `email` must be unique across all `sys_users`
- `short_name` must be unique across all `sys_users`
- `emp_code` is auto-generated but must remain unique

**Photo Handling**
- Image uploaded via Spatie Media Library collection `user_img`
- Supported MIME types: jpg, jpeg, png, webp
- Max file size: 2MB

### 2.4 CRUD Operations

**Create**
- Route: `POST /student/create-student-login`
- Validates: name, short_name, email, password+confirmation, status
- Creates `sys_users` record with auto-generated `emp_code`
- Assigns Student role
- Sends credentials email
- Links to student if `student_id` is provided in request
- On success: redirects to editStudentDetails with `activeTab = student_details` tab
- On failure: returns to login tab with validation errors

**Update**
- Route: `PUT /student/{user}/update-login`
- Validates: name, short_name, emp_code, email, optional password, is_active
- Unique checks ignore the current user's own values
- Updates `sys_users` record
- Password only updated if provided (nullable field)
- Photo replaced if new image uploaded (clears old collection first)

### 2.5 Permissions

| Operation | Permission Key |
|---|---|
| View any student | `tenant.student.viewAny` |
| View student details | `tenant.student.view` |
| Create student login | `tenant.student.create` |
| Update student | `tenant.student.update` |
| Delete student | `school-setup.student.delete` |

---

## 3. Student Details (Core Profile)

### 3.1 What It Does
Captures the core demographic and identification information for each student. Split across two tables: `std_students` (core identity) and `std_student_profiles` (extended demographics, bank details, and physical stats snapshot).

### 3.2 Database Fields — std_students

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `user_id` | INT FK → `sys_users` | Required. Unique. Links to login account. |
| `admission_no` | VARCHAR(50) | Required. Unique. School admission number. |
| `admission_date` | DATE | Required. Date of admission. |
| `student_qr_code` | VARCHAR(20) | Nullable. Auto-set to `emp_code` on creation if empty. Used for ID cards. |
| `student_id_card_type` | ENUM | `QR` / `RFID` / `NFC` / `Barcode`. Default: `QR`. |
| `smart_card_id` | VARCHAR(100) | Nullable. RFID/NFC tag ID. |
| `aadhar_id` | VARCHAR(20) | Nullable. Unique. National ID. |
| `apaar_id` | VARCHAR(100) | Nullable. Academic Bank of Credits ID. |
| `birth_cert_no` | VARCHAR(50) | Nullable. |
| `first_name` | VARCHAR(50) | Required. Combined with middle+last → saved as `name` in `sys_users`. |
| `middle_name` | VARCHAR(50) | Nullable. |
| `last_name` | VARCHAR(50) | Nullable. |
| `gender` | ENUM | `Male` / `Female` / `Transgender` / `Prefer Not to Say`. Default: `Male`. |
| `dob` | DATE | Required. Date of birth. |
| `photo_file_name` | VARCHAR(100) | Nullable. FK to sys_media. |
| `media_id` | INT | Nullable. Optional sys_media link. |
| `current_status_id` | INT FK → `sys_dropdown_table` | Required. Active / Left / Suspended / Alumni / Withdrawn. |
| `is_active` | TINYINT(1) | Default 1. |
| `note` | VARCHAR(255) | Nullable. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |

### 3.3 Database Fields — std_student_profiles

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. Unique. |
| `mobile` | VARCHAR(20) | Nullable. Also saved as `mobile` in `sys_users`. |
| `email` | VARCHAR(150) | Nullable. Also saved as `email` in `sys_users`. |
| `religion` | INT FK → `sys_dropdown_table` | Nullable. |
| `caste_category` | INT FK → `sys_dropdown_table` | Nullable. General/OBC/SC/ST. |
| `nationality` | INT FK → `sys_dropdown_table` | Nullable. |
| `mother_tongue` | INT FK → `sys_dropdown_table` | Nullable. |
| `bank_account_no` | VARCHAR(100) | Nullable. |
| `bank_name` | VARCHAR(100) | Nullable. |
| `ifsc_code` | VARCHAR(50) | Nullable. |
| `bank_branch` | VARCHAR(100) | Nullable. |
| `upi_id` | VARCHAR(100) | Nullable. |
| `fee_depositor_pan_number` | VARCHAR(10) | Nullable. For tax benefit. |
| `right_to_education` | TINYINT(1) | Default 0. RTE Quota flag. |
| `is_ews` | TINYINT(1) | Default 0. Economically Weaker Section. |
| `height_cm` | DECIMAL(5,2) | Nullable. Latest snapshot. |
| `weight_kg` | DECIMAL(5,2) | Nullable. Latest snapshot. |
| `measurement_date` | DATE | Nullable. |
| `additional_info` | JSON | Nullable. Flexible metadata storage. |

### 3.4 Business Rules

**Name Sync**
- `first_name + middle_name + last_name` are combined (space-separated, filter nulls) and saved as `name` in the linked `sys_users` record
- Total combined length must not exceed 100 characters

**Admission No Uniqueness**
- `admission_no` must be unique across all `std_students`
- Checked at both form validation and database level (UNIQUE KEY)

**Aadhar Uniqueness**
- `aadhar_id` must be unique if provided
- Checked at both form validation and database level (UNIQUE KEY)

**Student QR Code Auto-Population**
- On first save, if `student_qr_code` is empty, it is auto-set to the linked user's `emp_code`
- This happens only once (checked with `if (empty(...))`)

**Photo Upload**
- Supports Spatie Media Library collections: `student_photo` and `user_img`
- On upload, photo is synced to both the student record AND the linked `sys_users` record
- On photo removal, both collections are cleared
- Supported MIME types: jpeg, png, gif, webp
- Image conversions: thumb (100x100), small (150x150), medium (300x300), large (600x600)

**Measurement Validation**
- `measurement_date` must be before or equal to today
- `measurement_date` is required when `height_cm` or `weight_kg` is provided
- Height range: 30-300 cm. Weight range: 1-500 kg.

### 3.5 CRUD Operations

**Create (step in admission flow)**
- Route: `POST /student/create-student-details`
- Validates all std_students + std_student_profiles fields + dynamic address array
- Uses `updateOrCreate` pattern (handles both create and update in admission flow)
- After creation, handles photo upload + sync to user
- On success: redirects to `activeTab = parent_details`
- On failure: returns to student_details tab with errors

**Update**
- Route: `PUT /student/{student}/update-student-details`
- Same validation as create
- Addresses are upserted: existing IDs are updated, new ones inserted, removed ones deleted
- Single primary address constraint enforced
- After update, checks `completedTabs` and auto-advances to next incomplete tab
- If tab was already complete, stays on same tab

**View (360° Profile)**
- Route: `GET /student/{student}`
- Loads all relationships: user, profile, sessions, addresses, guardians, health, documents, previous education, medical incidents, vaccinations
- Shows current session, photo URL, email verification status
- Tabbed sub-navigation: Overview, Attendance, Academics, Fees, Health, Timeline, Documents

**List**
- Route: `GET /students`
- Two sub-tabs: Student Management + Document Generate
- Student Management tab: paginated with search, class/section/session/status filters, subject group filter
- Missing Optional Subjects tab: shows students with incomplete optional subject selections
- Document Generate tab: simplified student selection for ID card printing

**Toggle Status**
- Route: `POST /student/{student}/toggle-status`
- AJAX endpoint accepting `{ is_active: boolean }`
- Returns JSON: `{ success: true, is_active: bool, message: string }`

**Soft Delete**
- Route: `DELETE /student/{student}`
- Cascades to the linked `sys_users` record (soft deletes user)
- All related child records cascade via FK constraints

**Restore**
- Route: `PATCH /student/{id}/restore`
- Restores both `std_students` and linked `sys_users`

**Force Delete**
- Route: `DELETE /student/{id}/force-delete`
- Clears media collections before permanent deletion
- Cascades to all child records

**Trash View**
- Route: `GET /student/trash/view`
- Lists soft-deleted students via `User::onlyTrashed()->role('Student')`
- Bulk operations: bulk restore, bulk force delete, empty trash, restore all

**Export**
- Route: `GET /student/export/{type}`
- Excel export using Maatwebsite

### 3.6 Permissions

| Operation | Permission Key |
|---|---|
| View any student | `tenant.student.viewAny` |
| View student details | `tenant.student.view` |
| Create student | `tenant.student.create` |
| Update student | `tenant.student.update` |
| Delete student | `school-setup.student.delete` |
| Restore student | `school-setup.student.restore` |
| Force delete student | `school-setup.student.forceDelete` |

---

## 4. Family & Guardians

### 4.1 What It Does
Manages parent/guardian information with a shared guardian master table that prevents duplicate records across sibling students. Supports both new guardian creation and linking to existing guardians via mobile number lookup. Each student-guardian relationship includes granular permissions (emergency contact, pickup authorization, fee payer, portal access, notification preferences).

### 4.2 Database Fields — std_guardians

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `user_code` | VARCHAR(20) | Required. Unique. Auto-generated: `PRN-YYYY-NNNNN`. |
| `user_id` | INT FK → `sys_users` | Nullable. Set when Parent Portal access is created. |
| `first_name` | VARCHAR(50) | Required. Combined with last → saved as `name` in `sys_users`. |
| `last_name` | VARCHAR(50) | Nullable. |
| `gender` | ENUM | `Male` / `Female` / `Transgender` / `Prefer Not to Say`. |
| `mobile_no` | VARCHAR(20) | Required. Unique. Primary identifier. |
| `phone_no` | VARCHAR(20) | Nullable. |
| `email` | VARCHAR(100) | Nullable. |
| `occupation` | VARCHAR(100) | Nullable. |
| `qualification` | VARCHAR(100) | Nullable. |
| `annual_income` | DECIMAL(15,2) | Nullable. |
| `preferred_language` | INT FK → `glb_languages` | Required. |
| `photo_file_name` | VARCHAR(100) | Nullable. |
| `media_id` | INT | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |

### 4.3 Database Fields — std_student_guardian_jnt

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `guardian_id` | INT FK → `std_guardians` | Required. |
| `relation_type` | ENUM | `Father` / `Mother` / `Guardian`. |
| `relationship` | VARCHAR(50) | Required. Father, Mother, Uncle, Brother, Sister, Grandfather, Grandmother, etc. |
| `is_emergency_contact` | TINYINT(1) | Default 0. |
| `can_pickup` | TINYINT(1) | Default 0. Authorization to pick up child. |
| `is_fee_payer` | TINYINT(1) | Default 0. Who pays the fees. |
| `can_access_parent_portal` | TINYINT(1) | Default 0. Parent Portal access flag. |
| `can_receive_notifications` | TINYINT(1) | Default 1. |
| `notification_preference` | ENUM | `Email` / `SMS` / `WhatsApp` / `All`. Default `All`. |

### 4.4 Business Rules

**Guardian Uniqueness via Mobile**
- Each guardian is uniquely identified by `mobile_no`
- When a new guardian is added, the system first checks if a guardian with that mobile already exists
- If found, the existing guardian is linked instead of creating a duplicate
- This ensures sibling students share the same guardian record

**Existing Guardian Lookup**
- During admission, admin can search for existing guardians by mobile number
- System auto-fills guardian details if found
- Admin confirms linking or creates a new guardian

**Parent Portal User Creation**
- When a new guardian is created, a `sys_users` record is also created with `user_type = 'PARENT'`
- If an existing guardian is linked but has no user, a user is created/updated
- The parent user is shared across all guardians of the same student (`user_id` column on guardian)
- Role assignment: Parent role is looked up and assigned

**Emp Code Generation for Parents**
- Format: `PRN-YYYY-NNNNN` (e.g., `PRN-2026-00001`)
- Auto-generated per year

**Multi-Guardian Support**
- A student can have multiple guardians (typically Father + Mother)
- Each guardian can have different permissions (one can be emergency contact, another can be fee payer)
- Each guardian has a distinct `relation_type` and `relationship` value

**Guardian-Student Junction Constraints**
- Unique constraint on `(student_id, guardian_id)` — a specific guardian can only be linked to a specific student once
- Junction record tracks relationship type and all permission flags

### 4.5 CRUD Operations

**Create (in admission flow)**
- Route: `POST /student/create-parent-details`
- Accepts array of guardians with sources: `new` or `existing`
- Validates: student_id, guardians array (first_name required for new, mobile_no required for new), relationships array
- For existing guardians: links via guardian_id or user_id, creates Guardian record if missing
- For new guardians: checks mobile uniqueness, creates Guardian + User record
- Links all guardians to student via `StudentGuardianJnt`
- Syncs parent user_id across all guardians for the student
- On success: redirects to `activeTab = session_details`
- On failure: returns to parent_details tab with error

**Update**
- Route: `PUT /parent/{parent}/update`
- Validates: first_name, last_name, gender, mobile_no, email, occupation, qualification, annual_income, relation_type
- Updates Guardian record
- Syncs changes to linked User record (name, email, mobile_no, is_active)
- Updates StudentGuardianJnt junction (relation_type, relationship, all permission flags)
- Handles parent photo upload/replacement via Spatie Media Library

**Delete Guardian Link**
- Route: `DELETE /student/{student}/parent/{parent}/delete`
- Removes the junction record, optionally deletes guardian if no longer linked to any student

### 4.6 Permissions
Same as Student Details permissions (create, update, delete are gated by `tenant.student.*`).

---

## 5. Addresses

### 5.1 What It Does
Manages multiple addresses per student with type classification (Permanent, Correspondence, Guardian, Local). Supports one primary address per student.

### 5.2 Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `address_type` | ENUM | `Permanent` / `Correspondence` / `Guardian` / `Local`. Default: `Correspondence`. |
| `address` | VARCHAR(512) | Required. |
| `city_id` | INT FK → `glb_cities` | Required. |
| `pincode` | VARCHAR(10) | Required. |
| `is_primary` | TINYINT(1) | Default 0. Only one primary per student. |
| `is_active` | TINYINT(1) | Default 1. |

### 5.3 Business Rules

**Single Primary Address**
- Only one address per student can be marked as primary
- Enforced at application level (`ensureSinglePrimaryAddress`)
- When updating, if a new primary is set, all others are demoted to non-primary
- If no primary exists after update, the first address is auto-assigned as primary

**Dynamic Address Array Handling**
- Addresses are submitted as arrays: `address_types[]`, `addresses[]`, `city_ids[]`, `pincodes[]`
- During update, existing addresses are matched by `address_ids[]`
- New addresses are inserted, removed addresses (IDs not in submission) are deleted
- Empty address strings are skipped

**Auto-Create During Admission**
- At least one address is created during the initial student details save
- Addresses are saved in the `storeStudentAddress` method called from `createStudentDetails`

### 5.4 CRUD Operations

**Create (in admission flow)**
- Part of `POST /student/create-student-details`
- Addresses are part of the same form submission as student details
- Dynamic form allows adding multiple address blocks

**Update**
- Route: `PUT /student/{student}/update-student-details` (batch update as part of student details)
- Route: `PUT /student/{student}/update-address` (single address update)
- Single address update validates: address_type, address (max 512), city_id, pincode, is_primary

**Delete**
- Route: `DELETE /student/address/{addressId}`
- Soft deletes the address record

---

## 6. Academic Sessions & Subject Options

### 6.1 What It Does
Tracks the student's academic journey across sessions/years. Each session record represents the student's class-section assignment, roll number, house, and subject group for a particular academic year. Supports promotion/transfer workflows with historical preservation. Also manages student subject choices for optional subjects within a session.

### 6.2 Database Fields — std_student_academic_sessions

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `academic_session_id` | INT FK → `sch_org_academic_sessions_jnt` | Required. |
| `class_section_id` | INT FK → `sch_class_section_jnt` | Required. |
| `roll_no` | INT | Nullable. |
| `subject_group_id` | INT FK → `sch_subject_groups` | Nullable. For stream-based classes. |
| `house` | INT FK → `sys_dropdown_table` | Nullable. House assignment. |
| `is_current` | TINYINT(1) | Default 0. Only one active record per student. |
| `current_flag` | INT GENERATED | Generated column: `IF(is_current=1, student_id, NULL)`. Supports unique constraint. |
| `session_status_id` | INT FK → `sys_dropdown_table` | Required. PROMOTED / ACTIVE / LEFT / SUSPENDED / ALUMNI / WITHDRAWN. |
| `count_for_timetable` | TINYINT(1) | Default 1. Whether to count for timetable generation. |
| `leaving_date` | DATE | Nullable. Date of leaving/withdrawal. |
| `count_as_attrition` | TINYINT(1) | Default 0. Whether to count in attrition reports. |
| `reason_quit` | INT FK → `sys_dropdown_table` | Nullable. Reason for leaving the session. |
| `dis_note` | TEXT | Required. Discharge/discontinuation note. |

### 6.3 Database Fields — std_student_opted_subjects

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_academic_session_id` | INT FK → `std_student_academic_sessions` | Required. |
| `subject_group_id` | INT FK → `sch_subject_groups` | Nullable. |
| `subject_id` | INT FK → `sch_subjects` | Required. |
| `study_format_id` | INT FK → `sch_subject_study_format_jnt` | Required. Regular / Honors / AP, etc. |
| `sch_class_group_subject_options_id` | INT FK → `sch_class_group_subject_options` | Nullable. |
| `is_core` | TINYINT(1) | Default 0. Whether this is a core (non-optional) subject. |

### 6.4 Business Rules

**Single Current Session**
- Only one session per student can have `is_current = 1`
- When creating/updating a session with `is_current = true`, all other sessions for that student are set to `is_current = 0`
- Enforced at application level (not DB level — the generated `current_flag` column provides partial enforcement)

**Unique Student-Per-Session**
- A student can only have one record per academic session (unique constraint on `student_id, academic_session_id`)
- `updateOrCreate` pattern is used to upsert

**Auto-Update Class Section Count**
- On create/update/delete of a StudentAcademicSession, the `actual_total_student` count on the related `ClassSection` is recalculated
- Count is based on `is_current = 1` students in that class section
- Implemented via Eloquent model events (`booted`)

**Promotion Workflow**
1. Admin navigates to Academic Tab in Edit Mode
2. Clicks Promote/Transfer
3. Selects New Session, New Class, New Section
4. Sets session status (e.g., Promoted)
5. On save: old session `is_current = 0`, new session `is_current = 1`
6. Historical data preserved in old session record

**Optional Subject Selection**
- Students in higher classes may have optional subject choices
- The subject group defines available subjects; students choose which optional subjects to take
- Missing optional subjects detection: the Student List view has a dedicated tab showing students who:
  - Have a subject group but have not selected optional subjects from that group, OR
  - Are in a class-section that has optional subjects but have no subject group assigned

**Opted Subjects Sync**
- On session save/update, existing opted subjects for that session are deleted and re-inserted
- Duplicate subject IDs within the same session are prevented (array dedup)
- Each opted subject links to a study format and optionally to a class group subject option

**Session Statuses (sys_dropdown_table)**
- ACTIVE — currently enrolled
- PROMOTED — promoted to next class
- LEFT — left the school
- SUSPENDED — temporarily suspended
- ALUMNI — graduated
- WITHDRAWN — withdrawn

### 6.5 CRUD Operations

**Create (in admission flow)**
- Route: `POST /student/create-student-session`
- Supports both GET (show form) and POST (save)
- Validates: student_id, academic_session_id, class_section_id, subject_group_id, roll_no, is_current, session_status_id, house, leaving_date, count_as_attrition, reason_quit, dis_note, opted_subjects array
- Creates/updates session record
- Syncs opted subjects
- On success: redirects to `activeTab = student_previous_education`
- On failure: returns to session_details tab with error

**Update**
- Route: `PUT /session/{session}/update`
- Same validation as create
- Handles current flag cleanup
- Supports session image upload

**Delete**
- Route: `DELETE /session/{session}/delete`
- Soft deletes (or hard deletes depending on model config)
- Returns AJAX response if requested
- Cascades to opted subjects

**Get Session Data (AJAX)**
- Route: `GET /session/{session}/edit`
- Returns session data for inline editing

**Missing Optional Subjects Detection**
- Built into the Student List controller
- Complex subquery detects students with incomplete optional subject selections
- Shown in a separate paginated tab

### 6.6 Permissions
Same as Student Details permissions.

---

## 7. Previous Education

### 7.1 What It Does
Captures a student's educational history from previous schools, including transfer certificate (TC) details. Supports multiple previous school entries per student.

### 7.2 Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `school_name` | VARCHAR(150) | Required. |
| `school_address` | VARCHAR(255) | Nullable. |
| `board` | VARCHAR(50) | Nullable. CBSE, ICSE, State Board, etc. |
| `class_passed` | VARCHAR(50) | Nullable. |
| `year_of_passing` | YEAR | Nullable. |
| `percentage_grade` | VARCHAR(20) | Nullable. |
| `medium_of_instruction` | VARCHAR(30) | Nullable. English, Hindi, Gujarati, etc. |
| `tc_number` | VARCHAR(50) | Nullable. Transfer Certificate Number. |
| `tc_date` | DATE | Nullable. |
| `is_recognized` | TINYINT(1) | Default 1. Whether previous school was recognized. |
| `remarks` | TEXT | Nullable. |

### 7.3 Business Rules

**Multiple Previous Schools**
- A student can have multiple previous education records
- Displayed as a grid with [+ Add Previous School] button
- `updateOrCreate` pattern used with `school_name` + `tc_number` as unique identifiers

**TC Validation**
- TC number and date are optional but when provided, they are stored for audit purposes

### 7.4 CRUD Operations

**Create (in admission flow)**
- Route: `POST /student/create-student-prev-edu-details`
- Validates: student_id, school_name (nullable), school_address, board, class_passed, year_of_passing, percentage_grade, tc_number, tc_date, is_recognized, remarks
- Also handles document uploads in the same form
- Uses `updateOrCreate` with `student_id + school_name + tc_number` as unique key
- On success: redirects to `activeTab = student_health`
- On failure: returns to previous_education tab with error

**Update**
- Route: `PUT /previous-education/{education}/update`
- Validates: all previous education fields + multi-document arrays
- Updates the education record
- Handles document CRUD (create, update, delete) in the same request
- Supports document file uploads

**Delete**
- Route: `DELETE /previous-education/{education}/delete`
- Soft deletes the record

**Get Data (AJAX)**
- Route: `GET /previous-education/{education}/edit`
- Returns education data for inline editing

---

## 8. Student Documents

### 8.1 What It Does
Manages uploaded documents for each student — including ID proofs, transfer certificates, mark sheets, and other supporting documents. Each document has a verification workflow.

### 8.2 Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `document_name` | VARCHAR(100) | Required. Display name (e.g., 'Transfer Certificate'). |
| `document_type_id` | INT FK → `sys_dropdown_table` | Required. Document category. |
| `document_number` | VARCHAR(100) | Nullable. |
| `issue_date` | DATE | Nullable. |
| `expiry_date` | DATE | Nullable. Must be after or equal to issue_date. |
| `issuing_authority` | VARCHAR(150) | Nullable. |
| `is_verified` | TINYINT(1) | Default 0. Verified by school admin. |
| `verified_by` | INT FK → `sys_users` | Nullable. Who verified. |
| `verification_date` | DATETIME | Nullable. |
| `file_name` | VARCHAR(100) | Nullable. Stored filename in sys_media. |
| `media_id` | INT | Nullable. |
| `notes` | TEXT | Nullable. |

### 8.3 Business Rules

**Verification Workflow**
- Documents are uploaded unverified (`is_verified = 0` by default)
- Admin can mark documents as verified, setting `verified_by` and `verification_date`
- The dashboard alerts show count of unverified documents needing attention

**File Upload**
- Uses Spatie Media Library collection `student_document`
- Supported MIME types: pdf, jpg, jpeg, png, doc, docx
- Max file size: 2MB
- Image conversions: small, medium, large

**Expiry Validation**
- `expiry_date` must be after or equal to `issue_date` (validated at form level)
- Expiry dates are optional

**Multi-Document Support**
- A student can have unlimited documents
- In the admission flow, documents are uploaded on the Previous Education tab
- In the edit flow, documents can be added/updated/deleted independently

### 8.4 CRUD Operations

**Create (in admission flow)**
- Documents are uploaded as part of `POST /student/create-student-prev-edu-details`
- Multiple documents can be uploaded in one submission (array of document data with file uploads)
- Each document gets its own media collection entry

**Update**
- Route: `PUT /student-document/{document}/update`
- Updates document metadata and optionally replaces the file
- Handles Media Library collection clearing on file replacement

**Delete**
- Route: `DELETE /student-document/{document}/delete`
- Deletes document record and associated media

**Bulk Document Update**
- In `updatePreviousEducation`, documents are managed as arrays:
  - Existing documents matched by `document_ids[]`
  - New documents created for empty IDs
  - Documents not in the submission are deleted

---

## 9. Health & Medical

### 9.1 What It Does
Manages three aspects of student health: (1) health profile with blood group, allergies, chronic conditions, (2) vaccination records, and (3) medical incident logging for school clinic visits.

### 9.2 Database Fields — std_health_profiles

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. Unique. |
| `blood_group` | ENUM | `A+` / `A-` / `B+` / `B-` / `AB+` / `AB-` / `O+` / `O-`. |
| `height_cm` | DECIMAL(5,2) | Nullable. Last recorded. |
| `weight_kg` | DECIMAL(5,2) | Nullable. Last recorded. |
| `measurement_date` | DATE | Nullable. |
| `allergies` | TEXT | Nullable. CSV or notes. |
| `chronic_conditions` | TEXT | Nullable. Asthma, Diabetes, etc. |
| `medications` | TEXT | Nullable. Ongoing medications. |
| `dietary_restrictions` | TEXT | Nullable. |
| `vision_left` | VARCHAR(20) | Nullable. |
| `vision_right` | VARCHAR(20) | Nullable. |
| `doctor_name` | VARCHAR(100) | Nullable. |
| `doctor_phone` | VARCHAR(20) | Nullable. |

### 9.3 Database Fields — std_vaccination_records

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `vaccine_name` | VARCHAR(100) | Required. |
| `date_administered` | DATE | Nullable. |
| `next_due_date` | DATE | Nullable. |
| `remarks` | VARCHAR(255) | Nullable. |

### 9.4 Database Fields — std_medical_incidents

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `incident_date` | DATETIME | Required. |
| `incident_type_id` | INT FK → `sys_dropdown_table` | Required. Injury, Sickness, Fainting, etc. |
| `location` | VARCHAR(100) | Nullable. Playground, Classroom, etc. |
| `description` | TEXT | Required. |
| `first_aid_given` | TEXT | Nullable. |
| `action_taken` | VARCHAR(255) | Nullable. Sent home, Rested, Taken to hospital. |
| `reported_by` | INT FK → `sys_users` | Nullable. Teacher/Staff who reported. |
| `parent_notified` | TINYINT(1) | Default 0. |
| `closure_date` | DATE | Nullable. |
| `follow_up_required` | TINYINT(1) | Default 0. |

### 9.5 Business Rules

**Health Profile — One per Student**
- Each student has exactly one health profile (unique FK on `student_id`)
- Created as part of admission flow or separately via the health tab
- Physical measurements (height/weight) are a snapshot; historical tracking is not in the profile (separate growth tracking not yet implemented)

**Medical Incidents**
- Multiple incidents can be logged per student
- Each incident has a type (from sys_dropdown_table), description, and action taken
- Parent notification is tracked as a boolean flag
- Follow-up tracking: `follow_up_required` + `closure_date`
- Toggle endpoints for `parent_notified` and `follow_up_required` (AJAX)

**Vaccination Records**
- Multiple vaccination records per student
- Separate table from health profile (not tracked in profile)

### 9.6 CRUD Operations

**Create (in admission flow)**
- Route: `POST /student/create-student-medical-details`
- Creates/updates health profile, vaccination records, and optionally logs first medical incident
- Part of the admission flow's Health tab

**Update Health Profile**
- Route: `PUT /student/{student}/health-profile/update`
- `updateOrCreate` pattern for health profile
- Validates: blood_group, height_cm, weight_kg, allergies, chronic_conditions, medications, dietary_restrictions, vision, doctor info

**Update Vaccination Record**
- Route: `PUT /vaccination/{vaccination}/update`
- Delete: `DELETE /vaccination/{vaccination}/delete`

**Medical Incidents CRUD**
- Full resource controller: `MedicalIncidentController`
- Routes: `GET /medical-incidents`, `POST /medical-incidents`, `GET /medical-incidents/{id}`, etc.
- Additionally:
  - AJAX student search: `GET /ajax/medical-incidents/get-students`
  - Trash view, restore, force delete
  - Toggle follow-up: `POST /medical-incidents/{id}/toggle-follow-up`
  - Toggle parent notified: `POST /medical-incidents/{id}/toggle-parent-notified`

### 9.7 Permissions
- Medical incidents use their own resource permissions (not tenant.student.*)
- Follow standard Laravel resource authorization patterns

---

## 10. Attendance

### 10.1 What It Does
Manages daily student attendance with period-wise marking. Supports manual entry, bulk marking, and a correction request workflow for parents/students to dispute attendance records.

### 10.2 Database Fields — std_student_attendance

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `academic_session_id` | INT FK → `sch_org_academic_sessions_jnt` | Required. |
| `class_section_id` | INT FK → `sch_class_section_jnt` | Required. |
| `attendance_date` | DATE | Required. |
| `attendance_period` | TINYINT | Default 0. Period number (0 = full day). |
| `status` | ENUM | `Present` / `Absent` / `Late` / `Half Day` / `Short Leave` / `Leave`. |
| `remarks` | VARCHAR(255) | Nullable. |
| `marked_by` | INT FK → `sys_users` | Nullable. Who marked. |
| `marked_at` | TIMESTAMP | Auto-set on save. |

### 10.3 Database Fields — std_attendance_corrections

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `attendance_id` | INT FK → `std_student_attendance` | Required. |
| `requested_by` | INT FK → `sys_users` | Required. Parent or Student. |
| `requested_status` | ENUM | `Present` / `Absent` / `Late` / `Half Day` / `Short Leave` / `Leave`. |
| `requested_period` | TINYINT | Default 0. |
| `reason` | TEXT | Required. |
| `status` | ENUM | `Pending` / `Approved` / `Rejected`. Default: `Pending`. |
| `admin_remarks` | VARCHAR(255) | Nullable. Admin/Teacher remark on approval/rejection. |
| `action_by` | INT FK → `sys_users` | Nullable. Admin who acted. |
| `action_at` | TIMESTAMP | Nullable. When acted upon. |

### 10.4 Business Rules

**Period-Wise Attendance**
- Controlled by system setting `Period_wise_Student_Attendance` (TRUE/FALSE)
- When enabled, attendance can be marked per period
- Unique constraint per `(student_id, attendance_date, attendance_period)`

**Daily Attendance Marking**
- Route: `POST /student/attendance/manual` for single student marking
- Route: `POST /student/attendance/bulk/store` for bulk class-wise marking
- Class section + date = marking context

**Correction Request Workflow**
- Parent/Student submits a correction request when they believe attendance was marked incorrectly
- Status: `Pending` → `Approved` or `Rejected`
- Admin provides remarks on decision
- On approval, the main attendance record is updated
- Correction record remains as audit trail

**Attendance Policy**
- Policy class: `AttendancePolicy`
- Used for authorization checks on attendance operations

### 10.5 CRUD Operations

**Manual Attendance**
- Route: `POST /student/attendance/manual`
- Single student, single date, single status

**Bulk Attendance**
- Routes: `GET /bulk-attendance` (form), `POST /bulk-attendance/store` (save)
- Mark attendance for all students in a class-section for a given date
- Missing students (no record created) are not auto-marked

**Scan Attendance**
- Route: `POST /student/attendance/scan`
- For RFID/NFC/QR code based marking
- Reads student identifier from scan input

**Correction Requests**
- Correction records are created by parents/students via API/portal
- Admin reviews through the attendance management interface
- Approval updates the original attendance record

### 10.6 Permissions
Gated via `AttendancePolicy`:
- View attendance: depends on role
- Mark attendance: Teachers, Admin
- Approve corrections: Admin only

---

## 11. Student Leave Management

### 11.1 What It Does
A full-featured student leave application system with an 8-state finite state machine (FSM). Students apply for leave via the Student Portal; class teachers review, approve/reject, or request additional information/documents. On approval, attendance records are automatically updated.

### 11.2 Database Fields — std_leave_types

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `code` | VARCHAR(30) | Required. Unique. SICK, CASUAL, MEDICAL, BEREAVEMENT, FESTIVAL, etc. |
| `name` | VARCHAR(100) | Required. Display name. |
| `description` | VARCHAR(255) | Nullable. |
| `max_days_per_application` | TINYINT | Default 30. Max consecutive days allowed. 0 = no limit. |
| `max_days_per_year` | SMALLINT | Default 0. Annual quota. 0 = unlimited. |
| `requires_document` | TINYINT(1) | Default 0. 1 = supporting document mandatory. |
| `allow_half_day` | TINYINT(1) | Default 1. 1 = half-day leave allowed. |
| `advance_notice_days` | TINYINT | Default 0. Minimum advance notice in days. |
| `is_active` | TINYINT(1) | Default 1. |

### 11.3 Database Fields — std_leave_applications

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `student_id` | INT FK → `std_students` | Required. |
| `academic_session_id` | INT FK → `sch_org_academic_sessions_jnt` | Required. |
| `class_section_id` | INT FK → `sch_class_section_jnt` | Required. Routes to class teacher. |
| `leave_type_id` | INT FK → `std_leave_types` | Required. |
| `from_date` | DATE | Required. First day of leave. |
| `to_date` | DATE | Required. Last day (= from_date for single-day). |
| `total_days` | TINYINT | Default 1. Calendar days (app layer excludes holidays if configured). |
| `is_half_day` | TINYINT(1) | Default 0. Only valid when from_date = to_date. |
| `half_day_slot` | ENUM | `Morning` / `Afternoon`. Only when is_half_day = 1. |
| `reason` | TEXT | Required. Student-provided reason. |
| `status` | ENUM | `Draft` / `Submitted` / `Under Review` / `Info Requested` / `Doc Requested` / `Approved` / `Rejected` / `Cancelled`. Default: `Draft`. |
| `applied_by` | INT FK → `sys_users` | Required. Student or parent who submitted. |
| `reviewed_by` | INT FK → `sys_users` | Nullable. Class teacher who reviewed. |
| `reviewed_at` | TIMESTAMP | Nullable. |
| `approved_days` | TINYINT | Nullable. May differ from total_days if partially approved. |
| `review_remarks` | TEXT | Nullable. Teacher remarks. |

### 11.4 Database Fields — std_leave_application_documents

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `leave_application_id` | INT FK → `std_leave_applications` | Required. |
| `document_name` | VARCHAR(150) | Required. Display name. |
| `document_type_id` | INT FK → `sys_dropdown_table` | Nullable. |
| `description` | VARCHAR(255) | Nullable. |
| `file_name` | VARCHAR(255) | Required. Stored in sys_media. |
| `media_id` | INT | Nullable. |
| `uploaded_by` | INT FK → `sys_users` | Required. |
| `is_in_response_to_request` | TINYINT(1) | Default 0. 1 = uploaded in response to teacher doc request. |
| `request_remark_id` | INT FK → `std_leave_application_remarks` | Nullable. Links to the Doc Requested remark. |

### 11.5 Database Fields — std_leave_application_remarks

| Field | Type | Conditions |
|---|---|---|
| `id` | INT PK | Auto-increment |
| `leave_application_id` | INT FK → `std_leave_applications` | Required. |
| `remark_type` | ENUM | `Comment` / `Info_Request` / `Doc_Request` / `Response` / `Status_Change`. |
| `message` | TEXT | Required. |
| `is_from_teacher` | TINYINT(1) | Default 0. 1 = from teacher; 0 = from student. |
| `remarked_by` | INT FK → `sys_users` | Required. Who wrote this. |
| `parent_remark_id` | INT FK → self | Nullable. Links response to the specific query. |
| `is_resolved` | TINYINT(1) | Default 0. 1 = request answered/fulfilled. |
| `resolved_at` | TIMESTAMP | Nullable. |
| `old_status` | VARCHAR(30) | Nullable. For status_change type only. |
| `new_status` | VARCHAR(30) | Nullable. For status_change type only. |

### 11.6 Business Rules

**Leave Application FSM**
```
Draft → Submitted → Under Review → Info Requested / Doc Requested → Submitted (re-opened)
                                                    ↘
                                         Approved / Rejected
Draft / Submitted / Info Requested / Doc Requested → Cancelled (by student)
```

- **Draft**: Saved but not yet submitted (visible only to student)
- **Submitted**: Formally submitted; visible to class teacher
- **Under Review**: Class teacher has opened and is reviewing
- **Info Requested**: Teacher asked for additional information (ball in student's court)
- **Doc Requested**: Teacher asked for supporting document (ball in student's court)
- **Approved**: Leave approved; app layer marks attendance as 'Leave'
- **Rejected**: Leave rejected with reason
- **Cancelled**: Cancelled by student before final decision

**Half-Day Validation**
- `is_half_day = 1` is only valid when `from_date = to_date`
- When half-day, `half_day_slot` must be specified (Morning/Afternoon)

**Attendance Sync on Approval**
- On status change to **Approved**: application layer creates `std_student_attendance` records with `status = Leave` for each working day in `[from_date .. to_date]`
- On status change to **Rejected** or **Cancelled**: no attendance impact

**Communication Thread**
- Teachers and students communicate via remarks
- Remark types:
  - `comment` — general note (informational)
  - `info_request` — teacher asks for clarification
  - `doc_request` — teacher requests a document
  - `response` — student replies to a request
  - `status_change` — auto-logged by system (audit trail)
- When student responds, application status reverts to `Submitted` for teacher re-review
- `is_resolved` marks requests as addressed

**Leave Type Configuration**
- School admin configures leave types with policies:
  - Per-application day limit
  - Annual quota
  - Document requirement (mandatory for medical leave)
  - Half-day allowance
  - Advance notice requirement

**Review Workflow**
- `/student-leave/{id}/review` — teacher review page
- `/student-leave/{id}/update-review` — POST/UPDATE to approve, reject, or request info/doc
- `/student-leave/remarks/store` — AJAX endpoint for adding remarks
- Teacher can also edit leave application details from review page

### 11.7 CRUD Operations

**Leave Types CRUD**
- Full resource controller: `StudentLeaveTypeController`
- Routes: `resource('student-leave-types', StudentLeaveTypeController::class)`
- Soft delete, restore, force delete, toggle status
- Trash view: `GET /student-leave-types/trash`

**Leave Applications — Teacher View**
- Route: `GET /student-leave` — list of applications for the teacher's class section
- Route: `GET /student-leave/{id}/review` — detailed review page with timeline
- Route: `PUT /student-leave/{id}/update-review` — approve/reject/request-info

**AJAX Endpoints**
- `GET /ajax/student-leave/students` — get students by section
- `GET /ajax/student-leave/applications` — get applications by student
- `POST /student-leave/remarks/store` — store a new remark

**Leave Application — Student Portal**
- Students submit via Student Portal (Mobile app/web)
- Application is routed to the class teacher based on `class_section_id`

### 11.8 Permissions
- Review permissions are role-based (Class Teacher, Admin, Principal)
- Students can only view/edit their own applications

---

## 12. Reports & Dashboard

### 12.1 Dashboard
**Route:** `/students/dashboard` or `/dashboard/student-profile`
**Role Access:** Principal, School Admin, Coordinator

#### KPI Cards
| Widget | Data Source | Logic |
|---|---|---|
| **Total Students** | `std_students` | Count where `is_active = 1` AND `current_status = 'Active'`. Click → filtered list. |
| **New Admissions** | `std_students` | Count where `admission_date` is in current academic session. Click → filtered list. |
| **Attrition (YTD)** | `std_student_academic_sessions` | Count where `count_as_attrition = 1` in current session. |
| **Attendance Today** | `std_student_attendance` | % Present / Total Marked for today's date. |

#### Charts
| Chart | Type | Data Source |
|---|---|---|
| Student Distribution | Bar Chart | `std_student_academic_sessions` grouped by class |
| Gender Ratio | Donut Chart | `std_students.gender` |
| Admission Trend | Line Chart | Annual admission counts over last 5 years |
| Student Categories | Table | Caste category + RTE/EWS counts |

#### Critical Alerts
1. **Doc Verification Needed**: `std_student_documents` where `is_verified = 0`
2. **Low Attendance**: Classes with avg daily attendance < 75%
3. **Suspended Students**: Students with `current_status_id` mapping to 'Suspended'

#### Quick Actions
- [+ New Admission] → Create flow
- [Bulk Import] → CSV/Excel import
- [ID Card Print] → Batch ID card generation

### 12.2 Report Types

**1. Class-wise Student Strength Report**
- **Purpose**: Breakdown of student count per Class and Section with gender and category distribution
- **Filters**: Academic Session, Class (Range)
- **Fields**: Class Name, Section, Total Students, Boys, Girls, General, OBC/SC/ST, RTE/EWS, Class Teacher
- **Tables**: `std_student_academic_sessions`, `sch_class_section_jnt`, `std_students`, `std_student_profiles`
- **Chart**: Stacked Bar Chart (Gender Split by Class)

**2. Admission Register Report**
- **Purpose**: List of new admissions in a date range for government submission/audit
- **Filters**: Admission Date Range, Class
- **Fields**: Admission No, Date, Student Name, DOB, Gender, Father/Mother Name, Address, Previous School, TC Number
- **Tables**: `std_students`, `std_guardians`, `std_previous_education`

**3. Student Medical Profile & Exceptions**
- **Purpose**: Students with medical conditions, missing vaccinations, recent incidents
- **Filters**: Health Condition (Has Allergy / Has Condition), Blood Group
- **Fields**: Student Name, Class-Section, Blood Group, Allergies, Chronic Conditions, Emergency Contact
- **Tables**: `std_health_profiles`, `std_students`, `std_student_guardian_jnt`, `std_guardians`
- **Useful For**: School Nurse, PE Teachers

**4. Caste Category Distribution Report**
- **Purpose**: Category-wise student distribution for government compliance
- **Filters**: Academic Session
- **Tables**: `std_student_profiles`, `std_students`

**5. Age-wise Student Report**
- **Purpose**: Age distribution of students as of a reference date
- **Filters**: Academic Session, Age Range
- **Tables**: `std_students`

**6. Suspended/Inactive Student Report**
- **Purpose**: List of suspended, withdrawn, or left students
- **Filters**: Status, Date Range
- **Tables**: `std_student_academic_sessions`, `std_students`

**7. RTE/EWS Quota Report**
- **Purpose**: RTE and EWS quota compliance
- **Tables**: `std_student_profiles`

**8. Student Attendance Summary Report**
- **Filters**: Session, Class, Section, Date Range
- **Fields**: Student Name, Total Days, Present, Absent, Late, Leave, Percentage
- **Tables**: `std_student_attendance`

**9. Student ID Card Report**
- **Purpose**: Batch ID card generation with QR code
- **Route**: `GET /student/{student}/print-id-card`
- Uses Template system to render card layout

**10. Missing Optional Subjects Report**
- **Purpose**: Students who have not completed optional subject selection
- Built into the Student List view as a dedicated tab

**11. Student Login Credentials Report**
- **Purpose**: Send login credentials to selected students
- Route: `POST /students/send-credentials`

### 12.3 Student Report Routes
- `GET /reports-mgt` — combined report management view
- `GET /reports/class-wise-student-strength` — class strength report

### 12.4 Permissions for Reports
| Report | View Permission |
|---|---|
| All reports | `tenant.student.viewAny` |
| Export | `tenant.student.export` |

---

## 13. Permissions Matrix

| Operation | Super Admin | School Admin | Principal | Teacher | Clerk |
|---|---|---|---|---|---|
| View Student List | ✓ | ✓ | ✓ | ✓ | ✓ |
| View Student Detail (360°) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Create Student Login | ✓ | ✓ | ✗ | ✗ | ✓ |
| Edit Basic Info | ✓ | ✓ | ✗ | ✗ | ✓ |
| Edit Family/Guardian | ✓ | ✓ | ✗ | ✗ | ✓ |
| Edit Academic Session | ✓ | ✓ | ✗ | ✗ | ✓ |
| Edit Health/Medical | ✓ | ✓ | ✗ | ✓* | ✓ |
| Mark Attendance | ✓ | ✓ | ✗ | ✓ | ✗ |
| Approve Corrections | ✓ | ✓ | ✗ | ✓ | ✗ |
| Review Leave Applications | ✓ | ✓ | ✗ | ✓ | ✗ |
| Print ID Card | ✓ | ✓ | ✓ | ✓ | ✓ |
| Export Reports | ✓ | ✓ | ✓ | ✗ | ✓ |
| Delete Student | ✓ | ✓ | ✗ | ✗ | ✗ |
| Restore Student | ✓ | ✓ | ✗ | ✗ | ✗ |

*\*Teachers may only edit specific fields like Attendance/Remarks.*

---

## 14. Implementation Checklist

- [ ] Student Login CRUD (create + update + email notification)
- [ ] Student Details CRUD with photo upload & user sync
- [ ] Guardian Management (new + existing linking, multi-guardian)
- [ ] Parent Portal user creation with role assignment
- [ ] Address management (dynamic array, single primary)
- [ ] Academic Session CRUD with promotion workflow
- [ ] Auto-update ClassSection student count on session changes
- [ ] Optional Subject selection with missing detection
- [ ] Previous Education CRUD
- [ ] Student Document upload + verification workflow
- [ ] Health Profile (blood group, allergies, conditions)
- [ ] Vaccination Records CRUD
- [ ] Medical Incidents (full resource + toggle endpoints)
- [ ] Daily Attendance (manual, bulk, scan)
- [ ] Attendance Correction Request workflow
- [ ] Leave Types CRUD with soft delete
- [ ] Leave Application FSM (8 states)
- [ ] Attendance auto-sync on leave approval
- [ ] Teacher↔Student communication thread (remarks)
- [ ] Dashboard KPI cards + charts + alerts
- [ ] 11+ Reports (strength, admission, medical, caste, age, attendance, etc.)
- [ ] ID Card generation via Template system
- [ ] Export to Excel
- [ ] Soft delete with trash view, restore, force delete for all entities
- [ ] Bulk operations (restore, force delete, empty trash)
- [ ] Admission progress tracking (completed tabs, percentage)
- [ ] Sibling auto-detection via mobile number

---

*End of Requirements Document*
