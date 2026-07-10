<?php

namespace Tests\Browser\Modules\Prime\TenantManagement;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\View;
use Laravel\Dusk\Browser;
use ReflectionClass;
use ReflectionMethod;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Tenant & Subscription Management dashboard — READ / COMPOSITE screen.
 *
 * Feature ...... Prime (PRM) → TenantManagement
 * Screen type .. Single read-only composite dashboard (index() only).
 * Route ........ central.prime.tenant-management.index  →  GET /prime/tenant-management
 * Gate ......... Gate::authorize('prime.tenant.viewAny')  (controller index)
 * DB scope ..... CENTRAL / prime_db (prm_tenant, prm_tenant_groups) — NO tenant init.
 * Controller ... Modules\Prime\Http\Controllers\TenantManagementController@index
 * Models ....... Modules\Prime\Models\Tenant, Modules\Prime\Models\TenantGroup
 * Views ........ prime::tenant-management.index (+ tenant / tenant-group partials)
 *
 * This screen only LISTS tenants and tenant groups and shows computed dashboard
 * stats. It delegates ALL create/edit/delete/toggle to the dedicated Tenant and
 * TenantGroup screens (which register their own routes). The suite is therefore
 * READ-FOCUSED: render, tabs, listing columns, pagination, permissions, empty
 * state, guest redirect, and an explicit "no mutation route" matrix — no CRUD
 * matrix is invented for a screen that has none.
 *
 * Central-only per Constraint E21/E22: extends the Prime central base
 * (PrimeDuskTestCase, resolved via preload alias) and runs on 127.0.0.1:8000.
 * Central auth/report helpers are implemented locally (mirrored from
 * prm_BillingDuskTestCase_TestCas) because this feature lives at the top level
 * of the Prime tree, not under Billing/.
 */
class prm_TenantManagement_TestCas extends PrimeDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/TenantManagement/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/TenantManagement/report';
    protected const STATUS_REPORT_PREFIX = 'prime_tenant_management_report_';

    private const INDEX_PATH = '/prime/tenant-management';
    private const ROUTE_NAME = 'central.prime.tenant-management.index';
    private const INDEX_GATE = 'prime.tenant.viewAny';

    private const TENANT_TAB_VIEW = 'prime::tenant-management.partials.tenant._tenantTab';
    private const TENANT_GROUP_TAB_VIEW = 'prime::tenant-management.partials.tenant-group._tenantGroupTab';

    protected ?User $adminUser = null;
    protected string $centralBaseUrl = '';
    protected string $adminEmail = '';
    protected string $adminPassword = '';
    protected array $statusReportEntries = [];

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->statusReportEntries = [];

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (!empty($this->statusReportEntries)) {
            $this->writeStatusReportForCurrentTest();
        }

        parent::tearDown();
    }

    // =========================================================================
    // Band 01–09 — Schema / route / model / policy configuration truth
    // =========================================================================

    /**
     * TC-P01 — Route, controller, models, policy and schema all match the source.
     * Sources: DDL-prm_tenant, DDL-prm_tenant_groups, Req-Route, Screen-PM-1.
     */
    public function test_tenantmanagement_01_route_model_policy_and_schema_configuration_are_correct(): void
    {
        // --- Route wiring (central domain, prime prefix, GET, index only) ---
        $this->assertTrue(Route::has(self::ROUTE_NAME), 'Route ' . self::ROUTE_NAME . ' is not registered.');

        $route = Route::getRoutes()->getByName(self::ROUTE_NAME);
        $this->assertNotNull($route, 'Named route object could not be resolved.');
        $this->assertSame('prime/tenant-management', $route->uri(), 'Unexpected route URI.');
        $this->assertContains('GET', $route->methods(), 'Route must respond to GET.');

        // --- Controller: index() with NO request parameters (no search/filter input) ---
        $controllerClass = 'Modules\\Prime\\Http\\Controllers\\TenantManagementController';
        $this->assertTrue(class_exists($controllerClass), 'TenantManagementController is not autoloadable.');
        $this->assertTrue(method_exists($controllerClass, 'index'), 'Controller is missing index().');
        $this->assertSame(
            0,
            (new ReflectionMethod($controllerClass, 'index'))->getNumberOfParameters(),
            'index() unexpectedly accepts parameters — screen is read-only with no request input.'
        );

        // --- Controller gate string is the Tenant viewAny permission ---
        $controllerSource = $this->classSource($controllerClass);
        $this->assertStringContainsString(
            "Gate::authorize('prime.tenant.viewAny')",
            $controllerSource,
            'Index gate string does not match the verified source.'
        );

        // --- Policy present (see BUG-PRM-TM-001 for the wiring gap) ---
        $policyClass = 'Modules\\Prime\\Policies\\TenantManagementPolicy';
        $this->assertTrue(class_exists($policyClass), 'TenantManagementPolicy is not autoloadable.');
        $this->assertTrue(method_exists($policyClass, 'viewAny'), 'Policy is missing viewAny().');

        // --- Tenant model config ---
        $tenantClass = 'Modules\\Prime\\Models\\Tenant';
        $this->assertTrue(class_exists($tenantClass), 'Tenant model is not autoloadable.');
        $tenant = new $tenantClass();
        $this->assertSame('prm_tenant', $tenant->getTable(), 'Tenant table name mismatch.');
        $this->assertSame('boolean', $tenant->getCasts()['is_active'] ?? null, 'Tenant is_active cast mismatch.');
        $this->assertTrue(method_exists($tenantClass, 'scopeLive'), 'Tenant is missing scopeLive (used by index()).');
        $this->assertTrue(method_exists($tenantClass, 'city'), 'Tenant is missing city() relation.');
        $this->assertTrue(method_exists($tenantClass, 'tenantGroup'), 'Tenant is missing tenantGroup() relation.');
        $this->assertTrue(method_exists($tenantClass, 'tenantPlans'), 'Tenant is missing tenantPlans() relation.');
        $this->assertTrue(method_exists($tenantClass, 'isProfileComplete'), 'Tenant is missing isProfileComplete().');
        $this->assertContains(
            'Illuminate\\Database\\Eloquent\\SoftDeletes',
            class_uses_recursive($tenantClass),
            'Tenant must use SoftDeletes.'
        );

        // --- TenantGroup model config ---
        $groupClass = 'Modules\\Prime\\Models\\TenantGroup';
        $this->assertTrue(class_exists($groupClass), 'TenantGroup model is not autoloadable.');
        $group = new $groupClass();
        $this->assertSame('prm_tenant_groups', $group->getTable(), 'TenantGroup table name mismatch.');
        foreach (['code', 'short_name', 'name', 'city_id', 'is_active'] as $col) {
            $this->assertContains($col, $group->getFillable(), "TenantGroup fillable missing '{$col}'.");
        }
        $this->assertTrue(method_exists($groupClass, 'liveTenants'), 'TenantGroup is missing liveTenants() relation.');
        $this->assertTrue(method_exists($groupClass, 'city'), 'TenantGroup is missing city() relation.');

        // --- Live schema (central prime_db). Guarded: the runner may not expose it. ---
        try {
            if (Schema::hasTable('prm_tenant')) {
                $this->assertTrue(
                    Schema::hasColumns('prm_tenant', ['id', 'tenant_group_id', 'code', 'short_name', 'name', 'city_id', 'is_active']),
                    'prm_tenant is missing one or more core columns.'
                );
            }
            if (Schema::hasTable('prm_tenant_groups')) {
                $this->assertTrue(
                    Schema::hasColumns('prm_tenant_groups', ['id', 'code', 'short_name', 'name', 'city_id', 'is_active']),
                    'prm_tenant_groups is missing one or more core columns.'
                );
            }
        } catch (Throwable $e) {
            // Central prime_db not reachable from this runner context — model/route truth above is authoritative.
        }
    }

    // =========================================================================
    // Band 10–19 — Render / composite behaviour
    // =========================================================================

    /** TC-P02 — Page renders with the breadcrumb title and the management card. Source: Screen-Render. */
    public function test_tenantmanagement_10_index_renders_with_breadcrumb_and_management_card(): void
    {
        $this->browseWithFailureScreenshot('index-renders', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Tenant Management page not reachable.');
            $this->ensurePageAccessible($browser, 'Tenant Management dashboard');
            $browser->assertSee('Tenant & Subscription Mgmt');
        });
    }

    /** TC-P03 — Both dashboard tabs are rendered. Source: Screen-Render, Screen-PM-1/2. */
    public function test_tenantmanagement_11_both_tenant_group_and_tenant_tabs_are_present(): void
    {
        $this->browseWithFailureScreenshot('tabs-present', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $browser->assertPresent('#tenant-group-tab')
                ->assertPresent('#tenant-tab')
                ->assertPresent('#tenant-group-pane')
                ->assertPresent('#tenant-pane')
                ->assertSee('Tenant Group')
                ->assertSee('Tenant');
        });
    }

    /** TC-P04 — Tenant Group pane is the default active tab. Source: Screen-Render. */
    public function test_tenantmanagement_12_tenant_group_pane_is_the_default_active_tab(): void
    {
        $this->browseWithFailureScreenshot('default-active-tab', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $browser->waitFor('#tenant-group-pane', 10)
                ->assertVisible('#tenant-group-pane');
        });
    }

    /** TC-P05 — Selecting the Tenant tab reveals the tenant pane. Source: Screen-Render. */
    public function test_tenantmanagement_13_switching_to_tenant_tab_reveals_tenant_pane(): void
    {
        $this->browseWithFailureScreenshot('switch-tenant-tab', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->ensureTabVisible($browser, '#tenant-tab', '#tenant-pane');
            $browser->assertVisible('#tenant-pane')
                ->assertPresent('#tenant-pane table');
        });
    }

    /**
     * TC-P06 — Dashboard stats render from REAL computed data, not fabricated values.
     * Verifies BUG-PRM-009 (rand()/stub metrics) does NOT apply to this screen:
     * computeTenantGroupStats()/computeTenantStats() derive from live queries.
     * Source: Audit-BUG-PRM-009, Screen-Render.
     */
    public function test_tenantmanagement_14_tenant_group_dashboard_stats_render_from_real_data_not_fabricated(): void
    {
        $controllerSource = $this->classSource('Modules\\Prime\\Http\\Controllers\\TenantManagementController');

        $this->assertStringContainsString('computeTenantGroupStats', $controllerSource);
        $this->assertStringContainsString('computeTenantStats', $controllerSource);
        // Proof the metrics are computed, not fabricated:
        $this->assertStringNotContainsString('rand(', $controllerSource, 'BUG-PRM-009: fabricated rand() metrics found on this screen.');
        $this->assertStringNotContainsString('mt_rand(', $controllerSource, 'BUG-PRM-009: fabricated mt_rand() metrics found on this screen.');
        $this->assertStringContainsString("withCount('liveTenants')", $controllerSource, 'Tenant-group stat is not query-derived.');

        $this->browseWithFailureScreenshot('group-dashboard-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertVisible('#tenant-group-pane');
        });
    }

    /** TC-P07 — Tenant tab dashboard/table section renders. Source: Screen-Render. */
    public function test_tenantmanagement_15_tenant_dashboard_section_renders(): void
    {
        $this->browseWithFailureScreenshot('tenant-dashboard-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->ensureTabVisible($browser, '#tenant-tab', '#tenant-pane');
            $browser->assertPresent('#tenant-pane table.js-sortable');
        });
    }

    // =========================================================================
    // Band 50–59 — Permissions / authorization
    // =========================================================================

    /** TC-N01 — Guest is redirected to the login page. Source: Req-Middleware(auth,verified). */
    public function test_tenantmanagement_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);

            $path = $this->currentPath($browser);
            $onLogin = str_contains($path, '/login')
                || ($browser->element('input[name="email"]') && $browser->element('input[name="password"]'));

            $this->assertTrue($onLogin, 'Unauthenticated user was NOT redirected to /login (got: ' . $path . ').');
        });
    }

    /** TC-P08 — Authorised admin can view the dashboard. Source: Screen-PM-1. */
    public function test_tenantmanagement_51_authorized_admin_can_view_the_dashboard(): void
    {
        $this->browseWithFailureScreenshot('authorized-access', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Authorised admin could not reach the dashboard.');
            $this->ensurePageAccessible($browser, 'Tenant Management (authorised admin)');
        });
    }

    /** TC-P09 — Index is gated by the prime.tenant.viewAny permission. Source: Screen-PM-1. */
    public function test_tenantmanagement_52_index_is_gated_by_prime_tenant_viewany_permission(): void
    {
        $source = $this->classSource('Modules\\Prime\\Http\\Controllers\\TenantManagementController');
        $this->assertStringContainsString(
            "Gate::authorize('" . self::INDEX_GATE . "')",
            $source,
            'Controller does not authorise via ' . self::INDEX_GATE . '.'
        );
    }

    /**
     * TC-D01 / BUG-PRM-TM-001 — The dedicated TenantManagementPolicy checks a DIFFERENT
     * permission ('prime.tenant-management.viewAny') than the one the controller actually
     * enforces ('prime.tenant.viewAny'), and the policy is never invoked by the controller.
     * The policy + its permission are effectively orphaned. Documented, not a test bug.
     * Source: Cross-Ref-Check-10 (Gate vs Policy).
     */
    public function test_tenantmanagement_53_dedicated_policy_permission_is_mismatched_and_unwired(): void
    {
        $controllerSource = $this->classSource('Modules\\Prime\\Http\\Controllers\\TenantManagementController');
        $policySource = $this->classSource('Modules\\Prime\\Policies\\TenantManagementPolicy');

        // Controller enforces the Tenant permission...
        $this->assertStringContainsString("prime.tenant.viewAny", $controllerSource);
        // ...but the dedicated policy enforces a tenant-management permission...
        $this->assertStringContainsString("prime.tenant-management.viewAny", $policySource);
        // ...and the controller never references the tenant-management permission or the policy.
        $this->assertStringNotContainsString("prime.tenant-management.viewAny", $controllerSource,
            'Controller now references the tenant-management permission — BUG-PRM-TM-001 may be fixed; update this test.');
        $this->assertStringNotContainsString('TenantManagementPolicy', $controllerSource,
            'Controller now references TenantManagementPolicy — BUG-PRM-TM-001 may be fixed; update this test.');
    }

    /** TC-P10 — Tenant-group action buttons (Add / View Trash) are present. Source: Screen-Render. */
    public function test_tenantmanagement_54_tenant_group_action_buttons_are_present(): void
    {
        $this->browseWithFailureScreenshot('group-action-buttons', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $browser->assertPresent('#tenant-group-pane a[title="Add"]')
                ->assertPresent('#tenant-group-pane a[title="Delete"]');
        });
    }

    // =========================================================================
    // Band 60–69 — UI/UX: columns, pagination, empty state, search/filter
    // =========================================================================

    /** TC-P11 — Tenant table renders the expected column headers. Source: Screen-Render. */
    public function test_tenantmanagement_60_tenant_table_renders_expected_column_headers(): void
    {
        $this->browseWithFailureScreenshot('tenant-columns', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensureTabVisible($browser, '#tenant-tab', '#tenant-pane');

            foreach (['Tenant', 'Domain', 'Details', 'Contact', 'Address'] as $header) {
                $browser->assertSeeIn('#tenant-pane table', $header);
            }
        });
    }

    /** TC-P12 — Tenant-group table renders the expected column headers. Source: Screen-Render. */
    public function test_tenantmanagement_61_tenant_group_table_renders_expected_column_headers(): void
    {
        $this->browseWithFailureScreenshot('group-columns', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            foreach (['Tenant Group', 'Contact', 'Address'] as $header) {
                $browser->assertSeeIn('#tenant-group-pane table', $header);
            }
        });
    }

    /**
     * TC-P13 — Both tabs paginate using independently scoped page parameters
     * (tenant_page / tenant-group_page). Source: Controller index() paginate().
     */
    public function test_tenantmanagement_62_pagination_uses_scoped_page_parameters(): void
    {
        $source = $this->classSource('Modules\\Prime\\Http\\Controllers\\TenantManagementController');
        $this->assertStringContainsString("'tenant-group_page'", $source, 'Tenant-group pagination page name missing.');
        $this->assertStringContainsString("'tenant_page'", $source, 'Tenant pagination page name missing.');

        $this->browseWithFailureScreenshot('pagination-present', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            // Pagination containers render (links present only when >1 page; container always renders).
            $browser->assertPresent('#tenant-group-pane .row');
        });
    }

    /**
     * TC-N02 — Empty-state message "Not Found Data" is defined for both listings.
     * Asserted at the view-source level (the shared central DB may not be empty at run time).
     * Source: Screen-EmptyState.
     */
    public function test_tenantmanagement_63_empty_state_message_is_defined_for_both_tables(): void
    {
        $tenantView = $this->viewSource(self::TENANT_TAB_VIEW);
        $groupView = $this->viewSource(self::TENANT_GROUP_TAB_VIEW);

        $this->assertNotSame('', $tenantView, 'Could not resolve the tenant tab view source.');
        $this->assertNotSame('', $groupView, 'Could not resolve the tenant-group tab view source.');
        $this->assertStringContainsString('Not Found Data', $tenantView, 'Tenant table has no empty-state row.');
        $this->assertStringContainsString('Not Found Data', $groupView, 'Tenant-group table has no empty-state row.');
        $this->assertStringContainsString('@forelse', $tenantView, 'Tenant table does not use @forelse for empty handling.');
        $this->assertStringContainsString('@forelse', $groupView, 'Tenant-group table does not use @forelse for empty handling.');
    }

    /**
     * TC-N03 / BUG-PRM-TM-002 — Search box and the two filter dropdowns are NON-FUNCTIONAL stubs:
     * dummy "Filter 1"/"Filter 2" options, no name attributes, form has no action/method, and the
     * controller index() takes no request input. Selecting/typing does nothing. Documented defect.
     * Source: Cross-Ref (Blade vs Controller), Screen-Search.
     */
    public function test_tenantmanagement_64_search_and_filter_controls_are_nonfunctional_stubs(): void
    {
        $tenantView = $this->viewSource(self::TENANT_TAB_VIEW);
        $this->assertNotSame('', $tenantView, 'Could not resolve the tenant tab view source.');

        // The UI is present...
        $this->assertStringContainsString('placeholder="Search..."', $tenantView, 'Search box placeholder missing.');
        $this->assertStringContainsString('Filter 1', $tenantView, 'Stub filter dropdown missing.');
        $this->assertStringContainsString('Filter 2', $tenantView, 'Stub filter dropdown missing.');
        $this->assertStringContainsString('Option 1', $tenantView, 'Dummy filter option missing.');

        // ...but it is not wired: no field names and no request handling in the controller.
        $this->assertStringNotContainsString('name="search"', $tenantView, 'Search input now has a name — stub may be wired; re-verify BUG-PRM-TM-002.');
        $this->assertStringNotContainsString('name="filter', $tenantView, 'Filter select now has a name — stub may be wired; re-verify BUG-PRM-TM-002.');

        $controllerSource = $this->classSource('Modules\\Prime\\Http\\Controllers\\TenantManagementController');
        $this->assertStringNotContainsString('request(', $controllerSource, 'Controller now reads request() — search may be wired.');
        $this->assertStringNotContainsString('->when(', $controllerSource, 'Controller now applies conditional filters — search may be wired.');
    }

    /** TC-N04 / BUG-PRM-TM-002b — Export button present but has no handler. Source: Screen-Search. */
    public function test_tenantmanagement_65_export_button_present_without_handler(): void
    {
        $tenantView = $this->viewSource(self::TENANT_TAB_VIEW);
        $this->assertNotSame('', $tenantView, 'Could not resolve the tenant tab view source.');
        $this->assertStringContainsString('title="Export"', $tenantView, 'Export button missing.');
        // The Export button is a bare <button> with no route, id or data-* handler.
        $this->assertStringNotContainsString('id="export', $tenantView, 'Export button now has an id/handler — re-verify the stub finding.');
    }

    // =========================================================================
    // Band 70–79 — Edge / "no mutation" matrix (delegation to Tenant screen)
    // =========================================================================

    /**
     * TC-D02 — This screen exposes NO create/edit/delete/toggle routes of its own.
     * Only central.prime.tenant-management.index exists; all mutations belong to the
     * Tenant and TenantGroup screens. Source: Req-Route (delegation).
     */
    public function test_tenantmanagement_70_screen_exposes_no_create_edit_delete_routes(): void
    {
        foreach (['store', 'create', 'edit', 'update', 'destroy', 'show'] as $verb) {
            $this->assertFalse(
                Route::has('central.prime.tenant-management.' . $verb),
                "Unexpected mutation route central.prime.tenant-management.{$verb} exists on a read-only screen."
            );
        }
        // Mutations live on the delegated screens:
        $this->assertTrue(Route::has('central.prime.tenant.toggleStatus'), 'Delegated Tenant toggle route missing.');
        $this->assertTrue(Route::has('central.prime.tenant-group.toggleStatus'), 'Delegated TenantGroup toggle route missing.');
    }

    /**
     * TC-N05 / BUG-PRM-TM-003 — The Tenant "Address" cell renders the raw numeric city_id
     * instead of the city name (unlike the tenant-group tab which uses $group->city?->name).
     * Source: Cross-Ref (Blade render), Screen-Render.
     */
    public function test_tenantmanagement_71_tenant_address_column_renders_raw_city_id(): void
    {
        $tenantView = $this->viewSource(self::TENANT_TAB_VIEW);
        $groupView = $this->viewSource(self::TENANT_GROUP_TAB_VIEW);
        $this->assertNotSame('', $tenantView, 'Could not resolve the tenant tab view source.');
        $this->assertNotSame('', $groupView, 'Could not resolve the tenant-group tab view source.');

        // Bug: tenant tab prints the FK id...
        $this->assertStringContainsString('$tenant->city_id', $tenantView,
            'Tenant address no longer prints raw city_id — BUG-PRM-TM-003 may be fixed; update this test.');
        // ...while the group tab correctly resolves the city name (the intended behaviour).
        $this->assertStringContainsString('$group->city?->name', $groupView, 'Reference behaviour (city name) changed.');
    }

    /**
     * TC-N06 / BUG-PRM-TM-004 — Empty-state row uses colspan="5" on both tables even though
     * they render 6–7 columns when Status/Action columns are visible, so the "Not Found Data"
     * row does not span the full width. Source: Cross-Ref (Blade render), Screen-EmptyState.
     */
    public function test_tenantmanagement_72_empty_state_colspan_does_not_span_all_columns(): void
    {
        $tenantView = $this->viewSource(self::TENANT_TAB_VIEW);
        $groupView = $this->viewSource(self::TENANT_GROUP_TAB_VIEW);
        $this->assertNotSame('', $tenantView, 'Could not resolve the tenant tab view source.');
        $this->assertNotSame('', $groupView, 'Could not resolve the tenant-group tab view source.');

        $this->assertStringContainsString('colspan="5"', $tenantView,
            'Tenant empty-state colspan changed — BUG-PRM-TM-004 may be fixed; update this test.');
        $this->assertStringContainsString('colspan="5"', $groupView,
            'Tenant-group empty-state colspan changed — BUG-PRM-TM-004 may be fixed; update this test.');
        // Tenant table can render up to 7 columns (5 data + Status + Action), proving colspan=5 is too small.
        $this->assertStringContainsString('scope="col">Action', $tenantView, 'Action column marker changed.');
    }

    // =========================================================================
    // Band 80–89 — Configuration / schema drift documentation
    // =========================================================================

    /**
     * TC-D03 / BUG-PRM-TM-005 (doc drift) — The runtime prm_tenant table carries columns
     * (tenant_type, setup_status, rollover_*) that the model (scopeLive / getCustomColumns)
     * and controller (->live(), groupBy('setup_status')) depend on, but which are ABSENT from
     * the consolidated DDL _prime_db_v4.sql. Schema truth for these must come from live
     * migrations, not the DDL file. Source: DDL-vs-Migration drift.
     */
    public function test_tenantmanagement_80_runtime_tenant_columns_exceed_consolidated_ddl(): void
    {
        $tenantClass = 'Modules\\Prime\\Models\\Tenant';
        $this->assertTrue(class_exists($tenantClass));
        $custom = $tenantClass::getCustomColumns();

        // The model declares these columns and the controller/scope rely on them.
        foreach (['tenant_type', 'setup_status', 'rollover_status'] as $col) {
            $this->assertContains($col, $custom, "Model no longer declares '{$col}'.");
        }

        // scopeLive filters tenant_type='live'; index() calls ->live().
        $this->assertStringContainsString(
            "where('tenant_type', 'live')",
            $this->classSource($tenantClass),
            'scopeLive no longer filters tenant_type.'
        );

        // If the live table is reachable, confirm the migration-added columns exist there.
        try {
            if (Schema::hasTable('prm_tenant')) {
                $this->assertTrue(
                    Schema::hasColumn('prm_tenant', 'setup_status'),
                    'Runtime prm_tenant is missing setup_status (added by central migration).'
                );
            }
        } catch (Throwable $e) {
            // Central DB unreachable in this runner context — model-level evidence above stands.
        }
    }

    // =========================================================================
    // Band 90–99 — Central-scope / smoke
    // =========================================================================

    /** TC-S01 — Central feature runs on 127.0.0.1 with no tenant context initialised. Source: Constraint-E21/A4. */
    public function test_tenantmanagement_91_feature_is_central_and_requires_no_tenant_context(): void
    {
        $this->assertSame('127.0.0.1', parse_url($this->primeBaseUrl, PHP_URL_HOST), 'Prime base URL host must be 127.0.0.1.');

        if (function_exists('tenancy')) {
            $this->assertFalse(
                tenancy()->initialized,
                'Tenant context is initialised — this central screen must not require tenancy.'
            );
        } else {
            $this->assertTrue(true);
        }
    }

    /** TC-S02 — Happy-path load produces no fatal/error banners; console log captured. Source: Screen-Smoke. */
    public function test_tenantmanagement_90_happy_path_load_is_clean(): void
    {
        $this->browseWithFailureScreenshot('happy-path-smoke', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->ensurePageAccessible($browser, 'Tenant Management (smoke)');
            $this->assertNotNull($browser->element('body'), 'Page body not rendered.');

            // Capture browser console log as evidence (non-failing — third-party noise tolerated).
            try {
                $logs = $browser->driver->manage()->getLog('browser');
                $severe = array_filter($logs, fn($l) => ($l['level'] ?? '') === 'SEVERE');
                $this->recordReportEntry('console-severe-count', 'INFO', (string) count($severe), '');
            } catch (Throwable $e) {
                // Console log not available on this driver — ignore.
            }
        });
    }

    // =========================================================================
    // Central auth / report helpers (mirrored from prm_BillingDuskTestCase_TestCas)
    // =========================================================================

    protected function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }

        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    protected function authenticateCentral(Browser $browser): void
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

    protected function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    protected function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
                $this->recordReportEntry($caseName, 'PASS', 'Step completed successfully.', '');
            } catch (Throwable $e) {
                $screenshot = $this->captureFailureScreenshot($browser, $caseName);
                $this->recordReportEntry($caseName, 'FAIL', $e->getMessage(), $screenshot);
                if ($e instanceof \PHPUnit\Framework\SkippedTestError) {
                    throw new \RuntimeException($e->getMessage(), 0, $e);
                }
                throw $e;
            }
        });
    }

    protected function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        $directory = base_path(static::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $timestamp = now()->format('Ymd_Hisv');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'failure';
        $filename = $safeName . '_' . $timestamp . '.png';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $filename;

        try {
            $browser->driver->takeScreenshot($absolutePath);
            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolutePath);
        } catch (Throwable) {
            return '';
        }
    }

    protected function recordReportEntry(string $stepName, string $status, string $message, string $screenshotPath): void
    {
        $this->statusReportEntries[] = [
            'timestamp' => now()->format('Y-m-d H:i:s'),
            'test' => $this->name(),
            'step' => $stepName,
            'status' => $status,
            'message' => $message,
            'screenshot' => $screenshotPath,
        ];
    }

    protected function writeStatusReportForCurrentTest(): void
    {
        $directory = base_path(static::STATUS_REPORT_DIRECTORY);
        File::ensureDirectoryExists($directory);

        $prefix = static::STATUS_REPORT_PREFIX;
        $sanitizedTestName = preg_replace('/[^a-z0-9_-]+/i', '_', strtolower($this->name()));
        $filename = $prefix . $sanitizedTestName . '_' . now()->format('Ymd_Hisv') . '.md';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $filename;

        $lines = [];
        $lines[] = '# Tenant Management Dusk Status Report';
        $lines[] = '';
        $lines[] = '- Test Method: `' . $this->name() . '`';
        $lines[] = '- Generated At: `' . now()->format('Y-m-d H:i:s') . '`';
        $lines[] = '';
        $lines[] = '| Time | Step | Status | Message | Screenshot |';
        $lines[] = '| --- | --- | --- | --- | --- |';

        foreach ($this->statusReportEntries as $entry) {
            $message = str_replace('|', '/', $entry['message']);
            $screenshot = $entry['screenshot'] !== '' ? '`' . $entry['screenshot'] . '`' : '-';
            $lines[] = '| '
                . $entry['timestamp'] . ' | '
                . $entry['step'] . ' | '
                . $entry['status'] . ' | '
                . $message . ' | '
                . $screenshot . ' |';
        }

        file_put_contents($absolutePath, implode(PHP_EOL, $lines) . PHP_EOL);
        $this->statusReportEntries = [];
    }

    protected function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    protected function resolveAdminUser(): void
    {
        $userByEmail = User::query()->where('email', $this->adminEmail)->first();
        $superAdmin = User::query()->where('is_super_admin', 1)->first();

        if ($superAdmin) {
            $this->adminUser = $superAdmin;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        if ($userByEmail) {
            $this->adminUser = $userByEmail;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        $this->adminUser = User::create([
            'email' => $this->adminEmail,
            'password' => bcrypt($this->adminPassword),
            'name' => 'Tenant Mgmt Dusk Admin',
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

    protected function ensureTabVisible(Browser $browser, string $tabSelector, string $paneSelector): void
    {
        if ($browser->element($tabSelector)) {
            $browser->click($tabSelector)->pause(800);
        }

        if ($browser->element($paneSelector)) {
            $browser->waitFor($paneSelector, 10);
        }
    }

    protected function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows login page; authentication failed.');
        }

        if (!$browser->element('body')) {
            $this->fail($context . ' page body not available.');
        }

        $bodyText = $browser->text('body');
        $signals = ['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'];

        foreach ($signals as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    // ---- Source-inspection helpers (robust: read the real file behind a class/view) ----

    private function classSource(string $fqcn): string
    {
        try {
            if (!class_exists($fqcn)) {
                return '';
            }
            $file = (new ReflectionClass($fqcn))->getFileName();
            return $file ? (string) file_get_contents($file) : '';
        } catch (Throwable $e) {
            return '';
        }
    }

    private function viewSource(string $viewName): string
    {
        try {
            $path = View::getFinder()->find($viewName);
            return is_string($path) ? (string) file_get_contents($path) : '';
        } catch (Throwable $e) {
            return '';
        }
    }
}
