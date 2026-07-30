# slb_lesson_sequencing_TcList

## Module: Syllabus → Planning → Lesson Sequencing

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Planning |
| Feature | Lesson Sequencing |
| URL(s) | `GET /syllabus/planning?tab=lesson_sequencing` (display), `POST /syllabus/planning/save-sequencing` (save), `POST /syllabus/planning/auto-schedule` (auto-schedule), `POST /syllabus/planning/{id}/toggle-lock` (toggle lock), `POST /syllabus/planning/save-scheduling` (save scheduling) |
| Controller | `Modules\Syllabus\Http\Controllers\SyllabusController@planning()` (tab render), `SyllabusController@saveSequencing()` (save), `SyllabusController@buildSequencingFromCrud()` (first-time build), `SyllabusController@filterRowsByLevel()` (depth filter) |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` (table: `slb_syllabus_schedule`), `Modules\Syllabus\Models\Lesson`, `Modules\Syllabus\Models\Topic` |
| Validation | Inline `$request->validate()` in `saveSequencing()` — no dedicated FormRequest |
| Permissions | `Gate::authorize('tenant.lesson.update')` (save), `tenant.lesson.viewAny` (view) |
| Default Depth | Read from `SchConfig` key `syllabus_teaching_estimation_level_for_lesson_planning` |
| Pagination | 50 rows per page using `seq_page` parameter |
| Default Limits | daily_limit=10, weekly_limit=99 (when no PeriodsAllocation records) |

---

## 2. Pre-conditions

- Required permissions: `tenant.lesson.viewAny` (view), `tenant.lesson.update` (save)
- Required seed data: `Lesson` and `Topic` master records with hierarchy (Topic → Sub-Topic → Mini-Topic)
- `TopicLevelType` records with appropriate level names
- At least one `OrganizationAcademicSession`, `SchoolClass` with section, `Subject`
- `SchConfig` with key `syllabus_teaching_estimation_level_for_lesson_planning` (optional — defaults apply)
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

---

## 3. Default Data Load

When the page loads via SyllabusController@planning() (GET /syllabus/planning) with tab=lesson_sequencing, default filters are applied: class_section_id=1, subject_id=5, academic_session_id=7.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Classes | planning() | SchoolClass::where(is_active,1)->orderBy(ordinal) | is_active=1 | None |
| Shared: Sections | planning() | Section::where(is_active,1)->orderBy(name) | is_active=1 | None |
| Shared: Class-Sections | planning() | ClassSection::active()->with(class,section)->orderBy(ordinal) | active=1 | None |
| Shared: Subjects | planning() | Subject::where(is_active,1)->orderBy(name) | is_active=1 | None |
| Shared: Academic Sessions | planning() | OrganizationAcademicSession::orderBy(name) | None | None |
| Shared: Topic Level Types | planning() | TopicLevelType::where(is_active,1)->orderBy(level) | is_active=1 | None |
| Sequencing Grid | planning() | SyllabusSchedule::with(lesson,topic,topicLevelType,topic.parent+parent.parent) OR buildSequencingFromCrud() | class_id, subject_id, section_id, academic_session_id | 50/page (seq_page) |
| Period Limits | planning() | PeriodsAllocation::selectRaw(MAX(tot_periods_in_day), MAX(tot_periods_in_week)) | class_id, subject_id, section_id, academic_session_id | None (single row) |
| Duration Level | planning() | SchConfig::whereIn(key) → syllabus_teaching_estimation_level_for_lesson_planning | 4 config keys | None |
## 4. Test Data Strategy

- **Lesson/Topic hierarchy**: Create lessons with topics at multiple levels (root, sub, mini) for hierarchy walk tests
- **Duration minutes**: Set `duration_minutes` on topics to test roll-up calculation in `buildSequencingFromCrud()`
- **Unique suffix**: `now()->format('His') . random_int(100, 999)` where needed
- **Schedule records**: Pre-create via factory or via saveSequencing flow
- **Pre-test cleanup**: Delete created schedule records after tests
- **Depth filter levels**: Test with each of the 4 estimation levels (lesson, topic, sub_topic, mini_topic)
- **Period limits**: Create `PeriodsAllocation` records with known tot_periods_in_day and tot_periods_in_week values
- **Class teacher**: Set up ClassSection mapping for auto-assignment tests

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_syllabus_schedule`

(Same DDL as Lesson Date Planning — see `csm_SlbLessonDatePlanningTcList.md` section 4.1)

### 4.2 Validation Rules — `saveSequencing()` Inline

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | rows | required, array | "The rows field is required." |
| BC-VAL-02 | rows.*.lesson_id | required, integer, exists:slb_lessons,id | "Invalid row data. Please refresh and try again." |
| BC-VAL-03 | rows.*.topic_id | required, integer, exists:slb_topics,id | "Invalid row data. Please refresh and try again." |
| BC-VAL-04 | rows.*.ordinal | required, integer, min:1 | "Invalid row data. Please refresh and try again." |
| BC-VAL-05 | rows.*.priority | required, string, in:HIGH,MEDIUM,LOW | "The rows.0.priority must be one of HIGH, MEDIUM, LOW." |
| BC-VAL-06 | rows.*.is_active | required, boolean | — |
| BC-VAL-07 | rows.*.planned_periods | nullable, numeric, min:0, max:100 | "The rows.0.planned_periods must be a number." |
| BC-VAL-08 | rows.*.schedule_id | nullable, integer | If present → UPDATE; if absent → INSERT |

### 4.3 Daily/Weekly Limit Validation

| BC ID | Check | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | Daily limit per row | planned_periods > COALESCE(MAX(tot_periods_in_day), 10) | "Planned periods (X) exceeds the daily allocation limit (Y)..." |
| BC-VAL-U02 | Weekly limit total | SUM(planned_periods) > COALESCE(MAX(tot_periods_in_week), 99) | "Total planned periods (X) exceeds the weekly allocation limit (Y)..." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lesson.viewAny | planning() tab render | Without → 403 |
| BC-AUTH-02 | tenant.lesson.update | saveSequencing() | Without → 403 |
| BC-AUTH-03 | Guest access | Any sequencing route | Redirect to /login |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | No schedule records exist | `buildSequencingFromCrud()` walks Lesson → Topic → Sub-Topic → Mini-Topic hierarchy |
| BC-BIZ-02 | Schedule records exist | Load from SyllabusSchedule with relations, ordered by ordinal, id |
| BC-BIZ-03 | Depth filter = "topic" | Show only root-level topics (hide Sub/Mini/Micro/Nano) |
| BC-BIZ-04 | Depth filter = "sub_topic" | Show rows where level is Sub (hide Mini/Micro/Nano) |
| BC-BIZ-05 | Depth filter = "mini_topic" | Show rows where level is Mini (hide Micro/Nano) |
| BC-BIZ-06 | Depth filter = "nano_topic" | Show all rows (no filtering) |
| BC-BIZ-07 | Period roll-up from duration_minutes | Root topic gets sum of sub-children durations; sub gets sum of mini durations; mini uses own duration |
| BC-BIZ-08 | Daily limit exceeded | Reject save with 500 error |
| BC-BIZ-09 | Weekly limit exceeded | Reject save with 500 error |
| BC-BIZ-10 | Class teacher auto-assignment | If section has class_teacher_id, resolve via fallback chain and set assigned_teacher_id |
| BC-BIZ-11 | Schedule_id exists → UPDATE | Existing record updated with new ordinal, periods, priority, status |
| BC-BIZ-12 | Schedule_id empty → INSERT | New SyllabusSchedule record created |
| BC-BIZ-13 | Transactional save | All rows in single DB::transaction(); rollback on failure |
| BC-BIZ-14 | Pagination | 50 rows per page using `seq_page` parameter via LengthAwarePaginator |
| BC-BIZ-15 | Default depth level | If no SchConfig, defaults handled by reading normalized snake_case value |
| BC-BIZ-16 | Default daily limit | 10 (when PeriodsAllocation has no records) |
| BC-BIZ-17 | Default weekly limit | 99 (when PeriodsAllocation has no records) |
| BC-BIZ-18 | Screen loads via SyllabusController@planning() at GET /syllabus/planning with tab=lesson_sequencing | Navigating to GET /syllabus/planning with tab=lesson_sequencing loads this screen's grid data with correct filters applied |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt | CASCADE |
| BC-REF-02 | class_id | sch_classes | CASCADE |
| BC-REF-03 | section_id | sch_sections | CASCADE |
| BC-REF-04 | subject_id | sch_subjects | CASCADE |
| BC-REF-05 | lesson_id | slb_lessons | Not declared |
| BC-REF-06 | topic_id | slb_topics | CASCADE |
| BC-REF-07 | topic_level_type_id | slb_topic_level_types | Not declared |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Lesson Sequencing Tab Loads With Filter | Tab opens with class/section/subject filter, Apply button | — | — | ⬜ |
| TC-P02 | First-Time Load — Builds From CRUD (No Schedule Records) | buildSequencingFromCrud() walks Lesson→Topic hierarchy and displays rows | — | — | ⬜ |
| TC-P03 | Existing Schedule Records Loaded | Schedule records exist → table loads with saved ordinals, periods, priorities | — | — | ⬜ |
| TC-P04 | Depth Filter = "topic" Shows Only Root Topics | Only root-level topic rows visible; deeper levels hidden | — | — | ⬜ |
| TC-P05 | Depth Filter = "sub_topic" Shows Sub-Topic Level | Sub-topic rows visible; mini/micro/nano hidden | — | — | ⬜ |
| TC-P06 | Depth Filter = "mini_topic" Shows Mini-Topic Level | Mini-topic rows visible; micro/nano hidden | — | — | ⬜ |
| TC-P07 | Period Roll-Up From duration_minutes | Root topic periods = sum of child durations; sub-topic periods = sum of mini durations | — | — | ⬜ |
| TC-P08 | Save Sequencing — All Rows Valid | Save succeeds; rows with schedule_id updated, rows without inserted | — | — | ⬜ |
| TC-P09 | Save Sequencing — Existing Row Updated | Change ordinal, periods, priority on existing schedule_id → UPDATE | — | — | ⬜ |
| TC-P10 | Save Sequencing — New Row Inserted | Row without schedule_id → INSERT new record | — | — | ⬜ |
| TC-P11 | Save Sequencing — Class Teacher Auto-Assigned | ClassSection has class_teacher → all rows get assigned_teacher_id | — | — | ⬜ |
| TC-P12 | Save Sequencing — No Class Teacher | ClassSection has no class_teacher → assigned_teacher_id remains null | — | — | ⬜ |
| TC-P13 | Drag Reorder Updates Ordinals | Drag row to new position → ordinals renumber client-side | — | — | ⬜ |
| TC-P14 | Pagination — 50 Rows Per Page | Load 51+ rows → 50 on page 1, remaining on page 2 with seq_page=2 | — | — | ⬜ |
| TC-P15 | Save Sequencing Transaction Success | 30 rows saved in single transaction → all committed | — | — | ⬜ |
| TC-P16 | Priority Dropdown Options | Each row has HIGH, MEDIUM, LOW dropdown options | — | — | ⬜ |
| TC-P17 | Status Toggle (Active/Inactive) | Toggle is_active per row; inactive rows excluded from downstream | — | — | ⬜ |
| TC-P18 | Running Total Banner At Bottom | Banner shows sum of all planned_periods | — | — | ⬜ |
| TC-P19 | Daily Limit Check Pass | All rows planned_periods <= daily_limit → save proceeds | — | — | ⬜ |
| TC-P20 | Weekly Limit Check Pass | SUM(planned_periods) <= weekly_limit → save proceeds | — | — | ⬜ |
| TC-P21 | Filter Rows By Class + Subject Change | Change filter → table reloads with new data | — | — | ⬜ |
| TC-P22 | Default Depth When Config Not Set | No SchConfig → system uses default depth level | — | — | ⬜ |
| TC-P23 | Auto-Save On Page Change | Change page → unsaved changes auto-saved via AJAX before navigating | — | — | ⬜ |
| TC-P28 | Depth filter = nano_topic — all rows visible | Set depth config to nano_topic → grid shows all rows including Nano level; no rows hidden | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Save Without Permission | User without tenant.lesson.update → HTTP 403 | — | — | ⬜ |
| TC-N02 | Row Missing Required lesson_id | Omit lesson_id → HTTP 500: "Invalid row data" | — | — | ⬜ |
| TC-N03 | Row Missing Required topic_id | Omit topic_id → HTTP 500 | — | — | ⬜ |
| TC-N04 | Row Missing Required ordinal | Omit ordinal → HTTP 500 | — | — | ⬜ |
| TC-N05 | Invalid Ordinal — 0 Or Negative | Ordinal = 0 → HTTP 500 (min:1) | — | — | ⬜ |
| TC-N06 | Invalid Priority Value | Priority = "URGENT" → HTTP 500: must be HIGH/MEDIUM/LOW | — | — | ⬜ |
| TC-N07 | Single Row Exceeds Daily Limit | planned_periods=15, daily_limit=10 → HTTP 500 | — | — | ⬜ |
| TC-N08 | Total Exceeds Weekly Limit | SUM(periods)=120, weekly_limit=99 → HTTP 500 | — | — | ⬜ |
| TC-N09 | Invalid planned_periods Format | planned_periods="abc" → HTTP 500: must be number | — | — | ⬜ |
| TC-N10 | Guest Access Redirect | Not logged in → redirect to /login | — | — | ⬜ |
| TC-N11 | View Without Permission | No tenant.lesson.viewAny → HTTP 403 | — | — | ⬜ |
| TC-N12 | Empty Rows Array | POST {"rows":[]} → validation error | — | — | ⬜ |
| TC-N13 | planned_periods Negative | planned_periods=-5 → validation error (min:0) | — | — | ⬜ |
| TC-N14 | planned_periods > 100 | planned_periods=150 → validation error (max:100) | — | — | ⬜ |
| TC-N15 | DB Transaction Rollback | FK violation on 15th row → all 30 rows rolled back | — | — | ⬜ |
| TC-N16 | XSS In Row Name | Script tag stored as literal; Blade escapes output | — | — | ⬜ |
| TC-N17 | Default filter values not applied on load | Load tab without filter params → defaults to class_section_id=1, subject_id=5, academic_session_id=7 | — | — | ⬜ |
| TC-N18 | is_active required boolean validation — missing field | Submit row without is_active → validation error | — | — | ⬜ |
| TC-N19 | is_active required boolean validation — non-boolean value | Submit row with is_active="yes" → validation error | — | — | ⬜ |
| TC-N20 | schedule_id nullable integer validation — invalid type | Submit row with schedule_id="abc" → validation error | — | — | ⬜ |
| TC-N21 | Period roll-up zero → manual entry needed | All child topics have duration_minutes=null → planned_periods=0; teacher must enter manually | — | — | ⬜ |
| TC-N22 | Level mismatch after depth config change | Change depth from sub_topic to topic → previously visible sub-rows hidden; existing releases unaffected | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Sequencing → Scheduling data flow | After sequencing save, scheduling tab shows all sequences | — | — | ⬜ |
| TC-D02 | B | Settings Depth Change — Reload Shows Different Rows | Change estimation level from topic→sub_topic → sequencing shows more rows | — | — | ⬜ |
| TC-D03 | C | PeriodsAllocation Limits Used For Validation | Create allocation with max=3 → daily limit becomes 3 | — | — | ⬜ |
| TC-D04 | D | Class Teacher Chain — user_id Resolution | class_teacher_id matches user_id of Employee → auto-assigned | — | — | ⬜ |
| TC-D05 | E | Class Teacher Chain — Employee::find() | class_teacher_id matches employee id directly → auto-assigned | — | — | ⬜ |
| TC-D06 | F | Default Limits When No Allocation Records | No PeriodsAllocation → daily=10, weekly=99 defaults apply | — | — | ⬜ |
| TC-D07 | G | Delete Lesson → Sequencing Cascade | Soft-delete lesson → sequencing rows for that lesson cascaded | — | — | ⬜ |
| TC-D08 | H | Page Change Auto-Save Preserves Data | Edit row, change page → auto-save fires; return to page — edits persisted | — | — | ⬜ |
| TC-D09 | J | Save sequencing with invalid priority value — Priority ENUM Validation (`in:HIGH,MEDIUM,LOW`) | Submitting priority "URGENT" returns 500 validation error; HIGH/MEDIUM/LOW accepted | — | — | ⬜ |
| TC-D10 | K | Save sequencing with planned_periods > 100 — Planned Periods Max (max:100 rule) | Submitting planned_periods=150 returns 500 validation error | — | — | ⬜ |
| TC-D11 | L | Auto-schedule calculates dates using ppd from PeriodsAllocation — Auto Schedule (`autoSchedule()`) | Submitting rows to auto-schedule with ppd=2 returns calculated start/end dates spanning correct days | — | — | ⬜ |
| TC-D12 | M | Auto-schedule skips locked schedules — Locked Schedule Bypass (`is_locked=true`) | Locked schedules retain their existing dates; unlocked schedules get new calculated dates | — | — | ⬜ |
| TC-D13 | N | Toggle lock flips is_locked — Lock Toggle (`toggleLock()`) | Calling POST /syllabus/planning/{id}/toggle-lock flips is_locked from false→true or true→false | — | — | ⬜ |
| TC-D14 | O | Transaction rollback on DB error during save — Transactional Integrity (`DB::rollBack()`) | If one row fails (e.g., FK violation), all prior rows are rolled back; no partial save | — | — | ⬜ |
| TC-D15 | P | Filter rows by depth level (topic/sub_topic/mini_topic) — Depth Filtering (`filterRowsByLevel()`) | Setting estimation to "sub_topic" shows Sub-Topic rows; Mini-Topic/Micro/Nano rows are hidden | — | — | ⬜ |
| TC-D16 | Q | Pagination at 50 rows per page via seq_page — Pagination (`seq_page` parameter) | With 60 rows, page 1 shows rows 1-50, page 2 shows rows 51-60 | — | — | ⬜ |
| TC-D17 | R | Daily limit validation (per row vs MAX tot_periods_in_day) — Daily Limit (`$dailyLimit` check) | Row with planned_periods > daily_limit returns 500; row with planned_periods <= daily_limit passes | — | — | ⬜ |
| TC-D18 | S | Weekly limit validation (SUM vs MAX tot_periods_in_week) — Weekly Limit (`$weeklyLimit` check) | Total planned_periods > weekly_limit returns 500; total <= weekly_limit passes | — | — | ⬜ |
| TC-D19 | — | FK CASCADE — class delete cascades to sequencing rows | Delete class → related slb_syllabus_schedule rows for that class cascade deleted | — | — | ⬜ |
| TC-D20 | — | FK CASCADE — subject delete cascades to sequencing rows | Delete subject → related schedule rows cascade deleted | — | — | ⬜ |
| TC-D21 | — | FK CASCADE — topic delete cascades to sequencing rows | Delete topic → related schedule rows cascade deleted | — | — | ⬜ |
| TC-D22 | — | FK topic_level_type_id undeclared behavior | Delete topic_level_type → behavior (SET NULL or error); document actual constraint | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Planning tabs are wrapped by @can('tenant.lesson.viewAny'); users without viewAny permission cannot see Planning section | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.planning` key → `'syllabus/planning'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — try-catch Exception Handling on saveSequencing | saveSequencing() uses try-catch; exceptions are caught, logged, and user receives error feedback; no unhandled \Exception causes 500 | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — saveSequencing Returns JSON Success Response | saveSequencing() returns response()->json(['success' => true, 'message' => '...']); frontend displays success toast on response | — | — | ◌ |


---



## 7. Detailed Test Steps

#### TC-CR03: Controller — try-catch Exception Handling on saveSequencing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SyllabusController.php | Controller found in app/Http/Controllers/
| 2 | Locate saveSequencing() method | Method uses try-catch for bulk upsert logic
| 3 | Inspect try block | Save logic (findOrFail + updates + creates + activityLog) wrapped in try
| 4 | Inspect catch block | On \Exception, error logged; user redirected with error message; no partial data written


#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open lesson-sequencing partial blade for this screen | View file found in lesson-management/partials/lesson-sequencing/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Load sequencing with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR06: Controller — saveSequencing Returns JSON Success Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SyllabusController.php | Controller found
| 2 | Locate saveSequencing() method | Method exists with try-catch, validation, and bulk upsert logic
| 3 | Inspect the method return | On success, returns response()->json([...]) with success: true and message
| 4 | Send a valid POST to save-sequencing endpoint | Response has {success: true, message: '...'}
| 5 | Verify frontend behavior | Success toast/notification displayed based on JSON response


#### TC-CR01: Blade @can Directives — Permission-based Tab Visibility via viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect planning/index.blade.php | Tab is conditionally rendered via @can('tenant.lesson.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.lesson.viewAny'
| 3 | Log in as user with viewAny permission | Lesson Sequencing tab visible in Planning section |
| 4 | Log in as user without viewAny permission | Lesson Sequencing tab hidden; user cannot access Planning section |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.planning' key exists | Config has 'syllabus.planning' => 'syllabus/planning' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/planning' correctly references Planning tab view
| 4 | Load the screen via the Planning tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Planning tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Lesson Sequencing Tab Loads With Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin, navigate to Planning → Lesson Sequencing | Tab loads at /planning?tab=lesson_sequencing |
| 2 | Check filter area | Class dropdown, Section dropdown, Subject dropdown, Apply button |
| 3 | Select a class, section, and subject | Filters selected |
| 4 | Click "Apply" | Table loads with sequencing rows |

---

#### TC-P02: First-Time Load — Builds From CRUD (No Schedule Records)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no schedule records exist for selected class+subject | Clean state |
| 2 | Click Apply | System calls buildSequencingFromCrud() |
| 3 | Verify rows appear | Rows built from Lesson → Topic hierarchy |
| 4 | Check planned_periods | Rolled up from duration_minutes of child topics |

---

#### TC-P03: Existing Schedule Records Loaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-create schedule records with known ordinals | 5 records exist |
| 2 | Click Apply for that class+subject | Table loads with saved data |
| 3 | Verify ordinals match saved values | Correct order |
| 4 | Verify planned_periods, priority, is_active match saved values | All fields preserved |

---

#### TC-P04: Depth Filter = "topic" Shows Only Root Topics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set SchConfig estimation_level = "topic" | Config saved |
| 2 | Reload sequencing tab | Only root topics visible |
| 3 | Verify no Sub-Topic, Mini-Topic, Micro-Topic rows | Deeper levels hidden |

---

#### TC-P05: Depth Filter = "sub_topic" Shows Sub-Topic Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set estimation_level = "sub_topic" | Config saved |
| 2 | Reload sequencing tab | Lesson + Topic + Sub-Topic columns shown |
| 3 | Verify Mini-Topic, Micro-Topic rows hidden | Hidden |

---

#### TC-P06: Depth Filter = "mini_topic" Shows Mini-Topic Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set estimation_level = "mini_topic" | Config saved |
| 2 | Reload sequencing tab | All levels down to Mini-Topic visible |
| 3 | Verify Nano-Topic rows hidden (if applicable) | Hidden |

---

#### TC-P07: Period Roll-Up From duration_minutes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Topic A (root) with Sub-Topic A1 (duration=20), Sub-Topic A2 (duration=30) | Children exist |
| 2 | Create Sub-Topic A1 with Mini-Topic A1a (duration=10), Mini-Topic A1b (duration=10) | Grandchildren exist |
| 3 | Load sequencing (first-time) | Root Topic A planned_periods = 20+30 = 50 (sum of subs) |
| 4 | Check Sub-Topic A1 planned_periods | = 10+10 = 20 (sum of minis) |

---

#### TC-P08: Save Sequencing — All Rows Valid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit ordinals, priorities, periods, statuses for several rows | Rows modified |
| 2 | Click "Save Teaching Sequence" | AJAX POST to /planning/save-sequencing |
| 3 | Check response | { success: true, message: "Teaching sequence saved successfully!" } |
| 4 | DB check: all rows persisted | Correct values in slb_syllabus_schedule |

---

#### TC-P09: Save Sequencing — Existing Row Updated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Row with schedule_id=10, change ordinal from 2 to 5 | Ordinal changed |
| 2 | Save | schedule_id=10 updated |
| 3 | DB check: ordinal = 5 | Updated successfully |

---

#### TC-P10: Save Sequencing — New Row Inserted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add a new row without schedule_id | New row |
| 2 | Save | INSERT new record |
| 3 | DB check: new schedule_id generated | Record inserted |

---

#### TC-P11: Save Sequencing — Class Teacher Auto-Assigned

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set ClassSection.class_teacher_id for selected class+section | Mapping exists |
| 2 | Save sequencing | All rows get assigned_teacher_id = resolved Employee |
| 3 | DB check: assigned_teacher_id populated | Non-null on all rows |

---

#### TC-P12: Save Sequencing — No Class Teacher

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure ClassSection has no class_teacher_id | No mapping |
| 2 | Save sequencing | All rows assigned_teacher_id = null |
| 3 | Verify | No teacher auto-assigned |

---

#### TC-P13: Drag Reorder Updates Ordinals

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Display 3 rows with ordinals 1, 2, 3 | Rows in order |
| 2 | Drag row 3 to position 1 | Ordinals renumbered: row3=1, row1=2, row2=3 |
| 3 | Save | Correct ordinals persisted |

---

#### TC-P14: Pagination — 50 Rows Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 51 schedule records for selected filters | 51 records exist |
| 2 | Load sequencing tab | 50 rows on page 1 |
| 3 | Check pagination | Page 2 link visible with seq_page=2 |
| 4 | Click page 2 | Remaining 1 row shown |

---

#### TC-P15: Save Sequencing Transaction Success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Modify 30 rows | All valid |
| 2 | Click Save | Single DB::transaction |
| 3 | DB check: all 30 rows updated/inserted | Transaction committed |

---

#### TC-P16: Priority Dropdown Options

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click priority dropdown on any row | Options: HIGH, MEDIUM, LOW |
| 2 | Select HIGH | Row priority = HIGH |
| 3 | Change to MEDIUM | Row priority = MEDIUM |
| 4 | Change to LOW | Row priority = LOW |

---

#### TC-P17: Status Toggle (Active/Inactive)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle status to Inactive on a row | Row marked inactive (is_active=0) |
| 2 | Save | Inactive persisted |
| 3 | Toggle back to Active | is_active=1 |
| 4 | Save | Active persisted |

---

#### TC-P18: Running Total Banner At Bottom

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set planned_periods on rows: 3, 5, 2 | Sum = 10 |
| 2 | Check bottom banner | Shows "Total: 10 periods" or similar |

---

#### TC-P19: Daily Limit Check Pass

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set PeriodsAllocation MAX(tot_periods_in_day) = 10 | Daily limit = 10 |
| 2 | Set all rows planned_periods <= 10 | Within limit |
| 3 | Save | Succeeds |

---

#### TC-P20: Weekly Limit Check Pass

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set PeriodsAllocation MAX(tot_periods_in_week) = 50 | Weekly limit = 50 |
| 2 | Set SUM of all planned_periods = 45 | Within limit |
| 3 | Save | Succeeds |

---

#### TC-P21: Filter Rows By Class + Subject Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A / Subject X | Rows for A/X shown |
| 2 | Change to Class B / Subject Y | Table reloads with rows for B/Y |
| 3 | Change back to A/X | Original rows shown again |

---

#### TC-P22: Default Depth When Config Not Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove SchConfig for estimation_level | No config |
| 2 | Reload sequencing | System uses default depth |
| 3 | Verify rows shown at default level | Default behavior applied |

---

#### TC-P23: Auto-Save On Page Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Modify a row's planned_periods on page 1 | Change made but not saved |
| 2 | Click page 2 link | Auto-save AJAX fires before navigation |
| 3 | Return to page 1 | Change persisted from auto-save |

---

### 6.2 Negative TC Steps

#### TC-N01: Save Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.lesson.update | Dashboard loads |
| 2 | Try to save sequencing | HTTP 403 Forbidden |

---

#### TC-N02: Row Missing Required lesson_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit row without lesson_id | HTTP 500 |
| 2 | Error: "Invalid row data. Please refresh and try again." | Validation error |

---

#### TC-N03: Row Missing Required topic_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit row without topic_id | HTTP 500 |

---

#### TC-N04: Row Missing Required ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit row without ordinal | HTTP 500 |

---

#### TC-N05: Invalid Ordinal — 0 Or Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit ordinal = 0 | HTTP 500 (min:1) |
| 2 | Submit ordinal = -5 | HTTP 500 (min:1) |

---

#### TC-N06: Invalid Priority Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit priority = "URGENT" | HTTP 500: must be HIGH, MEDIUM, LOW |

---

#### TC-N07: Single Row Exceeds Daily Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set daily_limit = 10 (from PeriodsAllocation MAX) | Limit = 10 |
| 2 | Set a row planned_periods = 15 | Exceeds limit |
| 3 | Click Save | HTTP 500: "Planned periods (15) exceeds the daily allocation limit (10)..." |

---

#### TC-N08: Total Exceeds Weekly Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set weekly_limit = 99 | Limit = 99 |
| 2 | Set SUM of all planned_periods = 120 | Exceeds limit |
| 3 | Click Save | HTTP 500: "Total planned periods (120) exceeds the weekly allocation limit (99)..." |

---

#### TC-N09: Invalid planned_periods Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit planned_periods = "abc" | HTTP 500: must be a number |

---

#### TC-N10: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to /planning?tab=lesson_sequencing | Redirect to /login |

---

#### TC-N11: View Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without tenant.lesson.viewAny → navigate to sequencing | HTTP 403 |

---

#### TC-N12: Empty Rows Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST {"rows":[]} to /planning/save-sequencing | Validation error: rows required |

---

#### TC-N13: planned_periods Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit planned_periods = -5 | Validation error (min:0) |

---

#### TC-N14: planned_periods > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit planned_periods = 150 | Validation error (max:100) |

---

#### TC-N15: DB Transaction Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Include a row with FK violation (invalid lesson_id) | Transaction rollback |
| 2 | Check DB: no rows saved from this batch | All reverted |

---

#### TC-N16: XSS In Row Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson/topic with name containing script tag | Stored as literal string |
| 2 | View sequencing table | Blade {{ }} escapes output; no script execution |

---

### 6.3 Dependency TC Steps

#### TC-D01: Sequencing → Scheduling Data Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save sequencing for Class A / Subject X | Success |
| 2 | Navigate to Lesson Scheduling tab | All sequenced rows appear with correct ordinals, periods, priorities |
| 3 | Verify assigned_teacher_id | If class teacher exists, pre-assigned |

---

#### TC-D02: Settings Depth Change — Reload Shows Different Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set estimation level = "topic" | Only root topics |
| 2 | Navigate to Lesson Sequencing | Shows N root topic rows |
| 3 | Change setting to "sub_topic" | Config saved |
| 4 | Reload sequencing | Shows more rows (N + sub-topics) |

---

#### TC-D03: PeriodsAllocation Limits Used For Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PeriodsAllocation with tot_periods_in_day=5, tot_periods_in_week=30 | Records exist |
| 2 | Save sequencing with row having 8 periods | Fails with daily limit exceeded (8 > 5) |
| 3 | Reduce to 4 periods per row, total 25 | Succeeds (within both limits) |

---

#### TC-D04: Class Teacher Chain — user_id Resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set ClassSection.class_teacher_id = user_id of Employee | matches Employee.user_id |
| 2 | Save sequencing | assigned_teacher_id = Employee.id where user_id matches |

---

#### TC-D05: Class Teacher Chain — Employee::find()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set ClassSection.class_teacher_id = 999 (no user match, but Employee::find(999) exists) | Employee found by id |
| 2 | Save sequencing | assigned_teacher_id = 999 |

---

#### TC-D06: Default Limits When No Allocation Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no PeriodsAllocation records exist | Clean |
| 2 | Save sequencing with row having 12 planned_periods | Fails: daily limit defaults to 10, 12 > 10 |
| 3 | Reduce row to 9, total 50 | Succeeds: weekly limit defaults to 99, 50 < 99 |

---

#### TC-D07: Delete Lesson → Sequencing Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with schedule records | Schedule exists |
| 2 | Soft-delete the lesson | booted() deleting event fires |
| 3 | DB check: schedule records have deleted_at set | Cascaded soft delete |

---

#### TC-D08: Page Change Auto-Save Preserves Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit planned_periods on page 1 row | Value changed |
| 2 | Click page 2 | Auto-save AJAX fires; page 2 loads |
| 3 | Click page 1 back | Edited row shows updated planned_periods |

---

#### TC-D09: Save Sequencing With Invalid Priority Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit priority = "URGENT" via POST /syllabus/planning/save-sequencing | HTTP 500: "must be one of HIGH, MEDIUM, LOW" |
| 2 | Submit priority = "HIGH" | Accepted |
| 3 | Submit priority = "MEDIUM" | Accepted |
| 4 | Submit priority = "LOW" | Accepted |

---

#### TC-D10: Save Sequencing With planned_periods > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit planned_periods = 150 via POST /syllabus/planning/save-sequencing | HTTP 500: validation error (max:100) |
| 2 | Submit planned_periods = 100 | Accepted (boundary value) |

---

#### TC-D11: Auto-Schedule Calculates Dates Using ppd From PeriodsAllocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PeriodsAllocation with period_per_day = 2 | ppd = 2 |
| 2 | Submit rows with planned_periods = 4, 2, 6 | Total = 12 periods / 2 ppd = 6 days needed |
| 3 | Call POST /syllabus/planning/auto-schedule | Response contains start_date and end_date spanning 6 school days |

---

#### TC-D12: Auto-Schedule Skips Locked Schedules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_locked = true on schedule_id = 5 | Schedule locked |
| 2 | Call POST /syllabus/planning/auto-schedule | Locked schedule retains existing dates |
| 3 | Verify unlocked schedules | Unlocked schedules receive new calculated dates |

---

#### TC-D13: Toggle Lock Flips is_locked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check schedule.is_locked = false | Initially unlocked |
| 2 | POST /syllabus/planning/5/toggle-lock | Response: is_locked = true |
| 3 | POST /syllabus/planning/5/toggle-lock again | Response: is_locked = false |

---

#### TC-D14: Transaction Rollback on DB Error During Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit 30 valid sequencing rows + 1 row with invalid FK (non-existent lesson_id) | Batch processed in DB::transaction() |
| 2 | Check DB for prior 30 rows | None exist (all rolled back) |
| 3 | Verify error response | HTTP 500 or validation error; no partial save |

---

#### TC-D15: Filter Rows by Depth Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set estimation_level = "sub_topic" | Config applied |
| 2 | Reload sequencing tab | Only Lesson/Topic/Sub-Topic rows visible |
| 3 | Verify Mini-Topic, Micro-Topic, Nano-Topic rows | Hidden from view |

---

#### TC-D16: Pagination at 50 Rows Per Page via seq_page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 60 schedule records for selected filters | 60 records |
| 2 | Load sequencing tab (seq_page=1) | Rows 1-50 displayed |
| 3 | Click page 2 (seq_page=2) | Rows 51-60 displayed |

---

#### TC-D17: Daily Limit Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set PeriodsAllocation MAX(tot_periods_in_day) = 5 | Daily limit = 5 |
| 2 | Submit row with planned_periods = 6 | HTTP 500: exceeds daily allocation limit |
| 3 | Submit row with planned_periods = 5 | Accepted (within limit) |

---

#### TC-D18: Weekly Limit Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set PeriodsAllocation MAX(tot_periods_in_week) = 20 | Weekly limit = 20 |
| 2 | Submit SUM of planned_periods = 25 | HTTP 500: exceeds weekly allocation limit |
| 3 | Submit SUM of planned_periods = 20 | Accepted (within limit) |

---

#### TC-P28: Depth Filter = nano_topic — All Rows Visible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set SchConfig syllabus_teaching_estimation_level_for_lesson_planning = nano_topic | Config saved |
| 2 | Load Lesson Sequencing tab | Grid loads with nano-level depth |
| 3 | Verify all hierarchy levels visible (Lesson, Topic, Sub-Topic, Mini-Topic, Micro-Topic, Nano-Topic) | No rows hidden |
| 4 | Count rows — matches total across all levels | All levels displayed |

#### TC-N17: Default Filter Values Applied on Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Lesson Sequencing tab without filter params | Class defaults to first option (id=1) |
| 2 | Check subject filter | Defaults to subject_id=5 |
| 3 | Check academic session filter | Defaults to academic_session_id=7 |
| 4 | Data loads with these default filters | Grid populated |

#### TC-N18: is_active Required Boolean Validation — Missing Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare row with all required fields except is_active | is_active omitted |
| 2 | Submit save request | Validation error: "is_active is required" |
| 3 | Verify save fails | Row not saved |

#### TC-N19: is_active Required Boolean Validation — Non-Boolean Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare row with is_active="yes" | Invalid value |
| 2 | Submit save request | Validation error: "is_active must be true or false" |
| 3 | Verify save fails | Row not saved |

#### TC-N20: schedule_id Nullable Integer Validation — Invalid Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare row with schedule_id="abc" | Invalid type |
| 2 | Submit save request | Validation error: "schedule_id must be an integer" |
| 3 | Verify save fails | Row not saved |

#### TC-N21: Period Roll-Up Zero — Manual Entry Needed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create topics with duration_minutes=null for all | No durations set |
| 2 | Load Lesson Sequencing tab and build from CRUD | planned_periods=0 for all rows |
| 3 | Verify teacher can manually enter planned_periods | Input fields editable |
| 4 | Enter planned_periods=3, save | Save succeeds |

#### TC-N22: Level Mismatch After Depth Config Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set depth = sub_topic, save sequencing rows | Rows saved at sub_topic level |
| 2 | Change depth to topic | Grid reloads, shows only root topics |
| 3 | Verify sub_topic rows hidden but still in DB | Data preserved |
| 4 | Revert depth to sub_topic | Sub-topic rows visible again |

#### TC-D19: FK CASCADE — Class Delete Cascades to Sequencing Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create sequencing rows for Class A | Rows exist with class_id=A |
| 2 | Delete Class A from sch_classes | Class removed |
| 3 | DB check: sequencing rows for Class A | All rows cascade deleted |

#### TC-D20: FK CASCADE — Subject Delete Cascades to Sequencing Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create sequencing rows for Subject X | Rows exist with subject_id=X |
| 2 | Delete Subject X from sch_subjects | Subject removed |
| 3 | DB check: sequencing rows for Subject X | All rows cascade deleted |

#### TC-D21: FK CASCADE — Topic Delete Cascades to Sequencing Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create sequencing rows for Topic Y | Rows exist with topic_id=Y |
| 2 | Delete Topic Y from slb_topics | Topic removed |
| 3 | DB check: sequencing rows for Topic Y | All rows cascade deleted |

#### TC-D22: FK topic_level_type_id Undeclared Behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find schedule row with topic_level_type_id set | FK populated |
| 2 | Delete referenced topic_level_type | Action taken |
| 3 | Check schedule row's topic_level_type_id | Behavior = actual DB constraint (SET NULL or error); document for future migration |
