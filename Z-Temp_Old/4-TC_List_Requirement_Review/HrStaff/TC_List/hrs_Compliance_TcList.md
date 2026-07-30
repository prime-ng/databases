# hrs_Compliance_TcList

## Module: HrStaff → Payroll → Compliance Registers

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Payroll → Compliance Registers |
| Feature | Compliance |
| URL(s) | `GET /hr-staff/employees/{employee}/compliance/{type}` (show) |
| | `POST /hr-staff/employees/{employee}/compliance/{type}` (store) |
| | `PUT /hr-staff/employees/{employee}/compliance/{type}` (update) |
| | `GET /hr-staff/compliance/pf-register` (pfRegister) |
| | `GET /hr-staff/compliance/esi-register` (esiRegister) |
| Controller | `Modules\HrStaff\Http\Controllers\ComplianceController` — `show()` lines 25-34, `store()` lines 39-55, `update()` lines 60-63, `pfRegister()` lines 68-78, `esiRegister()` lines 83-93 |
| Model(s) | `Modules\HrStaff\Models\ComplianceRecord` (table: `hrs_compliance_records`) |
| | `Modules\HrStaff\Models\PfContributionRegister` (table: `hrs_pf_contribution_register`) |
| | `Modules\HrStaff\Models\EsiContributionRegister` (table: `hrs_esi_contribution_register`) |
| Validation (Create / Update) | `Modules\HrStaff\Http\Requests\StoreComplianceRecordRequest` (shared) |
| Policy | `Modules\HrStaff\Policies\CompliancePolicy` |
| Permissions | `hrs.compliance.manage` |
| Pagination | None (single-record form; registers show all records for selected month/year) |
| Soft Deletes | Yes — `SoftDeletes` trait on all three models |
| Read-Only | PF Register and ESI Register are read-only reports |

---

## 2. Pre-conditions

- User must be logged in with `hrs.compliance.manage` permission
- At least one employee record must exist in `sch_employees`
- For register reports, `PfContributionRegister` and `EsiContributionRegister` records must exist for the queried month/year
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

`ComplianceController::show()` loads the employee and compliance type, validates type, then calls `ComplianceService::getByType()` returning the active record or null. Register reports load with current month/year as defaults.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Compliance Record | `show()` | `ComplianceRecord::where('employee_id', $id)->where('compliance_type', $type)->active()->first()` | `is_active=true` | None |
| PF Register | `pfRegister()` | `PfContributionRegister::with('complianceRecord.employee')->active()->where('month',$m)->where('year',$y)->orderBy('compliance_record_id')->get()` | month, year, is_active | None |
| ESI Register | `esiRegister()` | `EsiContributionRegister::with('complianceRecord.employee')->active()->where('month',$m)->where('year',$y)->orderBy('compliance_record_id')->get()` | month, year, is_active | None |

---

## 4. Test Data Strategy

- Create employee records via SchoolSetup
- Direct DB inserts for `ComplianceRecord`, `PfContributionRegister`, `EsiContributionRegister` as needed
- Test all 5 compliance types: pf, esi, tds, gratuity, pt
- For register reports, insert records for specific month/year combinations
- Pre-test cleanup: truncate `hrs_compliance_records`, `hrs_pf_contribution_register`, `hrs_esi_contribution_register`

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_compliance_records`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id, UNIQUE with compliance_type |
| BC-DB-03 | compliance_type | ENUM('pf','esi','tds','gratuity','pt') | NOT NULL, UNIQUE with employee_id |
| BC-DB-04 | reference_number | VARCHAR(100) | NULL DEFAULT NULL (encrypted via SafeEncrypted cast) |
| BC-DB-05 | enrollment_date | DATE | NULL DEFAULT NULL |
| BC-DB-06 | applicable_flag | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-07 | nominee_json | JSON | NULL DEFAULT NULL |
| BC-DB-08 | details_json | JSON | NULL DEFAULT NULL |
| BC-DB-09 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-10 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-11 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-12 | created_at | TIMESTAMP | NULL |
| BC-DB-13 | updated_at | TIMESTAMP | NULL |
| BC-DB-14 | deleted_at | TIMESTAMP | NULL |
| BC-DB-15 | UNIQUE KEY | `uq_hrs_compliance` | `(employee_id, compliance_type)` |

### 5.2 Validation Rules — StoreComplianceRecordRequest

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | reference_number | nullable, string, max:100 | The Reference Number (UAN/IP/PAN) must not exceed 100 characters. |
| BC-VAL-02 | enrollment_date | nullable, date | The Enrollment Date is not a valid date. |
| BC-VAL-03 | applicable_flag | required, boolean | The Applicable field is required. |
| BC-VAL-04 | nominee_json | nullable, array | The nominee_json must be a valid array. |
| BC-VAL-05 | nominee_json.*.name | nullable, string, max:100 | — |
| BC-VAL-06 | nominee_json.*.relationship | nullable, string, max:50 | — |
| BC-VAL-07 | nominee_json.*.share_pct | nullable, numeric, min:0, max:100 | — |
| BC-VAL-08 | details_json | nullable, array | The details_json must be a valid array. |

`prepareForValidation()` normalizes `applicable_flag` via `$this->boolean('applicable_flag', true)`.

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.compliance.manage` (granted) | Full access to all compliance routes |
| BC-AUTH-02 | `hrs.compliance.manage` (denied) | All methods return 403 |
| BC-AUTH-03 | Guest (not logged in) | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Show compliance for valid type (pf, esi, tds, gratuity, pt) with existing record | Form pre-filled with existing record data |
| BC-BIZ-02 | Show compliance for valid type without existing record | Empty create form displayed |
| BC-BIZ-03 | Show compliance for invalid type (e.g., "xyz") | 404 "Invalid compliance type: xyz" |
| BC-BIZ-04 | Store new compliance record | Record created via updateOrCreate; redirect with success message "{type} compliance record saved successfully." |
| BC-BIZ-05 | Update existing compliance record via store() | Same upsert logic updates the record; activity logged |
| BC-BIZ-06 | Update existing compliance record via update() | Delegates to store(); same behavior |
| BC-BIZ-07 | Upsert with applicable_flag=false | applicable_flag set to false; record saved |
| BC-BIZ-08 | PF Register loads with current month/year | Displays all PF contribution records for current month/year |
| BC-BIZ-09 | PF Register with custom month/year filter | Displays filtered records |
| BC-BIZ-10 | ESI Register loads with current month/year | Displays all ESI contribution records |
| BC-BIZ-11 | ESI Register with custom month/year filter | Displays filtered records |
| BC-BIZ-12 | Register with no data for selected month/year | Empty state displayed |
| BC-BIZ-13 | `reference_number` encrypted at rest | Raw value in DB is encrypted; retrieved value decrypted |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `hrs_compliance_records.employee_id` | `sch_employees` | RESTRICT |
| BC-REF-02 | `hrs_pf_contribution_register.compliance_record_id` | `hrs_compliance_records` | CASCADE |
| BC-REF-03 | `hrs_pf_contribution_register.payroll_run_id` | `pay_payroll_runs` | RESTRICT |
| BC-REF-04 | `hrs_esi_contribution_register.compliance_record_id` | `hrs_compliance_records` | CASCADE |
| BC-REF-05 | `hrs_esi_contribution_register.payroll_run_id` | `pay_payroll_runs` | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Show compliance form for employee with no existing PF record | Empty create form displayed | — | — | ⬜ |
| TC-P02 | Show compliance form for employee with existing TDS record | Pre-filled edit form displayed | — | — | ⬜ |
| TC-P03 | Create PF compliance record with all fields | Record created; success message "pf compliance record saved successfully." | — | — | ⬜ |
| TC-P04 | Create ESI compliance record | Record created; success message "esi compliance record saved successfully." | — | — | ⬜ |
| TC-P05 | Create TDS compliance record with nominee_json | Record created with nominee data stored | — | — | ⬜ |
| TC-P06 | Create Gratuity compliance record | Record created; success message | — | — | ⬜ |
| TC-P07 | Create PT compliance record with details_json (state_code) | Record created with details_json stored | — | — | ⬜ |
| TC-P08 | Update existing compliance via store() (same type) | Record updated; upsert logic runs | — | — | ⬜ |
| TC-P09 | Update existing compliance via update() | Delegates to store(); record updated | — | — | ⬜ |
| TC-P10 | Set applicable_flag to false for an existing record | applicable_flag flipped to false | — | — | ⬜ |
| TC-P11 | Load PF Register with default month/year | All PF records for current month/year displayed | — | — | ⬜ |
| TC-P12 | Load PF Register with custom month/year filter | Filtered records displayed | — | — | ⬜ |
| TC-P13 | Load ESI Register with default month/year | All ESI records displayed | — | — | ⬜ |
| TC-P14 | Load ESI Register with custom month/year | Filtered records displayed | — | — | ⬜ |
| TC-P15 | Verify reference_number encrypted in DB | Raw DB value encrypted; Eloquent returns decrypted | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Show compliance with invalid type "xyz" | 404 "Invalid compliance type: xyz" | — | — | ⬜ |
| TC-N02 | Store compliance with invalid type in URL | 404 "Invalid compliance type: xyz" | — | — | ⬜ |
| TC-N03 | Create without required `applicable_flag` | Validation error: "The Applicable field is required." | — | — | ⬜ |
| TC-N04 | Create with `reference_number` exceeding 100 characters | Validation error: "The Reference Number (UAN/IP/PAN) must not exceed 100 characters." | — | — | ⬜ |
| TC-N05 | Create with invalid `enrollment_date` format | Validation error: "The Enrollment Date is not a valid date." | — | — | ⬜ |
| TC-N06 | Access any compliance page without `hrs.compliance.manage` | 403 "This action is unauthorized." | — | — | ⬜ |
| TC-N07 | Guest user attempts to access | Redirect to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Activity logged on create/update | `activityLog()` called with type 'Saved', message 'Compliance record saved.', employee_id and compliance_type | — | — | ⬜ |
| TC-D02 | B | `ComplianceService::upsert()` uses DB transaction | `DB::transaction()` wraps `updateOrCreate()` | — | — | ⬜ |
| TC-D03 | B | `updateOrCreate()` matches on employee_id + compliance_type | Composite key ensures one record per type per employee | — | — | ⬜ |
| TC-D04 | C | `compliance_type` ENUM constraint | Only 'pf','esi','tds','gratuity','pt' accepted at DB level | — | — | ⬜ |
| TC-D05 | D | UNIQUE constraint (employee_id, compliance_type) | Attempting duplicate insert causes DB error | — | — | ⬜ |
| TC-D06 | E | FK: `hrs_compliance_records.employee_id` → `sch_employees.id` | Cannot insert with non-existent employee_id | — | — | ⬜ |
| TC-D07 | E | FK: `hrs_pf_contribution_register.compliance_record_id` → `hrs_compliance_records.id` (CASCADE) | Deleting a ComplianceRecord cascades to PfContributionRegister | — | — | ⬜ |
| TC-D08 | E | FK: `hrs_esi_contribution_register.compliance_record_id` → `hrs_compliance_records.id` (CASCADE) | Deleting a ComplianceRecord cascades to EsiContributionRegister | — | — | ⬜ |
| TC-D09 | F | `reference_number` SafeEncrypted cast | Value encrypted at rest; decrypted on Eloquent access | — | — | ⬜ |
| TC-D10 | G | Gate `hrs.compliance.manage` enforced on all methods | All controller methods call `Gate::authorize('hrs.compliance.manage')` | — | — | ⬜ |
| TC-D11 | H | `validateComplianceType()` aborts for invalid types | `abort_unless(in_array($type, [...]), 404)` | — | — | ⬜ |
| TC-D12 | I | Controller `store()` and `update()` use same `StoreComplianceRecordRequest` | Both methods type-hint the same FormRequest | — | — | ⬜ |
| TC-D13 | J | `prepareForValidation()` normalizes applicable_flag | `$this->merge(['applicable_flag' => $this->boolean('applicable_flag', true)])` | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns | ComplianceRecord $fillable: employee_id, compliance_type, reference_number, enrollment_date, applicable_flag, nominee_json, details_json, is_active, created_by, updated_by | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` | ComplianceRecord: enrollment_date=>date, applicable_flag=>boolean, nominee_json=>array, details_json=>array, is_active=>boolean, reference_number=>SafeEncrypted | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `SoftDeletes` trait | All 3 models (ComplianceRecord, PfContributionRegister, EsiContributionRegister) have SoftDeletes | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | ComplianceRecord: employee() BelongsTo, pfContributions() HasMany, esiContributions() HasMany | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — `Gate::authorize()` on every method | All 5 methods call `Gate::authorize('hrs.compliance.manage')` | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on upsert | `ComplianceService::upsert()` uses `DB::transaction()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — activity logged on state changes | `store()` calls `activityLog()` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — redirect success response | Store returns redirect with success "X compliance record saved successfully." | — | — | ◌ |
| TC-CR09 | CR | P1 | Request — `StoreComplianceRecordRequest` `prepareForValidation()` | Normalizes applicable_flag to boolean | — | — | ◌ |
| TC-CR10 | CR | P1 | Policy — `CompliancePolicy` methods defined | viewAny, view, create, update, delete, restore, forceDelete all check `hrs.compliance.manage` | — | — | ◌ |
| TC-CR11 | CR | P1 | Routes — all routes registered | Compliance routes: show, store, update, pf-register, esi-register | — | — | ◌ |
| TC-CR12 | CR | P1 | Database — UNIQUE index on (employee_id, compliance_type) | `uq_hrs_compliance` present in DDL | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model $fillable matches DDL
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ComplianceRecord.php` $fillable | Contains: employee_id, compliance_type, reference_number, enrollment_date, applicable_flag, nominee_json, details_json, is_active, created_by, updated_by |

#### TC-CR02: Model $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ComplianceRecord $casts | enrollment_date=>date, applicable_flag=>boolean, nominee_json=>array, details_json=>array, is_active=>boolean, reference_number=>SafeEncrypted::class |

#### TC-CR03: SoftDeletes on all models
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect all 3 models | `use SoftDeletes;` present; DDL shows `deleted_at` for all 3 tables |

#### TC-CR04: Relationships defined
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ComplianceRecord | employee() BelongsTo, pfContributions() HasMany, esiContributions() HasMany |

#### TC-CR05: Gate on all methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ComplianceController | All 5 methods call `Gate::authorize('hrs.compliance.manage')` |

#### TC-CR06: DB transaction on upsert
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ComplianceService::upsert() | `DB::transaction(function () ...)` present |

#### TC-CR07: Activity logged
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | `activityLog($record, 'Saved', ...)` present |

#### TC-CR08: Redirect success
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() line 53-54 | `redirect()->route(..., ucfirst($type) . ' compliance record saved successfully.')` |

#### TC-CR09: prepareForValidation()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect StoreComplianceRecordRequest lines 40-43 | `$this->merge(['applicable_flag' => $this->boolean('applicable_flag', true)])` |

#### TC-CR10: Policy methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect CompliancePolicy.php | viewAny, view, create, update, delete, restore, forceDelete all use `hrs.compliance.manage` |

#### TC-CR11: Routes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --name=hr-staff.compliance` | 5 routes: show, store, update, pf-register, esi-register |

#### TC-CR12: UNIQUE index
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL `hrs_compliance_records` | `UNIQUE KEY uq_hrs_compliance (employee_id, compliance_type)` present |

### 7.1 Positive TC Steps

#### TC-P01: Show compliance for employee with no existing record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/employees/5/compliance/pf` | Empty form displayed for PF compliance type |

#### TC-P02: Show compliance for employee with existing TDS record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a ComplianceRecord for employee 5, type=tds, reference_number="PANABCD1234" | Record exists |
| 2 | GET `/hr-staff/employees/5/compliance/tds` | Form pre-filled with reference_number "PANABCD1234" |

#### TC-P03: Create PF compliance record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/compliance/pf` with reference_number="UAN1234567890", enrollment_date="2025-07-01", applicable_flag=1, nominee_json[0][name]="Raj", nominee_json[0][relationship]="Spouse", nominee_json[0][share_pct]=100 | Redirect with "pf compliance record saved successfully." |
| 2 | Verify DB | ComplianceRecord exists for employee_id=5, type=pf, with nominee_json stored as JSON |

#### TC-P04: Create ESI compliance record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/compliance/esi` with reference_number="ESI123456", enrollment_date="2025-07-01", applicable_flag=1 | Success "esi compliance record saved successfully." |

#### TC-P05: Create TDS with nominee
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/compliance/tds` with applicable_flag=1, details_json[regime]="new" | Success; details_json stored as JSON |

#### TC-P06: Create Gratuity record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/compliance/gratuity` with applicable_flag=1 | Success |

#### TC-P07: Create PT record with details_json
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/compliance/pt` with applicable_flag=1, details_json[state_code]="KA" | Success |

#### TC-P08: Update via store()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/compliance/pf` with updated reference_number | Record updated; one record still exists |

#### TC-P09: Update via update()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/hr-staff/employees/5/compliance/pf` with applicable_flag=0 | Record updated; delegates to store() |

#### TC-P10: Set applicable_flag=false
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/hr-staff/employees/5/compliance/pf` with applicable_flag=0 | Record updated; applicable_flag = 0 |

#### TC-P11: PF Register default
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert PfContributionRegister records for current month/year | 3 records exist |
| 2 | GET `/hr-staff/compliance/pf-register` | 3 PF contribution records displayed for current month/year |

#### TC-P12: PF Register custom filter
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/compliance/pf-register?month=6&year=2025` | Records for June 2025 displayed |

#### TC-P13: ESI Register default
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert EsiContributionRegister records for current month/year | Records exist |
| 2 | GET `/hr-staff/compliance/esi-register` | ESI records displayed for current month/year |

#### TC-P14: ESI Register custom filter
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/compliance/esi-register?month=6&year=2025` | Records for June 2025 displayed |

#### TC-P15: Reference number encryption
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store compliance with reference_number="UAN1234567890" | Success |
| 2 | Query DB directly | Raw reference_number column contains encrypted string (not "UAN1234567890") |
| 3 | Load via Eloquent `ComplianceRecord::find($id)->reference_number` | Returns decrypted "UAN1234567890" |

### 7.2 Negative TC Steps

#### TC-N01: Invalid compliance type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/employees/5/compliance/xyz` | 404 "Invalid compliance type: xyz" |

#### TC-N02: Store with invalid type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/compliance/xyz` | 404 "Invalid compliance type: xyz" |

#### TC-N03: Missing applicable_flag
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/compliance/pf` without applicable_flag | Validation error: "The Applicable field is required." |

#### TC-N04: reference_number too long
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with reference_number of 101 characters | Validation error: "The Reference Number (UAN/IP/PAN) must not exceed 100 characters." |

#### TC-N05: Invalid enrollment_date
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with enrollment_date="not-a-date" | Validation error: "The Enrollment Date is not a valid date." |

#### TC-N06: Access without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `hrs.compliance.manage` | Authenticated |
| 2 | Access any compliance route | 403 "This action is unauthorized." |

#### TC-N07: Guest access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, access compliance route | Redirect to /login |

### 7.3 Dependency TC Steps

#### TC-D01: Activity logged
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create compliance record for employee 5 | Success |
| 2 | Check activity log | Entry: type 'Saved', message 'Compliance record saved.', employee_id=5, compliance_type='pf' |

#### TC-D02: DB transaction in upsert
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review ComplianceService::upsert() | `DB::transaction()` present |

#### TC-D03: updateOrCreate match keys
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review ComplianceService::upsert() line 22-26 | `updateOrCreate(['employee_id' => $id, 'compliance_type' => $type], ...)` |

#### TC-D04: ENUM compliance_type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt direct DB insert with compliance_type='invalid' | DB error: "Incorrect enum value" |

#### TC-D05: UNIQUE constraint
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert two records with same employee_id=5, compliance_type='pf' | DB error: duplicate entry for uq_hrs_compliance |

#### TC-D06: FK employee_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Direct DB insert with employee_id=99999 | FK violation error |

#### TC-D07: CASCADE on compliance_record_id (PF)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ComplianceRecord with linked PfContributionRegister | Records exist |
| 2 | Soft delete the ComplianceRecord | PfContributionRegister.deleted_at also set (CASCADE) |
| > **Note:** This assumes the DDL FK cascade behavior applies to soft delete. Verify if it's cascaded via model events or database cascade. |

#### TC-D08: CASCADE on compliance_record_id (ESI)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Same cascade test as TC-D07 for EsiContributionRegister | ESI records cascade on ComplianceRecord delete |

#### TC-D09: SafeEncrypted cast
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review ComplianceRecord model $casts | `reference_number` => \App\Casts\SafeEncrypted::class |

#### TC-D10: Gate on all methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review ComplianceController | All 5 methods have `Gate::authorize('hrs.compliance.manage')` |

#### TC-D11: validateComplianceType()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review lines 95-102 | `abort_unless(in_array($type, ['pf','esi','tds','gratuity','pt'], true), 404, ...)` |

#### TC-D12: Shared FormRequest
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() and update() type-hints | Both use `StoreComplianceRecordRequest` |

#### TC-D13: prepareForValidation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review StoreComplianceRecordRequest lines 40-43 | `applicable_flag` normalized via `$this->boolean()` |
