# Progress Tracker — Business Requirements

## What This Screen Does

The Progress Tracker is a highly detailed, tabular report that breaks down syllabus completion at the most granular level possible. While the Overview Dashboard shows high-level gauges and pie charts, the Progress Tracker lists every single Lesson, Topic, and Micro-Topic, showing exactly when it was planned versus when it was actually taught.

It serves as the ultimate ledger of academic delivery, holding teachers accountable for their daily pacing.

---

## When This Screen Is Used

- Weekly Academic Reviews used by Heads of Departments during weekly meetings to review exactly what was covered in classrooms last week
- Exam Preparation used by the Examination Department to confirm which topics can be safely included in the upcoming unit tests without asking students questions on untaught material
- Self-Assessment used by Teachers to review their own historical teaching pace and plan the upcoming week

---

## Key Fields and Columns in the Report

**Context and Entity Details**
Columns for Class, Section, and Subject identify the specific classroom. Columns showing the Assigned Teacher versus the Actual Teacher highlight proxy situations where a substitute took the class.

**Deep Content Breakdown**
The Lesson Name shows the broad chapter. The Topic Name is displayed with hierarchical indents to visually show depth, such as Sub-topics nested under Topics. A Topic Level column explicitly indicates if it is a Root, Sub, or Micro topic.

**Crucial Schedule Metrics**
Target Start Date and Target End Date are pulled directly from the Syllabus Schedule planner. The Actual Completion Date records the exact date and time when the teacher marked the topic as completed in their app. Planned Periods shows how many classes were originally allocated for this topic.

**Status and Variance Indicators**
A Status column displays visual colored badges such as Green for Completed or Red for Overdue. A Variance column provides a calculated number showing the difference in days between the Target End Date and the Actual Completion Date, indicating exactly how many days early or late the topic was finished.

---

## Business Rules and Conditions

**Hierarchical Roll-up Status Calculation**
The status of a parent Lesson is dynamically derived from its child Topics. A Lesson can only show as Completed if 100% of its active child Topics are marked completed by the teacher. If 8 out of 10 topics are done, the Lesson must show In Progress at 80%. The report logic must automatically aggregate the statuses up the hierarchy.

**Strict Filter Dependencies**
To prevent the report from loading millions of rows and crashing, the interface must enforce a strict, step-by-step filtering process. The user must select the Academic Session, then the Class, and then the Subject. The dropdowns must cascade, meaning selecting a Class filters the available Subjects. The report should only generate after these mandatory parameters are provided.

**Exclusion of Non-Trackable Content**
The report generation process must explicitly filter out any topics that are marked as optional or not trackable in the master setup. Including optional topics would falsely skew the percentage completion metrics.

---

## Workflow Steps

**Generating a Departmental Review Report**
The Science HOD opens the Progress Tracker. They apply filters for Class 12, Subject Chemistry, and Section A. The table displays all Chapters. The HOD clicks the expand icon next to Organic Chemistry, and the table reveals 15 granular sub-topics. 14 rows are highlighted Green for Completed, but the final topic is highlighted Red for Overdue by 4 days. The HOD clicks the Export to PDF button to download this detailed tabular view for their meeting with the Chemistry teacher.

---

## Example Scenario

Two weeks before the Final Exams, the Exam Coordinator needs to set the question paper. They open the Progress Tracker, filter for all subjects in Class 9, and generate a Pending Topics Report. 

This generates a PDF listing every single topic across Math, Science, and English that has not yet been marked completed by the teachers. The Coordinator sends this PDF to all teachers with a strict mandate stating that they have 5 days to complete these specific topics, otherwise they will be excluded from the Final Exam blueprint.

---

## Related Screens

- **Overview Dashboard** — Gives the high-level graphical summary of this exact tabular data
- **Lesson Date Planning** — The absolute source of truth for the Target Date columns shown in this report
