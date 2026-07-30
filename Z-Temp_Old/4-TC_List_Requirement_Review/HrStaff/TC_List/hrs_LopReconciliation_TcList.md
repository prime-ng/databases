# hrs_LopReconciliation_TcList

## Module: HrStaff → Leave Management → LOP Reconciliation

## 1. Feature Information

| Item | Details |
|------|---------|
| Module / Tab Group / Feature | HrStaff / Leave Management / LOP Reconciliation |
| URL(s) | `GET /lop-reconciliation` (`hr-staff.lop.index`), `POST /lop-reconciliation/confirm` (`hr-staff.lop.confirm`) |
| Controller | `Modules\HrStaff\Http\Controllers\LopController::index()` lines 24–38, `confirm()` lines 43–61 |
| Model(s) | `Modules\HrStaff\Models\LopRecord` (table: `hrs_lop_records`) |
| Validation (Confirm) | `Modules\HrStaff\Http\Requests\ConfirmLopRequest` |
| Policy | None — direct `Gate::authorize('hrs.lop.confirm')` in controller |
| Permissions | `hrs.lop.confirm` |
| Pagination | 50 per page (standalone), 20 per page with `lop_page` param (menu page) |
| Soft Deletes | Yes — `SoftDeletes` trait on model |
| Read-Only | No — bulk confirm/waive actions available |

## 2. Pre-conditions

- User must be logged in with `hrs.lop.confirm` permission
- LOP records must exist in `hrs_lop_records` with `flag_status = flagged` (the default)
- Active employees must exist in `sch_employees` (for the employee FK)
- Dusk env: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

## 3. Default Data Load

`LopController::index()` gates with `hrs.lop.confirm`, loads flagged records with employee relation, ordered by `absent_date`, paginated at 50. Summary counts for confirmed and waived records are also loaded.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Flagged records grid | `LopController::index()` | `LopRecord::with(['employee'])->active()->flagged()->orderBy('absent_date')` | flag_status=flagged, is_active | 50/page |
| Confirmed count | `LopController::index()` | `LopRecord::active()->confirmed()->count()` | flag_status=confirmed | None |
| Waived count | `LopController::index()` | `LopRecord::active()->where('flag_status', 'waived')->count()` | flag_status=waived | None |
| Menu page flagged | `HrMenuController::leaveManagement()` | Same as above | flagged | 20/page (lop_page) |

## 4. Test Data Strategy

- Insert 10 LOP records with `flag_status = flagged` for 3 different employees with various absent dates
- Insert 2 confirmed and 2 waived records for summary count verification
- Use distinct dates to avoid the unique constraint
- Pre-test cleanup: truncate `hrs_lop_records`
- For pagination: create 55 flagged records to test 50/page limit

## 5. Business Conditions

### 5.1 Database Schema — `hrs_lop_records`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | `employee_id` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (CASCADE) |
| BC-DB-03 | `absent_date` | DATE | NOT NULL |
| BC-DB-04 | `flag_status` | ENUM('flagged','confirmed','waived') | NOT NULL, DEFAULT 'flagged' |
| BC-DB-05 | `confirmed_by` | INT UNSIGNED | NULL, FK → `sch_employees.id` (CASCADE) |
| BC-DB-06 | `confirmed_at` | TIMESTAMP | NULL |
| BC-DB-07 | `payroll_month` | VARCHAR(7) | NULL, YYYY-MM |
| BC-DB-08 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-09 | `created_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-10 | `updated_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-11 | `created_at` | TIMESTAMP | NULL |
| BC-DB-12 | `updated_at` | TIMESTAMP | NULL |
| BC-DB-13 | `deleted_at` | TIMESTAMP | NULL (Soft delete) |
| BC-DB-14 | UNIQUE KEY `uq_hrs_lop` | (`employee_id`, `absent_date`) | |
| BC-DB-15 | KEY `idx_hrs_lop_status` | INDEX | (`flag_status`) |
| BC-DB-16 | KEY `idx_hrs_lop_month` | INDEX | (`payroll_month`) |

### 5.2 Validation Rules — `ConfirmLopRequest`

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `lop_ids` | `required\|array\|min:1` | — |
| BC-VAL-02 | `lop_ids.*` | `required\|integer\|exists:hrs_lop_records,id` | — |
| BC-VAL-03 | `action` | `required\|in:confirmed,waived` | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|------------|----------|
| BC-AUTH-01 | `hrs.lop.confirm` | View LOP dashboard and confirm/waive actions allowed |
| BC-AUTH-02 | No `hrs.lop.confirm` | `GET /lop-reconciliation` → 403 |
| BC-AUTH-03 | No `hrs.lop.confirm` | `POST /lop-reconciliation/confirm` → 403 |
| BC-AUTH-04 | Guest | Redirect to `/login` |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Default page load | Grid shows all flagged LOP records; confirmed/waived counts displayed |
| BC-BIZ-02 | Confirm single flagged record | status → confirmed; confirmed_by set; confirmed_at timestamped |
| BC-BIZ-03 | Confirm multiple flagged records | All selected records updated to confirmed |
| BC-BIZ-04 | Waive single flagged record | status → waived; confirmed_by set; confirmed_at timestamped |
| BC-BIZ-05 | Waive multiple flagged records | All selected records updated to waived |
| BC-BIZ-06 | Summary counts update after action | confirmedCount/waivedCount increase accordingly |
| BC-BIZ-07 | Already-confirmed records excluded from action | Re-selecting already confirmed records has no effect (where flagged filter skips them) |
| BC-BIZ-08 | Empty state (no flagged records) | Grid shows no records message |
| BC-BIZ-09 | Activity logged on confirm | "LOP Confirmed" activity with IDs and count |
| BC-BIZ-10 | Activity logged on waive | "LOP Waived" activity with IDs and count |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `employee_id` | `sch_employees` | CASCADE |
| BC-REF-02 | `confirmed_by` | `sch_employees` | CASCADE |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load LOP Reconciliation page | Grid shows flagged records; confirmed/waived counts visible | — | — | ⬜ |
| TC-P02 | Confirm single flagged LOP record | Status changed to confirmed; confirmed_by and confirmed_at set | — | — | ⬜ |
| TC-P03 | Confirm multiple flagged records (3 records) | All 3 statuses changed to confirmed | — | — | ⬜ |
| TC-P04 | Waive single flagged LOP record | Status changed to waived | — | — | ⬜ |
| TC-P05 | Waive multiple flagged records (2 records) | Both statuses changed to waived | — | — | ⬜ |
| TC-P06 | Confirmed count updates after confirm action | Count increments by number of confirmed records | — | — | ⬜ |
| TC-P07 | Waived count updates after waive action | Count increments by number of waived records | — | — | ⬜ |
| TC-P08 | Empty state (no flagged records) | Grid shows empty/no records message; counts still shown | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Submit with empty lop_ids array | Validation error: required | — | — | ⬜ |
| TC-N02 | Submit with non-existent lop_id | Validation error: exists | — | — | ⬜ |
| TC-N03 | Submit with invalid action (not confirmed/waived) | Validation error: invalid selection | — | — | ⬜ |
| TC-N04 | Submit without lop_ids | Validation error: required | — | — | ⬜ |
| TC-N05 | Access page without `hrs.lop.confirm` | 403 Forbidden | — | — | ⬜ |
| TC-N06 | Guest access | Redirect to /login | — | — | ⬜ |
| TC-N07 | Already-confirmed record selected | Record not updated (where flagged filter prevents it); count unaffected | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Model `$fillable` matches DDL columns | All DDL columns in fillable | — | — | ⬜ |
| TC-D02 | A | Model `$casts` — date/datetime/boolean | `absent_date` cast to date; `confirmed_at` to datetime; `is_active` to boolean | — | — | ⬜ |
| TC-D03 | A | Model uses `SoftDeletes` | Trait present; DDL has `deleted_at` | — | — | ⬜ |
| TC-D04 | A | Model relationships | `employee()` belongsTo; `confirmedByEmployee()` belongsTo | — | — | ⬜ |
| TC-D05 | A | Model scopes | `active()`, `flagged()`, `confirmed()`, `forMonth()` | — | — | ⬜ |
| TC-D06 | B | FK CASCADE — deleting employee cascades to LOP records | Employee delete removes their LOP records | — | — | ⬜ |
| TC-D07 | B | UNIQUE KEY prevents duplicate (employee, date) | Inserting same employee+date twice fails | — | — | ⬜ |
| TC-D08 | C | Controller gate on both methods | `index()` and `confirm()` both call `Gate::authorize('hrs.lop.confirm')` | — | — | ⬜ |
| TC-D09 | C | Activity logged on confirm/waive | `activityLog()` called with "LOP Confirmed" or "LOP Waived" | — | — | ⬜ |
| TC-D10 | C | `confirmLopRecords()` updates only flagged records | `where('flag_status', 'flagged')` in update query | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model `$fillable` matches DDL columns | Mass-assignment protection covers all columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model `$casts` — date/datetime/boolean | `$casts` array correctly defines types | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `SoftDeletes` trait | Trait present; `deleted_at` column in DDL | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships | `employee()`, `confirmedByEmployee()` defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — scopes | `active()`, `flagged()`, `confirmed()`, `forMonth()` | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — `Gate::authorize()` on both methods | `index()` and `confirm()` have gate check | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — activity logged on action | `activityLog()` called in `confirm()` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — JSON/flash after action | Redirect with flash message after confirm/waive | — | — | ◌ |
| TC-CR09 | CR | P1 | Request — validation rules | `ConfirmLopRequest` has rules for all 3 fields | — | — | ◌ |
| TC-CR10 | CR | P1 | Routes — both routes registered | `hr-staff.lop.index` (GET) and `hr-staff.lop.confirm` (POST) | — | — | ◌ |
| TC-CR11 | CR | P1 | View — Blade `@can` directives | LOP tab visible only with `hrs.lop.confirm` | — | — | ◌ |
| TC-CR12 | CR | P1 | View — null-safe checks for relationships | `isset($record->employee)` check before rendering | — | — | ◌ |
| TC-CR13 | CR | P1 | Database — unique indexes match validation | `uq_hrs_lop` enforces (employee_id, absent_date) uniqueness | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01 through TC-CR13: Code Review
| TC ID | Action | Expected Result |
|-------|--------|-----------------|
| TC-CR01 | Open `LopRecord.php` — `$fillable` | Verify `$fillable` matches all DDL columns |
| TC-CR02 | Open `LopRecord.php` — `$casts` | Verify date/datetime/boolean casts correctly defined |
| TC-CR03 | Open `LopRecord.php` — traits | Verify `SoftDeletes` trait present; DDL has `deleted_at` column |
| TC-CR04 | Open `LopRecord.php` — relationships | Verify `employee()`, `confirmedByEmployee()` defined |
| TC-CR05 | Open `LopRecord.php` — scopes | Verify `active()`, `flagged()`, `confirmed()`, `forMonth()` scopes defined |
| TC-CR06 | Open `LopController.php` — gates | Verify `index()` and `confirm()` both have `Gate::authorize('hrs.lop.confirm')` |
| TC-CR07 | Open `LopController.php` — activity | Verify `activityLog()` called in `confirm()` |
| TC-CR08 | Open `LopController.php` — flash | Verify redirect with flash message after confirm/waive |
| TC-CR09 | Open `ConfirmLopRequest.php` | Verify rules: lop_ids (required|array|min:1), lop_ids.* (exists:hrs_lop_records,id), action (required|in:confirmed,waived) |
| TC-CR10 | Open `routes/web.php` | Verify 2 routes: `GET /lop-reconciliation` and `POST /lop-reconciliation/confirm` |
| TC-CR11 | Open views — `@can` directives | Verify LOP tab visible only with `hrs.lop.confirm` permission |
| TC-CR12 | Open views — null-safe | Verify `isset($record->employee)` check before rendering |
| TC-CR13 | Check DDL — `hrs_lop_records` | Verify ENUM values (flagged, confirmed, waived); UNIQUE KEY uq_hrs_lop on (employee_id, absent_date); FKs with correct constraints |

### 7.1 Positive TC Steps

#### TC-P01: Load LOP Reconciliation page
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `hrs.lop.confirm` | — |
| 2 | Navigate to Leave Management > LOP Reconciliation tab | Grid shows flagged records with columns: Employee, Absent Date, Payroll Month; counts show confirmed=X, waived=Y |

#### TC-P02: Confirm single flagged LOP record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select one flagged record checkbox | — |
| 2 | Click "Confirm as LOP" | Flash: "1 LOP records confirmed successfully." |
| 3 | Record no longer in flagged grid | — |

#### TC-P03: Confirm multiple flagged records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select 3 flagged records | — |
| 2 | Confirm as LOP | Flash: "3 LOP records confirmed successfully." |
| 3 | Verify DB: all 3 have flag_status='confirmed', confirmed_by set, confirmed_at not null | — |

#### TC-P04: Waive single flagged record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select one flagged record | — |
| 2 | Click "Waive" | Flash: "1 LOP records waived successfully." |
| 3 | Record removed from flagged grid | — |

#### TC-P05: Waive multiple flagged records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select 2 flagged records, click Waive | Flash: "2 LOP records waived successfully." |

#### TC-P06: Confirmed count updates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note confirmed count before action (e.g., 5) | — |
| 2 | Confirm 3 records | — |
| 3 | Reload page | Confirmed count shows 8 |

### 7.2 Negative TC Steps

#### TC-N01: Empty lop_ids array
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit confirm action without selecting any records | Validation error: "The lop ids field is required." |

#### TC-N02: Non-existent lop_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with lop_id 99999 | Validation error |

#### TC-N03: Invalid action
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with action="delete" | Validation error: "The selected action is invalid." |

#### TC-N05: Access without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `hrs.lop.confirm` | — |
| 2 | Navigate to LOP tab | 403 Forbidden |

#### TC-P06, TC-P07, TC-P08: Summary counts and empty state (compact table)
| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P06 | Note confirmed count, then confirm 3 records | Reload page | Confirmed count increases by 3 |
| TC-P07 | Note waived count, then waive 2 records | Reload page | Waived count increases by 2 |
| TC-P08 | Confirm/waive all flagged records; reload page | Grid shows no records; counts still visible | Empty state displayed gracefully |

#### TC-N04, TC-N06, TC-N07: Additional negative scenarios (compact table)
| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N04 | Submit confirm action without `lop_ids` field in request | — | Validation error: "The lop ids field is required." |
| TC-N06 | Log out, navigate to `GET /lop-reconciliation` | — | Redirect to /login |
| TC-N07 | Select a record already in `confirmed` status | Submit confirm action | Record not updated (where flagged filter prevents it); count unaffected |

### 7.3 Dependency TC Steps

#### TC-D01 through TC-D05, TC-D08 through TC-D10: Model, FK, controller, and service dependency checks (compact table)
| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-D01 | Open `LopRecord.php` | Check `$fillable` | All DDL columns present |
| TC-D02 | Open `LopRecord.php` | Check `$casts` | `absent_date`→date, `confirmed_at`→datetime, `is_active`→boolean |
| TC-D03 | Open `LopRecord.php` | Check `SoftDeletes` trait | Trait present; DDL has `deleted_at` |
| TC-D04 | Open `LopRecord.php` | Check relationships | `employee()`, `confirmedByEmployee()` |
| TC-D05 | Open `LopRecord.php` | Check scopes | `active()`, `flagged()`, `confirmed()`, `forMonth()` |
| TC-D08 | Open `LopController.php` | Check gates on both methods | `Gate::authorize('hrs.lop.confirm')` on `index()` and `confirm()` |
| TC-D09 | Open `LopController.php` `confirm()` | Check `activityLog()` | Called with "LOP Confirmed" or "LOP Waived" |
| TC-D10 | Open `LeaveService.php` `confirmLopRecords()` | Check `where('flag_status', 'flagged')` | Only flagged records are updated |

#### TC-D06: FK CASCADE on employee delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete employee who has LOP records | LOP records for that employee cascade-deleted |

#### TC-D07: UNIQUE KEY prevents duplicate
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert LOP record for employee_id=1, absent_date=2025-08-11 | Success |
| 2 | Insert same employee_id=1, absent_date=2025-08-11 again | DB unique constraint violation |
