# Behavior Incidents — Business Requirements

## What This Screen Does

The Behavior Incidents screen allows the school to log and track student misconduct incidents. Each incident has a severity level (Low, Medium, High, Critical), a description, and a status (Open, Reviewed, Closed). Corrective actions (warnings, detentions, suspensions, expulsions) can be associated with each incident.

The screen shows an incidents list (within the Promotions & Alumni tab group) with student details, severity badges, status, and action buttons. Each incident has a detail/show page with the full incident report, corrective actions timeline, and review/close workflows.

---

## When This Screen Is Used

- A teacher or staff member witnesses misconduct: An incident is logged
- Disciplinary review: Admin reviews open incidents and takes action
- Parent communication: Admin needs to reference a specific incident history
- End-of-year: Admin reviews the behavior record for a student

---

## Key Fields at a Glance

**Student**
The student involved in the incident.

**Incident Date & Time**
When the incident occurred.

**Severity**
Low — minor infraction (e.g., late submission).
Medium — moderate issue (e.g., classroom disruption).
High — serious matter (e.g., fighting, bullying).
Critical — extreme (e.g., violence, legal involvement).

**Description**
A detailed narrative of what happened, written by the reporting staff member.

**Reported By**
The staff member who logged the incident.

**Status**
Open — reported, not yet reviewed.
Reviewed — has been reviewed by admin/principal.
Closed — resolved, no further action needed.

**Corrective Actions**
A timeline of actions taken: Warning, Detention, Suspension, Expulsion, or custom action.

---

## Business Rules and Conditions

**Student Must Exist**
Incidents can only be linked to existing student records.

**Severity Escalation**
If corrective actions are insufficient and the incident persists, the severity can be escalated.

**Review Required for High/Critical**
Incidents with High or Critical severity require an admin/principal review before they can be closed.

**Corrective Action Chain**
Multiple actions can be added to a single incident over time. Each action has a date, type, description, and the staff member who authorized it.

**Soft Delete**
Incidents can be soft-deleted. The student's incident history is preserved for audit purposes.

---

## Workflow Steps

**Logging an Incident**
Admin clicks "Add Incident", selects the student, enters the date, severity, description, and submits. The incident is created in Open status.

**Viewing Incidents List**
The incidents tab displays all incidents with severity badges (color-coded: Low=gray, Medium=yellow, High=orange, Critical=red), student names, status, and date.

**Viewing Incident Details**
Admin clicks on an incident to open the show page. This displays:
- Full incident report (student, date, severity, description)
- Status timeline (Open → Reviewed → Closed)
- Corrective actions list
- Action buttons (Review, Close, Add Action)

**Reviewing an Incident**
Admin clicks "Review Incident". A dialog asks for review notes. The status changes to Reviewed.

**Closing an Incident**
Admin clicks "Close Incident". A dialog asks for resolution notes. The status changes to Closed.

**Adding Corrective Actions**
Admin clicks "Add Action" on the incident show page. Selects the action type (Warning/Detention/Suspension/Expulsion), enters description, and submits. The action appears in the timeline.

---

## Example Scenario

A teacher reports that a Class IX student was involved in a fight during recess. Admin logs an incident:
- Student: Aadil Saurabh Baral
- Severity: High
- Description: "Physical altercation with another student in the playground at 11:30 AM"
- Reported By: Mrs. Sharma (Class Teacher)

Admin reviews the incident and issues a 3-day suspension as corrective action. After the suspension period and a parent meeting, Admin closes the incident with resolution notes.

---

## Related Screens

- **StudentProfile** — Incidents link to student records
- **Alumni** — Behavior records are preserved for alumni
- **Transfer Certificates** — Conduct remarks on TCs may reference incident history
