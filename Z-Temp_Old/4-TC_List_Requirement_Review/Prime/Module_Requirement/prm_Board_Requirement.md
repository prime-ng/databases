# Prime — Board Management

**Feature:** Board Management | **REQ-ID:** REQ-PRM-009 | **Priority:** P0 (MUST)

---

## 1. Description

The Board Management feature enables Platform IT/Ops and Super Admins to manage education boards that serve as reference data for all school modules. Boards represent educational curricula such as CBSE, ICSE, State Boards, and other recognized boards. When a board is deactivated, it no longer appears in school configuration dropdowns across all tenant modules. Boards support the full CRUD lifecycle including soft-delete, restore, force-delete, and AJAX toggle-status.

**Key Capabilities:**
- CRUD operations for boards (name, short_name, is_active)
- Soft-delete, trash view, restore, and force-delete
- AJAX toggle-status for active/inactive flag
- Validation: name and short_name are unique
- Activity logging for all state-changing operations

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/Prime/app/Http/Controllers/BoardController.php` | 201 | DONE |
| Model | `Modules\GlobalMaster\Models\Board` | 37 | DONE |
| Form Request | `Modules/Prime/app/Http/Requests/BoardRequest.php` | 56 | EXISTS |
| View (index) | `prime::board.index` | — | EXISTS |
| View (create) | `prime::board.create` | — | EXISTS |
| View (show) | `prime::board.show` | — | EXISTS |
| View (edit) | `prime::board.edit` | — | EXISTS |
| View (trash) | `prime::board.trash` | — | EXISTS |

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/prime/board` | `index` | `prime.board.viewAny` | ✅ Gate check present |
| GET | `/prime/board/create` | `create` | `prime.board.create` | ✅ Gate check present |
| POST | `/prime/board` | `store` | `prime.board.create` | ✅ Gate + Form Request |
| GET | `/prime/board/{board}` | `show` | `prime.board.view` | ✅ Gate check present |
| GET | `/prime/board/{board}/edit` | `edit` | `prime.board.update` | ✅ Gate check present |
| PUT | `/prime/board/{board}` | `update` | `prime.board.update` | ✅ Gate + Form Request |
| DELETE | `/prime/board/{board}` | `destroy` | `prime.board.delete` | ✅ Gate check present |
| GET | `/prime/board/trash/view` | `trashedBoard` | `prime.board.restore` | ✅ Gate check present |
| GET | `/prime/board/{id}/restore` | `restore` | `prime.board.restore` | ✅ Gate check present |
| DELETE | `/prime/board/{id}/force-delete` | `forceDelete` | `prime.board.forceDelete` | ✅ Gate check present |
| POST | `/prime/board/{board}/toggle-status` | `toggleStatus` | `prime.board.update` | ✅ Gate check present |

---

## 4. Data Model

### 4.1 Board (`glb_boards` — global_master database)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `short_name` | VARCHAR(10) | ✅ | — | UNIQUE; e.g. "CBSE", "ICSE" |
| `name` | VARCHAR(50) | ✅ | — | Full name; e.g. "Central Board of Secondary Education" |
| `is_active` | TINYINT(1) | ✅ | 1 | — |
| `deleted_at` | TIMESTAMP | — | NULL | Soft delete |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

**Model Fillable:** name, short_name, is_active
**Model Casts:** is_active (boolean)
**Connection:** `global_master_mysql`

### 4.2 Validation Rules (BoardRequest)

| Field | Rules |
|-------|-------|
| `name` | required, string, max:50, unique:glb_boards (ignores current ID on update) |
| `short_name` | required, string, max:10, unique:glb_boards (ignores current ID on update) |
| `is_active` | required, boolean |

### 4.3 Relations

| Relation | Type | Target | Pivot |
|----------|------|--------|-------|
| `organizations` | belongsToMany | `Modules\SchoolSetup\Models\Organization` | `sch_board_organization_jnt` |

---

## 5. Controller Implementation Details

### 5.1 `index()`

- **Gate:** `Gate::authorize('prime.board.viewAny')`
- **Query:** `Board::paginate(10)`
- **View:** `prime::board.index` with `compact('boards')`

### 5.2 `create()`

- **Gate:** `Gate::authorize('prime.board.create')`
- **View:** `prime::board.create`

### 5.3 `store(BoardRequest $request)`

- **Gate:** `Gate::authorize('prime.board.create')`
- **Logic:** `Board::create($request->all())` — note: uses `$request->all()` not `$request->validated()` — **potential mass assignment issue if $fillable is not strictly guarded**
- **Audit:** `activityLog($board, 'Stored', ...)`
- **Redirect:** `central.prime.session-board-setup.index#academicboard`

### 5.4 `show(Board $board)`

- **Gate:** `Gate::authorize('prime.board.view')`
- **View:** `prime::board.show` with `compact('board')`

### 5.5 `edit(string $id)`

- **Gate:** `Gate::authorize('prime.board.update')`
- **Query:** `Board::findOrFail($id)`
- **View:** `prime::board.edit` with `compact('board')`

### 5.6 `update(BoardRequest $request, Board $board)`

- **Gate:** `Gate::authorize('prime.board.update')`
- **Logic:** Captures original values, calls `$board->update($request->all())` — note: uses `$request->all()` not `$request->validated()`
- **Audit:** Captures changed attributes with old/new values; calls `activityLog()` only when changes exist
- **Redirect:** `central.prime.session-board-setup.index#academicboard`

### 5.7 `destroy(string $id)`

- **Gate:** `Gate::authorize('prime.board.delete')`
- **Logic:** Sets `is_active = false`, saves, then calls `$board->delete()` (soft-delete)
- **Audit:** `activityLog($board, 'Trashed', ...)`
- **Redirect:** `central.prime.session-board-setup.index#academicboard`

### 5.8 `trashedBoard()`

- **Gate:** `Gate::authorize('prime.board.restore')`
- **Query:** `Board::onlyTrashed()->paginate(10)`
- **View:** `prime::board.trash` with `compact('boards')`

### 5.9 `restore($id)`

- **Gate:** `Gate::authorize('prime.board.restore')`
- **Query:** `Board::withTrashed()->findOrFail($id)`
- **Logic:** Calls `$board->restore()`
- **Audit:** `activityLog($board, 'Restored', ...)`
- **Redirect:** `central.prime.board.trashed`

### 5.10 `forceDelete($id)`

- **Gate:** `Gate::authorize('prime.board.forceDelete')`
- **Query:** `Board::withTrashed()->findOrFail($id)`
- **Logic:** Calls `$board->forceDelete()`
- **Audit:** `activityLog($board, 'Deleted', ...)`
- **Redirect:** `central.prime.board.trashed`

### 5.11 `toggleStatus(Request $request, Board $board)` — JSON

- **Gate:** `Gate::authorize('prime.board.update')`
- **Validation:** `is_active` required, boolean
- **Logic:** Sets `$board->is_active = $newStatus`, calls `$board->save()`
- **Audit:** `activityLog($board, 'Toggled', ...)`
- **Response:** JSON `{ success, is_active, message }` — success/error depends on `save()` return value

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:-----------:|
| BR-PRM-023 | All state-changing operations must produce activity log entry | ✅ All 7 state-changing methods call `activityLog()` |

---

## 7. Security Rules

| Rule | Implementation |
|------|---------------|
| Gate check on `viewAny` | ✅ `index()` |
| Gate check on `create` | ✅ `create()`, `store()` |
| Gate check on `view` | ✅ `show()` |
| Gate check on `update` | ✅ `edit()`, `update()`, `toggleStatus()` |
| Gate check on `delete` | ✅ `destroy()` |
| Gate check on `restore` | ✅ `trashedBoard()`, `restore()` |
| Gate check on `forceDelete` | ✅ `forceDelete()` |
| Form Request validation | ✅ `BoardRequest` with rules + authorization |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | `store()` and `update()` use `$request->all()` instead of `$request->validated()` — violates project convention (NFR-PRM-004) | Security — mass assignment risk | P1 — High | ⬜ |
| 2 | No feature tests exist for BoardController | Testing gap | P1 — High | ⬜ |
| 3 | `is_active` is listed in both `$fillable` and `$casts` — consistent but redundant in `$request->all()` context | Code quality | P3 — Low | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-PRM-009 | FRD §1.3 | Global Reference Data Management — education boards |
| BR-PRM-023 | FRD §1.4 | Activity log for all state-changing actions |
| US-PRM-009 | FRD §8.1 | User story for reference data management |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
