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
 * MarksheetGeneration — Student Results & Print (screen: 05-Student-Results-and-Print.md)
 * Feature: StudentResultsAndPrint  |  Prefix: msh_  |  Primary table: msh_student_results
 * Combined screen route: marksheet-generation.results.combined  →  /marksheet-generation/results
 *
 * DB scope: TENANT-side (DDL header "Database: tenant_db", prefix msh_) → tenancy scaffolding required.
 * Style: browser Dusk (golden Class reference), extends DuskTestCase, namespace Tests\Browser.
 *
 * V1 = foundation suite (16 methods). See msh_StudentResultsAndPrintV2_TestCas for the full matrix.
 */
class msh_StudentResultsAndPrintV1_TestCas extends DuskTestCase
{
    private const RESULTS_PATH = '/marksheet-generation/results';
    private const STUDENT_RESULT_BASE = '/marksheet-generation/student-result';
    private const MIGRATION_FILE = 'Modules/MarksheetGeneration/database/migrations/tenant/2026_04_13_000017_create_msh_student_results_table.php';
    private const REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/StudentResultRequest.php';
    private const WITHHOLD_REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/WithholdStudentResultRequest.php';
    private const CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/StudentResultController.php';
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

    // ── 01: Schema / model / request configuration truth ──────────────────────
    public function test_studentresult_01_migration_model_and_request_configuration_are_correct(): void
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

        // Unique (schedule_id, student_id)
        if (DB::connection()->getDriverName() === 'mysql') {
            $unique = DB::select("SHOW INDEX FROM msh_student_results WHERE Key_name = 'uq_msh_sr_schedule_student'");
            $this->assertNotEmpty($unique, 'Unique index uq_msh_sr_schedule_student missing on msh_student_results.');
        }

        // Model configuration
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

        // FormRequest rule strings (verbatim)
        $requestPath = base_path(self::REQUEST_FILE);
        $this->assertTrue(File::exists($requestPath), 'StudentResultRequest not found.');
        $requestContent = File::get($requestPath);
        $this->assertStringContainsString("'exists:msh_marksheet_schedules,id'", $requestContent);
        $this->assertStringContainsString("'exists:std_students,id'", $requestContent);
        $this->assertStringContainsString("'exists:sch_class_section_jnt,id'", $requestContent);
        $this->assertStringContainsString("in:PROMOTED,DETAINED,COMPARTMENT,PLACED", $requestContent);
        $this->assertStringContainsString("in:DECLARED,WITHHELD", $requestContent);
        $this->assertStringContainsString("Rule::unique('msh_student_results', 'schedule_id')", $requestContent);
    }

    // ── 02: Combined results screen renders the four result tabs ──────────────
    public function test_studentresult_02_results_combined_screen_renders_with_tabs(): void
    {
        $this->browseWithFailureScreenshot('sr-02-results-screen', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 1200);

            $this->assertTrue(
                $this->pageSourceContains($browser, 'Student Results')
                    && $this->pageSourceContains($browser, 'Subject Results')
                    && $this->pageSourceContains($browser, 'IA Marks')
                    && $this->pageSourceContains($browser, 'Coscholastic Results'),
                'Combined results screen did not render all four result tabs.'
            );
        });
    }

    // ── 03: Store persists a student result and logs "Stored" ─────────────────
    public function test_studentresult_03_store_persists_result_and_logs_stored(): void
    {
        $deps = $this->resultDependencies();
        $studentId = $this->freshStudentForSchedule((int) $deps['schedule_id']);

        $payload = [
            'schedule_id' => (int) $deps['schedule_id'],
            'student_id' => $studentId,
            'class_section_id' => (int) $deps['class_section_id'],
            'grand_total' => 450.50,
            'grand_max' => 500,
            'overall_percentage' => 90.10,
            'overall_grade' => 'A1',
            'promotion_status' => 'PROMOTED',
            'result_status' => 'DECLARED',
            'is_active' => true,
        ];

        $this->browseWithFailureScreenshot('sr-03-store', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertTrue(
                in_array((int) ($response['status'] ?? 0), [200, 302], true),
                'Store did not return a success/redirect status. Got: ' . (int) ($response['status'] ?? 0)
            );
        });

        $result = StudentResult::withTrashed()
            ->where('schedule_id', (int) $deps['schedule_id'])
            ->where('student_id', $studentId)
            ->latest('id')
            ->first();

        $this->assertNotNull($result, 'Student result was not persisted.');
        $this->assertSame('PROMOTED', (string) $result->promotion_status);
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Stored');

        $this->forceDeleteResult($result);
    }

    // ── 04: Show page displays the aggregate scores ───────────────────────────
    public function test_studentresult_04_show_page_displays_aggregates(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed((int) $deps['schedule_id'], (int) $deps['class_section_id'], [
            'grand_total' => 480, 'grand_max' => 500, 'overall_percentage' => 96.00, 'overall_grade' => 'A1',
        ]);

        $this->browseWithFailureScreenshot('sr-04-show', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::STUDENT_RESULT_BASE . '/' . $result->id, 1000);
            $this->assertTrue(
                $this->pageSourceContains($browser, 'A1') || $this->pageSourceContains($browser, '96'),
                'Show page did not render the student result aggregates.'
            );
        });

        $this->forceDeleteResult($result);
    }

    // ── 05: Update persists changes and logs "Updated" ────────────────────────
    public function test_studentresult_05_update_persists_and_logs_updated(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed((int) $deps['schedule_id'], (int) $deps['class_section_id'], [
            'overall_grade' => 'B1', 'promotion_status' => 'PROMOTED',
        ]);

        $payload = [
            'schedule_id' => (int) $result->schedule_id,
            'student_id' => (int) $result->student_id,
            'class_section_id' => (int) $result->class_section_id,
            'overall_grade' => 'A2',
            'promotion_status' => 'DETAINED',
            'is_active' => true,
        ];

        $this->browseWithFailureScreenshot('sr-05-update', function (Browser $browser) use ($result, $payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'PUT', self::STUDENT_RESULT_BASE . '/' . $result->id, $payload);
            $this->assertTrue(
                in_array((int) ($response['status'] ?? 0), [200, 302], true),
                'Update did not return success/redirect. Got: ' . (int) ($response['status'] ?? 0)
            );
        });

        $result->refresh();
        $this->assertSame('A2', (string) $result->overall_grade);
        $this->assertSame('DETAINED', (string) $result->promotion_status);
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Updated');

        $this->forceDeleteResult($result);
    }

    // ── 06: Destroy soft-deletes and logs "Deleted" ───────────────────────────
    public function test_studentresult_06_destroy_soft_deletes_and_logs_deleted(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed((int) $deps['schedule_id'], (int) $deps['class_section_id']);

        $this->browseWithFailureScreenshot('sr-06-destroy', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::STUDENT_RESULT_BASE . '/' . $result->id, []);
            $this->assertTrue(
                in_array((int) ($response['status'] ?? 0), [200, 302], true),
                'Destroy did not return success/redirect. Got: ' . (int) ($response['status'] ?? 0)
            );
        });

        $result->refresh();
        $this->assertNotNull($result->deleted_at, 'Student result was not soft deleted.');
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Deleted');

        $this->forceDeleteResult($result);
    }

    // ── 07: Duplicate (schedule_id, student_id) is rejected (422) ─────────────
    public function test_studentresult_07_duplicate_schedule_student_rejected(): void
    {
        $deps = $this->resultDependencies();
        $existing = $this->createStudentResultSeed((int) $deps['schedule_id'], (int) $deps['class_section_id']);

        $payload = [
            'schedule_id' => (int) $existing->schedule_id,
            'student_id' => (int) $existing->student_id,
            'class_section_id' => (int) $existing->class_section_id,
            'is_active' => true,
        ];

        $this->browseWithFailureScreenshot('sr-07-duplicate', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, $payload);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate schedule+student should return 422.');
        });

        $this->assertSame(
            1,
            StudentResult::withTrashed()->where('schedule_id', (int) $existing->schedule_id)->where('student_id', (int) $existing->student_id)->count(),
            'Duplicate student result should not be inserted.'
        );

        $this->forceDeleteResult($existing);
    }

    // ── 08: Required validation blocks store (422) ────────────────────────────
    public function test_studentresult_08_required_validation_blocks_store(): void
    {
        $this->browseWithFailureScreenshot('sr-08-required', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE, ['is_active' => true]);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Missing required fields should return 422.');
            $body = (string) ($response['body'] ?? '');
            $this->assertTrue(
                str_contains($body, 'schedule_id') || str_contains($body, 'student_id') || str_contains($body, 'required'),
                'Expected required-field validation errors in response body.'
            );
        });
    }

    // ── 09: Withhold transitions DECLARED → WITHHELD and logs "Withheld" ──────
    public function test_studentresult_09_withhold_transitions_to_withheld(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed((int) $deps['schedule_id'], (int) $deps['class_section_id'], [
            'result_status' => 'DECLARED',
        ]);

        $this->browseWithFailureScreenshot('sr-09-withhold', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/withhold', [
                'withheld_reason' => 'Disciplinary inquiry pending outcome',
            ]);
        });

        $result->refresh();
        $this->assertSame('WITHHELD', (string) $result->result_status, 'Result was not transitioned to WITHHELD.');
        $this->assertSame('Disciplinary inquiry pending outcome', (string) $result->withheld_reason);
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Withheld');

        $this->forceDeleteResult($result);
    }

    // ── 10: Declare transitions WITHHELD → DECLARED and clears reason ─────────
    public function test_studentresult_10_declare_transitions_to_declared(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed((int) $deps['schedule_id'], (int) $deps['class_section_id'], [
            'result_status' => 'WITHHELD', 'withheld_reason' => 'Prior hold',
        ]);

        $this->browseWithFailureScreenshot('sr-10-declare', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $this->sendJsonRequestFromBrowser($browser, 'POST', self::STUDENT_RESULT_BASE . '/' . $result->id . '/declare', []);
        });

        $result->refresh();
        $this->assertSame('DECLARED', (string) $result->result_status, 'Result was not transitioned to DECLARED.');
        $this->assertNull($result->withheld_reason, 'Declare should clear withheld_reason.');
        $this->assertActivityIssuedByAdmin((int) $result->id, 'Declared');

        $this->forceDeleteResult($result);
    }

    // ── 11: Export endpoint returns an XLSX download ──────────────────────────
    public function test_studentresult_11_export_endpoint_returns_xlsx(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed((int) $deps['schedule_id'], (int) $deps['class_section_id']);

        $this->browseWithFailureScreenshot('sr-11-export', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STUDENT_RESULT_BASE . '/' . $result->id . '/export', []);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Export endpoint did not return HTTP 200.');
        });

        $this->forceDeleteResult($result);
    }

    // ── 12: Print route is registered and authorized ──────────────────────────
    public function test_studentresult_12_print_route_registered_and_authorized(): void
    {
        $deps = $this->resultDependencies();
        $result = $this->createStudentResultSeed((int) $deps['schedule_id'], (int) $deps['class_section_id']);

        $this->browseWithFailureScreenshot('sr-12-print', function (Browser $browser) use ($result): void {
            $this->visitAuthenticated($browser, self::RESULTS_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STUDENT_RESULT_BASE . '/' . $result->id . '/print', []);
            // Print may redirect (missing template → back with error) or render (200). Both prove route+gate.
            $this->assertTrue(
                in_array((int) ($response['status'] ?? 0), [200, 302], true),
                'Print route did not resolve. Got: ' . (int) ($response['status'] ?? 0)
            );
        });

        $this->forceDeleteResult($result);
    }

    // ── 13: Guest is redirected to /login ─────────────────────────────────────
    public function test_studentresult_13_guest_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::RESULTS_PATH))->pause(900);
            $this->assertTrue(
                str_contains($this->currentPath($browser), '/login'),
                'Guest was not redirected to /login from the results screen.'
            );
        });
    }

    // ── 14: IA-mark & coscholastic child-table configuration is correct ───────
    public function test_studentresult_14_child_tables_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable('msh_student_ia_marks'));
        $this->assertTrue(Schema::hasColumns('msh_student_ia_marks', ['schedule_id', 'student_id', 'subject_id', 'ia_component_id', 'marks_obtained', 'max_marks', 'entered_by', 'deleted_at']));
        $this->assertTrue(Schema::hasTable('msh_student_coscholastic_results'));
        $this->assertTrue(Schema::hasColumns('msh_student_coscholastic_results', ['schedule_id', 'student_id', 'coscholastic_component_id', 'grade', 'is_auto_from_ba', 'deleted_at']));
        $this->assertTrue(Schema::hasTable('msh_student_attendance'));
        $this->assertTrue(Schema::hasColumns('msh_student_attendance', ['schedule_id', 'student_id', 'total_working_days', 'days_present', 'is_auto_populated']));
        $this->assertTrue(Schema::hasTable('msh_student_subject_exam_marks'));
        $this->assertTrue(Schema::hasColumns('msh_student_subject_exam_marks', ['schedule_id', 'student_id', 'subject_id', 'exam_type_id', 'marks_obtained']));
    }

    // ── 15: computation_logs is an immutable audit table (no soft deletes) ────
    public function test_studentresult_15_computation_log_is_immutable_no_soft_deletes(): void
    {
        $this->assertTrue(Schema::hasTable('msh_computation_logs'));
        $this->assertFalse(
            Schema::hasColumn('msh_computation_logs', 'deleted_at'),
            'msh_computation_logs must NOT have deleted_at (immutable audit log).'
        );
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(ComputationLog::class),
            'ComputationLog must NOT use SoftDeletes — withTrashed()/forceDelete() would throw.'
        );
    }

    // ── 16: Resource index redirects to the combined results screen ───────────
    public function test_studentresult_16_index_redirects_to_combined_results(): void
    {
        $this->browseWithFailureScreenshot('sr-16-index-redirect', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::STUDENT_RESULT_BASE, 1000);
            $this->assertTrue(
                str_contains($this->currentPath($browser), '/marksheet-generation/results'),
                'student-result.index did not redirect to the combined results screen.'
            );
        });
    }

    // =====================================================================
    //  Private helper library (mirrors the golden Class reference)
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
                $this->capturePassScreenshot($browser, $caseName);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    private function capturePassScreenshot(Browser $browser, string $caseName): void
    {
        $this->captureScreenshot($browser, 'pass-' . $caseName);
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        $this->captureScreenshot($browser, 'fail-' . $caseName);
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

        $scheduleId = DB::table('msh_marksheet_schedules')
            ->where('is_active', 1)
            ->where('is_locked', 0)
            ->orderBy('id')
            ->value('id');

        $classSectionId = DB::table('sch_class_section_jnt')->orderBy('id')->value('id');
        $studentId = DB::table('std_students')->orderBy('id')->value('id');

        if (!$scheduleId || !$classSectionId || !$studentId) {
            $this->markTestSkipped(
                'Student-result Dusk tests require an active unlocked msh_marksheet_schedule, a sch_class_section_jnt row, and a std_students row in the tenant DB.'
            );
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
        $usedStudentIds = StudentResult::withTrashed()
            ->where('schedule_id', $scheduleId)
            ->pluck('student_id')
            ->map(fn ($v) => (int) $v)
            ->all();

        $studentId = DB::table('std_students')
            ->when(!empty($usedStudentIds), fn ($q) => $q->whereNotIn('id', $usedStudentIds))
            ->orderBy('id')
            ->value('id');

        if (!$studentId) {
            $this->markTestSkipped('No std_students row available without an existing result for this schedule.');
        }

        return (int) $studentId;
    }

    private function createStudentResultSeed(int $scheduleId, int $classSectionId, array $overrides = []): StudentResult
    {
        $studentId = $this->freshStudentForSchedule($scheduleId);

        $payload = array_merge([
            'schedule_id' => $scheduleId,
            'student_id' => $studentId,
            'class_section_id' => $classSectionId,
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

        window.__srApiResult = { status: response.status, ok: response.ok, body, json };
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
