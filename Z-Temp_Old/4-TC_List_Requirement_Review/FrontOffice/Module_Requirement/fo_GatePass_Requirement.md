# Gate Passes — Business Requirements

## What This Screen Does

The Gate Passes tab manages student and staff gate passes for leaving campus during school hours. The tab has three internal sections: **Pending Approval**, **Active** (Approved/Exited), and **History** (Returned/Rejected/Cancelled). Each pass tracks the person (Student or Staff), purpose, exit/return times, and approval workflow.

## When This Screen Is Used

- **Gate Pass Request**: Student or staff requests permission to leave campus
- **Approval Workflow**: Authorized staff approves or rejects pass requests
- **Exit Tracking**: Security marks the person as exited when they leave
- **Return Tracking**: Marks return when the person comes back
- **Compliance Log**: Complete history of all gate passes for audit

## Key Fields

- **Pass Number** (string) — Unique auto-generated identifier
- **Person Type** (enum) — Student, Staff
- **Student** (FK → `std_students`, nullable) — If person_type = Student
- **Staff User** (FK → `sys_users`, nullable) — If person_type = Staff
- **Purpose** (enum) — Medical, Personal, Official, Sports, Family_Emergency, Other
- **Purpose Details** (string 200, nullable)
- **Exit Time** (datetime, nullable) — When person actually left
- **Expected Return Time** (datetime, nullable)
- **Actual Return Time** (datetime, nullable)
- **Parent Notified** (boolean)
- **Status** (enum) — Pending_Approval, Approved, Exited, Returned, Rejected, Cancelled
- **Rejection Reason** (text, nullable)
- **Approved By** (FK → `sys_users`, nullable)
- **Approved At** (datetime, nullable)

## Business Rules

**One Active Pass Per Student (BR-FOF-004):** `IssueGatePassRequest` validates on POST that no active pass (Pending_Approval, Approved, or Exited) exists for the same student. Prevents duplicate concurrent passes.

**Status FSM:** `Pending_Approval → Approved → Exited → Returned` (forward flow). Also: `Pending_Approval → Rejected` (via modal with reason). `Pending_Approval → Cancelled` (by requester). The view groups records: Pending_Approval in Pending section, Approved+Exited in Active section, Returned+Rejected+Cancelled in History section.

**Reject Modal:** Each pending pass row has a "Reject" button opening a modal requiring a rejection reason textarea.

**Approve/Exit/Return Actions:** Three distinct PATCH routes: `approve()`, `markExited()`, `markReturned()`.

**Soft Delete:** Uses SoftDeletes. `trashed()`, `restore()`, `forceDelete()` routes exist.

**Status Toggle:** Ajax endpoint `toggleStatus()` flips `is_active`.

**Search:** Controller searches across `pass_number`, `purpose`, `purpose_details`, `status`, `person_type`, student name/admission_no, staff name.

## Workflow

1. Staff navigates to Front Office → Visitor Management → Gate Passes tab
2. **Pending Approval** section: rows with Approve + Reject buttons; Reject opens modal for reason
3. **Active** section: Approved passes show "Mark Exited" button; Exited passes show "Mark Returned" button
4. **History** section: paginated list of completed/rejected/cancelled passes with read-only actions
5. Each row has status toggle and view/edit/delete actions

## Requirements

- MUST display at `/front-office/visitor-management?tab=gate-passes` with 3 internal sections
- MUST authorize via `frontoffice.gate-pass.*` policy gates
- MUST enforce one active pass per student (BR-FOF-004)
- MUST support status workflow: Pending→Approved→Exited→Returned and Pending→Rejected
- MUST require rejection reason when rejecting a pass
- MUST support status toggle via Ajax
- MUST support soft delete with restore/forceDelete
