# Interventions — Business Requirements

## What This Screen Does

The Interventions screen acts as a central repository for the school's standardized corrective, supportive, or restorative actions. When a student behaves exceptionally (either positively or negatively), the school does not just log the incident; they assign an **Intervention** to help guide or acknowledge the student.

Examples of negative interventions include "Principal Warning," "Parent-Teacher Counseling," "Restorative Service," or "Reflection Essay Assignment." Examples of positive interventions (reinforcements) include "Leadership Certificate Nomination," "Appreciation Badge," or "Roll of Honour recommendation."

Defining these interventions globally ensures that teachers and counselors use standardized administrative measures rather than defining ad-hoc actions.

---

## When This Screen Is Used

- **Policy Setup**: Admin configures the standard list of interventions approved by the school board.
- **Introducing Restorative Practices**: The school adds a new intervention type such as "Peer Mediation Sessions" to resolve student conflicts.
- **Updating Intervention Descriptions**: Updating standard procedures (e.g., specifying that a "Suspension Notice" must be signed by both HOD and Principal).
- **Retiring an Intervention**: An outdated disciplinary measure is deactivated.

---

## Key Fields at a Glance

| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Intervention Name** | String | Text Input | Yes | Must be unique. Max 100 characters. e.g., "Parent Counseling Session" |
| **Intervention Code**| Alphanumeric | Text Input | Yes | Unique capitalized code. e.g., "DISC_PARENT_COUNSEL" |
| **Intervention Type**| Dropdown | Select | Yes | Options: `Supportive` (Counselling, coaching), `Corrective` (Warning, suspension), `Reinforcement` (Award, recommendation) |
| **Description** | String | Text Area | Yes | Explains the protocol and expectations. Max 500 characters. |
| **Escalation Level** | Dropdown | Select | Yes | Options: `Level 1` (Teacher handled), `Level 2` (Counsellor/HOD), `Level 3` (Principal/Board) |
| **Status** | Boolean | Toggle | Yes | Active/Inactive. Defaults to Active. |

---

## Business Rules and Conditions

**Standardization Enforcement**
- Subject teachers can only view and select interventions during incident logging that match the incident's severity (e.g., a teacher cannot assign a Level 3 "Suspension" intervention directly; they can only suggest it or assign Level 1 interventions).

**Deactivation Protections**
- An intervention cannot be deactivated if it is linked to an open/active incident in `ba_incident_intervention_jnt`.
- Inactive interventions remain linked to historical incidents for record-keeping but are hidden from the dropdown menu on the [Interventions Applied](./14-Interventions-Applied.md) tab.

**Unique Code & Name**
- The system enforces unique combinations of Intervention Codes and Names to prevent administrative duplicate definitions.

---

## Workflow Steps

**Adding a New Intervention**
1. Admin navigates to **Masters -> Interventions** and clicks **Add Intervention**.
2. Fills in the Intervention Name (e.g., "Disciplinary Reflection Assignment") and Intervention Code (e.g., "DISC_REFLECT").
3. Selects Intervention Type as `Corrective`.
4. Selects Escalation Level as `Level 1`.
5. Enters Description: `"Student completes a structured worksheet reflecting on their behaviour, actions, and impact on peers. Checked by the homeroom teacher."`
6. Admin clicks **Save**. The record is successfully written to `ba_interventions`.

**Editing an Intervention**
1. Admin clicks **Edit** on "Suspension Notice".
2. Modifies the description to include: `"Requires a formal parent signature before the student is allowed back in class."`
3. Clicks **Save**. The description updates immediately across all active instances.

---

## Example Scenario

The school counsellor wants to standardize positive reinforcements. The admin registers a new intervention:
- **Intervention Name**: Star Student Badge
- **Intervention Code**: POS_STAR_BADGE
- **Intervention Type**: Reinforcement
- **Escalation Level**: Level 2 (Counsellor/HOD approved)
- **Description**: "Awarded to students exhibiting outstanding empathy and helping behavior. Highlighted during the weekly assembly."

This positive intervention is now ready to be selected in the [Interventions Applied](./14-Interventions-Applied.md) screen.

---

## Related Screens

- [12-Incident-Log.md](./12-Incident-Log.md) — Incidents where these interventions are mapped.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Screen where staff log and update the progress of assigned interventions.
- [24-Incident-Report.md](./24-Incident-Report.md) — Analytics summarizing intervention success rates.
