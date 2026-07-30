# SYS — sys_DropdownValues — Test Case List & Business Conditions

**Module:** SystemConfig (SYS) · **Feature:** Dropdown Value Management
**Code:** SYS · **Prefix:** `sys_` · **DB scope:** Central (`sys_dropdown_table` in prime_db)
**Primary table:** `sys_dropdown_table` · **Junction table:** `sys_dropdown_need_dropdowns_jnt`
**Test style:** HTTP Feature Tests (PHPUnit/Pest) · **Controller:** `TenantDropdownController` (258 lines)
**FormRequest:** `TenantDropdownRequest`

**Routes (prefix `system-config.`):**

- `GET /system-config/dropdown` — grouped index (master view)
- `GET /system-config/dropdown/create` — create form
- `POST /system-config/dropdown` — store values (comma-separated)
- `GET /system-config/dropdown/{id}/edit` — edit form
- `PUT /system-config/dropdown/{id}` — update value
- `DELETE /system-config/dropdown/{id}` — soft-delete
- `GET /system-config/dropdown/trash` — trash view
- `GET /system-config/dropdown/{id}/restore` — restore
- `DELETE /system-config/dropdown/{id}/force-delete` — force delete
- `POST /system-config/dropdown/{id}/toggle-status` — toggle status
- `GET /system-config/dropdown/columns` — AJAX get columns

---

## 1. Business Conditions

### BC-SCHEMA — Schema & Model

| ID | Condition | Source |
|----|-----------|--------|
| BC-SCHEMA-01 | Table `sys_dropdown_table` exists with columns: `id` (INT PK AI), `ordinal` (TINYINT UNSIGNED), `key` (VARCHAR 160), `value` (VARCHAR 100), `type` (ENUM 'String','Integer','Decimal','Date','Datetime','Time','Boolean'), `additional_info` (JSON NULL), `is_active` (TINYINT 1), `created_at`, `updated_at`, `deleted_at` | DDL: prime_db_v3.sql:215-228 |
| BC-SCHEMA-02 | Model `Dropdown`: table `sys_dropdown_table`, uses `SoftDeletes` + `BaseModel` | Dropdown.php:8-12 |
| BC-SCHEMA-03 | Fillable: `ordinal`, `key`, `value`, `type`, `additional_info`, `is_active` | Dropdown.php:14-21 |
| BC-SCHEMA-04 | Casts: `ordinal`→integer, `is_active`→boolean, `deleted_at`→datetime | Dropdown.php:23-27 |
| BC-SCHEMA-05 | Defaults: `type`='String', `is_active`=true | Dropdown.php:29-32 |
| BC-SCHEMA-06 | Relationship `dropdownNeeds()`: belongsToMany via `sys_dropdown_need_dropdowns_jnt` with pivot `is_active` | Dropdown.php:34-43 |
| BC-SCHEMA-07 | Relationship `junction()`: hasOne `DropdownNeedDropdown` | Dropdown.php:45-48 |
| BC-SCHEMA-08 | UNIQUE KEY `uq_dropdownTable_key_ordinal` on (`key`, `ordinal`) | DDL: prime_db_v3.sql:226 |
| BC-SCHEMA-09 | UNIQUE KEY `uq_dropdownTable_key_value` on (`key`, `value`) | DDL: prime_db_v3.sql:227 |

### BC-VALIDATION — Validation Rules

| ID | Condition | Source |
|----|-----------|--------|
| BC-VALIDATION-01 | `key`: required, string, max:160 | TenantDropdownRequest:23 |
| BC-VALIDATION-02 | `value`: required, string, max:255 | TenantDropdownRequest:24-28 |
| BC-VALIDATION-03 | `type`: nullable, in:String/Integer/Decimal/Date/Datetime/Time/Boolean | TenantDropdownRequest:30-32 |
| BC-VALIDATION-04 | `additional_info`: nullable, string | TenantDropdownRequest:33 |
| BC-VALIDATION-05 | `is_active`: boolean (prepared from 'on' checkbox) | TenantDropdownRequest:34, 40-42 |
| BC-VALIDATION-06 | Store splits value by comma, array_unique, array_filter, trim | Ctrl:95 |
| BC-VALIDATION-07 | Key slugified via `Str::slug($key, '_')` server-side | Ctrl:97 |
| BC-VALIDATION-08 | Ordinal = MAX(ordinal for key) + 1; 0 if none | Ctrl:97 |
| BC-VALIDATION-09 | Update preserves `additional_info` if not provided in request | Ctrl:137-139 |
| BC-VALIDATION-10 | getColumns: `table_name` required; whitelist only `sys_dropdown_table`, `sys_settings`, `sys_users` | Ctrl:228-231 |

### BC-AUTH — Authorization

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` gate `system-config.dropdown.viewAny` | Ctrl:23 |
| BC-AUTH-02 | `create()`/`store()` gate `system-config.dropdown.create` | Ctrl:72, 92 |
| BC-AUTH-03 | `edit()`/`update()` gate `system-config.dropdown.update` | Ctrl:122, 134 |
| BC-AUTH-04 | `destroy()` gate `system-config.dropdown.delete` | Ctrl:160 |
| BC-AUTH-05 | `trashed()`/`restore()` gate `system-config.dropdown.restore` | Ctrl:177, 189 |
| BC-AUTH-06 | `forceDelete()` gate `system-config.dropdown.forceDelete` | Ctrl:206 |
| BC-AUTH-07 | `toggleStatus()` gate `system-config.dropdown.update` | Ctrl:247 |
| BC-AUTH-08 | `getColumns()` gate `system-config.dropdown.viewAny` | Ctrl:222 |
| BC-AUTH-09 | TenantDropdownRequest::authorize(): POST→`system-config.dropdown.create`, PUT→`system-config.dropdown.update` | TenantDropdownRequest:13-17 |

### BC-BIZ — Business Logic

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Index displays grouped dropdowns: distinct keys paginated per 10, each key expands to values ordered by ordinal | Ctrl:27-62 |
| BC-BIZ-02 | Index filters: `search` (key/value LIKE), `type` (exact), `status` (is_active) | Ctrl:29-38, 46-48 |
| BC-BIZ-03 | Store creates N records from comma-separated values; each with sequential ordinal | Ctrl:95-112 |
| BC-BIZ-04 | Store derives key as `Str::slug($data['key'], '_')` regardless of input format | Ctrl:97 |
| BC-BIZ-05 | Store calls activityLog per-value with 'Stored' event | Ctrl:111 |
| BC-BIZ-06 | Store redirects to `system-config.dropdown.index` with success flash | Ctrl:114 |
| BC-BIZ-07 | Update preserves `additional_info` when not provided in request body | Ctrl:137-139 |
| BC-BIZ-08 | Update logs 'Updated' activity with before/after changes (excluding updated_at) | Ctrl:144-150 |
| BC-BIZ-09 | Update redirects to index with success flash | Ctrl:152 |
| BC-BIZ-10 | Destroy sets `is_active=false`, then soft-deletes, logs 'Trashed' | Ctrl:163-169 |
| BC-BIZ-11 | Destroy redirects to index with success flash | Ctrl:169 |
| BC-BIZ-12 | Trashed returns only soft-deleted records, ordered by key, paginated 15/page | Ctrl:179 |
| BC-BIZ-13 | Restore recovers record, sets `is_active=true`, logs 'Restored' | Ctrl:191-198 |
| BC-BIZ-14 | Restore redirects to trash view with success flash | Ctrl:198 |
| BC-BIZ-15 | ForceDelete removes junction entries first, then force-deletes dropdown, logs 'Deleted' | Ctrl:208-217 |
| BC-BIZ-16 | ForceDelete redirects to trash view with success flash | Ctrl:217 |
| BC-BIZ-17 | ToggleStatus flips is_active, logs 'Toggled' with new status, returns JSON | Ctrl:245-256 |
| BC-BIZ-18 | getColumns returns column listing from Schema::getColumnListing() for whitelisted tables only | Ctrl:220-239 |
| BC-BIZ-19 | Create form loads tenant tables via SHOW TABLES for display | Ctrl:70-84 |

### BC-EDGE — Edge Cases

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDGE-01 | Non-existing ID → 404 (findOrFail for edit/update/destroy) | Ctrl |
| BC-EDGE-02 | `withTrashed()->findOrFail()` for restore/forceDelete → 404 if not in trash | Ctrl:191, 208 |
| BC-EDGE-03 | Empty comma-separated value string → skips empty entries (array_filter), no records created | Ctrl:95 |
| BC-EDGE-04 | Duplicate values in comma list → deduplicated by array_unique | Ctrl:95 |
| BC-EDGE-05 | Duplicate (key, value) → DB UNIQUE violation → 500 (not graceful) | DDL:227 |
| BC-EDGE-06 | Concurrent ordinal collision → DB UNIQUE violation → 500 (not graceful) | DDL:226 |
| BC-EDGE-07 | getColumns with empty table_name → returns empty array | Ctrl:224-225 |
| BC-EDGE-08 | getColumns with invalid table → returns 422 JSON error | Ctrl:228-231 |
| BC-EDGE-09 | getColumns with valid but empty table → returns empty array from Schema::getColumnListing | Ctrl:234-235 |
| BC-EDGE-10 | Toggle on non-existent ID → 404 (implicit Route Model Binding) | Ctrl:245 |
| BC-EDGE-11 | Store with all values filtered out (empty after array_filter) → redirect with success but 0 records | Ctrl:95 |
| BC-EDGE-12 | Update of soft-deleted record → 404 (implicit model binding excludes soft-deleted) | Ctrl:132 |
| BC-EDGE-13 | ForceDelete on active (non-trashed) record → 404 (withTrashed finds nothing) | Ctrl:208 |

---

## 2. Test Case List

### Cross-Cutting — Schema, Model, Auth

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P01 | Schema | DDL/Model | Migration, model, table (`sys_dropdown_table`), fillable (6 fields), casts, SoftDeletes, defaults | All pass | — | ⬜ |
| TC-DDV-P02 | Schema | DDL/Model | UNIQUE KEYs: `uq_dropdownTable_key_ordinal` and `uq_dropdownTable_key_value` exist | Both present | — | ⬜ |
| TC-DDV-P03 | Schema | Model | Relationship `dropdownNeeds()` works with pivot `is_active` | Correct relation | — | ⬜ |
| TC-DDV-P04 | Schema | Model | Relationship `junction()` exists as hasOne | Correct relation | — | ⬜ |
| TC-DDV-P05 | Schema | Routes | All 11 routes registered in `routes/tenant.php` under `system-config.` | All present | — | ⬜ |
| TC-DDV-P10 | Auth | Middleware | Guest user redirected to login for all routes | /login | — | ⬜ |
| TC-DDV-P11 | Auth | Ctrl | Gate authorization present on all 11 methods | Gates present | — | ⬜ |
| TC-DDV-N12 | Auth | Ctrl | User without `system-config.dropdown.viewAny` → 403 on index/getColumns | 403 | — | ⬜ |
| TC-DDV-N13 | Auth | Ctrl | User without `system-config.dropdown.create` → 403 on create/store | 403 | — | ⬜ |
| TC-DDV-N14 | Auth | Ctrl | User without `system-config.dropdown.update` → 403 on edit/update/toggleStatus | 403 | — | ⬜ |
| TC-DDV-N15 | Auth | Ctrl | User without `system-config.dropdown.delete` → 403 on destroy | 403 | — | ⬜ |
| TC-DDV-N16 | Auth | Ctrl | User without `system-config.dropdown.restore` → 403 on trashed/restore | 403 | — | ⬜ |
| TC-DDV-N17 | Auth | Ctrl | User without `system-config.dropdown.forceDelete` → 403 on forceDelete | 403 | — | ⬜ |
| TC-DDV-N18 | Auth | FR | FormRequest authorize() matches controller gates | Consistent | — | ⬜ |

### Screen 1: Index — Grouped Dropdown List (GET /system-config/dropdown)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P30 | Positive | View | Index displays grouped accordion: distinct keys paginated 10/page | Page rendered | — | ⬜ |
| TC-DDV-P31 | Positive | View | Each accordion section shows values ordered by ordinal | Ordered | — | ⬜ |
| TC-DDV-P32 | Positive | Ctrl | Filter by `search` (key/value LIKE) narrows keys | Filtered | — | ⬜ |
| TC-DDV-P33 | Positive | Ctrl | Filter by `type` narrows results | Filtered | — | ⬜ |
| TC-DDV-P34 | Positive | Ctrl | Filter by `status` (is_active) narrows results | Filtered | — | ⬜ |
| TC-DDV-P35 | Positive | View | Empty state when no records match filters | "Not Data Found" | — | ⬜ |
| TC-DDV-P36 | Positive | View | "Add New" button links to create page | Link works | — | ⬜ |
| TC-DDV-P37 | Positive | View | Trash link visible and links to trash view | Link works | — | ⬜ |

### Screen 2: Create Form (GET /system-config/dropdown/create)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P40 | Positive | View | Create page renders: key input, value textarea, type select, additional_info, status switch | All fields rendered | — | ⬜ |
| TC-DDV-P41 | Positive | View | Create page shows tenant table listing (from SHOW TABLES) | Table listed | — | ⬜ |

### Screen 3: Store (POST /system-config/dropdown)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P50 | Positive | Ctrl | Store single value creates dropdown record with slugified key | Created | — | ⬜ |
| TC-DDV-P51 | Positive | Ctrl | Store comma-separated "A+,B+,AB+" creates 3 records with sequential ordinals | 3 records | — | ⬜ |
| TC-DDV-P52 | Positive | Ctrl | Ordinal auto-assigned as MAX+1 within key group | Correct ordinal | — | ⬜ |
| TC-DDV-P53 | Positive | Ctrl | Key slugified with underscore: "Test Key" → "test_key" | Slugified | — | ⬜ |
| TC-DDV-P54 | Positive | Ctrl | Deduplicates repeated values in comma list | Unique values | — | ⬜ |
| TC-DDV-P55 | Positive | Ctrl | Store logs "Stored" activity per value | Log entries | — | ⬜ |
| TC-DDV-P56 | Positive | Ctrl | Store redirects to index with success flash | Redirect + flash | — | ⬜ |
| TC-DDV-P57 | Positive | Ctrl | `is_active` defaults to true when not provided | is_active=1 | — | ⬜ |
| TC-DDV-P58 | Positive | Ctrl | `type` defaults to 'String' when not provided | type='String' | — | ⬜ |
| TC-DDV-N60 | Negative | Ctrl | Empty key → validation error | 422 | — | ⬜ |
| TC-DDV-N61 | Negative | Ctrl | Empty value → validation error | 422 | — | ⬜ |
| TC-DDV-N62 | Negative | Ctrl | Key exceeds 160 chars → validation error | 422 | — | ⬜ |
| TC-DDV-N63 | Negative | Ctrl | Value exceeds 255 chars → validation error | 422 | — | ⬜ |
| TC-DDV-N64 | Negative | Ctrl | Invalid type → validation error | 422 | — | ⬜ |
| TC-DDV-N65 | Negative | Ctrl | Duplicate (key, value) → DB UNIQUE violation → 500 (not graceful) | 500 | — | ⬜ |
| TC-DDV-N66 | Negative | Ctrl | Concurrent ordinal MAX+1 collision → DB UNIQUE violation → 500 | 500 | — | ⬜ |
| TC-DDV-N67 | Negative | Ctrl | Empty value after filtering (only whitespace) → redirect with success but 0 records | 0 records | — | ⬜ |

### Screen 4: Edit (GET /system-config/dropdown/{id}/edit)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P70 | Positive | View | Edit page pre-fills with existing values for all editable fields | Pre-filled | — | ⬜ |
| TC-DDV-N71 | Negative | Ctrl | Invalid ID → 404 | 404 | — | ⬜ |
| TC-DDV-N72 | Negative | Ctrl | Soft-deleted ID → 404 (no withTrashed) | 404 | — | ⬜ |

### Screen 5: Update (PUT /system-config/dropdown/{id})

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P80 | Positive | Ctrl | Update modifies value, type, ordinal and logs 'Updated' with changes | Updated + log | — | ⬜ |
| TC-DDV-P81 | Positive | Ctrl | Update preserves `additional_info` when not sent in request | Preserved | — | ⬜ |
| TC-DDV-P82 | Positive | Ctrl | Update redirects to index with success flash | Redirect + flash | — | ⬜ |
| TC-DDV-N83 | Negative | Ctrl | Invalid ID → 404 | 404 | — | ⬜ |
| TC-DDV-N84 | Negative | Ctrl | Update with empty value → validation error | 422 | — | ⬜ |
| TC-DDV-N85 | Negative | Ctrl | Update with invalid type → validation error | 422 | — | ⬜ |

### Screen 6: Destroy (DELETE /system-config/dropdown/{id})

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P90 | Positive | Ctrl | Destroy sets is_active=false, soft-deletes, logs 'Trashed' | Soft-deleted | — | ⬜ |
| TC-DDV-P91 | Positive | Ctrl | Destroy redirects to index with success flash | Redirect + flash | — | ⬜ |
| TC-DDV-N92 | Negative | Ctrl | Invalid ID → 404 | 404 | — | ⬜ |

### Screen 7: Trash (GET /system-config/dropdown/trash)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P100 | Positive | View | Trash page lists soft-deleted dropdowns | Trashed listed | — | ⬜ |
| TC-DDV-P101 | Positive | View | Each trashed row shows key, value, type, ordinal | Fields shown | — | ⬜ |
| TC-DDV-P102 | Positive | View | Each trashed row has Restore and Force Delete buttons | 2 buttons | — | ⬜ |
| TC-DDV-P103 | Positive | View | Trash page paginated (15/page) | Paginated | — | ⬜ |

### Screen 8: Restore (GET /system-config/dropdown/{id}/restore)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P110 | Positive | Ctrl | Restore recovers record, sets is_active=true, logs 'Restored' | Restored | — | ⬜ |
| TC-DDV-P111 | Positive | Ctrl | Restore redirects to trash view with success flash | Redirect + flash | — | ⬜ |
| TC-DDV-N112 | Negative | Ctrl | Restore on non-trashed/non-existing ID → 404 | 404 | — | ⬜ |

### Screen 9: Force Delete (DELETE /system-config/dropdown/{id}/force-delete)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P120 | Positive | Ctrl | Force delete removes junction entries + dropdown permanently, logs 'Deleted' | Deleted + junction cleanup | — | ⬜ |
| TC-DDV-P121 | Positive | Ctrl | Force delete redirects to trash view with success flash | Redirect + flash | — | ⬜ |
| TC-DDV-N122 | Negative | Ctrl | Force delete on non-trashed ID → 404 | 404 | — | ⬜ |

### Screen 10: Toggle Status (POST /system-config/dropdown/{id}/toggle-status)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P130 | Positive | Ctrl | Toggle active→inactive: is_active flips to false | is_active=false | — | ⬜ |
| TC-DDV-P131 | Positive | Ctrl | Toggle inactive→active: is_active flips to true | is_active=true | — | ⬜ |
| TC-DDV-P132 | Positive | Ctrl | Toggle returns JSON `{success: true, is_active, message}` | JSON response | — | ⬜ |
| TC-DDV-P133 | Positive | Ctrl | Toggle logs 'Toggled' activity with new status | Log entry | — | ⬜ |
| TC-DDV-N134 | Negative | Ctrl | Non-existent ID → 404 (route model binding) | 404 | — | ⬜ |

### Screen 11: AJAX — Get Columns (GET /system-config/dropdown/columns)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P140 | Positive | Ctrl | getColumns with allowed table returns JSON array of column names | Array | — | ⬜ |
| TC-DDV-N141 | Negative | Ctrl | getColumns with empty table_name → empty array | [] | — | ⬜ |
| TC-DDV-N142 | Negative | Ctrl | getColumns with disallowed table → 422 `{error: "Invalid table"}` | 422 JSON | — | ⬜ |
| TC-DDV-N143 | Negative | Ctrl | getColumns with non-existent but allowed table → empty array | [] | — | ⬜ |

### Screen 12: Activity Logging (Cross-Cutting)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-P150 | Positive | Ctrl | Store logs 'Stored' activity with entity type, ID, user | Log entry | — | ⬜ |
| TC-DDV-P151 | Positive | Ctrl | Update logs 'Updated' with before/after changes | Log entry | — | ⬜ |
| TC-DDV-P152 | Positive | Ctrl | Destroy logs 'Trashed' activity | Log entry | — | ⬜ |
| TC-DDV-P153 | Positive | Ctrl | Restore logs 'Restored' activity | Log entry | — | ⬜ |
| TC-DDV-P154 | Positive | Ctrl | ForceDelete logs 'Deleted' activity | Log entry | — | ⬜ |
| TC-DDV-P155 | Positive | Ctrl | ToggleStatus logs 'Toggled' activity with new_status | Log entry | — | ⬜ |

### Screen 13: Business Rule Gap Tests (Known Issues)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-G01 | Gap | BR-SYS-007 | Store a value WITHOUT matching DropdownNeed → currently SUCCEEDS (should be blocked) | Current: 201·Expected: 422 | — | ⬜ |
| TC-DDV-G02 | Gap | BR-SYS-008 | Store with injected key `"anything_injected"` → currently accepted as-is (should derive from Need) | Current: created·Expected: derived | — | ⬜ |
| TC-DDV-G03 | Gap | BR-SYS-016 | Destroy a value that WOULD be referenced by school data → currently succeeds (should block) | Current: 302·Expected: blocked | — | ⬜ |

### Screen 14: Edge Cases & Security

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDV-N180 | Negative | Security | XSS attempt in value text stored → escaped on render | Escaped | — | ⬜ |
| TC-DDV-N181 | Negative | Security | SQL injection in getColumns table_name parameter → safe | Safe | — | ⬜ |
| TC-DDV-N182 | Negative | Security | Large payload in store (1000+ values) → reasonable-size rejection | 413/422 | — | ⬜ |
| TC-DDV-N183 | Negative | Edge | JSON injection in additional_info → stored as-is (JSON column) | Stored | — | ⬜ |
| TC-DDV-N184 | Negative | Edge | getColumns with special characters in table_name → 422 | 422 | — | ⬜ |

---

## 3. Test Method Index

**File:** `sys_DropdownValues_Test.php` (estimated ~65 methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_schema_model_and_table | TC-DDV-P01 | Schema | 01-09 |
| 2 | test_schema_db_unique_constraints | TC-DDV-P02 | Schema | 01-09 |
| 3 | test_schema_model_relationships | TC-DDV-P03, P04 | Schema | 01-09 |
| 4 | test_schema_routes_registered | TC-DDV-P05 | Schema | 01-09 |
| 5 | test_auth_guest_redirected | TC-DDV-P10 | Auth | 10-19 |
| 6 | test_auth_gates_present | TC-DDV-P11 | Auth | 10-19 |
| 7 | test_auth_without_viewAny_gets_403 | TC-DDV-N12 | Auth | 10-19 |
| 8 | test_auth_without_create_gets_403 | TC-DDV-N13 | Auth | 10-19 |
| 9 | test_auth_without_update_gets_403 | TC-DDV-N14 | Auth | 10-19 |
| 10 | test_auth_without_delete_gets_403 | TC-DDV-N15 | Auth | 10-19 |
| 11 | test_auth_without_restore_gets_403 | TC-DDV-N16 | Auth | 10-19 |
| 12 | test_auth_without_forceDelete_gets_403 | TC-DDV-N17 | Auth | 10-19 |
| 13 | test_auth_form_request_consistency | TC-DDV-N18 | Auth | 10-19 |
| 14 | test_index_page_renders | TC-DDV-P30 | Index | 30-37 |
| 15 | test_index_search_filter | TC-DDV-P32 | Index | 30-37 |
| 16 | test_index_type_filter | TC-DDV-P33 | Index | 30-37 |
| 17 | test_index_status_filter | TC-DDV-P34 | Index | 30-37 |
| 18 | test_index_empty_state | TC-DDV-P35 | Index | 30-37 |
| 19 | test_create_page_renders | TC-DDV-P40, P41 | Create | 40-41 |
| 20 | test_store_single_value | TC-DDV-P50 | Store | 50-58 |
| 21 | test_store_comma_separated_values | TC-DDV-P51 | Store | 50-58 |
| 22 | test_store_ordinal_auto_increment | TC-DDV-P52 | Store | 50-58 |
| 23 | test_store_key_slugified | TC-DDV-P53 | Store | 50-58 |
| 24 | test_store_deduplication | TC-DDV-P54 | Store | 50-58 |
| 25 | test_store_logs_activity | TC-DDV-P55 | Store | 50-58 |
| 26 | test_store_defaults | TC-DDV-P57, P58 | Store | 50-58 |
| 27 | test_validation_key_required | TC-DDV-N60 | Val | 60-67 |
| 28 | test_validation_value_required | TC-DDV-N61 | Val | 60-67 |
| 29 | test_validation_key_max_length | TC-DDV-N62 | Val | 60-67 |
| 30 | test_validation_value_max_length | TC-DDV-N63 | Val | 60-67 |
| 31 | test_validation_type_invalid | TC-DDV-N64 | Val | 60-67 |
| 32 | test_validation_duplicate_key_value | TC-DDV-N65 | Val | 60-67 |
| 33 | test_validation_empty_after_filter | TC-DDV-N67 | Val | 60-67 |
| 34 | test_edit_page_prefills | TC-DDV-P70 | Edit | 70-72 |
| 35 | test_edit_invalid_id | TC-DDV-N71, N72 | Edit | 70-72 |
| 36 | test_update_success | TC-DDV-P80 | Update | 80-85 |
| 37 | test_update_preserves_additional_info | TC-DDV-P81 | Update | 80-85 |
| 38 | test_update_invalid_id | TC-DDV-N83 | Update | 80-85 |
| 39 | test_update_validation | TC-DDV-N84, N85 | Update | 80-85 |
| 40 | test_destroy_soft_delete | TC-DDV-P90 | Destroy | 90-92 |
| 41 | test_destroy_invalid_id | TC-DDV-N92 | Destroy | 90-92 |
| 42 | test_trash_view | TC-DDV-P100-P103 | Trash | 100-103 |
| 43 | test_restore_success | TC-DDV-P110 | Restore | 110-112 |
| 44 | test_restore_non_trashed | TC-DDV-N112 | Restore | 110-112 |
| 45 | test_force_delete_cleanup | TC-DDV-P120 | ForceDel | 120-122 |
| 46 | test_force_delete_non_trashed | TC-DDV-N122 | ForceDel | 120-122 |
| 47 | test_toggle_active_to_inactive | TC-DDV-P130 | Toggle | 130-134 |
| 48 | test_toggle_inactive_to_active | TC-DDV-P131 | Toggle | 130-134 |
| 49 | test_toggle_returns_json | TC-DDV-P132 | Toggle | 130-134 |
| 50 | test_toggle_logs_activity | TC-DDV-P133 | Toggle | 130-134 |
| 51 | test_toggle_non_existent | TC-DDV-N134 | Toggle | 130-134 |
| 52 | test_get_columns_valid_table | TC-DDV-P140 | Columns | 140-143 |
| 53 | test_get_columns_empty_table | TC-DDV-N141 | Columns | 140-143 |
| 54 | test_get_columns_invalid_table | TC-DDV-N142 | Columns | 140-143 |
| 55 | test_get_columns_allowed_tables | TC-DDV-N143 | Columns | 140-143 |
| 56 | test_activity_log_store | TC-DDV-P150 | Audit | 150-155 |
| 57 | test_activity_log_update | TC-DDV-P151 | Audit | 150-155 |
| 58 | test_activity_log_destroy | TC-DDV-P152 | Audit | 150-155 |
| 59 | test_activity_log_restore | TC-DDV-P153 | Audit | 150-155 |
| 60 | test_activity_log_forceDelete | TC-DDV-P154 | Audit | 150-155 |
| 61 | test_activity_log_toggle | TC-DDV-P155 | Audit | 150-155 |
| 62 | test_gap_br_sys_007_not_enforced | TC-DDV-G01 | Gap | — |
| 63 | test_gap_br_sys_008_key_derivation | TC-DDV-G02 | Gap | — |
| 64 | test_gap_br_sys_016_reference_check | TC-DDV-G03 | Gap | — |
| 65 | test_security_xss_and_injection | TC-DDV-N180-N184 | Security | 180-184 |

**Total: 65 methods (62 Automated, 3 Gap-documented, 0 Planned).**

---

## 4. Notes

### Critical Business Rule Gaps (Documented as Known Failures)

| Gap ID | BR Ref | Description | Severity | Current Behaviour |
|--------|--------|-------------|----------|-------------------|
| GAP-01 | BR-SYS-007 | No Need check on value creation | Critical | Value created without verifying Need exists |
| GAP-02 | BR-SYS-008 | Key accepted from request, not derived from Need | Critical | User-provided key slugified but not validated against registered Needs |
| GAP-03 | BR-SYS-016 | No reference check before deletion | High | Value deleted even if referenced by school data |

### Additional Notes

- **DB UNIQUE constraints** enforce (key, ordinal) and (key, value) uniqueness but concurrent writes can cause 500 errors — use `updateOrCreate` or explicit try-catch for graceful handling
- **`getColumns` whitelist** is restrictive (3 tables): `sys_dropdown_table`, `sys_settings`, `sys_users`. Any new table requiring column discovery needs whitelist update
- **Permission naming:** Uses `system-config.dropdown.*` prefix — distinct from `tenant.dropdown.*` used by the Dropdown Needs controller. Tests must verify the correct gate name
- **Test Status:** All TCs currently marked `⬜` (not yet implemented). Gap TCs (TC-DDV-G01–G03) document known business rule violations that need to be resolved first
