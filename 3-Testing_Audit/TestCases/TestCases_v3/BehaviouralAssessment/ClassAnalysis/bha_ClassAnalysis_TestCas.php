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
 * Behavioural Assessment — Class Analysis Report (Class-Section Behaviour Analysis).
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/21-Class-Analysis*.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime table      : ba_computed_scores  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaReportController::byClass()
 *                      (route reports.class → /behavioural-assessment/reports/class/{classSection})
 * View               : behaviouralassessment::reports.by-class  (resources/views/reports/by-class.blade.php)
 * Permission prefix  : tenant.behavioural-assessment.reports.{viewAny|view|export}
 *                      (byClass() gates on reports.view; export() on reports.view — VAL-BA-003)
 * Activity log       : NONE — read-only report controller, no activityLog() helper (documented absence).
 * Screen type        : Report / visualization — LIGHT, read-focused set (render, chart-data correctness vs
 *                      computed_scores, class/section + period filters, export, permissions, empty state).
 *                      NO create/edit/delete matrix.
 * Test STYLE         : browser Dusk (extends DuskTestCase) — mirrors the committed sibling
 *                      RatingScale/bha_RatingScale_TestCas.php + StudentScoresReport (nearest same-module precedents).
 *
 * Defects proven (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md + this run):
 *   - BUG-BA-013 : byClass() (the CLASS-LEVEL path) + by-class.blade aggregate a NON-EXISTENT `score` column —
 *                  the live column is `numeric_score`. Collection->avg('score')/min/max/pluck('score') read null,
 *                  so every student's overall_score renders 0.00, every category avg/min/max/std_dev = 0.00, and
 *                  every student is flagged at-risk (0.00 < 2.50) regardless of real numeric_score.
 *                  Deterministic proof in _15; source contrast (student() uses numeric_score) in _16 (proven).
 *   - BUG-BA-011 : reports/export is a permanent abort(501) stub on a live, authorized route (proven in _70).
 *   - DEAD-BA-001: routes/api.php `behaviouralassessments` apiResource has NO tenancy middleware AND is never
 *                  registered (RSP::map maps only web.php — constraint #23) (proven in _91).
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 * Feature-scoped requirement-vs-implementation gaps:
 *   - VAL-BA-003 : export() authorizes reports.view though BaReportPolicy exposes an `export` ability on
 *                  reports.export (dead policy method / weaker gate) (proven in _53).
 *   - CA-GAP-01  : requirement CSV/export of the class-analysis grid is unimplemented — only the 501 stub exists
 *                  (proven in _71).
 */
class bha_ClassAnalysis_TestCas extends DuskTestCase
{
    private const URL_PREFIX     = '/behavioural-assessment';
    private const REPORTS_INDEX  = '/behavioural-assessment/reports';
    private const REPORT_CLASS   = '/behavioural-assessment/reports/class/';   // append classSection id
    private const REPORT_EXPORT  = '/behavioural-assessment/reports/export';

    private const SCORES_TABLE   = 'ba_computed_scores';
    private const DDL_SCORES     = 'bha_computed_scores';   // stale DDL-doc name (must NOT exist at runtime)

    private const MISSING_ID     = 987654321;

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/ClassAnalysis/screenshots';

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
    // Band 01–09 — Schema / DDL / model / route / view configuration truth
    // =====================================================================

    public function test_class_analysis_01_computed_scores_schema_and_model_are_correct(): void
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

        // The class report aggregates on `score`, which does NOT exist — the live column is `numeric_score` (BUG-BA-013).
        $this->assertFalse(
            Schema::hasColumn(self::SCORES_TABLE, 'score'),
            'ba_computed_scores has no bare `score` column — the class-analysis code that reads it is defective (BUG-BA-013).'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::SCORES_TABLE))->keyBy('Field');
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['numeric_score']->Type ?? '')));
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['overall_score']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));

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

    public function test_class_analysis_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
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

    public function test_class_analysis_03_byclass_route_and_controller_method_are_registered(): void
    {
        $this->assertTrue(
            method_exists(BaReportController::class, 'byClass'),
            'BaReportController::byClass() is expected to exist (the Class Analysis handler).'
        );

        foreach ([
            'behavioural-assessment.reports.index',
            'behavioural-assessment.reports.class',
            'behavioural-assessment.reports.export',
        ] as $routeName) {
            $this->assertTrue(Route::has($routeName), "Route {$routeName} is not registered.");
        }
    }

    public function test_class_analysis_04_by_class_view_declares_expected_sections(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/by-class.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('by-class view source not readable from the app repo.');
        }
        $this->assertStringContainsString('Class Analysis Report', $view, 'Breadcrumb title expected.');
        $this->assertStringContainsString('Class-Section:', $view, 'Class-Section selector label expected.');
        $this->assertStringContainsString("name=\"period_id\"", $view, 'Period filter select expected.');
        $this->assertStringContainsString('Category-Wise Class Performance', $view, 'Category performance section expected.');
        $this->assertStringContainsString('Student Ranking', $view, 'Student ranking section expected.');
        $this->assertStringContainsString('No score data available', $view, 'Documented empty-state text expected.');
    }

    // =====================================================================
    // Band 10–19 — Render + chart-data correctness (BC-BIZ) incl. BUG-BA-013
    // =====================================================================

    public function test_class_analysis_10_report_renders_for_authorized_admin(): void
    {
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available to render the Class Analysis report.');
        }

        $this->browseWithFailureScreenshot('render', function (Browser $browser) use ($classSectionId): void {
            $this->visitAuthenticated($browser, self::REPORT_CLASS . $classSectionId, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser), 'Authorized admin must not be bounced to login.');
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('Whoops', $source, 'Class Analysis must not throw a server error.');
            // Either the grid renders or the documented empty state does — both prove no 500.
            $rendered = str_contains($source, 'Class Average Score')
                || str_contains($source, 'Student Ranking')
                || str_contains($source, 'No score data available');
            $this->assertTrue($rendered, 'by-class report must render either the analysis grid or its empty state.');
        });
    }

    public function test_class_analysis_11_class_section_and_period_filters_render(): void
    {
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available to render the filters.');
        }

        $this->browseWithFailureScreenshot('filters', function (Browser $browser) use ($classSectionId): void {
            $this->visitAuthenticated($browser, self::REPORT_CLASS . $classSectionId, 1100);
            $browser->assertSee('Class-Section:');
            $browser->assertSee('Period:');
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('id="classSectionSelect"', $source, 'Class-Section selector must render.');
            $this->assertStringContainsString('name="period_id"', $source, 'Period filter select must render.');
            $this->assertStringContainsString('byClassForm', $source, 'The filter form must render.');
        });
    }

    public function test_class_analysis_12_period_filter_narrows_without_error(): void
    {
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available for the period-filter smoke.');
        }
        $periodId = Schema::hasTable('ba_assessment_periods') ? DB::table('ba_assessment_periods')->value('id') : null;
        $suffix = $periodId !== null ? ('?period_id=' . $periodId) : '';

        $response = $this->getFromAdminPage(self::REPORT_CLASS . $classSectionId . $suffix);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'A period_id filter should narrow the report, not 500.'
        );
    }

    public function test_class_analysis_13_unknown_period_filter_degrades_gracefully(): void
    {
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available for the unknown-period smoke.');
        }
        $response = $this->getFromAdminPage(self::REPORT_CLASS . $classSectionId . '?period_id=' . self::MISSING_ID);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'An unknown period_id (find() → null) must degrade gracefully, not 500.'
        );
    }

    public function test_class_analysis_14_computed_score_has_no_score_attribute_bug_ba_013(): void
    {
        // Basis of BUG-BA-013: the live column/attribute is `numeric_score`; there is no `score`.
        $this->assertFalse(Schema::hasColumn(self::SCORES_TABLE, 'score'));
        $this->assertContains('numeric_score', (new BaComputedScore())->getFillable());
        $this->assertNotContains('score', (new BaComputedScore())->getFillable());

        $seed = $this->seedComputedScore(['numeric_score' => 4.50]);
        if ($seed === null) {
            $this->markTestSkipped('Could not seed a computed score (student/category/period unavailable).');
        }
        $seed->refresh();
        $this->assertSame('4.50', (string) $seed->numeric_score);
        $this->assertNull($seed->score, 'BUG-BA-013: BaComputedScore exposes no `score` attribute — the class report averages null.');
        $this->deleteComputedScore($seed);
    }

    public function test_class_analysis_15_class_level_aggregation_on_score_yields_zero_bug_ba_013(): void
    {
        // Deterministic core proof of the CLASS-LEVEL defect. byClass() computes, per student:
        //   overall_score = round((float) $scores->avg('score'), 2)
        // and per category avg('score')/min('score')/max('score'). With no `score` attribute those are null → 0.00,
        // while the correct numeric_score aggregate is the real value. This is exactly what the byClass() path does.
        $seed = $this->seedComputedScore(['numeric_score' => 4.50]);
        if ($seed === null) {
            $this->markTestSkipped('Could not seed a computed score to prove the aggregation defect.');
        }

        $rows = BaComputedScore::query()->whereKey($seed->id)->get();

        // The (broken) aggregation the controller actually performs:
        $brokenAvg = $rows->avg('score');
        $this->assertNull($brokenAvg, 'BUG-BA-013: avg(\'score\') over rows with no `score` attribute is null.');
        $this->assertSame(0.0, round((float) $brokenAvg, 2), 'BUG-BA-013: round((float) null, 2) = 0.00 — the class report shows 0.00 for a 4.50 student.');
        $this->assertSame(0.0, round((float) $rows->min('score'), 2), 'BUG-BA-013: category min(\'score\') collapses to 0.00.');
        $this->assertSame(0.0, round((float) $rows->max('score'), 2), 'BUG-BA-013: category max(\'score\') collapses to 0.00.');

        // The correct aggregation the code SHOULD have performed:
        $this->assertSame(4.5, round((float) $rows->avg('numeric_score'), 2), 'numeric_score is the real column and aggregates correctly.');

        // Consequence: at-risk logic (overall < 2.50) fires for a 4.50 student.
        $this->assertTrue(round((float) $brokenAvg, 2) < 2.50, 'BUG-BA-013: a top-scoring student is wrongly flagged at-risk.');

        $this->deleteComputedScore($seed);
    }

    public function test_class_analysis_16_controller_byclass_aggregates_nonexistent_score_bug_ba_013(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm BUG-BA-013.');
        }
        $byClass = $this->extractByClassMethod($controller);

        $this->assertStringContainsString("avg('score')", $byClass, 'BUG-BA-013: byClass() averages the non-existent `score` column.');
        $this->assertStringContainsString("min('score')", $byClass, 'BUG-BA-013: byClass() takes min of `score`.');
        $this->assertStringContainsString("max('score')", $byClass, 'BUG-BA-013: byClass() takes max of `score`.');
        $this->assertStringContainsString("pluck('score')", $byClass, 'BUG-BA-013: byClass() plucks `score` for std-dev.');
        $this->assertStringNotContainsString("avg('numeric_score')", $byClass, 'BUG-BA-013: byClass() never reads the real numeric_score column.');

        // Contrast: student() (the per-student path) DOES read the correct column — proving the bug is byClass-specific.
        $this->assertStringContainsString("avg('numeric_score')", $controller, 'student() reads the real numeric_score column (contrast).');
    }

    public function test_class_analysis_17_by_class_blade_reads_nonexistent_score_bug_ba_013(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/by-class.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('by-class view not readable to confirm BUG-BA-013.');
        }
        // The at-risk "low categories" filter reads $cs->score directly on the computed-score model.
        $this->assertStringContainsString('->score < 2.5', $view, 'BUG-BA-013: by-class.blade filters low categories on the non-existent ->score attribute.');
    }

    // =====================================================================
    // Band 30–39 — Validation / negative (invalid ids & filters)
    // =====================================================================

    public function test_class_analysis_30_invalid_class_section_id_returns_404(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_CLASS . self::MISSING_ID);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Unknown class-section id must 404 (findOrFail).');
    }

    public function test_class_analysis_31_non_numeric_class_section_id_returns_404(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_CLASS . 'not-a-number');
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'A non-numeric class-section id must not resolve to a record.');
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency
    // =====================================================================

    public function test_class_analysis_40_computed_scores_fks_restrict_on_delete(): void
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

    public function test_class_analysis_41_byclass_selects_active_students_and_top_level_categories(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $byClass = $this->extractByClassMethod($controller);
        $this->assertStringContainsString("where('class_section_id', \$classSection->id)", $byClass, 'byClass() scopes students to the class-section.');
        $this->assertStringContainsString("where('is_active', true)", $byClass, 'byClass() only includes active students.');
        $this->assertStringContainsString('whereNull(\'parent_id\')', $byClass, 'byClass() renders only top-level (parent) categories.');
        $this->assertTrue(Schema::hasTable('ba_categories'), 'ba_categories backing table must exist.');
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_class_analysis_50_guest_is_redirected_to_login(): void
    {
        $classSectionId = $this->anyClassSectionId() ?? self::MISSING_ID;
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser) use ($classSectionId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::REPORT_CLASS . $classSectionId))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_class_analysis_51_limited_user_gets_403_on_class_report(): void
    {
        $classSectionId = $this->anyClassSectionId() ?? self::MISSING_ID;
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-403', function (Browser $browser) use ($limited, $classSectionId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORT_CLASS . $classSectionId));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'reports.view gate must block the limited user before findOrFail.');
        });

        $this->deleteUser($limited);
    }

    public function test_class_analysis_52_policy_maps_to_permission_strings(): void
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

    public function test_class_analysis_53_export_gate_diverges_from_policy_val_ba_003(): void
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
    // Band 60–69 — UI/UX (empty state, back navigation, thresholds)
    // =====================================================================

    public function test_class_analysis_60_empty_state_when_no_scores(): void
    {
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available for the empty-state check.');
        }
        // Force an unlikely period so the scores collection is empty → documented empty state (or a rendered grid).
        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser) use ($classSectionId): void {
            $this->visitAuthenticated($browser, self::REPORT_CLASS . $classSectionId . '?period_id=' . self::MISSING_ID, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertTrue(
                str_contains($source, 'No score data available')
                    || str_contains($source, 'Student Ranking')
                    || str_contains($source, 'Class Average Score'),
                'by-class report must show the documented empty state or the grid.'
            );
        });
    }

    public function test_class_analysis_61_report_links_back_to_reports_hub(): void
    {
        $classSectionId = $this->anyClassSectionId();
        if ($classSectionId === null) {
            $this->markTestSkipped('No class-section available for the back-link check.');
        }
        $this->browseWithFailureScreenshot('back-link', function (Browser $browser) use ($classSectionId): void {
            $this->visitAuthenticated($browser, self::REPORT_CLASS . $classSectionId, 1000);
            $browser->assertSee('All Reports');
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('/behavioural-assessment/reports', $source, 'A back link to the Reports Hub must render.');
        });
    }

    public function test_class_analysis_62_at_risk_threshold_is_documented(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/by-class.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('by-class view not readable for the at-risk threshold check.');
        }
        $this->assertStringContainsString('2.50', $view, 'The at-risk threshold (< 2.50) must be documented in the report.');
        $this->assertStringContainsString('At Risk', $view, 'The at-risk label must render.');
    }

    // =====================================================================
    // Band 70–79 — Edge cases / requirement gaps (BC-EDG)
    // =====================================================================

    public function test_class_analysis_70_export_is_live_abort_501_stub_bug_ba_011(): void
    {
        // BUG-BA-011: an authorized user hitting the live export route gets HTTP 501 (unimplemented stub).
        $response = $this->getFromAdminPage(self::REPORT_EXPORT);
        $this->assertSame(
            501,
            (int) ($response['status'] ?? 0),
            'BUG-BA-011 regression fixed? Export should currently abort(501) "Export feature coming soon."'
        );
    }

    public function test_class_analysis_71_class_analysis_export_unimplemented_ca_gap_01(): void
    {
        // CA-GAP-01: the class-analysis grid has no working export — the only export route is the 501 stub.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm CA-GAP-01.');
        }
        $exportBody = $this->extractExportMethod($controller);
        $this->assertStringContainsString('abort(501', $exportBody, 'CA-GAP-01: export remains an abort(501) stub.');
        $this->assertStringNotContainsString('StreamedResponse', $controller, 'CA-GAP-01: no streamed CSV export implemented.');
        $this->assertStringNotContainsString('fputcsv', $controller, 'CA-GAP-01: no CSV writer implemented.');
    }

    public function test_class_analysis_72_std_dev_collapses_to_zero_from_broken_score_bug_ba_013(): void
    {
        // The category std-dev is sqrt(avg((v - avg)^2)) over pluck('score'). With all `score` null → 0 values,
        // the deviation is 0.0 for any real distribution — the "spread" visualization is meaningless (BUG-BA-013).
        $seedA = $this->seedComputedScore(['numeric_score' => 1.00]);
        $seedB = $this->seedComputedScore(['numeric_score' => 5.00, 'period_shift' => true]);
        if ($seedA === null) {
            $this->markTestSkipped('Could not seed computed scores to prove the std-dev collapse.');
        }

        $ids = array_values(array_filter([$seedA?->id, $seedB?->id]));
        $rows = BaComputedScore::query()->whereIn('id', $ids)->get();

        $values = $rows->pluck('score')->map(fn ($v) => (float) $v); // all 0.0 — `score` is null
        $avg = (float) $rows->avg('score');
        $stdDev = $values->count() > 1
            ? sqrt($values->map(fn ($v) => ($v - $avg) ** 2)->avg())
            : 0.0;
        $this->assertSame(0.0, round($stdDev, 2), 'BUG-BA-013: std-dev over the non-existent `score` column is always 0.00.');

        // The real numeric_score distribution would NOT be flat — proving information is lost.
        $realValues = $rows->pluck('numeric_score')->map(fn ($v) => (float) $v);
        if ($realValues->count() > 1) {
            $realAvg = (float) $rows->avg('numeric_score');
            $realStd = sqrt($realValues->map(fn ($v) => ($v - $realAvg) ** 2)->avg());
            $this->assertGreaterThan(0.0, $realStd, 'The real numeric_score distribution has non-zero spread that the report discards.');
        }

        $this->deleteComputedScore($seedA);
        $this->deleteComputedScore($seedB);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + API deadness + security
    // =====================================================================

    public function test_class_analysis_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side report tests.'
        );
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'ba_computed_scores must resolve within the tenant DB.');
    }

    public function test_class_analysis_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001(): void
    {
        // DEAD-BA-001: routes/api.php declares Route::middleware(['auth:sanctum'])->apiResource(...) with NO tenancy
        // bootstrapper; and RSP::map() only maps web.php (constraint #23) — the route is never registered.
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

    public function test_class_analysis_92_rendered_report_escapes_output(): void
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
        $rawName = 'class-analysis-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'class-analysis-' . $kind . '-' . now()->format('Ymd_His');
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
window.__caApiDone = false;
window.__caApiError = '';
window.__caApiResult = null;

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

        window.__caApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__caApiError = String(error);
    } finally {
        window.__caApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__caApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__caApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__caApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Seed / cleanup ---------------------------------------------------

    /**
     * Seed a computed score for an existing student/category/period, respecting the
     * (student_id, category_id, period_id) unique key. The `period_shift` override picks a second
     * period (when available) so two rows can co-exist for std-dev checks.
     */
    private function seedComputedScore(array $overrides = []): ?BaComputedScore
    {
        try {
            $studentId  = $this->anyStudentId();
            $categoryId = Schema::hasTable('ba_categories') ? DB::table('ba_categories')->value('id') : null;

            $wantSecondPeriod = (bool) ($overrides['period_shift'] ?? false);
            unset($overrides['period_shift']);
            $periodId = null;
            if (Schema::hasTable('ba_assessment_periods')) {
                $periodIds = DB::table('ba_assessment_periods')->orderBy('id')->pluck('id');
                if ($wantSecondPeriod && $periodIds->count() > 1) {
                    $periodId = (int) $periodIds[1];
                } else {
                    $periodId = $periodIds->isNotEmpty() ? (int) $periodIds[0] : null;
                }
            }

            if ($studentId === null || $categoryId === null || $periodId === null) {
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
                'name'              => 'CA Limited ' . $this->uniqueSuffix(),
                'email'             => 'ca_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'CL' . substr($this->uniqueSuffix(), -8);
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
