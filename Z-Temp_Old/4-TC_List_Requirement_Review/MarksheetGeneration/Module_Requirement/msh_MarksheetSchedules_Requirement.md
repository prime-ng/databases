# Marksheet Schedules — Business Requirements

## What This Screen Does

The Marksheet Schedules screen is the central orchestration hub for the entire marksheet generation process. A schedule defines when and how student marksheets are calculated for a specific academic term. Each schedule links to a Config Template (defining grading rules and weightages), specifies which academic session and classes are covered, and tracks the calculations through a formal lifecycle: **Draft** ➔ **Computed** ➔ **Reviewed** ➔ **Published** ➔ **Locked**.

This screen coordinates all processing stages. Without schedules, the system would not know when to pull student grades or which classes to process. The Examination Coordinator would have no way to run, review, and lock results, leading to disorganized score compilation and potential data discrepancies. By establishing schedules, the school automates grade compilation and ensures a secure, auditable lifecycle for report card publication.

The screen appears in two contexts:
1. **Scheduling Hub → Schedules tab** — Displays a paginated list of schedules with their code, name, config template, schedule date, and status.
2. **Schedule Details Page (Show Page)** — The main workspace for managing a schedule, running checks, executing calculations, and triggering lifecycle status changes.

---

## Default Data Load

When the user opens the Scheduling Hub and selects the Schedules tab, the system runs a query in the background that retrieves all schedules, paginated at 15 records per page, using a specific page indicator for schedules. The query pre-loads references to the configuration template to display in the table.

When creating a schedule, the standalone page loads active lists for Config Templates, Academic Sessions, and Class Sections.

---

## When This Screen Is Used

*   **Term-End Calculations** — When an academic term ends, the coordinator creates a schedule to compute final report cards for all students in the selected classes.
*   **Progress Report Runs** — Mid-term, the coordinator schedules a progress report run to compile cumulative quiz, homework, and behavior scores.
*   **Audit and Verification** — After computation, the coordinator reviews the draft results on this screen.
*   **Results Publication** — Once approved, the schedule status is moved to published to make report cards available.
*   **Data Locking** — Once report cards are finalized and distributed, the schedule is locked to prevent any modifications.
*   **Recomputation and Corrections** — If a student's score was recorded incorrectly, the coordinator unlocks the schedule (specifying a reason), re-runs calculations, and publishes again.

---

## Key Fields at a Glance

**Identity and Schedule Parameters**
Each schedule has a unique code (e.g., "T1_2026") that is unique within its academic session, a descriptive name (e.g., "Term 1 Final 2026-27"), and is linked to an Academic Session and a Config Template. A target Schedule Date specifies when grades are finalized.

**Lifecycle Tracking and Locking**
*   **Workflow Status** — Tracks the current state: Draft, Computed, Reviewed, Published, or Locked.
*   **Calculation Timestamp** — Records when the last marksheet computation was run.
*   **Lock Details** — Records when the schedule was locked, who locked it, and similarly, when it was unlocked, who unlocked it, and the mandatory Unlock Reason.

**Class Sections**
The list of class sections included in this schedule's computation run.

---

## Business Rules and Conditions

**Session-Scoped Uniqueness (BR-MSG-018)**
The schedule code must be unique within the same academic session.

**Lifecycle State Machine (BR-MSG-019)**
The schedule must progress sequentially:
*   **Compute** is allowed only when status is Draft or Computed. If the schedule is locked, computation is blocked.
*   **Review** is allowed only when status is Computed.
*   **Publish** is allowed only when status is Reviewed. Publishing a schedule automatically locks its config template, preventing any changes to its grading weightages.
*   **Lock** is allowed only when status is Published, making the schedule and results completely immutable.
*   **Unlock** is allowed only when status is Published or Locked, and requires a mandatory reason of at least 5 characters. Unlocking resets the status to Computed.

**Gating and Safety (BR-MSG-020)**
No computation run can be triggered if another calculation job is currently running for the same schedule.

**Deletion Restrictions (BR-MSG-021)**
A schedule cannot be deleted if it contains computed student results or is in a locked/published state.

---

## Workflow Steps

**Creating, Checking, and Computing a Schedule**
It is the end of the term. The Examination Coordinator, Mr. Sharma, opens the Scheduling Hub and selects the Schedules tab. He clicks "Add Marksheet Schedule" to open the creation page. Mr. Sharma enters code "TERM1_2026", name "Grade 10 Term 1 Final", selects Config Template "CBSE Grade 10 Template", selects Academic Session "2026-27", and selects class sections: "10-A" and "10-B". He saves the schedule, which starts in Draft status.

He then clicks **Precheck** on the schedule details page. The system runs a data check and confirms that the template weightages sum to 100% and that student score counts are complete. Seeing no errors, Mr. Sharma clicks **Compute**. The system triggers the calculation in the background, updating the status to Computed once done.

**Reviewing, Publishing, and Locking**
After verifying the grades, Mr. Sharma clicks **Review** (status moves to Reviewed). The Principal, Mrs. Desai, logs in, reviews the summary, and clicks **Publish** (status moves to Published, and the "CBSE Grade 10 Template" is locked). Once parents have received report cards, Mrs. Desai clicks **Lock** to make the schedule completely immutable.

**Unlocking for Corrections**
A week later, a teacher reports a grading error in Physics for student John. Mrs. Desai clicks **Unlock** on the schedule details page, enters the reason: _Correcting John's raw Physics exam score_, and submits. The status resets to Computed, allowing Mr. Sharma to update the raw score, re-run computation, and re-publish.

---

## Example Scenario

Greenwood International School has completed Term 1. The coordinator, Mrs. Desai, sets up the schedule:
*   **Name**: "Term 1 Final 2026" (code: T1_2026)
*   **Template**: "CBSE Class 10 Template"
*   **Classes**: 10-A, 10-B.

She runs the precheck, triggers the computation, reviews the grades, and publishes the results. The system automatically locks the template to prevent accidental modifications to the 2026 grading rules.

---

## Related Screens

*   **Config Templates** — The grading templates referenced by schedules.
*   **Schedule Classes** — Links class sections to schedules.
*   **Student Results** — Shows overall computed student results.
*   **Computation Logs** — Audit logs tracking all calculations and lifecycle changes.
