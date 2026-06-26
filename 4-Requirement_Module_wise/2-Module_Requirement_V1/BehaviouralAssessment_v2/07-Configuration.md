# Configuration — Business Requirements

## What This Screen Does

The Configuration screen allows administrators to manage global parameters and system rules for the entire Behavioural Assessment module. This panel controls the core logical behavior of the module, ensuring that the system enforces school-wide grading policies automatically.

This screen is where the admin binds a specific [Rating Scale](./02-Rating-Scales.md) as the default for the active Academic Session, determines whether teacher-submitted scores require an approval workflow, and establishes automated thresholds for behavioral alerts.

---

## When This Screen Is Used

- **Academic Session Initialization**: The admin selects the active school session and links the behavioral rules to it.
- **Switching Grading Models**: The school board decides that teachers no longer need HOD approval for minor behavioral marks, and the admin toggles off the "Approval Workflow Required" setting.
- **Configuring Automated Disciplinary Triggers**: The admin updates the system rules so that any student reaching 3 high-severity incidents automatically triggers a counsellor alert email.

---

## Key Fields at a Glance

| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Academic Session** | Integer (ID) | Read-only / Dropdown | Yes | References `org_academic_sessions`. |
| **Active Rating Scale** | Integer (ID) | Dropdown / Select | Yes | References `ba_rating_scales`. Sets the scoring standard school-wide. |
| **Approval Workflow** | Boolean | Toggle / Switch | Yes | If True, teacher grades must be reviewed in the [Review Queue](./11-Review-Queue.md) before publishing. |
| **Incident Escalation Threshold** | Integer | Number Input | Yes | Count of negative incidents that automatically flags a student for counsellor attention. Default is `3`. |
| **Notification Settings** | Checkbox Group | Multi-select checkbox | No | Options: `Email HOD on Submission`, `Email Parents on Severe Incident`, `Daily Digest to Principal`. |

---

## Business Rules and Conditions

**Scale Integrity Constraint**
- Once a Rating Scale is active and teachers have entered *even a single rating* in `ba_assessment_ratings` for the current academic session, the **Active Rating Scale** dropdown is locked and cannot be changed. This prevents catastrophic database corruption where scores mapped to 5-point scales are suddenly evaluated under a 3-point scale.

**Global Approval Flow**
- If **Approval Workflow** is enabled:
  - Teacher submissions go to the `PENDING` status.
  - Grades are not visible in [Student Reports](./20-Student-Report.md) or final analytics until the HOD locks and changes the status to `APPROVED`.
- If disabled:
  - Teacher submission directly saves as `APPROVED` and publishes immediately.

**Multi-Tenant Validation**
- All configuration settings are securely restricted to the current school (tenant) inside `ba_config` and cannot affect other schools on the same server database.

---

## Workflow Steps

**Configuring Global Parameters**
1. Admin navigates to **Setup -> Configuration**.
2. The active academic session is pre-filled: `2026-2027 Academic Session`.
3. Selects **Active Rating Scale**: `Standard 5-Point Scale`.
4. Enables the **Approval Workflow** toggle.
5. Sets **Incident Escalation Threshold** to `3`.
6. Checks **Email Parents on Severe Incident** in Notification Settings.
7. Admin clicks **Save**. The system inserts or updates the record in `ba_config` and logs the action in the audit trail.

**Mid-Session Modification (Protected)**
1. Admin attempts to change **Active Rating Scale** from `Standard 5-Point Scale` to `Primary Behaviour Scale`.
2. System queries `ba_assessment_ratings`.
3. The query returns 150 student ratings already submitted.
4. The system disables the dropdown and renders a warning message: `"Active Rating Scale cannot be modified because behavioral grades have already been recorded. Create a new academic session mapping instead."`

---

## Example Scenario

At the start of the year, the admin configures:
- **Rating Scale**: Standard A-E Scale
- **Approval Workflow**: Enabled
- **Incident Escalation Threshold**: 3 Incidents

In October, Student Ajay gets logged for 3 separate minor class disruptions. On the third incident log entry, the system checks `ba_config`, matches the threshold of 3, and automatically triggers an email notification to the High School Counsellor for immediate guidance mapping.

---

## Related Screens

- [02-Rating-Scales.md](./02-Rating-Scales.md) — The grading scales linked in this configuration panel.
- [11-Review-Queue.md](./11-Review-Queue.md) — Screen that executes the HOD approval workflow if toggled on here.
- [12-Incident-Log.md](./12-Incident-Log.md) — Screen that tracks infractions against the escalation thresholds.
