# slb_lesson_date_planning_TcList

## Module: Syllabus → Planning → Lesson Date Planning

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Planning |
| Feature | Lesson Date Planning |
| URL(s) | `GET /syllabus/planning?tab=lesson_date_planning` (grid), `GET /syllabus/planning?tab=lesson_date_planning&view=grid` (grid explicit), `GET /syllabus/planning?tab=lesson_date_planning&view=list` (list), `POST /syllabus/planning/update-dates/{id}` (inline save), `GET /syllabus/get-topics-ajax` (topic AJAX), `GET /syllabus/schedule/get-teachers` (teacher AJAX) |
| Controller | `Modules\Syllabus\Http\Controllers\SyllabusScheduleController` + `Modules\Syllabus\Http\Controllers\SyllabusController@planning()` (tab render), `SyllabusController@updatePlanningDates()` (inline save) |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` (table: `slb_syllabus_schedule`) |
| Validation (Save) | Inline `$request->validate()` in `updatePlanningDates()` with `after_or_equal:planned_start_date`; no FormRequest |
| Request Class | `Modules\Syllabus\Http\Requests\SyllabusScheduleRequest` |
| Policy | `Modules\Syllabus\Policies\SyllabusSchedulePolicy` |
| Permissions | `tenant.syllabus_schedule.*` + via Gate: `tenant.lesson.update` (save), `tenant.lesson.viewAny` (view) |
| Soft Deletes | Yes (`SyllabusSchedule` uses `SoftDeletes` trait) |
| Grid Pagination | 12 cards per page (`planning_lessons_page` parameter) |
| List Pagination | 10 rows per page (`schedules_page` parameter) |
| Default View | Grid View (`?view=grid`) |

---

## 2. Pre-conditions

- Required permissions: `tenant.lesson.viewAny` (view), `tenant.lesson.update` (save), `tenant.syllabus_schedule.*` for schedule operations
- Required seed data: At least one active `OrganizationAcademicSession`, one active `SchoolClass` with section, one active `Subject`, sequenced topics in `SyllabusSchedule` table
- Test user must have `tenant.lesson.update` permission to perform inline saves
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Pre-existing schedule records must exist with `lesson_id`, `topic_id`, `topic_level_type_id`, `ordinal` populated via sequencing
- Teachers must be seeded in `Employee` table with `is_teacher=true`, `is_active=true`

---



---

## 3. Default Data Load

When the page loads via SyllabusController@planning() (GET /syllabus/planning) with tab=lesson_date_planning, default filters: class_section_id=1, subject_id=5, academic_session_id=7.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: dropdowns | planning() | Same as LessonSequencing (classes, sections, classSections, subjects, academicSessions) | --- | None |
| Schedule Grid (list view) | planning() | SyllabusSchedule::with(class,subject,lesson,topic,topicLevelType) | class_id, section_id, subject_id, academic_session_id | 12/page (planning_lessons_page) |
| Schedule Table (grid view) | planning() | SyllabusSchedule::with(academicSession,class,section,subject,lesson,topic,topicLevelType,assignedTeacher) | class_id, section_id, subject_id, academic_session_id | 10/page (schedules_page) |
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method where needed
- **Schedule records**: Pre-create via `SyllabusSchedule::factory()` or via sequencing save flow for test setup
- **Date format**: Always `Y-m-d` (e.g., `2026-07-15`) for both start and end dates
- **Teacher assignment**: Use existing teacher IDs from `Employee::where('is_teacher', true)->pluck('id')`
- **Pre-test cleanup**: Delete created schedule records after test run to avoid collisions
- **Date range validation**: Use `Carbon::parse()` for comparisons; end date must be `>=` start date
- **Grid view test data**: At least 13 records to verify 12-per-page pagination
- **List view test data**: At least 11 records to verify 10-per-page pagination
- **Filter dependencies**: Class/section must be selected before subject; subject is AJAX-dependent on class
- **Progress bar**: Client-side JS calculates 100%/50%/0% based on date presence — no server call for recalculation

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_syllabus_schedule`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | academic_session_id | INT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id`, ON DELETE CASCADE |
| BC-DB-03 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id`, ON DELETE CASCADE |
| BC-DB-04 | section_id | INT UNSIGNED | NOT NULL, FK → `sch_sections.id`, ON DELETE CASCADE |
| BC-DB-05 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id`, ON DELETE CASCADE |
| BC-DB-06 | ordinal | SMALLINT | NOT NULL |
| BC-DB-07 | lesson_id | INT UNSIGNED | FK → `slb_lessons.id` |
| BC-DB-08 | topic_id | INT UNSIGNED | FK → `slb_topics.id`, ON DELETE CASCADE |
| BC-DB-09 | topic_level_type_id | INT UNSIGNED | FK → `slb_topic_level_types.id` |
| BC-DB-10 | scheduled_start_date | DATE | DEFAULT NULL |
| BC-DB-11 | scheduled_end_date | DATE | DEFAULT NULL |
| BC-DB-12 | assigned_teacher_id | INT UNSIGNED | FK → `employees.id`, ON DELETE SET NULL |
| BC-DB-13 | taught_by_teacher_id | INT UNSIGNED | FK → `employees.id`, ON DELETE SET NULL |
| BC-DB-14 | planned_periods | SMALLINT | DEFAULT NULL |
| BC-DB-15 | priority | ENUM('HIGH','MEDIUM','LOW') | NOT NULL DEFAULT 'MEDIUM' |
| BC-DB-16 | notes | VARCHAR(500) | DEFAULT NULL |
| BC-DB-17 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-18 | is_locked | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-19 | is_completed | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-20 | completed_at | TIMESTAMP | NULLABLE |
| BC-DB-21 | completed_by | INT UNSIGNED | NULLABLE |
| BC-DB-22 | created_by | INT UNSIGNED | NOT NULL |
| BC-DB-23 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-24 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Validation Rules — Inline `updatePlanningDates()` Save

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | planned_start_date | nullable, date | "The planned start date is not a valid date." |
| BC-VAL-02 | planned_end_date | nullable, date, `after_or_equal:planned_start_date` (only when both present) | "The planned end date must be a date after or equal to planned start date." |
| BC-VAL-03 | planned_start_date + planned_end_date | Both null allowed | Clearing both dates sets them to NULL |
| BC-VAL-04 | planned_start_date null, planned_end_date set | Allowed (partial date) | Single date accepted |
| BC-VAL-05 | planned_start_date set, planned_end_date null | Allowed (partial date) | Single date accepted |

### 4.3 Validation Rules — `SyllabusScheduleRequest` (for other CRUD operations)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | academic_session_id | required, integer, exists | — |
| BC-VAL-U02 | class_id | required, integer, exists:sch_classes,id | — |
| BC-VAL-U03 | section_id | required, integer, exists:sch_sections,id | — |
| BC-VAL-U04 | subject_id | required, integer, exists:sch_subjects,id | — |
| BC-VAL-U05 | ordinal | required, integer, min:1 | — |
| BC-VAL-U06 | lesson_id | required, integer, exists:slb_lessons,id | — |
| BC-VAL-U07 | topic_id | required, integer, exists:slb_topics,id | — |
| BC-VAL-U08 | planned_periods | nullable, integer, min:1, max:100 | — |
| BC-VAL-U09 | priority | required, string, in:HIGH,MEDIUM,LOW | — |
| BC-VAL-U10 | notes | nullable, string, max:500 | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lesson.viewAny | planning() tab render | Without → 403 |
| BC-AUTH-02 | tenant.lesson.update | updatePlanningDates() inline save | Without → 403 |
| BC-AUTH-03 | tenant.syllabus_schedule.viewAny | index() | Without → 403 |
| BC-AUTH-04 | tenant.syllabus_schedule.create | store() | Without → 403 |
| BC-AUTH-05 | tenant.syllabus_schedule.update | update() | Without → 403 |
| BC-AUTH-06 | tenant.syllabus_schedule.delete | destroy() | Without → 403 |
| BC-AUTH-07 | Guest access (no auth) | Any route | Redirect to /login |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Grid View default | No `view` param → show Grid View with animated cards |
| BC-BIZ-02 | View toggle `?view=list` | URL param `view=list` → show List View with data table |
| BC-BIZ-03 | Grid pagination | 12 cards per page, `planning_lessons_page` parameter |
| BC-BIZ-04 | List pagination | 10 rows per page, `schedules_page` parameter |
| BC-BIZ-05 | Independent paginators | Grid page 3 → switch to List → List page 1 (different param names) |
| BC-BIZ-06 | Inline card save via AJAX | `POST /syllabus/planning/update-dates/{id}` with `planned_start_date`, `planned_end_date` |
| BC-BIZ-07 | Both dates null allowed | Clears both DB fields to NULL; progress bar → 0% yellow "Empty" |
| BC-BIZ-08 | End date before start date | Client-side JS blocks with toast; no AJAX sent |
| BC-BIZ-09 | Server date validation | `after_or_equal:planned_start_date` on end date when both present |
| BC-BIZ-10 | Progress bar — both set | 100% green "Filled" |
| BC-BIZ-11 | Progress bar — one set | 50% blue "Partial" |
| BC-BIZ-12 | Progress bar — none set | 0% yellow "Empty" |
| BC-BIZ-13 | Progress client-side only | Recalculated in browser after save response; no server request |
| BC-BIZ-14 | Record not found | `findOrFail($id)` → 404 |
| BC-BIZ-15 | Cascade filter order | Class + Section first, then Subject (AJAX-dependent) |
| BC-BIZ-16 | `markComplete()` method | Sets `is_completed=1`, `completed_at=now()`, `completed_by=auth()->id()` |
| BC-BIZ-17 | Teacher dropdown population | Lists `Employee::where('is_teacher',true)->where('is_active',true)` |
| BC-BIZ-18 | Topic AJAX load | `get-topics-ajax` returns JSON topics filtered by class/subject/lesson |
| BC-BIZ-19 | Grid view sort order | Ordered by `scheduled_start_date DESC` (latest first) |
| BC-BIZ-20 | List view sort order | Ordered by `scheduled_start_date DESC` |
| BC-BIZ-21 | Screen loads via SyllabusController@planning() at GET /syllabus/planning with tab=lesson_date_planning | Navigating to GET /syllabus/planning with tab=lesson_date_planning loads this screen's grid data with correct filters applied |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt (id) | CASCADE |
| BC-REF-02 | class_id | sch_classes (id) | CASCADE |
| BC-REF-03 | section_id | sch_sections (id) | CASCADE |
| BC-REF-04 | subject_id | sch_subjects (id) | CASCADE |
| BC-REF-05 | lesson_id | slb_lessons (id) | Not declared (validated in request) |
| BC-REF-06 | topic_id | slb_topics (id) | CASCADE |
| BC-REF-07 | topic_level_type_id | slb_topic_level_types (id) | Not declared |
| BC-REF-08 | assigned_teacher_id | employees (id) | SET NULL |
| BC-REF-09 | taught_by_teacher_id | employees (id) | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Lesson Date Planning Grid View Loads With Default View | Page loads with grid of animated cards at 12 per page, `view=grid` in URL | — | — | ⬜ |
| TC-P02 | Lesson Date Planning List View Loads Via Toggle | Toggle to List View → page reloads with `view=list`, table with 10 rows per page | — | — | ⬜ |
| TC-P03 | Cascade Filter — Class/Section Then Subject | Select class+section → subject dropdown populated via AJAX; selecting subject loads data | — | — | ⬜ |
| TC-P04 | Grid View Shows Correct Card Data | Each card shows lesson code, topic level type badge, class+subject badge, topic name, start/end date pickers, progress bar | — | — | ⬜ |
| TC-P05 | List View Shows Correct Column Data | Table shows session, class+section, subject, lesson+level type, topic, assigned teacher, start date, end date, priority badge, action buttons | — | — | ⬜ |
| TC-P06 | Grid Pagination — Page 1 Shows 12 Cards | Grid page 1 renders exactly 12 cards when 13+ records exist | — | — | ⬜ |
| TC-P07 | Grid Pagination — Navigate To Page 2 | Click page 2 → URL gets `planning_lessons_page=2`, remaining cards shown | — | — | ⬜ |
| TC-P08 | List Pagination — Page 1 Shows 10 Rows | List page 1 renders exactly 10 rows when 11+ records exist | — | — | ⬜ |
| TC-P09 | List Pagination — Navigate To Page 2 | Click page 2 → URL gets `schedules_page=2`, remaining rows shown | — | — | ⬜ |
| TC-P10 | Inline Save — Set Both Start And End Dates | Fill both dates on card, click Save → AJAX 200, progress bar → 100% green "Filled" | — | — | ⬜ |
| TC-P11 | Inline Save — Set Only Start Date | Fill start date, leave end empty, click Save → AJAX 200, progress bar → 50% blue "Partial" | — | — | ⬜ |
| TC-P12 | Inline Save — Set Only End Date | Fill end date, leave start empty, click Save → AJAX 200, progress bar → 50% blue "Partial" | — | — | ⬜ |
| TC-P13 | Inline Save — Clear Both Dates To Null | Clear both date inputs, click Save → AJAX 200, DB fields NULL, progress bar → 0% yellow "Empty" | — | — | ⬜ |
| TC-P14 | Progress Bar — Both Dates Filled Shows 100% Green | Card with both dates shows green bar, "Filled" badge | — | — | ⬜ |
| TC-P15 | Progress Bar — One Date Shows 50% Blue | Card with one date shows blue bar, "Partial" badge | — | — | ⬜ |
| TC-P16 | Progress Bar — No Dates Shows 0% Yellow | Card with no dates shows yellow bar, "Empty" badge | — | — | ⬜ |
| TC-P17 | Assign Teacher Via Dropdown On List View | Select teacher from dropdown on list row, save → teacher updated in DB | — | — | ⬜ |
| TC-P18 | Change Teacher Assignment | Change existing teacher to different teacher on list row, save → updated | — | — | ⬜ |
| TC-P19 | Priority Filter On Grid/List | Filter by HIGH/MEDIUM/LOW priority → only matching records shown | — | — | ⬜ |
| TC-P20 | Teacher Dropdown Shows Active Teachers Only | Dropdown lists only `is_teacher=true` and `is_active=true` employees | — | — | ⬜ |
| TC-P21 | Topic AJAX Load On Filter Change | Switching class/subject → `get-topics-ajax` returns correct topic list for that scope | — | — | ⬜ |
| TC-P22 | `markComplete()` Sets Completion Fields | Mark a schedule complete → `is_completed=1`, `completed_at` set, `completed_by` set | — | — | ⬜ |
| TC-P23 | View Persists Across Tab Switch | Switch to another tab and back → selected view (grid/list) is preserved | — | — | ⬜ |
| TC-P24 | Bookmark Grid View URL | Open `?view=grid&class_section_id=5&subject_id=12` → Grid View loads with pre-selected filters | — | — | ⬜ |
| TC-P25 | Bookmark List View URL | Open `?view=list&class_section_id=5&subject_id=12` → List View loads with pre-selected filters | — | — | ⬜ |
| TC-P26 | Empty State — No Filter Selected | Page shows prompt: "Select a class and subject to view lesson planning" | — | — | ⬜ |
| TC-P27 | Empty State — No Schedule Records | Select class/subject with no schedules → show appropriate empty message | — | — | ⬜ |
| TC-P28 | Multiple Cards Save Independently | Edit dates on card A and card B → save each individually → each AJAX call independent | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | End Date Before Start Date (Client-Side) | Set start=2026-07-20, end=2026-07-15 → toast error "End date cannot be before start date"; no AJAX sent | — | — | ⬜ |
| TC-N02 | End Date Before Start Date (Server-Side Via Direct API) | Send POST with end<start directly → HTTP 500: "The planned end date must be a date after or equal to planned start date." | — | — | ⬜ |
| TC-N03 | Invalid Date Format For Start Date | Submit "abc" as date → HTTP 500: "The planned start date is not a valid date." | — | — | ⬜ |
| TC-N04 | Invalid Date Format For End Date | Submit "12-34-56" as date → HTTP 500: validation error | — | — | ⬜ |
| TC-N05 | Save With Non-Existent Schedule ID | POST to `/planning/update-dates/99999` → HTTP 404 | — | — | ⬜ |
| TC-N06 | Save Without Permission (No tenant.lesson.update) | User without permission clicks Save → HTTP 403 Forbidden | — | — | ⬜ |
| TC-N07 | Guest Access Redirect (Not Logged In) | Navigate to planning tab → redirect to /login | — | — | ⬜ |
| TC-N08 | View Grid Without Permission (No viewAny) | User without viewAny → HTTP 403 | — | — | ⬜ |
| TC-N09 | Invalid Schedule ID In URL | `/planning/update-dates/abc` → 404 or validation error | — | — | ⬜ |
| TC-N10 | XSS In Start Date Field (Client Escape) | Attempt script injection in date field → input type=date prevents free text | — | — | ⬜ |
| TC-N11 | Load Grid With Invalid Class ID | Select non-existent class → empty result or error | — | — | ⬜ |
| TC-N12 | Load Grid With Invalid Subject ID | Select non-existent subject → empty result or error | — | — | ⬜ |
| TC-N13 | Date Out Of Academic Session Range | Set dates outside academic session boundary → system does not enforce session boundary validation (no such rule declared) | — | — | ⬜ |
| TC-N14 | Rapid Double-Click Save | Click Save twice rapidly → first request succeeds, second may 404 or succeed depending on timing | — | — | ⬜ |
| TC-N15 | Save With Only Whitespace Dates | Submit whitespace for dates → validation catches as invalid date format | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Grid View Toggle → List View → Back To Grid | Switch grid→list→grid → Grid View state preserved, correct page shown | — | — | ⬜ |
| TC-D02 | A | Independent Pagination — Grid Page 2 → List → Grid | Grid page 2 → switch to List page 1 → switch back to Grid page 2 | — | — | ⬜ |
| TC-D03 | B | Inline Save Updates `scheduled_start_date` In DB | Save new dates → DB fields match saved values | — | — | ⬜ |
| TC-D04 | B | Inline Save Updates `scheduled_end_date` In DB | Save new end date → `scheduled_end_date` updated in `slb_syllabus_schedule` | — | — | ⬜ |
| TC-D05 | C | Delete Schedule Record → Card Shows 404 | Another admin deletes the schedule → save attempt returns 404 | — | — | ⬜ |
| TC-D06 | D | Teacher Set → `taught_by_teacher_id` Cascaded | Setting `assigned_teacher_id` also sets `taught_by_teacher_id` | — | — | ⬜ |
| TC-D07 | D | Teacher Removed → `taught_by_teacher_id` Also Removed | Clearing teacher clears both fields (SET NULL) | — | — | ⬜ |
| TC-D08 | E | Filter Change Reloads Cards | Change subject → grid reloads with new subject's schedule records | — | — | ⬜ |
| TC-D09 | F | Concurrent Save — Two Users Edit Same Schedule | Both save → last save wins; no data corruption | — | — | ⬜ |
| TC-D10 | G | `markComplete()` Persists After Page Reload | Mark complete, refresh → card shows completed status | — | — | ⬜ |
| TC-D11 | H | Topic AJAX Returns Only Topics For Selected Lesson | `get-topics-ajax?lesson_id=X` → only topics belonging to lesson X returned | — | — | ⬜ |
| TC-D12 | H | Teacher Dropdown Shows Employee Code | Each teacher option shows name + employee code | — | — | ⬜ |
| TC-D13 | M | Grid View loads 12 cards per page | With 13 schedule records, grid shows 12 cards on page 1, 1 card on page 2 | — | — | ⬜ |
| TC-D14 | N | List View loads 10 rows per page | With 11 schedule records, list shows 10 rows on page 1, 1 row on page 2 | — | — | ⬜ |
| TC-D15 | O | Inline save uses planned_start_date and planned_end_date (snake_case) | Submitting `planned_start_date` and `planned_end_date` updates `scheduled_start_date` and `scheduled_end_date` in DB | — | — | ⬜ |
| TC-D16 | P | Server validates after_or_equal when both dates filled | Submitting start=2026-07-20, end=2026-07-15 returns 500; start=2026-07-15, end=2026-07-20 succeeds | — | — | ⬜ |
| TC-D17 | Q | Partial dates (one null, one set) are accepted | Submitting start=2026-07-15 with end=null saves successfully; end_date set to NULL in DB | — | — | ⬜ |
| TC-D18 | R | Schedule not found returns 404 | POST to /planning/update-dates/99999 (non-existent ID) returns 404 | — | — | ⬜ |
| TC-D19 | S | Default filters auto-set when none provided | Opening tab without filter params auto-selects default class/section/subject/session | — | — | ⬜ |
| TC-D20 | T | Independent paginators: grid page ≠ list page | Navigating to grid page 3 then switching to list shows list page 1 (not list page 3) | — | — | ⬜ |
| TC-D21 | U | Missing tenant.lesson.update returns 403 on save | User without lesson.update permission receives 403 when attempting inline save | — | — | ⬜ |
| TC-D22 | V | Grid view sorted by scheduled_start_date DESC | Grid view records ordered by `scheduled_start_date DESC` (latest first) | — | — | ⬜ |
| TC-D23 | W | List view sorted by scheduled_start_date DESC | List view records ordered by `scheduled_start_date DESC` (latest first) | — | — | ⬜ |
| TC-D24 | X | Code Review — Controller — Gate::authorize() on every CRUD method | Each CRUD method (`create`, `store`, `show`, `edit`, `update`, `destroy`, `trashed`, `restore`, `forceDelete`, `toggleStatus`, `markComplete`) calls `Gate::authorize('tenant.syllabus_schedule.*')` with correct permission | — | — | ⬜ |
| TC-D25 | Y | Code Review — Controller — Activity logged on all state transitions | `Stored` (store), `Updated` (update), `Trashed` (destroy), `Restored` (restore), `Deleted` (forceDelete), `Completed` (markComplete) events recorded in activity log with model ID, event name, performed_by. `toggleStatus()` does NOT call activityLog | — | — | ⬜ |
| TC-D26 | Z | Code Review — Controller — is_active set false before soft delete in destroy() | destroy() sets `is_active = 0` before `delete()`; DB check after delete: is_active=0, deleted_at IS NOT NULL | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.syllabus-schedule.create'), @can('tenant.syllabus-schedule.edit'), @can('tenant.syllabus-schedule.delete'), @can('tenant.syllabus-schedule.status'), @can('tenant.syllabus-schedule.view'), @canany(['tenant.syllabus-schedule.restore', 'tenant.syllabus-schedule.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.planning` key → `'syllabus/planning'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — Gate::authorize() on Every CRUD Method | Every controller method (create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, markComplete) calls `Gate::authorize('tenant.syllabus_schedule.*')` with correct permission string before executing business logic; unauthorized user receives 403 | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — Activity Logged on All State Transitions | Each state-changing method fires an activityLog event: `Created` (store), `Updated` (update), `Trashed` (destroy), `Restored` (restore), `Deleted` (forceDelete), `Completed` (markComplete); log entry contains model ID, event name, performed_by user. `toggleStatus()` does NOT call activityLog | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | View — Success Flash Messages After Create/Update/Delete | After CRUD actions, controller redirects with success flash; Blade displays success alert with correct action-specific message | — | — | ◌ |


---



## 7. Detailed Test Steps



#### TC-CR03: Controller — Gate::authorize() on Every CRUD Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SyllabusScheduleController@create` | `Gate::authorize('tenant.syllabus_schedule.create')` present as first line before any DB/View logic |
| 2 | Inspect `SyllabusScheduleController@store` | `Gate::authorize('tenant.syllabus_schedule.create')` present as first line |
| 3 | Inspect `SyllabusScheduleController@show` | `Gate::authorize('tenant.syllabus_schedule.view')` present as first line |
| 4 | Inspect `SyllabusScheduleController@edit` | `Gate::authorize('tenant.syllabus_schedule.update')` present as first line |
| 5 | Inspect `SyllabusScheduleController@update` | `Gate::authorize('tenant.syllabus_schedule.update')` present as first line |
| 6 | Inspect `SyllabusScheduleController@destroy` | `Gate::authorize('tenant.syllabus_schedule.delete')` present as first line |
| 7 | Inspect `SyllabusScheduleController@trashed` | `Gate::authorize('tenant.syllabus_schedule.restore')` present as first line |
| 8 | Inspect `SyllabusScheduleController@restore` | `Gate::authorize('tenant.syllabus_schedule.restore')` present as first line |
| 9 | Inspect `SyllabusScheduleController@forceDelete` | `Gate::authorize('tenant.syllabus_schedule.forceDelete')` present as first line |
| 10 | Inspect `SyllabusScheduleController@toggleStatus` | `Gate::authorize('tenant.syllabus_schedule.update')` present as first line |
| 11 | Inspect `SyllabusScheduleController@markComplete` | `Gate::authorize('tenant.syllabus_schedule.update')` present as first line |
| 12 | Login as user without `tenant.syllabus_schedule.create` | Access store() → HTTP 403 Forbidden |
| 13 | Login as user without `tenant.syllabus_schedule.delete` | Access destroy() → HTTP 403 Forbidden |
| 14 | Login as user without `tenant.syllabus_schedule.restore` | Access restore() → HTTP 403 Forbidden |
| 15 | Login as user without `tenant.syllabus_schedule.forceDelete` | Access forceDelete() → HTTP 403 Forbidden |

---

#### TC-CR04: Controller — Activity Logged on All State Transitions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new SyllabusSchedule via `store()` | `activityLog($schedule, 'Created', ...)` called; log entry created with message "Syllabus Schedule created successfully" |
| 2 | Query `activity_log` table: `SELECT * FROM activity_log WHERE log_name = 'SyllabusSchedule' AND event = 'Created'` | Log entry exists with correct model ID, `performed_by` = current user |
| 3 | Update the same record via `update()` | `activityLog($schedule, 'Updated', ...)` called; log entry with message "Syllabus Schedule updated" |
| 4 | Verify `Updated` log entry | Log entry exists with `event = 'Updated'` and correct model ID |
| 5 | Soft delete the record via `destroy()` | `activityLog($schedule, 'Trashed', ...)` called; log entry with message "Syllabus Schedule moved to trash" |
| 6 | Verify `Trashed` log entry | Log entry exists with `event = 'Trashed'` and correct model ID |
| 7 | Restore the trashed record via `restore()` | `activityLog($schedule, 'Restored', ...)` called; log entry with message "Syllabus Schedule restored" |
| 8 | Verify `Restored` log entry | Log entry exists with `event = 'Restored'` and correct model ID |
| 9 | Force delete the record via `forceDelete()` | `activityLog($schedule, 'Deleted', ...)` called; log entry with message "Syllabus Schedule permanently deleted" |
| 10 | Verify `Deleted` log entry | Log entry exists with `event = 'Deleted'` and correct model ID |
| 11 | Verify `toggleStatus()` does NOT call activityLog | Method returns JSON response directly without activityLog; no `Toggled` event recorded |

---

#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php for this screen | View file found in lesson-management/partials/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Create a record with null relationship | View renders without undefined index/property error
| 5 | Load index page with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR06: View — Success Flash Messages After Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new record | POST to store(); redirects with session flash
| 2 | Verify success message after create | Page shows success alert: ‘Complexity level created successfully’ (or equivalent for this screen)
| 3 | Update the record | PUT/PATCH to update(); redirects with flash
| 4 | Verify success message after update | ‘Complexity level updated successfully’ (or equivalent)
| 5 | Soft delete the record | DELETE to destroy(); redirects with flash
| 6 | Verify success message after delete | ‘Complexity level trashed successfully’ (or equivalent)
| 7 | Restore from trash | POST to restore(); redirects with flash
| 8 | Verify success message after restore | ‘Complexity level restored successfully’ (or equivalent)
| 9 | Force delete from trash | DELETE to forceDelete(); redirects with flash
| 10 | Verify success message after force delete | ‘Complexity level force deleted successfully’ (or equivalent)


#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.syllabus-schedule.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.syllabus-schedule.view'), @can('tenant.syllabus-schedule.edit'), @can('tenant.syllabus-schedule.delete'), @can('tenant.syllabus-schedule.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.syllabus-schedule.restore', 'tenant.syllabus-schedule.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.syllabus-schedule.edit') wraps the Edit button on show/details page
| 5 | Log in as user with all permissions | All buttons visible and functional |
| 6 | Log in as user with viewAny only (no create/edit/delete) | Add New button hidden; action columns show view icon only or no actions |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.planning' key exists | Config has 'syllabus.planning' => 'syllabus/planning' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/planning' correctly references Planning tab view
| 4 | Load the screen via the Planning tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Planning tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Lesson Date Planning Grid View Loads With Default View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Planning" and select "Lesson Date Planning" tab | Page loads at `/planning?tab=lesson_date_planning` |
| 4 | Verify URL contains `view=grid` (or no view param) | Default view is Grid |
| 5 | Select a class with section from the filter dropdown | Class/section selected |
| 6 | Select a subject from the dropdown | Subject selected; grid cards appear |
| 7 | Count visible cards | 12 cards maximum per page |
| 8 | Verify each card shows: topic name, lesson code, level type badge, class+subject badge, date pickers, progress bar | All elements present |

---

#### TC-P02: Lesson Date Planning List View Loads Via Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | From Grid View, click "List View" toggle button | Page reloads with `?view=list` |
| 2 | Verify table structure | Columns: Session, Class+Section, Subject, Lesson+Level Type, Topic, Assigned Teacher, Start Date, End Date, Priority, Actions |
| 3 | Count visible rows | 10 rows maximum per page |
| 4 | Switch back to Grid View using toggle | Page reloads with `?view=grid` |

---

#### TC-P03: Cascade Filter — Class/Section Then Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no filter is selected | Empty state prompt shown |
| 2 | Select a class from the class dropdown | AJAX loads sections for that class |
| 3 | Select a section from the section dropdown | Section selected |
| 4 | Observe the subject dropdown | Subject dropdown populated with subjects linked to selected class |
| 5 | Select a subject | Grid view loads with schedule records for that class+section+subject |

---

#### TC-P04: Grid View Shows Correct Card Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters to show grid cards | Cards rendered |
| 2 | Hover over first card | Card lifts with enhanced shadow effect |
| 3 | Check card accent bar | Colored accent bar at top (one of rotating 6-color palette) |
| 4 | Check lesson code | Lesson code displayed on card |
| 5 | Check topic level type badge | Correct level type badge (e.g., "Topic", "Sub-Topic") |
| 6 | Check class+subject badge | Combined badge at card top |
| 7 | Check topic name | Topic name displayed with two-line truncation |
| 8 | Check date pickers | Start date input with blue calendar-plus icon, End date with red calendar-check icon |

---

#### TC-P05: List View Shows Correct Column Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Switch to List View | Table renders |
| 2 | Check column headers | Academic Session, Class & Section, Subject, Lesson with Level Type, Topic Name, Assigned Teacher, Start Date, End Date, Priority, Actions (view/edit/delete) |
| 3 | Check teacher column shows employee code | Teacher name + code displayed |
| 4 | Check priority badge | HIGH=red, MEDIUM=amber, LOW=green badge shown |
| 5 | Click "View" action on a row | Detail view or modal with record data |
| 6 | Click "Edit" action on a row | Edit form loaded for that row |

---

#### TC-P06: Grid Pagination — Page 1 Shows 12 Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 13+ schedule records exist for the selected filters | Records exist |
| 2 | Apply filters in Grid View | 12 cards visible |
| 3 | Check pagination controls | "Showing 1 to 12 of 13+" with page numbers |
| 4 | Check URL parameter | No `planning_lessons_page` param (default page 1) |

---

#### TC-P07: Grid Pagination — Navigate To Page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click page 2 link in pagination | Page reloads |
| 2 | Check URL | `?planning_lessons_page=2` present |
| 3 | Verify remaining cards shown | Remaining 1+ card(s) displayed |
| 4 | Check pagination shows "Page 2 of 2" | Correct page indicator |

---

#### TC-P08: List Pagination — Page 1 Shows 10 Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Switch to List View with 11+ records | List renders |
| 2 | Count visible rows | 10 rows visible |
| 3 | Check pagination | "Showing 1 to 10 of 11+" |

---

#### TC-P09: List Pagination — Navigate To Page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click page 2 in list pagination | Page reloads with `?schedules_page=2` |
| 2 | Verify remaining rows shown | Remaining 1+ row(s) displayed |

---

#### TC-P10: Inline Save — Set Both Start And End Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Grid View with a card that has empty dates | Card shows 0% yellow "Empty" |
| 2 | Click the start date picker and select a date (e.g., 2026-07-15) | Date filled in input |
| 3 | Click the end date picker and select a later date (e.g., 2026-07-18) | Date filled in input |
| 4 | Click "Save Planning" button on the card | AJAX POST to `/planning/update-dates/{id}` |
| 5 | Check response | JSON `{ success: true, message: "Date Planning Updated successfully!" }` |
| 6 | Check progress bar | Instantly updates to 100% green "Filled" |
| 7 | DB check: `SELECT scheduled_start_date, scheduled_end_date FROM slb_syllabus_schedule WHERE id={id}` | Dates match saved values |

---

#### TC-P11: Inline Save — Set Only Start Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open card with empty dates | Empty state |
| 2 | Set only the start date to 2026-07-15 | End date empty |
| 3 | Click "Save Planning" | AJAX sent |
| 4 | Check response | Success |
| 5 | DB check: `scheduled_start_date` = 2026-07-15, `scheduled_end_date` = NULL | Partial date saved |
| 6 | Check progress bar | 50% blue "Partial" |

---

#### TC-P12: Inline Save — Set Only End Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open card with empty dates | Empty state |
| 2 | Set only the end date to 2026-07-20 | Start date empty |
| 3 | Click "Save Planning" | AJAX sent |
| 4 | Check response | Success |
| 5 | DB check: `scheduled_start_date` = NULL, `scheduled_end_date` = 2026-07-20 | Partial date saved |
| 6 | Check progress bar | 50% blue "Partial" |

---

#### TC-P13: Inline Save — Clear Both Dates To Null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a card that has both dates set | Card shows 100% green "Filled" |
| 2 | Clear both date pickers (delete values) | Both inputs empty |
| 3 | Click "Save Planning" | AJAX sent with both fields null |
| 4 | Check response | Success |
| 5 | DB check: `scheduled_start_date` = NULL, `scheduled_end_date` = NULL | Both cleared |
| 6 | Check progress bar | 0% yellow "Empty" |

---

#### TC-P14: Progress Bar — Both Dates Filled Shows 100% Green

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set both start and end dates on a card | Progress bar immediately shows green |
| 2 | Check progress bar width | 100% width |
| 3 | Check badge text | "Filled" |

---

#### TC-P15: Progress Bar — One Date Shows 50% Blue

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set only start date on a card | Progress bar shows blue |
| 2 | Check progress bar width | 50% width |
| 3 | Check badge text | "Partial" |

---

#### TC-P16: Progress Bar — No Dates Shows 0% Yellow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear both dates on a card | Progress bar shows yellow |
| 2 | Check progress bar width | 0% width |
| 3 | Check badge text | "Empty" |

---

#### TC-P17: Assign Teacher Via Dropdown On List View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Switch to List View | Table with teacher column |
| 2 | Click the teacher dropdown on a row with no teacher | Dropdown opens with active teachers |
| 3 | Select a teacher from the list | Teacher name appears in dropdown |
| 4 | Verify `taught_by_teacher_id` also set | Cascaded from `assigned_teacher_id` |
| 5 | Refresh page | Teacher assignment persists |

---

#### TC-P18: Change Teacher Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a row with existing teacher "Teacher A" | Current teacher shown |
| 2 | Change to "Teacher B" from dropdown | Teacher changed |
| 3 | Save the row | Update succeeds |
| 4 | DB check: `assigned_teacher_id` and `taught_by_teacher_id` | Both point to Teacher B |

---

#### TC-P19: Priority Filter On Grid/List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filter with class/subject that has mixed priority records (HIGH, MEDIUM, LOW) | All records shown |
| 2 | Select "HIGH" priority filter | Only HIGH priority records visible |
| 3 | Select "MEDIUM" priority filter | Only MEDIUM priority records visible |
| 4 | Select "LOW" priority filter | Only LOW priority records visible |
| 5 | Clear the filter | All records visible again |

---

#### TC-P20: Teacher Dropdown Shows Active Teachers Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the teacher dropdown on any row | Dropdown lists teachers |
| 2 | Verify each teacher in list has `is_teacher=true` and `is_active=true` | Only valid teachers shown |
| 3 | Count teachers in dropdown vs `Employee::where('is_teacher',1)->where('is_active',1)->count()` | Counts match |

---

#### TC-P21: Topic AJAX Load On Filter Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class and subject combination | AJAX fires to `get-topics-ajax` |
| 2 | Check response | JSON array of topics scoped to selected class+subject |
| 3 | Verify topics belong to that class+subject only | No cross-scope topics returned |

---

#### TC-P22: `markComplete()` Sets Completion Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to a schedule record | Record loaded |
| 2 | Call `markComplete()` via action button | AJAX or form submit |
| 3 | DB check: `SELECT is_completed, completed_at, completed_by FROM slb_syllabus_schedule WHERE id={id}` | `is_completed=1`, `completed_at` timestamp set, `completed_by` = auth user ID |

---

#### TC-P23: View Persists Across Tab Switch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Switch to List View (`view=list`) | List View shown |
| 2 | Click on a different planning tab (e.g., Lesson Sequencing) | Sequencing tab loads |
| 3 | Click back on "Lesson Date Planning" tab | List View still active (view=list preserved) |

---

#### TC-P24: Bookmark Grid View URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Copy URL: `/planning?tab=lesson_date_planning&view=grid&class_section_id=5&subject_id=12` | URL copied |
| 2 | Open URL in a new tab | Page loads directly in Grid View with class=5, subject=12 pre-selected |
| 3 | Verify cards correspond to class=5, subject=12 | Correct data shown |

---

#### TC-P25: Bookmark List View URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/planning?tab=lesson_date_planning&view=list&class_section_id=5&subject_id=12` | List View loads with pre-selected filters |
| 2 | Verify table shows correct data | Rows for class=5, subject=12 |

---

#### TC-P26: Empty State — No Filter Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Lesson Date Planning tab without filters | Empty state shown |
| 2 | Verify prompt message | "Select a class and subject to view lesson planning" |
| 3 | Verify no cards/rows displayed | Empty area |

---

#### TC-P27: Empty State — No Schedule Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class+section+subject combination that has no schedule records | Empty state |
| 2 | Verify appropriate message | "No scheduled topics found for the selected filters" |
| 3 | Verify "Complete Lesson Sequencing first" link or message | Guidance to sequence first |

---

#### TC-P28: Multiple Cards Save Independently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Grid View with 3 cards | Cards A, B, C visible |
| 2 | Change dates on Card A and click Save | AJAX for Card A only |
| 3 | Immediately change dates on Card B and click Save | AJAX for Card B only (independent) |
| 4 | DB check: Card A dates updated, Card B dates updated | Both saved correctly |
| 5 | Verify Card C unchanged | No AJAX sent for Card C |

---

### 6.2 Negative TC Steps

#### TC-N01: End Date Before Start Date (Client-Side)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a card in Grid View | Card visible |
| 2 | Set start date to 2026-07-20 | Start date filled |
| 3 | Set end date to 2026-07-15 | End date before start |
| 4 | Click "Save Planning" | Client-side validation catches; toast error "End date cannot be before start date" |
| 5 | Check network tab | No AJAX request sent |

---

#### TC-N02: End Date Before Start Date (Server-Side Via Direct API)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send direct POST to `/planning/update-dates/{id}` with `planned_start_date=2026-07-20` and `planned_end_date=2026-07-15` | HTTP 500 |
| 2 | Check response body | Validation error: "The planned end date must be a date after or equal to planned start date." |
| 3 | DB check: dates unchanged | Record retains previous dates |

---

#### TC-N03: Invalid Date Format For Start Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `planned_start_date="abc"` | HTTP 500 |
| 2 | Error: "The planned start date is not a valid date." | Validation error |

---

#### TC-N04: Invalid Date Format For End Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `planned_end_date="12-34-56"` | HTTP 500 |
| 2 | Error: "The planned end date is not a valid date." | Validation error |

---

#### TC-N05: Save With Non-Existent Schedule ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/planning/update-dates/99999` with valid dates | HTTP 404 |
| 2 | `SyllabusSchedule::findOrFail(99999)` throws `ModelNotFoundException` | 404 error |

---

#### TC-N06: Save Without Permission (No tenant.lesson.update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.lesson.update` permission | Dashboard loads |
| 2 | Navigate to Lesson Date Planning tab | Page loads (read-only) |
| 3 | Try to save a card via AJAX | HTTP 403 Forbidden |
| 4 | Verify the Save Planning button is hidden/disabled | UI respects permission |

---

#### TC-N07: Guest Access Redirect (Not Logged In)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to `/planning?tab=lesson_date_planning` | Redirected to /login |

---

#### TC-N08: View Grid Without Permission (No viewAny)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.lesson.viewAny` | Dashboard loads |
| 2 | Navigate to `/planning?tab=lesson_date_planning` | HTTP 403 Forbidden |

---

#### TC-N09: Invalid Schedule ID In URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/planning/update-dates/abc` | HTTP 404 (route binding fails) or 500 |

---

#### TC-N10: XSS In Start Date Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to type `<script>alert('xss')</script>` in date input | Browser `type=date` restricts to date format; free text not allowed |
| 2 | Attempt to send via AJAX with xss string | Validation rejects invalid date |

---

#### TC-N11: Load Grid With Invalid Class ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manipulate URL to set `class_section_id=99999` | Page loads with empty grid or error message |
| 2 | Verify no crashes | Graceful handling of invalid FK |

---

#### TC-N12: Load Grid With Invalid Subject ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `subject_id=99999` in URL | Empty grid or error message, no crash |

---

#### TC-N13: Date Out Of Academic Session Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set dates far outside academic session (e.g., year 2050) | System currently does not enforce session boundary validation; save succeeds |

---

#### TC-N14: Rapid Double-Click Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Save Planning" twice rapidly | First request processes; second may return 404 (if already processed) or 200 (idempotent) |
| 2 | Verify no duplicate records or corruption | Data integrity maintained |

---

#### TC-N15: Save With Only Whitespace Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `planned_start_date="   "` | Validation error: invalid date format |

---

### 6.3 Dependency TC Steps

#### TC-D01: Grid View Toggle → List View → Back To Grid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Start in Grid View | Grid showing 12 cards |
| 2 | Click "List View" toggle | URL changes to `?view=list` |
| 3 | Click "Grid View" toggle | URL changes back to `?view=grid` |
| 4 | Verify grid cards still display correctly | Same data shown |

---

#### TC-D02: Independent Pagination — Grid Page 2 → List → Grid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Grid View, navigate to page 2 | URL: `?planning_lessons_page=2` |
| 2 | Switch to List View | URL: `?view=list&schedules_page=1` (page 1) |
| 3 | Switch back to Grid View | URL: `?view=grid&planning_lessons_page=2` (page 2 preserved) |

---

#### TC-D03: Inline Save Updates `scheduled_start_date` In DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save a card with `planned_start_date=2026-07-15` | AJAX succeeds |
| 2 | DB query: `SELECT scheduled_start_date FROM slb_syllabus_schedule WHERE id={id}` | Value = `2026-07-15` |

---

#### TC-D04: Inline Save Updates `scheduled_end_date` In DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save a card with `planned_end_date=2026-07-18` | AJAX succeeds |
| 2 | DB query: `SELECT scheduled_end_date FROM slb_syllabus_schedule WHERE id={id}` | Value = `2026-07-18` |

---

#### TC-D05: Delete Schedule Record → Card Shows 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Grid View with schedule_id=5 | Card for ID 5 visible |
| 2 | In another session, soft-delete schedule_id=5 | Record deleted |
| 3 | Edit dates on that card and click Save | AJAX returns 404 |
| 4 | Verify error handling | User prompted to refresh page |

---

#### TC-D06: Teacher Set → `taught_by_teacher_id` Cascaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assign teacher_id=10 to a schedule | Save succeeds |
| 2 | DB check: `SELECT assigned_teacher_id, taught_by_teacher_id FROM slb_syllabus_schedule WHERE id={id}` | Both = 10 |

---

#### TC-D07: Teacher Removed → Both Fields Cleared

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear teacher dropdown on a row that had a teacher | Teacher set to null |
| 2 | Save the row | Update succeeds |
| 3 | DB check: both `assigned_teacher_id` and `taught_by_teacher_id` = NULL | Both cleared |

---

#### TC-D08: Filter Change Reloads Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A / Subject X | Grid shows cards for A/X |
| 2 | Change to Subject Y | Grid reloads with cards for A/Y |
| 3 | Verify no cards from Subject X remain | Only Y cards visible |

---

#### TC-D09: Concurrent Save — Two Users Edit Same Schedule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A opens schedule ID=5 | Card loaded |
| 2 | User B opens same schedule ID=5 | Same card loaded |
| 3 | User A saves start_date=2026-07-15 | Success |
| 4 | User B saves start_date=2026-07-20 | Success (last save wins) |
| 5 | DB check: `scheduled_start_date` = 2026-07-20 | Last write persists |

---

#### TC-D10: `markComplete()` Persists After Page Reload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Mark schedule as complete | `is_completed=1` |
| 2 | Refresh the page | Card/tab still shows completed status |
| 3 | DB check: `is_completed`, `completed_at`, `completed_by` all persist | Fields unchanged |

---

#### TC-D11: Topic AJAX Returns Only Topics For Selected Lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select lesson_id=5 | AJAX fires |
| 2 | Check response JSON | All topics have `lesson_id=5` |
| 3 | Check count matches DB query | Correct count |

---

#### TC-D12: Teacher Dropdown Shows Employee Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open teacher dropdown | Each option shows: "Teacher Name (EMP001)" |
| 2 | Verify employee code matches `Employee` table | Code correct |

---

#### TC-D13: Grid View Loads 12 Cards Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 13+ schedule records exist for the selected filters | Records exist |
| 2 | Apply filters in Grid View | Grid renders |
| 3 | Count visible cards | 12 cards displayed |
| 4 | Check pagination text | "Showing 1 to 12 of 13+" with page 2 link |
| 5 | Click page 2 link | URL updates with `planning_lessons_page=2` |
| 6 | Verify remaining cards | 1 card shown on page 2 |

---

#### TC-D14: List View Loads 10 Rows Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Switch to List View with 11+ schedule records | List renders |
| 2 | Count visible rows | 10 rows displayed |
| 3 | Check pagination text | "Showing 1 to 10 of 11+" with page 2 link |
| 4 | Click page 2 link | URL updates with `schedules_page=2` |
| 5 | Verify remaining rows | 1 row shown on page 2 |

---

#### TC-D15: Inline Save Uses planned_start_date And planned_end_date (snake_case)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/planning/update-dates/{id}` with `planned_start_date=2026-07-15` and `planned_end_date=2026-07-18` | HTTP 200 success |
| 2 | DB query: `SELECT scheduled_start_date, scheduled_end_date FROM slb_syllabus_schedule WHERE id={id}` | `scheduled_start_date` = 2026-07-15, `scheduled_end_date` = 2026-07-18 |
| 3 | Verify snake_case field names in request body | `planned_start_date` and `planned_end_date` used (not camelCase or dashed) |

---

#### TC-D16: Server Validates after_or_equal When Both Dates Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `planned_start_date=2026-07-20`, `planned_end_date=2026-07-15` | HTTP 500 |
| 2 | Check error message | "The planned end date must be a date after or equal to planned start date." |
| 3 | Send POST with `planned_start_date=2026-07-15`, `planned_end_date=2026-07-20` | HTTP 200 success |
| 4 | DB check: dates match submitted values | `scheduled_start_date` = 2026-07-15, `scheduled_end_date` = 2026-07-20 |

---

#### TC-D17: Partial Dates (One Null, One Set) Are Accepted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `planned_start_date=2026-07-15` and no `planned_end_date` field | HTTP 200 success |
| 2 | DB query: `SELECT scheduled_start_date, scheduled_end_date FROM slb_syllabus_schedule WHERE id={id}` | `scheduled_start_date` = 2026-07-15, `scheduled_end_date` = NULL |
| 3 | Send POST with `planned_end_date=2026-07-20` and no `planned_start_date` field | HTTP 200 success |
| 4 | DB query: same record | `scheduled_start_date` = NULL, `scheduled_end_date` = 2026-07-20 |

---

#### TC-D18: Schedule Not Found Returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/planning/update-dates/99999` with valid dates | HTTP 404 Not Found |
| 2 | Verify `SyllabusSchedule::findOrFail(99999)` throws `ModelNotFoundException` | 404 error page |

---

#### TC-D19: Default Filters Auto-Set When None Provided

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Lesson Date Planning tab without any filter query params | Tab loads |
| 2 | Check class_section_id filter | Auto-selected to 1 |
| 3 | Check subject_id filter | Auto-selected to 5 |
| 4 | Check academic_session_id filter | Auto-selected to 7 |
| 5 | Verify grid loads with data corresponding to default filters | Schedule records shown for the default filter combination |

---

#### TC-D20: Independent Paginators — Grid Page ≠ List Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Grid View, navigate to page 3 | URL contains `planning_lessons_page=3` |
| 2 | Switch to List View using toggle | URL changes to `?view=list` |
| 3 | Check list pagination | List shows page 1 (`schedules_page=1`), not page 3 |
| 4 | Verify list page 1 data | First 10 rows of list data shown |

---

#### TC-D21: Missing tenant.lesson.update Returns 403 On Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.lesson.update` permission | Dashboard loads |
| 2 | Navigate to Lesson Date Planning tab | Tab loads in read-only mode |
| 3 | Attempt to send POST to `/planning/update-dates/{id}` with valid dates | HTTP 403 Forbidden |
| 4 | Verify Save Planning button disabled or hidden | UI reflects permission restriction |

---

#### TC-D22: Grid view sorted by scheduled_start_date DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create schedule records for the same class+subject with different scheduled_start_date values: Record A (2026-07-10), Record B (2026-07-20), Record C (2026-07-15) | 3 records exist |
| 2 | Navigate to Grid View for that class+subject | Grid cards displayed |
| 3 | Inspect card order from top-left to bottom-right | Cards appear in DESC order: Record B (Jul 20) first, Record C (Jul 15) second, Record A (Jul 10) last |
| 4 | Verify records with NULL scheduled_start_date appear last | NULL dates sorted to end of grid |
| 5 | Inspect `SyllabusController@planning()` grid query | Ordered by `scheduled_start_date DESC` |

---

#### TC-D23: List view sorted by scheduled_start_date DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Using the same 3 schedule records, switch to List View (`?view=list`) | List table displayed |
| 2 | Inspect row order from top to bottom | Rows appear in DESC order: Record B (Jul 20) first, Record C (Jul 15) second, Record A (Jul 10) last |
| 3 | Verify records with NULL scheduled_start_date appear last | NULL dates sorted to end of table |
| 4 | Inspect `SyllabusController@planning()` list query | Ordered by `scheduled_start_date DESC` |
| 5 | Verify sort applies consistently across paginated pages | Page 2 continues the same sort order |

---

#### TC-D24: Controller — Gate::authorize() on Every CRUD Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `store()` route without authentication token | HTTP 302 redirect to login (no session) |
| 2 | Login as user with `tenant.syllabus_schedule.create` permission | POST to `store()` succeeds (HTTP 302 redirect) |
| 3 | Login as user WITHOUT `tenant.syllabus_schedule.create` permission | POST to `store()` returns HTTP 403 Forbidden |
| 4 | Login as user with `tenant.syllabus_schedule.update` permission | PUT to `update()` succeeds (HTTP 302 redirect) |
| 5 | Login as user WITHOUT `tenant.syllabus_schedule.update` permission | PUT to `update()` returns HTTP 403 Forbidden |
| 6 | Login as user with `tenant.syllabus_schedule.delete` permission | DELETE to `destroy()` succeeds (HTTP 302 redirect) |
| 7 | Login as user WITHOUT `tenant.syllabus_schedule.delete` permission | DELETE to `destroy()` returns HTTP 403 Forbidden |
| 8 | Login as user with `tenant.syllabus_schedule.restore` permission | GET to `restore()` succeeds (HTTP 302 redirect) |
| 9 | Login as user WITHOUT `tenant.syllabus_schedule.restore` permission | GET to `restore()` returns HTTP 403 Forbidden |
| 10 | Login as user with `tenant.syllabus_schedule.forceDelete` permission | DELETE to `forceDelete()` succeeds (HTTP 302 redirect) |
| 11 | Login as user WITHOUT `tenant.syllabus_schedule.forceDelete` permission | DELETE to `forceDelete()` returns HTTP 403 Forbidden |
| 12 | Login as user with `tenant.syllabus_schedule.update` permission | POST to `toggleStatus()` returns 200 JSON (AJAX) |
| 13 | Login as user WITHOUT `tenant.syllabus_schedule.update` permission | POST to `toggleStatus()` returns HTTP 403 Forbidden |

---

#### TC-D25: Controller — Activity Logged on All State Transitions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new SyllabusSchedule record via `store()` `POST /syllabus-schedule` | Redirect success; record created in `slb_syllabus_schedule` |
| 2 | Query `activity_log` for the new record: `SELECT * FROM activity_log WHERE subject_id = {id} AND event = 'Created'` | Log entry exists with `description` containing "Syllabus Schedule created successfully", `causer_id` = current user ID |
| 3 | Update the record via `update()` `PUT /syllabus-schedule/{id}` | Redirect success; record updated |
| 4 | Query `activity_log` for `event = 'Updated'` on same subject_id | Log entry exists with `description` containing "Syllabus Schedule updated" |
| 5 | Soft delete the record via `destroy()` `DELETE /syllabus-schedule/{id}` | Redirect success; `deleted_at` set, `is_active = 0` |
| 6 | Query `activity_log` for `event = 'Trashed'` on same subject_id | Log entry exists with `description` containing "Syllabus Schedule moved to trash" |
| 7 | Restore the trashed record via `restore()` `GET /syllabus-schedule/{id}/restore` | Redirect success; `deleted_at` = NULL, `is_active = 1` |
| 8 | Query `activity_log` for `event = 'Restored'` on same subject_id | Log entry exists with `description` containing "Syllabus Schedule restored" |
| 9 | Force delete the record via `forceDelete()` `DELETE /syllabus-schedule/{id}/force-delete` | Redirect success; record permanently removed |
| 10 | Query `activity_log` for `event = 'Deleted'` on same subject_id | Log entry exists with `description` containing "Syllabus Schedule permanently deleted" |
| 11 | Toggle status via `toggleStatus()` | Verify NO activityLog entry created for event 'Toggled' (controller returns JSON directly without activityLog call) |

---

#### TC-D26: Controller — is_active Set False Before Soft Delete in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a SyllabusSchedule record with `is_active = 1` | Record active in DB |
| 2 | Call `destroy()` on this record `DELETE /syllabus-schedule/{id}` | HTTP redirect success |
| 3 | DB query: `SELECT is_active, deleted_at FROM slb_syllabus_schedule WHERE id = {id}` | `is_active = 0`, `deleted_at` IS NOT NULL (timestamp present) |
| 4 | Inspect `SyllabusScheduleController@destroy()` source code | Method calls `$schedule->update(['is_active' => false])` BEFORE `$schedule->delete()` |
| 5 | Verify `onlyTrashed()` scope returns this record | `SyllabusSchedule::onlyTrashed()->where('id', $id)->exists()` returns true |
