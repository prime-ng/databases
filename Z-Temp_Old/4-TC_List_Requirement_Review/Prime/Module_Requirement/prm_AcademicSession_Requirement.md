# Prime — Academic Session Management

**Feature:** Academic Session Management | **REQ-ID:** REQ-PRM-009 | **Priority:** P0 (MUST)

---

## 1. Description

The Academic Session Management feature enables Platform IT/Ops and Super Admins to create and manage global academic sessions that serve as the authoritative school-year reference for the entire platform. An academic session defines the start and end dates of a school year (e.g., April 2025 to March 2026). Exactly one session can be marked as "current" at any time, and this session gates plan assignment operations across the platform. Sessions support soft-delete, restore, force-delete, and toggle-status operations, with the constraint that the currently-active session cannot be deleted.

**Key Capabilities:**
- CRUD operations for academic sessions (name, short_name, start_date, end_date, is_current)
- Atomic "set current" — marking one session as current clears the flag from all others
- Soft-delete, trash view, restore, and force-delete
- AJAX toggle-status for the `is_current` flag (ensures only one current session)
- Validation: end_date must be after or equal to start_date; name and short_name are unique
- Activity logging for all state-changing operations

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/Prime/app/Http/Controllers/AcademicSessionController.php` | 230 | DONE |
| Model | `Modules\Prime/app/Models/AcademicSession.php` | 103 | DONE |
| Form Request | `Modules/Prime/app/Http/Requests/AcademicSessionRequest.php` | 57 | EXISTS |
| View (index) | `prime::academic-session.index` | — | EXISTS |
| View (create) | `prime::academic-session.create` | — | EXISTS |
| View (show) | `prime::academic-session.show` | — | EXISTS |
| View (edit) | `prime::academic-session.edit` | — | EXISTS |
| View (trash) | `prime::academic-session.trash` | — | EXISTS |

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/prime/academic-session` | `index` | `prime.academic-session.viewAny` | ✅ Gate check present |
| GET | `/prime/academic-session/create` | `create` | `prime.academic-session.create` | ✅ Gate check present |
| POST | `/prime/academic-session` | `store` | `prime.academic-session.create` | ✅ Gate + Form Request |
| GET | `/prime/academic-session/{academic_session}` | `show` | `prime.academic-session.view` | ✅ Gate check present |
| GET | `/prime/academic-session/{academic_session}/edit` | `edit` | `prime.academic-session.update` | ✅ Gate check present |
| PUT | `/prime/academic-session/{academic_session}` | `update` | `prime.academic-session.update` | ✅ Gate + Form Request |
| DELETE | `/prime/academic-session/{academic_session}` | `destroy` | `prime.academic-session.delete` | ✅ Gate check present |
| GET | `/prime/academic-session/trash/view` | `trashedAcademicSession` | `prime.academic-session.restore` | ✅ Gate check present |
| GET | `/prime/academic-session/{id}/restore` | `restore` | `prime.academic-session.restore` | ✅ Gate check present |
| DELETE | `/prime/academic-session/{id}/force-delete` | `forceDelete` | `prime.academic-session.forceDelete` | ✅ Gate check present |
| POST | `/prime/academic-session/{session}/toggle-status` | `toggleStatus` | `prime.academic-session.update` | ✅ Gate check present |

---

## 4. Data Model

### 4.1 Academic Session (`glb_academic_sessions` — global_master database)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `short_name` | VARCHAR(10) | ✅ | — | UNIQUE; e.g. "2025-26" |
| `name` | VARCHAR(50) | ✅ | — | Full name; e.g. "April 2025 – March 2026" |
| `start_date` | DATE | ✅ | — | Session start |
| `end_date` | DATE | ✅ | — | Session end (must be >= start_date) |
| `is_current` | TINYINT(1) | ✅ | 0 | Boolean; only one session can be current |
| `is_active` | TINYINT(1) | ✅ | 1 | — |
| `deleted_at` | TIMESTAMP | — | NULL | Soft delete |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

**Model Fillable:** short_name, name, start_date, end_date, is_current
**Model Casts:** start_date (date), end_date (date), is_current (boolean)
**Connection:** `global_master_mysql`

### 4.2 Validation Rules (AcademicSessionRequest)

| Field | Rules |
|-------|-------|
| `name` | required, string, max:50, unique:glb_academic_sessions (ignores current ID on update) |
| `short_name` | required, string, max:10, unique:glb_academic_sessions (ignores current ID on update) |
| `is_current` | nullable, boolean |
| `start_date` | required, date |
| `end_date` | required, date, after_or_equal:start_date |

---

## 5. Controller Implementation Details

### 5.1 `index()`

- **Gate:** `Gate::authorize('prime.academic-session.viewAny')`
- **Query:** `AcademicSession::paginate(10)`
- **View:** `prime::academic-session.index` with `compact('academicSessions')`

### 5.2 `create()`

- **Gate:** `Gate::authorize('prime.academic-session.create')`
- **View:** `prime::academic-session.create`

### 5.3 `store(AcademicSessionRequest $request)`

- **Gate:** `Gate::authorize('prime.academic-session.create')`
- **Current Session Logic:** If `$request->boolean('is_current')` is true, clears `is_current` from all other sessions before creating
- **Create:** `AcademicSession::create($request->validated())`
- **Audit:** `activityLog($academicSession, 'Stored', ...)`
- **Redirect:** `central.prime.session-board-setup.index#academicsession`

### 5.4 `show(AcademicSession $academicSession)`

- **Gate:** `Gate::authorize('prime.academic-session.view')`
- **View:** `prime::academic-session.show` with `compact('academicSession')`

### 5.5 `edit(string $id)`

- **Gate:** `Gate::authorize('prime.academic-session.update')`
- **Query:** `AcademicSession::findOrFail($id)`
- **View:** `prime::academic-session.edit` with `compact('academicSession')`

### 5.6 `update(AcademicSessionRequest $request, AcademicSession $academicSession)`

- **Gate:** `Gate::authorize('prime.academic-session.update')`
- **Current Session Logic:** If setting `is_current` to true and session was not already current, clears `is_current` from all other sessions (except this one)
- **Update:** `$academicSession->update($request->validated())`
- **Audit:** Captures changed attributes with old/new values; calls `activityLog()` only when changes exist
- **Redirect:** `central.prime.session-board-setup.index#academicsession`

### 5.7 `destroy(string $id)`

- **Gate:** `Gate::authorize('prime.academic-session.delete')`
- **Protection:** If `$academicSession->is_current` is true, redirects with error: "Cannot move active session to Trash"
- **Soft Delete:** Calls `$academicSession->delete()`
- **Audit:** `activityLog($academicSession, 'Trashed', ...)`
- **Redirect:** `central.prime.session-board-setup.index#academicsession`

### 5.8 `trashedAcademicSession()`

- **Gate:** `Gate::authorize('prime.academic-session.restore')`
- **Query:** `AcademicSession::onlyTrashed()->paginate(10)`
- **View:** `prime::academic-session.trash` with `compact('academicSessions')`

### 5.9 `restore($id)`

- **Gate:** `Gate::authorize('prime.academic-session.restore')`
- **Query:** `AcademicSession::withTrashed()->findOrFail($id)`
- **Logic:** Calls `$academicSession->restore()`
- **Audit:** `activityLog($academicSession, 'Restored', ...)`
- **Redirect:** `central.prime.academic-session.trashed`

### 5.10 `forceDelete($id)`

- **Gate:** `Gate::authorize('prime.academic-session.forceDelete')`
- **Query:** `AcademicSession::withTrashed()->findOrFail($id)`
- **Logic:** Calls `$academicSession->forceDelete()`
- **Audit:** `activityLog($academicSession, 'Deleted', ...)`
- **Redirect:** `central.prime.academic-session.trashed`

### 5.11 `toggleStatus(Request $request, AcademicSession $academicSession)` — JSON

- **Gate:** `Gate::authorize('prime.academic-session.update')`
- **Validation:** `is_current` required, boolean
- **Atomic Current-Flag Logic:** If enabling `is_current`, clears the flag from ALL other sessions (excluding this one)
- **Save:** Sets `$academicSession->is_current = $newStatus`, calls `$academicSession->save()`
- **Audit:** `activityLog($academicSession, 'Toggled', ...)`
- **Response:** JSON `{ success, is_current, message }` — success/error depends on `save()` return value

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:-----------:|
| BR-PRM-003 | Active academic session must exist before plan assignment | ✅ Session entity has `is_current` flag; checked in plan assignment flow |
| BR-PRM-021 | Exactly one academic session may be current at any time | ✅ Atomic clear-others logic in `store()`, `update()`, and `toggleStatus()` |
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
| Gate check on `restore` | ✅ `trashedAcademicSession()`, `restore()` |
| Gate check on `forceDelete` | ✅ `forceDelete()` |
| Form Request validation | ✅ `AcademicSessionRequest` with rules + authorization |
| Current session protected from delete | ✅ Destroy blocked with error message |
| Atomic current-flag toggle | ✅ Toggle clears others in the same transaction-like update |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | The `toggleStatus()` is_current logic does not use a database transaction — if the clear-others update succeeds but the save() on the target session fails, multiple sessions could incorrectly have is_current=false | Data integrity | P1 — Medium | ⬜ |
| 2 | `store()` and `update()` do not wrap the is_current clear + create/update in a DB transaction | Concurrency risk | P2 — Low | ⬜ |
| 3 | `deleted_at` column exists (SoftDeletes) but `is_active` column is absent from the AcademicSession model's `$fillable` — the model does not manage is_active directly | DDL gap | P2 — Low | ⬜ |
| 4 | No feature tests exist for AcademicSessionController | Testing gap | P1 — High | ⬜ |
| 5 | The AcademicSession model's `boards()` relation uses `belongsToMany(Board::class)` without specifying a pivot table — likely expects a pivot table `academic_session_board` or similar | Data integrity | P2 — Low | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-PRM-009 | FRD §1.3 | Global Reference Data Management — academic sessions |
| BR-PRM-003 | FRD §1.4 | Active session required for plan assignment |
| BR-PRM-021 | FRD §1.4 | Exactly one current academic session |
| US-PRM-009 | FRD §8.1 | User story for reference data management |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
