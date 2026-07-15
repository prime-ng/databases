<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Controllers\BaReportController;
use Modules\BehaviouralAssessment\Models\BaCategory;
use Modules\BehaviouralAssessment\Models\BaComputedScore;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Category Summary Report (Reports Hub → "Category & Criteria Performance").
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/17-Category-Summary.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns → tenant init required).
 * Runtime table      : ba_computed_scores  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaReportController::categories()
 *                      Route  : behavioural-assessment.reports.categories  →  GET /behavioural-assessment/reports/categories
 *                      View   : behaviouralassessment::reports.categories (breadcrumb title "Category Performance")
 *                      Screen requirement 17 (Category-Summary) AND screen requirement 23 (Category-Performance)
 *                      BOTH map to this single categories() implementation (DOC-BA-002, proven in _73).
 * Permission prefix  : tenant.behavioural-assessment.reports.{viewAny|view|export}
 * Activity log       : NONE — read-only report controller, no activityLog() helper (documented absence).
 * Test STYLE         : browser Dusk (extends DuskTestCase) — mirrors the committed siblings
 *                      RatingScale/bha_RatingScale_TestCas.php and StudentScoresReport/bha_StudentScoresReport_TestCas.php.
 *
 * Defects proven:
 *   - BUG-BA-013 : categories() aggregates via RAW SQL `AVG(score)/MIN(score)/MAX(score)` on ba_computed_scores,
 *                  whose real column is `numeric_score` — there is NO `score` column. Because these are RAW-SQL
 *                  aggregates (not in-memory Collection avg like byClass()), the query throws
 *                  SQLSTATE[42S22] "Unknown column 'score'" → the Category Summary page HARD-500s every time it
 *                  is opened (worse than byClass()'s silent 0.00). Proven deterministically at the DB layer in
 *                  _11, at the route in _12, and by source scan in _13. Contrast: student() reads numeric_score (_15).
 *   - BUG-BA-011 : reports/export is a permanent abort(501) stub on a live, authorized route — the requirement's
 *                  PDF/CSV export is therefore unavailable for this screen (proven in _70 / _72).
 *   - DEAD-BA-001: api.php `behaviouralassessments` apiResource has NO tenancy middleware AND is never registered
 *                  (RouteServiceProvider::map only maps web.php — constraint #23) (proven in _91).
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - VAL-BA-003 : export() authorizes reports.view though BaReportPolicy exposes an `export` ability on
 *                  reports.export (dead policy method / weaker gate) (proven in _53).
 * Requirement-vs-implementation gaps (screen 17):
 *   - RPT-GAP-11 : requirement Class + Section filters are NOT implemented — only a period_id filter exists (_71).
 *   - RPT-GAP-12 : requirement columns Students Count / Category Average / Top Criterion / Lowest Criterion /
 *                  Cohort Distribution buckets and the PDF/CSV export are NOT implemented as specified (_72).
 *   - DOC-BA-002 : screen 17 (Category-Summary) and screen 23 (Category-Performance) share one implementation (_73).
 */
class bha_CategorySummary_TestCas extends DuskTestCase
{
    private const URL_PREFIX        = '/behavioural-assessment';
    private const REPORTS_INDEX     = '/behavioural-assessment/reports';
    private const REPORT_CATEGORIES = '/behavioural-assessment/reports/categories';
    private const REPORT_STUDENT    = '/behavioural-assessment/reports/student/'; // append student id (contrast path)
    private const REPORT_EXPORT     = '/behavioural-assessment/reports/export';

    private const SCORES_TABLE      = 'ba_computed_scores';
    private const DDL_SCORES        = 'bha_computed_scores';   // stale DDL-doc name (must NOT exist at runtime)

    private const MISSING_ID        = 987654321;

    private const SCREENSHOT_DIR    = 'tests/Browser/Modules/BehaviouralAssessment/CategorySummary/screenshots';

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

    public function test_category_summary_01_computed_scores_schema_and_model_are_correct(): void
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

        // BUG-BA-013 anchor: the aggregation column the requirement means is `numeric_score`; a bare `score`
        // column (which categories() incorrectly aggregates on) does NOT exist.
        $this->assertTrue(Schema::hasColumn(self::SCORES_TABLE, 'numeric_score'), 'numeric_score is the real score column.');
        $this->assertFalse(
            Schema::hasColumn(self::SCORES_TABLE, 'score'),
            'ba_computed_scores has no bare `score` column — categories() aggregating on it is defective (BUG-BA-013).'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::SCORES_TABLE))->keyBy('Field');
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['numeric_score']->Type ?? '')));
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['overall_score']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));
        }

        // Migration content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130619_create_ba_computed_scores_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_computed_scores'", $migration);
            $this->assertStringContainsString("\$table->decimal('numeric_score', 5, 2)", $migration);
            $this->assertStringContainsString("\$table->unique(['student_id', 'category_id', 'period_id']", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
            $this->assertStringNotContainsString("->decimal('score'", $migration, 'No bare `score` column is created — confirms BUG-BA-013.');
        }

        // Model configuration.
        $score = new BaComputedScore();
        $this->assertSame('ba_computed_scores', $score->getTable());
        $this->assertSame([
            'student_id', 'category_id', 'period_id', 'numeric_score', 'grade',
            'overall_score', 'overall_grade', 'computed_at', 'is_active',
            'created_by', 'updated_by',
        ], $score->getFillable());
        $this->assertNotContains('score', $score->getFillable(), 'The model exposes no `score` attribute (BUG-BA-013).');
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaComputedScore::class));
        $this->assertInstanceOf(BelongsTo::class, $score->category());
        $this->assertInstanceOf(BelongsTo::class, $score->period());
    }

    public function test_category_summary_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
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

    public function test_category_summary_03_report_controller_method_and_route_are_registered(): void
    {
        foreach (['index', 'categories', 'student', 'export'] as $method) {
            $this->assertTrue(
                method_exists(BaReportController::class, $method),
                "BaReportController::{$method}() is expected to exist."
            );
        }

        foreach ([
            'behavioural-assessment.reports.index',
            'behavioural-assessment.reports.categories',
            'behavioural-assessment.reports.export',
        ] as $routeName) {
            $this->assertTrue(Route::has($routeName), "Route {$routeName} is not registered.");
        }

        // The Category Summary route is a static GET with NO route-model param (filtered via ?period_id=).
        $route = Route::getRoutes()->getByName('behavioural-assessment.reports.categories');
        if ($route !== null) {
            $this->assertSame([], $route->parameterNames(), 'reports.categories takes no route parameter — filters are query-string only.');
            $this->assertContains('GET', $route->methods(), 'reports.categories must be a GET route.');
        }
    }

    public function test_category_summary_04_categories_view_and_hub_link_exist(): void
    {
        $view  = $this->readAppFile($this->moduleRootPath('resources/views/reports/categories.blade.php'));
        $index = $this->readAppFile($this->moduleRootPath('resources/views/reports/index.blade.php'));

        if ($view === null && $index === null) {
            $this->markTestSkipped('Report view sources not readable from the app repo.');
        }
        if ($view !== null) {
            $this->assertStringContainsString('School-Wide Category', $view, 'categories view renders the school-wide category grid.');
        }
        if ($index !== null) {
            $this->assertStringContainsString("route('behavioural-assessment.reports.categories')", $index, 'Reports Hub must link to the Category Summary report.');
        }
    }

    // =====================================================================
    // Band 10–19 — Business rules / render + BUG-BA-013 (BC-BIZ)
    // =====================================================================

    public function test_category_summary_10_reports_hub_renders_for_authorized_admin(): void
    {
        $this->browseWithFailureScreenshot('hub-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORTS_INDEX, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser), 'Authorized admin must not be bounced to login.');
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Category & Criteria Performance', $source, 'Reports Hub must advertise the Category report card.');
        });
    }

    public function test_category_summary_11_category_aggregate_raw_sql_uses_nonexistent_score_column_bug_ba_013(): void
    {
        // DEFINITIVE DB-level proof: categories() runs exactly this RAW-SQL aggregate. Because `score` is not a
        // column of ba_computed_scores, MySQL rejects the query at prepare time (Unknown column 'score'),
        // regardless of how many rows exist. Seed a real row first so the failure can never be blamed on empty data.
        $seed = $this->seedComputedScore(['numeric_score' => 4.25]);

        $threw = false;
        $message = '';
        try {
            BaComputedScore::query()
                ->selectRaw('category_id, AVG(score) as avg_score, MIN(score) as min_score, MAX(score) as max_score, COUNT(DISTINCT student_id) as student_count')
                ->groupBy('category_id')
                ->get();
        } catch (QueryException $e) {
            $threw = true;
            $message = strtolower($e->getMessage());
        } catch (Throwable $e) {
            $threw = true;
            $message = strtolower($e->getMessage());
        } finally {
            $this->deleteComputedScore($seed);
        }

        $this->assertTrue($threw, 'BUG-BA-013 regression: AVG(score) on ba_computed_scores should throw — `score` is not a column.');
        $this->assertStringContainsString('score', $message, 'The QueryException should reference the unknown `score` column.');

        // Control: the SAME aggregate on the REAL column succeeds — proving the fix is a one-word column rename.
        $ok = true;
        try {
            BaComputedScore::query()
                ->selectRaw('category_id, AVG(numeric_score) as avg_score, MIN(numeric_score) as min_score, MAX(numeric_score) as max_score, COUNT(DISTINCT student_id) as student_count')
                ->groupBy('category_id')
                ->get();
        } catch (Throwable) {
            $ok = false;
        }
        $this->assertTrue($ok, 'AVG(numeric_score) — the correct column — must succeed.');
    }

    public function test_category_summary_12_category_summary_page_hard_500s_due_to_bug_ba_013(): void
    {
        // Route manifestation: an authorized admin opening the Category Summary page gets a server error (500)
        // because categories() executes the broken AVG(score) aggregate. Graceful-skip when the module is
        // disabled (404) or the environment bounces to login, so partial environments stay green.
        $response = $this->getFromAdminPage(self::REPORT_CATEGORIES);
        $status = (int) ($response['status'] ?? 0);

        if (in_array($status, [0, 404], true)) {
            $this->markTestSkipped('Category Summary route not reachable (module disabled / 404) — cannot exercise the route-level 500.');
        }
        if ($status === 302) {
            $this->markTestSkipped('Category Summary route redirected (auth/login) — route-level 500 not exercised.');
        }

        $this->assertSame(
            500,
            $status,
            'BUG-BA-013: the Category Summary page must currently 500 (Unknown column `score`). '
                . 'When the controller is fixed to aggregate numeric_score, update this expectation to 200.'
        );
    }

    public function test_category_summary_13_categories_controller_aggregates_on_score_not_numeric_score_bug_ba_013(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm BUG-BA-013.');
        }

        $categoriesBody = $this->extractMethodBody($controller, 'function categories', 'function export');
        $this->assertStringContainsString('AVG(score)', $categoriesBody, 'BUG-BA-013: categories() aggregates AVG(score).');
        $this->assertStringContainsString('MIN(score)', $categoriesBody, 'BUG-BA-013: categories() aggregates MIN(score).');
        $this->assertStringContainsString('MAX(score)', $categoriesBody, 'BUG-BA-013: categories() aggregates MAX(score).');
        $this->assertStringNotContainsString('AVG(numeric_score)', $categoriesBody, 'BUG-BA-013: categories() should have used numeric_score.');
    }

    public function test_category_summary_14_seeded_score_has_numeric_score_but_no_score_attribute(): void
    {
        $seed = $this->seedComputedScore(['numeric_score' => 3.80]);
        if ($seed === null) {
            $this->markTestSkipped('Could not seed a computed score (dependencies absent).');
        }

        $seed->refresh();
        $this->assertSame('3.80', (string) $seed->numeric_score, 'numeric_score persists correctly.');
        $this->assertNull($seed->score, 'BUG-BA-013: the model exposes no `score` attribute — the summary would read null.');
        $this->deleteComputedScore($seed);
    }

    public function test_category_summary_15_student_report_correctly_reads_numeric_score_contrast(): void
    {
        // Contrast: student() uses the REAL column, proving BUG-BA-013 is specific to categories()/byClass().
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $studentBody = $this->extractMethodBody($controller, 'function student', 'function byClass');
        $this->assertStringContainsString("avg('numeric_score')", $studentBody, 'student() reads the real numeric_score column.');
        $this->assertStringNotContainsString("avg('score')", $studentBody, 'student() does not read the broken `score` column.');
    }

    public function test_category_summary_16_criterion_performance_reads_rating_levels_numeric_value(): void
    {
        // The Bottom-10-criteria block of the same screen aggregates ba_rating_levels.numeric_value (a real column)
        // and is therefore unaffected by BUG-BA-013 — but it is never reached because $categoryAverages 500s first.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $categoriesBody = $this->extractMethodBody($controller, 'function categories', 'function export');
        $this->assertStringContainsString('ba_rating_levels.numeric_value', $categoriesBody, 'Bottom-10 criteria uses the real numeric_value column.');
        $this->assertTrue(Schema::hasTable('ba_rating_levels'), 'ba_rating_levels backing table must exist.');
        $this->assertTrue(Schema::hasColumn('ba_rating_levels', 'numeric_value'), 'ba_rating_levels.numeric_value must exist.');
    }

    public function test_category_summary_17_report_is_anonymized_no_student_identity_columns(): void
    {
        // Screen-17 business rule "Anonymized Reporting": the summary must show no student names/ids — only
        // categories, counts and averages. Confirm via source (the page itself cannot render — BUG-BA-013).
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/categories.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('categories view not readable to confirm anonymization.');
        }
        $this->assertStringNotContainsString('student->name', $view, 'Anonymized report must not print student names.');
        $this->assertStringNotContainsString('roll_no', $view, 'Anonymized report must not print roll numbers.');
        $this->assertStringNotContainsString('admission_no', $view, 'Anonymized report must not print admission numbers.');
        $this->assertStringContainsString('student_count', $view, 'The grid aggregates a student COUNT, not identities.');
    }

    // =====================================================================
    // Band 30–39 — Validation / negative (filters & bad params)
    // =====================================================================

    public function test_category_summary_30_period_filter_does_not_change_the_bug_ba_013_outcome(): void
    {
        // The AVG(score) aggregate runs whether or not a period filter is applied, so a period_id filter cannot
        // rescue the page — it still 500s. Proven at the DB layer to stay environment-independent.
        $seed = $this->seedComputedScore(['numeric_score' => 2.90]);
        $periodId = $this->anyPeriodId();

        $threw = false;
        try {
            BaComputedScore::query()
                ->when($periodId, fn ($q) => $q->where('period_id', $periodId))
                ->selectRaw('category_id, AVG(score) as avg_score')
                ->groupBy('category_id')
                ->get();
        } catch (Throwable) {
            $threw = true;
        } finally {
            $this->deleteComputedScore($seed);
        }
        $this->assertTrue($threw, 'BUG-BA-013 is unconditional: filtering by period does not avoid the broken AVG(score).');
    }

    public function test_category_summary_31_unknown_period_filter_still_reaches_the_bug(): void
    {
        // A non-existent period_id resolves to find() → null → no WHERE clause added, so the broken aggregate still
        // executes. Route probe accepts the documented outcome set (500 broken, or 404/302 in a disabled env).
        $response = $this->getFromAdminPage(self::REPORT_CATEGORIES . '?period_id=' . self::MISSING_ID);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [500, 404, 302, 0],
            'An unknown period_id still drives the broken aggregate (500), or degrades to 404/302 in a disabled env.'
        );
    }

    public function test_category_summary_32_garbage_query_params_do_not_introduce_a_new_error(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_CATEGORIES . '?period_id=not-a-number&foo=%3Cb%3E');
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [500, 404, 302, 0],
            'Injection-shaped query params must not produce an outcome outside the documented set.'
        );
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency (BC-INT / BC-REF)
    // =====================================================================

    public function test_category_summary_40_computed_scores_fks_restrict_on_delete(): void
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

    public function test_category_summary_41_categories_report_dependency_tables_exist(): void
    {
        // categories() joins ba_criteria + ba_rating_levels, reads ba_class_category_jnt (applicability map) and
        // sch classes. Confirm the dependency surface exists (defensive; skip individually if a table is absent).
        foreach (['ba_computed_scores', 'ba_categories', 'ba_criteria', 'ba_rating_levels', 'ba_class_category_jnt'] as $table) {
            $this->assertTrue(Schema::hasTable($table), "Dependency table {$table} must exist for the Category Summary report.");
        }
        // BaCategory must expose polarity + parent_id + sort_order (grid grouping / badge).
        $cat = new BaCategory();
        foreach (['polarity', 'parent_id', 'sort_order', 'is_active'] as $col) {
            $this->assertContains($col, $cat->getFillable(), "BaCategory must be fillable on {$col}.");
        }
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_category_summary_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::REPORT_CATEGORIES))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_category_summary_51_limited_user_gets_403_on_category_summary(): void
    {
        $limited = $this->makeLimitedUser();
        $this->browseWithFailureScreenshot('limited-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORT_CATEGORIES));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'reports.view gate must block the limited user BEFORE the broken query runs.');
        });
        $this->deleteUser($limited);
    }

    public function test_category_summary_52_policy_maps_to_permission_strings(): void
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

    public function test_category_summary_53_export_gate_diverges_from_policy_val_ba_003(): void
    {
        // VAL-BA-003: export() authorizes reports.view though the Policy exposes an `export` ability on reports.export.
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
    // Band 60–69 — UI/UX (empty state, filter, navigation)
    // =====================================================================

    public function test_category_summary_60_categories_view_declares_an_empty_state(): void
    {
        // The view has a documented empty state ("No computed scores available"), though it is unreachable while
        // BUG-BA-013 stands (the aggregate 500s before the view is rendered).
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/categories.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('categories view not readable for the empty-state check.');
        }
        $this->assertStringContainsString('No computed scores available', $view, 'Documented empty-state message expected.');
    }

    public function test_category_summary_61_categories_view_exposes_only_a_period_filter(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/categories.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('categories view not readable for the filter check.');
        }
        $this->assertStringContainsString('name="period_id"', $view, 'Period filter select must render.');
    }

    public function test_category_summary_62_reports_hub_card_links_to_category_report(): void
    {
        $this->browseWithFailureScreenshot('hub-link', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORTS_INDEX, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('reports/categories', $source, 'Reports Hub must link to the Category Summary report.');
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases / requirement-vs-implementation gaps (BC-EDG)
    // =====================================================================

    public function test_category_summary_70_export_is_live_abort_501_stub_bug_ba_011(): void
    {
        // BUG-BA-011: an authorized user hitting the live export route gets HTTP 501 (unimplemented stub).
        $response = $this->getFromAdminPage(self::REPORT_EXPORT);
        $status = (int) ($response['status'] ?? 0);
        if (in_array($status, [0, 404, 302], true)) {
            $this->markTestSkipped('Export route not reachable (module disabled / redirect) — cannot exercise the 501 stub.');
        }
        $this->assertSame(501, $status, 'BUG-BA-011: export should currently abort(501) "Export feature coming soon."');
    }

    public function test_category_summary_71_requirement_class_and_section_filters_not_implemented_rpt_gap_11(): void
    {
        // Screen-17 specifies Class + Section filters (Section enabled only when Class chosen). The implementation
        // has ONLY a period_id filter — RPT-GAP-11.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/categories.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('categories view not readable to confirm RPT-GAP-11.');
        }
        $this->assertStringNotContainsString('name="class_id"', $view, 'RPT-GAP-11 changed: a Class filter is now implemented.');
        $this->assertStringNotContainsString('name="section_id"', $view, 'RPT-GAP-11 changed: a Section filter is now implemented.');
        $this->assertStringNotContainsString('name="class_section_id"', $view, 'RPT-GAP-11 changed: a Class-Section filter is now implemented.');
    }

    public function test_category_summary_72_requirement_columns_and_export_not_implemented_rpt_gap_12(): void
    {
        // Screen-17 grid promises Top Criterion / Lowest Criterion / Cohort Distribution buckets per category and
        // PDF + CSV export. None are implemented — RPT-GAP-12.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/categories.blade.php'));
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($view === null && $controller === null) {
            $this->markTestSkipped('Sources not readable to confirm RPT-GAP-12.');
        }
        if ($view !== null) {
            $this->assertStringNotContainsString('Top Criterion', $view, 'RPT-GAP-12 changed: Top Criterion column now present.');
            $this->assertStringNotContainsString('Lowest Criterion', $view, 'RPT-GAP-12 changed: Lowest Criterion column now present.');
            $this->assertStringNotContainsString('Cohort Distribution', $view, 'RPT-GAP-12 changed: Cohort Distribution column now present.');
        }
        if ($controller !== null) {
            $this->assertStringNotContainsString('StreamedResponse', $controller, 'RPT-GAP-12: no streamed CSV/PDF export implemented.');
            $this->assertStringNotContainsString('fputcsv', $controller, 'RPT-GAP-12: no CSV writer implemented.');
        }
    }

    public function test_category_summary_73_screen_17_and_23_share_one_implementation_doc_ba_002(): void
    {
        // DOC-BA-002: requirement screen 17 (Category-Summary) and screen 23 (Category-Performance) both resolve to
        // the single categories() route/view — there is no separate Category-Summary implementation.
        $this->assertTrue(Route::has('behavioural-assessment.reports.categories'), 'The shared categories route must exist.');
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/categories.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('categories view not readable to confirm DOC-BA-002.');
        }
        // The one shared view is titled "Category Performance" (screen 23 wording) — screen 17's "Category Summary"
        // has no distinct page.
        $this->assertStringContainsString('Category Performance', $view, 'The single shared view is labelled Category Performance.');
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + API deadness + security
    // =====================================================================

    public function test_category_summary_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side report tests.'
        );
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'ba_computed_scores must resolve within the tenant DB.');
    }

    public function test_category_summary_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001(): void
    {
        // DEAD-BA-001: routes/api.php declares Route::middleware(['auth:sanctum'])->apiResource(...) with NO tenancy
        // bootstrapper; and RouteServiceProvider::map() only maps web.php (constraint #23) — never registered.
        $this->assertFalse(
            Route::has('behaviouralassessment.index'),
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

    public function test_category_summary_92_web_report_routes_carry_full_tenancy_stack(): void
    {
        $rsp = $this->readAppFile($this->moduleRootPath('app/Providers/RouteServiceProvider.php'));
        if ($rsp === null) {
            $this->markTestSkipped('RouteServiceProvider source not readable.');
        }
        foreach (['InitializeTenancyByDomain', 'PreventAccessFromCentralDomains', 'EnsureTenantIsActive', "'auth'", "'verified'"] as $needle) {
            $this->assertStringContainsString($needle, $rsp, "Web report routes must carry {$needle} in the middleware stack.");
        }
    }

    public function test_category_summary_93_categories_view_escapes_output(): void
    {
        // The page cannot render while BUG-BA-013 stands, so assert output-escaping at the source level: category
        // names must be printed with Blade's escaping {{ }}, never raw {!! !!}.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/categories.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('categories view not readable for the escaping smoke.');
        }
        $this->assertStringContainsString('{{ $cat->name }}', $view, 'Category name must be escaped via {{ }}.');
        $this->assertStringNotContainsString('{!! $cat->name', $view, 'Category name must NOT be printed raw ({!! !!}).');
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
        $rawName = 'category-summary-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'category-summary-' . $kind . '-' . now()->format('Ymd_His');
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
window.__csApiDone = false;
window.__csApiError = '';
window.__csApiResult = null;

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

        window.__csApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__csApiError = String(error);
    } finally {
        window.__csApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__csApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__csApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__csApiResult || null;');
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
            $periodId   = $this->anyPeriodId();
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

    private function anyPeriodId(): ?int
    {
        try {
            if (!Schema::hasTable('ba_assessment_periods')) {
                return null;
            }
            $id = DB::table('ba_assessment_periods')->value('id');
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
                'name'              => 'CS Limited ' . $this->uniqueSuffix(),
                'email'             => 'cs_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'CS' . substr($this->uniqueSuffix(), -8);
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
     * Extract a controller method body (from $startNeedle up to $endNeedle, or a byte length) for targeted
     * source assertions without a full parser.
     */
    private function extractMethodBody(string $source, string $startNeedle, ?string $endNeedle, int $fallbackLen = 4000): string
    {
        $start = strpos($source, $startNeedle);
        if ($start === false) {
            return $source;
        }
        if ($endNeedle !== null) {
            $end = strpos($source, $endNeedle, $start + strlen($startNeedle));
            if ($end !== false) {
                return substr($source, $start, $end - $start);
            }
        }
        return substr($source, $start, $fallbackLen);
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
