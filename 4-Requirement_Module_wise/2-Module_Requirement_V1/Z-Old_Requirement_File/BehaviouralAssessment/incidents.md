# Incidents — Requirements

## What It Does
Records ad-hoc behavioural incidents — both positive reinforcement and negative events. Supports severity classification, witness linking, intervention mapping, evidence attachments, and follow-up tracking.

## Database Fields

### `ba_incidents`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED | FK → `std_students.id` (cross-module). Student involved. |
| `reported_by` | INT UNSIGNED | FK → `sch_employees.id` (cross-module). Teacher/staff who reported. |
| `category_id` | BIGINT UNSIGNED | Nullable FK → `ba_categories.id`. Optional linked category. |
| `criterion_id` | BIGINT UNSIGNED | Nullable FK → `ba_criteria.id`. Optional linked criterion. |
| `incident_date` | DATE | Required. Date of incident. |
| `incident_time` | TIME | Nullable. Time of incident. |
| `incident_type` | ENUM('positive_reinforcement','negative_incident') | Required. Positive or negative. |
| `severity` | ENUM('minor','moderate','major','critical') | Nullable. Required for negative; NULL for positive. |
| `description` | TEXT | Required. Detailed description (min 10 chars). |
| `location` | ENUM('classroom','playground','corridor','lab','transport','canteen','library','other') | Default `'classroom'`. Where it occurred. |
| `intervention_notes` | TEXT | Nullable. Free-text action taken. |
| `is_follow_up_required` | BOOLEAN | Default `0`. |
| `follow_up_date` | DATE | Nullable. Scheduled follow-up. |
| `follow_up_notes` | TEXT | Nullable. Appendable after submission. |
| `attachments_json` | JSON | Nullable. File references `[{"media_id":1,"filename":"evidence.jpg"}]`. |
| `is_notified` | BOOLEAN | Default `0`. Whether parent notification was sent. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `ba_incident_witnesses_jnt`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `incident_id` | BIGINT UNSIGNED | FK → `ba_incidents.id`. Parent incident. |
| `witness_type` | ENUM('student','staff') | Required. Type of witness. |
| `witness_id` | INT UNSIGNED | Polymorphic: `std_students.id` or `sch_employees.id`. No DB-level FK. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |

**Unique Constraints:**
- `uq_ba_witness` — `(incident_id, witness_type, witness_id)`: no duplicate witnesses.

### `ba_incident_intervention_jnt`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `incident_id` | BIGINT UNSIGNED | FK → `ba_incidents.id`. |
| `intervention_id` | BIGINT UNSIGNED | FK → `ba_interventions.id`. |
| `notes` | VARCHAR(500) | Nullable. Additional notes. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |

**Unique Constraints:**
- `uq_ba_inc_int` — `(incident_id, intervention_id)`: no duplicate intervention mappings.

## Business Rules

**Immutability (BR-BA-008)**
- Core fields (`student_id`, `incident_date`, `incident_time`, `incident_type`, `severity`, `description`, `location`) cannot be edited after creation.
- Only follow-up fields (`follow_up_notes`, `follow_up_date`, `is_follow_up_required`) can be appended/updated post-creation.
- Enforced at the service layer.

**Parent Notification (BR-BA-015)**
- Notification triggered for incidents with severity ≥ `ba_config.parent_notification_threshold`.
- Default threshold: `moderate`.
- `is_notified` flag tracks whether notification was sent.
- Delegates to the Notification module (no SMS/Push channel logic in BA).

**Witness Linking**
- Witnesses are polymorphic — can be students or staff.
- Multiple witnesses can be linked to a single incident.
- At least one witness must exist if witnesses are provided.

**Intervention Mapping**
- Multiple interventions can be mapped to a single incident via `ba_incident_intervention_jnt`.
- Interventions selected from the master list (`ba_interventions`).
- Teachers can also provide free-text `intervention_notes` without selecting from the list.

## CRUD Operations

**Create**
- Route: `POST /behavioural-assessment/incidents` → form with student auto-suggest, category/criterion dropdowns, witness multi-select, intervention checkboxes
- Validates: `student_id` exists; `incident_date` before or equal today; `incident_type` enum; `severity` required for negative; `description` min:10; `location` enum
- Auto-computes `is_notified` based on severity vs config threshold
- Fires `IncidentCreated` event

**List**
- Route: `GET /behavioural-assessment/incidents` → filterable list (by student, type, severity, date range, location)
- Shows: student, type badge, severity badge, date, reported by, follow-up indicator, actions

**View**
- Route: `GET /behavioural-assessment/incidents/{incident}` → full detail with witnesses, interventions, follow-up timeline

**Add Follow-Up**
- Route: `POST /behavioural-assessment/incidents/{incident}/follow-up`
- Validates: `notes` required min:10; `follow_up_date` nullable after today
- Updates `follow_up_notes`, `follow_up_date`, `is_follow_up_required`

**Student Timeline**
- Route: `GET /behavioural-assessment/incidents/student/{student}/timeline` → chronological incident history grouped by month
- Used within student behavioural report and incident dashboard

**Delete (Soft)**
- Route: `DELETE /behavioural-assessment/incidents/{incident}` → SweetAlert2 confirmation → soft delete

## Permissions

| Operation | Permission Key |
|---|---|
| View incidents tab | `tenant.ba.incident.viewAny` |
| View incident details | `tenant.ba.incident.viewAny` |
| Create incident | `tenant.ba.incident.create` |
| Add follow-up | `tenant.ba.incident.manage` |
| View student timeline | `tenant.ba.incident.viewAny` |
