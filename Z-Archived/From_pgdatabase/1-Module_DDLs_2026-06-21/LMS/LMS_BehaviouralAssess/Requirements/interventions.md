# Interventions — Requirements

## What It Does
Master list of predefined intervention types that can be applied in response to behavioural incidents. Covers three categories: reward (positive reinforcement), corrective (disciplinary action), and counselling (supportive guidance).

## Database Fields

### `ba_interventions`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(100) | Required. Intervention name (e.g., "Verbal Warning", "Award/Certificate"). |
| `description` | TEXT | Nullable. Detailed description. |
| `intervention_type` | ENUM('reward','corrective','counselling') | Required. Type classification. |
| `sort_order` | TINYINT UNSIGNED | Required. Display order in UI. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

**Three Types**

| Type | Purpose | Examples |
|---|---|---|
| **Reward** | Positive reinforcement for good behaviour | Award/Certificate, Public Recognition, Extra Privileges |
| **Corrective** | Disciplinary action for negative behaviour | Verbal Warning, Written Warning, Detention, Suspension |
| **Counselling** | Supportive guidance involving professionals | Parent Meeting, Counselling Referral |

**Usage in Incidents**
- Teachers select one or more interventions from this list when logging an incident.
- Mapped via `ba_incident_intervention_jnt` junction table.
- Teachers can also provide free-text `intervention_notes` in addition to or instead of selecting from the list.

**Seeded Data**
- 9 interventions provisioned during tenant onboarding:
  - 3 Reward: Award/Certificate, Public Recognition, Extra Privileges
  - 4 Corrective: Verbal Warning, Written Warning, Detention, Suspension
  - 2 Counselling: Parent Meeting, Counselling Referral

## CRUD Operations

**Create**
- Route: `POST /behavioural-assessment/interventions` → form
- Validates: `name` required max:100; `intervention_type` enum; `sort_order` integer

**List**
- Route: `GET /behavioural-assessment/interventions` → table grouped by type (reward/corrective/counselling)
- Shows: name, type badge, sort order, active/inactive, action buttons

**View**
- Route: `GET /behavioural-assessment/interventions/{intervention}` → detail with usage count (how many incidents reference this intervention)

**Update**
- Route: `PUT /behavioural-assessment/interventions/{intervention}` → validates → updates

**Delete (Soft)**
- Route: `DELETE /behavioural-assessment/interventions/{intervention}` → blocked if referenced by any incidents
- Deactivate via `is_active = false` instead of delete if references exist

## Permissions

| Operation | Permission Key |
|---|---|
| View interventions tab | `tenant.ba.intervention.manage` |
| View intervention details | `tenant.ba.intervention.manage` |
| Create intervention | `tenant.ba.intervention.manage` |
| Update intervention | `tenant.ba.intervention.manage` |
| Delete intervention | `tenant.ba.intervention.manage` |
