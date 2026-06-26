# Bank Reconciliation — Business Requirements

## Business Need
The school's bank account balance as per the bank's records often differs from what's recorded in the school's books due to cheques in transit, bank charges, interest credits, or unrecorded transactions. Bank reconciliation matches the school's recorded transactions against the bank statement to identify and resolve these differences. It is a statutory requirement for audits.

## Business Objectives
- Import bank statements (CSV/MT940 format) for each bank account
- Automatically match bank transactions to voucher entries by amount, date, and reference
- Allow manual matching/unmatching for exceptions
- Generate a Bank Reconciliation Statement (BRS) showing reconciling items
- Track reconciliation history per bank ledger per period

## User Stories

**As School Accountant,** I want to:
- Start a new reconciliation session for a specific bank account
- Upload the bank statement file (CSV or MT940 format)
- View imported bank transactions with date, description, debit/credit, and running balance
- See which transactions auto-matched to our recorded voucher items
- Manually match an unmatched bank entry to a voucher item (or vice versa)
- Unmatch an incorrectly matched pair
- Add a note explaining each reconciling item
- Complete the reconciliation and mark it as done
- View the Bank Reconciliation Statement report
- Reconcile the same bank account for different statement periods

## Key Business Rules

**Eligibility**
- Only bank ledgers marked "Allow Reconciliation" appear in reconciliation screens
- Each reconciliation session covers one bank account for one statement period

**Matching Strategies (Auto-Match)**
The system tries three strategies in order:
1. **Exact Match:** Amount + Date + Reference Number all match a voucher item
2. **Amount Match:** Amount matches (fuzzy date range, ±3 days)
3. **Reference Match:** Bank reference matches cheque number or receipt number

**Reconciliation Status**
- **In Progress:** Currently working on this reconciliation
- **Completed:** All differences resolved, BRS generated

**Validation**
- The system verifies: `closing_balance = opening_balance + sum(credits) − sum(debits)`
- Unmatched items appear as reconciling items in the BRS report

## Business Workflow

1. **Start:** Select a bank ledger and statement date. Create a reconciliation session.
2. **Import:** Upload the bank statement CSV file. System parses it into individual entries.
3. **Auto-Match:** System automatically matches bank entries to voucher items.
4. **Manual Review:** Accountant reviews unmatched entries and manually matches them.
5. **Resolve:** Any remaining differences are investigated and noted.
6. **Complete:** Mark reconciliation as complete. BRS report is generated.

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Primary user — performs reconciliation monthly |
| School Admin / Bursar | Reviews BRS report for management |
| Auditor | Requires reconciled bank statements for audit |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access to reconciliation |
| Accountant | Create/perform reconciliation |
| Auditor | View reconciliation reports only |
