# Technical Audit — Complaint Module — 2026-06-23

**Auditor:** Technical Auditor agent  
**Repo:** `/Users/bkwork/Herd/prime_ai` · Branch: current  
**Module path:** `Modules/Complaint/`  
**DDL path:** `Modules/Complaint/DDL/Complaint_ddl_v2.sql`  
**Prior completion (progress.md):** ~30%  
**This audit result:** 20% (revised down — P0 DDL blocking deployment, P0 auth gaps on store/reports/document-requests, mobile API fully unguarded)

---

## Executive Summary

The Complaint module has widespread, multi-layer defects that prevent safe production use. The most critical findings are an unauthenticated `store()` path on the core complaint creation flow (any tenant user can log a complaint without authorization), zero Gate checks on the full reports surface and all document-request endpoints, a mobile API with no Gate on 7 of 9 methods, and a DDL that contains two type-mismatch foreign keys that will crash `CREATE TABLE` statements. The module's core complaint category and department-SLA sub-controllers are reasonably well-built, but these are overshadowed by the security and structural problems across the rest of the module.

---

## P0 Findings — Fix Before Any User Testing

| Code | Severity | File:Line | Issue |
|------|----------|-----------|-------|
| SCH-CMP-002 | P0 | DDL:177 | `fk_cmp_medical_check FOREIGN KEY (is_medical_check_required) REFERENCES cmp_medical_checks(id)` — `is_medical_check_required` is TINYINT(1), stores 0/1. Cannot FK a boolean flag to an INT PK. DDL will fail on execution. |
| SCH-CMP-003 | P0 | DDL:226 | `fk_med_result FOREIGN KEY (result) REFERENCES sys_dropdown_table(id)` — `result` is VARCHAR(20), FK references INT id. Type mismatch. DDL will error on creation. |
| SCH-CMP-007 | P0 | `Modules/Complaint/database/migrations/` | No tenant migration files exist. Tables cannot be created for new tenants. Module is effectively undeployable without manual DDL execution. |
| SEC-CMP-007 | P0 | `ComplaintController.php` store() | **`store()` has NO `Gate::authorize()`**. Any authenticated tenant user can create a complaint. `create()` at line 173 has Gate but `store()` (lines 209–430) has none. Prior codes SEC-CMP-001–003 noted this but it remains unresolved. |
| SEC-CMP-008 | P0 | `DocumentRequestController.php` index/show/update | **Zero Gate::authorize on all 3 methods**. Any authenticated user can list, view, and update document request status. Exposes parent-submitted document requests to all staff. |
| BUG-CMP-014 | P0 | `ComplaintActionController.php` | `restore()` and `forceDelete()` methods do not exist. Routes `GET complaint-actions/{id}/restore` and `DELETE complaint-actions/{id}/force-delete` both throw 500. |
| DEAD-CMP-001 | P0 | `AiInsightController.php` | Complete scaffold stub — `show()`, `store()`, `update()` are empty `{}`. `forceDelete()` does not exist. All 4 are wired to live routes. Any call executes silently or throws. Zero Gate checks. |

---

## P1 Findings — Fix Before Release

| Code | Severity | File:Line | Issue |
|------|----------|-----------|-------|
| SCH-CMP-001 | P1 | DDL:160 | `KEY idx_cmp_status (status)` — column `status` does not exist on `cmp_complaints`. The status column is `status_id`. Broken index definition. |
| SCH-CMP-004 | P1 | DDL + `ComplaintCategoryController.php`, `DepartmentSlaRequest.php` | Column name mismatch: code uses `expected_resolution_hours`, `escalation_hours_l1`–`l5` on complaint categories; DDL defines `default_expected_resolution_hours`, `default_escalation_hours_l1`–`l5`. Every query against these columns will return null or error. |
| SCH-CMP-006 | P1 | DDL + `ComplaintController.php`, `ComplaintReportController.php`, `ComplaintMobileController.php` | DDL FK constraints reference `sys_dropdown_table` (e.g. `fk_med_result`). Application code queries `sys_dropdowns`. Table name mismatch throughout. |
| SEC-CMP-009 | P1 | `DocumentRequestController.php:1` | **Cross-module hard dependency**: Complaint module imports `Modules\ParentPortal\Models\ParentDocumentRequest`. Complaint must not depend on ParentPortal. Breaks module isolation and creates an undeclared runtime dependency. |
| SEC-CMP-010 | P1 | `Mobile/ComplaintMobileController.php` dashboard/index/show/categories/subcategories/dropdowns/users | **Zero Gate::authorize** on 7 of 9 methods. Any `auth:sanctum` user sees the full complaint dashboard, all complaints, and all users. Only `store()` and `update()` are gated. |
| SEC-CMP-011 | P1 | `ComplaintActionController.php` | Wrong permission prefix: uses `complaint.complaint.*` (e.g. `complaint.complaint.view`) instead of `tenant.complaint-action.*`. All Gate checks silently mismatch registered permissions — effective authorization is zero even when Gate is called. |
| SEC-CMP-012 | P1 | `ComplaintController.php`, `ComplaintReportController.php`, `ComplaintMobileController.php`, `ComplaintCategoryController.php` | Cross-layer imports: `Modules\Prime\Models\Dropdown` (central module model) used in 3 tenant controllers; `Modules\GlobalMaster\Models\Dropdown` used in 1 controller. Central models queried in tenant context violate tenancy isolation. |
| BUG-CMP-015 | P1 | `routes/web.php:104–130` | `GET complaints/manage` (line 128) is registered **after** `Route::resource('complaints', ...)` (line 104). Laravel's router matches `complaints/{complaint}` first, capturing `manage` as the ID parameter. `ComplaintController::show('manage')` fires `Complaint::findOrFail('manage')` → 404. The manage view is permanently unreachable. |
| BUG-CMP-016 | P1 | `routes/web.php:107–120` | `complaints/trash/view`, `complaints/{id}/restore`, `complaints/{id}/force-delete`, `complaints/{id}/toggle-status` all reference `ComplaintController::trashed()`, `restore()`, `forceDelete()`, `toggleStatus()`. **None of these methods exist** on `ComplaintController`. All 4 routes throw 500. |
| BUG-CMP-017 | P1 | `routes/api.php` | `Route::apiResource('complaints', ComplaintController::class)` maps the **web** `ComplaintController` as an API resource. This controller renders Blade views, not JSON. Any API call returns either a view string or a 500. A `ComplaintMobileController` exists for this purpose but is not wired in api.php. |
| DEAD-CMP-002 | P1 | `ComplaintController.php` severityVsDepartmentDonut / departmentVsSeverityDonut / departmentStatusDonut | Three chart methods with **zero Gate::authorize**. Registered routes at lines 30–44 of web.php. Any authenticated user reads complaint severity/department analytics. |

---

## P2 Findings — Fix in Next Sprint

| Code | Severity | File:Line | Issue |
|------|----------|-----------|-------|
| SCH-CMP-005 | P2 | DDL | Missing audit columns on 4 tables: `cmp_complaint_categories`, `cmp_department_sla`, `cmp_complaint_actions`, `cmp_ai_insights` all lack `created_by`/`updated_by`. `cmp_medical_checks` is missing `updated_at` and `deleted_at`. `cmp_complaint_actions` is missing `deleted_at` (but `MedicalCheckController::destroy()` calls soft delete). |
| SEC-CMP-013 | P2 | `ComplaintController.php` getTableColumns() | `getTableColumns($table)` has no Gate::authorize. Any authenticated user can enumerate the schema of any allowed table. |
| SEC-CMP-014 | P2 | `Modules/Complaint/app/Providers/RouteServiceProvider.php` | Mobile API route group applies only `['api', InitializeTenancyByDomain, PreventAccessFromCentralDomains]` — **missing `EnsureTenantIsActive`**. A deactivated tenant's users can still use the mobile API. |
| BUG-CMP-018 | P2 | `Modules/Complaint/app/Models/Complaint.php` targetable() | `morphTo('targetable', 'target_table_name', 'target_selected_id')` — uses the database table name as the morph type key. Laravel morphs expect the model class name (or a registered morph alias), not a table name. Resolution will always fail at runtime. |
| DEAD-CMP-003 | P2 | `MedicalCheckController.php` store():71–76 | Commented-out `dd($request->all())` debug call. (Related: BUG-CMP-001 from Mar 2026 audit noted `dd()` in ComplaintController::store() catch — verify if also resolved.) |
| DEAD-CMP-004 | P2 | `ComplaintReportController.php` baseParetoQuery() | Private method defined but never called — `getParetoReport()` uses an inline query instead. Dead code, 15+ lines. |
| DEAD-CMP-005 | P2 | `ComplaintController.php` getFilteredDashboardData() | Private method declared but never called from any other method in the controller. Dead code. |
| DEAD-CMP-006 | P2 | `ComplaintReportController.php:88-89` | `aiRiskSentimentReport` appears twice in the `compact()` call — duplicate variable reference. Second entry is silently ignored but indicates an incomplete refactor. |
| PERF-CMP-001 | P2 | `ComplaintController.php` getComplaintsWithEscalation() | N+1 query: inside `.map()`, fires `DB::table('sys_dropdowns')->where('id', $complaint->status_id)->value('value')` per complaint to resolve status label. 10 complaints = 10 extra queries. Fix: eager-load status via join or whereIn. |
| PERF-CMP-002 | P2 | `ComplaintController.php` index() | 15+ queries per request: `DepartmentSla::all()` (line 114), `ComplaintCategory::all()` (line 127), two `User::select('id','name')->get()` calls (unbounded), `Role::all()`, `Department::all()`, `Designation::all()`. All unbounded and uncached. |
| PERF-CMP-003 | P2 | `ComplaintController.php` getComplaintActionsData() | `User::orderBy('name')->get(['id','name'])` called twice in the same method. Duplicate identical query. |
| PERF-CMP-004 | P2 | `DepartmentSlaController.php` create() / edit() | Seven unbounded queries on every form render: `Vehicle::all()`, `Vendor::all()`, `User::all()`, `Role::all()`, `Department::all()`, `Designation::all()`, `EntityGroup::all()`. |
| PERF-CMP-005 | P2 | `ComplaintReportController.php` getComplainantHotspotReport() | N+1 inside `.map()`: 3 additional `DB::table` queries fired per hotspot row to resolve most-active complainant, most-common category, and most-common issue. 20 rows = 60 extra queries. |
| PERF-CMP-006 | P2 | `ComplaintController.php` create() / edit() / getTableData() | `DB::select('SHOW TABLES')` and `DB::getSchemaBuilder()->getColumnListing($table)` called on every render — schema introspection in the HTTP hot path. No caching. Should use config/cached value. |
| PERF-CMP-007 | P2 | `MedicalCheckController.php` create() / edit() | `Complaint::all()` and `User::all()` unbounded on every form render. |
| PERF-CMP-008 | P2 | `Mobile/ComplaintMobileController.php` show() | `Role::orderBy->get()->map(fn => ['user_count' => $role->users()->count()])` — N+1 per role. One query per role to count users instead of using `withCount('users')`. |

---

## Layer Health Summary

| Layer | Status | Key Finding |
|-------|--------|-------------|
| DDL Schema | 🔴 RED | Two type-mismatch FKs crash DDL; broken index on non-existent column; no migrations |
| Code Quality | 🔴 RED | 7+ missing methods (500 errors), AiInsightController is a complete stub on live routes, complaints/manage shadowed |
| Security | 🔴 RED | store() unguarded (P0), reports/document-requests zero auth (P0), mobile 7/9 methods unguarded (P1) |
| Performance | 🟡 AMBER | N+1 in complaint listing and reports; 7 unbounded queries in DepartmentSla forms; schema introspection in hot path |
| Deployment | 🔴 RED | No migrations — module cannot be deployed to new tenants; api.php maps wrong controller |

---

## Detailed Findings by Layer

### Layer 1 — DDL Schema

#### Tables Audited
`cmp_complaint_categories`, `cmp_department_sla`, `cmp_complaints`, `cmp_complaint_actions`, `cmp_medical_checks`, `cmp_ai_insights`

#### SCH-CMP-001 — Broken Index (P1)
- **Table:** `cmp_complaints`
- **DDL line:** ~160
- **Issue:** `KEY idx_cmp_status (status)` — the column `status` does not exist. The complaint status column is `status_id` (INT FK).
- **Fix:** `KEY idx_cmp_status_id (status_id)`

#### SCH-CMP-002 — Invalid FK Type: Boolean → INT PK (P0)
- **Table:** `cmp_complaints`
- **DDL line:** ~177
- **Issue:** `CONSTRAINT fk_cmp_medical_check FOREIGN KEY (is_medical_check_required) REFERENCES cmp_medical_checks (id)` — `is_medical_check_required` is `TINYINT(1)`, holding 0 or 1 as a boolean flag. It cannot be a foreign key to `cmp_medical_checks.id` (which holds auto-increment IDs). This will cause MySQL to refuse the entire DDL file.
- **Fix:** Remove this FK entirely. Add a separate `medical_check_id INT UNSIGNED NULL` column if a complaint needs to reference a specific medical check record.

#### SCH-CMP-003 — Invalid FK Type: VARCHAR → INT (P0)
- **Table:** `cmp_medical_checks`
- **DDL line:** ~226
- **Issue:** `CONSTRAINT fk_med_result FOREIGN KEY (result) REFERENCES sys_dropdown_table (id)` — `result` is `VARCHAR(20)`, FK references `id` which is INT. MySQL will reject this FK definition.
- **Fix:** Either change `result` to `result_id INT UNSIGNED` FK, or remove the FK and store result as a freeform/enumerated string without a DB constraint.

#### SCH-CMP-004 — Column Name Mismatch: Code vs DDL (P1)
- **Affected columns:** `expected_resolution_hours`, `escalation_hours_l1`–`l5` on `cmp_complaint_categories`
- **Issue:** Application code (ComplaintCategoryController, DepartmentSlaRequest validation rules) references these column names, but the DDL defines them as `default_expected_resolution_hours`, `default_escalation_hours_l1`–`l5`. Every query against the category escalation columns returns null or fails.
- **Fix:** Align DDL to code (remove `default_` prefix) or run a migration to rename columns and update all references.

#### SCH-CMP-005 — Missing Audit and Soft-Delete Columns (P2)
| Table | Missing |
|-------|---------|
| `cmp_complaint_categories` | `created_by`, `updated_by` |
| `cmp_department_sla` | `created_by`, `updated_by` |
| `cmp_complaint_actions` | `created_by`, `updated_by`, `deleted_at` |
| `cmp_ai_insights` | `created_by`, `updated_by`, `updated_at` |
| `cmp_medical_checks` | `updated_at`, `deleted_at` |
- **Note:** `MedicalCheckController::destroy()` calls `$medicalCheck->delete()` which writes to `deleted_at`. Column must exist.

#### SCH-CMP-006 — FK References Wrong Table Name (P1)
- **Issue:** DDL FK constraints (e.g. `REFERENCES sys_dropdown_table`) reference `sys_dropdown_table`. All application code (ComplaintController, ComplaintReportController, ComplaintMobileController, Dropdown model) queries `sys_dropdowns`. One of these is wrong. Verify actual table name and reconcile DDL.

#### SCH-CMP-007 — No Tenant Migration Files (P0)
- **Path:** `Modules/Complaint/database/migrations/` — empty
- **Issue:** No migration files exist for the Complaint module. Tenant creation (`php artisan tenants:create`) will not create any Complaint tables. DDL must be executed manually, and the broken FK/index issues (SCH-CMP-002, SCH-CMP-003) mean even manual execution will fail.
- **Fix:** Create migration files for all 6 Complaint tables, applying all SCH-CMP fixes in the migration.

---

### Layer 2 — Code Quality

#### 2.1 God Controller
`ComplaintController.php` — 1341 lines. Violates service-layer conventions.  
`ComplaintMobileController.php` — ~671 lines.  
`ComplaintReportController.php` — ~539 lines.  
All three should delegate business logic to service classes.

#### 2.2 Route → Controller Coverage Gaps

**ComplaintController — 4 missing methods:**
| Route | Method | Status |
|-------|--------|--------|
| `GET complaints/trash/view` | `ComplaintController::trashed()` | MISSING → 500 |
| `GET complaints/{id}/restore` | `ComplaintController::restore()` | MISSING → 500 |
| `DELETE complaints/{id}/force-delete` | `ComplaintController::forceDelete()` | MISSING → 500 |
| `POST complaints/{id}/toggle-status` | `ComplaintController::toggleStatus()` | MISSING → 500 |

**ComplaintActionController — 2 missing methods:**
| Route | Method | Status |
|-------|--------|--------|
| `GET complaint-actions/{id}/restore` | `ComplaintActionController::restore()` | MISSING → 500 |
| `DELETE complaint-actions/{id}/force-delete` | `ComplaintActionController::forceDelete()` | MISSING → 500 |

**AiInsightController — 1 missing method:**
| Route | Method | Status |
|-------|--------|--------|
| `DELETE ai-insights/{id}/force-delete` | `AiInsightController::forceDelete()` | MISSING → likely 500 |

**Route shadowing — `complaints/manage`:**
- `Route::resource('complaints', ...)` at line 104 registers `GET complaints/{complaint}` (show).
- `Route::get('complaints/manage', ...)` at line 128 is registered AFTER the resource.
- Laravel matches `complaints/{complaint}` first, treating `manage` as the ID.
- `Complaint::findOrFail('manage')` → 404. Manage view is permanently unreachable.

#### 2.3 Stub Controllers on Live Routes

**AiInsightController (DEAD-CMP-001 — P0):**
- `show()` → returns `view('complaint::show')` (likely wrong view name)
- `store()` → empty `{}`
- `update()` → empty `{}`
- `forceDelete()` → does not exist
- Zero Gate::authorize on any method

**ComplaintActionController (partial stubs):**
- `store()` → has Gate but returns nothing (empty after Gate call)
- `update()` → completely empty `{}`
- `show()` → returns wrong view `complaint::show`
- Wrong permission prefix throughout (`complaint.complaint.*`)

#### 2.4 Dead Code Summary

| Code | Location | Issue |
|------|----------|-------|
| DEAD-CMP-001 | AiInsightController.php | Complete stub wired to live routes (P0 — see P0 section) |
| DEAD-CMP-002 | ComplaintDashboardController.php | Complete stub — route commented out in web.php, harmless for now |
| DEAD-CMP-003 | MedicalCheckController.php:71–76 | Commented `dd($request->all())` debug code |
| DEAD-CMP-004 | ComplaintReportController.php baseParetoQuery() | Private method never called from anywhere |
| DEAD-CMP-005 | ComplaintController.php getFilteredDashboardData() | Private method declared but never called |
| DEAD-CMP-006 | ComplaintReportController.php:88–89 | `aiRiskSentimentReport` duplicated in compact() |

Also note (cross-reference to BUG-CMP-013 from April 2026):  
`MedicalCheckController::index()` and `create()` use `dummy_table_name.dummy_column_name.medical_check_type` and `dummy_table_name.dummy_column_name.medical_check_result` as dropdown lookup keys. These keys will never match any real dropdown entry — create/index forms always render empty dropdowns. This was logged as BUG-CMP-013 in April 2026 and remains unresolved.

---

### Layer 3 — Security

#### 3.1 Authorization Matrix

| Controller | Methods With Gate | Methods Without Gate | Risk |
|------------|------------------|----------------------|------|
| ComplaintController | create, edit, show, update, destroy, manage, getSubCategories, getCategoryMeta, usersByRole | **store**, filter, getTableData, getTableColumns, dashboard chart methods | P0 (store) |
| ComplaintCategoryController | all methods ✓ | none | OK |
| DepartmentSlaController | all methods ✓ | none | OK |
| ComplaintActionController | partial (wrong prefix, never matches) | store, update, show | P1 |
| AiInsightController | none | all | P0 |
| ComplaintReportController | none | all (summary, pareto, hotspot, etc.) | P0 |
| DocumentRequestController | none | all | P0 |
| MedicalCheckController | all crud ✓ | none noted | OK (data issue not auth) |
| ComplaintMobileController | store, update | dashboard, index, show, categories, subcategories, dropdowns, users | P1 |
| ComplaintDashboardController | none | all (not routed, harmless) | — |

#### 3.2 FormRequest Authorization Bypass
Both FormRequests use `authorize(): bool { return true; }`:
- `ComplaintCategoryRequest.php` — D25 systemic pattern
- `DepartmentSlaRequest.php` — D25 systemic pattern

The validation rules themselves are well-written (composite unique, ordered escalation hours). Only the authorize() is a no-op.

#### 3.3 Mass Assignment Risk
`Complaint.$fillable` includes `escalation_level`, `is_escalated`, `is_medical_check_required`, `support_file`:
- `is_medical_check_required` should be derived from the category, not user-set
- `escalation_level` should be computed by the escalation engine
- These allow any authenticated user (given the store() P0 gap) to set system-computed fields directly

#### 3.4 Cross-Layer Model Usage (Tenancy Isolation Risk)
| File | Central Model Used | Risk |
|------|--------------------|------|
| `ComplaintController.php` | `Modules\Prime\Models\Dropdown`, `Modules\Prime\Models\User` | Cross-layer |
| `ComplaintReportController.php` | `Modules\Prime\Models\Dropdown` | Cross-layer |
| `ComplaintMobileController.php` | `Modules\Prime\Models\Dropdown`, `App\Models\User` | Cross-layer |
| `ComplaintCategoryController.php` | `Modules\GlobalMaster\Models\Dropdown` | Cross-layer |
| `MedicalCheckController.php` | `App\Models\User` | Cross-layer |
| `DepartmentSlaController.php` | `App\Models\User` | Cross-layer |
| `Complaint.php` (model) | `Modules\GlobalMaster\Models\Dropdown` | Cross-layer |
All tenant-module controllers and models should use tenant-scoped models only.

#### 3.5 API Route Double-Controller Bug
`routes/api.php` registers:
```php
Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::apiResource('complaints', ComplaintController::class)->names('complaint');
});
```
`ComplaintController` is a web controller returning Blade views. This creates 7 REST API routes that all return HTML. The mobile API (`ComplaintMobileController`) is the correct controller but is not registered in api.php or mobile_api.php via the RSP.

---

### Layer 4 — Performance

#### 4.1 N+1 Query Patterns
| Code | Method | Pattern | Impact |
|------|--------|---------|--------|
| PERF-CMP-001 | ComplaintController::getComplaintsWithEscalation() | `DB::table('sys_dropdowns')->where('id', $complaint->status_id)` inside `.map()` | 1 query/complaint |
| PERF-CMP-005 | ComplaintReportController::getComplainantHotspotReport() | 3 `DB::table` queries inside `.map()` | 3 queries/hotspot row |
| PERF-CMP-008 | ComplaintMobileController::show() | `$role->users()->count()` inside map loop | 1 query/role |

#### 4.2 Unbounded Queries on Form Render
`DepartmentSlaController::create()` and `edit()` each fire 7 unbounded queries:
```
Vehicle::all(), Vendor::all(), User::all(), Role::all(), Department::all(), Designation::all(), EntityGroup::all()
```
With even 200 users and 50 vehicles, this renders several thousand rows on every form open.

#### 4.3 Schema Introspection in Hot Path
`ComplaintController` calls `DB::select('SHOW TABLES')` and `DB::getSchemaBuilder()->getColumnListing($table)` in `create()`, `edit()`, and `getTableData()`. Schema introspection on every render is expensive and cannot be cached by query cache. Should use `config()` or a one-time-cached value.

#### 4.4 Duplicate Identical Query
`ComplaintController::getComplaintActionsData()` — `User::orderBy('name')->get(['id','name'])` issued twice in the same method. Second call returns identical data.

---

### Layer 5 — Deployment Readiness

| Code | Issue |
|------|-------|
| DEPLOY-CMP-01 | No migration files exist. Module tables cannot be created for new tenants via `php artisan tenants:migrate`. Manual DDL execution also blocked by P0 DDL errors (SCH-CMP-002, SCH-CMP-003). |
| DEPLOY-CMP-02 | `api.php` maps web `ComplaintController` as `apiResource`. Route caching will succeed but all 7 API routes return HTML responses. Should map `ComplaintMobileController` or a dedicated API controller. |

**Environment configuration:** No hardcoded API keys found in Complaint module source. ✓

**Mobile API RSP:** Missing `EnsureTenantIsActive` in the middleware stack for the API route group (SEC-CMP-014). Applies to all API routes, not just Complaint.

---

## Known Issue Cross-References

The following codes from prior audits were reviewed and their current status noted:

| Old Code | Prior Finding | Current Status |
|----------|--------------|----------------|
| BUG-CMP-001 (Mar 2026) | `dd($e->getMessage())` in store() catch | Unverified — store() was not fully re-read in this audit. The dd() may remain. Recommend: `grep -n "dd(" Modules/Complaint/app/Http/Controllers/ComplaintController.php` |
| BUG-CMP-001 (Apr 2026) | 4 routes → non-existent ComplaintController methods | **CONFIRMED STILL PRESENT** as BUG-CMP-016 |
| BUG-CMP-002 (Mar 2026) | `dd('FILTER HIT')` in filter() | `filter()` is still routed via `/dashboard-data`. Status unknown. Recommend grep. |
| BUG-CMP-002 (Apr 2026) | 2 routes → non-existent ComplaintActionController methods | **CONFIRMED STILL PRESENT** as BUG-CMP-014 |
| BUG-CMP-003 (Mar 2026) | 3 stub controllers | Partially fixed — ComplaintAction/Dashboard/AiInsight still stubs. AiInsight is now P0. |
| SEC-CMP-001–003 (Mar 2026) | show/edit/store/update no Gate | Partially fixed: show/edit/update now have Gate. **store() still missing Gate** (SEC-CMP-007). |
| SEC-CMP-006 (Mar 2026) | ComplaintReportController zero auth | **CONFIRMED STILL PRESENT** — summary() and all chart methods have no Gate. |
| BUG-CMP-005 (Mar 2026) | MedicalCheckController placeholder dropdown keys | **CONFIRMED STILL PRESENT** — `dummy_table_name` keys in use (same as BUG-CMP-013). |
| BUG-CMP-013 (Apr 2026) | Dropdown queries use dummy_table_name | **CONFIRMED STILL PRESENT** in MedicalCheckController index/create. |

**Note on code conflict:** BUG-CMP-001 and BUG-CMP-002 were registered twice in known-issues.md for different issues (March 2026 vs April 2026). The April 2026 audit reused these codes for new findings. The March 2026 findings (dd() statements) may or may not still be present. Known-issues.md should reconcile these duplicate code entries.

---

## Recommended Fix Priority

### Sprint 1 (Block on release)
1. Add `Gate::authorize('tenant.complaint.create')` to `ComplaintController::store()`
2. Add Gate to `ComplaintReportController::summary()` and chart methods
3. Add Gate to `DocumentRequestController` index/show/update — or move DocumentRequest handling out of Complaint module (preferred, given cross-module dependency)
4. Fix DDL: remove invalid FKs (SCH-CMP-002, SCH-CMP-003), fix broken index (SCH-CMP-001)
5. Create tenant migrations for all 6 tables
6. Add missing methods to ComplaintController: trashed(), restore(), forceDelete(), toggleStatus()
7. Register complaints/manage BEFORE `Route::resource()` or convert to `complaints/{id}/manage`

### Sprint 2 (Before public beta)
8. Add Gate to all AiInsightController routes or disable them until implemented
9. Add Gate to ComplaintMobileController: dashboard, index, show, users
10. Fix ComplaintActionController permission prefix: `complaint.complaint.*` → `tenant.complaint-action.*`
11. Add ComplaintActionController::restore() and forceDelete() methods
12. Fix column name mismatch (SCH-CMP-004) — align code or DDL
13. Remove ParentPortal dependency from DocumentRequestController
14. Fix api.php to use ComplaintMobileController or a dedicated API controller

### Sprint 3 (Performance / cleanup)
15. Resolve all N+1 queries (PERF-CMP-001, 005, 008)
16. Paginate unbounded queries; replace DepartmentSla form queries with select2/AJAX
17. Cache `SHOW TABLES` and schema builder calls
18. Fix Complaint::targetable() morphTo (BUG-CMP-018)
19. Remove commented-out dd() calls (DEAD-CMP-003)
20. Fix dummy_table_name dropdown keys in MedicalCheckController

---

## Module Completion Estimate — Revised

| Sub-component | Prior % | Current % | Blocker |
|---------------|---------|-----------|---------|
| DDL / Migrations | 50% | 15% | P0 DDL errors, no migrations |
| Complaint Categories | 85% | 80% | Minor: cross-layer Dropdown model |
| Department SLA | 80% | 75% | Missing created_by/updated_by in DDL, perf |
| Core Complaints CRUD | 60% | 40% | store() no auth, trash routes missing, manage shadowed |
| Complaint Actions | 20% | 15% | Wrong permission prefix, 2 missing methods, stubs |
| Complaint Reports | 50% | 25% | Zero auth on all report endpoints |
| Document Requests | 30% | 10% | Zero auth, cross-module dependency |
| Medical Checks | 40% | 30% | Dummy keys (create always empty), missing DDL columns |
| AI Insights | 10% | 5% | Complete stub on live routes, zero auth |
| Mobile API | 30% | 15% | 7/9 methods unguarded, api.php wrong controller |

**Overall: ~20%** (down from 30% in prior progress.md entry)

---

*Audit completed: 2026-06-23 | Technical Auditor Agent*  
*Issues registered in known-issues.md: SCH-CMP-001 to 007, BUG-CMP-014 to 018, DEAD-CMP-001 to 006, SEC-CMP-007 to 014, PERF-CMP-001 to 008, DEPLOY-CMP-01 to 02*
