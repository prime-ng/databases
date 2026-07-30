# Account Group — Business Requirements

## What This Screen Does

The Account Group screen manages the hierarchical classification tree for ledgers. Each group can have a parent group (creating a self-referencing hierarchy), a fixed nature type, and a system-protected flag. The grouping structure follows standard accounting conventions (Assets, Liabilities, Income, Expenses) and is used to organize ledgers for reporting.

## When This Screen Is Used

- **During initial accounting setup** when configuring the chart of accounts hierarchy.
- **When adding new sub-groups** to organize new ledgers under appropriate categories.
- **When restructuring the chart of accounts** by modifying parent-child group relationships.

## Key Fields

- **Name** (string 100) — Group display name
- **Parent Group** (FK → self, nullable) — Parent group for hierarchy
- **Nature** (enum: Asset/Liability/Income/Expense) — Fixed accounting nature
- **Nature Type** (enum: Current/NonCurrent/Direct/Indirect/Null) — Sub-classification
- **Is System** (boolean) — System-protected group (cannot be deleted)
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Self-Referencing Hierarchy:**
A group's parent is another group via `parent_id` FK to the same table. The hierarchy depth is managed at the application layer. A group cannot be its own parent.

**System Group Protection:**
Groups with `is_system = true` cannot be deleted or force-deleted. These are the foundational accounting groups.

**Nature Immutability:**
The `nature` field is fixed on creation and cannot be changed via the edit form (the field is read-only). This prevents accounting classification mismatches.

**Delete Guard:**
A group cannot be deleted if it has child groups (`children()->exists()`) or ledgers assigned (`ledgers()->exists()`).

**Unique Name:**
Group name must be unique across all groups (enforced by UNIQUE key).

**Model Helpers:**
- `isSystem(): bool` — returns `is_system`
- `children(): HasMany` — self-referencing children query
- `ledgers(): HasMany` — ledgers in this group

## Workflow

1. User navigates to Accounting → Setup Masters → Account Groups.
2. Table shows hierarchical list with Name, Parent Group, Nature, Nature Type, System badge, Active toggle, Actions.
3. User creates a group by selecting parent, nature, nature type, and name.
4. System groups are marked with a shield icon and cannot be deleted.
5. Deleting a group checks for child groups and ledgers — blocked if found.

## Requirements

- MUST display at `/accounting/account-group?tab=account-groups` as paginated table
- MUST authorize via `tenant.accounting.account-group.*` policy gates
- MUST support self-referencing parent group hierarchy
- MUST enforce nature immutability after creation
- MUST prevent deletion of system groups (is_system = true)
- MUST prevent deletion if child groups exist
- MUST prevent deletion if ledgers exist under the group
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
