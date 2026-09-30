# Prime-AI Accounting Module — Data Dictionary

**Document ID:** ACC-DD-V4.6
**Version:** 1.1
**Date:** 2026-09-09
**Describes:** `Accounting_DDL_v4.6.sql` — 75 tables, 22 views
**Supersedes:** `Dictionary_DDL_v4.5.md` — same schema, less the `del_marker` column
**Database:** TENANT database only · MySQL 8.0.16+ · InnoDB · utf8mb4
**Prefix:** `acc_`

**Companion documents:** `Accounting_BRD_v2.md` (what the business needs) · `Solution_Design_v1.md` (how it works) · `ScreenDesign_v2.1.md` (voucher entry screens)

---

## How to read this dictionary

Every table has the same four parts:

| Part | What it tells you |
|---|---|
| **What it is for** | Plain-English purpose, in two or three sentences |
| **Example row** | Realistic data, so the shape of the table is obvious at a glance |
| **Columns** | Every column: type, nullability, meaning, and an example value |
| **Keys & rules** | Unique keys, foreign keys, CHECK constraints, and behaviour worth knowing |

### Notation

| Symbol | Meaning |
|---|---|
| **PK** | Primary key |
| **UK** | Part of a unique key |
| **FK** | Foreign key — the parent table is named |
| **GEN** | Generated column. MySQL calculates it; **you never write to it** |
| **CACHE** | Derived from `acc_voucher_items` by a named service. Rebuildable, never authoritative |
| **FROZEN** | Copied at the moment of posting and never read back from the master |
| ✔ / — | Column allows NULL / does not allow NULL |

---

## The four rules this schema exists to enforce

Everything in this database follows from these. If a design choice below looks odd, it is almost always one of these four rules being obeyed.

| # | Rule | What it means in practice |
|---|---|---|
| **R-01** | **Debits equal credits, in every posted voucher, always** | `Σ Dr = Σ Cr` on every voucher. A voucher that does not balance cannot post |
| **R-02** | **Only POSTED transactions count** | Draft, Pending_Approval, Rejected and provisional vouchers affect **no** balance, **no** report, **no** outstanding figure |
| **R-03** | **Posted is immutable** | You correct by **reversal**, never by editing. A posted voucher's lines are never updated |
| **R-05** | **Balances are DERIVED, never asserted** | Every balance in this schema traces back to `acc_voucher_items`. There is no "the balance is what someone typed" |

> **Rule R-05 is why `acc_ledgers` has no `closing_balance` column.** Earlier versions stored one with no rule for keeping it true. A stored balance with no maintenance rule is a number that will eventually disagree with the transactions behind it, and nothing will notice. Balances now live in `acc_ledger_period_balances` — a cache with a named owner (`PostingService`), a rebuild command (`acc:rebuild-balances`) and a nightly assertion that the rebuild changes nothing.

---

## Patterns used throughout — explained once

### 1. The audit columns

Most tables carry these. They are described here and **not repeated** in each table below.

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `created_by` | INT UNSIGNED | ✔ | Who created the row. FK → `sys_users.id` | `14` |
| `updated_by` | INT UNSIGNED | ✔ | Who last changed it. FK → `sys_users.id` | `22` |
| `created_at` | TIMESTAMP | — | When created. Defaults to now | `2026-09-09 10:14:22` |
| `updated_at` | TIMESTAMP | — | Auto-updated on every change | `2026-09-09 16:02:05` |
| `deleted_at` | TIMESTAMP | ✔ | **Soft delete.** NULL = live. A date = hidden but retained | `NULL` |

All FKs to `sys_users` are `ON DELETE SET NULL`, so removing a staff account never destroys the record of what they did.

### 2. Uniqueness is absolute — a code or a name is never reused

```sql
`deleted_at`  TIMESTAMP NULL,
UNIQUE KEY (`code`),
UNIQUE KEY (`name`)
```

**A code or a name is unique across the whole table — live rows and soft-deleted rows alike.**

**What this replaces.** v4.3 used `UNIQUE(code, deleted_at)`, which does not work at all: MySQL treats every `NULL` as distinct, so **any number of live rows could share the same code**. The constraint existed and enforced nothing. v4.4 and v4.5 fixed that with a generated `del_marker` column (`0` while live, the deletion timestamp once deleted) carried in 30 tables, which made the key soft-delete aware and therefore **allowed a code to be re-issued once its first holder was deleted**.

**v4.6 removes `del_marker` entirely and narrows those keys.** The reasoning is the business rule, not the storage. There is no good reason to create a second account group, cost category, ledger, cost centre, voucher type or tax type carrying a code or a name that a deleted row already holds. The deleted row's name still appears in reports, in the audit trail and in last year's accounts, so handing it to a different entity is a reporting defect dressed up as a convenience. Blocking it at the key costs nothing; 30 stored columns and 30 wider indexes did.

> **`deleted_at` is unchanged. Soft delete still works exactly as before** — it simply no longer widens a unique key.

**What this means when you build the UI.** Re-creating a soft-deleted master now fails with **ER_DUP_ENTRY (1062)**. The right response is not a raw error, it is an offer:

> *"A deleted Account Group already uses the code `SUNDRY_DEBTORS`. Restore it?"*

Every create form on a table listed under *"Codes are retired for good"* below must catch 1062 and offer **Restore**, not **Insert**.

### 3. The `*_marker` columns — NULL-safe unique keys

The same MySQL NULL problem appears whenever a unique key spans a **nullable** column. The fix is the same:

```sql
`cost_center_id`  INT UNSIGNED NULL,
`cc_marker`       INT UNSIGNED GENERATED ALWAYS AS (IFNULL(`cost_center_id`,0)) STORED,
UNIQUE KEY (`ledger_id`, `period_id`, `cc_marker`, `fund_marker`, `campus_marker`)
```

Without `cc_marker`, "the balance of ledger 42 in period 6 with no cost centre" could exist **many times over**, and every one of them would look correct.

Tables using this pattern: `acc_voucher_number_sequences` (`period_marker`) · `acc_ledger_period_balances` · `acc_opening_balances` · `acc_fund_balances` · `acc_budget_lines` · `acc_event_voucher_configs` · `acc_ledger_mappings` · `acc_settings` · `acc_interest_computations`.

> **The `*_marker` columns are described here once and generally not repeated in each table below**, the same way the audit columns are. Where a table's unique key depends on one, the key definition in that table's *Keys & rules* names it. They are all `GENERATED … STORED`: **never write to them.**
>
> **These markers have nothing to do with soft delete.** They exist because a unique key spanning a *nullable dimension* column would otherwise permit duplicate rows. They were not removed in v4.6 and they are not going anywhere.

### Codes are retired for good — the tables this applies to

A code or name used on any of these can never be given to another row, whether or not the first holder was deleted:

| Group | Tables |
|---|---|
| **Masters — restore, don't re-create** | `acc_campuses` · `acc_account_groups` · `acc_ledgers` · `acc_cost_categories` · `acc_cost_centers` · `acc_funds` · `acc_voucher_category` · `acc_voucher_types` · `acc_tax_types` · `acc_tax_rules` · `acc_asset_categories` · `acc_recurring_templates` · `acc_interest_rules` · `acc_exception_rules` · `acc_module_events` · `acc_ledger_mappings` · `acc_tally_ledger_mappings` · `acc_event_voucher_configs` |
| **Numbered documents — already never reused** | `acc_expense_claims` (`claim_number`) · `acc_concessions` (`concession_no`) · `acc_grants` (`grant_code`) · `acc_budgets` (`code` + `version`) · `acc_fixed_assets` (`asset_code`) |
| **Delete-and-re-enter is blocked; restore instead** | `acc_bank_reconciliations` (bank + `statement_date`) · `acc_cheque_registers` (bank + `book_number`) · `acc_tds_payments` (`challan_no` + `challan_date`) · `acc_bill_references` (ledger + `reference_no` + year) · `acc_tds_certificates` (party + certificate + section) |

The third group is the one most likely to surprise a user in practice: deleting a mistaken bank reconciliation and redoing it for the same statement date is now a **restore**, not a fresh insert.

### 4. The cache triple

Five tables are **caches over `acc_voucher_items`**. Each carries the same three columns:

| Column | Meaning |
|---|---|
| `last_voucher_item_id` | The newest line folded into this figure. **Makes drift diagnosable** — you can see exactly where the cache stopped |
| `last_rebuilt_at` | When it was last recomputed from scratch |
| `is_stale` | Set by a failed nightly assertion; cleared by a rebuild |

Cache tables: `acc_ledger_period_balances` · `acc_fund_balances` · `acc_bill_reference_balances`.

> **If a cache ever disagrees with `acc_voucher_items`, the voucher items win.** Run `acc:rebuild-balances`.

### 5. Type discipline — one width per concept

| Type | Used for | Tables |
|---|---|---|
| `SMALLINT UNSIGNED` | Config and small reference sets | voucher types, financial years, periods, tax types, currencies, campuses, categories |
| `INT UNSIGNED` | Masters | account groups, ledgers, cost centres, funds, budgets |
| `BIGINT UNSIGNED` | Transactions and logs | vouchers, items, allocations, bill references, audit |
| `INT UNSIGNED` | External tenant tables | `sys_users`, `sys_media`, `std_students`, `sch_employees`, `vnd_vendors` |

An earlier version joined columns of **different** integer widths across 12 foreign keys. InnoDB rejects every one of them, so the script would not run.

### 6. External tables

All in the **same tenant database**, all `INT UNSIGNED` primary keys:
`sys_users` · `sys_media` · `sys_dropdown_table` · `std_students` · `sch_employees` · `vnd_vendors`

`glb_app_modules` lives in the **GLOBAL** database and is keyed `VARCHAR(10)`. A cross-database foreign key would break tenant portability, so `module_key` is stored as a plain, indexed `VARCHAR(10)` and its integrity is enforced by the application.

---

## Accounting terms, for the non-accountant

| Term | Plain meaning | Table |
|---|---|---|
| **Voucher** | One financial transaction: a payment, a receipt, a journal entry | `acc_vouchers` |
| **Voucher item / line** | One Dr or Cr line inside a voucher. **A voucher always has at least two** | `acc_voucher_items` |
| **Debit (Dr)** | Money in / value received. Increases assets and expenses | `entry_type = 'Dr'` |
| **Credit (Cr)** | Money out / value given. Increases liabilities, income and equity | `entry_type = 'Cr'` |
| **Ledger** | An account you post to: "Cash", "Bank HDFC", "Tuition Fee Income", "Ravi Kumar" | `acc_ledgers` |
| **Account group** | The classification tree above ledgers: Assets → Current Assets → Bank Accounts | `acc_account_groups` |
| **Cost centre** | *Where* the money went, for internal analysis: Primary Section, Transport, Science Lab | `acc_cost_centers` |
| **Fund** | *Whose* money it is, for restricted grants and donations: "CSR Library Fund" | `acc_funds` |
| **Bill reference** | One invoice or demand, tracked to settlement. Answers "which bills are unpaid?" | `acc_bill_references` |
| **Posting** | Making a voucher final and countable | `status = 'Posted'` |
| **Reversal** | Cancelling a posted voucher by creating an equal-and-opposite one | `acc_voucher_references` |
| **Trial balance** | The proof that all debits equal all credits | `vw_trial_balance` |
| **Period close** | Locking a month so nobody can post into it | `acc_accounting_periods` |

---

## A worked example — one fee receipt, end to end

A parent pays ₹25,000 school fees by cheque. This one event touches 14 tables.

| # | What happens | Table | Key data |
|---:|---|---|---|
| 1 | The Fees module raises a demand | `acc_module_events` | event `FEE_DEMAND_RAISED` |
| 2 | A rule says what voucher to build | `acc_event_voucher_configs` + `acc_event_voucher_line_templates` | Dr student, Cr Tuition Income |
| 3 | The event is logged for idempotency | `acc_event_processing_log` | `source_event_uid` |
| 4 | A demand voucher is created | `acc_vouchers` | `SAL-0117`, Draft |
| 5 | Two lines are written | `acc_voucher_items` | Dr Ravi Kumar 25,000 / Cr Tuition Fee 25,000 |
| 6 | It is posted; a number is issued | `acc_voucher_number_sequences` | next_number 118 |
| 7 | A bill is opened for tracking | `acc_bill_references` | `FEE/T2/00412`, Open, due 15 Sep |
| 8 | Balances update | `acc_ledger_period_balances` | Ravi Dr 25,000 |
| 9 | The parent pays by cheque | `acc_vouchers` | `RCP-0431` |
| 10 | Two lines again | `acc_voucher_items` | Dr Bank 25,000 / Cr Ravi Kumar 25,000 |
| 11 | Cheque details are captured | `acc_voucher_bank_details` | cheque 004512, HDFC |
| 12 | The payment is matched to the bill | `acc_bill_allocations` | 25,000 against `FEE/T2/00412` |
| 13 | The bill closes | `acc_bill_reference_balances` | outstanding 0, status Settled |
| 14 | The cheque clears at the bank | `acc_cheque_transactions` | Issued → Presented → Cleared |
| 15 | It appears on the statement | `acc_bank_statement_entries` | credit 25,000 |
| 16 | The line is reconciled | `acc_bank_reconciliation_matches` | Confirmed |
| 17 | Everything is audited | `acc_audit_logs` | 9 rows for this story |

**The two vouchers, in the form the books actually hold:**

```
SAL-0117   05-Sep-2026   Fee demand — Ravi Kumar, Term 2
   Dr   Ravi Kumar (student)          25,000.00
   Cr   Tuition Fee Income                        25,000.00
                                      ─────────  ─────────
                                      25,000.00  25,000.00     ✓ R-01

RCP-0431   09-Sep-2026   Fee received — cheque 004512
   Dr   Bank — HDFC Current           25,000.00
   Cr   Ravi Kumar (student)                      25,000.00
                                      ─────────  ─────────
                                      25,000.00  25,000.00     ✓ R-01
```

After both are posted, Ravi Kumar's ledger balance is zero and bill `FEE/T2/00412` is settled — **and both of those facts are derived from the four lines above, not stored independently.**

---

# SECTION 1 — Organisation, Currency and Time

## 1.1 `acc_campuses`

### What it is for
A school may run several campuses under one legal entity. Multi-campus *reporting* is a later phase, but the dimension is carried from day one: **adding a dimension to posted history later is far more expensive than carrying a mostly-constant column now.**

### Example row
`MAIN` · Prime Public School — Main Campus · is_primary 1

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `1` |
| `code` | VARCHAR(20) | — | **UK.** Short identifier | `MAIN` |
| `name` | VARCHAR(150) | — | Campus name | `Prime Public School — Main` |
| `address` | VARCHAR(500) | ✔ | Postal address | `12 MG Road, Indore` |
| `is_primary` | TINYINT(1) | — | **Exactly one campus is primary.** Used as the default on entry | `1` |
| `is_active` | TINYINT(1) | — | In use | `1` |

## 1.2 `acc_currencies`

### What it is for
The currencies the school transacts in. **Exactly one is the base currency** — INR for Prime-AI — and every balance in the books is stored in it.

### Example rows

| code | name | symbol | decimal_places | is_base |
|---|---|---|:---:|:---:|
| `INR` | Indian Rupee | ₹ | 2 | **1** |
| `USD` | US Dollar | $ | 2 | 0 |
| `GBP` | Pound Sterling | £ | 2 | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `1` |
| `code` | CHAR(3) | — | **UK.** ISO 4217 | `INR` |
| `name` | VARCHAR(60) | — | Full name | `Indian Rupee` |
| `symbol` | VARCHAR(10) | — | Display symbol | `₹` |
| `decimal_places` | TINYINT UNSIGNED | — | How many decimals this currency uses. Not all use 2 | `2` |
| `is_base` | TINYINT(1) | — | **Exactly one row has this set.** All books are kept in it | `1` |
| `is_active` | TINYINT(1) | — | Available for selection | `1` |

## 1.3 `acc_exchange_rates`

### What it is for
The rate used to convert a foreign-currency transaction into the base currency. **The rate is captured on the voucher when it posts and never read back from here** — a historical voucher must always convert the way it did on the day.

### Example rows

| currency_id | rate_date | rate_to_base | rate_type | source |
|---:|---|---:|---|---|
| 2 (USD) | 2026-09-09 | 88.42000000 | `Standard` | RBI reference |
| 2 (USD) | 2026-09-09 | 88.90000000 | `Selling` | HDFC card rate |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `310` |
| `currency_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_currencies` | `2` |
| `rate_date` | DATE | — | **UK.** The date this rate applies to | `2026-09-09` |
| `rate_to_base` | DECIMAL(18,8) | — | **1 unit of this currency = this many base units.** 8 decimals, because rounding here compounds | `88.42000000` |
| `rate_type` | ENUM | — | **UK.** `Standard`, `Selling`, `Buying`, `Custom` — banks quote different rates for buying and selling | `Standard` |
| `source` | VARCHAR(100) | ✔ | Where the rate came from. An auditor will ask | `RBI reference` |

### Keys & rules
`UNIQUE (currency_id, rate_date, rate_type)` · `CHECK (rate_to_base > 0)`.

## 1.4 `acc_financial_years`

### What it is for
The accounting year. In India this runs **1 April to 31 March**. Every voucher belongs to exactly one.

### Example row

```
name            : "2026-27"
start_date 2026-04-01 · end_date 2027-03-31
is_current      : 1
status          : Open
carry_forward_at: NULL      ← opening balances for 2027-28 not yet generated
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `3` |
| `name` | VARCHAR(20) | — | **UK.** The year label | `2026-27` |
| `start_date` | DATE | — | **UK.** First day | `2026-04-01` |
| `end_date` | DATE | — | Last day | `2027-03-31` |
| `is_current` | TINYINT(1) | — | The year the UI defaults to | `1` |
| `status` | ENUM | — | `Open` · `Soft_Closed` (reversible, senior users may still post) · `Hard_Closed` (nothing may post, ever) | `Open` |
| `closed_at` / `closed_by` | DATETIME / INT UNSIGNED | ✔ | Who closed it and when | `NULL` |
| `carry_forward_at` | DATETIME | ✔ | **When opening balances were generated for the NEXT year.** NULL means the roll-forward has not run | `NULL` |
| `carry_forward_by` | INT UNSIGNED | ✔ | Who ran the roll-forward | `NULL` |
| `is_active` | TINYINT(1) | — | Selectable | `1` |

### Keys & rules
`UNIQUE (name)` · `UNIQUE (start_date)` · `CHECK (end_date > start_date)`.

## 1.5 `acc_accounting_periods`

### What it is for
The **months** inside a financial year. This is what makes a monthly close possible: you lock April so nobody can quietly post a April entry in November and change a report someone already signed.

### Example rows

| financial_year_id | period_no | name | start_date | end_date | status |
|---:|:---:|---|---|---|---|
| 3 | 1 | Apr 2026 | 2026-04-01 | 2026-04-30 | `Hard_Closed` |
| 3 | 5 | Aug 2026 | 2026-08-01 | 2026-08-31 | `Soft_Closed` |
| 3 | 6 | Sep 2026 | 2026-09-01 | 2026-09-30 | `Open` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `30` |
| `financial_year_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_financial_years` | `3` |
| `period_no` | TINYINT UNSIGNED | — | **UK.** 1–12. **1 = April** in the Indian year | `6` |
| `name` | VARCHAR(30) | — | Display label | `Sep 2026` |
| `start_date` | DATE | — | **UK.** First day of the month | `2026-09-01` |
| `end_date` | DATE | — | Last day | `2026-09-30` |
| `status` | ENUM | — | `Open`, `Soft_Closed`, `Hard_Closed` | `Open` |
| `closed_at` / `closed_by` | DATETIME / INT UNSIGNED | ✔ | The close record | `NULL` |
| `reopened_at` / `reopened_by` | DATETIME / INT UNSIGNED | ✔ | If it was reopened | `NULL` |
| `reopen_reason` | VARCHAR(500) | ✔ | **Why it was reopened.** An auditor will ask about every one of these | `NULL` |
| `reopen_count` | SMALLINT UNSIGNED | — | **How many times.** A period reopened four times is a control problem, and this makes it visible | `0` |

### Keys & rules
`UNIQUE (financial_year_id, period_no)` · `UNIQUE (start_date)` · `CHECK (period_no BETWEEN 1 AND 12)` · `CHECK (end_date >= start_date)`.

---

# SECTION 2 — Chart of Accounts

## 2.1 `acc_account_groups`

### What it is for
The **classification tree** above ledgers. Every ledger hangs off a group, and the group's `nature` decides which financial statement the ledger appears in.

### The tree

```
Assets (nature = Asset)
  └── Current Assets
        ├── Bank Accounts        ← ledgers: "Bank — HDFC Current"
        ├── Cash-in-Hand         ← ledgers: "Cash"
        └── Sundry Debtors       ← is_subledger = 1; ledgers: every student and customer
Liabilities (nature = Liability)
  └── Current Liabilities
        └── Sundry Creditors     ← is_subledger = 1; ledgers: every vendor
Income (nature = Income)
  └── Direct Income              ← ledgers: "Tuition Fee Income"
Expenses (nature = Expense)
  └── Indirect Expenses          ← ledgers: "Salaries", "Electricity"
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `18` |
| `code` | VARCHAR(30) | — | **UK** | `SUNDRY_DEBTORS` |
| `name` | VARCHAR(120) | — | **UK** | `Sundry Debtors` |
| `alias` | VARCHAR(120) | ✔ | Alternate name for search | `Receivables` |
| `parent_id` | INT UNSIGNED | ✔ | Self-FK. NULL = a top-level group | `4` |
| `nature` | ENUM | — | **`Asset`, `Liability`, `Equity`, `Income`, `Expense`. This decides which statement the ledger lands in** | `Asset` |
| `affects_gross_profit` | TINYINT(1) | — | Include in the gross-profit calculation (trading accounts) | `0` |
| `path` | VARCHAR(500) | ✔ | Materialised ancestor path, so a subtree query needs no recursion | `/1/4/18/` |
| `depth` | TINYINT UNSIGNED | — | Levels below the root | `2` |
| `is_system` | TINYINT(1) | — | **May not be deleted, and its `nature` may not be changed.** Changing "Sundry Debtors" from Asset to Expense would silently rewrite every report ever produced | `1` |
| `is_subledger` | TINYINT(1) | — | **A party control account.** Its ledgers are individual people or vendors rather than accounts | `1` |
| `ordinal` | SMALLINT UNSIGNED | — | Display order among siblings | `3` |
| `is_active` | TINYINT(1) | — | Selectable | `1` |

### Keys & rules
`CHECK (parent_id <> id)` · parent FK is `ON DELETE RESTRICT` — you cannot delete a group that has children.

### Additional Info:
### What is `path` & `depth`

In acc_account_groups, path and depth implement a design pattern called the Materialized Path Pattern. They are used to make hierarchy traversal (parent-child-grandchild group relationships) extremely fast and simple in SQL reports and UI tree views.

1. path (VARCHAR(500)) — Materialized Ancestor Path
What it stores: A string representing the complete chain of ancestor Group IDs from the root down to the current group.

Example: /1/4/18/
1 = Assets (Root)
4 = Current Assets (Child of 1)
18 = Bank Accounts (Child of 4)
Why it is used:

Eliminates Expensive Recursive Queries (WITH RECURSIVE CTEs): Without path, finding all sub-groups under "Current Assets" requires multi-pass recursive queries. With path, retrieving all descendant groups and ledgers under "Current Assets" (ID: 4) becomes a single, fast indexed query:
sql
SELECT * FROM acc_account_groups WHERE path LIKE '/1/4/%';
Financial Statement Roll-ups (Balance Sheet / P&L): When compiling financial reports (e.g., calculating total Current Assets), the system uses path LIKE '/1/4/%' to aggregate all child groups and ledgers instantly.

2. depth (TINYINT UNSIGNED) — Hierarchy Level
What it stores: The depth/level of the group in the tree structure.

0 = Top-level Root Group (e.g., Assets, Liabilities)
1 = Level 1 Sub-Group (e.g., Current Assets)
2 = Level 2 Sub-Group (e.g., Bank Accounts)
Why it is used:

UI Indentation & Tree Rendering: Controls UI spacing and indentation when rendering the Chart of Accounts tree in the browser or mobile app (e.g., margin-left = depth * 20px).
Level-Based Report Summaries: Allows filtering financial reports to a specific summary level (e.g., WHERE depth <= 2 to generate a high-level summary Balance Sheet).
Quick Comparison
Column	Example Value	Main Purpose	Business Benefit
path	/1/4/18/	Fast descendant/subtree queries	Replaces slow recursive joins with a single LIKE '/1/4/%' query
depth	2	Hierarchy level indicator	Powers UI tree indentation and level-based report summaries

## 2.2 `acc_ledgers` — the accounts you actually post to

### What it is for
Every account a transaction can touch: bank accounts, cash, income heads, expense heads, and **one ledger per party** — every student, vendor and employee you owe or who owes you.

This is the widest table in the schema because a ledger carries whatever its `ledger_type` needs: a bank ledger needs IFSC and account number, a party ledger needs PAN and credit limit, an income head needs neither.

### Example rows

| name | account_group_id | ledger_type | party_type | is_bill_wise | student_id |
|---|---|---|---|:---:|---:|
| Bank — HDFC Current | Bank Accounts | `Bank` | — | 0 | — |
| Cash | Cash-in-Hand | `Cash` | — | 0 | — |
| Tuition Fee Income | Direct Income | `General` | — | 0 | — |
| Ravi Kumar (Class 8-A) | Sundry Debtors | `Party` | `Student` | **1** | 4471 |
| Sharma Stationers | Sundry Creditors | `Party` | `Vendor` | **1** | — |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `142` |
| `code` | VARCHAR(30) | ✔ | **UK.** Optional short code | `HDFC_CUR` |
| `name` | VARCHAR(150) | — | **UK.** What appears in every dropdown | `Bank — HDFC Current` |
| `alias` | VARCHAR(150) | ✔ | Alternate search name | `HDFC 5521` |
| `account_group_id` | INT UNSIGNED | — | FK → `acc_account_groups`. **Decides which statement this ledger appears in** | `12` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_campuses`. **NULL = shared across campuses** | `NULL` |
| `currency_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_currencies`. **NULL = base currency** | `NULL` |
| `ledger_type` | ENUM | — | `General`, `Cash`, `Bank`, `Party`, `Tax`, `Fund`, `Suspense`, `Rounding`, `Control`. **Drives which fields the UI shows and which rules apply** | `Bank` |
| `party_type` | ENUM | ✔ | `Student`, `Parent`, `Vendor`, `Employee`, `Donor`, `Grantor`, `Other` | `Student` |
| **— behaviour flags —** | | | | |
| `is_bill_wise` | TINYINT(1) | — | **Outstanding is tracked per invoice, not just as one balance.** Set for parties you need an ageing report on | `1` |
| `is_cost_centre_applicable` | TINYINT(1) | — | Lines on this ledger must be allocated to cost centres | `0` |
| `is_fund_applicable` | TINYINT(1) | — | Lines must be allocated to a fund | `0` |
| `allow_reconciliation` | TINYINT(1) | — | This ledger can be bank-reconciled | `1` |
| `is_interest_applicable` | TINYINT(1) | — | Overdue interest may be computed on it | `0` |
| `is_tds_applicable` | TINYINT(1) | — | Tax is deducted at source on payments to this party | `1` |
| `tds_section` | VARCHAR(20) | ✔ | Which section of the Income Tax Act | `194C` |
| **— party links —** | | | | |
| `student_id` | INT UNSIGNED | ✔ | **UK.** FK → `std_students`. **One ledger per student, for the life of the table** | `4471` |
| `employee_id` | INT UNSIGNED | ✔ | **UK.** FK → `sch_employees` | `NULL` |
| `vendor_id` | INT UNSIGNED | ✔ | **UK.** FK → `vnd_vendors` | `NULL` |
| **— bank details (for `ledger_type = 'Bank'`) —** | | | | |
| `bank_name` / `bank_branch` | VARCHAR(120) | ✔ | The bank | `HDFC Bank` / `MG Road` |
| `bank_account_number` | VARCHAR(50) | ✔ | Account number | `50200012345678` |
| `bank_account_type` | ENUM | ✔ | `Savings`, `Current`, `OD`, `CC`, `FD`, `Other` | `Current` |
| `ifsc_code` / `swift_code` / `micr_code` | VARCHAR(20) | ✔ | Routing codes. IFSC for India, SWIFT for international | `HDFC0000123` |
| **— credit control (for parties) —** | | | | |
| `credit_limit` | DECIMAL(15,2) | ✔ | How much they may owe | `50000.00` |
| `credit_days` | SMALLINT UNSIGNED | ✔ | Payment terms | `30` |
| `credit_limit_action` | ENUM | — | `None`, `Warn`, `Approve`, `Block` — **what happens when the limit is exceeded** | `Warn` |
| **— statutory —** | | | | |
| `gst_registration_type` | ENUM | ✔ | `Regular`, `Composition`, `Unregistered`, `SEZ`, `Consumer`, `Overseas` | `Regular` |
| `gstin` / `pan` / `tan` | VARCHAR(20)/(15)/(15) | ✔ | Tax registration numbers | `23AAACH1234K1Z5` |
| `state_code` | VARCHAR(5) | ✔ | **Drives place of supply** — which decides CGST+SGST vs IGST | `23` |
| `address` / `contact_person` / `phone` / `email` | VARCHAR | ✔ | Contact details | `accounts@sharma.in` |
| `is_system` | TINYINT(1) | — | **Cash, Suspense, Rounding and control accounts.** Cannot be deleted | `0` |
| `is_active` | TINYINT(1) | — | Selectable | `1` |
| `notes` | VARCHAR(1000) | ✔ | Free notes | `NULL` |

### Keys & rules

- Five unique keys, each absolute: `name`, `code`, `student_id`, `employee_id`, `vendor_id`. **One student cannot have two ledgers** — and since v4.6 that holds across deleted rows too, so a re-admitted student **reuses the restored ledger** rather than getting a new one. That is also the correct accounting outcome: the history belongs to the party, not to the enrolment.
- Every FK is `ON DELETE RESTRICT` — you cannot delete a student who has an accounting ledger.
- **There is no `closing_balance` column, deliberately (R-05).** The balance comes from `acc_ledger_period_balances`, or from `vw_ledger_balances` which computes it live.

---

# SECTION 3 — Dimensions

Two independent ways of tagging a transaction beyond its ledger:

| Dimension | Answers | Example |
|---|---|---|
| **Cost centre** | *Where* did the money go, internally? | Primary Section · Transport · Science Lab |
| **Fund** | *Whose* money is it? | CSR Library Fund · Corpus Fund · Building Fund |

A single expense can carry both: ₹40,000 of books, allocated to the *Primary Section* cost centre and paid from the *CSR Library Fund*.

## 3.1 `acc_cost_categories`

### What it is for
Cost centres are grouped into categories so a line can be allocated along **several independent axes at once** — by section *and* by activity, for example.

### Example rows

| code | name | is_mandatory | allow_multiple |
|---|---|:---:|:---:|
| `SECTION` | Academic Section | 1 | 1 |
| `ACTIVITY` | Activity Type | 0 | 1 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `1` |
| `code` | VARCHAR(20) | — | **UK** | `SECTION` |
| `name` | VARCHAR(100) | — | **UK** | `Academic Section` |
| `description` | VARCHAR(500) | ✔ | What this axis means | `Primary / Middle / Senior` |
| `is_mandatory` | TINYINT(1) | — | **Allocation in this category is required** on applicable lines | `1` |
| `allow_multiple` | TINYINT(1) | — | May one line split across several centres in this category | `1` |
| `ordinal` | SMALLINT UNSIGNED | — | Display order | `1` |
| `is_active` | TINYINT(1) | — | In use | `1` |

## 3.2 `acc_cost_centers`

### What it is for
The internal units you want to report cost against. Hierarchical, so "Primary Section" can roll up under "Academics".

### Example rows

| cost_category_id | code | name | parent_id |
|---:|---|---|---:|
| 1 | `PRIM` | Primary Section | NULL |
| 1 | `PRIM-1` | Grade 1 | (Primary) |
| 2 | `SPORTS` | Sports | NULL |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `7` |
| `cost_category_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_cost_categories`. Which axis this belongs to | `1` |
| `code` | VARCHAR(20) | — | **UK** | `PRIM` |
| `name` | VARCHAR(120) | — | **UK** (with `cost_category_id`) | `Primary Section` |
| `parent_id` | INT UNSIGNED | ✔ | Self-FK, `ON DELETE SET NULL`. Hierarchy | `NULL` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_campuses` | `1` |
| `path` / `depth` | VARCHAR(500) / TINYINT | ✔ / — | Materialised tree position | `/7/` / `0` |
| `incharge_user_id` | INT UNSIGNED | ✔ | FK → `sys_users`. **Who is answerable for this centre's spend** | `22` |
| `ordinal` | SMALLINT UNSIGNED | — | Display order | `1` |
| `is_active` | TINYINT(1) | — | Selectable | `1` |

### Keys & rules
`CHECK (parent_id <> id)`.

## 3.3 `acc_funds`

### What it is for

**Restricted money.** When a donor gives ₹5,00,000 for a library, that money is not the school's to spend on salaries. This table tracks the restriction, the sanctioned amount, the utilisation window, and what happens if someone tries to overspend it.

### Example row

```
code                : CSR-LIB-2026
name                : "TechCorp CSR — Library Development"
fund_type           : Restricted
restriction_purpose : "Purchase of books, shelving and reading-room furniture only.
                       Not available for salaries or building work."
grantor_ledger_id   : TechCorp Foundation (party ledger)
fund_ledger_id      : "Restricted Funds — Library" (balance sheet ledger)
sanctioned_amount   : 500,000.00
utilisation_from 2026-04-01 · utilisation_to 2027-03-31
overspend_action    : Block          ← the system will REFUSE the entry
status              : Active
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `4` |
| `code` | VARCHAR(30) | — | **UK** | `CSR-LIB-2026` |
| `name` | VARCHAR(150) | — | **UK** | `TechCorp CSR — Library` |
| `fund_type` | ENUM | — | `Unrestricted` · `Restricted` (a stated purpose) · `Corpus` (capital, cannot be spent) · `Designated` (management-earmarked, reversible) | `Restricted` |
| `restriction_purpose` | VARCHAR(1000) | ✔ | **What the money may be spent on.** Quoted verbatim in the utilisation certificate | `Books and shelving only` |
| `grantor_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. The donor or grantor | `88` |
| `fund_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. The balance-sheet ledger carrying the fund | `91` |
| `sanctioned_amount` | DECIMAL(15,2) | ✔ | How much was granted | `500000.00` |
| `utilisation_from` / `utilisation_to` | DATE | ✔ | **The window in which it may be spent.** Money unspent by the end date is often refundable | `2026-04-01` |
| `overspend_action` | ENUM | — | **`Block` (refuse the entry), `Approve` (needs authorisation), `Warn` (allow with a message)** | `Block` |
| `status` | ENUM | — | `Active`, `Fully_Utilised`, `Suspended`, `Closed` | `Active` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_campuses` | `NULL` |
| `is_active` | TINYINT(1) | — | Selectable | `1` |
| `notes` | VARCHAR(1000) | ✔ | Free notes | `NULL` |

### Keys & rules
`CHECK (utilisation_to >= utilisation_from)` where both are set. Fund balances live in `acc_fund_balances` (a cache), never on this row.

---

# SECTION 4 — Voucher Configuration

## 4.1 `acc_voucher_category`

### What it is for
Which **business event** a voucher came from. This is what lets Accounting accept postings from the Fees, Library, Transport, Hostel and Payroll modules while still knowing where each entry originated.

> Note the singular table name — `acc_voucher_category`, not `_categories`. It is inconsistent with the rest of the schema but it is what the deployed table is called.

### Example rows

| module_key | code | name | module_table_name |
|---|---|---|---|
| `ACC` | `ACCOUNTING` | Manual accounting entry | — |
| `FEE` | `FEE_COLLECTION` | Fee collection | `fee_transactions` |
| `LIB` | `LIBRARY_FINE` | Library fine | `lib_fines` |
| `PAY` | `PAYROLL_POSTING` | Monthly payroll | `pay_salary_runs` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `3` |
| `module_key` | VARCHAR(10) | — | `glb_app_modules.key`. **A plain indexed column, not a FK** — that table lives in the GLOBAL database and a cross-database FK would break tenant portability | `LIB` |
| `code` | VARCHAR(40) | — | **UK** | `LIBRARY_FINE` |
| `name` | VARCHAR(120) | — | Display name | `Library fine` |
| `event_detail` | VARCHAR(255) | ✔ | What business event this represents | `Fine on late book return` |
| `module_table_name` | VARCHAR(64) | ✔ | The source table in the originating module | `lib_fines` |
| `is_system` | TINYINT(1) | — | Shipped with the application | `1` |
| `is_active` | TINYINT(1) | — | Selectable | `1` |

## 4.2 `acc_voucher_types`

### What it is for
The kinds of voucher a user can create, and **all the rules that apply when they do**: how it is numbered, what it requires, which ledgers it may touch, and whether it affects the books at all.

### Example rows

| code | name | school_label | base_type | prefix | restart_policy | affects_books |
|---|---|---|---|---|---|:---:|
| `PAYMENT` | Payment | Payment | `Payment` | `PAY` | `Financial_Year` | 1 |
| `RECEIPT` | Receipt | Fee Collection | `Receipt` | `RCP` | `Financial_Year` | 1 |
| `JOURNAL` | Journal | Adjustment | `Journal` | `JV` | `Financial_Year` | 1 |
| `SALES` | Sales | Fee Demand | `Sales` | `SAL` | `Financial_Year` | 1 |
| `MEMO` | Memorandum | Estimate | `Memorandum` | `MEM` | `Never` | **0** |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `2` |
| `code` | VARCHAR(20) | — | **UK** | `RECEIPT` |
| `name` | VARCHAR(80) | — | **UK** | `Receipt` |
| `school_label` | VARCHAR(80) | ✔ | **What the UI calls it.** An accountant sees "Receipt"; a fee clerk sees "Fee Collection" | `Fee Collection` |
| `voucher_category_id` | SMALLINT UNSIGNED | — | FK → `acc_voucher_category` | `2` |
| `base_type` | ENUM | — | `Payment`, `Receipt`, `Contra`, `Journal`, `Sales`, `Purchase`, `Credit_Note`, `Debit_Note`, `Memorandum`. **The accounting behaviour underneath the school label** | `Receipt` |
| **— numbering —** | | | | |
| `prefix` / `suffix` | VARCHAR(10) | ✔ | **UK** on prefix | `RCP` / NULL |
| `number_width` | TINYINT UNSIGNED | — | Zero-padding width → `RCP-0042` | `4` |
| `numbering_method` | ENUM | — | `Auto`, `Manual`, `Auto_Override` | `Auto` |
| `restart_policy` | ENUM | — | `Financial_Year` (restart at 1 each April), `Never`, `Monthly` | `Financial_Year` |
| **— what this type requires —** | | | | |
| `requires_party` | TINYINT(1) | — | A counterparty ledger is mandatory | `1` |
| `creates_bill_reference` | TINYINT(1) | — | Posting opens a new bill for tracking | `1` |
| `requires_narration` | TINYINT(1) | — | A description is mandatory | `1` |
| `requires_evidence` | TINYINT(1) | — | An attachment is mandatory | `0` |
| `requires_bank_details` | TINYINT(1) | — | Cheque / UTR details are mandatory | `1` |
| `allow_zero_value` | TINYINT(1) | — | A zero-amount voucher is permitted | `0` |
| `allow_post_dated` | TINYINT(1) | — | Future-dated instruments are permitted | `1` |
| `allowed_ledger_types` | VARCHAR(200) | ✔ | Only these ledger types may appear | `Bank,Cash,Party` |
| `forbidden_ledger_types` | VARCHAR(200) | ✔ | These may never appear | `Suspense` |
| **— behaviour —** | | | | |
| `affects_books` | TINYINT(1) | — | **`0` for Memorandum: it NEVER posts and never appears in a financial report.** This is how estimates and quotations are kept without polluting the accounts | `1` |
| `default_entry_mode` | ENUM | — | `Single` (one side pre-filled) or `Double` (full grid) | `Single` |
| `default_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. Pre-filled on one side | `142` |
| `is_system` | TINYINT(1) | — | Shipped; cannot be deleted | `1` |
| `is_active` / `ordinal` | TINYINT(1) / SMALLINT | — | Selectable, display order | `1` / `2` |

### Additional Info:
### What is Memorandum Voucher
A Memorandum Voucher (or Memo Voucher) is a non-accounting record used to track tentative, unverified, or uncertain transactions without affecting a company's final books of accounts.

**Key Uses of Memorandum Vouchers:**
* **Suspense or Cash Advances:** Used when giving an employee a cash advance for expenses where the exact cost is unknown. You record a memo voucher initially and convert it into a regular payment voucher once the final expense details and receipts are submitted. 
* **Unverified Transactions:** Helpful when you do not fully understand or have complete details of a transaction during entry. You can log it as a memo and amend or convert it later.
* **Goods Sent on Approval:** Used to track inventory or items sent to customers "on approval". If the sale goes through, the memo is converted into a regular sales voucher; if returned, it is deleted or cancelled. 

Provisional and Expected Entries: Useful for internal planning and recording anticipated expenses or proposed budget allocations (like an expected salary hike) before formal approval.

**Main Benefits:**
* **Flexibility:** Allows recording uncertain or provisional transactions without affecting the books.
* **Audit Trail:** Even though they don't post, memo vouchers can be tracked and converted into regular vouchers later.
* **Non-Intrusive:** Enables forward planning and temporary entries without distorting financial reports.

**How Memorandum Vouchers Work**
A memo voucher can be created and saved like a regular voucher, but when a user attempts to post it (i.e., move it from "Draft" to "Approved" or "Posted" status), the application performs special checks:
1. **Check if the voucher is a Memo:** The application verifies the `voucher_type_id` to determine if it is a memo voucher.
2. **Check `allows_affecting_books`:** It reads the `allows_affecting_books` column in the `acc_voucher_types` table. If this flag is 0 (false), the voucher is treated as a non-accounting record.
3. **Bypass Posting Logic:** The system skips the standard accounting posting logic, which would normally:
    * Create debit and credit entries in `acc_entries`
    * Update ledger balances in `acc_ledgers`
    * Update financial year summaries in `acc_fy_snapshots`
    * Create or update bill references in `acc_bills`
    * Update sub-ledger postings in `acc_sub_ledger_postings` (if applicable)
4. **Update Status:** The voucher's status is updated to a posted state (e.g., from `DRAFT` to `POSTED`), but no accounting entries are created.

**Typical Workflow**
1. **Creation:** A user creates a memo voucher for a tentative transaction.
   * *Example:* A memo voucher for an employee's travel advance.
2. **Editing/Updating:** The voucher may be edited or updated before it is finalized.
   * *Example:* The advance amount is adjusted after checking current cash balance.
3. **Conversion to Regular Voucher:** Once the transaction is confirmed and all details are known, the memo voucher is converted into a regular voucher.
   * *Example:* Upon return, the employee submits receipts. The memo is converted into a payment voucher with detailed expense entries.
4. **Deletion:** If the transaction is cancelled, the memo voucher may be deleted.
   * *Example:* The travel advance is withdrawn, so the memo voucher is deleted.




## 4.3 `acc_voucher_number_sequences`

### What it is for

**The one place a voucher number is issued from.** An earlier version kept a `last_number` column on the voucher type, which loses updates under concurrency: two clerks posting at the same instant both read 41, both write 42, and two vouchers carry number `RCP-0042`.

This table is locked for the duration of the allocation, so that cannot happen.

### Example rows

| voucher_type_id | financial_year_id | period_id | period_marker (GEN) | next_number |
|---:|---:|---:|:---:|---:|
| 2 (Receipt) | 3 (2026-27) | NULL | **0** | 432 |
| 7 (Petty Cash) | 3 (2026-27) | 30 (Sep) | **30** | 15 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `9` |
| `voucher_type_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_voucher_types` | `2` |
| `financial_year_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_financial_years` | `3` |
| `period_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_accounting_periods`. **Set only when `restart_policy = 'Monthly'`** | `NULL` |
| `period_marker` | SMALLINT UNSIGNED | — | **GEN.** `IFNULL(period_id, 0)` | `0` |
| `next_number` | INT UNSIGNED | — | The next number to issue | `432` |
| `last_issued_at` | DATETIME | ✔ | When the last number went out | `2026-09-09 11:02` |

### Keys & rules

`UNIQUE (voucher_type_id, financial_year_id, period_marker)` · `CHECK (next_number >= 1)`.

> **Why `period_marker` and not `period_id` in the key.** With `period_id` NULL for every type that does not restart monthly, MySQL treats each NULL as distinct — so the key permitted **two sequence rows for the same type and year**, and therefore two vouchers taking the same number. That is the exact defect the sequence table was introduced to prevent.

## 4.4 `acc_approval_policies`

### What it is for
Which vouchers need approval, by whom, and at how many levels. A ₹500 petty-cash payment and a ₹5,00,000 vendor payment should not require the same authorisation.

### Example rows

| name | voucher_type_id | min_amount | max_amount | approval_level | approver_role_slug | forbid_self_approval |
|---|---|---:|---:|:---:|---|:---:|
| Payments over ₹10k | Payment | 10000.00 | 100000.00 | 1 | `accounts-manager` | 1 |
| Payments over ₹1L | Payment | 100000.00 | NULL | 2 | `principal` | 1 |
| All journals | Journal | 0.00 | NULL | 1 | `accounts-manager` | 1 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `4` |
| `name` | VARCHAR(120) | — | Policy name | `Payments over ₹1L` |
| `voucher_type_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_voucher_types`. **NULL = applies to every type** | `1` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_campuses` | `NULL` |
| `min_amount` | DECIMAL(15,2) | — | Applies at or above this | `100000.00` |
| `max_amount` | DECIMAL(15,2) | ✔ | **NULL = no ceiling** | `NULL` |
| `ledger_group_id` | INT UNSIGNED | ✔ | FK → `acc_account_groups`. Applies only to vouchers touching this group | `NULL` |
| `approval_level` | TINYINT UNSIGNED | — | **Multi-level: level 1 approves, then level 2, then 3** | `2` |
| `approver_role_slug` | VARCHAR(60) | — | The role permitted to approve at this level | `principal` |
| `forbid_self_approval` | TINYINT(1) | — | **Segregation of duties: the person who entered it may not approve it** | `1` |
| `allow_override` | TINYINT(1) | — | A senior user may bypass this policy, and it is recorded | `0` |
| `escalate_after_hours` | SMALLINT UNSIGNED | ✔ | Escalate if nobody acts within this many hours | `48` |
| `is_active` | TINYINT(1) | — | In force | `1` |

### Keys & rules
`CHECK (max_amount >= min_amount)` where both are set.

---

# SECTION 5 — Tax Configuration

## 5.1 `acc_tax_types`

### What it is for
The kinds of tax the school deals with: GST components, TDS, TCS.

### Example rows

| code | name | tax_family | is_input |
|---|---|---|:---:|
| `CGST` | Central GST | `GST` | 0 |
| `SGST` | State GST | `GST` | 0 |
| `IGST` | Integrated GST | `GST` | 0 |
| `TDS` | Tax Deducted at Source | `TDS` | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `1` |
| `code` | VARCHAR(15) | — | **UK** | `CGST` |
| `name` | VARCHAR(100) | — | Full name | `Central GST` |
| `tax_family` | ENUM | — | `GST`, `TDS`, `TCS`, `Other` | `GST` |
| `is_input` | TINYINT(1) | — | **Input credit (tax you paid and can reclaim) vs output liability (tax you collected and must remit)** | `0` |
| `ordinal` / `is_active` | SMALLINT / TINYINT(1) | — | Display order, selectable | `1` / `1` |

## 5.2 `acc_tax_rates`

### What it is for
The actual percentages, **each with a validity window**. When a rate changes, you add a new row and close the old one — you never edit the old rate, because historical vouchers must keep converting the way they did.

### Example rows

| tax_type_id | name | rate | is_interstate | effective_from | effective_to |
|---:|---|---:|:---:|---|---|
| 1 (CGST) | CGST 9% | 9.0000 | 0 | 2026-04-01 | NULL |
| 2 (SGST) | SGST 9% | 9.0000 | 0 | 2026-04-01 | NULL |
| 3 (IGST) | IGST 18% | 18.0000 | **1** | 2026-04-01 | NULL |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `1` |
| `tax_type_id` | SMALLINT UNSIGNED | — | FK → `acc_tax_types` | `1` |
| `name` | VARCHAR(100) | — | Display name | `CGST 9%` |
| `rate` | DECIMAL(9,4) | — | The percentage | `9.0000` |
| `hsn_sac_code` | VARCHAR(20) | ✔ | The goods/services classification this rate applies to | `9992` |
| `is_interstate` | TINYINT(1) | — | **IGST applies between states; CGST+SGST within one state** | `0` |
| `tax_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **Where this tax posts** | `210` |
| `effective_from` | DATE | — | First day this rate applies | `2026-04-01` |
| `effective_to` | DATE | ✔ | **NULL = still in force** | `NULL` |
| `is_active` | TINYINT(1) | — | Selectable | `1` |

### Keys & rules
`CHECK (rate >= 0)` · `CHECK (effective_to >= effective_from)`.

## 5.3 `acc_tax_rules`

### What it is for
**When** a tax applies and at what rate — chiefly for TDS, where the rate depends on the section, the party type, the amount, and whether the party gave you their PAN.

### Example row

```
code                  : TDS_194C_CONTRACTOR
name                  : "TDS 194C — payments to contractors"
tax_type_id           : TDS
section_code          : 194C
applies_to_party_type : Vendor
single_txn_threshold  : 30,000.00        ← below this on one bill, no deduction
annual_threshold      : 100,000.00       ← below this in the year, no deduction
rate_without_pan      : 20.0000          ← the penal rate when PAN is not furnished
deduct_on             : Earlier_Of_Both  ← at credit or at payment, whichever comes first
rounding              : Nearest_Rupee
priority              : 10               ← lower wins; most specific rule first
effective_from 2026-04-01
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `2` |
| `code` | VARCHAR(30) | — | **UK** | `TDS_194C_CONTRACTOR` |
| `name` | VARCHAR(150) | — | Description | `TDS 194C — contractors` |
| `tax_type_id` | SMALLINT UNSIGNED | — | FK → `acc_tax_types` | `4` |
| `tax_rate_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_tax_rates`. The normal rate | `8` |
| `section_code` | VARCHAR(20) | ✔ | Income Tax Act section | `194C` |
| `nature_of_payment` | VARCHAR(150) | ✔ | What kind of payment this covers | `Contract work` |
| `applies_to_party_type` | ENUM | — | `Any`, `Student`, `Parent`, `Vendor`, `Employee`, `Donor`, `Grantor`, `Other` | `Vendor` |
| `applies_to_group_id` | INT UNSIGNED | ✔ | FK → `acc_account_groups`. Narrow it further | `NULL` |
| `single_txn_threshold` | DECIMAL(15,2) | ✔ | **No deduction below this on a single bill** | `30000.00` |
| `annual_threshold` | DECIMAL(15,2) | ✔ | **No deduction below this cumulatively in the year** | `100000.00` |
| `rate_without_pan` | DECIMAL(9,4) | ✔ | **The higher rate when the party has not given their PAN** | `20.0000` |
| `deduct_on` | ENUM | — | `Credit` (when the bill is booked), `Payment` (when paid), `Earlier_Of_Both` | `Earlier_Of_Both` |
| `rounding` | ENUM | — | `None`, `Nearest_Rupee`, `Up_Rupee`, `Down_Rupee` | `Nearest_Rupee` |
| `priority` | SMALLINT UNSIGNED | — | **Lower wins; the most specific rule is evaluated first** | `10` |
| `effective_from` / `effective_to` | DATE | — / ✔ | Validity window | `2026-04-01` / NULL |
| `is_active` | TINYINT(1) | — | In force | `1` |

---

# SECTION 6 — Transactions

This is the heart of the module. **Everything else in the schema is derived from these two tables.**

```
acc_vouchers                    the transaction header — one financial event
  └── acc_voucher_items         the Dr/Cr lines. ALWAYS at least two, ALWAYS balancing
        ├── acc_voucher_item_cost_centers   where the money went
        ├── acc_voucher_item_funds          whose money it was
        └── acc_voucher_item_taxes          tax computed on this line
  ├── acc_voucher_bank_details  cheque / NEFT / UPI details
  ├── acc_voucher_references    this voucher adjusts or reverses that one
  ├── acc_voucher_approvals     who approved it, at which level
  └── acc_voucher_attachments   the invoice, the sanction letter
```

## 6.1 `acc_vouchers` — the transaction header

### What it is for
One financial event. Its lifecycle, its numbering, its approval trail, its source, and its currency all live here; **the money lives in `acc_voucher_items`.**

### Example row

```
id 88214
voucher_type_id     : 2 (Receipt)
voucher_prefix      : RCP              ← FROZEN at posting
voucher_number      : 431              ← NULL until POSTED
voucher_display_no  : RCP-0431
financial_year_id 3 · period_id 30 (Sep 2026)
voucher_date        : 2026-09-09
total_amount        : 25,000.00        ← Σ Dr = Σ Cr, in base currency
status              : Posted
party_ledger_id     : 4471 (Ravi Kumar)
narration           : "Fee received — cheque 004512, HDFC"
source_module_key   : FEE
source_event_uid    : fee-txn-99231    ← idempotency key from the Fees module
entered_by 14 · posted_by 14 · posted_at 2026-09-09 11:02
```

### The lifecycle

```
   Draft ──submit──▶ Pending_Approval ──approve──▶ Posted
     │                      │                        │
     │                      └──reject──▶ Rejected    ├──cancel──▶ Cancelled
     └──────────── (edit freely) ─────────           └──reverse──▶ Reversed

   R-02: only Posted counts.  R-03: Posted is immutable — correct by reversal.
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `88214` |
| `voucher_type_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_voucher_types` | `2` |
| `voucher_prefix` | VARCHAR(10) | ✔ | **FROZEN at posting.** The type may be reconfigured later; this voucher keeps the prefix it was issued with | `RCP` |
| `voucher_number` | INT UNSIGNED | ✔ | **UK. NULL until POSTED.** A draft never consumes a number, so cancelled drafts leave no gaps in the sequence | `431` |
| `voucher_display_no` | VARCHAR(40) | ✔ | Materialised for search and printing | `RCP-0431` |
| `financial_year_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_financial_years` | `3` |
| `period_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_accounting_periods`. **Resolved from `voucher_date` at posting** | `30` |
| `voucher_date` | DATE | — | The accounting date. Drives which period it lands in | `2026-09-09` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_campuses` | `1` |
| **— amounts —** | | | | |
| `total_amount` | DECIMAL(15,2) | — | **Σ Dr = Σ Cr, in base currency** | `25000.00` |
| `currency_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_currencies`. NULL = base | `NULL` |
| `exchange_rate` | DECIMAL(18,8) | — | **FROZEN at posting.** Never read back from `acc_exchange_rates` | `1.00000000` |
| `total_amount_txn_ccy` | DECIMAL(15,2) | ✔ | The total in the original currency | `NULL` |
| **— status and flags —** | | | | |
| `status` | ENUM | — | `Draft`, `Pending_Approval`, `Rejected`, `Posted`, `Cancelled`, `Reversed`. **A single source of truth** — an earlier version had both a status and an `is_cancelled` flag, which could disagree | `Posted` |
| `is_provisional` | TINYINT(1) | — | **Provisional vouchers affect NO report** (R-02) | `0` |
| `is_post_dated` | TINYINT(1) | — | The instrument is dated in the future | `0` |
| `effective_date` | DATE | ✔ | When a post-dated voucher becomes effective | `NULL` |
| `is_opening` | TINYINT(1) | — | An opening-balance voucher | `0` |
| `is_closing` | TINYINT(1) | — | A year-end closing journal | `0` |
| `is_system_generated` | TINYINT(1) | — | Created by an integration or a job, not typed by a person | `1` |
| `applicable_upto` | DATE | ✔ | **A reversing journal auto-reverses after this date** — used for accruals | `NULL` |
| **— parties and references —** | | | | |
| `party_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. The counterparty, where there is one | `4471` |
| `narration` | TEXT | ✔ | The description that appears in the day book | `Fee received — cheque 004512` |
| `reference_number` / `reference_date` | VARCHAR(100) / DATE | ✔ | **The external document number** — a vendor's bill number, a cheque number | `INV-2214` |
| `due_date` | DATE | ✔ | On Sales and Purchase invoices | `2026-09-15` |
| **— where it came from —** | | | | |
| `source_module_key` | VARCHAR(10) | ✔ | `glb_app_modules.key` | `FEE` |
| `source_category_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_voucher_category` | `2` |
| `source_model` / `source_id` | VARCHAR(100) / BIGINT | ✔ | **UK.** The originating table and row | `fee_transactions` / `99231` |
| `source_event_uid` | VARCHAR(100) | ✔ | **UK. The idempotency key.** Stops one fee payment producing two vouchers if the event is delivered twice | `fee-txn-99231` |
| **— the workflow trail —** | | | | |
| `entered_by` | INT UNSIGNED | ✔ | Who typed it | `14` |
| `submitted_at` / `submitted_by` | DATETIME / INT UNSIGNED | ✔ | Sent for approval | `NULL` |
| `approved_at` / `approved_by` | DATETIME / INT UNSIGNED | ✔ | Approved | `NULL` |
| `posted_at` / `posted_by` | DATETIME / INT UNSIGNED | ✔ | **Made final and countable** | `2026-09-09 11:02` / `14` |
| `cancelled_at` / `cancelled_by` | DATETIME / INT UNSIGNED | ✔ | Cancelled | `NULL` |
| `cancelled_reason` | VARCHAR(1000) | ✔ | **Mandatory when cancelling** | `NULL` |
| `rejected_reason` | VARCHAR(1000) | ✔ | Why an approver sent it back | `NULL` |

### Keys & rules

| Constraint | What it enforces |
|---|---|
| `UNIQUE (financial_year_id, voucher_type_id, voucher_number)` | **No two vouchers of one type share a number in one year** |
| `UNIQUE (source_model, source_id, source_event_uid)` | **One source event produces at most one voucher** — idempotent integration |
| `CHECK chk_acc_v_number_posted` | A Posted / Cancelled / Reversed voucher **must** have a number; a Draft / Pending / Rejected voucher **must not**. This is what stops drafts consuming numbers |
| `CHECK chk_acc_v_cancel_reason` | Cancelling requires a reason |
| `CHECK (total_amount >= 0)` · `CHECK (exchange_rate > 0)` | Sanity |

## 6.2 `acc_voucher_items` — the Dr/Cr lines

### What it is for

**The single source of truth for every number in this module.** Every balance, every report, every outstanding figure, every fund utilisation traces back to rows in this table. Nothing else is authoritative.

### Example rows — one receipt

| id | voucher_id | ledger_id | sequence_no | entry_type | amount | voucher_status |
|---:|---:|---|:---:|:---:|---:|---|
| 210441 | 88214 | Bank — HDFC Current | 1 | **Dr** | 25,000.00 | `Posted` |
| 210442 | 88214 | Ravi Kumar | 2 | **Cr** | 25,000.00 | `Posted` |

**Note there is no signed amount.** `amount` is always positive; `entry_type` carries the direction. This is deliberate — a signed amount invites someone to store −25,000 as a "credit", and then two different conventions exist in one column.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `210441` |
| `voucher_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_vouchers`, `ON DELETE CASCADE` | `88214` |
| `ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`, `ON DELETE RESTRICT`. **The account being debited or credited** | `142` |
| `sequence_no` | SMALLINT UNSIGNED | — | **UK.** Grid order. **Without it, the lines reorder when a voucher is reopened** and the entry looks different from the one that was approved | `1` |
| `entry_type` | ENUM | — | **`Dr` or `Cr`. This is the direction; the amount is always positive** | `Dr` |
| `amount` | DECIMAL(15,2) | — | Base currency, **always positive** | `25000.00` |
| `amount_txn_ccy` | DECIMAL(15,2) | ✔ | The amount in the original currency | `NULL` |
| **— denormalised for query speed —** | | | | |
| `voucher_date` | DATE | — | Copied from the header. **Every balance query filters on date; joining the header for 10 million lines is not viable** | `2026-09-09` |
| `financial_year_id` | SMALLINT UNSIGNED | — | Copied from the header | `3` |
| `period_id` | SMALLINT UNSIGNED | ✔ | Copied from the header | `30` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | Copied from the header | `1` |
| `voucher_status` | ENUM | — | **Copied from the header. This is the R-02 filter** — every balance query reads `voucher_status = 'Posted'` and never joins | `Posted` |
| `narration` | VARCHAR(500) | ✔ | Line-level description, distinct from the header's | `Cheque 004512` |
| **— reconciliation —** | | | | |
| `is_reconciled` | TINYINT(1) | — | This line has been matched to a bank statement | `0` |
| `reconciled_at` | DATETIME | ✔ | When | `NULL` |
| `bank_value_date` | DATE | ✔ | **The bank's own date, set at reconciliation — never at entry.** The date you wrote the cheque and the date the bank took the money are different facts | `NULL` |

### Keys & rules

- `UNIQUE (voucher_id, sequence_no)` · `CHECK (amount >= 0)`
- `idx_acc_vi_ledger_balance (ledger_id, voucher_status, voucher_date, entry_type, amount)` — **the index the whole module runs on.** It covers the balance query entirely: no table lookup needed.
- **`Σ Dr = Σ Cr` per voucher (R-01) is enforced by `PostingService`, not by a database constraint** — SQL cannot express a cross-row sum check in a CHECK. The nightly assertion in `acc_assertion_results` verifies it independently.

## 6.3 `acc_voucher_item_cost_centers`

### What it is for
Splitting one line across cost centres. A ₹1,00,000 electricity bill might be 60% Primary, 40% Senior.

### Example rows

| voucher_item_id | cost_center_id | cost_category_id | amount | percentage | is_auto_allocated |
|---:|---|---:|---:|---:|:---:|
| 210443 | Primary Section | 1 | 60,000.00 | 60.0000 | 1 |
| 210443 | Senior Section | 1 | 40,000.00 | 40.0000 | 1 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `55021` |
| `voucher_item_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_voucher_items`, `ON DELETE CASCADE` | `210443` |
| `cost_center_id` | INT UNSIGNED | — | **UK.** FK → `acc_cost_centers` | `7` |
| `cost_category_id` | SMALLINT UNSIGNED | — | FK → `acc_cost_categories`. **Denormalised: allocation totals are checked per category** | `1` |
| `amount` | DECIMAL(15,2) | — | The share | `60000.00` |
| `percentage` | DECIMAL(9,4) | ✔ | The share as a percentage, when entered that way | `60.0000` |
| `narration` | VARCHAR(500) | ✔ | Why this split | `Metered separately` |
| `is_auto_allocated` | TINYINT(1) | — | **Filled by a predefined rule rather than typed** | `1` |
| `overridden_by` | INT UNSIGNED | ✔ | FK → `sys_users`. Who changed an automatic allocation | `NULL` |

### Keys & rules
`UNIQUE (voucher_item_id, cost_center_id)` · `CHECK (amount >= 0)`. The **sum of allocations per category must equal the line amount**, enforced in the service.

## 6.4 `acc_voucher_item_funds`

### What it is for
Tagging a line to a restricted fund — and saying whether it **adds to** or **spends from** it.

### Example row

| voucher_item_id | fund_id | amount | allocation_type |
|---:|---|---:|---|
| 210443 | CSR Library Fund | 40,000.00 | `Utilisation` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `9012` |
| `voucher_item_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_voucher_items`, `ON DELETE CASCADE` | `210443` |
| `fund_id` | INT UNSIGNED | — | **UK.** FK → `acc_funds` | `4` |
| `amount` | DECIMAL(15,2) | — | The share | `40000.00` |
| `percentage` | DECIMAL(9,4) | ✔ | As a percentage | `100.0000` |
| `allocation_type` | ENUM | — | **UK.** `Addition` (money in), `Utilisation` (money spent), `Transfer_In`, `Transfer_Out` | `Utilisation` |
| `narration` | VARCHAR(500) | ✔ | Why | `Library books — invoice 2214` |

### Keys & rules
`UNIQUE (voucher_item_id, fund_id, allocation_type)` · `CHECK (amount >= 0)`. Fund balances are recomputed in `acc_fund_balances` from these rows.

## 6.5 `acc_voucher_item_taxes`

### What it is for
The tax computed on a taxable line, and **which voucher line the tax itself posted to**.

### Example rows — an ₹1,00,000 invoice with 18% GST

| voucher_item_id | tax_line_item_id | tax_type_id | taxable_amount | rate_applied | tax_amount |
|---:|---:|---|---:|---:|---:|
| 210451 (the expense) | 210452 (CGST line) | CGST | 100,000.00 | 9.0000 | 9,000.00 |
| 210451 (the expense) | 210453 (SGST line) | SGST | 100,000.00 | 9.0000 | 9,000.00 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4410` |
| `voucher_item_id` | BIGINT UNSIGNED | — | FK → `acc_voucher_items`, `ON DELETE CASCADE`. **The taxable line** | `210451` |
| `tax_line_item_id` | BIGINT UNSIGNED | ✔ | FK → `acc_voucher_items`, `ON DELETE SET NULL`. **The voucher line where the tax itself posted** | `210452` |
| `tax_type_id` | SMALLINT UNSIGNED | — | FK → `acc_tax_types` | `1` |
| `tax_rate_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_tax_rates`. Which rate row was used | `1` |
| `tax_rule_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_tax_rules`. Which rule chose it | `NULL` |
| `taxable_amount` | DECIMAL(15,2) | — | The base the tax was computed on | `100000.00` |
| `rate_applied` | DECIMAL(9,4) | — | **FROZEN. Never read back from `acc_tax_rates`** — a rate change next year must not alter last year's invoice | `9.0000` |
| `tax_amount` | DECIMAL(15,2) | — | The tax | `9000.00` |
| `is_reverse_charge` | TINYINT(1) | — | The recipient pays the tax, not the supplier | `0` |
| `is_input_credit` | TINYINT(1) | — | Tax paid that can be reclaimed | `1` |
| `is_credit_eligible` | TINYINT(1) | — | **Ineligible credit is expensed rather than claimed.** Not all input GST is reclaimable | `1` |
| `hsn_sac_code` | VARCHAR(20) | ✔ | Goods/services classification | `9992` |
| `place_of_supply` | VARCHAR(5) | ✔ | **State code — decides CGST+SGST vs IGST** | `23` |

## 6.6 `acc_voucher_bank_details`

### What it is for
How the money actually moved: which instrument, which bank, which number.

### Example row

```
voucher_id 88214 · bank_ledger_id 142 (HDFC Current)
transaction_type : Cheque
instrument_no    : 004512      instrument_date : 2026-09-09
favouring_name   : "Prime Public School"
counterparty_bank: ICICI Bank
bank_value_date  : NULL        ← set only at reconciliation
is_printed 0
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `7021` |
| `voucher_id` | BIGINT UNSIGNED | — | FK → `acc_vouchers`, `ON DELETE CASCADE` | `88214` |
| `bank_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. Which bank account | `142` |
| `transaction_type` | ENUM | — | `Cheque`, `DD`, `NEFT`, `RTGS`, `IMPS`, `UPI`, `Card`, `Cash`, `ECS`, `Other` | `Cheque` |
| `instrument_no` | VARCHAR(50) | ✔ | **Mandatory for Cheque and DD** | `004512` |
| `instrument_date` | DATE | ✔ | **A future date auto-sets `is_post_dated` on the voucher** | `2026-09-09` |
| `bank_value_date` | DATE | ✔ | **Set at reconciliation, never at entry** | `NULL` |
| `favouring_name` | VARCHAR(200) | ✔ | Payee name as written on the instrument | `Prime Public School` |
| `counterparty_bank` / `counterparty_account` / `counterparty_ifsc` | VARCHAR | ✔ | The other side's bank details | `ICICI Bank` |
| `utr_number` | VARCHAR(50) | ✔ | **The bank's unique transaction reference for NEFT/RTGS/IMPS.** This is what you quote when a transfer goes missing | `HDFCN52026090912` |
| `cheque_leaf_id` | BIGINT UNSIGNED | ✔ | FK → `acc_cheque_leaves`. Which physical leaf was used | `3311` |
| `is_printed` / `printed_at` | TINYINT(1) / DATETIME | — / ✔ | Cheque printing state | `0` |

## 6.7 `acc_voucher_references`

### What it is for
**Voucher-to-voucher relationships** — which voucher reverses, adjusts or corrects which. This is how R-03 works in practice: you never edit a posted voucher, you post another one that points back at it.

### Example rows

| voucher_id | against_voucher_id | reference_type | amount | note |
|---:|---:|---|---:|---|
| 88990 (JV-0044) | 88214 (RCP-0431) | `Reverses` | 25,000.00 | Cheque bounced |
| 89100 (RCP-0500) | 88214 (RCP-0431) | `Replaces` | 25,000.00 | Re-presented by NEFT |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `1204` |
| `voucher_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_vouchers`, `ON DELETE CASCADE`. **The adjusting or reversing voucher** | `88990` |
| `against_voucher_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_vouchers`, `ON DELETE RESTRICT`. **The original.** RESTRICT, because you cannot delete a voucher something points at | `88214` |
| `reference_type` | ENUM | — | **UK.** `Adjusts`, `Reverses`, `Corrects`, `Settles`, `Relates_To`, `Replaces` | `Reverses` |
| `amount` | DECIMAL(15,2) | ✔ | How much of the original this affects | `25000.00` |
| `note` | VARCHAR(500) | ✔ | Why | `Cheque 004512 bounced` |

### Keys & rules
`CHECK (voucher_id <> against_voucher_id)` — a voucher cannot reverse itself.

## 6.8 `acc_voucher_approvals`

### What it is for
The **approval trail**: every submission, approval, rejection, escalation and override, at every level.

### Example rows

| voucher_id | approval_level | action | actioned_by | is_self_approval |
|---:|:---:|---|---:|:---:|
| 88700 | 1 | `Submitted` | 14 | 0 |
| 88700 | 1 | `Approved` | 22 | 0 |
| 88700 | 2 | `Approved` | 3 | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `3320` |
| `voucher_id` | BIGINT UNSIGNED | — | FK → `acc_vouchers`, `ON DELETE CASCADE` | `88700` |
| `approval_level` | TINYINT UNSIGNED | — | Which level this action was at | `2` |
| `policy_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_approval_policies`. Which rule applied | `4` |
| `action` | ENUM | — | `Submitted`, `Approved`, `Rejected`, `Escalated`, `Overridden`, `Withdrawn` | `Approved` |
| `actioned_by` | INT UNSIGNED | ✔ | FK → `sys_users` | `3` |
| `actioned_at` | DATETIME | — | When | `2026-09-08 15:22` |
| `is_self_approval` | TINYINT(1) | — | **Flagged for the segregation-of-duties report even when the policy permits it.** Recording it is the control; blocking it is not always practical in a small school | `0` |
| `note` | VARCHAR(1000) | ✔ | Approver's comment | `Sanction letter attached` |

## 6.9 `acc_voucher_attachments`

### What it is for
The supporting documents — the invoice, the sanction letter, the bank advice. Some voucher types make an attachment mandatory (`requires_evidence`).

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `2101` |
| `voucher_id` | BIGINT UNSIGNED | — | FK → `acc_vouchers`, `ON DELETE CASCADE` | `88700` |
| `media_id` | INT UNSIGNED | — | FK → `sys_media`, `ON DELETE RESTRICT`. **The file itself lives in media storage** | `9912` |
| `file_name` | VARCHAR(255) | ✔ | Original name | `sharma-invoice-2214.pdf` |
| `document_type` | ENUM | — | `Invoice`, `Bill`, `Receipt`, `Contract`, `Sanction`, `Bank_Advice`, `Challan`, `Other` | `Invoice` |
| `note` | VARCHAR(500) | ✔ | What this document shows | `Original tax invoice` |
| `uploaded_by` | INT UNSIGNED | ✔ | FK → `sys_users` | `14` |

---

# SECTION 7 — Bill-wise Tracking

**The question this section answers: *which invoices are still unpaid, and how old are they?***

A ledger balance tells you Ravi Kumar owes ₹25,000. It does not tell you whether that is one bill from last week or three bills, one of which is 120 days overdue. Bill-wise tracking is the difference.

## 7.1 `acc_bill_references` — one invoice or demand

### What it is for
One tracked obligation: a fee demand, a vendor bill, an advance. It is opened when the demand is raised and settled when payments are allocated to it.

### Example row

```
ledger_id       : 4471 (Ravi Kumar)
reference_no    : FEE/T2/00412
reference_date  : 2026-09-05     due_date : 2026-09-15
bill_type       : Sales
original_amount : 25,000.00
source_voucher_id : 88213 (SAL-0117)
status          : Settled
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `55110` |
| `ledger_id` | INT UNSIGNED | — | **UK.** FK → `acc_ledgers`. **The party who owes or is owed** | `4471` |
| `reference_no` | VARCHAR(100) | — | **UK.** The bill or demand number | `FEE/T2/00412` |
| `reference_date` | DATE | — | Bill date | `2026-09-05` |
| `due_date` | DATE | ✔ | **When payment is due. This drives the ageing report** | `2026-09-15` |
| `bill_type` | ENUM | — | `Sales`, `Purchase`, `Advance`, `On_Account`, `Opening`, `Adjustment` | `Sales` |
| `original_amount` | DECIMAL(15,2) | — | The full amount of the bill | `25000.00` |
| `currency_id` / `exchange_rate` | SMALLINT / DECIMAL(18,8) | ✔ / — | Foreign-currency bills | `NULL` / `1.0` |
| `source_voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The voucher that created this bill** | `88213` |
| `source_voucher_item_id` | BIGINT UNSIGNED | ✔ | FK → `acc_voucher_items`. Which line | `210440` |
| `financial_year_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_financial_years` | `3` |
| `campus_id` / `fund_id` / `cost_center_id` | SMALLINT / INT / INT | ✔ | Dimensions carried from the source | `1` |
| `status` | ENUM | — | `Open`, `Partially_Settled`, `Settled`, `Written_Off`, `Disputed`, `Cancelled` | `Settled` |
| `is_disputed` / `dispute_note` | TINYINT(1) / VARCHAR(500) | — / ✔ | **A disputed bill still ages but is excluded from collection chasing** | `0` |
| `written_off_amount` | DECIMAL(15,2) | — | How much was given up as uncollectable | `0.00` |
| `written_off_voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The write-off must itself be a posted voucher** | `NULL` |
| `narration` | VARCHAR(500) | ✔ | Description | `Term 2 tuition` |

### Keys & rules
`UNIQUE (ledger_id, reference_no, financial_year_id)` · `CHECK (original_amount >= 0)` · `CHECK (written_off_amount BETWEEN 0 AND original_amount)`.

**There is no `outstanding_amount` column here (R-05).** Outstanding is `original − allocated − written_off`, computed in `acc_bill_reference_balances`.

## 7.2 `acc_bill_allocations`

### What it is for
**Which payment settled which bill, and by how much.** One receipt may settle three bills; one bill may be settled by four instalments.

### Example rows

| bill_reference_id | voucher_item_id | voucher_id | allocation_type | amount |
|---:|---:|---:|---|---:|
| 55110 | 210442 | 88214 | `Against_Reference` | 25,000.00 |
| 55111 | 210442 | 88214 | `Against_Reference` | 8,000.00 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `77201` |
| `bill_reference_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_bill_references`, `ON DELETE RESTRICT` | `55110` |
| `voucher_item_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_voucher_items`, `ON DELETE CASCADE`. The payment line | `210442` |
| `voucher_id` | BIGINT UNSIGNED | — | FK → `acc_vouchers`, `ON DELETE CASCADE`. **Denormalised: cancelling a voucher releases its allocations by voucher, without joining** | `88214` |
| `allocation_type` | ENUM | — | `Against_Reference` (settles an existing bill), `New_Reference` (opens one), `Advance`, `On_Account` (unallocated), `Write_Off`, `Adjustment` | `Against_Reference` |
| `amount` | DECIMAL(15,2) | — | How much of the payment goes to this bill | `25000.00` |
| `allocation_date` | DATE | — | When it was applied | `2026-09-09` |
| `note` | VARCHAR(500) | ✔ | Any qualification | `NULL` |
| `allocated_by` | INT UNSIGNED | ✔ | FK → `sys_users` | `14` |

### Keys & rules
`UNIQUE (bill_reference_id, voucher_item_id)` · **`CHECK (amount > 0)`** — note strictly greater than zero; a zero allocation means nothing.

---

# SECTION 8 — Balances

Every table in this section is **derived from `acc_voucher_items`** (R-05). None of them is a place where somebody types a balance.

| Table | Holds | Rebuilt by |
|---|---|---|
| `acc_ledger_period_balances` | **CACHE** — ledger balance per month, per dimension | `acc:rebuild-balances` |
| `acc_period_closing_balances` | **SNAPSHOT** — frozen at month close, never recomputed | Period close |
| `acc_opening_balances` | The starting position of a financial year | Migration or carry-forward |
| `acc_fund_balances` | **CACHE** — fund position per month | `acc:rebuild-balances` |
| `acc_bill_reference_balances` | **CACHE** — outstanding per bill, with ageing | `acc:rebuild-balances` |
| `acc_period_close_checklist` | What must be true before a month can close | — |

**Cache vs snapshot is the important distinction.** A cache can be thrown away and rebuilt from the transactions. A snapshot is a historical record of what the books said on the day they were closed, and rebuilding it would destroy its purpose.

## 8.1 `acc_ledger_period_balances` — the balance cache

### What it is for
Ledger balances per period, optionally split by cost centre, fund and campus. This exists so a trial balance does not aggregate ten million voucher lines every time somebody opens a report.

### Example row

```
ledger_id 4471 (Ravi Kumar) · financial_year_id 3 · period_id 30 (Sep 2026)
cost_center_id NULL · fund_id NULL · campus_id 1
opening_debit  0.00      opening_credit  0.00
period_debit   25,000.00 period_credit   25,000.00
closing_debit  0.00      closing_credit  0.00
transaction_count    : 2
last_voucher_item_id : 210442     ← the newest line folded in
last_rebuilt_at      : 2026-09-09 23:05
is_stale             : 0
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `881021` |
| `ledger_id` | INT UNSIGNED | — | **UK.** FK → `acc_ledgers`, `ON DELETE CASCADE` | `4471` |
| `financial_year_id` | SMALLINT UNSIGNED | — | FK → `acc_financial_years` | `3` |
| `period_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_accounting_periods` | `30` |
| `cost_center_id` | INT UNSIGNED | ✔ | FK → `acc_cost_centers`. NULL = not split by cost centre | `NULL` |
| `fund_id` | INT UNSIGNED | ✔ | FK → `acc_funds` | `NULL` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_campuses` | `1` |
| `opening_debit` / `opening_credit` | DECIMAL(18,2) | — | Where the period started | `0.00` |
| `period_debit` / `period_credit` | DECIMAL(18,2) | — | Movement during the period | `25000.00` |
| `closing_debit` / `closing_credit` | DECIMAL(18,2) | — | Where it ended | `0.00` |
| `transaction_count` | INT UNSIGNED | — | Lines folded in | `2` |
| `last_voucher_item_id` | BIGINT UNSIGNED | ✔ | **CACHE.** The newest line included. **Makes drift diagnosable** — you can see exactly where it stopped | `210442` |
| `last_rebuilt_at` | DATETIME | ✔ | **CACHE.** Last full recomputation | `2026-09-09 23:05` |
| `is_stale` | TINYINT(1) | — | **CACHE.** Set by a failed assertion; cleared by a rebuild | `0` |
| `cc_marker` / `fund_marker` / `campus_marker` | GEN | — | **NULL-safe unique key components.** See the pattern section | `0` / `0` / `1` |

### Keys & rules

`UNIQUE (ledger_id, period_id, cc_marker, fund_marker, campus_marker)` · `CHECK` — all six balance columns are `>= 0`.

> **Why debit and credit are separate columns rather than one signed balance.** A trial balance must show ₹25,000 Dr and ₹25,000 Cr as two figures that visibly agree. A single net column of `0.00` hides both, and hides whether the ledger moved at all.

### Additional Info:
### Calculation Engine for `acc_ledger_period_balances` Closing Balances

To calculate the final Closing Balance for every period in acc_ledger_period_balances, the system uses a period-bucketed derivation model maintained by PostingService.

Here is the step-by-step breakdown of how closing balances are computed, updated, and carried forward across accounting periods.

1. The Core Calculation Formula
For any given ledger in a specific period:

$$\text{Closing Balance} = \text{Opening Balance} + \text{Period Movement}$$

Because accounting principles require separate Debit and Credit columns (so a Trial Balance can display ₹25,000 Dr and ₹25,000 Cr separately rather than hiding both behind 0.00), the stored fields work as follows:

Opening Balance (opening_debit, opening_credit):
Represents the balance at the start of the period.
Period Movement (period_debit, period_credit):
The sum ($\Sigma$) of all posted transactions (acc_voucher_items) for that ledger within the period's date range.
Closing Balance (closing_debit, closing_credit):
Derived mathematically: $$\text{Net Opening} = \text{opening_debit} - \text{opening_credit}$$ $$\text{Net Period} = \text{period_debit} - \text{period_credit}$$ $$\text{Net Closing} = \text{Net Opening} + \text{Net Period}$$
Stored in standard Dr/Cr format:
If $\text{Net Closing} \ge 0 \implies \text{closing_debit} = \text{Net Closing}, \quad \text{closing_credit} = 0.00$
If $\text{Net Closing} < 0 \implies \text{closing_debit} = 0.00, \quad \text{closing_credit} = |\text{Net Closing}|$
2. How Opening Balances Carry Forward Across Periods
The periods in a financial year form a continuous chain:

[ Period 1 (e.g. Apr) ] ──► [ Period 2 (e.g. May) ] ──► [ Period 3 (e.g. Jun) ]
  Opening: Year-Start          Opening = Period 1 Closing    Opening = Period 2 Closing
  + Movement                   + Movement                    + Movement
  = Closing ──────────────────►= Closing ───────────────────►= Closing
Period 1 (First Period of FY):
Asset, Liability, Equity Ledgers: opening_debit / opening_credit comes from the opening balance table (acc_opening_balances) or the prior year-end carry-forward.
Income & Expense Ledgers: opening_debit / opening_credit start at 0.00 (since P&L accounts reset at the start of a financial year).
Period 2 to 12 (Subsequent Periods):
opening_debit and opening_credit for Period $N$ are always equal to closing_debit and closing_credit of Period $N-1$.
3. How Rows Are Updated (Maintenance Engine)
acc_ledger_period_balances is a derived balance cache. There are two ways these rows stay up to date:

A. Incremental Posting (PostingService)
When a new voucher is posted (e.g., in Period 3):
PostingService finds the matching row (ledger_id, financial_year_id, period_id, cc_marker=0, fund_marker=0, campus_marker=0).
It adds the line amount to period_debit or period_credit.
It recalculates closing_debit / closing_credit for Period 3.
If a backdated entry is posted into an earlier open period (e.g., Period 1), the resulting change in closing balance cascades forward to update the opening/closing balances of subsequent periods (Periods 2 and 3).
B. Complete Rebuild (php artisan acc:rebuild-balances)
If needed, the system can truncate acc_ledger_period_balances and recompute every single row sequentially by aggregating acc_voucher_items from scratch.
Design Rule R-05 guarantees that deleting and rebuilding this table yields byte-identical figures.
4. What the Total Row (NULL Dimensions) Means for Statements
In Phase 1, only the ledger total rows are maintained:

cost_center_id = NULL
fund_id = NULL
campus_id = NULL
When reports like Trial Balance, Balance Sheet, or Income & Expenditure run, they execute a simple indexed query:

sql
SELECT ledger_id, closing_debit, closing_credit
FROM acc_ledger_period_balances
WHERE period_id = :periodId
  AND cost_center_id IS NULL 
  AND fund_id IS NULL 
  AND campus_id IS NULL;
Because the total row already caches the final closing balance for that period, the financial statements perform a single indexed table scan rather than summing millions of voucher line items.

5. Period Close & Frozen Snapshots
When a period is officially closed:

The final closing balances from acc_ledger_period_balances are written into acc_period_closing_balances (an immutable snapshot table).
Future statement queries for closed periods read from acc_period_closing_balances to guarantee 100% reproducible figures regardless of any administrative audit adjustments.

---

## 8.2 `acc_period_closing_balances` — the frozen snapshot

### What it is for

**What the books said on the day the month was closed.** This is not a cache: it is never recomputed, because its whole purpose is to be a fixed record. If someone reopens the period and posts a back-dated entry, the snapshot still shows what was signed off — and the difference is exactly what an auditor wants to see.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4410` |
| `period_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_accounting_periods` | `29` |
| `financial_year_id` | SMALLINT UNSIGNED | — | FK → `acc_financial_years` | `3` |
| `ledger_id` | INT UNSIGNED | — | **UK.** FK → `acc_ledgers` | `142` |
| `account_group_id` | INT UNSIGNED | — | FK → `acc_account_groups`. **Snapshotted too** — a ledger could be regrouped later | `12` |
| `group_nature` | ENUM | — | `Asset`, `Liability`, `Equity`, `Income`, `Expense`. **Also snapshotted**, so a later reclassification cannot rewrite a closed month's balance sheet | `Asset` |
| `opening_debit` | DECIMAL(18,2) | — | Debit brought forward into the period | `1284000.00` |
| `opening_credit` | DECIMAL(18,2) | — | Credit brought forward | `0.00` |
| `period_debit` | DECIMAL(18,2) | — | Debit movement during the period | `412000.00` |
| `period_credit` | DECIMAL(18,2) | — | Credit movement | `388000.00` |
| `closing_debit` | DECIMAL(18,2) | — | Debit carried forward, **as at close** | `1308000.00` |
| `closing_credit` | DECIMAL(18,2) | — | Credit carried forward | `0.00` |
| `transaction_count` | INT UNSIGNED | — | Lines in the period | `412` |
| `max_voucher_item_id` | BIGINT UNSIGNED | ✔ | **The highest line id included.** Anything posted after this is a back-dated entry, and this is how you find them | `209918` |
| `snapshot_version` | SMALLINT UNSIGNED | — | **UK. Incremented on an authorised re-close.** Version 1 and version 2 both survive | `1` |
| `frozen_at` / `frozen_by` | DATETIME / INT UNSIGNED | — / ✔ | When the snapshot was taken and by whom | `2026-09-02 18:40` |

### Keys & rules
`UNIQUE (period_id, ledger_id, snapshot_version)`. All FKs are `ON DELETE RESTRICT` — a closed period's evidence cannot be deleted out from under it.

## 8.3 `acc_opening_balances`

### What it is for
Where a financial year starts. Either **migrated** from a previous system, **carried forward** from last year's closing snapshot, or **corrected** afterwards.

### Example row

```
ledger_id 142 · financial_year_id 3
entry_type Dr · amount 1,284,000.00
source                    : Carry_Forward
source_closing_balance_id : 4410           ← traces to the 2025-26 March snapshot
status                    : Finalised
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `9001` |
| `ledger_id` | INT UNSIGNED | — | **UK.** FK → `acc_ledgers` | `142` |
| `financial_year_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_financial_years` | `3` |
| `campus_id` / `fund_id` | SMALLINT / INT | ✔ | Dimensions | `NULL` |
| `entry_type` | ENUM | — | `Dr` or `Cr` | `Dr` |
| `amount` | DECIMAL(18,2) | — | Always positive; direction is in `entry_type` | `1284000.00` |
| `currency_id` / `exchange_rate` / `amount_txn_ccy` | SMALLINT / DECIMAL(18,8) / DECIMAL(18,2) | ✔ / — / ✔ | Foreign-currency opening positions | `NULL` |
| `source` | ENUM | — | **`Migration`** (from the old system), **`Carry_Forward`** (from last year's close), **`Correction`** | `Carry_Forward` |
| `source_closing_balance_id` | BIGINT UNSIGNED | ✔ | FK → `acc_period_closing_balances`. **The snapshot row this came from** — full traceability | `4410` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. The opening journal, where one was posted | `88001` |
| `status` | ENUM | — | `Draft`, `Finalised`, `Superseded` | `Finalised` |
| `finalised_at` / `finalised_by` | DATETIME / INT UNSIGNED | ✔ | When it was locked | `2026-04-02 10:00` |
| `superseded_by_id` | BIGINT UNSIGNED | ✔ | Self-FK. **A correction supersedes rather than overwrites** | `NULL` |
| `correction_reason` | VARCHAR(500) | ✔ | **Mandatory when `source = 'Correction'`** | `NULL` |
| `notes` | VARCHAR(500) | ✔ | Free notes | `NULL` |
| `campus_marker` | SMALLINT UNSIGNED | — | **GEN.** `IFNULL(campus_id, 0)` | `0` |
| `fund_marker` | INT UNSIGNED | — | **GEN.** `IFNULL(fund_id, 0)` | `0` |

### Keys & rules
`UNIQUE (ledger_id, financial_year_id, campus_marker, fund_marker)` · `CHECK (amount >= 0)` · `CHECK (exchange_rate > 0)` · `CHECK` — a correction requires a reason.

> **⚠ Changed in v4.6, and it changes behaviour.** In v4.5 this key ended in `del_marker`, so a BR-OPEN-04 correction could be stored as a **second row** beside the soft-deleted original — that is what `status = 'Superseded'` and `superseded_by_id` were for. Without `del_marker` the two rows collide on this key. **A correction must now UPDATE the row in place**, writing `correction_reason` and leaving the audit trail in `acc_audit_logs` rather than in a second row. If supersession-as-a-second-row is required, this key needs a `version` column — not `del_marker` back.

## 8.4 `acc_fund_balances`

### What it is for
**CACHE.** Where each restricted fund stands: what came in, what was spent, what remains available.

### Example row

```
fund_id 4 (CSR Library) · period_id 30
opening_balance 500,000.00
additions 0.00 · utilisation 140,000.00 · transfers_in 0.00 · transfers_out 0.00
closing_balance   : 360,000.00
available_balance : 360,000.00
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `2201` |
| `fund_id` | INT UNSIGNED | — | **UK.** FK → `acc_funds`, `ON DELETE CASCADE` | `4` |
| `financial_year_id` | SMALLINT UNSIGNED | — | FK → `acc_financial_years` | `3` |
| `period_id` | SMALLINT UNSIGNED | — | **UK.** FK → `acc_accounting_periods` | `30` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_campuses` | `NULL` |
| `opening_balance` | DECIMAL(18,2) | — | Where the period started | `500000.00` |
| `additions` | DECIMAL(18,2) | — | **Receipts into the fund** | `0.00` |
| `utilisation` | DECIMAL(18,2) | — | **Spend from the fund** | `140000.00` |
| `transfers_in` / `transfers_out` | DECIMAL(18,2) | — | Movement between funds | `0.00` |
| `closing_balance` | DECIMAL(18,2) | — | Where it ended | `360000.00` |
| `available_balance` | DECIMAL(18,2) | ✔ | **Closing less commitments.** What may still be spent | `360000.00` |
| `last_voucher_item_id` / `last_rebuilt_at` / `is_stale` | — | | **CACHE triple.** See the pattern section | `210443` |
| `campus_marker` | GEN | — | NULL-safe key component | `0` |

### Keys & rules
`UNIQUE (fund_id, period_id, campus_marker)`.

## 8.5 `acc_bill_reference_balances`

### What it is for
**CACHE.** Outstanding per bill, with ageing. This is what the receivables and payables reports read; it means an ageing report never aggregates allocations at query time.

### Example row

```
bill_reference_id 55110 · ledger_id 4471
original_amount  25,000.00
allocated_amount 25,000.00
written_off_amount 0.00
outstanding_amount 0.00
due_date 2026-09-15 · days_overdue -6 · age_bucket NULL
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `55110` |
| `bill_reference_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_bill_references`, `ON DELETE CASCADE`. **One row per bill** | `55110` |
| `ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. **Denormalised: party ageing never joins** | `4471` |
| `original_amount` | DECIMAL(15,2) | — | The full bill | `25000.00` |
| `allocated_amount` | DECIMAL(15,2) | — | Sum of allocations against it | `25000.00` |
| `written_off_amount` | DECIMAL(15,2) | — | Given up as uncollectable | `0.00` |
| `outstanding_amount` | DECIMAL(15,2) | — | **`original − allocated − written_off`** | `0.00` |
| `due_date` | DATE | ✔ | Copied from the bill | `2026-09-15` |
| `days_overdue` | INT | — | **Recomputed nightly. Negative = not yet due** | `-6` |
| `age_bucket` | VARCHAR(20) | ✔ | `'0-30'`, `'31-60'`, `'61-90'`, `'90+'`. **Buckets are configurable** | `NULL` |
| `last_allocation_id` / `last_rebuilt_at` / `is_stale` | — | | CACHE triple | `77201` |

### Keys & rules
`UNIQUE (bill_reference_id)` · `CHECK (outstanding_amount >= 0)`.

### Additional Info:

In the accounting schema, the age_bucket field in acc_bill_reference_balances is configured via system settings stored in the acc_settings table.

Here is how the configuration works in detail:

1. Configuration in acc_settings
The bucket thresholds and calculation rules are stored in acc_settings (Line 4773–4774 of Accounting_DDL_v4.7.sql):

sql
INSERT INTO `acc_settings` 
  (`setting_key`, `setting_group`, `value_type`, `value_json`, `default_value`, `description`, `is_school_editable`) 
VALUES
  ('billwise.ageing_buckets', 'Bill_Wise', 'Json', CAST('[30,60,90,180]' AS JSON), '[30,60,90,180]', 'Ageing bucket edges in days (BR-AR-02)', 1),
  ('billwise.ageing_basis',   'Bill_Wise', 'String', NULL, 'Due_Date', 'Age from the due date or the bill date (BR-AR-02)', 1);
Key Settings:
billwise.ageing_buckets: A JSON array of day limits.
Default: [30, 60, 90, 180]
This JSON array defines the interval boundaries:
Bucket 1: 0 to 30 days (01_30)
Bucket 2: 31 to 60 days (31_60)
Bucket 3: 61 to 90 days (61_90)
Bucket 4: 91 to 180 days (91_180)
Bucket 5: > 180 days (Over_180)
billwise.ageing_basis: Defines whether the age calculation calculates days elapsed from Due_Date or Bill_Date (Reference Date).
2. How School/Tenant Customization Works
Since is_school_editable = 1, an institution can customize its ageing buckets via the admin interface or API update to acc_settings:

sql
-- Example: Customizing to 15, 30, 45, 60 day buckets for a specific campus or school-wide
UPDATE `acc_settings`
SET `value_json` = JSON_ARRAY(15, 30, 45, 60)
WHERE `setting_key` = 'billwise.ageing_buckets';
3. How the Services & Views Use It
BalanceService / Background Cache Rebuild:

When updating acc_bill_reference_balances, the service reads the JSON bucket array from acc_settings.
It calculates: $$\text{days_overdue} = \text{DATEDIFF}(\text{CURRENT_DATE}, \text{due_date})$$
It assigns the string label matching the bucket interval (e.g. '01_30', '31_60', '61_90') to acc_bill_reference_balances.age_bucket.
Reporting Views (vw_receivable_ageing & vw_payable_ageing):

The default SQL views fallback to the standard CASE evaluation (Line 3997–4004):
sql
CASE
    WHEN days_overdue <= 0   THEN 'Not_Due'
    WHEN days_overdue <= 30  THEN '01_30'
    WHEN days_overdue <= 60  THEN '31_60'
    WHEN days_overdue <= 90  THEN '61_90'
    WHEN days_overdue <= 180 THEN '91_180'
    ELSE                          'Over_180'
END AS ageing_bucket
When reporting dynamically, the Laravel reporting service evaluates the custom edges from acc_settings to group open bill references according to the institution's configured intervals.

---

## 8.6 `acc_period_close_checklist`

### What it is for
**What must be true before a month can be closed.** Some checks are automatic (the service runs them); some are manual (a person confirms them). A blocking item that has not passed stops the close.

### Example rows

| item_code | item_name | item_group | is_blocking | check_type | status |
|---|---|---|:---:|---|---|
| `ALL_POSTED` | No draft vouchers remain | `Transactions` | 1 | `Automatic` | `Passed` |
| `BANK_RECONCILED` | All bank accounts reconciled | `Reconciliation` | 1 | `Automatic` | `Failed` |
| `SUSPENSE_ZERO` | Suspense account is nil | `Review` | 1 | `Automatic` | `Passed` |
| `TDS_DEPOSITED` | TDS for the month deposited | `Compliance` | 0 | `Manual` | `Waived` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `771` |
| `period_id` | SMALLINT UNSIGNED | — | FK → `acc_accounting_periods` | `30` |
| `financial_year_id` | SMALLINT UNSIGNED | — | FK → `acc_financial_years` | `3` |
| `item_code` | VARCHAR(50) | — | Stable identifier for the check | `BANK_RECONCILED` |
| `item_name` | VARCHAR(200) | — | What the human sees | `All bank accounts reconciled` |
| `item_group` | ENUM | — | `Transactions`, `Reconciliation`, `Compliance`, `Review` | `Reconciliation` |
| `ordinal` | SMALLINT UNSIGNED | — | Display order | `4` |
| `is_blocking` | TINYINT(1) | — | **A failed blocking item stops the close** | `1` |
| `check_type` | ENUM | — | `Automatic` (a service runs it) or `Manual` (a person confirms it) | `Automatic` |
| `checker_key` | VARCHAR(100) | ✔ | Which service check produces this result | `bank.unreconciled_count` |
| `status` | ENUM | — | `Pending`, `Passed`, `Failed`, `Waived`, `Not_Applicable` | `Failed` |
| `owner_user_id` | INT UNSIGNED | ✔ | FK → `sys_users`. Who must action it | `22` |
| `result_value` / `result_count` | DECIMAL(18,2) / INT | ✔ | The measured figure | `48200.00` / `7` |
| `result_detail` | TEXT | ✔ | **JSON: the offending record ids.** "7 items unreconciled" is not actionable; a list of them is | `[88214, 88301, …]` |
| `evidence_media_id` | INT UNSIGNED | ✔ | FK → `sys_media`. A signed checklist, a bank letter | `NULL` |
| `waived_by` / `waived_at` / `waive_reason` | INT / DATETIME / VARCHAR(1000) | ✔ | **Waiving a blocking item is permitted — and recorded, with a reason** | `NULL` |
| `checked_at` / `checked_by` | DATETIME / INT UNSIGNED | ✔ | When the check last ran | `2026-10-01 09:00` |

---

# SECTION 9 — Banking

```
acc_cheque_registers          a cheque book
  └── acc_cheque_leaves       individual leaves, each used at most once
acc_cheque_transactions       the LIFECYCLE of a cheque: issued → presented → cleared / bounced
acc_bank_reconciliations      one reconciliation exercise for one account, one statement date
  ├── acc_bank_statement_mapping    how to read this bank's CSV
  ├── acc_bank_statement_entries    the statement lines
  └── acc_bank_reconciliation_matches   statement line ↔ voucher line
```

## 9.1 `acc_cheque_registers`

### What it is for
A physical cheque book, so that every leaf is accounted for. **Losing track of blank cheques is a fraud risk**, and this makes "which leaves are unused?" answerable.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `12` |
| `bank_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. Which account | `142` |
| `book_number` | VARCHAR(50) | — | The book identifier | `HDFC-CB-07` |
| `leaf_prefix` | VARCHAR(10) | ✔ | Any prefix printed on the leaves | `00` |
| `start_leaf_no` / `end_leaf_no` | BIGINT UNSIGNED | — | The range this book covers | `4501` / `4550` |
| `total_leaves` | SMALLINT UNSIGNED | — | How many | `50` |
| `received_date` | DATE | ✔ | When the book arrived from the bank | `2026-08-01` |
| `status` | ENUM | — | `Active`, `Exhausted`, `Cancelled`, `Lost` | `Active` |
| `notes` | VARCHAR(500) | ✔ | Free notes | `NULL` |

## 9.2 `acc_cheque_leaves`

### What it is for
One row per physical leaf. **A leaf can be used at most once**, which is what stops the same cheque number being issued twice.

### Example rows

| leaf_no | status | voucher_id | issued_date |
|---:|---|---:|---|
| 4510 | `Issued` | 88214 | 2026-09-09 |
| 4511 | `Spoiled` | NULL | — |
| 4512 | `Unused` | NULL | — |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `3311` |
| `cheque_register_id` | BIGINT UNSIGNED | — | FK → `acc_cheque_registers` | `12` |
| `bank_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. **Denormalised: leaf lookup never joins the register** | `142` |
| `leaf_no` | BIGINT UNSIGNED | — | The printed number | `4510` |
| `status` | ENUM | — | `Unused`, `Issued`, `Cancelled`, `Spoiled`, `Lost` | `Issued` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **Set when the leaf is used** | `88214` |
| `issued_date` | DATE | ✔ | When | `2026-09-09` |
| `cancelled_reason` | VARCHAR(500) | ✔ | Why a leaf was spoiled or cancelled | `Printer misfeed` |

## 9.3 `acc_cheque_transactions`

### What it is for
**The life of a cheque after it leaves your hand.** A cheque is not money until it clears, and this table tracks the difference — including bounces, stop payments, and cheques that go stale (uncashed for three months).

### Example row

```
voucher_id 88214 · bank_ledger_id 142 · direction Issued
instrument_no 004512 · instrument_date 2026-09-09 · amount 25,000.00
status      : Cleared         status_date : 2026-09-12
is_post_dated 0 · stale_on 2026-12-09
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4401` |
| `voucher_id` | BIGINT UNSIGNED | — | FK → `acc_vouchers` | `88214` |
| `voucher_bank_detail_id` | BIGINT UNSIGNED | ✔ | FK → `acc_voucher_bank_details` | `7021` |
| `bank_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers` | `142` |
| `party_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. Who it was to or from | `4471` |
| `direction` | ENUM | — | **`Issued`** (you wrote it) or **`Received`** (someone gave it to you) | `Issued` |
| `cheque_leaf_id` | BIGINT UNSIGNED | ✔ | FK → `acc_cheque_leaves`. **Only for `Issued`** | `3311` |
| `instrument_no` / `instrument_date` | VARCHAR(50) / DATE | — | The cheque | `004512` / `2026-09-09` |
| `amount` | DECIMAL(15,2) | — | Face value | `25000.00` |
| `favouring_name` / `counterparty_bank` | VARCHAR(200)/(150) | ✔ | Payee and their bank | `Prime Public School` |
| `status` | ENUM | — | **`Issued` → `Presented` → `Cleared`**, or `Bounced`, `Stopped`, `Cancelled`, `Stale` | `Cleared` |
| `status_date` | DATE | — | When the status last changed | `2026-09-12` |
| `status_note` | VARCHAR(500) | ✔ | Any explanation | `NULL` |
| `is_post_dated` | TINYINT(1) | — | Dated in the future | `0` |
| `stale_on` | DATE | ✔ | **When it becomes stale — three months in India.** After this the bank will not honour it | `2026-12-09` |
| `bounce_reason` | VARCHAR(255) | ✔ | Why it was returned | `NULL` |
| `bounce_charge_amount` | DECIMAL(15,2) | ✔ | The bank's penalty | `NULL` |
| `reversal_voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The entry that reverses the original receipt when it bounces** | `NULL` |
| `charge_voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. The entry booking the bounce charge | `NULL` |
| `replacement_voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. The replacement payment | `NULL` |
| `actioned_by` | INT UNSIGNED | ✔ | FK → `sys_users` | `14` |

> **Three separate voucher links, not one.** A bounced cheque produces three distinct accounting events — reverse the receipt, book the charge, record the replacement — and collapsing them into one column would lose which was which.

## 9.4 `acc_bank_reconciliations`

### What it is for
One reconciliation exercise: **proving that what your books say about a bank account matches what the bank says**, and explaining every difference.

### Example row

```
bank_ledger_id 142 · statement_date 2026-09-30
balance_as_per_books      : 1,284,000.00
unpresented_amount        :    48,000.00   ← cheques you wrote, bank hasn't paid yet
uncredited_amount         :    25,000.00   ← deposits bank hasn't credited yet
other_adjustments         :         0.00
balance_as_per_bank       : 1,307,000.00   ← computed
statement_closing_balance : 1,307,000.00   ← what the bank actually says
difference                :         0.00   ← must be zero to complete
status                    : Completed
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `220` |
| `bank_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. Which account | `142` |
| `financial_year_id` / `period_id` | SMALLINT UNSIGNED | — / ✔ | Which period | `3` / `30` |
| `statement_from_date` / `statement_date` | DATE | ✔ / — | The statement period; `statement_date` is its closing date | `2026-09-30` |
| `balance_as_per_books` | DECIMAL(18,2) | — | What the ledger says | `1284000.00` |
| `unpresented_amount` | DECIMAL(18,2) | — | **Cheques issued but not yet debited by the bank** | `48000.00` |
| `uncredited_amount` | DECIMAL(18,2) | — | **Deposits not yet credited by the bank** | `25000.00` |
| `other_adjustments` | DECIMAL(18,2) | — | Bank charges, interest, anything else | `0.00` |
| `balance_as_per_bank` | DECIMAL(18,2) | — | **Computed** from the four figures above | `1307000.00` |
| `statement_closing_balance` | DECIMAL(18,2) | — | **What the bank actually says** | `1307000.00` |
| `difference` | DECIMAL(18,2) | — | **Computed minus actual. Must be zero to complete the reconciliation** | `0.00` |
| `statement_file_name` / `media_id` | VARCHAR(255) / INT | ✔ | The statement file | `hdfc-sep-2026.csv` |
| `can_be_import` | TINYINT(1) | — | This statement can be machine-imported | `1` |
| `imported_row_count` | INT UNSIGNED | — | Lines read from the file | `184` |
| `auto_confirm_exact` | TINYINT(1) | — | **Automatically confirm matches where amount, date and reference all agree exactly** | `0` |
| `match_tolerance_days` | TINYINT UNSIGNED | — | How many days apart a match may be. **Cheques clear a few days after issue** | `3` |
| `status` | ENUM | — | `Draft`, `In_Progress`, `Completed`, `Reopened`, `Abandoned` | `Completed` |
| `completed_at` / `completed_by` | DATETIME / INT | ✔ | Sign-off | `2026-10-02 11:00` |
| `reopened_at` / `reopened_by` / `reopen_reason` | DATETIME / INT / VARCHAR(500) | ✔ | If it was reopened, and why | `NULL` |
| `notes` | VARCHAR(1000) | ✔ | Reconciler's notes | `NULL` |

## 9.5 `acc_bank_statement_mapping`

### What it is for
**How to read this bank's file.** Every bank exports a different CSV layout, and rather than writing code per bank, the layout is configuration: which column is the date, which is the debit, whether debit and credit are in one column or two.

### Example row

```
name                   : "HDFC current account CSV"
file_format            : CSV
has_column_header 1 · row_no_for_header 1 · import_data_from_row_no 2
date_format            : d/m/Y
tran_date_column_no    : 1
description_column_no  : 3
reference_column_no    : 4
separate_col_for_dr_cr : 1      ← this bank uses two columns
debit_column_no  : 5   credit_column_no : 6
balance_column_no      : 7
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4` |
| `bank_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. Which account this layout is for | `142` |
| `reconciliation_id` | BIGINT UNSIGNED | ✔ | FK → `acc_bank_reconciliations`. A one-off layout for one import | `NULL` |
| `name` | VARCHAR(120) | ✔ | Friendly name | `HDFC current account CSV` |
| `file_format` | ENUM | — | `CSV`, `XLS`, `XLSX`, `MT940`, `OFX`, `Other` | `CSV` |
| `has_column_header` / `row_no_for_header` | TINYINT(1) / TINYINT | — / ✔ | Whether there is a header row, and where | `1` / `1` |
| `import_data_from_row_no` / `import_data_to_row_no` | SMALLINT UNSIGNED | ✔ | The data range. **Bank files often have summary rows at the bottom that must be skipped** | `2` / NULL |
| `date_format` | VARCHAR(30) | ✔ | PHP date format. **`d/m/Y` and `m/d/Y` look identical until the 13th of the month** | `d/m/Y` |
| `tran_date_column_no` / `value_date_column_no` | TINYINT UNSIGNED | ✔ | Which columns hold the dates | `1` / `2` |
| `description_column_no` / `reference_column_no` | TINYINT UNSIGNED | ✔ | Narration and reference columns | `3` / `4` |
| `separate_col_for_dr_cr` | TINYINT(1) | — | **`1` = two columns (debit, credit); `0` = one amount column plus a Dr/Cr indicator** | `1` |
| `debit_column_no` / `credit_column_no` | TINYINT UNSIGNED | ✔ | Used when `separate_col_for_dr_cr = 1` | `5` / `6` |
| `amount_column_no` / `amount_type_dr_cr_col_no` | TINYINT UNSIGNED | ✔ | Used when `separate_col_for_dr_cr = 0` | `NULL` |
| `balance_column_no` | TINYINT UNSIGNED | ✔ | Running balance column | `7` |
| `is_default` / `is_active` | TINYINT(1) | — | The layout to use by default | `1` / `1` |

## 9.6 `acc_bank_statement_entries`

### What it is for
The individual lines read from the bank statement, before matching.

### Example row

```
transaction_date 2026-09-12 · value_date 2026-09-12
description : "CHQ PAID 004512"
reference   : 004512      instrument_no : 004512
debit 25,000.00 · credit 0.00 · balance 1,259,000.00
row_hash      : 7d41ba…       ← SHA-256 of the raw source row
row_occurrence: 1
match_status  : Matched       matched_amount : 25,000.00
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `99120` |
| `reconciliation_id` | BIGINT UNSIGNED | — | FK → `acc_bank_reconciliations` | `220` |
| `bank_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers` | `142` |
| `transaction_date` | DATE | — | The bank's transaction date | `2026-09-12` |
| `value_date` | DATE | ✔ | When funds actually became available | `2026-09-12` |
| `description` | VARCHAR(500) | ✔ | The bank's narration | `CHQ PAID 004512` |
| `reference` / `instrument_no` | VARCHAR(255)/(50) | ✔ | Reference and cheque number, where the bank gives them | `004512` |
| `debit` / `credit` | DECIMAL(15,2) | — | **One of these is zero.** Money out / money in, from the bank's point of view | `25000.00` / `0.00` |
| `balance` | DECIMAL(18,2) | ✔ | The running balance the bank printed | `1259000.00` |
| `entry_type` | ENUM | — | `Manual` (typed) or `Imported` (from a file) | `Imported` |
| `source_row_no` | INT UNSIGNED | ✔ | Which row of the file this came from | `44` |
| `row_hash` | CHAR(64) | — | **SHA-256 of the raw source row.** Re-importing the same statement finds the duplicate instead of double-counting it | `7d41ba…` |
| `row_occurrence` | TINYINT UNSIGNED | — | **A statement can genuinely contain two identical rows** — two ₹500 cash withdrawals on the same day. This distinguishes them | `1` |
| `match_status` | ENUM | — | `Unmatched`, `Proposed`, `Matched`, `Excluded` | `Matched` |
| `matched_amount` | DECIMAL(15,2) | — | How much of this line has been matched. **A statement line may be matched against several vouchers** | `25000.00` |
| `exclude_reason` | VARCHAR(500) | ✔ | Why a line was excluded from reconciliation | `NULL` |
| `reconciler_remarks` | VARCHAR(500) | ✔ | Notes from the person doing the work | `NULL` |

> **There is no `matched_voucher_item_id` column here, deliberately.** A match can be proposed, confirmed, rejected and undone — none of which a single nullable column can express. The match is a row in `acc_bank_reconciliation_matches`.

## 9.7 `acc_bank_reconciliation_matches`

### What it is for
**The match itself, as a record with a lifecycle.** A proposed match is not a confirmed one, and an undone match should leave a trace.

### Example row

```
statement_entry_id 99120 · voucher_item_id 210441 · voucher_id 88214
amount 25,000.00
match_method   : Auto_Exact       confidence : 1.0000
score_breakdown: {"amount":1.0,"date":0.95,"reference":1.0}
status         : Confirmed        confirmed_by 14
bank_value_date: 2026-09-12       ← copied to acc_voucher_items on confirmation
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `44012` |
| `reconciliation_id` | BIGINT UNSIGNED | — | FK → `acc_bank_reconciliations` | `220` |
| `statement_entry_id` | BIGINT UNSIGNED | — | FK → `acc_bank_statement_entries`. The bank's line | `99120` |
| `voucher_item_id` | BIGINT UNSIGNED | — | FK → `acc_voucher_items`. Your line | `210441` |
| `voucher_id` | BIGINT UNSIGNED | — | FK → `acc_vouchers`. **Denormalised: cancelling a voucher releases its matches by voucher** | `88214` |
| `amount` | DECIMAL(15,2) | — | How much of the statement line this match covers | `25000.00` |
| `match_method` | ENUM | — | `Auto_Exact` (amount, date and reference agree), `Auto_Scored` (a weighted guess), `Learned` (from past confirmations), `Manual` | `Auto_Exact` |
| `confidence` | DECIMAL(5,4) | ✔ | 0.0000–1.0000 | `1.0000` |
| `score_breakdown` | JSON | ✔ | **Which components contributed, for explainability.** A reconciler who cannot see *why* a match was proposed will not trust it | `{"amount":1.0,…}` |
| `status` | ENUM | — | **`Proposed` → `Confirmed`, or `Rejected`, or `Undone`** | `Confirmed` |
| `bank_value_date` | DATE | ✔ | **Copied to `acc_voucher_items.bank_value_date` on confirmation** | `2026-09-12` |
| `confirmed_at` / `confirmed_by` | DATETIME / INT | ✔ | Who accepted it | `14` |
| `rejected_reason` | VARCHAR(500) | ✔ | Why a proposal was refused | `NULL` |
| `undone_at` / `undone_by` / `undo_reason` | DATETIME / INT / VARCHAR(500) | ✔ | **Reversing a confirmed match leaves a trace** | `NULL` |

---

# SECTION 10 — Recurring Vouchers

## 10.1 `acc_recurring_templates`

### What it is for
Transactions that repeat: monthly rent, quarterly insurance, an annual audit fee. The template holds the pattern; the lines hold the entries; the log records every run.

### Example row

```
name        : "Monthly office rent"
voucher_type_id 1 (Payment)
frequency   : Monthly     day_of_month_week : 5
month_end_policy : Same_Day
start_date 2026-04-05 · end_date 2027-03-05
occurrences_generated 6 · last_generated_date 2026-09-05 · next_due_date 2026-10-05
auto_post   : 0           requires_approval : 1
total_amount: 45,000.00
status      : Active
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `18` |
| `name` | VARCHAR(150) | — | Template name | `Monthly office rent` |
| `code` | VARCHAR(30) | ✔ | Optional short code | `RENT-OFF` |
| `voucher_type_id` | SMALLINT UNSIGNED | — | FK → `acc_voucher_types`. What kind of voucher to create | `1` |
| `campus_id` / `party_ledger_id` | SMALLINT / INT | ✔ | Dimensions carried onto each generated voucher | `1` / `310` |
| `frequency` | ENUM | — | `Daily`, `Weekly`, `Monthly`, `Quarterly`, `Half_Yearly`, `Yearly`, `Custom` | `Monthly` |
| `interval_days` | SMALLINT UNSIGNED | ✔ | **Only for `Custom`: every N days** | `NULL` |
| `day_of_month_week` | TINYINT UNSIGNED | ✔ | 1–31 for monthly/quarterly/yearly; 1–7 for weekly | `5` |
| `month_end_policy` | ENUM | — | **`Same_Day`, `Last_Day_Of_Month`, `Skip`. What to do about the 31st in February** | `Same_Day` |
| `start_date` / `end_date` | DATE | — / ✔ | The schedule window | `2026-04-05` |
| `occurrence_limit` | SMALLINT UNSIGNED | ✔ | Stop after N occurrences instead of on a date | `NULL` |
| `occurrences_generated` | SMALLINT UNSIGNED | — | How many have run | `6` |
| `last_generated_date` | DATE | ✔ | The most recent occurrence | `2026-09-05` |
| `next_due_date` | DATE | ✔ | **The scheduler's index. Recomputed after each run** | `2026-10-05` |
| `auto_post` | TINYINT(1) | — | Post automatically, or leave as a draft for review | `0` |
| `requires_approval` | TINYINT(1) | — | Route through the approval workflow | `1` |
| `narration` | TEXT | ✔ | Narration for each generated voucher | `Office rent — {month}` |
| `total_amount` | DECIMAL(15,2) | — | **Must equal Σ Dr and Σ Cr of the lines** | `45000.00` |
| `status` | ENUM | — | `Active`, `Paused`, `Completed`, `Cancelled` | `Active` |
| `paused_reason` | VARCHAR(500) | ✔ | Why it was paused | `NULL` |

### Keys & rules
`CHECK` — **exactly one of `end_date` and `occurrence_limit` must be set.** A recurring template with neither runs forever, and one with both is ambiguous.

## 10.2 `acc_recurring_template_lines`

### What it is for
The Dr/Cr pattern the template generates each time.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `77` |
| `recurring_template_id` | BIGINT UNSIGNED | — | FK → `acc_recurring_templates` | `18` |
| `sequence_no` | SMALLINT UNSIGNED | — | Line order | `1` |
| `ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers` | `520` |
| `entry_type` | ENUM | — | `Dr` or `Cr` | `Dr` |
| `amount` | DECIMAL(15,2) | — | The amount, always positive | `45000.00` |
| `narration` | VARCHAR(500) | ✔ | Line description | `Rent for the month` |
| `cost_center_id` / `cost_category_id` / `fund_id` | INT / SMALLINT / INT | ✔ | Dimensions to carry onto the generated line | `NULL` |
| `is_active` | TINYINT(1) | — | Include this line | `1` |

## 10.3 `acc_recurring_transaction_log`

### What it is for
**Every run of every template — including the runs that produced nothing.** A skipped occurrence is as important to record as a successful one: "the rent voucher was never generated in October" is exactly the thing you want to find before the auditor does.

### Example rows

| scheduled_date | occurrence_no | run_at | voucher_id | outcome | skip_reason |
|---|:---:|---|---:|---|---|
| 2026-09-05 | 6 | 2026-09-05 01:00 | 88190 | `Posted` | — |
| 2026-10-05 | 7 | 2026-10-05 01:00 | NULL | `Skipped` | Period closed |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `901` |
| `recurring_template_id` | BIGINT UNSIGNED | — | FK → `acc_recurring_templates` | `18` |
| `scheduled_date` | DATE | — | **The occurrence this run is FOR, not when it ran.** They differ when a run is late | `2026-10-05` |
| `occurrence_no` | SMALLINT UNSIGNED | — | Which occurrence in the sequence | `7` |
| `run_at` | DATETIME | — | When the job actually executed | `2026-10-05 01:00` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **NULL when the run failed or was skipped** | `NULL` |
| `voucher_date` / `total_amount` | DATE / DECIMAL(15,2) | ✔ | What was created | `NULL` |
| `outcome` | ENUM | — | `Generated` (draft created), `Posted`, `Skipped`, `Failed` | `Skipped` |
| `skip_reason` | VARCHAR(255) | ✔ | **Period closed, template paused, occurrence limit reached** | `Period closed` |
| `error_message` | TEXT | ✔ | The failure detail | `NULL` |
| `posted_at` / `posted_by` | DATETIME / INT | ✔ | If it posted | `NULL` |

---

# SECTION 11 — Fixed Assets

## 11.1 `acc_asset_categories`

### What it is for
Asset classes with their **default depreciation treatment** and the three ledgers depreciation posts to.

### Example rows

| code | name | depreciation_method | depreciation_rate | useful_life_years |
|---|---|---|---:|---:|
| `FURN` | Furniture & Fixtures | `WDV` | 10.0000 | 10 |
| `COMP` | Computers | `WDV` | 40.0000 | 3 |
| `LAND` | Land | `None` | 0.0000 | — |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `2` |
| `code` | VARCHAR(20) | — | **UK** | `COMP` |
| `name` | VARCHAR(100) | — | Class name | `Computers` |
| `parent_id` | SMALLINT UNSIGNED | ✔ | Self-FK. Sub-classes | `NULL` |
| `depreciation_method` | ENUM | — | **`SLM`** (straight line — same amount each year), **`WDV`** (written-down value — a percentage of the reducing balance), `None` | `WDV` |
| `depreciation_rate` | DECIMAL(9,4) | — | Annual percentage | `40.0000` |
| `useful_life_years` | SMALLINT UNSIGNED | ✔ | Expected life | `3` |
| `asset_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **The balance-sheet asset head** | `601` |
| `accum_dep_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **Accumulated depreciation (a contra-asset)** | `602` |
| `depreciation_expense_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **The income & expenditure charge** | `710` |
| `is_active` | TINYINT(1) | — | Selectable | `1` |

### Additional Info:

#### Comparison: WDV vs SLM
| **Feature** | **WDV (Written-Down Value)** | **SLM (Straight Line Method)** |
|---|---|---|
| **Basis of Calculation** | Calculated on reducing opening WDV each year. | Calculated on original purchase cost every year.|
| **Annual Charge** | Decreases every year. | Remains constant every year.|
| **Book Value** | Gradually approaches zero, but mathematically never reaches absolute zero. | Can reach zero (or scrap value) at end of useful life.|
| **Typical Assets Used For** | Computers, Motor Vehicles, Machinery (assets that lose value rapidly in early years). | Buildings, Furniture, Fixtures. |


**The Written-Down Value (WDV) method**
Also known as the Reducing Balance Method or Diminishing Value Method, calculates depreciation as a fixed percentage (**depreciation_rate**) applied to the remaining book value (**opening WDV**) of the asset at the start of each period, rather than on its original cost.

**As the asset's net value decreases each year, the amount of annual depreciation charged also decreases over time.**

1. General Formulas
A. Annual WDV Depreciation Formula
$$\text{Annual Depreciation Amount} = \text{Opening WDV} \times \left( \frac{\text{Depreciation Rate}}{100} \right)$$

$$\text{Closing WDV} = \text{Opening WDV} - \text{Annual Depreciation Amount}$$

For Year 1: $\text{Opening WDV} = \text{Original Purchase Cost}$
For Year $N$ ($N > 1$): $\text{Opening WDV} = \text{Closing WDV of Year } (N-1)$
B. Monthly / Pro-Rata WDV Depreciation Formula
When depreciation is run monthly or pro-rated for mid-year asset purchases (days_in_use):

$$\text{Period Depreciation Amount} = \text{Opening WDV} \times \left( \frac{\text{Depreciation Rate}}{100} \right) \times \left( \frac{\text{Days in Use}}{\text{Total Days in Financial Year}} \right)$$

2. Comprehensive Multi-Year Example
Suppose an institution buys a computer system with the following setup:

Category: COMP (Computers)
depreciation_method: 'WDV'
depreciation_rate: 40.00% (0.40)
Purchase Cost: ₹1,00,000
Year-by-Year Depreciation Schedule:
Year	Opening WDV	Calculation	Depreciation Charge	Closing WDV (Carried Forward)
Year 1	₹1,00,000.00	₹1,00,000.00 × 40%	₹40,000.00	₹60,000.00
Year 2	₹60,000.00	₹60,000.00 × 40%	₹24,000.00	₹36,000.00
Year 3	₹36,000.00	₹36,000.00 × 40%	₹14,400.00	₹21,600.00
Year 4	₹21,600.00	₹21,600.00 × 40%	₹8,640.00	₹12,960.00
3. Monthly / Periodical Example in Database (acc_depreciation_entries)
In the system, each run creates an entry in acc_depreciation_entries (Line 2148 of Dictionary_DDL_v4.7.md):

Scenario: Period 1 (30 days in September) for an asset with Opening WDV = ₹48,000.00 at 40% WDV:
$$\text{Depreciation Amount} = ₹48,000.00 \times \left( \frac{40}{100} \right) \times \left( \frac{30}{365} \right) = ₹1,578.08$$

---

## 11.2 `acc_fixed_assets`

### What it is for
The asset register: one row per asset, with what it cost, where it is, who holds it, and whether it is still in service.

### Example row

```
asset_code   : COMP-2026-014
name         : "Dell OptiPlex 7010 — Lab 2"
asset_category_id 2 (Computers)
purchase_date 2026-06-12 · put_to_use_date 2026-06-20
purchase_cost 48,000.00 · salvage_value 4,000.00
depreciation_method WDV · depreciation_rate 40.0000
location "Computer Lab 2" · custodian_user_id 31
vendor_id 88 · voucher_id 87720 · invoice_no INV-4412
serial_no CN-98221 · warranty_upto 2029-06-12
status       : Active
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `1014` |
| `asset_code` | VARCHAR(50) | — | **UK.** The tag number on the asset | `COMP-2026-014` |
| `name` / `description` | VARCHAR(150)/(500) | — / ✔ | What it is | `Dell OptiPlex 7010` |
| `asset_category_id` | SMALLINT UNSIGNED | — | FK → `acc_asset_categories` | `2` |
| `parent_asset_id` | BIGINT UNSIGNED | ✔ | Self-FK. **A capital improvement to an existing asset** — a new engine in an old bus | `NULL` |
| `purchase_date` | DATE | — | When bought | `2026-06-12` |
| `put_to_use_date` | DATE | ✔ | **When depreciation starts, which is not always the purchase date.** A machine bought in June and commissioned in August depreciates from August | `2026-06-20` |
| `purchase_cost` | DECIMAL(15,2) | — | What it cost | `48000.00` |
| `salvage_value` | DECIMAL(15,2) | — | Expected residual value. Depreciation stops here | `4000.00` |
| `depreciation_method` / `depreciation_rate` / `useful_life_years` | ENUM / DECIMAL / SMALLINT | ✔ | **Overrides the category defaults for this one asset** | `WDV` / `40.0000` |
| `location` | VARCHAR(150) | ✔ | Where it physically is | `Computer Lab 2` |
| `custodian_user_id` | INT UNSIGNED | ✔ | FK → `sys_users`. **Who is answerable for it** | `31` |
| `campus_id` / `cost_center_id` / `fund_id` | SMALLINT / INT / INT | ✔ | Dimensions. **`fund_id` matters: an asset bought from a restricted fund may have conditions attached** | `1` / `9` / `4` |
| `vendor_id` | INT UNSIGNED | ✔ | FK → `vnd_vendors` | `88` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The purchase voucher** | `87720` |
| `invoice_no` / `serial_no` | VARCHAR(100) | ✔ | Supplier invoice and manufacturer serial | `INV-4412` |
| `warranty_upto` / `insurance_policy_no` / `insured_upto` | DATE / VARCHAR(100) / DATE | ✔ | Warranty and insurance | `2029-06-12` |
| `status` | ENUM | — | `Active`, `Disposed`, `Written_Off`, `Held_For_Sale`, `Lost` | `Active` |
| `is_active` | TINYINT(1) | — | In the register | `1` |
| `notes` | VARCHAR(1000) | ✔ | Free notes | `NULL` |

> **This table holds NO `current_value` and NO `accumulated_depreciation` (R-05).** An earlier version stored both with nothing to keep them true. Net book value is **purchase cost − posted depreciation − disposal**, and `vw_fixed_asset_register` is the one place that arithmetic lives.

## 11.3 `acc_depreciation_entries`

### What it is for
One depreciation computation, per asset, per period — and the voucher that posted it.

### Example row

| fixed_asset_id | period_id | method | rate_applied | opening_wdv | depreciation_amount | closing_wdv | days_in_use | is_posted |
|---:|---:|---|---:|---:|---:|---:|---:|:---:|
| 1014 | 30 | `WDV` | 40.0000 | 48,000.00 | 1,600.00 | 46,400.00 | 30 | 1 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `55021` |
| `fixed_asset_id` | BIGINT UNSIGNED | — | FK → `acc_fixed_assets` | `1014` |
| `financial_year_id` / `period_id` | SMALLINT UNSIGNED | — | Which period | `3` / `30` |
| `depreciation_date` | DATE | — | The accounting date of the charge | `2026-09-30` |
| `method` | ENUM | — | `SLM` or `WDV` — **as applied**, not as configured | `WDV` |
| `rate_applied` | DECIMAL(9,4) | — | **FROZEN.** The rate used, so a later rate change cannot rewrite history | `40.0000` |
| `opening_wdv` | DECIMAL(15,2) | — | Written-down value at the start | `48000.00` |
| `depreciation_amount` | DECIMAL(15,2) | — | The charge for this period | `1600.00` |
| `closing_wdv` | DECIMAL(15,2) | — | Value at the end | `46400.00` |
| `days_in_use` | SMALLINT UNSIGNED | ✔ | **Pro-rata in the year of purchase or disposal.** An asset bought on the 20th does not get a full month | `30` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The depreciation journal** | `88410` |
| `is_posted` | TINYINT(1) | — | Whether the journal has been posted | `1` |
| `computed_by` | INT UNSIGNED | ✔ | FK → `sys_users` | `14` |

## 11.4 `acc_asset_disposals`

### What it is for
Selling, scrapping, donating or losing an asset — and computing the gain or loss that must be recognised.

### Example row

```
fixed_asset_id 1014 · disposal_date 2029-08-14 · disposal_type Sale
buyer_ledger_id 940
sale_proceeds  6,000.00
disposal_cost    500.00      ← removal, brokerage
cost_at_disposal        48,000.00
accumulated_depreciation 43,500.00
net_book_value           4,500.00
gain_loss_amount         1,000.00   ← 6,000 − 500 − 4,500. Positive = gain
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `221` |
| `fixed_asset_id` | BIGINT UNSIGNED | — | FK → `acc_fixed_assets` | `1014` |
| `disposal_date` | DATE | — | When | `2029-08-14` |
| `disposal_type` | ENUM | — | `Sale`, `Scrap`, `Donation`, `Loss`, `Transfer` | `Sale` |
| `buyer_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. Who bought it | `940` |
| `sale_proceeds` | DECIMAL(15,2) | — | What was received | `6000.00` |
| `disposal_cost` | DECIMAL(15,2) | — | **Removal, brokerage — costs of disposing** | `500.00` |
| `cost_at_disposal` | DECIMAL(15,2) | — | Original cost, snapshotted | `48000.00` |
| `accumulated_depreciation` | DECIMAL(15,2) | — | Total depreciation to date, snapshotted | `43500.00` |
| `net_book_value` | DECIMAL(15,2) | — | Cost less accumulated depreciation | `4500.00` |
| `gain_loss_amount` | DECIMAL(15,2) | — | **`proceeds − costs − NBV`. Negative = a loss** | `1000.00` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The disposal journal** | `92110` |
| `approved_by` / `approved_at` | INT / DATETIME | ✔ | **Disposing of an asset needs authorisation** | `3` |
| `reason` | VARCHAR(1000) | ✔ | Why it was disposed | `End of useful life` |

> The three snapshot columns exist because a disposal is a historical event. Recomputing NBV from today's depreciation table five years later would give a different answer if anything was ever corrected.

---

# SECTION 12 — Expense Claims

## 12.1 `acc_expense_claims`

### What it is for
A staff member spends their own money and claims it back. The claim is a document that gets approved, possibly reduced, and eventually paid — **two separate vouchers: one to book the liability, one to pay it.**

### Example row

```
claim_number : EXP-2026-0088
employee_id 31 · employee_ledger_id 3110
claim_date 2026-09-06 · financial_year_id 3
total_amount     : 4,200.00
approved_amount  : 3,800.00      ← one line was reduced
advance_adjusted :   1,000.00    ← an outstanding travel advance
payable_amount   : 2,800.00
status           : Paid
voucher_id 88510 (the booking) · payment_voucher_id 88602 (the payment)
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `88` |
| `claim_number` | VARCHAR(50) | — | **UK** | `EXP-2026-0088` |
| `employee_id` | INT UNSIGNED | — | FK → `sch_employees`. Who is claiming | `31` |
| `employee_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **Resolved at submission; the Cr side of the posting** | `3110` |
| `claim_date` | DATE | — | Date of the claim | `2026-09-06` |
| `financial_year_id` / `campus_id` | SMALLINT UNSIGNED | — / ✔ | Period and campus | `3` / `1` |
| `narration` | VARCHAR(500) | ✔ | What the claim is for | `Sep field trip expenses` |
| `total_amount` | DECIMAL(15,2) | — | **What was claimed** | `4200.00` |
| `approved_amount` | DECIMAL(15,2) | ✔ | **What was allowed. An approver may pass less than was claimed** — and both figures are kept | `3800.00` |
| `advance_adjusted` | DECIMAL(15,2) | — | An outstanding advance netted off | `1000.00` |
| `payable_amount` | DECIMAL(15,2) | ✔ | **What is actually paid: approved less advance** | `2800.00` |
| `status` | ENUM | — | `Draft`, `Submitted`, `Pending_Approval`, `Approved`, `Rejected`, `Paid`, `Cancelled` | `Paid` |
| `submitted_at` | DATETIME | ✔ | When it was sent for approval | `2026-09-06 17:20` |
| `approved_by` / `approved_at` | INT / DATETIME | ✔ | Who approved | `22` |
| `rejected_reason` | VARCHAR(1000) | ✔ | Why it was refused | `NULL` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The journal booking the liability** | `88510` |
| `payment_voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The payment voucher settling it** | `88602` |
| `paid_at` | DATETIME | ✔ | When the money went out | `2026-09-12 11:00` |

## 12.2 `acc_expense_claim_lines`

### What it is for
The individual expenses within a claim, each with its own receipt and its own approval outcome.

### Example rows

| sequence_no | expense_date | ledger_id | description | amount | approved_amount | line_status |
|:---:|---|---|---|---:|---:|---|
| 1 | 2026-09-04 | Travel Expenses | Bus hire, Ujjain trip | 3,000.00 | 3,000.00 | `Approved` |
| 2 | 2026-09-04 | Staff Refreshments | Lunch for 12 staff | 1,200.00 | 800.00 | **`Reduced`** |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `3301` |
| `expense_claim_id` | BIGINT UNSIGNED | — | FK → `acc_expense_claims` | `88` |
| `sequence_no` | SMALLINT UNSIGNED | — | Line order | `2` |
| `expense_date` | DATE | — | **When the money was spent**, which is not the claim date | `2026-09-04` |
| `reference_number` | VARCHAR(50) | ✔ | The receipt or bill number | `R-7741` |
| `ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. **The expense head** | `742` |
| `cost_center_id` / `cost_category_id` / `fund_id` | INT / SMALLINT / INT | ✔ | Dimensions | `9` |
| `description` | VARCHAR(255) | — | What was bought | `Lunch for 12 staff` |
| `amount` | DECIMAL(15,2) | — | The claimed amount before tax | `1200.00` |
| `tax_amount` | DECIMAL(15,2) | — | GST on the receipt | `0.00` |
| `total_amount` | DECIMAL(15,2) | — | Amount plus tax | `1200.00` |
| `approved_amount` | DECIMAL(15,2) | ✔ | **What was allowed on this line** | `800.00` |
| `line_status` | ENUM | — | **`Claimed`, `Approved`, `Reduced`, `Rejected`.** Per line, so a claim can be part-approved | `Reduced` |
| `reject_reason` | VARCHAR(500) | ✔ | Why it was cut or refused | `Above the ₹800 limit` |
| `receipt_file_name` / `media_id` | VARCHAR(255) / INT | ✔ | The receipt image | `receipt-7741.jpg` |

---

# SECTION 13 — Budgets, Interest and Credit Control

## 13.1 `acc_budgets`

### What it is for
A budget for a financial year, with **versioning**: an original budget, then a revision, then a forecast — each keeping the one before it.

### Example row

```
code      : BUD-2026-27-REV1
name      : "2026-27 Revised Budget"
budget_type : Revised     version : 2
supersedes_budget_id : 14 (the original)
revision_reason : "Enrolment 8% below plan; fee income and staffing revised."
breach_action : Warn      breach_tolerance_pct : 5.0000
status    : Active
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `19` |
| `code` | VARCHAR(30) | — | **UK** (with `version`) | `BUD-2026-27-REV1` |
| `name` | VARCHAR(150) | — | Display name | `2026-27 Revised Budget` |
| `financial_year_id` | SMALLINT UNSIGNED | — | FK → `acc_financial_years` | `3` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_campuses` | `NULL` |
| `budget_type` | ENUM | — | `Original`, `Revised`, `Forecast`, `Scenario` | `Revised` |
| `version` | SMALLINT UNSIGNED | — | Revision number | `2` |
| `supersedes_budget_id` | INT UNSIGNED | ✔ | Self-FK. **The version this replaces — which is retained, not overwritten** | `14` |
| `revision_reason` | VARCHAR(1000) | ✔ | **Why the budget changed.** A revised budget with no stated reason is just a moved goalpost | `Enrolment 8% below plan` |
| `breach_action` | ENUM | — | **`None`, `Warn`, `Approve`, `Block` — what happens when spend exceeds budget** | `Warn` |
| `breach_tolerance_pct` | DECIMAL(9,4) | — | How far over before the action fires | `5.0000` |
| `status` | ENUM | — | `Draft`, `Approved`, `Active`, `Superseded`, `Closed` | `Active` |
| `approved_by` / `approved_at` | INT / DATETIME | ✔ | Sign-off | `3` |
| `notes` | VARCHAR(1000) | ✔ | Free notes | `NULL` |

## 13.2 `acc_budget_lines`

### What it is for
The budgeted amounts. A line may be set at **ledger** level or at **account-group** level, and may be broken down by cost centre, fund, campus and month — or by none of them.

### Example rows

| ledger_id | account_group_id | cost_center_id | period_id | budgeted_amount |
|---|---|---|---:|---:|
| Salaries | — | — | NULL (whole year) | 12,000,000.00 |
| — | Indirect Expenses | Primary Section | 30 (Sep) | 340,000.00 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4412` |
| `budget_id` | INT UNSIGNED | — | FK → `acc_budgets` | `19` |
| `ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. Budget at ledger level | `701` |
| `account_group_id` | INT UNSIGNED | ✔ | FK → `acc_account_groups`. **Budget at group level, allocated down in reporting** | `NULL` |
| `cost_center_id` / `fund_id` / `campus_id` | INT / INT / SMALLINT | ✔ | Optional dimensions | `NULL` |
| `period_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_accounting_periods`. **NULL = the whole year, not split by month** | `NULL` |
| `budgeted_amount` | DECIMAL(18,2) | — | The figure | `12000000.00` |
| `notes` | VARCHAR(500) | ✔ | Assumptions behind the number | `18 teachers @ avg 55k` |
| `ledger_marker` | INT UNSIGNED | — | **GEN.** `IFNULL(ledger_id, 0)` | `701` |
| `group_marker` | INT UNSIGNED | — | **GEN.** `IFNULL(account_group_id, 0)` | `0` |
| `cc_marker` | INT UNSIGNED | — | **GEN.** `IFNULL(cost_center_id, 0)` | `0` |
| `fund_marker` | INT UNSIGNED | — | **GEN.** `IFNULL(fund_id, 0)` | `0` |
| `campus_marker` | SMALLINT UNSIGNED | — | **GEN.** `IFNULL(campus_id, 0)` | `0` |
| `period_marker` | SMALLINT UNSIGNED | — | **GEN.** `IFNULL(period_id, 0)` | `0` |

**Six NULL-safe key components.** Without them, "the salaries budget for the whole year with no cost centre" could exist many times over, and every duplicate would look correct.

### Keys & rules
`CHECK` — **at least one of `ledger_id`, `account_group_id`, `cost_center_id`, `fund_id` must be present.** A budget line against nothing at all budgets nothing.

## 13.3 `acc_interest_rules`

### What it is for
When and how to charge interest on overdue amounts — late fee payments, overdue vendor bills.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `3` |
| `code` | VARCHAR(30) | — | **UK** | `LATE_FEE_18` |
| `name` | VARCHAR(150) | — | Description | `Late fee interest — 18% pa` |
| `ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **NULL = applies to a party TYPE instead of one party** | `NULL` |
| `applies_to_party_type` | ENUM | — | `Any`, `Student`, `Parent`, `Vendor`, `Employee`, `Donor`, `Grantor`, `Other` | `Student` |
| `rate_percent` | DECIMAL(9,4) | — | Annual rate | `18.0000` |
| `basis` | ENUM | — | `Simple` or `Compound` | `Simple` |
| `compounding` | ENUM | — | `None`, `Monthly`, `Quarterly`, `Half_Yearly`, `Yearly` | `None` |
| `day_count` | ENUM | — | **`Actual_365`, `Actual_360`, `30_360`, `Actual_Actual`. Different conventions give different answers on the same facts** | `Actual_365` |
| `calculate_from` | ENUM | — | `Due_Date`, `Bill_Date`, `Transaction_Date` | `Due_Date` |
| `grace_days` | SMALLINT UNSIGNED | — | **Days after the due date before interest starts** | `7` |
| `minimum_amount` | DECIMAL(15,2) | ✔ | **Below this, do not charge.** Chasing ₹4 of interest costs more than the ₹4 | `100.00` |
| `interest_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. Where the interest posts | `815` |
| `effective_from` / `effective_to` | DATE | — / ✔ | Validity window | `2026-04-01` / NULL |
| `is_active` | TINYINT(1) | — | In force | `1` |


### Additional Info:

defines the Day Count Convention (also known as the Day Count Fraction or Accrual Basis).

It specifies how the system counts the number of days in a period and what denominator it uses for a full year when calculating interest.

1. Why day_count is Needed
The standard formula for simple interest is:

$$I = \text{Principal} \times \left( \frac{\text{Annual Rate %}}{100} \right) \times t$$

Where $t$ is the Time Factor (fraction of a year):

$$t = \frac{\text{Days in Calculation Period}}{\text{Total Days in a Year}}$$

Because different banking systems, bond markets, and statutory regulations have different legal conventions for counting days, the exact same principal amount, rate, and date range will yield different interest figures depending on the selected day_count convention.

2. Detailed Breakdown of the 4 ENUM Options
A. Actual_365 (Actual / 365 Fixed — Standard Commercial Basis)
Meaning: Uses the exact calendar number of days elapsed ($\Delta D$), divided by a fixed 365 days (even during a leap year).
Formula: $$t = \frac{\Delta D}{365}$$
Use Case: Standard consumer loans, fee late charges, and commercial banking in India and the UK.
Default: This is the default in acc_interest_rules.
B. Actual_360 (Actual / 360 — Money Market Basis)
Meaning: Uses the exact calendar number of days elapsed ($\Delta D$), but divides by 360 days.
Formula: $$t = \frac{\Delta D}{360}$$
Effect: Since $\frac{1}{360} > \frac{1}{365}$, the borrower pays slightly more interest per day ($\approx +1.39%$ more interest per year).
Use Case: Commercial bank loans, institutional credit lines, and US corporate banking.
C. 30_360 (30 / 360 — Bond Basis / German Method)
Meaning: Assumes every month has exactly 30 days and every year has 360 days ($12 \text{ months} \times 30 \text{ days} = 360$).
Formula: $$t = \frac{360(Y_2 - Y_1) + 30(M_2 - M_1) + (D_2 - D_1)}{360}$$
Effect: Ignores whether a month has 28, 29, 30, or 31 days. Provides predictable, uniform monthly interest charges.
Use Case: Corporate bonds, mortgages, institutional term loans.
D. Actual_Actual (Actual / Actual — Treasury Basis / ISDA Method)
Meaning: Uses the exact calendar number of days elapsed ($\Delta D$), divided by the actual number of days in that calendar year ($365$ in a normal year, or $366$ in a leap year).
Formula: $$t = \frac{\Delta D}{365 \text{ (or 366)}}$$
Use Case: Government treasury bills, sovereign debt, and statutory tax interest calculations.
3. Practical Numerical Comparison
Suppose a student or vendor has an overdue principal of ₹1,00,000 at an annual interest rate of 12% p.a. over a period of 90 days:

day_count Convention	Days Charged	Year Base	Calculation	Total Computed Interest
Actual_365	90	365	$₹1,00,000 \times 12% \times \frac{90}{365}$	₹2,958.90
Actual_360	90	360	$₹1,00,000 \times 12% \times \frac{90}{360}$	₹3,000.00
30_360	90 (3 × 30)	360	$₹1,00,000 \times 12% \times \frac{90}{360}$	₹3,000.00
Actual_Actual (Leap Year)	90	366	$₹1,00,000 \times 12% \times \frac{90}{366}$	₹2,950.82
4. How It Works in the Schema & Application
Rule Configuration (acc_interest_rules): The institution sets day_count = 'Actual_365' (or another option) when configuring a late fee or loan interest rule.
Computation Proposal (acc_interest_computations): When the background interest job runs, it freezes the convention into acc_interest_computations.day_count_basis, calculates days, and records interest_amount so that the exact figure can be legally defended or audited if questioned.

---


## 13.4 `acc_interest_computations`

### What it is for
Each interest calculation, **as a proposal first**. Interest is frequently waived, and the record should show it was computed, considered and waived — not that it was never computed.

### Example row

```
interest_rule_id 3 · ledger_id 4471 · bill_reference_id 55110
principal_amount 25,000.00 · rate_applied 18.0000
from_date 2026-09-22 · to_date 2026-10-09 · days 17
day_count_basis Actual_365
interest_amount 209.59
status : Waived      waive_reason : "First late payment; goodwill."
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `1120` |
| `interest_rule_id` | SMALLINT UNSIGNED | — | FK → `acc_interest_rules` | `3` |
| `ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. Who owes it | `4471` |
| `bill_reference_id` | BIGINT UNSIGNED | ✔ | FK → `acc_bill_references`. Which bill | `55110` |
| `computed_upto` | DATE | — | The as-at date of the computation | `2026-10-09` |
| `principal_amount` | DECIMAL(15,2) | — | The overdue amount | `25000.00` |
| `rate_applied` | DECIMAL(9,4) | — | **FROZEN.** The rate used | `18.0000` |
| `from_date` / `to_date` / `days` | DATE / DATE / INT | — | **The exact period charged.** Every one of these is needed to defend the figure | `2026-09-22` … `17` |
| `day_count_basis` | ENUM | — | **FROZEN.** The convention used | `Actual_365` |
| `interest_amount` | DECIMAL(15,2) | — | The computed interest | `209.59` |
| `status` | ENUM | — | **`Proposed` → `Accepted` → `Posted`, or `Waived`, or `Cancelled`** | `Waived` |
| `waive_reason` | VARCHAR(500) | ✔ | **Why it was waived.** This is the column an auditor reads | `First late payment` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. The charge, once posted | `NULL` |
| `computed_by` | INT UNSIGNED | ✔ | FK → `sys_users` | `14` |
| `bill_marker` | GEN | — | NULL-safe key component | `55110` |

## 13.5 `acc_credit_limit_overrides`

### What it is for
**Every time somebody exceeded a credit limit, and what happened.** Whether it was warned, approved or blocked, the attempt is recorded — because a limit that is silently exceeded is not a limit.

### Example row

```
ledger_id 940 (Sharma Stationers)
credit_limit       :  50,000.00     ← the limit as it stood
current_exposure   :  47,500.00     ← outstanding bills at the moment of the check
attempted_amount   :  12,000.00
excess_amount      :   9,500.00
action_taken       : Approved
approved_by 3 · reason "Annual stationery order; supplier is reliable."
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `440` |
| `ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. The party | `940` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. The voucher that triggered the check | `88710` |
| `credit_limit` | DECIMAL(15,2) | ✔ | **The limit as it stood at that moment** — it may be changed later | `50000.00` |
| `current_exposure` | DECIMAL(15,2) | — | **Outstanding bills at the moment of the check** | `47500.00` |
| `attempted_amount` | DECIMAL(15,2) | — | What was being added | `12000.00` |
| `excess_amount` | DECIMAL(15,2) | — | How far over | `9500.00` |
| `action_taken` | ENUM | — | `Warned`, `Approved`, `Blocked` | `Approved` |
| `approved_by` / `approved_at` | INT / DATETIME | ✔ | Who allowed it | `3` |
| `reason` | VARCHAR(1000) | ✔ | **The justification** | `Annual order; reliable supplier` |
| `requested_by` | INT UNSIGNED | ✔ | FK → `sys_users`. Who was trying to post | `14` |

---

# SECTION 14 — School-specific: Concessions, Donations and Grants

## 14.1 `acc_concessions`

### What it is for
Fee concessions — scholarships, sibling discounts, staff-ward waivers. Accounting-wise this matters because **a concession is either a reduced demand or a credit note, and the two are different entries.**

### The timing distinction

| `timing` | What it means | Accounting effect |
|---|---|---|
| `Before_Demand` | The discount is applied when the fee is raised | The demand is simply smaller. No separate voucher |
| `After_Demand` | The full fee was already demanded | **A credit note is posted against the existing bill** |

### Example row

```
concession_no  : CON-2026-0142
student_id 4471 · student_ledger_id 4471
concession_date 2026-09-05 · concession_type Sibling
gross_amount      25,000.00
concession_amount  5,000.00
net_amount        20,000.00     ← enforced: net = gross − concession
concession_percent 20.0000
timing            : Before_Demand
sanction_reference: "Sibling policy 2026, clause 4"
authorised_by 3
status            : Posted
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `1420` |
| `concession_no` | VARCHAR(50) | — | **UK** | `CON-2026-0142` |
| `student_id` | INT UNSIGNED | ✔ | FK → `std_students` | `4471` |
| `student_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. The student's account | `4471` |
| `financial_year_id` / `period_id` / `campus_id` | SMALLINT UNSIGNED | — / ✔ / ✔ | Period and campus | `3` / `30` / `1` |
| `concession_date` | DATE | — | When granted | `2026-09-05` |
| `concession_type` | ENUM | — | `Scholarship`, `Sibling`, `Staff_Ward`, `Merit`, `Hardship`, `Management`, **`RTE`** (Right to Education — statutory), `Alumni`, `Sports`, `Other` | `Sibling` |
| `sanction_reference` | VARCHAR(100) | ✔ | **The policy or approval this rests on.** Concessions are a fraud and favouritism risk; this is the control | `Sibling policy 2026, cl.4` |
| `authorised_by` / `authorised_at` | INT / DATETIME | ✔ | Who granted it | `3` |
| `gross_amount` | DECIMAL(15,2) | — | The full fee | `25000.00` |
| `concession_amount` | DECIMAL(15,2) | — | The discount | `5000.00` |
| `net_amount` | DECIMAL(15,2) | — | **Enforced by CHECK: `net = gross − concession`** | `20000.00` |
| `concession_percent` | DECIMAL(9,4) | ✔ | As a percentage | `20.0000` |
| `timing` | ENUM | — | **`Before_Demand` or `After_Demand`.** See the table above | `Before_Demand` |
| `bill_reference_id` | BIGINT UNSIGNED | ✔ | FK → `acc_bill_references`. The demand it relates to | `55110` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The credit note, where `timing = After_Demand`** | `NULL` |
| `concession_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **The expense or contra-income head it posts to** | `760` |
| `source_module_key` / `source_model` / `source_id` | VARCHAR / VARCHAR / BIGINT | ✔ | Where the Fees module raised it | `FEE` |
| `status` | ENUM | — | `Draft`, `Approved`, `Posted`, `Cancelled` | `Posted` |
| `cancelled_reason` / `remarks` | VARCHAR(500)/(1000) | ✔ | Explanations | `NULL` |

### Keys & rules
`CHECK` — `gross >= 0`, `concession >= 0`, `concession <= gross`, and **`net = gross − concession`**. The arithmetic cannot be wrong.

## 14.2 `acc_donations`

### What it is for
Donations received, and the **80G certificate** the donor needs for their tax return. Section 80G of the Income Tax Act lets a donor deduct their donation — but only against a properly numbered receipt from a registered institution.

### Example row

```
receipt_no      : 80G/2026-27/0212     receipt_sequence : 212
donation_date 2026-09-08
is_anonymous 0 · donor_ledger_id 880
donor_name "Meera Shah" · donor_pan ABCPS1234K
donation_nature : Corpus       fund_id 6 (Corpus Fund)
amount 100,000.00 · mode Cheque · instrument_no 771201
is_80g_eligible : 1
voucher_id 88420      ← every receipt traces to a posted voucher
status : Posted
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `212` |
| `receipt_no` | VARCHAR(50) | — | **UK** (with `financial_year_id`). **The 80G receipt number** | `80G/2026-27/0212` |
| `receipt_sequence` | INT UNSIGNED | ✔ | **The numeric part — what the gap watch reads.** A missing number in an 80G series is a serious finding, and this makes it detectable | `212` |
| `financial_year_id` / `period_id` / `campus_id` | SMALLINT UNSIGNED | — / ✔ / ✔ | Period and campus | `3` |
| `donation_date` | DATE | — | When received | `2026-09-08` |
| `is_anonymous` | TINYINT(1) | — | **Anonymous donations are permitted but have different tax treatment** | `0` |
| `donor_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **NULL only when anonymous** | `880` |
| `donor_name` / `donor_pan` / `donor_address` / `donor_email` / `donor_phone` | VARCHAR | ✔ | **Printed on the 80G certificate. PAN is mandatory above ₹2,000** | `Meera Shah` / `ABCPS1234K` |
| `donation_nature` | ENUM | — | **`Corpus`** (capital, cannot be spent), **`General`**, **`Restricted`** (a stated purpose) | `Corpus` |
| `fund_id` | INT UNSIGNED | ✔ | FK → `acc_funds`. Which fund it goes to | `6` |
| `purpose` | VARCHAR(500) | ✔ | What the donor said it was for | `Building corpus` |
| `amount` | DECIMAL(15,2) | — | The donation | `100000.00` |
| `mode` | ENUM | — | `Cash`, `Cheque`, `DD`, `NEFT`, `RTGS`, `UPI`, `Card`, **`In_Kind`**, `Other`. **Cash donations above ₹2,000 are not 80G-eligible** | `Cheque` |
| `instrument_no` | VARCHAR(50) | ✔ | Cheque or reference number | `771201` |
| `is_in_kind` | TINYINT(1) | — | Goods rather than money | `0` |
| `in_kind_description` | VARCHAR(500) | ✔ | What was given | `NULL` |
| `valuation_basis` / `valued_by` | VARCHAR(500)/(200) | ✔ | **How an in-kind donation was valued, and by whom.** Self-valued donations are a classic audit finding | `NULL` |
| `is_80g_eligible` | TINYINT(1) | — | Whether a certificate may be issued | `1` |
| `certificate_issued_at` | DATETIME | ✔ | When the 80G certificate went out | `2026-09-10 12:00` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **Every receipt traces to a posted voucher** | `88420` |
| `status` | ENUM | — | `Draft`, `Posted`, `Cancelled` | `Posted` |
| `cancelled_reason` / `remarks` | VARCHAR(500)/(1000) | ✔ | Explanations | `NULL` |

## 14.3 `acc_grants`

### What it is for
Grants received — government, CSR, foundation — with the **conditions attached** and the **utilisation certificate** that must eventually be filed. Unspent grant money is usually refundable, which makes this a liability question, not just an income one.

### Example row

```
grant_code      : CSR-TECH-2026
name            : "TechCorp CSR — Library Development"
grantor_name "TechCorp Foundation" · grantor_type CSR
fund_id 4
sanction_reference "TC/CSR/2026/118" · sanction_date 2026-04-15
sanctioned_amount 500,000.00
recognition_basis : On_Receipt
utilisation_from 2026-04-01 · utilisation_to 2027-03-31
refundable_if_unutilised : 1
utilisation_cert_due_on  : 2027-04-30
utilisation_cert_filed_on: NULL
status : Active
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `18` |
| `grant_code` | VARCHAR(30) | — | **UK** | `CSR-TECH-2026` |
| `name` | VARCHAR(200) | — | Grant title | `TechCorp CSR — Library` |
| `grantor_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. The grantor's account | `88` |
| `grantor_name` | VARCHAR(200) | — | Who gave it | `TechCorp Foundation` |
| `grantor_type` | ENUM | — | `Government`, `CSR`, `Trust`, `Foundation`, `Individual`, `International`, `Other` | `CSR` |
| `fund_id` | INT UNSIGNED | — | FK → `acc_funds`. **Mandatory: a grant always lands in a fund** | `4` |
| `sanction_reference` / `sanction_date` | VARCHAR(100) / DATE | ✔ | The sanction letter | `TC/CSR/2026/118` |
| `sanctioned_amount` | DECIMAL(15,2) | — | How much was awarded | `500000.00` |
| `recognition_basis` | ENUM | — | **`On_Sanction`** (recognise income when awarded) or **`On_Receipt`** (when the money arrives). A real accounting-policy choice with different balance-sheet effects | `On_Receipt` |
| `receivable_voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. The entry booking it as receivable, when recognised on sanction | `NULL` |
| `purpose` | VARCHAR(1000) | ✔ | What it is for | `Library development` |
| `conditions` | TEXT | ✔ | **The grantor's conditions, verbatim.** These are what the utilisation certificate is checked against | `Books and shelving only…` |
| `utilisation_from` / `utilisation_to` | DATE | ✔ | The spending window | `2026-04-01` / `2027-03-31` |
| `unutilised_liability_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **Where unspent money sits as a liability** | `315` |
| `refundable_if_unutilised` | TINYINT(1) | — | **Whether unspent money must be returned.** This decides whether it is income or a liability | `1` |
| `utilisation_cert_due_on` | DATE | ✔ | **When the certificate must be filed** | `2027-04-30` |
| `utilisation_cert_filed_on` | DATE | ✔ | When it actually was | `NULL` |
| `utilisation_cert_media_id` | INT UNSIGNED | ✔ | FK → `sys_media`. The filed certificate | `NULL` |
| `campus_id` / `cost_center_id` | SMALLINT / INT | ✔ | Dimensions | `1` |
| `status` | ENUM | — | `Sanctioned`, `Active`, `Fully_Utilised`, `Closed`, `Cancelled`, **`Lapsed`** (the window expired unspent) | `Active` |
| `notes` | VARCHAR(1000) | ✔ | Free notes | `NULL` |

---

# SECTION 15 — TDS

**TDS = Tax Deducted at Source.** When the school pays a contractor ₹1,00,000, it must withhold (say) 2% and pay that ₹2,000 to the government directly, giving the contractor ₹98,000 plus a certificate proving the ₹2,000 was paid on their behalf.

Three tables, in the order the money moves:

```
acc_tds_deductions   ── you withheld tax when you paid someone
acc_tds_payments     ── you deposited it with the government (a challan)
acc_tds_payment_allocations ── which challan covered which deduction
```

## 15.1 `acc_tds_certificates`

### What it is for
Certificates a **payee** gives **you**, allowing a lower or nil deduction. Without one you deduct at the full rate; with one you deduct at the certified rate, up to the certified limit.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `44` |
| `party_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. Whose certificate | `940` |
| `certificate_no` | VARCHAR(50) | — | **UK** (with party ledger and `section_code`) | `LDC/2026/8812` |
| `certificate_type` | ENUM | — | `Lower_Deduction`, `Nil_Deduction`, `Self_Declaration_15G`, `Self_Declaration_15H` | `Lower_Deduction` |
| `section_code` | VARCHAR(20) | — | Which section it covers | `194C` |
| `pan` | VARCHAR(15) | ✔ | The payee's PAN | `AABCS1234M` |
| `certified_rate` | DECIMAL(9,4) | — | **The reduced rate to apply** | `0.5000` |
| `valid_from` / `valid_to` | DATE | — | The validity window | `2026-04-01` / `2027-03-31` |
| `limit_amount` | DECIMAL(15,2) | ✔ | **NULL = no ceiling.** Above the limit, the normal rate resumes | `2000000.00` |
| `consumed_amount` | DECIMAL(15,2) | — | How much of the limit has been used | `340000.00` |
| `media_id` | INT UNSIGNED | ✔ | FK → `sys_media`. **The certificate itself** | `9921` |
| `status` | ENUM | — | `Active`, `Exhausted`, `Expired`, `Revoked` | `Active` |

## 15.2 `acc_tds_deductions`

### What it is for
One deduction, made from one voucher line. This is the row that eventually appears on the quarterly 26Q return and on the payee's Form 16A.

### Example row

```
voucher_id 88710 · voucher_item_id 210901 · party_ledger_id 940
financial_year_id 3 · quarter 2 · deduction_date 2026-09-12
section_code 194C · nature_of_payment "Contract work"
pan AABCS1234M · is_higher_rate_no_pan 0
gross_amount   100,000.00
taxable_amount 100,000.00
rate_applied   2.0000
tds_amount       2,000.00
net_paid_amount 98,000.00
status : Paid    paid_amount 2,000.00
certificate_issued_no "16A/2026-27/Q2/0088"
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `881` |
| `voucher_id` | BIGINT UNSIGNED | — | FK → `acc_vouchers` | `88710` |
| `voucher_item_id` | BIGINT UNSIGNED | — | FK → `acc_voucher_items`. **The party line the deduction was made from** | `210901` |
| `party_ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. The payee | `940` |
| `financial_year_id` / `period_id` | SMALLINT UNSIGNED | — / ✔ | Period | `3` / `30` |
| `quarter` | TINYINT UNSIGNED | — | **1–4. TDS returns (26Q) are filed quarterly** | `2` |
| `deduction_date` | DATE | — | When deducted | `2026-09-12` |
| `section_code` | VARCHAR(20) | — | Income Tax Act section | `194C` |
| `nature_of_payment` | VARCHAR(150) | ✔ | Description for the return | `Contract work` |
| `tax_rule_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_tax_rules`. Which rule decided the rate | `2` |
| `tds_certificate_id` | BIGINT UNSIGNED | ✔ | FK → `acc_tds_certificates`. **When a lower or nil certificate applied** | `NULL` |
| `pan` | VARCHAR(15) | ✔ | **FROZEN.** The PAN as it stood at deduction | `AABCS1234M` |
| `is_higher_rate_no_pan` | TINYINT(1) | — | **The penal rate was applied because no PAN was furnished** | `0` |
| `gross_amount` | DECIMAL(15,2) | — | The full bill | `100000.00` |
| `taxable_amount` | DECIMAL(15,2) | — | The portion TDS applies to | `100000.00` |
| `rate_applied` | DECIMAL(9,4) | — | **FROZEN** | `2.0000` |
| `tds_amount` | DECIMAL(15,2) | — | **What was withheld** | `2000.00` |
| `net_paid_amount` | DECIMAL(15,2) | — | What the payee actually received | `98000.00` |
| `cumulative_at_deduction` | DECIMAL(15,2) | ✔ | **Year-to-date total for this party at that moment.** This is what the annual threshold is tested against | `340000.00` |
| `deduct_on` | ENUM | — | `Credit` (when booked) or `Payment` (when paid) | `Credit` |
| `tds_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **The TDS Payable head it credited** | `318` |
| `status` | ENUM | — | `Deducted`, `Partly_Paid`, `Paid`, `Reversed` | `Paid` |
| `paid_amount` | DECIMAL(15,2) | — | How much has been deposited | `2000.00` |
| `certificate_issued_no` / `certificate_issued_at` | VARCHAR(50) / DATETIME | ✔ | **The Form 16A issued to the payee** | `16A/2026-27/Q2/0088` |

### Keys & rules
`CHECK` — all amounts `>= 0`, and **`paid_amount <= tds_amount`**. You cannot deposit more than you withheld.

## 15.3 `acc_tds_payments`

### What it is for
The **challan** — the deposit of withheld tax with the government. One challan usually covers many deductions.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `55` |
| `financial_year_id` / `quarter` | SMALLINT / TINYINT | — | Which return period | `3` / `2` |
| `section_code` | VARCHAR(20) | ✔ | **NULL = a challan covering several sections** | `194C` |
| `challan_no` | VARCHAR(50) | — | **The CIN — Challan Identification Number** | `0510208-2026-09-15-00412` |
| `bsr_code` | VARCHAR(20) | ✔ | The receiving bank's branch code | `0510208` |
| `challan_date` / `deposit_date` | DATE | — | When the challan was raised and when the money was deposited | `2026-09-15` |
| `tax_amount` | DECIMAL(15,2) | — | The tax itself | `18400.00` |
| `surcharge` / `cess` | DECIMAL(15,2) | — | Additional levies | `0.00` |
| `interest` | DECIMAL(15,2) | — | **Interest for late deposit** | `0.00` |
| `late_fee` | DECIMAL(15,2) | — | **Section 234E fee for a late return — ₹200 per day** | `0.00` |
| `total_amount` | DECIMAL(15,2) | — | The whole challan | `18400.00` |
| `allocated_amount` | DECIMAL(15,2) | — | How much has been matched to deductions | `18400.00` |
| `bank_ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. Which account it was paid from | `142` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **The payment voucher** | `88820` |
| `return_filed_on` / `return_acknowledgement` | DATE / VARCHAR(50) | ✔ | When the 26Q was filed and its acknowledgement number | `2026-10-28` |
| `media_id` | INT UNSIGNED | ✔ | FK → `sys_media`. **The challan receipt** | `9944` |
| `status` | ENUM | — | `Draft`, `Paid`, `Allocated`, `Filed`, `Cancelled` | `Filed` |

## 15.4 `acc_tds_payment_allocations`

### What it is for
**Which challan covered which deduction.** This is what makes the 26Q return and the Form 16A defensible: every deduction can point at the challan that paid it.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `2210` |
| `tds_payment_id` | BIGINT UNSIGNED | — | FK → `acc_tds_payments`. The challan | `55` |
| `tds_deduction_id` | BIGINT UNSIGNED | — | FK → `acc_tds_deductions`. The deduction | `881` |
| `amount` | DECIMAL(15,2) | — | How much of the challan covers this deduction | `2000.00` |
| `allocated_by` | INT UNSIGNED | ✔ | FK → `sys_users` | `14` |

---

# SECTION 16 — Cross-module Integration

**The problem this section solves.** A library fine, a transport charge, a hostel bill and a payroll run are all financial events that happen in *other* modules. Each must become a correct double-entry voucher in Accounting — without every module needing to know what a debit is.

```
acc_module_events              "the Library module can raise a late-return fine"
  └── acc_event_voucher_configs      "when it does, build a JOURNAL voucher"
        └── acc_event_voucher_line_templates   "Dr the student, Cr Library Fine Income"
acc_event_processing_log       every event received, and what became of it
acc_module_reconciliation      does the Library's total agree with ours?
acc_ledger_mappings            "fee head 12 posts to ledger 704"
```

## 16.1 `acc_ledger_mappings`

### What it is for
Telling Accounting **which ledger a source-module concept posts to**. The Fees module knows about "Term 2 Tuition"; Accounting knows about ledger 704. This table is the translation.

### Example rows

| module_key | source_type | source_id | ledger_id | description |
|---|---|---:|---|---|
| `FEE` | `FeeHead` | 12 | Tuition Fee Income | Term tuition |
| `FEE` | `FeeHead` | NULL | Miscellaneous Fee Income | **Default for any unmapped fee head** |
| `LIB` | `FineType` | 3 | Library Fine Income | Late return |
| `TPT` | `Route` | 7 | Transport Income — Route 7 | — |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `112` |
| `ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. **Where it posts** | `704` |
| `module_key` | VARCHAR(10) | — | **UK.** `glb_app_modules.key`. A plain column, not a FK — that table is in the global database | `FEE` |
| `source_type` | VARCHAR(100) | ✔ | **UK.** The kind of thing being mapped | `FeeHead` |
| `source_id` | BIGINT UNSIGNED | ✔ | **UK. NULL = a DEFAULT for the whole `source_type`** — the fallback when a specific mapping is missing | `12` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | **UK.** Different campuses may post to different ledgers | `NULL` |
| `description` | VARCHAR(255) | ✔ | What this mapping is | `Term tuition` |
| `is_active` | TINYINT(1) | — | In use | `1` |
| `source_type_marker` / `source_id_marker` / `campus_marker` | GEN | — | **Three NULL-safe key components** | `FeeHead` / `12` / `0` |

> **`source_type_marker` is `VARCHAR(100)` generated as `IFNULL(source_type,'')`** — the empty string rather than zero, because the source column is text. The principle is the same: a NULL cannot participate in a unique key.

## 16.2 `acc_module_events`

### What it is for
The catalogue of business events other modules can raise.

### Example rows

| module_key | event_code | event_name | source_model |
|---|---|---|---|
| `FEE` | `FEE_DEMAND_RAISED` | Fee demand raised | `fee_demands` |
| `FEE` | `FEE_COLLECTED` | Fee collected | `fee_transactions` |
| `LIB` | `LIB_LATE_RETURN_FINE` | Library late-return fine | `lib_fines` |
| `PAY` | `PAYROLL_FINALISED` | Payroll finalised | `pay_salary_runs` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `7` |
| `module_key` | VARCHAR(10) | — | **UK.** Which module raises it | `LIB` |
| `event_code` | VARCHAR(60) | — | **UK.** Stable event identifier | `LIB_LATE_RETURN_FINE` |
| `event_name` | VARCHAR(150) | — | Human name | `Library late-return fine` |
| `description` | TEXT | ✔ | What triggers it | `Raised when a book is returned late` |
| `source_model` | VARCHAR(100) | — | **The table that owns the triggering record** | `lib_fines` |
| `is_system` / `is_active` | TINYINT(1) | — | Shipped, enabled | `1` / `1` |

## 16.3 `acc_event_voucher_configs`

### What it is for
**What voucher to build when an event arrives**, and whether it may post automatically.

### Example row

```
module_event_id 7 (LIB_LATE_RETURN_FINE)
voucher_type_id 4 (Journal)
is_auto_post      : 1
requires_approval : 0
narration_template: "Library fine — {student_name}, {reference_no}"
max_amount        : 5,000.00      ← above this, never auto-post whatever the flags say
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `9` |
| `module_event_id` | BIGINT UNSIGNED | — | **UK.** FK → `acc_module_events` | `7` |
| `voucher_type_id` | SMALLINT UNSIGNED | — | FK → `acc_voucher_types`. What kind of voucher to build | `4` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | **UK.** Different rules per campus | `NULL` |
| `cost_center_id` / `fund_id` | INT UNSIGNED | ✔ | Dimensions applied to every generated line | `NULL` |
| `is_auto_post` | TINYINT(1) | — | **Post straight through, or leave as a draft for review** | `1` |
| `requires_approval` | TINYINT(1) | — | Route through the approval workflow | `0` |
| `narration_template` | VARCHAR(500) | ✔ | **Placeholders: `{student_name}`, `{amount}`, `{date}`, `{reference_no}`** | `Library fine — {student_name}` |
| `max_amount` | DECIMAL(15,2) | ✔ | **Above this, never auto-post — whatever the flags say.** A small automatic fine is fine; a ₹5,00,000 automatic entry is not | `5000.00` |
| `is_active` | TINYINT(1) | — | In use | `1` |
| `campus_marker` | GEN | — | NULL-safe key component | `0` |

## 16.4 `acc_event_voucher_line_templates`

### What it is for
**The Dr/Cr recipe.** This is where "a library fine means Dr the student, Cr Library Fine Income" is actually expressed — and where the amounts and ledgers are *resolved* rather than hard-coded.

### Example rows

| sequence_no | entry_type | ledger_resolver | ledger_id | amount_resolver | source_amount_field | bill_action |
|:---:|:---:|---|---|---|---|---|
| 1 | `Dr` | `student_ledger` | — | `from_source` | `fine_amount` | `New_Reference` |
| 2 | `Cr` | `fixed` | Library Fine Income | `balancing` | — | `None` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `18` |
| `event_voucher_config_id` | BIGINT UNSIGNED | — | FK → `acc_event_voucher_configs` | `9` |
| `sequence_no` | SMALLINT UNSIGNED | — | Line order | `1` |
| `entry_type` | ENUM | — | `Dr` or `Cr` | `Dr` |
| `ledger_resolver` | ENUM | — | **How to find the ledger:** `fixed` (named here), `student_ledger`, `vendor_ledger`, `employee_ledger` (look it up from the source record's party), `mapped_ledger` (via `acc_ledger_mappings`) | `student_ledger` |
| `ledger_id` | INT UNSIGNED | ✔ | FK → `acc_ledgers`. **Required when `ledger_resolver = 'fixed'`** | `NULL` |
| `ledger_mapping_type` | VARCHAR(100) | ✔ | **The `source_type` to look up when `ledger_resolver = 'mapped_ledger'`** | `NULL` |
| `amount_resolver` | ENUM | — | **How to find the amount:** `from_source` (a named field on the source record), `fixed_amount`, `from_payload`, **`balancing`** (whatever makes the voucher balance) | `from_source` |
| `source_amount_field` | VARCHAR(100) | ✔ | Which field of the source record holds the amount | `fine_amount` |
| `fixed_amount` | DECIMAL(15,2) | ✔ | Used when `amount_resolver = 'fixed_amount'` | `NULL` |
| `cost_center_id` / `fund_id` | INT UNSIGNED | ✔ | Dimensions for this line | `NULL` |
| `bill_action` | ENUM | — | **`None`, `New_Reference` (open a bill), `Against_Reference` (settle one), `Advance`, `On_Account`** | `New_Reference` |
| `narration` | VARCHAR(500) | ✔ | Line narration | `Fine for {days_late} days` |
| `is_active` | TINYINT(1) | — | Include this line | `1` |

> **`balancing` is the important resolver.** It means "make this line whatever it needs to be for Σ Dr = Σ Cr". One line per voucher may use it, and it is what guarantees R-01 even when the source amount is unexpected.

## 16.5 `acc_event_processing_log`

### What it is for
**Every event received, and what became of it.** This is the table you look at when the Library says it charged ₹4,000 of fines and Accounting shows ₹3,600.

### Example rows

| source_model | source_id | source_event_uid | voucher_id | status | skip_reason |
|---|---:|---|---:|---|---|
| `lib_fines` | 8821 | `lib-fine-8821` | 88515 | `Processed` | — |
| `lib_fines` | 8822 | `lib-fine-8822` | NULL | `Skipped` | `Zero_Amount` |
| `lib_fines` | 8823 | `lib-fine-8823` | NULL | `Failed` | — |
| `lib_fines` | 8821 | `lib-fine-8821` | — | *(rejected — duplicate uid)* | — |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `44120` |
| `module_event_id` | BIGINT UNSIGNED | — | FK → `acc_module_events` | `7` |
| `module_key` | VARCHAR(10) | — | Which module | `LIB` |
| `source_model` / `source_id` | VARCHAR(100) / BIGINT | — | The originating record | `lib_fines` / `8821` |
| `source_event_uid` | VARCHAR(100) | — | **The idempotency key. Delivering the same event twice must not create two vouchers** | `lib-fine-8821` |
| `payload_json` | JSON | ✔ | **The event as received, in full.** When something goes wrong, this is what you replay | `{"fine_amount":40,…}` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. What it produced | `88515` |
| `status` | ENUM | — | `Pending`, `Processing`, `Processed`, `Failed`, `Skipped`, **`Escalated`** | `Processed` |
| `skip_reason` | ENUM | ✔ | **`No_Config`** (nobody set up a rule), `Inactive_Event`, `Duplicate`, `Zero_Amount`, `Period_Closed`, `Other` | `NULL` |
| `error_message` | TEXT | ✔ | The failure detail | `NULL` |
| `retry_count` / `next_retry_at` | TINYINT / DATETIME | — / ✔ | **Retries are bounded.** After the limit it escalates rather than looping | `0` |
| `escalated_at` / `escalated_to` | DATETIME / INT | ✔ | **Who was told when automation gave up** | `NULL` |
| `received_at` / `processed_at` | DATETIME | — / ✔ | Timing | `2026-09-09 14:02` |

> **`No_Config` is the most useful skip reason.** It means the Library raised an event that nobody ever told Accounting how to handle — a silent revenue leak that this column makes visible.

## 16.6 `acc_module_reconciliation`

### What it is for
**Does the source module's total agree with what Accounting posted?** Run per module, per period, per metric. A difference here is the earliest warning that an integration is dropping events.

### Example rows

| module_key | period_id | metric | source_total | posted_total | difference | status |
|---|---:|---|---:|---:|---:|---|
| `FEE` | 30 | `FEE_COLLECTED` | 4,820,000.00 | 4,820,000.00 | 0.00 | `Matched` |
| `LIB` | 30 | `LIB_FINES` | 4,000.00 | 3,600.00 | **400.00** | `Investigating` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `881` |
| `module_key` | VARCHAR(10) | — | **UK.** Which module | `LIB` |
| `financial_year_id` / `period_id` | SMALLINT UNSIGNED | — | **UK.** Which period | `3` / `30` |
| `reconciliation_date` | DATE | — | As-at date | `2026-09-30` |
| `metric` | VARCHAR(60) | — | **UK.** What is being compared | `LIB_FINES` |
| `source_total` | DECIMAL(18,2) | — | **What the module says** | `4000.00` |
| `posted_total` | DECIMAL(18,2) | — | **What Accounting says** | `3600.00` |
| `difference` | DECIMAL(18,2) | — | The gap | `400.00` |
| `source_count` / `posted_count` | INT UNSIGNED | — | Record counts on each side | `40` / `36` |
| `unposted_count` | INT UNSIGNED | — | **Events received but never posted** | `4` |
| `failed_count` | INT UNSIGNED | — | Events that errored | `0` |
| `difference_detail` | JSON | ✔ | **Which specific records differ.** "₹400 short" is not actionable; a list of four fine ids is | `{"unposted":[8822,…]}` |
| `status` | ENUM | — | `Matched`, `Difference`, `Investigating`, **`Explained`** (a known and accepted difference), `Failed` | `Investigating` |
| `explanation` | VARCHAR(1000) | ✔ | Why the difference is acceptable, when it is | `NULL` |
| `reviewed_by` / `reviewed_at` | INT / DATETIME | ✔ | Who looked at it | `NULL` |
| `run_at` | DATETIME | — | When the comparison ran | `2026-10-01 02:00` |

---

# SECTION 17 — Tally Export

Many Indian schools' auditors work in Tally. These two tables let the books be handed over in a form the auditor already uses.

## 17.1 `acc_tally_export_logs`

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `44` |
| `export_type` | ENUM | — | `Ledgers`, `Groups`, `Vouchers`, `Cost_Centres`, `All` | `Vouchers` |
| `export_format` | ENUM | — | `XML` (Tally's native), `CSV`, `Excel` | `XML` |
| `financial_year_id` | SMALLINT UNSIGNED | ✔ | FK → `acc_financial_years` | `3` |
| `start_date` / `end_date` | DATE | ✔ | The period exported | `2026-04-01` / `2026-09-30` |
| `file_name` | VARCHAR(255) | — | The generated file | `tally-2026-h1.xml` |
| `media_id` | INT UNSIGNED | ✔ | FK → `sys_media` | `9950` |
| `record_count` | INT UNSIGNED | ✔ | How many records went | `8412` |
| `status` | ENUM | — | `Queued`, `Running`, `Completed`, `Failed`, `Cancelled` | `Completed` |
| `error_log` | TEXT | ✔ | Failure detail | `NULL` |
| `exported_by` | INT UNSIGNED | ✔ | FK → `sys_users` | `14` |
| `started_at` / `completed_at` | DATETIME | ✔ | Timing | `2026-10-02 15:00` |

## 17.2 `acc_tally_ledger_mappings`

### What it is for
Prime-AI's ledger names and Tally's are not identical. This holds the translation, so an export lands in the auditor's existing chart of accounts rather than creating duplicates.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `310` |
| `ledger_id` | INT UNSIGNED | — | FK → `acc_ledgers`. Our ledger | `142` |
| `tally_ledger_name` | VARCHAR(200) | — | **What Tally calls it** | `HDFC Bank A/c 5521` |
| `tally_group_name` | VARCHAR(200) | ✔ | The Tally group it belongs under | `Bank Accounts` |
| `tally_alias` | VARCHAR(200) | ✔ | Tally alias | `HDFC` |
| `mapping_type` | ENUM | — | `Auto` (matched by name) or `Manual` (a person decided) | `Manual` |
| `sync_direction` | ENUM | — | `Export_Only`, `Import_Only`, `Bidirectional` | `Export_Only` |
| `last_synced_at` | DATETIME | ✔ | Last successful sync | `2026-10-02 15:04` |
| `is_active` | TINYINT(1) | — | In use | `1` |

---

# SECTION 18 — Control: Audit, Exceptions, Assertions and Settings

## 18.1 `acc_audit_logs`

### What it is for
**Who did what, when, and why.** An earlier version of this module had no audit table at all, which made the whole thing unauditable. Every material change lands here.

### Example row

```
entity_type acc_vouchers · entity_id 88214 · voucher_id 88214
action     : Cancelled
old_values : {"status":"Posted"}
new_values : {"status":"Cancelled"}
changed_fields : "status,cancelled_reason,cancelled_by"
reason     : "Cheque 004512 returned unpaid — bank memo attached."
actor_type User · user_id 14 · user_name "Anita Verma"
ip_address 192.168.1.42 · request_id req_88f21a
occurred_at 2026-09-14 10:22:07.418
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `992104` |
| `entity_type` | VARCHAR(64) | — | **The table name** | `acc_vouchers` |
| `entity_id` | BIGINT UNSIGNED | — | The row id | `88214` |
| `voucher_id` | BIGINT UNSIGNED | ✔ | FK → `acc_vouchers`. **Denormalised, so "show me everything that happened to this voucher" is one indexed lookup** | `88214` |
| `action` | ENUM | — | `Created`, `Updated`, `Deleted`, `Restored`, `Submitted`, `Approved`, `Rejected`, `Posted`, `Cancelled`, `Reversed`, `Reconciled`, `Unreconciled`, `Closed`, `Reopened`, `Allocated`, `Deallocated`, `Written_Off`, `Exported`, `Imported`, **`Viewed_Sensitive`**, **`Permission_Overridden`**, `Rebuilt` | `Cancelled` |
| `old_values` / `new_values` | JSON | ✔ | Before and after | `{"status":"Posted"}` |
| `changed_fields` | VARCHAR(1000) | ✔ | **CSV, so you can filter on a field without parsing the JSON** | `status,cancelled_reason` |
| `reason` | VARCHAR(1000) | ✔ | **Required for cancel, reverse, reopen, waive and override.** These are the actions an auditor asks about | `Cheque returned unpaid` |
| `actor_type` | ENUM | — | `User`, `System`, `Job`, `Integration`, `Migration`. **So automation is distinguishable from a person** | `User` |
| `user_id` | INT UNSIGNED | ✔ | FK → `sys_users` | `14` |
| `user_name` | VARCHAR(150) | ✔ | **Denormalised on purpose: the audit must read correctly even after the user account is deleted** | `Anita Verma` |
| `impersonated_by` | INT UNSIGNED | ✔ | **When a support user acted as someone else.** Without this, an impersonated action looks like the user's own | `NULL` |
| `ip_address` | VARCHAR(45) | ✔ | **45 characters, because IPv6** | `192.168.1.42` |
| `user_agent` | VARCHAR(255) | ✔ | Browser signature | `Mozilla/5.0 …` |
| `request_id` | VARCHAR(64) | ✔ | **Correlates every row written by one request.** One click that writes nine audit rows is one story, not nine | `req_88f21a` |
| `module_key` | VARCHAR(10) | ✔ | Which module the action came from | `ACC` |
| `financial_year_id` / `period_id` | SMALLINT UNSIGNED | ✔ | Period context | `3` / `30` |
| `occurred_at` | DATETIME(3) | — | **Millisecond precision — ordering within a single transaction matters** | `2026-09-14 10:22:07.418` |

## 18.2 `acc_exception_rules`

### What it is for
The definitions of things that should not be true: negative cash, aged suspense balances, stale cheques, unapproved vouchers.

### Example rows

| code | name | category | severity | blocks_period_close | run_frequency |
|---|---|---|---|:---:|---|
| `NEGATIVE_CASH` | Cash balance is negative | `Balance` | `Critical` | 1 | `Realtime` |
| `AGED_SUSPENSE` | Suspense entries over 30 days | `Review` | `High` | 1 | `Daily` |
| `STALE_CHEQUE` | Cheques uncleared over 90 days | `Reconciliation` | `Warning` | 0 | `Daily` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `4` |
| `code` | VARCHAR(50) | — | **UK** | `AGED_SUSPENSE` |
| `name` | VARCHAR(200) | — | What it checks | `Suspense entries over 30 days` |
| `category` | ENUM | — | `Balance`, `Ageing`, `Reconciliation`, `Approval`, `Compliance`, `Data_Quality`, **`Fraud_Risk`**, `Budget`, `Numbering` | `Review` |
| `severity` | ENUM | — | `Info`, `Warning`, `High`, `Critical` | `High` |
| `checker_key` | VARCHAR(100) | — | Which service check produces it | `suspense.aged` |
| `threshold_amount` / `threshold_days` / `threshold_percent` | DECIMAL / SMALLINT / DECIMAL | ✔ | **The thresholds are configuration, not code** | `NULL` / `30` / NULL |
| `blocks_period_close` | TINYINT(1) | — | **An open exception of this rule stops the month closing** | `1` |
| `allow_acknowledge` | TINYINT(1) | — | May somebody accept it and move on | `1` |
| `acknowledge_valid_days` | SMALLINT UNSIGNED | ✔ | **An acknowledgement EXPIRES.** Otherwise "we know about it" becomes permanent and the exception is never fixed | `30` |
| `notify_role_slug` | VARCHAR(60) | ✔ | Who is told | `accounts-manager` |
| `run_frequency` | ENUM | — | `Realtime`, `Hourly`, `Daily`, `Weekly`, `On_Close` | `Daily` |
| `is_active` | TINYINT(1) | — | In force | `1` |

## 18.3 `acc_exceptions`

### What it is for
The exceptions actually found. **Note `detection_count` and `Recurred`** — an exception that keeps coming back is a different problem from one that appeared once.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `7712` |
| `exception_rule_id` | SMALLINT UNSIGNED | — | FK → `acc_exception_rules` | `4` |
| `rule_code` | VARCHAR(50) | — | **Denormalised: the dashboard never joins** | `AGED_SUSPENSE` |
| `severity` | ENUM | — | Copied from the rule, so a later rule change does not rewrite history | `High` |
| `entity_type` / `entity_id` | VARCHAR(64) / BIGINT | — | What is wrong | `acc_ledgers` / `999` |
| `entity_label` | VARCHAR(255) | ✔ | **Human-readable: `PAY-0042`, `Sundry Debtors`, `Ravi Kumar`.** An id alone is not actionable | `Suspense Account` |
| `ledger_id` / `voucher_id` | INT / BIGINT | ✔ | Direct links where relevant | `999` |
| `financial_year_id` / `period_id` / `campus_id` | SMALLINT / SMALLINT / SMALLINT | ✔ | Context | `3` / `30` |
| `amount` / `age_days` | DECIMAL(18,2) / INT | ✔ | The measured figures | `18400.00` / `44` |
| `detail` | JSON | ✔ | The offending records | `{"voucher_ids":[…]}` |
| `message` | VARCHAR(1000) | — | What to tell the user | `₹18,400 in suspense for 44 days` |
| `status` | ENUM | — | `Open`, `Acknowledged`, `Resolved`, `Suppressed`, **`Recurred`** | `Open` |
| `first_detected_at` / `last_detected_at` | DATETIME | — | **The span it has persisted** | `2026-08-26` / `2026-10-09` |
| `detection_count` | INT UNSIGNED | — | **How many runs have found it.** 44 consecutive detections is a different conversation from 1 | `44` |
| `acknowledged_by` / `acknowledged_at` / `acknowledge_reason` | INT / DATETIME / VARCHAR(1000) | ✔ | Who accepted it and why | `NULL` |
| `acknowledge_expires_at` | DATETIME | ✔ | **When the acknowledgement lapses and it reopens** | `NULL` |
| `resolved_by` / `resolved_at` / `resolution_note` | INT / DATETIME / VARCHAR(1000) | ✔ | How it was actually fixed | `NULL` |

## 18.4 `acc_assertion_results`

### What it is for

**The schema checking itself.** Every night, a set of assertions runs: does every posted voucher balance? Does the trial balance total to zero? Does rebuilding the balance cache change anything? A failure here means something is wrong that no user has noticed.

### Example rows

| assertion_code | scope | result | checked_count | failure_count | expected_value | actual_value | variance |
|---|---|---|---:|---:|---:|---:|---:|
| `DR_EQUALS_CR` | `Global` | `Pass` | 8,412 | 0 | 0.00 | 0.00 | 0.00 |
| `TB_BALANCES` | `Financial_Year` | `Pass` | 1 | 0 | 0.00 | 0.00 | 0.00 |
| `CACHE_MATCHES_REBUILD` | `Period` | **`Fail`** | 1,204 | 3 | 0.00 | 4,800.00 | **4,800.00** |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `55210` |
| `assertion_code` | VARCHAR(50) | — | Which check | `CACHE_MATCHES_REBUILD` |
| `assertion_name` | VARCHAR(200) | — | What it asserts | `Balance cache equals a full rebuild` |
| `scope` | ENUM | — | `Global`, `Financial_Year`, `Period`, `Ledger`, `Fund`, `Party`, `Asset`, `Voucher` | `Period` |
| `financial_year_id` / `period_id` | SMALLINT UNSIGNED | ✔ | What was checked | `3` / `30` |
| `result` | ENUM | — | `Pass`, `Fail`, `Error`, `Skipped` | `Fail` |
| `checked_count` | INT UNSIGNED | — | Rows examined | `1204` |
| `failure_count` | INT UNSIGNED | — | Rows that failed | `3` |
| `expected_value` / `actual_value` / `variance` | DECIMAL(18,2) | ✔ | **The three numbers that make a failure diagnosable** | `0.00` / `4800.00` / `4800.00` |
| `failure_detail` | JSON | ✔ | Which specific rows failed | `{"ledger_ids":[142,…]}` |
| `exception_id` | BIGINT UNSIGNED | ✔ | FK → `acc_exceptions`. **The exception raised, where it failed** | `7713` |
| `duration_ms` | INT UNSIGNED | ✔ | How long the check took | `4820` |
| `run_at` | DATETIME | — | When | `2026-10-09 23:30` |

> **This table is how R-05 is kept honest.** A cache is only trustworthy if something independently verifies it, and this is that something.

## 18.5 `acc_settings`

### What it is for
Module configuration, typed. The value lives in whichever `value_*` column matches `value_type` — one column per type, rather than everything as a string that has to be parsed.

### Example rows

| setting_key | setting_group | value_type | value | is_school_editable | requires_four_eyes |
|---|---|---|---|:---:|:---:|
| `allow_backdated_posting` | `Posting` | Boolean | `value_boolean = 0` | 1 | 1 |
| `backdate_limit_days` | `Posting` | Integer | `value_integer = 7` | 1 | 0 |
| `auto_reconcile_exact` | `Bank` | Boolean | `value_boolean = 1` | 1 | 0 |
| `ageing_buckets` | `Bill_Wise` | Json | `value_json = [30,60,90]` | 1 | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK** | `12` |
| `setting_key` | VARCHAR(80) | — | **UK** (with `campus_marker`) | `backdate_limit_days` |
| `setting_group` | ENUM | — | `Posting`, `Numbering`, `Period`, `Bill_Wise`, `Bank`, `Tax`, `Fund`, `Budget`, `Approval`, `Reporting`, `Integration`, `Security` | `Posting` |
| `value_type` | ENUM | — | `String`, `Integer`, `Decimal`, `Boolean`, `Date`, `Json`. **Says which column below holds the value** | `Integer` |
| `value_string` / `value_integer` / `value_decimal` / `value_boolean` / `value_date` / `value_json` | various | ✔ | **One typed column per type.** No parsing, no "is `'0'` true?" | `value_integer = 7` |
| `default_value` | VARCHAR(500) | ✔ | The shipped default, so you can see what was changed | `7` |
| `description` | VARCHAR(500) | ✔ | What the setting does | `Days a voucher may be backdated` |
| `is_school_editable` | TINYINT(1) | — | May the school change it, or is it fixed by the product | `1` |
| `requires_four_eyes` | TINYINT(1) | — | **Two people must agree to change it.** For settings that weaken a control, such as allowing backdated posting | `0` |
| `campus_id` | SMALLINT UNSIGNED | ✔ | **UK. NULL = applies school-wide** | `NULL` |
| `campus_marker` | GEN | — | NULL-safe key component | `0` |

---

# Views — 22 read-only reports

Every view derives from `acc_voucher_items` filtered to `voucher_status = 'Posted'` (R-02) and, where relevant, from the cache tables.

## Financial statements

| View | Answers |
|---|---|
| `vw_ledger_balances` | **The balance of every ledger right now**, computed live from posted lines |
| `vw_trial_balance` | **Do all debits equal all credits?** The proof that the books balance |
| `vw_balance_sheet` | Assets, liabilities and equity as at a date |
| `vw_income_expenditure` | Income less expenditure for a period — the non-profit equivalent of a P&L |

## Transaction listings

| View | Answers |
|---|---|
| `vw_day_book` | **Every voucher on a given day**, in entry order. The accountant's daily read |
| `vw_ledger_statement` | Every movement on one ledger, with a running balance |
| `vw_voucher_audit_trail` | The full history of one voucher: entered, submitted, approved, posted, cancelled |

## Receivables and payables

| View | Answers |
|---|---|
| `vw_party_outstanding` | **Who owes us, and who we owe** |
| `vw_receivable_ageing` | Outstanding fees by age bucket: 0-30, 31-60, 61-90, 90+ |
| `vw_payable_ageing` | The same for vendor bills |
| `vw_bill_reconciliation` | Bill by bill: original, allocated, written off, outstanding |

## Dimensions

| View | Answers |
|---|---|
| `vw_cost_center_summary` | **What did each section, activity or department cost?** |
| `vw_fund_utilisation` | **How much of each restricted fund is spent, and how much remains** |
| `vw_budget_variance` | Budget vs actual, by ledger, cost centre and period |

## Banking

| View | Answers |
|---|---|
| `vw_bank_reconciliation_status` | Which accounts are reconciled, to which date, with what difference |
| `vw_cheque_register` | Every cheque and where it is in its lifecycle |

## Statutory

| View | Answers |
|---|---|
| `vw_tds_summary` | TDS deducted, deposited and outstanding, by quarter and section |
| `vw_tax_summary` | GST input and output by period |
| `vw_fixed_asset_register` | **The asset register with net block computed** — cost less depreciation less disposal. This is the one place that arithmetic lives |

## Control

| View | Answers |
|---|---|
| `vw_accounting_exceptions` | Open exceptions by severity, with age |
| `vw_module_reconciliation` | Where Accounting and the source modules disagree |
| `vw_period_close_status` | **What is still blocking this month from closing** |

---

# Quick reference

## Where does each business question live?

| Question | Tables |
|---|---|
| What is this ledger's balance? | `acc_ledger_period_balances` (cache) or `vw_ledger_balances` (live) |
| Do the books balance? | `vw_trial_balance` — and `acc_assertion_results` checks it nightly |
| Which fees are unpaid, and how overdue? | `acc_bill_references` + `acc_bill_reference_balances` |
| Who approved this payment? | `acc_voucher_approvals` |
| Why was this voucher cancelled? | `acc_vouchers.cancelled_reason` + `acc_audit_logs` |
| Has this cheque cleared? | `acc_cheque_transactions.status` |
| Does the bank agree with us? | `acc_bank_reconciliations.difference` |
| **How much of the CSR grant is left?** | `acc_fund_balances` |
| What did the Primary Section cost? | `acc_voucher_item_cost_centers` → `vw_cost_center_summary` |
| What is this asset worth now? | `vw_fixed_asset_register` — **never a stored column** |
| Did we deposit the TDS we withheld? | `acc_tds_deductions` + `acc_tds_payment_allocations` |
| Why didn't the library fine post? | `acc_event_processing_log.skip_reason` |
| Can we close September? | `acc_period_close_checklist` → `vw_period_close_status` |
| What is wrong right now? | `acc_exceptions` |
| Who changed this, and why? | `acc_audit_logs` |

## Table count by section

| Section | Tables |
|---|---:|
| 1 · Organisation, currency and time | 5 |
| 2 · Chart of accounts | 2 |
| 3 · Dimensions | 3 |
| 4 · Voucher configuration | 4 |
| 5 · Tax configuration | 3 |
| 6 · Transactions | 9 |
| 7 · Bill-wise | 2 |
| 8 · Balances | 6 |
| 9 · Banking | 7 |
| 10 · Recurring | 3 |
| 11 · Fixed assets | 4 |
| 12 · Expense claims | 2 |
| 13 · Budgets, interest, credit | 5 |
| 14 · School-specific | 3 |
| 15 · TDS | 4 |
| 16 · Cross-module integration | 6 |
| 17 · Tally export | 2 |
| 18 · Control | 5 |
| **Total** | **75 tables, 22 views** |

## Seven things that are easy to get wrong

| # | Trap | The rule |
|---|---|---|
| 1 | Writing to any `*_marker` column | **They are GENERATED.** MySQL maintains them |
| 2 | Looking for `acc_ledgers.closing_balance` | **It does not exist (R-05).** Use `acc_ledger_period_balances` or `vw_ledger_balances` |
| 3 | Looking for `acc_fixed_assets.current_value` | **Also does not exist.** Use `vw_fixed_asset_register` |
| 4 | Counting draft or provisional vouchers in a report | **Only `voucher_status = 'Posted'` counts (R-02)** |
| 5 | Editing a posted voucher | **Impossible by design (R-03).** Post a reversal and record it in `acc_voucher_references` |
| 6 | Storing a negative amount to mean a credit | **`amount` is always positive.** Direction is `entry_type` = `Dr` or `Cr` |
| 7 | Trusting a cache that disagrees with the voucher items | **The voucher items always win.** Run `acc:rebuild-balances` |

## The five caches, and who owns them

| Table | Owner | Rebuild | Verified by |
|---|---|---|---|
| `acc_ledger_period_balances` | `PostingService` | `acc:rebuild-balances` | Nightly assertion |
| `acc_fund_balances` | `PostingService` | `acc:rebuild-balances` | Nightly assertion |
| `acc_bill_reference_balances` | `AllocationService` | `acc:rebuild-balances` | Nightly assertion |
| `acc_period_closing_balances` | Period close | **Never — it is a snapshot, not a cache** | — |
| `acc_opening_balances` | Migration / carry-forward | **Never — corrections supersede** | — |

---

## What changed in v4.6

| | |
|---|---|
| **Schema change** | The generated column `del_marker` was dropped from all **30** tables that carried it, and removed from the **42** unique keys that ended with it. Every key keeps its name and its remaining columns, so no index was added or renamed. |
| **Not changed** | `deleted_at` and soft delete · every `*_marker` NULL-safe column · every table, view, column, FK and CHECK. The table and view counts are unchanged at **75** and **22**. |
| **Why** | A code or a name that a deleted row already holds should not be handed to a new row. Carrying an extra stored column and a wider index in 30 tables to permit that was cost without benefit. |

### Tables that lost `del_marker` (30)

`acc_campuses` · `acc_account_groups` · `acc_ledgers` · `acc_cost_categories` · `acc_cost_centers` · `acc_funds` · `acc_voucher_category` · `acc_voucher_types` · `acc_tax_types` · `acc_tax_rules` · `acc_bill_references` · `acc_opening_balances` · `acc_cheque_registers` · `acc_bank_reconciliations` · `acc_recurring_templates` · `acc_asset_categories` · `acc_fixed_assets` · `acc_expense_claims` · `acc_budgets` · `acc_interest_rules` · `acc_concessions` · `acc_donations` · `acc_grants` · `acc_tds_certificates` · `acc_tds_payments` · `acc_ledger_mappings` · `acc_module_events` · `acc_event_voucher_configs` · `acc_tally_ledger_mappings` · `acc_exception_rules`

`acc_donations` carried the column but no key used it; it was dropped as dead weight.

### What the application team must do

| # | Change | Where |
|---|---|---|
| 1 | Catch **ER_DUP_ENTRY (1062)** on create and offer **Restore the deleted record** instead of insert | Every master listed under *Codes are retired for good* |
| 2 | A re-admitted student, re-hired employee or re-engaged vendor **restores** their existing ledger | `acc_ledgers` |
| 3 | A BR-OPEN-04 correction **updates in place**; it can no longer be a second superseding row | `acc_opening_balances` |
| 4 | Delete-and-re-enter of the same document becomes restore | `acc_bank_reconciliations` · `acc_cheque_registers` · `acc_tds_payments` · `acc_bill_references` · `acc_tds_certificates` |
| 5 | Drop `del_marker` from any model `$fillable`, `$casts`, factory or seeder that names it | Laravel models for the 30 tables above |

### Migrating an existing v4.5 database

Find the rows the narrower key will reject **before** altering anything — per table, per key:

```sql
SELECT code, COUNT(*) FROM acc_account_groups GROUP BY code HAVING COUNT(*) > 1;
```

Resolve each collision (hard-delete or re-code the dead row), then per table:

```sql
ALTER TABLE acc_account_groups DROP INDEX uq_acc_ag_code, DROP INDEX uq_acc_ag_name;
ALTER TABLE acc_account_groups DROP COLUMN del_marker;
ALTER TABLE acc_account_groups ADD UNIQUE KEY uq_acc_ag_code (code),
                               ADD UNIQUE KEY uq_acc_ag_name (name);
```

**Order matters:** the index must be dropped before the generated column it references.

---

**End of `Dictionary_DDL_v4.6.md`**
