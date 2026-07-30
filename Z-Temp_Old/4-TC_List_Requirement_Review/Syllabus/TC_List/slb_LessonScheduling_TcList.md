# slb_lesson_scheduling_TcList

## Module: Syllabus → Planning → Lesson Scheduling

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Planning |
| Feature | Lesson Scheduling |
| URL(s) | `GET /syllabus/planning?tab=lesson_scheduling` (display), `POST /syllabus/planning/save-scheduling` (batch save), `POST /syllabus/planning/auto-schedule` (auto date calc), `POST /syllabus/planning/{id}/toggle-lock` (lock toggle) |
| Controller | `Modules\Syllabus\Http\Controllers\SyllabusScheduleController` (CRUD) + `SyllabusController@planning()` (tab render), `SyllabusController@saveScheduling()` (batch save), `SyllabusController@autoSchedule()` (auto-schedule) |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` (table: `slb_syllabus_schedule`) |
| Validation | Inline validation in `saveScheduling()` per row loop; no dedicated FormRequest |
| Permissions | `tenant.lesson.update` (save), `tenant.lesson.viewAny` (view) |
| Lock Mechanism | `is_locked` boolean on `SyllabusSchedule`; locked rows skipped in save |
| View | `resources/views/lesson-management/partials/lesson-scheduling/index.blade.php` |
| Auto-Fill | On tab open, if any row has empty start date, auto-schedule API called automatically |

---

## 2. Pre-conditions

- Required permissions: `tenant.lesson.viewAny` (view), `tenant.lesson.update` (save scheduling, auto-schedule, lock toggle)
- Required seed data: Sequenced topics in `SyllabusSchedule` table with `lesson_id`, `topic_id`, `ordinal`, `planned_periods`, `priority`, `is_active`
- At least one active `OrganizationAcademicSession`, one `SchoolClass` with section, one `Subject`
- `Employee` records with `is_teacher=true`, `is_active=true` for teacher dropdown
- `PeriodsAllocation` records (or defaults apply: ppd=1)
- `ClassSection` mapping for class teacher auto-resolution
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---



---

## 3. Default Data Load

When the page loads via SyllabusController@planning() (GET /syllabus/planning) with tab=lesson_scheduling, default filters: class_section_id=1, subject_id=5, academic_session_id=7.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: dropdowns | planning() | Same as LessonSequencing (classes, sections, classSections, subjects, academicSessions) | --- | None |
| Teachers dropdown | planning() | Employee::where(is_teacher,true)->where(is_active,true)->orderBy(first_name) | is_teacher=1, is_active=1 | None |
| Scheduling Grid | planning() | SyllabusSchedule::with(lesson,topic,topicLevelType,topic.parent+parent.parent,assignedTeacher) OR empty | class_id, subject_id, section_id, academic_session_id | None (full collection filtered by level) |
| Period Limits | planning() | PeriodsAllocation::selectRaw(MAX(tot_periods_in_day), MAX(tot_periods_in_week)) | class_id, subject_id, section_id, academic_session_id | None (single row) |
## 4. Test Data Strategy

- **Schedule records**: Pre-create via `SyllabusSchedule::factory()` or via sequencing save
- **Teacher IDs**: Use `Employee::where('is_teacher', true)->pluck('id')` for assignments
- **Date range**: Use `Carbon::now()->addDays()` for relative dates
- **Lock state**: Toggle `is_locked` field directly in DB for locked-row tests
- **Periods allocation**: Ensure `syncPeriodsAllocation()` has been run or create records manually
- **Auto-schedule ppd**: Defaults to 1 if no `PeriodsAllocation` records exist
- **Batch payload**: Array of `{schedule_id, scheduled_start_date, scheduled_end_date, assigned_teacher_id}` per row
- **Pre-test cleanup**: Delete created schedule records after each test
- **Unique suffix**: `now()->format('His') . random_int(100, 999)` where needed

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_syllabus_schedule`

(Same DDL as Lesson Date Planning — see `csm_SlbLessonDatePlanningTcList.md` section 4.1)

### 4.2 Validation Rules — `saveScheduling()` Inline Per Row

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | rows | required, array | "The rows field is required." |
| BC-VAL-02 | rows.*.schedule_id | required, integer, exists:slb_syllabus_schedule,id | Skipped silently if not found |
| BC-VAL-03 | rows.*.scheduled_start_date | nullable, date | — |
| BC-VAL-04 | rows.*.scheduled_end_date | nullable, date | — |
| BC-VAL-05 | rows.*.assigned_teacher_id | nullable, integer, exists:employees,id | — |
| BC-VAL-06 | class_id | required, integer | — |
| BC-VAL-07 | subject_id | required, integer | — |
| BC-VAL-08 | section_id | required, integer | — |

### 4.3 Validation Rules — `autoSchedule()` Request

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | start_date | required, date | "The start date is required." |
| BC-VAL-U02 | class_id | required, integer | — |
| BC-VAL-U03 | subject_id | required, integer | — |
| BC-VAL-U04 | section_id | required, integer | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lesson.viewAny | planning() tab render | Without → 403 |
| BC-AUTH-02 | tenant.lesson.update | saveScheduling() | Without → 403 |
| BC-AUTH-03 | tenant.lesson.update | autoSchedule() | Without → 403 |
| BC-AUTH-04 | tenant.lesson.update | toggleLock() | Without → 403 |
| BC-AUTH-05 | Guest access | Any scheduling route | Redirect to /login |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | No schedule records exist | Show empty table: "Complete Lesson Sequencing first" |
| BC-BIZ-02 | Tab opens with empty dates | Auto-schedule API triggered once automatically |
| BC-BIZ-03 | Auto-schedule: locked rows | Locked rows keep existing dates; skipped in calculation |
| BC-BIZ-04 | Auto-schedule: ppd from PeriodsAllocation MAX | Defaults to 1 if no records |
| BC-BIZ-05 | Auto-schedule: cumulative offset | `startOff = floor(cumulative/ppd)`, `endOff = ceil((cumulative+dur)/ppd)-1` |
| BC-BIZ-06 | Save: locked row encountered | `continue` — row silently skipped, no error |
| BC-BIZ-07 | Save: schedule_id not found | `find()` returns null → `continue`, silently skipped |
| BC-BIZ-08 | Save: both dates present | `planned_periods = diffInDays(start,end) + 1 x ppd` |
| BC-BIZ-09 | Save: teacher explicitly set | Updates `assigned_teacher_id` |
| BC-BIZ-10 | Save: teacher not passed | Keeps existing teacher (not nullified) |
| BC-BIZ-11 | Save: teacher changed | Also sets `taught_by_teacher_id = assigned_teacher_id` |
| BC-BIZ-12 | Save: any row has dates | Calls `syncPeriodsAllocation()` to create/update allocation records |
| BC-BIZ-13 | Lock toggle | Flips `is_locked` value: true→false, false→true |
| BC-BIZ-14 | Locked row visual | Inputs disabled, red lock icon |
| BC-BIZ-15 | Unlocked row visual | Inputs enabled, green open lock icon |
| BC-BIZ-16 | Teacher dropdown defaults | Falls back to class teacher from ClassSection mapping |
| BC-BIZ-17 | Manual date change recalculates | `days_in_range x ppd` displayed as Duration badge |
| BC-BIZ-18 | Hierarchy columns based on Settings depth | Same as Sequencing: shows Lesson/Topic/Sub-Topic/Mini-Topic based on config |
| BC-BIZ-19 | Screen loads via SyllabusController@planning() at GET /syllabus/planning with tab=lesson_scheduling | Navigating to GET /syllabus/planning with tab=lesson_scheduling loads this screen's grid data with correct filters applied |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt | CASCADE |
| BC-REF-02 | class_id | sch_classes | CASCADE |
| BC-REF-03 | section_id | sch_sections | CASCADE |
| BC-REF-04 | subject_id | sch_subjects | CASCADE |
| BC-REF-05 | lesson_id | slb_lessons | Not declared |
| BC-REF-06 | topic_id | slb_topics | CASCADE |
| BC-REF-07 | assigned_teacher_id | employees | SET NULL |
| BC-REF-08 | taught_by_teacher_id | employees | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Lesson Scheduling Tab Loads With Table | Tab opens with table showing hierarchy columns, teacher dropdowns, date pickers, duration badge, priority, status, lock toggle | — | — | ⬜ |
| TC-P02 | No Schedule Records — Shows Sequencing Prompt | If no records exist, show "Complete Lesson Sequencing first" message | — | — | ⬜ |
| TC-P03 | Batch Save — Update Teacher And Dates For 3 Rows | 3 unlocked rows saved: teacher, start date, end date all updated; success response | — | — | ⬜ |
| TC-P04 | Batch Save — Teacher Cascades To taught_by_teacher_id | Setting assigned_teacher_id also sets taught_by_teacher_id | — | — | ⬜ |
| TC-P05 | Batch Save — Periods Recalculated When Both Dates Set | planned_periods = (diffInDays + 1) x ppd calculated and saved | — | — | ⬜ |
| TC-P06 | Batch Save — Existing Teacher Preserved When Not Sent | If teacher not in request row, existing teacher remains unchanged | — | — | ⬜ |
| TC-P07 | Auto-Fill Dates On Tab Open | Tab opens → auto-schedule API triggered (if empty dates exist) → dates filled automatically | — | — | ⬜ |
| TC-P08 | Auto-Fill Does Not Re-Trigger On Subsequent Opens | Switch tabs away and back → auto-fill does not run again | — | — | ⬜ |
| TC-P09 | Auto-Schedule Button — Distributes Topics Correctly | Click "Auto Schedule" → algorithm calculates dates based on ppd and cumulative offset | — | — | ⬜ |
| TC-P10 | Auto-Schedule — Locked Rows Skipped | Locked rows keep original dates; only unlocked rows get new dates | — | — | ⬜ |
| TC-P11 | Auto-Schedule — Ppd Reads From PeriodsAllocation MAX | MAX(tot_periods_in_day) used; defaults to 1 if no records | — | — | ⬜ |
| TC-P12 | Auto-Schedule — Zero-Period Rows Get Null Dates | Rows with planned_periods <= 0 get null start/end dates | — | — | ⬜ |
| TC-P13 | Lock Toggle — Lock A Row | Click lock icon → row locked, inputs disabled, red lock icon | — | — | ⬜ |
| TC-P14 | Lock Toggle — Unlock A Row | Click lock icon on locked row → row unlocked, inputs enabled, green lock icon | — | — | ⬜ |
| TC-P15 | Locked Row Skipped During Batch Save | Save includes locked + unlocked rows → only unlocked rows updated; locked unchanged | — | — | ⬜ |
| TC-P16 | Teacher Dropdown Shows Active Teachers | Dropdown lists Employee::where(is_teacher,1)->where(is_active,1) ordered by first_name | — | — | ⬜ |
| TC-P17 | Teacher Dropdown Defaults To Class Teacher | If ClassSection has class_teacher_id, auto-selected in dropdown | — | — | ⬜ |
| TC-P18 | Duration Badge Updates On Date Change (Client-Side) | Change start or end date → duration badge recalculates instantly | — | — | ⬜ |
| TC-P19 | Save Scheduling Triggers syncPeriodsAllocation() | After save, slb_syllabus_periods_allocation has records for each date in the range | — | — | ⬜ |
| TC-P20 | syncPeriodsAllocation() Creates Records With data_created_by='AUTO' | Records have data_created_by='AUTO', notes='Auto-generated from Lesson Scheduling' | — | — | ⬜ |
| TC-P21 | syncPeriodsAllocation() Uses updateOrCreate | Second save with overlapping dates updates existing records (no duplicates) | — | — | ⬜ |
| TC-P22 | Subject Study Format Missing — Skip Sync | Subject with no active SubjectStudyFormat → sync exits early, no allocation records | — | — | ⬜ |
| TC-P23 | Save Scheduling Success Response | Handler returns { success: true, message: "Scheduling saved successfully!" } | — | — | ⬜ |
| TC-P24 | Teacher Assignment Visual | Selected teacher name shown in dropdown; empty shows "Class Teacher" label | — | — | ⬜ |
| TC-P25 | Priority Badge Display | HIGH=red badge, MEDIUM=amber badge, LOW=green badge (read-only from sequencing) | — | — | ⬜ |
| TC-P26 | Status Badge Display | Active badge (green) or Inactive badge (red) based on sequencing is_active | — | — | ⬜ |
| TC-P27 | Hierarchy Columns Match Settings Depth | Config=Sub-Topic → columns: Lesson, Topic, Sub-Topic shown | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Save Scheduling Without Permission | User without tenant.lesson.update → HTTP 403 | — | — | ⬜ |
| TC-N02 | Save With Invalid Schedule ID (Row Silently Skipped) | schedule_id=99999 → find() returns null → row skipped with continue; no error | — | — | ⬜ |
| TC-N03 | Save Locked Row — Silently Skipped | Locked row data unchanged; no error message returned | — | — | ⬜ |
| TC-N04 | Auto-Schedule Without Permission | User without tenant.lesson.update → HTTP 403 | — | — | ⬜ |
| TC-N05 | Auto-Schedule Missing Required Fields | POST without start_date → HTTP 500 validation error | — | — | ⬜ |
| TC-N06 | Lock Toggle Without Permission | User without tenant.lesson.update → HTTP 403 | — | — | ⬜ |
| TC-N07 | Guest Access Redirect | Not logged in → redirect to /login | — | — | ⬜ |
| TC-N08 | Invalid Date In Save Payload | Date format "abc" → HTTP 500 via Laravel validation | — | — | ⬜ |
| TC-N09 | Invalid Teacher ID In Save | assigned_teacher_id=99999 → validation error or silently set to null | — | — | ⬜ |
| TC-N10 | End Date Before Start Date (Client Blocked) | Manual entry: end<start → client-side validation blocks | — | — | ⬜ |
| TC-N11 | Save Empty Rows Array | POST {"rows":[]} → validation error: "The rows field is required." | — | — | ⬜ |
| TC-N12 | Save Without Any Rows Key | POST without rows → validation error | — | — | ⬜ |
| TC-N13 | Rapid Double-Click Lock Toggle | Multiple rapid requests → each flips independently; last one determines state | — | — | ⬜ |
| TC-N14 | Save with no dates on any row → keep existing planned_periods | Submit rows without scheduled_start_date and scheduled_end_date → planned_periods unchanged, no validation error | — | — | ⬜ |
| TC-N15 | Missing required filter field — class_id | Save scheduling without class_id → validation error | — | — | ⬜ |
| TC-N16 | Missing required filter field — subject_id | Save scheduling without subject_id → validation error | — | — | ⬜ |
| TC-N17 | Default filter values not applied | Load tab with no filter saved → defaults to class_section_id=1, subject_id=5, academic_session_id=7 | — | — | ⬜ |
| TC-N18 | FK lesson_id undeclared behavior on lesson delete | Delete a lesson referenced by schedule → behavior per DB constraint (SET NULL or error) | — | — | ⬜ |
| TC-N19 | DB save error → HTTP 500 with error message | Mock DB failure during saveScheduling → 500 response with "Error saving scheduling: {message}" | — | — | ⬜ |
| TC-N20 | schedule_id exists validation failure | Submit row with schedule_id that does not exist in DB → row silently skipped | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Sequencing → Scheduling data flow | After sequencing save, scheduling tab shows all sequenced topics with correct ordinals | — | — | ⬜ |
| TC-D02 | B | Batch Save → Periods Allocation Sync | Save dates for 3 rows spanning 5 dates → syncPeriodsAllocation() creates 5 records | — | — | ⬜ |
| TC-D03 | B | Auto-Schedule → Periods Allocation Sync | Running auto-schedule then save → allocation records created | — | — | ⬜ |
| TC-D04 | C | Lock State Persists After Page Reload | Lock a row → refresh → row still locked | — | — | ⬜ |
| TC-D05 | D | Lock Does Not Block Date Planning Grid Save | Locked row date still editable from Lesson Date Planning (separate endpoint) | — | — | ⬜ |
| TC-D06 | E | Overlapping Date Saves Use updateOrCreate | Save dates Jul 15-18 → save Jul 15-18 again → single record per date | — | — | ⬜ |
| TC-D07 | F | Class Teacher Auto-Resolve Fallback Chain | class_teacher_id → Employee by user_id → Employee by id → first active teacher → null | — | — | ⬜ |
| TC-D08 | G | Settings Depth Change Affects Visible Columns | Change estimation level from Topic to Sub-Topic → additional columns shown | — | — | ⬜ |
| TC-D09 | H | Delete Schedule → Row Silently Skipped On Save | Delete schedule between loads → save skips it with continue | — | — | ⬜ |
| TC-D10 | I | Auto-Schedule Cumulative Offset Correctness | Row1 (3 periods), Row2 (4 periods), ppd=2 → Row1 Jul 1-2, Row2 Jul 2-4 | — | — | ⬜ |
| TC-D11 | J | UI/API | P1 | Lesson scheduling form open — ENUM Field Validation — priority | — | — | ⬜ |
| TC-D12 | K | DB | P1 | slb_syllabus_schedule with assigned teacher — FK SET NULL — assigned_teacher_id Teacher Deletion | — | — | ⬜ |
| TC-D13 | L | Integration | P1 | Schedule record with topic, lesson, class, subject, session — Multi-FK Dependency — 5 Foreign Keys | — | — | ⬜ |
| TC-CR01 | A | Code Review | P1 | Model — table name and 20 fillable attributes match `slb_syllabus_schedule` DDL | — | — | ⬜ |
| TC-CR02 | B | Code Review | P1 | Model — `$casts` correctly defines boolean (is_active/is_locked/is_completed) and integer (planned_periods/ordinal) | — | — | ⬜ |
| TC-CR03 | C | Code Review | P1 | Model — `SoftDeletes` trait enabled; `deleted_at` column present; restore/forceDelete functional | — | — | ⬜ |
| TC-CR04 | D | Code Review | P1 | Model — All 8 `BelongsTo` relationships defined (lesson/topic/topicLevelType/assignedTeacher/academicSession/class/section/subject) | — | — | ⬜ |
| TC-CR05 | E | Code Review | P1 | Controller — `store()` creates record with all fillable fields and writes activity log | — | — | ⬜ |
| TC-CR06 | F | Code Review | P1 | Controller — `update()` modifies existing record and writes activity log | — | — | ⬜ |
| TC-CR07 | G | Code Review | P1 | Controller — `destroy()` sets `is_active=false` before soft delete; activity log recorded | — | — | ⬜ |
| TC-CR08 | H | Code Review | P1 | Controller — `toggleStatus()` flips `is_active` boolean value | — | — | ⬜ |
| TC-CR09 | I | Code Review | P1 | Controller — `trashed()` returns only soft-deleted records; `restore()` brings back; `forceDelete()` permanently removes | — | — | ⬜ |
| TC-CR10 | J | Code Review | P1 | Controller — `markComplete()` sets `is_completed=true`, `completed_at=Carbon::now()`, `completed_by=auth()->id()` | — | — | ⬜ |
| TC-CR11 | K | Code Review | P1 | Controller — `getTopicsAjax()` returns JSON of topics filtered by given `lesson_id` | — | — | ⬜ |
| TC-CR12 | L | Code Review | P1 | Policy — All 8 methods (viewAny/view/create/update/delete/restore/forceDelete/status) defined and gated via `Gate::authorize('tenant.syllabus-schedule.*')` | — | — | ⬜ |
| TC-CR13 | M | Code Review | P1 | Request — `SyllabusScheduleRequest` validation rules cover all required fillable fields with correct type constraints | — | — | ⬜ |
| TC-CR14 | N | Code Review | P1 | Routes — All 8 resource routes + 6 extra routes (trashed/restore/forceDelete/toggleStatus/markComplete/getTopicsAjax) defined | — | — | ⬜ |
| TC-CR15 | O | Code Review | P1 | Authorization — `Gate::authorize('tenant.syllabus-schedule.*')` called consistently in every controller method | — | — | ⬜ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade @can Directives — Permission-based Tab Visibility via viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect planning/index.blade.php | Tab is conditionally rendered via @can('tenant.lesson.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.lesson.viewAny'
| 3 | Log in as user with viewAny permission | Lesson Scheduling tab visible in Planning section |
| 4 | Log in as user without viewAny permission | Lesson Scheduling tab hidden; user cannot access Planning section |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.planning' key exists | Config has 'syllabus.planning' => 'syllabus/planning' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/planning' correctly references Planning tab view
| 4 | Load the screen via the Planning tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Planning tab page without errors |

#### TC-CR03: Controller — try-catch Exception Handling on saveScheduling/autoSchedule/toggleLock

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SyllabusController.php | Controller found in app/Http/Controllers/
| 2 | Inspect saveScheduling() method | try-catch wraps update + activityLog; on exception, error logged and returned in JSON response
| 3 | Inspect autoSchedule() method | try-catch wraps auto-calculation + update; exceptions return error JSON
| 4 | Inspect toggleLock() method | Business logic wrapped in try-catch; exceptions caught and returned as error JSON


#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open lesson-scheduling partial blade for this screen | View file found in lesson-management/partials/lesson-scheduling/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Load scheduling with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR06: Controller — saveScheduling/autoSchedule Returns JSON Success Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SyllabusController.php | Controller found
| 2 | Locate saveScheduling() method | On success, returns response()->json(['success' => true, 'message' => '...'])
| 3 | Locate autoSchedule() method | On success, returns response()->json(['success' => true, 'message' => '...'])
| 4 | Send a valid POST to save-scheduling endpoint | Response has {success: true, message: 'Scheduling saved successfully!'}
| 5 | Send a valid POST to auto-schedule endpoint | Response has {success: true, message: '...'}
| 6 | Verify frontend behavior | Success toast/notification displayed based on JSON response


### 6.1 Positive TC Steps

#### TC-P01: Lesson Scheduling Tab Loads With Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin, navigate to Planning → Lesson Scheduling | Tab loads at /planning?tab=lesson_scheduling |
| 2 | Select class, section, subject, click Apply | Table loads with sequenced rows |
| 3 | Check hierarchy columns | Columns for Lesson, Topic (and deeper based on Settings) |
| 4 | Check teacher dropdown on each row | Dropdown present with active teachers |
| 5 | Check date pickers | Start and End date inputs present |
| 6 | Check Duration badge | Shows planned_periods value |
| 7 | Check Priority badge | HIGH/MEDIUM/LOW colored badge |
| 8 | Check Status badge | Active (green) or Inactive (red) |
| 9 | Check Lock toggle | Lock/unlock icon per row |

---

#### TC-P02: No Schedule Records — Shows Sequencing Prompt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class+subject with no schedule records | No rows in table |
| 2 | Verify message | "Complete Lesson Sequencing first" with link to Sequencing tab |

---

#### TC-P03: Batch Save — Update Teacher And Dates For 3 Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit 3 unlocked rows: set teacher, start_date, end_date | All 3 rows modified |
| 2 | Click "Save Dates" | AJAX POST to /planning/save-scheduling |
| 3 | Check response | { success: true, message: "Scheduling saved successfully!" } |
| 4 | DB check: each row's assigned_teacher_id, scheduled_start_date, scheduled_end_date updated | Values match what was entered |

---

#### TC-P04: Batch Save — Teacher Cascades To taught_by_teacher_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save a row with assigned_teacher_id=5 | Save succeeds |
| 2 | DB check: taught_by_teacher_id FROM slb_syllabus_schedule WHERE id={id} | taught_by_teacher_id = 5 |

---

#### TC-P05: Batch Save — Periods Recalculated When Both Dates Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set start_date=2026-07-15, end_date=2026-07-18, ppd=2 | 4 days x 2 = 8 periods expected |
| 2 | Save row | Save succeeds |
| 3 | DB check: planned_periods = 8 | Recalculated correctly |

---

#### TC-P06: Batch Save — Existing Teacher Preserved When Not Sent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Row has teacher_id=5 (existing) | Teacher present |
| 2 | Save row WITHOUT sending assigned_teacher_id key | Save succeeds |
| 3 | DB check: assigned_teacher_id still = 5 | Existing teacher preserved |

---

#### TC-P07: Auto-Fill Dates On Tab Open

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up schedules with empty dates for class A/subject X | Rows exist with null dates |
| 2 | Navigate to Lesson Scheduling tab | Tab loads |
| 3 | Check network tab | Auto-schedule API called automatically (POST /syllabus/planning/auto-schedule) |
| 4 | Verify dates filled | Empty rows now have calculated dates |
| 5 | Verify auto-fill happened only once (no duplicate API calls) | Single API request |

---

#### TC-P08: Auto-Fill Does Not Re-Trigger On Subsequent Opens

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab opens → auto-fill runs once | Dates filled |
| 2 | Switch to another tab and back | No auto-fill API call |
| 3 | Manually clear all dates | Dates cleared |
| 4 | Switch tabs and back | No auto-fill (must click "Auto Schedule" manually) |

---

#### TC-P09: Auto-Schedule Button — Distributes Topics Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 3 rows with planned_periods=3, 4, 2 and ppd=2 | Data ready |
| 2 | Click "Auto Schedule" button | AJAX POST to /planning/auto-schedule |
| 3 | Check response | { rows: [{schedule_id, start, end, planned_periods}], ppd: 2, wpw: 10 } |
| 4 | Verify Row1: 3 periods → Jul 1-2 | Correct dates |
| 5 | Verify Row2: 4 periods → Jul 2-4 | Correct dates (cumulative=3, offset floor=1) |
| 6 | Verify Row3: 2 periods → Jul 4-5 | Correct dates (cumulative=7, offset floor=3) |

---

#### TC-P10: Auto-Schedule — Locked Rows Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lock Row2 of 3 rows | Row2 is_locked = true |
| 2 | Click "Auto Schedule" | API runs |
| 3 | Verify Row1 and Row3 dates recalculated | Updated |
| 4 | Verify Row2 dates unchanged (keeps existing dates) | Not modified |

---

#### TC-P11: Auto-Schedule — Ppd Reads From PeriodsAllocation MAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure PeriodsAllocation has tot_periods_in_day=3 for this scope | Ppd = 3 |
| 2 | Run auto-schedule | Dates calculated with ppd=3 |
| 3 | Delete all PeriodsAllocation records for this scope | No records |
| 4 | Run auto-schedule again | Defaults to ppd=1 |

---

#### TC-P12: Auto-Schedule — Zero-Period Rows Get Null Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Row2 planned_periods = 0 | Row2 has 0 periods |
| 2 | Run auto-schedule | Row2 gets null start_date and null end_date |
| 3 | Verify Row1 and Row3 calculated normally | Other rows unaffected |

---

#### TC-P13: Lock Toggle — Lock A Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click the lock icon (green open padlock) on a row | AJAX POST to /planning/{id}/toggle-lock |
| 2 | Check response | { success: true, message: "..." } |
| 3 | DB check: is_locked = 1 | Row locked |
| 4 | Check visual: icon changed to red lock, inputs disabled | Lock state reflected in UI |

---

#### TC-P14: Lock Toggle — Unlock A Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click the lock icon (red padlock) on a locked row | AJAX POST to /planning/{id}/toggle-lock |
| 2 | DB check: is_locked = 0 | Row unlocked |
| 3 | Check visual: icon changed to green open lock, inputs enabled | Unlocked state reflected |

---

#### TC-P15: Locked Row Skipped During Batch Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lock Row2 (is_locked=1) | Row2 locked |
| 2 | Edit Row1, Row2, Row3 (change dates/teacher for all 3) | All 3 modified in UI |
| 3 | Click "Save Dates" | POST to save-scheduling |
| 4 | DB check: Row1 and Row3 updated, Row2 unchanged | Locked row skipped |
| 5 | Verify no error for locked row | Clean success response |

---

#### TC-P16: Teacher Dropdown Shows Active Teachers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click teacher dropdown on any row | Dropdown opens |
| 2 | Verify each option has is_teacher=true and is_active=true | All valid teachers |
| 3 | Count matches Employee::where(is_teacher,1)->where(is_active,1)->count() | Count matches |

---

#### TC-P17: Teacher Dropdown Defaults To Class Teacher

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up ClassSection with class_teacher_id for selected class+section | Mapping exists |
| 2 | Open scheduling tab for that class+section | Teacher dropdown pre-selected with class teacher |
| 3 | Remove class_teacher_id from ClassSection | No default |
| 4 | Reload tab | Teacher dropdown shows first active teacher or empty |

---

#### TC-P18: Duration Badge Updates On Date Change (Client-Side)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current planned_periods for a row | e.g., 5 |
| 2 | Change start date to widen the range | Duration badge recalculates instantly |
| 3 | Verify new duration = new_days_range x ppd | Badge shows correct value |

---

#### TC-P19: Save Scheduling Triggers syncPeriodsAllocation()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save 3 rows with dates from Jul 15-18 | Save succeeds |
| 2 | Query: SELECT * FROM slb_syllabus_periods_allocation WHERE class_id={cid} AND subject_id={sid} | Records exist for Jul 15, 16, 17, 18 |
| 3 | Verify tot_periods_in_day matches ppd | Correct value |

---

#### TC-P20: syncPeriodsAllocation() Creates Records With data_created_by='AUTO'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save scheduling with dates | Trigger sync |
| 2 | DB check: data_created_by field | 'AUTO' |
| 3 | DB check: notes field | 'Auto-generated from Lesson Scheduling' |

---

#### TC-P21: syncPeriodsAllocation() Uses updateOrCreate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save dates Jul 15-18 → sync creates 4 records | Records created |
| 2 | Save dates Jul 15-18 again (same range) | updateOrCreate updates existing records |
| 3 | Verify no duplicate records | Only 4 records exist for that range |

---

#### TC-P22: Subject Study Format Missing — Skip Sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set subject with no active SubjectStudyFormat | No format |
| 2 | Save scheduling with dates | Save succeeds |
| 3 | Check allocation table | No records created for this subject |

---

#### TC-P23: Save Scheduling Success Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save valid scheduling data | Response status 200 |
| 2 | Check JSON body | { success: true, message: "Scheduling saved successfully!" } |

---

#### TC-P24: Teacher Assignment Visual

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assign a teacher to a row | Teacher name shown in dropdown |
| 2 | Clear teacher selection | Shows "Class Teacher" label if default exists, or empty |

---

#### TC-P25: Priority Badge Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check row with priority=HIGH | Red badge "HIGH" |
| 2 | Check row with priority=MEDIUM | Amber badge "MEDIUM" |
| 3 | Check row with priority=LOW | Green badge "LOW" |
| 4 | Verify badges are read-only (no dropdown) | Plain badge, not editable |

---

#### TC-P26: Status Badge Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check row with is_active=1 | Green "Active" badge |
| 2 | Check row with is_active=0 | Red "Inactive" badge |
| 3 | Verify read-only | No toggle on scheduling tab |

---

#### TC-P27: Hierarchy Columns Match Settings Depth

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set estimation level to "Topic" | Columns: Lesson, Topic |
| 2 | Reload scheduling tab | Only 2 hierarchy columns |
| 3 | Change setting to "Sub-Topic" | Columns: Lesson, Topic, Sub-Topic |
| 4 | Reload scheduling tab | 3 hierarchy columns shown |

---

### 6.2 Negative TC Steps

#### TC-N01: Save Scheduling Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.lesson.update | Dashboard loads |
| 2 | Navigate to scheduling tab | Tab loads (read-only) |
| 3 | Modify dates and click Save | HTTP 403 Forbidden |

---

#### TC-N02: Save With Invalid Schedule ID (Row Silently Skipped)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Include schedule_id=99999 in save payload | Schedule not found |
| 2 | Click Save | saveScheduling loops: find(99999)=null → continue |
| 3 | Check response | 200 success (row silently skipped, no error) |

---

#### TC-N03: Save Locked Row — Silently Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Include a locked row in save payload | Row is_locked=true |
| 2 | Click Save | continue executed for locked row |
| 3 | DB check: locked row dates unchanged | Not modified |

---

#### TC-N04: Auto-Schedule Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.lesson.update | Read-only |
| 2 | Click "Auto Schedule" | HTTP 403 Forbidden |

---

#### TC-N05: Auto-Schedule Missing Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to /planning/auto-schedule without start_date | HTTP 500 |
| 2 | Error: "The start date is required." | Validation error |

---

#### TC-N06: Lock Toggle Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without tenant.lesson.update tries to toggle lock | HTTP 403 Forbidden |

---

#### TC-N07: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to /planning?tab=lesson_scheduling | Redirected to /login |

---

#### TC-N08: Invalid Date In Save Payload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send scheduled_start_date="invalid-date" | HTTP 500 validation error |

---

#### TC-N09: Invalid Teacher ID In Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send assigned_teacher_id=99999 | Validation error: "The selected assigned teacher id is invalid." |

---

#### TC-N10: End Date Before Start Date (Client Blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually set end_date before start_date on a row | Client-side JS shows validation error toast |
| 2 | Check network | No save request sent |

---

#### TC-N11: Save Empty Rows Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST {"rows":[]} to /planning/save-scheduling | HTTP 500: "The rows field is required." |

---

#### TC-N12: Save Without Any Rows Key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without rows key | HTTP 500 validation error |

---

#### TC-N13: Rapid Double-Click Lock Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly click lock toggle 5 times | Each click sends independent AJAX |
| 2 | DB check: is_locked = final toggle state | Last toggle determines state |
| 3 | No data corruption or server errors | All requests 200 |

---

#### TC-N14: Save With No Dates On Any Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Lesson Scheduling tab with existing schedule rows | Rows displayed with existing planned_periods |
| 2 | Clear both scheduled_start_date and scheduled_end_date for a row | Dates cleared |
| 3 | Click Save | Save request sent |
| 4 | Verify planned_periods for that row unchanged | Periods remain as previously saved |
| 5 | DB check: row's planned_periods preserved | No change in DB |

#### TC-N15: Missing Required Filter Field — class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select subject only, leave class unselected | Class dropdown empty |
| 2 | Click Apply or Save | Validation error: "Class is required" |
| 3 | Repeat with subject_id missing | Same validation error for subject |

#### TC-N16: Missing Required Filter Field — subject_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class only, leave subject unselected | Subject dropdown empty |
| 2 | Click Apply or Save | Validation error: "Subject is required" |
| 3 | Verify save blocked | No data saved |

#### TC-N17: Default Filter Values Applied on Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Lesson Scheduling tab without any filter params | Class dropdown defaults to first option (id=1) |
| 2 | Check subject filter | Defaults to subject_id=5 |
| 3 | Check academic session filter | Defaults to academic_session_id=7 |
| 4 | Verify data loads with these defaults | Schedule rows filtered by default values |

#### TC-N18: FK lesson_id Undeclared Behavior on Lesson Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create schedule row referencing a lesson | lesson_id populated |
| 2 | Delete the referenced lesson from slb_lessons | Lesson removed |
| 3 | Check schedule row's lesson_id | Behavior depends on DB constraint (SET NULL or error); document actual behavior |

#### TC-N19: DB Save Error → HTTP 500

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Mock a database failure during save (e.g., via DB::rollback or connection error) | DB write fails |
| 2 | Click Save | Save request sent |
| 3 | Verify HTTP 500 response | "Error saving scheduling: {message}" returned |
| 4 | Verify data NOT saved | No changes persisted |

#### TC-N20: schedule_id Exists Validation — Silent Skip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send save request with row containing non-existent schedule_id (e.g., 99999) | Request processed |
| 2 | Verify row silently skipped | No error; remaining valid rows saved |
| 3 | DB check: only valid rows updated | Invalid schedule_id row ignored |

---

### 6.3 Dependency TC Steps

#### TC-D01: Sequencing → Scheduling Data Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Lesson Sequencing tab, save a sequence for Class A/Subject X | Sequence saved |
| 2 | Navigate to Lesson Scheduling tab, select same Class A/Subject X | All sequenced topics appear with correct ordinals |

---

#### TC-D02: Batch Save → Periods Allocation Sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save 3 rows with dates: Jul 15-17, Jul 17-18, Jul 20-21 | Save succeeds |
| 2 | Query allocation table | Records for Jul 15, 16, 17, 18, 20, 21 (6 records) |
| 3 | Verify Jul 17 exists (both rows cover it) | Single record for Jul 17 (updateOrCreate) |

---

#### TC-D03: Auto-Schedule → Periods Allocation Sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run auto-schedule, then save | Allocation records created |
| 2 | Verify dates match auto-schedule output | Allocation dates = scheduled dates |

---

#### TC-D04: Lock State Persists After Page Reload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lock a row via toggle | is_locked=1 |
| 2 | Refresh the page | Row still shows locked state |
| 3 | DB check: is_locked=1 | Persisted |

---

#### TC-D05: Lock Does Not Block Date Planning Grid Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lock a row in scheduling | is_locked=1 |
| 2 | Go to Lesson Date Planning grid for same row | Card editable |
| 3 | Change dates on card and save | AJAX succeeds (separate endpoint, no lock check) |

---

#### TC-D06: Overlapping Date Saves Use updateOrCreate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save dates Jul 15-18 | Allocation records created |
| 2 | Save same dates Jul 15-18 again | updateOrCreate updates existing |
| 3 | Count: SELECT COUNT(*) FROM slb_syllabus_periods_allocation WHERE date BETWEEN '2026-07-15' AND '2026-07-18' | 4 records (no duplicates) |

---

#### TC-D07: Class Teacher Auto-Resolve Fallback Chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_teacher_id=user_id_of_teacher in ClassSection | Teacher resolved via user_id |
| 2 | Save sequencing | assigned_teacher_id set to that Employee |
| 3 | Remove class_teacher_id | No mapping |
| 4 | Save sequencing for new class+section | No teacher auto-assigned |

---

#### TC-D08: Settings Depth Change Affects Visible Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set estimation level to "mini_topic" | Config saved |
| 2 | Reload scheduling tab | Columns: Lesson, Topic, Sub-Topic, Mini-Topic |
| 3 | Change to "topic" | Only Lesson, Topic columns |

---

#### TC-D09: Delete Schedule → Row Silently Skipped On Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open scheduling tab (schedule_ids loaded) | Rows visible |
| 2 | In another session, delete schedule_id=5 | Record deleted |
| 3 | Save all rows | find(5)=null → continue silently |
| 4 | Check response | Success (no error for deleted row) |

---

#### TC-D10: Auto-Schedule Cumulative Offset Correctness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Row1: 3 periods, Row2: 4 periods, Row3: 2 periods, ppd=2 | Data ready |
| 2 | Run auto-schedule | |
| 3 | Row1: start_offset=floor(0/2)=0, end_offset=ceil(3/2)-1=1 | Jul 1 - Jul 2 |
| 4 | Row2: start_offset=floor(3/2)=1, end_offset=ceil(7/2)-1=3 | Jul 2 - Jul 4 |
| 5 | Row3: start_offset=floor(7/2)=3, end_offset=ceil(9/2)-1=4 | Jul 4 - Jul 5 |

---

#### TC-D11: Lesson Scheduling Form Open — ENUM Field Validation — priority

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Lesson Scheduling tab and inspect the priority column for any row | Priority values displayed as badges (HIGH/MEDIUM/LOW) |
| 2 | Attempt to set a priority value that is not HIGH, MEDIUM, or LOW via API call | Validation rejects invalid values |
| 3 | Send a save payload with priority="URGENT" on a row | HTTP 500 or row skipped with validation error |
| 4 | Send a save payload with priority="high" (lowercase) | Case-sensitive validation rejects if not exact match |
| 5 | Send a save payload with priority=null or empty | Rejected or defaults to existing value |
| 6 | Send a save payload with priority="" (empty string) | Validation rejects empty string |

---

#### TC-D12: FK SET NULL — assigned_teacher_id Teacher Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a schedule record that has assigned_teacher_id set to a valid employee ID | Record exists with assigned_teacher_id = X |
| 2 | Note the employee ID referenced | Employee X is active teacher |
| 3 | Delete the referenced employee (sch_employees.id = X) | Teacher deleted |
| 4 | Query: SELECT assigned_teacher_id FROM slb_syllabus_schedule WHERE id = {id} | assigned_teacher_id is NULL (SET NULL behavior) |
| 5 | Verify other fields remain intact | All other columns unchanged |
| 6 | Repeat the same test for taught_by_teacher_id FK | taught_by_teacher_id also SET NULL |

---

#### TC-D13: Multi-FK Dependency — 5 Foreign Keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a schedule record with all 5 FK columns populated | Record has academic_session_id, class_id, section_id, subject_id, topic_id |
| 2 | Delete the parent record from sch_org_academic_sessions_jnt (academic_session_id) | Schedule record deleted (CASCADE) |
| 3 | Create a new record and delete parent from sch_classes (class_id) | Schedule record deleted (CASCADE) |
| 4 | Create a new record and delete parent from sch_sections (section_id) | Schedule record deleted (CASCADE) |
| 5 | Create a new record and delete parent from sch_subjects (subject_id) | Schedule record deleted (CASCADE) |
| 6 | Create a new record and delete parent from slb_topics (topic_id) | Schedule record deleted (CASCADE) |
| 7 | Verify that deleting any one of the 5 parent records cascades the schedule deletion | No orphaned records remain |

---

#### TC-CR01: Model — Table Name And Fillable Attributes Match DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SyllabusSchedule` model file | Model exists in `Modules\Syllabus\Models` |
| 2 | Check `$table` property | `'slb_syllabus_schedule'` |
| 3 | Check `$fillable` array | Contains all 20 fields: academic_session_id, class_id, section_id, subject_id, lesson_id, topic_id, topic_level_type_id, assigned_teacher_id, taught_by_teacher_id, ordinal, planned_periods, priority, scheduled_start_date, scheduled_end_date, is_active, is_locked, is_completed, completed_at, completed_by |
| 4 | Cross-reference with `slb_syllabus_schedule` migration/DDL | Every DDL column has a matching fillable entry |
| 5 | Verify no extra fillable fields exist | All 20 fields correspond to actual DB columns |

---

#### TC-CR02: Model — $casts For Boolean And Integer Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SyllabusSchedule` model `$casts` array | `is_active => 'boolean'`, `is_locked => 'boolean'`, `is_completed => 'boolean'` |
| 2 | Check integer casts | `planned_periods => 'integer'`, `ordinal => 'integer'` |
| 3 | Retrieve a record and access `is_active` | Returns `true`/`false` (not 1/0) |
| 4 | Retrieve a record and access `planned_periods` | Returns integer (not string) |
| 5 | Set `is_locked = true` and save | DB stores 1; re-read returns `true` |

---

#### TC-CR03: Model — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SyllabusSchedule` model `use` statements | `SoftDeletes` trait imported and used |
| 2 | Query: `SyllabusSchedule::all()` | Returns only non-deleted records |
| 3 | Delete a record via `->delete()` | `deleted_at` populated with timestamp |
| 4 | Query: `SyllabusSchedule::withTrashed()->find($id)` | Record returned with non-null `deleted_at` |
| 5 | Query: `SyllabusSchedule::onlyTrashed()->get()` | Only soft-deleted records returned |
| 6 | Call `->restore()` on trashed record | `deleted_at` set to null |
| 7 | Call `->forceDelete()` on record | Record permanently removed from DB |

---

#### TC-CR04: Model — BelongsTo Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SyllabusSchedule` model relationship methods | `belongsTo(Lesson::class)`, `belongsTo(Topic::class)`, `belongsTo(TopicLevelType::class)`, `belongsTo(Employee::class, 'assigned_teacher_id')`, `belongsTo(AcademicSession::class)`, `belongsTo(SchoolClass::class, 'class_id')`, `belongsTo(Section::class)`, `belongsTo(Subject::class)` |
| 2 | Check `assignedTeacher()` method | Uses `'assigned_teacher_id'` foreign key; class `Employee` |
| 3 | Access `$schedule->lesson` on a record | Returns related `Lesson` model instance |
| 4 | Access `$schedule->assignedTeacher` | Returns `Employee` or `null` |
| 5 | Verify foreign key column names match relationship definitions | Each `belongsTo` second arg matches actual FK column |

---

#### TC-CR05: Controller — store() Creates Record With Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send `POST` to `syllabus-schedule` with valid fillable data | HTTP 201 or 200 |
| 2 | Query `slb_syllabus_schedule` for the new record | Record exists with all submitted values |
| 3 | Check `activity_log` table | Entry with `causer_id` = auth user, `description` contains "created" or "store", `subject_type` = `SyllabusSchedule` |
| 4 | Call same `POST` without required fields | HTTP 500 validation error |
| 5 | Verify `created_at` and `updated_at` are populated | Timestamps set |

---

#### TC-CR06: Controller — update() Modifies Record With Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send `PUT/PATCH` to `syllabus-schedule/{id}` with updated fields | HTTP 200 |
| 2 | Query the record | Fields updated to new values |
| 3 | Check `activity_log` table | Entry with `description` containing "updated" for this subject |
| 4 | Send `PUT` with invalid `assigned_teacher_id=99999` | HTTP 500 or rejected |
| 5 | Verify `updated_at` timestamp refreshed | `updated_at` > original `created_at` |

---

#### TC-CR07: Controller — destroy() Sets is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a schedule record with `is_active=true` | Record active |
| 2 | Send `DELETE` to `syllabus-schedule/{id}` | HTTP 200 or 204 |
| 3 | Query the record with `withTrashed()` | `is_active=false`, `deleted_at` is non-null |
| 4 | Check `is_active` was set to `false` **before** `deleted_at` was set | Both conditions true |
| 5 | Check `activity_log` table | Entry with `description` containing "deleted" |
| 6 | Query without `withTrashed()` | Record not returned in normal queries |

---

#### TC-CR08: Controller — toggleStatus() Flips is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record has `is_active=true` | Active |
| 2 | Send `POST` to `syllabus-schedule/{id}/toggle-status` | HTTP 200 |
| 3 | Re-read record from DB | `is_active=false` |
| 4 | Send same request again | `is_active=true` (toggled back) |
| 5 | Check response JSON | `{ success: true, is_active: <new_value> }` |
| 6 | Verify 403 if user lacks `tenant.syllabus-schedule.status` | Gate denies |

---

#### TC-CR09: Controller — trashed()/restore()/forceDelete() Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a schedule record via `DELETE` endpoint | Record has `deleted_at` set |
| 2 | Send `GET` to `syllabus-schedule/trashed` | Response lists only soft-deleted records |
| 3 | Send `POST` to `syllabus-schedule/{id}/restore` | HTTP 200; `deleted_at` nullified |
| 4 | Query record normally | Record returned (no longer trashed) |
| 5 | Soft-delete the record again, then send `DELETE` to `syllabus-schedule/{id}/force-delete` | HTTP 200 |
| 6 | Query with `withTrashed()` | Record permanently gone |
| 7 | Check `activity_log` for restore and forceDelete events | Entries recorded for each action |

---

#### TC-CR10: Controller — markComplete() Sets Completion Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record has `is_completed=false`, `completed_at=null`, `completed_by=null` | Incomplete |
| 2 | Send `POST` to `syllabus-schedule/{id}/mark-complete` | HTTP 200 |
| 3 | Re-read record | `is_completed=true`, `completed_at` is a Carbon timestamp, `completed_by` = auth user's ID |
| 4 | Send same request again | `is_completed` flips to `false` or stays `true` per toggle logic |
| 5 | Check `activity_log` | Entry with description containing "marked complete" |
| 6 | Verify 403 if user lacks permission | Gate enforces authorization |

---

#### TC-CR11: Controller — getTopicsAjax() Returns Topics JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a Lesson has multiple Topics in DB | Topics exist |
| 2 | Send `GET` to `syllabus-schedule/get-topics-ajax?lesson_id={id}` | HTTP 200 |
| 3 | Check response `Content-Type` header | `application/json` |
| 4 | Verify response body is array of topics | Each item has `id`, `name`, `topic_level_type_id` |
| 5 | Send `GET` without `lesson_id` parameter | HTTP 500 or empty array |
| 6 | Send `GET` with non-existent `lesson_id=99999` | Empty JSON array `[]` |

---

#### TC-CR12: Policy — All 8 Methods Defined And Gated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SyllabusSchedulePolicy` file | Class exists in `Policies` directory |
| 2 | Check method signatures | `viewAny(User)`, `view(User, SyllabusSchedule)`, `create(User)`, `update(User, SyllabusSchedule)`, `delete(User, SyllabusSchedule)`, `restore(User, SyllabusSchedule)`, `forceDelete(User, SyllabusSchedule)`, `status(User, SyllabusSchedule)` |
| 3 | Verify each method returns `true`/`false` or calls `Gate::authorize(...)` | Each method has a guard |
| 4 | Map each method to its permission string | `tenant.syllabus-schedule.{action}` naming convention |
| 5 | Check `AuthServiceProvider` or policy auto-discovery | Policy registered or auto-discovered for `SyllabusSchedule` model |

---

#### TC-CR13: Request — SyllabusScheduleRequest Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SyllabusScheduleRequest` file | Class exists in `Http\Requests` |
| 2 | Check `authorize()` method | Returns true or calls `Gate::authorize('tenant.syllabus-schedule.*')` |
| 3 | Check `rules()` method | Rules defined for: academic_session_id (required,integer,exists), class_id (required,integer,exists), section_id (required,integer,exists), subject_id (required,integer,exists), lesson_id (required,integer,exists), topic_id (required,integer,exists), assigned_teacher_id (nullable,integer,exists), ordinal (required,integer), planned_periods (required,integer,min:0), priority (required,string,in:HIGH,MEDIUM,LOW), scheduled_start_date (nullable,date), scheduled_end_date (nullable,date), is_active (boolean), is_locked (boolean) |
| 4 | Verify `exists` rules reference correct tables | e.g., `exists:slb_lessons,id`, `exists:employees,id` |
| 5 | Submit invalid payload targeting each rule | Each violation returns HTTP 500 with field-specific error |

---

#### TC-CR14: Routes — Resource + Extra Routes Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --path=syllabus-schedule` | All routes listed |
| 2 | Check resource routes | `GET|HEAD syllabus-schedule` (index), `GET syllabus-schedule/create` (create), `POST syllabus-schedule` (store), `GET syllabus-schedule/{syllabus_schedule}` (show), `GET syllabus-schedule/{syllabus_schedule}/edit` (edit), `PUT|PATCH syllabus-schedule/{syllabus_schedule}` (update), `DELETE syllabus-schedule/{syllabus_schedule}` (destroy) |
| 3 | Check extra routes | `GET syllabus-schedule/trashed` (trashed), `POST syllabus-schedule/{syllabus_schedule}/restore` (restore), `DELETE syllabus-schedule/{syllabus_schedule}/force-delete` (forceDelete), `POST syllabus-schedule/{syllabus_schedule}/toggle-status` (toggleStatus), `POST syllabus-schedule/{syllabus_schedule}/mark-complete` (markComplete), `GET syllabus-schedule/get-topics-ajax` (getTopicsAjax) |
| 4 | Verify all routes have named route helpers | e.g., `route('syllabus-schedule.index')` works |
| 5 | Check middleware applied | All routes have `auth` + `tenant` middleware |

---

#### TC-CR15: Authorization — Gate::authorize() In Every Controller Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SyllabusScheduleController` file | Class in `Http\Controllers` |
| 2 | Scan every public method for `Gate::authorize()` call | `index()` → `Gate::authorize('tenant.syllabus-schedule.viewAny')`, `store()` → `Gate::authorize('tenant.syllabus-schedule.create')`, `show()` → `Gate::authorize('tenant.syllabus-schedule.view')`, `update()` → `Gate::authorize('tenant.syllabus-schedule.update')`, `destroy()` → `Gate::authorize('tenant.syllabus-schedule.delete')`, `trashed()` → `Gate::authorize('tenant.syllabus-schedule.viewAny')`, `restore()` → `Gate::authorize('tenant.syllabus-schedule.restore')`, `forceDelete()` → `Gate::authorize('tenant.syllabus-schedule.forceDelete')`, `toggleStatus()` → `Gate::authorize('tenant.syllabus-schedule.status')`, `markComplete()` → `Gate::authorize('tenant.syllabus-schedule.update')`, `getTopicsAjax()` → `Gate::authorize('tenant.syllabus-schedule.viewAny')` |
| 3 | Verify no public method lacks authorization | Every method has a gate check before business logic |
| 4 | Check permission strings match policy methods | String after last dot corresponds to policy method name |
| 5 | Verify `__construct` does not use `$this->authorizeResource()` excessively | No duplicate authorization |

