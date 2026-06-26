# Review Queue — Business Requirements

## What This Screen Does

The Review Queue is the primary workspace for academic coordinators, section heads, and HODs. When teachers submit behavioral evaluations from their [My Assessments](./08-My-Assessments.md) dashboard, the records enter the Review Queue rather than publishing immediately. 

This portal acts as a quality control gateway. Supervisors review teachers' grades and qualitative remarks to verify consistency, professional language, and objective grading standards. From this screen, coordinators can either **Approve & Lock** a section's grades or **Send Back with Feedback** to a teacher for corrections.

---

## When This Screen Is Used

- **End of Term Audits**: After teachers complete their grades, the coordinator opens the queue to inspect and sign off on submissions.
- **Validating Remarks**: A coordinator scans student narratives to ensure no emotional or inappropriate language was recorded.
- **Handling Grade Corrections**: Returning a grading sheet to a teacher who accidentally gave a student incorrect marks.

---

## Key Fields & Screen Layout

### Pending Submissions Queue (Index Grid)
The main screen lists all sections awaiting approval:
| Field Name | Source Table | Description |
|------------|--------------|-------------|
| **Class & Section** | `sch_classes`, `sch_sections` | The student cohort (e.g., "Class 10-B"). |
| **Teacher Name** | `sch_employees` | The name of the teacher who submitted the grades. |
| **Period** | `ba_assessment_periods` | The grading period (e.g., "Term 1"). |
| **Submitted Date** | `ba_assessments` | The timestamp when the teacher clicked submit. |
| **Status Badge** | `ba_assessments` | Visual indicator: `Pending Review` (Yellow). |
| **Actions** | Interactive Buttons | **"Review Sheet"** opens the modal; **"Quick Approve"** signs off without detailing. |

### Detailed Review Modal / View Sheet Panel
Clicking "Review Sheet" opens a side-drawer or full-screen view of the teacher's grading matrix:
- Displays a read-only list of all students with their numeric criteria grades and written remarks.
- **HOD Feedback Box**: A text field to record internal feedback if returning the sheet.
- **Action Footer**:
  - **"Approve & Lock"** (Green Button)
  - **"Send Back for Correction"** (Red Button)

---

## Business Rules and Conditions

**Approval Workflow Constraint**
- The HOD approval logic is globally controlled via the [Configuration](./07-Configuration.md) panel. If approval is disabled, this queue is hidden, and teacher submissions bypass this screen.

**Approved State Freeze**
- Clicking **Approve & Lock**:
  - Transitions `status` in `ba_assessments` to `Approved`.
  - Disables the "Send Back" option permanently.
  - Automatically pushes finalized averages to the student academic records, making them visible on the parent portal and in [Student Reports](./20-Student-Report.md).

**Send Back Loop**
- Clicking **Send Back for Correction**:
  - Transitions `status` back to `Draft`.
  - Copies the HOD’s feedback message into a notification table.
  - Automatically unlocks the grading grid on the teacher's [My Assessments](./08-My-Assessments.md) dashboard, flagging it with a red `"Correction Required"` alert.

---

## Workflow Steps

**Approving a Submission**
1. Coordinator logs in and navigates to **Assessments -> Review Queue**.
2. Sees 3 sections pending. Clicks **Review Sheet** next to `"Grade 8-A — Mrs. Priya"`.
3. Modal displays. The coordinator reviews rolls 1 to 30. All criteria ratings are balanced and Amit’s remarks are professional.
4. Coordinator clicks **Approve & Lock**.
5. System displays a confirmation: `"Approved scores will be instantly visible to parents and locked. Proceed?"`
6. Coordinator clicks **Confirm**. The status updates to `Approved`, the row disappears from the queue, and the database freezes.

**Returning a Submission**
1. Coordinator opens `"Grade 8-B — Mr. Roy"`.
2. Scans remarks. Sees roll 12 has a generic remark: `"Good student"`. This violates the 30-character rule.
3. In the Feedback Box, the coordinator writes: `"Please expand on the remarks for Amit (Roll 12) to describe his interpersonal skills in class."`
4. Clicks **Send Back for Correction**.
5. System resets `ba_assessments.status` to `Draft` and logs the feedback.
6. The class unlocks for Mr. Roy to edit.

---

## Example Scenario

High School Coordinator Mr. Jacob opens the queue. Mrs. Priya's submission for 8-A has been sitting in `Pending` since yesterday. Mr. Jacob reviews the sheet. He finds a student rated 1.0 (Low) in Collaboration, but the remark says `"Excellent student."` This is a contradiction. Jacob writes: `"The remark contradicts the low collaboration rating. Please review."` and clicks `Send Back`. Mrs. Priya receives an automated alert and fixes it.

---

## Related Screens

- [07-Configuration.md](./07-Configuration.md) — Controls whether this queue is active.
- [08-My-Assessments.md](./08-My-Assessments.md) — The teacher portal affected by HOD approvals/returns.
- [09-Ratings.md](./09-Ratings.md) / [10-Remarks.md](./10-Remarks.md) — The sheets audited inside this queue.
