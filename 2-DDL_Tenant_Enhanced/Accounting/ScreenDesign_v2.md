# Accounting Module — Screen Design (v1)

**Module:** Accounting (`ACC` / prefix `acc_`)
**Scope of this document:** **Voucher Entry** screens (Tally-Prime style)
**DDL Reference:** `1-New_Enhancements/Accounting/Accounting_DDL_v4.sql` (v4.0 — 2026-08-24)
**Document Version:** 1.0
**Last Updated:** 29 August 2026

---

## 1. OVERVIEW

### 1.1 Purpose

This document specifies the UI/UX for the **Voucher Entry** family of screens in the Accounting module.
The design deliberately mirrors **TallyPrime's voucher entry paradigm** — a single, consistent entry shell that changes behaviour based on the selected *Voucher Type*, driven by function keys, with keyboard-first navigation — because school accountants in India are already trained on Tally, and the module also exports to Tally (`acc_tally_export_logs`, `acc_tally_ledger_mappings`).

**Design principle:** *One screen, many voucher types.* The accountant never leaves the entry shell; pressing `F4`–`F9` switches voucher type in place, preserving the date and keeping the cursor in the grid.

### 1.2 Tally Reference Baseline

TallyPrime ships **24 predefined voucher types** grouped into categories. This release implements the **Accounting** category in full; Inventory and Order categories are structurally supported by the DDL (`acc_voucher_category`) but are **out of scope for v1** (see §14).

| # | Tally Voucher Type | Key | Category | v1 Status |
|---|--------------------|-----|----------|-----------|
| 1 | **Payment** | `F5` | Accounting | ✅ In scope |
| 2 | **Receipt** | `F6` | Accounting | ✅ In scope |
| 3 | **Contra** | `F4` | Accounting | ✅ In scope |
| 4 | **Journal** | `F7` | Accounting | ✅ In scope |
| 5 | **Sales** (school → Fee/Service Invoice) | `F8` | Accounting | ✅ In scope |
| 6 | **Purchase** | `F9` | Accounting | ✅ In scope |
| 7 | **Credit Note** | `Alt+F6` | Accounting | ✅ In scope |
| 8 | **Debit Note** | `Alt+F5` | Accounting | ✅ In scope |
| 9 | **Memorandum** (Optional voucher) | `Ctrl+F10` | Accounting | ✅ In scope (via `is_optional`) |
| 10 | **Reversing Journal** | `F10` | Accounting | ⚠️ Deferred — needs `applicable_upto` column |
| 11 | Delivery Note | `Alt+F8` | Inventory | ❌ Out of scope (v2) |
| 12 | Receipt Note | `Alt+F9` | Inventory | ❌ Out of scope (v2) |
| 13 | Rejection In / Rejection Out | `Ctrl+F6`/`Ctrl+F5` | Inventory | ❌ Out of scope (v2) |
| 14 | Stock Journal | `Alt+F7` | Inventory | ❌ Out of scope (v2) |
| 15 | Physical Stock | `Ctrl+F7` | Inventory | ❌ Out of scope (v2) |
| 16 | Sales Order / Purchase Order | `Ctrl+F8`/`Ctrl+F9` | Order | ❌ Out of scope (v2) |
| 17 | Point of Sale (POS) | — | Accounting | ❌ Not applicable to schools |

> Source: TallyPrime — *Voucher Types* (help.tallysolutions.com/voucher-types-tally/), *Record Accounting Entry*, *Payments and Receipts*.

### 1.3 School-Context Mapping

Tally is built for traders. This module is for **schools**. The voucher types are retained, but their day-to-day meaning is re-labelled:

| Voucher Type | Generic Tally Meaning | School Meaning (label shown in UI) |
|--------------|----------------------|-------------------------------------|
| Receipt | Money received | **Fee collection, donation, grant, hostel/transport receipt** |
| Payment | Money paid out | **Salary payout, vendor payment, utility bill, refund** |
| Contra | Cash ↔ Bank transfer | **Cash deposit to bank, bank-to-bank transfer, petty cash draw** |
| Journal | Adjustment entry | **Fee accrual, depreciation, scholarship/concession write-off, year-end adjustment** |
| Sales | Sale invoice | **Fee demand / service invoice raised on student or parent** |
| Purchase | Purchase invoice | **Vendor bill for books, uniforms, lab equipment, services** |
| Credit Note | Sales return | **Fee concession, waiver, cancelled fee demand** |
| Debit Note | Purchase return | **Goods returned to vendor, vendor bill short-billing** |
| Memorandum | Optional / suspense | **Provisional or draft entry pending approval** |

### 1.4 User Roles & Permissions

| Role | Create | View | Update | Delete/Cancel | Approve | Post | Print | Export |
|------|--------|------|--------|---------------|---------|------|-------|--------|
| Super Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| PG Support | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ | ✓ |
| School Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Principal | ✗ | ✓ | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ |
| Accountant | ✓ | ✓ | ✓ (Draft only) | ✓ (Draft only) | ✗ | ✓ | ✓ | ✓ |
| Accounts Clerk | ✓ | ✓ | ✓ (own Draft only) | ✗ | ✗ | ✗ | ✓ | ✗ |
| Auditor (read-only) | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| Teacher / Student / Parent | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

**Permission slugs:** `acc.voucher.create`, `acc.voucher.view`, `acc.voucher.update`, `acc.voucher.cancel`, `acc.voucher.approve`, `acc.voucher.post`, `acc.voucher.print`, `acc.voucher.export`, `acc.voucher.backdate`, `acc.voucher.view_all_users`.

### 1.5 Data Context (DDL v4 tables touched by these screens)

```
acc_vouchers                  ← voucher header (1 row per voucher)
 └── acc_voucher_items        ← Dr/Cr lines (2..n rows per voucher)

Lookups / drivers:
acc_voucher_types             ← voucher type + prefix + auto-numbering counter
acc_voucher_category          ← category of the voucher type (Accounting/Inventory/…)
acc_voucher_modules           ← originating module (Accounting/Fee/Library/Transport/…)
acc_financial_years           ← active FY, lock flag
acc_ledgers                   ← ledger picker source (incl. student/vendor/employee ledgers)
acc_account_groups            ← group tree shown in the ledger picker
acc_cost_centers              ← cost centre allocation (header + line level)
acc_accounting_status_masters ← voucher status (Draft/Posted/Approved/Cancelled/Auto_Approved)
acc_tax_rates, acc_tax_types  ← GST ledgers on Sales/Purchase/Credit/Debit notes
sys_users                     ← entered_by / approved_by
```

### 1.6 Currency, Date & Number Formats

- Currency symbol: **₹**, thousands separator: Indian lakh/crore grouping (`12,34,567.00`)
- Amount precision: **2 decimals**, right-aligned, stored as `DECIMAL(15,2)`
- Date format: `DD-MMM-YYYY` (e.g. `29-Aug-2026`), stored as `DATE`
- Voucher number display: `{prefix}{number}` → `PAY-0042`, `RCV-1187`

---

## 2. NAVIGATION & SCREEN INVENTORY

```
Accounting
├── Vouchers dashboard
│   ├── Voucher Entry Hub  ......................  VE-00   /accounting/vouchers
│   ├── Create Voucher (entry shell) ............  VE-01   /accounting/vouchers/create
│   │     ├── Payment ...........................  VE-02   ?type=PAYMENT      [F5]
│   │     ├── Receipt ...........................  VE-03   ?type=RECEIPT      [F6]
│   │     ├── Contra ............................  VE-04   ?type=CONTRA       [F4]
│   │     ├── Journal ...........................  VE-05   ?type=JOURNAL      [F7]
│   │     ├── Sales / Fee Invoice ...............  VE-06   ?type=SALES        [F8]
│   │     ├── Purchase ..........................  VE-07   ?type=PURCHASE     [F9]
│   │     └── Credit / Debit Note ...............  VE-08   ?type=CREDIT_NOTE  [Alt+F6/Alt+F5]
│   ├── Voucher View (read-only) ................  VE-09   /accounting/vouchers/{id}
│   ├── Day Book ................................  VE-10   /accounting/vouchers/day-book
│   └── Pending Approvals .......................  VE-11   /accounting/vouchers/approvals
└── Shared sub-screens (modals / panels)
    ├── Ledger Picker ...........................  VE-S1
    ├── Cost Centre Allocation ..................  VE-S2
    ├── Bill-wise / Reference Allocation ........  VE-S3
    ├── Bank Allocation Details .................  VE-S4
    ├── Voucher Configuration (F12) .............  VE-S5
    └── Cancel / Reason Modal ...................  VE-S6
```

---

## 3. THE COMMON VOUCHER ENTRY SHELL

Every voucher type renders inside the **same shell**. Only the *particulars grid* behaviour and the *contextual panel* change.

### 3.1 Payment Voucher Entry

```ascii

┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ VOUCHER ENTRY                                                                                                                                              FINANCE > ACCOUNTING > VOUCHERS ENTRY  │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│[ DASHBOARD ] │   PAYMENT   | [  RECEIPT   ] [  CONTRA    ] [  JOURNAL   ] [  SALES     ] [  PURCHASE  ] [ Cr/Dr NOTE ]                                                                            │
├──────────────┼─────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ PAYMENT                                                                              Voucher No. [ PAY-0042        ] Date [ 29-Aug-2026 ]  Status [ Draft            ]                            │
│ ACCOUNT (CR) : [HDFC Bank — 50200012345678                                      ]    Ref. No. [ CHQ-884512         ] Date [ 28-Aug-2026 ]                                                         │ 
│ Cur Bal: 42,18,900.00 Dr                                                                                                                                                                          │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Dr/Cr │ Particulars (Ledger Account)                               │ Narration                                                                              │       Amount ₹    │ Action          │        
│ ──────┼────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────────┼─────────────────│
│  Dr   │ Electricity Charges                                        │                                                                                        │       1,24,500.00 │ [Cost] [Info]   │ Info - Ref.No, date, 
│       │   Cur Bal: 8,45,000.00 Dr                                  │                                                                                        │                   │                 │
│  Dr   │ Water Carges                                               │ —                                                                                      │       1,24,500.00 │ [Cost] [Info]   │ Info - Ref.No, date, 
│       │   Cur Bal: 23,3900.00 Cr                                   │                                                                                        │                   │                 │
│  ▸    │ [ Select ledger…                        ]                  │                                                                                        │                   │                 │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Narration :                                                                                                                                         TOTAL   │ ₹  1,24,500.00(Dr)│₹ 1,24,500.00(Cr) │
│ [ Electricity bill for Aug-2026 paid vide cheque 884512 .....................................                                        ]           DIFFERENCE │ ₹ 0.00                               │
│                                                                                                                                                             │                                      │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ☐ Optional (Memorandum)   ☐ Post-dated          [Cancel]  [Save as Draft]  [Save & Post (Ctrl+A)]                                                                                                 │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Cost Center Modal
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Payment Voucher                                                                                                                       │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Cost Center                         │ Percentage │         Amount │ Narration                                                         │
├─────────────────────────────────────┼────────────┼────────────────┼───────────────────────────────────────────────────────────────────┤
│                                     │            │                │                                                                   │
│ Primary Wing                        │            │    1,00,000.00 │ Narration...................................................      │
│ Senior Wing                         │            │      50,000.00 │ Narration...................................................      │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Region Specification

| Region | Element | Behaviour | DDL Mapping |
|--------|---------|-----------|-------------|
| **A** | Financial Year selector | Defaults to `acc_financial_years` where `is_active=1`. If `is_locked=1` the entire form is read-only with banner *"FY 2025-26 is locked. No entries permitted."* | `acc_vouchers.financial_year_id` |
| **A** | Status pill | `Draft` (grey) / `Posted` (blue) / `Approved` (green) / `Cancelled` (red strike) / `Auto_Approved` (teal) | `acc_vouchers.status` → `acc_accounting_status_masters` |
| **B** | Voucher type switcher | Renders one chip per active row in `acc_voucher_types` where category = Accounting. Switching **preserves Date and Narration**, clears the grid after a confirm prompt if lines exist. | `acc_vouchers.voucher_type_id` |
| **C** | Voucher No. | If `auto_numbering=1` → read-only, shows `prefix + (last_number+1)` as a *preview* (reserved only on save). If `auto_numbering=0` → editable, mandatory, uniqueness checked live. | `voucher_prefix`, `voucher_number` |
| **C** | Date | Defaults to today, clamped to the selected FY's `start_date`…`end_date`. Back-dating beyond N days requires `acc.voucher.backdate`. | `voucher_date` |
| **C** | Ref. No. / Ref. Date | Cheque no. / UTR / bill no. and its date. Mandatory when the payment/receipt instrument is a cheque. | `reference_number`, `reference_date` |
| **C** | Mode toggle | `Ctrl+H` — **Single Entry** (Tally style: pick one bank/cash account, then list the contra ledgers) vs **Double Entry** (explicit Dr/Cr per line). Only offered on Payment, Receipt, Contra. | UI-only; both persist identically to `acc_voucher_items.type` |
| **D** | Particulars grid | Repeating rows; each row = one `acc_voucher_items` record. Minimum **2 rows**. New blank row auto-appended when the last row gains a ledger. | `acc_voucher_items` |
| **D** | Dr/Cr cell | Dropdown `Dr`/`Cr`. In Single Entry mode this column is hidden and derived. | `acc_voucher_items.type` |
| **D** | Ledger cell | Type-ahead over `acc_ledgers` (active only), grouped by `acc_account_groups.name`. `Alt+C` creates a ledger inline. Shows live *Current Balance* under the selected ledger. | `acc_voucher_items.ledger_id` |
| **D** | Cost Centre cell | Optional per-line. Defaults to the header cost centre if one is set. `Ctrl+Shift+C` opens the multi-split allocation modal (VE-S2). | `acc_voucher_items.cost_center_id` |
| **D** | Amount cells | Debit and Credit columns are mutually exclusive per row. Accepts inline arithmetic (`1200*3`). | `acc_voucher_items.amount` |
| **D** | Per-line narration | Toggled on via F12 config; renders as a sub-row under each line. | `acc_voucher_items.narration` |
| **E** | Totals bar | Live sum of Debit and Credit columns + **Difference**. Save is blocked while Difference ≠ 0. | `acc_vouchers.total_amount` = Σ Debits |
| **F** | Narration | Free text, multi-line, 1000 char soft cap. | `acc_vouchers.narration` |
| **G** | Optional flag | Marks a **Memorandum** voucher — appears in reports but is **not posted to ledgers** until explicitly un-flagged and approved. | `acc_vouchers.is_optional` |
| **G** | Post-dated flag | For post-dated cheques. Excluded from current-period balances until the date arrives. | `acc_vouchers.is_post_dated` |

### 3.3 Keyboard Map (Tally-parity)

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `F2` | Change voucher date | `Ctrl+A` | Save & Post |
| `F4` | Switch to Contra | `Ctrl+S` | Save as Draft |
| `F5` | Switch to Payment | `Ctrl+H` | Change mode (Single ↔ Double entry) |
| `F6` | Switch to Receipt | `Ctrl+F10` | Mark as Optional (Memorandum) |
| `F7` | Switch to Journal | `Alt+C` | Create ledger inline from the picker |
| `F8` | Switch to Sales | `Alt+D` | Delete current line |
| `F9` | Switch to Purchase | `Alt+X` | Cancel voucher (in view mode) |
| `Alt+F5` | Debit Note | `Ctrl+Shift+C` | Cost centre allocation modal |
| `Alt+F6` | Credit Note | `Ctrl+Shift+B` | Bill-wise allocation modal |
| `F12` | Voucher configuration | `Enter` | Commit cell → next cell |
| `F11` | Company/module features | `Esc` | Back / close modal |
| `Ctrl+P` | Print voucher | `Ctrl+N` | New voucher, same type |

> **Accessibility note:** every function-key action also exists as a visible button or menu item. Function keys are an accelerator, never the only route.

### 3.4 Field-Level Cursor Flow

`Date → Ref.No → Ref.Date → [grid] Dr/Cr → Ledger → Cost Centre → Amount → (next row) … → Narration → Save`

`Enter` on an empty Ledger cell in the last row jumps directly to **Narration** (Tally behaviour). `Tab`/`Shift+Tab` move linearly; arrow keys move within the grid.

---

## 4. VE-00 — VOUCHER ENTRY HUB

**Route:** `/accounting/vouchers`
**Purpose:** Landing screen — pick a voucher type to create, or find an existing voucher.

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ACCOUNTING > VOUCHERS                                    FY: 2026-27 ▼        [+ New Voucher ▼]      │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  CREATE A VOUCHER                                                                                    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │  💵 PAYMENT  │ │  🧾 RECEIPT  │ │  🔁 CONTRA   │ │  📘 JOURNAL  │ │  📄 SALES    │               │
│  │      F5      │ │      F6      │ │      F4      │ │      F7      │ │      F8      │               │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                                │
│  │ 🛒 PURCHASE  │ │ ➖ CREDIT NT │ │ ➕ DEBIT NT  │ │ 📝 MEMO      │                                │
│  │      F9      │ │    Alt+F6    │ │    Alt+F5    │ │   Ctrl+F10   │                                │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘                                │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  SEARCH: [ Voucher no / narration / ledger… ]  TYPE:[All ▼] STATUS:[All ▼] FROM:[01-Aug] TO:[29-Aug] │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Date        │ Voucher No │ Type     │ Particulars (Dr → Cr)              │  Amount ₹ │ Status    │
│───┼─────────────┼────────────┼──────────┼────────────────────────────────────┼───────────┼───────────│
│ ☐ │ 29-Aug-2026 │ PAY-0042   │ Payment  │ Electricity Chgs → HDFC Bank       │ 1,24,500  │ Posted    │
│ ☐ │ 29-Aug-2026 │ RCV-1187   │ Receipt  │ Cash A/c → Tuition Fee Income      │   45,000  │ Approved  │
│ ☐ │ 28-Aug-2026 │ JRN-0311   │ Journal  │ Depreciation → Accum. Depreciation │   88,750  │ Draft     │
│ ☐ │ 28-Aug-2026 │ CNT-0009   │ Cr Note  │ Fee Concession → Aarav Singh       │    5,000  │ Posted    │
│ ☐ │ 27-Aug-2026 │ CON-0055   │ Contra   │ HDFC Bank → Cash A/c               │   20,000  │ Cancelled │
│───┴─────────────┴────────────┴──────────┴────────────────────────────────────┴───────────┴───────────│
│ Showing 1-25 of 386 vouchers                                                          [< 1 2 3 … >]  │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Interactions**
- Voucher-type tiles are keyboard-addressable by their function key from anywhere on this screen.
- Row click → **VE-09 Voucher View**. Draft rows open directly in edit mode.
- Cancelled rows render struck-through in red and are never editable.
- Bulk actions (checkbox column): *Approve Selected*, *Post Selected*, *Export*, *Print*. Bulk approve is gated on `acc.voucher.approve`.
- Status filter options come from `acc_accounting_status_masters` where `status_type = 'Voucher Status'`.

---

## 5. VE-02 — PAYMENT VOUCHER `F5`

**Route:** `/accounting/vouchers/create?type=PAYMENT`
**Accounting rule:** Credit the Cash/Bank ledger, Debit the expense or party ledger.
**School use:** salary payout, vendor bill payment, electricity/water bill, student fee refund, petty cash expense.

### 5.1 Single Entry Mode (default for clerks)

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PAYMENT                                                    No. [ PAY-0042 ]   Date [ 29-Aug-2026 ]  │
│  Mode: ( ) Double Entry  (•) Single Entry                              [Ctrl+H to change mode]       │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Account  [ HDFC Bank — 50200012345678                                          ▼ ]                  │
│           Current Balance: ₹ 42,18,900.00 Dr                                                         │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Particulars (paid towards)                        │ Cost Centre        │            Amount ₹        │
│ ───────────────────────────────────────────────────┼────────────────────┼────────────────────────────│
│  Electricity Charges                               │ Primary Wing       │              1,00,000.00   │
│  Water Charges                                     │ Primary Wing       │                24,500.00   │
│  [ Select ledger…                                ] │ [ —              ▼]│           [           ]    │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                       TOTAL   ₹ 1,24,500.00          │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ▸ BANK ALLOCATION                                                                     [expand ▼]    │
│     Transaction Type [ Cheque      ▼]   Instrument No. [ 884512    ]  Instrument Date [ 28-Aug-2026 ]│
│     Favouring Name   [ MSEDCL                                                                      ] │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Narration [ Electricity & water bill Aug-2026 vide chq 884512 ................................. ]  │
│  ☐ Optional   ☐ Post-dated                       [Cancel]  [Save as Draft]  [Save & Post (Ctrl+A)]   │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Persistence:** the single-entry form still writes normal double-entry rows —
`Account` ledger → one `Cr` row for the total; each *Particulars* line → one `Dr` row.

### 5.2 Double Entry Mode

Identical to the shell in §3.1 — the `Dr/Cr` column is visible, any number of Dr and Cr lines allowed, Difference must be ₹ 0.00.

### 5.3 Field Specification

| Field | Type | Req. | Validation / Behaviour | DDL Column |
|-------|------|:----:|------------------------|------------|
| Date | Date picker | ✔ | Within active FY; not in a locked FY; future date allowed only if *Post-dated* is ticked | `acc_vouchers.voucher_date` |
| Voucher No. | Text / auto | ✔ | Auto from `acc_voucher_types.last_number + 1` with `prefix`; unique per `(financial_year_id, voucher_prefix, voucher_number)` | `voucher_prefix`, `voucher_number` |
| Account (Single mode) | Ledger picker | ✔ | Filtered to `is_bank_account=1 OR is_cash_account=1` | line with `type='Cr'` |
| Particulars ledger | Ledger picker | ✔ | Any active ledger; excludes the already-chosen Account ledger | `acc_voucher_items.ledger_id` |
| Cost Centre | Dropdown | ✗ | Active `acc_cost_centers`; blank = unallocated | `acc_voucher_items.cost_center_id` |
| Amount | Decimal(15,2) | ✔ | `> 0`; inline arithmetic allowed | `acc_voucher_items.amount` |
| Transaction Type | Dropdown | ✗* | `Cheque, e-Fund Transfer (NEFT/RTGS/IMPS), UPI, Cash, DD, Card, Others` — *mandatory when Account is a bank ledger* | UI → composed into `reference_number` context |
| Instrument No. | Text(100) | ✗* | Mandatory when Transaction Type = Cheque / DD | `acc_vouchers.reference_number` |
| Instrument Date | Date | ✗* | Mandatory when Transaction Type = Cheque / DD; if > voucher date → auto-tick *Post-dated* | `acc_vouchers.reference_date` |
| Favouring Name | Text(255) | ✗ | Printed on the cheque-print layout | (appended to `narration`) |
| Narration | Textarea | ✗ | Recommended; ≤ 1000 chars | `acc_vouchers.narration` |
| Optional | Checkbox | ✗ | Memorandum voucher — not posted to ledgers | `acc_vouchers.is_optional` |
| Post-dated | Checkbox | ✗ | Excluded from current balances until date arrives | `acc_vouchers.is_post_dated` |

### 5.4 Business Rules

1. **BR-PAY-01** — At least one `Cr` line must be a Cash or Bank ledger (`is_cash_account=1` or `is_bank_account=1`). Warn (do not block) otherwise: *"No cash/bank ledger credited — is this really a Payment? Consider a Journal."*
2. **BR-PAY-02** — Negative cash warning: if posting drives a `is_cash_account=1` ledger below zero, show a blocking confirm — *"Cash balance will become negative (₹ -4,200). Continue?"* Bank ledgers warn but never block (overdraft is legitimate).
3. **BR-PAY-03** — Salary payments should target employee ledgers (`acc_ledgers.employee_id IS NOT NULL`); vendor payments target `vendor_id IS NOT NULL`. The ledger picker surfaces these as dedicated groups.
4. **BR-PAY-04** — On **Save & Post**, `status` is set to the `Posted` row of `acc_accounting_status_masters`; `entered_by` = current user. If the school's workflow requires approval, status is `Draft` until an approver acts.

---

## 6. VE-03 — RECEIPT VOUCHER `F6`

**Route:** `/accounting/vouchers/create?type=RECEIPT`
**Accounting rule:** Debit the Cash/Bank ledger, Credit the income or party ledger.
**School use:** fee collection, donation, grant, hostel/transport charges, library fine, sale of prospectus.

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  RECEIPT                                                    No. [ RCV-1187 ]   Date [ 29-Aug-2026 ]  │
│  Mode: ( ) Double Entry  (•) Single Entry                                                            │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Account  [ Cash A/c                                                            ▼ ]                  │
│           Current Balance: ₹ 1,86,400.00 Dr                                                          │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Particulars (received from / towards)             │ Cost Centre        │            Amount ₹        │
│ ───────────────────────────────────────────────────┼────────────────────┼────────────────────────────│
│  Aarav Singh (STD-00412, Class 5-A)                │ Primary Wing       │                45,000.00   │
│    ▸ Bill-wise: Term-2 Tuition Fee  ₹ 40,000                                                         │
│    ▸ Bill-wise: Transport Fee Aug   ₹  5,000                                    [Ctrl+Shift+B]       │
│  [ Select ledger…                                ] │ [ —              ▼]│           [           ]    │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                       TOTAL   ₹ 45,000.00            │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ▸ INSTRUMENT DETAILS                                                                  [expand ▼]    │
│     Received By [ Cash ▼]  Instrument No. [ —        ]  Instrument Date [ —          ]               │
│     Received From [ Mr. R. Singh (Father)                                                          ] │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Narration [ Term-2 fee + Aug transport received in cash ..................................... ]     │
│  ☐ Optional   ☐ Post-dated                       [Cancel]  [Save as Draft]  [Save & Post (Ctrl+A)]   │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 6.1 Receipt-Specific Behaviour

- **Student ledger search.** The ledger picker's first group is **Students (Sundry Debtors)** — rows from `acc_ledgers` where `student_id IS NOT NULL`, searchable by admission no., name, class and section (joined from `std_students`).
- **Outstanding panel.** Selecting a student ledger reveals a right-hand panel listing that student's outstanding demands with a *Settle* button per row; settling auto-fills the amount and stamps `acc_voucher_items.bill_reference`.
- **Print on save.** If F12 → *Print after saving* is on, saving opens the fee-receipt print preview immediately (`Ctrl+P` layout).
- **Cross-module receipts.** Receipts created automatically by the Fee/Library/Transport modules arrive through the event engine (`acc_module_events` → `acc_event_voucher_configs`). They open here **read-only** with a banner: *"Auto-generated from Student Fee module — edit the source record instead."* `source_module_id` / `source_category_id` identify the origin.

| Field | Req. | Notes | DDL Column |
|-------|:----:|-------|------------|
| Account | ✔ | Bank/Cash ledger only → becomes the `Dr` line | `acc_voucher_items` (`type='Dr'`) |
| Particulars ledger | ✔ | Student / income / party ledger → `Cr` lines | `acc_voucher_items.ledger_id` |
| Bill reference | ✗ | Free text or picked from outstanding panel | `acc_voucher_items.bill_reference` |
| Received From | ✗ | Payer name, printed on the receipt | (appended to `narration`) |
| Instrument No./Date | ✗* | Mandatory for cheque/DD | `reference_number`, `reference_date` |

**BR-RCV-01** — At least one `Dr` line must be a cash or bank ledger.
**BR-RCV-02** — A receipt against a student ledger must not exceed that student's outstanding balance unless *Allow advance receipt* is enabled in F12; excess is posted as an advance (credit balance).

---

## 7. VE-04 — CONTRA VOUCHER `F4`

**Route:** `/accounting/vouchers/create?type=CONTRA`
**Accounting rule:** Both sides are Cash/Bank. No income or expense ledger may appear.
**School use:** cash deposited into bank, cash withdrawn for petty expenses, transfer between the school's two bank accounts.

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CONTRA                                                     No. [ CON-0055 ]   Date [ 29-Aug-2026 ]  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Dr/Cr │ Particulars (Cash / Bank only)                     │            Debit ₹ │        Credit ₹   │
│ ───────┼────────────────────────────────────────────────────┼────────────────────┼───────────────────│
│   Dr   │ HDFC Bank — 50200012345678                         │        2,00,000.00 │                   │
│        │   Cur Bal: 42,18,900.00 Dr                         │                    │                   │
│   Cr   │ Cash A/c                                           │                    │     2,00,000.00   │
│        │   Cur Bal: 3,86,400.00 Dr                          │                    │                   │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                    TOTAL   │        2,00,000.00 │     2,00,000.00    │
│                                                    DIFFERENCE: ₹ 0.00  ✓ Balanced                    │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ▸ DEPOSIT SLIP DETAILS                        Slip No. [ DS-9921 ]   Deposit Date [ 29-Aug-2026 ]   │
│  ▸ CASH DENOMINATIONS (optional)               ₹500 × [ 300 ]  ₹200 × [ 150 ]  ₹100 × [ 200 ] = ₹2,00,000 │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Narration [ Fee collection of 28-Aug deposited to HDFC ....................................... ]    │
│                                                  [Cancel]  [Save as Draft]  [Save & Post (Ctrl+A)]   │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**BR-CON-01** — *Hard block:* every line's ledger must satisfy `is_cash_account = 1 OR is_bank_account = 1`. Error: *"Contra vouchers may only involve Cash and Bank accounts. Use a Payment or Journal voucher instead."*
**BR-CON-02** — The cash-denomination helper is a UI aid only; its total must equal the cash-side amount, and nothing from it is persisted in v1.
**BR-CON-03** — Same-ledger-both-sides is rejected.

---

## 8. VE-05 — JOURNAL VOUCHER `F7`

**Route:** `/accounting/vouchers/create?type=JOURNAL`
**Accounting rule:** Free-form multi-line double entry. No cash/bank restriction — but by convention cash/bank should *not* appear (use Payment/Receipt/Contra instead).
**School use:** fee accrual/demand posting, depreciation, scholarship & concession adjustments, provision entries, opening balance corrections, year-end closing entries.

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  JOURNAL                                                    No. [ JRN-0311 ]   Date [ 31-Aug-2026 ]  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Dr/Cr │ Particulars (Ledger Account)          │ Cost Centre      │        Debit ₹ │      Credit ₹   │
│ ───────┼───────────────────────────────────────┼──────────────────┼────────────────┼─────────────────│
│   Dr   │ Depreciation A/c                      │ —                │      88,750.00 │                 │
│        │   ↳ Furniture & Fixtures  ₹ 32,000                                                          │
│        │   ↳ Lab Equipment         ₹ 56,750                              [per-line narration on]     │
│   Cr   │ Accum. Depreciation — Furniture       │ —                │                │     32,000.00   │
│   Cr   │ Accum. Depreciation — Lab Equipment   │ —                │                │     56,750.00   │
│   ▸    │ [ Select ledger…                    ] │ [ —            ▼]│  [          ]  │  [           ]  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                  TOTAL │      88,750.00 │     88,750.00               │
│                                                  DIFFERENCE: ₹ 0.00  ✓ Balanced                      │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Narration [ Depreciation charged for FY 2026-27 as per SLM schedule ......................... ]     │
│  ☐ Optional (Memorandum)                         [Cancel]  [Save as Draft]  [Save & Post (Ctrl+A)]   │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Journal-specific behaviour**
- No Single Entry mode — journals are always explicit Dr/Cr (`Ctrl+H` is disabled with a tooltip).
- Unlimited lines; **n-way entries** are fully supported (many Dr against many Cr) — the DDL models each line independently in `acc_voucher_items`.
- Per-line narration is **on by default** for journals, since adjustment entries need line-level justification.
- **BR-JRN-01** — Soft warning when a cash/bank ledger is used: *"Cash/Bank in a Journal is unusual. Consider Payment (F5), Receipt (F6) or Contra (F4)."* Accountant may override.
- **BR-JRN-02** — Depreciation journals created by the Fixed Assets run (`acc_depreciation_entries`) open here read-only with a link back to the depreciation run.

---

## 9. VE-06 — SALES / FEE INVOICE `F8`

**Route:** `/accounting/vouchers/create?type=SALES`
**Accounting rule:** Debit the party (student/customer) ledger, Credit the income ledger(s) + tax ledgers.
**School use:** raising a fee demand, invoicing a service (transport, hostel, canteen), selling uniforms/books/prospectus.

TallyPrime offers two entry styles. Because v1 has **no inventory tables**, only the *Accounting Invoice* style is implemented; the *Item Invoice* style is deferred to v2 alongside the Inventory module.

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  SALES — Accounting Invoice                                 No. [ SAL-0233 ]   Date [ 01-Sep-2026 ]  │
│  Mode: (•) Accounting Invoice  ( ) Item Invoice [disabled — Inventory module not enabled]            │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Party A/c  [ Aarav Singh (STD-00412, Class 5-A)                                ▼ ]                  │
│  GSTIN [ —                ]   GST Reg. Type [ Unregistered ▼]   Place of Supply [ Maharashtra ▼ ]    │
│  Ref. / Bill No. [ FEE/2026-27/T2/00412 ]                    Due Date [ 15-Sep-2026 ]                │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Particulars (Income Ledger)               │ Cost Centre      │ Tax Rate  │            Amount ₹      │
│ ───────────────────────────────────────────┼──────────────────┼───────────┼──────────────────────────│
│  Tuition Fee Income                        │ Primary Wing     │ Exempt    │            40,000.00     │
│  Transport Fee Income                      │ Transport        │ 5% GST    │             5,000.00     │
│ ───────────────────────────────────────────┴──────────────────┴───────────┴──────────────────────────│
│                                                              Sub-total    ₹        45,000.00         │
│  CGST @2.5% (on ₹5,000)                                                   ₹           125.00         │
│  SGST @2.5% (on ₹5,000)                                                   ₹           125.00         │
│  Round Off                                                                ₹            -0.00         │
│                                                              GRAND TOTAL  ₹        45,250.00         │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Narration [ Term-2 fee demand incl. transport ................................................ ]    │
│                                       [Cancel]  [Save as Draft]  [Save & Post]  [Save & Print (Ctrl+P)] │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 9.1 Tax Handling

- The **Tax Rate** column lists active rows from `acc_tax_rates` (joined to `acc_tax_types`), plus `Exempt` and `Nil-rated`.
- **Intra-state vs inter-state** is decided by comparing the school's state with *Place of Supply*: intra-state splits into **CGST + SGST**, inter-state produces **IGST** — matching `acc_tax_rates.is_interstate`.
- Each computed tax amount is written as its **own `Cr` line** in `acc_voucher_items` against the corresponding GST ledger. Tax is not stored on the voucher header.
- Party GST fields are read from `acc_ledgers.gstin` / `gst_registration_type` and shown read-only; editing them opens the ledger master.

### 9.2 Resulting Double Entry

| Line | Dr/Cr | Ledger | Amount |
|------|-------|--------|--------|
| 1 | Dr | Aarav Singh (Sundry Debtor) | 45,250.00 |
| 2 | Cr | Tuition Fee Income | 40,000.00 |
| 3 | Cr | Transport Fee Income | 5,000.00 |
| 4 | Cr | CGST Output | 125.00 |
| 5 | Cr | SGST Output | 125.00 |

**BR-SAL-01** — Party ledger must belong to a group whose `nature = 'Asset'` (Sundry Debtors branch). Blocking error otherwise.
**BR-SAL-02** — Particulars ledgers must have `nature = 'Income'`; a warning (not a block) appears otherwise.
**BR-SAL-03** — Bulk fee demands are **not** raised here one student at a time. The Student Fee module generates them in batch through the event engine; this screen handles one-off and ad-hoc invoices.

---

## 10. VE-07 — PURCHASE VOUCHER `F9`

**Route:** `/accounting/vouchers/create?type=PURCHASE`
**Accounting rule:** Debit the expense/asset ledger + input tax ledgers, Credit the vendor ledger.
**School use:** vendor bill for library books, lab equipment, uniforms, stationery, AMC and service contracts.

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PURCHASE — Accounting Invoice                              No. [ PUR-0178 ]   Date [ 29-Aug-2026 ]  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Party A/c  [ Sharma Book Depot (VND-0021)                                      ▼ ]                  │
│  GSTIN [ 27AABCS1234C1ZV ]   GST Reg. Type [ Regular ▼]   Place of Supply [ Maharashtra ▼ ]          │
│  Supplier Invoice No. [ SBD/26-27/0912 ]   Supplier Inv. Date [ 27-Aug-2026 ]  Due [ 26-Sep-2026 ]   │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Particulars (Expense / Asset Ledger)      │ Cost Centre      │ Tax Rate  │            Amount ₹      │
│ ───────────────────────────────────────────┼──────────────────┼───────────┼──────────────────────────│
│  Library Books (Fixed Asset)               │ Library          │ 12% GST   │          1,50,000.00     │
│  Stationery Expense                        │ Admin Office     │ 18% GST   │            22,000.00     │
│ ───────────────────────────────────────────┴──────────────────┴───────────┴──────────────────────────│
│                                                              Sub-total    ₹      1,72,000.00         │
│  CGST (₹9,000 + ₹1,980)                                                   ₹         10,980.00        │
│  SGST (₹9,000 + ₹1,980)                                                   ₹         10,980.00        │
│                                                              GRAND TOTAL  ₹      1,93,960.00         │
│  Input Tax Credit eligible: ✓ Yes (vendor is GST-Regular)                                            │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Narration [ Library book purchase — PO/2026/0088 .............................................. ]   │
│                                                  [Cancel]  [Save as Draft]  [Save & Post (Ctrl+A)]   │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Purchase-specific behaviour**
- Party picker is scoped to vendor ledgers first (`acc_ledgers.vendor_id IS NOT NULL`).
- **ITC eligibility banner** is driven by `acc_ledgers.gst_registration_type`: `Regular`/`SEZ` → eligible; `Composition`/`Unregistered`/`Consumer` → not eligible, and the tax lines post to an expense ledger rather than an Input GST ledger.
- **Supplier Invoice No./Date** map to `acc_vouchers.reference_number` / `reference_date`, and are validated as unique per vendor per FY (duplicate-bill guard).
- Purchasing a fixed asset offers an inline prompt: *"Create a Fixed Asset record for 'Library Books'?"* → links through to `acc_fixed_assets`.

---

## 11. VE-08 — CREDIT NOTE `Alt+F6` & DEBIT NOTE `Alt+F5`

**Route:** `/accounting/vouchers/create?type=CREDIT_NOTE` | `?type=DEBIT_NOTE`

| | **Credit Note** | **Debit Note** |
|---|---|---|
| Reverses | A Sales / fee demand | A Purchase / vendor bill |
| School use | Fee concession, scholarship, waiver, cancelled demand, over-billing correction | Goods returned to vendor, vendor over-billed, damaged supply |
| Entry | **Dr** Income (or Concession A/c), **Cr** Party | **Dr** Party, **Cr** Expense/Asset |
| Mandatory link | Original Sales voucher reference | Original Purchase voucher reference |

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CREDIT NOTE                                                No. [ CNT-0009 ]   Date [ 05-Sep-2026 ]  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Party A/c   [ Aarav Singh (STD-00412, Class 5-A)                               ▼ ]                  │
│  Against Invoice  [ SAL-0233  ·  01-Sep-2026  ·  ₹45,250.00                     ▼ ]  [Clear]         │
│  Reason      [ Merit Scholarship — 25% tuition concession                                          ] │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Particulars (Ledger to Debit)             │ Cost Centre      │ Tax Rate  │            Amount ₹      │
│ ───────────────────────────────────────────┼──────────────────┼───────────┼──────────────────────────│
│  Fee Concession A/c                        │ Primary Wing     │ Exempt    │            10,000.00     │
│ ───────────────────────────────────────────┴──────────────────┴───────────┴──────────────────────────│
│                                                              GRAND TOTAL  ₹        10,000.00         │
│  Note: Party balance after this note → ₹ 35,250.00 Dr                                                │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Narration [ 25% merit scholarship approved by Principal vide MoM 12-Aug-2026 .................. ]   │
│                                                  [Cancel]  [Save as Draft]  [Save & Post (Ctrl+A)]   │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**BR-CN-01** — *Against Invoice* is mandatory and restricted to Posted/Approved Sales vouchers for the same party in the same FY.
**BR-CN-02** — The note total may not exceed the original invoice value minus any earlier credit notes against it. The picker shows the remaining creditable balance.
**BR-CN-03** — The original voucher's id is stored in `acc_voucher_items.bill_reference` on the party line (format `VCH:{voucher_id}`), and the voucher view renders a two-way link between the pair.
**BR-CN-04** — Credit notes always require approval (`acc.voucher.approve`) regardless of school workflow settings — a concession is a revenue write-off.

---

## 12. SHARED SUB-SCREENS

### 12.1 VE-S1 — Ledger Picker

Invoked from any *Particulars* / *Account* cell. Type-ahead over `acc_ledgers`, grouped by `acc_account_groups`.

```ascii
┌───────────────────────────────────────────────────────────────────────┐
│  SELECT LEDGER                                                   [✕]  │
├───────────────────────────────────────────────────────────────────────┤
│  [ hdf|                                                        🔍 ]   │
│  Filter: [All Groups ▼]        ☐ Show inactive     [+ Create (Alt+C)] │
├───────────────────────────────────────────────────────────────────────┤
│  ▾ BANK ACCOUNTS                                                      │
│      HDFC Bank — 50200012345678            42,18,900.00 Dr            │
│      HDFC Bank — Salary A/c                 6,40,000.00 Dr            │
│  ▾ CASH-IN-HAND                                                       │
│      Cash A/c                               1,86,400.00 Dr            │
│      Petty Cash — Admin                        12,500.00 Dr           │
│  ▾ SUNDRY DEBTORS › STUDENTS                                          │
│      Aarav Singh (STD-00412, 5-A)              45,250.00 Dr           │
│  ▾ SUNDRY CREDITORS › VENDORS                                         │
│      Sharma Book Depot (VND-0021)            1,93,960.00 Cr           │
├───────────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate   Enter select   Alt+C create new   Esc cancel           │
└───────────────────────────────────────────────────────────────────────┘
```

- Search matches ledger `name`, `alias`, `code`, and — for student/vendor/employee ledgers — the linked master's name and code.
- Groups reflect the `acc_account_groups` hierarchy (`parent_id` tree), with `is_subledger` groups rendered as a nested tier.
- Only `is_active = 1` ledgers are selectable unless *Show inactive* is ticked (view-only, cannot be chosen for a new voucher).
- **Alt+C** opens a compact ledger-create modal (name, group, opening balance, bank/cash flags) and returns the new ledger straight into the cell.
- The right column shows the ledger's `closing_balance` + `closing_balance_type`.

### 12.2 VE-S2 — Cost Centre Allocation

For splitting one line across several cost centres (`Ctrl+Shift+C`).

```ascii
┌───────────────────────────────────────────────────────────────────────┐
│  COST CENTRE ALLOCATION — Electricity Charges  ₹ 1,24,500.00     [✕]  │
├───────────────────────────────────────────────────────────────────────┤
│  Cost Centre                    │        %  │              Amount ₹   │
│ ────────────────────────────────┼───────────┼─────────────────────────│
│  Primary Wing                   │    50.00  │             62,250.00   │
│  Secondary Wing                 │    30.00  │             37,350.00   │
│  Hostel Block                   │    20.00  │             24,900.00   │
│  [ Select cost centre…        ] │  [     ]  │           [         ]   │
├───────────────────────────────────────────────────────────────────────┤
│                        ALLOCATED  100.00 %              ₹ 1,24,500.00 │
│                        UNALLOCATED                      ₹         0.00│
│                                              [Cancel]     [Allocate]  │
└───────────────────────────────────────────────────────────────────────┘
```

> ⚠️ **Schema limitation.** `acc_voucher_items` carries a *single* `cost_center_id`. A true multi-way split needs either a child table (`acc_voucher_item_cost_allocations`) or one voucher line per cost centre. **v1 implements the split by writing one `acc_voucher_items` row per cost centre**, all against the same ledger — the modal is a convenience wrapper over that. Entering the percentages above produces three `Dr` rows for Electricity Charges. This is recorded as a DDL gap in §16.

### 12.3 VE-S3 — Bill-wise / Reference Allocation

`Ctrl+Shift+B` from a party line. Mirrors Tally's *Bill-wise Details*.

```ascii
┌────────────────────────────────────────────────────────────────────────────────┐
│  BILL-WISE DETAILS — Aarav Singh   Receipt ₹ 45,000.00                    [✕]  │
├────────────────────────────────────────────────────────────────────────────────┤
│  Method     │ Reference             │  Due Date   │  Outstanding │  Allocate ₹ │
│ ────────────┼───────────────────────┼─────────────┼──────────────┼─────────────│
│  Agst Ref   │ FEE/T2/00412          │ 15-Sep-2026 │    40,000.00 │   40,000.00 │
│  Agst Ref   │ TPT/AUG/00412         │ 10-Sep-2026 │     5,000.00 │    5,000.00 │
│  Agst Ref   │ FEE/T3/00412          │ 15-Dec-2026 │    40,000.00 │        0.00 │
│  New Ref    │ [ ADV-00412         ] │ [        ]  │          —   │        0.00 │
├────────────────────────────────────────────────────────────────────────────────┤
│  Sort: [Due date ▼]      ALLOCATED ₹ 45,000.00      UNALLOCATED ₹ 0.00         │
│                                                       [Cancel]     [Apply]     │
└────────────────────────────────────────────────────────────────────────────────┘
```

- Allocation methods: **Agst Ref** (settle an existing bill), **New Ref** (create a new tracked bill), **Advance** (money received before a demand), **On Account** (unallocated).
- Sort options: due date, bill date, outstanding amount — as in Tally.
- **BR-BW-01** — Total allocated must equal the line amount before *Apply* is enabled, unless *On Account* is used for the remainder.

> ⚠️ **Schema limitation.** `acc_voucher_items.bill_reference` is a single `VARCHAR(100)`. Multi-bill allocation against one line requires a child table (`acc_voucher_bill_allocations`). **v1 behaviour:** allocating across N bills writes N `acc_voucher_items` rows against the same party ledger, one per bill reference. See §16.

### 12.4 VE-S4 — Bank Allocation Details

Inline expandable panel (not a modal) shown on Payment, Receipt and Contra when the selected Account ledger has `is_bank_account = 1`.

| Field | Options / Rule | Persisted As |
|-------|----------------|--------------|
| Transaction Type | Cheque · e-Fund Transfer (NEFT/RTGS/IMPS) · UPI · Cash · Demand Draft · Card · Others | prefix of `reference_number` (e.g. `CHQ:884512`) |
| Instrument No. | Mandatory for Cheque/DD | `acc_vouchers.reference_number` |
| Instrument Date | Mandatory for Cheque/DD; a future date auto-ticks *Post-dated* | `acc_vouchers.reference_date` |
| Bank Date | Set later during reconciliation, not on entry | `acc_bank_statement_entries.matched_at` |
| Favouring / Received From | Free text, used by the cheque-print layout | appended to `narration` |
| Reconciliation Status | Read-only on entry; shows `Pending` until matched in Bank Reconciliation | `acc_bank_reconciliations.status` |

Ledgers with `allow_reconciliation = 1` display an extra hint under the panel: *"This voucher will appear in Bank Reconciliation for HDFC Bank."*

### 12.5 VE-S5 — Voucher Configuration `F12`

Per-user, per-voucher-type UI preferences (stored in user settings, not in `acc_*` tables).

```ascii
┌───────────────────────────────────────────────────────────────────────┐
│  VOUCHER CONFIGURATION — Payment                                 [✕]  │
├───────────────────────────────────────────────────────────────────────┤
│  ENTRY                                                                │
│   ☑ Use Single Entry mode by default                                  │
│   ☑ Show ledger current balance in the grid                           │
│   ☐ Show per-ledger narration line                                    │
│   ☑ Show cost centre column                                           │
│   ☐ Warn on negative cash balance                    (☑ = block)      │
│  ALLOCATION                                                           │
│   ☑ Enable bill-wise details for party ledgers                        │
│   ☐ Pre-allocate bills before entering the amount                     │
│  BANKING                                                              │
│   ☑ Show bank allocation details                                      │
│   ☑ Show bank reconciliation status                                   │
│  ON SAVE                                                              │
│   ☐ Print after saving                                                │
│   ☑ Open a new voucher of the same type after saving                  │
│                                              [Reset]        [Save]    │
└───────────────────────────────────────────────────────────────────────┘
```

### 12.6 VE-S6 — Cancel Voucher Modal `Alt+X`

Posted vouchers are **never deleted** — they are cancelled, preserving the number in the audit trail.

```ascii
┌───────────────────────────────────────────────────────────────────────┐
│  CANCEL VOUCHER — PAY-0042                                       [✕]  │
├───────────────────────────────────────────────────────────────────────┤
│  This voucher will be marked Cancelled. Its number is retained and    │
│  will not be reused. Ledger balances will be reversed.                │
│                                                                       │
│  Reason *  [ Cheque 884512 returned unpaid by bank ................ ] │
│            [ ................................................... ]   │
│                                                                       │
│                                     [Keep Voucher]   [Cancel Voucher] │
└───────────────────────────────────────────────────────────────────────┘
```

Sets `is_cancelled = 1`, `cancelled_reason`, and `status` → the `Cancelled` row of `acc_accounting_status_masters`.

---

## 13. VE-09 / VE-10 / VE-11 — VIEW, DAY BOOK, APPROVALS

### 13.1 VE-09 Voucher View (read-only)

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ACCOUNTING > VOUCHERS > PAY-0042                                                 [Posted ●]          │
│ [◀ Prev] [Next ▶]        [Print Ctrl+P] [Duplicate Ctrl+N] [Edit] [Cancel Voucher Alt+X] [Export]    │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Payment · PAY-0042 · 29-Aug-2026                     Ref: CHQ-884512 dt. 28-Aug-2026                │
│  ───────────────────────────────────────────────────────────────────────────────────────────────     │
│   Dr  Electricity Charges          Primary Wing                        1,24,500.00                   │
│   Cr  HDFC Bank — 50200012345678                                                     1,24,500.00     │
│  ───────────────────────────────────────────────────────────────────────────────────────────────     │
│                                                    TOTAL   1,24,500.00               1,24,500.00     │
│                                                                                                      │
│  Narration: Electricity bill for Aug-2026 paid vide cheque 884512                                    │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  AUDIT TRAIL                                                                                         │
│   Entered by  : R. Kulkarni (Accountant)          29-Aug-2026 11:04                                  │
│   Approved by : S. Mehta (School Admin)           29-Aug-2026 15:22                                  │
│   Source      : Manual entry (Accounting module)                                                     │
│   Bank Recon  : Pending                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

- **Edit** is available only when `status = Draft`, or to Super Admin within the F12-configured edit window.
- The audit block renders `entered_by`, `approved_by`, `created_at`, `updated_at`, and — for auto-generated vouchers — a link to `acc_event_processing_log`.

### 13.2 VE-10 Day Book

Chronological register of every voucher for a date or range — Tally's *Day Book*.

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ACCOUNTING > DAY BOOK                     Period: [29-Aug-2026] to [29-Aug-2026]   [F2 Change Period] │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ TYPE: [All ▼]   STATUS: [All ▼]   COST CENTRE: [All ▼]   ☐ Include optional  ☐ Include cancelled     │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Date        │ Particulars                              │ Vch Type │ Vch No   │ Debit ₹  │ Credit ₹   │
│─────────────┼──────────────────────────────────────────┼──────────┼──────────┼──────────┼────────────│
│ 29-Aug-2026 │ Electricity Chgs / HDFC Bank             │ Payment  │ PAY-0042 │ 1,24,500 │  1,24,500  │
│ 29-Aug-2026 │ Cash A/c / Aarav Singh                   │ Receipt  │ RCV-1187 │   45,000 │    45,000  │
│ 29-Aug-2026 │ HDFC Bank / Cash A/c                     │ Contra   │ CON-0056 │ 2,00,000 │  2,00,000  │
│─────────────┴──────────────────────────────────────────┴──────────┴──────────┼──────────┼────────────│
│                                                            DAY TOTAL         │ 3,69,500 │  3,69,500  │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 13.3 VE-11 Pending Approvals

Queue of vouchers with `status = Draft` awaiting an approver, plus vouchers with `is_optional = 1` awaiting conversion to regular.

| Column | Source |
|--------|--------|
| Date, Voucher No, Type, Amount | `acc_vouchers` |
| Entered By | `sys_users` via `entered_by` |
| Ageing (days pending) | `NOW() - created_at` |
| Source | `acc_voucher_modules.name` via `source_module_id` |
| Actions | **Approve** · **Reject (→ back to entrant with a note)** · **Open** |

Bulk approve is available; each approval writes `approved_by` and moves `status` to `Approved`.

---

## 14. CROSS-MODULE (AUTO-GENERATED) VOUCHERS

Vouchers created by other modules through the event engine (`acc_module_events` → `acc_event_voucher_configs` → `acc_event_voucher_line_templates`) surface in the same screens with distinct treatment:

| Aspect | Manual voucher | Auto-generated voucher |
|--------|----------------|------------------------|
| `source_module_id` | Accounting | Fee / Library / Transport / Hostel / Payroll |
| `source_category_id` | NULL | e.g. `LIBRARY_FINE`, `TRANSPORT_FINE` |
| Editability | Full (while Draft) | **Read-only** — a banner links to the source record |
| Status on creation | `Draft` or `Posted` | Per config: `is_auto_post=1 & requires_approval=0` → `Auto_Post`; `1 & 1` → `Auto_Approved`; `is_auto_post=0` → `Draft` |
| Badge | — | 🔗 *Auto* chip beside the voucher number |

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ⓘ  This voucher was generated automatically from the Library module (Library Fine, lib_fines#8842).  │
│    It cannot be edited here. [Open source record →]   [View event log →]                             │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 15. VALIDATION SUMMARY

### 15.1 Blocking Errors

| Code | Condition | Message |
|------|-----------|---------|
| E-01 | Total Debit ≠ Total Credit | "Voucher is out of balance by ₹ {diff}. Debits must equal credits." |
| E-02 | Fewer than 2 line items | "A voucher needs at least one debit and one credit line." |
| E-03 | Any line amount ≤ 0 | "Line amounts must be greater than zero." |
| E-04 | Voucher date outside the selected FY | "Date must fall within FY {name} ({start} – {end})." |
| E-05 | FY `is_locked = 1` | "FY {name} is locked. No new entries or edits are permitted." |
| E-06 | Duplicate voucher number in the FY | "Voucher number {no} already exists for FY {name}." |
| E-07 | Contra with a non-cash/bank ledger | "Contra vouchers may only involve Cash and Bank accounts." |
| E-08 | Inactive ledger selected | "Ledger '{name}' is inactive and cannot be used." |
| E-09 | Same ledger on both sides with identical amount | "Debit and credit sides cannot be the same ledger." |
| E-10 | Credit Note total > creditable balance of the linked invoice | "Credit note cannot exceed the outstanding invoice value of ₹ {amt}." |
| E-11 | Cheque selected without Instrument No./Date | "Instrument number and date are required for cheque transactions." |
| E-12 | Editing a Posted/Approved voucher without privilege | "Posted vouchers cannot be edited. Cancel and re-enter, or contact an administrator." |
| E-13 | Back-dating beyond the allowed window without `acc.voucher.backdate` | "You cannot record entries older than {n} days." |

### 15.2 Non-Blocking Warnings

| Code | Condition | Message |
|------|-----------|---------|
| W-01 | Cash balance would go negative | "Cash A/c will become negative (₹ {bal}). Continue?" |
| W-02 | Bank balance would go negative | "HDFC Bank will be overdrawn by ₹ {amt}." |
| W-03 | Cash/bank ledger used in a Journal | "Consider Payment (F5), Receipt (F6) or Contra (F4) instead." |
| W-04 | Payment with no cash/bank on the credit side | "No cash or bank account credited — is this really a Payment?" |
| W-05 | Empty narration | "Narration is empty. Add a description for the audit trail?" |
| W-06 | Receipt exceeds the student's outstanding balance | "₹ {excess} will be recorded as an advance." |
| W-07 | Duplicate supplier invoice number for the same vendor | "Bill {no} was already recorded on {date} (PUR-{n})." |
| W-08 | Expense ledger with no cost centre | "No cost centre selected — this entry will be unallocated in budget reports." |

### 15.3 Save & Post Sequence

```
1. Client validation (E-01…E-13)         → block on failure
2. Confirm warnings (W-01…W-08)          → user acknowledges
3. BEGIN TRANSACTION
4.   Lock acc_voucher_types row           (SELECT … FOR UPDATE)
5.   voucher_number = last_number + 1;  UPDATE last_number
6.   INSERT acc_vouchers  (status = Draft | Posted per workflow)
7.   INSERT acc_voucher_items  (n rows)
8.   Re-verify Σ(Dr) = Σ(Cr) = total_amount  server-side
9.   If status is Posted → update acc_ledgers.closing_balance for each ledger
10. COMMIT
11. Post-commit: fire notification to approvers if status = Draft
```

**Number reservation is deliberately deferred to step 5**, inside the transaction and behind a row lock, so that concurrent accountants never collide on a voucher number. The number shown during data entry is a *preview only* and is re-computed on save.

---

## 16. DDL OBSERVATIONS & GAPS

These surfaced while mapping the screens onto `Accounting_DDL_v4.sql`. They are reported here, not fixed — the DDL is owned separately.

### 16.1 Errors that will prevent the DDL from executing

| # | Table | Line ref | Issue |
|---|-------|----------|-------|
| 1 | `acc_voucher_category` | L61–62 vs L70–71 | FK constraints `fk_vc_debit_ledger` / `fk_vc_credit_ledger` reference `debit_ledger_id` and `credit_ledger_id`, but **both columns are commented out**. The `CREATE TABLE` will fail. |
| 2 | `acc_voucher_category` | L70–71 | Both FKs reference `acc_ledgers`, defined **later** in the file (L206, Section 2). Forward reference — needs reordering or `SET FOREIGN_KEY_CHECKS=0`. |
| 3 | `acc_vouchers` | L312 | `idx_acc_voucher_source` indexes `source_module`, but the column (L295) is named **`source_module_id`**. |
| 4 | `acc_vouchers` | L314 | `idx_acc_voucher_composite` indexes `date`, but the column (L285) is named **`voucher_date`**. |
| 5 | `acc_vouchers` | L279–321 | The change log says *"Add `voucher_category_id`"* to `acc_vouchers`, but the column and its FK are **absent** from the table definition. Screens derive the category via `voucher_type_id → acc_voucher_types.voucher_category_id`; confirm whether the denormalised column is still wanted. |
| 6 | `acc_event_processing_log` | L877 vs L280 | `voucher_id` is `BIGINT UNSIGNED` with an FK to `acc_vouchers.id`, which is **`INT UNSIGNED`** (L280). Type mismatch — the FK will be rejected. |
| 7 | `acc_event_voucher_line_templates` | L819 vs L206 | `ledger_id` is `INT UNSIGNED` with an FK to `acc_ledgers.id`, which is **`MEDIUMINT UNSIGNED`** (L206). Same mismatch. |

### 16.2 Gaps relative to the screens specified here

| # | Need | Current state | Suggested addition |
|---|------|---------------|--------------------|
| 1 | Multi-cost-centre split on one line (§12.2) | Single `acc_voucher_items.cost_center_id` | `acc_voucher_item_cost_allocations (voucher_item_id, cost_center_id, percentage, amount)` |
| 2 | Bill-wise allocation across several bills (§12.3) | Single `bill_reference VARCHAR(100)` | `acc_voucher_bill_allocations (voucher_item_id, method, reference, due_date, amount)` |
| 3 | Structured bank instrument data (§12.4) | Squeezed into `reference_number` / `reference_date` | `acc_voucher_bank_details (voucher_id, transaction_type, instrument_no, instrument_date, bank_date, favouring_name)` |
| 4 | Tax breakup per line on Sales/Purchase (§9.1) | Tax lands as extra `acc_voucher_items` rows; the source rate is not retained | `acc_voucher_items.tax_rate_id` (FK → `acc_tax_rates`), plus `taxable_amount` |
| 5 | Credit/Debit Note → original invoice link (§11) | Encoded in `bill_reference` as text | `acc_vouchers.against_voucher_id` (self-FK) |
| 6 | Reversing Journal (`applicable_upto`) | Not modelled | `acc_vouchers.applicable_upto DATE NULL` |
| 7 | Line ordering in the grid | No sequence column on `acc_voucher_items` | `acc_voucher_items.sequence TINYINT UNSIGNED` — otherwise line order on re-open depends on `id` |
| 8 | Due date on Sales/Purchase invoices (§9, §10) | Not modelled | `acc_vouchers.due_date DATE NULL` |
| 9 | Approval timestamp | `approved_by` exists; no `approved_at` | `acc_vouchers.approved_at TIMESTAMP NULL` |
| 10 | Voucher type ↔ mode defaults | Not modelled | `acc_voucher_types.default_entry_mode ENUM('Single','Double')`, `allow_zero_value TINYINT(1)` — both are configurable per voucher type in Tally |

---

## 17. API SURFACE (indicative)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/accounting/vouchers` | List / search (filters: type, status, date range, cost centre, source module) |
| `GET` | `/api/accounting/vouchers/{id}` | Voucher with items, ledger names, audit trail |
| `POST` | `/api/accounting/vouchers` | Create (Draft or Posted) |
| `PUT` | `/api/accounting/vouchers/{id}` | Update — Draft only |
| `POST` | `/api/accounting/vouchers/{id}/post` | Draft → Posted (writes ledger balances) |
| `POST` | `/api/accounting/vouchers/{id}/approve` | Posted → Approved |
| `POST` | `/api/accounting/vouchers/{id}/cancel` | Sets `is_cancelled`, `cancelled_reason` |
| `GET` | `/api/accounting/vouchers/next-number?type_id=` | Voucher-number preview |
| `GET` | `/api/accounting/ledgers/search?q=&group=` | Ledger picker feed |
| `GET` | `/api/accounting/ledgers/{id}/balance?as_on=` | Live balance shown in the grid |
| `GET` | `/api/accounting/ledgers/{id}/outstanding` | Bill-wise panel feed |
| `GET` | `/api/accounting/cost-centres` | Cost centre dropdown |
| `GET` | `/api/accounting/tax-rates` | Tax dropdown on Sales/Purchase |
| `GET` | `/api/accounting/day-book?from=&to=` | Day Book |

All endpoints are tenant-scoped: voucher data lives in **`tenant_db`**, never in `prime_db`.

---

## 18. OUT OF SCOPE FOR v1

1. **Inventory vouchers** — Delivery Note, Receipt Note, Stock Journal, Physical Stock, Rejection In/Out. Require the Inventory module and stock-item tables.
2. **Order vouchers** — Sales Order, Purchase Order.
3. **Item Invoice mode** on Sales/Purchase (quantity × rate lines) — depends on stock items.
4. **Reversing Journal** — needs `applicable_upto` (§16.2 #6).
5. **Voucher Classes** — Tally's templating layer that pre-fills ledgers and auto-computes taxes for a voucher type.
6. **Multi-currency** — the DDL has no currency table; ₹ is assumed throughout.
7. **POS voucher** — not applicable to schools.
8. **Cheque printing layouts** — the data is captured (§12.4); the print templates are a separate deliverable.

---

## 19. CHANGE LOG

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 29-Aug-2026 | Claude (DB/Screen Design) | Initial Voucher Entry screen design for Accounting module, mapped to `Accounting_DDL_v4.sql`. Covers the 9 in-scope accounting voucher types, 6 shared sub-screens, validation rules, and a DDL gap analysis. |

---

## 20. REFERENCES

- TallyPrime — *Voucher Types*: https://help.tallysolutions.com/voucher-types-tally/
- TallyPrime — *Record Accounting Entry*: https://help.tallysolutions.com/tally-prime/accounting/accounting-entry-tally/
- TallyPrime — *Payments and Receipts*: https://help.tallysolutions.com/tally-prime/accounting/payments-and-receipts-tally/
- TallyPrime — *Keyboard Shortcuts*: https://help.tallysolutions.com/tally-prime/keyboard-shortcuts/keyboard-shortcuts-tally-prime/
- Internal — `1-New_Enhancements/Accounting/Accounting_DDL_v4.sql`
- Internal — `AI_Brain/memory/conventions.md` (module prefixes, naming)
- Internal — `8-Support_Docs/9-Templates/Screen_Sample.md` (screen-doc house style)
