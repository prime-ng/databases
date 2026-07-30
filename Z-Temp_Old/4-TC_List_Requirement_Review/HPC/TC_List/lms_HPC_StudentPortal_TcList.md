# TC List – HPC Student Portal

## 1. Feature Information

| Field | Value |
|---|---|
| **Module** | HPC (Higher Purpose Curriculum) |
| **Tab Group** | Student Portal |
| **Feature** | Student Portal – Self Assessment, Goals, Peer Review |
| **Controller(s)** | `Modules\Hpc\Http\Controllers\StudentHpcFormController`, `StudentGoalsController`, `PeerHpcFormController` |
| **Model(s)** | `Modules\Hpc\Models\StudentFormSubmission`, `PeerAssignment`, `PeerResponse`, `HpcReport` |
| **URL(s)** | `hpc/student/dashboard`, `hpc/student/form/{report_id}`, `hpc/student/submit/{report_id}`, `hpc/student/goals/{report_id}`, `hpc/student/peer-review/{assignment_id}` |
| **Validation** | report_id required+exists; student_id auto-injected from auth; status ENUM; fields_total/filled integers |
| **Permission(s)** | `tenant.hpc-student.view`, `tenant.hpc-student.submit` |
| **Soft Deletes** | Yes — StudentFormSubmission, PeerAssignment, PeerResponse all use SoftDeletes trait |
| **Activity Log** | None |

---

## 2. Pre-conditions

1. HPC module is installed and active.
2. Student user is authenticated and logged into the tenant.
3. Seed data exists: at least one HpcReport record linked to the student.
4. Student owns at least one StudentFormSubmission record (any status).
5. Peer assignments exist for at least one cycle number.
6. `hpc_student_form_submissions`, `hpc_peer_assignments`, `hpc_peer_responses` tables exist and are migrated.
7. Student has `tenant.hpc-student.view` and `tenant.hpc-student.submit` permissions assigned.

---

## 3. Default Data Load

| # | Table | Records Expected |
|---|---|---|
| 1 | `hpc_reports` | ≥ 1 report linked to student |
| 2 | `hpc_student_form_submissions` | ≥ 3 submissions with mix of statuses (pending, in_progress, completed) |
| 3 | `hpc_peer_assignments` | ≥ 2 peer assignments for the student |
| 4 | `hpc_peer_responses` | ≥ 1 existing peer response per assignment |
| 5 | `users` | Active student user with HPC module access |
| 6 | `permissions` | `tenant.hpc-student.view` and `tenant.hpc-student.submit` assigned |

---

## 4. Test Data Strategy

| Data Type | Source | Approach |
|---|---|---|
| Valid report IDs | Factory/Seeder | Pre-seeded HpcReport records with known IDs |
| Invalid report IDs | Hard-coded | Non-existent integer (e.g. 99999), negative, zero, string, special chars |
| Student form submissions | Factory | Create with controlled status values |
| Peer assignments | Factory | Create with cycle_number (1–9), various peer_student_id |
| Auth user | Test Auth | Authenticate as the student who owns the submission |
| Permission mismatch | Role edit | Revoke one permission via Spatie before request |

---

## 5. Business Conditions

### BC-DB – Database Conditions

| ID | Condition | Description |
|---|---|---|
| BC-DB-01 | hpc_student_form_submissions table schema | id (PK), report_id (FK→hpc_reports.id), student_id (FK→users.id), template_id, part_id, status (ENUM: pending/in_progress/completed), fields_total (int), fields_filled (int), started_at (nullable timestamp), completed_at (nullable timestamp), deleted_at (nullable timestamp) |
| BC-DB-02 | hpc_peer_assignments table schema | id (PK), report_id (FK→hpc_reports.id), student_id (FK→users.id), peer_student_id (FK→users.id), cycle_number (int 1–9), peer_number (int), status (ENUM: pending/in_progress/completed), completed_at (nullable timestamp), deleted_at (nullable timestamp) |
| BC-DB-03 | hpc_peer_responses table schema | id (PK), assignment_id (FK→hpc_peer_assignments.id), html_object_name (string), value (text), deleted_at (nullable timestamp) |
| BC-DB-04 | Soft Deletes | StudentFormSubmission, PeerAssignment, PeerResponse models use Illuminate\Database\Eloquent\SoftDeletes trait |
| BC-DB-05 | Foreign key: StudentFormSubmission.report_id → HpcReport.id | CASCADE on delete |

### BC-VAL – Validation Conditions

| ID | Condition | Description |
|---|---|---|
| BC-VAL-01 | report_id required | All student endpoints require valid report_id in route |
| BC-VAL-02 | report_id must exist in hpc_reports | 404 returned on non-existent report |
| BC-VAL-03 | student_id auto-injected | Controller reads from `auth()->id()` — never from request body |
| BC-VAL-04 | status ENUM validation | Only `pending`, `in_progress`, `completed` values accepted |
| BC-VAL-05 | fields_total must be integer | Non-integer values rejected by form request validation |
| BC-VAL-06 | fields_filled must be integer | Non-integer values rejected |
| BC-VAL-07 | fields_filled ≤ fields_total | Business logic validation in service layer |
| BC-VAL-08 | peer_student_id must differ from student_id | Self-review prohibited |
| BC-VAL-09 | cycle_number range 1–9 | Out-of-range values rejected |

### BC-AUTH – Authorisation Conditions

| ID | Condition | Description |
|---|---|---|
| BC-AUTH-01 | `tenant.hpc-student.view` required | Dashboard, form open, goals load, peer review load |
| BC-AUTH-02 | `tenant.hpc-student.submit` required | Form submit, goals submit, peer review submit |
| BC-AUTH-03 | Permission checked via middleware | Spatie permission gates on every endpoint |
| BC-AUTH-04 | Unauthenticated user redirected to login | Guest user hitting any student endpoint gets 302 |
| BC-AUTH-05 | Unauthorised user gets 403 | Authenticated user without correct permission receives 403 |

### BC-BIZ – Business Logic Conditions

| ID | Condition | Description |
|---|---|---|
| BC-BIZ-01 | Dashboard scope | Only submissions owned by logged-in student are shown |
| BC-BIZ-02 | Dashboard filter | Only `pending` and `in_progress` submissions shown as actionable cards |
| BC-BIZ-03 | Self-assessment edit scope | Only fields tagged as `student-owned` are editable |
| BC-BIZ-04 | Teacher-owned fields read-only | Teacher fields rendered as text/label, not input |
| BC-BIZ-05 | Goals wizard – 5 steps | Steps: Career, College, Skills, Short-term, Long-term |
| BC-BIZ-06 | Goals save as draft | Each step can save independently without final submit |
| BC-BIZ-07 | Goals final submit | Submit locks all steps, no further edits |
| BC-BIZ-08 | No self-review | peer_student_id must !== student_id |
| BC-BIZ-09 | No reciprocal pairs | If A reviews B, B cannot review A in same cycle |
| BC-BIZ-10 | Cycle range | cycle_number is 1 through 9 inclusive |
| BC-BIZ-11 | Submit locks | After section submit, re-edit is refused |
| BC-BIZ-12 | Progress calculation | `(fields_filled / fields_total) * 100` rounded down |
| BC-BIZ-13 | Missing DB table handling | If table missing → graceful error message, not 500 |
| BC-BIZ-14 | Completion updates dashboard | Completed items move to "Completed" section |

### BC-REF – Reference Conditions

| ID | Condition | Description |
|---|---|---|
| BC-REF-01 | ENUM reference | `status` in submissions: pending, in_progress, completed |
| BC-REF-02 | cycle_number reference | Peer cycles: values 1 through 9 |
| BC-REF-03 | Student ownership | `student_id` column in submissions table identifies owner |
| BC-REF-04 | Report reference | `report_id` FK references hpc_reports.id |

---

## 6. Test Case List – Student Portal

### TC-P (Positive Test Cases)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-P-001 | Dashboard loads with card list for authenticated student | Dashboard page renders with list of pending/in-progress submission cards | Tester A | Tester B | ⬜ |
| TC-P-002 | Self-assessment form opens for pending submission | Form renders with all fields; student-owned fields shown as inputs, teacher fields as labels | Tester A | Tester B | ⬜ |
| TC-P-003 | Save text field value in self-assessment | Text value persists in hpc_student_form_submissions after save; fields_filled increments | Tester A | Tester B | ⬜ |
| TC-P-004 | Save dropdown selection in self-assessment | Dropdown selection persists; fields_filled increments | Tester A | Tester B | ⬜ |
| TC-P-005 | Save partial progress and reopen form | Previously saved values restored on reopen; fields_filled reflects saved count | Tester A | Tester B | ⬜ |
| TC-P-006 | Submit a section — status changes to completed | Section locked; fields_filled = fields_total; submitted section shows read-only | Tester A | Tester B | ⬜ |
| TC-P-007 | Dashboard shows in-progress card after partial save | Card displays updated completion percentage progress bar | Tester A | Tester B | ⬜ |
| TC-P-008 | Dashboard shows completed card after final submit | Card moves to Completed section; shows 100% | Tester A | Tester B | ⬜ |
| TC-P-009 | Goals wizard loads with 5-step UI | All 5 step tabs/labels visible; first step active | Tester A | Tester B | ⬜ |
| TC-P-010 | Save goals step 1 (Career) as draft | Career step saves; wizard stays on step 1; other steps still empty | Tester A | Tester B | ⬜ |
| TC-P-011 | Save goals step 2 (College) as draft | College step saves independently | Tester A | Tester B | ⬜ |
| TC-P-012 | Save goals step 3 (Skills) as draft | Skills step saves independently | Tester A | Tester B | ⬜ |
| TC-P-013 | Save goals step 4 (Short-term) as draft | Short-term step saves independently | Tester A | Tester B | ⬜ |
| TC-P-014 | Save goals step 5 (Long-term) as draft | Long-term step saves independently | Tester A | Tester B | ⬜ |
| TC-P-015 | Submit all goals — final submit locks wizard | All steps locked; no further edits accepted; confirmation message shown | Tester A | Tester B | ⬜ |
| TC-P-016 | Reopen submitted goals — read-only view | Goals render as read-only; no save/submit buttons | Tester A | Tester B | ⬜ |
| TC-P-017 | Peer review form loads with valid assignment_id | Peer review form renders with rating fields for the assigned peer | Tester A | Tester B | ⬜ |
| TC-P-018 | Rate peer on numeric scale and save | Rating value persists in hpc_peer_responses; assignment status shows in_progress | Tester A | Tester B | ⬜ |
| TC-P-019 | Complete peer assignment — submit final review | PeerAssignment status = completed; completed_at timestamp set | Tester A | Tester B | ⬜ |
| TC-P-020 | Completion percentage updates after each save | Progress bar on dashboard refreshes to show new percentage | Tester A | Tester B | ⬜ |
| TC-P-021 | Dashboard shows Pending/InProgress/Completed filter tabs | Tabs render; clicking each filter shows only matching cards | Tester A | Tester B | ⬜ |
| TC-P-022 | Student sees only own submissions — no cross-student data leak | Logged-in student never sees another student's submission content | Tester A | Tester B | ⬜ |
| TC-P-023 | Save all fields one-by-one — progress increments per save | fields_filled increments atomically on each field save | Tester A | Tester B | ⬜ |
| TC-P-024 | Dashboard loading with zero submissions — empty state | Empty state message displayed; no errors | Tester A | Tester B | ⬜ |

### TC-N (Negative Test Cases)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-N-001 | Invalid report_id (non-existent integer) → 404 | 404 Not Found page rendered; no exception stack trace | Tester A | Tester B | ⬜ |
| TC-N-002 | Invalid report_id (negative number) → 404 | 404 Not Found rendered | Tester A | Tester B | ⬜ |
| TC-N-003 | Invalid report_id (zero) → 404 | 404 Not Found rendered | Tester A | Tester B | ⬜ |
| TC-N-004 | Invalid report_id (string value) → 404 | 404 Not Found rendered | Tester A | Tester B | ⬜ |
| TC-N-005 | Edit teacher-owned field — value discarded and logged | Value not saved; warning logged; field reverts to original | Tester A | Tester B | ⬜ |
| TC-N-006 | Submit empty required field — validation error | Error message displayed; submission not saved | Tester A | Tester B | ⬜ |
| TC-N-007 | Re-edit submitted/completed section — refused | Edit request rejected; section remains read-only; error flash message | Tester A | Tester B | ⬜ |
| TC-N-008 | Peer assignment missing for given assignment_id — graceful error | Error message "Peer assignment not found"; no 500; no stack trace | Tester A | Tester B | ⬜ |
| TC-N-009 | Duplicate peer submission for same assignment_id | Second submission rejected; error message "You have already completed this peer review" | Tester A | Tester B | ⬜ |
| TC-N-010 | Unauthenticated guest user redirected to login | 302 redirect to login page; no form data exposed | Tester A | Tester B | ⬜ |
| TC-N-011 | Authenticated user without `tenant.hpc-student.view` → 403 | 403 Forbidden; error message "You do not have permission to view this page" | Tester A | Tester B | ⬜ |
| TC-N-012 | Authenticated user without `tenant.hpc-student.submit` → 403 on submit | 403 Forbidden on form/goal/peer submit actions | Tester A | Tester B | ⬜ |
| TC-N-013 | Missing DB table (hpc_student_form_submissions dropped) → graceful error | Error message "System configuration error. Please contact administrator." No 500, no debug output | Tester A | Tester B | ⬜ |
| TC-N-014 | Missing DB table (hpc_peer_assignments dropped) → graceful error | Graceful error displayed; peer section shows "Unavailable" | Tester A | Tester B | ⬜ |
| TC-N-015 | fields_total set to 0 — division by zero avoided | Progress shows N/A or 0%; no DivisionByZeroError | Tester A | Tester B | ⬜ |
| TC-N-016 | fields_filled exceeds fields_total — capped at 100% | Progress clamped to 100%; no negative or overflow display | Tester A | Tester B | ⬜ |
| TC-N-017 | CSRF token mismatch on form submit | 419 Page Expired; form data not persisted | Tester A | Tester B | ⬜ |

### TC-D (Design / Deep-Dive Test Cases)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-D-001 | StudentFormSubmission SoftDeletes – delete sets deleted_at | Soft delete sets deleted_at timestamp; record remains in DB | Tester A | Tester B | ⬜ |
| TC-D-002 | StudentFormSubmission restore after soft delete | `restore()` clears deleted_at; record accessible again | Tester A | Tester B | ⬜ |
| TC-D-003 | StudentFormSubmission force delete removes record permanently | `forceDelete()` physically removes row from DB | Tester A | Tester B | ⬜ |
| TC-D-004 | PeerAssignment SoftDeletes – delete sets deleted_at | Soft delete sets deleted_at; record hidden from queries | Tester A | Tester B | ⬜ |
| TC-D-005 | PeerAssignment restore after soft delete | Restored record visible in queries; FK intact | Tester A | Tester B | ⬜ |
| TC-D-006 | PeerResponse FK cascade – delete assignment cascades | Deleting PeerAssignment cascades to related PeerResponses (or nullifies) | Tester A | Tester B | ⬜ |
| TC-D-007 | Role-field filter – teacher-owned field not editable by student | Input rendered as plain text; POST value ignored | Tester A | Tester B | ⬜ |
| TC-D-008 | Submit lock – after submit, subsequent POST returns error | Controller returns validation error; DB unchanged | Tester A | Tester B | ⬜ |
| TC-D-009 | Peer auto-assignment – no self-review logic | Algorithm never assigns student_id == peer_student_id | Tester A | Tester B | ⬜ |
| TC-D-010 | Peer no-reciprocal logic – A→B prevents B→A in same cycle | If assignment exists (A→B), creation of (B→A) is blocked | Tester A | Tester B | ⬜ |
| TC-D-011 | Progress percentage calculation – (filled/total)*100 exact | 3/10 = 30%; 10/10 = 100%; 0/10 = 0%; integer floor | Tester A | Tester B | ⬜ |
| TC-D-012 | StudentFormSubmission.report_id FK to HpcReport | Cannot insert orphan report_id; FK constraint enforced | Tester A | Tester B | ⬜ |
| TC-D-013 | PeerAssignment cycle uniqueness per student+peer pair | Unique composite key on (student_id, peer_student_id, cycle_number) prevents duplicates | Tester A | Tester B | ⬜ |
| TC-D-014 | Soft deleted records excluded from default dashboard query | Dashboard only counts records with deleted_at IS NULL | Tester A | Tester B | ⬜ |
| TC-D-015 | Status transition: pending → in_progress → completed | Each transition valid; completed → pending blocked | Tester A | Tester B | ⬜ |
| TC-D-016 | Completed_at timestamp set on status=completed | DB records completed_at = NOW(); null otherwise | Tester A | Tester B | ⬜ |
| TC-D-017 | Multiple cycles can exist simultaneously | Student can have peer assignments in cycle 1, 2, 3 concurrently | Tester A | Tester B | ⬜ |
| TC-D-018 | Student cannot view peer's responses to other students | Query scope ensures student only sees own peer assignments | Tester A | Tester B | ⬜ |
| TC-D-019 | fields_total computed from template, not user-input | Changing template part increases/decreases fields_total accordingly | Tester A | Tester B | ⬜ |
| TC-D-020 | WithTrashed scope available for admin views | Admin can query soft-deleted records via ->withTrashed() | Tester A | Tester B | ⬜ |
| TC-D-021 | Only own goals visible to student | Goals query scoped by student_id | Tester A | Tester B | ⬜ |

---

## 7. Detailed Test Steps

### TC-P-001: Dashboard loads with card list for authenticated student

**Prerequisites:** Student is logged in; has submissions with status pending and in_progress.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/dashboard` as authenticated student | Page loads without error |
| 2 | Observe page content | Dashboard heading displayed |
| 3 | Check card list area | At least one card rendered for each pending/in_progress submission |
| 4 | Verify card data | Each card shows report name, status badge, progress percentage |
| 5 | Verify no cards for completed submissions (if any exist) | Completed submissions may appear in a separate "Completed" section |

### TC-P-002: Self-assessment form opens for pending submission

**Prerequisites:** Student has at least one submission with status = pending.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click on a pending card from dashboard | Redirected to `hpc/student/form/{report_id}` |
| 2 | Observe form layout | Form title matches report name |
| 3 | Locate student-owned fields | Rendered as input, select, textarea elements |
| 4 | Locate teacher-owned fields | Rendered as plain text or label; no edit controls |
| 5 | Check for save/submit buttons | Save Draft and Submit buttons present |

### TC-P-003: Save text field value in self-assessment

**Prerequisites:** Form is open for a pending submission.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Locate a student-owned text input | Input is editable |
| 2 | Enter text value "Test response ABC" | Text appears in input |
| 3 | Click Save Draft button | Success message "Progress saved" |
| 4 | Reload the page | Entered text value restored |
| 5 | Check DB `hpc_student_form_submissions` | fields_filled incremented by number of saved fields |

### TC-P-004: Save dropdown selection in self-assessment

**Prerequisites:** Form is open; a dropdown field exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Locate a student-owned dropdown | Dropdown is editable |
| 2 | Select an option (e.g., "Option B") | Option selected |
| 3 | Click Save Draft | Success message shown |
| 4 | Reload page | Dropdown shows previously selected option |

### TC-P-005: Save partial progress and reopen form

**Prerequisites:** Form has multiple fields; only some filled.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Fill 3 out of 10 fields | 3 fields have values |
| 2 | Click Save Draft | fields_filled = 3 |
| 3 | Close browser / navigate away | Session ends |
| 4 | Open same report form again | 3 previously filled values restored |
| 5 | Check progress indicator | Shows 30% |

### TC-P-006: Submit a section — status changes to completed

**Prerequisites:** All required fields filled.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Fill all required fields | All inputs have valid values |
| 2 | Click Submit button | Confirmation dialog "Are you sure?" (if implemented) |
| 3 | Confirm submission | Status changes to completed |
| 4 | Check DB | status = 'completed', completed_at timestamp set, fields_filled = fields_total |
| 5 | Try editing any field | All fields rendered as read-only text |

### TC-P-007: Dashboard shows in-progress card after partial save

**Prerequisites:** Submission has status in_progress.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to dashboard | Card visible in "In Progress" section |
| 2 | Hover over progress bar | Tooltip shows "3/10 fields completed" |
| 3 | Verify progress bar width | ~30% of container width |

### TC-P-008: Dashboard shows completed card after final submit

**Prerequisites:** Submission has status completed.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to dashboard | Card visible in "Completed" section |
| 2 | Verify progress bar | Shows 100% |
| 3 | Click on completed card | Form opens in read-only mode |

### TC-P-009: Goals wizard loads with 5-step UI

**Prerequisites:** Student has a valid report_id.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/goals/{report_id}` | Wizard container renders |
| 2 | Check step indicators | 5 steps visible: Career, College, Skills, Short-term, Long-term |
| 3 | Verify first step is active | Step 1 content visible; others grayed/hidden |
| 4 | Check for navigation controls | Next/Prev buttons or step click navigation |

### TC-P-010: Save goals step 1 (Career) as draft

**Prerequisites:** Goals wizard open on step 1.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Enter text in Career step fields | Values entered |
| 2 | Click Save Draft for step 1 | Success message "Career goals saved" |
| 3 | Navigate to step 2 | Step 2 loads |
| 4 | Return to step 1 | Previously saved values restored |

### TC-P-011: Save goals step 2 (College) as draft

**Prerequisites:** Step 1 saved; step 2 fields visible.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to step 2 (College) | Fields rendered |
| 2 | Enter college name, major, etc. | Values entered |
| 3 | Click Save Draft | Success message "College goals saved" |

### TC-P-012: Save goals step 3 (Skills) as draft

**Prerequisites:** Step 2 saved.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to step 3 (Skills) | Skills fields rendered |
| 2 | Enter skills to develop | Values entered |
| 3 | Click Save Draft | Success message "Skills goals saved" |

### TC-P-013: Save goals step 4 (Short-term) as draft

**Prerequisites:** Step 3 saved.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to step 4 (Short-term) | Short-term goals fields rendered |
| 2 | Enter short-term goals | Values entered |
| 3 | Click Save Draft | Success message "Short-term goals saved" |

### TC-P-014: Save goals step 5 (Long-term) as draft

**Prerequisites:** Step 4 saved.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to step 5 (Long-term) | Long-term goals fields rendered |
| 2 | Enter long-term goals | Values entered |
| 3 | Click Save Draft | Success message "Long-term goals saved" |

### TC-P-015: Submit all goals — final submit locks wizard

**Prerequisites:** All 5 steps have data saved.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click Submit All Goals button | Confirmation prompt |
| 2 | Confirm final submission | Wizard enters read-only mode |
| 3 | Try editing any step field | Fields disabled; Save button gone |
| 4 | Check DB | goals_submitted_at timestamp set (if column exists) |

### TC-P-016: Reopen submitted goals — read-only view

**Prerequisites:** Goals have been submitted.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/goals/{report_id}` | Wizard loads in read-only mode |
| 2 | Click through each step | All values visible but not editable |
| 3 | Verify no Save or Submit buttons | Buttons absent |

### TC-P-017: Peer review form loads with valid assignment_id

**Prerequisites:** Valid PeerAssignment exists for the current student.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/peer-review/{assignment_id}` | Peer review form renders |
| 2 | Check peer info displayed | Peer student name and details shown |
| 3 | Check rating fields | Rating scale (e.g., 1–5) shown for each criterion |

### TC-P-018: Rate peer on numeric scale and save

**Prerequisites:** Peer review form open.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Select rating "4" for first criterion | Rating selected |
| 2 | Select rating "3" for second criterion | Rating selected |
| 3 | Click Save Draft | Ratings persisted; success message |
| 4 | Reload page | Ratings restored |

### TC-P-019: Complete peer assignment — submit final review

**Prerequisites:** All rating fields filled.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click Submit Final Review | Confirmation dialog |
| 2 | Confirm | Status changes to completed; completed_at timestamp set |
| 3 | Check DB | hpc_peer_assignments.status = 'completed' |
| 4 | Try reopening | Form in read-only mode |

### TC-P-020: Completion percentage updates after each save

**Prerequisites:** Submission has fields_total > 0.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Note current fields_filled count | e.g., 4/10 |
| 2 | Save one more field | fields_filled increments to 5 |
| 3 | Navigate to dashboard | Progress bar shows 50% |
| 4 | Repeat save | Progress updates each time |

### TC-P-021: Dashboard shows Pending/InProgress/Completed filter tabs

**Prerequisites:** Student has submissions in all statuses.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to dashboard | Tab bar visible: Pending, In Progress, Completed, All |
| 2 | Click "Pending" tab | Only pending cards shown |
| 3 | Click "In Progress" tab | Only in_progress cards shown |
| 4 | Click "Completed" tab | Only completed cards shown |
| 5 | Click "All" tab | All cards shown |

### TC-P-022: Student sees only own submissions — no cross-student data leak

**Prerequisites:** Another student has submissions in same report.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Log in as Student A | Dashboard shows Student A's cards only |
| 2 | Attempt to access Student B's form URL directly | 403 or redirect; no data from Student B exposed |

### TC-P-023: Save all fields one-by-one — progress increments per save

**Prerequisites:** Form has 10 student-owned fields; all empty.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open form | fields_filled = 0 |
| 2 | Fill field 1 and save | fields_filled = 1 |
| 3 | Fill field 2 and save | fields_filled = 2 |
| 4 | Continue for all 10 fields | fields_filled increments to 10 |

### TC-P-024: Dashboard loading with zero submissions — empty state

**Prerequisites:** Student has zero submissions.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to dashboard | Dashboard loads without error |
| 2 | Observe content | "No submissions found" or similar empty state message |
| 3 | Verify no exception or error log | App log clean |

### TC-N-001: Invalid report_id (non-existent integer) → 404

**Prerequisites:** None.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/form/99999` (non-existent ID) | 404 page rendered |
| 2 | Verify error message | "Report not found" displayed |
| 3 | Check server log | No exception stack trace logged at error level |

### TC-N-002: Invalid report_id (negative number) → 404

**Prerequisites:** None.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/form/-1` | 404 page rendered |
| 2 | Verify no DB query attempted with negative ID | Route binding fails gracefully |

### TC-N-003: Invalid report_id (zero) → 404

**Prerequisites:** None.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/form/0` | 404 page rendered |

### TC-N-004: Invalid report_id (string value) → 404

**Prerequisites:** None.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/form/abc` | 404 page rendered |

### TC-N-005: Edit teacher-owned field — value discarded and logged

**Prerequisites:** Form with teacher-owned fields rendered.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open form | Teacher-owned field shown as label/text |
| 2 | Use browser DevTools to change field to input | Field becomes editable artificially |
| 3 | POST modified value | Server ignores value; original preserved |
| 4 | Check Laravel log | Warning logged: "Attempt to edit teacher-owned field [field_name] by student [id]" |

### TC-N-006: Submit empty required field — validation error

**Prerequisites:** Form has at least one required field empty.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Leave required field empty | Field shows required indicator |
| 2 | Click Submit | Form not submitted |
| 3 | Check error message | "This field is required" shown near empty field |
| 4 | Check DB | Status unchanged; no update |

### TC-N-007: Re-edit submitted/completed section — refused

**Prerequisites:** Submission status = completed.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open completed form | All fields read-only |
| 2 | Attempt to POST edit via DevTools | Server rejects; error "Section already submitted" |
| 3 | Check DB | Data unchanged |

### TC-N-008: Peer assignment missing for given assignment_id — graceful error

**Prerequisites:** Assignment ID does not exist.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/student/peer-review/99999` | Error page rendered |
| 2 | Verify error message | "Peer assignment not found" or similar |
| 3 | Verify no 500 error | Status code 404 |

### TC-N-009: Duplicate peer submission for same assignment_id

**Prerequisites:** Peer assignment already completed.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open completed peer review | Read-only view |
| 2 | Attempt POST submit via DevTools | Rejected; error "You have already completed this peer review" |
| 3 | Check DB | No duplicate record; original unchanged |

### TC-N-010: Unauthenticated guest user redirected to login

**Prerequisites:** User not logged in.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access `hpc/student/dashboard` while not authenticated | 302 redirect to login page |
| 2 | Check redirect URL | URL contains `/login` or `/auth/login` |
| 3 | After login | Redirected back to original page |

### TC-N-011: Authenticated user without `tenant.hpc-student.view` → 403

**Prerequisites:** User authenticated but lacks permission.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Assign user role without `tenant.hpc-student.view` | Permission not present |
| 2 | Access `hpc/student/dashboard` | 403 Forbidden |
| 3 | Verify error message | "You do not have permission to view this page" |

### TC-N-012: Authenticated user without `tenant.hpc-student.submit` → 403 on submit

**Prerequisites:** User has view but not submit permission.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access form as user without submit permission | Form loads (view OK) |
| 2 | Click Submit | 403 Forbidden |
| 3 | Try Save Draft | If save requires submit permission → 403; if save uses view → may succeed |

### TC-N-013: Missing DB table (hpc_student_form_submissions dropped) → graceful error

**Prerequisites:** Table dropped for testing.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Remove `hpc_student_form_submissions` table | Table missing |
| 2 | Access `hpc/student/dashboard` | Error message displayed; no 500 |
| 3 | Verify graceful message | "System configuration error" or "Please contact administrator" |
| 4 | Check log | Exception logged but not displayed to user |

### TC-N-014: Missing DB table (hpc_peer_assignments dropped) → graceful error

**Prerequisites:** Table dropped for testing.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Remove `hpc_peer_assignments` table | Table missing |
| 2 | Access `hpc/student/peer-review/{id}` | Graceful error; no 500 |
| 3 | Verify section shows "Unavailable" message | Peer review section renders placeholder |

### TC-N-015: fields_total set to 0 — division by zero avoided

**Prerequisites:** Submission with fields_total = 0.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open form with fields_total = 0 | Form loads |
| 2 | Check progress display | Shows "N/A" or "0%" |
| 3 | Check logs | No DivisionByZeroError or warning |

### TC-N-016: fields_filled exceeds fields_total — capped at 100%

**Prerequisites:** fields_filled > fields_total (simulate data inconsistency).

| Step | Action | Expected Result |
|---|---|---|
| 1 | Artificially set fields_filled = 15, fields_total = 10 in DB | Inconsistent data |
| 2 | Open form | Progress shows 100%, not 150% |
| 3 | Verify no exception | Form loads normally |

### TC-N-017: CSRF token mismatch on form submit

**Prerequisites:** Valid form loaded; CSRF token expired or manipulated.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open form normally | CSRF token in page |
| 2 | Replace CSRF token with invalid value | Token mismatch |
| 3 | Submit form | 419 Page Expired |
| 4 | Check DB | No changes persisted |

### TC-D-001: StudentFormSubmission SoftDeletes – delete sets deleted_at

**Prerequisites:** Record exists in DB.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `$submission->delete()` on a StudentFormSubmission | deleted_at set to current timestamp |
| 2 | Query DB directly | Row still exists with deleted_at NOT NULL |
| 3 | Query via Eloquent default scope | Record not returned |

### TC-D-002: StudentFormSubmission restore after soft delete

**Prerequisites:** Record is soft-deleted.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `$submission->restore()` | deleted_at set to null |
| 2 | Query via default Eloquent scope | Record returned |
| 3 | Verify all original data intact | fields_filled, status, report_id unchanged |

### TC-D-003: StudentFormSubmission force delete removes record permanently

**Prerequisites:** Record exists (soft-deleted or active).

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `$submission->forceDelete()` | Row physically removed from table |
| 2 | Query DB directly | Row does not exist |
| 3 | Verify cascade | Any dependent data handled per FK rules |

### TC-D-004: PeerAssignment SoftDeletes – delete sets deleted_at

**Prerequisites:** PeerAssignment record exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `$assignment->delete()` | deleted_at timestamp set |
| 2 | Check withTrashed() | Record retrievable with trashed scope |
| 3 | Check PeerResponses | Related responses may soft-delete or remain depending on cascade |

### TC-D-005: PeerAssignment restore after soft delete

**Prerequisites:** PeerAssignment is soft-deleted.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `$assignment->restore()` | deleted_at cleared |
| 2 | Query via normal scope | Record available |
| 3 | Verify peer_student_id, cycle_number intact | All attributes preserved |

### TC-D-006: PeerResponse FK cascade – delete assignment cascades

**Prerequisites:** PeerAssignment with related PeerResponse records.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Note count of PeerResponses for assignment | e.g., 3 responses |
| 2 | Delete the PeerAssignment | Soft delete on assignment |
| 3 | Check PeerResponses | Responses deletion behaviour depends on FK setup (SET NULL or CASCADE) |
| 4 | Verify FK constraint | If CASCADE, responses also soft-deleted |

### TC-D-007: Role-field filter – teacher-owned field not editable by student

**Prerequisites:** Form has at least one teacher-owned field.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Inspect form HTML for teacher-owned field | Rendered as `<span>`, `<p>`, or disabled input |
| 2 | Attempt POST with teacher field value | Controller ignores field |
| 3 | Check DB | Teacher field original value unchanged |

### TC-D-008: Submit lock – after submit, subsequent POST returns error

**Prerequisites:** Submission status = completed.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Submit form | Status = completed |
| 2 | Send POST request to same endpoint | Server returns error (JSON or HTTP error) |
| 3 | DB unchanged | No modification to record |

### TC-D-009: Peer auto-assignment – no self-review logic

**Prerequisites:** Peer assignment algorithm runs.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Fetch any peer assignment for student | peer_student_id !== student_id |
| 2 | Verify across all assignments in system | Zero assignments where student_id == peer_student_id |

### TC-D-010: Peer no-reciprocal logic – A→B prevents B→A in same cycle

**Prerequisites:** Assignment exists: A→B in cycle X.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Attempt to create B→A in cycle X | Creation blocked |
| 2 | Check error/return value | Assignment not created or validation error |
| 3 | Try different cycle | B→A allowed in different cycle |

### TC-D-011: Progress percentage calculation – (filled/total)*100 exact

**Prerequisites:** Known fields_filled and fields_total values.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Set fields_filled=3, fields_total=10 | Progress = 30% |
| 2 | Set fields_filled=0, fields_total=10 | Progress = 0% |
| 3 | Set fields_filled=10, fields_total=10 | Progress = 100% |
| 4 | Set fields_filled=5, fields_total=7 | Progress = 71% (floor, not ceiling) |
| 5 | Set fields_filled=1, fields_total=3 | Progress = 33% (integer floor) |

### TC-D-012: StudentFormSubmission.report_id FK to HpcReport

**Prerequisites:** HpcReport exists with known ID.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Insert submission with valid report_id | Insert succeeds |
| 2 | Insert submission with invalid report_id (99999) | FK constraint violation error |
| 3 | Delete report that has submissions | Cascade or restrict per FK definition |

### TC-D-013: PeerAssignment cycle uniqueness per student+peer pair

**Prerequisites:** Student A and Student B exist.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Create assignment: A→B, cycle 1 | Succeeds |
| 2 | Create assignment: A→B, cycle 1 again | Fails (duplicate) |
| 3 | Create assignment: A→B, cycle 2 | Succeeds (different cycle) |
| 4 | Create assignment: B→A, cycle 1 | Succeeds unless reciprocal block exists |

### TC-D-014: Soft deleted records excluded from default dashboard query

**Prerequisites:** At least one soft-deleted submission.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Hard-delete would remove; soft-delete sets deleted_at | Record soft-deleted |
| 2 | Call dashboard endpoint | Soft-deleted record not in response |
| 3 | Call with withTrashed scope (admin) | Soft-deleted record included |

### TC-D-015: Status transition: pending → in_progress → completed

**Prerequisites:** Submission in status pending.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open form for first time | Status changes to in_progress |
| 2 | Submit form | Status changes to completed |
| 3 | Attempt to revert to pending | Blocked |
| 4 | Attempt to revert to in_progress | Blocked |

### TC-D-016: Completed_at timestamp set on status=completed

**Prerequisites:** Submission is being submitted.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Submit form with all required fields | Status = completed |
| 2 | Check DB completed_at | Timestamp equals submission time |
| 3 | Verify timezone | UTC or configured timezone |

### TC-D-017: Multiple cycles can exist simultaneously

**Prerequisites:** Peer assignments for cycles 1, 2, 3 exist.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Query all peer assignments for student | Returns assignments from multiple cycles |
| 2 | Complete cycle 1 assignment | Cycle 2 and 3 unaffected |
| 3 | Dashboard shows all active cycles | Each cycle shown separately |

### TC-D-018: Student cannot view peer's responses to other students

**Prerequisites:** Student B has submitted responses about Student C.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Student A accesses `hpc/student/peer-review/{assignment}` | Only their own assignments visible |
| 2 | Student A attempts to access Student B's assignment | 403 or 404 |
| 3 | Verify query scoping | Controller scopes by `student_id = auth()->id()` |

### TC-D-019: fields_total computed from template, not user-input

**Prerequisites:** Template has defined field count.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Create submission from Template A (10 fields) | fields_total = 10 |
| 2 | Create submission from Template B (15 fields) | fields_total = 15 |
| 3 | Edit template to add fields | existing submissions NOT updated |

### TC-D-020: WithTrashed scope available for admin views

**Prerequisites:** Admin user accessing trashed records.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Soft-delete a submission | deleted_at set |
| 2 | Query without withTrashed() | Record excluded |
| 3 | Query with withTrashed() | Record included |
| 4 | Admin panel shows trashed records | UI has "Show deleted" toggle |

### TC-D-021: Only own goals visible to student

**Prerequisites:** Multiple students have goals.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Student A saves goals | Goals stored with student_id = A |
| 2 | Student B navigates to goals | Only Student B's goals shown |
| 3 | Student B attempts to view Student A's goals URL | 403 or redirect |

---

*Document generated for HPC Student Portal testing. Status column uses ⬜ (pending), 🟢 (pass), 🔴 (fail), 🟡 (blocked).*

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `dashboard()` — StudentHpcFormController (Line 29)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `StudentHpcFormController.php:32` | `Gate::authorize('tenant.hpc-student.view')` |
| 2 | `StudentHpcFormController.php:34` | `$this->getAuthenticatedStudentId()` — queries `Student::where('user_id', auth()->id())->first()` |
| 3 | `StudentHpcFormController.php:36` | `$this->formService->getPendingReports($studentId)` — loads pending reports |
| 4 | `StudentHpcFormController.php:38` | `$this->formService->getOverallProgress($templateId)` — computes progress % |
| 5 | `StudentHpcFormController.php:40-47` | Returns `hpc::student.dashboard` view |

### CODE-TRACE-02: `form()` — StudentHpcFormController (Line 53)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `StudentHpcFormController.php:55` | `Gate::authorize('tenant.hpc-student.view')` |
| 2 | `StudentHpcFormController.php:57-59` | `HpcReport::where('id',$reportId)->where('student_id',$studentId)->firstOrFail()` — ownership check |
| 3 | `StudentHpcFormController.php:61` | Checks status not PUBLISHED/ARCHIVED |
| 4 | `StudentHpcFormController.php:64` | `formService->getStudentPages($templateId)` — loads pages |
| 5 | `StudentHpcFormController.php:67` | `formService->getOrCreateSubmissions(...)` |
| 6 | `StudentHpcFormController.php:70-75` | `formService->getOverallProgress(...)` |
| 7 | `StudentHpcFormController.php:78-85` | Loads saved values via `reportService->getSavedValues()` |
| 8 | `StudentHpcFormController.php:88-95` | Returns `hpc::student.form` view |

### CODE-TRACE-03: `save()` — StudentHpcFormController (Line 101)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `StudentHpcFormController.php:103` | `Gate::authorize('tenant.hpc-student.submit')` |
| 2 | `StudentHpcFormController.php:105-108` | Validates report ownership and status |
| 3 | `StudentHpcFormController.php:111` | `HpcSectionRoleService::filterPayloadByRole($payload, $templateId, 'student')` |
| 4 | `StudentHpcFormController.php:114` | Gets allowed field names from template |
| 5 | `StudentHpcFormController.php:117` | `reportService->upsertReportItemsForFields(...)` — saves field values |
| 6 | `StudentHpcFormController.php:120-125` | Updates page progress |
| 7 | `StudentHpcFormController.php:128-171` | Returns JSON response |

### CODE-TRACE-04: `submit()` — StudentHpcFormController (Line 177)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `StudentHpcFormController.php:179` | `Gate::authorize('tenant.hpc-student.submit')` |
| 2 | `StudentHpcFormController.php:181-185` | Validates report ownership |
| 3 | `StudentHpcFormController.php:188` | `formService->markComplete($reportId, $studentId)` — marks final submission |
| 4 | `StudentHpcFormController.php:190-206` | Returns JSON success |

### CODE-TRACE-05: `assignPeers()` — PeerHpcFormController (Line 30)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `PeerHpcFormController.php:32` | `Gate::authorize('tenant.hpc.update')` — teacher permission |
| 2 | `PeerHpcFormController.php:34` | Validates `class_section_id`, `template_id` |
| 3 | `PeerHpcFormController.php:37` | `peerService->autoAssignPeers($classSectionId, $templateId, auth()->id())` |
| 4 | `PeerHpcFormController.php:39-50` | Returns JSON with count of assigned peers |

### CODE-TRACE-06: `form()` — PeerHpcFormController (Line 82)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `PeerHpcFormController.php:84` | `Gate::authorize('tenant.hpc-student.view')` |
| 2 | `PeerHpcFormController.php:86-92` | `PeerAssignment::where('id',$assignmentId)->where('peer_student_id',$studentId)->where('is_active',true)->with(['student','report.template'])->firstOrFail()` |
| 3 | `PeerHpcFormController.php:94` | Checks if already completed |
| 4 | `PeerHpcFormController.php:97` | `peerService->getPeerPages($templateId, $cycle_number)` |
| 5 | `PeerHpcFormController.php:100` | Maps responses to saved values |
| 6 | `PeerHpcFormController.php:103-119` | Returns `hpc::student.peer-review` view |

### CODE-TRACE-07: `save()` — PeerHpcFormController (Line 125)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `PeerHpcFormController.php:127` | `Gate::authorize('tenant.hpc-student.submit')` |
| 2 | `PeerHpcFormController.php:129-132` | Validates assignment ownership |
| 3 | `PeerHpcFormController.php:135` | `HpcSectionRoleService::filterPayloadByRole($payload, $template_id, 'peer')` |
| 4 | `PeerHpcFormController.php:138` | `peerService->saveResponses($assignment, $filteredPayload)` |
| 5 | `PeerHpcFormController.php:141-161` | If `submit_final` ? `completeReview($assignment)` ? JSON |

### CODE-TRACE-08: `index()` — StudentGoalsController (Line 41)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `StudentGoalsController.php:43` | `Gate::authorize('tenant.hpc-student.view')` |
| 2 | `StudentGoalsController.php:46-48` | Validates report ownership, `template_id == 4` (Secondary only) |
| 3 | `StudentGoalsController.php:54-56` | Determines `currentStep` (1-8 wizard) |
| 4 | `StudentGoalsController.php:59-66` | Loads template with specific `page_no` matching step config |
| 5 | `StudentGoalsController.php:69-75` | Loads saved values via `reportService->getSavedValues()` |
| 6 | `StudentGoalsController.php:78-85` | Computes step completion via `getStepCompletion()` |
| 7 | `StudentGoalsController.php:88-94` | Returns `hpc::student.goals` view |

---
