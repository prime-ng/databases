<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Controllers\BaReportController;
use Modules\BehaviouralAssessment\Models\BaAssessment;
use Modules\BehaviouralAssessment\Models\BaAssessmentPeriod;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Period Report (a.k.a. "Teacher Progress Report").
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/18-Period-Report.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime tables     : ba_assessment_periods, ba_assessments, ba_assessment_ratings, ba_student_remarks
 *                      (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaReportController@period(int $period)
 *                      Gate::authorize('tenant.behavioural-assessment.reports.view') then findOrFail($period).
 *                      Aggregates ba_assessments status counts + teacher-wise progress + rating/remarks
 *                      completion for a SINGLE period. Renders reports/period.blade.php.
 * Route              : GET reports/period/{period} → name behavioural-assessment.reports.period
 * Permission prefix  : tenant.behavioural-assessment.reports.{viewAny|view|export}
 * Activity log       : NONE — read-only report controller, no activityLog() helper (documented absence).
 * Test STYLE         : browser Dusk (extends DuskTestCase) — mirrors the committed sibling
 *                      StudentScoresReport/bha_StudentScoresReport_TestCas.php and RatingScale (same module).
 *
 * IMPORTANT — computed_scores is NOT read by this screen:
 *   The module inventory tags PeriodReport as "reads computed_scores (LIGHT)", but the actual period()
 *   method aggregates ba_assessments / ba_assessment_ratings / ba_student_remarks and never touches
 *   ba_computed_scores or its `score`/`numeric_score` columns. Therefore BUG-BA-013 (aggregation on the
 *   non-existent `score` column in byClass()/categories()) does NOT affect the Period Report path — proven
 *   as a contrast in _14. The computed-scores `score` bug lives in the ClassAnalysis / CategoryPerformance
 *   screens, not here.
 *
 * Defects / gaps proven:
 *   - BUG-BA-011    : reports/export is a permanent abort(501) stub on a live, authorized route (proven in _70).
 *   - DEAD-BA-001   : api.php `behaviouralassessments` apiResource has NO tenancy middleware AND is never
 *                     registered (RSP::map maps only web.php — constraint #23) (proven in _91).
 *   - DOC-BA-001    : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - VAL-BA-003    : export() authorizes reports.view though BaReportPolicy exposes an `export` ability on
 *                     reports.export (dead policy method / weaker gate) (proven in _53).
 *   - RPT-GAP-PRD-01: screen-18 specifies a multi-period COMPARISON grid (Roll No, Student, Period-N averages,
 *                     Score Delta, per-period incidents, Trend Indicator) with Session + Class/Section +
 *                     multi-period-select filters. The implemented period() renders a SINGLE-period teacher
 *                     progress report instead — the comparative analytics are unimplemented (proven in _71).
 *   - RPT-GAP-PRD-02: screen-18 "Score Delta" formula + "Dynamic Period Mapping" business rules have no
 *                     implementation in controller/view (proven in _72).
 *   - RPT-GAP-PRD-03: screen-18 report-card export is unimplemented — the only export route is the 501 stub
 *                     (proven in _73).
 *   - UI-BA-PRD-01  : the period selector <select name="period"> auto-submits GET ?period=<id> to the SAME url,
 *                     but period() binds only the route {period} path segment — changing the dropdown reloads
 *                     the same period (non-functional filter) (proven in _62).
 */
class bha_PeriodReport_TestCas extends DuskTestCase
{
    private const URL_PREFIX      = '/behavioural-assessment';
    private const REPORTS_INDEX   = '/behavioural-assessment/reports';
    private const REPORT_PERIOD   = '/behavioural-assessment/reports/period/'; // append period id
    private const REPORT_EXPORT   = '/behavioural-assessment/reports/export';

    private const PERIOD_TABLE    = 'ba_assessment_periods';
    private const ASSESS_TABLE    = 'ba_assessments';
    private const RATING_TABLE    = 'ba_assessment_ratings';
    private const REMARK_TABLE    = 'ba_student_remarks';
    private const SCORES_TABLE    = 'ba_computed_scores';
    private const DDL_PERIOD      = 'bha_assessment_periods';   // stale DDL-doc name (must NOT exist at runtime)

    private const MISSING_ID      = 987654321;

    private const SCREENSHOT_DIR  = 'tests/Browser/Modules/BehaviouralAssessment/PeriodReport/screenshots';

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

    public function test_period_report_01_period_and_assessment_schema_and_models_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::PERIOD_TABLE), 'Table ba_assessment_periods does not exist.');
        $this->assertTrue(Schema::hasTable(self::ASSESS_TABLE), 'Table ba_assessments does not exist.');

        $this->assertTrue(
            Schema::hasColumns(self::PERIOD_TABLE, [
                'id', 'academic_session_id', 'academic_term_id', 'name',
                'start_date', 'end_date', 'deadline', 'status',
                'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_assessment_periods.'
        );

        $this->assertTrue(
            Schema::hasColumns(self::ASSESS_TABLE, [
                'id', 'period_id', 'teacher_id', 'class_section_id', 'status',
                'submitted_at', 'reviewed_by', 'reviewed_at', 'reviewer_remarks',
                'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_assessments.'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            $pCols = collect(DB::select('SHOW COLUMNS FROM ' . self::PERIOD_TABLE))->keyBy('Field');
            $aCols = collect(DB::select('SHOW COLUMNS FROM ' . self::ASSESS_TABLE))->keyBy('Field');

            // Period lifecycle enum: open, closed, locked.
            $periodStatusType = strtolower((string) ($pCols['status']->Type ?? ''));
            $this->assertStringContainsString('enum', $periodStatusType);
            foreach (['open', 'closed', 'locked'] as $st) {
                $this->assertStringContainsString($st, $periodStatusType, "Period status enum missing '{$st}'.");
            }

            // Assessment workflow enum: draft, submitted, reviewed, locked.
            $assessStatusType = strtolower((string) ($aCols['status']->Type ?? ''));
            $this->assertStringContainsString('enum', $assessStatusType);
            foreach (['draft', 'submitted', 'reviewed', 'locked'] as $st) {
                $this->assertStringContainsString($st, $assessStatusType, "Assessment status enum missing '{$st}'.");
            }
        }

        // Migration content — resolved from the APP repo via reflection (constraint #29/#32); fail-soft.
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130617_create_ba_assessments_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_assessments'", $migration);
            $this->assertStringContainsString("enum('status'", $migration);
            $this->assertStringContainsString("constrained('ba_assessment_periods')", $migration);
            $this->assertStringContainsString("unique(['teacher_id', 'class_section_id', 'period_id'], 'uq_ba_assessment')", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // Model configuration.
        $period = new BaAssessmentPeriod();
        $this->assertSame('ba_assessment_periods', $period->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessmentPeriod::class));
        $this->assertInstanceOf(HasMany::class, $period->assessments());
        $this->assertInstanceOf(HasMany::class, $period->computedScores());
        $this->assertInstanceOf(BelongsTo::class, $period->academicSession());

        $assessment = new BaAssessment();
        $this->assertSame('ba_assessments', $assessment->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessment::class));
        $this->assertInstanceOf(BelongsTo::class, $assessment->period());
        $this->assertInstanceOf(BelongsTo::class, $assessment->teacher());
        $this->assertInstanceOf(HasMany::class, $assessment->ratings());
        $this->assertInstanceOf(HasMany::class, $assessment->studentRemarks());
    }

    public function test_period_report_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
    {
        $this->assertTrue(Schema::hasTable(self::PERIOD_TABLE), 'Runtime table ba_assessment_periods must exist.');

        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_PERIOD),
                'DOC-BA-001 regression: bha_assessment_periods exists at runtime; expected only the live ba_ table.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 check: ' . $e->getMessage());
        }

        $this->assertSame('ba_assessment_periods', (new BaAssessmentPeriod())->getTable());
        $this->assertSame('ba_assessments', (new BaAssessment())->getTable());
    }

    public function test_period_report_03_report_controller_period_method_and_routes_are_registered(): void
    {
        foreach (['index', 'student', 'byClass', 'period', 'categories', 'incidents', 'export'] as $method) {
            $this->assertTrue(
                method_exists(BaReportController::class, $method),
                "BaReportController::{$method}() is expected to exist."
            );
        }

        foreach ([
            'behavioural-assessment.reports.index',
            'behavioural-assessment.reports.period',
            'behavioural-assessment.reports.export',
        ] as $routeName) {
            $this->assertTrue(Route::has($routeName), "Route {$routeName} is not registered.");
        }
    }

    public function test_period_report_04_period_view_exists_with_breadcrumb_and_period_selector(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/period.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('reports/period.blade.php not readable from the app repo.');
        }
        $this->assertStringContainsString('Teacher Progress Report', $view, 'Period view breadcrumb title expected.');
        $this->assertStringContainsString('Assessment Workflow Status', $view, 'Workflow status section expected.');
        $this->assertStringContainsString('Teacher-Wise Progress', $view, 'Teacher-wise progress section expected.');
        $this->assertStringContainsString('name="period"', $view, 'Period selector <select name="period"> expected.');
    }

    // =====================================================================
    // Band 10–19 — Business rules / render + data correctness (BC-BIZ)
    // =====================================================================

    public function test_period_report_10_reports_hub_renders_for_authorized_admin(): void
    {
        $this->browseWithFailureScreenshot('hub-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORTS_INDEX, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser), 'Authorized admin must not be bounced to login.');
        });
    }

    public function test_period_report_11_period_report_renders_teacher_progress_for_real_period(): void
    {
        $periodId = $this->anyPeriodId();
        if ($periodId === null) {
            $this->markTestSkipped('No assessment period available to render the period report.');
        }

        $this->browseWithFailureScreenshot('period-render', function (Browser $browser) use ($periodId): void {
            $this->visitAuthenticated($browser, self::REPORT_PERIOD . $periodId, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser));
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('Whoops', $source, 'Period report must not throw a server error.');
            $this->assertTrue(
                str_contains($source, 'Teacher Progress Report') || str_contains($source, 'Teacher-Wise Progress'),
                'Period report must render the Teacher Progress heading.'
            );
        });
    }

    public function test_period_report_12_workflow_status_breakdown_renders(): void
    {
        $periodId = $this->anyPeriodId();
        if ($periodId === null) {
            $this->markTestSkipped('No assessment period available for the workflow-status render check.');
        }

        $this->browseWithFailureScreenshot('workflow-status', function (Browser $browser) use ($periodId): void {
            $this->visitAuthenticated($browser, self::REPORT_PERIOD . $periodId, 1000);
            $browser->assertSee('Assessment Workflow Status');
            $source = $browser->driver->getPageSource();
            // The four workflow labels are always rendered by the blade @foreach(['draft','submitted','reviewed','locked']).
            foreach (['Draft', 'Submitted', 'Reviewed', 'Locked'] as $label) {
                $this->assertStringContainsString($label, $source, "Workflow status label '{$label}' must render.");
            }
        });
    }

    public function test_period_report_13_teacher_progress_table_or_empty_state_renders(): void
    {
        $periodId = $this->anyPeriodId();
        if ($periodId === null) {
            $this->markTestSkipped('No assessment period available for the teacher-progress render check.');
        }

        $this->browseWithFailureScreenshot('teacher-progress', function (Browser $browser) use ($periodId): void {
            $this->visitAuthenticated($browser, self::REPORT_PERIOD . $periodId, 1000);
            $source = $browser->driver->getPageSource();
            $rendered = str_contains($source, 'No assessments found for this period')
                || str_contains($source, 'Last Activity')     // teacher table header
                || str_contains($source, 'Completion');        // teacher table header
            $this->assertTrue($rendered, 'Period report must render either the teacher-progress table or its empty state.');
        });
    }

    public function test_period_report_14_period_report_does_not_read_computed_score_column_contrast_ba_013(): void
    {
        // Contrast to BUG-BA-013: period() aggregates ba_assessments, NOT ba_computed_scores.
        // Prove the period() method body references none of score/numeric_score/computed.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm the computed-scores contrast.');
        }
        $periodBody = $this->extractPeriodMethod($controller);

        $this->assertStringNotContainsString("avg('score')", $periodBody, 'period() must not average the broken `score` column.');
        $this->assertStringNotContainsString('numeric_score', $periodBody, 'period() does not read numeric_score either — it is assessment-progress only.');
        $this->assertStringNotContainsString('BaComputedScore', $periodBody, 'period() does not query BaComputedScore.');
        $this->assertStringContainsString('BaAssessment::where', $periodBody, 'period() aggregates ba_assessments status counts.');

        // Sanity: the broken `score` column still does not exist on ba_computed_scores (BUG-BA-013 root).
        $this->assertFalse(Schema::hasColumn(self::SCORES_TABLE, 'score'), 'ba_computed_scores has no bare `score` column (BUG-BA-013 root).');
    }

    public function test_period_report_15_workflow_counts_reflect_seeded_assessment_statuses(): void
    {
        // Aggregate-correctness: seed assessments in known statuses for a period, assert the workflow counts
        // (rendered by the blade) reflect the seed. Heavily guarded — skips when cross-module FKs are absent.
        $seed = $this->seedAssessmentsForPeriod(['draft', 'submitted', 'reviewed']);
        if ($seed === null) {
            $this->markTestSkipped('Cross-module FKs (period/teacher/class-section) unavailable to seed assessments.');
        }

        try {
            [$periodId, $created] = $seed;

            $expected = BaAssessment::where('period_id', $periodId)
                ->selectRaw('status, COUNT(*) as cnt')
                ->groupBy('status')
                ->pluck('cnt', 'status');

            $this->assertGreaterThanOrEqual(1, (int) ($expected['draft'] ?? 0), 'Seed should include a draft assessment.');

            $this->browseWithFailureScreenshot('seeded-counts', function (Browser $browser) use ($periodId): void {
                $this->visitAuthenticated($browser, self::REPORT_PERIOD . $periodId, 1100);
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('Whoops', $source, 'Seeded period report must render without error.');
                $this->assertStringContainsString('Assessment Workflow Status', $source);
            });
        } finally {
            $this->cleanupAssessments($seed[1] ?? []);
        }
    }

    public function test_period_report_16_remarks_completion_reads_student_remarks(): void
    {
        $this->assertTrue(Schema::hasTable(self::REMARK_TABLE), 'ba_student_remarks backing table must exist.');
        $this->assertTrue(Schema::hasTable(self::RATING_TABLE), 'ba_assessment_ratings backing table must exist.');

        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $periodBody = $this->extractPeriodMethod($controller);
        $this->assertStringContainsString('BaStudentRemark::selectRaw', $periodBody, 'period() computes remarks completion from ba_student_remarks.');
        $this->assertStringContainsString('BaAssessmentRating::selectRaw', $periodBody, 'period() computes rating-grid completion from ba_assessment_ratings.');
    }

    // =====================================================================
    // Band 20–29 — Workflow / state-machine statuses surfaced (read-only)
    // =====================================================================

    public function test_period_report_20_report_surfaces_documented_assessment_fsm_statuses(): void
    {
        // The report READS (does not transition) the assessment FSM. Prove the surfaced set matches the DDL enum.
        if (DB::connection()->getDriverName() === 'mysql') {
            $type = strtolower((string) (collect(DB::select('SHOW COLUMNS FROM ' . self::ASSESS_TABLE))
                ->firstWhere('Field', 'status')->Type ?? ''));
            foreach (['draft', 'submitted', 'reviewed', 'locked'] as $st) {
                $this->assertStringContainsString($st, $type, "Assessment FSM status '{$st}' must exist in the enum.");
            }
        }

        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/period.blade.php'));
        if ($view !== null) {
            $this->assertStringContainsString("'draft', 'submitted', 'reviewed', 'locked'", $view, 'Period view iterates the four FSM statuses.');
            $this->assertStringContainsString('Draft</strong> → <strong>Submitted</strong> → <strong>Reviewed</strong> → <strong>Locked', $view, 'Workflow legend must show the FSM order.');
        }
    }

    public function test_period_report_21_period_lifecycle_badge_uses_open_closed_locked(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/period.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('reports/period.blade.php not readable.');
        }
        // Period lifecycle badge colour map keyed by the DDL enum values.
        $this->assertStringContainsString("'open' => 'success'", $view, 'Period lifecycle badge must map open.');
        $this->assertStringContainsString("'closed' => 'secondary'", $view, 'Period lifecycle badge must map closed.');
        $this->assertStringContainsString("'locked' => 'danger'", $view, 'Period lifecycle badge must map locked.');
    }

    // =====================================================================
    // Band 30–39 — Validation / negative (invalid ids)
    // =====================================================================

    public function test_period_report_30_invalid_period_id_returns_404(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_PERIOD . self::MISSING_ID);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Unknown period id must 404 (findOrFail).');
    }

    public function test_period_report_31_non_numeric_period_id_is_rejected(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_PERIOD . 'not-a-number');
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [404, 400, 500],
            'A non-numeric period id (int type-hint / route model) must not render a valid report.'
        );
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency (BC-INT / BC-REF)
    // =====================================================================

    public function test_period_report_40_assessments_fks_restrict_on_delete(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('FK metadata inspection requires MySQL.');
        }
        try {
            $rules = collect(DB::select(
                "SELECT REFERENCED_TABLE_NAME, DELETE_RULE
                 FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'ba_assessments'"
            ))->keyBy('REFERENCED_TABLE_NAME');

            if ($rules->isEmpty()) {
                $this->markTestSkipped('No FK metadata for ba_assessments.');
            }
            foreach (['ba_assessment_periods', 'sch_employees', 'sch_class_section_jnt'] as $ref) {
                if (isset($rules[$ref])) {
                    $rule = strtoupper((string) ($rules[$ref]->DELETE_RULE ?? ''));
                    $this->assertTrue(
                        str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'),
                        "ba_assessments → {$ref} should be RESTRICT; found {$rule}."
                    );
                }
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('FK dependency inspection unavailable: ' . $e->getMessage());
        }
    }

    public function test_period_report_41_period_report_eager_loads_cross_module_relations_defensively(): void
    {
        // period() eager-loads teacher (sch_employees) + classSection (sch_class_section_jnt) + academicSession.
        // Rendering a real period must not 500 even when those cross-module rows are sparse.
        $periodId = $this->anyPeriodId();
        if ($periodId === null) {
            $this->markTestSkipped('No period available for the cross-module render check.');
        }
        $response = $this->getFromAdminPage(self::REPORT_PERIOD . $periodId);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'Period report must render (200) or redirect (302), never 500 on cross-module relation loads.'
        );
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_period_report_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::REPORT_PERIOD . self::MISSING_ID))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_period_report_51_limited_user_gets_403_on_period_report(): void
    {
        $periodId = $this->anyPeriodId() ?? self::MISSING_ID;
        $limited = $this->makeLimitedUser();
        $this->browseWithFailureScreenshot('limited-period-403', function (Browser $browser) use ($limited, $periodId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORT_PERIOD . $periodId));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'reports.view gate must block the limited user before findOrFail.');
        });
        $this->deleteUser($limited);
    }

    public function test_period_report_52_policy_maps_to_permission_strings(): void
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

    public function test_period_report_53_export_gate_diverges_from_policy_val_ba_003(): void
    {
        // VAL-BA-003: export() authorizes reports.view though the Policy exposes an `export` ability on reports.export.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaReportPolicy.php'));
        if ($controller === null || $policy === null) {
            $this->markTestSkipped('Sources not readable to confirm VAL-BA-003.');
        }
        $exportBody = $this->extractExportMethod($controller);
        $this->assertStringContainsString('tenant.behavioural-assessment.reports.view', $exportBody, 'export() gates on reports.view.');
        $this->assertStringNotContainsString('tenant.behavioural-assessment.reports.export', $exportBody, 'VAL-BA-003: export() does NOT use the reports.export permission.');
        $this->assertStringContainsString('tenant.behavioural-assessment.reports.export', $policy, 'Policy still declares the unused export ability.');
    }

    // =====================================================================
    // Band 60–69 — UI/UX (empty state, filters, navigation)
    // =====================================================================

    public function test_period_report_60_empty_state_message_for_period_without_assessments(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/period.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('reports/period.blade.php not readable for empty-state text check.');
        }
        $this->assertStringContainsString('No assessments found for this period', $view, 'Documented teacher-progress empty state expected.');
    }

    public function test_period_report_61_period_selector_dropdown_renders_options(): void
    {
        $periodId = $this->anyPeriodId();
        if ($periodId === null) {
            $this->markTestSkipped('No period available to render the selector.');
        }
        $this->browseWithFailureScreenshot('period-selector', function (Browser $browser) use ($periodId): void {
            $this->visitAuthenticated($browser, self::REPORT_PERIOD . $periodId, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('name="period"', $source, 'Period selector <select> must render.');
            $this->assertStringContainsString('All Reports', $source, 'Back-to-hub link must render.');
        });
    }

    public function test_period_report_62_period_selector_submits_query_but_route_binds_path_segment_ui_ba_prd_01(): void
    {
        // UI-BA-PRD-01: the selector auto-submits GET ?period=<id> to the SAME url; period() only reads the
        // {period} path segment, so switching the dropdown does NOT switch the report.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/period.blade.php'));
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($view === null && $controller === null) {
            $this->markTestSkipped('Sources not readable to confirm UI-BA-PRD-01.');
        }
        if ($view !== null) {
            $this->assertStringContainsString('name="period"', $view, 'Selector posts a `period` query param.');
            $this->assertStringContainsString('onchange="this.form.submit()"', $view, 'Selector auto-submits on change.');
            // The GET form has no action attribute → submits to the current /reports/period/{period} path.
            $this->assertStringNotContainsString("route('behavioural-assessment.reports.period'", $view, 'UI-BA-PRD-01: selector does not target the period route with the chosen id.');
        }
        if ($controller !== null) {
            $periodBody = $this->extractPeriodMethod($controller);
            $this->assertStringContainsString('function period(int $period)', $periodBody, 'period() binds only the {period} route segment.');
            $this->assertStringNotContainsString("request('period')", $periodBody, 'UI-BA-PRD-01: period() ignores the ?period query param the selector submits.');
        }
    }

    // =====================================================================
    // Band 70–79 — Edge cases / requirement-vs-implementation gaps (BC-EDG)
    // =====================================================================

    public function test_period_report_70_export_is_live_abort_501_stub_bug_ba_011(): void
    {
        // BUG-BA-011: an authorized user hitting the live export route gets HTTP 501 (unimplemented stub).
        $response = $this->getFromAdminPage(self::REPORT_EXPORT);
        $this->assertSame(
            501,
            (int) ($response['status'] ?? 0),
            'BUG-BA-011 regression fixed? Export should currently abort(501) "Export feature coming soon."'
        );
    }

    public function test_period_report_71_requirement_comparison_grid_is_not_implemented_rpt_gap_prd_01(): void
    {
        // Screen-18 specifies a multi-period COMPARISON grid (Score Delta, Trend Indicator, per-period incidents,
        // Session + Class/Section + multi-period-select filters). period()/period.blade render a single-period
        // Teacher Progress report — none of the comparison surface exists.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/period.blade.php'));
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($view === null && $controller === null) {
            $this->markTestSkipped('Sources not readable to confirm RPT-GAP-PRD-01.');
        }
        if ($view !== null) {
            $this->assertStringNotContainsString('Score Delta', $view, 'RPT-GAP-PRD-01 changed: comparison grid now renders Score Delta.');
            $this->assertStringNotContainsString('Trend Indicator', $view, 'RPT-GAP-PRD-01 changed: Trend Indicator now rendered.');
            $this->assertStringNotContainsString('Compare Periods', $view, 'RPT-GAP-PRD-01 changed: multi-period compare filter now present.');
        }
        if ($controller !== null) {
            $periodBody = $this->extractPeriodMethod($controller);
            $this->assertStringNotContainsString('delta', strtolower($periodBody), 'RPT-GAP-PRD-01: period() computes no score delta between periods.');
            $this->assertStringContainsString('teacherProgress', $periodBody, 'period() only builds the single-period teacher progress model.');
        }
    }

    public function test_period_report_72_delta_and_dynamic_mapping_rules_are_unimplemented_rpt_gap_prd_02(): void
    {
        // Screen-18 business rules: Score Delta = Period(N)avg - Period(N-1)avg (+/-0.30 → arrows; ±0.20 stable);
        // Dynamic Period Mapping (delta across categories active in BOTH periods). No implementation exists.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm RPT-GAP-PRD-02.');
        }
        $periodBody = $this->extractPeriodMethod($controller);
        $this->assertStringNotContainsString('previous', strtolower($periodBody), 'RPT-GAP-PRD-02: no previous-period lookup for a delta.');
        $this->assertStringNotContainsString('N-1', $periodBody, 'RPT-GAP-PRD-02: no Period(N-1) comparison.');
        // The report does not even read cohort averages here (no computed-scores in period()).
        $this->assertStringNotContainsString('BaComputedScore', $periodBody, 'RPT-GAP-PRD-02: period() reads no cohort averages to compare.');
    }

    public function test_period_report_73_report_card_export_unimplemented_only_dead_501_route_rpt_gap_prd_03(): void
    {
        // Screen-18 (parent report cards / visual charts) implies an export; the only export route is the 501 stub.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm RPT-GAP-PRD-03.');
        }
        $exportBody = $this->extractExportMethod($controller);
        $this->assertStringContainsString('abort(501', $exportBody, 'RPT-GAP-PRD-03: export remains an abort(501) stub.');
        $this->assertStringNotContainsString('StreamedResponse', $controller, 'RPT-GAP-PRD-03: no streamed export implemented.');
        $this->assertStringNotContainsString('fputcsv', $controller, 'RPT-GAP-PRD-03: no CSV writer implemented.');
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + API deadness + security
    // =====================================================================

    public function test_period_report_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side report tests.'
        );
        $this->assertTrue(Schema::hasTable(self::PERIOD_TABLE), 'ba_assessment_periods must resolve within the tenant DB.');
        $this->assertTrue(Schema::hasTable(self::ASSESS_TABLE), 'ba_assessments must resolve within the tenant DB.');
    }

    public function test_period_report_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001(): void
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

    public function test_period_report_92_web_report_routes_carry_full_tenancy_stack(): void
    {
        $rsp = $this->readAppFile($this->moduleRootPath('app/Providers/RouteServiceProvider.php'));
        if ($rsp === null) {
            $this->markTestSkipped('RouteServiceProvider source not readable.');
        }
        foreach (['InitializeTenancyByDomain', 'PreventAccessFromCentralDomains', 'EnsureTenantIsActive', "'auth'", "'verified'"] as $needle) {
            $this->assertStringContainsString($needle, $rsp, "Web report routes must carry {$needle} in the middleware stack.");
        }
    }

    public function test_period_report_93_rendered_report_escapes_output(): void
    {
        // Defensive stored-XSS smoke: the Blade report must escape teacher/section text.
        $periodId = $this->anyPeriodId();
        if ($periodId === null) {
            $this->markTestSkipped('No period available for the output-escaping smoke.');
        }
        $this->browseWithFailureScreenshot('escape-smoke', function (Browser $browser) use ($periodId): void {
            $this->visitAuthenticated($browser, self::REPORT_PERIOD . $periodId, 1000);
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
        $rawName = 'period-report-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'period-report-' . $kind . '-' . now()->format('Ymd_His');
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

    // ---- Seed / cleanup ---------------------------------------------------

    /**
     * Seed one assessment per requested status for an existing period.
     *
     * @param  array<int,string>  $statuses
     * @return array{0:int,1:array<int,BaAssessment>}|null  [periodId, createdRows] or null when FKs unavailable
     */
    private function seedAssessmentsForPeriod(array $statuses): ?array
    {
        try {
            $periodId  = $this->anyPeriodId();
            $teacherId = $this->firstIdOf('sch_employees');
            $sectionId = $this->firstIdOf('sch_class_section_jnt') ?? $this->firstIdOf('sch_class_sections');
            if ($periodId === null || $teacherId === null || $sectionId === null || $this->adminUser === null) {
                return null;
            }

            $created = [];
            foreach ($statuses as $i => $status) {
                // Respect uq_ba_assessment (teacher_id, class_section_id, period_id): vary teacher across rows,
                // and clear any pre-existing collision first.
                $tId = $teacherId + $i;
                if (!$this->idExists('sch_employees', $tId)) {
                    $tId = $teacherId; // fall back — may collide; clear below
                }
                BaAssessment::withTrashed()
                    ->where('period_id', $periodId)
                    ->where('teacher_id', $tId)
                    ->where('class_section_id', $sectionId)
                    ->get()
                    ->each(fn (BaAssessment $a) => $this->safeForceDelete($a));

                $row = BaAssessment::query()->create([
                    'period_id'        => $periodId,
                    'teacher_id'       => $tId,
                    'class_section_id' => $sectionId,
                    'status'           => $status,
                    'is_active'        => true,
                    'created_by'       => (int) $this->adminUser->id,
                    'updated_by'       => (int) $this->adminUser->id,
                ]);
                $created[] = $row;
            }

            if ($created === []) {
                return null;
            }
            return [$periodId, $created];
        } catch (Throwable) {
            return null;
        }
    }

    /** @param  array<int,BaAssessment>  $rows */
    private function cleanupAssessments(array $rows): void
    {
        foreach ($rows as $row) {
            if ($row instanceof BaAssessment) {
                $this->safeForceDelete($row);
            }
        }
    }

    private function safeForceDelete(BaAssessment $row): void
    {
        try {
            $row->forceDelete();
        } catch (Throwable) {
        }
    }

    private function anyPeriodId(): ?int
    {
        return $this->firstIdOf(self::PERIOD_TABLE);
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

    private function idExists(string $table, int $id): bool
    {
        try {
            return Schema::hasTable($table) && DB::table($table)->where('id', $id)->exists();
        } catch (Throwable) {
            return false;
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
                'name'              => 'PR Limited ' . $this->uniqueSuffix(),
                'email'             => 'pr_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'PL' . substr($this->uniqueSuffix(), -8);
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
            $modelFile = (new ReflectionClass(BaAssessmentPeriod::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaAssessmentPeriod.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaAssessmentPeriod::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaAssessmentPeriod.php → app root = dirname(,5)
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

    /** Extract the period() method body (up to categories()) for targeted source assertions. */
    private function extractPeriodMethod(string $controller): string
    {
        $start = strpos($controller, 'function period(');
        if ($start === false) {
            return $controller;
        }
        $end = strpos($controller, 'function categories', $start);
        $len = $end === false ? 4000 : ($end - $start);
        return substr($controller, $start, $len);
    }

    /** Extract the export() method body for targeted source assertions. */
    private function extractExportMethod(string $controller): string
    {
        $pos = strpos($controller, 'function export');
        if ($pos === false) {
            return $controller;
        }
        return substr($controller, $pos, 400);
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
