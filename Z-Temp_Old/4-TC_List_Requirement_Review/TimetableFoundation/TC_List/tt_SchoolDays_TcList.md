# tt_school_days_TcList

## Module: TimetableFoundation → Timetable Masters → School Days

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | School Days (includes School Days, Day Types, Working Days, Class Working Days) |
| URL(s) | `GET /timetable-foundation/timetable-masters?tab=school-days` (school day tab), `GET /timetable-foundation/timetable-masters?tab=day-types` (day type tab), `GET /timetable-foundation/timetable-masters?tab=working-days` (working day tab), `GET /timetable-foundation/timetable-masters?tab=class-working-days` (class working day tab) |
| | **School Day Resource:** `GET|POST /timetable-foundation/school-day` (index/store), `GET /timetable-foundation/school-day/create` (create), `GET /timetable-foundation/school-day/{id}` (show), `GET|PUT|PATCH /timetable-foundation/school-day/{id}/edit` (edit/update), `DELETE /timetable-foundation/school-day/{id}` (destroy), `GET /timetable-foundation/school-day/trash/view` (trashed), `GET /timetable-foundation/school-day/{id}/restore` (restore), `DELETE /timetable-foundation/school-day/{id}/force-delete` (forceDelete), `POST /timetable-foundation/school-day/{schoolDay}/toggle-status` (toggleStatus) |
| | **Day Type Resource:** `GET|POST /timetable-foundation/day-type` (index/store), `GET /timetable-foundation/day-type/create` (create), `GET /timetable-foundation/day-type/{id}` (show), `GET|PUT|PATCH /timetable-foundation/day-type/{id}/edit` (edit/update), `DELETE /timetable-foundation/day-type/{id}` (destroy), `GET /timetable-foundation/day-type/trash/view` (trashed), `GET /timetable-foundation/day-type/{id}/restore` (restore), `DELETE /timetable-foundation/day-type/{id}/force-delete` (forceDelete), `POST /timetable-foundation/day-type/{dayType}/toggle-status` (toggleStatus) |
| | **Working Day Resource:** `GET|POST /timetable-foundation/working-day` (index/store), `GET /timetable-foundation/working-day/create` (create), `GET /timetable-foundation/working-day/{id}` (show), `GET|PUT|PATCH /timetable-foundation/working-day/{id}/edit` (edit/update), `DELETE /timetable-foundation/working-day/{id}` (destroy) |
| | **Working Day AJAX:** `POST /timetable-foundation/working-day/ajax/store` (ajaxStore), `POST /timetable-foundation/working-day/ajax/edit` (ajaxEdit), `POST /timetable-foundation/working-day/ajax/remark/{id}` (ajaxUpdateRemark), `DELETE /timetable-foundation/working-day/ajax/delete/{id}` (ajaxDestroy), `POST /timetable-foundation/working-day/ajax/initialize-calander` (ajaxInitializeWorkingDays), `DELETE /timetable-foundation/working-day/ajax/clear` (ajaxClearWorkingDays), `GET /timetable-foundation/working-day/ajax/events` (eventFeed) |
| | **Class Working Day Resource:** `GET|POST /timetable-foundation/class-working-day` (index/store), `GET /timetable-foundation/class-working-day/create` (create), `GET /timetable-foundation/class-working-day/{id}` (show), `GET|PUT|PATCH /timetable-foundation/class-working-day/{id}/edit` (edit/update), `DELETE /timetable-foundation/class-working-day/{id}` (destroy) |
| | **Class Working Day AJAX:** `POST /timetable-foundation/class-working-day/ajax/store` (ajaxStore), `DELETE /timetable-foundation/class-working-day/ajax/delete/{id}` (ajaxDestroy), `POST /timetable-foundation/class-working-day/ajax/initialize` (ajaxInitialize), `GET /timetable-foundation/class-working-day/ajax/events` (eventFeed), `GET /timetable-foundation/class-working-day/ajax/working-day-feed` (workingDayFeed) |
| Controller(s) | `Modules\TimetableFoundation\Http\Controllers\SchoolDayController` (School Days), `Modules\TimetableFoundation\Http\Controllers\DayTypeController` (Day Types), `Modules\TimetableFoundation\Http\Controllers\WorkingDayController` (Working Days), `Modules\TimetableFoundation\Http\Controllers\ClassWorkingDayController` (Class Working Days); Tab page loaded via `TimetableFoundationController@timetableMasters()` |
| Model(s) | `Modules\TimetableFoundation\Models\SchoolDay` (table: `tt_school_days`), `Modules\TimetableFoundation\Models\DayType` (table: `tt_day_types`), `Modules\TimetableFoundation\Models\WorkingDay` (table: `tt_working_days`), `Modules\TimetableFoundation\Models\ClassWorkingDay` (table: `tt_class_working_days_jnt`) |
| Validation | All controllers use inline `$request->validate()` — no Form Request classes |
| Policy(ies) | `DayPolicy` (School Days), `DayTypePolicy`, `WorkingDayPolicy`, `ClassWorkingDayPolicy` |
| Permissions | `timetable-foundation.school-day.{viewAny,view,create,update,delete,restore,forceDelete}`; `timetable-foundation.day-type.{viewAny,view,create,update,delete,restore,forceDelete}`; `timetable-foundation.working-day.{viewAny,view,create,update,delete,restore,forceDelete}`; `timetable-foundation.class-working-day.{viewAny,view,create,update,delete,restore,forceDelete}` |
| Pagination | Trash views: `10 records/page` (School Day `trashedDay()`, Day Type `trashedDayType()`, Class Working Day `trashedClassWorkingDay()`); Working Day trash route defined but controller methods not implemented |
| Soft Deletes | Yes — all 4 models use `SoftDeletes` trait |
| Activity Log | School Day: `Trashed`, `Restored`, `Deleted`, `Toggled`; Day Type: `Created`, `Updated`, `Trashed`, `Deleted`, `Restored`, `Toggled`; Working Day: `Stored`, `Updated`, `Trashed`; Class Working Day: `Created`, `Updated`, `Trashed`, `Deleted`, `Restored`, `Toggled` |

---

## 2. Pre-conditions

- Required permissions (full set): `timetable-foundation.school-day.*`, `timetable-foundation.day-type.*`, `timetable-foundation.working-day.*`, `timetable-foundation.class-working-day.*` (viewAny/view/create/update/delete/restore/forceDelete for each)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Required seed data: At least one active OrganizationAcademicSession (with `is_current = true` and defined `start_date`/`end_date`)
- For Working Days tests: At least 2 active Day Types (one working, one non-working/holiday)
- For Class Working Days tests: At least one active SchoolClass, one active Section, one active PeriodSet, existing WorkingDay records
- For bulk operations: At least 2 active SchoolClasses and 2 active Sections
- For calendar-based AJAX tests: WorkingDay records initialized via `ajaxInitializeWorkingDays`

---

## 3. Default Data Load

When the `timetable-masters` tab page loads via `TimetableFoundationController@timetableMasters()` (`GET /timetable-foundation/timetable-masters`), all four sub-tab grids are present but each tab loads its data dynamically via its own controller:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| School Days Grid | SchoolDayController@index | `SchoolDay::orderBy('ordinal')` (redirects to tab) | `is_active` on create/edit forms | None (max 7 rows) |
| Day Types Grid | DayTypeController@index | `DayType::orderBy('ordinal')` (redirects to tab) | `is_active` on create/edit forms | None (small dataset) |
| Working Days Calendar | WorkingDayController@eventFeed | `WorkingDay::with(dayType,dayType2,dayType3,dayType4)->whereBetween('date',[$start,$end])` | `is_active=true`, date range `start`/`end` | None |
| Class Working Days Calendar | ClassWorkingDayController@eventFeed | `ClassWorkingDay::with(class,section,periodSet)->whereBetween('date',[$start,$end])` | `is_active=true`, `class_ids[]`, `section_ids[]`, date range | None |
| Working Day Background Feed | ClassWorkingDayController@workingDayFeed | `WorkingDay::whereBetween('date',[$start,$end])` with `dayType` relations | `is_active=true`, date range | None |

---

## 4. Test Data Strategy

- **Test data creation**: Use direct UI CRUD for School Days and Day Types; use AJAX endpoints (`ajaxInitializeWorkingDays`, `ajaxStore`) for Working Days and Class Working Days bulk operations
- **Unique suffix**: Append `now()->format('His')` to names/codes for uniqueness
- **Date range**: Use current academic session's date range; for multi-date tests, use a contiguous 5-day window within the session
- **Pre-test cleanup**: Use Working Day `ajaxClearWorkingDays` to reset calendar; delete created records by ID after each test
- **Pagination overflow**: For trash views, create 12 records to test the 10/page pagination limit
- **Cross-module data**: Ensure `sch_organization_academic_sessions` has one `is_current = true` record with valid `start_date` and `end_date`

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_school_days`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | TINYINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | code | VARCHAR(10) | NOT NULL, UNIQUE (`uq_schoolday_code`) |
| BC-DB-03 | name | VARCHAR(20) | NOT NULL |
| BC-DB-04 | short_name | VARCHAR(5) | NOT NULL |
| BC-DB-05 | day_of_week | TINYINT UNSIGNED | NOT NULL, UNIQUE (`uq_schoolday_dow`) |
| BC-DB-06 | ordinal | TINYINT UNSIGNED | NOT NULL |
| BC-DB-07 | is_school_day | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-08 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-09 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-11 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Database Schema — `tt_day_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-12 | id | TINYINT UNSIGNED PK | Auto-increment |
| BC-DB-13 | code | VARCHAR(20) | NOT NULL, UNIQUE (`uq_daytype_code`) |
| BC-DB-14 | name | VARCHAR(100) | NOT NULL, UNIQUE (`uq_daytype_name`) |
| BC-DB-15 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-16 | is_working_day | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-17 | reduced_periods | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-18 | ordinal | TINYINT UNSIGNED | DEFAULT 1, UNIQUE (`uq_daytype_ordinal`) |
| BC-DB-19 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-20 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-21 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-22 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.3 Database Schema — `tt_working_days`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-23 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-24 | academic_session_id | SMALLINT UNSIGNED | NOT NULL, FK → `sch_organization_academic_sessions.id` |
| BC-DB-25 | date | DATE | NOT NULL, UNIQUE (`uq_workday_date`) |
| BC-DB-26 | day_type1_id | TINYINT UNSIGNED | NOT NULL, FK → `tt_day_types.id`, ON DELETE RESTRICT |
| BC-DB-27 | day_type2_id | TINYINT UNSIGNED | DEFAULT NULL, FK → `tt_day_types.id`, ON DELETE RESTRICT |
| BC-DB-28 | day_type3_id | TINYINT UNSIGNED | DEFAULT NULL, FK → `tt_day_types.id`, ON DELETE RESTRICT |
| BC-DB-29 | day_type4_id | TINYINT UNSIGNED | DEFAULT NULL, FK → `tt_day_types.id`, ON DELETE RESTRICT |
| BC-DB-30 | is_school_day | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-31 | remarks | VARCHAR(255) | DEFAULT NULL |
| BC-DB-32 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-33 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-34 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-35 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.4 Database Schema — `tt_class_working_days_jnt`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-36 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-37 | academic_session_id | SMALLINT UNSIGNED | NOT NULL |
| BC-DB-38 | date | DATE | NOT NULL |
| BC-DB-39 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` |
| BC-DB-40 | section_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_sections.id` |
| BC-DB-41 | working_day_id | INT UNSIGNED | NOT NULL, FK → `tt_working_days.id` |
| BC-DB-42 | is_exam_day | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-43 | is_ptm_day | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-44 | is_half_day | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-45 | is_holiday | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-46 | is_study_day | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-47 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-48 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-49 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-50 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.5 Validation Rules — SchoolDayController (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | code | required, string, max:10, unique:tt_school_days,code | Default Laravel messages |
| BC-VAL-02 | name | required, string, max:20 | Default Laravel messages |
| BC-VAL-03 | short_name | required, string, max:5 | Default Laravel messages |
| BC-VAL-04 | day_of_week | required, integer, between:1,7, unique:tt_school_days,day_of_week | Default Laravel messages |
| BC-VAL-05 | ordinal | required, integer, min:1, unique:tt_school_days,ordinal | Default Laravel messages |
| BC-VAL-06 | is_school_day | nullable | Normalized via `$request->boolean()` |
| BC-VAL-07 | is_active | nullable | Normalized via `$request->boolean()` |

### 5.6 Validation Rules — SchoolDayController (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | code | required, string, max:10, unique:tt_school_days,code,`{id}` | Default Laravel messages |
| BC-VAL-U02 | day_of_week | required, integer, between:1,7, unique:tt_school_days,day_of_week,`{id}` | Default Laravel messages |
| BC-VAL-U03 | ordinal | required, integer, min:1, unique:tt_school_days,ordinal,`{id}` | Default Laravel messages |
| BC-VAL-U04 | is_school_day | nullable | Normalized via `$request->boolean()` |
| BC-VAL-U05 | is_active | nullable | Normalized via `$request->boolean()` |

### 5.7 Validation Rules — DayTypeController (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-08 | code | required, string, max:20, unique:tt_day_types,code (whereNull deleted_at) | Default Laravel messages |
| BC-VAL-09 | name | required, string, max:100, unique:tt_day_types,name (whereNull deleted_at) | Default Laravel messages |
| BC-VAL-10 | description | nullable, string, max:255 | Default Laravel messages |
| BC-VAL-11 | ordinal | required, integer, min:1, unique:tt_day_types,ordinal (whereNull deleted_at) | Default Laravel messages |
| BC-VAL-12 | is_active | required (nullable via `$request->boolean()`) | Default Laravel messages |

### 5.8 Validation Rules — DayTypeController (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U06 | code | required, string, max:20, unique:tt_day_types,code,`{id}` (whereNull deleted_at) | Default Laravel messages |
| BC-VAL-U07 | name | required, string, max:100, unique:tt_day_types,name,`{id}` (whereNull deleted_at) | Default Laravel messages |
| BC-VAL-U08 | description | nullable, string, max:255 | Default Laravel messages |
| BC-VAL-U09 | ordinal | required, integer, min:1, unique:tt_day_types,ordinal,`{id}` (whereNull deleted_at) | Default Laravel messages |
| BC-VAL-U10 | is_working_day | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-U11 | reduced_periods | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-U12 | is_active | nullable | Normalized via `$request->boolean()` |

### 5.9 Validation Rules — WorkingDayController (Create / Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-13 | date | required, date | Default Laravel messages |
| BC-VAL-14 | day_type1_id | required, exists:tt_day_types,id | Default Laravel messages |
| BC-VAL-15 | is_school_day | required, boolean | Default Laravel messages |
| BC-VAL-16 | is_active | nullable, boolean | Default set to `true` via `$request->boolean('is_active', true)` |

### 5.10 Validation Rules — WorkingDay AJAX Endpoints

| BC ID | Endpoint | Field(s) | Rule(s) |
|-------|----------|----------|---------|
| BC-VAL-17 | ajaxStore | start | required, date |
| BC-VAL-18 | ajaxStore | end | nullable, date |
| BC-VAL-19 | ajaxStore | day_type_id | required, exists:tt_day_types,id |
| BC-VAL-20 | ajaxEdit | id | required, string (format: `wd-{id}-{slot}`) |
| BC-VAL-21 | ajaxEdit | date | required, date |
| BC-VAL-22 | ajaxUpdateRemark | remarks | nullable, string, max:500 |
| BC-VAL-23 | toggleStatus | is_active | required, boolean |

### 5.11 Validation Rules — ClassWorkingDayController (Create / Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-24 | academic_session_id | required, integer, exists:sch_organization_academic_sessions,id | Default Laravel messages |
| BC-VAL-25 | date | required, date | Default Laravel messages |
| BC-VAL-26 | class_id | required, integer, exists:sch_classes,id | Default Laravel messages |
| BC-VAL-27 | section_id | nullable, integer, exists:sch_sections,id | Default Laravel messages |
| BC-VAL-28 | working_day_id | nullable, integer, exists:tt_working_days,id | Default Laravel messages |
| BC-VAL-29 | period_set_id | nullable, integer, exists:tt_period_sets,id | Default Laravel messages |
| BC-VAL-30 | is_exam_day | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-31 | is_ptm_day | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-32 | is_half_day | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-33 | is_holiday | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-34 | is_study_day | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-35 | is_active | nullable, boolean | Normalized via `$request->boolean()` |

### 5.12 Validation Rules — ClassWorkingDay AJAX Endpoints

| BC ID | Endpoint | Field(s) | Rule(s) |
|-------|----------|----------|---------|
| BC-VAL-36 | ajaxStore (bulk) | start | required, date |
| BC-VAL-37 | ajaxStore (bulk) | end | nullable, date |
| BC-VAL-38 | ajaxStore (bulk) | class_ids | required, array, min:1; each: integer, exists:sch_classes,id |
| BC-VAL-39 | ajaxStore (bulk) | section_ids | nullable, array; each: integer, exists:sch_sections,id |
| BC-VAL-40 | ajaxStore (bulk) | day_type | required, string (exam/ptm/half_day/holiday/study) |
| BC-VAL-41 | ajaxStore (bulk) | period_set_id | nullable, integer, exists:tt_period_sets,id |
| BC-VAL-42 | ajaxInitialize | class_ids | required, array, min:1; each: integer, exists:sch_classes,id |
| BC-VAL-43 | ajaxInitialize | section_ids | nullable, array; each: integer, exists:sch_sections,id |
| BC-VAL-44 | ajaxInitialize | period_set_id | nullable, integer, exists:tt_period_sets,id |
| BC-VAL-45 | ajaxInitialize | clear_existing | required, boolean |

### 5.13 Authorization

| BC ID | Permission | Controller Methods | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | timetable-foundation.school-day.viewAny | index(), show() | Without → 403 |
| BC-AUTH-02 | timetable-foundation.school-day.view | — | Policy defines but not used as custom gate in controller |
| BC-AUTH-03 | timetable-foundation.school-day.create | store() (without id), create() | Without → 403 |
| BC-AUTH-04 | timetable-foundation.school-day.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | timetable-foundation.school-day.delete | destroy() | Without → 403 |
| BC-AUTH-06 | timetable-foundation.school-day.restore | restore(), trashedDay() | Without → 403 |
| BC-AUTH-07 | timetable-foundation.school-day.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | timetable-foundation.day-type.viewAny | index(), show() | Without → 403 |
| BC-AUTH-09 | timetable-foundation.day-type.create | store(), create() | Without → 403 |
| BC-AUTH-10 | timetable-foundation.day-type.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-11 | timetable-foundation.day-type.delete | destroy() | Without → 403 |
| BC-AUTH-12 | timetable-foundation.day-type.restore | restore(), trashedDayType() | Without → 403 |
| BC-AUTH-13 | timetable-foundation.day-type.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-14 | timetable-foundation.working-day.viewAny | index(), show(), eventFeed() | Without → 403 |
| BC-AUTH-15 | timetable-foundation.working-day.create | store(), create(), ajaxStore(), ajaxInitializeWorkingDays() | Without → 403 |
| BC-AUTH-16 | timetable-foundation.working-day.update | update(), edit(), ajaxEdit(), ajaxUpdateRemark(), toggleStatus() | Without → 403 |
| BC-AUTH-17 | timetable-foundation.working-day.delete | destroy(), ajaxDestroy(), ajaxClearWorkingDays() | Without → 403 |
| BC-AUTH-18 | timetable-foundation.class-working-day.viewAny | index(), show(), eventFeed(), workingDayFeed() | Without → 403 |
| BC-AUTH-19 | timetable-foundation.class-working-day.create | store(), create(), ajaxStore(), ajaxInitialize() | Without → 403 |
| BC-AUTH-20 | timetable-foundation.class-working-day.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-21 | timetable-foundation.class-working-day.delete | destroy(), ajaxDestroy() | Without → 403 |
| BC-AUTH-22 | timetable-foundation.class-working-day.restore | restore(), trashedClassWorkingDay() | Without → 403 |
| BC-AUTH-23 | timetable-foundation.class-working-day.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-24 | Guest access | All routes | Redirect to `/login` |

### 5.14 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | School Day create with `is_school_day=true` | Record saved with `is_school_day = 1`; day counted as school day |
| BC-BIZ-02 | School Day create with `is_school_day=false` | Record saved with `is_school_day = 0`; day excluded from school day calculations |
| BC-BIZ-03 | School Day code uniqueness | No two school days can share the same `code`; unique constraint `uq_schoolday_code` |
| BC-BIZ-04 | School Day day_of_week uniqueness | No two school days can share the same `day_of_week`; unique constraint `uq_schoolday_dow` |
| BC-BIZ-05 | School Day destroy deactivates before soft-delete | `destroy()` sets `is_active = false`, saves, then calls `delete()` |
| BC-BIZ-06 | School Day restore re-activates | `restore()` nullifies `deleted_at`, then sets `is_active = true` |
| BC-BIZ-07 | School Day toggleStatus flips is_active | AJAX `toggleStatus()` sets `is_active` to the boolean value sent in request |
| BC-BIZ-08 | Day Type code auto-uppercased on store | `store()` applies `strtoupper()` to `$validated['code']` before create |
| BC-BIZ-09 | Day Type code auto-uppercased on update | `update()` applies `strtoupper()` to `$validated['code']` before update |
| BC-BIZ-10 | Day Type uniqueness scoped to non-deleted | `Rule::unique(...)->whereNull('deleted_at')` allows soft-deleted records to have same code/name/ordinal |
| BC-BIZ-11 | Day Type destroy deactivates before soft-delete | `destroy()` sets `is_active = false`, saves, then calls `delete()` |
| BC-BIZ-12 | Day Type restore re-activates | `restore()` nullifies `deleted_at`, then sets `is_active = true` |
| BC-BIZ-13 | Working Day academic_session_id auto-set | `store()` sets `academic_session_id` from `OrganizationAcademicSession::where('is_current',true)->firstOrFail()->id` |
| BC-BIZ-14 | Working Day unique date constraint | Each `date` can have only one row; UNIQUE constraint `uq_workday_date` enforced at DB level |
| BC-BIZ-15 | Working Day - max 4 day types per date | `addDayTypeToWorkingDay()` throws RuntimeException if 4 slots already filled |
| BC-BIZ-16 | Working Day - no duplicate day_type on same date | `addDayTypeToWorkingDay()` throws RuntimeException if same day_type already assigned |
| BC-BIZ-17 | Working Day - mutual exclusion: working + non-working types | Cannot add working type if non-working exists; cannot add non-working if working exists |
| BC-BIZ-18 | Working Day - at most one non-working type per date | Cannot add second non-working day type to a date that already has one |
| BC-BIZ-19 | Working Day - is_school_day auto-computed on add | When a day type is added, `is_school_day` recomputed based on remaining types |
| BC-BIZ-20 | Working Day - slot compaction on remove | `removeSlotAndCompact()` shifts remaining day types upward to fill gaps |
| BC-BIZ-21 | Working Day - ajaxInitialize bulk creates session days | Creates/updates WorkingDay for each date in academic session; school-closed days get Holiday, rest get Working Day |
| BC-BIZ-22 | Working Day - ajaxInitialize uses Config for closed days | Uses `week_start_day` and `default_school_closed_days_per_week` from `tt_configs` |
| BC-BIZ-23 | Working Day - ajaxDestroy last slot deletes row | When last day type removed, `WorkingDay` row is force-deleted; linked ClassWorkingDay records also force-deleted |
| BC-BIZ-24 | Working Day - ajaxDestroy requires_confirm for linked records | If `ClassWorkingDay` records exist for the last slot, returns `requires_confirm=true` unless `force=true` |
| BC-BIZ-25 | Class Working Day - unique (class_id, working_day_id) | UNIQUE constraint `uq_class_working_day` at DB level |
| BC-BIZ-26 | Class Working Day - ajaxStore validates parent WorkingDay exists | Throws RuntimeException if date not configured in Working Days |
| BC-BIZ-27 | Class Working Day - ajaxInitialize copies from Working Days | Creates ClassWorkingDay for each date, mapping `is_school_day` to `is_study_day` |
| BC-BIZ-28 | Class Working Day - destroy deactivates before soft-delete | `destroy()` sets `is_active = false`, saves, then calls `delete()` |
| BC-BIZ-29 | Class Working Day - restore re-activates | `restore()` nullifies `deleted_at`, then sets `is_active = true` |
| BC-BIZ-30 | Class Working Day - ajaxDestroy uses forceDelete | `ajaxDestroy()` calls `forceDelete()` directly without soft-delete |
| BC-BIZ-31 | Class Working Day - isTeachingAllowed helper | Returns true only when `is_active && is_study_day && !is_holiday` |
| BC-BIZ-32 | Class Working Day - isSpecialDay helper | Returns true when any of `is_exam_day`, `is_ptm_day`, `is_half_day` is true |
| BC-BIZ-33 | Tab loads via TimetableFoundationController@timetableMasters() at GET /timetable-foundation/timetable-masters with tab parameter | Navigating to `GET /timetable-foundation/timetable-masters?tab=school-days` (or `day-types`, `working-days`, `class-working-days`) loads the page with corresponding sub-tab active |

### 5.15 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | day_type1_id (tt_working_days) | tt_day_types (id) | RESTRICT |
| BC-REF-02 | day_type2_id (tt_working_days) | tt_day_types (id) | RESTRICT |
| BC-REF-03 | day_type3_id (tt_working_days) | tt_day_types (id) | RESTRICT |
| BC-REF-04 | day_type4_id (tt_working_days) | tt_day_types (id) | RESTRICT |

> **Note:** DDL for `tt_school_days` has no explicit FK constraints. `tt_class_working_days_jnt` has FKs to `sch_classes`, `sch_sections`, and `tt_working_days` but `ON DELETE` actions are not specified in the DDL (uses InnoDB default RESTRICT behavior).

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | School Day Tab Loads With All UI Elements | Page loads with school days tab active; grid/table showing existing school days; Create button visible | — | — | ⬜ |
| TC-P02 | Create School Day With All Required Fields | School day created with code, name, short_name, day_of_week, ordinal; redirect to tab with success message | — | — | ⬜ |
| TC-P03 | Create School Day With is_school_day = false | `is_school_day` set to 0; day excluded from school day calculations | — | — | ⬜ |
| TC-P04 | Create School Day With is_active = false | `is_active` set to 0; day hidden from active dropdowns | — | — | ⬜ |
| TC-P05 | Edit School Day Loads Pre-Filled Data | Edit form shows existing school day data; all fields populated correctly | — | — | ⬜ |
| TC-P06 | Update School Day Code And Name | Code and name updated; unique validation on code respects ignore of own ID | — | — | ⬜ |
| TC-P07 | Toggle School Day Active Status via AJAX | `toggleStatus()` flips `is_active`; JSON response with `success=true` and new `is_active` value | — | — | ⬜ |
| TC-P08 | View School Day Show Page | Show page displays all fields: code, name, short_name, day_of_week, ordinal, status | — | — | ⬜ |
| TC-P09 | Soft Delete School Day | `destroy()` sets `is_active=false`, soft-deletes record; success flash message | — | — | ⬜ |
| TC-P10 | Restore School Day From Trash | `restore()` nullifies `deleted_at`, sets `is_active=true`; record reappears in active list | — | — | ⬜ |
| TC-P11 | Force Delete School Day Permanently | `forceDelete()` removes record from DB permanently; redirect with flash message | — | — | ⬜ |
| TC-P12 | Trash School Day List Shows Deleted Records | `trashedDay()` returns only soft-deleted school days ordered by day_of_week (10/page) | — | — | ⬜ |
| TC-P13 | Day Type Tab Loads With All UI Elements | Day types tab active; grid with existing day types; Create button visible | — | — | ⬜ |
| TC-P14 | Create Day Type With All Fields | Day type created with code (auto-uppercased), name, description, ordinal; activity logged as 'Created' | — | — | ⬜ |
| TC-P15 | Create Day Type With is_working_day = false | `is_working_day` set to 0; day type treated as non-working (holiday) | — | — | ⬜ |
| TC-P16 | Create Day Type With reduced_periods = true | `reduced_periods` set to 1; signals fewer periods on this day | — | — | ⬜ |
| TC-P17 | Update Day Type Name And Ordinal | Day type updated; code remains uppercased; activity logged as 'Updated' | — | — | ⬜ |
| TC-P18 | Toggle Day Type Active Status via AJAX | `toggleStatus()` flips `is_active`; JSON response with `success=true` | — | — | ⬜ |
| TC-P19 | Soft Delete Day Type | `destroy()` deactivates then soft-deletes; activity logged as 'Trashed' | — | — | ⬜ |
| TC-P20 | Restore Day Type From Trash | `restore()` re-activates; record returns to active list | — | — | ⬜ |
| TC-P21 | Force Delete Day Type Permanently | `forceDelete()` removes record permanently; activity logged as 'Deleted' | — | — | ⬜ |
| TC-P22 | Working Day Tab Calendar Loads | Calendar view renders with WorkingDay events; eventFeed returns JSON for visible date range | — | — | ⬜ |
| TC-P23 | Create Working Day via Standard Form | Working day created with date, day_type1_id, academic_session_id auto-set; redirect with success | — | — | ⬜ |
| TC-P24 | AJAX Store Single Date Working Day | `ajaxStore()` creates Working Day with one day type; JSON `status=true` | — | — | ⬜ |
| TC-P25 | AJAX Store Date Range Working Day | `ajaxStore()` creates Working Days for each date in range; `applied` equals date count | — | — | ⬜ |
| TC-P26 | AJAX Stack Multiple Day Types on Same Date | Adding day types fills slot 2, 3, 4 sequentially; `is_school_day` computed correctly | — | — | ⬜ |
| TC-P27 | AJAX Edit Move Day Type to Another Date | `ajaxEdit()` removes day type from source, adds to target; JSON success | — | — | ⬜ |
| TC-P28 | AJAX Update Remark | `ajaxUpdateRemark()` saves remark text; JSON returns saved remark | — | — | ⬜ |
| TC-P29 | AJAX Initialize Working Days for Academic Session | `ajaxInitializeWorkingDays()` creates days across session; school-closed days set as Holiday, rest as Working Day; JSON with `data.created` count | — | — | ⬜ |
| TC-P30 | AJAX Remove Single Day Type Slot | `ajaxDestroy()` removes one slot; remaining slots compacted upward | — | — | ⬜ |
| TC-P31 | AJAX Clear All Working Days | `ajaxClearWorkingDays()` force-deletes all WorkingDays and linked ClassWorkingDays in session | — | — | ⬜ |
| TC-P32 | Class Working Day Tab Calendar Loads | Calendar renders with class working day events; eventFeed and workingDayFeed return JSON | — | — | ⬜ |
| TC-P33 | Create Class Working Day via Standard Form | Class working day created with class_id, date, flags; success flash message | — | — | ⬜ |
| TC-P34 | AJAX Bulk Store Class Working Days | `ajaxStore()` creates CWD across class_ids[] × section_ids[] × date range; JSON with count | — | — | ⬜ |
| TC-P35 | AJAX Bulk Store With Notification | When `send_notification=true`, `SpecialDayAssigned` event dispatched | — | — | ⬜ |
| TC-P36 | AJAX Initialize Class Working Days | `ajaxInitialize()` copies Working Days to CWD for selected classes; `is_holiday` and `is_study_day` set correctly | — | — | ⬜ |
| TC-P37 | AJAX Delete Single Class Working Day | `ajaxDestroy()` force-deletes record; JSON `status=true` | — | — | ⬜ |
| TC-P38 | Toggle Class Working Day Active Status via AJAX | `toggleStatus()` flips `is_active`; JSON response with `success=true` | — | — | ⬜ |
| TC-P39 | Working Day Event Feed Returns Colored Events | `eventFeed()` returns JSON array; each event has `backgroundColor` from `DAY_TYPE_COLORS` mapping | — | — | ⬜ |
| TC-P40 | Full Lifecycle: Create School Day → Edit → Toggle → Delete → Trash → Restore → Force Delete | All transitions succeed; activity logged at each step | — | — | ⬜ |
| TC-P41 | Full Lifecycle: Create Day Type → Edit → Toggle → Delete → Restore → Force Delete | All transitions succeed; code stays uppercased throughout | — | — | ⬜ |
| TC-P42 | Full Calendar Lifecycle: Initialize Working Days → Add Day Types → Move → Remove | All AJAX operations succeed; calendar reflects all changes | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing School Day `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing School Day `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing School Day `short_name` | Validation error: "The short name field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing School Day `day_of_week` | Validation error: "The day of week field is required." | — | — | ⬜ |
| TC-N05 | Required — Missing School Day `ordinal` | Validation error: "The ordinal field is required." | — | — | ⬜ |
| TC-N06 | Duplicate — School Day `code` Already Exists | Validation error on unique:tt_school_days,code | — | — | ⬜ |
| TC-N07 | Duplicate — School Day `day_of_week` Already Exists | Validation error on unique:tt_school_days,day_of_week | — | — | ⬜ |
| TC-N08 | Duplicate — School Day `ordinal` Already Exists | Validation error on unique:tt_school_days,ordinal | — | — | ⬜ |
| TC-N09 | Max Length — School Day `code` > 10 Characters | Validation error on code.max | — | — | ⬜ |
| TC-N10 | Max Length — School Day `name` > 20 Characters | Validation error on name.max | — | — | ⬜ |
| TC-N11 | Max Length — School Day `short_name` > 5 Characters | Validation error on short_name.max | — | — | ⬜ |
| TC-N12 | Invalid Range — `day_of_week` < 1 or > 7 | Validation error on day_of_week.between | — | — | ⬜ |
| TC-N13 | Invalid Range — `ordinal` < 1 | Validation error on ordinal.min | — | — | ⬜ |
| TC-N14 | Required — Missing Day Type `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N15 | Required — Missing Day Type `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N16 | Required — Missing Day Type `ordinal` | Validation error: "The ordinal field is required." | — | — | ⬜ |
| TC-N17 | Duplicate — Day Type `code` Already Exists | Validation error on code unique | — | — | ⬜ |
| TC-N18 | Duplicate — Day Type `name` Already Exists | Validation error on name unique | — | — | ⬜ |
| TC-N19 | Duplicate — Day Type `ordinal` Already Exists | Validation error on ordinal unique | — | — | ⬜ |
| TC-N20 | Max Length — Day Type `code` > 20 Characters | Validation error on code.max | — | — | ⬜ |
| TC-N21 | Max Length — Day Type `name` > 100 Characters | Validation error on name.max | — | — | ⬜ |
| TC-N22 | Max Length — Day Type `description` > 255 Characters | Validation error on description.max | — | — | ⬜ |
| TC-N23 | Invalid Ordinal — Day Type `ordinal` < 1 | Validation error on ordinal.min | — | — | ⬜ |
| TC-N24 | Required — Missing Working Day `date` | Validation error: "The date field is required." | — | — | ⬜ |
| TC-N25 | Required — Missing Working Day `day_type1_id` | Validation error: "The day type1 id field is required." | — | — | ⬜ |
| TC-N26 | Invalid FK — Working Day `day_type1_id` Non-Existent | Validation error on day_type1_id.exists | — | — | ⬜ |
| TC-N27 | Duplicate — Working Day `date` Already Exists | DB unique constraint violation on `uq_workday_date` | — | — | ⬜ |
| TC-N28 | Working Day AJAX Max 4 Slots Exceeded | `addDayTypeToWorkingDay()` throws RuntimeException "This date already has 4 day types (max)." | — | — | ⬜ |
| TC-N29 | Working Day AJAX Duplicate Day Type On Same Date | `addDayTypeToWorkingDay()` throws RuntimeException "already assigned to this date." | — | — | ⬜ |
| TC-N30 | Working Day AJAX — Add Working Type To Holiday Date | RuntimeException: "Cannot add a working day type — this date is already a holiday." | — | — | ⬜ |
| TC-N31 | Working Day AJAX — Add Holiday To Working Date | RuntimeException: "Cannot add a holiday — this date already has working day type(s)." | — | — | ⬜ |
| TC-N32 | Working Day AJAX — Add Second Holiday Type | RuntimeException: "Only one holiday type allowed per date." | — | — | ⬜ |
| TC-N33 | Working Day AJAX Delete — Not Found (404) | `ajaxDestroy()` with invalid ID → JSON `status=false`, 404 | — | — | ⬜ |
| TC-N34 | Working Day AJAX Delete — Empty Slot | `ajaxDestroy()` on already-empty slot → JSON `status=false`, "That slot is already empty." | — | — | ⬜ |
| TC-N35 | Working Day AJAX Initialize — No Academic Session | If no current session → JSON `status=false`, "No current academic session found or session has no start/end dates." | — | — | ⬜ |
| TC-N36 | Working Day AJAX Initialize — No Active Working Day Type | If no working day type → JSON `status=false`, "No active Working Day type found." | — | — | ⬜ |
| TC-N37 | Working Day AJAX Initialize — No Active Holiday Type | If no holiday type → JSON `status=false`, "No active Holiday day type found." | — | — | ⬜ |
| TC-N38 | Required — Missing Class Working Day `class_id` | Validation error: "The class id field is required." | — | — | ⬜ |
| TC-N39 | Required — Missing Class Working Day `academic_session_id` | Validation error: "The academic session id field is required." | — | — | ⬜ |
| TC-N40 | Invalid FK — Class Working Day `class_id` Non-Existent | Validation error on class_id.exists | — | — | ⬜ |
| TC-N41 | Duplicate — Class Working Day (class_id, working_day_id) Exists | DB unique constraint violation on `uq_class_working_day` | — | — | ⬜ |
| TC-N42 | Class Working Day AJAX Store — Date Not Configured | If date has no WorkingDay record → RuntimeException with 422 JSON | — | — | ⬜ |
| TC-N43 | Class Working Day AJAX Initialize — No Working Days Found | If no WorkingDays in session → JSON `status=false`, "No working days found. Please auto-fill Working Days first." | — | — | ⬜ |
| TC-N44 | Permission 403 — No School Day Permissions | 403 Forbidden on all school day CRUD endpoints for user without gates | — | — | ⬜ |
| TC-N45 | Permission 403 — No Day Type Permissions | 403 Forbidden on all day type CRUD endpoints | — | — | ⬜ |
| TC-N46 | Permission 403 — No Working Day Permissions | 403 Forbidden on working day routes | — | — | ⬜ |
| TC-N47 | Permission 403 — No Class Working Day Permissions | 403 Forbidden on class working day routes | — | — | ⬜ |
| TC-N48 | Guest Access Redirect For All Routes | Redirect to /login for all school day/day type/working day/class working day routes | — | — | ⬜ |
| TC-N49 | Edit/Show/Delete School Day With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N50 | Edit/Show/Delete Day Type With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | School Day — Soft Delete Sets is_active=false Before Delete | `destroy()` sets `is_active=false`, saves, then `delete()`; `restore()` sets `is_active=true` | — | — | ⬜ |
| TC-D02 | B | Day Type — is_working_day Flag Determines Working Day AJAX Stacking Behavior | Working day types stack together; holiday types blocked from stacking with working types | — | — | ⬜ |
| TC-D03 | B | Day Type — Code Auto-Uppercased on Create and Update | Code stored as uppercase even when entered lowercase; persists through update | — | — | ⬜ |
| TC-D04 | C | Day Type — Unique Scope Ignores Soft-Deleted Records | `whereNull('deleted_at')` in unique rule allows reusing code/name/ordinal after soft-delete | — | — | ⬜ |
| TC-D05 | D | Working Day — academic_session_id Auto-From Current Session | New working day gets session where `is_current=true`; no user selection required | — | — | ⬜ |
| TC-D06 | E | Working Day — Slot Compaction After Removal | Removing slot 2 shifts slot 3→2 and slot 4→3; `day_type1_id` never null when any slot has value | — | — | ⬜ |
| TC-D07 | F | Working Day — is_school_day Recomputes After Add/Remove | Adding working day type sets `is_school_day=true`; removing all working types sets it `false` | — | — | ⬜ |
| TC-D08 | G | Working Day — ajaxDestroy Last Slot Triggers Row Deletion | Deleting last day type force-deletes WorkingDay row and linked ClassWorkingDay records | — | — | ⬜ |
| TC-D09 | G | Working Day — ajaxDestroy Requires Confirm When Linked Records Exist | If ClassWorkingDay records exist, returns `requires_confirm=true` with `linked_count`; only deletes when `force=true` | — | — | ⬜ |
| TC-D10 | H | Working Day — ajaxInitialize Reads Config For Closed Days | Uses `week_start_day` and `default_school_closed_days_per_week` from `tt_configs` to determine which days are closed | — | — | ⬜ |
| TC-D11 | I | Day Type — RESTRICT FK Prevents Deletion When Referenced | DayType with id used in `tt_working_days.day_type1_id` cannot be force-deleted; FK constraint violation | — | — | ⬜ |
| TC-D12 | J | Class Working Day — (class_id, working_day_id) Unique Constraint | Creating duplicate (class_id, working_day_id) combination throws integrity constraint violation | — | — | ⬜ |
| TC-D13 | K | Class Working Day — isTeachingAllowed Logic | Returns true only when `is_active=1 AND is_study_day=1 AND is_holiday=0`; false otherwise | — | — | ⬜ |
| TC-D14 | L | Class Working Day — isSpecialDay Logic | Returns true when any of is_exam_day, is_ptm_day, is_half_day is true | — | — | ⬜ |
| TC-D15 | M | Class Working Day — ajaxInitialize Maps is_school_day to is_study_day | WorkingDays with `is_school_day=1` become `is_study_day=1`; `is_school_day=0` become `is_holiday=1` | — | — | ⬜ |
| TC-D16 | N | Class Working Day — ajaxStore Resolves day_type String to Boolean Flags | `resolveDayTypeFlags()` maps 'exam'/'ptm'/'half_day'/'holiday'/'study' to correct boolean combinations | — | — | ⬜ |
| TC-D17 | O | Class Working Day — ajaxStore Restores + Updates Existing Soft-Deleted Records | When existing record found with same (class_id, working_day_id), it's restored and updated; no duplicate created | — | — | ⬜ |
| TC-D18 | P | Working Day — Working Day Model $casts Verification | `is_school_day`, `is_active` cast to boolean; `day_type*_id` cast to integer; `date` cast to date; values stored/retrieved correctly | — | — | ⬜ |
| TC-D19 | Q | Day Type — DayType Model $casts Verification | `is_working_day`, `reduced_periods`, `is_active` cast to boolean; `ordinal` cast to integer | — | — | ⬜ |
| TC-D20 | R | School Day — SchoolDay Model $casts Verification | `is_school_day`, `is_active` cast to boolean; `day_of_week`, `ordinal` cast to integer | — | — | ⬜ |
| TC-D21 | S | Class Working Day — ClassWorkingDay Model $casts and Relationships | All 5 flag fields cast to boolean; `belongsTo` relationships for `class`, `section`, `workingDay`, `periodSet`, `academicSession` defined; eager loading works | — | — | ⬜ |
| TC-D22 | T | Working Day — WorkingDay Relationships (4 belongsTo DayType) | `dayType()`, `dayType2()`, `dayType3()`, `dayType4()` each return correct DayType; null for empty slots; eager loading loads all | — | — | ⬜ |
| TC-D23 | U | Controller — findOrFail on edit/update/show/destroy with Invalid IDs | Non-existent ID throws `ModelNotFoundException` → HTTP 404 for all CRUD methods across all 4 controllers | — | — | ⬜ |
| TC-D24 | V | Controller — Gate::authorize() Called Before All CRUD Methods | Each controller method calls `Gate::authorize()` with correct permission string; without permission → 403 Forbidden | — | — | ⬜ |
| TC-D25 | W | Controller — Activity Logged On State Changes | School Day: Trashed/Restored/Deleted/Toggled; Day Type: Created/Updated/Trashed/Deleted/Restored/Toggled; Working Day: Stored/Updated/Trashed; Class Working Day: Created/Updated/Trashed/Deleted/Restored/Toggled | — | — | ⬜ |
| TC-D26 | X | Policy — All 4 Policies Define All Required Gates | DayPolicy, DayTypePolicy, WorkingDayPolicy, ClassWorkingDayPolicy each define viewAny/view/create/update/delete/restore/forceDelete methods; each delegates to `$user->can()` | — | — | ⬜ |
| TC-D27 | Y | Routes — Resourceful + Custom Routes Registered for All 4 Controllers | SchoolDay: 9 routes; DayType: 9 routes; WorkingDay: resource + 7 AJAX routes; ClassWorkingDay: resource + 5 AJAX + 3 trash routes; each maps to correct controller method | — | — | ⬜ |
| TC-D28 | Z | Working Day — ajaxInitialize Handles Trashed Dates Correctly | When date has soft-deleted WorkingDay, it's restored and updated instead of creating new | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — $fillable Matches DDL Columns (All 4 Models) | SchoolDay, DayType, WorkingDay, ClassWorkingDay $fillable arrays include all non-PK, non-timestamp columns from DDL; no extra columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts for Booleans/Integers/Dates (All 4 Models) | Boolean flags cast to 'boolean'; integer FK fields cast to 'integer'; date/created_at/updated_at/deleted_at cast to 'datetime'/'date' | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes Trait Implemented on All 4 Models | All models use `SoftDeletes`; `deleted_at` column present; `onlyTrashed()`, `withTrashed()`, `restore()` work | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — Relationships Defined Per FK | SchoolDay: (no explicit relationships); DayType: `timetableTypes()` hasMany; WorkingDay: 4 belongsTo DayType; ClassWorkingDay: 5 belongsTo (class, section, workingDay, periodSet, academicSession) | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Try-Catch Exception Handling on Write Methods | SchoolDayController/Destroy: no try-catch; DayTypeController store/update: no try-catch; WorkingDayController ajaxStore/ajaxEdit/ajaxDestroy: try-catch for RuntimeException; ClassWorkingDayController ajaxStore: try-catch for RuntimeException | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB Transactions on Multi-Step Writes | WorkingDayController ajaxStore/ajaxEdit/ajaxDestroy/ajaxInitializeWorkingDays/ajaxClearWorkingDays: DB::transaction() wraps multi-step operations; ajaxInitializeWorkingDays uses DB::transaction for all date creation | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — Gate::authorize() on Every Method | All 4 controllers call Gate::authorize() at start of every public method; no unauthenticated write access | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — Activity Logged on All State Changes | Every create/update/delete/restore/forceDelete/toggleStatus across all 4 controllers has `activityLog()` call | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — is_active=false Before Soft Delete | SchoolDayController destroy(), DayTypeController destroy(), ClassWorkingDayController destroy() all set `is_active=false` before `delete()` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — toggleStatus() Flips is_active via AJAX | All 4 controllers have toggleStatus(); validates `is_active` as required boolean; saves; returns JSON `{success, is_active, message}` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — Trash/Restore/ForceDelete Flow | trashedDay/trashedDayType/trashedClassWorkingDay uses `onlyTrashed()`; restore uses `onlyTrashed()->findOrFail()` then `restore()` then sets `is_active=true`; forceDelete uses `withTrashed()->findOrFail()` then `forceDelete()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — JSON Success Response After AJAX Operations (Working Day / Class Working Day) | WorkingDay AJAX endpoints return JSON `{status, message}`; toggleStatus returns `{success, is_active, message}`; ClassWorkingDay AJAX endpoints return JSON `{status, message, count}` | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — Flash Success Response After CRUD Operations (School Day / Day Type) | SchoolDayController and DayTypeController redirect with `->with('success', flash(...))` after create/update/destroy/restore/forceDelete | — | — | ◌ |
| TC-CR14 | CR | P1 | Validation — All Fields Covered; Unique Rules Ignore Current ID on Update | SchoolDay update: `unique:...,code,{id}` ignores own record; DayType: `Rule::unique(...)->ignore($id)`; WorkingDay/ClassWorkingDay: no unique rules on date (enforced at DB level) | — | — | ◌ |
| TC-CR15 | CR | P1 | Policy — All Required Methods Defined; Permission Strings Match Routes | DayPolicy, DayTypePolicy, WorkingDayPolicy, ClassWorkingDayPolicy each have 7 methods (viewAny/view/create/update/delete/restore/forceDelete); permission strings match route gate calls | — | — | ◌ |
| TC-CR16 | CR | P1 | Routes — Resource + Custom Routes Registered; Model Binding 404s | All 4 controller resource routes registered; AJAX routes registered before resource to avoid wildcard conflicts; {id} parameters use explicit route binding | — | — | ◌ |
| TC-CR17 | CR | P1 | View — Blade @can Directives on Tab/Action Buttons | Tab buttons in timetableMasters view wrapped in @can checks for each sub-feature's viewAny permission | — | — | ◌ |
| TC-CR18 | CR | P1 | View — isset()/null-safe Checks for Relationship Variables | Views check `$dayType?->description`, `$workingDay?->remarks`, `$cwd?->section?->name` etc. before display | — | — | ◌ |
| TC-CR19 | CR | P1 | Breadcrumb — Route Registered in config/breadcrumb.php | `timetable-foundation.menu.timetableMasters` key defined in breadcrumb config; renders correct hierarchy | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — $fillable Matches DDL Columns (All 4 Models)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SchoolDay.php` model | `$fillable` contains: code, name, short_name, day_of_week, ordinal, is_school_day, is_active (7 fields) |
| 2 | Cross-check with `tt_school_days` DDL | No non-PK/non-timestamp column is missing from $fillable; no extra columns |
| 3 | Open `DayType.php` model | `$fillable` contains: code, name, description, is_working_day, reduced_periods, ordinal, is_active, created_by |
| 4 | Cross-check with `tt_day_types` DDL | All non-PK/non-timestamp columns covered |
| 5 | Open `WorkingDay.php` model | `$fillable` contains: academic_session_id, date, day_type1_id, day_type2_id, day_type3_id, day_type4_id, is_school_day, remarks, is_active |
| 6 | Cross-check with `tt_working_days` DDL | All applicable columns covered |
| 7 | Open `ClassWorkingDay.php` model | `$fillable` contains: academic_session_id, date, class_id, section_id, working_day_id, is_exam_day, is_ptm_day, is_half_day, is_holiday, is_study_day, is_active |
| 8 | Cross-check with `tt_class_working_days_jnt` DDL | All applicable columns covered |

#### TC-CR02: Model — $casts for Booleans/Integers/Dates (All 4 Models)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SchoolDay.php` | `$casts` has: is_school_day→boolean, is_active→boolean, day_of_week→integer, ordinal→integer, dates→datetime |
| 2 | Open `DayType.php` | `$casts` has: is_working_day→boolean, reduced_periods→boolean, is_active→boolean, ordinal→integer, dates→datetime |
| 3 | Open `WorkingDay.php` | `$casts` has: is_school_day→boolean, is_active→boolean, day_type*_id→integer, academic_session_id→integer, date→date, dates→datetime |
| 4 | Open `ClassWorkingDay.php` | `$casts` has: all 5 flags→boolean, FK fields→integer, date→date, dates→datetime |
| 5 | Verify boolean cast read | When `is_active=1` in DB, model returns `true` (boolean, not 1) |
| 6 | Verify boolean cast write | Setting `is_active=true` on model stores `1` in DB |

#### TC-CR03: Model — SoftDeletes Trait Implemented on All 4 Models

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open each model file | All 4 models import and use `SoftDeletes` trait |
| 2 | Delete a SchoolDay record | `deleted_at` column populated; record hidden from normal queries |
| 3 | Query `onlyTrashed()` | Soft-deleted record appears in trashed results |
| 4 | Call `restore()` on trashed record | `deleted_at` set to null; record visible again |
| 5 | Call `forceDelete()` on trashed record | Record permanently removed from DB |

#### TC-CR05: Controller — Try-Catch Exception Handling on Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open WorkingDayController.php | `ajaxStore()` wraps transaction in try-catch; catches `\RuntimeException` → returns 422 JSON |
| 2 | Inspect `ajaxEdit()` | try-catch wraps DB::transaction; RuntimeException → 422 JSON |
| 3 | Inspect `ajaxDestroy()` | No explicit try-catch (findOrFail handles 404) |
| 4 | Open ClassWorkingDayController.php | `ajaxStore()` wraps DB::transaction in try-catch for RuntimeException |
| 5 | Open SchoolDayController.php | No try-catch on store/update/destroy (validation handles failures) |
| 6 | Open DayTypeController.php | No try-catch on store/update/destroy |
| 7 | Verify exception type | `ajaxStore` and `ajaxEdit` only catch `\RuntimeException`, not general `\Exception` |

#### TC-CR06: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open WorkingDayController.php | `ajaxStore()` uses `DB::transaction()` for date range creation |
| 2 | Inspect `ajaxEdit()` | `DB::transaction()` wraps source removal + target addition |
| 3 | Inspect `ajaxDestroy()` | Transaction wraps ClassWorkingDay forceDelete + WorkingDay forceDelete |
| 4 | Inspect `ajaxInitializeWorkingDays()` | `DB::transaction()` wraps all date creation across full session range |
| 5 | Inspect `ajaxClearWorkingDays()` | Uses DB::transaction implicitly via delete operations |
| 6 | Inspect ClassWorkingDay `ajaxStore()` | `DB::transaction()` wraps bulk class/section/date creation |
| 7 | Inspect ClassWorkingDay `ajaxInitialize()` | `DB::transaction()` wraps all class/section/working-day creation |

#### TC-CR07: Controller — Gate::authorize() on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SchoolDayController.php | Every public method (index/create/store/show/edit/update/destroy/restore/trashedDay/forceDelete/toggleStatus) starts with `Gate::authorize(...)` |
| 2 | Open DayTypeController.php | Every public method has `Gate::authorize()` |
| 3 | Open WorkingDayController.php | Every public method (including AJAX: ajaxStore/ajaxEdit/ajaxUpdateRemark/ajaxDestroy/ajaxInitializeWorkingDays/ajaxClearWorkingDays/eventFeed) has `Gate::authorize()` |
| 4 | Open ClassWorkingDayController.php | Every public method (including AJAX) has `Gate::authorize()` |
| 5 | Test without permission | 403 Forbidden returned for each corresponding route |

#### TC-CR08: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a School Day | `activityLog()` not called (no activity logging on create/store in SchoolDayController) |
| 2 | Delete a School Day | `activityLog()` called with event='Trashed' |
| 3 | Restore a School Day | `activityLog()` called with event='Restored' |
| 4 | Force Delete a School Day | `activityLog()` called with event='Deleted' |
| 5 | Toggle School Day Status | `activityLog()` called with event='Toggled' |
| 6 | Create a Day Type | `activityLog()` called with event='Created' |
| 7 | Update a Day Type | `activityLog()` called with event='Updated' |
| 8 | Create a Working Day | `activityLog()` called with event='Stored' |
| 9 | Create a Class Working Day | `activityLog()` called with event='Created' |

#### TC-CR09: Controller — is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SchoolDayController `destroy()` | Code sets `$schoolDay->is_active = false`, saves, then calls `delete()` |
| 2 | Open DayTypeController `destroy()` | Same pattern: `is_active=false` before `delete()` |
| 3 | Open ClassWorkingDayController `destroy()` | Same pattern: `is_active=false` before `delete()` |
| 4 | Open WorkingDayController `destroy()` | Does NOT set is_active=false before delete (uses `$workingDay->delete()` directly) |
| 5 | Verify WorkingDay behavior | WorkingDay destroy only calls `delete()` without deactivating first |

#### TC-CR10: Controller — toggleStatus() Flips is_active via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SchoolDayController `toggleStatus()` | Validates `is_active` as `required|boolean`; sets `$schoolDay->is_active = (bool) $request->input('is_active')`; saves; returns JSON `{success, is_active, message}` |
| 2 | Open DayTypeController `toggleStatus()` | Same pattern: validates boolean, flips, returns JSON |
| 3 | Open WorkingDayController `toggleStatus()` | Method not implemented in controller (route registered but no method) |
| 4 | Open ClassWorkingDayController `toggleStatus()` | Same pattern: validates boolean, flips, returns JSON |
| 5 | Call toggleStatus with is_active=false | JSON response: `success: true, is_active: false` |
| 6 | Call toggleStatus with is_active=true | JSON response: `success: true, is_active: true` |
| 7 | Trigger save failure | JSON response: `success: false`, HTTP 422 |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SchoolDayController `trashedDay()` | Uses `SchoolDay::onlyTrashed()->orderBy('day_of_week')->paginate(10)` |
| 2 | Inspect `restore()` | Uses `onlyTrashed()->findOrFail($id)`, calls `restore()`, sets `is_active=true`, logs activity, redirects to trashed route |
| 3 | Inspect `forceDelete()` | Uses `withTrashed()->findOrFail($id)`, calls `forceDelete()`, logs 'Deleted' activity |
| 4 | Open DayTypeController `trashedDayType()` | Same pattern: `onlyTrashed()->orderBy('ordinal')->paginate(10)` |
| 5 | Open ClassWorkingDayController `trashedClassWorkingDay()` | Same pattern: `onlyTrashed()->orderByDesc('date')->paginate(10)` |
| 6 | WorkingDay trash/restore/forceDelete | Routes exist but controller methods not implemented in WorkingDayController |

#### TC-CR12: Controller — JSON Success Response After AJAX Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call WorkingDay `ajaxStore()` with valid data | JSON `{status: true, message: "...", applied: N, skipped: [...]}` |
| 2 | Call WorkingDay `ajaxEdit()` to move day type | JSON `{status: true, message: "Day type moved."}` |
| 3 | Call WorkingDay `ajaxUpdateRemark()` | JSON `{status: true, message: "Remark saved.", remarks: "..."}` |
| 4 | Call WorkingDay `ajaxDestroy()` to remove slot | JSON `{status: true, message: "..."}` |
| 5 | Call WorkingDay `ajaxInitializeWorkingDays()` | JSON `{status: true, message: "...", data: {created: N}}` |
| 6 | Call WorkingDay `ajaxClearWorkingDays()` | JSON `{status: true, message: "...", data: {deleted: N}}` |
| 7 | Call ClassWorkingDay `ajaxStore()` | JSON `{status: true, message: "N class working day(s) saved.", count: N}` |
| 8 | Call ClassWorkingDay `ajaxDestroy()` | JSON `{status: true, message: "Removed."}` |
| 9 | Call ClassWorkingDay `ajaxInitialize()` | JSON `{status: true, message: "...", data: {created: N}}` |
| 10 | Call toggleStatus on any controller | JSON `{success: true, is_active: bool, message: "..."}` |

#### TC-CR13: Controller — Flash Success Response After CRUD Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day | `redirect()->route(...)->with('success', flash('created.school_day'))` |
| 2 | Update School Day | `->with('success', flash('updated.school_day'))` |
| 3 | Delete School Day | `->with('success', flash('trashed.school_day'))` |
| 4 | Restore School Day | `->with('success', flash('restored.school_day'))` |
| 5 | Force Delete School Day | `->with('success', flash('force_deleted.school_day'))` |
| 6 | Create Day Type | `->with('success', flash('created.day_type'))` |
| 7 | Update Day Type | `->with('success', flash('updated.day_type'))` |
| 8 | Create Working Day | `->with('success', flash('created.working_day'))` |
| 9 | Create Class Working Day | `->with('success', flash('created.class_working_day'))` |

#### TC-CR14: Validation — All Fields Covered; Unique Rules Ignore Current ID on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SchoolDayController `update()` | `'unique:tt_school_days,code,' . $schoolDay->id` — ignores own ID |
| 2 | Inspect day_of_week unique rule | `'unique:tt_school_days,day_of_week,' . $schoolDay->id` |
| 3 | Inspect ordinal unique rule | `'unique:tt_school_days,ordinal,' . $schoolDay->id` |
| 4 | Open DayTypeController `update()` | `Rule::unique('tt_day_types', 'code')->ignore($dayType->id)->whereNull('deleted_at')` |
| 5 | Inspect name/ordinal unique rules | Same pattern: `->ignore($dayType->id)->whereNull('deleted_at')` |
| 6 | Open WorkingDayController `store()` | No unique validation rule on `date` (enforced at DB constraint level) |
| 7 | Open ClassWorkingDayController `store()` | No unique validation rule on (class_id, working_day_id) (enforced at DB constraint level) |

#### TC-CR15: Policy — All Required Methods Defined; Permission Strings Match Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DayPolicy.php` | 7 methods: viewAny/view/create/update/delete/restore/forceDelete; each calls `$user->can('timetable-foundation.school-day.*')` |
| 2 | Open `DayTypePolicy.php` | 7 methods; permissions: `timetable-foundation.day-type.*` |
| 3 | Open `WorkingDayPolicy.php` | 7 methods; permissions: `timetable-foundation.working-day.*` |
| 4 | Open `ClassWorkingDayPolicy.php` | 7 methods; permissions: `timetable-foundation.class-working-day.*` |
| 5 | Verify route Gate strings match | `Gate::authorize('timetable-foundation.school-day.create')` in route matches policy permission string |
| 6 | Verify policy registration | Policies registered via `$gate->policy()` in service provider or `RouteServiceProvider` |

#### TC-CR16: Routes — Resource + Custom Routes Registered; Model Binding 404s

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | SchoolDay: resource + trash/view/restore/forceDelete/toggleStatus (lines 121-126) |
| 2 | Inspect DayType routes | Resource + trash/view/restore/forceDelete/toggleStatus (lines 137-142) |
| 3 | Inspect WorkingDay routes | 7 AJAX routes BEFORE resource; trash/restore/forceDelete/toggleStatus BEFORE resource (lines 146-158) |
| 4 | Inspect ClassWorkingDay routes | 5 AJAX routes BEFORE resource; trash/restore/forceDelete/toggleStatus BEFORE resource (lines 272-282) |
| 5 | Call GET /school-day/9999 (non-existent) | Returns 404 (ModelNotFoundException caught by Laravel) |
| 6 | Verify AJAX route order | Ajax routes registered before resource to prevent wildcard `{schoolDay}` catching "ajax" |

#### TC-CR17: View — Blade @can Directives on Tab/Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open timetableMasters.blade.php | Tab buttons wrapped in `@can('timetable-foundation.school-day.viewAny')`, `@can('timetable-foundation.day-type.viewAny')`, etc. |
| 2 | Inspect school day create button | `@can('timetable-foundation.school-day.create')` wraps Add button |
| 3 | Inspect school day edit/delete buttons | `@can('timetable-foundation.school-day.update')` and `@can('timetable-foundation.school-day.delete')` on row actions |
| 4 | Inspect day type action buttons | Similar @can directives for each permission |
| 5 | Inspect toggleStatus buttons | `@can('timetable-foundation.school-day.update')` or similar on status toggle |
| 6 | Log in as user without create permission | Add New button hidden; read-only mode confirmed |

#### TC-CR18: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open working-day/index.blade.php | Relationship access like `$workingDay->dayType->name` uses `?->` or `isset()` |
| 2 | Open class-working-day/index.blade.php | `$cwd->section?->name`, `$cwd->periodSet?->name` use null-safe operator |
| 3 | Open school-day/show.blade.php | Direct string fields only (no relationship access) |
| 4 | Create WorkingDay with null day_type2_id | View renders without undefined index/property error |
| 5 | Create ClassWorkingDay with null section_id | View renders gracefully with dash or empty string for section |

#### TC-CR19: Breadcrumb — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File exists in config directory |
| 2 | Search for 'timetable-foundation.menu.timetableMasters' | Key defined with correct parent hierarchy |
| 3 | Load the timetable masters page | Breadcrumb trail shows: Home > Timetable Foundation > Timetable Masters |
| 4 | Click breadcrumb parent link | Navigates correctly to parent page without errors |

---

### 7.1 Positive TC Steps

#### TC-P01: School Day Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Timetable Foundation" from left sidebar | Menu options appear |
| 3 | Click "Timetable Masters" and select "School Days" tab | Page loads with `tab=school-days` parameter |
| 4 | Check the school days data table | Grid showing list of existing school days with columns: Code, Name, Short Name, Day of Week, Ordinal, Is School Day, Status |
| 5 | Check the "Add School Day" button | Visible (if create permission granted) |
| 6 | Check status toggle buttons | Toggle switches visible for each row |

#### TC-P02: Create School Day With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add School Day" button | Create form loads |
| 2 | Enter code = "MON", name = "Monday", short_name = "Mon" | Fields populated |
| 3 | Select day_of_week = 1, ordinal = 1 | Values selected |
| 4 | Leave is_school_day checkbox checked (default true) | is_school_day = true |
| 5 | Click "Save" | Form submitted |
| 6 | Verify redirect | Redirected to school-days tab with success message: "School day created successfully" |
| 7 | Verify new record in grid | "MON" / "Monday" / "Mon" row visible in table |

#### TC-P03: Create School Day With is_school_day = false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add School Day" | Create form loads |
| 2 | Enter code = "SUN", name = "Sunday", short_name = "Sun", day_of_week = 7, ordinal = 7 | Fields populated |
| 3 | Uncheck "is_school_day" checkbox | is_school_day = false |
| 4 | Click "Save" | Record saved with is_school_day = 0 |
| 5 | Verify in DB | `tt_school_days` row has `is_school_day = 0` |

#### TC-P04: Create School Day With is_active = false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add School Day" | Create form loads |
| 2 | Enter code = "SPD", name = "Special Day", short_name = "Spd", day_of_week = 8, ordinal = 8 | Fields populated |
| 3 | Uncheck "is_active" checkbox | is_active = false |
| 4 | Click "Save" | Record saved; grid shows row with inactive badge/status |

#### TC-P05: Edit School Day Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click edit icon on existing School Day row | Edit form loads with pre-filled data |
| 2 | Verify code field | Shows existing code value |
| 3 | Verify name field | Shows existing name value |
| 4 | Verify short_name field | Shows existing short_name |
| 5 | Verify day_of_week dropdown | Correct day selected |
| 6 | Verify ordinal field | Correct ordinal value |

#### TC-P06: Update School Day Code And Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing School Day with code "MON" | Edit form loaded |
| 2 | Change code to "MOND", name to "Monday Updated" | Values changed |
| 3 | Click "Update" | Record updated; redirect with success message |
| 4 | Verify grid shows updated values | "MOND" and "Monday Updated" displayed |

#### TC-P07: Toggle School Day Active Status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate active School Day with status toggle ON | Toggle shows active state |
| 2 | Click the toggle to deactivate | AJAX POST to `/school-day/{id}/toggle-status` with `is_active=false` |
| 3 | Verify JSON response | `{success: true, is_active: false, message: "..."}` |
| 4 | Verify toggle now shows OFF | UI reflects inactive state |
| 5 | Click toggle again to activate | AJAX POST with `is_active=true` |
| 6 | Verify JSON response | `{success: true, is_active: true, message: "..."}` |

#### TC-P08: View School Day Show Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click view icon on School Day row | Show page loads at `/school-day/{id}` |
| 2 | Verify all fields displayed | Code, name, short_name, day_of_week, ordinal, is_school_day, is_active shown |
| 3 | Verify timestamps present | Created at and Updated at visible |

#### TC-P09: Soft Delete School Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete icon on active School Day | Confirmation dialog appears |
| 2 | Confirm deletion | Record soft-deleted |
| 3 | Verify redirect | Redirected to school-days tab with flash "School day was deactivated and moved to trash" |
| 4 | Verify record hidden from active list | Record no longer visible in main grid |

#### TC-P10: Restore School Day From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash view (`/school-day/trash/view`) | Trash list shows soft-deleted School Days (10/page) |
| 2 | Locate previously deleted School Day | Row visible with deleted_at timestamp |
| 3 | Click "Restore" | GET to `/school-day/{id}/restore` |
| 4 | Verify redirect | Redirected to trash view with success message |
| 5 | Go back to main School Days tab | Restored record visible in grid with is_active = true |

#### TC-P11: Force Delete School Day Permanently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash view | Trash list loaded |
| 2 | Locate a soft-deleted School Day | Row visible |
| 3 | Click "Force Delete" | DELETE to `/school-day/{id}/force-delete` |
| 4 | Confirm permanent deletion | Record permanently removed |
| 5 | Verify record gone | Record no longer in trash or active list; DB query returns null |

#### TC-P12: Trash School Day List Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 12 School Days | 12 records in trash |
| 2 | Navigate to Trash view | Only 10 records shown (page 1) |
| 3 | Check pagination | Pagination links visible; page 2 has remaining 2 records |
| 4 | Click page 2 | Remaining 2 records displayed |

#### TC-P13: Day Type Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Day Types" tab on Timetable Masters page | Tab activated; data table with existing day types |
| 2 | Check grid columns | Code, Name, Description, Is Working Day, Reduced Periods, Ordinal, Status visible |
| 3 | Check "Add Day Type" button | Visible |

#### TC-P14: Create Day Type With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Day Type" | Create form loads |
| 2 | Enter code = "study" (lowercase), name = "Study Day", description = "Regular study day", ordinal = 1 | Fields populated |
| 3 | Check is_working_day = true, reduced_periods = false | Checkboxes set correctly |
| 4 | Click "Save" | Record created; code auto-uppercased to "STUDY" |
| 5 | Verify success message | Flash "Day type created successfully" |
| 6 | Verify activity log | Activity record with event='Created' exists |

#### TC-P15: Create Day Type With is_working_day = false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create new Day Type with code = "hol", name = "Holiday", ordinal = 5 | Form filled |
| 2 | Uncheck is_working_day, check reduced_periods | is_working_day = false |
| 3 | Click "Save" | Record saved with is_working_day = 0 |
| 4 | Verify in DB | `tt_day_types` row has `is_working_day = 0` |

#### TC-P16: Create Day Type With reduced_periods = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create new Day Type with code = "spd", name = "Sports Day", ordinal = 6 | Form filled |
| 2 | Check reduced_periods = true | Checkbox set |
| 3 | Click "Save" | Record saved with reduced_periods = 1 |

#### TC-P17: Update Day Type Name And Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing Day Type | Edit form loads with pre-filled data |
| 2 | Change name to "Updated Study Day", ordinal to 2 | Values changed |
| 3 | Click "Update" | Record updated; activity 'Updated' logged |
| 4 | Verify grid | Updated values displayed |

#### TC-P18: Toggle Day Type Active Status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate active Day Type with toggle ON | Toggle shows ON |
| 2 | Click toggle | AJAX POST to `/day-type/{dayType}/toggle-status` |
| 3 | Verify JSON response | `{success: true, is_active: false}` |
| 4 | Toggle back to active | `{success: true, is_active: true}` |

#### TC-P19: Soft Delete Day Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete an active Day Type | Confirmation dialog |
| 2 | Confirm | Record deactivated then soft-deleted |
| 3 | Verify flash | "Day type was deactivated and moved to trash" |
| 4 | Verify activity log | 'Trashed' activity logged |

#### TC-P20: Restore Day Type From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Day Type Trash | List of soft-deleted day types (10/page) |
| 2 | Click "Restore" on deleted record | Record restored; is_active set to true |
| 3 | Verify in active list | Record visible with active status |

#### TC-P21: Force Delete Day Type Permanently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Day Type Trash | List of deleted day types |
| 2 | Click "Force Delete" on a soft-deleted Day Type | Record permanently removed |
| 3 | Verify activity log | 'Deleted' activity logged |

#### TC-P22: Working Day Tab Calendar Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Working Days" tab | Calendar view loaded with FullCalendar |
| 2 | Verify calendar renders | Month/week/day views available |
| 3 | Check AJAX eventFeed called | Network tab shows GET `/working-day/ajax/events?start=...&end=...` |
| 4 | Verify events displayed | Day type colored events visible on calendar dates |

#### TC-P23: Create Working Day via Standard Form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Working Day" | Create form loads |
| 2 | Select date (e.g., 2026-07-20) within academic session | Date selected |
| 3 | Select day_type1_id from dropdown | Day type selected |
| 4 | Set is_school_day = true | Checkbox set |
| 5 | Click "Save" | Created with auto-set academic_session_id; redirect with success |

#### TC-P24: AJAX Store Single Date Working Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare POST to `/working-day/ajax/store` with `start=2026-07-20`, `day_type_id=1` | AJAX request |
| 2 | Verify response | `{status: true, message: "Saved 1 day(s).", applied: 1, skipped: []}` |
| 3 | Verify DB | WorkingDay row created for 2026-07-20 with day_type1_id = 1 |

#### TC-P25: AJAX Store Date Range Working Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/working-day/ajax/store` with `start=2026-07-20`, `end=2026-07-25`, `day_type_id=1` | Range request |
| 2 | Verify response | `{status: true, applied: 5, skipped: []}` (5 days: 20th-24th) |
| 3 | Verify DB | 5 WorkingDay rows created (dates 20th-24th) |

#### TC-P26: AJAX Stack Multiple Day Types on Same Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Working Day on 2026-07-20 with day_type_id=1 (Working Day) | Slot 1 filled |
| 2 | POST ajaxStore with same date, day_type_id=2 (Exam) | Day type added to slot 2 |
| 3 | POST ajaxStore with same date, day_type_id=3 (PTM) | Day type added to slot 3 |
| 4 | POST ajaxStore with same date, day_type_id=4 (Sports Day) | Day type added to slot 4 |
| 5 | Verify all 4 slots populated | `day_type1_id=1, day_type2_id=2, day_type3_id=3, day_type4_id=4` |
| 6 | Verify is_school_day computed | `is_school_day = 1` (contains working day type) |

#### TC-P27: AJAX Edit Move Day Type to Another Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a day type exists on 2026-07-20, slot 1 | WorkingDay exists with id=WD1 |
| 2 | POST `/working-day/ajax/edit` with `id=wd-WD1-1`, `date=2026-07-21` | Move request |
| 3 | Verify response | `{status: true, message: "Day type moved."}` |
| 4 | Verify source date slot cleared | 2026-07-20 day_type1_id is now null |
| 5 | Verify target date populated | 2026-07-21 has the moved day type |

#### TC-P28: AJAX Update Remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/working-day/ajax/remark/wd-1-1` with `remarks=Test remark` | AJAX update |
| 2 | Verify response | `{status: true, message: "Remark saved.", remarks: "Test remark"}` |
| 3 | Verify DB | `tt_working_days` row has `remarks = "Test remark"` |

#### TC-P29: AJAX Initialize Working Days for Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure tt_configs has `week_start_day=MONDAY`, `default_school_closed_days_per_week=1` | Config in place |
| 2 | POST `/working-day/ajax/initialize-calander` | Initialize request |
| 3 | Verify response includes created count | JSON with `status: true, data.created: N` |
| 4 | Verify each date has a WorkingDay | All dates in session covered |
| 5 | Verify Sundays (closed days) have Holiday type | Day type with is_working_day=0 assigned |
| 6 | Verify weekdays have Working Day type | Day type with is_working_day=1 assigned |
| 7 | Verify is_school_day set correctly | Closed days: is_school_day=0; Open days: is_school_day=1 |

#### TC-P30: AJAX Remove Single Day Type Slot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure date has 3 day type slots filled | Slots 1, 2, 3 populated |
| 2 | DELETE `/working-day/ajax/delete/wd-1-2` | Remove slot 2 |
| 3 | Verify response | `{status: true, message: "Day type removed."}` |
| 4 | Verify compaction | Old slot 3 value is now in slot 2; slot 3 is empty |

#### TC-P31: AJAX Clear All Working Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure WorkingDays exist for current session | Days initialized |
| 2 | DELETE `/working-day/ajax/clear` | Clear request |
| 3 | Verify response | `{status: true, data: {deleted: N}}` |
| 4 | Verify DB empty | No WorkingDays in session date range |

#### TC-P32: Class Working Day Tab Calendar Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Class Working Days" tab | Calendar with class/section filter renders |
| 2 | Verify eventFeed called | GET `/class-working-day/ajax/events` with start/end |
| 3 | Verify workingDayFeed called | GET `/class-working-day/ajax/working-day-feed` with start/end |
| 4 | Verify background events | Working day types shown as background colors on calendar |

#### TC-P33: Create Class Working Day via Standard Form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Class Working Day" | Create form loads with dropdowns |
| 2 | Select academic session, date, class, section, working_day_id | Fields filled |
| 3 | Check is_study_day = true | Study day flag set |
| 4 | Click "Save" | Record created; activity 'Created' logged |

#### TC-P34: AJAX Bulk Store Class Working Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/class-working-day/ajax/store` with `start=2026-07-20`, `end=2026-07-22`, `class_ids=[1,2]`, `day_type=study` | Bulk store |
| 2 | Verify response | `{status: true, count: 6, message: "6 class working day(s) saved."}` |
| 3 | Verify DB | 6 records created (2 classes × 3 dates) |
| 4 | Verify flags set correctly | is_study_day=true, is_holiday=false |

#### TC-P35: AJAX Bulk Store With Notification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/class-working-day/ajax/store` with notification data | Include `send_notification=true`, `notification_channels=["email","sms","in_app"]` |
| 2 | Verify response | `{status: true, count: N}` |
| 3 | Verify SpecialDayAssigned event dispatched | Event fired with notification channels |

#### TC-P36: AJAX Initialize Class Working Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Working Days initialized for session | WorkingDays exist |
| 2 | POST `/class-working-day/ajax/initialize` with `class_ids=[1]`, `clear_existing=true` | Initialize request |
| 3 | Verify response | `{status: true, data: {created: N}}` |
| 4 | Verify DB | ClassWorkingDay records created for each WorkingDay |
| 5 | Verify flag mapping | WorkingDay `is_school_day=1` → CWD `is_study_day=1`; `is_school_day=0` → `is_holiday=1` |

#### TC-P37: AJAX Delete Single Class Working Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a ClassWorkingDay record exists (id=5) | Record present |
| 2 | DELETE `/class-working-day/ajax/delete/cwd-5` | Delete via AJAX |
| 3 | Verify response | `{status: true, message: "Removed."}` |
| 4 | Verify record gone | forceDelete removed from DB |

#### TC-P38: Toggle Class Working Day Active Status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/class-working-day/{cwd}/toggle-status` with `is_active=false` | Toggle deactivate |
| 2 | Verify response | `{success: true, is_active: false}` |
| 3 | Toggle back to active | `{success: true, is_active: true}` |

#### TC-P39: Working Day Event Feed Returns Colored Events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/working-day/ajax/events?start=2026-07-01&end=2026-07-31` | Event feed |
| 2 | Verify each event has `backgroundColor` | Color hex string present per event |
| 3 | Verify WD (Working Day) returns blue (#3b82f6) | `DAY_TYPE_COLORS['WD']` applied |
| 4 | Verify HD (Half Day) returns amber (#f59e0b) | `DAY_TYPE_COLORS['HD']` applied |
| 5 | Verify H (Holiday) returns gray (#6b7280) | `DAY_TYPE_COLORS['H']` applied |

#### TC-P40: Full Lifecycle: Create School Day → Edit → Toggle → Delete → Trash → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day with code="FUL", name="Full Lifecycle", short_name="Ful", day_of_week=9, ordinal=9 | Created successfully |
| 2 | Edit School Day, change name to "Full LC Updated" | Updated successfully |
| 3 | Toggle status to inactive | is_active=false |
| 4 | Toggle status back to active | is_active=true |
| 5 | Soft delete School Day | Deactivated; moved to trash |
| 6 | View trash, find deleted record | Visible in trash list |
| 7 | Restore School Day | Restored; active again |
| 8 | Force delete School Day | Permanently removed |

#### TC-P41: Full Lifecycle: Create Day Type → Edit → Toggle → Delete → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type with code="test", name="Test Type", ordinal=50 | Code auto-uppercased to "TEST" |
| 2 | Edit, change name to "Test Type Updated" | Updated successfully |
| 3 | Toggle status to inactive | is_active=false |
| 4 | Toggle back to active | is_active=true |
| 5 | Soft delete | Moved to trash |
| 6 | Restore from trash | Reactivated |
| 7 | Force delete | Permanently removed |

#### TC-P42: Full Calendar Lifecycle: Initialize Working Days → Add Day Types → Move → Remove

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize working days for session via ajaxInitializeWorkingDays | Days created |
| 2 | Add a second day type to a date (e.g., Exam to a Working Day) | Slot 2 filled |
| 3 | Move a day type to another date | Moved successfully |
| 4 | Update remark on a date | Remark saved |
| 5 | Remove a day type slot | Slot compacted |
| 6 | Remove last slot from a date | WorkingDay row force-deleted |

---

### 7.2 Negative TC Steps

#### TC-N01: Required — Missing School Day `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Add School Day | Create form loads |
| 2 | Leave code empty, fill all other required fields | Code field blank |
| 3 | Click Save | Validation error: "The code field is required." |

#### TC-N02: Required — Missing School Day `name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day with code="TST", leave name empty | Name blank |
| 2 | Click Save | "The name field is required." |

#### TC-N03: Required — Missing School Day `short_name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day with code="TST", name="Test", leave short_name empty | Short name blank |
| 2 | Click Save | "The short name field is required." |

#### TC-N04: Required — Missing School Day `day_of_week`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day, leave day_of_week unselected | Day of week not set |
| 2 | Click Save | "The day of week field is required." |

#### TC-N05: Required — Missing School Day `ordinal`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day, leave ordinal empty | Ordinal blank |
| 2 | Click Save | "The ordinal field is required." |

#### TC-N06: Duplicate — School Day `code` Already Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day with code="MON" | Created successfully |
| 2 | Create another School Day with same code="MON" | Validation error on unique:tt_school_days,code |

#### TC-N07: Duplicate — School Day `day_of_week` Already Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day with day_of_week=1 | Created |
| 2 | Create another with day_of_week=1 | Validation error on unique:tt_school_days,day_of_week |

#### TC-N08: Duplicate — School Day `ordinal` Already Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day with ordinal=1 | Created |
| 2 | Create another with ordinal=1 | Validation error on unique:tt_school_days,ordinal |

#### TC-N09: Max Length — School Day `code` > 10 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code = "VERYLONGCOD" (11 characters) | |
| 2 | Click Save | Validation error on code.max:10 |

#### TC-N10: Max Length — School Day `name` > 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name = "ThisIsAVeryLongNameExceeds20" (27 chars) | |
| 2 | Click Save | Validation error on name.max:20 |

#### TC-N11: Max Length — School Day `short_name` > 5 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter short_name = "TooLong" (7 characters) | |
| 2 | Click Save | Validation error on short_name.max:5 |

#### TC-N12: Invalid Range — `day_of_week` < 1 or > 7

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter day_of_week = 0 | |
| 2 | Click Save | "The day of week must be between 1 and 7." |
| 3 | Try day_of_week = 8 | Same validation error |

#### TC-N13: Invalid Range — `ordinal` < 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter ordinal = 0 | |
| 2 | Click Save | "The ordinal must be at least 1." |

#### TC-N14: Required — Missing Day Type `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Day Type, leave code empty | Code blank |
| 2 | Click Save | "The code field is required." |

#### TC-N15: Required — Missing Day Type `name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Day Type with code="TST", leave name empty | Name blank |
| 2 | Click Save | "The name field is required." |

#### TC-N16: Required — Missing Day Type `ordinal`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Day Type with code="TST", name="Test", leave ordinal empty | Ordinal blank |
| 2 | Click Save | "The ordinal field is required." |

#### TC-N17: Duplicate — Day Type `code` Already Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type with code="STUDY" | Created |
| 2 | Create another with code="STUDY" | Validation error on code unique |

#### TC-N18: Duplicate — Day Type `name` Already Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type with name="Study Day" | Created |
| 2 | Create another with name="Study Day" | Validation error on name unique |

#### TC-N19: Duplicate — Day Type `ordinal` Already Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type with ordinal=1 | Created |
| 2 | Create another with ordinal=1 | Validation error on ordinal unique |

#### TC-N20: Max Length — Day Type `code` > 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code = "ABCDEFGHIJKLMNOPQRSTU" (21 chars) | |
| 2 | Click Save | Validation error on code.max:20 |

#### TC-N21: Max Length — Day Type `name` > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter 101-character name | |
| 2 | Click Save | Validation error on name.max:100 |

#### TC-N22: Max Length — Day Type `description` > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter 256-character description | |
| 2 | Click Save | Validation error on description.max:255 |

#### TC-N23: Invalid Ordinal — Day Type `ordinal` < 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter ordinal = 0 | |
| 2 | Click Save | "The ordinal must be at least 1." |

#### TC-N24: Required — Missing Working Day `date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Working Day, leave date blank | |
| 2 | Click Save | "The date field is required." |

#### TC-N25: Required — Missing Working Day `day_type1_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Working Day, leave day_type1_id unselected | |
| 2 | Click Save | "The day type1 id field is required." |

#### TC-N26: Invalid FK — Working Day `day_type1_id` Non-Existent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Working Day with day_type1_id = 99999 | Non-existent ID |
| 2 | Click Save | "The selected day type1 id is invalid." |

#### TC-N27: Duplicate — Working Day `date` Already Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Working Day for 2026-07-20 | Created |
| 2 | Create another Working Day for same date | DB unique constraint violation on `uq_workday_date` |

#### TC-N28: Working Day AJAX Max 4 Slots Exceeded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill 4 day type slots on one date via ajaxStore | 4 types added |
| 2 | Try to add a 5th day type | JSON response with 422: "This date already has 4 day types (max)." |

#### TC-N29: Working Day AJAX Duplicate Day Type On Same Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add day_type_id=1 to a date via ajaxStore | Added successfully |
| 2 | Try to add same day_type_id=1 to same date | JSON 422: "already assigned to this date." |

#### TC-N30: Working Day AJAX — Add Working Type To Holiday Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add a non-working (holiday) day type to a date | Holiday added to slot 1 |
| 2 | Try to add a working day type to the same date | JSON 422: "Cannot add a working day type — this date is already a holiday." |

#### TC-N31: Working Day AJAX — Add Holiday To Working Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add a working day type to a date | Working day in slot 1 |
| 2 | Try to add a holiday type to same date | JSON 422: "Cannot add a holiday — this date already has working day type(s)." |

#### TC-N32: Working Day AJAX — Add Second Holiday Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add a non-working (holiday) type to a date | Holiday added to slot 1 |
| 2 | Try to add another non-working type | JSON 422: "Only one holiday type allowed per date." |

#### TC-N33: Working Day AJAX Delete — Not Found (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/working-day/ajax/delete/wd-99999-1` (non-existent) | JSON `{status: false, message: "Working day not found or already deleted."}`, 404 |

#### TC-N34: Working Day AJAX Delete — Empty Slot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/working-day/ajax/delete/wd-1-3` where slot 3 is already empty | JSON `{status: false, message: "That slot is already empty."}`, 422 |

#### TC-N35: Working Day AJAX Initialize — No Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set no academic session as `is_current=true` | No current session |
| 2 | POST `/working-day/ajax/initialize-calander` | JSON 422: "No current academic session found or session has no start/end dates." |

#### TC-N36: Working Day AJAX Initialize — No Active Working Day Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Deactivate all working day types (is_working_day=true) | No active working day type |
| 2 | POST `/working-day/ajax/initialize-calander` | JSON 422: "No active Working Day type found." |

#### TC-N37: Working Day AJAX Initialize — No Active Holiday Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Deactivate all holiday types (is_working_day=false) | No active holiday type |
| 2 | POST `/working-day/ajax/initialize-calander` | JSON 422: "No active Holiday day type found." |

#### TC-N38: Required — Missing Class Working Day `class_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Class Working Day, leave class_id unselected | |
| 2 | Click Save | "The class id field is required." |

#### TC-N39: Required — Missing Class Working Day `academic_session_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Class Working Day, leave academic_session_id unselected | |
| 2 | Click Save | "The academic session id field is required." |

#### TC-N40: Invalid FK — Class Working Day `class_id` Non-Existent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Class Working Day with class_id = 99999 | |
| 2 | Click Save | "The selected class id is invalid." |

#### TC-N41: Duplicate — Class Working Day (class_id, working_day_id) Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ClassWorkingDay with class_id=1, working_day_id=1 | Created |
| 2 | Create another with same class_id=1, working_day_id=1 | DB unique constraint violation on `uq_class_working_day` |

#### TC-N42: Class Working Day AJAX Store — Date Not Configured

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/class-working-day/ajax/store` with start date that has no WorkingDay | |
| 2 | Verify response | JSON 422: "date has not been configured in Working Days yet." |

#### TC-N43: Class Working Day AJAX Initialize — No Working Days Found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear all working days (ajaxClearWorkingDays) | No working days exist |
| 2 | POST `/class-working-day/ajax/initialize` with class_ids=[1] | JSON 422: "No working days found. Please auto-fill Working Days first." |

#### TC-N44: Permission 403 — No School Day Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any `timetable-foundation.school-day.*` permissions | User lacks gates |
| 2 | Access `/school-day` | 403 Forbidden |
| 3 | Try POST to `/school-day` | 403 Forbidden |
| 4 | Try any school day route | All return 403 |

#### TC-N45: Permission 403 — No Day Type Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `timetable-foundation.day-type.*` permissions | |
| 2 | Access `/day-type` | 403 Forbidden |

#### TC-N46: Permission 403 — No Working Day Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `timetable-foundation.working-day.*` permissions | |
| 2 | Access `/working-day` | 403 Forbidden |
| 3 | Try AJAX endpoints | 403 Forbidden |

#### TC-N47: Permission 403 — No Class Working Day Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `timetable-foundation.class-working-day.*` permissions | |
| 2 | Access `/class-working-day` | 403 Forbidden |
| 3 | Try AJAX endpoints | 403 Forbidden |

#### TC-N48: Guest Access Redirect For All Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest user) | No auth session |
| 2 | Access any school day/day type/working day/class working day route | Redirected to `/login` |

#### TC-N49: Edit/Show/Delete School Day With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/school-day/99999/edit` | 404 Not Found |
| 2 | GET `/school-day/99999` | 404 Not Found |
| 3 | DELETE `/school-day/99999` | 404 Not Found |

#### TC-N50: Edit/Show/Delete Day Type With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/day-type/99999/edit` | 404 Not Found |
| 2 | GET `/day-type/99999` | 404 Not Found |
| 3 | DELETE `/day-type/99999` | 404 Not Found |

---

### 7.3 Dependency TC Steps

#### TC-D01: School Day — Soft Delete Sets is_active=false Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create School Day with is_active=true | Active record |
| 2 | Call destroy() | Controller sets is_active=false, saves, then delete() |
| 3 | Check DB directly | `is_active = 0`, `deleted_at` populated |
| 4 | Restore the record | is_active set back to true |
| 5 | Check DB | `is_active = 1`, `deleted_at = null` |

#### TC-D02: Day Type — is_working_day Flag Determines AJAX Stacking Behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type "WD" with is_working_day=true | Working type |
| 2 | Create Day Type "HD" with is_working_day=false | Holiday type |
| 3 | Add "WD" to a date (slot 1) | Success |
| 4 | Try to add "HD" to same date | Rejected: "Cannot add a holiday..." |
| 5 | Add "WD" to a new date | Success |
| 6 | Add "HD" to that new date | Rejected |

#### TC-D03: Day Type — Code Auto-Uppercased on Create and Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type with code="study" (lowercase) | Code stored as "STUDY" |
| 2 | Verify in DB | `code = 'STUDY'` |
| 3 | Edit the Day Type, change code to "exam" (lowercase) | Code stored as "EXAM" |
| 4 | Verify update | `code = 'EXAM'` |

#### TC-D04: Day Type — Unique Scope Ignores Soft-Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type with code="TEMP" | Created |
| 2 | Soft-delete it | moved to trash |
| 3 | Create new Day Type with same code="TEMP" | Allowed (unique ignores soft-deleted) |
| 4 | Create new Day Type with same name | Allowed |
| 5 | Create new Day Type with same ordinal | Allowed |

#### TC-D05: Working Day — academic_session_id Auto-From Current Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure one AcademicSession has `is_current=true` | Current session exists |
| 2 | Create Working Day via standard form (no academic_session_id input) | Form auto-sets academic_session_id |
| 3 | Check DB | `academic_session_id` = current session's id |

#### TC-D06: Working Day — Slot Compaction After Removal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill slots 1=WD, 2=EXAM, 3=PTM, 4=SPORTS | 4 slots filled |
| 2 | Remove slot 2 via ajaxDestroy | Slot compacted |
| 3 | Check DB | day_type1_id=WD, day_type2_id=PTM, day_type3_id=SPORTS, day_type4_id=null |
| 4 | Remove slot 1 | day_type1_id=PTM, day_type2_id=SPORTS, rest null |

#### TC-D07: Working Day — is_school_day Recomputes After Add/Remove

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize date with working day type (is_working_day=true) | is_school_day = true |
| 2 | Remove the working day type | If remaining types are all non-working, is_school_day = false |
| 3 | Add a working day type back | is_school_day = true again |

#### TC-D08: Working Day — ajaxDestroy Last Slot Triggers Row Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure date has only 1 day type slot filled | Single slot |
| 2 | DELETE `/working-day/ajax/delete/wd-1-1` | Last slot removal |
| 3 | Verify WorkingDay row force-deleted | Row permanently removed from DB |
| 4 | Verify linked ClassWorkingDay also force-deleted | Related CWD records also removed |

#### TC-D09: Working Day — ajaxDestroy Requires Confirm When Linked Records Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create WorkingDay with linked ClassWorkingDay records | Linked records exist |
| 2 | DELETE `/working-day/ajax/delete/wd-1-1` without `force=true` | Response with `requires_confirm=true`, `linked_count=N` |
| 3 | DELETE with `force=true` | Records force-deleted |

#### TC-D10: Working Day — ajaxInitialize Reads Config For Closed Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `week_start_day=MONDAY`, `default_school_closed_days_per_week=2` in tt_configs | Config set |
| 2 | Run ajaxInitializeWorkingDays | Days initialized |
| 3 | Verify Saturday and Sunday have Holiday type | Both weekend days = holiday |
| 4 | Verify weekdays have Working Day type | Mon-Fri = Working Day |
| 5 | Change config to `default_school_closed_days_per_week=1` and re-initialize | Only Sunday = Holiday, Saturday = Working Day |

#### TC-D11: Day Type — RESTRICT FK Prevents Deletion When Referenced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type, use it in a WorkingDay's day_type1_id | Day Type referenced |
| 2 | Try to forceDelete the Day Type from trash | FK constraint violation; deletion blocked |
| 3 | Verify Day Type still exists | Not deleted |

#### TC-D12: Class Working Day — (class_id, working_day_id) Unique Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ClassWorkingDay with class_id=1, working_day_id=1 | Created |
| 2 | Try direct DB insert with same combination | Integrity constraint violation on `uq_class_working_day` |

#### TC-D13: Class Working Day — isTeachingAllowed Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create CWD with is_active=1, is_study_day=1, is_holiday=0 | `isTeachingAllowed()` returns true |
| 2 | Set is_holiday=1 | `isTeachingAllowed()` returns false |
| 3 | Set is_study_day=0 | `isTeachingAllowed()` returns false |
| 4 | Set is_active=0 | `isTeachingAllowed()` returns false |

#### TC-D14: Class Working Day — isSpecialDay Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create CWD with all flags false | `isSpecialDay()` returns false |
| 2 | Set is_exam_day=true | Returns true |
| 3 | Set is_ptm_day=true | Returns true |
| 4 | Set is_half_day=true | Returns true |

#### TC-D15: Class Working Day — ajaxInitialize Maps is_school_day to is_study_day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure WorkingDay has is_school_day=1 | School day |
| 2 | Run ajaxInitialize for class | CWD created with is_study_day=1, is_holiday=0 |
| 3 | Ensure WorkingDay has is_school_day=0 | Non-school day |
| 4 | Run ajaxInitialize for class | CWD created with is_holiday=1, is_study_day=0 |

#### TC-D16: Class Working Day — ajaxStore Resolves day_type String to Boolean Flags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST ajaxStore with day_type="exam" | CWD created with is_exam_day=1, others 0 |
| 2 | POST with day_type="ptm" | is_ptm_day=1 |
| 3 | POST with day_type="half_day" | is_half_day=1, is_study_day=1 |
| 4 | POST with day_type="holiday" | is_holiday=1 |
| 5 | POST with day_type="study" (or default) | is_study_day=1 |

#### TC-D17: Class Working Day — ajaxStore Restores + Updates Existing Soft-Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create CWD, then soft-delete it | Record in trash |
| 2 | POST ajaxStore with same class_id and working_day_id | Existing record restored and updated |
| 3 | Verify deleted_at is null | Record active again |
| 4 | Verify only 1 record exists for this combination | No duplicate |

#### TC-D18: Working Day — Working Day Model $casts Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create WorkingDay with is_school_day=1, is_active=1 | DB stores 1,1 |
| 2 | Read from model | `$wd->is_school_day` returns `true` (boolean) |
| 3 | Check day_type1_id cast | Returns integer, not string |
| 4 | Check date cast | Returns Carbon instance (datetime, not string) |

#### TC-D19: Day Type — DayType Model $casts Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DayType with is_working_day=1, reduced_periods=0, is_active=1 | DB values set |
| 2 | Read from model | All boolean casts return true/false (not 1/0) |
| 3 | Read ordinal | Returns integer |

#### TC-D20: School Day — SchoolDay Model $casts Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SchoolDay with is_school_day=1, is_active=1, day_of_week=1, ordinal=1 | DB stores values |
| 2 | Read from model | is_school_day → boolean true; day_of_week → integer 1 |
| 3 | Set is_school_day = false | DB stores 0 |

#### TC-D21: Class Working Day — ClassWorkingDay Model $casts and Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ClassWorkingDay model | 5 boolean casts, 4 integer casts for FK fields |
| 2 | Verify belongsTo relationships | class(), section(), workingDay(), periodSet(), academicSession() defined |
| 3 | Eager load relationships | `ClassWorkingDay::with(['class', 'section', 'workingDay'])->get()` works in 1+N queries |
| 4 | Verify section nullable relationship | CWD with null section_id returns null for `->section` |

#### TC-D22: Working Day — WorkingDay Relationships (4 belongsTo DayType)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create WorkingDay with day_type1_id=1, day_type2_id=2 | References exist |
| 2 | Access `$wd->dayType` | Returns DayType for id=1 |
| 3 | Access `$wd->dayType2` | Returns DayType for id=2 |
| 4 | Access `$wd->dayType3` | Returns null (not populated) |
| 5 | Eager load all | `WorkingDay::with(['dayType','dayType2','dayType3','dayType4'])->get()` |

#### TC-D23: Controller — findOrFail on edit/update/show/destroy with Invalid IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/school-day/99999` | 404 (ModelNotFoundException) |
| 2 | GET `/day-type/99999/edit` | 404 |
| 3 | GET `/working-day/99999` | 404 |
| 4 | GET `/class-working-day/99999/edit` | 404 |
| 5 | DELETE any route with invalid ID | 404 |

#### TC-D24: Controller — Gate::authorize() Called Before All CRUD Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect SchoolDayController index() | First line: `Gate::authorize('timetable-foundation.school-day.viewAny')` |
| 2 | Inspect SchoolDayController store() | First line: `Gate::authorize('timetable-foundation.school-day.create')` |
| 3 | Inspect WorkingDayController ajaxStore() | First line: `Gate::authorize('timetable-foundation.working-day.create')` |
| 4 | Inspect ClassWorkingDayController eventFeed() | First line: `Gate::authorize('timetable-foundation.class-working-day.viewAny')` |
| 5 | Inspect DayTypeController destroy() | First line: `Gate::authorize('timetable-foundation.day-type.delete')` |

#### TC-D25: Controller — Activity Logged On State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Day Type | Check activity_log for event='Created', model='DayType' |
| 2 | Update Day Type | event='Updated' |
| 3 | Delete School Day | event='Trashed' |
| 4 | Restore School Day | event='Restored' |
| 5 | Force Delete School Day | event='Deleted' |
| 6 | Toggle School Day Status | event='Toggled' |
| 7 | Create Working Day | event='Stored' |
| 8 | Create Class Working Day | event='Created' |

#### TC-D26: Policy — All 4 Policies Define All Required Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open DayPolicy.php | 7 methods: viewAny, view, create, update, delete, restore, forceDelete |
| 2 | Open DayTypePolicy.php | 7 methods; permission strings: timetable-foundation.day-type.* |
| 3 | Open WorkingDayPolicy.php | 7 methods; permission strings: timetable-foundation.working-day.* |
| 4 | Open ClassWorkingDayPolicy.php | 7 methods; permission strings: timetable-foundation.class-working-day.* |
| 5 | Verify each method delegates | Each returns `$user->can('permission.string')` |

#### TC-D27: Routes — Resourceful + Custom Routes Registered for All 4 Controllers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list | grep school-day` | Resource routes (index/create/store/show/edit/update/destroy) + custom trash/restore/forceDelete/toggleStatus registered |
| 2 | Run `route:list | grep working-day/ajax` | 7 AJAX routes (ajaxStore, ajaxEdit, ajaxUpdateRemark, ajaxDestroy, ajaxInitializeWorkingDays, ajaxClearWorkingDays, eventFeed) |
| 3 | Run `route:list | grep class-working-day/ajax` | 5 AJAX routes (ajaxStore, ajaxDestroy, ajaxInitialize, eventFeed, workingDayFeed) |
| 4 | Verify AJAX routes before resource | All custom routes precede resource declaration to prevent wildcard conflicts |
| 5 | Verify auth middleware | All routes behind auth middleware |

#### TC-D28: Working Day — ajaxInitialize Handles Trashed Dates Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create WorkingDay for 2026-07-20, then soft-delete it | Trashed |
| 2 | Run ajaxInitializeWorkingDays | System finds trashed record |
| 3 | Verify 2026-07-20 restored and updated | Restored with correct day_type and is_school_day |
| 4 | Verify no duplicate dates | Unique constraint maintained |
