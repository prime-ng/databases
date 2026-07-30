# Tally Mapping — Business Requirements

## What This Screen Does

The Tally Mapping screen maps Tally ERP ledger names to system ledgers. Each mapping links a `tally_ledger_name` (as used in Tally) to a local ledger, with optional JSON `mapping_details` for additional configuration. This enables bidirectional data exchange with Tally.

## When This Screen Is Used

- **During Tally integration setup** when configuring which Tally ledgers map to which system ledgers.
- **When adding new Tally ledger mappings** for new accounts created in Tally.
- **When updating mappings** due to ledger name changes in Tally.

## Key Fields

- **Tally Ledger Name** (string 100) — Ledger name as it appears in Tally ERP
- **Ledger** (FK → acc_ledgers, SET NULL) — Mapped system ledger
- **Mapping Details** (JSON, nullable) — Additional configuration data
- **Is Active** (boolean)
- **Tenant** (FK → tenants, CASCADE) — Tenant scope
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Tenant Scoping:**
Tally mappings are tenant-scoped via `tenant_id`. Each tenant has its own set of Tally mappings.

**SET NULL FK:**
If the system ledger is deleted, the mapping's `ledger_id` is set to NULL. The mapping structure (tally_ledger_name) is preserved.

**CASCADE on Tenant Delete:**
If a tenant is deleted, all its Tally mappings are automatically deleted via CASCADE FK.

**JSON Mapping Details:**
The `mapping_details` field stores flexible configuration as JSON (e.g., GST rate overrides, custom fields). The model casts this to array.

**No Unique Constraint:**
There is no DB-level unique constraint on `tally_ledger_name`. Uniqueness is enforced only at the application layer (per tenant).

## Workflow

1. User navigates to Accounting → Assets & Integration → Tally Mappings.
2. Table shows: Tally Ledger Name, Mapped Ledger, Active toggle, Actions.
3. User creates a mapping: enters Tally ledger name, selects system ledger, optionally adds mapping details JSON.
4. Mappings can be updated, deactivated, or soft-deleted.

## Requirements

- MUST display at `/accounting/tally-mapping?tab=tally-mappings` as paginated table
- MUST authorize via `tenant.accounting.tally-mapping.*` policy gates
- MUST scope mappings per tenant (tenant_id)
- MUST allow mapping without a linked ledger (ledger_id = NULL)
- MUST support JSON mapping_details field
- MUST cascade delete when tenant is deleted
- MUST enforce unique tally_ledger_name per tenant at application layer
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
- **SHOULD** add DB-level unique constraint on tally_ledger_name per tenant
