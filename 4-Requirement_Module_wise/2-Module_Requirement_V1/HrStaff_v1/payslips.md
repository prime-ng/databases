# Payslips — Requirements

## What It Does
Generates and distributes employee payslips after payroll run lock. Supports bulk generation, employee self-service download, and email delivery status tracking. Stores PDFs in Spatie Media Library.

Features:
- Bulk payslip generation after payroll lock
- Employee self-service download (`/my-payslips`)
- PDF generation via DomPDF
- Media Library storage for generated PDFs
- Email delivery status tracking

## Database Fields

**pay_payslips**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `run_detail_id` | BIGINT UNSIGNED FK → `pay_payroll_run_details` | Required. CASCADE on delete. |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. |
| `payroll_month` | VARCHAR(7) | Format: `YYYY-MM`. |
| `media_id` | BIGINT UNSIGNED FK → `sys_media` | Required. Link to generated PDF. |
| `generated_at` | DATETIME | When the PDF was generated. |
| `email_status` | ENUM | `not_sent`, `sent`, `failed`. Default `not_sent`. |
| `email_sent_at` | DATETIME | Nullable. When the email was sent. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Payslip Generation**
- Triggered by `POST /hr-staff/payroll/{run}/payslips/generate-all`
- Only available when payroll run is in `locked` or `paid` status
- Generates PDF for each employee in the run
- PDF includes:
  - Employee details: name, code, designation, department
  - Payroll month
  - Earnings table: component name, amount (one row per earning component)
  - Deductions table: component name, amount (one row per deduction component)
  - Totals: gross pay, total deductions, net pay
  - Employer contributions (informational)
  - Amount in words (for net pay)
- PDF stored in Spatie Media Library, linked via `media_id`

**Bulk Generation Behavior**
- Skips employees who already have a payslip for this run (idempotent)
- Processes in chunks to avoid timeout
- Progress indicator: X of Y generated
- On error: continues to next employee, logs error

**Employee Self-Service**
- Shows all payslips for the authenticated employee
- Filterable by: financial year, month range
- Download link for each payslip

**Payslip Download**
- Direct download of the PDF
- Access control: employee can only download their own payslips (policy check)

## CRUD Operations

**Bulk Generate Payslips**
- Button appears on payroll show page after lock
- Shows generation progress

**View My Payslips**
- Employee portal for payslip access
- Filter by financial year
- Download each payslip as PDF

**Download Payslip**
- PDF download

## Permissions

| Operation | Permission Key |
|---|---|
| Generate payslips (bulk) | `pay.payslip.generate` |
| Download own payslip | `pay.payslip.own.download` |
| View all payslips (HR) | `pay.payslip.generate` |
