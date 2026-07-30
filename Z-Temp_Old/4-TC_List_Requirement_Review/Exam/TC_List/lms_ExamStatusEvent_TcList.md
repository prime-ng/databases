# lms_ExamStatusEvent_TcList

## Module: LmsExam → Masters → Exam Status Event

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Masters (Exam Master) |
| Feature | Exam Status Event |
| URL(s) | `GET lms-exam.masters.index?active_tab=exam_status_event` (index), `GET lms-exam.exam-status-event.create` (create), `POST lms-exam.exam-status-event.store` (store), `GET lms-exam.exam-status-event.show/{id}` (show), `GET lms-exam.exam-status-event.edit/{id}` (edit), `PUT lms-exam.exam-status-event.update/{id}` (update), `DELETE lms-exam.exam-status-event.destroy/{id}` (destroy), `GET lms-exam.exam-status-event.trashed` (trash), `POST lms-exam.exam-status-event.restore/{id}` (restore), `DELETE lms-exam.exam-status-event.forceDelete/{id}` (forceDelete), `POST lms-exam.exam-status-event.toggle-status/{id}` (toggleStatus) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamStatusEventController` |
| Model(s) | `Modules\LmsExam\Models\ExamStatusEvent` |
| Validation (Create) | `Modules\LmsExam\Http\Requests\ExamStatusEventRequest` |
| Validation (Update) | `Modules\LmsExam\Http\Requests\ExamStatusEventRequest` (same class, ignores own id on code unique) |
| Permissions | `tenant.exam-status-event.viewAny`, `tenant.exam-status-event.view`, `tenant.exam-status-event.create`, `tenant.exam-status-event.update`, `tenant.exam-status-event.delete`, `tenant.exam-status-event.restore`, `tenant.exam-status-event.forceDelete`, `tenant.exam-status-event.status`, `tenant.exam-status-event.import`, `tenant.exam-status-event.export`, `tenant.exam-status-event.print` |
| Soft Deletes | Yes (`ExamStatusEvent` uses `SoftDeletes` trait; destroy() calls update(['is_active'=>false]) before delete()) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Event Types | ENUM: `EXAM`, `PAPER`, `RESULT`, `ATTEMPT` |
| Action Logic | JSON field storing name, code, event_type metadata |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam-status-event.viewAny`, `tenant.exam-status-event.view`, `tenant.exam-status-event.create`, `tenant.exam-status-event.update`, `tenant.exam-status-event.delete`, `tenant.exam-status-event.restore`, `tenant.exam-status-event.forceDelete`, `tenant.exam-status-event.status`
- Required seed data: At least one active exam status event record in `lms_exam_status_events` table
- Test user must have all above permissions (default admin user)
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For usage-block tests: At least one exam or exam paper referencing a status event via `status_id`
- Database tables: `lms_exam_status_events`, `lms_exams`, `lms_exam_papers` must exist

---

## 3. Default Data Load

When the page loads via Masters tab `?active_tab=exam_status_event`, index() builds query with filters:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Status Events Grid | queryBuilder() | ExamStatusEvent::query()->latest() | search(code,name,description,event_type); event_type filter; is_active filter | 10/page |

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('His') . random_int(100, 999)` for unique code/name
- **Code uniqueness**: `code` column has UNIQUE constraint `uq_exam_status_event_code`
- **Event type**: ENUM with 4 allowed values: EXAM, PAPER, RESULT, ATTEMPT
- **Action logic**: JSON field auto-populated with name/code/event_type on create and update
- **Pre-test cleanup**: Delete created records by unique code suffix
- **Usage check**: `ExamStatusEventUsageCheckService` checks exams + examPapers referencing status_id
- **Model-level protection**: `booted() -> deleting()` event blocks forceDelete if exams or examPapers exist
- **Boolean casting**: `is_active` stored as TINYINT(1), cast to boolean

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_status_events`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE (uq_exam_status_event_code) |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | event_type | ENUM('EXAM','PAPER','RESULT','ATTEMPT') | NOT NULL DEFAULT 'EXAM' |
| BC-DB-06 | action_logic | JSON | NOT NULL |
| BC-DB-07 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-08 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-09 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-10 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `ExamStatusEventRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:50, unique:lms_exam_status_events,code | "Status code is required" / "This status code already exists" |
| BC-VAL-02 | name | required, string, max:100 | "Status name is required" |
| BC-VAL-03 | description | nullable, string, max:255 | — |
| BC-VAL-04 | event_type | required, in:EXAM,PAPER,RESULT,ATTEMPT | "Event type is required" |
| BC-VAL-05 | action_logic | nullable, json | "Action logic must be valid JSON" |
| BC-VAL-06 | is_active | boolean | — |
| BC-VAL-07 | action_logic (prepare) | merged as json_encode([]) if not filled; else json_encode(action_logic) | — |
| BC-VAL-08 | is_active (prepare) | merged via `$this->boolean('is_active')` | — |

### 4.3 Validation Rules — `ExamStatusEventRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, max:50, unique + ignore current id | "This status code already exists" |
| BC-VAL-U02 | name | required, string, max:100 | "Status name is required" |
| BC-VAL-U03 | description | nullable, string, max:255 | — |
| BC-VAL-U04 | event_type | required, in:EXAM,PAPER,RESULT,ATTEMPT | "Event type is required" |
| BC-VAL-U05 | action_logic | nullable, json | "Action logic must be valid JSON" |
| BC-VAL-U06 | is_active | boolean | — |

### 4.4 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam-status-event.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.exam-status-event.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.exam-status-event.view | show() | Without → 403 |
| BC-AUTH-04 | tenant.exam-status-event.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.exam-status-event.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam-status-event.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.exam-status-event.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.exam-status-event.status | Status switch toggle | Without → toggle hidden |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create status event | $statusData['action_logic'] set to {name, code, event_type}; ExamStatusEvent::create(); activityLog('Stored') |
| BC-BIZ-02 | Update status event | Blocked if usageCheck->isUsed(); action_logic rebuilt with current name/code/event_type; getChanges() tracked; activityLog('Updated') |
| BC-BIZ-03 | Delete (soft) status event | Blocked if isUsed(); update is_active=false; then soft delete; activityLog('Trashed') |
| BC-BIZ-04 | Restore status event | Blocked if isUsed(); model->restore(); set is_active=true; activityLog('Restored') |
| BC-BIZ-05 | Force delete status event | Blocked if isUsed(); model-level deleting event also blocks if exams/examPapers exist; forceDelete(); activityLog('Deleted') |
| BC-BIZ-06 | Toggle status | AJAX endpoint; validates is_active required+boolean; DB transaction; activityLog('Toggled'); JSON response |
| BC-BIZ-07 | Model-level force-delete protection | booted() deleting() event throws Exception if exams() or examPapers() exists and isForceDeleting() |
| BC-BIZ-08 | Index query builder | Filters: event_type (exact match), search (code,name,description,event_type like), is_active (boolean) |
| BC-BIZ-09 | Show page with usage | Passes isUsed, usageDetails to view; displays usage warning if used |
| BC-BIZ-10 | Action logic auto-population | In store and update, action_logic = ['name' => $request->name, 'code' => $request->code, 'event_type' => $request->event_type] |
| BC-BIZ-11 | Trash view | ExamStatusEvent::onlyTrashed()->paginate(10) |
| BC-BIZ-12 | Transaction rollback | All write operations wrapped in DB::beginTransaction/commit/rollback |
| BC-BIZ-13 | Activity logging on exception | On exception, rollback + redirect back with error; no partial log entry |
| BC-BIZ-14 | Event_type enum validation | Only EXAM, PAPER, RESULT, ATTEMPT allowed; ENUM DB constraint enforces |
| BC-BIZ-15 | Show view | Uses ExamStatusEvent::with(['exams'])->findOrFail($id) |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | status_id (lms_exams) | lms_exam_status_events (id) | RESTRICT (via fk_exam_status) |
| BC-REF-02 | status_id (lms_exam_papers) | lms_exam_status_events (id) | RESTRICT (via fk_paper_status) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Status Events Tab Loads With All UI Elements | Tab loads with search bar, event_type filter, is_active filter, table with Code/Name/Event Type/Description/Active/Action columns | — | — | ⬜ |
| TC-P02 | Search Status Events By Code | Table filters to show only matching status by code | — | — | ⬜ |
| TC-P03 | Search Status Events By Name | Table filters to show only matching status by name | — | — | ⬜ |
| TC-P04 | Search Status Events By Event Type Text | Table filters to show matching status by event_type text | — | — | ⬜ |
| TC-P05 | Filter Status Events By Event Type EXAM | Selecting EXAM type shows only EXAM status events | — | — | ⬜ |
| TC-P06 | Filter Status Events By Event Type PAPER | Selecting PAPER type shows only PAPER status events | — | — | ⬜ |
| TC-P07 | Filter Status Events By Event Type RESULT | Selecting RESULT type shows only RESULT status events | — | — | ⬜ |
| TC-P08 | Filter Status Events By Event Type ATTEMPT | Selecting ATTEMPT type shows only ATTEMPT status events | — | — | ⬜ |
| TC-P09 | Filter Status Events By Active Status | Selecting Active shows only active; Inactive shows only inactive | — | — | ⬜ |
| TC-P10 | Create Status Event With Code Name And Event Type EXAM | Status event created with code, name, event_type='EXAM', action_logic auto-populated | — | — | ⬜ |
| TC-P11 | Create Status Event With Event Type PAPER | Status event created with event_type='PAPER' | — | — | ⬜ |
| TC-P12 | Create Status Event With Event Type RESULT | Status event created with event_type='RESULT' | — | — | ⬜ |
| TC-P13 | Create Status Event With Event Type ATTEMPT | Status event created with event_type='ATTEMPT' | — | — | ⬜ |
| TC-P14 | Create Status Event With Optional Description | Status event created with description saved correctly | — | — | ⬜ |
| TC-P15 | Create Status Event With Inactive Status | Status event created with is_active=false | — | — | ⬜ |
| TC-P16 | Edit Status Event Loads Pre-Filled Data | Edit form shows existing data with all fields pre-filled | — | — | ⬜ |
| TC-P17 | Update Status Event Code And Name | Code and name updated; action_logic auto-regenerated | — | — | ⬜ |
| TC-P18 | Update Status Event Event Type | event_type changed; action_logic updated accordingly | — | — | ⬜ |
| TC-P19 | Update Status Event Description | Description updated | — | — | ⬜ |
| TC-P20 | View Status Event Details Page | Detail page shows code, name, description, event_type badge, action_logic, is_active, timestamps | — | — | ⬜ |
| TC-P21 | View Status Event Usage Details (When Used) | Show page displays warning alert with usage details | — | — | ⬜ |
| TC-P22 | Toggle Status Event Status (Active to Inactive) via AJAX | Status switch toggles is_active; JSON response | — | — | ⬜ |
| TC-P23 | Toggle Status Event Status (Inactive to Active) via AJAX | Status switch toggles is_active back to true | — | — | ⬜ |
| TC-P24 | Soft Delete Status Event (Not Used) | Status event moved to trash; is_active=false; activity Trashed | — | — | ⬜ |
| TC-P25 | View Trashed Status Events | Trash page lists soft-deleted status events with action buttons | — | — | ⬜ |
| TC-P26 | Restore Soft-Deleted Status Event | Status event restored; is_active=true; activity Restored | — | — | ⬜ |
| TC-P27 | Force Delete Status Event (Not Used, No References) | Status event permanently removed; activity Deleted | — | — | ⬜ |
| TC-P28 | Full Lifecycle: Create → View → Toggle → Edit → Delete → Restore → Force Delete | All transitions succeed | — | — | ⬜ |
| TC-P29 | Empty State — No Status Events | Table shows "No status events found" | — | — | ⬜ |
| TC-P30 | Action Logic JSON Auto-Populated On Create | action_logic contains name/code/event_type as JSON | — | — | ⬜ |
| TC-P31 | Action Logic JSON Updated On Edit | action_logic reflects updated name/code/event_type | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `code` | Validation error: "Status code is required" | — | — | ⬜ |
| TC-N02 | Required — Missing `name` | Validation error: "Status name is required" | — | — | ⬜ |
| TC-N03 | Required — Missing `event_type` | Validation error: "Event type is required" | — | — | ⬜ |
| TC-N04 | Invalid `event_type` — Not In Enum | Validation error: event_type must be EXAM/PAPER/RESULT/ATTEMPT | — | — | ⬜ |
| TC-N05 | Duplicate `code` | Validation error: "This status code already exists" | — | — | ⬜ |
| TC-N06 | Max Length — Code > 50 Characters | Validation fails on code.max | — | — | ⬜ |
| TC-N07 | Max Length — Name > 100 Characters | Validation fails on name.max | — | — | ⬜ |
| TC-N08 | Max Length — Description > 255 Characters | Validation fails on description.max | — | — | ⬜ |
| TC-N09 | Invalid JSON For action_logic | Validation error: "Action logic must be valid JSON" | — | — | ⬜ |
| TC-N10 | Edit Blocked When Status Event Is Used In Exams | Edit redirects back with error: "Cannot edit this status because it is being used in exams or exam papers." | — | — | ⬜ |
| TC-N11 | Update Blocked When Status Event Is Used | Update redirects back with same error | — | — | ⬜ |
| TC-N12 | Delete Blocked When Status Event Is Used | Destroy redirects back with error | — | — | ⬜ |
| TC-N13 | Restore Blocked When Status Event Is Used | Restore redirects back with error | — | — | ⬜ |
| TC-N14 | Force Delete Blocked When Status Event Is Used (Service Check) | ForceDelete redirects back with error | — | — | ⬜ |
| TC-N15 | Force Delete Blocked By Model-Level Protection | Model booted() deleting() throws Exception if exams/examPapers exist | — | — | ⬜ |
| TC-N16 | View Status Event With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N17 | Edit/Update/Delete/Restore/ForceDelete With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N18 | Toggle Status Without is_active Parameter | Validation error: "The is active field is required." | — | — | ⬜ |
| TC-N19 | Toggle Status With Non-Boolean is_active | Validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N20 | Permission 403 — No Status Event Permissions | 403 on all endpoints | — | — | ⬜ |
| TC-N21 | Guest Access Redirect | Redirect to /login | — | — | ⬜ |
| TC-N22 | XSS Injection In Code/Name/Description | Stored securely; Blade escapes | — | — | ⬜ |
| TC-N23 | Whitespace-Only Code | Required validation catches | — | — | ⬜ |
| TC-N24 | Duplicate Code At DB Level | Integrity constraint violation | — | — | ⬜ |
| TC-N25 | Restore Non-Trashed Record | 404 from onlyTrashed() | — | — | ⬜ |
| TC-N26 | Toggle With Invalid ID | JSON 500 error | — | — | ⬜ |
| TC-N27 | DB Error During Create — Transaction Rollback | Rollback, no partial record | — | — | ⬜ |
| TC-N28 | DB Error During Update — Transaction Rollback | Rollback, original data preserved | — | — | ⬜ |
| TC-N29 | Invalid event_type At DB Level | ENUM constraint violation | — | — | ⬜ |
| TC-N30 | Event Type Mismatch — EXAM Status Applied To Paper | Business logic allows; but usage is context-dependent | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Status Event → Activity Logged 'Stored' | activity_logs has entry with event 'Stored' | — | — | ⬜ |
| TC-D02 | B | Update Status Event → Changes Tracked In Activity Log | Activity log has changes JSON diff | — | — | ⬜ |
| TC-D03 | C | Soft Delete → Is_Active Set False Before Delete | DB shows is_active=0 AND deleted_at IS NOT NULL | — | — | ⬜ |
| TC-D04 | D | Restore → Is_Active Set True | DB shows is_active=1 AND deleted_at IS NULL | — | — | ⬜ |
| TC-D05 | E | Usage Check Blocks Edit/Delete/Restore/ForceDelete | All protected by ExamStatusEventUsageCheckService | — | — | ⬜ |
| TC-D06 | F | Model-Level ForceDelete Protection | deleting() event blocks forceDelete if exams/examPapers exist | — | — | ⬜ |
| TC-D07 | G | Action Logic Auto-Populated On Create And Update | JSON stored contains name/code/event_type | — | — | ⬜ |
| TC-D08 | H | Index Query Builder — All Filters | event_type, search, is_active filters work | — | — | ⬜ |
| TC-D09 | I | ExamStatusEventPolicy — All Gates Coverage | Policy defines 11 gates: viewAny, view, create, update, delete, restore, forceDelete, status, import, export, print | — | — | ⬜ |
| TC-D10 | J | ExamStatusEventRequest — authorize() Matches HTTP Method | POST→create, PUT/PATCH→update, DELETE→delete, GET→view | — | — | ⬜ |
| TC-D11 | K | SoftDeletes Trait — onlyTrashed/withTrashed Methods | onlyTrashed returns deleted; withTrashed returns all | — | — | ⬜ |
| TC-D12 | L | Model — $casts Boolean And Array | is_active as boolean; action_logic as array | — | — | ⬜ |
| TC-D13 | M | Model — hasMany Exams Relationship | $status->exams returns related Exam records | — | — | ⬜ |
| TC-D14 | N | Model — hasMany ExamPapers Relationship | $status->examPapers returns related ExamPaper records | — | — | ⬜ |
| TC-D15 | O | Model — scopeActive And scopeByEventType | active() where is_active=1; byEventType($type) where event_type=$type | — | — | ⬜ |
| TC-D16 | P | Controller — findOrFail With Valid/Invalid IDs | Valid → model loaded; Invalid → HTTP 404 | — | — | ⬜ |
| TC-D17 | Q | Controller — Gate::authorize Before All Actions | All 11 methods call Gate::authorize | — | — | ⬜ |
| TC-D18 | R | Controller — activityLog After CRUD | Each write operation logs appropriate event | — | — | ⬜ |
| TC-D19 | S | Controller — DB Transactions | All write ops wrapped in beginTransaction/commit/rollback | — | — | ⬜ |
| TC-D20 | T | Routes — Resourceful + Custom | All routes map correctly with auth middleware | — | — | ⬜ |
| TC-D21 | U | Blade @can Directives — Permission Visibility | Status toggle and action buttons wrapped with @can | — | — | ⬜ |
| TC-D22 | V | View — Event Type Badge Color Coding | EXAM→primary, PAPER→info, RESULT→success, ATTEMPT→warning | — | — | ⬜ |
| TC-D23 | W | View — isset()/null-safe Checks | ?? and null-safe operators used; no undefined errors | — | — | ⬜ |
| TC-D24 | X | Controller — Redirect/JSON Responses | All actions return redirect with flash or JSON | — | — | ⬜ |
| TC-D25 | Y | ENUM DB Constraint For event_type | INSERT with invalid value throws DB error | — | — | ⬜ |
| TC-D26 | Z | Unique Code Constraint At DB Level | Duplicate code INSERT throws integrity constraint violation | — | — | ⬜ |
| TC-D27 | AA | Cascade RESTRICT — Cannot Delete Status When Used By Exams | FK constraint blocks; controller blocks first | — | — | ⬜ |
| TC-D28 | AB | prepareForValidation — is_active Boolean Conversion | Checkbox→true/false conversion works | — | — | ⬜ |
| TC-D29 | AC | prepareForValidation — action_logic JSON Encoding | Null/empty→empty JSON array; filled→JSON encoded | — | — | ⬜ |
| TC-D30 | AD | ToggleStatus Returns 500 On Exception | Catch returns JSON error with 500 status | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.exam-status-event.status'), @canany(['tenant.exam-status-event.view', 'update', 'delete']), @canany(['restore', 'forceDelete']) | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered | Breadcrumb config has entry for status event routes | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions in All Write Operations | store/update/destroy/restore/forceDelete/toggleStatus use DB::transaction | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Null coalescing and null-safe operators used throughout | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Response After CRUD | Redirect with flash or JSON response | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Model-Level ForceDelete Protection In booted() | deleting() event blocks hard deletes when referenced | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Action Logic Auto-Population In Controller | store() and update() set action_logic before create/update | — | — | ◌ |

---

## 7. Detailed Test Steps

### 6.1 Positive TC Steps

#### TC-P01: Status Events Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Exam" from left sidebar | Menu options appear |
| 3 | Click "Masters" and select "Exam Status Events" tab | Page loads with `active_tab=exam_status_event` |
| 4 | Check search input | Placeholder "Search code, name..." |
| 5 | Check event_type filter dropdown | All Types, Exam, Paper, Result, Attempt options |
| 6 | Check is_active filter dropdown | All Status, Active, Inactive |
| 7 | Check table headers | Code, Name, Event Type, Description, Active, Action |

---

#### TC-P02 to TC-P04: Search By Code/Name/Event Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create status events: "DRAFT", "PUBLISHED", "CONCLUDED" | 3 records exist |
| 2 | Search "DRAFT" | Only DRAFT shown |
| 3 | Search "Draft" (case-insensitive) | DRAFT shown (LIKE query) |
| 4 | Clear search | All 3 shown |

---

#### TC-P05 to TC-P08: Filter By Event Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create EXAM status "DRAFT", PAPER status "IN_PROGRESS", RESULT status "EVALUATED", ATTEMPT status "ATTEMPTED" | 4 records with different event_types |
| 2 | Select "EXAM" from event_type filter | Only DRAFT shown |
| 3 | Select "PAPER" | Only IN_PROGRESS shown |
| 4 | Select "RESULT" | Only EVALUATED shown |
| 5 | Select "ATTEMPT" | Only ATTEMPTED shown |

---

#### TC-P09: Filter By Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active + inactive records | Both exist |
| 2 | Filter "Active" | Only active shown |
| 3 | Filter "Inactive" | Only inactive shown |

---

#### TC-P10: Create Status Event With Event Type EXAM

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Masters → Status Events tab | Page loads |
| 2 | Click "Add Status Event" | Create form opens |
| 3 | Enter code: "DRAFT" | Code filled |
| 4 | Enter name: "Draft" | Name filled |
| 5 | Select event_type: "EXAM" | Event type selected |
| 6 | Ensure is_active checked | Toggle ON |
| 7 | Click "Create Status Event" | POST to store |
| 8 | Redirect to masters tab with success | Flash: "Status event created successfully" |
| 9 | DB check: code='DRAFT', event_type='EXAM' | Record exists |
| 10 | DB check: action_logic JSON | Contains {name:"Draft", code:"DRAFT", event_type:"EXAM"} |

---

#### TC-P11 to TC-P13: Create With Different Event Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with event_type='PAPER', code='IN_PROGRESS' | event_type='PAPER' saved |
| 2 | Create with event_type='RESULT', code='EVALUATED' | event_type='RESULT' saved |
| 3 | Create with event_type='ATTEMPT', code='STARTED' | event_type='ATTEMPT' saved |

---

#### TC-P14: Create With Optional Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill required: code="PUBLISHED", name="Published", event_type="EXAM" | Required fields set |
| 3 | Enter description: "Exam has been published and is visible to students" | Description filled |
| 4 | Submit | Created with description saved |

---

#### TC-P15: Create With Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with is_active unchecked | is_active=0 |

---

#### TC-P16: Edit Status Event Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create status event with all fields | Record exists with ID=X |
| 2 | Click "Edit" | Edit form at /exam-status-event/{id}/edit |
| 3 | Verify code, name, event_type, description, is_active pre-filled | All match original values |

---

#### TC-P17: Update Code And Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create status event code="OLD", name="Old" | Record exists |
| 2 | Edit: change code to "NEW", name to "New" | Fields updated |
| 3 | Submit | Update succeeds |
| 4 | DB check: code="NEW", name="New" | Updated |
| 5 | DB check: action_logic | Updated JSON with new name/code |

---

#### TC-P18: Update Event Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create status event with event_type='EXAM' | Record exists |
| 2 | Edit: change to 'PAPER' | Event type changed |
| 3 | Submit | Update succeeds |
| 4 | DB check: event_type='PAPER' | Updated |
| 5 | DB check: action_logic | Has event_type:"PAPER" |

---

#### TC-P19: Update Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with null description | Description is NULL |
| 2 | Edit: set description to "Updated desc" | Updated |
| 3 | DB check: description | "Updated desc" |

---

#### TC-P20: View Status Event Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create status event with all fields | Record exists |
| 2 | Click "View" | Detail page at /exam-status-event/{id} |
| 3 | Check code displayed | Code shown |
| 4 | Check name displayed | Name shown |
| 5 | Check event_type badge | Color-coded badge |
| 6 | Check action_logic | JSON displayed or "No action logic configured" |
| 7 | Check is_active badge | Active/Inactive badge |
| 8 | Check timestamps | Created_at, updated_at |

---

#### TC-P21: View With Usage Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create status event, assign to exam via status_id | Used |
| 2 | Navigate to show page | Detail page with warning alert |
| 3 | Check "Usage Details" section | Shows where used and counts |

---

#### TC-P22: Toggle Active to Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active status event | is_active=1 |
| 2 | Click status switch OFF | AJAX POST to toggle-status |
| 3 | JSON response | {success: true, is_active: false} |
| 4 | DB check | is_active=0 |

---

#### TC-P23: Toggle Inactive to Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inactive status event | is_active=0 |
| 2 | Click status switch ON | AJAX POST |
| 3 | JSON: is_active=true | is_active=1 |

---

#### TC-P24: Soft Delete (Not Used)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create unused status event | Clean record |
| 2 | Click "Delete" | DELETE to destroy |
| 3 | Redirect with success | Flash: "Status event trashed successfully" |
| 4 | DB: is_active=0, deleted_at NOT NULL | Soft deleted |
| 5 | Activity log: 'Trashed' | Logged |

---

#### TC-P25: View Trashed Status Events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a status event | Soft deleted |
| 2 | Navigate to trash | /exam-status-event/trashed |
| 3 | Check table | Shows deleted record with Inactive badge |
| 4 | Check actions | Restore and Force Delete buttons |

---

#### TC-P26: Restore Soft-Deleted Status Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure soft-deleted record | deleted_at IS NOT NULL |
| 2 | Click "Restore" | POST to restore |
| 3 | Redirect with success | Flash: "Status event restored successfully" |
| 4 | DB: is_active=1, deleted_at=NULL | Restored |

---

#### TC-P27: Force Delete (Not Used, No References)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure soft-deleted, unused record | No exams referencing |
| 2 | Click "Force Delete" | DELETE to forceDelete |
| 3 | Redirect with success | Flash: "Status event permanently deleted" |
| 4 | DB: record gone | Permanently removed |

---

#### TC-P28: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "LIFECYCLE-TEST" | Created |
| 2 | View details | All fields shown |
| 3 | Toggle inactive | is_active=0 |
| 4 | Toggle active | is_active=1 |
| 5 | Edit name to "Lifecycle Updated" | Updated |
| 6 | Soft delete | Trashed |
| 7 | Restore | Restored |
| 8 | Soft delete again | Trashed |
| 9 | Force delete | Permanently removed |

---

#### TC-P29: Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No records in table | Clean state |
| 2 | Load tab | Shows "No status events found" |
| 3 | Create button still visible | If permission allows |

---

#### TC-P30: Action Logic Auto-Populated On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create status event | action_logic populated |
| 2 | Query action_logic | JSON with name, code, event_type keys |

---

#### TC-P31: Action Logic Updated On Edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit name/code/event_type | action_logic regenerated |
| 2 | Query action_logic | Reflects new values |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Leave code blank; fill other required fields | Code empty |
| 3 | Submit | Validation error: "Status code is required" |

---

#### TC-N02: Required — Missing `name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name blank | Validation error: "Status name is required" |

---

#### TC-N03: Required — Missing `event_type`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave event_type unselected | Validation error: "Event type is required" |

---

#### TC-N04: Invalid `event_type`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send event_type="INVALID" | Validation fails (not in EXAM/PAPER/RESULT/ATTEMPT) |

---

#### TC-N05: Duplicate `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with code="DUP" | First record |
| 2 | Create another with same code | "This status code already exists" |

---

#### TC-N06 to TC-N08: Max Length Violations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code 51 chars | Validation fails |
| 2 | Enter name 101 chars | Validation fails |
| 3 | Enter description 256 chars | Validation fails |

---

#### TC-N09: Invalid JSON For action_logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send action_logic as malformed string | "Action logic must be valid JSON" |

---

#### TC-N10 to TC-N14: Usage Check Blocks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam/examPaper referencing status | isUsed=true |
| 2 | Try edit/update/destroy/restore/forceDelete | All return error: "Cannot ... because it is being used in exams or exam papers." |

---

#### TC-N15: Model-Level ForceDelete Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam referencing status | relation exists |
| 2 | Try forceDelete | Exception thrown by booted() deleting() event |

---

#### TC-N16 to TC-N17: Invalid ID 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access show/edit/update/destroy/restore/forceDelete with ID 99999 | HTTP 404 |

---

#### TC-N18 to TC-N19: Toggle Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle without is_active param | "The is active field is required" |
| 2 | Toggle with non-boolean | "must be true or false" |

---

#### TC-N20: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any exam-status-event permissions | 403 on all endpoints |

---

#### TC-N21: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, access any route | Redirect to /login |

---

#### TC-N22: XSS Injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store <script>alert('xss')</script> in name | Stored as literal; Blade escapes |

---

#### TC-N23: Whitespace-Only Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit code as whitespace | Required validation catches |

---

#### TC-N24: DB-Level Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | INSERT directly with duplicate code | Integrity constraint violation |

---

#### TC-N25: Restore Non-Trashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST restore on active record | 404 (onlyTrashed needs deleted_at) |

---

#### TC-N26: Toggle With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status with ID=99999 | JSON 500 error |

---

#### TC-N27: DB Error During Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force DB failure during store | Transaction rollback; redirect back with error |

---

#### TC-N28: DB Error During Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force DB failure during update | Rollback; original data preserved |

---

#### TC-N29: Invalid event_type At DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | INSERT directly with event_type='INVALID' | ENUM constraint violation |

---

#### TC-N30: Event Type Applied To Incorrect Context

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create EXAM status, assign to exam paper | Technically allowed by FK but model-level logic may handle |

---

### 6.3 Dependency TC Steps

#### TC-D01: Create → Activity Logged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create status event | store() succeeds |
| 2 | Query activity_logs | 'Stored' event, message 'A new exam status event was created.' |

---

#### TC-D02: Update → Changes Logged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update name from "Old" to "New" | update() succeeds |
| 2 | Query activity_logs | 'Updated' event with changes JSON |

---

#### TC-D03: Soft Delete → Is_Active False

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete | destroy() succeeds |
| 2 | Query with trashed | is_active=0, deleted_at NOT NULL |

---

#### TC-D04: Restore → Is_Active True

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore | restore() succeeds |
| 2 | Query | is_active=1, deleted_at=NULL |

---

#### TC-D05: Usage Check Protects All Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit when used | Blocked |
| 2 | Update when used | Blocked |
| 3 | Delete when used | Blocked |
| 4 | Restore when used | Blocked |
| 5 | ForceDelete when used | Blocked |

---

#### TC-D06: Model-Level ForceDelete Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamStatusEvent.php | Find booted() method |
| 2 | Inspect deleting() closure | Checks isForceDeleting(); throws Exception if exams() or examPapers() exist |
| 3 | Create exam referencing status | Relation exists |
| 4 | Try forceDelete at controller level | Model throws Exception; controller catch returns error |

---

#### TC-D07: Action Logic Auto-Populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with code="DRAFT", name="Draft", event_type="EXAM" | action_logic={name:"Draft", code:"DRAFT", event_type:"EXAM"} |
| 2 | Update code="PUBLISHED", name="Published" | action_logic updated to {name:"Published", code:"PUBLISHED", event_type:"EXAM"} |

---

#### TC-D08: All Index Filters Work

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Filter event_type=EXAM | WHERE event_type='EXAM' applied |
| 2 | Search="DRAFT" | WHERE code LIKE '%DRAFT%' OR name LIKE ... |
| 3 | Filter is_active=1 | WHERE is_active=1 |

---

#### TC-D09: ExamStatusEventPolicy — All Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamStatusEventPolicy.php | 11 gates defined |
| 2 | Verify each gate | Returns $user->can('tenant.exam-status-event.*') |

---

#### TC-D10: Request authorize() Per HTTP Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST → create gate | allowIf: tenant.exam-status-event.create |
| 2 | PUT/PATCH → update gate | allowIf: tenant.exam-status-event.update |
| 3 | DELETE → delete gate | allowIf: tenant.exam-status-event.delete |
| 4 | GET → view gate (fallback) | allowIf: tenant.exam-status-event.view |

---

#### TC-D11: SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | onlyTrashed() | Only soft-deleted records |
| 2 | withTrashed() | All records including deleted |

---

#### TC-D12: Model $casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access is_active | Returns boolean |
| 2 | Access action_logic | Returns array (from JSON cast) |

---

#### TC-D13 to TC-D15: Relationships and Scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $status->exams | Returns HasMany Exam |
| 2 | $status->examPapers | Returns HasMany ExamPaper |
| 3 | ExamStatusEvent::active() | Where is_active=1 |
| 4 | ExamStatusEvent::byEventType('EXAM') | Where event_type='EXAM' |

---

#### TC-D16 to TC-D19: Controller Patterns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | findOrFail valid ID | Model found |
| 2 | findOrFail invalid ID | 404 |
| 3 | Gate::authorize called | Before each action |
| 4 | activityLog called | After each write |
| 5 | DB::transaction wraps writes | All CRUD writes |

---

#### TC-D20: Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check route:list | All routes present with correct controller methods |

---

#### TC-D21: Blade @can

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index status column | @canany(['tenant.exam-status-event.status']) |
| 2 | Index action column | @canany(['view', 'update', 'delete']) |

---

#### TC-D22: Event Type Badge Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | EXAM badge | bg-primary |
| 2 | PAPER badge | bg-info |
| 3 | RESULT badge | bg-success |
| 4 | ATTEMPT badge | bg-warning |

---

#### TC-D23: Null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check view files | Uses ?? and -> null-safe operators |

---

#### TC-D24: Response Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create/update/delete/restore/forceDelete | Redirect with flash message |
| 2 | Toggle status | JSON response |

---

#### TC-D25: ENUM DB Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DB INSERT with event_type='INVALID' | Column constraint violation |

---

#### TC-D26: Unique Code At DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DB INSERT with duplicate code | Duplicate entry violation |

---

#### TC-D27: Cascade RESTRICT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam references status via status_id | RESTRICT FK prevents deletion |
| 2 | Controller blocks before DB reaches error | User-friendly message |

---

#### TC-D28: prepareForValidation is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Checkbox checked → boolean(true) | is_active=true in validated data |
| 2 | Checkbox unchecked → boolean(false) | is_active=false |

---

#### TC-D29: prepareForValidation action_logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No action_logic provided | Sets to json_encode([]) |
| 2 | action_logic provided as array | JSON encoded |

---

#### TC-D30: ToggleStatus Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force exception | Catch returns JSON with 500 status |

---

### 6.4 Code Review TC Steps

#### TC-CR01: Blade @can Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | @canany status and action columns present |
| 2 | Inspect trash.blade.php | @canany for restore/forceDelete |
| 3 | User with all permissions | All buttons visible |
| 4 | User with viewAny only | No action buttons |

#### TC-CR02: Breadcrumb

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check config/breadcrumb.php | Routes registered |

#### TC-CR04: DB Transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store/update/destroy/restore/forceDelete/toggleStatus | All use DB::beginTransaction + commit/rollback |

#### TC-CR05: Null-safe View Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scan view files | All expressions use ?? or ->nullsafe |

#### TC-CR06: Response After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create/update/delete/restore/forceDelete | Redirect with flash |
| 2 | Toggle | JSON response |

#### TC-CR07: Model-Level ForceDelete Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model booted() | Static deleting() method |
| 2 | Verify logic | if(!isForceDeleting()) return; checks exams/examPapers; throws Exception |

#### TC-CR08: Action Logic Auto-Population

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | Sets $statusData['action_logic'] before create |
| 2 | Inspect update() | Sets $statusData['action_logic'] before update |
| 3 | Verify format | ['name'=>$name, 'code'=>$code, 'event_type'=>$event_type] |