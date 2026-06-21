# Financial Years — Business Requirements

## Business Need
Schools operate on a fixed financial year (April 1 to March 31 for Indian schools). Once a year ends, the books must be "closed" — no further changes allowed in that period. Closing balances must carry forward to the new year. This ensures proper financial reporting, audit compliance, and prevents accidental edits to completed periods.

## Business Objectives
- Define fiscal year periods with clear start and end dates
- Lock a completed financial year to prevent any voucher operations
- Carry forward closing balances as opening balances for the next year
- Allow only authorized users to unlock a locked year (audit requirement)
- Support creating next year's records in advance

## User Stories

**As School Accountant,** I want to:
- Create a new financial year record (e.g., "2026-27") before it starts
- Set the start date (April 1) and end date (March 31)
- View all financial years with their lock status
- Know which year is currently active for transaction entry

**As School Admin / Bursar,** I want to:
- Lock a completed financial year so no one can modify its data
- Review that all vouchers in the year are approved before locking
- Verify the auto-calculated closing balances before finalizing the lock
- Ensure unlocking a locked year requires my explicit authorization

## Key Business Rules

**Locking Behavior**
- A locked financial year blocks ALL voucher create, edit, and delete operations
- Locking is one-way by default — unlocking requires Super Admin authorization (audit safeguard)
- On lock, the system computes closing balances for all ledgers
- Closing balance of FY(n) = Opening balance of FY(n+1) (carried forward automatically)

**Date Validation**
- Every voucher must fall within its assigned financial year's date range
- No overlapping financial years allowed — date ranges must not conflict

**Lifecycle**
- One FY is typically active at a time
- Schools create the next FY record in advance (before April 1)
- Locked years should normally stay locked (audit compliance)

## Business Workflow

1. **Setup:** School seeds the current FY (e.g., 2026-27, April 1 to March 31)
2. **Daily Use:** All vouchers are created within the active FY
3. **Year-End:** Accountant reviews all vouchers for completeness
4. **Lock:** Admin initiates "Lock Year" — system validates all vouchers are approved, computes closing balances, locks the FY
5. **Next Year:** New FY is created with opening balances pre-filled from the locked year

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Creates new FY records, manages day-to-day within FY |
| School Admin / Bursar | Authorizes year-end lock, unlocks if absolutely needed |
| Auditor | Requires clean year-end closure, no post-closure edits |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access — create, lock, unlock financial years |
| Accountant | View FY records, know active FY |
| Auditor | View FY status and lock history |
