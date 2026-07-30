# hmw_AssignmentTracking_TcList

## Module: LmsHomework → Homework Master → Assignment Tracking

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsHomework |
| Tab Group | Homework Master |
| Feature | Assignment Tracking |
| URL(s) | `/lms-home-work` (index via tab `homework_assignment`), `/lms-home-work/assignments` (list), `/lms-home-work/assignments/{id}` (show), `/lms-home-work/assignments/{id}/grade` (grade), `/lms-home-work/assignments/{id}/status` (update-status), `/lms-home-work/assignments/{id}/due-date` (update-due-date), `/lms-home-work/assignments/{id}/assign-date` (update-assign-date), `/lms-home-work/assignments/{id}/toggle-release` (toggle-release) |
| Controller | `Modules\LmsHomework\Http\Controllers\LmsHomeworkController` |
| Model(s) | `Modules\LmsHomework\Models\HomeworkAssignment` (table: `lms_homework_assignment`) |
| Related Models | `Homework`, `HomeworkSubmission`, `Student` |
| Permissions | `tenant.home-work-assignment-tracking.viewAny`, `tenant.home-work-assignment-tracking.view`, `tenant.home-work-assignment-tracking.create`, `tenant.home-work-assignment-tracking.update`, `tenant.home-work-assignment-tracking.delete` |
| Soft Deletes | Yes (`HomeworkAssignment` uses `SoftDeletes` trait) |
| Unique Constraint | `(homework_id, student_id)` — one assignment per student per homework |

---

## 2. Pre-conditions

- Required permissions: `tenant.home-work-assignment-tracking.viewAny`
- Required seed data: At least one published `Homework` with enrolled students (assignments created)
- Required seed data: At least one `HomeworkSubmission` linked to an assignment (for grade/show tests)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For due date tests: Homework with `due_date` set in the past (for overdue scenarios)

---

## 3. Default Data Load

When the page loads via `LmsHomeworkController@index()` with `tab=homework_assignment`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Assignments Grid | HomeworkAssignment | `with(student, homework.class, homework.section, homework.subject, homework.topic, submission, status)` | search(student name/admission/email, homework title), class_id | 10/page (`asgn_page`) |
| Shared: Classes | index() | `SchoolClass::where('is_active',1)->get()` | is_active=1 | None |
| Shared: Sections | index() | `Section::where('is_active',1)->get()` | is_active=1 | None |
| Shared: Subjects | index() | `Subject::where('is_active',1)->get()` | is_active=1 | None |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Assignment**: Created via homework publish flow or direct DB insert with valid student, homework, class, section, subject
- **Submission**: Linked to assignment via `assignment_id` (unique constraint)
- **Pre-test cleanup**: Delete created assignments by ID after tests
- **Filter test data**: Create assignments for at least 2 classes with varied statuses

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_homework_assignment`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | homework_id | INT UNSIGNED FK | NOT NULL, FK → `lms_homework.id` |
| BC-DB-03 | student_id | INT UNSIGNED FK | NOT NULL, FK → `std_students.id` |
| BC-DB-04 | academic_session_id | SMALLINT UNSIGNED FK | NOT NULL |
| BC-DB-05 | class_id | INT UNSIGNED FK | NOT NULL (denormalized) |
| BC-DB-06 | section_id | INT UNSIGNED FK | NULLABLE |
| BC-DB-07 | subject_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-08 | release_condition | ENUM('IMMEDIATE', 'ON_TOPIC_COMPLETE', 'ON_SCHEDULED_DATE') | DEFAULT 'ON_TOPIC_COMPLETE' |
| BC-DB-09 | release_scheduled_date | DATETIME | NULLABLE |
| BC-DB-10 | is_released | BOOLEAN | DEFAULT false |
| BC-DB-11 | released_at | DATETIME | NULLABLE |
| BC-DB-12 | due_date | DATETIME | NULLABLE (per-student override) |
| BC-DB-13 | allow_late_submission | TINYINT(1) | DEFAULT NULL |
| BC-DB-14 | late_submission_override_reason | VARCHAR(500) | DEFAULT NULL |
| BC-DB-15 | late_submission_override_by | INT UNSIGNED FK | NULLABLE |
| BC-DB-16 | late_submission_override_at | DATETIME | NULLABLE |
| BC-DB-17 | viewed_at | DATETIME | NULLABLE |
| BC-DB-18 | view_count | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-19 | student_notified_at | DATETIME | NULLABLE |
| BC-DB-20 | parent_notified_at | DATETIME | NULLABLE |
| BC-DB-21 | reminder_sent_at | DATETIME | NULLABLE |
| BC-DB-22 | status_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-23 | assigned_by | INT UNSIGNED FK | NOT NULL |
| BC-DB-24 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-25 | created_at | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-26 | updated_at | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-27 | deleted_at | TIMESTAMP | NULLABLE |
| BC-DB-28 | created_by | INT UNSIGNED FK | NOT NULL, FK → `sys_users.id` |
| BC-DB-29 | updated_by | INT UNSIGNED FK | NULLABLE, FK → `sys_users.id` |

### 5.2 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | One assignment per student per homework | Unique constraint `(homework_id, student_id)` enforced at DB level |
| BC-BIZ-02 | Extension can only add time | New due_date must be later than current due_date |
| BC-BIZ-03 | Released assignments: assign date locked | Cannot change assign_date once `is_released=true` |
| BC-BIZ-04 | Late override requires reason | `late_submission_override_reason` must be provided when overriding |
| BC-BIZ-05 | Toggle release flips `is_released` flag | `is_released` toggles; `released_at` updated on release |
| BC-BIZ-06 | Reminder sends notification | `reminder_sent_at` timestamped on assignment; notification record created |
| BC-BIZ-07 | Status changes via `assignmentUpdateStatus()` | Status_id updated; activity logged |
| BC-BIZ-08 | Grade from assignment view | `assignmentsGrade()` marks submission; updates assignment status |
| BC-BIZ-09 | Auto late flag on overdue | If due_date passed and no submission, status transitions to Overdue |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.home-work-assignment-tracking.viewAny | assignmentsIndex() (via index tab) | Without → 403 |
| BC-AUTH-02 | tenant.home-work-assignment-tracking.view | assignmentsShow() | Without → 403 |
| BC-AUTH-03 | tenant.home-work-assignment-tracking.update | assignmentUpdateDueDate(), assignmentUpdateAssignDate(), toggleAssignmentRelease(), assignmentUpdateStatus() | Without → 403 |
| BC-AUTH-04 | tenant.home-work.update | assignmentsGrade() | Without → 403 (grading uses home-work.update) |

### 5.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | homework_id | lms_homework | CASCADE |
| BC-REF-02 | student_id | std_students | CASCADE |
| BC-REF-03 | academic_session_id | sch_org_academic_sessions_jnt | RESTRICT |
| BC-REF-04 | class_id | sch_classes | RESTRICT |
| BC-REF-05 | section_id | sch_sections | SET NULL |
| BC-REF-06 | subject_id | sch_subjects | RESTRICT |
| BC-REF-07 | status_id | sys_dropdown_table | RESTRICT |
| BC-REF-08 | late_submission_override_by | sys_users | SET NULL |
| BC-REF-09 | assigned_by | sys_users | RESTRICT |
| BC-REF-10 | created_by | sys_users | RESTRICT |
| BC-REF-11 | updated_by | sys_users | SET NULL |

### 5.5 DDL Conditions

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-CON-01 | App creates one row per active enrolled student on homework PUBLISHED | Assignment count = count of active enrolled students in class+section+subject for the academic session |
| BC-CON-02 | due_date NULL by default — app resolves effective due_date | Effective due_date = COALESCE(assignment.due_date, homework.due_date) |
| BC-CON-03 | allow_late_submission NULL by default — app resolves effective policy | Effective policy = COALESCE(assignment.allow_late_submission, homework.allow_late_submission) |
| BC-CON-04 | Nightly scheduled job sets OVERDUE status | Assignments past effective due_date with no submission get status = OVERDUE |
| BC-CON-05 | Topic completion triggers auto-release for matching assignments | When teacher marks topic completed, matching ON_TOPIC_COMPLETE assignment rows get is_released=1, status=ASSIGNED |
| BC-CON-06 | section_id = student's actual section, NOT homework.section_id | assignment.section_id reflects the student's enrolled section, not the homework's target section |
| BC-CON-07 | Late submission override: NULL=inherit, 0=DENY, 1=ALLOW | Three-state logic for per-student late submission control |
| BC-CON-08 | Lifecycle status progression | PENDING_RELEASE → ASSIGNED → VIEWED → SUBMITTED → GRADED / LATE_SUBMITTED / OVERDUE / EXEMPTED |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Assignment Tracking List Loads | Page loads with student name, homework title, class, release status, due date, assignment status | — | — | ⬜ |
| TC-P02 | Search Assignment By Student Name | Typing student first/last name filters assignments list | — | — | ⬜ |
| TC-P03 | Search Assignment By Admission Number | Typing admission_no finds matching assignment | — | — | ⬜ |
| TC-P04 | Search Assignment By Homework Title | Typing homework title filters assignments | — | — | ⬜ |
| TC-P14 | Search Assignments By Student Email | Typing student email filters the assignments list via `student.user` relationship | — | — | ⬜ |
| TC-P05 | Filter Assignments By Class | Selecting class from filter dropdown shows only that class's assignments | — | — | ⬜ |
| TC-P06 | View Single Assignment Details | Show page loads with student info, homework context, due date, release status, view tracking, submission/grading data | — | — | ⬜ |
| TC-P07 | Extend Due Date For Individual Student | New later due date saved; student's `due_date` updated | — | — | ⬜ |
| TC-P08 | Toggle Release Assignment | `is_released` flips; `released_at` timestamped on release; status changes to Assigned | — | — | ⬜ |
| TC-P09 | Send Reminder To Student | `reminder_sent_at` stamped; notification record created | — | — | ⬜ |
| TC-P10 | Grade Submission From Assignment View | Marks and feedback saved; `graded_by` and `graded_at` recorded | — | — | ⬜ |
| TC-P11 | Override Late Policy With Reason | `late_submission_override_reason` saved; `allow_late_submission` toggled for student | — | — | ⬜ |
| TC-P12 | Assignment Status Displayed Correctly | Color-coded badges: Pending Release(grey), Assigned(blue), Viewed(light blue), Submitted(green), Late Submitted(amber), Graded(dark green), Overdue(red), Exempted(grey) | — | — | ⬜ |
| TC-P13 | Empty State — No Assignments For Filter | "No records found" message displayed | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Extend Due Date — New Date Earlier Than Current | "Due date override must be later than the existing due date." | — | — | ⬜ |
| TC-N02 | Change Assign Date After Release | "Assign date cannot be changed after release." — field locked/rejected | — | — | ⬜ |
| TC-N03 | Override Late Policy Without Reason | "Reason is required for late submission override." | — | — | ⬜ |
| TC-N04 | View Invalid Assignment ID (404) | `/lms-home-work/assignments/99999` returns HTTP 404 | — | — | ⬜ |
| TC-N05 | Grade Non-Existent Submission | 404 if submission not found or already graded | — | — | ⬜ |
| TC-N06 | Permission 403 — No Assignment Tracking Permission | User without `tenant.home-work-assignment-tracking.*` sees 403 or tab hidden | — | — | ⬜ |
| TC-N07 | Guest Access Redirect | Logged-out user redirected to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | One assignment per student per homework enforced | Attempting duplicate `(homework_id, student_id)` → DB unique violation | — | — | ⬜ |
| TC-D02 | B | Publishing homework creates assignments automatically | Assignment count matches enrolled student count | — | — | ⬜ |
| TC-D03 | C | Re-publishing updates existing (no duplicates) | Existing assignments updated; new students get new records | — | — | ⬜ |
| TC-D04 | D | Toggle release → `released_at` timestamped | `released_at` = now when `is_released` changes from false to true | — | — | ⬜ |
| TC-D05 | E | Toggle release → Assignment status changes | Status transitions from "Pending Release" to "Assigned" | — | — | ⬜ |
| TC-D06 | F | Late override reason audited | `late_submission_override_by` = current user ID; `late_submission_override_at` timestamped | — | — | ⬜ |
| TC-D07 | G | Reminder stamps `reminder_sent_at` | Timestamp updated; notification record created in `notifications` table | — | — | ⬜ |
| TC-D21 | U | Due Date Extension Creates Student Notification | `assignmentUpdateDueDate()` creates Notification + NotificationTarget records for the student | — | — | ⬜ |
| TC-D22 | V | Release Toggle Creates Student Notification | `toggleAssignmentRelease()` creates Notification + NotificationTarget records for the student | — | — | ⬜ |
| TC-D08 | H | View count increments on student access | `view_count` increases; `viewed_at` updated on first view | — | — | ⬜ |
| TC-D09 | I | Create → created_by set to auth user | `created_by` = current authenticated user's ID on publish (assignment creation) | — | — | ⬜ |
| TC-D10 | J | Update → updated_by set to auth user | `updated_by` updated to current user's ID on any assignment mutation | — | — | ⬜ |
| TC-D11 | K | ON DELETE CASCADE — homework deletion cascades to assignments | Force-delete homework → all related lms_homework_assignment records auto-deleted | — | — | ⬜ |
| TC-D12 | L | ON DELETE RESTRICT — parent delete rejected if assignment exists | Delete class/session/subject used by assignment → DB FK error | — | — | ⬜ |
| TC-D13 | M | ON DELETE SET NULL — section/override_by set to NULL on parent delete | Delete section → assignment.section_id=NULL; delete sys_user → late_submission_override_by=NULL | — | — | ⬜ |
| TC-D14 | N | DEFAULT values on insert | New assignment has is_released=0, view_count=0, is_active=1 by default | — | — | ⬜ |
| TC-D15 | O | INDEX exists for query performance | EXPLAIN on homework_id+student_id, status_id, due_date shows index usage | — | — | ⬜ |
| TC-D16 | P | BC-CON-02 — effective due_date resolution | Assignment with NULL due_date inherits homework.due_date; assignment with explicit due_date uses its own | — | — | ⬜ |
| TC-D17 | Q | BC-CON-03 — effective allow_late_submission resolution | Assignment with NULL allow_late_submission inherits homework default; explicit 0/1 overrides | — | — | ⬜ |
| TC-D18 | R | BC-CON-04 — scheduled OVERDUE job | Assignment past effective due_date with no submission gets status_id = OVERDUE after scheduled job runs | — | — | ⬜ |
| TC-D19 | S | BC-CON-05 — topic completion auto-releases ON_TOPIC_COMPLETE assignments | Mark schedule topic completed → PENDING_RELEASE assignments become is_released=1, status=ASSIGNED | — | — | ⬜ |
| TC-D20 | T | BC-CON-06 — section_id reflects student's actual section | assignment.section_id = student's enrolled section, distinct from homework.section_id (which can be NULL for all sections) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Tab permission | Tab hidden if user lacks `tenant.home-work-assignment-tracking.viewAny` | — | — | ◌ |
| TC-CR02 | CR | P1 | DB Transaction for grade operations | assignmentsGrade uses transaction for submission + assignment update | — | — | ◌ |
| TC-CR03 | CR | P1 | isset()/null-safe checks for student/homework relations | `$assignment?->student?->first_name` used in blade; no undefined errors | — | — | ◌ |
| TC-CR04 | CR | P1 | Due date validation on server side | `assignmentUpdateDueDate()` validates new date > current date | — | — | ◌ |
| TC-CR05 | CR | P1 | Hub page tab integration — permission-filtered tab | Tab only visible with `tenant.home-work-assignment-tracking.viewAny`; direct URL returns 403 without permission | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-P07: Extend Due Date For Individual Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assignment Tracking tab | List loads with assignments |
| 2 | Find an assignment with current due_date = 20 July | Record found |
| 3 | Click "Edit Due Date" for that student | Date picker opens |
| 4 | Select new date: 25 July (later than current) | Date selected |
| 5 | Click Save | PATCH to `/assignments/{id}/due-date` |
| 6 | Check success response | JSON 200; due_date updated to 25 July |
| 7 | DB check: `SELECT due_date FROM lms_homework_assignment WHERE id={id}` | due_date = 25 July |
| 8 | Verify notification created | `student_notified_at` timestamped |

#### TC-N01: Extend Due Date — New Date Earlier Than Current

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find assignment with due_date = 20 July | Record found |
| 2 | Click "Edit Due Date", select 18 July (earlier) | Date selected |
| 3 | Click Save | Validation fails: "Due date override must be later than the existing due date." |
| 4 | DB check: due_date unchanged | Still 20 July |

#### TC-D01: One Assignment Per Student Per Homework Enforced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework for Class 8-A | Homework exists |
| 2 | Publish homework — 35 assignments created | Assignments created |
| 3 | Try to manually insert duplicate assignment for same student + homework | DB throws unique constraint violation |
| 4 | Publish again (re-publish) | No duplicate — existing records updated; only new students get new records |

#### TC-P01: Assignment Tracking List Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Master → Assignment Tracking tab | Page loads without errors |
| 3 | Verify the grid displays columns: student name, homework title, class, release status, due date, assignment status | All six columns present |
| 4 | Verify class filter dropdown is visible above the grid | Dropdown populated with active classes |
| 5 | Verify pagination controls are displayed at the bottom | Pagination shows 10 per page |
| 6 | Verify assignment rows contain clickable links | Each student name links to show page |

#### TC-P02: Search Assignment By Student Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays all assignments |
| 3 | Type a known student's first name in the search box | Grid filters to show only matching assignments |
| 4 | Clear search, type the same student's last name | Matching assignments displayed |
| 5 | Type a partial match (first 3 characters of name) | Partial matches shown |
| 6 | Clear search and verify full list restores | All assignments visible again |

#### TC-P03: Search Assignment By Admission Number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays all assignments |
| 3 | Type a known student's admission number in search box | Only the matching assignment displayed |
| 4 | Type a non-existent admission number | "No records found" displayed |
| 5 | Clear search | Full list restored |

#### TC-P04: Search Assignment By Homework Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays all assignments |
| 3 | Type a known homework title in the search box | Only assignments with matching homework title shown |
| 4 | Type a partial homework title | Partial matches returned |
| 5 | Clear search | Full list restored |

#### TC-P05: Filter Assignments By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays all assignments |
| 3 | Select a specific class from the Class filter dropdown | Only assignments for that class displayed |
| 4 | Verify assignment count is less than or equal to total | Filter applied correctly |
| 5 | Select a different class | Grid refreshes with that class's assignments |
| 6 | Select "All" / clear filter | Full list restored |

#### TC-P06: View Single Assignment Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Click on a student name in the grid | Navigates to `/lms-home-work/assignments/{id}` |
| 4 | Verify student info section displayed | Full name, admission number, class, section shown |
| 5 | Verify homework context section displayed | Homework title, subject, topic, due date shown |
| 6 | Verify release status and view tracking displayed | `is_released` badge, `view_count`, `viewed_at` shown |
| 7 | Verify submission/grading data displayed | Submission status, marks, graded_by, graded_at shown |

#### TC-P08: Toggle Release Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Identify an assignment with `is_released = false` | Record found |
| 4 | Click "Toggle Release" button | Confirmation prompt shown |
| 5 | Confirm release | Success message displayed |
| 6 | DB check: `SELECT is_released, released_at FROM lms_homework_assignment WHERE id={id}` | `is_released = true`, `released_at` timestamped with current time |
| 7 | Verify grid shows updated status badge | Badge changes from "Pending Release" to "Assigned" |

#### TC-P09: Send Reminder To Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Click "Send Reminder" for an assignment | Success message displayed |
| 4 | DB check: `SELECT reminder_sent_at FROM lms_homework_assignment WHERE id={id}` | `reminder_sent_at` is not null, timestamped with current time |
| 5 | DB check: `SELECT * FROM notifications WHERE notifiable_id = {student_id} AND type LIKE '%reminder%'` | Notification record created |
| 6 | Verify button becomes disabled or shows "Reminder Sent" | UI reflects reminder already sent |

#### TC-P10: Grade Submission From Assignment View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Click on an assignment with status "Submitted" or "Late Submitted" | Show page loads |
| 4 | Click "Grade" button | Grade form opens with marks and feedback fields |
| 5 | Enter marks (e.g., 85) and feedback text | Fields populated |
| 6 | Click Save/Submit | Success message displayed |
| 7 | DB check: `SELECT graded_by, graded_at FROM lms_homework_submission WHERE assignment_id={id}` | `graded_by` = current user ID, `graded_at` timestamped |
| 8 | Verify assignment status updated to "Graded" | Badge shows "Graded" (dark green) |

#### TC-P11: Override Late Policy With Reason

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Click "Override Late Policy" for an assignment | Override form opens |
| 4 | Enter a valid reason in the text field | Reason entered |
| 5 | Click Save | Success message displayed |
| 6 | DB check: `SELECT allow_late_submission, late_submission_override_reason FROM lms_homework_assignment WHERE id={id}` | `allow_late_submission = true`, `late_submission_override_reason` = entered reason |
| 7 | Verify UI shows late submission now allowed | Badge or indicator updated |

#### TC-P12: Assignment Status Displayed Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Locate assignments for each status type in the grid | Status badges visible next to each row |
| 4 | Verify "Pending Release" shows grey badge | Grey badge displayed |
| 5 | Verify "Assigned" shows blue badge | Blue badge displayed |
| 6 | Verify "Viewed" shows light blue badge | Light blue badge displayed |
| 7 | Verify "Submitted" shows green badge | Green badge displayed |
| 8 | Verify "Late Submitted" shows amber badge | Amber badge displayed |
| 9 | Verify "Graded" shows dark green badge | Dark green badge displayed |
| 10 | Verify "Overdue" shows red badge | Red badge displayed |
| 11 | Verify "Exempted" shows grey badge | Grey badge displayed |

#### TC-P13: Empty State — No Assignments For Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Select a class that has no assignments assigned | Grid shows empty state |
| 4 | Verify "No records found" message displayed | Empty state message visible |
| 5 | Type a gibberish string in the search box | "No records found" displayed |
| 6 | Clear filter and search | Full list restored |

#### TC-N02: Change Assign Date After Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Click on a released assignment (`is_released = true`) | Show page loads |
| 4 | Attempt to change the assign date field | Field is disabled/locked |
| 5 | If field editable, submit a new assign date | Validation error: "Assign date cannot be changed after release." |
| 6 | DB check: assign_date unchanged | Original assign_date preserved |

#### TC-N03: Override Late Policy Without Reason

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Click "Override Late Policy" | Override form opens |
| 4 | Leave reason field blank and click Save | Validation error: "Reason is required for late submission override." |
| 5 | DB check: `allow_late_submission` remains unchanged | `allow_late_submission` = previous value (false) |

#### TC-N04: View Invalid Assignment ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate directly to `/lms-home-work/assignments/99999` (non-existent ID) | HTTP 404 page displayed |
| 3 | Verify 404 error message shown | "Not Found" or custom 404 page rendered |

#### TC-N05: Grade Non-Existent Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to an assignment that has no submission | Show page loads |
| 3 | Click "Grade" | Error: 404 or "No submission found to grade" |
| 4 | Alternatively, grade an already-graded submission | Error: "Submission already graded" or 404 |

#### TC-N06: Permission 403 — No Assignment Tracking Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as a user without `tenant.home-work-assignment-tracking.*` permissions | Dashboard loads |
| 2 | Check if the Homework Master tab is visible | Tab hidden or greyed out |
| 3 | Navigate directly to `/lms-home-work?tab=homework_assignment` | HTTP 403 Forbidden |
| 4 | Navigate to a direct assignment URL `/lms-home-work/assignments/{id}` | HTTP 403 Forbidden |

#### TC-N07: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out of the application | Redirected to login page |
| 2 | Navigate to `/lms-home-work?tab=homework_assignment` | Redirected to `/login` |
| 3 | Navigate to `/lms-home-work/assignments/{id}` directly | Redirected to `/login` |
| 4 | After login, verify original URL loads | Assignment Tracking page loads correctly |

#### TC-D02: Publishing Homework Creates Assignments Automatically

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create a new homework for a class with 35 enrolled students | Homework created in draft state |
| 3 | Publish the homework | Success message displayed |
| 4 | DB check: `SELECT COUNT(*) FROM lms_homework_assignment WHERE homework_id = {id}` | Count = 35 (matches enrolled student count) |
| 5 | Verify each assignment has correct `class_id`, `subject_id` | All assignments properly linked |

#### TC-D03: Re-publishing Updates Existing (No Duplicates)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Use homework from TC-D02 (35 assignments) | 35 existing assignments |
| 2 | Enroll 5 new students to the class | 40 total students enrolled |
| 3 | Re-publish the homework | Success message displayed |
| 4 | DB check: `SELECT COUNT(*) FROM lms_homework_assignment WHERE homework_id = {id}` | Count = 40 (no duplicates) |
| 5 | DB check: existing 35 assignments have `updated_at` changed | Existing records updated |
| 6 | DB check: 5 new assignments have `created_at` = new timestamp | New records created for new students |

#### TC-D04: Toggle Release → `released_at` Timestamped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Use DB to find an assignment with `is_released = false` and `released_at IS NULL` | Assignment found |
| 3 | Toggle release on this assignment | Success response received |
| 4 | DB check: `SELECT is_released, released_at FROM lms_homework_assignment WHERE id={id}` | `is_released = true`, `released_at` approx = current DB time |
| 5 | Toggle release again (set back to false) | `is_released = false`, `released_at` remains unchanged |

#### TC-D05: Toggle Release → Assignment Status Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Find assignment with status "Pending Release" and `is_released = false` | Assignment found |
| 3 | Toggle release to `is_released = true` | Success response |
| 4 | DB check: `SELECT status_id FROM lms_homework_assignment WHERE id={id}` | `status_id` now corresponds to "Assigned" |
| 5 | Verify grid badge updates from grey "Pending Release" to blue "Assigned" | Badge reflects new status |

#### TC-D06: Late Override Reason Audited

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Perform late submission override with a reason | Override successful |
| 3 | DB check: `SELECT late_submission_override_by, late_submission_override_at, late_submission_override_reason FROM lms_homework_assignment WHERE id={id}` | `override_by` = current user ID, `override_at` timestamped, `reason` = entered text |
| 4 | Verify audit trail is complete | All three audit fields populated correctly |

#### TC-D07: Reminder Stamps `reminder_sent_at`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Send reminder for an assignment | Success message displayed |
| 3 | DB check: `SELECT reminder_sent_at FROM lms_homework_assignment WHERE id={id}` | `reminder_sent_at` is not null and timestamped |
| 4 | DB check: `SELECT * FROM notifications WHERE type LIKE '%HomeworkReminder%' AND notifiable_id = {student_id}` | Notification record exists with correct type and data |
| 5 | Verify `student_notified_at` or `parent_notified_at` is also updated if applicable | Notification timestamps recorded |

#### TC-D08: View Count Increments On Student Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record current `view_count` for an assignment | e.g., view_count = 0 |
| 2 | Log in as the student and view the assignment | Assignment detail page loads |
| 3 | DB check: `SELECT view_count, viewed_at FROM lms_homework_assignment WHERE id={id}` | `view_count` = 1 (incremented), `viewed_at` timestamped |
| 4 | Student refreshes the page | Page loads again |
| 5 | DB check: `view_count` after refresh | `view_count` = 2 (incremented again) |

#### TC-D09: Create → `created_by` Set To Auth User

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin (determine user ID, e.g., ID=1) | Dashboard loads |
| 2 | Publish a homework to create assignments | Assignments created |
| 3 | DB check: `SELECT created_by FROM lms_homework_assignment WHERE homework_id = {id} LIMIT 1` | `created_by` = current authenticated user's ID (e.g., 1) |
| 4 | Create assignments via direct insert as another user | `created_by` matches that user's ID |

#### TC-D10: Update → `updated_by` Set To Auth User

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Perform a mutation on an assignment (e.g., extend due date) | Success |
| 3 | DB check: `SELECT updated_by, updated_at FROM lms_homework_assignment WHERE id={id}` | `updated_by` = current user ID, `updated_at` timestamped |
| 4 | Perform another mutation (e.g., toggle release) | Success |
| 5 | DB check: `updated_by` updated again | `updated_by` = current user ID (updated to latest mutation user) |

#### TC-D11: ON DELETE CASCADE — Homework Deletion Cascades to Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 35 students | 35 assignment records exist |
| 2 | Force-delete the homework | Homework permanently removed |
| 3 | DB check: SELECT COUNT(*) FROM lms_homework_assignment WHERE homework_id={id} | 0 records (all cascaded) |

#### TC-D12: ON DELETE RESTRICT — Parent Delete Rejected if Assignment Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework referencing Class A with assignments | Assignment records exist |
| 2 | Attempt DELETE on Class A from sch_classes | DB throws FK RESTRICT error |
| 3 | Repeat for subject_id, academic_session_id | Each RESTRICT constraint enforced |

#### TC-D13: ON DELETE SET NULL — Section/Override By Set to NULL on Parent Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find assignment with section_id=X and late_submission_override_by=Y | Both populated |
| 2 | Delete section X from sch_sections | assignment.section_id set to NULL |
| 3 | Delete user Y from sys_users | assignment.late_submission_override_by set to NULL |

#### TC-D14: DEFAULT Values on Insert

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Publish homework (bulk-inserts assignments) | Assignments created |
| 2 | DB check: is_released=0, view_count=0, is_active=1 | Defaults applied |
| 3 | DB check: allow_late_submission=NULL, due_date=NULL, release_condition='ON_TOPIC_COMPLETE' | NULL defaults inherited |

#### TC-D15: INDEX Exists for Query Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run EXPLAIN SELECT on lms_homework_assignment WHERE homework_id=? AND student_id=? | Uses UNIQUE index |
| 2 | Run EXPLAIN on status_id filter | Uses idx_hwa_status |
| 3 | Run EXPLAIN on is_released filter | Uses idx_hwa_is_released |
| 4 | Run EXPLAIN on due_date range query | Uses idx_hwa_due_date |

#### TC-D16: BC-CON-02 — Effective due_date Resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with due_date = 25 July 2026 | Homework exists with due_date set |
| 2 | Publish homework and verify assignments created | Assignments exist for enrolled students |
| 3 | DB check: assignment with NULL due_date — query COALESCE(assignment.due_date, homework.due_date) | Effective due_date = 25 July 2026 (inherited from homework) |
| 4 | Extend a specific assignment's due_date to 30 July 2026 | Assignment due_date updated |
| 5 | DB check: COALESCE(assignment.due_date, homework.due_date) for the modified assignment | Effective due_date = 30 July 2026 (own value takes precedence) |
| 6 | DB check: other assignments still have NULL due_date | Other assignments still inherit homework.due_date = 25 July 2026 |

#### TC-D17: BC-CON-03 — Effective allow_late_submission Resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with allow_late_submission = 1 (allowed) | Homework has late submission enabled |
| 2 | Publish homework and verify default on assignments | All assignments have allow_late_submission = NULL |
| 3 | DB check: COALESCE(assignment.allow_late_submission, homework.allow_late_submission) | Effective policy = 1 (inherits from homework) |
| 4 | Override one assignment: set allow_late_submission = 0 (deny) with reason | Override saved |
| 5 | DB check: COALESCE(assignment.allow_late_submission, homework.allow_late_submission) for overridden assignment | Effective policy = 0 (explicit override takes precedence) |
| 6 | DB check: other assignments still have NULL | Other assignments still inherit homework default = 1 |

#### TC-D18: BC-CON-04 — Scheduled OVERDUE Job

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with due_date in the past (e.g., 10 July 2026) | Homework exists with past due_date |
| 2 | Publish homework — assignments created with status = PENDING_RELEASE | Assignments exist |
| 3 | Release assignments (toggle release) → status changes to ASSIGNED | Assignments in ASSIGNED status |
| 4 | Ensure no submission exists for the test assignment | No submission record |
| 5 | Run the nightly scheduled job (artisan command for overdue check) | Job executes |
| 6 | DB check: SELECT status_id FROM lms_homework_assignment WHERE id={id} | Status = OVERDUE (status_id mapped to OVERDUE) |
| 7 | Verify assignments with submissions are NOT marked overdue | SUBMITTED/GRADED statuses unchanged |
| 8 | Verify assignments with future due_date are NOT marked overdue | Status remains ASSIGNED, not OVERDUE |

#### TC-D19: BC-CON-05 — Topic Completion Auto-Releases ON_TOPIC_COMPLETE Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with release_condition = ON_TOPIC_COMPLETE, linked to a syllabus topic | Homework created in draft |
| 2 | Publish homework → assignments created with status = PENDING_RELEASE, is_released = 0 | An assignment rows in PENDING_RELEASE |
| 3 | DB check: SELECT is_released, status_id FROM lms_homework_assignment WHERE homework_id={id} | is_released = 0, status_id = PENDING_RELEASE |
| 4 | Mark the associated syllabus topic as completed via teacher UI | Topic completion saved |
| 5 | DB check (immediately after topic completion): SELECT is_released, status_id, released_at FROM lms_homework_assignment WHERE homework_id={id} | is_released = 1, status_id = ASSIGNED, released_at timestamped |
| 6 | Verify assignments for other homeworks with IMMEDIATE/ON_SCHEDULED_DATE are unaffected | Their release status unchanged |

#### TC-D20: BC-CON-06 — section_id Reflects Student's Actual Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with section_id = NULL (all sections) targeting Class 8 | Homework.section_id = NULL |
| 2 | Ensure enrolled students belong to different sections: Student A in 8-A, Student B in 8-B | Students in distinct sections |
| 3 | Publish homework | Assignments created |
| 4 | DB check: SELECT assignment.section_id, student.section_id FROM lms_homework_assignment JOIN std_students ON ... WHERE student_id = StudentA | assignment.section_id = section_id of 8-A (matches student's enrolled section) |
| 5 | DB check: same query for Student B | assignment.section_id = section_id of 8-B (different from Student A's section) |
| 6 | Confirm assignment.section_id != homework.section_id (when homework.section_id is NULL) | assignment.section_id reflects student's actual section, not the homework's target |
| 7 | Create homework with specific section (e.g., 8-A only) | Homework.section_id = 8-A |
| 8 | Publish and verify assignments for 8-A students | assignment.section_id = 8-A (matches student's section, which also equals homework's section in this case) |

#### TC-CR01: Blade @can Directives — Tab Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the hub page blade file (e.g., `homework-master.blade.php`) | File loaded |
| 2 | Search for `@can('tenant.home-work-assignment-tracking.viewAny')` surrounding the Assignment Tracking tab link | `@can` directive present |
| 3 | Verify `@endcan` closes the permission block | Permission block properly closed |
| 4 | Verify that without this permission the tab is hidden from the UI | Tab not rendered in HTML |
| 5 | Verify the `@can` value matches the permission name in section 1 | Permission name matches `tenant.home-work-assignment-tracking.viewAny` |

#### TC-CR02: DB Transaction For Grade Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LmsHomeworkController.php` | File loaded |
| 2 | Locate `assignmentsGrade()` method | Method found |
| 3 | Verify `DB::transaction()` or `\DB::beginTransaction()` is used | Transaction wraps the grade logic |
| 4 | Verify both `HomeworkSubmission` update and `HomeworkAssignment` status update are inside the transaction | Both operations within same transaction |
| 5 | Verify `DB::commit()` on success and `DB::rollBack()` on exception | Transaction properly finalized |
| 6 | Verify exception handling (try-catch) around the transaction | Exceptions cause rollback, no partial updates |

#### TC-CR03: `isset()` / Null-Safe Checks For Student/Homework Relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade view files for assignment tracking (e.g., `show.blade.php`, `index.blade.php`) | Files loaded |
| 2 | Search for `$assignment->student->` patterns | Properly uses `?->` null-safe operator or `isset()` check |
| 3 | Verify `$assignment?->student?->first_name` or `optional($assignment->student)->first_name` pattern | Null-safe operator used |
| 4 | Verify `$assignment?->homework?->title` pattern | Null-safe operator used for homework relation |
| 5 | Confirm no `Trying to get property of non-object` errors possible | All optional chaining in place |

#### TC-CR04: Due Date Validation On Server Side

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LmsHomeworkController.php` | File loaded |
| 2 | Locate `assignmentUpdateDueDate()` method | Method found |
| 3 | Verify validation rule: new due_date must be greater than current `due_date` | Validation `gt:current_due_date` or custom validator present |
| 4 | Check if validation is in a FormRequest class | Request class with rule exists |
| 5 | Verify error message matches "Due date override must be later than the existing due date." | Custom validation message configured |
| 6 | Verify validation runs before the update query | Validation gates the DB write |

#### TC-CR05: Hub Page Tab Integration — Permission-Filtered Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the hub page blade file that renders Homework Master tabs | File loaded |
| 2 | Locate the Assignment Tracking tab link | Tab link element found |
| 3 | Verify `@can('tenant.home-work-assignment-tracking.viewAny')` wraps the tab | `@can` / `@endcan` present |
| 4 | Search for the route generating the tab URL | Route name matches `/lms-home-work?tab=homework_assignment` |
| 5 | Without permission, verify tab is not rendered in HTML | Tab markup absent |
| 6 | Without permission, verify direct URL `/lms-home-work?tab=homework_assignment` returns 403 | Gate check present in `assignmentsIndex()` |

#### TC-P14: Search Assignments By Student Email

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays all assignments |
| 3 | Type a known student's email in the search box | Grid filters to show only assignments for that student (filter uses `student.user` relationship) |
| 4 | Type partial email prefix (e.g., first 3 chars before @) | Partial email matches shown |
| 5 | Type a non-existent email | "No records found" displayed |
| 6 | Clear search | Full list restored |

#### TC-D21: Due Date Extension Creates Student Notification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Extend due date for a student via "Edit Due Date" | PATCH to `/assignments/{id}/due-date` succeeds |
| 4 | DB check: `SELECT * FROM notifications WHERE type LIKE '%HomeworkDueDate%' AND notifiable_id = {student_id}` | Notification record created with correct type |
| 5 | DB check: `SELECT * FROM notification_targets WHERE notification_id = {notification_id}` | NotificationTarget record exists linking to the student |
| 6 | Verify notification payload contains homework title, new due date, and assignment ID | Notification data payload populated correctly |

#### TC-D22: Release Toggle Creates Student Notification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Assignment Tracking tab | Grid displays assignments |
| 3 | Toggle release for a PENDING_RELEASE assignment | Success message displayed |
| 4 | DB check: `SELECT * FROM notifications WHERE type LIKE '%HomeworkRelease%' AND notifiable_id = {student_id}` | Notification record created with correct type |
| 5 | DB check: `SELECT * FROM notification_targets WHERE notification_id = {notification_id}` | NotificationTarget record exists linking to the student |
| 6 | Verify notification payload contains homework title, released timestamp, and assignment ID | Notification data payload populated correctly |
