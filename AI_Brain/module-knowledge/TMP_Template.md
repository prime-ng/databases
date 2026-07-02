# Module Knowledge — TMP: Template
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | Template |
| Module Code | TMP |
| Table Prefix | `tmp_*` |
| Laravel Module Path | `Modules/Template/` |
| Namespace | `Modules\Template` |
| DB Layer | **Tenant** — tenant_db (no `tenant_id` column; isolated by DB connection via stancl/tenancy) |
| Domain Scope | Tenant — School Admin + Academic Head + system engine callers |
| V2 Requirement | **NONE** — V1 screen specs are the only requirement source (6 files in `Template_v2/`) |
| V1 Screen Specs | 6 files covering all 5 tabs (Overview + 5 tabs) |
| Estimated Completion | ~75–80% — most solid module of the seeded set (confirmed 2026-06-30) |

### Verified File Counts (from `find Modules/Template -type f | sort` — 2026-06-30)

| Component | Count | Notes |
|-----------|-------|-------|
| Controllers | 5 | TemplateController, TemplatePurposeController, TemplateAssignmentController, TemplateTypeController, TemplateVariableController |
| Models | 6 | Template, TemplateAssignment, TemplatePurpose, TemplateType, TemplateVariable, TemplateVariableJnt |
| FormRequests | 10 | Store + Update pair for each of the 5 resources |
| Policies | 5 | All registered in TemplateServiceProvider — TemplatePolicy, TemplateTypePolicy, TemplateVariablePolicy, TemplatePurposePolicy, TemplateAssignmentPolicy |
| Services | 2 | TemplateEngine (canonical; final class), TemplateService (@deprecated wrapper) |
| Contracts | 2 | TemplateEngineInterface, DataProviderInterface |
| Facades | 1 | Template (alias: `Template::render(...)`) |
| Exceptions | 2 | TemplateNotFoundException, TemplateRenderException |
| Seeders | 4 | TemplateDatabaseSeeder, TemplatePurposeSeeder, TemplateTypeSeeder, TemplateVariableSeeder |
| Tests (Unit) | 1 file | TemplateEngineTest — 12 Pest cases covering loop/variable logic |
| Tests (Feature) | 1 file | TemplateMigrationTest — 5 cases verifying table + column existence |
| Tests (HTTP) | 0 | No HTTP/controller tests |
| Views | ~35 | 5×5 CRUD grid (create/edit/list/show/trash per resource), tab-view, 3 partials, layout |

---

## DDL Table Inventory (5 tables — all created 2026-06-16 in tenant_db)

All tables created in a single batch: `2026_06_16_082734` through `2026_06_16_082739`.

| Table | Purpose | SoftDeletes | Key Constraints |
|-------|---------|:-----------:|-----------------|
| `tmp_template_purposes` | Registry of output purposes (MARKSHEET_PRINT, FEE_RECEIPT, etc.) | YES | UNIQUE(`code`); FK → `sys_dropdowns.id` for `scope_type_id` |
| `tmp_templates_type` | Category lookup (MARKSHEET, ID_CARD, FEE_RECEIPT, etc.) | YES | — |
| `tmp_template_variables` | Placeholder master registry (variable = merge field) | YES | UNIQUE(`name`); FK → `tmp_templates_type.id` via `template_type_id` (CASCADE) |
| `tmp_templates` | Visual template designs (canvas JSON + compiled HTML) | YES | UNIQUE(`code`); FK → `tmp_templates_type.id` via `type_id` (SET NULL on delete) |
| `tmp_templates_variables_jnt` | Template ↔ Variable mapping (pivot with position + default) | YES | FK → `tmp_templates.id` (CASCADE); FK → `tmp_template_variables.id` (CASCADE) |
| `tmp_template_assignments` | Scope-based assignment (session × purpose × class/group) | YES | UNIQUE(`scope_hash`) generated column; CHECK `chk_tmp_ta_scope_target` |

### Table Column Summaries

#### `tmp_templates`
| Column | Type | Notes |
|--------|------|-------|
| `code` | varchar(50) | Immutable machine identifier; UNIQUE |
| `name` | varchar(100) | Display label |
| `type_id` | int unsigned NULL | FK → `tmp_templates_type.id` (SET NULL); cast integer |
| `description` | text NULL | Layout scope explanation |
| `canvas_json` | json NULL | Positional coordinates `[{element_id, x, y, width, font}]`; cast array |
| `html_content` | longtext NULL | Compiled HTML/CSS used by PDF generator |
| `background_image` | varchar(255) NULL | Stored path; resolved via `tenant_asset()` at render time |
| `is_active` | tinyint(1) | Draft=0, Active=1; cast boolean |

#### `tmp_template_variables`
| Column | Type | Notes |
|--------|------|-------|
| `template_type_id` | int unsigned | FK → `tmp_templates_type.id`; NOT NULL |
| `name` | varchar(50) | Placeholder name e.g. `student_name`; UNIQUE; `[a-z0-9_]` only |
| `description` | varchar(255) NULL | Tooltip for canvas editor |
| `db_name` | varchar(60) NULL | Source database name (e.g. `tenant_db`) |
| `table_name` | varchar(60) NULL | Source table (e.g. `std_students`) |
| `field_name` | varchar(60) NULL | Source column (e.g. `father_name`) |
| `is_active` | tinyint(1) | cast boolean |

> **Note:** `tmp_template_variables` missing `value_type` column in DDL — but `TemplateEngine::formatVariableValue()` references `$var->value_type` to determine text/html/image rendering. If this column does not exist in the migration, the engine silently defaults to 'text'. Verify if `value_type` was added in a separate migration.

#### `tmp_template_assignments`
| Column | Type | Notes |
|--------|------|-------|
| `template_id` | int unsigned | FK → `tmp_templates.id` (RESTRICT) |
| `purpose_id` | int unsigned | FK → `tmp_template_purposes.id` (RESTRICT) |
| `academic_session_id` | smallint unsigned | FK → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| `class_id` | int unsigned NULL | Optional; FK → `sch_classes.id` |
| `class_group_id` | int unsigned NULL | Optional; FK → `msh_class_groups.id` |
| `scope_hash` | varchar(80) | **Generated column** (UNIQUE) — see scope hash formula below |
| `is_active` | tinyint(1) | cast boolean |

#### `tmp_templates_variables_jnt`
| Column | Type | Notes |
|--------|------|-------|
| `template_id` | int unsigned | FK → `tmp_templates.id` (CASCADE) |
| `variable_id` | int unsigned | FK → `tmp_template_variables.id` (CASCADE) |
| `display_order` | smallint unsigned | Rendering order; default 0 |
| `default_value` | varchar(255) NULL | Fallback when DB returns NULL |
| `is_active` | tinyint(1) | Per-mapping toggle; default 1 |

---

## Architecture: Template Engine

Template is not just a CRUD module — it is a **platform rendering engine** consumed by other modules (MarksheetGeneration, StudentPortal, etc.).

### Rendering Flow

```
Caller → TemplateEngine::render(purpose, data, studentId, classId, sessionId)
    ↓
    1. resolveProviderData() — pulls data from config('template.providers.{purpose}') DataProvider
    2. mergedData = providerData + caller overrides
    3. resolveTemplate(purpose, classId, sessionId) — 3-step fallback hierarchy
    4. renderById(templateId, mergedData, ...)
        a. expandLoopBlocks() — process LOOP:key / ENDLOOP markers
        b. resolveVariables() — resolve @{{varName}} placeholders
            - If in caller's $data: use caller value (escape per value_type)
            - If DB-mapped: fetchColumn() or resolveStudentAlias()
            - Else: use pivot default_value from junction
    5. Return rendered HTML string
```

### Template Resolution Hierarchy (3-Step Fallback)

For a given `$purposeCode + $classId + $sessionId`, the engine tries in order:

| Priority | Condition |
|----------|-----------|
| 1 | Direct session match (`ta.academic_session_id = $sessionId`) + class match (`ta.class_id = $classId`) |
| 2 | Direct session match + school-wide fallback (`ta.class_id IS NULL`) |
| 3 | Joined session fallback via `sch_org_academic_sessions_jnt.academic_session_id = $sessionId` + class match |
| 4 | Joined session fallback + school-wide |
| 5 | No session constraint + class match (`ta.academic_session_id IS NULL`) |
| 6 | No session constraint + school-wide fallback |
| FAIL | `TemplateNotFoundException::forPurpose($purposeCode)` |

> The engine does NOT implement class group fallback via `msh_class_groups` — only direct class or school-wide. V1 spec describes group fallback (Class Group priority step) but the TemplateEngine code resolves class→school only. Class group assignment rows exist in the DB but the engine doesn't query them.

### Scope Hash Formula (tmp_template_assignments)

```sql
CONCAT(purpose_id, ':', academic_session_id, ':', COALESCE(CONCAT('C', class_id), CONCAT('G', class_group_id), 'SCHOOL'))
```

Examples:
- Direct class: `3:5:C10` (purpose 3, session 5, class 10)
- Class group: `3:5:G2` (purpose 3, session 5, group 2)
- School-wide: `3:5:SCHOOL`

DB CHECK constraint `chk_tmp_ta_scope_target` enforces: `class_id` and `class_group_id` cannot both be non-NULL.

### DataProvider Pattern

External modules can register data providers for specific template purposes:

```php
// Central config/template.php
return [
    'providers' => [
        'MARKSHEET_PRINT' => \Modules\MarksheetGeneration\Services\MarksheetDataProvider::class,
    ],
];
```

Providers implement `DataProviderInterface::provide(array $context): array`. The engine calls the provider, then merges with the caller's explicit `$data` overrides (caller wins on key collision).

### Variable Value Types

| Type | Engine Behavior |
|------|----------------|
| `text` | HTML-escaped via `e()` — safe default |
| `html` | **Trusted pass-through** — not escaped (XSS risk if variable source is untrusted) |
| `image` | Wrapped in `<img src="..." alt="..." class="tpl-img tpl-img-{name}">` |

### Loop Block Syntax

```html
<!-- LOOP: subjects -->
  <tr><td>@{{subject_name}}</td><td>@{{marks}}</td></tr>
<!-- ENDLOOP -->
```

Data must be keyed by loop name and be a list array. Missing/empty loop data → block rendered as empty string (no error).

### Legacy Marker Translation

Old template HTML using non-standard markers is translated before loop expansion:

| Legacy Marker | Translates To |
|--------------|--------------|
| `<!-- SUBJECT_TABLE_START -->` | `<!-- LOOP: subjects -->` |
| `<!-- SUBJECT_TABLE_END -->` | `<!-- ENDLOOP -->` |
| `<!-- EXAM_COLUMNS_START -->` | `<!-- LOOP: exam_columns -->` |
| `<!-- EXAM_COLUMNS_END -->` | `<!-- ENDLOOP -->` |
| `<!-- COSCHO_TABLE_START -->` | `<!-- LOOP: coscho_rows -->` |
| `<!-- COSCHO_TABLE_END -->` | `<!-- ENDLOOP -->` |

### DB Auto-Resolution — Supported Tables

The engine's `fetchColumn()` knows these tables for automated variable resolution:

| Source Table | Context Required | Typical Use |
|-------------|-----------------|-------------|
| `std_students` | `$studentId` | student_name, admission_no, dob, gender |
| `std_student_academic_sessions` | `$studentId` | roll_no, section |
| `std_student_profiles` | `$studentId` | photo path, father_name, mother_name |
| `sch_classes` | `$classId` | class_name, class_code |
| `sch_organizations` | — (latest) | school_name, logo |
| `sch_org_academic_sessions_jnt` | — (is_current=1 or latest) | session_name, start_date, end_date |
| `hrs_employees` | `$employeeId` | teacher_name, designation |

Any other `table_name` on a variable returns NULL (silent failure — no exception).

---

## Feature Area Status (as of 2026-06-30)

| # | Feature Area | Status | Notes |
|---|-------------|--------|-------|
| 1 | Template Types CRUD | ✅ 85% | Full CRUD + trash/restore/forceDelete + toggleStatus; views complete |
| 2 | Template Purposes CRUD | ✅ 85% | Full CRUD + system-protected guard + scope_type_id from sys_dropdowns; views complete |
| 3 | Template Variables CRUD | ✅ 80% | Full CRUD; getDatabases/getTables/getColumns introspection endpoints present — security exposure |
| 4 | Template Designer CRUD | ✅ 80% | Canvas JSON, html_content, background upload, variable picker; schema/preview endpoints |
| 5 | Template Assignments CRUD | ✅ 80% | scope_hash, CHECK constraint, session/class/group targeting all implemented |
| 6 | TemplateEngine — Core Render | ✅ 90% | Loop expansion, legacy markers, variable types, DB resolution all implemented |
| 7 | TemplateEngine — Provider Pattern | ✅ 85% | DataProviderInterface + config('template.providers') integration; 12 unit tests cover it |
| 8 | PDF Generation | ✅ 80% | `toPdf()` via `barryvdh/dompdf` — Facade::`Pdf::loadHTML()` |
| 9 | Class Group Fallback Resolution | ❌ 0% | V1 spec defines 3-step fallback (Class → Group → School); TemplateEngine only implements Class → School (skips group) |
| 10 | EnsureTenantHasModule | ❌ 0% | Not applied to any route; P0 gap — consistent with platform-wide missing pattern |
| 11 | HTTP / Controller Tests | ❌ 0% | No HTTP tests; 12 unit + 5 migration tests only |
| 12 | Rate Limiting | ❌ 0% | No rate limiting on any route |

---

## Known Gaps & Open Issues

### P0 — Critical

| ID | Issue | Location |
|----|-------|---------|
| GAP-TMP-01 | `EnsureTenantHasModule` middleware missing from all routes — any authenticated tenant user can access Template routes even if their school hasn't subscribed to the module | `routes/web.php` |
| GAP-TMP-02 | Class group fallback NOT implemented in TemplateEngine — V1 spec says the fallback chain is Class → ClassGroup → School; actual code only does Class → School; class group assignments in the DB are never matched by the engine | `TemplateEngine.php:resolveTemplate()` lines 120-164 |

### P1 — High

| ID | Issue | Location |
|----|-------|---------|
| BUG-TMP-03 | `value_type` column referenced in `TemplateEngine::formatVariableValue()` may not exist on `tmp_template_variables` migration (migration defines: template_type_id, name, description, db_name, table_name, field_name, is_active — no `value_type`). If missing, every variable silently falls to 'text' type even if html/image intended | `TemplateEngine.php:233`; migration `2026_06_16_082736` |
| GAP-TMP-04 | `TemplateVariableController::getDatabases/getTables/getColumns` expose live DB schema introspection to any authorized tenant user — these endpoints can be used to enumerate table structure across the tenant database | `TemplateVariableController.php` |
| GAP-TMP-05 | `html` value type in variable engine is trusted pass-through — any HTML injected into a template variable marked as `html` type (from `std_students` or other DB-resolved fields) is rendered unescaped. Risk if user-controlled data is stored in those fields | `TemplateEngine.php:264` |
| GAP-TMP-06 | `TemplateService` is marked `@deprecated` but no audit has been done to identify and migrate external callers — unknown breakage risk if deleted | `TemplateService.php` |

### P2 — Medium

| ID | Issue | Location |
|----|-------|---------|
| GAP-TMP-07 | Module `config/config.php` contains only `['name' => 'Template']` — the `providers` map is expected in `config/template.php` (central config). If this file doesn't exist, `config('template.providers')` returns `[]` and ALL provider-based purpose rendering silently returns empty data | `Modules/Template/config/config.php`; `TemplateEngine.php:45` |
| GAP-TMP-08 | `TemplateAssignment` imports `Modules\MarksheetGeneration\Models\ClassGroup` directly — creates a tight dependency between Template (generic engine) and MarksheetGeneration (specific consumer); Template cannot be loaded without MarksheetGeneration being present | `TemplateAssignment.php:16` |
| GAP-TMP-09 | `img_content` format: `style="width: 100%%; height: 100%%;"` — double `%%` is a printf artifact; the CSS is valid in a plain string context but would break if string is ever processed through printf/sprintf | `TemplateEngine.php:271` |
| GAP-TMP-10 | `tmp_template_variables.name` has UNIQUE DB index but the FormRequest for variable creation may not enforce `unique:tmp_template_variables,name` — duplicate names could fail with a raw DB integrity error rather than a user-friendly validation message | `StoreTemplateVariableRequest.php` (unverified) |
| GAP-TMP-11 | `TemplateEngine::fetchColumn()` on unknown table returns `null` silently — a misconfigured variable mapping (e.g., typo in table_name) fails silently rather than logging a warning; leads to blank placeholders in PDF without any error | `TemplateEngine.php:282-315` |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-TMP-12 | No rate limiting on any Template route — especially `/template/{template}/preview-sample` which triggers DB resolution |
| GAP-TMP-13 | Zero HTTP feature tests — no coverage for assignment scope conflict, system-protected purpose guard, or template activation-without-variables rule |
| GAP-TMP-14 | Seeded purposes (`MARKSHEET_PRINT`, `STUDENT_ID_CARD`, `TRANSFER_CERT`, `CHARACTER_CERT`, `ADMIT_CARD`, `FEE_RECEIPT`) are marked `is_system=1`; controller must enforce system-protection guard before update/delete — not verified in code |
| GAP-TMP-15 | TemplatePurposeController toggleStatus endpoint doesn't currently check whether in-use active assignments exist before deactivating purpose |
| GAP-TMP-16 | `tmp_template_purposes.scope_type_id` FK to `sys_dropdowns` creates a CROSS-MODULE hard dependency on SYS DropdownsSeeder being run first — Template seeder order must come AFTER SYS seeders |
| GAP-TMP-17 | Background image files stored at `storage/tenant_{id}/templates/backgrounds/` but soft-deleted template records retain the file path — no file cleanup on hard delete |

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| TemplateEngine is `final` singleton | Stateless — safe to bind as singleton across the request; `final` prevents inheritance abuse | ServiceProvider |
| Caller data overrides provider data | When both provider and caller pass a key, caller value wins (`array_merge($providerData, $data)`) | TemplateEngine:35 |
| Scope hash as generated column | UNIQUE constraint on `scope_hash` (computed from purpose+session+scope target) enforces one active assignment per scope at DB level — no application-level duplicate check needed | Migration `082738` |
| CHECK constraint on scope target | `chk_tmp_ta_scope_target` — class_id and class_group_id mutually exclusive at DB level; backend FormRequest must also validate | Migration `082738` |
| Purpose scope_type from sys_dropdowns | `tmp_template_purposes.scope_type_id` FK to `sys_dropdowns` (not enum) — allows future scope types without schema change | V1 spec 03 |
| `is_system=1` for seeded purposes | Seeded purposes cannot have code or scope_type changed; delete blocked | V1 spec 03 Business Logic |
| Template must have ≥1 variable before activation | `is_active = 1` requires at least one `tmp_templates_variables_jnt` row — enforced at application level | V1 spec 01 BR |
| Hard delete of template blocked if active assignments exist | Soft-delete on template cascades `is_active=0` on related assignments | V1 spec 01 BR |
| Variable deletion cascades junction | FK `fk_tmp_tvj_variable` ON DELETE CASCADE removes all junction rows when variable deleted | Migration `082739` |
| `@{{varName}}` syntax for placeholders | Both `{{varName}}` and `@{{varName}}` matched by `VAR_PATTERN` regex — Blade-syntax compatibility | TemplateEngine:24 |
| TemplateService @deprecated | Wrapper maintained for backward compat; new callers must inject `TemplateEngineInterface` directly | TemplateService:16 |
| Central config/template.php for providers | Each consuming module registers its DataProvider in central `config/template.php` (not in module config) — allows Template module to remain decoupled from consumers | TemplateServiceProvider:58 |

---

## Permission Architecture

### Current State — Consistent (all registered)

| Resource | Policy Class | Permission Prefix | Registered? |
|----------|-------------|------------------|:-----------:|
| Template | TemplatePolicy | `tenant.template.*` | ✅ |
| TemplateType | TemplateTypePolicy | `tenant.template-type.*` (assumed) | ✅ |
| TemplateVariable | TemplateVariablePolicy | `tenant.template-variable.*` (assumed) | ✅ |
| TemplatePurpose | TemplatePurposePolicy | `tenant.template-purpose.*` (assumed) | ✅ |
| TemplateAssignment | TemplateAssignmentPolicy | `tenant.template-assignment.*` (assumed) | ✅ |

> Policies registered in `TemplateServiceProvider::registerPolicies()` — all 5 are wired. This is one of the only modules with complete policy registration. Permission prefixes for TypePolicy, VariablePolicy, PurposePolicy, AssignmentPolicy were not individually read — verify they're consistent with their controllers' Gate::authorize() calls.

### Confirmed Permission Set (from TemplatePolicy)

| Method | Permission |
|--------|-----------|
| viewAny | `tenant.template.viewAny` |
| view | `tenant.template.view` |
| status | `tenant.template.view` |
| create | `tenant.template.create` |
| update | `tenant.template.update` |
| delete | `tenant.template.delete` |
| restore | `tenant.template.restore` |
| forceDelete | `tenant.template.forceDelete` |

---

## Cross-Module Dependencies

### TMP Consumes From

| Source Module | Import | Purpose |
|--------------|--------|---------|
| SchoolSetup | `OrganizationAcademicSession` | Academic session FK on assignments |
| SchoolSetup | `SchoolClass` | Class FK on assignments |
| SchoolSetup | `User` | Policy user type |
| MarksheetGeneration | `ClassGroup` | Class group FK on assignments — hard coupling |
| SystemConfig | `sys_dropdowns` | `tmp_template_purposes.scope_type_id` FK — requires SYS DropdownsSeeder |
| barryvdh/dompdf | DomPDF facade | PDF generation via `toPdf()` |

### TMP Provides To (Platform-Wide Impact)

| Consumer | Mechanism | What TMP Provides |
|----------|-----------|-------------------|
| MarksheetGeneration | `TemplateEngineInterface::render('MARKSHEET_PRINT', ...)` | Rendered HTML / PDF for marksheet printing |
| Certificate module (CRT) | `TemplateEngine::render('TRANSFER_CERT', ...)` | Certificate layout rendering |
| StudentFee (FIN) | `TemplateEngine::render('FEE_RECEIPT', ...)` | Fee receipt layout |
| StudentProfile (STD) | `TemplateEngine::render('STUDENT_ID_CARD', ...)` | ID card rendering |
| LmsExam (EXM) | `TemplateEngine::render('ADMIT_CARD', ...)` | Exam admit card rendering |
| Any future consumer | Implement `DataProviderInterface`; register in `config/template.php` | Generic layout engine |

---

## Route Inventory

All routes in `Modules/Template/routes/web.php` (routes are PROPERLY defined in the module — unlike SYS):

| Route | Controller | Method |
|-------|-----------|--------|
| GET `/templates-tabs` | TemplateController@tabView | Tab dashboard |
| Resource `/template` | TemplateController | Full CRUD |
| GET `/templates/{id}/restore` | TemplateController@restore | Trash restore |
| DELETE `/templates/{id}/force-delete` | TemplateController@forceDelete | Hard delete |
| POST `/templates/{id}/toggle-status` | TemplateController@toggleStatus | Active toggle |
| GET `/templates-trash` | TemplateController@trashed | Trash list |
| POST `/template/upload-image` | TemplateController@uploadImage | Background image upload |
| GET `/template/{template}/schema` | TemplateController@schema | Variable schema for picker |
| GET `/template/{template}/preview-sample` | TemplateController@previewSample | Sample preview |
| Resource `/purposes` | TemplatePurposeController | Full CRUD |
| + restore/force-delete/toggle-status/trash | TemplatePurposeController | Full lifecycle |
| Resource `/assignments` | TemplateAssignmentController | Full CRUD |
| + restore/force-delete/toggle-status/trash | TemplateAssignmentController | Full lifecycle |
| Resource `/template-types` | TemplateTypeController | Full CRUD |
| + restore/force-delete/toggle-status/trash | TemplateTypeController | Full lifecycle |
| Resource `/template-variables` | TemplateVariableController | Full CRUD |
| GET `/template-variables-get-databases` | TemplateVariableController@getDatabases | DB schema introspection |
| GET `/template-variables-get-tables` | TemplateVariableController@getTables | DB schema introspection |
| GET `/template-variables-get-columns` | TemplateVariableController@getColumns | DB schema introspection |
| + restore/force-delete/toggle-status/trash | TemplateVariableController | Full lifecycle |

---

## V1 Screen Spec Inventory (6 files)

| File | Screen / Topic |
|------|---------------|
| `00-Module-Overview.md` | Architecture, resolution workflow, resolution priority chain, variable modes, actor matrix, tab directory |
| `01-Template-Templates.md` | Canvas designer CRUD: tmp_templates + tmp_templates_variables_jnt schema, field rules, business logic, test scenarios, Dusk tests |
| `02-Template-Template_Types.md` | Type category CRUD: tmp_templates_type schema |
| `03-Template-Template_Purposes.md` | Purpose registry CRUD: tmp_template_purposes schema, scope types (CLASS_SCOPED/SCHOOL_WIDE), system-protected guard |
| `04-Template-Template_Variables.md` | Variable placeholder CRUD: tmp_template_variables schema, Automated vs Manual mode, partial-mapping validation |
| `05-Template-Template_Assignments.md` | Scope assignment CRUD: tmp_template_assignments schema, scope_hash formula, CHECK constraint, purpose-type compatibility |

---

## Seeder Notes

| Seeder | Populates | Dependency |
|--------|-----------|-----------|
| `TemplatePurposeSeeder` | Seeded purposes: `MARKSHEET_PRINT`, `STUDENT_ID_CARD`, `TRANSFER_CERT`, `CHARACTER_CERT`, `ADMIT_CARD`, `FEE_RECEIPT` (all `is_system=1`) | Requires `sys_dropdowns` seeded with `tmp_template_purposes.scope_type_id` values |
| `TemplateTypeSeeder` | Seeded types: MARKSHEET, ID_CARD, FEE_RECEIPT, ADMIT_CARD, CERTIFICATE | None |
| `TemplateVariableSeeder` | Common variables (student_name, roll_no, school_name, etc.) | Requires TemplateTypeSeeder run first |
| `TemplateDatabaseSeeder` | Orchestrator — calls the 3 above in order | |

**Seeder run order:** SYS DropdownsSeeder → TMP TemplateDatabaseSeeder

---

## Test Coverage Summary

### Unit: `TemplateEngineTest` (12 cases — all pass)
- Engine instantiation
- Legacy marker translation (SUBJECT_TABLE, EXAM_COLUMNS, COSCHO_TABLE)
- Loop block expansion (single, multiple, empty/missing)
- Legacy marker + loop expand integration
- `formatVariableValue`: image wrapping, empty image, text escape, html pass-through
- `resolveProviderData`: with registered provider, without registered provider

### Feature: `TemplateMigrationTest` (5 cases)
- All 6 tmp_* tables exist
- `tmp_templates` has `code` and `type_id` columns (not stale `type`/`variables`)
- `tmp_template_variables` has `template_type_id`
- `tmp_templates_variables_jnt` has required pivot columns
- `tmp_template_assignments` has `scope_hash` column

**Missing test coverage:**
- HTTP: controller auth, CRUD lifecycle, scope hash conflict rejection
- System-protected purpose guard (update/delete blocked for is_system=1)
- Template activation validation (must have ≥1 variable)
- Hard delete blocked when active assignments exist
- Background image upload (type validation, size limit, storage path)
- TemplateEngine full render integration (resolveTemplate fallback chain)

---

## Lessons Learned

- [2026-06-30 | Business Analyst] Template has **no V2 requirement file** — V1 screen specs in `Template_v2/` are the only spec source. This is unusual; all other seeded modules had a V2. The V1 specs are well-detailed (schema + field rules + business logic + Dusk test templates for each screen).
- [2026-06-30 | Business Analyst] Template is a **platform rendering engine first, CRUD module second**. The critical value is `TemplateEngine` consumed by other modules (MSH, CRT, FIN, STD). When auditing or fixing TMP, prioritize engine correctness over CRUD completeness.
- [2026-06-30 | Business Analyst] The class-group fallback (V1 spec priority 2) is **NOT implemented** in `TemplateEngine::resolveTemplate()`. Assignments with `class_group_id` exist in the DB but the engine only looks for direct `class_id` match and school-wide fallback. This means class-group-scoped templates are assigned via UI but never resolved at render time. This is P0 functional gap.
- [2026-06-30 | Business Analyst] `TemplateAssignment` model imports `Modules\MarksheetGeneration\Models\ClassGroup` — a hard coupling from a generic engine to a specific consumer. This violates layering. `ClassGroup` should live in SchoolSetup or a shared module, not MarksheetGeneration.
- [2026-06-30 | Business Analyst] Config split pattern: module `config/config.php` contains only `['name' => 'Template']`; consumer-registered DataProviders must be in central `config/template.php`. If deploying without MSH, `config/template.php` won't exist → all purpose rendering silently returns empty data. Always check `config/template.php` exists before Template rendering works.
- [2026-06-30 | Business Analyst] TemplateEngine's `formatVariableValue()` references `$var->value_type` but this column does NOT appear in the migration file `2026_06_16_082736`. Either: (a) a separate migration added it later, or (b) the engine silently defaults because `$var->value_type` returns null → 'text'. Needs verification.

---

## FRD Summary

| Attribute | Value |
|-----------|-------|
| FRD File | `0-FRD_Documents/TMP_FRD_2026-06-30.md` |
| Complete Pack | `0-FRD_Documents/TMP_FRD_Complete_2026-06-30.md` |
| Conditions Catalog | `5-Requirement_Conditions/TMP_Conditions.md` |
| Date Produced | 2026-06-30 |
| REQ Count | 12 (P0: 9, P1: 3, P2: 0) |
| BR Count | 21 (DONE: 4, PARTIAL: 6, NOT ENFORCED: 5, NOT VERIFIED: 6) |
| Workflow Count | 7 |
| RPT Count | 1 |
| ENH Count | 6 |
| User Stories | 12 (one per P0/P1 REQ, with Gherkin AC) |
| Sprint Tasks | 31 tasks, ~68 h total gap effort across 3 sprints |
| Estimated Completion after Sprints | ~95% |

**P0 critical gaps confirmed by analysis:**
- BR-001: activation guard (≥1 variable) missing from FormRequest + controller
- BR-007: TemplatePurposeController.update() not guarded for is_system code/scope_type changes
- BR-008/BR-016: soft-delete cascade to assignments NOT implemented (purpose delete, template delete)
- BR-009: variable name format [a-z0-9_] not validated in FormRequest
- BR-010: partial mapping cross-field validation missing from StoreTemplateVariableRequest
- BR-015 Step 2: class group fallback NOT implemented in TemplateEngine::resolveTemplate()
- BR-017: TemplateController.forceDelete does not check for active assignments before deleting
- NFR-TMP-S-005: EnsureTenantHasModule missing from all routes

---

## Pending Next Steps

1. **P0 — Add `EnsureTenantHasModule`** to `routes/web.php` prefix group
2. **P0 — Implement class group fallback** in `TemplateEngine::resolveTemplate()` step between Direct Class Match and School-Wide Fallback — query `msh_class_group_items_jnt` to get all groups containing `$classId`, then match assignments
3. **P1 — Verify `value_type` column** — run `Schema::hasColumn('tmp_template_variables', 'value_type')` in TemplateMigrationTest; add migration if missing
4. **P1 — Audit DB introspection endpoints** (getDatabases/getTables/getColumns) — add authorization gate; consider restricting to Super Admin only
5. **P1 — Migrate callers off TemplateService** — grep codebase for `TemplateService`; replace with `TemplateEngineInterface` injection; remove deprecated class
6. **P2 — Move ClassGroup import** — resolve MarksheetGeneration coupling; move `ClassGroup` to SchoolSetup or replace with plain DB query
7. **P2 — Add `config/template.php`** template file to application config with stub `providers: []` — prevents silent failure
8. **Test priority** — `TemplatePurposeSystemProtectionTest`, `TemplateActivationValidationTest`, `TemplateAssignmentScopeHashTest`, `TemplateEngineResolutionIntegrationTest`

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V1 screen specs (6 files) + full Laravel module filesystem + migration-derived DDL + TemplateEngine deep-read |
| 1.1 | 2026-06-30 | Business Analyst | Complete Analysis Pack produced — FRD + RTM + BRs + Conditions + Flows + FSM + Data Dict + Dependencies + NFR + Risk + Sprint Tasks + 12 User Stories + Feature Spec. 8 P0 gaps confirmed. |
| 1.2 | 2026-06-30 | Technical Auditor | Mode X Complete Audit — 3 P0 confirmed, 7 P1 found (3 new), 2 BA gaps cleared, 2 new stale BA corrections applied. Health 40/100 NO-GO. |

---

## Mode X Audit Lessons Learned (2026-06-30)

### Stale BA Knowledge — CLEARED
- **GAP-TMP-07 CLEARED** — `config/template.php` confirmed present with 3 registered providers: `MARKSHEET_PRINT` → `MarksheetDataProvider`, `STUDENT_ID_CARD` → `StudentIdCardDataProvider`, `TRANSPORT_STAFF_ID_CARD` → `TransportStaffIdCardDataProvider`. Facade and provider system fully wired.
- **GAP-TMP-10 CLEARED** — `StoreTemplateVariableRequest` has `Rule::unique('tmp_template_variables')->where('template_type_id', $this->input('template_type_id'))` — compound unique correctly enforced in FormRequest validation layer.

### P0 Findings — Confirmed by Live Code

**BUG-TMP-03 — `value_type` column MISSING from migration (P0)**
- Migration `2026_06_16_082736_create_tmp_template_variables_table.php` columns: `id, name, description, db_name, table_name, field_name, is_active, created_at, updated_at, template_type_id, deleted_at`. No `value_type` column.
- Exhaustive grep across all tenant migrations confirms NO subsequent migration adds this column.
- `TemplateEngine::resolveVariables()` line 237 casts `(string) ($var->value_type ?? 'text')` — always resolves to 'text' via the null coalesce.
- `formatVariableValue()` branches for `image` (→ `<img src="...">`) and `html` (→ trusted `{$value}` pass-through) are permanently unreachable. All variable rendering silently degrades to text, regardless of configuration intent.
- **Impact:** ALL image variables (e.g., student photo on ID cards and marksheets) render as raw URLs/text instead of `<img>` tags. ALL HTML-type variables render escaped, breaking formatted content blocks.

**GAP-TMP-02 — class_group_id fallback absent from resolveTemplate() (P0)**
- `TemplateEngine::resolveTemplate()` performs 6-step fallback (lines 120–165). Steps query: `ta.class_id` and `ta.academic_session_id` only.
- No step ever queries `ta.class_group_id`. `TemplateAssignment` model has `class_group_id` fillable and `TemplateAssignment::store()` accepts `class_group_id` input.
- Schools can create group-scoped assignments via the UI, but the engine never finds them — falls through all 6 steps and throws `TemplateNotFoundException`.
- **Fix needed:** Add a step between step 2 (class-level match) and step 3 (purpose-only match) that queries `ta.class_group_id = :class_group_id AND ta.academic_session_id = :session_id`.

**SEC-PLATFORM-003 — EnsureTenantHasModule absent (P0)**
- `RouteServiceProvider::mapWebRoutes()` middleware: `['web', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class, EnsureTenantIsActive::class, 'auth', 'verified']`
- `EnsureTenantHasModule` not present. Confirmed platform-wide P0 (13/13 tenant modules).

### New Security Findings (P1)

**SEC-TMP-01 — SQL injection in DB introspection endpoints**
- `getTables()` line 227: `DB::connection('tenant_mysql')->select("SHOW TABLES FROM \`{$dbName}\`")` — `$dbName` is raw `$request->db_name` with no sanitization. Backtick quoting does not prevent all injection.
- `getColumns()` line 247: same pattern with both `$dbName` and `$tableName`.
- Methods are gated (`Gate::authorize('tenant.template.variable.create')`) but school admins who have this permission can enumerate/probe via injection.
- **Fix:** Validate `$dbName` and `$tableName` against whitelist of known DB names from SHOW DATABASES result, or use parameterized queries where possible.

**SEC-TMP-02 — getDatabases() exposes cross-tenant schema**
- `getDatabases()` returns `DB::select('SHOW DATABASES')` result directly — all databases visible to the MySQL connection: `prime_db`, `global_master_mysql`, all `tenant_*` databases.
- Also called unconditionally on every `create()` and `edit()` page load — leaks DB names to any user who opens the variable creation form.
- **Fix:** Filter result to only current tenant's database, or hardcode to current tenant connection DB name.

**SEC-TMP-03 — uploadImage() no Gate::authorize**
- `TemplateController::uploadImage()` (line 408) validates file MIME/size but has no `Gate::authorize()` call. Any authenticated user can upload images.
- All other TemplateController methods are properly gated.

### New Functional Findings (P1)

**BUG-TMP-04 — Template code field is updatable**
- `UpdateTemplateRequest` includes `code` field with `unique:tmp_templates,code,{id}` validation rule.
- `TemplateController::update()` passes `$validated['code']` to the update array.
- Template code is documented as immutable (BR-TMP-003) and used as a stable reference key by consuming modules (MSH, STD, FIN).
- **Fix:** Remove `code` from `UpdateTemplateRequest` rules and from the update array in the controller.

**GAP-TMP-05 — TemplatePurposeController::update() missing is_system guard**
- `destroy()` line 116 checks `$purpose->is_system` ✅. `forceDelete()` line 191 checks `$purpose->is_system` ✅.
- `update()` lines 91–99: no `is_system` check. System purposes (MARKSHEET, IDCARD, etc.) can have their name/description/is_active modified.
- **Fix:** Add `abort_if($purpose->is_system, 403, 'System purposes cannot be modified.')` to update().

**BUG-TMP-05 — forceDelete() no active-assignment check**
- `TemplateController::forceDelete()` (line 463): calls `$template->forceDelete()` with no check for existing `TemplateAssignment` records.
- BR-017 states templates with active assignments cannot be permanently deleted.
- **Fix:** Add check `abort_if($template->assignments()->exists(), 422, 'Cannot permanently delete a template with active assignments.')`.

### Verified Good Items (ABOVE BASELINE)
- **5 policies, zero duplicate kills** — unlike EXM (13× Gate::policy overwrite), TTF (19/23 dead), SLB (2 dead), QUZ (1 dead). `registerPolicies()` in TemplateServiceProvider registers all 5 cleanly.
- **Consistent `tenant.template.*` prefix** — all 5 controllers and all 5 policies use matching `tenant.template.{resource}.{action}` strings. Zero prefix-split issue (unlike SYS, STT, TTF).
- **TemplateAssignmentController transaction pattern** — `store()` and `update()` both use `DB::beginTransaction()` with try/catch/rollback and user-friendly duplicate detection (catching `QueryException` for unique violations).
- **TemplateTypeController protective guards** — `destroy()` checks `templates()->exists()` before soft-delete; `forceDelete()` checks `withTrashed()->exists()` before permanent delete. Reference integrity enforced at controller layer.
- **TemplateEngine escaping** — text variable type uses `e()` (Blade/HTML escape). Only `html` type uses trusted pass-through. Image type constructs `<img>` safely. No stored XSS risk in the engine itself (though SEC-TMP-02 exposes DB names).
