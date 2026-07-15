# Phase 1 — Verification Harness Results (Gate 1 evidence)

**Run:** 2026-07-09 · read-only checks against `prime_ai`, `prime_testing`, and the consolidated DDLs.
**Purpose:** decide which team-agent constraints are safe to encode into `Testcase_Creator`. **Only verified claims become imperative rules.**

**Legend — Decision:** `ENCODE` (verified true) · `ENCODE-ADJUSTED` (true but adapt to our names/paths) · `DO-NOT-ENCODE` (false here — his-repo-specific) · `ADVISORY` (relevant but verify per-feature/runtime).

| ID | Claim (from team agent) | Result HERE | Evidence | Decision |
|----|-------------------------|-------------|----------|----------|
| H1 | Resolve tenant via `Modules\Prime\Models\Domain` host lookup; never `artisan tenancy:init`; guard `tenancy()->end()` | ✅ TRUE | `DuskTestCase` base has **no** init method; golden `csm` test uses `initializeTenantContext()` (Domain→`tenancy()->initialize`); `HrStaff/LeaveType` uses `initTenant()` (same Domain pattern) + `DatabaseMigrations`+`actingAs` | **ENCODE-ADJUSTED** — use the **sibling's** helper name/style; both resolve via `Domain`; guard `end()` |
| H2 | `password` NOT in `$fillable` on `Modules\SchoolSetup\Models\User` → use direct property assignment | ❌ FALSE | `SchoolSetup/app/Models/User.php` fillable **includes** `'password'` + cast `'password'=>'hashed'`; same in Prime User | **DO-NOT-ENCODE** his rule → **ENCODE opposite**: password IS fillable here |
| H2b | Use `App\Models\User::factory()` | ⚠️ PARTLY FALSE | `App\Models\User` **does not exist** (`app/Models/` has only `SysMedia.php`); User models are `Modules\Prime\Models\User` (`HasFactory`) and `Modules\SchoolSetup\Models\User`; a `UserFactory.php` exists at `prime_ai/database/factories/` | **ENCODE-ADJUSTED**: correct model namespaces; prefer factory where the model has `HasFactory` |
| H3a | `sys_users.emp_code` VARCHAR(20) → short suffixes | ✅ TRUE | `_tenant_db_v4`/`_prime_db_v4` `sys_users`: `emp_code VARCHAR(20) NOT NULL`, unique | **ENCODE** |
| H3b | `prefered_language` FK → `glb_languages` (note misspelling "prefered") | ✅ TRUE | tenant `sys_users`: `prefered_language INT unsigned NOT NULL` FK `glb_languages(id)` | **ENCODE** (keep exact spelling) |
| H3c | `user_type` does NOT exist in `sys_users` | ❌ FALSE (tenant) | tenant `sys_users` has `user_type ENUM('PRIME','EMPLOYEE','TEACHER','STUDENT','PARENT','OTHER') NOT NULL` | **DO-NOT-ENCODE** his rule → **ENCODE**: tenant `sys_users` HAS required `user_type` ENUM |
| H4 | `glb_languages` is a VIEW; ensure id=1 before creating users | ✅ TRUE | `_prime_db_v4.sql`: `CREATE VIEW glb_languages AS SELECT * FROM global_master.glb_languages;` | **ENCODE** (advisory: languages must be available) |
| H5 | Media table is `sys_media` (not `media`); wrap `forceDelete()` in try/catch | ✅ TRUE | `sys_media` table (INT UNSIGNED PK) in prime+tenant; Prime User uses `InteractsWithMedia` | **ENCODE** |
| H6 | `APP_ENV=testing` needed or CSRF 419 on state-changing requests | ⚠️ ADVISORY | No `phpunit.dusk.xml`/`.env.dusk*` in repo; `.env.bak` has `APP_ENV=local`; base class **warns** if not `testing`; golden runner sets `$env:APP_ENV="testing"` | **ADVISORY** — runners set it; validation tests must authenticate |
| H7 | Module disabled ⇒ all routes 404; check `modules_statuses.json` first | ✅ TRUE + **CRITICAL** | `modules_statuses.json`: **every module `false` except `Syllabus`** (BehaviouralAssessment=false) | **ENCODE** as mandatory pre-run/prerequisite check |
| H8 | MySQL 8 `COLUMN_TYPE` variance (`int` vs `int unsigned`) → use `assertStringContainsString` | ⚠️ ADVISORY | MySQL confirmed; exact version not pinned in docs | **ENCODE** as defensive assertion guidance |
| H9 | Read the Service layer — business logic lives there | ✅ TRUE | 38/46 modules have `app/Services/`; BehaviouralAssessment has `BehaviouralScoreService.php` | **ENCODE** (WP-C) |
| H10 | Distinguish prime-side vs tenant-side; toggle tenancy scaffolding | ✅ TRUE | central `prm_*`/`sys_*` in `_prime_db_v4`; BHA DDL header: "Database: tenant_db (one per tenant)"; determinable from DDL header + prefix | **ENCODE** (WP-D) via DDL header/prefix |
| U1 | Dusk `Browser` has no `assertStatus()`; use HTTP test methods for status codes | ✅ UNIVERSAL | Laravel Dusk API fact | **ENCODE** as-is |
| U2 | `withTrashed()/forceDelete()` only if model uses `SoftDeletes` (`class_uses_recursive`) | ✅ UNIVERSAL | Laravel fact | **ENCODE** as-is |
| U3 | Browse closures don't capture outer vars → `use ($var)` | ✅ UNIVERSAL | PHP closure fact | **ENCODE** as-is |
| U4 | Factory/test data must respect column limits (TINYINT ≤127, ENUM case-sensitive, VARCHAR sizes) | ✅ UNIVERSAL | MySQL fact | **ENCODE** as-is |

## Headline outcomes
- **2 team-agent constraints are FALSE in this codebase** and will be **inverted, not copied**: `password` **is** fillable (H2); `user_type` **exists** in tenant `sys_users` (H3c). This validates the verify-before-encode gate.
- **1 critical environment fact:** nearly **all modules are disabled** in `modules_statuses.json` — generated suites need the target module enabled first; this becomes a mandatory prerequisite note (H7).
- **Tenancy pattern confirmed** (Domain lookup, no `tenancy:init`) but the **helper name follows the module's sibling** (`initializeTenantContext` for browser, `initTenant` for HTTP) — consistent with the existing "detect test style" rule.
- **Service-layer read (H9)** and **prime-vs-tenant toggle (H10)** are both verified and safe to encode.

## Gate-4 correction (added after the dry run)
- **H2b was wrong** — it checked the APP repo (`prime_ai`), but tests **execute in the RUNNER repo (`prime_testing`)**, which **does** have `App\Models\User` (dynamic `$table`→`sys_users`, with a `UserFactory`). The golden reference, `DuskTestCase` base, and committed `HrStaff` sibling all `use App\Models\User;`. Constraint `05_` §B was corrected to **default to `App\Models\User` + `User::factory()`** (matching the sibling), using a module User model only when a Service/Policy type-hints it. This is the value of Gate 4: it caught an error in *our* constraint, not the agent's output.
- Also noted: the runner `UserFactory` sets `emp_code` + `prefered_language` but may omit `user_type` → pass it in the `create([...])` override.

## What gets encoded in Phase 1
- **WP-A** `05_Known_Test_Failure_Constraints.md`: U1–U4 (as-is), H1/H2/H2b/H3a/H3b/H3c/H4/H5/H10 (adjusted to real facts), H6/H7/H8 (advisory/prerequisite).
- **WP-C**: add Service layer to source-read order.
- **WP-B**: cross-reference gap checks.
- **WP-D**: prime-vs-tenant determination + tenancy-scaffolding toggle.
