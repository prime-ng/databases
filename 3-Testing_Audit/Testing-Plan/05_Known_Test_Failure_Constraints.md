# Known Test-Failure Constraints — RULE CARD (MUST FOLLOW)

**The agent MUST read this Rule Card before generating any PHP test, and obey every line.** This is the terse operative list. The full rationale + code snippets + file/line *Evidence:* for each rule live in **`05a_Constraints_Evidence_Appendix.md`** — read a rule's appendix entry **only** when you need its justification or an exact snippet (do NOT read the whole appendix every run; that is the token waste this split removes).

**Golden principle:** these guard against *false* failures (environmental/harness, not real defects). When a rule conflicts with what you see in the real source at generation time, **trust the source and note the discrepancy**. `⚠️` = inverts peer-agent lore (that lore is FALSE here). Rules verified vs codebase 2026-07-09 + test-quality reviews 2026-07-14.

---

## A. Tenancy & test style
1. **Mirror the module's committed sibling for test style + tenancy helper** (Dusk `initializeTenantContext()` vs HTTP `initTenant()`+`DatabaseMigrations`+`actingAs()`; `DuskTestCase` gives no init). **ONE style per file** — never mix `browse()` and `actingAs()->post()`; if HTTP, init tenant (#2) BEFORE `actingAs()`.
2. **Resolve tenant via `Modules\Prime\Models\Domain`** → `tenancy()->initialize($domain->tenant)`. Never `artisan('tenancy:init')`; never `\App\Models\Tenant` (use `Modules\Prime\Models\Tenant`, table `prm_tenant`).
3. **Guard teardown:** `if (function_exists('tenancy') && tenancy()->initialized) tenancy()->end();`.
4. **Prime-side vs tenant-side:** central `prm_*`/`sys_*` (`prime_db`) = NO tenant init; module-prefixed tables = tenant-side (init required). Decide from DDL header + prefix; emit tenancy scaffolding only tenant-side.

## B. Users & factories
5. **Use `App\Models\User` + `User::factory()->create([...])`** (exists in the `prime_testing` runner, bound to `sys_users`) to match the sibling.
6. **Use a module User model** (`Modules\Prime\Models\User` / `Modules\SchoolSetup\Models\User`) ONLY when a Service/Policy type-hints it; else stay on `App\Models\User`.
7. ⚠️ **`password` IS fillable** (cast `hashed`) — create via factory/mass-assignment.
8. **`sys_users` NOT-NULL-no-default cols you MUST supply on a hand-built `User::create`:** `emp_code`(≤20, UNIQUE), `short_name`(≤30), `prefered_language`(FK→glb_languages), `user_type` ENUM (where required); add `academic_session_id` where the table needs it. Prefer the factory. ⚠️ `user_type` DOES exist.
9. **`emp_code` ≤ 20 chars** — suffix `'_'.uniqid()` (~14), never `uniqid().'_'.date('YmdHis')` (overflows).
10. **`glb_languages` is a VIEW** onto global_master — ensure a valid language id exists before creating users or the FK insert fails.

## C. Soft-delete, media & typed props
11. **`forceDelete()` on `InteractsWithMedia` models hits `sys_media`** (not default `media`), which may be ABSENT in the test DB → guard media ops in `try/catch`; note `sys_media` as an env prerequisite in the Validation Report; never edit `prime_testing`.
12. **`withTrashed()/onlyTrashed()/forceDelete()` ONLY if the model uses `SoftDeletes`** (verify via `class_uses_recursive`); else document the gap, don't add the trait.
13. **Initialize all typed properties** (`private ?User $userA = null;`) — teardown accesses them.

## D. Assertions & HTTP
14. **Dusk `Browser` has NO `assertStatus()` and no `.post/.put/.delete`** — use Laravel HTTP test methods (`getJson/postJson/...` → `assertStatus/assertForbidden/...`) for status/endpoints; verify browser flows via `assertPathBeginsWith`/`assertSee`/banners.
15. **Authenticate (`actingAs($user)`) before validation/negative POSTs** — else redirect to login, no validation errors.
16. **Pass outer vars into browse closures:** `browse(function (Browser $b) use ($record) {...})`.
17. **Assert schema types with `assertStringContainsString('int',...)`** (or accepted-types array), never `assertEquals('int unsigned',...)` — MySQL 8 variance.
18. **Keep your OWN fixture data within column limits** (TINYINT ≤127; ENUM exact & case-sensitive vs DDL; VARCHAR within size). Complement of #45 (which deliberately EXCEEDS to test rejection).

## E. Environment prerequisites
19. ⚠️ **Target module must be ENABLED** in `prime_testing/modules_statuses.json` (most are `false`) or all routes 404 — document as env prereq, not a code fix.
20. **`APP_ENV=testing` for Dusk** (bypasses CSRF, else 419) — the runner sets it.
21. **Prime/central features run on `http://127.0.0.1:8000`, NOT `test.localhost`** — extend the module's central base (e.g. `BillingDuskTestCase`) + its `authenticateCentral()/centralUrl()`, not tenant `DUSK_TENANT_URL`/`initializeTenantContext()`.
22. **Module-local base classes are filename↔classname-mismatched, resolved via `preload.php` `class_alias`** — mirror the sibling's `use ...\XDuskTestCase; extends XDuskTestCase` verbatim; `php -l` passes, alias resolves at runtime.
23. **A module's `routes/api.php` may be UNregistered** (`RouteServiceProvider::map()` may call only `mapWebRoutes()`) — verify with `Route::has()`/`method_exists()`; accept dead-route set `{401,403,404,405,500}`.
24. **Prime/central WEB routes live in app `prime_ai/routes/web.php`,** not the module's (often-empty) `routes/web.php` — grep the app file, assert `Route::has('<group>.<name>')`.
25. **`activityLog()` routes by tenancy:** prime/central (tenancy not init) → `sys_central_activity_logs` (conn `mysql`, no consolidated DDL — assert via `Schema::hasTable`+model `$fillable`); tenant-side → `activity_logs`. Assert the right sink.
26. **A module's own `database/migrations/` may be EMPTY** — real tenant migrations in `prime_ai/database/migrations/tenant/`; derive schema truth from live `Schema::hasTable/hasColumns`+`SHOW INDEX`, not a module-local migration file.
27. **A "rename X to Y" migration may be a no-op** — read the BODY + model `$table`, not the filename (e.g. runtime table is `sys_dropdown_table`, not `sys_dropdowns`).
28. **Some `glb_*` models bind to connection `global_master_mysql`** (DB `global_master`) — assert via `Schema::connection('global_master_mysql')` / `Model::on(...)`; consolidated DDL can lag (fail-soft `hasColumn`).
29. **The runner has NO app `Modules/*` source on disk** (autoloaded only) — to read raw source TEXT resolve the app-repo path (`env('MAIN_PROJECT_PATH')` → `../prime_ai/...`) and fail-soft `markTestSkipped` if unreadable; `class_exists`/`Route::has` still work directly.
30. **Assert soft-delete & GENERATED columns against the LIVE schema** (`Schema::hasColumn`/`information_schema`), never the DDL file — the `deleted_at` column and the `SoftDeletes` trait can disagree (assert INDEPENDENTLY, report mismatch); don't add trait/generated col in the test.
31. **`Gate::before` grants Super Admin ALL abilities** — authorization NEGATIVES must use a fresh NON-super-admin (clear `is_super_admin`/`super_admin_flag`, `syncRoles([])`/`syncPermissions([])`) or they FALSE-PASS; probe observed status vs a documented set; verify "commented-out gate" claims against current source.
32. **To read real APP source TEXT from the runner, resolve the file via reflection** — `(new \ReflectionClass(SomeController::class))->getFileName()` (base_path = runner, not `prime_ai`); `dirname($file,4/6)` for module/app root; wrap in try/catch + `markTestSkipped`.

## F. Assertion completeness & test hygiene *(2026-07-14 review)*
33. **BANNED: `addToAssertionCount(1)` / empty method bodies** — every test has ≥1 real assertion, or `markTestIncomplete/Skipped`. Negatives assert the observed outcome (403/see/DB row), not "visited the page".
34. **Real Laravel-12 methods only:** `hasCast()` not `isCasted()`; NO `->isActive()` instance method (use scope `Model::active()` or read the attribute). Verify a method exists before using it.
35. **`->refresh()` after `->create()`** before asserting DB-populated values (defaults/computed/trigger); passed-in attributes need no refresh.
36. **`assertGreaterThanOrEqual()` (not `assertEquals`) for seed/reference counts** — suites don't all reset between tests.
37. **Permission negatives:** after revoke/sync call `app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions()`, then assert 403 (HTTP method) / hidden control; use a non-super-admin (#31).
38. **Clean up every created record** — the sibling's `DatabaseMigrations`/`RefreshDatabase`, or an unconditional `try/finally` teardown (keep the `try{forceDelete}catch` guard, #11/#12).
39. **Real browser AJAX must send `X-CSRF-TOKEN` + `X-Requested-With: XMLHttpRequest`;** prefer HTTP test methods for endpoints (#14). CSRF is bypassed under testing env (#20), but include the headers anyway.
40. **Never hand-write URL paths or selectors** — derive paths from `route:list`/module routes/`Route::has()` (mind the module prefix!) and selectors/labels/field-names from the real Blade (element type, button text). Restates HARD RULE #1; #1 mass-failure cause.
41. **Infra failures are NOT test-code bugs** — assert tolerantly, document as prereqs, never edit `prime_testing`: validation 500-vs-422 → assert `{422,500}`; stale route cache → note `route:clear` prereq; ChromeDriver curl timeout → `retry()` + note version alignment, never assert on it.
42. **Copy the sibling's private helper library VERBATIM** (don't paraphrase) so fixes propagate; prefer HTTP methods over a raw-cURL status fallback. *(Shared-trait extraction = a maintainer design decision, not adopted mid-generation — see v3.)*

## G. DDL-derived coverage obligations *(2026-07-14 batch 2 — GENERATE these tests; derive from the DDL, not the form)*
> For every "app rejects it" assertion: tolerate 500-vs-422 (#41) and DB-or-FormRequest enforcement — assert the **observed outcome / tolerant set**, never a brittle `422`; assert schema truth vs the **LIVE** schema where the DDL lags (#28/#30); one-layer-only enforcement → `DEV-###` via the Cross-Reference scan, don't "fix" it in the test.
43. **Every DDL `UNIQUE` column/composite key → a duplicate-rejection test** (create one, attempt the same value(s), assert refused; composite = vary only keyed cols). Prove uniqueness, don't assume it.
44. **Every NOT-NULL-no-default column → a missing-value negative** asserting rejection; representative nullable cols → an omitted-value positive asserting success. DDL-vs-FormRequest `required` divergence → `DEV-###`. (DB-default cols aren't user-required.)
45. **Every `VARCHAR(n)`/`CHAR(n)` → an over-length (`n+k`) negative** asserting rejection + an exactly-`n` positive asserting success. DDL size vs FormRequest `max:` mismatch → `DEV-###`. Complement of #18.
46. **`test_01` asserts the FULL DDL↔app alignment matrix** (cols exist, null/not-null, types, lengths, defaults, UNIQUE(#43), FKs, name consistency across DDL/model/request/controller/test) vs the **LIVE** schema; soft-delete column & trait asserted INDEPENDENTLY (#30/#12); mismatch → `DEV-###`.
47. **Route ALL CRUD through the correct verified Eloquent model** (`$table`/prefix, fillable, relationships confirmed from real source); a wrong/misconfigured app model → `DEV-###`, don't paper over it.
48. **Test the CODE, not the UI** — programmatically-managed fields (auto `ordinal`, auto code/name, server defaults, computed cols, workflow-set status) tested as AUTO-behaviour (controller/service sets them; user can't override), **NEVER** proposed as form inputs. (HARD RULE #1/#2.)

---

## Usage in generated artifacts
- The **`.php`** must comply with A–G: real assertions (F33), real methods (F34), `refresh()` (F35), `>=` counts (F36), permission cache-flush + 403 (F37), cleanup (F38), no hand-written URLs/selectors (F40); and it GENERATES the DDL coverage — duplicate-rejection per UNIQUE (G43), missing-value per NOT NULL/nullable (G44), over-length per sized string (G45), full alignment `test_01` (G46), CRUD via the verified model (G47), code-managed fields as auto-behaviour (G48).
- The **Validation Report** lists constraints that shaped the tests + env prerequisites (E19/E20 + F41 infra: `sys_media`, 500-vs-422, route cache, ChromeDriver).
- **Feedback loop:** a NEW general failure/fix found during generation → append a one-line rule to THIS card AND its evidence to `05a_…_Evidence_Appendix.md` (see `03_`). Keep both de-duplicated.
