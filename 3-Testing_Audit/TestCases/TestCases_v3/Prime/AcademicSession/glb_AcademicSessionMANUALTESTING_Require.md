# Academic Session — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — **CENTRAL** database scope |
| Feature / Screen | AcademicSession |
| URL | `http://127.0.0.1:8000/prime/academic-session` |
| Trash URL | `http://127.0.0.1:8000/prime/academic-session/trash/view` |
| Controller | `Modules\Prime\Http\Controllers\AcademicSessionController` |
| FormRequest | `Modules\Prime\Http\Requests\AcademicSessionRequest` |
| Model | `Modules\Prime\Models\AcademicSession` (connection `global_master_mysql`) |
| Primary table | `glb_academic_sessions` (DB `global_master`) |
| Route name prefix | `central.prime.academic-session.*` |
| Validation | name (req, ≤50, unique), short_name (req, ≤10, unique), is_current (bool). **No date rules** |
| CRUD type | Full CRUD + soft delete + restore + force delete + toggleStatus |
| Soft delete | Yes (`deleted_at`) |
| Pagination | 10 / page |
| Activity log | `sys_central_activity_logs` (central) — events Stored/Updated/Trashed/Restored/Deleted/Toggled |
| Auth | `auth` + `verified`; gates `prime.academic-session.*`; super-admin bypass via `Gate::before` |

### Environment prerequisites (must be true before running)
1. **`Prime` module enabled** in `prime_testing/modules_statuses.json` (currently `false` → all `/prime/*` routes 404).
2. Central app served at `http://127.0.0.1:8000` (`APP_ENV=testing` for CSRF bypass).
3. `global_master` DB reachable via the `global_master_mysql` connection and containing `glb_academic_sessions`.
4. A super-admin user (`is_super_admin=1 & super_admin_flag=1`) or `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD` valid.

---

## 2. Business Conditions (detailed)

### Validation & messages
- **name**: required, string, `max:50`, `unique(glb_academic_sessions)` (ignores own id on edit). No DB unique backstop.
- **short_name**: required, string, `max:10`, `unique(glb_academic_sessions)` (DDL is varchar(20), UNIQUE).
- **is_current**: nullable boolean; checkbox coerced to boolean in `prepareForValidation`.
- **start_date / end_date**: form marks them `required`, but the FormRequest defines **NO rule**, and the controller persists `$request->validated()` → the dates are dropped (BUG-PRM-012).

### Success toast text (from `config/flash.php`)
| Action | Rendered toast |
|--------|----------------|
| store | `Academic Session was created successfully.` |
| update | `Academic-session was updated successfully.` ← hyphen/case defect (BUG-PRM-014) |
| destroy | `Academic Session was moved to trash.` |
| restore | `Academic Session was restored successfully.` |
| forceDelete | `Academic Session was permanently deleted.` |
| toggleStatus ok | `Academic Session status was successfully changed.` |
| toggleStatus fail | `Failed to change the status of Academic Session.` |
| destroy active | `Cannot move active session to Trash` (unreachable — guard reads missing `is_active`) |

### One-current-session rule (BR-PRM-021)
- The DDL generates `current_flag = CASE WHEN is_current=1 THEN 1 ELSE NULL END` and puts a **UNIQUE** key on it → at most one row can have `is_current=1`.
- The application does **not** unset other rows' `is_current`, so a second `is_current=1` insert/update raises a **QueryException** (unique violation) rather than switching current. `toggleStatus`'s intended app enforcement writes the nonexistent `is_active` column (BUG-PRM-013), so it never works.

---

## 3. Manual Test Cases

### MTC-01 — Create academic session (happy path)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super-admin; visit `/prime/academic-session/create` | Form with Name, Short Name, Start Date, End Date, Is Current |
| 2 | Fill valid unique Name (≤50), Short Name (≤10), Start/End dates | — |
| 3 | Submit | Redirect to `session-board-setup#academicsession`; toast `Academic Session was created successfully.` |
| 4 | DB check | `SELECT * FROM glb_academic_sessions WHERE name=?` → row present |
| 5 | ⚠ Defect check (BUG-PRM-012) | `start_date`/`end_date` likely NULL/omitted; on strict MySQL the insert fails with "Field 'start_date' doesn't have a default value" |
| 6 | Activity check | `SELECT * FROM sys_central_activity_logs WHERE subject_type LIKE '%AcademicSession' AND event='Stored'` → 1 row |

### MTC-02 — Required-field validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit create with empty Name | Redirect back; error "The name field is required." |
| 2 | Submit with empty Short Name | Error on short_name |
| 3 | Submit Name > 50 chars | max:50 error |
| 4 | Submit Short Name > 10 chars | max:10 error |
| 5 | Submit duplicate Short Name | unique error on short_name |

### MTC-03 — Update session
| Step | Action | Expected |
|------|--------|----------|
| 1 | Edit an existing session, change Name | — |
| 2 | Submit | Toast `Academic-session was updated successfully.` (note hyphen defect) |
| 3 | DB check | name updated |
| 4 | Activity check | event `Updated` row present with `changes` payload |

### MTC-04 — Toggle status (BUG-PRM-013)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/prime/academic-session/{id}/toggle-status` with `is_active=1` | ⚠ 500 — `save()` writes nonexistent `is_active` column (SQL "Unknown column 'is_active'") |
| 2 | Root-cause | `glb_academic_sessions` has `is_current` + generated `current_flag`, **no `is_active`** |
| 3 | Expected (correct) behaviour | endpoint should operate on `is_current` and switch the single current session |

### MTC-05 — Soft delete / trash / restore / force delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a session from the index | Row moved to trash; toast `moved to trash`; `deleted_at` set |
| 2 | ⚠ Guard defect (BUG-PRM-013) | destroy checks `$session->is_active !== true` (always true, column missing) → the "Cannot move active session to Trash" branch is dead; ANY session is deletable |
| 3 | Visit trash view | Soft-deleted rows listed |
| 4 | Restore | `deleted_at` cleared; event `Restored` |
| 5 | Force delete | Row removed permanently; event `Deleted` |

### MTC-06 — One current session (BR-PRM-021)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create session A with Is Current on | A becomes current |
| 2 | Create session B with Is Current on | ⚠ QueryException — unique(current_flag) blocks a second current row (ungraceful; app does not switch) |
| 3 | `SELECT COUNT(*) FROM glb_academic_sessions WHERE is_current=1 AND deleted_at IS NULL` | ≤ 1 |

### MTC-07 — Permissions & guest
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit index while logged out | Redirect to `/login` |
| 2 | Controller gates | `prime.academic-session.{viewAny,create,view,update,delete,restore,forceDelete}` verbatim |
| 3 | ⚠ Policy defect (BUG-PRM-011) | `AcademicSessionPolicy` mapped to the model is never reached — authZ goes through the string abilities; `SessionBoardSetupPolicy` is an orphan |

### MTC-08 — Security
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a session with Name `<script>alert(1)</script>` | Stored; on show/index the raw `<script>` is escaped (Blade `{{ }}`) |
| 2 | Visit `/prime/academic-session/99999999` | 404 (findOrFail) |
