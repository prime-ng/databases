# SessionBoardSetup — Test-Case List & Requirements (glb_)

- **Module / Area:** GlobalMaster (served by Prime — CENTRAL / prime-side)
- **Screen:** Session & Board Setup — **READ-ONLY COMPOSITE** (two lists in tabs)
- **Live path:** `/prime/session-board-setup` (host `http://127.0.0.1:8000`)
- **Route name:** `central.prime.session-board-setup.index`
- **Controller (LIVE):** `Modules\Prime\Http\Controllers\SessionBoardSetupController::index`
- **View (LIVE):** `prime::session-board-setup.index`
- **Prefix:** `glb_` (both backing tables are glb_)
- **Primary tables (read-only):** `glb_academic_sessions`, `glb_boards` — the screen owns **no table**.
- **Models:** `Modules\Prime\Models\AcademicSession`, `Modules\GlobalMaster\Models\Board`
- **Test file (single):** `glb_SessionBoardSetup_TestCas.php` (26 methods)

> **Scope note (LIGHTER read-focused set).** This is a composite of two lists. No create/edit/delete/restore matrix is generated — the resource's write methods are non-functional stubs (DEV-GLB-S01). Coverage centres on: schema/model truth, business-rule documentation, negative/auth, permission/tab visibility, and read UI (render, search, status filter, pagination, empty state).

---

## 1. Backing-data truth (glb_academic_sessions)

| Column | Type | Notes |
| --- | --- | --- |
| id | INT unsigned PK | auto-increment |
| short_name | varchar(20) | **UNIQUE** (`uq_glb_acadSessions_shortName`) |
| name | varchar(50) | |
| start_date | date | business rule: `start_date < end_date` |
| end_date | date | |
| is_current | tinyint(1) | default 1 — the session status concept |
| current_flag | tinyint(1) GENERATED STORED | NULL unless `is_current=1`; **UNIQUE** (`uq_glb_acadSession_currentFlag`) ⇒ at most ONE current session |
| deleted_at / created_at / updated_at | timestamp | SoftDeletes |

**AcademicSession model:** connection `global_master_mysql`, SoftDeletes, fillable `[short_name,name,start_date,end_date,is_current]`, casts (start_date/end_date=date, is_current=boolean), `scopeCurrent`.

## 2. Backing-data truth (glb_boards)

| Column | Type | Notes |
| --- | --- | --- |
| id | INT unsigned PK | auto-increment |
| name | varchar(255) | **UNIQUE** (`uq_glb_academicBoard_name`) |
| short_name | varchar(20) | **UNIQUE** (`uq_glb_academicBoard_shortName`) |
| is_active | tinyint(1) | default 1 — board status |
| created_at / updated_at / deleted_at | timestamp | SoftDeletes |

**Board model:** connection `global_master_mysql`, SoftDeletes, fillable `[name,short_name,is_active]`, casts (is_active=boolean), `belongsToMany(Organization, 'sch_board_organization_jnt')`.

---

## 3. Controller `index()` behaviour (LIVE Prime)

- Gate: `prime.session-board-setup.viewAny`.
- **Academic Sessions:** optional `search` over `name`/`short_name` (LIKE); optional `status` in `{0,1}` filtered on `is_active`; `orderByDesc(start_date)`; `paginate(10, ['*'], 'academicsession_page')` → `fragment('academicsession')`.
- **Boards:** same `search`; `status` in `{0,1}` on `is_active`; `orderBy(name)`; `paginate(4, ['*'], 'academicboard_page')` → `fragment('academicboard')`.
- Tabs (view): `academicsession` (label "Academic Session", gated `prime.academic-session.viewAny`), `academicboard` (label "Academic Board", gated `prime.board.viewAny`).
- Empty states: **"No Academic Session Data Found"** / **"No Board Data Found"**.
- Breadcrumb title: **"Session & Board Setup"**.

---

## 4. Test-case list (26 methods, semantic bands)

### Band 01–09 — Schema / model configuration truth
| # | Method | Assertion | Source |
| --- | --- | --- | --- |
| 01 | `..._01_academic_sessions_table_and_columns_exist` | table + columns present | DDL glb_academic_sessions |
| 02 | `..._02_boards_table_and_columns_exist` | table + columns present | DDL glb_boards |
| 03 | `..._03_academic_session_model_configuration_is_correct` | getTable/connection/fillable/SoftDeletes/scopeCurrent/casts | AcademicSession model |
| 04 | `..._04_board_model_configuration_is_correct` | getTable/connection/fillable/SoftDeletes/casts | Board model |
| 05 | `..._05_academic_sessions_current_flag_column_present` | generated current_flag + UNIQUE index | DDL |
| 06 | `..._06_boards_unique_name_and_short_name` | UNIQUE(name), UNIQUE(short_name) | DDL |
| 07 | `..._07_screen_has_no_own_table` | no dedicated table (composite) | reconciliation |

### Band 10–19 — Business rules (documented; read-only screen)
| # | Method | Assertion | Source |
| --- | --- | --- | --- |
| 10 | `..._10_single_current_session_rule_documented` | ≤1 current session (current_flag UNIQUE) | DDL + scopeCurrent |
| 11 | `..._11_session_start_before_end_rule_documented` | every row start_date<end_date (trigger, not DB) | DDL comment |
| 12 | `..._12_board_is_active_is_boolean` | is_active cast boolean | Board casts |
| 13 | `..._13_academic_sessions_missing_is_active_column_defect` | **DEV-GLB-S03** is_active absent; is_current present | DDL + controller |
| 14 | `..._14_dual_controller_reconciliation_documented` | **DEV-GLB-S02** two divergent controllers | reconciliation |

### Band 30–39 — Negative / auth
| # | Method | Assertion | Source |
| --- | --- | --- | --- |
| 30 | `..._30_guest_redirected_to_login` | guest → /login | auth middleware |
| 31 | `..._31_user_without_viewany_receives_403` | denied (403/401/302) via getJson | Gate::authorize |

### Band 50–59 — Permission / visibility
| # | Method | Assertion | Source |
| --- | --- | --- | --- |
| 50 | `..._50_admin_sees_both_tabs` | "Academic Session" + "Academic Board" | view nav-tab |
| 51 | `..._51_tab_panes_present` | #academicsession-pane / #academicboard-pane | view |

### Band 60–69 — UI / render / filter / pagination
| # | Method | Assertion | Source |
| --- | --- | --- | --- |
| 60 | `..._60_index_renders_at_prime_path` | renders at /prime/session-board-setup | HARD RULE 13 |
| 61 | `..._61_index_shows_screen_title` | "Session & Board Setup" | view breadcrum |
| 62 | `..._62_index_renders_both_lists` | both tables present | view |
| 63 | `..._63_search_and_status_filter_present` | search input + status select (0/1) | view search-bar |
| 64 | `..._64_search_filters_sessions_list` | `?search=` narrows sessions | controller search |
| 65 | `..._65_sessions_page_size_is_ten` | ≤10 rows on page 1 | paginate(10) |
| 66 | `..._66_boards_page_size_is_four` | ≤4 rows on page 1 | paginate(4) |
| 67 | `..._67_distinct_pagination_param_names` | `academicsession_page` link | page-name/fragment |
| 68 | `..._68_empty_state_messages_documented` | empty-state strings | view @empty |
| 69 | `..._69_resource_is_read_only_no_crud` | **DEV-GLB-S01** write methods are stubs | controller |

---

## 5. Documented defects / reconciliation (see Gap Analysis)
- **DEV-GLB-S01** — resource write methods are non-functional stubs → screen is READ-ONLY (no CRUD to test).
- **DEV-GLB-S02** — two SessionBoardSetupControllers (Prime live vs GlobalMaster dead), divergent gates/views/paginate sizes.
- **DEV-GLB-S03** — controller/view reference `is_active` on `glb_academic_sessions`, which has no such column (only `is_current`). Session status filter is defective.
