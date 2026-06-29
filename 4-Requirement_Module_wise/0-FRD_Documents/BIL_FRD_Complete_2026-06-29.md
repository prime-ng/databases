# Complete Analysis Pack — Billing (BIL)
# Prime-AI School ERP Platform — Central / Prime-layer Module

| Field | Value |
|-------|-------|
| **Module Name** | Billing |
| **Module Code** | BIL |
| **Table Prefix** | `bil_*` (+ shared `prm_billing_cycles`) |
| **Database Layer** | **prime_db** (central SaaS database — NOT tenant_db) |
| **Document Version** | 1.0 |
| **Date** | 2026-06-29 |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI (pa-business-analyst) |
| **Sources Read** | V2 `BIL_Billing_Requirement.md`; V1 screen-spec folder `Billing_v1/` (10 files); live code `Modules/Billing/`; `prime_db_v4.sql`; central `routes/web.php`; module knowledge `BIL_Billing.md` |

> **Scope note (multi-tenancy):** Billing is the only **Prime/central** module documented here. It runs from the Super Admin (platform) panel and manages SaaS subscription invoicing for **all** school tenants. School data is isolated per tenant; Billing is the single exception that *temporarily* reads a tenant's isolated database to count active students for invoice quantity, then immediately closes that context. There is no cross-tenant data mixing in any school's own modules.

---

## Index / Table of Contents

This is the consolidated **Complete Analysis Pack**. The FRD (Sections 1–10) is the single source of truth; every later section references its `REQ-/BR-/RPT-/ENH-` IDs without renumbering.

1. Section 1–10 — **Functional Requirements Document (FRD)**
2. Section A — Requirements Traceability Matrix (RTM)
3. Section B — Business Rules Register (standalone) + Requirement Conditions Catalog + Validation & Edge-Case Catalog
4. Section C — Process Flows + State Machine (FSM) Catalog
5. Section D — Data Dictionary (business view) + Cross-Module Dependency Map
6. Section E — NFR Catalog + Risk Register
7. Section F — Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown
8. Section G — User Stories (Gherkin) + Reporting & KPI Spec
9. Section H — Feature Specification (screen-by-screen)
10. Section I — Technical Reconciliation Appendix (technical register; for DB Architect / Technical Auditor)

---
---

# Functional Requirements Document (FRD)

## Section 1 — Module Overview

### 1.1 Business Purpose
Prime-AI is sold to Indian K-12 schools as a subscription SaaS platform. Every school (tenant) is placed on a subscription plan with a defined billing frequency. The Billing module is the platform operator's back-office that turns those subscriptions into money collected: it generates periodic invoices for each school, records the payments schools make (online, bank transfer, cheque or cash), keeps a tamper-evident history of every billing action, and produces the invoices, receipts and statements schools and auditors need. Without this module the platform operator would have no controlled way to bill schools, track who has paid, or evidence its revenue.

### 1.2 Business Value
- Converts subscriptions into auditable invoices automatically priced from the school's plan, student count and contracted minimums.
- Supports Indian tax practice with up to four configurable tax lines (CGST / SGST / IGST / custom) per invoice.
- Lets the finance team record full, partial and consolidated payments and confirm them against bank/gateway statements (reconciliation).
- Gives every invoice a complete event history (generated, emailed, paid, note added) for dispute handling and audit.
- Delivers professional PDF invoices, receipts and statements by email or bulk download, reducing manual paperwork.

### 1.3 Scope

#### In Scope
1. Maintaining billing cycle types (Monthly, Quarterly, Yearly, One-Time) used to price subscriptions.
2. Generating invoices for due billing-schedule entries, including student-count capture, plan rate, minimum quantity, discounts, extra charges and taxes.
3. Listing, filtering, viewing and adding remarks to invoices.
4. Recording individual payments against a single invoice.
5. Recording one consolidated payment spread across several outstanding invoices.
6. Marking payments as reconciled against bank/gateway confirmations.
7. Emailing invoices as PDF attachments, immediately or at a scheduled time.
8. Generating and bulk-downloading invoice / subscription / payment / reconciliation / audit PDFs (and printable views).
9. Maintaining a per-invoice billing audit trail with free-text notes.
10. (Planned) Automated recurring invoice generation, overdue detection and reminders, usage/overage billing, online payment gateway, a school-facing billing portal, and GST/compliance reporting.

#### Out of Scope
1. **Subscription plan creation and plan-to-school assignment** — owned by the **Prime** module; Billing only reads this data.
2. **School master data** (school profile, classes, sections) — owned by **SchoolSetup**; Billing reads tenant identity only.
3. **Student records and counts at source** — owned by **StudentProfile** inside each tenant database; Billing only counts active students at invoice time.
4. **A school's own fee collection from parents/students** — that is the tenant-side **StudentFee** module, a completely separate concern from platform-to-school SaaS billing.
5. **Platform-wide financial accounting / ledgers** — not handled here.

### 1.4 Key Terminology

| Business Term | Meaning |
|---------------|---------|
| Tenant (School) | A single subscribing school; the customer being billed. |
| Subscription Plan | The package (price, included modules, billing cycle) a school is signed up to; owned by the Prime module. |
| Billing Cycle | Billing frequency: Monthly (1 month), Quarterly (3 months), Yearly (12 months), or One-Time. |
| Billing Schedule | A pre-generated calendar of billing periods for a school's plan; each entry is the trigger for one invoice. |
| Invoice | The billing document raised against a school for one billing period. |
| Billing Quantity | The number of licences billed = the greater of the contracted minimum and the school's actual active student count. |
| Minimum Billing Quantity | Contracted floor — the school is billed for at least this many licences even with fewer active students. |
| Active Student Count | Live count of active students read from the school's own database at invoice time. |
| Net Payable | Final invoice amount = sub-total − discount + extra charges + taxes. |
| Credit Days | Number of days a school is given to pay after the invoice date. |
| Consolidated Payment | A single received amount (e.g. one bank transfer) distributed across several outstanding invoices. |
| Reconciliation | Confirming a recorded payment matches the bank/gateway statement. |
| Audit Trail | The per-invoice event history (who did what, when) plus optional notes. |
| Invoice Status | Lifecycle state: Pending, Partially Paid, Paid, Overdue, Cancelled (configurable list). |

---

## Section 2 — User Roles & Access

### 2.1 Actor Definitions

| Role | Who They Are | Their Relationship to This Module |
|------|-------------|----------------------------------|
| Super Admin | Platform operator's senior administrator | Full access: manage billing cycles, generate invoices, record payments, send emails, view all reports for every school. |
| Prime Accountant | Platform operator's finance staff | Records payments, downloads receipts/PDFs, toggles reconciliation, adds audit notes. |
| Prime Manager | Platform operator's management/oversight | Views the billing dashboard, invoices and subscriptions, downloads reports (read-mostly). |
| School Admin (Tenant) | Administrator at a subscribing school | (Planned) Self-service portal to view and pay their own school's invoices — not yet available. |
| System — Queue Worker | Automated background process | Generates invoice PDFs and sends invoice emails. |
| System — Scheduler | Automated background process | (Planned) Auto-generates due invoices and overdue reminders. |

> Access is enforced by platform permissions of the form *"may generate invoices", "may record payments", "may view billing"* etc. School-level data isolation does not apply between Billing and a school's own modules because Billing is a central operator function over all schools.

### 2.2 Role-Feature Access Matrix

| Feature | Super Admin | Prime Accountant | Prime Manager | School Admin |
|---------|:-----------:|:----------------:|:-------------:|:------------:|
| Billing Cycle Management (REQ-BIL-001) | Full | No Access | View Only | No Access |
| Subscription Viewing (REQ-BIL-002) | Full | View | View | No Access |
| Invoice Generation (REQ-BIL-003) | Full | No Access | No Access | No Access |
| Invoice Listing & Detail (REQ-BIL-004) | Full | View | View | No Access |
| Invoice Remarks (REQ-BIL-005) | Full | Full | View | No Access |
| Individual Payment (REQ-BIL-006) | Full | Full | View | No Access |
| Consolidated Payment (REQ-BIL-007) | Full | Full | View | No Access |
| Payment Reconciliation (REQ-BIL-008) | Full | Full | View | No Access |
| Invoice Email (REQ-BIL-009) | Full | Full | No Access | No Access |
| PDF / ZIP / Print (REQ-BIL-010) | Full | Full | View | No Access |
| Audit Trail & Notes (REQ-BIL-011) | Full | Full | View | No Access |
| Tenant Billing Portal (REQ-BIL-016) | n/a | n/a | n/a | Full (planned) |

---

## Section 3 — Functional Requirements

### 3.1 Billing Cycle Management
**Requirement ID:** REQ-BIL-001
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION] [DATA_ENTRY]

#### Business Description
Lets the Super Admin define and maintain the billing frequencies the platform sells on (Monthly, Quarterly, Yearly, One-Time), including how many months each cycle covers and whether it recurs. These cycles are the foundation used to price plans and schedule billing. Cycles can be created, edited, deactivated, soft-deleted, restored and permanently removed.

#### Actors
- **Initiates:** Super Admin
- **Processes / Approves:** Super Admin
- **Views / Receives notification:** Super Admin, Prime Manager

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-001 | A billing cycle's short code must be unique across the platform. | Validation |
| BR-BIL-002 | The cycle length in months must be a whole number between 1 and 255. | Validation |
| BR-BIL-003 | Deleting a cycle first deactivates it, then soft-deletes it; permanent deletion is blocked if the cycle is in use by any plan or invoice. | Workflow |

#### Acceptance Criteria
1. A Super Admin can create a billing cycle with a unique short code, name and month count, and it appears in the active list.
2. Attempting to save a duplicate short code shows a validation error and saves nothing.
3. A cycle can be deactivated, soft-deleted, restored, and (when not referenced) permanently deleted; a referenced cycle cannot be permanently deleted.

#### Integration with Other Modules
- Sends to: Prime module (cycles are referenced when assigning plans).

#### Enhancement Notes (Future)
- None.

---

### 3.2 Subscription Plan Viewing & Summary Download
**Requirement ID:** REQ-BIL-002
**Priority:** Standard (P1)
**Category Tags:** [DASHBOARD] [REPORT]

#### Business Description
Provides a read-only view of each school's current subscription — the assigned plan, pricing, billing schedule and included modules — so the finance team can see what a school is contracted for before billing it. Detail panels open inline, and a subscription summary can be downloaded as a PDF (single or bulk ZIP). The plan itself is owned and edited in the Prime module; Billing only displays it.

#### Actors
- **Initiates:** Super Admin, Prime Accountant, Prime Manager
- **Processes / Approves:** —
- **Views / Receives notification:** Super Admin, Prime Accountant, Prime Manager

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-004 | Subscription data is read-only inside Billing; any change must be made in the Prime module. | Permission |
| BR-BIL-005 | The subscription list can be filtered by subscription status and start-date range and is shown in pages. | Workflow |

#### Acceptance Criteria
1. A user can open a school's subscription, pricing, billing-schedule and module-list panels without leaving the page.
2. The user can download one or many subscription summaries as PDF (multiple are delivered as a single ZIP).
3. No control on this screen can alter the underlying plan.

#### Integration with Other Modules
- Receives from: Prime (plan, rate, schedule), GlobalMaster (module list).

#### Enhancement Notes (Future)
- Trial-period management, auto-renewal and mid-cycle plan switching with proration (see ENH-BIL-003, ENH-BIL-008).

---

### 3.3 Invoice Generation Engine
**Requirement ID:** REQ-BIL-003
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [CALCULATION] [DATA_ENTRY]

#### Business Description
The heart of the module. For one or more due billing-schedule entries, the Super Admin generates invoices. For each, the system reads the school's plan rate, captures the school's live active-student count, applies the contracted minimum, calculates the sub-total, applies discount and extra charges, calculates up to four tax lines, and produces the net payable. It assigns a unique invoice number, sets the payment due date, records which modules are covered, marks the schedule entry as billed, and writes a "Generated" event to the audit trail — all as a single all-or-nothing operation per invoice.

#### Actors
- **Initiates:** Super Admin
- **Processes / Approves:** Super Admin (selects schedule entries)
- **Views / Receives notification:** Super Admin; (planned) School Admin notified.

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-006 | Every invoice number is globally unique, formatted INV-YYYYMMDD-NNN, where NNN is that day's running count. | Calculation / Validation |
| BR-BIL-007 | Billing quantity = the greater of the contracted minimum quantity and the school's active student count. | Calculation |
| BR-BIL-008 | The active student count is read from the school's own isolated database at generation time, and that connection must be closed immediately after. | Workflow / Concurrency |
| BR-BIL-009 | Sub-total = plan rate × billing quantity. | Calculation |
| BR-BIL-010 | Tax base = sub-total − discount + extra charges; each tax line = tax base × its percentage. | Calculation |
| BR-BIL-011 | Net payable = sub-total − discount + extra charges + total tax. | Calculation |
| BR-BIL-012 | Payment due date = invoice date + credit days. | Calculation |
| BR-BIL-013 | A billing-schedule entry may be invoiced only once; once billed it no longer appears in the "to generate" list. | Workflow |
| BR-BIL-014 | Invoice generation is all-or-nothing: if any step fails the whole invoice is rolled back and the schedule entry stays unbilled. | Workflow / Concurrency |
| BR-BIL-015 | A new invoice starts in Pending status with zero paid. | Workflow |
| BR-BIL-016 | Currency defaults to INR. | Validation |

#### Acceptance Criteria
1. Selecting eligible schedule entries and generating produces correctly priced invoices with unique numbers and a due date.
2. Billing quantity equals the contracted minimum when the active student count is lower, and equals the student count when higher.
3. A schedule entry already billed cannot be billed again.
4. If generation of one invoice fails, that invoice is not partially saved and its schedule entry remains available to retry.
5. A "Generated" entry appears in that invoice's audit trail.

#### Integration with Other Modules
- Receives from: Prime (plan rate, schedule, credit days), StudentProfile (active student count via the school's database), GlobalMaster (module list, status values).
- Sends to: Prime (marks schedule entry billed).

#### Enhancement Notes (Future)
- Automated daily generation (ENH-BIL-001); automatic inclusion of overage line items (ENH-BIL-005).

---

### 3.4 Invoice Listing, Filtering & Detail Viewing
**Requirement ID:** REQ-BIL-004
**Priority:** Core (P0)
**Category Tags:** [DASHBOARD] [REPORT]

#### Business Description
A unified billing dashboard with tabs for invoices, subscriptions, payments, consolidated payments, reconciliation and audit. The invoice tab lists billing-schedule entries and generated invoices, filterable by "to generate" vs "done", invoice status, school and date range, with paging. Selecting an invoice opens its full details (period, rate, quantity, discounts, taxes, totals, payment history, audit) inline.

#### Actors
- **Initiates:** Super Admin, Prime Accountant, Prime Manager
- **Views:** same

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-017 | Lists are filterable by data type, status, school and date range, and shown 10 per page. | Workflow |
| BR-BIL-018 | The date filter defaults to today when none is supplied. | Workflow |

#### Acceptance Criteria
1. A user can switch tabs and the correct data set loads for each.
2. Filters narrow results and persist in the filter form after applying.
3. Opening an invoice shows all its detail without page reload.

#### Integration with Other Modules
- Receives from: Prime, StudentProfile (school identity), GlobalMaster (status labels).

#### Enhancement Notes (Future)
- Colour-coded status badges and inline outstanding-balance display (ENH-BIL-011); persistent bulk-action toolbar.

---

### 3.5 Invoice Remarks Management
**Requirement ID:** REQ-BIL-005
**Priority:** Enhanced (P2)
**Category Tags:** [DATA_ENTRY]

#### Business Description
Allows authorised staff to view and update free-text remarks on an invoice (e.g. context for a discount or a dispute note), kept separate from the formal audit trail.

#### Actors
- **Initiates / Processes:** Super Admin, Prime Accountant
- **Views:** Prime Manager

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-019 | Remarks are editable text and updating them is permission-controlled. | Permission / Validation |

#### Acceptance Criteria
1. A user can open and read an invoice's remarks.
2. A permitted user can update remarks and the new text is saved and shown.
3. A user without the remark permission cannot update remarks.

#### Integration with Other Modules
- None.

#### Enhancement Notes (Future)
- None.

---

### 3.6 Individual Payment Recording
**Requirement ID:** REQ-BIL-006
**Priority:** Core (P0)
**Category Tags:** [DATA_ENTRY] [WORKFLOW]

#### Business Description
Lets finance staff record a payment received against a single invoice — capturing date, amount, mode (online, bank transfer, cheque, cash), transaction reference, status and a reconciliation flag. The invoice's cumulative paid amount and status are updated, and a payment event is written to the audit trail, all as one atomic operation.

#### Actors
- **Initiates / Processes:** Super Admin, Prime Accountant
- **Views:** Prime Manager

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-020 | An invoice's paid amount is cumulative and is never reduced by recording a payment. | Calculation |
| BR-BIL-021 | Recording a payment, updating the invoice and writing the audit entry must all succeed together or all be undone. | Workflow / Concurrency |
| BR-BIL-022 | Sensitive raw request data must never be stored in the audit event detail; only a defined whitelist of payment fields is kept. | Validation / Security |
| BR-BIL-023 | When cumulative paid reaches the net payable the invoice becomes Paid; a smaller payment makes it Partially Paid. | Workflow |

#### Acceptance Criteria
1. Recording a valid payment increases the invoice's paid amount by exactly that amount.
2. The invoice status moves to Partially Paid or Paid based on the cumulative total.
3. A payment event appears in the invoice's audit trail.
4. If any part of the save fails, no payment, invoice change or audit entry is persisted.

#### Integration with Other Modules
- Receives from: GlobalMaster (payment mode/status values).

#### Enhancement Notes (Future)
- Online payment capture via gateway (REQ-BIL-015).

---

### 3.7 Consolidated Payment Recording
**Requirement ID:** REQ-BIL-007
**Priority:** Standard (P1)
**Category Tags:** [DATA_ENTRY] [WORKFLOW]

#### Business Description
Handles the common case where a school pays one lump sum (e.g. a single bank transfer) covering several outstanding invoices. The user enters the total and the allocation per invoice; the system records a payment line per invoice, stores the total against each, updates each invoice's paid amount and status, and logs a payment event per invoice — all in one atomic operation.

#### Actors
- **Initiates / Processes:** Super Admin, Prime Accountant
- **Views:** Prime Manager

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-024 | Invoices with a zero allocation are skipped (no payment line created). | Workflow |
| BR-BIL-025 | The total received is stored against every allocated invoice line, while each line also records its own allocated amount. | Calculation |
| BR-BIL-026 | The whole consolidated posting succeeds together or is fully undone. | Workflow / Concurrency |

#### Acceptance Criteria
1. Entering a total and per-invoice allocations records one payment line per allocated invoice.
2. Invoices allocated zero receive no payment line.
3. Each affected invoice's paid amount and status update correctly.
4. A failure anywhere rolls back the entire consolidated posting.

#### Integration with Other Modules
- Receives from: GlobalMaster (payment mode/status values).

#### Enhancement Notes (Future)
- None.

---

### 3.8 Payment Reconciliation
**Requirement ID:** REQ-BIL-008
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW]

#### Business Description
Lets finance staff confirm that a recorded payment matches the bank or gateway statement by toggling its reconciliation status, and filter the list to reconciled vs non-reconciled transactions. Selected payments can be downloaded as a reconciliation PDF.

#### Actors
- **Initiates / Processes:** Super Admin, Prime Accountant
- **Views:** Prime Manager

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-027 | A payment's reconciliation flag can be toggled on or off and each change is activity-logged. | Workflow |
| BR-BIL-028 | The reconciliation list can be filtered to show reconciled-only or non-reconciled-only payments. | Workflow |

#### Acceptance Criteria
1. Toggling a payment updates its reconciliation status and is reflected immediately.
2. The list can be filtered by reconciliation state.
3. Selected payments can be exported as a reconciliation PDF.

#### Integration with Other Modules
- None.

#### Enhancement Notes (Future)
- Automatic matching of payments to bank/gateway confirmations (ENH-BIL-002 family).

---

### 3.9 Invoice Email Delivery (Immediate & Scheduled)
**Requirement ID:** REQ-BIL-009
**Priority:** Standard (P1)
**Category Tags:** [NOTIFICATION] [SCHEDULED]

#### Business Description
Emails invoices to schools as PDF attachments. Staff can send immediately to one or many invoices, or schedule sending for a chosen future date/time. Sending runs as a background job so the screen is not blocked, and a "Notice Sent" event is recorded on each invoice.

#### Actors
- **Initiates / Processes:** Super Admin, Prime Accountant
- **Receives:** School (recipient of email)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-029 | Each emailed invoice has its PDF generated and attached automatically. | Workflow |
| BR-BIL-030 | A scheduled email is held with a "pending" status until its scheduled time, then dispatched. | Workflow / Scheduled |
| BR-BIL-031 | Sending (immediate or scheduled) records a "Notice Sent" event on the invoice's audit trail. | Workflow |

#### Acceptance Criteria
1. Selecting invoices and sending queues the emails and confirms to the user.
2. Scheduling an email stores it as pending and dispatches it at the scheduled time.
3. A "Notice Sent" audit entry is recorded for each invoice.

#### Integration with Other Modules
- Sends to: school email address (from tenant master).

#### Enhancement Notes (Future)
- Retry/failure handling and failed-status updates on the schedule (ENH technical); overdue reminder emails (ENH-BIL-002).

---

### 3.10 Invoice & Document PDF / ZIP Download & Print
**Requirement ID:** REQ-BIL-010
**Priority:** Standard (P1)
**Category Tags:** [REPORT]

#### Business Description
Produces professional A4 PDFs and printable views for invoices, subscription summaries, consolidated payment statements, reconciliation reports and audit reports. Multiple invoices can be bulk-downloaded as a single ZIP archive.

#### Actors
- **Initiates / Processes:** Super Admin, Prime Accountant
- **Views:** Prime Manager

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-032 | A bulk download packages each selected invoice's PDF into one ZIP and cleans up its temporary files afterward. | Workflow |
| BR-BIL-033 | Printable views are provided for each data type (invoice, subscription, consolidated, reconciliation, payment, audit). | Workflow |

#### Acceptance Criteria
1. A single invoice can be downloaded/printed as an A4 PDF.
2. Selecting multiple invoices produces one ZIP containing all their PDFs.
3. Each major data type has a working printable view.

#### Integration with Other Modules
- None.

#### Enhancement Notes (Future)
- Move large bulk ZIP generation to a background job with a "ready" notification (ENH-BIL-009).

---

### 3.11 Billing Audit Trail & Notes
**Requirement ID:** REQ-BIL-011
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW] [REPORT]

#### Business Description
Maintains a per-invoice event history — generation, payments, notices sent, etc. — capturing who performed the action, when, and structured event detail. Staff can add and update free-text notes on the trail and view the structured event detail, and produce an audit report PDF filtered by date, school, performer and event type. The trail is append-only except for its notes.

#### Actors
- **Initiates / Processes:** Super Admin, Prime Accountant
- **Views:** Prime Manager

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-034 | Audit entries are append-only; only the note text may be updated after creation. | Workflow |
| BR-BIL-035 | Each audit entry records the acting user and timestamp. | Validation |
| BR-BIL-036 | The audit report can be filtered by date range, school, performer and event type. | Workflow |

#### Acceptance Criteria
1. Every billing action (generation, payment, email) creates an audit entry on the relevant invoice.
2. A user can add and update a note on an audit entry, but cannot alter the recorded event itself.
3. An audit report PDF can be produced with the available filters.

#### Integration with Other Modules
- Receives from: SystemConfig (acting user identity).

#### Enhancement Notes (Future)
- Record plan upgrade/downgrade events once subscription lifecycle is built.

---

### 3.12 Automated Recurring Invoice Scheduler *(Planned)*
**Requirement ID:** REQ-BIL-012
**Priority:** Enhanced (P2)
**Category Tags:** [SCHEDULED] [WORKFLOW]

#### Business Description
A background process that, each day, finds billing-schedule entries due that day and generates their invoices automatically, removing the need for manual generation as the number of schools grows.

#### Actors
- **Initiates:** System — Scheduler
- **Views:** Super Admin

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-037 | The scheduler generates an invoice only for entries due today that are not already billed, applying all generation rules (BR-BIL-006 to BR-BIL-016). | Workflow |

#### Acceptance Criteria
1. On a day with due entries, invoices are generated without manual action.
2. Entries already billed are skipped.
3. Generation failures are logged and retried without blocking other entries.

#### Integration with Other Modules
- Receives from: Prime (billing schedule).

#### Enhancement Notes (Future)
- Promoted from ENH-BIL-001.

---

### 3.13 Overdue Detection & Payment Reminders *(Planned)*
**Requirement ID:** REQ-BIL-013
**Priority:** Enhanced (P2)
**Category Tags:** [SCHEDULED] [NOTIFICATION]

#### Business Description
A daily process that flags invoices past their due date and still unpaid as Overdue and sends reminder emails to the school, recording an Overdue event on the audit trail.

#### Actors
- **Initiates:** System — Scheduler
- **Receives:** School

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-038 | An invoice past its due date with paid amount below net payable and not cancelled is marked Overdue and triggers a reminder. | Workflow |

#### Acceptance Criteria
1. Eligible invoices are automatically marked Overdue.
2. A reminder email is sent and an Overdue audit entry recorded.
3. Paid or cancelled invoices are never flagged.

#### Integration with Other Modules
- Sends to: school email.

#### Enhancement Notes (Future)
- Promoted from ENH-BIL-002.

---

### 3.14 Usage Metering & Overage Billing *(Planned)*
**Requirement ID:** REQ-BIL-014
**Priority:** Enhanced (P2)
**Category Tags:** [INTEGRATION] [CALCULATION]

#### Business Description
Tracks each school's consumption (e.g. storage, API usage) against plan limits, warns when nearing limits, and adds overage charges to invoices when limits are exceeded.

#### Actors
- **Initiates:** System
- **Views:** Super Admin; School (planned)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-039 | Usage above a plan threshold is priced as overage and added as invoice line items. | Calculation |

#### Acceptance Criteria
1. Consumption is tracked per school against plan limits.
2. Schools are warned as they approach limits.
3. Exceeding a limit produces overage charges on the next invoice.

#### Integration with Other Modules
- Receives from: platform usage telemetry (future).

#### Enhancement Notes (Future)
- Entire requirement is future scope.

---

### 3.15 Online Payment Gateway Integration (Razorpay) *(Planned)*
**Requirement ID:** REQ-BIL-015
**Priority:** Standard (P1)
**Category Tags:** [INTEGRATION] [WORKFLOW]

#### Business Description
Enables schools to pay invoices online. The platform configures gateway keys and currencies, schools are redirected to pay, and the gateway confirms payment back to the platform, which records the payment and updates the invoice automatically.

#### Actors
- **Initiates:** School (pays); Super Admin (configures)
- **Processes:** System (records confirmation)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-040 | The gateway's payment-confirmation callback must be authenticated by verifying its signature, not by a user login session. | Security / Validation |
| BR-BIL-041 | A confirmed online payment is recorded and applied to the invoice the same way as a manual payment, including audit logging. | Workflow |

#### Acceptance Criteria
1. The platform can configure gateway credentials and supported currencies.
2. A school can complete an online payment and be returned to the platform.
3. A verified confirmation updates the invoice's paid amount and status automatically.
4. An unverified/forged confirmation is rejected.

#### Integration with Other Modules
- External: payment gateway (Razorpay).

#### Enhancement Notes (Future)
- Multi-currency and exchange-rate sourcing.

---

### 3.16 Tenant Self-Service Billing Portal *(Planned)*
**Requirement ID:** REQ-BIL-016
**Priority:** Enhanced (P2)
**Category Tags:** [DASHBOARD] [REPORT]

#### Business Description
A school-facing area where a School Admin can view their own invoices, filter by paid/unpaid, download invoice PDFs and receipts, and initiate online payment — all scoped strictly to their own school.

#### Actors
- **Initiates / Views:** School Admin

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-042 | A School Admin may only ever see and pay invoices belonging to their own school. | Permission / Security |

#### Acceptance Criteria
1. A School Admin sees only their own school's invoices.
2. They can filter by paid/unpaid and download invoice/receipt PDFs.
3. They can initiate an online payment for an unpaid invoice.

#### Integration with Other Modules
- Receives from: gateway (REQ-BIL-015).

#### Enhancement Notes (Future)
- Show usage/overage to the school.

---

### 3.17 GST & Compliance Reporting *(Planned)*
**Requirement ID:** REQ-BIL-017
**Priority:** Standard (P1)
**Category Tags:** [REPORT] [INTEGRATION]

#### Business Description
Produces GST/tax reports and revenue summaries for the platform operator's statutory and management reporting, and enriches invoices with the data B2B GST invoices require (seller/buyer GSTIN, place of supply, SAC code).

#### Actors
- **Initiates / Views:** Super Admin, Prime Accountant

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-BIL-043 | Tax reports aggregate invoice tax lines by tax type and period for the platform operator. | Calculation / Report |

#### Acceptance Criteria
1. A GST/tax report can be produced for a chosen period.
2. Revenue/collection summaries are available by period.
3. Invoices carry the GST fields required for B2B compliance.

#### Integration with Other Modules
- None (platform-level reporting).

#### Enhancement Notes (Future)
- GSTIN capture on tenant profile; default Indian GST tax templates (ENH-BIL-006, ENH-BIL-007).

---

## Section 4 — Business Rules Register

| Rule ID | Description | Feature | Rule Type | Priority |
|---------|-------------|---------|-----------|----------|
| BR-BIL-001 | Billing cycle short code is unique. | REQ-BIL-001 | Validation | P0 |
| BR-BIL-002 | Cycle length 1–255 months. | REQ-BIL-001 | Validation | P0 |
| BR-BIL-003 | Delete deactivates then soft-deletes; permanent delete blocked if referenced. | REQ-BIL-001 | Workflow | P0 |
| BR-BIL-004 | Subscription data is read-only inside Billing. | REQ-BIL-002 | Permission | P1 |
| BR-BIL-005 | Subscription list filterable by status and start-date range, paged. | REQ-BIL-002 | Workflow | P1 |
| BR-BIL-006 | Invoice number globally unique, format INV-YYYYMMDD-NNN. | REQ-BIL-003 | Calculation/Validation | P0 |
| BR-BIL-007 | Billing qty = max(min qty, active student count). | REQ-BIL-003 | Calculation | P0 |
| BR-BIL-008 | Student count read from school DB then connection closed immediately. | REQ-BIL-003 | Workflow/Concurrency | P0 |
| BR-BIL-009 | Sub-total = plan rate × billing qty. | REQ-BIL-003 | Calculation | P0 |
| BR-BIL-010 | Tax base = sub-total − discount + extra; each tax = base × percent. | REQ-BIL-003 | Calculation | P0 |
| BR-BIL-011 | Net payable = sub-total − discount + extra + total tax. | REQ-BIL-003 | Calculation | P0 |
| BR-BIL-012 | Payment due date = invoice date + credit days. | REQ-BIL-003 | Calculation | P0 |
| BR-BIL-013 | A schedule entry can be invoiced only once. | REQ-BIL-003 | Workflow | P0 |
| BR-BIL-014 | Invoice generation is atomic (all-or-nothing). | REQ-BIL-003 | Workflow/Concurrency | P0 |
| BR-BIL-015 | New invoice starts Pending, zero paid. | REQ-BIL-003 | Workflow | P0 |
| BR-BIL-016 | Currency defaults to INR. | REQ-BIL-003 | Validation | P1 |
| BR-BIL-017 | Lists filterable by data type/status/school/date, 10 per page. | REQ-BIL-004 | Workflow | P1 |
| BR-BIL-018 | Date filter defaults to today. | REQ-BIL-004 | Workflow | P2 |
| BR-BIL-019 | Remarks are permission-controlled editable text. | REQ-BIL-005 | Permission/Validation | P2 |
| BR-BIL-020 | Invoice paid amount is cumulative, never reduced. | REQ-BIL-006 | Calculation | P0 |
| BR-BIL-021 | Payment + invoice update + audit entry are atomic. | REQ-BIL-006 | Workflow/Concurrency | P0 |
| BR-BIL-022 | No raw request data in audit detail; whitelist payment fields only. | REQ-BIL-006 | Validation/Security | P1 |
| BR-BIL-023 | Paid≥net → Paid; 0<paid<net → Partially Paid. | REQ-BIL-006 | Workflow | P0 |
| BR-BIL-024 | Zero-allocation invoices skipped in consolidated payment. | REQ-BIL-007 | Workflow | P1 |
| BR-BIL-025 | Total stored per line; each line also keeps its own allocation. | REQ-BIL-007 | Calculation | P1 |
| BR-BIL-026 | Consolidated posting is atomic. | REQ-BIL-007 | Workflow/Concurrency | P1 |
| BR-BIL-027 | Reconciliation flag toggleable and activity-logged. | REQ-BIL-008 | Workflow | P1 |
| BR-BIL-028 | Reconciliation list filterable reconciled/non-reconciled. | REQ-BIL-008 | Workflow | P1 |
| BR-BIL-029 | Emailed invoice has PDF generated and attached. | REQ-BIL-009 | Workflow | P1 |
| BR-BIL-030 | Scheduled email held pending until scheduled time then dispatched. | REQ-BIL-009 | Workflow/Scheduled | P1 |
| BR-BIL-031 | Sending records a "Notice Sent" audit event. | REQ-BIL-009 | Workflow | P1 |
| BR-BIL-032 | Bulk download packages PDFs into one ZIP and cleans temp files. | REQ-BIL-010 | Workflow | P1 |
| BR-BIL-033 | Printable views exist per data type. | REQ-BIL-010 | Workflow | P1 |
| BR-BIL-034 | Audit entries append-only except notes. | REQ-BIL-011 | Workflow | P1 |
| BR-BIL-035 | Each audit entry records acting user and timestamp. | REQ-BIL-011 | Validation | P1 |
| BR-BIL-036 | Audit report filterable by date/school/performer/event type. | REQ-BIL-011 | Workflow | P1 |
| BR-BIL-037 | Scheduler generates only due, unbilled entries applying all generation rules. | REQ-BIL-012 | Workflow | P2 |
| BR-BIL-038 | Overdue = past due, paid<net, not cancelled → mark + remind. | REQ-BIL-013 | Workflow | P2 |
| BR-BIL-039 | Usage above threshold priced as overage line items. | REQ-BIL-014 | Calculation | P2 |
| BR-BIL-040 | Gateway callback authenticated by signature, not session. | REQ-BIL-015 | Security/Validation | P1 |
| BR-BIL-041 | Confirmed online payment applied like a manual payment with audit. | REQ-BIL-015 | Workflow | P1 |
| BR-BIL-042 | School Admin sees/pays only their own school's invoices. | REQ-BIL-016 | Permission/Security | P2 |
| BR-BIL-043 | Tax reports aggregate tax lines by type and period. | REQ-BIL-017 | Calculation/Report | P1 |

**Total business rules: 43.**

---

## Section 5 — Data Requirements

### 5.1 Billing Cycle
**What it represents:** A billing frequency the platform sells on.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Short Code | Machine code (e.g. MONTHLY) | Yes | Unique |
| Name | Display name | Yes | |
| Months Count | Length in months | Yes | 1–255 |
| Description | Free text | No | |
| Recurring? | Whether it repeats | Yes | Default yes |
| Active? | In use for sale | Yes | Default yes |
**Relationships:** Used by Plans and Invoices. **Retention:** Long-lived config; soft-deletable when unused. **Privacy:** Internal.

### 5.2 Invoice
**What it represents:** The billing document raised against a school for one period.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| School | The billed tenant | Yes | |
| Subscription | The plan assignment billed | Yes | |
| Billing Cycle | Frequency applied | Yes | |
| Invoice Number | Unique reference | Yes | INV-YYYYMMDD-NNN |
| Invoice Date / Period Start / Period End | Dates | Yes | |
| Minimum / Actual Student / Billing Quantity | Counts | Yes | Billing qty = max of the first two |
| Plan Rate / Sub-total | Money | Yes | Sub-total = rate × billing qty |
| Discount (% / amount / remark) | Money | No | |
| Extra Charges (amount / remark) | Money | No | |
| Tax Lines 1–4 (percent / amount / label) | Money | No | CGST/SGST/IGST/custom |
| Total Tax / Net Payable | Money | Yes | |
| Paid Amount | Cumulative money | Yes | Never reduced |
| Currency | ISO code | Yes | Default INR |
| Status | Lifecycle state | Yes | Config-driven list |
| Credit Days / Payment Due Date | Terms | Yes | Due = date + credit days |
| Remarks | Free text | No | |
**Relationships:** Belongs to School, Subscription, Cycle; contains Module list, Payments, Audit entries. **Retention:** Permanent (financial record); soft-delete only. **Privacy:** Confidential (financial).

### 5.3 Invoice Module Coverage
**What it represents:** Which platform modules an invoice covers. **Privacy:** Internal.

### 5.4 Payment
**What it represents:** A payment received against an invoice.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Invoice | The invoice paid | Yes | |
| Payment Date | When received | Yes | |
| Transaction Reference | Bank/gateway ref | No | |
| Mode / Other | online/bank/cheque/cash | Yes | Config-driven |
| Amount Paid | Per-invoice allocation | Yes | |
| Consolidated Amount | Total when part of a consolidated payment | No | |
| Currency / Status | INR / success-failed | Yes | |
| Reconciled? | Matched to statement | Yes | Default no |
| Remarks | Free text | No | |
**Relationships:** Belongs to Invoice. **Retention:** Permanent. **Privacy:** Confidential. **PII/Sensitive:** Gateway response may contain sensitive data — must not be exposed in audit detail (BR-BIL-022).

### 5.5 Audit Entry
**What it represents:** One event in an invoice's history (who/what/when + detail + optional note).
**Relationships:** Belongs to Invoice and to the acting user. **Retention:** Permanent, append-only. **Privacy:** Confidential.

### 5.6 Email Schedule
**What it represents:** A queued/scheduled invoice email with a pending/sent/failed status. **Privacy:** Internal.

---

## Section 6 — Workflows

### 6.1 Invoice Generation Workflow
**Trigger:** Super Admin selects eligible billing-schedule entries and generates. **End State:** One Pending invoice per entry, schedule marked billed.
**Steps:**
1. [Super Admin] selects entries → [System] validates each is unbilled.
2. [System] reads plan rate for the period; reads the school's active student count from its own database, then closes that connection (BR-BIL-008).
3. [System] computes billing qty, sub-total, discount, extra, taxes, net payable; assigns invoice number; sets due date.
4. [System] creates the invoice (Pending), records covered modules, marks the schedule entry billed, writes a "Generated" audit entry — atomically.
**Exception Paths:** If the plan rate is missing, the student-count read fails, or any write fails → roll back that invoice; the entry stays unbilled and the reason is returned.
**Notifications:** (Planned) School notified on generation.

### 6.2 Payment Recording Workflow (Individual & Consolidated)
**Trigger:** Staff records a payment. **End State:** Invoice paid amount and status updated, audit entry written.
**Steps (individual):** validate → begin atomic operation → create payment → increase invoice paid amount → update status → write payment audit entry → commit.
**Steps (consolidated):** validate → begin atomic operation → for each allocated invoice (skip zero) create a payment line (store total + allocation), update paid amount and status, write audit entry → commit.
**Exception Paths:** Any failure rolls back the entire posting (BR-BIL-021, BR-BIL-026).
**Notifications:** None (internal).

### 6.3 Email Dispatch Workflow
**Trigger:** Staff sends or schedules invoice email. **End State:** Email delivered (or held until scheduled time), "Notice Sent" audit entry written.
**Steps:** queue a background job per invoice → job generates the PDF → records "Notice Sent" → sends the email with PDF attached. Scheduled emails are stored pending and dispatched at the chosen time.
**Exception Paths:** Delivery failure should be retried and, on final failure, the schedule marked failed *(currently not implemented — see Section I)*.

### 6.4 Reconciliation Workflow
**Trigger:** Accountant reviews a payment. **End State:** Payment reconciliation flag set/cleared.
**Steps:** open reconciliation tab → toggle a payment → status flips and is activity-logged.
**Exception Paths:** None material.

### 6.5 Billing Cycle Lifecycle
**Trigger:** Super Admin manages a cycle. **End State:** Cycle active/inactive/soft-deleted/restored/removed.
**Steps:** create/edit → deactivate → soft-delete → restore → (if unreferenced) permanently delete.
**Exception Paths:** Permanent delete blocked when the cycle is referenced by a plan or invoice.

---

## Section 7 — Reporting & Analytics Requirements

### 7.1 Invoice / Tax Invoice Document
**Report ID:** RPT-BIL-001 | **Audience:** Super Admin, Accountant, School | **Frequency:** As-needed | **Priority:** P0
Contents: school, period, plan rate, billing quantity, sub-total, discount, extra charges, tax lines, net payable, due date, payment status. Filters: by invoice. Export: PDF (single + bulk ZIP), Print.

### 7.2 Subscription Summary
**Report ID:** RPT-BIL-002 | **Audience:** Super Admin, Accountant | **Frequency:** As-needed | **Priority:** P1
Contents: plan, pricing, billing schedule, included modules. Export: PDF (single + ZIP), Print.

### 7.3 Consolidated Payment Statement
**Report ID:** RPT-BIL-003 | **Audience:** Accountant | **Frequency:** As-needed | **Priority:** P1
Contents: total received and per-invoice allocations for outstanding invoices. Filters: school, date range. Export: PDF, Print.

### 7.4 Payment Reconciliation Report
**Report ID:** RPT-BIL-004 | **Audience:** Accountant | **Frequency:** Weekly/As-needed | **Priority:** P1
Contents: selected payments with reconciliation status. Filters: reconciled/non-reconciled, date range. Export: PDF, Print.

### 7.5 Billing Audit Log Report
**Report ID:** RPT-BIL-005 | **Audience:** Super Admin, Accountant | **Frequency:** As-needed | **Priority:** P1
Contents: invoice events with performer, timestamp, type and note. Filters: date range, school, performer, event type. Export: PDF, Print.

### 7.6 GST / Tax Compliance Report *(Planned)*
**Report ID:** RPT-BIL-006 | **Audience:** Super Admin, Accountant | **Frequency:** Monthly/Quarterly | **Priority:** P2
Contents: tax collected by type (CGST/SGST/IGST) and period; country/place-of-supply summaries.

### 7.7 Revenue / Collection Dashboard *(Planned)*
**Report ID:** RPT-BIL-007 | **Audience:** Super Admin, Prime Manager | **Frequency:** Ongoing | **Priority:** P2
Contents: billed vs collected, outstanding, MRR, payment-failure rate across tenants.

---

## Section 8 — Future Enhancement Log

| Enhancement ID | Requested Feature | Reason / Business Value | Requested By | Priority | Status |
|----------------|------------------|------------------------|--------------|----------|--------|
| ENH-BIL-001 | Automated recurring invoice generation | Manual generation does not scale past ~100 tenants | Analyst | P1 | Backlog (→REQ-BIL-012) |
| ENH-BIL-002 | Overdue detection + automated reminders | No mechanism flags overdue invoices today | Analyst | P1 | Backlog (→REQ-BIL-013) |
| ENH-BIL-003 | Trial-period management & auto-convert | Support trial-to-paid lifecycle | Analyst | P2 | Backlog |
| ENH-BIL-004 | Academic-year billing alignment (Apr–Mar) | Year-wise revenue reporting for Indian schools | Analyst | P2 | Backlog |
| ENH-BIL-005 | Multi-school trust/group consolidated billing | Trusts (DAV, KV) bill multiple campuses together | Analyst | P3 | Backlog |
| ENH-BIL-006 | Default Indian GST tax templates (CGST/SGST/IGST) | Faster, error-free tax entry | Analyst | P1 | Backlog |
| ENH-BIL-007 | GSTIN, HSN/SAC, place-of-supply on invoice PDF | B2B GST compliance | Analyst | P1 | Backlog |
| ENH-BIL-008 | Mid-cycle plan switch with proration | Upgrade/downgrade support | Analyst | P2 | Backlog |
| ENH-BIL-009 | Queued ZIP generation with "ready" notification | Avoid timeouts on 50+ invoice bulk download | Analyst | P2 | Backlog |
| ENH-BIL-010 | In-app notification on invoice generation | Immediate school awareness | Analyst | P3 | Backlog |
| ENH-BIL-011 | Status badges + inline outstanding balance | Faster visual scanning for accountants | Analyst | P3 | Backlog |
| ENH-BIL-012 | Payment-source tracking (self/grant) | Subsidy reporting for government-aided schools | Analyst | P3 | Backlog |

**Total enhancements logged: 12.**

---

## Section 9 — Non-Functional Requirements

### 9.1 Performance Expectations
| Requirement | Standard |
|-------------|---------|
| Billing dashboard load | < 3 seconds with 1,000+ records |
| Standard report generation | < 10 seconds |
| Reference-data loading | School/user lists must be filtered/paged, not loaded wholesale on every page |
| Bulk ZIP | 50+ invoices generated via background job |

### 9.2 Security Requirements (Business Language)
| Requirement | Rule |
|-------------|------|
| Access control | Every billing screen and action requires the matching billing permission. |
| Cross-school protection | The planned school portal must show a school only its own invoices. |
| Audit trail | Every billing action records who did it and when; entries are append-only. |
| Sensitive data | Raw payment/gateway data must never be stored in audit detail; whitelist only. |
| Gateway callbacks | Online-payment confirmations must be verified by signature, not by a login session. |
| Tenant context | When reading a school's database for student count, that connection must be closed immediately after. |

### 9.3 Usability Requirements
| Requirement | Standard |
|-------------|---------|
| Inline panels | Subscription/invoice/payment/audit detail open without leaving the page. |
| Print & PDF | Each data type has a professional A4 PDF and a printable view. |
| Language | English labels and messages. |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Summary
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---------------|---------|----------|------|:---:|:---:|:---:|:---:|:---:|
| REQ-BIL-001 | Billing Cycle Management | P0 | CONFIG, DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-BIL-002 | Subscription Viewing & Download | P1 | DASHBOARD, REPORT | No | Yes | No | No | Yes |
| REQ-BIL-003 | Invoice Generation Engine | P0 | WORKFLOW, CALC | Yes | Yes | No | Yes | Yes |
| REQ-BIL-004 | Invoice Listing & Detail | P0 | DASHBOARD, REPORT | Yes | Yes | No | No | Yes |
| REQ-BIL-005 | Invoice Remarks | P2 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-BIL-006 | Individual Payment | P0 | DATA_ENTRY, WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-BIL-007 | Consolidated Payment | P1 | DATA_ENTRY, WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-BIL-008 | Payment Reconciliation | P1 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-BIL-009 | Invoice Email (Immediate+Scheduled) | P1 | NOTIFICATION, SCHEDULED | Yes | Yes | Yes | No | Yes |
| REQ-BIL-010 | PDF / ZIP / Print | P1 | REPORT | No | Yes | No | No | Yes |
| REQ-BIL-011 | Audit Trail & Notes | P1 | WORKFLOW, REPORT | Yes | Yes | No | No | Yes |
| REQ-BIL-012 | Automated Scheduler | P2 | SCHEDULED, WORKFLOW | No | No | No | Yes | Yes |
| REQ-BIL-013 | Overdue Detection & Reminders | P2 | SCHEDULED, NOTIFICATION | No | No | No | Yes | Yes |
| REQ-BIL-014 | Usage Metering & Overage | P2 | INTEGRATION, CALC | Yes | Yes | Yes | No | Yes |
| REQ-BIL-015 | Payment Gateway (Razorpay) | P1 | INTEGRATION, WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-BIL-016 | Tenant Billing Portal | P2 | DASHBOARD, REPORT | No | Yes | No | No | Yes |
| REQ-BIL-017 | GST & Compliance Reporting | P1 | REPORT, INTEGRATION | Yes | Yes | No | No | Yes |

### 10.2 Business Rules Coverage Summary
| Rule ID | Rule Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|-------------|-------------|:---:|:---:|:---:|
| BR-BIL-001 | Unique cycle code | REQ-BIL-001 | Yes | Yes | No |
| BR-BIL-002 | Months 1–255 | REQ-BIL-001 | Yes | No | No |
| BR-BIL-003 | Delete blocked if referenced | REQ-BIL-001 | No | Yes | Yes |
| BR-BIL-004 | Subscription read-only | REQ-BIL-002 | No | No | Yes |
| BR-BIL-005 | Subscription filter/paging | REQ-BIL-002 | No | No | No |
| BR-BIL-006 | Unique invoice number format | REQ-BIL-003 | Yes | Yes | No |
| BR-BIL-007 | Billing qty = max(min, count) | REQ-BIL-003 | No | Yes | No |
| BR-BIL-008 | Close tenant connection after count | REQ-BIL-003 | No | No | Yes |
| BR-BIL-009 | Sub-total formula | REQ-BIL-003 | No | Yes | No |
| BR-BIL-010 | Tax base & line formula | REQ-BIL-003 | No | Yes | No |
| BR-BIL-011 | Net payable formula | REQ-BIL-003 | No | Yes | No |
| BR-BIL-012 | Due date formula | REQ-BIL-003 | No | Yes | No |
| BR-BIL-013 | Bill once | REQ-BIL-003 | No | Yes | Yes |
| BR-BIL-014 | Atomic generation | REQ-BIL-003 | No | No | Yes |
| BR-BIL-015 | New invoice Pending | REQ-BIL-003 | No | No | Yes |
| BR-BIL-016 | Default INR | REQ-BIL-003 | Yes | No | No |
| BR-BIL-017 | List filter/paging | REQ-BIL-004 | No | No | No |
| BR-BIL-018 | Default date today | REQ-BIL-004 | No | No | No |
| BR-BIL-019 | Remark permission | REQ-BIL-005 | Yes | No | Yes |
| BR-BIL-020 | Paid cumulative | REQ-BIL-006 | No | Yes | No |
| BR-BIL-021 | Atomic payment | REQ-BIL-006 | No | No | Yes |
| BR-BIL-022 | No raw data in audit | REQ-BIL-006 | Yes | No | Yes |
| BR-BIL-023 | Status from cumulative paid | REQ-BIL-006 | No | Yes | Yes |
| BR-BIL-024 | Skip zero allocation | REQ-BIL-007 | Yes | No | Yes |
| BR-BIL-025 | Total + allocation stored | REQ-BIL-007 | No | Yes | No |
| BR-BIL-026 | Atomic consolidated | REQ-BIL-007 | No | No | Yes |
| BR-BIL-027 | Toggle reconcile + log | REQ-BIL-008 | No | No | Yes |
| BR-BIL-028 | Reconcile filter | REQ-BIL-008 | No | No | No |
| BR-BIL-029 | PDF attached to email | REQ-BIL-009 | No | No | Yes |
| BR-BIL-030 | Scheduled email pending→sent | REQ-BIL-009 | No | No | Yes |
| BR-BIL-031 | Notice Sent audit | REQ-BIL-009 | No | No | Yes |
| BR-BIL-032 | ZIP + temp cleanup | REQ-BIL-010 | No | No | Yes |
| BR-BIL-033 | Print views per type | REQ-BIL-010 | No | No | No |
| BR-BIL-034 | Append-only audit | REQ-BIL-011 | No | No | Yes |
| BR-BIL-035 | Record performer + time | REQ-BIL-011 | Yes | No | No |
| BR-BIL-036 | Audit report filters | REQ-BIL-011 | No | No | No |
| BR-BIL-037 | Scheduler eligibility | REQ-BIL-012 | No | Yes | Yes |
| BR-BIL-038 | Overdue eligibility | REQ-BIL-013 | No | Yes | Yes |
| BR-BIL-039 | Overage pricing | REQ-BIL-014 | No | Yes | No |
| BR-BIL-040 | Signature-verified callback | REQ-BIL-015 | Yes | No | Yes |
| BR-BIL-041 | Online payment applied like manual | REQ-BIL-015 | No | No | Yes |
| BR-BIL-042 | School sees own invoices only | REQ-BIL-016 | No | Yes | Yes |
| BR-BIL-043 | Tax report aggregation | REQ-BIL-017 | No | Yes | No |

### 10.3 Report Coverage Summary
| Report ID | Report Name | Priority | Filters Count | Export Needed |
|-----------|------------|----------|:---:|:---:|
| RPT-BIL-001 | Invoice / Tax Invoice | P0 | 1 | Yes |
| RPT-BIL-002 | Subscription Summary | P1 | 1 | Yes |
| RPT-BIL-003 | Consolidated Payment Statement | P1 | 2 | Yes |
| RPT-BIL-004 | Payment Reconciliation | P1 | 2 | Yes |
| RPT-BIL-005 | Billing Audit Log | P1 | 4 | Yes |
| RPT-BIL-006 | GST / Tax Compliance | P2 | 2 | Yes |
| RPT-BIL-007 | Revenue / Collection Dashboard | P2 | 3 | Yes |

### 10.4 Total Scope Numbers
| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 17 |
| Total Business Rules (BR-) | 43 |
| Total Workflows defined | 5 |
| Total Reports required | 7 |
| Total Enhancements logged | 12 |
| Total P0 (Core) Requirements | 4 |
| Total P1 (Standard) Requirements | 8 |
| Total P2 (Enhanced) Requirements | 5 |

---
---

# Section A — Requirements Traceability Matrix (RTM)

> Code status reflects live code verified 2026-06-29. "Built" = implemented and working; "Partial" = built with known defects; "Not started" = future scope.

| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | Code Status |
|--------|---------|---------|-----------|----------|-----------|-------------|
| REQ-BIL-001 | Billing Cycle Management | 001–003 | Billing Cycle index/create/edit/trash | 6.5 | — | Built |
| REQ-BIL-002 | Subscription Viewing & Download | 004–005 | Subscription tab + detail panels + PDF | — | RPT-002 | Partial (lifecycle features not started) |
| REQ-BIL-003 | Invoice Generation | 006–016 | Invoicing tab | 6.1 | RPT-001 | Partial (atomicity/scheduler gaps) |
| REQ-BIL-004 | Invoice Listing & Detail | 017–018 | Billing Management index | — | — | Built |
| REQ-BIL-005 | Invoice Remarks | 019 | Invoice remarks panel | — | — | Built |
| REQ-BIL-006 | Individual Payment | 020–023 | Add-payment panel | 6.2 | — | Partial (no try/catch; audit FK + leak) |
| REQ-BIL-007 | Consolidated Payment | 024–026 | Consolidated payment tab | 6.2 | RPT-003 | Partial (no try/catch; array validation gaps) |
| REQ-BIL-008 | Payment Reconciliation | 027–028 | Reconciliation tab | 6.4 | RPT-004 | Built |
| REQ-BIL-009 | Invoice Email | 029–031 | Schedule-invoice modal | 6.3 | — | Partial (no retry/failure handling) |
| REQ-BIL-010 | PDF / ZIP / Print | 032–033 | PDF/print views | — | RPT-001..005 | Partial (sync ZIP) |
| REQ-BIL-011 | Audit Trail & Notes | 034–036 | Audit tab + note panels | — | RPT-005 | Partial (FK mismatch; unprotected note methods) |
| REQ-BIL-012 | Automated Scheduler | 037 | — | 6.1 | — | Not started |
| REQ-BIL-013 | Overdue & Reminders | 038 | — | — | — | Not started |
| REQ-BIL-014 | Usage Metering & Overage | 039 | — | — | — | Not started |
| REQ-BIL-015 | Payment Gateway | 040–041 | — | — | — | Not started (package installed) |
| REQ-BIL-016 | Tenant Billing Portal | 042 | — | — | — | Not started |
| REQ-BIL-017 | GST & Compliance Reporting | 043 | — | — | RPT-006 | Not started |

---

# Section B — Business Rules, Conditions & Validation

## B.1 Business Rules Register
See **FRD Section 4** (43 rules, BR-BIL-001 to BR-BIL-043) — not restated here.

## B.2 Requirement Conditions Catalog
*(Canonical copy also belongs at `{REQUIREMENT_CONDITIONS}/Billing_Conditions.md`; reuses BR- IDs.)*

| Condition ID (=BR-) | Entity/Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-BIL-001 | Cycle.short_code | Must be unique | Validation | Save cycle | Reject with validation error |
| BR-BIL-002 | Cycle.months_count | 1–255 integer | Validation | Save cycle | Reject |
| BR-BIL-006 | Invoice.number | Unique, INV-YYYYMMDD-NNN | Validation | Generate | Block / regenerate counter |
| BR-BIL-007 | Invoice.billing_qty | = max(min, active count) | Calculation | Generate | Recompute |
| BR-BIL-008 | Tenant connection | Closed after student count | Concurrency | Generate | Risk of context leak — must close |
| BR-BIL-011 | Invoice.net_payable | = sub−disc+extra+tax | Calculation | Generate | Recompute |
| BR-BIL-013 | Schedule.billed | Invoice once only | Workflow | Generate | Hide entry / refuse re-bill |
| BR-BIL-014/021/026 | Multi-table writes | All-or-nothing | Concurrency | Generate / pay | Roll back fully |
| BR-BIL-020 | Invoice.paid | Cumulative, never reduced | Calculation | Record payment | Add only |
| BR-BIL-022 | Audit.event_detail | Whitelist only, no raw data | Security | Record payment | Strip non-whitelisted fields |
| BR-BIL-023 | Invoice.status | Derived from cumulative paid | Workflow | Record payment | Set Partially Paid / Paid |
| BR-BIL-034 | Audit entry | Append-only except note | Workflow | Edit | Refuse edit of event |
| BR-BIL-040 | Gateway callback | Signature-verified | Security | Online payment | Reject forged callback |
| BR-BIL-042 | Portal invoice access | Own school only | Permission | Portal view | Deny cross-school access |

## B.3 Validation & Edge-Case Catalog
| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency | Expected behaviour |
|---|---|---|---|---|---|---|
| Cycle short code (BR-001) | "MONTHLY" | "MONTHLY" duplicate | 50 chars | blank | two saves same code | reject duplicates |
| Months count (BR-002) | 3 | 0 / 300 / "x" | 1 and 255 | blank | — | reject out of range |
| Billing qty (BR-007) | count 80 vs min 50 → 80 | negative count | min=count | count 0 | count read mid-edit | use max; never below min |
| Payment amount (BR-020) | 5000 | -100 / non-numeric | 0 vs net payable | blank | two payments same instant | add to cumulative; never reduce |
| Consolidated allocation (BR-024/025) | total 9000 across 3 | allocation > total | allocation = 0 (skip) | blank allocations | partial failure | skip zero; roll back on failure |
| Invoice number (BR-006) | INV-20260629-001 | duplicate | NNN rollover same day | — | two generations same instant | guarantee uniqueness |
| Audit event detail (BR-022) | whitelisted fields | full raw request | — | empty | — | store whitelist only |
| Generation atomicity (BR-014) | all writes succeed | student read fails | — | missing plan rate | concurrent generate | full rollback; entry stays unbilled |
| Gateway callback (BR-040) | valid signature | missing/forged signature | — | empty body | replay | reject unverified |

---

# Section C — Process Flows & State Machine Catalog

## C.1 Process Flows
See **FRD Section 6** (Workflows 6.1–6.5).

## C.2 State Machine — Invoice
**Entity:** Invoice. Status list is configuration-driven (school/operator may extend).
| From State | Event/Action | Guard | To State | Side-Effects |
|---|---|---|---|---|
| (none) | Generate invoice | schedule unbilled, rate found | Pending | "Generated" audit; schedule marked billed; modules recorded |
| Pending | Record payment | 0 < cumulative paid < net | Partially Paid | payment audit; paid amount increased |
| Pending / Partially Paid | Record payment | cumulative paid ≥ net | Paid | payment audit; paid amount increased |
| Pending / Partially Paid | Due date passes unpaid | paid < net, not cancelled | Overdue | (planned) overdue audit + reminder |
| Pending / Partially Paid | Cancel | manual | Cancelled | (planned — no endpoint today) |
**Terminal states:** Paid, Cancelled. **Illegal transitions (must block):** Paid → Pending; reducing paid amount; editing a posted audit event (note only).

## C.3 State Machine — Scheduled Email
| From | Event | Guard | To | Side-Effects |
|---|---|---|---|---|
| (none) | Schedule email | valid future time | Pending | "Notice Sent" audit |
| Pending | Scheduled time reached | — | Sent | email delivered |
| Pending | Delivery fails (final) | retries exhausted | Failed | *(planned)* mark failed |

---

# Section D — Data Dictionary & Dependency Map

## D.1 Data Dictionary — Business View
See **FRD Section 5** for entity-level business fields.

## D.2 Cross-Module Dependency Map
**Inbound (Billing reads from):**
| Source Module | Data/Entity | Why |
|---|---|---|
| Prime (PRM) | Tenant, tenant plan assignment, plan rate, billing schedule, credit days | Identify school, price invoice, find due entries |
| GlobalMaster (GLB) | Module list; status / mode / payment-status dropdown values | Record covered modules; configurable status lists |
| StudentProfile (STD) | Active student count (inside the school's own database) | Determine billing quantity |
| SchoolSetup (SCH) | Tenant plan model reference | Subscription display |
| SystemConfig (SYS) | Acting user identity; activity log | Audit "performed by"; activity logging |

**Outbound (Billing feeds):**
| Target Module | Mechanism | What |
|---|---|---|
| Prime (PRM) | Shared schedule record | Marks a billing-schedule entry as billed; links generated invoice |
| Notification (future) | Event | School notified on generation/overdue (planned) |
| Analytics (future) | Shared invoice/payment data | Revenue dashboards (planned) |

**External:** Razorpay (planned), email delivery, PDF generation.

---

# Section E — NFR Catalog & Risk Register

## E.1 NFR Catalog
| NFR-ID | Category | Requirement (measurable) | Threshold |
|---|---|---|---|
| NFR-BIL-001 | Performance | Billing dashboard with 1,000+ rows | < 3s |
| NFR-BIL-002 | Performance | Reference (school/user) lists filtered/paged, never loaded wholesale | No unfiltered full-table loads |
| NFR-BIL-003 | Performance | Bulk ZIP for 50+ invoices via background job | No request timeout |
| NFR-BIL-004 | Security | Every action requires its billing permission | 100% of mutating endpoints |
| NFR-BIL-005 | Security | No raw request/gateway data in audit detail | Whitelist enforced |
| NFR-BIL-006 | Security | Gateway callback signature-verified, not session-auth | 100% |
| NFR-BIL-007 | Data Integrity | Multi-table writes atomic with rollback | 100% of generate/pay paths |
| NFR-BIL-008 | Concurrency | Tenant DB connection closed after student count | Always |
| NFR-BIL-009 | Reliability | Email job has retry + failure handling | tries ≥ 3, failed() defined |
| NFR-BIL-010 | Auditability | Every billing action logged; append-only | 100% |
| NFR-BIL-011 | Compliance | Invoices support Indian GST tax lines & GST fields | CGST/SGST/IGST + GSTIN/SAC (planned) |

## E.2 Risk Register
| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|---|
| RISK-BIL-001 | Audit-log column-name mismatch causes audit inserts to fail on a correct database | Data Integrity | H | H | Align model/controller to DDL column; add test | DB Architect / Backend |
| RISK-BIL-002 | Payment posting without rollback leaves an open transaction / inconsistent paid amount on failure | Data Integrity | H | H | Wrap in try/catch with rollback | Backend |
| RISK-BIL-003 | Tenant DB context not closed leaks one school's connection into another's request | Tenancy | M | H | Guarantee close in a finally-style block | Tenancy/Backend |
| RISK-BIL-004 | Unprotected audit-note & payment-detail methods expose/allow edits without permission | Security | M | M | Add permission checks to every method | Backend |
| RISK-BIL-005 | Sensitive raw payment data stored in audit detail | Security/Privacy | M | H | Whitelist fields (BR-BIL-022) | Backend |
| RISK-BIL-006 | Manual generation does not scale with tenant growth | Operational | M | M | Build automated scheduler (REQ-BIL-012) | Product |
| RISK-BIL-007 | No overdue detection → revenue leakage | Financial | M | M | Build overdue job (REQ-BIL-013) | Product |
| RISK-BIL-008 | Triplicated billing route block in central routes file is a maintenance/merge hazard | Maintainability | M | L | Consolidate to one group | Backend |
| RISK-BIL-009 | Synchronous bulk ZIP can time out | Performance | M | M | Queue ZIP generation | Backend |

---

# Section F — Prioritization & Sprint Tasks

## F.1 MoSCoW
- **Must (P0):** REQ-BIL-001, 003, 004, 006.
- **Should (P1):** REQ-BIL-002, 007, 008, 009, 010, 011, 015, 017.
- **Could (P2):** REQ-BIL-005, 012, 013, 014, 016.
- **Won't (this release):** multi-school trust billing (ENH-BIL-005), payment-source tracking (ENH-BIL-012).

## F.2 Effort Estimation & Sprint Task Breakdown
*(Estimates are indicative; defect-fix tasks reference Section I findings.)*
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|---|---|---|---|---|
| 1 | Fix audit-log column-name mismatch (model/relationship/inserts vs DDL) | Backend/Schema | 4 | — | 1 |
| 2 | Wrap individual + consolidated payment posting in try/catch + rollback | Backend | 4 | — | 1 |
| 3 | Whitelist audit event detail; remove raw request data | Backend | 2 | 1 | 1 |
| 4 | Add permission checks to unprotected methods (payment detail, audit notes, gateway-less callbacks) | Backend | 4 | — | 1 |
| 5 | Remove duplicate invoice fillable + non-existent field; clean dead policy classes | Backend | 3 | — | 1 |
| 6 | Consolidate triplicated billing route block to one group; remove dead `view` route or add method | Backend | 3 | — | 1 |
| 7 | Add missing standard columns + indexes + FK via migrations (REQ-BIL data entities) | Schema | 6 | — | 2 |
| 8 | Add email-job retry/backoff/failed() + schedule failed-status update | Backend | 4 | — | 2 |
| 9 | Move bulk ZIP to queued job with ready notification | Backend | 6 | — | 2 |
| 10 | Build automated recurring invoice scheduler (REQ-BIL-012) | Backend | 12 | 1,2 | 3 |
| 11 | Build overdue detection + reminders (REQ-BIL-013) | Backend | 10 | 10 | 3 |
| 12 | Razorpay gateway + signature-verified callback (REQ-BIL-015) | Backend/Integration | 20 | 2 | 4 |
| 13 | Tenant billing portal (REQ-BIL-016) | Full-stack | 24 | 12 | 5 |
| 14 | GST/compliance reporting + GST invoice fields (REQ-BIL-017) | Backend/Frontend | 16 | 7 | 5 |

---

# Section G — User Stories & Reporting/KPI Spec

## G.1 User Stories (P0/P1, Gherkin)

**US-BIL-001 | P0 | REQ-BIL-001**
As a Super Admin, I want to define billing cycles so plans can be priced by frequency.
- Scenario (happy): Given I enter a unique code and 1–255 months, When I save, Then the cycle appears active.
- Scenario (invalid): Given I reuse an existing code, When I save, Then I see a validation error and nothing is saved.
- Scenario (delete guard): Given a cycle used by a plan, When I try to permanently delete it, Then it is refused.
- DoD: validation enforced; activity logged.

**US-BIL-002 | P0 | REQ-BIL-003**
As a Super Admin, I want to generate invoices for due schedule entries so schools are billed correctly.
- Scenario (happy): Given eligible entries, When I generate, Then each invoice has a unique number, correct net payable, due date, and a "Generated" audit entry.
- Scenario (min qty): Given active students below the minimum, When I generate, Then billing quantity equals the minimum.
- Scenario (bill once): Given an already-billed entry, When I generate, Then it is not billed again.
- Scenario (failure): Given the student-count read fails, When I generate, Then nothing is saved and the entry stays unbilled.
- DoD: atomic; tenant connection closed; audit written.

**US-BIL-003 | P0 | REQ-BIL-004**
As a Prime Manager, I want to filter and open invoices so I can review billing status.
- Scenario (happy): Given invoices exist, When I filter by status and date, Then matching invoices are listed and persist the filter.
- Scenario (detail): When I open an invoice, Then all its detail loads inline.
- Scenario (permission): Given a user without billing-view permission, Then access is refused.

**US-BIL-004 | P0 | REQ-BIL-006**
As a Prime Accountant, I want to record a payment so an invoice's balance is current.
- Scenario (happy): Given a Pending invoice, When I record a part payment, Then paid amount increases and status becomes Partially Paid.
- Scenario (full): When cumulative paid reaches net payable, Then status becomes Paid.
- Scenario (failure): Given a save failure, Then no payment, invoice change or audit entry persists.
- DoD: atomic; whitelist-only audit detail.

**US-BIL-005 | P1 | REQ-BIL-007**
As a Prime Accountant, I want to record one consolidated payment across invoices so a single transfer is allocated correctly.
- Scenario (happy): Given a total and allocations, When I post, Then a payment line is created per allocated invoice and balances update.
- Scenario (skip zero): Given a zero allocation, Then no line is created for it.
- Scenario (failure): Given a failure, Then the whole posting rolls back.

**US-BIL-006 | P1 | REQ-BIL-008**
As a Prime Accountant, I want to toggle reconciliation so I can confirm payments against statements.
- Scenario (happy): When I toggle a payment, Then its reconciliation status flips and is logged.
- Scenario (filter): When I filter reconciled-only, Then only reconciled payments show.

**US-BIL-007 | P1 | REQ-BIL-009**
As a Prime Accountant, I want to email/schedule invoices so schools receive them as PDFs.
- Scenario (immediate): When I send, Then emails are queued and a "Notice Sent" entry is recorded.
- Scenario (scheduled): When I schedule, Then it is stored pending and dispatched at the chosen time.

**US-BIL-008 | P1 | REQ-BIL-011**
As a Super Admin, I want a complete audit trail so disputes can be evidenced.
- Scenario (happy): When any billing action occurs, Then an audit entry records who and when.
- Scenario (note): When I add a note, Then it saves without altering the event.
- Scenario (report): When I filter and export, Then an audit PDF is produced.

## G.2 Reporting & KPI Spec
Reports: see **FRD Section 7** (RPT-BIL-001 to 007).
| KPI | Definition (business) | Source | Target | Cadence |
|---|---|---|---|---|
| Collection rate | Total collected ÷ total billed | Invoices, payments | ≥ 95% | Monthly |
| Outstanding amount | Σ (net payable − paid) for unpaid invoices | Invoices | Trend ↓ | Weekly |
| Overdue count | Invoices past due and unpaid | Invoices | Trend ↓ | Daily (planned) |
| Reconciliation lag | Avg days from payment to reconciliation | Payments | < 3 days | Weekly |
| Email delivery success | Sent ÷ attempted | Email schedule | ≥ 99% | Monthly |

---

# Section H — Feature Specification (screen-by-screen)

**Implemented screens (verified live):** Billing Cycle (index/create/edit/show/trash); Billing Management hub (index) with tabbed partials for Invoicing (list/generate/pdf/print/email/schedule), Subscription (view/pdf/print), Invoice Payment (list/print/add-payment), Consolidated Payment (form/pdf/print), Payment Reconciliation (list/pdf/print), Invoice Audit (list/pdf/print, add-note, event-info); plus AJAX detail panels and email-schedule list. Total 43 Blade files.

### Screen: Invoicing Tab (REQ-BIL-003 / REQ-BIL-004)
| # | Field (business label) | Type | Required | Validation | Options Source | Notes |
|---|---|---|---|---|---|---|
| 1 | Data Type | Select | No | — | "To Generate" / "Done" | drives list mode |
| 2 | Status | Select | No | — | active/inactive | schedule status |
| 3 | Invoice Status | Select | No | — | config status list | only when "Done" |
| 4 | School | Select | No | — | tenant list | filter |
| 5 | Date Range | Date range | No | valid range | — | defaults today |
| 6 | Select rows | Checkbox | for actions | ≥1 to act | — | generate/email/PDF |
**Actions:** Generate, Email, Schedule Email, Download PDF (ZIP), View detail. **Empty state:** "No billing entries for the selected filters." **Permissions:** view list / generate / email / pdf.

### Screen: Add Payment (REQ-BIL-006)
| # | Field | Type | Required | Validation | Options | Notes |
|---|---|---|---|---|---|---|
| 1 | Payment Date | Date | Yes | valid date | — | |
| 2 | Amount Paid | Money | Yes | > 0 | — | added cumulatively |
| 3 | Mode | Select | Yes | — | online/bank/cheque/cash | |
| 4 | Mode (other) | Text | No | — | — | when mode=other |
| 5 | Transaction Ref | Text | No | — | — | |
| 6 | Payment Status | Select | Yes | — | success/initiated/failed | |
| 7 | Reconciled? | Toggle | No | — | yes/no | |
| 8 | Remarks | Text | No | — | — | |
**Actions:** Save. **Permissions:** record payment.

### Screen: Consolidated Payment (REQ-BIL-007)
Header: total amount, date, mode, transaction ref. Grid: per outstanding invoice → allocation amount, status. **Rule:** zero allocations skipped. **Permissions:** record payment.

### Screen: Billing Cycle Create/Edit (REQ-BIL-001)
Fields: Short Code (unique), Name, Months Count (1–255), Description, Recurring, Active. **Actions:** Save, Toggle Status, Soft Delete, Restore, Force Delete. **Permissions:** billing-cycle create/update/delete/restore.

---

# Section I — Technical Reconciliation Appendix
*(Technical register — for DB Architect & Technical Auditor. This is the only section that names tables/classes. Findings VERIFIED against live code on 2026-06-29.)*

## I.1 Live inventory (verified)
- Controllers: 7 — `BillingCycleController` (199), `BillingManagementController` (1036, "GOD"), `EmailScheduleController` (61), `InvoicingAuditLogController` (146), `InvoicingController` (69, dead stub — not routed), `InvoicingPaymentController` (328), `SubscriptionController` (154).
- Models: 6 — `BillingCycle`, `BilTenantInvoice`, `BillOrgInvoicingModulesJnt`, `InvoicingPayment`, `InvoicingAuditLog`, `BillTenatEmailSchedule` (class-name typo retained).
- FormRequests: 3 — `BillingCycleRequest`, `ConsolidatedPaymentRequest`, `StoreInvoicePaymentRequest`.
- Policies: 8. Jobs: 1 (`SendInvoiceEmailJob`). Mail: 1 (`InvoiceMail`). Views: 43 Blade. Module migrations: 0. Module `routes/web.php`: empty (foreach over central_domains with empty body — registers nothing). Module `routes/api.php`: empty.
- DDL: `bil_*` tables live in `prime_db_v4.sql` (no standalone module DDL): `bil_tenant_invoices`, `bil_tenant_invoicing_modules_jnt`, `bil_tenant_invoicing_payments`, `bil_tenant_invoicing_audit_logs`, `bil_tenant_email_schedules` + shared `prm_billing_cycles`.

## I.2 CORRECTIONS to prior knowledge / reconnaissance notes
1. **"Route 3× duplication resolved / single central group" — INCORRECT.** Live `routes/web.php` still contains the billing route block **three times** (lines ~311, ~558, ~888), all inside one `Route::domain(config('app.domain'))->name("central.")` group. The whole central body appears triplicated (system-config, scheduler, billing, global-master each repeat 3×) → duplicate route-name registration. The module `routes/web.php` IS empty, so the duplication lives in the central file. **RT-04 persists.**
2. **Policy registration MOVED to `BillingServiceProvider::registerPolicies()` (lines 58–71), not `AppServiceProvider`** — confirmed. Duplicate registrations persist: `BilTenantInvoice` → `BillingManagementPolicy` then `InvoicingPolicy` (last wins); `InvoicingPayment` → `ConsolidatedPaymentPolicy`, `PaymentReconciliationPolicy`, `SubscriptionPolicy`, then `InvoicingPaymentPolicy` (last wins). The three dead policies for `InvoicingPayment` plus `BillingManagementPolicy` are dead code; `ConsolidatedPaymentPolicy` and `PaymentReconciliationPolicy` reference non-existent `App\Models\ConsolidatedPayment` / `App\Models\PaymentReconciliation`.
3. **"Duplicate policy registration silently bypasses ALL authorization" — REFUTED.** `AppServiceProvider` registers a Spatie `Gate::before` hook (line 65). Controller calls use dotted permission strings (`prime.billing-management.create`, etc.) which are **Spatie permissions resolved by `Gate::before`**, NOT policy methods (`viewAny/create/...`). So authorization is NOT silently bypassed by the duplicate registrations; the policies are largely unused/dead. **The real auth gaps are methods with NO `Gate::authorize` call at all** (see I.3). Technical Auditor should confirm the Spatie permission rows exist.

## I.3 CONFIRMED defects (still present)
- **DB-01 / MDL-01 (P0):** DDL column is `tenant_invoice_id` on `bil_tenant_invoicing_audit_logs`, but `InvoicingAuditLog::$fillable`, its `invoice()`/`auditLogs()` relationships, and all controller inserts (`InvoicingPaymentController::store` line ~80, `consolidatedStore` line ~221) use `tenant_invoicing_id`. Audit inserts fail on a correct DB. Also missing model casts `event_info`→array, `action_date`→datetime; model uses SoftDeletes but DDL lacks `deleted_at`/`updated_at`.
- **ERR-01 / ERR-02 (P0):** `InvoicingPaymentController::store()` (begin@52, commit@100) and `consolidatedStore()` (begin@158, commit@247) call `DB::beginTransaction()` with **no try/catch/rollBack**.
- **DB-07 (P0):** `BilTenantInvoice::$fillable` duplicates 8 fields (`paid_amount`, `currency`, `status`, `credit_days`, `payment_due_date`, `is_recurring`, `auto_renew`, `remarks`) and includes `invoice_amount`, which **does not exist** in the DDL (DDL has `sub_total` / `net_payable_amount`).
- **INP-06 (P1):** `InvoicingPaymentController::store()` stores `'request_data' => $request->all()` inside audit `event_info` — violates BR-BIL-022.
- **SEC (auth-missing, P1):** Methods with NO `Gate::authorize`: `InvoicingPaymentController::paymentDetails()`, `downloadConsolidatedPdf()`, `downloadSelectedPdf()`; `InvoicingAuditLogController::auditAddNote()`, `auditAddNoteUpdate()`, `auditEventInfo()`, `downloadAuditNotePdf()`; `SubscriptionController::pricingDetails()`, `billingDetails()`. (`auditAddNoteUpdate` allows note edits without a permission check.)
- **RT-03 (P2):** Route `billing.billing-management.view` → `BillingManagementController@view`, but **no `view()` method exists** → broken route.
- **Resolved since seed:** `subscriptionDetails()`, `invoiceDetails()`, `moduleDetails()`, `printData()`, `sendEmail()`, `scheduleEmail()`, `downloadPDF()` now carry `Gate::authorize`; `index()` now uses `Gate::any([...]) || abort(403)` (functional; minor duplicate ability entry). `store()`/`consolidatedStore()` now use typed FormRequests.

## I.4 Schema correction plan (carried from V2 §5.4, re-validated)
M-05 (P0) fix audit-log FK column name; M-01/02/03/04 (P1) add `created_by`/`deleted_at`/`is_active`/`updated_at` to invoices, payments, modules-jnt, audit-logs; M-06/07 (P2) add indexes on `action_date` and payments `tenant_invoice_id`; M-08 (P2) modules-jnt standard columns; M-09/10 (P2) email-schedules standard columns + FK on `invoice_id`.

---

## Document Control
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-29 | Initial Complete Analysis Pack (FRD + RTM + BR/Conditions/Validation + Flows/FSM + Data Dict/Dependencies + NFR/Risk + Prioritization/Sprint + Stories/KPI + Feature Spec + Technical Reconciliation). Live-code verified. | Business Analysis — Prime-AI |

*This document is the single source of truth for Billing (BIL) requirements. REQ-/BR-/RPT-/ENH- IDs are stable and reused by downstream gap analyses — do not renumber.*
