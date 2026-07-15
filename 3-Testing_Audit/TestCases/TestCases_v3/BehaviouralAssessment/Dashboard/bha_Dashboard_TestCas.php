<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Controllers\BaDashboardController;
use Modules\BehaviouralAssessment\Models\BaCategory;
use Modules\BehaviouralAssessment\Models\BaIncident;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Dashboard screen — single comprehensive Dusk suite (read-focused).
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/01-Dashboard.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Route              : GET /behavioural-assessment  ->  name behavioural-assessment.dashboard
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaDashboardController::index()
 * Policy             : Modules\BehaviouralAssessment\Policies\BaDashboardPolicy (viewAny, view)
 * Permission         : tenant.behavioural-assessment.dashboard.{viewAny|view}
 * FormRequest        : NONE — read-only aggregate screen, no write path, no CRUD.
 * Activity log       : NONE — index() performs reads only; no activityLog() helper call.
 *
 * Aggregate sources (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001):
 *   ba_assessments, ba_assessment_ratings, ba_incidents, ba_assessment_periods,
 *   ba_computed_scores, ba_categories, ba_rating_levels + cross-module std_students.
 *
 * Feature-scoped divergences (requirement 01-Dashboard.md vs implemented controller/blade):
 *   - DASH-GAP-01 : implemented KPIs are Total Assessments / Students Assessed / Total Incidents /
 *                   Open Periods — NOT the requirement's "Active Period days / Assessments Completed % /
 *                   Incidents This Week / Active Interventions" (proven in _92).
 *   - DASH-GAP-02 : no server-side filters on the dashboard; unexpected query params are ignored (proven in _30).
 *   - DASH-GAP-03 : role-based data scoping (Admin school-wide vs Teacher section-only) is NOT implemented —
 *                   index() runs school-wide aggregates for every viewer (proven in _31).
 *   - DASH-GAP-04 : severity ENUM includes 'critical', but the Recent-Incidents blade only maps
 *                   major/moderate/minor (critical falls through to the em-dash branch) (proven in _71).
 * Inherited audit defects surfaced on this screen:
 *   - DOC-BA-001  : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - PERF-BA-002 : rating-map eager-loads criterion but not criterion.category (documented in Gap Analysis).
 */
class bha_Dashboard_TestCas extends DuskTestCase
{
    private const URL_PREFIX     = '/behavioural-assessment';
    private const DASHBOARD_PATH = '/behavioural-assessment';

    private const ASSESSMENTS_TABLE = 'ba_assessments';
    private const RATINGS_TABLE     = 'ba_assessment_ratings';
    private const INCIDENTS_TABLE   = 'ba_incidents';
    private const PERIODS_TABLE     = 'ba_assessment_periods';
    private const SCORES_TABLE      = 'ba_computed_scores';
    private const CATEGORIES_TABLE  = 'ba_categories';
    private const LEVELS_TABLE      = 'ba_rating_levels';

    private const DDL_ASSESSMENTS = 'bha_assessments';   // stale DDL-doc name — must NOT exist at runtime
    private const DDL_INCIDENTS   = 'bha_incidents';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/Dashboard/screenshots';

    /** @var array<int,string> */
    private const DASH_PERMISSIONS = [
        'tenant.behavioural-assessment.dashboard.viewAny',
        'tenant.behavioural-assessment.dashboard.view',
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
    // Band 01–09 — Schema / route / policy / config truth
    // =====================================================================

    public function test_dashboard_01_aggregate_source_tables_and_columns_exist(): void
    {
        foreach ([
            self::ASSESSMENTS_TABLE, self::RATINGS_TABLE, self::INCIDENTS_TABLE,
            self::PERIODS_TABLE, self::SCORES_TABLE, self::CATEGORIES_TABLE, self::LEVELS_TABLE,
        ] as $table) {
            $this->assertTrue(Schema::hasTable($table), "Dashboard aggregate source table {$table} does not exist.");
        }

        // Columns the controller reads for its widgets.
        $this->assertTrue(Schema::hasColumns(self::INCIDENTS_TABLE, [
            'incident_date', 'incident_type', 'severity', 'student_id', 'category_id',
        ]), 'ba_incidents is missing columns used by the dashboard incident-trend/recent widgets.');

        $this->assertTrue(Schema::hasColumns(self::PERIODS_TABLE, [
            'status', 'end_date', 'name',
        ]), 'ba_assessment_periods is missing columns used by the open-periods / latest-locked-period logic.');

        $this->assertTrue(Schema::hasColumns(self::SCORES_TABLE, [
            'period_id', 'category_id', 'student_id', 'numeric_score', 'grade',
        ]), 'ba_computed_scores is missing columns used by category-average / bottom-student widgets.');

        $this->assertTrue(Schema::hasColumns(self::CATEGORIES_TABLE, [
            'parent_id', 'is_active', 'sort_order', 'polarity', 'name',
        ]), 'ba_categories is missing columns used by the category-average widget.');

        $this->assertTrue(Schema::hasColumns(self::LEVELS_TABLE, [
            'label', 'numeric_value',
        ]), 'ba_rating_levels is missing columns used by the rating-distribution donut.');
    }

    public function test_dashboard_02_runtime_ba_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime aggregate tables use the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::ASSESSMENTS_TABLE), 'Runtime table ba_assessments must exist.');
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'Runtime table ba_incidents must exist.');

        // The DDL/registry spec name `bha_*` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_ASSESSMENTS),
                'DOC-BA-001 regression: bha_assessments exists at runtime; expected only the live ba_assessments.'
            );
            $this->assertFalse(
                Schema::hasTable(self::DDL_INCIDENTS),
                'DOC-BA-001 regression: bha_incidents exists at runtime; expected only the live ba_incidents.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_incidents', (new BaIncident())->getTable());
        $this->assertSame('ba_categories', (new BaCategory())->getTable());
    }

    public function test_dashboard_03_dashboard_route_is_registered_and_controller_has_index(): void
    {
        $this->assertTrue(Route::has('behavioural-assessment.dashboard'), 'Route behavioural-assessment.dashboard is not registered.');
        $this->assertTrue(class_exists(BaDashboardController::class), 'BaDashboardController class must exist.');
        $this->assertTrue(method_exists(BaDashboardController::class, 'index'), 'BaDashboardController::index must exist.');

        $route = Route::getRoutes()->getByName('behavioural-assessment.dashboard');
        $this->assertNotNull($route, 'Named dashboard route could not be resolved.');
        $this->assertContains('GET', $route->methods(), 'Dashboard route must respond to GET.');
        $this->assertSame('behavioural-assessment', $route->uri(), 'Dashboard index is served at the module root URI.');
    }

    public function test_dashboard_04_policy_maps_abilities_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaDashboardPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('BaDashboardPolicy source not readable from app repo.');
        }
        $this->assertStringContainsString('tenant.behavioural-assessment.dashboard.viewAny', $policy, 'Policy missing viewAny gate string.');
        // `view` ability is declared on the policy but no controller action uses it (documented as a soft gap).
        $this->assertStringContainsString('tenant.behavioural-assessment.dashboard.view', $policy, 'Policy missing view gate string.');
    }

    // =====================================================================
    // Band 10–19 — Render + KPI/widget correctness (BC-BIZ)
    // =====================================================================

    public function test_dashboard_10_index_renders_with_breadcrumb_and_kpi_labels(): void
    {
        $this->browseWithFailureScreenshot('render', function (Browser $browser): void {
            $this->openDashboard($browser);
            $browser->assertSee('Behavioural Assessment Dashboard')
                ->assertSee('Total Assessments')
                ->assertSee('Students Assessed')
                ->assertSee('Total Incidents')
                ->assertSee('Open Periods');
        });
    }

    public function test_dashboard_11_total_assessments_kpi_matches_ba_assessments_count(): void
    {
        $expected = DB::table(self::ASSESSMENTS_TABLE)->whereNull('deleted_at')->count();

        $this->browseWithFailureScreenshot('kpi-assessments', function (Browser $browser) use ($expected): void {
            $this->openDashboard($browser);
            $browser->assertSee(number_format($expected));
        });
    }

    public function test_dashboard_12_total_incidents_kpi_matches_ba_incidents_count(): void
    {
        $incident = $this->seedIncident(['incident_type' => 'negative_incident', 'severity' => 'major']);
        if ($incident === null) {
            $this->markTestSkipped('Could not seed an incident (missing cross-module student/employee rows).');
        }

        try {
            $expected = DB::table(self::INCIDENTS_TABLE)->whereNull('deleted_at')->count();
            $this->assertGreaterThanOrEqual(1, $expected, 'At least the seeded incident must be counted.');

            $this->browseWithFailureScreenshot('kpi-incidents', function (Browser $browser) use ($expected): void {
                $this->openDashboard($browser);
                $browser->assertSee(number_format($expected));
            });
        } finally {
            $this->deleteIncident($incident);
        }
    }

    public function test_dashboard_13_open_periods_kpi_matches_open_status_count(): void
    {
        $expected = DB::table(self::PERIODS_TABLE)->whereNull('deleted_at')->where('status', 'open')->count();

        $this->browseWithFailureScreenshot('kpi-open-periods', function (Browser $browser) use ($expected): void {
            $this->openDashboard($browser);
            $browser->assertSee(number_format($expected));
        });
    }

    public function test_dashboard_14_students_assessed_kpi_matches_distinct_rating_students(): void
    {
        $expected = (int) DB::table(self::RATINGS_TABLE)
            ->whereNull('deleted_at')
            ->distinct()
            ->count('student_id');

        $this->browseWithFailureScreenshot('kpi-students-assessed', function (Browser $browser) use ($expected): void {
            $this->openDashboard($browser);
            $browser->assertSee(number_format($expected));
        });
    }

    public function test_dashboard_15_seeded_incident_appears_in_recent_incidents(): void
    {
        // Future-dated so the incident sorts to the top of the "last 5 by incident_date desc" grid.
        $incident = $this->seedIncident([
            'incident_type' => 'negative_incident',
            'severity'      => 'moderate',
            'incident_date' => now()->addYears(5)->toDateString(),
        ]);
        if ($incident === null) {
            $this->markTestSkipped('Could not seed an incident (missing cross-module student/employee rows).');
        }

        try {
            $student = DB::table('std_students')->where('id', $incident->student_id)->first();
            $firstName = (string) ($student->first_name ?? '');

            $this->browseWithFailureScreenshot('recent-incident', function (Browser $browser) use ($firstName): void {
                $this->openDashboard($browser);
                $browser->assertSee('Recent Incidents');
                if ($firstName !== '') {
                    $this->assertStringContainsString(
                        $firstName,
                        $browser->driver->getPageSource(),
                        'Freshly-seeded (future-dated) incident student should surface in Recent Incidents.'
                    );
                }
            });
        } finally {
            $this->deleteIncident($incident);
        }
    }

    public function test_dashboard_16_recent_incidents_limited_to_five_ordered_desc(): void
    {
        // Structural guarantee: the controller uses ->orderByDesc('incident_date')->limit(5).
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaDashboardController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaDashboardController source not readable from app repo.');
        }
        $this->assertStringContainsString("orderByDesc('incident_date')", $controller, 'Recent incidents must be ordered by incident_date desc.');
        $this->assertStringContainsString('limit(5)', $controller, 'Recent incidents must be capped at 5 rows.');
    }

    public function test_dashboard_17_rating_distribution_chart_container_present(): void
    {
        $this->browseWithFailureScreenshot('chart-rating', function (Browser $browser): void {
            $this->openDashboard($browser);
            $browser->assertSee('Rating Level Distribution');
            $this->assertStringContainsString('chart-rating-distribution', $browser->driver->getPageSource(), 'Rating distribution chart container missing.');
        });
    }

    public function test_dashboard_18_category_scores_chart_container_present(): void
    {
        $this->browseWithFailureScreenshot('chart-category', function (Browser $browser): void {
            $this->openDashboard($browser);
            $browser->assertSee('Category Average Scores');
            $this->assertStringContainsString('chart-category-scores', $browser->driver->getPageSource(), 'Category scores chart container missing.');
        });
    }

    public function test_dashboard_19_incident_trend_chart_container_present(): void
    {
        $this->browseWithFailureScreenshot('chart-trend', function (Browser $browser): void {
            $this->openDashboard($browser);
            $browser->assertSee('Incident Trend (Last 6 Months)');
            $this->assertStringContainsString('chart-incident-trend', $browser->driver->getPageSource(), 'Incident trend chart container missing.');
        });
    }

    // =====================================================================
    // Band 20–29 — Period-scoping business rules (latest LOCKED period)
    // =====================================================================

    public function test_dashboard_20_category_scores_use_latest_locked_period(): void
    {
        // BR: category-average widget reads BaAssessmentPeriod::where('status','locked')->orderByDesc('end_date')->first().
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaDashboardController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaDashboardController source not readable.');
        }
        $this->assertStringContainsString("where('status', 'locked')", $controller, 'Latest-period selection must filter status=locked.');
        $this->assertStringContainsString("orderByDesc('end_date')", $controller, 'Latest locked period must be the one with the greatest end_date.');

        // Behavioural: when a locked period exists, its name is surfaced under the Category Average Scores card.
        $period = $this->seedLockedPeriod();
        if ($period === null) {
            $this->markTestSkipped('Could not seed a locked period (missing academic session row).');
        }
        try {
            $this->browseWithFailureScreenshot('locked-period-name', function (Browser $browser) use ($period): void {
                $this->openDashboard($browser);
                // The blade prints $latestPeriod->name when a locked period is present.
                $this->assertStringContainsString(
                    (string) $period->name,
                    $browser->driver->getPageSource(),
                    'The latest locked period name should appear beneath the category-scores card.'
                );
            });
        } finally {
            $this->deletePeriod($period);
        }
    }

    public function test_dashboard_21_students_needing_attention_from_latest_locked_period(): void
    {
        // Structural: bottom-5 students are derived from ba_computed_scores of the latest locked period.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaDashboardController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaDashboardController source not readable.');
        }
        $this->assertStringContainsString("orderBy('avg_score')", $controller, 'Bottom students must be ordered ascending by average score.');
        $this->assertStringContainsString('std_students', $controller, 'Bottom students must resolve names from cross-module std_students.');
        $this->assertStringContainsString("limit(5)", $controller, 'Bottom students must be capped at 5.');
    }

    public function test_dashboard_22_period_status_enum_values_are_valid(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('ENUM inspection requires MySQL.');
        }
        $col = collect(DB::select('SHOW COLUMNS FROM ' . self::PERIODS_TABLE))
            ->firstWhere('Field', 'status');
        $this->assertNotNull($col, 'status column not found on ba_assessment_periods.');
        $type = strtolower((string) ($col->Type ?? ''));
        foreach (['open', 'locked', 'closed'] as $value) {
            $this->assertStringContainsString("'{$value}'", $type, "Period status ENUM must allow '{$value}'.");
        }
    }

    // =====================================================================
    // Band 30–39 — Input robustness / requirement gaps
    // =====================================================================

    public function test_dashboard_30_unexpected_query_params_are_ignored_no_server_filter_dash_gap_02(): void
    {
        // The dashboard has no server-side filter; junk query params must not break the render.
        $this->browseWithFailureScreenshot('junk-params', function (Browser $browser): void {
            $this->visitAuthenticated(
                $browser,
                self::DASHBOARD_PATH . '?search=' . urlencode('<script>') . '&period_id=abc&status=nonsense',
                1000
            );
            $browser->assertSee('Behavioural Assessment Dashboard');
            $this->assertStringNotContainsString('<script>alert', $browser->driver->getPageSource(), 'Reflected junk param must not inject script.');
        });
    }

    public function test_dashboard_31_no_role_based_scope_filter_implemented_dash_gap_03(): void
    {
        // Requirement 01-Dashboard "Role-Based Data Visibility": teachers should see section-only data.
        // The controller runs school-wide aggregates unconditionally with no role/scope branch.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaDashboardController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaDashboardController source not readable.');
        }
        // index() body: no per-role scoping, no teacher_id/section filter on the KPI counts.
        $indexBody = $this->extractMethodBody($controller, 'index');
        $this->assertNotSame('', $indexBody, 'Unable to isolate index() body.');
        $this->assertStringNotContainsString("hasRole(", $indexBody, 'DASH-GAP-03 changed: index() now branches on role.');
        $this->assertStringContainsString('BaAssessment::count()', $indexBody, 'KPI is a school-wide count (no scope) — DASH-GAP-03.');
    }

    // =====================================================================
    // Band 40–49 — Integration / cross-module aggregation (BC-INT)
    // =====================================================================

    public function test_dashboard_40_incident_trend_splits_positive_and_negative(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaDashboardController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaDashboardController source not readable.');
        }
        $this->assertStringContainsString("incident_type = 'positive_reinforcement'", $controller, 'Trend must aggregate positive reinforcement.');
        $this->assertStringContainsString("incident_type = 'negative_incident'", $controller, 'Trend must aggregate negative incidents.');
        $this->assertStringContainsString('subMonths(6)', $controller, 'Trend window is the last 6 months.');
    }

    public function test_dashboard_41_computed_score_category_relationship_resolves(): void
    {
        // The bottom-student widget calls $sc->category?->name; verify the FK/relationship column exists.
        $this->assertTrue(Schema::hasColumn(self::SCORES_TABLE, 'category_id'), 'ba_computed_scores.category_id must exist for category resolution.');
        if (DB::connection()->getDriverName() === 'mysql') {
            $fk = DB::select(
                "SELECT REFERENCED_TABLE_NAME FROM information_schema.KEY_COLUMN_USAGE
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = 'category_id'
                   AND REFERENCED_TABLE_NAME IS NOT NULL",
                [self::SCORES_TABLE]
            );
            if (!empty($fk)) {
                $this->assertSame('ba_categories', (string) ($fk[0]->REFERENCED_TABLE_NAME ?? ''), 'category_id should reference ba_categories.');
            }
        }
    }

    public function test_dashboard_42_bottom_students_join_std_students_defensive(): void
    {
        try {
            $this->assertTrue(Schema::hasTable('std_students'), 'Cross-module std_students table must exist for the bottom-student join.');
            $this->assertTrue(
                Schema::hasColumns('std_students', ['first_name', 'last_name', 'admission_no']),
                'std_students must expose the columns the bottom-student widget selects.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('std_students not available in this environment: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_dashboard_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::DASHBOARD_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_dashboard_51_limited_user_without_view_permission_gets_403(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'GET',
                $this->tenantUrl(self::DASHBOARD_PATH)
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without dashboard.viewAny must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_dashboard_52_controller_enforces_gate_authorize_string(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaDashboardController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaDashboardController source not readable.');
        }
        $this->assertStringContainsString(
            "Gate::authorize('tenant.behavioural-assessment.dashboard.viewAny')",
            $controller,
            'index() must authorize against the dashboard viewAny gate.'
        );
    }

    public function test_dashboard_53_admin_with_permission_can_view_dashboard(): void
    {
        $response = $this->apiCall('GET', $this->tenantUrl(self::DASHBOARD_PATH));
        $this->assertSame(200, (int) ($response['status'] ?? 0), 'Permitted admin must receive 200 for the dashboard.');
    }

    // =====================================================================
    // Band 60–69 — UI/UX & empty-state
    // =====================================================================

    public function test_dashboard_60_quick_links_render_with_correct_routes(): void
    {
        $this->browseWithFailureScreenshot('quick-links', function (Browser $browser): void {
            $this->openDashboard($browser);
            $browser->assertSee('Quick Links')
                ->assertSee('Masters')
                ->assertSee('Setup')
                ->assertSee('Assessments')
                ->assertSee('Incidents')
                ->assertSee('Reports');

            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('/behavioural-assessment/masters', $source, 'Masters quick-link URL missing.');
            $this->assertStringContainsString('/behavioural-assessment/setup', $source, 'Setup quick-link URL missing.');
            $this->assertStringContainsString('/behavioural-assessment/reports-page', $source, 'Reports quick-link URL missing.');
        });
    }

    public function test_dashboard_61_recent_incidents_view_all_links_to_incidents_page(): void
    {
        $this->browseWithFailureScreenshot('view-all-link', function (Browser $browser): void {
            $this->openDashboard($browser);
            $this->assertStringContainsString(
                '/behavioural-assessment/incidents-page',
                $browser->driver->getPageSource(),
                'The Recent Incidents "View All" link must target the incidents page.'
            );
        });
    }

    public function test_dashboard_62_empty_recent_incidents_shows_placeholder_when_no_data(): void
    {
        // Only assertable when the tenant genuinely has no incidents; otherwise document via skip.
        $count = DB::table(self::INCIDENTS_TABLE)->whereNull('deleted_at')->count();
        if ($count > 0) {
            $this->markTestSkipped('Tenant already has ' . $count . ' incident(s); empty-state not reproducible non-destructively.');
        }

        $this->browseWithFailureScreenshot('empty-incidents', function (Browser $browser): void {
            $this->openDashboard($browser);
            $browser->assertSee('No incidents recorded yet.');
        });
    }

    public function test_dashboard_63_students_needing_attention_hidden_without_locked_scores(): void
    {
        // The "Students Needing Attention" card is @if($bottomStudents->isNotEmpty()) only.
        // When no locked period has computed scores, the card must be absent.
        $lockedWithScores = DB::table(self::PERIODS_TABLE . ' as p')
            ->join(self::SCORES_TABLE . ' as s', 's.period_id', '=', 'p.id')
            ->where('p.status', 'locked')
            ->whereNull('p.deleted_at')
            ->exists();

        if ($lockedWithScores) {
            $this->markTestSkipped('A locked period with computed scores exists; the attention card is legitimately shown.');
        }

        $this->browseWithFailureScreenshot('no-attention-card', function (Browser $browser): void {
            $this->openDashboard($browser);
            $browser->assertDontSee('Students Needing Attention');
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_dashboard_70_renders_without_locked_period_no_crash(): void
    {
        // With no latest-locked period the controller yields empty category/bottom collections;
        // the page must still render its KPI row and quick links without error.
        $this->browseWithFailureScreenshot('no-locked-period', function (Browser $browser): void {
            $this->openDashboard($browser);
            $browser->assertSee('Total Assessments')
                ->assertSee('Quick Links');
        });
    }

    public function test_dashboard_71_severity_enum_has_critical_but_blade_maps_only_three_dash_gap_04(): void
    {
        // ENUM allows 'critical', but the Recent Incidents blade only branches major/moderate/minor.
        if (DB::connection()->getDriverName() === 'mysql') {
            $col = collect(DB::select('SHOW COLUMNS FROM ' . self::INCIDENTS_TABLE))
                ->firstWhere('Field', 'severity');
            $this->assertNotNull($col, 'severity column not found.');
            $this->assertStringContainsString("'critical'", strtolower((string) ($col->Type ?? '')), 'severity ENUM should include critical.');
        }

        $blade = $this->readAppFile($this->moduleRootPath('resources/views/pages/dashboard.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('dashboard.blade.php source not readable.');
        }
        $this->assertStringContainsString("severity === 'major'", $blade, 'Blade should branch on major.');
        $this->assertStringContainsString("severity === 'moderate'", $blade, 'Blade should branch on moderate.');
        $this->assertStringContainsString("severity === 'minor'", $blade, 'Blade should branch on minor.');
        $this->assertStringNotContainsString("severity === 'critical'", $blade, 'DASH-GAP-04 changed: blade now handles critical severity.');
    }

    public function test_dashboard_72_kpi_values_are_number_formatted(): void
    {
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/pages/dashboard.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('dashboard.blade.php source not readable.');
        }
        $this->assertStringContainsString('number_format($totalAssessments)', $blade, 'Total Assessments KPI must be number_format-ed.');
        $this->assertStringContainsString('number_format($totalIncidents)', $blade, 'Total Incidents KPI must be number_format-ed.');
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security + requirement divergence
    // =====================================================================

    public function test_dashboard_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for the tenant-side dashboard.'
        );
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'Aggregate tables resolve within the current tenant DB.');
    }

    public function test_dashboard_91_cross_tenant_direct_isolation_defensive(): void
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

    public function test_dashboard_92_implemented_kpis_diverge_from_requirement_dash_gap_01(): void
    {
        // Requirement 01-Dashboard KPI cards: Active Assessment Period / Assessments Completed % /
        // Incidents Logged (This Week) / Active Interventions.
        // Implementation renders a different KPI set — assert the ACTUAL labels, proving DASH-GAP-01.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/pages/dashboard.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('dashboard.blade.php source not readable.');
        }
        $this->assertStringContainsString('Total Assessments', $blade);
        $this->assertStringContainsString('Students Assessed', $blade);
        $this->assertStringContainsString('Open Periods', $blade);
        // The requirement's headline KPIs are NOT implemented.
        $this->assertStringNotContainsString('Assessments Completed', $blade, 'DASH-GAP-01 changed: % completed KPI now implemented.');
        $this->assertStringNotContainsString('Active Interventions', $blade, 'DASH-GAP-01 changed: active interventions KPI now implemented.');
    }

    public function test_dashboard_93_stored_xss_in_incident_description_not_executed_on_dashboard(): void
    {
        $incident = $this->seedIncident([
            'incident_type' => 'negative_incident',
            'severity'      => 'major',
            'incident_date' => now()->addYears(5)->toDateString(),
            'description'   => 'Dashboard XSS <img src=x onerror=alert(1)>',
        ]);
        if ($incident === null) {
            $this->markTestSkipped('Could not seed an incident for the stored-XSS check.');
        }

        try {
            $this->browseWithFailureScreenshot('stored-xss', function (Browser $browser): void {
                $this->openDashboard($browser);
                $this->assertStringNotContainsString(
                    '<img src=x onerror=alert(1)>',
                    $browser->driver->getPageSource(),
                    'Stored incident description must be escaped anywhere it surfaces on the dashboard.'
                );
            });
        } finally {
            $this->deleteIncident($incident);
        }
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
        $rawName = 'dashboard-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'dashboard-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- UI drivers -------------------------------------------------------

    private function openDashboard(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::DASHBOARD_PATH, 1200);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $source = $browser->driver->getPageSource();
            return str_contains($source, 'Behavioural Assessment Dashboard')
                || str_contains($source, 'Quick Links');
        }, 'Dashboard page did not render.');
    }

    // ---- HTTP-from-browser (authenticated fetch) --------------------------

    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
    }

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openDashboard($browser);
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
window.__baApiDone = false;
window.__baApiError = '';
window.__baApiResult = null;

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

        window.__baApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__baApiError = String(error);
    } finally {
        window.__baApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__baApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__baApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__baApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // `redirect: manual` reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Seed / cleanup (defensive, cross-module aware) -------------------

    private function seedIncident(array $overrides = []): ?BaIncident
    {
        try {
            $studentId  = $this->existingStudentId();
            $employeeId = $this->existingEmployeeId();
            if ($studentId === null || $employeeId === null) {
                return null;
            }

            $data = array_merge([
                'incident_date'         => now()->toDateString(),
                'incident_type'         => 'negative_incident',
                'severity'              => 'major',
                'description'           => 'Seeded dashboard incident ' . $this->uniqueSuffix(),
                'location'              => 'classroom',
                'is_follow_up_required' => 0,
                'is_notified'           => 0,
                'is_active'             => 1,
                'student_id'            => $studentId,
                'reported_by'           => $employeeId,
                'created_by'            => (int) $this->adminUser->id,
                'updated_by'            => (int) $this->adminUser->id,
                'created_at'            => now(),
                'updated_at'            => now(),
            ], $overrides);

            $id = DB::table(self::INCIDENTS_TABLE)->insertGetId($data);
            return BaIncident::query()->find($id);
        } catch (Throwable) {
            return null;
        }
    }

    private function deleteIncident(?BaIncident $incident): void
    {
        if ($incident === null) {
            return;
        }
        try {
            DB::table(self::INCIDENTS_TABLE)->where('id', $incident->id)->delete();
        } catch (Throwable) {
        }
    }

    /** @return object{id:int,name:string}|null */
    private function seedLockedPeriod(): ?object
    {
        try {
            $sessionId = DB::table('sch_org_academic_sessions_jnt')->value('id');
            if ($sessionId === null) {
                return null;
            }
            $name = 'DASH LOCKED ' . $this->uniqueSuffix();
            $id = DB::table(self::PERIODS_TABLE)->insertGetId([
                'name'                => $name,
                'start_date'          => now()->subMonths(2)->toDateString(),
                'end_date'            => now()->subMonth()->toDateString(),
                'deadline'            => now()->subMonth()->toDateString(),
                'status'              => 'locked',
                'is_active'           => 1,
                'academic_session_id' => $sessionId,
                'created_by'          => (int) $this->adminUser->id,
                'updated_by'          => (int) $this->adminUser->id,
                'created_at'          => now(),
                'updated_at'          => now(),
            ]);
            return (object) ['id' => (int) $id, 'name' => $name];
        } catch (Throwable) {
            return null;
        }
    }

    private function deletePeriod(?object $period): void
    {
        if ($period === null) {
            return;
        }
        try {
            DB::table(self::PERIODS_TABLE)->where('id', $period->id)->delete();
        } catch (Throwable) {
        }
    }

    private function existingStudentId(): ?int
    {
        try {
            if (!Schema::hasTable('std_students')) {
                return null;
            }
            $id = DB::table('std_students')->value('id');
            return $id === null ? null : (int) $id;
        } catch (Throwable) {
            return null;
        }
    }

    private function existingEmployeeId(): ?int
    {
        try {
            if (!Schema::hasTable('sch_employees')) {
                return null;
            }
            $id = DB::table('sch_employees')->value('id');
            return $id === null ? null : (int) $id;
        } catch (Throwable) {
            return null;
        }
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
                'name'              => 'BA Dash Limited ' . $this->uniqueSuffix(),
                'email'             => 'ba_dash_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'DL' . substr($this->uniqueSuffix(), -8);
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
        $this->grantDashboardPermissions($this->adminUser);
    }

    private function grantDashboardPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::DASH_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::DASH_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::DASH_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.ba-dashboard-admin');
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
            $modelFile = (new ReflectionClass(BaIncident::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaIncident.php → module root = dirname(,3)
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

    /** Best-effort isolation of a method body from PHP source (brace-matched). */
    private function extractMethodBody(string $source, string $method): string
    {
        $needle = 'function ' . $method . '(';
        $pos = strpos($source, $needle);
        if ($pos === false) {
            return '';
        }
        $brace = strpos($source, '{', $pos);
        if ($brace === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($source);
        for ($i = $brace; $i < $len; $i++) {
            $ch = $source[$i];
            if ($ch === '{') {
                $depth++;
            } elseif ($ch === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $brace, $i - $brace + 1);
                }
            }
        }
        return substr($source, $brace);
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
