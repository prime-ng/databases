# Timetable Types & Class Assignments — Business Requirements

## What This Screen Does

Timetable Types are the classification layer that determines what kind of schedule a class-section follows on a given day. A Timetable Type defines the scheduling context — for example, "Standard Academic", "Half Day", "Unit Test Timetable", "Half Yearly Exam", or "Final Exam". Each type carries its own time boundaries (school start/end time), flags for teaching and exam modes, an ordinal for display ordering, a default flag, and an optional association with a school shift (Morning, Afternoon, Evening).

The Class Timetable Assignments (junction table `tt_class_timetable_types_jnt`) links a specific Timetable Type to a specific class (and optionally a section) for a specific academic term. This determines which period set the class-section uses, whether teaching and/or exam periods are active, the weekly period counts by category (teaching, exam, free), and the effective date range for the assignment.

Both entities are managed on the **Timetable Masters page** (Page 3 of the Timetable Foundation workflow), under two separate tabs:
- **Timetable Types** tab (`tab=timetable-types`) — Full CRUD for TimetableType records, with the ability to inline-create class timetable assignments during creation/editing.
- **Class Timetable** tab (`tab=class-timetable`) — Dedicated bulk CRUD for ClassTimetableType records, allowing multi-class and multi-section assignment in a single form submission.

The system enforces mutual exclusion between `applies_to_all_sections` and a non-null `section_id` via a database CHECK constraint. Two additional cross-validation rules — overlapping school start/end times for timetable types within the same shift, and overlapping period set assignments for the same class-section — are specified in the DDL as business conditions but are **not yet implemented** in the controller logic.

---

## When This Screen Is Used

- **Setting up a new academic year** — At the start of an academic session, the Timetable Manager creates the timetable types the school uses (e.g., Standard, Exam, Remedial, Sports Day) and assigns each class-section to the appropriate timetable type.
- **Introducing a new scheduling context mid-year** — When the school introduces a new type of timetable (e.g., a "Bridge Course" timetable for remedial students), a new Timetable Type is created and assigned to the relevant class-sections.
- **Switching between teaching and exam mode** — Before exam week, the administrator assigns an Exam Timetable Type to the relevant class-sections, which may have a different period set (exam slots instead of teaching slots) and different weekly period counts.
- **Configuring shift-specific schedules** — Schools with multiple shifts create separate Timetable Types per shift (e.g., "Morning Shift Standard", "Afternoon Shift Standard") with different start/end times.
- **Deactivating or cleaning up old timetable types** — When a timetable type is no longer needed or has been replaced, it is soft-deleted to preserve historical timetable data.

---

## Default Data Load

### Timetable Types Tab

The `timetableMasters()` method in `TimetableFoundationController` loads the multi-tab page. The Timetable Types data is not loaded by `TimetableTypeController@index` (which redirects to the masters page), but directly within `timetableMasters()` when the `tab=timetable-types` parameter is active. The data is queried via:

```php
$timetableTypes = TimetableType::query()
    ->when($r->filled('tt_search'), $applyNameCodeSearch('tt_search'))
    ->when(true, $applyStatus('tt_status'))
    ->ordered()
    ->paginate(10);
```

| Filter | Input name | Default |
|--------|------------|---------|
| Search (name + code) | `tt_search` | None (all records) |
| Status (is_active) | `tt_status` | All (`$applyStatus` with no default means all) |

Results are ordered by `ordinal` (ASC) and paginated at 10 records per page. Each row shows: #, Code, Name, Shift, Start Time, End Time, Ordinal, Default badge, Status toggle, Action (View, Edit, Delete).

### Class Timetable Tab

The class timetable assignments are also loaded within `timetableMasters()` and filtered similarly:

```php
$classTimetableTypes = ClassTimetableType::query()
    ->with(['academicTerm:id,term_name', 'timetableType:id,code,name', 'class:id,name', 'section:id,name', 'periodSet:id,name'])
    ->when($r->filled('ctt_search'), function ($q) use ($r) {
        $s = $r->input('ctt_search');
        $q->whereHas('timetableType', fn($qq) => $qq->where('name', 'like', "%{$s}%")->orWhere('code', 'like', "%{$s}%"))
          ->orWhereHas('class', fn($qq) => $qq->where('name', 'like', "%{$s}%"));
    })
    ->when(true, $applyStatus('ctt_status'))
    ->orderByDesc('id')
    ->paginate(10);
```

| Filter | Input name | Default |
|--------|------------|---------|
| Search (timetable type name/code, class name) | `ctt_search` | None (all records) |
| Status (is_active) | `ctt_status` | All |

Results are ordered by `id` DESC and paginated at 10 per page. Each row shows: #, Timetable Type, Academic Term, Class, Section, Period Set, Teaching, Exam, Effective Range, Status toggle, Action (View, Edit, Delete).

---

## Key Fields at a Glance

### Timetable Type (`tt_timetable_types`)

**Identity and Origin**

| Field | Type | Description |
|-------|------|-------------|
| `code` | VARCHAR(30) | Unique machine-readable identifier (e.g., `STANDARD`, `HALF_DAY`, `UNIT_TEST_1`). Regex: `/^[A-Z0-9_]+$/i`. Uppercased on save. |
| `name` | VARCHAR(100) | Human-readable display name (e.g., "Standard Timetable", "Half Day Timetable"). |
| `description` | VARCHAR(255) | Optional explanatory text for internal use. |
| `shift_id` | INT UNSIGNED NULL | FK to `tt_shifts(id)`. Associates the timetable type with a specific school shift (Morning, Afternoon, Evening). Nullable. |

**Effective Period**

| Field | Type | Description |
|-------|------|-------------|
| `effective_from_date` | DATE | The calendar date from which this timetable type becomes active. Null means no lower bound. |
| `effective_to_date` | DATE | The calendar date after which this timetable type is no longer valid. Must be >= effective_from_date. Null means no upper bound. |

**Time Configuration**

| Field | Type | Description |
|-------|------|-------------|
| `school_start_time` | TIME | The school day start time for this timetable type (e.g., `07:30:00`). Used as the default time boundary. |
| `school_end_time` | TIME | The school day end time for this timetable type (e.g., `14:30:00`). Must be > school_start_time. |

**Flags & Ordering**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `has_teaching` | TINYINT(1) | `1` | Whether this timetable type includes teaching periods. |
| `has_exam` | TINYINT(1) | `0` | Whether this timetable type includes exam periods. |
| `ordinal` | SMALLINT UNSIGNED | `1` | Display ordering within the timetable type list. |
| `is_default` | TINYINT(1) | `0` | If `1`, this is the default timetable type. Only one record may have this flag set across the entire table. |
| `is_active` | TINYINT(1) | `1` | Whether the record is active and selectable in dropdowns. |

**Audit Fields:** `created_at`, `updated_at`, `deleted_at` (standard SoftDeletes).

### Class Timetable Type (`tt_class_timetable_types_jnt`)

**Relations**

| Field | Type | FK | Description |
|-------|------|----|-------------|
| `academic_term_id` | INT UNSIGNED NULL | `sch_academic_term(id)` | The academic term this assignment is scoped to. Nullable. |
| `timetable_type_id` | INT UNSIGNED NOT NULL | `tt_timetable_type(id)` | The timetable type being assigned. |
| `class_id` | INT UNSIGNED NOT NULL | `sch_classes(id)` | The class receiving this timetable type. |
| `section_id` | INT UNSIGNED NULL | `sch_sections(id)` | The specific section. **Must be NULL** when `applies_to_all_sections = 1`. |
| `period_set_id` | INT UNSIGNED NOT NULL | `tt_period_set(id)` | The period set that defines the daily period grid for this assignment. |

**Assignment Mode**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `applies_to_all_sections` | TINYINT(1) | `1` | If `1`, this assignment covers all sections of the class. Mutually exclusive with a non-null `section_id` via CHECK constraint. |

**Teaching & Exam Flags**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `has_teaching` | TINYINT(1) | `1` | Whether this class-section is allowed to have teaching periods under this timetable type. |
| `has_exam` | TINYINT(1) | `0` | Whether this class-section is allowed to have exam periods under this timetable type. |

**Weekly Period Counts**

| Field | Type | Description |
|-------|------|-------------|
| `weekly_teaching_period_count` | TINYINT UNSIGNED NULL | Number of teaching periods per week (derived from period set, but stored for denormalised lookup). |
| `weekly_exam_period_count` | TINYINT UNSIGNED NULL | Number of exam periods per week. |
| `weekly_free_period_count` | TINYINT UNSIGNED NULL | Number of free (non-teaching, non-exam) periods per week. |

**Effective Range**

| Field | Type | Description |
|-------|------|-------------|
| `effective_from` | DATE | Start date of this assignment's validity. Null means no lower bound. |
| `effective_to` | DATE | End date of this assignment's validity. Must be >= effective_from. Null means no upper bound. |

**Status & Audit**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `is_active` | TINYINT(1) | `1` | Active flag. |
| `created_at` | TIMESTAMP | CURRENT_TIMESTAMP | Standard audit. |
| `updated_at` | TIMESTAMP | CURRENT_TIMESTAMP ON UPDATE | Standard audit. |
| `deleted_at` | TIMESTAMP | NULL | SoftDeletes. |

---

## Business Rules and Conditions

**BR-TT-001 — Unique Code:** Every timetable type must have a unique `code` (case-insensitive at the application level — uppercased on save; enforced by DB unique key `uq_tttype_code`). Codes are limited to 30 characters and must match the regex `/^[A-Z0-9_]+$/i`.

**BR-TT-002 — Time Ordering:** When both `school_start_time` and `school_end_time` are provided, the end time must be strictly after the start time. This is enforced by the `after:school_start_time` validation rule on update. On create, the controller checks `$request->school_start_time >= $request->school_end_time` manually. The DDL also has `CONSTRAINT chk_tttype_time CHECK (school_end_time > school_start_time)` AND `(effective_from_date <= effective_to_date)`.

**BR-TT-003 — Effective Date Ordering:** If both `effective_from_date` and `effective_to_date` are provided, the from date must be on or before the to date. Enforced by `after_or_equal:effective_from_date` validation rule and the DDL CHECK constraint.

**BR-TT-004 — Single Default:** At most one timetable type may have `is_default = true` across the entire table. The controller enforces this by explicitly setting `is_default = false` on any existing default record before saving the new default — both on create and update.

**BR-TT-005 — Ordinal Required:** The `ordinal` field is required and must be an integer >= 1. No two records are required to have unique ordinals (no unique constraint), but the default global scope orders by ordinal.

**BR-TT-006 — Global Ordinal Scope:** The `TimetableType` model applies a global scope `ordered` in `booted()` that adds `orderBy('ordinal')` to every query. This cannot be removed at the query level without explicit `withoutGlobalScope()`.

**BR-TT-007 — Section Mutual Exclusion (CHECK Constraint):** The `tt_class_timetable_types_jnt` table enforces `CONSTRAINT chk_cttj_apply_to_all_section CHECK ((section_id IS NULL AND applies_to_all_sections = 1) OR (section_id IS NOT NULL AND applies_to_all_sections = 0))`. This means:
- If `applies_to_all_sections = 1`, `section_id` **must** be NULL.
- If `applies_to_all_sections = 0`, `section_id` **must not** be NULL.
The controller enforces this by setting `section_id = null` and `applies_to_all_sections = true` when "All Sections" is chosen, and `section_id = <selected>` with `applies_to_all_sections = false` per selected section.

**BR-TT-008 — Effective Date Ordering on Assignments:** On `tt_class_timetable_types_jnt`, `effective_to` must be >= `effective_from` when both are provided. Enforced by `CONSTRAINT chk_valid_effective_range CHECK (effective_from < effective_to)` at the DB level and `after_or_equal:classes.*.effective_from` in validation.

**BR-TT-009 — Overlap Check for Same Shift (NOT IMPLEMENTED):** The DDL comment on `tt_timetable_type` states: *"Application need to check and not allowed to insert/update overlapping school start/end time for 2 or more Timetable type for same shift."* This means that for a given `shift_id`, no two active timetable types should have overlapping `school_start_time`–`school_end_time` ranges (e.g., a Morning Shift Standard timetable from 07:30–14:30 and a Morning Shift Extra timetable from 08:00–15:00 would overlap). **This check is not implemented in the current controller (neither `store()` nor `update()` performs this validation).** This is a known gap per the FRD.

**BR-TT-010 — Period Set Overlap for Same Class-Section (NOT IMPLEMENTED):** The DDL comment on `tt_class_timetable_types_jnt` states: *"Application need to check and not allowed to insert/update overlapping period set for same class and section."* This means that for a given `(class_id, section_id)` combination, two active `class_timetable_type_jnt` records should not have overlapping `effective_from`–`effective_to` ranges that reference the same `period_set_id`. **This check is not implemented in the current controller.** When assignments are saved (controller re-creates all records via delete + insert), no overlap pre-validation is performed. This is a known gap.

**BR-TT-011 — Class-Section Resolution on Bulk Create:** When creating class timetable type assignments via `ClassTimetableTypeController@store`, each selected class must have at least one section resolved — either via the "All Sections" checkbox (`all_sections` array) or via explicit section IDs (`section_ids` array). The controller enforces this: `if (!in_array($classId, $allSectionClassIds) && empty($sectionIdsByClass[$classId]))` → validation error.

**BR-TT-012 — AJAX Section Exclusions:** The `getSectionsByClass()` AJAX endpoint examines existing `ClassTimetableType` records for the selected `(timetable_type_id, class_id)` and excludes sections that are already individually assigned. If an "All Sections" row exists for that class, the endpoint returns an empty response — the class is considered fully covered.

**BR-TT-013 — Create Form Class Filtering:** The `ClassTimetableTypeController@create` filters out classes where every section is already assigned for the selected timetable type. It checks for:
- Existing `applies_to_all_sections = true` rows → class is fully covered.
- Existing individual section assignments covering every active section → class is fully covered.

**BR-TT-014 — Soft Delete with Deactivation:** When a Timetable Type is deleted, the controller sets `is_active = false` before calling `delete()` (SoftDeletes). The same pattern applies to Class Timetable Type deletion. On restore, `is_active = true` is reinstated automatically (unlike Academic Terms where it is not reinstated).

**BR-TT-015 — Force Delete Removes Orphaned Assignments:** `TimetableTypeController@forceDelete` performs a hard delete. If the timetable type has child `ClassTimetableType` records, the FK constraint `fk_cttj_mode` (ON DELETE RESTRICT by default — though the DDL does not specify an ON DELETE action, MySQL defaults to RESTRICT) will prevent the deletion unless child records are removed first. **The controller does not cascade-delete child records before force-deleting the parent.**

**BR-TT-016 — Inline Assignment During Create/Update:** The `TimetableTypeController@store` and `update` methods accept an optional `classes` array parameter that allows creating `ClassTimetableType` records inline with the timetable type. This enables a one-step workflow for adding a new timetable type and immediately assigning it to class-sections.

**BR-TT-017 — Sync Strategy on Update:** The `TimetableTypeController@update` uses a **delete-all-then-recreate** strategy for inline class assignments: `ClassTimetableType::where('timetable_type_id', $timetableType->id)->delete()`. This means all existing assignments for that timetable type are soft-deleted and recreated from the submitted form data. Assignments that were not resubmitted are lost.

**BR-TT-018 — `updateOrCreate` on Bulk Store:** The `ClassTimetableTypeController@store` uses `updateOrCreate()` with unique keys `(academic_term_id, timetable_type_id, class_id, section_id, applies_to_all_sections)` to avoid duplicate records when the same combination is submitted multiple times.

---

## Workflow Steps

### Creating a Timetable Type

1. The Timetable Manager navigates to Timetable Foundation → Timetable Masters → Timetable Types tab and clicks the **Create** button.
2. The `create()` method loads:
   - `SchoolShift::active()->ordered()->get()` — active shifts for the shift dropdown.
   - `PeriodSet::active()->with('periods.periodConfig')->get()` — active period sets with their period configurations.
   - `SchoolClass::with(['classSections.section'])->where('is_active', true)->orderBy('ordinal')->get()` — classes with their sections.
   - `AcademicTerm::where('is_active', true)->orderBy('term_name')->get()` — active academic terms.
3. The user fills in:
   - Identity: Code (uppercase alphanumeric + underscore), Name, Description (optional).
   - Relation: Shift (optional dropdown).
   - Effective Period: From/To dates (optional).
   - Time Configuration: School Start Time, School End Time (optional).
   - Flags & Ordering: has_teaching (default on), has_exam (default off), is_default, is_active, ordinal.
   - Optional inline class assignments: for each class, select sections (or check "All Sections"), period set, academic term, flags, weekly period counts, effective dates.
4. The user clicks **Save**. The `store()` method:
   - Gates on `timetable-foundation.timetable-type.create`.
   - Validates via inline validation rules in the controller (no separate FormRequest).
   - Checks school_start_time < school_end_time.
   - Begins a DB transaction.
   - If `is_default = true`, clears default flag on all other records.
   - Creates the `TimetableType` record.
   - If inline `classes` array is present, creates `ClassTimetableType` records (one per section per class, or one with `section_id = null` for "All Sections").
   - Commits the transaction.
   - Logs activity.
   - Redirects to the Timetable Masters page with `tab=timetable-types` and a success flash.

### Editing a Timetable Type

1. From the Timetable Types list, the user clicks the **Edit** icon on a row.
2. The `edit()` method loads the existing timetable type, plus the same reference data as `create()` (shifts, period sets, classes, academic terms).
3. Existing class assignments are loaded via `ClassTimetableType::where('timetable_type_id', $id)->get()->groupBy('class_id')`.
4. The user modifies fields and clicks **Update**. The `update()` method:
   - Gates on `timetable-foundation.timetable-type.update`.
   - Validates (same rules as store, plus unique code ignores current record's ID).
   - Begins a DB transaction.
   - If `is_default = true`, clears default flag on all other records (excluding self).
   - Updates the `TimetableType` record.
   - **Deletes all** existing `ClassTimetableType` records for this timetable type.
   - Recreates assignments from the submitted `classes` array (if any).
   - Commits.
   - Logs activity with changed attributes.
   - Redirects with success flash.

### Viewing a Timetable Type

1. The user clicks the **View** (eye) icon on a row.
2. The `show()` method loads the timetable type with its `shift` relationship and renders a read-only detail view.

### Deleting a Timetable Type (Soft Delete)

1. The user clicks **Delete** on a row.
2. The `destroy()` method:
   - Gates on `timetable-foundation.timetable-type.delete`.
   - Sets `is_active = false`.
   - Calls `$timetableType->delete()` (SoftDeletes).
   - Logs "Trashed" activity.
   - Redirects to Timetable Masters with success flash.

### Restoring a Timetable Type

1. From the Trash view, the user clicks **Restore**.
2. The `restore()` method:
   - Gates on `timetable-foundation.timetable-type.restore`.
   - Calls `onlyTrashed()->findOrFail($id)->restore()`.
   - Sets `is_active = true`.
   - Logs "Restored" activity.
   - Redirects to the Trash view.

### Force Deleting a Timetable Type

1. From the Trash view, the user triggers **Force Delete**.
2. The `forceDelete()` method:
   - Gates on `timetable-foundation.timetable-type.delete`.
   - Calls `withTrashed()->findOrFail($id)->forceDelete()`.
   - **Note:** Will fail if child `ClassTimetableType` records exist (FK constraint). The controller does not cascade-delete children.

### Toggling Timetable Type Status

1. The user clicks the status toggle switch on a list row.
2. POST goes to `timetable-foundation.timetable-type.toggle-status`.
3. The `toggleStatus()` method:
   - Gates on `timetable-foundation.timetable-type.update`.
   - Validates `is_active` as required|boolean.
   - Saves the new status.
   - Logs "Toggled" activity.
   - Returns JSON `{ success, is_active, message }`.

### Creating Class Timetable Assignments (Bulk Form)

1. The user navigates to Timetable Masters → **Class Timetable** tab and clicks **Create**.
2. The `create()` method loads:
   - Active academic terms, active timetable types, active classes, active period sets.
   - Sections loaded via AJAX when a class is selected.
   - Pre-filtered classes (excluding those fully assigned for the selected timetable type).
3. The user:
   - Selects an academic term, timetable type, and period set (shared across all assignments).
   - Selects one or more classes.
   - For each class, checks "All Sections" or selects specific sections.
   - Optionally sets: has_teaching, has_exam, weekly period counts, effective dates, active status.
4. The user clicks **Save**. The `store()` method:
   - Gates on `timetable-foundation.class-timetable.create`.
   - Validates the form data.
   - Cross-validates that each selected class has sections resolved.
   - Creates one row per class-section combination using `updateOrCreate()`.
   - Logs an activity per created record.
   - Redirects to Timetable Masters with success flash.

### Editing a Class Timetable Assignment

1. The user clicks **Edit** on a class timetable row.
2. The `edit()` method loads the single record with reference data.
3. The user modifies fields and clicks **Update**.
4. The `update()` method validates and updates the single record.

### Deleting / Restoring / Force Deleting Class Timetable Assignments

Follows the same soft-delete pattern as Timetable Types: deactivate → soft-delete, restore → reactivate, force delete with FK dependency risk.

### AJAX Sections Endpoint

1. When the user selects a class in the Class Timetable create/edit form, JavaScript calls `GET /class-timetable/ajax/sections/{classId}?timetable_type_id=X&academic_term_id=Y`.
2. `getSectionsByClass()` returns a JSON array of sections that are not yet assigned for that (timetable_type_id, class_id) combination. If an "All Sections" row exists, returns `[]`.

---

## Example Scenario

**Green Valley School** has two shifts (Morning 07:30–13:30, Afternoon 13:30–17:30) and runs classes 1–12.

**Ms. Sharma** (Timetable Manager) sets up the timetable types for the 2025–26 academic year:

**Step 1 — Create Timetable Types:**

1. **Standard Timetable** (`STANDARD`): Morning shift, 07:30–13:30, has_teaching=1, has_exam=0, ordinal=1, is_default=1.
2. **Afternoon Standard** (`AFTN_STD`): Afternoon shift, 13:30–17:30, has_teaching=1, has_exam=0, ordinal=2, is_default=0.
3. **Half Day Timetable** (`HALF_DAY`): Morning shift, 07:30–10:30, has_teaching=1, has_exam=0, ordinal=3, is_default=0.
4. **Unit Test 1** (`UT1`): Morning shift, 07:30–11:00, has_teaching=0, has_exam=1, ordinal=4, is_default=0.
5. **Half Yearly Exam** (`HALF_YRLY`): Morning shift, 07:30–12:00, has_teaching=0, has_exam=1, ordinal=5, is_default=0.
6. **Final Exam** (`FINAL_EXAM`): Morning shift, 07:30–12:30, has_teaching=0, has_exam=1, ordinal=6, is_default=0.

**Step 2 — Assign to Class-Sections:**

Ms. Sharma assigns the **Standard Timetable** to classes 3–12 (all sections) for Term 1, with the "Standard Period Set" (8 periods/day). For classes 1–2, she assigns the **Half Day Timetable** with the "Primary Period Set" (6 periods/day).

As exam season approaches, she creates **Unit Test 1** assignments for classes 10–12 (sections A, B only) for a 2-week period, with the "Exam Period Set" (4 exam periods/day), has_teaching=0, has_exam=1.

**Step 3 — Mid-Year Update:**

After Unit Test 1 concludes, Ms. Sharma goes to the Class Timetable tab, edits the UT1 assignments, and sets `is_active = false` for those records (or deletes them). The classes revert to their Standard Timetable assignments because those assignments remain active.

---

## Related Screens

- **Timetable Masters (Other Tabs)** — The same multi-tab page hosts Shifts, Day Types, Period Types, Teacher Roles, School Days, Working Days, Class Working Days, and Period Set management. Changes to Shifts affect the shift dropdown in Timetable Types.
- **Period Set Management** — Period Sets define the daily period grid (which periods, their order, and timing). The Class Timetable Assignment links to a specific Period Set.
- **Academic Terms** — Academic Terms define the time buckets in which timetables operate. Class Timetable Assignments are scoped to an academic term.
- **Slot Requirement Generation** — After Class Timetable Assignments are defined, the system generates `tt_slot_requirement` records that drive the solver's slot availability calculations.
- **Activity Management** — Activities are scoped to timetable types, academic terms, and class-sections. Changing assignments may require regenerating activities.
- **SchoolShift Management** — The Shift entity provides the FK target for `shift_id` on Timetable Types.
- **SchoolSetup (Classes, Sections)** — The class and section entities that get assigned to Timetable Types.

---

## Requirements

**TimetableTypeController** (`Modules/TimetableFoundation/Http/Controllers/TimetableTypeController.php`, 542 lines):
- Implements: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashedTimetableType()`, `restore()`, `forceDelete()`, `toggleStatus()`.
- The `index()` method gates on `timetable-foundation.timetable-type.viewAny` and redirects to `timetable-foundation.menu.timetableMasters` with `tab=timetable-types`. The actual list is rendered by `TimetableFoundationController@timetableMasters`.
- The `create()` and `edit()` methods load the same reference data (shifts, period sets, classes, academic terms). The `edit()` additionally loads existing class assignments grouped by class_id.
- The `store()` and `update()` methods do **not** use a FormRequest — validation is inline in the controller. Write operations:
  - Run within `DB::transaction()` for atomicity.
  - Enforce single default by clearing `is_default` on other records.
  - Normalise the `code` to uppercase via `strtoupper()`.
  - Support inline `classes` array for simultaneous class-timetable-type creation.
  - Use **delete-all-then-recreate** for class assignments on update.
- The `destroy()` method soft-deletes after deactivation.
- The `forceDelete()` method does **not** cascade to child `ClassTimetableType` records.
- The `toggleStatus()` method returns JSON for AJAX.

**ClassTimetableTypeController** (`Modules/TimetableFoundation/Http/Controllers/ClassTimetableTypeController.php`, 523 lines):
- Implements: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `getSectionsByClass()`, `trashedClassTimetable()`, `restore()`, `forceDelete()`, `toggleStatus()`.
- The `index()` method gates on `timetable-foundation.class-timetable.viewAny` and redirects to the masters page.
- The `create()` method includes pre-filtering of fully assigned classes when a `timetable_type_id` query parameter is present:
  - Classes with `applies_to_all_sections = true` rows are fully covered.
  - Classes where every individual section has an assignment are fully covered.
- The `store()` method:
  - Accepts bulk creation: multiple classes × multiple sections.
  - Uses `updateOrCreate()` to prevent duplicates.
  - Cross-validates that each selected class has at least one section resolved.
  - Logs an activity record per created row.
- The `getSectionsByClass()` method is an AJAX-only endpoint (returns JSON) that excludes already-assigned sections. It does not require a specific gate other than `viewAny`.
- The `destroy()`, `restore()`, `forceDelete()`, `toggleStatus()` follow the same patterns as the TimetableTypeController.

**TimetableFoundationController@timetableMasters** (referenced method in a 2821-line controller):
- Renders the multi-tab Timetable Masters page.
- For the `timetable-types` tab, queries `TimetableType::query()` with search (name + code), status filter, ordered by `ordinal`, paginated at 10.
- For the `class-timetable` tab, queries `ClassTimetableType::query()` with eager-loaded relationships (academicTerm, timetableType, class, section, periodSet), search (timetable type name/code, class name), status filter, ordered by `id DESC`, paginated at 10.

**Models:**

| Model | Table | Key Features |
|-------|-------|-------------|
| `TimetableType` (183 lines) | `tt_timetable_types` | SoftDeletes, global scope `ordered` by `ordinal`, scope `effectiveOn(date)`, relationships: `shift()`, `classModeRules()`, `timetables()`, `classTimetableTypes()` |
| `ClassTimetableType` (143 lines) | `tt_class_timetable_types_jnt` | SoftDeletes (trait not explicitly imported but table has `deleted_at`), scope `effectiveOn(date)`, helper methods: `isEffectiveForDate()`, `allowsTeaching()`, `allowsExam()`, `appliesToAllSections()` |

**Routes:**
- `timetable-foundation.menu.timetableMasters` — multi-tab page (GET)
- `timetable-foundation.timetable-type.*` — resourceful routes (index/create/store/show/edit/update/destroy)
- `timetable-foundation.timetable-type.trashed` — trash view (GET)
- `timetable-foundation.timetable-type.restore` — restore (GET)
- `timetable-foundation.timetable-type.forceDelete` — force delete (DELETE)
- `timetable-foundation.timetable-type.toggleStatus` — AJAX toggle (POST)
- `timetable-foundation.class-timetable.*` — resourceful routes
- `timetable-foundation.class-timetable.trashed` — trash view (GET)
- `timetable-foundation.class-timetable.restore` — restore (GET)
- `timetable-foundation.class-timetable.forceDelete` — force delete (DELETE)
- `timetable-foundation.class-timetable.toggleStatus` — AJAX toggle (POST)
- `timetable-foundation.class-timetable.sections.ajax` — AJAX sections endpoint (GET)

**Namespacing:** All routes are prefixed with `timetable-foundation` and named with `timetable-foundation.*` by the RouteServiceProvider.

---

## Who Can Access

### Timetable Type Gates

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.timetable-type.viewAny` | `index()` | Required to view the Timetable Types tab |
| `timetable-foundation.timetable-type.view` | `show()` | Required to view a single timetable type's details |
| `timetable-foundation.timetable-type.create` | `create()`, `store()` | Required to show the create form and persist a new timetable type |
| `timetable-foundation.timetable-type.update` | `edit()`, `update()`, `toggleStatus()` | Required to edit, update, or toggle active status |
| `timetable-foundation.timetable-type.delete` | `destroy()`, `forceDelete()` | Required to soft-delete or force-delete |
| `timetable-foundation.timetable-type.restore` | `trashedTimetableType()`, `restore()` | Required to view trash and restore |

### Class Timetable Type Gates

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.class-timetable.viewAny` | `index()`, `getSectionsByClass()` | Required to view the tab and use the AJAX endpoint |
| `timetable-foundation.class-timetable.view` | `show()` | Required to view a single assignment |
| `timetable-foundation.class-timetable.create` | `create()`, `store()` | Required to show the create form and persist |
| `timetable-foundation.class-timetable.update` | `edit()`, `update()`, `toggleStatus()` | Required to edit, update, or toggle active status |
| `timetable-foundation.class-timetable.delete` | `destroy()` | Required to soft-delete |
| `timetable-foundation.class-timetable.restore` | `trashedClassTimetable()`, `restore()` | Required to view trash and restore |
| `timetable-foundation.class-timetable.forceDelete` | `forceDelete()` | Required to permanently delete |

**Policy Note:** Unlike AcademicTerms which has a policy class (`AcademicTermPolicy`), these controllers do not appear to have dedicated Policy classes listed. Gate checks are performed inline using `Gate::authorize()` with permission strings directly.

---

## Logic Flow

### 1. Page Load — Timetable Masters (Timetable Types Tab)

1. The user navigates to Timetable Foundation → Timetable Masters (or directly to a URL with `?tab=timetable-types`).
2. `TimetableFoundationController@timetableMasters()` runs (gated by `timetable-foundation.viewAny`).
3. It queries `TimetableType::query()` with optional search and status filters, ordered by `ordinal`, paginated.
4. The view renders the multi-tab page with the Timetable Types pane showing the search bar, status filter, and the filtered table. Each row shows Code, Name, Shift (if any), Start Time, End Time, Ordinal, Default badge, Status toggle, and Action buttons.

### 2. Create Timetable Type (Form → Submit)

1. User clicks Create → `TimetableTypeController@create()` gates on `timetable-foundation.timetable-type.create`, loads shifts, period sets, classes with sections, academic terms.
2. User fills the form. For inline class assignments, the user selects classes and either chooses "All Sections" or individually checks sections.
3. User clicks "Save". POST goes to `timetable-foundation.timetable-type.store`.
4. `store()` gates, validates inline:
   - Code: required, regex `/^[A-Z0-9_]+$/i`, max:30, unique on `tt_timetable_types.code`.
   - Name: required, max:100.
   - Description: nullable, max:255.
   - shift_id: nullable, exists:tt_shifts,id.
   - effective_from_date: nullable, date.
   - effective_to_date: nullable, date, after_or_equal:effective_from_date.
   - school_start_time: nullable, date_format:H:i.
   - school_end_time: nullable, date_format:H:i.
   - ordinal: required, integer, min:1.
   - has_teaching, has_exam, is_default, is_active: boolean.
   - classes array: nested validation (class_id, section_ids, period_set_id, academic_term_id, flags, weekly counts, effective dates).
5. Additional check: `school_start_time < school_end_time` if both provided.
6. Transaction begins:
   - If `is_default = true`, clears default on all other `TimetableType` records.
   - Creates `TimetableType` record.
   - If `classes` array present, creates `ClassTimetableType` records: one row per section per class, or one row with `section_id = null` for "All Sections".
7. Commits. Activity logged. Redirects to masters page with success flash.

### 3. Edit/Update Timetable Type

1. User clicks Edit → `edit()` gates, loads the timetable type, reference data, and existing class assignments grouped by class_id.
2. User modifies fields (including inline class assignments) and clicks "Update".
3. `update()` validates (same rules as store; code unique excludes current ID).
4. Transaction:
   - If `is_default = true`, clears default on all records except self.
   - Updates `TimetableType` record.
   - **Deletes all** existing `ClassTimetableType` records for this timetable type.
   - Recreates from submitted `classes` array (if any).
5. Commits. Activity logged (changed attributes only). Redirects with success.

### 4. Create Class Timetable (Bulk Form)

1. User navigates to Class Timetable tab → clicks Create.
2. `ClassTimetableTypeController@create()` gates, loads reference data (academic terms, timetable types, classes, period sets).
3. If `timetable_type_id` query param is present, pre-filters classes to exclude fully assigned ones.
4. User selects academic term, timetable type, period set (shared), selects multiple classes, and for each class chooses "All Sections" or specific sections.
5. User clicks Save. POST to `class-timetable.store`.
6. `store()` validates and cross-validates.
7. Iterates over selected classes:
   - For "All Sections" classes: creates/update one row with `section_id = null`, `applies_to_all_sections = true`.
   - For specific-section classes: creates/update one row per section.
   - Uses `updateOrCreate()` with unique composite key.
8. Logs activity per row. Redirects with success.

### 5. Status Toggle (AJAX)

1. User clicks status toggle switch on any list row.
2. POST to respective `toggle-status` route.
3. Controller validates `is_active` as required|boolean, saves, logs, returns JSON.

### 6. Soft Delete / Restore / Force Delete

Standard pattern: deactivate → soft-delete (or restore → reactivate for restore). Force delete does not cascade to children.

---

## Validate Before Save

### Timetable Type — Inline Validation in Controller

Validation is performed directly in `TimetableTypeController@store()` and `@update()` using `$request->validate()`. There is no separate FormRequest class.

| Field | Rule(s) | Error Message (Implied) |
|-------|---------|------------------------|
| `code` | required, string, max:30, regex:/^[A-Z0-9_]+$/i, unique:tt_timetable_types,code (update ignores current id) | The code field is required / ... may not be greater than 30 characters / ... must match the pattern / ... has already been taken. |
| `name` | required, string, max:100 | The name field is required / ... max 100 characters. |
| `description` | nullable, string, max:255 | ... may not be greater than 255 characters. |
| `shift_id` | nullable, exists:tt_shifts,id | The selected shift is invalid. |
| `effective_from_date` | nullable, date | ... is not a valid date. |
| `effective_to_date` | nullable, date, after_or_equal:effective_from_date | ... must be a date after or equal to effective from date. |
| `school_start_time` | nullable, date_format:H:i | ... does not match the format H:i. |
| `school_end_time` | nullable, date_format:H:i | ... does not match the format H:i. |
| `ordinal` | required, integer, min:1 | The ordinal field is required / ... must be an integer / ... at least 1. |
| `has_teaching` | sometimes, boolean | ... must be true or false. |
| `has_exam` | sometimes, boolean | ... must be true or false. |
| `is_default` | sometimes, boolean | ... must be true or false. |
| `is_active` | sometimes (store) / required (update) | — |
| `classes` | nullable, array | — |
| `classes.*.class_id` | required_with:classes, integer, exists:sch_classes,id | — |
| `classes.*.section_ids` | nullable, array | — |
| `classes.*.section_ids.*` | integer, exists:sch_sections,id | — |
| `classes.*.period_set_id` | nullable, integer, exists:tt_period_sets,id | — |
| `classes.*.academic_term_id` | nullable, integer | — |
| `classes.*.has_teaching` | nullable, boolean | — |
| `classes.*.has_exam` | nullable, boolean | — |
| `classes.*.weekly_teaching_period_count` | nullable, integer, min:0, max:99 | — |
| `classes.*.weekly_exam_period_count` | nullable, integer, min:0, max:99 | — |
| `classes.*.weekly_free_period_count` | nullable, integer, min:0, max:99 | — |
| `classes.*.effective_from` | nullable, date | — |
| `classes.*.effective_to` | nullable, date, after_or_equal:classes.*.effective_from | — |
| `classes.*.is_active` | nullable, boolean | — |

**Controller-level checks (not in validation rules):**

| Check | Location | Action |
|-------|----------|--------|
| `school_start_time >= school_end_time` | `store()` lines 138–148 | Returns back with error on `school_end_time`: "School end time must be after start time." |
| `is_default` on create | `store()` lines 157–160 | `TimetableType::where('is_default', true)->update(['is_default' => false])` |
| `is_default` on update | `update()` lines 357–361 | `TimetableType::where('id', '!=', $timetableType->id)->where('is_default', true)->update(['is_default' => false])` |

### Class Timetable Type — Inline Validation in Controller

| Field | Rule(s) |
|-------|---------|
| `academic_term_id` | required, integer, exists:sch_academic_term,id |
| `timetable_type_id` | required, integer, exists:tt_timetable_types,id |
| `class_ids` | required, array, min:1 |
| `class_ids.*` | integer, exists:sch_classes,id |
| `all_sections` | nullable, array |
| `all_sections.*` | integer, exists:sch_classes,id |
| `section_ids` | nullable, array |
| `section_ids.*` | nullable, array |
| `section_ids.*.*` | integer, exists:sch_sections,id |
| `period_set_id` | nullable, integer, exists:tt_period_sets,id |
| `has_teaching` | nullable, boolean |
| `has_exam` | nullable, boolean |
| `weekly_exam_period_count` | nullable, integer, min:0 |
| `weekly_teaching_period_count` | nullable, integer, min:0 |
| `weekly_free_period_count` | nullable, integer, min:0 |
| `effective_from` | nullable, date |
| `effective_to` | nullable, date, after_or_equal:effective_from |
| `is_active` | nullable, boolean |

**Controller-level checks:**

| Check | Location | Action |
|-------|----------|--------|
| Each class has sections resolved | `store()` lines 145–153 | Returns back with error: "Each selected class needs 'All Sections' checked or at least one section selected." |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing required field (code) | "The code field is required." | Validation rule |
| Code format invalid | "The code format is invalid." or built-in regex message | Validation rule (regex) |
| Duplicate code | "The code has already been taken." | Validation rule (unique) |
| school_end_time before start_time (create) | "School end time must be after start time." | Controller check (back with errors) |
| school_end_time not after start_time (update) | "The school end time must be a date after school start time." | Validation rule (after) |
| effective_to before effective_from | "The effective to date must be a date after or equal to effective from date." | Validation rule (after_or_equal) |
| ordinal not a positive integer | "The ordinal must be an integer." / "The ordinal must be at least 1." | Validation rule |
| Missing class section resolution (bulk create) | "Each selected class needs 'All Sections' checked or at least one section selected." | Controller cross-field check |
| Unauthorised access (any method) | 403 HTTP response (AuthorizationException from Gate) | Framework |
| Success — timetable type created | Flash from `flash('created.timetable_type')` | Success flash |
| Success — timetable type updated | Flash from `flash('updated.timetable_type')` | Success flash |
| Success — timetable type deleted | Flash from `flash('deleted.timetable_type')` | Success flash |
| Success — timetable type restored | Flash from `flash('restored.timetable_type')` | Success flash |
| Success — timetable type force deleted | Flash from `flash('force_deleted.timetable_type')` | Success flash |
| Success — class timetable type created | Flash from `flash('created.class_timetable_type')` | Success flash |
| Success — class timetable type toggled | JSON `{ success: true, is_active, message: flash('status_updated.*') }` | AJAX response |
| Save failure on toggleStatus | JSON `{ success: false, ... message: flash('status_switch_failed.*') }` | AJAX response |

---

## Success Scenarios

**SC-001 — Create a Standard Timetable Type with Inline Class Assignments**
Ms. Sharma creates a new "Standard Timetable" (code: `STANDARD`) for the Morning shift, with school hours 07:30–13:30, has_teaching=1, has_exam=0, ordinal=1, is_default=1. She also assigns it inline to Class 10 (Sections A, B, C) with the "Standard Period Set" for Term 1. The system validates, clears any existing default, creates the TimetableType record, creates 3 ClassTimetableType rows (one per section), logs activity, and redirects with success.

**SC-002 — Bulk Create Class Timetable Assignments**
Ms. Sharma goes to the Class Timetable tab, selects Term 1, "Standard" timetable type, "Standard Period Set". She checks classes 8 and 9, checks "All Sections" for both, and clicks Save. The system creates 2 ClassTimetableType rows (one per class, both with `section_id = null` and `applies_to_all_sections = true`), logs 2 activity entries, and redirects with success.

**SC-003 — Toggle a Timetable Type's Active Status via AJAX**
On the Timetable Types list, Ms. Sharma clicks the status switch for "Half Day" to deactivate it. The `toggleStatus()` method receives `is_active=0`, validates, saves, logs "Toggled", and returns `{ success: true, is_active: false }`. The UI updates the badge to "Inactive" without a page reload.

**SC-004 — Soft Delete and Restore a Timetable Type**
Ms. Sharma deletes the "Final Exam" timetable type (past event). The controller sets `is_active = false`, soft-deletes. Later, she restores it from the Trash view. The record is restored with `is_active = true` and is once again available for assignments.

**SC-005 — AJAX Section Filtering During Assignment Creation**
While creating a new Class Timetable assignment, Ms. Sharma selects the "Unit Test 1" timetable type. For Class 10, sections A and B are already assigned (individually) to UT1, so the AJAX endpoint returns only section C. For Class 11 (no existing assignments), all sections are returned. She selects Section C for Class 10 and all sections for Class 11. The system creates 4 rows total.

---

## Failure Scenarios

**FC-001 — Duplicate Timetable Type Code**
Ms. Sharma tries to create a second timetable type with code "STANDARD". The `unique` validation rule detects an existing record and returns: "The code has already been taken."

**FC-002 — School End Time Before Start Time**
Ms. Sharma enters school_start_time = 14:00 and school_end_time = 13:00. On create, the controller's manual check catches this and returns back with error: "School end time must be after start time." On update, the `after:school_start_time` rule triggers.

**FC-003 — Class Selected Without Sections Resolved (Bulk Create)**
Ms. Sharma creates a new Class Timetable assignment, selects Class 12 but forgets to check "All Sections" or select any individual sections. The controller's cross-field check returns: "Each selected class needs 'All Sections' checked or at least one section selected."

**FC-004 — Force Delete with Existing Child Records**
Ms. Sharma tries to permanently delete a Timetable Type that has existing Class Timetable Type assignments. The `forceDelete()` method calls `forceDelete()` on the model, but the FK constraint `fk_cttj_mode` (RESTRICT) prevents deletion, resulting in a database query exception. The exception is not caught in the controller, so the user sees an SQL error page.

**FC-005 — Unauthorised Access to Create Form**
A user without `timetable-foundation.timetable-type.create` permission attempts to access the create form. `Gate::authorize()` throws an `AuthorizationException`, resulting in a 403 HTTP response.

**FC-006 — Time Overlap Between Two Timetable Types for Same Shift (Known Gap)**
Ms. Sharma creates a "Morning Standard" (07:30–13:30) and a "Morning Extended" (08:00–15:00), both assigned to the Morning shift. The system does **not** prevent this, even though the DDL states: "Application need to check and not allowed to insert/update overlapping school start/end time for 2 or more Timetable type for same shift." This is a known unimplemented feature.

**FC-007 — Period Set Overlap for Same Class-Section (Known Gap)**
Ms. Sharma creates two Class Timetable assignments for Class 10-A: one with the Standard Period Set (effective 01-Apr to 30-Sep) and another with the same Standard Period Set (effective 01-Jun to 31-Aug) — overlapping range. The system does **not** prevent this. The DDL states: "Application need to check and not allowed to insert/update overlapping period set for same class and section." This is a known unimplemented feature.

**FC-008 — Update Deletes Unsubmitted Inline Assignments**
Ms. Sharma edits a Timetable Type that previously had assignments for Classes 10, 11, and 12. She updates the form but forgets to re-include Class 12 in the `classes` array. The controller uses delete-all-then-recreate, so the Class 12 assignment is silently removed. This is by design but can be surprising.

---

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_shifts` | FK parent (no explicit ON DELETE in DDL — defaults to RESTRICT) | `shift_id` on `tt_timetable_type` references `tt_shifts(id)` via `fk_tttype_shift`. A shift with timetable types cannot be deleted. |
| `sch_academic_term` | FK parent | `academic_term_id` on `tt_class_timetable_types_jnt` references `sch_academic_term(id)` via `fk_cttj_term`. |
| `sch_classes` | FK parent | `class_id` on `tt_class_timetable_types_jnt` references `sch_classes(id)` via `fk_cttj_class`. |
| `sch_sections` | FK parent | `section_id` on `tt_class_timetable_types_jnt` references `sch_sections(id)` via `fk_cttj_section`. |
| `tt_period_sets` | FK parent | `period_set_id` on `tt_class_timetable_types_jnt` references `tt_period_set(id)` via `fk_cttj_period_set`. |
| `tt_timetable_types` | Self-referencing / FK child | `timetable_type_id` on `tt_class_timetable_types_jnt` references `tt_timetable_type(id)` via `fk_cttj_mode`. |
| `tt_slot_requirement` | Child consumer | `tt_slot_requirement.class_timetable_type_id` references `tt_class_timetable_types_jnt(id)`. |
| `tt_timetables` | Child consumer | `tt_timetables.timetable_type_id` references `tt_timetable_type(id)`. |
| `tt_activities` | Child consumer | `tt_activities.timetable_type_id` references `tt_timetable_type(id)`. |
| `Modules\SchoolSetup\Models\SchoolShift` | Service dependency | Used in `create()` and `edit()` of TimetableTypeController for the shift dropdown. |
| `Modules\SchoolSetup\Models\SchoolClass` | Service dependency | Used in both controllers for class dropdown and section filtering. |
| `Modules\SchoolSetup\Models\Section` / `ClassSection` | Service dependency | Used for section resolution in both controllers. |
| `activityLog()` helper | Service dependency | Called on every state-changing method to record audit entries. |

### Table: `tt_timetable_types`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `code` | VARCHAR(30) | NOT NULL. Unique (`uq_tttype_code`). Regex `/^[A-Z0-9_]+$/i` |
| `name` | VARCHAR(100) | NOT NULL |
| `description` | VARCHAR(255) | NULLABLE |
| `shift_id` | INT UNSIGNED | NULLABLE. FK → `tt_shifts(id)` |
| `effective_from_date` | DATE | NULLABLE |
| `effective_to_date` | DATE | NULLABLE. CHECK: `effective_from_date <= effective_to_date` (part of `chk_tttype_time`) |
| `school_start_time` | TIME | NULLABLE |
| `school_end_time` | TIME | NULLABLE. CHECK: `school_end_time > school_start_time` (part of `chk_tttype_time`) |
| `has_exam` | TINYINT(1) | NOT NULL. DEFAULT 0 |
| `has_teaching` | TINYINT(1) | NOT NULL. DEFAULT 1 |
| `ordinal` | SMALLINT UNSIGNED | DEFAULT 1 |
| `is_default` | TINYINT(1) | DEFAULT 0 |
| `is_active` | TINYINT(1) | NOT NULL. DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULLABLE |

**Unique Keys:**
- `uq_tttype_code` — on `code`

**Indexes:**
- `idx_tttype_shift` — on `shift_id`
- Global scope orders by `ordinal`

### Table: `tt_class_timetable_types_jnt`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `academic_term_id` | INT UNSIGNED | NULLABLE. FK → `sch_academic_term(id)` (`fk_cttj_term`) |
| `timetable_type_id` | INT UNSIGNED | NOT NULL. FK → `tt_timetable_type(id)` (`fk_cttj_mode`) |
| `class_id` | INT UNSIGNED | NOT NULL. FK → `sch_classes(id)` (`fk_cttj_class`) |
| `section_id` | INT UNSIGNED | NULLABLE. FK → `sch_sections(id)` (`fk_cttj_section`). Mutually exclusive with `applies_to_all_sections` |
| `period_set_id` | INT UNSIGNED | NOT NULL. FK → `tt_period_set(id)` (`fk_cttj_period_set`) |
| `applies_to_all_sections` | TINYINT(1) | NOT NULL. DEFAULT 1. Mutually exclusive with non-null `section_id` |
| `has_teaching` | TINYINT(1) | NOT NULL. DEFAULT 1 |
| `has_exam` | TINYINT(1) | NOT NULL. DEFAULT 0 |
| `weekly_exam_period_count` | TINYINT UNSIGNED | NULLABLE |
| `weekly_teaching_period_count` | TINYINT UNSIGNED | NULLABLE |
| `weekly_free_period_count` | TINYINT UNSIGNED | NULLABLE |
| `effective_from` | DATE | NULLABLE |
| `effective_to` | DATE | NULLABLE. CHECK: `effective_from < effective_to` (`chk_valid_effective_range`) |
| `is_active` | TINYINT(1) | NOT NULL. DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULLABLE |

**Check Constraints:**
- `chk_cttj_apply_to_all_section`: `(section_id IS NULL AND applies_to_all_sections = 1) OR (section_id IS NOT NULL AND applies_to_all_sections = 0)`
- `chk_valid_effective_range`: `effective_from < effective_to`

**Indexes:**
- `idx_cttj_term` — on `(academic_term_id, timetable_type_id, class_id, section_id)`

### FK Constraints Summary

| Constraint | Child Column | Parent Table | Parent Column | On Delete |
|------------|-------------|--------------|---------------|-----------|
| `fk_tttype_shift` | `shift_id` | `tt_shifts` | `id` | RESTRICT (implied) |
| `fk_cttj_term` | `academic_term_id` | `sch_academic_terms` | `id` | RESTRICT (implied) |
| `fk_cttj_mode` | `timetable_type_id` | `tt_timetable_type` | `id` | RESTRICT (implied) |
| `fk_cttj_class` | `class_id` | `sch_classes` | `id` | RESTRICT (implied) |
| `fk_cttj_section` | `section_id` | `sch_sections` | `id` | RESTRICT (implied) |
| `fk_cttj_period_set` | `period_set_id` | `tt_period_set` | `id` | RESTRICT (implied) |

Note: The DDL does not specify explicit `ON DELETE` actions for any of these foreign keys. MySQL defaults to `ON DELETE RESTRICT` when no action is specified.
