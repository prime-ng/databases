# Prompt: Batch-Move Module Routes & Gate Policies into Module-Owned Files

## How to Run

Open Claude Code in the Laravel project directory and paste this entire file.
**No other input is required.** The prompt will iterate through every module automatically.

---

> ### Strict Scope — Exactly 4 Files Per Module Will Be Touched
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

**The fix:** Each module owns its own routes and policies. This prompt iterates through
every module in the `Module_List`, extracts that module's routes and policies from the
central files, and places them inside the module's own provider and route file.

---

## Module_List

Process these modules **in order, one at a time**. After completing (or skipping) a
module, immediately proceed to the next one.

```
 1. Accounting
 2. Admission
 3. Billing
 4. Cafeteria
 5. Certificate
 6. Complaint
 7. Dashboard
 8. Documentation
 9. EventEngine
10. FrontOffice
11. GlobalMaster
12. Hpc
13. HrStaff
14. Inventory
15. Library
16. LmsExam
17. LmsHomework
18. LmsQuests
19. LmsQuiz
20. Notification
21. Payment
22. Prime
23. QuestionBank
24. Recommendation
25. Scheduler
26. SchoolSetup
27. SmartTimetable
28. StandardTimetable
29. StudentFee
30. StudentPortal
31. StudentProfile
32. Syllabus
33. SyllabusBooks
34. SystemConfig
35. TimetableFoundation
36. Transport
37. Vendor
```

---

## Step 0 — Resolve Paths (Run Once at Start)

### 0a. Detect APP_REPO

Look for the directory that contains the `artisan` file. That directory is `APP_REPO`.

### 0b. Set all variables

```
APP_REPO      = <directory containing artisan>
TENANT_ROUTES = {APP_REPO}/routes/tenant.php
APP_SP        = {APP_REPO}/app/Providers/AppServiceProvider.php
MODULES_DIR   = {APP_REPO}/Modules
```

Per-module variables (set these fresh for each module in the loop):
```
MODULE_DIR    = {MODULES_DIR}/{MODULE_NAME}
MODULE_ROUTES = {MODULE_DIR}/routes/web.php
MODULE_SP     = {MODULE_DIR}/app/Providers/{MODULE_NAME}ServiceProvider.php
```

### 0c. Pre-flight checks — stop the entire run if any of these fail

- `{TENANT_ROUTES}` exists and is readable
- `{APP_SP}` exists and is readable
- `{MODULES_DIR}` exists

---

## Main Loop — For Each MODULE_NAME in Module_List

For each module, execute **Step 1 through Step 5** below. Then move to the next module.

---

### Step 1 — Skip Detection (Per Module)

Before doing any work, check whether this module needs migration at all.

**1a. Check if module directory exists:**
- If `{MODULE_DIR}` does NOT exist → print `SKIP {MODULE_NAME} — module directory not found` → **next module**

**1b. Check if ServiceProvider exists:**
- If `{MODULE_SP}` does NOT exist → print `SKIP {MODULE_NAME} — ServiceProvider not found` → **next module**

**1c. Check for routes in tenant.php:**
Search `{TENANT_ROUTES}` for any line matching:
```
use Modules\{MODULE_NAME}\Http\Controllers\
```
- Count the matches → store as `ROUTE_IMPORT_COUNT`

**1d. Check for policies in AppServiceProvider:**
Search `{APP_SP}` for any line matching:
```
use Modules\{MODULE_NAME}\Models\
```
or:
```
use Modules\{MODULE_NAME}\Policies\
```
- Count the matches → store as `POLICY_IMPORT_COUNT`

**1e. Skip decision:**

| ROUTE_IMPORT_COUNT | POLICY_IMPORT_COUNT | Action |
|--------------------|---------------------|--------|
| 0 | 0 | Print `SKIP {MODULE_NAME} — routes and policies already migrated (or none exist)` → **next module** |
| > 0 | 0 | Run Step 2 (routes only), skip Step 3. Then Step 4 and Step 5. |
| 0 | > 0 | Skip Step 2, run Step 3 (policies only). Then Step 4 and Step 5. |
| > 0 | > 0 | Run Step 2 and Step 3. Then Step 4 and Step 5. |

---

### Step 2 — Read Everything First, Change Nothing

Read all relevant files completely before making any edits.

#### From `{TENANT_ROUTES}` find and note:

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

#### From `{APP_SP}` find and note (if POLICY_IMPORT_COUNT > 0):

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

#### From `{MODULE_SP}` note:

- What `use` statements already exist at the top
- The exact structure of `boot()` — what calls are already inside it
- Whether a `registerPolicies()` method already exists

#### From `{MODULE_ROUTES}` note:

- What routes are already defined (often just a placeholder or empty)

---

### Step 3 — Migrate Routes

> **Skip this step entirely if ROUTE_IMPORT_COUNT = 0.**

#### 3a. Write `{MODULE_ROUTES}`

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

#### 3b. Clean `{TENANT_ROUTES}`

**Remove controller imports (Step A lines):**
Delete every `use Modules\{MODULE_NAME}\Http\Controllers\...;` line found in Step 2A.
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

### Step 4 — Migrate Gate Policies

> **Skip this step entirely if POLICY_IMPORT_COUNT = 0.**

#### 4a. Cross-module safety check

For each `Gate::policy(ModelX::class, PolicyY::class)` line found in Step 2E:

Search `{APP_SP}` for **any other** `Gate::policy(...)` line outside this module's
block that references `ModelX` or `PolicyY`.

- If found → this is a **cross-module reference**. Do NOT move this policy.
  Add comment on that line: `// cross-module ref — kept in AppServiceProvider`
- If not found → safe to move.

#### 4b. Update `{MODULE_SP}`

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
    // ... all policies marked safe-to-move in Step 4a
}
```

#### 4c. Clean `{APP_SP}`

**Remove Gate::policy lines:**
Delete every `Gate::policy(...)` line that was moved to `{MODULE_SP}`.
Replace the entire section (including its section comment header if present)
with one comment:
```php
// {MODULE_NAME} policies → Modules/{MODULE_NAME}/app/Providers/{MODULE_NAME}ServiceProvider.php
```

**Remove orphaned `use` imports:**
For each import from Steps 2C and 2D — before deleting, grep `{APP_SP}` for any other
usage of that class anywhere else in the file.
- If used elsewhere → keep the import, do not delete it.
- If not used anywhere else → delete the import line.

---

### Step 5 — Verify (Per Module)

Run these checks after all edits for the current module, before proceeding to the next:

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

Checks 1-5 apply only if routes were migrated (Step 3 ran).
Checks 6-8 apply only if policies were migrated (Step 4 ran).

If any check fails — fix it before proceeding to the next module.

---

### Step 6 — Print Module Summary

After completing (or skipping) each module, print a brief status line:

**If skipped:**
```
[{N}/{TOTAL}] SKIP {MODULE_NAME} — {reason}
```

**If migrated:**
```
[{N}/{TOTAL}] DONE {MODULE_NAME} — {R} routes moved, {P} policies moved, {X} cross-module kept
```

Then immediately proceed to the next module in the list.

---

## After All Modules — Final Summary

After the last module is processed, print this comprehensive summary:

```
================================================================
  BATCH MIGRATION COMPLETE
================================================================

MODULES PROCESSED : {TOTAL}
MODULES MIGRATED  : {MIGRATED_COUNT}
MODULES SKIPPED   : {SKIPPED_COUNT}

MIGRATED:
  {MODULE_NAME_1} — {R} routes, {P} policies
  {MODULE_NAME_2} — {R} routes, {P} policies
  ...

SKIPPED:
  {MODULE_NAME_X} — {reason}
  {MODULE_NAME_Y} — {reason}
  ...

CROSS-MODULE POLICIES KEPT IN AppServiceProvider:
  {list each Gate::policy line that was NOT moved, with reason}

FILES CHANGED (stage and commit these manually):
  routes/tenant.php
  app/Providers/AppServiceProvider.php
  Modules/{MODULE_1}/routes/web.php
  Modules/{MODULE_1}/app/Providers/{MODULE_1}ServiceProvider.php
  ... (list only modules that were actually changed)

AFTER COMMITTING — run on your machine:
  php artisan route:clear
  php artisan route:cache
================================================================
```

---

## Absolute Rules

| Rule | Detail |
|------|--------|
| 4 files per module max | No other file may be created, modified, or deleted |
| No git commands | Do not run git add, git commit, git checkout, or any git command |
| No migration files | `database/migrations/` is completely off-limits |
| No route renames | `->name('x')` must be copied exactly — renaming breaks `route('x')` calls everywhere |
| No URL changes | `prefix(...)` and route URIs must be copied exactly |
| No blind deletes | Every `use` deletion must be preceded by a grep confirming zero other usages |
| Cross-module stays | A `Gate::policy` involving a class from another module stays in `AppServiceProvider` |
| Skip if done | If a module's routes and policies are already migrated, skip it — do not duplicate |
| Auto-continue | After completing or skipping a module, immediately proceed to the next — do not stop to ask |
| Stop on ambiguity | If any situation is unclear for a specific module, skip that module with reason "ambiguous — needs manual review" and continue to the next |
| Re-read after each module | Re-read `{TENANT_ROUTES}` and `{APP_SP}` at the start of each module iteration, since the previous module's edits changed these files |
