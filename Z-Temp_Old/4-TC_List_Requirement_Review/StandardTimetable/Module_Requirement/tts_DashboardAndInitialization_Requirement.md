# Dashboard & Timetable Initialization — Business Requirements

---

## What This Screen Does

The Standard Timetable Dashboard provides administrators with a consolidated overview of all timetables created within the system. It displays key statistics — total timetables, published vs. draft counts, cell placement progress, and counts of supporting entities (activities, class sections, school days, period sets, timetable types, rooms) — in a card-based layout. A "Recent Timetables" table shows the five most recently updated timetables along with their cell coverage, type, term, and status.

From this dashboard, administrators can create a new manual timetable. The creation process validates that a Period Set (the master grid layout of periods) is configured for the chosen Term and Timetable Type before allowing the timetable to exist. Once created, the timetable is stored in `DRAFT` status with `generation_method` set to `MANUAL`, and can be deleted only while it remains in draft state.

---

## When This Screen Is Used

- **At the start of a new academic term** when the school needs to create a timetable for the upcoming term; the admin opens the dashboard, selects the term and timetable type, and initialises a new manual timetable.
- **Mid-term review** when the admin wants to check the status of all timetables — how many are still in draft, how many have been published, and how many cells have been placed across the board.
- **After a timetable has been published** the admin returns to the dashboard to verify the total count update and confirm the published/draft split.
- **When cleaning up obsolete drafts** the admin uses the dashboard to locate draft timetables and deletes those that are no longer needed, ensuring only relevant timetables remain in the system.
- **When navigating to related configuration screens** the admin uses the Quick Navigation cards on the dashboard to jump to Manual Placement, Timetable Foundation, Pre-Requisites Setup, Timetable Masters, Requirements, or Reports & Logs.

---

## Default Data Load

The screen loads via the `StandardTimetableController::index()` method at the route `GET /standard-timetable/` (named `standard-timetable.index`). No tab parameter is used. The controller gates access with `standard-timetable.viewAny`.

The following data is loaded by default:

| Data | Source | Query / Method | Filters | Pagination |
|------|--------|---------------|---------|------------|
| Stat cards | `$stats` array | Eight aggregated counts across `Timetable`, `Activity`, `ClassSection`, `TimetableCell`, `SchoolDay`, `PeriodSet`, `TimetableType`, `Room` | Only `is_active` for Activity, ClassSection, SchoolDay, PeriodSet, TimetableType, Room | None |
| Recent Timetables table | `$recentTimetables` | `Timetable::with(['academicTerm', 'timetableType'])->withCount('cells')->orderByDesc('updated_at')->limit(5)->get()` | None — always last 5 updated | 5 records, no page parameter |
| Timetable coverage | `$timetableCoverage` | Derived from `$recentTimetables` — maps each to an array of name, type, term, cell count, status, updated date | Same as recent timetables | 5 records |
| Summary card | Derived from `$stats` | Published/draft counts + progress bar | — | None |
| Quick Navigation | `$menuPages` | Six hardcoded navigation card definitions with title, icon, route, colour, and description | Route existence check (`Route::has()`) disables links for undefined routes | None |

Empty state: When no timetables exist, the Recent Timetables table area shows a centred placeholder with an inbox icon and the message "No timetables created yet."

---

## Key Fields at a Glance

**Stat Cards**

| Stat | Business Meaning |
|------|-----------------|
| Timetables | Total count of all timetables in the system regardless of status |
| Published | Count of timetables with a non-null `published_at` timestamp |
| Draft | Count of timetables with a null `published_at` timestamp |
| Activities | Active activity records that can be placed into timetable cells |
| Class Sections | Active class-section combinations that appear in the timetable grid |
| Cells Placed | Total number of timetable cells that have been filled across all timetables |
| School Days | Active school-day definitions (e.g., Monday–Friday) |
| Period Sets | Active period-set configurations that define the grid layout |
| TT Types | Active timetable types (e.g., Standard, Half Day, Exam) |
| Rooms | Active room resources available for scheduling |

**Recent Timetables Table**

| Column | Business Meaning |
|--------|-----------------|
| # | Sequential row number within the list |
| Name | The human-readable name assigned to the timetable at creation |
| Type | The timetable type (badge), e.g. "Standard Timetable" |
| Term | The academic term this timetable is generated for, e.g. "Winter Term 2026" |
| Cells | Total number of cells placed in this timetable (coverage indicator) |
| Status | `Published` (green badge) or `Draft` (yellow badge) |
| Updated | Human-readable relative time since last update, e.g. "2 hours ago" |

**Timetable Creation (CreateTimetableRequest)**

| Field | Business Meaning |
|-------|-----------------|
| `name` | A descriptive label for the new timetable, e.g. "Winter Term Standard" |
| `academic_term_id` | The academic term this timetable belongs to, selected from existing terms |
| `timetable_type_id` | The type of timetable being created, selected from existing types |

---

## Business Rules and Conditions

**Period Set Requirement Before Creation**

A new manual timetable cannot be created unless a Period Set is configured for the selected combination of Academic Term and Timetable Type. The system first looks for a `ClassTimetableType` record that matches both `academic_term_id` and `timetable_type_id` and has a non-null `period_set_id`. If no exact match is found, it falls back to a type-only match — any `ClassTimetableType` record with the same `timetable_type_id` and a non-null `period_set_id`. If neither attempt yields a Period Set, creation is blocked with a 422 error.

**Manual Generation Method Only**

All timetables created through this dashboard are hardcoded to `generation_method = 'MANUAL'`. The semi-automatic and full-automatic generation methods (`SEMI_AUTO`, `FULL_AUTO`) are not available through this feature.

**Status Lifecycle — Draft**

Newly created timetables always start in `DRAFT` status. A draft timetable can be edited by placing or removing cells, and it can be deleted. Once a timetable transitions out of `DRAFT` (e.g., to `GENERATED`, `PUBLISHED`, or `ARCHIVED`), deletion is permanently blocked.

**Deletion Scope — Draft and Manual Only**

The delete operation is allowed only when both conditions are met: the timetable's `generation_method` is `'MANUAL'` and its `status` is `'DRAFT'`. If either condition fails, the system returns a 422 error and the timetable is not removed.

**Cascading Delete — Hard Delete on Children**

When a draft manual timetable is deleted, the system performs a hard delete (`forceDelete`) — not a soft delete — on dependent records. It first removes all rows from `tt_timetable_cell_teachers` that reference cells belonging to this timetable, then force-deletes all `TimetableCell` records for this timetable, and finally force-deletes the timetable record itself. The entire operation runs inside a database transaction; if any step fails, all changes are rolled back.

**Activity Logging**

Every state-changing operation (create and delete) is recorded via the `activityLog()` helper with the actor's name, the timetable identity, and a descriptive message.

**Timetable Code Auto-Generation**

When a timetable is created, its `code` field is automatically generated in the format `MT_YYYYMMDD_HHmmss_XXXX` where `XXXX` is a 4-character random string. Example: `MT_20260718_103045_aB3x`.

---

## Workflow Steps

**Creating a New Manual Timetable**

1. The admin navigates to the Standard Timetable Dashboard (`GET /standard-timetable/`).
2. The admin clicks or interacts with a "Create Timetable" button (or a comparable UI trigger) on the dashboard or from the Manual Placement screen.
3. A form is presented asking for three inputs: **Name** (free text, max 200 characters), **Academic Term** (dropdown of existing terms), and **Timetable Type** (dropdown of existing timetable types).
4. The admin fills in the fields, e.g., Name = "Winter Term 2026", Academic Term = "Winter 2026", Timetable Type = "Standard".
5. The admin submits the form. The `CreateTimetableRequest` validates that all three fields are present and that `academic_term_id` and `timetable_type_id` reference existing records.
6. The controller attempts to locate a Period Set for the chosen term and type combination. Suppose a `ClassTimetableType` record exists linking "Winter 2026" + "Standard" to Period Set #3. The system uses Period Set #3.
7. A database transaction begins. The controller creates a new `Timetable` record with auto-generated code (`MT_20260718_103045_aB3x`), the given name, the resolved `period_set_id`, `generation_method = 'MANUAL'`, `status = 'DRAFT'`, `version = 1`, and `created_by` set to the authenticated admin's ID.
8. An activity log entry is created: "Manual timetable created."
9. The transaction commits. The system returns a JSON response with success `true`, the new timetable object, and the message "Timetable 'Winter Term 2026' created."
10. The admin sees the new timetable appear in the Recent Timetables table on the dashboard.

**Deleting a Draft Manual Timetable**

1. The admin identifies a draft timetable to remove, e.g., "Test Timetable" with status `Draft`.
2. The admin triggers the delete action (e.g., a delete button) which sends `DELETE /standard-timetable/delete-timetable/{id}`.
3. The controller gates the action with `standard-timetable.delete`.
4. The system verifies the timetable's `generation_method` is `'MANUAL'` and `status` is `'DRAFT'`. Both checks pass.
5. A database transaction begins:
   - All rows in `tt_timetable_cell_teachers` whose `cell_id` belongs to this timetable are deleted.
   - All `TimetableCell` records with this `timetable_id` are force-deleted.
   - The timetable record itself is force-deleted.
6. An activity log entry is created: "Timetable 'Test Timetable' deleted."
7. The transaction commits. The system returns a JSON response with success `true` and the message "Timetable 'Test Timetable' deleted."
8. The dashboard updates automatically, and the deleted timetable no longer appears in the list.

---

## Example Scenario

Ms. Sharma, the school administrator at Sunshine Academy, is preparing the timetable for the upcoming Winter Term 2026. She navigates to the Standard Timetable Dashboard.

The dashboard shows 3 existing timetables: 2 published (Summer Term 2026, Spring Term 2026) and 1 draft (a leftover test). There are 32 active activities, 48 class sections, and 1,240 total cells placed across all timetables.

Ms. Sharma clicks "Create Timetable" and fills in:
- Name: "Winter Term 2026"
- Academic Term: "Winter 2026"
- Timetable Type: "Standard"

The system checks for a Period Set. A `ClassTimetableType` record exists for "Winter 2026" + "Standard" linked to Period Set #5 (which defines 8 periods per day, Monday–Friday). The Period Set check passes.

The timetable is created as `DRAFT` with code `MT_20260718_110200_kL9m`. The dashboard now shows 4 timetables total, 2 published and 2 draft.

Later, Ms. Sharma realises she accidentally created a duplicate. She locates the duplicate draft and deletes it. The system removes all cells (none yet placed), cell-teacher links, and the timetable record itself. The dashboard updates back to 3 timetables.

---

## Related Screens

- **Manual Placement** — The drag-and-drop grid where timetable cells are placed for a selected timetable; created timetables from the dashboard are opened in this screen for cell placement.
- **Timetable Foundation** — The parent module that manages period sets, timetable types, academic terms, school days, and related master data; Period Sets must be configured here before a timetable can be created.
- **Pre-Requisites Setup** — Configuration of buildings, rooms, classes, and subjects that feed into cell placement.
- **Timetable Masters** — Management of shifts, days, periods, and timetable types.
- **Requirements** — Health checks, activity groups, and timetable requirement definitions.
- **Reports & Logs** — Timetable reports and audit logs including the activity log entries generated during create and delete operations.

---

## Requirements

- The `StandardTimetableController::index()` method loads the dashboard. It gates access with `Gate::authorize('standard-timetable.viewAny')`. It queries eight aggregate counts (`Timetable::count()`, `Activity`/`ClassSection`/`TimetableCell`/`SchoolDay`/`PeriodSet`/`TimetableType`/`Room` scoped to `is_active` where applicable), loads the five most recently updated timetables with their `academicTerm` and `timetableType` relations and cell counts, builds a coverage array, and returns the view `standardtimetable::index`.
- The `StandardTimetableController::createTimetable()` method handles timetable creation. It gates with `Gate::authorize('standard-timetable.manualPlace')`. It validates through `CreateTimetableRequest`, resolves a `period_set_id` via `ClassTimetableType` with a two-tier fallback, and if none is found returns a 422 JSON error. On success, it creates a record inside a `DB::transaction()`, calls `activityLog()`, and returns a JSON response.
- The `StandardTimetableController::deleteTimetable()` method handles deletion. It gates with `Gate::authorize('standard-timetable.delete')`. It constrains the query to `generation_method = 'MANUAL'` and uses `findOrFail($id)`. It checks that `status === 'DRAFT'`, otherwise returns 422. Inside a transaction, it force-deletes `tt_timetable_cell_teachers` rows, then `TimetableCell` rows, then the timetable itself. It logs activity and returns JSON.
- The route `GET /standard-timetable/` named `standard-timetable.index` serves the dashboard.
- The route `POST /standard-timetable/create-timetable` named `standard-timetable.createTimetable` handles timetable creation.
- The route `DELETE /standard-timetable/delete-timetable/{id}` named `standard-timetable.deleteTimetable` handles timetable deletion.
- Validation is handled by `CreateTimetableRequest` with rules: `name` is `required|string|max:200`, `academic_term_id` is `required|exists:sch_academic_term,id`, `timetable_type_id` is `required|exists:tt_timetable_types,id`. The request also authorises via `can('standard-timetable.manualPlace')` in its `authorize()` method.
- Controller-level business validation (period set existence) happens outside the form request — the controller queries `ClassTimetableType` and returns a 422 JSON error if no Period Set is found.
- The `Timetable` model uses the `SoftDeletes` trait (column `deleted_at` exists in the DDL at `tt_timetables.deleted_at`).
- Delete operations use `forceDelete()` — they permanently remove the record and bypass the soft-delete mechanism.
- Timetable `code` is auto-generated as `'MT_' . now()->format('Ymd_His') . '_' . Str::random(4)` before creation.
- `generation_method` is hardcoded to `'MANUAL'`; `status` is hardcoded to `'DRAFT'`; `version` to `1`; `academic_session_id` to `null`; `effective_from` to `now()`. These values are passed directly in the controller, not from user input.
- Activity logging is performed via `activityLog()` helper on both create and delete operations with the message and `performed_by` data.
- The policy `StandardTimetablePolicy` defines eight methods: `viewAny`, `manualPlace`, `publish`, `lock`, `viewClass`, `viewTeacher`, `viewRoom`, `delete`. Each checks the corresponding `standard-timetable.*` permission.
- The `academic_term_id` column in `tt_timetables` has no explicit foreign key constraint in the DDL (line 1240 declares the column with a comment noting it as FK to `sch_academic_term.id`, but no `CONSTRAINT fk_* FOREIGN KEY` is defined for it among lines 1272–1278).

---

## Who Can Access

| Gate / Permission | Methods | Notes |
|-------------------|---------|-------|
| `standard-timetable.viewAny` | `index()` | Dashboard access — any user with this permission can view stats, recent timetables, and navigation cards |
| `standard-timetable.manualPlace` | `createTimetable()`, also checked in `CreateTimetableRequest::authorize()` | Creation of manual timetables |
| `standard-timetable.delete` | `deleteTimetable()` | Deletion of draft manual timetables |
| `StandardTimetablePolicy` | All above methods | Policy class that delegates each method to the corresponding `standard-timetable.*` permission via `$user->can()` |

---

## Logic Flow

**Page Load (index)**

1. User sends `GET /standard-timetable/`.
2. `Gate::authorize('standard-timetable.viewAny')` runs — if the user lacks the permission, a 403 response is returned.
3. Controller queries all counts:
   - `Timetable::count()` → total timetables.
   - `Timetable::whereNotNull('published_at')->count()` → published count.
   - `Timetable::whereNull('published_at')->count()` → draft count.
   - `Activity::where('is_active', true)->count()` → active activities.
   - `ClassSection::where('is_active', true)->count()` → active class sections.
   - `TimetableCell::count()` → total cells across all timetables.
   - `SchoolDay::where('is_active', true)->count()` → active school days.
   - `PeriodSet::where('is_active', true)->count()` → active period sets.
   - `TimetableType::where('is_active', true)->count()` → active timetable types.
   - `Room::where('is_active', true)->count()` → active rooms.
4. Controller fetches recent timetables: `Timetable::with(['academicTerm', 'timetableType'])->withCount('cells')->orderByDesc('updated_at')->limit(5)->get()`.
5. Controller loops through recent timetables to build the `$timetableCoverage` array — each entry contains `name`, `type` (from relation), `term` (from relation), `cells` (from `cells_count`), `status` (`Published` if `published_at` is not null, else `Draft`), `updated` (via `diffForHumans()`).
6. Controller defines the six-element `$menuPages` navigation array.
7. View `standardtimetable::index` renders:
   - Row 1: Eight stat cards in a responsive grid.
   - Row 2: Recent Timetables table (left column, 8 cols) + Quick Action / Summary card (right column, 4 cols).
   - Row 3: Quick Navigation cards (six cards in responsive grid).

**Create Timetable**

1. User sends `POST /standard-timetable/create-timetable` with JSON body: `{ "name": "...", "academic_term_id": N, "timetable_type_id": N }`.
2. `CreateTimetableRequest::authorize()` checks `can('standard-timetable.manualPlace')` — 403 if absent.
3. `CreateTimetableRequest::rules()` validates:
   - `name`: required, string, max 200 chars.
   - `academic_term_id`: required, must exist in `sch_academic_term.id`.
   - `timetable_type_id`: required, must exist in `tt_timetable_types.id`.
4. Validation failure returns a 422 JSON response with field-level error messages.
5. Controller enters `try` block:
   - First attempt: `ClassTimetableType::where('academic_term_id', ...)->where('timetable_type_id', ...)->whereNotNull('period_set_id')->value('period_set_id')`.
   - Fallback (if first returns null): `ClassTimetableType::where('timetable_type_id', ...)->whereNotNull('period_set_id')->value('period_set_id')`.
   - If both return null → return 422 JSON: `"No Period Set is configured for the selected Timetable Type. Please set it up in Timetable Foundation → Class Timetable Types."`
6. `DB::beginTransaction()`.
7. `Timetable::create([...])` with auto-generated `code`, provided `name/academic_term_id/timetable_type_id`, resolved `period_set_id`, `academic_session_id => null`, `effective_from => now()`, `generation_method => 'MANUAL'`, `status => 'DRAFT'`, `version => 1`, `created_by => auth()->id()`.
8. `activityLog($timetable, 'Created', ['message' => 'Manual timetable created.', 'performed_by' => auth()->user()?->name])`.
9. `DB::commit()`.
10. Return JSON: `{ "success": true, "timetable": { ... }, "message": "Timetable '...' created." }`
11. On exception: `DB::rollBack()`, return 500 JSON: `{ "success": false, "message": "Failed to create timetable: ..." }`.

**Delete Timetable**

1. User sends `DELETE /standard-timetable/delete-timetable/{id}`.
2. `Gate::authorize('standard-timetable.delete')` — 403 if absent.
3. `Timetable::where('generation_method', 'MANUAL')->findOrFail($id)` — if not found or not manual, 404.
4. Check `$timetable->status !== 'DRAFT'` → if true, return 422 JSON: `"Only draft timetables can be deleted."`
5. `DB::beginTransaction()`.
6. `DB::table('tt_timetable_cell_teachers')->whereIn('cell_id', TimetableCell::where('timetable_id', $id)->pluck('id'))->delete()` — delete all cell-teacher links.
7. `TimetableCell::where('timetable_id', $id)->forceDelete()` — permanently delete all cells.
8. `$timetable->forceDelete()` — permanently delete the timetable record (bypasses SoftDeletes).
9. `activityLog(...)` with message `"Timetable '...' deleted."`.
10. `DB::commit()`.
11. Return JSON: `{ "success": true, "message": "Timetable '...' deleted." }`
12. On exception: `DB::rollBack()`, return 500 JSON: `{ "success": false, "message": "Delete failed: ..." }`.

---

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `name` | `required\|string\|max:200` | "validation.required" / "validation.max.string" (Laravel default) |
| `academic_term_id` | `required\|exists:sch_academic_term,id` | "validation.required" / "validation.exists" (Laravel default) |
| `timetable_type_id` | `required\|exists:tt_timetable_types,id` | "validation.required" / "validation.exists" (Laravel default) |
| **Parent level (controller)** | Period Set existence check via `ClassTimetableType` | "No Period Set is configured for the selected Timetable Type. Please set it up in Timetable Foundation → Class Timetable Types." (422) |
| **Parent level (controller)** | Delete guard — status must be `DRAFT` | "Only draft timetables can be deleted." (422) |
| **Parent level (controller)** | Delete guard — `generation_method` must be `MANUAL` | Implicit — query scopes to `generation_method = 'MANUAL'`; non-manual timetables produce a 404 (`findOrFail`). |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing `name` field | "validation.required" | Validation rule (422) |
| `name` exceeds 200 characters | "validation.max.string" | Validation rule (422) |
| Missing or invalid `academic_term_id` (not existing in DB) | "validation.required" / "validation.exists" | Validation rule (422) |
| Missing or invalid `timetable_type_id` (not existing in DB) | "validation.required" / "validation.exists" | Validation rule (422) |
| No Period Set configured for the selected term and type | "No Period Set is configured for the selected Timetable Type. Please set it up in Timetable Foundation → Class Timetable Types." | Controller check (422 JSON) |
| User lacks `standard-timetable.manualPlace` permission | 403 Forbidden | Gate / Request authorization |
| User lacks `standard-timetable.delete` permission | 403 Forbidden | Gate authorization |
| Attempt to delete a non-DRAFT timetable | "Only draft timetables can be deleted." | Controller check (422 JSON) |
| Attempt to delete a non-MANUAL timetable (e.g., generated timetable) | 404 Not Found | `findOrFail` scoped to `generation_method = 'MANUAL'` |
| Timetable ID not found | 404 Not Found | `findOrFail` |
| Database exception during create | "Failed to create timetable: {exception message}" | Controller catch (500 JSON) |
| Database exception during delete | "Delete failed: {exception message}" | Controller catch (500 JSON) |

---

## Success Scenarios

**SC-001 — Creating a New Manual Timetable Successfully**

The admin creates a timetable named "Winter Term 2026" for Academic Term ID 5 ("Winter 2026") and Timetable Type ID 1 ("Standard"). A `ClassTimetableType` record exists linking term ID 5 + type ID 1 to Period Set ID 3. The system resolves Period Set ID 3, creates the timetable with code `MT_20260718_110200_kL9m`, generation method `MANUAL`, status `DRAFT`, version 1. The system commits the transaction, logs "Manual timetable created." in the activity log, and returns JSON `{ "success": true, "timetable": { ... }, "message": "Timetable 'Winter Term 2026' created." }`.

**SC-002 — Deleting a Draft Manual Timetable Successfully**

The admin deletes timetable ID 7 which has `generation_method = 'MANUAL'` and `status = 'DRAFT'`. The system deletes 0 cell-teacher links (no cells placed yet), 0 cells, and the timetable record itself. It logs "Timetable 'Test Timetable' deleted." and returns JSON `{ "success": true, "message": "Timetable 'Test Timetable' deleted." }`.

**SC-003 — Deleting a Draft Manual Timetable with Cells**

The admin deletes timetable ID 10 which has 40 cells placed. The system deletes all cell-teacher links for those 40 cells, force-deletes the 40 cells, force-deletes the timetable, logs the activity, and returns the success JSON. The dashboard's total cell count decreases by 40.

---

## Failure Scenarios

**FC-001 — Creation Blocked: No Period Set Configured**

The admin selects Academic Term ID 5 and Timetable Type ID 2 ("Half Day"). No `ClassTimetableType` record exists with `academic_term_id = 5` and `timetable_type_id = 2` with a non-null `period_set_id`. The fallback type-only match also returns null. The system returns 422 JSON: `{ "success": false, "message": "No Period Set is configured for the selected Timetable Type. Please set it up in Timetable Foundation → Class Timetable Types." }`. No timetable is created.

**FC-002 — Deletion Blocked: Timetable Is Published**

The admin attempts to delete timetable ID 3, whose `status` is `'PUBLISHED'`. The controller check `$timetable->status !== 'DRAFT'` fails. The system returns 422 JSON: `{ "success": false, "message": "Only draft timetables can be deleted." }`. No records are removed.

**FC-003 — Deletion Blocked: Timetable Is Not Manual**

The admin sends a delete request for timetable ID 15, which has `generation_method = 'FULL_AUTO'`. The query `Timetable::where('generation_method', 'MANUAL')->findOrFail($id)` returns 404 because the scope excludes non-manual timetables, even though ID 15 exists.

**FC-004 — Creation Fails: Database Error**

The admin submits a valid creation request, but a database error occurs (e.g., deadlock, connection lost). The `catch` block rolls back the transaction and returns 500 JSON: `{ "success": false, "message": "Failed to create timetable: {exception message}" }`.

---

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `TimetableFoundation` | Module dependency | Provides `Timetable`, `TimetableCell`, `TimetableType`, `PeriodSet`, `AcademicTerm`, `ClassTimetableType`, `SchoolDay` models and their underlying tables. This module is required — without it no timetables can be created or managed. |
| `SchoolSetup` | Module dependency | Provides `ClassSection`, `Room`, `User` models. `ClassSection` is used for the stat count; `Room` for the stat count; `User` for `created_by` reference. |
| `SmartTimetable` | Module dependency | Provides `ConflictDetection`, `GenerationRun`, `TtGenerationStrategy` models. Referenced by the DDL but not directly called by dashboard or initialization endpoints. |
| `sch_academic_term` | FK parent (no explicit constraint in DDL) | `tt_timetables.academic_term_id` references `sch_academic_term.id`. The DDL declares the column (line 1240) with an FK comment but **no explicit `CONSTRAINT fk_*`** is defined in the DDL (verified at lines 1272–1278). |
| `sch_org_academic_sessions_jnt` | FK parent (RESTRICT) | `tt_timetables.academic_session_id` → `sch_org_academic_sessions_jnt.id`, `ON DELETE RESTRICT`. |
| `tt_timetable_types` | FK parent (RESTRICT) | `tt_timetables.timetable_type_id` → `tt_timetable_types.id`, `ON DELETE RESTRICT`. |
| `tt_period_sets` | FK parent (RESTRICT) | `tt_timetables.period_set_id` → `tt_period_sets.id`, `ON DELETE RESTRICT`. |
| `tt_timetables` (self) | Self-referencing FK (SET NULL) | `tt_timetables.parent_timetable_id` → `tt_timetables.id`, `ON DELETE SET NULL`. |
| `sys_users` | FK parent (SET NULL) | `tt_timetables.published_by` and `tt_timetables.created_by` → `sys_users.id`, `ON DELETE SET NULL`. |
| `tt_generation_strategies` | FK parent (SET NULL) | `tt_timetables.generation_strategy_id` → `tt_generation_strategies(id)`, `ON DELETE SET NULL`. |
| `tt_timetable_cells` | Child table (CASCADE) | `tt_timetable_cells.timetable_id` → `tt_timetables.id`, `ON DELETE CASCADE`. |
| `tt_timetable_cell_teachers` | Child table (no direct FK to tt_timetables) | Referenced via `tt_timetable_cells.id`; deleted manually in controller before cell deletion. |
| `tt_conflict_detections` | Child table (no ON DELETE) | `tt_conflict_detections.timetable_id` → `tt_timetables.id`. DDL shows no `ON DELETE` action (line 1299). |
| `tt_generation_runs` | Child table (CASCADE) | `tt_generation_runs.timetable_id` → `tt_timetables.id`, `ON DELETE CASCADE`. |
| `tt_constraint_violations` | Child table (CASCADE) | `tt_constraint_violations.timetable_id` → `tt_timetables.id`, `ON DELETE CASCADE`. |
| `tt_teacher_workloads` | Child table (SET NULL) | `tt_teacher_workloads.timetable_id` → `tt_timetables.id`, `ON DELETE SET NULL`. |
| `tt_change_logs` | Child table (CASCADE) | `tt_change_logs.timetable_id` → `tt_timetables.id`, `ON DELETE CASCADE`. |
| Activity Log | Cross-cutting service | `activityLog()` helper called on both create and delete for audit trail. |

**Table:** `tt_timetables`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE (`uq_tt_code`). Auto-generated as `MT_YYYYMMDD_HHmmss_XXXX` |
| `name` | VARCHAR(200) | NOT NULL |
| `description` | TEXT | DEFAULT NULL |
| `academic_session_id` | SMALLINT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| `academic_term_id` | INT UNSIGNED | NOT NULL, documented FK → `sch_academic_term.id` but **no explicit constraint** in DDL |
| `timetable_type_id` | INT UNSIGNED | NOT NULL, FK → `tt_timetable_types.id` (RESTRICT) |
| `period_set_id` | INT UNSIGNED | NOT NULL, FK → `tt_period_sets.id` (RESTRICT) |
| `effective_from` | DATE | NOT NULL. Start date of this timetable |
| `effective_to` | DATE | DEFAULT NULL. End date of this timetable |
| `generation_method` | ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') | NOT NULL, DEFAULT 'MANUAL'. For this module always 'MANUAL' |
| `version` | SMALLINT UNSIGNED | NOT NULL, DEFAULT 1 |
| `parent_timetable_id` | INT UNSIGNED | DEFAULT NULL, FK → `tt_timetables.id` (SET NULL, self-referencing) |
| `status` | ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') | NOT NULL, DEFAULT 'DRAFT' |
| `published_at` | TIMESTAMP | NULL |
| `published_by` | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id` (SET NULL) |
| `constraint_violations` | INT UNSIGNED | DEFAULT 0 |
| `soft_score` | DECIMAL(8,2) | DEFAULT NULL |
| `stats_json` | JSON | DEFAULT NULL |
| `generation_strategy_id` | INT UNSIGNED | DEFAULT NULL, FK → `tt_generation_strategies.id` (SET NULL) |
| `optimization_cycles` | INT UNSIGNED | DEFAULT 0 |
| `last_optimized_at` | TIMESTAMP | NULL |
| `quality_score` | DECIMAL(5,2) | DEFAULT NULL. Quality score (0–100) |
| `teacher_satisfaction_score` | DECIMAL(5,2) | DEFAULT NULL |
| `room_utilization_score` | DECIMAL(5,2) | DEFAULT NULL |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_by` | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id` (SET NULL) |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULL, DEFAULT NULL |
