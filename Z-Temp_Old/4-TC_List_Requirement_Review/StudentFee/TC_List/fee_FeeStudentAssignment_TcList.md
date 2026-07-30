# fee_FeeStudentAssignment_TcList

## Module: StudentFee → Assignment → Fee Student Assignment

## 1. Feature Information

| Item | Details |
|---|---|
| Module / Tab Group / Feature | StudentFee / Assignment / Fee Student Assignment |
| URL(s) | `GET /student-fee/assignment` (tab load) <br> `GET /student-fee/fee-student-assignment` (index redirect) <br> `GET /student-fee/fee-student-assignment/create` <br> `POST /student-fee/fee-student-assignment` <br> `GET /student-fee/fee-student-assignment/{fee_student_assignment}` <br> `GET /student-fee/fee-student-assignment/{fee_student_assignment}/edit` <br> `PUT /student-fee/fee-student-assignment/{fee_student_assignment}` <br> `DELETE /student-fee/fee-student-assignment/{fee_student_assignment}` <br> `POST /student-fee/fee-student-assignment/generate/all` <br> `GET /student-fee/fee-student-assignment/trash/view` <br> `GET /student-fee/fee-student-assignment/{id}/restore` <br> `DELETE /student-fee/fee-student-assignment/{id}/force-delete` <br> `POST /student-fee/fee-student-assignment/{fee_student_assignment}/toggle-status` <br> `GET /student-fee/fee-student-assignment/sections-by-class/{classId}` <br> `PATCH /student-fee/fee-student-assignment/{id}/update-structure` |
| Controller | `Modules\StudentFee\Http\Controllers\FeeStudentAssignmentController` |
| Model(s) | `Modules\StudentFee\Models\FeeStudentAssignment` (table: `fee_student_assignments`) |
| Validation (Create) | `Modules\StudentFee\Http\Requests\StoreFeeStudentAssignmentRequest` |
| Validation (Update) | `Modules\StudentFee\Http\Requests\UpdateFeeStudentAssignmentRequest` |
| Validation (Structure-Only Update) | `Modules\StudentFee\Http\Requests\UpdateFeeAssignmentStructureRequest` |
| Policy | `Modules\StudentFee\Policies\FeeStudentAssignmentPolicy` |
| Permissions | `tenant.fee-student-assignment.create`, `tenant.fee-student-assignment.view`, `tenant.fee-student-assignment.update`, `tenant.fee-student-assignment.delete`, `tenant.fee-student-assignment.restore`, `tenant.fee-student-assignment.forceDelete`, `tenant.fee-student-assignment.status`, `tenant.student-fee-management.viewAny` (tab load) |
| Pagination | 12 records per page using default `page` parameter |
| Soft Deletes | Yes — `SoftDeletes` trait on `FeeStudentAssignment` |
| Activity Log | `Created`, `Updated`, `Trashed`, `Restored`, `Toggled`, `Deleted` (force delete) logged via `activityLog()` |
| Data Source | Direct CRUD on `fee_student_assignments`; bulk generate uses `Modules\StudentProfile\Models\StudentAcademicSession` joined with `Modules\StudentFee\Models\FeeStructureMaster` |

---

## 2. Pre-conditions

- Tenant URL is configured via `DUSK_TENANT_URL`.
- An admin user with credentials `DUSK_ADMIN_EMAIL` and `DUSK_ADMIN_PASSWORD` exists and has all `tenant.fee-student-assignment.*` and `tenant.student-fee-management.viewAny` permissions.
- A current academic session is set (required for create, generate, and default load).
- Reference data exists: `std_students` rows with active users, `sch_classes`, `sch_sections`, `sch_org_academic_sessions_jnt`, and `fee_structure_master` records linked to the current session.
- For negative tests, create a user role that lacks each permission individually.
- Clean up `fee_student_assignments` test rows before and after each run to avoid unique-key conflicts.

---

## 3. Default Data Load

The default load is handled by `StudentFeeManagementController::assignment()` via `GET /student-fee/assignment`, gated by `tenant.student-fee-management.viewAny`. It filters to the current academic session, applies `search` and `status` filters, and paginates 12 records per page using the default `page` parameter.

| Data | Source | Query | Filters | Pagination |
|---|---|---|---|---|
| Shared dropdowns | `create()` / `edit()` | `Student::with('user')`, `ClassSection::with(['class','section'])`, `FeeStructureMaster::where('is_active', 1)` | `is_active = 1`, session-scoped for structures | None |
| Assignment grid | `assignment()` | `FeeStudentAssignment::with(['student.user','class','section','feeStructure'])` | Current session, `search` (name/admission no), `status` | 12 per page (`page`) |
| Trashed assignments | `trashedFeeStudentAssignments()` | `FeeStudentAssignment::onlyTrashed()->with(['student.user'])` | `orderByDesc('created_at')` | 10 per page (`page`) |

> **Data Source:** The bulk generate route reads `StudentAcademicSession` from the StudentProfile module and matches it against `FeeStructureMaster` from the StudentFee module.

---

## 4. Test Data Strategy

- Create assignments via direct DB inserts for dependency and negative tests, or via the UI for positive lifecycle tests.
- Use consistent academic session and class/section references across all tests.
- Create at least 13 assignments to test pagination (12 + 1 overflow).
- For search tests, prepare students with distinct first names, last names, and admission numbers.
- For duplicate tests, seed one assignment for a student in the current session.
- For delete/restore tests, create assignments with and without related `fee_invoices` and `fee_student_concessions` to verify FK behavior.
- Clean up all test rows in `fee_student_assignments` after each test run to avoid `uq_fee_student_session` conflicts.

---

## 5. Business Conditions

### 5.1 Database Schema — fee_student_assignments

> **Note:** The form request and view use the field name `join_in_mid_year` (underscore), while the DDL column is `join_in_mid-year` (hyphen). The controller maps the request to the column, but this is a naming inconsistency.

| BC ID | Column | Type (DDL) | Constraints |
|---|---|---|---|
| BC-DB-01 | `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| BC-DB-02 | `student_id` | INT UNSIGNED NOT NULL | FK → `std_students.id` ON DELETE CASCADE |
| BC-DB-03 | `class_id` | INT UNSIGNED NOT NULL | FK → `sch_classes.id` ON DELETE RESTRICT |
| BC-DB-04 | `section_id` | INT UNSIGNED NULL | FK → `sch_sections.id` ON DELETE RESTRICT |
| BC-DB-05 | `academic_session_id` | SMALLINT UNSIGNED NOT NULL | FK → `sch_org_academic_sessions_jnt.id` ON DELETE RESTRICT |
| BC-DB-06 | `fee_structure_id` | INT UNSIGNED NOT NULL | FK → `fee_structure_master.id` ON DELETE RESTRICT |
| BC-DB-07 | `total_fee_amount` | DECIMAL(12,2) NOT NULL | — |
| BC-DB-08 | `opted_heads` | JSON NULL | COMMENT 'Selected optional heads' |
| BC-DB-09 | `opted_groups` | JSON NULL | COMMENT 'Selected optional groups' |
| BC-DB-10 | `assignment_date` | DATE NOT NULL | — |
| BC-DB-11 | `join_in_mid-year` | TINYINT(1) NOT NULL DEFAULT 0 | — |
| BC-DB-12 | `fee_start_date` | DATE NULL | COMMENT 'Actual fee start date for mid-year joins' |
| BC-DB-13 | `proration_percentage` | DECIMAL(5,2) NULL | COMMENT 'Percentage of total fee applicable' |
| BC-DB-14 | `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | INDEX `idx_fee_assignment_active` |
| BC-DB-15 | `created_at` | TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP | — |
| BC-DB-16 | `updated_at` | TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | — |
| BC-DB-17 | `deleted_at` | TIMESTAMP NULL | Soft-delete timestamp |
| BC-DB-18 | UNIQUE KEY `uq_fee_student_session` | (`student_id`, `academic_session_id`) | Prevents duplicate assignment per student/session |
| BC-DB-19 | INDEX `idx_fee_assignment_active` | (`is_active`) | Filter index |

### 5.2 Validation Rules — StoreFeeStudentAssignmentRequest (Create)

| BC ID | Field | Rule(s) | Error Message |
|---|---|---|---|
| BC-VAL-01 | `student_id` | `required`, `integer`, `exists:std_students,id` | Laravel default: "The student id field is required." / "The selected student id is invalid." |
| BC-VAL-02 | `class_id` | `required`, `integer`, `exists:sch_classes,id` | Laravel default required/invalid messages |
| BC-VAL-03 | `section_id` | `nullable`, `integer`, `exists:sch_sections,id` | Laravel default invalid messages |
| BC-VAL-04 | `academic_session_id` | `required`, `integer` | Laravel default required/integer messages |
| BC-VAL-05 | `fee_structure_id` | `required`, `integer`, `exists:fee_structure_master,id` | Laravel default required/invalid messages |
| BC-VAL-06 | `assignment_date` | `required`, `date` | Laravel default required/date messages |
| BC-VAL-07 | `is_active` | `required`, `boolean` | Laravel default required/boolean messages |
| BC-VAL-08 | `opted_heads` | `nullable` | Laravel default messages |
| BC-VAL-09 | `opted_groups` | `nullable` | Laravel default messages |
| BC-VAL-10 | `join_in_mid_year` | `nullable`, `boolean` | Laravel default boolean messages |
| BC-VAL-11 | `fee_start_date` | `required_if:join_in_mid_year,1`, `nullable`, `date` | Laravel default required_if/date messages |
| BC-VAL-12 | `proration_percentage` | `required_if:join_in_mid_year,1`, `nullable`, `numeric`, `min:0`, `max:100` | Laravel default numeric/min/max messages |

### 5.3 Validation Rules — UpdateFeeStudentAssignmentRequest (Update)

| BC ID | Field | Rule(s) | Error Message |
|---|---|---|---|
| BC-VAL-13 | `class_id` | `required`, `integer`, `exists:sch_classes,id` | Laravel default required/invalid messages |
| BC-VAL-14 | `section_id` | `nullable`, `integer`, `exists:sch_sections,id` | Laravel default invalid messages |
| BC-VAL-15 | `fee_structure_id` | `required`, `integer`, `exists:fee_structure_master,id` | Laravel default required/invalid messages |
| BC-VAL-16 | `total_fee_amount` | `required`, `numeric`, `min:0` | Laravel default required/numeric/min messages |
| BC-VAL-17 | `assignment_date` | `required`, `date` | Laravel default required/date messages |
| BC-VAL-18 | `is_active` | `required`, `boolean` | Laravel default required/boolean messages |
| BC-VAL-19 | `opted_heads` | `nullable` | Laravel default messages |
| BC-VAL-20 | `opted_groups` | `nullable` | Laravel default messages |
| BC-VAL-21 | `join_in_mid_year` | `nullable`, `boolean` | Laravel default boolean messages |
| BC-VAL-22 | `fee_start_date` | `required_if:join_in_mid_year,1`, `nullable`, `date` | Laravel default required_if/date messages |
| BC-VAL-23 | `proration_percentage` | `required_if:join_in_mid_year,1`, `nullable`, `numeric`, `min:0`, `max:100` | Laravel default numeric/min/max messages |

### 5.4 Validation Rules — UpdateFeeAssignmentStructureRequest

| BC ID | Field | Rule(s) | Error Message |
|---|---|---|---|
| BC-VAL-24 | `fee_structure_id` | `required`, `integer`, `exists:fee_structure_master,id` | Laravel default required/invalid messages |

### 5.5 Authorization

| BC ID | Permission | Behavior |
|---|---|---|
| BC-AUTH-01 | Guest access | Redirected to `/login` |
| BC-AUTH-02 | `tenant.fee-student-assignment.create` | Required for `create`, `store`, `generateStudentAssignment`; without it → 403 |
| BC-AUTH-03 | `tenant.fee-student-assignment.view` | Required for `show`; without it → 403 |
| BC-AUTH-04 | `tenant.fee-student-assignment.update` | Required for `edit`, `update`, `updateAssignmentStructure`; without it → 403 |
| BC-AUTH-05 | `tenant.fee-student-assignment.delete` | Required for `destroy`; without it → 403 |
| BC-AUTH-06 | `tenant.fee-student-assignment.restore` | Required for `trashedFeeStudentAssignments`, `restore`; without it → 403 |
| BC-AUTH-07 | `tenant.fee-student-assignment.forceDelete` | Required for `forceDelete`; without it → 403 |
| BC-AUTH-08 | `tenant.fee-student-assignment.status` | Required for `toggleStatus`; without it → 403 |
| BC-AUTH-09 | `tenant.student-fee-management.viewAny` | Required to open `GET /student-fee/assignment`; without it → 403 |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|---|---|---|
| BC-BIZ-01 | Default tab load | Grid shows only assignments for the current academic session, sorted by latest first |
| BC-BIZ-02 | Search by student name | Filters assignments where `student.user.name` matches the search term |
| BC-BIZ-03 | Search by admission number | Filters assignments where `student.admission_no` matches the search term |
| BC-BIZ-04 | Filter status = 1 | Grid shows only `is_active = true` assignments |
| BC-BIZ-05 | Filter status = 0 | Grid shows only `is_active = false` assignments |
| BC-BIZ-06 | Pagination | 12 records per page; `page` parameter advances the result set |
| BC-BIZ-07 | Card / list view | Clicking card/list buttons toggles the visible container and persists the preference in `localStorage` |
| BC-BIZ-08 | Empty state | When no assignments match, both card and list views show "No Fee Assignments Found" |
| BC-BIZ-09 | Total assignments card | The statistics card shows the count of assignments for the current session |
| BC-BIZ-10 | Duplicate prevention | `store()` returns error if `student_id + academic_session_id` already exists; DB unique key also enforces it |
| BC-BIZ-11 | Structure session mismatch | `store()` returns error if the selected `fee_structure_id` does not belong to the submitted `academic_session_id` |
| BC-BIZ-12 | Total amount on create | `store()` sets `total_fee_amount` from the selected fee structure, not from any submitted value |
| BC-BIZ-13 | Mid-year toggle | Checking `join_in_mid_year` makes `fee_start_date` and `proration_percentage` required; unchecking clears them |
| BC-BIZ-14 | Class→section AJAX | Selecting a class filters the section dropdown to sections linked to that class |
| BC-BIZ-15 | Bulk generate | `generateStudentAssignment()` creates assignments for all active student sessions of the current session |
| BC-BIZ-16 | Bulk generate idempotency | Existing assignments (including trashed) are restored and updated instead of duplicated |
| BC-BIZ-17 | Bulk generate skip | Students whose class has no active fee structure or no class-section mapping are skipped and counted |
| BC-BIZ-18 | Restore reactivates | `restore()` sets `is_active = true` after restoring the soft-deleted row |
| BC-BIZ-19 | Destroy deactivates | `destroy()` sets `is_active = false` before calling `delete()` |
| BC-BIZ-20 | Toggle JSON response | `toggleStatus()` returns JSON with `success`, `is_active`, and translated flash message |
| BC-BIZ-21 | PATCH update-structure | `updateAssignmentStructure()` updates `fee_structure_id` and `total_fee_amount` from the new structure |
| BC-BIZ-22 | No active session guard on create | `create()` redirects with error if no current academic session exists |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|---|---|---|---|
| BC-REF-01 | `student_id` | `std_students` | CASCADE |
| BC-REF-02 | `class_id` | `sch_classes` | RESTRICT |
| BC-REF-03 | `section_id` | `sch_sections` | RESTRICT |
| BC-REF-04 | `academic_session_id` | `sch_org_academic_sessions_jnt` | RESTRICT |
| BC-REF-05 | `fee_structure_id` | `fee_structure_master` | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-P01 | Assignment tab loads with all UI elements | Page shows search, status filter, card/list toggle, generate banner, total assignments card, and assignment grid | — | — | ⬜ |
| TC-P02 | Default card view | Assignments render as cards with student name, admission no, class-section, structure, total fee, status, and action buttons | — | — | ⬜ |
| TC-P03 | Switch to list view | Clicking list view shows a table with Student, Adm No, Class & Section, Fee Structure, Total Fee, Status, Action columns | — | — | ⬜ |
| TC-P04 | Pagination navigation | Page 2 link displays the next set of assignments and updates the `page` query string | — | — | ⬜ |
| TC-P05 | Search by student first name | Grid returns assignments whose student name contains the search term | — | — | ⬜ |
| TC-P06 | Search by admission number | Grid returns assignments whose admission number matches the search term | — | — | ⬜ |
| TC-P07 | Filter active assignments | Status filter "1" returns only assignments with `is_active = true` | — | — | ⬜ |
| TC-P08 | Filter inactive assignments | Status filter "0" returns only assignments with `is_active = false` | — | — | ⬜ |
| TC-P09 | Create assignment with required fields only | Assignment is created with `total_fee_amount` from the structure, redirected to show page with success message | — | — | ⬜ |
| TC-P10 | Create assignment with optional heads and groups | Assignment is created with `opted_heads` and `opted_groups` stored as JSON arrays | — | — | ⬜ |
| TC-P11 | Create assignment with mid-year join and proration | Assignment is created with `join_in_mid-year = true`, `fee_start_date`, and `proration_percentage` stored | — | — | ⬜ |
| TC-P12 | Bulk generate assignments for all active students | Controller iterates active student sessions, creates missing assignments, and flashes counts | — | — | ⬜ |
| TC-P13 | Bulk generate skips students without matching fee structure | Skipped count is reported in the success message | — | — | ⬜ |
| TC-P14 | Show assignment details | Detail page displays student info, fee structure info, financial details, status, and optional selections | — | — | ⬜ |
| TC-P15 | Edit assignment page load | Edit form pre-populates class, section, student, session, structure, total fee, date, status, mid-year fields, and JSON textareas | — | — | ⬜ |
| TC-P16 | Update assignment with all fields | Assignment is updated with new values, activity logged, and redirected to show page | — | — | ⬜ |
| TC-P17 | Update assignment structure via PATCH route | `fee_structure_id` and `total_fee_amount` are updated from the new structure, success message shown | — | — | ⬜ |
| TC-P18 | Toggle assignment status off | Status switch flips `is_active` to false and returns JSON success | — | — | ⬜ |
| TC-P19 | Toggle assignment status on | Status switch flips `is_active` to true and returns JSON success | — | — | ⬜ |
| TC-P20 | Delete assignment (soft delete) | `is_active` set to false, row soft-deleted, activity logged, row appears in trash | — | — | ⬜ |
| TC-P21 | Restore assignment from trash | Row restored, `is_active` set to true, activity logged, row appears in grid | — | — | ⬜ |
| TC-P22 | Force delete assignment from trash | Row permanently deleted, activity logged, no longer in trash | — | — | ⬜ |
| TC-P23 | AJAX class→section dropdown | Selecting a class loads sections via `GET /student-fee/fee-student-assignment/sections-by-class/{classId}` | — | — | ⬜ |
| TC-P24 | Full lifecycle — create, edit, toggle, delete | Assignment flows through create, edit, toggle off, soft delete, and is visible in trash | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-N01 | Missing `student_id` on create | Validation error: "The student id field is required." | — | — | ⬜ |
| TC-N02 | Missing `class_id` on create | Validation error: "The class id field is required." | — | — | ⬜ |
| TC-N03 | Missing `fee_structure_id` on create | Validation error: "The fee structure id field is required." | — | — | ⬜ |
| TC-N04 | Missing `assignment_date` on create | Validation error: "The assignment date field is required." | — | — | ⬜ |
| TC-N05 | Invalid `assignment_date` format | Validation error: "The assignment date field must be a valid date." | — | — | ⬜ |
| TC-N06 | Duplicate assignment for same student and session | Controller error: "Student assignment already exists for this academic session." | — | — | ⬜ |
| TC-N07 | Fee structure from a different academic session | Controller error: "Selected fee structure does not belong to the selected academic session." | — | — | ⬜ |
| TC-N08 | Invalid JSON in `opted_heads` on update | Controller error: "Invalid JSON format for opted heads." | — | — | ⬜ |
| TC-N09 | Invalid JSON in `opted_groups` on update | Controller error: "Invalid JSON format for opted groups." | — | — | ⬜ |
| TC-N10 | `proration_percentage` greater than 100 | Validation error: "The proration percentage field must not be greater than 100." | — | — | ⬜ |
| TC-N11 | `proration_percentage` less than 0 | Validation error: "The proration percentage field must be at least 0." | — | — | ⬜ |
| TC-N12 | Missing `fee_start_date` when mid-year join is checked | Validation error: "The fee start date field is required when join in mid year is 1." | — | — | ⬜ |
| TC-N13 | Missing `proration_percentage` when mid-year join is checked | Validation error: "The proration percentage field is required when join in mid year is 1." | — | — | ⬜ |
| TC-N14 | Guest access to assignment tab | Redirected to `/login` | — | — | ⬜ |
| TC-N15 | Missing `tenant.fee-student-assignment.create` permission | 403 Forbidden on create/store/generate routes | — | — | ⬜ |
| TC-N16 | Missing `tenant.fee-student-assignment.update` permission | 403 Forbidden on edit/update/update-structure routes | — | — | ⬜ |
| TC-N17 | Missing `tenant.fee-student-assignment.delete` permission | 403 Forbidden on destroy route | — | — | ⬜ |
| TC-N18 | Missing `tenant.fee-student-assignment.view` permission | 403 Forbidden on show route | — | — | ⬜ |
| TC-N19 | Missing `tenant.fee-student-assignment.status` permission | 403 Forbidden on toggle-status route | — | — | ⬜ |
| TC-N20 | Show non-existent assignment | 404 Not Found | — | — | ⬜ |
| TC-N21 | Edit non-existent assignment | 404 Not Found | — | — | ⬜ |
| TC-N22 | Force delete non-existent assignment | 404 Not Found | — | — | ⬜ |
| TC-N23 | No active session on create redirect | Controller redirects back with "No active academic session found. Please set a current session first." | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|
| TC-D01 | A | Model uses `SoftDeletes` trait | `deleted_at` column is populated on delete, `onlyTrashed()` returns rows | — | — | ⬜ |
| TC-D02 | A | `$fillable` matches DDL columns | Mass assignment includes all required columns and no extra fields | — | — | ⬜ |
| TC-D03 | A | `$casts` for decimal, boolean, date, and JSON | `total_fee_amount` decimal, `is_active` boolean, `opted_heads` array, `assignment_date` date | — | — | ⬜ |
| TC-D04 | B | `belongsTo` relationships defined | `student`, `class`, `section`, `academicSession`, `feeStructure` relationships exist | — | — | ⬜ |
| TC-D05 | B | `hasMany` relationships defined | `invoices` and `concessions` relationships exist | — | — | ⬜ |
| TC-D06 | C | Unique index `uq_fee_student_session` enforces duplicate prevention | Inserting a second `(student_id, academic_session_id)` row raises a unique constraint violation | — | — | ⬜ |
| TC-D07 | D | FK `fk_fsa_student` ON DELETE CASCADE | Deleting the parent `std_students` row deletes related assignments | — | — | ⬜ |
| TC-D08 | E | FK `fk_fsa_class` ON DELETE RESTRICT | Deleting a referenced `sch_classes` row is blocked while assignments exist | — | — | ⬜ |
| TC-D09 | E | FK `fk_fsa_section` ON DELETE RESTRICT | Deleting a referenced `sch_sections` row is blocked while assignments exist | — | — | ⬜ |
| TC-D10 | E | FK `fk_fsa_session` ON DELETE RESTRICT | Deleting a referenced `sch_org_academic_sessions_jnt` row is blocked while assignments exist | — | — | ⬜ |
| TC-D11 | E | FK `fk_fsa_structure` ON DELETE RESTRICT | Deleting a referenced `fee_structure_master` row is blocked while assignments exist | — | — | ⬜ |
| TC-D12 | F | Child `fee_student_concessions` cascade on assignment delete | `fk_fsc_assignment` ON DELETE CASCADE removes concessions when the parent assignment is deleted | — | — | ⬜ |
| TC-D13 | F | Child `fee_invoices` blocks assignment force delete | `fk_finv_assignment` ON DELETE RESTRICT raises an integrity error when force-deleting an assignment with invoices | — | — | ⬜ |
| TC-D14 | G | `restore()` sets `is_active = true` | Restored row has `is_active = 1` and `deleted_at = null` | — | — | ⬜ |
| TC-D15 | G | `destroy()` sets `is_active = false` before delete | Soft-deleted row has `is_active = 0` and `deleted_at` populated | — | — | ⬜ |
| TC-D16 | H | Activity log on create | `activityLog()` is called with action `Created` and assignment metadata | — | — | ⬜ |
| TC-D17 | H | Activity log on update | `activityLog()` is called with action `Updated` and `getChanges()` | — | — | ⬜ |
| TC-D18 | H | Activity log on delete | `activityLog()` is called with action `Trashed` | — | — | ⬜ |
| TC-D19 | H | Activity log on restore | `activityLog()` is called with action `Restored` | — | — | ⬜ |
| TC-D20 | H | Activity log on toggle | `activityLog()` is called with action `Toggled` | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|---|
| TC-CR01 | CR | P1 | Model `$fillable` matches DDL columns | `FeeStudentAssignment::$fillable` includes all non-PK, non-timestamp columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model `$casts` for booleans, decimals, dates, and JSON | Cast entries present for `total_fee_amount`, `is_active`, `opted_heads`, `opted_groups`, `assignment_date`, etc. | — | — | ◌ |
| TC-CR03 | CR | P1 | `SoftDeletes` trait correctly implemented | Model uses `SoftDeletes`; `deleted_at` nullable in DDL | — | — | ◌ |
| TC-CR04 | CR | P1 | Relationships defined for all FKs | `belongsTo` for student, class, section, academicSession, feeStructure; `hasMany` for invoices, concessions | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller try-catch on store | `store()` catches `Throwable`, rolls back, and returns error message | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller try-catch on update | `update()` catches `Throwable`, rolls back, and returns error message | — | — | ◌ |
| TC-CR07 | CR | P1 | DB transactions on multi-step writes | `store()` and `update()` wrap create/update and activity log in `DB::beginTransaction` / `commit` / `rollBack` | — | — | ◌ |
| TC-CR08 | CR | P1 | `Gate::authorize()` on every method | Every public method contains a `Gate::authorize()` call | — | — | ◌ |
| TC-CR09 | CR | P1 | Activity logged on all state changes | `activityLog()` called in create, update, delete, restore, toggle, generate, structure-update | — | — | ◌ |
| TC-CR10 | CR | P1 | `is_active=false` before soft delete | `destroy()` saves `is_active = false` before `delete()` | — | — | ◌ |
| TC-CR11 | CR | P1 | Restore sets `is_active=true` | `restore()` calls `restore()` then saves `is_active = true` | — | — | ◌ |
| TC-CR12 | CR | P1 | `toggleStatus()` flips `is_active` | Toggle saves the negated value and returns JSON with `success` and `is_active` | — | — | ◌ |
| TC-CR13 | CR | P1 | JSON success response after toggle | `toggleStatus()` returns `response()->json([success, is_active, message])` | — | — | ◌ |
| TC-CR14 | CR | P1 | Validation rules cover all fields | `StoreFeeStudentAssignmentRequest`, `UpdateFeeStudentAssignmentRequest`, and `UpdateFeeAssignmentStructureRequest` validate every submitted field | — | — | ◌ |
| TC-CR15 | CR | P1 | Policy methods match route/gate names | `FeeStudentAssignmentPolicy` defines `create`, `view`, `update`, `delete`, `restore`, `forceDelete`, `status`, `import`, `export`, `print`, `emailSchedule`, `remark`, `pdf`, `viewAny` | — | — | ◌ |
| TC-CR16 | CR | P1 | Routes registered including custom routes | Resource routes plus `generate`, `trashed`, `restore`, `forceDelete`, `toggleStatus`, `sections-by-class`, `update-structure` are declared | — | — | ◌ |
| TC-CR17 | CR | P2 | Views use null-safe checks | Views use `??` fallbacks for `student.user`, `class`, `section`, `feeStructure` | — | — | ◌ |
| TC-CR18 | CR | P2 | Blade `@can` directives on action buttons | Action buttons are gated by `@can` or controller-level authorization | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-CR01 | Open `Modules/StudentFee/app/Models/FeeStudentAssignment.php` | Compare `$fillable` array with DDL columns of `fee_student_assignments` | All non-PK, non-timestamp columns are present; no extra fields exist |
| TC-CR02 | Open `FeeStudentAssignment.php` | Inspect `$casts` array | Casts present for `student_id`→integer, `class_id`→integer, `total_fee_amount`→decimal:2, `opted_heads`→array, `is_active`→boolean, `assignment_date`→date, etc. |
| TC-CR03 | Open `FeeStudentAssignment.php` and DDL | Confirm trait and column | File contains `use SoftDeletes;`; DDL has `deleted_at TIMESTAMP NULL` |
| TC-CR04 | Open `FeeStudentAssignment.php` | Inspect relationship methods | Methods `student()`, `class()`, `section()`, `academicSession()`, `feeStructure()`, `invoices()`, `concessions()` are defined with correct types and FK column names |
| TC-CR05 | Open `FeeStudentAssignmentController.php` | Locate `store()` | `try { … } catch (\Throwable $e) { DB::rollBack(); report($e); return back()->with('error', 'Creation failed. Please try again.'); }` is present |
| TC-CR06 | Open `FeeStudentAssignmentController.php` | Locate `update()` | `try { … } catch (\Throwable $e) { DB::rollBack(); return back()->with('error', 'Update failed: ' . $e->getMessage()); }` is present |
| TC-CR07 | Open `FeeStudentAssignmentController.php` | Locate `store()` and `update()` | Both methods call `DB::beginTransaction()`, then `DB::commit()` on success, and `DB::rollBack()` on exception |
| TC-CR08 | Open `FeeStudentAssignmentController.php` | Locate each public method | Every public method contains a `Gate::authorize()` call |
| TC-CR09 | Open `FeeStudentAssignmentController.php` | Search for `activityLog(` calls | Calls exist in `store()`, `update()`, `destroy()`, `restore()`, `toggleStatus()`, `generateStudentAssignment()`, `updateAssignmentStructure()` |
| TC-CR10 | Open `FeeStudentAssignmentController.php` | Locate `destroy()` | Method sets `$assignment->is_active = false; $assignment->save();` before `$assignment->delete();` |
| TC-CR11 | Open `FeeStudentAssignmentController.php` | Locate `restore()` | Method calls `$assignment->restore();` then sets `$assignment->is_active = true; $assignment->save();` |
| TC-CR12 | Open `FeeStudentAssignmentController.php` | Locate `toggleStatus()` | Method executes `$feeStudentAssignment->is_active = !$feeStudentAssignment->is_active;` and saves |
| TC-CR13 | Open `FeeStudentAssignmentController.php` | Locate `toggleStatus()` return | On success returns `response()->json(['success' => true, 'is_active' => ..., 'message' => flash('status_updated.fee_student_assignment')])` |
| TC-CR14 | Open the three request classes | Compare `rules()` with form fields | Every submitted field in create and edit forms is covered by a validation rule |
| TC-CR15 | Open `FeeStudentAssignmentPolicy.php` | Count policy methods | Methods `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`, `import`, `export`, `print`, `status`, `emailSchedule`, `remark`, `pdf` are present |
| TC-CR16 | Open `Modules/StudentFee/routes/web.php` | Inspect fee-student-assignment block | Resource route plus all custom routes are registered with correct verbs and controller methods |
| TC-CR17 | Open view files | Search for null-safe operators | `$assignment->student->user->name ?? '-'`, etc. are used |
| TC-CR18 | Open view files | Search for `@can` directives | Buttons performing protected actions are wrapped in `@can` or protected by controller gates |

### 7.1 Positive TC Steps

#### TC-P01: Assignment tab loads with all UI elements

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as admin and navigate to `GET /student-fee/assignment` | Tab loads with HTTP 200 |
| 2 | Verify the search input placeholder reads "Search by student name or admission no" | Search input is visible |
| 3 | Verify the status dropdown contains All, Active, Inactive | Filter is visible |
| 4 | Verify card/list toggle buttons and generate banner are present | UI elements render |
| 5 | Verify the total assignments statistics card is present | Card shows count |

#### TC-P02: Default card view

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open `GET /student-fee/assignment` | Page renders with card view visible by default |
| 2 | Verify at least one card shows student name, admission no, class-section, fee structure name, total fee, and status | Card content matches DB values |
| 3 | Verify action buttons (eye, edit, delete) are present on each card | Buttons have correct route links |

#### TC-P03: Switch to list view

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open `GET /student-fee/assignment` | Card view is visible |
| 2 | Click the list view button | List view table becomes visible; card view is hidden |
| 3 | Verify table headers: Student, Adm No, Class & Section, Fee Structure, Total Fee, Status, Action | Headers match columns |
| 4 | Reload the page | Last selected view is restored from `localStorage` |

#### TC-P04: Pagination navigation

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 13 assignments in the current session | 13 rows exist in DB |
| 2 | Open `GET /student-fee/assignment` | First page shows 12 assignments |
| 3 | Click page 2 link | Page 2 shows the 13th assignment; URL contains `page=2` |

#### TC-P05: Search by student first name

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create an assignment for a student named "Aarav Sharma" | Row exists in DB |
| 2 | Open `GET /student-fee/assignment?search=Aarav` | Grid shows only Aarav's assignment |
| 3 | Open `GET /student-fee/assignment?search=Sharma` | Grid still shows Aarav's assignment |

#### TC-P06: Search by admission number

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create an assignment for a student with admission no `2025-099` | Row exists |
| 2 | Open `GET /student-fee/assignment?search=2025-099` | Grid shows only that student's assignment |

#### TC-P07: Filter active assignments only

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create one active and one inactive assignment in the same session | Both rows exist |
| 2 | Open `GET /student-fee/assignment?status=1` | Grid shows only the active assignment |

#### TC-P08: Filter inactive assignments only

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Use status=0 filter | Grid shows only the inactive assignment |

#### TC-P09: Create assignment with required fields only

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open `GET /student-fee/fee-student-assignment/create` | Create form loads |
| 2 | Select class, section, student, and fee structure for the current session | Fields populated |
| 3 | Leave assignment date default, set status Active | Form ready |
| 4 | Submit the form to `POST /student-fee/fee-student-assignment` | Assignment created; `total_fee_amount` equals the structure's total; redirect to `show` with success message |

#### TC-P10: Create assignment with optional heads and groups

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open the create form | Form loads |
| 2 | Fill required fields and enter `opted_heads` = `["Transport", "Lab"]` and `opted_groups` = `["Sports"]` | Textareas populated |
| 3 | Submit | Assignment created; DB stores JSON arrays under `opted_heads` and `opted_groups` |

#### TC-P11: Create assignment with mid-year join and proration

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open the create form | Form loads |
| 2 | Fill required fields and check **Join in Mid-Year** | Fee start date and proration fields become required |
| 3 | Enter `fee_start_date` = `2026-03-01` and `proration_percentage` = `50.00` | Fields populated |
| 4 | Submit | Assignment created with `join_in_mid-year = 1`, `fee_start_date = 2026-03-01`, `proration_percentage = 50.00` |

#### TC-P12: Bulk generate assignments for all active students

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure current session has active fee structures for multiple classes and active student sessions | Data exists |
| 2 | Click **Generate** (POST to `/student-fee/fee-student-assignment/generate/all`) | Controller processes all student sessions |
| 3 | Verify the flash message contains counts | Counts are non-negative and sum to active students |
| 4 | Verify assignments exist in DB for each processed student | Rows created |

#### TC-P13: Bulk generate skips students without matching fee structure

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create a student session whose class has no active fee structure | Data exists |
| 2 | Run bulk generate | Flash message includes skipped count |
| 3 | Verify that student has no assignment | No row in DB |

#### TC-P14: Show assignment details

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create an assignment with optional heads and groups | Row exists |
| 2 | Open `GET /student-fee/fee-student-assignment/{id}` | Detail page renders with student info, structure info, total fee, assignment date, status, and optional selections |

#### TC-P15: Edit assignment page load

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create an assignment with mid-year join and optional arrays | Row exists |
| 2 | Open edit form | Form pre-populates all fields; student dropdown is disabled |

#### TC-P16: Update assignment with all fields

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Change section, fee structure, total fee, date, status, and optional JSON arrays | Fields updated |
| 2 | Submit `PUT` | Row updated; activity log recorded; redirected to show page with success message |

#### TC-P17: Update assignment structure via PATCH route

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create assignment with structure A (total 30,000) | Row exists |
| 2 | Send `PATCH` with `fee_structure_id` = structure B (total 35,000) | Row's `fee_structure_id` and `total_fee_amount` updated to 35,000; success message shown |

#### TC-P18: Toggle assignment status off

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Click the status toggle switch for an active assignment | POST to `toggle-status` endpoint |
| 2 | Verify JSON response has `success: true`, `is_active: false` | Toggle succeeds |

#### TC-P19: Toggle assignment status on

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Click the status toggle switch for an inactive assignment | POST to `toggle-status` endpoint |
| 2 | Verify JSON response has `success: true`, `is_active: true` | Toggle succeeds |

#### TC-P20: Delete assignment (soft delete)

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Click delete button and confirm | DELETE request submitted |
| 2 | Verify the row has `is_active = 0` and `deleted_at` is set | Soft-deleted |
| 3 | Open the trash view | Row is listed in trashed assignments |

#### TC-P21: Restore assignment from trash

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Click **Restore** in the trash view | GET restore request submitted |
| 2 | Verify `is_active = 1` and `deleted_at = null` | Row restored and reactivated |

#### TC-P22: Force delete assignment from trash

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Soft-delete an assignment with no related invoices | Row in trash |
| 2 | Click **Force Delete** | DELETE force-delete request submitted |
| 3 | Verify the row is permanently removed | No row with that ID |

#### TC-P23: AJAX class→section dropdown

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open the create form and select a class with multiple sections | Class selected |
| 2 | Verify the section dropdown is populated only with sections linked to that class | Sections filtered |
| 3 | Verify the AJAX response returns JSON array of `{id, name}` | AJAX returns 200 with expected sections |

#### TC-P24: Full lifecycle — create, edit, toggle, delete

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create a new assignment | Row created, redirect to show |
| 2 | Edit the assignment and change the total fee | Row updated |
| 3 | Toggle the assignment off | `is_active = 0` |
| 4 | Delete the assignment | Soft-deleted, row in trash |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-N01 | Open create form | Submit with `student_id` empty | "The student id field is required." |
| TC-N02 | Open create form | Submit with `class_id` empty | "The class id field is required." |
| TC-N03 | Open create form | Submit with `fee_structure_id` empty | "The fee structure id field is required." |
| TC-N04 | Open create form | Submit with `assignment_date` empty | "The assignment date field is required." |
| TC-N05 | Open create form | Enter `assignment_date` = "not-a-date" | "The assignment date field must be a valid date." |
| TC-N06 | Create an assignment for student S in session X | Submit create form again for same student and session | "Student assignment already exists for this academic session." |
| TC-N07 | Create a fee structure for a different session | On create form, select that structure for the current session | "Selected fee structure does not belong to the selected academic session." |
| TC-N08 | Open edit form | Enter `opted_heads` = "invalid json" | "Invalid JSON format for opted heads." |
| TC-N09 | Open edit form | Enter `opted_groups` = "{broken" | "Invalid JSON format for opted groups." |
| TC-N10 | Open create form | Check mid-year, enter `proration_percentage` = 150 | "must not be greater than 100." |
| TC-N11 | Open create form | Check mid-year, enter `proration_percentage` = -10 | "must be at least 0." |
| TC-N12 | Open create form | Check mid-year, leave `fee_start_date` empty | "required when join in mid year is 1." |
| TC-N13 | Open create form | Check mid-year, leave `proration_percentage` empty | "required when join in mid year is 1." |
| TC-N14 | Log out and open `GET /student-fee/assignment` | — | Redirected to `/login` |
| TC-N15 | Login as user without create permission | Open create/store/generate routes | 403 Forbidden |
| TC-N16 | Login as user without update permission | Open edit/update/update-structure | 403 Forbidden |
| TC-N17 | Login as user without delete permission | Submit DELETE | 403 Forbidden |
| TC-N18 | Login as user without view permission | Open show route | 403 Forbidden |
| TC-N19 | Login as user without status permission | Submit toggle-status | 403 Forbidden |
| TC-N20 | Open `GET /student-fee/fee-student-assignment/999999` | — | 404 Not Found |
| TC-N21 | Open `GET /student-fee/fee-student-assignment/999999/edit` | — | 404 Not Found |
| TC-N22 | Submit `DELETE /student-fee/fee-student-assignment/999999/force-delete` | — | 404 Not Found |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-D01 | Create an assignment, click delete | Inspect DB row | `deleted_at` is populated; `onlyTrashed()` returns the row |
| TC-D02 | Compare model `$fillable` with DDL | Open model and DDL | All writable columns listed; no extra columns |
| TC-D03 | Create assignment with various types | Read the stored row | Casts confirmed (decimal rounds, boolean stores as 1/0, JSON array stored) |
| TC-D04 | Call relationship methods | Verify return types | Each returns a `BelongsTo` relation instance |
| TC-D05 | Call `invoices()`, `concessions()` | Verify return types | Each returns a `HasMany` relation instance |
| TC-D06 | Insert one assignment for student S in session X | Attempt duplicates | DB raises unique constraint violation |
| TC-D07 | Create an assignment for a student | Delete parent `std_students` row | Assignment row cascade-deleted |
| TC-D08 through TC-D11 | Create assignment referencing FK parents | Attempt to delete each parent row | DB rejects deletion due to RESTRICT |
| TC-D12 | Create assignment with concession | Force-delete assignment | Concession row cascade-deleted |
| TC-D13 | Create assignment with invoice | Force-delete assignment | DB raises integrity error (RESTRICT) |
| TC-D14 | Soft-delete then restore | Read row after restore | `deleted_at = null`, `is_active = 1` |
| TC-D15 | Delete active assignment | Read row immediately | `is_active = 0`, `deleted_at` set |
| TC-D16 through TC-D20 | Perform each action (create, update, delete, restore, toggle) | Inspect `activity_log` table | Log entry with correct action exists |

---

## 8. Known Issues

| KI ID | Issue | Severity | Details |
|---|---|---|---|
| KI-01 | Proration fields are not used to compute `total_fee_amount` | Medium | The create form captures `fee_start_date` and `proration_percentage`, but `store()` always copies the full structure `total_fee_amount`. The requirement stated the amount should be recomputed from proration. |
| KI-02 | Optional heads/groups are textareas, not checkboxes | Low | The requirement described optional heads and groups as checkboxes, but the create/edit views expose JSON textareas with example arrays. |
| KI-03 | Stale `_search-bar.blade.php` partial | Low | The partial references `has_group` and "Notification / Group", but the actual `index.blade.php` renders its own search bar. The partial appears unused. |
| KI-04 | Naming mismatch between form field and DB column | Low | The form and request use `join_in_mid_year` (underscore) while the DDL column is `join_in_mid-year` (hyphen). The controller maps them correctly, but this is inconsistent. |
| KI-05 | `trash.blade.php` uses wrong column name `structure_name` | Low | The trash view references `fee_structure->structure_name` but the column is `name`. Fallback `?? '-'` may always show `-`. |
| KI-06 | No explicit `@can` directives in action buttons | Low | Action buttons are rendered without Blade `@can` guards; authorization relies on controller gates only. |

---

## 9. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|---|---|---|---|---|
| GET | `/student-fee/assignment` | `student-fee.assignment` | `StudentFeeManagementController::assignment` | `tenant.student-fee-management.viewAny` |
| GET | `/student-fee/fee-student-assignment` | `student-fee.fee-student-assignment.index` | `FeeStudentAssignmentController::index` | `tenant.student-fee-management.viewAny` (via redirect) |
| GET | `/student-fee/fee-student-assignment/create` | `student-fee.fee-student-assignment.create` | `FeeStudentAssignmentController::create` | `tenant.fee-student-assignment.create` |
| POST | `/student-fee/fee-student-assignment` | `student-fee.fee-student-assignment.store` | `FeeStudentAssignmentController::store` | `tenant.fee-student-assignment.create` |
| GET | `/student-fee/fee-student-assignment/{fee_student_assignment}` | `student-fee.fee-student-assignment.show` | `FeeStudentAssignmentController::show` | `tenant.fee-student-assignment.view` |
| GET | `/student-fee/fee-student-assignment/{fee_student_assignment}/edit` | `student-fee.fee-student-assignment.edit` | `FeeStudentAssignmentController::edit` | `tenant.fee-student-assignment.update` |
| PUT | `/student-fee/fee-student-assignment/{fee_student_assignment}` | `student-fee.fee-student-assignment.update` | `FeeStudentAssignmentController::update` | `tenant.fee-student-assignment.update` |
| DELETE | `/student-fee/fee-student-assignment/{fee_student_assignment}` | `student-fee.fee-student-assignment.destroy` | `FeeStudentAssignmentController::destroy` | `tenant.fee-student-assignment.delete` |
| POST | `/student-fee/fee-student-assignment/generate/all` | `student-fee.fee-student-assignment.generate` | `FeeStudentAssignmentController::generateStudentAssignment` | `tenant.fee-student-assignment.create` |
| GET | `/student-fee/fee-student-assignment/trash/view` | `student-fee.fee-student-assignment.trashed` | `FeeStudentAssignmentController::trashedFeeStudentAssignments` | `tenant.fee-student-assignment.restore` |
| GET | `/student-fee/fee-student-assignment/{id}/restore` | `student-fee.fee-student-assignment.restore` | `FeeStudentAssignmentController::restore` | `tenant.fee-student-assignment.restore` |
| DELETE | `/student-fee/fee-student-assignment/{id}/force-delete` | `student-fee.fee-student-assignment.forceDelete` | `FeeStudentAssignmentController::forceDelete` | `tenant.fee-student-assignment.forceDelete` |
| POST | `/student-fee/fee-student-assignment/{fee_student_assignment}/toggle-status` | `student-fee.fee-student-assignment.toggleStatus` | `FeeStudentAssignmentController::toggleStatus` | `tenant.fee-student-assignment.status` |
| GET | `/student-fee/fee-student-assignment/sections-by-class/{classId}` | `student-fee.fee-student-assignment.sections-by-class` | `FeeStudentAssignmentController::getSectionsByClass` | None (AJAX) |
| PATCH | `/student-fee/fee-student-assignment/{id}/update-structure` | `student-fee.fee-student-assignment.update-structure` | `FeeStudentAssignmentController::updateAssignmentStructure` | `tenant.fee-student-assignment.update` |

---

## 10. Execution Status

### 10.1 Summary

| Section | Total TCs | Executed | Passed | Failed | Blocked | Not Executed |
|---|---|---|---|---|---|---|
| Positive | 24 | 0 | 0 | 0 | 0 | 24 |
| Negative | 23 | 0 | 0 | 0 | 0 | 23 |
| Dependency | 20 | 0 | 0 | 0 | 0 | 20 |
| Code Review | 18 | 0 | 0 | 0 | 0 | 18 |
| **Total** | **85** | **0** | **0** | **0** | **0** | **85** |

### 10.2 Per-TC Execution

| TC ID | Test Name | Type | Status | Date | Tester | Remarks |
|---|---|---|---|---|---|---|
| TC-P01 | Assignment tab loads with all UI elements | Positive | ⬜ | — | — | — |
| TC-P02 | Default card view | Positive | ⬜ | — | — | — |
| TC-P03 | Switch to list view | Positive | ⬜ | — | — | — |
| TC-P04 | Pagination navigation | Positive | ⬜ | — | — | — |
| TC-P05 | Search by student first name | Positive | ⬜ | — | — | — |
| TC-P06 | Search by admission number | Positive | ⬜ | — | — | — |
| TC-P07 | Filter active assignments only | Positive | ⬜ | — | — | — |
| TC-P08 | Filter inactive assignments only | Positive | ⬜ | — | — | — |
| TC-P09 | Create assignment with required fields only | Positive | ⬜ | — | — | — |
| TC-P10 | Create assignment with optional heads and groups | Positive | ⬜ | — | — | — |
| TC-P11 | Create assignment with mid-year join and proration | Positive | ⬜ | — | — | — |
| TC-P12 | Bulk generate assignments for all active students | Positive | ⬜ | — | — | — |
| TC-P13 | Bulk generate skips students without matching fee structure | Positive | ⬜ | — | — | — |
| TC-P14 | Show assignment details | Positive | ⬜ | — | — | — |
| TC-P15 | Edit assignment page load | Positive | ⬜ | — | — | — |
| TC-P16 | Update assignment with all fields | Positive | ⬜ | — | — | — |
| TC-P17 | Update assignment structure via PATCH route | Positive | ⬜ | — | — | — |
| TC-P18 | Toggle assignment status off | Positive | ⬜ | — | — | — |
| TC-P19 | Toggle assignment status on | Positive | ⬜ | — | — | — |
| TC-P20 | Delete assignment (soft delete) | Positive | ⬜ | — | — | — |
| TC-P21 | Restore assignment from trash | Positive | ⬜ | — | — | — |
| TC-P22 | Force delete assignment from trash | Positive | ⬜ | — | — | — |
| TC-P23 | AJAX class→section dropdown | Positive | ⬜ | — | — | — |
| TC-P24 | Full lifecycle — create, edit, toggle, delete | Positive | ⬜ | — | — | — |
| TC-N01 | Missing student_id on create | Negative | ⬜ | — | — | — |
| TC-N02 | Missing class_id on create | Negative | ⬜ | — | — | — |
| TC-N03 | Missing fee_structure_id on create | Negative | ⬜ | — | — | — |
| TC-N04 | Missing assignment_date on create | Negative | ⬜ | — | — | — |
| TC-N05 | Invalid assignment_date format | Negative | ⬜ | — | — | — |
| TC-N06 | Duplicate assignment for same student and session | Negative | ⬜ | — | — | — |
| TC-N07 | Fee structure from a different academic session | Negative | ⬜ | — | — | — |
| TC-N08 | Invalid JSON in opted_heads on update | Negative | ⬜ | — | — | — |
| TC-N09 | Invalid JSON in opted_groups on update | Negative | ⬜ | — | — | — |
| TC-N10 | Proration percentage greater than 100 | Negative | ⬜ | — | — | — |
| TC-N11 | Proration percentage less than 0 | Negative | ⬜ | — | — | — |
| TC-N12 | Missing fee_start_date when mid-year checked | Negative | ⬜ | — | — | — |
| TC-N13 | Missing proration_percentage when mid-year checked | Negative | ⬜ | — | — | — |
| TC-N14 | Guest access to assignment tab | Negative | ⬜ | — | — | — |
| TC-N15 | Missing create permission | Negative | ⬜ | — | — | — |
| TC-N16 | Missing update permission | Negative | ⬜ | — | — | — |
| TC-N17 | Missing delete permission | Negative | ⬜ | — | — | — |
| TC-N18 | Missing view permission | Negative | ⬜ | — | — | — |
| TC-N19 | Missing status permission | Negative | ⬜ | — | — | — |
| TC-N20 | Show non-existent assignment | Negative | ⬜ | — | — | — |
| TC-N21 | Edit non-existent assignment | Negative | ⬜ | — | — | — |
| TC-N22 | Force delete non-existent assignment | Negative | ⬜ | — | — | — |
| TC-N23 | No active session on create redirect | Negative | ⬜ | — | — | — |
| TC-D01 | SoftDeletes trait and deleted_at column | Dependency | ⬜ | — | — | — |
| TC-D02 | Fillable matches DDL columns | Dependency | ⬜ | — | — | — |
| TC-D03 | Casts for decimal/boolean/date/JSON | Dependency | ⬜ | — | — | — |
| TC-D04 | belongsTo relationships defined | Dependency | ⬜ | — | — | — |
| TC-D05 | hasMany relationships defined | Dependency | ⬜ | — | — | — |
| TC-D06 | Unique index enforces duplicate prevention | Dependency | ⬜ | — | — | — |
| TC-D07 | Cascade on student delete | Dependency | ⬜ | — | — | — |
| TC-D08 | Restrict on class delete | Dependency | ⬜ | — | — | — |
| TC-D09 | Restrict on section delete | Dependency | ⬜ | — | — | — |
| TC-D10 | Restrict on session delete | Dependency | ⬜ | — | — | — |
| TC-D11 | Restrict on structure delete | Dependency | ⬜ | — | — | — |
| TC-D12 | Concessions cascade on assignment delete | Dependency | ⬜ | — | — | — |
| TC-D13 | Invoices block assignment force delete | Dependency | ⬜ | — | — | — |
| TC-D14 | Restore sets is_active true | Dependency | ⬜ | — | — | — |
| TC-D15 | Destroy sets is_active false before delete | Dependency | ⬜ | — | — | — |
| TC-D16 | Activity log on create | Dependency | ⬜ | — | — | — |
| TC-D17 | Activity log on update | Dependency | ⬜ | — | — | — |
| TC-D18 | Activity log on delete | Dependency | ⬜ | — | — | — |
| TC-D19 | Activity log on restore | Dependency | ⬜ | — | — | — |
| TC-D20 | Activity log on toggle | Dependency | ⬜ | — | — | — |
| TC-CR01 | Model fillable matches DDL | Code Review | ◌ | — | — | — |
| TC-CR02 | Model casts correct | Code Review | ◌ | — | — | — |
| TC-CR03 | SoftDeletes trait implemented | Code Review | ◌ | — | — | — |
| TC-CR04 | Relationships defined | Code Review | ◌ | — | — | — |
| TC-CR05 | Controller try-catch on store | Code Review | ◌ | — | — | — |
| TC-CR06 | Controller try-catch on update | Code Review | ◌ | — | — | — |
| TC-CR07 | DB transactions on writes | Code Review | ◌ | — | — | — |
| TC-CR08 | Gate::authorize on every method | Code Review | ◌ | — | — | — |
| TC-CR09 | Activity logged on state changes | Code Review | ◌ | — | — | — |
| TC-CR10 | is_active false before soft delete | Code Review | ◌ | — | — | — |
| TC-CR11 | Restore sets is_active true | Code Review | ◌ | — | — | — |
| TC-CR12 | toggleStatus flips is_active | Code Review | ◌ | — | — | — |
| TC-CR13 | JSON success response after toggle | Code Review | ◌ | — | — | — |
| TC-CR14 | Validation rules cover all fields | Code Review | ◌ | — | — | — |
| TC-CR15 | Policy methods defined | Code Review | ◌ | — | — | — |
| TC-CR16 | Routes registered | Code Review | ◌ | — | — | — |
| TC-CR17 | View null-safe checks | Code Review | ◌ | — | — | — |
| TC-CR18 | Blade @can directives | Code Review | ◌ | — | — | — |

**Legend:** `⬜ = Pending Execution | ✅ = Passed | ❌ = Failed | ⛔ = Blocked | ◌ = Code Review (structure verified, not executed)`
