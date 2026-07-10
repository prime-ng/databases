# Activity Log (Central Audit Viewer) — Test Case List & Business Conditions

**Module:** GlobalMaster (central / Prime-side)
**Feature:** ActivityLog — read-only audit-trail viewer
**Primary table:** `sys_activity_logs` (prime_db) · **Prefix:** `sys_`
**Model of record:** `Modules\GlobalMaster\Models\ActivityLog`
**Wired central controller:** `Modules\Prime\Http\Controllers\ActivityLogController`
**Route (name):** `central.global-master.activity-log.index` (+ `.search`)
**Test style:** central browser Dusk (extends `PrimeDuskTestCase`, host `http://127.0.0.1:8000`)
**Screen type:** REPORT / AUDIT VIEWER → lighter depth (render, ordering, pagination, filter/search, permission, empty state). No create/edit/delete matrix.

> **Source-verified premise corrections (see Gap Analysis Cross-Reference Findings):**
> 1. The wired central viewer reads **`sys_central_activity_logs`** via `Modules\Prime\Models\ActivityLog`, NOT `sys_activity_logs`. `sys_activity_logs` (GlobalMaster tenancy-aware model) is written only in **tenant** context by the global `activityLog()` helper. → **BUG-GLB-ALOG-03 / RISK-GLB-008** (dual divergent audit sinks).
> 2. The index is **NOT ungated**. Only the `global-master.activity-log.viewAny` line is commented; an active `Gate::any(['prime.activity-log.viewAny'])` (GlobalMaster ctrl) / `Gate::authorize('prime.activity-log.viewAny')` (Prime ctrl) still guards it.
> 3. `activity-log/search` is **live** (Prime `search()` returns JSON) — audit **BUG-GLB-005** ("dead search route → 500") is **NOT reproduced** for the central Prime controller. However `search()` has **no Gate** → **BUG-GLB-ALOG-01 (SEC)**.

---

## 1. Business Conditions

### BC-DB — schema (Source: `DDL-sys_activity_logs`, `_prime_db_v4.sql`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `sys_activity_logs` has columns id, subject_type, subject_id, user_id, event, properties, ip_address, user_agent, created_at, updated_at | DDL |
| BC-DB-02 | `id` INT UNSIGNED AUTO_INCREMENT PK | DDL |
| BC-DB-03 | `subject_type` VARCHAR(255) NOT NULL; `subject_id` INT UNSIGNED NOT NULL (polymorph) | DDL |
| BC-DB-04 | `user_id` INT UNSIGNED NOT NULL, FK → `sys_users(id)` ON DELETE CASCADE | DDL |
| BC-DB-05 | `event` VARCHAR(255) NOT NULL | DDL |
| BC-DB-06 | `properties` JSON NULLABLE | DDL |
| BC-DB-07 | `ip_address`, `user_agent` VARCHAR(255) NULLABLE | DDL |
| BC-DB-08 | Indexes: (subject_type, subject_id), (user_id), (created_at, user_id) | DDL |
| BC-DB-09 | **No `deleted_at`** — table/model are NOT soft-deletable (constraint C12) | DDL/Model |

### BC-VAL — validation (Source: Controller)

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | Read-only screen: no FormRequest, no create/edit/delete forms exposed (store/edit/update/destroy are stubs) | Controller |

### BC-AUTH — authorization (Source: Controller/Policy/Blade)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` requires `prime.activity-log.viewAny` (Prime `Gate::authorize`; GlobalMaster `Gate::any([...]) \|\| abort(403)`) | Controller |
| BC-AUTH-02 | Guest is redirected to `/login` by `auth` middleware | routes/web.php |
| BC-AUTH-03 | Audit-trail card is additionally gated `@can('prime.activity-log.view')` (view ≠ viewAny → **BUG-GLB-ALOG-02**) | Blade |
| BC-AUTH-04 | `search()` has **NO** gate → any authenticated central user can enumerate audit data → **BUG-GLB-ALOG-01 (SEC)** | Controller |
| BC-AUTH-05 | Super-admin bypass via `Gate::before` (is_super_admin && super_admin_flag) | AppServiceProvider |
| BC-AUTH-06 | `PrimeActivityLogPolicy` defines viewAny/view/create/update/delete/restore/forceDelete | Policy |

### BC-BIZ — behaviour (Source: Controller/Model/Helper/Blade)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Index orders newest-first (`ActivityLog::latest()`) | Controller |
| BC-BIZ-02 | GlobalMaster index paginates at 10/page; Prime central index paginates at 20/page | Controller |
| BC-BIZ-03 | `properties` casts to array (JSON round-trip) | Model |
| BC-BIZ-04 | `subject()` is polymorphic `morphTo`; view shows `class_basename(subject_type)` | Model/Blade |
| BC-BIZ-05 | `user()` belongsTo — resolves CentralUser (Prime\User) in central, TenantUser (SchoolSetup\User) in tenant | Model |
| BC-BIZ-06 | Global `activityLog($subject,$event,$properties)` appends a row; user_id = `Auth::id()` (issued_by) | Helper |
| BC-BIZ-07 | `activityLog()` routes to CentralActivityLog (sys_central_activity_logs) in central, TenantActivityLog (sys_activity_logs) in tenant | Helper |
| BC-BIZ-08 | `activityLog(null,...)` returns null (no-op) | Helper |
| BC-BIZ-09 | Search returns JSON suggestions by type: subject / event / user / all | Controller |

### BC-INT / BC-REF — integration & referential (Source: DDL/Helper)

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `user_id` FK → `sys_users(id)` ON DELETE CASCADE (deleting a user removes their logs) | DDL |
| BC-INT-01 | `subject_type`/`subject_id` may reference any model across modules (polymorphic; no FK) | Model/DDL |
| BC-INT-02 | Two divergent audit sinks for one conceptual feature: `sys_activity_logs` (tenant) vs `sys_central_activity_logs` (central) → **RISK-GLB-008** | Helper/Models |

### BC-EDG — edge cases (Source: Blade/DDL)

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Null `properties` allowed and rendered without message/changes blocks | DDL/Blade |
| BC-EDG-02 | Null `ip_address`/`user_agent` allowed; blocks hidden when absent | DDL/Blade |
| BC-EDG-03 | Unknown `event` → default (secondary) badge style | Blade |
| BC-EDG-04 | Null `subject_type` → `—` placeholder | Blade |
| BC-EDG-05 | Missing user relation → `System` label | Blade |
| BC-EDG-06 | `user_agent` truncated to 260px in UI; stored ≤ 255 chars | Blade/DDL |

### BC-SEC — security pack (Source: Controller/Blade)

| ID | Condition | Source |
|----|-----------|--------|
| BC-SEC-01 | Free-text (`properties.message`, `user_agent`) rendered escaped via `{{ }}` (no `{!! !!}`) | Blade |
| BC-SEC-02 | `search()` endpoint unguarded (info disclosure) | Controller (BUG-GLB-ALOG-01) |

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Schema | BC-DB-01..09 | DDL | Table + columns + no deleted_at | All present; no soft delete | 01 | 01,02 | Ready |
| TC-P02 | Model | BC-BIZ-04,05 | Model | subject morphTo, user belongsTo | Correct relation types | 02 | 04,05 | Ready |
| TC-P03 | Schema | BC-DB-04,08 | DDL | user_id non-null int + indexes | FK/index metadata correct | 03 | 06,08 | Ready |
| TC-P04 | Route | BC-AUTH-01 | routes | index+search route/method registered | All registered | 04 | 09 | Ready |
| TC-P05 | Schema | BC-DB-06 | DDL | properties json/text | Type in {json,text} | — | 07 | Ready |
| TC-P06 | Biz | BC-BIZ-03 | Model | properties array cast round-trip | Array returned | 06 | 11 | Ready |
| TC-P07 | Biz | BC-BIZ-01 | Controller | latest() newest-first | Newest row first | 07 | 13 | Ready |
| TC-P08 | Biz | BC-BIZ-02 | Controller | paginate 10 (GM) / 20 (Prime) | perPage correct | 08 | 14,15 | Ready |
| TC-P09 | Biz | BC-BIZ-04 | Model | morphTo resolves subject | Subject model resolved | 09 | 16 | Ready |
| TC-P10 | Biz | BC-BIZ-06 | Helper | activityLog() writes row w/ issued_by | Row + user_id = admin | 10 | 18 | Ready |
| TC-P11 | Biz | BC-BIZ-08 | Helper | activityLog(null) → null | Returns null | — | 19 | Ready |
| TC-P12 | UI | BC-BIZ-01 | Blade | index renders heading + audit card | "Activity Log" visible | 12 | 60 | Env-gated |
| TC-P13 | UI | BC-BIZ-09 | Blade | search form controls present | inputs/filter/reset present | 16 | 61,66 | Ready |
| TC-P14 | UI | BC-BIZ-09 | Blade | filter options subject/event/user | All three present | — | 62 | Ready |
| TC-P15 | UI | BC-DB | Blade | total-count badge + pagination links | Present | 16 | 64,65 | Ready |

### Negative / Security (TC-N / TC-S)

| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Auth | BC-AUTH-02 | routes | Guest hitting index | Redirect to /login | 11 | 50 | Env-gated |
| TC-N02 | Auth | BC-AUTH-01 | Controller | index authorises via prime.viewAny | Gate present | 14 | 51 | Ready |
| TC-N03 | Auth | BC-AUTH-01 | Controller | GM-specific gate only commented (not ungated) | Active Gate::any present | — | 52 | Ready |
| TC-S01 | Security | BC-SEC-02 / BC-AUTH-04 | Controller | search() has no Gate | No Gate in method | 15 | 53 | Ready |
| TC-S02 | Security | BC-AUTH-03 | Blade | card gate view≠viewAny mismatch | @can view present | 16 | 55 | Ready |
| TC-S03 | Security | BC-SEC-01 | Blade | properties escaped in view | `{{ }}` not `{!! !!}` | — | 91 | Ready |
| TC-S04 | Security | BC-SEC-01 | Model | XSS payload stored verbatim (escaped at render) | Verbatim in JSON | — | 92 | Env-gated |
| TC-S05 | Auth | BC-AUTH-05 | Provider | super-admin Gate::before configured | Present | — | 56 | Ready |
| TC-S06 | Auth | BC-AUTH-06 | Policy | policy defines abilities | viewAny/view/create exist | — | 54 | Ready |
| TC-S07 | Security | BC-AUTH-04 | routes | search HTTP probe status set | Status in accepted set | — | 93 | Env-gated |
| TC-N04 | Auth | BC-AUTH-01 | routes | index HTTP probe status set | Status in accepted set | — | 94 | Env-gated |

### Dependency (TC-D)

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 (C) | Ref | BC-REF-01 | DDL | user_id FK → sys_users CASCADE | FK metadata correct | 03 | 40 | Ready |
| TC-D02 (E) | Int | BC-INT-01 | Model | subject accepts arbitrary model class | Stored verbatim | — | 41 | Env-gated |
| TC-D03 (E) | Int | BC-INT-02 | Helper | central vs tenant sinks distinct | Tables differ | 05 | 42 | Ready |
| TC-D04 (E) | Int | BC-BIZ-07 | Helper | helper routes by tenancy | Branch present | — | 43 | Ready |
| TC-D05 (E) | Int | MIG-GLB-001 | Migration | model table ≠ dead `activity_logs` | table = sys_activity_logs | — | 44 | Ready |
| TC-D06 (F) | Edge | BC-BIZ-05 | Model | user() tenancy-aware switch | Branch present | 02 | 05,90 | Ready |

### Edge (TC-EDG)

| TC ID | BC | Source | Description | Expected | V2 | Status |
|-------|----|--------|-------------|----------|----|--------|
| TC-EDG-01 | BC-EDG-01,02 | Blade/DDL | null properties/ip/ua | Allowed / hidden | 12,70 | Ready |
| TC-EDG-02 | BC-EDG-03 | Blade | unknown event default style | secondary badge | 71 | Ready |
| TC-EDG-03 | BC-EDG-04 | Blade | null subject → `—` | Placeholder present | 72 | Ready |
| TC-EDG-04 | BC-EDG-05 | Blade | missing user → `System` | Fallback present | 73 | Ready |
| TC-EDG-05 | BC-EDG-06 | DDL | long user_agent ≤ 255 | Stored within limit | 74 | Env-gated |

---

## 3. Known Source Defects (audit-equivalent)

| ID | Severity | Title | Proving test |
|----|----------|-------|--------------|
| BUG-GLB-ALOG-01 | High (SEC) | `ActivityLogController::search()` has no authorization gate | V1 test_15 / V2 test_53 |
| BUG-GLB-ALOG-02 | Medium | Audit card gated `view` while index gated `viewAny` (permission mismatch) | V1 test_16 / V2 test_55 |
| BUG-GLB-ALOG-03 / RISK-GLB-008 | Medium (ARCH) | Two divergent audit sinks: central viewer reads `sys_central_activity_logs`, not `sys_activity_logs` | V1 test_05 / V2 test_42,43 |
| MIG-GLB-001 | P2 | Dead `activity_logs` migration; `sys_activity_logs` is the real audit table | V2 test_44 |
| BUG-GLB-005 (NOT reproduced) | — | "activity-log.search dead → 500": Prime `search()` is live/JSON; documented as resolved for central | V1 test_04,13 / V2 test_09 |

---

## 4. V2 Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_activitylog_01_table_exists_with_all_ddl_columns | TC-P01 | Schema | 01-09 |
| 2 | test_activitylog_02_table_has_no_soft_delete_column | TC-P01/BC-DB-09 | Schema | 01-09 |
| 3 | test_activitylog_03_model_table_fillable_and_casts_are_exact | TC-P01 | Model | 01-09 |
| 4 | test_activitylog_04_subject_is_morphto_relationship | TC-P02 | Model | 01-09 |
| 5 | test_activitylog_05_user_is_belongsto_relationship_in_central_context | TC-P02/TC-D06 | Model | 01-09 |
| 6 | test_activitylog_06_user_id_column_is_non_null_integer | TC-P03 | Schema | 01-09 |
| 7 | test_activitylog_07_properties_column_is_json_or_text | TC-P05 | Schema | 01-09 |
| 8 | test_activitylog_08_composite_and_fk_indexes_exist | TC-P03 | Schema | 01-09 |
| 9 | test_activitylog_09_central_route_search_route_and_controller_methods_registered | TC-P04 | Route | 01-09 |
| 10 | test_activitylog_10_row_persists_with_exact_event_string | TC-P10 | Biz | 10-19 |
| 11 | test_activitylog_11_properties_array_cast_round_trips | TC-P06 | Biz | 10-19 |
| 12 | test_activitylog_12_null_properties_are_allowed | TC-EDG-01 | Edge | 10-19 |
| 13 | test_activitylog_13_latest_orders_newest_first | TC-P07 | Biz | 10-19 |
| 14 | test_activitylog_14_index_paginates_at_ten_per_page | TC-P08 | Biz | 10-19 |
| 15 | test_activitylog_15_central_controller_paginates_at_twenty | TC-P08 | Biz | 10-19 |
| 16 | test_activitylog_16_morphto_subject_resolves_polymorphically | TC-P09 | Biz | 10-19 |
| 17 | test_activitylog_17_class_basename_used_for_subject_display | TC-P09 | Biz | 10-19 |
| 18 | test_activitylog_18_helper_writes_central_row_with_issued_by | TC-P10 | Biz | 10-19 |
| 19 | test_activitylog_19_helper_returns_null_for_null_subject | TC-P11 | Biz | 10-19 |
| 20 | test_activitylog_40_user_fk_references_sys_users_on_delete_cascade | TC-D01 | Integration | 40-49 |
| 21 | test_activitylog_41_subject_columns_accept_arbitrary_model_class | TC-D02 | Integration | 40-49 |
| 22 | test_activitylog_42_central_and_tenant_sinks_are_distinct_tables | TC-D03 | Integration | 40-49 |
| 23 | test_activitylog_43_helper_routes_by_tenancy_state | TC-D04 | Integration | 40-49 |
| 24 | test_activitylog_44_dead_activity_logs_migration_is_not_the_model_table | TC-D05 | Integration | 40-49 |
| 25 | test_activitylog_50_guest_cannot_reach_index | TC-N01 | Permissions | 50-59 |
| 26 | test_activitylog_51_index_authorizes_via_prime_viewany_permission | TC-N02 | Permissions | 50-59 |
| 27 | test_activitylog_52_global_master_specific_gate_is_only_commented_out | TC-N03 | Permissions | 50-59 |
| 28 | test_activitylog_53_search_endpoint_lacks_authorization_gate_SEC | TC-S01 | Security | 50-59 |
| 29 | test_activitylog_54_policy_defines_viewany_view_and_create_abilities | TC-S06 | Permissions | 50-59 |
| 30 | test_activitylog_55_audit_card_gate_uses_view_not_viewany_mismatch | TC-S02 | Security | 50-59 |
| 31 | test_activitylog_56_super_admin_bypass_gate_before_is_configured | TC-S05 | Permissions | 50-59 |
| 32 | test_activitylog_60_index_renders_heading_and_audit_card | TC-P12 | UI | 60-69 |
| 33 | test_activitylog_61_search_form_controls_present | TC-P13 | UI | 60-69 |
| 34 | test_activitylog_62_filter_type_options_are_subject_event_user | TC-P14 | UI | 60-69 |
| 35 | test_activitylog_63_empty_state_message_present | TC-P12 | UI | 60-69 |
| 36 | test_activitylog_64_pagination_links_rendered | TC-P15 | UI | 60-69 |
| 37 | test_activitylog_65_index_shows_total_count_badge | TC-P15 | UI | 60-69 |
| 38 | test_activitylog_66_search_uses_get_method_and_data_search_url | TC-P13 | UI | 60-69 |
| 39 | test_activitylog_70_null_ip_and_user_agent_allowed | TC-EDG-01 | Edge | 70-79 |
| 40 | test_activitylog_71_unknown_event_falls_back_to_default_style | TC-EDG-02 | Edge | 70-79 |
| 41 | test_activitylog_72_null_subject_type_renders_dash_placeholder | TC-EDG-03 | Edge | 70-79 |
| 42 | test_activitylog_73_missing_user_renders_system_fallback | TC-EDG-04 | Edge | 70-79 |
| 43 | test_activitylog_74_long_user_agent_stored_within_varchar_limit | TC-EDG-05 | Edge | 70-79 |
| 44 | test_activitylog_90_model_user_switches_by_tenancy_state | TC-D06 | Tenancy | 90-99 |
| 45 | test_activitylog_91_properties_free_text_is_escaped_in_view | TC-S03 | Security | 90-99 |
| 46 | test_activitylog_92_xss_payload_in_properties_stored_verbatim | TC-S04 | Security | 90-99 |
| 47 | test_activitylog_93_search_endpoint_probe_returns_dead_or_json_status | TC-S07 | Security | 90-99 |
| 48 | test_activitylog_94_index_http_probe_returns_expected_status_set | TC-N04 | Permissions | 90-99 |

**V1 methods:** 16 · **V2 methods:** 48 · **Ratio:** 3.0× (gate ≥ 2× satisfied).
