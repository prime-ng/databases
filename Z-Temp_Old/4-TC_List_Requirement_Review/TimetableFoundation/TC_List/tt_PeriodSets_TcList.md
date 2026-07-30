# tt_PeriodSets_TcList

## Module: TimetableFoundation → Timetable Masters → Period Sets

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Period Sets |
| URL(s) | `GET timetable-foundation/timetable-masters?tab=period-sets` (index via tab), `POST timetable-foundation/period-set` (store), `GET timetable-foundation/period-set/{id}` (show), `GET timetable-foundation/period-set/{id}/edit` (edit), `PUT timetable-foundation/period-set/{periodSet}` (update), `DELETE timetable-foundation/period-set/{id}` (destroy), `GET timetable-foundation/period-set/trash/view` (trashed), `GET timetable-foundation/period-set/{id}/restore` (restore), `DELETE timetable-foundation/period-set/{id}/force-delete` (forceDelete), `POST timetable-foundation/period-set/{periodSet}/toggle-status` (toggleStatus), `GET timetable-foundation/period-set/ajax/period-configs?shift_id={id}` (ajaxPeriodConfigs), `POST timetable-foundation/period-set/{periodSet}/ajax/sync-range` (ajaxSyncRange) |
| Controller | `Modules\TimetableFoundation\Http\Controllers\PeriodSetController`; screen loaded via `TimetableFoundationController@timetableMasters()` |
| Model(s) | `Modules\TimetableFoundation\Models\PeriodSet` (table: `tt_period_sets`) |
| Validation (Create/Update) | Inline in `PeriodSetController@store()` / `@update()` — no dedicated Form Request |
| Policy | `Modules\TimetableFoundation\Policies\PeriodSetPolicy` |
| Permissions | `timetable-foundation.period-set.viewAny`, `timetable-foundation.period-set.view`, `timetable-foundation.period-set.create`, `timetable-foundation.period-set.update`, `timetable-foundation.period-set.delete`, `timetable-foundation.period-set.restore`, `timetable-foundation.period-set.forceDelete` |
| Pagination | Configurable; default page size |
| Soft Deletes | Yes (`SoftDeletes` trait on model) |
| Activity Log | Events: `Trashed`, `Restored`, `Deleted`, `Toggled` via `activityLog()` helper |

---

## 2. Pre-conditions

- Required permissions: All `timetable-foundation.period-set.*` permissions (viewAny, view, create, update, delete, restore, forceDelete)
- Required seed/reference data: At least one active `SchoolShift` (`tt_shifts`) with teaching period configs
- For range validation: The shift must have a known teaching slot count (e.g., 8 teaching slots)
- For AJAX tests: At least 8 period configs in the same shift (mix of teaching and non-teaching)
- For junction tests: At least 4 period configs available for sync testing
- For default set protection tests: At least one period set marked as default
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the Timetable Masters page loads via `TimetableFoundationController@timetableMasters()` (`GET timetable-foundation/timetable-masters?tab=period-sets`), the following data is available:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Period Sets Grid | `index()` → redirect to `timetableMasters()` | `PeriodSet::with('shift')->orderBy('name')` | None | Default page size |
| Shared: Shifts (create/edit) | `create()` / `edit()` | `SchoolShift::where('is_active', true)->orderBy('ordinal')->get()` | is_active=true | None |
| Period Configs (edit page) | `edit()` | `PeriodConfig::with('periodType')->where('shift_id', X)->where('is_active', true)->ordered()` | shift_id, is_active | None |
| Period Configs AJAX | `ajaxPeriodConfigs()` | `PeriodConfig::where('shift_id', $shiftId)->ordered()->get()` with `in_range`/`teaching_slot_count` computed | shift_id | None |

---

## 4. Test Data Strategy

- **Unique suffix:** Use `now()->format('His')` for code uniqueness (e.g., `TEST_SET_142530`)
- **Code format:** Must be uppercase + underscore only (regex `^[A-Z0-9_]+$`); test lowercase inputs are uppercased by controller
- **Global uniqueness:** `code` must be unique across all period sets (no soft-delete exclusion)
- **Range:** `to_period_ord` must be >= `from_period_ord` and <= shift's teaching slot count
- **Default set:** Only one `is_default=true` at a time; default set cannot be deleted/force-deleted/deactivated
- **Derived counters:** After update, `total_periods` and `teaching_periods` are recalculated from actual junction contents
- **Pre-test cleanup:** Delete created records by code suffix before/after tests to avoid collisions
- **FK chain:** PeriodSet → Shift (RESTRICT); PeriodSetPeriod → PeriodSet (CASCADE), PeriodConfig (RESTRICT), PeriodType (RESTRICT)
- **Soft delete:** Controller sets `is_active=false` before soft delete; restore sets `is_active=true`

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_period_sets`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | code | VARCHAR(30) | NOT NULL, UNIQUE (`uq_periodset_code`) |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | shift_id | TINYINT UNSIGNED FK | NOT NULL, FK `tt_shifts(id)` ON DELETE RESTRICT |
| BC-DB-06 | from_period_ord | TINYINT UNSIGNED | NOT NULL |
| BC-DB-07 | to_period_ord | TINYINT UNSIGNED | NOT NULL, CHECK `to_period_ord >= from_period_ord` |
| BC-DB-08 | total_periods | TINYINT UNSIGNED | NOT NULL |
| BC-DB-09 | teaching_periods | TINYINT UNSIGNED | NOT NULL |
| BC-DB-10 | exam_periods | TINYINT UNSIGNED | NOT NULL |
| BC-DB-11 | free_periods | TINYINT UNSIGNED | NOT NULL |
| BC-DB-12 | is_default | TINYINT(1) | DEFAULT 0 |
| BC-DB-13 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-16 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Database Schema — `tt_period_set_periods_jnt`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-20 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-21 | period_set_id | INT UNSIGNED FK | NOT NULL, FK `tt_period_sets(id)` ON DELETE CASCADE |
| BC-DB-22 | period_config_id | INT UNSIGNED FK | NOT NULL, FK `tt_period_configs(id)` ON DELETE RESTRICT |
| BC-DB-23 | period_ord | TINYINT UNSIGNED | NOT NULL, UNIQUE `(period_set_id, period_ord)` |
| BC-DB-24 | code | VARCHAR(20) | NOT NULL, UNIQUE `(period_set_id, code)` |
| BC-DB-25 | short_name | VARCHAR(50) | NOT NULL |
| BC-DB-26 | period_type_id | TINYINT UNSIGNED FK | NOT NULL, FK `tt_period_types(id)` ON DELETE RESTRICT |
| BC-DB-27 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-28 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-29 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-30 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.3 Validation Rules — Period Set (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | code | required, string, max:30, regex:/^[A-Z0-9_]+$/, unique:tt_period_sets,code | — |
| BC-VAL-02 | name | required, string, max:100 | — |
| BC-VAL-03 | description | nullable, string, max:255 | — |
| BC-VAL-04 | shift_id | required, integer, exists:tt_shifts,id; custom: `to_period_ord` cannot exceed shift teaching slots | "To Period Ord ({$to}) cannot exceed the number of teaching slots in this shift ({$teachingCount})." |
| BC-VAL-05 | from_period_ord | required, integer, min:1 | — |
| BC-VAL-06 | to_period_ord | required, integer, min:1, gte:from_period_ord | — |
| BC-VAL-07 | total_periods | required, integer, min:1, max:`maxPeriodsPerDay` | — |
| BC-VAL-08 | teaching_periods | required, integer, lte:total_periods | — |
| BC-VAL-09 | exam_periods | required, integer | — |
| BC-VAL-10 | free_periods | required, integer | — |
| BC-VAL-11 | is_default | nullable, boolean | — |
| BC-VAL-12 | applicable_class_ids | nullable, array | — |
| BC-VAL-13 | applicable_class_ids.* | integer, exists:sch_classes,id | — |
| BC-VAL-14 | period_config_ids | nullable, array | — |
| BC-VAL-15 | period_config_ids.* | integer, exists:tt_period_configs,id | — |
| BC-VAL-16 | **Business rule (controller)** | If `is_default=true`, clear existing defaults | Applied silently |
| BC-VAL-17 | **Business rule (controller)** | `code = strtoupper($validated['code'])` | Normalised to uppercase |

### 5.4 Validation Rules — Period Set (Update — additional checks)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | code | unique:tt_period_sets,code ->ignore($periodSet->id), regex:/^[A-Z0-9_]+$/ | — |
| BC-VAL-U02 | periods.*.code | required, string, max:20 | — |
| BC-VAL-U03 | periods.*.short_name | nullable, string, max:50 | — |
| BC-VAL-U04 | periods.*.period_type_id | required, integer, exists:tt_period_types,id | — |
| BC-VAL-U05 | periods.*.period_ord | required, integer, min:1 | — |
| BC-VAL-U06 | periods.*.is_active | nullable | — |
| BC-VAL-U07 | **Cross-row dedup (controller)** | Duplicate `period_ord` across submitted rows | "Period Ord {X} is duplicated within this set." |
| BC-VAL-U08 | **Cross-row dedup (controller)** | Duplicate `code` across submitted rows or vs existing DB rows | "Code \"{X}\" is already used by another period in this set." |
| BC-VAL-U09 | **Default set protection (controller)** | If `is_default=true`, all other sets have `is_default=false` | Applied silently |

### 5.5 Authorization

| BC ID | Permission | Controller Method(s) | Behavior |
|-------|-----------|----------------------|----------|
| BC-AUTH-01 | timetable-foundation.period-set.viewAny | `index()`, `ajaxPeriodConfigs()` | Without → 403 |
| BC-AUTH-02 | timetable-foundation.period-set.view | `show()` | Without → 403 |
| BC-AUTH-03 | timetable-foundation.period-set.create | `create()`, `store()` | Without → 403 |
| BC-AUTH-04 | timetable-foundation.period-set.update | `edit()`, `update()`, `toggleStatus()`, `ajaxSyncRange()` | Without → 403 |
| BC-AUTH-05 | timetable-foundation.period-set.delete | `destroy()` | Without → 403 |
| BC-AUTH-06 | timetable-foundation.period-set.restore | `trashedPeriodSet()`, `restore()` | Without → 403 |
| BC-AUTH-07 | timetable-foundation.period-set.forceDelete | `forceDelete()` | Without → 403 |
| BC-AUTH-G | Guest access | All routes | Redirect to /login |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Period Sets tab loads via `timetableMasters()` at `GET timetable-foundation/timetable-masters?tab=period-sets` | Grid rendered with all period sets; each row shows code, name, shift badge, from/to range, total/teaching/exam/free counts, default badge, status toggle |
| BC-BIZ-02 | Default set singleton on create | If `is_default=true`, controller clears all other sets' `is_default` before saving |
| BC-BIZ-03 | Default set singleton on update | Same clearing logic; only one set has `is_default=true` |
| BC-BIZ-04 | Code uppercase normalisation | `store()` and `update()` force `code = strtoupper($validated['code'])` |
| BC-BIZ-05 | Default set protection on destroy | If `is_default=true`, `destroy()` redirects back with error |
| BC-BIZ-06 | Default set protection on forceDelete | If `is_default=true`, returns error redirect |
| BC-BIZ-07 | Default set protection on toggleStatus | If `is_default=true` and toggling to inactive, returns JSON 403 error |
| BC-BIZ-08 | Deactivate before soft delete | `destroy()` sets `is_active=false` before `delete()` |
| BC-BIZ-09 | Restore reactivates | `restore()` sets `is_active=true` after `restore()` |
| BC-BIZ-10 | Auto-create junction rows on create | If `period_config_ids` provided, `syncPeriodSetPeriods()` creates junction records |
| BC-BIZ-11 | Picker membership sync on update | If `selected_period_config_ids` submitted, `syncPickerMembership()` diffs current vs selected; force-deletes removed, creates new |
| BC-BIZ-12 | Auto-add in range on update | If picker NOT submitted, `autoAddInRangeConfigs()` adds configs in `(from..to)` range not yet in junction |
| BC-BIZ-13 | Derived counters sync from junction | After update, `syncDerivedCountersFromJunction()` recomputes total/teaching/from/to from junction contents |
| BC-BIZ-14 | Two-pass period_ord update | Park values above max ord in Pass 1, final ordinals in Pass 2 to avoid unique collisions |
| BC-BIZ-15 | ajaxPeriodConfigs returns configs for shift | GET with `shift_id` returns JSON with `configs` array, `teaching_slot_count`, and `in_range` per config |
| BC-BIZ-16 | ajaxSyncRange persists from/to and auto-adds | POST with new from/to; updates set; auto-adds newly-in-range configs; returns JSON with `added` count |
| BC-BIZ-17 | Activity log on state changes | `activityLog()` called on destroy (Trashed), restore (Restored), forceDelete (Deleted), toggleStatus (Toggled) |
| BC-BIZ-18 | Empty state — no period sets exist | Grid shows "No records found" with Add button visible |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tt_period_sets.shift_id | tt_shifts (id) | RESTRICT |
| BC-REF-02 | tt_period_set_periods_jnt.period_set_id | tt_period_sets (id) | CASCADE |
| BC-REF-03 | tt_period_set_periods_jnt.period_config_id | tt_period_configs (id) | RESTRICT |
| BC-REF-04 | tt_period_set_periods_jnt.period_type_id | tt_period_types (id) | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Period Sets Tab — Page Loads With All UI Elements | Page loads with `?tab=period-sets`, Add Period Set button, sets grid with all columns (Code, Name, Shift, Period Range, Total, Teaching, Default, Active, Actions) | — | — | ⬜ |
| TC-P02 | Create Period Set With Required Fields Only | Period set created with code, name, shift, from/to ord, total/teaching/exam/free counts | — | — | ⬜ |
| TC-P03 | Create Period Set With All Fields (Description, Default, Configs) | Period set created with description, is_default=true, and selected period_config_ids creating junction rows | — | — | ⬜ |
| TC-P04 | Create Period Set As Default | Set created with `is_default=true`; any existing default set downgraded to `is_default=false` | — | — | ⬜ |
| TC-P05 | Create Period Set With Auto-Created Junction Rows | `period_config_ids=[1,2,3,4]` triggers `syncPeriodSetPeriods()`; 4 junction rows created with sequential period_ord | — | — | ⬜ |
| TC-P06 | Create Period Set Code Normalised to Uppercase | Enter `code="standard_8p"` (lowercase); stored as `STANDARD_8P` | — | — | ⬜ |
| TC-P07 | View Period Set Details | Show page displays code, name, description, shift badge, period range, counts, default badge, status, list of member periods | — | — | ⬜ |
| TC-P08 | Edit Period Set Loads Pre-Filled Data | Edit form shows existing set with all fields pre-populated, period config picker with in-range tagging | — | — | ⬜ |
| TC-P09 | Update Period Set Basic Fields | Update name, description, counts; fields persist correctly | — | — | ⬜ |
| TC-P10 | Update Period Set — Change From/To Ord With Auto-Add | Widen `to_period_ord` from 8 to 10; `autoAddInRangeConfigs()` creates 2 new junction rows; existing rows preserved | — | — | ⬜ |
| TC-P11 | Update Period Set — Picker Membership Sync | Uncheck config B, check config D; submit; config B force-deleted, config D created; junction reflects A, C, D | — | — | ⬜ |
| TC-P12 | Update Period Set — Inline Period Overrides | Edit junction row code, short_name, period_type_id per row; changes saved correctly | — | — | ⬜ |
| TC-P13 | Update Period Set — Swap Period Ordinals (Two-Pass) | Two rows with ordinals 2 and 3 swapped; park-and-reassign avoids unique constraint violation | — | — | ⬜ |
| TC-P14 | Update Period Set — Derived Counters Synced After Save | After junction change, `total_periods` and `teaching_periods` recomputed from actual junction contents | — | — | ⬜ |
| TC-P15 | AJAX Fetch Period Configs For Shift | GET `ajaxPeriodConfigs?shift_id=X` returns JSON with configs array, each tagged `in_range`, and `teaching_slot_count` | — | — | ⬜ |
| TC-P16 | AJAX Sync Range Inline | POST `ajaxSyncRange` with new from/to ordinals updates set and auto-adds new configs; returns JSON with `added` count | — | — | ⬜ |
| TC-P17 | Toggle Period Set Status Active ↔ Inactive | `is_active` flips; JSON success response (non-default set) | — | — | ⬜ |
| TC-P18 | Soft Delete Period Set (Non-Default) | `is_active` set to false; record soft-deleted; hidden from main grid | — | — | ⬜ |
| TC-P19 | View Trashed Period Sets | Trash view lists all soft-deleted sets with Restore and Force Delete actions | — | — | ⬜ |
| TC-P20 | Restore Soft-Deleted Period Set | Record restored; `is_active` set to true; reappears in main grid | — | — | ⬜ |
| TC-P21 | Force Delete Period Set (Non-Default) | Record permanently removed from DB | — | — | ⬜ |
| TC-P22 | Full Lifecycle: Create → View → Edit → Toggle → Delete → Restore → Force Delete | Each step in sequence succeeds; data transitions correctly | — | — | ⬜ |
| TC-P23 | Empty State — No Period Sets Exist | Grid shows empty state message with Add button visible | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Missing `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N03 | Missing `shift_id` | Validation error: "The shift id field is required." | — | — | ⬜ |
| TC-N04 | Missing `from_period_ord` | Validation error: "The from period ord field is required." | — | — | ⬜ |
| TC-N05 | Missing `to_period_ord` | Validation error: "The to period ord field is required." | — | — | ⬜ |
| TC-N06 | `code` With Invalid Characters (spaces, hyphens, lowercase) | Regex `/^[A-Z0-9_]+$/` fails; validation error | — | — | ⬜ |
| TC-N07 | Duplicate `code` | Validation error on `unique:tt_period_sets,code` | — | — | ⬜ |
| TC-N08 | `code` Exceeds 30 Characters | Validation error on `code` max:30 | — | — | ⬜ |
| TC-N09 | `name` Exceeds 100 Characters | Validation error on `name` max:100 | — | — | ⬜ |
| TC-N10 | `to_period_ord` < `from_period_ord` | Validation error on `gte:from_period_ord` | — | — | ⬜ |
| TC-N11 | `to_period_ord` Exceeds Shift Teaching Slot Count | Custom validation: "To Period Ord (10) cannot exceed the number of teaching slots in this shift (8)." | — | — | ⬜ |
| TC-N12 | `teaching_periods` > `total_periods` | Validation error on `lte:total_periods` | — | — | ⬜ |
| TC-N13 | `total_periods` = 0 | Validation error on `min:1` | — | — | ⬜ |
| TC-N14 | `from_period_ord` = 0 | Validation error on `min:1` | — | — | ⬜ |
| TC-N15 | Duplicate `period_ord` In Update Rows | Cross-row dedup error: "Period Ord 3 is duplicated within this set." | — | — | ⬜ |
| TC-N16 | Duplicate `code` In Update Rows | Cross-row dedup error: "Code \"DUP\" is already used by another period in this set." | — | — | ⬜ |
| TC-N17 | Delete Default Period Set | Redirect back with error `flash('default_period_set_delete_not_allowed')` | — | — | ⬜ |
| TC-N18 | Force Delete Default Period Set | Redirect back with error `flash('default_period_set_force_delete_not_allowed')` | — | — | ⬜ |
| TC-N19 | Toggle Default Set To Inactive | JSON 403: `flash('default_period_set_disable_not_allowed')` | — | — | ⬜ |
| TC-N20 | Invalid FK `shift_id` | Validation error: "The selected shift id is invalid." | — | — | ⬜ |
| TC-N21 | Invalid `period_config_ids.*` (non-existent config) | Validation error on `exists:tt_period_configs,id` | — | — | ⬜ |
| TC-N22 | Permission 403 — No `period-set.viewAny` | 403 Forbidden on accessing the tab | — | — | ⬜ |
| TC-N23 | Permission 403 — No `period-set.create` | 403 Forbidden on create form and store | — | — | ⬜ |
| TC-N24 | Permission 403 — No `period-set.update` | 403 Forbidden on edit, update, toggleStatus, ajaxSyncRange | — | — | ⬜ |
| TC-N25 | Permission 403 — No `period-set.delete` | 403 Forbidden on destroy | — | — | ⬜ |
| TC-N26 | Permission 403 — No `period-set.restore` | 403 Forbidden on trash view and restore | — | — | ⬜ |
| TC-N27 | Permission 403 — No `period-set.forceDelete` | 403 Forbidden on forceDelete | — | — | ⬜ |
| TC-N28 | Guest Access Redirect | Unauthenticated user redirected to /login | — | — | ⬜ |
| TC-N29 | Non-Existent Record — 404 on Show | `GET period-set/99999` → 404 | — | — | ⬜ |
| TC-N30 | Non-Existent Record — 404 on Edit | `GET period-set/99999/edit` → 404 | — | — | ⬜ |
| TC-N31 | Non-Existent Record — 404 on Update | `PUT period-set/99999` → 404 | — | — | ⬜ |
| TC-N32 | Non-Existent Record — 404 on Destroy | `DELETE period-set/99999` → 404 | — | — | ⬜ |
| TC-N33 | Non-Existent Record — 404 on Restore | `GET period-set/99999/restore` → 404 | — | — | ⬜ |
| TC-N34 | Non-Existent Record — 404 on Force Delete | `DELETE period-set/99999/force-delete` → 404 | — | — | ⬜ |
| TC-N35 | Non-Existent Record — 404 on Toggle Status | `POST period-set/99999/toggle-status` → 404 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Default Set Singleton — Create Replaces Existing | Creating Set B with `is_default=true` sets Set A's `is_default=false` | — | — | ⬜ |
| TC-D02 | A | Default Set Singleton — Update Replaces Existing | Updating Set B to `is_default=true` unsets Set A's default flag | — | — | ⬜ |
| TC-D03 | B | Code Uppercase Normalised On Create | Enter `standard_8p` → stored as `STANDARD_8P` | — | — | ⬜ |
| TC-D04 | B | Code Uppercase Normalised On Update | Existing code lowercase preserved/uppercased on re-save | — | — | ⬜ |
| TC-D05 | C | Create Auto-Syncs Junction From Configs | Create with `period_config_ids=[5,6,7]`; 3 junction rows created with correct period_ord | — | — | ⬜ |
| TC-D06 | D | Update Picker Sync Removes Unchecked Rows | Unchecking Config B; Config B force-deleted from junction | — | — | ⬜ |
| TC-D07 | D | Update Picker Sync Adds Newly Checked Rows | Checking Config D; new junction row created with auto-assigned period_ord | — | — | ⬜ |
| TC-D08 | E | Auto-Add In Range On Range Widen | Changing `to_period_ord` from 8 to 10 auto-adds configs with slot_ord 9 and 10 | — | — | ⬜ |
| TC-D09 | F | Two-Pass Ord Swap Avoids Unique Violation | Swapping ordinals 2↔3 succeeds; unique constraint not violated | — | — | ⬜ |
| TC-D10 | G | Derived Counters Recalculated After Sync | After picker sync, `total_periods` and `teaching_periods` match actual junction counts | — | — | ⬜ |
| TC-D11 | H | Soft Delete Sets is_active=false | `destroy()` sets `is_active=false` before `delete()`; record retrievable via `onlyTrashed()` | — | — | ⬜ |
| TC-D12 | H | Restore Sets is_active=true | `restore()` nullifies `deleted_at` and sets `is_active=true` | — | — | ⬜ |
| TC-D13 | I | Shift Deletion Blocked By Period Set (RESTRICT) | Cannot delete shift referenced by period sets | — | — | ⬜ |
| TC-D14 | J | Period Set Deletion Cascades To Junction (CASCADE) | Deleting period set auto-deletes all its `tt_period_set_periods_jnt` records (soft delete) | — | — | ⬜ |
| TC-D15 | K | Period Config Deletion Blocked By Junction (RESTRICT) | Cannot delete period config referenced by junction | — | — | ⬜ |
| TC-D16 | L | Activity Logged After State Changes | Activity log entries created for Trashed/Restored/Deleted/Toggled | — | — | ⬜ |
| TC-D17 | M | DB — tt_period_sets Unique Constraint | Duplicate `code` at DB level throws integrity violation | — | — | ⬜ |
| TC-D18 | N | DB — CHECK to_period_ord >= from_period_ord | Direct DB insert with `from=10, to=5` fails constraint | — | — | ⬜ |
| TC-D19 | O | Unit — PeriodSet Model $casts | `is_default`→boolean, `is_active`→boolean, period counts→integer | — | — | ⬜ |
| TC-D20 | P | Unit — PeriodSet Model Relationships | `shift()`→BelongsTo, `periodSetPeriods()`→HasMany, `periodConfigs()`→HasManyThrough | — | — | ⬜ |
| TC-D21 | Q | Integration — findOrFail Returns 404 on Invalid ID | Non-existent ID for show/edit/update/destroy returns 404 | — | — | ⬜ |
| TC-D22 | R | Integration — Gate::authorize() Before All Operations | Each controller method calls Gate::authorize() before processing; 403 w/o permissions | — | — | ⬜ |
| TC-D23 | S | Integration — All Custom Routes Registered | Every AJAX, trash, restore, forceDelete, toggleStatus route resolves to correct controller method | — | — | ⬜ |
| TC-D24 | T | Cross-Module — PeriodSet Referenced By ClassTimetableType | Period set deletion may be blocked by `tt_class_timetable_type_jnt.period_set_id` FK | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns | `$fillable` includes code, name, description, shift_id, from_period_ord, to_period_ord, total_periods, teaching_periods, exam_periods, free_periods, is_default, is_active | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers | `is_default`→boolean, `is_active`→boolean, shift_id→integer, period ordinals/counts→integer | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `use SoftDeletes;` present; `delete()` sets `deleted_at`; `restore()` nullifies | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | `shift()`→BelongsTo, `periods()`→HasMany, `periodSetPeriods()`→HasMany, `periodConfigs()`→HasManyThrough, `timetables()`→HasMany, `classModeRules()`→HasMany | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling on write methods | `store()`, `update()`, `destroy()` use try-catch; on exception → rollback + error redirect | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `syncPeriodSetPeriods()`, `syncPickerMembership()`, `autoAddInRangeConfigs()`, inline period update use `DB::transaction()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Every method calls `Gate::authorize()` with respective permission string | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | `activityLog()` called on destroy, restore, forceDelete, toggleStatus | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets active | `destroy()` sets `is_active=false` before `delete()`; `restore()` sets `is_active=true` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` flips `is_active`; default set protection | `toggleStatus()` validates, saves; if `is_default=true` and deactivating, returns 403 JSON | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashedPeriodSet()` uses `onlyTrashed()`; `restore()` uses `onlyTrashed()->findOrFail()`; `forceDelete()` uses `withTrashed()->findOrFail()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — redirect/JSON response after write | `store()`/`update()`/`destroy()` → redirect with flash; AJAX endpoints → JSON response | — | — | ◌ |
| TC-CR13 | CR | P1 | Validation — unique rule ignores current ID on update | `code` unique uses `->ignore($periodSet->id)` on update | — | — | ◌ |
| TC-CR14 | CR | P1 | Validation — cross-row period_ord and code dedup | Controller validates uniqueness of `period_ord` and `code` across submitted rows and vs existing DB rows | — | — | ◌ |
| TC-CR15 | CR | P1 | Policy — all required methods defined | Policy defines viewAny, view, create, update, delete, restore, forceDelete; permission strings match gate names | — | — | ◌ |
| TC-CR16 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | Resource route for `period-set`; custom routes for trashed, restore, forceDelete, toggleStatus, AJAX; implicit model binding throws 404 | — | — | ◌ |
| TC-CR17 | CR | P1 | View — Blade `@can` directives on tab/action buttons | Tab and action buttons guarded by permissions | — | — | ◌ |
| TC-CR18 | CR | P1 | View — `isset()`/null-safe checks for relationship variables | `$set->shift->name ?? '--'` pattern; null-safe access for optional relationships | — | — | ◌ |
| TC-CR19 | CR | P1 | Breadcrumb — route registered in `config/breadcrumb.php` | Each view defines breadcrumb hierarchy via component | — | — | ◌ |
| TC-CR20 | CR | P1 | Database — unique indexes match request validation rules | `uq_periodset_code` on `code` matches `unique:tt_period_sets,code` | — | — | ◌ |
| TC-CR21 | CR | P1 | Controller — QueryException handling for integrity violations | Catches SQLSTATE 23000; maps `uq_psp_set_code` and `uq_psp_set_period_ord` to user-friendly error messages | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PeriodSet.php` model | Model found in `Modules/TimetableFoundation/Models/` |
| 2 | Inspect `$fillable` array | Contains: code, name, description, shift_id, from_period_ord, to_period_ord, total_periods, teaching_periods, exam_periods, free_periods, is_default, is_active |
| 3 | Cross-check DDL `tt_period_sets` columns | All writable columns present; no extra columns |

#### TC-CR02: Model — `$casts` for Booleans/Integers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$casts` property | `is_default`→boolean, `is_active`→boolean |
| 2 | Verify integer casts | `shift_id`→integer, `from_period_ord`→integer, `to_period_ord`→integer, all period counts→integer |
| 3 | Create a set and fetch it | Cast fields return correct PHP types |

#### TC-CR03: Model — SoftDeletes Trait Correctly Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model for `use SoftDeletes` | `use Illuminate\Database\Eloquent\SoftDeletes;` present |
| 2 | Soft delete a record | `deleted_at` set; record excluded from normal queries |
| 3 | Query `onlyTrashed()` | Only soft-deleted records appear |
| 4 | Restore | `deleted_at` nullified |

#### TC-CR04: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `shift()` relationship | Returns `belongsTo(SchoolShift::class)` |
| 2 | Inspect `periods()` relationship | Returns `hasMany(PeriodSetPeriod::class)` |
| 3 | Inspect `periodSetPeriods()` relationship | Returns `hasMany(PeriodSetPeriod::class)` |
| 4 | Inspect `periodConfigs()` relationship | Returns `hasManyThrough(PeriodConfig::class, ...)` |
| 5 | Inspect `timetables()` relationship | Returns `hasMany(Timetable::class)` |

#### TC-CR05: Controller — Try-Catch Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` | Try-catch wraps all logic; catch rolls back and returns error redirect |
| 2 | Inspect `update()` | Same try-catch pattern; catch handles integrity violations |
| 3 | Inspect `destroy()` | Try-catch wraps deactivate + delete + activity log |

#### TC-CR06: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `syncPeriodSetPeriods()` | `DB::transaction()` wraps wipe and create all junction rows |
| 2 | Inspect `syncPickerMembership()` | `DB::transaction()` wraps forceDelete and new creates |
| 3 | Inspect `autoAddInRangeConfigs()` | `DB::transaction()` wraps all junction creates |
| 4 | Inspect inline period update in `update()` | `DB::transaction()` wraps park-and-reassign + field updates |

#### TC-CR07: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` | `Gate::authorize('timetable-foundation.period-set.viewAny')` |
| 2 | Inspect `create()` | `Gate::authorize('timetable-foundation.period-set.create')` |
| 3 | Inspect `store()` | `Gate::authorize('timetable-foundation.period-set.create')` |
| 4 | Inspect `show()` | `Gate::authorize('timetable-foundation.period-set.view')` |
| 5 | Inspect `edit()` | `Gate::authorize('timetable-foundation.period-set.update')` |
| 6 | Inspect `update()` | `Gate::authorize('timetable-foundation.period-set.update')` |
| 7 | Inspect `destroy()` | `Gate::authorize('timetable-foundation.period-set.delete')` |
| 8 | Inspect AJAX methods | `Gate::authorize('timetable-foundation.period-set.update')` on ajaxSyncRange; `viewAny` on ajaxPeriodConfigs |

#### TC-CR08: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` | `activityLog($periodSet, 'Trashed', [...])` |
| 2 | Inspect `restore()` | `activityLog($periodSet, 'Restored', [...])` |
| 3 | Inspect `forceDelete()` | `activityLog($periodSet, 'Deleted', [...])` |
| 4 | Inspect `toggleStatus()` | `activityLog($periodSet, 'Toggled', [...])` |

#### TC-CR09: Controller — `is_active=false` Before Soft Delete; Restore Sets Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` | `$periodSet->is_active = false; $periodSet->save(); $periodSet->delete();` |
| 2 | Inspect `restore()` | `$periodSet->restore(); $periodSet->is_active = true; $periodSet->save();` |

#### TC-CR10: Controller — `toggleStatus()` With Default Set Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` | Validates `is_active`; if default and deactivating → JSON 403; else saves and returns JSON |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashedPeriodSet()` | `PeriodSet::onlyTrashed()->with(...)->paginate()` |
| 2 | Inspect `restore($id)` | `PeriodSet::onlyTrashed()->findOrFail($id)->restore()` |
| 3 | Inspect `forceDelete($id)` | `PeriodSet::withTrashed()->findOrFail($id)->forceDelete()` |

#### TC-CR12: Controller — Redirect/JSON Response After Write

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` success | Redirect with flash |
| 2 | Inspect `update()` success | Redirect with flash |
| 3 | Inspect `destroy()` success | Redirect with flash; but default set returns error redirect |
| 4 | Inspect `toggleStatus()` response | JSON `{success, is_active, message}` |
| 5 | Inspect `ajaxSyncRange` response | JSON `{success, added, message}` |
| 6 | Inspect `ajaxPeriodConfigs` response | JSON `{configs: [...], teaching_slot_count: N}` |

#### TC-CR13: Validation — Unique Ignores Current ID On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `update()` code validation | `Rule::unique('tt_period_sets','code')->ignore($periodSet->id)` |

#### TC-CR14: Validation — Cross-Row Dedup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `update()` lines 263-314 | Cross-row dedup for `period_ord` and `code` |
| 2 | Verify `$seenOrds` tracking | Each submitted `period_ord` tracked; collision caught |
| 3 | Verify `$seenCodes` tracking | Each submitted `code` tracked; collision with other rows or existing DB rows caught |

#### TC-CR15: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PeriodSetPolicy.php` | Policy found |
| 2 | Inspect each method | `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` all defined; each returns `$user->can(...)` |

#### TC-CR16: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | Route group found at lines 190-196 |
| 2 | Verify resource route | `Route::resource('period-set', PeriodSetController::class)` |
| 3 | Verify custom routes | trashed, restore, forceDelete, toggleStatus, ajaxPeriodConfigs, ajaxSyncRange present |
| 4 | Verify AJAX routes before resource | AJAX routes registered before resource to avoid wildcard conflicts |

#### TC-CR17: View — Blade `@can` Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect period set list view | `@can('timetable-foundation.period-set.create')` on Add button |
| 2 | Inspect action buttons | View, Edit, Delete actions guarded by `@can` directives |

#### TC-CR18: View — Null-Safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect list view | `$set->shift->name ?? '--'` pattern for relationship access |
| 2 | Inspect show view | Null-safe access for optional relationships |

#### TC-CR19: Breadcrumb — Route Registered in Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect create view | `x-backend.components.breadcrum` with title "Create Period Set" |
| 2 | Inspect edit view | Breadcrumb hierarchy: Timetable Masters > Period Sets > Edit |

#### TC-CR20: Database — Unique Indexes Match Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for `tt_period_sets` | `uq_periodset_code` on `code` matches `unique:tt_period_sets,code` |

#### TC-CR21: Controller — QueryException Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect catch block in `update()` | SQLSTATE 23000 checked for `uq_psp_set_code` and `uq_psp_set_period_ord` |
| 2 | Verify error messages | Code collision → "Code is already used by another period in this set."; Ord collision → "Period Ord is already used by another period in this set." |

---

### 7.1 Positive TC Steps

#### TC-P01: Period Sets Tab — Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to Timetable Foundation → Timetable Masters → Period Sets tab | Page loads with `?tab=period-sets` |
| 3 | Check "Add Period Set" button | Button visible (if create permission) |
| 4 | Check sets grid columns | Code, Name, Shift badge, Period Range (from→to), Total, Teaching, Exam, Free, Default badge, Active toggle, Actions (View/Edit/Delete) |

#### TC-P02: Create Period Set With Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Period Set" | Create form opens with shift dropdown |
| 2 | Enter code `STD_8P`, name `Standard 8 Period` | Fields filled |
| 3 | Select shift "Morning", enter from=1, to=8 | Range set |
| 4 | Enter total=8, teaching=6, exam=0, free=0 | Counts filled |
| 5 | Leave is_default unchecked | Default OFF |
| 6 | Click "Save" | POST to `period-set`; redirects with success |
| 7 | DB check: `SELECT * FROM tt_period_sets WHERE code='STD_8P'` | Record exists; `is_default=0`, `is_active=1` |

#### TC-P03: Create Period Set With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter code `FULL_SET`, name `Full Set Test`, description `Test description` | Fields filled |
| 3 | Select shift, enter from=1, to=8, total=8, teaching=6, exam=1, free=1 | Range and counts set |
| 4 | Toggle `is_default=ON` | Default flag set |
| 5 | Select period_config_ids = [1,2,3,4,5,6,7,8] | 8 configs selected |
| 6 | Click "Save" | Set created with all fields |
| 7 | DB check | Record exists; `is_default=1`; 8 junction rows created |

#### TC-P04: Create Period Set As Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Set A with `is_default=true` | Set A created as default |
| 2 | Create Set B with `is_default=true` | Set B created as default |
| 3 | DB check: `SELECT id, is_default FROM tt_period_sets` | Only Set B has `is_default=1`; Set A has `is_default=0` |

#### TC-P05: Create Period Set With Auto-Created Junction Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure shift has 4 period configs with IDs 1,2,3,4 | Configs exist |
| 2 | Create period set with `period_config_ids=[1,2,3,4]` | POST to store |
| 3 | DB check: `SELECT period_config_id, period_ord FROM tt_period_set_periods_jnt WHERE period_set_id={id} ORDER BY period_ord` | 4 rows: ord=1→config1, ord=2→config2, ord=3→config3, ord=4→config4 |

#### TC-P06: Create Period Set Code Normalised to Uppercase

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with `code="standard_8p"` | Code entered in lowercase |
| 2 | DB check | `code='STANDARD_8P'` (uppercased) |

#### TC-P07: View Period Set Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a set with all fields | Record exists |
| 2 | Click "View" on that set | Show page loads |
| 3 | Verify displayed fields | Code, Name, Description, Shift (badge), Period Range, Total/Teaching/Exam/Free counts, Default badge (if applicable), Active badge, list of member periods |

#### TC-P08: Edit Period Set Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with known values | Record exists |
| 2 | Click "Edit" on that set | Edit form loads; all fields pre-filled; period config picker shows configs with in-range tagging |

#### TC-P09: Update Period Set Basic Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing set | Edit form loaded |
| 2 | Change name to "Updated Set", description to "Updated desc" | Fields changed |
| 3 | Set total=10, teaching=7, exam=1, free=2 | Counts changed |
| 4 | Click "Save" | Update succeeds; redirect with success |
| 5 | DB check | `name='Updated Set'`, `total_periods=10`, `teaching_periods=7` |

#### TC-P10: Update Period Set — Change From/To Ord With Auto-Add

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with from=1, to=8, configs for slot 1-8 in junction | 8 junction rows |
| 2 | Edit: change `to_period_ord` to 10 (picker not submitted) | Range widened |
| 3 | Click "Save" | Auto-add creates 2 new junction rows |
| 4 | DB check: `SELECT COUNT(*) FROM tt_period_set_periods_jnt WHERE period_set_id={id}` | Count = 10 |

#### TC-P11: Update Period Set — Picker Membership Sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with configs A,B,C in junction | 3 rows exist |
| 2 | Edit: uncheck B, check D; submit with `selected_period_config_ids=[A,C,D]` | Picker submitted |
| 3 | Save | Row B force-deleted; row D created |
| 4 | DB check | Junction has A, C, D only (3 rows) |

#### TC-P12: Update Period Set — Inline Period Overrides

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit set with 2 junction rows | 2 rows visible |
| 2 | Change row 1 code to `P_UPD`, short_name to `Updated P1`, period_type_id to TEACHING | Fields modified |
| 3 | Click "Save" | Changes persisted |
| 4 | DB check | Junction rows updated with new values |

#### TC-P13: Update Period Set — Swap Period Ordinals

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with 2 junction rows: ord=2 and ord=3 | Rows exist |
| 2 | Edit: swap ordinals (row 2→3, row 3→2) | Ordinals swapped in form |
| 3 | Save | Update succeeds (two-pass avoids unique violation) |
| 4 | DB check: `SELECT id, period_ord FROM tt_period_set_periods_jnt WHERE period_set_id={id} ORDER BY id` | Row 1→ord=3, Row 2→ord=2 |

#### TC-P14: Update Period Set — Derived Counters Synced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set has 8 junction rows (6 teaching, 2 non-teaching) | total=8, teaching=6 |
| 2 | Remove 1 teaching config via picker sync | 7 rows total, 5 teaching |
| 3 | DB check: `SELECT total_periods, teaching_periods FROM tt_period_sets WHERE id={id}` | `total_periods=7`, `teaching_periods=5` |

#### TC-P15: AJAX Fetch Period Configs For Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Shift has 5 configs (3 teaching, 2 non-teaching) | Configs exist |
| 2 | GET `period-set/ajax/period-configs?shift_id=1` | AJAX request |
| 3 | Check response | JSON with 5 items; each tagged with `in_range` boolean; `teaching_slot_count=3` |

#### TC-P16: AJAX Sync Range Inline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with from=1, to=8, 8 configs auto-added | Set and junction exist |
| 2 | POST `period-set/{id}/ajax/sync-range` with `from=1&to=10` | AJAX request |
| 3 | Check response | JSON `{success:true, added:2, message:"Range saved. Auto-added 2 new period(s)."}` |
| 4 | DB check: junction count | 10 rows (2 new configs auto-added) |

#### TC-P17: Toggle Period Set Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active non-default set (`is_active=1`) | Set exists |
| 2 | Click status toggle → POST with `is_active=0` | AJAX request |
| 3 | Check response | JSON `{success:true, is_active:false, message:"..."}` |
| 4 | DB check | `is_active=0` |
| 5 | Toggle back to active | JSON success; DB `is_active=1` |

#### TC-P18: Soft Delete Period Set (Non-Default)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active non-default set (`is_active=1`) | Set exists |
| 2 | Click "Delete" | DELETE to `period-set/{id}` |
| 3 | Verify redirect | Redirected with success flash |
| 4 | DB check | `is_active=0`, `deleted_at` set |
| 5 | Verify junction rows cascade-deleted | Junction rows also soft-deleted (CASCADE) |

#### TC-P19: View Trashed Period Sets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete at least one set | Set in trash |
| 2 | Navigate to trash: `GET period-set/trash/view` | Trash page loads |
| 3 | Verify columns and actions | Code, Name, Shift, deleted_at; Actions: Restore, Force Delete |

#### TC-P20: Restore Soft-Deleted Period Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trashed sets listed |
| 2 | Click "Restore" on a trashed set | GET to `period-set/{id}/restore` |
| 3 | Verify redirect | Redirected to trash view with success |
| 4 | DB check | `deleted_at=NULL`, `is_active=1` |
| 5 | Verify junction rows restored | CASCADE restored junction rows as well |

#### TC-P21: Force Delete Period Set (Non-Default)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trashed sets listed |
| 2 | Click "Force Delete" | DELETE to `period-set/{id}/force-delete` |
| 3 | Verify redirect | Redirected to trash view with success |
| 4 | DB check (including withTrashed) | Record permanently removed |

#### TC-P22: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set (TC-P02) | Set created |
| 2 | View details (TC-P07) | Details shown |
| 3 | Edit basic fields (TC-P09) | Updated |
| 4 | Toggle status inactive (TC-P17) | Status changed |
| 5 | Soft delete (TC-P18) | Set trashed |
| 6 | View in trash (TC-P19) | Set in trash list |
| 7 | Restore (TC-P20) | Set restored, active |
| 8 | Force delete (TC-P21) | Set permanently removed |

#### TC-P23: Empty State — No Period Sets Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no period sets exist | No records |
| 2 | Load Period Sets tab | Grid shows empty state message with Add button |

---

### 7.2 Negative TC Steps

#### TC-N01 to TC-N05: Missing Required Fields

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N01 | Leave `code` empty, fill all others | Validation error: "The code field is required." |
| TC-N02 | Leave `name` empty | Validation error: "The name field is required." |
| TC-N03 | Leave `shift_id` empty | Validation error: "The shift id field is required." |
| TC-N04 | Leave `from_period_ord` empty | Validation error: "The from period ord field is required." |
| TC-N05 | Leave `to_period_ord` empty | Validation error: "The to period ord field is required." |

#### TC-N06: `code` With Invalid Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter `code="standard-8p"` (hyphens, lowercase) | Regex `/^[A-Z0-9_]+$/` fails |
| 2 | Click "Save" | Validation error on regex rule |

#### TC-N07: Duplicate `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with `code="DUP_SET"` | Created |
| 2 | Create another set with `code="DUP_SET"` | Validation error on `unique:tt_period_sets,code` |

#### TC-N08 to TC-N09: Length Violations

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N08 | Enter `code` with 31+ characters | Validation error on code max:30 |
| TC-N09 | Enter `name` with 101+ characters | Validation error on name max:100 |

#### TC-N10: `to_period_ord` < `from_period_ord`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from=10, to=5 | to < from |
| 2 | Click "Save" | Validation error on `gte:from_period_ord` |

#### TC-N11: `to_period_ord` Exceeds Shift Teaching Slot Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Shift has 8 teaching slots | Teaching count = 8 |
| 2 | Set `to_period_ord=10` | Exceeds limit |
| 3 | Click "Save" | Custom error: "To Period Ord (10) cannot exceed the number of teaching slots in this shift (8)." |

#### TC-N12: `teaching_periods` > `total_periods`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `total_periods=8`, `teaching_periods=10` | Teaching exceeds total |
| 2 | Click "Save" | Validation error on `lte:total_periods` |

#### TC-N13 to TC-N14: Min Violations

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N13 | Set `total_periods=0` | Validation error on min:1 |
| TC-N14 | Set `from_period_ord=0` | Validation error on min:1 |

#### TC-N15: Duplicate `period_ord` In Update Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit period set with 2 junction rows | Both rows visible |
| 2 | Set both rows to `period_ord=3` | Duplicate ord |
| 3 | Click "Save" | Error: "Period Ord 3 is duplicated within this set." |

#### TC-N16: Duplicate `code` In Update Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit period set with 2 junction rows | Both rows visible |
| 2 | Set both to `code="DUP"` | Duplicate code |
| 3 | Click "Save" | Error: "Code \"DUP\" is already used by another period in this set." |

#### TC-N17 to TC-N19: Default Set Protection

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N17 | Ensure a set is default; click Delete | Redirect back with error `flash('default_period_set_delete_not_allowed')` |
| TC-N18 | Force Delete on a default set | Redirect back with error `flash('default_period_set_force_delete_not_allowed')` |
| TC-N19 | Toggle status on default set to inactive | JSON 403: `flash('default_period_set_disable_not_allowed')` |

#### TC-N20: Invalid FK `shift_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `shift_id` to non-existent value (999) | Invalid FK |
| 2 | Click "Save" | Validation error: "The selected shift id is invalid." |

#### TC-N21: Invalid `period_config_ids.*`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `period_config_ids` = [999] | Non-existent config ID |
| 2 | Click "Save" | Validation error on `exists:tt_period_configs,id` |

#### TC-N22 to TC-N27: Permission 403

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N22 | User without `period-set.viewAny` | 403 on accessing tab |
| TC-N23 | User without `period-set.create` | 403 on create form and store |
| TC-N24 | User without `period-set.update` | 403 on edit, update, toggleStatus, ajaxSyncRange |
| TC-N25 | User without `period-set.delete` | 403 on destroy |
| TC-N26 | User without `period-set.restore` | 403 on trash view and restore |
| TC-N27 | User without `period-set.forceDelete` | 403 on forceDelete |

#### TC-N28: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest session) | Not authenticated |
| 2 | Access any period-set route | Redirected to /login |

#### TC-N29 to TC-N35: Non-Existent Record — 404

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N29 | `GET /period-set/99999` | 404 Not Found |
| TC-N30 | `GET /period-set/99999/edit` | 404 Not Found |
| TC-N31 | `PUT /period-set/99999` | 404 Not Found |
| TC-N32 | `DELETE /period-set/99999` | 404 Not Found |
| TC-N33 | `GET /period-set/99999/restore` | 404 Not Found |
| TC-N34 | `DELETE /period-set/99999/force-delete` | 404 Not Found |
| TC-N35 | `POST /period-set/99999/toggle-status` | 404 Not Found |

---

### 7.3 Dependency TC Steps

#### TC-D01: Default Set Singleton — Create Replaces Existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Set A with `is_default=true` | Set A is default |
| 2 | Create Set B with `is_default=true` | Controller clears Set A's default before saving Set B |
| 3 | DB check: `SELECT id, is_default FROM tt_period_sets` | Only Set B has `is_default=1` |

#### TC-D02: Default Set Singleton — Update Replaces Existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Set A (`is_default=1`), Set B (`is_default=0`) | Two sets |
| 2 | Edit Set B, set `is_default=1` | Controller clears Set A's default |
| 3 | DB check | Set A: `is_default=0`, Set B: `is_default=1` |

#### TC-D03: Code Uppercase Normalised On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with `code="my_set_test"` | Lowercase entered |
| 2 | DB check | `code='MY_SET_TEST'` |

#### TC-D04: Code Uppercase Normalised On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit set, change code to `updated_set` | Lowercase entered |
| 2 | DB check | `code='UPDATED_SET'` |

#### TC-D05: Create Auto-Syncs Junction From Configs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with `period_config_ids=[5,6,7]` | Store succeeds |
| 2 | DB check: `SELECT period_config_id, period_ord FROM tt_period_set_periods_jnt WHERE period_set_id={id} ORDER BY period_ord` | ord=1→config5, ord=2→config6, ord=3→config7 |

#### TC-D06: Update Picker Sync Removes Unchecked Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set has configs A,B,C (IDs 5,6,7) in junction | 3 rows |
| 2 | Submit update with `selected_period_config_ids=[5,7]` (B unchecked) | Config B removed |
| 3 | DB check: `SELECT period_config_id FROM tt_period_set_periods_jnt WHERE period_set_id={id}` | IDs 5 and 7 only (2 rows) |

#### TC-D07: Update Picker Sync Adds Newly Checked Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set has configs A,C (IDs 5,7) in junction | 2 rows |
| 2 | Submit update with `selected_period_config_ids=[5,6,7]` (D=6 newly checked) | Config D added |
| 3 | DB check | 3 rows: IDs 5,6,7 |

#### TC-D08: Auto-Add In Range On Range Widen

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set has from=1, to=8, 8 configs in junction | 8 rows |
| 2 | Submit update with `to_period_ord=10` (picker not submitted) | Auto-add creates 2 new rows |
| 3 | DB check: junction count | 10 rows |

#### TC-D09: Two-Pass Ord Swap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 2 junction rows with period_ord=2 and ord=3 | Rows exist |
| 2 | Submit update swapping ordinals | Pass 1: park values > max; Pass 2: write final ordinals |
| 3 | DB check | Rows have swapped ordinals; no unique violation |

#### TC-D10: Derived Counters Recalculated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set has 8 junction rows (6 teaching, 2 non-teaching) | total=8, teaching=6 |
| 2 | Remove 1 teaching via picker sync | 7 rows total, 5 teaching |
| 3 | DB check: `SELECT total_periods, teaching_periods FROM tt_period_sets WHERE id={id}` | `total_periods=7`, `teaching_periods=5` |

#### TC-D11: Soft Delete Sets is_active=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active set (`is_active=1`) | Set active |
| 2 | Delete set | `is_active` set to false, then soft-deleted |
| 3 | Query `onlyTrashed()` | `is_active=0`, `deleted_at` not null |

#### TC-D12: Restore Sets is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a soft-deleted set | `restore()` nullifies `deleted_at` and sets `is_active=true` |
| 2 | Verify DB | `deleted_at=NULL`, `is_active=1` |

#### TC-D13: Shift Deletion Blocked By Period Set (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a shift that has period sets | Shift referenced by sets |
| 2 | Attempt to delete that shift | FK constraint violation; deletion blocked |

#### TC-D14: Period Set Deletion Cascades To Junction (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Period set has 5 junction rows | 5 rows exist |
| 2 | Delete the period set (soft delete) | Set soft-deleted |
| 3 | DB check junction (withTrashed) | All 5 junction rows also soft-deleted (CASCADE) |

#### TC-D15: Period Config Deletion Blocked By Junction (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a period config referenced by junction | Junction row exists |
| 2 | Attempt to delete that period config | FK constraint violation; deletion blocked |

#### TC-D16: Activity Logged After State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create then delete a set | Activity log entry with event 'Trashed' |
| 2 | Restore the set | 'Restored' entry |
| 3 | Force delete | 'Deleted' entry |
| 4 | Toggle status | 'Toggled' entry |

#### TC-D17: DB — Unique Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Direct DB insert with duplicate `code='STD_8P'` | Integrity constraint violation on `uq_periodset_code` |

#### TC-D18: DB — CHECK to_period_ord >= from_period_ord

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Direct DB insert with `from=10, to=5` | CHECK constraint violation; insert fails |

#### TC-D19: Unit — PeriodSet Model $casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Retrieve a PeriodSet from DB | Model instance returned |
| 2 | Check `is_default` type | Returns boolean |
| 3 | Check `is_active` type | Returns boolean |
| 4 | Check `total_periods` type | Returns integer |

#### TC-D20: Unit — PeriodSet Model Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fetch set with `shift` | `$set->shift` returns SchoolShift |
| 2 | Fetch set with `periodSetPeriods` | `$set->periodSetPeriods` returns Collection |
| 3 | Fetch set with `periodConfigs` | `$set->periodConfigs` returns Collection |

#### TC-D21: Integration — findOrFail Returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access show/edit/update/destroy with valid ID | Model loaded successfully |
| 2 | Access with non-existent ID (99999) | `ModelNotFoundException` → HTTP 404 |

#### TC-D22: Integration — Gate::authorize() Before All Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove permissions from test user | User lacks permissions |
| 2 | Access any period-set endpoint | 403 Forbidden |

#### TC-D23: Integration — All Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list | grep period-set` | All routes present: resource + trash/restore/forceDelete/toggleStatus/ajaxPeriodConfigs/ajaxSyncRange |
| 2 | Verify AJAX routes before resource | AJAX routes registered before resource route |

#### TC-D24: Cross-Module — PeriodSet Referenced By ClassTimetableType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a period set referenced by `tt_class_timetable_type_jnt` | Class-timetable assignment exists |
| 2 | Attempt to delete that period set | Deletion may be blocked by FK RESTRICT on `period_set_id` |
