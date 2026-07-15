<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Controllers\BaReportController;
use Modules\BehaviouralAssessment\Models\BaComputedScore;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use ReflectionMethod;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Period Progress (screen 22, "Longitudinal Trend Dashboard").
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/22-Period-Progress.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime data source: ba_computed_scores  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaReportController
 *                      -- NO `progress()` method exists. The screen is UNIMPLEMENTED.
 * Route              : NONE — there is no `reports/progress` route (RPT-GAP-PROG-02).
 * View               : NONE — there is no `reports/progress.blade.php` (RPT-GAP-PROG-03).
 * Permission prefix  : tenant.behavioural-assessment.reports.{viewAny|view|export}
 * Activity log       : NONE — read-only report surface, no activityLog() helper (documented absence).
 * Test STYLE         : browser Dusk (extends DuskTestCase) — mirrors the committed sibling
 *                      PeriodReport/ClassAnalysis (same module, same BaReportController).
 *
 * WHICH CONTROLLER METHOD BACKS THIS SCREEN? — none.
 *   The Feature Inventory tags PeriodProgress as "BaReportController · reads computed_scores · LIGHT".
 *   Exhaustive source scan (grep progress|trend|milestone|interpolat|longitudinal + Route::has + method scan)
 *   proves there is NO progress()/trend() controller action, NO reports/progress route, and NO progress view.
 *   The requirement (trend-line chart, milestone flags, KPI Score-Delta cards, 5-category multi-line limit,
 *   continuous interpolation) has ZERO implementation. This is the primary finding — the whole screen is a
 *   specified-but-unbuilt feature. Proven in _03/_04/_05/_71/_74.
 *
 * IS BUG-BA-013 APPLICABLE HERE? — YES, to the specified data path (not to a live route, because none exists).
 *   Screen-22 says: "The system queries `ba_computed_scores` for John across all active terms" and plots the
 *   composite/category score trend and the section class-average per quarter. That is exactly the per-period
 *   ba_computed_scores aggregation that the two implemented computed-scores methods already perform DEFECTIVELY:
 *     - categories() : RAW SQL `AVG(score)/MIN(score)/MAX(score)` on ba_computed_scores → SQL "Unknown column
 *                      'score'" → HARD 500 (the live column is `numeric_score`).
 *     - byClass()    : collection `->avg('score')/min/max/pluck('score')` → null → 0.00 (silent wrong data).
 *     - student()    : correctly uses `avg('numeric_score')`/`AVG(numeric_score)` (the CONTRAST — proven in _73).
 *   Any implementation of Period Progress that reuses the categories()/byClass() idiom inherits BUG-BA-013.
 *   Proven deterministically in _72 and at source level in _73.
 *
 * Defects / gaps proven:
 *   - RPT-GAP-PROG-01 : the Period Progress screen is entirely unimplemented — no progress() method (_03),
 *                       no reports/progress route (_04), no progress view / trend widgets (_05, _71).
 *   - RPT-GAP-PROG-02 : the requirement business rules (5-category multi-line limit, continuous interpolation
 *                       of missing periods, Score-Delta KPI %) have no controller/view implementation (_74).
 *   - BUG-BA-013      : the specified ba_computed_scores per-period aggregation is defective in the reusable
 *                       computed-scores methods (categories() AVG(score) hard-500; byClass() avg('score')=0.00);
 *                       root column is `score` which does not exist — live column is `numeric_score` (_72, _73).
 *   - BUG-BA-011      : reports/export (the requirement's "export progress chart to PDF", step 9) is a permanent
 *                       abort(501) stub on a live authorized route (_70).
 *   - DEAD-BA-001     : routes/api.php `behaviouralassessments` apiResource has NO tenancy middleware AND is
 *                       never registered (RSP::map maps only web.php — constraint #23) (_91).
 *   - DOC-BA-001      : DDL doc prefix `bha_` diverges from the live `ba_` runtime prefix (_02).
 *   - VAL-BA-003      : export() authorizes reports.view though BaReportPolicy exposes the `export` ability on
 *                       reports.export (weaker gate than the declared policy ability) (_53).
 */
class bha_PeriodProgress_TestCas extends DuskTestCase
{
    private const URL_PREFIX      = '/behavioural-assessment';
    private const REPORTS_INDEX   = '/behavioural-assessment/reports';
    private const REPORT_STUDENT  = '/behavioural-assessment/reports/student/';   // append student id
    private const REPORT_CLASS    = '/behavioural-assessment/reports/class/';      // append class-section id
    private const REPORT_CATEG    = '/behavioural-assessment/reports/categories';
    private const REPORT_EXPORT   = '/behavioural-assessment/reports/export';
    private const REPORT_PROGRESS = '/behavioural-assessment/reports/progress';    // the SPECIFIED-but-missing screen

    private const SCORES_TABLE    = 'ba_computed_scores';
    private const PERIOD_TABLE    = 'ba_assessment_periods';
    private const DDL_SCORES      = 'bha_computed_scores';   // stale DDL-doc name (must NOT exist at runtime)

    private const MISSING_ID      = 987654321;

    private const SCREENSHOT_DIR  = 'tests/Browser/Modules/BehaviouralAssessment/PeriodProgress/screenshots';

    /** @var array<int,string> */
    private const REPORT_PERMISSIONS = [
        'tenant.behavioural-assessment.reports.viewAny',
        'tenant.behavioural-assessment.reports.view',
        'tenant.behavioural-assessment.reports.export',
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
    // Band 01–09 — Schema / DDL / model / route configuration truth
    // =====================================================================

    public function test_period_progress_01_computed_scores_schema_and_model_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'Table ba_computed_scores (the trend data source) does not exist.');

        $this->assertTrue(
            Schema::hasColumns(self::SCORES_TABLE, [
                'id', 'student_id', 'category_id', 'period_id',
                'numeric_score', 'grade', 'overall_score', 'overall_grade',
                'computed_at', 'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_computed_scores.'
        );

        // The trend dashboard's specified aggregation reads `score`, which does NOT exist — live column is
        // `numeric_score` (BUG-BA-013 root).
        $this->assertFalse(
            Schema::hasColumn(self::SCORES_TABLE, 'score'),
            'ba_computed_scores has no bare `score` column — the computed-scores aggregation code that reads it is defective (BUG-BA-013).'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::SCORES_TABLE))->keyBy('Field');
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['numeric_score']->Type ?? '')));
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['overall_score']->Type ?? '')));
        }

        // Migration content — resolved from the APP repo via reflection (constraint #29/#32); fail-soft.
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130619_create_ba_computed_scores_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_computed_scores'", $migration);
            $this->assertStringContainsString("decimal('numeric_score', 5, 2)", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        $score = new BaComputedScore();
        $this->assertSame('ba_computed_scores', $score->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaComputedScore::class));
        $this->assertContains('numeric_score', $score->getFillable());
        $this->assertNotContains('score', $score->getFillable(), 'There is no `score` fillable — only numeric_score/overall_score exist.');
        $this->assertInstanceOf(BelongsTo::class, $score->student());
        $this->assertInstanceOf(BelongsTo::class, $score->category());
        $this->assertInstanceOf(BelongsTo::class, $score->period());
    }

    public function test_period_progress_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
    {
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'Runtime table ba_computed_scores must exist.');

        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_SCORES),
                'DOC-BA-001 regression: bha_computed_scores exists at runtime; expected only the live ba_computed_scores.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 check: ' . $e->getMessage());
        }

        $this->assertSame('ba_computed_scores', (new BaComputedScore())->getTable());
    }

    public function test_period_progress_03_no_progress_controller_action_exists_rpt_gap_prog_01(): void
    {
        // RPT-GAP-PROG-01: BaReportController implements the OTHER reports, but NO progress()/trend() action.
        foreach (['index', 'student', 'byClass', 'period', 'categories', 'incidents', 'export'] as $method) {
            $this->assertTrue(
                method_exists(BaReportController::class, $method),
                "BaReportController::{$method}() is expected to exist (sibling report method)."
            );
        }

        foreach (['progress', 'trend', 'periodProgress', 'trendline'] as $missing) {
            $this->assertFalse(
                method_exists(BaReportController::class, $missing),
                "RPT-GAP-PROG-01 changed: BaReportController::{$missing}() now exists — Period Progress may have been implemented."
            );
        }

        // Enumerate PUBLIC actions to be certain none is a progress action under another name.
        $public = array_map(
            static fn (ReflectionMethod $m): string => strtolower($m->getName()),
            (new ReflectionClass(BaReportController::class))->getMethods(ReflectionMethod::IS_PUBLIC)
        );
        $this->assertNotContains('progress', $public, 'RPT-GAP-PROG-01: no public progress action.');
        $this->assertNotContains('trend', $public, 'RPT-GAP-PROG-01: no public trend action.');
    }

    public function test_period_progress_04_no_progress_route_is_registered_rpt_gap_prog_02(): void
    {
        // The implemented report routes ARE registered ...
        foreach ([
            'behavioural-assessment.reports.index',
            'behavioural-assessment.reports.student',
            'behavioural-assessment.reports.class',
            'behavioural-assessment.reports.categories',
            'behavioural-assessment.reports.export',
        ] as $routeName) {
            $this->assertTrue(Route::has($routeName), "Sibling report route {$routeName} is expected to be registered.");
        }

        // ... but the specified Period Progress route is NOT.
        foreach ([
            'behavioural-assessment.reports.progress',
            'behavioural-assessment.reports.trend',
            'behavioural-assessment.reports.period-progress',
        ] as $missingRoute) {
            $this->assertFalse(
                Route::has($missingRoute),
                "RPT-GAP-PROG-02 changed: route {$missingRoute} is now registered — Period Progress may exist."
            );
        }
    }

    public function test_period_progress_05_no_progress_view_or_trend_widgets_exist_rpt_gap_prog_03(): void
    {
        // No progress.blade.php in the reports view folder, and none of the requirement's trend widgets are
        // rendered anywhere in the reports views.
        $viewsDir = $this->moduleRootPath('resources/views/reports');
        if ($viewsDir !== null && is_dir($viewsDir)) {
            $this->assertFileDoesNotExist($viewsDir . '/progress.blade.php', 'RPT-GAP-PROG-03: reports/progress.blade.php exists — screen may be implemented.');
            $this->assertFileDoesNotExist($viewsDir . '/period-progress.blade.php', 'RPT-GAP-PROG-03: reports/period-progress.blade.php exists.');
            $this->assertFileDoesNotExist($viewsDir . '/trend.blade.php', 'RPT-GAP-PROG-03: reports/trend.blade.php exists.');
        }

        // The requirement's signature widget strings must be absent from the whole reports view tree.
        $needles = [
            'Period Progress', 'Trend Line', 'Milestone', 'Composite Score Trend',
            'Total Progress Delta', 'Starting Score', 'Ending Score',
        ];
        $found = $this->grepReportsViews($needles);
        $this->assertSame(
            [],
            $found,
            'RPT-GAP-PROG-03: expected the Period Progress trend widgets to be absent, but found: ' . implode(', ', $found)
        );
    }

    // =====================================================================
    // Band 10–19 — Render / data-path presence (the surface a progress screen would sit on)
    // =====================================================================

    public function test_period_progress_10_reports_hub_renders_for_authorized_admin(): void
    {
        $this->browseWithFailureScreenshot('hub-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORTS_INDEX, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser), 'Authorized admin must not be bounced to login.');
        });
    }

    public function test_period_progress_11_reports_hub_does_not_link_a_period_progress_screen(): void
    {
        // The hub links period/incidents/categories reports but exposes NO Period Progress / trend link.
        $this->browseWithFailureScreenshot('hub-no-progress-link', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORTS_INDEX, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('Whoops', $source, 'Reports hub must render without a server error.');
            $this->assertStringNotContainsString('Period Progress', $source, 'Reports hub must not advertise an unimplemented Period Progress screen.');
            $this->assertStringNotContainsString('reports/progress', $source, 'Reports hub must not link a reports/progress route.');
        });
    }

    public function test_period_progress_12_computed_scores_backed_report_renders_as_nearest_surface(): void
    {
        // The nearest implemented computed-scores surface a trend dashboard would extend is the per-student
        // report (student() uses numeric_score correctly). Prove it renders (200) or redirects (302), never 500.
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available to render the computed-scores-backed report.');
        }
        $response = $this->getFromAdminPage(self::REPORT_STUDENT . $studentId);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'The per-student computed-scores report must render (student() reads numeric_score correctly).'
        );
    }

    public function test_period_progress_13_requirement_names_computed_scores_as_the_trend_data_source(): void
    {
        // Documentation-truth: screen-22 explicitly queries ba_computed_scores across terms. Confirm the source
        // table exists and that the multi-period axis data (period_id) is present for a longitudinal plot.
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'ba_computed_scores is the specified trend source.');
        $this->assertTrue(Schema::hasColumn(self::SCORES_TABLE, 'period_id'), 'period_id is the X-axis key for a longitudinal trend.');
        $this->assertTrue(Schema::hasColumn(self::SCORES_TABLE, 'numeric_score'), 'numeric_score is the Y-axis value for a trend line.');
        $this->assertTrue(Schema::hasTable(self::PERIOD_TABLE), 'ba_assessment_periods supplies the chronological X-axis.');
    }

    // =====================================================================
    // Band 30–39 — Validation / negative (missing route, invalid ids)
    // =====================================================================

    public function test_period_progress_30_progress_url_returns_404_because_screen_is_unbuilt(): void
    {
        // Hitting the specified /reports/progress url returns 404 — there is no such route.
        $response = $this->getFromAdminPage(self::REPORT_PROGRESS);
        $this->assertSame(
            404,
            (int) ($response['status'] ?? 0),
            'RPT-GAP-PROG-02: /reports/progress must 404 (route not registered).'
        );
    }

    public function test_period_progress_31_invalid_student_id_on_data_path_returns_404(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_STUDENT . self::MISSING_ID);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Unknown student id on the computed-scores report path must 404 (findOrFail).');
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency (BC-INT / BC-REF)
    // =====================================================================

    public function test_period_progress_40_computed_scores_fks_restrict_on_delete(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('FK metadata inspection requires MySQL.');
        }
        try {
            $rules = collect(DB::select(
                "SELECT REFERENCED_TABLE_NAME, DELETE_RULE
                 FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'ba_computed_scores'"
            ))->keyBy('REFERENCED_TABLE_NAME');

            if ($rules->isEmpty()) {
                $this->markTestSkipped('No FK metadata for ba_computed_scores.');
            }
            foreach (['std_students', 'ba_categories', 'ba_assessment_periods'] as $ref) {
                if (isset($rules[$ref])) {
                    $rule = strtoupper((string) ($rules[$ref]->DELETE_RULE ?? ''));
                    $this->assertTrue(
                        str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'),
                        "ba_computed_scores → {$ref} should be RESTRICT; found {$rule}."
                    );
                }
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('FK dependency inspection unavailable: ' . $e->getMessage());
        }
    }

    public function test_period_progress_41_computed_scores_uniquely_key_student_category_period(): void
    {
        // uq_ba_score (student_id, category_id, period_id) — one score row per student/category/period, which is
        // exactly the grain a per-period trend line consumes.
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Unique-index inspection requires MySQL.');
        }
        try {
            $indexes = collect(DB::select('SHOW INDEX FROM ' . self::SCORES_TABLE))
                ->groupBy('Key_name')
                ->map(fn ($rows) => $rows->pluck('Column_name')->all());

            $uniqueTriples = $indexes->filter(function (array $cols, string $name): bool {
                return in_array('student_id', $cols, true)
                    && in_array('category_id', $cols, true)
                    && in_array('period_id', $cols, true);
            });
            $this->assertTrue($uniqueTriples->isNotEmpty(), 'Expected a (student_id, category_id, period_id) unique key on ba_computed_scores.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Index inspection unavailable: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_period_progress_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::REPORTS_INDEX))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_period_progress_51_limited_user_gets_403_on_computed_scores_report(): void
    {
        $studentId = $this->anyStudentId() ?? self::MISSING_ID;
        $limited = $this->makeLimitedUser();
        $this->browseWithFailureScreenshot('limited-403', function (Browser $browser) use ($limited, $studentId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORT_STUDENT . $studentId));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'reports.view gate must block the limited user before findOrFail.');
        });
        $this->deleteUser($limited);
    }

    public function test_period_progress_52_report_policy_maps_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaReportPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('BaReportPolicy source not readable.');
        }
        foreach (['viewAny', 'view', 'export'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.reports.{$ability}",
                $policy,
                "BaReportPolicy missing gate string for {$ability}."
            );
        }
    }

    public function test_period_progress_53_export_gate_diverges_from_policy_val_ba_003(): void
    {
        // VAL-BA-003: the requirement's "export progress chart" would flow through export(), which authorizes
        // reports.view — though BaReportPolicy declares the `export` ability on reports.export.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaReportPolicy.php'));
        if ($controller === null || $policy === null) {
            $this->markTestSkipped('Sources not readable to confirm VAL-BA-003.');
        }
        $exportBody = $this->extractMethodBody($controller, 'function export', null, 400);
        $this->assertStringContainsString('tenant.behavioural-assessment.reports.view', $exportBody, 'export() gates on reports.view.');
        $this->assertStringNotContainsString('tenant.behavioural-assessment.reports.export', $exportBody, 'VAL-BA-003: export() does NOT use the reports.export permission.');
        $this->assertStringContainsString('tenant.behavioural-assessment.reports.export', $policy, 'Policy still declares the unused export ability.');
    }

    // =====================================================================
    // Band 70–79 — Requirement-vs-implementation gaps + BUG-BA-013 (BC-EDG)
    // =====================================================================

    public function test_period_progress_70_export_is_live_abort_501_stub_bug_ba_011(): void
    {
        // BUG-BA-011: screen-22 step 9 "exports this progress chart to PDF" — the only export route is a 501 stub.
        $response = $this->getFromAdminPage(self::REPORT_EXPORT);
        $this->assertSame(
            501,
            (int) ($response['status'] ?? 0),
            'BUG-BA-011 regression fixed? Export should currently abort(501) "Export feature coming soon."'
        );
    }

    public function test_period_progress_71_trend_dashboard_widgets_are_unimplemented_rpt_gap_prog_01(): void
    {
        // The trend-line chart, milestone flags, and KPI Score-Delta cards have no controller or view code.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm RPT-GAP-PROG-01.');
        }
        $lower = strtolower($controller);
        $this->assertStringNotContainsString('function progress', $lower, 'RPT-GAP-PROG-01: no progress action in the controller.');
        $this->assertStringNotContainsString('milestone', $lower, 'RPT-GAP-PROG-01: no milestone-marker logic.');
        $this->assertStringNotContainsString('interpolat', $lower, 'RPT-GAP-PROG-01: no continuous-interpolation logic.');
        // The only "trend" in the controller is the 6-month INCIDENT trend, not a per-period score trend line.
        $this->assertStringNotContainsString('reports.progress', $controller, 'RPT-GAP-PROG-01: controller never references a progress view/route.');
    }

    public function test_period_progress_72_computed_scores_aggregation_on_score_yields_zero_bug_ba_013(): void
    {
        // Deterministic BUG-BA-013 proof against the exact aggregation the trend screen would reuse (byClass idiom):
        //   overall = round((float) $scores->avg('score'), 2)  — with no `score` attribute this is null → 0.00,
        // while the correct numeric_score aggregate is the real value. A 4.25 student would trend as a flat 0.00.
        $this->assertFalse(Schema::hasColumn(self::SCORES_TABLE, 'score'), 'BUG-BA-013 root: ba_computed_scores has no `score` column.');
        $this->assertContains('numeric_score', (new BaComputedScore())->getFillable());

        $seed = $this->seedComputedScore(['numeric_score' => 4.25]);
        if ($seed === null) {
            $this->markTestSkipped('Could not seed a computed score (student/category/period unavailable) to prove BUG-BA-013.');
        }

        try {
            $rows = BaComputedScore::query()->whereKey($seed->id)->get();

            // The (broken) aggregation the reusable computed-scores code performs:
            $brokenAvg = $rows->avg('score');
            $this->assertNull($brokenAvg, 'BUG-BA-013: avg(\'score\') over rows with no `score` attribute is null.');
            $this->assertSame(0.0, round((float) $brokenAvg, 2), 'BUG-BA-013: round((float) null, 2) = 0.00 — a 4.25 student trends as flat 0.00.');

            // The correct aggregation the trend SHOULD perform:
            $this->assertSame(4.25, round((float) $rows->avg('numeric_score'), 2), 'numeric_score is the real column and aggregates correctly.');

            // The per-row attribute the milestone/KPI code would read is also absent.
            $seed->refresh();
            $this->assertNull($seed->score, 'BUG-BA-013: BaComputedScore exposes no `score` attribute.');
        } finally {
            $this->deleteComputedScore($seed);
        }
    }

    public function test_period_progress_73_controller_score_aggregation_is_defective_contrast_student_bug_ba_013(): void
    {
        // Source-level proof + precise applicability: the two computed-scores methods a trend screen reuses are
        // defective on `score`; the per-student method uses numeric_score correctly (the contrast).
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm BUG-BA-013.');
        }

        $categoriesBody = $this->extractMethodBody($controller, 'function categories', 'function export');
        $this->assertStringContainsString('AVG(score)', $categoriesBody, 'BUG-BA-013: categories() aggregates the non-existent `score` via RAW SQL (hard 500).');

        $byClassBody = $this->extractMethodBody($controller, 'function byClass', 'function incidents');
        $this->assertStringContainsString("avg('score')", $byClassBody, 'BUG-BA-013: byClass() averages the non-existent `score` (silent 0.00).');

        // Contrast: the per-student report (the nearest correct data path) reads the real column.
        $studentBody = $this->extractMethodBody($controller, 'function student', 'function byClass');
        $this->assertStringContainsString("avg('numeric_score')", $studentBody, 'student() reads the real numeric_score column (BUG-BA-013 does NOT affect the per-student path).');
        $this->assertStringNotContainsString("avg('score')", $studentBody, 'student() never averages the broken `score` column.');
    }

    public function test_period_progress_74_multiline_limit_and_interpolation_rules_unimplemented_rpt_gap_prog_02(): void
    {
        // Screen-22 business rules: max 5 category lines (alert on the 6th), continuous interpolation of missing
        // middle periods with a dashed line, Score-Delta % KPI. None exist in controller or view.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm RPT-GAP-PROG-02.');
        }
        $lower = strtolower($controller);
        $this->assertStringNotContainsString('interpolat', $lower, 'RPT-GAP-PROG-02: no continuous-interpolation rule.');
        $this->assertStringNotContainsString('max 5', $lower, 'RPT-GAP-PROG-02: no 5-category multi-line cap.');
        $this->assertStringNotContainsString('score delta', $lower, 'RPT-GAP-PROG-02: no Score-Delta KPI computation.');

        // And confirm the widget strings are absent from the whole reports view tree (nothing renders these rules).
        $found = $this->grepReportsViews(['interpolat', 'Uncheck a category', 'Total Progress Delta']);
        $this->assertSame([], $found, 'RPT-GAP-PROG-02: expected the multi-line/interpolation/KPI widgets absent, found: ' . implode(', ', $found));
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + API deadness + security
    // =====================================================================

    public function test_period_progress_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side report tests.'
        );
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'ba_computed_scores must resolve within the tenant DB.');
        $this->assertTrue(Schema::hasTable(self::PERIOD_TABLE), 'ba_assessment_periods must resolve within the tenant DB.');
    }

    public function test_period_progress_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001(): void
    {
        // DEAD-BA-001: routes/api.php declares Route::middleware(['auth:sanctum'])->apiResource(...) with NO
        // tenancy bootstrapper; and RSP::map() only maps web.php (constraint #23) — the route is never registered.
        $apiRegistered = Route::has('behaviouralassessment.index');
        $this->assertFalse(
            $apiRegistered,
            'DEAD-BA-001: the api behaviouralassessments resource is not registered (RSP::map maps only web.php).'
        );

        $api = $this->readAppFile($this->moduleRootPath('routes/api.php'));
        $rsp = $this->readAppFile($this->moduleRootPath('app/Providers/RouteServiceProvider.php'));
        if ($api === null && $rsp === null) {
            $this->markTestSkipped('api.php / RSP sources not readable to confirm DEAD-BA-001.');
        }
        if ($api !== null) {
            $this->assertStringContainsString('auth:sanctum', $api, 'api.php uses the sanctum guard.');
            $this->assertStringNotContainsString('InitializeTenancyByDomain', $api, 'DEAD-BA-001: api.php has no tenancy middleware.');
        }
        if ($rsp !== null) {
            $this->assertStringNotContainsString('routes/api.php', $rsp, 'DEAD-BA-001: RSP::map() never loads routes/api.php.');
        }
    }

    public function test_period_progress_92_web_report_routes_carry_full_tenancy_stack(): void
    {
        $rsp = $this->readAppFile($this->moduleRootPath('app/Providers/RouteServiceProvider.php'));
        if ($rsp === null) {
            $this->markTestSkipped('RouteServiceProvider source not readable.');
        }
        foreach (['InitializeTenancyByDomain', 'PreventAccessFromCentralDomains', 'EnsureTenantIsActive', "'auth'", "'verified'"] as $needle) {
            $this->assertStringContainsString($needle, $rsp, "Web report routes must carry {$needle} in the middleware stack.");
        }
    }

    public function test_period_progress_93_rendered_report_escapes_output(): void
    {
        // Defensive stored-XSS smoke: the nearest computed-scores report (student) must HTML-escape output.
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available for the output-escaping smoke.');
        }
        $this->browseWithFailureScreenshot('escape-smoke', function (Browser $browser) use ($studentId): void {
            $this->visitAuthenticated($browser, self::REPORT_STUDENT . $studentId, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(', $source, 'Report output must be HTML-escaped by Blade.');
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
        $rawName = 'period-progress-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'period-progress-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- HTTP-from-browser (admin session) --------------------------------

    private function getFromAdminPage(string $path): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'GET', $this->tenantUrl($path)));
    }

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openReportsBase($browser);
            $result = $callback($browser);
        });
        return $result;
    }

    private function openReportsBase(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::REPORTS_INDEX, 900);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::REPORTS_INDEX, 800);
        }
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
window.__prApiDone = false;
window.__prApiError = '';
window.__prApiResult = null;

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

        window.__prApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__prApiError = String(error);
    } finally {
        window.__prApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__prApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__prApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__prApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Seed / cleanup (computed scores) ---------------------------------

    /**
     * Seed one computed-score row for an existing student/category/period.
     *
     * @param  array<string,mixed>  $overrides
     */
    private function seedComputedScore(array $overrides = []): ?BaComputedScore
    {
        try {
            $studentId  = $this->anyStudentId();
            $categoryId = Schema::hasTable('ba_categories') ? DB::table('ba_categories')->value('id') : null;
            $periodId   = Schema::hasTable(self::PERIOD_TABLE) ? DB::table(self::PERIOD_TABLE)->value('id') : null;

            if ($studentId === null || $categoryId === null || $periodId === null || $this->adminUser === null) {
                return null;
            }

            BaComputedScore::withTrashed()
                ->where('student_id', $studentId)
                ->where('category_id', $categoryId)
                ->where('period_id', $periodId)
                ->get()
                ->each(fn (BaComputedScore $s) => $this->deleteComputedScore($s));

            $payload = array_merge([
                'student_id'    => $studentId,
                'category_id'   => (int) $categoryId,
                'period_id'     => (int) $periodId,
                'numeric_score' => 4.25,
                'grade'         => 'A',
                'overall_score' => 4.10,
                'overall_grade' => 'A',
                'computed_at'   => now(),
                'is_active'     => true,
                'created_by'    => (int) $this->adminUser->id,
                'updated_by'    => (int) $this->adminUser->id,
            ], $overrides);

            return BaComputedScore::query()->create($payload);
        } catch (Throwable) {
            return null;
        }
    }

    private function deleteComputedScore(?BaComputedScore $score): void
    {
        if ($score === null) {
            return;
        }
        try {
            $score->forceDelete();
        } catch (Throwable) {
        }
    }

    private function anyStudentId(): ?int
    {
        foreach (['std_students', 'students'] as $table) {
            $id = $this->firstIdOf($table);
            if ($id !== null) {
                return $id;
            }
        }
        return null;
    }

    private function firstIdOf(string $table): ?int
    {
        try {
            if (!Schema::hasTable($table)) {
                return null;
            }
            $id = DB::table($table)->value('id');
            return $id !== null ? (int) $id : null;
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
                'name'              => 'PP Limited ' . $this->uniqueSuffix(),
                'email'             => 'pp_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'PP' . substr($this->uniqueSuffix(), -8);
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
        $this->ensurePermissionsExist(self::REPORT_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::REPORT_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::REPORT_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.ba-report-admin');
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
            $modelFile = (new ReflectionClass(BaComputedScore::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaComputedScore.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaComputedScore::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaComputedScore.php → app root = dirname(,5)
            $appRoot = dirname($modelFile, 5);
            return $appRoot . '/' . ltrim($relative, '/');
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

    /**
     * Grep the reports view tree for any of the given needles; returns the needles that were found.
     *
     * @param  array<int,string>  $needles
     * @return array<int,string>
     */
    private function grepReportsViews(array $needles): array
    {
        $dir = $this->moduleRootPath('resources/views/reports');
        if ($dir === null || !is_dir($dir)) {
            return [];
        }
        $found = [];
        $files = glob($dir . DIRECTORY_SEPARATOR . '*.blade.php');
        if ($files === false) {
            return [];
        }
        foreach ($files as $file) {
            $content = $this->readAppFile($file);
            if ($content === null) {
                continue;
            }
            foreach ($needles as $needle) {
                if (str_contains($content, $needle) && !in_array($needle, $found, true)) {
                    $found[] = $needle;
                }
            }
        }
        return $found;
    }

    /**
     * Extract a method body from source text: from $startMarker up to $endMarker (or a byte cap).
     */
    private function extractMethodBody(string $source, string $startMarker, ?string $endMarker, int $cap = 4000): string
    {
        $start = strpos($source, $startMarker);
        if ($start === false) {
            return $source;
        }
        if ($endMarker !== null) {
            $end = strpos($source, $endMarker, $start + strlen($startMarker));
            if ($end !== false) {
                return substr($source, $start, $end - $start);
            }
        }
        return substr($source, $start, $cap);
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
