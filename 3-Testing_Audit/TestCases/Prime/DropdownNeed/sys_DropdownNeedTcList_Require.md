# sys_DropdownNeed — Business Conditions & Test Case List

**Module:** Prime (PRM) · **Feature/Screen:** DropdownNeed · **DB scope:** CENTRAL (`prime_db`, no tenant init)
**Primary table:** `sys_dropdown_needs` (prefix `sys_` — DDL/migration verified) · **Host:** `http://127.0.0.1:8000`
**Controller:** `Modules\Prime\Http\Controllers\DropdownNeedController` · **Model:** `Modules\Prime\Models\DropdownNeed`
**Junctions:** `sys_dropdown_need_dropdowns_jnt` (mapping — model relationship), `sys_dropdown_need_table_jnt` (legacy — delete/restore/toggle)
**Route name prefix:** `central.global-master.dropdown-need.*` · **Activity sink:** `sys_central_activity_logs` (central)
**Test style:** central browser Dusk (`extends PrimeDuskTestCase`) with in-process Schema/Route/source-scan + HTTP guards.

> Screen requirement source: `4-Requirement_Module_wise/2-Module_Requirement_V1/SystemConfig/01-Dropdown-Needs.md`.

---

## 1. Business Conditions

### BC-DB — Schema (Source: DDL `_prime_db_v4.sql` + runtime migration `2025_11_16_114617_create_sys_dropdown_needs_table.php`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `sys_dropdown_needs` exists with columns id, db_type, table_name, column_name, menu_category, main_menu, sub_menu, tab_name, field_name, is_system, tenant_creation_allowed, dropdown_table_record_exist, compulsory, is_active, deleted_at, timestamps | DDL-sys_dropdown_needs |
| BC-DB-02 | `db_type` ENUM('Prime','Tenant','Global'); table/column/menu_category/main/sub varchar(150); tab_name/field_name varchar(100) | DDL |
| BC-DB-03 | Composite UNIQUE on (db_type, table_name, column_name) = `uq_dropdownNeeds_db_table_column_key` | DDL/Migration |
| BC-DB-04 | Soft delete: model `use SoftDeletes`; migration `softDeletes()`; runtime `deleted_at` present | REL_MODEL/REL_MIGRATION |
| BC-DB-05 | Model fillable + boolean casts for is_system, tenant_creation_allowed, compulsory, dropdown_table_record_exist, is_active | REL_MODEL |
| BC-DB-06 | Mapping junction `sys_dropdown_need_dropdowns_jnt` (dropdown_needs_id, dropdown_table_id, is_active) FK RESTRICT, unique pair | REL_JNT_MAP_MIGRATION |
| BC-DB-07 | Legacy junction `sys_dropdown_need_table_jnt` FK CASCADE, unique per need & per table | REL_JNT_LEGACY_MIGRATION |
| BC-DB-08 | Runtime CHECK `chk_dropdown_needs_valid` enforces tenant_creation_allowed ↔ menu-field consistency | REL_MIGRATION |

### BC-VAL — Validation (Source: inline `$request->validate()` in controller — NO FormRequest)

| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `db_type` required, in:Prime,Tenant,Global | Screen-VR / REL_CONTROLLER store()/update() |
| BC-VAL-02 | `table_name` required, string, max:150 | REL_CONTROLLER |
| BC-VAL-03 | `column_name` required, string, max:150 | REL_CONTROLLER |
| BC-VAL-04 | `tenant_creation_allowed` required, boolean | REL_CONTROLLER |
| BC-VAL-05 | `is_system`, `compulsory` required, boolean | REL_CONTROLLER |
| BC-VAL-06 | When `tenant_creation_allowed` truthy → menu_category, main_menu, sub_menu required max:150; tab_name, field_name required max:100 | Screen-BR / REL_CONTROLLER |
| BC-VAL-07 | `toggleStatus`: `is_active` required, boolean | REL_CONTROLLER |
| BC-VAL-08 | No uniqueness rule → duplicate (db_type,table,column) hits DB unique = 500 (**BUG-PRM-DDNEED-003**) | DDL vs REL_CONTROLLER |

### BC-AUTH — Authorization (Source: controller `Gate::authorize` + `RolePermissionSeeder`, guard `web`)

| ID | Method → Gate | Source |
|----|---------------|--------|
| BC-AUTH-01 | index / filterOptions → `prime.dropdown.viewAny` (**sibling gate — BUG-PRM-DDNEED-006**) | REL_CONTROLLER |
| BC-AUTH-02 | create / store → `prime.dropdown-need.create` | REL_CONTROLLER |
| BC-AUTH-03 | show → `prime.dropdown-need.view` | REL_CONTROLLER |
| BC-AUTH-04 | edit / update / toggleStatus → `prime.dropdown-need.update` | REL_CONTROLLER |
| BC-AUTH-05 | destroy → `prime.dropdown-need.delete` | REL_CONTROLLER |
| BC-AUTH-06 | trashed / restore → `prime.dropdown-need.restore` | REL_CONTROLLER |
| BC-AUTH-07 | forceDelete → `prime.dropdown-need.forceDelete` | REL_CONTROLLER |
| BC-AUTH-08 | AJAX (search, migration-tables, table-columns, migration-content, menu-data, main-menus, sub-menus) → **NO Gate** (**SEC-PRM-004**) | REL_CONTROLLER + routes |

### BC-BIZ — Business logic / activity (Source: controller/model + Screen)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Activity events (verbatim): store→`Created`, update→`Updated`, destroy→`Trashed`, restore→`Restored`, forceDelete→`Deleted`, toggleStatus→`Toggled` | REL_CONTROLLER |
| BC-BIZ-02 | `is_system` records cannot be edited/deleted (redirect with error) | Screen-BR / REL_CONTROLLER |
| BC-BIZ-03 | When tenant_creation_allowed=false, menu fields nulled before persist | REL_CONTROLLER |
| BC-BIZ-04 | destroy: soft-delete + flip legacy junction is_active=false | REL_CONTROLLER |
| BC-BIZ-05 | restore: restore + is_active=true + reactivate legacy junction | REL_CONTROLLER |
| BC-BIZ-06 | store/update/destroy redirect to `dropdown.index` (**BUG-PRM-DDNEED-004**) | REL_CONTROLLER |
| BC-BIZ-07 | toggleStatus returns JSON `{success,is_active,message}` | REL_CONTROLLER |

### BC-INT / BC-REF — Integration & FK

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | Mapping junction FK → sys_dropdown_needs / sys_dropdown_table, RESTRICT | REL_JNT_MAP_MIGRATION |
| BC-REF-02 | Legacy junction FK CASCADE on delete | REL_JNT_LEGACY_MIGRATION |
| BC-INT-01 | **Junction mismatch** — mappings read from `sys_dropdown_need_dropdowns_jnt`; destroy/restore/toggle mutate `sys_dropdown_need_table_jnt` (**BUG-PRM-DDNEED-001**) | REL_MODEL vs REL_CONTROLLER |
| BC-INT-02 | forceDelete removes legacy junction rows before force-deleting need | REL_CONTROLLER |

### BC-EDG — Edge / boundary

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | XSS payload persisted verbatim (escaped only at render) | Screen / TC-S |
| BC-EDG-02 | Runtime has ONE unique index; DDL's 2nd (menu-path) unique NOT created → duplicate menu paths not DB-blocked | REL_MIGRATION |
| BC-EDG-03 | No trim/prepareForValidation → whitespace passes `string` rule | REL_CONTROLLER |
| BC-EDG-04 | Over-length (>150) table_name rejected | REL_CONTROLLER |

### BC-CFG — Configuration / defect corrections

| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | SEC-PRM-004 correction: `filterOptions()` IS gated and has NO route (dead code) | REL_CONTROLLER + routes |
| BC-CFG-02 | TEN-PRM-001 correction: fetchMigrationTables/fetchTableColumns call `tenancy()->end()` in `finally` (no leak) | REL_CONTROLLER |
| BC-CFG-03 | PERF-PRM-001: raw `SHOW COLUMNS`/`SHOW TABLES` on AJAX; Prime/Global cached 1h, Tenant uncached | REL_CONTROLLER |
| BC-CFG-04 | BUG-PRM-DUP correction: single canonical model; no stale root-level model | filesystem |
| BC-CFG-05 | DOC-PRM-DDNEED-002: DDL misspells column `dropdown_tabel_record_exist` + omits deleted_at; runtime correct | DDL vs REL_MIGRATION |
| BC-CFG-06 | BUG-PRM-DDNEED-005: dropdown-need routes registered twice in routes/web.php | routes/web.php |

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..08 | DDL/Migration | Schema/model/migration config truth | All columns/index/softdelete present | test_dropdownneed_01 | Automated |
| TC-P02 | BC-DB-02 | Migration | Column types within DDL limits | varchar sizes exact | test_dropdownneed_02 | Automated |
| TC-P03 | BC-DB-03 | Migration | Composite unique index exists | uq present | test_dropdownneed_03 | Automated |
| TC-P04 | BC-DB-04 | Model/Migration | Soft delete supported | deleted_at + trait | test_dropdownneed_04 | Automated |
| TC-P05 | BC-DB-05 | Model | Fillable + boolean casts | present | test_dropdownneed_05 | Automated |
| TC-P06 | BC-DB-06 | Migration | Mapping junction schema | correct | test_dropdownneed_06 | Automated |
| TC-P07 | BC-DB-07 | Migration | Legacy junction schema | correct | test_dropdownneed_07 | Automated |
| TC-P08 | BC-DB-08 | Migration | CHECK constraint present | present | test_dropdownneed_09 | Automated |
| TC-P09 | BC-BIZ-01 | Controller | Activity event strings verbatim | Created/Updated/Trashed/Restored/Deleted/Toggled | test_dropdownneed_10 | Automated |
| TC-P10 | BC-BIZ-01 | Controller | Store creates + logs Created | 302 + row persisted | test_dropdownneed_11 | Automated (guarded) |
| TC-P11 | BC-BIZ-03 | Controller | Menu fields nulled when disallowed | null | test_dropdownneed_13 | Automated |
| TC-P12 | BC-BIZ-04 | Controller | Destroy soft-deletes + junction | delete() | test_dropdownneed_14 | Automated |
| TC-P13 | BC-BIZ-05 | Controller | Restore reactivates | restore() | test_dropdownneed_15 | Automated |
| TC-P14 | BC-BIZ-07 | Controller | toggleStatus JSON contract | validated + JSON | test_dropdownneed_20 | Automated |
| TC-P15 | BC-UIX | routes | All named routes registered | Route::has true | test_dropdownneed_60 | Automated (guarded) |
| TC-P16 | BC-UIX | Blade | Create form selectors present | present | test_dropdownneed_62 | Automated (browser) |
| TC-P17 | BC-UIX | View | Index reachable for admin | 200 | test_dropdownneed_63 | Automated (browser) |
| TC-P18 | BC-UIX | View | Trash reachable | table present | test_dropdownneed_64 | Automated (browser) |
| TC-P19 | Constraint#25 | Helper | Central activity sink schema | sys_central_activity_logs | test_dropdownneed_95 | Automated (guarded) |

### Negative (TC-N)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01/02/03/04 | Controller | Required fields declared | rules present | test_dropdownneed_30 | Automated |
| TC-N02 | BC-VAL-01 | Controller | db_type enum rejects invalid | 302 errors/422 | test_dropdownneed_31 | Automated (guarded) |
| TC-N03 | BC-VAL-02/03 | Controller | max length rules present | max:150/100 | test_dropdownneed_32 | Automated |
| TC-N04 | BC-VAL-05 | Controller | boolean flags required | rules present | test_dropdownneed_33 | Automated |
| TC-N05 | BC-VAL-06 | Controller | Conditional menu-field requirement | rules present | test_dropdownneed_34 | Automated |
| TC-N06 | BC-VAL-08 | DDL vs Controller | No unique validation (dup → 500) | absence proven | test_dropdownneed_35 | Automated |
| TC-N07 | BC-VAL-01 | Controller | update() rules present | ≥2 db_type rules | test_dropdownneed_36 | Automated |
| TC-N08 | BC-EDG-04 | Controller | Over-length table_name rejected | error | test_dropdownneed_73 | Automated (guarded) |
| TC-N09 | BC-AUTH-02 | Seeder | Fresh user denied create | denies | test_dropdownneed_51 | Automated (guarded) |
| TC-N10 | BC-AUTH-* | Seeder | Fresh user denied all gates | denies | test_dropdownneed_52 | Automated (guarded) |
| TC-N11 | BC-AUTH | Middleware | Guest redirected from index | /login | test_dropdownneed_55 | Automated (browser) |
| TC-N12 | TC-S | Controller | Unknown id → 404 (IDOR) | not 200 | test_dropdownneed_94 | Automated (guarded) |

### Dependency (TC-D)

| TC ID | Sub | BC | Source | Description | Method | Status |
|-------|-----|----|--------|-------------|--------|--------|
| TC-D01 | C | BC-REF-01 | Migration | Mapping junction FK RESTRICT | test_dropdownneed_40 | Automated |
| TC-D02 | B | BC-REF-02 | Migration | Legacy junction FK CASCADE | test_dropdownneed_41 | Automated |
| TC-D03 | E | BC-INT-01 | Model/Controller | Junction mismatch proof (BUG-PRM-DDNEED-001) | test_dropdownneed_42 | Automated |
| TC-D04 | B | BC-INT-02 | Controller | forceDelete removes legacy junction first | test_dropdownneed_43 | Automated |
| TC-D05 | F | BC-BIZ-02 | Controller | is_system protection lifecycle | test_dropdownneed_12 | Automated |

### Security / Defect proofs (TC-S)

| TC ID | BC | Source | Description | Method | Status |
|-------|----|--------|-------------|--------|--------|
| TC-S01 | BC-AUTH-08 | Controller | Registered AJAX endpoints ungated (SEC-PRM-004) | test_dropdownneed_53 | Automated |
| TC-S02 | BC-CFG-01 | Controller | filterOptions gated + dead (SEC-PRM-004 correction) | test_dropdownneed_90 | Automated |
| TC-S03 | BC-CFG-02 | Controller | Tenant AJAX helpers end() tenancy (TEN-PRM-001 correction) | test_dropdownneed_91 | Automated |
| TC-S04 | BC-CFG-03 | Controller | Raw SHOW queries (PERF-PRM-001) | test_dropdownneed_92 | Automated |
| TC-S05 | BC-CFG-04 | filesystem | Single canonical model (BUG-PRM-DUP correction) | test_dropdownneed_93 | Automated |
| TC-S06 | BC-EDG-01 | Controller | XSS stored verbatim | test_dropdownneed_70 | Automated (guarded) |

### Edge / config (TC-E)

| TC ID | BC | Source | Description | Method | Status |
|-------|----|--------|-------------|--------|--------|
| TC-E01 | BC-CFG-05 | DDL vs Migration | DDL typo documented / runtime correct | test_dropdownneed_08 | Automated |
| TC-E02 | BC-EDG-02 | Migration | Duplicate menu-path not DB-blocked | test_dropdownneed_71 | Automated |
| TC-E03 | BC-EDG-03 | Controller | No whitespace trimming | test_dropdownneed_72 | Automated |
| TC-E04 | BC-BIZ-06 | Controller | Redirect to dropdown.index (BUG-PRM-DDNEED-004) | test_dropdownneed_16 | Automated |
| TC-E05 | BC-AUTH-01 | Controller | index uses sibling viewAny gate (BUG-PRM-DDNEED-006) | test_dropdownneed_17 | Automated |
| TC-E06 | BC-CFG-06 | routes | Duplicate route group (BUG-PRM-DDNEED-005) | test_dropdownneed_65 | Automated |
| TC-E07 | BC-UIX | routes | Dead controller methods unregistered | test_dropdownneed_61 | Automated (guarded) |
| TC-E08 | BC-AUTH | Seeder | Super admin allowed gates | test_dropdownneed_54 | Automated (guarded) |
| TC-E09 | BC-AUTH-01 | Controller | Gate strings verbatim | test_dropdownneed_50 | Automated |

---

## 3. Test Method Index (bands)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_dropdownneed_01 | TC-P01 | Schema/config | 01–09 |
| 2 | test_dropdownneed_02 | TC-P02 | Schema | 01–09 |
| 3 | test_dropdownneed_03 | TC-P03 | Schema | 01–09 |
| 4 | test_dropdownneed_04 | TC-P04 | Schema | 01–09 |
| 5 | test_dropdownneed_05 | TC-P05 | Schema | 01–09 |
| 6 | test_dropdownneed_06 | TC-P06 | Schema | 01–09 |
| 7 | test_dropdownneed_07 | TC-P07 | Schema | 01–09 |
| 8 | test_dropdownneed_08 | TC-E01 | DDL correction | 01–09 |
| 9 | test_dropdownneed_09 | TC-P08 | Schema | 01–09 |
| 10 | test_dropdownneed_10 | TC-P09 | Business rules | 10–19 |
| 11 | test_dropdownneed_11 | TC-P10 | Business rules | 10–19 |
| 12 | test_dropdownneed_12 | TC-D05 | Business rules | 10–19 |
| 13 | test_dropdownneed_13 | TC-P11 | Business rules | 10–19 |
| 14 | test_dropdownneed_14 | TC-P12 | Business rules | 10–19 |
| 15 | test_dropdownneed_15 | TC-P13 | Business rules | 10–19 |
| 16 | test_dropdownneed_16 | TC-E04 | Business rules | 10–19 |
| 17 | test_dropdownneed_17 | TC-E05 | Business rules | 10–19 |
| 18 | test_dropdownneed_20 | TC-P14 | Status toggle | 20–29 |
| 19 | test_dropdownneed_30 | TC-N01 | Validation | 30–39 |
| 20 | test_dropdownneed_31 | TC-N02 | Validation | 30–39 |
| 21 | test_dropdownneed_32 | TC-N03 | Validation | 30–39 |
| 22 | test_dropdownneed_33 | TC-N04 | Validation | 30–39 |
| 23 | test_dropdownneed_34 | TC-N05 | Validation | 30–39 |
| 24 | test_dropdownneed_35 | TC-N06 | Validation | 30–39 |
| 25 | test_dropdownneed_36 | TC-N07 | Validation | 30–39 |
| 26 | test_dropdownneed_40 | TC-D01 | FK dependency | 40–49 |
| 27 | test_dropdownneed_41 | TC-D02 | FK dependency | 40–49 |
| 28 | test_dropdownneed_42 | TC-D03 | Integration | 40–49 |
| 29 | test_dropdownneed_43 | TC-D04 | Integration | 40–49 |
| 30 | test_dropdownneed_50 | TC-E09 | Permissions | 50–59 |
| 31 | test_dropdownneed_51 | TC-N09 | Permissions | 50–59 |
| 32 | test_dropdownneed_52 | TC-N10 | Permissions | 50–59 |
| 33 | test_dropdownneed_53 | TC-S01 | Permissions/security | 50–59 |
| 34 | test_dropdownneed_54 | TC-E08 | Permissions | 50–59 |
| 35 | test_dropdownneed_55 | TC-N11 | Permissions | 50–59 |
| 36 | test_dropdownneed_60 | TC-P15 | UI/routing | 60–69 |
| 37 | test_dropdownneed_61 | TC-E07 | UI/routing | 60–69 |
| 38 | test_dropdownneed_62 | TC-P16 | UI | 60–69 |
| 39 | test_dropdownneed_63 | TC-P17 | UI | 60–69 |
| 40 | test_dropdownneed_64 | TC-P18 | UI | 60–69 |
| 41 | test_dropdownneed_65 | TC-E06 | UI/routing | 60–69 |
| 42 | test_dropdownneed_70 | TC-S06 | Edge/security | 70–79 |
| 43 | test_dropdownneed_71 | TC-E02 | Edge | 70–79 |
| 44 | test_dropdownneed_72 | TC-E03 | Edge | 70–79 |
| 45 | test_dropdownneed_73 | TC-N08 | Edge | 70–79 |
| 46 | test_dropdownneed_90 | TC-S02 | Security | 90–99 |
| 47 | test_dropdownneed_91 | TC-S03 | Tenancy | 90–99 |
| 48 | test_dropdownneed_92 | TC-S04 | Performance | 90–99 |
| 49 | test_dropdownneed_93 | TC-S05 | Security | 90–99 |
| 50 | test_dropdownneed_94 | TC-N12 | Security | 90–99 |
| 51 | test_dropdownneed_95 | TC-P19 | Tenancy/sink | 90–99 |

## 4. Known Source Defects (audit-equivalent)

| ID | Sev | Summary | Proving method |
|----|-----|---------|----------------|
| SEC-PRM-004 | P1 | Registered AJAX endpoints (search/migration-tables/table-columns/migration-content/menu-data/main-menus/sub-menus) carry NO Gate — leak DB schema/menu structure to any authenticated user. (Audit's specific claim about `filterOptions()` is corrected: that method is gated + routeless.) | test_dropdownneed_53, _90 |
| TEN-PRM-001 | P1 | (Corrected) tenant AJAX helpers DO `tenancy()->end()` in a `finally` — no context leak in current source. | test_dropdownneed_91 |
| PERF-PRM-001 | P2 | Raw `SHOW COLUMNS`/`SHOW TABLES` per AJAX call (Prime/Global cached 1h, Tenant uncached). | test_dropdownneed_92 |
| BUG-PRM-DUP | P2 | (Corrected) No stale root-level model; single canonical `app/Models/DropdownNeed.php`. | test_dropdownneed_93 |
| BUG-PRM-DDNEED-001 | P1 | Junction mismatch — mappings read from `sys_dropdown_need_dropdowns_jnt`, but destroy/restore/toggle mutate `sys_dropdown_need_table_jnt`, so status changes don't affect displayed mappings. | test_dropdownneed_42, _14 |
| BUG-PRM-DDNEED-003 | P2 | No uniqueness validation → duplicate (db_type,table,column) surfaces as DB 500 not a friendly error. | test_dropdownneed_35 |
| BUG-PRM-DDNEED-004 | P3 | store/update/destroy redirect to `dropdown.index` not `dropdown-need.index`. | test_dropdownneed_16 |
| BUG-PRM-DDNEED-005 | P3 | dropdown-need routes registered twice in routes/web.php. | test_dropdownneed_65 |
| BUG-PRM-DDNEED-006 | P3 | index() gated by sibling `prime.dropdown.viewAny`. | test_dropdownneed_17 |
| DOC-PRM-DDNEED-002 | P3 | DDL misspells `dropdown_tabel_record_exist` + omits deleted_at; runtime migration correct. | test_dropdownneed_08 |
