# Prime-AI Accounting Module — Solution Design

**Document ID:** ACC-SD-V1
**Version:** 1.0
**Governed by:** `Accounting_BRD_v2.md` (v2.0)
**Realised by:** `Accounting_DDL_v4.4.sql` (v4.4)
**Aligned with:** `ScreenDesign_v2.1.md` (v2.1)
**Status:** Draft for Technical Review
**Date:** 2026-09-05

---

## 0. Document Control

### 0.1 Position

| Layer | Document | Answers |
|---|---|---|
| Business | `Accounting_BRD_v2.md` | What does the school need, and why |
| **Solution** | **This document** | How does the system work, and how is it built |
| Physical | `Accounting_DDL_v4.4.sql` | How is the information stored |
| Interaction | `ScreenDesign_v2.1.md` | How voucher entry is presented |

This is the first solution design for the module. It decides. Every question the BRD left open is either resolved here or listed in §20 as an explicit, owned decision.

### 0.2 What this document settles

| # | Decision area | Why it needed settling |
|---|---|---|
| S-01 | **Balance derivation** (§5) — how a ledger balance, a party outstanding and a Trial Balance are produced at 500,000 lines a year | `acc_ledgers.closing_balance` is currently a stored column with no stated maintenance rule. BRD R-05 forbids that |
| S-02 | **The posting engine** (§4) — what posting does, atomically, and what it locks | The single most consequential undefined behaviour in the module |
| S-03 | **Bill-wise model** (§6) — references and allocations as real entities | BRD §17 is unimplementable against a `VARCHAR(100)` |
| S-04 | **Dimensions** (§7) — cost centre, fund and campus as separable analysis axes | Conflating them makes fund reporting impossible |
| S-05 | **Numbering under concurrency** (§4.6) | `last_number` on the type row is a lost-update waiting to happen |
| S-06 | **Tax engine** (§9) — effective-dated, data-driven | BRD BR-TAX-01 forbids code-embedded rates |
| S-07 | **Integration contract** (§10) — idempotency, reconciliation, failure handling | An event engine exists; its guarantees were unstated |
| S-08 | **Period close** (§8) — what it blocks, what it freezes | BRD BR-PERIOD-04..07 |
| S-09 | **Reconciliation** (§11) — staging, matching, confirmation | Statement rows must never touch the books directly |
| S-10 | **The 20 defects in `Accounting_DDL_v4.3.sql`** (§17.1), 9 of them fatal | The script does not execute |
| S-11 | **Migration from the deployed schema** (§18) | The deployed tenant schema has drifted from the DDL text |

---

## 1. Solution Overview

### 1.1 In one paragraph

The Accounting Module is a **Laravel 12 / MySQL 8 tenant-scoped module** in the Prime-AI platform. It implements Tally-style double-entry bookkeeping on a **voucher header + Dr/Cr lines** model. Everything is derived from posted voucher lines: ledger balances, party outstandings, financial statements, tax positions and fund utilisation. Nothing is asserted independently. A **posting engine** is the sole writer of accounting effect — it validates, numbers, allocates, posts and audits inside one transaction, and refuses everything that would break a rule in BRD §58. Other Prime-AI modules do not write accounting data; they emit **events**, which a configurable rules engine converts into vouchers, idempotently and reconcilably. Periods close, and closed means closed.

### 1.2 Context

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │  Fees · Library · Transport · Hostel · Payroll · Vendor · Inventory │
  └───────────────────────────────┬─────────────────────────────────────┘
                                  │ domain events (never direct writes)
                                  ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │                       ACCOUNTING MODULE                             │
  │                                                                     │
  │   Event Engine ──► Posting Engine ──► Ledger (acc_voucher_items)    │
  │                          │                      │                   │
  │                          │                      ├──► Balances       │
  │                          │                      ├──► Bill-wise      │
  │                          ├──► Audit             ├──► Dimensions     │
  │                          └──► Numbering         └──► Tax            │
  │                                                                     │
  │   Reconciliation · Period Close · Reports · Statements              │
  └─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
              Trial Balance · Balance Sheet · Income & Expenditure
              Receivables · Payables · Funds · Tax · Budgets · MIS
```

### 1.3 Design tenets

| # | Tenet | Consequence in the design |
|---|---|---|
| T-01 | **The voucher line is the only truth** | Every balance, statement and outstanding is derived from `acc_voucher_items`, and rebuildable from it |
| T-02 | **Posted is immutable** | No `UPDATE` on a posted voucher, anywhere, by anyone. Correction is a new voucher |
| T-03 | **One writer** | Only `PostingService` may create accounting effect. No controller, job, observer or seeder writes voucher lines |
| T-04 | **Derived data is a cache with a rebuild** | Every summary table has a rebuild command and a nightly assertion |
| T-05 | **Dimensions are orthogonal** | Cost centre, fund and campus are separate axes and never substitute for one another |
| T-06 | **Configuration is data** | Tax rates, approval thresholds, numbering, event mappings and posting rules are rows, not code |
| T-07 | **Refuse rather than guess** | Ambiguity queues for a person. Nothing is silently assumed |
| T-08 | **Everything is attributable** | Person or identified system process, on every write |

---

## 2. Architecture

### 2.1 Technology

| Concern | Choice | Note |
|---|---|---|
| Runtime | PHP 8.3+, Laravel 12 | Prime-AI stack |
| Database | MySQL 8.0.16+, InnoDB, utf8mb4 | `Accounting_DDL_v4.4.sql` |
| Tenancy | `stancl/tenancy`, database-per-tenant | All `acc_*` tables live in the tenant database. Never in `prime_db` |
| Modularity | `nwidart/laravel-modules` | `Modules/Accounting` |
| UI | Blade + AdminLTE + Alpine.js; Vue 3 for the voucher grid | Matches Prime-AI; the entry grid needs real reactivity |
| Background work | Laravel queues + scheduler | Event posting, recurring vouchers, depreciation, rebuilds, assertions |
| Money | `DECIMAL(15,2)` in the database; integer paise or a Money value object in PHP | Never float. Ever |
| Reporting | SQL views for shape, materialised summary tables for volume | §12 |
| Files | `sys_media` | Statements, bills, receipts, sanctions |

### 2.2 Service layer

| Service | Responsibility | May write |
|---|---|---|
| `PostingService` | **The only writer of accounting effect.** Validate → number → allocate → post → audit, in one transaction | vouchers, items, allocations, dimensions, tax, balances |
| `VoucherDraftService` | Draft create/edit/discard | drafts only |
| `NumberingService` | Allocate the next number under concurrency (§4.6) | number sequences |
| `AllocationService` | Bill reference creation and allocation arithmetic | references, allocations |
| `BalanceService` | Read balances; maintain and rebuild summaries | balance summaries |
| `TaxEngine` | Resolve applicable tax, compute, produce lines | nothing directly — returns lines to `PostingService` |
| `ApprovalService` | Route, approve, reject, escalate | approval records |
| `CancellationService` | Cancel and reverse | cancellation records, reversal vouchers |
| `PeriodService` | Open, soft-close, hard-close, reopen, year-end | period records, opening balances |
| `ReconciliationService` | Import, stage, propose, confirm, undo | statement rows, matches |
| `EventPostingService` | Consume module events, resolve config, call `PostingService` | event log only |
| `ReportService` / `StatementService` | Read-only composition | nothing |
| `AuditService` | Append-only trail | audit log |
| `AssertionService` | Continuous integrity checks (§5.5) | assertion results |

**Enforced in review:**
1. `acc_voucher_items` is written by `PostingService` and nothing else.
2. No `UPDATE` or `DELETE` statement targets a posted voucher or its children.
3. Every service that writes accounting effect writes audit in the same transaction.
4. Every derived table is written only by its own rebuild/increment service.
5. Every monetary comparison uses an exact type. No float enters the module.

### 2.3 The single most important architectural rule

> **`PostingService::post()` is the only path by which anything becomes part of the books.**

Manual entry, cross-module events, recurring templates, depreciation runs, expense claims, opening balances and year-end carry-forward all converge on it. There is exactly one place where the rules of BRD §58 are enforced, and therefore exactly one place where they can be got wrong.

---

## 3. Data Model Overview

### 3.1 Core spine

```
acc_financial_years ──< acc_accounting_periods
                              │
acc_voucher_types ────────────┤
                              ▼
                        acc_vouchers  (header: type, number, date, period, status, source, party)
                              │
                              ├──< acc_voucher_items          (Dr/Cr, ledger, amount)   ← THE LEDGER
                              │       ├──< acc_voucher_item_cost_centers   (dimension: where)
                              │       ├──< acc_voucher_item_funds          (dimension: whose)
                              │       ├──< acc_bill_allocations            (which obligation)
                              │       └──< acc_voucher_item_taxes          (which tax, which rate)
                              ├──< acc_voucher_bank_details   (instrument)
                              ├──< acc_voucher_approvals      (who approved)
                              └──< acc_voucher_references     (against which voucher)

acc_account_groups ──< acc_ledgers ──< acc_bill_references ──< acc_bill_allocations
```

### 3.2 Key type decisions

| Concern | Decision | Reason |
|---|---|---|
| Surrogate keys | `BIGINT UNSIGNED` on transaction tables, `INT UNSIGNED` on masters, `SMALLINT`/`TINYINT` on small reference tables | v4.3 mixes widths across the two sides of the same foreign key in 12 places, and every one of those FKs is rejected by InnoDB (§17.1) |
| Money | `DECIMAL(15,2)` | ₹9,999,999,999,999.99 ceiling — ample, and exact |
| Rates | `DECIMAL(9,4)` | Tax and depreciation rates need 4 decimals |
| Dates | `DATE` for accounting dates, `DATETIME`/`TIMESTAMP` for events | An accounting date is a date, never a moment |
| Enums | `ENUM` for closed, code-controlled sets; reference tables for user-extensible sets | v4.3's single generic status table lets a voucher's status point at an expense-claim status (§17.1 #12) |
| Soft delete | `deleted_at`, plus a **generated** `is_deleted` column inside unique keys | `UNIQUE(code, deleted_at)` does not work — MySQL treats NULLs as distinct, so live duplicates are permitted (§17.1 #11) |

### 3.3 External references

All in the tenant database, all `INT UNSIGNED`:
`sys_users`, `sys_media`, `sys_dropdown_table`, `std_students`, `sch_employees`, `vnd_vendors`, and `glb_app_modules` (global, keyed `VARCHAR(10)`).

---

## 4. The Posting Engine

### 4.1 States

```
Draft ──► Pending_Approval ──► Posted ──┬──► Cancelled
  │              │                      └──► Reversed (a new posted voucher negates it)
  │              └──► Rejected ──► Draft
  └──► Discarded
```

`Draft`, `Pending_Approval`, `Rejected` and `Discarded` have **no accounting effect whatsoever** — no balance, no statement, no outstanding, no tax. Only `Posted` counts. `Cancelled` retains the voucher and its number, and contributes nothing.

### 4.2 The posting sequence

```
PostingService::post(voucher, actor)

  BEGIN TRANSACTION
    01  Lock the voucher row FOR UPDATE
    02  Re-assert state = Draft or Pending_Approval        else abort
    03  VALIDATE (§4.3) — every rule, all failures collected, not just the first
    04  Resolve the accounting period from voucher_date; assert it is Open
    05  Allocate the voucher number (§4.6)                 — first irreversible act
    06  Compute tax lines via TaxEngine, append to the line set
    07  Re-assert Σ Dr = Σ Cr on the final line set        else abort
    08  Persist lines; assert per-line dimension totals (§7.4)
    09  Create and allocate bill references (§6.4)
    10  Assert no bill reference outstanding went negative
    11  Write bank instrument details, if any
    12  Set status = Posted, posted_at, posted_by
    13  Increment affected ledger-period balance rows (§5.3)
    14  Write the audit record
    15  Emit AccountingVoucherPosted
  COMMIT
```

**Any failure aborts the whole transaction.** A partially posted voucher cannot exist (BRD BR-INTEGRITY-01).

### 4.3 Validation rules

| # | Rule | Failure |
|---|---|---|
| V-01 | At least two lines | Block |
| V-02 | At least one Dr and one Cr | Block |
| V-03 | Σ Dr = Σ Cr exactly | Block, showing the difference |
| V-04 | No line amount ≤ 0 | Block |
| V-05 | Every ledger active and not deleted | Block |
| V-06 | Voucher date within the financial year | Block |
| V-07 | Period Open (or Soft-Closed with the adjustment permission) | Block |
| V-08 | Date not in the future unless post-dated is set | Block |
| V-09 | Back-dating beyond the tolerance requires `acc.voucher.backdate` | Block |
| V-10 | Type-specific account rules (§4.4) | Block |
| V-11 | Required approvals present | Block |
| V-12 | Bill allocation complete for bill-wise parties | Block |
| V-13 | Cost centre allocation complete where required | Block |
| V-14 | Fund allocation complete where the ledger is fund-tracked | Block |
| V-15 | Restricted fund balance sufficient | Block or approve, per policy |
| V-16 | Credit limit not breached | Warn, approve or block, per policy |
| V-17 | Cash/bank balance not driven negative | Warn or block, per policy |
| V-18 | Required evidence attached | Block if the type requires it |
| V-19 | Duplicate candidate | Warn, with acknowledgement recorded |
| V-20 | Vendor bill number unique per vendor per year | Block |
| V-21 | Rounding within tolerance and posted to the rounding ledger | Block beyond tolerance |

### 4.4 Type rules

| Type | Must | Must not |
|---|---|---|
| Receipt | Debit a Cash/Bank/Clearing ledger | — |
| Payment | Credit a Cash/Bank/Clearing ledger | — |
| Contra | Touch only Cash/Bank ledgers | Touch Income or Expense |
| Journal | Have a narration | Touch Cash or Bank |
| Sales | Have a party; create a bill reference | — |
| Purchase | Have a party; create a bill reference | — |
| Credit Note | Have a reason | — |
| Debit Note | Have a reason | — |
| Memorandum | — | Ever post to the books |

Encoded as data on `acc_voucher_types` (`requires_party`, `creates_bill_reference`, `allowed_ledger_natures`, `forbidden_ledger_natures`, `requires_narration`, `requires_evidence`, …), so a new voucher type needs no code.

### 4.5 Cancellation and reversal

**Cancellation** — permitted only in an open period, with `acc.voucher.cancel`. Sets `is_cancelled`, reason, actor, time; releases bill allocations and restores outstandings; reverses balance increments; invalidates any reconciliation match and flags it; retains the number forever.

**Reversal** — creates a *new* voucher of the same type, dated in an open period, with every line's side inverted, linked to the original by `acc_voucher_references`. The original is untouched. This is the only lawful correction once a period is closed.

**Decision rule:**

| Situation | Action |
|---|---|
| Not posted | Edit |
| Posted, open period, wholly wrong | Cancel |
| Posted, open period, partly wrong | Reverse and re-enter |
| Posted, closed period | Reverse in an open period |
| Posted and reconciled | Reverse; re-open the reconciliation; elevated permission |
| Posted and inside a filed return | Reverse; flag the return for revision; elevated permission |

### 4.6 Numbering under concurrency

`acc_voucher_types.last_number` as a plain counter is a lost update: two concurrent posts read the same value and both write `n+1`. BRD BR-VNO-04 forbids it.

**Design:** a dedicated sequence table, one row per `(voucher_type, financial_year)`, incremented under a row lock inside the posting transaction:

```sql
SELECT next_number FROM acc_voucher_number_sequences
 WHERE voucher_type_id = ? AND financial_year_id = ?
   FOR UPDATE;                                    -- serialises concurrent posters
UPDATE acc_voucher_number_sequences
   SET next_number = next_number + 1 ...;
```

Held for microseconds at the very end of the transaction. A `UNIQUE (financial_year_id, voucher_type_id, voucher_number)` on `acc_vouchers` is the backstop: even if the application is wrong, the database refuses a duplicate.

Numbers are allocated **at posting, not at draft creation**, so abandoned drafts consume nothing and the series stays gapless (BR-VNO-02, BR-VNO-03).

---

## 5. Balance Derivation

The most important performance and correctness decision in the module.

### 5.1 The problem

BRD BR-LEDGER-02 and R-05 require balances to be **derived**. But a Trial Balance over 500,000 lines a year, ten years deep, cannot scan `acc_voucher_items` every time. And v4.3's stored `acc_ledgers.closing_balance` has no maintenance rule at all — nothing says when it changes, and nothing detects when it is wrong.

### 5.2 The design: period buckets

```
acc_ledger_period_balances
    ledger_id, financial_year_id, period_id,
    [cost_center_id, fund_id, campus_id]     ← nullable dimension slices
    opening_debit, opening_credit,
    period_debit, period_credit,
    closing_debit, closing_credit,
    last_voucher_item_id, last_rebuilt_at
```

One row per ledger per period (plus optional dimension slices). A ten-year, 2,000-ledger book is ~240,000 rows — trivial.

| Query | Path |
|---|---|
| Ledger balance as at a date | Closing of the last complete period + same-period lines to the date |
| Trial Balance for a period | One indexed scan of the period's rows |
| Balance Sheet / I&E | Aggregate period rows up the group tree |
| Ledger statement | Period opening + that period's lines |
| Cost-centre report | Dimension-sliced rows |

`acc_ledgers.closing_balance` is **removed**. A cached current balance, if wanted for the entry grid, lives in `acc_ledger_period_balances` for the current period, where its provenance is explicit.

### 5.3 Maintenance

**Incremental** — `PostingService` increments the affected `(ledger, period)` rows inside the posting transaction. Cancellation decrements. Nothing else touches them.

**Rebuild** — `php artisan acc:rebuild-balances {--from-year=} {--ledger=}` truncates and recomputes from `acc_voucher_items` alone, chunked, restartable, and safe to run on a live system.

### 5.4 The rebuild guarantee

> Deleting every row of `acc_ledger_period_balances` and rebuilding must produce byte-identical figures.

This is asserted nightly and after every release. It is what makes BRD R-05 real rather than aspirational.

### 5.5 Continuous assertions

`AssertionService`, hourly (BRD Enhancement E-01):

| Assertion | Failure means |
|---|---|
| Every posted voucher: Σ Dr = Σ Cr | The posting engine has a defect |
| Trial Balance: Σ Dr = Σ Cr for every period | Balance maintenance has drifted |
| Every ledger: bucket closing = Σ lines + opening | Increment logic is wrong |
| Every party: ledger balance = Σ open bill outstandings | Allocation is wrong |
| Balance Sheet balances at every period end | Group classification is wrong |
| Bill reference: allocated ≤ original | Allocation guard failed |
| Fund: opening + additions − utilisation = closing | Fund tracking is wrong |
| Voucher number series gapless per type per year | Numbering failed or a voucher vanished |
| Asset register net block = asset ledger balances | Asset accounting drifted |

Each failure names the offending record and raises an exception, not a log line.

---

## 6. Bill-Wise Accounting

### 6.1 The gap

BRD §17 requires nine rules of bill-wise behaviour. The current schema offers `acc_voucher_items.bill_reference VARCHAR(100)`. The ScreenDesign already documents the workaround — "allocating across N bills writes N voucher_items rows" — which corrupts the ledger line structure to carry allocation data, and still cannot express partial settlement across time.

### 6.2 The model

```
acc_bill_references                        the obligation
    ledger_id, reference_no, reference_date, due_date,
    original_amount, bill_type (Sales|Purchase|Advance|OnAccount|Opening),
    source_voucher_item_id, status, campus_id, fund_id

acc_bill_allocations                       the settlement
    bill_reference_id, voucher_item_id, allocation_type, amount, allocated_at
```

`outstanding = original_amount − Σ allocations`. **Derived**, never stored — with `acc_bill_reference_balances` as an optional maintained cache carrying the same rebuild guarantee as §5.4.

### 6.3 Allocation methods

| Method | Behaviour |
|---|---|
| **Against Reference** | Allocate to one or more existing open references |
| **New Reference** | Create a reference and allocate to it — a sales/purchase invoice |
| **Advance** | Create an advance reference to be adjusted later |
| **On Account** | Deliberately unallocated. Reportable and aged; never silent |

### 6.4 Allocation at posting

```
For each party line on a bill-wise ledger:
   1  Assert Σ allocations = line amount     (On Account counts as an allocation)
   2  For Against Reference:
        lock the reference row FOR UPDATE
        assert allocation ≤ outstanding      → else block (BR-BILL-07)
        insert acc_bill_allocations
        update reference status: Open → Partially_Settled → Settled
   3  For New Reference: create, then allocate
   4  For Advance: create an Advance reference, then allocate
   5  Assert the ledger's Σ outstanding = its ledger balance movement
```

Cancellation and reversal delete the allocations and restore each reference's status (BR-BILL-08).

### 6.5 Ageing

Computed from `due_date` (configurable to `reference_date`), bucketed by configuration, always reconciled to the control account. The party-vs-bill assertion in §5.5 is what guarantees BRD R-12.

---

## 7. Dimensions: Cost Centre, Fund, Campus

### 7.1 They are not the same thing

| Dimension | Question | Example |
|---|---|---|
| **Cost Centre** | *Where did the money go?* | Primary Wing, Science Department, Annual Day |
| **Fund** | *Whose money was it?* | Corpus, CSR Grant 2026, Building Fund |
| **Campus** | *Which unit?* | Main Campus, North Campus |

A single ₹50,000 lab-equipment purchase is: cost centre *Science Department*, fund *CSR Grant 2026*, campus *Main*. Collapsing these makes fund utilisation reporting impossible, which is why BRD BR-FUND-06 separates them explicitly.

### 7.2 Cost centres

`acc_cost_categories` (independent axes) → `acc_cost_centers` (hierarchical, one category each) → `acc_voucher_item_cost_centers` (allocation by amount or percentage).

**Rule:** where a ledger requires cost-centre allocation, the total per **category** must equal the line amount — independently for each category (BRD BR-CC-04). Allocating across two categories does not double the expense; it analyses the same amount twice.

### 7.3 Funds

`acc_funds` (type: Unrestricted / Restricted / Corpus / Designated; with restriction, grantor, period, sanctioned amount) → `acc_voucher_item_funds` (allocation).

`acc_fund_balances` is the maintained utilisation cache: opening, additions, utilisation, closing per fund per period — with the §5.4 rebuild guarantee and the §5.5 assertion.

Restricted overspend is checked at posting (V-15) and blocks or requires approval.

### 7.4 The allocation completeness rule

```
For every voucher line:
    for each dimension the ledger requires:
        Σ allocations within that dimension = line amount
    dimensions do not interact; each is checked independently
```

### 7.5 Campus

A column on `acc_vouchers`, inherited by lines, indexed on the balance buckets. Present from Phase 1 even though multi-campus is Phase 4 (BRD D-02) — adding a dimension to posted history later is far more expensive than carrying a mostly-constant column now.

---

## 8. Periods and Closing

### 8.1 Structure

`acc_financial_years` (1 Apr – 31 Mar) → `acc_accounting_periods` (twelve months, each with its own state).

| State | Create | Edit draft | Post | Cancel | Reverse |
|---|---|---|---|---|---|
| **Open** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Soft-Closed** | ✗ | ✗ | with permission | with permission | with permission |
| **Hard-Closed** | ✗ | ✗ | ✗ | ✗ | ✗ |

### 8.2 Close checklist

`acc_period_close_checklist` — one row per item per period, each with owner, state, evidence and whether it blocks.

| Item | Blocking |
|---|---|
| All vouchers posted (no drafts) | Yes |
| No pending approvals | Yes |
| Bank reconciliation complete for every bank ledger | Yes |
| Suspense balance zero | Yes |
| Unallocated On Account within tolerance | Warn |
| Depreciation posted (year-end) | Yes |
| Accruals and provisions posted | Warn |
| Statutory liabilities reconciled | Warn |
| Fee reconciliation with the Fees module zero | Yes |
| Fund utilisation within sanction | Yes |
| Exception list reviewed | Warn |
| Management review | Warn (year-end: Yes) |

### 8.3 Closing

```
1  Evaluate every blocking item; refuse and list failures if any
2  Freeze: write closing balances into acc_period_closing_balances (the immutable snapshot)
3  Set period state; record actor, time, and the figures as at that moment
4  Audit
```

The snapshot is what makes BRD AC-CLOSE-03 achievable: a closed period's Trial Balance is served from frozen figures, so it is identical whenever re-run, and does not depend on nothing having changed.

### 8.4 Year end

```
1  Hard-close all twelve periods
2  Post year-end adjustments (depreciation, accruals, provisions)
3  Compute surplus/deficit from Income and Expenditure groups
4  Post the closing journal: transfer surplus/deficit to the accumulated/corpus fund
5  Carry forward Asset, Liability and Equity closing balances as next-year opening balances
6  Income and Expenditure ledgers open the new year at zero
7  Carry forward every open bill reference with its original date and due date
8  Carry forward fund balances
9  Record the carry-forward: every opening balance names the closing balance it came from
```

Reopening a closed year re-runs steps 3–8 and supersedes — never edits — the prior carry-forward.

---

## 9. Tax Engine

### 9.1 Principle

Tax is **resolved from effective-dated configuration at posting time**, and the resolution is stored on the transaction. A later rate change cannot alter it (BRD BR-TAX-01).

### 9.2 Structure

```
acc_tax_types          CGST, SGST, IGST, CESS, TDS, TCS
acc_tax_rates          rate, effective_from, effective_to, HSN/SAC, interstate flag
acc_tax_rules          applicability: nature of payment, party type, threshold, section
acc_voucher_item_taxes the resolved outcome: taxable amount, rate, tax amount, rule id
```

Resolution: transaction context → candidate rules effective on the voucher date → most specific match → compute → produce lines → **store the rule and rate used** on `acc_voucher_item_taxes`.

### 9.3 TDS

```
1  Is the ledger TDS-applicable? Which section?
2  Does the payee have a valid lower/nil certificate covering this date and amount?
3  Has the annual threshold for this payee and section been crossed?
        cumulative = Σ prior credits/payments this year for this payee+section
4  Rate = certificate rate, else section rate, else higher rate for missing PAN
5  TDS = round(taxable × rate)
6  Lines:  Dr Expense (gross) · Cr Party (net) · Cr TDS Payable (tds)
7  Record against the certificate's consumed limit
```

`acc_tds_deductions` (one row per deduction, linked to its voucher item) and `acc_tds_payments` (challan detail, matched to the deductions it covers) make BRD BR-TDS-06 a query, not a spreadsheet.

### 9.4 GST

Applied selectively (BRD §45). Supply classification and place of supply determine the split; ineligible input credit is expensed rather than claimed; reverse charge produces a separate liability. Return data is composed from `acc_voucher_item_taxes` and must reconcile to the tax ledger movement — asserted, not assumed.

---

## 10. Integration

### 10.1 Contract

Other modules **never write accounting tables**. They emit events. The engine converts them.

```
Module event ──► acc_event_processing_log (Pending)
                        │
                        ▼
             resolve acc_module_events → acc_event_voucher_configs
                        │                        │
                  not configured?           configured
                        ▼                        ▼
                    Skipped                 build lines from
                  (reported)          acc_event_voucher_line_templates
                                             │
                                             ▼
                                    PostingService::post()
                                             │
                            ┌────────────────┼────────────────┐
                            ▼                ▼                ▼
                       Processed          Failed          Skipped
                     (voucher_id)      (retry ≤ N,       (duplicate
                                        then escalate)      guard)
```

### 10.2 Idempotency

```
UNIQUE (module_event_id, source_model, source_id, source_event_uid)
   on acc_event_processing_log, where status = 'Processed'
```

Replaying a day of events produces nothing new. `source_event_uid` lets a source legitimately fire the same event twice for the same record when the business means it (an allocation genuinely changed twice), while a mere replay does not.

### 10.3 Reconciliation

`acc_module_reconciliation` — per module, per period: source total, posted total, difference, unposted count, failed count. Nightly.

**This is the control that catches everything else.** If the Fees module says ₹42,00,000 collected in August and Accounting says ₹41,85,000, the difference is itemised to the receipt, the same night — not at audit (BRD BR-INT-06, K-04).

### 10.4 Failure handling

Retry with backoff to a configured limit, then escalate to a person with the payload retained. Unconfigured events queue and are reported with count and age. Nothing is dropped, and nothing is guessed at (BRD BR-INT-04).

---

## 11. Banking and Reconciliation

### 11.1 Instruments

`acc_voucher_bank_details` — one row per bank voucher: transaction type (Cheque, NEFT, RTGS, IMPS, UPI, DD, Card, Cash), instrument number, instrument date, bank value date, favouring name, cheque-book leaf.

v4.3 squeezes this into `reference_number` / `reference_date`, and the ScreenDesign already flags it (§16.2 #3). Structured data is required for cheque tracking, reconciliation matching and printing.

### 11.2 Cheque lifecycle

`acc_cheque_registers` + `acc_cheque_leaves` (stock and issue tracking) + `acc_cheque_transactions` (status history: Issued → Presented → Cleared, with Bounced / Stopped / Cancelled / Stale).

A bounce posts a reversal of the settlement, restores the bill outstanding, and posts any bank charge separately (BRD BR-CHEQUE-04).

### 11.3 Reconciliation

```
Import  → acc_bank_statement_entries (staging; affects NO balance)
Propose → acc_bank_reconciliation_matches with a confidence
Confirm → a person accepts; only then is the voucher item marked reconciled
Explain → residual differences itemised on the reconciliation statement
```

Matching score:

```
0.40  exact amount and side
0.25  date within the tolerance window (default ±3 days)
0.20  instrument number appears in the narration
0.10  party name similarity
0.05  a previously confirmed match for the same counterparty pattern

≥ 0.90  propose, pre-selected
0.60–0.89  propose
< 0.60  leave unmatched
```

Auto-confirmation only on an exact amount + instrument number match, and only when the school has enabled it (BRD BR-BRS-03).

Import idempotency: `UNIQUE (reconciliation_id, statement_row_hash)`, so re-importing the same file adds nothing (BR-BRS-07).

---

## 12. Reporting

### 12.1 Strategy

| Report class | Source | Why |
|---|---|---|
| Statements (TB, BS, I&E) | `acc_ledger_period_balances` | Aggregates over ~240k rows, not ~5M lines |
| Closed-period statements | `acc_period_closing_balances` | Frozen; reproducible by construction |
| Registers, Day Book, ledger statements | `acc_voucher_items`, always date-filtered | Detail is inherently detailed |
| Outstanding and ageing | `acc_bill_references` + allocations | Derived, asserted |
| Cost centre / fund | Dimension-sliced balance buckets | Same aggregate path |
| Exceptions | Purpose-built queries | Each names its records |

### 12.2 Views delivered

`vw_ledger_balances` · `vw_trial_balance` · `vw_balance_sheet` · `vw_income_expenditure` · `vw_day_book` · `vw_ledger_statement` · `vw_party_outstanding` · `vw_receivable_ageing` · `vw_payable_ageing` · `vw_bill_reconciliation` · `vw_cost_center_summary` · `vw_fund_utilisation` · `vw_bank_reconciliation_status` · `vw_cheque_register` · `vw_budget_variance` · `vw_tds_summary` · `vw_tax_summary` · `vw_fixed_asset_register` · `vw_voucher_audit_trail` · `vw_accounting_exceptions` · `vw_module_reconciliation` · `vw_period_close_status`

### 12.3 Drill-down

Every figure carries the filter needed to reach the next level:

```
Balance Sheet → Group → Sub-group → Ledger → Voucher → Line → Evidence
```

Four clicks from any statement figure to the vouchers behind it (BRD AC-FS-03).

---

## 13. Security

| Control | Implementation |
|---|---|
| Tenancy | Database-per-tenant. No `acc_*` table exists in `prime_db` |
| Permissions | Granular slugs — `acc.voucher.post`, `acc.period.close`, `acc.fund.reallocate`, … — checked in every service entry point, not in controllers |
| Segregation of duties | Enforced in `ApprovalService`; reported by the SoD analyser (E-04) |
| Auditor role | Read-only by construction: no write permission exists to grant |
| Audit immutability | `acc_audit_logs` has no update or delete path; the application DB user holds no `UPDATE`/`DELETE` grant on it |
| Bank details | Separately permissioned; masked by default; every view logged |
| Sensitive changes | Bank account, IFSC, approval thresholds require four-eyes (E-05) |
| Evidence | Served through an authorising controller; never a public path |
| Data to AI | Aggregates and structure only. No donor identity, no bank number, no student PII |

---

## 14. Non-Functional

### 14.1 Sizing (per tenant, 10 years)

| Entity | Volume |
|---|---|
| Ledgers | 2,000–10,000 (student ledgers dominate) |
| Vouchers/year | 50,000–200,000 |
| Voucher lines/year | 150,000–600,000 |
| Voucher lines, 10 years | 1.5M–6M |
| Bill references/year | 30,000–150,000 |
| Bill allocations/year | 50,000–250,000 |
| Ledger period balances | ~240,000 |
| Audit rows | 5M–20M |

### 14.2 Targets

| Operation | Target | Method |
|---|---|---|
| Voucher post | < 300 ms | One transaction, bounded increments |
| Ledger picker search | < 200 ms | Prefix index + covering index |
| Ledger balance as at date | < 150 ms | Period bucket + partial period |
| Trial Balance | < 1.5 s | One indexed scan of balance rows |
| Balance Sheet / I&E | < 2 s | Aggregate up the group tree |
| Day Book (one day) | < 500 ms | `(voucher_date, status)` index |
| Ledger statement (one year) | < 1.5 s | `(ledger_id, voucher_date)` index |
| Outstanding / ageing | < 2 s | Bill reference index |
| Bank reconciliation screen | < 2 s | Staged rows, filtered |
| Balance rebuild, 5M lines | < 30 min | Chunked, offline-safe |

### 14.3 Indexing principles

1. Every foreign key indexed.
2. `acc_voucher_items` leads with `(ledger_id, voucher_id)` and carries a covering index for balance aggregation.
3. `acc_vouchers` indexed on `(financial_year_id, voucher_date, status)`, `(voucher_type_id, voucher_number)`, `(status, voucher_date)`.
4. Bill references indexed on `(ledger_id, status, due_date)` — the ageing path.
5. Partial-period aggregation never scans a whole year.
6. `acc_voucher_items` is a partitioning candidate by `financial_year_id` past ~5M rows; the design stays partition-ready.

### 14.4 Backup and recovery

Nightly full plus binlog. Financial data is the highest-value data in the platform. RPO 1 hour, RTO 4 hours. Monthly restore rehearsal. Balance rebuild after every restore, with the §5.4 assertion as the acceptance test.

---

## 15. Screen Inventory

Voucher-entry screens are specified in `ScreenDesign_v2.1.md` (VE-00 … VE-11, VE-S1 … VE-S6). This design adds the rest.

| # | Screen | Phase |
|---|---|---|
| 1 | Accounting Dashboard | 1 |
| 2 | Account Groups (tree) | 1 |
| 3 | Ledgers — list, create, edit | 1 |
| 4 | Ledger Statement | 1 |
| 5 | Financial Years and Periods | 1 |
| 6 | Voucher Types and Numbering | 1 |
| 7 | Voucher Entry (VE-00…VE-11) | 1 |
| 8 | Opening Balances | 1 |
| 9 | Trial Balance | 1 |
| 10 | Balance Sheet | 1 |
| 11 | Income & Expenditure | 1 |
| 12 | Day Book | 1 |
| 13 | Audit Trail | 1 |
| 14 | Bill-wise Outstanding | 1 |
| 15 | Cash & Bank Book | 2 |
| 16 | Cheque Register | 2 |
| 17 | Bank Reconciliation | 2 |
| 18 | Statement Import & Mapping | 2 |
| 19 | Receivables + Ageing | 2 |
| 20 | Payables + Ageing | 2 |
| 21 | Cost Categories and Centres | 2 |
| 22 | Cost Centre Reports | 2 |
| 23 | Pending Approvals | 2 |
| 24 | Period Close Cockpit | 2 |
| 25 | Year-End Processing | 2 |
| 26 | Module Reconciliation | 2 |
| 27 | Student Financial Statement | 2 |
| 28 | Funds — master and utilisation | 3 |
| 29 | TDS Register, Certificates, Challans | 3 |
| 30 | GST Register and Return Data | 3 |
| 31 | Donations and 80G Receipts | 3 |
| 32 | Grants and Utilisation Certificates | 3 |
| 33 | Fixed Asset Register | 3 |
| 34 | Depreciation Run | 3 |
| 35 | Budgets and Variance | 3 |
| 36 | Recurring Templates | 3 |
| 37 | Expense Claims | 3 |
| 38 | Cash Flow / Fund Flow / Ratios | 3 |
| 39 | Exception Dashboard | 3 |
| 40 | Compliance Calendar | 3 |
| 41 | Reconciliation Cockpit | 3 |
| 42 | Multi-Campus Consolidation | 4 |
| 43 | Payment Run | 4 |
| 44 | Tally Export | 4 |
| 45 | AI Suggestions Review | 4 |
| 46 | Auditor Workspace | 4 |

---

## 16. Key Workflows

**W-01 Manual voucher** — select type → header → lines with live balances → sub-screens (bill-wise, cost centre, fund, bank) → save draft → submit → approve if required → post → numbered, balances updated, audited.

**W-02 Fee collection (integrated)** — Fees records a collection → event → engine resolves config → Dr Bank, Cr Student → allocated to the demands the parent paid against → posted → reconciliation confirms Fees and Accounting agree that night.

**W-03 Vendor bill to payment** — Purchase voucher creates the bill reference and computes TDS → approval → posted → appears in payables ageing → payment run selects it → payment voucher allocates against it → reference closes → cheque tracked to clearing → reconciled.

**W-04 Bank reconciliation** — import statement → staged → auto-propose with confidence → accountant confirms or rejects each → residuals itemised → adjusting vouchers created deliberately → statement balances to the bank → period item cleared.

**W-05 Month close** — cockpit shows blockers → accountant clears each → close → closing balances frozen → period hard-closed → statements reproducible forever.

**W-06 Restricted grant** — grant sanctioned → fund created with its restriction → receipt allocated to the fund → expenditure allocated to the fund and to a cost centre → overspend blocked → utilisation certificate generated from posted vouchers.

**W-07 Correction after close** — error found in a closed period → reversal dated in the open period, referencing the original → correct entry posted → both visible → prior-period statements unchanged.

---

## 17. The Database Design

### 17.1 Defects corrected from `Accounting_DDL_v4.3.sql`

Found by reading v4.3 against the BRD and against the deployed schema. **Items 1–9 prevent the script from executing.**

| # | Defect | Location | Effect | Fix in v4.4 |
|---|---|---|---|---|
| 1 | FKs `fk_vc_debit_ledger` / `fk_vc_credit_ledger` reference `debit_ledger_id` / `credit_ledger_id`, which are **not declared** | `acc_voucher_category` | **`CREATE TABLE` fails** | Columns declared, or FKs removed |
| 2 | FK to `tco_app_modules`, a table that **does not exist** (the module registry moved to `glb_app_modules`, keyed `VARCHAR(10)`) | `acc_voucher_category` | **FK creation fails** | References `glb_app_modules`.`key` |
| 3 | `ON DELETE SET NUL` — misspelt | `acc_cost_centers` | **Syntax error; the file stops parsing here** | `SET NULL` |
| 4 | Indexes and an FK on `source_module`, `cost_center_id`, `date` — **none of the three columns is declared** (they exist in the *deployed* table; the column list was edited and the index list was not) | `acc_vouchers` | **`CREATE TABLE` fails** | Index list matches the column list |
| 5 | Index and FK on `cost_center_id`, **not declared** | `acc_voucher_items` | **`CREATE TABLE` fails** | Removed; allocation lives in the child table |
| 6 | Index and FK on `voucher_id`, which is **commented out** | `acc_fixed_assets` | **`CREATE TABLE` fails** | Column declared |
| 7 | ~45 lines of **raw non-comment text** (``` `acc_voucher.voucher_prefix` = "PAY-" ```) in the expense-claim section | after `acc_expense_claim_lines` | **Syntax error** | Moved into comments |
| 8 | Constraint `fk_acc_rtl_template` and index `idx_acc_rtl_template` declared in **two different tables** | `acc_recurring_template_lines`, `acc_recurring_transaction_log` | **Duplicate FK name — schema-wide uniqueness violated** | Distinct names |
| 9 | **12 foreign keys join columns of different integer widths** — `voucher_type_id` TINYINT vs MEDIUMINT; `ledger_id` INT vs MEDIUMINT; `voucher_id` BIGINT vs INT; `fixed_asset_id` BIGINT vs INT; `financial_year_id` TINYINT vs SMALLINT | 8 tables | **InnoDB rejects every one of them** | One width per concept, everywhere |
| 10 | `UNIQUE (code, deleted_at)` as a soft-delete-aware key. MySQL treats NULLs as distinct, so **unlimited live duplicates are permitted** | 6 tables | Duplicate live asset codes, claim numbers, event codes | Generated `is_deleted` column inside the unique key |
| 11 | A single generic status table with a plain FK from every entity | `acc_accounting_status_masters` | A voucher's status can point at an `ExpenseClaimStatus` row; nothing prevents it | Per-entity `ENUM`s for closed sets; typed status tables where extensibility is needed |
| 12 | `acc_ledgers.closing_balance` / `opening_balance` stored with **no stated maintenance rule** | `acc_ledgers` | Violates BRD BR-LEDGER-02 and R-05; will drift silently | Derived via `acc_ledger_period_balances` (§5) |
| 13 | `last_number` incremented on the type row | `acc_voucher_types` | **Lost update** — two concurrent posts take the same number | Locked sequence table + `UNIQUE` backstop (§4.6) |
| 14 | `bill_reference VARCHAR(100)` on the line | `acc_voucher_items` | BRD §17 (nine rules) is **unimplementable** | `acc_bill_references` + `acc_bill_allocations` (§6) |
| 15 | No currency anywhere | schema-wide | BRD §39 unimplementable | Currency and rate columns; `acc_currencies`, `acc_exchange_rates` |
| 16 | Comment: an optional voucher "should be considered in financial reports but should not be posted to ledgers" | `acc_vouchers` | **Contradicts BRD BR-PROV-01** and v1's own BR-OPT-02 | Corrected: provisional appears in no statement |
| 17 | `is_cancelled` as a flag beside `status` | `acc_vouchers` | Two sources of truth for one state; they can disagree | Single `status` including `Cancelled` |
| 18 | No accounting period entity — only financial years | schema-wide | BRD §9 (eight rules) unimplementable; monthly close impossible | `acc_accounting_periods` + closing snapshots |
| 19 | No audit table at all | schema-wide | BRD §30 (six rules) unimplementable; the module is unauditable | `acc_audit_logs`, append-only |
| 20 | Header says `Version: 4.2` in the file named v4.3; and the deployed tenant schema has **drifted from this text** (`date` vs `voucher_date`, different PK widths, extra columns) | file | v4.3 neither creates the deployed schema nor matches it | Corrected; §18 states the migration |

### 17.2 What v4.4 adds

| Area | New tables |
|---|---|
| Periods | `acc_accounting_periods`, `acc_period_closing_balances`, `acc_period_close_checklist` |
| Numbering | `acc_voucher_number_sequences` |
| Balances | `acc_ledger_period_balances`, `acc_opening_balances` |
| Bill-wise | `acc_bill_references`, `acc_bill_allocations` |
| Dimensions | `acc_cost_categories`, `acc_funds`, `acc_fund_balances`, `acc_voucher_item_funds`, `acc_campuses` |
| Voucher detail | `acc_voucher_bank_details`, `acc_voucher_references`, `acc_voucher_approvals`, `acc_voucher_item_taxes` |
| Banking | `acc_cheque_registers`, `acc_cheque_leaves`, `acc_cheque_transactions`, `acc_bank_reconciliation_matches` |
| Tax | `acc_tax_rules`, `acc_tds_deductions`, `acc_tds_certificates`, `acc_tds_payments` |
| School | `acc_donations`, `acc_grants`, `acc_concessions` |
| Control | `acc_audit_logs`, `acc_approval_policies`, `acc_exceptions`, `acc_module_reconciliation`, `acc_assertion_results` |
| Currency | `acc_currencies`, `acc_exchange_rates` |
| Budgets | `acc_budget_lines` (revisions and dimensions) |

### 17.3 Deliberate omissions

| Not included | Why |
|---|---|
| Database triggers | Balances are maintained by an explicit, testable service. Triggers hide behaviour and slow the hot path |
| Stored procedures | Business logic belongs in version-controlled, testable services |
| Inventory tables | The Inventory module owns stock; Accounting records only its financial effect |
| VAT / CST / Service Tax / Excise | Dead regimes (BRD §45) |
| Physical partitioning, initially | `acc_voucher_items` becomes a candidate past ~5M rows; the design stays partition-ready and §14.3 records the trigger |

---

## 18. Migration

The deployed tenant schema differs from the v4.3 text — different primary-key widths, `date` rather than `voucher_date`, and columns present in production that v4.3 does not declare. Data volumes are small today (16 ledgers, 5 vouchers, 10 lines in the reference tenant), which makes this the cheapest moment this migration will ever be.

| Step | Action | Reversible |
|---|---|---|
| 1 | Full backup of every tenant database | — |
| 2 | Reconcile the text to production: adopt the deployed widths where they are already the wider and correct choice | Yes |
| 3 | Normalise every FK to one width per concept (§17.1 #9); drop and recreate the affected constraints | Yes |
| 4 | Fix the fatal defects — items 1–8 | Yes |
| 5 | Replace `UNIQUE(code, deleted_at)` with the generated-column pattern; **report** existing duplicates rather than deleting them | Yes |
| 6 | Create the new tables (§17.2) | Yes |
| 7 | Backfill `acc_accounting_periods` for every existing financial year | Yes |
| 8 | Migrate `acc_voucher_items.bill_reference` text into `acc_bill_references` + `acc_bill_allocations`; report every row that cannot be resolved | Yes |
| 9 | Migrate `acc_voucher_items.cost_center_id` into `acc_voucher_item_cost_centers` (100% allocation) | Yes |
| 10 | Migrate `reference_number`/`reference_date` on bank vouchers into `acc_voucher_bank_details` | Yes |
| 11 | Build `acc_ledger_period_balances` from `acc_voucher_items`; **compare against `acc_ledgers.closing_balance` and report every difference** — do not overwrite silently | Yes |
| 12 | Only after step 11 reports clean: drop `acc_ledgers.closing_balance` and `opening_balance` | Yes |
| 13 | Consolidate `is_cancelled` into `status` | Yes |
| 14 | Seed the school chart of accounts, voucher types, statuses and approval policies | Yes |
| 15 | Run the full assertion suite (§5.5); refuse to proceed on any failure | — |
| 16 | Set the schema version to 4.4 | — |

**Step 11 is the one that matters.** Any difference between the stored balance and the derived balance is a pre-existing defect. Finding it now, at 10 voucher lines, is free. Finding it at 500,000 is a forensic exercise.

---

## 19. Implementation Roadmap

| Phase | Weeks | Delivers | Definition of done |
|---|---|---|---|
| **0 — Foundation** | 1–3 | Schema v4.4, seeds, permissions, audit, module scaffolding | The DDL executes clean and re-runs idempotently; audit captures every write |
| **1 — The books** | 4–12 | Groups, ledgers, periods, voucher types, numbering, posting engine, all nine types, bill-wise, opening balances, balance derivation, TB/BS/I&E, Day Book, ledger statements | An accountant keeps a full month of books; the Trial Balance balances; every assertion passes |
| **2 — Operations** | 13–22 | Cash/bank, cheques, statement import and reconciliation, receivables and payables, cost centres, approvals, cancel/reverse, period close, year end, Fees integration, concessions | A month closes in under 10 days with the bank reconciled and Fees agreed |
| **3 — Compliance** | 23–34 | Funds, TDS, GST, 80G, grants, fixed assets, depreciation, budgets, recurring, expense claims, Payroll and Vendor integration, cash flow, exceptions | A statutory audit completes from the system; returns are prepared from the books |
| **4 — Reach** | 35–44 | Interest, credit limits, multi-currency, multi-campus, scenarios, payment runs, Tally export, AI | Forward-looking decisions, not only backward-looking records |

Phases 0–2 are the minimum viable accounting system. Phase 3 is what makes it auditable and compliant.

---

## 20. Open Decisions

Everything else in this document is decided. These need the business owner's confirmation before the phase that depends on them.

| ID | Decision | Recommendation | Needed by |
|---|---|---|---|
| **OD-01** | Confirm BRD D-31: fee income recognised on demand (accrual) | Accrual. Configurable to cash | Phase 1 |
| **OD-02** | Carry `campus_id` from Phase 1 even though multi-campus is Phase 4? | **Yes.** Adding a dimension to posted history later is far more expensive | Phase 1 |
| **OD-03** | Same question for `fund_id` | **Yes**, for the same reason | Phase 1 |
| **OD-04** | Should `acc_ledger_period_balances` slice by dimension, or only by ledger and period? | Ledger+period in Phase 1; dimension slices in Phase 2, behind a setting | Phase 1 |
| **OD-05** | Back-dating tolerance without elevated permission | 7 days within an open period | Phase 1 |
| **OD-06** | Approval thresholds | Payments > ₹50,000; journals > ₹25,000; all credit notes and write-offs. School-configurable | Phase 2 |
| **OD-07** | Negative cash: block or warn by default? | **Block**, overridable with permission | Phase 1 |
| **OD-08** | Auto-confirm exact bank matches? | Off by default. Opt-in per school | Phase 2 |
| **OD-09** | Student ledger per student, or per family? | **Per student**, with a family roll-up view. Fee liability is per student | Phase 1 |
| **OD-10** | Are student ledgers created for every student, or on first transaction? | On admission. 3,000 mostly-nil ledgers cost nothing and avoid a race at first receipt | Phase 1 |
| **OD-11** | Rounding tolerance per voucher | ₹1 | Phase 1 |
| **OD-12** | Retain `acc_accounting_status_masters` for user-extensible statuses? | Retain only for genuinely extensible sets. Voucher status becomes an `ENUM` | Phase 0 |
| **OD-13** | Depreciation: monthly or annual? | Annual at year end, with a monthly option | Phase 3 |
| **OD-14** | GST registration expected for the pilot schools? | Assume not; build the capability behind a flag | Phase 3 |
| **OD-15** | Tally export scope | Masters and vouchers, export only, XML | Phase 4 |
| **OD-16** | Do we migrate historical vouchers at go-live? | **No.** Opening balances and open bills only (BRD D-50) | Phase 1 |

---

## 21. Traceability — BRD to Solution

| BRD area | Solution section | Principal tables |
|---|---|---|
| §5 School context | §7.3, §7.5 | `acc_funds`, `acc_campuses` |
| §9 Periods | §8 | `acc_accounting_periods`, `acc_period_closing_balances` |
| §10 Groups | §3.1 | `acc_account_groups` |
| §11 Ledgers | §5 | `acc_ledgers`, `acc_ledger_period_balances` |
| §12 Opening balances | §8.4 | `acc_opening_balances` |
| §13 Vouchers | §3.1, §4 | `acc_vouchers`, `acc_voucher_items` |
| §14 Posting model | §4 | `PostingService` |
| §15 Numbering | §4.6 | `acc_voucher_number_sequences` |
| §16 Voucher types | §4.4 | `acc_voucher_types` |
| §17 Bill-wise | §6 | `acc_bill_references`, `acc_bill_allocations` |
| §18 Cost centres | §7.2 | `acc_cost_categories`, `acc_voucher_item_cost_centers` |
| §19–§21 Banking | §11 | `acc_voucher_bank_details`, `acc_cheque_*`, `acc_bank_*` |
| §22 Receivables/payables | §6.5 | `acc_bill_references` |
| §23–§24 Fees, concessions | §10 | `acc_concessions` |
| §25 Funds | §7.3 | `acc_funds`, `acc_fund_balances`, `acc_voucher_item_funds` |
| §28 Approval | §4.2 | `acc_approval_policies`, `acc_voucher_approvals` |
| §29 Correction | §4.5 | `acc_voucher_references` |
| §30 Audit | §13 | `acc_audit_logs` |
| §34 Budgets | §12 | `acc_budgets`, `acc_budget_lines` |
| §35 Fixed assets | §12 | `acc_fixed_assets`, `acc_depreciation_entries` |
| §39 Multi-currency | §3.2 | `acc_currencies`, `acc_exchange_rates` |
| §44 Period close | §8.2–§8.4 | `acc_period_close_checklist` |
| §45–§47 Tax | §9 | `acc_tax_rules`, `acc_voucher_item_taxes`, `acc_tds_*` |
| §48–§49 Donations, grants | §12 | `acc_donations`, `acc_grants` |
| §50–§51 Statements | §12 | `vw_*` |
| §52 Integration | §10 | `acc_module_events`, `acc_event_*`, `acc_module_reconciliation` |
| §53 Exceptions | §5.5 | `acc_exceptions`, `acc_assertion_results` |
| §55 Security | §13 | permissions |

---

## 22. Design Principles — the short version

1. **The voucher line is the only truth.** Everything else is derived and rebuildable.
2. **Posted is immutable.** Correct by reversal, never by edit.
3. **One writer.** `PostingService` is the sole path into the books.
4. **Closed means closed**, and a closed period's figures are frozen, not merely protected.
5. **Dimensions are orthogonal.** Cost centre, fund and campus answer different questions.
6. **Configuration is data.** Rates, thresholds, mappings and rules are rows.
7. **Refuse rather than guess.** Ambiguity queues for a person.
8. **Assert continuously.** Corruption should surface in an hour, not at year end.
9. **Every figure is drillable** to the vouchers behind it.
10. **The schema serves the questions in BRD §61.1.** If a question cannot be answered from it, the schema is wrong — not the question.

---

**End of Solution_Design_v1.md**
