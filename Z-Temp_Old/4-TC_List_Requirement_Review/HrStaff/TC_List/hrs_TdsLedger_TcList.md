# hrs_TdsLedger_TcList

## Module: HrStaff → HR Masters → TDS Ledger

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | HR Masters |
| Feature | TDS Ledger |
| URL(s) | `GET tds-ledgers` (index → redirects to tab), `POST tds-ledgers` (store), `GET tds-ledgers/{tdsLedger}` (show), `GET tds-ledgers/{tdsLedger}/edit` (edit), `PUT tds-ledgers/{tdsLedger}` (update), `DELETE tds-ledgers/{tdsLedger}` (destroy), `GET tds-ledgers/trash/view` (trashed), `GET tds-ledgers/{id}/restore` (restore), `DELETE tds-ledgers/{id}/force-delete` (forceDelete), `POST tds-ledgers/{tdsLedger}/toggle-status` (toggleStatus) |
| Controller | `Modules\HrStaff\Http\Controllers\TdsLedgerController` — `index()` lines 22-25, `store()` lines 30-48, `show()` lines 53-60, `edit()` lines 65-73, `update()` lines 94-110, `destroy()` lines 161-176, `trashed()` lines 115-125, `restore()` lines 130-141, `forceDelete()` lines 146-156, `toggleStatus()` lines 78-89 |
| Model(s) | `Modules\HrStaff\Models\TdsLedger` (table: `pay_tds_ledger`) |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StoreTdsLedgerRequest` |
| Policy | No dedicated policy — `Gate::authorize('hrs.compliance.manage')` used directly in each controller method |
| Permissions | `hrs.compliance.manage` |
| Pagination | 15 records per page (trashed view); index via tabbed page |
| Soft Deletes | Yes — `SoftDeletes` trait on `TdsLedger` |
| Data Source | Native + auto-populated by `TdsComputationService` during payroll computation |

## 2. Pre-conditions

- Required permission: `hrs.compliance.manage`
- Required seed data: At least one employee, TDS compliance records for tax regime configuration
- Tenant context initialized with `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- TDS ledger entries with various months and financial years for filter/display testing
- At least 16 entries for pagination testing on trashed view

## 3. Default Data Load

The `index()` method redirects to the HR Masters tabbed page with `tab=tds-ledgers`. Individual view/edit operations load specific records.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Index | `index()` | Redirect to `hr-staff.menu.hrMasters?tab=tds-ledgers` | — | — |
| Show | `show()` | `TdsLedger::with('employee')->findOrFail($id)` | None | None |
| Edit | `edit()` | `TdsLedger::with('employee')` + `Employee::active()->orderBy('first_name')` | None | None |
| Trashed | `trashed()` | `TdsLedger::onlyTrashed()->with('employee')->orderByDesc('created_at')` | Soft-deleted only | 15/page |

## 4. Test Data Strategy

- Create TDS ledger entries for multiple employees across different FYs and months, including duplicate-combination edge cases
- Create at least 16 entries and soft-delete 3 to test pagination (15 per page on trash view) and restore flow
- Test auto-population by computing a payroll run and verifying TDS ledger entries are created automatically
- Verify YTD rollup correctness across consecutive months for the same employee+FY

## 5. Business Conditions

### 5.1 Database Schema — pay_tds_ledger

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-03 | financial_year | VARCHAR(7) | NOT NULL, YYYY-YY format |
| BC-DB-04 | month | TINYINT UNSIGNED | NOT NULL, 1–12 |
| BC-DB-05 | gross_pay | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-06 | tds_deducted | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| BC-DB-07 | ytd_gross | DECIMAL(14,2) | NOT NULL, DEFAULT 0 |
| BC-DB-08 | ytd_tds | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-09 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-10 | deleted_at | TIMESTAMP | NULL |
| BC-DB-11 | UNIQUE KEY uq_pay_tds | (`employee_id`, `financial_year`, `month`) | Unique per employee per month per FY |

### 5.2 Validation Rules — StoreTdsLedgerRequest (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | employee_id | required, exists:sch_employees,id, unique:pay_tds_ledger,employee_id+financial_year+month ignore current ID | The Employee has already been taken. |
| BC-VAL-02 | financial_year | required, string, regex:/^\d{4}-\d{2}$/ | The Financial Year must be in YYYY-YY format. |
| BC-VAL-03 | month | required, integer, min:1, max:12 | Month must be between 1 and 12. |
| BC-VAL-04 | gross_pay | required, numeric, min:0 | Gross Pay must be a number and at least 0. |
| BC-VAL-05 | tds_deducted | required, numeric, min:0 | TDS Deducted must be a number and at least 0. |
| BC-VAL-06 | ytd_gross | required, numeric, min:0 | YTD Gross must be a number and at least 0. |
| BC-VAL-07 | ytd_tds | required, numeric, min:0 | YTD TDS must be a number and at least 0. |
| BC-VAL-08 | is_active | required, boolean | Auto-set via `prepareForValidation()` merging `$this->boolean('is_active', true)` |

### 5.3 Validation Rules — StoreTdsLedgerRequest (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-09 | employee_id | required, exists:sch_employees,id, unique:pay_tds_ledger,employee_id+financial_year+month ignore `$this->route('tdsLedger')->id` | The Employee has already been taken. |

### 5.4 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | hrs.compliance.manage | Without: 403 on all TDS ledger methods |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|------------------|
| BC-BIZ-01 | Index redirects to HR Masters tab | Redirected to `hr-staff.menu.hrMasters?tab=tds-ledgers` |
| BC-BIZ-02 | Show entry loads with employee details | Entry displayed with employee name, FY, month, gross, TDS, YTD values |
| BC-BIZ-03 | Create new manual entry | Entry stored with all provided values; redirect to tab with success flash |
| BC-BIZ-04 | Create duplicate entry (same employee+FY+month) | Validation error: "The Employee has already been taken." |
| BC-BIZ-05 | Update entry (edit same employee+FY+month) | Update succeeds (unique ignores current ID) |
| BC-BIZ-06 | Soft delete entry | is_active=false; deleted_at set; redirect to tab with success flash |
| BC-BIZ-07 | View trashed entries | Lists soft-deleted entries only, 15 per page |
| BC-BIZ-08 | Restore trashed entry | deleted_at=null; is_active=true; redirect to trash with success flash |
| BC-BIZ-09 | Force delete entry | Record permanently removed from DB |
| BC-BIZ-10 | Toggle status via AJAX | is_active flips; JSON response with success=true |
| BC-BIZ-11 | Auto-population during payroll computation | Ledger entry created with correct YTD rollup from prior month |
| BC-BIZ-12 | prepareForValidation sets is_active default | When is_active not provided in request, defaults to true |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|-----------------|----------------|
| BC-REF-01 | pay_tds_ledger.employee_id | sch_employees.id | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Show TDS ledger entry | Entry displayed with employee name and all financial fields | — | — | ⬜ |
| TC-P02 | Edit TDS ledger entry | Edit form loads with employee dropdown and current values | — | — | ⬜ |
| TC-P03 | Create new TDS ledger entry | Entry saved; redirect to tab with success flash | — | — | ⬜ |
| TC-P04 | Update existing TDS ledger entry | Entry updated; redirect with success flash | — | — | ⬜ |
| TC-P05 | Soft-delete TDS ledger entry | is_active=false; deleted_at set; redirect with success flash | — | — | ⬜ |
| TC-P06 | View trashed entries (soft-deleted) | Lists only soft-deleted entries, 15 per page | — | — | ⬜ |
| TC-P07 | Restore trashed entry | deleted_at=null; is_active=true; success flash | — | — | ⬜ |
| TC-P08 | Force-delete (permanently remove) entry | Record removed from DB; success flash | — | — | ⬜ |
| TC-P09 | Toggle status via AJAX | is_active toggled; JSON response {success: true, is_active: newValue, message: "Status updated successfully."} | — | — | ⬜ |
| TC-P10 | Create entry with same employee+FY+month after deleting original | Delete removes conflict; new entry created successfully | — | — | ⬜ |
| TC-P11 | Pagination on trashed view (>15 entries) | Page 2 available showing remaining entries | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create with non-existent employee_id | Validation error (exists rule) | — | — | ⬜ |
| TC-N02 | Create with invalid financial_year format | Validation error: must be YYYY-YY format | — | — | ⬜ |
| TC-N03 | Create with month < 1 | Validation error: Month must be between 1 and 12. | — | — | ⬜ |
| TC-N04 | Create with month > 12 | Validation error: Month must be between 1 and 12. | — | — | ⬜ |
| TC-N05 | Create with negative gross_pay | Validation error: Gross Pay must be a number and at least 0. | — | — | ⬜ |
| TC-N06 | Create with non-numeric tds_deducted | Validation error: TDS Deducted must be a number. | — | — | ⬜ |
| TC-N07 | Create duplicate (employee_id+FY+month) | Validation error: "The Employee has already been taken." | — | — | ⬜ |
| TC-N08 | Access any TDS ledger method without hrs.compliance.manage | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N09 | Access any TDS ledger route as guest | Redirect to /login | — | — | ⬜ |
| TC-N10 | Show non-existent entry | ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N11 | Restore non-existent entry | ModelNotFoundException → 404 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Unique constraint on (employee_id, financial_year, month) | Duplicate entries prevented at DB level | — | — | ⬜ |
| TC-D02 | B | SoftDeletes on TdsLedger | Deleted entries have deleted_at set; excluded from active queries | — | — | ⬜ |
| TC-D03 | C | Activity logged on create/update/delete/restore/forceDelete | Each operation creates activity log entry | — | — | ⬜ |
| TC-D04 | D | Employee FK RESTRICT | Cannot delete employee referenced by TDS ledger | — | — | ⬜ |
| TC-D05 | E | prepareForValidation normalisation | is_active coerced to boolean via `$this->boolean()` | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — TdsLedger $fillable matches DDL | employee_id, financial_year, month, gross_pay, tds_deducted, ytd_gross, ytd_tds, is_active, created_by, updated_by in fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts for decimals/integers/boolean | month → integer; gross_pay, tds_deducted, ytd_gross, ytd_tds → decimal:2; is_active → boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes | deleted_at column exists | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — employee relationship | BelongsTo defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Gate::authorize() on every method | Each CRUD method checks hrs.compliance.manage | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — Activity logged on create/update/destroy/restore/forceDelete | Each state change calls activityLog() | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — is_active=false before soft delete; restore sets is_active=true | destroy() sets is_active=false then delete(); restore() sets is_active=true | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — toggleStatus flips is_active | Toggle updates is_active to opposite value; returns JSON | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — trash/restore/forceDelete flow | trashed() uses onlyTrashed(); restore() uses onlyTrashed()->findOrFail(); forceDelete uses withTrashed()->findOrFail() | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — JSON response after toggle | response()->json with success, is_active, message | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — unique rule ignores current ID on update | Rule uses `->ignore($id)->whereNull('deleted_at')` | — | — | ◌ |
| TC-CR12 | CR | P1 | Request — prepareForValidation merges is_active boolean | Merges boolean value of is_active | — | — | ◌ |
| TC-CR13 | CR | P1 | Routes — full resource routes registered | index, store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete all registered | — | — | ◌ |
| TC-CR14 | CR | P1 | Database — unique index matches validation | uq_pay_tds matches the unique rule in StoreTdsLedgerRequest | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01: Model — TdsLedger $fillable matches DDL
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare `TdsLedger::$fillable` against DDL of `pay_tds_ledger` | employee_id, financial_year, month, gross_pay, tds_deducted, ytd_gross, ytd_tds, is_active, created_by, updated_by all present |

#### TC-CR02: Model — $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TdsLedger::$casts` | month → 'integer'; gross_pay, tds_deducted, ytd_gross, ytd_tds → 'decimal:2'; is_active → 'boolean' |

#### TC-CR03: Model — SoftDeletes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a TdsLedger | deleted_at set; excluded from active queries |

#### TC-CR04: Model — employee relationship
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect TdsLedger model | employee() (BelongsTo Employee) defined |

#### TC-CR05: Controller — Gate::authorize() on every method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus | Each has `Gate::authorize('hrs.compliance.manage')` |

#### TC-CR06: Controller — Activity logged
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store, update, destroy, restore, forceDelete | Each calls activityLog() after state change |

#### TC-CR07: Controller — is_active=false before soft delete; restore sets is_active=true
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect destroy() | Calls `update(['is_active'=>false])` before `delete()` |
| 2 | Inspect restore() | Calls `update(['is_active'=>true])` after `restore()` |

#### TC-CR08: Controller — toggleStatus flips is_active
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect toggleStatus() | Updates is_active to `! $tdsLedger->is_active` |

#### TC-CR09: Controller — trash/restore/forceDelete flow
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect trashed() | Uses `onlyTrashed()` |
| 2 | Inspect restore() | Uses `onlyTrashed()->findOrFail($id)` |
| 3 | Inspect forceDelete() | Uses `withTrashed()->findOrFail($id)` |

#### TC-CR10: Controller — JSON response after toggle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect toggleStatus() | Returns `response()->json(['success'=>true, 'is_active'=>..., 'message'=>"Status updated successfully."])` |

#### TC-CR11: Request — unique rule ignores current ID on update
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect StoreTdsLedgerRequest::rules() | Unique rule uses `->ignore($id)->whereNull('deleted_at')` |

#### TC-CR12: Request — prepareForValidation merges is_active boolean
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `prepareForValidation()` | Merges `is_active` as boolean via `$this->boolean('is_active', true)` |

#### TC-CR13: Routes — full resource routes registered
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect web.php | All TDS ledger routes registered: index, toggle-status, trashed, restore, force-delete, resource routes |

#### TC-CR14: Database — unique index matches validation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare DDL unique key uq_pay_tds with request validation | Both enforce uniqueness on (employee_id, financial_year, month) |

### 7.1 Positive TC Steps

#### TC-P01: Show TDS ledger entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with hrs.compliance.manage | Session ready |
| 2 | Navigate to `GET /tds-ledgers/{id}` (existing entry) | Entry details displayed: employee name, FY, month, gross_pay, tds_deducted, ytd_gross, ytd_tds |

#### TC-P02: Edit TDS ledger entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /tds-ledgers/{id}/edit` | Edit form loads with current values and employee dropdown |

#### TC-P03: Create new TDS ledger entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `POST /tds-ledgers` with employee_id=1, financial_year="2025-26", month=4, gross_pay=28500, tds_deducted=800, ytd_gross=28500, ytd_tds=800 | Entry created; redirect to tab; flash "TDS ledger entry created successfully." |

#### TC-P04: Update existing TDS ledger entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `PUT /tds-ledgers/{id}` with updated tds_deducted=900 | Entry updated; flash "TDS ledger entry updated successfully." |

#### TC-P05: Soft-delete TDS ledger entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `DELETE /tds-ledgers/{id}` | Entry soft-deleted; is_active=false; deleted_at set; flash "TDS ledger entry removed successfully." |

#### TC-P06: View trashed entries (soft-deleted)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /tds-ledgers/trash/view` | Lists soft-deleted entries, 15 per page |
| 2 | Verify soft-deleted entries from TC-P05 appear | Listed in trash view |

#### TC-P07: Restore trashed entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click restore on a trashed entry from TC-P05 | Entry restored; deleted_at=null; is_active=true; flash "TDS ledger entry restored successfully." |

#### TC-P08: Force-delete (permanently remove) entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an entry | Entry now in trash |
| 2 | Submit `DELETE /tds-ledgers/{id}/force-delete` | Entry permanently removed; flash "TDS ledger entry permanently deleted." |

#### TC-P09: Toggle status via AJAX
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `POST /tds-ledgers/{id}/toggle-status` | JSON response: {"success": true, "is_active": true/false, "message": "Status updated successfully."} |
| 2 | Verify is_active changed | Entry's is_active field flipped |

#### TC-P10: Create entry with same combination after deleting original
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create entry for (emp=1, FY=2025-26, month=4) then soft-delete it | Entry trashed |
| 2 | Create another entry for same combination | Succeeds (unique doesn't conflict with soft-deleted) |

#### TC-P11: Pagination on trashed view (>15 entries)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 18 entries and soft-delete them | 18 trashed entries |
| 2 | Navigate to trash | Page 1 shows 15 |
| 3 | Click page 2 | Remaining 3 shown |

### 7.2 Negative TC Steps

#### TC-N01: Create with non-existent employee_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with employee_id=99999 | Validation error (exists rule) |

#### TC-N02: Create with invalid financial_year format
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with financial_year="2025" | Validation error: must be YYYY-YY format |

#### TC-N03: Create with month < 1
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with month=0 | Validation error: Month must be between 1 and 12. |

#### TC-N04: Create with month > 12
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with month=13 | Validation error: Month must be between 1 and 12. |

#### TC-N05: Create with negative gross_pay
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with gross_pay=-100 | Validation error: Gross Pay must be a number and at least 0. |

#### TC-N06: Create with non-numeric tds_deducted
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with tds_deducted="abc" | Validation error: TDS Deducted must be a number. |

#### TC-N07: Create duplicate (employee_id+FY+month)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create entry for (emp=1, FY=2025-26, month=4) | First entry created |
| 2 | Create another entry for same combination | Validation error: "The Employee has already been taken." |

#### TC-N08: Access without hrs.compliance.manage permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without hrs.compliance.manage | No permission |
| 2 | Navigate to any TDS ledger URL | HTTP 403 Forbidden |

#### TC-N09: Access any TDS ledger route as guest
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Guest session |
| 2 | Navigate to any TDS ledger URL | Redirect to /login |

#### TC-N10: Show non-existent entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /tds-ledgers/99999` | ModelNotFoundException → 404 |

#### TC-N11: Restore non-existent entry
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /tds-ledgers/99999/restore` | ModelNotFoundException → 404 |

### 7.3 Dependency TC Steps

#### TC-D01: Unique constraint on (employee_id, financial_year, month)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert two rows with same employee_id=1, FY=2025-26, month=4 | Second insert fails with integrity constraint violation |

#### TC-D02: SoftDeletes on TdsLedger
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a TdsLedger | deleted_at set; excluded from trashed() before restore |
| 2 | Call restore() | deleted_at=null; is_active=true |

#### TC-D03: Activity logged on create/update/delete/restore/forceDelete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform create, update, delete, restore, forceDelete | Each creates an activity log entry with relevant description |

#### TC-D04: Employee FK RESTRICT
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to delete an employee who has TDS ledger entries | FK constraint violation (RESTRICT) |

#### TC-D05: prepareForValidation normalisation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create request without is_active field | is_active defaults to true via `$this->boolean('is_active', true)` in prepareForValidation |
