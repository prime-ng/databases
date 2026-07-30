# Visitor Purposes — Business Requirements

## What This Screen Does

The Visitor Purposes tab manages the predefined list of reasons a visitor can have when visiting the school (e.g., "Parent Meeting", "Official Visit", "Delivery"). Each purpose has a unique **code** and **name**, a **sort order** for display sequencing, and a boolean **is_government_visit** flag that triggers special audit/compliance rules (BR-FOF-007).

Government visit purposes cannot be deleted or force-deleted — the `VisitorPurposePolicy` rejects `delete` and `forceDelete` when `is_government_visit = true`. The `VisitorPolicy` also blocks deletion of visitor records linked to a government purpose.

Purposes are referenced by `fof_visitors.purpose_id` and displayed in the Visitors tab as `$visitor->purpose?->name`.

## When This Screen Is Used

- **Initial Setup**: Configuring the list of visit reasons at school deployment
- **Ongoing Maintenance**: Adding/renaming purposes as needs evolve
- **Compliance**: Flagging government visits for audit tracking
- **Sorting**: Reordering purposes to match most-frequent-first display

## Key Fields

- **Name** (string 100) — Display name (e.g., "Parent Meeting", "Official Visit")
- **Code** (string 30, unique) — Short identifier for dropdowns/references
- **Is Government Visit** (boolean, default false) — When true, protects records from deletion
- **Sort Order** (integer 0-255, nullable) — Display sequence (lower = first)
- **Is Active** (boolean, default true) — Toggle via status switch

## Business Rules

**Government Visit Protection (BR-FOF-007):** Both `VisitorPurposePolicy` and `VisitorPolicy` check `is_government_visit`:
- `delete()` and `forceDelete()` on purpose → `return false`
- `delete()` and `forceDelete()` on visitor → `return false` if visitor's purpose is government
- No error message is surfaced to the user — the gate simply denies with 403

**Soft Delete:** Model uses SoftDeletes. `trashed()`, `restore()`, `forceDelete()` routes exist.

**Unique Code:** `StoreVisitorPurposeRequest` validates `code` is unique on `fof_visitor_purposes`, ignoring the current record's ID on update.

**Status Toggle:** Ajax endpoint `toggleStatus()` flips `is_active` via `X-backend.table.status-switch` component. Returns JSON `{success, message, is_active}`.

**Search:** The controller's `visitorManagement()` method searches by `name`, `code`, `sort_order`, and has special logic to match `is_government_visit` by keyword ("yes"/"government"/"govt" → true, "no"/"regular" → false).

## Workflow

1. Staff navigates to Front Office → Visitor Management → Visitor Purposes tab
2. Paginated table shows Code (badge), Name, Sort Order, Govt Visit (Yes/No badge), Status toggle, Actions
3. Staff searches by name/code or filters by active/inactive status
4. Actions: View, Edit, Delete (government purposes blocked from delete)

## Requirements

- MUST display at `/front-office/visitor-management?tab=visitor-purposes` as paginated table
- MUST authorize via `frontoffice.visitor-purpose.*` policy gates
- MUST enforce unique `code` validation (ignore current record on update)
- MUST protect government visit purposes from delete/forceDelete (BR-FOF-007)
- MUST support status toggle via Ajax
- MUST support soft delete with restore/forceDelete
- MUST sort by `sort_order` then `name` by default
