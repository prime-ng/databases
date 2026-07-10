# Dropdown (PRM / Prime) — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — **CENTRAL / prime_db** (no tenant) |
| Feature | Dropdown (central dropdown option store) |
| Base URL | `http://127.0.0.1:8000/global-master/dropdown` |
| Trash URL | `http://127.0.0.1:8000/global-master/dropdown/trash/view` |
| Controller | `Modules\Prime\Http\Controllers\DropdownController` |
| FormRequest | `Modules\Prime\Http\Requests\DropdownRequest` |
| Model | `Modules\Prime\Models\Dropdown` → table `sys_dropdown_table` |
| Primary table | `sys_dropdown_table` (constraint #27 — NOT `sys_dropdowns`; rename migration is a no-op) |
| Validation | key required/max160/unique; value required/max100; type in 7 enum; ordinal nullable/int/min1 |
| Migration | `database/migrations/2025_11_16_114618_create_sys_dropdown_table.php` (central) |
| CRUD type | Modal/redirect forms + AJAX; multi-tab management screen |
| Soft delete | Yes (`SoftDeletes`, `deleted_at`) |
| Pagination | 10/page (list_page, needs_page, mapped_page, mapping_page, unmapped_page) |
| Activity log | `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog`; events: `Trashed`, `Restored`, `Toggled` only |
| Permissions | `prime.dropdown.{viewAny,view,create,update,delete,restore,forceDelete}` |
| Prerequisite | Prime module ENABLED in `modules_statuses.json`; run host `127.0.0.1:8000`; `APP_ENV=testing` |

## 2. Business Conditions (detailed)
- **Create (store):** requires a `dropdown_need_id` (else "Please select a dropdown need first!"); auto-assigns `ordinal = max(ordinal)+1` when blank; default `type=String`; free-text `additional_info` is stored as `json_encode(['info'=>...])`; creates a `sys_dropdown_need_table_jnt` row. Global unique on `key` alone (see DEV-DROPDOWN-004).
- **Update:** `DropdownRequest` rules; unique key ignores self; may re-point junction on `dropdown_need_id` change. No activity log (DEV-DROPDOWN-007).
- **Delete (destroy):** `is_active=false` → soft delete → deactivate `sys_dropdown_need_dropdowns_jnt`; logs `Trashed` — **but** `$dropdown` is out of the closure scope (DEV-DROPDOWN-002), logging a null subject.
- **Restore:** restore + `is_active=true` → reactivate `sys_dropdown_need_table_jnt` (different junction table than destroy → DEV-DROPDOWN-003); logs `Restored`.
- **Toggle status:** validate `is_active` boolean; update dropdown + junction; logs `Toggled`.
- **Force delete:** delete `sys_dropdown_need_dropdowns_jnt` rows then `forceDelete()` the dropdown.
- **AJAX helpers:** `saveDropdownOption` (narrow enum → DEV-DROPDOWN-005), `addBySelection`/`quickSave` (use removed `str_slug()` → DEV-DROPDOWN-008), `search`, `checkKeyExists`, `getOptionsByKey`, bulk update/delete/restore/forceDelete.

## 3. Manual Test Cases

### TC-M01 — Schema & config truth
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW TABLES LIKE 'sys_dropdown_table'` | Returns the table |
| 2 | `SHOW COLUMNS FROM sys_dropdown_table` | id, ordinal, key, value, type, additional_info, is_active, created_at, updated_at, **deleted_at** |
| 3 | `SHOW INDEX FROM sys_dropdown_table` | `uq_dropdownTable_key_value`, `uq_dropdownTable_key_ordinal` |
| 4 | Inspect `type` column | ENUM with 7 values String..Boolean |

### TC-M02 — Admin loads index
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super-admin at `/login` | Dashboard |
| 2 | Visit `/global-master/dropdown` | Page loads, breadcrumb "Dropdown Management" |
| 3 | Observe list pane | `#dropdown-list-pane` + table with Key/Value rows |
| 4 | Observe filters | `list_key`, `list_value`, `list_status` inputs present |

### TC-M03 — Create a dropdown option (positive)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Select a dropdown need, open create form | Form with key/ordinal/type/value/additional_info |
| 2 | Submit valid key/value/type | Redirect to index, toast "Dropdown saved successfully!" |
| 3 | `SELECT * FROM sys_dropdown_table WHERE key=?` | Row exists; ordinal auto-assigned; type default String |
| 4 | `SELECT * FROM sys_dropdown_need_table_jnt WHERE dropdown_table_id=?` | Junction row created, is_active=1 |

### TC-M04 — Validation (negative)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit empty key | "key is required" |
| 2 | Submit duplicate key | "This key already exists." |
| 3 | Submit key >160 chars | max:160 error |
| 4 | Submit value >100 chars | max:100 error |
| 5 | Submit type not in enum | in-rule error |

### TC-M05 — Toggle status
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/global-master/dropdown/{id}/toggle-status` is_active=0 | JSON success, is_active=false |
| 2 | `SELECT is_active` | 0 |
| 3 | `SELECT * FROM sys_central_activity_logs WHERE event='Toggled'` | Row present |

### TC-M06 — Soft delete / restore / force delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a dropdown | Soft deleted, deleted_at set; toast "Dropdown trashed successfully!" |
| 2 | `sys_central_activity_logs` event `Trashed` | Row present (note DEV-DROPDOWN-002 → null subject) |
| 3 | Visit `/global-master/dropdown/trash/view` | Trashed row visible (Key/Value/Action) |
| 4 | Restore | Row back; deleted_at null; event `Restored` |
| 5 | Force delete from trash | Row permanently gone |

### TC-M07 — Permissions
| Step | Action | Expected |
|------|--------|----------|
| 1 | As guest visit index | Redirect `/login` |
| 2 | As guest visit trash | Redirect `/login` |
| 3 | As user without permission | Gate denies create/update/delete |

### TC-M08 — Defect verification (see Gap Analysis)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Trigger addBySelection/quickSave | Runtime fatal `Call to undefined function str_slug()` (DEV-DROPDOWN-008) |
| 2 | Soft-delete a key+value then recreate same | Unique index collision (DEV-DROPDOWN-006) |
| 3 | Inspect `sys_central_activity_logs` subject for Trashed | subject_id null / mismatched (DEV-DROPDOWN-002) |
