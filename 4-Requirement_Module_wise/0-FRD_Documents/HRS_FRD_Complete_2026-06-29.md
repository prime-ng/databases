# HRS — HrStaff (HR & Payroll) — Complete Analysis Pack (FRD + Catalog)

**Module:** HrStaff (HR & Payroll) | **Code:** HRS | **Prefixes:** `hrs_*` (HR) + `pay_*` (Payroll)
**Date:** 2026-06-29 | **Author:** Business Analyst (parallel worker)
**Type:** Tenant module (database-per-tenant; data is isolated per school; no `tenant_id` columns)
**Sources reconciled:** V2 requirement (`HRS_HrStaff_Requirement_v2.md`, 46 FRs) · V1 baseline · DDL `HrStaff_Payroll_DDL_v2.sql` (33 tables) · live Laravel module (`Modules/HrStaff`, verified counts) · tenant migrations.

> **Single source of truth.** This document assigns the stable `REQ-HRS-/BR-HRS-/BR-PAY-/RPT-HRS-/NFR-HRS-/RISK-HRS-` IDs that downstream gap analyses reuse. Do NOT renumber. The `## Section`s below ARE the analysis pack (FRD first, then RTM, rules, flows, data dictionary, dependency map, NFRs, risks, prioritization, sprint tasks, user stories, reporting). Module knowledge: `AI_Brain/module-knowledge/HRS_HrStaff.md`.

## Table of Contents
1. Module Overview · 2. User Roles & Access · 3. Functional Requirements · 4. Business Rules Register · 5. Data Requirements (incl. Technical Data Dictionary) · 6. Workflows & State Machines · 7. Reporting & Analytics + KPIs · 8. Future Enhancement Log · 9. Non-Functional Requirements · 10. Gap Analysis Readiness Index · 11. Requirements Traceability Matrix · 12. Requirement Conditions & Validation Catalog · 13. Cross-Module Dependency Map · 14. Risk Register · 15. Prioritization · 16. Effort Estimation & Sprint Tasks · 17. User Stories (P0/P1) · A. Boundary Note for Enterprise Architect

---

## Section 1 — Module Overview

### 1.1 Purpose
HrStaff is the school's complete **Human Resources workflow and Payroll engine**. It extends the basic
employee record (owned by School Setup) with full employment details, document storage, leave
administration, statutory compliance (Provident Fund, Employee State Insurance, Tax Deducted at Source,
Gratuity, Profession Tax), performance appraisal, staff identity cards, and an end-to-end monthly payroll
cycle — salary structure design, computation, review, approval, lock, payslips, bank disbursement files,
TDS and Form 16, statutory returns, and payroll analytics.

### 1.2 Business Value
- Replaces paper leave registers and Excel payroll with an auditable, balance-enforced, multi-level system.
- Guarantees statutory accuracy (PF/ESI/PT/TDS) and on-time Form 16, reducing compliance risk.
- Links appraisal outcomes directly to salary increments, removing subjective off-system decisions.
- Gives every employee self-service access to leave balances, payslips, ID card, and Form 16.

### 1.3 Scope
**In scope:** employment record extension; employment-change history; document repository with expiry
reminders; staff ID card generation; leave types, holiday calendar, leave policy, balance initialization
& carry-forward, leave application, multi-level approval, balance adjustments; Loss-of-Pay (LOP)
reconciliation; pay grades; salary component & structure masters; per-employee salary assignment with CTC
breakdown; PF/ESI/TDS/Gratuity/PT compliance records & contribution registers; KPI templates, appraisal
cycles, self-appraisal, manager review, finalization; monthly & supplementary payroll runs with
computation/review/approval/lock; payslip generation, email, self-service download; bank NEFT/RTGS file
export and payment-status tracking; monthly TDS computation and annual Form 16; PF ECR and ESI challan
exports; appraisal-linked variable pay and ad-hoc salary revision; payroll reports (salary register, bank
summary, CTC analysis, trend).

**Out of scope** (≥3): actual PF/ESI remittance and bank payment execution (Finance/Accounting); payroll
Journal Voucher posting (Accounting — triggered by event); biometric device sync (Attendance module);
recruitment / applicant tracking (not planned); staff mobile-app portal (future); gratuity disbursement
payment (Accounting).

### 1.4 Terminology (business register)
- **CTC** — Cost to Company; the full annual cost of employing a person (earnings + employer contributions).
- **Gross / Net Pay** — earnings before deductions / amount actually credited after all deductions.
- **LOP / LWP** — Loss of Pay / Leave Without Pay; salary deducted for unapproved absence days.
- **Salary Structure** — a reusable template of earning and deduction components and how each is calculated.
- **Payroll Run** — one month's batch salary processing for all (or supplementary) employees.
- **Compliance Record** — a per-employee statutory enrolment (PF/ESI/TDS/Gratuity/PT) with reference numbers.
- **Appraisal Cycle** — a time-boxed performance review round driven by a KPI template.
- **Form 16** — the annual tax certificate (Part A employer + Part B employee) issued to each taxed employee.
- **PF ECR** — Provident Fund Electronic Challan Return filed monthly with EPFO.

### 1.5 Build status (verified 2026-06-29)
Substantially built (~85–90% scaffolded): 33 tables migrated, 26 controllers, 15 services, 27 form
requests, 17 policies, 5 events, 108 Blade views, 9 seeders, 26 permissions. No automated tests yet.
Two open structural items (dual leave engine; pending Attendance dependency) — see Section A and Section 14.

---

## Section 2 — User Roles & Access

### 2.1 Actors
| Actor | Description |
|---|---|
| HR Manager | Owns all HR records, leave config & approvals, compliance, appraisals, leave balance adjustments, LOP confirmation. |
| Payroll Manager | Initiates/computes/locks payroll, generates payslips & Form 16, exports bank/statutory files, processes increments. |
| Principal | Views everything; final-level leave approval; appraisal finalization authority; **payroll approval**. |
| Head of Department (HOD) | First-level leave approval for their department; initiates/reviews department appraisals. |
| Employee (self-service) | Applies for leave; views balances; submits self-appraisal; downloads own payslip, ID card, Form 16. |
| Accountant | Read-only on salary assignments, PF/ESI registers, payroll reports. |
| System | Auto-reconciles LOP (when Attendance available), fires notifications/events, computes payroll & TDS. |

### 2.2 Role–Feature Matrix (summary; full permission grid in Section 4 / source §10.1)
| Capability area | HR Mgr | Payroll Mgr | Principal | HOD | Employee | Accountant |
|---|---|---|---|---|---|---|
| Employment / documents / ID card | Manage | – | View | – | Own | – |
| Leave config & balances | Manage | – | View | Dept | Own | – |
| Leave approval | L1+L2 | – | L2 | L1 | Apply | – |
| LOP confirmation | Yes | – | – | – | – | – |
| Salary / compliance | Manage | Manage | – | – | – | Read |
| Appraisal | Manage | – | Review/Finalize | Review | Self | – |
| Payroll run | – | Initiate/Compute/Lock | Approve | – | – | – |
| Payslip / Form 16 | – | Generate | – | – | Own download | – |
| Bank file / statutory export | – | Export | – | – | – | – |
| Payroll reports | View | View | View | – | – | View |

---

## Section 3 — Functional Requirements

> Register: business language. Each REQ: ID · Priority (P0 Core / P1 Standard / P2 Enhanced) · Tags ·
> Description · Actors (Initiates / Processes / Views) · Business Rules · Acceptance Criteria (YES/NO).
> REQ-HRS-NNN are independently numbered from 001; the trailing "(src FR-HRS-NNN)" preserves V2 traceability.

### 3A — Staff HR Records

**REQ-HRS-001 — Employee HR Details Extension** (src FR-HRS-001) · P0 · [DATA_ENTRY]
HR Manager records, per employee, the HR extension: contract type (permanent / contractual / probation /
part-time / substitute), probation end & confirmation dates, notice period, bank account details
(encrypted), and emergency contact. One HR record per employee. The employee code (`EMP/YYYY/NNN`) is
supplied by School Setup, not created here.
*Initiates:* HR Manager · *Processes:* System · *Views:* HR Manager, Principal, owner Employee.
*Rules:* BR-HRS-015, BR-HRS-021, BR-HRS-023.
*Acceptance:* (a) Saving with all required fields creates exactly one HR record per employee; a second attempt edits the same record. (b) Bank account number is never shown or logged in plain text. (c) Contract type only accepts the five allowed values.

**REQ-HRS-002 — Employment History Log** (src FR-HRS-002) · P1 · [WORKFLOW][DATA_ENTRY]
The system records an immutable history entry for every change to contract type, department, designation,
pay grade, or salary; each entry keeps old value, new value, effective date, who changed it, and remarks.
HR Manager views a per-employee timeline.
*Rules:* BR-HRS-023. *Acceptance:* (a) Any tracked change writes one history row. (b) History rows cannot be edited or deleted. (c) Timeline lists changes newest-first with the actor named.

**REQ-HRS-003 — Employee Document Repository** (src FR-HRS-003) · P0 · [DATA_ENTRY][NOTIFICATION]
HR Manager and the employee can upload categorized documents (appointment letter, ID proof, certificates,
etc.) with issue/expiry dates. Files are stored securely (no public link). The system sends a renewal
reminder 30 days before any expiry date.
*Rules:* BR-HRS-022, BR-HRS-023. *Acceptance:* (a) Upload requires a document type and file. (b) A document with an expiry date triggers a reminder 30 days prior. (c) Files are only retrievable via a secure, time-limited link.

**REQ-HRS-004 — Staff ID Card Generation** (src FR-HRS-004) · P1 · [REPORT][CONFIGURATION]
HR Manager generates a printable ID card (photo, name, designation, department, employee code, QR code of
the code). Layout is configurable per school via an ID card template; the generated card is stored and
downloadable. Employee can view/download their own.
*Acceptance:* (a) Generating produces a PDF using the school's default template. (b) The QR code encodes the employee code. (c) Employee can download only their own card.

### 3B — Leave Management

**REQ-HRS-005 — Leave Type Master** (src FR-HRS-005) · P0 · [CONFIGURATION]
HR Manager configures leave types (code, name, annual days, carry-forward cap, applicability, paid/unpaid,
medical-certificate rule, half-day allowed, gender restriction, minimum service, max consecutive days).
Seven defaults are pre-seeded (CL, EL, SL, ML, PL, CO, LWP). Values are config-driven so a school can extend.
*Rules:* BR-HRS-003, BR-HRS-005, BR-HRS-006, BR-HRS-007, BR-HRS-023. *Acceptance:* (a) Leave type code is unique. (b) Disabling a type hides it from new applications but preserves history. (c) Defaults seed on setup.

**REQ-HRS-006 — Holiday Calendar** (src FR-HRS-006) · P1 · [CONFIGURATION]
HR Manager maintains a per-academic-year holiday calendar (date, name, type national/state/school/optional,
applicability). Leave day-count **excludes** holidays and weekends. Employees may elect up to the
configured number of optional holidays per year.
*Acceptance:* (a) A leave spanning a holiday/weekend excludes those days from the counted total. (b) Calendar is scoped to the selected academic year. (c) Optional-holiday elections cannot exceed the policy count.

**REQ-HRS-007 — Leave Policy Configuration** (src FR-HRS-007) · P2 · [CONFIGURATION]
HR Manager sets school-wide policy: max backdated days, minimum advance days, approval levels (1 or 2),
optional-holiday count. A null academic year means the global default policy.
*Rules:* BR-HRS-004. *Acceptance:* (a) Approval levels accept only 1 or 2. (b) A year-specific policy overrides the global default for that year.

**REQ-HRS-008 — Leave Balance Initialization** (src FR-HRS-008) · P0 · [WORKFLOW]
HR Manager initializes annual leave balances per academic year, creating one balance per employee per leave
type. Carry-forward = the smaller of last year's closing balance and the type's carry-forward cap; the
excess lapses. Manual adjustments are logged with a mandatory reason.
*Rules:* BR-HRS-003. *Acceptance:* (a) Initialization creates balances for all active employees. (b) Carry-forward never exceeds the cap. (c) Every manual adjustment records a reason and adjuster.

**REQ-HRS-009 — Leave Application** (src FR-HRS-009) · P0 · [DATA_ENTRY][WORKFLOW]
Employee applies for leave (type, dates, half-day option, reason, optional supporting document). On submit
the system validates sufficient balance, no overlap with existing leave, minimum service, and date window;
the application starts as Pending.
*Rules:* BR-HRS-001, BR-HRS-002, BR-HRS-004, BR-HRS-005, BR-HRS-006, BR-HRS-007. *Acceptance:* (a) An overlapping date range is rejected. (b) Insufficient balance (except LWP) is rejected. (c) Day-count is auto-calculated excluding holidays/weekends.

**REQ-HRS-010 — Leave Approval Workflow** (src FR-HRS-010) · P0 · [APPROVAL][WORKFLOW][NOTIFICATION]
Approval follows the configured level count (HOD then Principal). Each action (approve / reject /
return-for-clarification) is logged with mandatory remarks. Final approval increases used balance and
notifies the employee. An employee may cancel an approved leave only if it has not started, restoring balance.
*Rules:* BR-HRS-008, BR-HRS-024. *Acceptance:* (a) A single-level policy approves directly after L1. (b) Every approval/rejection requires remarks. (c) Cancelling a future-dated approved leave restores balance; a started leave cannot be cancelled. (d) Each transition notifies the employee.

**REQ-HRS-011 — Leave Balance Dashboard** (src FR-HRS-011) · P1 · [DASHBOARD][REPORT]
Employee sees allocated/used/available/carry-forward per type. HR Manager sees an employee × leave-type
matrix with department/designation filters, exportable to CSV/PDF.
*Acceptance:* (a) Employee sees only their own balances. (b) HR matrix supports department filter and export.

**REQ-HRS-012 — LOP Reconciliation** (src FR-HRS-012) · P1 · [WORKFLOW]
The system flags days an employee was absent without approved leave (sourced from staff attendance) as LOP;
HR Manager confirms or waives each before month-end close. Confirmed LOP feeds payroll. *Current state:*
attendance source is pending; LOP is entered manually meanwhile.
*Rules:* BR-HRS-009. *Acceptance:* (a) Only HR Manager can confirm/waive LOP. (b) Confirmed LOP for a month is available to that month's payroll. (c) A day cannot be both approved-leave and LOP.

### 3C — Payroll Preparation & Compliance

**REQ-HRS-013 — Pay Grade Master** (src FR-HRS-013) · P2 · [CONFIGURATION]
HR Manager defines pay grades (name, min CTC, max CTC, applicable designations). *Acceptance:* (a) Max CTC ≥ min CTC. (b) Grades drive CTC validation on assignment.

**REQ-HRS-014 — Employee Salary Assignment** (src FR-HRS-014) · P0 · [DATA_ENTRY][WORKFLOW]
HR Manager assigns a salary structure and CTC to an employee, effective from a date. A revision creates a
new assignment and closes the prior one; only one assignment is active at a time. Payroll reads the latest
active assignment.
*Rules:* BR-HRS-010, BR-HRS-011. *Acceptance:* (a) Only one active assignment per employee. (b) CTC outside the pay-grade band is rejected. (c) A revision sets the prior assignment's end date.

**REQ-HRS-015 — PF Compliance Records** (src FR-HRS-015) · P0 · [DATA_ENTRY][SCHEDULED]
HR/Payroll Manager records PF enrolment (UAN, enrolment date, applicability, nominees). A monthly PF
contribution register holds basic wage, employee 12%, employer EPF 3.67%, employer EPS 8.33%, NCP days,
and filing status. PF is mandatory when basic ≤ ₹15,000.
*Rules:* BR-HRS-012, BR-PAY-004. *Acceptance:* (a) One PF record per employee. (b) Register rows compute correct split. (c) Status moves computed → submitted → challan-generated.

**REQ-HRS-016 — ESI Compliance Records** (src FR-HRS-016) · P0 · [DATA_ENTRY]
ESI enrolment (IP number, dispensary) and monthly register (gross wage, employee 0.75%, employer 3.25%,
status). ESI applies when gross ≤ ₹21,000.
*Rules:* BR-HRS-013, BR-PAY-004. *Acceptance:* (a) One ESI record per employee. (b) Applicability follows the gross threshold.

**REQ-HRS-017 — TDS Declaration Storage** (src FR-HRS-017) · P0 · [DATA_ENTRY]
TDS record stores PAN (encrypted), tax regime (old/new), and investment declarations (80C, 80D, HRA, LTA).
*Rules:* BR-HRS-015. *Acceptance:* (a) PAN stored encrypted. (b) Regime is old or new. (c) Declarations feed TDS computation.

**REQ-HRS-018 — Gratuity Records** (src FR-HRS-018) · P2 · [DATA_ENTRY][INTEGRATION]
Gratuity record (applicability, nominees, eligibility date, projected amount). Eligibility starts after 5
years of continuous service; on exit the computed amount is signalled to Accounting by event.
*Rules:* BR-HRS-014. *Acceptance:* (a) Eligibility flagged only after 5 years. (b) Exit fires a gratuity event.

### 3D — Performance Appraisal

**REQ-HRS-019 — KPI Template Management** (src FR-HRS-019) · P1 · [CONFIGURATION]
HR Manager creates KPI templates (applicability, rating scale 5 or 10) with weighted items
(name, category academic/behavioural/administrative, weight). Item weights must total exactly 100.
*Rules:* BR-HRS-016. *Acceptance:* (a) Saving a template whose weights ≠ 100 is rejected. (b) Rating scale is 5 or 10.

**REQ-HRS-020 — Appraisal Cycle Configuration** (src FR-HRS-020) · P1 · [CONFIGURATION][WORKFLOW]
HR Manager creates an appraisal cycle (type, KPI template, self & manager windows, applicable departments,
reviewer mode auto/manual). Manager window cannot open before the self-appraisal close date.
*Rules:* BR-HRS-018. *Acceptance:* (a) Manager open date ≥ self close date. (b) Cycle lifecycle is draft → active → closed.

**REQ-HRS-021 — Self-Appraisal Submission** (src FR-HRS-021) · P1 · [DATA_ENTRY][WORKFLOW]
Employee enters per-KPI self ratings, comments, and evidence; submission locks the form unless HR unlocks it.
*Rules:* BR-HRS-017. *Acceptance:* (a) Submitted self-appraisal is read-only to the employee. (b) HR can unlock for re-edit (logged).

**REQ-HRS-022 — Manager Review & Finalization** (src FR-HRS-022) · P1 · [APPROVAL][WORKFLOW][NOTIFICATION]
Reviewer rates each KPI; the system computes the weighted overall rating; HR finalizes. HR may adjust the
overall rating within ±10%. Finalization notifies the employee and creates an increment flag for payroll.
*Rules:* BR-HRS-019, BR-HRS-020. *Acceptance:* (a) Overall rating = weighted average of KPI ratings. (b) HR adjustment beyond ±10% is rejected. (c) Finalization creates exactly one increment flag.

### 3E — Salary Structure Master

**REQ-HRS-023 — Salary Component Master** (src FR-HRS-023) · P0 · [CONFIGURATION]
HR/Payroll Manager defines salary components (code, type earning/deduction/employer-contribution,
calculation type, default value, taxable flag, statutory flag). 14 standard components are seeded.
*Acceptance:* (a) Component code is unique. (b) Statutory components are marked. (c) Defaults seed on setup.

**REQ-HRS-024 — Salary Structure Template** (src FR-HRS-024) · P0 · [CONFIGURATION]
HR/Payroll Manager composes structures from components with sequence and optional formula overrides; a
structure must include the Basic component.
*Rules:* BR-PAY-011. *Acceptance:* (a) Saving a structure without Basic is rejected. (b) A component cannot be added twice to one structure.

**REQ-HRS-025 — CTC Breakdown Preview** (src FR-HRS-025) · P1 · [DASHBOARD]
On assigning a structure, the system shows a live CTC breakdown (earnings, deductions, net monthly, annual
CTC, employer cost) from the entered CTC and structure rules.
*Acceptance:* (a) Preview recalculates as CTC/components change. (b) Annual CTC = monthly components × 12 incl. employer contributions.

### 3F — Monthly Payroll Run

**REQ-HRS-026 — Payroll Run Initiation** (src FR-HRS-026) · P0 · [WORKFLOW]
Payroll Manager initiates a run for a month (regular or supplementary). Pre-conditions: LOP confirmed for
the month; all active employees have a valid salary assignment; no prior regular run for the month already
computed/approved/locked. Only one regular run per month.
*Rules:* BR-PAY-001, BR-PAY-002, BR-PAY-008. *Acceptance:* (a) A second regular run for the month is blocked. (b) Missing salary assignment blocks computation. (c) Run starts in Draft.

**REQ-HRS-027 — Payroll Computation Engine** (src FR-HRS-027) · P0 · [WORKFLOW][CALCULATION]
Computes per employee: gross earnings per component; LWP deduction; PF; ESI; PT; TDS; net pay; full
breakdown. Synchronous for ≤100 employees, queued beyond. Run moves to Computed.
*Rules:* BR-PAY-004, BR-PAY-010. *Acceptance:* (a) Net pay = gross − LWP − all deductions. (b) LWP = (monthly gross ÷ working days) × confirmed LOP days. (c) PF/ESI applied only to applicable employees. (d) Run reaches Computed with one detail row per employee.

**REQ-HRS-028 — Payroll Review & Amendment** (src FR-HRS-028) · P0 · [WORKFLOW][DATA_ENTRY]
Payroll Manager reviews the computed run and may override an employee's net pay (with a mandatory reason,
logged) or re-compute individuals. Amendments allowed only while Computed.
*Rules:* BR-PAY-005. *Acceptance:* (a) Override requires a reason and is logged. (b) Overridden rows are visibly flagged. (c) No amendment is possible after approval/lock.

**REQ-HRS-029 — Payroll Approval & Lock** (src FR-HRS-029) · P0 · [APPROVAL][WORKFLOW][INTEGRATION]
Payroll Manager submits for approval; Principal approves; Payroll Manager locks. A locked run is immutable.
Locking fires the payroll-approved event (Accounting creates the Journal Voucher) and advances PF/ESI
register status to submitted.
*Rules:* BR-PAY-003. *Acceptance:* (a) A locked run cannot be modified, re-processed, or deleted. (b) Lock fires the Accounting event exactly once. (c) PF/ESI register status moves to submitted on lock.

**REQ-HRS-030 — Supplementary Payroll Run** (src FR-HRS-030) · P1 · [WORKFLOW]
A supplementary run processes employees missed in the month's regular run, linked to the parent run; its
payslips and bank file cover only those employees.
*Rules:* BR-PAY-008. *Acceptance:* (a) A supplementary run references its parent regular run. (b) It includes only the missed employees.

### 3G — Payslips & Distribution

**REQ-HRS-031 — Individual Payslip Generation** (src FR-HRS-031) · P0 · [REPORT]
Payroll Manager generates a password-protected payslip PDF (school header, earnings, deductions, net,
YTD, employer PF). Password = PAN last 4 + DDYYYY of date of birth.
*Acceptance:* (a) PDF opens only with the specified password. (b) Earnings − deductions = net pay shown.

**REQ-HRS-032 — Bulk Payslip Generation** (src FR-HRS-032) · P1 · [REPORT][SCHEDULED]
Payroll Manager generates payslips for the whole run in one action (queued; progress shown); downloadable
as a ZIP.
*Acceptance:* (a) One action produces a payslip for every employee in the run. (b) Progress is reported. (c) A ZIP of all payslips is downloadable.

**REQ-HRS-033 — Payslip Email Distribution** (src FR-HRS-033) · P1 · [NOTIFICATION][SCHEDULED]
After bulk generation, payslips are emailed to employees; delivery status is tracked.
*Acceptance:* (a) Each employee receives their own payslip. (b) Send status is pending/sent/failed per employee.

**REQ-HRS-034 — Employee Self-Service Payslip Download** (src FR-HRS-034) · P1 · [DASHBOARD]
Employee downloads their own payslips (last 24 months), password-protected, behind a permission check.
*Acceptance:* (a) Employee sees only their own payslips. (b) Download is the same password-protected PDF.

### 3H — Bank Disbursement

**REQ-HRS-035 — Bank NEFT/RTGS File Export** (src FR-HRS-035) · P1 · [INTEGRATION][REPORT]
Payroll Manager exports a salary disbursement file (generic CSV or bank-specific format) for an approved
run, covering employees with net pay > 0 and pending payment. On export their status becomes Exported.
*Rules:* BR-PAY-007. *Acceptance:* (a) Export blocked unless run is approved. (b) Only pending, positive-net employees are included. (c) Status advances to Exported.

**REQ-HRS-036 — Payment Status Tracking** (src FR-HRS-036) · P2 · [WORKFLOW]
Payroll Manager marks employees Paid (or Failed) after bank confirmation; failed entries can go to a
supplementary run.
*Acceptance:* (a) Status path pending → exported → paid (or failed). (b) Bulk mark-paid is supported.

### 3I — TDS & Form 16

**REQ-HRS-037 — Monthly TDS Computation** (src FR-HRS-037) · P1 · [CALCULATION]
TDS is computed within the run from projected annual income (YTD + remaining months) and declarations,
applying the chosen regime; monthly TDS = (annual liability − YTD TDS) ÷ remaining months; Dec–Mar
recomputed for accuracy; cumulative ledger maintained.
*Rules:* BR-PAY-006. *Acceptance:* (a) Monthly TDS is never negative. (b) Old vs new regime apply correct exemptions/slabs. (c) Cumulative YTD figures reconcile across months.

**REQ-HRS-038 — Form 16 Generation** (src FR-HRS-038) · P1 · [REPORT][SCHEDULED]
After year close (post April 15), Payroll Manager generates Form 16 (Part A + Part B) for employees with
TDS > 0; employees download their own; bulk generation is queued.
*Rules:* BR-PAY-009. *Acceptance:* (a) Generation blocked before April 15 for the prior FY. (b) Only employees with TDS > 0 are eligible. (c) Employee downloads only their own.

### 3J — Statutory Returns

**REQ-HRS-039 — PF ECR File Generation** (src FR-HRS-039) · P1 · [INTEGRATION][REPORT]
Payroll Manager exports the monthly EPFO ECR file (pipe-delimited) after lock, validated for UAN format
and sum-checks; PF register status advances to challan-generated.
*Acceptance:* (a) Export allowed only after lock. (b) File passes UAN/sum validation. (c) Status → challan-generated.

**REQ-HRS-040 — ESI Contribution Export** (src FR-HRS-040) · P2 · [REPORT]
Payroll Manager exports monthly ESI challan data and half-yearly Form 5.
*Acceptance:* (a) Monthly CSV includes IP number and both contributions. (b) Half-yearly export covers the correct 6-month period.

### 3K — Variable Pay & Increments

**REQ-HRS-041 — Appraisal-Linked Variable Pay** (src FR-HRS-041) · P1 · [WORKFLOW][CALCULATION]
HR Manager defines increment rules (rating band → percentage or flat). After finalization the system
proposes increments per employee; Payroll Manager approves; a new salary assignment effective next month
is created and the flag is marked processed.
*Acceptance:* (a) Proposal matches the employee's rating band rule. (b) Approval creates a new assignment effective the 1st of next month. (c) The increment flag becomes processed.

**REQ-HRS-042 — Ad-hoc Salary Revision** (src FR-HRS-042) · P1 · [DATA_ENTRY][WORKFLOW]
HR Manager applies a salary revision outside appraisal (increment/revision/promotion) with effective date
and reason; creates a new assignment, closes the prior, and appears in employment history. Effective from
the next payroll run after the effective date.
*Rules:* BR-HRS-010. *Acceptance:* (a) A new assignment is created and the old one closed. (b) The change appears in employment history. (c) It applies from the next run on/after the effective date.

### 3L — Payroll Reports
(See Section 7 for RPT-HRS-001…004: Salary Register, Bank Transfer Summary, CTC-vs-Net Analysis, Payroll Trend — mapped from src FR-HRS-043…046.)

---

## Section 4 — Business Rules Register

> Stable IDs reused downstream. Type ∈ Validation / Workflow / Permission / Calculation / Concurrency.

| BR ID | Rule (business statement) | Type | Trigger | Enforcement (REQ) | Priority |
|---|---|---|---|---|---|
| BR-HRS-001 | Leave balance cannot go below 0 except LWP type | Validation | Leave apply | REQ-HRS-009 | P0 |
| BR-HRS-002 | Overlapping approved leave for same employee is rejected | Validation | Leave apply | REQ-HRS-009 | P0 |
| BR-HRS-003 | Carry-forward capped at leave type's cap; excess lapses at year end | Calculation | Balance init | REQ-HRS-005,008 | P0 |
| BR-HRS-004 | Backdated applications allowed only within policy max-backdated-days | Validation | Leave apply | REQ-HRS-007,009 | P1 |
| BR-HRS-005 | Medical certificate mandatory for SL beyond threshold days | Validation | Leave apply | REQ-HRS-005,009 | P1 |
| BR-HRS-006 | Maternity leave female-only; paternity leave male-only | Validation | Leave apply | REQ-HRS-005,009 | P1 |
| BR-HRS-007 | Minimum service months enforced at application | Validation | Leave apply | REQ-HRS-009 | P1 |
| BR-HRS-008 | Approved leave cancellable only if start date is in the future; balance restored | Workflow | Cancel | REQ-HRS-010 | P0 |
| BR-HRS-009 | LOP confirmation restricted to HR Manager (financial impact) | Permission | LOP confirm | REQ-HRS-012 | P1 |
| BR-HRS-010 | Only one active salary assignment per employee at a time | Concurrency | Assign/revise | REQ-HRS-014,042 | P0 |
| BR-HRS-011 | CTC must be within the assigned pay grade's min/max | Validation | Assign | REQ-HRS-014 | P0 |
| BR-HRS-012 | PF mandatory when basic ≤ ₹15,000; voluntary otherwise | Validation | PF record | REQ-HRS-015 | P0 |
| BR-HRS-013 | ESI applicable when gross ≤ ₹21,000; not otherwise | Validation | ESI record | REQ-HRS-016 | P0 |
| BR-HRS-014 | Gratuity eligibility only after 5 years continuous service | Calculation | Gratuity/exit | REQ-HRS-018 | P2 |
| BR-HRS-015 | PAN and bank account number encrypted; never logged in plain text | Validation | Save | REQ-HRS-001,017 | P0 |
| BR-HRS-016 | KPI item weights within a template must sum exactly to 100 | Validation | Template save | REQ-HRS-019 | P1 |
| BR-HRS-017 | Self-appraisal submission locks the form; HR must unlock to re-edit | Workflow | Self submit | REQ-HRS-021 | P1 |
| BR-HRS-018 | Manager review window cannot open before self-appraisal close | Validation | Cycle save | REQ-HRS-020 | P1 |
| BR-HRS-019 | Finalized appraisal immutable; only HR reopens with audit entry | Workflow | Finalize | REQ-HRS-022 | P1 |
| BR-HRS-020 | HR overall-rating adjustment limited to ±10% of computed average | Calculation | Finalize | REQ-HRS-022 | P1 |
| BR-HRS-021 | Employee code format EMP/YYYY/NNN — auto, unique per tenant, immutable (owned by School Setup) | Validation | Employee create | REQ-HRS-001 | P1 |
| BR-HRS-022 | Document expiry reminders fire 30 days before expiry | Workflow | Scheduled | REQ-HRS-003 | P1 |
| BR-HRS-023 | Soft-delete only; permanent deletion not permitted | Workflow | Delete | all | P0 |
| BR-HRS-024 | All approval/rejection actions require non-empty remarks | Validation | Approve/reject | REQ-HRS-010,022 | P0 |
| BR-PAY-001 | Only one regular payroll run per month; duplicates blocked | Concurrency | Run init | REQ-HRS-026 | P0 |
| BR-PAY-002 | Computation cannot start if any active employee lacks a valid salary assignment | Validation | Compute | REQ-HRS-026,027 | P0 |
| BR-PAY-003 | Locked payroll cannot be modified, re-processed, or deleted | Workflow | Lock | REQ-HRS-029 | P0 |
| BR-PAY-004 | PF/ESI deduction mandatory for applicable employees; not per-employee overridable | Validation | Compute | REQ-HRS-015,016,027 | P0 |
| BR-PAY-005 | Manual net-pay override requires a mandatory reason; logged | Validation | Override | REQ-HRS-028 | P0 |
| BR-PAY-006 | Monthly TDS cannot be negative; shortfall carried to next month | Calculation | Compute | REQ-HRS-037 | P1 |
| BR-PAY-007 | Bank file export allowed only after run is approved | Permission | Export | REQ-HRS-035 | P1 |
| BR-PAY-008 | Supplementary run must reference the regular run's parent for the month | Validation | Supp. run | REQ-HRS-030 | P1 |
| BR-PAY-009 | Form 16 generation allowed only after April 15 for the prior financial year | Validation | Generate | REQ-HRS-038 | P1 |
| BR-PAY-010 | LWP = (monthly gross ÷ working days in month) × LOP days | Calculation | Compute | REQ-HRS-027 | P0 |
| BR-PAY-011 | Salary structure must include the Basic component | Validation | Structure save | REQ-HRS-024 | P0 |
| BR-PAY-012 | Payslip re-generation allowed only while approved; blocked after lock | Workflow | Re-generate | REQ-HRS-031 | P1 |

**Totals:** 36 business rules (24 BR-HRS + 12 BR-PAY).

---

## Section 5 — Data Requirements

### 5.1 Business entities (privacy classification)
| Entity | Meaning | Sensitivity |
|---|---|---|
| Employment Detail | HR extension of an employee incl. bank & emergency contact | **Sensitive (PII)** — bank a/c encrypted |
| Employment History | Audit of HR changes | Internal |
| Employee Document | Stored documents with expiry | Confidential |
| Leave Type / Holiday / Policy | Leave configuration | Internal |
| Leave Balance / Application / Approval / Adjustment | Leave records | Confidential |
| LOP Record | Unapproved-absence flags | Confidential (financial impact) |
| Pay Grade / Salary Component / Structure | Salary configuration | Internal |
| Salary Assignment | Employee CTC & structure | **Confidential** |
| Compliance Record / PF & ESI Register | Statutory enrolments & contributions | **Sensitive (PII)** — PAN/UAN encrypted |
| KPI Template / Appraisal Cycle / Appraisal | Performance data | Confidential |
| Payroll Run / Detail / Override | Monthly payroll | **Confidential** |
| Payslip / Form 16 | Generated documents | **Sensitive (PII)** — password-protected |
| TDS Ledger | Cumulative tax | **Sensitive (PII)** |
| Increment Policy / Flag | Salary revision rules & triggers | Confidential |

### 5.2 Technical Data Dictionary (technical register — DDL ↔ migration ↔ model reconciled)
33 tables, all InnoDB/utf8mb4, all with `is_active`, `created_by`, `updated_by`, `created_at`,
`updated_at`, `deleted_at`. Employee FKs are **INT UNSIGNED** (→ `sch_employees.id`); academic-year FKs are
**SMALLINT UNSIGNED** (→ `sch_org_academic_sessions_jnt.id`, NOT a non-existent `sch_academic_years`).

**`hrs_*` (23):** `hrs_leave_types`, `hrs_holiday_calendars`, `hrs_pay_grades`, `hrs_id_card_templates`,
`hrs_leave_policies`, `hrs_leave_balances` (uq: employee+type+year), `hrs_leave_applications` (status FSM),
`hrs_leave_approvals`, `hrs_leave_balance_adjustments`, `hrs_lop_records` (uq: employee+date),
`hrs_compliance_records` (uq: employee+type), `hrs_pf_contribution_register` (uq: compliance+month+year),
`hrs_esi_contribution_register`, `hrs_kpi_templates`, `hrs_kpi_template_items`, `hrs_appraisal_cycles`,
`hrs_appraisals` (uq: cycle+employee), `hrs_appraisal_increment_flags`, `hrs_pt_slabs`,
`hrs_employment_details` (uq: employee — 1:1), `hrs_employment_history`, `hrs_employee_documents`,
`hrs_salary_assignments` (effective-dated).

**`pay_*` (10):** `pay_salary_components` (uq code; 14 seeded), `pay_salary_structures`,
`pay_salary_structure_components` (uq: structure+component), `pay_payroll_runs` (uq: month+run_type; FSM
draft→computing→computed→reviewing→approved→locked), `pay_payroll_run_details` (uq: run+employee),
`pay_payroll_overrides`, `pay_payslips` (uq: run_detail — 1:1; password PDF), `pay_tds_ledger` (uq:
employee+FY+month), `pay_form16` (uq: employee+FY), `pay_increment_policies`.

**Encrypted columns:** `hrs_employment_details.bank_account_number` (TEXT, Laravel `encrypt()`);
`hrs_compliance_records.reference_number` for TDS = encrypted PAN (VARCHAR(100)).
**Cross-prefix FKs (intra-module):** `hrs_salary_assignments.pay_salary_structure_id` →
`pay_salary_structures`; `pay_payroll_run_details.salary_assignment_id` → `hrs_salary_assignments`.
**Reconciliation result:** all 33 DDL tables have a matching migration (`2026_06_16_1603*`) and a matching
model (`protected $table`). No drift found between DDL, migration list, and model table bindings.

---

## Section 6 — Workflows & State Machines

### Workflow 1 — Leave Application (FSM on `hrs_leave_applications.status`)
States: `pending` → (`pending_l2`) → `approved` | `rejected` | `cancelled` | `returned`.
| From | Event (guard) | To | Side-effects |
|---|---|---|---|
| pending | HOD approve (levels=2) | pending_l2 | log approval; notify |
| pending | HOD approve (levels=1) | approved | balance.used += days; notify |
| pending | HOD reject | rejected | notify (remarks required) |
| pending | HOD return | returned | notify |
| pending_l2 | Principal approve | approved | balance.used += days; notify |
| pending_l2 | Principal reject | rejected | notify |
| returned | employee resubmit | pending | — |
| approved | employee cancel (start>today) | cancelled | balance.used −= days; notify |
Terminal: rejected, cancelled. Illegal (block): cancel after start; edit after approved; approve without remarks.
Exception path: insufficient balance / overlap at submit → application not created.

### Workflow 2 — Payroll Run (FSM on `pay_payroll_runs.status`)
States: `draft` → `computing` → `computed` → `reviewing` → `approved` → `locked`.
| From | Event (guard) | To | Side-effects |
|---|---|---|---|
| draft | compute (LOP confirmed; all have assignment; no prior run) | computing→computed | create detail rows |
| computed | override / re-compute | computed | log override (reason) |
| computed | submit | reviewing | — |
| reviewing | Principal approve | approved | set approved_by/at |
| reviewing | Principal reject | computed | reopen for amendment |
| approved | lock | locked | fire PayrollApproved → Accounting JV; PF/ESI status→submitted |
Terminal: locked (immutable, BR-PAY-003). Post-lock allowed: bank file export, payslip gen/email, PF ECR, ESI challan.
Exception paths: pre-condition fail blocks computing; export before approved blocked (BR-PAY-007).

### Workflow 3 — Appraisal
Cycle: `draft` → `active` → `closed`. Appraisal: `draft` → `submitted` → `reviewed` → `finalized`.
Side-effects: finalize → notify employee + create `hrs_appraisal_increment_flags` (pending); increment
processed → flag `processed` + new `hrs_salary_assignments` row.

### Events fired
`LeaveApproved`, `LeaveRejected` (→ Notification); `AppraisalFinalized` (→ IncrementService);
`PayrollApproved` (→ Accounting Journal Voucher); `PayrollLocked` (→ statutory register status update).
(`DocumentExpiringSoon` is spec'd as a scheduled trigger; no dedicated event class present yet.)

---

## Section 7 — Reporting & Analytics + KPIs

| RPT ID | Report | Audience | Frequency | Contents | Filters | Export | (src) |
|---|---|---|---|---|---|---|---|
| RPT-HRS-001 | Monthly Salary Register | Payroll Mgr, Accountant | Monthly | per-employee basic, HRA, earnings, gross, PF, ESI, TDS, PT, deductions, net | dept, designation, type | PDF (A3), Excel | FR-HRS-043 |
| RPT-HRS-002 | Bank Transfer Summary | Payroll Mgr, Principal | Monthly | dept-wise & overall totals (gross/deductions/net, headcount); drilldown | dept | PDF, Excel | FR-HRS-044 |
| RPT-HRS-003 | CTC vs Gross vs Net Analysis | HR Mgr, Principal | On demand | annual CTC vs YTD gross/net; employer cost | dept, employee | Excel | FR-HRS-045 |
| RPT-HRS-004 | Payroll Trend | Principal, HR Mgr | Monthly | 12-month gross/net/headcount trend; >5% MoM anomaly flag | dept | PDF, Excel | FR-HRS-046 |

Operational exports (not "reports" but document outputs): payslip (REQ-031/032), bank NEFT file (REQ-035),
PF ECR (REQ-039), ESI challan / Form 5 (REQ-040), Form 16 (REQ-038), PF & ESI registers (REQ-015/016).

**KPI catalog (illustrative):** Leave Utilization % = used ÷ allocated; LOP Rate = confirmed LOP days ÷
working days; On-time Payroll % = runs locked by pay date ÷ total; Statutory Filing Compliance % =
challans generated on time; Appraisal Completion % = finalized ÷ eligible; Average Increment % per cycle.

---

## Section 8 — Future Enhancement Log
- ENH-HRS-001 — Consume shared `sch_holiday_calendars` instead of module-local holiday table (align with Timetable/Attendance) — see OQ-004.
- ENH-HRS-002 — Auto LOP reconciliation once the Attendance module (`att_staff_attendances`) ships (currently manual stub).
- ENH-HRS-003 — Add `pay_payroll_formula_changelog` to satisfy NFR-009 (formula-change audit).
- ENH-HRS-004 — Introduce explicit queued Job classes (bulk payslip, Form 16, payslip email) per NFR-004.
- ENH-HRS-005 — "Apply leave on behalf of employee" (HR Manager) per OQ-008.

---

## Section 9 — Non-Functional Requirements

| NFR ID | Category | Requirement (measurable) | Threshold |
|---|---|---|---|
| NFR-HRS-001 | Performance | Single-employee leave balance read | < 200 ms |
| NFR-HRS-002 | Performance | LOP reconciliation for 200 employees | < 10 s |
| NFR-HRS-003 | Performance | Payroll compute ≤100 employees synchronous; >100 queued | < 30 s |
| NFR-HRS-004 | Performance | Bulk payslip generation (200) via queue | < 5 min |
| NFR-HRS-005 | Security | Bank a/c + PAN encrypted; never in plaintext logs | Mandatory |
| NFR-HRS-006 | Security | Documents/payslips served via signed temporary URLs | Mandatory |
| NFR-HRS-007 | Security | Payslip PDFs password-protected (PAN4 + DDYYYY DOB) | Mandatory |
| NFR-HRS-008 | Compliance | PF/ESI/TDS data retained ≥ 7 years (soft-delete only) | 7 years |
| NFR-HRS-009 | Auditability | Formula changes logged with effective date | Required (gap: changelog table absent) |
| NFR-HRS-010 | Availability | HR ops must not block payroll runs (async where possible) | Mandatory |
| NFR-HRS-011 | Auditability | Leave & payroll approve/lock actions logged in activity log | Mandatory |
| NFR-HRS-012 | Scalability | Up to 500 employees/tenant; balance init < 30 s | 500 employees |
| NFR-HRS-013 | Usability | Forms WCAG 2.1 AA, keyboard navigable | AA |
| NFR-HRS-014 | Localization | Currency INR; display DD-MM-YYYY; store ISO 8601 | Mandatory |
| NFR-HRS-015 | Data Integrity | Locked payroll rows immutable (service guard + audit) | Mandatory |
| NFR-HRS-016 | Tenancy | Data isolated per school (separate DB per tenant); no cross-tenant access | Mandatory |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Coverage table (downstream contract)
| REQ ID | Feature | Priority | Tags | DDL Entity | Screen | API | Notification | Test |
|---|---|---|---|---|---|---|---|---|
| REQ-HRS-001 | Employment details | P0 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-HRS-002 | Employment history | P1 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-003 | Document repository | P0 | DATA_ENTRY,NOTIFICATION | Yes | Yes | Yes | Yes | Yes |
| REQ-HRS-004 | ID card generation | P1 | REPORT,CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HRS-005 | Leave type master | P0 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HRS-006 | Holiday calendar | P1 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HRS-007 | Leave policy | P2 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HRS-008 | Balance initialization | P0 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-009 | Leave application | P0 | DATA_ENTRY,WORKFLOW | Yes | Yes | Yes | Yes | Yes |
| REQ-HRS-010 | Leave approval | P0 | APPROVAL,NOTIFICATION | Yes | Yes | Yes | Yes | Yes |
| REQ-HRS-011 | Balance dashboard | P1 | DASHBOARD,REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HRS-012 | LOP reconciliation | P1 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-013 | Pay grade master | P2 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HRS-014 | Salary assignment | P0 | DATA_ENTRY,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-015 | PF compliance | P0 | DATA_ENTRY,SCHEDULED | Yes | Yes | Yes | No | Yes |
| REQ-HRS-016 | ESI compliance | P0 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-HRS-017 | TDS declaration | P0 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-HRS-018 | Gratuity records | P2 | DATA_ENTRY,INTEGRATION | Yes | Yes | Yes | No | Yes |
| REQ-HRS-019 | KPI templates | P1 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HRS-020 | Appraisal cycle | P1 | CONFIG,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-021 | Self-appraisal | P1 | DATA_ENTRY,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-022 | Manager review/finalize | P1 | APPROVAL,NOTIFICATION | Yes | Yes | Yes | Yes | Yes |
| REQ-HRS-023 | Salary component master | P0 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HRS-024 | Salary structure template | P0 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HRS-025 | CTC breakdown preview | P1 | DASHBOARD | Yes | Yes | Yes | No | Yes |
| REQ-HRS-026 | Payroll run initiation | P0 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-027 | Payroll computation | P0 | CALCULATION,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-028 | Payroll review/override | P0 | WORKFLOW,DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-HRS-029 | Approval & lock | P0 | APPROVAL,INTEGRATION | Yes | Yes | Yes | Yes | Yes |
| REQ-HRS-030 | Supplementary run | P1 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-031 | Individual payslip | P0 | REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HRS-032 | Bulk payslip | P1 | REPORT,SCHEDULED | Yes | Yes | Yes | No | Yes |
| REQ-HRS-033 | Payslip email | P1 | NOTIFICATION,SCHEDULED | Yes | Yes | Yes | Yes | Yes |
| REQ-HRS-034 | Self-service payslip | P1 | DASHBOARD | Yes | Yes | Yes | No | Yes |
| REQ-HRS-035 | Bank file export | P1 | INTEGRATION,REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HRS-036 | Payment status | P2 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-037 | Monthly TDS | P1 | CALCULATION | Yes | Yes | Yes | No | Yes |
| REQ-HRS-038 | Form 16 | P1 | REPORT,SCHEDULED | Yes | Yes | Yes | No | Yes |
| REQ-HRS-039 | PF ECR file | P1 | INTEGRATION,REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HRS-040 | ESI export | P2 | REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HRS-041 | Variable pay | P1 | WORKFLOW,CALCULATION | Yes | Yes | Yes | Yes | Yes |
| REQ-HRS-042 | Ad-hoc revision | P1 | DATA_ENTRY,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-HRS-043 | Salary register (RPT-001) | P1 | REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HRS-044 | Bank summary (RPT-002) | P2 | REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HRS-045 | CTC analysis (RPT-003) | P2 | REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HRS-046 | Payroll trend (RPT-004) | P2 | REPORT,DASHBOARD | Yes | Yes | Yes | No | Yes |

### 10.2 Business-rule coverage
36 rules (24 BR-HRS + 12 BR-PAY) all mapped to ≥1 REQ in Section 4. Highest-risk enforcement points to
verify in audit: BR-PAY-003 (lock immutability), BR-HRS-015/NFR-005 (encryption), BR-PAY-010 (LWP formula),
BR-HRS-016 (weight sum 100), BR-HRS-010 (single active assignment).

### 10.3 Report coverage
4 analytical reports (RPT-HRS-001…004) + 6 statutory/operational document exports. All have a screen route.

### 10.4 Totals (reconciled)
- Functional requirements: **46** (REQ-HRS-001…046).
- Business rules: **36** (24 BR-HRS + 12 BR-PAY).
- Workflows / FSMs: **3** (+ 6 domain events).
- Reports: **4** (RPT-HRS-001…004); operational exports: 6.
- NFRs: **16** (NFR-HRS-001…016). Enhancements: **5** (ENH-HRS-001…005). Risks: **8** (Section 14).
- **Priority split:** P0 = 18 · P1 = 20 · P2 = 8 (sums to 46).

---

## Section 11 — Requirements Traceability Matrix

| REQ | BR refs | Screen(s) | Workflow | Report | Code status (verified) | Gap |
|---|---|---|---|---|---|---|
| REQ-HRS-001 | 015,021,023 | employment.show | — | — | Built (EmploymentController/Service, EmploymentDetail) | Verify encryption |
| REQ-HRS-002 | 023 | history.index | — | — | Built (EmploymentHistory) | — |
| REQ-HRS-003 | 022,023 | documents.index | — | — | Built (DocumentController) | Verify expiry reminder job |
| REQ-HRS-004 | — | id-card.show | — | — | Built (IdCard + Template controllers) | — |
| REQ-HRS-005 | 003,005,006,007 | leave-types.* | — | — | Built (LeaveTypeController + seeder) | Overlap w/ sch_staff_leave_types |
| REQ-HRS-006 | — | holidays.* | — | — | Built (HolidayController) | Shared-table candidate |
| REQ-HRS-007 | 004 | leave-policy.* | — | — | Built (LeaveController) | Overlap w/ sch_leave_approval_policies |
| REQ-HRS-008 | 003 | balances.* | WF1 | — | Built (LeaveController) | — |
| REQ-HRS-009 | 001,002,004,005,006,007 | applications.* | WF1 | — | Built (LeaveApplicationController) | Overlap w/ sch_employee_leave_applications |
| REQ-HRS-010 | 008,024 | applications.approve/reject/cancel | WF1 | — | Built (LeaveApprovalService, events) | — |
| REQ-HRS-011 | — | balances.index | — | — | Built | — |
| REQ-HRS-012 | 009 | lop.* | WF1 | — | Built but **stub source** (manual; att_ pending) | P1 dependency |
| REQ-HRS-013 | — | pay-grades.* | — | — | Built (PayGradeController) | — |
| REQ-HRS-014 | 010,011 | salary.* | WF | — | Built (SalaryAssignmentController/Service) | — |
| REQ-HRS-015 | 012,PAY-004 | compliance.*, pf-register | — | — | Built (ComplianceController, PfContributionRegister) | — |
| REQ-HRS-016 | 013,PAY-004 | compliance.*, esi-register | — | — | Built (EsiContributionRegister) | — |
| REQ-HRS-017 | 015 | compliance.* | — | — | Built | Verify PAN encryption |
| REQ-HRS-018 | 014 | compliance.* | — | — | Built (gratuity type) | Exit event TBD |
| REQ-HRS-019 | 016 | kpi-templates.* | WF3 | — | Built (AppraisalController, KpiTemplate*) | — |
| REQ-HRS-020 | 018 | cycles.* | WF3 | — | Built (AppraisalCycle) | — |
| REQ-HRS-021 | 017 | appraisals.submit-self | WF3 | — | Built | — |
| REQ-HRS-022 | 019,020 | appraisals.submit-review/finalize | WF3 | — | Built (AppraisalFinalized event) | — |
| REQ-HRS-023 | — | salary-components.* | — | — | Built (+14 seeded) | — |
| REQ-HRS-024 | PAY-011 | salary-structures.* | — | — | Built (SalaryStructureService) | — |
| REQ-HRS-025 | — | salary-structures.preview | — | — | Built (preview route) | — |
| REQ-HRS-026 | PAY-001,002,008 | payroll.index/store | WF2 | — | Built (PayrollRunService) | — |
| REQ-HRS-027 | PAY-004,010 | payroll.compute | WF2 | — | Built (PayrollComputationService) | Verify LWP/PF/ESI formulas |
| REQ-HRS-028 | PAY-005 | payroll.details/override | WF2 | — | Built (PayrollOverride) | — |
| REQ-HRS-029 | PAY-003 | payroll.submit/approve/lock | WF2 | — | Built (PayrollApproved/Locked events) | Verify lock immutability guard |
| REQ-HRS-030 | PAY-008 | payroll (parent_run_id) | WF2 | — | Built (run_type/parent) | — |
| REQ-HRS-031 | PAY-012 | payslip pdf | — | — | Built (PayslipService) | Verify PDF password |
| REQ-HRS-032 | — | payslips.generate-all | — | — | Built; **no Job class** | P1 (queue gap) |
| REQ-HRS-033 | — | (email) | — | — | Partial (email status field) | Verify email wiring |
| REQ-HRS-034 | — | my-payslips.* | — | — | Built | — |
| REQ-HRS-035 | PAY-007 | payroll.bank-file | — | — | Built (BankExportService) | — |
| REQ-HRS-036 | — | payroll.mark-paid | — | — | Built | — |
| REQ-HRS-037 | PAY-006 | (in compute) | WF2 | — | Built (TdsComputationService, TdsLedger) | Verify slab logic |
| REQ-HRS-038 | PAY-009 | form16.* | — | — | Built (Form16Controller) | Verify April-15 guard |
| REQ-HRS-039 | — | payroll.pf-ecr | — | — | Built (StatutoryController) | — |
| REQ-HRS-040 | — | payroll.esi-challan | — | — | Built | — |
| REQ-HRS-041 | — | increments.* | WF3 | — | Built (IncrementService, IncrementPolicy) | — |
| REQ-HRS-042 | 010 | salary.revision | WF | — | Built | — |
| REQ-HRS-043 | — | reports.salary-register | — | RPT-001 | Built (PayrollReportController) | — |
| REQ-HRS-044 | — | reports.bank-summary | — | RPT-002 | Built | — |
| REQ-HRS-045 | — | reports.ctc-analysis | — | RPT-003 | Built | — |
| REQ-HRS-046 | — | reports.payroll-trend | — | RPT-004 | Built | — |

> RTM reconciles to §10.4: 46 REQ rows; all 36 BRs referenced; 4 RPT mapped. "Code status" is structural
> (class/route presence verified live) — behavioural correctness is for the Technical Auditor.

---

## Section 12 — Requirement Conditions & Validation Catalog

> Canonical copy may also populate `{REQUIREMENT_CONDITIONS}/HrStaff_Conditions.md`; IDs reuse BR-.

| BR (Condition) | Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency | Expected |
|---|---|---|---|---|---|---|---|
| BR-HRS-001 | leave balance | apply 2 of 5 avail | apply 6 of 5 | apply exactly 5 | LWP type | two parallel applies | reject when would go <0 (except LWP) |
| BR-HRS-002 | overlap | non-overlapping dates | dates inside existing leave | adjacent days | — | concurrent overlap | reject overlap |
| BR-HRS-003 | carry-forward | closing 10 cap 30 → 10 | carry 40 cap 30 | closing = cap | zero balance | — | min(closing, cap); excess lapses |
| BR-HRS-010 | single active assignment | one active | two with null end | revision same day | — | two revisions race | only one active; close prior |
| BR-HRS-011 | CTC vs grade | within band | above max | exactly at max | no grade | — | reject out-of-band |
| BR-HRS-016 | KPI weights | sum 100 | sum 90 | sum 100.00 | no items | — | reject ≠ 100 |
| BR-HRS-020 | rating adjust | +5% | +15% | exactly ±10% | — | — | reject beyond ±10% |
| BR-HRS-024 | approval remarks | "approved, ok" | empty | 1 char | null | — | reject empty remarks |
| BR-PAY-001 | one regular run/month | first run | second regular | supplementary allowed | — | two inits race | block duplicate regular |
| BR-PAY-002 | assignment present | all assigned | one missing | new joiner | — | — | block compute |
| BR-PAY-003 | locked immutable | edit while computed | edit after lock | at lock instant | — | edit during lock | block all writes post-lock |
| BR-PAY-005 | override reason | reason given | no reason | 1 char | null | — | reject without reason; log |
| BR-PAY-006 | TDS floor | TDS 500 | TDS −200 | TDS 0 | — | — | floor at 0; carry shortfall |
| BR-PAY-007 | export gate | run approved | run computed | at approval | — | — | block export pre-approval |
| BR-PAY-009 | Form16 date | Apr 16 | Apr 10 | Apr 15 exactly | — | — | block before Apr 15 |
| BR-PAY-010 | LWP formula | gross 30000/30×2 | negative LOP | LOP=working days | LOP 0 | — | (gross÷working)×LOP |
| BR-PAY-011 | structure Basic | incl. BASIC | no BASIC | only BASIC | empty structure | — | reject without BASIC |

---

## Section 13 — Cross-Module Dependency Map

**Inbound (HrStaff reads):**
| Source | Data | Why | Access |
|---|---|---|---|
| SchoolSetup (`sch_*`) | `sch_employees`, `sch_employees_profile`, `sch_department`, `sch_designation` | employee base, reporting line, dept/designation | read + extend |
| SchoolSetup (`sch_*`) | `sch_org_academic_sessions_jnt` | year scoping of leave & payroll | read-only |
| SchoolSetup_EmployeeSetup (`sch_*_leave_*`) | parallel staff-leave engine | **overlap — see Section A** | conflict |
| Attendance (`att_*`) | `att_staff_attendances` | LOP source | read-only (**pending; stubbed**) |
| System (`sys_*`) | `sys_media`, `sys_users`, `sys_activity_logs` | files, audit user, audit trail | read/write |

**Outbound (HrStaff provides):**
| Consumer | Mechanism | What |
|---|---|---|
| Accounting (`acc_*`) | `PayrollApproved` event | salary-expense Journal Voucher (no FK; event only) |
| Accounting (`acc_*`) | gratuity-on-exit event | disbursement input |
| Notification (`ntf_*`) | `ntf_notifications` | leave decisions, document expiry, payslip email |

---

## Section 14 — Risk Register

| Risk ID | Risk | Cat | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|---|
| RISK-HRS-001 | Dual leave engines (hrs_* vs sch_employee_leave_*) cause data split / double truth | Architecture | H | H | Decide canonical engine; deprecate/redirect the other | Enterprise Architect |
| RISK-HRS-002 | LOP depends on Attendance module not yet built → manual entry, payroll error risk | Dependency | H | H | Keep manual path; integrate `att_staff_attendances` when ready | DB Architect / Backend |
| RISK-HRS-003 | Lock immutability (BR-PAY-003) not enforced → tampering of locked payroll | Integrity | M | H | Service guard + audit; auditor verification | Technical Auditor |
| RISK-HRS-004 | PAN/bank encryption not applied everywhere → PII leak / compliance breach | Security | M | H | Verify `encrypt()` on all writes + log scrubbing | Technical Auditor |
| RISK-HRS-005 | Bulk payslip/Form 16 run synchronously (no Job classes) → timeout at scale | Performance | M | M | Add queued Jobs (ENH-HRS-004) | Backend |
| RISK-HRS-006 | TDS slab/regime logic incorrect → wrong tax, Form 16 errors | Compliance | M | H | Unit-test old/new regime + year-end recompute | Testing Architect |
| RISK-HRS-007 | No automated tests yet (`tests/` empty) → regressions undetected | Quality | H | M | Build Pest suite per V2 §14 | Testing Architect |
| RISK-HRS-008 | Holiday calendar duplicated vs Timetable/Attendance needs | Architecture | M | M | Evaluate shared `sch_holiday_calendars` (ENH-HRS-001) | Enterprise Architect |

---

## Section 15 — Prioritization (MoSCoW → P0/P1/P2)

- **Must (P0, 18):** REQ-HRS-001,003,005,008,009,010,014,015,016,017,023,024,026,027,028,029,031 (+ BR-PAY-003 enforcement). Core HR record, leave apply/approve/balance, salary assignment, statutory enrolment, structure master, and the payroll run through lock + payslip.
- **Should (P1, 20):** REQ-HRS-002,004,006,011,012,019,020,021,022,025,030,032,033,034,035,037,038,039,041,042,043. History, ID card, appraisal suite, supplementary/bulk/email/self-service payslip, bank file, TDS, Form 16, PF ECR, increments, salary register.
- **Could (P2, 8):** REQ-HRS-007,013,018,036,040,044,045,046. Policy fine-tuning, pay grades, gratuity, payment-status, ESI export, and three analytical reports.
- **Won't (this release):** recruitment, mobile portal, gratuity disbursement payment (out of scope §1.3).

---

## Section 16 — Effort Estimation & Sprint Tasks

> Most of this module is already built; estimates below are for **completion + hardening** of the
> highest-risk gaps, not greenfield. (S=1–2d, M=3–5d, L=6–8d.)

| # | Task | Type | Effort | Depends on | Sprint |
|---|---|---|---|---|---|
| T1 | Resolve dual leave-engine ownership; pick canonical; migration/redirect plan | Integration | L | RISK-HRS-001 | 1 |
| T2 | Verify & enforce lock immutability guard (BR-PAY-003) | Backend | M | — | 1 |
| T3 | Audit PAN/bank encryption + log scrubbing (BR-HRS-015) | Backend | M | — | 1 |
| T4 | Add queued Jobs: bulk payslip, Form 16, payslip email | Backend | M | — | 2 |
| T5 | Verify payroll formulas (LWP/PF/ESI/PT/TDS) with unit tests | Testing | L | — | 2 |
| T6 | Integrate `att_staff_attendances` LOP source when Attendance ships | Integration | M | Attendance module | 3 |
| T7 | Add `pay_payroll_formula_changelog` + wiring (NFR-009) | Schema | S | — | 3 |
| T8 | Build Pest feature/unit suite per V2 §14 (~95 tests) | Testing | L | T5 | 2–3 |
| T9 | Confirm Form 16 April-15 guard and TDS regime/year-end recompute | Backend | M | T5 | 3 |

---

## Section 17 — User Stories (P0/P1 — Gherkin)

**US-HRS-001 (REQ-HRS-009) P0** — As an Employee I want to apply for leave so that my absence is approved and tracked.
- Happy: Given sufficient balance and no overlap, When I submit valid dates, Then an application is created as Pending and days exclude holidays/weekends.
- Boundary: Given I request more days than available (non-LWP), When I submit, Then it is rejected with a balance message.
- Permission: Given I am not the applicant, When I open another's application form, Then access is refused.
- Empty: Given no leave types are active, When I open the form, Then I see an empty-state prompt.
- DoD: balance validated; day-count auto-computed; academic-year scoped; notification on submit.

**US-HRS-002 (REQ-HRS-010) P0** — As an HOD/Principal I want to approve or reject leave with remarks so that decisions are auditable.
- Happy: Given a pending application, When I approve with remarks, Then status advances and the employee is notified; balance updates on final approval.
- Boundary: Given an approved future-dated leave, When the employee cancels, Then balance is restored; a started leave cannot be cancelled.
- Permission: Given I lack approval rights, When I try to approve, Then it is refused.
- DoD: remarks mandatory (BR-HRS-024); every transition logged + notified.

**US-HRS-003 (REQ-HRS-014) P0** — As an HR Manager I want to assign/revise salary so that payroll uses the correct CTC.
- Happy: Given a CTC within the pay-grade band, When I assign a structure, Then one active assignment exists and a CTC breakdown shows.
- Boundary: Given a CTC above the grade max, When I save, Then it is rejected.
- Concurrency: Given an existing active assignment, When I create a revision, Then the prior closes and only one remains active.
- DoD: history entry written; single-active enforced (BR-HRS-010,011).

**US-HRS-004 (REQ-HRS-026/027/029) P0** — As a Payroll Manager I want to run, review, approve and lock monthly payroll so that staff are paid accurately and immutably.
- Happy: Given confirmed LOP and complete assignments, When I compute, Then one detail row per employee is produced with net = gross − LWP − deductions.
- Boundary: Given a regular run already exists for the month, When I initiate another, Then it is blocked (BR-PAY-001).
- Permission: Given I am not Principal, When I approve, Then it is refused.
- Immutability: Given a locked run, When anyone edits it, Then the change is blocked (BR-PAY-003); lock fires the Accounting event once.
- DoD: pre-conditions enforced; override needs reason; PF/ESI status→submitted on lock.

**US-HRS-005 (REQ-HRS-015/016/017) P0** — As an HR Manager I want to record PF/ESI/TDS so that statutory deductions are correct.
- Happy: Given an employee with basic ≤ ₹15,000, When I create a PF record, Then PF is mandatory and the register computes the correct split.
- Boundary: Given gross > ₹21,000, When I set ESI, Then it is not applicable.
- Security: Given a TDS record, When I save PAN, Then it is stored encrypted and never logged in plain text.
- DoD: one record per type per employee; applicability follows thresholds (BR-HRS-012,013,015).

**US-HRS-006 (REQ-HRS-022) P1** — As a Reviewer/HR I want to review and finalize appraisals so that ratings drive increments.
- Happy: Given submitted self-appraisal, When I rate each KPI, Then the weighted overall rating computes and finalization creates an increment flag + employee notice.
- Boundary: Given I adjust the overall beyond ±10%, When I save, Then it is rejected (BR-HRS-020).
- DoD: weights summed to 100 at template (BR-HRS-016); finalized appraisal immutable except HR reopen (BR-HRS-019).

**US-HRS-007 (REQ-HRS-031/034) P1** — As an Employee I want to download my password-protected payslip so that I have my salary record.
- Happy: Given a generated payslip, When I open it, Then it requires PAN-last-4 + DDYYYY(DOB).
- Permission: Given another employee's payslip, When I request it, Then access is refused.
- DoD: self-service shows only own last-24-months payslips.

**US-HRS-008 (REQ-HRS-038) P1** — As a Payroll Manager I want to generate Form 16 so that taxed employees get their certificate.
- Happy: Given the FY closed and TDS > 0, When I generate after April 15, Then Part A+B PDFs are produced and employees can download their own.
- Boundary: Given before April 15, When I generate, Then it is blocked (BR-PAY-009).
- DoD: only TDS>0 employees eligible; bulk queued.

---

## Section A — Boundary Note for Enterprise Architect (HRS ↔ SchoolSetup_EmployeeSetup)

**HRS-owned (`hrs_*`) leave entities:** `hrs_leave_types`, `hrs_leave_policies`, `hrs_leave_balances`,
`hrs_leave_applications`, `hrs_leave_approvals`, `hrs_leave_balance_adjustments`, `hrs_holiday_calendars`,
`hrs_lop_records` — with full controllers/services/views in this module.

**Consumed/competing `sch_*` employee masters & a PARALLEL leave engine (SchoolSetup_EmployeeSetup, code SCE):**
- Employee masters legitimately consumed: `sch_employees` (INT UNSIGNED PK), `sch_employees_profile`
  (`reporting_to`), `sch_department`, `sch_designation`, `sch_org_academic_sessions_jnt`.
- **Overlap (flag):** SCE also ships 11 staff-leave tables — `sch_annual_leave_sessions`,
  `sch_staff_leave_types`, `sch_staff_leave_config`, `sch_leave_approval_policies`,
  `sch_leave_approval_policy_levels`, `sch_leave_approval_level_approvers`, `sch_employee_leave_balance`,
  `sch_employee_leave_applications`, `sch_employee_leave_approvals`, `sch_employee_leave_application_docs`,
  `sch_employee_leave_application_remarks` — a second, arguably more elaborate, implementation of the SAME
  capability HRS implements with `hrs_leave_*`. The HRS DDL itself states *"Maximum part of Leave
  Management has been created in Employee Module."*

**Decision required:** designate ONE canonical staff-leave engine. Options — (A) HRS owns leave, SCE leave
tables deprecated; (B) SCE owns leave config/approval, HRS consumes it (drop `hrs_leave_*`); (C) split by
concern (SCE = policy/approval-chain config; HRS = balances/applications/LOP/payroll link). This must be
resolved before further leave or payroll-LWP work, since payroll LWP (BR-PAY-010) reads confirmed LOP that
currently lives in `hrs_lop_records`. `std_leave_*` (StudentProfile) is **student** leave and is unrelated.

*Document ends.*
