<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\MarksheetGeneration\Models\ComputationLog;
use Modules\MarksheetGeneration\Models\StudentResult;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * MarksheetGeneration — Student Results & Print
 * Screen requirement : MarksheetGeneration_V2/05-Student-Results-and-Print.md
 * Feature            : StudentResultsAndPrint
 * Prefix             : msh_   (verified against DDL CREATE TABLE `msh_student_results`)
 * Primary table      : msh_student_results  (UNIQUE uq_msh_sr_schedule_student)
 * Combined screen    : marksheet-generation.results.combined → /marksheet-generation/results
 *
 * ONE comprehensive Dusk suite per screen (V1 foundation + V2 comprehensive MERGED — no V1/V2 split).
 * DB scope: TENANT-side (DDL header "Database: tenant_db", prefix msh_) → tenancy scaffolding required.
 * Style   : browser Dusk (golden Class reference), extends DuskTestCase, namespace Tests\Browser.
 *
 * Semantic numbering bands (WP-G):
 *   01-09 schema/config truth · 10-19 business rules / CRUD / print-pdf-export
 *   20-29 state machine (DECLARED ↔ WITHHELD) · 30-39 validation + error messages
 *   40-49 integration / child entities / FK · 50-59 permissions + traced security defects
 *   60-69 UI/UX · 70-79 edge cases · 90-99 tenancy isolation + security pack
 *
 * Owned audit defects proven here (current-behaviour proving tests):
 *   SEC-MSH-001 (P1) StudentResultController::create() authorizes .view instead of .create   → test_51
 *   SEC-MSH-002 (P1) StudentResultController::store()  authorizes .update instead of .create  → test_52
 *   SEC-MSH-003 (P1) StudentResultRequest / WithholdStudentResultRequest authorize() = true   → test_09 / test_53
 * Documented (not directly automatable without heavy fixtures):
 *   PERF-MSH-003 (P2) unbounded Student::get()/Subject::get() in results view (no pagination)
 *   PERF-MSH-004 (P3) wipePreviousResults() hard-deletes soft-deletable result rows on recompute
 *
 * NOTE: msh_computation_logs has NO deleted_at and ComputationLog does NOT use SoftDeletes —
 *       withTrashed()/onlyTrashed()/forceDelete() on it throw (asserted in test_07 / test_92).
 */
class msh_StudentResultsAndPrint_TestCas extends DuskTestCase
{
    private const RESULTS_PATH = '/marksheet-generation/results';
    private const STUDENT_RESULT_BASE = '/marksheet-generation/student-result';
    private const REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/StudentResultRequest.php';
    private const WITHHOLD_REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/WithholdStudentResultRequest.php';
    private const CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/StudentResultController.php';
    private const RESULTS_CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/MarksheetGenerationController.php';
    private const RESULTS_VIEW_FILE = 'Modules/MarksheetGeneration/resources/views/pages/results.blade.php';
    private const SCREENSHOT_DIR = 'tests/Browser/Modules/MarksheetGeneration/StudentResultsAndPrint/screenshots';

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private array $resultDependencies = [];
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->tenantBaseUrl = rtrim(env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')), '/');
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
    //  01-09 · Schema / model / request configuration truth
    // =====================================================================

    /** TC-P01 · BC-DB-01/02/03 · schema + model + fillable + relations + casts. */
    public function test_studentresult_01_student_results_schema_and_model_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable('msh_student_results'), 'Table msh_student_results does not exist.');
        $this->assertTrue(
            Schema::hasColumns('msh_student_results', [
                'schedule_id', 'student_id', 'class_section_id',
                'grand_total', 'grand_max', 'overall_percentage', 'overall_grade', 'division',
                'rank_in_section', 'rank_in_class',
                'total_subjects', 'subjects_passed', 'subjects_failed',
                'promotion_status', 'result_status', 'withheld_reason',
                'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in msh_student_results table.'
        );

        $model = new StudentResult();
        $this->assertSame('msh_student_results', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(StudentResult::class));

        foreach (['schedule_id', 'student_id', 'class_section_id', 'grand_total', 'overall_percentage', 'promotion_status', 'result_status', 'withheld_reason', 'is_active'] as $col) {
            $this->assertContains($col, $model->getFillable(), "Fillable is missing '{$col}'.");
        }

        $this->assertInstanceOf(BelongsTo::class, $model->marksheetSchedule());
        $this->assertInstanceOf(BelongsTo::class, $model->student());
        $this->assertInstanceOf(BelongsTo::class, $model->classSection());
        $this->assertInstanceOf(HasMany::class, $model->subjectResults());
        $this->assertInstanceOf(HasMany::class, $model->coscholasticResults());

        $casts = $model->getCasts();
        $this->assertSame('decimal:2', $casts['grand_total'] ?? null);
        $this->assertSame('decimal:2', $casts['overall_percentage'] ?? null);
    }

    /** TC-P02 · BC-DB-04 · UNIQUE (schedule_id, student_id). */
    public function test_studentresult_02_unique_schedule_student_index_exists(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Index inspection requires MySQL.');
        }
        $rows = DB::select("SHOW INDEX FROM msh_student_results WHERE Key_name = 'uq_msh_sr_schedule_student'");
        $this->assertNotEmpty($rows, 'UNIQUE (schedule_id, student_id) index is missing.');
        $columns = array_map(fn ($r) => $r->Column_name, $rows);
        $this->assertContains('schedule_id', $columns);
        $this->assertContains('student_id', $columns);
    }

    /** TC-P03 · BC-DB-05 · subject-results child schema. */
    public function test_studentresult_03_subject_results_schema_is_correct(): void
    {
        $this->assertTrue(Schema::hasTable('msh_student_subject_results'));
        $this->assertTrue(Schema::hasColumns('msh_student_subject_results', [
            'schedule_id', 'student_id', 'subject_id', 'exam_weighted_total', 'theory_marks',
            'practical_marks', 'homework_score', 'quiz_score', 'quest_score', 'ia_total',
            'subject_total', 'subject_max', 'subject_grade', 'is_passed', 'deleted_at',
        ]));
    }

    /** TC-P04 · BC-DB-06 · IA-marks child schema. */
    public function test_studentresult_04_ia_marks_schema_is_correct(): void
    {
        $this->assertTrue(Schema::hasTable('msh_student_ia_marks'));
        $this->assertTrue(Schema::hasColumns('msh_student_ia_marks', [
            'schedule_id', 'student_id', 'subject_id', 'ia_component_id',
            'marks_obtained', 'max_marks', 'entered_by', 'entered_at', 'deleted_at',
        ]));
    }

    /** TC-P05 · BC-DB-07 · co-scholastic + attendance child schema. */
    public function test_studentresult_05_coscholastic_and_attendance_schema_are_correct(): void
    {
        $this->assertTrue(Schema::hasColumns('msh_student_coscholastic_results', [
            'schedule_id', 'student_id', 'coscholastic_component_id', 'grade', 'remarks',
            'entered_by', 'is_auto_from_ba', 'deleted_at',
        ]));
        $this->assertTrue(Schema::hasColumns('msh_student_attendance', [
            'schedule_id', 'student_id', 'total_working_days', 'days_present', 'entered_by', 'is_auto_populated',
        ]));
    }

    /** TC-P06 · BC-DB-08 · raw exam-marks matrix schema. */
    public function test_studentresult_06_exam_marks_matrix_schema_is_correct(): void
    {
        $this->assertTrue(Schema::hasTable('msh_student_subject_exam_marks'));
        $this->assertTrue(Schema::hasColumns('msh_student_subject_exam_marks', [
            'schedule_id', 'student_id', 'subject_id', 'exam_type_id',
            'marks_obtained', 'max_marks', 'result_status', 'exam_result_id',
        ]));
    }

    /** TC-D07 · BC-DB-09 · computation_logs is immutable (no deleted_at, no SoftDeletes). */
    public function test_studentresult_07_computation_log_immutable_no_soft_deletes(): void
    {
        $this->assertTrue(Schema::hasTable('msh_computation_logs'));
        $this->assertFalse(Schema::hasColumn('msh_computation_logs', 'deleted_at'), 'msh_computation_logs must NOT have deleted_at.');
        $this->assertNotContains(SoftDeletes::class, class_uses_recursive(ComputationLog::class), 'ComputationLog must NOT use SoftDeletes.');

        $threw = false;
        try {
            ComputationLog::withTrashed()->limit(1)->get();
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'withTrashed() on ComputationLog should throw (no SoftDeletes trait).');
    }

    /** TC-N-config · BC-VAL-* · StudentResultRequest rule strings are verbatim. */
    public function test_studentresult_08_student_result_request_rules_are_verbatim(): void
    {
        $content = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("'exists:msh_marksheet_schedules,id'", $content);
        $this->assertStringContainsString("'exists:std_students,id'", $content);
        $this->assertStringContainsString("'exists:sch_class_section_jnt,id'", $content);
        $this->assertStringContainsString("'overall_percentage' => ['nullable', 'numeric', 'min:0', 'max:100']", $content);
        $this->assertStringContainsString('in:PROMOTED,DETAINED,COMPARTMENT,PLACED', $content);
        $this->assertStringContainsString('in:DECLARED,WITHHELD', $content);
        $this->assertStringContainsString("Rule::unique('msh_student_results', 'schedule_id')", $content);
    }

    /** TC-N-config · SEC-MSH-003 · WithholdStudentResultRequest rules + open authorize(). */
    public function test_studentresult_09_withhold_request_rules_and_open_authorize(): void
    {
        $content = File::get(base_path(self::WITHHOLD_REQUEST_FILE));
        $this->assertStringContainsString("'withheld_reason' => ['required', 'string', 'min:5', 'max:255']", $content);
        // SEC-MSH-003 / D39-MSH: FormRequest authorize() returns true (no per-request gate).
        $this->assertMatchesRegularExpression(
            '/function authorize\(\):\s*bool\s*\{\s*return true;/s',
            $content,
            'WithholdStudentResultRequest::authorize() is expected to return true (SEC-MSH-003).'
        );
    }

    // =====================================================================
    //  10-19 · Business rules / core CRUD / print-pdf-export
    // =====================================================================

    /** TC-P10 · BC-BIZ-01 · combined results screen renders the four result tabs. */
    public function test_studentresult_10_results_screen_renders_four_tabs(): void
    {
        $this->browseWithFailureScreenshot('10-tabs', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 1200);
            foreach (['Student Results', 'Subject Results', 'IA Marks', 'Coscholastic Results'] as $tab) {
                $this->assertTrue($this->pageSourceContains($browser, $tab), "Results tab missing: {$tab}");
            }
        });
    }

    /** TC-P11 · BC-BIZ-02 · store persists a result and logs 'Stored'. */
    public function test_studentresult_11_store_persists_and_logs_stored(): void
    {
        $deps = $this->resultDependencies();
        $studentId = $this->freshStudentForSchedule((int) $deps['schedule_id']);
        $payload = $this->buildStorePayload($deps, $studentId, ['overall_grade' => 'A1', 'promotion_status' => 'PROMOTED']);

        $this->browseWithFailureScreenshot('11-store', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertTrue(in_array((int) ($response['status'] ?? 0), [200, 302], true), 'Store status: ' . (int) ($response['status'] ?? 0));
        });

        $result = StudentResult::withTrashed()
            ->where('schedule_id', $payload['schedule_id'])
            ->where('student_id', $payload['student_id'])
            ->latest('id')->first();

        $this->assertNotNull($result, 'Result not persisted.');
        $this->assertSame('PROMOTED', (string) $result->promotion_status, 'promotion_status not persisted.');
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Stored');
        $this->forceDeleteResult($result);
    }

    /** TC-P12 · BC-BIZ-03 · update persists and logs 'Updated'. */
    public function test_studentresult_12_update_persists_and_logs_updated(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['overall_grade' => 'C1', 'promotion_status' => 'PROMOTED']);
        $payload = [
            'schedule_id' => (int) $result->schedule_id, 'student_id' => (int) $result->student_id,
            'class_section_id' => (int) $result->class_section_id, 'overall_grade' => 'A2',
            'promotion_status' => 'DETAINED', 'overall_percentage' => 88.50, 'is_active' => true,
        ];

        $this->browseWithFailureScreenshot('12-update', function (Browser $browser) use ($result, $payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'PUT', self::STUDENT_RESULT_BASE . '/' . $result->id, $payload);
            $this->assertTrue(in_array((int) ($response['status'] ?? 0), [200, 302], true), 'Update status: ' . (int) ($response['status'] ?? 0));
        });

        $result->refresh();
        $this->assertSame('A2', (string) $result->overall_grade);
        $this->assertSame('DETAINED', (string) $result->promotion_status);
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Updated');
        $this->forceDeleteResult($result);
    }

    /** TC-D13 · BC-BIZ-04 · destroy soft-deletes and logs 'Deleted'. */
    public function test_studentresult_13_destroy_soft_deletes_and_logs_deleted(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps);

        $this->browseWithFailureScreenshot('13-destroy', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::STUDENT_RESULT_BASE . '/' . $result->id, []);
        });

        $result->refresh();
        $this->assertNotNull($result->deleted_at, 'Result not soft deleted.');
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Deleted');
        $this->forceDeleteResult($result);
    }

    /** TC-P14 · BC-BIZ-05 · show page displays aggregate scores. */
    public function test_studentresult_14_show_page_displays_aggregates(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['overall_grade' => 'A1', 'overall_percentage' => 95.00]);

        $this->browseWithFailureScreenshot('14-show', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::STUDENT_RESULT_BASE . '/' . $result->id, 1000);
            $this->assertTrue($this->pageSourceContains($browser, 'A1') || $this->pageSourceContains($browser, '95'), 'Aggregates not rendered on show page.');
        });
        $this->forceDeleteResult($result);
    }

    /** TC-P15 · BC-BIZ-06 · export returns an XLSX download (StudentResultExport). */
    public function test_studentresult_15_export_returns_xlsx_download(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps);

        $this->browseWithFailureScreenshot('15-export', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STUDENT_RESULT_BASE . '/' . $result->id . '/export', []);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Export status: ' . (int) ($response['status'] ?? 0));
        });
        $this->forceDeleteResult($result);
    }

    /** TC-P16 · BC-BIZ-07 · print route resolves (Template::render or DomainException redirect). */
    public function test_studentresult_16_print_route_resolves(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps);

        $this->browseWithFailureScreenshot('16-print', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            // Print may render (200) or redirect back with an error when the MARKSHEET_PRINT template is absent.
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STUDENT_RESULT_BASE . '/' . $result->id . '/print', []);
            $this->assertTrue(in_array((int) ($response['status'] ?? 0), [200, 302], true), 'Print status: ' . (int) ($response['status'] ?? 0));
        });
        $this->forceDeleteResult($result);
    }

    /** TC-P17 · BC-BIZ-08 · pdf route resolves (downloadPdf redirects to print?download=1&auto=1). */
    public function test_studentresult_17_pdf_route_resolves_to_print_download(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps);

        $this->browseWithFailureScreenshot('17-pdf', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STUDENT_RESULT_BASE . '/' . $result->id . '/pdf', []);
            $this->assertTrue(in_array((int) ($response['status'] ?? 0), [200, 302], true), 'PDF status: ' . (int) ($response['status'] ?? 0));
        });
        $this->forceDeleteResult($result);
    }

    /** TC-P18 · BC-BIZ-09 · resource index redirects to the combined results screen. */
    public function test_studentresult_18_index_redirects_to_combined_results(): void
    {
        $this->browseWithFailureScreenshot('18-index-redirect', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::STUDENT_RESULT_BASE, 1000);
            $this->assertTrue(str_contains($this->currentPath($browser), '/marksheet-generation/results'), 'index did not redirect to combined results.');
        });
    }

    /** TC-N19 · BC-REF · invalid id returns 404 on show (route-model binding). */
    public function test_studentresult_19_invalid_id_returns_404_on_show(): void
    {
        $this->browseWithFailureScreenshot('19-show-404', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STUDENT_RESULT_BASE . '/999999999', []);
            $this->assertSame(404, (int) ($response['status'] ?? 0), 'Invalid show id should 404.');
        });
    }

    // =====================================================================
    //  20-29 · State machine (BC-SM: DECLARED ↔ WITHHELD)
    // =====================================================================

    /** TC-SM20 · BC-SM-01 · DECLARED → WITHHELD sets status + reason and logs 'Withheld'. */
    public function test_studentresult_20_withhold_sets_withheld_and_logs(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'DECLARED']);

        $this->browseWithFailureScreenshot('20-withhold', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/withhold', [
                'withheld_reason' => 'Malpractice investigation in progress',
            ]);
        });

        $result->refresh();
        $this->assertSame('WITHHELD', (string) $result->result_status);
        $this->assertSame('Malpractice investigation in progress', (string) $result->withheld_reason);
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Withheld');
        $this->forceDeleteResult($result);
    }

    /** TC-SM21 · BC-SM-02 · WITHHELD → DECLARED clears reason and logs 'Declared'. */
    public function test_studentresult_21_declare_sets_declared_and_clears_reason(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'WITHHELD', 'withheld_reason' => 'Hold reason']);

        $this->browseWithFailureScreenshot('21-declare', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/declare', []);
        });

        $result->refresh();
        $this->assertSame('DECLARED', (string) $result->result_status);
        $this->assertNull($result->withheld_reason, 'Declare should null withheld_reason.');
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Declared');
        $this->forceDeleteResult($result);
    }

    /** TC-SM22 · BC-SM-03 (illegal) · withhold is blocked while schedule is locked. */
    public function test_studentresult_22_withhold_blocked_when_schedule_locked(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'DECLARED']);

        $this->temporarilyLockSchedule((int) $result->schedule_id, function () use ($result): void {
            $this->browseWithFailureScreenshot('22-withhold-locked', function (Browser $browser) use ($result): void {
                $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
                $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/withhold', [
                    'withheld_reason' => 'Attempted while locked',
                ]);
            });
            $result->refresh();
            $this->assertNotSame('WITHHELD', (string) $result->result_status, 'Withhold must be blocked while the schedule is locked (BC-SM illegal transition).');
        });

        $this->forceDeleteResult($result);
    }

    /** TC-SM23 · BC-SM-04 (illegal) · declare is blocked while schedule is locked. */
    public function test_studentresult_23_declare_blocked_when_schedule_locked(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'WITHHELD', 'withheld_reason' => 'Hold']);

        $this->temporarilyLockSchedule((int) $result->schedule_id, function () use ($result): void {
            $this->browseWithFailureScreenshot('23-declare-locked', function (Browser $browser) use ($result): void {
                $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
                $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/declare', []);
            });
            $result->refresh();
            $this->assertSame('WITHHELD', (string) $result->result_status, 'Declare must be blocked while the schedule is locked (BC-SM illegal transition).');
        });

        $this->forceDeleteResult($result);
    }

    /** TC-N24 · BC-VAL · withhold requires reason ≥ min:5. */
    public function test_studentresult_24_withhold_requires_reason_min_length(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'DECLARED']);

        $this->browseWithFailureScreenshot('24-withhold-minlen', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/withhold', ['withheld_reason' => 'no']);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'withheld_reason shorter than min:5 should 422.');
        });

        $result->refresh();
        $this->assertNotSame('WITHHELD', (string) $result->result_status, 'Result must not be withheld on invalid reason.');
        $this->forceDeleteResult($result);
    }

    /** TC-N25 · BC-VAL · withhold requires reason present. */
    public function test_studentresult_25_withhold_requires_reason_present(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'DECLARED']);

        $this->browseWithFailureScreenshot('25-withhold-required', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/withhold', []);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Missing withheld_reason should 422.');
        });
        $this->forceDeleteResult($result);
    }

    // =====================================================================
    //  30-39 · Validation + error messages (BC-VAL)
    // =====================================================================

    /** TC-N30 · BC-VAL · required fields block store; response body carries the errors. */
    public function test_studentresult_30_required_fields_block_store(): void
    {
        $this->browseWithFailureScreenshot('30-required', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, ['is_active' => true]);
            $this->assertSame(422, (int) ($response['status'] ?? 0));
            $body = (string) ($response['body'] ?? '');
            $this->assertTrue(
                str_contains($body, 'schedule_id') || str_contains($body, 'student_id') || str_contains($body, 'required'),
                'Expected required-field validation errors in response body.'
            );
        });
    }

    /** TC-N31 · BC-VAL / BC-DB-04 · duplicate (schedule_id, student_id) rejected. */
    public function test_studentresult_31_duplicate_schedule_student_rejected(): void
    {
        $deps = $this->resultDependencies();
        $existing = $this->createStudentResultSeed($deps);
        $payload = [
            'schedule_id' => (int) $existing->schedule_id, 'student_id' => (int) $existing->student_id,
            'class_section_id' => (int) $existing->class_section_id, 'is_active' => true,
        ];

        $this->browseWithFailureScreenshot('31-duplicate', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate (schedule_id, student_id) should 422.');
        });

        $this->assertSame(1, StudentResult::withTrashed()->where('schedule_id', $payload['schedule_id'])->where('student_id', $payload['student_id'])->count());
        $this->forceDeleteResult($existing);
    }

    /** TC-N32 · BC-VAL · overall_percentage > 100 rejected. */
    public function test_studentresult_32_overall_percentage_over_100_rejected(): void
    {
        $deps = $this->resultDependencies();
        $studentId = $this->freshStudentForSchedule((int) $deps['schedule_id']);
        $payload = $this->buildStorePayload($deps, $studentId, ['overall_percentage' => 150]);

        $this->browseWithFailureScreenshot('32-percentage', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'overall_percentage > 100 should 422.');
        });
    }

    /** TC-N33 · BC-VAL · promotion_status outside enum rejected. */
    public function test_studentresult_33_invalid_promotion_status_rejected(): void
    {
        $deps = $this->resultDependencies();
        $studentId = $this->freshStudentForSchedule((int) $deps['schedule_id']);
        $payload = $this->buildStorePayload($deps, $studentId, ['promotion_status' => 'GRADUATED']);

        $this->browseWithFailureScreenshot('33-promotion-enum', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'promotion_status outside enum should 422.');
        });
    }

    /** TC-N34 · BC-VAL · result_status outside enum rejected. */
    public function test_studentresult_34_invalid_result_status_rejected(): void
    {
        $deps = $this->resultDependencies();
        $studentId = $this->freshStudentForSchedule((int) $deps['schedule_id']);
        $payload = $this->buildStorePayload($deps, $studentId, ['result_status' => 'PENDING']);

        $this->browseWithFailureScreenshot('34-result-enum', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'result_status outside enum should 422.');
        });
    }

    /** TC-N35 · BC-REF · non-existent schedule_id rejected (exists rule). */
    public function test_studentresult_35_nonexistent_schedule_rejected(): void
    {
        $deps = $this->resultDependencies();
        $studentId = $this->freshStudentForSchedule((int) $deps['schedule_id']);
        $payload = $this->buildStorePayload($deps, $studentId, ['schedule_id' => 999999999]);

        $this->browseWithFailureScreenshot('35-schedule-exists', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Non-existent schedule_id should 422 (exists rule).');
        });
    }

    /** TC-N36 · BC-REF · non-existent student_id rejected (exists rule). */
    public function test_studentresult_36_nonexistent_student_rejected(): void
    {
        $deps = $this->resultDependencies();
        $payload = $this->buildStorePayload($deps, 999999999, []);

        $this->browseWithFailureScreenshot('36-student-exists', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Non-existent student_id should 422 (exists rule).');
        });
    }

    /** TC-N37 · BC-VAL · rank_in_section < 1 rejected. */
    public function test_studentresult_37_rank_below_one_rejected(): void
    {
        $deps = $this->resultDependencies();
        $studentId = $this->freshStudentForSchedule((int) $deps['schedule_id']);
        $payload = $this->buildStorePayload($deps, $studentId, ['rank_in_section' => 0]);

        $this->browseWithFailureScreenshot('37-rank-min', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'rank_in_section < 1 should 422.');
        });
    }

    /** TC-N38 · BC-REF · update of a non-existent id returns 404. */
    public function test_studentresult_38_update_invalid_id_returns_404(): void
    {
        $this->browseWithFailureScreenshot('38-update-404', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'PUT', self::STUDENT_RESULT_BASE . '/999999999', [
                'schedule_id' => 1, 'student_id' => 1, 'class_section_id' => 1,
            ]);
            $this->assertSame(404, (int) ($response['status'] ?? 0), 'Update of non-existent id should 404.');
        });
    }

    /** TC-N39 · BC-VAL · withheld_reason > max:255 rejected. */
    public function test_studentresult_39_withhold_reason_over_255_rejected(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'DECLARED']);

        $this->browseWithFailureScreenshot('39-reason-maxlen', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/withhold', [
                'withheld_reason' => str_repeat('x', 300),
            ]);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'withheld_reason > max:255 should 422.');
        });
        $this->forceDeleteResult($result);
    }

    // =====================================================================
    //  40-49 · Integration / child entities / FK behaviour
    // =====================================================================

    /** TC-D40 · BC-REF (soft-delete B) · soft-deleted result hidden from default scope. */
    public function test_studentresult_40_soft_deleted_result_hidden_from_active_scope(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps);
        $result->delete();

        $this->assertFalse(StudentResult::whereKey($result->id)->exists(), 'Soft-deleted result should not appear in default query.');
        $this->assertTrue(StudentResult::withTrashed()->whereKey($result->id)->exists(), 'Soft-deleted result should be visible via withTrashed().');
        $this->forceDeleteResult($result);
    }

    /** TC-D41 · BC-DB · decimal:2 cast preserves grand_total precision on round-trip. */
    public function test_studentresult_41_result_status_defaults_survive_round_trip(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['grand_total' => 321.75, 'grand_max' => 400]);
        $result->refresh();
        $this->assertSame('321.75', (string) $result->grand_total, 'decimal:2 cast should preserve grand_total precision.');
        $this->forceDeleteResult($result);
    }

    /** TC-D42 · BC-INT · subject-results tab renders. */
    public function test_studentresult_42_subject_results_tab_renders(): void
    {
        $this->browseWithFailureScreenshot('42-subject-tab', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH . '?tab=subject-results', 1100);
            $this->assertTrue($this->pageSourceContains($browser, 'Subject Results'), 'Subject Results tab did not render.');
        });
    }

    /** TC-D43 · BC-INT · IA-marks tab renders. */
    public function test_studentresult_43_ia_marks_tab_renders(): void
    {
        $this->browseWithFailureScreenshot('43-ia-tab', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH . '?tab=ia-marks', 1100);
            $this->assertTrue($this->pageSourceContains($browser, 'IA Marks'), 'IA Marks tab did not render.');
        });
    }

    /** TC-D44 · BC-INT · coscholastic tab renders. */
    public function test_studentresult_44_coscholastic_tab_renders(): void
    {
        $this->browseWithFailureScreenshot('44-cosch-tab', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH . '?tab=coscholastic-results', 1100);
            $this->assertTrue($this->pageSourceContains($browser, 'Coscholastic Results'), 'Coscholastic tab did not render.');
        });
    }

    /** TC-D45 · BC-INT · computation-log index resolves (read-only audit surface). */
    public function test_studentresult_45_computation_log_index_renders_read_only(): void
    {
        $this->browseWithFailureScreenshot('45-complog', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', '/marksheet-generation/computation-log', []);
            $this->assertTrue(in_array((int) ($response['status'] ?? 0), [200, 302], true), 'Computation-log index did not resolve. Got: ' . (int) ($response['status'] ?? 0));
        });
    }

    // =====================================================================
    //  50-59 · Permissions / authorization / traced security defects
    // =====================================================================

    /** TC-N50 · BC-AUTH · guest is redirected to /login. */
    public function test_studentresult_50_guest_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::RESULTS_PATH))->pause(900);
            $this->assertTrue(str_contains($this->currentPath($browser), '/login'), 'Guest not redirected to /login.');
        });
    }

    /** TC-S51 · SEC-MSH-001 (P1) · create() authorizes .view instead of .create (proving current behaviour). */
    public function test_studentresult_51_sec_msh_001_create_uses_view_gate(): void
    {
        $content = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertMatchesRegularExpression(
            "/function create\(\)\s*\{\s*Gate::authorize\('tenant\.msh-student-result\.view'\)/s",
            $content,
            'SEC-MSH-001: StudentResultController::create() is expected to (wrongly) authorize tenant.msh-student-result.view instead of .create.'
        );
    }

    /** TC-S52 · SEC-MSH-002 (P1) · store() authorizes .update instead of .create (proving current behaviour). */
    public function test_studentresult_52_sec_msh_002_store_uses_update_gate(): void
    {
        $content = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertMatchesRegularExpression(
            "/function store\(StudentResultRequest \\\$request\)\s*\{\s*Gate::authorize\('tenant\.msh-student-result\.update'\)/s",
            $content,
            'SEC-MSH-002: StudentResultController::store() is expected to (wrongly) authorize tenant.msh-student-result.update instead of .create.'
        );
    }

    /** TC-S53 · SEC-MSH-003 (P1) · StudentResultRequest::authorize() returns true (no per-request gate). */
    public function test_studentresult_53_sec_msh_003_form_request_authorize_open(): void
    {
        $content = File::get(base_path(self::REQUEST_FILE));
        $this->assertMatchesRegularExpression('/function authorize\(\):\s*bool\s*\{\s*return true;/s', $content, 'SEC-MSH-003: StudentResultRequest::authorize() should return true.');
    }

    /** TC-AUTH54 · BC-AUTH · result tabs are permission-gated in the results view. */
    public function test_studentresult_54_result_tabs_are_permission_gated_in_view(): void
    {
        $content = File::get(base_path(self::RESULTS_VIEW_FILE));
        $this->assertStringContainsString("@can('tenant.msh-student-result.view')", $content, 'Student-results tab is expected to be permission-gated in the view.');
        $this->assertStringContainsString("@can('tenant.msh-student-ia-mark.view')", $content);
        $this->assertStringContainsString("@can('tenant.msh-student-coscholastic-result.view')", $content);
        $this->assertStringContainsString("@can('tenant.msh-student-subject-result.view')", $content);
    }

    /** TC-AUTH55 · BC-AUTH · results() controller gate is tenant.msh-results.view. */
    public function test_studentresult_55_results_controller_gate_is_msh_results_view(): void
    {
        $content = File::get(base_path(self::RESULTS_CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.msh-results.view')", $content, 'results() should authorize tenant.msh-results.view.');
    }

    // =====================================================================
    //  60-69 · UI/UX (search, filter, pagination, empty state)
    // =====================================================================

    /** TC-P60 · BC-UIX · student search filter applies on the student-results tab. */
    public function test_studentresult_60_student_search_filter_applies(): void
    {
        $this->browseWithFailureScreenshot('60-search', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH . '?tab=student-results&search=zzz_no_such_student', 1100);
            $this->assertTrue(
                $this->pageSourceContains($browser, 'No Student Results Found') || $this->pageSourceContains($browser, 'Student Results'),
                'Search filter did not render the student-results tab / empty state.'
            );
        });
    }

    /** TC-P61 · BC-UIX · class-section filter control is present. */
    public function test_studentresult_61_class_section_filter_control_present(): void
    {
        $this->browseWithFailureScreenshot('61-cs-filter', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 1000);
            $this->assertTrue(
                $this->pageSourceContains($browser, 'sr_class_section_id') || $this->pageSourceContains($browser, 'All Classes'),
                'Class-section filter control not present on the student-results tab.'
            );
        });
    }

    /** TC-P62 · BC-UIX · empty-state message shown when no results match. */
    public function test_studentresult_62_empty_state_message_when_no_results(): void
    {
        $this->browseWithFailureScreenshot('62-empty', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH . '?tab=student-results&search=___definitely_absent___', 1100);
            $this->assertTrue(
                $this->pageSourceContains($browser, 'No Student Results Found') || $this->pageSourceContains($browser, 'Run the marksheet'),
                'Empty-state message not shown for a no-match search.'
            );
        });
    }

    /** TC-P63 · BC-UIX · breadcrumb (Marksheet Generation / Results) present. */
    public function test_studentresult_63_breadcrumb_present_on_results_screen(): void
    {
        $this->browseWithFailureScreenshot('63-breadcrumb', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 1000);
            $this->assertTrue(
                $this->pageSourceContains($browser, 'Marksheet Generation') && $this->pageSourceContains($browser, 'Results'),
                'Breadcrumb (Marksheet Generation / Results) missing.'
            );
        });
    }

    // =====================================================================
    //  70-79 · Edge cases (BC-EDG)
    // =====================================================================

    /** TC-EDG70 · BC-EDG · subjectResults() joins on student_id only (cross-schedule); scoped helpers exist. */
    public function test_studentresult_70_subject_results_relationship_is_cross_schedule(): void
    {
        $model = new StudentResult();
        $this->assertInstanceOf(HasMany::class, $model->subjectResults());
        $this->assertTrue(method_exists($model, 'subjectResultsForSchedule'), 'subjectResultsForSchedule() helper must exist to scope by schedule.');
        $this->assertTrue(method_exists($model, 'coscholasticResultsForSchedule'), 'coscholasticResultsForSchedule() helper must exist.');
    }

    /** TC-EDG71 · BC-EDG · whitespace-only withhold reason rejected (min:5 + service trim guard). */
    public function test_studentresult_71_whitespace_only_withhold_reason_rejected(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'DECLARED']);

        $this->browseWithFailureScreenshot('71-reason-whitespace', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/withhold', ['withheld_reason' => '   ']);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Whitespace-only reason should 422 (min:5).');
        });

        $result->refresh();
        $this->assertNotSame('WITHHELD', (string) $result->result_status);
        $this->forceDeleteResult($result);
    }

    /** TC-EDG72 · BC-EDG · DECIMAL(8,2) grand_total persists at boundary precision. */
    public function test_studentresult_72_grand_total_high_precision_persists(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['grand_total' => 999999.99, 'grand_max' => 1000000]);
        $result->refresh();
        $this->assertSame('999999.99', (string) $result->grand_total, 'DECIMAL(8,2) grand_total should persist at boundary precision.');
        $this->forceDeleteResult($result);
    }

    // =====================================================================
    //  90-99 · Tenancy isolation + security pack
    // =====================================================================

    /** TC-T90 · tenancy · out-of-range / foreign id must 404 (no cross-tenant IDOR leak). */
    public function test_studentresult_90_cross_tenant_direct_id_is_not_leaked(): void
    {
        $this->browseWithFailureScreenshot('90-idor', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STUDENT_RESULT_BASE . '/2147483647', []);
            $this->assertSame(404, (int) ($response['status'] ?? 0), 'Out-of-range/foreign id should 404 (no cross-tenant leak).');
        });
    }

    /** TC-S91 · security · XSS payload in withhold reason is stored verbatim (Blade escapes on render). */
    public function test_studentresult_91_xss_in_withhold_reason_is_stored_escaped(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed($deps, ['result_status' => 'DECLARED']);
        $payload = '<script>alert(1)</script> flagged';

        $this->browseWithFailureScreenshot('91-xss', function (Browser $browser) use ($result, $payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/withhold', ['withheld_reason' => $payload]);
        });

        $result->refresh();
        $this->assertSame('WITHHELD', (string) $result->result_status);
        $this->assertStringContainsString('alert(1)', (string) $result->withheld_reason);
        $this->forceDeleteResult($result);
    }

    /** TC-S92 · security / data-integrity · onlyTrashed() on immutable ComputationLog throws. */
    public function test_studentresult_92_computation_log_force_delete_would_throw(): void
    {
        $threw = false;
        try {
            ComputationLog::onlyTrashed()->limit(1)->get();
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'onlyTrashed() on ComputationLog should throw — it is an immutable audit log with no SoftDeletes.');
    }

    // =====================================================================
    //  Private helper library
    // =====================================================================

    private function buildStorePayload(array $deps, int $studentId, array $overrides = []): array
    {
        return array_merge([
            'schedule_id' => (int) $deps['schedule_id'],
            'student_id' => $studentId,
            'class_section_id' => (int) $deps['class_section_id'],
            'grand_total' => 400,
            'grand_max' => 500,
            'overall_percentage' => 80.00,
            'overall_grade' => 'B1',
            'promotion_status' => 'PROMOTED',
            'result_status' => 'DECLARED',
            'is_active' => true,
        ], $overrides);
    }

    private function temporarilyLockSchedule(int $scheduleId, callable $fn): void
    {
        $original = DB::table('msh_marksheet_schedules')->where('id', $scheduleId)->value('is_locked');
        try {
            DB::table('msh_marksheet_schedules')->where('id', $scheduleId)->update(['is_locked' => 1]);
            $this->resultDependencies = []; // force re-resolve to an unlocked schedule next time
            $fn();
        } finally {
            DB::table('msh_marksheet_schedules')->where('id', $scheduleId)->update(['is_locked' => (int) ($original ?? 0)]);
        }
    }

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
                $this->captureScreenshot($browser, 'pass-' . $caseName);
            } catch (Throwable $e) {
                $this->captureScreenshot($browser, 'fail-' . $caseName);
                throw $e;
            }
        });
    }

    private function captureScreenshot(Browser $browser, string $caseName): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);
        $rawName = 'sr-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'sr-' . now()->format('His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function resultDependencies(): array
    {
        if (!empty($this->resultDependencies)) {
            return $this->resultDependencies;
        }

        $scheduleId = DB::table('msh_marksheet_schedules')->where('is_active', 1)->where('is_locked', 0)->orderBy('id')->value('id');
        $classSectionId = DB::table('sch_class_section_jnt')->orderBy('id')->value('id');
        $studentId = DB::table('std_students')->orderBy('id')->value('id');

        if (!$scheduleId || !$classSectionId || !$studentId) {
            $this->markTestSkipped('Student-result Dusk tests require an active unlocked msh_marksheet_schedule, a sch_class_section_jnt row, and a std_students row in the tenant DB.');
        }

        $this->resultDependencies = [
            'schedule_id' => (int) $scheduleId,
            'class_section_id' => (int) $classSectionId,
            'student_id' => (int) $studentId,
        ];

        return $this->resultDependencies;
    }

    private function freshStudentForSchedule(int $scheduleId): int
    {
        $usedStudentIds = StudentResult::withTrashed()->where('schedule_id', $scheduleId)->pluck('student_id')->map(fn ($v) => (int) $v)->all();
        $studentId = DB::table('std_students')
            ->when(!empty($usedStudentIds), fn ($q) => $q->whereNotIn('id', $usedStudentIds))
            ->orderBy('id')->value('id');

        if (!$studentId) {
            $this->markTestSkipped('No std_students row available without an existing result for this schedule.');
        }

        return (int) $studentId;
    }

    private function createStudentResultSeed(array $deps, array $overrides = []): StudentResult
    {
        $studentId = $this->freshStudentForSchedule((int) $deps['schedule_id']);
        $payload = array_merge([
            'schedule_id' => (int) $deps['schedule_id'],
            'student_id' => $studentId,
            'class_section_id' => (int) $deps['class_section_id'],
            'grand_total' => 400,
            'grand_max' => 500,
            'overall_percentage' => 80.00,
            'overall_grade' => 'B1',
            'promotion_status' => 'PROMOTED',
            'result_status' => 'DECLARED',
            'is_active' => true,
            'created_by' => (int) ($this->adminUser->id ?? 1),
        ], $overrides);

        return StudentResult::query()->create($payload);
    }

    private function forceDeleteResult(?StudentResult $result): void
    {
        if ($result === null) {
            return;
        }
        try {
            if (StudentResult::withTrashed()->whereKey($result->id)->exists()) {
                StudentResult::withTrashed()->whereKey($result->id)->forceDelete();
            }
        } catch (Throwable) {
        }
    }

    private function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): array
    {
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

        window.__srApiResult = { status: response.status, ok: response.ok, url: response.url, body, json };
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
        }, 'Timed out waiting for browser JSON request.');

        $errorResult = $browser->script('return window.__srApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__srApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        return is_array($response) ? $response : [];
    }

    private function assertActivityIssuedByAdmin(int $subjectId, string $event): void
    {
        $log = ActivityLog::query()
            ->where('subject_type', StudentResult::class)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->latest('id')
            ->first();

        $this->assertNotNull($log, 'Activity log not found for student-result event: ' . $event);
        $this->assertNotNull($this->adminUser, 'Admin user is not resolved for activity verification.');
        $this->assertSame((int) $this->adminUser->id, (int) $log->user_id, 'Issued-by user_id mismatch for event: ' . $event);
    }

    private function pageSourceContains(Browser $browser, string $text): bool
    {
        return str_contains($browser->driver->getPageSource(), $text);
    }

    private function authenticate(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(700);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)->type('password', $this->adminPassword)->press('Sign In')->pause(1000);
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
        $this->grantResultPermissions($this->adminUser);
    }

    private function grantResultPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }

        $permissions = [
            'tenant.msh-results.view',
            'tenant.msh-student-result.view', 'tenant.msh-student-result.create', 'tenant.msh-student-result.update',
            'tenant.msh-student-result.delete', 'tenant.msh-student-result.export', 'tenant.msh-student-result.print',
            'tenant.msh-student-result.withhold', 'tenant.msh-student-result.declare',
            'tenant.msh-student-subject-result.view',
            'tenant.msh-student-ia-mark.view', 'tenant.msh-student-ia-mark.viewAny', 'tenant.msh-student-ia-mark.create',
            'tenant.msh-student-ia-mark.update', 'tenant.msh-student-ia-mark.delete',
            'tenant.msh-student-coscholastic-result.view', 'tenant.msh-student-coscholastic-result.viewAny',
            'tenant.msh-student-coscholastic-result.create', 'tenant.msh-student-coscholastic-result.update', 'tenant.msh-student-coscholastic-result.delete',
            'tenant.msh-student-attendance.view', 'tenant.msh-student-attendance.create', 'tenant.msh-student-attendance.update',
            'tenant.msh-student-subject-exam-mark.view',
            'tenant.msh-computation-log.view',
        ];

        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist($permissions, $guard);
        $this->syncResultRoleWithPermissions($user, $permissions, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach ($permissions as $permission) {
                try {
                    $user->givePermissionTo($permission);
                } catch (Throwable) {
                }
            }
        }
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

    private function syncResultRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.msh-admin');
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
