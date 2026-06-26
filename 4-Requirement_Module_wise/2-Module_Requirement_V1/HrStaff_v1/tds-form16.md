# TDS & Form 16 — Requirements

## What It Does
Tracks monthly TDS deductions per employee per financial year with year-to-date (YTD) accumulations. Generates Form 16 PDFs (annual tax certificate) per employee per financial year. TDS computation integrates with salary computation — taxable components are summed, exemptions applied, and tax calculated per slab.

Features:
- Monthly TDS ledger with YTD tracking (gross + TDS)
- Per-month and cumulative YTD values
- Taxable income computation from salary components
- Form 16 auto-generation with employee + employer details
- DomPDF-based PDF download
- Soft-delete with restore

## Database Fields

**pay_tds_ledger**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `financial_year` | VARCHAR(7) | Required. Format: `2025-26`. |
| `month` | INTEGER | Month number (1-12). |
| `gross_pay` | DECIMAL(10,2) | Gross pay for this month. Cast to 2 decimals. |
| `tds_deducted` | DECIMAL(10,2) | TDS deducted this month. Cast to 2 decimals. |
| `ytd_gross` | DECIMAL(12,2) | Cumulative gross pay from April to current month. Cast to 2 decimals. |
| `ytd_tds` | DECIMAL(12,2) | Cumulative TDS from April to current month. Cast to 2 decimals. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**pay_form16**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `financial_year` | VARCHAR(7) | Required. Format: `2025-26`. |
| `media_id` | BIGINT UNSIGNED FK → `sys_media` | Required. Link to generated PDF file. |
| `generated_at` | DATETIME | When the Form 16 was generated. |
| `generated_by` | BIGINT UNSIGNED FK → `sch_employees` | Who generated it. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**TDS Computation**
- Performed by `TdsComputationService` during payroll computation
- Sum of all taxable salary components in the structure = taxable income
- Standard income tax slabs applied (as per Indian IT Act for the financial year)
- Default tax regime (old regime) used unless employee has opted for new regime
- Standard deductions (50,000 under Section 16) applied automatically
- Chapter VI-A deductions (80C, 80D) need manual entry (not yet implemented)

**YTD Tracking**
- `ytd_gross` and `ytd_tds` are cumulative from April (month 1) to the current month
- Computed as: sum of all previous months' gross/tds + current month
- Used for tax slab application (tax is computed on YTD basis, then current TDS = YTD TDS - already deducted)
- Reset per financial year

**Financial Year**
- Format: `YYYY-YY` (e.g., `2025-26` for April 2025 to March 2026)
- Used as a composite key (employee_id + financial_year + month) for uniqueness
- Scope: `forFinancialYear(fy)` filters by financial year
- Form 16 is generated per financial year

**Form 16 Generation**
- Triggered via `POST /hr-staff/form16/{year}/generate-all` for bulk generation
- Or individually accessed via `GET /hr-staff/form16/{year}` listing
- PDF includes:
  - Part A: Employer/Employee details, PAN, TAN, Summary of TDS
  - Part B: Gross salary, exemptions, deductions, taxable income, tax payable, tax deducted
  - Breakup by month
- Generated via `Form16Controller` using DomPDF
- PDF stored in Spatie Media Library, linked via `media_id`

**Form 16 Download**
- Employee self-service: `GET /hr-staff/my-form16/{year}/download`
- HR: View all generated Form 16s per year

## CRUD Operations

**List Form 16 Records (by year)**
- Shows all employees with Form 16 generated for the given financial year
- Columns: employee name, employee code, generated at, download link
- "Generate All" button for bulk generation

**Bulk Generate Form 16**
- Generates Form 16 for all active employees with TDS ledger entries for the year
- Existing Form 16s are NOT overwritten (skipped)
- Progress: processes in chunks to avoid timeout

**Download Form 16**
- PDF download of the Form 16 document

**Payroll TDS View**
- TDS details shown in payroll detail view
- TDS Ledger entries created automatically during payroll computation

## Permissions

| Operation | Permission Key |
|---|---|
| View TDS / Form 16 listing | `pay.form16.generate` |
| Generate Form 16 | `pay.form16.generate` |
| Download own Form 16 | `pay.form16.own.download` |
