# Fee Collection — Business Requirements

## What This Screen Does

The Fee Collection screen records payments received from parents against transport fee invoices created in the Fee Creation screen. It is where money is actually received — whether by cash, UPI, card, bank transfer, or cheque.

When a parent pays their child's transport fee, Mrs. Desai (or the accountant) opens this screen and records the payment. The system calculates any late payment fines automatically based on the number of days past the due date, updates the fee invoice status, and logs everything in the payment audit trail.

This screen appears as the fourth tab within the Student Route Fees Management section, loaded by the `FeeCollectionController`.

---

## Default Data Load

When the user opens the Fee Collection tab, the system displays a paginated table of all collection records. Each row shows the student's name, month, fee amount, paid amount, payment date, payment mode, total delay days, status, reconciliation status, and remarks. Filters allow searching by student name, month, payment mode, or status.

---

## When This Screen Is Used

- **Recording a Cash Payment** — A parent comes to the school office and pays ₹800 in cash for their child's July transport fee. Mrs. Desai opens the Fee Collection screen, selects the student's July fee record, enters the paid amount (₹800), sets payment mode to "Cash," enters today's date as the payment date, and saves. The system records the collection and updates the fee status to "Completed."

- **Recording a Late Payment with Fine** — A parent pays on 25 July (10 days after the due date of 15 July). Mrs. Desai selects the fee record and a Fine Master rule for late payment. The system calculates 10 delay days and applies a ₹50 late fee. The total collected is ₹850 (₹800 fee + ₹50 fine).

- **Recording a Partial Payment** — A parent pays only ₹500 of the ₹800 fee, promising to pay the remaining ₹300 next month. Mrs. Desai enters the paid amount as ₹500. The system records the collection and updates the fee status to "Partial" (not "Completed").

- **Updating a Collection Record** — Mrs. Desai entered the wrong payment amount by mistake. She edits the collection record to correct the amount.

- **Deleting a Collection Record** — A payment was recorded for the wrong student. Mrs. Desai deletes the collection record and re-enters it correctly.

- **Exporting Collection Data** — The Finance department needs a report of all transport fee collections for July. Mrs. Desai exports the data to Excel with the relevant filters.

---

## Key Fields at a Glance

**Fee Master Reference**
The fee invoice (from Fee Creation) that this payment is being applied to. Contains the student's name, month, and original fee amount.

**Payment Date**
The date on which the payment was received. This is critical for calculating delay days (the difference between this date and the fee record's due date).

**Total Delay Days**
The number of days between the due date and the payment date. If the payment is on or before the due date, this is 0. Calculated automatically in the store method.

**Paid Amount**
The actual amount received. This may be less than the fee total (partial payment) or equal to it (full payment).

**Payment Mode**
How the payment was made. Options include: Cash, UPI, Card, Bank, Cheque. The value is always stored in lowercase.

**Fine Reference**
If a late payment fine is being applied, the Fine Master rule is selected. This triggers the auto-creation of a fine detail record with the calculated fine amount.

**Status**
The payment status for this collection record. Typical values are:
- Paid: Payment received in full for the collected amount
- Pending: If for some reason the collection is not finalized

**Reconciled**
A boolean flag indicating whether this payment has been verified against the bank statement or accounting records. 0 = unreconciled, 1 = reconciled.

**Remarks**
Any notes about this payment — for example, "Cash received from parent at office" or "UPI payment confirmed via receipt."

---

## Business Rules and Conditions

**Delay Days Are Calculated Automatically**
When a fee collection is created, the system compares the payment date against the fee record's due date:

```text
If payment_date > due_date:
    delay_days = payment_date - due_date (in days)
Else:
    delay_days = 0
```

This calculation happens in `FeeCollectionController@store` using Carbon's `diffInDays()`.

**Fine Is Created During Collection, Not Before**
The fine is not a separate step. When the user records a fee collection and selects a Fine Master rule, the system:
1. Calculates the delay days
2. Checks if the delay falls within the rule's `fine_from_days` to `fine_to_days` range
3. Calculates the fine amount (Fixed or Percentage)
4. Checks if `student_restricted = 1` and deactivates the student if so
5. Creates a `TptStudentFineDetail` record
6. Creates the fee collection record

All of this happens in a single database transaction.

**Fee Master Status Is Auto-Refreshed**
After any fee collection is created, updated, or deleted, the system calls `refreshFeeMasterStatus()` to recalculate the fee master's status:

| Total Collected vs Fee Amount | Status |
|-------------------------------|--------|
| No collections exist | Pending |
| Some collections exist but total collected < fee amount | Partial |
| Total collected >= fee amount | Completed |

The refresh uses the count of collections and the sum of `paid_amount` across all collections for that fee record.

**Accounting Integration**
When a fee collection is created, the system attempts to send a `TPT_FEE_PAYMENT` event to the accounting module through `RemoteEntryService`. If the accounting service fails (e.g., the accounting module is offline), the system catches the error, logs it, but does NOT roll back the payment. The payment remains recorded in Transport even if accounting synchronization fails.

**Student Pay Log Entry Is Always Created**
Every fee collection action (create, update, delete) creates a corresponding entry in the `StudentPayLog` table with:
- Activity type: `fee_collected_create`, `fee_collected_update`, or `fee_collected_delete`
- Reference table: `tpt_student_fee_collection`
- Amount: The paid amount

**Partial Payments Are Allowed**
The system does not require the paid amount to equal the fee amount. A parent can pay any amount, and the fee master status will reflect "Partial" until the total amount is fully paid.

---

## Workflow Steps

**Recording a Standard Payment**
Mrs. Desai clicks the Create button on the Fee Collection tab. She selects the student's July fee record (₹800, due 15 July). She enters the paid amount as ₹800. She selects "Cash" as the payment mode. She enters today's date as the payment date. She optionally selects a Fine Master rule if the payment is late. She clicks Save. Behind the scenes, the system calculates delay days (0 if paid on time), creates the collection record, optionally creates a fine detail, updates the fee master status to "Completed," logs the activity, creates a pay log entry, and sends an accounting event.

**Recording a Late Payment with Fine**
Mrs. Desai creates a collection for the same fee record, but the payment date is 25 July (10 days late). She selects a Fine Master rule for 1-15 days late (₹50 fixed fine). The system calculates 10 delay days. The fine amount is ₹50. The total collection is ₹850. The fine detail record is created alongside the collection.

**Recording a Partial Payment**
A parent pays only ₹500 of an ₹800 fee. Mrs. Desai enters ₹500 as the paid amount. The system creates the collection. The fee master status becomes "Partial." The remaining ₹300 is still due.

**Editing a Collection Record**
Mrs. Desai realizes she entered ₹700 instead of ₹800. She opens the edit screen, corrects the amount, and saves. The system recalculates the fee master status. A pay log entry with `fee_collected_update` is created.

**Deleting a Collection Record**
A payment was recorded for the wrong student. Mrs. Desai deletes the record. The system refreshes the fee master status (it may revert to "Pending" if this was the only collection). A pay log entry with `fee_collected_delete` is created.

---

## Example Scenario

Green Valley School's July transport fees are due on 15 July. By 31 July, Mrs. Desai has recorded the following collections:

| Scenario | Count | Detail |
|----------|-------|--------|
| On-time payment | 300 | Paid on or before 15 July, no fine |
| Late payment (1-15 days) | 50 | Paid 16-30 July, ₹50 late fee each |
| Late payment (16-30 days) | 20 | Paid after 30 July, ₹100 late fee each (different rule) |
| Partial payment | 30 | Paid only ₹400 of ₹800, status = Partial |
| Not paid | 20 | No collection recorded, status = Pending |

For the 50 late payments with ₹50 fines, the system auto-created fine detail records. For the 20 payments with ₹100 fines, the system used a different Fine Master rule.

Of the 30 partial payments, 10 of them pay the remaining ₹400 in August. When Mrs. Desai records the second payment, the fee master status changes from "Partial" to "Completed."

Total collected: ₹3,20,000 (300×₹800 + 50×₹850 + 20×₹900 + 30×₹400)

---

## Related Screens

- **Fee Creation (Invoicing)** — The fee records that collections are recorded against.
- **Fine Detail** — Late payment fines are auto-created here during collection.
- **Fine Master** — The rules used to calculate late payment fines.
- **Fee Log** — Every collection action is logged in the pay log.

---

## Requirements

- Controller: `FeeCollectionController` with CRUD + `export()`, `trashed()`, `restore()`, `forceDelete()`, `refreshFeeMasterStatus()`
- Model: `TptStudentFeeCollection` (table: `tpt_student_fee_collection`) — SoftDeletes
- Export: `FeeCollectionExport`
- Form Request: `FeeCollectionRequest`
- Permissions: `tenant.fee-collection.{viewAny,view,create,update,delete,restore,forceDelete}`
- Activity logging: ✅ Present on create, update, delete, restore, forceDelete
- Pay Log: ✅ Created on create, update, and delete actions
- Accounting integration: ✅ Sends `TPT_FEE_PAYMENT` event to `RemoteEntryService`

---

## Who Can Access

- **Transport Manager** — Full access. Can record, edit, delete, and export fee collections.

- **Accountant** — Full access. Can record, edit, delete, and export collections. Can also reconcile payments.

- **Fleet Supervisor** — Read-only access to view collection records.

- **School Administrator** — Read-only access for reporting.

Behind the scenes, each action is protected by a permission check.

---

## Logic Flow

When the user opens the Fee Collection tab, the system queries all `TptStudentFeeCollection` records with eager-loaded feeMaster and studentAllocation relationships, ordered by latest first, paginated.

When creating a collection:
1. The system loads the fee master record (to get amount, due date)
2. Delay days are calculated: `payment_date - due_date`
3. If a Fine Master rule is selected:
   a. The system checks if delay days fall within the rule's range
   b. Fine amount is calculated (Fixed or Percentage)
   c. If `student_restricted = 1`, the student is deactivated
   d. A `TptStudentFineDetail` record is created
4. The `TptStudentFeeCollection` record is created
5. `refreshFeeMasterStatus()` is called to update the fee master status
6. A `StudentPayLog` entry is created
7. An accounting event (`TPT_FEE_PAYMENT`) is sent
8. Activity log is written

When updating a collection:
1. The existing collection is fetched and updated
2. `refreshFeeMasterStatus()` is called
3. Pay log and activity log entries are created

When deleting a collection:
1. The collection is soft-deleted
2. `refreshFeeMasterStatus()` is called (status may revert)
3. Pay log and activity log entries are created

The `refreshFeeMasterStatus()` private method:
1. Counts the number of collections for the fee master
2. Sums the `paid_amount` across all collections
3. Sets status to "Completed" if total >= fee amount, "Partial" if > 0 but less than fee amount, or "Pending" if no collections exist

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Fee Master | Must exist and belong to a valid student | "Fee record not found." |
| Payment Date | Must be a valid date | "Please enter a valid payment date." |
| Paid Amount | Must be a positive number | "Please enter a valid paid amount." |
| Payment Mode | Must be one of: Cash, UPI, Card, Bank, Cheque | "Please select a valid payment mode." |
| Status | Must be valid | "Please select a valid status." |
| Reconciled | Must be 0 or 1 | "Please select reconciliation status." |
| Fine Master | Optional — if provided, must exist | "Fine rule not found." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Payment recorded for wrong fee master | Collection is attached to wrong invoice — must be deleted and re-entered | Data entry error |
| Accounting sync fails | Payment is still recorded — error is logged but not shown to user | Design choice (graceful degradation) |
| Fine master rule mismatch | If fine rule range does not match delay days, no fine is applied | Business rule (silent skip) |
| Partial payment recorded as full | System records whatever amount is entered — no partial/full validation | Design choice |
| Duplicate payment entry | System does not check if a payment for the same fee master already exists on the same date | 🔴 Gap — no duplicate check |
| Negative fine amount | If percentage fine calculation produces a negative (should not happen with proper rules), fine is negative | 🔴 Gap — no minimum=0 check |

---

## Success Scenarios — When Everything Works

**SC-001 — On-Time Full Payment**
Parent pays ₹800 on 10 July (before the 15 July due date). Mrs. Desai records the collection. Delay days = 0. No fine applied. Fee master status becomes "Completed." Pay log is created. Accounting event is sent.

**SC-002 — Late Payment with Auto Fine**
Parent pays ₹800 on 25 July (10 days late). Mrs. Desai selects the late fee rule (1-15 days, ₹50 fixed). System calculates 10 delay days, applies ₹50 fine, creates fine detail record. Collection total = ₹850. Fee master status becomes "Completed." Fine detail record is visible in the Fine Detail tab.

**SC-003 — Partial Payment with Later Settlement**
Parent pays ₹500 on 10 July. Status becomes Partial. Next month, parent pays ₹300. Second collection recorded for the same fee master. Status becomes Completed.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Late Fee Not Applied Due to Missing Fine Master Rule**
Mrs. Desai records a late payment on 25 July (10 days late) but does not select a Fine Master rule. The system creates the collection with delay_days = 10 but no fine detail record. The student pays only ₹800 instead of ₹850. The school loses ₹50 in late fee revenue.

**FC-002 — Wrong Payment Mode Recorded**
Mrs. Desai selects "Cash" instead of "UPI" as the payment mode. This is later discovered during reconciliation. She must edit the collection to correct the mode.

**FC-003 — Payment Recorded for Wrong Month**
Mrs. Desai accidentally selects the August fee record instead of July when recording a payment. The parent's July balance remains unpaid and shows as overdue. The August balance shows as paid even though the school is in July.