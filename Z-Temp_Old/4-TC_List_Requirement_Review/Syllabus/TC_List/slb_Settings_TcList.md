# slb_settings_TcList

## Module: Syllabus → Planning → Settings

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Planning |
| Feature | Syllabus Settings |
| URL(s) | `GET /syllabus/planning?tab=syllabus_settings` (display), `POST /syllabus/planning/save-setting` (save) |
| Controller | `SyllabusController@planning()` (tab render, line 167), `SyllabusController@saveSetting()` (save, line 1729) |
| Model(s) | `Modules\SchoolSetup\Models\SchConfig` (table: `sch_configs`) — NOT a Syllabus model |
| Validation | Inline `$request->validate()` with `in:` rule — no FormRequest |
| Policy | None — uses `Gate::authorize('tenant.lesson.update')` directly |
| Permissions | `tenant.lesson.update` (save), `tenant.lesson.viewAny` (view) |
| View | `resources/views/lesson-management/partials/syllabus-settings/index.blade.php` |
| Config Keys | `syllabus_teaching_estimation_level_for_lesson_planning`, `homework_released_on_syllabus_level`, `quiz_released_on_syllabus_level`, `quest_released_on_syllabus_level` |
| Teaching Est. Allowed Values | `lesson`, `topic`, `sub_topic`, `mini_topic` (4 values) |
| Release Level Allowed Values | `lesson`, `topic`, `sub_topic`, `mini_topic`, `micro_topic`, `nano_topic` (6 values) |
| Post-Save | Client JS: toast → 1.2s delay → `location.reload()` |

---

## 2. Pre-conditions

- Required permissions: `tenant.lesson.viewAny` (view), `tenant.lesson.update` (save/modify settings)
- `SchConfig` table must exist in the tenant database
- No seed data required for settings — defaults handled by downstream screens
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---



---

## 3. Default Data Load

When the page loads via SyllabusController@planning() (GET /syllabus/planning) with tab=syllabus_settings, default filters: class_section_id=1, subject_id=5, academic_session_id=7.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: dropdowns | planning() | Same as LessonSequencing (classes, sections, classSections, subjects, academicSessions) | --- | None |
| Config Settings | planning() | SchConfig::whereIn(key) with 4 keys: syllabus_teaching_estimation_level_for_lesson_planning, homework/quiz/quest_released_on_syllabus_level | key in (4 values) | None (single pluck) |
| Current session | planning() | academicSessions->firstWhere(is_current,1) | is_current=1 | None |
## 4. Test Data Strategy

- **Config records**: Create `SchConfig` records directly in DB for pre-configured state tests
- **Unique suffix**: Where needed for test isolation
- **Value normalization**: Input `sub_topic` → stored as `Sub-Topic`; read back as `sub_topic` for comparison
- **Pre-test cleanup**: Reset modified config keys to defaults after tests
- **Teaching estimation levels**: Only `lesson`, `topic`, `sub_topic`, `mini_topic` are valid for this key
- **Release levels**: All 6 values valid for homework/quiz/quest keys
- **Uniqueness**: The 3 release level keys must have different values from each other

---

## 5. Business Conditions

### 4.1 Database Schema — `sch_configs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | module_id | INT | NOT NULL |
| BC-DB-03 | module_code | VARCHAR(10) | NOT NULL |
| BC-DB-04 | key | VARCHAR(100) | NOT NULL, UNIQUE |
| BC-DB-05 | key_name | VARCHAR(100) | DEFAULT NULL |
| BC-DB-06 | value | TEXT | DEFAULT NULL |
| BC-DB-07 | value_type | VARCHAR(20) | DEFAULT 'STRING' |
| BC-DB-08 | description | TEXT | DEFAULT NULL |
| BC-DB-09 | ordinal | INT | DEFAULT NULL |
| BC-DB-10 | tenant_can_modify | TINYINT(1) | DEFAULT 1 |
| BC-DB-11 | mandatory | TINYINT(1) | DEFAULT 1 |
| BC-DB-12 | used_by_app | TINYINT(1) | DEFAULT 1 |
| BC-DB-13 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Validation Rules — `saveSetting()` Inline

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | key | required, string, in:4 allowed keys | "The selected key is invalid." |
| BC-VAL-02 | value | required, string | — |
| BC-VAL-03 | description | nullable, string, max:500 | — |
| BC-VAL-04 | value (teaching estimation) | in:lesson,topic,sub_topic,mini_topic | "Invalid option selected for this setting." |
| BC-VAL-05 | value (release levels) | in:lesson,topic,sub_topic,mini_topic,micro_topic,nano_topic | "Invalid option selected for this setting." |
| BC-VAL-06 | Uniqueness (release levels) | Must differ from other 2 release level values | "The level '{value}' is already assigned to {otherLabel}. Homework, Quiz, and Quest release levels must be unique." |

### 4.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lesson.viewAny | planning() tab render | Without → 403 |
| BC-AUTH-02 | tenant.lesson.update | saveSetting() | Without → 403 |
| BC-AUTH-03 | Guest access | Any settings route | Redirect to /login |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Tab loads | Sidebar shows 4 config keys with current values as badges |
| BC-BIZ-02 | Select a setting from sidebar | Right panel shows edit form with dropdown |
| BC-BIZ-03 | Save teaching estimation level | Value normalized, stored, page reloads after 1.2s |
| BC-BIZ-04 | Save release level | Value normalized, uniqueness check passes, stored, reload |
| BC-BIZ-05 | Format normalization | `sub_topic` → `Sub-Topic` (title-case with hyphens) |
| BC-BIZ-06 | Uniqueness check passes | 3 release levels all different → save succeeds |
| BC-BIZ-07 | Uniqueness check fails | Two release levels same → 500 with specific error message |
| BC-BIZ-08 | Metadata fallback | If no existing config, module_id=20, module_code='SLB', ordinal=3 |
| BC-BIZ-09 | Teaching estimation ignores uniqueness check | Only release level keys check uniqueness |
| BC-BIZ-10 | Activity logging | "Updated syllabus setting {key} to {value}" logged |
| BC-BIZ-11 | Post-save page reload | Success toast → 1.2s delay → location.reload() |
| BC-BIZ-12 | First-time save (INSERT) | No existing record → updateOrCreate inserts |
| BC-BIZ-13 | Subsequent save (UPDATE) | Existing record found → values updated |
| BC-BIZ-14 | Screen loads via SyllabusController@planning() at GET /syllabus/planning with tab=syllabus_settings | Navigating to GET /syllabus/planning with tab=syllabus_settings loads this screen's grid data with correct filters applied |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Settings Tab Loads With 4 Config Keys | Sidebar shows all 4 settings with current values; right panel empty or shows selected | — | — | ⬜ |
| TC-P02 | Select Teaching Estimation Level From Sidebar | Click setting → right panel shows name, description, dropdown with current value | — | — | ⬜ |
| TC-P03 | Change Teaching Estimation To "lesson" | Select "lesson" from dropdown, save → value stored, page reloads | — | — | ⬜ |
| TC-P04 | Change Teaching Estimation To "topic" | Select "topic" → stored as "Topic" | — | — | ⬜ |
| TC-P05 | Change Teaching Estimation To "sub_topic" | Select "sub_topic" → stored as "Sub-Topic" | — | — | ⬜ |
| TC-P06 | Change Teaching Estimation To "mini_topic" | Select "mini_topic" → stored as "Mini-Topic" | — | — | ⬜ |
| TC-P07 | Change Homework Release Level To "lesson" | Select "lesson" → stored as "Lesson", uniqueness check passes | — | — | ⬜ |
| TC-P08 | Change Homework Release Level To "sub_topic" | Select "sub_topic" → stored as "Sub-Topic" | — | — | ⬜ |
| TC-P09 | Change Quiz Release Level To "topic" | Select "topic" → stored as "Topic" | — | — | ⬜ |
| TC-P10 | Change Quiz Release Level To "mini_topic" | Select "mini_topic" → stored as "Mini-Topic" | — | — | ⬜ |
| TC-P11 | Change Quest Release Level To "micro_topic" | Select "micro_topic" → stored as "Micro-Topic" | — | — | ⬜ |
| TC-P12 | Change Quest Release Level To "nano_topic" | Select "nano_topic" → stored as "Nano-Topic" | — | — | ⬜ |
| TC-P13 | All 3 Release Levels Different — Saves Successfully | Save each release level to different values → all 3 succeed | — | — | ⬜ |
| TC-P14 | Setting Persists After Page Reload | Change a setting, page reloads → badge shows new value | — | — | ⬜ |
| TC-P15 | Post-Save Shows Success Toast | Save → green success toast appears | — | — | ⬜ |
| TC-P16 | Post-Save Auto-Reload After 1.2s | Save → toast → 1.2s wait → page reloads | — | — | ⬜ |
| TC-P17 | Metadata Defaults For First-Time Save | No existing config → module_id=20, module_code='SLB', ordinal=3 used | — | — | ⬜ |
| TC-P18 | Update Existing Setting (Update Or Create) | Save same key again → updates existing record | — | — | ⬜ |
| TC-P19 | View-Only User Can See Settings Sidebar | User with viewAny but not update → can see badges, cannot edit | — | — | ⬜ |
| TC-P20 | Value Normalization Round-Trip | Save "sub_topic" → DB stores "Sub-Topic" → read back normalizes to "sub_topic" | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Save Without Permission (No tenant.lesson.update) | User without update permission → HTTP 403 | — | — | ⬜ |
| TC-N02 | Invalid Key Submitted | POST with key="invalid_key" → HTTP 500: "The selected key is invalid." | — | — | ⬜ |
| TC-N03 | Invalid Value For Teaching Estimation | Set teaching estimation to "nano_topic" → 500: "Invalid option selected for this setting." | — | — | ⬜ |
| TC-N04 | Invalid Value For Release Level | Set release level to "invalid_value" → 500: "Invalid option selected for this setting." | — | — | ⬜ |
| TC-N05 | Duplicate Release Level — Homework = Quiz | Set homework and quiz to same value → 500 uniqueness error | — | — | ⬜ |
| TC-N06 | Duplicate Release Level — Homework = Quest | Set homework and quest to same value → 500 uniqueness error | — | — | ⬜ |
| TC-N07 | Duplicate Release Level — Quiz = Quest | Set quiz and quest to same value → 500 uniqueness error | — | — | ⬜ |
| TC-N08 | Guest Access Redirect | Not logged in → redirect to /login | — | — | ⬜ |
| TC-N09 | View Settings Without Permission | No viewAny → HTTP 403 on planning page | — | — | ⬜ |
| TC-N10 | Empty Value Submitted | POST value="" → validation error (required) | — | — | ⬜ |
| TC-N11 | Missing Key In Request | POST without key → validation error (required) | — | — | ⬜ |
| TC-N12 | XSS In Description Field | Description with script tag → stored safely, Blade escapes | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Teaching Estimation Change Affects Sequencing Display | Change to "sub_topic" → sequencing shows Sub-Topic rows | — | — | ⬜ |
| TC-D02 | B | Homework Release Level Affects Topic Release Control | Set homework level to "mini_topic" → topic release shows Mini-Topic rows | — | — | ⬜ |
| TC-D03 | C | Quiz Release Level Affects Release Filter | Set quiz level to "sub_topic" → quiz filter shows sub-topic rows | — | — | ⬜ |
| TC-D04 | D | Quest Release Level Affects Release Filter | Set quest level to "topic" → quest filter shows only root topics | — | — | ⬜ |
| TC-D05 | E | Multiple Release Levels Must Stay Unique | Cannot save if any two release levels match | — | — | ⬜ |
| TC-D06 | F | Config Change Does Not Affect Other Tenants | Change value in Tenant A → Tenant B unaffected | — | — | ⬜ |
| TC-D07 | G | API — P1 — Invalid key returns 500 validation error — Key Validation — `in:` rule | Submitting key="invalid_key" returns 500; 4 allowed keys pass validation | — | — | ⬜ |
| TC-D08 | H | API — P1 — Invalid value for teaching estimation level rejected — Value Validation Per Key — nano_topic not allowed | Setting teaching estimation to "nano_topic" returns 500 "Invalid option"; "mini_topic" accepted | — | — | ⬜ |
| TC-D09 | I | API — P1 — Value normalization converts sub_topic to Sub-Topic — Format Normalization — `str_replace('_', '-', ucwords(...))` | Submitting value="sub_topic" stores "Sub-Topic" in sch_configs.value | — | — | ⬜ |
| TC-D10 | J | API — P1 — Post-save triggers client-side page reload after 1.2s — Post-Save Reload — `location.reload()` delay | After successful save, client shows toast, waits 1200ms, then reloads page | — | — | ⬜ |
| TC-D11 | K | API — P2 — Activity log entry created on setting save — Activity Logging — `activityLog()` | After saving a setting, activity_logs table has entry with message "Updated syllabus setting {key} to {value}" | — | — | ⬜ |
| TC-D12 | L | API — P1 — Metadata defaults used when no existing config — Metadata Defaults — module_id=20, module_code='SLB' | First-time save uses module_id=20, module_code='SLB', ordinal=3 from fallback | — | — | ⬜ |
| TC-D13 | M | API — P1 — Schema mapping stores key_name, value_type, tenant_can_modify — Schema Metadata — all schema fields | Saved config record has key_name = "Homework Released Level", value_type = "STRING", tenant_can_modify = 1, mandatory = 1, used_by_app = 1, is_active = 1 | — | — | ⬜ |
| TC-D14 | N | API — P1 — No dedicated Policy — uses Gate directly — No Policy — `Gate::authorize('tenant.lesson.update')` | User without lesson.update permission receives 403; no Policy class exists for this feature | — | — | ⬜ |
| TC-D15 | O | API — P1 — No FormRequest — uses inline validate — No FormRequest — `$request->validate()` | Validation errors come from inline validate() not from a FormRequest class | — | — | ⬜ |
| TC-D16 | P | UI — P1 — Four config keys displayed in sidebar — Sidebar Display — 4 SchConfig keys | Page load shows all 4 keys in sidebar with current values as badges | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Settings tab and all Planning tabs are wrapped by @can('tenant.lesson.viewAny'); users without viewAny permission cannot see Planning section | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.planning` key → `'syllabus/planning'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Save Setting Returns JSON Success Response | saveSetting() returns response()->json(['success' => true, 'message' => 'Setting updated successfully.']); frontend displays success toast on response | — | — | ◌ |


---



## 7. Detailed Test Steps


#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open settings blade for this screen | View file found in lesson-management/partials/syllabus-settings/
| 2 | Scan for relationship access patterns (e.g. $setting->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Load settings with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR06: Controller — Save Setting Returns JSON Success Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SyllabusController.php | Controller found in app/Http/Controllers/
| 2 | Locate saveSetting() method | Method exists with Gate::authorize, validation, and data update logic
| 3 | Inspect the method return | Method returns response()->json(['success' => true, 'message' => 'Setting updated successfully.'])
| 4 | Send a valid POST to save-setting endpoint | Response has {success: true, message: 'Setting updated successfully.'}
| 5 | Verify frontend behavior | Success toast/notification displayed based on JSON response


#### TC-CR01: Blade @can Directives — Permission-based Tab Visibility via viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect planning/index.blade.php | Settings tab is wrapped by @can('tenant.lesson.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.lesson.viewAny'
| 3 | Log in as user with viewAny permission | Syllabus Settings tab visible in Planning section |
| 4 | Log in as user without viewAny permission | Syllabus Settings tab hidden; user cannot access Planning section |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.planning' key exists | Config has 'syllabus.planning' => 'syllabus/planning' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/planning' correctly references Planning tab view
| 4 | Load the screen via the Planning tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Planning tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Settings Tab Loads With 4 Config Keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin, navigate to Planning → Settings | Tab loads at /planning?tab=syllabus_settings |
| 2 | Check left sidebar | 4 settings listed: Syllabus Teaching Estimation Level, Homework Release Level, Quiz Release Level, Quest Release Level |
| 3 | Check each badge shows current value | Value displayed as human-readable badge |
| 4 | Check right panel | Empty or shows first selected setting |

---

#### TC-P02: Select Teaching Estimation Level From Sidebar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Syllabus Teaching Estimation Level" in sidebar | Right panel shows edit form |
| 2 | Check form fields | Setting name displayed, description textarea, dropdown with options |
| 3 | Check dropdown options | lesson, topic, sub_topic, mini_topic |
| 4 | Check current value pre-selected | Dropdown shows current value |

---

#### TC-P03: Change Teaching Estimation To "lesson"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "lesson" from dropdown | lesson selected |
| 2 | Click "Save Changes" | AJAX POST to /planning/save-setting |
| 3 | Check response | { success: true, message: "Setting updated successfully." } |
| 4 | Check toast | Green success toast |
| 5 | Wait 1.2 seconds | Page reloads automatically |
| 6 | DB check: SchConfig value for key | "Lesson" (title-case) |

---

#### TC-P04: Change Teaching Estimation To "topic"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "topic", save | Succeeds |
| 2 | DB check: value = "Topic" | Stored correctly |

---

#### TC-P05: Change Teaching Estimation To "sub_topic"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "sub_topic", save | Succeeds |
| 2 | DB check: value = "Sub-Topic" | Normalized correctly |

---

#### TC-P06: Change Teaching Estimation To "mini_topic"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "mini_topic", save | Succeeds |
| 2 | DB check: value = "Mini-Topic" | Stored correctly |

---

#### TC-P07: Change Homework Release Level To "lesson"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Homework Release Level" | Edit form shown |
| 2 | Select "lesson" from dropdown | lesson selected |
| 3 | Click Save | Uniqueness check passes (assuming quiz and quest are different) |
| 4 | Verify success | Setting updated |

---

#### TC-P08: Change Homework Release Level To "sub_topic"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "sub_topic", save | Succeeds if unique |
| 2 | DB check: value = "Sub-Topic" | Correct |

---

#### TC-P09: Change Quiz Release Level To "topic"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "topic", save | Succeeds (must differ from homework and quest) |

---

#### TC-P10: Change Quiz Release Level To "mini_topic"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "mini_topic", save | Succeeds |

---

#### TC-P11: Change Quest Release Level To "micro_topic"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "micro_topic", save | Succeeds (all 6 values valid for release levels) |

---

#### TC-P12: Change Quest Release Level To "nano_topic"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "nano_topic", save | Succeeds |

---

#### TC-P13: All 3 Release Levels Different — Saves Successfully

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Homework = "lesson" | Succeeds |
| 2 | Set Quiz = "topic" | Succeeds (differs from homework) |
| 3 | Set Quest = "sub_topic" | Succeeds (differs from both) |
| 4 | Verify all 3 different in DB | lesson, topic, sub_topic all present |

---

#### TC-P14: Setting Persists After Page Reload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change a setting to a new value | Save succeeds |
| 2 | Page reloads automatically | After 1.2s |
| 3 | Check sidebar badge | Shows new value |
| 4 | Manually refresh page | Value still shown correctly |

---

#### TC-P15: Post-Save Shows Success Toast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save a setting | Toast notification appears |
| 2 | Check toast text | "Setting updated successfully." |
| 3 | Check toast color | Green (success) |

---

#### TC-P16: Post-Save Auto-Reload After 1.2s

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save a setting | Toast appears |
| 2 | Wait 1-2 seconds | Page automatically reloads after ~1.2s delay |

---

#### TC-P17: Metadata Defaults For First-Time Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no SchConfig records exist for syllabus settings | Clean state |
| 2 | Save a new setting | INSERT succeeds |
| 3 | DB check: module_id = 20, module_code = 'SLB', ordinal = 3 | Defaults applied |

---

#### TC-P18: Update Existing Setting (Update Or Create)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save a setting with new value | UPDATE (not INSERT) |
| 2 | DB check: same id, value changed | Record updated |

---

#### TC-P19: View-Only User Can See Settings Sidebar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with viewAny but not update | Dashboard |
| 2 | Navigate to Syllabus Settings | Sidebar visible with badges |
| 3 | Click on a setting | Form displayed but dropdown disabled or save button hidden |

---

#### TC-P20: Value Normalization Round-Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save value "sub_topic" | DB stores "Sub-Topic" |
| 2 | Read from DB | Value = "Sub-Topic" |
| 3 | Normalize for internal use | "sub_topic" |

---

### 6.2 Negative TC Steps

#### TC-N01: Save Without Permission (No tenant.lesson.update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.lesson.update | Dashboard |
| 2 | Navigate to settings, try to save | HTTP 403 Forbidden |

---

#### TC-N02: Invalid Key Submitted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with key="invalid_key", value="topic" | HTTP 500 |
| 2 | Error: "The selected key is invalid." | Validation error |

---

#### TC-N03: Invalid Value For Teaching Estimation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST key="syllabus_teaching_estimation_level_for_lesson_planning", value="nano_topic" | HTTP 500 |
| 2 | Error: "Invalid option selected for this setting." | nano_topic not in allowed list for this key |

---

#### TC-N04: Invalid Value For Release Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST key="homework_released_on_syllabus_level", value="invalid_value" | HTTP 500 |
| 2 | Error: "Invalid option selected for this setting." | Validation error |

---

#### TC-N05: Duplicate Release Level — Homework = Quiz

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Quiz = "topic" | Success |
| 2 | Try to set Homework = "topic" (same as Quiz) | HTTP 500 |
| 3 | Error: "The level 'Topic' is already assigned to Quiz Release Level. Homework, Quiz, and Quest release levels must be unique." | Uniqueness violation |

---

#### TC-N06: Duplicate Release Level — Homework = Quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Quest = "mini_topic" | Success |
| 2 | Try to set Homework = "mini_topic" | HTTP 500: already assigned to Quest |

---

#### TC-N07: Duplicate Release Level — Quiz = Quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Homework = "lesson", Quiz = "topic" | Both succeed |
| 2 | Try to set Quest = "topic" (same as Quiz) | HTTP 500: already assigned to Quiz |

---

#### TC-N08: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to /planning?tab=syllabus_settings | Redirect to /login |

---

#### TC-N09: View Settings Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without tenant.lesson.viewAny | HTTP 403 on planning tab |

---

#### TC-N10: Empty Value Submitted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with value="" | HTTP 500: "The value field is required." |

---

#### TC-N11: Missing Key In Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without key field | HTTP 500: "The key field is required." |

---

#### TC-N12: XSS In Description Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save setting with description="<script>alert('xss')</script>" | Stored as literal |
| 2 | Reload settings tab | Blade escapes; no script execution |

---

### 6.3 Dependency TC Steps

#### TC-D01: Teaching Estimation Change Affects Sequencing Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set estimation level = "sub_topic" | Saved |
| 2 | Navigate to Lesson Sequencing tab | Shows Lesson + Topic + Sub-Topic columns |
| 3 | Change to "topic" | Shows only Lesson + Topic columns |

---

#### TC-D02: Homework Release Level Affects Topic Release Control

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set homework_released_on_syllabus_level = "mini_topic" | Saved |
| 2 | Navigate to Topic Release Control, select Homework filter | Shows rows at Mini-Topic depth |

---

#### TC-D03: Quiz Release Level Affects Release Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set quiz_released_on_syllabus_level = "sub_topic" | Saved |
| 2 | Topic Release Control → Quiz filter | Shows Sub-Topic rows |

---

#### TC-D04: Quest Release Level Affects Release Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set quest_released_on_syllabus_level = "topic" | Saved |
| 2 | Topic Release Control → Quest filter | Shows only root topic rows |

---

#### TC-D05: Multiple Release Levels Must Stay Unique

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Homework="lesson", Quiz="topic" | Succeeds |
| 2 | Try to set Quest="lesson" | Fails: duplicate with Homework |
| 3 | Try to set Quest="topic" | Fails: duplicate with Quiz |
| 4 | Set Quest="sub_topic" | Succeeds: unique |

---

#### TC-D06: Config Change Does Not Affect Other Tenants

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Tenant A, change estimation level to "mini_topic" | Saved |
| 2 | In Tenant B, check estimation level | Unchanged from before Tenant A's change |

---

#### TC-D07: Invalid key returns 500 validation error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to /planning/save-setting with key="invalid_key", value="topic" | HTTP 500 returned |
| 2 | Check error message | "The selected key is invalid." |
| 3 | POST with each of the 4 valid keys individually | All return 200 success |

---

#### TC-D08: Invalid value for teaching estimation level rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST key="syllabus_teaching_estimation_level_for_lesson_planning", value="nano_topic" | HTTP 500 |
| 2 | Check error message | "Invalid option selected for this setting." |
| 3 | POST same key with value="mini_topic" | Accepted (200) — mini_topic is valid for teaching estimation |

---

#### TC-D09: Value normalization converts sub_topic to Sub-Topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST key="syllabus_teaching_estimation_level_for_lesson_planning", value="sub_topic" | 200 success |
| 2 | Query sch_configs for this key | value column contains "Sub-Topic" |
| 3 | Verify format | Hyphenated title case: "Sub-Topic" not "sub_topic" or "Sub_Topic" |

---

#### TC-D10: Post-save triggers client-side page reload after 1.2s

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save any setting via the UI | AJAX POST returns success |
| 2 | Observe toast notification | Green success toast appears |
| 3 | Wait | Page automatically reloads after ~1200ms |
| 4 | Verify no manual intervention | No user action required — JS setTimeout triggers location.reload() |

---

#### TC-D11: Activity log entry created on setting save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save key="homework_released_on_syllabus_level", value="topic" | 200 success |
| 2 | Query activity_logs table | Entry found with message "Updated syllabus setting homework_released_on_syllabus_level to topic" |
| 3 | Verify log metadata | Caused by authenticated user, timestamp matches save time |

---

#### TC-D12: Metadata defaults used when no existing config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no SchConfig record exists for a syllabus setting key | Clean state |
| 2 | POST a valid save request | Setting saved successfully |
| 3 | Query sch_configs for the new record | module_id = 20, module_code = 'SLB', ordinal = 3 |
| 4 | Verify no custom metadata was provided | Defaults applied because no existing record was found |

---

#### TC-D13: Schema mapping stores key_name, value_type, tenant_can_modify

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save key="homework_released_on_syllabus_level", value="topic" | 200 success |
| 2 | Query sch_configs for the saved record | key_name = "Homework Released Level" |
| 3 | Verify value_type | "STRING" |
| 4 | Verify tenant_can_modify | 1 |
| 5 | Verify mandatory | 1 |
| 6 | Verify used_by_app | 1 |
| 7 | Verify is_active | 1 |

---

#### TC-D14: No dedicated Policy — uses Gate directly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search codebase for Policy class related to Syllabus Settings | No Policy class found |
| 2 | Inspect SyllabusController@saveSetting() | Uses Gate::authorize('tenant.lesson.update') directly |
| 3 | Login as user without tenant.lesson.update permission | Dashboard |
| 4 | Attempt to save a setting | HTTP 403 Forbidden |
| 5 | Login as user with tenant.lesson.update permission | Save succeeds (200) |

---

#### TC-D15: No FormRequest — uses inline validate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search codebase for a FormRequest class for syllabus settings | No FormRequest class found |
| 2 | Inspect SyllabusController@saveSetting() | Uses $request->validate([...]) inline |
| 3 | POST with missing required fields | Validation errors returned with 500 status |
| 4 | Check error response format | Errors generated by Laravel's base validate() method, not a custom FormRequest |

---

#### TC-D16: Four config keys displayed in sidebar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login and navigate to Planning → Settings | GET /syllabus/planning?tab=syllabus_settings loads |
| 2 | Examine left sidebar | 4 settings listed: Syllabus Teaching Estimation Level, Homework Release Level, Quiz Release Level, Quest Release Level |
| 3 | Check each badge | Each shows its current value as a human-readable badge |
| 4 | Verify no extra keys | Exactly 4 keys, no more |
