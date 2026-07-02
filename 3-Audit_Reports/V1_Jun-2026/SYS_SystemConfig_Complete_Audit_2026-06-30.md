# SystemConfig Module — Mode X Complete Audit
**Date:** 2026-06-30
**Auditor:** Technical Auditor Agent (Mode X — 12-Layer A+B+C+G+D Protocol)
**Module:** SYS — SystemConfig
**Module Path:** `Modules/SystemConfig/`
**Health Score:** 40 / 100 — P0-CAPPED
**Deploy Gate:** ❌ NO-GO

---

## Module Architecture Context

| Property | Value |
|---|---|
| Type | Central-only (prime domain only, NOT tenant-scoped) |
| Databases | `prime_db` (`sys_*`) + `global_db` (`glb_menus`, `glb_translations`) |
| EnsureTenantHasModule | N/A — central module, no tenant scoping needed |
| Super Admin enforcement | Required at every method (current state: inconsistent) |
| Routes (module) | `Modules/SystemConfig/routes/web.php` (central) + `routes/api.php` |
| Routes (tenant context) | `routes/tenant.php` lines 95–148 (SYS controllers registered here too) |
| Controllers | 11 total |
| Models | 8 total |
| FormRequests | 4 total |
| Policies | 2 total (`MenuPolicy`, `SystemConfigPolicy`) |
| Services | 2 total |
| Jobs | 1 (`RunBackupJob`) |
| Notifications | 2 |
| Blade Views | 36 total |

---

## Summary of Findings

| Severity | Count | IDs |
|---|---|---|
| P0 | 5 | SEC-SYS-02, SEC-SYS-28, SEC-SYS-29, SEC-SYS-30, ARCH-SYS-05 |
| P1 | 8 | SEC-SYS-03, BUG-SYS-04, BUG-SYS-08, BUG-SYS-16, SEC-SYS-22, PERM-SYS-01, ARCH-SYS-06, AUD-SYS-01 |
| P2 | 4 | SEC-SYS-01 (downgraded), BUG-SYS-14, BUG-SYS-15, GAP-SYS-13 |
| P3 | 1 | DAT-SYS-01 |
| Cleared | 2 | BUG-SYS-06, BUG-SYS-07 |

**P0 presence activates hard cap: Health capped at 40/100. Deploy: NO-GO.**

---

## P0 Findings — Critical / Deploy Blockers

---

### SEC-SYS-02 — MenuSyncController Auth Commented Out [CONFIRMED FROM BA]

**File:** `Modules/SystemConfig/app/Http/Controllers/MenuSyncController.php:74–79`

**Evidence (live code):**
```php
$user = auth()->user();
// if (!$user || !$user->hasRole('Super Admin')) {
//     return response()->json([
//         'success' => false,
//         'message' => 'Unauthorized. Only Super Admin can sync menus.',
//     ], 403);
// }
```

**Route:** `GET /system-config/sync-menus` (middleware: `auth+verified` only)

**Impact:** Any authenticated + email-verified user (teacher, parent, student) can call this endpoint.
The sync operation at lines 84–91:
- Sets `FOREIGN_KEY_CHECKS=0`
- Truncates `glb_menu_module_jnt` (global junction table)
- Calls `Menu::where('menu_for', 'tenant')->forceDelete()` — permanently deletes ALL tenant menus across the entire platform
- Rebuilds menus from code

This is **platform-wide menu destruction**, affecting every tenant school simultaneously.

**Fix:** Uncomment lines 75–79. Or replace with `Gate::authorize('system-config.menu.sync')` and add `system-config.menu.sync` to Super Admin permissions seeder.

---

### SEC-SYS-28 — BackupController Zero Gate + DB Dump Download Exposed [NEW]

**File:** `Modules/SystemConfig/app/Http/Controllers/BackupController.php`

**Evidence:** ZERO Gate::authorize on all 6 methods:
- `index()` — lists all backup runs
- `create()` — backup creation form
- `store()` — triggers backup job (dispatches RunBackupJob)
- `download(BackupRun $run)` — **downloads ZIP file from local storage**
- `destroy(BackupRun $run)` — deletes backup run record
- `statuses()` — AJAX status polling

Only `auth+verified` middleware guards these routes.

**Most severe impact — download():** Any authenticated teacher or parent can download complete database backup ZIP files containing:
- All `prime_db` data (billing, users, settings, system config)
- All `global_db` data (menus, translations)
- All tenant databases included in the backup scope (student records, fees, PII)

This is a **direct data breach vector** requiring no privilege escalation — only a valid user account.

Additionally, any user can trigger backup jobs (`store()`) consuming server resources, or delete backup records (`destroy()`) to cover tracks post-breach.

**Fix:**
```php
// All methods:
Gate::authorize('system-config.backup.viewAny');   // index, statuses
Gate::authorize('system-config.backup.download');  // download
Gate::authorize('system-config.backup.create');    // create, store
Gate::authorize('system-config.backup.delete');    // destroy
```
Add corresponding permissions to Super Admin seeder.

---

### SEC-SYS-29 — BackupScheduleController Zero Gate [NEW]

**File:** `Modules/SystemConfig/app/Http/Controllers/BackupScheduleController.php`

**Evidence:** ZERO Gate::authorize on all 6 methods (index, create, store, edit, update, destroy, toggleStatus).
Only `auth+verified` middleware guards these routes.

**Impact:**
- Any authenticated user can create backup schedules (potential resource exhaustion — schedule hourly backups)
- Any authenticated user can disable/delete existing backup schedules (backup sabotage — organization loses backup protection)
- Any authenticated user can modify backup scope (add/remove tenant DBs from backup)

**Fix:** Add `Gate::authorize('system-config.backup-schedule.*')` to all methods. Add to Super Admin seeder.

---

### SEC-SYS-30 — SQL Injection + Ungated AJAX Endpoint in TenantDropdownController::getColumns() [NEW]

**File:** `Modules/SystemConfig/app/Http/Controllers/TenantDropdownController.php:219–234`

**Evidence:**
```php
public function getColumns(Request $request): JsonResponse
{
    // NO Gate::authorize here
    try {
        $columns = DB::connection('tenant')
            ->select("SHOW COLUMNS FROM {$request->table_name}");
        // ...
    }
}
```

`$request->table_name` is raw unsanitized user input injected directly into a SQL string.

**Impact:**
1. **No authorization check** — any auth+verified user can call this AJAX endpoint
2. **SQL injection** — attacker can pass crafted `table_name` values:
   - `valid_table; DROP TABLE sys_settings-- ` → destructive SQL
   - Sub-select injections depending on MySQL version and connector behavior
   - Even without DDL rights, the endpoint enumerates DB schema for any table name passed
3. The connection is `DB::connection('tenant')` called from a central context where no tenant is initialized — but this means the injection targets whatever DB connection happens to resolve (potentially prime_db or global_db depending on Laravel's fallback behavior)

**Fix:**
```php
// Step 1: Add Gate
Gate::authorize('system-config.dropdown.manage');

// Step 2: Whitelist table names
$allowedTables = ['sys_dropdowns', 'sys_settings']; // enumerate known safe tables
if (!in_array($request->table_name, $allowedTables, true)) {
    return response()->json(['error' => 'Invalid table'], 422);
}
$columns = DB::connection('tenant')->select('SHOW COLUMNS FROM ' . $request->table_name);
```

---

### ARCH-SYS-05 — Duplicate Setting Model on Same Table [CONFIRMED FROM BA]

**Files:**
- `Modules/Prime/Models/Setting.php` — `$table = 'sys_settings'`, likely uses prime connection
- `Modules/SystemConfig/Models/Setting.php` — `$table = 'sys_settings'`

Both models map to the same table. Any code that uses `use Modules\Prime\Models\Setting` vs `use Modules\SystemConfig\Models\Setting` may behave differently (different `$fillable`, different events, different observers, different `$connection` if either specifies one).

**Impact:** Silent behavioral inconsistency depending on which model is imported. If one model is missing a field in `$fillable`, mass assignment may silently drop data. If `$connection` differs between models, queries hit different DBs for the same table.

**Fix:** Consolidate to one canonical `Setting` model in `Modules\SystemConfig\Models\Setting`. Add `@deprecated` docblock and `use` alias in `Modules\Prime\Models\Setting` pointing to the SystemConfig model. Remove the Prime model in the next major release.

---

## P1 Findings

---

### SEC-SYS-03 — MenuController Stubs Missing Gate [CONFIRMED]

**File:** `Modules/SystemConfig/app/Http/Controllers/MenuController.php`

`create()` (lines 59–62) and `destroy()` (lines 164–167) are empty stubs returning null/redirect with no Gate::authorize. While these are scaffolded stubs with no real logic, they create exploitable routes that return unexpected null responses to unauthorized users — no 403 is issued.

**Fix:** Add stub guard or implement properly:
```php
public function create(): Response {
    Gate::authorize('system-config.menu.create');
    // ...
}
```

---

### BUG-SYS-04 — MenuController::update() Mass Assignment with Immutable Field [CONFIRMED]

**File:** `Modules/SystemConfig/app/Http/Controllers/MenuController.php:127`

```php
$menu->update($request->all());
```

`request->all()` passes every form field including `code` (the slug/identifier used for permission keys and cross-module references). The `code` field is intended to be immutable after creation. A user with `system-config.menu.update` permission can overwrite the menu code, breaking all `Gate::authorize('system-config.menu.{oldCode}')` permission checks across the platform.

**Fix:** Use `$request->validated()` with a `MenuRequest` that excludes `code` from the updateable fields.

---

### BUG-SYS-08 — MenuPolicy Uses Wrong Permission Prefix (Dead Code) [CONFIRMED]

**File:** `Modules/SystemConfig/app/Policies/MenuPolicy.php`

All 7 policy methods use `prime.menu.*` prefix:
```php
public function viewAny(User $user): bool {
    return $user->can('prime.menu.viewAny');
}
```

**MenuController** calls `Gate::authorize('system-config.menu.*')` directly (bypassing the policy). The policy is never consulted and is effectively dead code. Any developer relying on the policy for access control will be misled — the policy checks permissions that may not be seeded or enforced.

**Fix:** Update all 7 MenuPolicy methods to use `system-config.menu.*` prefix. Register with `Gate::policy(Menu::class, MenuPolicy::class)` in ServiceProvider (already registered — the prefix mismatch is the only issue).

---

### BUG-SYS-16 — MenuController::forceDelete() No Gate [CONFIRMED]

**File:** `Modules/SystemConfig/app/Http/Controllers/MenuController.php:187–198`

`forceDelete()` has live logic (`$menu->forceDelete()`) but NO Gate::authorize. Unlike the stub methods that return nothing, this method permanently deletes menu records. Any auth+verified user who can reach the route can force-delete menu items with no authorization check.

**Fix:** Add `Gate::authorize('system-config.menu.forceDelete');` as the first line.

---

### SEC-SYS-22 — SettingController Wrong Permission Prefix [CONFIRMED]

**File:** `Modules/SystemConfig/app/Http/Controllers/SettingController.php:19, 45, 57`

Uses `tenant.setting.*` prefix (e.g., `Gate::authorize('tenant.setting.viewAny')`). SYS is a **central module** — the correct prefix is `system-config.setting.*` or `system-config.settings.*`. The `tenant.setting.*` permission string is unlikely to be seeded for central-domain users. Actual authorization outcome: **403 for Super Admin** or **pass for any role with `tenant.setting.*`** (undefined behavior depending on which permissions are seeded).

**Fix:** Change all 3 Gate::authorize calls to `system-config.settings.*`.

---

### PERM-SYS-01 — Platform-Wide Permission Prefix Inconsistency in 5 Controllers [CONFIRMED]

All five "Tenant" controllers within SYS module use `tenant.*` prefixes in a central module:

| Controller | Incorrect Prefix Used |
|---|---|
| TenantActivityLogController | `tenant.activity-log.*` |
| TenantMediaStoreController | `tenant.setting.*` (also wrong resource) |
| TenantLocationController | `tenant.geography.*` |
| TenantDropdownController | `tenant.dropdown.*` |
| SettingController | `tenant.setting.*` |

Correct prefix for all: `system-config.*`. The `tenant.*` namespace is for tenant-scoped modules (STT, SLB, etc.). Using it in a central module means:
1. The permissions may not be seeded for central-domain Super Admin users
2. Tenant users may inadvertently hold these permissions through wildcard grants
3. Future developers cannot determine module ownership from permission strings

**Fix:** Rename all permission checks to `system-config.*` namespace. Update seeders accordingly.

---

### ARCH-SYS-06 — TenantDropdownController::create() Calls tenant DB in Central Context [CONFIRMED]

**File:** `Modules/SystemConfig/app/Http/Controllers/TenantDropdownController.php:75`

```php
$tables = DB::connection('tenant')->select('SHOW TABLES');
```

Called in a central route (no tenancy middleware), where `tenant` connection is not initialized. Laravel will throw a `PDOException` or resolve to the wrong DB. This is caught in a try/catch that returns an empty array — **the form silently shows no table options** with no error feedback.

**Fix:** Either move TenantDropdownController to tenant routes with proper tenancy middleware, or replace the dynamic table lookup with a hardcoded whitelist of allowed tenant tables.

---

### AUD-SYS-01 — activityLog Wrong Argument Order in SettingController [CONFIRMED]

**File:** `Modules/SystemConfig/app/Http/Controllers/SettingController.php:67`

```php
activityLog('updated', $setting, ['key' => $setting->key]);
```

The `activityLog()` helper signature is `activityLog($subject, $event, $properties)`. Here, the string `'updated'` is passed as the subject (should be the Eloquent model) and `$setting` as the event (should be a string). This produces corrupted activity log entries with no traceable subject model.

**Fix:** `activityLog($setting, 'updated', ['key' => $setting->key]);`

---

## P2 Findings

---

### SEC-SYS-01 — SystemConfigController Stubs (Downgraded from BA P0) [SCOPE REDUCED]

**File:** `Modules/SystemConfig/app/Http/Controllers/SystemConfigController.php`

All 7 CRUD methods are empty stubs with ZERO Gate::authorize. However, only `dashboard` (index) is actively routed — it returns a stub view (no sensitive data rendered). The other 6 methods (create, store, show, edit, update, destroy) are NOT registered in any route file and are unreachable. The API resource in `Modules/SystemConfig/routes/api.php` is also not loaded by the module's RouteServiceProvider.

**Downgrade rationale:** No live route exploit for the 6 CRUD stubs. The `dashboard` route returns an empty view — low risk. If routes are added in future, missing Gate becomes P0 immediately.

**Fix:** Add `Gate::authorize('system-config.dashboard.viewAny')` to `index()`. Add `abort(501)` stubs to the 6 unimplemented methods so they return proper Not Implemented responses if accidentally routed.

---

### BUG-SYS-14 — trashedMenu() No Gate + Wrong View Name [CONFIRMED]

**File:** `Modules/SystemConfig/app/Http/Controllers/MenuController.php:171–177`

1. No `Gate::authorize` on `trashedMenu()`
2. Returns `view('systemconfig.menu.trash', ...)` — dot notation references the global view namespace. Correct Laravel module view notation is `view('systemconfig::menu.trash', ...)` (double-colon)
3. `menu/trash.blade.php` does not exist in the module's views directory

**Result:** Any authenticated user accessing this route gets a 500 ViewNotFoundException. The missing Gate is irrelevant in practice since the route always throws, but the underlying authorization gap is a latent bug.

**Fix:** Add Gate, fix to `systemconfig::menu.trash`, create the missing view.

---

### BUG-SYS-15 — Missing menu/trash.blade.php View [CONFIRMED]

Companion to BUG-SYS-14. The trash list view is referenced but does not exist. Creates a 500 on the trashed menus route.

---

### GAP-SYS-13 — SystemConfigPolicy Not Registered [CONFIRMED]

**File:** `Modules/SystemConfig/app/Providers/SystemConfigServiceProvider.php:50`

`registerPolicies()` only registers `Gate::policy(Menu::class, MenuPolicy::class)`. `SystemConfigPolicy` exists in the module but is never registered. All model-binding authorization that would route through `SystemConfigPolicy` bypasses the policy entirely.

---

## P3 Findings

---

### DAT-SYS-01 — D30 Pattern: 3 of 4 FormRequests Return authorize()=true

| FormRequest | authorize() | Status |
|---|---|---|
| TenantDropdownRequest | `return true;` | D30 — no authorization |
| StoreBackupRequest | `return true;` | D30 — no authorization |
| StoreBackupScheduleRequest | `return true;` | D30 — no authorization |
| MenuRequest | contains `authorize()` method | Requires verification |

For SYS (central module), the D30 pattern is partially mitigated by Gate::authorize calls in the controllers for some methods — but controllers that lack Gate calls (BackupController, BackupScheduleController) have no defense-in-depth fallback.

---

## Cleared / Stale BA Findings

| ID | BA Finding | Status |
|---|---|---|
| BUG-SYS-06 | SettingController wrong table in validation / validates wrong fields | ✅ CLEARED — update() correctly validates only `value` field with `max:1000`; no extraneous fields |
| BUG-SYS-07 | store() returns raw $request data | ✅ CLEARED — no store() method exists in SettingController; only index/edit/update are implemented |

---

## Verified Good

| Item | Finding |
|---|---|
| RunBackupJob | Correct ShouldQueue implementation; active-backup guard (only one at a time); disk space check (500MB minimum); `failed()` handler notifies user; dynamically registers tenant DB connections for scope — no tenancy re-init needed (central operation) |
| MenuController CRUD | index/store/edit/update/updateMenu all have correct `Gate::authorize('system-config.menu.*')` calls |
| MenuController::store() | Uses `$request->validated()` — correct, unlike update() |
| TenantDropdownController CRUD | All CRUD methods (create/store/edit/update/destroy/trash/restore/toggleStatus) have Gate::authorize — only getColumns() is ungated |
| TenantLocationController | All 20+ country/state/district/city CRUD methods have Gate::authorize calls |
| Blade Views | 36 views; no obvious unescaped `{!! user_input !!}` patterns found in key views |
| BackupJob disk check | Prevents backup runs when disk < 500MB free — production-safe guard |

---

## Systemic Pattern Scorecard (SYS)

| Pattern | Status | Notes |
|---|---|---|
| D30: FormRequest authorize()=true | CONFIRMED | 3/4 FormRequests affected |
| D29: ENUM columns | N/A | SYS uses key-value sys_settings — 0 ENUM cols |
| SEC-PLATFORM-003: EnsureTenantHasModule absent | N/A | Central module — not applicable |
| PERM-SYS-01: Permission prefix chaos | CONFIRMED | 5 controllers using wrong `tenant.*` prefix |
| ARCH-SLK-01: Cross-layer model import | N/A | SYS does not import from wrong layer |
| Duplicate Gate::policy kill | N/A | Only 1 policy registration; MenuPolicy dead for different reason (prefix mismatch) |
| activityLog argument order | CONFIRMED (new) | SettingController line 67; also seen in other modules |

---

## Health Score Breakdown

| Dimension | Score | Notes |
|---|---|---|
| Security Posture | 10/35 | P0×5: SEC-SYS-02 (menu wipe), SEC-SYS-28 (DB dump download), SEC-SYS-29 (backup schedule), SEC-SYS-30 (SQL injection), ARCH-SYS-05 |
| Data Integrity | 20/25 | No ENUM cols; ARCH-SYS-05 dual-model risk; BUG-SYS-04 mass assignment |
| Code Quality | 10/20 | MenuPolicy dead code; permission prefix chaos; stubs; wrong view notation |
| Gap Coverage | 10/20 | Multiple methods ungated; SystemConfigPolicy unregistered |
| **Raw Total** | **50/100** | |
| **P0 Cap Applied** | **40/100** | Hard cap: any P0 present |

**Final Health Score: 40 / 100 — NO-GO**

---

## Fix Priority (Ordered for Sprint)

**Sprint 0 — Immediate (before any deploy):**
1. **SEC-SYS-28** — Add Gate to all BackupController methods. The download() route is a live data breach vector. (2h)
2. **SEC-SYS-02** — Uncomment auth check in MenuSyncController::sync(). (15min)
3. **SEC-SYS-30** — Add Gate + table whitelist to TenantDropdownController::getColumns(). (1h)
4. **SEC-SYS-29** — Add Gate to all BackupScheduleController methods. (2h)

**Sprint 1 — High Priority:**
5. **PERM-SYS-01** — Rename all 5 controllers' permission prefixes from `tenant.*` to `system-config.*`; update seeders. (4h)
6. **BUG-SYS-16** — Add Gate to MenuController::forceDelete(). (15min)
7. **BUG-SYS-04** — Replace `$request->all()` with `$request->validated()` in MenuController::update(). (30min)
8. **BUG-SYS-08** — Fix MenuPolicy prefix from `prime.menu.*` to `system-config.menu.*`. (30min)

**Sprint 2 — Medium Priority:**
9. **ARCH-SYS-05** — Consolidate duplicate Setting models. (2h)
10. **ARCH-SYS-06** — Fix TenantDropdownController context (tenant routes vs central routes). (3h)
11. **AUD-SYS-01** — Fix activityLog argument order in SettingController. (15min)
12. **GAP-SYS-13** — Register SystemConfigPolicy in ServiceProvider. (15min)
13. **BUG-SYS-14/15** — Fix trashedMenu() Gate + view notation + create trash.blade.php. (2h)

**Sprint 3 — Low Priority:**
14. **DAT-SYS-01** — Add Gate-delegating authorize() to all FormRequests. (1h)
15. **SEC-SYS-01** — Add abort(501) to stub methods; Gate to dashboard. (1h)
