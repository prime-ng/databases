# hrs_HolidayCalendar_TcList

## Module: HrStaff → HR Masters → Holiday Calendar

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | HR Masters |
| Feature | Holiday Calendar |
| URL(s) | `GET /hr-masters?tab=holidays` (tab view), `GET /holidays` (index), `POST /holidays` (store), `GET /holidays/{holiday}` (show), `GET /holidays/{holiday}/edit` (edit), `PUT /holidays/{holiday}` (update), `DELETE /holidays/{holiday}` (destroy), `POST /holidays/{holiday}/toggle-status` (toggleStatus), `GET /holidays/trash/view` (trashed), `GET /holidays/{id}/restore` (restore), `DELETE /holidays/{id}/force-delete` (forceDelete) |
| Controller | `Modules\HrStaff\Http\Controllers\HolidayController` |
| Model(s) | `Modules\HrStaff\Models\HolidayCalendar` (table: `hrs_holiday_calendars`) |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StoreHolidayRequest` |
| Policy | `Modules\HrStaff\Policies\HolidayCalendarPolicy` |
| Permissions | `hrs.holiday.manage` (policy); controller uses `hrs.leave_type.manage` |
| Pagination | 30 records per page (`HolidayController@index`); tab view returns full collection |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` sets `is_active=false` before `delete()`; restore sets `is_active=true` |
| Activity Log | Events: Created, Updated, Trashed, Restored, Deleted (force delete) |
| Data Source | Holidays are linked to academic years from `OrganizationAcademicSession` |

---

## 2. Pre-conditions

- Required permissions: `hrs.holiday.manage` (or `hrs.leave_type.manage` per controller)
- Required seed data: At least one active academic session in `sch_org_academic_sessions_jnt` with `is_current=true`
- Test user must have required permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For pagination tests: Create 35 holiday records

---

## 3. Default Data Load

When the page loads via `HrMenuController@hrMasters()` (`GET /hr-masters` with `tab=holidays`), or `HolidayController@index()` (`GET /holidays`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Holidays Grid (tab) | `HrMenuController@hrMasters()` | `HolidayCalendar::with('academicYear')->orderBy('holiday_date', 'desc')` | search (holiday_name), type (holiday_type) | None (full collection) |
| Holidays Grid (standalone) | `HolidayController@index()` | `HolidayCalendar::active()->where('academic_year_id', currentSession->id)->orderBy('holiday_date')` | search (holiday_name), type (holiday_type) | 30/page |
| Academic Years (shared) | `HolidayController@index()`/`edit()` | `OrganizationAcademicSession::orderByDesc('start_date')` | None | None |

> **Data Source:** The `academic_year_id` FK references `sch_org_academic_sessions_jnt.id` (SchoolSetup module).

---

## 4. Test Data Strategy

- **Academic year**: Use the current academic session (`is_current=true`) for all tests
- **Date range**: Use past and future dates for test holidays; ensure dates do not conflict
- **Holiday types**: Test each type (national, state, school, optional)
- **Pre-test cleanup**: Delete created holidays by name before/after tests
- **Pagination**: Create 35 records to test 30-record boundary

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_holiday_calendars`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | academic_year_id | SMALLINT UNSIGNED FK | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` |
| BC-DB-03 | holiday_date | DATE | NOT NULL |
| BC-DB-04 | holiday_name | VARCHAR(150) | NOT NULL |
| BC-DB-05 | holiday_type | ENUM('national','state','school','optional') | NOT NULL |
| BC-DB-06 | applicable_to | ENUM('all','teaching','non_teaching') | NOT NULL DEFAULT 'all' |
| BC-DB-07 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-08 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-09 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-10 | created_at | TIMESTAMP | NULL |
| BC-DB-11 | updated_at | TIMESTAMP | NULL |
| BC-DB-12 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Validation Rules — `StoreHolidayRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | academic_year_id | required, exists:sch_org_academic_sessions_jnt,id | — |
| BC-VAL-02 | holiday_date | required, date | — |
| BC-VAL-03 | holiday_name | required, string, max:150 | — |
| BC-VAL-04 | holiday_type | required, in:national,state,school,optional | — |
| BC-VAL-05 | applicable_to | required, in:all,teaching,non_teaching | — |
| BC-VAL-06 | is_active | required, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.holiday.manage` / `hrs.leave_type.manage` | All controller methods require gate; without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with `tab=holidays` | Holidays list displayed in HR Masters tabbed view |
| BC-BIZ-02 | Standalone index page scoped to current session | Only holidays for `is_current=true` academic year shown |
| BC-BIZ-03 | Search by holiday_name | Grid filtered to matching name |
| BC-BIZ-04 | Filter by holiday_type | Grid filtered to selected type |
| BC-BIZ-05 | Create holiday with `is_active` default=true | `is_active`=1 |
| BC-BIZ-06 | Empty grid | Shows empty state message |
| BC-BIZ-07 | Toggle status active→inactive | AJAX toggles `is_active` |
| BC-BIZ-08 | Screen loads via HolidayController@index() at GET /holidays | Standalone paginated view; tab via GET /hr-masters?tab=holidays |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_year_id | sch_org_academic_sessions_jnt (id) | RESTRICT (no CASCADE specified) |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Holiday Calendar page loads with all UI elements | Page loads with search, type filter, Add button, grid | — | — | ⬜ |
| TC-P02 | Search holidays by name | Grid filtered to matching name | — | — | ⬜ |
| TC-P03 | Filter by holiday_type=national | Grid shows only national holidays | — | — | ⬜ |
| TC-P04 | Filter by holiday_type=state | Grid shows only state holidays | — | — | ⬜ |
| TC-P05 | Filter by holiday_type=school | Grid shows only school holidays | — | — | ⬜ |
| TC-P06 | Filter by holiday_type=optional | Grid shows only optional holidays | — | — | ⬜ |
| TC-P07 | Create holiday with all required fields | Holiday created with correct values | — | — | ⬜ |
| TC-P08 | Create holiday with type=national | Holiday_type set to national | — | — | ⬜ |
| TC-P09 | Create holiday with type=optional | Holiday_type set to optional | — | — | ⬜ |
| TC-P10 | Create holiday with applicable_to=teaching | Holiday applicable to teaching staff only | — | — | ⬜ |
| TC-P11 | Create holiday with applicable_to=non_teaching | Holiday applicable to non-teaching only | — | — | ⬜ |
| TC-P12 | Edit holiday loads pre-filled data | Edit form shows existing values | — | — | ⬜ |
| TC-P13 | Update holiday name and date | Name and date updated | — | — | ⬜ |
| TC-P14 | Update holiday type from school to optional | Type changed | — | — | ⬜ |
| TC-P15 | View holiday details | Show page renders all fields | — | — | ⬜ |
| TC-P16 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P17 | Soft delete holiday | Holiday moved to trash | — | — | ⬜ |
| TC-P18 | View trashed holidays | Trash page lists soft-deleted records | — | — | ⬜ |
| TC-P19 | Restore trashed holiday | Holiday restored with is_active=1 | — | — | ⬜ |
| TC-P20 | Force delete holiday from trash | Permanently removed | — | — | ⬜ |
| TC-P21 | Full lifecycle: create→edit→toggle→delete→trash→restore | All transitions succeed | — | — | ⬜ |
| TC-P22 | Pagination — first page shows 30 records | Page 1 shows up to 30 records | — | — | ⬜ |
| TC-P23 | Pagination — second page shows remaining | Page 2 shows records 31+ | — | — | ⬜ |
| TC-P24 | Standalone index scopes to current academic session | Only current year holidays shown | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `academic_year_id` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `holiday_date` | Validation error: "The holiday date field is required." | — | — | ⬜ |
| TC-N03 | Required — missing `holiday_name` | Validation error: "The holiday name field is required." | — | — | ⬜ |
| TC-N04 | Required — missing `holiday_type` | Validation error | — | — | ⬜ |
| TC-N05 | Invalid holiday_type value | Validation error on holiday_type.in | — | — | ⬜ |
| TC-N06 | Invalid applicable_to value | Validation error on applicable_to.in | — | — | ⬜ |
| TC-N07 | Invalid academic_year_id (non-existent) | "The selected academic year id is invalid." | — | — | ⬜ |
| TC-N08 | Max length — name > 150 chars | Validation error on name.max | — | — | ⬜ |
| TC-N09 | Invalid date format for holiday_date | Validation error on date | — | — | ⬜ |
| TC-N10 | View non-existent holiday (404) | 404 Not Found | — | — | ⬜ |
| TC-N11 | Edit non-existent holiday (404) | 404 Not Found | — | — | ⬜ |
| TC-N12 | Delete non-existent holiday (404) | 404 Not Found | — | — | ⬜ |
| TC-N13 | Permission denied — user without gate | 403 Forbidden | — | — | ⬜ |
| TC-N14 | Guest access | Redirected to /login | — | — | ⬜ |
| TC-N15 | Whitespace-only name | Required validation catches empty | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft delete sets is_active=false | is_active set to false before delete() | — | — | ⬜ |
| TC-D02 | A | Restore sets is_active=true | is_active set to true after restore() | — | — | ⬜ |
| TC-D03 | B | Activity logged on create | activityLog called with 'Created' | — | — | ⬜ |
| TC-D04 | B | Activity logged on update | activityLog called with 'Updated' | — | — | ⬜ |
| TC-D05 | B | Activity logged on delete | activityLog called with 'Trashed' | — | — | ⬜ |
| TC-D06 | C | Model $casts — holiday_date as date | holiday_date cast to date instance | — | — | ⬜ |
| TC-D07 | C | Model $casts — is_active as boolean | is_active stored as TINYINT, accessed as bool | — | — | ⬜ |
| TC-D08 | D | Model relationship — academicYear() BelongsTo | `$holiday->academicYear` returns OrganizationAcademicSession | — | — | ⬜ |
| TC-D09 | E | Controller — findOrFail — 404 on invalid ID | edit/update/show/destroy with invalid ID returns 404 | — | — | ⬜ |
| TC-D10 | F | Controller — Gate::authorize() on every method | All 10 methods gate before execution | — | — | ⬜ |
| TC-D11 | G | FK constraint — academic_year_id | Cannot insert holiday with non-existent academic year ID | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — $fillable matches DDL columns | $fillable includes all non-PK, non-timestamp columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts for booleans/dates | holiday_date as date, is_active as boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait implemented | SoftDeletes imported; deleted_at column present | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | academicYear() BelongsTo defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Gate::authorize() on every method | All 10 methods gate before execution | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activityLog on all state changes | store/update/destroy/restore/forceDelete all call activityLog | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — is_active=false before soft delete | destroy() sets is_active=false before delete() | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — restore sets is_active=true | restore() calls update(['is_active' => true]) | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — toggleStatus() flips is_active | toggleStatus() toggles via update() | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — trash/restore/forceDelete flow | trashed() uses onlyTrashed(); restore() uses onlyTrashed()->findOrFail(); forceDelete() uses withTrashed()->findOrFail() | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — JSON/flash success response | Redirect with flash on write; JSON on toggleStatus | — | — | ◌ |
| TC-CR12 | CR | P1 | Request — validation rules cover all fillable fields | All fillable columns have corresponding rules | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — prepareForValidation() casts is_active | Boolean cast via $this->boolean('is_active', true) | — | — | ◌ |
| TC-CR14 | CR | P1 | Policy — all required methods defined | viewAny, view, create, update, delete, restore, forceDelete defined | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes — resource + custom routes registered | resource (except create) + toggle-status, trashed, restore, force-delete | — | — | ◌ |
| TC-CR16 | CR | P1 | Database — index on academic_year_id and holiday_date | fk_hrs_holiday_ayid and idx_hrs_holiday_date defined | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-CR06 | Inspect store/update/destroy/restore/forceDelete | All call activityLog() |
| TC-CR07 | Inspect destroy() | Sets is_active=false before delete() |
| TC-CR08 | Inspect restore() | Calls update(['is_active' => true]) |
| TC-CR09 | Inspect toggleStatus() | Flips is_active via update() |
| TC-CR10 | Inspect trashed/restore/forceDelete | onlyTrashed/findOrFail/withTrashed patterns |
| TC-CR11 | Inspect flash/JSON responses | Flash on CRUD, JSON on toggle |
| TC-CR12 | Compare StoreHolidayRequest rules with $fillable | All fillable columns have rules |
| TC-CR13 | Inspect prepareForValidation() | is_active cast via $this->boolean('is_active', true) |
| TC-CR15 | Check web.php routes | resource('holidays') + toggle-status, trashed, restore, force-delete |
| TC-CR16 | Check DDL indexes | fk_hrs_holiday_ayid and idx_hrs_holiday_date present |

#### TC-CR01: Model — $fillable Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open HolidayCalendar.php | Model found |
| 2 | Inspect $fillable | academic_year_id, holiday_date, holiday_name, holiday_type, applicable_to, is_active, created_by, updated_by |
| 3 | Cross-check with DDL | All non-PK, non-timestamp columns present |

#### TC-CR02: Model — $casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect $casts | holiday_date => date, is_active => boolean |

#### TC-CR03: Model — SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check imports | use SoftDeletes; present |

#### TC-CR04: Model — Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect academicYear() | BelongsTo to OrganizationAcademicSession |

#### TC-CR05: Controller — Gate::authorize() on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index() | Gate::authorize('hrs.leave_type.manage') before query |
| 2 | Inspect store() | Gate::authorize() before create |
| 3 | Inspect all other methods | All gate before execution |

#### TC-CR14: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open HolidayCalendarPolicy.php | Methods: viewAny, view, create, update, delete, restore, forceDelete |

### 7.1 Positive TC Steps

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P02 | Create holidays: "Republic Day" and "Diwali" | Search by "Republic" | Grid shows only "Republic Day" |
| TC-P03 | Create national holiday "Republic Day" and state holiday "Diwali" | Filter by type=national | Grid shows only "Republic Day" |
| TC-P04 | Create state holiday | Filter by type=state | Only state holiday shown |
| TC-P05 | Create school holiday | Filter by type=school | Only school holiday shown |
| TC-P06 | Create optional holiday | Filter by type=optional | Only optional holiday shown |
| TC-P08 | Create holiday with type=national | Verify DB | holiday_type = 'national' |
| TC-P09 | Create holiday with type=optional | Verify DB | holiday_type = 'optional' |
| TC-P10 | Create holiday with applicable_to=teaching | Verify DB | applicable_to = 'teaching' |
| TC-P11 | Create holiday with applicable_to=non_teaching | Verify DB | applicable_to = 'non_teaching' |
| TC-P12 | Create holiday "Diwali", click Edit | Verify form fields | All fields pre-filled |
| TC-P13 | Edit holiday: rename "Republic Day" to "R Day" | Save | Name updated, flash "Holiday updated successfully." |
| TC-P14 | Edit holiday: change type from school to optional | Save | holiday_type changed |
| TC-P15 | Create holiday, click View | Show page loads | All fields displayed correctly |
| TC-P17 | Create holiday, click Delete | Verify flash | "Holiday removed successfully." |
| TC-P18 | Navigate to trash view | Verify list | Soft-deleted records shown ordered by holiday_date |
| TC-P19 | Click Restore on trashed holiday | Verify flash | "Holiday restored successfully." |
| TC-P20 | Click Force Delete on trashed holiday | Verify flash | "Holiday permanently deleted." |
| TC-P21 | Create→edit name→toggle→delete→trash→restore cycle | All steps succeed | No errors at any step |
| TC-P22 | Create 35 holidays | Navigate to page 1 | 30 records shown on page 1 |
| TC-P23 | Navigate to page 2 | Verify grid | 5 remaining records shown |
| TC-P24 | Navigate to standalone /holidays | Verify scope | Only current academic session holidays shown |

#### TC-P01: Holiday Calendar Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to HrStaff → HR Masters → Holidays tab | Page loads with tab=holidays |
| 3 | Verify search input | Search text field visible |
| 4 | Verify type filter | Holiday type dropdown (National/State/School/Optional) |
| 5 | Verify Add button | Add/New button visible |
| 6 | Verify grid columns | Date, Name, Type, Applicable To, Status columns |

#### TC-P07: Create Holiday With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" button | Create form opens |
| 2 | Select academic year | Current session selected |
| 3 | Pick holiday_date: 2026-01-26 | Date selected |
| 4 | Enter holiday_name: "Republic Day" | Name filled |
| 5 | Select holiday_type: national | Type set |
| 6 | Select applicable_to: all | Applicability set |
| 7 | Click Save | POST to /holidays |
| 8 | Verify flash message | "Holiday added successfully." |
| 9 | DB check | Record exists with name=Republic Day |

#### TC-P16: Toggle Status Active to Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active holiday | Record with is_active=1 |
| 2 | Click status toggle | AJAX POST to /holidays/{id}/toggle-status |
| 3 | Verify JSON | success=true, is_active=false |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N01 | Open create form, leave academic_year_id blank | Click Save | Validation error on academic_year_id |
| TC-N02 | Open create form, leave holiday_date blank | Click Save | "The holiday date field is required." |
| TC-N03 | Open create form, leave holiday_name blank | Click Save | "The holiday name field is required." |
| TC-N04 | Open create form, leave holiday_type blank | Click Save | Validation error on holiday_type |
| TC-N05 | Select invalid holiday_type value | Submit form | Validation error on holiday_type.in |
| TC-N06 | Select invalid applicable_to value | Submit form | Validation error on applicable_to.in |
| TC-N08 | Enter holiday_name > 150 chars | Submit form | Validation error on name.max |
| TC-N09 | Enter holiday_date as text "abc" | Submit form | Validation error on date |
| TC-N10 | Navigate to /holidays/99999 | Verify response | 404 Not Found |
| TC-N11 | Navigate to /holidays/99999/edit | Verify response | 404 Not Found |
| TC-N12 | DELETE /holidays/99999 | Verify response | 404 Not Found |
| TC-N13 | Login as user without permission | Access holidays | 403 Forbidden |
| TC-N14 | Logout and access /holidays | Verify redirect | Redirected to /login |
| TC-N15 | Enter whitespace-only holiday_name | Submit form | Required validation catches empty string |

#### TC-N07: Invalid academic_year_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Select non-existent academic year ID | Validation: "The selected academic year id is invalid." |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-D01 | Create holiday, call destroy() | is_active set to 0 before delete() called |
| TC-D02 | Restore trashed holiday | is_active set to 1 after restore() |
| TC-D03 | Create holiday, check activity log | activityLog called with 'Created' and holiday details |
| TC-D04 | Update holiday, check activity log | activityLog called with 'Updated' |
| TC-D05 | Soft-delete holiday, check activity log | activityLog called with 'Trashed' |
| TC-D06 | Access $holiday->holiday_date | Returns Carbon date instance (cast to date) |
| TC-D07 | Access $holiday->is_active | Returns boolean (stored as TINYINT) |
| TC-D09 | Access /holidays/99999/edit | 404 ModelNotFoundException |
| TC-D10 | Inspect all HolidayController methods | Each method calls Gate::authorize() before execution |

#### TC-D08: Model Relationship — academicYear() BelongsTo

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create holiday with academic_year_id=1 | Holiday exists |
| 2 | Access $holiday->academicYear | Returns OrganizationAcademicSession model |
| 3 | Verify name matches | academicYear->id matches academic_year_id |

#### TC-D11: FK Constraint — academic_year_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt direct INSERT with invalid academic_year_id=999999 | FK constraint violation |
