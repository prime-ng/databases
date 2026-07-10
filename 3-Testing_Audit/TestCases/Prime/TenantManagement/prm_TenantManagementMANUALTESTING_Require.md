# prm_TenantManagement — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) |
| Feature / Screen | TenantManagement (Tenant & Subscription Mgmt dashboard) |
| Screen type | READ / COMPOSITE (single `index()` action) |
| URL | `http://127.0.0.1:8000/prime/tenant-management` (central domain) |
| Route name | `central.prime.tenant-management.index` (GET) |
| Middleware | `auth`, `verified` |
| Controller | `Modules\Prime\Http\Controllers\TenantManagementController@index` |
| Models | `Tenant` (`prm_tenant`), `TenantGroup` (`prm_tenant_groups`) |
| Primary tables | `prm_tenant`, `prm_tenant_groups` (central `prime_db`) |
| Validation / FormRequest | None (no input on this screen) |
| CRUD type | Read-only listing + computed dashboard; **all mutations delegated** to Tenant / TenantGroup screens |
| Soft delete | Yes on both models (listing shows non-deleted, live tenants only) |
| Pagination | 10/page each — Tenants under `tenant_page` (fragment `#tenant`), Tenant Groups under `tenant-group_page` (fragment `#tenant-group`) |
| Permission gate (index) | `Gate::authorize('prime.tenant.viewAny')` |
| Tab gates | Tenant Group tab = `prime.tenant-group.viewAny`; Tenant tab = `prime.tenant.viewAny` |
| Activity log | None (read action logs nothing) |
| Environment prerequisite | Prime module enabled in `modules_statuses.json`; run on `127.0.0.1:8000`; `APP_ENV=testing` |

---

## 2. Business Conditions (detailed)

### Listing scope
- **Live tenants only.** `Tenant::live()` filters `tenant_type = 'live'`; archived tenants are excluded from the Tenant tab.
- **Tenant Group count.** Each group shows `live_tenants_count` (`withCount('liveTenants')`).
- **Tenant modules count.** Each tenant shows `modules_count` = number of its plans that have at least one module; the Status toggle is only editable when `isProfileComplete() && modules_count > 0`, otherwise a read-only "Inactive" badge is shown with a tooltip.

### Dashboard stats (query-derived, NOT fabricated)
- `computeTenantGroupStats()` → total/active/inactive groups, tenants-per-group, groups-by-state.
- `computeTenantStats()` → total/active/inactive tenants, setup-status breakdown, tenants-by-state (India map), tenants-by-plan, last-12-months registrations.
- **BUG-PRM-009 check:** these values come from real queries; there is **no `rand()`/`mt_rand()`** stub on this screen.

### Permissions
- Index requires `prime.tenant.viewAny`. Guest → `/login`.
- Tabs and per-row Status/Action columns are individually gated (see table above).
- **BUG-PRM-TM-001:** the dedicated `TenantManagementPolicy::viewAny` checks `prime.tenant-management.viewAny` — a different permission that the controller never uses; the policy is dead/unwired.

### Known screen defects
- **BUG-PRM-TM-002** — Search box + "Filter 1"/"Filter 2" dropdowns are stubs (dummy options, no `name`, no form action, controller reads no request). **BUG-PRM-TM-002b** — Export button has no handler.
- **BUG-PRM-TM-003** — Tenant "Address" cell prints raw `city_id` (numeric FK) instead of the city name.
- **BUG-PRM-TM-004** — Empty-state row uses `colspan="5"` while up to 6–7 columns render.
- **BUG-PRM-TM-005** — `tenant_type`, `setup_status`, `rollover_*` columns exist at runtime (central migrations) but are missing from consolidated `_prime_db_v4.sql`.

---

## 3. Manual Test Cases

### MTC-01 — Config & schema truth (developer check)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `php artisan route:list --name=tenant-management` | Shows `central.prime.tenant-management.index` → `GET prime/tenant-management` only |
| 2 | Inspect `TenantManagementController@index` | Calls `Gate::authorize('prime.tenant.viewAny')`; takes 0 params |
| 3 | `DESCRIBE prm_tenant;` | Has `id, tenant_group_id, code, short_name, name, city_id, is_active, deleted_at` (+ runtime `setup_status, tenant_type, ...`) |
| 4 | `DESCRIBE prm_tenant_groups;` | Has `id, code, short_name, name, city_id, is_active, deleted_at` |
| 5 | `SHOW INDEX FROM prm_tenant;` | `uq_tenant_code` unique on `code` |

### MTC-02 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log out | Session cleared |
| 2 | Visit `/prime/tenant-management` | Redirected to `/login` |

### MTC-03 — Authorised render
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as super-admin | Authenticated |
| 2 | Visit `/prime/tenant-management` | Page 200; breadcrumb "Tenant & Subscription Mgmt" |
| 3 | Observe tabs | "Tenant Group" (active) and "Tenant" tabs present |
| 4 | Observe group table | Columns: Tenant Group, Contact, Address (+ Status/Action if permitted) |
| 5 | Click "Tenant" tab | `#tenant-pane` shows; columns Tenant, Domain, Details, Contact, Address |

### MTC-04 — Listing correctness (DB checks)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SELECT COUNT(*) FROM prm_tenant WHERE tenant_type='live' AND deleted_at IS NULL;` | Matches count shown across Tenant tab pages (10/page) |
| 2 | Add `?tenant_page=2#tenant` to URL | Second page of Tenants shown; group tab paging unaffected |
| 3 | Add `?tenant-group_page=2#tenant-group` | Second page of Tenant Groups shown; tenant tab paging unaffected |
| 4 | Group with 0 live tenants | Live-tenant count shows 0 |

### MTC-05 — Empty state
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | With no live tenants | Tenant table shows a single "Not Found Data" row |
| 2 | Inspect that row | **BUG-PRM-TM-004:** `colspan="5"` does not span all visible columns |

### MTC-06 — Search / filter / export (defect confirmation)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Type into the Search box, submit | **BUG-PRM-TM-002:** nothing filters (input has no `name`; form has no action) |
| 2 | Choose "Filter 1"/"Filter 2" option | No effect (dummy options; controller reads no request) |
| 3 | Click Export | **BUG-PRM-TM-002b:** nothing happens (no handler) |

### MTC-07 — Address column defect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View a tenant row with a city set | **BUG-PRM-TM-003:** Address shows the numeric `city_id`, not the city name |
| 2 | Compare with a Tenant Group row | Group Address correctly shows the city name |

### MTC-08 — Delegation (no mutations here)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attempt `POST /prime/tenant-management` | No such route (405/404) — screen has only GET index |
| 2 | Use the row Add/Edit/Delete controls | They link to the Tenant / TenantGroup screens (`central.prime.tenant.*`, `central.prime.tenant-group.*`) |

### MTC-09 — Policy mismatch (defect confirmation)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `TenantManagementPolicy::viewAny` | Checks `prime.tenant-management.viewAny` |
| 2 | Inspect controller | Enforces `prime.tenant.viewAny`; never calls the policy | 
| 3 | Conclusion | **BUG-PRM-TM-001:** policy + `prime.tenant-management.viewAny` permission are orphaned |
