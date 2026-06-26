# Witnesses — Business Requirements

## What This Screen Does

The Witnesses screen allows school administrators, HODs, and counsellors to record the testimony and statements of individuals who observed a logged behavioral incident. When serious incidents occur (e.g., student bullying, property damage, academic dishonesty), having a formal method to document multiple witness statements ensures administrative objectivity and accuracy.

Witnesses can be either other **Students** or **Staff Members** (teachers, security guards, administrators). Each witness is linked to a specific parent incident, and their statements are stored securely to build a complete case record.

---

## When This Screen Is Used

- **Investigating Serious Infractions**: A coordinator is resolving a physical dispute between two students and records testimonies from three classmates who saw the event.
- **Validating Claims**: A student claims they were unfairly accused of cheating; the HOD reviews the statements of proctoring teachers logged on this screen.
- **Formal Record Keeping**: Attaching staff testimonies before sending a formal behavior report or disciplinary action to parents.

---

## Key Fields & Add Witness Form

This screen is typically accessed as a nested panel or a sub-tab when viewing the details of a specific parent incident from the [Incident Log](./12-Incident-Log.md).

### Active Incident Context (Header)
- Displays Parent Incident ID, Student Name, Date, Severity, and the primary Description of the event in a read-only container.

### Add Witness Row / Form
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Witness Type** | String | Dropdown / Select | Yes | Options: `Student` or `Staff Member`. |
| **Witness Name** | Integer (ID) | Autocomplete Search | Yes | If Student: searches `std_students`. If Staff: searches `sch_employees`. |
| **Witness Statement** | String | Text Area | Yes | Explains exactly what they observed. Min 10, Max 500 characters. |

### Witnesses Linked Grid
A table displaying already recorded witnesses for this incident:
- Name and Role (e.g., "Amit Sharma - Student" or "Mr. Khan - Staff").
- Witness Statement text.
- Date Added.
- **Action**: **"Remove"** (Trash icon) to delete the link.

---

## Business Rules and Conditions

**Self-Referential Block**
- A student who is the **primary subject** of the logged incident cannot be added as a witness to their own incident. The autocomplete dropdown automatically excludes the subject student's ID from searches.

**Audit Lock**
- Once the parent incident has been closed or resolved with an associated [Intervention](./14-Interventions-Applied.md) that is marked "Completed," the witness list freezes. No new witnesses can be added, and existing statements cannot be edited or deleted.

**Role-Based Security**
- Witness statements are highly sensitive. While regular subject teachers can see that witnesses exist for an incident, the actual *statement text* can only be viewed by users with HOD, Counsellor, or Principal credentials.

---

## Workflow Steps

**Adding a Witness to an Incident**
1. HOD navigates to **Incidents -> Incident Log** and clicks **View Details** on a High-Severity conflict incident.
2. Clicks on the **Witnesses** tab.
3. Clicks **Add Witness**.
4. Selects Witness Type: `Student`.
5. Searches for: `Rohan Verma` (Admission #1452). Autocomplete matches and populates.
6. Enters Witness Statement: `"Rohan stated that he was sitting two desks away and saw the argument start over a misplaced notebook. He confirms that John pushed Ajay first."`
7. HOD clicks **Save Witness**.
8. The system inserts a record into the joint table `ba_incident_witnesses_jnt` and refreshes the grid.

---

## Example Scenario

During recess, a playground window is broken. A security guard and a student witness the event. The admin logs:
- **Parent Incident**: Window Broken (Subject: John Doe)
- **Witness 1**: Mr. Samuel (Staff / Security Guard) — Statement: `"I was patrolling the west corridor and heard the glass shatter. I saw John running away with a bat."`
- **Witness 2**: Ajay Kumar (Student) — Statement: `"John and I were playing cricket. John hit a ball that went straight into the window."`

These records provide the necessary evidence for the HOD to assign an intervention.

---

## Related Screens

- [12-Incident-Log.md](./12-Incident-Log.md) — The parent incident screen.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — The resolution screen linked to this investigation.
- [24-Incident-Report.md](./24-Incident-Report.md) — Prints witness summaries when exporting serious cases.
