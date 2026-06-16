# Assessment Periods — Requirements

## What It Does
Defines time windows during which teachers record behavioural assessments. Periods follow an open → closed → locked lifecycle and can optionally link to academic exam terms for report card integration.

## Database Fields

### `ba_assessment_periods`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `academic_session_id` | SMALLINT UNSIGNED | FK → `sch_org_academic_sessions_jnt.id` (cross-module). `ON DELETE RESTRICT`. |
| `academic_term_id` | SMALLINT UNSIGNED | Nullable FK → `sch_academic_term.id` (cross-module). Optional term linking. `ON DELETE SET NULL`. |
| `name` | VARCHAR(100) | Required. Period name (e.g., "Term 1 Assessment"). |
| `start_date` | DATE | Required. Assessment window start. |
| `end_date` | DATE | Required. Assessment window end. |
| `deadline` | DATE | Required. Teacher submission deadline. |
| `status` | ENUM('open','closed','locked') | Default `'open'`. Period lifecycle status. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

**Date Validation**
- `start_date < end_date` — assessment window must have positive duration.
- `deadline >= end_date` — teachers get at least until the window closes to submit.
- All dates must fall within the academic session's range.

**Lifecycle (FSM)**
```
open ──close()──▶ closed ──lock()──▶ locked (terminal)
   ▲                  │
   └── reopen() ──────┘
```

| Transition | Trigger | Pre-conditions | Side Effects |
|---|---|---|---|
| `open → closed` | Admin closes period / deadline passes | — | No NEW assessments can be created; existing drafts remain editable |
| `closed → open` | Admin reopens period | Must have `ba.period.manage` permission | Period reopened for entry |
| `closed → locked` | Admin locks period | ALL assessments in period must be `reviewed` status | All assessments → `locked`; scores computed; available for report cards |

**Academic Term Linking**
- `academic_term_id` is optional — periods can exist independently of exam terms.
- If linked, behavioural scores appear alongside term-wise exam results.
- Multiple periods can exist within a single academic term.

**Locked Periods (BR-BA-003)**
- A locked period prevents ALL edits to assessments, ratings, and remarks within that period.
- Checked at the service layer before any write operation.
- Scores are finalised and cached in `ba_computed_scores`.

## CRUD Operations

**Create**
- Route: `POST /behavioural-assessment/periods` → via modal form
- Validates: `name` required, `start_date` < `end_date`, `deadline` >= `end_date`, `academic_session_id` exists
- Default status: `open`

**List**
- Route: `GET /behavioural-assessment/periods` → table with status badges (open/closed/locked), date ranges, term link, assessment completion stats

**View**
- Route: `GET /behavioural-assessment/periods/{period}` → detail with completion status per teacher

**Update**
- Route: `PUT /behavioural-assessment/periods/{period}` → cannot edit a locked period
- Validates same rules as create

**Delete (Soft)**
- Route: `DELETE /behavioural-assessment/periods/{period}` → cannot delete if assessments exist
- Pre-delete: deactivate (`is_active = false`) if assessments exist

**Lock/Unlock**
- Routes: `POST /behavioural-assessment/periods/{period}/lock`, `POST /behavioural-assessment/periods/{period}/unlock`
- Lock: validates all assessments are `reviewed`; transitions all to `locked`; fires `ScoresComputed` event
- Unlock: reverses lock (only from locked → closed)

## Permissions

| Operation | Permission Key |
|---|---|
| View periods tab | `tenant.ba.period.viewAny` |
| View period details | `tenant.ba.period.viewAny` |
| Create period | `tenant.ba.period.manage` |
| Update period | `tenant.ba.period.manage` |
| Delete period | `tenant.ba.period.manage` |
| Lock/unlock period | `tenant.ba.period.manage` |
