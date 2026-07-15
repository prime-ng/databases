# glb_SessionBoardSetup — Manual Testing Spec

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — CENTRAL |
| Feature | SessionBoardSetup ("Session & Board Setup") composite screen |
| URL | `http://127.0.0.1:8000/prime/session-board-setup` |
| Route names | `central.prime.session-board-setup.{index,create,store,show,edit,update,destroy}` |
| Controller | `Modules\Prime\Http\Controllers\SessionBoardSetupController` |
| Models | `Modules\Prime\Models\AcademicSession` (`glb_academic_sessions`), `Modules\GlobalMaster\Models\Board` (`glb_boards`) — conn `global_master_mysql` |
| Validation | None (no FormRequest; write endpoints are stubs) |
| Migrations | Tables from `_global_db_v4.sql` (global_master). No pivot migration. |
| CRUD Type | **Read-only composite** (index functional; create/store/show/edit/update/destroy stubbed) |
| Soft Delete | Yes on both models |
| Pagination | Sessions 10/page (`academicsession_page`); Boards 4/page (`academicboard_page`) |
| Activity Log | **None** (controller emits no activityLog). Central sink would be `sys_central_activity_logs`. |
| Permissions | Controller: `prime.session-board-setup.*`. View tabs: `prime.academic-session.*`, `prime.board.*` (divergent — BUG-PRM-012) |

**Prerequisites:** Prime module enabled in `prime_testing/modules_statuses.json`; `APP_ENV=testing`; server on `127.0.0.1:8000`; admin `root@tenant.com` / `password`.

## 2. Business Conditions (detailed)
- **BC-DB-03 (defect root):** `glb_academic_sessions` has `is_current`/`current_flag` but **no `is_active`**. The controller's Academic-Session status filter (`where('is_active', ...)`) therefore errors → `SQLSTATE[42S22] Unknown column 'is_active'`. Since the session query paginates first, the whole page 500s when `?status=0` or `?status=1` is supplied.
- **BC-DB-05 / BC-INT (defect):** `AcademicSession::boards()` = `belongsToMany(Board::class)` → default pivot `academic_session_board`, which has no DDL/migration. The screen never persists a session↔board link; the two tabs are independent lists.
- **BC-AUTH-04/05 (defect):** `PrimeServiceProvider::boot()` binds `Gate::policy(AcademicSession::class, GlobalMaster\AcademicSessionPolicy::class)`. `SessionBoardSetupPolicy` is never registered → dead code. The controller enforces `prime.session-board-setup.*` as raw string gates via Spatie permission lookup.
- **Activity flow:** none. No create/update/delete side-effects; nothing written to any activity sink.

## 3. Test Cases (step-by-step)

### TC-P10 — Index renders both tabs
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; visit `/prime/session-board-setup` | HTTP 200, breadcrumb "Session & Board Setup" |
| 2 | Inspect DOM | `#academicsession-pane` and `#academicboard-pane` present |
| 3 | DB check | `SELECT COUNT(*) FROM glb_academic_sessions` ≥ rendered rows |

### TC-N30 — Academic-Session status filter (BUG-PRM-013)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/prime/session-board-setup?status=1&tab=academicsession` | Page 500s |
| 2 | Server log | `Unknown column 'is_active'` on `glb_academic_sessions` |
| 3 | DB check | `SHOW COLUMNS FROM glb_academic_sessions LIKE 'is_active'` → 0 rows |

### TC-N33/34/35 — Write endpoints no-op (BUG-PRM-015)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `POST /prime/session-board-setup` (authorized) | 200, empty body; no row created |
| 2 | DB check | `SELECT COUNT(*)` on both tables unchanged |
| 3 | Activity check | `SELECT COUNT(*) FROM sys_central_activity_logs WHERE subject_type LIKE '%AcademicSession%'` unchanged |

### TC-N36 — create/show/edit missing views (BUG-PRM-015)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `GET /prime/session-board-setup/create` | 500 — `View [prime::create] not found` |
| 2 | `GET /prime/session-board-setup/{id}` and `/{id}/edit` | 500 — `prime::show` / `prime::edit` not found |

### TC-D40 — Pairing pivot absent (BUG-PRM-014)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW TABLES LIKE 'academic_session_board'` | 0 rows |
| 2 | Eloquent `$session->boards` | QueryException — base table not found |

### TC-D43 — Single current session
| Step | Action | Expected |
|------|--------|----------|
| 1 | Insert session A `is_current=1` | OK |
| 2 | Insert session B `is_current=1` | Unique violation on `current_flag` |

### TC-S51/52 — Policy binding (BUG-PRM-011)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `Gate::getPolicyFor(AcademicSession::class)` | Instance of `GlobalMaster\AcademicSessionPolicy` |
| 2 | Grep `PrimeServiceProvider` for `SessionBoardSetupPolicy` | Not found (dead) |

### TC-S53 — Permission surface divergence (BUG-PRM-012)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read controller | Gates `prime.session-board-setup.viewAny` |
| 2 | Read view | `@can('prime.academic-session.viewAny')` / `@can('prime.board.viewAny')` |
| 3 | Conclusion | A user with only session-board-setup.viewAny sees empty tabs |

### TC-N71 — Reflected search escaped
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `?search=<script>alert(1)</script>` | No live `<script>` node; value HTML-escaped in input |
