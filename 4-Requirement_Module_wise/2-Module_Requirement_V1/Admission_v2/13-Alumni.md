# Alumni — Business Requirements

## What This Screen Does

The Alumni screen lists students who have been flagged as alumni — typically those who have graduated from the school. Within the Promotions & Alumni tab group, this tab shows a searchable table of former students with their graduation year, last class attended, and current status.

Alumni status is typically assigned through the Promotion Records screen (when a student's promotion result is "Alumni") or manually from this tab.

---

## When This Screen Is Used

- End of academic year: Admin reviews the list of graduating students
- Alumni outreach: School administration needs contact information for alumni events
- Alumni verification: Admin verifies that promoted students have been correctly flagged as alumni
- Manual flagging: Admin needs to mark a specific student as alumni

---

## Key Fields at a Glance

**Student Name**
The full name of the former student.

**Last Class Attended**
The class from which the student graduated (e.g., Class XII).

**Graduation Year**
The academic session in which the student completed their studies.

**Current Status**
Alumni — the student has graduated.
Note: Other statuses (Promoted, Detained, Transferred, Left) may appear if the tab also shows all non-current students.

**Contact Information**
Parent/guardian phone and email for alumni outreach.

---

## Business Rules and Conditions

**Source of Alumni Records**
Most alumni records are created automatically when a promotion record has result "Alumni" and the batch is confirmed.

**Read-Only by Default**
Alumni records are primarily for viewing and search. Editing is limited to contact information updates.

**No Re-Enrollment Check**
If an alumni student re-enrolls, the system should handle this case (typically creating a new enrollment rather than re-activating the alumni record).

---

## Workflow Steps

**Viewing the Alumni List**
Admin navigates to the Alumni tab. The table displays all alumni with search and filter options (by graduation year, last class, etc.).

**Searching for an Alumni**
Admin uses the search box to find a specific student by name. Filters can narrow by graduation year or class.

**Viewing Alumni Details**
Admin clicks on a student name to open their student profile, showing full academic history.

---

## Example Scenario

After confirming the Class XII → Alumni promotion batch, 120 students are marked as alumni. The admin visits the Alumni tab to verify:
- 120 alumni records exist
- Each shows the correct graduation year (2026-27) and last class (Class XII)
- Contact information is complete for all 120

---

## Related Screens

- **Promotion Records** — Students are flagged as alumni via promotion results
- **Batch Confirmation** — Alumni status is applied when a promotion batch is confirmed
- **Transfer Certificates** — Alumni may request TCs after graduation
