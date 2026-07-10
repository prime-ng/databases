# Dropdown — Manual Test Specification (`sys_DropdownMANUALTESTING_Require.md`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | GlobalMaster |
| Feature / Screen | Dropdown (central dropdown value registry) |
| Scope | **CENTRAL / prime-side** (`prime_db`) — NO tenant init |
| Base URL | `http://127.0.0.1:8000/global-master/dropdown` |
| Route name family | `central.global-master.dropdown.*` |
| Controller | `Modules/GlobalMaster/app/Http/Controllers/DropdownController.php` |
| Model | `Modules/GlobalMaster/Models/Dropdown` |
| Request | `Modules/GlobalMaster/Http/Requests/DropdownRequest` |
| Policy / gates | `DropdownPolicy` → `prime.dropdown.{viewAny,view,create,update,delete,restore,forceDelete}` |
| Migration (central) | `database/migrations/2025_11_16_114618_create_sys_dropdown_table.php` |
| Primary table | `sys_dropdown_table` (unique `(key,value)` & `(key,ordinal)`) |
| Junction table | `sys_dropdown_need_table_jnt` |
| CRUD type | Create page + edit page + index (no modal); AJAX toggle |
| Soft delete | Yes (`deleted_at`) |
| Pagination | 10 distinct keys / page |
| Activity log | Central `sys_central_activity_logs` (via `activityLog()` when tenancy not initialized) |
| Login | `DUSK_ADMIN_EMAIL` / `DUSK_ADMIN_PASSWORD` (super-admin) |

### Environment prerequisites (read before manual runs)
1. `modules_statuses.json`: **`GlobalMaster: true` AND `Prime: true`** — otherwise every route 404s (constraint E19; both are currently `false`).
2. `APP_ENV=testing` for state-changing requests (CSRF bypass; else 419).
3. Central host must be `http://127.0.0.1:8000` (PrimeDuskTestCase hardcodes and `fail()`s otherwise).

---

## 2. Business Conditions (detailed)

### Activity-log events (assert the **exact** literals)

| Action | Event string | Properties `message` (verbatim) | Flash key |
|--------|--------------|----------------------------------|-----------|
| destroy | `Trashed` | `A new module was deactivated and deleted.` | `trashed.module` |
| restore | `Restored` | `A new module was restored.` | `restored.module` |
| forceDelete | `Deleted` | `A new module was permanently deleted.` | `force_deleted.module` |
| toggleStatus | `Toggled` | `Module toggle was updated.` | `status_updated.dropdown` |
| store | *(none)* | — | `created.dropdown` |
| update | *(none)* | — | `updated.dropdown` |

> The message text and flash keys say **"module"** even though this is the Dropdown feature — this is a copy/paste mislabel (BUG-GLB-009). Assert the literal strings as-is.

### store() flow (as coded — includes defects)
```
value (comma-separated) --> trim each --> array_unique
ordinal = max(ordinal WHERE org_id = auth id) + 1        # BUG-GLB-009: org_id not a column; not key-scoped
for each value:
    Dropdown::create({ org_id, ordinal++, key=slug(key,'_'), value, type, is_active })
                                # org_id + key + type come from $request->validated()
                                # but validated() only returns value + is_active (VAL-GLB-001)
redirect central.global-master.dropdown.index  with success flash created.dropdown
```
Because `$request->validated()` returns only `value` and `is_active`, `$data['org_id']`, `$data['key']`, `$data['type']` are undefined, and `Dropdown::where('org_id', …)` targets a non-existent column. The store path is therefore effectively broken; manual create through the UI is expected to error or persist incomplete rows.

---

## 3. Manual Test Cases (Step / Action / Expected + DB & activity-log checks)

### TC-P01 — Index loads and lists keys
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super-admin | Dashboard visible |
| 2 | Visit `/global-master/dropdown` | HTTP 200, breadcrumb "Dropdowns" |
| 3 | Observe list | Accordion of distinct `key` groups, ≤10 keys/page |
| 4 | DB check | `SELECT COUNT(DISTINCT `key`) FROM sys_dropdown_table` matches paginator total |

### TC-P05 — Toggle status (AJAX)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On index, expand a key accordion | Value rows with status switches visible |
| 2 | Click `#statusSwitch-{id}` | AJAX POST `/global-master/dropdown/{id}/toggle-status` |
| 3 | Response | JSON `{success:true, is_active:<bool>, message:"…"}` |
| 4 | DB check | `SELECT is_active FROM sys_dropdown_table WHERE id={id}` flipped |
| 5 | Activity check | `sys_central_activity_logs` row `event='Toggled'`, `properties.message='Module toggle was updated.'`, `user_id`=admin |

### TC-P06/07/08 & TC-D05 — Full soft-delete lifecycle
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed one row (key K, value V) | Row present, `is_active=1` |
| 2 | Click delete on the row → confirm SweetAlert | Redirect to index; success flash |
| 3 | DB check | `deleted_at` NOT NULL; `is_active=0` (destroy deactivates first) |
| 4 | Activity check | `event='Trashed'`, `properties.message='A new module was deactivated and deleted.'` |
| 5 | Visit `/global-master/dropdown/trash/view` | Row V listed |
| 6 | Click restore → confirm | `deleted_at` NULL; `event='Restored'` logged |
| 7 | Delete again, go to trash, click force-delete → confirm | Row removed permanently; `event='Deleted'` logged |
| 8 | DB check | `SELECT * FROM sys_dropdown_table WHERE id={id}` → 0 rows (incl. withTrashed) |

### TC-N01/N02 — VAL-GLB-001 (missing key/type not rejected)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST to `/global-master/dropdown` with `value=Alpha`, `is_active=on`, no `key`/`type` | No validation error naming `key` or `type` |
| 2 | Observe | Only `value`/`is_active` are validated (request rules) |
| 3 | Note | Store then errors on `org_id`/undefined keys (BUG-GLB-009) — defect chain |

### TC-N06/N07 — Uniqueness
| Step | Action | Expected |
|------|--------|----------|
| 1 | Insert (key K, value V, ordinal 1) | OK |
| 2 | Insert (key K, value V, ordinal 2) | DB rejects — `uq_dropdownTable_key_value` |
| 3 | Insert (key K, value W, ordinal 1) | DB rejects — `uq_dropdownTable_key_ordinal` |
| 4 | Insert (key K2, value W, ordinal 1) | OK (different key) |

### TC-N11 — BUG-GLB-005 dead search route
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/global-master/dropdown/search` | HTTP 500 (controller has no `search()` method) — accept {404,405,500} |
| 2 | Confirm | `DropdownController` declares no `search` method |

### TC-D07 — BUG-GLB-009 org_id
| Step | Action | Expected |
|------|--------|----------|
| 1 | DB check | `SHOW COLUMNS FROM sys_dropdown_table LIKE 'org_id'` → 0 rows |
| 2 | Run `Dropdown::where('org_id',1)->max('ordinal')` | SQL error: Unknown column 'org_id' |

### TC-S01 — Stored XSS on value
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed value = `<script>alert(1)</script>` | Row created |
| 2 | Visit index, view page source | Escaped (`&lt;script&gt;…`); no executing script |

### TC-N10 / TC-S05 — Guest access
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout; visit `/global-master/dropdown` | Redirect to `/login` |
| 2 | Visit `/global-master/dropdown/create` | Redirect to `/login` |

### TC-N12 / TC-S03 — Invalid-id / IDOR
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/global-master/dropdown/99999999/edit` | 404 |
| 2 | POST `/global-master/dropdown/99999999/toggle-status` | 404 |
| 3 | GET `/global-master/dropdown/99999999/restore` | 404 |

(Remaining TCs — schema truth, relationships, pagination size, ordinal/key boundaries, defaults, JSON contract keys — are exercised as listed in the TcList Method Index and are primarily automatable schema/reflection checks.)
