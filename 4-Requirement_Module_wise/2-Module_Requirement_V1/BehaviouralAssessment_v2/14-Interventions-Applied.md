# Interventions Applied — Business Requirements

## What This Screen Does

The Interventions Applied screen is where the school logs and manages the active resolution of behavioral issues. Logging an incident only records what went wrong; the **Interventions Applied** tab documents how the school is actively working to resolve it and support the student.

This portal allows counsellors, HODs, and teachers to assign standardized corrective or supportive programs (defined in the [Interventions Master](./04-Interventions.md)) to specific [Incidents](./12-Incident-Log.md). Staff use this screen to track the execution status (e.g., `Assigned`, `In Progress`, `Completed`), assign staff members to lead the intervention, and record developmental progress notes.

---

## When This Screen Is Used

- **Post-Incident Action**: After a severe disciplinary infraction is logged, a counsellor opens this screen to assign "Parent Counseling" to the student.
- **Monitoring Progress**: A counsellor updates progress notes weekly for a student undergoing "Weekly Mentor Meetings."
- **Closing a Case**: Mark an intervention as Completed once the student completes their reflection assignment or restorative service.
- **Reporting Outcomes**: Reviewing the success rates of various interventions during school safety audits.

---

## Key Fields & Assignment Form

This screen is accessible both as a sub-tab within an Incident’s detail card and as a standalone listing of all active behavioral interventions in the school.

### Assign New Intervention Form
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Parent Incident** | Integer (ID) | Read-only Context | Yes | The incident being resolved. Ref: `ba_incidents`. |
| **Select Intervention**| Integer (ID)| Dropdown / Select | Yes | References active interventions in `ba_interventions`. |
| **Assigned To Staff** | Integer (ID) | Autocomplete Search | Yes | The staff leading the intervention. Ref: `sch_employees`. |
| **Scheduled Date** | Date | Date Picker | Yes | When the intervention should commence. |
| **Status** | String | Dropdown / Select | Yes | Options: `Assigned` (Not started), `In Progress`, `Completed`, `Cancelled`. |
| **Progress Notes** | String | Text Area | No | Rolling log of sessions and student responses. Max 1000 chars. |

---

## Business Rules and Conditions

**Case Resolution Flow**
- A high-severity disciplinary incident *cannot* be marked as resolved or archived until the associated **Intervention Applied** record is updated to `Completed` or `Cancelled` (with a cancellation justification).

**Automated Closure Checklist**
- When the status is flipped to `Completed`, the system enforces filling in the **Completion Date** and adding a closing summary note of at least 50 characters in the **Progress Notes** field.

**Continuous Log Auditing**
- All modifications to the intervention status and notes are written to the [Audit Trail](./19-Audit-Trail.md) along with the staff author’s ID to maintain a secure behavioral record.

---

## Workflow Steps

**Assigning an Intervention**
1. Counsellor opens the active incident list and clicks **Assign Action** on John Doe’s high-severity academic cheating incident.
2. In the assignment form, select Intervention: `Disciplinary Reflection Assignment`.
3. Select Assigned Staff: `Mr. Roy` (Science Teacher).
4. Set Scheduled Date: `2026-12-01`. Set Status: `Assigned`.
5. Counsellor clicks **Save**. The row inserts into the joint table `ba_incident_intervention_jnt`.

**Updating and Completing an Intervention**
1. On December 3rd, Mr. Roy logs in, opens the **Interventions Applied** tab, and searches for John Doe.
2. Clicks **Update Progress**.
3. Changes Status to `Completed`.
4. Enters Progress Notes: `"John successfully completed his 3-page reflection worksheet, discussing the impact of cheating on his learning and character. He apologized to the class."`
5. Enters Completion Date: `2026-12-03`.
6. Clicks **Save**. The parent incident status automatically transitions to `Resolved`. John’s parent receives an automated confirmation email.

---

## Example Scenario

A student is caught using abusive language. The HOD logs the infraction. The counsellor assigns:
- **Intervention**: Anger Management Counselling (Type: Supportive)
- **Assigned Staff**: Dr. Sen (School Psychologist)
- **Scheduled Date**: December 5th
- **Status**: In Progress

Dr. Sen records weekly notes under `Progress Notes` detailing John's attendance and responsiveness. Once the 4-week program is done, Dr. Sen marks it `Completed`, archiving the file.

---

## Related Screens

- [04-Interventions.md](./04-Interventions.md) — The core interventions master.
- [12-Incident-Log.md](./12-Incident-Log.md) — Screen where the parent incident is logged.
- [24-Incident-Report.md](./24-Incident-Report.md) — The standalone report card detailing incident-intervention lifecycles.
