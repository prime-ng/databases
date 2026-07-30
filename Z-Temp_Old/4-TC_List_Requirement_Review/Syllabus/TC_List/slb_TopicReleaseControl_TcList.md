# slb_topic_release_control_TcList

## Module: Syllabus → Planning → Topic Release Control

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Planning |
| Feature | Topic Release Control |
| URL(s) | `GET /syllabus/planning?tab=topic_release_control` (display), `POST /topics/{id}/toggle-release` (AJAX toggle) |
| Controller | `SyllabusController@planning()` (tab render, lines 212-351), `TopicController@toggleReleaseStatus()` (AJAX toggle, line 670) |
| Service | `Modules\Syllabus\Services\TopicReleaseControlService` — `syncAllocation()`, `syncHomeworkPublic()`, `syncQuizPublic()`, `syncQuestPublic()`, `getLessonStats()` |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` (primary), `Lesson`, `Topic`, `TopicLevelType` |
| Validation | Inline `$request->validate()` in `toggleReleaseStatus()` |
| Permissions | `tenant.lesson.viewAny` (view), `tenant.topic.update` (toggle) |
| Default Release Type | `homework` |
| View | `resources/views/lesson-management/partials/topic-release-control/index.blade.php` |
| Cron Command | `php artisan tenant:syllabus:release-resources` |

---

## 2. Pre-conditions

- Required permissions: `tenant.lesson.viewAny` (view), `tenant.topic.update` (AJAX toggle)
- Required seed data: `SyllabusSchedule` records with topic hierarchy
- `SchConfig` records for `homework_released_on_syllabus_level`, `quiz_released_on_syllabus_level`, `quest_released_on_syllabus_level`
- External module records: `Homework`/`HomeworkAssignment`, `Quiz`/`QuizAllocation`, `QuestScope`/`QuestAllocation`
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---



---

## 3. Default Data Load

When the page loads via SyllabusController@planning() (GET /syllabus/planning) with tab=topic_release_control, default filters: class_section_id=1, subject_id=5, academic_session_id=7, release_type=homework.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: dropdowns | planning() | Same as LessonSequencing (classes, sections, classSections, subjects, academicSessions) | --- | None |
| Release Control Grid | planning() | SyllabusSchedule::with(lesson,topic,topicLevelType,topic.parent+parent.parent) OR buildSequencingFromCrud() | class_id, subject_id, section_id, academic_session_id | None (full collection filtered by level) |
| Cross-module release links | planning() | Homework::where(class_id,subject_id,topic_id) / Quiz::where(scope_topic_id) / QuestScope::where(topic_id) | release_type (homework/quiz/quest) | None (.exists() checks) |
| Duration Level | planning() | SchConfig::whereIn(key) homework/quiz/quest_released_on_syllabus_level | 4 config keys | None |
## 4. Test Data Strategy

- **Schedule data**: Pre-create schedule records at multiple hierarchy levels (Topic, Sub-Topic, Mini-Topic)
- **Release settings**: Set different levels for homework/quiz/quest to test depth filtering per type
- **External data**: Create Homework/Quiz/Quest records linked to specific topic IDs
- **Release status**: Set `is_released=1` on some assignments, leave others as 0
- **Pre-test cleanup**: Delete test schedule records and linked resources after tests
- **Unique suffix**: For test data identification
- **Toggle payload**: `{type:"schedule", field:"homework|quiz|quest", is_active:true|false}`

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_syllabus_schedule`

(Same DDL as Lesson Date Planning — see `csm_SlbLessonDatePlanningTcList.md` section 4.1)

### 4.2 Validation Rules — `toggleReleaseStatus()` AJAX

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | type | nullable, in:level,schedule,lesson,sync_all | — |
| BC-VAL-02 | field | nullable, string | "Invalid release field" (if not homework/quiz/quest) |
| BC-VAL-03 | is_active | required, boolean | — |
| BC-VAL-04 | lesson_id | nullable, integer | — |
| BC-VAL-05 | class_id | nullable, integer | — |
| BC-VAL-06 | subject_id | nullable, integer | — |
| BC-VAL-07 | view_mode | nullable, in:grid,list | — |
| BC-VAL-08 | release_date | nullable, date | — |
| BC-VAL-09 | schedule_date | nullable, date | — |
| BC-VAL-10 | result_date | nullable, date | — |

### 4.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lesson.viewAny | planning() tab render | Without → 403 |
| BC-AUTH-02 | tenant.topic.update | toggleReleaseStatus() | Without → 403 |
| BC-AUTH-03 | Guest access | Any route | Redirect to /login |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Tab loads with Homework release type default | Default release type = "homework" |
| BC-BIZ-02 | Release type filter = "Homework" | Reads homework_released_on_syllabus_level config |
| BC-BIZ-03 | Release type filter = "Quiz" | Reads quiz_released_on_syllabus_level config |
| BC-BIZ-04 | Release type filter = "Quest" | Reads quest_released_on_syllabus_level config |
| BC-BIZ-05 | Schedule records exist | Load from SyllabusSchedule with hierarchy walking |
| BC-BIZ-06 | No schedule records exist | Fall back to buildSequencingFromCrud() from Lesson/Topic masters |
| BC-BIZ-07 | Depth filtering | filterRowsByLevel() removes rows deeper than configured release level |
| BC-BIZ-08 | Homework link check | Query Homework::where(class_id, subject_id, topic_id) → pluck ids |
| BC-BIZ-09 | Homework release check | HomeworkAssignment::whereIn(homework_ids)->where(is_released,1)->exists() |
| BC-BIZ-10 | Quiz link check | Quiz::where(scope_topic_id, topicId)->value(id) |
| BC-BIZ-11 | Quiz release check | QuizAllocation::where(quiz_id, id)->where(target_id, classId)->where(is_active,1)->exists() |
| BC-BIZ-12 | Quest link check | QuestScope::where(topic_id, topicId)->pluck(quest_id) |
| BC-BIZ-13 | Quest release check | QuestAllocation::whereIn(quest_ids)->where(target_id, classId)->where(is_active,1)->exists() |
| BC-BIZ-14 | AJAX toggle — valid type | Calls TopicReleaseControlService::syncAllocation() |
| BC-BIZ-15 | AJAX toggle — schedule is_active flipped | Flips schedule.is_active based on request |
| BC-BIZ-16 | Cron auto-release | Iterates tenants, reads configs, releases homework/quiz/quest for schedules where start_date <= today |
| BC-BIZ-17 | Cron: inactive schedule → deactivate | If schedule.is_active=0, calls sync with activate=false |
| BC-BIZ-18 | Hierarchy parent walking | Walks topic.parent chain up to 4 levels to build flat hierarchy row |
| BC-BIZ-19 | Read-only monitoring | No create/update/delete buttons; only AJAX toggle action |
| BC-BIZ-20 | Level matching in cron (fuzzy) | Strips hyphens/underscores, lowercases before comparing |
| BC-BIZ-21 | Screen loads via SyllabusController@planning() at GET /syllabus/planning with tab=topic_release_control | Navigating to GET /syllabus/planning with tab=topic_release_control loads this screen's grid data with correct filters applied |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Topic Release Control Tab Loads With Filters | Tab loads with class/section, subject, release type filter (default=homework) | — | — | ⬜ |
| TC-P02 | Display Release Status Per Topic (Homework View) | Table shows: hierarchy columns, LMS Linked badge, Release Status badge for each topic | — | — | ⬜ |
| TC-P03 | Release Type Filter — Switch To Quiz | Change release type to Quiz → table reloads with Quiz depth level config | — | — | ⬜ |
| TC-P04 | Release Type Filter — Switch To Quest | Change release type to Quest → table reloads with Quest depth level config | — | — | ⬜ |
| TC-P05 | Hierarchy Display Based On Release Level Config | Config=Sub-Topic → shows Lesson, Topic, Sub-Topic columns | — | — | ⬜ |
| TC-P06 | Load Data From Existing Schedule Records | Schedule records exist → data loaded from SyllabusSchedule with hierarchy walk | — | — | ⬜ |
| TC-P07 | Fallback To CRUD When No Schedule Records | No schedule records → buildSequencingFromCrud() builds rows from masters | — | — | ⬜ |
| TC-P08 | Depth Filter — Sub-Topic Level Hides Deeper Rows | Release level=sub_topic → Mini/Micro/Nano rows hidden | — | — | ⬜ |
| TC-P09 | Depth Filter — Mini-Topic Level Shows Deeper Rows | Release level=mini_topic → Mini rows visible, Micro/Nano hidden | — | — | ⬜ |
| TC-P10 | LMS Linked = Yes (Homework Exists) | Topic has homework linked → green "Yes" badge | — | — | ⬜ |
| TC-P11 | LMS Linked = No (No Homework) | Topic has no homework → gray "No" badge | — | — | ⬜ |
| TC-P12 | Release Status = Released | HomeworkAssignment.is_released=1 → green "Released" badge | — | — | ⬜ |
| TC-P13 | Release Status = Pending | Homework exists but not released → amber "Pending" badge | — | — | ⬜ |
| TC-P14 | AJAX Toggle — Toggle Homework Release | POST /topics/{id}/toggle-release with {type:"schedule", field:"homework", is_active:true} → success | — | — | ⬜ |
| TC-P15 | AJAX Toggle — Toggle Quiz Release | POST with field:"quiz" → success | — | — | ⬜ |
| TC-P16 | AJAX Toggle — Toggle Quest Release | POST with field:"quest" → success | — | — | ⬜ |
| TC-P17 | Quiz Linked — Scope Topic ID Matches | Quiz::where(scope_topic_id) finds record → Yes badge | — | — | ⬜ |
| TC-P18 | Quiz Released — Allocation Active | QuizAllocation::where(is_active,1) exists → Released badge | — | — | ⬜ |
| TC-P19 | Quest Linked — QuestScope Found | QuestScope::where(topic_id) finds records → Yes badge | — | — | ⬜ |
| TC-P20 | Quest Released — Allocation Active | QuestAllocation::where(is_active,1) exists → Released badge | — | — | ⬜ |
| TC-P21 | Hierarchy Walking — Topic → Sub-Topic → Mini-Topic | Walking topic.parent 3 levels deep shows correct hierarchy in columns | — | — | ⬜ |
| TC-P22 | Class/Section Filter | Select class+section → only that scope's topics shown | — | — | ⬜ |
| TC-P23 | Subject Filter | Select subject → only that subject's topics shown | — | — | ⬜ |
| TC-P24 | Default Release Type = homework | Tab loads with homework filter selected by default | — | — | ⬜ |
| TC-P25 | Read-Only — No Create/Edit/Delete Buttons | Table shows only view/toggle actions | — | — | ⬜ |
| TC-P26 | Cron Sync Updates Release Status | Run cron → schedules with start_date <= today get resources released | — | — | ⬜ |
| TC-P27 | Filter By Release Status | Filter for Released/Pending/Not Linked → matching rows only | — | — | ⬜ |
| TC-P28 | Default config when SchConfig not set — release level defaults to topic | No SchConfig record → system defaults to topic level, shows only root-level topics | — | — | ⬜ |
| TC-P29 | Config snake_case normalization — stored as "Mini-Topic" resolves to mini_topic | Set config = "Mini-Topic" → filter normalizes to mini_topic, Mini level rows visible | — | — | ⬜ |
| TC-P30 | Depth filter nano_topic — all rows visible | Config = nano_topic → grid shows all hierarchy levels including Nano | — | — | ⬜ |
| TC-P31 | Depth filter micro_topic — Micro rows visible, Nano hidden | Config = micro_topic → Micro rows shown, Nano rows hidden | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | View Without Permission (No viewAny) | User without tenant.lesson.viewAny → HTTP 403 | — | — | ⬜ |
| TC-N02 | Toggle Without Permission (No topic.update) | User without tenant.topic.update → HTTP 403 | — | — | ⬜ |
| TC-N03 | Guest Access Redirect | Not logged in → redirect to /login | — | — | ⬜ |
| TC-N04 | Invalid Toggle Field | POST with field="invalid" → 400: "Invalid release field" | — | — | ⬜ |
| TC-N05 | Missing is_active In Toggle | POST without is_active → HTTP 500 validation error | — | — | ⬜ |
| TC-N06 | No Schedule Records — Fallback Shows No Status | Fallback to CRUD build → badges show default "No" and "Pending" | — | — | ⬜ |
| TC-N07 | No LMS Resources Created | No homework/quiz/quest linked → all rows show "No" | — | — | ⬜ |
| TC-N08 | Toggle On Non-Existent Schedule | POST to /topics/99999/toggle-release → 404 | — | — | ⬜ |
| TC-N09 | Invalid Release Type In Filter | Set release_type="invalid" → gracefully handled or ignored | — | — | ⬜ |
| TC-N10 | XSS In Topic Name | Script in topic name → Blade escapes, no execution | — | — | ⬜ |
| TC-N11 | Toggle service — no homework linked to schedule | Toggle homework release on schedule with no ON_TOPIC_COMPLETE homework → response: success=false, "No ON_TOPIC_COMPLETE homework linked to this schedule." | — | — | ⬜ |
| TC-N12 | Toggle service — no quiz linked to topic | Toggle quiz release on topic with no quiz → response: success=false, "No quiz found linked to this topic." | — | — | ⬜ |
| TC-N13 | Toggle service — no quest linked to topic | Toggle quest release on topic with no quest → response: success=false, "No quests found for this topic." | — | — | ⬜ |
| TC-N14 | Validation — field nullable not tested | Submit toggle without field parameter → validation error | — | — | ⬜ |
| TC-N15 | Validation — lesson_id nullable integer invalid | Submit toggle with lesson_id="abc" → validation error | — | — | ⬜ |
| TC-N16 | Validation — view_mode invalid | Submit toggle with view_mode="chart" → validation error (must be grid or list) | — | — | ⬜ |
| TC-N17 | Validation — release_date invalid format | Submit toggle with release_date="not-a-date" → validation error | — | — | ⬜ |
| TC-N18 | Level mismatch after config change — existing releases remain active | Change config from sub_topic to topic → sub-level rows hidden but linked homework/quiz still released | — | — | ⬜ |
| TC-N19 | Default filter values not applied on load | Load tab without filter params → defaults to class_section_id=1, subject_id=5 | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Homework Release Level Setting Affects Display | Change homework level → topic release shows different depth | — | — | ⬜ |
| TC-D02 | B | Lesson Scheduling Dates Drive Cron Release | Set scheduled_start_date=today → cron picks up and releases | — | — | ⬜ |
| TC-D03 | C | Settings → Topic Release Control Depth | All 3 release level configs independently control their filter depth | — | — | ⬜ |
| TC-D04 | D | Toggle Cascades To Children | Toggle release for parent → children also updated (service method) | — | — | ⬜ |
| TC-D05 | E | Cron: Active Schedule → Activate Resources | is_active=1 → cron calls sync with activate=true | — | — | ⬜ |
| TC-D06 | F | Cron: Inactive Schedule → Deactivate Resources | is_active=0 → cron calls sync with activate=false | — | — | ⬜ |
| TC-D07 | G | Level Matching Is Case/Format Insensitive | "Sub-Topic" matches "sub_topic" in cron level matching | — | — | ⬜ |
| TC-D08 | H | Schedule ID Not Found In Toggle → 404 | Deleted schedule → toggle returns 404 | — | — | ⬜ |
| TC-D09 | I | syncAllocation Flips is_active | Service method toggles schedule.is_active correctly | — | — | ⬜ |
| TC-D10 | J | getLessonStats Returns Summary | Service method returns stats on linked/released counts per lesson | — | — | ⬜ |
| TC-D11 | K | Three release type filters (homework/quiz/quest) change displayed rows | Release Type Filter — `release_type` dropdown | — | — | ⬜ |
| TC-D12 | L | Toggle release uses different permission than view | Toggle Permission — `tenant.topic.update` | — | — | ⬜ |
| TC-D13 | M | Toggle validates is_active as required boolean | Toggle Validation — `is_active required|boolean` | — | — | ⬜ |
| TC-D14 | N | Toggle with invalid type returns 500 | Type Validation — `in:level,schedule,lesson,sync_all` | — | — | ⬜ |
| TC-D15 | O | Fallback to CRUD data when no Schedule records exist | Fallback Data — `buildSequencingFromCrud()` | — | — | ⬜ |
| TC-D16 | P | Homework link query checks class_id + subject_id + topic_id | Homework Linked Check — cross-module query | — | — | ⬜ |
| TC-D17 | Q | Quiz link query checks scope_topic_id | Quiz Linked Check — cross-module query | — | — | ⬜ |
| TC-D18 | R | Quest link query checks QuestScope topic_id | Quest Linked Check — cross-module query | — | — | ⬜ |
| TC-D19 | S | Screen has no create/edit/delete buttons | Read-Only Display — monitoring only | — | — | ⬜ |
| TC-D20 | T | Homework release check queries HomeworkAssignment.is_released=1 | Homework Release Status — assignment existence | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Planning tabs are wrapped by @can('tenant.lesson.viewAny'); users without viewAny permission cannot see Planning section | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.planning` key → `'syllabus/planning'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |


---



## 7. Detailed Test Steps



#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open topic-release-control partial blade for this screen | View file found in lesson-management/partials/topic-release-control/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Load report with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR01: Blade @can Directives — Permission-based Tab Visibility via viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect planning/index.blade.php | Tab is conditionally rendered via @can('tenant.lesson.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.lesson.viewAny'
| 3 | Log in as user with viewAny permission | Topic Release Control tab visible in Planning section |
| 4 | Log in as user without viewAny permission | Topic Release Control tab hidden; user cannot access Planning section |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.planning' key exists | Config has 'syllabus.planning' => 'syllabus/planning' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/planning' correctly references Planning tab view
| 4 | Load the screen via the Planning tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Planning tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Topic Release Control Tab Loads With Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin, navigate to Planning → Topic Release Control | Tab loads at /planning?tab=topic_release_control |
| 2 | Check filter area | Class/Section dropdown, Subject dropdown, Release Type dropdown (default: Homework) |
| 3 | Check Apply button | Present |

---

#### TC-P02: Display Release Status Per Topic (Homework View)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class+section, subject, release type=Homework | Table loads |
| 2 | Check hierarchy columns | Lesson, Topic (and deeper based on config) |
| 3 | Check LMS Linked column | Green "Yes" or gray "No" badge per row |
| 4 | Check Release Status column | Green "Released" or amber "Pending" badge |

---

#### TC-P03: Release Type Filter — Switch To Quiz

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change release type dropdown to "Quiz" | Page reloads |
| 2 | Verify release type = Quiz | Filter shows "Quiz" |
| 3 | Check depth level | Based on quiz_released_on_syllabus_level config |

---

#### TC-P04: Release Type Filter — Switch To Quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change release type to "Quest" | Page reloads |
| 2 | Verify depth level | Based on quest_released_on_syllabus_level config |

---

#### TC-P05: Hierarchy Display Based On Release Level Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set homework_released_on_syllabus_level = "sub_topic" | Config saved |
| 2 | Reload Topic Release Control, release type = Homework | Columns: Lesson, Topic, Sub-Topic |
| 3 | Change to "mini_topic" | Columns: Lesson, Topic, Sub-Topic, Mini-Topic |

---

#### TC-P06: Load Data From Existing Schedule Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure schedule records exist for selected filters | Records exist |
| 2 | Load tab | Rows loaded from SyllabusSchedule table |
| 3 | Verify hierarchy parent walking | Each row shows correct parent hierarchy |

---

#### TC-P07: Fallback To CRUD When No Schedule Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select filters with no schedule records | No schedule data |
| 2 | Click Apply | Falls back to buildSequencingFromCrud() |
| 3 | Verify table shows rows from Lesson/Topic masters | Hierarchy displayed |
| 4 | Check LMS Linked column | All rows show "No" (no data to query) |

---

#### TC-P08: Depth Filter — Sub-Topic Level Hides Deeper Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set release level = "sub_topic" | Config saved |
| 2 | Load tab | Sub-topic rows visible |
| 3 | Verify no Mini-Topic, Micro-Topic, Nano-Topic rows | Hidden |

---

#### TC-P09: Depth Filter — Mini-Topic Level Shows Deeper Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set release level = "mini_topic" | Config saved |
| 2 | Load tab | Mini-topic rows visible |
| 3 | Verify Micro-Topic and Nano-Topic rows (if exist) | Hidden |

---

#### TC-P10: LMS Linked = Yes (Homework Exists)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Homework record linked to topic_id=T1, class_id=C1, subject_id=S1 | Record exists |
| 2 | Load tab with class=C1, subject=S1, release=Homework | Row for topic T1 shows green "Yes" badge |

---

#### TC-P11: LMS Linked = No (No Homework)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure topic T2 has no homework linked | No records |
| 2 | Load tab | Row for topic T2 shows gray "No" badge |

---

#### TC-P12: Release Status = Released

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HomeworkAssignment with homework_id for topic, is_released=1 | Released |
| 2 | Load tab | Green "Released" badge |

---

#### TC-P13: Release Status = Pending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HomeworkAssignment with is_released=0 | Not released |
| 2 | Load tab | Amber "Pending" badge |

---

#### TC-P14: AJAX Toggle — Toggle Homework Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click toggle button for a schedule | AJAX POST to /topics/{id}/toggle-release |
| 2 | Send {type:"schedule", field:"homework", is_active:true} | Request sent |
| 3 | Check response | { success: true, message: "Schedule release status updated." } |
| 4 | DB check: schedule.is_active | Flipped to true |

---

#### TC-P15: AJAX Toggle — Toggle Quiz Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with field:"quiz", is_active:true | Success |
| 2 | Verify service called | syncAllocation() runs for quiz type |

---

#### TC-P16: AJAX Toggle — Toggle Quest Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with field:"quest", is_active:true | Success |
| 2 | Verify | syncAllocation() runs for quest type |

---

#### TC-P17: Quiz Linked — Scope Topic ID Matches

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quiz with scope_topic_id=T1 | Quiz exists |
| 2 | Load tab, release=Quiz | Row for T1 shows "Yes" in LMS Linked |

---

#### TC-P18: Quiz Released — Allocation Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuizAllocation with quiz_id, target_id=classId, is_active=1 | Active allocation |
| 2 | Load tab | "Released" badge shown |

---

#### TC-P19: Quest Linked — QuestScope Found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuestScope with topic_id=T1 | Scope exists |
| 2 | Load tab, release=Quest | "Yes" badge shown |

---

#### TC-P20: Quest Released — Allocation Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuestAllocation with quest_id, target_id=classId, is_active=1 | Active |
| 2 | Load tab | "Released" badge |

---

#### TC-P21: Hierarchy Walking — Topic → Sub-Topic → Mini-Topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create hierarchy: Root Topic → Sub-Topic A → Mini-Topic A1 | 3-level hierarchy |
| 2 | Create schedule for Mini-Topic A1 | Schedule record exists |
| 3 | Load tab with mini_topic depth | Row shows: Lesson → Root Topic → Sub-Topic A → Mini-Topic A1 |

---

#### TC-P22: Class/Section Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A / Section 1 | Only Class A/Sec 1 topics shown |
| 2 | Change to Class B / Section 2 | Only Class B/Sec 2 topics shown |

---

#### TC-P23: Subject Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Subject X | Only Subject X topics shown |
| 2 | Change to Subject Y | Only Subject Y topics shown |

---

#### TC-P24: Default Release Type = homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Topic Release Control tab without release_type param | Release type defaults to "Homework" |
| 2 | Verify dropdown shows "Homework" | Correct default |

---

#### TC-P25: Read-Only — No Create/Edit/Delete Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load tab | No "Add", "Edit", or "Delete" buttons visible |
| 2 | Check action column | Only toggle button present (if permission allows) |

---

#### TC-P26: Cron Sync Updates Release Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set schedule with start_date <= today, is_active=1 | Schedule ready for release |
| 2 | Run php artisan tenant:syllabus:release-resources | Cron executes |
| 3 | Check release status | Resources released for matching schedules |

---

#### TC-P27: Filter By Release Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add a filter for release status = "Released" | Only released rows shown |
| 2 | Change to "Pending" | Only pending rows shown |
| 3 | Change to "Not Linked" | Only rows without LMS resources shown |

---

### 6.2 Negative TC Steps

#### TC-N01: View Without Permission (No viewAny)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.lesson.viewAny | Dashboard |
| 2 | Navigate to planning tab | HTTP 403 |

---

#### TC-N02: Toggle Without Permission (No topic.update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with viewAny but not topic.update | Can view but not toggle |
| 2 | Click toggle button | HTTP 403 Forbidden |

---

#### TC-N03: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to /planning | Redirect to /login |

---

#### TC-N04: Invalid Toggle Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST field="invalid" | Response: { success: false, message: "Invalid release field" } |

---

#### TC-N05: Missing is_active In Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without is_active | HTTP 500: "The is active field is required." |

---

#### TC-N06: No Schedule Records — Fallback Shows No Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select filters with no schedule records | Fallback to CRUD |
| 2 | Check LMS Linked column | All rows show "No" (no schedule to query from) |

---

#### TC-N07: No LMS Resources Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no Homework records exist for selected scope | No resources |
| 2 | Load Homework release view | All rows show "No" in LMS Linked |
| 3 | All rows show "Pending" in Release Status | Pending |

---

#### TC-N08: Toggle On Non-Existent Schedule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to /topics/99999/toggle-release | HTTP 404 |

---

#### TC-N09: Invalid Release Type In Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set release_type="invalid" in URL | System gracefully handles or defaults to homework |

---

#### TC-N10: XSS In Topic Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Topic name contains <script>alert('xss')</script> | Stored as literal |
| 2 | View in table | Blade escapes; no execution |

---

### 6.3 Dependency TC Steps

#### TC-D01: Homework Release Level Setting Affects Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set homework_released_on_syllabus_level = "topic" | Config saved |
| 2 | Load Topic Release control, Homework view | Shows only root topics |
| 3 | Change to "mini_topic" | Shows mini-topic rows |

---

#### TC-D02: Lesson Scheduling Dates Drive Cron Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set scheduled_start_date = today on a schedule | Schedule due for release |
| 2 | Run release cron | Resources auto-released |
| 3 | Check release status | Changed to "Released" |

---

#### TC-D03: Settings → Topic Release Control Depth

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set all 3 release levels to different values | Each independent |
| 2 | Check Homework view | Homework depth level applied |
| 3 | Check Quiz view | Quiz depth level applied |
| 4 | Check Quest view | Quest depth level applied |

---

#### TC-D04: Toggle Cascades To Children

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle release for a parent schedule | Service method syncAllocation() processes children |
| 2 | Verify child schedules also updated | Cascaded |

---

#### TC-D05: Cron: Active Schedule → Activate Resources

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Schedule has is_active=1, start_date <= today | Cron picks it up |
| 2 | Check syncHomeworkPublic called with activate=true | Resources activated |

---

#### TC-D06: Cron: Inactive Schedule → Deactivate Resources

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Schedule has is_active=0 | Cron picks it up |
| 2 | Check sync called with activate=false | Resources deactivated |

---

#### TC-D07: Level Matching Is Case Format Insensitive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DB stores "Sub-Topic" (title-case with hyphen) | Stored |
| 2 | Cron normalizes: remove hyphens, lowercase → "subtopic" | Normalized |
| 3 | Checks schedule level normalized the same way | Match succeeds |

---

#### TC-D08: Schedule ID Not Found In Toggle → 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete schedule with ID=5 | Record gone |
| 2 | POST to /topics/5/toggle-release | HTTP 404 |

---

#### TC-D09: syncAllocation Flips is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Schedule has is_active=false | Not active |
| 2 | Call syncAllocation(id, 'homework', true) | Service flips is_active to true |

---

#### TC-D10: getLessonStats Returns Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call TopicReleaseControlService::getLessonStats($classId, $subjectId) | Returns array with counts per lesson |
| 2 | Check structure | { lesson_id: { total: N, linked: M, released: K } } |

---

#### TC-D11: Three Release Type Filters Change Displayed Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set homework_released_on_syllabus_level = "topic", quiz = "sub_topic", quest = "mini_topic" | Config saved for each release type |
| 2 | Load tab with release_type=homework | Shows only rows at topic depth |
| 3 | Switch release_type=quiz | Rows reloaded at sub_topic depth |
| 4 | Switch release_type=quest | Rows reloaded at mini_topic depth |

---

#### TC-D12: Toggle Uses Different Permission Than View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with tenant.lesson.viewAny but NOT tenant.topic.update | User can view tab |
| 2 | Click toggle button for any schedule row | HTTP 403 Forbidden response |
| 3 | Login as user with both viewAny AND topic.update permissions | User can view tab |
| 4 | Click toggle button | AJAX POST succeeds (HTTP 200) |

---

#### TC-D13: Toggle Validates is_active As Required Boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST /topics/{id}/toggle-release without is_active field | HTTP 500: "The is active field is required." |
| 2 | POST with is_active=true | HTTP 200 success |
| 3 | POST with is_active=false | HTTP 200 success |
| 4 | POST with is_active="not_boolean" | HTTP 500 validation error |

---

#### TC-D14: Toggle With Invalid Type Returns 500

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with type="invalid_type", is_active=true | HTTP 500 validation error |
| 2 | POST with type="schedule", is_active=true | HTTP 200 success (schedule is valid type) |
| 3 | POST without type (null), is_active=true | HTTP 200 success (type is nullable) |

---

#### TC-D15: Fallback To CRUD When No Schedule Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no SyllabusSchedule records exist for selected class/subject/teacher | No schedule data |
| 2 | Load tab with release_type=homework | Table rows built from Lesson/Topic masters via buildSequencingFromCrud() |
| 3 | Check LMS Linked column | All rows show "No" (default fallback) |
| 4 | Check Release Status column | All rows show "Pending" (default fallback) |

---

#### TC-D16: Homework Link Query Checks class_id + subject_id + topic_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Homework record with class_id=C1, subject_id=S1, topic_id=T1 | Homework linked to topic |
| 2 | Load tab with class=C1, subject=S1, release_type=homework | Row for T1 shows green "Yes" badge |
| 3 | Ensure no Homework record exists for topic T2 with same class/subject scope | No link |
| 4 | Observe row for T2 | Gray "No" badge |

---

#### TC-D17: Quiz Link Query Checks scope_topic_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quiz with scope_topic_id=T1 | Quiz scoped to topic T1 |
| 2 | Load tab with release_type=quiz | Row for T1 shows green "Yes" badge |
| 3 | Ensure no Quiz has scope_topic_id=T2 | No scoped quiz for T2 |
| 4 | Observe row for T2 | Gray "No" badge |

---

#### TC-D18: Quest Link Query Checks QuestScope topic_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuestScope record with topic_id=T1 | Quest scope exists for T1 |
| 2 | Load tab with release_type=quest | Row for T1 shows green "Yes" badge |
| 3 | Ensure no QuestScope has topic_id=T2 | No scope for T2 |
| 4 | Observe row for T2 | Gray "No" badge |

---

#### TC-D19: Screen Has No Create/Edit/Delete Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Topic Release Control tab | Page renders with filter area and data table |
| 2 | Inspect header/toolbar area | No "Add", "Create", "New" action button present |
| 3 | Inspect each row's action column | No "Edit", "Delete", "Remove" icons/buttons visible |
| 4 | Verify only toggle switch/button appears (if permission allows) | Only AJAX toggle action is available |

---

#### TC-D20: Homework Release Check Queries is_released=1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HomeworkAssignment for topic T1 homework_id with is_released=1 | Record marked as released |
| 2 | Load tab with release_type=homework | Row for T1 shows green "Released" badge |
| 3 | Create HomeworkAssignment for topic T2 homework_id with is_released=0 | Record not released |
| 4 | Load tab | Row for T2 shows amber "Pending" badge |

#### TC-P28: Default Config When SchConfig Not Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no SchConfig record exists for homework_released_on_syllabus_level | Config absent |
| 2 | Load Topic Release Control tab with homework type | System defaults to topic level |
| 3 | Verify only root-level topic rows displayed | Sub/micro/mini/nano rows hidden |
| 4 | Verify release status badges shown for root topics | Badges rendered |

#### TC-P29: Config Snake_Case Normalization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set SchConfig homework_released_on_syllabus_level = "Mini-Topic" | Config saved with hyphen |
| 2 | Load Topic Release Control tab | Config value normalized to mini_topic |
| 3 | Verify Mini-Topic level rows visible, Micro/Nano rows hidden | Correct depth applied |

#### TC-P30: Depth Filter nano_topic — All Rows Visible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set config release level = nano_topic | Config saved |
| 2 | Load Topic Release Control tab | All hierarchy levels displayed |
| 3 | Verify Nano-Topic rows visible | No rows hidden |

#### TC-P31: Depth Filter micro_topic — Micro Visible, Nano Hidden

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set config release level = micro_topic | Config saved |
| 2 | Load Topic Release Control tab | Micro level rows shown |
| 3 | Verify Nano-Topic rows hidden | Correct filtering |

#### TC-N11: Toggle Service — No Homework Linked to Schedule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select schedule with no ON_TOPIC_COMPLETE homework | No homework linked |
| 2 | POST to toggle with type=schedule, field=homework, is_active=true | Request processed |
| 3 | Verify response: success=false | "No ON_TOPIC_COMPLETE homework linked to this schedule." |

#### TC-N12: Toggle Service — No Quiz Linked to Topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select schedule with no quiz linked to topic | No quiz found |
| 2 | POST to toggle with type=schedule, field=quiz, is_active=true | Request processed |
| 3 | Verify response: success=false | "No quiz found linked to this topic." |

#### TC-N13: Toggle Service — No Quest Linked to Topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select schedule with no quest linked to topic | No quest found |
| 2 | POST to toggle with type=schedule, field=quest, is_active=true | Request processed |
| 3 | Verify response: success=false | "No quests found for this topic." |

#### TC-N14: Validation — field Nullable Not Tested

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle endpoint without field parameter | field missing from request |
| 2 | Verify validation error | "field is required" or similar |

#### TC-N15: Validation — lesson_id Invalid Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle endpoint with lesson_id="abc" | Invalid type |
| 2 | Verify validation error | "lesson_id must be an integer" |

#### TC-N16: Validation — view_mode Invalid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle endpoint with view_mode="chart" | Invalid value |
| 2 | Verify validation error | "view_mode must be grid or list" |

#### TC-N17: Validation — release_date Invalid Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle endpoint with release_date="abc" | Invalid date |
| 2 | Verify validation error | "release_date is not a valid date" |

#### TC-N18: Level Mismatch After Config Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set release level = sub_topic, verify rows visible | Sub-topic rows shown |
| 2 | Create linked homework, toggle release = Released | Homework released for sub-topic |
| 3 | Change release level to topic | Grid shows only root topics |
| 4 | Verify sub-topic homework remains released in DB | is_released=1 still true |
| 5 | Revert to sub_topic level | Sub-topic rows visible again with Released badge |

#### TC-N19: Default Filter Values Applied on Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Topic Release Control tab without filter params | Class defaults to first option (id=1) |
| 2 | Check subject filter | Defaults to subject_id=5 |
| 3 | Verify data loads with these defaults | Grid populated |
| 4 | Verify release_type defaults to homework | Homework badges shown |
