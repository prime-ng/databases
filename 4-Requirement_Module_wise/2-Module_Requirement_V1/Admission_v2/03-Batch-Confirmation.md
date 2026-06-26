# Batch Confirmation — Business Requirements

## What This Screen Does

The Batch Confirmation action is the final step in the promotion workflow. When the admin is satisfied with all student promotion records in a batch, they confirm the batch to make the promotions official. Confirmation transitions the batch from Draft to Confirmed status and writes new academic session records for all Promoted students.

Think of this as the "publish" button — once confirmed, the promotions take effect in the system. Students who are marked as Promoted get enrolled in their new class-sections with their new roll numbers. Students marked as Detained, Transferred, Alumni, or Left are recorded for historical reference but do not get new academic sessions created.

---

## When This Screen Is Used

- Admin has added all student records to a promotion batch and reviewed them
- Admin is satisfied with the promotion outcomes and wants to finalize them
- End of academic year processing: all batches need to be confirmed before the new session starts
- Note: This action is irreversible — once confirmed, the batch cannot be edited

---

## Key Actions at a Glance

**Confirm Batch**
The primary action button. When clicked, the system validates that there is at least one Promoted record with a target section, then creates `StudentAcademicSession` records for each Promoted student. The batch status changes from Draft to Confirmed.

**Cancel Batch**
The alternative action. When clicked, all promotion records are deleted and the batch itself is deleted. This is used when the promotion plan changes completely and a fresh start is needed.

---

## Business Rules and Conditions

**Draft Batches Only**
Only batches in Draft status can be confirmed or cancelled. Already Confirmed batches cannot be modified.

**At Least One Promoted Record Required**
The system requires at least one student with result "Promoted" and a non-null `to_class_section_id`. If no such records exist, the confirmation is blocked with an error message.

**Idempotent Session Creation**
When creating new `StudentAcademicSession` records, the system uses `firstOrCreate` on `(student_id, academic_session_id, class_section_id)`. If a record already exists (e.g., the student was already enrolled in this session/section), it is not duplicated. This makes the confirmation action safe to retry.

**Cross-Module Write**
Confirmation writes to `std_student_academic_sessions` in the StudentProfile module. This is a cross-module dependency and must be handled within a database transaction to ensure consistency.

**Audit Trail**
When a batch is confirmed, an activity log entry is created recording the number of students promoted. When cancelled, a cancellation log entry is created.

**No Rollback**
Once confirmed, the batch cannot be reverted to Draft. If corrections are needed, the admin must create a new batch and manually adjust academic sessions.

---

## Workflow Steps

**Confirming a Batch**
Admin clicks the "Confirm Batch" button on the promotion batch show page (Quick Actions card). A confirmation dialog appears: "Confirm this promotion batch? This will update student academic sessions." Admin clicks OK.

The system processes all Promoted records with target sections inside a database transaction:
1. For each record, it creates a new `StudentAcademicSession` with:
   - `student_id` from the record
   - `academic_session_id` from the batch's `to_session_id`
   - `class_section_id` from the record's `to_class_section_id`
   - `roll_no` from the record's `new_roll_no` (if set)
   - `is_current = true`
2. The batch status is updated to Confirmed
3. A success message is shown: "Promotion batch confirmed. Student sessions updated."

**Cancelling a Batch**
Admin clicks the "Cancel Batch" button. A confirmation dialog appears: "Cancel this batch? This action cannot be undone." Admin clicks OK.

The system:
1. Deletes all promotion records associated with the batch
2. Deletes the batch itself
3. Redirects to the promotions list page with a success message

---

## Example Scenario

After adding all 64 student records to the Class III → Class IX promotion batch, the admin reviews the table:
- 55 students: Promoted (with target sections assigned)
- 5 students: Detained
- 3 students: Transferred
- 1 student: Left

The admin clicks "Confirm Batch". The system creates 55 new `StudentAcademicSession` records — one for each Promoted student — in the 2027-28 session with their assigned class-sections and roll numbers. The batch status changes to Confirmed. The show page now displays "Confirmed" instead of "Draft", and the Add/Edit/Delete buttons are hidden.

---

## Related Screens

- **Promotion Batch** — The batch header showing current status
- **Promotion Records** — All records must be finalized before confirmation
- **StudentProfile** — The target module where academic sessions are written
