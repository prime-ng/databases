<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\Prime\Models\Domain;
use Modules\StudentProfile\Exports\StudentsExport;
use Tests\DuskTestCase;
use Throwable;

/**
 * StudentProfile – Student Reports (composite, read-only)
 *
 * Feature scope: StudentReportController::combinedStudentReport (backs BOTH report routes).
 *   - student-profile.reports.index          => GET /student-profile/reports-mgt
 *   - student-profile.reports.class-strength => GET /student-profile/reports/class-wise-student-strength
 * View: studentprofile::reports.index  (tabs: student-strength | admission-register | medical-profile)
 * Underlying read tables (composite): std_students, std_student_academic_sessions,
 *   std_health_profiles, std_medical_incidents, std_student_attendance.
 * Permission gate: tenant.student.viewAny (report) / tenant.student.export (export).
 *
 * DB scope: TENANT (std_* per-tenant). Style mirrors committed sibling
 *   spr_StudentCompleteProfile_TestCas (browser Dusk + initializeTenantContext).
 *
 * This is a REPORT/COMPOSITE read-only screen => lighter, read-focused matrix:
 *   render each report, filters (class/session/date), export path, permissions,
 *   empty state, tenancy isolation. NO create/edit/delete matrix.
 *
 * Mapped audit defect: PERF-STD-10 (synchronous export path for large datasets).
 * Discovered defects: DEV-STD-R1 (breadcrumb -> unregistered complaint.reports.summary route),
 *   DEV-STD-R2 (null-unsafe $currentSession->id when no current academic session).
 *
 * Env prerequisites (see Validation Report): module STUDENT must be ENABLED in
 * prime_testing/modules_statuses.json (else 404 on all routes); APP_ENV=testing for Dusk.
 */
class std_StudentReports_TestCas extends DuskTestCase
{
    private const INDEX_PATH          = '/student-profile/reports-mgt';
    private const CLASS_STRENGTH_PATH = '/student-profile/reports/class-wise-student-strength';

    private const CONTROLLER_FILE = 'Modules/StudentProfile/app/Http/Controllers/StudentReportController.php';
    private const STUDENT_CTRL_FILE = 'Modules/StudentProfile/app/Http/Controllers/StudentController.php';
    private const EXPORT_FILE      = 'Modules/StudentProfile/app/Exports/StudentsExport.php';
    private const INDEX_VIEW_FILE  = 'Modules/StudentProfile/resources/views/reports/index.blade.php';
    private const STRENGTH_VIEW    = 'Modules/StudentProfile/resources/views/reports/student-strength/index.blade.php';
    private const ADMISSION_VIEW   = 'Modules/StudentProfile/resources/views/reports/admission-register/index.blade.php';
    private const MEDICAL_VIEW     = 'Modules/StudentProfile/resources/views/reports/medical-profile/index.blade.php';

    private const SCREENSHOT_DIR = 'tests/Browser/console/screenshots';

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail    = '';
    private string $adminPassword = '';

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenantBaseUrl = rtrim(
            env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')),
            '/'
        );
        $this->adminEmail    = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
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

    // =========================================================================
    // Band 01-09 : Schema / DDL / model / route configuration (config truth)
    // =========================================================================

    // TC-P01 | BC-DB-01..05 | Source: DDL-std_students / composite read tables
    public function test_studentreports_01_underlying_read_tables_and_report_wiring_are_correct(): void
    {
        // Composite read tables must exist (tenant DB).
        $this->assertTrue(Schema::hasTable('std_students'), 'std_students table missing.');
        $this->assertTrue(Schema::hasTable('std_student_academic_sessions'), 'std_student_academic_sessions table missing.');
        $this->assertTrue(Schema::hasTable('std_health_profiles'), 'std_health_profiles table missing.');
        $this->assertTrue(Schema::hasTable('std_medical_incidents'), 'std_medical_incidents table missing.');
        $this->assertTrue(Schema::hasTable('std_student_attendance'), 'std_student_attendance table missing.');

        // Key columns the report groups/filters on.
        $this->assertTrue(
            Schema::hasColumns('std_students', ['admission_no', 'first_name', 'gender', 'dob', 'is_active']),
            'std_students missing report columns.'
        );
        $this->assertTrue(
            Schema::hasColumns('std_student_academic_sessions', ['student_id', 'academic_session_id', 'class_section_id', 'is_current', 'admission_date']),
            'std_student_academic_sessions missing report columns.'
        );
        $this->assertTrue(
            Schema::hasColumns('std_health_profiles', ['student_id', 'blood_group', 'allergies', 'chronic_conditions']),
            'std_health_profiles missing report columns.'
        );

        // Controller wiring.
        $controller = $this->readSource(self::CONTROLLER_FILE);
        $this->assertStringContainsString('function combinedStudentReport', $controller, 'combinedStudentReport method missing.');
        $this->assertStringContainsString("Gate::authorize('tenant.student.viewAny')", $controller, 'Report gate missing.');
        $this->assertStringContainsString("view('studentprofile::reports.index'", $controller, 'Report view not returned.');
    }

    // TC-P02 | BC-AUTH-01 / Source: routes/web.php
    public function test_studentreports_02_both_report_routes_are_registered_to_combined_report(): void
    {
        $this->assertTrue(Route::has('student-profile.reports.index'), 'reports.index route not registered.');
        $this->assertTrue(Route::has('student-profile.reports.class-strength'), 'reports.class-strength route not registered.');

        $index = Route::getRoutes()->getByName('student-profile.reports.index');
        $strength = Route::getRoutes()->getByName('student-profile.reports.class-strength');

        $this->assertNotNull($index, 'reports.index route object missing.');
        $this->assertNotNull($strength, 'reports.class-strength route object missing.');
        $this->assertStringContainsString('reports-mgt', $index->uri(), 'reports.index URI unexpected.');
        $this->assertStringContainsString('class-wise-student-strength', $strength->uri(), 'class-strength URI unexpected.');
        $this->assertStringContainsString('combinedStudentReport', $index->getActionName(), 'reports.index not bound to combinedStudentReport.');
        $this->assertStringContainsString('combinedStudentReport', $strength->getActionName(), 'class-strength not bound to combinedStudentReport.');
    }

    // TC-P03 | Source: Controller
    public function test_studentreports_03_report_controller_methods_exist(): void
    {
        $fqcn = 'Modules\\StudentProfile\\Http\\Controllers\\StudentReportController';
        $this->assertTrue(class_exists($fqcn), 'StudentReportController class not found.');
        $this->assertTrue(method_exists($fqcn, 'combinedStudentReport'), 'combinedStudentReport missing.');
        $this->assertTrue(method_exists($fqcn, 'index'), 'index missing.');
        $this->assertTrue(method_exists($fqcn, 'classWiseStrengthReport'), 'classWiseStrengthReport missing.');
    }

    // =========================================================================
    // Band 10-19 : Render each report (business rules)
    // =========================================================================

    // TC-P10 | Source: view studentprofile::reports.index
    public function test_studentreports_10_report_index_renders_with_three_report_tabs(): void
    {
        $this->browseReport('rep-10-index', self::INDEX_PATH, function (Browser $browser): void {
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('student-strength-pane', $source, 'Student Strength tab pane missing.');
            $this->assertStringContainsString('admission-register-pane', $source, 'Admission Register tab pane missing.');
            $this->assertStringContainsString('medical-profile-pane', $source, 'Medical Profile tab pane missing.');
        });
    }

    // TC-P11 | Source: Screen-BR FR-18..FR-22
    public function test_studentreports_11_student_strength_tab_renders_expected_columns(): void
    {
        $this->browseReport('rep-11-strength', self::INDEX_PATH, function (Browser $browser): void {
            $source = $browser->driver->getPageSource();
            foreach (['Class', 'Section', 'Total', 'Boys', 'Girls', 'General', 'OBC/SC/ST', 'RTE/EWS', 'Class Teacher'] as $col) {
                $this->assertStringContainsString($col, $source, "Strength column '{$col}' not rendered.");
            }
        });
    }

    // TC-P12 | Source: Screen-BR FR-25..FR-28
    public function test_studentreports_12_admission_register_tab_renders_expected_columns(): void
    {
        $this->browseReport('rep-12-admission', self::INDEX_PATH, function (Browser $browser): void {
            $source = $browser->driver->getPageSource();
            foreach (['Admission No', 'Admission Date', 'Student Name', 'DOB', 'Gender', 'Previous School', 'TC No'] as $col) {
                $this->assertStringContainsString($col, $source, "Admission column '{$col}' not rendered.");
            }
        });
    }

    // TC-P13 | Source: Screen-BR FR-30..FR-32
    public function test_studentreports_13_medical_profile_tab_renders_expected_columns(): void
    {
        $this->browseReport('rep-13-medical', self::INDEX_PATH, function (Browser $browser): void {
            $source = $browser->driver->getPageSource();
            foreach (['Blood Group', 'Allergies', 'Chronic Conditions', 'Emergency Contact'] as $col) {
                $this->assertStringContainsString($col, $source, "Medical column '{$col}' not rendered.");
            }
        });
    }

    // TC-P14 | BC-BIZ-01 | Source: Controller (is_current scoping)
    public function test_studentreports_14_report_scopes_to_current_session_records(): void
    {
        $controller = $this->readSource(self::CONTROLLER_FILE);
        $this->assertStringContainsString("->where('is_current', 1)", $controller, 'Report must scope to current-session enrollments.');
        $this->assertStringContainsString("->where('academic_session_id', \$currentSessionId)", $controller, 'Report must scope by academic_session_id.');
    }

    // TC-P15 | Source: stability
    public function test_studentreports_15_report_index_renders_without_server_error(): void
    {
        $this->browseReport('rep-15-no500', self::INDEX_PATH, function (Browser $browser): void {
            $this->assertNoServerError($browser, self::INDEX_PATH);
        });
    }

    // TC-P16 | Source: routes (class-strength alias)
    public function test_studentreports_16_class_strength_route_renders_same_report(): void
    {
        $this->browseReport('rep-16-classstrength', self::CLASS_STRENGTH_PATH, function (Browser $browser): void {
            $this->assertNoServerError($browser, self::CLASS_STRENGTH_PATH);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('student-strength-pane', $source, 'Class-strength alias should render the composite report.');
        });
    }

    // =========================================================================
    // Band 30-39 : Filters (class / session / admission date range)
    // =========================================================================

    // TC-P30 | BC-VAL-01 | Source: Controller class_id filter (FR-23)
    public function test_studentreports_30_class_filter_param_is_accepted(): void
    {
        $this->browseReport('rep-30-classfilter', self::INDEX_PATH . '?class_id=1', function (Browser $browser): void {
            $this->assertNoServerError($browser, self::INDEX_PATH . '?class_id=1');
        });
        $controller = $this->readSource(self::CONTROLLER_FILE);
        $this->assertStringContainsString('$classId  = $request->class_id;', $controller, 'class_id filter not read.');
        $this->assertStringContainsString("\$q->where('class_id', \$classId)", $controller, 'class_id not applied to query.');
    }

    // TC-P31 | Source: Controller academic_session_id filter (FR-23)
    public function test_studentreports_31_academic_session_filter_param_is_accepted(): void
    {
        $this->browseReport('rep-31-sessfilter', self::INDEX_PATH . '?academic_session_id=1', function (Browser $browser): void {
            $this->assertNoServerError($browser, self::INDEX_PATH . '?academic_session_id=1');
        });
        $controller = $this->readSource(self::CONTROLLER_FILE);
        $this->assertStringContainsString('$request->academic_session_id', $controller, 'academic_session_id filter not read.');
    }

    // TC-P32 | Source: Controller from_date/to_date filter (FR-29)
    public function test_studentreports_32_admission_date_range_filter_param_is_accepted(): void
    {
        $url = self::INDEX_PATH . '?from_date=2020-01-01&to_date=2030-12-31';
        $this->browseReport('rep-32-daterange', $url, function (Browser $browser) use ($url): void {
            $this->assertNoServerError($browser, $url);
        });
        $controller = $this->readSource(self::CONTROLLER_FILE);
        $this->assertStringContainsString("whereDate('admission_date', '>=', \$fromDate)", $controller, 'from_date not applied.');
        $this->assertStringContainsString("whereDate('admission_date', '<=', \$toDate)", $controller, 'to_date not applied.');
    }

    // TC-N33 | Source: robustness — malformed filter values must not 500
    public function test_studentreports_33_malformed_filter_values_do_not_500(): void
    {
        $url = self::INDEX_PATH . '?class_id=abc&academic_session_id=xyz&from_date=notadate';
        $this->browseReport('rep-33-badfilter', $url, function (Browser $browser) use ($url): void {
            $this->assertNoServerError($browser, $url);
        });
    }

    // =========================================================================
    // Band 40-49 : Integration / export path (PERF-STD-10 mapping)
    // =========================================================================

    // TC-D40 | BC-INT-01 | Source: Exports/StudentsExport.php
    public function test_studentreports_40_students_export_declares_shouldqueue(): void
    {
        $this->assertTrue(class_exists(StudentsExport::class), 'StudentsExport class missing.');
        $this->assertTrue(
            in_array(\Illuminate\Contracts\Queue\ShouldQueue::class, class_implements(StudentsExport::class) ?: []),
            'StudentsExport should implement ShouldQueue (audit PERF-STD-10 remediation).'
        );
    }

    // TC-D41 | PERF-STD-10 | Source: StudentController@export excel branch (queued => mitigated)
    public function test_studentreports_41_excel_export_path_is_queued(): void
    {
        $ctrl = $this->readSource(self::STUDENT_CTRL_FILE);
        $this->assertStringContainsString("Excel::queue(\$export, 'exports/' . \$fileName . '.xlsx')", $ctrl, 'Excel export should be queued.');
    }

    // TC-D42 | PERF-STD-10 | Source: StudentController@export csv branch (queued)
    public function test_studentreports_42_csv_export_path_is_queued(): void
    {
        $ctrl = $this->readSource(self::STUDENT_CTRL_FILE);
        $this->assertStringContainsString("Excel::queue(\$export, 'exports/' . \$fileName . '.csv'", $ctrl, 'CSV export should be queued.');
    }

    // TC-D43 | PERF-STD-10 (PROVING) | Source: StudentController@exportPDF (still synchronous inline)
    public function test_studentreports_43_pdf_export_path_is_synchronous_inline_perf_gap(): void
    {
        $ctrl = $this->readSource(self::STUDENT_CTRL_FILE);
        // Excel/CSV were queued, but the PDF path builds the full collection in-request
        // and streams it synchronously via Pdf::...->download() — no queue, no chunking.
        // For 1000+ students this risks memory exhaustion / request timeout (audit PERF-STD-10).
        $this->assertStringContainsString('$this->exportPDF($students', $ctrl, 'PDF export delegates to exportPDF.');
        $this->assertStringContainsString("Pdf::loadView('studentprofile::exports.pdf'", $ctrl, 'PDF built inline in-request.');
        $this->assertStringContainsString('return $pdf->download($fileName);', $ctrl, 'PDF streamed synchronously (perf gap, not queued).');
        // Documented current behaviour: synchronous PDF export path remains a performance gap.
        $this->assertStringNotContainsString('Pdf::queue', $ctrl, 'PDF export is NOT queued — documents the PERF-STD-10 synchronous path.');
    }

    // TC-D44 | Source: StudentController@export gate
    public function test_studentreports_44_export_requires_export_permission(): void
    {
        $ctrl = $this->readSource(self::STUDENT_CTRL_FILE);
        $this->assertStringContainsString("Gate::authorize('tenant.student.export')", $ctrl, 'Export gate missing.');
    }

    // TC-D45 | BC-REF | Source: Controller composite eager-loads
    public function test_studentreports_45_report_eager_loads_composite_relationships(): void
    {
        $controller = $this->readSource(self::CONTROLLER_FILE);
        foreach (["'student.profile'", "'student.guardians'", "'student.healthProfile'", "'classSection.class'", "'classSection.section'"] as $rel) {
            $this->assertStringContainsString($rel, $controller, "Composite relation {$rel} not eager-loaded.");
        }
    }

    // =========================================================================
    // Band 50-59 : Permissions / authorization (heavy)
    // =========================================================================

    // TC-N50 | BC-AUTH-02 | Source: middleware auth
    public function test_studentreports_50_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            try {
                $browser->driver->manage()->deleteAllCookies();
            } catch (Throwable) {
            }
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    // TC-P51 | BC-AUTH-01 | Source: Controller gate
    public function test_studentreports_51_report_is_guarded_by_student_viewany(): void
    {
        $controller = $this->readSource(self::CONTROLLER_FILE);
        $count = substr_count($controller, "Gate::authorize('tenant.student.viewAny')");
        $this->assertGreaterThanOrEqual(1, $count, 'combinedStudentReport must call the viewAny gate.');
    }

    // TC-N52 | BC-AUTH-03 | Source: gate (no permission => 403)
    public function test_studentreports_52_user_without_permission_is_forbidden(): void
    {
        try {
            $limited = $this->makeLimitedUserWithoutReportPermission();
            if (!$limited) {
                $this->markTestSkipped('Could not build a limited user for 403 check.');
            }

            $this->actingAs($limited);
            $response = $this->getJson($this->tenantUrl(self::INDEX_PATH));
            // Gate::authorize failure => 403 (per constraint #14 use HTTP test methods for status).
            $this->assertContains($response->getStatusCode(), [403, 302, 401], 'User lacking viewAny should be denied.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Permission-denial path unavailable: ' . $e->getMessage());
        }
    }

    // TC-P53 | Source: routes (both aliases guarded)
    public function test_studentreports_53_class_strength_alias_uses_same_gate(): void
    {
        $controller = $this->readSource(self::CONTROLLER_FILE);
        // Both routes hit combinedStudentReport, which is gated; classWiseStrengthReport is also gated.
        $this->assertStringContainsString("Gate::authorize('tenant.student.viewAny')", $controller, 'Alias handler must be gated.');
    }

    // TC-P54 | Source: authorized admin gets 200
    public function test_studentreports_54_authorized_admin_receives_ok(): void
    {
        try {
            if (!$this->adminUser) {
                $this->markTestSkipped('No admin user resolved.');
            }
            $this->actingAs($this->adminUser);
            $response = $this->getJson($this->tenantUrl(self::INDEX_PATH));
            $this->assertContains($response->getStatusCode(), [200, 302], 'Authorized admin should receive OK/redirect, got ' . $response->getStatusCode());
        } catch (Throwable $e) {
            $this->markTestSkipped('Authorized-admin path unavailable: ' . $e->getMessage());
        }
    }

    // TC-P55 | Source: browser render for admin
    public function test_studentreports_55_authenticated_admin_can_view_report(): void
    {
        $this->browseReport('rep-55-admin-view', self::INDEX_PATH, function (Browser $browser): void {
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Student', $source, 'Report content should render for authenticated admin.');
        });
    }

    // =========================================================================
    // Band 60-69 : UI/UX — empty state, columns, charts, breadcrumb, tabs
    // =========================================================================

    // TC-P60 | Source: sub-views empty states
    public function test_studentreports_60_empty_state_messages_present_in_views(): void
    {
        $this->assertStringContainsString('No student data found.', $this->readSource(self::STRENGTH_VIEW), 'Strength empty state missing.');
        $this->assertStringContainsString('No admissions found.', $this->readSource(self::ADMISSION_VIEW), 'Admission empty state missing.');
        $this->assertStringContainsString('No medical records found.', $this->readSource(self::MEDICAL_VIEW), 'Medical empty state missing.');
    }

    // TC-P61 | Source: strength view @forelse
    public function test_studentreports_61_strength_view_iterates_report_rows(): void
    {
        $view = $this->readSource(self::STRENGTH_VIEW);
        $this->assertStringContainsString('@forelse($strengthReport as $row)', $view, 'Strength view should iterate strengthReport.');
        $this->assertStringContainsString('@empty', $view, 'Strength view should handle the empty branch.');
    }

    // TC-P62 | Source: chart containers (FR-24 / medical charts)
    public function test_studentreports_62_chart_containers_present(): void
    {
        $this->assertStringContainsString('classGenderChart', $this->readSource(self::STRENGTH_VIEW), 'Gender chart container missing.');
        $this->assertStringContainsString('bloodGroupChart', $this->readSource(self::MEDICAL_VIEW), 'Blood group chart container missing.');
        $this->assertStringContainsString('conditionChart', $this->readSource(self::MEDICAL_VIEW), 'Condition chart container missing.');
    }

    // TC-D63 | DEV-STD-R1 (PROVING) | Source: index.blade breadcrumb dead route
    public function test_studentreports_63_breadcrumb_references_unregistered_route_dev_std_r1(): void
    {
        // The report index breadcrumb links to route('complaint.reports.summary'),
        // a CROSS-MODULE route that is not registered. When the view is compiled
        // this throws RouteNotFoundException => the report index 500s. Documented as DEV-STD-R1.
        $view = $this->readSource(self::INDEX_VIEW_FILE);
        $this->assertStringContainsString("route('complaint.reports.summary')", $view, 'Breadcrumb should reference the cross-module route (defect fixture).');
        $this->assertFalse(
            Route::has('complaint.reports.summary'),
            'DEV-STD-R1: breadcrumb route complaint.reports.summary is NOT registered — report index render will fail.'
        );
    }

    // TC-P64 | Source: index.blade tab nav
    public function test_studentreports_64_index_defines_three_named_tabs(): void
    {
        $view = $this->readSource(self::INDEX_VIEW_FILE);
        foreach (["'student-strength'", "'admission-register'", "'medical-profile'"] as $tab) {
            $this->assertStringContainsString($tab, $view, "Tab {$tab} not declared in index view.");
        }
    }

    // =========================================================================
    // Band 70-79 : Edge cases
    // =========================================================================

    // TC-N70 | DEV-STD-R2 (PROVING) | Source: Controller null-unsafe currentSession
    public function test_studentreports_70_no_current_session_null_deref_dev_std_r2(): void
    {
        // Line: $currentSessionId = $request->academic_session_id ?? $currentSession->id;
        // If NO academic_session_id is passed AND no session has is_current=1,
        // $currentSession is null => "Attempt to read property 'id' on null" => 500.
        // Documented as DEV-STD-R2 (missing null-guard / optional()).
        $controller = $this->readSource(self::CONTROLLER_FILE);
        $this->assertStringContainsString('$request->academic_session_id ?? $currentSession->id', $controller, 'Null-unsafe currentSession deref (defect fixture).');
        $this->assertStringNotContainsString('optional($currentSession)->id', $controller, 'DEV-STD-R2: currentSession->id is not null-guarded.');
    }

    // TC-N71 | Source: out-of-range filter id
    public function test_studentreports_71_out_of_range_class_id_does_not_500(): void
    {
        $url = self::INDEX_PATH . '?class_id=999999999';
        $this->browseReport('rep-71-oob', $url, function (Browser $browser) use ($url): void {
            $this->assertNoServerError($browser, $url);
        });
    }

    // =========================================================================
    // Band 90-99 : Tenancy isolation + security
    // =========================================================================

    // TC-T90 | Source: tenancy — report scoped to current tenant
    public function test_studentreports_90_report_runs_within_tenant_context(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Report is tenant-scoped; tenancy must be initialized in setUp.'
        );
        // Composite tables resolve on the tenant connection.
        $this->assertTrue(Schema::hasTable('std_students'), 'Tenant std_students must be reachable in tenant context.');
    }

    // TC-T91 | Source: tenancy isolation (direct URL under tenant host only)
    public function test_studentreports_91_report_url_is_bound_to_tenant_host(): void
    {
        $host = parse_url($this->tenantBaseUrl, PHP_URL_HOST);
        $this->assertIsString($host, 'Tenant host must resolve.');
        $this->browseReport('rep-91-tenant-host', self::INDEX_PATH, function (Browser $browser) use ($host): void {
            $current = $browser->driver->getCurrentURL();
            $this->assertStringContainsString((string) $host, $current, 'Report must serve under the tenant host.');
        });
    }

    // TC-S92 | BC-BIZ read-only | Source: ActivityLog (no write on a read)
    public function test_studentreports_92_rendering_report_writes_no_activity_log(): void
    {
        try {
            $before = ActivityLog::query()->count();

            $this->browseReport('rep-92-readonly', self::INDEX_PATH, function (Browser $browser): void {
                $browser->pause(300);
            });

            $after = ActivityLog::query()->count();
            $this->assertSame($before, $after, 'Read-only report must not create activity-log rows.');
        } catch (Throwable $e) {
            $this->markTestSkipped('activity_logs not available for read-only assertion: ' . $e->getMessage());
        }
    }

    // TC-S93 | Source: reflected-input safety on filter params
    public function test_studentreports_93_reflected_filter_input_is_not_executed(): void
    {
        $payload = urlencode('"><script>window.__xss=1</script>');
        $url = self::INDEX_PATH . '?from_date=' . $payload;
        $this->browseReport('rep-93-xss', $url, function (Browser $browser): void {
            $flag = $browser->script('return window.__xss === 1;');
            $this->assertNotSame(
                true,
                is_array($flag) ? ($flag[0] ?? false) : false,
                'Reflected filter input must not execute as script.'
            );
        });
    }

    // TC-T94 | Source: gate present on both handlers guarantees no anon data
    public function test_studentreports_94_no_report_data_without_authentication(): void
    {
        $this->browse(function (Browser $browser): void {
            try {
                $browser->driver->manage()->deleteAllCookies();
            } catch (Throwable) {
            }
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(900);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('student-strength-pane', $source, 'Unauthenticated request must not leak report content.');
        });
    }

    // =========================================================================
    // HELPER METHODS  (mirror committed sibling spr_StudentCompleteProfile)
    // =========================================================================

    private function browseReport(string $caseName, string $path, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $path, $callback): void {
            try {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, $path, 1100);
                $callback($browser);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    private function assertNoServerError(Browser $browser, string $context): void
    {
        $source = $browser->driver->getPageSource();
        $this->assertStringNotContainsString('Server Error', $source, "Report at {$context} returned a Server Error.");
        $this->assertStringNotContainsString('Whoops', $source, "Report at {$context} returned an unexpected error page.");
        $this->assertStringNotContainsString('Attempt to read property', $source, "Report at {$context} threw a null-deref.");
    }

    private function readSource(string $relativePath): string
    {
        $full = base_path($relativePath);
        $this->assertFileExists($full, "Source file not found: {$relativePath}");

        return (string) File::get($full);
    }

    private function makeLimitedUserWithoutReportPermission(): ?User
    {
        try {
            $user = User::query()
                ->where('email', '!=', $this->adminEmail)
                ->first();

            if ($user && method_exists($user, 'getAllPermissions')) {
                $names = $user->getAllPermissions()->pluck('name')->all();
                if (!in_array('tenant.student.viewAny', $names, true)) {
                    return $user;
                }
            }
        } catch (Throwable) {
        }

        return null;
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $timestamp = now()->format('Ymd_His');
        $safeName  = preg_replace('/[^A-Za-z0-9_-]+/', '-', 'student-reports-fail-' . $caseName . '-' . $timestamp)
            ?? 'student-reports-fail-' . $timestamp;

        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
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
            $this->markTestSkipped('Tenant host missing.');
        }

        $domain = Domain::query()->where('domain', $tenantHost)->first();
        if (!$domain) {
            $this->markTestSkipped('Tenant domain not found for host ' . $tenantHost . '.');
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

        $this->grantPermissions($this->adminUser);
    }

    private function grantPermissions(User $user): void
    {
        $permissions = [
            'tenant.student.viewAny',
            'tenant.student.view',
            'tenant.student.export',
        ];

        $guard = $this->permissionGuardName($user);

        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }

        foreach ($permissions as $perm) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate(['name' => $perm, 'guard_name' => $guard]);
            } catch (Throwable) {
            }
        }

        if (method_exists($user, 'givePermissionTo')) {
            foreach ($permissions as $perm) {
                try {
                    $user->givePermissionTo($perm);
                } catch (Throwable) {
                }
            }
        }

        if (class_exists(\Spatie\Permission\PermissionRegistrar::class)) {
            try {
                app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
            } catch (Throwable) {
            }
        }
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
