# Bank Reconciliation — Business Requirements

## What This Screen Does

The Bank Reconciliation screen matches bank statement lines against system vouchers to identify cleared, uncleared, and missing transactions. It supports CSV/XLSX import of bank statements, auto-matching by amount/date/reference, manual matching, and reconciliation completion.

## When This Screen Is Used

- **Monthly/quarterly** when reconciling bank accounts against bank statements.
- **When verifying** that all bank transactions are correctly recorded in the system.
- **When identifying discrepancies** between bank and book balances.

## Key Fields

**Bank Reconciliation (Header):**
- **Bank Ledger** (FK → acc_ledgers, bank/cash) — The bank account being reconciled
- **Financial Year** (FK → acc_financial_years, nullable)
- **Statement Date** (date) — As-of date for reconciliation
- **Opening Balance** (decimal 15,2) — Bank statement opening balance
- **Closing Balance** (decimal 15,2) — Bank statement closing balance
- **Reconciled Balance** (decimal 15,2) — System-computed reconciled balance
- **Status** (enum: draft/in_progress/completed) — Current state
- **Is Completed** (boolean) — Whether reconciliation is final
- **Completed By / Completed At** — Completion trail

**Bank Statement Entry (Import):**
- **Transaction Date** (date)
- **Description** (string)
- **Cheque/Reference Number** (string, nullable)
- **Debit Amount** (decimal 15,2)
- **Credit Amount** (decimal 15,2)
- **Matched Voucher ID** (FK → acc_vouchers, nullable)
- **Match Status** (enum: unmatched/matched/manual/auto/difference)

## Business Rules

**CSV/XLSX Import:**
Bank statements are imported in two supported formats (CSV and XLSX). System auto-detects column mapping based on header row or configurable mapping. Import validation catches format errors before processing.

**Auto-Matching:**
The system attempts to auto-match statement lines to vouchers based on:
- Amount match (debit/credit)
- Date proximity (within configured tolerance)
- Reference/cheque number match

**Manual Matching:**
Unmatched statement lines or vouchers can be manually paired by the user. Manual matches override auto-match suggestions.

**Unmatching:**
A matched pair can be unmatched, reverting both to unmatched status. Previously matched vouchers become available for re-matching.

**Completion Guard:**
Once `is_completed = true`, the reconciliation is locked. No further matching or changes allowed. Must uncheck `is_completed` to modify.

**Critical Status Type Mismatch:**
The DDL defines `status` as TINYINT with FK to a status table, but the code treats `status` as a string. This mismatch causes data integrity issues.

**Critical is_completed Issue:**
The `is_completed` column in DDL may not exist or may be misconfigured, causing the completion guard to fail silently.

**Critical Broken Property Guard:**
The `is_completed` property guard in the controller may be referencing a non-existent DB column or have incorrect logic, allowing modifications on completed reconciliations.

## Workflow

1. User navigates to Accounting → Transactions → Bank Reconciliation.
2. User creates a new reconciliation: selects bank ledger, statement period, enters opening/closing balance.
3. User imports bank statement (CSV/XLSX). System parses and displays statement lines.
4. Auto-matching runs: matched items shown with green indicator.
5. User manually matches remaining items or unmatch auto-matched pairs.
6. User reviews the reconciliation. When satisfied, marks as `is_completed = true`.
7. Completed reconciliation is locked. Report viewable but not editable.

## Requirements

- MUST display at `/accounting/bank-reconciliation?tab=bank-reconciliation` as paginated table
- MUST authorize via `tenant.accounting.bank-reconciliation.*` policy gates
- MUST support CSV and XLSX bank statement import with auto-format detection
- MUST support auto-matching by amount, date, and reference number
- MUST support manual matching and unmatching of individual entries
- MUST lock reconciliation when marked as completed
- MUST prevent edits after completion (is_completed guard)
- MUST show summary: opening balance, closing balance, reconciled balance, difference
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
- **CRITICAL:** Resolve status type mismatch (DDL TINYINT vs code string)
- **CRITICAL:** Fix `is_completed` column and property guard
