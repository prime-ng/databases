# Voucher Type — Business Requirements

## What This Screen Does

The Voucher Type screen manages the types of financial vouchers available in the system (e.g., Payment, Receipt, Contra, Journal, Sales, Purchase, Credit Note, Debit Note). Each voucher type defines numbering rules (prefix, starting number), category, and whether it is system-protected.

## When This Screen Is Used

- **During accounting setup** when configuring which voucher types are available.
- **When adding custom voucher types** for specific business transactions.
- **When configuring voucher numbering** (prefix patterns, starting numbers, auto-numbering format).

## Key Fields

- **Name** (string 100) — Voucher type display name
- **Category** (enum: Payment/Receipt/Contra/Journal/Sales/Purchase/CreditNote/DebitNote)
- **Prefix** (string 20, nullable) — Number prefix (e.g., "PMT-", "RCT-")
- **Starting Number** (integer, default 1) — First number in the sequence
- **Auto Numbering** (boolean) — Enable auto-generation of voucher numbers
- **Number Format** (string, nullable) — Format pattern for generated numbers
- **Is System** (boolean) — System-protected, cannot be deleted
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Category Determination:**
The `category` field defines the accounting nature of the voucher type and is used by downstream logic to determine debit/credit rules, ledger selection, and reporting.

**Prefix/Numbering:**
When `auto_numbering = true`, vouchers are auto-numbered as `{prefix}{number}` format. The number increments per year. Starting number defaults to 1.

**System Voucher Types:**
System types (`is_system = true`) cannot be deleted or force-deleted. These are the base types required for system operation.

**Delete Guard:**
A voucher type cannot be deleted if it has existing vouchers using this type.

**Critical Model/DDL Mismatch:**
The model uses `category` as a string field but the DDL has `voucher_category_id` as a FK integer to a `acc_voucher_categories` table. This mismatch requires resolution — either migrate the model to use the FK or add the category column to DDL.

**Soft Delete:**
Uses SoftDeletes. Trash view, restore, and forceDelete routes available.

## Workflow

1. User navigates to Accounting → Setup Masters → Voucher Type.
2. Table shows: Name, Category badge, Prefix, Starting Number, Auto-numbering toggle, System badge, Active toggle, Actions.
3. User creates a voucher type with category, prefix, starting number, and auto-numbering preference.
4. System types show a lock icon and cannot be deleted.
5. Edit allows modifying prefix, starting number, and auto-numbering but NOT the category (once set).

## Requirements

- MUST display at `/accounting/voucher-type?tab=voucher-types` as paginated table
- MUST authorize via `tenant.accounting.voucher-type.*` policy gates
- MUST generate voucher numbers as `{prefix}{number}` when auto_numbering = true
- MUST enforce category selection from defined enum (Payment/Receipt/Contra/Journal/Sales/Purchase/CreditNote/DebitNote)
- MUST prevent deletion of system voucher types
- MUST prevent deletion if vouchers exist using this type
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
- **CRITICAL:** Must resolve model/DDL mismatch — `category` string vs `voucher_category_id` FK
