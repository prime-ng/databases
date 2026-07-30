# lms_quiz_activity_log_TcList

## Module: LmsQuiz → Quiz Management → Activity Log

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management |
| Feature | Activity Log |
| URL(s) | `/lms-quize/quize` (tab: activity_log) |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizController@index()` (inline query within tab view) |
| Model(s) | `AttemptActivityLog` (from `Modules\StudentPortal\Models`) — NOT generic `ActivityLog` |
| Validation | Filter parameters only |
| Permissions | `tenant.quiz.viewAny` (shared with main index page — no separate activity log permission) |
| Soft Deletes | N/A (activity log records are not soft-deleted) |
| Activity Log | N/A (this IS the activity log viewer) |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz.viewAny` (shared with entire Quiz Management tab view)
- Activity log entries must exist in `attempt_activity_logs` table with `attempt_type = 'QUIZ'`
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Activity Log | `AttemptActivityLog::with('eventType')` | `->where('attempt_type', 'QUIZ')->latest('occurred_at')` | `log_event_type` (event_type_id FK), `date_from`, `date_to` (occurred_at) | 15 per page (log_page) |
| Event Types | `AttemptActivityEventType::active()` | All active event types | None | None |
| Related Models | `StudentPortal\Models\AttemptActivityLog` | Uses `eventType` relationship | — | — |

---

## 4. Test Data Strategy

- **Seed Log Data**: Generate activity log entries via student quiz attempts (start, submit, timeout, evaluate)
- **Event Type Filtering**: Test filter by `log_event_type` (maps to `event_type_id` FK from `AttemptActivityEventType`)
- **Date Range**: Test filtering by `date_from` and `date_to` (filter on `occurred_at` column)
- **Detail View**: Verify that each row shows description, event type name, and timestamp
- **Empty State**: Test when no activity logs exist for QUIZ attempt type

---

## 5. Business Conditions

### 5.1 Database Schema

Table: `attempt_activity_logs` (from Modules\StudentPortal)

| Column | Type | Notes |
|--------|------|-------|
| id | bigint unsigned | PK |
| attempt_id | bigint unsigned | FK to quiz_quest_attempts |
| attempt_type | varchar(255) | 'QUIZ' or 'QUEST' |
| event_type_id | bigint unsigned | FK to attempt_activity_event_types |
| description | text | Activity description text |
| occurred_at | datetime | When the activity occurred |
| created_at | timestamp | |
| updated_at | timestamp | |

Table: `attempt_activity_event_types`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint unsigned | PK |
| name | varchar(255) | Event type name (e.g., 'Attempt Started', 'Submitted') |
| is_active | tinyint(1) | |

### 5.2 Validation Rules

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | log_event_type | nullable, integer, exists:attempt_activity_event_types,id | Filter on event_type_id |
| BC-VAL-02 | date_from | nullable, date | Filter on occurred_at >= date_from |
| BC-VAL-03 | date_to | nullable, date | Filter on occurred_at <= date_to |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Behavior Without |
|-------|-----------|-----------------|
| BC-AUTH-01 | tenant.quiz.viewAny | Entire tab view returns 403 (no separate activity log permission) |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Activity log loads — default state | Chronological list of all `AttemptActivityLog` entries with `attempt_type='QUIZ'` |
| BC-BIZ-02 | Filter by event type | Only shows logs matching selected `event_type_id` |
| BC-BIZ-03 | Filter by date range | Only shows logs with `occurred_at` within range |
| BC-BIZ-04 | Combined filters | AND logic: event type + date range |
| BC-BIZ-05 | No activity data | Shows "No activity recorded yet" or empty table |
| BC-BIZ-06 | View log row | Shows description, event type name, timestamp per row |
| BC-BIZ-07 | Event types dropdown populated | Dropdown lists all active `AttemptActivityEventType` entries |

### 5.5 Referential Integrity

`attempt_activity_logs.event_type_id` → `attempt_activity_event_types.id` (FK, no cascade — event types are reference data)
`attempt_activity_logs.attempt_id` → `quiz_quest_attempts.id` (implicit FK)

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | View Activity Log — All Entries | Chronological list of all QUIZ attempt activity entries | — | — | ⬜ |
| TC-P02 | View Activity Log — Each Row Shows | Description, event type name, timestamp visible per row | — | — | ⬜ |
| TC-P03 | Filter by Event Type | Only logs with selected event_type_id shown | — | — | ⬜ |
| TC-P04 | Filter by Date Range (from only) | Only logs with occurred_at >= date_from shown | — | — | ⬜ |
| TC-P05 | Filter by Date Range (to only) | Only logs with occurred_at <= date_to shown | — | — | ⬜ |
| TC-P06 | Filter by Date Range (both) | Only logs within range shown | — | — | ⬜ |
| TC-P07 | Combined Filters (event type + date) | Both filters applied with AND logic | — | — | ⬜ |
| TC-P08 | Event Type Dropdown Populated | Dropdown shows all active event types from DB | — | — | ⬜ |
| TC-P09 | Reset Filters/Default Load | Full list shown when no filters applied | — | — | ⬜ |
| TC-P10 | Pagination | Page 2 shows next set of 15 results | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Activity Exists | Empty state: "No activity recorded yet" or empty table | — | — | ⬜ |
| TC-N02 | Invalid Event Type ID | Filter ignored (no matching logs shown) | — | — | ⬜ |
| TC-N03 | Invalid Date Range | Date filter silently ignored or defaults applied | — | — | ⬜ |
| TC-N04 | View Without Permission (tenant.quiz.viewAny) | 403 Forbidden | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Attempt → Activity Log | P1 | Student starts quiz attempt → activity log entry created | New `attempt_activity_logs` row with `attempt_type='QUIZ'` and appropriate event_type_id | — | — | ⬜ |
| TC-D02 | B | Attempt → Activity Log | P1 | Student submits quiz attempt → activity log entry created | Activity log row with submit event type and description | — | — | ⬜ |
| TC-D03 | C | Attempt → Activity Log | P1 | Quiz auto-timeout → activity log entry created | Activity log row with timeout event type | — | — | ⬜ |
| TC-D04 | D | Filter → Accuracy | P1 | Select event type → count matches DB query | Number of displayed rows matches query with that event_type_id | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — index — activity_log filter scope | Query uses `AttemptActivityLog::where('attempt_type', 'QUIZ')` with optional `where('event_type_id', $request->log_event_type)` | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — index — pagination | Uses `paginate(15, ['*'], 'log_page')` | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — index — date range filters | Uses `whereBetween('occurred_at', [...])` with Carbon::parse for date filtering | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — index — event types dropdown | Loads `AttemptActivityEventType::active()->get()` for filter dropdown | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: View Activity Log — All Entries

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, navigate to LmsQuiz → Activity Log tab | Page loads with activity_log tab active |
| 2 | Check filter bar | Event Type dropdown + Date Range pickers visible |
| 3 | Check table columns | Description, Event Type, Timestamp columns present |
| 4 | Verify rows show QUIZ attempt activities | Each row has description, event type name, occurred_at timestamp |
| 5 | Check pagination (if 15+ logs exist) | Page 2 link visible |

#### TC-P03: Filter by Event Type

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select an event type from filter dropdown | Dropdown value changes |
| 2 | Wait for auto-refresh or click Filter | Table reloads with only matching event_type_id rows |

---

#### TC-P04: Filter by Date From

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set date_from to a specific date | Date picker filled |
| 2 | Apply filter | Only logs with occurred_at >= date_from shown |

---

#### TC-P05: Filter by Date To

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set date_to to a specific date | Date picker filled |
| 2 | Apply filter | Only logs with occurred_at <= date_to shown |

---

#### TC-P06: Filter by Date Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set both date_from and date_to | Both filled |
| 2 | Apply filter | Only logs within range shown |

---

#### TC-P07: Combined Filters

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select event type + set date range | Both filters applied |
| 2 | Verify AND logic | Rows match BOTH event type AND date range |

---

#### TC-P09: Reset Filters

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click Reset/Clear filters | All filters cleared; full list restored |

---

#### TC-P10: Pagination

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure 16+ activity logs exist | Data available |
| 2 | Navigate to activity log tab | Page 1 shows first 15 logs |
| 3 | Click page 2 | Remaining logs displayed |

### 7.2 Negative TC Steps

#### TC-N01: No Activity Exists

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure no QUIZ attempt activity logs exist | Delete or use fresh tenant |
| 2 | Navigate to Activity Log tab | Empty state: "No activity recorded yet" or empty table |

#### TC-N04: View Without Permission

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as user without `tenant.quiz.viewAny` | User authenticated |
| 2 | Navigate to LmsQuiz module | 403 Forbidden |

### 7.3 Dependency TC Steps

#### TC-D01: Attempt → Activity Log

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create quiz allocation, allocate to a student | Allocation ready |
| 2 | Student starts quiz attempt | Attempt initiated |
| 3 | Navigate to Activity Log tab | New entry with event_type = "Attempt Started", attempt_type = "QUIZ" |

#### TC-D02: Submit → Activity Log

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student submits a quiz attempt | Attempt submitted |
| 2 | Navigate to Activity Log tab | Entry with submit event type and description |

#### TC-D04: Filter Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count logs for a specific event_type_id via DB | Known count X |
| 2 | Select that event type in filter | Table shows exactly X rows |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | No entity/subject_type filter — only filters by fixed `attempt_type='QUIZ'` | Cannot filter by specific quiz entity; shows ALL quiz attempt activity | Confirmed (by design) |
| KI-02 | No causer (user) filter — only event type and date range | Cannot filter activity by who performed the action | Confirmed (by design) |
| KI-03 | No log detail/drill-down view — all info shown in table row | Cannot view old/new values or properties of the activity | Observed (blade inline) |
| KI-04 | Permission shared with `tenant.quiz.viewAny` — no granular control | Any user with quiz list access sees activity log tab | Observed |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quize` (active_tab=activity_log) | `lms-quize.quize.index` | `LmsQuizController@index` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 22 | 10 | 4 | 4 | 4 | 0 | 0 | 0 | 0 |
