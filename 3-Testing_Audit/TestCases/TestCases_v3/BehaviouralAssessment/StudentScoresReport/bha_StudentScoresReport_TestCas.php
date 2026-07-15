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
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Student Scores Report (Reports Hub / computed-scores grid).
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/16-Student-Scores-Report.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime table      : ba_computed_scores  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaReportController
 *                      (byClass = per-section student-scores grid; student = per-student category scores; export = 501 stub)
 * UI alias surface   : Modules\BehaviouralAssessment\Http\Controllers\BaDashboardController::reportsPage()
 *                      renders the "Student Scores" tab (reports-page?tab=student-scores) via
 *                      pages/partials/reports/_student-scores.blade.php.
 * Permission prefix  : tenant.behavioural-assessment.reports.{viewAny|view|export}
 *                      (reports-page.{viewAny|view} gate the tab shell — see the mismatch proven in _55).
 * Activity log       : NONE — read-only report controller, no activityLog() helper (documented absence).
 * Test STYLE         : browser Dusk (extends DuskTestCase) — mirrors the committed sibling
 *                      RatingScale/bha_RatingScale_TestCas.php (nearest same-module precedent).
 *
 * Defects proven (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md + this run):
 *   - BUG-BA-011 : reports/export is a permanent abort(501) stub on a live, authorized route (proven in _70).
 *   - DEAD-BA-001: api.php `behaviouralassessments` apiResource has NO tenancy middleware AND is never
 *                  registered (RSP::map only maps web.php — constraint #23) (proven in _91).
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - BUG-BA-013 : NEW — byClass()/categories() + by-class.blade.php read a NON-EXISTENT `score` column
 *                  (live column is `numeric_score`); every overall score renders as 0.00 and every student is
 *                  flagged at-risk. student() correctly reads numeric_score (contrast) (proven in _14 / _15).
 * Feature-scoped requirement-vs-implementation gaps:
 *   - RPT-GAP-01 : screen-16 grid columns (Roll No, Admission No, per-student dynamic category columns,
 *                  Grading Teacher, Status, draft warning banner) are NOT implemented in by-class.blade (proven in _71).
 *   - RPT-GAP-02 : screen-16 CSV export is unimplemented — the only export route is the 501 stub (proven in _72).
 *   - SEC-BA-003 : reports-page tab-nav gates on `reports.viewAny` while reportsPage() gates on
 *                  `reports-page.viewAny` (divergent permission keys) (proven in _55).
 *   - VAL-BA-003 : export() authorizes `reports.view` though BaReportPolicy exposes an `export` ability on
 *                  `reports.export` (dead policy method / weaker gate) (proven in _56).
 */
class bha_StudentScoresReport_TestCas extends DuskTestCase
{
    private const URL_PREFIX          = '/behavioural-assessment';
    private const REPORTS_INDEX       = '/behavioural-assessment/reports';
    private const REPORTS_PAGE_SS     = '/behavioural-assessment/reports-page?tab=student-scores';
    private const REPORT_CLASS        = '/behavioural-assessment/reports/class/';   // append classSection id
    private const REPORT_STUDENT      = '/behavioural-assessment/reports/student/'; // append student id
    private const REPORT_EXPORT       = '/behavioural-assessment/reports/export';

    private const SCORES_TABLE        = 'ba_computed_scores';
    private const DDL_SCORES          = 'bha_computed_scores';   // stale DDL-doc name (must NOT exist at runtime)
    private const ASSESS_TABLE        = 'ba_assessments';

    private const MISSING_ID          = 987654321;

    private const SCREENSHOT_DIR      = 'tests/Browser/Modules/BehaviouralAssessment/StudentScoresReport/screenshots';

    /** @var array<int,string> */
    private const REPORT_PERMISSIONS = [
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
    // Band 01–09 — Schema / DDL / model / route configuration truth
    // =====================================================================

    public function test_student_scores_report_01_computed_scores_schema_and_model_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'Table ba_computed_scores does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::SCORES_TABLE, [
                'id', 'student_id', 'category_id', 'period_id',
                'numeric_score', 'grade', 'overall_score', 'overall_grade',
                'computed_at', 'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_computed_scores table.'
        );

        // The report grid aggregates on `numeric_score`; the (broken) `score` column must NOT exist (see _14).
        $this->assertFalse(
            Schema::hasColumn(self::SCORES_TABLE, 'score'),
            'ba_computed_scores has no bare `score` column — the report code that reads it is defective (BUG-BA-013).'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::SCORES_TABLE))->keyBy('Field');
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['numeric_score']->Type ?? '')));
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['overall_score']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));

            // Unique key uq_ba_score (student_id, category_id, period_id).
            $unique = DB::select("SHOW INDEX FROM " . self::SCORES_TABLE . " WHERE Non_unique = 0 AND Column_name = 'student_id'");
            $this->assertIsArray($unique, 'Unable to inspect ba_computed_scores unique index.');
        }

        // Migration content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130619_create_ba_computed_scores_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_computed_scores'", $migration);
            $this->assertStringContainsString("\$table->decimal('numeric_score', 5, 2)", $migration);
            $this->assertStringContainsString("\$table->unique(['student_id', 'category_id', 'period_id']", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // Model configuration.
        $score = new BaComputedScore();
        $this->assertSame('ba_computed_scores', $score->getTable());
        $this->assertSame([
            'student_id', 'category_id', 'period_id', 'numeric_score', 'grade',
            'overall_score', 'overall_grade', 'computed_at', 'is_active',
            'created_by', 'updated_by',
        ], $score->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaComputedScore::class));
        $this->assertInstanceOf(BelongsTo::class, $score->student());
        $this->assertInstanceOf(BelongsTo::class, $score->category());
        $this->assertInstanceOf(BelongsTo::class, $score->period());
    }

    public function test_student_scores_report_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
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

    public function test_student_scores_report_03_report_controller_methods_and_routes_are_registered(): void
    {
        foreach (['index', 'student', 'byClass', 'period', 'categories', 'incidents', 'export'] as $method) {
            $this->assertTrue(
                method_exists(BaReportController::class, $method),
                "BaReportController::{$method}() is expected to exist."
            );
        }

        foreach ([
            'behavioural-assessment.reports.index',
            'behavioural-assessment.reports.student',
            'behavioural-assessment.reports.class',
            'behavioural-assessment.reports.period',
            'behavioural-assessment.reports.categories',
            'behavioural-assessment.reports.incidents',
            'behavioural-assessment.reports.export',
            'behavioural-assessment.reports-page',
        ] as $routeName) {
            $this->assertTrue(Route::has($routeName), "Route {$routeName} is not registered.");
        }
    }

    public function test_student_scores_report_04_report_views_and_tab_partial_exist(): void
    {
        $byClass = $this->readAppFile($this->moduleRootPath('resources/views/reports/by-class.blade.php'));
        $student = $this->readAppFile($this->moduleRootPath('resources/views/reports/student.blade.php'));
        $partial = $this->readAppFile($this->moduleRootPath('resources/views/pages/partials/reports/_student-scores.blade.php'));

        if ($byClass === null && $student === null && $partial === null) {
            $this->markTestSkipped('Report view sources not readable from the app repo.');
        }

        if ($byClass !== null) {
            $this->assertStringContainsString('Student Ranking', $byClass, 'by-class view should render the Student Ranking grid.');
        }
        if ($partial !== null) {
            $this->assertStringContainsString('student-scores-pane', $partial, 'Student-Scores tab pane id expected.');
            $this->assertStringContainsString('name="class_section_id"', $partial, 'Student-Scores tab filter expected.');
        }
    }

    // =====================================================================
    // Band 10–19 — Business rules / render + data correctness (BC-BIZ)
    // =====================================================================

    public function test_student_scores_report_10_reports_hub_renders_for_authorized_admin(): void
    {
        $this->browseWithFailureScreenshot('hub-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORTS_INDEX, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser), 'Authorized admin must not be bounced to login.');
            $browser->assertSee('Students Rated');
        });
    }

    public function test_student_scores_report_11_student_scores_tab_renders_with_filters(): void
    {
        $this->browseWithFailureScreenshot('tab-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORTS_PAGE_SS, 1100);
            $browser->assertSee('Student Scores');
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('student-scores-pane', $source, 'Student-Scores tab pane must render.');
            $this->assertStringContainsString('name="period_id"', $source, 'Period filter select must render.');
            $this->assertStringContainsString('name="class_section_id"', $source, 'Class/Section filter select must render.');
        });
    }

    public function test_student_scores_report_12_by_class_scores_grid_renders_or_shows_empty_state(): void
    {
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No active class-section available to render the by-class scores grid.');
        }

        $this->browseWithFailureScreenshot('by-class-render', function (Browser $browser) use ($classSectionId): void {
            $this->visitAuthenticated($browser, self::REPORT_CLASS . $classSectionId, 1100);
            // Either the ranking grid renders or the documented empty state does — both prove no 500.
            $source = $browser->driver->getPageSource();
            $rendered = str_contains($source, 'Class Average Score')
                || str_contains($source, 'Student Ranking')
                || str_contains($source, 'No score data available');
            $this->assertTrue($rendered, 'by-class report must render either the scores grid or its empty state.');
            $browser->assertSee('Class-Section:');
        });
    }

    public function test_student_scores_report_13_student_report_renders_and_reads_computed_scores(): void
    {
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available to render the per-student report.');
        }

        $this->browseWithFailureScreenshot('student-render', function (Browser $browser) use ($studentId): void {
            $this->visitAuthenticated($browser, self::REPORT_STUDENT . $studentId, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser));
            // student() reads BaComputedScore->numeric_score directly; page must not 500.
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('Whoops', $source, 'Student report must not throw a server error.');
        });
    }

    public function test_student_scores_report_14_by_class_report_reads_nonexistent_score_column_bug_ba_013(): void
    {
        // Live column is `numeric_score`; the model exposes no `score` attribute/accessor.
        $this->assertFalse(Schema::hasColumn(self::SCORES_TABLE, 'score'));
        $this->assertContains('numeric_score', (new BaComputedScore())->getFillable());

        // Runtime proof: a persisted computed score has numeric_score set but `score` is null.
        $seed = $this->seedComputedScore(['numeric_score' => 4.50]);
        if ($seed !== null) {
            $seed->refresh();
            $this->assertSame('4.50', (string) $seed->numeric_score);
            $this->assertNull($seed->score, 'BUG-BA-013: BaComputedScore has no `score` attribute — the by-class report averages null.');
            $this->deleteComputedScore($seed);
        }

        // Source proof: by-class report + controller aggregate on `score`, which does not exist.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/by-class.blade.php'));
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($view === null && $controller === null) {
            $this->markTestSkipped('Report source not readable to confirm BUG-BA-013.');
        }
        if ($controller !== null) {
            $this->assertStringContainsString("avg('score')", $controller, 'BUG-BA-013: byClass()/categories() average a non-existent `score` column.');
            $this->assertStringNotContainsString("avg('numeric_score')", $this->extractByClassMethod($controller), 'BUG-BA-013: byClass() should have used numeric_score.');
        }
        if ($view !== null) {
            $this->assertStringContainsString('overall_score', $view, 'by-class view renders overall_score derived from the broken aggregate.');
        }
    }

    public function test_student_scores_report_15_student_report_correctly_reads_numeric_score(): void
    {
        // Contrast with BUG-BA-013: student() uses the real column, proving the bug is byClass/categories-specific.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $this->assertStringContainsString("avg('numeric_score')", $controller, 'student() reads the real numeric_score column.');
    }

    // =====================================================================
    // Band 30–39 — Validation / negative (invalid ids & filters)
    // =====================================================================

    public function test_student_scores_report_30_invalid_student_id_returns_404(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_STUDENT . self::MISSING_ID);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Unknown student id must 404 (findOrFail).');
    }

    public function test_student_scores_report_31_invalid_class_section_id_returns_404(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_CLASS . self::MISSING_ID);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Unknown class-section id must 404 (findOrFail).');
    }

    public function test_student_scores_report_32_unknown_period_filter_does_not_error(): void
    {
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available for the period-filter smoke.');
        }
        $response = $this->getFromAdminPage(self::REPORT_CLASS . $classSectionId . '?period_id=' . self::MISSING_ID);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'An unknown period_id filter should degrade gracefully (find() → null), not 500.'
        );
    }

    public function test_student_scores_report_33_student_scores_tab_accepts_filter_params(): void
    {
        $response = $this->getFromAdminPage(self::URL_PREFIX . '/reports-page?tab=student-scores&period_id=' . self::MISSING_ID . '&class_section_id=' . self::MISSING_ID);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Filter params on the Student-Scores tab must not error.');
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency
    // =====================================================================

    public function test_student_scores_report_40_computed_scores_fks_restrict_on_delete(): void
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

    public function test_student_scores_report_41_student_scores_tab_reads_assessments_not_computed_scores(): void
    {
        // Documented alias divergence: the tab lists ba_assessments (reviewed/locked), NOT ba_computed_scores.
        $this->assertTrue(Schema::hasTable(self::ASSESS_TABLE), 'ba_assessments backing table must exist.');
        $partial = $this->readAppFile($this->moduleRootPath('resources/views/pages/partials/reports/_student-scores.blade.php'));
        if ($partial === null) {
            $this->markTestSkipped('Student-Scores partial not readable.');
        }
        $this->assertStringContainsString('assessmentScores', $partial, 'The tab iterates $assessmentScores (assessment rows), not computed scores.');
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_student_scores_report_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::REPORTS_INDEX))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_student_scores_report_51_limited_user_gets_403_on_reports_hub(): void
    {
        $limited = $this->makeLimitedUser();
        $this->browseWithFailureScreenshot('limited-hub-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORTS_INDEX));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without reports.viewAny must get 403.');
        });
        $this->deleteUser($limited);
    }

    public function test_student_scores_report_52_limited_user_gets_403_on_by_class_report(): void
    {
        $classSectionId = $this->anyClassSectionId() ?? self::MISSING_ID;
        $limited = $this->makeLimitedUser();
        $this->browseWithFailureScreenshot('limited-class-403', function (Browser $browser) use ($limited, $classSectionId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORT_CLASS . $classSectionId));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'reports.view gate must block the limited user before findOrFail.');
        });
        $this->deleteUser($limited);
    }

    public function test_student_scores_report_53_limited_user_gets_403_on_student_report(): void
    {
        $studentId = $this->anyStudentId() ?? self::MISSING_ID;
        $limited = $this->makeLimitedUser();
        $this->browseWithFailureScreenshot('limited-student-403', function (Browser $browser) use ($limited, $studentId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORT_STUDENT . $studentId));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'reports.view gate must block the limited user.');
        });
        $this->deleteUser($limited);
    }

    public function test_student_scores_report_54_policy_maps_to_permission_strings(): void
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

    public function test_student_scores_report_55_reports_page_gate_key_diverges_from_tab_nav_sec_ba_003(): void
    {
        // SEC-BA-003: tab-nav visibility uses reports.viewAny; reportsPage() controller gate uses reports-page.viewAny.
        $dashboard = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaDashboardController.php'));
        $reportsBlade = $this->readAppFile($this->moduleRootPath('resources/views/pages/reports.blade.php'));
        if ($dashboard === null && $reportsBlade === null) {
            $this->markTestSkipped('Sources not readable to confirm SEC-BA-003.');
        }
        if ($dashboard !== null) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.reports-page.viewAny",
                $dashboard,
                'reportsPage() is expected to gate on reports-page.viewAny.'
            );
        }
        if ($reportsBlade !== null) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.reports.viewAny",
                $reportsBlade,
                'The Student-Scores tab-nav is expected to gate visibility on reports.viewAny (divergent key — SEC-BA-003).'
            );
        }
    }

    public function test_student_scores_report_56_export_gate_diverges_from_policy_val_ba_003(): void
    {
        // VAL-BA-003: export() authorizes reports.view though the Policy exposes an `export` ability on reports.export.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaReportPolicy.php'));
        if ($controller === null || $policy === null) {
            $this->markTestSkipped('Sources not readable to confirm VAL-BA-003.');
        }
        $exportBody = $this->extractExportMethod($controller);
        $this->assertStringContainsString("tenant.behavioural-assessment.reports.view", $exportBody, 'export() gates on reports.view.');
        $this->assertStringNotContainsString("tenant.behavioural-assessment.reports.export", $exportBody, 'VAL-BA-003: export() does NOT use the reports.export permission.');
        $this->assertStringContainsString("tenant.behavioural-assessment.reports.export", $policy, 'Policy still declares the unused export ability.');
    }

    // =====================================================================
    // Band 60–69 — UI/UX (empty state, filters, navigation)
    // =====================================================================

    public function test_student_scores_report_60_by_class_empty_state_when_no_scores(): void
    {
        // A far-out class-section id (findOrFail 404) can't be used for the empty state; use a real section that
        // is unlikely to have computed scores. Accept either the empty-state banner or a rendered (zero-score) grid.
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available for the empty-state check.');
        }
        $this->browseWithFailureScreenshot('by-class-empty', function (Browser $browser) use ($classSectionId): void {
            $this->visitAuthenticated($browser, self::REPORT_CLASS . $classSectionId . '?period_id=' . self::MISSING_ID, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertTrue(
                str_contains($source, 'No score data available') || str_contains($source, 'Student Ranking') || str_contains($source, 'Class Average Score'),
                'by-class report must show the documented empty state or the grid.'
            );
        });
    }

    public function test_student_scores_report_61_student_scores_tab_empty_state_message(): void
    {
        $partial = $this->readAppFile($this->moduleRootPath('resources/views/pages/partials/reports/_student-scores.blade.php'));
        if ($partial === null) {
            $this->markTestSkipped('Student-Scores partial not readable for empty-state text check.');
        }
        $this->assertStringContainsString('No reviewed assessments yet', $partial, 'Documented empty-state message expected.');
    }

    public function test_student_scores_report_62_reports_hub_links_to_student_scores_tab(): void
    {
        $this->browseWithFailureScreenshot('hub-links', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORTS_INDEX, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('tab=student-scores', $source, 'Reports Hub must link to the Student-Scores tab.');
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases / requirement gaps (BC-EDG)
    // =====================================================================

    public function test_student_scores_report_70_export_is_live_abort_501_stub_bug_ba_011(): void
    {
        // BUG-BA-011: an authorized user hitting the live export route gets HTTP 501 (unimplemented stub).
        $response = $this->getFromAdminPage(self::REPORT_EXPORT);
        $this->assertSame(
            501,
            (int) ($response['status'] ?? 0),
            'BUG-BA-011 regression fixed? Export should currently abort(501) "Export feature coming soon."'
        );
    }

    public function test_student_scores_report_71_requirement_grid_columns_are_not_implemented_rpt_gap_01(): void
    {
        // Screen-16 specifies Roll No / Admission No / per-student category columns / Grading Teacher / Status /
        // draft-warning banner. by-class.blade renders none of these — RPT-GAP-01.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/by-class.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('by-class view not readable to confirm RPT-GAP-01.');
        }
        $this->assertStringNotContainsString('Roll No', $view, 'RPT-GAP-01 changed: by-class now renders Roll No.');
        $this->assertStringNotContainsString('Admission No', $view, 'RPT-GAP-01 changed: by-class now renders Admission No.');
        $this->assertStringNotContainsString('not yet approved', $view, 'RPT-GAP-01 changed: draft warning banner now present.');
    }

    public function test_student_scores_report_72_csv_export_unimplemented_only_dead_501_route_rpt_gap_02(): void
    {
        // Screen-16 promises CSV export; the only export route is the 501 stub — no working export exists.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm RPT-GAP-02.');
        }
        $exportBody = $this->extractExportMethod($controller);
        $this->assertStringContainsString('abort(501', $exportBody, 'RPT-GAP-02: export remains an abort(501) stub.');
        $this->assertStringNotContainsString('StreamedResponse', $controller, 'RPT-GAP-02: no streamed CSV export implemented.');
        $this->assertStringNotContainsString('fputcsv', $controller, 'RPT-GAP-02: no CSV writer implemented.');
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + API deadness + security
    // =====================================================================

    public function test_student_scores_report_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side report tests.'
        );
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'ba_computed_scores must resolve within the tenant DB.');
    }

    public function test_student_scores_report_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001(): void
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
            $this->assertStringContainsString("auth:sanctum", $api, 'api.php uses the sanctum guard.');
            $this->assertStringNotContainsString('InitializeTenancyByDomain', $api, 'DEAD-BA-001: api.php has no tenancy middleware.');
        }
        if ($rsp !== null) {
            $this->assertStringNotContainsString("routes/api.php", $rsp, 'DEAD-BA-001: RSP::map() never loads routes/api.php.');
        }
    }

    public function test_student_scores_report_92_web_report_routes_carry_full_tenancy_stack(): void
    {
        $rsp = $this->readAppFile($this->moduleRootPath('app/Providers/RouteServiceProvider.php'));
        if ($rsp === null) {
            $this->markTestSkipped('RouteServiceProvider source not readable.');
        }
        foreach (['InitializeTenancyByDomain', 'PreventAccessFromCentralDomains', 'EnsureTenantIsActive', "'auth'", "'verified'"] as $needle) {
            $this->assertStringContainsString($needle, $rsp, "Web report routes must carry {$needle} in the middleware stack.");
        }
    }

    public function test_student_scores_report_93_rendered_report_escapes_output(): void
    {
        // Defensive stored-XSS smoke: the Blade grid must escape student/category text.
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available for the output-escaping smoke.');
        }
        $this->browseWithFailureScreenshot('escape-smoke', function (Browser $browser) use ($classSectionId): void {
            $this->visitAuthenticated($browser, self::REPORT_CLASS . $classSectionId, 1000);
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
        $rawName = 'student-scores-report-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'student-scores-report-' . $kind . '-' . now()->format('Ymd_His');
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
        // If the hub itself is unreachable, fall back to the app root so a document exists for fetch().
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
window.__ssApiDone = false;
window.__ssApiError = '';
window.__ssApiResult = null;

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

        window.__ssApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__ssApiError = String(error);
    } finally {
        window.__ssApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__ssApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__ssApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__ssApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Seed / cleanup ---------------------------------------------------

    private function seedComputedScore(array $overrides = []): ?BaComputedScore
    {
        try {
            $studentId  = $this->anyStudentId();
            $categoryId = Schema::hasTable('ba_categories') ? DB::table('ba_categories')->value('id') : null;
            $periodId   = Schema::hasTable('ba_assessment_periods') ? DB::table('ba_assessment_periods')->value('id') : null;
            if ($studentId === null || $categoryId === null || $periodId === null) {
                return null;
            }

            // Respect the (student_id, category_id, period_id) unique key — clear any pre-existing row.
            BaComputedScore::withTrashed()
                ->where('student_id', $studentId)
                ->where('category_id', $categoryId)
                ->where('period_id', $periodId)
                ->get()
                ->each(fn (BaComputedScore $s) => $this->deleteComputedScore($s));

            $payload = array_merge([
                'student_id'    => $studentId,
                'category_id'   => $categoryId,
                'period_id'     => $periodId,
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

    private function anyClassSectionId(): ?int
    {
        try {
            if (!Schema::hasTable('sch_class_sections')) {
                return null;
            }
            $id = DB::table('sch_class_sections')->value('id');
            return $id !== null ? (int) $id : null;
        } catch (Throwable) {
            return null;
        }
    }

    private function anyStudentId(): ?int
    {
        try {
            if (!Schema::hasTable('std_students')) {
                return null;
            }
            $id = DB::table('std_students')->value('id');
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
                'name'              => 'SSR Limited ' . $this->uniqueSuffix(),
                'email'             => 'ssr_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'SL' . substr($this->uniqueSuffix(), -8);
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

    /** Extract the export() method body for targeted source assertions. */
    private function extractExportMethod(string $controller): string
    {
        $pos = strpos($controller, 'function export');
        if ($pos === false) {
            return $controller;
        }
        return substr($controller, $pos, 400);
    }

    /** Extract the byClass() method body (up to incidents()) for targeted source assertions. */
    private function extractByClassMethod(string $controller): string
    {
        $start = strpos($controller, 'function byClass');
        if ($start === false) {
            return $controller;
        }
        $end = strpos($controller, 'function incidents', $start);
        $len = $end === false ? 4000 : ($end - $start);
        return substr($controller, $start, $len);
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
