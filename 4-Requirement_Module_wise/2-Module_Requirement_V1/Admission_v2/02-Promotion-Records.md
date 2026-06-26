# Promotion Records — Business Requirements

## What This Screen Does

The Promotion Records screen is the detailed working area within a promotion batch. This is where the admin manages each student's promotion outcome individually. The screen shows a table of all students who have been added to the batch, with their promotion details — from which section they are moving, to which section they are going, what the result is (Promoted, Detained, etc.), and any new roll number assigned.

The screen also has an Add/Edit form on the side where the admin can select a student, choose their current section, choose their target section, set the result, and enter optional details like new roll number and remarks.

Think of this as the "promotion checklist" — the admin goes through each student, assigns their promotion outcome, and can make changes freely until the batch is confirmed.

---

## When This Screen Is Used

- Admin has created a promotion batch and now needs to add individual student records
- Admin wants to update a student's promotion result (e.g., change from Promoted to Detained)
- Admin needs to change which target section a promoted student will join
- Admin wants to assign a new roll number to a promoted student
- Admin needs to remove a student from the batch (delete the record)
- Admin wants to toggle a student's active status (temporarily disable/enable a record)

---

## Key Fields at a Glance

**Student**
The student being promoted. Selected from a dropdown list of eligible students — those currently enrolled in the batch's from-class with an active academic session.

**From Section**
The student's current class-section (e.g., Class III - A). This is auto-populated from the student's current academic session if not manually selected. The dropdown only shows sections belonging to the batch's from-class.

**To Section**
The target class-section the student will join after promotion (e.g., Class IX - A). This MUST be explicitly selected by the admin from a dropdown of sections belonging to the batch's to-class. The system does NOT auto-resolve this field.

**Result**
The promotion outcome: Promoted, Detained, Transferred, Alumni, or Left. Each result has a distinct color-coded badge in the table.

**New Roll No**
An optional new roll number to assign to the student in their new class-section.

**Active Status**
Toggle to mark the record as active or inactive. Inactive records are excluded from batch confirmation processing.

**Remarks**
Optional notes about the promotion decision.

---

## Business Rules and Conditions

**Eligible Students Only**
Only students with a current active academic session (`is_current = true`) in the batch's from-class appear in the student dropdown. Students must have a valid `StudentAcademicSession` record.

**From Section Auto-Resolve**
If the admin does not select a from-section, the system automatically resolves it from the student's current academic session record. If no current session is found, the system throws an error and the record cannot be saved.

**To Section Is Mandatory for Promoted**
Students with result "Promoted" must have a to-section selected. Records promoted without a to-section are ignored during batch confirmation.

**Unique Student Per Batch**
Each student can only appear once in a batch. If the admin tries to add a student who already has a record, the existing record is updated instead.

**Duplicate Prevention via updateOrCreate**
The system uses `updateOrCreate` on `(promotion_batch_id, student_id)` — so adding the same student twice updates the existing record rather than creating a duplicate.

**Empty to Null Conversion**
Form fields left empty (from-section, to-section, new roll no) are automatically converted from empty string to null before saving to prevent MySQL integer type errors.

**Soft Delete on Records**
Records can be soft-deleted individually. Deleted records are removed from the table view and excluded from batch confirmation.

**Status Toggle**
Each record has an active/inactive toggle switch. Inactive records remain in the table but are excluded from batch confirmation processing. The toggle works via AJAX without page refresh.

---

## Workflow Steps

**Adding a Student Record**
Admin opens the promotion batch show page. On the right side, the Add Student Record form is displayed. Admin selects a student from the dropdown, chooses their from-section (optional — auto-resolves if left blank), selects the to-section (mandatory for Promoted), chooses the result, optionally enters a new roll number and remarks, and clicks Save.

The record appears in the table immediately via AJAX — no page refresh needed.

**Editing a Student Record**
Admin clicks the Edit button on any record row. The form on the right populates with the record's data (student, from-section, to-section, result, roll number, remarks). Admin makes changes and clicks Save. The table row updates in-place via AJAX.

**Deleting a Student Record**
Admin clicks the Delete button on any record row. A confirmation dialog appears. Admin confirms, and the row fades out and is removed via AJAX. The record is soft-deleted in the database.

**Toggling Active Status**
Admin clicks the active/inactive toggle switch on any record row. The status updates via AJAX without page refresh. A toast notification confirms the change.

**Viewing All Records in a Batch**
The Promotion Records table shows all records in the batch with columns: student name, from-section, to-section, result (color-coded badge), new roll number, active status (toggle or badge), and action buttons (edit, delete).

---

## Example Scenario

A batch promotes 64 students from Class III to Class IX. The school has two Class III sections (A, B) and three Class IX sections (A, B, C).

Admin opens the batch and starts adding records:
1. Selects "Aadil Saurabh Baral" from the student dropdown
2. From Section dropdown shows "Class III - A" and "Class III - B" — selects "Class III - A"
3. To Section dropdown shows "Class IX - A", "Class IX - B", "Class IX - C" — selects "Class IX - A"
4. Result: "Promoted"
5. New Roll No: "15"
6. Clicks Save

The record appears in the table immediately with green "Promoted" badge. Admin continues adding all 64 students. After reviewing, admin confirms the batch — all Promoted students with to-sections get new academic session records created.

---

## Related Screens

- **Promotion Batch** — The parent batch that contains these records
- **Batch Confirmation** — Finalizes all records and creates academic sessions for promoted students
