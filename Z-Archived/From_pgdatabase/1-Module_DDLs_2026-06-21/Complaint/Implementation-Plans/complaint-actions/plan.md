# Complaint Actions — Implementation Plan

## Purpose
Immutable audit trail for every state change on a complaint. Actions are auto-generated for create, status change, assignment, resolution, and delete events.

## Documented But Not Implemented

### Item 1: ComplaintActionController Is a Stub

**Source:** Routes register full CRUD but controller is a stub

**Current Behavior:** `ComplaintActionController.php` (56 lines) only has an `index()` method returning `view('complaint::index')`.

**Implement:**
- [ ] `index()`: List actions with filters (complaint_id, action_type, date range) — this already works via `getComplaintActionsData()` in ComplaintController, but should be self-contained
- [ ] `show()`: View single action detail
- [ ] `destroy()`: Soft delete with SweetAlert2 confirmation
- [ ] `restore()`: Restore soft-deleted action
- [ ] `forceDelete()`: Permanent delete

### Item 2: `logAction()` Uses Raw DB Instead of Eloquent

**Source:** `ComplaintController` line 1064

**Current Behavior:** `DB::table('cmp_complaint_actions')->insert([...])` bypasses Eloquent events, casts, and relationships.

**Implement:**
- [ ] Replace with `ComplaintAction::create([...])`:
```php
ComplaintAction::create([
    'complaint_id'         => $data['complaint_id'],
    'action_type_id'       => $data['action_type_id'],
    'performed_by_user_id' => $data['performed_by_user_id'] ?? auth()->id(),
    'performed_by_role_id' => $data['performed_by_role_id'] ?? null,
    'assigned_to_user_id'  => $data['assigned_to_user_id'] ?? null,
    'assigned_to_role_id'  => $data['assigned_to_role_id'] ?? null,
    'notes'                => $data['notes'] ?? null,
    'is_private_note'      => $data['is_private_note'] ?? false,
]);
```

### Item 3: Migration Exists — Verify Schema

**Source:** `database/migrations/tenant/2025_12_22_070357_create_complaint_actions_table.php`

**Current Behavior:** Migration exists. Verify it matches the spec.

**Implement:**
- [ ] Review migration for all fields from spec
- [ ] Ensure `is_private_note` column exists

### Item 4: Missing Feature Tests

**Current Behavior:** Zero tests.

**Implement:**
- [ ] `ComplaintActionAuditTest.php`:
  - Create complaint → verify "Created" action logged
  - Change status → verify "StatusChange" action with old→new values
  - Change assignment → verify "Assigned" action with assigner+assignee
  - Mark resolved → verify "Resolved" action with resolver details
  - Soft delete complaint → verify "Deleted" action
