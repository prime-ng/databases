# glb_SessionBoardSetup — Test Case List & Business Conditions

**Module:** GlobalMaster (CENTRAL / prime-side)
**Feature / Screen:** Session & Board Setup (composite, read-only hub)
**Prefix:** `glb_` (DDL `glb_academic_sessions`, `glb_boards`; `_global_db_v4.sql`)
**Primary route (module):** `global-master.session-board-setup.index` → `GET /global-master/session-board-setup`
**Controller (feature):** `Modules\GlobalMaster\Http\Controllers\SessionBoardSetupController`
**Models:** `Modules\Prime\Models\AcademicSession` (glb_academic_sessions), `Modules\GlobalMaster\Models\Board` (glb_boards)
**DB scope:** CENTRAL — connection `global_master_mysql` (single `global_master` DB, NO tenant init)
**Test style:** browser Dusk CENTRAL — extends `PrimeDuskTestCase` (physical `prm_PrimeDuskTestCase_TestCas`), host forced `http://127.0.0.1:8000`
**Screen type:** composite / read-focused / **partly broken** — no CRUD matrix (store/update/destroy are empty stubs; create/show/edit views missing)

> This is a hub screen: it renders two read-only tabs (Academic Session, Academic Board), each a paginated list. There is intentionally **no create/edit/delete flow** to test — the write surface is non-functional (documented as defects). Coverage concentrates on schema truth, model/route/permission config, render, empty state, and the defect set.

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-glb_academic_sessions`, `DDL-glb_boards`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `glb_academic_sessions` has columns id, short_name(20), name(50), start_date, end_date, is_current(tinyint,def 1), current_flag(generated stored), deleted_at, timestamps | DDL-glb_academic_sessions |
| BC-DB-02 | `glb_academic_sessions` UNIQUE `uq_glb_acadSessions_shortName`(short_name) | DDL-glb_academic_sessions |
| BC-DB-03 | `glb_academic_sessions` UNIQUE `uq_glb_acadSession_currentFlag`(current_flag) — DB-enforced single-current invariant | DDL-glb_academic_sessions |
| BC-DB-04 | `glb_academic_sessions` has **NO** `is_active` column | DDL-glb_academic_sessions |
| BC-DB-05 | `glb_boards` has columns id, name(255), short_name(20), is_active(tinyint,def 1), timestamps, deleted_at | DDL-glb_boards |
| BC-DB-06 | `glb_boards` UNIQUE `uq_glb_academicBoard_name`(name) + `uq_glb_academicBoard_shortName`(short_name) | DDL-glb_boards |
| BC-DB-07 | Both models bind connection `global_master_mysql`; both use SoftDeletes | Board.php, AcademicSession.php |

### BC-BIZ — Business behaviour (Source: Controller / view)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `index()` loads `AcademicSession::paginate(10)` + `Board::paginate(10)`, returns `globalmaster::session-board-setup.index` | GM SessionBoardSetupController::index |
| BC-BIZ-02 | Hub renders two tabs via `x-backend.tab.nav-tab`: `academicsession`, `academicboard` | index.blade.php:8-11 |
| BC-BIZ-03 | Empty list renders literal `Not Data Found` (verbatim, note grammar) | index.blade.php:69,139 |
| BC-BIZ-04 | Each list renders `->links()` pagination | index.blade.php:76,146 |
| BC-BIZ-05 | Read-only: no create/edit/delete flow reachable from the hub view | index.blade.php |

### BC-AUTH — Authorization (Source: Controller gate / view @can / Policies)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` requires `Gate::any(['prime.board.viewAny']) \|\| abort(403)` | GM controller:18-20 |
| BC-AUTH-02 | Session tab body gated `@can('prime.academic-session.viewAny')` | index.blade.php:14 |
| BC-AUTH-03 | Board tab body gated `@can('prime.board.viewAny')` | index.blade.php:84 |
| BC-AUTH-04 | Guest (unauthenticated) is redirected to `/login` (auth+verified middleware) | GlobalMaster routes/web.php:10 |
| BC-AUTH-05 | Board actions gated `prime.board.view/update/delete`; session actions `prime.academic-session.view/update/delete` | BoardPolicy, AcademicSessionPolicy, index.blade.php |

### BC-REF — Relationships / FKs (Source: models / DDL)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `Board::organizations()` belongsToMany Organization via `sch_board_organization_jnt` | Board.php:27-35 |
| BC-REF-02 | `AcademicSession::boards()` belongsToMany Board | AcademicSession.php:65-68 |
| BC-REF-03 | `board_organization` junction migration present in GlobalMaster | migrations |

### BC-EDG — Edge / defect conditions (Source: Audit + live reconciliation)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | **BUG-GLB-001 (reconciled):** live GM controller imports `Modules\Prime\Models\AcademicSession` (EXISTS) — audit-predicted 500 does NOT reproduce; `Modules\GlobalMaster\Models\AcademicSession` genuinely does not exist | Audit-BUG-GLB-001, live controller:8 |
| BC-EDG-02 | **DATA-GLB-002:** hub view reads `$session->is_active` but the column is absent → silently null; the row-highlight class never applies | index.blade.php:47, DDL |
| BC-EDG-03 | **BUG-GLB-003:** single-current invariant is DB-only (`current_flag` UNIQUE); `store()` sets nothing | DDL, GM controller:38 |
| BC-EDG-04 | **BUG-GLB-004:** view mixes route-name prefixes `central.global-master.*` and `global-master.*` — mismatched names may be unregistered | index.blade.php:18,60,91,124,130 |
| BC-EDG-05 | **BUG-GLB-005:** dual controller collision — both `Modules\GlobalMaster\...` and `Modules\Prime\...SessionBoardSetupController` bind the `session-board-setup` resource (different paths/gates) | GM & Prime controllers, root web.php:41,173 |
| BC-EDG-06 | **BUG-GLB-006:** `create()/show()/edit()` return `globalmaster::create\|show\|edit` views that do not exist → 500; `store()/update()/destroy()` are empty `{}` no-ops | GM controller:30-64, views dir |

---

## 2. Test Case List

### Positive (render / config / read)
| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Schema | BC-DB-01/05 | DDL | Both hub tables exist with all DDL columns | Tables+columns present | 01 | 01,02 | Ready |
| TC-P02 | Schema | BC-DB-02/03/06 | DDL | Unique keys present (shortName, currentFlag, board name/shortName) | Indexes present | 01 | 03,04 | Ready |
| TC-P03 | Config | BC-DB-07 | Model | Model tables/connection/SoftDeletes correct | Config matches | 03,04 | 06,07 | Ready |
| TC-P04 | Route | BC-BIZ-01 | Route | Hub route registered at `/global-master/session-board-setup` | Route present | 01 | 08 | Ready |
| TC-P05 | Biz | BC-BIZ-01 | Controller | index paginates 10 each + returns hub view | Source proven | 30* | 10,11 | Ready |
| TC-P06 | UI | BC-BIZ-02 | View | Hub renders both tabs (nav-tab) | Tabs present | 12 | 12,60 | Ready |
| TC-P07 | UI | BC-BIZ-03 | View | Empty state renders `Not Data Found` | Marker present | — | 61 | Ready |
| TC-P08 | UI | BC-BIZ-04 | View | Pagination links rendered | links() present | — | 62 | Ready |
| TC-P09 | Render | BC-AUTH-01 | Browser | Admin can open hub (body renders) | Not /login | 11 | 56 | Ready |
| TC-P10 | Config | BC-REF-01/02/03 | Model | Board/session relationships + junction migration | Present | — | 40,41,42 | Ready |

### Negative / Authorization
| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Auth | BC-AUTH-04 | Route | Guest hitting hub redirected to `/login` | Redirect | 10 | 55 | Ready |
| TC-N02 | Auth | BC-AUTH-01 | Controller | index gate = `prime.board.viewAny` + abort(403) | Source proven | 50 | 50 | Ready |
| TC-N03 | Auth | BC-AUTH-02 | View | Session tab gated `prime.academic-session.viewAny` | @can present | — | 51 | Ready |
| TC-N04 | Auth | BC-AUTH-03 | View | Board tab gated `prime.board.viewAny` | @can present | — | 52 | Ready |
| TC-N05 | Auth | BC-AUTH-05 | Policy | Board/session policy permission keys correct | Keys present | — | 53,54 | Ready |
| TC-N06 | Security | BC-BIZ-05 | Browser | Reflected `search` param is escaped (no raw `<script>`) | Escaped | — | 90 | Ready |

### Dependency / Defect (read-only hub)
| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-D01 (F) | Broken-write | BC-EDG-06 | Controller | store/update/destroy are empty `{}` no-ops | Regex proven | 30 | 30,31,32 | Ready |
| TC-D02 (F) | Broken-write | BC-EDG-06 | Views | create/show/edit views missing → 500 | Files absent | 09 | 33,34,35 | Ready |
| TC-D03 (E) | Defect | BC-EDG-01 | Recon | BUG-GLB-001 model-resolution reconciliation | Prime model exists; GM absent | 07 | 70 | Ready |
| TC-D04 (G) | Defect | BC-EDG-02 | View/DDL | DATA-GLB-002 phantom `is_active` (col absent, view reads it) | Col absent + view reads | 05 | 71,72 | Ready |
| TC-D05 (G) | Defect | BC-EDG-03 | DDL/Controller | BUG-GLB-003 single-current DB-only; store no-op | current_flag UNIQUE + stub | 06 | 73 | Ready |
| TC-D06 (E) | Defect | BC-EDG-04 | View | BUG-GLB-004 view route-name mismatch | Mixed prefixes; central name unregistered | — | 74,76 | Ready |
| TC-D07 (E) | Defect | BC-EDG-05 | Controllers | BUG-GLB-005 dual controller collision | Both bind resource, divergent gates | 08 | 75 | Ready |
| TC-D08 (E) | Tenancy | — | Model | Cross-tenant isolation N/A (CENTRAL) — documented skip | Skipped w/ note | — | 92 | Ready |
| TC-D09 | Read-only | BC-BIZ-05 | Route | store route registered but handler no-op | Route exists | — | 91 | Ready |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 01 | test_..._01_academic_sessions_table_columns | TC-P01 | Schema | 01-09 |
| 02 | test_..._02_boards_table_columns | TC-P01 | Schema | 01-09 |
| 03 | test_..._03_academic_sessions_unique_keys | TC-P02 | Schema | 01-09 |
| 04 | test_..._04_boards_unique_keys | TC-P02 | Schema | 01-09 |
| 05 | test_..._05_migration_files_present_and_shaped | TC-P01 | Schema | 01-09 |
| 06 | test_..._06_academic_session_model_full_config | TC-P03 | Config | 01-09 |
| 07 | test_..._07_board_model_full_config | TC-P03 | Config | 01-09 |
| 08 | test_..._08_hub_route_registered_with_expected_path | TC-P04 | Route | 01-09 |
| 09 | test_..._09_controller_resource_methods_exist | TC-P05 | Config | 01-09 |
| 10 | test_..._10_index_paginates_ten_per_list | TC-P05 | Biz | 10-19 |
| 11 | test_..._11_index_returns_hub_view_with_both_datasets | TC-P05 | Biz | 10-19 |
| 12 | test_..._12_hub_view_uses_nav_tab_component | TC-P06 | Biz/UI | 10-19 |
| 30 | test_..._30_store_is_empty_stub | TC-D01 | Broken-write | 30-39 |
| 31 | test_..._31_update_is_empty_stub | TC-D01 | Broken-write | 30-39 |
| 32 | test_..._32_destroy_is_empty_stub | TC-D01 | Broken-write | 30-39 |
| 33 | test_..._33_create_view_missing | TC-D02 | Broken-write | 30-39 |
| 34 | test_..._34_show_view_missing | TC-D02 | Broken-write | 30-39 |
| 35 | test_..._35_edit_view_missing | TC-D02 | Broken-write | 30-39 |
| 40 | test_..._40_board_has_organizations_relationship | TC-P10 | Integration | 40-49 |
| 41 | test_..._41_academic_session_has_boards_relationship | TC-P10 | Integration | 40-49 |
| 42 | test_..._42_board_organization_junction_migration_present | TC-P10 | Integration | 40-49 |
| 50 | test_..._50_index_gate_is_prime_board_viewany | TC-N02 | Auth | 50-59 |
| 51 | test_..._51_session_tab_gated_by_academic_session_viewany | TC-N03 | Auth | 50-59 |
| 52 | test_..._52_board_tab_gated_by_board_viewany | TC-N04 | Auth | 50-59 |
| 53 | test_..._53_board_policy_permission_keys | TC-N05 | Auth | 50-59 |
| 54 | test_..._54_academic_session_policy_permission_keys | TC-N05 | Auth | 50-59 |
| 55 | test_..._55_guest_redirected_to_login | TC-N01 | Auth | 50-59 |
| 56 | test_..._56_admin_can_open_hub | TC-P09 | Render | 50-59 |
| 60 | test_..._60_hub_renders_both_tab_labels | TC-P06 | UI | 60-69 |
| 61 | test_..._61_empty_state_marker_present_in_view | TC-P07 | UI | 60-69 |
| 62 | test_..._62_pagination_links_rendered_in_view | TC-P08 | UI | 60-69 |
| 70 | test_..._70_bug_glb_001_model_resolution_reconciliation | TC-D03 | Defect | 70-79 |
| 71 | test_..._71_data_glb_002_is_active_absent_from_sessions | TC-D04 | Defect | 70-79 |
| 72 | test_..._72_data_glb_002_view_reads_phantom_is_active | TC-D04 | Defect | 70-79 |
| 73 | test_..._73_bug_glb_003_single_current_is_db_only | TC-D05 | Defect | 70-79 |
| 74 | test_..._74_bug_glb_004_view_route_name_mismatch | TC-D06 | Defect | 70-79 |
| 75 | test_..._75_bug_glb_005_dual_controller_collision | TC-D07 | Defect | 70-79 |
| 76 | test_..._76_bug_glb_004_mismatched_central_route_not_registered | TC-D06 | Defect | 70-79 |
| 90 | test_..._90_search_query_param_renders_safely | TC-N06 | Security | 90-99 |
| 91 | test_..._91_hub_is_read_only_no_write_endpoints_registered | TC-D09 | Read-only | 90-99 |
| 92 | test_..._92_cross_tenant_isolation_not_applicable_central | TC-D08 | Tenancy (N/A) | 90-99 |

**V1 methods: 14 | V2 methods: 41 | Ratio: 2.93× (gate ≥ 2× satisfied).**

---

## 4. Known Source Defects (audit-equivalent)

| ID | Severity | Summary | Proving test | Reconciliation |
|----|----------|---------|--------------|----------------|
| BUG-GLB-001 | P0→**Not reproduced** | Audit: controller references non-existent `GlobalMaster\Models\AcademicSession` → 500 | V1 test_07, V2 test_70 | Live controller imports `Prime\Models\AcademicSession` (EXISTS); the GM model genuinely does not exist but is not referenced → hub does NOT 500 from model resolution. Residual fragility documented as BUG-GLB-004/006. |
| DATA-GLB-002 | P2 | View reads `$session->is_active`; column absent from `glb_academic_sessions` → silently null | V1 test_05, V2 test_71/72 | Confirmed in source + DDL. |
| BUG-GLB-003 | P1 | Single-current invariant enforced only by DB (`current_flag` UNIQUE); `store()` sets nothing | V1 test_06, V2 test_73 | Confirmed. |
| BUG-GLB-004 | P1 | Hub view mixes `central.global-master.*` and `global-master.*` route-name prefixes → likely unregistered names → 500 when action components fire | V2 test_74/76 | Confirmed in source; route-registration probe gated on module-enabled. |
| BUG-GLB-005 | P1 | Dual controller collision: GlobalMaster + Prime both bind `session-board-setup` resource with divergent gates/logic | V1 test_08, V2 test_75 | Confirmed — GM gate `prime.board.viewAny`, Prime gate `prime.session-board-setup.viewAny`. |
| BUG-GLB-006 | P2 | `create/show/edit` views missing → 500; `store/update/destroy` empty stubs | V1 test_09, V2 test_30-35 | Confirmed. |
