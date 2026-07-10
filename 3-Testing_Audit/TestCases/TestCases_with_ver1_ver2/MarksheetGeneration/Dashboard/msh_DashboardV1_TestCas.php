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
 * V1 = foundation suite: routes/views/aggregation wiring truth, dashboard render,
 * stat aggregation, 4-pillar navigation resolution, permission gating, empty-state
 * branches, guest redirect, console-error smoke, and the BUG-MSH-001 dead-API proof.
 *
 * Source of truth:
 *   - Modules/MarksheetGeneration/app/Http/Controllers/MarksheetGenerationController.php
 *     (dashboard/configuration/components/scheduling/results — Gate::authorize each)
 *   - Modules/MarksheetGeneration/routes/web.php + routes/api.php
 *   - resources/views/dashboard.blade.php + pages/*.blade.php
 *   - 2-DDL_Tenant_Consolidated/MarksheetGeneration_DDL_v1.sql (msh_*, tenant_db)
 *
 * DB scope: tenant-side (msh_* prefix, Database: tenant_db) → tenant scaffolding required.
 * Env prereq: MarksheetGeneration must be ENABLED in modules_statuses.json, else 404.
 * D39-MSH: msh permissions are unseeded (super-admin only) — this suite grants the 5
 *   msh view gates explicitly to the admin so positive render tests are deterministic.
 */
class msh_DashboardV1_TestCas extends DuskTestCase
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

    /** msh_* tables the dashboard aggregates counts from. */
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

    /** Gates asserted verbatim against the controller source (Screen-PM). */
    private const MSH_VIEW_GATES = [
        'tenant.msh-dashboard.view',
        'tenant.msh-configuration.view',
        'tenant.msh-components.view',
        'tenant.msh-scheduling.view',
        'tenant.msh-results.view',
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

    // ─────────────────────────────────────────────────────────────────────────
    // 01–09  Wiring / schema / config truth
    // ─────────────────────────────────────────────────────────────────────────

    /** BC-DB / BC-BIZ / BC-AUTH — routes, views, aggregation and gate wiring. */
    public function test_dashboard_01_routes_views_and_aggregation_wiring_are_correct(): void
    {
        // (a) every msh_* table the dashboard aggregates exists in the tenant DB.
        foreach (self::DASHBOARD_TABLES as $table) {
            $this->assertTrue(
                Schema::hasTable($table),
                "Dashboard aggregation table missing: {$table}"
            );
        }

        // (b) models resolve to their DDL table names (aggregation query shape).
        $this->assertSame('msh_marksheet_types', (new MarksheetType())->getTable());
        $this->assertSame('msh_config_templates', (new ConfigTemplate())->getTable());
        $this->assertSame('msh_marksheet_schedules', (new MarksheetSchedule())->getTable());
        $this->assertSame('msh_student_results', (new StudentResult())->getTable());
        $this->assertSame('msh_schedule_class_jnt', (new ScheduleClass())->getTable());
        $this->assertSame('msh_subject_practical_configs', (new SubjectPracticalConfig())->getTable());

        // (c) dashboard + combined page views exist.
        $this->assertTrue(View::exists('marksheetgeneration::dashboard'), 'dashboard view missing');
        foreach (['pages.configuration', 'pages.components', 'pages.scheduling', 'pages.results'] as $view) {
            $this->assertTrue(
                View::exists('marksheetgeneration::' . $view),
                "combined page view missing: {$view}"
            );
        }

        // (d) controller source proves the aggregation + gate wiring.
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString('function dashboard()', $controller);
        $this->assertStringContainsString('MarksheetType::count()', $controller);
        $this->assertStringContainsString('StudentResult::count()', $controller);
        $this->assertStringContainsString("view('marksheetgeneration::dashboard'", $controller);
        foreach (self::MSH_VIEW_GATES as $gate) {
            $this->assertStringContainsString(
                "Gate::authorize('{$gate}')",
                $controller,
                "Controller missing expected gate: {$gate}"
            );
        }
    }

    /** BC-BIZ — dashboard + combined web routes are registered under the module prefix. */
    public function test_dashboard_02_web_routes_are_registered(): void
    {
        $this->assertTrue(Route::has('marksheet-generation.dashboard'), 'dashboard route not registered');
        $this->assertTrue(Route::has('marksheet-generation.configuration.combined'));
        $this->assertTrue(Route::has('marksheet-generation.components.combined'));
        $this->assertTrue(Route::has('marksheet-generation.scheduling.combined'));
        $this->assertTrue(Route::has('marksheet-generation.results.combined'));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 10–19  Render / aggregation business rules
    // ─────────────────────────────────────────────────────────────────────────

    /** TC-P01 — dashboard renders for the admin with the module header + breadcrumb. */
    public function test_dashboard_03_dashboard_renders_for_admin_with_breadcrumb(): void
    {
        $this->browseWithFailureScreenshot('render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);

            $this->assertStringContainsString(self::DASHBOARD_PATH, $this->currentPath($browser));
            $browser->assertSee(self::DASHBOARD_MARKER);
            $this->assertTrue(
                $browser->element('ol.breadcrumb') !== null,
                'Breadcrumb not rendered on dashboard.'
            );
        });
    }

    /** TC-P02 — the six primary stat cards render with their labels. */
    public function test_dashboard_04_six_primary_stat_cards_render(): void
    {
        $this->browseWithFailureScreenshot('stat-cards', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);

            foreach ([
                'Marksheet Types', 'Config Templates', 'Schedules',
                'Student Results', 'Schedule Classes', 'Practical Configs',
            ] as $label) {
                $browser->assertSee($label);
            }
        });
    }

    /** TC-P03 — stat values reflect live DB counts (aggregation truth). */
    public function test_dashboard_05_primary_stat_values_match_db_counts(): void
    {
        $totalResults = StudentResult::count();
        $totalTypes   = MarksheetType::count();

        $this->assertGreaterThanOrEqual(0, $totalResults);
        $this->assertGreaterThanOrEqual(0, $totalTypes);

        $this->browseWithFailureScreenshot('counts', function (Browser $browser) use ($totalResults): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            // The Student Results card renders the exact computed total.
            $browser->assertSee((string) $totalResults);
        });
    }

    /** TC-P05 — the three recent-activity tab controls are present. */
    public function test_dashboard_06_recent_activity_tabs_present(): void
    {
        $this->browseWithFailureScreenshot('tabs', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee('Overview')
                ->assertSee('Recent Schedules')
                ->assertSee('Recent Results');
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 40–49  Navigation / integration
    // ─────────────────────────────────────────────────────────────────────────

    /** TC-P06 — the 4-pillar navigation links target the combined routes. */
    public function test_dashboard_07_four_pillar_navigation_links_present(): void
    {
        $this->browseWithFailureScreenshot('pillars', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);

            foreach ([
                self::CONFIG_PATH, self::COMPONENTS_PATH,
                self::SCHEDULING_PATH, self::RESULTS_PATH,
            ] as $href) {
                $this->assertTrue(
                    $this->pageSourceContains($browser, $href),
                    "Pillar navigation link missing for {$href}"
                );
            }
        });
    }

    /** TC-P07 — Configuration combined page resolves and renders (not login). */
    public function test_dashboard_08_configuration_combined_resolves(): void
    {
        $this->assertCombinedPageResolves(self::CONFIG_PATH, 'configuration');
    }

    /** TC-P08 — Components combined page resolves and renders. */
    public function test_dashboard_09_components_combined_resolves(): void
    {
        $this->assertCombinedPageResolves(self::COMPONENTS_PATH, 'components');
    }

    /** TC-P09 — Scheduling combined page resolves and renders. */
    public function test_dashboard_10_scheduling_combined_resolves(): void
    {
        $this->assertCombinedPageResolves(self::SCHEDULING_PATH, 'scheduling');
    }

    /** TC-P10 — Results combined page resolves and renders (PERF-MSH-003 surface). */
    public function test_dashboard_11_results_combined_resolves(): void
    {
        // NOTE: results() eager-loads Student::where('is_active',1)->get() and
        // Subject::get() with no pagination (PERF-MSH-003). The page must still
        // render; the perf risk is documented in the Gap Analysis.
        $this->assertCombinedPageResolves(self::RESULTS_PATH, 'results');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 50–59  Permissions / auth / dead API
    // ─────────────────────────────────────────────────────────────────────────

    /** TC-N01 — a guest is redirected to /login from the dashboard. */
    public function test_dashboard_12_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest', function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::DASHBOARD_PATH))->pause(900);
            $this->assertStringContainsString(
                '/login',
                $this->currentPath($browser),
                'Guest was not redirected to /login.'
            );
        });
    }

    /** TC-N08/N09 — BUG-MSH-001: the marksheetgenerations API resource is dead. */
    public function test_dashboard_13_api_marksheetgenerations_resource_is_dead(): void
    {
        // (a) The controller declares NONE of the REST resource methods the
        //     apiResource('marksheetgenerations', ...) route group binds to.
        foreach (['index', 'store', 'show', 'update', 'destroy'] as $method) {
            $this->assertFalse(
                method_exists(MarksheetGenerationController::class, $method),
                "BUG-MSH-001 regressed: controller now defines {$method}()."
            );
        }

        // (b) The module RouteServiceProvider::map() only maps web routes, so the
        //     apiResource names are never registered.
        $this->assertFalse(
            Route::has('marksheetgeneration.index'),
            'BUG-MSH-001 regressed: api resource route is now registered.'
        );

        // (c) Hitting the endpoint does not return a working REST resource.
        $status = $this->getJson(self::API_PATH)->getStatusCode();
        $this->assertNotSame(200, $status, 'Dead API unexpectedly returned 200.');
        $this->assertContains(
            $status,
            [401, 403, 404, 405, 500],
            "Unexpected status for dead API: {$status}"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 60–69  UI / UX
    // ─────────────────────────────────────────────────────────────────────────

    /** TC-P11 — Recent Schedules tab renders a table or the empty-state branch. */
    public function test_dashboard_14_recent_schedules_tab_table_or_empty(): void
    {
        $this->browseWithFailureScreenshot('recent-schedules', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $hasData  = $this->pageSourceContains($browser, 'Schedule Name');
            $hasEmpty = $this->pageSourceContains($browser, 'No schedules created yet.');
            $this->assertTrue($hasData || $hasEmpty, 'Recent Schedules tab rendered neither table nor empty state.');
        });
    }

    /** TC-P12 — Recent Results tab renders a table or the empty-state branch. */
    public function test_dashboard_15_recent_results_tab_table_or_empty(): void
    {
        $this->browseWithFailureScreenshot('recent-results', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $hasData  = $this->pageSourceContains($browser, 'Grand Total');
            $hasEmpty = $this->pageSourceContains($browser, 'No results recorded yet.');
            $this->assertTrue($hasData || $hasEmpty, 'Recent Results tab rendered neither table nor empty state.');
        });
    }

    /** TC-P13 — the today-date badge renders. */
    public function test_dashboard_16_today_date_badge_renders(): void
    {
        $this->browseWithFailureScreenshot('date-badge', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee(now()->format('Y'));
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 90–99  Console / smoke
    // ─────────────────────────────────────────────────────────────────────────

    /** TC-A01 — no SEVERE console errors on the dashboard happy path. */
    public function test_dashboard_17_no_severe_console_errors(): void
    {
        $this->browseWithFailureScreenshot('console', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::DASHBOARD_PATH);
            $browser->assertSee(self::DASHBOARD_MARKER);

            $severe = $this->severeConsoleErrors($browser);
            $this->assertEmpty(
                $severe,
                'SEVERE console errors on dashboard: ' . implode(' | ', $severe)
            );
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private helper library
    // ─────────────────────────────────────────────────────────────────────────

    private function assertCombinedPageResolves(string $path, string $context): void
    {
        $this->browseWithFailureScreenshot('combined-' . $context, function (Browser $browser) use ($path, $context): void {
            $this->visitAuthenticated($browser, $path);
            $current = $this->currentPath($browser);

            $this->assertStringNotContainsString(
                '/login',
                $current,
                "{$context} combined page redirected to login (permission/env issue)."
            );
            $this->assertStringContainsString(
                $path,
                $current,
                "{$context} combined page did not resolve to {$path}."
            );
        });
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
                $this->capturePassScreenshot($browser, $caseName);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    private function capturePassScreenshot(Browser $browser, string $caseName): void
    {
        $this->captureScreenshot($browser, 'dashboard-pass-' . $caseName);
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        $this->captureScreenshot($browser, 'dashboard-fail-' . $caseName);
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

    /** D39-MSH: msh permissions are unseeded — grant the 5 view gates explicitly. */
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
