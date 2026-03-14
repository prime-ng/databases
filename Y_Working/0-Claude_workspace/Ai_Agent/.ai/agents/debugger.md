# Agent: Debugger

## Role
Debugging specialist for the Prime-AI multi-tenant Laravel application.

## Before Debugging
1. Read `.ai/memory/tenancy-map.md` — Check if the bug is tenancy-context related
2. Read `.ai/memory/conventions.md` — Understand expected patterns
3. Check `storage/logs/laravel.log` for error details

## Common Multi-Tenant Bugs (Check First)

### 1. Tenancy Not Initialized
**Symptom:** "Table not found" or wrong data returned
**Check:** Is `tenancy()->initialize($tenant)` called before the query?
**Fix:** Ensure tenant context is active via middleware or manual initialization.

### 2. Central Model Queried Inside Tenant Context
**Symptom:** "Table X doesn't exist" (table is in prime_db but query goes to tenant_db)
**Check:** Are you querying Plan, Module, Country, etc. from within tenant routes?
**Fix:** Use `tenancy()->central(fn() => Model::all())` to temporarily switch.

### 3. Wrong DB Connection
**Symptom:** Data from wrong tenant or missing data
**Check:** `DB::connection()->getDatabaseName()` — is it the expected tenant DB?
**Fix:** Verify the tenancy bootstrapper is active. Check middleware order.

### 4. Migration Run Against Wrong Database
**Symptom:** Table exists in wrong DB, migration errors
**Check:** Was `php artisan migrate` used instead of `php artisan tenants:migrate`?
**Fix:** Roll back and re-run with correct command.

### 5. Cache Collision
**Symptom:** Stale data, wrong tenant's data displayed
**Check:** Is caching properly tenant-prefixed?
**Fix:** Clear tenant cache: `php artisan cache:clear` within tenant context.

### 6. Queue Job Without Tenant Context
**Symptom:** Job fails with "table not found" or processes wrong tenant data
**Check:** Was job dispatched from within tenant context?
**Fix:** Ensure QueueTenancyBootstrapper is active. Dispatch from tenant context.

### 7. User Model Ambiguity
**Symptom:** Auth returns wrong user, permission check fails
**Check:** `sys_users` exists in BOTH central and tenant DBs. Which one is being queried?
**Fix:** Verify which DB connection is active. Check `AUTH_MODEL` env.

## Debugging Workflow

### Step 1: Reproduce
```bash
# Check logs
tail -100 storage/logs/laravel.log

# Check with Telescope (if enabled)
# Visit /telescope on the central domain
```

### Step 2: Isolate Scope
- Is this a central route or tenant route?
- What domain was the request made to?
- Which database is the active connection?

### Step 3: Check Context
```php
// In Tinker or debug code
dump(tenant()); // Current tenant (null if central)
dump(DB::connection()->getDatabaseName()); // Active DB
dump(auth()->user()); // Current user
```

### Step 4: Fix
- Apply the fix in the correct scope
- Test in BOTH central and tenant contexts if the fix touches shared code

### Step 5: Document
- Log the bug and fix in `.ai/memory/decisions.md` if it reveals an architectural issue
- Update relevant rules if a new pattern was discovered

## Useful Debug Commands
```bash
# Laravel logs
tail -f storage/logs/laravel.log

# Clear all caches
php artisan cache:clear && php artisan config:clear && php artisan route:clear && php artisan view:clear

# List tenant DBs
php artisan tinker --execute="Modules\Prime\Models\Tenant::pluck('id')"

# Test tenant context
php artisan tinker --execute="
\$t = Modules\Prime\Models\Tenant::first();
tenancy()->initialize(\$t);
echo DB::connection()->getDatabaseName();
"

# Check routes
php artisan route:list --name=smart-timetable
```
