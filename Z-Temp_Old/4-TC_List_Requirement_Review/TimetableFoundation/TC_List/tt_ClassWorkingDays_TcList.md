# tt_ClassWorkingDays_TcList

## Module: TimetableFoundation → Timetable Masters → Class Working Days

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Class Working Days |
| URL(s) | `GET /timetable-foundation/timetable-masters?tab=class-working-days` — main tab view |
| | `GET /timetable-foundation/class-working-day/ajax/events` — event feed (AJAX) |
| | `GET /timetable-foundation/class-working-day/ajax/working-day-feed` — background feed (AJAX) |
| | `POST /timetable-foundation/class-working-day/ajax/store` — AJAX bulk store |
| | `DELETE /timetable-foundation/class-working-day/ajax/delete/{id}` — AJAX force-delete |
| | `POST /timetable-foundation/class-working-day/ajax/initialize` — AJAX initialize from working days |
| | `GET|POST /timetable-foundation/class-working-day` — resource index/store |
| | `GET /timetable-foundation/class-working-day/create` — resource create |
| | `GET /timetable-foundation/class-working-day/{id}` — resource show |
| | `GET|PUT|PATCH /timetable-foundation/class-working-day/{id}/edit` — resource edit/update |
| | `DELETE /timetable-foundation/class-working-day/{id}` — resource destroy |
| | `GET /timetable-foundation/class-working-day/{id}/restore` — restore |
| | `DELETE /timetable-foundation/class-working-day/{id}/force-delete` — force delete |
| | `GET /timetable-foundation/class-working-day/trash/view` — trash view |
| | `POST /timetable-foundation/class-working-day/{classWorkingDay}/toggle-status` — toggle AJAX |
| Controller | `Modules\TimetableFoundation\Http\Controllers\ClassWorkingDayController` |
| Model(s) | `Modules\TimetableFoundation\Models\ClassWorkingDay` (table: `tt_class_working_days_jnt`) |
| Validation (Create) | Inline in `store()` and AJAX methods (no Form Requests) |
| Validation (Update) | Inline in `update()` |
| Policy | `Modules\TimetableFoundation\Policies\ClassWorkingDayPolicy` (viewAny, view, create, update, delete, restore, forceDelete) |
| Permissions | `timetable-foundation.class-working-day.viewAny` |
| | `timetable-foundation.class-working-day.view` |
| | `timetable-foundation.class-working-day.create` |
| | `timetable-foundation.class-working-day.update` |
| | `timetable-foundation.class-working-day.delete` |
| | `timetable-foundation.class-working-day.restore` |
| | `timetable-foundation.class-working-day.forceDelete` |
| Pagination | None on calendar view; 10 records/page on trash view |
| Soft Deletes | Yes — `SoftDeletes` + `HasFactory` traits on `ClassWorkingDay` model |
| Activity Log | Created, Updated, Trashed, Deleted, Restored, Toggled |

---

## 2. Pre-conditions

- Admin user has all `timetable-foundation.class-working-day.*` permissions granted.
- Dusk environment variables set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- One active `OrganizationAcademicSession` exists with `is_current = 1`, valid `start_date`, and `end_date`.
- School-wide Working Day calendar is initialized (WorkingDay rows exist for the test date range).
- At least 2 active `SchoolClass` records exist (e.g., Class 10, Class 12).
- At least 2 active `Section` records exist (e.g., A, B).
- At least 1 active `PeriodSet` record exists (for period_set_id tests).
- Day Types exist and are active (Study Day, Holiday, Exam, PTM Day).

---

## 3. Default Data Load

The `TimetableFoundationController@timetableMasters()` loads the Class Working Days tab with a FullCalendar instance and shared filter dropdowns.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| FullCalendar instance | `timetableMasters()` | Renders calendar shell | — | None |
| Class filter dropdown | `timetableMasters()` | Active classes | `is_active = 1` | None |
| Section filter dropdown | `timetableMasters()` | Active sections | `is_active = 1` | None |
| Academic Session | `timetableMasters()` | Current session | `is_current = 1` | None |
| Calendar events | `eventFeed()` | `ClassWorkingDay::with(academicSession, class, section, workingDay)->whereBetween('date',[$start,$end])` | `class_ids[]`, `section_ids[]`, date range | None |
| Background events | `workingDayFeed()` | `WorkingDay::with(dayType*)->whereBetween('date',[$start,$end])` | Date range | None |

> **Note:** Events are colour-coded by flag type: exam=red, ptm=green, half_day=orange, holiday=grey, study=blue. Background events from `workingDayFeed` render with reduced opacity behind class events.

---

## 4. Test Data Strategy

- **Working Day baseline**: Initialize the school-wide Working Day calendar via `ajaxInitializeWorkingDays` before any Class Working Day tests.
- **Test classes**: Use existing seeded classes (Class 10, Class 12) or create test classes with unique names.
- **Test sections**: Use sections (A, B) linked to the test classes.
- **Date range**: Use a contiguous 10-day window within the academic session (e.g., 1 April 2026 – 10 April 2026) for bulk operations.
- **Cross-product testing**: For bulk creation, use 2 classes × 2 sections × 5 dates = 20 expected records.
- **Pre-test cleanup**: For initialize tests, use `clear_existing=true` or delete test records by ID.
- **Pagination**: Create 12+ soft-deleted records for trash view pagination tests.
- **Notification test**: Create records with `send_notification=true` and verify event dispatch (mocked).

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_class_working_days_jnt`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | INT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-02 | `academic_session_id` | SMALLINT UNSIGNED | NOT NULL |
| BC-DB-03 | `date` | DATE | NOT NULL |
| BC-DB-04 | `class_id` | INT UNSIGNED | NOT NULL |
| BC-DB-05 | `section_id` | INT UNSIGNED | NULL |
| BC-DB-06 | `working_day_id` | INT UNSIGNED | NOT NULL |
| BC-DB-07 | `is_exam_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-08 | `is_ptm_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-09 | `is_half_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-10 | `is_holiday` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-11 | `is_study_day` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-12 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-13 | `created_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-14 | `updated_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-15 | `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-16 | UNIQUE KEY `uq_class_working_day` | — | `(class_id, working_day_id)` |

> **Note:** The DDL does not define explicit FK constraints with ON DELETE actions. Cascade behaviour for linked ClassWorkingDay records when a WorkingDay row is deleted is implemented in controller code.

### 5.2 Validation Rules — AJAX Store (ajaxStore)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `start` | `required`, `date` | Laravel default |
| BC-VAL-02 | `end` | `nullable`, `date` | Laravel default |
| BC-VAL-03 | `class_ids` | `required`, `array`, `min:1` | Laravel default |
| BC-VAL-04 | `class_ids.*` | `integer`, `exists:sch_classes,id` | Laravel default |
| BC-VAL-05 | `section_ids` | `nullable`, `array` | Laravel default |
| BC-VAL-06 | `section_ids.*` | `integer`, `exists:sch_sections,id` | Laravel default |
| BC-VAL-07 | `day_type` | `required`, `string` | Laravel default |
| BC-VAL-08 | `period_set_id` | `nullable`, `integer`, `exists:tt_period_sets,id` | Laravel default |
| BC-VAL-09 | `send_notification` | `nullable`, `boolean` | Laravel default |
| BC-VAL-10 | `notification_channels` | `nullable`, `array` | Laravel default |
| BC-VAL-11 | `notification_channels.*` | `string`, `in:email,sms,in_app` | Laravel default |
| BC-VAL-12 | *Controller: missing WorkingDay* | — | `"{date} has not been configured in Working Days yet. Please go to the Working Days tab and add this date first."` (422) |

### 5.3 Validation Rules — AJAX Initialize (ajaxInitialize)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-13 | `class_ids` | `required`, `array`, `min:1` | Laravel default |
| BC-VAL-14 | `class_ids.*` | `integer`, `exists:sch_classes,id` | Laravel default |
| BC-VAL-15 | `section_ids` | `nullable`, `array` | Laravel default |
| BC-VAL-16 | `section_ids.*` | `integer`, `exists:sch_sections,id` | Laravel default |
| BC-VAL-17 | `period_set_id` | `nullable`, `integer`, `exists:tt_period_sets,id` | Laravel default |
| BC-VAL-18 | `clear_existing` | `required`, `boolean` | Laravel default |
| BC-VAL-19 | *Controller: no session* | — | `"No current academic session."` (422) |
| BC-VAL-20 | *Controller: no working days* | — | `"No working days found. Please auto-fill Working Days first."` (422) |

### 5.4 Validation Rules — Resource CRUD (store)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-21 | `academic_session_id` | `required`, `integer`, `exists:sch_organization_academic_sessions,id` | Laravel default |
| BC-VAL-22 | `date` | `required`, `date` | Laravel default |
| BC-VAL-23 | `class_id` | `required`, `integer`, `exists:sch_classes,id` | Laravel default |
| BC-VAL-24 | `section_id` | `nullable`, `integer`, `exists:sch_sections,id` | Laravel default |
| BC-VAL-25 | `working_day_id` | `nullable`, `integer`, `exists:tt_working_days,id` | Laravel default |
| BC-VAL-26 | `period_set_id` | `nullable`, `integer`, `exists:tt_period_sets,id` | Laravel default |
| BC-VAL-27 | `is_exam_day` | `nullable`, `boolean` | Normalized via `$request->boolean()` |
| BC-VAL-28 | `is_ptm_day` | `nullable`, `boolean` | Normalized |
| BC-VAL-29 | `is_half_day` | `nullable`, `boolean` | Normalized |
| BC-VAL-30 | `is_holiday` | `nullable`, `boolean` | Normalized |
| BC-VAL-31 | `is_study_day` | `nullable`, `boolean` | Normalized |
| BC-VAL-32 | `is_active` | `nullable`, `boolean` | Normalized |

### 5.5 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `timetable-foundation.class-working-day.viewAny` | Without it → 403 on tab load / eventFeed / workingDayFeed |
| BC-AUTH-02 | `timetable-foundation.class-working-day.view` | Without it → 403 on show |
| BC-AUTH-03 | `timetable-foundation.class-working-day.create` | Without it → 403 on create/store/ajaxStore/ajaxInitialize |
| BC-AUTH-04 | `timetable-foundation.class-working-day.update` | Without it → 403 on edit/update/toggleStatus |
| BC-AUTH-05 | `timetable-foundation.class-working-day.delete` | Without it → 403 on destroy/ajaxDestroy |
| BC-AUTH-06 | `timetable-foundation.class-working-day.restore` | Without it → 403 on restore/trash view |
| BC-AUTH-07 | `timetable-foundation.class-working-day.forceDelete` | Without it → 403 on forceDelete |
| BC-AUTH-08 | Guest access | Redirect to `/login` |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `tab=class-working-days` | FullCalendar rendered with class/section filter dropdowns; background events from workingDayFeed visible; no class events until initialized |
| BC-BIZ-02 | Filter by single class | Select class from dropdown; calendar reloads showing only events for that class |
| BC-BIZ-03 | Filter by class + section | Select class and section; events filtered to that class-section combination |
| BC-BIZ-04 | Bulk create exam days for one class | POST `ajaxStore` with 1 class, 5 dates, day_type="exam"; 5 records created; is_exam_day=true, all other flags false |
| BC-BIZ-05 | Bulk create for multiple classes × sections × dates | POST `ajaxStore` with 2 classes, 2 sections, 5 dates, day_type="study"; 20 records created (2×2×5) |
| BC-BIZ-06 | Create override with "holiday" day type | day_type="holiday"; is_holiday=true, is_study_day=false, other flags false |
| BC-BIZ-07 | Create override with "ptm" day type | day_type="ptm"; is_ptm_day=true, other flags false |
| BC-BIZ-08 | Create override with "half_day" day type | day_type="half_day"; is_half_day=true, other flags false |
| BC-BIZ-09 | Create override with notification | send_notification=true, notification_channels=["email"]; records created; SpecialDayAssigned event dispatched |
| BC-BIZ-10 | Initialize from working days for 1 class | POST `ajaxInitialize` with 1 class; records created matching all WorkingDay rows; is_study_day matches wd.is_school_day; is_holiday is inverse |
| BC-BIZ-11 | Initialize with clear_existing=true | First initialize, then re-initialize with clear_existing=true; old records force-deleted; new records created |
| BC-BIZ-12 | Initialize with period_set_id | period_set_id provided; all created records have period_set_id populated |
| BC-BIZ-13 | Initialize when no WorkingDays exist | 422: "No working days found. Please auto-fill Working Days first." |
| BC-BIZ-14 | Delete a class working day event | DELETE `ajaxDestroy` with event ID `cwd-{id}`; record force-deleted |
| BC-BIZ-15 | Restore soft-deleted record | Soft-delete via resource destroy; restore; record reappears with is_active=true |
| BC-BIZ-16 | Force delete from trash | Soft-delete then force-delete; record permanently removed |
| BC-BIZ-17 | eventFeed returns colour-coded events by flag type | Exam events=red, PTM=green, half_day=orange, holiday=grey, study=blue |
| BC-BIZ-18 | workingDayFeed returns background events | Background events from Working Day calendar visible; reduced opacity/style differentiates from class events |
| BC-BIZ-19 | Existing trashed record restored on ajaxStore | Soft-delete a record; create new override for same class+date; trashed record restored and flags updated |
| BC-BIZ-20 | isTeachingAllowed() behavior | is_active && is_study_day && !is_holiday → true; any other combination → false |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `class_id` | `sch_classes.id` | Not specified in DDL |
| BC-REF-02 | `section_id` | `sch_sections.id` | Not specified in DDL |
| BC-REF-03 | `working_day_id` | `tt_working_days.id` | Not specified in DDL |
| BC-REF-04 | `period_set_id` | `tt_period_sets.id` | Not specified in DDL |

> **Note:** The DDL has no explicit FK constraints with ON DELETE actions. Cascade deletion of ClassWorkingDay records when a WorkingDay row is force-deleted is handled in controller code (`WorkingDayController@ajaxDestroy`).

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Class Working Days tab | `GET /timetable-foundation/timetable-masters?tab=class-working-days` returns 200; FullCalendar rendered; class and section filter dropdowns visible; Initialize and Save buttons present | — | — | ⬜ |
| TC-P02 | View background working day events | workingDayFeed returns events; calendar shows background shading for holidays and working days | — | — | ⬜ |
| TC-P03 | Initialize from working days for one class | POST `ajaxInitialize` with 1 class; records created for all WorkingDay dates; is_study_day matches wd.is_school_day; is_holiday is inverse | — | — | ⬜ |
| TC-P04 | Initialize from working days for multiple classes | POST `ajaxInitialize` with 3 classes; records created for each class × each date | — | — | ⬜ |
| TC-P05 | Initialize with clear_existing=true | Initialize, then re-initialize with clear_existing=true; old records deleted; new records created | — | — | ⬜ |
| TC-P06 | Initialize with period_set_id | Initialize with period_set_id=X; all created records have period_set_id=X | — | — | ⬜ |
| TC-P07 | Bulk create exam overrides for single class | POST `ajaxStore` with 1 class, 5 dates, day_type="exam"; 5 records created; is_exam_day=true | — | — | ⬜ |
| TC-P08 | Bulk create for multiple classes | POST `ajaxStore` with 2 classes, 5 dates, day_type="study"; 10 records created (2×5) | — | — | ⬜ |
| TC-P09 | Bulk create for classes × sections × dates | POST `ajaxStore` with 2 classes, 2 sections, 3 dates, day_type="exam"; 12 records created (2×2×3) | — | — | ⬜ |
| TC-P10 | Create holiday override | day_type="holiday"; is_holiday=true, is_study_day=false | — | — | ⬜ |
| TC-P11 | Create PTM day override | day_type="ptm"; is_ptm_day=true | — | — | ⬜ |
| TC-P12 | Create half day override | day_type="half_day"; is_half_day=true | — | — | ⬜ |
| TC-P13 | Create override with send_notification | send_notification=true, notification_channels=["email","sms"]; records created; SpecialDayAssigned event dispatched | — | — | ⬜ |
| TC-P14 | Create override on date where trashed record exists | Soft-delete existing record; create new override for same class+date; trashed record restored; flags updated | — | — | ⬜ |
| TC-P15 | Filter by single class | Select class from dropdown; calendar shows only events for that class; eventFeed called with class_ids[] param | — | — | ⬜ |
| TC-P16 | Filter by class + section | Select class and section; events filtered to that combination | — | — | ⬜ |
| TC-P17 | Delete single class working day | Click delete on event; DELETE `ajaxDestroy`; record force-deleted; event removed from calendar | — | — | ⬜ |
| TC-P18 | Restore soft-deleted record | Soft-delete via resource destroy; navigate to trash; click restore; record reappears in calendar | — | — | ⬜ |
| TC-P19 | Force delete from trash | Soft-delete; navigate to trash; click force delete; record permanently removed | — | — | ⬜ |
| TC-P20 | Toggle active status via AJAX | POST toggle-status; JSON `{ success: true, is_active: <new_value>, message }` | — | — | ⬜ |
| TC-P21 | Event feed colour coding by flag type | exam=red, ptm=green, half_day=orange, holiday=grey, study=blue | — | — | ⬜ |
| TC-P22 | isTeachingAllowed helper after creation | New study day record: isTeachingAllowed()=true; new holiday record: isTeachingAllowed()=false | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create override on uninitialized date | POST `ajaxStore` with date that has no WorkingDay row; 422: "{date} has not been configured in Working Days yet." | — | — | ⬜ |
| TC-N02 | Initialize with no current session | Set no active session; POST `ajaxInitialize`; 422: "No current academic session." | — | — | ⬜ |
| TC-N03 | Initialize with no working days | Delete all WorkingDay rows; POST `ajaxInitialize`; 422: "No working days found. Please auto-fill Working Days first." | — | — | ⬜ |
| TC-N04 | AJAX store — missing class_ids | POST `ajaxStore` without class_ids; validation error | — | — | ⬜ |
| TC-N05 | AJAX store — empty class_ids array | POST `ajaxStore` with class_ids=[]; validation error: min:1 | — | — | ⬜ |
| TC-N06 | AJAX store — missing start date | POST `ajaxStore` without start; validation error | — | — | ⬜ |
| TC-N07 | AJAX store — missing day_type | POST `ajaxStore` without day_type; validation error | — | — | ⬜ |
| TC-N08 | AJAX store — invalid class_id | POST `ajaxStore` with class_ids=[9999]; validation error: exists rule | — | — | ⬜ |
| TC-N09 | AJAX store — invalid section_id | POST `ajaxStore` with section_ids=[9999]; validation error: exists rule | — | — | ⬜ |
| TC-N10 | AJAX store — invalid period_set_id | POST `ajaxStore` with period_set_id=9999; validation error: exists rule | — | — | ⬜ |
| TC-N11 | AJAX store — invalid notification channel | POST `ajaxStore` with notification_channels=["telegram"]; validation error: in:email,sms,in_app | — | — | ⬜ |
| TC-N12 | AJAX initialize — missing class_ids | POST `ajaxInitialize` without class_ids; validation error | — | — | ⬜ |
| TC-N13 | AJAX destroy — non-existent ID | DELETE `ajaxDestroy` with id `cwd-99999`; 404 | — | — | ⬜ |
| TC-N14 | Guest access | Log out; navigate to tab; redirect to `/login` | — | — | ⬜ |
| TC-N15 | Missing viewAny on eventFeed | User without viewAny calls eventFeed; 403 | — | — | ⬜ |
| TC-N16 | Missing create on ajaxStore | User without create calls ajaxStore; 403 | — | — | ⬜ |
| TC-N17 | Missing delete on ajaxDestroy | User without delete calls ajaxDestroy; 403 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Cascade — WorkingDay last-slot delete force-deletes linked ClassWorkingDay | Delete last slot on a WorkingDay with force=true; both WorkingDay and linked ClassWorkingDay records force-deleted | — | — | ⬜ |
| TC-D02 | A | Cascade — WorkingDay clear-all deletes linked ClassWorkingDay | Run ajaxClearWorkingDays; all WorkingDay and linked ClassWorkingDay records force-deleted | — | — | ⬜ |
| TC-D03 | B | Unique (class_id, working_day_id) constraint at DB level | Insert duplicate (class_id, working_day_id) directly; SQL integrity constraint violation | — | — | ⬜ |
| TC-D04 | C | Activity logging on all state changes | Create, update, trash, restore, force-delete, toggle — each creates an activity log entry | — | — | ⬜ |
| TC-D05 | D | Model `$fillable` matches DDL columns | `$fillable` contains: academic_session_id, date, class_id, section_id, working_day_id, period_set_id, is_exam_day, is_ptm_day, is_half_day, is_holiday, is_study_day, is_active | — | — | ⬜ |
| TC-D06 | D | Model `$casts` for boolean/integer/dates | All 5 flag columns → boolean; is_active → boolean; date → date; FK columns → integer | — | — | ⬜ |
| TC-D07 | D | Model — SoftDeletes + HasFactory traits | Both traits imported and used | — | — | ⬜ |
| TC-D08 | D | Model — relationships defined | `academicSession()` belongsTo, `class()` belongsTo, `section()` belongsTo, `workingDay()` belongsTo | — | — | ⬜ |
| TC-D09 | E | SpecialDayAssigned event dispatched | When send_notification=true, event dispatched with classWorkingDays, channels, user | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns | All 12 DDL columns present; no extra column | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/dates | `is_exam_day`→boolean, `is_ptm_day`→boolean, `is_half_day`→boolean, `is_holiday`→boolean, `is_study_day`→boolean, `is_active`→boolean, `date`→date | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes + HasFactory traits | Both `SoftDeletes` and `HasFactory` imported and used | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | `academicSession()`, `class()`, `section()`, `workingDay()` — all belongsTo | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — helper methods | `isTeachingAllowed()` returns `is_active && is_study_day && !is_holiday`; `isSpecialDay()` returns `is_exam_day \|\| is_ptm_day \|\| is_half_day` | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — try-catch on AJAX write methods | `ajaxStore`, `ajaxDestroy`, `ajaxInitialize` have exception handling | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Each public method gates with appropriate `timetable-foundation.class-working-day.*` permission | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on state changes | All state-changing methods log via `activityLog()` | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `toggleStatus()` flips `is_active` | Validates boolean, updates model, returns JSON | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — trash/restore/forceDelete flow | Trash view uses `onlyTrashed()`, restore uses `onlyTrashed()->findOrFail()`, forceDelete uses `withTrashed()->findOrFail()` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — `resolveDayTypeFlags()` maps strings correctly | "study" → [is_study_day=true]; "exam" → [is_exam_day=true]; "ptm" → [is_ptm_day=true]; "half_day" → [is_half_day=true]; "holiday" → [is_holiday=true] | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — JSON responses for AJAX endpoints | All AJAX methods return JSON with `status`, `message`; errors with appropriate HTTP codes | — | — | ◌ |
| TC-CR13 | CR | P1 | Validation — rules cover all fields | Inline validation in each method covers required fields | — | — | ◌ |
| TC-CR14 | CR | P1 | Policy — all 7 CRUD methods defined | `ClassWorkingDayPolicy` defines viewAny, view, create, update, delete, restore, forceDelete | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes — resource + custom AJAX routes registered | Resource routes + AJAX routes (store, delete, initialize, events, working-day-feed) registered | — | — | ◌ |
| TC-CR16 | CR | P1 | Event — SpecialDayAssigned dispatches correctly | Event dispatched with classWorkingDays (Collection), channels (array), user (authenticated) | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDay.php` `$fillable` array | Array contains: `academic_session_id`, `date`, `class_id`, `section_id`, `working_day_id`, `period_set_id`, `is_exam_day`, `is_ptm_day`, `is_half_day`, `is_holiday`, `is_study_day`, `is_active` |
| 2 | Cross-reference with `tt_class_working_days_jnt` DDL | All 12 fillable columns exist in DDL; no fillable column absent; no DDL column that should be fillable is missing |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDay.php` `$casts` array | `is_exam_day`→boolean, `is_ptm_day`→boolean, `is_half_day`→boolean, `is_holiday`→boolean, `is_study_day`→boolean, `is_active`→boolean, `date`→date; FK columns (`academic_session_id`, `class_id`, `section_id`, `working_day_id`, `period_set_id`)→integer |

#### TC-CR03: Model — SoftDeletes + HasFactory Traits

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDay.php` imports | Both `use SoftDeletes;` and `use HasFactory;` imported from appropriate namespaces |
| 2 | Verify `deleted_at` in `$casts` | `'deleted_at' => 'datetime'` present in `$casts` array |

#### TC-CR04: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDay.php` | `academicSession()` returns `$this->belongsTo(OrganizationAcademicSession::class)` |
| 2 | Inspect `class()` relationship | `class()` returns `$this->belongsTo(SchoolClass::class)` |
| 3 | Inspect `section()` relationship | `section()` returns `$this->belongsTo(Section::class)` |
| 4 | Inspect `workingDay()` relationship | `workingDay()` returns `$this->belongsTo(WorkingDay::class)` |

#### TC-CR05: Model — Helper Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `isTeachingAllowed()` method | Returns `$this->is_active && $this->is_study_day && !$this->is_holiday` |
| 2 | Inspect `isSpecialDay()` method | Returns `$this->is_exam_day \|\| $this->is_ptm_day \|\| $this->is_half_day` |

#### TC-CR06: Controller — Try-Catch on AJAX Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDayController.php` `ajaxStore()` method | Wrapped in `try-catch`; validation exceptions and database errors handled gracefully; error JSON returned on failure |
| 2 | Inspect `ajaxDestroy()` and `ajaxInitialize()` methods | Each wrapped in try-catch; exceptions do not produce unhandled 500 errors |

#### TC-CR07: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each public method in `ClassWorkingDayController.php` | Every method gates with appropriate `timetable-foundation.class-working-day.*` permission: viewAny on index/eventFeed/workingDayFeed; create on store/ajaxStore/ajaxInitialize; update on edit/toggleStatus; delete on destroy/ajaxDestroy; restore on restore/trash view; forceDelete on forceDelete |

#### TC-CR08: Controller — Activity Logged on State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect state-changing methods | Each calls `activityLog()` with appropriate action: `'Created'` (store/ajaxStore), `'Updated'` (update), `'Trashed'` (destroy), `'Deleted'` (forceDelete/ajaxDestroy), `'Restored'` (restore), `'Toggled'` (toggleStatus) |

#### TC-CR09: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` method | Validates incoming `is_active` boolean; updates model's `is_active` attribute; returns JSON `{"success": true, "is_active": <new_value>, "message": "..."}` |

#### TC-CR10: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect trash view method | Uses `ClassWorkingDay::onlyTrashed()->paginate(10)` |
| 2 | Inspect `restore()` method | Uses `ClassWorkingDay::onlyTrashed()->findOrFail($id)` |
| 3 | Inspect `forceDelete()` method | Uses `ClassWorkingDay::withTrashed()->findOrFail($id)` |

#### TC-CR11: Controller — `resolveDayTypeFlags()` Maps Strings Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `resolveDayTypeFlags()` method | Input `"study"` returns array with `is_study_day=true` and all other flags false |
| 2 | Inspect mapping for `"exam"` | Returns `is_exam_day=true`, other flags false |
| 3 | Inspect mapping for `"ptm"` | Returns `is_ptm_day=true`, other flags false |
| 4 | Inspect mapping for `"half_day"` | Returns `is_half_day=true`, other flags false |
| 5 | Inspect mapping for `"holiday"` | Returns `is_holiday=true`, `is_study_day=false`, other flags false |

#### TC-CR12: Controller — JSON Responses for AJAX Endpoints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ajaxStore()`, `ajaxDestroy()`, `ajaxInitialize()`, `eventFeed()`, `workingDayFeed()` methods | All AJAX methods return `response()->json(...)` with `status`, `message` keys; errors return appropriate HTTP codes (422 for validation, 404 for not found, 403 for forbidden) |

#### TC-CR13: Validation — Rules Cover All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ajaxStore()` validation | `start` required/date; `class_ids` required/array/min:1; `class_ids.*` integer/exists:sch_classes; `day_type` required/string; `section_ids.*` exists:sch_sections; `period_set_id` exists:tt_period_sets; `notification_channels.*` in:email,sms,in_app |
| 2 | Inspect `ajaxInitialize()` validation | `class_ids` required/array/min:1; `clear_existing` required/boolean; `section_ids` nullable/array; `period_set_id` nullable/exists |
| 3 | Inspect resource `store()` validation | `academic_session_id` required/exists; `date` required/date; `class_id` required/exists; `working_day_id` nullable/exists; boolean flags normalized |

#### TC-CR14: Policy — All 7 CRUD Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDayPolicy.php` | Policy defines: `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()` — each returning boolean based on authenticated user's permissions |

#### TC-CR15: Routes — Resource + Custom AJAX Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect route definitions for class-working-day | `Route::resource('class-working-day', ...)` generates 7 resource routes |
| 2 | Locate AJAX routes | Custom routes: `ajax/events` (GET), `ajax/working-day-feed` (GET), `ajax/store` (POST), `ajax/delete/{id}` (DELETE), `ajax/initialize` (POST) |
| 3 | Verify trash/restore/forceDelete/toggle routes | Additional routes for trash/view, restore, force-delete, toggle-status |

#### TC-CR16: Event — `SpecialDayAssigned` Dispatches Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ajaxStore()` method where `send_notification=true` | `SpecialDayAssigned` event dispatched with: `classWorkingDays` (Collection of created records), `channels` (array from request, e.g. `['email', 'sms']`), `user` (authenticated user from `Auth::user()`) |

---

### 7.1 Positive TC Steps

#### TC-P01: Load Class Working Days Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as admin with full permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/timetable-masters?tab=class-working-days` | HTTP 200; Class Working Days tab pane active |
| 3 | Verify FullCalendar rendered | Calendar grid visible; navigation buttons present |
| 4 | Verify filter dropdowns | Class filter dropdown with class list; Section filter dropdown with section list |
| 5 | Verify action buttons | "Initialize from Working Days" and bulk action buttons present |
| 6 | Verify background events | Calendar shows background shading for working/holiday days from workingDayFeed |

#### TC-P02: View Background Working Day Events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Working Day calendar is initialized | — |
| 2 | Navigate to Class Working Days tab | Calendar shows background events: holidays in one shade, working days in another |
| 3 | Inspect workingDayFeed response | Returns WorkingDay events with `display: 'background'` or similar background rendering property |

#### TC-P03: Initialize from Working Days (Single Class)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure WorkingDay calendar has rows for the session | — |
| 2 | Click "Initialize from Working Days" | Dialog opens with class multi-select |
| 3 | Select Class 10, click OK | POST `ajaxInitialize` with `class_ids=[10]` |
| 4 | Verify response | `{ status: true, message: "Created {N} class working day(s)." }` |
| 5 | Verify calendar shows events | Each date has a coloured event for Class 10 |
| 6 | Verify mapping | Dates where wd.is_school_day=1 → is_study_day=true; dates where wd.is_school_day=0 → is_holiday=true |

#### TC-P04: Initialize from Working Days (Multiple Classes)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize for Class 10, Class 12, Class 5 simultaneously | — |
| 2 | Verify record count | 3 [classes] × {N} [working day dates] records created |
| 3 | Verify each class has events on calendar | Filter by each class individually; events present for each |

#### TC-P05: Initialize with clear_existing=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize Class 10 (records created) | — |
| 2 | Re-initialize Class 10 with clear_existing=true | Old records force-deleted; new records created |
| 3 | Verify old records gone | No ClassWorkingDay records with old IDs |
| 4 | Verify new records present | Fresh records created |

#### TC-P06: Initialize with period_set_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize Class 10 with period_set_id=1 | — |
| 2 | Query DB for created records | All records have `period_set_id = 1` |

#### TC-P07: Bulk Create Exam Overrides (Single Class)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 10, date range 1 Apr – 5 Apr, day_type="exam" | — |
| 2 | Click Save | POST `ajaxStore` |
| 3 | Verify response | `{ status: true, message: "5 class working day(s) saved.", count: 5 }` |
| 4 | Verify 5 records created | DB has 5 ClassWorkingDay records for Class 10 on those dates |
| 5 | Verify flags | `is_exam_day=true`, `is_study_day=false`, `is_ptm_day=false`, `is_half_day=false`, `is_holiday=false` |
| 6 | Verify calendar events | 5 red events (exam colour) for Class 10 on Apr 1–5 |

#### TC-P08: Bulk Create for Multiple Classes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 10 and Class 12, date range 1 Apr – 5 Apr, day_type="study" | — |
| 2 | Click Save | 10 records created (2 classes × 5 dates) |
| 3 | Verify response | count=10 |

#### TC-P09: Bulk Create with Sections × Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 10, sections A and B, date range 1 Apr – 3 Apr, day_type="exam" | — |
| 2 | Click Save | 6 records created (1 class × 2 sections × 3 dates) |
| 3 | Verify each record has correct section_id | section_id = A for 3 records, B for 3 records |

#### TC-P10: Create Holiday Override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 10, date 15 Apr, day_type="holiday" | — |
| 2 | Click Save | 1 record created |
| 3 | Verify flags | `is_holiday=true`, `is_study_day=false` |

#### TC-P11: Create PTM Day Override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 12, date 20 Apr, day_type="ptm" | — |
| 2 | Click Save | 1 record created |
| 3 | Verify flags | `is_ptm_day=true`, `is_study_day=false` |

#### TC-P12: Create Half Day Override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 10, date 25 Apr, day_type="half_day" | — |
| 2 | Click Save | 1 record created |
| 3 | Verify flags | `is_half_day=true`, `is_study_day=false` |

#### TC-P13: Create Override with Notification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 10, date 1 May, day_type="exam", check "Send Notification", select "Email" and "SMS" | — |
| 2 | Click Save | Records created; SpecialDayAssigned event dispatched with channels=["email","sms"] |

#### TC-P14: Create Override on Date with Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Class 10 override for 10 Apr | — |
| 2 | Soft-delete that record | — |
| 3 | Create a new override for Class 10, 10 Apr, day_type="exam" | Trashed record restored; flags updated to exam; no duplicate record created |

#### TC-P15: Filter by Single Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records for Class 10 and Class 12 | — |
| 2 | Select "Class 10" from filter dropdown | Calendar reloads; only Class 10 events visible |
| 3 | Inspect network request | eventFeed called with `class_ids[]=10` |

#### TC-P16: Filter by Class + Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records for Class 10-A and Class 10-B | — |
| 2 | Select "Class 10" and "Section A" | Only Class 10-A events visible |

#### TC-P17: Delete Single Class Working Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete icon on a Class 10 exam day event for 1 Apr | DELETE `ajaxDestroy` with id `cwd-{id}` |
| 2 | Verify response | `{ status: true, message: "Class working day deleted." }` |
| 3 | Verify event removed | Event no longer visible on calendar |

#### TC-P18: Restore Soft-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a ClassWorkingDay record via resource destroy | — |
| 2 | Navigate to trash view: `GET /class-working-day/trash/view` | Record listed |
| 3 | Click Restore | Record restored; is_active=true |
| 4 | Navigate back to calendar | Event visible again |

#### TC-P19: Force Delete from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a ClassWorkingDay record | — |
| 2 | Navigate to trash view | Record listed |
| 3 | Click Force Delete | Record permanently removed |

#### TC-P20: Toggle Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on a ClassWorkingDay record | AJAX POST to toggle-status |
| 2 | Verify response | JSON `{ success: true, is_active: false, message: "..." }` |
| 3 | Verify UI updates | Status badge changes |

#### TC-P21: Event Feed Colour Coding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records with different day types: exam, ptm, half_day, holiday, study | — |
| 2 | Inspect eventFeed response | exam events have `backgroundColor` = red; ptm=green; half_day=orange; holiday=grey; study=blue |

#### TC-P22: isTeachingAllowed Helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a study day record: is_study_day=true, is_holiday=false, is_active=true | `isTeachingAllowed()` = true |
| 2 | Create a holiday record: is_holiday=true | `isTeachingAllowed()` = false |
| 3 | Create an inactive study day record: is_active=false | `isTeachingAllowed()` = false |

---

### 7.2 Negative TC Steps

#### TC-N01: Create Override on Uninitialized Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 10, date range including a date with NO WorkingDay row | — |
| 2 | Click Save | 422: "{date} has not been configured in Working Days yet. Please go to the Working Days tab and add this date first." |
| 3 | Verify no records created | No ClassWorkingDay records for any date in the range |

#### TC-N02: Initialize with No Current Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set all academic sessions to `is_current=0` | — |
| 2 | Click "Initialize from Working Days" with any class | 422: "No current academic session." |
| 3 | Restore session | Clean up |

#### TC-N03: Initialize with No Working Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear all WorkingDay rows via ajaxClearWorkingDays | — |
| 2 | Click "Initialize from Working Days" with any class | 422: "No working days found. Please auto-fill Working Days first." |

#### TC-N04: AJAX Store — Missing class_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` without `class_ids` parameter | Validation error: "The class ids field is required." |

#### TC-N05: AJAX Store — Empty class_ids Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` with `class_ids=[]` | Validation error: "The class ids must have at least 1 items." |

#### TC-N06: AJAX Store — Missing start Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` without `start` parameter | Validation error: "The start field is required." |

#### TC-N07: AJAX Store — Missing day_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` without `day_type` parameter | Validation error: "The day type field is required." |

#### TC-N08: AJAX Store — Invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` with `class_ids=[9999]` | Validation error: "The selected class_ids.0 is invalid." |

#### TC-N09: AJAX Store — Invalid section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` with `section_ids=[9999]` | Validation error: "The selected section_ids.0 is invalid." |

#### TC-N10: AJAX Store — Invalid period_set_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` with `period_set_id=9999` | Validation error: "The selected period set id is invalid." |

#### TC-N11: AJAX Store — Invalid Notification Channel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` with `notification_channels=["telegram"]` | Validation error: "The selected notification_channels.0 is invalid." |

#### TC-N12: AJAX Initialize — Missing class_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxInitialize` without `class_ids` | Validation error: "The class ids field is required." |

#### TC-N13: AJAX Destroy — Non-Existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `ajaxDestroy` with id `cwd-99999` | HTTP 404 |

#### TC-N14: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to tab | Redirected to `/login` |

#### TC-N15: Missing viewAny on eventFeed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `viewAny` | — |
| 2 | Call GET `eventFeed` | 403 Forbidden |

#### TC-N16: Missing create on ajaxStore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `create` permission | — |
| 2 | POST `ajaxStore` with valid data | 403 Forbidden |

#### TC-N17: Missing delete on ajaxDestroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `delete` permission | — |
| 2 | DELETE `ajaxDestroy` with valid ID | 403 Forbidden |

---

### 7.3 Dependency TC Steps

#### TC-D01: Cascade — WorkingDay Last-Slot Delete Deletes Linked ClassWorkingDay

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ClassWorkingDay records linked to a specific WorkingDay | — |
| 2 | Delete the last slot on that WorkingDay with `force=true` via Working Days tab | WorkingDay row force-deleted; linked ClassWorkingDay records force-deleted |
| 3 | Query DB | Both WorkingDay and ClassWorkingDay records absent |

#### TC-D02: Cascade — WorkingDay Clear-All Deletes Linked ClassWorkingDay

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ClassWorkingDay records | — |
| 2 | Run `ajaxClearWorkingDays` on Working Days tab | All WorkingDay rows force-deleted; all linked ClassWorkingDay records force-deleted |

#### TC-D03: Unique (class_id, working_day_id) Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate directly: `INSERT INTO tt_class_working_days_jnt (academic_session_id, date, class_id, working_day_id) VALUES (1, '2026-04-01', 10, 42)` twice | Second insert throws `SQLSTATE[23000]: Integrity constraint violation` for `uq_class_working_day` |

#### TC-D04: Activity Logging

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a ClassWorkingDay record | Activity log: 'Class working day was created.' |
| 2 | Update a record | Activity log: 'Class working day was updated.' |
| 3 | Soft-delete a record | Activity log: 'Class working day was trashed.' |
| 4 | Restore from trash | Activity log: 'Class working day was restored.' |
| 5 | Force delete from trash | Activity log: 'Class working day was permanently deleted.' |
| 6 | Toggle status | Activity log: 'Class working day status was toggled.' |

#### TC-D05: Model — `$fillable` Matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDay.php` `$fillable` array | Contains: `academic_session_id`, `date`, `class_id`, `section_id`, `working_day_id`, `period_set_id`, `is_exam_day`, `is_ptm_day`, `is_half_day`, `is_holiday`, `is_study_day`, `is_active` |

#### TC-D06: Model — `$casts` for Boolean/Integer/Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDay.php` `$casts` array | `is_exam_day`→boolean, `is_ptm_day`→boolean, `is_half_day`→boolean, `is_holiday`→boolean, `is_study_day`→boolean, `is_active`→boolean, `date`→date, FK columns→integer |

#### TC-D07: Model — SoftDeletes + HasFactory

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDay.php` imports | Both `SoftDeletes` and `HasFactory` imported |
| 2 | Verify `deleted_at` in `$casts` | `'deleted_at' => 'datetime'` present |

#### TC-D08: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassWorkingDay.php` | `academicSession()` returns `belongsTo(OrganizationAcademicSession::class)`; `class()` returns `belongsTo(SchoolClass::class)`; `section()` returns `belongsTo(Section::class)`; `workingDay()` returns `belongsTo(WorkingDay::class)` |

#### TC-D09: SpecialDayAssigned Event Dispatched

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Mock the event dispatcher or check log | When send_notification=true, `SpecialDayAssigned` event dispatched with: `classWorkingDays` (Collection of created records), `channels` (array like ['email', 'sms']), `user` (authenticated user) |

---
