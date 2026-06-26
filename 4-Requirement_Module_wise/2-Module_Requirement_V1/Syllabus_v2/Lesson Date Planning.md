# Lesson Date Planning — Business Requirements

## What This Screen Does

The Lesson Date Planning screen breathes life into the static curriculum by transforming it into a dynamic, time-bound academic calendar. 

It maps the theoretical hierarchy of Lessons and Topics to actual physical dates, specific classroom sections, and individual teachers. This is the operational engine of the school, answering the critical logistical question of exactly when a specific class is scheduled to learn a specific chapter, and which teacher is responsible for delivering it.

---

## When This Screen Is Used

- Term Initialization at the beginning of a term to create the Monthly Split-up Syllabus or Annual Teaching Planner
- Workload Allocation when an Academic Coordinator assigns specific syllabus targets to a newly hired teacher
- Dynamic Rescheduling when adjusting schedules due to unforeseen school closures that force target dates to be pushed back
- Substitute Management for reallocating a syllabus target from an absent teacher to a proxy teacher

---

## Key Fields at a Glance

**Target Audience and Scope**
The Academic Session, Class, and Subject define the broad cohort. A Section Selection field is optional; if left blank, the schedule applies globally to all sections of that class. If a specific section is selected, it overrides the global schedule for that specific classroom.

**Curriculum Linkage**
A Target Lesson and Topic field identifies exactly what piece of content is being scheduled. A Topic Level Type identifies if the schedule is for a broad Lesson, a specific Topic, or a highly granular Micro-Topic, allowing scheduling at varying depths.

**Scheduling and Time Constraints**
A Scheduled Start Date and End Date capture the physical calendar window allocated for completion. Planned Periods capture the expected number of classes required, which is used to calculate pacing and teacher workload.

**Human Resources and Execution**
An Assigned Teacher captures the teacher officially scheduled to teach this content. An Actual Taught By field captures the teacher who actually taught it and marked it complete in the system. A Completion Status indicates if the topic is Pending, In Progress, Completed, or Delayed. A Priority Level with options like High, Medium, or Low dictates the urgency displayed on the teacher's dashboard.

---

## Business Rules and Conditions

**Date Validations and Boundaries**
The scheduled start and end dates must fall strictly within the boundaries of the selected academic session. Furthermore, the system must enforce that the end date cannot be earlier than the start date. The system should display a validation error if a schedule spans outside the active term dates.

**Section-Level Override Precedence**
An HOD might set a master schedule for Class 10 Science, stating that Chapter 1 must be finished by July 15th for all sections. However, if the teacher of Class 10-C falls behind and creates a specific schedule for Class 10-C ending on July 20th, the system must always prioritize and display the section-level schedule for students and reports related to 10-C, ignoring the global master schedule.

**Substitute Tracking**
If Teacher A is officially assigned, but Teacher B logs into their portal, takes the proxy class, and marks the topic as Completed, the system must automatically capture Teacher B's name as the Actual Teacher. This is necessary for accurate workload tracking, payroll, and accountability audits.

---

## Workflow Steps

**Scheduling a Lesson**
The Science HOD navigates to Lesson Date Planning. They select Class 9, Subject Science, and leave the Section blank to apply it to all sections. The system loads the Syllabus tree, and the HOD selects the Lesson "Motion". The HOD sets the Scheduled Start Date to July 1st and the End Date to July 15th. They allocate 8 Planned Periods, select Mr. Sharma as the Assigned Teacher, and save the schedule. Instantly, "Motion" appears on Mr. Sharma's dashboard with a countdown timer to July 15th.

---

## Example Scenario

A teacher goes on unexpected medical leave for a week. The HOD pulls up the Lesson Date Planning screen, filters by the absent teacher's name, and sees that they were scheduled to teach Chemical Bonding to Class 11-B this week. The timeline is critical because of upcoming exams. 

The HOD edits the schedule, changes the Assigned Teacher to a substitute teacher, and sets the priority to High. The substitute teacher instantly receives a push notification and sees this new, high-priority target on their dashboard, ensuring the syllabus does not fall behind despite the absence.

---

## Related Screens

- **Topic Release Control** — Directly relies on the dates set here to automatically unlock digital content for students
- **Planning Accuracy Report** — Compares the Scheduled End Date against the Actual Completion Date to calculate pacing efficiency
