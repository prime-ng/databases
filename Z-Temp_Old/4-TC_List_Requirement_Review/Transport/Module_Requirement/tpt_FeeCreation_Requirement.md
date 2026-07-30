# Fee Creation (Invoicing) — Business Requirements

## What This Screen Does

The Fee Creation (Invoicing) screen generates monthly transport fee invoices for students who are registered for school transport. Each invoice — called a "Fee Master" record — represents the transport fee for one student for one month.

The screen answers the question: "How much does this student owe for transport this month, and has it been paid?" It is the billing heart of the Transport module. Every month (or whenever the school billing cycle runs), Mrs. Desai uses this screen to create fee entries for all active transport students. These entries are then used by the Fee Collection screen to record payments and by the Fee Log to track every change.

This screen appears as the second tab within the Student Route Fees Management section, loaded by the `FeeMasterController`.

---

## Default Data Load

When the user opens the Fee Creation tab, the system displays a paginated table of all fee master records. Each row shows the student's name, academic session, month, fee amount, fine amount (if any), total amount, due date, status (Pending / Partial / Paid / Completed), and options to view, edit, or delete.

Above the table, filter options allow the user to search by student name, month, status, or academic session.

---

## When This Screen Is Used

- **Generating Monthly Transport Fees** — At the beginning of each month, Mrs. Desai creates fee master records for all active transport students. She enters each student's monthly fee amount (₹800), selects the month (July 2026), sets a due date (15th of the month), and saves. The system creates a fee record with status "Pending."

- **Creating a Fee Record for a Mid-Session Enrollee** — A student joins in October. Mrs. Desai creates a fee record for October's transport fee. The due date is set to 15 October. The system calculates the total as fare + fine (fine is 0 for a new record).

- **Viewing a Student's Fee History** — A parent calls asking about their child's transport fee for the last 3 months. Mrs. Desai searches for the student and views each month's fee record. Each record shows the amount, whether it was paid, and links to the collection details and fine details.

- **Downloading a PDF Invoice** — The Finance department requests an invoice for a specific student. Mrs. Desai opens the fee record and clicks "Download PDF." The system generates a PDF showing the fee amount, any fines applied, collection history, and the current balance.

- **Editing a Fee Record After a Rate Change** — The school revises transport fees from ₹800 to ₹900 per month starting January. Mrs. Desai edits the January fee record for each student to update the amount. She also adjusts the total amount accordingly.

- **Bulk Import of Fee Records** — At the start of the session, Finance provides an Excel file with 500 student fee entries. Mrs. Desai uploads and validates the file, then imports all records at once.

---

## Key Fields at a Glance

**Student Academic Session**
Each fee master record is linked to a student's academic session. This determines which student the fee belongs to, what class they are in, and which academic year applies.

**Month**
The month for which the transport fee is being charged. Stored as a date (first day of the month, e.g., 1 July 2026). This allows the system to sort by month and filter by month range.

**Amount**
The base transport fee amount for the month. This comes from the student's allocation fare or is entered manually. For a standard student on the MG Road route, this would be ₹800.

**Fine Amount**
Any fine that has been applied to this fee record. At the time of creation, this is usually 0. Fines are added later through the Fee Collection screen when a payment is late, or through the Fine Detail screen.

**Total Amount**
The sum of the base amount and fine amount. For a record with ₹800 fee and ₹0 fine, the total is ₹800. For a late payment with a ₹50 fine, the total would be ₹850.

**Due Date**
The date by which the fee should be paid. Typically the 15th or 20th of the month. If the payment is made after this date, delay days are calculated (in the Fee Collection screen) and fines may apply.

**Status**
The payment status of this invoice:
- Pending: No payment has been received yet
- Partial: Some payment has been received but the total is not yet fully paid
- Paid/Completed: The full amount has been received

The status is automatically updated whenever a fee collection is created, updated, or deleted against this invoice.

**Remark**
An optional text field where Mrs. Desai can note anything relevant — for example, "Fee waived for October due to leave" or "Updated after rate revision."

---

## Business Rules and Conditions

**Fee Records Are Student-Specific**
Each fee master record belongs to exactly one student and one month. There are no batch or group fee records. If the school has 500 transport students, there will be 500 fee records per month.

**Status Is Automatically Managed**
The fee master status is not set directly by the user during creation — it defaults to "Pending." When payments are recorded in the Fee Collection screen, the `refreshFeeMasterStatus()` method recalculates the status:

| Condition | Status |
|-----------|--------|
| No payments received | Pending |
| Some payment received, not full | Partial |
| Full amount collected | Completed |

This recalculation happens every time a fee collection is stored, updated, or deleted.

**Fine Amount Is Set During Collection, Not During Creation**
When creating a fee record, the fine amount is typically 0. Fines are calculated and applied during the Fee Collection process — when the payment date is after the due date, the system looks up the Fine Master rules to calculate the applicable late fee.

**Deleting a Fee Record Also Deletes Its Collections**
When a fee master record is deleted (soft delete), the system also soft-deletes all associated fee collection records. This prevents orphaned collection records. When the fee master is restored, the associated collections are also restored.

**Pay Log Is Created for Every Action**
Every create, update, delete, restore, force delete, and status change of a fee master record generates a corresponding entry in the Student Pay Log table. This provides a complete audit trail.

**Import Validates Against Existing Students**
When importing fee records via Excel, the system validates each row's roll number against the Student Academic Session table. If the roll number does not match any current student, the row is rejected.

---

## Workflow Steps

**Creating a Single Fee Invoice**
Mrs. Desai clicks the Create button. She selects a student from the academic session dropdown. She enters the month (July 2026). She enters the fee amount (₹800). The fine amount field is pre-filled as 0. She enters the total amount (₹800). She sets the due date (15 July 2026). She can optionally add a remark. She clicks Save. The system creates the fee record with status "Pending" and logs the action in the pay log.

**Editing a Fee Invoice**
Mrs. Desai clicks Edit on an existing fee record. She changes the amount from ₹800 to ₹900 (after a fee revision). She updates the total amount to ₹900. She saves. The system updates the record and creates a "fee_master_updated" entry in the pay log.

**Deleting a Fee Invoice**
Mrs. Desai clicks Delete on a fee record that was created by mistake. The system soft-deletes the fee record and all its associated collections. Both are moved to the Trash. The activity is logged.

**Restoring a Fee Invoice from Trash**
Mrs. Desai opens the Trash screen, finds the deleted fee record, and clicks Restore. The system restores both the fee record and its associated collections. The activity is logged.

**Downloading a PDF Invoice**
Mrs. Desai opens a fee record and clicks "Download PDF." The system generates a PDF document containing:
- School name and header
- Student name, class, and admission number
- Month and due date
- Fee amount, fine amount, and total
- Collection history (date, amount, mode)
- Current balance

---

## Example Scenario

Green Valley School charges ₹800 per month for transport. On 1 July, Mrs. Desai creates fee records for all 420 active transport students. She enters each student's fee manually (or uses the import feature). All records have status "Pending" with a due date of 15 July.

By 20 July, 350 students have paid. Their fee record statuses have been automatically updated to "Completed" by the Fee Collection process. 50 students have partially paid — their status shows "Partial." 20 students have not paid — their status remains "Pending."

For the 20 students who haven't paid, Mrs. Desai checks the Fine Master rules. Since 5 days have passed since the due date, a late fee of ₹50 per student applies. When those students eventually pay, the system will calculate the fine automatically.

---

## Related Screens

- **Student Transport Allocation** — Fare amounts from allocations are used as the base fee.
- **Fee Collection** — Payments are recorded against fee master records.
- **Fine Detail** — Fines applied to fee records are visible here.
- **Fee Log** — Every action on fee records is logged in the pay log.

---

## Requirements

- Controller: `FeeMasterController` with CRUD + `toggleStatus()`, `downloadPdf()`, `validateFile()`, `startImport()`, `export()`
- Model: `TptFeeMaster` (table: `tpt_student_fee_detail`) — SoftDeletes
- Import: `FeeMasterImport`, `FeeMasterReadOnly`
- Export: `FeeMasterExport`
- Form Request: `FeeMasterRequest`
- PDF: Barryvdh\DomPDF for invoice PDF generation
- Permissions: `tenant.fee-master.{viewAny,view,create,update,delete,restore,forceDelete,import,export,pdf}`
- Activity logging: ✅ Present on create, update, delete, restore, forceDelete, toggleStatus
- Pay Log: ✅ Created on every action (create, update, delete, restore, forceDelete, toggleStatus)

---

## Who Can Access

- **Transport Manager** — Full access. Can create, edit, delete, import, export, download PDF, and toggle status.

- **Accountant** — Can view, export, and download PDF invoices. Cannot create or edit fee records.

- **Fleet Supervisor** — Read-only access to view fee records for informational purposes.

- **School Administrator** — Read-only access for reporting.

Behind the scenes, each action is protected by a permission check.

---

## Logic Flow

When the user opens the Fee Creation tab, the system queries all `TptFeeMaster` records with eager-loaded academic session and student details, paginated.

When creating, the user selects an academic session (student). The month is entered as a date picker. The amount, fine amount, total, due date, and remark are entered. On save:
1. The system creates the `TptFeeMaster` record
2. The `amount` is stored, `fine_amount` defaults to 0, `total_amount` = amount + fine
3. The status defaults to `Pending`
4. A `StudentPayLog` entry is created with `activity_type = 'fee_master_created'`
5. The activity log is written

When updating:
1. The record is fetched and updated with the new values
2. A `StudentPayLog` entry is created with `activity_type = 'fee_master_updated'`
3. The activity log is written

When deleting:
1. The system loads the fee master with its fee collections
2. In a transaction, all fee collections are soft-deleted, then the fee master is soft-deleted
3. Pay log and activity log entries are created

PDF download:
1. The system loads the fee master record, its associated fee collections, and fine details
2. The PDF view renders all this data in a printable A4 portrait document
3. The PDF is returned as a downloadable file

Import:
1. The Excel file is uploaded and read into an array
2. Each row is validated for roll number, month, fee amount, due date, fine amount, total amount
3. If errors are found, a text report is downloaded with all error details
4. If validation passes, the file is stored in session and the import process creates all fee records

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Student Academic Session | Must exist in the system | "Please select a valid student." |
| Month | Must be a valid date (first of month) | "Please enter a valid month." |
| Amount | Must be a positive number | "Please enter a valid fee amount." |
| Due Date | Must be a valid date | "Please enter a valid due date." |
| Fine Amount | Optional — must be numeric if provided | "Please enter a valid fine amount." |
| Total Amount | Optional — must be numeric if provided | "Please enter a valid total amount." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Duplicate fee record for same student and month | System does not prevent this — two records could exist | 🔴 Gap — no unique constraint on student+month |
| Fee record deleted while collections exist | Collections are soft-deleted along with the fee record | Cascade handling (by design) |
| Fee amount set to zero or negative | System accepts it — no minimum check | 🔴 Gap — no minimum fee validation |
| Due date in the past | System accepts it — fine calculation will apply immediately | Design choice (allows back-dated entries) |
| Import with invalid roll numbers | Error report downloaded showing "Invalid Student Roll Number" | Validation by design |
| Month stored incorrectly | If user enters a date that is not the first of the month, the system converts it to start of month | Auto-correction |

---

## Success Scenarios — When Everything Works

**SC-001 — Monthly Fee Records Created for All Students**
Mrs. Desai creates fee records for all 420 active transport students for July. Each record has ₹800 fee, 0 fine, ₹800 total, due 15 July, status Pending. The system logs all creations.

**SC-002 — Fee Record Updated After Rate Revision**
The school revises transport fees to ₹900. Mrs. Desai edits the August fee records for all students, changing the amount to ₹900 and total to ₹900. Each update is logged.

**SC-003 — Fee Record Downloaded as PDF**
The accountant requests Priya Sharma's July fee invoice. Mrs. Desai opens the record and clicks Download PDF. The system generates a clean PDF with Priya's details, the fee amount, due date, and payment status.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Duplicate Fee Records Created**
Mrs. Desai accidentally creates two fee records for the same student for July. Both show ₹800 fee, Pending status. The student now appears to owe ₹1,600 instead of ₹800. Mrs. Desai must manually delete the duplicate and explain to the parent why the invoice showed the wrong amount.

**FC-002 — Incorrect Fee Amount Entered**
Mrs. Desai enters ₹8,000 instead of ₹800 for a student's fee. The invoice is sent to the parent showing ₹8,000 due. The parent complains. Mrs. Desai must edit the record and send a corrected invoice.

**FC-003 — Import Accepts Invalid Month Format**
During import, a row has the month column in DD-MM-YYYY format instead of MM-YYYY. The system may misinterpret the date, storing the wrong month. The student receives an invoice for the wrong month.