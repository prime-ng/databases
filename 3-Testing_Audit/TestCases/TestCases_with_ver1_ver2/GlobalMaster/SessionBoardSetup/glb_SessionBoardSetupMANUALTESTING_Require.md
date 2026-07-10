# glb_SessionBoardSetup — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | GlobalMaster (CENTRAL / prime-side) |
| Feature / Screen | Session & Board Setup (composite, read-only hub) |
| URL (module route) | `GET /global-master/session-board-setup` (name `global-master.session-board-setup.index`) |
| Host | `http://127.0.0.1:8000` (central; NOT `test.localhost`) |
| Controller (feature) | `Modules\GlobalMaster\Http\Controllers\SessionBoardSetupController` |
| Colliding twin | `Modules\Prime\Http\Controllers\SessionBoardSetupController` (root web.php, central group) — BUG-GLB-005 |
| Models | `Modules\Prime\Models\AcademicSession` (glb_academic_sessions), `Modules\GlobalMaster\Models\Board` (glb_boards) |
| DB connection | `global_master_mysql` (single `global_master` DB) |
| Validation | None (no FormRequest — write surface is non-functional) |
| Migrations | `*_create_academic_sessions_table.php`, `*_create_boards_table.php` (Modules/GlobalMaster/database/migrations) |
| CRUD Type | **Read-only hub** — store/update/destroy empty stubs; create/show/edit views missing |
| Soft Delete | Yes on both models (`SoftDeletes`) |
| Pagination | 10 per list (both tabs) |
| Activity Log | None (no mutations occur) |
| Permissions | `prime.board.viewAny` (index gate), `prime.academic-session.viewAny` (session tab), board/session view/update/delete on actions |

> **Environment prerequisites (see Validation Report §E):** GlobalMaster **and** Prime must be `true` in `prime_testing/modules_statuses.json` (both currently `false` → 404 on all routes); `APP_ENV=testing`; Chrome/Dusk driver running against `127.0.0.1:8000`.

---

## 2. Business Conditions (detailed)

### BC-AUTH-01 — index authorization
`index()` executes `Gate::any(['prime.board.viewAny']) || abort(403)`. A user lacking `prime.board.viewAny` receives HTTP 403. Note the asymmetry: the **index gate** keys on the *board* permission, but the session tab body is separately gated on `prime.academic-session.viewAny` — a user with board-view but not session-view sees the board tab only.

### BC-BIZ-01 — hub data load
```
index():
  Gate::any(['prime.board.viewAny']) || abort(403)
  $academicSessions = AcademicSession::paginate(10)   // Prime model, glb_academic_sessions
  $boards           = Board::paginate(10)             // GlobalMaster model, glb_boards
  return view('globalmaster::session-board-setup.index', compact('academicSessions','boards'))
```

### DATA-GLB-002 — phantom `is_active` on sessions (flow)
```
DDL glb_academic_sessions:  (no is_active column) → is_current + generated current_flag
view index.blade.php:47:    <tr class="... {{ $session->is_active ? 'table-primary' : '' }}">
Eloquent:                   $session->is_active → attribute absent → null → falsy
Result:                     row-highlight class NEVER applied (silent, no error)
```

### BUG-GLB-006 — broken write surface (flow)
```
create()  → view('globalmaster::create')  → file absent → ViewException (500)
show($id) → view('globalmaster::show')     → file absent → 500
edit($id) → view('globalmaster::edit')     → file absent → 500
store()   → {}                             → returns null → HTTP 200 empty body, nothing persisted
update()  → {}                             → no-op
destroy() → {}                             → no-op
```

---

## 3. Test Cases (step-by-step)

### TC-P01 — Both hub tables exist (schema)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On `global_master` DB: `SHOW TABLES LIKE 'glb_academic_sessions'` | Row returned |
| 2 | `SHOW COLUMNS FROM glb_academic_sessions` | Includes id, short_name, name, start_date, end_date, is_current, current_flag, deleted_at, created_at, updated_at |
| 3 | `SHOW TABLES LIKE 'glb_boards'` | Row returned |
| 4 | `SHOW COLUMNS FROM glb_boards` | Includes id, name, short_name, is_active, created_at, updated_at, deleted_at |

### TC-P02 — Unique keys present
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW INDEX FROM glb_academic_sessions` | Keys `uq_glb_acadSessions_shortName`, `uq_glb_acadSession_currentFlag` present |
| 2 | `SHOW INDEX FROM glb_boards` | Keys `uq_glb_academicBoard_name`, `uq_glb_academicBoard_shortName` present |

### TC-P04 / TC-P05 — Hub renders lists
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as super-admin at `http://127.0.0.1:8000/login` | Dashboard |
| 2 | Visit `/global-master/session-board-setup` | Page renders (not /login), heading "Session & Board Setup" |
| 3 | Observe the two tabs | "Academic Session" and "Academic Board" tabs present |
| 4 | Seed ≥ 1 session + ≥ 1 board | `SELECT COUNT(*) FROM glb_academic_sessions` ≥ 1; board row visible in Academic Board tab |
| 5 | Observe pagination | `->links()` pager rendered when > 10 rows |

### TC-P07 — Empty state
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure `glb_academic_sessions` empty (or soft-deleted) | 0 active rows |
| 2 | Visit hub, Academic Session tab | Row shows literal text `Not Data Found` (verbatim, grammar preserved) |

### TC-N01 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log out / clear session | Unauthenticated |
| 2 | Visit `/global-master/session-board-setup` | Redirect to `/login` |

### TC-N02 — index gate
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as a user WITHOUT `prime.board.viewAny` | Authenticated, limited |
| 2 | Visit the hub | HTTP 403 (Gate::any fails → abort(403)) |

### TC-N06 — Reflected search escaping
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/global-master/session-board-setup?search=<script>alert(1)</script>` | Page renders |
| 2 | View page source | No raw `<script>alert(1)</script>`; payload HTML-escaped |

### TC-D01 — Write stubs are no-ops (BUG-GLB-006)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `POST /global-master/session-board-setup` (store) with any body | No redirect, no DB write; `SELECT COUNT(*) FROM glb_boards` unchanged |
| 2 | Inspect controller source | `store()/update()/destroy()` are empty `{}` |

### TC-D02 — Missing create/show/edit views (BUG-GLB-006)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `GET /global-master/session-board-setup/create` | HTTP 500 (view `globalmaster::create` not found) |
| 2 | Confirm on disk | `Modules/GlobalMaster/resources/views/{create,show,edit}.blade.php` absent |

### TC-D03 — BUG-GLB-001 reconciliation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `grep -r "class AcademicSession" Modules/` | Only `Modules/Prime/app/Models/AcademicSession.php` |
| 2 | Inspect GM controller import | `use Modules\Prime\Models\AcademicSession;` (existing class) |
| 3 | Conclusion | Audit-predicted 500 does NOT reproduce; `Modules\GlobalMaster\Models\AcademicSession` absent but unreferenced |

### TC-D04 — DATA-GLB-002 phantom is_active
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW COLUMNS FROM glb_academic_sessions LIKE 'is_active'` | Empty (no such column) |
| 2 | Inspect view line 47 | Reads `$session->is_active` → resolves null → highlight class never applies |

### TC-D05 — BUG-GLB-003 single-current invariant
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `current_flag` | Generated STORED tinyint, UNIQUE `uq_glb_acadSession_currentFlag` |
| 2 | Attempt to insert a 2nd row with is_current=1 (raw) | DB rejects (duplicate current_flag) — invariant enforced only by DB, not app |
| 3 | Inspect `store()` | Empty stub, sets no is_current |

### TC-D06 — BUG-GLB-004 route-name mismatch
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect index.blade.php action/search components | Mixed `central.global-master.*` and `global-master.*` route names |
| 2 | `php artisan route:list \| grep session-board` (GlobalMaster enabled) | GM route registered as `global-master.*`; `central.global-master.academic-session.*` NOT registered |

### TC-D07 — BUG-GLB-005 dual controller collision
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect both controllers | GM gate `prime.board.viewAny`; Prime gate `Gate::authorize('prime.session-board-setup.viewAny')` |
| 2 | Inspect route files | GM registers at `/global-master/session-board-setup`; Prime registers `session-board-setup` under central group |
| 3 | Conclusion | Two distinct handlers share the `session-board-setup` segment — divergent behaviour/gates |

### TC-D08 — Cross-tenant isolation (N/A)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm both models use `global_master_mysql` | Single central DB; no per-tenant copy |
| 2 | Conclusion | Cross-tenant invisibility / IDOR-across-tenant not applicable — test skipped with documented note |
