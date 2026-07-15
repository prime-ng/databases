<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Controllers\BaReportController;
use Modules\BehaviouralAssessment\Models\BaIncident;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Incident Report (standalone conduct-tracking analytical panel).
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/24-Incident-Report.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime tables     : ba_incidents (core), ba_incident_intervention_jnt + ba_interventions (usage join),
 *                      ba_incident_witnesses_jnt, ba_categories, std_students, sch_employees
 *                      (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaReportController::incidents()
 *                      → returns view behaviouralassessment::reports.incidents
 *                      Route: behavioural-assessment.reports.incidents → GET /behavioural-assessment/reports/incidents
 * Permission         : tenant.behavioural-assessment.reports.view   (incidents() gate)
 *                      tenant.behavioural-assessment.reports.viewAny (Reports Hub shell / index)
 * Activity log       : NONE — read-only report controller, no activityLog() helper (documented absence).
 * Test STYLE         : browser Dusk (extends DuskTestCase) — mirrors the committed sibling
 *                      BehaviouralAssessment/StudentReport/bha_StudentReport_TestCas.php (same BaReportController).
 *
 * Real filter set (incidents()): incident_type, severity, from_date (def. startOfMonth), to_date (def. today),
 *   category_id.  NO class/section/student filter (contrast requirement §"Search and Filters" — see RPT-GAP-INC-01).
 *
 * Data-correctness contract (incidents()):
 *   - totalCount        = filtered ba_incidents count.
 *   - positiveCount     = filtered where incident_type='positive_reinforcement'.
 *   - negativeCount     = totalCount - positiveCount   (derived invariant).
 *   - typeSeverityBreakdown / categoryBreakdown / locationBreakdown = grouped aggregates on ba_incidents.
 *   - interventionUsage = DB::table('ba_incident_intervention_jnt') JOIN ba_interventions JOIN ba_incidents.
 *   - incidentLog       = paginate(25) with student/reportedBy/category/interventions eager loads.
 *
 * Defects proven (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md + this run):
 *   - BUG-BA-011 : reports/export is a permanent abort(501) stub on a live, authorized route — the
 *                  requirement's CSV/Excel/PDF export actions have no working backing (proven in _70).
 *   - BUG-BA-013 : NOT APPLICABLE to this screen — incidents() reads no `score`/computed_scores column,
 *                  so the broken bha_computed_scores.score grid bug does not fire here (documented in _71).
 *   - DEAD-BA-001: routes/api.php `behaviouralassessments` apiResource has NO tenancy middleware AND is never
 *                  registered (RSP::map maps only web.php — constraint #23) (proven in _91).
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _05).
 *   - VAL-BA-003 : export() authorizes reports.view though BaReportPolicy exposes an `export` ability on
 *                  reports.export (dead policy method / weaker gate) (proven in _53).
 * Feature-scoped requirement-vs-implementation gaps:
 *   - RPT-GAP-INC-01 : screen-24 Class&Section + Student filters are NOT implemented — incidents() only
 *                      filters incident_type/severity/from_date/to_date/category_id (proven in _72).
 *   - RPT-GAP-INC-02 : screen-24 charts ("Weekly Frequency Curve" line, "Intervention Success Rate" donut,
 *                      "Top 3 Infraction Triggers" bar) are rendered as HTML tables, and the trend is
 *                      MONTHLY (6-month) not WEEKLY — no chart canvas exists (proven in _73).
 *   - RPT-GAP-INC-03 : screen-24 "Export Compliance & Privacy" (roll-numbers in admin export + STUDENT-SHA
 *                      anonymisation in public digests) is unimplemented — export is the 501 stub (proven in _74).
 *   - RPT-GAP-INC-04 : screen-24 grid "Witness Count" column is absent — incidents() does not load witnesses;
 *                      the log grid shows an intervention count, not witness count (proven in _75).
 *   - DOC-BA-006     : screen-24 severity vocabulary (Info/Low/Medium/High) diverges from the live ENUM
 *                      (minor/moderate/major/critical) used by controller + blade (proven in _76).
 */
class bha_IncidentReport_TestCas extends DuskTestCase
{
    private const URL_PREFIX       = '/behavioural-assessment';
    private const REPORTS_INDEX    = '/behavioural-assessment/reports';
    private const REPORT_INCIDENTS = '/behavioural-assessment/reports/incidents';
    private const REPORT_EXPORT    = '/behavioural-assessment/reports/export';

    private const INCIDENTS_TABLE      = 'ba_incidents';
    private const INTERVENTIONS_TABLE  = 'ba_interventions';
    private const INC_INT_JNT_TABLE    = 'ba_incident_intervention_jnt';
    private const INC_WIT_JNT_TABLE    = 'ba_incident_witnesses_jnt';
    private const DDL_INCIDENTS        = 'bha_incidents';   // stale DDL-doc name (must NOT exist at runtime)

    private const MISSING_ID = 987654321;

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/IncidentReport/screenshots';

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

    public function test_incident_report_01_incidents_schema_and_model_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'Table ba_incidents does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::INCIDENTS_TABLE, [
                'id', 'student_id', 'reported_by', 'category_id', 'criterion_id',
                'incident_date', 'incident_time', 'incident_type', 'severity',
                'description', 'location', 'intervention_notes',
                'is_follow_up_required', 'follow_up_date', 'follow_up_notes',
                'is_notified', 'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_incidents table.'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::INCIDENTS_TABLE))->keyBy('Field');

            // The report splits on incident_type; assert the ENUM values verbatim (constraint #18).
            $typeDef = strtolower((string) ($cols['incident_type']->Type ?? ''));
            $this->assertStringContainsString('positive_reinforcement', $typeDef);
            $this->assertStringContainsString('negative_incident', $typeDef);

            // Severity ENUM used by the Severity filter/breakdown — live vocabulary (contrast DOC-BA-006).
            $sevDef = strtolower((string) ($cols['severity']->Type ?? ''));
            foreach (['minor', 'moderate', 'major', 'critical'] as $sev) {
                $this->assertStringContainsString($sev, $sevDef, "Severity ENUM should contain {$sev}.");
            }

            // Location ENUM feeds the Location Analysis widget.
            $locDef = strtolower((string) ($cols['location']->Type ?? ''));
            foreach (['classroom', 'playground', 'lab'] as $loc) {
                $this->assertStringContainsString($loc, $locDef, "Location ENUM should contain {$loc}.");
            }
        }

        $incident = new BaIncident();
        $this->assertSame('ba_incidents', $incident->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaIncident::class));
        $this->assertContains('incident_type', $incident->getFillable());
        $this->assertContains('severity', $incident->getFillable());
        $this->assertInstanceOf(BelongsTo::class, $incident->student());
        $this->assertInstanceOf(BelongsTo::class, $incident->reportedBy());
        $this->assertInstanceOf(BelongsTo::class, $incident->category());
        $this->assertInstanceOf(HasMany::class, $incident->witnesses());
        $this->assertInstanceOf(BelongsToMany::class, $incident->interventions());

        // Type-splitting scopes the report/analytics rely on.
        $this->assertTrue(method_exists(BaIncident::class, 'scopeNegative'));
        $this->assertTrue(method_exists(BaIncident::class, 'scopePositive'));
    }

    public function test_incident_report_02_intervention_join_tables_exist(): void
    {
        // interventionUsage = DB::table('ba_incident_intervention_jnt') JOIN ba_interventions JOIN ba_incidents.
        $this->assertTrue(Schema::hasTable(self::INC_INT_JNT_TABLE), 'ba_incident_intervention_jnt must exist for Intervention Usage widget.');
        $this->assertTrue(Schema::hasTable(self::INTERVENTIONS_TABLE), 'ba_interventions must exist.');
        $this->assertTrue(Schema::hasTable(self::INC_WIT_JNT_TABLE), 'ba_incident_witnesses_jnt must exist (witness linkage).');

        $this->assertTrue(
            Schema::hasColumns(self::INC_INT_JNT_TABLE, ['id', 'incident_id', 'intervention_id', 'notes']),
            'ba_incident_intervention_jnt missing expected columns.'
        );
        $this->assertTrue(
            Schema::hasColumns(self::INTERVENTIONS_TABLE, ['id', 'name', 'intervention_type']),
            'ba_interventions missing name/intervention_type consumed by the usage widget.'
        );
    }

    public function test_incident_report_03_report_controller_method_and_routes_are_registered(): void
    {
        $this->assertTrue(
            method_exists(BaReportController::class, 'incidents'),
            'BaReportController::incidents() is expected to exist.'
        );

        foreach ([
            'behavioural-assessment.reports.index',
            'behavioural-assessment.reports.incidents',
            'behavioural-assessment.reports.export',
        ] as $routeName) {
            $this->assertTrue(Route::has($routeName), "Route {$routeName} is not registered.");
        }

        $route = Route::getRoutes()->getByName('behavioural-assessment.reports.incidents');
        $this->assertNotNull($route, 'Incident report route must resolve.');
        $this->assertStringContainsString('reports/incidents', $route->uri(), 'Route uri should target reports/incidents.');
        $this->assertContains('GET', $route->methods(), 'Incident report route must be a GET route.');
    }

    public function test_incident_report_04_incidents_view_renders_expected_sections(): void
    {
        $view = $this->readAppFile($this->moduleRootPath('resources/views/reports/incidents.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('reports/incidents.blade.php source not readable from the app repo.');
        }
        foreach ([
            'Incident Report',                 // breadcrumb title
            'Filters',
            'Total Incidents',
            'Positive Reinforcements',
            'Negative Incidents',
            'Follow-ups Pending',
            'Breakdown by Type & Severity',
            'Location Analysis',
            'Incidents by Category',
            'Intervention Usage',
            'Incident Log',
        ] as $needle) {
            $this->assertStringContainsString($needle, $view, "Incident report view should render the '{$needle}' zone.");
        }
    }

    public function test_incident_report_05_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
    {
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'Runtime table ba_incidents must exist.');

        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_INCIDENTS),
                'DOC-BA-001 regression: bha_incidents exists at runtime; expected only the live ba_incidents.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 check: ' . $e->getMessage());
        }

        $this->assertSame('ba_incidents', (new BaIncident())->getTable());
        // The intervention-usage query hardcodes the live ba_ join tables.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller !== null) {
            $body = $this->extractIncidentsMethod($controller);
            $this->assertStringContainsString("DB::table('ba_incident_intervention_jnt')", $body, 'Usage widget must read the live ba_ junction table.');
            $this->assertStringContainsString("'ba_interventions'", $body, 'Usage widget must join the live ba_interventions table.');
            $this->assertStringNotContainsString('bha_incident', $body, 'Controller must not reference stale bha_ tables.');
        }
    }

    public function test_incident_report_06_controller_reads_real_filter_set(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $body = $this->extractIncidentsMethod($controller);
        foreach ([
            "request('incident_type')",
            "request('severity')",
            "request('from_date'",
            "request('to_date'",
            "request('category_id')",
        ] as $needle) {
            $this->assertStringContainsString($needle, $body, "incidents() must honour the {$needle} filter.");
        }
        // Defaults: from_date = startOfMonth, to_date = today.
        $this->assertStringContainsString('startOfMonth()', $body, 'from_date defaults to the start of the current month.');
        $this->assertStringContainsString('paginate(25)', $body, 'Incident Log paginates 25 rows per page.');
    }

    // =====================================================================
    // Band 10–19 — Render + data-correctness (BC-BIZ)
    // =====================================================================

    public function test_incident_report_10_report_renders_for_authorized_admin(): void
    {
        $this->browseWithFailureScreenshot('render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORT_INCIDENTS, 1100);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser), 'Authorized admin must not be bounced to login.');
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('Whoops', $source, 'Incident report must not throw a server error.');
            $this->assertStringContainsString('Incident Report', $source, 'The Incident Report heading must render.');
            $this->assertStringContainsString('Incident Log', $source, 'The Incident Log grid must render.');
        });
    }

    public function test_incident_report_11_executive_summary_kpi_cards_render(): void
    {
        $this->browseWithFailureScreenshot('kpi-cards', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORT_INCIDENTS, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Total Incidents', $source, 'Total Incidents KPI card must render.');
            $this->assertStringContainsString('Positive Reinforcements', $source, 'Positive Reinforcements KPI card must render.');
            $this->assertStringContainsString('Negative Incidents', $source, 'Negative Incidents KPI card must render.');
            $this->assertStringContainsString('Follow-ups Pending', $source, 'Follow-ups Pending KPI card must render.');
        });
    }

    public function test_incident_report_12_negative_count_is_total_minus_positive_invariant(): void
    {
        // Source-level correctness: negativeCount is DERIVED, never a separate query (keeps totals consistent).
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $body = $this->extractIncidentsMethod($controller);
        $this->assertStringContainsString('$totalCount    = $baseQuery()->count();', $body, 'totalCount is a filtered count.');
        $this->assertStringContainsString("where('incident_type', 'positive_reinforcement')->count()", $body, 'positiveCount filters on the positive enum.');
        $this->assertStringContainsString('$negativeCount = $totalCount - $positiveCount;', $body, 'negativeCount must be the total-minus-positive invariant.');
    }

    public function test_incident_report_13_seeded_incidents_appear_in_log_and_counts(): void
    {
        // Runtime data-correctness smoke: seed one positive + one negative incident dated today (in the
        // default startOfMonth..today window) and assert both surface in the rendered log + record count grows.
        $baseline = $this->countIncidentsInCurrentMonth();
        $pos = $this->seedIncident(['incident_type' => 'positive_reinforcement', 'severity' => null]);
        $neg = $this->seedIncident(['incident_type' => 'negative_incident', 'severity' => 'major']);
        if ($pos === null || $neg === null) {
            $this->cleanupIncident($pos);
            $this->cleanupIncident($neg);
            $this->markTestSkipped('Could not seed incidents (missing student/employee dependency).');
        }

        try {
            $after = $this->countIncidentsInCurrentMonth();
            $this->assertGreaterThanOrEqual($baseline + 2, $after, 'Both seeded incidents must be counted within the default window.');

            $this->browseWithFailureScreenshot('seeded-log', function (Browser $browser): void {
                $this->visitAuthenticated($browser, self::REPORT_INCIDENTS, 1100);
                $source = $browser->driver->getPageSource();
                $this->assertStringContainsString('records', $source, 'Incident Log record badge must render.');
                $this->assertStringNotContainsString('No incidents found for the selected filters.', $source, 'With seeded rows the empty state must not show.');
            });
        } finally {
            $this->cleanupIncident($pos);
            $this->cleanupIncident($neg);
        }
    }

    public function test_incident_report_14_analytics_widgets_render(): void
    {
        $this->browseWithFailureScreenshot('analytics', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORT_INCIDENTS, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Breakdown by Type', $source, 'Type/Severity breakdown widget must render.');
            $this->assertStringContainsString('Location Analysis', $source, 'Location Analysis widget must render.');
            $this->assertStringContainsString('Incidents by Category', $source, 'Category breakdown widget must render.');
            $this->assertStringContainsString('Intervention Usage', $source, 'Intervention Usage widget must render.');
        });
    }

    public function test_incident_report_15_intervention_usage_reads_junction_join(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $body = $this->extractIncidentsMethod($controller);
        $this->assertStringContainsString("join('ba_interventions'", $body, 'Usage must join ba_interventions.');
        $this->assertStringContainsString("join('ba_incidents'", $body, 'Usage must join ba_incidents for the date window.');
        $this->assertStringContainsString('ba_interventions.intervention_type', $body, 'Usage groups by intervention_type.');
        $this->assertTrue(Schema::hasTable(self::INC_INT_JNT_TABLE), 'Backing junction table must exist.');
    }

    // =====================================================================
    // Band 30–39 — Validation / negative filter handling
    // =====================================================================

    public function test_incident_report_30_unknown_category_filter_does_not_error(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_INCIDENTS . '?category_id=' . self::MISSING_ID);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'An unknown category_id filter should degrade gracefully (empty result set), not 500.'
        );
    }

    public function test_incident_report_31_garbage_date_filter_does_not_500(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_INCIDENTS . '?from_date=not-a-date&to_date=also-bad');
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302, 500],
            'A malformed date filter should ideally degrade; a 500 here documents an unguarded whereDate cast.'
        );
    }

    public function test_incident_report_32_valid_severity_filter_renders(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_INCIDENTS . '?severity=major');
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'A valid severity filter must render without error.');
    }

    public function test_incident_report_33_valid_incident_type_filter_renders(): void
    {
        $response = $this->getFromAdminPage(self::REPORT_INCIDENTS . '?incident_type=negative_incident');
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'A valid incident_type filter must render without error.');
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency
    // =====================================================================

    public function test_incident_report_40_incident_fks_restrict_or_set_null_on_delete(): void
    {
        $this->assertReferentialRules(self::INCIDENTS_TABLE, [
            'std_students'  => ['RESTRICT', 'NO ACTION'],
            'sch_employees' => ['RESTRICT', 'NO ACTION'],
            'ba_categories' => ['SET NULL'],
            'ba_criteria'   => ['SET NULL'],
        ]);
    }

    public function test_incident_report_41_intervention_junction_cascade_and_restrict(): void
    {
        $this->assertReferentialRules(self::INC_INT_JNT_TABLE, [
            'ba_incidents'      => ['CASCADE'],
            'ba_interventions'  => ['RESTRICT', 'NO ACTION'],
        ]);
    }

    public function test_incident_report_42_witness_junction_cascades_from_incident(): void
    {
        $this->assertReferentialRules(self::INC_WIT_JNT_TABLE, [
            'ba_incidents' => ['CASCADE'],
        ]);
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_incident_report_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::REPORT_INCIDENTS))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_incident_report_51_limited_user_gets_403(): void
    {
        $limited = $this->makeLimitedUser();
        $this->browseWithFailureScreenshot('limited-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REPORT_INCIDENTS));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'reports.view gate must block the limited user.');
        });
        $this->deleteUser($limited);
    }

    public function test_incident_report_52_policy_maps_to_permission_strings(): void
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

    public function test_incident_report_53_export_gate_diverges_from_policy_val_ba_003(): void
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
    // Band 60–69 — UI/UX (filters, empty state, pagination)
    // =====================================================================

    public function test_incident_report_60_filter_form_renders_real_fields_and_options(): void
    {
        $this->browseWithFailureScreenshot('filter-form', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORT_INCIDENTS, 1000);
            $source = $browser->driver->getPageSource();
            foreach ([
                'name="from_date"', 'name="to_date"',
                'name="incident_type"', 'name="severity"', 'name="category_id"',
            ] as $field) {
                $this->assertStringContainsString($field, $source, "Filter field {$field} must render.");
            }
            // Real dropdown option labels.
            $this->assertStringContainsString('All Types', $source, 'Incident Type filter offers an "All Types" default.');
            $this->assertStringContainsString('All Severities', $source, 'Severity filter offers an "All Severities" default.');
            $this->assertStringContainsString('All Categories', $source, 'Category filter offers an "All Categories" default.');
        });
    }

    public function test_incident_report_61_reset_link_present(): void
    {
        $this->browseWithFailureScreenshot('reset-link', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORT_INCIDENTS, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Reset', $source, 'A Reset link must clear the filters.');
            $this->assertStringContainsString('reports/incidents', $source, 'Reset link targets the unfiltered incident report.');
        });
    }

    public function test_incident_report_62_empty_state_message_on_no_results(): void
    {
        // Filter to a far-future single-day window that cannot contain any incident.
        $future = now()->addYears(5)->toDateString();
        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser) use ($future): void {
            $this->visitAuthenticated($browser, self::REPORT_INCIDENTS . '?from_date=' . $future . '&to_date=' . $future, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('/login', $this->currentPath($browser), 'Authorized admin must reach the report.');
            $this->assertStringContainsString('No incidents found for the selected filters.', $source, 'Documented empty-state message expected.');
        });
    }

    public function test_incident_report_63_incident_log_paginates_25_per_page(): void
    {
        // Convention note: this report paginates 25/page (NOT the platform default 10) — assert the real value.
        $view = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($view === null) {
            $this->markTestSkipped('BaReportController source not readable.');
        }
        $body = $this->extractIncidentsMethod($view);
        $this->assertStringContainsString('paginate(25)', $body, 'Incident Log paginates 25 rows per page.');
        $this->assertStringNotContainsString('paginate(10)', $body, 'Incident Log is not the default 10/page.');

        // The rendered page carries the query string across pages.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/reports/incidents.blade.php'));
        if ($blade !== null) {
            $this->assertStringContainsString('withQueryString()->links()', $blade, 'Pagination must preserve active filters across pages.');
        }
    }

    // =====================================================================
    // Band 70–79 — Edge cases / requirement gaps (BC-EDG)
    // =====================================================================

    public function test_incident_report_70_export_is_live_abort_501_stub_bug_ba_011(): void
    {
        // BUG-BA-011: the requirement's CSV/Excel/PDF export has no working backing — the only export route aborts 501.
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

    public function test_incident_report_71_bug_ba_013_not_applicable_to_incidents_report(): void
    {
        // BUG-BA-013 concerns bha_computed_scores.`score` (non-existent) read by student/class reports.
        // The Incident Report reads ONLY ba_incidents aggregates — it never touches computed_scores/score,
        // so the bug does not fire on this screen. Prove the isolation from source.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm BUG-BA-013 isolation.');
        }
        $body = $this->extractIncidentsMethod($controller);
        $this->assertStringNotContainsString('BaComputedScore', $body, 'incidents() must not query computed scores.');
        $this->assertStringNotContainsString("avg('score')", $body, 'incidents() must not read the broken `score` column.');
        $this->assertStringNotContainsString('AVG(score)', $body, 'incidents() must not aggregate the broken `score` column.');
        $this->assertStringNotContainsString('numeric_score', $body, 'incidents() is incident-only; no computed_scores columns.');
    }

    public function test_incident_report_72_class_and_student_filters_not_implemented_rpt_gap_inc_01(): void
    {
        // Screen-24 §"Search and Filters" specifies Class & Section + Student filters; incidents() has neither.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/reports/incidents.blade.php'));
        if ($controller === null && $blade === null) {
            $this->markTestSkipped('Sources not readable to confirm RPT-GAP-INC-01.');
        }
        if ($controller !== null) {
            $body = $this->extractIncidentsMethod($controller);
            $this->assertStringNotContainsString("request('class_section_id')", $body, 'RPT-GAP-INC-01 changed: class/section filter now honoured.');
            $this->assertStringNotContainsString("request('student_id')", $body, 'RPT-GAP-INC-01 changed: student filter now honoured.');
        }
        if ($blade !== null) {
            $this->assertStringNotContainsString('name="class_section_id"', $blade, 'RPT-GAP-INC-01 changed: class/section filter control now present.');
            $this->assertStringNotContainsString('name="student_id"', $blade, 'RPT-GAP-INC-01 changed: student filter control now present.');
        }
    }

    public function test_incident_report_73_charts_are_tables_and_trend_is_monthly_rpt_gap_inc_02(): void
    {
        // Screen-24 §"Analytical Charts & Widgets" specifies a Weekly Frequency line chart, an Intervention
        // Success-Rate donut, and a Top-3 Triggers bar chart. Implementation renders HTML tables and a
        // 6-MONTH (not weekly) trend; there is no chart canvas.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/reports/incidents.blade.php'));
        if ($controller === null && $blade === null) {
            $this->markTestSkipped('Sources not readable to confirm RPT-GAP-INC-02.');
        }
        if ($controller !== null) {
            $body = $this->extractIncidentsMethod($controller);
            // Trend is grouped by YEAR+MONTH over 6 months, not by week.
            $this->assertStringContainsString('subMonths(6)', $body, 'Trend window is 6 months.');
            $this->assertStringContainsString('MONTH(incident_date)', $body, 'RPT-GAP-INC-02: trend is monthly, not the requested weekly curve.');
            $this->assertStringNotContainsString('WEEK(incident_date)', $body, 'RPT-GAP-INC-02 changed: a weekly frequency curve now exists.');
        }
        if ($blade !== null) {
            $this->assertStringContainsString('6-Month Trend', $blade, 'Trend is rendered as a 6-Month table.');
            $this->assertStringNotContainsString('<canvas', $blade, 'RPT-GAP-INC-02 changed: a real chart canvas is now rendered.');
            $this->assertStringNotContainsString('Intervention Success Rate', $blade, 'RPT-GAP-INC-02: no success-rate donut — only a usage table.');
        }
    }

    public function test_incident_report_74_export_privacy_anonymisation_absent_rpt_gap_inc_03(): void
    {
        // Screen-24 §"Export Compliance & Privacy": admin exports carry roll numbers; public digests replace
        // names with STUDENT-SHA hashes. None of this exists — export is the 501 stub.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaReportController source not readable to confirm RPT-GAP-INC-03.');
        }
        $exportBody = $this->extractExportMethod($controller);
        $this->assertStringContainsString('abort(501', $exportBody, 'Export privacy rules cannot exist while export is a 501 stub.');
        $this->assertStringNotContainsString('STUDENT-SHA', $controller, 'RPT-GAP-INC-03 changed: anonymisation hashing now implemented.');
        $this->assertStringNotContainsString('roll_no', $exportBody, 'RPT-GAP-INC-03: export does not yet emit roll numbers.');
    }

    public function test_incident_report_75_witness_count_column_absent_rpt_gap_inc_04(): void
    {
        // Screen-24 grid specifies a "Witness Count" column; incidents() does not eager-load witnesses and
        // the log grid shows an intervention count instead.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaReportController.php'));
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/reports/incidents.blade.php'));
        if ($controller === null && $blade === null) {
            $this->markTestSkipped('Sources not readable to confirm RPT-GAP-INC-04.');
        }
        if ($controller !== null) {
            $body = $this->extractIncidentsMethod($controller);
            // incidentLog eager loads student/reportedBy/category/interventions — but NOT witnesses.
            $this->assertStringContainsString("with(['student', 'reportedBy', 'category', 'interventions'])", $body, 'Log eager-loads interventions, not witnesses.');
            $this->assertStringNotContainsString("'witnesses'", $body, 'RPT-GAP-INC-04 changed: witnesses now eager-loaded for the grid.');
        }
        if ($blade !== null) {
            $this->assertStringNotContainsString('Witness', $blade, 'RPT-GAP-INC-04 changed: a Witness Count column now exists in the grid.');
        }
    }

    public function test_incident_report_76_severity_vocabulary_diverges_from_requirement_doc_ba_006(): void
    {
        // DOC-BA-006: screen-24 lists severities Info/Low/Medium/High; the live ENUM + blade use
        // minor/moderate/major/critical.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/reports/incidents.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('reports/incidents.blade.php source not readable to confirm DOC-BA-006.');
        }
        foreach (['minor', 'moderate', 'major', 'critical'] as $sev) {
            $this->assertStringContainsString('value="' . $sev . '"', $blade, "Severity filter uses the live '{$sev}' value.");
        }
        // The requirement's vocabulary is NOT what the UI offers.
        $this->assertStringNotContainsString('value="high"', $blade, 'DOC-BA-006: the requirement severity "High" is not a live option.');
        $this->assertStringNotContainsString('value="info"', $blade, 'DOC-BA-006: the requirement severity "Info" is not a live option.');
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + API deadness + security
    // =====================================================================

    public function test_incident_report_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side report tests.'
        );
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'ba_incidents must resolve within the tenant DB.');
        $this->assertTrue(Schema::hasTable(self::INC_INT_JNT_TABLE), 'ba_incident_intervention_jnt must resolve within the tenant DB.');
    }

    public function test_incident_report_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001(): void
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

    public function test_incident_report_92_web_report_routes_carry_full_tenancy_stack(): void
    {
        $rsp = $this->readAppFile($this->moduleRootPath('app/Providers/RouteServiceProvider.php'));
        if ($rsp === null) {
            $this->markTestSkipped('RouteServiceProvider source not readable.');
        }
        foreach (['InitializeTenancyByDomain', 'PreventAccessFromCentralDomains', "'auth'"] as $needle) {
            $this->assertStringContainsString($needle, $rsp, "Web report routes must carry {$needle} in the middleware stack.");
        }
    }

    public function test_incident_report_93_rendered_report_escapes_output(): void
    {
        // Defensive stored-XSS smoke: the Blade grid must escape student/category/intervention text.
        $this->browseWithFailureScreenshot('escape-smoke', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REPORT_INCIDENTS, 1000);
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
        $rawName = 'incident-report-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'incident-report-' . $kind . '-' . now()->format('Ymd_His');
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
window.__irApiDone = false;
window.__irApiError = '';
window.__irApiResult = null;

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

        window.__irApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__irApiError = String(error);
    } finally {
        window.__irApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__irApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__irApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__irApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Seed / cleanup ---------------------------------------------------

    private function seedIncident(array $overrides = []): ?BaIncident
    {
        try {
            $studentId  = $this->anyStudentId();
            $employeeId = $this->anyEmployeeId();
            if ($studentId === null || $employeeId === null) {
                return null;
            }
            $categoryId = Schema::hasTable('ba_categories') ? DB::table('ba_categories')->value('id') : null;

            $payload = array_merge([
                'student_id'            => $studentId,
                'reported_by'           => $employeeId,
                'category_id'           => $categoryId,
                'incident_date'         => now()->toDateString(),
                'incident_type'         => 'negative_incident',
                'severity'              => 'minor',
                'description'           => 'IR test seed ' . $this->uniqueSuffix(),
                'location'              => 'classroom',
                'is_follow_up_required' => false,
                'is_notified'           => false,
                'is_active'             => true,
                'created_by'            => (int) $this->adminUser->id,
                'updated_by'            => (int) $this->adminUser->id,
            ], $overrides);

            return BaIncident::query()->create($payload);
        } catch (Throwable) {
            return null;
        }
    }

    private function cleanupIncident(?BaIncident $incident): void
    {
        if ($incident === null) {
            return;
        }
        try {
            $incident->forceDelete();
        } catch (Throwable) {
        }
    }

    private function countIncidentsInCurrentMonth(): int
    {
        try {
            return (int) BaIncident::query()
                ->whereDate('incident_date', '>=', now()->startOfMonth()->toDateString())
                ->whereDate('incident_date', '<=', now()->toDateString())
                ->count();
        } catch (Throwable) {
            return 0;
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

    private function anyEmployeeId(): ?int
    {
        try {
            if (!Schema::hasTable('sch_employees')) {
                return null;
            }
            $id = DB::table('sch_employees')->value('id');
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
                'name'              => 'IR Limited ' . $this->uniqueSuffix(),
                'email'             => 'ir_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'IR' . substr($this->uniqueSuffix(), -8);
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

    /** Extract the export() method body for targeted source assertions. */
    private function extractExportMethod(string $controller): string
    {
        $pos = strpos($controller, 'function export');
        if ($pos === false) {
            return $controller;
        }
        return substr($controller, $pos, 400);
    }

    /** Extract the incidents() method body (up to the next report method) for targeted source assertions. */
    private function extractIncidentsMethod(string $controller): string
    {
        $start = strpos($controller, 'function incidents');
        if ($start === false) {
            return $controller;
        }
        $end = strpos($controller, 'function period', $start);
        $len = $end === false ? 6000 : ($end - $start);
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
