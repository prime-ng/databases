# sys_DropdownMgmt — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — **CENTRAL** (`prime_db`), host `http://127.0.0.1:8000` |
| Feature | DropdownMgmt (composite: dropdown needs + dropdown values) |
| Index URL | `http://127.0.0.1:8000/global-master/dropdown-mgmt` |
| Filter/composite URL | `http://127.0.0.1:8000/global-master/dropdown/filter` |
| Controller | `Modules\Prime\Http\Controllers\DropdownMgmtController` |
| Models | `DropdownNeed` (sys_dropdown_needs), `Dropdown` (sys_dropdown_table), `DropdownNeedTableJnt` (sys_dropdown_need_table_jnt), `DropdownNeedDropdown` (sys_dropdown_need_dropdowns_jnt) |
| Validation | Inline in controller (no FormRequest) |
| CRUD type | Composite (needs = full-ish; values = create-only via storeDropdownOption; destroy = **stub**) |
| Soft delete | `DropdownNeed` + `Dropdown` use SoftDeletes; controller destroy does NOT soft-delete (stub) |
| Pagination | 10 / page (needs and values) |
| Activity log | Central `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog`; event `Created` on store() only |

**Environment prerequisites**
- Prime/central module enabled; run on `http://127.0.0.1:8000` (constraint #21) — the base `prm_PrimeDuskTestCase_TestCas` `$this->fail()`s on any other host.
- `APP_ENV=testing` (CSRF bypass) for authenticated mutating flows.
- Tenancy NOT initialised for this feature (central scope).

---

## 2. Business Conditions (detailed)

- **db_type ENUM** must be exactly one of `Prime`, `Tenant`, `Global` (case-sensitive — constraint #18).
- **Key composition:** a dropdown value's `key` = `{table_name}.{column_name}` of its parent need (e.g. `cmp_complaint_actions.action_type`).
- **Uniqueness:** need = UNIQUE(db_type, table_name, column_name) and UNIQUE(menu_category, main_menu, sub_menu, tab_name, field_name); value = UNIQUE(key, ordinal) and UNIQUE(key, value).
- **storeDropdownOption authorization:** super-admin OR `user_type=='PRIME'` OR (`user_type` ∈ {TEACHER, EMPLOYEE} AND parent need `tenant_creation_allowed=1`); otherwise HTTP 403 with message `Unauthorized: You do not have permission to create options for this dropdown.`
- **Activity flow (store):** create need → `activityLog($need,'Created',['message'=>'Dropdown need created successfully'])` → new row in `sys_central_activity_logs` with `event='Created'`, `subject_id=need.id`.
- **Known defective flows** (see §Defects): destroy no-op; edit/show missing views; mixed junction tables; unreachable deleteBulk; no duplicate-guard on option store; scaffold model; fillable/DDL typo.

---

## 3. Manual Test Cases

### MTC-01 — Create a dropdown need (happy path) — [TC-P10]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as super-admin; open `/global-master/dropdown-mgmt` | Composite screen loads (no 403/404/login) |
| 2 | Submit POST to `/global-master/dropdown-mgmt` with db_type=Prime, unique table/column, all boolean flags | 302 redirect to `central.global-master.dropdown-mgmt.index` with success flash |
| 3 | DB check | `SELECT * FROM sys_dropdown_needs WHERE table_name=? AND column_name=?` → 1 row |
| 4 | Activity check | `SELECT * FROM sys_central_activity_logs WHERE event='Created' AND subject_id=<id>` → 1 row |

### MTC-02 — Create a dropdown value (option) — [TC-P11/P12]
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/global-master/dropdown/store-option` {dropdown_needs_id, ordinal:1, value:"Active", additional_info:"x"} | 200 `{status:true, message:"Dropdown option saved successfully"}` |
| 2 | DB check | `sys_dropdown_table` row with `key='<table>.<column>'`, `type='String'`, `additional_info` JSON `{"info":"x"}` |

### MTC-03 — Validation: store required fields — [TC-N30..N33]
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST store with empty body | 302 back with errors on db_type, table_name, column_name |
| 2 | POST store db_type=Cloud | error on db_type (enum) |
| 3 | POST store without flags | errors on is_system, compulsory, is_active, tenant_creation_allowed |
| 4 | POST store table_name=151 chars | error on table_name |

### MTC-04 — Validation: store-option — [TC-N34..N37]
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST store-option {} | 422 errors dropdown_needs_id, ordinal, value |
| 2 | POST store-option dropdown_needs_id=999999999 | 422 error dropdown_needs_id (exists) |
| 3 | POST store-option value=256 chars | 422 error value |
| 4 | POST store-option ordinal="abc" | 422 error ordinal |

### MTC-05 — Uniqueness — [TC-D40..D42]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create need A, then create need B with same (db_type,table,column) | Integrity/duplicate exception; B not created |
| 2 | Inspect `SHOW INDEX FROM sys_dropdown_table` | UNIQUE(key,ordinal) and UNIQUE(key,value) present |

### MTC-06 — Permissions — [TC-N50/N53/AUTH-52]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/global-master/dropdown-mgmt` logged out | Redirect to `/login` |
| 2 | POST store logged out | No record created |
| 3 | store-option as user_type OTHER on need with tenant_creation_allowed=0 | 403 "Unauthorized: You do not have permission…" |

### MTC-07 — Cascading menus — [TC-P14]
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/global-master/dropdown-mgmt/menus/by-category/{category}` | 200 JSON list of distinct main menus |

### MTC-08 — Defect confirmations — [TC-D70/N71/EDG-72..75]
| Step | Action | Expected (current behaviour) |
|------|--------|------------------------------|
| 1 | DELETE `/global-master/dropdown-mgmt/{id}` | No-op: record still present, `deleted_at` NULL (DEV-DDM-001) |
| 2 | GET edit route (HTML) | View error `prime::edit` not found (DEV-DDM-002) |
| 3 | Inspect `DropdownMgmtModel` | Empty `$fillable`, default table (DEV-DDM-006) |
| 4 | `SHOW COLUMNS FROM sys_dropdown_needs LIKE 'dropdown_table_record_exist'` | 0 rows (DDL column is `dropdown_tabel_record_exist`) (DEV-DDM-007) |
| 5 | Update a need | No new `sys_central_activity_logs` row (update doesn't log) (BC-BIZ-04) |

### MTC-09 — Security — [TC-S91]
| Step | Action | Expected |
|------|--------|----------|
| 1 | store-option value=`<script>alert(1)</script>` | Value stored verbatim; must be escaped at render time (no stored-XSS execution) |
