# Gate Pass (Early Exit) — Requirements

## What It Does
Authorizes student and staff early exits from school. Student passes require parent NTF notification. Passes go through an approval workflow (`Pending_Approval → Approved/Rejected → Exited → Returned`) with strict state machine enforcement.

## Database Fields

### fof_gate_passes

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `pass_number` | VARCHAR(25) | Required. Unique. Auto-generated: `GP-YYYYMMDD-NNN`. |
| `person_type` | ENUM('Student','Staff') | Required. Determines which FK is populated. |
| `student_id` | INT UNSIGNED FK → `std_students` | Nullable. NULL for staff passes. |
| `staff_user_id` | INT UNSIGNED FK → `sys_users` | Nullable. NULL for student passes. |
| `purpose` | ENUM('Medical','Personal','Official','Sports','Family_Emergency','Other') | Required. |
| `purpose_details` | VARCHAR(200) | Nullable. |
| `exit_time` | DATETIME | Nullable. Set when marking Exited. |
| `expected_return_time` | DATETIME | Nullable. |
| `actual_return_time` | DATETIME | Nullable. Set when marking Returned. |
| `parent_notified` | TINYINT(1) | Default 0. 1 = NTF dispatched for student passes. |
| `status` | ENUM('Pending_Approval','Approved','Rejected','Exited','Returned','Cancelled') | Default 'Pending_Approval'. |
| `approved_by` | INT UNSIGNED FK → `sys_users` | Nullable. Principal/HOD who approved/rejected. |
| `approved_at` | DATETIME | Nullable. |
| `rejection_reason` | TEXT | Nullable. Required when Rejected. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-003 | Student gate passes require parent NTF dispatch before exit authorization | `GatePassService::createPass()` dispatches NTF; front desk warned on NTF failure |
| BR-FOF-004 | A student may only have one active gate pass (Pending/Approved/Exited) at a time | Custom validation rule in `IssueGatePassRequest` |

**State Machine (Strict FSM)**
```
Pending_Approval → Approved → Exited → Returned
                → Rejected
                → Cancelled (at any stage before Exited)
```
Each transition validates the current status:
- `approvePass`: Pre-condition `status = 'Pending_Approval'`
- `rejectPass`: Pre-condition `status = 'Pending_Approval'`
- `markExited`: Pre-condition `status = 'Approved'`
- `markReturned`: Pre-condition `status = 'Exited'`

**Parent NTF Flow (Student Passes Only)**
1. Gate pass created with `person_type = 'Student'`
2. `GatePassService::createPass()` dispatches parent NTF notification
3. On success: `parent_notified = 1`
4. On failure: front desk warned with flash alert; pass still created but marked for follow-up

## CRUD Operations

**Create Gate Pass**
- `POST /front-office/gate-passes` — validates person_type + corresponding FK, checks no active pass for student (BR-FOF-004), generates pass_number, dispatches parent NTF if student

**Approve/Reject**
- `PATCH /front-office/gate-passes/{gatePass}/approve` — sets approved_by, approved_at, status = 'Approved'
- `PATCH /front-office/gate-passes/{gatePass}/reject` — requires rejection_reason, status = 'Rejected'

**Exit/Return**
- `PATCH /front-office/gate-passes/{gatePass}/exit` — sets exit_time = NOW(), status = 'Exited'
- `PATCH /front-office/gate-passes/{gatePass}/return` — sets actual_return_time = NOW(), status = 'Returned'

**List**
- Tabs: Pending Approvals / Active / History
- Approve/reject inline with Alpine.js modal

## Permissions

| Operation | Permission Key |
|---|---|
| View gate passes | `frontoffice.gate-pass.view` |
| Create gate pass | `frontoffice.gate-pass.create` |
| Approve/reject gate pass | `frontoffice.gate-pass.approve` |
