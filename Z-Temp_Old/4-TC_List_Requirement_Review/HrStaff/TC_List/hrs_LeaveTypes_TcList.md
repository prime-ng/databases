# hrs_LeaveTypes_TcList

## Module: HrStaff → HR Masters → Leave Types

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | HR Masters |
| Feature | Leave Types |
| URL(s) | `GET /hr-masters?tab=leave-types` (tab view), `GET /leave-types` (index), `POST /leave-types` (store), `GET /leave-types/{leaveType}` (show), `GET /leave-types/{leaveType}/edit` (edit), `PUT /leave-types/{leaveType}` (update), `DELETE /leave-types/{leaveType}` (destroy), `POST /leave-types/{leaveType}/toggle-status` (toggleStatus), `GET /leave-types/trash/view` (trashed), `GET /leave-types/{id}/restore` (restore), `DELETE /leave-types/{id}/force-delete` (forceDelete) |
| Controller | `Modules\HrStaff\Http\Controllers\LeaveTypeController` |
| Model(s) | `Modules\HrStaff\Models\LeaveType` (table: `hrs_leave_types`) |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StoreLeaveTypeRequest` |
| Policy | `Modules\HrStaff\Policies\LeaveTypePolicy` |
| Permissions | `hrs.leave_type.manage` |
| Pagination | 20 records per page using default `page` parameter (`LeaveTypeController@index`); tab view returns unfiltered collection |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` sets `is_active=false` before `delete()`; restore sets `is_active=true` |
| Activity Log | Events: Created, Updated, Trashed, Restored, Deleted (force delete) |

---

## 2. Pre-conditions

- Required permissions: `hrs.leave_type.manage`
- No seed data required — leave types can be created fresh
- Test user must have `hrs.leave_type.manage` permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For delete-guard tests: At least one employee with a leave balance referencing the leave type

---

## 3. Default Data Load

When the page loads via `HrMenuController@hrMasters()` (`GET /hr-masters` with `tab=leave-types`), the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Leave Types Grid | `HrMenuController@hrMasters()` | `LeaveType::orderBy('name')` | search (name/code), status (is_active) | None (full collection) |
| Leave Types Standalone | `LeaveTypeController@index()` | `LeaveType::orderBy('code')->withQueryString()` | search (name/code), status (is_active) | 20/page |

---

## 4. Test Data Strategy

- **Code uniqueness**: Each leave type must have a unique code — suffix test data with timestamp or UUID
- **Leave balance dependency**: Test delete guard by creating a leave balance record via related leave balance factory
- **Boolean defaults**: `is_paid` defaults to true, `requires_medical_cert` defaults to false, `half_day_allowed` defaults to false, `is_active` defaults to true
- **Pre-test cleanup**: Delete created leave types by code before/after tests
- **Pagination**: Create 25 records to test 20-record pagination boundary

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_leave_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | code | VARCHAR(10) | NOT NULL, UNIQUE (uq_hrs_leave_type_code) |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | days_per_year | DECIMAL(5,1) | NOT NULL DEFAULT 0 |
| BC-DB-05 | carry_forward_days | TINYINT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-06 | applicable_to | ENUM('all','teaching','non_teaching') | NOT NULL DEFAULT 'all' |
| BC-DB-07 | is_paid | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-08 | requires_medical_cert | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-09 | medical_cert_threshold_days | TINYINT UNSIGNED | NOT NULL DEFAULT 3 |
| BC-DB-10 | half_day_allowed | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-11 | gender_restriction | ENUM('all','male','female') | NOT NULL DEFAULT 'all' |
| BC-DB-12 | min_service_months | TINYINT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-13 | max_consecutive_days | TINYINT UNSIGNED | NULL DEFAULT NULL |
| BC-DB-14 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-15 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-16 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-17 | created_at | TIMESTAMP | NULL |
| BC-DB-18 | updated_at | TIMESTAMP | NULL |
| BC-DB-19 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Validation Rules — `StoreLeaveTypeRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | code | required, string, max:10, unique:hrs_leave_types,code (ignore current ID, whereNull deleted_at) | "The leave code has already been taken." |
| BC-VAL-02 | name | required, string, max:100 | — |
| BC-VAL-03 | days_per_year | required, numeric, min:0, max:365 | — |
| BC-VAL-04 | carry_forward_days | required, integer, min:0, max:255 | — |
| BC-VAL-05 | applicable_to | required, in:all,teaching,non_teaching | — |
| BC-VAL-06 | is_paid | required, boolean | — |
| BC-VAL-07 | requires_medical_cert | required, boolean | — |
| BC-VAL-08 | medical_cert_threshold_days | required, integer, min:1, max:30 | — |
| BC-VAL-09 | half_day_allowed | required, boolean | — |
| BC-VAL-10 | gender_restriction | required, in:all,male,female | — |
| BC-VAL-11 | min_service_months | required, integer, min:0, max:60 | — |
| BC-VAL-12 | max_consecutive_days | nullable, integer, min:1, max:255 | — |
| BC-VAL-13 | is_active | required, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.leave_type.manage` | All controller methods require this gate; without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login for all leave-type routes |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with `tab=leave-types` | Leave types list displayed in HR Masters tabbed view |
| BC-BIZ-02 | Standalone index page | Paginated grid at 20 records/page, ordered by code |
| BC-BIZ-03 | Search by name | Filters leave types where name contains search term |
| BC-BIZ-04 | Search by code | Filters leave types where code contains search term |
| BC-BIZ-05 | Filter by status | Filters leave types by `is_active` (0 or 1) |
| BC-BIZ-06 | Create with `is_paid` default=true | New leave type created with `is_paid`=1 |
| BC-BIZ-07 | Create with `requires_medical_cert` default=false | `requires_medical_cert`=0 |
| BC-BIZ-08 | Create with `half_day_allowed` default=false | `half_day_allowed`=0 |
| BC-BIZ-09 | Create with `is_active` default=true | `is_active`=1 |
| BC-BIZ-10 | Empty grid | Table shows empty state message when no leave types exist |
| BC-BIZ-11 | Toggle status active→inactive | AJAX toggles `is_active`, returns JSON success |
| BC-BIZ-12 | Screen loads via LeaveTypeController@index() with hr-staff prefix | Navigating to GET /leave-types loads paginated grid; tab loads via GET /hr-masters?tab=leave-types |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | created_by | sys_users (id) | RESTRICT (implicit) |
| BC-REF-02 | updated_by | sys_users (id) | RESTRICT (implicit) |
| BC-REF-03 | id (self) | hrs_leave_balances.leave_type_id | Child FK — blocks delete if exists (controller guard) |
| BC-REF-04 | id (self) | hrs_leave_applications.leave_type_id | Child FK |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Leave Types page loads with all UI elements | Page loads with search bar, status filter, Add button, grid | — | — | ⬜ |
| TC-P02 | Search leave types by name | Grid filtered to matching name only | — | — | ⬜ |
| TC-P03 | Search leave types by code | Grid filtered to matching code only | — | — | ⬜ |
| TC-P04 | Filter by active status | Grid shows only active leave types | — | — | ⬜ |
| TC-P05 | Filter by inactive status | Grid shows only inactive leave types | — | — | ⬜ |
| TC-P06 | Create leave type with all required fields | Leave type created with correct values | — | — | ⬜ |
| TC-P07 | Create leave type with optional fields | max_consecutive_days and all fields saved | — | — | ⬜ |
| TC-P08 | Create leave type with boolean defaults | is_paid=1, requires_medical_cert=0, half_day_allowed=0, is_active=1 | — | — | ⬜ |
| TC-P09 | Create leave type with half_day_allowed=1 | half_day_allowed set to 1 | — | — | ⬜ |
| TC-P10 | Create leave type with gender_restriction=female | gender_restriction set to female | — | — | ⬜ |
| TC-P11 | Create leave type with gender_restriction=male | gender_restriction set to male | — | — | ⬜ |
| TC-P12 | Create leave type with applicable_to=teaching | Leave type applicable to teaching staff only | — | — | ⬜ |
| TC-P13 | Create leave type with applicable_to=non_teaching | Leave type applicable to non-teaching only | — | — | ⬜ |
| TC-P14 | Create leave type with max_consecutive_days=10 | Consecutive day limit set to 10 | — | — | ⬜ |
| TC-P15 | Create leave type with requires_medical_cert=1 and threshold=5 | Medical cert required for absences > 5 days | — | — | ⬜ |
| TC-P16 | Edit leave type loads pre-filled data | Edit form shows all existing field values | — | — | ⬜ |
| TC-P17 | Update leave type name and code | Name and code updated successfully | — | — | ⬜ |
| TC-P18 | Update carry_forward_days from 0 to 5 | carry_forward_days updated to 5 | — | — | ⬜ |
| TC-P19 | View leave type details page | Show page renders with all fields displayed | — | — | ⬜ |
| TC-P20 | Toggle status active to inactive | AJAX success, is_active flipped to 0 | — | — | ⬜ |
| TC-P21 | Toggle status inactive to active | AJAX success, is_active flipped to 1 | — | — | ⬜ |
| TC-P22 | Soft delete leave type (no balances) | Leave type removed, moved to trash | — | — | ⬜ |
| TC-P23 | View trashed leave types | Trash page lists soft-deleted records | — | — | ⬜ |
| TC-P24 | Restore trashed leave type | Leave type restored with is_active=1 | — | — | ⬜ |
| TC-P25 | Force delete leave type from trash | Leave type permanently removed | — | — | ⬜ |
| TC-P26 | Full lifecycle: create→edit→toggle→delete→trash→restore | All transitions succeed | — | — | ⬜ |
| TC-P27 | Pagination — first page shows 20 records | Page 1 shows up to 20 records | — | — | ⬜ |
| TC-P28 | Pagination — second page shows remaining records | Page 2 shows records 21+ | — | — | ⬜ |
| TC-P29 | Empty state — no leave types exist | Grid shows "No records found" or equivalent | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `code` | Validation error: "The leave code field is required." | — | — | ⬜ |
| TC-N02 | Required — missing `name` | Validation error: "The leave name field is required." | — | — | ⬜ |
| TC-N03 | Required — missing `days_per_year` | Validation error: "The days per year field is required." | — | — | ⬜ |
| TC-N04 | Required — missing `carry_forward_days` | Validation error | — | — | ⬜ |
| TC-N05 | Required — missing `applicable_to` | Validation error | — | — | ⬜ |
| TC-N06 | Required — missing `is_paid` | Validation error | — | — | ⬜ |
| TC-N07 | Required — missing `gender_restriction` | Validation error | — | — | ⬜ |
| TC-N08 | Required — missing `min_service_months` | Validation error | — | — | ⬜ |
| TC-N09 | Duplicate code | "The leave code has already been taken." | — | — | ⬜ |
| TC-N10 | Max length — code > 10 chars | Validation error on code.max | — | — | ⬜ |
| TC-N11 | Max length — name > 100 chars | Validation error on name.max | — | — | ⬜ |
| TC-N12 | Invalid days_per_year — negative | Validation error on days_per_year.min | — | — | ⬜ |
| TC-N13 | Invalid days_per_year — > 365 | Validation error on days_per_year.max | — | — | ⬜ |
| TC-N14 | Invalid carry_forward_days — > 255 | Validation error on carry_forward_days.max | — | — | ⬜ |
| TC-N15 | Invalid applicable_to value | Validation error on applicable_to.in | — | — | ⬜ |
| TC-N16 | Invalid gender_restriction value | Validation error on gender_restriction.in | — | — | ⬜ |
| TC-N17 | Invalid medical_cert_threshold_days — > 30 | Validation error | — | — | ⬜ |
| TC-N18 | min_service_months > 60 | Validation error on min_service_months.max | — | — | ⬜ |
| TC-N19 | Nested ternary — max_consecutive_days = 0 (below min) | Validation error on max_consecutive_days.min | — | — | ⬜ |
| TC-N20 | Delete leave type with existing balance records | "Cannot delete leave type with existing balance records." | — | — | ⬜ |
| TC-N21 | View non-existent leave type (404) | 404 Not Found | — | — | ⬜ |
| TC-N22 | Edit non-existent leave type (404) | 404 Not Found | — | — | ⬜ |
| TC-N23 | Update non-existent leave type (404) | 404 Not Found | — | — | ⬜ |
| TC-N24 | Delete non-existent leave type (404) | 404 Not Found | — | — | ⬜ |
| TC-N25 | Permission denied — user without `hrs.leave_type.manage` | 403 Forbidden on all endpoints | — | — | ⬜ |
| TC-N26 | Guest access | Redirected to /login | — | — | ⬜ |
| TC-N27 | XSS injection in name | Stored as literal; Blade escapes output | — | — | ⬜ |
| TC-N28 | Whitespace-only code | Required validation catches empty string | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft delete sets `is_active=false` before delete | `update(['is_active' => false])` called before `delete()` | — | — | ⬜ |
| TC-D02 | A | Restore sets `is_active=true` | `update(['is_active' => true])` called after `restore()` | — | — | ⬜ |
| TC-D03 | B | Leave balance blocks delete | `leaveBalances()->exists()` controller check prevents deletion | — | — | ⬜ |
| TC-D04 | C | `created_by` and `updated_by` set on create | Both fields set to `auth()->id()` | — | — | ⬜ |
| TC-D05 | C | `updated_by` set on update | `updated_by` set to `auth()->id()` | — | — | ⬜ |
| TC-D06 | D | Activity logged on create | activityLog called with 'Created' event | — | — | ⬜ |
| TC-D07 | D | Activity logged on update | activityLog called with 'Updated' event | — | — | ⬜ |
| TC-D08 | D | Activity logged on soft delete | activityLog called with 'Trashed' event | — | — | ⬜ |
| TC-D09 | D | Activity logged on restore | activityLog called with 'Restored' event | — | — | ⬜ |
| TC-D10 | D | Activity logged on force delete | activityLog called with 'Deleted' event | — | — | ⬜ |
| TC-D11 | E | Model $casts — boolean fields | `is_paid`, `requires_medical_cert`, `half_day_allowed`, `is_active` stored as TINYINT, accessed as boolean | — | — | ⬜ |
| TC-D12 | E | Model $casts — decimal field | `days_per_year` stored as DECIMAL(5,1), accessed as decimal | — | — | ⬜ |
| TC-D13 | E | Model $casts — integer fields | `carry_forward_days`, `medical_cert_threshold_days`, `min_service_months`, `max_consecutive_days` stored as TINYINT, accessed as integer | — | — | ⬜ |
| TC-D14 | F | Model relationship — leaveBalances() HasMany | `$leaveType->leaveBalances` returns related LeaveBalance records | — | — | ⬜ |
| TC-D15 | F | Model relationship — leaveApplications() HasMany | `$leaveType->leaveApplications` returns related LeaveApplication records | — | — | ⬜ |
| TC-D16 | G | Controller — findOrFail — 404 on invalid ID | edit/update/show/destroy with invalid ID returns 404 | — | — | ⬜ |
| TC-D17 | H | Controller — Gate::authorize() on every method | All methods gate `hrs.leave_type.manage` before execution | — | — | ⬜ |
| TC-D18 | I | Unique code enforced at DB level | Direct INSERT with duplicate code throws integrity constraint violation | — | — | ⬜ |
| TC-D19 | J | `prepareForValidation` boolean casting | `is_paid`, `requires_medical_cert`, `half_day_allowed`, `is_active` normalized from checkbox to boolean | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — $fillable matches DDL columns | $fillable includes all non-PK, non-timestamp columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts for booleans/integers/decimals/dates | All typed columns have correct $casts | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `$table->deleted_at` present; SoftDeletes imported | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined (HasMany per FK) | leaveBalances, leaveApplications defined correctly | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling | All write methods wrapped in try-catch or have default exception handling | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — Gate::authorize() on every method | All 10 methods gate before execution | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — activity_logged on all state changes | store/update/destroy/restore/forceDelete all call activityLog | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — is_active=false before soft delete | destroy() sets is_active=false before delete() | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — restore sets is_active=true | restore() calls update(['is_active' => true]) | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — toggleStatus() flips is_active | toggleStatus() toggles is_active via update() | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | trashed() uses onlyTrashed(); restore() uses onlyTrashed()->findOrFail(); forceDelete() uses withTrashed()->findOrFail() | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — JSON/flash success response after create/update/delete | Redirect with flash success on all write methods; JSON on toggleStatus | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — validation rules cover all fillable fields | All $fillable columns have corresponding validation rules | — | — | ◌ |
| TC-CR14 | CR | P1 | Request — unique rules ignore current ID on update | code.unique uses ignore($id)->whereNull('deleted_at') | — | — | ◌ |
| TC-CR15 | CR | P1 | Request — prepareForValidation() normalizations | Boolean casting for 4 fields | — | — | ◌ |
| TC-CR16 | CR | P1 | Policy — all required methods defined | viewAny, view, create, update, delete, restore, forceDelete defined | — | — | ◌ |
| TC-CR17 | CR | P1 | Policy — permission strings match route/gate names | All methods use `hrs.leave_type.manage` | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — resource + custom routes registered | resource (except create) + toggle-status, trashed, restore, force-delete all mapped | — | — | ◌ |
| TC-CR19 | CR | P1 | View — Blade @can directives on tab/action buttons | @can('hrs.leave_type.manage') used for visibility | — | — | ◌ |
| TC-CR20 | CR | P1 | View — isset()/null-safe checks for relationship variables | All relationship expressions use null-safe access | — | — | ◌ |
| TC-CR21 | CR | P1 | Database — unique index matches request validation | uq_hrs_leave_type_code on code column | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

#### TC-CR01: Model — $fillable Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LeaveType.php model | Model found in Modules/HrStaff/Models/ |
| 2 | Inspect $fillable array | Contains: code, name, days_per_year, carry_forward_days, applicable_to, is_paid, requires_medical_cert, medical_cert_threshold_days, half_day_allowed, gender_restriction, min_service_months, max_consecutive_days, is_active, created_by, updated_by |
| 3 | Cross-check with DDL hrs_leave_types | All non-PK, non-timestamp columns present in $fillable |

#### TC-CR02: Model — $casts for Booleans/Integers/Decimals/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect $casts array | Contains: days_per_year decimal:1, carry_forward_days integer, is_paid boolean, requires_medical_cert boolean, medical_cert_threshold_days integer, half_day_allowed boolean, min_service_months integer, max_consecutive_days integer, is_active boolean |

#### TC-CR03: Model — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model imports | use SoftDeletes; present |
| 2 | Check DDL deleted_at column | deleted_at TIMESTAMP NULL present |

#### TC-CR04: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect leaveBalances() | HasMany to LeaveBalance::class, foreign key leave_type_id |
| 2 | Inspect leaveApplications() | HasMany to LeaveApplication::class, foreign key leave_type_id |

#### TC-CR05: Controller — try-catch Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LeaveTypeController.php | Controller found |
| 2 | Inspect all write methods | No explicit try-catch; Laravel handles exceptions at framework level |

#### TC-CR06: Controller — Gate::authorize() on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index() | Gate::authorize('hrs.leave_type.manage') before query |
| 2 | Inspect store() | Gate::authorize() before create |
| 3 | Inspect show() | Gate::authorize() before view |
| 4 | Inspect edit() | Gate::authorize() before edit |
| 5 | Inspect update() | Gate::authorize() before update |
| 6 | Inspect toggleStatus() | Gate::authorize() before toggle |
| 7 | Inspect destroy() | Gate::authorize() before delete |
| 8 | Inspect trashed() | Gate::authorize() before query |
| 9 | Inspect restore() | Gate::authorize() before restore |
| 10 | Inspect forceDelete() | Gate::authorize() before force delete |

#### TC-CR07: Controller — activityLog on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | activityLog(leaveType, 'Created', ...) called after create |
| 2 | Inspect update() | activityLog(leaveType, 'Updated', ...) called after update |
| 3 | Inspect destroy() | activityLog(leaveType, 'Trashed', ...) called after delete |
| 4 | Inspect restore() | activityLog(leaveType, 'Restored', ...) called after restore |
| 5 | Inspect forceDelete() | activityLog(leaveType, 'Deleted', ...) called after force delete |

#### TC-CR08: Controller — is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect destroy() | `$leaveType->update(['is_active' => false, 'updated_by' => auth()->id()])` called before `$leaveType->delete()` |

#### TC-CR09: Controller — restore Sets is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect restore() | `$leaveType->update(['is_active' => true])` called after `$leaveType->restore()` |

#### TC-CR10: Controller — toggleStatus() Flips is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect toggleStatus() | `update(['is_active' => !$leaveType->is_active, 'updated_by' => auth()->id()])` |

#### TC-CR11: Controller — trash/restore/forceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect trashed() | LeaveType::onlyTrashed()->orderBy('name')->paginate(15) |
| 2 | Inspect restore() | LeaveType::onlyTrashed()->findOrFail($id) |
| 3 | Inspect forceDelete() | LeaveType::withTrashed()->findOrFail($id) |

#### TC-CR12: Controller — JSON/Flash Success Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | redirect()->route(...)->with('success', 'Leave type created successfully.') |
| 2 | Inspect update() | redirect()->route(...)->with('success', 'Leave type updated successfully.') |
| 3 | Inspect destroy() | redirect()->route(...)->with('success', 'Leave type removed successfully.') |
| 4 | Inspect toggleStatus() | response()->json(['success'=>true, 'is_active'=>..., 'message'=>'Status updated successfully.']) |
| 5 | Inspect restore() | redirect()->route(...)->with('success', 'Leave Type restored successfully.') |
| 6 | Inspect forceDelete() | redirect()->route(...)->with('success', 'Leave Type permanently deleted.') |

#### TC-CR13: Request — Validation Rules Cover All Fillable Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open StoreLeaveTypeRequest.php | Request found |
| 2 | Compare rules() with model $fillable | Every $fillable column except created_by/updated_by has a rule |

#### TC-CR14: Request — Unique Rules Ignore Current ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect code rule | `Rule::unique('hrs_leave_types', 'code')->ignore($id)->whereNull('deleted_at')` |

#### TC-CR15: Request — prepareForValidation() Normalizations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect prepareForValidation() | `is_paid`, `requires_medical_cert`, `half_day_allowed`, `is_active` cast via `$this->boolean()` |

#### TC-CR16: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LeaveTypePolicy.php | Methods: viewAny, view, create, update, delete, restore, forceDelete — all present |

#### TC-CR17: Policy — Permission Strings Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect all policy methods | All use `$user->can('hrs.leave_type.manage')` |

#### TC-CR18: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect web.php routes | resource('leave-types', LeaveTypeController::class)->except(['create']) |
| 2 | Check custom routes | toggle-status, trashed, restore, force-delete present |

#### TC-CR19: View — Blade @can Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php for leave types | @can('hrs.leave_type.manage') wraps action buttons |
| 2 | Check trash view | @can('hrs.leave_type.manage') wraps restore/forceDelete |

#### TC-CR20: View — isset()/null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scan view files for relationship access | All use isset(), optional(), or ?-> null-safe operators |

#### TC-CR21: Database — Unique Index Matches Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL | UNIQUE KEY `uq_hrs_leave_type_code` on `code` |

### 7.1 Positive TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-P05 | Create inactive leave type, filter by status=inactive | Only inactive record shown |
| TC-P07 | Create leave type with max_consecutive_days=10 | DB has max_consecutive_days=10 |
| TC-P08 | Create leave type, check all boolean defaults | is_paid=1, requires_medical_cert=0, half_day_allowed=0, is_active=1 |
| TC-P10 | Create leave type with gender_restriction=female | DB has gender_restriction='female' |
| TC-P11 | Create leave type with gender_restriction=male | DB has gender_restriction='male' |
| TC-P12 | Create with applicable_to=teaching | DB has applicable_to='teaching' |
| TC-P13 | Create with applicable_to=non_teaching | DB has applicable_to='non_teaching' |
| TC-P14 | Create with max_consecutive_days=10 | DB has max_consecutive_days=10 |
| TC-P16 | Edit leave type, verify form pre-filled | All field values match existing record |
| TC-P17 | Edit name from "Old" to "New" and code from "OL" to "NW" | DB updated, flash "Leave type updated successfully." |
| TC-P18 | Edit carry_forward_days from 0 to 5 | DB has carry_forward_days=5 |
| TC-P19 | Click View on a leave type | Show page renders code, name, days, carry fwd, paid, status |
| TC-P21 | Toggle inactive leave type to active | AJAX success, is_active=1 |
| TC-P23 | Navigate to trash view | Grid shows soft-deleted records ordered by name |
| TC-P25 | Force delete from trash | Record permanently removed, flash "permanently deleted" |
| TC-P26 | Create→edit name→toggle→delete→trash→restore cycle | All steps succeed |
| TC-P27 | Create 25 leave types, go to page 1 | 20 records shown |
| TC-P28 | Go to page 2 | 5 remaining records shown |
| TC-P29 | No leave types exist | Grid shows "No records found" empty state |

#### TC-P01: Leave Types Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to HrStaff → HR Masters | Page loads with tab=leave-types default or selected |
| 3 | Verify search input | Search text field visible |
| 4 | Verify status filter | Status dropdown with Active/Inactive/All options |
| 5 | Verify Add button | Add/New button visible |
| 6 | Verify grid columns | Code, Name, Days/Year, Carry Fwd, Paid, Status columns present |

#### TC-P02: Search Leave Types By Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create leave type "Casual Leave" | Record exists |
| 2 | Create leave type "Earned Leave" | Record exists |
| 3 | Type "Casual" in search box | Grid filters to show only "Casual Leave" |
| 4 | Clear search | Both records visible |

#### TC-P03: Search Leave Types By Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create leave type with code "CL" | Record exists |
| 2 | Create leave type with code "EL" | Record exists |
| 3 | Type "CL" in search | Grid shows only "CL" record |

#### TC-P04: Filter by Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create one active and one inactive leave type | Two records |
| 2 | Select status filter = Active | Only active record shown |

#### TC-P06: Create Leave Type With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" button | Create form opens |
| 2 | Enter code "CL" | Code field filled |
| 3 | Enter name "Casual Leave" | Name field filled |
| 4 | Enter days_per_year: 12 | Days field filled |
| 5 | Enter carry_forward_days: 0 | Carry forward set |
| 6 | Select applicable_to: all | Dropdown set |
| 7 | Select gender_restriction: all | Gender set |
| 8 | Enter min_service_months: 0 | Service months set |
| 9 | Click Save | POST to /leave-types |
| 10 | Verify flash message | "Leave type created successfully." |
| 11 | DB check | Record exists with code=CL, name=Casual Leave |

#### TC-P09: Create Leave Type With half_day_allowed=1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill all required fields with code "HD" | Required fields set |
| 3 | Set half_day_allowed toggle to ON | Toggle ON |
| 4 | Click Save | Record created |
| 5 | DB check | half_day_allowed = 1 |

#### TC-P15: Create With requires_medical_cert=1 and threshold=5

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill required fields with code "SL" | Required fields set |
| 3 | Set requires_medical_cert = ON | Toggle ON |
| 4 | Set medical_cert_threshold_days = 5 | Threshold set |
| 5 | Click Save | Record created |
| 6 | DB check | requires_medical_cert=1, medical_cert_threshold_days=5 |

#### TC-P20: Toggle Status Active to Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active leave type | Record with is_active=1 |
| 2 | Click status toggle button | AJAX POST to /leave-types/{id}/toggle-status |
| 3 | Verify JSON response | success=true, is_active=false |
| 4 | DB check | is_active = 0 |

#### TC-P22: Soft Delete Leave Type (No Balances)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create leave type with no balance records | Record exists |
| 2 | Click Delete button | DELETE to /leave-types/{id} |
| 3 | Verify flash message | "Leave type removed successfully." |
| 4 | DB check | deleted_at NOT NULL, is_active=0 |

#### TC-P24: Restore Trashed Leave Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | GET /leave-types/trash/view |
| 2 | Click Restore on a trashed record | GET /leave-types/{id}/restore |
| 3 | Verify flash message | "Leave Type restored successfully." |
| 4 | DB check | deleted_at=NULL, is_active=1 |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-N01 | Submit create form without code | Validation error: "The leave code field is required." |
| TC-N02 | Submit create form without name | Validation error: "The leave name field is required." |
| TC-N03 | Submit create form without days_per_year | Validation error on days_per_year |
| TC-N04 | Submit create form without carry_forward_days | Validation error on carry_forward_days |
| TC-N05 | Submit create form without applicable_to | Validation error on applicable_to |
| TC-N06 | Submit create form without is_paid | Validation error on is_paid |
| TC-N07 | Submit create form without gender_restriction | Validation error on gender_restriction |
| TC-N08 | Submit create form without min_service_months | Validation error on min_service_months |
| TC-N10 | Submit create form with code of 11 characters | Validation error on code.max:10 |
| TC-N11 | Submit create form with name of 101 characters | Validation error on name.max:100 |
| TC-N12 | Submit create form with days_per_year=-1 | Validation error on days_per_year.min:0 |
| TC-N13 | Submit create form with days_per_year=366 | Validation error on days_per_year.max:365 |
| TC-N14 | Submit create form with carry_forward_days=256 | Validation error on carry_forward_days.max:255 |
| TC-N15 | Submit create form with applicable_to="invalid" | Validation error on applicable_to.in |
| TC-N16 | Submit create form with gender_restriction="other" | Validation error on gender_restriction.in |
| TC-N17 | Submit with medical_cert_threshold_days=31 | Validation error on max:30 |
| TC-N18 | Submit with min_service_months=61 | Validation error on min_service_months.max:60 |
| TC-N19 | Submit with max_consecutive_days=0 | Validation error on max_consecutive_days.min:1 |
| TC-N21 | Access /leave-types/99999 | 404 Not Found |
| TC-N22 | Access /leave-types/99999/edit | 404 Not Found |
| TC-N23 | PUT /leave-types/99999 | 404 Not Found |
| TC-N24 | DELETE /leave-types/99999 | 404 Not Found |
| TC-N26 | Logout and access /leave-types | Redirect to /login |
| TC-N27 | Submit create form with XSS in name | Stored as literal text, no script execution |
| TC-N28 | Submit create form with empty whitespace code | Required validation catches empty string |

#### TC-N09: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create leave type with code "CL" | First record created |
| 2 | Try to create another with code "CL" | Validation error: "The leave code has already been taken." |

#### TC-N20: Delete Blocked by Leave Balances

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create leave type "LT" | Leave type exists |
| 2 | Create leave balance record referencing this type | Balance exists |
| 3 | Try to delete the leave type | Redirect back with error "Cannot delete leave type with existing balance records." |

#### TC-N25: Permission Denied (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create user without hrs.leave_type.manage permission | User exists |
| 2 | Login as that user | Authenticated |
| 3 | Navigate to leave types | 403 Forbidden |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-D02 | Restore trashed leave type | is_active set to 1 |
| TC-D04 | Create leave type, check created_by and updated_by | Both set to auth()->id() |
| TC-D05 | Update leave type, check updated_by | updated_by set to auth()->id() |
| TC-D07 | Create leave type, check activity log | Logged with 'Updated' event |
| TC-D08 | Destroy leave type, check activity log | Logged with 'Trashed' event |
| TC-D09 | Restore leave type, check activity log | Logged with 'Restored' event |
| TC-D10 | Force delete leave type, check activity log | Logged with 'Deleted' event |
| TC-D11 | Access $leaveType->is_paid | Returns boolean (true/false) |
| TC-D12 | Access $leaveType->days_per_year | Returns decimal/float |
| TC-D13 | Access $leaveType->carry_forward_days | Returns integer |
| TC-D14 | Access $leaveType->leaveBalances | Returns HasMany collection |
| TC-D15 | Access $leaveType->leaveApplications | Returns HasMany collection (possibly empty) |
| TC-D16 | Access edit/update/show/destroy with invalid ID | 404 on all |
| TC-D17 | Inspect all LeaveTypeController methods | Each calls Gate::authorize() |
| TC-D19 | Submit create with is_paid=0 | prepareForValidation casts correctly to boolean 0 |

#### TC-D01: Soft Delete Sets is_active=false Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create leave type with is_active=1 | Record exists |
| 2 | Call destroy() | Controller sets is_active=0 before calling delete() |
| 3 | DB check after delete | is_active=0, deleted_at=NOT NULL |

#### TC-D03: Leave Balance Blocks Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create leave type with ID=1 | Type exists |
| 2 | Create leave balance with leave_type_id=1 | Balance references type |
| 3 | POST DELETE /leave-types/1 | Controller checks leaveBalances()->exists() = true |
| 4 | Verify redirect back with error | "Cannot delete leave type with existing balance records." |
| 5 | Verify record still exists | deleted_at is NULL |

#### TC-D06: Activity Logged on Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new leave type | Activity logged via activityLog() |
| 2 | Check activity log table | Entry with event='Created', properties contain code and name |

#### TC-D18: Unique Code Enforced at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create leave type with code "CL" | Record exists |
| 2 | Direct INSERT with duplicate code via DB query | Integrity constraint violation thrown |
