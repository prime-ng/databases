# tt_WorkingDays_TcList

## Module: TimetableFoundation → Timetable Masters → Working Days

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Working Days |
| URL(s) | `GET /timetable-foundation/timetable-masters?tab=working-days` — main tab view |
| | `GET /timetable-foundation/working-day/ajax/events` — FullCalendar event feed (AJAX) |
| | `POST /timetable-foundation/working-day/ajax/store` — AJAX add day type |
| | `POST /timetable-foundation/working-day/ajax/edit` — AJAX drag-move day type |
| | `POST /timetable-foundation/working-day/ajax/remark/{id}` — AJAX update remarks |
| | `DELETE /timetable-foundation/working-day/ajax/delete/{id}` — AJAX destroy slot/row |
| | `POST /timetable-foundation/working-day/ajax/initialize-calander` — AJAX initialize calendar |
| | `DELETE /timetable-foundation/working-day/ajax/clear` — AJAX clear all |
| | `GET|POST /timetable-foundation/working-day` — resource index/store |
| | `GET /timetable-foundation/working-day/create` — resource create form |
| | `GET /timetable-foundation/working-day/{id}` — resource show |
| | `GET|PUT|PATCH /timetable-foundation/working-day/{id}/edit` — resource edit/update |
| | `DELETE /timetable-foundation/working-day/{id}` — resource destroy |
| | `GET /timetable-foundation/working-day/{id}/restore` — restore |
| | `DELETE /timetable-foundation/working-day/{id}/force-delete` — force delete |
| | `GET /timetable-foundation/working-day/trash/view` — trash view |
| | `POST /timetable-foundation/working-day/{workingDay}/toggle-status` — toggle AJAX |
| Controller | `Modules\TimetableFoundation\Http\Controllers\WorkingDayController` |
| Model(s) | `Modules\TimetableFoundation\Models\WorkingDay` (table: `tt_working_days`) |
| Validation (Create) | Inline in `store()` and AJAX methods (no Form Requests) |
| Validation (Update) | Inline in `update()` |
| Policy | `Modules\TimetableFoundation\Policies\WorkingDayPolicy` (viewAny, view, create, update, delete, restore, forceDelete) |
| Permissions | `timetable-foundation.working-day.viewAny` |
| | `timetable-foundation.working-day.view` |
| | `timetable-foundation.working-day.create` |
| | `timetable-foundation.working-day.update` |
| | `timetable-foundation.working-day.delete` |
| | `timetable-foundation.working-day.restore` |
| | `timetable-foundation.working-day.forceDelete` |
| Pagination | None on calendar view (FullCalendar lazy-loads); 10 records/page on trash view |
| Soft Deletes | Yes — `SoftDeletes` trait on `WorkingDay` model |
| Activity Log | Stored, Updated, Trashed, Restored, Deleted, Toggled |

---

## 2. Pre-conditions

- Admin user has all `timetable-foundation.working-day.*` permissions granted.
- Dusk environment variables set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- One active `OrganizationAcademicSession` exists with `is_current = 1`, valid `start_date`, and `end_date`.
- At least 2 active Day Types exist: one with `is_working_day = 1` (e.g., "Study Day") and one with `is_working_day = 0` (e.g., "Holiday").
- Day Types have distinct codes for colour-mapping verification (e.g., STUDY, HOLIDAY, EXAM, PTM_DAY).
- School Days seeded (7 rows) with `week_start_day` and `default_school_closed_days_per_week` configured in `tt_configs`.
- No existing WorkingDay records in the test date range (or initial setup creates a clean slate).

---

## 3. Default Data Load

The `TimetableFoundationController@timetableMasters()` loads the Working Days tab, rendering a FullCalendar instance. Events are loaded asynchronously via `eventFeed()`.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| FullCalendar instance | `timetableMasters()` | Renders calendar shell; no events on load | — | None |
| Calendar events | `WorkingDayController@eventFeed()` | `WorkingDay::with(dayType,dayType2,dayType3,dayType4)->whereBetween('date',[$start,$end])` | Date range `start`/`end` (FullCalendar params) | None |
| Day Types dropdown | `timetableMasters()` | Active day types for the add-dialog | `is_active = 1` | None |
| Academic Session | `timetableMasters()` | Current session | `is_current = 1` | None |

> **Note:** Each filled day-type slot emits a separate event with ID `wd-{workingDayId}-{slot}`. Empty slots emit no event. One WorkingDay row can emit up to 4 events.

---

## 4. Test Data Strategy

- **Calendar initialisation**: Use `ajaxInitializeWorkingDays` to create baseline data for a defined date range (e.g., 1 April 2026 to 30 April 2026 = 30 days).
- **Day Types**: Use seeded types STUDY (working), HOLIDAY (non-working), EXAM (non-working), PTM_DAY (working, reduced_periods). Create additional test types if needed.
- **Date range**: Use a contiguous 30-day window within the academic session for range-based AJAX operations (ajaxStore with start/end).
- **Linked records**: For cascade tests, create `ClassWorkingDay` records referencing specific WorkingDay IDs.
- **Trash tests**: Create WorkingDay rows and soft-delete them via the resource destroy endpoint.
- **Pre-test cleanup**: Use `ajaxClearWorkingDays` to reset the calendar between test suites or use unique date ranges to avoid collision.
- **Pagination**: Create 12+ soft-deleted records to test the 10/page trash view pagination.

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_working_days`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | INT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-02 | `academic_session_id` | SMALLINT UNSIGNED | NOT NULL |
| BC-DB-03 | `date` | DATE | NOT NULL, UNIQUE (`uq_workday_date`) |
| BC-DB-04 | `day_type1_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_day_types(id)` ON DELETE RESTRICT |
| BC-DB-05 | `day_type2_id` | TINYINT UNSIGNED | NULL, FK → `tt_day_types(id)` ON DELETE RESTRICT |
| BC-DB-06 | `day_type3_id` | TINYINT UNSIGNED | NULL, FK → `tt_day_types(id)` ON DELETE RESTRICT |
| BC-DB-07 | `day_type4_id` | TINYINT UNSIGNED | NULL, FK → `tt_day_types(id)` ON DELETE RESTRICT |
| BC-DB-08 | `is_school_day` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-09 | `remarks` | VARCHAR(255) | DEFAULT NULL |
| BC-DB-10 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-11 | `created_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-12 | `updated_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-13 | `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-14 | UNIQUE KEY `uq_workday_date` | — | `date` |
| BC-DB-15 | FK `fk_workday_daytype1` | — | `day_type1_id` → `tt_day_types(id)` ON DELETE RESTRICT |
| BC-DB-16 | FK `fk_workday_daytype2` | — | `day_type2_id` → `tt_day_types(id)` ON DELETE RESTRICT |
| BC-DB-17 | FK `fk_workday_daytype3` | — | `day_type3_id` → `tt_day_types(id)` ON DELETE RESTRICT |
| BC-DB-18 | FK `fk_workday_daytype4` | — | `day_type4_id` → `tt_day_types(id)` ON DELETE RESTRICT |

### 5.2 Validation Rules — Inline in `store()` (Resource CRUD)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `date` | `required`, `date` | Laravel default |
| BC-VAL-02 | `day_type1_id` | `required`, `exists:tt_day_types,id` | Laravel default |
| BC-VAL-03 | `is_school_day` | `required`, `boolean` | Laravel default |
| BC-VAL-04 | `is_active` | `nullable`, `boolean` | Normalized via `$request->boolean()` |

### 5.3 Validation Rules — AJAX Store (ajaxStore)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-05 | `start` | `required`, `date` | Laravel default |
| BC-VAL-06 | `end` | `nullable`, `date` | Laravel default |
| BC-VAL-07 | `day_type_id` | `required`, `exists:tt_day_types,id` | Laravel default |
| BC-VAL-08 | *Controller: duplicate type* | — | `"{name}" is already assigned to this date.` |
| BC-VAL-09 | *Controller: max 4 types* | — | `"This date already has 4 day types (max)."` |
| BC-VAL-10 | *Controller: add working to holiday* | — | `"Cannot add a working day type — this date is already a holiday."` |
| BC-VAL-11 | *Controller: add holiday to working* | — | `"Cannot add a holiday — this date already has working day type(s)."` |
| BC-VAL-12 | *Controller: second non-working* | — | `"Only one holiday type allowed per date."` |

### 5.4 Validation Rules — AJAX Edit (ajaxEdit)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-13 | `id` | `required`, `string` | Laravel default |
| BC-VAL-14 | `date` | `required`, `date` | Laravel default |
| BC-VAL-15 | *Controller: invalid event ID* | — | `"Invalid event ID."` (422) |
| BC-VAL-16 | *Controller: source slot empty* | — | `"Source slot is empty."` (422) |
| BC-VAL-17 | *Controller: source type not found* | — | `"Source day type not found."` (422) |
| BC-VAL-18 | *Controller: same source/target date* | — | `"No change."` (200) |

### 5.5 Validation Rules — AJAX Update Remark (ajaxUpdateRemark)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-19 | `remarks` | `nullable`, `string`, `max:255` | Laravel default |

### 5.6 Controller-level Checks — AJAX Destroy (ajaxDestroy)

| BC ID | Condition | Error Message |
|-------|-----------|---------------|
| BC-VAL-20 | Invalid event ID | `"Invalid event ID."` (422) |
| BC-VAL-21 | Working day not found | `"Working day not found or already deleted."` (404) |
| BC-VAL-22 | Slot already empty | `"That slot is already empty."` (422) |
| BC-VAL-23 | Last slot with linked records, no force | `"{N} class working day record(s) are linked to {date}. Removing the last day type will also remove those records."` (200, requires_confirm) |

### 5.7 Controller-level Checks — AJAX Initialize (ajaxInitializeWorkingDays)

| BC ID | Condition | Error Message |
|-------|-----------|---------------|
| BC-VAL-24 | No current session or missing dates | `"No current academic session found or session has no start/end dates."` (422) |
| BC-VAL-25 | No active Working Day type | `"No active Working Day type found."` (422) |
| BC-VAL-26 | No active Holiday type | `"No active Holiday day type found."` (422) |

### 5.8 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `timetable-foundation.working-day.viewAny` | Without it → 403 on tab load / eventFeed |
| BC-AUTH-02 | `timetable-foundation.working-day.view` | Without it → 403 on show |
| BC-AUTH-03 | `timetable-foundation.working-day.create` | Without it → 403 on create/store/ajaxStore/ajaxInitialize |
| BC-AUTH-04 | `timetable-foundation.working-day.update` | Without it → 403 on edit/update/ajaxEdit/ajaxUpdateRemark/toggleStatus |
| BC-AUTH-05 | `timetable-foundation.working-day.delete` | Without it → 403 on destroy/ajaxDestroy/ajaxClear |
| BC-AUTH-06 | `timetable-foundation.working-day.restore` | Without it → 403 on restore/trash view |
| BC-AUTH-07 | `timetable-foundation.working-day.forceDelete` | Without it → 403 on forceDelete |
| BC-AUTH-08 | Guest access | Redirect to `/login` |

### 5.9 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `tab=working-days` | FullCalendar instance rendered; no events on page load; events fetched via `eventFeed` AJAX when calendar renders |
| BC-BIZ-02 | Initialize calendar with valid config | WorkingDay rows created for all dates in session; Sundays get Holiday (closed), other days get Working Day (open); each row has `day_type1_id` populated |
| BC-BIZ-03 | Initialize with `clear_existing=true` | Existing WorkingDay rows and linked ClassWorkingDay records force-deleted before re-initialization |
| BC-BIZ-04 | Initialize when no session exists | 422 response: "No current academic session found or session has no start/end dates." |
| BC-BIZ-05 | Initialize when no Working Day type active | 422 response: "No active Working Day type found." |
| BC-BIZ-06 | Initialize when no Holiday type active | 422 response: "No active Holiday day type found." |
| BC-BIZ-07 | Add first day type to empty date | New WorkingDay row created with type in slot 1; `is_school_day` computed from type's `is_working_day` |
| BC-BIZ-08 | Add second compatible type to existing date | Type stacked in slot 2; `is_school_day` recomputed |
| BC-BIZ-09 | Add duplicate type to same date | 422 error: "{name} is already assigned to this date." |
| BC-BIZ-10 | Add 5th type to date with 4 types | 422 error: "This date already has 4 day types (max)." |
| BC-BIZ-11 | Add working type to date with non-working types | 422 error: "Cannot add a working day type — this date is already a holiday." |
| BC-BIZ-12 | Add non-working type to date with working types | 422 error: "Cannot add a holiday — this date already has working day type(s)." |
| BC-BIZ-13 | Add second non-working type to same date | 422 error: "Only one holiday type allowed per date." |
| BC-BIZ-14 | Add day type to date with trashed row | Trashed row restored and reset to single slot with new type |
| BC-BIZ-15 | Drag event to new date (single slot source) | Source slot removed; row deleted if last slot; target date receives type in first free slot |
| BC-BIZ-16 | Drag event to same date | 200 response: "No change." |
| BC-BIZ-17 | Drag event to date with conflicting types | Transaction rolled back; 422 error with mutual exclusion message |
| BC-BIZ-18 | Delete non-last slot | Slot removed; remaining slots compacted upward; `is_school_day` recomputed |
| BC-BIZ-19 | Delete last slot (no linked records) | WorkingDay row force-deleted |
| BC-BIZ-20 | Delete last slot with linked records (no force) | 200 response with `requires_confirm: true`, `linked_count`, `date_label` |
| BC-BIZ-21 | Delete last slot with linked records (force=true) | WorkingDay row and linked ClassWorkingDay records force-deleted |
| BC-BIZ-22 | Update remarks for a date | Remarks saved; 200 response: "Remarks updated." |
| BC-BIZ-23 | Clear all working days | All WorkingDay rows and linked ClassWorkingDay records force-deleted for current session |
| BC-BIZ-24 | eventFeed returns colour-coded events | Each event has `backgroundColor` matching the DAY_TYPE_COLORS constant for its day type |
| BC-BIZ-25 | eventFeed date range filtering | Only events within FullCalendar's `start`/`end` parameters returned |

### 5.10 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `day_type1_id` | `tt_day_types.id` | RESTRICT |
| BC-REF-02 | `day_type2_id` | `tt_day_types.id` | RESTRICT |
| BC-REF-03 | `day_type3_id` | `tt_day_types.id` | RESTRICT |
| BC-REF-04 | `day_type4_id` | `tt_day_types.id` | RESTRICT |

> **Note:** The DDL does not define explicit FK constraints for `academic_session_id`. Cascade behaviour for linked `ClassWorkingDay` records is implemented in controller code.

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Working Days tab | `GET /timetable-foundation/timetable-masters?tab=working-days` returns 200; FullCalendar rendered with month view; Initialize Calendar, Clear All, and day-type dialog UI elements visible | — | — | ⬜ |
| TC-P02 | Initialize calendar for full session | POST to `ajaxInitializeWorkingDays` with session 1 Apr 2026 – 31 Mar 2027; 365 rows created; Sundays get Holiday; other days get Study Day; response `{ status: true, message }` | — | — | ⬜ |
| TC-P03 | Initialize calendar with clear_existing=true | First initialize, then re-initialize with `clear_existing=true`; old rows deleted; new rows created with fresh data | — | — | ⬜ |
| TC-P04 | eventFeed returns events after initialization | GET `eventFeed` with `start`/`end` parameters covering initialized range; events returned for each date with correct ID format `wd-{id}-{slot}`, title, color, and extended props | — | — | ⬜ |
| TC-P05 | Add working day type to empty date | POST `ajaxStore` with `start=2026-04-01`, `day_type_id={StudyDay}`; new WorkingDay row created; `is_school_day=true`; response `{ status: true, message }` | — | — | ⬜ |
| TC-P06 | Add second compatible type to existing date | Date already has Study Day (slot 1); add PTM Day (working, reduced_periods); PTM Day stacked in slot 2; `is_school_day` stays true | — | — | ⬜ |
| TC-P07 | Add day type to date range (3 dates) | POST `ajaxStore` with `start=2026-04-10`, `end=2026-04-13`, `day_type_id={StudyDay}`; 3 dates receive the type (end-1 because end is exclusive); response with applied count = 3 | — | — | ⬜ |
| TC-P08 | Drag event from one date to another | Drag event `wd-{id}-1` from 2026-04-01 to 2026-04-15; source slot removed with compaction; target date receives the type; response `{ status: true, message }` | — | — | ⬜ |
| TC-P09 | Drag event to same date | Drag event to its own date; response `"No change."` (200); no DB modification | — | — | ⬜ |
| TC-P10 | Delete non-last slot | Date has 2 slots (Study Day + PTM Day); delete PTM Day event; slot 2 removed; Study Day remains in slot 1; `is_school_day` stays true | — | — | ⬜ |
| TC-P11 | Delete last slot without linked records | Date has only 1 slot; delete it; row force-deleted; response `{ status: true, message }` | — | — | ⬜ |
| TC-P12 | Delete last slot with linked records (confirmed) | Date has last slot and 3 linked ClassWorkingDay records; first delete returns `requires_confirm: true`; second delete with `force=true` force-deletes row and linked records | — | — | ⬜ |
| TC-P13 | Update remarks for a date | POST `ajaxUpdateRemark` with `remarks=Independence Day holiday`; remarks saved; response `{ status: true, message }`; eventFeed includes `remarks` in extended props | — | — | ⬜ |
| TC-P14 | Clear all working days | POST `ajaxClearWorkingDays`; all rows force-deleted; eventFeed returns no events; cleared count reported in response | — | — | ⬜ |
| TC-P15 | Restore soft-deleted working day | Soft-delete via resource destroy; then restore; record restored with `is_active=true`; reappears in eventFeed | — | — | ⬜ |
| TC-P16 | Force delete from trash | Soft-delete then force-delete; record permanently removed | — | — | ⬜ |
| TC-P17 | Add day type to date with trashed row | Soft-delete a date's row; then add a new type to the same date via `ajaxStore`; trashed row restored; reset to single slot with new type | — | — | ⬜ |
| TC-P18 | Initialize respects closed-day config | Set `default_school_closed_days_per_week=2` (Sat+Sun closed); initialize; Saturdays and Sundays get Holiday type | — | — | ⬜ |
| TC-P19 | Initialize with custom week start | Set `week_start_day=SUNDAY`, `default_school_closed_days_per_week=1`; initialize; Saturdays become closed (computed from formula) | — | — | ⬜ |
| TC-P20 | eventFeed colour coding by day type | Verify event background colours match day-type codes: e.g., STUDY=blue, HOLIDAY=red, EXAM=orange, PTM_DAY=green per `DAY_TYPE_COLORS` constant | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Initialize with no active Holiday type | Deactivate all non-working day types; initialize; 422 error: "No active Holiday day type found." | — | — | ⬜ |
| TC-N02 | Initialize with no active Working Day type | Deactivate all working day types; initialize; 422 error: "No active Working Day type found." | — | — | ⬜ |
| TC-N03 | Initialize with no current session | Delete or deactivate current academic session; initialize; 422 error: "No current academic session found or session has no start/end dates." | — | — | ⬜ |
| TC-N04 | Add duplicate day type to same date | Date has Study Day; add Study Day again; 422 error: "Study Day is already assigned to this date." | — | — | ⬜ |
| TC-N05 | Add 5th type to date with 4 slots full | Fill all 4 slots; add 5th type; 422 error: "This date already has 4 day types (max)." | — | — | ⬜ |
| TC-N06 | Add holiday to date with working types | Date has Study Day; add Holiday; 422 error: "Cannot add a holiday — this date already has working day type(s)." | — | — | ⬜ |
| TC-N07 | Add working type to date with holiday | Date has Holiday; add Study Day; 422 error: "Cannot add a working day type — this date is already a holiday." | — | — | ⬜ |
| TC-N08 | Add second non-working type to date | Date has Holiday; add Exam (also non-working); 422 error: "Only one holiday type allowed per date." | — | — | ⬜ |
| TC-N09 | Drag event to date with conflicting types | Drag Study Day to a date that already has Holiday; transaction rolled back; 422 error | — | — | ⬜ |
| TC-N10 | Delete with invalid event ID format | DELETE to `ajaxDestroy` with id `invalid-format`; 422 error: "Invalid event ID." | — | — | ⬜ |
| TC-N11 | Delete non-existent working day | DELETE to `ajaxDestroy` with id `wd-99999-1`; 404 error: "Working day not found or already deleted." | — | — | ⬜ |
| TC-N12 | Delete already-empty slot | Delete the same slot twice; second attempt returns 422: "That slot is already empty." | — | — | ⬜ |
| TC-N13 | AJAX store with missing required fields | POST `ajaxStore` without `start` or `day_type_id`; validation errors for required fields | — | — | ⬜ |
| TC-N14 | AJAX edit with missing required fields | POST `ajaxEdit` without `id` or `date`; validation errors | — | — | ⬜ |
| TC-N15 | Guest access to tab | Log out; navigate to working-days tab; redirect to `/login` | — | — | ⬜ |
| TC-N16 | Missing viewAny permission on eventFeed | User without `viewAny` calls `eventFeed`; 403 Forbidden | — | — | ⬜ |
| TC-N17 | Missing create permission on ajaxStore | User without `create` calls `ajaxStore`; 403 Forbidden | — | — | ⬜ |
| TC-N18 | Missing update permission on ajaxEdit | User without `update` calls `ajaxEdit`; 403 Forbidden | — | — | ⬜ |
| TC-N19 | Missing delete permission on ajaxDestroy | User without `delete` calls `ajaxDestroy`; 403 Forbidden | — | — | ⬜ |
| TC-N20 | Non-existent day type ID in ajaxStore | POST `ajaxStore` with `day_type_id=9999`; validation error: exists rule fails | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | FK RESTRICT — delete day type assigned to a working day slot | Try to soft-delete or force-delete a Day Type that is used in `day_type1_id` of an active WorkingDay; FK RESTRICT constraint prevents deletion; integrity violation error | — | — | ⬜ |
| TC-D02 | B | Cascade — delete last slot deletes linked ClassWorkingDay records | Date has last slot and 3 linked ClassWorkingDay records; delete with `force=true`; WorkingDay row and all linked ClassWorkingDay records force-deleted in transaction | — | — | ⬜ |
| TC-D03 | B | Cascade — clear all deletes linked ClassWorkingDay records | Run `ajaxClearWorkingDays`; all WorkingDay rows force-deleted; all linked ClassWorkingDay records force-deleted | — | — | ⬜ |
| TC-D04 | C | Activity logging on all state changes | Create, update, trash, restore, force-delete, toggle-status — each creates an activity log entry with appropriate action type and message | — | — | ⬜ |
| TC-D05 | D | Model `$fillable` matches DDL columns | `$fillable` contains: academic_session_id, date, day_type1_id, day_type2_id, day_type3_id, day_type4_id, is_school_day, remarks, is_active | — | — | ⬜ |
| TC-D06 | D | Model `$casts` for boolean/integer/dates | `is_school_day` → boolean, `is_active` → boolean, `date` → date, `academic_session_id` → integer, `day_type*_id` → integer | — | — | ⬜ |
| TC-D07 | E | Unique `date` constraint at DB level | Direct DB insert with duplicate date throws `SQLSTATE[23000]` for `uq_workday_date` | — | — | ⬜ |
| TC-D08 | F | SoftDeletes — WorkingDay model hides deleted records | Soft-deleted WorkingDay rows not returned by eventFeed; appear in trash view | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for mass-assignment protection | All DDL columns present; no extra column | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/dates | `is_school_day` → boolean, `is_active` → boolean, `date` → date; integer casts for FK columns | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `SoftDeletes` imported and used; `deleted_at` in `$casts` | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | `dayType()`, `dayType2()`, `dayType3()`, `dayType4()` belongsTo DayType; `classWorkingDays()` hasMany ClassWorkingDay | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch on all write methods | `ajaxStore`, `ajaxEdit`, `ajaxDestroy`, `ajaxInitializeWorkingDays`, resource CRUD — all have exception handling | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `ajaxEdit` wraps remove+add in DB transaction; `ajaxDestroy` wraps cascade delete; `ajaxInitializeWorkingDays` wraps bulk insert | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Each public method gates with appropriate `timetable-foundation.working-day.*` permission | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | All state-changing methods log via `activityLog()` | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `toggleStatus()` flips `is_active` | Validates boolean, updates, returns JSON | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — trash/restore/forceDelete flow | Trash view uses `onlyTrashed()`, restore uses `onlyTrashed()->findOrFail()`, forceDelete uses `withTrashed()->findOrFail()` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — JSON responses for all AJAX endpoints | All AJAX methods return JSON with `status`, `message`; error responses with appropriate HTTP codes | — | — | ◌ |
| TC-CR12 | CR | P1 | Validation — rules cover all fields | Inline validation in each method covers all required fields with appropriate rules | — | — | ◌ |
| TC-CR13 | CR | P1 | Policy — all 7 CRUD methods defined | `WorkingDayPolicy` defines `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` | — | — | ◌ |
| TC-CR14 | CR | P1 | Routes — resource + custom AJAX routes registered | Resource routes + AJAX routes (store, edit, destroy, initialize, clear, events) registered in web.php | — | — | ◌ |
| TC-CR15 | CR | P1 | View — FullCalendar configuration | FullCalendar initialized with `eventSources` pointing to `eventFeed`; day type dialog renders on date click; drag-and-drop enabled | — | — | ◌ |
| TC-CR16 | CR | P1 | Database — unique `date` index matches validation | DB `uq_workday_date` enforces uniqueness; controller validation does not explicitly check date uniqueness (relies on DB) | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `WorkingDay.php` `$fillable` array | Array contains: `academic_session_id`, `date`, `day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`, `is_school_day`, `remarks`, `is_active` |
| 2 | Cross-reference with `tt_working_days` DDL | All 9 fillable columns exist in DDL; no fillable column absent; no DDL column that should be fillable (excluding id, timestamps, deleted_at) is missing |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `WorkingDay.php` `$casts` array | `is_school_day`→boolean, `is_active`→boolean, `date`→date; integer casts for `academic_session_id`, `day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`; datetime for `created_at`, `updated_at`, `deleted_at` |

#### TC-CR03: Model — SoftDeletes Trait Correctly Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `WorkingDay.php` imports | `use SoftDeletes;` present from `Illuminate\Database\Eloquent\SoftDeletes` |
| 2 | Verify `deleted_at` in `$casts` | `'deleted_at' => 'datetime'` present in `$casts` array |

#### TC-CR04: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `WorkingDay.php` | `dayType()` returns `$this->belongsTo(DayType::class, 'day_type1_id')`; `dayType2()` returns `$this->belongsTo(DayType::class, 'day_type2_id')`; `dayType3()` and `dayType4()` similarly defined |
| 2 | Inspect classWorkingDays relationship | `classWorkingDays()` returns `$this->hasMany(ClassWorkingDay::class, 'working_day_id')` |

#### TC-CR05: Controller — Try-Catch on All Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `WorkingDayController.php` AJAX methods | `ajaxStore()`, `ajaxEdit()`, `ajaxDestroy()`, `ajaxInitializeWorkingDays()`, `ajaxClearWorkingDays()` all wrapped in `try-catch` |
| 2 | Inspect resource CRUD methods | `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `toggleStatus()` each have try-catch handling |

#### TC-CR06: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ajaxEdit()` method | Wraps source-slot removal and target-date assignment in `DB::transaction()` for atomicity |
| 2 | Inspect `ajaxDestroy()` method | Wraps slot removal and cascade ClassWorkingDay deletion in DB transaction |
| 3 | Inspect `ajaxInitializeWorkingDays()` method | Wraps bulk insert loop in DB transaction; rolled back if any insert fails |

#### TC-CR07: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each public method in `WorkingDayController.php` | Every method calls `Gate::authorize()` with appropriate `timetable-foundation.working-day.*` permission: viewAny on index/eventFeed; view on show; create on store/ajaxStore/ajaxInitialize; update on edit/ajaxEdit/toggleStatus; delete on destroy/ajaxDestroy/ajaxClear; restore on restore/trash view; forceDelete on forceDelete |

#### TC-CR08: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect state-changing methods | Each calls `activityLog()` with appropriate action: `'Created'` (store/ajaxStore), `'Updated'` (update/ajaxEdit/ajaxUpdateRemark), `'Trashed'` (destroy), `'Deleted'` (forceDelete/ajaxDestroy/ajaxClear), `'Restored'` (restore), `'Toggled'` (toggleStatus) |

#### TC-CR09: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` method | Validates incoming `is_active` boolean; updates model's `is_active` attribute; returns JSON response |

#### TC-CR10: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect trash view method | Uses `WorkingDay::onlyTrashed()->paginate(10)` to list soft-deleted records |
| 2 | Inspect `restore()` method | Uses `WorkingDay::onlyTrashed()->findOrFail($id)` |
| 3 | Inspect `forceDelete()` method | Uses `WorkingDay::withTrashed()->findOrFail($id)` |

#### TC-CR11: Controller — JSON Responses for AJAX Endpoints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ajaxStore()`, `ajaxEdit()`, `ajaxDestroy()`, `ajaxInitializeWorkingDays()`, `ajaxClearWorkingDays()`, `eventFeed()` methods | All AJAX methods return `response()->json(...)` with `status`, `message` keys; error responses return appropriate HTTP codes (422 for validation, 404 for not found, 403 for forbidden) |

#### TC-CR12: Validation — Rules Cover All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ajaxStore()` validation | `start` required/date; `day_type_id` required/exists:tt_day_types,id; `end` nullable/date |
| 2 | Inspect `ajaxEdit()` validation | `id` required/string; `date` required/date |
| 3 | Inspect resource `store()` validation | `date` required/date; `day_type1_id` required/exists; `is_school_day` required/boolean |
| 4 | Inspect business logic guards | Controller checks for duplicate types (422), max 4 slots (422), working+holiday mutual exclusion (422), second non-working type (422) |

#### TC-CR13: Policy — All 7 CRUD Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `WorkingDayPolicy.php` | Policy defines methods: `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()` — each returning boolean based on authenticated user's permissions |

#### TC-CR14: Routes — Resource + Custom AJAX Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect route definitions for working-day | `Route::resource('working-day', ...)` generates 7 resource routes |
| 2 | Locate AJAX routes | Custom AJAX routes registered: `ajax/events` (GET), `ajax/store` (POST), `ajax/edit` (POST), `ajax/delete/{id}` (DELETE), `ajax/remark/{id}` (POST), `ajax/initialize-calander` (POST), `ajax/clear` (DELETE) |
| 3 | Verify trash/restore/forceDelete routes | Standard resource trash routes + 4 custom routes for toggle-status, trash/view, restore, force-delete |

#### TC-CR15: View — FullCalendar Configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect working-days Blade view | FullCalendar initialized with `eventSources` pointing to `eventFeed` AJAX endpoint |
| 2 | Verify date click handler | Clicking a date opens day-type selection dialog that calls `ajaxStore` |
| 3 | Verify drag-and-drop | Event drop handler calls `ajaxEdit` to move events; drag-and-drop enabled in calendar options |

#### TC-CR16: Database — Unique `date` Index Matches Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect database schema for `tt_working_days` | `uq_workday_date` unique index on `date` column enforces one row per date at DB level |
| 2 | Cross-reference with validation | Controller does not explicitly check date uniqueness in validation (relies on DB unique constraint); duplicate date insert throws `SQLSTATE[23000]` integrity constraint violation

---

### 7.1 Positive TC Steps

#### TC-P01: Load Working Days Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as admin with full permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/timetable-masters?tab=working-days` | HTTP 200; page title "Timetable Masters" visible; Working Days tab pane active |
| 3 | Verify FullCalendar rendered | Calendar grid visible showing current month; navigation (prev/next/today) buttons present |
| 4 | Verify toolbar elements | Initialize Calendar button, Clear All button present |
| 5 | Verify no events initially | Calendar cells empty (no coloured events) until eventFeed loads |

#### TC-P02: Initialize Calendar for Full Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure active session exists with start=2026-04-01, end=2027-03-31 | — |
| 2 | Ensure Study Day (working) and Holiday (non-working) day types are active | — |
| 3 | Click "Initialize Calendar" button | POST to `ajaxInitializeWorkingDays` |
| 4 | Verify response | `{ status: true, message: "Initialized 365 days (2026-04-01 to 2027-03-31). School-closed days set as Holiday, rest as Working Day." }` |
| 5 | Navigate calendar to April 2026 | Sundays (5, 12, 19, 26 April) show Holiday event (red); other days show Study Day event (blue) |
| 6 | Query DB for a Sunday date | `day_type1_id` = Holiday type ID; `is_school_day = 0` |
| 7 | Query DB for a Monday date | `day_type1_id` = Study Day type ID; `is_school_day = 1` |

#### TC-P03: Initialize with clear_existing=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize calendar (365 rows created) | — |
| 2 | Re-initialize with "Clear existing" checkbox checked | POST with `clear_existing=1` |
| 3 | Verify old rows deleted | Force-deleted; no existing WorkingDay rows in DB for previous session date range |
| 4 | Verify new rows created | Fresh 365 rows created |

#### TC-P04: eventFeed Returns Events After Initialization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize calendar | — |
| 2 | Navigate FullCalendar to April 2026 | Browser network tab shows GET request to `eventFeed` with `start`/`end` parameters |
| 3 | Inspect response JSON | Array of event objects; each has: `id` (format `wd-{n}-1`), `title` (day type name), `start` (date), `backgroundColor` (hex colour), `extendedProps` containing `day_type_id`, `slot`, `working_day_id`, `is_school_day`, `date`, `remarks` |
| 4 | Count events for April 2026 | 30 events (one per day); each day has exactly 1 event (slot 1) |

#### TC-P05: Add Working Day Type to Empty Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure date 2026-04-15 has no WorkingDay row (clear if needed) | — |
| 2 | Click 2026-04-15 on calendar | Day type selection dialog opens |
| 3 | Select "Study Day" and confirm | POST `ajaxStore` with `start=2026-04-15`, `day_type_id={StudyDayId}` |
| 4 | Verify response | `{ status: true, message: "Saved 1 day(s)." }` |
| 5 | Verify event appears on calendar | 2026-04-15 shows Study Day event (blue) |
| 6 | Query DB | New WorkingDay row; `day_type1_id` = StudyDay ID; `is_school_day = 1` |

#### TC-P06: Add Second Compatible Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-15 has Study Day in slot 1 | — |
| 2 | Click 2026-04-15, select "PTM Day" | POST `ajaxStore` |
| 3 | Verify response | Saved successfully |
| 4 | Verify 2 events on same date | Two stacked events: Study Day + PTM Day |
| 5 | Query DB | `day_type1_id` = StudyDay, `day_type2_id` = PTMDay; `is_school_day = 1` |

#### TC-P07: Add Day Type to Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear existing working days for April 2026 | — |
| 2 | Click and drag across 2026-04-10 to 2026-04-12 (3 dates) or use range dialog | POST `ajaxStore` with `start=2026-04-10`, `end=2026-04-13`, `day_type_id={StudyDayId}` |
| 3 | Verify response | `{ status: true, message: "Saved 3 day(s).", applied: [3 dates], skipped: [] }` |
| 4 | Verify 3 rows created | DB has 3 rows for 10, 11, 12 April |

#### TC-P08: Drag Event to New Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-01 has Study Day (slot 1) | — |
| 2 | Ensure 2026-04-20 is empty (no row) | — |
| 3 | Drag the Study Day event from 2026-04-01 to 2026-04-20 | POST `ajaxEdit` with event ID and target date |
| 4 | Verify response | `{ status: true, message: "Day type moved successfully." }` |
| 5 | Verify source date | 2026-04-01 has no events (row deleted if last slot); or if still exists, slot removed with compaction |
| 6 | Verify target date | 2026-04-20 shows Study Day event |

#### TC-P09: Drag Event to Same Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Drag an event to its own date | POST `ajaxEdit` |
| 2 | Verify response | `"No change."` (200) |
| 3 | Verify no DB change | Source and target dates unchanged |

#### TC-P10: Delete Non-Last Slot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-15 has 2 slots: Study Day and PTM Day | — |
| 2 | Click delete on the PTM Day event | DELETE `ajaxDestroy` with event ID `wd-{id}-2` |
| 3 | Verify response | `{ status: true, message: "Day type removed." }` |
| 4 | Verify only Study Day remains | Single event on 2026-04-15; `day_type2_id` = null; row not deleted |

#### TC-P11: Delete Last Slot Without Linked Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-20 has 1 slot (Study Day) and no linked ClassWorkingDay records | — |
| 2 | Click delete on the Study Day event | DELETE `ajaxDestroy` |
| 3 | Verify response | `{ status: true, message: "Day type removed." }` |
| 4 | Verify row deleted | WorkingDay row force-deleted from DB |

#### TC-P12: Delete Last Slot with Linked Records (Confirmed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-10 has 1 slot and 3 linked ClassWorkingDay records | — |
| 2 | Click delete on the single event | DELETE `ajaxDestroy` without `force` flag |
| 3 | Verify confirmation response | `{ status: false, requires_confirm: true, linked_count: 3, date_label: "10 Apr 2026", message: "3 class working day record(s) are linked to 10 Apr 2026. Removing the last day type will also remove those records." }` |
| 4 | Confirm deletion (set force=true) | Second DELETE with `force=true` |
| 5 | Verify row and linked records deleted | WorkingDay row force-deleted; linked ClassWorkingDay records force-deleted |

#### TC-P13: Update Remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click 2026-04-15 and select "Edit Remarks" | Dialog with current remarks (empty) |
| 2 | Enter "Independence Day holiday" and confirm | POST `ajaxUpdateRemark` with `remarks=Independence Day holiday` |
| 3 | Verify response | `{ status: true, message: "Remarks updated." }` |
| 4 | Verify DB | `remarks` column = "Independence Day holiday" |

#### TC-P14: Clear All Working Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize calendar (ensure rows exist) | — |
| 2 | Click "Clear All" button | DELETE `ajaxClearWorkingDays` |
| 3 | Verify response | `{ status: true, message: "..." }` with cleared count |
| 4 | Verify calendar empty | No events visible; eventFeed returns empty array |
| 5 | Query DB | No WorkingDay rows for current session |

#### TC-P15: Restore Soft-Deleted Working Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a WorkingDay row via resource destroy | — |
| 2 | Navigate to trash view: `GET /working-day/trash/view` | Record listed with restore option |
| 3 | Click Restore | Record restored; `is_active=1` |
| 4 | Navigate back to calendar | Record's event visible again |

#### TC-P16: Force Delete from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a WorkingDay row | — |
| 2 | Navigate to trash view | Record listed |
| 3 | Click Force Delete | Record permanently removed |
| 4 | Verify record absent | Not in main table; not in trash |

#### TC-P17: Add Day Type to Date with Trashed Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure date 2026-04-25 has a soft-deleted WorkingDay row | — |
| 2 | Click 2026-04-25, select "Study Day" | POST `ajaxStore` |
| 3 | Verify trashed row restored | `deleted_at` set to null; row reset to single slot with new type |
| 4 | Verify event appears | Calendar shows Study Day on 2026-04-25 |

#### TC-P18: Initialize with 2 Closed Days (Sat+Sun)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `default_school_closed_days_per_week=2` in `tt_configs` | — |
| 2 | Clear existing and initialize | — |
| 3 | Verify Saturdays and Sundays closed | Both get Holiday type; `is_school_day=0` for Sat and Sun |
| 4 | Restore config to 1 | Clean up |

#### TC-P19: Initialize with Custom Week Start

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `week_start_day=SUNDAY`, `default_school_closed_days_per_week=1` in `tt_configs` | — |
| 2 | Clear existing and initialize | — |
| 3 | Verify Saturdays closed | Saturday (ISO 6) is closed based on formula: `closedIsoDays[1] = ((7-1-1+7)%7)+1 = 6` |
| 4 | Restore config defaults | Clean up |

#### TC-P20: eventFeed Colour Coding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize calendar with multiple day types (Study Day, Holiday, Exam, PTM Day) | — |
| 2 | Inspect eventFeed response for each event | `backgroundColor` matches the DAY_TYPE_COLORS constant mapping: e.g., STUDY → #..., HOLIDAY → #..., EXAM → #..., PTM_DAY → #... |

---

### 7.2 Negative TC Steps

#### TC-N01: Initialize With No Active Holiday Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Deactivate or delete all day types where `is_working_day = 0` | — |
| 2 | Click "Initialize Calendar" | POST to `ajaxInitializeWorkingDays` |
| 3 | Verify response | 422 JSON: `{ status: false, message: "No active Holiday day type found." }` |
| 4 | Verify no rows created | DB has no new WorkingDay rows |
| 5 | Reactivate a Holiday type | Clean up |

#### TC-N02: Initialize With No Active Working Day Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Deactivate all day types where `is_working_day = 1` | — |
| 2 | Click "Initialize Calendar" | 422: `"No active Working Day type found."` |
| 3 | Reactivate a Working Day type | Clean up |

#### TC-N03: Initialize With No Current Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set current session's `is_current = 0` or delete it | — |
| 2 | Click "Initialize Calendar" | 422: `"No current academic session found or session has no start/end dates."` |
| 3 | Restore session | Clean up |

#### TC-N04: Add Duplicate Day Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-10 has Study Day in slot 1 | — |
| 2 | Click 2026-04-10, select "Study Day" again | POST `ajaxStore` |
| 3 | Verify 422 error | `"Study Day is already assigned to this date."` |

#### TC-N05: Add 5th Type to Date With 4 Slots Full

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill date 2026-05-01 with 4 different day types | — |
| 2 | Click date, select any other type | POST `ajaxStore` |
| 3 | Verify 422 error | `"This date already has 4 day types (max)."` |

#### TC-N06: Add Holiday to Date With Working Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-10 has Study Day | — |
| 2 | Click 2026-04-10, select "Holiday" | POST `ajaxStore` |
| 3 | Verify 422 error | `"Cannot add a holiday — this date already has working day type(s)."` |

#### TC-N07: Add Working Type to Date With Holiday

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-20 has Holiday only | — |
| 2 | Click 2026-04-20, select "Study Day" | POST `ajaxStore` |
| 3 | Verify 422 error | `"Cannot add a working day type — this date is already a holiday."` |

#### TC-N08: Add Second Non-Working Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2026-04-25 has Holiday (non-working) in slot 1 | — |
| 2 | Click 2026-04-25, select "Exam" (also non-working) | POST `ajaxStore` |
| 3 | Verify 422 error | `"Only one holiday type allowed per date."` |

#### TC-N09: Drag Event to Conflicting Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure source date (2026-04-01) has Study Day | — |
| 2 | Ensure target date (2026-04-20) has Holiday | — |
| 3 | Drag Study Day from 2026-04-01 to 2026-04-20 | POST `ajaxEdit` |
| 4 | Verify 422 error | Mutual exclusion error; transaction rolled back |
| 5 | Verify source date unchanged | Study Day still on 2026-04-01 |

#### TC-N10 through TC-N20 — Negative AJAX and Permission Tests

*(Each follows the same pattern: perform the action, verify the expected HTTP status and error message as described in the test case table.)*

##### TC-N10: Delete With Invalid Event ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE to `ajaxDestroy` with id `invalid-id` | 422: `"Invalid event ID."` |

##### TC-N11: Delete Non-Existent Working Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE to `ajaxDestroy` with id `wd-99999-1` | 404: `"Working day not found or already deleted."` |

##### TC-N12: Delete Already-Empty Slot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a slot twice | First delete succeeds; second delete returns 422: `"That slot is already empty."` |

##### TC-N13: AJAX Store Missing Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` without `start` and `day_type_id` | Validation errors: "The start field is required.", "The day type id field is required." |

##### TC-N14: AJAX Edit Missing Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxEdit` without `id` and `date` | Validation errors for required fields |

##### TC-N15: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to working-days tab | Redirected to `/login` |

##### TC-N16: Missing viewAny on eventFeed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `viewAny` | — |
| 2 | Call GET `eventFeed` | 403 Forbidden |

##### TC-N17: Missing create on ajaxStore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `create` permission | — |
| 2 | POST `ajaxStore` | 403 Forbidden |

##### TC-N18: Missing update on ajaxEdit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `update` permission | — |
| 2 | POST `ajaxEdit` | 403 Forbidden |

##### TC-N19: Missing delete on ajaxDestroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `delete` permission | — |
| 2 | DELETE `ajaxDestroy` | 403 Forbidden |

##### TC-N20: Non-Existent Day Type ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajaxStore` with `day_type_id=9999` | Validation error: "The selected day type id is invalid." |

---

### 7.3 Dependency TC Steps

#### TC-D01: FK RESTRICT — Delete Day Type Used in Working Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a Day Type that is used as `day_type1_id` in at least one WorkingDay row | — |
| 2 | Attempt to delete this Day Type via the UI | DB throws integrity constraint violation; deletion blocked by FK RESTRICT |

#### TC-D02: Cascade — Delete Last Slot Deletes Linked ClassWorkingDay Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ClassWorkingDay records linked to a specific WorkingDay | — |
| 2 | Delete the last slot on that WorkingDay with `force=true` | WorkingDay row force-deleted; all linked ClassWorkingDay records force-deleted |
| 3 | Query DB | Both WorkingDay and ClassWorkingDay records gone |

#### TC-D03: Cascade — Clear All Deletes Linked ClassWorkingDay Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create WorkingDay rows with linked ClassWorkingDay records | — |
| 2 | Run `ajaxClearWorkingDays` | All WorkingDay and ClassWorkingDay records force-deleted |

#### TC-D04: Activity Logging

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a WorkingDay via resource store (or AJAX) | Activity log: 'Working Day was created.' |
| 2 | Update remarks | Activity log: 'Working Day was updated.' |
| 3 | Soft-delete a WorkingDay | Activity log: 'Working Day was trashed.' |
| 4 | Restore from trash | Activity log: 'Working Day was restored.' |
| 5 | Force delete from trash | Activity log: 'Working Day was permanently deleted.' |
| 6 | Toggle status | Activity log: 'Working Day status was toggled.' |

#### TC-D05: Model — `$fillable` Matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `WorkingDay.php` `$fillable` array | Contains: `academic_session_id`, `date`, `day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`, `is_school_day`, `remarks`, `is_active` |

#### TC-D06: Model — `$casts` for Boolean/Integer/Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `WorkingDay.php` `$casts` array | `is_school_day` → `boolean`, `is_active` → `boolean`, `date` → `date`, `academic_session_id` → `integer`, `day_type1_id` → `integer`, etc. |

#### TC-D07: Unique Date Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate date: `INSERT INTO tt_working_days (date, day_type1_id) VALUES ('2026-04-01', 1)` twice | Second insert throws `SQLSTATE[23000]: Integrity constraint violation` for `uq_workday_date` |

#### TC-D08: SoftDeletes Hides Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a WorkingDay row | — |
| 2 | Navigate calendar to the date range | Deleted date shows no event (not returned by eventFeed) |
| 3 | Query DB with `withTrashed()` | Row found with `deleted_at` populated |

---
