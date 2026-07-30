# Copy Timetable & Cell Lock/Unlock — Business Requirements

## What This Screen Does

The Copy Timetable operation allows users to duplicate an existing manual timetable — including all its cells and teacher assignments — as a new draft. This is primarily used to create a template for a new academic term or to fork a timetable for a parallel class section without rebuilding from scratch.

The Cell Lock/Unlock feature enables timetable coordinators to mark individual cells (or all cells at once) as locked, preventing accidental removal during the editing phase. Locked cells display a warning badge in the grid and are protected against the `removeCell` operation. This provides a safety net while the timetable is still in DRAFT or GENERATED status.

---

## When This Screen Is Used

- **Term Rollover** when a school ends Term 1 and wants to reuse the same timetable structure for Term 2, copying the existing timetable and updating the academic term reference
- **Parallel Section Duplication** when Class 10-A and Class 10-B share the same schedule, the coordinator builds the timetable for one section and copies it for the other
- **Locking a Completed Cell** when a coordinator finishes placing a specific activity in a slot and wants to prevent accidental removal while continuing to fill adjacent cells
- **Bulk Lock Before Review** when the coordinator has finished the entire grid and locks all cells before handing the timetable off for approval
- **Unlocking a Cell for Correction** when the coordinator realizes a locked cell contains the wrong activity and needs to free it for replacement

---

## Default Data Load

These are action endpoints (POST routes), not data-loading screens. They are triggered via action buttons on the Manual Placement page under the Manual Placement tab group. The copy operation loads the source timetable by ID, queries all its cells and cell-teacher pivot records, and creates duplicates. The lock/unlock operations load a single cell by `cellId` or all cells by `timetableId`. No grids or dropdowns are loaded — the resulting JSON response includes the newly created timetable (for copy) or a success message (for lock/unlock).

---

## Key Fields at a Glance

**Identity and Tracking**
The copied timetable receives a new auto-generated `code` using the pattern `CP_YYYYMMDD_HHMMSS_XXXX` (where XXXX is a 4-character random string) to distinguish it as a copy. The `name` is set to the source timetable's name appended with ` (Copy)`, so the copy is immediately identifiable in the timetable list.

**Copy Behavior**
All cells from the source timetable are replicated into the new timetable. The `replicate()->toArray()` approach copies every column except the auto-increment `id` and `timetable_id`. Notably, `has_conflict` and `conflict_details_json` are **not** excluded from replication — the service calls `$cell->replicate()->toArray()` which includes all fillable attributes, so the copy will carry over any conflict flags from the source.

**Cell Protection State**
Each cell carries an `is_locked` boolean (default `false`). When locked, the cell displays a warning badge in the view and is protected from the `removeCell` operation which checks `if ($cell->is_locked)` and returns 422 with "Cell is locked." Lock state is independent of timetable status — only the PUBLISHED check on the timetable itself overrides.

---

## Business Rules and Conditions

**Copy Integrity Rules**
The copy operation runs inside `DB::transaction()`. If any insert fails (e.g., duplicate key, FK violation), the entire copy is rolled back and an exception is thrown. The service accepts an optional `$overrides` array — if provided, these override the cloned attributes (e.g., `academic_term_id` can be changed during the copy). The new timetable always gets `status = 'DRAFT'`, `version = 1`, `generation_method = 'MANUAL'`, `created_by = auth()->id()`, and `effective_from = now()`.

**Source Timestamp Preservation**
The `created_at` and `updated_at` timestamps in the pivot table (`tt_timetable_cell_teachers`) are reset to `now()` for the newly inserted rows — they are not carried over from the source.

**Lock Rules**
`lockCell()` and `unlockCell()` act on a single cell identified by `cellId`. `lockAll()` acts on the entire timetable — it updates `is_locked = true` on every cell belonging to the timetable. All three methods verify the parent timetable is not PUBLISHED before applying the change; if PUBLISHED, they return 422 with "Published timetables are immutable."

**Remove Protection**
The `removeCell()` controller method checks `$cell->is_locked` before deleting a cell. If locked, it returns 422 with "Cell is locked." This enforcement applies regardless of the timetable's status (except PUBLISHED, which is checked earlier).

**Published Timetable Lockdown**
Even though `lockCell`/`unlockCell`/`lockAll` check the PUBLISHED status explicitly, a published timetable is already fully protected by the immutability check at the top of each method — no further locking changes are possible on a published schedule.

**Activity Logging**
Every copy, lock, unlock, and lock-all operation logs to the activity trail with the action name (`Copied`, `Locked`, `Unlocked`, `LockAll`) and the performing user.

---

## Workflow Steps

**Copying a Timetable**
1. The coordinator selects a timetable from the list and clicks "Copy."
2. The system loads the source timetable with `findOrFail($id)`, filtering for `generation_method = 'MANUAL'`.
3. `ManualTimetableService::copyTimetable()` creates a new `Timetable` record with the copied attributes, a `CP_...` code, and ` (Copy)` appended to the name.
4. The service loops through every cell of the source and creates a new cell via `$newTimetable->cells()->create($cell->replicate()->toArray())`.
5. For each new cell, the service copies all `tt_timetable_cell_teachers` pivot records.
6. The entire operation is wrapped in a database transaction.
7. An activity log entry records the copy event.
8. The response returns the newly created timetable object.

**Locking a Cell**
1. The coordinator clicks the lock icon on a specific cell in the grid.
2. The system loads the cell by `$cellId`, verifies the parent timetable is not PUBLISHED, sets `is_locked = true`, logs the activity, and returns success.

**Unlocking a Cell**
1. The coordinator clicks the unlock icon on a locked cell.
2. The system loads the cell, checks the parent timetable is not PUBLISHED, sets `is_locked = false`, logs the activity, and returns success.

**Locking All Cells**
1. The coordinator clicks "Lock All" on the timetable action bar.
2. The system loads the timetable by `$timetableId`, checks it is not PUBLISHED, performs `TimetableCell::where('timetable_id', $timetableId)->update(['is_locked' => true])`, logs a single `LockAll` activity entry, and returns success.

---

## Example Scenario

Mr. Verma has built the "Class 10 Science Standard" timetable for Term 1 at Springfields School. He needs the same structure for Term 2 with a different academic term. He clicks "Copy," and the system creates "Class 10 Science Standard (Copy)" with code `CP_20260718_103000_aBcD` in DRAFT status. He then opens the new timetable and adjusts a few cells. To prevent accidental removal of the core Science lecture cells, he clicks the lock icon on each of Periods 1-3 on Monday, Tuesday, and Wednesday. Each cell shows a "Locked" badge. He then locks all remaining cells by clicking "Lock All." The grid is now fully protected. When a junior coordinator tries to remove a cell to add an extracurricular activity, the system rejects it: "Cell is locked."

---

## Related Screens

- **Manual Placement** — The primary grid where cells are placed, removed, locked, and unlocked
- **Publishing & Approval Workflow** — The next step after locking; submitting the timetable for approval to make it final
- **Timetable Views (Class/Teacher/Room)** — Read-only displays that show locked cells with a warning badge
- **Timetable Dashboard** — The index page showing all timetables with their status, where the copy action is triggered from the timetable row

---

## Requirements

- Controller `StandardTimetableController`:
  - `copyTimetable(int $id)` lines 576-595: loads source, delegates to `ManualTimetableService::copyTimetable()`, logs activity `Copied`, gated by `standard-timetable.manualPlace`
  - `lockCell(int $cellId)` lines 597-616: loads cell, checks parent timetable not PUBLISHED, sets `is_locked = true`, logs `Locked`, gated by `standard-timetable.lock`
  - `unlockCell(int $cellId)` lines 618-637: loads cell, checks parent timetable not PUBLISHED, sets `is_locked = false`, logs `Unlocked`, gated by `standard-timetable.lock`
  - `lockAll(int $timetableId)` lines 639-656: loads timetable, checks not PUBLISHED, bulk updates all cells to `is_locked = true`, logs `LockAll`, gated by `standard-timetable.lock`
- Service `ManualTimetableService::copyTimetable(Timetable $source, array $overrides = [])` lines 78-116:
  - Creates new timetable with `code = 'CP_' . now()->format('Ymd_His') . '_' . Str::random(4)`, `name = $source->name . ' (Copy)'`, `status = 'DRAFT'`, `version = 1`, `generation_method = 'MANUAL'`, `created_by = auth()->id()`, `effective_from = now()`
  - Copies all cells via `$cell->replicate()->toArray()` — carries over `has_conflict` and `conflict_details_json` from source
  - Copies all `tt_timetable_cell_teachers` pivot records with new timestamps
  - Wrapped in `DB::transaction()` — full rollback on failure
  - Accepts `$overrides` array to replace any default attribute (e.g., `academic_term_id`)
- Routes (web.php): `POST copy-timetable/{id}` (name: `copyTimetable`), `POST lock-cell/{cellId}` (name: `lockCell`), `POST unlock-cell/{cellId}` (name: `unlockCell`), `POST lock-all/{timetableId}` (name: `lockAll`)
- Activity logged on all four operations with distinct action names
- `removeCell()` checks `$cell->is_locked` and returns 422 "Cell is locked." if true
- Published timetable check returns 422 "Published timetables are immutable." in `lockCell`, `unlockCell`, `lockAll`

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `standard-timetable.manualPlace` | `copyTimetable()` | Same permission as cell placement; typically assigned to timetable coordinators |
| `standard-timetable.lock` | `lockCell()`, `unlockCell()`, `lockAll()` | Single permission gates all three lock/unlock operations |
| Policy | `StandardTimetablePolicy::manualPlace()` | For copy — delegates to `$user->can('standard-timetable.manualPlace')` |
| Policy | `StandardTimetablePolicy::lock()` | For lock/unlock — delegates to `$user->can('standard-timetable.lock')` |

---

## Logic Flow

**1. copyTimetable (controller)**
- Gate: `Gate::authorize('standard-timetable.manualPlace')`
- Load source: `Timetable::where('generation_method', 'MANUAL')->findOrFail($id)`
- Delegate: `$service->copyTimetable($source)` — wrapped in try-catch
- Log: `activityLog($copy, 'Copied', ...)`
- Return: JSON `{"success": true, "timetable": $copy}`
- On exception: return 500 JSON `"Copy failed: <message>"`

**2. copyTimetable (service — ManualTimetableService)**
- `DB::transaction()`:
  - Create new `Timetable` record with defaults + `$overrides` merged
  - For each source cell: `$newTimetable->cells()->create($cell->replicate()->toArray())`
  - For each source cell_teacher: insert into `tt_timetable_cell_teachers` with new cell_id
- Return the new Timetable model

**3. lockCell**
- Gate: `Gate::authorize('standard-timetable.lock')`
- Load cell: `TimetableCell::findOrFail($cellId)`
- Check: `$cell->timetable->status === 'PUBLISHED'` → 422
- Update: `$cell->update(['is_locked' => true])`
- Log: `activityLog($cell, 'Locked', ...)`
- Return: JSON `{"success": true, "message": "Cell locked."}`

**4. unlockCell**
- Gate: `Gate::authorize('standard-timetable.lock')`
- Load cell: `TimetableCell::findOrFail($cellId)`
- Check: `$cell->timetable->status === 'PUBLISHED'` → 422
- Update: `$cell->update(['is_locked' => false])`
- Log: `activityLog($cell, 'Unlocked', ...)`
- Return: JSON `{"success": true, "message": "Cell unlocked."}`

**5. lockAll**
- Gate: `Gate::authorize('standard-timetable.lock')`
- Load timetable: `Timetable::findOrFail($timetableId)`
- Check: `$timetable->status === 'PUBLISHED'` → 422
- Bulk update: `TimetableCell::where('timetable_id', $timetableId)->update(['is_locked' => true])`
- Log: `activityLog($timetable, 'LockAll', ...)`
- Return: JSON `{"success": true, "message": "All cells locked."}`

---

## Validate Before Save

No form requests are used. All checks are inline in the controller or service.

| Operation | Check | Error Message |
|-----------|-------|---------------|
| **copyTimetable** | `Timetable::findOrFail($id)` with generation_method='MANUAL' | 404 if not found |
| **lockCell/unlockCell** | `TimetableCell::findOrFail($cellId)` | 404 if not found |
| **lockCell/unlockCell/lockAll** | Parent timetable status === 'PUBLISHED' | "Published timetables are immutable." (422 JSON) |
| **removeCell** (cross-reference) | `$cell->is_locked` | "Cell is locked." (422 JSON) |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Copy: timetable not found (invalid ID) | ModelNotFoundException | 404 |
| Copy: database failure during transaction | "Copy failed: <exception message>" | 500 JSON |
| Lock: cell not found | ModelNotFoundException | 404 |
| Lock/unlock/lockAll: timetable is PUBLISHED | "Published timetables are immutable." | Controller check (422 JSON) |
| Lock/unlock: parent timetable is PUBLISHED (via cell->timetable) | "Published timetables are immutable." | Controller check (422 JSON) |
| Remove cell: cell is locked | "Cell is locked." | Controller check (422 JSON) |
| Unauthorized: missing manualPlace permission | AuthorizationException | 403 |
| Unauthorized: missing lock permission | AuthorizationException | 403 |

---

## Success Scenarios

**SC-001 — Copy Timetable Successfully**
Source timetable ID 3 ("Class 10 Standard") is copied. The system creates "Class 10 Standard (Copy)" with code `CP_20260718_103000_xYz9`, status DRAFT, all 48 cells replicated, all teacher assignments carried over. Response: `{"success": true, "timetable": {...}}`.

**SC-002 — Lock a Single Cell**
Cell ID 127 (day 2, period 4) on an active draft timetable is locked. Response: `{"success": true, "message": "Cell locked."}`. The cell's `is_locked` column is now `true` and it displays a "Locked" badge in the view.

**SC-003 — Unlock a Single Cell**
Cell ID 127 is unlocked. Response: `{"success": true, "message": "Cell unlocked."}`. The cell's `is_locked` column is now `false`.

**SC-004 — Lock All Cells in a Timetable**
Timetable ID 3 has 48 cells. `lockAll(3)` updates all 48 rows to `is_locked = true`. A single `LockAll` activity log entry is created. Response: `{"success": true, "message": "All cells locked."}`.

---

## Failure Scenarios

**FC-001 — Copy Non-Manual Timetable**
The source timetable has `generation_method = 'AUTO'` (not MANUAL). `findOrFail` with the `where('generation_method', 'MANUAL')` filter returns nothing → 404.

**FC-002 — Lock Cell on Published Timetable**
The cell's parent timetable is PUBLISHED. `lockCell()` returns 422: `"Published timetables are immutable."`.

**FC-003 — Unlock Cell on Published Timetable**
Same as FC-002, returns 422: `"Published timetables are immutable."`.

**FC-004 — Lock All on Published Timetable**
`lockAll()` returns 422: `"Published timetables are immutable."`.

**FC-005 — Remove a Locked Cell**
`removeCell()` is called on a cell where `is_locked = true`. The controller returns 422: `"Cell is locked."`. The cell remains in place.

**FC-006 — Unauthorized Copy Attempt**
User without `standard-timetable.manualPlace` attempts copy. `Gate::authorize()` throws 403.

**FC-007 — Unauthorized Lock Attempt**
User without `standard-timetable.lock` attempts lock/unlock/lockAll. 403 forbidden.

---

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_timetables` | Primary table | Source and destination timetable records |
| `tt_timetable_cells` | Child table | Cells replicated during copy; `is_locked` column used by lock/unlock |
| `tt_timetable_cell_teachers` | Pivot table | Teacher assignments replicated during copy |
| `Modules\TimetableFoundation\Models\Timetable` | Model | FQN, table `tt_timetables`, `SoftDeletes` |
| `Modules\TimetableFoundation\Models\TimetableCell` | Model | FQN, table `tt_timetable_cells`, `SoftDeletes`; `is_locked` boolean cast |
| `Modules\StandardTimetable\Services\ManualTimetableService` | Service | `copyTimetable()` method handles full duplication logic |
| `Modules\StandardTimetable\Policies\StandardTimetablePolicy` | Policy | `manualPlace()` gates copy; `lock()` gates lock/unlock/lockAll |
| `activityLog()` | Helper | Logs all four operations |

**Table:** `tt_timetable_cells`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto-increment |
| `timetable_id` | INT UNSIGNED | FK to `tt_timetables.id`, not null |
| `generation_run_id` | INT UNSIGNED | Nullable |
| `day_of_week` | INT UNSIGNED | Not null |
| `period_ord` | INT UNSIGNED | Not null |
| `cell_date` | DATE | Nullable |
| `class_group_id` | INT UNSIGNED | Not null |
| `class_subgroup_id` | INT UNSIGNED | Nullable |
| `activity_id` | INT UNSIGNED | Not null |
| `sub_activity_id` | INT UNSIGNED | Nullable |
| `room_id` | INT UNSIGNED | Nullable, FK to `sch_rooms` |
| `source` | VARCHAR(20) | Default 'MANUAL' |
| `is_locked` | BOOLEAN | Default FALSE — target of lock/unlock/lockAll operations |
| `locked_by` | INT UNSIGNED | Nullable |
| `locked_at` | DATETIME | Nullable |
| `has_conflict` | BOOLEAN | Default FALSE — carried over during copy via replicate() |
| `conflict_details_json` | JSON | Nullable — carried over during copy via replicate() |
| `is_active` | BOOLEAN | Default TRUE |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |
| `deleted_at` | TIMESTAMP | Nullable (SoftDeletes) |

**Table:** `tt_timetable_cell_teachers`

| Column | Type | Details |
|--------|------|---------|
| `cell_id` | INT UNSIGNED | FK to `tt_timetable_cells.id` |
| `teacher_id` | INT UNSIGNED | FK to teacher record |
| `assignment_role_id` | INT UNSIGNED | FK to `tt_teacher_assignment_role` |
| `is_substitute` | BOOLEAN | Default FALSE |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |
