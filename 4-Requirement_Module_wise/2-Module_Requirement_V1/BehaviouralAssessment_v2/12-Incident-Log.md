# Incident Log — Business Requirements

## What This Screen Does

The Incident Log screen enables real-time tracking of behavioral events. While periodic term assessments reflect overall development, the Incident Log captures specific, concrete actions—both exceptional positive accomplishments (e.g., "Assisted a classmate during a medical emergency," "Won national debate championship") and critical disciplinary infractions (e.g., "Cheated during a math exam," "Aggressive conflict during recess").

By logging these events immediately, the school maintains an objective, verifiable log of critical events that directly influence parental discussions, counsellor meetings, and student report card comments.

---

## When This Screen Is Used

- **Immediate Infractions**: A teacher catches a student copying answers during an exam and registers the event.
- **Positive Milestones**: A teacher logs a student’s exemplary leadership during a school festival.
- **Consulting Records**: A counsellor reviews a student's history of incidents before a scheduled meeting.
- **Parent Meetings**: Class teachers open the incident history list to show parents evidence of repeated classroom disruption.

---

## Key Fields & Log Form

The main page contains an **"Add Incident"** form button and a list of previously recorded incidents with advanced search and filters.

### Log New Incident Form
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Student** | Integer (ID) | Autocomplete Search | Yes | Search by Name/Admission Number. Ref: `std_students`. |
| **Incident Type** | String | Radio Group | Yes | Options: `Positive (Achievement)` or `Negative (Infraction)`. |
| **Category** | Integer (ID) | Dropdown | Yes | Filters active categories from `ba_categories`. |
| **Severity** | String | Dropdown / Select | Yes | Options: `Info` (Minor), `Low` (Warning), `Medium` (Escalate), `High` (Critical). |
| **Incident Date** | Date / Time | Date-Time Picker | Yes | Defaults to current date-time. Cannot be a future date. |
| **Description** | String | Text Area | Yes | Plain description of the event. Min 20, Max 1000 characters. |
| **Logged By** | Integer (ID) | Read-only Text | Yes | Defaults to current user ID from `sch_employees`. |

---

## Business Rules and Conditions

**Real-Time Logging Rule**
- Incidents can only be logged within a **maximum of 7 days** from the event occurrence date. The system prevents choosing dates older than 7 days to maintain reporting accuracy and avoid delayed disciplinary processing.

**Automated Email Warnings (High Severity)**
- When an incident is saved with `Severity = 'High'`:
  - An email alert is instantly dispatched to the student's Homeroom Teacher, Section HOD, and the School Principal.
  - If parent email notification is checked in [Configuration](./07-Configuration.md), the system auto-generates a standardized email detailing the event.

**Incident Type Visual Formatting**
- In lists and timelines, Positive incidents are highlighted in light emerald green with a star icon. Disciplinary incidents are highlighted in light rose/amber with an exclamation triangle icon.

---

## Workflow Steps

**Logging a Disciplinary Incident**
1. Teacher clicks **Log Incident** on the Incident Log tab.
2. Type student's name: `Amit Sharma`. Autocomplete lists matching records; MRS. Priya selects Amit (Class 8-A, Admission #12345).
3. Selects Incident Type: `Negative (Infraction)`.
4. Selects Category: `Peer Relations`.
5. Selects Severity: `Medium`.
6. Enters Description: `"Amit was repeatedly shouting and disrupting other students during group project work. He refused to quiet down when asked multiple times."`
7. Teacher clicks **Submit**. 
8. The system creates the incident record in `ba_incidents`, logs the author, and displays a success toast.
9. Mrs. Priya is prompted: `"Do you want to add witnesses to this incident?"` Clicking Yes opens the [Witnesses](./13-Witnesses.md) sub-tab.

---

## Example Scenario

During Chemistry lab, John is caught playing on his mobile phone and breaking a beaker. Teacher Mr. Roy logs:
- **Student**: John Doe (Grade 10)
- **Incident Type**: Negative
- **Category**: Responsibility & Care of Equipment
- **Severity**: Low (Requires Warning)
- **Description**: "John was using his personal mobile phone during experiments and accidentally knocked over a beaker, shattering it."
- **Logged By**: Mr. Roy

The record immediately updates John's student timeline and is flagged on the [Dashboard](./01-Dashboard.md).

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Category classifications.
- [13-Witnesses.md](./13-Witnesses.md) — Linking student/staff witnesses.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Attaching corrective actions to resolve this logged incident.
- [24-Incident-Report.md](./24-Incident-Report.md) — The standalone report card summarizing logged infractions.
