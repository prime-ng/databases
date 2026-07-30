# Fee Fine Transactions — Business Requirements

## What This Screen Does

The Fee Fine Transactions screen tracks fines applied to student invoices. Each record captures the student, invoice, fine rule used, days late, fine amount, and waiver status. Supports full or partial waiver of fines with audit trail. This screen is part of the Fine Management tab group alongside Fee Fine Rules.

---

## When This Screen Is Used

- **Viewing Applied Fines** when reviewing penalties on a student's account
- **Waiving Fines** when an admin decides to reduce or remove a fine for a specific student
- **Manual Fine Recording** when a fine needs to be applied outside the automated schedule

## Default Data Load

This screen displays within the Fine Management tab group. `StudentFeeManagementController@fineManagement()` loads `FeeFineTransaction::with(['student.user', 'invoice', 'fineRule'])->latest('fine_date')->paginate(15)`. The grid is filterable by student name search and waived status.

---

## Key Fields at a Glance

**Transaction Identity**
Links to `student_id` (FK → `std_students`), `invoice_id` (FK → `fee_invoices`), and `fine_rule_id` (FK → `fee_fine_rules`). The `fine_date` records when the fine was applied. `days_late` tracks the number of overdue days.

**Fine Amounts**
`fine_amount` is the computed penalty. `waived` (boolean) indicates if the fine has been waived. `waived_amount` supports partial waivers (NULL = full waiver). `waivered` field tracks the effective fine after waiver via `getEffectiveFine()`.

**Waiver Audit**
When waived: `waived_by` (FK → `sys_users`), `waiver_reason`, and `waived_at` (datetime) are recorded for audit trail.

---

## Business Rules and Conditions

**Waiver Rules**
- Fine can be fully or partially waived
- `waived_amount` cannot exceed `fine_amount` (validated in `WaiveFeeFineTransactionRequest` with rule `max:{fine_amount}`)
- Once waived, the effective fine = `fine_amount - waived_amount` (full waiver = 0)
- If `waived_amount` is null and `waived=1`, it's a full waiver
- `getEffectiveFine()` helper: if not waived → returns full fine_amount; if waived with amount → returns fine_amount - waived_amount; if waived without amount → returns 0
- Waived fines cannot be edited — error: "Cannot edit a waived fine transaction."
- Already waived fines cannot be waived again — error: "This fine has already been waived."

**Duplicate Prevention**
The `ApplyFines` scheduled command checks for existing fine transactions before creating new ones for the same `invoice_id + fine_rule_id + fine_date`.

**Soft Delete**
Fine transactions support soft delete. No restore/forceDelete routes exist in the controller.

---

## Workflow Steps

**Recording a Fine Transaction**
The system (via `FeeFineService@record()` or manual entry) creates a transaction with student_id, invoice_id, fine_rule_id, fine_date, days_late, fine_amount, and waived=false.

**Waiving a Fine**
The admin navigates to the fine transaction, clicks "Waive", optionally enters a partial waived_amount and waiver_reason. The system validates that the fine is not already waived, then calls `FeeFineService@waive()` which sets waived=true, waived_amount, waived_by, waiver_reason, waived_at.

**Editing a Fine Transaction**
The admin can edit fine_rule_id, fine_date, days_late, and fine_amount as long as the transaction has not been waived. Waived fines show error: "Cannot edit a waived fine transaction."

---

## Example Scenario

A student has an overdue tuition fee invoice. The daily fine rule (₹25/day) has been running for 10 days, generating a fine of ₹250. The parent visits the school and explains the delay. The admin partially waives ₹150, keeping ₹100 as a nominal fine. The system records waived_by, waiver_reason, and waived_at. The effective fine becomes ₹100.

---

## Related Screens

- **Fee Fine Rules** — Defines the rules used to calculate fines
- **Billing** — Invoice grid showing applied fines on invoices
- **Governance** — Name removal logs triggered by excessive fines

---

## Requirements

- Controller `FeeFineTransactionController` with `FeeFineService` dependency injection via constructor
- `index()` redirects to `student-fee.fineManagement` with gate `tenant.fee-fine-transaction.view`
- `create()` gates `tenant.fee-fine-transaction.create`, loads active students, unpaid/non-cancelled invoices, and active fine rules
- `store()` validates via `StoreFeeFineTransactionRequest`, delegates to `FeeFineService::record()`
- `show()` loads with `student.user`, `invoice`, `fineRule`, `waivedBy` relations
- `edit()` loads transaction with relations and active fine rules
- `update()` validates via `UpdateFeeFineTransactionRequest`, blocks if waived ("Cannot edit a waived fine transaction.")
- `destroy()` soft-deletes with activity log
- `waive()` gates `tenant.fee-fine-transaction.update`, validates via `WaiveFeeFineTransactionRequest`, checks already waived ("This fine has already been waived."), delegates to `FeeFineService::waive()` for full or partial waiver
- Route: `PUT /fee-fine-transaction/{id}/waive` for waiving
- Activity logged for Created, Updated, Deleted, Waived events

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.fee-fine-transaction.view` | `index()`, `show()` | Page load + view |
| `tenant.fee-fine-transaction.create` | `create()`, `store()` | Manual fine recording |
| `tenant.fee-fine-transaction.update` | `edit()`, `update()`, `waive()` | Edit + waive |
| `tenant.fee-fine-transaction.delete` | `destroy()` | Soft delete |

## Logic Flow

1. **Page Load** — Screen via Fine Management tab loads fine transactions with student, invoice, fine rule data. Filterable by search (student name) and waived status.
2. **Create** — `create()` loads active students, invoices (not Paid/Cancelled), active fine rules. `store()` validates, calls `FeeFineService::record()` which creates FeeFineTransaction with waived=false.
3. **Edit** — `edit()` loads transaction. `update()` validates, checks `$transaction->waived`, blocks if true with error message.
4. **Waive** — `waive()` validates `WaiveFeeFineTransactionRequest` which dynamically sets `max:{fine_amount}` for `waived_amount`. Service calls `$transaction->waive($waivedBy, $reason, $amount)` which sets waived flags and timestamp.
5. **Delete** — Soft delete with activity log. No restore route.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `student_id` | `required, integer, exists:std_students,id` | — |
| `invoice_id` | `required, integer, exists:fee_invoices,id` | — |
| `fine_rule_id` | `required, integer, exists:fee_fine_rules,id` | — |
| `fine_date` | `required, date` | — |
| `days_late` | `required, integer, min:0` | — |
| `fine_amount` | `required, numeric, min:0` | — |
| **Update** — `waived_amount` | `nullable, numeric, min:0, max:{transaction->fine_amount}` | — |
| **Update** — `waiver_reason` | `nullable, string, max:500` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Edit waived transaction | "Cannot edit a waived fine transaction." | Controller |
| Waive already waived | "This fine has already been waived." | Controller (DomainException) |
| Waive amount exceeds fine | Validation: max rule dynamically set | Validation |
| Delete fine transaction | "Fine transaction deleted successfully." | Flash success |
| Waive fine | "Fine waived successfully." | Flash success |

## Success Scenarios

**SC-001 — Recording a Fine Transaction**
Admin records a fine for student, invoice, fine rule with 10 days late and ₹250 amount. System creates record with waived=false. Returns success message "Fine transaction recorded successfully."

**SC-002 — Partial Waiver of Fine**
Admin waives a ₹500 fine with waived_amount=200 and reason="Partial concession". System sets waived=true, waived_amount=200, waiver_reason, waived_by, waived_at. Returns "Fine waived successfully."

**SC-003 — Full Waiver of Fine**
Admin waives a ₹500 fine without specifying waived_amount. System treats as full waiver, sets waived=true, waived_amount=null. `getEffectiveFine()` returns 0.

## Failure Scenarios

**FC-001 — Edit After Waive**
Admin tries to edit a waived fine transaction. System returns "Cannot edit a waived fine transaction."

**FC-002 — Double Waive**
Admin tries to waive an already waived transaction. System returns "This fine has already been waived."

**FC-003 — Waive Amount Exceeds Fine**
Admin enters waived_amount=600 for a fine of ₹500. Validation rule `max:500` rejects.

## Dependencies Module and Tables

| Dependency | Type | Details |
|-----------|------|---------|
| `fee_fine_transactions` | Main Table | All CRUD on this table |
| `std_students` | FK Table | `student_id` FK RESTRICT |
| `fee_invoices` | FK Table | `invoice_id` FK RESTRICT |
| `fee_fine_rules` | FK Table | `fine_rule_id` FK RESTRICT |
| `sys_users` | FK Table | `waived_by` FK SET NULL |
| `FeeFineService` | Service | `record()` and `waive()` methods |
