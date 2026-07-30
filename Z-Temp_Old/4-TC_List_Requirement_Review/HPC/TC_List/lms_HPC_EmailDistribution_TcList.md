# lms_HPC_EmailDistribution_TcList

## Module: HPC → Email Distribution

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HPC |
| Tab Group | Email Distribution |
| Feature | Email Distribution |
| URL(s) | `hpc/send-report-email`, `hpc/send-bulk-report-email` |
| Controller | `Modules\Hpc\Http\Controllers\HpcController` (sendReportEmail, sendBulkReportEmail) |
| Model(s) | HpcReport, Student (guardian relation), Job (Laravel queue) |
| Permissions | `tenant.hpc.viewAny` |
| Soft Deletes | No |
| Activity Log | None |

---

## 2. Pre-conditions

- Required permissions: `tenant.hpc.viewAny`
- At least one `HpcReport` record with status=final or published exists for the student
- Student must have a `guardians` relation defined (with `email` field on the guardian model)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Queue connection must be configured (database/sqs/redis) for `SendHpcReportEmail` job
- Mail driver must be configured for sending via Laravel Mail system
- Email template `hpc::emails.hpc-report` must exist in views
- `Mail\HpcReportMail` mailable class must exist
- `Jobs\SendHpcReportEmail` job class must exist with `->queue()` dispatch
- For bulk email: at least one selected student must have a guardian with email to verify sending

---

## 3. Default Data Load

When the email distribution action is triggered, the following data is fetched and processed:

| Data Loaded | Source | Filters | Pagination |
|------------|--------|---------|------------|
| HpcReport for email | `HpcReport::with('student.guardians')->findOrFail($report_id)` | report_id | None (single record) |
| Guardian email | `$student->guardians->pluck('email')->filter()->first()` | email not null, not empty | None (first valid) |
| Bulk students | `Student::whereIn('id', $student_ids)->with('guardians', 'hpcReport')->get()` | student_ids array | None |
| Email view-link URL | Generated via route helper or encrypted student_id | student_id | None |
| Access code | Generated or fetched from HpcReport | report_id | None |

---

## 4. Test Data Strategy

- **Guardian with email**: Seed at least one guardian with a valid email address for the student
- **Guardian without email**: Seed a guardian with `email=null` and another with `email=''` (empty string)
- **Invalid email**: Seed a guardian with malformed email like "not-an-email"
- **Bulk mixed**: Create a set of students with varying guardian email scenarios (some have email, some don't)
- **Duplicate send**: Send the same student report email twice to verify duplicate is allowed
- **No rate limit**: Send bulk emails to verify no rate limiting is applied
- **Queue testing**: Use `sync` queue driver for testing, `database` for integration
- **Pre-test cleanup**: Delete sent email records from mailtrap/test mail driver before/after tests

---

## 5. Business Conditions

### 4.1 Database Schema — Email Distribution Tables

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-01 | hpc_reports | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | hpc_reports | student_id | INT UNSIGNED | NOT NULL, FK → `sch_students.id` |
| BC-DB-03 | hpc_reports | status | ENUM('draft','final','published','archived') | NOT NULL DEFAULT 'draft' |
| BC-DB-04 | hpc_reports | access_code | VARCHAR(255) | NULLABLE |
| BC-DB-05 | students | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-06 | students | first_name | VARCHAR(255) | NOT NULL |
| BC-DB-07 | students | last_name | VARCHAR(255) | NOT NULL |
| BC-DB-08 | guardians | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-09 | guardians | student_id | INT UNSIGNED | NOT NULL, FK → `sch_students.id` |
| BC-DB-10 | guardians | email | VARCHAR(255) | NULLABLE |
| BC-DB-11 | guardians | first_name | VARCHAR(255) | NOT NULL |
| BC-DB-12 | jobs | id | BIGINT UNSIGNED | PK, auto-increment (Laravel queue) |
| BC-DB-13 | jobs | queue | VARCHAR(255) | NOT NULL |
| BC-DB-14 | jobs | payload | LONGTEXT | NOT NULL |
| BC-DB-15 | jobs | attempts | TINYINT UNSIGNED | NOT NULL DEFAULT 0 |

### 4.2 Validation Rules (Create)

| BC ID | Field | Rule | Error Message / Behavior |
|-------|-------|------|--------------------------|
| BC-VAL-01 | report_id (single email) | Must exist in `hpc_reports` table | 422 Validation Error |
| BC-VAL-02 | student_ids (bulk) | Must be an array of integers | 422 Validation Error |
| BC-VAL-03 | student_ids (bulk) | Each ID must exist in `sch_students` | 422 Validation Error |
| BC-VAL-04 | guardian email | No validation on email format (just existence check) | Guardian without email: skipped, warning logged |

### 4.3 Validation Rules (Update)

| BC ID | Field | Rule | Error Message / Behavior |
|-------|-------|------|--------------------------|
| BC-VAL-U01 | (No update-specific validation) | N/A — no update operations for email dispatch | No update operations exist for this feature |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.hpc.viewAny` | sendReportEmail(), sendBulkReportEmail() | Without → 403 Forbidden on send-report-email and send-bulk-report-email |
| BC-AUTH-02 | Guest access | — | Redirected to login page |
| BC-AUTH-03 | Student role | — | Cannot send email (no viewAny permission) |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Single email — guardian has email | Finds guardian email via `student->guardians` relation, generates view-link, queues `SendHpcReportEmail` job |
| BC-BIZ-02 | Single email — no guardian email | Skips with warning logged — no email sent |
| BC-BIZ-03 | Single email — email queued | Job dispatched via `->queue()`; does not block UI |
| BC-BIZ-04 | Bulk email — iterate selected students | Processes each student independently |
| BC-BIZ-05 | Bulk email — skip student without guardian email | Student skipped, warning logged, continues to next student |
| BC-BIZ-06 | Bulk email — summary returned | Response shows count of sent and skipped |
| BC-BIZ-07 | Email content — school name | Blade template `hpc::emails.hpc-report` includes school name in email body |
| BC-BIZ-08 | Email content — student name | Email template shows student's first_name and last_name |
| BC-BIZ-09 | Email content — view-link | Email contains URL to view the report (public view URL or encrypted link) |
| BC-BIZ-10 | Email content — access code | Email displays the report's access code |
| BC-BIZ-11 | Email content — 30-day validity notice | Email includes text stating the view link is valid for 30 days |
| BC-BIZ-12 | Guardian resolution | From `student->guardians` relation, reads `email` field, picks first non-null non-empty email |
| BC-BIZ-13 | View-link generation | Uses encrypted student_id or public route URL |
| BC-BIZ-14 | No rate-limit on bulk | All emails queued without delay (enhancement planned for future) |
| BC-BIZ-15 | Email sent via Mail + Queue | `Mail\HpcReportMail` mailable queued via `Jobs\SendHpcReportEmail` |
| BC-BIZ-16 | Email with invalid format — skipped | Invalid email format is treated as "no valid email" — skipped with warning |
| BC-BIZ-17 | Same student send twice | Duplicate emails allowed — no deduplication logic |
| BC-BIZ-18 | Unpublished card — allowed | No status check on HpcReport before sending email |
| BC-BIZ-19 | Queue not running | Job sits in queue until worker picks it up; no failure on dispatch |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | hpc_reports.student_id | sch_students (id) | CASCADE |
| BC-REF-02 | guardians.student_id | sch_students (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Send single email — guardian has email | Email sent successfully via queue; job dispatched | — | — | ⬜ |
| TC-P02 | Email received with correct student name | Received email contains student's first_name and last_name | — | — | ⬜ |
| TC-P03 | Email received with correct class information | Email body includes student's class/grade | — | — | ⬜ |
| TC-P04 | Email contains view-link URL | Email body has clickable link to view report | — | — | ⬜ |
| TC-P05 | Email contains access code | Email displays the report's access code | — | — | ⬜ |
| TC-P06 | Email template renders correctly | HTML email renders with correct layout, school branding, all sections | — | — | ⬜ |
| TC-P07 | Bulk email sends to multiple students (all have email) | All students receive email; queue jobs dispatched for each | — | — | ⬜ |
| TC-P08 | Guardians without email are skipped with warning | Students without guardian email logged as warning; no email sent | — | — | ⬜ |
| TC-P09 | Bulk email summary shows sent/skipped counts | Response/notification shows X sent, Y skipped | — | — | ⬜ |
| TC-P10 | Email is queued (doesn't block UI) | Response returns immediately; job in queue table | — | — | ⬜ |
| TC-P11 | Same student send twice (duplicate allowed) | Both sends queue successfully; duplicate emails sent | — | — | ⬜ |
| TC-P12 | Email contains 30-day validity notice | Email text mentions link valid for 30 days | — | — | ⬜ |
| TC-P13 | Bulk email with mixed guardian statuses | Some have email (sent), some don't (skipped); summary shows correct counts | — | — | ⬜ |
| TC-P14 | Email sent to primary guardian (first guardian with email) | Uses first guardian email found in guardians relation | — | — | ⬜ |
| TC-P15 | Student has multiple guardians — first with email used | Multiple guardians; first non-null email used | — | — | ⬜ |
| TC-P16 | School name renders in email | Email template shows configured school/tenant name | — | — | ⬜ |
| TC-P17 | View-link is clickable and works | Clicking link opens report in browser (public view) | — | — | ⬜ |
| TC-P18 | Bulk email 50 students processes successfully | All 50 emails queued; no timeout or memory issue | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Student without guardian email — skipped | No email sent; warning logged; no error thrown | — | — | ⬜ |
| TC-N02 | Guardian email is empty string — skipped | Empty email treated as no email; skipped with warning | — | — | ⬜ |
| TC-N03 | Invalid email format — skipped | Malformed email skipped with warning; no attempt to send | — | — | ⬜ |
| TC-N04 | Non-existent student in bulk | 422 Validation Error for invalid student_id | — | — | ⬜ |
| TC-N05 | Unpublished card (draft status) — allowed | Email sent without status check (no restriction) | — | — | ⬜ |
| TC-N06 | Permission denied | User without `tenant.hpc.viewAny` gets 403 Forbidden | — | — | ⬜ |
| TC-N07 | Guest redirect | Unauthenticated user redirected to login | — | — | ⬜ |
| TC-N08 | Queue not running — job waits | Job stays in jobs table until worker processes it | — | — | ⬜ |
| TC-N09 | Non-existent report_id for single email | 422 Validation Error or 404 Not Found | — | — | ⬜ |
| TC-N10 | Bulk request with duplicate student_ids | Duplicates processed independently; emails sent for each occurrence | — | — | ⬜ |
| TC-N11 | Bulk request with empty student_ids array | 422 Validation Error (array must not be empty) | — | — | ⬜ |
| TC-N12 | Student with no guardians relation at all | No guardian record exists; skipped with warning | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | SendHpcReportEmail job serialization | Job payload serializes correctly; stored in jobs table | — | — | ⬜ |
| TC-D02 | B | HpcReportMail mailable content | Mailable builds correct email with student name, view-link, access code, 30-day notice | — | — | ⬜ |
| TC-D03 | C | Guardian email resolution via student->guardians relation | `$student->guardians` returns collection; first non-null email used | — | — | ⬜ |
| TC-D04 | D | Skip trigger for guardian email = null | Guard condition checks email !== null; skips if null | — | — | ⬜ |
| TC-D05 | D | Skip trigger for guardian email = empty string | Guard condition checks email !== ''; skips if empty | — | — | ⬜ |
| TC-D06 | E | Queueable job dispatched with ->queue() | Job dispatched via `$this->job->onQueue('hpc-emails')` or similar | — | — | ⬜ |
| TC-D07 | F | Bulk processing independent — one failure doesn't stop others | If one student's job fails to dispatch, others still queued | — | — | ⬜ |
| TC-D08 | G | Email link uses public view URL | Link in email points to `hpc/hpc-view/{encrypted_student_id}` | — | — | ⬜ |
| TC-D09 | H | Access code generation | Access code exists on HpcReport or generated at send time | — | — | ⬜ |
| TC-D10 | I | 30-day validity text in email template | Template contains hardcoded or dynamic "30 days" validity message | — | — | ⬜ |
| TC-D11 | J | Job queue name configuration | SendHpcReportEmail dispatched to specific queue name | — | — | ⬜ |
| TC-D12 | K | Email sent from correct sender address | From address matches tenant/school configured email | — | — | ⬜ |
| TC-D13 | L | Bulk email large payload (50 students) | 50 jobs created in queue; no payload size issues | — | — | ⬜ |
| TC-D14 | M | Email subject line format | Subject contains student name and "HPC Report" | — | — | ⬜ |
| TC-D15 | N | Soft-deleted student guardian relation | Student soft-deleted; guardian email still resolved (or handled gracefully) | — | — | ⬜ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Send Single Email — Guardian Has Email

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Ensure student has HpcReport (status=final) and a guardian with valid email | Seed data ready |
| 3 | POST to `hpc/send-report-email` with report_id | Request accepted (200) |
| 4 | Verify response indicates email queued | Success message shown |
| 5 | Check jobs table for SendHpcReportEmail entry | Job found in queue |
| 6 | Run queue worker | Job processed |
| 7 | Check mailtrap/test mail driver | Email received |

---

#### TC-P02: Email Received With Correct Student Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send report email for student John Doe | Email queued and processed |
| 2 | Open received email | Email body contains "John Doe" |
| 3 | Verify full name appears in greeting or body | Correct name displayed |

---

#### TC-P03: Email Received With Correct Class Information

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send report email for student in Class 5A | Email queued and processed |
| 2 | Open received email | Email body contains "Class 5A" or equivalent class info |

---

#### TC-P04: Email Contains View-Link URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send report email | Email sent |
| 2 | Open received email | Clickable URL/link present |
| 3 | Verify URL points to valid route (hpc-view or similar) | Correct report view URL |

---

#### TC-P05: Email Contains Access Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure report has an access_code = "ABC123" | Access code exists |
| 2 | Send report email | Email sent |
| 3 | Open received email | "ABC123" visible in email body |

---

#### TC-P06: Email Template Renders Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send report email | Email sent |
| 2 | Open received email in HTML mode | Template renders with school logo/branding, student info, view-link, access code, 30-day notice |
| 3 | Verify all sections present | Complete layout renders |
| 4 | Verify no broken images or missing CSS | Email renders correctly |

---

#### TC-P07: Bulk Email Sends To Multiple Students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 students, each with guardian email and HpcReport | 5 ready records |
| 2 | POST to `hpc/send-bulk-report-email` with all 5 student_ids | Request accepted |
| 3 | Verify 5 SendHpcReportEmail jobs in queue | 5 jobs created |
| 4 | Process queue | All 5 emails sent |
| 5 | Check mailtrap/test mail driver | 5 emails received |

---

#### TC-P08: Guardians Without Email Are Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with HpcReport but guardian has email=null | No guardian email |
| 2 | Send report email for this student | No email attempt |
| 3 | Check log file | Warning logged: "No guardian email for student X" |
| 4 | No email in mail driver | No email sent |

---

#### TC-P09: Bulk Email Summary Shows Sent/Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 4 students: 3 with guardian email, 1 without | Mixed dataset |
| 2 | POST to `hpc/send-bulk-report-email` with all 4 | Request accepted |
| 3 | Check response/notification | Summary: "3 emails sent, 1 skipped" or equivalent |

---

#### TC-P10: Email Is Queued (Doesn't Block UI)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send single report email | Request returns immediately (no delay) |
| 2 | Check response time | Under 1 second |
| 3 | Verify job in queue | Not processed yet (if using async driver) |
| 4 | Process queue worker | Email sent afterwards |

---

#### TC-P11: Same Student Send Twice (Duplicate Allowed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send report email for Student A | First email queued |
| 2 | Send report email for Student A again (same report_id) | Second email queued |
| 3 | Process queue | 2 emails sent to same guardian |
| 4 | Check mail driver | 2 identical emails received |

---

#### TC-P12: Email Contains 30-Day Validity Notice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send report email | Email sent |
| 2 | Open received email | Text mentioning "30 days" or "valid for 30 days" found |
| 3 | Verify wording about link expiry | "This link will expire in 30 days" or equivalent |

---

#### TC-P13: Bulk Email With Mixed Guardian Statuses

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 students: Student A (has email), B (has email), C (email=null), D (email=''), E (invalid email) | Mixed dataset |
| 2 | POST to `hpc/send-bulk-report-email` with all 5 | Request accepted |
| 3 | Check response summary | "2 emails sent, 3 skipped" |
| 4 | Process queue | Only 2 emails sent (A and B) |
| 5 | Check logs | 3 warnings logged for C, D, E |

---

#### TC-P14: Email Sent To Primary Guardian

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with 2 guardians: Guardian 1 (email=parent1@test.com), Guardian 2 (email=parent2@test.com) | 2 guardians |
| 2 | Send report email | Email sent to parent1@test.com (first guardian) |

---

#### TC-P15: Student Has Multiple Guardians — First With Email Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with 3 guardians: G1 (email=null), G2 (email=g2@test.com), G3 (email=g3@test.com) | Multiple guardians, first has null |
| 2 | Send report email | Email sent to g2@test.com (first with non-null email) |

---

#### TC-P16: School Name Renders In Email

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Configure tenant/school name as "Sunrise International School" | School name set |
| 2 | Send report email | Email sent |
| 3 | Open email | "Sunrise International School" visible in email body/header |

---

#### TC-P17: View-Link Is Clickable And Works

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send report email | Email sent |
| 2 | Open email and click view-link | Public view page opens in browser |
| 3 | Verify report data displayed correctly | Student card/report visible |

---

#### TC-P18: Bulk Email 50 Students Processes Successfully

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 50 students, each with guardian email and HpcReport | 50 records |
| 2 | POST to `hpc/send-bulk-report-email` with all 50 | Request accepted |
| 3 | Verify 50 jobs in queue | 50 SendHpcReportEmail jobs |
| 4 | Process queue | All 50 emails sent |
| 5 | Verify no timeout or memory errors | All processed successfully |

---

### 7.2 Negative TC Steps

#### TC-N01: Student Without Guardian Email — Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with HpcReport but guardian has email=null | No guardian email |
| 2 | POST to `hpc/send-report-email` with report_id | Request accepted |
| 3 | Verify response shows email not sent | Message: "No guardian email found" |
| 4 | Check jobs table | No job created |
| 5 | Check log | Warning logged |

---

#### TC-N02: Guardian Email Is Empty String — Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with guardian having email='' | Empty email |
| 2 | Send report email | No email sent |
| 3 | Check log | Warning logged: empty email skipped |

---

#### TC-N03: Invalid Email Format — Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with guardian having email='not-an-email' | Invalid format |
| 2 | Send report email | No email sent (treated as invalid) |
| 3 | Check log | Warning logged about invalid email |

---

#### TC-N04: Non-Existent Student In Bulk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `hpc/send-bulk-report-email` with student_ids = [1, 2, 99999] | 422 Validation Error |
| 2 | Verify error message mentions invalid student_id | "Invalid student_id: 99999" |

---

#### TC-N05: Unpublished Card (Draft Status) — Allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set HpcReport status='draft' for a student | Draft report |
| 2 | Send report email | Email queued and sent (no status check restriction) |
| 3 | Verify email received | Email sent despite draft status |

---

#### TC-N06: Permission Denied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.hpc.viewAny` | Authenticated |
| 2 | POST to `hpc/send-report-email` | 403 Forbidden |
| 3 | POST to `hpc/send-bulk-report-email` | 403 Forbidden |

---

#### TC-N07: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | Not authenticated |
| 2 | POST to `hpc/send-report-email` | Redirected to login |
| 3 | POST to `hpc/send-bulk-report-email` | Redirected to login |

---

#### TC-N08: Queue Not Running — Job Waits

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Stop queue worker | No worker running |
| 2 | Send report email | Request accepted; job dispatched |
| 3 | Check jobs table | Job present with attempts=0 |
| 4 | Start queue worker | Job processed; email sent |

---

#### TC-N09: Non-Existent report_id For Single Email

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `hpc/send-report-email` with report_id=99999 | 422 Validation Error or 404 |
| 2 | Verify error message | Report not found |

---

#### TC-N10: Bulk Request With Duplicate student_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `hpc/send-bulk-report-email` with student_ids = [1, 2, 1, 2] | Request accepted |
| 2 | Verify 4 jobs created (2 duplicates) | Each occurrence processed independently |
| 3 | Guardian of student 1 receives 2 emails | Duplicate emails sent |

---

#### TC-N11: Bulk Request With Empty student_ids Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `hpc/send-bulk-report-email` with student_ids = [] | 422 Validation Error |
| 2 | Verify error message | At least one student required |

---

#### TC-N12: Student With No Guardians Relation At All

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with zero guardian records | No guardians |
| 2 | Send report email | No email sent |
| 3 | Check log | Warning logged: "No guardian found for student X" |

---

### 7.3 Dependency TC Steps

#### TC-D01: SendHpcReportEmail Job Serialization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send a report email (using sync queue for test) | Job dispatched |
| 2 | Inspect SendHpcReportEmail class | Implements ShouldQueue |
| 3 | Verify job serializes HpcReport or report_id | Serialization works; no "Object could not be serialized" error |
| 4 | Check jobs table payload for async queue | Payload contains serialized data |

---

#### TC-D02: HpcReportMail Mailable Content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcReportMail mailable class | build() method defined |
| 2 | Verify mailable uses template `hpc::emails.hpc-report` | Correct view referenced |
| 3 | Verify mailable receives: student name, view-link, access code | Data passed to view |
| 4 | Send test email and inspect content | All fields present in rendered email |

---

#### TC-D03: Guardian Email Resolution via student->guardians

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with 3 guardians: email1='a@b.com', email2=null, email3='c@d.com' | Multiple guardians |
| 2 | Execute email resolution logic (send email) | Email sent to a@b.com (first non-null) |
| 3 | Verify `$student->guardians` loads collection | Relation works |
| 4 | Verify `pluck('email')->filter()->first()` logic | First valid email selected |

---

#### TC-D04: Skip Trigger For Guardian Email = null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect sendReportEmail code for email check | Conditional found |
| 2 | Verify condition: `if (!$guardianEmail)` or `if (empty($guardianEmail))` | Null triggers skip |
| 3 | Test with email=null | Skipped; no job created |

---

#### TC-D05: Skip Trigger For Guardian Email = Empty String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect sendReportEmail code for empty check | Conditional found |
| 2 | Verify condition: `if (empty($guardianEmail))` | Empty string triggers skip |
| 3 | Test with email='' | Skipped; no job created |

---

#### TC-D06: Queueable Job Dispatched With ->queue()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect sendReportEmail code | Job dispatched via `SendHpcReportEmail::dispatch()` or `dispatch()->onQueue()` |
| 2 | Verify queue method used | `->onQueue('hpc')` or similar queue name |
| 3 | Check jobs table for queue name | Job in correct queue |

---

#### TC-D07: Bulk Processing Independent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 students: 2 with valid data, 1 with missing report | Mixed |
| 2 | Send bulk email | 2 jobs created for valid students |
| 3 | Verify the failing student doesn't block others | 2 emails sent; warning logged for failed student |
| 4 | No overall request failure | Partial success |

---

#### TC-D08: Email Link Uses Public View URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect email template or mailable | URL generation code found |
| 2 | Verify URL route is `hpc/hpc-view/{encrypted_id}` | Public view route used |
| 3 | Send test email and extract link | Clicking link opens public view |

---

#### TC-D09: Access Code Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcReport model or sendReportEmail code | Access code logic found |
| 2 | If generated at send time: check generation method | Random/unique code generated |
| 3 | If stored on model: verify field exists | access_code column on hpc_reports |
| 4 | Send email and verify access code in body | Code displayed correctly |

---

#### TC-D10: 30-Day Validity Text In Email Template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `hpc::emails.hpc-report` blade template | Template found |
| 2 | Search for "30" or "day" in template | Validity notice text found |
| 3 | Verify wording: "valid for 30 days" or equivalent | Text present |
| 4 | Send test email and verify text in body | 30-day notice visible |

---

#### TC-D11: Job Queue Name Configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect SendHpcReportEmail job class | `$queue` property or `onQueue()` call found |
| 2 | Verify queue name (e.g., 'hpc', 'emails', 'default') | Queue name identified |
| 3 | Check config/queue.php for queue mapping | Queue exists in configuration |

---

#### TC-D12: Email Sent From Correct Sender Address

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcReportMail mailable | `from()` address set |
| 2 | Verify from address matches tenant/school email | Correct sender |
| 3 | Send test email and check headers | From header matches |

---

#### TC-D13: Bulk Email Large Payload (50 Students)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 50 students with emails and reports | 50 records |
| 2 | Send bulk email for all 50 | Request accepted |
| 3 | Check jobs table | 50 jobs created |
| 4 | Verify no payload size error | All jobs serialized correctly |

---

#### TC-D14: Email Subject Line Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcReportMail mailable | Subject line defined |
| 2 | Verify subject contains student name and "HPC Report" | Subject: "HPC Report for John Doe" or similar |
| 3 | Send test email | Subject matches format |

---

#### TC-D15: Soft-Deleted Student Guardian Relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a student who has guardians with emails | Student.deleted_at set |
| 2 | Send report email for this student | Based on implementation: may or may not resolve guardian |
| 3 | Document behaviour | If guardian resolved → email sent; if not → skipped with warning |

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `sendReportEmail()` � HpcController (Line 1667)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:1669` | `Gate::authorize('tenant.hpc.viewAny')` |
| 2 | `HpcController.php:1671-1675` | Validates request: `student_id`, `academic_term_id` |
| 3 | `HpcController.php:1677-1685` | Loads `Student` with `guardians` relation |
| 4 | `HpcController.php:1687` | Resolves template via `reportService->resolveTemplateId()` |
| 5 | `HpcController.php:1689-1695` | Checks guardian emails exist |
| 6 | `HpcController.php:1697-1705` | Dispatches `SendHpcReportEmail` job (queued) |
| 7 | `HpcController.php:1707-1738` | Returns JSON with queued status |

### CODE-TRACE-02: `sendBulkReportEmail()` � HpcController (Line 1744)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:1746` | `Gate::authorize('tenant.hpc.viewAny')` |
| 2 | `HpcController.php:1748-1752` | Validates `student_ids` array, `academic_term_id` |
| 3 | `HpcController.php:1754-1765` | Batch pre-loads all students with guardians |
| 4 | `HpcController.php:1767-1790` | Loops each student: resolves template, checks guardians/emails, dispatches `SendHpcReportEmail` job |
| 5 | `HpcController.php:1792-1810` | Logs queued report links via `logQueuedReportLinks()` |
| 6 | `HpcController.php:1812-1822` | Returns JSON with queued count + warnings for missing emails |

---
