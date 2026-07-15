# sys_DropdownNeed — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Prime (PRM) — Global Master / Core Configuration |
| Feature / Screen | DropdownNeed (defines which table+column need a dropdown) |
| DB scope | **CENTRAL** (`prime_db`) — no tenant initialization |
| Host | `http://127.0.0.1:8000` (Prime tests hard-require 127.0.0.1) |
| Index URL | `/global-master/dropdown-need` → renders `prime::index` combined mgmt screen |
| Create URL | `/global-master/dropdown-need/create` |
| Trash URL | `/global-master/dropdown-need/trash/view` |
| Route name prefix | `central.global-master.dropdown-need.*` |
| Controller | `Modules\Prime\Http\Controllers\DropdownNeedController` |
| Models | `DropdownNeed` (`sys_dropdown_needs`), `DropdownNeedTableJnt` (`sys_dropdown_need_table_jnt`), `DropdownNeedDropdown` (`sys_dropdown_need_dropdowns_jnt`) |
| Validation | Inline `$request->validate()` — **no dedicated FormRequest** |
| Migration | `database/migrations/2025_11_16_114617_create_sys_dropdown_needs_table.php` (central) |
| Soft delete | Yes (`SoftDeletes`, `deleted_at`) |
| Pagination | 10/page (`needs_page` on the combined index) |
| Activity log | Central `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` (events: Created, Updated, Trashed, Restored, Deleted, Toggled) |
| CRUD type | Resource + trash/restore/forceDelete/toggleStatus + AJAX schema/menu helpers |

**Environment prerequisites:** Prime module must be `true` in `prime_testing/modules_statuses.json` (currently `false` → all routes 404); `APP_ENV=testing` (bypasses CSRF); admin creds `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`.

---

## 2. Business Conditions (detailed)

### Create flow (store)
Validation rules (from controller):
```
db_type                  → required|in:Prime,Tenant,Global
table_name               → required|string|max:150
column_name              → required|string|max:150
tenant_creation_allowed  → required|boolean
is_system                → required|boolean
compulsory               → required|boolean
menu_category/main_menu/sub_menu → nullable|string|max:150  (REQUIRED when tenant_creation_allowed)
tab_name/field_name              → nullable|string|max:100  (REQUIRED when tenant_creation_allowed)
dropdown_table_record_exist / is_active → nullable|boolean
```
Post-validate logic: if `tenant_creation_allowed` is false, all five menu fields are forced to `null`. `is_active` defaults true. On success → `activityLog($need,'Created')` then **redirect to `central.global-master.dropdown.index`** (BUG-PRM-DDNEED-004) with success flash.

### is_system protection
`edit`, `update`, `destroy` short-circuit when `is_system` is truthy → redirect with error `System records cannot be edited.` / `System records cannot be deleted.`

### Delete / restore / toggle
- `destroy` → set legacy junction `is_active=false`, set need `is_active=false`, `delete()` (soft), `activityLog(...,'Trashed')`.
- `restore` → `restore()`, `is_active=true`, reactivate legacy junction, `activityLog(...,'Restored')`.
- `forceDelete` → `DropdownNeedTableJnt::...->forceDelete()` then `$need->forceDelete()`, `activityLog(...,'Deleted')`.
- `toggleStatus` → validate `is_active|required|boolean`, flip need + legacy junction, `activityLog(...,'Toggled')`, return JSON.

> **BUG-PRM-DDNEED-001:** all of the above mutate `sys_dropdown_need_table_jnt`, but the mappings actually displayed come from `sys_dropdown_need_dropdowns_jnt` (the model relationship). Toggling/trashing a need therefore does NOT deactivate its shown dropdown mappings.

---

## 3. Test Cases (step-by-step)

### TC-P10 — Create a valid dropdown need (tenant_creation_allowed = No)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as super admin at `/login` | Dashboard loads |
| 2 | Visit `/global-master/dropdown-need/create` | Create form renders with db_type/table_name/column_name/tenant_creation_allowed selects |
| 3 | Select db_type=Prime; table_name=`sys_it_<uniq>`; column_name=`status_<uniq>`; tenant_creation_allowed=No; is_system=No; compulsory=Yes; status=Active | Fields accepted |
| 4 | Submit "Add Dropdown Need" | HTTP 302 redirect to `dropdown.index`; green success toast "Dropdown need created successfully" |
| 5 | DB check | `SELECT * FROM sys_dropdown_needs WHERE table_name='sys_it_<uniq>'` → 1 row, db_type='Prime', menu_category IS NULL |
| 6 | Activity check | `SELECT * FROM sys_central_activity_logs WHERE subject_type LIKE '%DropdownNeed%' AND event='Created'` → 1 row, user_id = admin |

### TC-N02 — Invalid db_type rejected

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Authenticated POST to `/global-master/dropdown-need` with db_type=`NotADbType` | Redirect back (302) with session error on `db_type` (or 422 for JSON) |
| 2 | DB check | No new row inserted |

### TC-N05 — Menu fields required when tenant_creation_allowed = Yes

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST with tenant_creation_allowed=1 but menu_category/main_menu/sub_menu/tab_name/field_name empty | Validation errors on all five menu fields |

### TC-N06 — Duplicate (db_type, table, column) — BUG-PRM-DDNEED-003

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create need A (Prime, tblX, colY) | Success |
| 2 | Create need B with identical (Prime, tblX, colY) | **DB unique `uq_dropdownNeeds_db_table_column_key` violated → QueryException 500** (no friendly validation message — defect) |

### TC-D05 — is_system protection

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a need with is_system=1 | Row present |
| 2 | GET edit for that need | Redirect to `dropdown-need.index` with error "System records cannot be edited." |
| 3 | DELETE that need | Redirect with error "System records cannot be deleted."; row NOT trashed |

### TC-S01 — Ungated AJAX endpoints (SEC-PRM-004)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Authenticate as a user WITHOUT any dropdown permission | Session established |
| 2 | GET `/global-master/dropdown-need-api/migration-tables/Prime` | 200 with table list — **no authorization check** (only `auth`+`verified` middleware). Confirms schema leak. |
| 3 | GET `/global-master/dropdown-need-api/table-columns?db_type=Prime&table_name=...` | 200 with column list — ungated |

### TC-N11 — Guest redirect

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure logged out | — |
| 2 | Visit `/global-master/dropdown-need` | Redirect to `/login` |

### TC-D03 — Junction mismatch (BUG-PRM-DDNEED-001)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Map a need to a dropdown via mapping junction (`sys_dropdown_need_dropdowns_jnt`) | Mapping visible |
| 2 | Toggle the need status to inactive | `sys_dropdown_need_table_jnt` rows flipped, but `sys_dropdown_need_dropdowns_jnt` rows unchanged → mapping still shown (defect) |

### TC-S06 — XSS stored verbatim

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a need with column_name=`<script>alert(1)</script>` | Persisted literally in DB |
| 2 | Render index | Value HTML-escaped on output (Blade `{{ }}`) — no script execution |

---

## 4. DB & Activity Check Reference

```sql
-- record existence
SELECT id, db_type, table_name, column_name, is_system, is_active, deleted_at
FROM sys_dropdown_needs WHERE table_name = ?;

-- soft-delete
SELECT deleted_at FROM sys_dropdown_needs WHERE id = ?;   -- expect NOT NULL after destroy

-- activity (central sink)
SELECT event, user_id FROM sys_central_activity_logs
WHERE subject_type LIKE '%DropdownNeed%' ORDER BY id DESC LIMIT 5;

-- junction mismatch
SELECT is_active FROM sys_dropdown_need_table_jnt      WHERE dropdown_needs_id = ?;
SELECT is_active FROM sys_dropdown_need_dropdowns_jnt  WHERE dropdown_needs_id = ?;
```
