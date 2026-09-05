# Prime-AI Accounting Module — Business Requirements Document (BRD)

**Document ID:** ACC-BRD-V2
**Version:** 2.0
**Supersedes:** `Accounting_BRD_v1.md` (v1.0)
**Application:** Prime-AI — Accounting Module (tenant-scoped)
**Perspective:** Business Analyst
**Reference Benchmark:** Tally.ERP 9 / TallyPrime
**Status:** Draft for Business Sign-off
**Date:** 2026-09-05

---

## 0. Document Control

### 0.1 Related Documents

| Document | Version | Role |
|---|---|---|
| `Accounting_BRD_v1.md` | 1.0 | Predecessor |
| `Accounting_BRD_v2.md` | 2.0 | **This document** — authoritative business requirement |
| `Solution_Design_v1.md` | 1.0 | Functional + technical solution derived from this BRD |
| `Accounting_DDL_v4.4.sql` | 4.4 | Physical schema derived from the solution design |
| `ScreenDesign_v2.1.md` | 2.1 | Voucher-entry screen specification (already aligned to this BRD) |

### 0.2 What Changed From v1, and Why

v1 is a thorough Tally parity study — 130 sections, and genuinely good as a checklist of what a general-purpose accounting system does. It has three structural problems, and v2 fixes them.

| # | Change | Reason |
|---|---|---|
| C-01 | **The module is now specified as a school's accounting system, not a generic trader's.** New §5 (School Accounting Context), and every voucher type, party type and report re-expressed in school terms | v1 never mentions a student, a fee, a concession, a grant or a trust. But Prime-AI is a K-12 school platform, its parties are students/parents/vendors/employees, and its largest transaction stream by far is fee demand and fee collection. A BRD that does not say so cannot be built from |
| C-02 | **Added Fund Accounting** (§25) — restricted vs unrestricted funds, corpus, grants, donations | A school trust or society must report how restricted money was used. This is not optional for them, and v1 has no concept of it |
| C-03 | **Added Fee Receivable and Concession accounting** (§23, §24) as first-class requirements | The single highest-volume accounting flow in the product, entirely absent from v1 |
| C-04 | **Scoped the tax requirement to what actually applies** (§45–§49) | v1 carries the full Tally India surface — GST, TDS, TCS, VAT, CST, Service Tax, Excise. Most school income is GST-exempt; excise and CST are dead regimes. Building all of it is waste; building none of it fails TDS and the taxable ancillary services. §45 states which applies and when |
| C-05 | **Every business rule now carries an acceptance criterion** | v1's rules ("should support", "must be appropriate") are not testable, so they cannot be signed off or verified |
| C-06 | **Added a Glossary** (§4) fixing one meaning per term | v1 uses "voucher", "bill", "reference", "period", "posting", "optional" and "provisional" with more than one meaning |
| C-07 | **Replaced v1 §128's 50 open questions with an answered Decisions Register** (§60) | The business cannot sign off a document that ends in 50 questions. Each now carries a recommended answer |
| C-08 | **Added the posting model as an explicit business rule set** (§14) — what "posted" means, what it locks, and what may still change | v1 §112 lists workflow states but never says what each state guarantees. This is the single most consequential omission for the build |
| C-09 | **Added measurable KPIs and phased delivery** (§61, §63) | v1 has no definition of done and no priority order across 130 sections of scope |
| C-10 | **Added the integration contract** (§52) — what Accounting owns vs what the source module owns | v1 §84–§87 describe integration as intent. The DDL has already built an event engine against an unstated contract |
| C-11 | **Enhancements** section (§64) | Requested |

### 0.3 Reading Guide

- **§1–§8** — purpose, context, school model, scope. Read first.
- **§9–§57** — the requirements. Each is: *Business need → Business rules (BR-*) → Acceptance criteria (AC-*)*.
- **§58–§59** — the non-negotiable rules and the lifecycles they protect.
- **§60** — decisions to confirm; each already carries a recommendation.
- **§64** — proposed additional capabilities.

---

## 1. Purpose

This document defines **what the business needs from the Prime-AI Accounting Module, and why**.

The Accounting Module is the financial record of a school. It must maintain a complete, balanced, auditable set of books; track what every student owes and every vendor is owed; manage cash, bank and cheques; account for restricted funds; meet the school's statutory obligations; produce financial statements a trustee or auditor will accept; and give the management the information it needs to run the institution.

This document does **not** define database tables, keys, frameworks, APIs or screens. Those belong to `Solution_Design_v1.md`, `Accounting_DDL_v4.4.sql` and `ScreenDesign_v2.1.md`.

Where v1 said "the business needs X", v2 also says **how the business will know it got X**.

---

## 2. Business Context

Prime-AI is a multi-tenant school management platform. Each school (tenant) keeps its own books. The Accounting Module sits at the end of almost every other module's business process:

```
   Fees ──┐
 Library ─┤
Transport ┤
  Hostel ─┼──► an accountable financial event ──► ACCOUNTING ──► Books, Statements, Compliance
 Payroll ─┤
  Vendor ─┤
Inventory ┘
```

The module supports the full lifecycle:

**Business event → Accounting classification → Voucher → Posting → Receivable/Payable → Cash & Bank → Reconciliation → Tax → Period close → Financial statements → Management analysis → Audit**

Two things distinguish this from a generic accounting package, and both drive real requirements:

1. **Most transactions are not typed by an accountant.** They arrive from other modules — a fee receipt, a library fine, a transport charge, a payroll run. The accounting module must accept them, classify them, and remain reconcilable with the module that produced them.
2. **The organisation is usually a trust or society, not a trading company.** It has restricted funds, donors, grants, and an obligation to report how restricted money was spent. Its income is largely exempt from GST. Its statutory exposure is concentrated in TDS and in maintaining books that satisfy a charitable-institution audit.

---

## 3. Business Problems to Be Solved

| # | Problem | Consequence today |
|---|---|---|
| P-01 | Fee dues are tracked in the Fees module and money in the bank, with nothing reconciling them | Nobody can prove the fee receivable figure |
| P-02 | Receipts are recorded but not allocated to specific demands | "How much does this student owe, for what?" is answered by hand |
| P-03 | Vendor bills and payments are tracked outside the books | Payables are unknown until someone asks |
| P-04 | Bank statements are reconciled in a spreadsheet, if at all | Cash position is a guess; errors surface months later |
| P-05 | Restricted grants and donations are mixed with general funds | The school cannot show a donor how their money was used |
| P-06 | Concessions and scholarships are netted off invisibly | Neither the true fee income nor the true concession cost is known |
| P-07 | TDS is deducted manually and remembered by one person | Late deposits, interest, penalty |
| P-08 | Financial statements are prepared once a year by an external accountant from raw data | Management flies blind for eleven months |
| P-09 | There is no audit trail of who changed what | An auditor cannot rely on the books |
| P-10 | Period-end has no defined close, so figures keep moving after they are reported | Reported numbers are not reproducible |
| P-11 | Corrections are made by editing the original entry | The error is concealed rather than corrected |
| P-12 | Duplicate payments and duplicate bills are found only by luck | Direct financial loss |

---

## 4. Glossary — Canonical Vocabulary

This glossary is **binding**. Where any later document, screen, report or table uses one of these words, it uses it with this meaning only.

| Term | Definition |
|---|---|
| **Voucher** | One accounting transaction as a business document: a header plus two or more Dr/Cr lines that balance. The unit of entry, approval, posting and audit |
| **Voucher Type** | The classification of a voucher — Receipt, Payment, Contra, Journal, Sales, Purchase, Credit Note, Debit Note, Memorandum — which determines its behaviour, numbering and permitted accounts |
| **Voucher Line (Item)** | One Dr or Cr posting within a voucher, against exactly one ledger |
| **Posting** | The act that makes a voucher part of the books. Before posting, a voucher affects nothing. After posting, it affects every balance and report, and may no longer be edited |
| **Ledger** | An individual account head — Cash, HDFC Bank, a named student, a named vendor, Tuition Fee Income, Salary Expense |
| **Account Group** | The classification a ledger belongs to, forming the Chart of Accounts hierarchy. Determines which financial statement the ledger appears in |
| **Nature** | The fundamental class of an account group: Asset, Liability, Equity, Income or Expense |
| **Party Ledger** | A ledger representing someone the school transacts with: a student, a parent, a vendor, an employee, a donor |
| **Bill Reference** | A named, dated, tracked obligation within a party ledger — a fee demand, a vendor invoice, an advance. The unit of outstanding tracking |
| **Bill Allocation** | The linking of a receipt or payment to one or more bill references, in stated amounts |
| **On Account** | Money received or paid that has deliberately not been allocated to any bill reference |
| **Advance** | Money received or paid before the corresponding demand or bill exists |
| **Cost Centre** | A management-accounting dimension a transaction is attributed to — a wing, a class, a department, an activity, a project, a campus |
| **Cost Category** | An independent family of cost centres, so the same amount can be analysed on more than one axis at once |
| **Fund** | A pool of money whose use is restricted by its donor, grantor or by the trust deed. Distinct from a cost centre: a cost centre says *where the money went*, a fund says *whose money it was* |
| **Financial Year** | The statutory accounting year (1 April – 31 March in India). Distinct from the Academic Session |
| **Academic Session** | The school year, which may not coincide with the financial year. A reporting dimension, never the basis of statutory accounts |
| **Accounting Period** | A subdivision of a financial year — normally a month — that can be independently closed |
| **Closed Period** | A period in which no voucher may be created, edited, posted or cancelled without an authorised reopening |
| **Opening Balance** | The balance of a ledger at the start of a financial year, carried from the prior year or entered at go-live |
| **Provisional (Optional) Voucher** | A voucher deliberately recorded but excluded from the books — an estimate, a scenario, a draft awaiting evidence. Never included in a financial statement |
| **Post-dated Voucher** | A voucher whose effective date is in the future. Excluded from the books until that date arrives |
| **Reversal** | A new voucher that exactly negates a posted voucher. The mechanism for correcting a posted error |
| **Cancellation** | Marking a posted voucher void. The voucher and its number remain visible; its amounts stop counting |
| **Reconciliation** | Matching the school's bank book against the bank's statement, and explaining every difference |
| **Concession** | A reduction of a fee demand granted by the school — scholarship, sibling discount, staff ward, hardship waiver |
| **Write-off** | An authorised decision that an outstanding amount will never be collected or paid |
| **Suspense** | A temporary holding account for a transaction whose correct classification is not yet known |
| **Maker / Checker** | The person who creates a transaction, and the different person who approves it |
| **Audit Trail** | The immutable record of who did what, when, to which record, from what value to what value |

---

## 5. School Accounting Context

This section is new in v2 and governs the interpretation of everything that follows.

### 5.1 The organisation

| Attribute | Typical value | Consequence |
|---|---|---|
| Legal form | Trust, Society or Section 8 Company | Fund accounting required; "profit" is *surplus*; capital is *corpus* |
| Financial year | 1 April – 31 March | Fixed; not user-choosable in India |
| Academic session | April–March or June–May | May not equal the financial year — see BR-SESSION-01 |
| Campuses | One, sometimes several | Multi-unit accounting and consolidation |
| Income tax | Usually exempt under s.12A/12AB | Requires 80G receipt numbering and Form 10B-grade books |
| GST | Core education is **exempt**; ancillary supplies to non-students may be taxable | Selective, not blanket, GST |
| TDS | Applies to salary, contractor, rent, professional fees | Genuinely required |
| Audit | Annual statutory audit by a chartered accountant | Audit trail and period lock are hard requirements |

### 5.2 Voucher types in school language

| Voucher Type | School meaning |
|---|---|
| **Sales** | Fee demand / invoice raised on a student or parent; hostel, transport or service billing |
| **Receipt** | Fee collection, donation, grant receipt, hostel/transport receipt, refund received |
| **Payment** | Salary payout, vendor payment, utility bill, statutory deposit, refund issued |
| **Contra** | Cash deposit to bank, bank-to-bank transfer, petty cash draw |
| **Journal** | Fee accrual, depreciation, concession/scholarship charge, provision, year-end adjustment |
| **Purchase** | Vendor bill for books, uniforms, lab equipment, services |
| **Credit Note** | Fee concession, waiver, cancelled fee demand, sales return |
| **Debit Note** | Goods returned to a vendor, vendor short-billing adjustment |
| **Memorandum** | Provisional or draft entry pending evidence or approval |

### 5.3 Party types

| Party | Ledger created | Typical balance | Bill-wise |
|---|---|---|---|
| Student | Automatically, on admission | Debit (owes fees) | Mandatory |
| Parent/Guardian | Where billing is to the guardian rather than the student | Debit | Mandatory |
| Vendor / Supplier | On vendor registration | Credit (school owes) | Mandatory |
| Employee | On joining | Credit (salary payable), Debit (advances) | Optional |
| Donor | On first donation | Usually nil-balance | Optional |
| Grantor / Government body | On grant sanction | Debit (grant receivable) | Mandatory |

### 5.4 Business rules

**BR-SCHOOL-01:** The financial year is the sole basis of statutory accounting. The academic session is a reporting dimension only and must never determine which period a transaction belongs to.

**BR-SCHOOL-02:** A student ledger must be created automatically on admission and must never be deleted, only deactivated, because it carries financial history.

**BR-SCHOOL-03:** The accounting module must be able to state the fee receivable of any student, class, section, wing or campus at any date, and that figure must reconcile with the Fees module.

**BR-SCHOOL-04:** A concession is an expense or an income reduction consciously granted — never a silent reduction of the demand. The gross fee and the concession must both be visible.

**BR-SCHOOL-05:** Where the school operates several campuses, every transaction must be attributable to one, and both campus-level and consolidated statements must be producible.

**Acceptance criteria**

- **AC-SCHOOL-01** Fee receivable per the Accounting Module equals fee receivable per the Fees module, at any date, or the difference is itemised.
- **AC-SCHOOL-02** Gross fee income, total concession, and net fee income are separately reportable for any period.
- **AC-SCHOOL-03** A student's complete financial history survives their leaving the school.

---

## 6. Business Objectives

| ID | Objective | Measure of achievement |
|---|---|---|
| **BR-OBJ-01** | Accurate bookkeeping | Trial Balance balances at every date; no posted voucher is unbalanced |
| **BR-OBJ-02** | Complete financial visibility | Assets, liabilities, corpus, income, expenditure, receivables, payables, cash, bank, funds and tax positions are all reportable at any date |
| **BR-OBJ-03** | Reliable financial statements | Balance Sheet, Income & Expenditure and Trial Balance are produced from posted vouchers alone, and reconcile with each other |
| **BR-OBJ-04** | Receivable and payable control | Every outstanding amount is attributable to a named party and a named bill reference |
| **BR-OBJ-05** | Banking control | Every bank ledger is reconciled monthly, and every unreconciled item is explained |
| **BR-OBJ-06** | Statutory compliance support | TDS, and where applicable GST, are computed, tracked, deposited and reconciled from the books |
| **BR-OBJ-07** | Management accounting | Cost, surplus and utilisation are reportable by wing, department, activity, campus and fund |
| **BR-OBJ-08** | Auditability | Every posted transaction and every master change is traceable to a person, a time and a reason |
| **BR-OBJ-09** | Controlled accounting | Creation, approval, posting, cancellation, reversal and period reopening are separately permissioned |
| **BR-OBJ-10** | Historical integrity | A statement produced today for a closed period returns exactly what it returned when the period was closed |
| **BR-OBJ-11** | Fund accountability | The school can show, per fund, what was received, what was spent, and what remains |
| **BR-OBJ-12** | Integration integrity | Every financial event originating in another module is recorded exactly once, and is reconcilable with its source |
| **BR-OBJ-13** | Timeliness | Books are closed monthly, not annually |
| **BR-OBJ-14** | Explainability | Every figure in every report is drillable to the vouchers behind it |

---

## 7. Users

| Role | Responsibility | Key permissions |
|---|---|---|
| **Accounts Clerk** | Day-to-day entry | Create and edit own drafts. Cannot post, approve or cancel |
| **Accountant** | Owns the books | Create, edit drafts, post, reconcile, run period-end. Cannot approve own high-value vouchers |
| **Accounts Manager / Head** | Controls and approves | Approve, cancel, reverse, write off, close a period |
| **Principal** | Institutional oversight | View everything, approve high-value payments. No entry |
| **Trustee / Management** | Governance | Financial statements, fund utilisation, dashboards. Read only |
| **Auditor (internal or external)** | Independent review | Read everything including the audit trail; add review notes. No modification of any kind |
| **School Admin** | Configuration | Masters, voucher types, numbering, approval policy |
| **Super Admin / PG Support** | Platform | Configuration and support. Support may not approve or post |
| **System** | Automated posting | Cross-module events, recurring vouchers, depreciation. Always identified as a system actor |

**BR-USER-01:** Every accounting action is attributable to a named person or to an identified system process. "Unknown" is never an acceptable actor.

**BR-USER-02:** A user who creates a voucher may not approve it, where the approval policy requires independent approval.

**BR-USER-03:** Auditor access is read-only by construction, not by convention — the role must be incapable of modifying a financial record.

---

## 8. Scope

### 8.1 In scope

| ID | Capability | Phase |
|---|---|---|
| C-01 | Chart of accounts: groups and ledgers | 1 |
| C-02 | Financial years and accounting periods | 1 |
| C-03 | Voucher types, numbering and configuration | 1 |
| C-04 | Voucher entry — all nine types | 1 |
| C-05 | Double-entry posting engine and balance derivation | 1 |
| C-06 | Opening balances | 1 |
| C-07 | Party ledgers: students, vendors, employees, donors | 1 |
| C-08 | Bill-wise tracking and allocation | 1 |
| C-09 | Trial Balance, Balance Sheet, Income & Expenditure | 1 |
| C-10 | Day Book, ledger statements, registers | 1 |
| C-11 | Audit trail | 1 |
| C-12 | Role-based access and permissions | 1 |
| C-13 | Cash and bank management | 2 |
| C-14 | Cheque lifecycle | 2 |
| C-15 | Bank statement import and reconciliation | 2 |
| C-16 | Receivables, payables and ageing | 2 |
| C-17 | Cost centres and cost categories | 2 |
| C-18 | Approval workflow and maker-checker | 2 |
| C-19 | Cancellation and reversal | 2 |
| C-20 | Period close and year-end carry forward | 2 |
| C-21 | Cross-module event posting | 2 |
| C-22 | Fee receivable and concession accounting | 2 |
| C-23 | Fund accounting | 3 |
| C-24 | TDS | 3 |
| C-25 | GST, where applicable | 3 |
| C-26 | Fixed assets and depreciation | 3 |
| C-27 | Budgets and variance | 3 |
| C-28 | Recurring vouchers | 3 |
| C-29 | Expense claims | 3 |
| C-30 | Cash flow, fund flow, ratios | 3 |
| C-31 | Exception and risk reporting | 3 |
| C-32 | Interest calculation | 4 |
| C-33 | Credit limits | 4 |
| C-34 | Multi-currency | 4 |
| C-35 | Multi-campus and consolidation | 4 |
| C-36 | Scenarios and cash-flow projection | 4 |
| C-37 | Payment advice and e-payment files | 4 |
| C-38 | Tally export/import | 4 |
| C-39 | AI-assisted analysis | 4 |

### 8.2 Out of scope

- Inventory valuation and stock vouchers (the Inventory module owns stock; Accounting records only its financial effect).
- Order processing — sales orders and purchase orders.
- Payroll computation (the Payroll module computes; Accounting records the financial effect).
- Dead statutory regimes: VAT, CST, Service Tax, Excise. Not built. Not migrated.
- POS vouchers.
- Statutory return *filing*. The module prepares and reconciles return data; filing happens on the government portal.
- Any technical design decision.

### 8.3 Scope boundary rule

**BR-SCOPE-01:** Accounting records the financial consequence of a business event. It never becomes the authority on the event itself. Where Accounting and a source module disagree, the module reports a reconciliation difference rather than overwriting either side.

---

## 9. Financial Year and Accounting Period

**BR-PERIOD-01:** Every voucher has exactly one accounting date, and that date alone determines its financial year and accounting period.

**BR-PERIOD-02:** A financial year runs from 1 April to 31 March and is subdivided into twelve monthly accounting periods.

**BR-PERIOD-03:** Exactly one financial year is *current* at any time. More than one may be *open*, to permit prior-year adjustments before finalisation.

**BR-PERIOD-04:** A period may be **Open**, **Soft-Closed** (entry blocked, adjustments permitted with approval) or **Hard-Closed** (nothing may change).

**BR-PERIOD-05:** No voucher may be created, edited, posted, cancelled or reversed in a hard-closed period. Reopening requires an authorised act, and both the reopening and every subsequent change are recorded.

**BR-PERIOD-06:** Closing a period must be blocked while any voucher in it is unposted, unapproved, or in suspense.

**BR-PERIOD-07:** Year-end closing preserves the prior year completely and creates the next year's opening balances as an identifiable, traceable act.

**BR-PERIOD-08:** Back-dating a voucher into an open but earlier period requires a specific permission, and is recorded.

**Acceptance criteria**

- **AC-PERIOD-01** A Trial Balance run today for a hard-closed period returns identical figures to the one run on the day it was closed.
- **AC-PERIOD-02** Attempting to post into a closed period is refused with the period and its status named.
- **AC-PERIOD-03** A reopened period shows who reopened it, when, why, and every change made since.

---

## 10. Chart of Accounts — Groups

**BR-GROUP-01:** Every group has exactly one nature: Asset, Liability, Equity, Income or Expense. The nature determines which statement the group's ledgers appear in and may never be changed once transactions exist beneath it.

**BR-GROUP-02:** Groups form a hierarchy of unlimited depth. A group's effective nature is inherited from its root.

**BR-GROUP-03:** System-defined groups may not be deleted or have their nature changed.

**BR-GROUP-04:** A group may not be its own ancestor.

**BR-GROUP-05:** Reclassifying a ledger to a different group applies prospectively for reporting; historical statements for closed periods remain as issued.

**BR-GROUP-06:** The default chart must be a school chart — Corpus Fund, Restricted Funds, Fee Income, Grant Income, Donation Income, Establishment Expenses, Academic Expenses, and so on — not a trading chart.

**Acceptance criteria**

- **AC-GROUP-01** Changing a group's nature is refused when any posted voucher exists under it.
- **AC-GROUP-02** The Balance Sheet and Income & Expenditure between them account for every ledger exactly once.

---

## 11. Ledger Accounts

**BR-LEDGER-01:** Every ledger belongs to exactly one group and has a unique name.

**BR-LEDGER-02:** A ledger's balance is **derived from its posted transactions plus its opening balance**. It is never an independently maintained figure that could disagree with them.

**BR-LEDGER-03:** A ledger with any posted transaction may never be deleted, only deactivated.

**BR-LEDGER-04:** A ledger declares its behavioural traits: is it a bank account, a cash account, a party account, a tax account, reconcilable, bill-wise tracked, cost-centre applicable, interest applicable.

**BR-LEDGER-05:** A party ledger is linked to the master record it represents — student, vendor, employee, donor — and that link is one-to-one.

**BR-LEDGER-06:** Bank ledgers carry the bank identification required to reconcile and to pay: bank name, branch, account number, IFSC, account type.

**BR-LEDGER-07:** Deactivating a ledger prevents new postings and preserves every historical one.

**Acceptance criteria**

- **AC-LEDGER-01** A ledger's displayed balance always equals the sum of its posted lines plus its opening balance. A rebuild of derived balances changes nothing.
- **AC-LEDGER-02** Deleting a ledger with history is refused, naming the transactions.

---

## 12. Opening Balances

**BR-OPEN-01:** Opening balances are identifiable as such and are never mixed with transactions of the year.

**BR-OPEN-02:** The set of opening balances must balance: total debits equal total credits. An unbalanced set may be saved as draft but never finalised.

**BR-OPEN-03:** Party opening balances must be entered bill-wise where the party is bill-wise tracked, so that day-one ageing is correct.

**BR-OPEN-04:** Once a financial year is finalised, its opening balances may be changed only by an authorised correction, which is recorded.

**Acceptance criteria**

- **AC-OPEN-01** A go-live Trial Balance consisting only of opening balances balances to zero.
- **AC-OPEN-02** An opening receivable of ₹40,000 across three demands ages correctly from each demand's own date.

---

## 13. Vouchers

**BR-VOUCHER-01:** A voucher has a type, a number, a date, a financial year, a narration, and two or more lines.

**BR-VOUCHER-02:** The sum of debits equals the sum of credits, to the last paisa, in every voucher that is posted.

**BR-VOUCHER-03:** A voucher line posts to exactly one ledger, for one amount, on one side.

**BR-VOUCHER-04:** A voucher must have at least one debit line and at least one credit line.

**BR-VOUCHER-05:** Line order is preserved as entered.

**BR-VOUCHER-06:** A voucher carries the business context that explains it: the source module and record where it came from, the party, the instrument, the bill references, the cost centres, the fund.

**BR-VOUCHER-07:** Zero-value vouchers are refused unless the voucher type explicitly permits them.

**BR-VOUCHER-08:** A voucher may reference the voucher it adjusts, corrects or reverses.

**Acceptance criteria**

- **AC-VOUCHER-01** Posting an unbalanced voucher is impossible; the difference is displayed on entry.
- **AC-VOUCHER-02** A voucher reopened after a month displays its lines in the order they were entered.

---

## 14. The Posting Model

This section is new in v2. It is the most important set of rules in the document, because every other guarantee depends on it.

**BR-POST-01:** A voucher exists in exactly one state: **Draft**, **Pending Approval**, **Posted**, **Cancelled** or **Reversed**.

**BR-POST-02:** Only a **Posted** voucher affects any balance, any statement, any outstanding figure, any tax computation or any report. A Draft voucher affects nothing at all.

**BR-POST-03:** Posting is a single, atomic, irreversible act. A voucher is posted in full or not at all.

**BR-POST-04:** A posted voucher may never be edited. It may only be cancelled or reversed, and either act is itself recorded.

**BR-POST-05:** Posting is refused unless: the voucher balances; every ledger is active; the date falls in an open period; the numbering is valid; required approvals are present; and every type-specific rule is satisfied.

**BR-POST-06:** The voucher number of a posted voucher is permanent.

**BR-POST-07:** Cancellation voids the amounts while retaining the voucher, its number, its lines and its history. A cancelled voucher appears in the Day Book marked cancelled, and in no balance.

**BR-POST-08:** Reversal creates a new, separate, posted voucher that exactly negates the original. Both remain visible. This is the only correct way to fix a posted error in a closed period.

**BR-POST-09:** A provisional (memorandum) voucher and a post-dated voucher are never posted to the books until they are, respectively, confirmed and due. They are reportable separately at all times.

**BR-POST-10:** System-posted vouchers follow every rule in this section. Automation is not an exemption.

**Acceptance criteria**

- **AC-POST-01** A Draft voucher for ₹1,00,000 changes no ledger balance, no Trial Balance and no outstanding figure.
- **AC-POST-02** Editing a posted voucher is impossible through every route, including the API.
- **AC-POST-03** A cancelled voucher's number is never reissued.
- **AC-POST-04** A reversal displays alongside its original, and the pair nets to zero.

---

## 15. Voucher Numbering

**BR-VNO-01:** Each voucher type has its own numbering series, per financial year.

**BR-VNO-02:** A number is assigned at posting, not at draft creation, so that drafts abandoned do not consume numbers.

**BR-VNO-03:** A posted series must be gapless within its financial year. A gap must be explainable — a cancelled voucher retains its number.

**BR-VNO-04:** Two vouchers of the same type may never share a number within a financial year, under any concurrency.

**BR-VNO-05:** Numbering configuration — prefix, suffix, width, restart policy — is set per voucher type and may not be changed once the series has begun in that year.

**BR-VNO-06:** Manual numbering is permitted only where the voucher type allows it, and uniqueness is still enforced.

**Acceptance criteria**

- **AC-VNO-01** Two users posting the same voucher type simultaneously receive consecutive distinct numbers; neither fails.
- **AC-VNO-02** A gap-detection report lists every missing number in every series with its explanation.

---

## 16. Voucher Types and Their Rules

Each type carries rules beyond the general ones.

| Type | Additional rules |
|---|---|
| **Receipt** | Must debit a cash, bank or clearing ledger. Party lines must be bill-allocated or explicitly On Account |
| **Payment** | Must credit a cash, bank or clearing ledger. Must warn, or block per policy, on negative cash. Bank lines require instrument details |
| **Contra** | Every line is a cash or bank ledger. May not touch income or expenditure |
| **Journal** | May not touch cash or bank ledgers. Requires a narration. High-value journals require approval |
| **Sales (Fee Demand / Invoice)** | Requires a party. Creates a bill reference. Recognises income and any tax |
| **Purchase** | Requires a party. Creates a bill reference. Recognises expenditure or asset and any input tax and TDS |
| **Credit Note** | Requires a reason and, where applicable, the original invoice. Reduces a receivable |
| **Debit Note** | Requires a reason and, where applicable, the original bill. Reduces a payable |
| **Memorandum** | Never posts to the books. Always reportable separately |

**BR-VTYPE-01:** A voucher type's permitted and forbidden account classes are configuration, enforced at posting.

**BR-VTYPE-02:** System voucher types may not be deleted, and their fundamental behaviour may not be changed.

**BR-VTYPE-03:** Using a voucher type to bypass a control — a Journal to move cash, for instance — must be prevented by the rules above, not by convention.

**Acceptance criteria**

- **AC-VTYPE-01** A Journal touching a bank ledger is refused at posting.
- **AC-VTYPE-02** A Contra affecting an income ledger is refused.

---

## 17. Bill-Wise Accounting

v1 required this (§14). It is restated here with the precision the build needs.

**BR-BILL-01:** A bill reference is a named, dated obligation within one party ledger, created by a Sales voucher, a Purchase voucher, an opening balance, or explicitly as a New Reference.

**BR-BILL-02:** A bill reference has an original amount, a due date, and a derived outstanding amount.

**BR-BILL-03:** Every receipt or payment line against a bill-wise party must be allocated: to one or more existing references (**Against Reference**), to a new reference (**New Reference**), as an **Advance**, or explicitly **On Account**.

**BR-BILL-04:** The total allocated on a line must equal that line's amount. No remainder may be left implicit.

**BR-BILL-05:** One payment may settle many bills; one bill may be settled by many payments. Partial settlement is normal.

**BR-BILL-06:** A bill reference's outstanding amount is **derived** from its allocations. It is never independently stored in a way that could disagree.

**BR-BILL-07:** Outstanding must never go negative. Over-allocation is refused.

**BR-BILL-08:** Cancelling or reversing a voucher releases its allocations and restores the affected outstandings.

**BR-BILL-09:** The sum of a party's open bill outstandings must equal that party's ledger balance. Any divergence is a defect, and the module must be able to report it.

**Acceptance criteria**

- **AC-BILL-01** A ₹45,000 receipt allocated ₹40,000 / ₹5,000 across two demands leaves both closed and the ledger balance reduced by exactly ₹45,000.
- **AC-BILL-02** Allocating ₹50,000 against a ₹40,000 outstanding is refused.
- **AC-BILL-03** A "party ledger balance vs bill outstanding" reconciliation report returns zero differences.

---

## 18. Cost Centres and Cost Categories

**BR-CC-01:** A cost centre is a management dimension and never alters the financial classification of a transaction.

**BR-CC-02:** A voucher line may be allocated across several cost centres, by amount or percentage.

**BR-CC-03:** Where cost-centre allocation is required for a ledger, the allocated total must equal the line amount.

**BR-CC-04:** Cost categories permit independent, simultaneous analysis — the same salary analysed by wing and by department at once. Allocation within each category must total the line amount independently.

**BR-CC-05:** Cost-centre reports must reconcile to the underlying ledger totals.

**BR-CC-06:** Predefined allocation rules may pre-fill an allocation. The user may review and override where policy permits, and the override is recorded.

**Acceptance criteria**

- **AC-CC-01** The sum of a period's cost-centre expenditure equals that period's total expenditure, for every category.
- **AC-CC-02** A ₹1,00,000 salary split 60/40 across two wings appears in full in both the wing reports and the P&L, without double counting.

---

## 19. Cash and Bank

**BR-CASH-01:** Cash and bank balances are derived from posted vouchers.

**BR-CASH-02:** Negative cash must be preventable by configuration, and always detectable by report.

**BR-BANK-01:** Every bank ledger is separately identified and separately reconciled.

**BR-BANK-02:** A payment or receipt through a bank captures its instrument: mode, number, date, and the party favoured.

**BR-BANK-03:** Petty cash is a distinct cash ledger with its own custodian and its own limit.

**Acceptance criteria**

- **AC-CASH-01** With negative-cash blocking enabled, a payment exceeding cash on hand is refused, stating the balance.
- **AC-BANK-01** Every bank ledger reports its book balance, reconciled balance and unreconciled difference at any date.

---

## 20. Cheque Management

**BR-CHEQUE-01:** A cheque has a lifecycle, and its current stage is always known: Issued, Presented, Cleared, Bounced, Stopped, Cancelled, Stale.

**BR-CHEQUE-02:** Issued and received cheques are distinguishable and separately reportable.

**BR-CHEQUE-03:** A post-dated cheque does not affect the bank balance until its date.

**BR-CHEQUE-04:** A bounced cheque reverses the settlement, restores the outstanding, and is recorded as a bounce — with any charge accounted separately.

**BR-CHEQUE-05:** Cheque-book stock and used leaves are trackable, so a missing leaf is detectable.

**BR-CHEQUE-06:** A cancelled or stopped cheque retains its history.

**Acceptance criteria**

- **AC-CHEQUE-01** A bounced fee cheque restores the student's outstanding to its pre-receipt value, and the bank charge appears as an expense.
- **AC-CHEQUE-02** Cheques uncleared beyond three months appear on a stale-cheque report.

---

## 21. Bank Reconciliation

**BR-BRS-01:** Every bank ledger transaction carries a reconciliation state and, once reconciled, the bank's own value date.

**BR-BRS-02:** A bank statement may be imported. Imported rows are staging data and affect no balance until matched.

**BR-BRS-03:** The module proposes matches; a person confirms them. An automatic match is never final without confirmation, unless the school has explicitly enabled auto-confirmation for exact matches.

**BR-BRS-04:** A reconciliation difference is explained, never silently adjusted. Creating an adjusting voucher is a separate, deliberate, recorded act.

**BR-BRS-05:** A confirmed match may be undone, and the undo is recorded.

**BR-BRS-06:** A reconciliation statement must at all times show: balance as per books, add/less unpresented and uncredited items, and balance as per bank — and the last must equal the statement.

**BR-BRS-07:** Importing the same statement twice must not create duplicate rows.

**Acceptance criteria**

- **AC-BRS-01** The reconciliation statement's closing figure equals the bank statement's closing balance, or the residual difference is itemised line by line.
- **AC-BRS-02** Re-importing an identical statement file adds nothing.

---

## 22. Receivables and Payables

**BR-AR-01:** Receivables and payables are reportable in total, by party, by bill, by due date and by age.

**BR-AR-02:** Ageing buckets are configurable and are computed from the due date by default, from the bill date optionally.

**BR-AR-03:** Ageing must reconcile with the control account balance.

**BR-AR-04:** Advances and On Account amounts are shown distinctly from allocated settlements, and never netted silently against unrelated bills.

**BR-AR-05:** Disputed amounts may be flagged and excluded from collection actions while remaining in the books.

**Acceptance criteria**

- **AC-AR-01** The ageing report total equals the sundry debtors control balance.
- **AC-AR-02** A student's statement shows every demand, every receipt, every concession and the running balance.

---

## 23. Fee Receivable Accounting *(new in v2)*

**BR-FEE-01:** A fee demand raised in the Fees module creates a receivable in Accounting, as a bill reference against the student's ledger, exactly once.

**BR-FEE-02:** Fee income is recognised according to the school's stated policy — on demand (accrual) or on receipt (cash). The policy is configured, applied consistently, and stated on the financial statements.

**BR-FEE-03:** Fee received for a future period is a liability (Fees Received in Advance), not income of the current period.

**BR-FEE-04:** A fee receipt must be allocable to specific demands, so that "what has this student paid for?" is answerable.

**BR-FEE-05:** Cancelling a fee demand must reverse its receivable and its income, and must be refused if the demand has been settled.

**BR-FEE-06:** The Fees module and the Accounting module must be reconcilable at any date, by student and in total.

**Acceptance criteria**

- **AC-FEE-01** Total fee receivable in Accounting equals total outstanding demands in the Fees module, or the difference is itemised by student.
- **AC-FEE-02** Advance fee collected in March for the next session appears as a liability at 31 March, not as income.

---

## 24. Concessions, Scholarships and Waivers *(new in v2)*

**BR-CONC-01:** A concession is recorded explicitly. It never reduces the gross demand silently.

**BR-CONC-02:** The gross fee, the concession and the net receivable are separately reportable for any student, class or period.

**BR-CONC-03:** Each concession carries its type — scholarship, sibling, staff ward, merit, hardship, management — its authoriser, and its sanction reference.

**BR-CONC-04:** A concession granted after the demand is a credit note against the receivable. One granted before is a reduction of the demand raised, and both the gross and the concession are still recorded.

**BR-CONC-05:** Total concession is a reportable figure that management and trustees will be asked for, and must reconcile to the ledger.

**BR-CONC-06:** A write-off of an uncollectable fee is not a concession. The two must never be conflated.

**Acceptance criteria**

- **AC-CONC-01** Gross fee income, concession, and net fee income are reportable for any period and reconcile.
- **AC-CONC-02** Concession by type and by authoriser is reportable for the year.

---

## 25. Fund Accounting *(new in v2)*

A school trust receives money it is not free to spend as it likes. The books must show that it did not.

**BR-FUND-01:** A fund is a named pool of money with a stated restriction: **Unrestricted**, **Restricted** (donor- or grantor-specified purpose), **Corpus** (permanently restricted), or **Designated** (management-earmarked, internally reversible).

**BR-FUND-02:** A receipt into a restricted fund, and any expenditure from it, is attributable to that fund.

**BR-FUND-03:** Expenditure from a restricted fund exceeding its balance must be prevented or must require authorisation, per policy.

**BR-FUND-04:** For every fund the school must be able to state: opening balance, additions, utilisation, and closing balance, for any period.

**BR-FUND-05:** Corpus receipts are never income of the period. They are added to the corpus fund.

**BR-FUND-06:** Fund is a distinct dimension from cost centre. A cost centre says where the money went; a fund says whose money it was. The same expenditure carries both.

**BR-FUND-07:** The Balance Sheet must present funds separately, and the sum of fund balances must reconcile to the net asset position.

**Acceptance criteria**

- **AC-FUND-01** A fund utilisation statement for any period balances: opening + additions − utilisation = closing.
- **AC-FUND-02** Spending ₹5,00,000 from a fund holding ₹3,00,000 is refused, or requires recorded authorisation.
- **AC-FUND-03** A donor can be shown exactly what their restricted donation was spent on.

---

## 26. Advances

**BR-ADV-01:** An advance remains identifiable until it is adjusted or refunded.

**BR-ADV-02:** An advance is not income or expenditure. It is a liability or an asset until adjusted.

**BR-ADV-03:** Adjusting an advance against a subsequent bill is a traceable act linking the two.

**BR-ADV-04:** Long-unadjusted advances are an exception and must be reportable.

**Acceptance criteria**

- **AC-ADV-01** Unadjusted advances are reportable by party and age.

---

## 27. Provisional, Post-Dated and Scenario Transactions

**BR-PROV-01:** A provisional voucher is excluded from every financial statement, every balance and every tax computation, without exception.

**BR-PROV-02:** Provisional and post-dated vouchers are separately reportable at all times.

**BR-PROV-03:** Confirming a provisional voucher is a posting event subject to every posting rule.

**BR-PROV-04:** A post-dated voucher becomes eligible for posting on its date, and never before.

**BR-PROV-05:** Scenario values are never mixed with actuals in any statement. A report including scenario values must say so on its face.

> **Note on a v1/DDL conflict.** `Accounting_DDL_v4.3.sql` states that an optional voucher "should be considered in financial reports but should not be posted to ledgers". That contradicts v1's own BR-OPT-02 and is contradicted here by BR-PROV-01. The rule is: **provisional vouchers appear in no financial statement.** This must be corrected in the schema comments and in the code.

**Acceptance criteria**

- **AC-PROV-01** A ₹10,00,000 provisional voucher changes no figure in the Trial Balance, Balance Sheet or Income & Expenditure.

---

## 28. Approval and Maker-Checker

**BR-APPR-01:** Approval requirements are configurable by voucher type, by amount threshold, by ledger and by role.

**BR-APPR-02:** The approver is recorded, with the time and any note.

**BR-APPR-03:** Approval never erases the identity of the creator.

**BR-APPR-04:** Where segregation of duties applies, a user may not approve their own voucher. An override, where permitted at all, is recorded as an override.

**BR-APPR-05:** A rejected voucher returns to draft with the rejection reason, and the rejection is retained.

**BR-APPR-06:** Multi-level approval must be supported where policy requires it, and each level recorded separately.

**BR-APPR-07:** Pending approvals must be visible to those who must act on them, and their age reportable.

**Acceptance criteria**

- **AC-APPR-01** A payment above the configured threshold cannot be posted without the required approval.
- **AC-APPR-02** A user attempting to approve their own voucher is refused, naming the rule.

---

## 29. Correction, Cancellation and Reversal

**BR-CORR-01:** An unposted voucher is corrected by editing it.

**BR-CORR-02:** A posted voucher in an open period may be cancelled, or reversed and re-entered. It may not be edited.

**BR-CORR-03:** A posted voucher in a closed period may only be corrected by a reversal dated in an open period, or by reopening the closed period under authorisation.

**BR-CORR-04:** Every cancellation and every reversal records who, when and why.

**BR-CORR-05:** Correction never conceals the original. Both remain visible and reportable.

**BR-CORR-06:** A voucher that has been reconciled, or included in a filed statutory return, requires elevated authorisation to cancel or reverse, and the downstream effect is flagged.

**Acceptance criteria**

- **AC-CORR-01** Cancelled and reversed vouchers are listed on a dedicated report with reason and actor.
- **AC-CORR-02** Cancelling a reconciled bank voucher warns that the reconciliation will be invalidated, and records the acknowledgement.

---

## 30. Audit Trail

**BR-AUD-01:** Every create, change, post, approve, cancel, reverse, reconcile, close and reopen is recorded with actor, timestamp, record, before-value, after-value and reason where required.

**BR-AUD-02:** Master changes — ledger, group, tax rate, credit limit, bank detail, approval policy, numbering — are audited equally.

**BR-AUD-03:** The audit trail is append-only. No role may edit or delete an audit record.

**BR-AUD-04:** The audit trail distinguishes a person from a system process.

**BR-AUD-05:** The audit trail is retained at least as long as the financial records it describes, and no less than eight years.

**BR-AUD-06:** An auditor must be able to obtain the complete history of any voucher, ledger or master record in one action.

**Acceptance criteria**

- **AC-AUD-01** For any posted voucher, the full sequence of who did what and when is displayable.
- **AC-AUD-02** No role in the system, including Super Admin, can modify an audit record through any route.

---

## 31. Supporting Evidence

**BR-DOC-01:** A voucher may carry supporting documents — invoice, bill, receipt, sanction, bank advice, contract.

**BR-DOC-02:** Evidence remains associated with the voucher for the retention period.

**BR-DOC-03:** Voucher types may require evidence before posting, by configuration.

**BR-DOC-04:** Evidence access follows the same permissions as the voucher.

**Acceptance criteria**

- **AC-DOC-01** A purchase voucher above the configured threshold cannot be posted without an attached bill.

---

## 32. Duplicate Prevention

**BR-DUP-01:** The module detects likely duplicates on entry — same party, same document number, same date, same amount.

**BR-DUP-02:** Detection warns; it does not silently reject.

**BR-DUP-03:** Proceeding past a duplicate warning is recorded with the user and the reason.

**BR-DUP-04:** Vendor bill number must be unique per vendor per financial year, enforced not merely warned.

**Acceptance criteria**

- **AC-DUP-01** Entering the same vendor bill number twice for one vendor in one year is refused.
- **AC-DUP-02** A near-duplicate payment produces a warning naming the earlier voucher.

---

## 33. Recurring Transactions

**BR-RECUR-01:** A recurring definition is a template, never a posted transaction.

**BR-RECUR-02:** Generated vouchers are created as drafts unless the template is explicitly configured to auto-post, and auto-posting requires a permission.

**BR-RECUR-03:** Changing a template never alters vouchers already generated.

**BR-RECUR-04:** Every generation is logged, including a failure to generate.

**BR-RECUR-05:** A template has an end condition — an end date or an occurrence count — and stops.

**Acceptance criteria**

- **AC-RECUR-01** A monthly rent template generates exactly twelve vouchers in a year, none duplicated even if the job runs twice in a day.

---

## 34. Budgets

**BR-BUD-01:** Budgets may be set by ledger, group, cost centre, fund or campus, for a period.

**BR-BUD-02:** Several budgets may coexist — original, revised, forecast — and each is identified.

**BR-BUD-03:** Actuals are never affected by budgets.

**BR-BUD-04:** Budget revisions are traceable.

**BR-BUD-05:** Budget-versus-actual variance is reportable in amount and percentage, and drillable to transactions.

**BR-BUD-06:** Exceeding a budget may warn or block, by configuration.

**Acceptance criteria**

- **AC-BUD-01** Variance reported equals actual minus budget for every line, and drills to the vouchers.

---

## 35. Fixed Assets and Depreciation

**BR-FA-01:** An asset is registered with cost, date, category, location, custodian and funding source.

**BR-FA-02:** Acquisition is traceable to its purchase voucher.

**BR-FA-03:** Depreciation follows a stated method and rate per category and is posted as an accounting transaction, not merely calculated.

**BR-FA-04:** Depreciation is never posted twice for the same asset and period.

**BR-FA-05:** Disposal records proceeds, computes gain or loss, and preserves the asset's history.

**BR-FA-06:** Assets purchased from a restricted fund record that fund.

**BR-FA-07:** The fixed asset register must reconcile to the asset ledgers in the Balance Sheet.

**Acceptance criteria**

- **AC-FA-01** The asset register's net block equals the sum of the asset ledger balances.
- **AC-FA-02** Re-running depreciation for a period already depreciated posts nothing.

---

## 36. Expense Claims

**BR-EXP-01:** A claim is submitted, approved and paid as distinct, recorded steps.

**BR-EXP-02:** A claim posts to the books only on approval.

**BR-EXP-03:** Claim lines carry their own expense head, cost centre and evidence.

**BR-EXP-04:** A claimant may not approve their own claim.

**BR-EXP-05:** Payment against an approved claim is traceable to it.

**Acceptance criteria**

- **AC-EXP-01** An unapproved claim appears in no expenditure figure.

---

## 37. Interest Calculation

**BR-INT-01:** Interest rules are configurable per ledger or agreement: rate, basis, day-count, grace period, compounding.

**BR-INT-02:** Calculated interest is a proposal until posted as a voucher.

**BR-INT-03:** Every interest computation is explainable — principal, rate, period, days, amount.

**BR-INT-04:** Interest is distinguishable from principal in every report.

**Acceptance criteria**

- **AC-INT-01** Any interest figure can be expanded to show its computation.

---

## 38. Credit Limits

**BR-CRED-01:** A credit limit and credit period may be set per party.

**BR-CRED-02:** Current exposure is computed from outstanding bills plus unposted commitments where configured.

**BR-CRED-03:** Exceeding a limit warns, requires approval, or blocks — per policy.

**BR-CRED-04:** Every override is recorded with approver and reason.

**Acceptance criteria**

- **AC-CRED-01** A transaction breaching the limit cannot proceed silently under any setting.

---

## 39. Multi-Currency

**BR-FX-01:** Every amount is stored in both the transaction currency and the base currency.

**BR-FX-02:** The exchange rate used is recorded on the transaction and never retrospectively altered.

**BR-FX-03:** Foreign-currency balances are separately reportable from base-currency balances.

**BR-FX-04:** Exchange differences on settlement and on revaluation are recognised per policy and posted as identifiable entries.

**BR-FX-05:** Historical transactions remain explainable when rates later change.

**Acceptance criteria**

- **AC-FX-01** A foreign-currency receipt settled at a different rate produces an identifiable exchange gain or loss.
- **AC-FX-02** Reports state the currency and the rate basis on their face.

---

## 40. Multi-Campus and Inter-Unit

**BR-UNIT-01:** Where the school has multiple campuses, every transaction is attributable to one.

**BR-UNIT-02:** Campus-level and consolidated statements are both producible.

**BR-UNIT-03:** Inter-campus transactions are distinguishable from external ones.

**BR-UNIT-04:** Consolidation eliminates inter-campus balances so nothing is double counted.

**Acceptance criteria**

- **AC-UNIT-01** Consolidated totals equal the sum of campuses minus eliminations, and the eliminations are listed.

---

## 41. Suspense and Unclassified Items

**BR-SUSP-01:** A transaction whose classification is unknown may be posted to suspense rather than guessed.

**BR-SUSP-02:** Suspense balances are visible and aged.

**BR-SUSP-03:** A period may not be closed with a non-zero suspense balance without authorisation.

**Acceptance criteria**

- **AC-SUSP-01** Suspense items older than 30 days appear on the exception report.

---

## 42. Write-Offs

**BR-WO-01:** A write-off requires authorisation at a level set by amount.

**BR-WO-02:** The reason and the authoriser are recorded.

**BR-WO-03:** The original outstanding history remains visible after write-off.

**BR-WO-04:** A written-off amount later recovered is recognised as income, not as a reversal of the write-off.

**Acceptance criteria**

- **AC-WO-01** Write-offs for a period are reportable by party, amount, reason and authoriser.

---

## 43. Rounding

**BR-ROUND-01:** Rounding rules are configured and applied consistently.

**BR-ROUND-02:** A rounding adjustment posts to a dedicated ledger and is never absorbed silently into another head.

**BR-ROUND-03:** Rounding may never be used to force an unbalanced voucher to balance beyond a configured tolerance.

**Acceptance criteria**

- **AC-ROUND-01** Total rounding for a period is reportable as a single figure.

---

## 44. Period Close and Year End

**BR-CLOSE-01:** Closing follows a checklist, and the checklist state is recorded.

**BR-CLOSE-02:** Closing is refused while blocking conditions exist: unposted vouchers, pending approvals, unreconciled bank items beyond tolerance, non-zero suspense, unallocated advances beyond tolerance.

**BR-CLOSE-03:** Closing records who closed, when, and the closing figures as at that moment.

**BR-CLOSE-04:** Reopening requires elevated authorisation and is recorded with reason.

**BR-CLOSE-05:** Year-end produces the next year's opening balances from the closing balances of balance-sheet accounts, and transfers the surplus or deficit to the appropriate fund.

**BR-CLOSE-06:** Income and expenditure accounts start the new year at zero.

**BR-CLOSE-07:** Carry-forward is traceable: every opening balance names the closing balance it came from.

**Acceptance criteria**

- **AC-CLOSE-01** Closing a period with an unposted voucher is refused, listing the voucher.
- **AC-CLOSE-02** Opening balances of a new year equal the closing balances of the prior year, account by account.
- **AC-CLOSE-03** A closed period's Trial Balance is byte-identical whenever it is re-run.

---

## 45. Tax Scope *(rescoped in v2)*

v1 carried Tally's entire India tax surface. Most of it does not apply to a school, and building it would be waste. This section states what applies.

| Regime | Applicability to a school | Decision |
|---|---|---|
| **TDS** | Applies — salary, contractor, rent, professional fees, commission | **In scope, Phase 3** |
| **GST** | Core education is exempt. Ancillary supplies to non-students — canteen, transport to outsiders, hall hire, uniform/book sales through a taxable entity — may be taxable. Registration may be required | **In scope, selectively, Phase 3** |
| **TCS** | Rare for a school | **Configurable, not built by default. Phase 4 if needed** |
| **Professional Tax, PF, ESI** | Payroll statutory deductions; computed by Payroll | **Accounting records the liability and its payment. Phase 3** |
| **Income Tax (12A/80G)** | Exemption maintenance; 80G receipts to donors | **In scope, Phase 3 — receipt numbering and donor reporting** |
| **VAT, CST, Service Tax, Excise** | Dead regimes | **Not built. Not migrated** |

**BR-TAX-01:** Tax configuration is effective-dated. A rate change never alters the tax on a transaction already recorded.

**BR-TAX-02:** Every tax amount is traceable to the transaction that produced it and to the rate and rule that computed it.

**BR-TAX-03:** Tax liability, tax paid and tax outstanding are separately reportable.

**BR-TAX-04:** A statutory return period may be locked once its return is filed. Changing a transaction inside a locked return period requires authorisation and flags the return for revision.

**Acceptance criteria**

- **AC-TAX-01** A rate change effective 1 October leaves September transactions untouched.
- **AC-TAX-02** Every tax report reconciles to the tax ledger balances.

---

## 46. TDS

**BR-TDS-01:** TDS applicability is determined by nature of payment, payee status and threshold, all configurable and effective-dated.

**BR-TDS-02:** TDS is deducted at the earlier of credit or payment, per the rule.

**BR-TDS-03:** TDS deducted is a liability distinct from the expense and from the amount payable to the party.

**BR-TDS-04:** Lower-deduction and nil-deduction certificates are recorded with their validity and limit, and applied automatically within it.

**BR-TDS-05:** Deposits are recorded with challan detail and matched to the deductions they cover.

**BR-TDS-06:** Deduction, deposit and return data must reconcile at all times.

**BR-TDS-07:** Late deposit interest is computed and made visible.

**Acceptance criteria**

- **AC-TDS-01** A quarterly TDS statement reconciles to the TDS payable ledger movement for the quarter.
- **AC-TDS-02** A payee with a valid lower-deduction certificate is deducted at the certificate rate, up to its limit, automatically.

---

## 47. GST (where applicable)

**BR-GST-01:** Each supply is classified — taxable, exempt, nil-rated, zero-rated, non-GST — and the classification drives the accounting.

**BR-GST-02:** Output tax and input tax credit are separately maintained.

**BR-GST-03:** Input credit is claimed only where eligible; ineligible credit is expensed.

**BR-GST-04:** Reverse-charge liability is identified, accounted and paid separately from ordinary output tax.

**BR-GST-05:** Place of supply determines the tax split (CGST+SGST or IGST), and the determination is recorded.

**BR-GST-06:** Return data is prepared from posted transactions and reconciles to the tax ledgers.

**BR-GST-07:** A rate or classification change never rewrites the tax of a recorded transaction.

**Acceptance criteria**

- **AC-GST-01** Output tax per the return equals the movement in the output tax ledgers for the period.
- **AC-GST-02** Exempt education income appears in the exempt figure and attracts no output tax.

---

## 48. Donations and 80G *(new in v2)*

**BR-DON-01:** A donation records the donor, amount, mode, purpose and whether it is corpus or general.

**BR-DON-02:** An 80G receipt carries a unique, gapless, sequential number per financial year.

**BR-DON-03:** Anonymous donations are identified as such, because they are taxed differently.

**BR-DON-04:** Donations in kind are recorded at valuation with the basis of valuation.

**BR-DON-05:** Donor-wise and purpose-wise donation reporting must be available for the year.

**Acceptance criteria**

- **AC-DON-01** The 80G receipt series has no gaps, and every receipt is traceable to a posted voucher.

---

## 49. Grants *(new in v2)*

**BR-GRANT-01:** A grant records the grantor, sanction, amount, purpose, conditions and utilisation period.

**BR-GRANT-02:** A grant receivable is recognised on sanction where the policy is accrual.

**BR-GRANT-03:** Grant utilisation is tracked against the sanctioned purpose.

**BR-GRANT-04:** Unutilised grant at period end is a liability, not income.

**BR-GRANT-05:** A utilisation certificate must be producible from the books.

**Acceptance criteria**

- **AC-GRANT-01** For any grant, sanctioned, received, utilised and unutilised amounts are reportable and reconcile.

---

## 50. Financial Statements

Required: **Balance Sheet**, **Income & Expenditure** (the school equivalent of Profit & Loss), **Receipts & Payments**, **Trial Balance**, **Cash Flow**, **Fund Flow**, **Fund Utilisation**.

**BR-FS-01:** Every statement derives from posted vouchers and opening balances alone.

**BR-FS-02:** Every statement supports a date or period, and comparison with the prior period or year.

**BR-FS-03:** Every figure drills to group, ledger, voucher and evidence.

**BR-FS-04:** Statements must reconcile with one another. The Balance Sheet must balance.

**BR-FS-05:** A statement for a closed period is reproducible identically at any later date.

**BR-FS-06:** Statements state their period, their basis, their filters and whether provisional items are included — always "no", per BR-PROV-01.

**BR-FS-07:** The Balance Sheet presents funds separately as required by BR-FUND-07.

**Acceptance criteria**

- **AC-FS-01** Balance Sheet total assets equal total liabilities plus funds, at every date, to the paisa.
- **AC-FS-02** The surplus in the Income & Expenditure equals the movement in the accumulated fund on the Balance Sheet.
- **AC-FS-03** Any figure can be expanded to the vouchers behind it in no more than four steps.

---

## 51. Books, Registers and Reports

Day Book · Cash Book · Bank Book · Ledger Statement · Group Summary · Sales (Fee Demand) Register · Purchase Register · Receipt Register · Payment Register · Journal Register · Credit/Debit Note Registers · Outstanding Receivables · Outstanding Payables · Ageing · Cost Centre Statement · Fund Utilisation · Budget Variance · Exception Reports · Audit Trail Report.

**BR-RPT-01:** Every report derives from posted transactions, never from a stored summary that could disagree.

**BR-RPT-02:** Every report is drillable and exportable.

**BR-RPT-03:** Every report states its period, filters and generation time.

**BR-RPT-04:** Reports distinguish zero, unknown and not-applicable.

**BR-RPT-05:** Cancelled, provisional and post-dated vouchers are visibly marked wherever they appear.

**Acceptance criteria**

- **AC-RPT-01** The Day Book for a date lists every voucher of that date, including cancelled ones, marked.
- **AC-RPT-02** Any report exported to Excel or PDF carries its filters and its generation timestamp.

---

## 52. Integration Contract *(new in v2)*

v1 described integration as intent. The DDL has already built an event engine. This section states the contract it must satisfy.

**BR-INT-01:** Each side owns its own truth. The source module owns the business event; Accounting owns its financial representation.

**BR-INT-02:** A financial event produces exactly one accounting transaction. Replaying it produces none.

**BR-INT-03:** Every generated voucher records its source module, source record and source event, permanently.

**BR-INT-04:** A source event whose accounting configuration is missing is queued and reported. It is never silently dropped, and never guessed at.

**BR-INT-05:** A failed posting is retried a bounded number of times and then escalated to a person.

**BR-INT-06:** Every integration is reconcilable: for any period, the module's own total must equal the total posted to Accounting from it, or the difference must be itemised.

**BR-INT-07:** Reversing a source event reverses its accounting entry. It never edits it.

**BR-INT-08:** Configuration is explicit opt-in. An unconfigured event produces no voucher.

| Module | Event | Accounting effect |
|---|---|---|
| Fees | Demand raised | Dr Student · Cr Fee Income (or Fee Receivable/Deferred per policy) |
| Fees | Fee collected | Dr Cash/Bank · Cr Student, allocated to demands |
| Fees | Concession granted | Dr Concession Expense · Cr Student |
| Fees | Demand cancelled | Reversal of the demand |
| Library | Fine levied / collected | Dr Student · Cr Fine Income / Dr Cash · Cr Student |
| Transport | Charge / collection | As per Fees |
| Hostel | Charge / collection / refund | As per Fees |
| Payroll | Salary run | Dr Salary Expense · Cr Salary Payable, Cr TDS, Cr PF/ESI |
| Payroll | Salary paid | Dr Salary Payable · Cr Bank |
| Vendor | Bill received | Dr Expense/Asset · Cr Vendor · Dr Input Tax · Cr TDS |
| Vendor | Payment | Dr Vendor · Cr Bank, allocated to bills |
| Inventory | Goods received / issued | Dr Stock · Cr GRN Clearing / Dr Consumption · Cr Stock |

**Acceptance criteria**

- **AC-INT-01** A fee collection reconciliation for any date returns zero difference between the Fees module and Accounting, or itemises it.
- **AC-INT-02** Replaying a day of events creates no duplicate voucher.
- **AC-INT-03** Events pending because of missing configuration are visible with their count and age.

---

## 53. Exception and Risk Monitoring

Exceptions to detect: negative cash · unexpected negative balances · overdue receivables and payables · unreconciled bank items · unallocated advances and On Account balances · aged suspense · unusual journals · frequent cancellations · repeated corrections · missing evidence · missing tax details · duplicate candidates · budget breaches · restricted-fund overspend · unposted drafts · pending approvals · stale cheques · gaps in numbering.

**BR-EXC-01:** Exception rules and thresholds are configurable.

**BR-EXC-02:** Each exception names the records concerned and is drillable.

**BR-EXC-03:** An exception may be acknowledged with a reason, and the acknowledgement is recorded and expires.

**BR-EXC-04:** Blocking exceptions prevent period close.

**Acceptance criteria**

- **AC-EXC-01** The exception dashboard shows the count and value of every open exception, drillable to records.

---

## 54. Notifications

**BR-NOT-01:** Notifications are targeted by responsibility, not broadcast.

**BR-NOT-02:** The same condition does not notify repeatedly within a configured window.

**BR-NOT-03:** Notifiable events include: approval pending, high-value transaction posted, negative cash, credit limit breach, cheque bounced, statutory due date approaching, period close due, reconciliation overdue, restricted-fund overspend, integration failure.

**BR-NOT-04:** Every notification states what happened and what action is expected.

**Acceptance criteria**

- **AC-NOT-01** A bounced cheque notifies the accountant and the fee counter once, not once per report run.

---

## 55. Security and Access

**BR-SEC-01:** Permissions are granular: per capability, per voucher type, per ledger group, per campus.

**BR-SEC-02:** Sensitive capabilities — approve, post, cancel, reverse, write off, close, reopen, change masters, view bank details — are separately permissioned.

**BR-SEC-03:** Accounting data is tenant-scoped and never visible across tenants.

**BR-SEC-04:** Bank account details and donor personal data are restricted beyond ordinary accounting access.

**BR-SEC-05:** Every permission denial on a sensitive capability is logged.

**BR-SEC-06:** Auditor access is read-only by construction.

**Acceptance criteria**

- **AC-SEC-01** A clerk cannot post, approve, cancel or view another campus's data.
- **AC-SEC-02** An auditor account cannot write to any accounting table through any route.

---

## 56. Data Import and Export

**BR-IMP-01:** Imported data is staged and validated before it becomes accounting data.

**BR-IMP-02:** The import source and batch remain identifiable on every imported record.

**BR-IMP-03:** Re-importing the same file creates nothing new.

**BR-IMP-04:** Import errors are itemised and correctable without restarting.

**BR-IMP-05:** An import may be reversed while its batch is unposted.

**BR-EXP-01:** Export states its scope, period and filters.

**BR-EXP-02:** Exported figures equal on-screen figures.

**BR-EXP-03:** Exports containing bank or donor data are restricted and logged.

**Acceptance criteria**

- **AC-IMP-01** Importing an identical statement or master file twice changes nothing.
- **AC-EXP-01** An exported Trial Balance balances and matches the screen.

---

## 57. AI-Assisted Analysis

**BR-AI-01:** AI never posts, alters, approves or cancels an accounting record. It proposes; a person disposes.

**BR-AI-02:** Every AI output carries its evidence, its confidence and a review state.

**BR-AI-03:** AI suggestions are always visually and structurally distinct from confirmed accounting data.

**BR-AI-04:** Accepting or rejecting a suggestion is recorded with actor and time.

**BR-AI-05:** AI accuracy by suggestion type is measured against subsequent human decisions and reported.

**BR-AI-06:** No tenant financial data, bank detail or personal data is sent to an external AI service beyond what is governed and minimised.

Candidate uses: duplicate detection · expense classification · bank reconciliation matching · anomaly detection · collection and payment prioritisation · cash forecasting · variance explanation · narration drafting · exception triage.

**Acceptance criteria**

- **AC-AI-01** Every AI suggestion displays why it was made.
- **AC-AI-02** An AI-suggested classification is never applied without a recorded human acceptance.

---

## 58. Core Accounting Rules

These sixteen rules govern everything above. Where a design decision conflicts with one, the rule wins.

| # | Rule | Consequence if violated |
|---|---|---|
| **R-01** | **Debits equal credits.** Always, in every posted voucher | The books are not books |
| **R-02** | **Only posted transactions count.** Drafts, provisional and post-dated entries affect nothing | Reported figures include things that did not happen |
| **R-03** | **Posted is immutable.** Correct by reversal, never by edit | History becomes unreliable |
| **R-04** | **Cancellation is not deletion.** The voucher and its number survive | Numbering gaps become unexplainable |
| **R-05** | **Balances are derived, never asserted.** Every balance must be rebuildable from transactions | Corruption becomes undetectable |
| **R-06** | **Closed means closed.** A closed period's figures never change again | Reported numbers are not reproducible |
| **R-07** | **Masters and history are separate.** Changing a master never rewrites a recorded transaction | Last year's accounts change by themselves |
| **R-08** | **Every figure is traceable.** From statement to group to ledger to voucher to evidence | Nobody can defend the accounts |
| **R-09** | **Maker is not checker.** Creation and approval are different acts by different people | Control is theatre |
| **R-10** | **Every action is attributable.** Person or identified system process | No accountability |
| **R-11** | **Restricted money is accounted separately.** A fund's use is demonstrable | Breach of trust |
| **R-12** | **Party balance equals bill outstanding.** The control account and the sub-ledger always agree | Receivables cannot be relied on |
| **R-13** | **One event, one entry.** Integration never duplicates and never drops | The books diverge from operations |
| **R-14** | **Tax follows the transaction as it was.** A rate change is prospective | Historical tax becomes indefensible |
| **R-15** | **Audit trail is append-only.** No role may alter it | The audit trail proves nothing |
| **R-16** | **AI assists, never posts** | Unverifiable entries enter the books |

---

## 59. Lifecycles

### 59.1 Voucher

```
Draft ──► Pending Approval ──► Posted ──┬──► Cancelled
  │              │                      └──► Reversed (by a new posted voucher)
  │              └──► Rejected ──► Draft
  └──► Discarded (never numbered, never posted)
```

### 59.2 Bill Reference

`Open → Partially Settled → Settled`, with `Written Off`, `Disputed` and `Cancelled` as alternatives. Reopens when a settling voucher is cancelled or reversed.

### 59.3 Cheque

`Issued/Received → Deposited/Presented → Cleared`, with `Bounced`, `Stopped`, `Cancelled`, `Stale`.

### 59.4 Accounting Period

`Open → Soft-Closed → Hard-Closed`, with authorised `Reopened → Open`.

### 59.5 Bank Reconciliation

`Not Started → In Progress → Matched → Confirmed → Completed`, with `Unmatched` and `Disputed` for residuals.

### 59.6 Fund

`Created → Active → Fully Utilised → Closed`, with `Suspended` where the grantor imposes a hold.

---

## 60. Decisions Register

v1 §128 ended with 50 unanswered questions. Each is answered here. **Decisions marked ⚠ materially change the build and must be confirmed before Phase 1.**

| ID | Decision | Recommended answer | Rationale |
|---|---|---|---|
| **D-01** ⚠ | Single or multi-company? | **One legal entity per tenant.** Multi-campus within it | Prime-AI's tenancy already isolates schools |
| **D-02** ⚠ | Multi-campus accounting? | **Yes, from Phase 4** — but design the campus dimension into the schema in Phase 1 | Retrofitting a dimension into posted history is painful |
| **D-03** | Consolidated reporting? | Yes, with inter-campus elimination | BR-UNIT-04 |
| **D-04** | Financial year | 1 April – 31 March, fixed | Statutory in India |
| **D-05** ⚠ | Academic session vs financial year | **The financial year governs accounting. The session is a reporting tag only** | Conflating them corrupts statutory accounts |
| **D-06** | Can periods reopen? | Yes, with elevated authorisation and full audit | BR-PERIOD-05 |
| **D-07** | Who may reopen? | Accounts Manager or above, with a recorded reason | Segregation of duties |
| **D-08** | Which transactions need approval? | Journals above threshold, all payments above threshold, credit notes, write-offs, period reopening, master changes to bank details | Risk-weighted |
| **D-09** | Maker-checker mandatory? | Yes for payments and journals above threshold; configurable elsewhere | Practicality vs control |
| **D-10** ⚠ | What is "finalised"? | **Posted.** Posting is the point of no return | BR-POST-02 |
| **D-11** | What may be cancelled? | Any posted voucher in an open period, with authorisation. Reconciled or return-included vouchers need elevated rights | BR-CORR-06 |
| **D-12** | Edit vs reverse | Never edit a posted voucher. Reverse | R-03 |
| **D-13** | Numbering policy | Per type, per financial year, gapless, assigned at posting, configurable prefix | BR-VNO-01..03 |
| **D-14** ⚠ | Is bill-wise mandatory? | **Yes for students, vendors and grantors. Optional for employees and donors** | Without it, receivables cannot be defended |
| **D-15** | Credit limits? | Yes for vendors and institutional customers. Not for students | Students are governed by fee policy, not credit |
| **D-16** | Multi-currency? | Phase 4. Base currency INR | Rare for a school; do not delay Phase 1 |
| **D-17** | Interest calculation? | Phase 4. Late-fee on fees is owned by the Fees module | Avoid duplicating the fee engine |
| **D-18** ⚠ | Cost centres required? | **Yes, from Phase 2** — wings, departments, activities. Design in from Phase 1 | Same reason as D-02 |
| **D-19** | Multiple cost categories? | Yes | BR-CC-04 |
| **D-20** | Project/job costing? | Use cost centres of category Project. No separate subsystem | Avoids a parallel dimension |
| **D-21** | Inventory integration? | Phase 4, financial effect only | Inventory module owns stock |
| **D-22** | Fees integration? | **Phase 2, and it is the single most important integration** | Highest volume by far |
| **D-23** | Payroll integration? | Phase 3, financial effect only | Payroll owns computation |
| **D-24** | Bank statement import? | Yes, Phase 2, with configurable column mapping | Already partly built |
| **D-25** | Automatic reconciliation? | Propose automatically, confirm manually. Auto-confirm only on exact match, and only if enabled | BR-BRS-03 |
| **D-26** | Electronic payments? | Phase 4 — generate the bank's payment file. No direct bank API | Bank APIs are a per-bank project |
| **D-27** | Cheque printing? | Phase 4. Capture the data from Phase 2 | Data first, layout later |
| **D-28** ⚠ | Which taxes? | **TDS (Phase 3), GST selectively (Phase 3), 80G (Phase 3). TCS configurable. VAT/CST/Service Tax/Excise never** | §45 |
| **D-29** | Statutory return filing? | Prepare and reconcile data. Do not file | Filing is a portal activity |
| **D-30** | Retention | 8 years minimum for books and audit trail; permanent for the general ledger | Statutory and audit |
| **D-31** ⚠ | Fee income recognition | **Accrual — recognise on demand.** Configurable to cash for schools that prefer it | Accrual is what an auditor expects |
| **D-32** | Advance fee treatment | Liability until the period it relates to | BR-FEE-03 |
| **D-33** ⚠ | Fund accounting required? | **Yes, Phase 3.** Design the fund dimension in Phase 1 | A trust cannot report without it |
| **D-34** | Depreciation method | Per asset category — SLM or WDV, configurable | BR-FA-03 |
| **D-35** | Budget enforcement | Warn by default; block configurable per budget | Practicality |
| **D-36** | Suspense allowed? | Yes, but blocks period close if non-zero | BR-SUSP-03 |
| **D-37** | Rounding tolerance | ₹1 per voucher, to a dedicated ledger | BR-ROUND-03 |
| **D-38** | Negative cash | Block by default; overridable with permission | BR-CASH-02 |
| **D-39** | Ageing basis | Due date, with bill date as an option | BR-AR-02 |
| **D-40** | Ageing buckets | 0–30, 31–60, 61–90, 91–180, >180, configurable | Standard |
| **D-41** | AI level | Suggest with evidence and confidence. Never post | R-16 |
| **D-42** | Which AI needs approval? | All of it | R-16 |
| **D-43** | Management dashboard | Cash, receivables, payables, fund position, surplus/deficit trend, budget variance, exceptions, close status | Decision-relevant only |
| **D-44** | Primary quality measure | **Books closed within 10 working days of month end, with a clean exception list** | Measures the whole system at once |
| **D-45** | Audit history depth | Every field change on every financial and master record, permanently | BR-AUD-01 |
| **D-46** | Which processes stay manual? | Approval, write-off, period close, reconciliation confirmation, duplicate confirmation, fund reallocation | All judgement |
| **D-47** | Voucher classes? | Phase 4. Predefined cost allocation in Phase 2 covers most of the need | Complexity vs value |
| **D-48** | Scenarios? | Phase 4 | Low value until actuals are trustworthy |
| **D-49** ⚠ | Tally export? | **Phase 4, export only.** Not bidirectional | Bidirectional sync with Tally creates two masters and no truth |
| **D-50** | Go-live migration | Opening balances plus open bills only. No historical voucher migration | Cheap, sufficient, and avoids importing other systems' errors |

---

## 61. Success Criteria and KPIs

### 61.1 The module succeeds when the school can answer, from the books:

**Position** — What do we own and owe? What is each fund worth?
**Performance** — What was our income and expenditure? Are we in surplus?
**Receivables** — Who owes us, how much, for what, and for how long?
**Payables** — Whom do we owe, how much, and when is it due?
**Cash** — What is our cash and bank position? What is unreconciled?
**Funds** — What did we receive for a restricted purpose, and what did we spend it on?
**Tax** — What do we owe, what have we paid, what is due?
**Budget** — What did we plan, what happened, where is the variance?
**Audit** — Who created, changed, approved or cancelled this, and why?
**Integration** — Does Accounting agree with Fees, Payroll and the bank?

### 61.2 KPIs

| KPI | Definition | Target |
|---|---|---|
| K-01 Close cycle | Working days from month end to hard close | ≤ 10, then ≤ 5 |
| K-02 Reconciliation currency | Bank ledgers reconciled within 5 days of month end | 100% |
| K-03 Unreconciled ageing | Value of bank items unreconciled > 30 days | ≈ 0 |
| K-04 Fee reconciliation variance | Difference between Fees module and Accounting | 0, or fully itemised |
| K-05 Suspense at close | Suspense balance at period close | 0 |
| K-06 Unallocated receipts | On Account balance as % of receipts | ≤ 2% |
| K-07 Draft ageing | Vouchers in Draft > 7 days | ≈ 0 |
| K-08 Approval latency | Median time from submission to approval | ≤ 1 working day |
| K-09 Reversal rate | Reversals ÷ posted vouchers | ≤ 2% |
| K-10 Duplicate leakage | Duplicate payments detected after posting | 0 |
| K-11 Statutory timeliness | TDS deposited by due date | 100% |
| K-12 Restricted fund compliance | Instances of restricted overspend | 0 |
| K-13 Audit observations | Observations on books and controls per audit | Declining |
| K-14 Integration lag | Time from source event to posted voucher | ≤ 1 hour |
| K-15 Drill-down completeness | Statement figures traceable to vouchers | 100% |

---

## 62. Assumptions, Constraints and Risks

### 62.1 Assumptions

| ID | Assumption |
|---|---|
| A-01 | One legal entity per tenant |
| A-02 | Financial year 1 April – 31 March |
| A-03 | Base currency INR |
| A-04 | The school has, or will appoint, a qualified accountant |
| A-05 | Fees, Payroll and Vendor modules are the authoritative sources of their events |
| A-06 | Bank statements are obtainable in a machine-readable form |
| A-07 | The school is a trust, society or Section 8 company with 12A registration |

### 62.2 Constraints

| ID | Constraint |
|---|---|
| CN-01 | Tenant-scoped; no cross-tenant visibility, ever |
| CN-02 | Must be usable by a clerk who knows Tally, not accounting theory |
| CN-03 | Must support at least 10 years of history without degradation |
| CN-04 | Must remain performant at ~500,000 voucher lines per year per tenant |
| CN-05 | Statutory rules change annually; tax configuration must be data, not code |
| CN-06 | Must run on the existing Laravel/MySQL stack |
| CN-07 | Financial statements must be acceptable to a statutory auditor |

### 62.3 Risks

| ID | Risk | Impact | Mitigation |
|---|---|---|---|
| RK-01 | Books diverge from the Fees module | Receivables cannot be relied on | BR-INT-06 reconciliation report, from day one |
| RK-02 | Users post to Suspense to avoid thinking | Books become meaningless | Aged suspense blocks close (BR-SUSP-03) |
| RK-03 | Everything is entered by one person with all permissions | No control at all | Enforce maker-checker; report on it |
| RK-04 | Period close never happens | Figures never settle | K-01 tracked and escalated |
| RK-05 | Stored balances drift from transactions | Silent corruption | R-05: derived only, with a rebuild command |
| RK-06 | Cross-module events duplicate or vanish | Books wrong in both directions | BR-INT-02 idempotency plus BR-INT-06 reconciliation |
| RK-07 | Tax rules change and history is rewritten | Indefensible prior returns | BR-TAX-01 effective dating |
| RK-08 | Restricted funds are spent generally | Breach of trust; loss of exemption | BR-FUND-03 |
| RK-09 | Scope is driven by Tally parity rather than school need | Years spent on features nobody uses | §45 rescoping and the phase plan |
| RK-10 | Migration imports another system's errors | Bad opening position | D-50: balances and open bills only |

---

## 63. Phased Delivery

| Phase | Theme | Delivers | Business acceptance |
|---|---|---|---|
| **1** | **The books** | Groups, ledgers, financial years and periods, voucher types and numbering, all nine voucher types, the posting engine, opening balances, party ledgers, bill-wise tracking, Trial Balance, Balance Sheet, Income & Expenditure, Day Book, ledger statements, audit trail, permissions | An accountant can keep a complete, balanced, auditable set of books for a full month and produce a Trial Balance that balances |
| **2** | **Operations and control** | Cash and bank, cheques, statement import and reconciliation, receivables and payables with ageing, cost centres, approval workflow, cancellation and reversal, period close and year-end, Fees integration, concessions | The school can close a month in under 10 days with the bank reconciled and receivables agreed to Fees |
| **3** | **Compliance and analysis** | Fund accounting, TDS, GST, 80G and donations, grants, fixed assets and depreciation, budgets, recurring vouchers, expense claims, Payroll and Vendor integration, cash flow, fund flow, ratios, exceptions | The school can complete a statutory audit and file its statutory returns from the books |
| **4** | **Reach and intelligence** | Interest, credit limits, multi-currency, multi-campus consolidation, scenarios and forecasting, payment advice and e-payment files, Tally export, AI assistance | The books produce forward-looking decisions, not only backward-looking records |

**Overall acceptance:** the school can answer every question in §61.1 from posted transactions, and an auditor can verify every answer.

---

## 64. Enhancements

Capabilities **beyond v1**, each with the problem it solves, its value, and relative effort. Recommendations, not committed scope.

### 64.1 Control and accuracy

**E-01 — Continuous Trial Balance Assertion.**
A background check that asserts, continuously: every posted voucher balances; every ledger balance equals the sum of its lines; every party balance equals its bill outstandings; the Balance Sheet balances. Any failure raises an alert naming the record.
*Problem:* corruption discovered at year end costs weeks. *Value:* it is discovered the same day, with the culprit named. *Effort:* Low. **The highest value-to-effort item in this list.**

**E-02 — Reconciliation Cockpit.**
One screen showing every reconciliation the school owes: bank vs book, Fees vs Accounting, Payroll vs Accounting, vendor statements vs payables, tax returns vs tax ledgers, fixed asset register vs asset ledgers, fund statements vs fund balances — each with its difference, age and owner.
*Value:* turns "are the books right?" from an annual investigation into a daily glance. *Effort:* Medium.

**E-03 — Period Close Cockpit.**
The close checklist as a live, owned, blocking workflow: each item with its owner, state, blocking condition and evidence. Close cannot proceed until the blockers clear.
*Value:* K-01 becomes achievable rather than aspirational. *Effort:* Medium.

**E-04 — Segregation-of-Duties Analyser.**
Reports which users can both create and approve, both post and reconcile, both raise and pay. Flags actual instances where one person did both.
*Value:* the first thing an auditor asks for, answered before they ask. *Effort:* Low.

**E-05 — Four-Eyes on Masters.**
Bank account numbers, IFSC, vendor payment details and approval thresholds require a second person to confirm a change.
*Problem:* the most common accounting fraud is changing a vendor's bank account. *Value:* closes it. *Effort:* Low.

**E-06 — Numbering Gap Watch.**
Continuous detection of gaps in every voucher and receipt series, with each gap explained or flagged.
*Value:* a missing voucher is noticed in a day, not at audit. *Effort:* Low.

### 64.2 School-specific

**E-07 — Student Financial Statement.**
One parent-facing statement per student: demands, concessions, receipts, advances, balance, due dates — reconciling exactly to the ledger.
*Value:* removes the largest single source of front-desk disputes. *Effort:* Low.

**E-08 — Fee Collection Forecast.**
Projects collections from demand schedule, historical payment behaviour by class and by family, and seasonality.
*Value:* a school's cash crisis is always a collection-timing problem. *Effort:* Medium.

**E-09 — Concession Analytics.**
Concession by type, class, authoriser and trend, against policy limits, with the total cost of concession as a line management will be asked about.
*Value:* concession is usually the second-largest "expense" and the least controlled. *Effort:* Low.

**E-10 — Fund Utilisation Certificate Generator.**
Produces, per grant or restricted fund, the utilisation statement a grantor requires, directly from posted vouchers, with the underlying transactions attached.
*Value:* days of manual compilation per grant, eliminated. *Effort:* Medium.

**E-11 — 80G Receipt Automation.**
Sequential, gapless 80G receipts issued at donation posting, with donor register and annual donor statements.
*Value:* compliance and donor goodwill in one step. *Effort:* Low.

**E-12 — Per-Student and Per-Class Cost.**
Allocates operating cost to classes and wings and derives cost per student against fee per student.
*Value:* the single most useful number for fee-setting, and no school has it. *Effort:* Medium.

**E-13 — Statutory Compliance Calendar.**
Every due date — TDS, GST, PF, ESI, returns, audit — with owner, status, evidence of filing and escalation.
*Value:* penalties are avoidable and entirely self-inflicted. *Effort:* Low.

### 64.3 Efficiency

**E-14 — Bank Statement Auto-Matching.**
Rule-based and learned matching on amount, date window, instrument number and narration, with confidence, proposing rather than confirming.
*Value:* reconciliation goes from days to an hour. *Effort:* Medium.

**E-15 — Voucher Templates and Favourites.**
Saved, per-user templates for repeated entries.
*Value:* removes most repetitive typing. *Effort:* Low.

**E-16 — Bulk Voucher Entry.**
Grid entry and validated spreadsheet upload for high-volume, low-variance batches.
*Value:* month-end journals and utility bills stop taking a day. *Effort:* Medium.

**E-17 — Smart Ledger Suggestion.**
Suggests the expense head from narration, party and history, with confidence, always overridable.
*Value:* faster and more consistently classified entry. *Effort:* Medium.

**E-18 — Mobile Approvals.**
Approve, reject or query a voucher from a phone, with the evidence attached.
*Value:* approval latency (K-08) collapses. *Effort:* Medium.

**E-19 — Payment Run.**
Select due bills, apply available cash, produce a payment batch, one approval, one bank file, and automatic allocation on posting.
*Value:* turns vendor payment from an afternoon into ten minutes. *Effort:* Medium.

### 64.4 Insight

**E-20 — Accounting Health Score.**
A single explainable score from: reconciliation currency, suspense, unallocated receipts, draft ageing, approval latency, exception count, close timeliness. Always drillable to its components.
*Value:* management can see the books are being kept properly without reading them. *Effort:* Low.

**E-21 — Cash Runway.**
Current cash, committed payments, expected collections, statutory dues and payroll, projected forward with a stated confidence band.
*Value:* answers "can we pay salaries next month?" — the question that actually matters. *Effort:* Medium.

**E-22 — Anomaly Detection.**
Flags transactions materially unlike their own history: amount, timing, frequency, counterparty, classification.
*Value:* finds error and fraud that no rule anticipated. *Effort:* Medium.

**E-23 — Trustee Pack.**
A single scheduled pack: position, surplus, fund utilisation, receivables, cash, budget variance, compliance status — narrated, and generated automatically.
*Value:* the finance sub-committee stops consuming a week of preparation per meeting. *Effort:* Medium.

**E-24 — Comparative Benchmarking (anonymised, opt-in).**
Compare cost per student, collection efficiency and concession ratio against anonymised peer schools on the platform.
*Value:* a genuinely unique advantage of a multi-tenant platform. *Effort:* High. **Requires explicit consent and rigorous anonymisation.**

**E-25 — Explain This Number.**
Any figure, anywhere, offers a plain-language account of what it is made of, which vouchers drive it, and what changed since the prior period.
*Value:* determines whether non-accountants trust the system at all. *Effort:* Low if designed in; expensive if retrofitted.

### 64.5 Platform

**E-26 — Immutable Posting Journal.**
An append-only, hash-chained record of every posting, so tampering is detectable rather than merely prohibited.
*Value:* raises the audit trail from a control to evidence. *Effort:* Medium.

**E-27 — What-If on Closed Periods (read-only).**
Model an adjustment against a closed period and see its effect, without touching the closed data.
*Value:* removes most of the pressure to reopen periods. *Effort:* Medium.

**E-28 — Auditor Workspace.**
A read-only workspace: sampling, tick-marks, queries raised against vouchers, responses, and a resolution log.
*Value:* the annual audit stops consuming the accountant's month. *Effort:* Medium.

### 64.6 Recommended sequence

| Priority | Enhancements | Reason |
|---|---|---|
| **First** | E-01, E-25, E-04, E-05, E-06 | Cheap, and E-01 and E-25 must be designed in from the start |
| **Second** | E-03, E-02, E-07, E-13, E-20 | Directly serve the Phase 1–2 acceptance criteria |
| **Third** | E-14, E-19, E-15, E-11, E-09, E-10 | Daily time saved for the accountant |
| **Fourth** | E-21, E-12, E-08, E-23, E-17, E-18, E-16 | Compounding value once the books are trustworthy |
| **Later** | E-22, E-26, E-27, E-28, E-24 | Valuable, not on the critical path |

---

## 65. Document Boundary

This document answers **what the business needs from Accounting** and **why**.

- `Solution_Design_v1.md` answers *how users perform these activities* and *how the system implements them*.
- `Accounting_DDL_v4.4.sql` answers *how the information is represented and related*.
- `ScreenDesign_v2.1.md` answers *how voucher entry is presented*.

Where any of these conflict, **this document governs the intent** and the others must be corrected.

---

## 66. Key Business Principle

> **Every financial number shown to the school must be trustworthy, explainable, traceable and consistent with the underlying accounting records.**

A user must be able to move from

**Decision → Report → Statement → Group → Ledger → Voucher → Evidence**

and understand exactly how the number was produced.

And the outcome the school is buying:

> The module should not merely record debits and credits. It should let a school **know its true financial position at any moment, prove it to an auditor, demonstrate to a donor how their money was used, and decide what to do next.**

---

## 67. Benchmark Note

Tally.ERP 9 / TallyPrime was used as the functional benchmark for voucher structure, masters, registers and report vocabulary — the areas where Tally's design is genuinely good and where users' expectations are already formed.

It was **not** followed for scope. Tally is built for traders; this module is for schools. Tally's inventory, order-processing, POS, excise, VAT, CST and service-tax capabilities are deliberately excluded (§8.2, §45). Its fund accounting, restricted-grant reporting, student fee receivable and concession capabilities are absent from Tally and are added here (§23–§25, §48–§49) because a school cannot operate without them.

**Primary reference:** Tally Solutions — TallyPrime Help, https://help.tallysolutions.com/

---

**End of Accounting_BRD_v2.md**
