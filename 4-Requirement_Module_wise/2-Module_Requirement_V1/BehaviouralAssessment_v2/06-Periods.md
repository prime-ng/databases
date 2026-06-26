# Assessment Periods — Business Requirements

## What This Screen Does

The Assessment Periods screen allows schools to define the calendar schedule for behavioral evaluations. Similar to academic exams, behavioral assessments are conducted in structured cycles—either Monthly (e.g., "September 2026 Evaluation"), Term-wise (e.g., "Term 1 Behavioral Review"), or Annual.

This screen defines the start and end dates for each period, and more importantly, establishes a **Lock Date / Submission Deadline**. Once the lock date passes, the system automatically locks the evaluation data, blocking teachers from making further changes to protect grade integrity before reports are generated.

---

## When This Screen Is Used

- **Academic Calendar Planning**: Admin registers all behavioral assessment periods for the entire academic year.
- **Extending Grading Deadlines**: Teachers request more time, and the admin edits the Lock Date for the current period to grant a 2-day extension.
- **Locking a Period Manually**: A period has finished, HODs have approved all scores, and the admin manually flags the period as Locked to freeze the database.
- **Reviewing Historic Periods**: Checking start/end dates of previous terms for audit purposes.

---

## Key Fields at a Glance

| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Period Name** | String | Text Input | Yes | Unique name. Max 100 characters. e.g., "Term 1 Behavioral Review" |
| **Academic Session**| Integer (ID) | Dropdown | Yes | References `org_academic_sessions`. |
| **Start Date** | Date | Date Picker | Yes | Must be within the academic session calendar. |
| **End Date** | Date | Date Picker | Yes | Must be after or equal to the Start Date. |
| **Lock Date** | Date | Date Picker | Yes | Deadline for grading. Must be equal to or after the End Date. |
| **Is Locked** | Boolean | Toggle | Yes | Defaults to False (Open). If True, all database inserts and edits to ratings for this period are blocked. |

---

## Business Rules and Conditions

**Chronological Non-Overlapping Rule**
- No two active assessment periods under the same academic session can have overlapping date ranges. The system will throw an error if a newly proposed period starts before the previous one ends.

**The Absolute Lock Rule**
- Once a period is flagged as **Locked** (`is_locked = true`):
  - Teachers cannot enter or edit grades in [Ratings](./09-Ratings.md) or [Remarks](./10-Remarks.md).
  - Coordinators/HODs cannot modify entries in the [Review Queue](./11-Review-Queue.md).
  - All API endpoints for saving marks verify `is_locked` and reject requests with a `403 Forbidden` response.
- Only the Admin can toggle `Is Locked` back to False to temporary open the period for emergency corrections.

**Delete Restrictions**
- An assessment period cannot be deleted if there are any records in `ba_assessments` or `ba_computed_scores` pointing to its ID. It can only be locked/deactivated.

---

## Workflow Steps

**Creating a New Assessment Period**
1. Admin navigates to **Setup -> Periods** and clicks **Add Period**.
2. Fills in the Period Name: `"Term 2 Assessment"`.
3. Selects Academic Session: `"2026-2027 Academic Session"`.
4. Sets Start Date: `2026-11-01` and End Date: `2027-01-31`.
5. Sets Lock Date: `2027-02-05` (giving teachers 5 days after the term ends to finish grading).
6. Admin clicks **Save**. The system validates no date conflicts and writes the record to `ba_assessment_periods`.

**Extending a Deadline**
1. Admin opens the edit screen for `"Term 2 Assessment"`.
2. Changes the Lock Date from `2027-02-05` to `2027-02-08`.
3. Clicks **Save**. Teachers immediately gain access to input scores for an extra three days.

**Manual Locking**
1. Admin views the periods list.
2. Toggles the `Is Locked` switch for `"Term 2 Assessment"` to True.
3. System prompts: `"Are you sure you want to lock this period? This will freeze all evaluations."`
4. Admin confirms. The database state updates, preventing any future edits.

---

## Example Scenario

The school operates on a quarterly assessment cycle. The admin registers:
- **Period**: Q1 Behavioural Assessment (Start: June 1, End: Aug 31, Lock Date: Sept 5)
- **Period**: Q2 Behavioural Assessment (Start: Sept 1, End: Nov 30, Lock Date: Dec 5)

On September 6th, a teacher attempts to edit a student's Q1 score. The page loads in read-only mode, displaying a banner: `"This assessment period was locked on Sept 5, 2026."`

---

## Related Screens

- [07-Configuration.md](./07-Configuration.md) — Linking classes to default configurations.
- [09-Ratings.md](./09-Ratings.md) — Core grid where teachers score within active periods.
- [11-Review-Queue.md](./11-Review-Queue.md) — Queue where submitted scores are locked at the deadline.
