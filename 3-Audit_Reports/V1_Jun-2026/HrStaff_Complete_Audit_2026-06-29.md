# Complete Audit — HrStaff (HR & Payroll) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** HrStaff | **Code:** HRS | **Prefixes:** `hrs_*` (HR, 23 tables) + `pay_*` (Payroll, 10 tables)
**App dir:** `/Users/bkwork/Herd/prime_ai/Modules/HrStaff` | **Auditor:** Technical Auditor (pa-technical-auditor)
**Baseline FRD:** `4-Requirement_Module_wise/0-FRD_Documents/HRS_FRD_Complete_2026-06-29.md` (46 REQ, 36 BR, 4 RPT, 16 NFR)

> **Issue-code namespace note.** All findings are namespaced under module code **HRS** (`SEC-HRS-`, `BUG-HRS-`,
> `DATA-HRS-`, `VAL-HRS-`, `MIG-HRS-`, `PERF-HRS-`, `JOB-HRS-`, `TEN-HRS-`). The `PAY` token is already owned by
> the **Payment** module (`SEC-PAY-001..008`, `BUG-PAY-001` in known-issues.md, prefix `pmt_`); per the
> "never reuse a code" rule, payroll-layer findings here keep the HRS prefix and name the `pay_*` context in the title.

---

## Executive Summary

HrStaff is genuinely ~85% built (33 tables/migrations/models reconciled clean, 26 controllers, 15 services,
108 views, 17 policies, 26 seeded+role-mapped permissions) and is **above platform norms** on the highest-risk
layers: tenancy is correct (full middleware stack + `auth`+`verified`), there is **zero `$request->all()`**, **zero
debug statements**, **zero `Schema::` introspection**, **zero `initialize()` leaks**, all `pay_*`/`hrs_*` PKs are
`bigIncrements` (not the INT-PK platform default), and the salary/payslip/leave endpoints have **proper ownership
checks (no IDOR)** — the payroll-confidentiality and IDOR risks the brief asked me to hunt are largely well-handled.

The worst finding is **DATA-HRS-001 (P0)**: `LeaveService::initializeBalances()` runs an unconditional
`forceDelete()` of every leave balance for the academic year before recreating them, permanently destroying
accrued `used_days` / `carry_forward_days` and orphaning the adjustment audit trail on any re-run — a data-loss
path on a live route that also violates BR-HRS-023 (soft-delete only). Around it sit six P1s that make several
flagship features non-functional rather than unsafe: domain events fire into **no listeners** (Accounting Journal
Voucher and all notifications never happen), payslip PDFs are **not password-protected** (NFR-HRS-007), PF is
computed from a **hardcoded `gross × 50%` approximation** (wrong statutory filings), payroll computation **silently
skips** employees with no salary assignment instead of blocking (BR-PAY-002), Form 16 generation is a **no-op stub**
with no April-15 guard, and bulk payslip/Form 16/email run **synchronously with no queue or Job classes** (NFR-004).

**Overall health: 40 / 100 (P0 cap applied; uncapped weighted ≈ 63).  DEPLOY: NO-GO.**

---

## Health Score

| Dimension | Raw | Note |
|---|---|---|
| Weighted layer index (uncapped) | ≈ 63 | Strong tenancy/auth/validation; weak data-integrity & queue/integration |
| **P0 hard cap** | **40** | DATA-HRS-001 (data-loss) caps health at 40 per the scoring rule |
| **Reported health** | **40 / 100** | "Not healthy until the P0 + the integration/compliance P1s are fixed" |

---

## Deploy Gate Verdict (Mode G)

**NO-GO.** Blocking items:
1. **DATA-HRS-001 (P0)** — permanent leave-balance data loss on `initializeBalances` re-run.
2. **Inherited platform P0s** (not HRS-owned, but they disable HRS's async story the moment Jobs are added):
   `DEPLOY-HRZ-01` queue `database` vs Horizon `redis` mismatch; `DEPLOY-ENV-02` committed `APP_KEY` in
   `.env-original`; `SEC-RTG-001` unauthenticated seeder routes.
3. **TEN-HRS-001 (P2)** — RSP omits `EnsureTenantHasModule` (TEN-RTG-001 platform pattern): off-plan tenants
   reach HRS (not a deploy blocker by itself, listed for the gate record).

Layer 6/8/10/12 module-local check: tenancy ✅ correct; transactions present on multi-write paths ✅ but missing
row-locks on contended balances (P2); **no queue/Job layer at all** (P1); no committed secrets / route closures /
`env()` misuse found inside the module.

---

## P0 Findings

```
[DATA-HRS-001] Severity: P0 | Leave-balance initialization permanently force-deletes the year's balances
- Location: Modules/HrStaff/app/Services/LeaveService.php  (initializeBalances(), the pre-loop wipe)
- Evidence:
    DB::transaction(function () use (...) {
        // Hard-delete all existing balances for this year before re-creating
        LeaveBalance::withTrashed()->where('academic_year_id', $academicYearId)->forceDelete();
        foreach ($employees as $employee) { foreach ($leaveTypes as $type) { ... LeaveBalance::create([...]) } }
    });
- Why it's a risk: This is reachable from a live route (balance initialization) with no guard against running on a
  year that already has activity. A re-run permanently destroys every employee's accrued `used_days`,
  `carry_forward_days` and any manual `adjustment` for that year, and orphans `hrs_leave_balance_adjustments`
  rows whose `leave_balance_id` FK now points at deleted parents. It is irreversible (forceDelete bypasses soft
  delete) and contradicts BR-HRS-023 ("Soft-delete only; permanent deletion not permitted"). Blast radius = all
  staff of the tenant for that year.
- Fix: Do not `forceDelete`. Make initialization idempotent with `updateOrCreate` keyed on
  (employee_id, leave_type_id, academic_year_id), and HARD-BLOCK re-initialization of a year that already has any
  application/usage (or require an explicit "reset" capability gated separately + audited). Never bulk-hard-delete
  a ledger table.
- Confidence: High
- Systemic? : Module-local; sibling concern to BR-HRS-023.
```

---

## P1 Findings

```
[BUG-HRS-001] Severity: P1 | Domain events fire into ZERO listeners — Accounting JV & all notifications are dead
- Location: Modules/HrStaff/app/Providers/EventServiceProvider.php  ($listen = []; no app/Listeners/ dir exists)
            event(new PayrollApproved(...)) PayrollRunService.php; event(new PayrollLocked(...)) PayrollRunService.php;
            event(new LeaveApproved(...)) / LeaveRejected(...) LeaveApprovalService.php
- Evidence:
    protected $listen = [];
    protected static $shouldDiscoverEvents = true;   // auto-discovery scans app/Listeners/ — which does not exist
- Why it's a risk: REQ-HRS-029(b) requires lock to fire the Accounting Journal-Voucher event "exactly once" — the
  event fires but nothing consumes it, so **no JV is ever created**. REQ-HRS-010(d)/REQ-HRS-033 leave-decision and
  payslip-email notifications likewise never dispatch. The module's entire outbound integration surface is unwired.
- Fix: Add `app/Listeners/` classes (or register in `$listen`) for PayrollApproved→Accounting JV, PayrollLocked→
  PF/ESI register status, LeaveApproved/Rejected→Notification, AppraisalFinalized→IncrementService. Add a feature
  test asserting each event has ≥1 listener.
- Confidence: High
- Systemic? : Module-local integration gap.
```
```
[BUG-HRS-002] Severity: P1 | PF computed from a hardcoded "gross × 50%" approximation, not actual Basic
- Location: Modules/HrStaff/app/Services/PayrollComputationService.php  (computePf())
- Evidence:
    // PF base = Basic + DA (capped at ₹15,000 for statutory)
    $basicDa = min($grossAfterLwp * 0.50, 15000); // Approximate: basic ≈ 50% of gross
    $empPf = round($basicDa * 0.12, 2);
- Why it's a risk: Statutory PF must be computed on the employee's ACTUAL Basic (+DA) component from the assigned
  salary structure, not a 50%-of-gross heuristic. This produces materially wrong employee 12% / employer
  3.67%+8.33% splits, wrong `hrs_pf_contribution_register` rows, and wrong EPFO ECR filings (BR-PAY-004,
  REQ-HRS-015/039) — a compliance exposure. Applicability is also taken purely from `applicable_flag`, never from
  the basic ≤ ₹15,000 threshold (BR-HRS-012).
- Fix: Resolve the Basic (and DA) component amount from `salaryStructure.structureComponents` for the employee and
  compute PF on that; drive applicability from the basic-wage threshold per BR-HRS-012. Unit-test against known cases.
- Confidence: High
- Systemic? : Module-local; relates to Mode C BR-PAY-004 PARTIAL.
```
```
[BUG-HRS-003] Severity: P1 | Payroll computation SKIPS employees with no salary assignment instead of blocking (BR-PAY-002)
- Location: Modules/HrStaff/app/Services/PayrollComputationService.php  (computeRun() try/catch; computeEmployee() throw)
- Evidence:
    try { $detail = $this->computeEmployee($run, $employee); ... }
    catch (\Exception $e) { $notes[] = "Employee #{$employee->id}: {$e->getMessage()}"; }
    ...
    $run->update(['status' => 'computed', ... 'computation_notes' => implode("\n", $notes) ...]);
- Why it's a risk: REQ-HRS-026(b)/BR-PAY-002 require "Computation cannot start if any active employee lacks a valid
  salary assignment." Instead the run reaches `computed` with the unassigned employees silently absent (only noted
  in `computation_notes`), so payroll is approved/locked/paid while some staff are missed — a money-correctness defect.
- Fix: Pre-flight validate that every active employee has an active assignment BEFORE setting `computing`; abort the
  whole run (DomainException) if any are missing, surfacing the list. Keep the supplementary-run path for true late joiners.
- Confidence: High
- Systemic? : Module-local; Mode C BR-PAY-002 MISSING.
```
```
[BUG-HRS-004] Severity: P1 | Form 16 generateAll() is a no-op stub; no April-15 guard (BR-PAY-009)
- Location: Modules/HrStaff/app/Http/Controllers/Form16Controller.php  (generateAll())
- Evidence:
    // Form 16 generation is a heavy operation — will be queued in production
    activityLog(null, 'Form16Generate', ['message' => "Form 16 generation triggered for FY {$year}."]);
    return redirect()->route('hr-staff.form16.index', $year)->with('success', "Form 16 generation queued ...");
- Why it's a risk: The route is live and reports success, but no `pay_form16` rows are ever produced, so
  `Form16Controller::download()` always 404s (REQ-HRS-038 non-functional). BR-PAY-009 ("blocked before April 15 for
  prior FY") and "only TDS>0 employees eligible" are entirely absent. Stub wired to a live route (Layer 4.3).
- Fix: Implement Form 16 generation (Part A+B PDF, queued — see PERF-HRS-001), gate on `date >= April 15` for the
  prior FY, restrict to `tds_deducted > 0` employees.
- Confidence: High
- Systemic? : Module-local; Mode C BR-PAY-009 MISSING.
```
```
[SEC-HRS-001] Severity: P1 | Payslip PDFs are NOT password-protected (NFR-HRS-007 / REQ-HRS-031)
- Location: Modules/HrStaff/app/Services/PayslipService.php  (generate())
- Evidence:
    $pdf = Pdf::loadView('hrstaff::payslip.pdf', ['detail' => $detail]);
    $media = $employee->addMediaFromString($pdf->output())->usingFileName(...)->toMediaCollection('payslips');
- Why it's a risk: REQ-HRS-031(a) requires the payslip PDF to open only with the specified password (PAN last 4 +
  DDYYYY of DOB); NFR-HRS-007 makes this mandatory. DomPDF output is written with no encryption/password, so a
  sensitive PII document (salary breakdown, PF, YTD) is stored and downloadable unprotected. Download also streams
  the raw `$media->getPath()` rather than a signed temporary URL (NFR-HRS-006 partial) — though it IS behind an
  auth + ownership check (no IDOR).
- Fix: Apply PDF password protection at generation (e.g. encrypt the DomPDF output / use a PDF lib that supports
  user-password) using PAN-last-4 + DDYYYY(DOB); serve via `temporaryUrl()` / signed route per NFR-HRS-006.
- Confidence: High
- Systemic? : Module-local; Mode C / NFR.
```
```
[PERF-HRS-001 / JOB-HRS-001] Severity: P1 | Bulk payslip / Form 16 / email run synchronously — no queue, no Jobs (NFR-HRS-004)
- Location: Modules/HrStaff/app/Http/Controllers/PayslipController.php (generateAll → PayslipService::generateAll loop);
            Form16Controller::generateAll; (no Modules/HrStaff/app/Jobs/ directory exists)
- Evidence:
    foreach ($details as $detail) { $this->generate($detail); $count++; }   // DomPDF render + media write per employee, in-request
- Why it's a risk: NFR-HRS-004 mandates bulk payslip generation for ~200 employees via queue (<5 min); RISK-HRS-005
  flags timeout at scale. Rendering N DomPDFs and writing N media files inside one web request will exceed PHP
  max_execution_time / 504 for any real school (200–500 staff). No `ShouldQueue` Job classes exist (BA-confirmed).
- Fix: Introduce queued Jobs (GeneratePayslipsJob, GenerateForm16Job, SendPayslipEmailJob) that re-init tenancy in
  handle() and declare `$tries/$backoff/$timeout` (Layer 10.1). NOTE: blocked by DEPLOY-HRZ-01 (queue=database vs
  Horizon=redis) — fix that first or the jobs will never run.
- Confidence: High
- Systemic? : Module-local feature gap; depends on platform DEPLOY-HRZ-01.
```
```
[VAL-HRS-001] Severity: P1 | Leave application skips medical-cert / gender / min-service rules (BR-HRS-005/006/007)
- Location: Modules/HrStaff/app/Services/LeaveService.php  (applyLeave())
- Evidence: applyLeave() validates balance, backdated window, overlap, max-consecutive — but never checks
  $leaveType->gender_restriction against the applicant, never requires a medical certificate for SL beyond the
  threshold, never enforces minimum service months; calculateDays() is called WITHOUT $applicableTo so holiday
  applicability defaults to 'all'.
- Why it's a risk: REQ-HRS-009 lists BR-HRS-005/006/007 as enforced rules; none are. A male employee can take
  maternity leave, SL beyond threshold needs no certificate, and brand-new joiners bypass the min-service gate.
- Fix: Add these validations to applyLeave() (resolve employee gender/join date from sch_employees), and pass the
  leave type's `applicable_to` into calculateDays().
- Confidence: High
- Systemic? : Module-local; Mode C BR-HRS-005/006/007 MISSING.
```

---

## P2 Findings

```
[DATA-HRS-002] Severity: P2 | Overlap detection misses an existing leave that fully encloses the new range (BR-HRS-002)
- Location: Modules/HrStaff/app/Services/LeaveService.php  (applyLeave() overlap query)
- Evidence:
    ->where(fn ($q) => $q->whereBetween('from_date', [$from, $to])->orWhereBetween('to_date', [$from, $to]))
- Why: The predicate only catches existing rows whose from_date OR to_date lies inside the new range. An existing
  approved leave that fully encloses the new dates (existing.from < new.from AND existing.to > new.to) is NOT
  detected → a second, overlapping leave is accepted. BR-HRS-002 PARTIAL.
- Fix: Use the standard interval-overlap predicate: existing.from_date <= new.to AND existing.to_date >= new.from.
- Confidence: High | Systemic?: module-local
```
```
[VAL-HRS-002] Severity: P2 | SalaryAssignmentController::update() bypasses the service — CTC band & single-active not re-checked
- Location: Modules/HrStaff/app/Http/Controllers/SalaryAssignmentController.php (update());
            band check lives only in SalaryAssignmentService::validateCtcInGrade (called by assign()/revise())
- Evidence:
    $active->update(array_merge($request->validated(), ['updated_by' => auth()->id()]));
- Why: update() writes validated data straight onto the active assignment, never calling validateCtcInGrade(), so
  an out-of-band CTC (BR-HRS-011) can be set; the assign/revise single-active discipline is also bypassed. The
  FormRequest does not enforce the band (it can't — band depends on the chosen grade).
- Fix: Route update() through the service (or call validateCtcInGrade in update); also note assign()'s band check
  is skipped entirely when pay_grade_id is null.
- Confidence: High | Systemic?: module-local
```
```
[DATA-HRS-003] Severity: P2 | Read-modify-write on leave balance & single-active assignment without row locks (concurrency)
- Location: LeaveService::applyLeave()/deductBalance via LeaveApprovalService; SalaryAssignmentService::assign()
- Evidence: balance availability is read then compared then written, and the prior active assignment is closed then a
  new one created, all inside DB::transaction but with no lockForUpdate / atomic decrement and no DB uniqueness on
  "one active row".
- Why: Concurrent applies/approvals can both pass the balance check (BR-HRS-001), and two concurrent assigns/revisions
  can leave two active assignments (BR-HRS-010) — the FRD Conditions catalog explicitly tests both races. Matches the
  platform Layer 8.2 missing-lock pattern.
- Fix: `lockForUpdate()` the balance/assignment rows inside the transaction, or add a generated active-flag UNIQUE
  (D26/D36 pattern) for single-active.
- Confidence: Medium | Systemic?: platform Layer 8.2
```
```
[SEC-HRS-002] Severity: P2 | All 27 FormRequests authorize() return hardcoded true (D30)
- Location: Modules/HrStaff/app/Http/Requests/*.php  (27 of 27)
- Evidence: e.g. StorePayrollRunRequest, StoreSalaryAssignmentRequest, OverridePayrollDetailRequest, ApproveLeaveRequest
  all `public function authorize(): bool { return true; }`
- Why: Defense-in-depth collapses to the controller Gate calls only. Today every HRS controller action DOES gate
  with Gate::authorize(...) (verified), so this is not currently an open hole — but if any future method forgets the
  gate, the FormRequest provides zero fallback. This is the platform D30 norm (437/485).
- Fix: Each authorize() returns the matching Gate::allows('hrs.*'/'pay.*') for its route; keep controller gates too.
- Confidence: High | Systemic?: D30 (platform)
```
```
[MIG-HRS-001] Severity: P2 | 27 ->enum() columns across 20 migrations instead of sys_dropdown_table FKs (D29) + value-set drift
- Location: database/migrations/tenant/*create_hrs_*_table.php and *create_pay_*_table.php (20 files)
- Evidence: status FSMs and type columns are enums — e.g. pay_payroll_runs.status
  ['approved','computed','computing','draft','locked','reviewing'], run_type ['regular','supplementary'],
  compliance_type ['esi','gratuity','pf','pt','tds'], contract_type, holiday_type, payment_status, flag_status, etc.
  `applicable_to` appears with THREE different value sets across tables incl. a capitalised variant
  ['All','Non-Teaching','Teaching'] vs lowercase ['all','non_teaching','teaching'] — cross-table writes/filters can
  silently mismatch (strict-mode reject or wrong filter).
- Why: D29 requires extensible pick-lists (incl. status FSMs) to FK sys_dropdown_table so schools/PG-Admin can extend
  without a per-tenant migration. The casing inconsistency on applicable_to is a latent data bug.
- Fix: Migrate enum columns to `*_id` FK → sys_dropdown_table per D29 (or TINYINT for true binaries); at minimum
  normalise the applicable_to value set/casing across hrs_leave_types / hrs_holiday_calendars / hrs_kpi_templates.
- Confidence: High | Systemic?: D29 (platform)
```
```
[SEC-HRS-003] Severity: P2 | Non-standard permission prefixes hrs.* / pay.* instead of platform tenant.* (D24) + dead dual scheme
- Location: Modules/HrStaff/database/seeders/HrsPermissionSeeder.php; all controllers Gate::authorize('hrs.*'/'pay.*');
            config/permissionslist.php:532+ seeds UNUSED tenant.hrs-*/CRUD perms
- Evidence: controllers use 129 `hrs.*` + 55 `pay.*` gate strings (all seeded & role-mapped — works), while
  config/permissionslist.php defines `'hrs-employment' => $crud` etc. ('tenant.hrs-employment.create' …) that NO
  controller references.
- Why: D24 targets a single `tenant.*` prefix for tenant modules; HRS adds two more prefixes and ships a parallel,
  dead CRUD permission set. Not a live auth hole (the used scheme is consistent), but taxonomy debt + confusion.
- Fix: Standardise to `tenant.*` (or formally bless `hrs.`/`pay.`), and remove the unused permissionslist entries.
- Confidence: High | Systemic?: D24 (platform)
```
```
[SEC-HRS-004] Severity: P2 | Primary FRD actor roles "HR Manager" / "Payroll Manager" receive no permissions (D39-adjacent)
- Location: Modules/HrStaff/database/seeders/HrsPermissionSeeder.php  ($rolePermissions map)
- Evidence: role map covers Super Admin, Principal, Vice Principal, Accountant, Teacher, Staff — but NOT "HR Manager"
  or "Payroll Manager", which FRD §2.1 names as the module's primary actors.
- Why: If those tenant roles exist (per design OQ-010 "separate Payroll Manager role"), they get 403 on all HRS
  features and the module is operable only by Principal/Super Admin (the D39 "secured-to-nobody" shape). Confidence
  medium because Principal currently carries the full grant, masking the gap.
- Fix: Add HR Manager / Payroll Manager to the role map with their capability slice per the FRD §2.2 matrix, or
  confirm those roles are not provisioned and document Principal as the operator.
- Confidence: Medium | Systemic?: D39-adjacent
```
```
[TEN-HRS-001] Severity: P2 | RSP omits EnsureTenantHasModule — off-plan tenants can reach HRS (TEN-RTG-001 pattern)
- Location: Modules/HrStaff/app/Providers/RouteServiceProvider.php  (mapWebRoutes / mapApiRoutes middleware stack)
- Evidence: stack = ['web', InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive,
  'auth', 'verified'] — no `EnsureTenantHasModule`.
- Why: Consistent with the platform TEN-RTG-001 finding (module-subscription gate applied to only 1 of 26 groups):
  a tenant whose plan excludes HR/Payroll can still access HRS routes.
- Fix: Add EnsureTenantHasModule (HRS) to the RSP stack, matching the platform remediation.
- Confidence: High | Systemic?: TEN-RTG-001 (platform)
```

---

## P3 Findings

- **DEAD-HRS-001 (P3)** — `PayrollController::override()` recomputes `net_pay` AFTER applying the override, so an
  override whose `field_name` is `net_pay` is immediately overwritten by the recomputation. Minor logic edge.
- **BUG-HRS-005 (P3)** — `PayrollComputationService::computeRun()` sets `status='computing'` OUTSIDE the transaction;
  if the inner transaction throws, the run is left stuck in `computing`. Add a try/finally or set computing inside.
- **STYLE-HRS-001 (P3)** — `computePt()` parameter named `$grossMonthly` actually receives `grossAfterLwp`; harmless
  but misleading. The brief referenced `LeaveService::runLopReconciliation` — the actual stub method is
  `flagLopRecords()` (manual-input LOP, comment cites the pending `att_staff_attendances`); name corrected here.

---

## Layer Health Summary

| # | Layer | Status | Key finding |
|---|---|---|---|
| 1 | DDL Schema Integrity | 🟡 Amber | D29 enums (MIG-HRS-001); otherwise conventions clean, bigIncrements PKs, deleted_at/timestamps present |
| 2 | Migration↔Model↔DDL | 🟢 Green | 33 DDL = 33 migrations = 33 models; no orphans/dupes; no D17/D36/D37/D38 (BA reconcile confirmed live) |
| 3 | Model & ORM | 🟢 Green | Encryption casts correct; JSON arrays cast; booleans cast |
| 4 | Code Quality / Dead Code | 🟡 Amber | No debug/backup files; but Form16 stub (BUG-HRS-004) on a live route |
| 5 | Authorization | 🟢 Green | Every controller action gated; permissions seeded+role-mapped; no IDOR (salary/payslip/leave ownership checks) |
| 6 | Multi-Tenancy | 🟢 Green | Full RSP middleware stack + auth/verified; no initialize() leaks; no bare cache keys; (TEN-HRS-001 module-gate P2) |
| 7 | Input Validation / Mass-assign | 🟡 Amber | No $request->all(); file upload validated — but D30 (SEC-HRS-002) + missing leave rules (VAL-HRS-001) |
| 8 | Data Integrity / Tx / Concurrency | 🔴 Red | DATA-HRS-001 (P0 force-delete); BR-PAY-002 skip (BUG-HRS-003); missing row locks (DATA-HRS-003); overlap bug (DATA-HRS-002) |
| 9 | Performance | 🟡 Amber | Synchronous bulk payslip/Form16 (PERF-HRS-001); no obvious N+1 (eager loads used on list/detail) |
| 10 | Queue / Job / Scheduler | 🔴 Red | No Jobs/queue layer at all; events fire into no listeners (BUG-HRS-001) |
| 11 | Frontend / Output Safety | 🟢 Green | No raw user-string output flagged (not exhaustively swept; 108 views) |
| 12 | Deployment | 🔴 Red | Module clean, but inherited platform P0s (HRZ/ENV/RTG); NO-GO with DATA-HRS-001 |

---

## STEP 1 Reading-Discipline Output (three-way reconcile)

| Check | Result |
|---|---|
| DDL tables vs migrations vs models | 33 = 33 = 33; every `protected $table` has a `create_*` migration and a DDL block. **No drift** — BA's "no drift" claim verified against live tree. |
| `->increments('id')` (INT PK) | 0 of 33 — all use `$table->id()` (bigIncrements). Better than platform baseline (428/658 INT). |
| `softDeletes()` + timestamps | Present on the tables spot-checked (employment_details, payslips, salary_assignments); D38 NOT present. |
| GENERATED columns (D36) | None declared in DDL/migrations for HRS — D36 N/A. |
| Status-master FK as string (D37) | Status columns are `enum` (string) with string casts and migrations applied → consistent (D29 tradeoff, not D37). |
| Cross-prefix intra-module FKs | `hrs_salary_assignments.pay_salary_structure_id`→`pay_salary_structures`; `pay_payroll_run_details.salary_assignment_id`→`hrs_salary_assignments` — intentional (confirmed). |
| Snapshot correction | module-knowledge claimed "0 enums implied / ENUM-free" is wrong — **27 enums** exist (corrected in HRS_HrStaff.md). My own first grep gave a false negative because the shell `grep` is aliased to `ugrep`, which parses a pattern starting with `-` (`->enum(`) as an option; re-ran with `-e`. |

---

## FRD Gap Summary (Mode B)

Structurally, all 46 REQ have a controller/route/view (RTM "Built"). Behavioural/quality gaps by REQ:

| REQ | Gap | Finding |
|---|---|---|
| REQ-HRS-008 Balance init | force-delete data loss | DATA-HRS-001 (P0) |
| REQ-HRS-009 Leave application | BR-005/006/007 not enforced; overlap predicate bug | VAL-HRS-001, DATA-HRS-002 |
| REQ-HRS-010 Leave approval | notifications never sent (no listener) | BUG-HRS-001 |
| REQ-HRS-012 LOP | manual stub pending Attendance (`att_staff_attendances`) | RISK-HRS-002 (known) |
| REQ-HRS-014 Salary assignment | update() bypasses band/single-active | VAL-HRS-002 |
| REQ-HRS-015/027 PF | wrong PF base (50%-of-gross) | BUG-HRS-002 |
| REQ-HRS-026/027 Payroll compute | skips unassigned employees instead of blocking | BUG-HRS-003 |
| REQ-HRS-029 Approve/lock | Accounting JV event has no listener | BUG-HRS-001 |
| REQ-HRS-031 Payslip | not password-protected; raw download not signed | SEC-HRS-001 |
| REQ-HRS-032/033 Bulk payslip / email | synchronous, no Jobs; email never sent (no listener) | PERF-HRS-001, BUG-HRS-001 |
| REQ-HRS-038 Form 16 | generateAll() is a no-op stub; no April-15 guard | BUG-HRS-004 |
| ALL | **0 automated tests** (`tests/` has only `.gitkeep`) | RISK-HRS-007 (known) |

Architecture (out of audit scope, hand to Enterprise Architect): dual leave engine `hrs_leave_*` vs SCE
`sch_employee_leave_*` (RISK-HRS-001) — unchanged; resolve canonical ownership before further leave work.

---

## Business-Rule Enforcement (Mode C)

| BR | Type | Location | Status | Link |
|---|---|---|---|---|
| BR-HRS-001 balance ≥ 0 (except LWP) | Validation | LeaveService::applyLeave | ENFORCED (no row lock) | DATA-HRS-003 |
| BR-HRS-002 no overlap | Validation | LeaveService::applyLeave | **PARTIAL** (enclosing-range miss) | DATA-HRS-002 |
| BR-HRS-003 carry-forward cap | Calculation | LeaveService::initializeBalances `min(max(remaining,0),cap)` | ENFORCED | — |
| BR-HRS-004 backdated window | Validation | LeaveService::applyLeave | ENFORCED | — |
| BR-HRS-005 medical cert for SL | Validation | — | **MISSING** | VAL-HRS-001 |
| BR-HRS-006 gender restriction | Validation | — | **MISSING** | VAL-HRS-001 |
| BR-HRS-007 min service | Validation | — | **MISSING** | VAL-HRS-001 |
| BR-HRS-008 cancel only if future; restore | Workflow | LeaveService::cancelLeave | ENFORCED | — |
| BR-HRS-009 LOP confirm = HR only | Permission | LopController gate `hrs.lop.confirm` | ENFORCED | — |
| BR-HRS-010 single active assignment | Concurrency | SalaryAssignmentService::assign | **PARTIAL** (no lock; update() bypass) | DATA-HRS-003, VAL-HRS-002 |
| BR-HRS-011 CTC in grade band | Validation | SalaryAssignmentService::validateCtcInGrade | **PARTIAL** (skipped on update() & null grade) | VAL-HRS-002 |
| BR-HRS-012 PF mandatory if basic ≤ 15k | Validation | computePf (uses applicable_flag, not threshold) | **PARTIAL** | BUG-HRS-002 |
| BR-HRS-013 ESI if gross ≤ 21k | Validation | computeEsi (`$grossAfterLwp > 21000` guard) | ENFORCED | — |
| BR-HRS-015 PAN/bank encrypted | Validation | EmploymentDetail/ComplianceRecord `=> 'encrypted'` casts | ENFORCED | — |
| BR-HRS-016 KPI weights = 100 | Validation | (KpiTemplate path — not deep-read) | LIKELY (verify) | — |
| BR-HRS-023 soft-delete only | Workflow | violated by initializeBalances forceDelete | **MISSING** | DATA-HRS-001 |
| BR-HRS-024 remarks mandatory | Validation | ApproveLeaveRequest `remarks: required\|min:5` (+ Reject) | ENFORCED | — |
| BR-PAY-001 one regular run/month | Concurrency | DB unique `uq_pay_run_month_type` on (payroll_month,run_type) | ENFORCED at DB (no app-level pre-check → raw 500 on dup) | P2 UX note |
| BR-PAY-002 block compute if any unassigned | Validation | computeRun catches & continues | **MISSING** | BUG-HRS-003 |
| BR-PAY-003 locked immutable | Workflow | PayrollRunService::guardEditable + override abort_if isLocked | ENFORCED (service-layer guard; no DB trigger — acceptable per NFR-015) | — |
| BR-PAY-004 PF/ESI mandatory for applicable | Validation | computePf/computeEsi | **PARTIAL** (PF base wrong) | BUG-HRS-002 |
| BR-PAY-005 override needs reason; logged | Validation | OverridePayrollDetailRequest + PayrollOverride row | ENFORCED | — |
| BR-PAY-007 export only after approved | Permission | (BankExportService — verify gate on status) | LIKELY (verify) | — |
| BR-PAY-009 Form16 after Apr 15 | Validation | — | **MISSING** | BUG-HRS-004 |
| BR-PAY-010 LWP = (gross÷working)×LOP | Calculation | computeEmployee `round(($grossMonthly/$workingDays)*$lopDays,2)` | ENFORCED ✅ | — |
| BR-PAY-011 structure must include Basic | Validation | (SalaryStructureService — not deep-read) | LIKELY (verify) | — |

---

## Systemic-Pattern Scorecard (Mode D, scoped to HRS)

| Pattern | Present? | Count / Evidence | Finding |
|---|---|---|---|
| D17 fillable vs missing column | No (spot-clean) | reconcile clean | — |
| D24 permission-prefix chaos | **Yes** | `hrs.*`/`pay.*` not `tenant.*` + dead dual scheme | SEC-HRS-003 |
| D25 `$request->all()` | No | 0 sites | — (above baseline) |
| D29 `->enum()` in migrations | **Yes** | 27 across 20 files | MIG-HRS-001 |
| D30 authorize(){return true;} | **Yes** | 27/27 FormRequests | SEC-HRS-002 |
| D36 generated-column degraded | No | no GENERATED cols in HRS | — |
| D37 status-master FK as string | No | enums + string casts consistent | — |
| D38 SoftDeletes vs missing deleted_at | No | tables have deleted_at/timestamps | — |
| D39 permission referenced-not-seeded | Partial | custom perms seeded; HR/Payroll Manager roles unmapped | SEC-HRS-004 |
| Layer 2.5 missing/cross-DB FK target | No | sch_/sys_ targets exist; intra-module pay_↔hrs_ intentional | — |
| Layer 6.2 initialize() leak | No | 0 in module | — |
| Layer 10.1 job tenancy/retry | N/A→gap | no Jobs exist at all | PERF-HRS-001/JOB-HRS-001 |
| TEN-RTG-001 module-subscription gate | **Yes** | no EnsureTenantHasModule in RSP | TEN-HRS-001 |

---

## vs Platform Baseline

- **Better than baseline:** 0 `$request->all()` (baseline 24 sites); 0 INT-PK tables (baseline 428/658);
  correct tenancy stack (no D23); no initialize() leaks; encryption casts actually applied; no debug/backup files.
- **At baseline:** D30 27/27 authorize()=true (platform 90%); D29 27 enums (hst 28, sch 22 — HRS comparable);
  TEN-RTG-001 module-gate missing (platform-wide); no tests (platform norm for recently-built modules).
- **Module-specific risk above baseline:** the P0 force-delete data-loss path and the wholly-unwired event layer
  (Accounting JV + notifications dead) are HRS-local, not platform patterns.

---

## Recommended Fix Order

1. **DATA-HRS-001 (P0)** — stop the force-delete; make balance init idempotent + guard re-run. *(unblocks deploy gate)*
2. **BUG-HRS-001 (P1)** — wire event listeners (Accounting JV, notifications, increment). *(restores integration)*
3. **BUG-HRS-002 + BUG-HRS-003 (P1)** — correct PF base from actual Basic; block compute on any unassigned employee. *(payroll correctness/compliance)*
4. **SEC-HRS-001 (P1)** — password-protect payslip PDFs + signed download. *(PII compliance)*
5. **BUG-HRS-004 (P1)** — implement Form 16 + April-15 guard; VAL-HRS-001 leave rules.
6. **PERF-HRS-001 (P1)** — queued Jobs for bulk payslip/Form16/email (after platform DEPLOY-HRZ-01).
7. **P2 batch** — DATA-HRS-002 overlap predicate; VAL-HRS-002 update() through service; DATA-HRS-003 row locks;
   MIG-HRS-001 enum→dropdown; SEC-HRS-002 authorize() gates; SEC-HRS-003/004 permission taxonomy & role map; TEN-HRS-001.
8. **Testing** — build the Pest suite (RISK-HRS-007) covering BR-PAY-010, lock immutability, encryption, the P0/P1 fixes.
9. **Architecture (separate)** — Enterprise Architect resolves dual leave engine (RISK-HRS-001).

---

*Mode X complete. Findings: 1×P0, 7×P1, 8×P2, 3×P3 (each coded once; de-duplicated across A/B/C/D/G).*
*Health 40/100 (P0-capped). DEPLOY: NO-GO.*
