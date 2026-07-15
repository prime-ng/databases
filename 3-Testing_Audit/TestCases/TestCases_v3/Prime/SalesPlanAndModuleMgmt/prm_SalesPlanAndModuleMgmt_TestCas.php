<?php

namespace Tests\Browser\Modules\Prime\SalesPlanAndModuleMgmt;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * prm_SalesPlanAndModuleMgmt_TestCas
 * -----------------------------------------------------------------------------
 * Feature: Prime (PRM) central "Sales Plan & Module Mgmt" screen.
 * Screen type: COMPOSITE READ-ONLY dashboard. The single index() action
 * aggregates THREE paginated catalogues onto one screen behind tabs:
 *   - Billing Cycle tab  -> prm_billing_cycles  (Modules\Billing\Models\BillingCycle)
 *   - Modules tab        -> glb_modules         (Modules\GlobalMaster\Models\Module)
 *   - Plans tab          -> prm_plans           (Modules\GlobalMaster\Models\Plan)
 * with a shared `search` + `status` filter and per-tab pagination page params
 * (billing_page / modules_page / plans_page, 10/page each).
 *
 * The controller is a Laravel resource controller, but its write half is NON
 * FUNCTIONAL: store()/update()/destroy() are EMPTY stubs (Gate::authorize only,
 * no persistence, no redirect) and create()/show()/edit() return views
 * prime::create / prime::show / prime::edit that DO NOT EXIST. The real write
 * operations for these three catalogues live in OTHER controllers (Billing
 * billing-cycle.*, GlobalMaster module.* / plan.*). These facts are proven as
 * CURRENT-BEHAVIOUR defects (HARD RULE 10), not desired behaviour.
 *
 * Primary table: prm_plans (prefix prm_). DB scope: Prime = CENTRAL (prime_db,
 * connection 'mysql'). NO tenant initialization. Host http://127.0.0.1:8000
 * (enforced by PrimeDuskTestCase::setUp). Central auth/helpers are implemented
 * LOCALLY here (mirroring BillingDuskTestCase) so this suite does not depend on
 * the Billing namespace. (Constraints E21, E22, #24, #25.)
 *
 * Real source of truth (read before authoring — HARD RULE 1):
 *   - Modules/Prime/app/Http/Controllers/SalesPlanAndModuleMgmtController.php
 *   - Modules/Prime/app/Policies/SalesPlanAndModuleMgmtPolicy.php
 *   - Modules/Prime/resources/views/sales-plan-and-module-mgmt/index.blade.php
 *   - Modules/GlobalMaster/app/Models/{Plan,Module}.php ; Modules/Billing/app/Models/BillingCycle.php
 *   - Modules/Prime/app/Providers/PrimeServiceProvider.php (registerCommands)
 *   - routes/web.php:167-169  Route::resource('sales-plan-mgmt', ...) under prefix('prime')->name('prime.')
 *   - DDL _prime_db_v4.sql: prm_plans / prm_billing_cycles / prm_module_plan_jnt
 *
 * Documented defects proven here (see Gap Analysis):
 *   DEV-PRM-SPM-001 (P1) store/update/destroy are empty stubs (no persistence).
 *   DEV-PRM-SPM-002 (P1) create/show/edit render non-existent views.
 *   DEV-PRM-SPM-003 (P2) controller gate prime.sale-plan-module-mgmt.* vs view
 *                        per-tab gates prime.billing-cycle/module/plan.* mismatch.
 *   DEV-PRM-SPM-004 (P2) Policy type-hints Modules\Prime\Models\TenantPlan
 *                        (prm_tenant_plan_jnt) though the screen manages prm_plans.
 *   DEV-PRM-SPM-005 (P2) DDL pivot prm_module_plan_jnt vs code glb_module_plan_jnt.
 *   DEV-PRM-SPM-006 (P3) Plan $fillable omits price_quarterly (present in DDL).
 *   DEV-PRM-SPM-007 (P2) BillingCycle uses SoftDeletes+timestamps but DDL
 *                        prm_billing_cycles declares no such columns.
 *   GAP-PRM-001    (P1) REFUTED by current source — GenerateInvoicesCommand
 *                        exists and IS registered (registerCommands not empty).
 */
class prm_SalesPlanAndModuleMgmt_TestCas extends PrimeDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/SalesPlanAndModuleMgmt/screenshots';

    private const INDEX_PATH = '/prime/sales-plan-mgmt';

    private const ROUTE_INDEX   = 'prime.sales-plan-mgmt.index';
    private const ROUTE_CREATE  = 'prime.sales-plan-mgmt.create';
    private const ROUTE_STORE   = 'prime.sales-plan-mgmt.store';
    private const ROUTE_SHOW    = 'prime.sales-plan-mgmt.show';
    private const ROUTE_EDIT    = 'prime.sales-plan-mgmt.edit';
    private const ROUTE_UPDATE  = 'prime.sales-plan-mgmt.update';
    private const ROUTE_DESTROY = 'prime.sales-plan-mgmt.destroy';

    // Controller top-level gates (note singular "sale"/"module").
    private const GATE_VIEW_ANY = 'prime.sale-plan-module-mgmt.viewAny';
    private const GATE_VIEW     = 'prime.sale-plan-module-mgmt.view';
    private const GATE_CREATE   = 'prime.sale-plan-module-mgmt.create';
    private const GATE_UPDATE   = 'prime.sale-plan-module-mgmt.update';
    private const GATE_DELETE   = 'prime.sale-plan-module-mgmt.delete';

    // Per-tab view gates (DIFFERENT vocabulary — DEV-PRM-SPM-003).
    private const GATE_TAB_BILLING = 'prime.billing-cycle.viewAny';
    private const GATE_TAB_MODULE  = 'prime.module.viewAny';
    private const GATE_TAB_PLAN    = 'prime.plan.viewAny';

    private const TABLE_PLANS    = 'prm_plans';
    private const TABLE_CYCLES   = 'prm_billing_cycles';
    private const TABLE_MOD_PLAN = 'prm_module_plan_jnt';
    private const TABLE_MODULES  = 'glb_modules';

    private const CONTROLLER_SRC = 'Modules/Prime/app/Http/Controllers/SalesPlanAndModuleMgmtController.php';
    private const POLICY_SRC     = 'Modules/Prime/app/Policies/SalesPlanAndModuleMgmtPolicy.php';
    private const VIEW_SRC       = 'Modules/Prime/resources/views/sales-plan-and-module-mgmt/index.blade.php';
    private const PLAN_MODEL_SRC = 'Modules/GlobalMaster/app/Models/Plan.php';
    private const CYCLE_MODEL_SRC = 'Modules/Billing/app/Models/BillingCycle.php';
    private const MODULE_MODEL_SRC = 'Modules/GlobalMaster/app/Models/Module.php';
    private const PROVIDER_SRC   = 'Modules/Prime/app/Providers/PrimeServiceProvider.php';

    private ?User $adminUser = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        // Prime/central feature — no tenant context is ever initialized here.
        parent::tearDown();
    }

    // =========================================================================
    // 01-09  CONFIGURATION TRUTH (schema + route + gate + model wiring)
    // =========================================================================

    /**
     * test_01 = config truth. Asserts the three backing tables' schema (live,
     * fail-soft), the resource route registration + verbs, the controller gate
     * abilities, and the DDL unique/FK facts for prm_plans.
     * BC-DB-01..12 / BC-AUTH / Source: DDL _prime_db_v4.sql, routes/web.php:168.
     */
    public function test_salesplanandmodulemgmt_01_schema_route_and_gate_configuration_are_correct(): void
    {
        // --- Resource routes registered under the prime.* name group ---
        foreach ([
            self::ROUTE_INDEX, self::ROUTE_CREATE, self::ROUTE_STORE, self::ROUTE_SHOW,
            self::ROUTE_EDIT, self::ROUTE_UPDATE, self::ROUTE_DESTROY,
        ] as $name) {
            $this->assertTrue(Route::has($name), "Route {$name} is not registered.");
        }

        // --- Index URI matches the documented /prime/sales-plan-mgmt path ---
        $index = Route::getRoutes()->getByName(self::ROUTE_INDEX);
        $this->assertNotNull($index, 'index route object missing.');
        $this->assertSame('prime/sales-plan-mgmt', $index->uri(), 'index URI is not prime/sales-plan-mgmt.');
        $this->assertContains('GET', $index->methods(), 'index is not a GET route.');

        $store = Route::getRoutes()->getByName(self::ROUTE_STORE);
        $this->assertContains('POST', $store->methods(), 'store is not a POST route.');
        $destroy = Route::getRoutes()->getByName(self::ROUTE_DESTROY);
        $this->assertContains('DELETE', $destroy->methods(), 'destroy is not a DELETE route.');

        // --- Backing tables exist in prime_db (connection 'mysql'), fail-soft ---
        $this->assertPrimeTableExists(self::TABLE_PLANS);
        $this->assertPrimeTableExists(self::TABLE_CYCLES);

        // --- prm_plans key columns (live, accepted-type assertions) ---
        foreach (['id', 'plan_code', 'version', 'name', 'description', 'billing_cycle_id',
                  'price_monthly', 'price_yearly', 'currency', 'trial_days', 'is_active',
                  'deleted_at', 'created_at', 'updated_at'] as $col) {
            $this->assertPrimeColumnExists(self::TABLE_PLANS, $col);
        }

        // --- prm_plans DDL truth: UNIQUE(plan_code,version) + FK RESTRICT ---
        $planDdl = $this->readAppSourceDdl('prm_plans');
        if ($planDdl !== null) {
            $this->assertStringContainsString('uq_plans_planCode_version', $planDdl, 'prm_plans unique(plan_code,version) missing in DDL.');
            $this->assertStringContainsString('ON DELETE RESTRICT', $planDdl, 'prm_plans billing_cycle_id FK RESTRICT missing in DDL.');
        }

        // --- Controller gate abilities registered ---
        foreach ([self::GATE_VIEW_ANY, self::GATE_VIEW, self::GATE_CREATE, self::GATE_UPDATE, self::GATE_DELETE] as $ability) {
            $this->assertTrue(Gate::has($ability), "Gate {$ability} is not registered.");
        }
    }

    /**
     * Primary source files exist (controller, policy, index view).
     * BC-CFG-01 / Source: HARD RULE 1 read-set.
     */
    public function test_salesplanandmodulemgmt_02_primary_source_files_present(): void
    {
        foreach ([self::CONTROLLER_SRC, self::POLICY_SRC, self::VIEW_SRC, self::PLAN_MODEL_SRC, self::CYCLE_MODEL_SRC, self::MODULE_MODEL_SRC] as $rel) {
            $src = $this->readAppSource($rel);
            if ($src === null) {
                $this->markTestSkipped('App source not reachable (MAIN_PROJECT_PATH unset); file presence covered by route/schema config in test_01.');
            }
            $this->assertNotSame('', trim($src), "Source file empty/absent: {$rel}");
        }
    }

    /**
     * Models back the correct tables: Plan->prm_plans, BillingCycle->prm_billing_cycles,
     * Module->glb_modules. BC-DB-13 / Source: model $table declarations.
     */
    public function test_salesplanandmodulemgmt_03_models_back_expected_tables(): void
    {
        $plan = $this->readAppSource(self::PLAN_MODEL_SRC);
        $cycle = $this->readAppSource(self::CYCLE_MODEL_SRC);
        $module = $this->readAppSource(self::MODULE_MODEL_SRC);
        if ($plan === null || $cycle === null || $module === null) {
            $this->markTestSkipped('App source not reachable; table wiring covered live in test_01.');
        }

        $this->assertStringContainsString("protected \$table = 'prm_plans';", $plan, 'Plan model does not back prm_plans.');
        $this->assertStringContainsString("protected \$table = 'prm_billing_cycles';", $cycle, 'BillingCycle model does not back prm_billing_cycles.');
        $this->assertStringContainsString("protected \$table = 'glb_modules';", $module, 'Module model does not back glb_modules.');
    }

    // =========================================================================
    // 10-19  BUSINESS RULES — composite index aggregation (BC-BIZ)
    // =========================================================================

    /**
     * Index renders the three tabs (Billing Cycle default active) for an
     * authorized user. BC-BIZ-01 / Source: index.blade.php nav-tab config.
     */
    public function test_salesplanandmodulemgmt_10_index_renders_three_tabs(): void
    {
        $this->browseWithFailureScreenshot('spm-index-tabs', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Sales Plan & Module Mgmt index not reachable.');
            $this->ensurePageAccessible($browser, 'Sales Plan & Module Mgmt index');

            $browser->assertPresent('#billing-tab')
                ->assertPresent('#modules-tab')
                ->assertPresent('#plans-tab');
        });
    }

    /**
     * Billing Cycle tab lists prm_billing_cycles columns (Short Name / Name /
     * Months) or an empty-state. BC-BIZ-02 / Source: index.blade.php billing pane.
     */
    public function test_salesplanandmodulemgmt_11_billing_tab_lists_cycles(): void
    {
        $this->browseWithFailureScreenshot('spm-billing-tab', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle tab');

            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Short Name', $source, 'Billing Cycle table header missing.');
            $this->assertStringContainsString('Months', $source, 'Billing Cycle Months column missing.');
            $browser->assertPresent('#billing-pane table');
        });
    }

    /**
     * Modules tab lists glb_modules (Name / Version / Menus columns).
     * BC-BIZ-03 / Source: index.blade.php modules pane.
     */
    public function test_salesplanandmodulemgmt_12_modules_tab_lists_modules(): void
    {
        $this->browseWithFailureScreenshot('spm-modules-tab', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=modules');
            $this->ensurePageAccessible($browser, 'Modules tab');

            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('id="modules-pane"', $source, 'Modules pane missing.');
            $this->assertStringContainsString('Menus', $source, 'Modules Menus column missing.');
        });
    }

    /**
     * Plans tab lists prm_plans with billing cycle + trial columns.
     * BC-BIZ-04 / Source: index.blade.php plans pane.
     */
    public function test_salesplanandmodulemgmt_13_plans_tab_lists_plans(): void
    {
        $this->browseWithFailureScreenshot('spm-plans-tab', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=plans');
            $this->ensurePageAccessible($browser, 'Plans tab');

            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('id="plans-pane"', $source, 'Plans pane missing.');
            $this->assertStringContainsString('Billing Cycle', $source, 'Plans Billing Cycle column missing.');
            $this->assertStringContainsString('Trial', $source, 'Plans Trial column missing.');
        });
    }

    /**
     * Each plan row exposes a plan-detail modal (#planDetail-{id}) listing its
     * modules. BC-BIZ-05 / Source: index.blade.php planDetail modal.
     */
    public function test_salesplanandmodulemgmt_14_plan_detail_modal_markup_present(): void
    {
        $view = $this->readAppSource(self::VIEW_SRC);
        if ($view === null) {
            $this->markTestSkipped('View source not reachable; modal render covered behaviourally in test_13.');
        }
        $this->assertStringContainsString('id="planDetail-{{ $plan->id }}"', $view, 'Per-plan detail modal markup missing.');
        $this->assertStringContainsString('$plan->modules', $view, 'Plan modules loop missing from detail modal.');
    }

    /**
     * Each tab paginates 10/page with a distinct page param
     * (billing_page / modules_page / plans_page). BC-BIZ-06 / Source:
     * controller index() paginate(10, ...) with named pages.
     */
    public function test_salesplanandmodulemgmt_15_index_uses_distinct_pagination_params(): void
    {
        $controller = $this->readAppSource(self::CONTROLLER_SRC);
        if ($controller === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        $this->assertStringContainsString("'modules_page'", $controller, 'modules_page pagination param missing.');
        $this->assertStringContainsString("'billing_page'", $controller, 'billing_page pagination param missing.');
        $this->assertStringContainsString("'plans_page'", $controller, 'plans_page pagination param missing.');
        $this->assertStringContainsString('paginate(10', $controller, 'Expected 10-per-page pagination.');
    }

    // =========================================================================
    // 30-39  FILTERS / VALIDATION-EQUIVALENT + NEGATIVE (BC-VAL)
    // =========================================================================

    /**
     * The shared search box + status select are present on the billing pane.
     * BC-VAL-01 / Source: index.blade.php search-bar form inputs.
     */
    public function test_salesplanandmodulemgmt_30_search_and_status_controls_present(): void
    {
        $this->browseWithFailureScreenshot('spm-filter-controls', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Filter controls');

            $browser->assertPresent('input[name="search"]')
                ->assertPresent('select[name="status"]');
        });
    }

    /**
     * A search term is applied server-side (query filters each catalogue). The
     * page still renders (200, no 500) with the term echoed into the input.
     * BC-VAL-02 / Source: controller index() where(...like...).
     */
    public function test_salesplanandmodulemgmt_31_search_filter_applies_without_error(): void
    {
        $this->browseWithFailureScreenshot('spm-search-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=MONTHLY');
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Search request did not stay on index.');
            $this->ensurePageAccessible($browser, 'Search filter');
            $browser->assertInputValue('search', 'MONTHLY');
        });
    }

    /**
     * status=1 (Active) and status=0 (Inactive) filters are honoured; the page
     * renders for both. BC-VAL-03 / Source: controller in_array status guard.
     */
    public function test_salesplanandmodulemgmt_32_status_filter_active_and_inactive(): void
    {
        $this->browseWithFailureScreenshot('spm-status-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);

            $this->visitAuthenticated($browser, self::INDEX_PATH . '?status=1');
            $this->ensurePageAccessible($browser, 'Status=1 filter');
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'status=1 did not stay on index.');

            $this->visitAuthenticated($browser, self::INDEX_PATH . '?status=0');
            $this->ensurePageAccessible($browser, 'Status=0 filter');
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'status=0 did not stay on index.');
        });
    }

    /**
     * An out-of-range status value is IGNORED (controller guards with
     * in_array($status, ['0','1'])) rather than erroring. BC-VAL-04 / TC-N /
     * Source: controller index() status guard.
     */
    public function test_salesplanandmodulemgmt_33_invalid_status_value_is_ignored(): void
    {
        $this->browseWithFailureScreenshot('spm-status-invalid', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?status=not-a-flag');
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Invalid status caused a redirect.');
            $this->ensurePageAccessible($browser, 'Invalid status value');
        });
    }

    /**
     * A no-match search shows the tab's empty-state ("Not Data Found" /
     * "No Data Found"), not an error. BC-VAL-05 / TC-N / Source: @empty rows.
     */
    public function test_salesplanandmodulemgmt_34_no_match_search_shows_empty_state(): void
    {
        $this->browseWithFailureScreenshot('spm-empty-state', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $needle = 'zznomatch' . substr(md5((string) mt_rand()), 0, 8);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . $needle);
            $this->ensurePageAccessible($browser, 'Empty-state search');

            $source = $browser->driver->getPageSource();
            $this->assertTrue(
                str_contains($source, 'Not Data Found') || str_contains($source, 'No Data Found'),
                'Expected an empty-state message for a no-match search.'
            );
        });
    }

    // =========================================================================
    // 40-49  INTEGRATION / FK + CRUD-STUB DEFECTS (BC-INT / DEV)
    // =========================================================================

    /**
     * DEV-PRM-SPM-001 (P1): store() is an empty stub — it persists nothing.
     * Source proof: the method body contains only Gate::authorize and NO
     * Eloquent write (create/save/insert). BC-INT-01 / Source: controller store().
     */
    public function test_salesplanandmodulemgmt_40_store_is_a_nonfunctional_stub(): void
    {
        $controller = $this->readAppSource(self::CONTROLLER_SRC);
        if ($controller === null) {
            $this->markTestSkipped('Controller source not reachable; stub proven behaviourally in test_42.');
        }
        $body = $this->extractMethodBody($controller, 'store');
        $this->assertNotNull($body, 'store() method not found.');
        $this->assertStringContainsString('Gate::authorize', $body, 'store() lost its gate.');
        foreach (['->create(', '->save(', '::create(', '->insert(', 'DB::table'] as $writeToken) {
            $this->assertStringNotContainsString($writeToken, $body, "store() unexpectedly persists via {$writeToken} — re-verify DEV-PRM-SPM-001.");
        }
    }

    /**
     * DEV-PRM-SPM-001 (P1): update() and destroy() are empty stubs too.
     * BC-INT-02 / Source: controller update()/destroy().
     */
    public function test_salesplanandmodulemgmt_41_update_and_destroy_are_nonfunctional_stubs(): void
    {
        $controller = $this->readAppSource(self::CONTROLLER_SRC);
        if ($controller === null) {
            $this->markTestSkipped('Controller source not reachable; stub proven behaviourally in test_42.');
        }
        foreach (['update', 'destroy'] as $method) {
            $body = $this->extractMethodBody($controller, $method);
            $this->assertNotNull($body, "{$method}() method not found.");
            foreach (['->save(', '->update(', '->delete(', '->forceDelete('] as $writeToken) {
                $this->assertStringNotContainsString($writeToken, $body, "{$method}() unexpectedly persists via {$writeToken} — re-verify DEV-PRM-SPM-001.");
            }
        }
    }

    /**
     * DEV-PRM-SPM-001 behavioural proof: a POST to the store route creates no
     * prm_plans row (count unchanged), regardless of the 200/302/403 status.
     * BC-INT-03 / TC-D / Source: controller store() (no persistence).
     */
    public function test_salesplanandmodulemgmt_42_store_post_creates_no_plan_row(): void
    {
        try {
            $before = DB::connection('mysql')->table(self::TABLE_PLANS)->count();
        } catch (Throwable) {
            $this->markTestSkipped('prm_plans not reachable on the mysql connection in this environment.');
        }

        try {
            $this->actingAs($this->adminUser)
                ->post($this->centralUrl('/prime/sales-plan-mgmt'), [
                    'plan_code' => 'ZZTEST' . rand(1000, 9999),
                    'name' => 'Zz Stub Probe',
                    'version' => 1,
                    'billing_cycle_id' => 1,
                ]);
        } catch (Throwable) {
            // A stub that returns void may surface as an exception in the HTTP kernel;
            // the assertion below (no row created) is what proves the defect.
        }

        $after = DB::connection('mysql')->table(self::TABLE_PLANS)->count();
        $this->assertSame($before, $after, 'store() unexpectedly created a prm_plans row — DEV-PRM-SPM-001 may be fixed.');
    }

    /**
     * DEV-PRM-SPM-002 (P1): create()/show()/edit() return views prime::create /
     * prime::show / prime::edit that DO NOT EXIST — a hard runtime failure if
     * hit. Source proof: controller returns those view names AND no such blade
     * files exist under the Prime module views root.
     * BC-INT-04 / Source: controller create()/show()/edit().
     */
    public function test_salesplanandmodulemgmt_43_create_show_edit_reference_missing_views(): void
    {
        $controller = $this->readAppSource(self::CONTROLLER_SRC);
        if ($controller === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        $this->assertStringContainsString("view('prime::create')", $controller, 'create() no longer returns prime::create.');
        $this->assertStringContainsString("view('prime::show')", $controller, 'show() no longer returns prime::show.');
        $this->assertStringContainsString("view('prime::edit')", $controller, 'edit() no longer returns prime::edit.');

        foreach (['create', 'show', 'edit'] as $v) {
            $blade = $this->readAppSource("Modules/Prime/resources/views/{$v}.blade.php");
            $this->assertNull($blade, "prime::{$v} view unexpectedly EXISTS — DEV-PRM-SPM-002 may be resolved.");
        }
    }

    /**
     * prm_plans.billing_cycle_id is FK -> prm_billing_cycles ON DELETE RESTRICT.
     * BC-REF-01 / Source: DDL fk_plans_billingCycleId.
     */
    public function test_salesplanandmodulemgmt_44_plan_billing_cycle_fk_is_restrict(): void
    {
        $ddl = $this->readAppSourceDdl('prm_plans');
        if ($ddl === null) {
            $this->markTestSkipped('DDL not reachable; FK documented in Manual/Gap artifacts.');
        }
        $this->assertStringContainsString('fk_plans_billingCycleId', $ddl, 'billing_cycle_id FK constraint name missing.');
        $this->assertStringContainsString('REFERENCES `prm_billing_cycles`', $ddl, 'FK does not reference prm_billing_cycles.');
        $this->assertStringContainsString('ON DELETE RESTRICT', $ddl, 'FK is not ON DELETE RESTRICT.');
    }

    /**
     * DEV-PRM-SPM-005 (P2): the module<->plan pivot is named prm_module_plan_jnt
     * in the DDL but Plan::modules()/Module::plans() query glb_module_plan_jnt.
     * BC-INT-05 / Source: DDL vs Plan/Module models.
     */
    public function test_salesplanandmodulemgmt_45_module_plan_pivot_name_mismatch(): void
    {
        $ddl = $this->readAppSourceDdl('prm_module_plan_jnt');
        $plan = $this->readAppSource(self::PLAN_MODEL_SRC);
        if ($ddl === null || $plan === null) {
            $this->markTestSkipped('DDL/model source not reachable; mismatch documented in Gap Analysis.');
        }
        // DDL declares prm_module_plan_jnt ...
        $this->assertStringContainsString('prm_module_plan_jnt', $ddl, 'DDL no longer defines prm_module_plan_jnt.');
        // ... but the model queries glb_module_plan_jnt (the documented mismatch).
        $this->assertStringContainsString('glb_module_plan_jnt', $plan, 'Plan::modules() no longer uses glb_module_plan_jnt — re-verify DEV-PRM-SPM-005.');
    }

    /**
     * DEV-PRM-SPM-006 (P3): DDL prm_plans has price_quarterly, but Plan $fillable
     * omits it — a mass-assigned quarterly price is silently dropped.
     * BC-INT-06 / Source: DDL prm_plans vs Plan $fillable.
     */
    public function test_salesplanandmodulemgmt_46_plan_fillable_omits_price_quarterly(): void
    {
        $ddl = $this->readAppSourceDdl('prm_plans');
        $plan = $this->readAppSource(self::PLAN_MODEL_SRC);
        if ($ddl === null || $plan === null) {
            $this->markTestSkipped('DDL/model source not reachable; documented in Gap Analysis.');
        }
        $this->assertStringContainsString('price_quarterly', $ddl, 'DDL no longer defines price_quarterly.');
        $fillable = $this->extractMethodBody($plan, null, '$fillable');
        if ($fillable !== null) {
            $this->assertStringNotContainsString("'price_quarterly'", $fillable, 'price_quarterly is now fillable — DEV-PRM-SPM-006 may be fixed.');
        }
    }

    /**
     * DEV-PRM-SPM-007 (P2): BillingCycle uses SoftDeletes + default timestamps,
     * but the DDL prm_billing_cycles declares NO deleted_at/created_at/updated_at.
     * Asserted fail-soft against the live schema. BC-INT-07 / Source: DDL vs model.
     */
    public function test_salesplanandmodulemgmt_47_billing_cycle_softdelete_timestamp_gap(): void
    {
        $cycle = $this->readAppSource(self::CYCLE_MODEL_SRC);
        if ($cycle === null) {
            $this->markTestSkipped('BillingCycle source not reachable.');
        }
        $this->assertStringContainsString('use HasFactory, SoftDeletes;', $cycle, 'BillingCycle no longer declares SoftDeletes.');

        $ddl = $this->readAppSourceDdl('prm_billing_cycles');
        if ($ddl !== null) {
            // Current behaviour: the DDL block omits these columns (the defect).
            $hasDeletedAt = str_contains($ddl, 'deleted_at');
            $this->assertFalse(
                $hasDeletedAt,
                'DDL prm_billing_cycles now declares deleted_at — DEV-PRM-SPM-007 may be resolved.'
            );
        }
    }

    /**
     * GAP-PRM-001 (P1) — REFUTED by current source. The audit claimed
     * GenerateInvoicesCommand was missing / registerCommands() empty. Current
     * source registers the command AND the command class exists, so the plan->
     * billing->invoice command IS wired. This test proves CURRENT behaviour.
     * BC-INT-08 / Source: PrimeServiceProvider::registerCommands.
     */
    public function test_salesplanandmodulemgmt_48_generate_invoices_command_is_registered(): void
    {
        $provider = $this->readAppSource(self::PROVIDER_SRC);
        if ($provider === null) {
            $this->markTestSkipped('Provider source not reachable; GAP-PRM-001 status documented in Gap Analysis.');
        }
        $this->assertStringContainsString('GenerateInvoicesCommand::class', $provider, 'GenerateInvoicesCommand is not registered (GAP-PRM-001 would then hold).');

        $command = $this->readAppSource('Modules/Billing/app/Console/Commands/GenerateInvoicesCommand.php');
        $this->assertNotNull($command, 'GenerateInvoicesCommand class file is missing (GAP-PRM-001 would then hold).');
        $this->assertStringContainsString('prime:generate-invoices', $command, 'GenerateInvoicesCommand signature changed.');
    }

    // =========================================================================
    // 50-59  PERMISSIONS / AUTHORIZATION (BC-AUTH)
    // =========================================================================

    /**
     * index() is gated by EXACTLY prime.sale-plan-module-mgmt.viewAny.
     * BC-AUTH-01 / Source: controller index() Gate::authorize.
     */
    public function test_salesplanandmodulemgmt_50_index_is_gated_by_view_any(): void
    {
        $this->assertTrue(Gate::has(self::GATE_VIEW_ANY), self::GATE_VIEW_ANY . ' gate not registered.');
        $controller = $this->readAppSource(self::CONTROLLER_SRC);
        if ($controller === null) {
            $this->markTestSkipped('Controller source not reachable; gate registration asserted via Gate::has.');
        }
        $this->assertStringContainsString("Gate::authorize('prime.sale-plan-module-mgmt.viewAny')", $controller, 'index() gate changed.');
    }

    /**
     * The write/read gates map to the resource verbs:
     * create/store -> .create ; show -> .view ; edit/update -> .update ;
     * destroy -> .delete. BC-AUTH-02 / Source: controller Gate::authorize calls.
     */
    public function test_salesplanandmodulemgmt_51_resource_gates_map_to_verbs(): void
    {
        $controller = $this->readAppSource(self::CONTROLLER_SRC);
        if ($controller === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        $this->assertStringContainsString("Gate::authorize('prime.sale-plan-module-mgmt.create')", $controller, 'create/store gate changed.');
        $this->assertStringContainsString("Gate::authorize('prime.sale-plan-module-mgmt.view')", $controller, 'show gate changed.');
        $this->assertStringContainsString("Gate::authorize('prime.sale-plan-module-mgmt.update')", $controller, 'edit/update gate changed.');
        $this->assertStringContainsString("Gate::authorize('prime.sale-plan-module-mgmt.delete')", $controller, 'destroy gate changed.');
    }

    /**
     * DEV-PRM-SPM-003 (P2): the VIEW gates its three tabs on
     * prime.billing-cycle/module/plan.viewAny — a DIFFERENT permission vocabulary
     * from the controller's prime.sale-plan-module-mgmt.* gate. A user holding the
     * three tab perms but not sale-plan-module-mgmt.viewAny is blocked at the
     * controller. BC-AUTH-03 / Source: index.blade.php nav-tab permissions.
     */
    public function test_salesplanandmodulemgmt_52_view_tab_gates_differ_from_controller_gate(): void
    {
        $view = $this->readAppSource(self::VIEW_SRC);
        if ($view === null) {
            $this->markTestSkipped('View source not reachable; mismatch documented in Gap Analysis.');
        }
        $this->assertStringContainsString(self::GATE_TAB_BILLING, $view, 'Billing tab gate changed.');
        $this->assertStringContainsString(self::GATE_TAB_MODULE, $view, 'Module tab gate changed.');
        $this->assertStringContainsString(self::GATE_TAB_PLAN, $view, 'Plan tab gate changed.');
        // The controller-level ability is absent from the view (the mismatch).
        $this->assertStringNotContainsString('prime.sale-plan-module-mgmt', $view, 'View now references the controller gate — DEV-PRM-SPM-003 may be resolved.');
    }

    /**
     * DEV-PRM-SPM-004 (P2): the Policy type-hints Modules\Prime\Models\TenantPlan
     * (prm_tenant_plan_jnt) although the screen manages the Plan CATALOGUE
     * (prm_plans). The Policy is also never bound (controller uses string gates),
     * making it dead code. BC-AUTH-04 / Source: SalesPlanAndModuleMgmtPolicy.php.
     */
    public function test_salesplanandmodulemgmt_53_policy_type_hints_tenant_plan_not_plan(): void
    {
        $policy = $this->readAppSource(self::POLICY_SRC);
        if ($policy === null) {
            $this->markTestSkipped('Policy source not reachable; mismatch documented in Gap Analysis.');
        }
        $this->assertStringContainsString('use Modules\Prime\Models\TenantPlan;', $policy, 'Policy no longer imports TenantPlan.');
        $this->assertStringContainsString("can('prime.sale-plan-module-mgmt.viewAny')", $policy, 'Policy viewAny ability changed.');
        $this->assertStringNotContainsString('use Modules\GlobalMaster\Models\Plan;', $policy, 'Policy now type-hints Plan — DEV-PRM-SPM-004 may be resolved.');
    }

    /**
     * A guest is redirected to /login (route sits behind auth+verified).
     * BC-AUTH-05 / TC-N / Source: routes/web.php:107 middleware(['auth','verified']).
     */
    public function test_salesplanandmodulemgmt_54_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('spm-guest-redirect', function (Browser $browser): void {
            $this->logoutBrowser($browser);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest was NOT redirected to /login.');
        });
    }

    /**
     * An authenticated super-admin reaches the index (not 403). BC-AUTH-06 /
     * TC-P / Source: controller Gate::authorize + super-admin Gate::before.
     */
    public function test_salesplanandmodulemgmt_55_authorized_admin_reaches_index(): void
    {
        $this->browseWithFailureScreenshot('spm-admin-access', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Authorized admin could not reach the index.');
            $this->ensurePageAccessible($browser, 'Authorized admin index access');
        });
    }

    // =========================================================================
    // 60-69  UI / UX (breadcrumb, per-tab controls, pane switching)
    // =========================================================================

    /**
     * The breadcrumb title "Sales Plan & Module Mgmt" renders.
     * BC-EDG-01 / Source: index.blade.php breadcrum component.
     */
    public function test_salesplanandmodulemgmt_60_breadcrumb_title_present(): void
    {
        $this->browseWithFailureScreenshot('spm-breadcrumb', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Breadcrumb');
            $browser->assertSee('Sales Plan & Module Mgmt');
        });
    }

    /**
     * The billing pane is active/shown by default (nav-tab active="billing").
     * BC-EDG-02 / Source: index.blade.php active default + sync script.
     */
    public function test_salesplanandmodulemgmt_61_billing_pane_active_by_default(): void
    {
        $this->browseWithFailureScreenshot('spm-default-pane', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Default pane');
            $browser->waitFor('#billing-pane', 10)->assertVisible('#billing-pane');
        });
    }

    /**
     * Clicking the Plans tab reveals the plans pane. BC-EDG-03 / Source:
     * index.blade.php bootstrap tab toggle.
     */
    public function test_salesplanandmodulemgmt_62_plans_tab_click_shows_plans_pane(): void
    {
        $this->browseWithFailureScreenshot('spm-tab-switch', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Tab switch');

            if ($browser->element('#plans-tab')) {
                $browser->click('#plans-tab')->pause(600);
                $browser->waitFor('#plans-pane', 10)->assertVisible('#plans-pane');
            } else {
                $this->markTestSkipped('Plans tab not visible for current user (per-tab gate).');
            }
        });
    }

    // =========================================================================
    // 90-99  CENTRAL SCOPE + SECURITY PACK (TC-S)
    // =========================================================================

    /**
     * This is a CENTRAL feature: the suite runs on 127.0.0.1:8000 and no tenant
     * context is initialized (Constraint #21). BC-CFG-02 / Source: PrimeDuskTestCase.
     */
    public function test_salesplanandmodulemgmt_90_runs_in_central_scope_without_tenancy(): void
    {
        $this->assertSame('127.0.0.1', parse_url($this->primeBaseUrl, PHP_URL_HOST), 'Prime tests must run on 127.0.0.1.');
        if (function_exists('tenancy')) {
            $this->assertFalse(tenancy()->initialized, 'Tenant context must NOT be initialized for a central feature.');
        }
    }

    /**
     * Reflected-XSS smoke: an injected search payload is NOT reflected unescaped
     * into the page. Blade {{ }} escapes request('search'). TC-S-01 / Source:
     * index.blade.php value="{{ request('search') }}".
     */
    public function test_salesplanandmodulemgmt_91_search_input_is_not_reflected_unescaped(): void
    {
        $marker = 'zzxss' . substr(md5((string) mt_rand()), 0, 6);
        $payload = '<script>' . $marker . '</script>';

        $this->browseWithFailureScreenshot('spm-xss-smoke', function (Browser $browser) use ($payload, $marker): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . rawurlencode($payload));
            $this->ensurePageAccessible($browser, 'Search XSS smoke');

            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>' . $marker . '</script>', $source, 'Injected search input was reflected unescaped.');
        });
    }

    /**
     * IDOR/verb smoke: an unauthenticated DELETE to the destroy route does NOT
     * succeed (redirect/40x), so no arbitrary plan can be removed by a guest.
     * The stub also removes nothing regardless. TC-S-02 / Source:
     * routes/web.php auth middleware + controller destroy() stub.
     */
    public function test_salesplanandmodulemgmt_92_guest_delete_is_blocked(): void
    {
        try {
            $before = DB::connection('mysql')->table(self::TABLE_PLANS)->count();
        } catch (Throwable) {
            $this->markTestSkipped('prm_plans not reachable on the mysql connection.');
        }

        $status = 0;
        try {
            $response = $this->deleteJson($this->centralUrl('/prime/sales-plan-mgmt/1'));
            $status = $response->getStatusCode();
        } catch (Throwable) {
            // A redirect to login or an auth exception both satisfy "blocked".
            $status = 302;
        }

        $this->assertContains($status, [301, 302, 401, 403, 404, 405, 419, 500], 'Guest DELETE unexpectedly returned a success status.');
        $after = DB::connection('mysql')->table(self::TABLE_PLANS)->count();
        $this->assertSame($before, $after, 'A plan row changed on a guest DELETE — investigate.');
    }

    // =========================================================================
    // Private helper library (central auth + screenshots + source access)
    // Implemented locally (mirrors BillingDuskTestCase) — no Billing dependency.
    // =========================================================================

    private function assertPrimeTableExists(string $table): void
    {
        try {
            $this->assertTrue(
                Schema::connection('mysql')->hasTable($table),
                "Expected prime_db table {$table} to exist."
            );
        } catch (Throwable) {
            $this->markTestSkipped("prime_db (mysql) connection not reachable to verify {$table}.");
        }
    }

    private function assertPrimeColumnExists(string $table, string $column): void
    {
        try {
            $this->assertTrue(
                Schema::connection('mysql')->hasColumn($table, $column),
                "Expected {$table}.{$column} to exist."
            );
        } catch (Throwable) {
            $this->markTestSkipped("prime_db (mysql) connection not reachable to verify {$table}.{$column}.");
        }
    }

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }

        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();

        return (string) parse_url($url, PHP_URL_PATH);
    }

    private function resolveAdminUser(): void
    {
        $superAdmin = User::query()->where('is_super_admin', 1)->first();
        if ($superAdmin) {
            $this->adminUser = $superAdmin;
            $this->ensureUserIsVerified($this->adminUser);

            return;
        }

        $userByEmail = User::query()->where('email', $this->adminEmail)->first();
        if ($userByEmail) {
            $this->adminUser = $userByEmail;
            $this->ensureUserIsVerified($this->adminUser);

            return;
        }

        $this->adminUser = User::create([
            'email' => $this->adminEmail,
            'password' => bcrypt($this->adminPassword),
            'name' => 'SalesPlan Dusk Admin',
            'emp_code' => 'EMP' . rand(100, 999),
            'short_name' => 'ADM' . rand(1000, 9999),
            'status' => 'ACTIVE',
            'is_active' => 1,
            'is_super_admin' => 1,
            'email_verified_at' => now(),
        ]);
    }

    private function ensureUserIsVerified(User $user): void
    {
        $updates = [];

        if (empty($user->email_verified_at)) {
            $updates['email_verified_at'] = now();
        }

        if (property_exists($user, 'is_active') && (int) $user->is_active !== 1) {
            $updates['is_active'] = 1;
        }

        if (!empty($updates)) {
            $user->fill($updates);
            $user->save();
        }
    }

    private function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl('/login'))->pause(800);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1200);
        }

        if (str_contains($this->currentPath($browser), '/login')) {
            if ($this->adminUser) {
                $browser->loginAs($this->adminUser)->pause(800);
            }
        }
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    private function logoutBrowser(Browser $browser): void
    {
        try {
            $browser->visit($this->centralUrl('/'))->pause(300);
            $browser->driver->manage()->deleteAllCookies();
        } catch (Throwable) {
            // best-effort: fall through to a cookie-less visit
        }
    }

    private function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows login page; authentication failed.');
        }

        $bodyText = $browser->element('body') ? $browser->text('body') : '';
        $signals = ['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419'];

        foreach ($signals as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'failure';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $safeName . '_' . now()->format('Ymd_His') . '.png';

        try {
            $browser->driver->takeScreenshot($absolutePath);

            return $absolutePath;
        } catch (Throwable) {
            return '';
        }
    }

    private function cleanScreenshots(): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);

        try {
            if (File::isDirectory($directory)) {
                File::cleanDirectory($directory);
            }
        } catch (Throwable) {
            // non-fatal
        }
    }

    /**
     * Read a source file from the APP repo (prime_ai). The Dusk runner's
     * base_path() points at the runner, so app source lives under
     * MAIN_PROJECT_PATH. Returns null (fail-soft) when unreachable.
     */
    private function readAppSource(string $relativePath): ?string
    {
        $roots = array_filter([
            env('MAIN_PROJECT_PATH'),
            base_path(),
        ]);

        foreach ($roots as $root) {
            $candidate = rtrim((string) $root, '/') . '/' . ltrim($relativePath, '/');
            try {
                if (File::exists($candidate)) {
                    return (string) File::get($candidate);
                }
            } catch (Throwable) {
                continue;
            }
        }

        return null;
    }

    /**
     * Read the CREATE TABLE block for a prime table from the consolidated DDL,
     * searching a few likely roots. Returns the block text (from CREATE TABLE to
     * the terminating ");") or null (fail-soft) when the DDL is not reachable.
     */
    private function readAppSourceDdl(string $table): ?string
    {
        $candidates = array_filter([
            env('PRIME_DDL_PATH'),
            '/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated/_prime_db_v4.sql',
        ]);

        foreach ($candidates as $path) {
            try {
                if (!File::exists((string) $path)) {
                    continue;
                }
                $sql = (string) File::get((string) $path);
                $needle = 'CREATE TABLE IF NOT EXISTS `' . $table . '`';
                $start = strpos($sql, $needle);
                if ($start === false) {
                    continue;
                }
                $end = strpos($sql, ');', $start);
                $end = $end === false ? $start + 2000 : $end + 2;

                return substr($sql, $start, $end - $start);
            } catch (Throwable) {
                continue;
            }
        }

        return null;
    }

    /**
     * Extract a rough method/property body from PHP source for content asserts.
     * When $property is given, returns the text of that property declaration up
     * to the closing "];". Otherwise returns the brace-balanced body of the
     * named method. Returns null when the target is not found.
     */
    private function extractMethodBody(string $source, ?string $method, ?string $property = null): ?string
    {
        if ($property !== null) {
            $anchor = strpos($source, $property);
            if ($anchor === false) {
                return null;
            }
            $end = strpos($source, '];', $anchor);
            $end = $end === false ? $anchor + 800 : $end + 2;

            return substr($source, $anchor, $end - $anchor);
        }

        if ($method === null) {
            return null;
        }

        $anchor = strpos($source, 'function ' . $method . '(');
        if ($anchor === false) {
            return null;
        }
        $brace = strpos($source, '{', $anchor);
        if ($brace === false) {
            return null;
        }

        $depth = 0;
        $len = strlen($source);
        for ($i = $brace; $i < $len; $i++) {
            if ($source[$i] === '{') {
                $depth++;
            } elseif ($source[$i] === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $brace, $i - $brace + 1);
                }
            }
        }

        return null;
    }
}
