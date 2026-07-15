# UserRolePrm — Test Case List & Business Conditions (`sys_`)

**Module:** Prime (PRM) · central / `prime_db` · **DB scope: CENTRAL (no tenancy)**
**Feature (screen):** UserRolePrm — user ↔ role assignment / junction screen
**Primary table (DDL-verified prefix `sys_`):** `sys_model_has_roles_jnt` (`role_id`, `model_type`, `model_id`)
**Controller:** `Modules\Prime\Http\Controllers\UserRolePrmController`
**Route names:** `central.prime.user-role-prm.{index,create,store,show,edit,update,destroy,search}` · path `/prime/user-role-prm`
**View gate (index):** `prime.role-permission.viewAny`
**Test file:** `sys_UserRolePrm_TestCas.php` (class `sys_UserRolePrm_TestCas extends PrimeDuskTestCase`)

> **Reality note (drives the whole matrix):** `UserRolePrmController` is only partly implemented. `index()` and `search()` are functional; `create()/show()/edit()` return non-existent views; `store()/update()/destroy()` are empty stubs. The screen therefore **reads/filters** users-with-roles and provides a name-search endpoint, but performs **no assignment persistence itself**. Role↔user junction rows are exercised at the DB/model layer. Stub behaviour is captured as documented defects (DEV-URP-003/004/005) with proving tests, not hidden.

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-sys_model_has_roles_jnt`, `_prime_db_v4.sql`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `sys_model_has_roles_jnt` has columns `role_id`, `model_type`, `model_id` | DDL-jnt |
| BC-DB-02 | Composite PK `(role_id, model_id, model_type)` — the sole duplicate-grant guard | DDL-jnt |
| BC-DB-03 | FK `role_id → sys_roles(id) ON DELETE CASCADE` | DDL-jnt |
| BC-DB-04 | No FK on `model_id` (polymorphic) — user delete does not DB-cascade the pivot | DDL-jnt |
| BC-DB-05 | `sys_roles` unique `(name, guard_name)` and `(short_name, guard_name)` | DDL-sys_roles |
| BC-DB-06 | `sys_users` has `deleted_at` (SoftDeletes), unique `email`, `emp_code`, `mobile_no`; single-super-admin unique on generated `super_admin_flag` | DDL-sys_users |

### BC-CFG — Spatie binding (Source: `config/permission.php`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | `table_names.model_has_roles = sys_model_has_roles_jnt` | Config |
| BC-CFG-02 | `table_names.roles = sys_roles`, `table_names.permissions = sys_permissions` | Config |
| BC-CFG-03 | `column_names.model_morph_key = model_id` | Config |
| BC-CFG-04 | Morph map alias `user → Modules\Prime\Models\User` (pivot `model_type` = `user`) | AppServiceProvider morphMap |

### BC-BIZ — Behaviour (Source: Controller + Blade)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `index()` lists users with roles, ordered `is_super_admin DESC, name ASC`, 10/page | Controller:49,68 |
| BC-BIZ-02 | Filters: `role` (all / no-role / role id), `search` (name or email), `status` (is_active) | Controller:45-66 |
| BC-BIZ-03 | Summary cards: Total / Active / Super Admin / No-Role counts | Controller:73-76 |
| BC-BIZ-04 | Role tab paginates roles 10/page (fragment `role-permisons`) | Controller:37-40 |
| BC-BIZ-05 | `search(q,type)` → JSON; empty `[]` when `q` or `type` missing; `type∈{user,role}`; `limit(10)`; returns only `id,name` | Controller:129-153 |
| BC-BIZ-06 | User may hold multiple roles; roles rendered as badges (first 2 + "+N more") | Blade:148-161 |

### BC-AUTH — Authorization (Source: Controller + Blade `@can`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` gated by `prime.role-permission.viewAny` | Controller:29 |
| BC-AUTH-02 | Guest → redirected to `/login` by `auth` middleware | routes/web.php group |
| BC-AUTH-03 | `search()` has **no** `Gate::authorize` — any authenticated user may query it | Controller:129 (**DEV-URP-002**) |
| BC-AUTH-04 | View action columns keyed to `prime.user.*` / `prime.role-permission.*` permissions | Blade:118-185,229-246 |

### BC-REF / BC-INT — Referential integrity
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | Deleting a role removes its junction rows (ON DELETE CASCADE) | DDL-jnt |
| BC-REF-02 | Soft-deleting a user leaves junction rows intact (no cascade on `model_id`) | DDL-jnt + User SoftDeletes |
| BC-INT-01 | `roles` relation resolves pivot via morph alias `user` + `model_id` | Spatie HasRoles + morphMap |

### BC-EDG — Edge cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `search` LIKE wildcards (`%`, `_`) passed literally — must not error | Controller:139-149 |
| BC-EDG-02 | `search` special/quote chars must not 500 (bound param) | Controller:139-149 |
| BC-EDG-03 | Impossible index filter shows "No users found for this filter." | Blade:189-191 |
| BC-EDG-04 | Bogus `show` id must not leak a populated record | Controller:102 (stub) |

### Known Source Defects (audit-equivalent)
| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| DEV-URP-001 | P2 (Auth) | Route family `user-role-prm.*` is gated by `prime.role-permission.viewAny` (foreign resource); no dedicated `user-role-prm` permission exists | `test_01`, `test_51` |
| DEV-URP-002 | P2 (Security) | `search()` has no authorization gate — any authenticated central user can enumerate users & roles by name | `test_53` |
| DEV-URP-003 | P3 (Broken) | `create()/show()/edit()` return non-existent views `prime::create/show/edit` → 500 | `test_54`, `test_72` |
| DEV-URP-004 | P3 (Missing) | `store()/update()/destroy()` are empty stubs — no user↔role assignment is persisted by this screen | `test_55` |
| DEV-URP-005 | P4 (Audit) | No activity logging in `UserRolePrmController` — user/role views & (would-be) changes are unaudited | `test_93` |
| DEV-URP-006 | P4 (Data) | `search()` returns raw collections with no input normalisation (wildcards accepted) | `test_70` |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/02, BC-CFG-* | DDL/Config | Schema + config + route truth | All present | `test_01` | Ready |
| TC-P02 | BC-BIZ-01 | Ctrl | Index loads user tab | Table + cards | `test_10` | Ready |
| TC-P03 | BC-BIZ-03 | Ctrl | Summary cards render | 4 cards | `test_11` | Ready |
| TC-P04 | BC-BIZ-04 | Ctrl | Role tab renders | Pane present | `test_12` | Ready |
| TC-P05 | BC-BIZ-06 | Blade | User's role badge shown | Role name visible | `test_13` | Ready |
| TC-P06 | BC-BIZ-01 | Ctrl | Assignment creates junction row | Row exists | `test_20` | Ready |
| TC-P07 | BC-INT-01 | Spatie | Sync replaces assignments | Old gone / new kept | `test_22` | Ready |
| TC-P08 | BC-DB-01 | DDL | Removal deletes row | Row gone | `test_23` | Ready |
| TC-P09 | BC-CFG-04 | morphMap | Pivot stores model_type+model_id | `user`/id | `test_24` | Ready |
| TC-P10 | BC-BIZ-06 | Blade | Multiple roles per user | 3 rows | `test_25` | Ready |
| TC-P11 | BC-BIZ-05 | Ctrl | Search users JSON | id/name rows | `test_30` | Ready |
| TC-P12 | BC-BIZ-05 | Ctrl | Search roles JSON | id/name rows | `test_31` | Ready |
| TC-P13 | BC-BIZ-05 | Ctrl | Search caps at 10 | ≤10 | `test_35` | Ready |
| TC-P14 | BC-BIZ-02 | Ctrl | Role filter narrows users | Only role users | `test_42` | Ready |
| TC-P15 | BC-BIZ-02 | Ctrl | Search filter matches name | User visible | `test_44` | Ready |
| TC-P16 | BC-AUTH-01 | Ctrl | Admin views index | 200/302 | `test_52` | Ready |
| TC-P17 | BC-BIZ-01 | Ctrl | Super admin listed first | Rows present | `test_73` | Ready |
| TC-P18 | BC-CFG-* | Config | Central connection pinning | mysql | `test_91` | Ready |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-DB-02 | DDL | Duplicate grant rejected by PK | Blocked, count=1 | `test_21` | Ready |
| TC-N02 | BC-BIZ-05 | Ctrl | Search missing `q` → `[]` | `[]` | `test_32` | Ready |
| TC-N03 | BC-BIZ-05 | Ctrl | Search missing `type` → `[]` | `[]` | `test_33` | Ready |
| TC-N04 | BC-BIZ-05 | Ctrl | Search unknown type → `[]` | `[]` | `test_34` | Ready |
| TC-N05 | BC-BIZ-05 | Ctrl | Search exposes only id+name | no leak | `test_36` | Ready |
| TC-N06 | BC-AUTH-02 | Route | Guest redirected to login | 302 /login | `test_50` | Ready |
| TC-N07 | BC-AUTH-01 | Ctrl | Unprivileged user → 403 | 403 | `test_51` | Ready |
| TC-N08 | BC-EDG-01 | Ctrl | Wildcard search no error | 200 | `test_70` | Ready |
| TC-N09 | BC-EDG-02 | Ctrl | Special chars no error | 200 | `test_71` | Ready |
| TC-N10 | BC-EDG-03 | Blade | Empty-state message | "No users found…" | `test_61` | Ready |
| TC-N11 | BC-EDG-04 | Ctrl | Bogus show id no leak | error/redirect | `test_72` | Ready |
| TC-N12 | DEV-URP-003 | Ctrl | create/show/edit view errors | 500/404 | `test_54` | Ready |
| TC-N13 | DEV-URP-004 | Ctrl | store no-op (no persistence) | count unchanged | `test_55` | Ready |
| TC-N14 | DEV-URP-002 | Ctrl | search ungated (documented) | not 403 | `test_53` | Ready |
| TC-N15 | DEV-URP-005 | Ctrl | view writes no activity log | count unchanged | `test_93` | Ready |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | C | BC-REF-01 | DDL | Role delete cascades junction | Rows gone | `test_40` | Ready |
| TC-D02 | B | BC-REF-02 | DDL | User soft-delete retains junction | Row kept | `test_41` | Ready |
| TC-D03 | F | BC-BIZ-02 | Ctrl | No-role filter query runs | Table present | `test_43` | Ready |
| TC-D04 | F | BC-BIZ-02 | Ctrl | Status filter query runs | Table present | `test_45` | Ready |
| TC-D05 | A | BC-BIZ-06 | Blade | No-role users countable | ≥1 | `test_14` | Ready |
| TC-D06 | G | BC-DB-02 | DDL | Composite PK present | PRIMARY key | `test_94` | Ready |

### Security / Central-isolation (TC-S / TC-T)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S01 | BC-BIZ-05 | Ctrl | Search XSS name JSON-encoded | application/json | `test_92` | Ready |
| TC-S02 | DEV-URP-002 | Ctrl | Search ungated enumeration | proven | `test_53` | Ready |
| TC-T01 | E21 | Constraint | Feature runs on 127.0.0.1 central host | host=127.0.0.1 | `test_90` | Ready |
| TC-T02 | BC-CFG | Config | Central connection isolation | mysql | `test_91` | Ready |

### UI/UX (TC-U)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-U01 | BC-BIZ-02 | Blade | Reset-filters link present | anchor present | `test_60` | Ready |
| TC-U02 | BC-BIZ-01 | Ctrl | Pagination control renders | pane present | `test_62` | Ready |
| TC-U03 | BC-BIZ-04 | Blade | Tab query selects role pane | active pane | `test_63` | Ready |

---

## 3. Test Method Index (44 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_userroleprm_01_schema_model_and_route_configuration_are_correct | TC-P01 | Schema | 01-09 |
| 2 | test_userroleprm_10_index_page_loads_with_user_tab | TC-P02 | Biz | 10-19 |
| 3 | test_userroleprm_11_summary_cards_render | TC-P03 | Biz | 10-19 |
| 4 | test_userroleprm_12_role_tab_renders | TC-P04 | Biz | 10-19 |
| 5 | test_userroleprm_13_user_with_role_shows_role_badge | TC-P05 | Biz | 10-19 |
| 6 | test_userroleprm_14_no_role_users_are_countable | TC-D05 | Dep-A | 10-19 |
| 7 | test_userroleprm_20_assignment_creates_junction_row | TC-P06 | Junction | 20-29 |
| 8 | test_userroleprm_21_duplicate_assignment_is_rejected_by_primary_key | TC-N01 | Junction | 20-29 |
| 9 | test_userroleprm_22_sync_replaces_assignments | TC-P07 | Junction | 20-29 |
| 10 | test_userroleprm_23_removal_deletes_junction_row | TC-P08 | Junction | 20-29 |
| 11 | test_userroleprm_24_junction_stores_morph_type_and_model_id | TC-P09 | Junction | 20-29 |
| 12 | test_userroleprm_25_user_may_hold_multiple_roles | TC-P10 | Junction | 20-29 |
| 13 | test_userroleprm_30_search_users_returns_matching_json | TC-P11 | Search | 30-39 |
| 14 | test_userroleprm_31_search_roles_returns_matching_json | TC-P12 | Search | 30-39 |
| 15 | test_userroleprm_32_search_without_query_returns_empty | TC-N02 | Search | 30-39 |
| 16 | test_userroleprm_33_search_without_type_returns_empty | TC-N03 | Search | 30-39 |
| 17 | test_userroleprm_34_search_unknown_type_returns_empty | TC-N04 | Search | 30-39 |
| 18 | test_userroleprm_35_search_caps_results_at_ten | TC-P13 | Search | 30-39 |
| 19 | test_userroleprm_36_search_json_shape_is_id_and_name_only | TC-N05 | Search | 30-39 |
| 20 | test_userroleprm_40_deleting_role_cascades_junction_rows | TC-D01 | Dep-C | 40-49 |
| 21 | test_userroleprm_41_soft_deleting_user_retains_junction_row | TC-D02 | Dep-B | 40-49 |
| 22 | test_userroleprm_42_index_role_filter_narrows_users | TC-P14 | Integ | 40-49 |
| 23 | test_userroleprm_43_index_no_role_filter_query_runs | TC-D03 | Integ | 40-49 |
| 24 | test_userroleprm_44_index_search_filter_matches_name | TC-P15 | Integ | 40-49 |
| 25 | test_userroleprm_45_index_status_filter_query_runs | TC-D04 | Integ | 40-49 |
| 26 | test_userroleprm_50_guest_is_redirected_to_login | TC-N06 | Auth | 50-59 |
| 27 | test_userroleprm_51_index_enforces_view_gate_for_unprivileged_user | TC-N07 | Auth | 50-59 |
| 28 | test_userroleprm_52_super_admin_can_view_index | TC-P16 | Auth | 50-59 |
| 29 | test_userroleprm_53_search_endpoint_has_no_authorization_gate | TC-N14/S02 | Auth | 50-59 |
| 30 | test_userroleprm_54_create_show_edit_reference_missing_views | TC-N12 | Auth | 50-59 |
| 31 | test_userroleprm_55_store_update_destroy_are_no_ops | TC-N13 | Auth | 50-59 |
| 32 | test_userroleprm_60_reset_filters_link_present | TC-U01 | UI | 60-69 |
| 33 | test_userroleprm_61_empty_state_message_for_impossible_filter | TC-N10 | UI | 60-69 |
| 34 | test_userroleprm_62_pagination_control_renders | TC-U02 | UI | 60-69 |
| 35 | test_userroleprm_63_tab_query_selects_role_pane | TC-U03 | UI | 60-69 |
| 36 | test_userroleprm_70_search_wildcard_characters_do_not_error | TC-N08 | Edge | 70-79 |
| 37 | test_userroleprm_71_search_special_chars_do_not_error | TC-N09 | Edge | 70-79 |
| 38 | test_userroleprm_72_invalid_show_id_does_not_expose_data | TC-N11 | Edge | 70-79 |
| 39 | test_userroleprm_73_super_admin_listed_first | TC-P17 | Edge | 70-79 |
| 40 | test_userroleprm_90_feature_runs_on_central_host | TC-T01 | Tenancy | 90-99 |
| 41 | test_userroleprm_91_junction_uses_central_connection | TC-T02/P18 | Tenancy | 90-99 |
| 42 | test_userroleprm_92_search_payload_is_json_encoded_not_html | TC-S01 | Security | 90-99 |
| 43 | test_userroleprm_93_no_activity_log_written_for_view_or_search | TC-N15 | Security | 90-99 |
| 44 | test_userroleprm_94_junction_pk_enforces_composite_uniqueness | TC-D06 | Security | 90-99 |
