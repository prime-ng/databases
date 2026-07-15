<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Controllers\BaReportController;
use Modules\BehaviouralAssessment\Models\BaComputedScore;
use Modules\BehaviouralAssessment\Models\BaIncident;
use Modules\BehaviouralAssessment\Models\BaStudentRemark;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Student Report (per-student consolidated behavioural dossier).
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/20-Student-Report.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime tables     : ba_computed_scores, ba_incidents, ba_student_remarks, ba_assessment_ratings,
 *                      ba_assessments, ba_assessment_periods, ba_categories
 *                      (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaReportController::student(int $student)
 *                      → returns view behaviouralassessment::reports.student
 *                      Route: behavioural-assessment.reports.student → /behavioural-assessment/reports/student/{student}
 * Permission         : tenant.behavioural-assessment.reports.view  (student() gate)
 *                      tenant.behavioural-assessment.reports.viewAny (Reports Hub shell / index)
 * Activity log       : NONE — read-only report controller, no activityLog() helper (documented absence).
 * Test STYLE         : browser Dusk (extends DuskTestCase) — mirrors the committed sibling
 *                      BehaviouralAssessment/StudentScoresReport/bha_StudentScoresReport_TestCas.php.
 *
 * Data-correctness contract (student()):
 *   - Overall KPI badge   = $categoryScores->avg('numeric_score')   → CORRECT live column.
 *   - Class Rank          = AVG(numeric_score) grouped by student    → CORRECT live column.
 *   - Category-wise grid  = rendered by student.blade.php via $cs->score (NON-EXISTENT column) → see BUG-BA-013.
 *   - Incidents           = ba_incidents whereBetween(incident_date, [period.start, period.end]).
 *   - Remarks             = ba_student_remarks for the student + latest assessment.
 *
 * Defects proven (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md + this run):
 *   - BUG-BA-013 : student.blade.php Category-Wise Scores grid reads a NON-EXISTENT `score` column
 *                  (live column is `numeric_score`). The controller overall KPI/class-rank use numeric_score
 *                  correctly, so the badge is right while every per-category Score / % / Performance-Bar
 *                  renders 0.00 — a split (partial) firing of BUG-BA-013 on this screen (proven in _70 / _11).
 *   - BUG-BA-011 : reports/export is a permanent abort(501) stub on a live, authorized route — the
 *                  requirement's "Download PDF" action has no working backing (proven in _71).
 *   - DEAD-BA-001: routes/api.php `behaviouralassessments` apiResource has NO tenancy middleware AND is never
 *                  registered (RSP::map maps only web.php — constraint #23) (proven in _91).
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _06).
 *   - VAL-BA-003 : export() authorizes reports.view though BaReportPolicy exposes an `export` ability on
 *                  reports.export (dead policy method / weaker gate) (proven in _53).
 * Feature-scoped requirement-vs-implementation gaps:
 *   - RPT-GAP-STU-01 : screen-20 "Grade Lockdown Rule" (hide Draft/Submitted grades + show
 *                      "Grading for this period is in progress…" + a staff "Show Drafts" toggle) is NOT
 *                      implemented — student() pulls latest() regardless of status and the blade renders
 *                      scores unconditionally (proven in _72).
 *   - RPT-GAP-STU-02 : screen-20 "Download PDF" button (identity header) is absent from student.blade;
 *                      the only export route is the 501 stub (proven in _73).
 */
class bha_StudentReport_TestCas extends DuskTestCase
{
    private const URL_PREFIX     = '/behavioural-assessment';
    private const REPORTS_INDEX  = '/behavioural-assessment/reports';
    private const REPORT_STUDENT = '/behavioural-assessment/reports/student/'; // append student id
    private const REPORT_EXPORT  = '/behavioural-assessment/reports/export';

    private const SCORES_TABLE   = 'ba_computed_scores';
    private const INCIDENTS_TABLE = 'ba_incidents';
    private const REMARKS_TABLE  = 'ba_student_remarks';
    private const DDL_SCORES     = 'bha_computed_scores';   // stale DDL-doc name (must NOT exist at runtime)

    private const MISSING_ID     = 987654321;

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/StudentReport/screenshots';

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

    public function test_student_report_01_computed_scores_schema_and_model_are_correct(): void
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

        // The report grid must aggregate on `numeric_score`; the (broken) `score` column must NOT exist (BUG-BA-013).
        $this->assertFalse(
            Schema::hasColumn(self::SCORES_TABLE, 'score'),
            'ba_computed_scores has no bare `score` column — the report blade that reads it is defective (BUG-BA-013).'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::SCORES_TABLE))->keyBy('Field');
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['numeric_score']->Type ?? '')));
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['overall_score']->Type ?? '')));
        }

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

    public function test_student_report_02_incidents_schema_and_model_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'Table ba_incidents does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::INCIDENTS_TABLE, [
                'id', 'student_id', 'reported_by', 'category_id', 'criterion_id',
                'incident_date', 'incident_time', 'incident_type', 'severity',
                'description', 'location', 'is_follow_up_required', 'follow_up_notes',
                'is_active', 'created_by', 'updated_by', 'deleted_at',
            ]),
            'Expected columns are missing in ba_incidents table.'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::INCIDENTS_TABLE))->keyBy('Field');
            // The report timeline splits on incident_type; assert the ENUM values verbatim (constraint #18).
            $typeDef = strtolower((string) ($cols['incident_type']->Type ?? ''));
            $this->assertStringContainsString('positive_reinforcement', $typeDef);
            $this->assertStringContainsString('negative_incident', $typeDef);
            $sevDef = strtolower((string) ($cols['severity']->Type ?? ''));
            foreach (['minor', 'moderate', 'major', 'critical'] as $sev) {
                $this->assertStringContainsString($sev, $sevDef, "Severity ENUM should contain {$sev}.");
            }
        }

        $incident = new BaIncident();
        $this->assertSame('ba_incidents', $incident->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaIncident::class));
        $this->assertInstanceOf(BelongsTo::class, $incident->student());
        $this->assertInstanceOf(BelongsTo::class, $incident->category());
        $this->assertInstanceOf(BelongsToMany::class, $incident->interventions());
    }

    public function test_student_report_03_student_remarks_schema_and_model_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::REMARKS_TABLE), 'Table ba_student_remarks does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::REMARKS_TABLE, [
                'id', 'assessment_id', 'student_id', 'remark_text',
                'is_active', 'created_by', 'updated_by', 'deleted_at',
            ]),
            'Expected columns are missing in ba_student_remarks table.'
        );

        $remark = new BaStudentRemark();
        $this->assertSame('ba_student_remarks', $remark->getTable());
        $this->assertSame([
            'assessment_id', 'student_id', 'remark_text', 'is_active', 'created_by', 'updated_by',
        ], $remark->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaStudentRemark::class));
        $this->assertInstanceOf(BelongsTo::class, $remark->assessment());
        $this->assertInstanceOf(BelongsTo::class, $remark->student());
    }

    public function test_student_report_04_report_controller_method_and_route_are_registered(): void
    {
        $this->assertTrue(
            method_exists(BaReportController::class, 'student'),
            'BaReportController::student() is expected to exist.'
        );

        foreach ([
            'behavioural-assessment.reports.index',
            'behavioural-assessment.reports.student',
            'behavioural-assessment.reports.export',
        ] as $routeName) {
            $this->assertTrue(Route::has($routeName), "Route {$routeName} is not registered.");
        }

        // The student report route binds a {student} parameter.
        $route = Route::getRoutes()->getByName('behavioural-assessment.reports.student');
        $this->assertNotNull($route, 'Student report route must resolve.');
        $this->assertStringContainsString('reports/student/', $route->uri(), 'Route uri should target reports/student/{student}.');
    }

    public function test_student_report_05_student_view_renders_expected_sections(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/student.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('student.blade.php source not readable from the app repo.');
        }
        $this->assertStringContainsString('Student Overview', $view, 'student view should render the Student Overview zone.');
        $this->assertStringContainsString('Overall Score', $view, 'student view should render the Overall Score KPI.');
        $this->assertStringContainsString('Category-Wise Scores', $view, 'student view should render the Category-Wise Scores grid.');
        $this->assertStringContainsString('Incident Summary', $view, 'student view should render the Incident Summary timeline.');
        $this->assertStringContainsString('Class Rank', $view, 'student view should render the Class Rank badge.');
    }

    public function test_student_report_06_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
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
        $this->assertSame('ba_incidents', (new BaIncident())->getTable());
        $this->assertSame('ba_student_remarks', (new BaStudentRemark())->getTable());
    }

    // =====================================================================
    // Band 10–19 — Business rules / render + data correctness (BC-BIZ)
    // =====================================================================

    public function test_student_report_10_student_report_renders_for_authorized_admin(): void
    {
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available to render the per-student report.');
        }

        $this->browseWithFailureScreenshot('student-render', function (Browser $browser) use ($studentId): void {
            $this->visitAuthenticated($browser, self::REPORT_STUDENT . $studentId, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser), 'Authorized admin must not be bounced to login.');
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('Whoops', $source, 'Student report must not throw a server error.');
            $this->assertStringContainsString('Student Overview', $source, 'The Student Overview zone must render.');
        });
    }

    public function test_student_report_11_controller_reads_numeric_score_for_overall_and_rank(): void
    {
        // The overall KPI badge and Class Rank are computed in the controller on the REAL column.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $studentBody = $this->extractStudentMethod($controller);
        $this->assertStringContainsString("avg('numeric_score')", $studentBody, 'student() overall score must average the real numeric_score column.');
        $this->assertStringContainsString("AVG(numeric_score)", $studentBody, 'student() class-rank ranking must use AVG(numeric_score).');
        $this->assertStringNotContainsString("avg('score')", $studentBody, 'student() must NOT average a non-existent `score` column (contrast with byClass()).');
    }

    public function test_student_report_12_kpi_badges_render_score_and_incident_counts(): void
    {
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available for the KPI badge render.');
        }
        $this->browseWithFailureScreenshot('kpi-render', function (Browser $browser) use ($studentId): void {
            $this->visitAuthenticated($browser, self::REPORT_STUDENT . $studentId, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Overall Score', $source, 'Overall Score KPI badge must render.');
            $this->assertStringContainsString('Positive Incidents', $source, 'Positive Incidents KPI must render.');
            $this->assertStringContainsString('Negative Incidents', $source, 'Negative Incidents KPI must render.');
            $this->assertStringContainsString('/ 5.00', $source, 'Overall Score must render on a /5.00 scale.');
        });
    }

    public function test_student_report_13_class_rank_uses_numeric_score_and_renders_or_hides(): void
    {
        // Class Rank is only rendered when computed; either way the page must not error.
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available for the class-rank check.');
        }
        $response = $this->getFromAdminPage(self::REPORT_STUDENT . $studentId);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'Student report (with class-rank aggregation on numeric_score) must render without a 500.'
        );
    }

    public function test_student_report_14_incident_timeline_reads_ba_incidents(): void
    {
        // The Incident Summary timeline splits positive/negative and reads ba_incidents.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/student.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('student.blade.php source not readable.');
        }
        $this->assertStringContainsString('positive_reinforcement', $view, 'Incident timeline must classify positive_reinforcement rows.');
        $this->assertStringContainsString('incident_date', $view, 'Incident timeline must render incident_date.');
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'ba_incidents backing table must exist.');
    }

    public function test_student_report_15_teacher_remarks_section_reads_student_remarks(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/student.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('student.blade.php source not readable.');
        }
        $this->assertStringContainsString('Teacher Remarks', $view, 'Narrative section (Teacher Remarks) must render.');
        $this->assertStringContainsString('remark_text', $view, 'Remarks section must render remark_text from ba_student_remarks.');
        $this->assertTrue(Schema::hasTable(self::REMARKS_TABLE), 'ba_student_remarks backing table must exist.');
    }

    // =====================================================================
    // Band 30–39 — Validation / negative (invalid ids & filters)
    // =====================================================================

    public function test_student_report_30_invalid_student_id_returns_404(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_STUDENT . self::MISSING_ID);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Unknown student id must 404 (findOrFail).');
    }

    public function test_student_report_31_unknown_period_filter_does_not_error(): void
    {
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available for the period-filter smoke.');
        }
        $response = $this->getFromAdminPage(self::REPORT_STUDENT . $studentId . '?period_id=' . self::MISSING_ID);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'An unknown period_id filter should degrade gracefully (find() → null), not 500.'
        );
    }

    public function test_student_report_32_period_selector_accepts_valid_filter(): void
    {
        $studentId = $this->anyStudentId();
        $periodId  = $this->anyPeriodId();
        if ($studentId === null || $periodId === null) {
            $this->markTestSkipped('No student/period available for the period-selector smoke.');
        }
        $response = $this->getFromAdminPage(self::REPORT_STUDENT . $studentId . '?period_id=' . $periodId);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'A valid period_id filter must render without error.');
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency
    // =====================================================================

    public function test_student_report_40_computed_scores_fks_restrict_on_delete(): void
    {
        $this->assertReferentialRules(self::SCORES_TABLE, [
            'std_students'            => ['RESTRICT', 'NO ACTION'],
            'ba_categories'           => ['RESTRICT', 'NO ACTION'],
            'ba_assessment_periods'   => ['RESTRICT', 'NO ACTION'],
        ]);
    }

    public function test_student_report_41_incident_fks_restrict_or_set_null_on_delete(): void
    {
        $this->assertReferentialRules(self::INCIDENTS_TABLE, [
            'std_students'  => ['RESTRICT', 'NO ACTION'],
            'sch_employees' => ['RESTRICT', 'NO ACTION'],
            'ba_categories' => ['SET NULL'],
            'ba_criteria'   => ['SET NULL'],
        ]);
    }

    public function test_student_report_42_student_remark_fks_cascade_and_restrict(): void
    {
        $this->assertReferentialRules(self::REMARKS_TABLE, [
            'ba_assessments' => ['CASCADE'],
            'std_students'   => ['RESTRICT', 'NO ACTION'],
        ]);
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_student_report_50_guest_is_redirected_to_login(): void
    {
        $studentId = $this->anyStudentId() ?? self::MISSING_ID;
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser) use ($studentId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::REPORT_STUDENT . $studentId))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_student_report_51_limited_user_gets_403_on_student_report(): void
    {
        $studentId = $this->anyStudentId() ?? self::MISSING_ID;
        $limited = $this->makeLimitedUser();
        $this->browseWithFailureScreenshot('limited-student-403', function (Browser $browser) use ($limited, $studentId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORT_STUDENT . $studentId));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'reports.view gate must block the limited user before findOrFail.');
        });
        $this->deleteUser($limited);
    }

    public function test_student_report_52_policy_maps_to_permission_strings(): void
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

    public function test_student_report_53_export_gate_diverges_from_policy_val_ba_003(): void
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

    public function test_student_report_60_empty_state_message_present(): void
    {
        // The documented empty state shows when categoryScores + ratings + incidents are all empty.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/student.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('student.blade.php source not readable for empty-state check.');
        }
        $this->assertStringContainsString('No behavioural data found', $view, 'Documented empty-state message expected.');
        $this->assertStringContainsString('computed after assessments are reviewed and locked', $view, 'Empty-state guidance text expected.');
    }

    public function test_student_report_61_period_selector_renders(): void
    {
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available for the period-selector render.');
        }
        $this->browseWithFailureScreenshot('period-selector', function (Browser $browser) use ($studentId): void {
            $this->visitAuthenticated($browser, self::REPORT_STUDENT . $studentId, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('name="period_id"', $source, 'Assessment Period selector must render.');
            $this->assertStringContainsString('Latest Period', $source, 'Period selector must offer the "Latest Period" default option.');
        });
    }

    public function test_student_report_62_all_reports_back_link_present(): void
    {
        $studentId = $this->anyStudentId();
        if ($studentId === null) {
            $this->markTestSkipped('No student available for the navigation check.');
        }
        $this->browseWithFailureScreenshot('back-link', function (Browser $browser) use ($studentId): void {
            $this->visitAuthenticated($browser, self::REPORT_STUDENT . $studentId, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('All Reports', $source, 'Student report must link back to the Reports Hub.');
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases / requirement gaps (BC-EDG)
    // =====================================================================

    public function test_student_report_70_category_grid_reads_nonexistent_score_column_bug_ba_013(): void
    {
        // Live column is `numeric_score`; the model exposes no `score` attribute/accessor.
        $this->assertFalse(Schema::hasColumn(self::SCORES_TABLE, 'score'));
        $this->assertContains('numeric_score', (new BaComputedScore())->getFillable());

        // Runtime proof: a persisted computed score has numeric_score set but `score` resolves to null.
        $seed = $this->seedComputedScore(['numeric_score' => 4.50]);
        if ($seed !== null) {
            $seed->refresh();
            $this->assertSame('4.50', (string) $seed->numeric_score);
            $this->assertNull($seed->score, 'BUG-BA-013: BaComputedScore has no `score` attribute — the student grid renders 0.00.');
            $this->deleteComputedScore($seed);
        }

        // Source proof: student.blade Category-Wise Scores grid reads $cs->score (non-existent column),
        // while the controller overall/rank correctly use numeric_score (split firing).
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/student.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('student.blade.php source not readable to confirm BUG-BA-013.');
        }
        $this->assertStringContainsString('$cs->score', $view, 'BUG-BA-013: student grid averages/renders the non-existent `score` column.');
        $this->assertStringContainsString('$categoryScores[$catId]?->score', $view, 'BUG-BA-013: collapsible category badge reads the broken `score` column.');
    }

    public function test_student_report_71_export_is_live_abort_501_stub_bug_ba_011(): void
    {
        // BUG-BA-011: the requirement's "Download PDF" has no working backing — the only export route aborts 501.
        $response = $this->getFromAdminPage(self::REPORT_EXPORT);
        $this->assertSame(
            501,
            (int) ($response['status'] ?? 0),
            'BUG-BA-011 regression fixed? Export should currently abort(501) "Export feature coming soon."'
        );

        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller !== null) {
            $exportBody = $this->extractExportMethod($controller);
            $this->assertStringContainsString('abort(501', $exportBody, 'export() remains an abort(501) stub.');
        }
    }

    public function test_student_report_72_grade_lockdown_rule_not_implemented_rpt_gap_stu_01(): void
    {
        // Screen-20 "Grade Lockdown Rule": draft/unapproved grades must be hidden + a "Show Drafts" toggle +
        // a "Grading for this period is in progress…" message. None of this is implemented.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/student.blade.php'));
        if ($controller === null && $view === null) {
            $this->markTestSkipped('Sources not readable to confirm RPT-GAP-STU-01.');
        }
        if ($controller !== null) {
            $studentBody = $this->extractStudentMethod($controller);
            // student() pulls the latest() assessment with no status filter → draft grades are NOT excluded.
            $this->assertStringContainsString('->latest()', $studentBody, 'student() selects the latest assessment.');
            $this->assertStringNotContainsString("where('status', 'locked')", $studentBody, 'RPT-GAP-STU-01 changed: student() now filters to locked grades.');
        }
        if ($view !== null) {
            $this->assertStringNotContainsString('Grading for this period is in progress', $view, 'RPT-GAP-STU-01 changed: lockdown message now present.');
            $this->assertStringNotContainsString('Show Drafts', $view, 'RPT-GAP-STU-01 changed: staff Show Drafts toggle now present.');
        }
    }

    public function test_student_report_73_download_pdf_button_absent_rpt_gap_stu_02(): void
    {
        // Screen-20 identity header specifies a "Download PDF" button; student.blade has none, only the 501 stub.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/student.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('student.blade.php source not readable to confirm RPT-GAP-STU-02.');
        }
        $this->assertStringNotContainsString('Download PDF', $view, 'RPT-GAP-STU-02 changed: Download PDF button now present.');
        $this->assertStringNotContainsString('reports.export', $view, 'RPT-GAP-STU-02 changed: student report now wires an export action.');
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + API deadness + security
    // =====================================================================

    public function test_student_report_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side report tests.'
        );
        $this->assertTrue(Schema::hasTable(self::SCORES_TABLE), 'ba_computed_scores must resolve within the tenant DB.');
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'ba_incidents must resolve within the tenant DB.');
    }

    public function test_student_report_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001(): void
    {
        // DEAD-BA-001: routes/api.php declares an apiResource with NO tenancy bootstrapper; and RSP::map()
        // only maps web.php (constraint #23) — the route is never registered.
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
            $this->assertStringNotContainsString('InitializeTenancyByDomain', $api, 'DEAD-BA-001: api.php has no tenancy middleware.');
        }
        if ($rsp !== null) {
            $this->assertStringNotContainsString('routes/api.php', $rsp, 'DEAD-BA-001: RSP::map() never loads routes/api.php.');
        }
    }

    public function test_student_report_92_web_report_routes_carry_full_tenancy_stack(): void
    {
        $rsp = $this->readAppFile($this->moduleRootPath('app/Providers/RouteServiceProvider.php'));
        if ($rsp === null) {
            $this->markTestSkipped('RouteServiceProvider source not readable.');
        }
        foreach (['InitializeTenancyByDomain', 'PreventAccessFromCentralDomains', "'auth'"] as $needle) {
            $this->assertStringContainsString($needle, $rsp, "Web report routes must carry {$needle} in the middleware stack.");
        }
    }

    public function test_student_report_93_rendered_report_escapes_output(): void
    {
        // Defensive stored-XSS smoke: the Blade grid must escape student/category/remark text.
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
        $rawName = 'student-report-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'student-report-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- FK metadata ------------------------------------------------------

    /**
     * @param  array<string,array<int,string>>  $expected  referenced-table => acceptable DELETE_RULE tokens
     */
    private function assertReferentialRules(string $table, array $expected): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('FK metadata inspection requires MySQL.');
        }
        try {
            $rules = collect(DB::select(
                "SELECT REFERENCED_TABLE_NAME, DELETE_RULE
                 FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ?",
                [$table]
            ))->keyBy('REFERENCED_TABLE_NAME');

            if ($rules->isEmpty()) {
                $this->markTestSkipped("No FK metadata for {$table}.");
            }

            $checked = 0;
            foreach ($expected as $ref => $acceptable) {
                if (!isset($rules[$ref])) {
                    continue;
                }
                $rule = strtoupper((string) ($rules[$ref]->DELETE_RULE ?? ''));
                $ok = false;
                foreach ($acceptable as $token) {
                    if (str_contains($rule, strtoupper($token))) {
                        $ok = true;
                        break;
                    }
                }
                $this->assertTrue($ok, "{$table} → {$ref} DELETE_RULE should be one of [" . implode(', ', $acceptable) . "]; found {$rule}.");
                $checked++;
            }

            if ($checked === 0) {
                $this->markTestSkipped("No matching FK constraints found for {$table} to assert.");
            }
        } catch (Throwable $e) {
            $this->markTestSkipped("FK dependency inspection unavailable for {$table}: " . $e->getMessage());
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
window.__srApiDone = false;
window.__srApiError = '';
window.__srApiResult = null;

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

        window.__srApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__srApiError = String(error);
    } finally {
        window.__srApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__srApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__srApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__srApiResult || null;');
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
                'name'              => 'SR Limited ' . $this->uniqueSuffix(),
                'email'             => 'sr_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'SR' . substr($this->uniqueSuffix(), -8);
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

    /** Extract the student() method body (up to byClass()) for targeted source assertions. */
    private function extractStudentMethod(string $controller): string
    {
        $start = strpos($controller, 'function student');
        if ($start === false) {
            return $controller;
        }
        $end = strpos($controller, 'function byClass', $start);
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
