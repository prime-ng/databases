# Template Module — Mode X Complete Audit
**Date:** 2026-06-30
**Auditor:** Technical Auditor Agent (Mode X — 12-Layer A+B+C+G+D Protocol)
**Module:** TMP — Template
**Module Path:** `Modules/Template/`
**Health Score:** 40 / 100 — P0-CAPPED
**Deploy Gate:** ❌ NO-GO

---

## Module Architecture Context

| Property | Value |
|---|---|
| Type | Tenant module (tenant_db; per-school isolation via DB connection) |
| DB Layer | Tenant only — `tmp_*` tables in tenant_db |
| EnsureTenantHasModule | ABSENT from RSP — P0 (SEC-PLATFORM-003) |
| Purpose | Platform rendering engine: TemplateEngine consumed by MSH, STD, FIN, EXM, CRT |
| Controllers | 5 (Template, TemplateType, TemplatePurpose, TemplateVariable, TemplateAssignment) |
| Models | 6 (Template, TemplateType, TemplatePurpose, TemplateVariable, TemplateVariableJnt, TemplateAssignment) |
| FormRequests | 10 (Store + Update pair for each of 5 resources) |
| Policies | 5 — all registered in TemplateServiceProvider |
| Services | 2 (TemplateEngine — final singleton; TemplateService — @deprecated wrapper) |
| Contracts | 2 (TemplateEngineInterface, DataProviderInterface) |
| Exceptions | 2 (TemplateNotFoundException, TemplateRenderException) |
| Facade | 1 (Template — alias for `Template::render(...)`) |
| Tests | 17 (12 unit TemplateEngineTest + 5 migration TemplateMigrationTest) |
| Views | ~35 (5×5 CRUD grid + tab-view + 3 partials + layout) |

**BA Pre-Audit Estimate:** ~75–80% (most solid seeded module)

---

## Summary of Findings

| Severity | Count | IDs |
|---|---|---|
| P0 | 3 | SEC-PLATFORM-003, GAP-TMP-02, BUG-TMP-03 |
| P1 | 7 | SEC-TMP-01, SEC-TMP-02, SEC-TMP-03, BUG-TMP-04, GAP-TMP-05, BUG-TMP-05, API-TMP-01 |
| P2 | 7 | BR-001, BR-009, BR-010, BR-008/016, GAP-TMP-11, GAP-TMP-08, PERF-TMP-01 |
| P3 | 2 | D30 (10/10 FormRequests), GAP-TMP-12 |
| Cleared | 2 | GAP-TMP-07, GAP-TMP-10 |

**P0 presence activates hard cap: Health capped at 40/100. Deploy: NO-GO.**

---

## P0 Findings — Critical / Deploy Blockers

---

### SEC-PLATFORM-003 — EnsureTenantHasModule Absent [CONFIRMED — Platform-Wide Pattern]

**File:** `Modules/Template/app/Providers/RouteServiceProvider.php:42–53`

**Evidence:**
```php
protected function mapWebRoutes(): void
{
    Route::middleware([
            'web',
            InitializeTenancyByDomain::class,
            PreventAccessFromCentralDomains::class,
            EnsureTenantIsActive::class,
            'auth',
            'verified',
        ])
        ->prefix('template')
        ->name('template.')
        ->group(module_path($this->name, '/routes/web.php'));
}
```

`EnsureTenantHasModule` is absent. The tenancy stack is otherwise complete (InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified). Any authenticated tenant user whose school has NOT subscribed to the Template module can access all Template routes — template designer, variable management, assignment creation, background image upload.

**Pattern note:** This is confirmed in 12/13 tenant modules audited. Only STD (StudentProfile) has EnsureTenantHasModule correctly applied via `module:STUDENT` in web.php.

**Fix:** Add `EnsureTenantHasModule::class` to the middleware array after `EnsureTenantIsActive::class`.

---

### GAP-TMP-02 — Class Group Fallback NOT Implemented in TemplateEngine::resolveTemplate() [CONFIRMED FROM BA]

**File:** `Modules/Template/app/Services/TemplateEngine.php:120–165`

**Evidence:** The entire `resolveTemplate()` method spans 45 lines and queries only `ta.class_id` and `ta.academic_session_id`. No query ever references `ta.class_group_id`.

Confirmed fallback chain in live code (6 attempts):
1. `ta.academic_session_id = $sessionId` + `ta.class_id = $classId`
2. `ta.academic_session_id = $sessionId` + `ta.class_id IS NULL`
3. JNT join + `soas.academic_session_id = $sessionId` + `ta.class_id = $classId`
4. JNT join + `soas.academic_session_id = $sessionId` + `ta.class_id IS NULL`
5. `ta.academic_session_id IS NULL` + `ta.class_id = $classId`
6. `ta.academic_session_id IS NULL` + `ta.class_id IS NULL`
7. FAIL → `TemplateNotFoundException::forPurpose($purposeCode)`

**None of these 6 attempts query `ta.class_group_id`.**

V1 spec defines the fallback as: Class → Class Group → School. The DB schema supports it (`tmp_template_assignments.class_group_id`, scope_hash formula `G{class_group_id}`). The UI allows creating group-scoped assignments. But when the engine runs for a student whose class_id is only group-matched, it falls through to school-wide fallback or throws TemplateNotFoundException.

**Impact:** For any school that configured a class-group-level template assignment (instead of a class-level or school-wide assignment), PDF rendering either fails with an exception or uses the wrong template. This is a deploy blocker for schools using group-based assignment.

**Fix:** After step 2 and 4, add a group-lookup step:
```php
// 1b. Get all groups containing $classId via msh_class_group_items_jnt
if ($classId) {
    $groupIds = DB::table('msh_class_group_items_jnt')->where('class_id', $classId)->pluck('class_group_id');
    if ($groupIds->isNotEmpty()) {
        $found = (clone $q1)->whereIn('ta.class_group_id', $groupIds)->whereNull('ta.class_id')->value('ta.template_id');
        if ($found) return (int) $found;
    }
}
```

---

### BUG-TMP-03 — `value_type` Column Missing from tmp_template_variables Migration [CONFIRMED FROM BA, VERIFIED]

**File:** `database/migrations/tenant/2026_06_16_082736_create_tmp_template_variables_table.php`

**Engine Reference:** `Modules/Template/app/Services/TemplateEngine.php:237`

**Evidence:**

Migration defines these columns for `tmp_template_variables`:
`id`, `name`, `description`, `db_name`, `table_name`, `field_name`, `is_active`, `created_at`, `updated_at`, `template_type_id`, `deleted_at`

**`value_type` is NOT present.** A full grep of all tenant migrations confirms NO ALTER TABLE or subsequent migration adds `value_type` to `tmp_template_variables`.

The engine accesses it at line 237:
```php
$resolved[$name] = $this->formatVariableValue(
    (string) ($var->value_type ?? 'text'),
    $raw,
    $name,
);
```

Since the column doesn't exist, `$var->value_type` returns null (Eloquent returns null for non-existent attributes). The null-coalescing to `'text'` means **every variable of every template in every tenant is treated as 'text' type regardless of intent.**

**Engine behavior per type:**
| Intended Type | Actual Type (Bug) | Result |
|---|---|---|
| `text` | `text` | HTML-escaped → Correct |
| `html` | `text` | HTML-escaped → Tags appear as entities (e.g., `&lt;b&gt;`) |
| `image` | `text` | HTML-escaped → Raw file path rendered as text, no `<img>` tag |

**Impact:** Student photos in marksheets/ID cards do not render as images — only the file path appears as text. Any HTML-formatted variable (formatted text blocks) shows raw escaped tags. This breaks all PDF generation that depends on image or HTML type variables — the core value proposition of the Template engine.

**Fix:** Add migration:
```php
Schema::table('tmp_template_variables', function (Blueprint $table) {
    $table->enum('value_type', ['text', 'html', 'image'])->default('text')->after('field_name');
});
```
Add `value_type` to `StoreTemplateVariableRequest` and `UpdateTemplateVariableRequest` rules. Update TemplateVariableSeeder to seed correct types for common variables (image type for student_photo, school_logo, etc.).

---

## P1 Findings

---

### SEC-TMP-01 — SQL Injection in getTables() and getColumns() [NEW]

**File:** `Modules/Template/app/Http/Controllers/TemplateVariableController.php:233, 254`

```php
// getTables()
$tables = DB::select("SHOW TABLES FROM `{$dbName}`");

// getColumns()
$columns = DB::select("SHOW COLUMNS FROM `{$dbName}`.`{$tableName}`");
```

`$dbName` and `$tableName` are raw values from `$request->db_name` / `$request->table_name` — no whitelist, no parameterized binding. While backtick quoting limits exploitation, injecting a backtick in the value breaks the quoting (e.g., `db_name = "prime_db\`; DROP TABLE sys_settings;--"`). These methods ARE gated with `Gate::authorize('tenant.template.variable.view')`, so the attack surface is authorized tenant users only — but that includes school admins.

**Fix:**
```php
$allowedDbs = ['tenant_db']; // Or resolve the current tenant DB name dynamically
if (!in_array($dbName, $allowedDbs, true)) {
    return response()->json(['error' => 'Invalid database'], 422);
}
```

---

### SEC-TMP-02 — getDatabases() Exposes Cross-Layer / Cross-Tenant DB Schema [NEW]

**File:** `Modules/Template/app/Http/Controllers/TemplateVariableController.php:207–220`

`DB::select('SHOW DATABASES')` returns ALL databases visible to the MySQL connection user, including `prime_db`, `global_db`, and other tenant databases (e.g., `tenant_abc123`). The filter only excludes `information_schema`, `mysql`, `performance_schema`, `sys`.

Tenant school admins with `tenant.template.variable.view` permission can:
1. Enumerate all databases on the server (prime_db, global_db, all tenant DBs)
2. Enumerate all tables in those databases via getTables()
3. Enumerate all columns of those tables via getColumns()

This also runs on every `create()` and `edit()` form load (`TemplateVariableController.php:37`, `87`) — not just the AJAX endpoint.

**Impact:** Multi-tenant schema enumeration; other tenants' DB names revealed; prime/global layer schema exposed to tenant users.

**Fix:** Replace `SHOW DATABASES` with the current tenant's database name only:
```php
$currentDb = config('database.connections.tenant.database', '');
return response()->json([$currentDb]);
```

---

### SEC-TMP-03 — TemplateController::uploadImage() No Gate::authorize [NEW]

**File:** `Modules/Template/app/Http/Controllers/TemplateController.php:408–431`

```php
public function uploadImage(Request $request): JsonResponse
{
    $request->validate([
        'image' => 'required|image|max:5120|mimes:jpg,jpeg,png,gif,webp'
    ]);
    // NO Gate::authorize here
```

Any `auth+verified` tenant user (teacher, parent, student) can upload files to `template-backgrounds/` on the public disk without any template permission. File type and size (5MB) are validated — but no authorization for WHO can upload.

**Impact:** Storage abuse by any authenticated user. Files persist on disk even after the template using them is deleted.

**Fix:** Add `Gate::authorize('tenant.template.create');` or `Gate::authorize('tenant.template.update');` as the first line of the method.

---

### BUG-TMP-04 — Template `code` Field Overwritable via update() [NEW]

**File:** `Modules/Template/app/Http/Requests/UpdateTemplateRequest.php:26`; `Modules/Template/app/Http/Controllers/TemplateController.php:318`

`UpdateTemplateRequest` includes `code` in its rules:
```php
'code' => ['required', 'string', 'max:50', 'unique:tmp_templates,code,' . $this->route('template')],
```

`TemplateController::update()` passes `$validated['code']` to `$template->update([...])`:
```php
$template->update([
    'code' => $validated['code'],
    ...
]);
```

**Design Decision (from module spec):** `tmp_templates.code` is the immutable machine identifier for the template, used in purpose code inference (`inferPurposeCode()`), logging, and external references. Changing it mid-lifecycle breaks any cross-module reference to the template by code.

**Fix:** Remove `code` from `UpdateTemplateRequest::rules()`. In the controller update array, omit `'code'` or use `$template->code` (preserve current value).

---

### GAP-TMP-05 — TemplatePurposeController::update() Missing is_system Guard [CONFIRMED BR-007]

**File:** `Modules/Template/app/Http/Controllers/TemplatePurposeController.php:91–105`

`update()` has NO `is_system` check:
```php
public function update(UpdateTemplatePurposeRequest $request, $id): RedirectResponse
{
    Gate::authorize('tenant.template.purpose.update');
    $purpose = TemplatePurpose::findOrFail($id);
    $validated = $request->validated();
    $validated['is_system'] = $request->boolean('is_system');
    $purpose->update($validated); // No is_system check
```

`destroy()` and `forceDelete()` both guard correctly:
```php
if ($purpose->is_system) {
    return redirect()->with('error', 'Cannot delete a system template purpose.');
}
```

**Impact:** Any user with `tenant.template.purpose.update` can change the `code` of system-seeded purposes (MARKSHEET_PRINT, FEE_RECEIPT, STUDENT_ID_CARD, etc.). All engine calls referencing these purpose codes by string (`TemplateEngine::render('MARKSHEET_PRINT', ...)`) would then throw `TemplateNotFoundException`.

**Fix:** Add at the start of `update()`:
```php
if ($purpose->is_system) {
    return back()->with('error', 'Cannot modify a system template purpose.');
}
```

---

### BUG-TMP-05 — TemplateController::forceDelete() No Active-Assignment Guard [CONFIRMED BR-017]

**File:** `Modules/Template/app/Http/Controllers/TemplateController.php:463–472`

```php
public function forceDelete($id): RedirectResponse
{
    Gate::authorize('tenant.template.forceDelete');
    $template = Template::withTrashed()->findOrFail($id);
    $template->forceDelete(); // No active assignment check
```

Design Decision: "Hard delete of template blocked if active assignments exist." No such check is implemented. After hard delete, `tmp_template_assignments` rows still reference the deleted template_id; the engine's `loadTemplate()` will throw `TemplateNotFoundException` for those assignments.

**Fix:**
```php
if ($template->assignments()->where('is_active', true)->exists()) {
    return back()->with('error', 'Cannot permanently delete a template with active assignments. Deactivate assignments first.');
}
```

---

### API-TMP-01 — API Routes Missing Tenancy Middleware [CONFIRMED]

**File:** `Modules/Template/routes/api.php:6`; `Modules/Template/app/Providers/RouteServiceProvider.php:63`

```php
// routes/api.php
Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::apiResource('templates', TemplateController::class)->names('template');
});

// RouteServiceProvider::mapApiRoutes()
Route::middleware('api')->prefix('api')->name('api.')->group(...)
```

No `InitializeTenancyByDomain` or any tenancy middleware on the API routes. The 5 apiResource endpoints (index, store, show, update, destroy) have no tenant context — any DB query would hit the default (central) connection, not the tenant DB. These routes are live and registered.

**Fix:** Add tenancy middleware to RSP::mapApiRoutes(), or remove the API routes if unused (no API consumers documented).

---

## P2 Findings

---

### BR-001 — Activation Guard Not Enforced (≥1 Variable Before is_active=1)

**File:** `Modules/Template/app/Http/Controllers/TemplateController.php:375–403`

`toggleStatus()` simply sets `$template->is_active = $request->is_active` with no check for variable existence. A user can activate a template that has no variables — the engine would render it with all placeholders unresolved (empty strings replacing all `@{{...}}`).

**Fix:** Before setting is_active=true: `if ($template->variables()->where('is_active', true)->count() === 0) { ... error ... }`

---

### BR-009 — Variable Name Format Not Validated

**File:** `Modules/Template/app/Http/Requests/StoreTemplateVariableRequest.php:20–30`

Variable `name` field has only `required|string|max:50|unique`. The spec mandates `[a-z0-9_]` format. Users can create variables named `Student Name`, `student-name`, or `STUDENT_NAME` — all valid against current rules but non-standard. The engine regex `/@?\{\{\s*([^}]+?)\s*\}\}/` would match them, but inconsistent naming degrades readability and cross-module compatibility.

**Fix:** Add `'regex:/^[a-z0-9_]+$/'` to `name` rules in both StoreTemplateVariableRequest and UpdateTemplateVariableRequest.

---

### BR-010 — Partial Mapping Cross-Field Validation Missing

**File:** `Modules/Template/app/Http/Requests/StoreTemplateVariableRequest.php`

No cross-field validation enforces: `table_name` and `field_name` must either both be provided or both be null. A variable with `table_name = 'std_students'` but `field_name = null` triggers `resolveFromDb()` → `fetchColumn()` is not called (no `$var->field_name` check guard) → null returned silently.

**Fix:** Add `withValidator()` with: if `table_name` filled then `field_name` required, and vice versa.

---

### BR-008/BR-016 — destroy() Doesn't Cascade is_active=0 to Assignments

**File:** `Modules/Template/app/Http/Controllers/TemplateController.php:360–370`

Design Decision: "Soft-delete on template cascades `is_active=0` on related assignments." `destroy()` calls `$template->delete()` with no cascade logic. Active assignments referencing a soft-deleted template remain active — the engine's `loadTemplate()` only checks `Template::find()` (no soft-delete scope), so it loads the template correctly. However, the assignment appears active in UI while the template is "deleted" — confusing state.

**Fix:** Add before `$template->delete()`:
```php
$template->assignments()->where('is_active', true)->update(['is_active' => false]);
```

---

### GAP-TMP-11 — fetchColumn() Silent Null on Unknown Table

**File:** `Modules/Template/app/Services/TemplateEngine.php:282–315`

When a variable's `table_name` is not in the whitelist match statement, `fetchColumn()` returns `null` silently:
```php
default => null,
```

A misconfigured variable (e.g., typo in `table_name`) produces a blank placeholder in the rendered PDF with no warning, no log entry, no exception. Diagnosis requires tracing back through rendered output.

**Fix:** Change `default => null` to:
```php
default => (function () use ($table, $field) {
    \Illuminate\Support\Facades\Log::warning("TemplateEngine: unresolved variable table_name=[{$table}] field=[{$field}]");
    return null;
})(),
```

---

### GAP-TMP-08 — Hard Coupling to MarksheetGeneration Module [CONFIRMED FROM BA]

**Files:** `TemplateController.php:31`; `TemplateAssignmentController.php:22`

Both import `Modules\MarksheetGeneration\Models\ClassGroup` for the assignment form dropdowns. Template is designed as a generic engine — importing from a specific consumer creates a hard dependency: Template module cannot be used without MarksheetGeneration present.

**Fix:** Move `ClassGroup` model to a shared location (SchoolSetup module), or replace with a raw DB query in the controller.

---

### PERF-TMP-01 — SHOW DATABASES on Every create/edit Form Load

**File:** `Modules/Template/app/Http/Controllers/TemplateVariableController.php:37–44, 87–94`

`DB::select('SHOW DATABASES')` runs synchronously on every `create()` and `edit()` view handler (not just the AJAX getDatabases() endpoint). This queries the MySQL information_schema on every variable form load — a slow metadata operation added to the hot view path.

**Fix:** Remove from `create()` and `edit()`; let the form use the AJAX endpoint `getDatabases()` to load databases asynchronously after page load.

---

## P3 Findings

---

### D30 — 10/10 FormRequests Return authorize()=true

All 10 FormRequests confirm `return true` in `authorize()`:
`StoreTemplateRequest`, `UpdateTemplateRequest`, `StoreTemplateVariableRequest`, `UpdateTemplateVariableRequest`, `StoreTemplatePurposeRequest`, `UpdateTemplatePurposeRequest`, `StoreTemplateAssignmentRequest`, `UpdateTemplateAssignmentRequest`, `StoreTemplateTypeRequest`, `UpdateTemplateTypeRequest`

Platform average: 70–100% D30. TMP is 100% — matching worst-case. Authorization delegated entirely to controller Gate::authorize calls (which is correct — but FormRequest should also gate via `Gate::allows` for defense-in-depth).

---

### GAP-TMP-12 — Zero Rate Limiting

No rate limiting on any Template route, including:
- `GET /template/{template}/preview-sample` — triggers full DB resolution (student data, school data, academic session)
- `POST /template/upload-image` — file upload endpoint
- AJAX schema introspection endpoints (getDatabases/getTables/getColumns)

---

## Cleared / Stale BA Findings

| ID | BA Finding | Status |
|---|---|---|
| GAP-TMP-07 | `config/template.php` doesn't exist — providers map missing | ✅ CLEARED — File exists at `config/template.php` with 3 registered providers: MARKSHEET_PRINT (MarksheetDataProvider), STUDENT_ID_CARD (StudentIdCardDataProvider), TRANSPORT_STAFF_ID_CARD (TransportStaffIdCardDataProvider) |
| GAP-TMP-10 | StoreTemplateVariableRequest no unique validation for compound key | ✅ CLEARED — `Rule::unique('tmp_template_variables')->where('template_type_id', $this->input('template_type_id'))` correctly enforces compound unique |

---

## Verified Good

| Item | Finding |
|---|---|
| Policy registration | All 5 policies registered in `TemplateServiceProvider::registerPolicies()` — no duplicate kill |
| Permission prefix consistency | All 5 controllers use consistent `tenant.template.*` namespace (no prefix chaos) |
| TemplatePolicy prefix | Matches controller: `tenant.template.*` ✅ |
| TemplateVariablePolicy prefix | Matches controller: `tenant.template.variable.*` ✅ |
| TemplateAssignmentController DB::transaction | store() + update() both use DB::beginTransaction/commit/rollBack with scope-hash duplicate detection and user-friendly error messages |
| TemplateTypeController guard on destroy/forceDelete | destroy() checks `$templateType->templates()->exists()` before soft delete; forceDelete() checks `->withTrashed()->exists()` |
| TemplatePurposeController guard on destroy/forceDelete | Both check `$purpose->is_system` and block with error ✅ (only update() is missing this guard) |
| TemplateController CRUD methods | 11/12 methods fully gated with correct `tenant.template.*` permissions; only uploadImage() lacks Gate |
| TemplateEngine — exception handling | TemplateRenderException wraps all Throwable in renderById(); TemplateNotFoundException has named constructors `forPurpose()` and `forId()` |
| TemplateEngine — legacy marker translation | All 6 legacy marker pairs correctly translated before loop expansion |
| TemplateEngine — background image | `__BG_URL__` placeholder correctly replaced via `tenant_asset()` |
| TemplateEngine — caller data override | `array_merge($providerData, $data)` — caller wins on collision ✅ |
| Unit tests (TemplateEngineTest) | 12 Pest cases covering: singleton, legacy markers, loop expand (single/multi/empty), format value (image/text/html), resolveProviderData (with/without provider) |
| Migration tests (TemplateMigrationTest) | 5 cases verifying all 6 tmp_* tables exist + key columns present |
| D29: ENUM columns | 0 ENUM columns in any tmp_* migration ✅ (clean) |
| config/template.php | Exists with 3 providers — TemplateEngine provider-resolution works correctly |
| TemplateHtmlNormalizer | Injected via `app(TemplateHtmlNormalizer::class)` in store/update — HTML cleaned before persisting |
| pdf generation | toPdf() uses `Pdf::loadHTML()` + `setPaper($size, $orientation)` — correct DomPDF usage |

---

## Systemic Pattern Scorecard (TMP)

| Pattern | Status | Notes |
|---|---|---|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ CONFIRMED | RSP missing it; 3rd confirmation in this session's batch |
| D30: FormRequest authorize()=true | ✅ CONFIRMED | 10/10 = 100% — worst rate in platform |
| D29: ENUM columns | ❌ NOT present | 0 ENUMs in all 6 tmp_* tables — clean |
| D24: Permission prefix consistency | ❌ NOT present — ABOVE BASELINE | All 5 controllers use consistent `tenant.template.*` namespace |
| Duplicate Gate::policy() kill | ❌ NOT present | 5 policies registered, no duplicates |
| ARCH-SLK-01: Cross-layer model import | ❌ NOT present | No cross-layer model imports |
| ClassGroup hard coupling | ✅ CONFIRMED | TemplateController + TemplateAssignmentController both import from MarksheetGeneration |
| API RSP no tenancy | ✅ CONFIRMED | api.php registers live routes with `auth:sanctum` only |
| Missing DB column in migration | ✅ NEW (BUG-TMP-03) | `value_type` column missing — engine silently defaults all variables to 'text' type |

---

## Health Score Breakdown

| Dimension | Score | Notes |
|---|---|---|
| Security Posture | 18/35 | SEC-PLATFORM-003 + SEC-TMP-01 (SQL injection) + SEC-TMP-02 (cross-layer schema) + SEC-TMP-03 (uploadImage ungated) |
| Data Integrity | 12/25 | BUG-TMP-03 (value_type missing — core engine broken), BUG-TMP-04 (immutable code overwritable) |
| Code Quality | 14/20 | 10/10 D30; ClassGroup coupling; missing guards; PERF-TMP-01 |
| Gap Coverage | 11/20 | 6 business rule gaps (BR-001/007/008/009/010/017); API no tenancy |
| **Raw Total** | **55/100** | Above other audited modules (prev: 40–50 raw) |
| **P0 Cap Applied** | **40/100** | Hard cap: any P0 present |

**Final Health Score: 40 / 100 — NO-GO**

---

## Fix Priority (Ordered for Sprint)

**Sprint 0 — Immediate (before any deploy):**
1. **BUG-TMP-03** — Add `value_type` migration to `tmp_template_variables`; update FormRequests; update seeders for common image-type variables (student_photo, school_logo). (3h)
2. **GAP-TMP-02** — Implement class group fallback in `TemplateEngine::resolveTemplate()` — query `msh_class_group_items_jnt` for groups containing `$classId`. (2h)
3. **SEC-PLATFORM-003** — Add `EnsureTenantHasModule::class` to RSP::mapWebRoutes(). (15min)
4. **SEC-TMP-02** — Replace `SHOW DATABASES` with current tenant DB name in getDatabases(), create(), edit(). (1h)

**Sprint 1 — High Priority:**
5. **SEC-TMP-01** — Whitelist table/database names in getTables() and getColumns(). (1h)
6. **SEC-TMP-03** — Add Gate::authorize to uploadImage(). (15min)
7. **GAP-TMP-05** — Add is_system guard to TemplatePurposeController::update(). (15min)
8. **BUG-TMP-05** — Add active-assignment check to TemplateController::forceDelete(). (30min)
9. **BUG-TMP-04** — Remove `code` from UpdateTemplateRequest and TemplateController::update() array. (30min)
10. **API-TMP-01** — Add tenancy middleware to RSP::mapApiRoutes() or remove API routes. (30min)

**Sprint 2 — Medium Priority:**
11. **BR-001** — Add variable-count check before activation in toggleStatus(). (1h)
12. **BR-009** — Add `regex:/^[a-z0-9_]+$/` to variable name validation. (15min)
13. **BR-010** — Add cross-field validation for table_name/field_name pair. (30min)
14. **BR-008/016** — Add assignment cascade on template soft-delete. (1h)
15. **GAP-TMP-11** — Add warning log to fetchColumn() default case. (15min)
16. **PERF-TMP-01** — Remove SHOW DATABASES from create/edit view handlers. (30min)
17. **GAP-TMP-08** — Move ClassGroup to SchoolSetup or replace with DB query. (2h)
