# Location Reference Data — Requirement Document

## 1. Overview

The Location Reference Data feature provides a **read-only, tabbed listing** of all geographic master data (countries, states, districts, cities) to platform administrators. Data lives in the **global database** (`global_master_mysql`, `glb_*` tables) and is managed centrally — tenants get view-only access via this feature. An AJAX autocomplete search is provided per tab.

| Attribute | Value |
|-----------|-------|
| **Module** | SystemConfig |
| **Controller** | `TenantLocationController` |
| **Prefix** | `glb_` (global DB tables) |
| **FRD IDs** | REQ-SYS-009 |
| **Permission** | `system-config.geography.viewAny` (uses `Gate::any()` — also checks `system-config.geography.*`) |
| **Auth Pattern** | `Gate::any(['system-config.geography.viewAny']) \|\| abort(403)` |
| **Routes** | `GET /system-config/location`, `GET /system-config/location/search` |
| **DB Source** | Global database (`global_master_mysql`) — `glb_countries`, `glb_states`, `glb_districts`, `glb_cities` |
| **CRUD?** | **No** — View Only. No create/edit/delete routes registered. |
| **Models** | `Modules\GlobalMaster\Models\Country`, `State`, `District`, `City` |

---

## 2. Actor / User Role

| Role | Access |
|------|--------|
| Super Admin | Full read access — all 4 tabs, search, autocomplete |
| Platform Manager | Read access (via `system-config.geography.*` wildcard permit) |
| Platform Support | Read access (same gate) |
| School Admin | Read access (same gate — accessible from tenant subdomain) |

**Note:** The controller uses `Gate::any(['system-config.geography.viewAny'])` which, combined with `|| abort(403)`, permits access if the user has **any** permission matching `system-config.geography.*`. This is a broader check than a single named permission.

---

## 3. Functional Requirements

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| FR-LC-01 | Tabbed listing: 4 tabs (Country, State, District, City) | ✅ Implemented | Bootstrap nav-tabs |
| FR-LC-02 | Paginated results per tab (15 per page) | ✅ Implemented | Separate page parameter per tab (`country_page`, `state_page`, `district_page`, `city_page`) |
| FR-LC-03 | Tab-specific search (name only) | ✅ Implemented | LIKE %search% on `name` column |
| FR-LC-04 | AJAX autocomplete search | ✅ Implemented | Returns plain string array of matching names (limit 10) |
| FR-LC-05 | Country table: Name, Short Name, Global Code, Currency | ✅ Implemented | |
| FR-LC-06 | State table: Country (name), State, Short Name, Global Code | ✅ Implemented | Eager loads `country` relationship |
| FR-LC-07 | District table: State (name), District, Short Name, Global Code | ✅ Implemented | Eager loads `state` relationship |
| FR-LC-08 | City table: City, District (name), State (name via district), Short Name, Timezone | ✅ Implemented | Eager loads `district.state` |
| FR-LC-09 | Per-tab permission check via `@can('tenant.geography.viewAny')` in Blade | ✅ Implemented | Each tab pane wrapped in `@can` directive |
| FR-LC-10 | Reset button per tab to clear search | ✅ Implemented | Links back to tab base URL |
| FR-LC-11 | Central CRUD for location masters | — | Not in SystemConfig — managed via GlobalMaster module central routes |

---

## 4. Business Rules

| Rule ID | Rule | Source | Status |
|---------|------|--------|--------|
| — | Location data is read-only for tenants; no mutation endpoints exposed | Architecture | ✅ Enforced (no store/update/destroy routes) |
| — | Each tab maintains independent pagination state via separate query params | Implementation | ✅ Implemented |
| — | Autocomplete returns max 10 results | Implementation | ✅ Implemented |
| — | Search across all 4 tabs builds all 4 queries upfront regardless of active tab | Implementation | ✅ Implemented (queries all 4 tables, paginates only active tab filtered) |

---

## 5. Data Dictionary

### `glb_countries`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED (PK) | Yes | |
| `name` | VARCHAR | Yes | |
| `short_name` | VARCHAR | No | |
| `global_code` | VARCHAR | No | |
| `currency_code` | VARCHAR | No | |
| `currency_name` | VARCHAR | No | |

### `glb_states`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED (PK) | Yes | |
| `country_id` | INT UNSIGNED (FK) | Yes | → `glb_countries.id` |
| `name` | VARCHAR | Yes | |
| `short_name` | VARCHAR | No | |
| `global_code` | VARCHAR | No | |

### `glb_districts`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED (PK) | Yes | |
| `state_id` | INT UNSIGNED (FK) | Yes | → `glb_states.id` |
| `name` | VARCHAR | Yes | |
| `short_name` | VARCHAR | No | |
| `global_code` | VARCHAR | No | |

### `glb_cities`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED (PK) | Yes | |
| `district_id` | INT UNSIGNED (FK) | Yes | → `glb_districts.id` |
| `name` | VARCHAR | Yes | |
| `short_name` | VARCHAR | No | |
| `default_timezone` | VARCHAR | No | |

---

## 6. Routes

| Method | URI | Name | Description |
|--------|-----|------|-------------|
| GET | `/system-config/location` | `system-config.location.index` | Tabbed listing (params: `tab`, `search`, `{tab}_page`) |
| GET | `/system-config/location/search` | `system-config.location.search` | AJAX autocomplete (params: `tab`, `search`) |

*Registered in `routes/tenant.php` under middleware `['auth', 'verified']` and prefix `system-config`.*

---

## 7. Controller Logic (TenantLocationController)

### `index(Request $request): View`

1. **Authorization:** `Gate::any(['system-config.geography.viewAny']) || abort(403)`
2. **Tab:** `$request->input('tab', 'country')`
3. **Search:** `$request->input('search')`
4. **Country Query:** `Country::orderBy('name')`, filtered by name if tab === 'country' and search present; paginate 15 with `country_page` parameter
5. **State Query:** `State::with('country')->orderBy('name')`, filtered if tab === 'state' and search present; paginate 15 with `state_page` parameter
6. **District Query:** `District::with('state')->orderBy('name')`, filtered if tab === 'district' and search present; paginate 15 with `district_page` parameter
7. **City Query:** `City::with(['district', 'district.state'])->orderBy('name')`, filtered if tab === 'city' and search present; paginate 15 with `city_page` parameter
8. **Page Parameters:** Uses named pagination parameters (`country_page`, `state_page`, `district_page`, `city_page`) to allow independent pagination state
9. **View:** `systemconfig::location.index` with all 4 paginated collections, `tab`, `search`

### `search(Request $request): JsonResponse`

1. If no search string, return empty JSON array
2. Match on `tab` input:
   - `country` → `Country::where('name', 'like', "%{$search}%")->limit(10)->pluck('name')`
   - `state` → `State::...`
   - `district` → `District::...`
   - `city` → `City::...`
3. Return JSON array of matched names

### View Logic (location/index.blade.php)

- Each tab pane wrapped in `@can('tenant.geography.viewAny')` guard
- Search bar with AJAX autocomplete: input field with `data-search-url` pointing to `system-config.location.search` with `tab` parameter
- Suggestion dropdown (`#suggestion-box-{tab}`) hidden by default, shown on input
- Reset button links to `route('system-config.location.index', ['tab' => '{tab}'])` without search

---

## 8. Known Issues & Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | FRD REQ-SYS-009 mentions "Location Reference Data Management" but controller is **view-only** — FRD may imply CRUD was planned | Medium | ⬜ Clarify with BA |
| 2 | All 4 queries execute on every page load regardless of active tab — minor performance concern for large datasets | Low | ⬜ Optimize |
| 3 | Search is limited to `name` column only — no search by country code, state code, etc. | Low | ⬜ Enhancement |
| 4 | The permission `tenant.geography.viewAny` referenced in Blade `@can` directives differs from the gate `system-config.geography.viewAny` in the controller — they must map to the same permission or one is redundant | Medium | ⬜ Verify |
| 5 | No feature tests exist for this controller | High | ⬜ Backlog |
| 6 | View Blade uses `permissions="tenant.geography"` in search-bar component while controller gate is `system-config.geography.*` — potential mismatch | Medium | ⬜ Audit |
| 7 | Autocomplete returns only `name` values (plain string array) — no ID or structured data — suitable for autocomplete-only, not for selection widgets | Info | As designed |

---

## 9. Dependencies

| Dependency | Type | Module | Details |
|------------|------|--------|---------|
| `Modules\GlobalMaster\Models\Country` | Model | GlobalMaster | `glb_countries` on `global_master_mysql` |
| `Modules\GlobalMaster\Models\State` | Model | GlobalMaster | `glb_states` with `country()` relationship |
| `Modules\GlobalMaster\Models\District` | Model | GlobalMaster | `glb_districts` with `state()` relationship |
| `Modules\GlobalMaster\Models\City` | Model | GlobalMaster | `glb_cities` with `district()` and `district.state()` relationships |
| `global_master_mysql` | DB Connection | — | Global database connection |

---

## 10. Mock Data / Seed Requirements

- At least 5 countries with varying completeness of short_name, global_code, currency
- At least 3 states per country (15+ total)
- At least 3 districts per state (45+ total)
- At least 3 cities per district (135+ total)

---

## 11. User Stories Coverage

No explicit user story in FRD for REQ-SYS-009 (classified as "Could" in MoSCoW). Feature inferred from filesystem analysis by FRD author.

---

## 12. Version History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-23 | OpenCode | Initial requirement document from controller analysis + FRD SYS_FRD_Complete_2026-06-30 |

---

## 13. Appendix — FRD Excerpts

**REQ-SYS-009:** Location Reference Data Management — Status: PARTIAL (70%) [inferred]. TenantLocationController + 8 views exist; auth unknown; overlap with GlobalMaster module to be confirmed.

*Note: 8 views refers to the 4 tab panes × 2 states (loaded with/without search). The actual view file count is 1 index view with 4 tab sections.*

---

## 14. Review Notes

- The controller is clean, well-structured, and follows single responsibility principle
- READ-ONLY nature is explicitly documented in the controller DocBlock
- Pagination uses named parameters to maintain independent pagination state — good pattern for multi-tab single-page views
- The `Gate::any()` pattern allows broader access than `Gate::authorize()` — this may be intentional for the geography permission wildcard

---

## 15. Open Questions

| # | Question | Raised By | Status |
|---|----------|-----------|--------|
| 1 | Are tenants expected to receive location management CRUD in the future? | — | ⬜ Open |
| 2 | Should the AJAX autocomplete return structured data (id + name) for use in form selectors? | — | ⬜ Open |
| 3 | Is the `tenant.geography.viewAny` Blade permission supposed to match `system-config.geography.viewAny`? | — | ⬜ Open |

---

## 16. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Business Analyst | OpenCode AI | 2026-07-23 | — |
| Tech Lead | — | — | — |
| QA Lead | — | — | — |
