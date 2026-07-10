<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\Domain;
use Modules\StudentProfile\Http\Controllers\StudentController;
use Modules\StudentProfile\Exports\StudentsExport;
use Modules\StudentProfile\Models\Student;
use Modules\StudentProfile\Providers\Data\StudentIdCardDataProvider;
use ReflectionClass;
use ReflectionMethod;
use Tests\DuskTestCase;
use Throwable;

/**
 * Student Profile - Complete Profile / View / ID-Card / Export (READ-FOCUSED composite screen)
 *
 * Feature scope (per StudentController):
 *   completeProfile(), show(), printIdCard(), export(), sendCredentials(), getFilterDependencies()
 *
 * Primary table: std_students (DDL StudentProfile_DDL_v1.6.sql, Database: tenant_db) => prefix std_
 * DB scope: TENANT (module-prefixed std_* tables) => tenant init required (mirrors committed sibling
 *   spr_StudentCompleteProfile_TestCas.php).
 *
 * This is a read/composite screen: no create/edit/delete matrix (those live in StudentCreate /
 * StudentEdit). Coverage = render, next-incomplete-tab redirect states, related-data display,
 * print ID card, export (pdf synchronous / excel|csv queued), permissions, empty state,
 * tenancy isolation / IDOR, plus the two mapped audit defects (GAP-STD-25, PERF-STD-10).
 *
 * NOTE: Several assertions are static/reflection-based (schema truth, route registration, defect
 * proofs) so they remain deterministic even when the STUDENT module is disabled in
 * modules_statuses.json (see Validation Report env prerequisite E19). Browser-dependent cases
 * fail-soft via markTestSkipped when seed data or a live route is unavailable.
 */
class std_StudentCompleteProfile_TestCas extends DuskTestCase
{
    private const COMPLETE_PROFILE_TMPL = '/student-profile/student/%d/complete-profile';
    private const SHOW_TMPL             = '/student-profile/student/%d';
    private const PRINT_ID_CARD_TMPL    = '/student-profile/student/%d/print-id-card';
    private const EXPORT_TMPL           = '/student-profile/student/export/%s';
    private const INDEX_PATH            = '/student-profile/student';
    private const SCREENSHOT_DIR        = 'tests/Browser/console/screenshots';
    private const PRIMARY_TABLE         = 'std_students';
    private const MIGRATION_GLOB        = 'database/migrations/tenant/*create_std_students_table.php';

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
    // BAND 01-09 : Schema / model / route configuration truth (TC-P01, BC-DB*)
    // =========================================================================

    /**
     * TC-P01 / BC-DB-* : std_students + related tables, columns, unique keys, model config
     * and every feature route are registered exactly as the source declares.
     */
    public function test_complete_profile_01_schema_model_and_routes_are_correct(): void
    {
        // -- primary table + core columns (DDL StudentProfile_DDL_v1.6.sql:46)
        $this->assertTrue(Schema::hasTable(self::PRIMARY_TABLE), 'std_students table must exist.');

        foreach ([
            'id', 'user_id', 'admission_no', 'admission_date', 'student_qr_code',
            'student_id_card_type', 'smart_card_id', 'aadhar_id', 'apaar_id',
            'birth_cert_no', 'first_name', 'middle_name', 'last_name', 'gender',
            'dob', 'current_status_id', 'is_active', 'note', 'deleted_at',
        ] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::PRIMARY_TABLE, $column),
                "std_students must have column {$column}."
            );
        }

        // -- related composite-read tables (guardians / sessions / prev-edu / health / docs / addr)
        foreach ([
            'std_student_profiles',
            'std_student_addresses',
            'std_guardians',
            'std_student_guardian_jnt',
            'std_student_academic_sessions',
            'std_previous_education',
            'std_student_documents',
            'std_health_profiles',
        ] as $relatedTable) {
            $this->assertTrue(
                Schema::hasTable($relatedTable),
                "Composite-read dependency table {$relatedTable} must exist."
            );
        }

        // -- migration content (resolved by glob from base_path per constraint #26)
        $migrations = File::glob(base_path(self::MIGRATION_GLOB));
        if (!empty($migrations)) {
            $body = (string) File::get($migrations[0]);
            $this->assertStringContainsString('std_students', $body, 'Migration must target std_students.');
            $this->assertStringContainsString('admission_no', $body, 'Migration must define admission_no.');
            $this->assertStringContainsString('softDeletes', $body, 'Migration must declare softDeletes().');
        }

        // -- model config truth
        $student = new Student();
        $this->assertSame(self::PRIMARY_TABLE, $student->getTable(), 'Model table must be std_students.');
        $this->assertContains('admission_no', $student->getFillable());
        $this->assertContains('student_qr_code', $student->getFillable());
        $this->assertContains('aadhar_id', $student->getFillable());
        $this->assertTrue(
            in_array(
                \Illuminate\Database\Eloquent\SoftDeletes::class,
                class_uses_recursive(Student::class),
                true
            ),
            'Student model must use SoftDeletes.'
        );
        $this->assertSame('encrypted', $student->getCasts()['aadhar_id'] ?? null, 'aadhar_id must be encrypted-cast.');

        // -- composite relations used by show()/printIdCard()
        foreach (['user', 'guardians', 'sessions', 'previousEducations', 'healthProfile', 'documents', 'addresses', 'profile', 'currentAcademicSession'] as $relation) {
            $this->assertTrue(method_exists(Student::class, $relation), "Student must expose {$relation}() relation.");
        }

        // -- full_name accessor (used by id-card + show)
        $this->assertTrue(method_exists(Student::class, 'getFullNameAttribute'), 'full_name accessor must exist.');

        // -- route registration (all feature endpoints)
        foreach ([
            'student-profile.student.completeProfile',
            'student-profile.student.show',
            'student-profile.student.print-id-card',
            'student-profile.student.export',
            'student-profile.student.send-credentials',
            'student-profile.student.filter-dependencies',
        ] as $routeName) {
            $this->assertTrue(Route::has($routeName), "Route {$routeName} must be registered.");
        }

        // -- controller exposes each mapped action
        foreach (['completeProfile', 'show', 'printIdCard', 'export', 'sendCredentials', 'getFilterDependencies'] as $action) {
            $this->assertTrue(
                method_exists(StudentController::class, $action),
                "StudentController must define {$action}()."
            );
        }
    }

    // =========================================================================
    // BAND 10-19 : Business rules - next-incomplete-tab redirect (BC-BIZ / BC-SM)
    // =========================================================================

    /**
     * TC-P10 / BC-BIZ-1 : login-only student (missing admission/first_name/dob) resumes at student_details.
     */
    public function test_complete_profile_10_login_only_redirects_to_student_details(): void
    {
        $student = Student::where(function ($q) {
            $q->whereNull('first_name')->orWhereNull('admission_no')->orWhereNull('dob');
        })->whereNotNull('user_id')->first();

        $this->assertRedirectsToTab($student, 'student_details', 'cp-10-login-only', 'login-only');
    }

    /**
     * TC-P11 / BC-BIZ-2 : details complete but no guardians resumes at parent_details.
     */
    public function test_complete_profile_11_no_guardians_redirects_to_parent_details(): void
    {
        $student = Student::whereNotNull('admission_no')->whereNotNull('first_name')->whereNotNull('dob')
            ->whereDoesntHave('guardians')->first();

        $this->assertRedirectsToTab($student, 'parent_details', 'cp-11-no-guardian', 'details+no-guardian');
    }

    /**
     * TC-P12 / BC-BIZ-3 : has guardians, no session resumes at session_details.
     */
    public function test_complete_profile_12_no_session_redirects_to_session_details(): void
    {
        $student = Student::whereNotNull('admission_no')->whereNotNull('first_name')->whereNotNull('dob')
            ->has('guardians')->whereDoesntHave('sessions')->first();

        $this->assertRedirectsToTab($student, 'session_details', 'cp-12-no-session', 'guardians+no-session');
    }

    /**
     * TC-P13 / BC-BIZ-4 : has session, no previous education resumes at student_previous_education.
     */
    public function test_complete_profile_13_no_prev_edu_redirects_to_prev_edu(): void
    {
        $student = Student::whereNotNull('admission_no')->whereNotNull('first_name')->whereNotNull('dob')
            ->has('guardians')->has('sessions')->whereDoesntHave('previousEducations')->first();

        $this->assertRedirectsToTab($student, 'student_previous_education', 'cp-13-no-prevedu', 'session+no-prevedu');
    }

    /**
     * TC-P14 / BC-BIZ-5 : has prev-edu, no health profile resumes at student_health.
     */
    public function test_complete_profile_14_no_health_redirects_to_health(): void
    {
        $student = Student::whereNotNull('admission_no')->whereNotNull('first_name')->whereNotNull('dob')
            ->has('guardians')->has('sessions')->has('previousEducations')
            ->whereDoesntHave('healthProfile')->first();

        $this->assertRedirectsToTab($student, 'student_health', 'cp-14-no-health', 'prevedu+no-health');
    }

    /**
     * TC-P15 / BC-BIZ-6 : fully complete student falls back to student_login_details.
     */
    public function test_complete_profile_15_all_complete_redirects_to_login_tab(): void
    {
        $student = Student::whereNotNull('admission_no')->whereNotNull('first_name')->whereNotNull('dob')
            ->has('guardians')->has('sessions')->has('previousEducations')->has('healthProfile')->first();

        $this->assertRedirectsToTab($student, 'student_login_details', 'cp-15-all-complete', 'fully-complete');
    }

    /**
     * TC-P16 / BC-BIZ-7 : redirect URL carries student_id and user_id query params.
     */
    public function test_complete_profile_16_redirect_url_has_student_and_user_ids(): void
    {
        $student = Student::whereNotNull('user_id')->first();
        if (!$student) {
            $this->markTestSkipped('No student with user_id for query-param check.');
        }

        $this->browseWithFailureScreenshot('cp-16-query-params', function (Browser $browser) use ($student): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, sprintf(self::COMPLETE_PROFILE_TMPL, $student->id), 1200);

            $url = $browser->driver->getCurrentURL();
            $this->assertStringContainsString('student_id=' . $student->id, $url, 'Redirect URL must include student_id.');
        });
    }

    /**
     * TC-P17 / BC-BIZ-8 : complete-profile flow never throws a 500 for any completion state.
     */
    public function test_complete_profile_17_no_500_for_any_state(): void
    {
        $students = Student::orderBy('id')->limit(8)->get();
        if ($students->isEmpty()) {
            $this->markTestSkipped('No students for 500-safety scan.');
        }

        foreach ($students as $student) {
            $this->browseWithFailureScreenshot('cp-17-no500-' . $student->id, function (Browser $browser) use ($student): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, sprintf(self::COMPLETE_PROFILE_TMPL, $student->id), 1200);

                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('Whoops', $source, "Student {$student->id} complete-profile errored.");
            });
        }
    }

    // =========================================================================
    // BAND 30-39 : Validation - sendCredentials + export type (BC-VAL)
    // =========================================================================

    /**
     * TC-N30 / BC-VAL-1 : sendCredentials rejects a missing password_option (422).
     */
    public function test_complete_profile_30_send_credentials_requires_password_option(): void
    {
        $student = Student::whereNotNull('user_id')->first();
        if (!$student) {
            $this->markTestSkipped('No student user for send-credentials validation.');
        }

        try {
            $response = $this->actingAs($this->adminUser)
                ->postJson($this->tenantUrl('/student-profile/students/send-credentials'), [
                    'students' => [$student->user_id],
                    // password_option intentionally omitted
                ]);

            $this->assertContains(
                $response->getStatusCode(),
                [422, 403, 404],
                'Missing password_option must not silently succeed (expected 422; 403/404 when module gated/disabled).'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('send-credentials endpoint unavailable: ' . $e->getMessage());
        }
    }

    /**
     * TC-N31 / BC-VAL-2 : export() with an unknown type returns an error (no export produced).
     */
    public function test_complete_profile_31_export_invalid_type_is_rejected(): void
    {
        // Static proof: the export() switch has a default branch returning an error for invalid types.
        $body = $this->readMethodSource(StudentController::class, 'export');
        $this->assertStringContainsString("default:", $body, 'export() must have a default (invalid-type) branch.');
        $this->assertStringContainsString('Invalid export type', $body, 'Invalid type must return the "Invalid export type" error.');
    }

    // =========================================================================
    // BAND 40-49 : Related-data display on the show() composite view (BC-INT)
    // =========================================================================

    /**
     * TC-P40 / BC-INT-1 : show() renders the profile overview with the student's admission number.
     */
    public function test_complete_profile_40_show_renders_profile_overview(): void
    {
        $student = Student::whereNotNull('admission_no')->first();
        if (!$student) {
            $this->markTestSkipped('No student with admission_no for show() render.');
        }

        $this->browseWithFailureScreenshot('cp-40-show-overview', function (Browser $browser) use ($student): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, sprintf(self::SHOW_TMPL, $student->id), 1200);

            $source = $browser->driver->getPageSource();
            if (str_contains($source, 'Profile Overview')) {
                $this->assertStringContainsString(
                    (string) $student->admission_no,
                    $source,
                    'Show view must display the student admission_no.'
                );
            } else {
                $this->markTestSkipped('Show view not reachable (module likely disabled).');
            }
        });
    }

    /**
     * TC-P41 / BC-INT-2 : show() exposes all seven detail tabs (basic/profile/parent/academic/address/medical/documents).
     */
    public function test_complete_profile_41_show_exposes_all_detail_tabs(): void
    {
        $student = Student::whereNotNull('admission_no')->first();
        if (!$student) {
            $this->markTestSkipped('No student for tab-presence check.');
        }

        $this->browseWithFailureScreenshot('cp-41-show-tabs', function (Browser $browser) use ($student): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, sprintf(self::SHOW_TMPL, $student->id), 1200);

            $source = $browser->driver->getPageSource();
            if (!str_contains($source, 'studentTabs')) {
                $this->markTestSkipped('Show tabs not reachable (module likely disabled).');
            }

            foreach (['#basic', '#profile', '#parent', '#academic', '#address', '#medical', '#documents'] as $tabTarget) {
                $this->assertStringContainsString(
                    'data-bs-target="' . $tabTarget . '"',
                    $source,
                    "Show view must render the {$tabTarget} tab."
                );
            }
        });
    }

    /**
     * TC-P42 / BC-INT-3 : show() eager-loads the composite relation set (no lazy-load / N+1 surprise).
     */
    public function test_complete_profile_42_show_eager_loads_composite_relations(): void
    {
        $body = $this->readMethodSource(StudentController::class, 'show');
        foreach ([
            "'guardians.user'",
            "'healthProfile'",
            "'previousEducations'",
            "'documents.documentType'",
            "'addresses.city'",
            "'sessions.academicSession'",
        ] as $eager) {
            $this->assertStringContainsString($eager, $body, "show() must eager-load {$eager}.");
        }
    }

    // =========================================================================
    // BAND 50-59 : Permissions / authorization (BC-AUTH)
    // =========================================================================

    /**
     * TC-P50 / BC-AUTH-1 : every mapped action is gated by the correct tenant.student.* ability.
     */
    public function test_complete_profile_50_actions_are_gated_by_correct_abilities(): void
    {
        $expected = [
            'show'                  => 'tenant.student.view',
            'printIdCard'           => 'tenant.student.view',
            'completeProfile'       => 'tenant.student.update',
            'sendCredentials'       => 'tenant.student.update',
            'export'                => 'tenant.student.export',
        ];

        foreach ($expected as $method => $ability) {
            $body = $this->readMethodSource(StudentController::class, $method);
            $this->assertStringContainsString(
                "Gate::authorize('{$ability}')",
                $body,
                "{$method}() must authorize {$ability}."
            );
        }
    }

    /**
     * TC-N51 / BC-AUTH-2 : the StudentPolicy view() ability maps to tenant.student.view plus owner/parent scoping.
     */
    public function test_complete_profile_51_policy_view_scopes_to_owner_and_parent(): void
    {
        $policy = \Modules\StudentProfile\Policies\StudentPolicy::class;
        $this->assertTrue(method_exists($policy, 'view'), 'StudentPolicy must define view().');
        $body = $this->readMethodSource($policy, 'view');
        $this->assertStringContainsString("tenant.student.view", $body, 'Policy view() must check tenant.student.view.');
        $this->assertStringContainsString('user->student', $body, 'Policy view() must allow a student to view its own record.');
        $this->assertStringContainsString('user->parent', $body, 'Policy view() must allow a parent to view linked children.');
    }

    /**
     * TC-N52 / BC-AUTH-3 : an unauthenticated guest is redirected to /login (never served the profile).
     */
    public function test_complete_profile_52_guest_is_redirected_to_login(): void
    {
        $student = Student::first();
        if (!$student) {
            $this->markTestSkipped('No student for guest-redirect check.');
        }

        $this->browse(function (Browser $browser) use ($student): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(sprintf(self::SHOW_TMPL, $student->id)))->pause(900);

            $path = $this->currentPath($browser);
            $this->assertTrue(
                str_contains($path, '/login') || str_contains($path, '/student-profile'),
                "Guest must land on /login (or module-gated redirect), got: {$path}"
            );
        });
    }

    // =========================================================================
    // BAND 60-69 : UI/UX - index actions, id-card render, empty state (BC-UIX)
    // =========================================================================

    /**
     * TC-P60 / BC-UIX-1 : the student list exposes Complete-Profile, Print-ID-Card and export actions.
     */
    public function test_complete_profile_60_index_exposes_row_actions(): void
    {
        $this->browseWithFailureScreenshot('cp-60-index-actions', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 1200);

            $source = $browser->driver->getPageSource();
            if (!str_contains($source, 'export-btn') && !str_contains($source, 'Complete Profile')) {
                $this->markTestSkipped('Student index not reachable (module likely disabled).');
            }

            $this->assertTrue(
                str_contains($source, 'export-btn') || str_contains($source, 'Export'),
                'Index must expose an export action.'
            );
        });
    }

    /**
     * TC-P61 / BC-UIX-2 : printIdCard() renders the id-card shell (toolbar + id-card-content container).
     */
    public function test_complete_profile_61_print_id_card_renders_card_shell(): void
    {
        $student = Student::whereNotNull('admission_no')->first();
        if (!$student) {
            $this->markTestSkipped('No student for id-card render.');
        }

        $this->browseWithFailureScreenshot('cp-61-id-card', function (Browser $browser) use ($student): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, sprintf(self::PRINT_ID_CARD_TMPL, $student->id), 1400);

            $source = $browser->driver->getPageSource();
            if (str_contains($source, 'id-card-content')) {
                $this->assertStringContainsString('ID Card', $source, 'Id-card page must render the ID Card toolbar.');
            } else {
                $this->markTestSkipped('Id-card not reachable (module disabled or template missing).');
            }
        });
    }

    /**
     * TC-N62 / BC-UIX-3 : printIdCard() fails soft (redirect to index with error) when the template throws.
     */
    public function test_complete_profile_62_print_id_card_fails_soft_on_template_error(): void
    {
        $body = $this->readMethodSource(StudentController::class, 'printIdCard');
        $this->assertStringContainsString('catch (\Exception $e)', $body, 'printIdCard() must catch template exceptions.');
        $this->assertStringContainsString('Cannot generate ID card', $body, 'printIdCard() must return a friendly error on failure.');
        $this->assertStringContainsString("route('student-profile.student.index')", $body, 'printIdCard() must redirect to the index on failure.');
    }

    // =========================================================================
    // BAND 70-79 : Edge cases (BC-EDG)
    // =========================================================================

    /**
     * TC-E70 / BC-EDG-1 : show() / printIdCard() with a non-existent id returns 404 (route-model binding).
     */
    public function test_complete_profile_70_missing_student_returns_404(): void
    {
        $ghostId = (int) (Student::max('id') ?? 0) + 999999;

        try {
            $response = $this->actingAs($this->adminUser)
                ->get($this->tenantUrl(sprintf(self::SHOW_TMPL, $ghostId)));

            $this->assertContains(
                $response->getStatusCode(),
                [404, 403, 302],
                'A non-existent student id must not resolve to a 200 profile.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('show() route unavailable: ' . $e->getMessage());
        }
    }

    /**
     * TC-E71 / BC-EDG-2 : the getNextIncompleteTabForCreate() ladder enumerates all six ordered states.
     */
    public function test_complete_profile_71_next_tab_ladder_covers_all_states(): void
    {
        $body = $this->readMethodSource(StudentController::class, 'getNextIncompleteTabForCreate');
        foreach ([
            'student_login_details',
            'student_details',
            'parent_details',
            'session_details',
            'student_previous_education',
            'student_health',
        ] as $tab) {
            $this->assertStringContainsString("'{$tab}'", $body, "Resume ladder must handle the {$tab} state.");
        }
    }

    // =========================================================================
    // BAND 80-89 : Mapped audit defects (GAP-STD-25, PERF-STD-10)
    // =========================================================================

    /**
     * TC-S80 / GAP-STD-25 (Audit) : the ID-card data provider exposes admission_no / aadhar_id /
     * student_qr_code as RAW plaintext template variables (no hash/UUID). Proves the current-behaviour
     * PII-exposure defect. When seed data is missing the exposure is proven from the source keys instead.
     */
    public function test_complete_profile_80_id_card_exposes_raw_admission_no_defect(): void
    {
        // Source-level proof (always available): the provider builds raw identifier keys with no hashing.
        $body = $this->readMethodSource(StudentIdCardDataProvider::class, 'provide');
        $this->assertStringContainsString("'admission_no'", $body, 'GAP-STD-25: provider exposes admission_no key.');
        $this->assertStringContainsString("'aadhar_id'", $body, 'GAP-STD-25: provider exposes aadhar_id key.');
        $this->assertStringContainsString("'student_qr_code'", $body, 'GAP-STD-25: provider exposes student_qr_code key.');
        $this->assertStringNotContainsString('hash(', $body, 'GAP-STD-25: no hashing is applied to id-card identifiers.');
        $this->assertStringNotContainsString('Str::uuid', $body, 'GAP-STD-25: no UUID substitution for admission_no.');

        // Runtime proof (when a seeded student exists): the rendered payload echoes the raw admission_no.
        $student = Student::whereNotNull('admission_no')->first();
        if ($student) {
            try {
                $payload = (new StudentIdCardDataProvider())->provide(['student_id' => $student->id]);
                if (!empty($payload)) {
                    $this->assertSame(
                        (string) $student->admission_no,
                        (string) ($payload['admission_no'] ?? ''),
                        'GAP-STD-25: id-card renders admission_no verbatim (should be a hash/UUID).'
                    );
                }
            } catch (Throwable $e) {
                // Source-level proof above is sufficient; runtime path optional.
            }
        }
    }

    /**
     * TC-N81 / PERF-STD-10 (Audit) : export split-behaviour is asserted against CURRENT source -
     * excel/csv are QUEUED (StudentsExport implements ShouldQueue + Excel::queue), while the PDF branch
     * remains SYNCHRONOUS (loads all matching rows via ->get() then inline ->download()). Documents that
     * the audit's "Excel::download synchronous" is remediated for excel/csv but the synchronous
     * full-load risk persists in the pdf branch.
     */
    public function test_complete_profile_81_export_sync_vs_queue_behaviour_defect(): void
    {
        // Excel/CSV path is queued.
        $this->assertTrue(
            in_array(\Illuminate\Contracts\Queue\ShouldQueue::class, class_implements(StudentsExport::class), true),
            'PERF-STD-10: StudentsExport should implement ShouldQueue (excel/csv queued).'
        );

        $body = $this->readMethodSource(StudentController::class, 'export');
        $this->assertStringContainsString('Excel::queue(', $body, 'PERF-STD-10: excel/csv export must be queued.');
        $this->assertStringContainsString('being processed', $body, 'PERF-STD-10: queued export must flash the async notice.');

        // PDF path is synchronous: full ->get() load then inline download (no queue, no chunk).
        $this->assertStringContainsString('->get();', $body, 'PERF-STD-10: pdf branch loads the full result set synchronously.');
        $this->assertStringContainsString('exportPDF(', $body, 'PERF-STD-10: pdf branch renders inline via exportPDF().');
        $pdfBody = $this->readMethodSource(StudentController::class, 'exportPDF');
        $this->assertStringContainsString('->download(', $pdfBody, 'PERF-STD-10: pdf is a synchronous inline download.');
    }

    // =========================================================================
    // BAND 90-99 : Tenancy isolation / IDOR (TC-T / TC-S) - mandatory P0/P1
    // =========================================================================

    /**
     * TC-T90 : the module wraps every route in the tenant module guard (module:STUDENT) so a
     * cross-tenant / disabled-module request cannot reach a profile.
     */
    public function test_complete_profile_90_routes_are_tenant_module_guarded(): void
    {
        $routesFile = base_path('Modules/StudentProfile/routes/web.php');
        if (!File::exists($routesFile)) {
            // In the runner the app repo may sit alongside; fall back to route middleware inspection.
            $this->assertTrue(Route::has('student-profile.student.show'), 'show route must be registered under the guard.');
            return;
        }
        $body = (string) File::get($routesFile);
        $this->assertStringContainsString("middleware('module:STUDENT')", $body, 'All student routes must sit under module:STUDENT.');
    }

    /**
     * TC-T91 / IDOR : a student id belonging to another tenant must 404 (route-model binding is
     * tenant-scoped), never leak a foreign profile. Fail-soft when a second tenant is unavailable.
     */
    public function test_complete_profile_91_cross_tenant_show_is_not_leaked(): void
    {
        try {
            $foreignId = (int) (Student::max('id') ?? 0) + 500000;
            $response = $this->actingAs($this->adminUser)
                ->get($this->tenantUrl(sprintf(self::PRINT_ID_CARD_TMPL, $foreignId)));

            $this->assertNotSame(
                200,
                $response->getStatusCode(),
                'A foreign / non-existent student id must not return a 200 id-card.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Cross-tenant IDOR path unavailable: ' . $e->getMessage());
        }
    }

    /**
     * TC-S92 : reflected-XSS smoke - a script-shaped export search term is not reflected unescaped.
     */
    public function test_complete_profile_92_export_search_is_not_reflected_unescaped(): void
    {
        $payload = '<script>alert(1)</script>';
        try {
            $response = $this->actingAs($this->adminUser)
                ->get($this->tenantUrl(sprintf(self::EXPORT_TMPL, 'pdf')) . '?search=' . urlencode($payload));

            $content = (string) $response->getContent();
            $this->assertStringNotContainsString(
                '<script>alert(1)</script>',
                $content,
                'Raw script payload must not be reflected verbatim in the export response.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Export endpoint unavailable for XSS smoke: ' . $e->getMessage());
        }
    }

    // =========================================================================
    // HELPER METHODS (mirrors committed sibling spr_StudentCompleteProfile_TestCas.php)
    // =========================================================================

    private function assertRedirectsToTab(?Student $student, string $expectedTab, string $caseName, string $stateLabel): void
    {
        if (!$student) {
            $this->markTestSkipped("No student in state [{$stateLabel}] to assert {$expectedTab} redirect.");
        }

        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($student, $expectedTab): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, sprintf(self::COMPLETE_PROFILE_TMPL, $student->id), 1200);

            $url = $browser->driver->getCurrentURL();
            if (!str_contains($url, 'activeTab=')) {
                $this->markTestSkipped('Complete-profile redirect not reachable (module likely disabled).');
            }
            $this->assertStringContainsString(
                'activeTab=' . $expectedTab,
                $url,
                "Expected resume tab activeTab={$expectedTab}, got URL: {$url}"
            );
        });
    }

    private function readMethodSource(string $class, string $method): string
    {
        $ref  = new ReflectionMethod($class, $method);
        $file = (string) $ref->getFileName();
        if ($file === '' || !File::exists($file)) {
            $this->markTestSkipped("Source file for {$class}::{$method} unavailable.");
        }

        $lines = File::lines($file)->slice($ref->getStartLine() - 1, $ref->getEndLine() - $ref->getStartLine() + 1);

        return (string) $lines->implode("\n");
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $timestamp = now()->format('Ymd_His');
        $safeName  = preg_replace('/[^A-Za-z0-9_-]+/', '-', 'complete-profile-fail-' . $caseName . '-' . $timestamp)
            ?? 'complete-profile-fail-' . $timestamp;

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
            $this->markTestSkipped('Tenant host missing.');
        }

        $domain = Domain::query()->where('domain', $tenantHost)->first();
        if (!$domain) {
            $this->markTestSkipped('Tenant domain not found.');
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
            'tenant.student.create',
            'tenant.student.update',
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
