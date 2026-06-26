# HrStaff Module — Requirements Index

## Purpose
Master index of all requirement files for the HrStaff module. Each file documents the business purpose, database fields, business rules, CRUD operations, and permissions for one feature area.

---

## Feature Area → Requirement File Map

| # | Feature Area | File | Status |
|---|---|---|---|
| 1 | **Employment Details & History** | `employment.md` | ✅ Documented |
| 2 | **Employee Documents** | `documents.md` | ✅ Documented |
| 3 | **ID Card Generation** | `id-card.md` | ✅ Documented |
| 4 | **Leave Types** | `leave-types.md` | ✅ Documented |
| 5 | **Leave Policy & Balances** | `leave-policy.md` | ✅ Documented |
| 6 | **Leave Applications & Approvals** | `leave-applications.md` | ✅ Documented |
| 7 | **LOP Reconciliation** | `lop.md` | ✅ Documented |
| 8 | **Holiday Calendar** | `holidays.md` | ✅ Documented |
| 9 | **Pay Grades** | `pay-grades.md` | ✅ Documented |
| 10 | **Salary Components** | `salary-components.md` | ✅ Documented |
| 11 | **Salary Structures** | `salary-structures.md` | ✅ Documented |
| 12 | **Salary Assignments** | `salary-assignments.md` | ✅ Documented |
| 13 | **Statutory Compliance (PF/ESI/PT)** | `compliance.md` | ✅ Documented |
| 14 | **TDS & Form 16** | `tds-form16.md` | ✅ Documented |
| 15 | **Payroll Engine** | `payroll.md` | ✅ Documented |
| 16 | **Payslips** | `payslips.md` | ✅ Documented |
| 17 | **KPI Templates** | `appraisal-kpi.md` | ✅ Documented |
| 18 | **Appraisal Cycles** | `appraisal-cycles.md` | ✅ Documented |
| 19 | **Appraisals** | `appraisals.md` | ✅ Documented |
| 20 | **Increment Policies & Processing** | `increments.md` | ✅ Documented |
| 21 | **Reports** | `reports.md` | ✅ Documented |

---

## Module Statistics

| Metric | Count |
|---|---|
| Module Name | HrStaff (Human Resources, Payroll & Staff Management) |
| Database Tables | 21 (hrs_* + pay_* prefix) |
| Models | 33 |
| Controllers | 22 |
| Web Routes | ~100+ (plus resourceful, includes soft-delete routes) |
| API Routes | 5 (apiResource: 5 endpoints) |
| View Files | ~50+ across 18 subdirectories |
| Policies | 17 |
| Form Requests | 23 |
| Events | 5 |
| Services | 15 |
| Seeders | 8 |

---

## Key Subsystems

### Phase 1: Core HR (Employment, Documents, ID Cards)
- `EmploymentController`, `DocumentController`, `IdCardController`
- `EmploymentService` with history audit, `IdCardService`
- Encrypted bank details, JSON emergency contacts
- Spatie Media Library for document storage

### Phase 2: Leave Management
- `LeaveTypeController`, `HolidayController`, `LeaveController`, `LeaveApplicationController`, `LopController`
- `LeaveService`, `LeaveApprovalService`
- 2-level approval FSM, balance initialization, carry-forward
- LOP flagging with confirm/waive workflow

### Phase 3: Salary Structure
- `PayGradeController`, `SalaryComponentController`, `SalaryStructureController`, `SalaryAssignmentController`
- `SalaryStructureService`, `SalaryAssignmentService`
- Component assembly with pivot, CTC computation, effective dating

### Phase 4: Compliance & Payroll
- `ComplianceController`, `PayrollController`, `PayslipController`, `StatutoryController`, `Form16Controller`
- `PayrollComputationService`, `PayrollRunService`, `PayslipService`, `TdsComputationService`, `ComplianceService`, `BankExportService`
- 7-stage state machine, PF/ESI registers, TDS YTD tracking, Form 16 generation

### Phase 5: Appraisal & Increments
- `AppraisalController` (30+ methods), `IncrementController`
- `AppraisalService`, `IncrementService`
- KPI templates, 2-phase rating, auto reviewer assignment, increment processing

---

## Critical Notes

**Route Prefix**: All tenant-scoped under `hr-staff/` with middleware: `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified`

**Gate Permissions**: HrStaff uses `hrs.*` and `pay.*` permission keys. 17 policies with granular gates.

**Services Pattern**: Unlike Billing's GOD controller, HrStaff follows a service layer pattern — 15 dedicated service classes handle business logic separately from controllers.

**Events**: Auto-discovered via `$shouldDiscoverEvents = true`. Key events: `AppraisalFinalized`, `LeaveApproved`, `LeaveRejected`, `PayrollApproved`, `PayrollLocked`.

**Soft Delete**: Nearly all models use `SoftDeletes` trait with full trashed/restore/forceDelete routes.

**Supplementary Payroll**: Supports mid-month corrections via supplementary runs linked to parent runs.
