# Module Review Checklist — MANDATORY

> **Purpose:** This checklist MUST be run on EVERY module before it is considered complete.
> Run in 2 rounds: **Round 1 = Functional Correctness**, **Round 2 = Performance & Quality**.
>
> **Canonical Reference Module:** `Modules/Vendor` — use as the benchmark for all checks.

---

## ROUND 1 — Functional Correctness Review

---

### ✅ CHECK 1: DDL Match (Migration ↔ DDL ↔ Model ↔ FormRequest ↔ Blade)

Verify that the database schema is fully in sync across ALL layers:

| Source | What to Check |
|---|---|
| `database/migrations/*.php` | Column names, types, nullability, defaults, indexes, foreign keys match DDL |
| `app/Models/{Resource}.php` | `$fillable` includes all writable columns; `$casts` covers all typed columns |
| Blade views (create/edit forms) | All `name=` attributes match actual DB column names |
| **DDL latest version** | ALWAYS check the **latest DDL file** (v2/v3/v4) — never old versions. DDL is the source of truth. |

**🔴 CRITICAL RULE — DDL → Validation Alignment:**
- DDL column is `NOT NULL` → FormRequest MUST have `'required'` (never `'nullable'`)
- DDL column is `NULL` (nullable) → FormRequest MUST have `'nullable'` (never `'required'`)
- DDL has `DEFAULT value` → Model `$attributes` should match; FormRequest can omit `'required'` if default exists
- DDL `UNIQUE` constraint → FormRequest MUST use `Rule::unique()->ignore($id)->whereNull('deleted_at')`

**DDL UNIQUE Constraints:**
- Every single-column `UNIQUE` → `Rule::unique('table', 'column')->ignore($id)->whereNull('deleted_at')` in FormRequest
- Every composite `UNIQUE (col1, col2, ...)` on junction tables → `$validator->after()` closure in FormRequest to check within-request duplicate combos (no two rows with same `(col1, col2, ...)`)
- Controller `store()`/`update()` MUST catch `QueryException` with `$e->getCode() === '23000'` for graceful duplicate error handling

**Common Bugs to Look For:**
- Column exists in DDL but missing from `$fillable` → silent data loss on save
- Column `nullable` in DDL but `'required'` in FormRequest → form always fails
- Column `NOT NULL` in DDL but `'nullable'` in FormRequest → DB error on save
- ENUM values in DDL (e.g., `'Open','Closed'`) but wrong string used in code → SQL truncation warning
- `deleted_at` column missing from migration but `SoftDeletes` used in Model → crash on delete
- FK column in migration but no `->constrained()` → orphaned records

**How to Check:**
```
1. Open the LATEST DDL file (e.g., CAF_DDL_v2.sql — never old v1)
2. Open migration file for that table
3. Open Model file
4. Open FormRequest file
5. Open Blade create/edit form files
6. Side-by-side compare: every DDL column → migration → fillable → cast → validation rule → blade input name
```

---

### ✅ CHECK 2: Notifications

Verify all user-facing events have proper notifications implemented.

**Required Notification Points:**
- Record **Created** → success flash message via `flash('created.{slug}')`
- Record **Updated** → success flash message via `flash('updated.{slug}')`
- Record **Trashed** → success flash message via `flash('trashed.{slug}')`
- Record **Restored** → success flash message via `flash('restored.{slug}')`
- Record **Force Deleted** → success flash message via `flash('force_deleted.{slug}')`
- Status **Toggled** → JSON response with `success: true` + `message: flash('status_updated.{slug}')`
- AJAX/Form **errors** → validation error display in Blade (`@if($errors->any())`)
- **Email notifications** → if business process requires email (e.g., invoice sent, payment received)

**Checklist:**
- [ ] Every controller method ends with `->with('success', flash('...'))` or JSON `success: true`
- [ ] `flash()` keys defined in language file (`lang/en/messages.php` or equivalent)
- [ ] Edit/Create forms show `@if ($errors->any())` validation error block
- [ ] Toggle status returns proper JSON with `success`, `is_active`, `message` keys
- [ ] Email Mailable exists if email notification is required (check `Mail/` directory)

---

### ✅ CHECK 3: Roles & Permissions

Verify ALL permission gates are properly implemented at every layer.

**Controller Layer:**
- [ ] `Gate::authorize('tenant.{slug}.viewAny')` → `index()`, `trashed()`
- [ ] `Gate::authorize('tenant.{slug}.create')` → `create()`, `store()`
- [ ] `Gate::authorize('tenant.{slug}.view')` → `show()`
- [ ] `Gate::authorize('tenant.{slug}.update')` → `edit()`, `update()`, `toggleStatus()`
- [ ] `Gate::authorize('tenant.{slug}.delete')` → `destroy()`
- [ ] `Gate::authorize('tenant.{slug}.restore')` → `restore()`, `trashed()`
- [ ] `Gate::authorize('tenant.{slug}.forceDelete')` → `forceDelete()`

**Policy Layer:**
- [ ] Policy file exists for every Model in `app/Policies/`
- [ ] Every Policy method delegates to `$user->can('tenant.{slug}.{action}')`
- [ ] Policy is registered in `ServiceProvider::registerPolicies()` via `Gate::policy()`

**Blade Layer (GOLD STANDARD — SYMMETRIC):**
- [ ] Add button wrapped in `@can('tenant.{slug}.create')`
- [ ] Status column `<th>` AND `<td>` BOTH wrapped in `@can('tenant.{slug}.update')`
- [ ] Action column `<th>` AND `<td>` BOTH wrapped in `@canany([...view, update, delete])`
- [ ] Trash action `<th>` AND `<td>` BOTH wrapped in `@canany([...restore, forceDelete])`
- [ ] Edit button on show page wrapped in `@can('tenant.{slug}.update')`
- [ ] Tab visibility uses `permission` key in `x-backend.tab.nav-tab` + `@can` around `@include`

**Permission Registration:**
- [ ] All permission slugs added to the permissions seeder / database

> 📄 See `rules/permission-rules.md` for full @can patterns and naming conventions.

---

### ✅ CHECK 4: Breadcrumb & Menu Placement

**Breadcrumb:**
- [ ] Every standalone page (`create`, `edit`, `show`, `trash`) has `<x-backend.components.breadcrum :links="[]" />`
- [ ] Breadcrumb `title` is descriptive and correct (e.g., "Add Vendor", "Edit Vendor Item")
- [ ] Hub tab page has breadcrumb with module title (e.g., "Vendor Master")
- [ ] Route segment → breadcrumb title mappings added to `config/breadcrumb.php` under `hub_map`
- [ ] Tab aliases (`?tab=vendor`, `?tab=vendor_item`) added to `config/breadcrumb.php` under `tab_aliases`

**Menu Placement:**
- [ ] Module has correct entry in the sidebar navigation menu
- [ ] Menu item has correct `route()` pointing to the hub/index page
- [ ] Menu item has correct icon
- [ ] Menu item is wrapped in `@can('tenant.{slug}.viewAny')` in the sidebar Blade

---

### ✅ CHECK 5: Background Services Required?

Determine if any functionality requires a **queued job** or **background process**:

| Scenario | Required Service |
|---|---|
| Sending emails | `Mail::to()->queue()` + Queue worker |
| PDF generation | Queue job if large/slow |
| File processing | Queue job via Spatie Media Library |
| Report generation | Queue job for heavy queries |
| External API calls | Queue job |
| Bulk data import | Queue job |

**Checklist:**
- [ ] Identify all operations that could be slow (>2 seconds)
- [ ] If email is sent in controller → move to `Mail::queue()` or `dispatch(new MailJob)`
- [ ] Check `Jobs/` directory — are all required jobs created?
- [ ] Are jobs properly dispatched with `dispatch()` or `Bus::dispatch()`?

---

### ✅ CHECK 6: CRON Jobs Required?

Determine if any business process requires **scheduled tasks**:

| Scenario | CRON Requirement |
|---|---|
| Agreement expiry check | Daily CRON to flag expired agreements |
| Invoice auto-generation | Monthly CRON |
| Report auto-export | Weekly/Monthly CRON |
| Status auto-update (e.g., overdue) | Daily CRON |
| Reminder emails | Daily CRON |

**Checklist:**
- [ ] Identify time-based business processes
- [ ] Check `app/Console/Kernel.php` or `routes/console.php` for registered schedules
- [ ] If a CRON is needed but missing → create Artisan command + add to schedule
- [ ] Test schedule: `php artisan schedule:list`

---

### ✅ CHECK 7: Dropdown Table Entries Required?

Verify all dropdown-dependent fields have their master data populated.

**Common Dropdown Tables:**
- `sys_dropdowns` (Global Master) — used for categories, types, units, etc.
- Module-specific config tables

**Checklist:**
- [ ] Identify all `category_id`, `type_id`, `unit_id`, etc. FK fields in forms
- [ ] Verify corresponding entries exist in `sys_dropdowns` for the correct `key` group
- [ ] Form dropdowns use `<x-backend.form.form-dropdown key="{table}.{column}" ...>` component
- [ ] If dropdown entries are missing → add seeder or manual DB insert
- [ ] Dropdown filter (`key` matching) is correct in the component call

---

### ✅ CHECK 8: Optional vs. Compulsory Fields

Review all form fields and verify required/nullable alignment across 4 layers:

| Layer | Should Match |
|---|---|
| DDL (`NOT NULL` vs `NULL`) | Source of truth |
| Migration (`->nullable()` vs no modifier) | Must match DDL |
| FormRequest (`'required'` vs `'nullable'`) | Must match DDL |
| Blade form (`required="true"` vs no required) | Must match DDL |

**Common Errors:**
- Field is `nullable` in DB but `'required'` in FormRequest → always fails on save
- Field is `NOT NULL` in DB but `'nullable'` in FormRequest → null insert causes DB error
- Required field has no `required="true"` in form → user can submit empty

**Checklist:**
- [ ] Every `NOT NULL` column in DDL → `'required'` in FormRequest + `required="true"` in Blade
- [ ] Every `NULL` column in DDL → `'nullable'` in FormRequest + no `required` in Blade
- [ ] Verify `$fillable` on Model has no column that is `NOT NULL` without a default

---

### ✅ CHECK 9: Look & Feel & Alignment

UI/UX consistency check across all views:

**Layout:**
- [ ] All create/edit forms use 4-column grid (`col-md-3`)
- [ ] All show/details pages use 2-card layout (left + right, `col-md-6`)
- [ ] All tables have `<thead class="table-light">` and `<table class="table table-sm align-middle">`
- [ ] All pages wrap content in `<div class="container-fluid">`
- [ ] All standalone pages have proper `<div class="card mb-4">` wrapping

**Buttons & Actions:**
- [ ] Create/Add → `btn-primary`
- [ ] Edit/Update → `btn-warning`
- [ ] Delete/Trash → `btn-danger`
- [ ] Restore → `btn-success`
- [ ] Back/Cancel → `btn-secondary` or `btn-outline-*`

**Status Badges:**
- [ ] Active → `<span class="badge bg-success">Active</span>`
- [ ] Inactive → `<span class="badge bg-danger">Inactive</span>`
- [ ] Pending/Draft → `<span class="badge bg-warning text-dark">Draft</span>`

**Icons (Font Awesome 6):**
- [ ] Add → `fa-solid fa-plus`
- [ ] Edit → `fas fa-edit`
- [ ] Delete → `fa-solid fa-trash`
- [ ] View/Show → `fas fa-eye`
- [ ] Restore → `fas fa-undo` or `fa-solid fa-rotate-left`
- [ ] Back → `fas fa-arrow-left`

---

### ✅ CHECK 10: Dropdown Data Filters Accurate?

Verify dynamic dropdown filters are properly scoped:

**Common Filters:**
- Vendor-scoped items → `where('vendor_id', $vendor->id)`
- Active-only dropdowns → `->where('is_active', true)` or `->active()`
- Session/Academic year-scoped → `->where('session_id', currentSession()->id)`
- Module-specific key filter → `key='{table}.{column}'` in `x-backend.form.form-dropdown`

**Checklist:**
- [ ] All dropdown components have the correct `key` parameter
- [ ] All filter queries scope to active records only
- [ ] All relational dropdowns (e.g., show agreements for selected vendor) use AJAX or pre-filtered Eloquent
- [ ] No dropdown shows ALL records when it should be filtered (e.g., all vendors in an item dropdown)

---

### ✅ CHECK 11: Business Condition & Process Flow

Verify the implementation matches the actual business requirement:

**Questions to Answer:**
1. Does the happy-path workflow match the expected sequence of screens/actions?
2. Are status transitions enforced? (e.g., Draft → Active → Expired — can user skip?)
3. Are cross-model dependencies respected? (e.g., can't delete Vendor if active Agreements exist)
4. Are computed/derived values correct? (e.g., invoice total = sum of items × price × GST)
5. Are soft-delete cascades handled? (e.g., trash parent → children should not be visible)
6. Is date/time logic correct? (e.g., agreement end date must be after start date)
7. Are batch operations (multi-select actions) required?

**Checklist:**
- [ ] Verify status state machine transitions are enforced in controller
- [ ] Verify foreign key constraints prevent orphaned operations
- [ ] Verify computed totals/amounts are calculated server-side (never trust client)
- [ ] Verify date comparisons use `Carbon` correctly
- [ ] Verify `->latest()` is used consistently for ordering

---

## ROUND 2 — Performance, Quality & Security

---

### ✅ CHECK 12: Database Indexes

Every table must have proper indexes for all query patterns:

**Required Indexes:**
- [ ] Primary Key → always auto-indexed
- [ ] Every FK column → `$table->index('vendor_id')`
- [ ] Frequently `WHERE`'d columns → `$table->index('is_active')`, `$table->index('status')`
- [ ] `deleted_at` → `$table->index('deleted_at')` (SoftDeletes performance)
- [ ] Date range filter columns → `$table->index('created_at')`, `$table->index('payment_date')`
- [ ] Unique business keys → `$table->unique(['vendor_id', 'ref_no'])`
- [ ] Composite indexes for common multi-column filters

**How to Identify Missing Indexes:**
```sql
EXPLAIN SELECT * FROM vnd_vendors WHERE is_active = 1 AND deleted_at IS NULL;
-- If type = "ALL" (full table scan) → add index
```

---

### ✅ CHECK 13: Performance Optimization

**N+1 Query Prevention:**
- [ ] All relationships are eager-loaded in index queries: `->with(['vendor', 'items'])`
- [ ] No `$model->relation` inside `@foreach` without eager loading
- [ ] Use `->withCount('items')` instead of `$model->items->count()` in loops

**Query Optimization:**
- [ ] Tab-based index queries apply filters ONLY when that tab is active (`if ($request->input('tab') === '...')`)
- [ ] Use `->select(['id', 'name', 'is_active'])` instead of `SELECT *` for listing queries
- [ ] Use `->paginate(10)` — never `->get()` on large tables
- [ ] Use `->withQueryString()` on all paginated queries

**Blade/View Optimization:**
- [ ] No heavy computation in Blade — move to Controller or Model scope
- [ ] Use `@once` directive for scripts repeated in included partials
- [ ] Avoid nested `@foreach` without pagination

---

### ✅ CHECK 14: Code Quality

**Controller:**
- [ ] Every method has a docblock comment
- [ ] No method exceeds ~40 lines (extract to private methods)
- [ ] Private query methods are `private`, not `public`
- [ ] No raw SQL (`DB::statement(...)`) without justification
- [ ] No `$request->all()` or `$request->input()` — always `$request->validated()`

**Model:**
- [ ] No business logic in Models — only data structure, scopes, relationships
- [ ] No `$guarded = []` — always explicit `$fillable`
- [ ] All constants defined as `public const` for ENUM values

**FormRequest:**
- [ ] `authorize()` returns `true` (never false)
- [ ] `Rule::unique()->whereNull('deleted_at')` for all unique fields
- [ ] `prepareForValidation()` casts boolean fields

**Blade:**
- [ ] No PHP logic in Blade (`@php` blocks) — move to Controller/Model
- [ ] All section comments use `{{-- ===== SECTION ===== --}}` format
- [ ] No inline JavaScript without `@once` or `@push('scripts')`

---

### ✅ CHECK 15: Code Vulnerability (Security)

**SQL Injection:**
- [ ] No raw `DB::select("SELECT ... WHERE id = $id")` — always use bindings
- [ ] Use Eloquent query builder — never string concatenation in queries

**Mass Assignment:**
- [ ] All models use explicit `$fillable` — never `$guarded = []`
- [ ] FormRequest `->validated()` used in all `create()` and `update()` calls

**Authorization:**
- [ ] `Gate::authorize()` at the top of EVERY controller method
- [ ] No method accessible without a Gate check (check trashed, restore, forceDelete too)
- [ ] `Route::resource` does not expose routes that should be restricted

**XSS:**
- [ ] All user-input displayed with `{{ }}` (escaped), never `{!! !!}` unless explicitly safe HTML
- [ ] File uploads validated by MIME type + extension, not just `hasFile()`

**CSRF:**
- [ ] All non-GET forms have `@csrf`
- [ ] All DELETE/PATCH forms have `@method('DELETE')` / `@method('PATCH')`
- [ ] AJAX requests include CSRF header: `'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')`

**File Upload Security:**
- [ ] Uploaded files validated by MIME type (`mimes:jpg,pdf,...`)
- [ ] File size limited (`max:2048`)
- [ ] Files stored via Spatie Media Library — never `move()` to public directory directly

---

## REVIEW SUMMARY TEMPLATE

Use this template to document each module review:

```markdown
## Module Review: {ModuleName} — {Date}

### Round 1 Results

| Check | Status | Notes |
|---|---|---|
| 1. DDL Match | ✅ / ❌ / ⚠️ | |
| 2. Notifications | ✅ / ❌ / ⚠️ | |
| 3. Roles & Permissions | ✅ / ❌ / ⚠️ | |
| 4. Breadcrumb & Menu | ✅ / ❌ / ⚠️ | |
| 5. Background Services | ✅ / ❌ / N/A | |
| 6. CRON Jobs | ✅ / ❌ / N/A | |
| 7. Dropdown Entries | ✅ / ❌ / ⚠️ | |
| 8. Optional/Compulsory | ✅ / ❌ / ⚠️ | |
| 9. Look & Feel | ✅ / ❌ / ⚠️ | |
| 10. Dropdown Filters | ✅ / ❌ / ⚠️ | |
| 11. Business Conditions | ✅ / ❌ / ⚠️ | |

### Round 2 Results

| Check | Status | Notes |
|---|---|---|
| 12. DB Indexes | ✅ / ❌ / ⚠️ | |
| 13. Performance | ✅ / ❌ / ⚠️ | |
| 14. Code Quality | ✅ / ❌ / ⚠️ | |
| 15. Security | ✅ / ❌ / ⚠️ | |

### Issues Found
1. ...

### Fixes Applied
1. ...
```
