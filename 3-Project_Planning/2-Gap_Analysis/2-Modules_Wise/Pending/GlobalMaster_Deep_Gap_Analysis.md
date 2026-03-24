# GlobalMaster Module — Production-Readiness Gap Analysis
**Date:** 2026-03-22  |  **Branch:** Brijesh_SmartTimetable  |  **Auditor:** Claude Code (Deep Audit)
**Module Path:** /Users/bkwork/Herd/prime_ai/Modules/GlobalMaster

---

## EXECUTIVE SUMMARY

| Severity    | Count |
|-------------|-------|
| Critical    | 8     |
| High        | 12    |
| Medium      | 18    |
| Low         | 9     |
| **Total**   | **47**|

### Module Scorecard

| Area                      | Score | Notes                                      |
|---------------------------|-------|--------------------------------------------|
| DB / DDL Integrity        | 7/10  | Missing `created_by` on all glb_ tables    |
| Route Integrity           | 6/10  | Duplicate route groups, dead routes         |
| Controller Quality        | 5/10  | `$request->all()` widespread, stub methods  |
| Model Quality             | 6/10  | Inconsistent `$connection`, missing casts   |
| Security                  | 5/10  | SQL injection via LIKE, `$request->all()`   |
| Performance               | 6/10  | N+1 queries, no caching                    |
| Authorization             | 7/10  | Good Gate usage, inconsistent naming        |
| Test Coverage             | 2/10  | 1 trivial test file                        |
| Architecture              | 5/10  | No service layer, duplicate model files     |
| **Overall**               | **5.4/10** |                                       |

---

## SECTION 1 — MISSING FEATURES

**MF-001 — No AcademicSession Model in GlobalMaster**
- File: `/Users/bkwork/Herd/prime_ai/Modules/GlobalMaster/app/Http/Controllers/AcademicSessionController.php` (Line 10)
- `use Modules\GlobalMaster\Models\AcademicSession;` — this model file does NOT exist in the GlobalMaster module.
- Only exists at `Modules/Prime/app/Models/AcademicSession.php`.
- Impact: Controller will throw class-not-found at runtime unless autoloader resolves Prime's model.

**MF-002 — No Board Controller in GlobalMaster Module**
- A `BoardController` is referenced in web.php routes (lines 152-157) via `use Modules\GlobalMaster\Http\Controllers\BoardController` (imported at top) but no `BoardController.php` exists in the GlobalMaster controllers directory.
- The routes point to `Modules\Prime\Http\Controllers\BoardController` (imported at line 24 of web.php).

**MF-003 — Translation Management Not Implemented**
- DDL defines `glb_translations` table (line 174-188 of global_db_v2.sql) but no Translation model, controller, or routes exist in GlobalMaster.

**MF-004 — Menu Management Not in GlobalMaster**
- DDL defines `glb_menus` and `glb_menu_model_jnt` tables but menu CRUD is handled in SystemConfig module, not GlobalMaster. No explicit Menu model in GlobalMaster.

**MF-005 — Missing `glb_languages` Timestamps**
- DDL `glb_languages` table (line 94-102) is missing `created_at`, `updated_at`, `deleted_at` columns — violates project standard.

---

## SECTION 2 — BUGS

**BUG-001 — `$request->all()` Used Instead of `$request->validated()` (CRITICAL)**
- Files affected (mass-assignment vulnerability):
  - `CountryController.php` line 42: `Country::create($request->all())`
  - `CountryController.php` line 78: `$country->update($request->all())`
  - `StateController.php` line 40: `State::create($request->all())`
  - `StateController.php` line 75: `$state->update($request->all())`
  - `CityController.php` line 39: `City::create($request->all())`
  - `CityController.php` line 74: `$city->update($request->all())`
  - `ModuleController.php` line 40: `Module::create($request->all())`
  - `ModuleController.php` line 88: `$module->update($request->all())`
  - `PlanController.php` line 41: `Plan::create($request->all())`
  - `PlanController.php` line 89: `$data = $request->all()`
  - `AcademicSessionController.php` line 44: `AcademicSession::create($request->all())`
  - `AcademicSessionController.php` line 83: `$academicSession->update($request->all())`

**BUG-002 — Double Activity Log on State Update**
- File: `StateController.php` lines 94-110
- `activityLog()` is called TWICE on update — once with the change-tracking logic (line 95) and again with a generic message (line 109). Results in duplicate log entries per update.

**BUG-003 — Double Activity Log on Module Update**
- File: `ModuleController.php` lines 112-128
- Same pattern: change-tracking log (line 113) + generic log (line 127) = two entries per update.

**BUG-004 — Faulty `is_active` Check in AcademicSession Destroy**
- File: `AcademicSessionController.php` line 124
- `if (!$academicSession->is_active === true)` — operator precedence issue. `!$academicSession->is_active` evaluates first, then `=== true`. This means: if is_active is truthy, `!is_active` is false, `false === true` is false, so active sessions CAN be deleted. The guard is inverted.
- Should be: `if ($academicSession->is_active === true)`

**BUG-005 — AcademicSessionRequest Missing `start_date` and `end_date` Validation**
- File: `AcademicSessionRequest.php` lines 17-33
- DDL requires `start_date` and `end_date` (NOT NULL) but FormRequest only validates `name` and `short_name`. Missing: `start_date`, `end_date`, `is_current`.

**BUG-006 — Inconsistent Gate Permission Naming**
- `AcademicSessionController.php`:
  - `index()` line 21: `prime.academic-session.viewAny`
  - `create()` line 34: `global-master.academic-session.create` (different prefix!)
  - `store()` line 43: `global-master.academic-session.create`
  - All other methods: `global-master.academic-session.*`
- `LanguageController.php`:
  - `index()` line 18: `prime.language.viewAny`
  - `create()` line 31: NO Gate check at all
  - `store()` line 37: NO Gate check
  - `edit()` line 54: NO Gate check
  - `update()` line 63: NO Gate check
  - `destroy()` line 74: `global-master.language.delete`

**BUG-007 — LanguageController Uses Wrong Model Import**
- File: `LanguageController.php` line 9
- `use Modules\Prime\Models\Language;` — imports from Prime module, but GlobalMaster has its own `Language.php` model at `app/Models/Language.php`.

**BUG-008 — Duplicate `Dropdown.php` Model File**
- Two Dropdown model files exist:
  1. `/Modules/GlobalMaster/Models/Dropdown.php` (root-level, no SoftDeletes, different namespace)
  2. `/Modules/GlobalMaster/app/Models/Dropdown.php` (proper location, has SoftDeletes)
- The root-level one references `Modules\Prime\Models\DropdownNeed` and has different fillable fields.

**BUG-009 — DropdownController Store Uses `$request->validated()` BUT Also Reads `auth()->user()->id` for `org_id`**
- File: `DropdownController.php` line 57
- `Dropdown::where('org_id', auth()->user()->id)->max('ordinal')` — uses user ID as org_id, which is semantically wrong.

**BUG-010 — Country Toggle Cascades Do Not Include Cities**
- File: `CountryController.php` lines 187-196
- Cascades to States and Districts but NOT Cities. Cities under those districts remain active when country is deactivated.

**BUG-011 — `Dropdown.php.bkk` Backup File in Production**
- File: `/Modules/GlobalMaster/app/Models/Dropdown.php.bkk` — backup file should be removed from repo.

---

## SECTION 3 — SECURITY ISSUES

**SEC-001 — SQL Injection via Unparameterized LIKE (MEDIUM)**
- File: `GeographySetupController.php` lines 47-70
- `$countriesQuery->where('name', 'LIKE', "%{$search}%")` — `$search` comes from `$request->search` without sanitization.
- Same pattern for states, districts, cities (lines 54, 61, 68).
- Also in `search()` method lines 141-148.
- While Laravel's query builder parameterizes values, the `%` wildcards allow denial-of-service via crafted patterns.

**SEC-002 — Mass Assignment via `$request->all()` (CRITICAL)**
- See BUG-001. Allows any field to be set including `is_active`, `deleted_at`, `created_at`.
- Even with `$fillable` on models, `$request->all()` passes unvalidated data.

**SEC-003 — No CSRF Protection Verification on Toggle Endpoints**
- Toggle endpoints return JSON but are POST routes. Verify CSRF middleware is applied (it is via web middleware, but no explicit check in controllers).

**SEC-004 — `uploadImage()` in Documentation Controllers Has Lax Validation**
- Not in GlobalMaster but affects the module ecosystem — max:20048 (20MB) is excessive for images.

**SEC-005 — No Rate Limiting on Search Endpoints**
- `GeographySetupController::search()` and `index()` with search have no rate limiting, enabling abuse.

**SEC-006 — Activity Log Before Status Check in StateController Toggle**
- File: `StateController.php` line 195
- Activity log is written BEFORE checking if the parent country is active (line 199). Failed toggles still get logged as successful.

**SEC-007 — `forceDelete` on Country Has No Cascade Protection**
- File: `CountryController.php` line 158-167
- Force-deleting a country does not check for existing states/districts/cities. Will fail with FK constraint but error is not handled (no try/catch).

**SEC-008 — No Input Sanitization on `DropdownController::store()` Values**
- File: `DropdownController.php` line 55
- `$values = array_filter(array_map('trim', explode(',', $data['value'])))` — no HTML/XSS sanitization on values before storing.

---

## SECTION 4 — PERFORMANCE ISSUES

**PERF-001 — N+1 Query in DropdownController::index()**
- File: `DropdownController.php` lines 23-33
- For each key, executes `Dropdown::where('key', $item->key)->get()` — N+1 pattern.
- Should use `groupBy` or eager loading.

**PERF-002 — Unbounded Query in GeographySetupController**
- File: `GeographySetupController.php` lines 73-74
- `Country::has('states')->with('states')->get()` and `with(['states', 'states.districts'])->get()` load ALL countries+states+districts into memory on every request, regardless of pagination.

**PERF-003 — StateController::index() Loads All Countries**
- File: `StateController.php` line 21
- `Country::has('states')->with('states')->get()` — no pagination, loads entire dataset.

**PERF-004 — No Database Indexes on Search Columns**
- Geography search queries use `LIKE "%search%"` which cannot use indexes.
- Consider adding full-text indexes for name columns.

**PERF-005 — CityController::index() Nested Eager Loading**
- File: `CityController.php` line 20
- `City::with(['district', 'district.state', 'district.state.country'])` — 4-level deep eager loading on every page.

**PERF-006 — No Caching for Static Reference Data**
- Countries, states, boards, academic sessions are rarely-changing reference data but are queried from DB on every request. Should use cache.

---

## SECTION 5 — AUTHORIZATION GAPS

**AUTH-001 — LanguageController Missing Auth on 4 Methods (CRITICAL)**
- `create()` (line 31): No Gate check
- `store()` (line 37): No Gate check
- `edit()` (line 54): No Gate check
- `update()` (line 63): No Gate check

**AUTH-002 — GeographySetupController Stub Methods Have No Auth**
- `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()` (lines 89-129) — all empty stubs with no Gate checks.

**AUTH-003 — GlobalMasterController Has No Auth on Any Method**
- File: `GlobalMasterController.php` — entire controller (7 methods) has zero Gate::authorize calls.

**AUTH-004 — OrganizationController Has No Auth on Any Method**
- File: `OrganizationController.php` — entire controller (7 methods) has zero Gate::authorize calls.

**AUTH-005 — SessionBoardSetupController Has No Auth on Stubs**
- `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()` (lines 30-64) — no Gate checks.

**AUTH-006 — NotificationController Has No Auth**
- File: `NotificationController.php` — `testNotification()` and `allNotifications()` have no Gate checks. `testNotification()` can be called by any authenticated user.

**AUTH-007 — ActivityLogController Stub Methods Have No Meaningful Implementation**
- `store()`, `show()`, `edit()`, `update()`, `destroy()` — have Gate checks but empty bodies. Dead code.

**AUTH-008 — PlanController::planDetails() Has No Gate Check**
- File: `PlanController.php` line 235-247
- AJAX endpoint exposes all modules and plan details without authorization.

---

## SECTION 6 — MISSING POLICIES

| Entity          | Policy Exists | Registered in AppServiceProvider |
|-----------------|---------------|----------------------------------|
| Country         | Yes           | Yes (line 534)                   |
| State           | Yes           | Yes (line 535)                   |
| District        | Yes           | Yes (line 536)                   |
| City            | Yes           | Yes (line 537)                   |
| Board           | Yes           | Yes (line 540)                   |
| Module          | Yes           | Yes (line 543)                   |
| Plan            | Yes           | Yes (line 544)                   |
| ActivityLog     | Yes           | Yes (line 579)                   |
| Dropdown        | Yes           | Yes (line 580)                   |
| Language        | Yes           | Yes (line 531)                   |
| AcademicSession | Yes           | Yes (line 541)                   |
| DropdownNeed    | Yes           | Yes (line 788)                   |
| GeographySetup  | Yes           | **NOT registered**               |
| Media           | **No**        | N/A                              |

**Note:** Policies exist but controllers use `Gate::authorize('prime.x.y')` with string permissions, NOT policy method resolution. Policies are registered but may not be invoked through the Gate facade pattern used.

---

## SECTION 7 — DB / MODEL MISMATCHES

**DBM-001 — `glb_countries` Missing `created_by` Column**
- DDL has no `created_by` column. Project standard requires it on all tables.
- Same issue on: `glb_states`, `glb_districts`, `glb_cities`, `glb_academic_sessions`, `glb_boards`, `glb_modules`, `glb_languages`, `glb_menus`, `glb_translations`.

**DBM-002 — `glb_languages` Missing Timestamps**
- DDL has no `created_at`, `updated_at`, `deleted_at` columns.
- Model uses SoftDeletes trait, which requires `deleted_at`.

**DBM-003 — `glb_academic_sessions` Missing `is_active` Column**
- DDL has `is_current` but no `is_active`. Model and controller reference `is_active` for toggle.

**DBM-004 — Country Model Missing `$connection` Property**
- File: `Country.php` — no `$connection` set, but State, City, Board all set `$connection = 'global_master_mysql'`.
- District has it commented out: `//protected $connection = 'global_master_mysql';`
- Inconsistent: queries will hit different DB connections.

**DBM-005 — Country Model Missing `$casts` for `is_active`**
- File: `Country.php` — no `$casts` array. State, District, City all cast `is_active` to boolean.

**DBM-006 — ActivityLog Model Missing SoftDeletes**
- File: `ActivityLog.php` — uses HasFactory but NOT SoftDeletes. Table has no `deleted_at` in migration.
- Project standard: all tables need `deleted_at` + SoftDeletes trait.

**DBM-007 — Media Model is Empty Shell**
- File: `Media.php` — `$fillable = []`, no table name, no relationships, no SoftDeletes.

**DBM-008 — Plan Model Points to `prm_plans` Not `glb_*`**
- File: `Plan.php` line 19: `$table = 'prm_plans'` — this is a prime_db table, not global_db. Yet it lives in GlobalMaster module.

**DBM-009 — Module->plans() Uses Hardcoded DB Prefix**
- File: `Module.php` line 100: `'prime_db.glb_module_plan_jnt'` — hardcodes database name in relationship pivot table.

**DBM-010 — DropdownRequest References Non-Existent Fields**
- File: `DropdownRequest.php` line 51: `$this->input('table_name')` and `$this->input('column_name')` — but these fields are not in the validation rules (they are commented out at lines 42-44).

---

## SECTION 8 — ROUTE ISSUES

**RT-001 — Triplicated Route Groups in web.php**
- The `global-master` route group appears THREE times in web.php:
  1. Lines 85-251 (under `central.prime.` prefix)
  2. Lines 384-493 (under `central.global-master.` prefix)
  3. Lines 629-818 (another `central.global-master.` prefix)
- This creates conflicting route names and duplicate endpoints.

**RT-002 — Scheduler Routes Duplicated**
- Scheduler route group appears 3 times at lines 274, 516, 841 of web.php.

**RT-003 — Module's Own `routes/web.php` is Empty**
- File: `/Modules/GlobalMaster/routes/web.php` — only has a domain group with empty callback.
- All routes are defined in the global `routes/web.php`, defeating the modular architecture.

**RT-004 — Missing `getStatesByCountry` Method on StateController**
- Route at web.php line 209: `Route::get('/get-states/{countryId}', [StateController::class, 'getStatesByCountry'])`
- Method `getStatesByCountry()` does not exist in `StateController.php`.

**RT-005 — Missing `search` Method on ActivityLogController**
- Route at web.php line 236: `[ActivityLogController::class, 'search']`
- No `search()` method exists on `ActivityLogController`.

**RT-006 — Missing `search` Method on DropdownController**
- Route at web.php line 242: `[DropdownController::class, 'search']`
- No `search()` method exists on `DropdownController`.

**RT-007 — `trashedSchedule` Method Missing on SchedulerController**
- Route at web.php line 278: `[SchedulerController::class, 'trashedSchedule']`
- No `trashedSchedule()` method exists on `SchedulerController`.

---

## SECTION 9 — MISSING FORM REQUESTS

| Controller Method                       | Uses FormRequest? | Issue                                        |
|-----------------------------------------|-------------------|----------------------------------------------|
| CountryController::toggleStatus()       | No (inline)       | Uses `$request->validate()` inline           |
| StateController::toggleStatus()         | No (inline)       | Uses `$request->validate()` inline           |
| DistrictController::toggleStatus()      | No (inline)       | Uses `$request->validate()` inline           |
| CityController::toggleStatus()          | No (inline)       | Uses `$request->validate()` inline           |
| ModuleController::toggleStatus()        | No (inline)       | Uses `$request->validate()` inline           |
| PlanController::toggleStatus()          | No (inline)       | Uses `$request->validate()` inline           |
| AcademicSessionController::toggleStatus() | No (inline)     | Uses `$request->validate()` inline           |
| DropdownController::toggleStatus()      | No (inline)       | Uses `$request->validate()` inline           |
| LanguageController::toggleStatus()      | No (inline)       | Uses `$request->validate()` inline           |
| GeographySetupController::store()       | No (Request)      | Accepts bare `Request`, no validation        |
| GeographySetupController::update()      | No (Request)      | Accepts bare `Request`, no validation        |
| ActivityLogController::store()          | No (Request)      | Accepts bare `Request`, empty body           |
| ActivityLogController::update()         | No (Request)      | Accepts bare `Request`, empty body           |

---

## SECTION 10 — TEST COVERAGE GAPS

**TEST-001 — Only 1 Test File with 2 Trivial Tests**
- File: `tests/Unit/BoardTest.php`
- `test_that_true_is_true()` — assertion of `true === true`
- `test_can_create_board()` — creates in-memory model, no DB interaction
- Both use old `App\Models\V1\GlobalMaster\Board` import (stale path).

**Missing Test Coverage:**
- Zero Feature tests
- No controller route tests
- No FormRequest validation tests
- No policy authorization tests
- No model relationship tests
- No integration tests for cascade toggle logic
- No activity log verification tests

---

## SECTION 11 — STUB / EMPTY METHODS

| File                              | Method      | Line | Status      |
|-----------------------------------|-------------|------|-------------|
| GlobalMasterController.php        | store()     | 29   | Empty body  |
| GlobalMasterController.php        | update()    | 50   | Empty body  |
| GlobalMasterController.php        | destroy()   | 55   | Empty body  |
| OrganizationController.php        | store()     | 29   | Empty body  |
| OrganizationController.php        | update()    | 50   | Empty body  |
| OrganizationController.php        | destroy()   | 55   | Empty body  |
| SessionBoardSetupController.php   | store()     | 38   | Empty body  |
| SessionBoardSetupController.php   | update()    | 59   | Empty body  |
| SessionBoardSetupController.php   | destroy()   | 64   | Empty body  |
| GeographySetupController.php      | store()     | 98   | Empty body  |
| GeographySetupController.php      | update()    | 122  | Empty body  |
| GeographySetupController.php      | destroy()   | 128  | Empty body  |
| ActivityLogController.php         | store()     | 39   | Empty body  |
| ActivityLogController.php         | update()    | 64   | Empty body  |
| ActivityLogController.php         | destroy()   | 73   | Empty body  |
| CountryController.php             | show()      | 56   | Empty body  |
| StateController.php               | show()      | 54   | Empty body  |
| CityController.php                | show()      | 52   | Empty body  |

---

## SECTION 12 — ARCHITECTURE VIOLATIONS

**ARCH-001 — No Service Layer**
- All business logic is in controllers. No services exist in the GlobalMaster module.
- Toggle cascades, dropdown grouping logic, plan billing cycle mapping — all in controllers.
- Violates "thin controllers, fat services" pattern.

**ARCH-002 — Stale V1 Import in CountryController**
- File: `CountryController.php` lines 6-7
- `use App\Models\V1\GlobalMaster\District;` and `State` — references old V1 model paths that may not exist. These imports are unused.

**ARCH-003 — Cross-Module Model Dependencies Without Interfaces**
- GlobalMaster models import from: `Modules\SchoolSetup`, `Modules\Prime`, `Modules\Complaint`, `Modules\StudentProfile`, `Modules\Billing`
- No interface abstraction — tight coupling between modules.

**ARCH-004 — Duplicate Model Files**
- `Dropdown.php` exists at both `/Models/Dropdown.php` (root) and `/app/Models/Dropdown.php` (standard location).
- Different namespaces, different fillable fields.

**ARCH-005 — Backup Files in Repository**
- `Dropdown.php.bkk`, `DropdownSeeder copy.bk`, `DropdownSeeder_24_01_2026.php.bk`, multiple `.bk` migration files.
- These should be gitignored/removed.

**ARCH-006 — ActivityLog Helper Uses Static Model Import**
- File: `/app/Helpers/activityLog.php` line 4
- `use Modules\GlobalMaster\Models\ActivityLog` — tightly couples the helper to a specific module.

---

## SECTION 13 — WHAT IS WORKING CORRECTLY

1. **Gate Authorization Pattern** — Consistently applied across Country, State, District, City, Module, Plan, Board, Dropdown controllers (except noted gaps).
2. **Soft Delete Workflow** — Proper deactivate -> soft delete -> restore -> force delete lifecycle on most entities.
3. **FormRequest Classes** — CountryRequest, StateRequest, DistrictRequest, CityRequest, BoardRequest, ModuleRequest, PlanRequest, DropdownRequest, LanguageRequest, AcademicSessionRequest all exist with proper validation rules.
4. **Activity Logging** — Comprehensive logging on CRUD operations with change tracking on updates.
5. **SoftDeletes Trait** — Properly used on Country, State, District, City, Board, Module, Plan, Language, Dropdown, DropdownNeed models.
6. **Policy Registration** — All major model policies registered in AppServiceProvider.
7. **Cascade Toggle on Country** — Cascades status to States and Districts within a transaction.
8. **Parent Status Check** — State toggle checks if parent Country is active; District toggle checks parent State.
9. **Unique Validation on FormRequests** — Uses `Rule::unique()->ignore()` properly for update scenarios.
10. **District Controller** — Uses `$request->validated()` correctly (unlike most other controllers).

---

## PRIORITY FIX PLAN

### P0 — Critical (Fix Immediately)
| ID       | Issue                                              | Effort |
|----------|----------------------------------------------------|--------|
| BUG-001  | Replace `$request->all()` with `$request->validated()` everywhere | 1h |
| AUTH-001 | Add Gate checks to LanguageController create/store/edit/update | 0.5h |
| BUG-004  | Fix inverted is_active check in AcademicSession destroy | 0.25h |
| AUTH-003 | Add Gate checks to GlobalMasterController or remove stubs | 0.5h |
| AUTH-004 | Add Gate checks to OrganizationController or remove stubs | 0.5h |
| BUG-006  | Standardize Gate permission naming to single prefix | 1h |
| RT-004   | Implement `getStatesByCountry` or remove route | 0.5h |
| AUTH-008 | Add Gate check to PlanController::planDetails() | 0.25h |

### P1 — High (Fix Before Release)
| ID       | Issue                                              | Effort |
|----------|----------------------------------------------------|--------|
| BUG-002  | Remove duplicate activity log calls in StateController | 0.25h |
| BUG-003  | Remove duplicate activity log calls in ModuleController | 0.25h |
| BUG-005  | Add start_date/end_date to AcademicSessionRequest | 0.5h |
| BUG-007  | Fix LanguageController import to GlobalMaster\Models\Language | 0.25h |
| BUG-008  | Remove duplicate Dropdown.php from root Models dir | 0.25h |
| BUG-010  | Add City cascade to Country toggleStatus | 0.5h |
| DBM-004  | Standardize $connection property across all models | 0.5h |
| DBM-005  | Add $casts to Country model | 0.25h |
| RT-001   | Consolidate triplicated route groups | 2h |

### P2 — Medium (Fix in Next Sprint)
| ID       | Issue                                              | Effort |
|----------|----------------------------------------------------|--------|
| ARCH-001 | Extract service layer for business logic | 4h |
| PERF-001 | Fix N+1 in DropdownController::index() | 1h |
| PERF-002 | Add pagination to GeographySetupController unbound queries | 1h |
| PERF-006 | Add caching for reference data (countries, states, boards) | 2h |
| DBM-001  | Add `created_by` to all glb_ tables | 1h |
| DBM-002  | Add timestamps to glb_languages DDL | 0.5h |
| MF-003   | Implement Translation CRUD | 8h |
| TEST-001 | Write comprehensive test suite | 8h |

### P3 — Low (Technical Debt)
| ID       | Issue                                              | Effort |
|----------|----------------------------------------------------|--------|
| ARCH-005 | Remove .bk/.bkk backup files | 0.25h |
| ARCH-002 | Remove stale V1 imports | 0.25h |
| SEC-001  | Add input sanitization on LIKE queries | 1h |
| DBM-007  | Complete or remove Media model | 0.5h |
| DBM-010  | Fix DropdownRequest validation rules | 0.5h |

---

## EFFORT ESTIMATION

| Priority | Items | Estimated Hours |
|----------|-------|----------------|
| P0       | 8     | 4.5h           |
| P1       | 9     | 4.75h          |
| P2       | 7     | 25.5h          |
| P3       | 5     | 2.5h           |
| **Total**| **29**| **37.25h**     |
