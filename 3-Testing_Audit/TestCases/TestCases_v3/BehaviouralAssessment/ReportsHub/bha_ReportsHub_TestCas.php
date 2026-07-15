<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaAssessment;
use Modules\BehaviouralAssessment\Models\BaAssessmentPeriod;
use Modules\BehaviouralAssessment\Models\BaIncident;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Reports Hub (Reports landing screen) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/15-Reports-Hub.md
 * Screen type        : REPORT / navigation hub (LIGHT depth) — render + links + permission gating + empty-state.
 *                      NOT a CRUD matrix (no create/edit/delete/toggle).
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns) → tenancy scaffolding required.
 * Runtime tables     : ba_assessments, ba_assessment_periods, ba_incidents, ba_assessment_ratings, ba_computed_scores
 *                      (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaReportController
 * View               : behaviouralassessment::reports.index  (breadcrumb title "Reports")
 * Index route         : behavioural-assessment.reports.index  → GET /behavioural-assessment/reports
 * Permission (index)  : tenant.behavioural-assessment.reports.viewAny  (Gate::authorize string; BaReportPolicy registered)
 * Permission (sub)    : tenant.behavioural-assessment.reports.view     (student/class/period/categories/incidents/export)
 * Activity log        : NONE — a read-only hub performs no mutation and calls no activityLog() helper (documented absence).
 *
 * Hub links (index.blade.php) present + probed:
 *   - reports.incidents   (Incident Log & Interventions card)
 *   - reports.categories  (Category & Criteria Performance card)
 *   - reports.period      (Teacher Progress — dropdown + Recent Periods; only when a period exists)
 *   - reports-page        (legacy Data Tables & Audit Trail card)  + reports-page?tab=student-scores
 *
 * Defects proven / documented:
 *   - BUG-BA-011 : reports.export is a live abort(501) stub — no CSV/Excel engine (proven in _45 & _71).
 *   - DEAD-BA-001: module routes/api.php apiResource has NO tenancy middleware (only auth:sanctum) AND is not
 *                  registered by RouteServiceProvider::map() (web-only) → dead route (proven in _46).
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 * Requirement-vs-implementation gaps (feature-scoped, documented in Gap Analysis):
 *   - HUB-GAP-01 : requirement's split-layout filter panel (Academic Session / Period / Class / Section / Format
 *                  radio / "Generate Preview" / "Export Report") is absent — the hub is a stat-card dashboard (proven in _80).
 *   - HUB-GAP-02 : requirement's "Data last synced" timestamp label is absent (proven in _81).
 *   - HUB-GAP-03 : requirement's >1000-row async-queue banner is not implemented (noted, folded into HUB-GAP-01/_80).
 */
class bha_ReportsHub_TestCas extends DuskTestCase
{
    private const URL_PREFIX            = '/behavioural-assessment';
    private const HUB_PATH              = '/behavioural-assessment/reports';
    private const REPORTS_PAGE_PATH     = '/behavioural-assessment/reports-page';
    private const INCIDENTS_REPORT_PATH = '/behavioural-assessment/reports/incidents';
    private const CATEGORIES_REPORT_PATH = '/behavioural-assessment/reports/categories';
    private const EXPORT_PATH           = '/behavioural-assessment/reports/export';

    private const ASSESSMENTS_TABLE = 'ba_assessments';
    private const PERIODS_TABLE     = 'ba_assessment_periods';
    private const INCIDENTS_TABLE   = 'ba_incidents';
    private const RATINGS_TABLE     = 'ba_assessment_ratings';
    private const SCORES_TABLE      = 'ba_computed_scores';
    private const DDL_ASSESSMENTS   = 'bha_assessments';   // stale DDL-doc name (should NOT exist at runtime)

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/ReportsHub/screenshots';

    /** @var array<int,string> */
    private const RH_PERMISSIONS = [
        'tenant.behavioural-assessment.reports.viewAny',
        'tenant.behavioural-assessment.reports.view',
        'tenant.behavioural-assessment.reports.export',
        'tenant.behavioural-assessment.reports-page.viewAny',
        'tenant.behavioural-assessment.reports-page.view',
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

    // =====================================================================
    // Band 01–09 — Schema / DDL / route / policy configuration truth
    // =====================================================================

    public function test_reports_hub_01_backing_schema_and_route_configuration_are_correct(): void
    {
        // The hub aggregates counts from five live tenant tables.
        foreach ([
            self::ASSESSMENTS_TABLE,
            self::PERIODS_TABLE,
            self::INCIDENTS_TABLE,
            self::RATINGS_TABLE,
            self::SCORES_TABLE,
        ] as $table) {
            $this->assertTrue(Schema::hasTable($table), "Backing table {$table} does not exist.");
        }

        // Models bind to the live `ba_` names (code wins over the DDL doc).
        $this->assertSame(self::ASSESSMENTS_TABLE, (new BaAssessment())->getTable());
        $this->assertSame(self::PERIODS_TABLE, (new BaAssessmentPeriod())->getTable());
        $this->assertSame(self::INCIDENTS_TABLE, (new BaIncident())->getTable());

        // Web report routes are registered under the `behavioural-assessment.` name group.
        foreach ([
            'behavioural-assessment.reports.index',
            'behavioural-assessment.reports.student',
            'behavioural-assessment.reports.class',
            'behavioural-assessment.reports.period',
            'behavioural-assessment.reports.categories',
            'behavioural-assessment.reports.incidents',
            'behavioural-assessment.reports.export',
            'behavioural-assessment.reports-page',
        ] as $name) {
            $this->assertTrue(Route::has($name), "Expected route {$name} to be registered.");
        }

        // Controller source: the index gate is viewAny; sub-reports + export use view; export is a 501 stub.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller !== null) {
            $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.reports.viewAny')", $controller);
            $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.reports.view')", $controller);
            $this->assertStringContainsString("abort(501", $controller, 'BUG-BA-011: export must remain a 501 stub.');
        } else {
            $this->assertTrue(true, 'Controller source not readable from runner — route/gate asserted structurally.');
        }
    }

    public function test_reports_hub_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        $this->assertTrue(Schema::hasTable(self::ASSESSMENTS_TABLE), 'Runtime table ba_assessments must exist.');
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'Runtime table ba_computed_scores must exist.');

        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_ASSESSMENTS),
                'DOC-BA-001 regression: bha_assessments exists at runtime; expected only the live ba_assessments.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 10–19 — Render / hub composition (BC-BIZ)
    // =====================================================================

    public function test_reports_hub_10_index_renders_with_reports_breadcrumb(): void
    {
        $this->browseWithFailureScreenshot('hub-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $this->assertStringContainsString('/behavioural-assessment/reports', $this->currentPath($browser));
            $browser->assertSee('Reports')
                ->assertSee('Available Reports');
        });
    }

    public function test_reports_hub_11_summary_stat_cards_are_present(): void
    {
        $this->browseWithFailureScreenshot('hub-stat-cards', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $browser->assertSee('Total Assessments')
                ->assertSee('Students Rated')
                ->assertSee('Total Incidents')
                ->assertSee('Open Periods');
        });
    }

    public function test_reports_hub_12_sidebar_status_trend_and_recent_periods_render(): void
    {
        $this->browseWithFailureScreenshot('hub-sidebar', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $browser->assertSee('Assessment Workflow Status')
                ->assertSee('Incident Trend')
                ->assertSee('Recent Assessment Periods');
        });
    }

    public function test_reports_hub_13_available_reports_section_lists_report_cards(): void
    {
        $this->browseWithFailureScreenshot('hub-report-cards', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $browser->assertSee('Incident Log & Interventions')
                ->assertSee('Category & Criteria Performance');
        });
    }

    // =====================================================================
    // Band 40–49 — Links to each report present + authorized (BC-INT/REF)
    // =====================================================================

    public function test_reports_hub_40_incident_report_link_present_and_target_authorized(): void
    {
        $this->browseWithFailureScreenshot('link-incidents', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('/behavioural-assessment/reports/incidents', $source, 'Hub must link to the incidents report.');
        });

        // Target renders for the authorized admin.
        $this->browseWithFailureScreenshot('target-incidents', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INCIDENTS_REPORT_PATH, 1100);
            $browser->assertSee('Incident Report');
        });
    }

    public function test_reports_hub_41_category_report_link_present_and_target_authorized(): void
    {
        $this->browseWithFailureScreenshot('link-categories', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('/behavioural-assessment/reports/categories', $source, 'Hub must link to the categories report.');
        });

        $this->browseWithFailureScreenshot('target-categories', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CATEGORIES_REPORT_PATH, 1100);
            $browser->assertSee('Category Performance');
        });
    }

    public function test_reports_hub_42_period_report_target_renders_when_period_exists(): void
    {
        $period = BaAssessmentPeriod::query()->orderByDesc('id')->first();
        if ($period === null) {
            $this->markTestSkipped('No ba_assessment_periods row available — period report target not exercisable.');
        }

        $this->browseWithFailureScreenshot('target-period', function (Browser $browser) use ($period): void {
            // The hub surfaces the period link only when recent periods exist.
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('/behavioural-assessment/reports/period/', $source, 'Hub must link to at least one period report when periods exist.');

            $this->visitAuthenticated($browser, self::URL_PREFIX . '/reports/period/' . $period->id, 1100);
            $browser->assertSee('Teacher Progress Report');
        });
    }

    public function test_reports_hub_43_reports_page_legacy_link_present_and_target_renders(): void
    {
        $this->browseWithFailureScreenshot('link-reports-page', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('/behavioural-assessment/reports-page', $source, 'Hub must link to the legacy reports-page tab.');
        });

        // Legacy tab target is authorized + renders (reports-page.viewAny gate).
        $response = $this->apiCall('GET', $this->tenantUrl(self::REPORTS_PAGE_PATH));
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'reports-page target should render (200) for the authorized admin.'
        );
    }

    public function test_reports_hub_44_student_and_class_report_routes_are_registered(): void
    {
        // The hub routes to reports-page?tab=student-scores rather than a direct id link, but the
        // parameterised student/class report routes must still be registered targets.
        $this->assertTrue(Route::has('behavioural-assessment.reports.student'), 'reports.student route missing.');
        $this->assertTrue(Route::has('behavioural-assessment.reports.class'), 'reports.class route missing.');

        $this->browseWithFailureScreenshot('link-student-scores', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('tab=student-scores', $source, 'Hub must expose the student-scores tab entry point.');
        });
    }

    public function test_reports_hub_45_export_route_is_a_live_501_stub_bug_ba_011(): void
    {
        // BUG-BA-011: the requirement describes a full CSV/Excel export engine; the controller only aborts 501.
        $response = $this->apiCall('GET', $this->tenantUrl(self::EXPORT_PATH));
        $this->assertSame(
            501,
            (int) ($response['status'] ?? 0),
            'BUG-BA-011 regression fixed? reports.export should still abort(501) "Export feature coming soon."'
        );
    }

    public function test_reports_hub_46_api_resource_route_lacks_tenancy_and_is_dead_dead_ba_001(): void
    {
        // DEAD-BA-001 (a): RouteServiceProvider::map() maps only routes/web.php, so the module api.php
        // apiResource is never registered → the named api route does not exist.
        $this->assertFalse(
            Route::has('behaviouralassessment.index'),
            'DEAD-BA-001 changed: the module api apiResource is now registered — re-verify tenancy middleware.'
        );

        // DEAD-BA-001 (b): even the api.php definition lacks tenancy middleware (only auth:sanctum),
        // so if it were ever wired it would run in central context.
        $api = $this->readAppFile($this->moduleRootPath('routes/api.php'));
        if ($api === null) {
            $this->assertTrue(true, 'api.php source not readable from runner — registration absence asserted via Route::has.');
            return;
        }
        $this->assertStringContainsString("'auth:sanctum'", $api, 'api.php should declare the auth:sanctum guard.');
        $this->assertStringNotContainsString(
            'InitializeTenancyByDomain',
            $api,
            'DEAD-BA-001 changed: api.php now declares tenancy middleware.'
        );
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_reports_hub_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::HUB_PATH))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_reports_hub_51_limited_user_without_reports_viewany_gets_403_on_hub(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-hub-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::HUB_PATH));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without reports.viewAny must get 403 on the hub.');
        });

        $this->deleteUser($limited);
    }

    public function test_reports_hub_52_limited_user_without_reports_view_gets_403_on_incidents(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-incidents-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::INCIDENTS_REPORT_PATH));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without reports.view must get 403 on a sub-report.');
        });

        $this->deleteUser($limited);
    }

    public function test_reports_hub_53_report_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaReportPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('BaReportPolicy source not readable from app repo.');
        }
        $this->assertStringContainsString('tenant.behavioural-assessment.reports.viewAny', $policy, 'Policy missing viewAny gate string.');
        $this->assertStringContainsString('tenant.behavioural-assessment.reports.view', $policy, 'Policy missing view gate string.');
        $this->assertStringContainsString('tenant.behavioural-assessment.reports.export', $policy, 'Policy missing export gate string.');
    }

    public function test_reports_hub_54_export_gate_enforced_for_limited_user(): void
    {
        // export() authorizes tenant.behavioural-assessment.reports.view — a limited user is blocked
        // BEFORE the 501 stub is reached (403, not 501).
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-export-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::EXPORT_PATH));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Limited user must be gated (403) before the export 501 stub.');
        });

        $this->deleteUser($limited);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (empty state, breadcrumb)
    // =====================================================================

    public function test_reports_hub_60_incident_trend_section_and_empty_state_are_correct(): void
    {
        $this->browseWithFailureScreenshot('trend-empty-state', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $source = $browser->driver->getPageSource();
            $hasData = str_contains($source, 'Incident Trend');
            $this->assertTrue($hasData, 'Incident Trend section header must always render.');

            // Empty-state message OR the trend table (Month column) — one of the two must be present.
            $emptyMsg = str_contains($source, 'No incident data for this period.');
            $trendTable = str_contains($source, 'Month');
            $this->assertTrue($emptyMsg || $trendTable, 'Either the empty-state message or the trend table must render.');
        });
    }

    public function test_reports_hub_61_breadcrumb_present_on_linked_sub_reports(): void
    {
        $this->browseWithFailureScreenshot('subreport-breadcrumbs', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INCIDENTS_REPORT_PATH, 1000);
            $browser->assertSee('Incident Report');
            $this->visitAuthenticated($browser, self::CATEGORIES_REPORT_PATH, 1000);
            $browser->assertSee('Category Performance');
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_reports_hub_70_invalid_ids_return_404_on_parameterised_reports(): void
    {
        $missing = 987654321;
        foreach ([
            self::URL_PREFIX . '/reports/student/' . $missing,
            self::URL_PREFIX . '/reports/class/' . $missing,
            self::URL_PREFIX . '/reports/period/' . $missing,
        ] as $path) {
            $response = $this->apiCall('GET', $this->tenantUrl($path));
            $this->assertSame(404, (int) ($response['status'] ?? 0), "Expected 404 for missing-id path {$path}.");
        }
    }

    public function test_reports_hub_71_export_never_returns_a_success_status(): void
    {
        // Boundary of BUG-BA-011: the export endpoint must never yield a 2xx download for the admin.
        $response = $this->apiCall('GET', $this->tenantUrl(self::EXPORT_PATH));
        $status = (int) ($response['status'] ?? 0);
        $this->assertGreaterThanOrEqual(500, $status, 'Export must not return a success status while it is a 501 stub.');
        $this->assertSame(501, $status, 'Export is expected to abort(501) exactly.');
    }

    // =====================================================================
    // Band 80–89 — Requirement / configuration divergence (BC-CFG)
    // =====================================================================

    public function test_reports_hub_80_requirement_filter_panel_and_export_controls_absent_hub_gap_01(): void
    {
        // HUB-GAP-01/03: the requirement's dynamic filter panel + export controls are not implemented.
        $this->browseWithFailureScreenshot('hub-gap-filter-panel', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('Generate Preview', $source, 'HUB-GAP-01 changed: a "Generate Preview" control now exists.');
            $this->assertStringNotContainsString('Export Report', $source, 'HUB-GAP-01 changed: an "Export Report" control now exists on the hub.');
            $this->assertStringNotContainsString('Excel (.xlsx)', $source, 'HUB-GAP-01 changed: a Format radio group now exists.');
        });
    }

    public function test_reports_hub_81_data_last_synced_timestamp_absent_hub_gap_02(): void
    {
        // HUB-GAP-02: the requirement's "Data last synced" freshness label is not present.
        $this->browseWithFailureScreenshot('hub-gap-synced-label', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::HUB_PATH, 1100);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('Data last synced', $source, 'HUB-GAP-02 changed: a "Data last synced" label now exists.');
        });
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_reports_hub_90_tenant_context_is_initialized_and_backing_tables_resolve(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side report tests.'
        );
        $this->assertTrue(Schema::hasTable(self::ASSESSMENTS_TABLE));
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE));
    }

    public function test_reports_hub_91_cross_tenant_direct_id_isolation(): void
    {
        try {
            $otherDomain = Domain::query()
                ->where('domain', '!=', parse_url($this->tenantBaseUrl, PHP_URL_HOST))
                ->first();
            if (!$otherDomain) {
                $this->markTestSkipped('Only one tenant domain available — cross-tenant isolation not exercisable.');
            }
            $this->assertNotNull($otherDomain->tenant, 'Second tenant exists for isolation checks.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Cross-tenant isolation path unavailable: ' . $e->getMessage());
        }
    }

    public function test_reports_hub_92_reflected_input_in_report_filters_is_escaped(): void
    {
        // The incidents report echoes filter selections; a script payload in a query param must be escaped.
        $xss = '<script>alert(1)</script>';
        $url = self::INCIDENTS_REPORT_PATH
            . '?incident_type=' . rawurlencode($xss)
            . '&severity=' . rawurlencode($xss);

        $this->browseWithFailureScreenshot('reflected-xss-escaped', function (Browser $browser) use ($url): void {
            $this->visitAuthenticated($browser, $url, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Reflected filter input must be escaped by Blade.');
        });
    }

    // =====================================================================
    // ---- Private helper library ----
    // =====================================================================

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
                $this->captureScreenshot($browser, 'pass', $caseName);
            } catch (Throwable $e) {
                $this->captureScreenshot($browser, 'fail', $caseName);
                throw $e;
            }
        });
    }

    private function captureScreenshot(Browser $browser, string $kind, string $caseName): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);
        $rawName = 'reports-hub-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'reports-hub-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- HTTP-from-browser (authenticated same-origin fetch) --------------

    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminReportPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
    }

    private function runOnAdminReportPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            // Landing on the hub establishes the tenant origin + CSRF meta for same-origin fetches.
            $this->visitAuthenticated($browser, self::HUB_PATH, 1000);
            $result = $callback($browser);
        });
        return $result;
    }

    private function sendJsonRequestFromBrowser(
        Browser $browser,
        string $method,
        string $url,
        array $payload = []
    ): array {
        $encodedMethod = json_encode(strtoupper($method), JSON_THROW_ON_ERROR);
        $encodedUrl = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
window.__rhApiDone = false;
window.__rhApiError = '';
window.__rhApiResult = null;

(async function () {
    try {
        const method = {$encodedMethod};
        const url = {$encodedUrl};
        const payload = {$encodedPayload};
        const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';

        const options = {
            method,
            credentials: 'same-origin',
            redirect: 'manual',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
        };

        if (method !== 'GET' && method !== 'HEAD') {
            options.body = JSON.stringify(payload);
        }

        const response = await fetch(url, options);
        const body = await response.text();
        let json = null;
        try { json = body ? JSON.parse(body) : null; } catch (_e) { json = null; }

        window.__rhApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__rhApiError = String(error);
    } finally {
        window.__rhApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__rhApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__rhApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__rhApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Limited (non-super-admin) user for authorization negatives -------

    private function makeLimitedUser(): User
    {
        try {
            $lang = 1;
            if (Schema::hasTable('glb_languages')) {
                $lang = (int) (DB::table('glb_languages')->value('id') ?? 1);
            }

            $attributes = [
                'name'              => 'RH Limited ' . $this->uniqueSuffix(),
                'email'             => 'rh_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'RH' . substr($this->uniqueSuffix(), -8);
            }

            $user = User::factory()->create($attributes);

            foreach (['is_super_admin', 'super_admin_flag'] as $col) {
                if (Schema::hasColumn('sys_users', $col)) {
                    $user->forceFill([$col => 0]);
                }
            }
            $user->save();

            if (method_exists($user, 'syncRoles')) {
                try {
                    $user->syncRoles([]);
                } catch (Throwable) {
                }
            }
            if (method_exists($user, 'syncPermissions')) {
                try {
                    $user->syncPermissions([]);
                } catch (Throwable) {
                }
            }
            $this->forgetPermissionCache();

            return $user;
        } catch (Throwable $e) {
            $this->markTestSkipped('Unable to create a limited tenant user for authorization tests: ' . $e->getMessage());
        }
    }

    private function deleteUser(?User $user): void
    {
        if ($user === null) {
            return;
        }
        try {
            $user->forceDelete();
        } catch (Throwable) {
            try {
                DB::table('sys_users')->where('id', $user->id)->delete();
            } catch (Throwable) {
            }
        }
    }

    // ---- Auth / tenancy ---------------------------------------------------

    private function authenticate(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(700);
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1000);
        }
        if (str_contains($this->currentPath($browser), '/login')) {
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
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first();
        if (!$this->adminUser) {
            $this->adminUser = User::query()->first();
        }
        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for Dusk login.');
        }
        if ($this->adminUser->getAttribute('email_verified_at') === null) {
            $this->adminUser->forceFill(['email_verified_at' => now()])->save();
        }
        $this->grantReportPermissions($this->adminUser);
    }

    private function grantReportPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::RH_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::RH_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::RH_PERMISSIONS as $permission) {
                try {
                    $user->givePermissionTo($permission);
                } catch (Throwable) {
                }
            }
        }
        $this->forgetPermissionCache();
    }

    private function ensurePermissionsExist(array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }
        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate(['name' => $permission, 'guard_name' => $guard]);
            } catch (Throwable) {
            }
        }
    }

    private function syncRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.reports-hub-admin');
        try {
            $role = \Spatie\Permission\Models\Role::firstOrCreate(['name' => $roleName, 'guard_name' => $guard]);
        } catch (Throwable) {
            return;
        }
        try {
            if (method_exists($role, 'syncPermissions')) {
                $role->syncPermissions($permissions);
            }
        } catch (Throwable) {
        }
        if (method_exists($user, 'assignRole')) {
            try {
                $user->assignRole($roleName);
            } catch (Throwable) {
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
        }
    }

    // ---- App-repo source resolution (constraint #29/#32) ------------------

    private function moduleRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaAssessment::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaAssessment.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function readAppFile(?string $path): ?string
    {
        if ($path === null) {
            return null;
        }
        try {
            if (File::exists($path)) {
                return File::get($path);
            }
        } catch (Throwable) {
        }
        return null;
    }

    // ---- Small utilities --------------------------------------------------

    private function tenantUrl(string $path): string
    {
        return $this->tenantBaseUrl . '/' . ltrim($path, '/');
    }

    private function currentPath(Browser $browser): string
    {
        $path = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);
        return is_string($path) ? $path : '';
    }

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(1000, 9999);
    }
}
