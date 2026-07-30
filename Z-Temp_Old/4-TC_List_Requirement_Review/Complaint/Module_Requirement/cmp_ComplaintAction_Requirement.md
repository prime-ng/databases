# Complaint Action — Business Requirements

## What This Screen Does

The Complaint Actions screen displays the audit trail timeline for all complaint activities. Actions are auto-logged by the system when complaints are created, assigned, status-changed, resolved, reopened, or deleted. Users can view the complete history with performed-by, action type, notes, and assignment details.

## When This Screen Is Used

- **When auditing complaint handling** to see who did what and when.
- **When tracking assignment changes** across the complaint lifecycle.
- **When viewing internal notes** (private notes visible only to admins).
- **When reviewing the complete history** of a specific complaint.

## Key Fields

- **Complaint** (FK → cmp_complaints) — Parent complaint
- **Action Type** (FK → sys_dropdown_table) — Created, Assigned, StatusChange, Comment, Resolved, Reopened, Deleted
- **Performed By User** (FK → sys_users, nullable) — Who performed the action
- **Performed By Role** (FK → sys_roles, nullable) — Under which role
- **Assigned To User/Role** (FK, nullable) — If reassignment occurred
- **Notes** (text, nullable)
- **Is Private Note** (boolean) — Hidden from non-admin users
- **Action Timestamp** (timestamp)

## Business Rules

**Auto-Logging:**
Actions are not created manually (ComplaintActionController is mostly a stub). All actions are auto-logged by `ComplaintController@logAction()` on: create, status change, assignment change, reopen, delete.

**Private Notes:**
The `scopeVisibleToUser()` query scope hides private notes from users without Super Admin, School Admin, or Principal roles.

**Timeline Ordering:**
Actions are ordered by `created_at` ascending, forming a chronological timeline.

**Read-Only Display:**
The actions tab is primarily a read-only viewer. The controller offers restore/forceDelete but actions are typically not manually deleted.

## Workflow

1. User navigates to Complaint → Complaint Management → Actions tab.
2. Timeline shows actions grouped by complaint, with performed-by, action type badge, timestamp, and notes.
3. Private notes are hidden from unauthorized users.
4. Filterable by complaint or action type.

## Requirements

- MUST display at `/complaint/complaint-mgt?tab=actions` as timeline view
- MUST authorize via `tenant.complaint-action.*` policy gates
- MUST auto-log actions on complaint create, update, assign, reopen, delete
- MUST support private notes hidden from non-admin users
- MUST show chronological timeline ordered by created_at
- MUST filter by complaint or action type
