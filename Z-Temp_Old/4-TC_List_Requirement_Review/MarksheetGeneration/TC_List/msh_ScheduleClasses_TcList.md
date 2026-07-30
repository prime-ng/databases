# Schedule Classes — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Schedule Class (`msh_schedule_classes`) |
| **Controller** | `ScheduleClassController` — 11 methods (index, create, store, show, edit, update, destroy, trashed, restore, forceDelete) |
| **Model** | `ScheduleClass` — SoftDeletes, 2 relationships |
| **Form Request** | `ScheduleClassRequest` |
| **Service Layer** | `ScheduleClassService` |
| **Tab Container** | `MarksheetGenerationController@scheduling()` — tab id `schedule-classes` |
| **Permission** | `tenant.msh-schedule-class` — actions: viewAny, view, create, update, delete |
| **Routes** | `schedule-class.*` (resource) + trashed, restore, forceDelete |
| **Hub Route** | `marksheet-generation.scheduling.combined?tab=schedule-classes` |
| **DB Table** | `msh_schedule_classes` — 5 fillable columns + timestamps |
| **Pagination** | 15 per page — page name `schedule_class_page` |
| **Junction Role** | Links `msh_marksheet_schedules` to `sch_class_sections` (many-to-many via this table vs pivot) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User logged in with `tenant.msh-schedule-class.*` permissions |
| PC-02 | `msh_schedule_classes` table exists with all columns |
| PC-03 | `msh_marksheet_schedules` has records to reference |
| PC-04 | `sch_class_sections` has records to reference |
| PC-05 | `ScheduleClassService` injectable |
| PC-06 | Soft deletes enabled on `msh_schedule_classes` |
| PC-07 | Activity log system operational |
| PC-08 | `permissionslist.php` has `msh-schedule-class` entry |
| PC-09 | Differentiating from pivot: ScheduleClass is a first-class model, not a pivot |
| PC-10 | Each schedule can have multiple schedule classes (1:N) vs classSections (N:N via pivot) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | index() redirects to hub schedules tab | `Controller:index()` — redirects to scheduling.combined?tab=schedule-classes |
| DL-02 | Hub scheduling page loads schedule classes with eager loads | Hub controller via MarksheetGenerationController@scheduling() |
| DL-03 | Eager loads: schedule (marksheetSchedule), classSection | Both relations loaded |
| DL-04 | Search/filter bar with tab hidden input | Tab partial blade |
| DL-05 | Action column with standard actions | edit/delete wrapped in @can |
| DL-06 | Pagination with `?tab=schedule-classes&schedule_class_page=N` | Blade appends tab param |
| DL-07 | Empty state: "No records found" | @empty block |
| DL-08 | Create form loads: schedules list, class sections list | Controller:create() |
| DL-09 | Edit form loads same dropdowns + record data | Controller:edit() |
| DL-10 | Show page displays schedule + class section names | Controller:show() |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Schedule Class** | schedule_id=1 (existing), class_section_id=5 (existing) |
| TD-02 | **Invalid Schedule ID** | schedule_id=99999 — exists failure |
| TD-03 | **Invalid Class Section ID** | class_section_id=99999 — exists failure |
| TD-04 | **Duplicate mapping** | Same schedule_id + class_section_id combination — unique violation |
| TD-05 | **Trashed schedule class** | Soft-deleted record for trash/restore tests |
| TD-06 | **FK constraint on force delete** | Schedule class referenced by other tables (if any) |
| TD-07 | **Schedule with multiple classes** | One schedule mapped to multiple class sections |

---

## 5. Business Conditions Matrix

### BC-DB: Database Conditions

| BC ID | Type | Category | Description |
|-------|------|----------|-------------|
| BC-DB-01 | DB | Structure | Table `msh_schedule_classes` has 5 fillable columns + timestamps |
| BC-DB-02 | DB | Structure | `schedule_id` — FK to `msh_marksheet_schedules.id` |
| BC-DB-03 | DB | Structure | `class_section_id` — FK to `sch_class_sections.id` |
| BC-DB-04 | DB | Structure | Composite unique on (schedule_id, class_section_id) |
| BC-DB-05 | DB | Soft Delete | `deleted_at` column — use SoftDeletes trait |
| BC-DB-06 | DB | FK | `schedule_id` → `msh_marksheet_schedules.id` ON DELETE CASCADE? |
| BC-DB-07 | DB | FK | `class_section_id` → `sch_class_sections.id` |
| BC-DB-08 | DB | FK | Possibly `created_by` / `updated_by` audit columns |

### BC-VAL: Validation Conditions

| BC ID | Type | Category | Description |
|-------|------|----------|-------------|
| BC-VAL-01 | VAL | Required | `schedule_id` is required on create |
| BC-VAL-02 | VAL | Exists | `schedule_id` must exist in `msh_marksheet_schedules` |
| BC-VAL-03 | VAL | Required | `class_section_id` is required on create |
| BC-VAL-04 | VAL | Exists | `class_section_id` must exist in `sch_class_sections` |
| BC-VAL-05 | VAL | Unique | Composite unique on (schedule_id, class_section_id) |
| BC-VAL-06 | VAL | Integer | Both FK fields must be integers |
| BC-VAL-07 | VAL | Sometimes | Update uses `sometimes` rules |

### BC-AUTH: Authorization Conditions

| BC ID | Type | Gate String | Controller Method |
|-------|------|-------------|-------------------|
| BC-AUTH-01 | AUTH | `tenant.msh-schedule-class.viewAny` | index() |
| BC-AUTH-02 | AUTH | `tenant.msh-schedule-class.create` | create(), store() |
| BC-AUTH-03 | AUTH | `tenant.msh-schedule-class.view` | show() |
| BC-AUTH-04 | AUTH | `tenant.msh-schedule-class.update` | edit(), update(), restore() |
| BC-AUTH-05 | AUTH | `tenant.msh-schedule-class.delete` | destroy(), forceDelete() |

### BC-BIZ: Business Conditions

| BC ID | Type | Description |
|-------|------|-------------|
| BC-BIZ-01 | BIZ | A schedule must exist before creating schedule class mapping |
| BC-BIZ-02 | BIZ | A class section must exist before creating mapping |
| BC-BIZ-03 | BIZ | Same mapping cannot be created twice (composite unique) |
| BC-BIZ-04 | BIZ | Deleting a schedule may cascade-delete its schedule classes |
| BC-BIZ-05 | BIZ | ScheduleClass is a first-class model (not just pivot) — has its own lifecycle |
| BC-BIZ-06 | BIZ | No toggle status — no is_active column likely (junction semantics) |
| BC-BIZ-07 | BIZ | No state machine — pure CRUD |
| BC-BIZ-08 | BIZ | FK 23000 error on force delete if referenced elsewhere |

### BC-REL: Relationship Map

| Relation | Type | Related Model | FK on ScheduleClass |
|----------|------|---------------|---------------------|
| schedule | BelongsTo | MarksheetSchedule | schedule_id |
| classSection | BelongsTo | ClassSection | class_section_id |

### BC-BIZ-DEEP: Detailed Analysis

| Aspect | Analysis |
|--------|----------|
| **Purpose** | ScheduleClass is a mapping/junction model that associates a marksheet schedule with a specific class section. This enables per-class-section marksheet generation. |
| **1:N vs N:N** | Schedule has both `classSections` (BelongsToMany via pivot `schedule_class_sections`) AND `scheduleClassSections` (HasMany to ScheduleClass model). ScheduleClass is the first-class model version of the pivot. |
| **Lifecycle** | Pure CRUD — no state machine. ScheduleClass records are created when a schedule needs to be scoped to specific class sections. |
| **Soft Delete** | Supports soft delete to allow recovery of accidentally removed mappings. |
| **Audit** | activityLog called on store, update, destroy, restore, forceDelete. |
| **No toggle** | Unlike SubjectPracticalConfig, ScheduleClass does NOT have an `is_active` column or toggleStatus() method. |

### CODE-TRACE: ScheduleClassController — Complete Method Analysis

| Method | File:Line | Gate | Input | Key Logic | Response |
|--------|-----------|------|-------|-----------|----------|
| index() | Controller:~15-25 | `viewAny` | Request (search/status) | `ScheduleClass::with(['schedule','classSection'])->latest()->paginate(15)` | view with compact |
| create() | Controller:~27-31 | `create` | — | Load schedules + class sections for dropdown | view with data |
| store() | Controller:~33-55 | `create` | ScheduleClassRequest | `$this->service->create($request->validated())` + activityLog | redirect with flash |
| show() | Controller:~57-62 | `view` | $id | `ScheduleClass::with(['schedule','classSection'])->findOrFail($id)` | view with record |
| edit() | Controller:~64-72 | `update` | $id | `findOrFail($id)` + load dropdowns | view |
| update() | Controller:~74-92 | `update` | ScheduleClassRequest, $id | `$this->service->update($request->validated(), $id)` + activityLog | redirect with flash |
| destroy() | Controller:~94-108 | `delete` | $id | `$this->service->trash($id)` + activityLog | redirect with flash |
| trashed() | Controller:~110-116 | `viewAny` | — | `ScheduleClass::onlyTrashed()->with(...)->paginate(15)` | view |
| restore() | Controller:~118-128 | `update` | $id | `$this->service->restoreRecord($id)` + activityLog | redirect with flash |
| forceDelete() | Controller:~130-145 | `delete` | $id | `$this->service->forceDeleteRecord($id)` + activityLog | redirect |

## 6. Test Case List

### 6.1 Positive Test Cases (TC-P)

| ID | Test Case | Summary | Pre-condition | Steps | Expected Result |
|----|-----------|---------|---------------|-------|-----------------|
| TC-P-01 | Create schedule-class mapping | Link schedule to class section | User has create, schedule+section exist | store() via form | Record created, redirect, activityLog 'Stored' |
| TC-P-02 | View mapping details | Access show() | Record exists, user has view | show() via route | Record + relations rendered |
| TC-P-03 | Edit mapping | Access edit() | Record exists, user has update | edit() via route | Form with record data + dropdowns |
| TC-P-04 | Update mapping | Change class_section_id | Record exists, user has update | update() via PUT | Updated record, activityLog |
| TC-P-05 | Soft-delete mapping | Delete a mapping | Record exists, user has delete | destroy() via DELETE | Soft deleted, redirect |
| TC-P-06 | List trashed mappings | Access trashed() | At least one trashed record | trashed() via route | Trashed records listed |
| TC-P-07 | Restore mapping | Restore from trash | Record trashed, user has update | restore() via GET | Restored, activityLog |
| TC-P-08 | Force delete mapping | Permanent delete | Record trashed, no FK refs | forceDelete() via DELETE | Permanently removed |
| TC-P-09 | Create mapping with same schedule multiple classes | Link schedule 1 → class 5 AND schedule 1 → class 6 | Both unique per schedule+section | store() twice | Two records for same schedule |
| TC-P-10 | View mapping with eager-loaded relations | Check schedule name + class section name | Record exists | show() | Both relation names displayed |

### 6.2 Negative Test Cases (TC-N)

| ID | Test Case | Summary | Steps | Expected Result |
|----|-----------|---------|-------|-----------------|
| TC-N-01 | Create — missing schedule_id | Submit without schedule | Validation: required |
| TC-N-02 | Create — invalid schedule_id | Use non-existent schedule | Validation: exists |
| TC-N-03 | Create — missing class_section_id | Submit without class section | Validation: required |
| TC-N-04 | Create — invalid class_section_id | Use non-existent class section | Validation: exists |
| TC-N-05 | Create — duplicate mapping | Same schedule_id + class_section_id | Validation: unique composite |
| TC-N-06 | Store — 403 missing create | No create permission | 403 Forbidden |
| TC-N-07 | Show — 403 missing view | No view permission | 403 Forbidden |
| TC-N-08 | Update — 403 missing update | No update permission | 403 Forbidden |
| TC-N-09 | Delete — 403 missing delete | No delete permission | 403 Forbidden |
| TC-N-10 | Restore — 403 missing update | No update permission | 403 Forbidden |
| TC-N-11 | Force delete — 403 missing delete | No delete permission | 403 Forbidden |
| TC-N-12 | Force delete — FK 23000 | Referenced by other records | User-friendly error |
| TC-N-13 | Show — non-existent ID | $id=99999 | 404 or ModelNotFoundException |
| TC-N-14 | Update — non-existent ID | $id=99999 | 404 |
| TC-N-15 | Destroy — non-existent ID | $id=99999 | 404 |
| TC-N-16 | Restore — not trashed | Active record accessed via onlyTrashed | 404 |
| TC-N-17 | Force delete — not trashed | Active record | 404 |

### 6.3 Security Test Cases (TC-SQ)

| ID | Test Case | Summary | Steps | Expected Result |
|----|-----------|---------|-------|-----------------|
| TC-SQ-01 | No viewAny → index redirect | User without viewAny accesses hub | 403 |
| TC-SQ-02 | No create → store | User without create submits store | 403 |
| TC-SQ-03 | No view → show | User without view accesses show | 403 |
| TC-SQ-04 | No update → edit/update/restore | User without update | 403 |
| TC-SQ-05 | No delete → destroy/forceDelete | User without delete | 403 |
| TC-SQ-06 | SQL injection in class_section_id | Send malicious integer | Parameterized query |
| TC-SQ-07 | XSS in schedule_id (display) | Attempt script injection | Blade escaping |

### 6.4 Integration Test Cases (TC-INT)

| ID | Test Case | Summary | Steps | Expected Result |
|----|-----------|---------|-------|-----------------|
| TC-INT-01 | Hub tab loads schedule classes | Navigate to scheduling.combined?tab=schedule-classes | Tab active, table loaded |
| TC-INT-02 | Pagination isolation | Navigate to schedule_class_page=3, switch tabs | Resets on tab switch |
| TC-INT-03 | Schedule name via relation | Verify schedule name column loads | Relation eager loaded |
| TC-INT-04 | Class section name via relation | Verify class section name column loads | Relation eager loaded |
| TC-INT-05 | Trash tab isolation | Verify trashed records only show in trashed view | Separate |
| TC-INT-06 | Schedule deletion cascade | Delete schedule → check schedule class records | Cascade behavior tested |
| TC-INT-07 | Activity log entries | Create, update, delete, restore, forceDelete | Each logged |

### 6.5 Code Review Test Cases (TC-CR)

| ID | Test Case | Source Line | Expected |
|----|-----------|-------------|----------|
| TC-CR-01 | Gate in index() | Controller:index | `tenant.msh-schedule-class.viewAny` |
| TC-CR-02 | Gate in create() | Controller:create | `tenant.msh-schedule-class.create` |
| TC-CR-03 | Gate in store() | Controller:store | `tenant.msh-schedule-class.create` |
| TC-CR-04 | Gate in show() | Controller:show | `tenant.msh-schedule-class.view` |
| TC-CR-05 | Gate in edit() | Controller:edit | `tenant.msh-schedule-class.update` |
| TC-CR-06 | Gate in update() | Controller:update | `tenant.msh-schedule-class.update` |
| TC-CR-07 | Gate in destroy() | Controller:destroy | `tenant.msh-schedule-class.delete` |
| TC-CR-08 | Gate in trashed() | Controller:trashed | `tenant.msh-schedule-class.viewAny` |
| TC-CR-09 | Gate in restore() | Controller:restore | `tenant.msh-schedule-class.update` (not restore) |
| TC-CR-10 | Gate in forceDelete() | Controller:forceDelete | `tenant.msh-schedule-class.delete` (not forceDelete) |
| TC-CR-11 | activityLog in store() | Controller:store | Type='Stored', message contains 'created' |
| TC-CR-12 | activityLog in update() | Controller:update | Type='Updated', message contains 'updated' |
| TC-CR-13 | activityLog in destroy() | Controller:destroy | Type='Deleted', message contains 'trashed' |
| TC-CR-14 | activityLog in restore() | Controller:restore | Type='Restored' |
| TC-CR-15 | activityLog in forceDelete() | Controller:forceDelete | Type='forceDeleted' |
| TC-CR-16 | Service::create() used in store | Controller:store | ScheduleClassService used |
| TC-CR-17 | Service::update() used in update | Controller:update | ScheduleClassService used |
| TC-CR-18 | Service::trash() used in destroy | Controller:destroy | ScheduleClassService used |
| TC-CR-19 | Service::restoreRecord() used in restore | Controller:restore | ScheduleClassService used |
| TC-CR-20 | Service::forceDeleteRecord() in forceDelete | Controller:forceDelete | ScheduleClassService used |
| TC-CR-21 | Eager load in index | Controller:index | `->with(['schedule','classSection'])` |
| TC-CR-22 | Eager load in show | Controller:show | `->with(['schedule','classSection'])` |
| TC-CR-23 | Pagination count in index | Controller:index | `->paginate(15)` |
| TC-CR-24 | Paginator name | Tab partial | `schedule_class_page` |
| TC-CR-25 | No toggleStatus() method | Controller | No toggleStatus — correct per schema |
| TC-CR-26 | Composite unique in Request | FormRequest | `unique:msh_schedule_classes,...->where(...)` |
| TC-CR-27 | prepareForValidation in Request | FormRequest | Casts to int if needed |
| TC-CR-28 | SoftDeletes trait on Model | Model | `use SoftDeletes` |
| TC-CR-29 | $fillable model property | Model | All 5 fillable columns |
| TC-CR-30 | BelongsTo relationships on Model | Model | schedule(), classSection() |

## 7. Detailed Test Steps

### TC-P-01: Create schedule-class mapping (Complete Steps)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-schedule-class.create` permission | Authenticated |
| 2 | Navigate to `marksheet-generation.scheduling.combined?tab=schedule-classes` | Schedule Classes tab visible |
| 3 | Click "Add Schedule Class" button | Create form displayed |
| 4 | Select **schedule_id** = 1 (existing marksheet schedule) | Dropdown populated |
| 5 | Select **class_section_id** = 5 (existing class section) | Dropdown populated |
| 6 | Click Save | POST to store() |
| 7 | Verify Gate at store() passes | `authorize('tenant.msh-schedule-class.create')` |
| 8 | Verify `$request->validated()` passes all rules | Validation OK |
| 9 | Verify Service::create() called with validated data | Record created |
| 10 | Verify DB: `msh_schedule_classes` has new record | schedule_id=1, class_section_id=5 |
| 11 | Verify activityLog type='Stored' | "Schedule class mapping created." |
| 12 | Verify redirect to `scheduling.combined?tab=schedule-classes` | Redirect OK |
| 13 | Verify flash('created.schedule_class') displayed | Success message |

### TC-P-02: View mapping details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with view permission | 200 OK |
| 2 | GET route `schedule-class.show(1)` | 200 |
| 3 | Verify Gate at show() passes | Authorized |
| 4 | Verify findOrFail(1) returns record | Found |
| 5 | Verify with(['schedule','classSection']) eager loads | Relations loaded |
| 6 | Verify schedule name displayed via relation | "Term 1 Marksheet 2026" |
| 7 | Verify class section name displayed via relation | "Section A" |
| 8 | Verify view rendered with compact('record') | Show page |

### TC-P-03: Edit mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | 200 OK |
| 2 | GET edit(1) | 200 |
| 3 | Verify Gate passes | Authorized |
| 4 | Verify findOrFail(1) | Record found |
| 5 | Verify dropdowns loaded: schedules, classSections | Form ready |
| 6 | Verify form pre-populated with existing values | old() + $record |

### TC-P-04: Update mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `schedule-class.update(1)` with new class_section_id=6 | Update |
| 2 | Verify Gate passes | Authorized |
| 3 | Verify Service::update() called | Service invoked |
| 4 | Verify DB class_section_id changed from 5 to 6 | Updated |
| 5 | Verify activityLog 'Updated' with changes tracked | Logged |
| 6 | Verify redirect with flash('updated.schedule_class') | Success |

### TC-P-05: Soft-delete mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record exists in DB | Precondition |
| 2 | DELETE `schedule-class.destroy(1)` | Request |
| 3 | Verify Gate passes | Authorized |
| 4 | Verify Service::trash(1) called | Service invoked |
| 5 | Verify DB deleted_at NOT NULL | Soft deleted |
| 6 | Verify activityLog 'Deleted' | "Schedule class mapping trashed." |
| 7 | Verify redirect with flash('trashed.schedule_class') | Success |

### TC-P-06: List trashed mappings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | At least one record already soft-deleted | Precondition |
| 2 | GET `schedule-class.trashed` | 200 |
| 3 | Verify Gate passes | Authorized |
| 4 | Verify onlyTrashed() scope applied | Only trashed shown |
| 5 | Verify trashed records listed in table | Listed |
| 6 | Verify each trashed record has Restore + Force Delete actions | Action buttons |

### TC-P-07: Restore mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record in trash (deleted_at not null) | Precondition |
| 2 | GET restore(1) | Request |
| 3 | Verify Gate passes | Authorized |
| 4 | Verify Service::restoreRecord(1) called | Service invoked |
| 5 | Verify DB deleted_at = NULL | Restored |
| 6 | Verify activityLog 'Restored' recorded | "Schedule class mapping restored." |
| 7 | Verify redirect with flash | Success |

### TC-P-08: Force delete mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record in trash, no FK references | Precondition |
| 2 | DELETE forceDelete(1) | Request |
| 3 | Verify Gate passes | Authorized |
| 4 | Verify Service::forceDeleteRecord(1) called | Service invoked |
| 5 | Verify DB record completely removed | Gone |
| 6 | Verify activityLog 'forceDeleted' | "Schedule class mapping permanently deleted." |
| 7 | Verify redirect | Success |

### TC-P-09: Multiple class sections for one schedule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping: schedule_id=1, class_section_id=5 | Success |
| 2 | Create mapping: schedule_id=1, class_section_id=6 | Success |
| 3 | Create mapping: schedule_id=1, class_section_id=7 | Success |
| 4 | Verify 3 records exist for schedule_id=1 | Multiple mappings |
| 5 | Verify each unique composite is distinct | No duplicates |

### TC-P-10: Relations displayed in view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record with schedule_id=1, class_section_id=5 exists | Precondition |
| 2 | View show or index page | Rendered |
| 3 | Verify schedule name column shows correct name | Relation loaded |
| 4 | Verify class section name column shows correct name | Relation loaded |
| 5 | Verify no N+1 queries (both eager loaded) | Single query |

### TC-N-01: Missing schedule_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill class_section_id but leave schedule_id empty | |
| 2 | Submit store() | Validation fails |
| 3 | Error: "The schedule id field is required." | Required rule |
| 4 | No DB record created | |

### TC-N-02: Invalid schedule_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set schedule_id=99999 (non-existent) | |
| 2 | Submit store() | Validation fails |
| 3 | Error: "The selected schedule id is invalid." | Exists rule |
| 4 | No DB record created | |

### TC-N-03: Missing class_section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill schedule_id but leave class_section_id empty | |
| 2 | Submit store() | Validation fails |
| 3 | Error: "The class section id field is required." | Required rule |
| 4 | No DB record created | |

### TC-N-04: Invalid class_section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_section_id=99999 (non-existent) | |
| 2 | Submit store() | Validation fails |
| 3 | Error: "The selected class section id is invalid." | Exists rule |
| 4 | No DB record created | |

### TC-N-05: Duplicate mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping: schedule_id=1, class_section_id=5 | Success |
| 2 | Same mapping: schedule_id=1, class_section_id=5 again | Duplicate |
| 3 | Submit store() | Error: "The class section id has already been taken." |
| 4 | No duplicate record created | Unique maintained |

### TC-N-06 through TC-N-11: Each tests 403 Forbidden for missing permission.

### TC-N-12: Force delete — FK 23000

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure schedule class has references in other tables (marksheets, etc.) | FK exists |
| 2 | Soft-delete the record | Trashed |
| 3 | Attempt forceDelete() | Request |
| 4 | QueryException with code 23000 | FK constraint |
| 5 | Catch block handles 23000 | User-friendly error message |
| 6 | Redirect back with error | Error displayed |
| 7 | Record NOT permanently deleted | Still in trash |

### TC-N-13 through TC-N-17: Each tests 404 for non-existent ID across show, update, destroy, restore, forceDelete.

### TC-SQ-01 through TC-SQ-05: 403 Forbidden tests for each GATE permission.

### TC-SQ-06: SQL injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit class_section_id as string "1; DROP TABLE msh_schedule_classes;--" | |
| 2 | Validation expects integer | Validation fails as non-integer string |
| 3 | No injection possible | Parameterized + type validation |

### TC-SQ-07: XSS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | schedule_id is FK — displayed via relation name | |
| 2 | Any schedule name with XSS attempt | Escaped via Blade {{ }} |

### TC-INT-01: Hub tab loads schedule classes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to scheduling.combined?tab=schedule-classes | Tab active |
| 2 | Verify schedule classes table visible | Data rendered |
| 3 | Verify schedule name shown via eager load | Relation loaded |
| 4 | Verify class section name shown via eager load | Relation loaded |

### TC-INT-02: Pagination isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with ?tab=schedule-classes&schedule_class_page=3 | Page 3 |
| 2 | Switch to another tab | Tab changes |
| 3 | Switch back to schedule-classes | Page 1 |

### TC-INT-03: Schedule name via relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index page renders schedule classes | |
| 2 | Column "Schedule" shows schedule->name | Relation loaded |
| 3 | Verify no N+1 — single DB query for all schedules | Performance OK |

### TC-INT-04: Class section name via relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index page renders | |
| 2 | Column "Class Section" shows classSection->name | Relation loaded |
| 3 | No N+1 queries | Performance OK |

### TC-INT-05: Trash tab isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a record | Trashed |
| 2 | Index page (active records) | Does NOT show trashed |
| 3 | Trashed page | Shows trashed record |

### TC-INT-06: Schedule deletion cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a marksheet schedule that has schedule class mappings | |
| 2 | Check whether cascade delete removes schedule_classes | Depends on FK constraint |
| 3 | If ON DELETE CASCADE: schedule classes deleted | Cascade confirmed |
| 4 | If ON DELETE RESTRICT: schedule cannot be deleted | Blocked |

### TC-INT-07: Activity log entries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create → activityLog('Stored') | Entry 1 |
| 2 | Update → activityLog('Updated') | Entry 2 |
| 3 | Soft-delete → activityLog('Deleted') | Entry 3 |
| 4 | Restore → activityLog('Restored') | Entry 4 |
| 5 | Force delete → activityLog('forceDeleted') | Entry 5 |

## 8. Observations & Gaps

| # | Observation | Severity | Details |
|---|-------------|----------|---------|
| OBS-01 | No toggleStatus() method | Low | Expected — Schedule Class is a junction mapping, not an activatable entity |
| OBS-02 | restore() uses update permission instead of restore | Low | Gate::authorize('...update') rather than dedicated '...restore' |
| OBS-03 | forceDelete() uses delete permission instead of forceDelete | Low | Gate::authorize('...delete') rather than dedicated '...forceDelete' |
| OBS-04 | No standalone index — redirects to hub | Info | index() redirects like other MSH controllers |
| OBS-05 | No performed_by in activityLog calls | Low | Missing user attribution in audit trail for all mutation methods |
| OBS-06 | No search/filter in index() query | Low | index() may not have search/status filters |
| OBS-07 | Duplicate model concept | Info | ScheduleClass (first-class model) vs schedule_class_sections (pivot) — potential confusion |
| OBS-08 | BelongsTo only (not HasMany) | Info | No inverse relationship on MarksheetSchedule or ClassSection |

## 9. Test Environment Requirements

| # | Requirement | Details |
|---|-------------|---------|
| TE-01 | Laravel PHP Framework | Version 10.x+ with Gate authorization |
| TE-02 | Database | MySQL 8.0+ with InnoDB engine |
| TE-03 | Permissions config | `config/permissionslist.php` with `msh-schedule-class` entry |
| TE-04 | Reference data | MarksheetSchedules and ClassSections must exist |
| TE-05 | Activity log table | `activity_log` table must be operational |
| TE-06 | Soft deletes | `deleted_at` column on `msh_schedule_classes` |
| TE-07 | Route registration | All routes in `routes/web.php` |
| TE-08 | Service class | `ScheduleClassService` injectable |

## 10. Route Registration

| Route Name | Method | Controller Action | Permission Required |
|------------|--------|-------------------|---------------------|
| schedule-class.index | GET | index() (redirect to hub) | viewAny |
| schedule-class.create | GET | create() | create |
| schedule-class.store | POST | store() | create |
| schedule-class.show | GET | show() | view |
| schedule-class.edit | GET | edit() | update |
| schedule-class.update | PUT/PATCH | update() | update |
| schedule-class.destroy | DELETE | destroy() | delete |
| schedule-class.trashed | GET | trashed() | viewAny |
| schedule-class.restore | GET | restore() | update |
| schedule-class.forceDelete | DELETE | forceDelete() | delete |

## 11. Permissions Reference

From `config/permissionslist.php` — group name: `msh-schedule-class`

| Permission Key | Used In | Purpose |
|----------------|---------|---------|
| `tenant.msh-schedule-class.viewAny` | index(), trashed() | Listing access |
| `tenant.msh-schedule-class.view` | show() | View details |
| `tenant.msh-schedule-class.create` | create(), store() | Create new |
| `tenant.msh-schedule-class.update` | edit(), update(), restore() | Edit, update, restore |
| `tenant.msh-schedule-class.delete` | destroy(), forceDelete() | Soft-delete, force delete |

## 12. Form Request Validation Details

### ScheduleClassRequest Validation Rules

| Field | Create Rule | Update Rule | Message Override |
|-------|-------------|-------------|------------------|
| schedule_id | required, integer, exists:msh_marksheet_schedules,id | sometimes, integer, exists:msh_marksheet_schedules,id | — |
| class_section_id | required, integer, exists:sch_class_sections,id | sometimes, integer, exists:sch_class_sections,id | — |

### Unique Composite Validation

The composite unique constraint on (schedule_id, class_section_id) is enforced:



### prepareForValidation() Logic



## 13. Service Layer CODE-TRACE

### ScheduleClassService — Complete Method Trace



## 14. Model Configuration

### ScheduleClass Model — Complete

| Property | Value | Source |
|----------|-------|--------|
| Table | `msh_schedule_classes` | Model table property |
| Primary Key | `id` (auto-increment) | Default |
| Fillable | 5 fields: schedule_id, class_section_id, is_active, created_by, updated_by | Model $fillable |
| Casts | `is_active` → boolean | Model $casts |
| Soft Delete | `use SoftDeletes` trait | Model |
| Timestamps | `created_at`, `updated_at`, `deleted_at` | SoftDeletes |
| Created By | `created_by` → User | Model createdBy() |
| Updated By | `updated_by` → User | Model updatedBy() |

### Relationships



## 15. Junction vs Pivot Analysis

| Aspect | ScheduleClass (First-Class Model) | schedule_class_sections (Pivot) |
|--------|----------------------------------|----------------------------------|
| Table | `msh_schedule_classes` | `schedule_class_sections` |
| Model | Yes — ScheduleClass | No — implicit pivot |
| Soft Delete | Yes | No |
| Own Created/Updated By | Yes | No |
| Own ID | Yes — auto-increment | Composite PK |
| Lifecycle | Full CRUD | Insert/delete only |
| Activity Log | Yes — each mutation logged | No |
| Service Layer | ScheduleClassService | Implicit via sync() |
| Permission | `tenant.msh-schedule-class.*` | Uses schedule's permissions |
| Use Case | Direct mapping management | Quick schedule-class assignment |
| Custom Attributes | Can have is_active, custom data | Limited |

## 16. Test Coverage Summary

| Category | Count | Details |
|----------|-------|---------|
| TC-P (Positive) | 10 | CRUD + soft delete cycle + relations |
| TC-N (Negative) | 17 | Validation, 403, 404, FK constraint |
| TC-SQ (Security) | 7 | Permission + injection tests |
| TC-INT (Integration) | 7 | Hub tab, pagination, cascade, activity log |
| TC-CR (Code Review) | 30 | Gate + activityLog + service verification |
| **Total** | **71** | Full feature coverage |

## 17. Test Execution Notes

| # | Note | Details |
|---|------|---------|
| TN-01 | Sequential trash/restore | TC-P-06 (trash) must run before TC-P-07 (restore) |
| TN-02 | FK cascade dependency | TC-INT-06 requires knowing DB FK constraint type |
| TN-03 | Composite unique | TC-N-05 requires first record created before duplicate attempt |
| TN-04 | Different permission per action | Each Gate test needs specific user setup |
| TN-05 | ActivityLog verification | Every TC-P should assert activityLog was called with correct type+message |
| TN-06 | 404 for not-trashed | TC-N-16/17 require non-trashed record for onlyTrashed() scope |

## 18. Key Differences from SubjectPracticalConfig

| Feature | SubjectPracticalConfig | ScheduleClass |
|---------|----------------------|---------------|
| toggleStatus() | ✅ Yes (JSON AJAX) | ❌ No |
| State Machine | ❌ No | ❌ No |
| has_practical | ✅ Yes | N/A |
| theory/practical marks | ✅ Yes (decimal:2) | N/A |
| Composite unique | 3 fields (session+class+subject) | 2 fields (schedule+class_section) |
| Eager loads | 3 relations | 2 relations |
| Service Layer | Mixed (direct + service) | Full service |
| Hub paginator | practical_config_page | schedule_class_page |
| List filters | search + status | None |

## 19. Quick Reference — Key File Locations

| Artifact | Path |
|----------|------|
| Controller | `Modules/MarksheetGeneration/Http/Controllers/ScheduleClassController.php` |
| Model | `Modules/MarksheetGeneration/Models/ScheduleClass.php` |
| Form Request | `Modules/MarksheetGeneration/Http/Requests/ScheduleClassRequest.php` |
| Service | `Modules/MarksheetGeneration/Services/ScheduleClassService.php` |
| Routes | `Modules/MarksheetGeneration/routes/web.php` |
| Permissions | `config/permissionslist.php` |
| Migration | `database/migrations/*_create_msh_schedule_classes_table.php` |

## 20. Complete Test Case Index

| TC ID | Type | Priority | Dependencies | Covered By |
|-------|------|----------|--------------|------------|
| TC-P-01 | Positive | High | None | Create, Gate, Validation, Service, DB, activityLog |
| TC-P-02 | Positive | Medium | TC-P-01 | Show, Relations |
| TC-P-03 | Positive | Medium | TC-P-01 | Edit form |
| TC-P-04 | Positive | High | TC-P-01 | Update, Gate, Service, DB |
| TC-P-05 | Positive | High | TC-P-01 | Delete, Gate, Service, DB |
| TC-P-06 | Positive | Medium | TC-P-05 | Trash listing |
| TC-P-07 | Positive | High | TC-P-05 | Restore, Gate, activityLog |
| TC-P-08 | Positive | High | TC-P-05, no FK | Force delete, Gate |
| TC-P-09 | Positive | Medium | None | Multiple mappings per schedule |
| TC-P-10 | Positive | Low | TC-P-01 | Relation display |
| TC-N-01 | Negative | High | None | Required validation |
| TC-N-02 | Negative | High | None | Exists validation |
| TC-N-03 | Negative | High | None | Required validation |
| TC-N-04 | Negative | High | None | Exists validation |
| TC-N-05 | Negative | High | TC-P-01 | Unique composite |
| TC-N-06 | Negative | High | None | 403 Gate |
| TC-N-07 | Negative | High | None | 403 Gate |
| TC-N-08 | Negative | High | None | 403 Gate |
| TC-N-09 | Negative | High | None | 403 Gate |
| TC-N-10 | Negative | Medium | None | 403 Gate |
| TC-N-11 | Negative | Medium | None | 403 Gate |
| TC-N-12 | Negative | Medium | TC-P-05, FK | FK 23000 catch |
| TC-N-13 | Negative | Medium | None | 404 |
| TC-N-14 | Negative | Medium | None | 404 |
| TC-N-15 | Negative | Medium | None | 404 |
| TC-N-16 | Negative | Low | None | onlyTrashed 404 |
| TC-N-17 | Negative | Low | None | onlyTrashed 404 |
| TC-SQ-01 | Security | High | None | Permission boundary |
| TC-SQ-02 | Security | High | None | Permission boundary |
| TC-SQ-03 | Security | High | None | Permission boundary |
| TC-SQ-04 | Security | High | None | Permission boundary |
| TC-SQ-05 | Security | High | None | Permission boundary |
| TC-SQ-06 | Security | Medium | None | SQL injection |
| TC-SQ-07 | Security | Medium | TC-P-01 | XSS |
| TC-INT-01 | Integration | High | TC-P-01 | Hub tab |
| TC-INT-02 | Integration | Medium | None | Pagination isolation |
| TC-INT-03 | Integration | Medium | TC-P-01 | Relation display |
| TC-INT-04 | Integration | Medium | TC-P-01 | Relation display |
| TC-INT-05 | Integration | Medium | TC-P-05 | Trash isolation |
| TC-INT-06 | Integration | Medium | None | Cascade behavior |
| TC-INT-07 | Integration | Low | All TC-P | Activity log sequence |

## 21. Code Pattern Comparison — All Three MSH Controllers

| Aspect | SubjectPracticalConfig | MarksheetSchedule | ScheduleClass |
|--------|----------------------|-------------------|---------------|
| Total Methods | 11 | 14 | 10 |
| toggleStatus() | ✅ | ❌ | ❌ |
| Lifecycle Methods | 0 | 6 (review, publish, lock, unlock, precheck, compute) | 0 |
| Export | ❌ | ✅ (Excel .xlsx) | ❌ |
| Service Layer | Mixed (store=direct, update/destroy=service) | Full service | Full service |
| AJAX JSON Responses | ✅ (store, update, destroy, toggleStatus) | ❌ (all redirect) | ❌ (all redirect) |
| Async Job | ❌ | ✅ (ComputeMarksheetJob) | ❌ |
| Form Requests | 1 | 2 (main + unlock) | 1 |
| State Machine | None | DRAFT→COMPUTED→REVIEWED→PUBLISHED→LOCKED | None |
| State Machine Exceptions | N/A | DomainException in LifecycleService | N/A |
| FK 23000 Catch | ✅ (forceDelete) | ✅ (forceDelete) | ✅ (forceDelete) |
| Unique Composite | session+class+subject | code+academic_session | schedule+class_section |
| Relationships | 5 | 10 | 2 |
| Fillable Columns | 9 | 18 | 5 |
| Hub Paginator | practical_config_page | sch_page | schedule_class_page |
| Eager Loads | 3 | 1 | 2 |
| Gate: restore() | update permission | update permission | update permission |
| Gate: forceDelete() | delete permission | delete permission | delete permission |
| Missing performed_by | ✅ All activityLog | ✅ All activityLog | ✅ All activityLog |
| Hardcoded flash messages | Some | Some | Some |

## 22. Permission Key Consistency Check

| Route/Controller | Actual Permission String Used | Expected (per permissionslist.php) | Match? |
|------------------|------------------------------|------------------------------------|--------|
| ScheduleClass index | `tenant.msh-schedule-class.viewAny` | `tenant.msh-schedule-class.viewAny` | ✅ |
| ScheduleClass create | `tenant.msh-schedule-class.create` | `tenant.msh-schedule-class.create` | ✅ |
| ScheduleClass store | `tenant.msh-schedule-class.create` | `tenant.msh-schedule-class.create` | ✅ |
| ScheduleClass show | `tenant.msh-schedule-class.view` | `tenant.msh-schedule-class.view` | ✅ |
| ScheduleClass edit | `tenant.msh-schedule-class.update` | `tenant.msh-schedule-class.update` | ✅ |
| ScheduleClass update | `tenant.msh-schedule-class.update` | `tenant.msh-schedule-class.update` | ✅ |
| ScheduleClass destroy | `tenant.msh-schedule-class.delete` | `tenant.msh-schedule-class.delete` | ✅ |
| ScheduleClass trashed | `tenant.msh-schedule-class.viewAny` | `tenant.msh-schedule-class.viewAny` | ✅ |
| ScheduleClass restore | `tenant.msh-schedule-class.update` | `tenant.msh-schedule-class.restore` | ⚠️ Mismatch |
| ScheduleClass forceDelete | `tenant.msh-schedule-class.delete` | `tenant.msh-schedule-class.forceDelete` | ⚠️ Mismatch |

### Issues Found

1. **restore()** uses `update` permission instead of dedicated `restore` permission
2. **forceDelete()** uses `delete` permission instead of dedicated `forceDelete` permission
3. These are consistent across ALL THREE controllers in the MSH module — suggesting intentional design or a systematic gap

### Recommendation

If the Vendor module pattern (gold standard) uses dedicated `restore` and `forceDelete` permissions, these controllers should be updated to match:
- `ScheduleClassController@restore`: `Gate::authorize('tenant.msh-schedule-class.restore')`
- `ScheduleClassController@forceDelete`: `Gate::authorize('tenant.msh-schedule-class.forceDelete')`

## 23. Data Flow Diagram — ScheduleClass within Hub

```
User Request → Hub MarksheetGenerationController@scheduling()
    ↓
Gate::any([viewAny for ALL tabs])
    ↓
Load schedules (marksheetSchedulesQuery)   → marksheetSchedules
Load configs (subjectPracticalConfigsQuery) → configs
Load scheduleClasses (scheduleClassesQuery) → scheduleClasses  ←── HERE
    ↓
Hub view: scheduling.tab
    ↓
x-backend.tab.nav-tab
    ├── @can('tenant.msh-schedule-class.viewAny')
    │   └── @include('marksheetgeneration::schedule-class.index')
    │       └── ScheduleClasses table rendered
    └── ...
```

### scheduleClassesQuery (private query helper)



## 24. Test Data Setup Script (Pseudo-code)



## 25. Migration Reference



### TC-P-20: Create schedule class mapping with class_section name visible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create modal with schedule_id=1, class_section drop-down | All class sections listed |
| 2 | Select "Section A" from dropdown | Value = class_section_id |
| 3 | Submit | POST |
| 4 | **Verify**: Index table shows "Section A" from relation | `$record->classSection->name` |

### TC-P-21: Update mapping to different class_section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit for mapping with class_section_id=1 | Current section shown |
| 2 | Change to class_section_id=2 | Different section |
| 3 | Submit update | PUT |
| 4 | **Verify**: Mapping now points to section 2 | Updated |
| 5 | **Verify**: activityLog records change | Audit log |

### TC-P-22: Verify redirect back (not to index) after create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create schedule class mapping | Store executed |
| 2 | **Verify**: `redirect()->back()` used | Returns to hub tab |
| 3 | **Verify**: `->with('success', flash(...))` | Success message flashed |

### TC-N-13: Create duplicate (schedule_id + class_section_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping with schedule_id=1, class_section_id=1 | First insert succeeds |
| 2 | Create another with same schedule_id=1, class_section_id=1 | Duplicate |
| 3 | **Verify**: `unique` composite validation | "The combination has already been taken." |

### TC-N-14: Create with invalid schedule_id FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST schedule_id=99999 | Non-existent schedule |
| 2 | **Verify**: `exists:msh_marksheet_schedules,id` validation | "The selected schedule is invalid." |

### TC-N-15: Create with invalid class_section_id FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST class_section_id=99999 | Non-existent class section |
| 2 | **Verify**: `exists:sch_class_sections,id` validation | FK validation error |

### TC-N-16: Mass assignment of non-fillable is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST is_active=0 with valid data | Non-fillable attempt |
| 2 | **Verify**: is_active NOT in `$fillable` | Default true remains |

### TC-N-17: DELETE on mapping with schedule soft-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete parent schedule | Parent in trash |
| 2 | Attempt destroy on schedule class mapping | Delete succeeds |
| 3 | **Verify**: Child can still be removed (no FK block) | Cascade on delete |

### TC-D-11: Cascade delete — delete parent schedule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete marksheet schedule that has 3 mappings | CASCADE |
| 2 | **Verify**: All 3 child mappings auto-deleted (cascadeOnDelete) | No orphan rows |
| 3 | **Verify**: Only schedule_id FK has cascade — class_section_id has RESTRICT | Different constraint types |

### TC-D-12: Concurrent edit of same mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A and User B open edit for same mapping | Same data loaded |
| 2 | User A updates class_section_id to 2 | Write A |
| 3 | User B updates class_section_id to 3 | Write B overwrites |
| 4 | **Verify**: Last-write-wins (no optimistic locking) | User B's value persists |

### TC-CR-30: Verify `ScheduleClassRequest` has `unique` composite rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ScheduleClassRequest.php` | `'schedule_id' => 'required|integer|exists:msh_marksheet_schedules,id'` |
| 2 | **Verify**: `class_section_id` rules | `'required|integer|exists:sch_class_sections,id'` |
| 3 | **Verify**: Composite unique rule | `Rule::unique('msh_schedule_classes')->where(fn ($q) => $q->where('schedule_id', $this->schedule_id))->ignore($id)` |

### BC-BIZ-DEEP-55: ScheduleClasses is a JUNCTION entity (not primary resource)

| # | Condition | Expected Behavior |
|---|-----------|------------------|
| BC-BIZ-DEEP-55 | Links `msh_marksheet_schedules` to `sch_class_sections` via msh_schedule_classes | Pivot/mapping table with extra columns |
| BC-BIZ-DEEP-56 | `cascadeOnDelete()` on schedule_id FK — parent deletion removes children | No orphan mappings |
| BC-BIZ-DEEP-57 | `restrictOnDelete()` on class_section_id FK — prevents deletion of in-use section | FK protection |
| BC-BIZ-DEEP-58 | `destroy()` does NOT set is_active=false first | Only `$record->delete()` |
| BC-BIZ-DEEP-59 | `forceDelete()` catch block handles 23000 with user-friendly flash | Non-23000 re-thrown |
| BC-BIZ-DEEP-60 | Flash key `flash('created.schedule-class')` must exist in lang file | Verify in flash.php |
| BC-BIZ-DEEP-61 | `toggleStatus()` returns `is_active` only — no `updated_by` in JSON | Only is_active returned |

### CODE-TRACE-HUB: `scheduleClassesQuery()` — MarksheetGenerationController Private Method

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | ~250 | `private function scheduleClassesQuery(Request $request): Builder` | Private query helper for scheduling hub tab |
| 02 | ~251 | `$query = ScheduleClass::with(['schedule', 'classSection'])` | Eager load both FKs |
| 03 | ~253 | `if ($request->input('tab') === 'scheduling')` | Only apply filters when tab active |
| 04 | ~254 | `->when($request->filled('schedule_id'), fn ($q) => $q->where('schedule_id', (int) $request->schedule_id))` | Filter by schedule |
| 05 | ~256 | `return $query->latest()` | Always order by latest |
| 06 | Hub | `paginate(15, ['*'], 'schedule_classes_page')` | Unique paginator for this tab |
