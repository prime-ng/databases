# glb_SessionBoardSetup — TC List & Business Conditions

- **Module:** Prime (PRM) — CENTRAL / GlobalMaster data (`global_master_mysql`, `glb_*`)
- **Feature / Screen:** SessionBoardSetup — composite "Session & Board Setup" screen (two tabs: Academic Session + Academic Board)
- **Primary tables:** `glb_academic_sessions`, `glb_boards` (DDL: `_global_db_v4.sql`)
- **File prefix:** `glb_` (DDL primary-table prefix) — **MISMATCH** vs registry Prime prefix `prm_` (HARD RULE 4: table-prefix wins)
- **Controller:** `Modules\Prime\Http\Controllers\SessionBoardSetupController`
- **Route:** `Route::resource('session-board-setup', ...)` under `domain(app.domain)->name('central.')` → `prefix('prime')->name('prime.')` (middleware `auth,verified`) → names `central.prime.session-board-setup.*`, path `/prime/session-board-setup`
- **DB scope:** CENTRAL (no tenant init). Host `http://127.0.0.1:8000`.
- **Screen type:** **read-focused composite** — only `index()` is functional; create/store/show/edit/update/destroy are stubs.
- **Activity log:** none (controller emits no `activityLog()`). Central sink would be `sys_central_activity_logs`.

---

## 1. Business Conditions

### BC-DB (schema) — Source: DDL `_global_db_v4.sql`
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `glb_academic_sessions`: id, short_name varchar(20), name varchar(50), start_date/end_date date, is_current tinyint, current_flag (generated stored), soft-delete + timestamps | DDL-glb_academic_sessions |
| BC-DB-02 | `glb_academic_sessions` UNIQUE(short_name); UNIQUE(current_flag) → at most one `is_current=1` | DDL-glb_academic_sessions |
| BC-DB-03 | `glb_academic_sessions` has **NO `is_active` column** (only `is_current`) | DDL-glb_academic_sessions |
| BC-DB-04 | `glb_boards`: id, name varchar(255) UNIQUE, short_name varchar(20) UNIQUE, is_active tinyint, soft-delete + timestamps | DDL-glb_boards |
| BC-DB-05 | Pivot `academic_session_board` (belongsToMany default) has **NO table / NO migration** | Model AcademicSession::boards() + DDL |

### BC-VAL (validation) — Source: Controller
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | Status filter accepted only when value ∈ {'0','1'} (`in_array(...,true)`) | Controller index() |
| BC-VAL-02 | No FormRequest exists — write endpoints perform no validation (stubs) | Controller store/update/destroy |

### BC-AUTH (authorization) — Source: Controller / Provider / Policy
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `prime.session-board-setup.viewAny` | Controller index() |
| BC-AUTH-02 | Route requires `auth` + `verified` (guest → /login) | routes/web.php |
| BC-AUTH-03 | create/store gate `.create`; show gate `.view`; edit/update gate `.update`; destroy gate `.delete` | Controller |
| BC-AUTH-04 | AcademicSession model policy = `GlobalMaster\AcademicSessionPolicy` (Provider:101) | PrimeServiceProvider |
| BC-AUTH-05 | `SessionBoardSetupPolicy` is **never registered** (dead code) | PrimeServiceProvider grep |

### BC-BIZ (behaviour) — Source: Controller
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Sessions listed `orderByDesc('start_date')`, paginate 10, page param `academicsession_page` | Controller index() |
| BC-BIZ-02 | Boards listed `orderBy('name')`, paginate 4, page param `academicboard_page` | Controller index() |
| BC-BIZ-03 | Search filters both lists on `name`/`short_name` (LIKE) | Controller index() |
| BC-BIZ-04 | Board status filter `where('is_active', ...)` — valid | Controller index() |
| BC-BIZ-05 | Controller emits **no** activity log | Controller |

### BC-INT / BC-EDG / BC-SEC
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Feature is central — must run without tenant context | Constraint #21/#22 |
| BC-EDG-01 | UNIQUE(current_flag) allows only one current session | DDL-glb_academic_sessions |
| BC-SEC-01 | Reflected `?search` value must be HTML-escaped in the search input | View Blade `{{ }}` |
| BC-SEC-02 | Search is parameterised (LIKE bindings) — injection-safe | Controller index() |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/02/04 | DDL | Schema/model/route config correct | All asserts pass | `_01` | Automated |
| TC-P10 | BC-AUTH-01 | Controller | Index renders both tabs for admin | Panes present | `_10` | Automated |
| TC-P11 | BC-BIZ-01 | Controller | Session listed on tab | Name/short seen | `_11` | Automated |
| TC-P12 | BC-BIZ-02 | Controller | Board listed on tab | Name seen | `_12` | Automated |
| TC-P13 | BC-BIZ-01/02 | Controller | Named pagination params (10/4) | perPage+pageName correct | `_13` | Automated |
| TC-P15 | BC-BIZ-03 | Controller | Board search name+short | Board returned | `_15` | Automated |
| TC-P17 | BC-BIZ-04 | Controller | Board status=1 filter | Active only | `_17` | Automated |
| TC-P50 | BC-AUTH-01 | Controller | viewAny gate admin allow / fresh deny | Correct | `_50` | Automated |
| TC-P54 | BC-AUTH-03 | Controller | create gate deny fresh | Denied | `_54` | Automated |
| TC-P60 | BC-UIX | View | Breadcrumb title | Seen | `_60` | Automated |
| TC-P61 | BC-UIX | View | Search controls both tabs | Present | `_61` | Automated |
| TC-P62 | BC-UIX | View | Empty-state text defined | Present | `_62` | Automated |
| TC-P90 | BC-INT-01 | Constraint | Central context, no tenant | Not initialized | `_90` | Automated |
| TC-P91 | BC-AUTH | routes | Route central-domain scoped | Path present | `_91` | Automated |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N30 | BC-DB-03 | Controller/DDL | Session status filter → missing is_active | QueryException(is_active) | `_30` | Automated · **BUG-PRM-013** |
| TC-N31 | BC-VAL-01 | Controller | Invalid status ignored | No filter, no error | `_31` | Automated |
| TC-N32 | BC-AUTH-02 | routes | Guest redirect | → /login | `_32` | Automated |
| TC-N33 | BC-VAL-02 | Controller | store() no-op stub | No persistence | `_33` | Automated · **BUG-PRM-015** |
| TC-N34 | BC-VAL-02 | Controller | update() no-op stub | No persistence | `_34` | Automated · **BUG-PRM-015** |
| TC-N35 | BC-VAL-02 | Controller | destroy() no-op stub | No deletion | `_35` | Automated · **BUG-PRM-015** |
| TC-N36 | BC-VAL-02 | Controller | create/show/edit missing views | Views absent | `_36` | Automated · **BUG-PRM-015** |
| TC-N71 | BC-SEC-01 | View | Reflected search escaped | No live `<script>` | `_71` | Automated |
| TC-N72 | BC-SEC-02 | Controller | Injection-shaped search safe | Query runs | `_72` | Automated |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D40 | C/E | BC-DB-05 | Model | Pivot table absent; ->boards throws | Missing table | `_40` | Automated · **BUG-PRM-014** |
| TC-D41 | B | BC-REF | Model | Session soft-delete excluded/restored | Correct | `_41` | Automated |
| TC-D42 | B | BC-REF | Model | Board soft-delete excluded | Correct | `_42` | Automated |
| TC-D43 | G | BC-EDG-01 | DDL | Only one current session | Unique violation | `_43` | Automated |

### Permissions / Defect proofs (TC-S / policy)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S51 | BC-AUTH-04 | Provider | Effective AcademicSession policy = GlobalMaster | Instanceof | `_51` | Automated · **BUG-PRM-011** |
| TC-S52 | BC-AUTH-05 | Provider | SessionBoardSetupPolicy unregistered (dead) | Not referenced | `_52` | Automated · **BUG-PRM-011** |
| TC-S53 | BC-AUTH | Controller/View | Controller vs view permission surface diverges | Divergence proven | `_53` | Automated · **BUG-PRM-012** |
| TC-S55 | BC-AUTH-03 | Seeder/Controller | destroy `.delete` absent from readWrite grant | Confirmed | `_55` | Automated · **BUG-PRM-016** |
| TC-P02 | BC-BIZ-05 | Constraint#25 | Central sink present; feature logs nothing | Correct | `_02` | Automated |

---

## 3. Test Method Index (bands)
| # | Method | TC | Band |
|---|--------|----|------|
| 1 | `test_sessionboardsetup_01_schema_model_and_route_configuration_are_correct` | TC-P01 | 01–09 |
| 2 | `test_sessionboardsetup_02_central_activity_sink_present_but_feature_logs_nothing` | TC-P02 | 01–09 |
| 3 | `test_sessionboardsetup_10_index_renders_both_tabs_for_admin` | TC-P10 | 10–19 |
| 4 | `test_sessionboardsetup_11_academic_session_tab_lists_created_session` | TC-P11 | 10–19 |
| 5 | `test_sessionboardsetup_12_board_tab_lists_created_board` | TC-P12 | 10–19 |
| 6 | `test_sessionboardsetup_13_index_uses_named_pagination_params` | TC-P13 | 10–19 |
| 7 | `test_sessionboardsetup_15_board_search_matches_name_and_short_name` | TC-P15 | 10–19 |
| 8 | `test_sessionboardsetup_17_board_status_filter_active_returns_only_active` | TC-P17 | 10–19 |
| 9 | `test_sessionboardsetup_30_academic_session_status_filter_hits_missing_is_active_column` | TC-N30 | 30–39 |
| 10 | `test_sessionboardsetup_31_invalid_status_value_is_ignored` | TC-N31 | 30–39 |
| 11 | `test_sessionboardsetup_32_guest_is_redirected_to_login` | TC-N32 | 30–39 |
| 12 | `test_sessionboardsetup_33_store_endpoint_is_a_noop_stub` | TC-N33 | 30–39 |
| 13 | `test_sessionboardsetup_34_update_endpoint_is_a_noop_stub` | TC-N34 | 30–39 |
| 14 | `test_sessionboardsetup_35_destroy_endpoint_is_a_noop_stub` | TC-N35 | 30–39 |
| 15 | `test_sessionboardsetup_36_create_show_edit_reference_missing_views` | TC-N36 | 30–39 |
| 16 | `test_sessionboardsetup_40_session_board_pivot_table_is_absent` | TC-D40 | 40–49 |
| 17 | `test_sessionboardsetup_41_soft_deleted_session_is_excluded_by_default` | TC-D41 | 40–49 |
| 18 | `test_sessionboardsetup_42_soft_deleted_board_is_excluded_by_default` | TC-D42 | 40–49 |
| 19 | `test_sessionboardsetup_43_only_one_current_session_allowed` | TC-D43 | 40–49 |
| 20 | `test_sessionboardsetup_50_index_gate_allows_admin_denies_fresh_user` | TC-P50 | 50–59 |
| 21 | `test_sessionboardsetup_51_effective_academic_session_policy_is_globalmaster_not_sessionboardsetup` | TC-S51 | 50–59 |
| 22 | `test_sessionboardsetup_52_sessionboardsetup_policy_is_not_registered_anywhere` | TC-S52 | 50–59 |
| 23 | `test_sessionboardsetup_53_controller_and_view_permission_surfaces_diverge` | TC-S53 | 50–59 |
| 24 | `test_sessionboardsetup_54_store_gate_denies_fresh_user` | TC-P54 | 50–59 |
| 25 | `test_sessionboardsetup_55_destroy_delete_ability_absent_from_standard_readwrite_grant` | TC-S55 | 50–59 |
| 26 | `test_sessionboardsetup_60_breadcrumb_title_present` | TC-P60 | 60–69 |
| 27 | `test_sessionboardsetup_61_search_controls_present_on_both_tabs` | TC-P61 | 60–69 |
| 28 | `test_sessionboardsetup_62_empty_state_text_defined_in_view` | TC-P62 | 60–69 |
| 29 | `test_sessionboardsetup_71_reflected_search_value_is_escaped` | TC-N71 | 70–79 |
| 30 | `test_sessionboardsetup_72_injection_shaped_search_does_not_break_query` | TC-N72 | 70–79 |
| 31 | `test_sessionboardsetup_90_runs_in_central_context_without_tenant` | TC-P90 | 90–99 |
| 32 | `test_sessionboardsetup_91_index_route_is_central_domain_scoped` | TC-S91 | 90–99 |

## 4. Known Source Defects
| ID | Sev | Summary | Proving method |
|----|-----|---------|----------------|
| BUG-PRM-011 | P1 | `SessionBoardSetupPolicy` never registered (dead); AcademicSession governed by `GlobalMaster\AcademicSessionPolicy`. *(Sub-run hypothesis of a duplicate overwrite is NOT in source — real defect is the inverse.)* | `_51`, `_52` |
| BUG-PRM-012 | P2 | Controller gates `session-board-setup.*` but view gates `academic-session.*`/`board.*` — divergent authorization surface | `_53` |
| BUG-PRM-013 | P1 | index() status filter `where('is_active')` on `glb_academic_sessions` — column does not exist → 500 on `?status=0|1` | `_30`, `_01` |
| BUG-PRM-014 | P2 | Composite "pairing" unimplemented — `belongsToMany` pivot `academic_session_board` has no table/migration | `_40` |
| BUG-PRM-015 | P2 | create/show/edit return missing Blade views (500); store/update/destroy are empty no-op stubs | `_33`,`_34`,`_35`,`_36` |
| BUG-PRM-016 | P3 | destroy gates `.delete`, but seeder `readWrite` grant for the academicCfg group omits `delete` | `_55` |
