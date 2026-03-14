# Known Issues, Gotchas & Hard-Won Fixes

> Add entries here whenever you hit a non-obvious bug, a tricky tenancy issue, or a pattern
> that burned time to figure out. Future work should check this file first.

---

## Format
```
### [SHORT TITLE]
- **Module/Area:** ...
- **Symptom:** What went wrong / what error appeared
- **Root Cause:** Why it happened
- **Fix:** Exact solution applied
- **Prevention:** How to avoid in the future
```

---

## Tenancy Issues

### Tenant DB Not Initialized on Queued Jobs
- **Module/Area:** All modules using queued jobs
- **Symptom:** Queued jobs fail with "Table not found" or query runs on wrong database
- **Root Cause:** Tenancy context is not automatically passed to queued jobs
- **Fix:** Use `TenancyAwareJob` or manually call `tenancy()->initialize($tenant)` inside the job's `handle()` method. Pass `$tenant->id` as a constructor argument.
- **Prevention:** Always implement `ShouldBeUniqueUntilProcessing` or pass tenant ID explicitly when dispatching jobs from tenant context.

### Cache Collision Between Tenants
- **Module/Area:** Any feature using Laravel Cache
- **Symptom:** One school sees another school's cached data
- **Root Cause:** Cache keys not prefixed with tenant ID
- **Fix:** Always prefix cache keys with `tenant()->id` or use `Cache::tags([tenant()->id])`
- **Prevention:** Never use bare string cache keys in tenant-scoped code. Always prefix.

### `InitializeTenancyByDomain` Fails on API Routes
- **Module/Area:** API routes in tenant modules
- **Symptom:** 404 or tenancy not initialized error on API calls
- **Root Cause:** API routes not wrapped in `tenancy` middleware group
- **Fix:** Ensure tenant API routes are in `routes/tenant.php` and use the `tenancy` middleware group
- **Prevention:** Check middleware groups in route files before adding new API routes.

---

## Module Issues

### Module Migration Not Running
- **Module/Area:** Any new module
- **Symptom:** Tables not created after `php artisan migrate`
- **Root Cause:** Tenant migrations must be in `database/migrations/tenant/` or use `php artisan module:make-migration --tenant`
- **Fix:** Move migration file to correct path, re-run `php artisan tenants:migrate`
- **Prevention:** Always use `--tenant` flag when creating migrations for tenant-scoped modules.

### Service Not Found in Container
- **Module/Area:** Any module
- **Symptom:** `BindingResolutionException` when controller tries to inject a service
- **Root Cause:** Service not registered in module's `ServiceProvider`
- **Fix:** Add `$this->app->singleton(EntityService::class)` to the module's `ServiceProvider::register()`
- **Prevention:** Use constructor injection only; register all services in the module provider.

---

## Database Issues

### Soft Delete + Unique Constraint Conflicts
- **Module/Area:** Any table with soft deletes and unique columns
- **Symptom:** Can't re-create a record with the same unique value after soft delete
- **Root Cause:** `deleted_at` is NULL for active records, but unique constraints don't account for soft-deleted rows
- **Fix:** Use composite unique: `->unique(['column', 'deleted_at'])` or use a `is_active` workaround
- **Prevention:** When adding unique constraints on tables with soft deletes, always make the index partial or composite.

---

## Testing Specific

### First DB Feature Test Run is Very Slow (~50s)
- **Area:** All Feature tests using `RefreshDatabase`
- **Symptom:** First test in the Feature suite takes 50-55s, subsequent tests are ~2s
- **Root Cause:** On the first run, SQLite in-memory DB is cold — Laravel runs ALL module migrations (29 modules × multiple migrations). This is one-time per test session.
- **Fix:** This is normal and expected. No action needed.
- **Prevention:** If speed becomes an issue, consider `--parallel` flag or splitting test suites.

### Spatie MediaLibrary PHP 8.4 Deprecation in Unit Tests
- **Area:** Any model using `InteractsWithMedia` (Student, etc.)
- **Symptom:** `DEPR` warning on first test that instantiates the model — `registerMediaConversions(): Implicitly marking parameter $media as nullable is deprecated`
- **Root Cause:** Spatie MediaLibrary code hasn't been updated for PHP 8.4 strict nullable types
- **Fix (in model):** Change `public function registerMediaConversions(Media $media = null)` → `public function registerMediaConversions(?Media $media = null)`
- **Prevention:** Only affects models with `InteractsWithMedia`. Unit tests still pass — it's a warning not a failure.

### Two Identical Setting Models
- **Area:** Setting model
- **Symptom:** `Modules\Prime\Models\Setting` and `Modules\SystemConfig\Models\Setting` are identical — same table `sys_settings`, same code
- **Root Cause:** Likely copy-paste during module split. Controllers use `SystemConfig\Models\Setting`.
- **Fix:** Consolidate to one model (pending decision). For now, write tests against `Modules\Prime\Models\Setting` (the one listed in the task).

### Setting HTTP Feature Tests Cannot Be Written Yet
- **Area:** Setting (HTTP layer)
- **Symptom:** `Modules/SystemConfig/routes/web.php` is empty — no setting routes registered
- **Root Cause:** Routes not defined yet
- **Fix:** Define routes first, then HTTP tests can be added.

## SmartTimetable Specific

*(Add SmartTimetable-specific issues here as discovered)*

---

## LMS Modules

*(Add LmsExam, LmsQuiz, LmsHomework issues here as discovered)*

---

---

## Critical Production Bugs (from Engineering Audit 2026-03-12)

### BUG-002: Policy Overwriting — Authorization Silently Broken for Multiple Models
- **Module/Area:** `app/Providers/AppServiceProvider.php`
- **Symptom:** QuestionBank, Vehicle, Section CRUD operations bypass authorization — wrong policy enforced
- **Root Cause:** `Gate::policy()` called multiple times for same model — only LAST registration wins. `QuestionBank::class` registered 3 times, `Vehicle::class` registered 5 times.
- **Fix:** Audit AppServiceProvider for duplicate `Gate::policy()` calls and remove duplicates. Copy-paste errors: `BookAuthors::class` mapped to `CircularGoalsPolicy`, `BokBook::class` mapped to `HpcParametersPolicy`.
- **Prevention:** Each model class should appear exactly once in Gate::policy() registration.

### BUG-004: Tenant Migration Pipeline Commented Out
- **Module/Area:** `app/Providers/TenancyServiceProvider.php`
- **Symptom:** New tenants created with empty database — no tables, no root user, onboarding broken
- **Root Cause:** `MigrateDatabase`, `CreateRootUser`, `AddOrganizationDetails`, `SeedDatabase` all commented out in TenantCreated event
- **Fix:** Uncomment at minimum `MigrateDatabase` and `CreateRootUser`
- **Prevention:** Never comment out the migration pipeline without explicit rollback plan.

### SEC-004: Payment Webhook Behind Auth Middleware — Razorpay Always Fails
- **Module/Area:** `routes/tenant.php` line 295, Payment module
- **Symptom:** All Razorpay payment callbacks fail with 401/redirect — invoices never marked as paid
- **Root Cause:** Webhook route inside `auth` + `verified` middleware group. Server-to-server webhooks cannot authenticate as Laravel users.
- **Fix:** Move `Route::post('/payment/webhook/{gateway}', ...)` OUTSIDE the auth middleware group. Signature verification in the controller is sufficient protection.
- **Prevention:** Webhook routes must ALWAYS be unauthenticated (protected by signature verification, not session auth).

### SEC-011: env() in Route File Breaks After Config Cache
- **Module/Area:** `routes/web.php` line 62
- **Symptom:** After running `php artisan config:cache`, ALL central admin routes stop working (domain group fails to register)
- **Root Cause:** `Route::domain(env('APP_DOMAIN'))` — `env()` returns null after config caching
- **Fix:** Change to `config('app.domain')` and ensure APP_DOMAIN is mapped in `config/app.php`
- **Prevention:** Never use `env()` outside config files. This breaks all routes after production config cache.

### SEC-002: is_super_admin in User $fillable — Privilege Escalation Risk
- **Module/Area:** `app/Models/User.php`
- **Symptom:** Any controller using `$request->all()` could allow a user to set `is_super_admin=1`
- **Root Cause:** `is_super_admin`, `super_admin_flag`, `remember_token` included in `$fillable`
- **Fix:** Remove these sensitive fields from `$fillable`; set via explicit assignment only
- **Prevention:** Audit `$fillable` arrays — privilege-related fields should never be mass-assignable.

### PERF-001: Zero Application-Level Caching
- **Module/Area:** All controllers system-wide
- **Symptom:** Slow page loads; dropdown data (queried 16+ times per request in ComplaintController), settings, academic sessions all re-queried from DB on every request
- **Root Cause:** No `Cache::remember()` calls anywhere in controllers or services
- **Fix:** Cache dropdowns (1h TTL), academic sessions, room types, settings, study formats. Use `Cache::remember('key_'.tenancy()->tenant->id, 3600, fn() => ...)`
- **Prevention:** Any reference data that changes rarely should be cached. Always prefix cache keys with tenant ID.

---

## SmartTimetable — Parallel Periods

### FETSolver: Parallel Non-Anchor Must Be Skipped, Not Blocked
- **Module/Area:** SmartTimetable / FETSolver parallel period logic
- **Symptom:** Non-anchor activities fail to place because their anchor hasn't been placed yet in the ordering
- **Root Cause:** `orderActivitiesByDifficulty()` boosts all parallel members before non-parallel activities, but within a group, non-anchors may appear before the anchor's current weekly instance
- **Fix:** In `backtrack()`, when a non-anchor member is encountered and its anchor has NOT yet been placed in context, skip it with `return $this->backtrack($activities, $index + 1, $solution, $context)` — do NOT return false. The anchor's placement logic will handle placing siblings.
- **Prevention:** Always check `findActivitySlotInContext($anchorId, $context)` before attempting to force-place a non-anchor sibling.

### FETSolver: Sibling classKey Must Come From Sibling Activity, Not Anchor
- **Module/Area:** SmartTimetable / FETSolver `placeParallelGroup` equivalent logic
- **Symptom:** Sibling placed in wrong class slot (overwriting a different class's timetable)
- **Root Cause:** Using anchor's `classKey` for all siblings instead of each sibling's own `getClassKey()`
- **Fix:** Always call `$this->getClassKey($siblingInstance)` to get the sibling's own class-section key before constructing the `Slot`.

---

## SmartTimetable Constraint System

### ConstraintCategory / ConstraintScope Point to Non-Existent Tables
- **Module/Area:** SmartTimetable / Constraint models
- **Symptom:** Any query on `ConstraintCategory` or `ConstraintScope` throws "Table tt_constraint_categories doesn't exist" or "tt_constraint_scopes doesn't exist"
- **Root Cause:** Models declared separate tables but the migration created a single shared table `tt_constraint_category_scope` with a `type` ENUM('CATEGORY','SCOPE')
- **Fix (2026-03-12):** Both models updated to use `tt_constraint_category_scope` with `addGlobalScope` filtering by `type`. Use `ConstraintCategoryScope` for direct access to the combined table.
- **Prevention:** When a migration creates a combined/polymorphic table, update ALL models that reference it before writing queries. Always cross-check `$table` against actual migration file.

### Constraint Model Column Names Differ from DB Columns
- **Module/Area:** SmartTimetable / `Constraint` model vs `tt_constraints` migration
- **Symptom:** Mass assignment silently fails; queries return null for date fields; `scopeForTerm()` queries wrong column
- **Root Cause:** Model was written with different names than the migration: `academic_term_id` vs `academic_session_id`, `effective_from_date` vs `effective_from`, `effective_to_date` vs `effective_to`, `applicable_days_json` vs `applies_to_days_json`, `target_type_id` vs `target_type`
- **Fix (2026-03-12):** Model fillable/casts/scopes all updated to use actual DB column names. Alias columns added via migration 2026_03_12_100002 for backward compat.
- **Prevention:** Always verify `$fillable` against the actual migration before writing new constraints. Use `php artisan db:show --table=tt_constraints` to inspect live columns.

### ConstraintType Model References Columns That Didn't Exist Yet
- **Module/Area:** SmartTimetable / `ConstraintType` model vs `tt_constraint_types` migration
- **Symptom:** Queries using `is_hard_capable`, `is_soft_capable`, `parameter_schema`, `scopeHardCapable()`, `scopeSoftCapable()` fail with "Unknown column" error
- **Root Cause:** Model was written ahead of migrations — `is_hard_capable`, `is_soft_capable`, `parameter_schema`, `applicable_target_types`, `constraint_level` not in original migration
- **Fix (2026-03-12):** Migration `2026_03_12_100001` adds all missing columns additively. Old `is_hard_constraint`/`param_schema` kept for rollback safety.
- **Prevention:** Run `php artisan tenants:migrate` after any model column addition before using those columns in queries.
- **Prevention:** In parallel group logic, each activity gets its own `Slot` with its own `classKey`; only `dayId` and `startIndex` are shared from the anchor.
