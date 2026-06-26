# HRS Module — Development Plan
**Module:** HrStaff (HR + Payroll)  |  **Namespace:** `Modules\HrStaff`
**Route Prefix:** `hr-staff/`  |  **Route Name Prefix:** `hr-staff.`
**Table Prefixes:** `hrs_*` (23 tables) + `pay_*` (10 tables)
**Generated:** 2026-03-26

---

## Section 1 — Controller Inventory

All controllers: `Modules\HrStaff\Http\Controllers\`
All views: `modules/HrStaff/Resources/views/`
All middleware on every route: `['auth', 'tenant', 'EnsureTenantHasModule:HrStaff']`

---

### 1.1 EmploymentController

**File:** `Http/Controllers/EmploymentController.php`
**Policy:** `EmploymentPolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `show` | GET | `employees/{emp}/hr` | `hr-staff.employment.show` | — | `hrs.employment.manage` |
| `store` | POST | `employees/{emp}/hr` | `hr-staff.employment.store` | `StoreEmploymentDetailRequest` | `hrs.employment.manage` |
| `update` | PUT | `employees/{emp}/hr` | `hr-staff.employment.update` | `UpdateEmploymentDetailRequest` | `hrs.employment.manage` |
| `history` | GET | `employees/{emp}/history` | `hr-staff.history.index` | — | `hrs.employment.manage` |

---

### 1.2 DocumentController

**File:** `Http/Controllers/DocumentController.php`
**Policy:** `DocumentPolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `employees/{emp}/documents` | `hr-staff.documents.index` | — | Own or `hrs.documents.manage` |
| `store` | POST | `employees/{emp}/documents` | `hr-staff.documents.store` | `StoreDocumentRequest` | Own or `hrs.documents.manage` |
| `destroy` | DELETE | `documents/{doc}` | `hr-staff.documents.destroy` | — | `hrs.documents.manage` |

---

### 1.3 IdCardController

**File:** `Http/Controllers/IdCardController.php`
**Policy:** `EmploymentPolicy` (reuse)

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `show` | GET | `employees/{emp}/id-card` | `hr-staff.id-card.show` | — | Own or `hrs.idcard.generate` |
| `generate` | POST | `employees/{emp}/id-card/generate` | `hr-staff.id-card.generate` | — | `hrs.idcard.generate` |

---

### 1.4 LeaveTypeController

**File:** `Http/Controllers/LeaveTypeController.php`
**Policy:** `LeaveTypePolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `leave-types` | `hr-staff.leave-types.index` | — | `hrs.leave_type.manage` |
| `store` | POST | `leave-types` | `hr-staff.leave-types.store` | `StoreLeaveTypeRequest` | `hrs.leave_type.manage` |
| `show` | GET | `leave-types/{id}` | `hr-staff.leave-types.show` | — | `hrs.leave_type.manage` |
| `update` | PUT | `leave-types/{id}` | `hr-staff.leave-types.update` | `UpdateLeaveTypeRequest` | `hrs.leave_type.manage` |
| `destroy` | DELETE | `leave-types/{id}` | `hr-staff.leave-types.destroy` | — | `hrs.leave_type.manage` |

---

### 1.5 HolidayController

**File:** `Http/Controllers/HolidayController.php`
**Policy:** `LeaveTypePolicy` (reuse)

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `holidays` | `hr-staff.holidays.index` | — | `hrs.leave_type.manage` |
| `store` | POST | `holidays` | `hr-staff.holidays.store` | `StoreHolidayRequest` | `hrs.leave_type.manage` |
| `show` | GET | `holidays/{id}` | `hr-staff.holidays.show` | — | `hrs.leave_type.manage` |
| `update` | PUT | `holidays/{id}` | `hr-staff.holidays.update` | `UpdateHolidayRequest` | `hrs.leave_type.manage` |
| `destroy` | DELETE | `holidays/{id}` | `hr-staff.holidays.destroy` | — | `hrs.leave_type.manage` |

---

### 1.6 LeaveController

**File:** `Http/Controllers/LeaveController.php`
**Policy:** `LeaveBalancePolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `policy` | GET | `leave-policy` | `hr-staff.leave-policy.show` | — | `hrs.leave_type.manage` |
| `updatePolicy` | PUT | `leave-policy` | `hr-staff.leave-policy.update` | `UpdateLeavePolicyRequest` | `hrs.leave_type.manage` |
| `initializeBalances` | POST | `leave-balances/initialize` | `hr-staff.balances.initialize` | `InitializeLeaveBalancesRequest` | `hrs.employment.manage` |
| `balances` | GET | `leave-balances` | `hr-staff.balances.index` | — | `hrs.leave.balance.view` |

---

### 1.7 LeaveApplicationController

**File:** `Http/Controllers/LeaveApplicationController.php`
**Policy:** `LeaveApplicationPolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `leave-applications` | `hr-staff.applications.index` | — | `hrs.leave.apply` |
| `store` | POST | `leave-applications` | `hr-staff.applications.store` | `StoreLeaveApplicationRequest` | `hrs.leave.apply` |
| `show` | GET | `leave-applications/{app}` | `hr-staff.applications.show` | — | Own or approver |
| `approve` | POST | `leave-applications/{app}/approve` | `hr-staff.applications.approve` | `ApproveLeaveRequest` | `hrs.leave.approve_l1` or `approve_l2` |
| `reject` | POST | `leave-applications/{app}/reject` | `hr-staff.applications.reject` | `RejectLeaveRequest` | `hrs.leave.approve_l1` or `approve_l2` |
| `cancel` | POST | `leave-applications/{app}/cancel` | `hr-staff.applications.cancel` | — | Own application |

---

### 1.8 LopController

**File:** `Http/Controllers/LopController.php`
**Policy:** Gate check: `hrs.lop.confirm`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `lop-reconciliation` | `hr-staff.lop.index` | — | `hrs.lop.confirm` |
| `confirm` | POST | `lop-reconciliation/confirm` | `hr-staff.lop.confirm` | `ConfirmLopRequest` | `hrs.lop.confirm` |

---

### 1.9 PayGradeController

**File:** `Http/Controllers/PayGradeController.php`
**Policy:** Gate check: `hrs.salary.manage`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `pay-grades` | `hr-staff.pay-grades.index` | — | `hrs.salary.manage` |
| `store` | POST | `pay-grades` | `hr-staff.pay-grades.store` | `StorePayGradeRequest` | `hrs.salary.manage` |
| `show` | GET | `pay-grades/{id}` | `hr-staff.pay-grades.show` | — | `hrs.salary.manage` |
| `update` | PUT | `pay-grades/{id}` | `hr-staff.pay-grades.update` | `UpdatePayGradeRequest` | `hrs.salary.manage` |
| `destroy` | DELETE | `pay-grades/{id}` | `hr-staff.pay-grades.destroy` | — | `hrs.salary.manage` |

---

### 1.10 SalaryAssignmentController

**File:** `Http/Controllers/SalaryAssignmentController.php`
**Policy:** `SalaryAssignmentPolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `show` | GET | `employees/{emp}/salary` | `hr-staff.salary.show` | — | `hrs.salary.manage` (read for Accountant) |
| `store` | POST | `employees/{emp}/salary` | `hr-staff.salary.store` | `StoreSalaryAssignmentRequest` | `hrs.salary.manage` |
| `update` | PUT | `employees/{emp}/salary` | `hr-staff.salary.update` | `UpdateSalaryAssignmentRequest` | `hrs.salary.manage` |
| `revision` | POST | `employees/{emp}/salary-revision` | `hr-staff.salary.revision` | `StoreSalaryRevisionRequest` | `hrs.salary.manage` |

---

### 1.11 ComplianceController

**File:** `Http/Controllers/ComplianceController.php`
**Policy:** `CompliancePolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `show` | GET | `employees/{emp}/compliance/{type}` | `hr-staff.compliance.show` | — | `hrs.compliance.manage` (read for Accountant) |
| `store` | POST | `employees/{emp}/compliance/{type}` | `hr-staff.compliance.store` | `StoreComplianceRecordRequest` | `hrs.compliance.manage` |
| `update` | PUT | `employees/{emp}/compliance/{type}` | `hr-staff.compliance.update` | `UpdateComplianceRecordRequest` | `hrs.compliance.manage` |
| `pfRegister` | GET | `compliance/pf-register` | `hr-staff.compliance.pf-register` | — | `hrs.compliance.manage` |
| `esiRegister` | GET | `compliance/esi-register` | `hr-staff.compliance.esi-register` | — | `hrs.compliance.manage` |

---

### 1.12 SalaryComponentController

**File:** `Http/Controllers/SalaryComponentController.php`
**Policy:** `SalaryStructurePolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `salary-components` | `hr-staff.salary-components.index` | — | `pay.structure.manage` |
| `store` | POST | `salary-components` | `hr-staff.salary-components.store` | `StoreSalaryComponentRequest` | `pay.structure.manage` |
| `show` | GET | `salary-components/{id}` | `hr-staff.salary-components.show` | — | `pay.structure.manage` |
| `update` | PUT | `salary-components/{id}` | `hr-staff.salary-components.update` | `UpdateSalaryComponentRequest` | `pay.structure.manage` |
| `destroy` | DELETE | `salary-components/{id}` | `hr-staff.salary-components.destroy` | — | `pay.structure.manage` |

---

### 1.13 SalaryStructureController

**File:** `Http/Controllers/SalaryStructureController.php`
**Policy:** `SalaryStructurePolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `salary-structures` | `hr-staff.salary-structures.index` | — | `pay.structure.manage` |
| `store` | POST | `salary-structures` | `hr-staff.salary-structures.store` | `StoreSalaryStructureRequest` | `pay.structure.manage` |
| `show` | GET | `salary-structures/{str}` | `hr-staff.salary-structures.show` | — | `pay.structure.manage` |
| `update` | PUT | `salary-structures/{str}` | `hr-staff.salary-structures.update` | `UpdateSalaryStructureRequest` | `pay.structure.manage` |
| `destroy` | DELETE | `salary-structures/{str}` | `hr-staff.salary-structures.destroy` | — | `pay.structure.manage` |
| `preview` | GET | `salary-structures/{str}/preview` | `hr-staff.salary-structures.preview` | — | `pay.structure.manage` |

---

### 1.14 AppraisalController

**File:** `Http/Controllers/AppraisalController.php`
**Policies:** `AppraisalCyclePolicy`, `AppraisalPolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `kpiIndex` | GET | `kpi-templates` | `hr-staff.kpi-templates.index` | — | `hrs.appraisal.manage` |
| `kpiStore` | POST | `kpi-templates` | `hr-staff.kpi-templates.store` | `StoreKpiTemplateRequest` | `hrs.appraisal.manage` |
| `kpiShow` | GET | `kpi-templates/{id}` | `hr-staff.kpi-templates.show` | — | `hrs.appraisal.manage` |
| `kpiUpdate` | PUT | `kpi-templates/{id}` | `hr-staff.kpi-templates.update` | `StoreKpiTemplateRequest` | `hrs.appraisal.manage` |
| `kpiDestroy` | DELETE | `kpi-templates/{id}` | `hr-staff.kpi-templates.destroy` | — | `hrs.appraisal.manage` |
| `cycleIndex` | GET | `appraisal-cycles` | `hr-staff.cycles.index` | — | `hrs.appraisal.manage` |
| `cycleStore` | POST | `appraisal-cycles` | `hr-staff.cycles.store` | `StoreAppraisalCycleRequest` | `hrs.appraisal.manage` |
| `cycleShow` | GET | `appraisal-cycles/{id}` | `hr-staff.cycles.show` | — | `hrs.appraisal.manage` |
| `cycleUpdate` | PUT | `appraisal-cycles/{id}` | `hr-staff.cycles.update` | `StoreAppraisalCycleRequest` | `hrs.appraisal.manage` |
| `index` | GET | `appraisals` | `hr-staff.appraisals.index` | — | `hrs.appraisal.manage` or `hrs.appraisal.self` |
| `show` | GET | `appraisals/{apr}` | `hr-staff.appraisals.show` | — | Own or reviewer or manage |
| `submitSelf` | POST | `appraisals/{apr}/submit-self` | `hr-staff.appraisals.submit-self` | `SubmitSelfAppraisalRequest` | `hrs.appraisal.self` |
| `submitReview` | POST | `appraisals/{apr}/submit-review` | `hr-staff.appraisals.submit-review` | `SubmitReviewRequest` | `hrs.appraisal.review` |
| `finalize` | POST | `appraisals/{apr}/finalize` | `hr-staff.appraisals.finalize` | — | `hrs.appraisal.manage` |

---

### 1.15 PayrollController

**File:** `Http/Controllers/PayrollController.php`
**Policy:** `PayrollRunPolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `payroll` | `hr-staff.payroll.index` | — | `pay.run.initiate` or `pay.run.approve` |
| `store` | POST | `payroll` | `hr-staff.payroll.store` | `StorePayrollRunRequest` | `pay.run.initiate` |
| `show` | GET | `payroll/{run}` | `hr-staff.payroll.show` | — | `pay.run.initiate` or `pay.run.approve` |
| `compute` | POST | `payroll/{run}/compute` | `hr-staff.payroll.compute` | — | `pay.run.compute` |
| `details` | GET | `payroll/{run}/details` | `hr-staff.payroll.details` | — | `pay.run.compute` |
| `override` | PUT | `payroll/{run}/details/{detail}/override` | `hr-staff.payroll.override` | `OverridePayrollDetailRequest` | `pay.run.compute` |
| `submit` | POST | `payroll/{run}/submit` | `hr-staff.payroll.submit` | — | `pay.run.compute` |
| `approve` | POST | `payroll/{run}/approve` | `hr-staff.payroll.approve` | — | `pay.run.approve` |
| `lock` | POST | `payroll/{run}/lock` | `hr-staff.payroll.lock` | — | `pay.run.lock` |
| `bankFile` | GET | `payroll/{run}/bank-file` | `hr-staff.payroll.bank-file` | — | `pay.bank_file.export` |
| `markPaid` | POST | `payroll/{run}/mark-paid` | `hr-staff.payroll.mark-paid` | — | `pay.bank_file.export` |

---

### 1.16 PayslipController

**File:** `Http/Controllers/PayslipController.php`
**Policy:** `PayslipPolicy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `generate` | POST | `payroll/{run}/payslips/generate` | `hr-staff.payslips.generate` | — | `pay.payslip.generate` |
| `generateAll` | POST | `payroll/{run}/payslips/generate-all` | `hr-staff.payslips.generate-all` | — | `pay.payslip.generate` |
| `emailAll` | POST | `payroll/{run}/payslips/email-all` | `hr-staff.payslips.email-all` | — | `pay.payslip.generate` |
| `downloadZip` | GET | `payroll/{run}/payslips/download-zip` | `hr-staff.payslips.download-zip` | — | `pay.payslip.generate` |
| `myPayslips` | GET | `my-payslips` | `hr-staff.my-payslips.index` | — | `pay.payslip.own.download` |
| `download` | GET | `my-payslips/{payslip}/download` | `hr-staff.my-payslips.download` | — | `pay.payslip.own.download` |

---

### 1.17 StatutoryController

**File:** `Http/Controllers/StatutoryController.php`
**Policy:** Gate check: `pay.bank_file.export`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `pfEcr` | GET | `payroll/{run}/pf-ecr` | `hr-staff.payroll.pf-ecr` | — | `pay.bank_file.export` |
| `esiChallan` | GET | `payroll/{run}/esi-challan` | `hr-staff.payroll.esi-challan` | — | `pay.bank_file.export` |

---

### 1.18 Form16Controller

**File:** `Http/Controllers/Form16Controller.php`
**Policy:** `Form16Policy`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `form16/{year}` | `hr-staff.form16.index` | — | `pay.form16.generate` |
| `generateAll` | POST | `form16/{year}/generate-all` | `hr-staff.form16.generate-all` | — | `pay.form16.generate` |
| `download` | GET | `my-form16/{year}/download` | `hr-staff.my-form16.download` | — | `pay.form16.own.download` |

---

### 1.19 IncrementController

**File:** `Http/Controllers/IncrementController.php`
**Policy:** Gate check: `pay.increment.process`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `increments` | `hr-staff.increments.index` | — | `pay.increment.process` |
| `policyIndex` | GET | `increment-policies` | `hr-staff.increment-policies.index` | — | `pay.increment.process` |
| `policyStore` | POST | `increment-policies` | `hr-staff.increment-policies.store` | `StoreIncrementPolicyRequest` | `pay.increment.process` |
| `policyShow` | GET | `increment-policies/{id}` | `hr-staff.increment-policies.show` | — | `pay.increment.process` |
| `policyUpdate` | PUT | `increment-policies/{id}` | `hr-staff.increment-policies.update` | `StoreIncrementPolicyRequest` | `pay.increment.process` |
| `process` | POST | `increments/process` | `hr-staff.increments.process` | — | `pay.increment.process` |

---

### 1.20 PayrollReportController

**File:** `Http/Controllers/PayrollReportController.php`
**Policy:** Gate check: `pay.report.view`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `salaryRegister` | GET | `reports/salary-register` | `hr-staff.reports.salary-register` | — | `pay.report.view` |
| `bankSummary` | GET | `reports/bank-summary` | `hr-staff.reports.bank-summary` | — | `pay.report.view` |
| `ctcAnalysis` | GET | `reports/ctc-analysis` | `hr-staff.reports.ctc-analysis` | — | `pay.report.view` |
| `trend` | GET | `reports/payroll-trend` | `hr-staff.reports.payroll-trend` | — | `pay.report.view` |

---

## Section 2 — Service Inventory (15 Services)

All services: `Modules\HrStaff\Services\`

---

### 2.1 EmploymentService

**File:** `Services/EmploymentService.php`
**Dependencies:** `HolidayService`
**Events Fired:** none (audit via `sys_activity_logs`)

```php
createOrUpdate(int $employeeId, array $data): EmploymentDetail
    // Creates hrs_employment_details row; encrypts bank_account_number
logHistory(int $employeeId, string $changeType, array $old, array $new, string $remarks): void
    // Writes hrs_employment_history
generateEmpCode(int $year): string
    // Format EMP/YYYY/NNN; atomically reserves next sequence
```

---

### 2.2 LeaveService

**File:** `Services/LeaveService.php`
**Dependencies:** `HolidayService`
**Events Fired:** none (events fired by `LeaveApprovalService`)

```php
initializeBalances(int $academicYearId): void
    // Creates hrs_leave_balances for all active employees × all leave types; applies carry-forward
calculateDays(int $leaveTypeId, Carbon $from, Carbon $to, bool $halfDay): float
    // Excludes weekends and holidays; returns 0.5 for half-day
applyLeave(array $data, int $employeeId): LeaveApplication
    // Validates balance, overlap, min_service_months, backdated window; writes hrs_leave_applications
cancelLeave(int $applicationId): bool
    // Restores balance; only allowed if from_date > today
runLopReconciliation(Carbon $month): Collection
    // Reads att_staff_attendances; flags absent-without-approved-leave into hrs_lop_records
adjustBalance(int $leaveBalanceId, float $days, string $reason, int $adjustedBy): void
    // Writes hrs_leave_balance_adjustments; updates hrs_leave_balances
```

---

### 2.3 LeaveApprovalService

**File:** `Services/LeaveApprovalService.php`
**Dependencies:** `LeaveService`
**Events Fired:** `LeaveApproved`, `LeaveRejected`

```php
approve(LeaveApplication $app, int $approverId, string $remarks): LeaveApplication
    // Writes hrs_leave_approvals; advances FSM (pending→pending_l2→approved); updates balance on final approval
reject(LeaveApplication $app, int $approverId, string $remarks): LeaveApplication
    // Writes hrs_leave_approvals; sets status=rejected
returnForClarification(LeaveApplication $app, int $approverId, string $remarks): LeaveApplication
    // Sets status=returned; employee can resubmit
resolveApproverForLevel(LeaveApplication $app, int $level): Employee
    // Level 1 = employee's HOD; Level 2 = Principal
```

---

### 2.4 HolidayService

**File:** `Services/HolidayService.php`
**Dependencies:** none

```php
getHolidaysForRange(int $academicYearId, Carbon $from, Carbon $to, string $applicableTo): Collection
    // Returns hrs_holiday_calendars rows; used by LeaveService::calculateDays()
getWorkingDaysInMonth(Carbon $month, string $applicableTo): int
    // Used by PayrollComputationService for LWP calculation
syncCalendar(int $academicYearId, array $holidays): void
    // Bulk upsert hrs_holiday_calendars (used on year-copy)
```

---

### 2.5 SalaryAssignmentService

**File:** `Services/SalaryAssignmentService.php`
**Dependencies:** none

```php
assign(int $employeeId, array $data): SalaryAssignment
    // Closes prior active assignment (sets effective_to_date); creates new row in hrs_salary_assignments
validateCtcInGrade(float $ctc, int $payGradeId): bool
    // Checks min_ctc ≤ ctc ≤ max_ctc; BR-HRS-011
revise(int $employeeId, array $data): SalaryAssignment
    // Same as assign(); creates employment history entry with change_type='salary_revision'
getActiveAssignment(int $employeeId): ?SalaryAssignment
    // Returns hrs_salary_assignments where effective_to_date IS NULL
```

---

### 2.6 ComplianceService

**File:** `Services/ComplianceService.php`
**Dependencies:** none

```php
upsert(int $employeeId, string $complianceType, array $data): ComplianceRecord
    // Upserts hrs_compliance_records; encrypts PAN for TDS type
getRegister(string $type, int $month, int $year): Collection
    // Returns hrs_pf_contribution_register or hrs_esi_contribution_register for given period
computeContributions(int $month, int $year): void
    // Reads payroll run details; writes/updates contribution registers
exportPfForm12A(int $month, int $year): BinaryFileResponse
    // Generates PDF of PF Form 12A
exportEsiForm5(int $half, int $year): BinaryFileResponse
    // Generates PDF/CSV of ESI Form 5 (half-yearly)
```

---

### 2.7 AppraisalService

**File:** `Services/AppraisalService.php`
**Dependencies:** none
**Events Fired:** `AppraisalFinalized`

```php
createCycle(array $data): AppraisalCycle
submitSelfAppraisal(int $appraisalId, array $ratingJson, string $comments): Appraisal
    // Validates KPI weights sum to 100; locks form (status→submitted)
submitManagerReview(int $appraisalId, array $ratingJson, string $comments): Appraisal
    // Status→reviewed
finalize(int $appraisalId, ?float $hrAdjustment, string $remarks): Appraisal
    // Computes overall_rating (weighted avg); applies ±10% HR tolerance cap; status→finalized
    // Creates hrs_appraisal_increment_flags (flag_status=pending)
computeOverallRating(Appraisal $appraisal): float
    // Weighted average from reviewer_rating_json × item weights
```

---

### 2.8 IdCardService

**File:** `Services/IdCardService.php`
**Dependencies:** `sys_media` (via Media model)

```php
generate(int $employeeId): Payslip
    // Renders DomPDF from hrs_id_card_templates layout_json; stores in sys_media; returns media record
getTemplate(bool $default = true): IdCardTemplate
getQrData(Employee $employee): string
    // Returns emp_code for QR encoding
```

---

### 2.9 SalaryStructureService

**File:** `Services/SalaryStructureService.php`
**Dependencies:** none

```php
createStructure(array $data): SalaryStructure
    // Creates pay_salary_structures + pay_salary_structure_components; validates BASIC present (BR-PAY-011)
updateComponents(int $structureId, array $components): void
    // Replaces junction records; re-validates BASIC present
previewCtcBreakdown(int $structureId, float $ctc): array
    // Returns per-component amounts given a CTC; used by salary structure builder live preview
    // Returns: ['earnings' => [...], 'deductions' => [...], 'net' => float]
```

---

### 2.10 PayrollComputationService

**File:** `Services/PayrollComputationService.php`
**Dependencies:** `HolidayService`, `TdsComputationService`
**Called by:** `PayrollRunService`, `ProcessPayrollJob`

```php
computeRun(PayrollRun $run): void
    // Iterates all active employees; calls computeEmployee(); updates run totals

computeEmployee(PayrollRun $run, Employee $emp): PayrollRunDetail
    /*
     * Step 1: Resolve hrs_salary_assignments (latest where effective_to_date IS NULL)
     * Step 2: Calculate gross earnings per pay_salary_structure_components formula
     *         — fixed: use default_value from assignment's component breakdown
     *         — percentage_of_basic: (basic × percentage / 100)
     *         — statutory / manual: 0 at gross stage (computed in deduction steps)
     * Step 3: LWP deduction = (gross_monthly / working_days_in_month) × lop_days
     *         lop_days from confirmed hrs_lop_records for this employee+month
     *         working_days_in_month from HolidayService::getWorkingDaysInMonth()
     * Step 4: PF employee = 12% of (basic + DA) if compliance.pf.applicable_flag = true
     *         PF employer: EPF 3.67% + EPS 8.33% of (basic + DA)
     * Step 5: ESI employee = 0.75% of gross_after_lwp if gross_after_lwp ≤ 21000
     *         ESI employer = 3.25% of gross_after_lwp (same eligibility)
     * Step 6: PT = slab lookup from hrs_pt_slabs by state_code in compliance.pt.details_json
     * Step 7: TDS = TdsComputationService::computeMonthlyTds($emp, $month, $year)
     * Step 8: net_pay = gross_after_lwp − pf_emp − esi_emp − pt − tds
     *         Write: pay_payroll_run_details row + pay_tds_ledger upsert (YTD tracking)
     */

recomputeEmployee(PayrollRunDetail $detail): PayrollRunDetail
    // Re-runs computeEmployee() for a single employee (used after manual override correction)
```

---

### 2.11 TdsComputationService

**File:** `Services/TdsComputationService.php`
**Dependencies:** none

```php
computeMonthlyTds(Employee $emp, int $month, int $year): float
    // Projects annual income for financial year; deducts exemptions (80C, HRA, LTA);
    // applies tax slab (old or new regime per compliance record);
    // distributes remaining tax equally over remaining months;
    // floors at 0 (BR-PAY-006)

getProjectedAnnualIncome(Employee $emp, string $financialYear): float
    // YTD gross (from pay_tds_ledger) + projected future months × current gross_monthly

generateForm16(Employee $emp, string $financialYear): BinaryFileResponse
    // Builds Part A (employer details + TDS deducted month-wise from pay_tds_ledger)
    // Builds Part B (salary breakdown + exemptions + total tax)
    // Renders DomPDF; stores in pay_form16 + sys_media
```

---

### 2.12 PayrollRunService

**File:** `Services/PayrollRunService.php`
**Dependencies:** `PayrollComputationService`
**Events Fired:** `PayrollApproved`, `PayrollLocked`

```php
initiate(array $data, int $initiatedBy): PayrollRun
    // Validates no duplicate regular run for payroll_month (BR-PAY-001); creates draft run
compute(PayrollRun $run): void
    // Pre-condition checks (all LOP confirmed, all employees have assignment — BR-PAY-002);
    // sets status=computing; dispatches ProcessPayrollJob if >100 employees, else runs sync
approve(PayrollRun $run, int $approverId): void
    // status: reviewing → approved
lock(PayrollRun $run): void
    // status: approved → locked; fires PayrollLocked; updates pf/esi register status
createSupplementaryRun(int $parentRunId, array $data): PayrollRun
    // Creates supplementary run referencing parent_run_id (BR-PAY-008)
```

---

### 2.13 PayslipService

**File:** `Services/PayslipService.php`
**Dependencies:** `TdsComputationService`

```php
generate(PayrollRunDetail $detail): Payslip
    // Renders payslip blade template via DomPDF; password-protects PDF;
    // stores in sys_media; upserts pay_payslips
generateAllForRun(PayrollRun $run): void
    // Dispatches GeneratePayslipsJob($run)
getPasswordForEmployee(Employee $emp): string
    // Returns PANlast4 + DDYYYY(DOB) — NFR-007; e.g. '1234R01041980'
emailPayslip(Payslip $payslip): void
    // Dispatches SendPayslipEmailJob; updates email_status
```

---

### 2.14 StatutoryExportService

**File:** `Services/StatutoryExportService.php`
**Dependencies:** none

```php
exportBankFile(PayrollRun $run, string $format = 'csv'): BinaryFileResponse
    // Validates status=approved (BR-PAY-007); generates bank NEFT file
    // Columns: EmpCode, Name, AccountNumber, IFSC, BankName, Amount
    // Updates payment_status=exported on all run_details
exportPfEcr(PayrollRun $run): BinaryFileResponse
    // Generates EPFO ECR v2 format flat file; reads hrs_pf_contribution_register
exportEsiChallan(PayrollRun $run): BinaryFileResponse
    // Generates ESI contribution challan; reads hrs_esi_contribution_register
```

---

### 2.15 IncrementService

**File:** `Services/IncrementService.php`
**Dependencies:** `SalaryAssignmentService`

```php
getProposals(int $cycleId): Collection
    // Reads hrs_appraisal_increment_flags (pending); fetches appraisal overall_rating;
    // matches rating to pay_increment_policies; returns proposed new CTC per employee
processIncrements(int $cycleId, array $approved): void
    // For each approved employee: calls SalaryAssignmentService::revise();
    // marks hrs_appraisal_increment_flags.flag_status = processed
applyAdHocRevision(int $employeeId, array $revisionData): SalaryAssignment
    // Wraps SalaryAssignmentService::revise(); logs reason
```

---

## Section 3 — FormRequest Inventory (30 FormRequests)

All FormRequests: `Modules\HrStaff\Http\Requests\`

---

### Employment & Documents (3)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `StoreEmploymentDetailRequest` | EmploymentController@store | `contract_type` in enum; `bank_account_number` required|string; `ifsc_code` regex:`/^[A-Z]{4}0[A-Z0-9]{6}$/`; `emergency_contact_phone` digits:10 |
| `UpdateEmploymentDetailRequest` | EmploymentController@update | Same as store; all fields `sometimes` (partial update allowed) |
| `StoreDocumentRequest` | DocumentController@store | `document_type` in enum; `media_id` exists:sys_media; `expiry_date` nullable\|date\|after:today; `issued_date` required\|date |

---

### Leave Management (7)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `StoreLeaveTypeRequest` | LeaveTypeController@store | `code` unique:hrs_leave_types\|max:10; `days_per_year` min:0; `applicable_to` in enum; `gender_restriction` in enum |
| `UpdateLeaveTypeRequest` | LeaveTypeController@update | Same as store; `code` unique ignore current |
| `StoreHolidayRequest` | HolidayController@store | `holiday_date` required\|date; `holiday_type` in enum; unique (holiday_date, academic_year_id) |
| `UpdateHolidayRequest` | HolidayController@update | Same as store; unique ignore current |
| `UpdateLeavePolicyRequest` | LeaveController@updatePolicy | `max_backdated_days` integer\|min:0\|max:30; `approval_levels` in:[1,2]; `min_advance_days` integer\|min:0 |
| `InitializeLeaveBalancesRequest` | LeaveController@initializeBalances | `academic_year_id` required\|exists:sch_org_academic_sessions_jnt,id |
| `StoreLeaveApplicationRequest` | LeaveApplicationController@store | `leave_type_id` exists; `from_date` required\|date; `to_date` required\|date\|after_or_equal:from_date; `half_day_session` required_if:half_day,1; custom rule: balance sufficient; custom rule: no overlap with approved leave |

---

### Leave Approval (2)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `ApproveLeaveRequest` | LeaveApplicationController@approve | `remarks` required\|string\|min:5 (BR-HRS-024) |
| `RejectLeaveRequest` | LeaveApplicationController@reject | `remarks` required\|string\|min:5 |

---

### LOP (1)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `ConfirmLopRequest` | LopController@confirm | `lop_record_ids` required\|array; `lop_record_ids.*` exists:hrs_lop_records,id; `action` required\|in:confirmed,waived |

---

### Salary & Pay Grades (5)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `StorePayGradeRequest` | PayGradeController@store | `grade_name` required\|unique:hrs_pay_grades; `min_ctc` required\|numeric\|min:0; `max_ctc` required\|numeric\|gt:min_ctc |
| `UpdatePayGradeRequest` | PayGradeController@update | Same; `grade_name` unique ignore current |
| `StoreSalaryAssignmentRequest` | SalaryAssignmentController@store | `pay_salary_structure_id` exists\|active; `pay_grade_id` exists; `ctc_amount` numeric; custom rule: CTC within grade min/max (BR-HRS-011); `effective_from_date` required\|date |
| `UpdateSalaryAssignmentRequest` | SalaryAssignmentController@update | Same as store; all fields sometimes |
| `StoreSalaryRevisionRequest` | SalaryAssignmentController@revision | Same as StoreSalaryAssignmentRequest; `revision_reason` required\|string\|min:10 |

---

### Compliance (2)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `StoreComplianceRecordRequest` | ComplianceController@store | `compliance_type` required\|in enum; `reference_number` required (PAN regex for TDS: `/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/`); `enrollment_date` required\|date; `details_json` required_if:compliance_type,tds — must contain `regime` in:[old,new] |
| `UpdateComplianceRecordRequest` | ComplianceController@update | Same; all fields sometimes |

---

### Salary Structure (4)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `StoreSalaryComponentRequest` | SalaryComponentController@store | `code` unique:pay_salary_components\|max:30\|uppercase; `component_type` in enum; `calculation_type` in enum; `default_value` numeric\|min:0 |
| `UpdateSalaryComponentRequest` | SalaryComponentController@update | Same; `code` unique ignore current |
| `StoreSalaryStructureRequest` | SalaryStructureController@store | `name` required\|unique:pay_salary_structures; `applicable_to` in enum; `components` required\|array\|min:1; custom rule: BASIC code must be present (BR-PAY-011); `components.*.component_id` exists:pay_salary_components,id; `components.*.sequence_order` integer\|min:1 |
| `UpdateSalaryStructureRequest` | SalaryStructureController@update | Same; `name` unique ignore current |

---

### Appraisal (3)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `StoreKpiTemplateRequest` | AppraisalController@kpiStore/kpiUpdate | `name` required; `rating_scale` in:[5,10]; `items` required\|array\|min:1; `items.*.weight` numeric\|min:1; custom rule: `items.*.weight` must sum to 100 (BR-HRS-016) |
| `StoreAppraisalCycleRequest` | AppraisalController@cycleStore/cycleUpdate | `appraisal_type` in enum; `kpi_template_id` exists; `self_close_date` after:self_open_date; `manager_open_date` after_or_equal:self_close_date (BR-HRS-018); `manager_close_date` after:manager_open_date |
| `SubmitSelfAppraisalRequest` | AppraisalController@submitSelf | `ratings` required\|array; `ratings.*.kpi_item_id` exists; `ratings.*.score` numeric\|min:1; `self_comments` required\|string\|min:20 |
| `SubmitReviewRequest` | AppraisalController@submitReview | Same as SubmitSelfAppraisalRequest; `reviewer_comments` required |

---

### Payroll (3)

| Class | Controller@method | Key Validation Rules |
|---|---|---|
| `StorePayrollRunRequest` | PayrollController@store | `payroll_month` required\|regex:/^\d{4}-(0[1-9]\|1[0-2])$/; `run_type` in:[regular,supplementary]; custom rule: no existing regular run for month (BR-PAY-001); `parent_run_id` required_if:run_type,supplementary\|exists:pay_payroll_runs,id (BR-PAY-008) |
| `OverridePayrollDetailRequest` | PayrollController@override | `field_name` required\|in:[net_pay,tds_deducted,other_deductions]; `override_value` required\|numeric\|min:0 (BR-PAY-006 — no negative TDS); `reason` required\|string\|min:10 (BR-PAY-005) |
| `StoreIncrementPolicyRequest` | IncrementController@policyStore/policyUpdate | `min_rating` required\|numeric\|min:0; `max_rating` required\|numeric\|gt:min_rating; custom rule: rating range must not overlap with existing policies for same cycle (prompt spec); `increment_type` in:[percentage,flat]; `increment_value` required\|numeric\|min:0 |

---

**Total: 30 FormRequests** (StoreEmploymentDetail, UpdateEmploymentDetail, StoreDocument, StoreLeaveType, UpdateLeaveType, StoreHoliday, UpdateHoliday, UpdateLeavePolicy, InitializeLeaveBalances, StoreLeaveApplication, ApproveLeave, RejectLeave, ConfirmLop, StorePayGrade, UpdatePayGrade, StoreSalaryAssignment, UpdateSalaryAssignment, StoreSalaryRevision, StoreComplianceRecord, UpdateComplianceRecord, StoreSalaryComponent, UpdateSalaryComponent, StoreSalaryStructure, UpdateSalaryStructure, StoreKpiTemplate, StoreAppraisalCycle, SubmitSelfAppraisal, SubmitReview, StorePayrollRun, OverridePayrollDetail)

---

## Section 4 — Blade View Inventory (~110 views)

All views: `modules/HrStaff/Resources/views/`
All layouts extend `layouts.tenant`

### 4.1 Employment & Documents (~8)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `employment/show.blade.php` | `hr-staff.employment.show` | EmploymentController@show | Tabbed: Employment / Documents / Compliance / History |
| `employment/edit.blade.php` | — | EmploymentController@show (modal) | Edit employment details form (AJAX modal) |
| `employment/history.blade.php` | `hr-staff.history.index` | EmploymentController@history | Timeline of contract/dept/salary changes |
| `documents/index.blade.php` | `hr-staff.documents.index` | DocumentController@index | Document list; expiry-coded color badges |
| `documents/create.blade.php` | — | DocumentController@index (modal) | Upload form with media dropzone |
| `documents/_document_card.blade.php` | — | — | Document card partial (type icon + expiry badge) |
| `employment/_tabs.blade.php` | — | — | Tab navigation partial (reused across employee sub-pages) |
| `documents/_expiry_badge.blade.php` | — | — | Color-coded expiry: green >90d, amber 30–90d, red <30d |

---

### 4.2 ID Cards (~3)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `id-card/show.blade.php` | `hr-staff.id-card.show` | IdCardController@show | Rendered card preview + Generate PDF button |
| `id-card/templates/index.blade.php` | — | — | Template list (admin screen) |
| `id-card/_card_preview.blade.php` | — | — | Card render partial (used in show + template preview) |

---

### 4.3 Leave Management (~15)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `leave-types/index.blade.php` | `hr-staff.leave-types.index` | LeaveTypeController@index | CRUD grid; enable/disable toggle |
| `leave-types/create.blade.php` | `hr-staff.leave-types.create` | — | Create form |
| `leave-types/edit.blade.php` | `hr-staff.leave-types.edit` | — | Edit form |
| `holidays/index.blade.php` | `hr-staff.holidays.index` | HolidayController@index | Month-view calendar; add/edit modal |
| `holidays/create.blade.php` | — | — | Add holiday form (rendered as modal) |
| `holidays/edit.blade.php` | — | — | Edit holiday form |
| `leave-policy/show.blade.php` | `hr-staff.leave-policy.show` | LeaveController@policy | Policy view/edit inline |
| `leave-balances/index.blade.php` | `hr-staff.balances.index` | LeaveController@balances | Matrix: employees × leave types; dept filter |
| `leave-balances/_balance_card.blade.php` | — | — | Employee self-service: single leave type balance card |
| `leave-applications/index.blade.php` | `hr-staff.applications.index` | LeaveApplicationController@index | Application list; tab: my / pending approvals |
| `leave-applications/create.blade.php` | `hr-staff.applications.create` | — | Application form; date picker; live day count |
| `leave-applications/show.blade.php` | `hr-staff.applications.show` | LeaveApplicationController@show | Application detail + approval action timeline |
| `leave-applications/pending.blade.php` | — | — | Pending approvals dashboard (L1/L2 tabs) |
| `lop/index.blade.php` | `hr-staff.lop.index` | LopController@index | Month selector; flag/confirm/waive action table |
| `lop/_lop_row.blade.php` | — | — | LOP record row partial (inline action buttons) |

---

### 4.4 Compliance (~8)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `compliance/index.blade.php` | — | ComplianceController@show (index) | Employee list; PF/ESI/TDS/PT status badges |
| `compliance/show.blade.php` | `hr-staff.compliance.show` | ComplianceController@show | Per-employee tabs: PF / ESI / TDS / Gratuity / PT |
| `compliance/pf/edit.blade.php` | — | — | PF enrollment form |
| `compliance/esi/edit.blade.php` | — | — | ESI enrollment form |
| `compliance/tds/edit.blade.php` | — | — | TDS declaration + investment form (80C, 80D, HRA) |
| `compliance/gratuity/edit.blade.php` | — | — | Gratuity record + eligibility display |
| `compliance/pf-register.blade.php` | `hr-staff.compliance.pf-register` | ComplianceController@pfRegister | PF contribution register table |
| `compliance/esi-register.blade.php` | `hr-staff.compliance.esi-register` | ComplianceController@esiRegister | ESI contribution register table |

---

### 4.5 Salary & Pay Grades (~10)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `pay-grades/index.blade.php` | `hr-staff.pay-grades.index` | PayGradeController@index | Pay grade CRUD grid |
| `pay-grades/create.blade.php` | `hr-staff.pay-grades.create` | — | Create form |
| `pay-grades/edit.blade.php` | `hr-staff.pay-grades.edit` | — | Edit form |
| `pay-grades/show.blade.php` | `hr-staff.pay-grades.show` | PayGradeController@show | Detail with assigned employees count |
| `salary-assignment/show.blade.php` | `hr-staff.salary.show` | SalaryAssignmentController@show | Current assignment card + revision history timeline |
| `salary-assignment/edit.blade.php` | `hr-staff.salary.edit` | — | Assign salary form; pay grade selector |
| `salary-assignment/create.blade.php` | `hr-staff.salary.create` | — | First-time assignment form |
| `salary-assignment/history.blade.php` | — | — | Full revision timeline partial |
| `salary-assignment/_revision_row.blade.php` | — | — | Revision row partial |
| `pay-grades/_grade_card.blade.php` | — | — | Pay grade card partial |

---

### 4.6 Appraisal (~12)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `kpi-templates/index.blade.php` | `hr-staff.kpi-templates.index` | AppraisalController@kpiIndex | Template list with applicable_to badges |
| `kpi-templates/create.blade.php` | `hr-staff.kpi-templates.create` | — | Template + items form (dynamic rows, weight sum validator) |
| `kpi-templates/edit.blade.php` | `hr-staff.kpi-templates.edit` | — | Edit template |
| `kpi-templates/show.blade.php` | `hr-staff.kpi-templates.show` | AppraisalController@kpiShow | Template detail with KPI items table |
| `appraisal-cycles/index.blade.php` | `hr-staff.cycles.index` | AppraisalController@cycleIndex | Cycle cards with completion progress bars |
| `appraisal-cycles/create.blade.php` | `hr-staff.cycles.create` | — | Create cycle form |
| `appraisal-cycles/edit.blade.php` | `hr-staff.cycles.edit` | — | Edit cycle (date windows) |
| `appraisals/index.blade.php` | `hr-staff.appraisals.index` | AppraisalController@index | Appraisal list for cycle; per-employee status |
| `appraisals/self.blade.php` | `hr-staff.appraisals.self` | — | Self-appraisal: KPI grid with rating sliders + comments |
| `appraisals/review.blade.php` | `hr-staff.appraisals.review` | — | Manager review: side-by-side self vs manager per KPI |
| `appraisals/show.blade.php` | `hr-staff.appraisals.show` | AppraisalController@show | Finalized appraisal; overall rating; HR remarks |
| `appraisals/_kpi_row.blade.php` | — | — | KPI rating row partial (reused in self/review forms) |

---

### 4.7 Salary Structure (~8)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `salary-components/index.blade.php` | `hr-staff.salary-components.index` | SalaryComponentController@index | Component grid: type/calculation badges |
| `salary-components/create.blade.php` | `hr-staff.salary-components.create` | — | Create component form |
| `salary-components/edit.blade.php` | `hr-staff.salary-components.edit` | — | Edit component form |
| `salary-structures/index.blade.php` | `hr-staff.salary-structures.index` | SalaryStructureController@index | Structure list; applicable_to badge |
| `salary-structures/create.blade.php` | `hr-staff.salary-structures.create` | — | Create structure + component composition |
| `salary-structures/edit.blade.php` | `hr-staff.salary-structures.edit` | SalaryStructureController@show | Structure builder: drag-and-drop component sequence; live CTC preview via `fetch(/preview)` |
| `salary-structures/show.blade.php` | `hr-staff.salary-structures.show` | SalaryStructureController@show | Read-only structure detail |
| `salary-structures/_ctc_preview.blade.php` | — | — | Live CTC breakdown partial (re-rendered by JS on component change) |

---

### 4.8 Payroll Runs (~12)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `payroll/index.blade.php` | `hr-staff.payroll.index` | PayrollController@index | Run history cards; initiate new run button |
| `payroll/create.blade.php` | `hr-staff.payroll.create` | — | Initiate run form (month selector, run_type) |
| `payroll/show.blade.php` | `hr-staff.payroll.show` | PayrollController@show | Status timeline; employee-wise computation table; totals |
| `payroll/details.blade.php` | `hr-staff.payroll.details` | PayrollController@details | Sortable grid; override button per row; override rows highlighted orange |
| `payroll/status.blade.php` | — | — | Compute status polling view: polls `/payroll/{run}/status` every 3s |
| `payroll/supplementary/create.blade.php` | — | — | Supplementary run form |
| `payroll/supplementary/show.blade.php` | — | — | Supplementary run detail |
| `payroll/_run_card.blade.php` | — | — | Run summary card partial |
| `payroll/_employee_row.blade.php` | — | — | Employee detail row partial |
| `payroll/_status_badge.blade.php` | — | — | FSM status badge with color |
| `payroll/_override_modal.blade.php` | — | — | Override AJAX modal partial |
| `payroll/_totals_bar.blade.php` | — | — | Total gross/net/deductions summary bar |

---

### 4.9 Payslips (~8)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `payslips/index.blade.php` | — | PayslipController (list) | Employee × month grid; generate/email/download per row |
| `payslips/generate-all.blade.php` | `hr-staff.payslips.generate-all` | PayslipController@generateAll | Bulk generate with progress bar (polls GeneratePayslipsJob) |
| `payslips/email-options.blade.php` | — | — | Email dispatch options modal |
| `payslips/payslip-template.blade.php` | — | — | DomPDF payslip template (not a route; rendered by PayslipService) |
| `payslips/_progress_bar.blade.php` | — | — | Bulk job progress bar partial |
| `my-payslips/index.blade.php` | `hr-staff.my-payslips.index` | PayslipController@myPayslips | Self-service list of downloadable payslips |
| `my-payslips/show.blade.php` | — | — | Payslip preview (embedded PDF) |
| `payslips/_payslip_row.blade.php` | — | — | Payslip list row partial |

---

### 4.10 Statutory Exports (~4)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `statutory/pf-ecr.blade.php` | `hr-staff.payroll.pf-ecr` | StatutoryController@pfEcr | PF ECR export preview + download button |
| `statutory/esi-challan.blade.php` | `hr-staff.payroll.esi-challan` | StatutoryController@esiChallan | ESI challan export form |
| `statutory/bank-file.blade.php` | `hr-staff.payroll.bank-file` | PayrollController@bankFile | Bank file export with format selector (CSV/TXT) |
| `statutory/_export_summary.blade.php` | — | — | Export summary: employee count, total amount |

---

### 4.11 Form 16 (~4)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `form16/index.blade.php` | `hr-staff.form16.index` | Form16Controller@index | Financial year selector; employee list with generate/download |
| `form16/generate-all.blade.php` | `hr-staff.form16.generate-all` | Form16Controller@generateAll | Bulk generation status (dispatches GenerateForm16Job) |
| `form16/form16-template.blade.php` | — | — | DomPDF Form 16 template (Part A + Part B) |
| `my-form16/index.blade.php` | `hr-staff.my-form16.download` | Form16Controller@download | Self-service: download Form 16 per financial year |

---

### 4.12 Increments (~6)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `increment-policies/index.blade.php` | `hr-staff.increment-policies.index` | IncrementController@policyIndex | Policy list; rating range → increment% mapping |
| `increment-policies/create.blade.php` | `hr-staff.increment-policies.create` | — | Create policy form (rating range + increment_type + value) |
| `increment-policies/edit.blade.php` | `hr-staff.increment-policies.edit` | — | Edit policy form |
| `increments/index.blade.php` | `hr-staff.increments.index` | IncrementController@index | Pending increment proposals table (from appraisal flags) |
| `increments/process.blade.php` | `hr-staff.increments.process` | — | Batch process confirmation: proposed new CTC per employee |
| `increments/_proposal_row.blade.php` | — | — | Increment proposal row partial |

---

### 4.13 Payroll Reports (~12)

| View File | Route Name | Controller@method | Description |
|---|---|---|---|
| `reports/index.blade.php` | — | — | Reports hub / navigation cards |
| `reports/salary-register.blade.php` | `hr-staff.reports.salary-register` | PayrollReportController@salaryRegister | Monthly salary register; dept/month filter; PDF+Excel export |
| `reports/bank-summary.blade.php` | `hr-staff.reports.bank-summary` | PayrollReportController@bankSummary | Bank transfer summary; branch-wise grouping |
| `reports/ctc-analysis.blade.php` | `hr-staff.reports.ctc-analysis` | PayrollReportController@ctcAnalysis | CTC vs gross vs net comparison chart + table |
| `reports/trend.blade.php` | `hr-staff.reports.payroll-trend` | PayrollReportController@trend | 12-month trend line chart; dept drilldown |
| `reports/salary-register-pdf.blade.php` | — | — | PDF template for salary register |
| `reports/bank-summary-pdf.blade.php` | — | — | PDF template for bank summary |
| `reports/ctc-analysis-pdf.blade.php` | — | — | PDF template for CTC analysis |
| `reports/_filter_bar.blade.php` | — | — | Month/dept/designation filter bar partial |
| `reports/_export_buttons.blade.php` | — | — | PDF + Excel + CSV export dropdown partial |
| `reports/_chart_container.blade.php` | — | — | Chart.js container partial |
| `reports/_pagination.blade.php` | — | — | Report-specific pagination partial |

---

### 4.14 Shared Partials (~8)

| View File | Description |
|---|---|
| `_partials/modal.blade.php` | Generic modal wrapper (header, body slot, footer buttons) |
| `_partials/confirm_delete.blade.php` | Delete confirmation modal with CSRF-aware form |
| `_partials/empty_state.blade.php` | Empty state card (icon + message + optional CTA) |
| `_partials/status_badge.blade.php` | Generic FSM status badge (color map by status string) |
| `_partials/export_dropdown.blade.php` | CSV/PDF/Excel export dropdown button group |
| `_partials/pagination.blade.php` | Standard pagination with 25/50/100 per-page selector |
| `_partials/alert_flash.blade.php` | Session flash messages (success/error/warning) |
| `_partials/table_header.blade.php` | Sortable column header with sort icon partial |

---

**Total: ~110 views** (8 + 3 + 15 + 8 + 10 + 12 + 8 + 12 + 8 + 4 + 4 + 6 + 12 + 8 = 118 including partials)

---

## Section 5 — Complete Route List

**File:** `routes/tenant.php`
**Middleware (all routes):** `['auth', 'tenant', 'EnsureTenantHasModule:HrStaff']`
**Route prefix:** `hr-staff/`

### 7.1 — Staff HR Records

| Method | URI | Route Name | Controller@method | FR |
|---|---|---|---|---|
| GET | `hr-staff/employees/{emp}/hr` | `hr-staff.employment.show` | EmploymentController@show | HRS-001 |
| POST | `hr-staff/employees/{emp}/hr` | `hr-staff.employment.store` | EmploymentController@store | HRS-001 |
| PUT | `hr-staff/employees/{emp}/hr` | `hr-staff.employment.update` | EmploymentController@update | HRS-001 |
| GET | `hr-staff/employees/{emp}/history` | `hr-staff.history.index` | EmploymentController@history | HRS-002 |
| GET | `hr-staff/employees/{emp}/documents` | `hr-staff.documents.index` | DocumentController@index | HRS-003 |
| POST | `hr-staff/employees/{emp}/documents` | `hr-staff.documents.store` | DocumentController@store | HRS-003 |
| DELETE | `hr-staff/documents/{doc}` | `hr-staff.documents.destroy` | DocumentController@destroy | HRS-003 |
| GET | `hr-staff/employees/{emp}/id-card` | `hr-staff.id-card.show` | IdCardController@show | HRS-004 |
| POST | `hr-staff/employees/{emp}/id-card/generate` | `hr-staff.id-card.generate` | IdCardController@generate | HRS-004 |

**Section subtotal: 9 routes**

### 7.2 — Leave Management

| Method | URI | Route Name | Controller@method | FR |
|---|---|---|---|---|
| GET | `hr-staff/leave-types` | `hr-staff.leave-types.index` | LeaveTypeController@index | HRS-005 |
| POST | `hr-staff/leave-types` | `hr-staff.leave-types.store` | LeaveTypeController@store | HRS-005 |
| GET | `hr-staff/leave-types/{id}` | `hr-staff.leave-types.show` | LeaveTypeController@show | HRS-005 |
| PUT | `hr-staff/leave-types/{id}` | `hr-staff.leave-types.update` | LeaveTypeController@update | HRS-005 |
| DELETE | `hr-staff/leave-types/{id}` | `hr-staff.leave-types.destroy` | LeaveTypeController@destroy | HRS-005 |
| GET | `hr-staff/holidays` | `hr-staff.holidays.index` | HolidayController@index | HRS-006 |
| POST | `hr-staff/holidays` | `hr-staff.holidays.store` | HolidayController@store | HRS-006 |
| GET | `hr-staff/holidays/{id}` | `hr-staff.holidays.show` | HolidayController@show | HRS-006 |
| PUT | `hr-staff/holidays/{id}` | `hr-staff.holidays.update` | HolidayController@update | HRS-006 |
| DELETE | `hr-staff/holidays/{id}` | `hr-staff.holidays.destroy` | HolidayController@destroy | HRS-006 |
| GET | `hr-staff/leave-policy` | `hr-staff.leave-policy.show` | LeaveController@policy | HRS-007 |
| PUT | `hr-staff/leave-policy` | `hr-staff.leave-policy.update` | LeaveController@updatePolicy | HRS-007 |
| POST | `hr-staff/leave-balances/initialize` | `hr-staff.balances.initialize` | LeaveController@initializeBalances | HRS-008 |
| GET | `hr-staff/leave-balances` | `hr-staff.balances.index` | LeaveController@balances | HRS-011 |
| GET | `hr-staff/leave-applications` | `hr-staff.applications.index` | LeaveApplicationController@index | HRS-009 |
| POST | `hr-staff/leave-applications` | `hr-staff.applications.store` | LeaveApplicationController@store | HRS-009 |
| GET | `hr-staff/leave-applications/{app}` | `hr-staff.applications.show` | LeaveApplicationController@show | HRS-010 |
| POST | `hr-staff/leave-applications/{app}/approve` | `hr-staff.applications.approve` | LeaveApplicationController@approve | HRS-010 |
| POST | `hr-staff/leave-applications/{app}/reject` | `hr-staff.applications.reject` | LeaveApplicationController@reject | HRS-010 |
| POST | `hr-staff/leave-applications/{app}/cancel` | `hr-staff.applications.cancel` | LeaveApplicationController@cancel | HRS-010 |
| GET | `hr-staff/lop-reconciliation` | `hr-staff.lop.index` | LopController@index | HRS-012 |
| POST | `hr-staff/lop-reconciliation/confirm` | `hr-staff.lop.confirm` | LopController@confirm | HRS-012 |

**Section subtotal: 22 routes**

### 7.3 — Salary Structures & Compliance

| Method | URI | Route Name | Controller@method | FR |
|---|---|---|---|---|
| GET | `hr-staff/pay-grades` | `hr-staff.pay-grades.index` | PayGradeController@index | HRS-013 |
| POST | `hr-staff/pay-grades` | `hr-staff.pay-grades.store` | PayGradeController@store | HRS-013 |
| GET | `hr-staff/pay-grades/{id}` | `hr-staff.pay-grades.show` | PayGradeController@show | HRS-013 |
| PUT | `hr-staff/pay-grades/{id}` | `hr-staff.pay-grades.update` | PayGradeController@update | HRS-013 |
| DELETE | `hr-staff/pay-grades/{id}` | `hr-staff.pay-grades.destroy` | PayGradeController@destroy | HRS-013 |
| GET | `hr-staff/employees/{emp}/salary` | `hr-staff.salary.show` | SalaryAssignmentController@show | HRS-014 |
| POST | `hr-staff/employees/{emp}/salary` | `hr-staff.salary.store` | SalaryAssignmentController@store | HRS-014 |
| PUT | `hr-staff/employees/{emp}/salary` | `hr-staff.salary.update` | SalaryAssignmentController@update | HRS-014 |
| GET | `hr-staff/employees/{emp}/compliance/{type}` | `hr-staff.compliance.show` | ComplianceController@show | HRS-015–018 |
| POST | `hr-staff/employees/{emp}/compliance/{type}` | `hr-staff.compliance.store` | ComplianceController@store | HRS-015–018 |
| PUT | `hr-staff/employees/{emp}/compliance/{type}` | `hr-staff.compliance.update` | ComplianceController@update | HRS-015–018 |
| GET | `hr-staff/compliance/pf-register` | `hr-staff.compliance.pf-register` | ComplianceController@pfRegister | HRS-015 |
| GET | `hr-staff/compliance/esi-register` | `hr-staff.compliance.esi-register` | ComplianceController@esiRegister | HRS-016 |
| GET | `hr-staff/salary-components` | `hr-staff.salary-components.index` | SalaryComponentController@index | HRS-023 |
| POST | `hr-staff/salary-components` | `hr-staff.salary-components.store` | SalaryComponentController@store | HRS-023 |
| GET | `hr-staff/salary-components/{id}` | `hr-staff.salary-components.show` | SalaryComponentController@show | HRS-023 |
| PUT | `hr-staff/salary-components/{id}` | `hr-staff.salary-components.update` | SalaryComponentController@update | HRS-023 |
| DELETE | `hr-staff/salary-components/{id}` | `hr-staff.salary-components.destroy` | SalaryComponentController@destroy | HRS-023 |
| GET | `hr-staff/salary-structures` | `hr-staff.salary-structures.index` | SalaryStructureController@index | HRS-024 |
| POST | `hr-staff/salary-structures` | `hr-staff.salary-structures.store` | SalaryStructureController@store | HRS-024 |
| GET | `hr-staff/salary-structures/{str}` | `hr-staff.salary-structures.show` | SalaryStructureController@show | HRS-024 |
| PUT | `hr-staff/salary-structures/{str}` | `hr-staff.salary-structures.update` | SalaryStructureController@update | HRS-024 |
| DELETE | `hr-staff/salary-structures/{str}` | `hr-staff.salary-structures.destroy` | SalaryStructureController@destroy | HRS-024 |
| GET | `hr-staff/salary-structures/{str}/preview` | `hr-staff.salary-structures.preview` | SalaryStructureController@preview | HRS-025 |

**Section subtotal: 24 routes**

### 7.4 — Appraisal

| Method | URI | Route Name | Controller@method | FR |
|---|---|---|---|---|
| GET | `hr-staff/kpi-templates` | `hr-staff.kpi-templates.index` | AppraisalController@kpiIndex | HRS-019 |
| POST | `hr-staff/kpi-templates` | `hr-staff.kpi-templates.store` | AppraisalController@kpiStore | HRS-019 |
| GET | `hr-staff/kpi-templates/{id}` | `hr-staff.kpi-templates.show` | AppraisalController@kpiShow | HRS-019 |
| PUT | `hr-staff/kpi-templates/{id}` | `hr-staff.kpi-templates.update` | AppraisalController@kpiUpdate | HRS-019 |
| DELETE | `hr-staff/kpi-templates/{id}` | `hr-staff.kpi-templates.destroy` | AppraisalController@kpiDestroy | HRS-019 |
| GET | `hr-staff/appraisal-cycles` | `hr-staff.cycles.index` | AppraisalController@cycleIndex | HRS-020 |
| POST | `hr-staff/appraisal-cycles` | `hr-staff.cycles.store` | AppraisalController@cycleStore | HRS-020 |
| GET | `hr-staff/appraisal-cycles/{id}` | `hr-staff.cycles.show` | AppraisalController@cycleShow | HRS-020 |
| PUT | `hr-staff/appraisal-cycles/{id}` | `hr-staff.cycles.update` | AppraisalController@cycleUpdate | HRS-020 |
| GET | `hr-staff/appraisals` | `hr-staff.appraisals.index` | AppraisalController@index | HRS-021 |
| GET | `hr-staff/appraisals/{apr}` | `hr-staff.appraisals.show` | AppraisalController@show | HRS-021 |
| POST | `hr-staff/appraisals/{apr}/submit-self` | `hr-staff.appraisals.submit-self` | AppraisalController@submitSelf | HRS-021 |
| POST | `hr-staff/appraisals/{apr}/submit-review` | `hr-staff.appraisals.submit-review` | AppraisalController@submitReview | HRS-022 |
| POST | `hr-staff/appraisals/{apr}/finalize` | `hr-staff.appraisals.finalize` | AppraisalController@finalize | HRS-022 |

**Section subtotal: 14 routes**

### 7.5 — Payroll Runs

| Method | URI | Route Name | Controller@method | FR |
|---|---|---|---|---|
| GET | `hr-staff/payroll` | `hr-staff.payroll.index` | PayrollController@index | HRS-026 |
| POST | `hr-staff/payroll` | `hr-staff.payroll.store` | PayrollController@store | HRS-026 |
| GET | `hr-staff/payroll/{run}` | `hr-staff.payroll.show` | PayrollController@show | HRS-027 |
| POST | `hr-staff/payroll/{run}/compute` | `hr-staff.payroll.compute` | PayrollController@compute | HRS-027 |
| GET | `hr-staff/payroll/{run}/details` | `hr-staff.payroll.details` | PayrollController@details | HRS-028 |
| PUT | `hr-staff/payroll/{run}/details/{detail}/override` | `hr-staff.payroll.override` | PayrollController@override | HRS-028 |
| POST | `hr-staff/payroll/{run}/submit` | `hr-staff.payroll.submit` | PayrollController@submit | HRS-029 |
| POST | `hr-staff/payroll/{run}/approve` | `hr-staff.payroll.approve` | PayrollController@approve | HRS-029 |
| POST | `hr-staff/payroll/{run}/lock` | `hr-staff.payroll.lock` | PayrollController@lock | HRS-029 |

**Section subtotal: 9 routes**

### 7.6 — Payslips

| Method | URI | Route Name | Controller@method | FR |
|---|---|---|---|---|
| POST | `hr-staff/payroll/{run}/payslips/generate` | `hr-staff.payslips.generate` | PayslipController@generate | HRS-031 |
| POST | `hr-staff/payroll/{run}/payslips/generate-all` | `hr-staff.payslips.generate-all` | PayslipController@generateAll | HRS-032 |
| POST | `hr-staff/payroll/{run}/payslips/email-all` | `hr-staff.payslips.email-all` | PayslipController@emailAll | HRS-033 |
| GET | `hr-staff/payroll/{run}/payslips/download-zip` | `hr-staff.payslips.download-zip` | PayslipController@downloadZip | HRS-032 |
| GET | `hr-staff/my-payslips` | `hr-staff.my-payslips.index` | PayslipController@myPayslips | HRS-034 |
| GET | `hr-staff/my-payslips/{payslip}/download` | `hr-staff.my-payslips.download` | PayslipController@download | HRS-034 |

**Section subtotal: 6 routes**

### 7.7 — Bank & Statutory

| Method | URI | Route Name | Controller@method | FR |
|---|---|---|---|---|
| GET | `hr-staff/payroll/{run}/bank-file` | `hr-staff.payroll.bank-file` | PayrollController@bankFile | HRS-035 |
| POST | `hr-staff/payroll/{run}/mark-paid` | `hr-staff.payroll.mark-paid` | PayrollController@markPaid | HRS-036 |
| GET | `hr-staff/payroll/{run}/pf-ecr` | `hr-staff.payroll.pf-ecr` | StatutoryController@pfEcr | HRS-039 |
| GET | `hr-staff/payroll/{run}/esi-challan` | `hr-staff.payroll.esi-challan` | StatutoryController@esiChallan | HRS-040 |
| GET | `hr-staff/form16/{year}` | `hr-staff.form16.index` | Form16Controller@index | HRS-038 |
| POST | `hr-staff/form16/{year}/generate-all` | `hr-staff.form16.generate-all` | Form16Controller@generateAll | HRS-038 |
| GET | `hr-staff/my-form16/{year}/download` | `hr-staff.my-form16.download` | Form16Controller@download | HRS-038 |

**Section subtotal: 7 routes**

### 7.8 — Increment & Payroll Reports

| Method | URI | Route Name | Controller@method | FR |
|---|---|---|---|---|
| GET | `hr-staff/increment-policies` | `hr-staff.increment-policies.index` | IncrementController@policyIndex | HRS-041 |
| POST | `hr-staff/increment-policies` | `hr-staff.increment-policies.store` | IncrementController@policyStore | HRS-041 |
| GET | `hr-staff/increment-policies/{id}` | `hr-staff.increment-policies.show` | IncrementController@policyShow | HRS-041 |
| PUT | `hr-staff/increment-policies/{id}` | `hr-staff.increment-policies.update` | IncrementController@policyUpdate | HRS-041 |
| GET | `hr-staff/increments` | `hr-staff.increments.index` | IncrementController@index | HRS-041 |
| POST | `hr-staff/increments/process` | `hr-staff.increments.process` | IncrementController@process | HRS-041 |
| POST | `hr-staff/employees/{emp}/salary-revision` | `hr-staff.salary.revision` | SalaryAssignmentController@revision | HRS-042 |
| GET | `hr-staff/reports/salary-register` | `hr-staff.reports.salary-register` | PayrollReportController@salaryRegister | HRS-043 |
| GET | `hr-staff/reports/bank-summary` | `hr-staff.reports.bank-summary` | PayrollReportController@bankSummary | HRS-044 |
| GET | `hr-staff/reports/ctc-analysis` | `hr-staff.reports.ctc-analysis` | PayrollReportController@ctcAnalysis | HRS-045 |
| GET | `hr-staff/reports/payroll-trend` | `hr-staff.reports.payroll-trend` | PayrollReportController@trend | HRS-046 |

**Section subtotal: 11 routes**

---

**Total routes: 9 + 22 + 24 + 14 + 9 + 6 + 7 + 11 = 102 routes**

---

## Section 6 — Implementation Phases

### Phase 1 — HR Foundation (Sprint 1–2)

**FRs:** HRS-001, HRS-003, HRS-005, HRS-006, HRS-008, HRS-009, HRS-010, HRS-011

**Files to create:**

| Category | Files |
|---|---|
| Controllers (6) | EmploymentController, DocumentController, LeaveTypeController, HolidayController, LeaveController, LeaveApplicationController |
| Services (4) | EmploymentService, LeaveService, LeaveApprovalService, HolidayService |
| Models (10) | EmploymentDetail, EmploymentHistory, EmployeeDocument, LeaveType, HolidayCalendar, LeavePolicy, LeaveBalance, LeaveBalanceAdjustment, LeaveApplication, LeaveApproval |
| FormRequests (10) | StoreEmploymentDetail, UpdateEmploymentDetail, StoreDocument, StoreLeaveType, UpdateLeaveType, StoreHoliday, UpdateHoliday, UpdateLeavePolicy, InitializeLeaveBalances, StoreLeaveApplication |
| Policies (4) | EmploymentPolicy, DocumentPolicy, LeaveTypePolicy, LeaveApplicationPolicy |
| Events (2) | LeaveApproved, LeaveRejected |
| Views (~23) | employment/show, edit, history; documents/index, create; id-card/show; leave-types CRUD (3); holidays CRUD (3); leave-policy/show; leave-balances/index; leave-applications index, create, show, pending; lop/index |
| Tests (3 files, 19 tests) | LeaveApplicationTest (8), LeaveApprovalTest (6), LeaveBalanceTest (5) |

**Key dependencies to verify before starting:**
`sch_employees` table exists; `sys_media` table exists; `att_staff_attendances` readable (cross-module read for LOP)

---

### Phase 2 — Compliance & Payroll Prep (Sprint 3–4)

**FRs:** HRS-004, HRS-012, HRS-013, HRS-014, HRS-015, HRS-016, HRS-017, HRS-018, HRS-023, HRS-024, HRS-025

**Files to create:**

| Category | Files |
|---|---|
| Controllers (7) | LopController, PayGradeController, SalaryAssignmentController, ComplianceController, SalaryComponentController, SalaryStructureController, IdCardController |
| Services (4) | SalaryAssignmentService, ComplianceService, IdCardService, SalaryStructureService |
| Models (10) | LopRecord, PayGrade, SalaryAssignment, ComplianceRecord, PfContributionRegister, EsiContributionRegister, PtSlab, SalaryComponent, SalaryStructure, SalaryStructureComponent |
| FormRequests (10) | ConfirmLop, StorePayGrade, UpdatePayGrade, StoreSalaryAssignment, UpdateSalaryAssignment, StoreSalaryRevision, StoreComplianceRecord, UpdateComplianceRecord, StoreSalaryComponent, UpdateSalaryComponent |
| Policies (3) | SalaryAssignmentPolicy, CompliancePolicy, SalaryStructurePolicy |
| Views (~29) | compliance: index, show, pf/edit, esi/edit, tds/edit, gratuity/edit, pf-register, esi-register (8); pay-grades: CRUD+show (4); salary-assignment: show, edit, create, history (4); salary-components: index, create, edit (3); salary-structures: index, create, edit, show, _ctc_preview (5); id-card: show, _card_preview, templates/index (3); lop/index, _lop_row (2) |
| Tests (3 files, 14 tests) | SalaryAssignmentTest (4), ComplianceRecordTest (5), SalaryStructureTest (5) |

---

### Phase 3 — Payroll Engine (Sprint 5–6)

**FRs:** HRS-026, HRS-027, HRS-028, HRS-029, HRS-030, HRS-037

**Files to create:**

| Category | Files |
|---|---|
| Controllers (1 partial) | PayrollController (methods: index, store, show, compute, details, override, submit, approve, lock) |
| Services (3) | PayrollComputationService, TdsComputationService, PayrollRunService |
| Jobs (1) | ProcessPayrollJob — `$tries=1; $timeout=600;` dispatched when employee count >100 |
| Models (4) | PayrollRun, PayrollRunDetail, PayrollOverride, TdsLedger |
| FormRequests (3) | StorePayrollRun, OverridePayrollDetail + ApprovePayrollRun (implicit) |
| Policies (1) | PayrollRunPolicy |
| Events (2) | PayrollApproved, PayrollLocked |
| Views (~12) | payroll: index, create, show, details, status, supplementary/create, supplementary/show, _run_card, _employee_row, _status_badge, _override_modal, _totals_bar |
| Tests (3 files, 22 tests) | PayrollRunTest (8), TdsComputationTest (6), PayrollComputationUnitTest (8) |

**Critical BR coverage in tests:**
- BR-PAY-001 (duplicate run blocked)
- BR-PAY-002 (compute blocked if missing assignment)
- BR-PAY-003 (locked run immutable)
- BR-PAY-006 (TDS floor at 0)

---

### Phase 4 — Payslip, Statutory & Distribution (Sprint 7–8)

**FRs:** HRS-031, HRS-032, HRS-033, HRS-034, HRS-035, HRS-036, HRS-039, HRS-040

**Files to create:**

| Category | Files |
|---|---|
| Controllers (2) | PayslipController, StatutoryController; add bankFile + markPaid to PayrollController |
| Services (2) | PayslipService, StatutoryExportService |
| Jobs (1) | GeneratePayslipsJob — always dispatched for bulk generation |
| Models (1) | Payslip |
| FormRequests (0) | No dedicated FRs for these endpoints (binary responses) |
| Policies (2) | PayslipPolicy, Form16Policy |
| Views (~12) | payslips: index, generate-all, email-options, payslip-template, _progress_bar, _payslip_row (6); my-payslips: index, show (2); statutory: pf-ecr, esi-challan, bank-file, _export_summary (4) |
| Tests (3 files, 11 tests) | PayslipGenerationTest (5), BankFileTest (3), PfEcrTest (3) |

**NFR-007 coverage:** `PayslipGenerationTest` must assert `password = PANlast4 + DDYYYY(DOB)` format.

---

### Phase 5 — Form 16, Increments & Reports (Sprint 9–10)

**FRs:** HRS-038, HRS-041, HRS-042, HRS-043, HRS-044, HRS-045, HRS-046

**Files to create:**

| Category | Files |
|---|---|
| Controllers (3) | Form16Controller, IncrementController, PayrollReportController |
| Services (1 extend) | IncrementService (new); extend TdsComputationService::generateForm16() |
| Jobs (1) | GenerateForm16Job — dispatched for bulk Form 16 generation |
| Models (2) | Form16, IncrementPolicy |
| FormRequests (1) | StoreIncrementPolicyRequest |
| Views (~22) | form16: index, generate-all, form16-template, my-form16/index (4); increment-policies: index, create, edit (3); increments: index, process, _proposal_row (3); reports: index, salary-register, bank-summary, ctc-analysis, trend + 3 PDF templates + 4 partials (12) |
| Tests (3 files, 13 tests) | Form16Test (3), IncrementProcessingTest (4), TdsProjectionTest (5) — plus extend TdsComputationTest with Form16 scenarios |

**BR coverage:** BR-PAY-009 (Form 16 blocked before April 15) in Form16Test.

---

### Phase 6 — Appraisal (Sprint 11–12)

**FRs:** HRS-002, HRS-007, HRS-019, HRS-020, HRS-021, HRS-022

**Files to create:**

| Category | Files |
|---|---|
| Controllers (1) | AppraisalController (all 14 methods) |
| Services (1) | AppraisalService |
| Models (5) | KpiTemplate, KpiTemplateItem, AppraisalCycle, Appraisal, AppraisalIncrementFlag |
| FormRequests (4) | StoreKpiTemplate, StoreAppraisalCycle, SubmitSelfAppraisal, SubmitReview |
| Policies (2) | AppraisalCyclePolicy, AppraisalPolicy |
| Events (1) | AppraisalFinalized |
| Views (~12) | kpi-templates: index, create, edit, show (4); appraisal-cycles: index, create, edit (3); appraisals: index, self, review, show, _kpi_row (5) |
| Tests (2 files, 10 tests) | AppraisalTest (6), AppraisalRatingCalculatorTest (4) |

**Note:** Phase 6 is the last phase. After completion, add `employment/history.blade.php` (FR HRS-002) and `leave-policy/show.blade.php` (FR HRS-007) which have low complexity.

---

**FR Coverage Check (all 46 FRs):**

| FR Range | Phase |
|---|---|
| HRS-001, 003, 005, 006, 008, 009, 010, 011 | Phase 1 |
| HRS-004, 012, 013, 014, 015, 016, 017, 018, 023, 024, 025 | Phase 2 |
| HRS-026, 027, 028, 029, 030, 037 | Phase 3 |
| HRS-031, 032, 033, 034, 035, 036, 039, 040 | Phase 4 |
| HRS-038, 041, 042, 043, 044, 045, 046 | Phase 5 |
| HRS-002, 007, 019, 020, 021, 022 | Phase 6 |

All 46 FRs covered.

---

## Section 7 — Seeder Execution Order

```
php artisan module:seed HrStaff
  -- or --
php artisan db:seed --class="Modules\HrStaff\Database\Seeders\HrsSeederRunner"

HrsSeederRunner::run()
  ↓
  1. HrsLeaveTypeSeeder
     → hrs_leave_types (7 types: CL, EL, SL, ML, PL, CO, LWP)
     → No dependencies
     → Key method: updateOrInsert on 'code'

  ↓
  2. HrsLeavePolicySeeder
     → hrs_leave_policies (1 global default; academic_year_id = NULL)
     → No dependencies
     → Idempotent: skips if global policy (academic_year_id IS NULL) exists

  ↓
  3. HrsPtSlabSeeder
     → hrs_pt_slabs (7 slabs: HP×2, KA×2, MH×3)
     → No dependencies
     → Key method: updateOrInsert on (state_code, min_salary)

  ↓
  4. HrsIdCardTemplateSeeder
     → hrs_id_card_templates (1 default template)
     → No dependencies
     → Idempotent: skips if is_default=1 AND is_active=1 exists

  ↓
  5. PaySalaryComponentSeeder
     → pay_salary_components (14 components: 7 earnings, 5 deductions, 2 employer contributions)
     → No dependencies
     → Key method: updateOrInsert on 'code'

  ↓
  6. PaySalaryStructureSeeder
     → pay_salary_structures (3 structures: Teaching, Non-Teaching, Contractual)
     → pay_salary_structure_components (junction records per structure)
     → Depends on: PaySalaryComponentSeeder (looks up component IDs by code)
     → Key method: insertGetId for new structure; updateOrInsert on (structure_id, component_id)
```

**For test suite minimum seeders:**
`HrsLeaveTypeSeeder` + `PaySalaryComponentSeeder` are the minimum required for most feature tests.
Payroll computation tests additionally require `PaySalaryStructureSeeder`.

**Seeder file locations:**
`Modules/HrStaff/Database/Seeders/`

**Runner registration:**
Register `HrsSeederRunner` in `Modules/HrStaff/Database/Seeders/DatabaseSeeder.php` and in the module's `module.json`.

---

## Section 8 — Testing Strategy

### 8.1 Framework Setup

```php
// Feature tests (Pest) — all files in tests/Feature/HrStaff/
uses(Tests\TestCase::class, Illuminate\Foundation\Testing\RefreshDatabase::class);

// Unit tests (PHPUnit) — all files in tests/Unit/HrStaff/
// Unit tests: no Laravel app boot; test pure computation classes

// Minimum seeder in Feature tests:
beforeEach(function () {
    $this->seed([
        HrsLeaveTypeSeeder::class,
        PaySalaryComponentSeeder::class,
    ]);
});
```

---

### 8.2 Queue & Event Faking

```php
// In payroll tests — always fake queue before dispatching
Queue::fake();
// Trigger compute
$this->post(route('hr-staff.payroll.compute', $run));
Queue::assertPushed(ProcessPayrollJob::class);

// In integration tests — fake events before workflow actions
Event::fake([PayrollApproved::class, PayrollLocked::class]);
$service->lock($run);
Event::assertDispatched(PayrollLocked::class, fn($e) => $e->run->id === $run->id);

// Leave approval tests
Event::fake([LeaveApproved::class, LeaveRejected::class]);
$service->approve($application, $approverId, 'Approved');
Event::assertDispatched(LeaveApproved::class);
```

---

### 8.3 Feature Test File Summary (15 files, ~75 tests)

| Test File | Location | Count | Key Scenarios |
|---|---|---|---|
| `LeaveApplicationTest` | `tests/Feature/HrStaff/LeaveApplicationTest.php` | 8 | Apply leave, balance check (BR-HRS-001), overlap rejection (BR-HRS-002), half-day = 0.5 days, cancel and balance restore (BR-HRS-008), backdated limit (BR-HRS-004) |
| `LeaveApprovalTest` | `tests/Feature/HrStaff/LeaveApprovalTest.php` | 6 | L1 approve transitions to pending_l2, L2 approve transitions to approved, reject at any level, return for clarification, balance updated on final approval |
| `LeaveBalanceTest` | `tests/Feature/HrStaff/LeaveBalanceTest.php` | 5 | Initialize balances for academic year, carry-forward capped at leave_type limit (BR-HRS-003), manual adjustment with reason, year-end lapse of excess |
| `LopReconciliationTest` | `tests/Feature/HrStaff/LopReconciliationTest.php` | 4 | Flag absent-without-approved-leave, confirm LOP (HR Manager only — BR-HRS-009), waive LOP, confirmed records consumed by payroll |
| `SalaryAssignmentTest` | `tests/Feature/HrStaff/SalaryAssignmentTest.php` | 4 | Assign structure, CTC out-of-grade-range rejected (BR-HRS-011), revision creates new row + closes prior, history preserved |
| `ComplianceRecordTest` | `tests/Feature/HrStaff/ComplianceRecordTest.php` | 5 | PF enrollment with UAN, ESI enrollment, TDS declaration (PAN encrypted, regime stored), PT slab lookup, gratuity eligibility at 5 years (BR-HRS-014) |
| `SalaryStructureTest` | `tests/Feature/HrStaff/SalaryStructureTest.php` | 5 | Create structure, add components to structure, CTC preview returns correct breakdown, missing BASIC rejected (BR-PAY-011), duplicate component rejected |
| `AppraisalTest` | `tests/Feature/HrStaff/AppraisalTest.php` | 6 | Cycle creation + date validation (BR-HRS-018), self-submit locks form (BR-HRS-017), reviewer submit, finalize with HR adjustment within ±10% (BR-HRS-020), increment flag created on finalize, weight sum validation (BR-HRS-016) |
| `PayrollRunTest` | `tests/Feature/HrStaff/PayrollRunTest.php` | 8 | Initiate run, pre-condition blocks compute if missing assignment (BR-PAY-002), compute dispatches job, override with reason (BR-PAY-005), submit→approve→lock FSM, duplicate regular run blocked (BR-PAY-001), **locked run immutable (BR-PAY-003)** — any mutation after lock must 403 |
| `PayslipGenerationTest` | `tests/Feature/HrStaff/PayslipGenerationTest.php` | 5 | Single generate creates Payslip record, bulk generate dispatches GeneratePayslipsJob, email dispatched after generation, **password = PANlast4+DDYYYY** (NFR-007), re-generate blocked after lock (BR-PAY-012) |
| `TdsComputationTest` | `tests/Feature/HrStaff/TdsComputationTest.php` | 6 | Old regime deduction, new regime (no 80C), mid-year regime change propagates to future months (OQ-011), December recompute adjusts remaining months, **negative TDS floors at 0** (BR-PAY-006), TDS ledger YTD updated |
| `Form16Test` | `tests/Feature/HrStaff/Form16Test.php` | 3 | Generate Form 16 creates pay_form16 + sys_media, employee self-service download, **blocked before April 15** (BR-PAY-009) |
| `BankFileTest` | `tests/Feature/HrStaff/BankFileTest.php` | 3 | Export CSV contains correct columns, export TXT format, **blocked if status ≠ approved** (BR-PAY-007) |
| `PfEcrTest` | `tests/Feature/HrStaff/PfEcrTest.php` | 3 | ECR v2 flat-file format, UAN present for all employees, contribution amounts sum-check |
| `IncrementProcessingTest` | `tests/Feature/HrStaff/IncrementProcessingTest.php` | 4 | Policy-based increment applied per rating band, ad-hoc revision creates new salary assignment, effective date enforced, increment flag status→processed |

---

### 8.4 Unit Test File Summary (7 files, ~30 tests)

| Test File | Location | Count | Key Scenarios |
|---|---|---|---|
| `LeaveDayCalculatorTest` | `tests/Unit/HrStaff/LeaveDayCalculatorTest.php` | 5 | Weekend days excluded, seeded holidays excluded, half_day = 0.5, cross-month range, LWP type allows 0 balance |
| `GratuityCalculatorTest` | `tests/Unit/HrStaff/GratuityCalculatorTest.php` | 3 | Standard calc (15 × last_basic × years / 26), below 5-year threshold returns 0, partial year rounds down |
| `AppraisalRatingCalculatorTest` | `tests/Unit/HrStaff/AppraisalRatingCalculatorTest.php` | 4 | Weighted average correct, weights not summing to 100 throws, HR adjustment within ±10% passes, HR adjustment >10% fails |
| `EmpCodeGeneratorTest` | `tests/Unit/HrStaff/EmpCodeGeneratorTest.php` | 3 | Format matches `EMP/\d{4}/\d{3}`, year extracted from current year, uniqueness enforced atomically |
| `PayrollComputationUnitTest` | `tests/Unit/HrStaff/PayrollComputationUnitTest.php` | 8 | Gross calculation from structure components, LWP formula: (gross/working_days)×lop_days, PF 12% of basic+DA, ESI 0.75% below ₹21k, ESI not applied above ₹21k, PT slab lookup for state, TDS monthly round-down, net_pay = gross_after_lwp − deductions |
| `TdsProjectionTest` | `tests/Unit/HrStaff/TdsProjectionTest.php` | 5 | Projected income = YTD + remaining months × current gross, 80C capped at ₹1.5L, HRA exemption formula, remaining months division distributes evenly, year-end single-month absorbs all remaining tax |
| `PayslipPasswordTest` | `tests/Unit/HrStaff/PayslipPasswordTest.php` | 2 | Password format: `PANlast4 + DDYYYY(DOB)` e.g. `1234R01041980`, PAN with special chars handled |

---

### 8.5 Factory Requirements

```php
// Modules/HrStaff/Database/Factories/

EmploymentDetailFactory::class
    // contract_type: random from enum
    // bank_account_number: encrypted random numeric string (12 digits)
    // bank_ifsc: regex-valid IFSC code

LeaveApplicationFactory::class
    // from_date: faker->dateTimeBetween('-1 month', '+1 month')
    // to_date: from_date + random 1–5 days
    // leave_type_id: must exist in hrs_leave_types (use firstOrFactory pattern)
    // status: 'pending' default

AppraisalFactory::class
    // cycle_id: requires AppraisalCycleFactory
    // employee_id: faker->randomElement(Employee::pluck('id'))
    // self_rating_json: JSON of KPI scores (valid range 1–rating_scale)
    // status: 'draft' default

PayrollRunFactory::class
    // payroll_month: format YYYY-MM, defaults to last month
    // run_type: 'regular'
    // status: 'draft'
    // initiated_by: 1 (system user)

PayrollRunDetailFactory::class
    // All numeric fields: faker->randomFloat(2, 0, 50000)
    // computation_json: JSON with component-wise breakdown
    // payment_status: 'pending'
    // is_override: 0
```

---

### 8.6 Mocking Strategy

```php
// LOP Reconciliation — att_staff_attendances read-only cross-module
// Use Mockery to mock the DB query:
$this->mock(LeaveService::class, function ($mock) {
    $mock->shouldReceive('runLopReconciliation')
         ->once()
         ->andReturn(collect([...]));
});

// DomPDF in payslip/ID card/Form16 tests — mock PDF generation
// to avoid filesystem writes:
$this->mock(PayslipService::class, function ($mock) {
    $mock->shouldReceive('generate')->andReturn(new Payslip([...]));
});

// Email dispatch — always use:
Mail::fake();
// Assert after emailAll():
Mail::assertQueued(PayslipEmail::class);
```

---

### 8.7 Queue Jobs Summary

| Job | Dispatch Condition | Timeout | Tries | Queued In |
|---|---|---|---|---|
| `ProcessPayrollJob` | PayrollRunService::compute() when employee count > 100 | 600s | 1 | `payroll` queue |
| `GeneratePayslipsJob` | PayslipService::generateAllForRun() — always | 300s | 1 | `payroll` queue |
| `GenerateForm16Job` | Form16Controller::generateAll() | 300s | 1 | `payroll` queue |

All jobs implement `ShouldBeUnique` scoped by `PayrollRun::id` to prevent duplicate dispatch.

---

### 8.8 Integration Events Summary

| Event | Class | Fired By | Payload | Listener |
|---|---|---|---|---|
| `LeaveApproved` | `Events\LeaveApproved` | LeaveApprovalService | `$application` | NotificationService |
| `LeaveRejected` | `Events\LeaveRejected` | LeaveApprovalService | `$application`, `$remarks` | NotificationService |
| `DocumentExpiringSoon` | `Events\DocumentExpiringSoon` | Scheduled command | `$document` | HR Manager notification |
| `AppraisalFinalized` | `Events\AppraisalFinalized` | AppraisalService | `$appraisal` | IncrementService (create flag) |
| `PayrollApproved` | `Events\PayrollApproved` | PayrollRunService | `$run` | Accounting module (Journal Voucher) |
| `PayrollLocked` | `Events\PayrollLocked` | PayrollRunService | `$run` | StatutoryExportService (update PF/ESI register status) |

---

## Quality Gate Checklist

- [x] All 20 controllers listed with all methods (Section 1)
- [x] All 15 services listed with method signatures (Section 2)
- [x] All 30 FormRequests listed with key validation rules (Section 3)
- [x] All 46 FRs (HRS-001 to HRS-046) appear in at least one implementation phase (Section 6 coverage table)
- [x] All 6 implementation phases have: FRs covered, files to create, test count (Section 6)
- [x] Payroll computation pseudocode present in Section 2 (PayrollComputationService::computeEmployee — 8 steps)
- [x] Seeder execution order documented with dependency note (Section 7)
- [x] Queue jobs documented: ProcessPayrollJob, GeneratePayslipsJob, GenerateForm16Job (Sections 6 + 8.7)
- [x] Route list consolidated with middleware and FR reference (Section 5 — 102 routes across 8 groups)
- [x] View count per sub-module totals approximately 110 (Section 4 — 118 total including partials)
- [x] Test strategy includes Event::fake() and Queue::fake() guidance (Section 8.2)
- [x] BR-PAY-003 (locked payroll immutable) test explicitly referenced (Section 8.3 — PayrollRunTest)
