# Publishing & Approval Workflow — Business Requirements

## What This Screen Does

The Publishing & Approval Workflow governs how a manually built standard timetable transitions from an editable draft to a finalized published schedule. Once a timetable reaches the PUBLISHED state, it becomes the school's authoritative schedule — all cells become immutable, and the timetable is considered final for the academic term.

The workflow supports three operations: submitting a draft for review (submitForApproval), approving a submitted timetable (approve), and a direct publish bypass that jumps from DRAFT or GENERATED straight to PUBLISHED (publish). Every state transition is logged to the activity trail.

---

## When This Screen Is Used

- **Draft Submission** when a timetable coordinator has finished placing all cells and wants to alert an approver that the timetable is ready for review
- **Approval Gate** when a principal or vice-principal reviews the submitted timetable and either approves it to lock it as final
- **Direct Publishing** when the same user who built the timetable also has publishing authority and can bypass the two-step submit-then-approve flow
- **Post-Publishing Lockdown** after PUBLISHED, no further cell placement, removal, or locking changes are permitted — ensuring timetable integrity for the term

---

## Default Data Load

These are action endpoints (POST routes), not data-loading screens. The operations are triggered from action buttons on the manual-placement page (`POST submit-for-approval/{id}`, `POST approve/{id}`, `POST publish/{id}`) under the Manual Placement tab group. No default grid or dropdown data is loaded — the timetable record is fetched by ID, its current status checked, and the state transition applied.

---

## Key Fields at a Glance

**Status State Machine**
The `tt_timetables.status` column drives the entire workflow. It is an ENUM with values: `DRAFT`, `GENERATING`, `GENERATED`, `PUBLISHED`, `ARCHIVED`. The publishing workflow only transitions through DRAFT → GENERATED → PUBLISHED. GENERATING and ARCHIVED are used by other flows (auto-generation and archival).

**Automation Timestamps**
The `published_at` datetime column is set to `now()` at the moment the timetable reaches PUBLISHED status. This provides an immutable audit trail of when the timetable became final.

---

## Business Rules and Conditions

**State Transition Rules**
Only a timetable with status `DRAFT` can be submitted for approval (`submitForApproval`). After submission, the status moves to `GENERATED`. Only a timetable with status `GENERATED` can go through the approval gate (`approve`). The `publish` method accepts either `DRAFT` or `GENERATED` — any other status returns a 422 error with the message "Timetable cannot be published from current state."

**Published Timetable Immutability**
Once `PUBLISHED`, the timetable is locked against all editing. The controller methods `placeCell`, `removeCell`, `lockCell`, `unlockCell`, and `lockAll` each check `if ($timetable->status === 'PUBLISHED')` and reject the operation with "Published timetables are immutable." at 422. Only admin force-deletion can remove a published timetable.

**Activity Logging**
Every status transition is recorded by the `activityLog()` helper with a unique action name: `Submitted` (for submitForApproval), `Published` (for approve and publish). The log entry includes the performed-by user and a descriptive message.

**FRD Gap — One-Published-Per-Term Rule (BR-TTS-005)**
The FRD specifies that only one timetable per academic term and timetable type should be allowed in PUBLISHED status. The current controller code does not enforce this rule — multiple timetables for the same term and type can be published independently. This is a documented gap.

**FRD Gap — Notification on Status Change**
The FRD envisions email or in-app notifications when a timetable is submitted or approved. No notification logic is implemented in the current code.

**Not Implemented — Print/Export**
There is no print CSS, PDF export button, or export endpoint on any publishing screen. Users cannot generate a printable version of the final timetable.

---

## Workflow Steps

**Standard Two-Step Approval**
1. The timetable coordinator prepares the draft timetable and clicks the "Submit for Approval" button.
2. The system verifies the timetable is in DRAFT state and transitions it to GENERATED.
3. The activity log records the submission with the coordinator's name.
4. The approver (principal/vice-principal) opens the timetable, reviews the cells, and clicks "Approve."
5. The system verifies the timetable is in GENERATED state and transitions it to PUBLISHED, setting `published_at` to the current timestamp.
6. The activity log records the publication with the approver's name.
7. All cells become immutable — no further edits allowed.

**Direct Publish Bypass**
1. An authorized user clicks "Publish" directly from the manual placement page.
2. The system accepts the timetable whether it is in DRAFT or GENERATED state.
3. The status moves to PUBLISHED with `published_at = now()`, same immutability rules apply.

---

## Example Scenario

Ms. Sharma, the timetable coordinator at Delhi Public School, builds the Class 10 Standard Timetable with 48 cells placed across 6 days. She clicks "Submit for Approval." The system changes the status from DRAFT to GENERATED and logs "Timetable 'Class 10 Standard' submitted for approval by Ms. Sharma." Principal Gupta logs in, navigates to the manual placement page, selects the GENERATED timetable, reviews the grid, and clicks "Approve." The system publishes it with `published_at = 18-07-2026 14:30:00`. From this point, no teacher can drag a new activity into any cell.

---

## Related Screens

- **Manual Placement** — Where timetable cells are placed, removed, locked, and unlocked before publishing
- **Copy Timetable** — Creates a copy of an existing timetable in DRAFT status, usable as a template for a new term
- **Cell Lock/Unlock** — Mark individual cells as locked to prevent accidental removal before the full review
- **Timetable Views (Class/Teacher/Room)** — Read-only displays of the final published timetable after approval

---

## Requirements

- Controller `StandardTimetableController` implements three publishing methods:
  - `submitForApproval(int $id)` lines 658-675: checks status `!== 'DRAFT'` → 422; sets `status = 'GENERATED'`; logs activity `Submitted`; gated by `standard-timetable.publish`
  - `approve(int $id)` lines 677-694: checks status `!== 'GENERATED'` → 422; sets `status = 'PUBLISHED'` + `published_at = now()`; logs activity `Published`; gated by `standard-timetable.publish`
  - `publish(int $id)` lines 696-713: checks status not in `['DRAFT', 'GENERATED']` → 422; sets `status = 'PUBLISHED'` + `published_at = now()`; logs activity `Published`; gated by `standard-timetable.publish`
- Routes (web.php): `POST submit-for-approval/{id}` (name: `submitForApproval`), `POST approve/{id}` (name: `approve`), `POST publish/{id}` (name: `publish`)
- All three methods gate via `standard-timetable.publish` permission through `StandardTimetablePolicy::publish()`
- Route model binding uses `Timetable::where('generation_method', 'MANUAL')->findOrFail($id)` — only manual timetables are publishable
- `activityLog()` records every state change with action name (`Submitted`, `Published`), message, and `performed_by`
- Published immutable check in `placeCell`, `removeCell`, `lockCell`, `unlockCell`, `lockAll` — each returns `422` with "Published timetables are immutable."
- No validation form request — all checks are inline controller logic
- No notification, email, or event/listener system tied to status transitions
- No one-published-per-term uniqueness enforcement — multiple PUBLISHED timetables for same term + type are allowed

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `standard-timetable.publish` | `submitForApproval()`, `approve()`, `publish()` | Single permission gates all three operations; typically assigned to principal/vice-principal role |
| Policy | `StandardTimetablePolicy::publish()` | Delegates to `$user->can('standard-timetable.publish')` |

---

## Logic Flow

**1. submitForApproval**
- Gate: `Gate::authorize('standard-timetable.publish')`
- Load timetable by ID with `Timetable::where('generation_method', 'MANUAL')->findOrFail($id)`
- Validate: if status is not `DRAFT`, return 422 JSON `"Only draft timetables can be submitted."`
- Update: `$timetable->update(['status' => 'GENERATED'])`
- Log: `activityLog($timetable, 'Submitted', ...)`
- Return: JSON success `"Timetable submitted for approval."`

**2. approve**
- Gate: `Gate::authorize('standard-timetable.publish')`
- Load timetable by ID with `Timetable::where('generation_method', 'MANUAL')->findOrFail($id)`
- Validate: if status is not `GENERATED`, return 422 JSON `"Only submitted timetables can be approved."`
- Update: `$timetable->update(['status' => 'PUBLISHED', 'published_at' => now()])`
- Log: `activityLog($timetable, 'Published', ...)`
- Return: JSON success `"Timetable published."`

**3. publish (direct bypass)**
- Gate: `Gate::authorize('standard-timetable.publish')`
- Load timetable by ID with `Timetable::where('generation_method', 'MANUAL')->findOrFail($id)`
- Validate: if status is not `DRAFT` and not `GENERATED`, return 422 JSON `"Timetable cannot be published from current state."`
- Update: `$timetable->update(['status' => 'PUBLISHED', 'published_at' => now()])`
- Log: `activityLog($timetable, 'Published', ...)`
- Return: JSON success `"Timetable published."`

---

## Validate Before Save

No form requests are used. All validation is inline in the controller:

| Scenario | Check | Error Message |
|----------|-------|---------------|
| **submitForApproval: wrong status** | `$timetable->status !== 'DRAFT'` | "Only draft timetables can be submitted." |
| **approve: wrong status** | `$timetable->status !== 'GENERATED'` | "Only submitted timetables can be approved." |
| **publish: wrong status** | `$timetable->status !== 'DRAFT' && $timetable->status !== 'GENERATED'` | "Timetable cannot be published from current state." |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| submitForApproval: timetable not in DRAFT | "Only draft timetables can be submitted." | Controller check (422 JSON) |
| approve: timetable not in GENERATED | "Only submitted timetables can be approved." | Controller check (422 JSON) |
| publish: timetable not in DRAFT or GENERATED | "Timetable cannot be published from current state." | Controller check (422 JSON) |
| Timetable not found / invalid ID | `ModelNotFoundException` → 404 | Framework exception |
| placeCell/removeCell on PUBLISHED | "Published timetables are immutable." | Controller check (422 JSON) |
| lockCell/unlockCell/lockAll on PUBLISHED | "Published timetables are immutable." | Controller check (422 JSON) |

---

## Success Scenarios

**SC-001 — Submit Draft for Approval**
A timetable with status DRAFT and ID 5 is sent to `submitForApproval(5)`. The system sets status to `GENERATED` and logs the submission. Response: `{"success": true, "message": "Timetable submitted for approval."}`.

**SC-002 — Approve a Submitted Timetable**
A timetable with status GENERATED and ID 5 is sent to `approve(5)`. The system sets status to `PUBLISHED` and `published_at` to the current datetime. Response: `{"success": true, "message": "Timetable published."}`.

**SC-003 — Direct Publish from Draft**
A timetable with status DRAFT and ID 5 is sent to `publish(5)`. The system sets status to `PUBLISHED` and `published_at` to now. Response: `{"success": true, "message": "Timetable published."}`.

**SC-004 — Direct Publish from Generated**
A timetable with status GENERATED and ID 5 is sent to `publish(5)`. Same behavior as SC-003. Response: `{"success": true, "message": "Timetable published."}`.

---

## Failure Scenarios

**FC-001 — Submit Non-Draft Timetable**
A timetable with status `PUBLISHED` is passed to `submitForApproval()`. The controller returns 422: `"Only draft timetables can be submitted."`.

**FC-002 — Approve a Draft Timetable**
A timetable with status `DRAFT` is passed to `approve()`. The controller returns 422: `"Only submitted timetables can be approved."`.

**FC-003 — Publish from Invalid State**
A timetable with status `ARCHIVED` is passed to `publish()`. The controller returns 422: `"Timetable cannot be published from current state."`. (`GENERATING` also triggers this.)

**FC-004 — Non-Existent Timetable**
An ID that does not exist in `tt_timetables` is passed. `findOrFail()` throws `ModelNotFoundException`, which results in a 404 response.

**FC-005 — Unauthorized User Without publish Permission**
A user without `standard-timetable.publish` attempts any of the three operations. `Gate::authorize()` throws `AuthorizationException` → 403.

---

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_timetables` | Primary table | Status field drives the workflow; `published_at` set on approval |
| `Modules\TimetableFoundation\Models\Timetable` | Model | FQN of the Timetable model with `SoftDeletes`; table `tt_timetables` |
| `Modules\StandardTimetable\Policies\StandardTimetablePolicy` | Policy | `publish()` gates all three methods |
| `StandardTimetableController` | Controller | All three methods in same controller |
| `activityLog()` | Helper | Logs every status transition |

**Table:** `tt_timetables`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto-increment |
| `code` | VARCHAR(30) | Unique timetable code |
| `name` | VARCHAR(150) | Timetable display name |
| `description` | TEXT | Nullable |
| `academic_session_id` | INT UNSIGNED | Nullable |
| `academic_term_id` | INT UNSIGNED | FK to `sch_academic_term` |
| `timetable_type_id` | INT UNSIGNED | FK to `tt_timetable_type` |
| `period_set_id` | INT UNSIGNED | FK to `tt_period_set` |
| `effective_from` | DATE | Not null |
| `effective_to` | DATE | Nullable |
| `generation_method` | VARCHAR(20) | Default `MANUAL` |
| `version` | INT | Default 1 |
| `parent_timetable_id` | INT UNSIGNED | Nullable, self-referencing FK |
| `status` | ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') | Default `DRAFT` — drives the publishing workflow |
| `published_at` | DATETIME | Nullable, set on approve/publish |
| `published_by` | INT UNSIGNED | Nullable |
| `constraint_violations` | INT | Default 0 |
| `soft_score` | DECIMAL(10,2) | Nullable |
| `stats_json` | JSON | Nullable |
| `generation_strategy_id` | INT UNSIGNED | Nullable |
| `optimization_cycles` | INT | Default 0 |
| `last_optimized_at` | DATETIME | Nullable |
| `quality_score` | DECIMAL(10,2) | Nullable |
| `teacher_satisfaction_score` | DECIMAL(10,2) | Nullable |
| `room_utilization_score` | DECIMAL(10,2) | Nullable |
| `is_active` | BOOLEAN | Default TRUE |
| `created_by` | INT UNSIGNED | Nullable |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |
| `deleted_at` | TIMESTAMP | Nullable (SoftDeletes) |
