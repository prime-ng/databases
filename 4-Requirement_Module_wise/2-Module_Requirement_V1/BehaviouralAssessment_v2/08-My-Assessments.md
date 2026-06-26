# My Assessments — Business Requirements

## What This Screen Does

The My Assessments screen serves as the primary workspace and dashboard for teachers. This portal aggregates all classes, sections, and behavioral evaluation periods assigned to the logged-in teacher for the active academic session.

Instead of navigating complex menus, a teacher can open this screen to instantly see a list of their assigned cohorts, the progress of their assessments (e.g., `"Not Started,"` `"Draft (12/25 Graded),"` `"Submitted,"` or `"Approved"`), the remaining days before the submission deadline, and quick links to open the grading sheets.

---

## When This Screen Is Used

- **Daily Grading**: A teacher opens this screen to resume scoring their class.
- **Checking Deadlines**: Teachers use this list to see which assessment terms are closing soon.
- **Submitting Scores**: Once all student marks and qualitative remarks are entered, the teacher triggers the submission approval workflow from this screen.
- **Viewing Approved Scores**: Reviewing historical grades that have already been finalized and locked by HODs.

---

## Key Columns & Fields

The core of this screen is a search filter bar followed by a detailed data grid of assigned classes.

### Filter Options
- **Assessment Period**: Dropdown filter to switch between terms (defaults to current active period).
- **Class / Grade**: Filter to narrow down search to specific classes.

### Assigned Classes Data Grid
For each assigned class-section, the grid displays:
| Field Name | Source Table | Description |
|------------|--------------|-------------|
| **Class & Section** | `sch_classes`, `sch_sections` | The class and section assigned to the teacher (e.g., "Class 8-A"). |
| **Assessment Period**| `ba_assessment_periods` | The current evaluation period (e.g., "Term 1"). |
| **Progress Status** | `ba_assessments` | Status of grading: `Not Started` (No scores saved), `Draft` (Some scores saved), `Submitted` (Pending HOD review), or `Approved` (Locked & Published). |
| **Completion Rate** | Calculated | Displays progress visually (e.g., a progress bar showing "15 / 30 Students Evaluated"). |
| **Lock Date** | `ba_assessment_periods` | The deadline for submission. Displays warning icons if under 48 hours remaining. |
| **Action** | Action Trigger | Dynamic button based on status: **"Start Grading"** (if Not Started), **"Edit Ratings"** (if Draft), or **"View Summary"** (if Submitted or Approved). |

---

## Business Rules and Conditions

**Strict Teacher Partitioning**
- Teachers can *only* see class-sections where they are officially registered as the Class Teacher or Subject Teacher in the school's central employee mapping (`sch_employees` & `sch_class_section_jnt`). They cannot see or edit assessments for other sections.

**Dynamic Status Transitions**
- **Draft** status triggers automatically as soon as a teacher saves the first numeric score in `ba_assessment_ratings`.
- **Submit Button Activation**: The "Submit to HOD" action button becomes clickable *only* when the Completion Rate is exactly 100% (i.e. every active student in the section has received a score for every mapped criterion and a qualitative remark).
- **Post-Submission Freeze**: As soon as the teacher clicks "Submit to HOD," the progress status changes to `Submitted`, the edit option is disabled, and the grid becomes read-only.

---

## Workflow Steps

**Resuming a Draft Grading Sheet**
1. Teacher logs in and opens **Assessments -> My Assessments**.
2. The screen automatically filters for the current active period (`Term 1`) and the teacher's assigned section (`Class 8-A`).
3. The progress status shows `Draft (18/30 Graded)`.
4. Teacher clicks **Edit Ratings**.
5. The system redirects them to the [Ratings Grid](./09-Ratings.md) with active student lists.

**Submitting a Completed Section**
1. Teacher completes grading all 30 students. The progress bar displays `30 / 30 Completed (100%)`.
2. The status is still `Draft`. A green **Submit to Coordinator** button appears in the action column.
3. Teacher clicks the button.
4. The system updates `status` in `ba_assessments` to `Submitted` and logs the submission time.
5. The action column changes to **"View Summary"** (read-only mode), and a notification is sent to the section coordinator's queue.

---

## Example Scenario

Mrs. Priya teaches Science to Grade 7-B and 7-C. At the end of September, she opens **My Assessments**:
- Row 1: `Grade 7-B — Sept Evaluation` — Status: `Submitted` (Locked, Mrs. Priya is waiting for HOD approval).
- Row 2: `Grade 7-C — Sept Evaluation` — Status: `Draft (20/28 Graded)` — MRS. Priya clicks `Edit Ratings` to input scores for the remaining 8 students.

---

## Related Screens

- [06-Periods.md](./06-Periods.md) — The assessment calendars showing deadlines.
- [09-Ratings.md](./09-Ratings.md) — The grading grid opened by clicking "Edit Ratings".
- [10-Remarks.md](./10-Remarks.md) — Screen where teachers write student narratives before submitting.
- [11-Review-Queue.md](./11-Review-Queue.md) — The supervisor screen where Mrs. Priya’s submissions are reviewed.
