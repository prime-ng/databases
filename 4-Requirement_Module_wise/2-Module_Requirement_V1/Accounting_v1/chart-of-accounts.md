# Chart of Accounts — Business Requirements

## Business Need
Schools need a structured way to organize all their financial accounts — income sources (tuition fees, transport fees, donations), expense categories (salaries, electricity, maintenance), assets (bank accounts, buildings, furniture), and liabilities (loans, payables). Without this structure, transactions are recorded inconsistently, financial reports become unreliable, and audit compliance is difficult.

## Business Objectives
- Organize all financial accounts in a Tally-inspired hierarchy (28 standard groups adapted for Indian schools)
- Allow schools to create custom sub-groups and ledgers as needed
- Link fee heads, transport routes, payroll items, and vendor accounts to the correct accounting ledgers automatically
- Track opening balances for each account at the start of each financial year
- Protect system accounts (seeded groups/ledgers) from accidental deletion

## User Stories

**As School Accountant,** I want to:
- View the full Chart of Accounts as an expandable hierarchy (Groups → Ledgers)
- Create new account groups (e.g., "Transport Fee Income" under "Income") and sub-groups
- Create individual ledgers under the appropriate group (e.g., a "Cash A/c" under "Current Assets")
- Set opening balances for ledgers at the start of the financial year
- Configure bank account details (bank name, account number, IFSC) for bank ledgers
- Link a fee head to an income ledger so fee collections automatically post to the correct account
- Mark ledgers as cash or bank accounts for cash/bank book reports

**As School Admin / Bursar,** I want to:
- Review the full account structure at a glance
- Ensure all income and expense categories are properly classified
- Freeze system accounts from modification or deletion

**As StudentFee Module,** I want to:
- Look up which income ledger a particular fee head maps to when posting fee receipts

## Key Business Rules

**Group Hierarchy**
- Account groups form a parent-child tree (e.g., "Current Assets" → "Bank Accounts" → "SBI Current A/c")
- Groups marked as "sub-ledger" allow direct posting (like Tally's sub-ledger concept)
- Parent groups (non-sub-ledger) are for organization only — ledgers must go under child groups
- 28 Tally standard groups + 4 school-specific groups are seeded as system-protected

**Ledger Rules**
- Each ledger belongs to exactly one account group
- Ledgers can optionally be linked to a student, employee, or vendor for auto-accounting
- Bank ledgers store branch details (bank name, account number, IFSC)
- Only ledgers marked for reconciliation appear in bank reconciliation screens
- System ledgers (Cash A/c, P&L A/c) are protected from deletion

**Cross-Module Mappings**
- Ledger mappings bridge external modules to accounting: Fee heads → Income Ledgers, Transport routes → Transport Income Ledgers, Vendor accounts → Creditor Ledgers
- One mapping per combination (ledger, module, entity type, entity ID)
- Mappings are optional — a ledger can exist without module linkage

**Balance Computation**
- Ledger balance is always computed at query time (never stored): `opening_balance ± sum of all voucher transactions`
- Computation is scoped within a financial year

## Business Workflow

1. **Setup Phase:** Accountant seeds the system with standard groups (28 Tally groups). School-specific groups are added as needed.
2. **Ledger Creation:** Individual ledgers are created under appropriate groups with opening balances.
3. **Mapping Phase:** Fee heads, transport routes, vendor accounts are mapped to their corresponding ledgers.
4. **Daily Use:** Voucher entries reference ledgers. Module events auto-post to mapped ledgers.
5. **Reporting:** Trial Balance, P&L, Balance Sheet are generated from ledger transaction data.

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Primary user — sets up and maintains the Chart of Accounts |
| School Admin / Bursar | Oversees account structure, approves new accounts |
| StudentFee Module | Consumes ledger mappings for fee receipt posting |
| Transport Module | Consumes ledger mappings for transport fee income |
| Auditor | Needs well-structured, auditable account hierarchy |
| CA / Tax Consultant | Requires proper classification for tax filings |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access — create/edit/delete groups and ledgers |
| Accountant | Full access to groups and ledgers |
| Cashier | View-only access |
| Auditor | View-only access |
