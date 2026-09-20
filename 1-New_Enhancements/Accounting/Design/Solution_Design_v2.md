# Prime-AI Accounting Module — Solution Design v2

**Document ID:** ACC-SD-V2  
**Version:** 2.0  
**Governed by:** `Accounting_BRD_v2.md` (v2.0)  
**Realised by:** `Accounting_DDL_v4.8.sql` (v4.8)  
**Aligned with:** `Dictionary_DDL_v4.8.md` (v4.8) & `ScreenDesign_v2.1.md` (v2.1)  
**Status:** Approved Technical Architecture & Design Document  
**Date:** 2026-09-15  

---

## 0. Document Control

### 0.1 Position

| Layer | Document | Answers |
|---|---|---|
| Business | `Accounting_BRD_v2.md` | What does the institution/school need, and why |
| **Solution** | **This document (`Solution_Design_v2.md`)** | How does the system work, what formulas govern calculations, and how are processes executed |
| Physical Data | `Accounting_DDL_v4.8.sql` | How is the information structured and stored in MySQL |
| Data Dictionary | `Dictionary_DDL_v4.8.md` | Comprehensive column-level specification, rules, keys, and edge cases |
| Interaction | `ScreenDesign_v2.1.md` | How voucher entry, reconciliation, and reports are presented |

### 0.2 Scope & Enhancements in Version 2.0

Version 2.0 expands upon Version 1.0 to reflect the complete schema definitions of `Accounting_DDL_v4.8.sql` and `Dictionary_DDL_v4.8.md`. Key additions include:
1. **Complete Mathematical Calculation Engine**: Explicit mathematical formulas for all derived fields, balance calculations, WDV/SLM depreciation, interest computations across day-count conventions, bank reconciliation difference equations, match-scoring algorithms, tax/TDS calculations, budget breach thresholds, and fund utilization.
2. **End-to-End Process Flows**: Detailed operational workflows and decision logic for all accounting transactions (Voucher Processing, Bill Allocation, Period Close, Bank Reconciliation, Asset Depreciation & Disposal, Recurring Voucher Schedule Execution, Cross-Module Event Integration, Budget Monitoring, and Interest Accrual).
3. **Physical Schema Realization**: Alignment with all tables, triggers, generated columns, null-safe unique markers (`cc_marker`, `fund_marker`, `campus_marker`, `period_marker`), junction tables (e.g., `acc_bill_allocations_jnt`), and assertions in `Accounting_DDL_v4.8.sql`.

---

## 1. Architectural Overview & Design Tenets

### 1.1 In One Paragraph

The Accounting Module is a **Laravel 12 / MySQL 8 tenant-scoped module** in the Prime-AI platform. It implements Tally-style double-entry bookkeeping on a **voucher header + Dr/Cr lines** model. Everything in the module is strictly derived from posted voucher lines (`acc_voucher_items`): ledger period balances, party outstandings, financial statements (Trial Balance, Balance Sheet, Income & Expenditure), tax positions, asset net block, and fund utilization. Nothing is independently asserted. A central **Posting Engine (`PostingService`)** is the sole writer of accounting effect — it validates, numbers, allocates, posts, and audits within a single database transaction, refusing any transaction that violates double-entry rules or period lock constraints. Other Prime-AI modules (Fees, Transport, Hostel, Payroll, Vendor, Library) do not write accounting data directly; they emit domain events, which a rules engine converts into vouchers idempotently and reconcilably.

### 1.2 System Context Diagram

```
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │  Fees · Library · Transport · Hostel · Payroll · Vendor · Fixed Assets      │
  └───────────────────────────────┬─────────────────────────────────────────────┘
                                  │ domain events (never direct DB writes)
                                  ▼
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                       ACCOUNTING MODULE                                     │
  │                                                                             │
  │   Event Engine ──► Posting Engine ──► Ledger Lines (acc_voucher_items)      │
  │                          │                      │                           │
  │                          │                      ├──► Period Balances        │
  │                          │                      ├──► Bill References & Jnt  │
  │                          ├──► Audit Trail       ├──► Dimension Slices       │
  │                          └──► Auto-Numbering    └──► Tax & Statutory Dues   │
  │                                                                             │
  │   Reconciliation · Period Close · Budget Engine · Depreciation · Reports    │
  └─────────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
              Trial Balance · Balance Sheet · Income & Expenditure
              Party Ageing · Fund Utilisation · Tax & Statutory Summaries
```

### 1.3 Core Design Tenets

| # | Tenet | Consequence in the System Design |
|---|---|---|
| **T-01** | **The voucher line is the only truth** | Every balance, statement, and bill outstanding is derived from `acc_voucher_items`, and can be completely rebuilt from it. |
| **T-02** | **Posted is immutable** | No `UPDATE` or `DELETE` is ever permitted on a posted voucher line by anyone (including Super Admin). Corrections require a reversing voucher. |
| **T-03** | **One writer (`PostingService`)** | Only `PostingService` may create accounting effect. No controller, observer, background job, or seeder directly inserts voucher lines. |
| **T-04** | **Derived data is a cache with a rebuild guarantee** | Every summary/cache table (`acc_ledger_period_balances`, `acc_bill_reference_balances`, `acc_fund_balances`) has an artisan rebuild command (`acc:rebuild-balances`) and a continuous assertion check. |
| **T-05** | **Dimensions are orthogonal** | Cost centre, fund, and campus are separate analysis axes and never substitute for one another. |
| **T-06** | **Configuration is data** | Tax rates, approval thresholds, numbering sequences, event mappings, and ageing bucket edges are stored rows in `acc_settings`, not hardcoded in application logic. |
| **T-07** | **Refuse rather than guess** | Any ambiguous transaction or unbalanced entry queues for human review; nothing is silently assumed or rounded away beyond tolerance. |
| **T-08** | **Everything is attributable** | Every write records the actor (user or identified system process), timestamp, and client IP in an append-only audit log (`acc_audit_logs`). |

---

## 2. Core Posting Engine Architecture

### 2.1 Posting Transaction Pipeline

The `PostingService` executes all voucher postings within a single MySQL InnoDB ACID transaction (`DB::transaction`).

```
[ Input Payload ]
       │
       ▼
 [ 1. Validation Phase ] ──► Check Dr=Cr, Dates, Closed Periods, Status, Permissions
       │ (Pass)
       ▼
 [ 2. Sequence Lock ]    ──► SELECT FOR UPDATE on acc_voucher_number_sequences
       │                     Generate display_number
       ▼
 [ 3. Insert Header ]    ──► Insert acc_vouchers (Status = 'Posted')
       │
       ▼
 [ 4. Insert Items ]     ──► Insert acc_voucher_items (Dr/Cr lines)
       │
       ▼
 [ 5. Insert Dimensions ]──► Insert acc_voucher_item_cost_centers & acc_voucher_item_funds
       │
       ▼
 [ 6. Maintain Caches ]  ──► Update acc_ledger_period_balances, acc_bill_reference_balances,
       │                     acc_fund_balances
       ▼
 [ 7. Write Audit Log ]  ──► Insert acc_audit_logs (Append-only)
       │
       ▼
[ COMMIT TRANSACTION ]
```

### 2.2 Validation Rules (Pre-Posting Checks)

Before acquiring locks or writing data, `PostingService` validates the following:
1. **Mathematical Equality:** $\sum \text{Debit Amount} = \sum \text{Credit Amount}$ (within rounding tolerance $\le \text{posting.rounding\_tolerance}$).
2. **Non-Negative Amounts:** Every line amount $> 0.00$.
3. **Period Open State:** `voucher_date` falls inside an `Open` period (`acc_accounting_periods.status = 'Open'`). If `Soft-Closed`, checks for `acc.period.adjust` permission. If `Hard-Closed`, refuses outright.
4. **Ledger Active State:** All referenced ledgers must have `is_active = 1` and `deleted_at IS NULL`.
5. **Cash Account Guard:** If `posting.negative_cash_action = 'Block'` and the transaction results in a negative cash balance for a cash ledger, posting is aborted.
6. **Approval Threshold:** If `total_amount > approval.payment_threshold` (or `journal_threshold`) and the voucher type requires approval, voucher is saved as `Submitted` / `Approved` before posting.

---

## 3. Mathematical Calculation Engine (ALL Formulas)

This section details every mathematical formula used by the application to calculate stored, derived, cached, and reported fields.

---

### 3.1 Period Ledger Balances (`acc_ledger_period_balances`)

`acc_ledger_period_balances` maintains period-bucketed balances per ledger and optional dimension slice.

#### A. Net Balance Equations
$$\text{Net Opening} = \text{opening\_debit} - \text{opening\_credit}$$

$$\text{Net Period Movement} = \text{period\_debit} - \text{period\_credit} = \sum_{i \in \text{VoucherItems}_{\text{Period, Ledger}}} (\text{debit}_i - \text{credit}_i)$$

$$\text{Net Closing} = \text{Net Opening} + \text{Net Period Movement}$$

#### B. Conversion to Non-Negative Stored Columns
To ensure Dr and Cr columns remain non-negative ($\ge 0.00$) for Trial Balance display:

$$\text{closing\_debit} = \begin{cases} \text{Net Closing}, & \text{if } \text{Net Closing} \ge 0 \\ 0.00, & \text{if } \text{Net Closing} < 0 \end{cases}$$

$$\text{closing\_credit} = \begin{cases} 0.00, & \text{if } \text{Net Closing} \ge 0 \\ |\text{Net Closing}|, & \text{if } \text{Net Closing} < 0 \end{cases}$$

#### C. Inter-Period Carry-Forward (Opening Balance Chaining)
For Period $N$ ($N \in [2, 12]$) in Financial Year $Y$:

$$\text{opening\_debit}_{\text{Period } N} = \text{closing\_debit}_{\text{Period } N-1}$$

$$\text{opening\_credit}_{\text{Period } N} = \text{closing\_credit}_{\text{Period } N-1}$$

#### D. Inter-Year Carry-Forward (Year-End Close)
At Financial Year-End:
- **Asset, Liability, Equity Ledgers:**
  $$\text{opening\_debit}_{\text{FY } Y+1, \text{Period 1}} = \text{closing\_debit}_{\text{FY } Y, \text{Period 12}}$$
  $$\text{opening\_credit}_{\text{FY } Y+1, \text{Period 1}} = \text{closing\_credit}_{\text{FY } Y, \text{Period 12}}$$
- **Income & Expense Ledgers:**
  $$\text{opening\_debit}_{\text{FY } Y+1, \text{Period 1}} = 0.00, \quad \text{opening\_credit}_{\text{FY } Y+1, \text{Period 1}} = 0.00$$
  *(Net Surplus/Deficit transferred to Accumulated/Corpus Fund Equity ledger via year-end journal)*.

---

### 3.2 Bill-Wise Outstanding & Ageing (`acc_bill_references` & `acc_bill_reference_balances`)

#### A. Outstanding Amount Equation
$$\text{outstanding\_amount} = \text{original\_amount} - \sum_{j \in \text{Allocations}} \text{allocated\_amount}_j - \text{written\_off\_amount}$$

Where $\sum \text{allocated\_amount}_j$ is the sum of all matching rows in `acc_bill_allocations_jnt`.

#### B. Days Overdue Calculation
$$\text{days\_overdue} = \text{DATEDIFF}(\text{CURRENT\_DATE}, \text{due\_date})$$

*(Note: If $\text{days\_overdue} < 0$, the bill is not yet due).*

#### C. Ageing Bucket Assignment Formula
The edge limits $B = [B_1, B_2, B_3, B_4]$ (e.g. $[30, 60, 90, 180]$) are parsed dynamically from `acc_settings` where `setting_key = 'billwise.ageing_buckets'`:

$$\text{age\_bucket} = \begin{cases} 
\text{'Not\_Due'}, & \text{if } \text{days\_overdue} \le 0 \\
\text{'01\_' + } B_1, & \text{if } 1 \le \text{days\_overdue} \le B_1 \\
(B_k + 1) + \text{'\_'} + B_{k+1}, & \text{if } B_k < \text{days\_overdue} \le B_{k+1} \\
\text{'Over\_'} + B_{\text{max}}, & \text{if } \text{days\_overdue} > B_{\text{max}}
\end{cases}$$

---

### 3.3 Fixed Asset Depreciation & Disposal (`acc_asset_categories`, `acc_fixed_assets`, `acc_depreciation_entries`, `acc_asset_disposals`)

#### A. Straight Line Method (SLM) Annual Depreciation
$$\text{Annual Dep}_{\text{SLM}} = \frac{\text{purchase\_cost} - \text{salvage\_value}}{\text{useful\_life\_years}}$$

$$\text{Rate}_{\text{SLM}} = \left( \frac{\text{Annual Dep}_{\text{SLM}}}{\text{purchase\_cost}} \right) \times 100$$

#### B. Written-Down Value Method (WDV) Depreciation
Under WDV, the annual rate $r = \text{depreciation\_rate}$ (%) is applied to the opening WDV:

$$\text{Annual Dep}_{\text{WDV}} = \text{opening\_wdv} \times \left( \frac{r}{100} \right)$$

$$\text{closing\_wdv} = \text{opening\_wdv} - \text{Annual Dep}_{\text{WDV}}$$

Where for Year 1, $\text{opening\_wdv} = \text{purchase\_cost}$.

#### C. Periodical / Pro-Rata Depreciation Calculation
When computing monthly depreciation charges or for mid-year asset acquisitions (`days_in_use`):

$$\text{depreciation\_amount} = \text{opening\_wdv} \times \left( \frac{\text{rate\_applied}}{100} \right) \times \left( \frac{\text{days\_in\_use}}{\text{Total Days in FY (365 or 366)}} \right)$$

#### D. Net Book Value (NBV)
$$\text{net\_book\_value} = \text{cost\_at\_disposal} - \text{accumulated\_depreciation}$$

#### E. Gain / Loss on Asset Disposal
$$\text{gain\_loss\_amount} = \text{sale\_proceeds} - \text{disposal\_cost} - \text{net\_book\_value}$$

- If $\text{gain\_loss\_amount} > 0.00 \implies \text{Gain on Disposal}$ (Credit to Income ledger).
- If $\text{gain\_loss\_amount} < 0.00 \implies \text{Loss on Disposal}$ (Debit to Expense ledger).

---

### 3.4 Interest Computation Engine (`acc_interest_computations` & `acc_interest_slabs`)

#### A. Simple Interest Formula
$$I = P \times \left( \frac{r}{100} \right) \times t$$

#### B. Compound Interest Formula
$$A = P \times \left( 1 + \frac{r / 100}{n} \right)^{n \times t}, \quad I = A - P$$

Where $n$ is compounding frequency per year:
- Monthly: $n = 12$
- Quarterly: $n = 4$
- Half-Yearly: $n = 2$
- Yearly: $n = 1$

#### C. Day Count Conventions ($t$)
Let $D_1, M_1, Y_1$ be start date and $D_2, M_2, Y_2$ be end date. $\Delta D = \text{Actual Days Elapsed}$:

1. **`Actual_365`:**
   $$t = \frac{\Delta D}{365}$$
2. **`Actual_360`:**
   $$t = \frac{\Delta D}{360}$$
3. **`30_360` (ISMA 30/360):**
   $$t = \frac{360(Y_2 - Y_1) + 30(M_2 - M_1) + (D_2 - D_1)}{360}$$
4. **`Actual_Actual`:**
   $$t = \frac{\Delta D}{\text{Days in Year (365 or 366)}}$$

---

### 3.5 Tax, TDS & GST Calculation

#### A. Line Tax Calculation
$$\text{tax\_amount} = \text{line\_amount} \times \left( \frac{\text{tax\_rate\_pct}}{100} \right)$$

$$\text{total\_amount} = \text{line\_amount} + \text{tax\_amount}$$

#### B. TDS (Tax Deducted at Source) Calculation
Triggered when cumulative party payments in the financial year exceed the threshold ($T_{\text{TDS}}$):

$$\text{TDS Amount} = \text{Taxable Base Amount} \times \left( \frac{\text{TDS Rate \%}}{100} \right)$$

$$\text{Net Payable to Vendor} = \text{Gross Bill Amount} - \text{TDS Amount}$$

#### C. Rounding Tolerance Verification
$$\left| \sum \text{Debit Amounts} - \sum \text{Credit Amounts} \right| \le \text{posting.rounding\_tolerance}$$

*(If variance is within tolerance, the difference is automatically absorbed into the specified rounding ledger).*

---

### 3.6 Bank Reconciliation Calculations (`acc_bank_reconciliations` & `acc_bank_statement_entries`)

#### A. Reconciliation Equation
$$\text{balance\_as\_per\_bank} = \text{balance\_as\_per\_books} + \text{uncredited\_amount} - \text{unpresented\_amount} + \text{other\_adjustments}$$

Where:
- $\text{unpresented\_amount} = \sum \text{Issued Cheques / Payments not debited by bank}$.
- $\text{uncredited\_amount} = \sum \text{Deposited Cheques / Receipts not credited by bank}$.
- $\text{other\_adjustments} = \text{Bank Charges, Direct Credits/Debits, Interest}$.

#### B. Reconciliation Difference Equation
$$\text{difference} = \text{statement\_closing\_balance} - \text{balance\_as\_per\_bank}$$

*(Note: To complete reconciliation, `difference` MUST evaluate to exactly $0.00$).*

#### C. Machine Import Match-Scoring Algorithm
When auto-matching bank statement lines against ledger entries, the system computes a confidence score ($C \in [0.0000, 1.0000]$):

$$C = w_{\text{amt}} S_{\text{amt}} + w_{\text{date}} S_{\text{date}} + w_{\text{ref}} S_{\text{ref}} + w_{\text{inst}} S_{\text{inst}}$$

Where:
- Weights: $w_{\text{amt}} = 0.40, w_{\text{date}} = 0.20, w_{\text{ref}} = 0.20, w_{\text{inst}} = 0.20$.
- Component Scores:
  - $S_{\text{amt}} = 1.0$ if amounts match exactly, else $0.0$.
  - $S_{\text{date}} = 1.0 - \left( \frac{|\text{Statement Date} - \text{Voucher Date}|}{\text{match\_tolerance\_days}} \right)$ (if within window, else $0.0$).
  - $S_{\text{ref}} = 1.0$ if reference numbers match, else $0.0$.
  - $S_{\text{inst}} = 1.0$ if instrument numbers match, else $0.0$.

---

### 3.7 Budget Variance & Breach Calculation (`acc_budgets` & `acc_budget_lines`)

#### A. Budget Variance Equation
$$\text{Variance Amount} = \text{Actual Utilisation} - \text{Budget Amount}$$

$$\text{Utilisation Percentage} = \left( \frac{\text{Actual Utilisation}}{\text{Budget Amount}} \right) \times 100$$

#### B. Breach Action Threshold Formula
$$\text{Breach Limit} = \text{budget\_amount} \times \left( 1 + \frac{\text{breach\_tolerance\_pct}}{100} \right)$$

Evaluation Logic during voucher posting:
- If $\text{Actual Utilisation} + \text{Voucher Line Amount} > \text{Breach Limit}$:
  - If `breach_action = 'Block'` $\implies$ Abort transaction with `BudgetBreachException`.
  - If `breach_action = 'Approve'` $\implies$ Require elevated managerial approval.
  - If `breach_action = 'Warn'` $\implies$ Post voucher and trigger audit alert.

---

### 3.8 Fund Utilisation Calculation (`acc_fund_balances`)

$$\text{closing\_balance} = \text{opening\_balance} + \text{additions} - \text{utilisation}$$

Where:
- $\text{additions} = \sum \text{Cr lines to restricted fund ledgers}$.
- $\text{utilisation} = \sum \text{Dr lines linked to fund via } \text{acc\_voucher\_item\_funds}$.

---

## 4. End-to-End Process Flows

This section details the operational workflows for key accounting functions.

---

### Process Flow 1: Voucher Processing Lifecycle

```
[ User / External Event ]
          │
          ▼
   1. Create Draft ──► Saved in acc_vouchers (Status = 'Draft')
          │
          ▼
 2. Validate Voucher ──► Check Dr=Cr, Dates, Closed Periods, Budgets
          │
     ┌────┴────────────────────────┐
     │ (Requires Approval)         │ (Direct / Approved)
     ▼                             ▼
 3. Approval Workflow       4. Posting Transaction (PostingService)
    - Check Thresholds         a. Acquire Lock on Number Sequence
    - Check Forbid Self        b. Generate Display Number
    - Status = 'Submitted'     c. Insert acc_vouchers (Status='Posted')
    - Status = 'Approved'      d. Insert acc_voucher_items (Dr/Cr)
     │                         e. Insert Dimensions (CC / Fund)
     └────────────────────────►f. Update Period & Bill Balances
                               g. Write Append-Only Audit Log
                                   │
                                   ▼
                            [ COMMITTED ]
```

---

### Process Flow 2: Bill Allocation & Settlement

```
[ Vendor Bill / Fee Demand Posted ] ──► Insert acc_bill_references (Outstanding = Original)
                                              │
                                              ▼
[ Payment / Receipt Voucher Posted ] ──► Match Bill Reference in UI
                                              │
                                              ▼
                                   Insert acc_bill_allocations_jnt
                                   (Allocated Amount, Voucher Item ID)
                                              │
                                              ▼
                                   Recalculate acc_bill_reference_balances:
                                   Outstanding = Original - Allocations - WrittenOff
                                              │
                                   ┌──────────┴──────────┐
                                   │ (Outstanding = 0)   │ (Outstanding > 0)
                                   ▼                     ▼
                             Status = 'Settled'    Status = 'Partial'
```

---

### Process Flow 3: Period Close & Year-End Carry-Forward

```
                       [ Month-End Cockpit ]
                               │
                               ▼
            1. Run Period Close Checklist (BR-CLOSE-01)
               - Fee Reconciliation = 0
               - Bank Reconciliation complete
               - Asset Depreciation posted
               - Exception list reviewed
                               │
                          (All Clear)
                               ▼
            2. Freeze Balances (acc_period_closing_balances)
               - Copy Period Balances to Immutable Snapshot
                               │
                               ▼
            3. Update Period Status (acc_accounting_periods)
               - Status = 'Hard_Closed'
                               │
                               ▼
              ┌────────────────┴────────────────┐
              │ (If Period 12 / Year-End)        │
              ▼                                 ▼
            4. Generate Year-End Journal      5. Open New Financial Year
               - Transfer Surplus/Deficit        - Carry Forward Asset/Liab/Equity
                 to Corpus Equity Fund           - Income/Expense Reset to 0
               - Mark Income/Expense = 0         - Open Bill References carried over
```

---

### Process Flow 4: Bank Reconciliation & Machine Import Auto-Match

```
[ Bank Statement File (CSV/XLS/MT940) ]
                   │
                   ▼
  1. Parse Layout Configuration (acc_bank_import_configs)
                   │
                   ▼
  2. Compute SHA-256 Row Hashes & Stage Entries (acc_bank_statement_entries)
                   │
                   ▼
  3. Run Match Engine (Match confidence algorithm)
       - Score exact amount, date window, instrument #, reference #
                   │
       ┌───────────┴──────────────────────────┐
       │ (Confidence >= Threshold & Auto-On)  │ (Low Confidence / Ambiguous)
       ▼                                      ▼
  4. Auto-Confirm Match                 5. Stage for Manual Review
     Insert acc_bank_reconciliation_      Accountant confirms/rejects match
     matches                                  │
       │                                      ▼
       └─────────────────────────────────────►│
                                              ▼
                                6. Balance Verification
                                   Verify Statement Closing Balance = Bank Balance
                                   Difference = 0.00
                                              │
                                              ▼
                                7. Sign-off & Complete Reconciliation
```

---

### Process Flow 5: Fixed Asset Depreciation Run & Disposal

```
[ Monthly / Annual Depreciation Run ]
                   │
                   ▼
  1. Fetch Active Assets (acc_fixed_assets WHERE status = 'Active')
                   │
                   ▼
  2. Compute Depreciation per Asset
     - Determine Method (SLM / WDV)
     - Calculate Days in Use & Depreciation Amount
     - Verify UNIQUE(fixed_asset_id, period_id)
                   │
                   ▼
  3. Generate & Post Depreciation Journal
     - Debit Depreciation Expense Ledger
     - Credit Accumulated Depreciation Ledger
     - Insert acc_depreciation_entries
                   │
                   ▼
[ Asset Disposal Event (Sale / Scrap / Loss) ]
                   │
                   ▼
  1. Freeze Cost at Disposal & Accumulated Depreciation
  2. Calculate Net Book Value (NBV)
  3. Calculate Gain / Loss = Proceeds - Costs - NBV
  4. Post Disposal Journal & Update Status = 'Disposed' (acc_asset_disposals)
```

---

### Process Flow 6: Cross-Module Event Integration Processing

```
[ Domain Event (e.g. FEE_COLLECTED, VND_BILL_BOOKED) ]
                   │
                   ▼
  1. Idempotency Check (Check event_uuid in acc_audit_logs / vouchers)
                   │ (New Event)
                   ▼
  2. Rule Engine Lookup (acc_event_voucher_configs)
     - Resolve Voucher Type, Dr/Cr Ledger Mappings
                   │
                   ▼
  3. Transform Event Payload to Voucher Payload
                   │
                   ▼
  4. Execute Posting Engine (PostingService)
     - Insert Voucher Header, Items, Dimensions, Bill Allocations
                   │
                   ▼
  5. Mark Event Handled & Audit
```

---

### Process Flow 7: Recurring Voucher Schedule Execution

```
[ Cron Scheduler / Artisan Command acc:process-recurring ]
                   │
                   ▼
  1. Query Active Templates (acc_recurring_templates WHERE status='Active' AND next_due_date <= TODAY)
                   │
                   ▼
  2. Evaluate End Conditions (end_date or occurrence_limit reached?)
                   │ (Active)
                   ▼
  3. Generate Voucher Payload from Template Lines
                   │
     ┌─────────────┴────────────────────────┐
     │ (auto_post = 1 & Has Perm)           │ (auto_post = 0)
     ▼                                      ▼
  4. Post Immediately via PostingService 5. Save as Draft Voucher
                   │                        Notify Accountant for Review
                   ├───────────────────────►│
                   ▼
  6. Update Template State (acc_recurring_templates)
     - Increment occurrences_generated
     - Recalculate next_due_date based on frequency & month_end_policy
     - Log run in acc_recurring_transaction_log
```

---

### Process Flow 8: Budget Breach Monitoring

```
[ Voucher Line Entry / Integration Event ]
                   │
                   ▼
  1. Check Ledger Budget Config (acc_budget_lines for Ledger, FY, Period, CC, Fund)
                   │ (Budget Exists)
                   ▼
  2. Calculate Current Utilisation
     Actual Utilisation = Σ Posted Dr Items in Period + Proposed Line Amount
                   │
                   ▼
  3. Compare against Budget & Tolerance Limit
     Threshold = Budget Amount * (1 + breach_tolerance_pct / 100)
                   │
     ┌─────────────┴──────────────────────────────────┐
     │ (Utilisation <= Threshold)                     │ (Utilisation > Threshold)
     ▼                                                ▼
  4. Allow Transaction                            5. Execute Breach Action
                                                     - Block: Abort & Throw Exception
                                                     - Approve: Escalation Workflow
                                                     - Warn: Post & Trigger Alert
```

---

### Process Flow 9: Interest Computation & Accrual Posting

```
[ Interest Batch Processing Job ]
                   │
                   ▼
  1. Fetch Active Interest Rules (acc_interest_computations WHERE status='Active')
                   │
                   ▼
  2. For Each Party / Loan Ledger:
     a. Fetch Balance & Transaction History
     b. Determine Applicable Rate & Slab (acc_interest_slabs)
     c. Calculate Elapsed Time (t) using Day Count Convention (Actual_365 / 30_360)
     d. Calculate Interest (Simple / Compound Formula)
                   │
                   ▼
  3. Check Minimum Threshold & Grace Days
                   │ (Interest > minimum_amount)
                   ▼
  4. Generate Interest Accrual Voucher
     - Debit Party / Interest Expense Ledger
     - Credit Interest Income / Payable Ledger
     - Post via PostingService
```

---

## 5. Database Schema Realization & Mapping

The table below maps every functional component of this Solution Design to its physical implementation in `Accounting_DDL_v4.8.sql`:

| Functional Area | Primary Table(s) | Generated Markers / Key Columns | Service Owner | Rebuild / Verification |
|---|---|---|---|---|
| **Core Ledgers** | `acc_account_groups`, `acc_ledgers` | `path`, `depth`, `tree_left`, `tree_right` | `LedgerService` | `vw_ledger_balances` |
| **Vouchers & Items** | `acc_vouchers`, `acc_voucher_items` | `voucher_display_no`, `is_posted` | `PostingService` | `acc_audit_logs` |
| **Numbering** | `acc_voucher_types`, `acc_voucher_number_sequences` | `period_marker` | `PostingService` | Continuous Sequence Check |
| **Balance Cache** | `acc_ledger_period_balances` | `cc_marker`, `fund_marker`, `campus_marker` | `PostingService` | `acc:rebuild-balances` |
| **Bill-Wise** | `acc_bill_references`, `acc_bill_allocations_jnt` | `bill_reference_id`, `voucher_item_id` | `BillService` | `acc_bill_reference_balances` |
| **Dimensions** | `acc_cost_centers`, `acc_cost_categories`, `acc_funds`, `acc_campuses` | `cost_center_id`, `fund_id`, `campus_id` | `DimensionService` | `acc_fund_balances` |
| **Periods & Close** | `acc_financial_years`, `acc_accounting_periods`, `acc_period_closing_balances` | `status`, `is_frozen` | `PeriodService` | Nightly Balance Assertion |
| **Bank & BRS** | `acc_bank_reconciliations`, `acc_bank_statement_entries`, `acc_bank_reconciliation_matches` | `row_hash`, `confidence` | `ReconciliationService` | `vw_bank_reconciliation_status` |
| **Fixed Assets** | `acc_asset_categories`, `acc_fixed_assets`, `acc_depreciation_entries`, `acc_asset_disposals` | `opening_wdv`, `closing_wdv`, `net_book_value` | `AssetService` | `vw_fixed_asset_register` |
| **Budgets** | `acc_budgets`, `acc_budget_lines` | `breach_action`, `breach_tolerance_pct` | `BudgetService` | `vw_budget_variance` |
| **Interest** | `acc_interest_computations`, `acc_interest_slabs` | `basis`, `compounding`, `day_count` | `InterestService` | Batch Calculation Engine |
| **Recurring** | `acc_recurring_templates`, `acc_recurring_template_lines`, `acc_recurring_transaction_log` | `frequency`, `month_end_policy` | `RecurringService` | Scheduler Execution Log |
| **Audit & Control** | `acc_audit_logs`, `acc_exceptions`, `acc_assertions`, `acc_settings` | `setting_key`, `value_json` | `AssertionService` | Hourly Continuous Assertions |

---

## 6. Verification & Integrity Assertions

The system enforces compliance with business rules through continuous hourly assertions (`AssertionService`):

| Assertion Code | Rule Verified | Failure Condition |
|---|---|---|
| **ASSERT-01** | Double-Entry Balance | Any posted voucher where $\sum \text{Dr} \ne \sum \text{Cr}$ |
| **ASSERT-02** | Trial Balance Balance | Any period where $\sum \text{Period Debit} \ne \sum \text{Period Credit}$ |
| **ASSERT-03** | Derived Balance Integrity | Any `acc_ledger_period_balances` row that disagrees with $\sum \text{acc\_voucher\_items}$ |
| **ASSERT-04** | Bill Outstanding Integrity | Any `acc_bill_reference_balances` row where $\text{outstanding} \ne \text{original} - \sum \text{allocations}$ |
| **ASSERT-05** | Asset Net Block Agreement | Asset register net book value total $\ne$ Asset ledger balance |
| **ASSERT-06** | Fund Balance Integrity | Fund closing balance $\ne \text{opening} + \text{additions} - \text{utilisation}$ |
| **ASSERT-07** | Gapless Numbering | Gap detected in any sequential voucher numbering series |

---
*End of Solution Design v2 Document.*
