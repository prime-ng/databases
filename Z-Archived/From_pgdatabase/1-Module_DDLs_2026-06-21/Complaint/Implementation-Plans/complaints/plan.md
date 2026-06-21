# Complaints (Core) — Implementation Plan

## Purpose
The central ticket registry for grievances with SLA-driven resolution deadlines, 5-level escalation tracking, status workflow FSM, and linked medical checks. Largest gap area in the module.

## Documented But Not Implemented

### Item 1: `resolution_due_at` Never Auto-Computed (P0)

**Source:** `Requirements/complaints.md:43` — "Calculated from SLA: ticket_date + category/department resolution hours"

**Current Behavior:** `resolution_due_at` is a nullable date field (line 508: `'resolution_due_at' => 'nullable|date'`). Never set during `store()`. Only manually editable via update form.

**Implement:**
- [ ] In `ComplaintController::store()`, after creation:
  - Call `SlaResolutionService::resolveSla($complaint)`
  - Set `resolution_due_at = ticket_date->addHours(resolvedHours)`
- [ ] In `ComplaintController::update()`, when category/assignment changes:
  - Recompute `resolution_due_at` via SLA service
- [ ] Add `adm:recompute-resolution-dates` command for backfill

### Item 2: Escalation Level Never Persisted to DB (P0)

**Source:** `Requirements/complaints.md:48-49` — Fields `escalation_level` (INT 0-5) and `is_escalated` (BOOLEAN) documented in schema

**Current Behavior:** Escalation computed at display time only in `ComplaintController` lines 753-800 as transient properties. DB fields `escalation_level` and `is_escalated` are always NULL.

**Implement:**
- [ ] Create `ProcessEscalationsCommand.php` (Artisan command):
```php
class ProcessEscalationsCommand extends Command
{
    protected $signature = 'adm:process-escalations';
    
    public function handle()
    {
        // 1. Query complaints not in Resolved/Closed/Rejected status
        // 2. Where escalation_level < 5 OR is NULL
        // 3. For each: compute current level via SlaResolutionService
        // 4. If level changed → dispatch ComplaintEscalated event
        // 5. Update escalation_level + is_escalated on DB
    }
}
```
- [ ] Register command in `ComplaintServiceProvider`
- [ ] Schedule in kernel: `$schedule->command('adm:process-escalations')->everyThirtyMinutes()`
- [ ] Remove transient computation from `ComplaintController` index listing (replace with DB read)

### Item 3: No Escalation Notifications (P0)

**Source:** Implied by escalation matrix — each level targets a different entity group

**Current Behavior:** No notifications fire when escalation levels breach.

**Implement:**
- [ ] Create `ComplaintEscalated` event (contains complaint, previous_level, new_level)
- [ ] Create `SendEscalationNotification` listener:
  - Read `DepartmentSla.escalation_l{N}_entity_group_id` or category defaults
  - Dispatch NTF notification to entity group members
- [ ] Wire event→listener in `EventServiceProvider`
- [ ] Create EscalationNotification with email + SMS templates

### Item 4: Status Workflow FSM Not Enforced (P0)

**Source:** `Requirements/complaints.md:82-84` — "Allowed transitions: Open → In Progress → Resolved / Rejected → Closed"

**Current Behavior:** No transition validation. Any status can be set to any value.

**Implement:**
- [ ] Create `StatusWorkflowService`:
```php
class StatusWorkflowService
{
    const TRANSITIONS = [
        'Open'        => ['In Progress'],
        'In Progress' => ['Resolved', 'Rejected'],
        'Resolved'    => ['Closed'],
        'Rejected'    => ['Closed'],
    ];

    public function canTransition(int $fromStatusId, int $toStatusId): bool
    {
        // Resolve value from sys_dropdowns for both IDs
        // Check against TRANSITIONS matrix
    }

    public function assertCanTransition($from, $to): void
    {
        if (!$this->canTransition($from, $to)) {
            throw new ValidationException('Invalid status transition');
        }
    }
}
```
- [ ] Integrate into `ComplaintController::update()` before any status change
- [ ] Create `UpdateComplaintStatusRequest` FormRequest with transition check

### Item 5: Resolution Validation Not Enforced (P0)

**Source:** `Requirements/complaints.md:87-89` — "actual_resolved_at must be on or after resolution_due_at. At least one of resolved_by_role_id or resolved_by_user_id must be set."

**Current Behavior:** Lines 508-509 show both as `nullable|date`. No cross-field validation.

**Implement:**
- [ ] When status changes to Resolved/Closed:
  - Validate `actual_resolved_at >= resolution_due_at` (warning if breached)
  - Require at least one: `resolved_by_role_id` XOR `resolved_by_user_id`
  - Require `resolution_summary` not empty
- [ ] Add custom rule or FormRequest validation

### Item 6: Complaint Store/Update Should Use FormRequest (P0)

**Source:** `Requirements/complaints.md:98-102` — create, validate, save workflow

**Current Behavior:** `ComplaintController::store()` (line 232) and `update()` (line 506) use inline validation.

**Implement:**
- [ ] Create `StoreComplaintRequest.php`:
  - Complainant type logic (anonymous → name required, user_id null)
  - `category_id`, `subcategory_id` chain validation
  - Severity/priority auto-filled from subcategory
  - Ticket number generation inside request (or keep in controller)
- [ ] Create `UpdateComplaintRequest.php` with change detection
- [ ] Create `UpdateComplaintStatusRequest.php` with FSM transition check + resolution validation

### Item 7: ComplaintPolicy::create() Wrong Permission (P0)

**Source:** `ComplaintPolicy.php` line for `create()`

**Current Behavior:** Checks `tenant.vendor-dahsboard.create` (typo: "dahsboard", wrong module "vendor").

**Implement:**
- [ ] Change to `tenant.complaint.create`

### Item 8: `logAction()` Uses Raw DB Instead of Eloquent

**Source:** `ComplaintController` line 1064

**Current Behavior:** `DB::table('cmp_complaint_actions')->insert([...])` bypasses Eloquent.

**Implement:**
- [ ] Replace with `ComplaintAction::create([...])`

### Item 9: DDL Doc Column Names Out of Sync

**Source:** DDL v2 doc uses `target_selected_id` / `current_escalation_level` but migrations use `target_id` / `escalation_level`

**Current Behavior:** Migrations and models agree (both use `target_id` and `escalation_level`). The fix migration (`2026_05_07_200000`) added `target_table_name`, `target_selected_id`, `target_code` separately — `target_selected_id` is for the displayed name reference, not replacing `target_id`.

**Implement:**
- [ ] Update `cmp_requirement.md` field names to match actual migration column names

### Item 10: Status Change Detection Logs Wrong Action Type

**Source:** `cmp_requirement.md:352` — "Change detection: logs StatusChange, Assigned, Resolved actions based on diffs"

**Current Behavior:** Need to verify the update method logs correct action types per change type.

**Verify:**
- [ ] Check update() logic for correct action_type_id per change type
- [ ] Ensure each change type maps to correct sys_dropdowns value

### Item 11: Escalation Level Default Value Check

**Source:** Migration `2025_12_22_065413` sets `escalation_level` default 0

**Current Behavior:** The escalation processing command (Item 2) must handle the default 0 correctly. Ensure command checks `escalation_level < 5` rather than `IS NULL` since the column defaults to 0.

### Item 12: Missing Feature Tests

**Implement:**
- [ ] `ComplaintCrudTest.php` — create, view, update, delete
- [ ] `ComplaintStatusWorkflowTest.php` — valid transitions pass, invalid fail
- [ ] `EscalationProcessingTest.php` — command escalates correctly, events fire
- [ ] `SlaResolutionIntegrationTest.php` — SLA overrides affect escalation computation
