# tts_copy_and_lock_cells_TcList

## Module: StandardTimetable → Management → Copy Timetable & Cell Lock/Unlock

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StandardTimetable |
| Tab Group | Management |
| Feature | Copy Timetable & Cell Lock/Unlock |
| URL(s) | `POST /standard-timetable/copy-timetable/{id}`, `POST /standard-timetable/lock-cell/{cellId}`, `POST /standard-timetable/unlock-cell/{cellId}`, `POST /standard-timetable/lock-all/{timetableId}` |
| Controller | `Modules\StandardTimetable\Http\Controllers\StandardTimetableController` — `copyTimetable()` lines 576-595, `lockCell()` lines 597-616, `unlockCell()` lines 618-637, `lockAll()` lines 639-656 |
| Model(s) | `Modules\TimetableFoundation\Models\Timetable` (table: `tt_timetables`), `Modules\TimetableFoundation\Models\TimetableCell` (table: `tt_timetable_cells`) |
| Service | `Modules\StandardTimetable\Services\ManualTimetableService` — `copyTimetable()` lines 78-116 |
| Validation | None (ID route parameters; service handles business logic) |
| Policy | `Modules\StandardTimetable\Policies\StandardTimetablePolicy` — `manualPlace()` method (for copyTimetable), `lock()` method (for lockCell/unlockCell/lockAll) |
| Permissions | `standard-timetable.manualPlace`, `standard-timetable.lock` |
| Pagination | None (action-only endpoints) |
| Soft Deletes | Yes (`Timetable` and `TimetableCell` use `SoftDeletes` trait; DDL shows `deleted_at` column on both tables) |

---

## 2. Pre-conditions

- Required permissions: `standard-timetable.manualPlace` (copy), `standard-timetable.lock` (lock/unlock/lockAll)
- Required seed data: At least one MANUAL `Timetable` with cells; at least one `TimetableCell` for lock/unlock tests
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

No data load — these are action-only AJAX endpoints. Each receives the record ID as a URL parameter.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| None (copy) | copyTimetable() | `Timetable::where('generation_method','MANUAL')->findOrFail($id)` | None | None |
| None (lock/unlock) | lockCell() / unlockCell() | `TimetableCell::findOrFail($cellId)` | None | None |
| None (lockAll) | lockAll() | `Timetable::findOrFail($timetableId)` | None | None |

---

## 4. Test Data Strategy

- Create `Timetable` records with `generation_method='MANUAL'` and at least 2-3 `TimetableCell` records (with teacher assignments via `tt_timetable_cell_teachers`) for copy tests
- Create `TimetableCell` records with `is_locked=false` for lock tests, `is_locked=true` for unlock tests
- Use consistent naming prefixes to identify test data
- Pre-test cleanup: Delete created timetables and cells by code/ID after tests
- Verify copied timetable has a new unique code starting with `CP_` and name with "(Copy)" suffix
- Verify all cells and cell teachers are duplicated in the copy

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_timetables` (relevant columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE (`uq_tt_code`) |
| BC-DB-03 | name | VARCHAR(200) | NOT NULL |
| BC-DB-04 | generation_method | ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') | NOT NULL DEFAULT 'MANUAL' |
| BC-DB-05 | status | ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') | NOT NULL DEFAULT 'DRAFT' |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-07 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-08 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-09 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Database Schema — `tt_timetable_cells` (relevant columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-10 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-11 | timetable_id | INT UNSIGNED | NOT NULL, FK → `tt_timetables.id`, ON DELETE CASCADE |
| BC-DB-12 | day_of_week | TINYINT UNSIGNED | NOT NULL |
| BC-DB-13 | period_ord | TINYINT UNSIGNED | NOT NULL |
| BC-DB-14 | class_group_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt.id`, ON DELETE CASCADE |
| BC-DB-15 | class_subgroup_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_class_requirement_subgroups.id`, ON DELETE CASCADE |
| BC-DB-16 | activity_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_activities.id`, ON DELETE SET NULL |
| BC-DB-17 | room_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms.id`, ON DELETE SET NULL |
| BC-DB-18 | source | ENUM('AUTO','MANUAL','SWAP','LOCK') | NOT NULL DEFAULT 'AUTO' |
| BC-DB-19 | is_locked | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-20 | has_conflict | TINYINT(1) | DEFAULT 0 |
| BC-DB-21 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-22 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-23 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-24 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-25 | UNIQUE KEY | (timetable_id, day_of_week, period_ord, class_group_id, class_subgroup_id) | `uq_cell_tt_day_period_group` |

### 5.3 Authorization

| BC ID | Permission | Methods | Behavior |
|-------|-----------|---------|----------|
| BC-AUTH-01 | standard-timetable.manualPlace | copyTimetable() | Without → 403 |
| BC-AUTH-02 | standard-timetable.lock | lockCell(), unlockCell(), lockAll() | Without → 403 |
| BC-AUTH-03 | Guest access | All endpoints | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Copy draft MANUAL timetable | New DRAFT timetable created with `code` starting with `CP_`, name = source name + " (Copy)", `generation_method='MANUAL'`, `version=1`; all cells and cell teachers duplicated |
| BC-BIZ-02 | Copy timetable with cells | Each source cell duplicated with same day_of_week, period_ord, activity_id, room_id, is_locked; cell teachers duplicated with same teacher_id and assignment_role_id |
| BC-BIZ-03 | Copy non-existent timetable | 404 via `findOrFail` |
| BC-BIZ-04 | Copy timetable with `generation_method != 'MANUAL'` | 404 via `where('generation_method','MANUAL')->findOrFail()` |
| BC-BIZ-05 | Lock cell on DRAFT/GENERATED timetable | Cell's `is_locked` set to `true`; activityLog 'Locked' recorded |
| BC-BIZ-06 | Lock cell on PUBLISHED timetable | 422: "Published timetables are immutable." |
| BC-BIZ-07 | Unlock cell on DRAFT/GENERATED timetable | Cell's `is_locked` set to `false`; activityLog 'Unlocked' recorded |
| BC-BIZ-08 | Unlock cell on PUBLISHED timetable | 422: "Published timetables are immutable." |
| BC-BIZ-09 | Lock all cells on DRAFT/GENERATED timetable | All cells in timetable get `is_locked=true`; activityLog 'LockAll' recorded |
| BC-BIZ-10 | Lock all cells on PUBLISHED timetable | 422: "Published timetables are immutable." |
| BC-BIZ-11 | Remove a locked cell | removeCell() checks `$cell->is_locked` → 422: "Cell is locked." |
| BC-BIZ-12 | Non-existent cell ID for lock/unlock | 404 via `findOrFail` |
| BC-BIZ-13 | Non-existent timetable ID for lockAll | 404 via `findOrFail` |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | timetable_id (tt_timetable_cells) | tt_timetables (id) | CASCADE |
| BC-REF-02 | cell_id (tt_timetable_cell_teachers) | tt_timetable_cells (id) | CASCADE |
| BC-REF-03 | activity_id (tt_timetable_cells) | tt_activities (id) | SET NULL |
| BC-REF-04 | room_id (tt_timetable_cells) | sch_rooms (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Copy DRAFT MANUAL timetable | New DRAFT timetable created with CP_ code, "(Copy)" suffix, same settings, version=1 | — | — | ⬜ |
| TC-P02 | Copy timetable with 2 cells — all cells duplicated | Both cells duplicated with same day/period/activity/room; cell teachers also duplicated | — | — | ⬜ |
| TC-P03 | Copy timetable with locked cells — lock status preserved | Locked cells in source remain locked in copy (is_locked=true copied) | — | — | ⬜ |
| TC-P04 | Lock a single cell on DRAFT timetable | Cell's `is_locked` set to true; JSON success; activityLog 'Locked' recorded | — | — | ⬜ |
| TC-P05 | Lock a single cell on GENERATED timetable | Cell's `is_locked` set to true; JSON success | — | — | ⬜ |
| TC-P06 | Unlock a locked cell on DRAFT timetable | Cell's `is_locked` set to false; JSON success; activityLog 'Unlocked' recorded | — | — | ⬜ |
| TC-P07 | Lock all cells on DRAFT timetable | All cells in timetable have `is_locked=true`; JSON success; activityLog 'LockAll' recorded | — | — | ⬜ |
| TC-P08 | Lock all cells on GENERATED timetable | All cells in timetable have `is_locked=true`; JSON success | — | — | ⬜ |
| TC-P09 | Unlock a locked cell then re-lock | Toggle works: unlock → is_locked=false, re-lock → is_locked=true | — | — | ⬜ |
| TC-P10 | Copy and verify activityLog | activityLog('Copied') entry created with source timetable name | — | — | ⬜ |
| TC-P11 | Lock cell and verify activityLog | activityLog('Locked') entry with cell location details | — | — | ⬜ |
| TC-P12 | Unlock cell and verify activityLog | activityLog('Unlocked') entry with cell location details | — | — | ⬜ |
| TC-P13 | Lock all cells and verify activityLog | activityLog('LockAll') entry with 'All cells locked.' message | — | — | ⬜ |
| TC-P14 | Copy timetable from GENERATED status | Source can have any status (no status check in copy); copy is always DRAFT | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Copy non-existent timetable ID | 404 | — | — | ⬜ |
| TC-N02 | Copy timetable with generation_method != 'MANUAL' | 404 | — | — | ⬜ |
| TC-N03 | Lock cell on PUBLISHED timetable | 422: "Published timetables are immutable." | — | — | ⬜ |
| TC-N04 | Unlock cell on PUBLISHED timetable | 422: "Published timetables are immutable." | — | — | ⬜ |
| TC-N05 | Lock all cells on PUBLISHED timetable | 422: "Published timetables are immutable." | — | — | ⬜ |
| TC-N06 | Lock non-existent cell ID | 404 | — | — | ⬜ |
| TC-N07 | Unlock non-existent cell ID | 404 | — | — | ⬜ |
| TC-N08 | Lock all on non-existent timetable ID | 404 | — | — | ⬜ |
| TC-N09 | Remove locked cell (via removeCell) | 422: "Cell is locked." | — | — | ⬜ |
| TC-N10 | No permission (standard-timetable.manualPlace) — copy | 403 | — | — | ⬜ |
| TC-N11 | No permission (standard-timetable.lock) — lock/unlock/lockAll | 403 | — | — | ⬜ |
| TC-N12 | Guest access to any action | Redirect to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Copy timetable — UNIQUE code constraint | `copyTimetable()` generates unique CP_ code; no uq_tt_code violation on duplicate attempt | — | — | ⬜ |
| TC-D02 | B | Copy timetable — DB transaction rollback on failure | If cell duplication fails, the new timetable is rolled back (no orphan timetable) | — | — | ⬜ |
| TC-D03 | C | FK CASCADE — delete source timetable after copy | Deleting source timetable does not affect the copy (different timetable_id) | — | — | ⬜ |
| TC-D04 | D | FK CASCADE — timetable deletion cascades to cells | Deleting a timetable cascades to delete all its cells (fk_cell_timetable) | — | — | ⬜ |
| TC-D05 | E | FK CASCADE — cell deletion cascades to cell teachers | Deleting a cell cascades to delete its teacher assignments (fk_cct_cell) | — | — | ⬜ |
| TC-D06 | F | Activity Logging — all four operations | activityLog() called on copy('Copied'), lock('Locked'), unlock('Unlocked'), lockAll('LockAll') | — | — | ⬜ |
| TC-D07 | G | Gate coverage — manualPlace on copyTimetable | `Gate::authorize('standard-timetable.manualPlace')` called in copyTimetable() | — | — | ⬜ |
| TC-D08 | H | Gate coverage — lock on lockCell/unlockCell/lockAll | `Gate::authorize('standard-timetable.lock')` called in all three lock methods | — | — | ⬜ |
| TC-D09 | I | Timetable findOrFail — copy with soft-deleted source | Soft-deleted timetable not found → 404 | — | — | ⬜ |
| TC-D10 | J | Cell findOrFail — lock/unlock with soft-deleted cell | Soft-deleted cell not found → 404 | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — Gate::authorize() on copyTimetable | `copyTimetable()` calls `Gate::authorize('standard-timetable.manualPlace')` before any logic | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — Gate::authorize() on lockCell/unlockCell/lockAll | All three lock methods call `Gate::authorize('standard-timetable.lock')` at the top | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — Published check on lockCell/unlockCell/lockAll | Each lock method checks `$timetable->status === 'PUBLISHED'` and returns 422 JSON with "Published timetables are immutable." | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transaction in copyTimetable via Service | `ManualTimetableService::copyTimetable()` uses `DB::transaction()`; failure rolls back both timetable and cells | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — JSON Success Response | All four methods return `response()->json(['success'=>true, ...])` or error JSON with status code; no HTML/flash responses | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — activity Logged on All Operations | activityLog() called on copy('Copied'), lock('Locked'), unlock('Unlocked'), lockAll('LockAll') after successful state change | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Service — ManualTimetableService::copyTimetable() duplicates cells and teachers | Each source cell replicated via `$cell->replicate()->toArray()`; cell teachers re-inserted with new `cell_id` | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Policy — manualPlace() and lock() methods defined | StandardTimetablePolicy has `manualPlace()` returning `standard-timetable.manualPlace` and `lock()` returning `standard-timetable.lock` | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Routes — All four routes registered | `web.php` defines `POST copy-timetable/{id}`, `POST lock-cell/{cellId}`, `POST unlock-cell/{cellId}`, `POST lock-all/{timetableId}` | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Controller — Gate::authorize() on copyTimetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StandardTimetableController.php` | File found |
| 2 | Inspect `copyTimetable()` line 576 | First logic line: `Gate::authorize('standard-timetable.manualPlace')` |
| 3 | Verify no other auth pattern replaces it | Only this gate call before business logic |

#### TC-CR02: Controller — Gate::authorize() on lockCell/unlockCell/lockAll

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `lockCell()` line 597 | First logic line: `Gate::authorize('standard-timetable.lock')` |
| 2 | Inspect `unlockCell()` line 618 | First logic line: `Gate::authorize('standard-timetable.lock')` |
| 3 | Inspect `lockAll()` line 639 | First logic line: `Gate::authorize('standard-timetable.lock')` |

#### TC-CR03: Controller — Published Check on lockCell/unlockCell/lockAll

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `lockCell()` | After gate, checks `$timetable->status === 'PUBLISHED'` → 422 |
| 2 | Inspect `unlockCell()` | After gate, checks `$timetable->status === 'PUBLISHED'` → 422 |
| 3 | Inspect `lockAll()` | After gate, checks `$timetable->status === 'PUBLISHED'` → 422 |
| 4 | Verify error message | All three return "Published timetables are immutable." |

#### TC-CR04: Controller — DB Transaction in copyTimetable via Service

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ManualTimetableService.php` | File found |
| 2 | Inspect `copyTimetable()` | `DB::transaction()` wraps timetable creation + cell duplication loop |
| 3 | Verify rollback on exception | Any exception during cell duplication rolls back the entire copy operation |

#### TC-CR05: Controller — JSON Success Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `copyTimetable()` success | Returns `response()->json(['success'=>true, 'timetable'=>$copy])` |
| 2 | Inspect `lockCell()` success | Returns `response()->json(['success'=>true, 'message'=>'Cell locked.'])` |
| 3 | Inspect `unlockCell()` success | `response()->json(['success'=>true, 'message'=>'Cell unlocked.'])` |
| 4 | Inspect `lockAll()` success | `response()->json(['success'=>true, 'message'=>'All cells locked.'])` |
| 5 | Inspect error paths | All error responses return JSON with `success=>false` and appropriate HTTP status code |

#### TC-CR06: Controller — activity Logged on All Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `copyTimetable()` | `activityLog($copy, 'Copied', ['message'=>"Timetable copied from '{$source->name}'"])` after success |
| 2 | Inspect `lockCell()` | `activityLog($cell, 'Locked', ['message'=>"Cell locked at day {$cell->day_of_week}, period {$cell->period_ord}."])` |
| 3 | Inspect `unlockCell()` | `activityLog($cell, 'Unlocked', [...])` |
| 4 | Inspect `lockAll()` | `activityLog($timetable, 'LockAll', ['message'=>'All cells locked.'])` |

#### TC-CR07: Service — ManualTimetableService::copyTimetable() Duplicates Cells and Teachers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `copyTimetable()` lines 95-109 | `$cells = TimetableCell::where('timetable_id', $source->id)->get()` |
| 2 | Verify cell replication | Each cell uses `$cell->replicate()->toArray()` to copy all fields |
| 3 | Verify teacher replication | `DB::table('tt_timetable_cell_teachers')->insert([...])` with teacher_id, assignment_role_id, is_substitute from source |

#### TC-CR08: Policy — manualPlace() and lock() Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StandardTimetablePolicy.php` | File found |
| 2 | Verify `manualPlace()` | Method `manualPlace(User $user): bool` returns `$user->can('standard-timetable.manualPlace')` |
| 3 | Verify `lock()` | Method `lock(User $user): bool` returns `$user->can('standard-timetable.lock')` |

#### TC-CR09: Routes — All Four Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php` in routes | Routes file found |
| 2 | Verify copy-timetable | `Route::post('copy-timetable/{id}', ...)` registered |
| 3 | Verify lock-cell | `Route::post('lock-cell/{cellId}', ...)` registered |
| 4 | Verify unlock-cell | `Route::post('unlock-cell/{cellId}', ...)` registered |
| 5 | Verify lock-all | `Route::post('lock-all/{timetableId}', ...)` registered |

### 7.1 Positive TC Steps

#### TC-P01: Copy DRAFT MANUAL Timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable: status='DRAFT', generation_method='MANUAL', name="Semester 1 TT", code="TT_SRC_01" | Source timetable exists with ID=X |
| 2 | POST `/standard-timetable/copy-timetable/{X}` | JSON response |
| 3 | Check response | `{"success": true, "timetable": {...}}` |
| 4 | DB check: new timetable code | Starts with `CP_` (e.g., `CP_20250718_120000_aBcD`) |
| 5 | DB check: new timetable name | "Semester 1 TT (Copy)" |
| 6 | DB check: new timetable status | 'DRAFT' |
| 7 | DB check: new timetable generation_method | 'MANUAL' |
| 8 | DB check: new timetable version | 1 |
| 9 | Verify source timetable unchanged | Source still exists with original name, code, status |

---

#### TC-P02: Copy Timetable With 2 Cells — All Cells Duplicated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create source timetable (ID=X) with 2 cells: cell A (day=1, period=1, activity_id=1) and cell B (day=2, period=3, activity_id=2) with teacher assignments | 2 cells exist with cell teachers |
| 2 | POST copy-timetable/{X} | Copy created with ID=Y |
| 3 | DB check: `SELECT COUNT(*) FROM tt_timetable_cells WHERE timetable_id=Y` | 2 cells |
| 4 | DB check: cell A in copy has same day_of_week, period_ord, activity_id | day=1, period=1, activity_id=1 |
| 5 | DB check: cell B in copy has same day_of_week, period_ord, activity_id | day=2, period=3, activity_id=2 |
| 6 | DB check: cell teachers count for copy cells | Same number as source, with same teacher_id and assignment_role_id |

---

#### TC-P03: Copy Timetable With Locked Cells — Lock Status Preserved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create source timetable with 1 locked cell (is_locked=true) and 1 unlocked cell (is_locked=false) | Source cells with mixed lock status |
| 2 | POST copy-timetable/{id} | Copy created |
| 3 | DB check: locked cell in copy | `is_locked` = true |
| 4 | DB check: unlocked cell in copy | `is_locked` = false |

---

#### TC-P04: Lock a Single Cell on DRAFT Timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable with cell: is_locked=false | Cell exists with ID=C |
| 2 | POST `/standard-timetable/lock-cell/{C}` | JSON success |
| 3 | Check response | `{"success": true, "message": "Cell locked."}` |
| 4 | DB check: `SELECT is_locked FROM tt_timetable_cells WHERE id=C` | `is_locked` = 1 |

---

#### TC-P05: Lock a Single Cell on GENERATED Timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create GENERATED timetable with cell: is_locked=false | Cell exists with ID=D |
| 2 | POST `/standard-timetable/lock-cell/{D}` | JSON success: "Cell locked." |
| 3 | DB check | `is_locked` = 1 |

---

#### TC-P06: Unlock a Locked Cell on DRAFT Timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable with cell: is_locked=true | Cell exists with ID=E |
| 2 | POST `/standard-timetable/unlock-cell/{E}` | JSON success |
| 3 | Check response | `{"success": true, "message": "Cell unlocked."}` |
| 4 | DB check: `SELECT is_locked FROM tt_timetable_cells WHERE id=E` | `is_locked` = 0 |

---

#### TC-P07: Lock All Cells on DRAFT Timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable with 3 cells: all is_locked=false | 3 cells exist |
| 2 | POST `/standard-timetable/lock-all/{timetableId}` | JSON success |
| 3 | Check response | `{"success": true, "message": "All cells locked."}` |
| 4 | DB check: `SELECT COUNT(*) FROM tt_timetable_cells WHERE timetable_id=X AND is_locked=1` | 3 (all cells locked) |

---

#### TC-P08: Lock All Cells on GENERATED Timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create GENERATED timetable with 2 cells: is_locked=false | 2 cells exist |
| 2 | POST lock-all/{id} | JSON success: "All cells locked." |
| 3 | DB check | Both cells have is_locked=1 |

---

#### TC-P09: Unlock a Locked Cell Then Re-lock

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cell with is_locked=true | Cell exists with ID=F |
| 2 | POST unlock-cell/{F} | Success: is_locked becomes 0 |
| 3 | POST lock-cell/{F} | Success: is_locked becomes 1 again |
| 4 | DB check final state | is_locked = 1 |

---

#### TC-P10: Copy and Verify activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable with code='TT_COPYLOG' | Timetable exists |
| 2 | POST copy-timetable | Success |
| 3 | Check activity_log | Entry with event='Copied', message containing source timetable name and user |

---

#### TC-P11: Lock Cell and Verify activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cell with is_locked=false on DRAFT timetable | Cell exists |
| 2 | POST lock-cell | Success |
| 3 | Check activity_log | Entry with event='Locked', message includes day and period of cell |

---

#### TC-P12: Unlock Cell and Verify activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cell with is_locked=true | Cell exists |
| 2 | POST unlock-cell | Success |
| 3 | Check activity_log | Entry with event='Unlocked', message includes day and period of cell |

---

#### TC-P13: Lock All Cells and Verify activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable with 2 cells | Timetable exists |
| 2 | POST lock-all | Success |
| 3 | Check activity_log | Entry with event='LockAll', message 'All cells locked.' |

---

#### TC-P14: Copy Timetable From GENERATED Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create GENERATED timetable with code='TT_GEN_SRC' | Timetable exists with ID=G |
| 2 | POST copy-timetable/{G} | Success |
| 3 | DB check: status of copy | 'DRAFT' (always DRAFT regardless of source status) |

### 7.2 Negative TC Steps

#### Negative Tests — Copy and Lock Cells (Compact)

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N01 | POST copy-timetable/99999 | 404 | Model not found |
| TC-N02 | Create timetable with generation_method='FULL_AUTO' → POST copy-timetable | 404 | findOrFail scoped to MANUAL |
| TC-N03 | Create PUBLISHED timetable with cell → POST lock-cell/{cellId} | 422 | "Published timetables are immutable." |
| TC-N04 | Create PUBLISHED timetable with locked cell → POST unlock-cell/{cellId} | 422 | "Published timetables are immutable." |
| TC-N05 | Create PUBLISHED timetable → POST lock-all/{timetableId} | 422 | "Published timetables are immutable." |
| TC-N06 | POST lock-cell/99999 | 404 | Cell not found |
| TC-N07 | POST unlock-cell/99999 | 404 | Cell not found |
| TC-N08 | POST lock-all/99999 | 404 | Timetable not found |
| TC-N09 | Create cell with is_locked=true → POST remove-cell with that cell | 422 | "Cell is locked." |
| TC-N10 | Login as user without standard-timetable.manualPlace → POST copy-timetable | 403 | Forbidden |
| TC-N11 | Login as user without standard-timetable.lock → POST lock-cell/unlock-cell/lock-all | 403 | Forbidden |
| TC-N12 | Logout → POST any of the four endpoints | Redirect to /login | Guest access blocked |

### 7.3 Dependency TC Steps

#### TC-D01: Copy Timetable — UNIQUE Code Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Copy a timetable | New code starts with `CP_` and includes timestamp + random string |
| 2 | Verify uniqueness | Code is unique in `tt_timetables.code` (no uq_tt_code violation) |
| 3 | Rapid double-copy same source | Both copies get different unique codes |

#### TC-D02: Copy Timetable — DB Transaction Rollback on Failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ManualTimetableService::copyTimetable()` | Wrapped in `DB::transaction()` |
| 2 | Verify rollback behavior | If cell creation fails after timetable is created, timetable creation is rolled back too |

#### TC-D03: FK CASCADE — Delete Source Timetable After Copy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create source timetable with 1 cell | Source ID=X, Copy ID=Y |
| 2 | Delete source timetable | Source and its cells deleted |
| 3 | Check copy timetable still exists | Copy Y still exists with its own cells |

#### TC-D04: FK CASCADE — Timetable Deletion Cascades to Cells

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with 3 cells | Timetable exists with 3 cells |
| 2 | Delete the timetable | Timetable soft-deleted |
| 3 | Check cells | Cells also deleted (CASCADE on fk_cell_timetable) |

#### TC-D05: FK CASCADE — Cell Deletion Cascades to Cell Teachers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cell with 2 teacher assignments | 2 records in tt_timetable_cell_teachers |
| 2 | Delete the cell | Cell soft-deleted |
| 3 | Check cell_teachers | Related teacher records also deleted (CASCADE on fk_cct_cell) |

#### TC-D06: Activity Logging — All Four Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform copy, lock, unlock, lockAll on test data | All succeed |
| 2 | Query activity_log | 4 entries with correct event names: 'Copied', 'Locked', 'Unlocked', 'LockAll' |

#### TC-D07: Gate Coverage — manualPlace on copyTimetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `copyTimetable()` | `Gate::authorize('standard-timetable.manualPlace')` present |
| 2 | Test with user without this permission | 403 Forbidden |

#### TC-D08: Gate Coverage — lock on lockCell/unlockCell/lockAll

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect all three methods | All call `Gate::authorize('standard-timetable.lock')` |
| 2 | Test with user without this permission | 403 Forbidden on all three |

#### TC-D09: Timetable findOrFail — Copy With Soft-Deleted Source

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and soft-delete a MANUAL timetable | deleted_at is set |
| 2 | POST copy-timetable/{id} | 404 — findOrFail excludes soft-deleted |

#### TC-D10: Cell findOrFail — Lock/Unlock With Soft-Deleted Cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and soft-delete a cell | deleted_at is set |
| 2 | POST lock-cell/{id} | 404 |
| 3 | POST unlock-cell/{id} | 404 |
