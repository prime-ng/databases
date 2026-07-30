# Location Reference Data — Test Case List

## 1. Module Overview

| Attribute | Value |
|-----------|-------|
| **Module** | SystemConfig |
| **Feature** | Location Reference Data (REQ-SYS-009) |
| **Controller** | `TenantLocationController` |
| **Routes** | `GET /system-config/location` (index), `GET /system-config/location/search` (AJAX) |
| **Permission** | `system-config.geography.viewAny` |
| **Auth Pattern** | `Gate::any(['system-config.geography.viewAny']) \|\| abort(403)` |
| **DB Source** | Global DB (`global_master_mysql`): `glb_countries`, `glb_states`, `glb_districts`, `glb_cities` |
| **CRUD?** | **No** — View-only |
| **Pagination** | 15 per page (named params per tab) |

---

## 2. Test Environment

- PHP 8.2+, Laravel 12
- MySQL 8.0+
- Global database (`global_master_mysql`) must contain `glb_countries`, `glb_states`, `glb_districts`, `glb_cities` tables with data
- Each table must have ≥ 15 records for pagination testing
- Models: `Modules\GlobalMaster\Models\Country`, `State`, `District`, `City` must be available
- Data relationships: State → Country (FK), District → State (FK), City → District (FK)

---

## 3. Test Case Matrix

### 3.1 Authentication & Authorization

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LC-01 | Unauthenticated user redirected to login | User not logged in | 1. Access `GET /system-config/location` | Redirected to login | — | — | ⬜ | ◌ |
| TC-LC-02 | Authenticated user without permission receives 403 | User lacks any `system-config.geography.*` permission | 1. Log in as user without permission<br>2. Access route | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-LC-03 | User with `system-config.geography.viewAny` can view | User has the explicit permission | 1. Log in with correct permission<br>2. Access route | 200 OK, view rendered | — | — | ⬜ | ◌ |
| TC-LC-04 | Gate::any() wildcard — user with `system-config.geography.*` passes | User has wildcard permission | 1. Assign `system-config.geography.*` via role<br>2. Access route | 200 OK | — | — | ⬜ | ◌ |
| TC-LC-05 | Unauthenticated user cannot access AJAX search | User not logged in | 1. Access `GET /system-config/location/search` | Redirected to login | — | — | ⬜ | ◌ |

### 3.2 Tab Navigation

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LC-06 | Default tab is Country | No `tab` parameter | 1. Access route without tab | Country tab is active | — | — | ⬜ | ◌ |
| TC-LC-07 | Country tab renders correctly | Countries in DB | 1. Click Country tab | Country table shown with columns: Name, Short Name, Global Code, Currency | — | — | ⬜ | ◌ |
| TC-LC-08 | State tab renders with country relationship | States in DB | 1. Click State tab | State table with columns: Country, State, Short Name, Global Code | — | — | ⬜ | ◌ |
| TC-LC-09 | District tab renders with state relationship | Districts in DB | 1. Click District tab | District table with columns: State, District, Short Name, Global Code | — | — | ⬜ | ◌ |
| TC-LC-10 | City tab renders with district + state relationship | Cities in DB | 1. Click City tab | City table with columns: City, District, State, Short Name, Timezone | — | — | ⬜ | ◌ |
| TC-LC-11 | Invalid tab defaults to Country | Invalid tab value | 1. Access route with `?tab=invalid` | Defaults to Country tab (no validation — request input default) | — | — | ⬜ | ◌ |

### 3.3 Search

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LC-12 | Country tab search (by name) | Countries with partial name match | 1. Switch to Country tab<br>2. Enter partial name<br>3. Submit | Countries filtered by name (LIKE %term%) | — | — | ⬜ | ◌ |
| TC-LC-13 | State tab search (by name) | States with partial name match | 1. Switch to State tab<br>2. Enter partial name<br>3. Submit | States filtered by name | — | — | ⬜ | ◌ |
| TC-LC-14 | District tab search (by name) | Districts with partial name match | 1. Switch to District tab<br>2. Enter partial name<br>3. Submit | Districts filtered by name | — | — | ⬜ | ◌ |
| TC-LC-15 | City tab search (by name) | Cities with partial name match | 1. Switch to City tab<br>2. Enter partial name<br>3. Submit | Cities filtered by name | — | — | ⬜ | ◌ |
| TC-LC-16 | Search scoped to active tab only | Search term exists in multiple tabs | 1. Search "United" on Country tab | Only countries matched; states/districts/cities not filtered (but pagination shows all) | — | — | ⬜ | ◌ |
| TC-LC-17 | Empty search on any tab returns all records | All data loaded | 1. Submit empty search on any tab | All paginated records for that tab | — | — | ⬜ | ◌ |
| TC-LC-18 | Search with no results | Term matches no records | 1. Enter unique search term | "No [entities] found." empty state | — | — | ⬜ | ◌ |
| TC-LC-19 | Reset button clears search | Search active | 1. Apply search<br>2. Click reset button | Tab reloaded without search parameter | — | — | ⬜ | ◌ |

### 3.4 AJAX Autocomplete Search

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LC-20 | Autocomplete returns matching country names | Countries exist | 1. Call `GET /location/search?tab=country&search=ind` | JSON array of matching country names (max 10) | — | — | ⬜ | ◌ |
| TC-LC-21 | Autocomplete returns matching state names | States exist | 1. Call `GET /location/search?tab=state&search=west` | JSON array of matching state names | — | — | ⬜ | ◌ |
| TC-LC-22 | Autocomplete returns matching district names | Districts exist | 1. Call `GET /location/search?tab=district&search=north` | JSON array of matching district names | — | — | ⬜ | ◌ |
| TC-LC-23 | Autocomplete returns matching city names | Cities exist | 1. Call `GET /location/search?tab=city&search=mumb` | JSON array of matching city names | — | — | ⬜ | ◌ |
| TC-LC-24 | Autocomplete with empty search returns empty array | Any data | 1. Call `?search=` (empty) | `[]` | — | — | ⬜ | ◌ |
| TC-LC-25 | Autocomplete limited to 10 results | 20+ matches exist | 1. Call with non-specific search | Max 10 results returned | — | — | ⬜ | ◌ |
| TC-LC-26 | Autocomplete with no match returns empty array | No match | 1. Call `?search=zzzzz` | `[]` | — | — | ⬜ | ◌ |
| TC-LC-27 | Autocomplete with invalid tab defaults to Country | Invalid tab | 1. Call `?tab=invalid&search=ind` | Returns country results (default match case) | — | — | ⬜ | ◌ |

### 3.5 Pagination

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LC-28 | Country pagination: 15 per page | 20+ countries | 1. View Country tab | 15 countries on page 1; pagination links visible | — | — | ⬜ | ◌ |
| TC-LC-29 | State pagination uses `state_page` param | 20+ states | 1. View State tab page 2 | URL contains `?tab=state&state_page=2` | — | — | ⬜ | ◌ |
| TC-LC-30 | District pagination uses `district_page` param | 20+ districts | 1. View District tab page 2 | URL contains `?tab=district&district_page=2` | — | — | ⬜ | ◌ |
| TC-LC-31 | City pagination uses `city_page` param | 20+ cities | 1. View City tab page 2 | URL contains `?tab=city&city_page=2` | — | — | ⬜ | ◌ |
| TC-LC-32 | Pagination preserves search across pages | Search + pagination | 1. Search, navigate page 2 | URL preserves `?tab=...&search=...&{tab}_page=2` | — | — | ⬜ | ◌ |
| TC-LC-33 | Switching tabs resets pagination | On page 3 of Country | 1. Switch to State tab | State tab shows page 1 (state_page defaults to 1) | — | — | ⬜ | ◌ |

### 3.6 Display & Data Integrity

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LC-34 | Country row shows all columns | Country exists | 1. View Country tab | Name, Short Name, Global Code, Currency displayed | — | — | ⬜ | ◌ |
| TC-LC-35 | State row shows parent country name | State with country relationship | 1. View State tab | Country column shows `state->country->name` | — | — | ⬜ | ◌ |
| TC-LC-36 | District row shows parent state name | District with state relationship | 1. View District tab | State column shows `district->state->name` | — | — | ⬜ | ◌ |
| TC-LC-37 | City row shows parent district and state | City with district → state chain | 1. View City tab | District column: `city->district->name`, State column: `city->district->state->name` | — | — | ⬜ | ◌ |
| TC-LC-38 | Null relationship shows "—" placeholder | Orphan record with no parent | 1. View record with missing FK | Shows "—" instead of parent name | — | — | ⬜ | ◌ |
| TC-LC-39 | Empty tab (no records) shows empty state | Empty table | 1. View tab with no data | "No [entities] found." message | — | — | ⬜ | ◌ |

### 3.7 View-Only (No CRUD)

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LC-40 | No create button on any tab | Any state | 1. Inspect page | No create/add button present | — | — | ✅ | ◌ |
| TC-LC-41 | No edit controls on any row | Any record | 1. Inspect page | No edit icon, link, or button | — | — | ✅ | ◌ |
| TC-LC-42 | No delete controls on any row | Any record | 1. Inspect page | No delete button or form | — | — | ✅ | ◌ |
| TC-LC-43 | No create/edit/destroy routes | N/A | 1. Check route list | Only GET routes registered for location | — | — | ✅ | ◌ |

---

## 4. Boundary & Edge Cases

| TC# | Test Case | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------|-----------------|----|----|--------|----|
| TC-LC-44 | Search with special regex characters | Search for `%` or `_` | LIKE treats as literal characters? (MySQL: `%` and `_` are wildcards in LIKE) | May match unintendedly — verify behavior | — | — | ⬜ | ◌ |
| TC-LC-45 | Very long search term (200+ chars) | Enter 200-char search | Search executes without error | — | — | ⬜ | ◌ |
| TC-LC-46 | SQL injection attempt in search | Enter `' OR 1=1 --` | Search treated as plain text; no injection | — | — | ⬜ | ◌ |
| TC-LC-47 | Pagination page parameter too high | Navigate to page 999 | Empty page shown (no records) | — | — | ⬜ | ◌ |
| TC-LC-48 | Pagination page parameter negative | Navigate to page -1 | Should default to page 1 | — | — | ⬜ | ◌ |
| TC-LC-49 | Pagination page parameter non-numeric | Navigate to page "abc" | Should default to page 1 | — | — | ⬜ | ◌ |
| TC-LC-50 | Data with Unicode/UTF-8 names | Records with accented or non-Latin names | Displayed correctly | — | — | ⬜ | ◌ |

---

## 5. Test Data Requirements

| Data Type | Quantity | Details |
|-----------|----------|---------|
| Countries | ≥ 20 | Include some with null short_name, global_code, currency |
| States | ≥ 20 | Spread across countries; include some orphaned (no country) |
| Districts | ≥ 20 | Spread across states |
| Cities | ≥ 20 | Spread across districts; include timezone data |
| Countries with name starting "A" | ≥ 3 | For autocomplete testing |
| States with name starting "W" | ≥ 3 | For autocomplete testing |

---

## 6. Test Execution Checklist

| Check | Description | Done? |
|-------|-------------|-------|
| Authentication tests pass (TC-LC-01 to TC-LC-05) | | ⬜ |
| Tab navigation works (TC-LC-06 to TC-LC-11) | | ⬜ |
| Search functions on all tabs (TC-LC-12 to TC-LC-19) | | ⬜ |
| AJAX autocomplete works (TC-LC-20 to TC-LC-27) | | ⬜ |
| Pagination works correctly (TC-LC-28 to TC-LC-33) | | ⬜ |
| Data integrity/display verified (TC-LC-34 to TC-LC-39) | | ⬜ |
| View-only constraint verified (TC-LC-40 to TC-LC-43) | | ⬜ |
| Boundary/edge cases tested (TC-LC-44 to TC-LC-50) | | ⬜ |

---

## 7. Automation Notes

- Use `Pest` with `get()` for HTTP tests
- Tests require connection to `global_master_mysql` — use `DatabaseTransactions` with `RefreshDatabase` on the global connection
- AJAX search tests should verify JSON response structure and content
- For `Gate::any()` testing, create a user with `system-config.geography.*` wildcard and verify access
- Blade `@can('tenant.geography.viewAny')` directives also need to be exercised — consider view tests

---

## 8. Known Issues

| # | Issue | Impact | Status |
|---|-------|--------|--------|
| 1 | All 4 queries executed on every page load regardless of active tab | Performance impact with large datasets | ⬜ Open |
| 2 | Permission mismatch: Blade uses `tenant.geography.viewAny`, controller uses `system-config.geography.viewAny` | Potential auth bypass if permissions are misconfigured | ⬜ Investigate |
| 3 | No feature tests exist — this list is forward-looking | All TCs unexecuted | ⬜ Backlog |

---

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/system-config/location` | `system-config.location.index` | `TenantLocationController@index` |
| GET | `/system-config/location/search` | `system-config.location.search` | `TenantLocationController@search` |

---

## 10. Execution Status

| Total TCs | Pass | Fail | Blocked | Not Run | Coverage |
|-----------|------|------|---------|---------|----------|
| 50 | 0 | 0 | 0 | 50 | 0% |

**Last Executed:** —
**Executed By:** —
**Environment:** —
**Remarks:** Initial test case list created from code analysis. CRUD tests not applicable (view-only feature).

---

## Document History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-23 | OpenCode AI | Initial TC list from controller + FRD analysis |
