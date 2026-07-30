# Fine Detail — Business Requirements

## What This Screen Does

The Fine Detail screen shows a list of all fines that have been applied to student transport fee records. A fine in this context is a penalty amount added to a student's transport fee — typically for late payment, but it can also be for other reasons defined in the Fine Master rules.

Each fine detail record links a specific Fine Master rule to a specific fee invoice. It records how many days the payment was delayed, the fine rate that was applied, the original fine amount, any waived amount, and the net amount the student must pay.

Fines can be created in two ways:
- **Automatically during Fee Collection** — When a payment is recorded and the payment date is after the due date, the system checks the Fine Master rules to calculate the applicable late fee. If a rule matches the delay period, a fine detail record is created automatically.
- **Manually** — The Transport Manager can create or edit fine details directly through this screen.

This screen appears as the third tab within the Student Route Fees Management section, loaded by the `TptStudentFineDetailController`.

---

## Default Data Load

When the user opens the Fine Detail tab, the system displays a paginated list of all fine detail records. Each row shows the student's name, month, fee amount, fine category, fine amount, waived amount, net fine amount, remark, and the date the fine was applied. Filters allow searching by student name, month, or fine category.

---

## When This Screen Is Used

- **Reviewing Late Payment Fines** — Mrs. Desai notices that several students' payments are overdue. She opens the Fee Collection screen to process payments, and the system automatically creates fine details for each late payment. She then opens the Fine Detail tab to review the applied fines and confirm they are correct.

- **Waiving a Fine** — A parent calls to explain that the payment was late because the school's online payment system was down. Mrs. Desai opens the relevant fine detail record, enters a waived amount equal to the fine amount (bringing the net fine to ₹0), and adds a remark: "Waived due to system issue." The student's fee balance is adjusted accordingly.

- **Creating a Manual Fine** — A student has repeatedly violated bus conduct rules. Mrs. Desai creates a manual fine detail record against the student's latest fee invoice, selecting a Fine Master rule for "Misconduct" and setting the fine amount.

- **Editing an Incorrect Fine** — The system calculated a fine of ₹100, but according to the school's policy, it should have been ₹50. Mrs. Desai edits the fine detail, changes the fine amount to ₹50, and enters a correcting remark.

- **Deleting an Incorrectly Applied Fine** — A fine was applied to the wrong student's fee record. Mrs. Desai deletes the fine detail record, which moves it to the Trash. She can restore it later if needed.

---

## Key Fields at a Glance

**Fee Master Reference**
Each fine detail record is linked to a `tpt_student_fee_detail` record (the Fee Master invoice). This connects the fine to a specific student, month, and fee amount.

**Fine Master Rule Reference**
The specific Fine Master rule that triggered this fine. This provides the context: was this a late payment fine, a misconduct fine, or some other type? The rule determines the fine type (Fixed or Percentage) and the rate.

**Fine Days**
The number of days the payment was delayed. For late payment fines, this is calculated as the difference between the payment date and the due date. For manual fines (like misconduct), this may be 0.

**Fine Type**
Whether the fine is "Fixed" (a flat amount like ₹50) or "Percentage" (a percentage of the fee amount, like 2% of ₹800 = ₹16).

**Fine Rate**
The rate used to calculate the fine. For Fixed fines, this is the flat amount. For Percentage fines, this is the percentage value.

**Fine Amount**
The calculated fine amount before any waiver. For a Fixed fine of ₹50, this is ₹50. For a 2% Percentage fine on an ₹800 fee, this is ₹16.

**Waived Fine Amount**
The portion of the fine that has been waived. If the full fine is waived, this equals the fine amount and the net fine becomes ₹0.

**Net Fine Amount**
The fine amount minus the waived amount. This is what the student actually owes. Calculated automatically as `fine_amount - waved_fine_amount`.

**Remark**
An optional text field explaining why the fine was applied or why it was waived.

---

## Business Rules and Conditions

**Fine Calculation Uses Fine Master Rules**
When a fine is automatically created during fee collection, the system looks up the `TptFineMaster` table for rules where the delay days fall within the `fine_from_days` and `fine_to_days` range. If a matching rule is found, the fine is calculated using that rule's type and rate:
- Fixed: `fine_amount = fine_rate` (e.g., ₹50 flat)
- Percentage: `fine_amount = (fee_amount * fine_rate) / 100` (e.g., 2% of ₹800 = ₹16)

**Student Restriction Flag**
Some Fine Master rules have a `student_restricted = 1` flag. When such a rule is applied, the system does not just add a fine — it also deactivates the student's account (sets `is_active = 0`). This is a punitive measure for serious violations where the school wants to temporarily suspend the student's transport access until the fine is resolved.

**Fines Are Optional During Collection**
When recording a fee collection, the user can optionally select a Fine Master rule. If no rule is selected, no fine detail is created. The delay days are still calculated and stored on the collection record, but no fine amount is applied.

**Net Fine Is Always Calculated**
The net fine amount is always `fine_amount - waved_fine_amount`. The system calculates this on save. If no waiver is applied, the net equals the fine amount. If the full amount is waived, the net is 0.

**Deleting a Fine Details Record**
When a fine detail is deleted (soft delete), the corresponding fee master's status is not automatically recalculated. The Transport Manager must manually review and adjust the fee status if needed.

---

## Workflow Steps

**Auto-Creating a Fine During Fee Collection**
A parent pays ₹800 for July's transport fee on 25 July. The due date was 15 July — a delay of 10 days. The system checks the Fine Master table: there is a rule for 1-15 days late, Fixed fine of ₹50. The system creates a fine detail record with fine_days = 10, fine_type = Fixed, fine_rate = 50, fine_amount = 50, waved_fine_amount = 0, net_fine_amount = 50. The student's total due becomes ₹850.

**Waiving a Fine**
Mrs. Desai opens the fine detail record for the student mentioned above. The parent had a genuine reason for the delay. She enters waved_fine_amount as 50 (full waiver). The net_fine_amount automatically recalculates to 0. She adds a remark: "Waived - parent was out of town." The student now owes only the original ₹800.

**Manually Creating a Fine**
A student, Arjun, has been consistently disobeying the bus conductor. Mrs. Desai opens the Fine Detail create screen. She selects Arjun's July fee record. She selects a Fine Master rule for "Misconduct" (which is a Fixed ₹200 fine with student_restricted = 1). She saves. The system creates the fine detail and deactivates Arjun's student account. Arjun cannot use school transport until the fine is resolved and his account is reactivated.

**Editing a Fine Detail**
The system calculated a fine of ₹100 for a 20-day delay, but the Fine Master rule says the fine for 15-30 days should be ₹75. Mrs. Desai edits the fine detail, changes the fine_amount to 75, and the net_fine_amount updates to 75. She adds a remark: "Corrected fine amount per Fine Master rule."

**Deleting a Fine Detail**
A fine was applied to the wrong student. Mrs. Desai deletes it. The record moves to the Trash. She can view the Trash screen to see all deleted fine details and restore them if needed.

---

## Example Scenario

Green Valley School's transport fee due date is the 15th of each month. In July, 420 students have fee records. By the 20th of July:
- 350 students paid on time — no fines
- 50 students paid 1-15 days late — each gets a Fixed ₹50 late fee
- 20 students have not paid yet — fines will apply when they pay

Of the 50 students who paid late, 5 parents call to request waivers:
- 3 waivers are approved (system issue, parent travel)
- 2 waivers are denied (no valid reason)

Mrs. Desai processes the approved waivers through the Fine Detail screen. For the 3 approved waivers, she sets waved_fine_amount = 50 and net_fine_amount = 0 with appropriate remarks. The 2 denied waivers remain unchanged.

For the 20 students who haven't paid, when they eventually pay after 30+ days, a higher Fine Master rule may apply — perhaps ₹100 for 16-30 days delay.

---

## Related Screens

- **Fee Creation (Invoicing)** — Fine details are linked to fee master records.
- **Fee Collection** — Fines are typically created during the collection process.
- **Fine Category** — The categories that classify fines (Late Fee, Misconduct, etc.).
- **Fine Master** — The rules that define fine rates and conditions.
- **Fee Log** — All fine detail actions are logged in the pay log.

---

## Requirements

- Controller: `TptStudentFineDetailController` with CRUD + `trashed()`, `destroyData()`
- Model: `TptStudentFineDetail` (table: `tpt_student_fine_detail`) — SoftDeletes
- Permissions: `tenant.fine-detail.{viewAny,view,create,update,delete,restore,forceDelete}`
- Activity logging: ✅ Present on create, update, delete, restore, forceDelete
- Pay Log: ✅ Created on update, delete, restore, forceDelete actions

---

## Who Can Access

- **Transport Manager** — Full access. Can create, edit, delete, restore, and force-delete fine details. Can also waive fines.

- **Accountant** — Can view fine details and export them for financial reporting. Cannot create, edit, or waive fines.

- **Fleet Supervisor** — Read-only access to view applied fines.

- **School Administrator** — Read-only access for reviewing fine-related disputes.

Behind the scenes, each action is protected by a permission check.

---

## Logic Flow

When the user opens the Fine Detail tab, the system queries all `TptStudentFineDetail` records with eager-loaded feeMaster and fineMasterRule relationships, paginated.

When a fine is created during fee collection (auto-creation):
1. The fee collection process calls the store method with the fee master ID and fine master ID
2. The system loads the fee master (to get amount and due date)
3. Delay days are calculated as `payment_date - due_date`
4. The fine master rule is loaded; if delay days fall within the rule's range, the fine is calculated
5. If `student_restricted = 1`, the student's `is_active` flag is set to 0
6. The fine detail record is created with all calculated values
7. Pay log and activity log entries are created

When the user manually creates a fine detail (via the create screen):
1. The user selects a fee master record and a fine master rule
2. The system creates the fine detail with the rule's fine type, rate, and calculated amount
3. Pay log and activity log entries are created

When the user edits a fine detail:
1. The old record is fetched
2. The fine amount, waived amount, net amount, and remark are updated
3. Net amount is recalculated automatically
4. Pay log and activity log entries are created

When the user deletes a fine detail:
1. The record is soft-deleted
2. Pay log and activity log entries are created

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Fee Master ID | Must exist in the fee master table | "Fee record not found." |
| Fine Master ID | Must exist in the fine master table | "Fine rule not found." |
| Fine Days | Must be a valid number | "Please enter valid delay days." |
| Fine Amount | Must be a valid number | "Please enter a valid fine amount." |
| Waived Amount | Must be a valid number (0 or more) | "Please enter a valid waived amount." |
| Net Fine Amount | Auto-calculated — no user input | Must equal fine_amount minus waved_fine_amount |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Fine applied to wrong fee record | Fine is attached to that record — must be manually deleted | Data entry error |
| Waived amount exceeds fine amount | System does not prevent this — net fine could go negative | 🔴 Gap — no validation that waived ≤ fine |
| Fine created without a fee master record | System requires fee_master_id — cannot create orphan records | Proper FK constraint |
| Student account deactivated by fine | Student cannot use transport until account is reactivated manually | Design behavior |
| Duplicate fine for same fee record and rule | System does not prevent duplicate fines | 🔴 Gap — no unique check |

---

## Success Scenarios — When Everything Works

**SC-001 — Late Fee Automatically Applied**
A parent pays on 25 July (10 days late). The system automatically calculates a ₹50 late fee and creates a fine detail record. The student's total due is now ₹850. The fee master status is updated to "Partial" if only the fee amount was paid, or "Completed" if the full ₹850 was paid.

**SC-002 — Fine Waived for Valid Reason**
A parent provides a valid reason for late payment. Mrs. Desai opens the fine detail, sets waived amount = ₹50, net fine = ₹0, and adds a remark. The student's balance returns to the original fee amount.

**SC-003 — Misconduct Fine with Student Restriction Applied**
A student misbehaves on the bus. Mrs. Desai creates a manual fine of ₹200 using the "Misconduct" rule (student_restricted = 1). The fine is applied, and the student's account is deactivated. The student cannot board the bus until the fine is resolved.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Inconsistent Fine Calculation**
A student pays on day 16 (the 16th day after the due date). The Fine Master has one rule for 1-15 days (₹50) and another for 16-30 days (₹100). The Fee Collection process should apply the ₹100 rule, but if the delay calculation uses the wrong date (counting inclusive vs exclusive), the wrong fine may be applied.

**FC-002 — Fine Applied to Wrong Fee Record**
During fee collection, the user selects the wrong fee master record. The fine is applied to a different student's fee. The correct student has no fine, and the wrong student shows an unexpected charge.

**FC-003 — Student Restriction Not Reversed After Fine Resolution**
A student's account was deactivated due to a misconduct fine. The parent pays the fine. However, there is no automatic process to reactivate the student's account. The Transport Manager must manually toggle the student's status back to active. Until then, the student cannot board the bus.