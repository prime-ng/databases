# Behavior Incidents — Business Requirements

## What This Screen Does

The Behavior Incidents screen tracks disciplinary incidents involving enrolled students. Each incident records the type, severity, description, location, witnesses, and a behavior score impact that integrates with merit/grading systems. Incidents progress through a lifecycle: Open → Action_Taken → Closed (or Escalated). Multiple corrective actions (Warning, Detention, Suspension, etc.) can be logged per incident.

This is the fourth tab (`?tab=incidents`) of the Promotions & Alumni page at `/admission/promotions-alumni`.

The module supports 8 incident types and 7 action types. Critical severity incidents automatically trigger notifications to the principal and parent.

## When This Screen Is Used

- **Incident Logging**: Recording disciplinary incidents as they occur
- **Action Tracking**: Documenting corrective actions taken (warnings, detention, suspension, etc.)
- **Incident Resolution**: Reviewing and closing incidents after action is taken
- **Behavior Score Impact**: Tracking behavior score deductions for merit/grading integration
- **Parent Notification**: Logging parent communication for serious incidents
- **Audit**: Reviewing incident history per student

## Key Fields

**Incident**
- Student (FK → std_students)
- Incident Date, Location
- Incident Type — Bullying, Cheating, Disruption, Absenteeism, Vandalism, Violence, Misconduct, Other
- Severity — Low, Medium, High, Critical
- Description (required)
- Witnesses (JSON array)
- Reported By (staff)
- Parent Notified (boolean + timestamp)
- Status — Open (default), Action_Taken, Closed, Escalated
- Behavior Score Impact — signed TINYINT (-127 to 127)

**Corrective Action**
- Action Type — Warning, Detention, Suspension, Expulsion, Parent_Meeting, Counseling, Community_Service
- Description
- Start Date, End Date (must be after start date)
- Parent Meeting Date, Meeting Outcome
- Action By (staff)

## Business Rules

**Incident Lifecycle:** Incidents start as Open. Staff can move them to Action_Taken (via review) or directly to Closed. Escalated status is for incidents that require higher authority intervention. The lifecycle is:
- Open → Action_Taken → Closed
- Open → Escalated → Closed
- Open → Closed (direct)

**Critical Severity Auto-Notify:** When an incident with severity = Critical is created, the system automatically sets `parent_notified = true` and triggers notifications to both the principal and the parent (via NTF notification system, as noted in the DDL comment).

**Behavior Score Impact:** The `behavior_score_impact` field is a signed TINYINT allowing values from -127 to 127. Negative values represent score deductions for merit/grading purposes. The validation enforces this range (±127).

**Multiple Actions:** An incident can have multiple corrective actions logged against it. When an incident is soft-deleted, all associated actions are cascade-deleted (FK CASCADE).

**Witnesses Storage:** The `witnesses_json` field stores an array of witness names as a JSON string. The request prepares the data by splitting a comma-separated input string into an array.

**Action Validation:** Corrective actions validate that `end_date` is after `start_date` (via `after:start_date` rule). Date fields are nullable to support different action types (e.g., Warning may not need dates, but Detention requires a date range).

## Workflow

1. Staff logs an incident with student, type, severity, description, and optional details
2. System creates the incident as Open with parent_notified based on severity
3. Staff can update the incident with more details as they become available
4. Staff takes corrective action(s) and logs them to the incident
5. Staff reviews the incident (→ Action_Taken) after initial action is taken
6. Staff closes the incident once fully resolved
7. The incident remains available for audit and reporting

## Related Screens

- **Alumni Tab** — Students who may have behavior records
- **TCs Tab** — Conduct grade on TC may reference incident history
- **Incident Show** — Detail view with actions list and add action form

## Requirements

- MUST display paginated incidents list with search (student), severity filter, status filter
- MUST authorize via `tenant.adm-incident.*` policy gates
- MUST validate store with 9 rules including score_impact range -127..127
- MUST validate action store with type enum, end_date after start_date
- MUST default status=Open, parent_notified=false on create
- MUST support review (→Action_Taken) and close (→Closed) transitions
- MUST support AJAX CRUD via modals (create, edit)
- MUST support multiple corrective actions per incident
- MUST store witnesses as JSON array
- MUST support soft-delete lifecycle with restore/force-delete
- MUST provide AJAX toggle-status endpoint
- MUST show severity badges (Low=success, Medium=warning, High=danger, Critical=dark)
- MUST show status badges (Open=primary, Action_Taken=info, Closed=secondary, Escalated=danger)
- MUST log all operations via activityLog()
