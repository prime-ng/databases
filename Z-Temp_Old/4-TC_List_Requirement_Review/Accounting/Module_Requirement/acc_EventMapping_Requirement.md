# Event Mapping — Business Requirements

## What This Screen Does

The Event Mapping screen defines the accounting rules for system events. Each event mapping specifies how a given business event (e.g., fee collection, salary processing) should generate accounting entries — which ledgers to debit/credit, in what amounts, and under what conditions. This is the core automation engine that translates business transactions into double-entry accounting entries.

## When This Screen Is Used

- **During accounting setup** when configuring auto-accounting for each business event.
- **When adding new events** from modules like Fee, Payroll, Vendor, etc.
- **When modifying accounting rules** for existing events to change ledger mappings or amount formulas.

## Key Fields

**Event Mapping (Primary):**
- **Event Type** (string, unique) — System event identifier (e.g., `fee.collection`, `salary.processing`)
- **Event Name** (string) — Human-readable event name
- **Is Active** (boolean)

**Event Mapping Lines (Nested):**
- **Line Type** (enum: Debit/Credit) — Debit or credit line
- **Ledger ID** (FK → acc_ledgers, RESTRICT) — The ledger to post to
- **Amount Type** (enum: Fixed/Percentage/Balance/Formula) — How amount is determined
- **Amount Value** (decimal) — Fixed value, percentage, or formula parameter
- **Reference Type** (string, nullable) — Source reference field name
- **Sort Order** (integer) — Line ordering

**Event Mapping Resolvers (Nested):**
- **Resolver Type** (enum: Amount/Balance/Description/Reference) — What the resolver resolves
- **Resolver Class** (string) — PHP class that resolves the value
- **Configuration** (JSON, nullable) — Resolver-specific config

## Business Rules

**3-Table Nested CRUD:**
Event Mapping is the parent. Event Mapping Lines and Resolvers are children. The create/edit form uses a single form with nested sub-forms for lines and resolvers. The controller handles all three tables on one store/update request.

**System Event Protection:**
System event mappings (`event_type` matching specific system events) cannot be deleted — only deactivated via `is_active = false`. This prevents accidental removal of critical accounting automation.

**Amount Resolution:**
Five amount/balance resolvers are supported via `$ledgerResolvers` and `$amountResolvers` arrays in the controller:
- Fixed amount
- Percentage of reference amount
- Balance from linked ledger
- Formula-based calculation
- Reference field copy

**DB Transaction Atomicity:**
All three tables (mapping, lines, resolvers) are created/updated within a single DB transaction. If any child insertion fails, the entire operation rolls back.

**Ledger FK RESTRICT:**
Event mapping lines have a RESTRICT FK on `ledger_id` → `acc_ledgers`. A ledger cannot be deleted if it is referenced by any event mapping line.

**Delete Guard:**
Only non-system event mappings can be deleted. System mappings show a delete error flash.

## Workflow

1. User navigates to Accounting → Setup Masters → Event Mapping.
2. Table shows: Event Type, Event Name, Active toggle, Actions.
3. User creates a mapping: enters event type/name, adds debit/credit lines (selecting ledgers and amount types), optionally configures resolvers.
4. System mappings cannot be deleted — only deactivated.
5. Lines and resolvers cascade on delete of parent mapping.

## Requirements

- MUST display at `/accounting/event-mapping?tab=event-mappings` as paginated table
- MUST authorize via `tenant.accounting.event-mapping.*` policy gates
- MUST support nested CRUD (mapping + lines + resolvers) in a single transaction
- MUST support system event protection — system mappings cannot be deleted
- MUST support 5 amount resolution types: Fixed, Percentage, Balance, Formula, Reference
- MUST enforce DB transaction atomicity for all 3 tables
- MUST validate at least one debit and one credit line
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
