# tt_ConfigSettings_TcList

## Module: TimetableFoundation → Timetable Configuration → Config Settings

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Configuration |
| Feature | Config Settings |
| URL(s) | `GET /timetable-foundation/timetable-configuration` (menu page, tab=`tt-config`) — `GET /timetable-foundation/config/create` — `POST /timetable-foundation/config` — `GET /timetable-foundation/config/{config}` — `GET /timetable-foundation/config/{config}/edit` — `PUT /timetable-foundation/config/{config}` — `DELETE /timetable-foundation/config/{config}` — `POST /timetable-foundation/config/{config}/toggle-status` — `GET /timetable-foundation/config/trash/view` — `GET /timetable-foundation/config/{id}/restore` — `DELETE /timetable-foundation/config/{id}/force-delete` — `POST /timetable-foundation/priority-config/recalculate` |
| Controller | `Modules\TimetableFoundation\Http\Controllers\ConfigController` (`index()` redirects to menu page; `create()` lines 23-38; `store()` lines 43-100; `show()` lines 102-115; `edit()` lines 120-133; `update()` lines 138-192; `destroy()` lines 197-212; `trashed()` lines 217-221; `restore()` lines 224-238; `forceDelete()` lines 240-254; `toggleStatus()` lines 259-289); `Modules\TimetableFoundation\Http\Controllers\PriorityConfigController` (`recalculate()` lines 21-36) |
| Model(s) | `Modules\TimetableFoundation\Models\Config` (table: `tt_configs`); `Modules\SmartTimetable\Models\PriorityConfig` (table: `tt_priority_configs`) |
| Validation (Create) | `Modules\TimetableFoundation\Http\Requests\ConfigRequest` — `rules()` lines 17-43, `prepareForValidation()` lines 59-101, `withValidator()` lines 130-182 |
| Validation (Update) | Same `ConfigRequest` — `rules()` uses `$isUpdate` branch (line 32) |
| Policy | `Modules\TimetableFoundation\Policies\TimetableConfigPolicy` (registered as `Config::class => TimetableConfigPolicy::class`) |
| Permissions | `timetable-foundation.config.create`, `timetable-foundation.config.view`, `timetable-foundation.config.update`, `timetable-foundation.config.delete`, `timetable-foundation.config.restore`, `timetable-foundation.config.forceDelete`, `timetable-foundation.viewAny`, `timetable-foundation.timetable-configuration.viewAny` |
| Pagination | Main listing: no pagination (all records via `->get()`). Trashed view: 10 records per page using default `page` parameter. |
| Soft Deletes | Yes — `SoftDeletes` trait on `Config` model. `destroy()` sets `is_active=false` before `->delete()`. `restore()` does NOT auto-set `is_active=true`. |

---

## 2. Pre-conditions

- **Permissions required:**
  - `timetable-foundation.viewAny` — access the menu page
  - `timetable-foundation.config.create` — create new config
  - `timetable-foundation.config.view` — view config details
  - `timetable-foundation.config.update` — edit and toggle status
  - `timetable-foundation.config.delete` — soft delete
  - `timetable-foundation.config.restore` — view trashed list, restore
  - `timetable-foundation.config.forceDelete` — permanently delete
- **Seed data:** At least 2 active and 1 inactive `tt_configs` record with different `value_type` values (STRING, NUMBER, BOOLEAN).
- **Tenant context:** Logged in as a tenant admin or super admin on an initialized tenant with a valid academic session.
- **Dusk env vars:** `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD` must be set.

---

## 3. Default Data Load

The `TimetableFoundationController::timetableConfiguration()` method (gate: `timetable-foundation.viewAny`) loads the Timetable Configuration menu page with tab parameter `tab=tt-config`. Default filter values: none (all statuses, no search).

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Config Grid | `timetableConfiguration()` line 127-136 | `Config::query()->when(cfg_search, search key_name/value/description)->when(cfg_status, filter is_active)->orderBy('ordinal')` | `cfg_search` (text search on key_name, value, description), `cfg_status` (1=active, 0=inactive, ''=all) | None (all matching records) |
| Trashed Configs | `trashed()` line 217-221 | `Config::onlyTrashed()->orderBy('deleted_at', 'desc')` | None | 10/page (`page` param) |

---

## 4. Test Data Strategy

- Create test `tt_configs` records directly via factory or DB insert with known `key`, `key_name`, `value`, `value_type`, `ordinal`, and flag values.
- Use consistent ordinal values: 1, 2, 3, … for seeding display order.
- Use date range: `2026-01-01` to `2026-12-31` for DATE/DATETIME value type tests.
- Pre-test cleanup: delete all `tt_configs` records before the test run to avoid unique key collisions.
- For pagination on the trashed view: create 12 trashed records (10 + 2 overflow) to verify page 2 loads.
- For search tests: create records with distinguishable key names (e.g., `max_periods_per_day`, `min_teacher_load`, `enable_lunch_tracking`).
- For `tt_priority_configs` recalculate tests: seed at least one active `RequirementConsolidation` record along with associated `SchoolDay`, `PeriodSet`, `Room`, and `TeacherAvailability` data.

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_configs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | INT UNSIGNED | PK, AUTO_INCREMENT, NOT NULL |
| BC-DB-02 | `ordinal` | int unsigned | NOT NULL, DEFAULT '1', UNIQUE (`uq_settings_ordinal`) |
| BC-DB-03 | `key` | varchar(150) | NOT NULL, UNIQUE (`uq_settings_key`) |
| BC-DB-04 | `key_name` | varchar(150) | NOT NULL |
| BC-DB-05 | `value` | varchar(512) | NOT NULL |
| BC-DB-06 | `value_type` | ENUM('STRING','NUMBER','BOOLEAN','DATE','TIME','DATETIME','JSON') | NOT NULL |
| BC-DB-07 | `description` | varchar(255) | NOT NULL |
| BC-DB-08 | `additional_info` | JSON | DEFAULT NULL |
| BC-DB-09 | `tenant_can_modify` | tinyint(1) | NOT NULL, DEFAULT '0' |
| BC-DB-10 | `mandatory` | tinyint(1) | NOT NULL, DEFAULT '1' |
| BC-DB-11 | `used_by_app` | tinyint(1) | NOT NULL, DEFAULT '1' |
| BC-DB-12 | `is_active` | tinyint(1) | NOT NULL, DEFAULT '1' |
| BC-DB-13 | `deleted_at` | timestamp | NULL DEFAULT NULL |
| BC-DB-14 | `created_at` | timestamp | NULL DEFAULT NULL |
| BC-DB-15 | `updated_at` | timestamp | NULL DEFAULT NULL |
| BC-DB-16 | — | UNIQUE KEY `uq_settings_ordinal` | (`ordinal`) |
| BC-DB-17 | — | UNIQUE KEY `uq_settings_key` | (`key`) |

### 5.2 Database Schema — `tt_priority_configs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-18 | `id` | INT UNSIGNED | PK, AUTO_INCREMENT, NOT NULL |
| BC-DB-19 | `requirement_consolidation_id` | INT UNSIGNED | NOT NULL, FK → `tt_requirement_consolidations.id` |
| BC-DB-20 | `tot_students` | INT UNSIGNED | DEFAULT NULL |
| BC-DB-21 | `teacher_scarcity_index` | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| BC-DB-22 | `weekly_load_ratio` | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| BC-DB-23 | `average_teacher_availability_ratio` | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| BC-DB-24 | `rigidity_score` | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| BC-DB-25 | `resource_scarcity` | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| BC-DB-26 | `subject_difficulty_index` | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| BC-DB-27 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |

### 5.3 Validation Rules — `ConfigRequest` (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `ordinal` | `required\|integer\|min:1` | — (default Laravel) |
| BC-VAL-02 | `key` | `required\|string\|max:100\|unique:tt_configs,key` | "This configuration key already exists." |
| BC-VAL-03 | `key_name` | `nullable\|string\|max:255` | — |
| BC-VAL-04 | `value_type` | `required\|in:STRING,NUMBER,BOOLEAN,DATE,TIME,DATETIME,JSON` | "Please select a valid value type." |
| BC-VAL-05 | `value` (STRING) | `required\|string` | — |
| BC-VAL-06 | `value` (NUMBER) | `required\|numeric` | "Please enter a valid number." |
| BC-VAL-07 | `value` (BOOLEAN) | `required\|in:true,false,0,1` | "Please select either true or false." |
| BC-VAL-08 | `value` (JSON) | `required\|json` | "Please enter valid JSON format." |
| BC-VAL-09 | `value` (DATE) | `required\|date` | "Please enter a valid date." |
| BC-VAL-10 | `value` (TIME) | `required\|date_format:H:i` | "Please enter a valid time format (HH:MM)." |
| BC-VAL-11 | `value` (DATETIME) | `required\|date` | "Please enter a valid date and time." |
| BC-VAL-12 | `description` | `nullable\|string` | — |
| BC-VAL-13 | `additional_info` | `nullable\|string` (JSON validated in `withValidator()`) | "Invalid JSON format." |
| BC-VAL-14 | `tenant_can_modify` | `boolean` | — |
| BC-VAL-15 | `mandatory` | `boolean` | — |
| BC-VAL-16 | `used_by_app` | `boolean` | — |
| BC-VAL-17 | `is_active` | `boolean` | — |
| BC-VAL-18 | **Controller-level (store):** Duplicate key check (`Config::where('key', ...)->exists()`) | "This key already exists. Please choose a different key." |
| BC-VAL-19 | **Controller-level (store):** Invalid `additional_info` JSON decode | "Invalid JSON format in Additional Info." |

### 5.4 Validation Rules — `ConfigRequest` (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-20 | `ordinal` | `required\|integer\|min:1` | — (default Laravel) |
| BC-VAL-21 | `key_name` | `nullable\|string\|max:255` | — |
| BC-VAL-22 | `value` (derived from existing record's `value_type`) | Same type-based rules as Create (BC-VAL-05–11) | Same messages as Create |
| BC-VAL-23 | `description` | `nullable\|string` | — |
| BC-VAL-24 | `additional_info` | `nullable\|string` (JSON validated in `withValidator()`) | "Invalid JSON format." |
| BC-VAL-25 | `tenant_can_modify` | `boolean` | — |
| BC-VAL-26 | `mandatory` | `boolean` | — |
| BC-VAL-27 | `used_by_app` | `boolean` | — |
| BC-VAL-28 | `is_active` | `boolean` | — |

### 5.5 Authorization

| BC ID | Permission | Behavior |
|-------|------------|----------|
| BC-AUTH-01 | `timetable-foundation.viewAny` | Missing → 403 on menu page (`timetableConfiguration()`) |
| BC-AUTH-02 | `timetable-foundation.config.create` | Missing → 403 on `create()` and `store()` |
| BC-AUTH-03 | `timetable-foundation.config.view` | Missing → 403 on `show()` |
| BC-AUTH-04 | `timetable-foundation.config.update` | Missing → 403 on `edit()`, `update()`, `toggleStatus()` |
| BC-AUTH-05 | `timetable-foundation.config.delete` | Missing → 403 on `destroy()` |
| BC-AUTH-06 | `timetable-foundation.config.restore` | Missing → 403 on `trashed()`, `restore()` |
| BC-AUTH-07 | `timetable-foundation.config.forceDelete` | Missing → 403 on `forceDelete()` |
| BC-AUTH-08 | Guest access (no authenticated user) | Redirect to `/login` |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | User visits `timetable-foundation.menu.timetableConfiguration?tab=tt-config` | Page loads with "Timetable Config" tab active; grid shows all `tt_configs` records ordered by `ordinal` |
| BC-BIZ-02 | `cfg_search` query param provided | Grid filters to records where `key_name`, `value`, or `description` contain the search term |
| BC-BIZ-03 | `cfg_status=1` query param | Grid shows only records with `is_active=1` |
| BC-BIZ-04 | `cfg_status=0` query param | Grid shows only records with `is_active=0` |
| BC-BIZ-05 | No config records exist | Grid displays "No records found" message |
| BC-BIZ-06 | User clicks "Create Configuration" | Create form loads with fields: Order, Configuration Name, Configuration Key, Value Type, dynamic Value, Description, Additional Info, and flags |
| BC-BIZ-07 | User submits create form with `key` left empty but `key_name` provided | System auto-generates `key` from `key_name` using `Str::snake(Str::lower(key_name))` |
| BC-BIZ-08 | User submits create with `value_type=BOOLEAN` and value "true" | System stores value as boolean `true` |
| BC-BIZ-09 | User submits create with `value_type=NUMBER` and value "42" | System casts value to numeric `42` |
| BC-BIZ-10 | User submits create with `value_type=JSON` and valid JSON string | System decodes JSON string into array before storage |
| BC-BIZ-11 | User submits create with checkboxes unchecked | Hidden inputs (value=0) ensure boolean flags default to 0/false |
| BC-BIZ-12 | User submits create | Record created; activity logged with "Created" event; redirect to menu page with success flash |
| BC-BIZ-13 | User views config detail (`show()`) | Detail page displays all fields: key, name, ordinal, value_type, value, description, flags, timestamps |
| BC-BIZ-14 | User edits config (`edit()`) | Edit form loads with pre-populated values; `key` and `value_type` are read-only |
| BC-BIZ-15 | User updates config with changes | Record updated; `getChanges()` logged as activity with old/new values; redirect to menu page with success flash |
| BC-BIZ-16 | User toggles status via AJAX (`toggleStatus()`) | `is_active` flipped; JSON response with `{success: true, is_active: <new>, message: ...}` |
| BC-BIZ-17 | User deletes config (`destroy()`) | System sets `is_active=false`, calls `->delete()` (soft delete); activity logged; redirect with success flash |
| BC-BIZ-18 | User visits trashed page (`trashed()`) | Grid shows soft-deleted configs ordered by `deleted_at` desc, paginated 10/page |
| BC-BIZ-19 | User restores config from trash (`restore()`) | Record restored via `->restore()`; `is_active` remains `false` (not auto-set); activity logged; redirect with success flash |
| BC-BIZ-20 | User force-deletes config (`forceDelete()`) | Record permanently removed from database; activity logged; redirect with success flash |
| BC-BIZ-21 | `POST /timetable-foundation/priority-config/recalculate` | `PriorityConfigController::recalculate()` computes scores from active `RequirementConsolidation` records; upserts `tt_priority_configs`; redirects with success message showing count |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `tt_priority_configs.requirement_consolidation_id` | `tt_requirement_consolidations` | None explicitly declared (implicit RESTRICT) |
| BC-REF-02 | `tt_configs` has no foreign keys | — | — |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Timetable Configuration page with Config tab active | Page loads; "Timetable Config" tab is active; grid displays all config records ordered by `ordinal`; filter bar, status switch, and action buttons are visible | — | — | ⬜ |
| TC-P02 | Search configs by `key_name` using `cfg_search` | Grid filters to records whose `key_name`, `value`, or `description` contain the search term | — | — | ⬜ |
| TC-P03 | Filter configs by active status (`cfg_status=1`) | Grid shows only records with `is_active=1` | — | — | ⬜ |
| TC-P04 | Filter configs by inactive status (`cfg_status=0`) | Grid shows only records with `is_active=0` | — | — | ⬜ |
| TC-P05 | Reset filters to show all configs | Clicking reset link clears search and status filter; grid shows all records | — | — | ⬜ |
| TC-P06 | Create config with all fields (STRING value type) | Form validates; record created with all provided values; flash "Timetable configuration was created." displayed | — | — | ⬜ |
| TC-P07 | Create config with auto-generated key from `key_name` | Leave `key` empty, provide "Max Periods Per Day" as `key_name`; system generates `max_periods_per_day`; record saved | — | — | ⬜ |
| TC-P08 | Create config with BOOLEAN value type, value=true | Radio "True / Yes" selected; record saved with `value_type=BOOLEAN`, `value=true` | — | — | ⬜ |
| TC-P09 | Create config with NUMBER value type | Enter value "42"; record saved with `value_type=NUMBER`, value cast to numeric 42 | — | — | ⬜ |
| TC-P10 | Create config with JSON value type | Enter `{"key":"val","arr":[1,2,3]}`; record saved; value stored as decoded array | — | — | ⬜ |
| TC-P11 | Create config with DATE value type | Pick `2026-06-15`; record saved with `value_type=DATE`, `value="2026-06-15"` | — | — | ⬜ |
| TC-P12 | Create config with TIME value type | Enter `14:30`; record saved with `value_type=TIME`, `value="14:30"` | — | — | ⬜ |
| TC-P13 | Create config with DATETIME value type | Pick `2026-06-15T14:30:00`; record saved with `value_type=DATETIME` | — | — | ⬜ |
| TC-P14 | Create config with all boolean flags toggled on | Check "Tenant Can Modify", "Mandatory", "Used By App", "Active"; all flags set to 1 on saved record | — | — | ⬜ |
| TC-P15 | Create config with all boolean flags toggled off | Uncheck all flags; all flags stored as 0 (via hidden inputs) | — | — | ⬜ |
| TC-P16 | View config detail page | Show page displays key, name, ordinal, value_type, value, description, all flags, additional_info, created_at, updated_at | — | — | ⬜ |
| TC-P17 | Edit config and update all editable fields | Edit form pre-filled; update ordinal, key_name, value, description, flags; record updated; flash "Timetable configuration was updated." displayed | — | — | ⬜ |
| TC-P18 | Toggle config status from Active to Inactive | Click status switch; AJAX call flips `is_active` to 0; badge updates to "Inactive" | — | — | ⬜ |
| TC-P19 | Toggle config status from Inactive to Active | Click status switch on inactive record; `is_active` flips to 1; badge updates to "Active" | — | — | ⬜ |
| TC-P20 | Soft delete (trash) an active config | Click delete; confirmation shown; after confirm, record soft-deleted with `is_active=false`; redirected to menu page with flash | — | — | ⬜ |
| TC-P21 | View trashed configs list | Navigate to trashed page; grid shows soft-deleted records ordered by `deleted_at` desc, paginated 10/page | — | — | ⬜ |
| TC-P22 | Navigate trashed list page 2 | Click page 2; loads next set of trashed records | — | — | ⬜ |
| TC-P23 | Restore a trashed config | Click restore on a trashed config; record restored; `is_active` remains false; flash "Timetable configuration was restored." displayed | — | — | ⬜ |
| TC-P24 | Force delete a trashed config | Click force delete on a trashed config; record permanently removed; flash "Timetable configuration was permanently deleted." displayed | — | — | ⬜ |
| TC-P25 | Full lifecycle: create → edit → toggle → delete → restore → force delete | Complete cycle succeeds at every step with correct state transitions and flash messages | — | — | ⬜ |
| TC-P26 | Empty state — no configs exist | Grid shows "No records found" message; create button and trash button still visible (for super admin) | — | — | ⬜ |
| TC-P27 | Empty state — no trashed configs | Trashed page shows "No trashed configurations found" | — | — | ⬜ |
| TC-P28 | Priority Config recalculate | POST to recalculate; system processes all active `RequirementConsolidation` records; success message shows count; `tt_priority_configs` rows upserted | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create: missing `ordinal` | Validation error: "The order field is required." | — | — | ⬜ |
| TC-N02 | Create: `ordinal` = 0 (less than 1) | Validation error: "The order must be at least 1." | — | — | ⬜ |
| TC-N03 | Create: missing `key` and `key_name` | Validation error: "The configuration key field is required." | — | — | ⬜ |
| TC-N04 | Create: duplicate `key` | Validation error: "This configuration key already exists." | — | — | ⬜ |
| TC-N05 | Create: invalid `value_type` | Validation error: "Please select a valid value type." | — | — | ⬜ |
| TC-N06 | Create: `value_type=STRING` but value empty | Validation error: "The value field is required." | — | — | ⬜ |
| TC-N07 | Create: `value_type=NUMBER` but value "abc" | Validation error: "Please enter a valid number." | — | — | ⬜ |
| TC-N08 | Create: `value_type=BOOLEAN` but value "invalid" | Validation error: "Please select either true or false." | — | — | ⬜ |
| TC-N09 | Create: `value_type=JSON` but value "not json" | Validation error: "Please enter valid JSON format." | — | — | ⬜ |
| TC-N10 | Create: `value_type=DATE` but value "abc" | Validation error: "Please enter a valid date." (or "The value is not a valid date.") | — | — | ⬜ |
| TC-N11 | Create: `value_type=TIME` but value "25:00" | Validation error: "Please enter a valid time format (HH:MM)." | — | — | ⬜ |
| TC-N12 | Create: invalid JSON in `additional_info` | `withValidator()` adds "Invalid JSON format." error on `additional_info` | — | — | ⬜ |
| TC-N13 | Create: duplicate `ordinal` | `IntegrityConstraintViolation` thrown by DB unique key; Laravel converts to 500 error | — | — | ⬜ |
| TC-N14 | Update: set `value_type=BOOLEAN` existing config's value to "not_bool" | Validation error from `withValidator()`: "Boolean must be true or false." | — | — | ⬜ |
| TC-N15 | Update: invalid JSON in `additional_info` | `withValidator()` adds "Invalid JSON format." error on `additional_info` | — | — | ⬜ |
| TC-N16 | Update: missing `ordinal` | Validation error: "The order field is required." | — | — | ⬜ |
| TC-N17 | Missing permission `timetable-foundation.config.create` → access create page | 403 Forbidden | — | — | ⬜ |
| TC-N18 | Missing permission `timetable-foundation.config.view` → view config detail | 403 Forbidden | — | — | ⬜ |
| TC-N19 | Missing permission `timetable-foundation.config.update` → edit config | 403 Forbidden | — | — | ⬜ |
| TC-N20 | Missing permission `timetable-foundation.config.delete` → delete config | 403 Forbidden | — | — | ⬜ |
| TC-N21 | Missing permission `timetable-foundation.config.restore` → view trashed | 403 Forbidden | — | — | ⬜ |
| TC-N22 | Missing permission `timetable-foundation.config.forceDelete` → force delete | 403 Forbidden | — | — | ⬜ |
| TC-N23 | Guest user (unauthenticated) accesses any config URL | Redirect to `/login` | — | — | ⬜ |
| TC-N24 | View non-existent config (`GET /config/9999`) | 404 Not Found (implicit `findOrFail` via route model binding) | — | — | ⬜ |
| TC-N25 | Edit non-existent config | 404 Not Found | — | — | ⬜ |
| TC-N26 | Restore non-existent config | `ModelNotFoundException` → 404 | — | — | ⬜ |
| TC-N27 | Force delete non-existent config | `ModelNotFoundException` → 404 | — | — | ⬜ |
| TC-N28 | Toggle status with invalid `is_active` value (not boolean) | Validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N29 | Toggle status on non-existent config | 404 Not Found | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Key auto-generation: `prepareForValidation()` generates key from `key_name` | When `key` is absent but `key_name` is provided, `key` is set to `Str::snake(Str::lower(key_name))` before validation | — | — | ⬜ |
| TC-D02 | B | Boolean checkbox normalization in `prepareForValidation()` | Unchecked checkboxes send hidden `0` value; checked checkboxes send `1`; `prepareForValidation()` merges presence as boolean | — | — | ⬜ |
| TC-D03 | C | Soft delete sets `is_active=false` before `->delete()` | After `destroy()`, record is soft-deleted (`deleted_at` set) and `is_active=0` | — | — | ⬜ |
| TC-D04 | D | Restore does NOT re-activate `is_active` | After `restore()`, `deleted_at` is null but `is_active` remains 0 (must be toggled separately) | — | — | ⬜ |
| TC-D05 | E | Unique `ordinal` constraint at DB level | Creating two configs with same `ordinal` throws DB `UniqueConstraintViolation` | — | — | ⬜ |
| TC-D06 | F | Unique `key` constraint at DB level | Creating two configs with same `key` throws DB `UniqueConstraintViolation` (caught by validation before DB) | — | — | ⬜ |
| TC-D07 | G | Activity logging on creation | `store()` calls `activityLog($ttConfig, 'Created', ...)`; activity record appears in activity log | — | — | ⬜ |
| TC-D08 | H | Activity logging on update with change tracking | `update()` calls `activityLog()` with `changes` array showing old and new values per field | — | — | ⬜ |
| TC-D09 | I | Activity logging on soft delete | `destroy()` calls `activityLog()` with "Trashed" event | — | — | ⬜ |
| TC-D10 | J | Activity logging on restore | `restore()` calls `activityLog()` with "Restored" event | — | — | ⬜ |
| TC-D11 | K | Activity logging on status toggle | `toggleStatus()` calls `activityLog()` with "Toggled" event including previous and new status | — | — | ⬜ |
| TC-D12 | L | Activity logging on force delete | `forceDelete()` calls `activityLog()` with "Deleted" event | — | — | ⬜ |
| TC-D13 | M | Config `$casts` for boolean fields | `tenant_can_modify`, `mandatory`, `used_by_app`, `is_active` are cast to `boolean`; `additional_info` cast to `array`; `value_type` cast to `string` | — | — | ⬜ |
| TC-D14 | N | Config `$fillable` matches DDL columns | `$fillable` array contains all mutable columns: ordinal, key, key_name, value, value_type, description, additional_info, tenant_can_modify, mandatory, used_by_app, is_active | — | — | ⬜ |
| TC-D15 | O | `Config::get()` helper reads value by key | `Config::get('max_periods')` returns cast value (int for NUMBER, bool for BOOLEAN, array for JSON, string otherwise) | — | — | ⬜ |
| TC-D16 | P | `Config::get()` returns default for missing key | `Config::get('nonexistent_key', 'fallback')` returns `'fallback'` | — | — | ⬜ |
| TC-D17 | Q | PriorityConfig recalculate upserts by `requirement_consolidation_id` | Calling recalculate twice with same data updates existing rows rather than creating duplicates (verified by unique `requirement_consolidation_id` + `deleted_at` is null match in `updateOrInsert`) | — | — | ⬜ |
| TC-D18 | R | PriorityConfig recalculate — total number of periods is computed from active SchoolDays × PeriodSet.total_periods | `PriorityConfigService::totalWeeklyPeriods()` returns `activeSchoolDays * defaultPeriodSet.total_periods` (minimum 1) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns (mass-assignment protection) | `Config::$fillable` includes all mutable columns: `ordinal`, `key`, `key_name`, `value`, `value_type`, `description`, `additional_info`, `tenant_can_modify`, `mandatory`, `used_by_app`, `is_active` | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/decimals/dates | `Config::$casts` includes `additional_info => array`, `value_type => string`, `tenant_can_modify => boolean`, `mandatory => boolean`, `used_by_app => boolean`, `is_active => boolean` | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `Config` model uses `SoftDeletes` trait; `$table` is `tt_configs`; `deleted_at` column exists in DDL | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — scope methods defined | `scopeActive()`, `scopeSearch()`, `scopeByValueType()`, `scopeByTenantModifiable()`, `scopeByMandatory()`, `scopeByUsedByApp()` present on `Config` model | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling on all write methods | `store()` uses conditional checks with `back()->withErrors()`; `update()` similar pattern; `destroy()`, `restore()`, `forceDelete()` rely on implicit DB exception handling | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `store()` and `update()` do not wrap in explicit `DB::transaction()` but each is a single `create()`/`update()` call plus activity log | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()`, `toggleStatus()` all have `Gate::authorize()` calls | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | `store()` logs "Created"; `update()` logs "Updated" with changes; `destroy()` logs "Trashed"; `restore()` logs "Restored"; `forceDelete()` logs "Deleted"; `toggleStatus()` logs "Toggled" | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false` before soft delete; restore does NOT set `is_active=true` | `destroy()` calls `$config->update(['is_active' => false])` then `$config->delete()`; `restore()` calls only `$ttConfig->restore()` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` actually flips `is_active` | `toggleStatus()` reads `$request->input('is_active')` and sets `$config->is_active = $newStatus` then `$config->save()` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashed()` uses `Config::onlyTrashed()->paginate(10)`; `restore($id)` uses `Config::onlyTrashed()->findOrFail($id)->restore()`; `forceDelete($id)` uses `Config::withTrashed()->findOrFail($id)->forceDelete()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — JSON success response after toggle; redirect+flash after create/update/delete | `toggleStatus()` returns `response()->json(['success'=>true, ...])`; `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()` return `redirect()->route(...)->with('success', flash(...))` | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — validation rules cover all fields; unique rules ignore current ID on update; `prepareForValidation()` normalizations | `ConfigRequest::rules()` covers `ordinal`, `key`, `key_name`, `value_type`, `value`, `description`, `additional_info`, `tenant_can_modify`, `mandatory`, `used_by_app`, `is_active`; unique rule on `key` only for create; `prepareForValidation()` normalizes checkbox booleans and auto-generates key | — | — | ◌ |
| TC-CR14 | CR | P1 | Policy — all required methods defined; permission strings match route/gate names | `TimetableConfigPolicy` defines `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()`; each calls `$user->can('timetable-foundation.config.<action>')` | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | `Route::resource('config', ConfigController::class)` plus `trashed`, `restore`, `forceDelete`, `toggleStatus` custom routes; implicit route model binding on `{config}` parameter | — | — | ◌ |
| TC-CR16 | CR | P1 | View — Blade `@can` directives on action buttons | `_list.blade.php` conditionally renders status switch and action buttons based on `@can('tenant.timetable-config.update')` and `auth()->user()->is_super_admin` | — | — | ◌ |
| TC-CR17 | CR | P1 | View — null-safe checks for relationship variables | Config views do not load relationships; variables accessed directly on `$config` model attributes | — | — | ◌ |
| TC-CR18 | CR | P1 | Breadcrumb — route registered in breadcrumb config | Breadcrumb renders "Timetable Configuration" → "Create Configuration" / "Edit Configuration" / "Configuration Details" hierarchy | — | — | ◌ |
| TC-CR19 | CR | P1 | Database — unique indexes match request validation rules | `uq_settings_key` (key) matches `unique:tt_configs,key` rule; `uq_settings_ordinal` (ordinal) has no matching validation rule (DB-level only) | — | — | ◌ |
| TC-CR20 | CR | P1 | PriorityConfigController — Gate authorization on recalculate | `recalculate()` gates on `timetable-foundation.viewAny` before processing | — | — | ◌ |
| TC-CR21 | CR | P1 | PriorityConfigService — DB transaction wraps upsert loop | `recalculate()` wraps the entire `updateOrInsert` loop inside `DB::transaction()` | — | — | ◌ |
| TC-CR22 | CR | P1 | PriorityConfigService — try-catch on recalculation | `PriorityConfigController::recalculate()` wraps `$this->service->recalculate()` in try-catch; on failure redirects with error message | — | — | ◌ |

---

## 7. Detailed Test Steps

All Code Review TC steps are listed first, followed by Positive, Negative, and Dependency TC steps.

#### TC-CR01: Model `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/TimetableFoundation/Models/Config.php` | File exists at expected path |
| 2 | Inspect `$fillable` array | Contains: `ordinal`, `key`, `key_name`, `value`, `value_type`, `description`, `additional_info`, `tenant_can_modify`, `mandatory`, `used_by_app`, `is_active` |
| 3 | Cross-check against `tt_configs` DDL columns | No DDL column that is fillable via mass-assignment is missing from `$fillable`; `id`, `deleted_at`, `created_at`, `updated_at` are NOT in `$fillable` |

#### TC-CR02: Model `$casts` For Booleans/Integers/Decimals/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Config.php` and inspect `$casts` array | Contains: `additional_info => array`, `value_type => string`, `tenant_can_modify => boolean`, `mandatory => boolean`, `used_by_app => boolean`, `is_active => boolean` |

#### TC-CR03: Model SoftDeletes Trait Correctly Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Config.php` | Model uses `SoftDeletes` trait |
| 2 | Verify `$table` property | `$table = 'tt_configs'` |
| 3 | Check migration for `deleted_at` column | `deleted_at` column of type `timestamp NULL DEFAULT NULL` exists in DDL |

#### TC-CR04: Model Scope Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Config.php` | `scopeActive()`, `scopeSearch()`, `scopeByValueType()`, `scopeByTenantModifiable()`, `scopeByMandatory()`, `scopeByUsedByApp()` methods present |
| 2 | Verify `scopeByValueType()` | Filters by `value_type` only if the provided type is in the allowed list `['STRING','NUMBER','BOOLEAN','DATE','TIME','DATETIME','JSON']` |
| 3 | Verify `scopeByTenantModifiable()`, `scopeByMandatory()`, `scopeByUsedByApp()` | Each filters only when value is not empty string |

#### TC-CR05: Controller Try-Catch Exception Handling On Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigController.php` | `store()` and `update()` use conditional `back()->withErrors()` for validation failures |
| 2 | Inspect `destroy()`, `restore()`, `forceDelete()` | No explicit try-catch; rely on Laravel's exception handler for 500 errors |

#### TC-CR06: Controller DB Transactions On Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigController.php` | `store()` does single `Config::create($data)` then `activityLog()` — no explicit transaction |
| 2 | Open `PriorityConfigService.php` | `recalculate()` wraps `updateOrInsert` loop inside `DB::transaction()` — transaction present |

#### TC-CR07: Controller `Gate::authorize()` On Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigController.php` | Each public method has `Gate::authorize()` call with appropriate permission string |
| 2 | Verify `create()`, `store()` | Both gate on `timetable-foundation.config.create` |
| 3 | Verify `show()` | Gates on `timetable-foundation.config.view` |
| 4 | Verify `edit()`, `update()`, `toggleStatus()` | Each gates on `timetable-foundation.config.update` |
| 5 | Verify `destroy()` | Gates on `timetable-foundation.config.delete` |
| 6 | Verify `trashed()`, `restore()` | Both gate on `timetable-foundation.config.restore` |
| 7 | Verify `forceDelete()` | Gates on `timetable-foundation.config.forceDelete` |

#### TC-CR08: Activity Logged On All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigController.php` | `store()` calls `activityLog($ttConfig, 'Created', ...)` |
| 2 | Check `update()` | Calls `activityLog()` with 'Updated' and `$changes` array |
| 3 | Check `destroy()` | Calls `activityLog()` with 'Trashed' |
| 4 | Check `restore()` | Calls `activityLog()` with 'Restored' |
| 5 | Check `forceDelete()` | Calls `activityLog()` with 'Deleted' |
| 6 | Check `toggleStatus()` | Calls `activityLog()` with 'Toggled' and status info |

#### TC-CR09: `is_active=false` Before Soft Delete; Restore Does Not Set `is_active=true`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` | Calls `$config->update(['is_active' => false])` then `$config->delete()` — order is correct |
| 2 | Open `restore()` | Calls only `$ttConfig->restore()` — no `is_active` update |

#### TC-CR10: `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus()` in `ConfigController.php` | Reads `is_active` from `$request->input()`; sets `$config->is_active = $newStatus`; calls `$config->save()` |

#### TC-CR11: Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trashed()` | Uses `Config::onlyTrashed()->orderBy('deleted_at', 'desc')->paginate(10)` |
| 2 | Open `restore($id)` | Uses `Config::onlyTrashed()->findOrFail($id)` then `->restore()` |
| 3 | Open `forceDelete($id)` | Uses `Config::withTrashed()->findOrFail($id)` then `->forceDelete()` |

#### TC-CR12: JSON/Redirect Response After Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus()` | Returns `response()->json(['success' => ..., 'is_active' => ..., 'message' => ...])` |
| 2 | Open `store()`, `update()`, `destroy()` | Each returns `redirect()->route(...)->with('success', flash(...))` |

#### TC-CR13: Validation Rules Coverage And `prepareForValidation()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigRequest.php` | `rules()` covers all form fields; `unique:tt_configs,key` only on create; `key` excluded on update |
| 2 | Check `prepareForValidation()` | Merges boolean checkboxes as true if present; auto-generates `key` from `key_name` on create; converts `value` based on `value_type` |
| 3 | Check `withValidator()` | After-validation checks for value-type correctness and JSON validity |

#### TC-CR14: Policy Methods And Permission Strings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TimetableConfigPolicy.php` | Methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` |
| 2 | Verify each method | Each calls `$user->can('timetable-foundation.config.<action>')` |
| 3 | Check `TimetableFoundationServiceProvider.php` | Line 101: `Gate::policy(Config::class, TimetableConfigPolicy::class)` registered |

#### TC-CR15: Routes Registered With Model Binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | `Route::resource('config', ConfigController::class)` registered (lines 62-66) |
| 2 | Custom routes present | `trashed`, `restore`, `forceDelete`, `toggleStatus` routes registered with correct names |
| 3 | Route model binding | `{config}` parameter in resource + `toggleStatus` routes provides implicit binding |

#### TC-CR16: Blade `@can` Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `_list.blade.php` | Status switch wrapped in `@can('tenant.timetable-config.update')` |
| 2 | Check action buttons | Create/trash buttons shown only for `is_super_admin` via `@can(auth()->user()->is_super_admin)` |

#### TC-CR17: View Null-Safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open config view files | All `$config->attribute` accesses are on the loaded model; no relationship access that could null-reference |

#### TC-CR18: Breadcrumb Route Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `config/breadcrumb.php` (or equivalent) | Route `timetable-foundation.menu.timetableConfiguration` renders "Timetable Configuration" breadcrumb; create/edit/show sub-routes render child breadcrumbs |

#### TC-CR19: Unique Indexes Match Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for `tt_configs` | `UNIQUE KEY uq_settings_key (key)` — matches `unique:tt_configs,key` validation rule |
| 2 | Check `uq_settings_ordinal` | Unique on `ordinal` — no matching validation rule; enforced only at DB level |

#### TC-CR20: PriorityConfigController Gate Authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PriorityConfigController.php` | `recalculate()` calls `Gate::authorize('timetable-foundation.viewAny')` before processing |

#### TC-CR21: PriorityConfigService DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PriorityConfigService.php` | `recalculate()` wraps the upsert loop in `DB::transaction()` |

#### TC-CR22: PriorityConfigService Try-Catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PriorityConfigController.php` | `recalculate()` wraps `$this->service->recalculate()` in try-catch; on exception redirects with `->with('error', 'Recalculation failed: ' . $e->getMessage())` |

---

### 7.1 Positive TC Steps

#### TC-P01: Load Timetable Configuration Page With Config Tab Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with `timetable-foundation.viewAny` permission | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/timetable-configuration?tab=tt-config` | Page loads without errors |
| 3 | Observe tab bar | "Timetable Config" tab is active; "Academic Terms" tab is visible |
| 4 | Observe grid | All `tt_configs` records displayed, ordered by `ordinal` ascending |
| 5 | Observe filter bar | Search input (`cfg_search`), status dropdown (`cfg_status`), filter button, reset link present |
| 6 | Observe action buttons | Create (+) and Trash buttons visible (for super admin) |

#### TC-P02: Search Configs By Key Name Using `cfg_search`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least one config has `key_name` containing "Period" | — |
| 2 | Enter "Period" in search field and click filter | Grid shows only configs where `key_name`, `value`, or `description` contains "Period" |
| 3 | Clear search and click filter | All configs shown again |

#### TC-P03: Filter Configs By Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 2 active and 1 inactive config exist | — |
| 2 | Select "Active" in status dropdown and click filter | Grid shows only configs with `is_active=1` |
| 3 | Verify count | Active count matches database |

#### TC-P04: Filter Configs By Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Inactive" in status dropdown and click filter | Grid shows only configs with `is_active=0` |
| 2 | Verify count | Inactive count matches database |

#### TC-P05: Reset Filters To Show All Configs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search and status filter | Grid filtered |
| 2 | Click reset link (`#tt-config` anchor) | Filters cleared; all configs displayed |

#### TC-P06: Create Config With All Fields (STRING Value Type)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "+" button to navigate to create page | `GET /timetable-foundation/config/create` loads with form |
| 2 | Enter Order: `10` | Field accepted |
| 3 | Enter Configuration Name: `Maximum Periods Per Day` | Field accepted |
| 4 | Enter Configuration Key: `max_periods_per_day` | Field accepted |
| 5 | Select Value Type: `STRING` | Dynamic value field appears (text input) |
| 6 | Enter Value: `8` | Field accepted |
| 7 | Enter Description: `Maximum number of periods allowed per day` | Field accepted |
| 8 | Toggle ON "Mandatory" and "Active"; leave others OFF | Checkboxes reflect state |
| 9 | Click "Create Configuration" | Form submits via POST; redirect to menu page with success flash "Timetable configuration was created." |
| 10 | Verify new config appears in grid | Row with key `max_periods_per_day`, value `8`, type `STRING`, Mandatory "Yes", Active "Yes" visible |

#### TC-P07: Create Config With Auto-Generated Key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter Order: `11` | — |
| 3 | Enter Configuration Name: `Enable Lunch Tracking` | — |
| 4 | Leave Configuration Key **empty** | — |
| 5 | Select STRING, enter Value `yes`, add description | — |
| 6 | Click Create | Auto-generated key: `enable_lunch_tracking`; record saved successfully |

#### TC-P08: Create Config With BOOLEAN Value Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter Order: `12`, Name: `Enable Double Shift`, Key: `enable_double_shift` | — |
| 3 | Select Value Type: `BOOLEAN` | Radio buttons appear for True/False |
| 4 | Select "True / Yes" | Radio checked |
| 5 | Click Create | Record saved with `value=1` (true); grid shows "Yes" |

#### TC-P09: Create Config With NUMBER Value Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter Order: `13`, Name: `Min Teacher Load`, Key: `min_teacher_load` | — |
| 3 | Select `NUMBER`, enter Value `24` | Number input accepts numeric |
| 4 | Click Create | Record saved with `value=24`, `value_type=NUMBER` |

#### TC-P10: Create Config With JSON Value Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter Order: `14`, Name: `Holiday Config`, Key: `holiday_config` | — |
| 3 | Select `JSON`, enter Value `{"sat": "half_day", "sun": "closed"}` | — |
| 4 | Click Create | Record saved; JSON decoded and stored as array |

#### TC-P11: Create Config With DATE Value Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter Order: `15`, Name: `Term Start`, Key: `term_start_date` | — |
| 3 | Select `DATE`, pick `2026-06-15` | Date picker works |
| 4 | Click Create | Record saved with `value_type=DATE` |

#### TC-P12: Create Config With TIME Value Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter Order: `16`, Name: `School Start Time`, Key: `school_start_time` | — |
| 3 | Select `TIME`, enter `08:30` | — |
| 4 | Click Create | Record saved with `value_type=TIME` |

#### TC-P13: Create Config With DATETIME Value Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter Order: `17`, Name: `Academic Year Start`, Key: `academic_year_start` | — |
| 3 | Select `DATETIME`, pick `2026-06-15T14:30:00` | — |
| 4 | Click Create | Record saved with `value_type=DATETIME` |

#### TC-P14: Create Config With All Boolean Flags Toggled On

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with Order: `18`, Name: `Full Flags Test`, Key: `full_flags_test`, STRING value `test` | — |
| 2 | Toggle ON all 4 flags: Tenant Can Modify, Mandatory, Used By App, Active | All switches ON |
| 3 | Click Create | All flag fields saved as 1 |

#### TC-P15: Create Config With All Boolean Flags Toggled Off

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with Order: `19`, Name: `No Flags Test`, Key: `no_flags_test`, STRING value `test` | — |
| 2 | Ensure all 4 flags are OFF | All switches OFF |
| 3 | Click Create | All flag fields saved as 0 (hidden inputs submit 0) |

#### TC-P16: View Config Detail Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In config grid, click "View" (eye icon) on a config | `GET /timetable-foundation/config/{id}` loads |
| 2 | Observe detail table | All fields displayed: Key (badge), Name (bold), Order (badge), Value Type (colored badge), Value, Description, Tenant Can Modify (Yes/No), Mandatory (Required/Optional), Used By App (Yes/No), Status (Active/Inactive), Additional Info (if present), Created At, Updated At |
| 3 | Observe action buttons | "Back" and "Edit" buttons visible |

#### TC-P17: Edit Config And Update All Editable Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In config grid, click "Edit" (pencil icon) | `GET /timetable-foundation/config/{id}/edit` loads; form pre-filled |
| 2 | Verify `key` is read-only (style `background:#f1f5f9`) | Key field not editable |
| 3 | Verify `value_type` is read-only | Value type shown as text, not a select |
| 4 | Update Order to `99` | — |
| 5 | Update Value to `updated_value` | — |
| 6 | Toggle OFF "Active" | Switch OFF |
| 7 | Click "Update Configuration" | Form submits via PUT; redirect with success flash; grid shows updated values |

#### TC-P18: Toggle Config Status From Active To Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure config with `is_active=1` exists | — |
| 2 | Click the status switch (toggle) on that config row | AJAX `POST /config/{id}/toggle-status` with `is_active=0` |
| 3 | Observe response | Status badge changes from green "Active" to red/gray "Inactive" |

#### TC-P19: Toggle Config Status From Inactive To Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure config with `is_active=0` exists | — |
| 2 | Click the status switch on that inactive config row | AJAX `POST /config/{id}/toggle-status` with `is_active=1` |
| 3 | Observe response | Status badge changes to "Active" |

#### TC-P20: Soft Delete (Trash) An Active Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete (trash icon) on an active config row | SweetAlert confirmation dialog: "Move to Trash?" |
| 2 | Click "Yes, move to trash!" | Form submits DELETE request; record soft-deleted; redirected to menu page with success flash |
| 3 | Switch status filter to "Inactive" | Trashed record appears with `is_active=0` |

#### TC-P21: View Trashed Configs List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click trash icon (in action buttons area) | `GET /timetable-foundation/config/trash/view` loads |
| 2 | Verify grid | Shows soft-deleted records ordered by `deleted_at` desc |
| 3 | Verify columns | Order, Key, Name, Value, Type, Status ("Trashed" badge), Action (restore/force-delete buttons) |

#### TC-P22: Navigate Trashed List Page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 12+ trashed configs exist | — |
| 2 | Visit trashed page | Page 1 shows 10 records; pagination controls visible |
| 3 | Click page 2 | URL changes to `?page=2`; remaining 2+ records displayed |

#### TC-P23: Restore A Trashed Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trashed page, click "Restore" on a trashed config | `GET /config/{id}/restore` called |
| 2 | Redirected to trashed page with success flash | "Timetable configuration was restored." |
| 3 | Go back to main config tab | Restored record visible but `is_active` is still inactive (red badge) |

#### TC-P24: Force Delete A Trashed Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trashed page, click "Force Delete" on a trashed config | `DELETE /config/{id}/force-delete` called |
| 2 | Redirected to trashed page with success flash | "Timetable configuration was permanently deleted." |
| 3 | Verify record gone | Record no longer visible in trashed or main list |

#### TC-P25: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with key `lifecycle_test`, value `test` | Record created successfully |
| 2 | Edit config: change value to `updated` | Update succeeds |
| 3 | Toggle status to inactive | Status changes to Inactive |
| 4 | Toggle status back to active | Status changes to Active |
| 5 | Delete config (soft) | Record moves to trash; is_active=0 |
| 6 | Restore config from trash | Record restored; is_active remains 0 |
| 7 | Toggle status to active | Status changes to Active |
| 8 | Delete again, then force delete | Record permanently removed |

#### TC-P26: Empty State — No Configs Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure `tt_configs` table is empty | — |
| 2 | Load timetable configuration page | Grid shows "No records found" |
| 3 | Verify action buttons | Create (+) and Trash buttons still visible (for super admin) |

#### TC-P27: Empty State — No Trashed Configs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no soft-deleted configs exist | — |
| 2 | Navigate to trashed page | Grid shows "No trashed configurations found" |

#### TC-P28: Priority Config Recalculate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least one active `RequirementConsolidation` exists with related data | — |
| 2 | Send `POST /timetable-foundation/priority-config/recalculate` | Request hits `PriorityConfigController::recalculate()` |
| 3 | Observe response | Redirected to requirement page with success: "Priority scores recalculated for {count} requirements." |
| 4 | Check `tt_priority_configs` table | Rows exist with computed score values for each processed consolidation |

---

### 7.2 Negative TC Steps

#### TC-N01: Create — Missing `ordinal`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Leave Order field empty | — |
| 3 | Fill all other required fields | — |
| 4 | Click Create | Validation error: "The order field is required." |

#### TC-N02: Create — `ordinal` = 0 (Less Than 1)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On create form, enter Order: `0` | — |
| 2 | Fill other required fields | — |
| 3 | Click Create | Validation error: "The order must be at least 1." |

#### TC-N03: Create — Missing `key` And `key_name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On create form, leave Configuration Key and Configuration Name empty | — |
| 2 | Click Create | Validation error: "The configuration key field is required." |

#### TC-N04: Create — Duplicate `key`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with key `duplicate_key` | First creation succeeds |
| 2 | Navigate to create form again | — |
| 3 | Enter key `duplicate_key` | — |
| 4 | Click Create | Validation error: "This configuration key already exists." |

#### TC-N05: Create — Invalid `value_type`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On create form, select Value Type as blank | — |
| 2 | Click Create | Validation error: "Please select a valid value type." |

#### TC-N06: Create — `value_type=STRING` But Value Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select STRING, leave Value empty | — |
| 2 | Click Create | Validation error: "The value field is required." |

#### TC-N07: Create — `value_type=NUMBER` But Value "abc"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select NUMBER, enter Value `abc` | — |
| 2 | Click Create | Validation error: "Please enter a valid number." |

#### TC-N08: Create — `value_type=BOOLEAN` But Value "invalid"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select BOOLEAN, manually submit with value `invalid` | — |
| 2 | Observe response | Validation error: "Please select either true or false." |

#### TC-N09: Create — `value_type=JSON` But Value "not json"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select JSON, enter Value `not json` | — |
| 2 | Click Create | Validation error: "Please enter valid JSON format." |

#### TC-N10: Create — `value_type=DATE` But Value "abc"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select DATE, enter Value `abc` | — |
| 2 | Click Create | Validation error: "Please enter a valid date." |

#### TC-N11: Create — `value_type=TIME` But Value "25:00"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select TIME, enter Value `25:00` | — |
| 2 | Click Create | Validation error: "Please enter a valid time format (HH:MM)." |

#### TC-N12: Create — Invalid JSON In `additional_info`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter Additional Info: `{invalid json}` | — |
| 2 | Click Create | Validation error: "Invalid JSON format." on `additional_info` |

#### TC-N13: Create — Duplicate `ordinal`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with ordinal `50` | First creation succeeds |
| 2 | Attempt to create another config with ordinal `50` (bypass JS via direct POST) | DB throws `UniqueConstraintViolation`; Laravel returns 500 error |

#### TC-N14: Update — BOOLEAN Config Set To Invalid Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a config with `value_type=BOOLEAN` | Edit form shows radio buttons |
| 2 | Manually POST with value `not_bool` | Validation error from `withValidator()`: "Boolean must be true or false." |

#### TC-N15: Update — Invalid JSON In `additional_info`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit any config, enter Additional Info: `{bad json}` | — |
| 2 | Click Update | Validation error: "Invalid JSON format." on `additional_info` |

#### TC-N16: Update — Missing `ordinal`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a config, clear Order field | — |
| 2 | Click Update | Validation error: "The order field is required." |

#### TC-N17: Missing Permission `config.create` → Access Create Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user WITHOUT `timetable-foundation.config.create` | — |
| 2 | Navigate to `GET /timetable-foundation/config/create` | 403 Forbidden |

#### TC-N18: Missing Permission `config.view` → View Config Detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user WITHOUT `timetable-foundation.config.view` | — |
| 2 | Navigate to `GET /timetable-foundation/config/{id}` | 403 Forbidden |

#### TC-N19: Missing Permission `config.update` → Edit Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user WITHOUT `timetable-foundation.config.update` | — |
| 2 | Navigate to `GET /timetable-foundation/config/{id}/edit` | 403 Forbidden |

#### TC-N20: Missing Permission `config.delete` → Delete Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user WITHOUT `timetable-foundation.config.delete` | — |
| 2 | Send `DELETE /timetable-foundation/config/{id}` | 403 Forbidden |

#### TC-N21: Missing Permission `config.restore` → View Trashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user WITHOUT `timetable-foundation.config.restore` | — |
| 2 | Navigate to `GET /timetable-foundation/config/trash/view` | 403 Forbidden |

#### TC-N22: Missing Permission `config.forceDelete` → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user WITHOUT `timetable-foundation.config.forceDelete` | — |
| 2 | Send `DELETE /timetable-foundation/config/{id}/force-delete` | 403 Forbidden |

#### TC-N23: Guest User Accesses Any Config URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out (no authenticated user) | — |
| 2 | Navigate to `GET /timetable-foundation/config/create` | Redirected to `/login` |

#### TC-N24: View Non-Existent Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/config/99999` (non-existent ID) | 404 Not Found |

#### TC-N25: Edit Non-Existent Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/config/99999/edit` | 404 Not Found |

#### TC-N26: Restore Non-Existent Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/config/99999/restore` | 404 Not Found (`ModelNotFoundException`) |

#### TC-N27: Force Delete Non-Existent Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send `DELETE /timetable-foundation/config/99999/force-delete` | 404 Not Found |

#### TC-N28: Toggle Status With Invalid `is_active` Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send `POST /config/{id}/toggle-status` with `is_active=invalid` | Validation error: "The is active field must be true or false." |

#### TC-N29: Toggle Status On Non-Existent Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send `POST /config/99999/toggle-status` with `is_active=1` | 404 Not Found |

---

### 7.3 Dependency TC Steps

#### TC-D01: Key Auto-Generation From `key_name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with Name `"Test Key Name"`, leave Key empty | — |
| 2 | Submit form | `prepareForValidation()` sets `key` = `Str::snake(Str::lower("Test Key Name"))` = `test_key_name` |
| 3 | Verify in database | Record has `key = "test_key_name"` |

#### TC-D02: Boolean Checkbox Normalization In `prepareForValidation()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with "Mandatory" and "Active" checked, others unchecked | — |
| 2 | Submit form | `prepareForValidation()` merges all 4 booleans as true via `$this->has()` |
| 3 | Verify record | `tenant_can_modify=0`, `mandatory=1`, `used_by_app=0`, `is_active=1` |

#### TC-D03: Soft Delete Sets `is_active=false` Before `->delete()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select an active config (`is_active=1`) | — |
| 2 | Click Delete and confirm | `destroy()` runs: `$config->update(['is_active' => false])` then `$config->delete()` |
| 3 | Query database for this record | `deleted_at` IS NOT NULL; `is_active` = 0 |

#### TC-D04: Restore Does Not Re-Activate `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed config | `restore()` calls `$ttConfig->restore()` only |
| 2 | Check record after restore | `deleted_at` IS NULL; `is_active` remains 0 |

#### TC-D05: Unique `ordinal` Constraint At DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with ordinal `77` | Succeeds |
| 2 | Directly insert via SQL another config with ordinal `77` | `SQLSTATE[23000]: Integrity constraint violation` for unique key `uq_settings_ordinal` |

#### TC-D06: Unique `key` Constraint At DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with key `unique_test` | Succeeds |
| 2 | Via API, attempt to create another config with key `unique_test` | Validation catches: "This configuration key already exists." |
| 3 | Bypass validation and insert directly with key `unique_test` | DB throws `Integrity constraint violation` for unique key `uq_settings_key` |

#### TC-D07: Activity Logging On Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new config | — |
| 2 | Check activity log table | Row exists with event "Created", subject type `Config`, message "Timetable configuration was created." |

#### TC-D08: Activity Logging On Update With Change Tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a config and change Value from "old" to "new" | — |
| 2 | Check activity log | Row exists with event "Updated", changes array containing `value => ['old' => 'old', 'new' => 'new']` |

#### TC-D09: Activity Logging On Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a config | — |
| 2 | Check activity log | Row exists with event "Trashed", message "Timetable configuration was deactivated and deleted." |

#### TC-D10: Activity Logging On Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed config | — |
| 2 | Check activity log | Row exists with event "Restored", message "Timetable configuration was restored." |

#### TC-D11: Activity Logging On Status Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle a config's status from Active to Inactive | — |
| 2 | Check activity log | Row exists with event "Toggled", status "Inactive" |

#### TC-D12: Activity Logging On Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete a trashed config | — |
| 2 | Check activity log | Row exists with event "Deleted", message "Timetable configuration was permanently deleted." |

#### TC-D13: Config `$casts` For Boolean Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Retrieve a Config model instance | `$config->tenant_can_modify`, `$config->mandatory`, `$config->used_by_app`, `$config->is_active` are boolean type |
| 2 | Check `$config->additional_info` | Returns array if JSON, null otherwise |
| 3 | Check `$config->value_type` | Returns string |

#### TC-D14: Config `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `Config::$fillable` | Contains: `ordinal`, `key`, `key_name`, `value`, `value_type`, `description`, `additional_info`, `tenant_can_modify`, `mandatory`, `used_by_app`, `is_active` |
| 2 | Attempt mass-assignment of `id` | Guarded — not assignable |

#### TC-D15: `Config::get()` Helper Reads Value By Key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with key `test_number`, value_type=NUMBER, value=42 | — |
| 2 | Call `Config::get('test_number')` | Returns integer `42` |
| 3 | Create config with key `test_bool`, value_type=BOOLEAN, value=true | — |
| 4 | Call `Config::get('test_bool')` | Returns boolean `true` |
| 5 | Create config with key `test_json`, value_type=JSON, value={"a":1} | — |
| 6 | Call `Config::get('test_json')` | Returns array `['a' => 1]` |

#### TC-D16: `Config::get()` Returns Default For Missing Key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `Config::get('nonexistent_key', 'fallback')` | Returns `'fallback'` |

#### TC-D17: PriorityConfig Recalculate Upserts By `requirement_consolidation_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure one active `RequirementConsolidation` exists with ID=1 | — |
| 2 | Run recalculate once | Row inserted with `requirement_consolidation_id=1` |
| 3 | Run recalculate again with same data | `updateOrInsert` matches on `requirement_consolidation_id=1` and `deleted_at is null`; row updated, no duplicate |

#### TC-D18: PriorityConfig Recalculate — Total Periods Computation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 6 active SchoolDays exist | — |
| 2 | Ensure default PeriodSet has `total_periods=8` | — |
| 3 | Run recalculate | `totalWeeklyPeriods()` returns `6 * 8 = 48` |
| 4 | Verify `weekly_load_ratio` values | Each computed ratio = `required_weekly_periods / 48` |

---

*End of document — tt_ConfigSettings_TcList*
