# Module Knowledge — HrStaff (HR & Payroll)

| Property | Value |
|---|---|
| Module Name | HrStaff (HR & Payroll) |
| Module Code | **HRS** |
| Table Prefixes | `hrs_*` (HR, 23 tables) + `pay_*` (Payroll, 10 tables) — both in this one module |
| Module Type | Tenant (database-per-tenant; stancl/tenancy v3.9; no `tenant_id` columns) |
| Namespace | `Modules\HrStaff` |
| App code dir | `/Users/bkwork/Herd/prime_ai/Modules/HrStaff` |
| Route file | `Modules/HrStaff/routes/web.php` (registered as tenant routes via RouteServiceProvider) |
| DDL | `{OLD_REPO}/2-DDL_Tenant_Consolidated/HrStaff_Payroll_DDL_v2.sql` (33 `CREATE TABLE`) |
| V2 Requirement | `{REQUIREMENT_OLD}/HRS_HrStaff_Requirement_v2.md` (1450 lines, 46 FRs) + `HRS_HrStaff_Requirement.md` (v1 baseline) |
| V1 screen specs | `{REQUIRE_DETAIL_V1}/HrStaff_v1/` |
| FRD | `{FRD_DIR}/HRS_FRD_Complete_2026-06-29.md` (Complete Analysis Pack) |
| Status (verified 2026-06-29) | **Substantially built (~85–90% scaffolded)** — NOT greenfield |

> Seeded 2026-06-29 by Business Analyst (parallel worker). All counts verified against the live
> filesystem and three-way reconciled (DDL ↔ migration ↔ model). Every claim below was confirmed in code.

---

## Module Facts (verified counts — `ls`/`grep` against live tree)

| Artifact | Count | Notes |
|---|---|---|
| DDL tables | **33** | 23 `hrs_*` + 10 `pay_*` (DDL summary block confirms) |
| Tenant migrations (hrs_/pay_) | **33** | `database/migrations/tenant/2026_06_16_1603*` — 1:1 with DDL |
| Models | **33** | each sets `protected $table`; 23 `hrs_*` + 10 `pay_*` (all map cleanly) |
| Controllers | **26** | V2 proposed 16; actual exceeds spec (split appraisal/increment/report/menu/dashboard controllers) |
| Services | **15** | incl. PayrollComputationService, TdsComputationService, PayrollRunService, PayslipService, BankExportService, LeaveService, LeaveApprovalService, AppraisalService, IncrementService, ComplianceService, EmploymentService, HolidayService, IdCardService, SalaryAssignmentService, SalaryStructureService |
| Form Requests | **27** | V2 proposed 30 |
| Policies | **17** | in-module `app/Policies/` (NOT central `app/Policies/`) |
| Events | **5** | `LeaveApproved`, `LeaveRejected`, `PayrollApproved`, `PayrollLocked`, `AppraisalFinalized` |
| Listeners / Jobs dirs | **absent** | no `app/Listeners/`, no `app/Jobs/` — wiring via `EventServiceProvider`; spec'd `GeneratePayslipsJob` not present as a class (see gaps) |
| Blade views | **108** | V2 proposed ~110; includes tabbed "pages/" menu shells + per-entity CRUD + PDF blades + report partials |
| Seeders | **9** | incl. `HrsLeaveTypeSeeder`, `HrsLeavePolicySeeder`, `HrsPtSlabSeeder`, `HrsIdCardTemplateSeeder`, `PaySalaryComponentSeeder`, `PaySalaryStructureSeeder`, `HrsPermissionSeeder` |
| Permissions | **26** | 16 `hrs.*` + 10 `pay.*` (seeded by `HrsPermissionSeeder`) |
| Routes | comprehensive | dashboard + 5 tabbed menu pages + full CRUD/workflow/report/statutory/self-service |

---

## DDL Table Inventory (33)

### `hrs_*` — HR Layer (23)
**HR Master / config:** `hrs_leave_types`, `hrs_holiday_calendars`, `hrs_pay_grades`, `hrs_id_card_templates`, `hrs_leave_policies`, `hrs_pt_slabs`, `hrs_kpi_templates`, `hrs_kpi_template_items`
**Employee HR records:** `hrs_employment_details` (1:1 with `sch_employees`, bank a/c encrypted), `hrs_employment_history` (immutable audit), `hrs_employee_documents` (→ `sys_media`, expiry reminders)
**Leave:** `hrs_leave_balances`, `hrs_leave_applications` (FSM), `hrs_leave_approvals` (per-step log), `hrs_leave_balance_adjustments` (audit), `hrs_lop_records` (LOP flags)
**Compliance:** `hrs_compliance_records` (pf/esi/tds/gratuity/pt), `hrs_pf_contribution_register`, `hrs_esi_contribution_register`
**Appraisal:** `hrs_appraisal_cycles`, `hrs_appraisals` (FSM), `hrs_appraisal_increment_flags` (bridge → payroll increment)
**Salary link:** `hrs_salary_assignments` (employee↔structure↔CTC; new row per revision)

### `pay_*` — Payroll Layer (10)
`pay_salary_components` (14 seeded), `pay_salary_structures`, `pay_salary_structure_components` (junction), `pay_payroll_runs` (FSM), `pay_payroll_run_details` (per-employee computed; immutable after lock), `pay_payroll_overrides` (audit), `pay_payslips` (1:1 run_detail; → `sys_media`; password PDF), `pay_tds_ledger` (YTD cumulative), `pay_form16` (per FY), `pay_increment_policies` (rating→increment slabs)

### Intentional cross-prefix FKs (within this one module)
- `hrs_salary_assignments.pay_salary_structure_id` → `pay_salary_structures.id`
- `pay_payroll_run_details.salary_assignment_id` → `hrs_salary_assignments.id`

### Consumed `sch_*` / `sys_*` masters (NOT owned here — read/extend only)
- `sch_employees` (`id` = **INT UNSIGNED** — all FK employee columns are INT UNSIGNED, not BIGINT)
- `sch_org_academic_sessions_jnt` (`id` = **SMALLINT UNSIGNED**) — used wherever V2 said `sch_academic_years` (which does NOT exist)
- `sch_department`, `sch_designation` (SINGULAR), `sch_employees_profile` (`reporting_to`)
- `sys_media` (files), `sys_users` (`created_by`/`updated_by`), `sys_activity_logs`

---

## Known Gaps & Open Issues

### Technical Audit — Mode X (2026-06-29, Technical Auditor) — Health 40/100 (P0-capped)
> Report: `3-Audit_Reports/V1_Jun-2026/HrStaff_Complete_Audit_2026-06-29.md`. Module is ~85% built and ABOVE
> platform norms on tenancy/auth/mass-assignment/IDOR. Issue codes namespaced **HRS** (PAY token owned by Payment module).
- **DATA-HRS-001 (P0):** `LeaveService::initializeBalances()` unconditionally `forceDelete()`s all leave balances
  for the year before recreating → permanent loss of `used_days`/carry-forward/adjustments; orphans
  `hrs_leave_balance_adjustments` FK; violates BR-HRS-023. Live route. **Deploy NO-GO.**
- **BUG-HRS-001 (P1):** `EventServiceProvider $listen=[]`, `$shouldDiscoverEvents=true`, but **no `app/Listeners/`
  directory** → all 5 domain events fire into nothing. Accounting Journal Voucher (REQ-HRS-029) never created;
  leave/payslip notifications (REQ-HRS-010/033) never sent. (Reusable lesson — see Lessons Learned.)
- **BUG-HRS-002 (P1):** PF base = hardcoded `min(gross*0.50,15000)`, not actual Basic component → wrong statutory
  PF/ECR (BR-PAY-004); applicability uses `applicable_flag` not basic≤15k (BR-HRS-012).
- **BUG-HRS-003 (P1):** `computeRun()` swallows per-employee "no salary assignment" exception & continues → run
  reaches `computed` with employees silently skipped (BR-PAY-002 not enforced; should block the whole run).
- **BUG-HRS-004 (P1):** `Form16Controller::generateAll()` is a no-op stub; no April-15 guard (BR-PAY-009); REQ-HRS-038 dead.
- **SEC-HRS-001 (P1):** payslip PDFs not password-protected (NFR-HRS-007/REQ-HRS-031); raw `getPath()` download (NFR-006).
- **PERF/JOB-HRS-001 (P1):** bulk payslip/Form16/email synchronous; no `app/Jobs/`; times out at scale (NFR-004).
- **VAL-HRS-001 (P1):** leave apply skips BR-HRS-005 (medical cert) / 006 (gender) / 007 (min service); holiday
  `applicableTo` not passed to calculateDays.
- **P2:** DATA-HRS-002 overlap predicate misses enclosing-range leave; VAL-HRS-002 `SalaryAssignment::update()`
  bypasses band/single-active service; DATA-HRS-003 missing row locks (BR-HRS-001/010 concurrency); SEC-HRS-002
  27/27 FormRequests `authorize(){return true}` (D30); MIG-HRS-001 27 `->enum()` over 20 migrations (D29) +
  `applicable_to` casing drift; SEC-HRS-003 `hrs.*`/`pay.*` perms not `tenant.*` (D24) + dead `tenant.hrs-*` set;
  SEC-HRS-004 "HR Manager"/"Payroll Manager" roles unmapped in seeder (D39-adjacent); TEN-HRS-001 RSP lacks
  `EnsureTenantHasModule`.
- **Verified ENFORCED:** BR-PAY-010 LWP formula; BR-PAY-003 lock immutability (service guard); BR-HRS-015
  encryption; BR-PAY-001 one-run/month DB unique; BR-HRS-008 cancel-restore; BR-HRS-024 remarks; BR-HRS-013 ESI.

### P0 — Architecture boundary (HAND OFF TO ENTERPRISE ARCHITECT)
- **DUAL / DUPLICATE LEAVE SUBSYSTEM.** HrStaff ships its own leave engine (`hrs_leave_types`,
  `hrs_leave_policies`, `hrs_leave_balances`, `hrs_leave_applications`, `hrs_leave_approvals`,
  `hrs_leave_balance_adjustments`, `hrs_holiday_calendars`, `hrs_lop_records`). **In parallel,
  SchoolSetup_EmployeeSetup (SCE) ships a more elaborate staff-leave engine** (11 `sch_*` tables:
  `sch_annual_leave_sessions`, `sch_staff_leave_types`, `sch_staff_leave_config`,
  `sch_leave_approval_policies`, `sch_leave_approval_policy_levels`, `sch_leave_approval_level_approvers`,
  `sch_employee_leave_balance`, `sch_employee_leave_applications`, `sch_employee_leave_approvals`,
  `sch_employee_leave_application_docs`, `sch_employee_leave_application_remarks`). The HRS DDL itself
  comments *"Maximum part of Leave Management has been created in Employee Module."* These are two
  competing implementations of the same capability. **Decision needed:** which is canonical; the other
  should be deprecated or HRS should consume the `sch_*` leave engine. (Separately, `std_leave_*` =
  StudentProfile student leave — unrelated, do not conflate.)

### P1
- **`att_staff_attendances` does not exist** (Attendance module pending). `LeaveService::runLopReconciliation`
  is a documented **stub** ("reads att_staff_attendances; for now, accepts manual input"). LOP flagging is
  therefore manual until Attendance ships. Payroll LWP depends on confirmed LOP.
- **`GeneratePayslipsJob` not present** — V2 spec'd bulk payslip + Form 16 + payslip-email as queued Jobs,
  but there is no `app/Jobs/` directory. Confirm whether bulk generation is synchronous (risk vs NFR-004).
- **`pay_payroll_formula_changelog`** referenced in NFR-009 does not exist in the DDL.

### P2 / Boundary notes
- `emp_code` (`EMP/YYYY/NNN`) is generated by **SchoolSetup on `sch_employees` creation** (OQ-001 = A), not HrStaff.
- Holiday calendar: V2 OQ-004 *preferred* a shared `sch_holiday_calendars` (used by Timetable + Attendance too),
  but the build uses module-local `hrs_holiday_calendars` — potential future consolidation.
- Accounting integration is **event-driven only** (`PayrollApproved` → Journal Voucher); no `acc_*` FK.

---

## Design Decisions Made (from V2 §16 + DDL corrections)
- D(HRS-merge): Payroll (`pay_*`) merged into HrStaff rather than a separate `prl_*` module — tightest-coupled pair kept intra-module.
- Bank a/c number + PAN stored via Laravel `encrypt()` (TEXT/VARCHAR for variable cipher length); never logged plaintext (BR-HRS-015).
- Payslip PDF password = `PAN last 4 + DDYYYY(DOB)` (OQ-013 = A).
- Payroll computation sync ≤100 employees, queued >100 (OQ-009 = A).
- Separate `Payroll Manager` role distinct from `HR Manager` (OQ-010 = A).
- Mid-year TDS regime change supported (OQ-011 = A).
- Bank file format bank-specific (SBI/HDFC/ICICI), configurable per school (OQ-012 = B).
- DDL corrections vs spec: `sch_academic_years`→`sch_org_academic_sessions_jnt`; employee FKs = INT UNSIGNED; `sch_department`/`sch_designation` singular.

## Cross-Module Dependencies
- **Inbound (reads):** SchoolSetup (`sch_employees`, `sch_employees_profile`, `sch_department`, `sch_designation`, `sch_org_academic_sessions_jnt`), Attendance (`att_staff_attendances` — pending), System (`sys_media`, `sys_users`, `sys_activity_logs`).
- **Outbound (provides):** Accounting (`PayrollApproved` event → salary Journal Voucher; gratuity-on-exit event), Notification (`ntf_notifications` — leave decisions, document expiry, payslip email).
- **Overlap to resolve:** SchoolSetup_EmployeeSetup staff-leave engine (see P0).

## Lessons Learned
- [2026-06-29 | Business Analyst] HRS is far past "greenfield": 33 tables migrated, 26 controllers, 15 services, 108 views, 17 policies, 5 events, 9 seeders, 26 permissions all present. Verify before stating status.
- [2026-06-29 | Business Analyst] Two leave engines coexist (hrs_* vs sch_employee_leave_*). The DDL author flagged it in a comment. Any HRS leave work must first resolve canonical ownership with the Enterprise Architect.
- [2026-06-29 | Business Analyst] LOP reconciliation is a real stub pending the Attendance module — `att_staff_attendances` is referenced in a comment in LeaveService but does not exist; manual input is the current path.
- [2026-06-29 | Business Analyst] V2 §6 schema references `sch_academic_years` throughout, but that table does not exist; the DDL correctly substitutes `sch_org_academic_sessions_jnt` (SMALLINT). Trust the DDL, not V2 §6, for FK types.
- [2026-06-29 | Technical Auditor] **Event-driven integration is unwired:** module ships 5 events but `EventServiceProvider $listen=[]` + `$shouldDiscoverEvents=true` with NO `app/Listeners/` dir → events vanish (no Accounting JV, no notifications). Reusable rule: verify `app/Listeners/` exists before clearing any event-driven integration as "wired".
- [2026-06-29 | Technical Auditor] **Snapshot correction — module is NOT ENUM-free:** migrations contain **27 `->enum()` across 20 files** (status FSMs + type columns), a D29 violation; `applicable_to` even has casing drift (`['All','Non-Teaching','Teaching']` vs lowercase). NOTE: the live shell `grep` is aliased to `ugrep`, which treats a pattern starting with `-` (`->enum(`) as an option and returns a false negative — always use `grep -e "->enum("`.
- [2026-06-29 | Technical Auditor] **What's genuinely solid (don't re-flag):** tenancy stack correct (full middleware + auth/verified, no D23); 0 `$request->all()`; 0 debug/Schema-introspection; encryption casts applied; salary/payslip/leave endpoints have proper ownership checks (NO IDOR); BR-PAY-010 LWP formula, BR-PAY-003 lock immutability, BR-HRS-015 encryption, BR-PAY-001 DB-unique all verified enforced. The real risk is data-integrity + unwired integration + compliance correctness, not security/tenancy.
- [2026-06-29 | Technical Auditor] Issue-code namespace: use **HRS** for all findings (incl. payroll). The `PAY` token belongs to the Payment module (`SEC-PAY-001..008`, `BUG-PAY-001` already in known-issues.md, prefix `pmt_`) — never reuse.

## FRD Summary
- **File:** `{FRD_DIR}/HRS_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — FRD + RTM + BR register + Conditions + FSMs + Data Dictionary + Dependency Map + NFR + Risk + Prioritization + Sprint tasks + User Stories + Reporting/KPI).
- **Counts:** 46 functional requirements (REQ-HRS-001…046), 45 business rules (BR-HRS-001…024 + BR-PAY-001…012, plus general), 3 workflows/FSMs, 4 payroll reports (RPT-HRS-001…004) + several operational exports, 6 events.
- **Priority split:** P0 = 18, P1 = 20, P2 = 8 (see FRD §10.4).

## Pending Next Steps
1. Enterprise Architect: resolve dual leave-engine boundary (HRS `hrs_leave_*` vs SCE `sch_employee_leave_*`).
2. DB Architect / Technical Auditor: schema gap analysis (confirm `pay_payroll_formula_changelog`, queued-job classes).
3. Technical Auditor (Mode B): FRD-driven code gap — verify each REQ's controller/service/policy actually enforces its BRs (esp. lock immutability BR-PAY-003, encryption BR-HRS-015, weight-sum BR-HRS-016).
4. Testing Architect: no test files exist yet (`tests/` only has `.gitkeep`) — design coverage against §14 of V2.

## Version History
- v1.0 — 2026-06-29 — Seeded from scratch by Business Analyst; counts verified live; Complete FRD produced same day.
- v1.1 — 2026-06-29 — Technical Auditor Mode X Complete Audit. Health 40/100 (P0-capped). Added audit findings block (1×P0, 7×P1, 8×P2, 3×P3), enforced-BR verification, and lessons (unwired events, enum snapshot correction, ugrep gotcha, no-IDOR confirmation). Report: `3-Audit_Reports/V1_Jun-2026/HrStaff_Complete_Audit_2026-06-29.md`.
