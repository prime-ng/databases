# Statutory Compliance — Requirements

## What It Does
Manages employee statutory registrations: PF (Provident Fund), ESI (Employee State Insurance), PT (Professional Tax), TDS (Tax Deducted at Source), and Gratuity. Tracks enrollment details, nominee information (JSON), and contribution registers per payroll run. Integration with payroll engine for automatic contribution computation.

Features:
- 5 compliance types: pf, esi, tds, gratuity, pt
- Encrypted reference numbers (PF account, ESI number)
- JSON-based nominee management with share percentages
- Monthly contribution registers (PF ECR, ESI Challan)
- PT slab-based automated deduction
- Payroll integration for contribution amounts

## Database Fields

**hrs_compliance_records**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `compliance_type` | ENUM | `pf`, `esi`, `tds`, `gratuity`, `pt`. |
| `reference_number` | VARCHAR(255) | Encrypted at rest. PF number, ESI number, etc. |
| `enrollment_date` | DATE | When the employee was enrolled in this compliance. |
| `applicable_flag` | BOOLEAN | Whether this compliance applies to this employee. |
| `nominee_json` | JSON | Array of nominees: `{name, relation, share_pct}`. Cast to array. |
| `details_json` | JSON | Flexible storage for compliance-specific details. Cast to array. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**hrs_pf_contribution_register**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `compliance_record_id` | BIGINT UNSIGNED FK → `hrs_compliance_records` | Required. |
| `payroll_run_id` | BIGINT UNSIGNED FK → `pay_payroll_runs` | Required. |
| `month` | INTEGER | Month number (1-12). |
| `year` | INTEGER | 4-digit year. |
| `basic_wage` | DECIMAL(10,2) | Basic + DA considered for PF. |
| `emp_contribution` | DECIMAL(10,2) | Employee PF contribution (12% of basic_wage, capped). |
| `employer_epf` | DECIMAL(10,2) | Employer PF contribution (3.67% of basic_wage). |
| `employer_eps` | DECIMAL(10,2) | Employer EPS contribution (8.33% of basic_wage, capped at 1250). |
| `ncp_days` | INTEGER | Non-contributory period days (unpaid leave). |
| `status` | VARCHAR(255) | Contribution status (pending, submitted). |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**hrs_esi_contribution_register**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `compliance_record_id` | BIGINT UNSIGNED FK → `hrs_compliance_records` | Required. |
| `payroll_run_id` | BIGINT UNSIGNED FK → `pay_payroll_runs` | Required. |
| `month` | INTEGER | Month number (1-12). |
| `year` | INTEGER | 4-digit year. |
| `gross_wage` | DECIMAL(10,2) | Gross wage for ESI calculation. |
| `emp_contribution` | DECIMAL(10,2) | Employee ESI contribution (0.75% of gross_wage). |
| `employer_contribution` | DECIMAL(10,2) | Employer ESI contribution (3.25% of gross_wage). |
| `status` | VARCHAR(255) | Contribution status. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**hrs_pt_slabs**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `state_code` | VARCHAR(10) | State code: `HP`, `KA`, `MH`, etc. |
| `min_salary` | DECIMAL(10,2) | Minimum salary for this slab. |
| `max_salary` | DECIMAL(10,2) | Maximum salary for this slab. |
| `pt_amount` | DECIMAL(8,2) | Professional Tax amount for this slab. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Compliance Type Behavior**
- `pf`: Provident Fund. Employee contributes 12% of basic (capped at 15,000), employer contributes 3.67% EPF + 8.33% EPS (capped at 1,250). Mandatory for employees with basic > 15,000 (opt-in) or < 15,000 (mandatory).
- `esi`: Employee State Insurance. Employee 0.75%, Employer 3.25% of gross wages. Applicable for gross ≤ 21,000/month.
- `pt`: Professional Tax. State-specific slabs deducted monthly. Varies by state and salary range.
- `tds`: Tax Deducted at Source. Income tax based on financial year, computed per payroll month.
- `gratuity`: Employer liability. 4.81% of basic. Payable after 5 years of continuous service.

**PF ECR (Electronic Challan cum Return)**
- Generated monthly per payroll run
- Contains: PF member ID, basic wage, employee contribution, employer EPF, employer EPS, NCP days
- Format matches EPFO ECR specification for direct upload
- Downloads the ECR file

**ESI Challan**
- Generated monthly per payroll run
- Contains: employee ESI ID, gross wage, employee contribution, employer contribution
- Format matches ESIC challan specification
- Downloads the challan

**PT Slab Resolution**
- Employee's gross pay matched against `hrs_pt_slabs` for the employee's state
- PT deducted = `pt_amount` of the matching slab
- If no matching slab, PT = 0
- States currently configured in seeder: HP, KA, MH

**Nominee Management**
- Each compliance record can have multiple nominees
- Each nominee: `{name, relation, share_pct}`
- Sum of all `share_pct` values must equal 100
- Used for gratuity and PF nomination (as applicable)

**Encrypted Reference Numbers**
- PF account numbers, ESI numbers are encrypted at rest
- Use Laravel `encrypted` cast on `reference_number`
- Displayed as masked (last 4 digits visible) in UI

**Compliance Applicability**
- `applicable_flag = true`: Compliance is active for this employee
- `applicable_flag = false`: Compliance exists as a placeholder but contributions are not computed
- Employees can be enrolled in multiple compliance types simultaneously

## CRUD Operations

**Show Compliance Record (by type)**
- Type-specific form: PF form, ESI form, PT form
- Shows enrollment details, reference number (masked), nominee list
- PF/ESI: shows contribution history table

**Create / Update Compliance**
- Nominee section: dynamic add/remove rows with share % validation
- Reference number masked on display, full on edit

**PF Contribution Register**
- Shows all PF contributions across all employees for a selected month/year or payroll run
- Exportable to ECR format

**ESI Contribution Register**
- Shows all ESI contributions across all employees for a selected month/year or payroll run
- Exportable to challan format

**Statutory File Download**
- PF ECR file download
- ESI challan file download

## Permissions

| Operation | Permission Key |
|---|---|
| View / Manage compliance records | `hrs.compliance.manage` |
| View PF/ESI registers | `hrs.compliance.manage` |
| Download statutory files | `hrs.compliance.manage` |
