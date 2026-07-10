# Activity Log — Test Case List & Business Conditions (`sys_`)

- **Module:** GlobalMaster (GLB) — **Prime / Central** (`prime_db`) — served by the **Prime** module
- **Feature / Screen:** Activity Log (central audit-sink viewer) — **READ-ONLY** list + search
- **Primary table:** `sys_central_activity_logs` (prefix **`sys_`**, *not* `glb_` — flagged, DEV-GLB-A01)
- **Model:** `Modules\Prime\Models\ActivityLog` (connection `mysql`, `HasFactory`, **NO SoftDeletes**)
- **LIVE controller:** `Modules\Prime\Http\Controllers\ActivityLogController` — `index()` `ActivityLog::latest()->paginate(20)` + search filter (`type ∈ {subject,event,user,all}`); view `prime::activity-log.index`
- **DEAD controller (central):** `Modules\GlobalMaster\Http\Controllers\ActivityLogController` — same model, `paginate(10)`, view `globalmaster::activity-log.index` (reconciliation, DEV-GLB-A02)
- **Route:** `Route::resource('activity-log', …)` → name `central.global-master.activity-log.*`, path **`/global-master/activity-log`**, middleware `auth,verified`
- **Gates:** index `prime.activity-log.viewAny`; create/store `prime.activity-log.create`; edit/update `prime.activity-log.update`; destroy `prime.activity-log.delete` (all write gates guard **non-functional stubs**)
- **Test file:** `sys_ActivityLog_TestCas.php` (23 methods, single read-focused suite)
- **Test style:** Browser Dusk, self-contained `extends \Tests\DuskTestCase`, inlined central helpers, host `http://127.0.0.1:8000`; seeding/DB truth via `Modules\Prime\Models\ActivityLog`; NO tenant init.

---

## 1. Business Conditions

### BC-DB (schema / model — Source: `Model` `Modules\Prime\Models\ActivityLog`, central migration, tenant `activity_logs` migration)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Primary table `sys_central_activity_logs`; `getTable()` returns it; prefix `sys_` (NOT `glb_`) | Model:`$table` |
| BC-DB-02 | Model connection is `mysql` (central DB only) | Model:`$connection` |
| BC-DB-03 | `$fillable = [subject_type, subject_id, user_id, event, properties, ip_address, user_agent]` | Model:`$fillable` |
| BC-DB-04 | Cast `properties => array` (JSON at rest) | Model:`$casts` |
| BC-DB-05 | Model uses **NO** `SoftDeletes` (no `deleted_at`; never call `withTrashed/onlyTrashed`) | Model, constraint 05_ |
| BC-DB-06 | Columns present (when table exists): `subject_type, subject_id, user_id, event, properties, ip_address, user_agent, created_at` | Migration (tenant analogue), constraint 17 |
| BC-DB-07 | **DEV-GLB-A01:** `sys_central_activity_logs` has **NO consolidated DDL** in `_prime_db_v4.sql`; schema comes only from a central migration — guarded by `Schema::hasTable` | Audit-MIG, `_prime_db_v4.sql` (absent) |

### BC-REL (relationships — Source: Model)

| ID | Condition | Source |
|----|-----------|--------|
| BC-REL-01 | `subject()` is polymorphic `morphTo()` (any subject model) | Model:40 |
| BC-REL-02 | `user()` is `belongsTo(Modules\Prime\Models\User::class)` — resolves the actor name | Model:45 |

### BC-BIZ (business logic — Source: LIVE Prime controller + blade)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `index()` lists `ActivityLog::latest()->paginate(20)` (newest first) | Controller:24,49 |
| BC-BIZ-02 | Search filter: `type=subject` → `SUBSTRING_INDEX(subject_type,'\\',-1) LIKE %s` | Controller:27 |
| BC-BIZ-03 | Search filter: `type=event` → `event LIKE %s` | Controller:30 |
| BC-BIZ-04 | Search filter: `type=user` → `whereHas('user', name LIKE %s)` | Controller:33 |
| BC-BIZ-05 | Search filter: `type` empty / `all` → subject OR event OR user (combined) | Controller:39 |
| BC-BIZ-06 | `properties` round-trips as an array (message / changes diff rendered) | Model cast + blade:54 |
| BC-BIZ-07 | Empty result renders empty state "No activity logs found." | blade:147 |
| BC-BIZ-08 | Paginator footer with `withQueryString()->links()` (query preserved across pages) | blade:155 |

### BC-AUTH (authorization — Source: `Gate::authorize`, route middleware)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` authorizes `prime.activity-log.viewAny` | Controller:23 |
| BC-AUTH-02 | Route group middleware `auth,verified` — guest redirected to `/login` | GlobalMaster routes/web.php:10 |
| BC-AUTH-03 | Write gates `prime.activity-log.{create,update,delete}` guard **non-functional stubs** (read-only screen) | Controller:60,85,103 |
| BC-AUTH-04 | Central super-admin `Gate::before` resolves dotted abilities (limited-user 403 is bypassed for super-admin) | AppServiceProvider (central) |

### BC-INT (integration — Source: `activityLog()` helper)

| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Central sink receives ALL central writes when tenancy **not** initialised — `activityLog($subject,$event,$props)` → `CentralActivityLog::create()` | `app/Helpers/activityLog.php:39` |
| BC-INT-02 | Cross-feature: Country/Language/Dropdown store/update/delete emit events `Stored/Updated/Trashed/Restored/Deleted/Toggled` into this viewer | Helper + GlobalMaster controllers |

### BC-EDG / cross-reference

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | **DEV-GLB-A03 (cross-ref only):** language `forceDelete` writes the sink with event literal `'Stored'` (wrong event for a delete) — visible as a data-integrity slip in this viewer; defect **owned by the Language feature** | Language controller (cross-module) |
| BC-EDG-02 | XSS-safe render: `subject_type` / `event` are Blade-escaped (`{{ }}`) — stored payload not executed on output | blade:79,80 |

---

## 2. Test Case List

### Positive (`TC-P`)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..05, BC-REL | Model | Schema/model config truth (table, connection, fillable, cast, no-softdeletes, morphTo/belongsTo) | All asserts pass | `_01` | Automated |
| TC-P02 | BC-DB-06 | Migration | Expected columns present (guarded) | Present | `_02` | Automated |
| TC-P03 | BC-DB-07 | Audit | No-DDL gap documented; prefix `sys_` | Documented | `_03` | Automated |
| TC-P04 | BC-BIZ-01 | Controller | `latest()` orders newest first | Newest first | `_10` | Automated |
| TC-P05 | BC-BIZ-06/DB-04 | Model | `properties` casts to array (round-trip) | Array | `_11` | Automated |
| TC-P06 | BC-BIZ-01 | Blade | Seeded log renders in index (subject basename) | Rendered | `_12` | Automated |
| TC-P07 | BC-INT-01/02 | Helper | Central-sink write appears in the list | Rendered | `_13` | Automated |
| TC-P08 | BC-REL-02 | Model | `belongsTo user()` resolves the actor | Resolved | `_14` | Automated |
| TC-P09 | BC-AUTH-01 | Controller | Privileged user reaches index; guest blocked | Reached / blocked | `_50` | Automated |
| TC-P10 | BC-BIZ-01/08 | Blade | Index renders Audit Trail + search/filter controls | Present | `_60` | Automated |
| TC-P11 | BC-BIZ-08 | Controller | Pagination present at 20/page (page=2 link with 21 rows) | Present | `_61` | Automated |
| TC-P12 | BC-BIZ-02 | Controller | Search `type=subject` returns filtered rows | Filtered | `_62` | Automated |
| TC-P13 | BC-BIZ-03 | Controller | Search `type=event` returns filtered rows | Filtered | `_63` | Automated |
| TC-P14 | BC-BIZ-04 | Controller | Search `type=user` returns filtered rows | Filtered | `_64` | Automated |
| TC-P15 | BC-BIZ-05 | Controller | Search `all` (empty type) returns filtered rows | Filtered | `_65` | Automated |

### Negative (`TC-N`)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-AUTH-02 | Middleware | Guest redirected to `/login` | `/login` | `_30` | Automated |
| TC-N02 | BC-AUTH-01/04 | Gate | Limited user denied by `viewAny` (defensive; super-admin bypass self-skips) | 403 / skip | `_31` | Automated (defensive) |
| TC-N03 | BC-EDG-02 | Blade | XSS payload in subject/event escaped on render | Escaped | `_32` | Automated |
| TC-N04 | BC-BIZ-07 | Blade | Improbable search → empty state | "No activity logs found." | `_66` | Automated |

### Dependency / Reconciliation / Security (`TC-D` / `TC-S` / `TC-T`)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-D01 | BC-AUTH-03 | Controller | Write methods are gated stubs (read-only) | Documented | `_51` | Automated |
| TC-D02 | BC-BIZ-01 | Controller | Two-controller reconciliation (Prime 20 live / GlobalMaster 10 dead) | Documented | `_52` | Automated |
| TC-D03 | BC-EDG-01 | Cross-ref | Wrong event `'Stored'` (Language forceDelete) visible in sink (DEV-GLB-A03) | Rendered verbatim | `_70` | Automated |
| TC-T01 | BC-INT-01 | Base | Runs in central context, tenancy not initialised | Not initialised | `_90` | Automated |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `_01_schema_and_model_configuration_are_correct` | TC-P01 | Config | 01–09 |
| 2 | `_02_expected_columns_present` | TC-P02 | Config | 01–09 |
| 3 | `_03_no_consolidated_ddl_gap_is_documented` | TC-P03 | Config | 01–09 |
| 4 | `_10_latest_orders_newest_first` | TC-P04 | BIZ | 10–19 |
| 5 | `_11_properties_cast_to_array` | TC-P05 | BIZ | 10–19 |
| 6 | `_12_seeded_log_renders_in_index` | TC-P06 | BIZ | 10–19 |
| 7 | `_13_central_sink_write_appears_in_list` | TC-P07 | INT | 10–19 |
| 8 | `_14_user_relationship_resolves_actor_name` | TC-P08 | REL | 10–19 |
| 9 | `_30_guest_is_redirected_to_login` | TC-N01 | AUTH | 30–39 |
| 10 | `_31_index_requires_viewany_permission` | TC-N02 | AUTH | 30–39 |
| 11 | `_32_xss_safe_render_of_event_and_subject` | TC-N03 | Security | 30–39 |
| 12 | `_50_index_gate_allows_privileged_and_blocks_guest` | TC-P09 | AUTH | 50–59 |
| 13 | `_51_write_methods_are_gated_stubs` | TC-D01 | AUTH | 50–59 |
| 14 | `_52_two_controllers_reconciliation` | TC-D02 | Recon | 50–59 |
| 15 | `_60_index_renders_audit_trail` | TC-P10 | UIX | 60–69 |
| 16 | `_61_pagination_present_at_twenty_per_page` | TC-P11 | UIX | 60–69 |
| 17 | `_62_search_by_subject_returns_filtered` | TC-P12 | UIX | 60–69 |
| 18 | `_63_search_by_event_returns_filtered` | TC-P13 | UIX | 60–69 |
| 19 | `_64_search_by_user_returns_filtered` | TC-P14 | UIX | 60–69 |
| 20 | `_65_search_all_type_returns_filtered` | TC-P15 | UIX | 60–69 |
| 21 | `_66_empty_state_renders` | TC-N04 | UIX | 60–69 |
| 22 | `_70_wrong_event_string_is_visible_in_sink` | TC-D03 | EDG | 70–79 |
| 23 | `_90_runs_in_central_context_without_tenant` | TC-T01 | Tenancy | 90–99 |

---

## 4. Known Source Defects (DEV-###)

| DEV | Sev | Status | Description | Proving method |
|-----|-----|--------|-------------|----------------|
| DEV-GLB-A01 | P2 | **Open** | `sys_central_activity_logs` has NO consolidated DDL (schema only from a central migration); prefix is `sys_` not `glb_` | `_01`, `_02`, `_03` (Schema::hasTable guard) |
| DEV-GLB-A02 | P3 | **Open** | `create/store/edit/update/destroy` gated but non-functional stubs; two controllers (Prime live `paginate(20)` vs GlobalMaster dead `paginate(10)`) | `_51`, `_52` |
| DEV-GLB-A03 | P2 | **Open (cross-ref)** | Central sink receives event `'Stored'` from Language `forceDelete` (wrong event) — data-integrity slip visible here; **defect owned by the Language feature** | `_70` (cross-reference only) |
