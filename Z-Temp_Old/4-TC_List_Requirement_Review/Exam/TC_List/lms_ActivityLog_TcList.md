# lms_ActivityLog_TcList

## Module: LmsExam → Exam Management → Activity Log

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Exam Management |
| Feature | Activity Log (Student Attempt Activity) |
| URL(s) | `GET /exam/master?active_tab=activity_log` (Log tab), `GET /exam/master?active_tab=event_log_pending` (Pending tab), `GET /exam/log-grievance?active_tab=activity_log` (alt route) |
| Controller | `Modules\LmsExam\Http\Controllers\LmsExamController` (masters() method, activity log/checkpoint queries) |
| Model(s) | `Modules\StudentPortal\Models\AttemptActivityLog` (table: `lms_attempt_activity_logs`), `AttemptCheckpoint` (table: `lms_attempt_checkpoints`), `AttemptActivityEventType` (table: `lms_attempt_activity_event_types`) |
| Views | `resources/views/activity_log/index.blade.php` (Activity Log tab), `resources/views/activity_log/event_log.blade.php` (Pending Attempts tab) |
| Libraries | daterangepicker, moment.js, Chart.js, Select2 |
| Pagination | Log tab: 15/page (`log_page`), Pending tab: paginated with default page size |
| Event Types | FOCUS_LOST, FULLSCREEN_EXIT, BROWSER_RESIZE, TAB_SWITCH, COPY_PASTE_DETECTED, CONTEXT_MENU_OPENED, DEVTOOLS_DETECTED, WINDOW_BLUR, NETWORK_DISCONNECT |
| Attempt Types | QUIZ, QUEST, EXAM (polymorphic via attempt_type + attempt_id) |
| Tables | `lms_attempt_activity_logs` (append-only, immutable), `lms_attempt_checkpoints` (ephemeral, deleted on submit), `lms_attempt_activity_event_types` (master) |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam.viewAny` (entire Exam module access)
- Test user must be logged in with appropriate role
- Tenant context via `tenancy()->initialize()`
- At least one online exam with student attempts must exist
- `lms_attempt_activity_logs` table must have records for activity log tab testing
- `lms_attempt_checkpoints` table must have records for pending attempts tab testing
- `lms_attempt_activity_event_types` must be seeded with standard event types
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `LmsExamController@masters()` with `active_tab=activity_log`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Activity Logs | `AttemptActivityLog::with(eventType, examAttempt.student, examAttempt.examPaper)` | Latest first | class_id, section_id, student_id, log_event_type, date_from, date_to | 15/page (`log_page`) |
| Event Types (filter) | `AttemptActivityEventType::all()` | All event types | None | None |
| Classes (filter) | `SchoolClass::where('is_active',1)->orderBy('name')` | Active classes | is_active | None |
| Pending Checkpoints | `AttemptCheckpoint::with(examAttempt.student, examAttempt.examPaper)` | Latest first | class_id, section_id, student_id | Paginated |
| Sections | Dynamic via AJAX `get-sections-by-class` | Based on class_id | class_id | None |
| Students | Dynamic via AJAX `student-search` | Based on class_id, section_id | class_id, section_id | None |

## 4. Test Data Strategy

- **Activity logs**: Insert records directly into `lms_attempt_activity_logs` with known student/paper IDs
- **Checkpoints**: Create records in `lms_attempt_checkpoints` simulating in-progress exam sessions
- **Event types**: Ensure `lms_attempt_activity_event_types` has standard types seeded
- **Date range**: Use timestamps spanning multiple days for date filter testing
- **Polymorphic nature**: Use attempt_type='EXAM' for exam module logs
- **JSON event_data**: Store structured data like `{"ip":"192.168.1.1","fullscreen":false,"tab_title":"Google"}`
- **Pre-test cleanup**: Delete test log/checkpoint records after tests

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_attempt_activity_logs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | attempt_type | ENUM('QUIZ','QUEST','EXAM') | NOT NULL |
| BC-DB-03 | attempt_id | INT | NOT NULL, polymorphic FK |
| BC-DB-04 | event_type_id | INT FK | FK → `lms_attempt_activity_event_types.id` |
| BC-DB-05 | event_data | JSON | DEFAULT NULL |
| BC-DB-06 | occurred_at | DATETIME | NOT NULL |

### 4.2 Database Schema — `lms_attempt_checkpoints`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-07 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-08 | attempt_type | ENUM('QUIZ','QUEST','EXAM') | NOT NULL |
| BC-DB-09 | attempt_id | INT | NOT NULL, polymorphic FK |
| BC-DB-10 | current_question_idx | SMALLINT | 0-based |
| BC-DB-11 | answered_question_ids | JSON | Array of answered question IDs |
| BC-DB-12 | flagged_question_ids | JSON | Array of flagged question IDs |
| BC-DB-13 | checkpoint_data | JSON | Full answer state snapshot |
| BC-DB-14 | saved_at | DATETIME | Last save timestamp |

### 4.3 Database Schema — `lms_attempt_activity_event_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-15 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-16 | code | VARCHAR(50) | UNIQUE, NOT NULL |
| BC-DB-17 | name | VARCHAR(100) | NOT NULL |
| BC-DB-18 | description | VARCHAR(255) | DEFAULT NULL |

### 4.4 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | tenant.exam.viewAny | Access to activity log and pending attempts tabs |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Activity log tab loads | Table shows log entries with sequential number, student, exam/paper, occurred_at, event type badge, details badges |
| BC-BIZ-02 | Filter by class | Logs filtered to students in selected class |
| BC-BIZ-03 | Filter by section | Logs filtered to students in selected section |
| BC-BIZ-04 | Filter by student | Logs filtered to specific student |
| BC-BIZ-05 | Filter by event type | Logs filtered to specific event type |
| BC-BIZ-06 | Filter by date range | Logs filtered between date_from and date_to |
| BC-BIZ-07 | Multi-filter combination | All filters applied together |
| BC-BIZ-08 | Clear filters | Reset button clears all filters |
| BC-BIZ-09 | Pending attempts tab loads | Table shows in-progress attempts with progress info |
| BC-BIZ-10 | Pending filter by class | Checkpoints filtered by class |
| BC-BIZ-11 | Pending filter by section | Checkpoints filtered by section |
| BC-BIZ-12 | Pending filter by student | Checkpoints filtered by student |
| BC-BIZ-13 | Checkpoint progress display | Question index, answered count, flagged count shown |
| BC-BIZ-14 | Checkpoint last saved timestamp | Date and time of last checkpoint save shown |
| BC-BIZ-15 | View checkpoint data | Button shows JSON data when clicked |
| BC-BIZ-16 | Activity logs are immutable | No update/delete operations on logs |
| BC-BIZ-17 | Checkpoints are ephemeral | Checkpoints deleted on attempt submission |
| BC-BIZ-18 | Event details displayed as badges | Key-value pairs from event_data shown as styled badges |
| BC-BIZ-19 | Event type shown as pill badge | Color-coded badge in rounded pill style |
| BC-BIZ-20 | Date range picker presets | Today, Yesterday, Last 7 Days, Last 30 Days, This Month, Last Month |
| BC-BIZ-21 | Cascading class→section→student dropdowns | Selecting class loads sections; selecting section loads students |
| BC-BIZ-22 | Pagination preserves filter state | All filter params in pagination links |
| BC-BIZ-23 | Empty state for activity logs | "No activity logs found." with icon |
| BC-BIZ-24 | Empty state for pending attempts | "No active/pending exam attempts found." with icon |
| BC-BIZ-25 | Sequential numbering in activity log | Number = (page-1)*perPage + iteration |
| BC-BIZ-26 | Student name fallback | If student relation null, shows "Student ID: X" |
| BC-BIZ-27 | Paper title fallback | If examPaper relation null, shows "N/A" |
| BC-BIZ-28 | Event type fallback | If eventType relation null, shows "Event #X" |
| BC-BIZ-29 | Empty event_data | Shows "System triggered event" italic text |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Activity Log Tab Loads With All UI Elements | Page loads with filter form (class, section, student, event type, date range), table with 6 columns, pagination | — | — | ⬜ |
| TC-P02 | Log Table Shows Correct Columns | Sequential #, Student, Exam/Paper, Occurred At, Event Type, Details | — | — | ⬜ |
| TC-P03 | Filter By Class | Select class → only logs from students in that class shown | — | — | ⬜ |
| TC-P04 | Filter By Section (After Class Selected) | Select section → only logs from students in that section shown | — | — | ⬜ |
| TC-P05 | Filter By Student (After Class+Section Selected) | Select student → only logs for that student shown | — | — | ⬜ |
| TC-P06 | Filter By Event Type | Select FOCUS_LOST → only FOCUS_LOST event type entries shown | — | — | ⬜ |
| TC-P07 | Filter By Date Range (Preset: Last 7 Days) | Select "Last 7 Days" → only logs from last 7 days shown | — | — | ⬜ |
| TC-P08 | Filter By Date Range (Custom Range) | Pick custom start/end dates → logs within that range shown | — | — | ⬜ |
| TC-P09 | Multi-Filter: Class + Event Type + Date Range | All three filters applied → only matching subset shown | — | — | ⬜ |
| TC-P10 | Clear Filters | Click Reset → all filters cleared, all logs shown | — | — | ⬜ |
| TC-P11 | Log Row Shows Student Name And Attempt ID | Student full_name shown as link, Attempt #X below | — | — | ⬜ |
| TC-P12 | Log Row Shows Exam/Paper Title | Paper title displayed (truncated), Paper ID below | — | — | ⬜ |
| TC-P13 | Log Row Shows Occurred At Timestamp | Date in bold "d M Y" format, time below "h:i:s A" | — | — | ⬜ |
| TC-P14 | Log Row Shows Event Type Badge | Pill badge with event type name, rounded with border | — | — | ⬜ |
| TC-P15 | Log Row Shows Event Details As Badges | Key-value pairs from event_data shown as styled badges (e.g., "Ip: 192.168.1.1") | — | — | ⬜ |
| TC-P16 | Log With Empty Event Data | Shows "System triggered event" italic text | — | — | ⬜ |
| TC-P17 | Multiple Details Badges For Rich Event Data | event_data with 3+ keys → all shown as individual badges | — | — | ⬜ |
| TC-P18 | Pagination Works (15 Per Page) | Page 2 shows next 15 records, prev/next links functional | — | — | ⬜ |
| TC-P19 | Pagination Preserves Filters | Filters persist in pagination URL params | — | — | ⬜ |
| TC-P20 | Pending Attempts Tab Loads | Tab shows filter form (class, section, student), table with 7 columns, pagination | — | — | ⬜ |
| TC-P21 | Pending Table Shows Correct Columns | #, Student, Exam/Paper, Last Saved, Status, Progress, Action | — | — | ⬜ |
| TC-P22 | Pending — Filter By Class | Select class → only checkpoints from that class shown | — | — | ⬜ |
| TC-P23 | Pending — Filter By Section | Select section → only checkpoints from that section shown | — | — | ⬜ |
| TC-P24 | Pending — Filter By Student | Select student → only checkpoints for that student shown | — | — | ⬜ |
| TC-P25 | Pending — All Checkpoints Show IN_PROGRESS Status | Status column always shows "IN_PROGRESS" badge | — | — | ⬜ |
| TC-P26 | Pending — Progress Display Shows Question Index | Current question number displayed (0-based + 1) | — | — | ⬜ |
| TC-P27 | Pending — Progress Shows Answered Count | "Answered: 5" displayed | — | — | ⬜ |
| TC-P28 | Pending — Progress Shows Flagged Count | "Flagged: 2" displayed | — | — | ⬜ |
| TC-P29 | Pending — Last Saved Timestamp | Date "d M Y" and time "h:i:s A" shown | — | — | ⬜ |
| TC-P30 | Pending — View Checkpoint Data Button | Clicking button shows JSON data (via alert or modal) | — | — | ⬜ |
| TC-P31 | Pending — Student Name Displayed | Student name linked, Attempt #X below | — | — | ⬜ |
| TC-P32 | Pending — Exam/Paper Title | Paper title, exam title below | — | — | ⬜ |
| TC-P33 | Pending — Pagination | Pagination footer with "Showing X to Y of Z" | — | — | ⬜ |
| TC-P34 | Switch Between Activity Log And Pending Tabs | Tab click switches content without page reload | — | — | ⬜ |
| TC-P35 | Date Range Picker Initializes On Tab Show | When activity_log tab becomes visible, date picker initializes | — | — | ⬜ |
| TC-P36 | Cascading Class→Section Dropdown For Activity Tab | Selecting class loads sections for that class | — | — | ⬜ |
| TC-P37 | Cascading Class→Section Dropdown For Pending Tab | Same cascade works in pending tab | — | — | ⬜ |
| TC-P38 | Cascading Section→Student Dropdown For Activity Tab | After section selected, students loaded via AJAX | — | — | ⬜ |
| TC-P39 | Cascading Section→Student Dropdown For Pending Tab | Students loaded for section in pending tab | — | — | ⬜ |
| TC-P40 | Log Row — Sequential Number Correct Across Pages | Page 1: #1-15, Page 2: #16-30 | — | — | ⬜ |
| TC-P41 | Log Row — Student Null Relation Fallback | If student relation null: "Student ID: {attempt_id}" shown | — | — | ⬜ |
| TC-P42 | Log Row — Paper Title Null Fallback | If examPaper null: "N/A" shown | — | — | ⬜ |
| TC-P43 | Log Row — Event Type Null Fallback | If eventType null: "Event #X" shown | — | — | ⬜ |
| TC-P44 | Pending — Student Null Relation Fallback | "Student #X" shown if student relation null | — | — | ⬜ |
| TC-P45 | Pending — Checkpoint With Answered Questions | JSON array of answered IDs properly counted | — | — | ⬜ |
| TC-P46 | Pending — Checkpoint With Flagged Questions | JSON array of flagged IDs properly counted | — | — | ⬜ |
| TC-P47 | Pending — Checkpoint With Both Answered And Flagged | Both counts displayed correctly | — | — | ⬜ |
| TC-P48 | Pending — Checkpoint At First Question (idx=0) | Question index shows "1" | — | — | ⬜ |
| TC-P49 | Pending — Checkpoint At Last Question | Index shows correct total question number | — | — | ⬜ |
| TC-P50 | Activity Logs In Reverse Chronological Order | Latest events at top |
| TC-P51 | Pending — Sequential Numbering | # shown as loop iteration |
| TC-P52 | Pending — Empty Checkpoint Data Action | Button still shows even if checkpoint_data null |
| TC-P53 | Activity Log — Multi-Month Date Range Filter | Date range spanning 2+ months returns correct data |
| TC-P54 | Activity Log — Today Filter | Only today's events |
| TC-P55 | Activity Log — Yesterday Filter | Only yesterday's events |
| TC-P56 | Activity Log — This Month Filter | All events from current month |
| TC-P57 | Activity Log — Last Month Filter | All events from previous month |
| TC-P58 | Pending — No Filters Shows All Active Attempts | All checkpoints across all classes/sections |
| TC-P59 | Activity Log — Rich event_data With Array Values | Array values in JSON displayed as JSON string in badge |
| TC-P60 | Activity Log — IP Address In event_data | "Ip: 192.168.1.1" badge visible |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Permission (tenant.exam.viewAny missing) | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest Access Redirect | Redirect to /login for activity log routes | — | — | ⬜ |
| TC-N03 | No Activity Logs Exist | Empty state: "No activity logs found." with icon | — | — | ⬜ |
| TC-N04 | No Pending Attempts Exist | Empty state: "No active/pending exam attempts found." | — | — | ⬜ |
| TC-N05 | Invalid Class ID In Filter | Class filter with non-existent ID → empty results | — | — | ⬜ |
| TC-N06 | Invalid Section ID In Filter | Section filter with non-existent ID → empty results | — | — | ⬜ |
| TC-N07 | Invalid Student ID In Filter | Student filter with non-existent ID → empty results | — | — | ⬜ |
| TC-N08 | Invalid Event Type ID In Filter | Event type filter with non-existent ID → empty results | — | — | ⬜ |
| TC-N09 | Date Range In Future | Future date range → empty results | — | — | ⬜ |
| TC-N10 | Date From After Date To | Invalid range → empty or handled gracefully | — | — | ⬜ |
| TC-N11 | Log Attempt Type Not EXAM | attempt_type=QUIZ or QUEST → may not appear in exam module logs | — | — | ⬜ |
| TC-N12 | Deleted Student Reference In Log | Student deleted → shows "Student ID: X" fallback | — | — | ⬜ |
| TC-N13 | Deleted Paper Reference In Log | Paper deleted → shows "N/A" fallback | — | — | ⬜ |
| TC-N14 | Deleted Event Type Reference | Event type deleted → shows "Event #X" fallback | — | — | ⬜ |
| TC-N15 | XSS In event_data Values | JSON values with script tags → escaped by Blade | — | — | ⬜ |
| TC-N16 | Very Large event_data Payload | 100+ key-value pairs → all displayed as badges (truncated if needed) | — | — | ⬜ |
| TC-N17 | Empty occurred_at Timestamp | If occurred_at is null → date display may error | — | — | ⬜ |
| TC-N18 | Invalid JSON In event_data | event_data stored as null or malformed → handled gracefully | — | — | ⬜ |
| TC-N19 | Checkpoint With Null Checkpoint Data | checkpoint_data = null → Action button shows null | — | — | ⬜ |
| TC-N20 | Both Tabs Simultaneous Empty | No activity logs AND no checkpoints → both tabs show empty state | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Activity Log Entries Created During Student Exam | During online exam, each proctoring event writes to lms_attempt_activity_logs | — | — | ⬜ |
| TC-D02 | B | Checkpoint Created During Active Exam | During exam, checkpoint saved at regular intervals to lms_attempt_checkpoints | — | — | ⬜ |
| TC-D03 | C | Checkpoint Deleted On Attempt Submission | When student submits, checkpoint record removed | — | — | ⬜ |
| TC-D04 | D | Activity Log — Polymorphic attempt_type=EXAM | Log created by Exam module uses attempt_type='EXAM' | — | — | ⬜ |
| TC-D05 | E | Activity Log — Immutable (No Udpate/Delete) | No UPDATE or DELETE operations on lms_attempt_activity_logs | — | — | ⬜ |
| TC-D06 | F | Multiple Event Types Available | lms_attempt_activity_event_types has all 9 standard types | — | — | ⬜ |
| TC-D07 | G | Class Cascade — Selecting Class Sets Section Dropdown | Class selection triggers AJAX to load sections | — | — | ⬜ |
| TC-D08 | H | Section Cascade — Selecting Section Sets Student Dropdown | Section selection triggers AJAX to load students | — | — | ⬜ |
| TC-D09 | I | Integration — P1 — AttemptActivityLog Model — belongsTo examAttempt | `$log->examAttempt` returns ExamAttempt model; relation defined via attempt_type + attempt_id polymorphic | — | — | ⬜ |
| TC-D10 | J | Integration — P1 — AttemptActivityLog Model — belongsTo eventType | `$log->eventType` returns AttemptActivityEventType; eager loading `AttemptActivityLog::with('eventType')` works | — | — | ⬜ |
| TC-D11 | K | Integration — P1 — AttemptCheckpoint Model — belongsTo examAttempt | `$cp->examAttempt` returns ExamAttempt; correct relation mapping | — | — | ⬜ |
| TC-D12 | L | Integration — P1 — Controller — masters() loads activity_log data conditionally | Only when active_tab=activity_log, the activity log query runs; not on other tabs | — | — | ⬜ |
| TC-D13 | M | Integration — P1 — Controller — masters() loads checkpoint data conditionally | Only when active_tab=event_log_pending, the checkpoint query runs | — | — | ⬜ |
| TC-D14 | N | Integration — P1 — Controller — Gate::authorize('tenant.exam.viewAny') on load | Access to activity log tab requires viewAny permission; 403 without | — | — | ⬜ |
| TC-D15 | O | Unit — P1 — AttemptActivityLog Model — $casts for event_data | `event_data` cast to array or JSON; accessing as array returns parsed data; null returns empty array | — | — | ⬜ |
| TC-D16 | P | Unit — P1 — AttemptCheckpoint Model — $casts for JSON fields | `answered_question_ids`, `flagged_question_ids`, `checkpoint_data` all cast to array/JSON; null returns empty array | — | — | ⬜ |
| TC-D17 | Q | Unit — P1 — AttemptActivityEventType Model — scopes | Standard model with code, name, description fields; scope for active types | — | — | ⬜ |
| TC-D18 | R | Integration — P1 — LmsExamController — activity_log query filters properly | Class → section → student cascade applied; date range WHERE between; event_type_id filter | — | — | ⬜ |
| TC-D19 | S | Integration — P1 — LmsExamController — event_log_pending query filters | Class → section → student cascade; order by saved_at desc; pagination | — | — | ⬜ |
| TC-D20 | T | DEV — P1 — Routes — AJAX endpoints for cascading dropdowns | `lms-exam.get-sections-by-class` (GET), `lms-exam.student-search` (GET); both return JSON with auth middleware | — | — | ⬜ |
| TC-D21 | U | DEV — P1 — Date picker auto-submit NOT triggered for activity log | User must click Filter button; date selection alone does not auto-submit | — | — | ⬜ |
| TC-D22 | V | DEV — P1 — Tab switching initializes daterangepicker | Switching to activity_log tab triggers daterangepicker initialization; no duplicate initializations | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade — isset()/null-safe Checks for Relationship Variables | All relationship access uses `$log->examAttempt?->student?->full_name` null-safe operator; no undefined property errors | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — Conditional Query Loading Based On active_tab | masters() checks `$request->get('active_tab')` before running activity log / checkpoint queries; queries NOT run when other tabs active | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — Date Range Picker Initialization on Tab Show | JS listens for `shown.bs.tab` event targetting `#activity_log-pane`; initLogDatePicker() called only on correct tab | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | View — Cascading Dropdown JS Functions | loadSections() and loadStudents() defined globally; used by both activity_log and event_log_pending tabs with different prefixes | — | — | ◌ |
| TC-CR05 | CR | Code Review | P2 | View — event_data Loop Escaping | Blade `{{ }}` auto-escapes key and value in foreach; no raw output | — | — | ◌ |
| TC-CR06 | CR | Code Review | P2 | Controller — Pagination Uses Custom Page Names | Activity log uses `log_page` page name; avoids conflict with other paginated elements on same screen | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open activity_log/index.blade.php | View file found |
| 2 | Scan for relationship access: `$log->examAttempt?->student?->full_name` | Null-safe operator used throughout |
| 3 | Scan for `$log->examAttempt?->examPaper?->title` | Null-safe chain used |
| 4 | Scan for `$log->eventType?->name` | Null-safe used |
| 5 | Open event_log.blade.php | View file found |
| 6 | Scan for `$cp->examAttempt?->student?->full_name` | Null-safe used |
| 7 | Scan for `$cp->examAttempt?->examPaper?->title` | Null-safe used |
| 8 | Create log with null relations | View renders with fallback values, no errors |

#### TC-CR02: Controller — Conditional Query Loading Based On active_tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller found |
| 2 | Inspect masters() method | Checks `$request->get('active_tab')` |
| 3 | When active_tab=activity_log | Activity log query runs, checkpoints query may not |
| 4 | When active_tab=event_log_pending | Checkpoints query runs, activity log query may not |
| 5 | When active_tab=dashboard | Neither query runs |
| 6 | DB query log verification | Only required queries executed per tab |

#### TC-CR03: View — Date Range Picker Initialization on Tab Show

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open activity_log/index.blade.php | JS for daterangepicker init found |
| 2 | Verify shown.bs.tab listener | `$('button[data-bs-toggle="tab"]').on('shown.bs.tab', ...)` |
| 3 | Verify target check | `if (target === '#activity_log-pane')` |
| 4 | Verify initLogDatePicker() called | Function initializes picker with presets |
| 5 | Switch to activity_log tab | Picker initializes on first show |
| 6 | Switch away and back | Picker not re-initialized (checks `!$el.data('daterangepicker')`) |

#### TC-CR04: View — Cascading Dropdown JS Functions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open activity_log/index.blade.php | loadSections() and loadStudents() defined |
| 2 | Verify loadSections() | Uses $.get to fetch sections, populates section dropdown |
| 3 | Verify loadStudents() | Uses $.get to student-search, populates student dropdown |
| 4 | Functions used by both tabs | activity_log tab uses prefix 'activity', event_log uses prefix 'event' |
| 5 | Verify duplicate init on page load | If class_id filter set, sections loaded on DOM ready |

#### TC-CR05: View — event_data Loop Escaping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php | Find foreach loop over event_data |
| 2 | Verify output uses `{{ }}` | Key and value wrapped in Blade echo: `{{ ucfirst(str_replace(...)) }}` and `{{ $val }}` |
| 3 | Create event_data with XSS value | Value displayed as escaped string, no script execution |

### 6.1 Positive TC Steps — Detailed

#### TC-P01: Activity Log Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to Exam Management → Activity Log tab | active_tab=activity_log |
| 3 | Check filter bar | Class dropdown, Section dropdown, Student dropdown, Event Type dropdown, Date Range picker |
| 4 | Check table headers | #, Student, Exam/Paper, Occurred At, Event Type, Details |
| 5 | Check pagination footer | If multiple pages, pagination links visible |
| 6 | Check tab navigation | "Activity Log" and "Pending Attempts" tabs visible |

#### TC-P02: Log Table Shows Correct Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create activity log entries | Entries exist |
| 2 | Load activity log tab | Table shows all columns: #, Student, Exam/Paper, Occurred At, Event Type, Details |
| 3 | Verify column headers | Matches expected 6 columns |

#### TC-P03: Filter By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create logs for students in Class A and Class B | Both classes have logs |
| 2 | Select Class A from dropdown | class_id set |
| 3 | Click Filter | Only Class A logs shown |
| 4 | Switch to Class B | Only Class B logs shown |

#### TC-P04: Filter By Section (After Class Selected)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class | Section dropdown loads via AJAX |
| 2 | Select a section | section_id set |
| 3 | Click Filter | Only logs from that section shown |
| 4 | Clear section | All sections for that class shown |

#### TC-P05: Filter By Student (After Class+Section Selected)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class+section | Student dropdown loads via AJAX (Select2) |
| 2 | Select specific student | student_id set |
| 3 | Click Filter | Only logs for that student shown |
| 4 | Clear student filter | All students for that class/section shown |

#### TC-P06: Filter By Event Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create logs with different event types | FOCUS_LOST, TAB_SWITCH, BROWSER_RESIZE |
| 2 | Select "Focus Lost" from Event Type | log_event_type = FOCUS_LOST id |
| 3 | Click Filter | Only FOCUS_LOST entries shown |
| 4 | Verify other types not shown | TAB_SWITCH, BROWSER_RESIZE hidden |

#### TC-P07: Filter By Date Range (Preset: Last 7 Days)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create logs: 2 today, 3 from 10 days ago | Mix of old and new |
| 2 | Open date range picker, select "Last 7 Days" | dates set to last 7 days |
| 3 | Click Filter | Only 2 today's logs shown |
| 4 | Older logs not shown | Hidden |

#### TC-P08: Filter By Date Range (Custom)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create logs on 3 dates: Jan 5, Jan 15, Jan 25 | 3 distinct dates |
| 2 | Pick custom range: Jan 10 - Jan 20 | Custom range set |
| 3 | Click Filter | Only Jan 15 log shown |

#### TC-P09: Multi-Filter: Class + Event Type + Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class filter + event type filter + date range | All 3 filters in URL |
| 2 | Click Filter | Only matching subset displayed |
| 3 | Verify URL params | class_id, log_event_type, date_from, date_to present |

#### TC-P10: Clear Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply multiple filters | URL has params |
| 2 | Click Reset (undo button) | URL clears, all filters reset |
| 3 | Verify all logs shown | No filter applied |

#### TC-P11: Log Row Shows Student Name And Attempt ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with student relation | Log exists |
| 2 | View log row | Student full name shown in bold blue text, "Attempt #X" below in gray |

#### TC-P12: Log Row Shows Exam/Paper Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with paper relation | Log exists |
| 2 | View log row | Paper title shown (truncated to 140px), "Paper ID: X" below |

#### TC-P13: Log Row Shows Occurred At Timestamp

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with occurred_at = 2025-06-15 14:30:00 | Log exists |
| 2 | View log row | Date: "15 Jun 2025" in bold, Time: "02:30:00 PM" below |

#### TC-P14: Log Row Shows Event Type Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with event_type = FOCUS_LOST | Log exists |
| 2 | View log row | Rounded pill badge "FOCUS_LOST" with primary color, border |

#### TC-P15: Log Row Shows Event Details As Badges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with event_data: {"ip":"192.168.1.1","fullscreen":false,"browser":"Chrome"} | Log exists |
| 2 | View log row | 3 badges: "Ip: 192.168.1.1", "Fullscreen: false", "Browser: Chrome" |
| 3 | Each badge: light bg, dark text, normal font weight, border, margin |

#### TC-P16: Log With Empty Event Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with event_data = null | Log exists |
| 2 | View log row | Shows "System triggered event" in italic gray text |

#### TC-P17: Multiple Details Badges For Rich Event Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with 5-key event_data | 5 key-value pairs |
| 2 | View log row | All 5 badges displayed in a row (wrap if needed) |

#### TC-P18: Pagination Works (15 Per Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 20 activity log entries | 20 records |
| 2 | Page 1: 15 entries | Shows 1-15 |
| 3 | Click page 2 | Shows 16-20 |
| 4 | Previous link works | Back to page 1 |

#### TC-P19: Pagination Preserves Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply event type filter | Filtered to 10 results |
| 2 | Click page 2 | URL preserves log_event_type param |
| 3 | Results still filtered | Same filter applied |

#### TC-P20: Pending Attempts Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Pending Attempts" tab | active_tab=event_log_pending |
| 2 | Check filter form | Class dropdown, Section dropdown, Student dropdown |
| 3 | Check table headers | #, Student, Exam/Paper, Last Saved, Status, Progress, Action |
| 4 | Check pagination | If multiple pages, footer shown |

#### TC-P21: Pending Table Shows Correct Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create checkpoint records | Records exist |
| 2 | Load pending tab | 7 columns: #, Student, Exam/Paper, Last Saved, Status, Progress, Action |
| 3 | Verify column headers | Exact match |

#### TC-P22 to TC-P24: Pending Tab Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class | Class filter applied |
| 2 | Select section (after class) | Section filter applied |
| 3 | Select student (after section) | Student filter applied |
| 4 | Clear filters | All checkpoints shown |

#### TC-P25: Pending — All Checkpoints Show IN_PROGRESS Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create checkpoint for active attempt | Attempt in progress |
| 2 | View pending tab row | Status column shows "IN_PROGRESS" info badge |
| 3 | Every pending row has same badge | Always IN_PROGRESS |

#### TC-P26 to TC-P29: Pending Progress Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Checkpoint with current_question_idx=4 | Question Index shows "5" (0-based + 1) |
| 2 | answered_question_ids = [1,2,3] | "Answered: 3" |
| 3 | flagged_question_ids = [2] | "Flagged: 1" |
| 4 | saved_at = 2025-06-15 14:30:00 | "15 Jun 2025" + "02:30:00 PM" |

#### TC-P30: Pending — View Checkpoint Data Button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View Checkpoint Data" button | alert() with JSON.stringify of checkpoint_data |
| 2 | If checkpoint_data has answers | All answer data visible in JSON |

#### TC-P31 to TC-P32: Pending Row Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student name displayed | "John Doe" in blue bold |
| 2 | Attempt #X below | "Attempt #42" in gray |
| 3 | Paper title | Paper title shown (truncated) |
| 4 | Exam title | Exam title below paper |

#### TC-P33: Pending Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25 checkpoints | 25 records |
| 2 | View pending tab | "Showing 1 to 15 of 25 entries" |
| 3 | Navigate pages | Previous/next functional |

#### TC-P34: Switch Between Activity Log And Pending Tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Activity Log" tab | activity_log-pane shows, event_log_pending-pane hides |
| 2 | Click "Pending Attempts" tab | event_log_pending-pane shows, activity_log-pane hides |
| 3 | Verify no page reload | Tab switch is client-side |

#### TC-P35: Date Range Picker Initializes On Tab Show

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Start on Pending tab | Date picker not initialized |
| 2 | Switch to Activity Log tab | shown.bs.tab fires, initLogDatePicker() runs |
| 3 | Verify picker visible | Input shows calendar icon, clickable |

#### TC-P36 to TC-P39: Cascading Dropdowns Detailed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Activity tab: select class | $.get loads sections for prefix='activity' |
| 2 | Activity tab: select section | $.get loads students for prefix='activity' |
| 3 | Pending tab: select class | $.get loads sections for prefix='event' |
| 4 | Pending tab: select section | $.get loads students for prefix='event' |
| 5 | Verify different prefixes | activity_section_id vs event_section_id |

#### TC-P40: Sequential Number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Page 1, first row | #1 |
| 2 | Page 1, last row | #15 |
| 3 | Page 2, first row | #16 |
| 4 | Formula: (page-1)*15 + iteration | Correct |

#### TC-P41 to TC-P43: Null Fallbacks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log with null student | "Student ID: {attempt_id}" |
| 2 | Log with null examPaper | "N/A" |
| 3 | Log with null eventType | "Event #X" |

#### TC-P44 to TC-P49: Pending Edge Cases

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Null student relation | "Student #X" shown |
| 2 | 0 answered questions | "Answered: 0" |
| 3 | 0 flagged questions | "Flagged: 0" |
| 4 | current_question_idx=0 | Index shows "1" |
| 5 | current_question_idx=49 | Index shows "50" |

#### TC-P50: Reverse Chronological Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 logs at different times | T1: 10:00, T2: 11:00, T3: 12:00 |
| 2 | Load activity log tab | Order: T3 (12:00), T2 (11:00), T1 (10:00) |
| 3 | Latest event first | Most recent at top |

### 6.2 Negative TC Steps — Detailed

#### TC-N01: No Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.exam.viewAny | Dashboard loads |
| 2 | Navigate to Exam Management → Activity Log | HTTP 403 Forbidden |

#### TC-N02: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Session ended |
| 2 | Navigate to exam master page with activity tab | Redirected to /login |

#### TC-N03: No Activity Logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no activity logs exist | Empty table |
| 2 | Load activity log tab | Shows icon + "No activity logs found." |
| 3 | Verify no 500 error | Graceful empty state |

#### TC-N04: No Pending Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no checkpoints exist | Empty table |
| 2 | Load pending tab | Shows icon + "No active/pending exam attempts found." |

#### TC-N05 to TC-N08: Invalid Filter IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_id=99999 | Empty results |
| 2 | Set section_id=99999 | Empty results |
| 3 | Set student_id=99999 | Empty results |
| 4 | Set log_event_type=99999 | Empty results |

#### TC-N09 to TC-N10: Invalid Date Ranges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Filter future dates | Empty results |
| 2 | Set date_from > date_to | Empty results (query returns nothing) |

#### TC-N11: Non-EXAM Attempt Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with attempt_type='QUIZ' | Not shown in exam module activity log (filtered by attempt_type) |

#### TC-N12 to TC-N14: Deleted References

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete student referenced in log | "Student ID: X" shown |
| 2 | Delete paper referenced in log | "N/A" shown |
| 3 | Delete event type referenced in log | "Event #X" shown |

#### TC-N15: XSS In event_data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with event_data = {"msg":"<script>alert('xss')</script>"} | Log exists |
| 2 | View log row | Badge shows escaped: "Msg: <script>alert('xss')</script>" |
| 3 | No script execution | Blade {{ }} auto-escapes |

#### TC-N16: Large event_data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with 100 event_data keys | Large JSON payload |
| 2 | View log row | All key-value pairs displayed as badges (may wrap) |
| 3 | Page renders without timeout | Badges rendered efficiently |

#### TC-N17 to TC-N19: Null Data States

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | occurred_at = null | May cause Carbon error |
| 2 | event_data = invalid JSON | Handled as null |
| 3 | checkpoint_data = null | Button shows "null" |

### 6.3 Dependency TC Steps — Detailed

#### TC-D01: Activity Log Created During Student Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student starts online exam | Attempt begins |
| 2 | Student switches browser tab | JS detects FOCUS_LOST event |
| 3 | Event written to lms_attempt_activity_logs | Log entry created with attempt_type='EXAM' |
| 4 | Student exits fullscreen | FULLSCREEN_EXIT event logged |
| 5 | Student copies text (Ctrl+C) | COPY_PASTE_DETECTED event logged |
| 6 | All events visible in admin Activity Log tab | All event types shown with timestamps |

#### TC-D02: Checkpoint Created During Active Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student starts exam | Exam in progress |
| 2 | Student answers Q1, Q2 | Checkpoint saved with answered_question_ids |
| 3 | Student flags Q3 | checkpoint.flagged_question_ids updated |
| 4 | View pending attempts tab | Checkpoint visible with progress |
| 5 | Verify saved_at timestamp | Recent timestamp |

#### TC-D03: Checkpoint Deleted On Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has active checkpoint | Checkpoint exists |
| 2 | Student submits exam | Application deletes checkpoint |
| 3 | Check pending attempts tab | Checkpoint no longer visible |
| 4 | DB check: lms_attempt_checkpoints | Record removed |

#### TC-D04: attempt_type='EXAM'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create activity log with attempt_type='EXAM' | Log exists |
| 2 | Create activity log with attempt_type='QUIZ' | Quiz log exists |
| 3 | Load exam module activity log | Only EXAM type shown (filtered) |

#### TC-D09: AttemptActivityLog Model — belongsTo examAttempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ActivityLog with attempt_id=42, attempt_type='EXAM' | Log exists |
| 2 | Access $log->examAttempt | Returns ExamAttempt model with id=42 |
| 3 | If attempt deleted | Returns null |
| 4 | Eager loading: AttemptActivityLog::with('examAttempt')->get() | 2 queries total |

#### TC-D10: AttemptActivityLog Model — belongsTo eventType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with event_type_id=1 | Log exists |
| 2 | Access $log->eventType | Returns AttemptActivityEventType |
| 3 | Access $log->eventType->name | "FOCUS_LOST" |
| 4 | If event type deleted | Returns null |

#### TC-D15: AttemptActivityLog $casts for event_data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create log with event_data = {"ip":"1.1.1.1"} | Stored as JSON |
| 2 | Access as array: $log->event_data['ip'] | Returns "1.1.1.1" |
| 3 | Iterate with foreach | Keys and values accessible |
| 4 | Null event_data | Returns empty array or null |

#### TC-D16: AttemptCheckpoint $casts for JSON Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | answered_question_ids = [1,2,3] | Cast to array: [1,2,3] |
| 2 | flagged_question_ids = [2] | Cast to array: [2] |
| 3 | count($cp->answered_question_ids) | 3 |
| 4 | Null fields return empty array | [] |

#### TC-D18: Activity Log Query Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | class_id filter applied | whereHas('examAttempt.student', ...) filters by class |
| 2 | section_id filter applied | Additional whereHas for section |
| 3 | log_event_type filter applied | where('event_type_id', $request->log_event_type) |
| 4 | date_from/date_to filter applied | whereBetween('occurred_at', [$from, $to]) |
| 5 | student_id filter applied | whereHas('examAttempt', fn) with student_id |

#### TC-D19: Checkpoint Query Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | class_id filter on checkpoints | Filters by student's class |
| 2 | section_id filter | Filters by student's section |
| 3 | student_id filter | Filters by specific student |
| 4 | Ordered by saved_at desc | Latest checkpoint first |

#### TC-D20: AJAX Endpoints for Cascading Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify route: GET lms-exam.get-sections-by-class | Returns JSON with `sections` array |
| 2 | Pass class_id=valid | Sections for that class returned |
| 3 | Pass class_id=0 or empty | Empty sections array |
| 4 | Verify route: GET lms-exam.student-search | Returns JSON array of students with id+text |
| 5 | Pass class_id + section_id | Filtered student list |
| 6 | Pass search param | Filtered by name search |
| 7 | Both routes have auth middleware | Protected from guest access |

#### TC-D21: Date Picker Does NOT Auto-Submit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open JS for activity log date picker | apply.daterangepicker handler sets hidden fields but does NOT submit form |
| 2 | Select "Last 7 Days" | Date inputs updated, page NOT submitted |
| 3 | Verify form NOT submitted | No network request |
| 4 | Click Filter button | Form submits with date params |

#### TC-D22: Tab Switching Initializes Date Picker

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On page load with activity_log tab NOT active | Date picker NOT initialized |
| 2 | Click Activity Log tab | shown.bs.tab event fires |
| 3 | initLogDatePicker() checks !$el.data('daterangepicker') | true → initializes |
| 4 | Switch away and back to tab | $el.data('daterangepicker') exists → skip re-init |
| 5 | Verify no duplicate instances | Only one date picker bound |

### 6.4 Additional Integration Test Steps

#### TC-AD-01: Many Event Types Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 1 log for each of the 9 event types | 9 logs with different types |
| 2 | Load activity log tab | All 9 shown with correct type badges |
| 3 | Event type dropdown filter shows all 9 | Each type selectable |

#### TC-AD-02: Filter By Event Type — Each Standard Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create logs: FOCUS_LOST, TAB_SWITCH, BROWSER_RESIZE, COPY_PASTE_DETECTED, CONTEXT_MENU_OPENED, DEVTOOLS_DETECTED, WINDOW_BLUR, NETWORK_DISCONNECT, FULLSCREEN_EXIT | One of each |
| 2 | Test each filter individually | Each returns exactly 1 log |

#### TC-AD-03: Pending — Student With No Checkpoint Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create checkpoint with null checkpoint_data | checkpoint_data = null |
| 2 | View pending tab | Action button visible |
| 3 | Click button | Shows alert with "null" or empty object |

#### TC-AD-04: Activity Log — All Event Types In Filter Dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load activity log tab | Event type dropdown has all event types |
| 2 | Verify "All Event Types" option | First option selected by default |
| 3 | Count options | Number matches event types count in DB |

#### TC-AD-05: Pending — Checkpoint For Exam With Many Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create checkpoint with current_question_idx=99 | Last of 100 questions |
| 2 | View pending tab | "Question Index: 100", "Answered: N" |

#### TC-AD-06: Pending — Checkpoint With Some Answered, Some Flagged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | answered_question_ids = [1,3,5,7] | 4 answered |
| 2 | flagged_question_ids = [2,4] | 2 flagged |
| 3 | Progress shows both | "Answered: 4 | Flagged: 2" |

#### TC-AD-07: Pending — Checkpoint With Overlapping Answered And Flagged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | answered_question_ids = [1,2,3] | Also in answered |
| 2 | flagged_question_ids = [2,5] | Q2 is both (possible) |
| 3 | Counts are independent | "Answered: 3 | Flagged: 2" |

#### TC-AD-08: Activity Log — Filter By Date + Event Reduces Results Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logs: FOCUS_LOST on day 1, TAB_SWITCH on day 2 | 2 logs |
| 2 | Filter: day 1 + FOCUS_LOST | 1 result |
| 3 | Filter: day 1 + TAB_SWITCH | 0 results |
| 4 | Filter: day 2 + TAB_SWITCH | 1 result |

#### TC-AD-09: Cascading — Class With No Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create class with no sections | Class exists without sections |
| 2 | Select this class in filter | AJAX returns empty sections array |
| 3 | Section dropdown shows "All Sections" only | No other options |

#### TC-AD-10: Cascading — Section With No Students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select section with no students | AJAX returns empty students array |
| 2 | Student dropdown shows "All Students" only | No other options |

#### TC-AD-11: Activity Log — Event Data With Nested JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | event_data = {"user_agent":{"browser":"Chrome","os":"Windows"},"ip":"1.1.1.1"} | Nested value |
| 2 | View in table | Nested JSON shown as JSON string or "[object Object]" based on implementation |

#### TC-AD-12: Activity Log — Event Data With Boolean Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | event_data = {"fullscreen":false,"copy":true} | Boolean values |
| 2 | Badges show | "Fullscreen: false", "Copy: true" |

#### TC-AD-13: Activity Log — Event Data With Numeric Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | event_data = {"tab_switches":3,"time_seconds":45} | Numeric values |
| 2 | Badges show | "Tab switches: 3", "Time seconds: 45" |

#### TC-AD-14: Activity Log — Event Data With Null Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | event_data = {"last_focus":null,"extra":null} | Null values |
| 2 | Badges show | "Last focus: ", "Extra: " (empty or null string) |

#### TC-AD-15: Pending — Last Saved At Midnight Boundary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | saved_at = 2025-06-15 00:00:00 | Midnight |
| 2 | Display | "15 Jun 2025" + "12:00:00 AM" |

#### TC-AD-16: Pending — Last Saved At Noon

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | saved_at = 2025-06-15 12:00:00 | Noon |
| 2 | Display | "15 Jun 2025" + "12:00:00 PM" |

#### TC-AD-17: Activity Log — Tab Switch Initialization On Direct URL Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate directly to URL with active_tab=activity_log | Tab pane visible on load |
| 2 | Check if date picker initialized | initLogDatePicker() called if pane visible |
| 3 | Verify picker functional | Click input → calendar shown |

#### TC-AD-18: Activity Log — Student Name Select2 Search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student dropdown has class 'select2-ajax' | Select2 initialized |
| 2 | Type partial student name | AJAX search returns matching students |
| 3 | Select a student | student_id set |
| 4 | Submit filter | Filtered by that student |

#### TC-AD-19: Activity Log — Event Type Dropdown Shows All Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load activity log tab | Event types from DB in dropdown |
| 2 | Types include: FOCUS_LOST, FULLSCREEN_EXIT, etc | All standard types |
| 3 | Each type has correct name | Display names match |

#### TC-AD-20: Pending — No Pagination When Under 15 Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 10 checkpoints | Under page size |
| 2 | Load pending tab | All 10 visible |
| 3 | Pagination footer hidden or shows single page | No pagination links |

#### TC-AD-21: Pending — Pagination With Exactly 15 Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 15 checkpoints | Exactly page size |
| 2 | Load pending tab | All 15 on 1 page |
| 3 | "Showing 1 to 15 of 15" | No page 2 link |

#### TC-AD-22: Activity Log — Filter Combination With Reset

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class + event type + date range | 3 filters active |
| 2 | Click reset | All filters cleared |
| 3 | URL returns to default | Only active_tab=activity_log |

#### TC-AD-23: Activity Log — Student Filter Without Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select student without selecting class first | Empty class → no sections → no student loading |
| 2 | Set student_id directly in URL | Logs filtered by student only |
| 3 | Verify cascade dependency | Class → Section → Student chain enforced |

#### TC-AD-24: Activity Log — Date Range Clear

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select date range | Dates filled |
| 2 | Open picker, click "Clear" | cancel.daterangepicker fires |
| 3 | Hidden date fields cleared | date_from, date_to = '' |
| 4 | Input text cleared | Placeholder shown |

#### TC-AD-25: Pending — Last Saved Sort Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 checkpoints: T1 (1 hour ago), T2 (30 min ago), T3 (5 min ago) | 3 records |
| 2 | Load pending tab | Order: T3, T2, T1 |
| 3 | Most recent checkpoint first | saved_at descending |

#### TC-AD-26: Activity Log — Event Details With Special Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | event_data = {"browser":"Chrome/120.0","os":"Windows 11 Pro"} | Special chars |
| 2 | Display in badges | Special characters rendered correctly |

#### TC-AD-27: Activity Log — No Date Filter Returns All

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear date_from and date_to | No date filtering |
| 2 | Load activity log tab | All logs across all dates shown |

#### TC-AD-28: Pending — Session Resumption Via Checkpoint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student pauses exam (browser crash) | Checkpoint saved |
| 2 | Student reopens exam | Application loads checkpoint data |
| 3 | Questions answered restored | Student resumes from current_question_idx |

#### TC-AD-29: Activity Log — IP Address Privacy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | event_data contains IP address | Displayed in badge |
| 2 | IP is visible to admin | "Ip: 192.168.x.x" |
| 3 | No masking applied | Full IP shown as stored |

#### TC-AD-30: Activity Log — Multiple Tabs/Windows Detection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student opens exam in 2 browser tabs | Tab switch events detected |
| 2 | Each tab switch logged | Multiple FOCUS_LOST / TAB_SWITCH events |
| 3 | Admin sees frequency of tab switches | Badges show count in details |


</parameter>
