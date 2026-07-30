# hrs_StatutoryExports_TcList

## Module: HrStaff → Payroll → Compliance Registers

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Payroll → Compliance Registers |
| Feature | Statutory Exports (PF ECR / ESI Challan) |
| URL(s) | `GET payroll/{run}/pf-ecr` (pfEcr), `GET payroll/{run}/esi-challan` (esiChallan) |
| Controller | `Modules\HrStaff\Http\Controllers\StatutoryController` — `pfEcr()` lines 19-29, `esiChallan()` lines 34-44 |
| Model(s) | `Modules\HrStaff\Models\PfContributionRegister` (table: `hrs_pf_contribution_register`), `Modules\HrStaff\Models\EsiContributionRegister` (table: `hrs_esi_contribution_register`) |
| Validation | None (read-only views) |
| Policy | No dedicated policy — uses `Gate::authorize('pay.bank_file.export')` directly |
| Permissions | `pay.bank_file.export` |
| Pagination | None (all records loaded at once) |
| Soft Deletes | Yes — via `SoftDeletes` trait on both models |
| Data Source | Derived — populated by `PayrollComputationService` during payroll computation |

## 2. Pre-conditions

- Required permission: `pay.bank_file.export`
- Required seed data: A payroll run that has been computed (with PF/ESI-eligible employees having compliance records), resulting in records in `hrs_pf_contribution_register` and `hrs_esi_contribution_register`
- Tenant context initialized with `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Employees with PF and ESI compliance records configured (applicable_flag = true)

## 3. Default Data Load

Both views load via routes under a specific `{run}` parameter. No filters other than `payroll_run_id = $run->id`.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| PF ECR records | `pfEcr()` | `PfContributionRegister::with('complianceRecord.employee')->where('payroll_run_id', $run->id)->active()->get()` | payroll_run_id, is_active | None |
| ESI Challan records | `esiChallan()` | `EsiContributionRegister::with('complianceRecord.employee')->where('payroll_run_id', $run->id)->active()->get()` | payroll_run_id, is_active | None |

> **Data Source:** Records are populated by `PayrollComputationService` during payroll run computation. If the run has not been computed, no records exist.

## 4. Test Data Strategy

- Create payroll runs with at least 3 PF-eligible employees and 3 ESI-eligible employees (different gross wage brackets)
- Include employees with PF compliance but Basic+DA > ₹15,000 and ≤ ₹15,000 to test PF capping
- Include employees with gross > ₹21,000 (ESI-exempt) to verify they don't appear in ESI register
- Create compliance records with `applicable_flag = false` to test exclusion
- Test a run with zero PF/ESI records to verify empty table rendering

## 5. Business Conditions

### 5.1 Database Schema — hrs_pf_contribution_register

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | compliance_record_id | BIGINT UNSIGNED | NOT NULL, FK → hrs_compliance_records.id |
| BC-DB-03 | payroll_run_id | BIGINT UNSIGNED | NULL, FK → pay_payroll_runs.id |
| BC-DB-04 | month | TINYINT UNSIGNED | NOT NULL |
| BC-DB-05 | year | SMALLINT UNSIGNED | NOT NULL |
| BC-DB-06 | basic_wage | DECIMAL(12,2) | NOT NULL |
| BC-DB-07 | emp_contribution | DECIMAL(10,2) | NOT NULL |
| BC-DB-08 | employer_epf | DECIMAL(10,2) | NOT NULL |
| BC-DB-09 | employer_eps | DECIMAL(10,2) | NOT NULL |
| BC-DB-10 | ncp_days | TINYINT UNSIGNED | NOT NULL, DEFAULT 0 |
| BC-DB-11 | status | ENUM('computed','submitted','challan_generated') | NOT NULL, DEFAULT 'computed' |
| BC-DB-12 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-13 | UNIQUE KEY uq_hrs_pfreg | (`compliance_record_id`, `month`, `year`) | Unique per compliance record per period |

### 5.2 Database Schema — hrs_esi_contribution_register

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-14 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-15 | compliance_record_id | BIGINT UNSIGNED | NOT NULL, FK → hrs_compliance_records.id |
| BC-DB-16 | payroll_run_id | BIGINT UNSIGNED | NULL, FK → pay_payroll_runs.id |
| BC-DB-17 | month | TINYINT UNSIGNED | NOT NULL |
| BC-DB-18 | year | SMALLINT UNSIGNED | NOT NULL |
| BC-DB-19 | gross_wage | DECIMAL(12,2) | NOT NULL |
| BC-DB-20 | emp_contribution | DECIMAL(10,2) | NOT NULL |
| BC-DB-21 | employer_contribution | DECIMAL(10,2) | NOT NULL |
| BC-DB-22 | status | ENUM('computed','submitted','challan_generated') | NOT NULL, DEFAULT 'computed' |
| BC-DB-23 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-24 | UNIQUE KEY uq_hrs_esireg | (`compliance_record_id`, `month`, `year`) | Unique per compliance record per period |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | pay.bank_file.export | Without: 403 on pfEcr and esiChallan |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|------------------|
| BC-BIZ-01 | PF ECR loads for computed run with PF records | Table displays employee-wise PF contributions: basic_wage, emp_contribution, employer_epf, employer_eps |
| BC-BIZ-02 | ESI Challan loads for computed run with ESI records | Table displays employee-wise ESI contributions: gross_wage, emp_contribution, employer_contribution |
| BC-BIZ-03 | PF ECR for run with no PF records | Empty table rendered |
| BC-BIZ-04 | ESI Challan for run with no ESI records | Empty table rendered |
| BC-BIZ-05 | Run not computed yet | Empty tables (no register records populated) |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|-----------------|----------------|
| BC-REF-01 | hrs_pf_contribution_register.compliance_record_id | hrs_compliance_records.id | RESTRICT |
| BC-REF-02 | hrs_pf_contribution_register.payroll_run_id | pay_payroll_runs.id | RESTRICT |
| BC-REF-03 | hrs_esi_contribution_register.compliance_record_id | hrs_compliance_records.id | RESTRICT |
| BC-REF-04 | hrs_esi_contribution_register.payroll_run_id | pay_payroll_runs.id | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | View PF ECR for a computed run with PF-eligible employees | Table displays all PF records with correct contribution splits | — | — | ⬜ |
| TC-P02 | View ESI Challan for a computed run with ESI-eligible employees | Table displays all ESI records with correct contribution amounts | — | — | ⬜ |
| TC-P03 | PF ECR shows correct PF capping for Basic+DA > ₹15,000 | basic_wage capped at ₹15,000; contributions computed on capped amount | — | — | ⬜ |
| TC-P04 | ESI Challan excludes employees with gross > ₹21,000 | Only employees with gross ≤ ₹21,000 appear | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Access PF ECR without pay.bank_file.export permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N02 | Access ESI Challan without pay.bank_file.export permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N03 | View PF ECR on non-existent run | ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N04 | View ESI Challan on non-existent run | ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N05 | View PF ECR for run with no PF compliance records | Empty table rendered | — | — | ⬜ |
| TC-N06 | View ESI Challan for run with no ESI compliance records | Empty table rendered | — | — | ⬜ |
| TC-N07 | Access any statutory export route as guest | Redirect to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | SoftDeletes on PfContributionRegister | Deleted records excluded from view | — | — | ⬜ |
| TC-D02 | B | SoftDeletes on EsiContributionRegister | Deleted records excluded from view | — | — | ⬜ |
| TC-D03 | C | Unique constraint on PF register (compliance_record_id, month, year) | Duplicate entry prevented | — | — | ⬜ |
| TC-D04 | D | Unique constraint on ESI register (compliance_record_id, month, year) | Duplicate entry prevented | — | — | ⬜ |
| TC-D05 | E | Registers repopulated on recomputation | Re-computing a run updates register records | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() on pfEcr and esiChallan | Each method checks pay.bank_file.export | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Eager loading in queries | Both methods use with('complianceRecord.employee') | — | — | ◌ |
| TC-CR03 | CR | P1 | Routes — statutory export routes registered | pf-ecr and esi-challan routes with correct names | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01: Controller — Gate::authorize() on pfEcr and esiChallan
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect StatutoryController::pfEcr() | first line is `Gate::authorize('pay.bank_file.export')` |
| 2 | Inspect StatutoryController::esiChallan() | first line is `Gate::authorize('pay.bank_file.export')` |

#### TC-CR02: Controller — Eager loading in queries
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect pfEcr() | Query uses `with('complianceRecord.employee')` |
| 2 | Inspect esiChallan() | Query uses `with('complianceRecord.employee')` |

#### TC-CR03: Routes — statutory export routes registered
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect web.php | `GET payroll/{run}/pf-ecr` and `GET payroll/{run}/esi-challan` registered |

### 7.1 Positive TC Steps

#### TC-P01: View PF ECR for a computed run with PF-eligible employees
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with pay.bank_file.export | Session ready |
| 2 | Compute a payroll run with employees having PF compliance records applicable_flag=true | PF register populated |
| 3 | Navigate to `GET /payroll/{run}/pf-ecr` | Table displays each employee: basic_wage, emp_contribution, employer_epf, employer_eps, ncp_days |

#### TC-P02: View ESI Challan for a computed run with ESI-eligible employees
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with pay.bank_file.export | Session ready |
| 2 | Compute a payroll run with employees having ESI compliance and gross ≤ ₹21,000 | ESI register populated |
| 3 | Navigate to `GET /payroll/{run}/esi-challan` | Table displays each employee: gross_wage, emp_contribution, employer_contribution |

#### TC-P03: PF ECR shows correct PF capping
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up employee with Basic+DA = ₹25,000 and PF compliance | Basic+DA exceeds ₹15,000 cap |
| 2 | Compute and view PF ECR | basic_wage = ₹15,000 (capped); emp_contribution = ₹1,800 (12% of 15,000); employer_epf = ₹550.50; employer_eps = ₹1,249.50 |

#### TC-P04: ESI Challan excludes employees with gross > ₹21,000
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up employees with gross ₹15,000 (eligible) and ₹25,000 (ineligible) | Different gross wages |
| 2 | Compute and view ESI Challan | Only employee with ₹15,000 appears; ₹25,000 employee absent |

### 7.2 Negative TC Steps

#### TC-N01: Access PF ECR without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.bank_file.export | No permission |
| 2 | Navigate to `GET /payroll/{run}/pf-ecr` | HTTP 403 Forbidden |

#### TC-N02: Access ESI Challan without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.bank_file.export | No permission |
| 2 | Navigate to `GET /payroll/{run}/esi-challan` | HTTP 403 Forbidden |

#### TC-N03: View PF ECR on non-existent run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /payroll/99999/pf-ecr` | ModelNotFoundException → 404 |

#### TC-N04: View ESI Challan on non-existent run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /payroll/99999/esi-challan` | ModelNotFoundException → 404 |

#### TC-N05: View PF ECR for run with no PF compliance records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compute a run where no employees have PF compliance or applicable_flag=false | No PF register records |
| 2 | Navigate to PF ECR | Empty table rendered |

#### TC-N06: View ESI Challan for run with no ESI compliance records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compute a run where no employees have ESI compliance or applicable_flag=false | No ESI register records |
| 2 | Navigate to ESI Challan | Empty table rendered |

#### TC-N07: Access any statutory export route as guest
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Guest session |
| 2 | Navigate to any statutory export URL | Redirect to /login |

### 7.3 Dependency TC Steps

#### TC-D01: SoftDeletes on PfContributionRegister
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a PF register record | deleted_at set; record excluded from pfEcr view |

#### TC-D02: SoftDeletes on EsiContributionRegister
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete an ESI register record | deleted_at set; record excluded from esiChallan view |

#### TC-D03: Unique constraint on PF register
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate (compliance_record_id=1, month=1, year=2026) | Second insert fails with integrity constraint violation |

#### TC-D04: Unique constraint on ESI register
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate (compliance_record_id=1, month=1, year=2026) | Second insert fails |

#### TC-D05: Registers repopulated on recomputation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Re-compute a payroll run | PF and ESI registers refreshed with updated values |
