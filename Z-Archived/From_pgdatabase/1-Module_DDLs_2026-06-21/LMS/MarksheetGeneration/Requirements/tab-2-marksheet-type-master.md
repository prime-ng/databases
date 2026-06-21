# MarksheetGeneration Tab 2: Marksheet Type Master

This screen lets the school admin define the types of marksheets the school issues. Each marksheet type represents a distinct report card format — for example, a Unit Test result sheet, a Term-1 Report Card, an Annual Report Card, or a Pre-Board marksheet. These types are then referenced when creating config templates and schedules.

---

## How It Works

The screen shows a simple table listing all existing marksheet types. Each row displays the type code, display name, optional description, and display order. The admin can add, edit, or delete marksheet types directly from this table. A typical school might have 3 to 8 types, but the system does not limit the number.

When creating a new type, the admin enters a machine-readable code (e.g. UNIT_TEST, TERM1, ANNUAL) and a human-readable name (e.g. "Term-1 Report Card"). The code must be unique across all types for the school. The display_order field controls how the types appear in dropdown menus throughout the module.

Deleting a marksheet type is restricted if any config templates or schedules are already linked to it. The system prevents accidental deletion of types that are in use.

---

## Important Business Rules

- The code field is unique across all marksheet types for the school. Duplicate codes are rejected.
- Codes may only contain uppercase letters, numbers, and underscores.
- A marksheet type cannot be deleted if any config templates reference it. The system shows a warning listing the templates that depend on it.
- Deactivated types (is_active = 0) are hidden from dropdowns in other screens but remain in the database for historical integrity.
- At least one marksheet type must exist before config templates can be created.

---

## Database Columns & Behavior

### msh_marksheet_types
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `code` — Unique machine-readable identifier. VARCHAR(30). UNIQUE index. E.g. UNIT_TEST, TERM1, ANNUAL.
- `name` — Display name shown in dropdowns. VARCHAR(100). E.g. "Term-1 Report Card".
- `description` — Optional description. VARCHAR(255), nullable.
- `display_order` — Sort order in UI dropdowns. SMALLINT UNSIGNED, default 1.
- `is_active` — Soft toggle for deactivation. TINYINT(1), default 1. Indexed.
- `created_by` — FK to sys_users. INT UNSIGNED.
- `updated_by` — FK to sys_users. INT UNSIGNED, nullable.
- `created_at` — TIMESTAMP, nullable.
- `updated_at` — TIMESTAMP, nullable.
- `deleted_at` — Soft delete timestamp. TIMESTAMP, nullable.

---

## Deep Analysis

### Business Workflows & State Machines
Simple CRUD lifecycle with soft delete. A marksheet type goes through **Active → Inactive** (via `is_active` toggle) or **Active → Deleted** (soft). Deletion is blocked by referential integrity if any `msh_config_templates` row references the type. Display order controls dropdown sorting across all downstream screens. No complex state machine — this is pure reference data.

### Validation Rules & Edge Cases
- `code` must be uppercase letters, numbers, and underscores only (regex: `^[A-Z0-9_]+$`).
- Code uniqueness is enforced at DB level via UNIQUE index. Reject with user-friendly message on duplicate.
- Delete guard: if templates reference this type, show a modal listing the dependent templates and forbid deletion. Deactivation (`is_active = 0`) is the recommended alternative.
- `display_order` must be a positive integer; gaps are allowed and do not need resequencing.
- At least one active marksheet type must exist before any template can be created — enforce via application check, not DB constraint.
- Soft delete: queries across the module must filter `WHERE deleted_at IS NULL` unless explicitly including deleted records for audit.

### Integration Points
- **msh_config_templates.marksheet_type_id**: Downstream FK that blocks deletion.
- **sys_users**: Creator/updater tracking.
- **msh_marksheet_schedules** (indirectly via templates): A deleted/inactive type breaks the chain only if no schedules reference the template.

### Permissions Matrix
| Role | View List | Create | Edit | Delete | Toggle Active |
|---|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes (if unused) | Yes |
| Principal | Yes | No | No | No | No |
| Class Teacher | Yes (read-only dropdown) | No | No | No | No |
| Subject Teacher | No | No | No | No | No |
| Student/Parent | No | No | No | No | No |
