# Behavior Incidents — Requirements

## What It Does
Track disciplinary incidents for enrolled students. Record incidents with severity levels, log corrective actions via action tracking, compute behavior impact scores, and auto-notify parents/principal for critical incidents.

## Database Fields

### `adm_behavior_incidents`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED | FK → `std_students.id`. |
| `incident_date` | DATE | Required. |
| `incident_type` | ENUM('Bullying','Cheating','Disruption','Absenteeism','Vandalism','Violence','Misconduct','Other') | Required. |
| `severity` | ENUM('Low','Medium','High','Critical') | Required. |
| `description` | TEXT | Required. |
| `location` | VARCHAR(100) | Nullable. |
| `witnesses_json` | JSON | Nullable. Array of witness names. |
| `reported_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. |
| `parent_notified` | BOOLEAN | Default `0`. |
| `parent_notified_at` | TIMESTAMP | Nullable. |
| `status` | ENUM('Open','Action_Taken','Closed','Escalated') | Default `'Open'`. |
| `behavior_score_impact` | TINYINT (signed) | Default `0`. Signed — negative = deduction. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `adm_behavior_actions`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `incident_id` | BIGINT UNSIGNED | FK → `adm_behavior_incidents.id`. |
| `action_type` | ENUM('Warning','Detention','Suspension','Expulsion','Parent_Meeting','Counseling','Community_Service') | Required. |
| `description` | TEXT | Nullable. |
| `start_date` | DATE | Nullable. |
| `end_date` | DATE | Nullable. |
| `parent_meeting_date` | DATETIME | Nullable. |
| `meeting_outcome` | TEXT | Nullable. |
| `action_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

**Severity-Based Notification**
- Critical severity incidents auto-notify principal AND parent via NTF module.
- `parent_notified` flag set to 1 after successful dispatch.

**Behavior Score Computation**
- `AdmissionAnalyticsService::computeBehaviorScore(studentId, sessionId)`: sums `behavior_score_impact` across incidents.
- Baseline: 100 points.
- Resets at new academic session start.
- `behavior_score_impact` is signed TINYINT — negative values for deductions (e.g., -5 for Medium severity).

**Incident Workflow (FSM)**
```
Open → Action_Taken → Closed
  ↓                      ↓
Escalated            (terminal)
```

| Transition | Trigger | Pre-conditions |
|---|---|---|
| `Open → Action_Taken` | Corrective action logged | At least one `adm_behavior_action` created |
| `Open → Escalated` | Incident escalated to higher authority | Reason required |
| `Action_Taken → Closed` | Incident resolved | All actions completed |
| `Action_Taken → Escalated` | Further escalation needed | Reason required |

**Multiple Actions**
- Multiple corrective actions can be associated with one incident.
- Parent meetings can be scheduled as part of corrective action.

## CRUD Operations

**Create**
- Route: `POST /admission/behavior/incidents` → log incident with type, severity, description, location, witnesses
- Validates: student_id exists; incident_date before or equal today; severity required; description min:10
- Severe/Critical incidents auto-set `parent_notified`

**List**
- Route: `GET /admission/behavior/incidents` → filterable table (by student, severity, status, date range, incident_type)

**View**
- Route: `GET /admission/behavior/incidents/{incident}` → detail with actions timeline, parent notification status

**Add Action**
- Route: `POST /admission/behavior/incidents/{incident}/actions` → log corrective action (type, description, dates)
- Changes incident status to Action_Taken if currently Open

**Update Status**
- Route: `PATCH /admission/behavior/incidents/{incident}/status` → Close or Escalate

**Delete (Soft)**
- Route: `DELETE /admission/behavior/incidents/{incident}` → completed incidents retain record

## Permissions

| Operation | Permission Key |
|---|---|
| View behavior tab | `tenant.adm.behavior.viewAny` |
| Create incident | `tenant.adm.behavior.create` |
| Add action | `tenant.adm.behavior.update` |
| Close/escalate incident | `tenant.adm.behavior.update` |
