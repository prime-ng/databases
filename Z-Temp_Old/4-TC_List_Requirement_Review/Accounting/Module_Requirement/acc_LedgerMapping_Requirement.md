# Ledger Mapping — Business Requirements

## What This Screen Does

The Ledger Mapping screen manages the mapping of system accounting types to specific ledgers. Each mapping type (e.g., "Accounts Receivable," "Accounts Payable," "Cash in Hand") is linked to a target ledger. The `is_cash_ledger` flag distinguishes cash vs non-cash mappings. These mappings are consumed by event-driven accounting automation.

## When This Screen Is Used

- **During accounting setup** when configuring which ledgers correspond to standard accounting types.
- **When adding new ledger mappings** for new automation rules.
- **When re-mapping** accounting types to different ledgers.

## Key Fields

- **Mapping Type** (string 50, unique) — System identifier for the mapping
- **Mapping Label** (string 100) — Human-readable label
- **Ledger** (FK → acc_ledgers, SET NULL) — Mapped ledger
- **Is Cash Ledger** (boolean) — Whether this is a cash/bank mapping
- **Description** (text, nullable)
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Unique Mapping Type:**
Each mapping type must be unique. This is the key used by automation logic to look up which ledger to use for a given accounting purpose.

**Optional Ledger:**
A mapping can exist without a linked ledger (ledger_id = NULL). This allows creating the mapping structure before ledger assignment.

**SET NULL FK:**
If the referenced ledger is deleted, the mapping's `ledger_id` is set to NULL (not deleted). This preserves the mapping structure.

**No System Guard:**
All mappings can be edited and deleted regardless of whether they are referenced by automation processes.

## Workflow

1. User navigates to Accounting → Assets & Integration → Ledger Mappings.
2. Table shows: Mapping Type, Label, Ledger, Cash Ledger badge, Active toggle, Actions.
3. User creates a mapping: enters type, label, optionally selects ledger, sets cash flag.
4. Mapping can be linked/unlinked from a ledger at any time.

## Requirements

- MUST display at `/accounting/ledger-mapping?tab=ledger-mappings` as paginated table
- MUST authorize via `tenant.accounting.ledger-mapping.*` policy gates
- MUST enforce unique mapping type
- MUST allow mapping without a linked ledger (ledger_id = NULL)
- MUST support is_cash_ledger flag
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
