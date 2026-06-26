# Promotion Batch — Business Requirements

## What This Screen Does

The Promotion Batch screen is where the school admin creates and manages class-to-class promotion campaigns. A promotion batch represents the transition of a group of students from one class and academic session to another — for example, promoting all Class III students (Session 2026-27) to Class IX (Session 2027-28).

Think of a promotion batch as a container: the admin defines the source class, target class, and sessions, then opens the batch to add individual student records (Promotion Records). Once all students are mapped with their results (Promoted, Detained, Transferred, etc.), the admin confirms the batch to finalize the promotions.

---

## When This Screen Is Used

- End of academic year: Admin needs to promote students from their current class to the next class
- Admin wants to create separate batches for different class transitions (e.g., Class III→IV and Class V→VI)
- Admin needs to review promotion statistics before finalizing (how many promoted, detained, transferred)
- Admin wants to cancel a batch if the promotion plan changes

---

## Key Fields at a Glance

**Source Session**
The academic session the students are currently in (e.g., 2026-27). This determines which session's data is used for eligibility checks.

**Target Session**
The academic session students will be promoted to (e.g., 2027-28). New academic session records will be created under this session upon confirmation.

**From Class**
The current class of the students being promoted (e.g., Class III). Only students enrolled in this class appear in the eligible list.

**To Class**
The target class after promotion (e.g., Class IX). Students confirmed as Promoted will be enrolled in this class.

**Status**
Draft — the batch is being prepared, records can be added/edited/deleted freely.
Confirmed — the batch is finalized, student academic sessions have been updated, no further changes allowed.

**Statistics**
The batch header shows real-time counts: total students, promoted count, detained count.

---

## Business Rules and Conditions

**Unique Batch Per Transition**
A promotion batch is uniquely identified by its from_class + to_class + from_session + to_session combination. Duplicate batches for the same transition should not be allowed.

**Draft-Only Edits**
Records can only be added, edited, or deleted while the batch is in Draft status. Once Confirmed, the batch becomes read-only.

**No Changes After Confirmation**
Confirmed batches cannot be re-opened. To make corrections, the batch must be cancelled and recreated.

**Soft Delete**
Batches can be soft-deleted. Deleted batches move to trash and can be restored if needed. Permanent deletion requires additional confirmation.

---

## Workflow Steps

**Creating a Promotion Batch**
Admin navigates to the promotions page, clicks "Create Batch", selects the source session, target session, from class, and to class, optionally enters criteria configuration, and submits. The batch is created in Draft status.

**Viewing Batch List**
The promotions index page displays all batches with their status, source/target details, and statistics. Admin can filter by status (Draft/Confirmed) or search by class name.

**Opening a Batch**
Admin clicks on a batch to open its show page, which displays the batch header details, statistics cards, and the Promotion Records table where individual student records are managed.

**Editing a Batch**
Admin can edit the batch metadata (sessions, classes) while it is in Draft status. Changes are saved immediately.

**Deleting a Batch**
Admin can delete a Draft batch. All associated promotion records are also deleted. Confirmed batches cannot be deleted directly — they must be cancelled first.

---

## Example Scenario

A school wants to promote 64 students from Class III (Session 2026-27) to Class IX (Session 2027-28). Admin creates a promotion batch with:
- From Session: 2026-27
- To Session: 2027-28
- From Class: Class III
- To Class: Class IX

The batch is created in Draft status. Admin then opens the batch and starts adding promotion records for each student.

---

## Related Screens

- **Promotion Records** — The main working screen within a batch where individual student records are managed
- **Batch Confirmation** — Finalizes the batch and writes student academic sessions
