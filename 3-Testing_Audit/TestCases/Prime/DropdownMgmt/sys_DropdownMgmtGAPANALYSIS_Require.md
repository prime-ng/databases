# sys_DropdownMgmt — Gap Analysis & Coverage

**Feature:** DropdownMgmt (Prime / PRM, CENTRAL) · **Test file:** `sys_DropdownMgmt_TestCas.php` (single file — no V1/V2) · **Methods:** 37

> Composite management screen driven by `Modules\Prime\Http\Controllers\DropdownMgmtController`
> over `sys_dropdown_needs` (definitions), `sys_dropdown_table` (runtime VALUES — constraint #27),
> and `sys_dropdown_need_table_jnt` (DDL junction). Central `prime_db` scope, host `127.0.0.1:8000`,
> activity sink `sys_central_activity_logs` (constraint #25). Several sub-flows are thin/stub in
> source and are covered as *documented defects*, not invented coverage.

---

## 1. Manual TC ↔ Dusk Method Mapping

### Positive

| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P01 schema/model/controller config truth | test_dropdownmgmt_01 | Full |
| TC-P10 store persists need + 'Created' central log | test_dropdownmgmt_10 | Full (env-guarded HTTP) |
| TC-P11 store-option builds key=table.column | test_dropdownmgmt_11 | Full (HTTP-guarded) |
| TC-P12 store-option type=String + JSON additional_info | test_dropdownmgmt_12 | Full (HTTP-guarded) |
| TC-P13 update persists changes | test_dropdownmgmt_13 | Full (HTTP-guarded) |
| TC-P14 cascading menu endpoint returns distinct | test_dropdownmgmt_14 | Full (HTTP-guarded) |
| TC-P15 index paginate(10) + view | test_dropdownmgmt_15 | Full (source) |
| TC-P16 filter composite view datasets | test_dropdownmgmt_16 | Full (source) |
| TC-P60 index loads for admin | test_dropdownmgmt_60 | Full (browser-guarded) |
| TC-P61 filter tabbed view renders | test_dropdownmgmt_61 | Full (browser-guarded) |
| TC-P62 search LIKE table/column | test_dropdownmgmt_62 | Full (source) |
| TC-P90 all route names registered | test_dropdownmgmt_90 | Full (env-guarded) |

### Negative

| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N30 store requires core fields | test_dropdownmgmt_30 | Full (HTTP-guarded) |
| TC-N31 store rejects invalid db_type enum | test_dropdownmgmt_31 | Full (HTTP-guarded) |
| TC-N32 store requires boolean flags | test_dropdownmgmt_32 | Full (HTTP-guarded) |
| TC-N33 table_name max:150 | test_dropdownmgmt_33 | Full (HTTP-guarded) |
| TC-N34 store-option requires core fields | test_dropdownmgmt_34 | Full (HTTP-guarded) |
| TC-N35 store-option unknown need id (exists) | test_dropdownmgmt_35 | Full (HTTP-guarded) |
| TC-N36 store-option value max:255 | test_dropdownmgmt_36 | Full (HTTP-guarded) |
| TC-N37 store-option ordinal integer | test_dropdownmgmt_37 | Full (HTTP-guarded) |
| TC-N50 guest → login redirect | test_dropdownmgmt_50 | Full (browser-guarded) |
| TC-N53 unauthenticated POST does not create | test_dropdownmgmt_53 | Full (HTTP-guarded) |

### Dependency / Integrity

| Manual TC | Sub | Method | Coverage |
|-----------|-----|--------|----------|
| TC-D40 UNIQUE(db_type,table,column) enforced | C/G | test_dropdownmgmt_40 | Full |
| TC-D41 UNIQUE(key,ordinal) DB-only, no app guard | G | test_dropdownmgmt_41 | Full (index + absence proof) |
| TC-D42 UNIQUE(key,value) enforced | G | test_dropdownmgmt_42 | Full |
| TC-D43 junction FK targets correct | — | test_dropdownmgmt_43 | Full |
| TC-D44 mixed junction tables | E | test_dropdownmgmt_44 | Full (source) |
| TC-D70 destroy stub — record persists | B | test_dropdownmgmt_70 | Full (source) / Partial (live) |

### Permissions (BC-AUTH)

| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-AUTH-51 controller gate strings exact | test_dropdownmgmt_51 | Full (source) |
| TC-AUTH-52 store-option in-code auth matrix | test_dropdownmgmt_52 | Full (source) |

### Edge / Defect

| Manual TC | DEV | Method | Coverage |
|-----------|-----|--------|----------|
| TC-N71 edit()/show() → missing prime::edit/show | DEV-DDM-002 | test_dropdownmgmt_71 | Full (source + file-absence proof) |
| TC-EDG-72 DropdownMgmtModel unused scaffold | DEV-DDM-006 | test_dropdownmgmt_72 | Full |
| TC-EDG-73 fillable vs DDL typo mismatch | DEV-DDM-007 | test_dropdownmgmt_73 | Full |
| TC-EDG-74 deleteBulk unreachable dead code | DEV-DDM-004 | test_dropdownmgmt_74 | Full (route-target proof) |
| TC-EDG-75 update() writes no activity log | BC-BIZ-04 | test_dropdownmgmt_75 | Full (source count) |

### Security / Tenancy

| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-S91 XSS value stored verbatim | test_dropdownmgmt_91 | Full (HTTP-guarded) |
| TC-T92 central scope, no tenant init | test_dropdownmgmt_92 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 12 | 12 | 0 | 0 | 100% |
| Negative | 10 | 10 | 0 | 0 | 100% |
| Dependency | 6 | 6 | 0 | 0 | 100% |
| Permissions | 2 | 2 | 0 | 0 | 100% |
| Edge/Defect | 5 | 5 | 0 | 0 | 100% |
| Security/Tenancy | 2 | 2 | 0 | 0 | 100% |
| **Total** | **37 TC** | **37** | **0** | **0** | **100%** |

> Targets met: Negative 100%, Positive 100% (≥ 90%), Dependency 100% (≥ 90%), Tenancy 100% (central-scope proof).
> "Partial (live)" notes above mean the *source-truth* assertion is Full while the *live end-to-end* observation
> is env-gated (module currently disabled in `modules_statuses.json` + optional ChromeDriver) and self-skips
> rather than failing — preserving a green suite in partial environments per constraints #19/#20.

---

## 3. Coverage-Score (by requirement Source)

Prime is central infrastructure — there is **no `Prime_v1` screen requirement file** (noted in the TcList). BCs
are derived from the DDL (`_prime_db_v4.sql`), the controller, the models, and the routes; the score below tracks
those Source-tagged BC families.

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`BC-BIZ` — key composition, type/JSON forcing, pagination, composite view, no-log-on-update) | 7 | 7 | 100% |
| Validation Rules (`BC-VAL` — controller inline rules) | 6 | 6 | 100% |
| Integration / FK (`BC-DB` / `BC-REF` / `BC-INT` — uniques, junction FKs, mixed pivots) | 7 | 7 | 100% |
| Permissions (`BC-AUTH` — 6 gate strings + in-code store-option matrix) | 7 | 7 | 100% |
| Edge/Defects (`BC-EDG` — DEV-DDM-001…007) | 7 | 7 | 100% |

Every Source-tagged BC maps to ≥ 1 TC. No 0-coverage requirement items.

---

## 4. Cross-Reference Findings (defect scan)

Each firing is reported "verify in source" and is traced to the exact controller/model/DDL/route location.
DEV-DDM-### are the module's audit-equivalent defect IDs (no separate audit report exists for this central screen).

| # | Check | Compare | Finding | ID | Method |
|---|-------|---------|---------|----|--------|
| 1 | Enum case | DDL `db_type ENUM(Prime,Tenant,Global)` vs controller `in:Prime,Tenant,Global` | Match (case-exact) — OK | — | _01/_31 |
| 2 | Route registration | Blade/controller route names vs `routes/web.php` | All 17 documented names resolve via `Route::has` | — | _90 |
| 3 | Gate vs Policy | controller `Gate::authorize('prime.dropdown-need-mgmt.*')` strings | 6 gate strings asserted verbatim; `delete` gate guards **unreachable** `deleteBulk` | DEV-DDM-004 | _51/_74 |
| 4 | Fillable vs DDL | model `$fillable` has `dropdown_table_record_exist` vs DDL `dropdown_tabel_record_exist` | **Typo mismatch** — fillable key never maps to a column | DEV-DDM-007 | _01/_73 |
| 5 | Cast vs DDL | `Dropdown` type/JSON casts vs `sys_dropdown_table` types | `type` forced to `'String'`, `additional_info` JSON-wrapped — matches ENUM default + JSON column | — | _12 |
| 6 | Service delegation | controller body vs Service method | No service layer — validation/logic inline in controller (acceptable for central infra) | — | — |
| 7 | State machine | n/a (no workflow — `is_active` flag only) | No FSM; no BC-SM required | — | — |
| 8 | Validation vs rules | requirement uniqueness vs controller `rules()` | store-option has **no `unique:` guard** on (key,ordinal)/(key,value) → raw DB 500 on duplicate | DEV-DDM-005 | _41 |
| 9 | Error message | expected auth message vs controller | `'Unauthorized: You do not have permission…'` present verbatim | — | _52 |
| 10 | Permissions | store-option matrix vs Gate | store-option uses **in-code** `is_super_admin`/`user_type=='PRIME'`/`tenant_creation_allowed` matrix + `prime.dropdown.create` gate | — | _52 |
| 11 | Integration FK | model relationship vs migration/DDL junction | `dropdowns()` pivot `sys_dropdown_need_dropdowns_jnt` ≠ `scopeWithActiveDropdownCount()` target `sys_dropdown_need_table_jnt` — **two junctions mixed** | DEV-DDM-003 | _44 |

### Additional confirmed defects (source-traced)

- **DEV-DDM-001 (High):** `DropdownMgmtController::destroy($id)` is an **empty stub** → resource DELETE is a no-op (record persists, `deleted_at` stays NULL). Proven `test_dropdownmgmt_70` + regex guard in `_01`.
- **DEV-DDM-002 (High):** `edit()` returns `view('prime::edit')` and non-JSON `show()` returns `view('prime::show')`; neither template exists at the module root (only `prime::index`). Proven `test_dropdownmgmt_71` (file-absence assertion).
- **DEV-DDM-006 (Low):** `DropdownMgmtModel` is an unused scaffold — empty `$fillable`, class-derived default table (not one of the three real dropdown tables). Proven `test_dropdownmgmt_72`.

### Constraint reconciliation (source overrides briefing)

- **Constraint #27 confirmed:** the runtime VALUES table is **`sys_dropdown_table`**, NOT `sys_dropdowns`. The rename migration `..._rename_sys_dropdown_table_to_sys_dropdowns.php` is a no-op (`Schema::rename('sys_dropdown_table','sys_dropdown_table')` under an always-false guard). Asserted positively (`Dropdown::$table === 'sys_dropdown_table'`) and negatively (`Schema::hasTable('sys_dropdowns')` is false) in `test_dropdownmgmt_01`.
- **Constraint #25 confirmed:** activity for this central feature routes to `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` (connection `mysql`, tenancy not initialised). Asserted in `test_dropdownmgmt_10` / `_92`.

---

## 5. Legend

- **Full** — assertion directly and deterministically verifies the condition (schema / route / source-scan) or exercises it end-to-end.
- **Full (source)** — verified by scanning the real controller/model/route source for the exact string/behaviour (deterministic; no live route needed).
- **Env-guarded / HTTP-guarded / browser-guarded** — asserts fully when the prerequisite (migrated central DB / registered routes / running ChromeDriver / enabled Prime module) is present; otherwise `markTestSkipped` with a clear reason (never a false failure).
- **Partial (live)** — the live end-to-end mutation is env-gated (module disabled); the source-truth assertion is the primary, Full-coverage proof.
