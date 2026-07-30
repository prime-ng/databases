# Fee Log — Business Requirements

## What This Screen Does

The Fee Log screen displays a read-only (with limited delete capability) history of every financial transaction that has occurred in the Transport module. It is the audit trail — a chronological record of who did what, when, and how much money was involved.

Every time a fee record is created, updated, deleted, restored, or force-deleted, and every time a payment is collected, updated, or deleted, an entry is written to the Student Pay Log table. This screen lets the Transport Manager and Accountant review that history, filter it by activity type or date, and verify that all financial actions are accounted for.

This screen appears as the fifth and last tab within the Student Route Fees Management section, directly loading the logs index view.

---

## Default Data Load

When the user opens the Fee Log tab, the system displays a paginated table of all `StudentPayLog` records where the module name is "Transport." Each row shows:
- Student name
- Academic session
- Log date and time
- Module name (always "Transport")
- Activity type (human-readable, e.g., "Fee Master Created")
- Description
- Amount in rupees
- Reference table name
- User who triggered the action
- Delete button (for users with delete permission)

Above the table, two filter controls are available:
- Activity Type dropdown: Filter by specific activity (e.g., "Fee Collected Create," "Fee Master Created," "Fine Details Updated," etc.)
- Date picker: Filter by a specific date

---

## When This Screen Is Used

- **Auditing Fee-Related Activities** — At the end of the month, Mrs. Desai reviews the fee log to ensure all fee creations, collections, and fine applications are properly recorded. She filters by "Fee Master Created" to see how many invoices were generated, then by "Fee Collected Create" to see how many payments were received.

- **Investigating a Discrepancy** — A parent claims they paid ₹800, but the system shows only ₹500 collected. Mrs. Desai opens the fee log and filters by the student's name. She sees a "Fee Collected Update" entry where the amount was changed from ₹800 to ₹500 with a description "Fee collected update." She investigates who made the change and why.

- **Tracking Deleted Records** — Mrs. Desai notices that a fee record is missing. She filters by "Fee Master Deleted" and sees that a user deleted a July fee record on a specific date. She can then check the Trash screen to restore it.

- **Verifying Fine Applications** — The school board wants to know how many late fees were applied in July. Mrs. Desai filters by "Fine Details Updated" to get a count of all fine applications.

- **Financial Reconciliation** — The accountant exports all fee log entries for July to cross-reference with the school's bank statements.

---

## Activity Types Tracked

The fee log tracks the following activity types (as seen in the filter dropdown):

| Activity Type | Meaning | Triggered By |
|--------------|---------|-------------|
| Fee Collected Create | A new payment was recorded | Fee Collection store |
| Fee Collected Update | A payment record was edited | Fee Collection update |
| Fee Collected Delete | A payment record was deleted | Fee Collection destroy |
| Fee Master Created | A new fee invoice was generated | Fee Master store |
| Fee Master Updated | A fee invoice was edited | Fee Master update |
| Fee Master Deleted | A fee invoice was moved to trash | Fee Master destroy |
| Fee Master Restored | A fee invoice was restored from trash | Fee Master restore |
| Fee Master Force Deleted | A fee invoice was permanently deleted | Fee Master forceDelete |
| Fee Master Status Changed | Fee invoice status toggled (Pending/Paid) | Fee Master toggleStatus |
| Fine Details Updated | A fine detail record was edited | Fine Detail update |
| Fine Details Deleted | A fine detail record was deleted | Fine Detail destroy |

Additionally, the transport module's other screens also write to this log:
- `fee_master_restored` — when a fee master is restored from trash
- `fine_deatils_updated` — when fine details are modified
- `fine_details_deleted` — when fine details are deleted
- `fine_master_restored` — when fine details are restored
- `fine_master_deleted` — when fine details are force-deleted
- `fee_master_created` — for student pay log creation
- `fee_collected_mobile` — for mobile app fee collections

---

## Key Fields at a Glance

**Student**
The student for whom the financial action was performed. Shows the student's first name (and last name if available).

**Academic Session**
The academic session this log entry belongs to. Shows the session's short name (e.g., "2025-26").

**Log Date**
The exact date and time when the action was performed. Displayed in `DD-MM-YYYY HH:MM` format.

**Module Name**
Always "Transport" for this screen. Helps differentiate transport logs from other module logs in the same table.

**Activity**
A human-readable version of the activity type. For example, `fee_collected_create` is displayed as "Fee Collected Create." Underscores are replaced with spaces, and the first letter of each word is capitalized.

**Description**
A brief explanation of what happened. Examples:
- "Transport Fee Master created"
- "Transport fee collected"
- "Transport Fee Master deleted"

**Amount**
The monetary amount involved in the transaction. Displayed with a ₹ symbol prefix. Shows "-" if no amount is associated (e.g., for a simple status change).

**Reference Table**
The database table that was affected. Examples:
- `tpt_fee_master`
- `tpt_student_fee_collection`
- `tpt_fine_details`

**User**
The name of the person who performed the action. This is the authenticated user's name at the time of the action.

---

## Business Rules and Conditions

**Read-Only by Default**
The Fee Log screen is primarily a viewing screen. The only action that can be performed is deleting individual log entries (if the user has `tenant.student-pay-log.delete` permission). There is no edit or create for log entries — they are system-generated.

**Log Entries Are Auto-Generated**
No user manually creates a log entry. Every entry is created programmatically by the controllers whenever a financial action is performed. The `TptStudentFineDetailController` also has a `destroyData()` method that allows deleting a log entry directly.

**Module Name Filter Is Implicit**
The log only shows entries where `module_name = 'Transport'`. This is hard-coded in the query and not exposed as a filter.

**Activity Type Filter Is Explicit**
The dropdown list includes all transport-specific activity types. If a new activity type is added in the future, the filter dropdown must be updated to include it.

**Delete Is Permanent**
When a log entry is deleted (through the delete button in the table), it is a soft delete (the `StudentPayLog` model uses `SoftDeletes`). However, the trash view for pay logs is not directly accessible from the Fee Log tab. The `destroyData()` method directly deletes the log by its ID.

---

## Workflow Steps

**Viewing the Fee Log**
Mrs. Desai clicks the Fee Log tab. The system loads the 20 most recent log entries, showing student name, date, activity, description, amount, and user. She scrolls through the pages to review all entries.

**Filtering by Activity Type**
Mrs. Desai wants to see how many payments were collected today. She selects "Fee Collected Create" from the activity dropdown and clicks the search button. The table updates to show only fee collection creation entries.

**Filtering by Date**
Mrs. Desai wants to see all activities for a specific date. She selects a date using the date picker and clicks search. The table updates to show only entries from that date.

**Deleting an Erroneous Log Entry**
Mrs. Desai notices a log entry that was created by mistake (e.g., a test entry). She clicks the delete button (trash icon) on that row. The system removes the entry from the log.

---

## Example Scenario

On 1 July, Mrs. Desai creates 420 fee master records for all transport students. This generates 420 "Fee Master Created" entries in the log.

Throughout the month, parents pay their fees. By 31 July:
- 300 on-time payments generate 300 "Fee Collected Create" entries
- 70 late payments generate 70 "Fee Collected Create" entries (each also creating a fine detail)

Some parents request changes:
- Mrs. Desai edits 5 fee records for rate corrections — 5 "Fee Master Updated" entries
- She deletes 1 incorrect fee record — 1 "Fee Master Deleted" entry
- She restores 1 fee record from trash — 1 "Fee Master Restored" entry

A dispute arises:
- A parent claims they paid ₹800 but the system shows ₹500. Mrs. Desai checks the log. She finds a "Fee Collected Update" entry where someone edited the amount from ₹800 to ₹500 on 20 July. The user who made the change is listed. She investigates further.

Total log entries for July: 799 entries.

---

## Related Screens

- **Fee Creation (Invoicing)** — Creates "Fee Master Created/Updated/Deleted" log entries.
- **Fee Collection** — Creates "Fee Collected Create/Update/Delete" log entries.
- **Fine Detail** — Creates "Fine Details Updated/Deleted" log entries.

---

## Requirements

- Model: `StudentPayLog` (table: `std_student_pay_log`) — SoftDeletes
- Data loaded via: `StudentRouteFeesController@studentPayLogQuery()` — passed to the logs index view
- Permissions: `tenant.student-pay-log.{viewAny,view,create,update,delete,restore,forceDelete}`
- Activity logging: Not needed (this IS the log)
- Delete functionality: Individual log entries can be soft-deleted from the UI
- Filtering: Activity type dropdown + date picker

---

## Who Can Access

- **Transport Manager** — Full read access to view all log entries. Can delete erroneous entries.

- **Accountant** — Full read access for audit and reconciliation purposes. Can delete entries if given delete permission.

- **Fleet Supervisor** — Read-only access to view log entries.

- **School Administrator** — Read-only access for audit and investigation purposes.

Behind the scenes, the tab itself is only shown to users with `tenant.student-pay-log.viewAny` permission.

---

## Logic Flow

When the user opens the Fee Log tab:
1. The `StudentRouteFeesController@index` method loads the main tab layout
2. The `studentPayLogQuery()` method queries `StudentPayLog::where('module_name', 'Transport')` with filters applied
3. The results are passed to the logs index view
4. The view renders a filter form (activity type dropdown + date) and a paginated table
5. The table iterates over the paginated results, showing each field with proper formatting

When filtering:
1. If an `activity_type` filter is selected, the query adds `->where('activity_type', $request->activity_type)`
2. If a `date` filter is selected, the query adds `->whereDate('log_date', $request->date)`
3. Paginated results are returned

When deleting a log entry:
1. The user clicks the delete button, which triggers a JavaScript confirmation
2. An AJAX or form request is sent to the `TptStudentFineDetailController@destroyData` endpoint (or directly via form submit)
3. The log entry is soft-deleted from the `std_student_pay_log` table
4. The table row is removed from the view

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Log ID (for delete) | Must exist in the pay log table | "Log not found." |
| Delete Permission | User must have `tenant.student-pay-log.delete` | Permission denied |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| No logs found for selected filter | "No logs found" message displayed | Expected behavior |
| Log entry deleted accidentally | Entry is gone — no way to undo (soft delete, but no restore UI on this tab) | 🔴 Gap — no restore from Fee Log tab |
| Activity type not in dropdown but exists in DB | Cannot filter by it — dropdown is hard-coded in the view | UI limitation |
| Large number of log entries (performance) | Pagination handles this, but very large datasets may slow loading | Potential performance issue |
| Delete button visible but action fails | User sees permission error even though button was shown | 🔴 Gap — permission check on button vs server |

---

## Success Scenarios — When Everything Works

**SC-001 — Monthly Audit Completed Successfully**
The accountant filters by "Fee Collected Create" for July and sees 370 entries. Cross-referencing with the bank statement shows total collected amount matches. All entries have correct student names, amounts, and dates. Audit is cleared.

**SC-002 — Discrepancy Investigated and Resolved**
A parent disputes a payment amount. Mrs. Desai finds the relevant "Fee Collected Update" entry showing that the amount was reduced from ₹800 to ₹500 by a specific user on a specific date. She speaks to that user, who confirms it was a data entry error. The correction is made, and the parent is satisfied.

**SC-003 — Deleted Fee Record Traced**
Mrs. Desai notices a missing fee invoice for student Aarav Sharma. She filters by "Fee Master Deleted" and finds an entry showing the deletion on 5 July. She goes to the Fee Creation Trash screen and restores the record. The log entry remains as evidence of the deletion.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Log Entry Deleted Without Trace**
A user with delete permission accidentally deletes a log entry that was needed for an audit. Since the log entry itself is now gone, there is no record of the deletion. The audit trail is broken.

**FC-002 — Missing Activity Type in Filter**
A new activity type is added to the system (e.g., "bulk_fee_created") but the filter dropdown in the log view is not updated. Users cannot filter by this new type through the UI, even though the entries exist in the database.

**FC-003 — Log Table Grows Too Large**
Over several academic years, the `std_student_pay_log` table grows to hundreds of thousands of entries. Queries for the Fee Log tab become slow. Pagination helps but loading the first page may take several seconds.