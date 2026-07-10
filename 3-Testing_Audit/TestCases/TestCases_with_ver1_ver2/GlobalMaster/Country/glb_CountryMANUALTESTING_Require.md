# glb_Country — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | GlobalMaster |
| Feature / Screen | Country (Geography / Location Setup) |
| Scope | **CENTRAL / prime-side** (shared `global_db`, model connection `global_master_mysql`) — NOT tenant-scoped |
| Host | `http://127.0.0.1:8000` (central) |
| Index URL | `/global-master/country` (route `central.global-master.country.index`) |
| Create URL | `/global-master/country/create` |
| Edit URL | `/global-master/country/{id}/edit` |
| Trash URL | `/global-master/country/trash/view` (route `central.global-master.country.trashed`) |
| Toggle URL | `POST /global-master/country/{country}/toggle-status` (JSON) |
| Restore URL | `GET /global-master/country/{id}/restore` |
| Force-delete URL | `DELETE /global-master/country/{id}/force-delete` |
| Controller | `Modules\GlobalMaster\Http\Controllers\CountryController` |
| Model | `Modules\GlobalMaster\Models\Country` (table `glb_countries`, connection `global_master_mysql`) |
| Request | `Modules\GlobalMaster\Http\Requests\CountryRequest` |
| Views | `resources/views/country/{index,create,edit,show,trash}.blade.php` (page-based CRUD — no modals) |
| CRUD Type | Full resource: create/edit are dedicated pages; delete via row form; toggle via AJAX |
| Soft Delete | Yes (`deleted_at`) |
| Pagination | 10 per page, ordered `is_active desc` |
| Activity Log | `sys_activity_logs` via global `activityLog()` helper; events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Permissions | `prime.country.{viewAny,create,view,update,delete,restore,forceDelete}` |

**Post-action redirects:** store/update/destroy redirect to `route('central.global-master.location-setup.index').'#country'` (the tabbed Location Setup page); restore/forceDelete redirect to `central.global-master.country.trashed`.

**Environment prerequisites:** GlobalMaster **and** Prime modules must be `true` in `prime_testing/modules_statuses.json` (both currently `false` → all routes 404). `APP_ENV=testing`. Run on `http://127.0.0.1:8000`.

---

## 2. Business Conditions (detailed)

### Validation rules & messages
`CountryRequest::rules()` (default Laravel messages unless overridden — no custom `messages()` present):
- `name` → required, string, max:50, `Rule::unique('glb_countries')->ignore($countryId)`
- `short_name` → required, string, max:10
- `global_code` → nullable, string, max:10
- `currency_code` → nullable, string, max:8
- `default_timezone` → nullable, string, max:64 — **validated but has no column/fillable (SEC-GLB-001 / cross-ref)**
- `is_active` → required, boolean
- `prepareForValidation()` sets `is_active = true` when checkbox submits `'on'`, else `false`.

### Delete / status flow diagram
```
destroy(country):
  is_active = false  ->  save()  ->  delete() [soft]  ->  activityLog(Trashed)
  redirect -> location-setup.index#country

toggleStatus(country, is_active):
  validate is_active required|boolean
  DB::beginTransaction
    country.is_active = input          -> save()
    State.where(country_id).update(is_active = status)          [cascade 1]
    District.whereIn(state_id in states).update(is_active)      [cascade 2]
    -- glb_cities: NOT updated  ==> BUG-GLB-004
  DB::commit -> activityLog(Toggled) -> JSON {success,is_active,message}
  (on exception) DB::rollBack -> JSON {success:false,...}
```

### Referential integrity
- `glb_states.country_id → glb_countries.id ON DELETE RESTRICT` — a country referenced by any state cannot be force-deleted.
- Soft-deleting a country does NOT cascade a soft delete to its states.

---

## 3. Test Cases (step-by-step)

### TC-P05 — Store a new country (happy path)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as super-admin on `http://127.0.0.1:8000` | Dashboard reachable |
| 2 | Visit `/global-master/country/create` | Form shows Name, Short Name, Global Code, Currency Code, Status |
| 3 | Enter name=`Testland`, short_name=`TLD`, global_code=`TL`, currency_code=`TLD`, tick Status | Fields accept input |
| 4 | Submit "Add Country" | Redirect to `…/location-setup#country` with success toast |
| 5 | DB check | `SELECT * FROM glb_countries WHERE name='Testland'` → 1 row, `is_active=1`, `deleted_at IS NULL` |
| 6 | Activity-log check | `SELECT event FROM sys_activity_logs WHERE subject_id=<id>` → contains `Stored` |

### TC-P06 — Update a country
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open `/global-master/country/{id}/edit` | Inputs prefilled with existing values |
| 2 | Change short_name to a new unique value, submit "Update Country" | Redirect with success toast |
| 3 | DB check | `short_name` updated for that id |
| 4 | Activity-log check | `Updated` event logged (with structured change set) |

### TC-P07 — Delete (soft) a country
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On index, click the row trash (danger) button | SweetAlert confirm → submit DELETE |
| 2 | DB check | `deleted_at` set AND `is_active=0` (destroy deactivates first) |
| 3 | Activity-log check | `Trashed` event logged |

### TC-P08 / TC-D01 — Restore from trash
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/global-master/country/trash/view` | Trashed country listed |
| 2 | Click Restore | Redirect to trashed view with toast |
| 3 | DB check | `deleted_at IS NULL` for that id |
| 4 | Activity-log check | `Restored` event logged |

### TC-P09 — Force delete
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | From trash, click Force Delete | Row permanently removed |
| 2 | DB check | `SELECT ... WITH TRASHED` returns 0 rows |
| 3 | Activity-log check | `Deleted` event logged |

### TC-P10 — Toggle status
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On index, flip the `input.status-toggle` switch for a country | AJAX POST to toggle-status |
| 2 | Response check | JSON `{success:true, is_active:<new>, message:...}` |
| 3 | DB check | `is_active` reflects the new value |
| 4 | Activity-log check | `Toggled` event logged |

### TC-D04/D05/D06 — Toggle cascade (states, districts, cities)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed country → state → district → city (all active) | Chain created |
| 2 | Toggle country to inactive | State `is_active=0` (TC-D04) |
| 3 | Check district | District `is_active=0` (TC-D05) |
| 4 | Check city | **City `is_active=1` (UNCHANGED)** → confirms **BUG-GLB-004** (should be 0 per BR-GLB-001) |

### TC-D03 — Force-delete blocked by FK RESTRICT
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed country with a referencing state | Chain created |
| 2 | Soft-delete then force-delete the country | DB throws (RESTRICT); force-delete fails |
| 3 | DB check | Country row still present (trashed) |

### TC-N01..N10 — Validation (representative)
| Step | Action | Expected Result |
|------|--------|-----------------|
| N01 | Submit store without `name` | Validation error on `name` |
| N02 | Submit `name` = 51 chars | Error on `name` (max:50) |
| N03 | Submit `name` duplicating an existing country | Error on `name` (unique) |
| N06 | Submit `short_name` = 11 chars | Error on `short_name` (max:10) |
| N07 | Submit `global_code` = 11 chars | Error on `global_code` (max:10) |
| N08 | Submit `currency_code` = 9 chars | Error on `currency_code` (max:8) |
| N10 | Toggle with `is_active='banana'` | HTTP 422 (required\|boolean) |

### TC-N12..N22 — Authorization / security
| Step | Action | Expected Result |
|------|--------|-----------------|
| N12 | Visit index as guest | 302 → `/login` |
| N14 | Visit index as user without `prime.country.viewAny` | 403 |
| N16 | POST store as unauthorized user | 403 |
| N17 | POST toggle as unauthorized user | 403 |
| N18 | Force-delete as unauthorized user | 403 |
| N19 | Open `/global-master/country/99999999/edit` | 404 |
| N23 | Store `name` = `<script>alert(1)</script>…` then view index | Rendered escaped; no raw `<script>` in DOM |

### TC-S01 — SEC-GLB-001 (default_timezone dropped)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Store a country including `default_timezone=Asia/Kolkata` | Store succeeds, redirect |
| 2 | Schema check | `glb_countries` has NO `default_timezone` column → value silently dropped |
| 3 | Conclusion | Documents SEC-GLB-001: validated-but-non-existent field passes validation and is lost |
