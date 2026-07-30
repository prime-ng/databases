# Ledger — Business Requirements

## What This Screen Does

The Ledger screen manages the chart of accounts — the individual account heads that transactions are posted against. Each ledger belongs to an account group and has a configurable opening balance, optional bank/cash details (name, account number, IFSC, branch, UPI), encrypted fields (bank account number), and optional linked entities (employee, vendor, student, etc.).

## When This Screen Is Used

- **During accounting setup** when creating all required account ledgers.
- **When adding new ledgers** for new bank accounts, new expense/revenue heads.
- **When configuring bank details** for bank/cash ledgers used in reconciliation and payment processing.
- **When setting opening balances** at the start of a new financial year.

## Key Fields

- **Name** (string 100) — Ledger display name
- **Account Group** (FK → acc_account_groups) — Parent group (determines nature)
- **Opening Balance** (decimal 15,2, default 0) — Initial balance
- **Opening Balance Type** (enum: Debit/Credit) — Sign of opening balance
- **Is Bank or Cash** (boolean) — Whether this is a bank/cash account
- **Bank Account Number** (string, encrypted) — Encrypted via Laravel encryption
- **Bank Name, Branch, IFSC, UPI** — Bank details
- **Linked Entity Type** (nullable polymorph) — employee, vendor, student, etc.
- **Linked Entity ID** (nullable integer)
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Bank/Cash Details:**
When `is_bank_or_cash = true`, bank details fields become required. Bank account number is encrypted at the model layer using Laravel's `encrypt` cast.

**Opening Balance:**
Balance type determines whether the opening_balance is debit (+) or credit (-). On creation, the opening balance sets the initial ledger balance.

**Linked Entities:**
A ledger can optionally be linked to an employee, vendor, or student via polymorphic relationship. This enables person-specific ledgers.

**Unique Name:**
Ledger name must be unique (enforced by UNIQUE key composite with deleted_at).

**JSON API for Create/Edit:**
The create and edit forms load account groups as a JSON API endpoint (`/accounting/ledger/get-groups`) filtered by nature compatibility.

**Custom Cross-Field Validations:**
- IFSC format validation (alphanumeric, 11 chars)
- UPI format validation
- Bank account number min length

**Delete Guard:**
A ledger cannot be deleted if it has voucher items (transactions) referencing it.

**Model Helpers:**
- `isBankOrCash(): bool`
- `getDecryptedBankAccountAttribute(): string` — decrypts bank account number

## Workflow

1. User navigates to Accounting → Setup Masters → Ledger.
2. Table shows: Name, Group, Opening Balance (with type), Bank/Cash badge, Active toggle, Actions.
3. User creates a ledger: selects group via JSON API, optionally sets opening balance, optionally fills bank details if bank/cash.
4. Bank account number is encrypted on save and decrypted on read.
5. Edit allows modifying all fields including group reassignment.
6. Delete checks for existing voucher items — blocked if transactions exist.

## Requirements

- MUST display at `/accounting/ledger?tab=ledgers` as paginated table
- MUST authorize via `tenant.accounting.ledger.*` policy gates
- MUST load account groups via JSON API (`getGroups` endpoint) filtered by nature
- MUST encrypt bank account number using Laravel encryption
- MUST require bank details only when `is_bank_or_cash = true`
- MUST validate IFSC format (11 alphanumeric chars)
- MUST support linked entities via polymorphic relationship
- MUST prevent deletion if voucher items reference the ledger
- MUST support opening balance with debit/credit type
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
