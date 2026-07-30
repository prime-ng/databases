# Recurring Template — Business Requirements

## What This Screen Does

The Recurring Template screen manages templates for vouchers that repeat on a schedule (e.g., monthly rent, quarterly taxes, annual subscriptions). Each template defines the voucher structure, schedule frequency, and next run date. A "Post Now" action creates and immediately posts a voucher from the template.

## When This Screen Is Used

- **When setting up recurring payments** like rent, loan payments, subscriptions.
- **For periodic journal entries** like monthly depreciation, amortization.
- **When scheduling quarterly or annual tax provisions.**

## Key Fields

- **Template Name** (string 100) — Human-readable template name
- **Voucher Type** (FK → acc_voucher_types) — Type of voucher to generate
- **Financial Year** (FK → acc_financial_years, nullable)
- **Total Amount** (decimal 15,2) — Voucher total
- **Frequency** (enum: Daily/Weekly/Monthly/Quarterly/HalfYearly/Yearly) — Schedule interval
- **Start Date** (date) — When recurring series begins
- **End Date** (date, nullable) — When series ends (null = no end)
- **Next Run Date** (date) — Next scheduled posting date
- **Is Active** (boolean)
- **Narration** (text, nullable)

**Template Items (Child):**
- **Ledger ID** (FK → acc_ledgers)
- **Debit Amount** (decimal 15,2)
- **Credit Amount** (decimal 15,2)
- **Narration** (text, nullable)

## Business Rules

**Frequency Scheduling:**
The next run date advances based on the frequency setting after each post. Daily = +1 day, Weekly = +7 days, Monthly = +1 month, Quarterly = +3 months, etc.

**Post Now:**
The "Post Now" action creates a new voucher from the template's structure, posts it immediately, and updates `next_run_date`. This happens within a DB transaction.

**Date Progression:**
Posting a voucher via recurring template should advance `next_run_date` by the configured frequency interval. If the next run date exceeds `end_date`, the template should be marked as completed or inactive.

**Template Deactivation:**
A template can be deactivated (is_active = false) to stop automatic scheduling without deleting it.

**Critical DDL Gap:**
The `next_run_date` column used in code is missing from the DDL. This will cause a SQL error on any Post Now action.

## Workflow

1. User navigates to Accounting → Transactions → Recurring Templates.
2. Table shows: Template Name, Voucher Type, Frequency, Next Run Date, Status, Actions.
3. User creates template with voucher structure, frequency, and date range.
4. "Post Now" creates and posts a voucher, advances next_run_date.
5. Template can be edited, deactivated, or deleted.

## Requirements

- MUST display at `/accounting/recurring-template?tab=recurring-templates` as paginated table
- MUST authorize via `tenant.accounting.recurring-template.*` policy gates
- MUST support frequency scheduling (Daily through Yearly)
- MUST advance next_run_date by frequency interval on Post Now
- MUST create and post voucher atomically within a DB transaction on Post Now
- MUST stop scheduling when next_run_date exceeds end_date
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
- **CRITICAL:** Must add `next_run_date` column to DDL (currently exists only in code)
