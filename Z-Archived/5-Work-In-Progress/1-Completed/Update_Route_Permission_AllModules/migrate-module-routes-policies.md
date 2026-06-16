# Prompt: Move Module Routes & Gate Policies into Module-Owned Files

## How to Run

Open Claude Code, paste this entire file, then set the module name:

```
MODULE_NAME = Admission
```

That is the **only input required.** Everything else — paths, routes, policies — is resolved automatically.

---

> ### ⚠️ Strict Scope — Exactly 4 Files Will Be Touched
>
> | File | Action |
> |------|--------|
> | `routes/tenant.php` | Remove this module's routes |
> | `app/Providers/AppServiceProvider.php` | Remove this module's Gate policies |
> | `Modules/{MODULE_NAME}/routes/web.php` | Receive the routes |
> | `Modules/{MODULE_NAME}/app/Providers/{MODULE_NAME}ServiceProvider.php` | Receive the policies |
>
> **DO NOT touch under any circumstances:**
> database migration files, model files, controller files, view files,
> config files, test files, or any other file not listed above.
> Database migrations stay exactly where they are — completely out of scope.
>
> **No git operations.** Do not run `git add`, `git commit`, `git checkout`,
> or any other git command. Branch management and commits are done manually by the developer.

---

## Background

This is the **Prime AI** Laravel 12 multi-tenant SaaS application.

**The problem:** All tenant module routes live in one central file (`routes/tenant.php`,
~3000 lines, 1500+ route definitions) and all Gate policy registrations live in one
central `AppServiceProvider.php` (~923 lines, 249 policies). This causes every page
request to boot all modules regardless of which module the request targets.

**The fix:** Each module owns its own routes and policies. When you pass `MODULE_NAME`,
this prompt extracts only that module's routes and policies from the central files and
places them inside the module's own provider and route file.

---

## Step 0 — Resolve Paths

### 0a. Detect APP_REPO

Look for the directory that contains the `artisan` file. That directory is `APP_REPO`.

### 0b. Set all variables

```
APP_REPO      = <directory containing artisan>
TENANT_ROUTES = {APP_REPO}/routes/tenant.php
APP_SP        = {APP_REPO}/app/Providers/AppServiceProvider.php
MODULE_DIR    = {APP_REPO}/Modules/{MODULE_NAME}
MODULE_ROUTES = {MODULE_DIR}/routes/web.php
MODULE_SP     = {MODULE_DIR}/app/Providers/{MODULE_NAME}ServiceProvider.php
```

### 0c. Pre-flight checks — stop if any of these fail

- `{MODULE_DIR}` exists → if not, report error and stop
- `{MODULE_SP}` exists → if not, report error and stop
- `{TENANT_ROUTES}` contains at least one `use Modules\{MODULE_NAME}\Http\Controllers\` line → if not, report "No routes found for this module in tenant.php" and stop
- `{MODULE_ROUTES}` is readable → if not, report error and stop

---

## Step 1 — Read Everything First, Change Nothing

Read all four files completely before making any edits.

### From `{TENANT_ROUTES}` find and note:

**A. Controller import lines** — every line matching:
```
use Modules\{MODULE_NAME}\Http\Controllers\...;
```
Note each line number.

**B. Route group block** — the complete group for this module, typically:
```php
//begin::{MODULE_NAME}
Route::middleware(['auth', 'verified'])->prefix('...')->name('...')->group(function () {
    // ...
});
//end::{MODULE_NAME}
```
Note:
- The `prefix(...)` value
- The `name(...)` value
- Start line and end line of the entire block
- Every `Route::` definition inside

### From `{APP_SP}` find and note:

**C. Model import lines** — every line matching:
```
use Modules\{MODULE_NAME}\Models\...;
```

**D. Policy import lines** — every line matching:
```
use Modules\{MODULE_NAME}\Policies\...;
```

**E. Gate policy lines** — every line matching:
```php
Gate::policy(SomeClass::class, SomePolicy::class)
```
where `SomeClass` is from `Modules\{MODULE_NAME}\Models\`
**or** `SomePolicy` is from `Modules\{MODULE_NAME}\Policies\`.

Note every such line number.

### From `{MODULE_SP}` note:

- What `use` statements already exist at the top
- The exact structure of `boot()` — what calls are already inside it
- Whether a `registerPolicies()` method already exists

### From `{MODULE_ROUTES}` note:

- What routes are already defined (often just a placeholder or empty)

---

## Step 2 — Migrate Routes

### 2a. Write `{MODULE_ROUTES}`

Replace the **entire content** of `{MODULE_ROUTES}` with the following structure.
Overwrite completely — do not preserve old content.

```php
<?php

use Illuminate\Support\Facades\Route;
use Modules\{MODULE_NAME}\Http\Controllers\ControllerA;
use Modules\{MODULE_NAME}\Http\Controllers\ControllerB;
// one `use` line per controller class actually referenced in the routes below

Route::middleware(['auth', 'verified'])->prefix('{prefix}')->name('{name.}')->group(function () {

    // Every Route:: line from the extracted block — copied exactly, unchanged

});
```

**Rules:**
- `{prefix}` must be identical to what was in `{TENANT_ROUTES}` — do not change it.
- `{name.}` must be identical to what was in `{TENANT_ROUTES}` — do not change it.
- Copy every `Route::` definition **exactly** — same HTTP verb, same URI, same `->name()`, same controller action.
- Only add `use` imports for controllers from `Modules\{MODULE_NAME}`.
  If any route calls a controller from a **different** module, do NOT move that route —
  leave it in `{TENANT_ROUTES}` and add this comment next to it:
  `// NOT moved — references Modules\OtherModule\...`

### 2b. Clean `{TENANT_ROUTES}`

**Remove controller imports (Step A lines):**
Delete every `use Modules\{MODULE_NAME}\Http\Controllers\...;` line found in Step 1A.
Replace the removed lines with exactly one comment:
```php
// {MODULE_NAME} routes → Modules/{MODULE_NAME}/routes/web.php
```

Before deleting each import, grep `{TENANT_ROUTES}` for any other occurrence of that
class name. If another route in the file still uses it, keep the import — do not delete it.

**Remove route block (Step B lines):**
Delete the entire route group block — from the `//begin::` comment (or first route)
to the `//end::` comment (or closing `});`) inclusive.
Replace with exactly one comment:
```php
// {MODULE_NAME} routes → Modules/{MODULE_NAME}/routes/web.php
```

---

## Step 3 — Migrate Gate Policies

### 3a. Cross-module safety check

For each `Gate::policy(ModelX::class, PolicyY::class)` line found in Step 1E:

Search `{APP_SP}` for **any other** `Gate::policy(...)` line outside this module's
block that references `ModelX` or `PolicyY`.

- If found → this is a **cross-module reference**. Do NOT move this policy.
  Add comment on that line: `// cross-module ref — kept in AppServiceProvider`
- If not found → safe to move.

### 3b. Update `{MODULE_SP}`

Make three additions to `{MODULE_SP}`:

**1. Add `use` imports** — insert after the last existing `use` line in the file:
```php
use Illuminate\Support\Facades\Gate;
use Modules\{MODULE_NAME}\Models\ModelA;
use Modules\{MODULE_NAME}\Models\ModelB;
// ... only models that appear in the Gate::policy calls below
use Modules\{MODULE_NAME}\Policies\PolicyA;
use Modules\{MODULE_NAME}\Policies\PolicyB;
// ... only policies that appear in the Gate::policy calls below
```

**2. Add call in `boot()`** — add as the last line inside the existing `boot()` method:
```php
$this->registerPolicies();
```

**3. Add method** — insert just before `registerCommands()`:
```php
/**
 * Register Gate policies for the {MODULE_NAME} module.
 */
protected function registerPolicies(): void
{
    Gate::policy(ModelA::class, PolicyA::class);
    Gate::policy(ModelB::class, PolicyB::class);
    // ... all policies marked safe-to-move in Step 3a
}
```

### 3c. Clean `{APP_SP}`

**Remove Gate::policy lines:**
Delete every `Gate::policy(...)` line that was moved to `{MODULE_SP}`.
Replace the entire section (including its section comment header if present)
with one comment:
```php
// {MODULE_NAME} policies → Modules/{MODULE_NAME}/app/Providers/{MODULE_NAME}ServiceProvider.php
```

**Remove orphaned `use` imports:**
For each import from Steps 1C and 1D — before deleting, grep `{APP_SP}` for any other
usage of that class anywhere else in the file.
- If used elsewhere → keep the import, do not delete it.
- If not used anywhere else → delete the import line.

---

## Step 4 — Verify

Run these checks after all edits, before reporting done:

| # | Check | Pass Condition |
|---|-------|----------------|
| 1 | Route names preserved | Every `->name('x')` in `{MODULE_ROUTES}` is identical to what was in `{TENANT_ROUTES}` |
| 2 | URL prefixes preserved | `prefix(...)` and `name(...)` values are identical to the original |
| 3 | No orphan controller imports | No `use Modules\{MODULE_NAME}\Http\Controllers\` lines remain in `{TENANT_ROUTES}` (unless kept for cross-module reason with comment) |
| 4 | No duplicate routes | The same `->name('x')` does not appear in both `{TENANT_ROUTES}` and `{MODULE_ROUTES}` |
| 5 | All controller imports present | Every controller class used in `{MODULE_ROUTES}` has a `use` import at the top |
| 6 | Policy block removed | The module's `Gate::policy` section in `{APP_SP}` is replaced by a single comment |
| 7 | All model/policy imports present | Every class in `registerPolicies()` has a `use` import at the top of `{MODULE_SP}` |
| 8 | `registerPolicies()` called | `$this->registerPolicies();` exists inside `boot()` in `{MODULE_SP}` |

If any check fails — fix it before reporting done.

---

## Step 5 — Print Summary

After all changes and verifications are complete, print this summary:

```
================================================
  DONE — {MODULE_NAME}
================================================

ROUTES
  Removed from : routes/tenant.php
  Written to   : Modules/{MODULE_NAME}/routes/web.php
  Count        : {N} Route:: definitions moved

POLICIES
  Removed from  : app/Providers/AppServiceProvider.php
  Written to    : Modules/{MODULE_NAME}/app/Providers/{MODULE_NAME}ServiceProvider.php
  Moved         : {M} Gate::policy calls
  Cross-module  : {X} kept in AppServiceProvider (commented)

FILES CHANGED (stage and commit these manually):
  routes/tenant.php
  app/Providers/AppServiceProvider.php
  Modules/{MODULE_NAME}/routes/web.php
  Modules/{MODULE_NAME}/app/Providers/{MODULE_NAME}ServiceProvider.php

AFTER COMMITTING — run on your machine:
  php artisan route:clear
  php artisan route:cache
================================================
```

---

## Absolute Rules

| Rule | Detail |
|------|--------|
| 4 files only | No other file may be created, modified, or deleted |
| No git commands | Do not run git add, git commit, git checkout, or any git command |
| No migration files | `database/migrations/` is completely off-limits |
| No route renames | `->name('x')` must be copied exactly — renaming breaks `route('x')` calls everywhere |
| No URL changes | `prefix(...)` and route URIs must be copied exactly |
| No blind deletes | Every `use` deletion must be preceded by a grep confirming zero other usages |
| Cross-module stays | A `Gate::policy` involving a class from another module stays in `AppServiceProvider` |
| Stop on ambiguity | If any situation is unclear, stop and ask — do not guess |
