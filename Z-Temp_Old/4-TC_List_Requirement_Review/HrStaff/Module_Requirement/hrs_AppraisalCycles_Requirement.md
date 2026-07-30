# Appraisal Cycles — Business Requirements

## What This Screen Does

Appraisal Cycles define the time-bound performance review periods for employees. Each cycle specifies date windows for self-assessment and manager review, the KPI template used for evaluation, the type of appraisal (annual, mid-year, probation, or confirmation), and which departments participate. Cycles progress through a three-state lifecycle: draft (setup), active (appraisals in progress), and closed (all appraisals finalized).

The system generates individual appraisal records for each eligible employee when HR activates the cycle. A cycle can optionally restrict participants by department and by the KPI template's staff category applicability.

---

## When This Screen Is Used

- Annual Appraisal Setup when HR creates the yearly review cycle at the start of the academic session
- Mid-Year Review when HR runs a half-yearly check on employee performance
- Probation/Confirmation Review when new employees complete their probation period
- Reviewer Assignment when HR decides whether reviewers are auto-assigned from hierarchy or manually selected

---

## Default Data Load

The Appraisal Cycles tab loads via `HrMenuController@appraisalsIncrements()` (GET `/appraisals-overview?tab=appraisal-cycles`). A standalone index page exists at `GET /appraisal-cycles` via `AppraisalController@cycleIndex()`. Both load all active `AppraisalCycle` records with `academicYear` and `kpiTemplate` relationships, ordered descending by `self_open_date`, with no pagination. The edit form additionally loads active KPI templates, academic sessions, and departments for dropdown selection.

---

## Key Fields at a Glance

**Cycle Identity and Timing**
The Cycle Name identifies the review period, like "Annual Appraisal 2025-26". The Academic Year links the cycle to the school's session calendar. The Appraisal Type selects one of four modes: annual (all employees), mid-year (optional half-yearly), probation (employees nearing probation end), or confirmation (post-probation confirmation).

**Date Windows**
Self-Appraisal Open/Close Dates define when employees can submit their self-ratings. Manager Review Open/Close Dates define when reviewers submit their evaluations. The manager open date must be on or after the self close date to ensure self-appraisal closes before manager review begins (BR-HRS-018).

**Template and Participants**
The KPI Template provides the evaluation criteria. Applicable Departments restricts the cycle to specific departments (NULL = all departments). The Reviewer Mode toggles between auto (uses the employee's reporting hierarchy from `sch_employees_profile`) and manual (HR explicitly assigns reviewers).

---

## Business Rules and Conditions

**Self-Close Before Manager Open**
The system enforces `manager_open_date >= self_close_date`. If this validation fails, the service throws a `DomainException` with the message "Manager open date must be on or after self-appraisal close date (BR-HRS-018)."

**Cycle State Machine**
A cycle lives in one of three statuses: `draft` (setup phase, editable), `active` (appraisals generated and in progress), or `closed` (all appraisals finalized). Only draft cycles can be updated or deleted. The `AppraisalCyclePolicy` enforces that `update` and `delete` require `hrs.appraisal.manage` AND status must be `draft`.

**Update Restriction by Status**
The `updateCycle()` service method checks that `cycle->status === 'draft'` before applying changes. If the cycle has moved past draft, a DomainException is thrown with "Cannot update cycle with status: {status}".

**Delete Protection**
A cycle cannot be deleted if it has appraisal records. The controller checks `appraisals()->exists()` before deletion.

---

## Workflow Steps

**Creating and Activating a Cycle**
HR navigates to Appraisals → Appraisal Cycles, clicks Add Cycle. HR enters "Annual Appraisal 2025-26", selects the current academic year, picks "annual" as the type, selects the "Teaching KPI" template, sets Self-Open to 01-Jan-2026, Self-Close to 31-Jan-2026, Manager-Open to 01-Feb-2026, Manager-Close to 28-Feb-2026, selects all departments, chooses "auto" reviewer mode, and saves. The cycle is created in draft status. HR then generates appraisal records for the cycle. The cycle transitions to active.

---

## Example Scenario

A school runs a mid-year appraisal in October 2025. HR creates a cycle named "Mid-Year 2025-26" with type `mid_year`, academic year 2025-26, using the "Teaching KPI" template (5-point scale, 4 items). Self dates: 01-Oct to 15-Oct. Manager dates: 16-Oct to 31-Oct. HR selects departments "Primary" and "Secondary", sets reviewer mode to "auto". After saving in draft, HR clicks "Generate Appraisals" to create appraisal records for all teachers in those departments. The cycle is now active.

---

## Related Screens

- **KPI Templates** — Provides the evaluation criteria used by the cycle
- **Appraisals** — Individual employee appraisal records generated for this cycle
- **Increment Policies** — May reference the cycle's finalized ratings for increment processing

---

## Requirements

- `AppraisalController@cycleIndex()` lists active cycles with `academicYear` and `kpiTemplate` relationships, ordered desc by `self_open_date`, gated by `hrs.appraisal.manage`.
- `AppraisalController@cycleStore()` validates via `StoreAppraisalCycleRequest`, delegates to `AppraisalService@createCycle()` which validates `manager_open_date >= self_close_date` (BR-HRS-018), sets `status=draft`, creates the cycle, logs activity, returns JSON or redirect with success. Catches `DomainException` for date validation failure.
- `AppraisalController@cycleShow()` loads a cycle with `kpiTemplate.items`, `appraisals.employee`, and `academicYear`, gated by `hrs.appraisal.manage`.
- `AppraisalController@cycleEdit()` loads the cycle plus active KPI templates, academic sessions, and departments for form dropdowns.
- `AppraisalController@cycleUpdate()` delegates to `AppraisalService@updateCycle()` which checks status is `draft` and re-validates date ordering if dates provided.
- `AppraisalController@cycleToggleStatus()` flips `is_active` boolean via AJAX, gated by `hrs.appraisal.manage`.
- `AppraisalController@cycleDestroy()` checks `appraisals()->exists()` — if true, returns back with error "Cannot delete a cycle that has appraisals linked to it."; otherwise sets `is_active=false`, soft-deletes, logs activity.
- Standard trash/restore/forceDelete methods for appraisal cycles with pagination (15/page for trash).
- `StoreAppraisalCycleRequest` rules: `name` required|string|max:200, `academic_year_id` required|exists:sch_org_academic_sessions_jnt,id, `appraisal_type` required|in:annual,mid_year,probation,confirmation, `kpi_template_id` required|exists:hrs_kpi_templates,id, `self_open_date` required|date, `self_close_date` required|date|after:self_open_date, `manager_open_date` required|date|after_or_equal:self_close_date, `manager_close_date` required|date|after:manager_open_date, `applicable_departments` nullable|array, `applicable_departments.*` integer|exists:sch_departments,id, `reviewer_mode` required|in:auto,manual, `is_active` required|boolean.
- `StoreAppraisalCycleRequest::prepareForValidation()` merges `is_active` as boolean with default `true`.
- `StoreAppraisalCycleRequest::attributes()` sets friendly attribute names for validation messages.
- `AppraisalCyclePolicy`: `update` and `delete` require `hrs.appraisal.manage` AND `cycle->status === 'draft'`; `forceDelete` always returns false.
- `AppraisalCycle` model: `$casts` self_open_date, self_close_date, manager_open_date, manager_close_date => date; applicable_departments => array; is_active => boolean.

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `hrs.appraisal.manage` | All cycle methods | HR role — every cycle operation requires this permission |
| Guest | — | No access — redirected to /login |

`AppraisalCyclePolicy` additionally restricts `update` and `delete` to draft-status cycles. `forceDelete` always returns false (not permitted).

---

## Logic Flow

1. **Page Load**: `cycleIndex()` gates, fetches active cycles with `academicYear` and `kpiTemplate` eager-loaded, ordered desc by `self_open_date`, returns view.
2. **Create**: `cycleStore()` validates via request. The `AppraisalService@createCycle()` checks `manager_open_date >= self_close_date` (BR-HRS-018). Sets `status='draft'`, `created_by`/`updated_by`. Creates cycle. Logs activity. Returns JSON (if API) or redirect with flash.
3. **Edit/Update**: `cycleUpdate()` calls `AppraisalService@updateCycle()` which first validates `cycle->status === 'draft'`, then if dates are present re-validates BR-HRS-018. Updates cycle. Logs activity. Redirects.
4. **Toggle Status**: `cycleToggleStatus()` flips `is_active`, returns JSON.
5. **Delete**: `cycleDestroy()` checks `appraisals()->exists()`. If exists, returns error. Otherwise sets `is_active=false`, soft-deletes, logs, redirects.
6. **Trash/Restore/ForceDelete**: Standard pattern. `forceDelete` is gated by policy which returns false (no force-delete permitted).

---

## Validate Before Save

| Field | Rule(s) | Error Message |
|---|---|---|
| name | required, string, max:200 | — |
| academic_year_id | required, exists:sch_org_academic_sessions_jnt,id | — (attributes: "Academic Year") |
| appraisal_type | required, in:annual,mid_year,probation,confirmation | — |
| kpi_template_id | required, exists:hrs_kpi_templates,id | — (attributes: "KPI Template") |
| self_open_date | required, date | — (attributes: "Self-Appraisal Open Date") |
| self_close_date | required, date, after:self_open_date | — (attributes: "Self-Appraisal Close Date") |
| manager_open_date | required, date, after_or_equal:self_close_date | — (attributes: "Manager Review Open Date") |
| manager_close_date | required, date, after:manager_open_date | — (attributes: "Manager Review Close Date") |
| applicable_departments | nullable, array | — |
| applicable_departments.* | integer, exists:sch_departments,id | — |
| reviewer_mode | required, in:auto,manual | — |
| **Service-level** | `manager_open_date >= self_close_date` | "Manager open date must be on or after self-appraisal close date (BR-HRS-018)." |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Date rule BR-HRS-018 violation | "Manager open date must be on or after self-appraisal close date (BR-HRS-018)." | DomainException (422 JSON / flash error) |
| Update non-draft cycle | "Cannot update cycle with status: {status}" | DomainException (flash error) |
| Delete cycle with appraisals | "Cannot delete a cycle that has appraisals linked to it." | Controller check (back with error) |
| Toggle status success | "Status updated successfully." | JSON response |
| Store success | "Appraisal cycle created." | Flash success |
| Update success | "Appraisal cycle updated." | Flash success |
| Remove success | "Appraisal cycle removed." | Flash success |
| Restore success | "Appraisal cycle restored successfully." | Flash success |

---

## Success Scenarios

**SC-001 — Create Cycle in Draft**: HR creates an annual cycle with valid dates (self 01-Jan to 31-Jan, manager 01-Feb to 28-Feb). Service validates BR-HRS-018, sets status=draft, creates the cycle, logs activity, and redirects with success.

**SC-002 — Update Draft Cycle**: HR changes the self_close_date of a draft cycle from 31-Jan to 25-Jan. Service verifies status=draft, re-validates dates, applies changes.

**SC-003 — Delete Draft Cycle with No Appraisals**: HR deletes a draft cycle that has no generated appraisals. Controller confirms `appraisals()->exists()` is false, soft-deletes, redirects.

---

## Failure Scenarios

**FC-001 — Manager Open Before Self Close**: HR sets self_close_date=31-Jan and manager_open_date=30-Jan. Service throws DomainException "Manager open date must be on or after self-appraisal close date (BR-HRS-018)."

**FC-002 — Update Active Cycle**: HR attempts to edit a cycle in active status. `updateCycle()` service throws DomainException "Cannot update cycle with status: active."

**FC-003 — Delete Cycle with Appraisals**: HR attempts to delete a cycle that has appraisal records. Controller returns back with error "Cannot delete a cycle that has appraisals linked to it."

---

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `hrs_kpi_templates.id` | FK parent | `kpi_template_id` references `hrs_kpi_templates.id` |
| `sch_org_academic_sessions_jnt.id` | FK parent | `academic_year_id` references academic sessions, FK ON DELETE — |
| `sch_departments.id` | FK parent | `applicable_departments` JSON array references department IDs |
| `hrs_appraisals.cycle_id` | Child FK | Appraisal records cascade — blocks delete via controller check `appraisals()->exists()` |
| `pay_increment_policies.appraisal_cycle_id` | Child FK | Increment policies may reference cycle; nullable |
| `hrs_appraisal_increment_flags.cycle_id` | Child FK | Denormalised flag records |

**Table:** `hrs_appraisal_cycles`

| Column | Type | Details |
|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| name | VARCHAR(200) | NOT NULL |
| academic_year_id | SMALLINT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` |
| appraisal_type | ENUM('annual','mid_year','probation','confirmation') | NOT NULL |
| kpi_template_id | BIGINT UNSIGNED | NOT NULL, FK → `hrs_kpi_templates.id` |
| self_open_date | DATE | NOT NULL |
| self_close_date | DATE | NOT NULL |
| manager_open_date | DATE | NOT NULL |
| manager_close_date | DATE | NOT NULL |
| applicable_departments | JSON | NULL, array of `sch_departments.id` |
| reviewer_mode | ENUM('auto','manual') | NOT NULL, DEFAULT 'auto' |
| status | ENUM('draft','active','closed') | NOT NULL, DEFAULT 'draft' |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
