# Setting (Prime / System Config) — Manual Test Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — **central** (`prime_db`), no tenancy |
| Feature / Screen | System Config → Setting |
| URL (index) | `http://127.0.0.1:8000/system-config/setting` |
| URL (edit) | `/system-config/setting/{id}/edit` |
| URL (search, JSON) | `/system-config/setting/search?search=...` |
| Route names | `central.system-config.setting.{index,create,store,show,edit,update,destroy}` + `central.system-config.setting.search` |
| Controller | `Modules\Prime\Http\Controllers\SettingController` |
| Model | `Modules\SystemConfig\Models\Setting` (canonical) — `Modules\Prime\Models\Setting` deprecated, same table |
| Table | `sys_settings` |
| Validation | Inline `$request->validate` in `update()` only (no FormRequest) |
| CRUD Type | READ + single-field UPDATE (Create/Store/Show/Destroy are non-functional stubs) |
| Soft Delete | **No** (`sys_settings` has no `deleted_at`) |
| Pagination | 10 / page |
| Activity Log | **None** (controller has no `activityLog()` calls) |
| Auth | `auth` + `verified` middleware; Gate `prime.setting.*`; Super Admin bypass |

> **Environment prerequisites:** Prime module must be **enabled** in `prime_testing/modules_statuses.json`; run on `http://127.0.0.1:8000` with `APP_ENV=testing`; a super-admin central user (`DUSK_ADMIN_EMAIL`) must exist. Central feature → **no** tenant initialization.

---

## 2. Business Conditions (detailed)

### Update flow (the only working mutation)
```
Edit link (index Action col, @can prime.setting.update)
   → GET /system-config/setting/{id}/edit   [Gate: prime.setting.update]
   → edit.blade renders hidden key + value input (or language selector when key = default_language)
   → PUT /system-config/setting/{id}         [Gate: prime.setting.update]
       validate: key = required|string|exists:sys_settings,key ; value = required
       Setting::where('key',$key)->first()->value = $value ; save()
   → redirect central.system-config.setting.index  with success flash  (NO activity log)
```

### Search flow (AJAX suggestions)
```
GET /system-config/setting/search?search=term   [NO GATE — DEV-001]
   if term === ''  → JSON []
   else → Setting WHERE key LIKE %term% OR description LIKE %term%
          SELECT key, description  ORDER BY key  LIMIT 10  → JSON
```

### Known defects (map to DEV-### in TcList / GapAnalysis)
- **DEV-001** search() ungated → BR-PRM-022 fails.
- **DEV-002** store() returns `$request` (no create).
- **DEV-003** destroy() empty (no delete).
- **DEV-004/005** create()/show() return non-existent `prime::create` / `prime::show` views → 500.
- **DEV-006** edit view reads absent `organization_id`.
- **DEV-007** index() dead `Setting::all()` calls.
- **DEV-008** no activity logging.

---

## 3. Manual Test Cases

### MTC-01 — Schema truth (TC-P01)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `DESCRIBE sys_settings;` | columns: id, description, key, value, type, is_public, created_at, updated_at; **no** deleted_at |
| 2 | `SHOW INDEX FROM sys_settings;` | UNIQUE `uq_settings_key` on `key` |
| 3 | Inspect model | table `sys_settings`, fillable `[key,value,type,is_public]`, no SoftDeletes |

### MTC-02 — Update persists value (TC-P05)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; visit `/system-config/setting` | Index renders; page accessible |
| 2 | Click the edit (sliders) icon on a row | Edit form at `/system-config/setting/{id}/edit` |
| 3 | Change **Value**, submit "Save Settings" | Redirect to `/system-config/setting`, success flash |
| 4 | `SELECT value FROM sys_settings WHERE id={id};` | equals the new value |
| 5 | `SELECT * FROM sys_central_activity_logs WHERE subject_type LIKE '%Setting%';` | **no** new row (no logging — DEV-008) |

### MTC-03 — Update validation (TC-N01..N04)
| Step | Action | Expected |
|------|--------|----------|
| 1 | PUT update with `value` omitted | Redirect back with error on `value`; DB unchanged |
| 2 | PUT update with `key` omitted | Error on `key` |
| 3 | PUT update with non-existent `key` | Error on `key` (`exists:sys_settings,key`) |
| 4 | PUT update with `value=''` | Error on `value` |

### MTC-04 — Search endpoint (TC-P12/P13, TC-S02)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/system-config/setting/search?search=<known-fragment>` | JSON array with `{key,description}` matching, ≤10, ordered by key |
| 2 | GET `.../search?search=` | JSON `[]` |
| 3 | GET `.../search?search=' OR '1'='1` | HTTP 200, JSON array; no SQL error / no table dump |

### MTC-05 — Permissions (TC-AUTH01/02, TC-N06/N07, DEV-001)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read controller | `Gate::authorize('prime.setting.viewAny|create|view|update|delete')` on the 5 RESTful actions |
| 2 | Read `search()` body | **no** Gate (DEV-001) |
| 3 | Logout; GET `/system-config/setting` | Redirect to `/login` |
| 4 | Login as user WITHOUT `prime.setting.viewAny` | 403 on index |
| 5 | Inspect index.blade | content wrapped in `@can('prime.setting.viewAny')`; Action column in `@can('prime.setting.update')` |

### MTC-06 — UI render (TC-P08..P11)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit index | Table headers Key/Value/Types/Is Public; search input `#search-input`; reset `#reset-btn`; breadcrumb "System Config" |
| 2 | Index with zero rows | "No Setting Data Found" |
| 3 | Visit edit | `input[name=value]`, hidden `input[name=key]`, breadcrumb "Edit Setting" |

### MTC-07 — Defect proofs (DEV-002..007)
| Step | Action | Expected (current defective behaviour) |
|------|--------|----------|
| 1 | POST `/system-config/setting` (store) | No row created (`SELECT COUNT(*)` unchanged) — DEV-002 |
| 2 | DELETE `/system-config/setting/{id}` | Row still present — DEV-003 |
| 3 | GET `/system-config/setting/create` | HTTP 500 (view `prime::create` missing) — DEV-004 |
| 4 | GET `/system-config/setting/{id}` (show) | HTTP 500 (view `prime::show` missing) — DEV-005 |
| 5 | `DESCRIBE sys_settings` for `organization_id` | absent (edit view references it) — DEV-006 |
| 6 | Read index() | contains `Setting::all()` dead calls — DEV-007 |

### MTC-08 — Security & scope (TC-N08, TC-T00)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Update value to `<script>alert(1)</script>` | DB stores it verbatim (no sanitisation) |
| 2 | View index | Rendered HTML is escaped; no executable `<script>alert(1)</script>` in source |
| 3 | Confirm scope | `tenancy()->initialized === false` (central feature; no cross-tenant isolation applicable) |
