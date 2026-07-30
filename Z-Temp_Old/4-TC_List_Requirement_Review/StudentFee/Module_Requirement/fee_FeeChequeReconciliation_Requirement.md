# Fee Cheque/DD Reconciliation — Business Requirements

## What This Screen Does

The Fee Cheque/DD Reconciliation screen manages the cheque and demand draft lifecycle for fee payments. It tracks the complete status workflow from Pending Deposit → Deposited → Cleared / Bounced → Resubmitted. On bounce, the payment is reversed by marking the original transaction as Failed and deducting the payment from the invoice.

---

## When This Screen Is Used

- **Cheque/DD Recording** when a cheque payment is received and needs to be tracked
- **Deposit Tracking** when cheques are deposited in the bank
- **Clearance Confirmation** when the bank confirms cheque clearance
- **Bounce Management** when a cheque is returned unpaid and payment needs reversal
- **Resubmission Tracking** when a bounced cheque is re-deposited

## Default Data Load

The index page loads `FeePaymentReconciliation::with(['transaction.student.user'])->latest()->paginate(15)`. The create page loads successful transactions with payment mode Cheque or DD.

---

## Key Fields at a Glance

**Cheque/DD Identity**
`transaction_id` — FK to the original fee transaction (unique in reconciliation). `cheque_no` — cheque/DD number (required). `bank_name` — issuing bank (required). `cheque_date` — date on the cheque (required).

**Lifecycle Dates**
`deposit_date` — when deposited in bank. `clearance_date` — when cleared. `bounce_date` — when bounced. `resubmit_date` — when re-deposited after bounce.

**Bounce Details**
`bounce_reason` — reason for bounce (required when bouncing, max 500 chars). `bounce_charge` — bank penalty fee (nullable, numeric, min:0).

**Status Workflow**
Five statuses: `Pending Deposit` → `Deposited` → `Cleared` / `Bounced` → `Resubmitted`.

---

## Business Rules and Conditions

**Status Transition Rules**
- Pending Deposit → Deposited: only if current status is Pending Deposit. Error: "Only pending deposit cheques can be marked as deposited."
- Deposited → Cleared: only if current status is Deposited. Error: "Only deposited cheques can be marked as cleared."
- Deposited → Bounced: only if current status is Deposited. Error: "Only deposited cheques can be marked as bounced."
- Bounced → Resubmitted: only if current status is Bounced. Error: "Only bounced cheques can be marked as resubmitted."
- Edit/Delete: only allowed if status is Pending Deposit. Errors: "Only pending deposit records can be edited." / "Only pending deposit records can be updated." / "Only pending deposit records can be deleted."

**Bounce Reversal**
When a cheque bounces:
1. Reconciliation status set to Bounced with bounce_reason, bounce_charge, bounce_date
2. Original transaction status updated to `FeeTransaction::STATUS_FAILED`
3. Invoice payment deducted via `$transaction->invoice->deductPayment((float) $transaction->amount)`
This effectively reverses the payment and restores the invoice balance.

**Duplicate Prevention**
- Only one active (non-Bounced) reconciliation record per transaction. Error: "A reconciliation record already exists for this transaction."
- Transactions with payment modes other than Cheque/DD cannot be selected.

**Resubmission Flow**
After bounce, the cheque can be resubmitted (new cycle starts from Resubmitted). No automatic status progression after resubmit.

---

## Workflow Steps

**Creating a Reconciliation Record**
Admin selects a successful Cheque/DD transaction, enters cheque number, bank name, cheque date, and optional remarks. System creates with status=Pending Deposit.

**Depositing a Cheque**
Admin clicks "Deposit" on a Pending Deposit record. System sets deposited status and deposit_date (now).

**Clearing a Cheque**
Admin clicks "Clear" on a Deposited record. System sets cleared status and clearance_date (now).

**Bouncing a Cheque**
Admin enters bounce reason (required) and optional bounce charge, then clicks "Bounce" on a Deposited record. System sets bounced status, bounce details, reverses the transaction to Failed, and deducts payment from invoice.

**Resubmitting a Cheque**
Admin clicks "Resubmit" on a Bounced record. System sets resubmitted status and resubmit_date (now).

---

## Example Scenario

A parent pays ₹25,000 fees via cheque. The admin records it (status=Pending Deposit). The cheque is deposited in the bank (status=Deposited). The bank clears it (status=Cleared). If the cheque had bounced due to insufficient funds, the system would record the bounce reason, mark the transaction as Failed, and restore the invoice balance. Later, the parent can resubmit a new cheque.

---

## Related Screens

- **Fee Transactions** — Original transactions linked to cheque/DD records
- **Fee Invoices** — Invoice balance updated on bounce
- **Payment** — Payment records with cheque/DD payment mode

---

## Requirements

- Controller `FeeChequeController` with full resource routes plus custom deposit/clear/bounce/resubmit routes (all POST)
- `index()` gates `tenant.fee-cheque.viewAny`, loads with transaction.student.user relations, paginated at 15
- `create()` gates `tenant.fee-cheque.create`, loads successful Cheque/DD transactions
- `store()` validates via `StoreFeeChequeRequest`, checks no existing active reconciliation for transaction, creates with status=Pending Deposit and updated_by
- `show()` loads with transaction.student.user, invoice, updatedBy
- `edit()` gates `tenant.fee-cheque.update`, blocks if not Pending Deposit ("Only pending deposit records can be edited.")
- `update()` validates via `UpdateFeeChequeRequest`, blocks if not Pending Deposit ("Only pending deposit records can be updated.")
- `destroy()` gates `tenant.fee-cheque.delete`, blocks if not Pending Deposit ("Only pending deposit records can be deleted.")
- `deposit()` gates `tenant.fee-cheque.deposit`, checks Pending Deposit status, sets Deposited + deposit_date=now
- `clear()` gates `tenant.fee-cheque.clear`, checks Deposited status, sets Cleared + clearance_date=now
- `bounce()` gates `tenant.fee-cheque.bounce`, checks Deposited status, validates bounce_reason (required, string, max:500) and bounce_charge (nullable, numeric, min:0), reverses transaction (status=Failed) and invoice payment in DB transaction
- `resubmit()` gates `tenant.fee-cheque.resubmit`, checks Bounced status, sets Resubmitted + resubmit_date=now

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.fee-cheque.viewAny` | `index()` | Page load |
| `tenant.fee-cheque.view` | `show()` | View details |
| `tenant.fee-cheque.create` | `create()`, `store()` | Create record |
| `tenant.fee-cheque.update` | `edit()`, `update()` | Edit pending |
| `tenant.fee-cheque.delete` | `destroy()` | Delete pending |
| `tenant.fee-cheque.deposit` | `deposit()` | Mark deposited |
| `tenant.fee-cheque.clear` | `clear()` | Mark cleared |
| `tenant.fee-cheque.bounce` | `bounce()` | Mark bounced |
| `tenant.fee-cheque.resubmit` | `resubmit()` | Mark resubmitted |

## Logic Flow

1. **Create** — `create()` loads successful Cheque/DD transactions. `store()` validates unique active reconciliation per transaction, creates record with Pending Deposit.
2. **Deposit** — `deposit()` checks Pending Deposit status, sets Deposited + deposit_date.
3. **Clear** — `clear()` checks Deposited status, sets Cleared + clearance_date.
4. **Bounce** — `bounce()` validates bounce_reason (required) and bounce_charge (optional). DB transaction: updates reconciliation to Bounced + details, marks transaction as Failed, deducts payment from invoice.
5. **Resubmit** — `resubmit()` checks Bounced status, sets Resubmitted + resubmit_date.
6. **Edit/Delete** — Both check Pending Deposit status. Block if not Pending Deposit.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `transaction_id` | `required, integer, exists:fee_transactions,id` where payment_mode in (Cheque, DD) | — |
| `cheque_no` | `required, string, max:50` | — |
| `bank_name` | `required, string, max:100` | — |
| `cheque_date` | `required, date` | — |
| `remarks` | `nullable, string, max:500` | — |
| **Bounce** — `bounce_reason` | `required, string, max:500` | — |
| **Bounce** — `bounce_charge` | `nullable, numeric, min:0` | — |
| **Duplicate check** | No existing active (non-Bounced) reconciliation for transaction | "A reconciliation record already exists for this transaction." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Edit non-Pending | "Only pending deposit records can be edited." | Controller |
| Update non-Pending | "Only pending deposit records can be updated." | Controller |
| Delete non-Pending | "Only pending deposit records can be deleted." | Controller |
| Deposit non-Pending | "Only pending deposit cheques can be marked as deposited." | Controller |
| Clear non-Deposited | "Only deposited cheques can be marked as cleared." | Controller |
| Bounce non-Deposited | "Only deposited cheques can be marked as bounced." | Controller |
| Resubmit non-Bounced | "Only bounced cheques can be marked as resubmitted." | Controller |
| Duplicate transaction | "A reconciliation record already exists for this transaction." | Validation (after) |
| Create success | "Cheque/DD reconciliation record created successfully." | Flash |
| Deposit success | "Cheque/DD marked as deposited." | Flash |
| Clear success | "Cheque/DD marked as cleared." | Flash |
| Bounce success | "Cheque/DD marked as bounced and payment reversed." | Flash |
| Resubmit success | "Cheque/DD marked as resubmitted." | Flash |

## Success Scenarios

**SC-001 — Full Clearance Lifecycle**
Cheque recorded (Pending Deposit) → deposited (Deposited) → cleared (Cleared). All statuses progress in sequence.

**SC-002 — Bounce With Reversal**
Cheque deposited → bounced with reason "Insufficient funds" and charge ₹50. Original transaction marked Failed. Invoice balance restored.

**SC-003 — Bounce and Resubmit**
Cheque deposited → bounced → resubmitted. New resubmit_date recorded.

**SC-004 — Edit Pending Deposit Record**
Admin edits cheque_no or bank_name while status is Pending Deposit. Update succeeds.

## Failure Scenarios

**FC-001 — Clear Non-Deposited Cheque**
User tries to clear a Pending Deposit cheque. Error: "Only deposited cheques can be marked as cleared."

**FC-002 — Duplicate Transaction**
Admin creates record for transaction that already has an active reconciliation. Error: "A reconciliation record already exists for this transaction."

**FC-003 — Bounce Without Reason**
User tries to bounce without entering bounce_reason. Validation fails on required. Error: "The bounce reason field is required."

**FC-004 — Resubmit Non-Bounced Cheque**
User tries to resubmit a Cleared cheque. Error: "Only bounced cheques can be marked as resubmitted."

## Dependencies Module and Tables

| Dependency | Type | Details |
|-----------|------|---------|
| `fee_payment_reconciliation` | Main Table | All CRUD + lifecycle on this table |
| `fee_transactions` | FK Table | `transaction_id` FK RESTRICT; status updated to Failed on bounce |
| `std_students` | FK Table | Via transaction.student |
| `fee_invoices` | Related Table | Invoice payment deducted on bounce via `deductPayment()` |
| `sys_users` | FK Table | `updated_by` FK SET NULL |
