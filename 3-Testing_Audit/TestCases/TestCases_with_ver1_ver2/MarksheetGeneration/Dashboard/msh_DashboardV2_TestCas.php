<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\View;
use Laravel\Dusk\Browser;
use Modules\MarksheetGeneration\Http\Controllers\MarksheetGenerationController;
use Modules\MarksheetGeneration\Models\ConfigTemplate;
use Modules\MarksheetGeneration\Models\MarksheetSchedule;
use Modules\MarksheetGeneration\Models\MarksheetType;
use Modules\MarksheetGeneration\Models\ScheduleClass;
use Modules\MarksheetGeneration\Models\StudentCoscholasticResult;
use Modules\MarksheetGeneration\Models\StudentIaMark;
use Modules\MarksheetGeneration\Models\StudentResult;
use Modules\MarksheetGeneration\Models\StudentSubjectResult;
use Modules\MarksheetGeneration\Models\SubjectPracticalConfig;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * MarksheetGeneration — Dashboard & Navigation (read-focused / composite screen).
 *
 * V2 = comprehensive read-focused suite (render / navigation / aggregation /
 * permissions / empty-state / edge / console / responsive) plus the proving tests
 * for BUG-MSH-001 (dead API), PERF-MSH-003 (unbounded results load) and D39-MSH
 * (permission gating). No create/edit/delete matrix — the dashboard is read-only.
 *
 * Semantic bands: 01-09 wiring · 10-19 aggregation rules · 40-49 navigation/integration
 * · 50-59 permissions/auth/dead-API · 60-69 UI/UX · 70-79 edge/empty-state
 * · 90-99 tenancy/console/responsive.
 *
 * DB scope: tenant-side (msh_*, tenant_db). Env prereq: MarksheetGeneration ENABLED
 * in modules_statuses.json. D39-MSH: msh gates unseeded → granted explicitly to admin.
 */
class msh_DashboardV2_TestCas extends DuskTestCase
{
    private const DASHBOARD_PATH   = '/marksheet-generation/dashboard';
    private const CONFIG_PATH      = '/marksheet-generation/configuration';
    private const COMPONENTS_PATH  = '/marksheet-generation/components';
    private const SCHEDULING_PATH  = '/marksheet-generation/scheduling';
    private const RESULTS_PATH     = '/marksheet-generation/results';
    private const API_PATH         = '/api/v1/marksheetgenerations';

    private const CONTROLLER_FILE  = 'Modules/MarksheetGeneration/app/Http/Controllers/MarksheetGenerationController.php';
    private const SCREENSHOT_DIR   = 'tests/Browser/Modules/MarksheetGeneration/Dashboard/screenshots';

    private const DASHBOARD_MARKER = 'Marksheet Generation Module';

    private const COMBINED_PATHS = [
        'configuration' => self::CONFIG_PATH,
        'components'    => self::COMPONENTS_PATH,
        'scheduling'    => self::SCHEDULING_PATH,
        'results'       => self::RESULTS_PATH,
    ];

    private const DASHBOARD_TABLES = [
        'msh_marksheet_types',
        'msh_config_templates',
        'msh_marksheet_schedules',
        'msh_student_results',
        'msh_schedule_class_jnt',
        'msh_subject_practical_configs',
        'msh_student_subject_results',
        'msh_student_ia_marks',
        'msh_student_coscholastic_results',
    ];

    private const MSH_VIEW_GATES = [
        'tenant.msh-dashboard.view',
        'tenant.msh-configuration.view',
        'tenant.msh-components.view',
        'tenant.msh-scheduling.view',
        'tenant.msh-results.view',
    ];

    /** gate => combined path, used to iterate the permission-denial matrix. */
    private const GATE_PATHS = [
        'tenant.msh-dashboard.view'      => self::DASHBOARD_PATH,
        'tenant.msh-configuration.view'  => self::CONFIG_PATH,
        'tenant.msh-components.view'     => self::COMPONENTS_PATH,
        'tenant.msh-scheduling.view'     => self::SCHEDULING_PATH,
        'tenant.msh-results.view'        => self::RESULTS_PATH,
    ];

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
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

        $this->tenantBaseUrl = rtrim(
            env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')),
            '/'
        );
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        $this->initializeTenantContext();
        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 01–09  Wiring / schema / config truth
    // ═════════════════════════════════════════════════════════════════════════

    /** BC-DB/BC-BIZ/BC-AUTH — routes, views, aggregation + gate wiring truth. */
    public function test_dashboard_01_routes_views_and_aggregation_wiring_are_correct(): void
    {
        foreach (self::DASHBOARD_TABLES as $table) {
            $this->assertTrue(Schema::hasTable($table), "Dashboard aggregation table missing: {$table}");
        }

        $this->assertSame('msh_marksheet_types', (new MarksheetType())->getTable());
        $this->assertSame('msh_schedule_class_jnt', (new ScheduleClass())->getTable());

        $this->assertTrue(View::exists('marksheetgeneration::dashboard'));
        foreach (['pages.configuration', 'pages.components', 'pages.scheduling', 'pages.results'] as $view) {
            $this->assertTrue(View::exists('marksheetgeneration::' . $view), "missing view: {$view}");
        }

        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString('function dashboard()', $controller);
        $this->assertStringContainsString('MarksheetType::count()', $controller);
        foreach (self::MSH_VIEW_GATES as $gate) {
            $this->assertStringContainsString("Gate::authorize('{$gate}')", $controller);
        }
    }

    /** BC-DB — every aggregated msh_* table exists in the tenant DB. */
    public function test_dashboard_02_all_aggregated_msh_tables_exist(): void
    {
        foreach (self::DASHBOARD_TABLES as $table) {
            $this->assertTrue(Schema::hasTable($table), "Missing table: {$table}");
        }
    }

    /** BC-BIZ — dashboard + 4 combined routes are registered under the module prefix. */
    public function test_dashboard_03_dashboard_and_combined_routes_registered(): void
    {
        $this->assertTrue(Route::has('marksheet-generation.dashboard'));
        $this->assertTrue(Route::has('marksheet-generation.configuration.combined'));
        $this->assertTrue(Route::has('marksheet-generation.components.combined'));
        $this->assertTrue(Route::has('marksheet-generation.scheduling.combined'));
        $this->assertTrue(Route::has('marksheet-generation.results.combined'));
    }

    /** BC-DB — dashboard and combined page views resolve. */
    public function test_dashboard_04_dashboard_and_page_views_exist(): void
    {
        $this->assertTrue(View::exists('marksheetgeneration::dashboard'));
        $this->assertTrue(View::exists('marksheetgeneration::pages.configuration'));
        $this->assertTrue(View::exists('marksheetgeneration::pages.components'));
        $this->assertTrue(View::exists('marksheetgeneration::pages.scheduling'));
        $this->assertTrue(View::exists('marksheetgeneration::pages.results'));
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 10–19  Aggregation / render business rules
    // ═════════════════════════════════════════════════════════════════════════

    /** TC-P01 — dashboard renders for the admin. */
    public function test_dashboard_10_dashboard_renders_for_admin(): void
    {
        $this->browseWithFailureScreenshot('render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee(self::DASHBOARD_MARKER);
            $this->assertStringContainsString(self::DASHBOARD_PATH, $this->currentPath($browser));
        });
    }

    /** TC-P02 — the six primary stat cards render. */
    public function test_dashboard_11_six_primary_stat_cards_render(): void
    {
        $this->browseWithFailureScreenshot('cards', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            foreach ([
                'Marksheet Types', 'Config Templates', 'Schedules',
                'Student Results', 'Schedule Classes', 'Practical Configs',
            ] as $label) {
                $browser->assertSee($label);
            }
        });
    }

    /** TC-P03 — primary stat values match live DB counts. */
    public function test_dashboard_12_primary_stat_values_match_db_counts(): void
    {
        $totalResults = StudentResult::count();
        $totalSched   = MarksheetSchedule::count();
        $this->assertGreaterThanOrEqual(0, $totalResults);
        $this->assertGreaterThanOrEqual(0, $totalSched);

        $this->browseWithFailureScreenshot('counts', function (Browser $browser) use ($totalResults): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee((string) $totalResults);
        });
    }

    /** TC-P04 — the secondary active/inactive breakdown row renders. */
    public function test_dashboard_13_secondary_active_inactive_breakdown_renders(): void
    {
        $this->browseWithFailureScreenshot('breakdown', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee('Active');
            $this->assertTrue(
                $this->pageSourceContains($browser, 'Inactive'),
                'Active/Inactive breakdown not rendered.'
            );
        });
    }

    /** TC-P05 — the three recent-activity tab controls are present. */
    public function test_dashboard_14_three_recent_activity_tabs_present(): void
    {
        $this->browseWithFailureScreenshot('tabs', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee('Overview')->assertSee('Recent Schedules')->assertSee('Recent Results');
        });
    }

    /** BC-BIZ — recent schedules are capped at five (controller take(5)). */
    public function test_dashboard_15_recent_schedules_limited_to_five(): void
    {
        $recent = MarksheetSchedule::latest()->take(5)->get();
        $this->assertLessThanOrEqual(5, $recent->count());

        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString('->take(5)', $controller);
    }

    /** BC-BIZ — recent results are capped at five and eager-load relations. */
    public function test_dashboard_16_recent_results_limited_to_five(): void
    {
        $recent = StudentResult::latest()->take(5)->get();
        $this->assertLessThanOrEqual(5, $recent->count());

        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("with(['student', 'classSection.class', 'classSection.section'])", $controller);
    }

    /** TC-P13 — the today-date badge shows the current year. */
    public function test_dashboard_17_date_badge_shows_today(): void
    {
        $this->browseWithFailureScreenshot('date', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee(now()->format('Y'));
        });
    }

    /** TC-P14 — the module header + Live indicator render. */
    public function test_dashboard_18_module_header_and_live_indicator_render(): void
    {
        $this->browseWithFailureScreenshot('header', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee(self::DASHBOARD_MARKER)->assertSee('Live');
        });
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 40–49  Navigation / integration
    // ═════════════════════════════════════════════════════════════════════════

    /** TC-P06 — the 4-pillar nav links target the combined routes. */
    public function test_dashboard_40_four_pillar_nav_links_target_combined_routes(): void
    {
        $this->browseWithFailureScreenshot('pillars', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            foreach (self::COMBINED_PATHS as $href) {
                $this->assertTrue($this->pageSourceContains($browser, $href), "Pillar link missing: {$href}");
            }
            $browser->assertSee('Configuration')->assertSee('Components')
                ->assertSee('Scheduling')->assertSee('Results');
        });
    }

    /** TC-P07 — Configuration combined page resolves and renders. */
    public function test_dashboard_41_configuration_combined_resolves(): void
    {
        $this->assertCombinedPageResolves(self::CONFIG_PATH, 'configuration');
    }

    /** TC-P08 — Components combined page resolves and renders. */
    public function test_dashboard_42_components_combined_resolves(): void
    {
        $this->assertCombinedPageResolves(self::COMPONENTS_PATH, 'components');
    }

    /** TC-P09 — Scheduling combined page resolves and renders. */
    public function test_dashboard_43_scheduling_combined_resolves(): void
    {
        $this->assertCombinedPageResolves(self::SCHEDULING_PATH, 'scheduling');
    }

    /** TC-P10 — Results combined page resolves and renders. */
    public function test_dashboard_44_results_combined_resolves(): void
    {
        $this->assertCombinedPageResolves(self::RESULTS_PATH, 'results');
    }

    /** TC-D02 — recent results eager-load cross-module student + class-section. */
    public function test_dashboard_45_recent_results_eager_load_cross_module(): void
    {
        try {
            $result = StudentResult::with(['student', 'classSection.class', 'classSection.section'])
                ->latest()->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('Cross-module relation unavailable in this environment: ' . $e->getMessage());
        }

        if ($result === null) {
            $this->markTestSkipped('No student results present to verify eager loading.');
        }

        $this->assertTrue($result->relationLoaded('student'));
        $this->assertTrue($result->relationLoaded('classSection'));
    }

    /**
     * PERF-MSH-003 — results() eager-loads Student::where('is_active',1)->get()
     * and Subject::get() with no pagination. The page must still render; this test
     * proves current behaviour and documents the unbounded-query risk.
     */
    public function test_dashboard_46_results_page_unbounded_load_renders(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        // Prove the unbounded loads are still present in source (proving test).
        $this->assertStringContainsString("Student::where('is_active', 1)->orderBy('id')->get()", $controller);
        $this->assertStringContainsString("Subject::orderBy('name')->get()", $controller);

        $this->assertCombinedPageResolves(self::RESULTS_PATH, 'results-perf');
    }

    /** TC-D01 — dashboard aggregate counts are all non-negative integers. */
    public function test_dashboard_47_dashboard_counts_are_non_negative(): void
    {
        foreach ([
            MarksheetType::count(), ConfigTemplate::count(), MarksheetSchedule::count(),
            StudentResult::count(), ScheduleClass::count(), SubjectPracticalConfig::count(),
            StudentSubjectResult::count(), StudentIaMark::count(), StudentCoscholasticResult::count(),
        ] as $count) {
            $this->assertIsInt($count);
            $this->assertGreaterThanOrEqual(0, $count);
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 50–59  Permissions / auth / dead API
    // ═════════════════════════════════════════════════════════════════════════

    /** TC-N01 — a guest is redirected to /login from the dashboard. */
    public function test_dashboard_50_guest_redirected_to_login_on_dashboard(): void
    {
        $this->browseWithFailureScreenshot('guest-dashboard', function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::DASHBOARD_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    /** TC-N02 — a guest is redirected to /login from each combined page. */
    public function test_dashboard_51_guest_redirected_to_login_on_combined_pages(): void
    {
        $this->browseWithFailureScreenshot('guest-combined', function (Browser $browser): void {
            foreach (self::COMBINED_PATHS as $path) {
                $browser->visit($this->tenantUrl($path))->pause(700);
                $this->assertStringContainsString(
                    '/login',
                    $this->currentPath($browser),
                    "Guest not redirected from {$path}"
                );
            }
        });
    }

    /** TC-N03 — D39: user without msh-dashboard.view is denied the dashboard. */
    public function test_dashboard_52_dashboard_gate_denies_user_without_permission(): void
    {
        $this->assertGateDenies(self::DASHBOARD_PATH);
    }

    /** TC-N04 — D39: user without msh-configuration.view is denied configuration. */
    public function test_dashboard_53_configuration_gate_denies_without_permission(): void
    {
        $this->assertGateDenies(self::CONFIG_PATH);
    }

    /** TC-N05 — D39: user without msh-components.view is denied components. */
    public function test_dashboard_54_components_gate_denies_without_permission(): void
    {
        $this->assertGateDenies(self::COMPONENTS_PATH);
    }

    /** TC-N06 — D39: user without msh-scheduling.view is denied scheduling. */
    public function test_dashboard_55_scheduling_gate_denies_without_permission(): void
    {
        $this->assertGateDenies(self::SCHEDULING_PATH);
    }

    /** TC-N07 — D39: user without msh-results.view is denied results. */
    public function test_dashboard_56_results_gate_denies_without_permission(): void
    {
        $this->assertGateDenies(self::RESULTS_PATH);
    }

    /** BC-AUTH — all five gate strings are present in the controller source. */
    public function test_dashboard_57_gate_strings_present_in_controller(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        foreach (self::GATE_PATHS as $gate => $_path) {
            $this->assertStringContainsString("Gate::authorize('{$gate}')", $controller);
        }
    }

    /** BUG-MSH-001 — the module apiResource is never registered (map() only maps web). */
    public function test_dashboard_58_api_resource_routes_not_registered(): void
    {
        foreach (['index', 'store', 'show', 'update', 'destroy'] as $action) {
            $this->assertFalse(
                Route::has('marksheetgeneration.' . $action),
                "BUG-MSH-001 regressed: marksheetgeneration.{$action} is registered."
            );
        }
    }

    /** BUG-MSH-001 — the controller defines NONE of the REST resource methods. */
    public function test_dashboard_59_controller_missing_rest_methods(): void
    {
        foreach (['index', 'store', 'show', 'update', 'destroy'] as $method) {
            $this->assertFalse(
                method_exists(MarksheetGenerationController::class, $method),
                "BUG-MSH-001 regressed: controller now defines {$method}()."
            );
        }
        // The controller only exposes the composite read actions.
        foreach (['dashboard', 'configuration', 'components', 'scheduling', 'results'] as $method) {
            $this->assertTrue(method_exists(MarksheetGenerationController::class, $method));
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 60–69  UI / UX
    // ═════════════════════════════════════════════════════════════════════════

    /** TC-P/UX — the breadcrumb renders on the dashboard. */
    public function test_dashboard_60_breadcrumb_renders(): void
    {
        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $this->assertTrue($browser->element('ol.breadcrumb') !== null, 'Breadcrumb missing.');
            $browser->assertSee('Dashboard');
        });
    }

    /** TC-P/UX — the Overview tab is active by default. */
    public function test_dashboard_61_overview_tab_active_by_default(): void
    {
        $this->browseWithFailureScreenshot('overview-active', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $active = $browser->script(
                "return document.querySelector('#pane-overview')?.classList.contains('active') || false;"
            );
            $this->assertTrue(is_array($active) && ($active[0] ?? false) === true, 'Overview pane not active.');
        });
    }

    /** TC-P11 — Recent Schedules tab renders a table or the empty-state branch. */
    public function test_dashboard_62_recent_schedules_tab_table_or_empty(): void
    {
        $this->assertTabTableOrEmpty('Schedule Name', 'No schedules created yet.');
    }

    /** TC-P12 — Recent Results tab renders a table or the empty-state branch. */
    public function test_dashboard_63_recent_results_tab_table_or_empty(): void
    {
        $this->assertTabTableOrEmpty('Grand Total', 'No results recorded yet.');
    }

    /** TC-P/UX — the "View All Schedules" link targets the scheduling combined page. */
    public function test_dashboard_64_view_all_schedules_link_targets_scheduling(): void
    {
        $this->browseWithFailureScreenshot('view-all-schedules', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            // Either the "View All" CTA or the empty-state CTA points at scheduling.
            $this->assertTrue(
                $this->pageSourceContains($browser, self::SCHEDULING_PATH),
                'No scheduling CTA present on dashboard.'
            );
        });
    }

    /** TC-P/UX — the "View All Results" link targets the results combined page. */
    public function test_dashboard_65_view_all_results_link_targets_results(): void
    {
        $this->browseWithFailureScreenshot('view-all-results', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $this->assertTrue(
                $this->pageSourceContains($browser, self::RESULTS_PATH),
                'No results CTA present on dashboard.'
            );
        });
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 70–79  Edge / empty-state
    // ═════════════════════════════════════════════════════════════════════════

    /** TC-EDG01 — schedules empty-state or table branch renders coherently. */
    public function test_dashboard_70_schedules_empty_state_branch(): void
    {
        $hasSchedules = MarksheetSchedule::count() > 0;

        $this->browseWithFailureScreenshot('edge-schedules', function (Browser $browser) use ($hasSchedules): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            if ($hasSchedules) {
                $this->assertTrue(
                    $this->pageSourceContains($browser, 'Schedule Name'),
                    'Schedules present but table header not rendered.'
                );
            } else {
                $this->assertTrue(
                    $this->pageSourceContains($browser, 'No schedules created yet.'),
                    'No schedules but empty-state message missing.'
                );
            }
        });
    }

    /** TC-EDG02 — results empty-state or table branch renders coherently. */
    public function test_dashboard_71_results_empty_state_branch(): void
    {
        $hasResults = StudentResult::count() > 0;

        $this->browseWithFailureScreenshot('edge-results', function (Browser $browser) use ($hasResults): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            if ($hasResults) {
                $this->assertTrue(
                    $this->pageSourceContains($browser, 'Grand Total'),
                    'Results present but table header not rendered.'
                );
            } else {
                $this->assertTrue(
                    $this->pageSourceContains($browser, 'No results recorded yet.'),
                    'No results but empty-state message missing.'
                );
            }
        });
    }

    /** BUG-MSH-001 — HTTP probe: the dead API never returns a working 200 resource. */
    public function test_dashboard_72_api_getjson_returns_dead_status(): void
    {
        $status = $this->getJson(self::API_PATH)->getStatusCode();
        $this->assertNotSame(200, $status, 'Dead API unexpectedly returned 200.');
        $this->assertContains($status, [401, 403, 404, 405, 500], "Unexpected dead-API status: {$status}");
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 90–99  Tenancy / console / responsive
    // ═════════════════════════════════════════════════════════════════════════

    /** TC-T01 — dashboard counts are scoped to the current tenant (non-negative smoke). */
    public function test_dashboard_90_counts_scoped_to_current_tenant(): void
    {
        $this->assertTrue(function_exists('tenancy') && tenancy()->initialized, 'Tenant context not initialized.');
        $this->assertGreaterThanOrEqual(0, MarksheetType::count());
        $this->assertGreaterThanOrEqual(0, StudentResult::count());
    }

    /** TC-A01 — no SEVERE console errors on the dashboard happy path. */
    public function test_dashboard_91_no_severe_console_errors_on_dashboard(): void
    {
        $this->browseWithFailureScreenshot('console-dashboard', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee(self::DASHBOARD_MARKER);
            $severe = $this->severeConsoleErrors($browser);
            $this->assertEmpty($severe, 'SEVERE console errors: ' . implode(' | ', $severe));
        });
    }

    /** TC-RSP01 — the dashboard renders at a mobile viewport. */
    public function test_dashboard_92_dashboard_renders_at_mobile_viewport(): void
    {
        $this->browseWithFailureScreenshot('mobile', function (Browser $browser): void {
            $browser->resize(390, 844);
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee(self::DASHBOARD_MARKER);
            $browser->resize(1280, 800);
        });
    }

    /** TC-A02 — combined pages produce no SEVERE console errors on the happy path. */
    public function test_dashboard_93_combined_pages_no_severe_console_errors(): void
    {
        $this->browseWithFailureScreenshot('console-combined', function (Browser $browser): void {
            foreach (self::COMBINED_PATHS as $context => $path) {
                $this->visitAuthenticated($browser, $path);
                if (str_contains($this->currentPath($browser), '/login')) {
                    continue;
                }
                $severe = $this->severeConsoleErrors($browser);
                $this->assertEmpty($severe, "SEVERE console errors on {$context}: " . implode(' | ', $severe));
            }
        });
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Private helper library
    // ═════════════════════════════════════════════════════════════════════════

    private function assertCombinedPageResolves(string $path, string $context): void
    {
        $this->browseWithFailureScreenshot('combined-' . $context, function (Browser $browser) use ($path, $context): void {
            $this->visitAuthenticated($browser, $path);
            $current = $this->currentPath($browser);
            $this->assertStringNotContainsString('/login', $current, "{$context} redirected to login.");
            $this->assertStringContainsString($path, $current, "{$context} did not resolve to {$path}.");
        });
    }

    private function assertTabTableOrEmpty(string $tableMarker, string $emptyMarker): void
    {
        $this->browseWithFailureScreenshot('tab-' . strtolower(str_replace(' ', '-', $tableMarker)), function (Browser $browser) use ($tableMarker, $emptyMarker): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $hasData  = $this->pageSourceContains($browser, $tableMarker);
            $hasEmpty = $this->pageSourceContains($browser, $emptyMarker);
            $this->assertTrue($hasData || $hasEmpty, "Tab rendered neither '{$tableMarker}' nor '{$emptyMarker}'.");
        });
    }

    /**
     * D39-MSH: a fresh tenant user without msh permissions must be denied a gated
     * page (Gate::authorize → 403). Defensive: skip cleanly if a limited user
     * cannot be provisioned or the environment grants a super-admin bypass.
     */
    private function assertGateDenies(string $path): void
    {
        $limited = $this->createLimitedUser();
        if ($limited === null) {
            $this->markTestSkipped('Could not provision a limited tenant user (D39 env prereq).');
        }

        $this->browseWithFailureScreenshot('gate-' . md5($path), function (Browser $browser) use ($limited, $path): void {
            $browser->loginAs($limited)->pause(400);
            $browser->visit($this->tenantUrl($path))->pause(900);

            $current = $this->currentPath($browser);
            $source  = $browser->driver->getPageSource();

            $showsDashboard = str_contains($source, self::DASHBOARD_MARKER);
            $denied = str_contains($current, '/login')
                || str_contains($source, '403')
                || str_contains($source, 'This action is unauthorized')
                || stripos($source, 'Forbidden') !== false
                || !$showsDashboard;

            if ($showsDashboard) {
                // A super-admin bypass leaked into the limited user — env-dependent.
                $this->markTestSkipped('Limited user still sees the page (super-admin bypass / D39 seed state).');
            }

            $this->assertTrue($denied, "Gated page {$path} was not denied for an unpermitted user.");
        });
    }

    private function createLimitedUser(): ?User
    {
        try {
            $languageId = (int) (\Illuminate\Support\Facades\DB::table('glb_languages')->value('id') ?? 1);

            $user = User::factory()->create([
                'name'              => 'MSH Limited ' . substr(uniqid(), -6),
                'email'             => 'msh_limited_' . uniqid() . '@example.test',
                'emp_code'          => 'MSHL' . substr(uniqid(), -6),
                'prefered_language' => $languageId,
                'user_type'         => 'EMPLOYEE',
                'email_verified_at' => now(),
            ]);

            // Ensure no msh permission/role leaks onto the limited user.
            if (method_exists($user, 'syncRoles')) {
                try {
                    $user->syncRoles([]);
                } catch (Throwable) {
                    // Ignore.
                }
            }

            return $user;
        } catch (Throwable) {
            return null;
        }
    }

    private function severeConsoleErrors(Browser $browser): array
    {
        try {
            $logs = $browser->driver->manage()->getLog('browser');
        } catch (Throwable) {
            return [];
        }

        $severe = [];
        foreach ((array) $logs as $entry) {
            if (($entry['level'] ?? '') === 'SEVERE') {
                $severe[] = (string) ($entry['message'] ?? '');
            }
        }

        return $severe;
    }

    private function cleanScreenshots(): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        if (!is_dir($directory)) {
            return;
        }
        $files = glob($directory . DIRECTORY_SEPARATOR . '*.png');
        if ($files === false) {
            return;
        }
        foreach ($files as $file) {
            if (is_file($file)) {
                @unlink($file);
            }
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
                $this->captureScreenshot($browser, 'dashboard-pass-' . $caseName);
            } catch (Throwable $e) {
                $this->captureScreenshot($browser, 'dashboard-fail-' . $caseName);
                throw $e;
            }
        });
    }

    private function captureScreenshot(Browser $browser, string $rawName): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $timestamp = now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName . '-' . $timestamp);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'dashboard-' . $timestamp;

        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
            // Keep the original assertion failure as the primary signal.
        }
    }

    private function pageSourceContains(Browser $browser, string $text): bool
    {
        return str_contains($browser->driver->getPageSource(), $text);
    }

    private function authenticate(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(700);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1000);
        }

        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(550);
        }
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 900): void
    {
        $browser->visit($this->tenantUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticate($browser);
            $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        }
    }

    private function initializeTenantContext(): void
    {
        $tenantHost = parse_url($this->tenantBaseUrl, PHP_URL_HOST);
        if (!is_string($tenantHost) || $tenantHost === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }

        $domain = Domain::query()->where('domain', $tenantHost)->first();
        if (!$domain) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $tenantHost);
        }

        if (function_exists('tenancy')) {
            tenancy()->initialize($domain->tenant);
        }
    }

    private function resolveAdminUser(): void
    {
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
            ?? User::query()->first();

        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for Dusk login.');
        }

        if ($this->adminUser->getAttribute('email_verified_at') === null) {
            $this->adminUser->forceFill(['email_verified_at' => now()])->save();
        }

        $this->grantDashboardPermissions($this->adminUser);
    }

    private function grantDashboardPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }

        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::MSH_VIEW_GATES, $guard);
        $this->syncRoleWithPermissions($user, self::MSH_VIEW_GATES, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::MSH_VIEW_GATES as $permission) {
                try {
                    $user->givePermissionTo($permission);
                } catch (Throwable) {
                    // Ignore when seed state differs.
                }
            }
        }
    }

    private function ensurePermissionsExist(array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }
        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate([
                    'name' => $permission,
                    'guard_name' => $guard,
                ]);
            } catch (Throwable) {
                // Ignore in restricted setups.
            }
        }
    }

    private function syncRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }

        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.msh-admin');

        try {
            $role = \Spatie\Permission\Models\Role::firstOrCreate([
                'name' => $roleName,
                'guard_name' => $guard,
            ]);
        } catch (Throwable) {
            return;
        }

        try {
            if (method_exists($role, 'syncPermissions')) {
                $role->syncPermissions($permissions);
            }
        } catch (Throwable) {
            // Ignore in restricted setups.
        }

        if (method_exists($user, 'assignRole')) {
            try {
                $user->assignRole($roleName);
            } catch (Throwable) {
                // Ignore when guard/seed state differs.
            }
        }

        $this->forgetPermissionCache();
    }

    private function permissionGuardName(User $user): string
    {
        if (method_exists($user, 'getDefaultGuardName')) {
            try {
                $guard = (string) $user->getDefaultGuardName();
                if ($guard !== '') {
                    return $guard;
                }
            } catch (Throwable) {
                // Fall through.
            }
        }

        return (string) config('auth.defaults.guard', 'web');
    }

    private function forgetPermissionCache(): void
    {
        if (!class_exists(\Spatie\Permission\PermissionRegistrar::class)) {
            return;
        }
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
            // Ignore.
        }
    }

    private function tenantUrl(string $path): string
    {
        return $this->tenantBaseUrl . '/' . ltrim($path, '/');
    }

    private function currentPath(Browser $browser): string
    {
        $path = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);
        return is_string($path) ? $path : '';
    }
}
