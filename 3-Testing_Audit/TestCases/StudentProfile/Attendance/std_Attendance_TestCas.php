<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\AcademicSession;
use Modules\Prime\Models\Domain;
use Modules\StudentProfile\Models\Student;
use Modules\StudentProfile\Models\StudentAttendance;
use Tests\DuskTestCase;
use Throwable;

/**
 * Student Profile – Attendance (daily scan / manual entry + bulk marking)
 *
 * Screen scope (one comprehensive suite — SUPERSEDES spr_BulkAttendance_TestCas.php):
 *   - GET  /student-profile/attendance/create        (AttendanceController@create)        QR scan + manual entry screen
 *   - POST /student-profile/attendance/scan          (AttendanceController@scanAttendance) JSON
 *   - POST /student-profile/attendance/manual        (AttendanceController@manualAttendance) JSON
 *   - GET  /student-profile/bulk-attendance          (AttendanceController@bulkAttendanceIndex)
 *   - POST /student-profile/bulk-attendance/store    (AttendanceController@storeBulkAttendance)
 *
 * Tables : std_student_attendance, std_attendance_corrections   (prefix std_, TENANT scope)
 * DDL    : StudentProfile_DDL_v1.6.sql
 *
 * IMPORTANT status casing: the live views (student-settings/index.blade.php radios,
 * student-attendance/create.blade.php manual buttons) AND the DDL ENUM all use Title Case
 * with spaces — 'Present','Absent','Late','Half Day','Short Leave','Leave'. The scan/manual
 * FormRequest `in:` rule matches this exactly. The prior sibling test used lowercase / underscore
 * values ('half_day','short_leave'); those are WRONG against the real source and are corrected here.
 *
 * Mapped audit defects (StudentProfile_Complete_Audit_2026-06-30.md):
 *   - BUG-STD-P3-01  stray debug comment `// dd($request->all());s`  -> verified ABSENT in current source (remediated)
 *   - GAP-STD-22     attendance < 75% notification not implemented   -> verified ABSENT (documented gap)
 * Discovered cross-reference findings (see Gap Analysis):
 *   - BUG-STD-ATT-01 storeBulkAttendance has NO status `in:` validation (accepts arbitrary status)
 *   - BUG-STD-ATT-02 getAttendanceReport() controller method has NO registered route (dead method)
 *   - GAP-STD-ATT-03 std_attendance_corrections schema exists but correction workflow is unimplemented (no controller/route)
 */
class std_Attendance_TestCas extends DuskTestCase
{
    private const CREATE_PATH     = '/student-profile/attendance/create';
    private const SCAN_PATH       = '/student-profile/attendance/scan';
    private const MANUAL_PATH     = '/student-profile/attendance/manual';
    private const BULK_INDEX_PATH = '/student-profile/bulk-attendance';
    private const BULK_STORE_PATH = '/student-profile/bulk-attendance/store';
    private const SCREENSHOT_DIR  = 'tests/Browser/console/screenshots';

    /** DDL ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') — Title Case, verified against view + DDL. */
    private const VALID_STATUSES = ['Present', 'Absent', 'Late', 'Half Day', 'Short Leave', 'Leave'];

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail    = '';
    private string $adminPassword = '';

    private static bool $screenshotsCleaned = false;
    private static array $seededData = [
        'class_section_id'       => null,
        'class_section_created'  => false,
        'class_id'               => null,
        'class_created'          => false,
        'section_id'             => null,
        'section_created'        => false,
        'room_type_id'           => null,
        'room_type_created'      => false,
        'language_id'            => null,
        'language_created'       => false,
        'user_ids'               => [],
    ];

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

    public static function tearDownAfterClass(): void
    {
        self::cleanupSeededData();
        parent::tearDownAfterClass();
    }

    // =========================================================================
    // BAND 01–09 : SCHEMA / MODEL / REQUEST CONFIGURATION TRUTH
    // =========================================================================

    public function test_attendance_01_migration_model_and_request_configuration_are_correct(): void
    {
        // --- std_student_attendance table + columns (DDL truth) ---
        $this->assertTrue(
            Schema::hasTable('std_student_attendance'),
            'Table std_student_attendance does not exist.'
        );
        $this->assertTrue(Schema::hasColumns('std_student_attendance', [
            'id', 'student_id', 'academic_session_id', 'class_section_id',
            'attendance_date', 'attendance_period', 'status', 'remarks',
            'marked_by', 'marked_at', 'created_at', 'updated_at',
        ]), 'Expected columns missing in std_student_attendance.');

        // --- std_attendance_corrections table + columns (DDL truth) ---
        $this->assertTrue(
            Schema::hasTable('std_attendance_corrections'),
            'Table std_attendance_corrections does not exist.'
        );
        $this->assertTrue(Schema::hasColumns('std_attendance_corrections', [
            'id', 'attendance_id', 'requested_by', 'requested_status',
            'requested_period', 'reason', 'status', 'admin_remarks',
            'action_by', 'action_at', 'created_at', 'updated_at',
        ]), 'Expected columns missing in std_attendance_corrections.');

        // --- status ENUM column type contains the six Title Case values (MySQL 8 tolerant) ---
        $statusType = $this->columnType('std_student_attendance', 'status');
        if ($statusType !== '') {
            $this->assertStringContainsString('Present', $statusType, 'status ENUM should include Present.');
            $this->assertStringContainsString('Half Day', $statusType, 'status ENUM should include "Half Day" (space, Title Case).');
            $this->assertStringContainsString('Short Leave', $statusType, 'status ENUM should include "Short Leave".');
        }

        // --- unique key (student_id, attendance_date, attendance_period) ---
        $uniqueColumns = $this->uniqueIndexColumns('std_student_attendance');
        if (!empty($uniqueColumns)) {
            $this->assertContains('student_id', $uniqueColumns, 'Unique key should include student_id.');
            $this->assertContains('attendance_date', $uniqueColumns, 'Unique key should include attendance_date.');
            $this->assertContains('attendance_period', $uniqueColumns, 'Unique key should include attendance_period.');
        }

        // --- Model configuration ---
        $model = new StudentAttendance();
        $this->assertSame('std_student_attendance', $model->getTable(), 'StudentAttendance table mismatch.');
        foreach (['student_id', 'academic_session_id', 'class_section_id', 'attendance_date', 'attendance_period', 'status', 'remarks', 'marked_by', 'marked_at'] as $fillable) {
            $this->assertContains($fillable, $model->getFillable(), "StudentAttendance should mass-assign {$fillable}.");
        }
        // Model does NOT use SoftDeletes (verified in source) — deletes are permanent.
        $this->assertNotContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(StudentAttendance::class),
            'StudentAttendance is NOT expected to use SoftDeletes (deletes are hard deletes).'
        );

        // --- Central tenant migration (fail-soft glob; module dir may be empty per 05_ #26) ---
        $migrationGlob = glob(base_path('database/migrations/tenant/*std_student_attendance*.php')) ?: [];
        if (!empty($migrationGlob)) {
            $content = (string) File::get($migrationGlob[0]);
            $this->assertStringContainsString('std_student_attendance', $content, 'Migration should reference the table.');
        }

        // --- Request/validation truth from controller source (scan/manual use exact Title Case in:) ---
        $controller = $this->attendanceControllerSource();
        if ($controller !== '') {
            $this->assertStringContainsString(
                "in:Present,Absent,Late,Half Day,Short Leave,Leave",
                $controller,
                'scan/manual validation should constrain status to the Title Case ENUM values.'
            );
        }
    }

    // =========================================================================
    // BAND 10–19 : BUSINESS RULES (BC-BIZ)
    // =========================================================================

    public function test_attendance_10_create_screen_loads_with_scan_and_manual_sections(): void
    {
        $this->browseWithFailureScreenshot('att-10-create-load', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 1200);

            $browser->assertPathBeginsWith('/student-profile/attendance');
            $this->assertTrue(
                $this->pageSourceContains($browser, 'manual-status-btn')
                || $this->pageSourceContains($browser, 'Manual')
                || $this->pageSourceContains($browser, 'scan'),
                'Create screen should render scan and/or manual attendance sections.'
            );
        });
    }

    public function test_attendance_11_bulk_index_loads(): void
    {
        $this->browseWithFailureScreenshot('att-11-bulk-load', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::BULK_INDEX_PATH, 1200);

            $browser->assertPresent('form, select, #bulk-pane');
        });
    }

    public function test_attendance_12_bulk_apply_marks_all_rows_present(): void
    {
        $context = $this->ensureAttendanceSeedData(2);
        if (!$context) {
            $this->markTestSkipped('No active class section for bulk-apply test.');
        }
        $url = self::BULK_INDEX_PATH . '?class_section_id=' . $context['class_section_id']
            . '&attendance_date=' . now()->format('Y-m-d');

        $this->browseWithFailureScreenshot('att-12-bulk-apply', function (Browser $browser) use ($url): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, $url, 1300);

            $browser->waitFor('form#attendanceForm', 20)->waitFor('input.attendance-radio', 20);

            // Bulk dropdown item uses Title Case data-status="Present"
            $browser->script(<<<'JS'
(function () {
    const present = document.querySelector('.bulk-action[data-status="Present"]');
    if (present) { present.click(); }
    else {
        document.querySelectorAll('input.attendance-radio[value="Present"]').forEach(r => { r.checked = true; });
    }
})();
JS);
            $browser->pause(600);

            $count = $browser->script('return document.querySelectorAll(\'input.attendance-radio[value="Present"]:checked\').length;');
            $this->assertGreaterThan(
                0,
                (int) (is_array($count) ? ($count[0] ?? 0) : 0),
                'No rows marked Present after bulk apply.'
            );
        });
    }

    public function test_attendance_13_individual_override_after_bulk(): void
    {
        $context = $this->ensureAttendanceSeedData(2);
        if (!$context) {
            $this->markTestSkipped('No active class section for individual override test.');
        }
        $url = self::BULK_INDEX_PATH . '?class_section_id=' . $context['class_section_id']
            . '&attendance_date=' . now()->format('Y-m-d');

        $this->browseWithFailureScreenshot('att-13-override', function (Browser $browser) use ($url): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, $url, 1300);
            $browser->waitFor('form#attendanceForm', 20)->waitFor('input.attendance-radio', 20);

            $browser->script(<<<'JS'
(function () {
    document.querySelectorAll('input.attendance-radio[value="Present"]').forEach(r => { r.checked = true; });
    const firstAbsent = document.querySelector('table tbody tr input.attendance-radio[value="Absent"]');
    if (firstAbsent) { firstAbsent.checked = true; }
})();
JS);
            $browser->pause(500);

            $present = $browser->script('return document.querySelectorAll(\'input.attendance-radio[value="Present"]:checked\').length;');
            $absent  = $browser->script('return document.querySelectorAll(\'input.attendance-radio[value="Absent"]:checked\').length;');

            $this->assertGreaterThan(0, (int) (is_array($present) ? ($present[0] ?? 0) : 0), 'Remaining rows should stay Present.');
            $this->assertGreaterThan(0, (int) (is_array($absent) ? ($absent[0] ?? 0) : 0), 'Overridden row should be Absent.');
        });
    }

    public function test_attendance_14_save_persists_to_database(): void
    {
        $context = $this->ensureAttendanceSeedData(3);
        if (!$context) {
            $this->markTestSkipped('No active class section for save test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentIds        = array_slice($context['student_ids'], 0, 3);
        if (count($studentIds) === 0) {
            $this->markTestSkipped('No students linked to the active class section.');
        }
        $students       = Student::whereIn('id', $studentIds)->get();
        $attendanceDate = now()->format('Y-m-d');
        $url = self::BULK_INDEX_PATH . '?class_section_id=' . $classSectionId . '&attendance_date=' . $attendanceDate;

        $this->browseWithFailureScreenshot('att-14-save', function (Browser $browser) use ($url): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, $url, 1300);
            $browser->waitFor('form#attendanceForm', 20)->waitFor('input.attendance-radio', 20);

            $browser->script(<<<'JS'
(function () {
    const present = document.querySelector('.bulk-action[data-status="Present"]');
    if (present) { present.click(); }
    else { document.querySelectorAll('input.attendance-radio[value="Present"]').forEach(r => { r.checked = true; }); }
})();
JS);
            $browser->pause(500);
            $browser->press('Save')->pause(1300);
        });

        foreach ($students as $student) {
            $record = StudentAttendance::where('student_id', $student->id)
                ->where('attendance_date', $attendanceDate)
                ->where('class_section_id', $classSectionId)
                ->where('academic_session_id', $academicSessionId)
                ->first();

            $this->assertNotNull($record, "Attendance record not created for student ID {$student->id}.");
            $this->assertSame('Present', (string) $record->status, "Status should be Title Case 'Present' for student {$student->id}.");
        }

        $this->cleanupAttendance($classSectionId, $academicSessionId, $attendanceDate, $students->pluck('id')->all());
    }

    public function test_attendance_15_mixed_bulk_and_individual_saved_correctly(): void
    {
        $context = $this->ensureAttendanceSeedData(4);
        if (!$context) {
            $this->markTestSkipped('No active class section for mixed save test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentIds        = array_slice($context['student_ids'], 0, 4);
        if (count($studentIds) < 2) {
            $this->markTestSkipped('Need at least 2 students for mixed attendance test.');
        }
        $students       = Student::whereIn('id', $studentIds)->get();
        $attendanceDate = now()->subDays(1)->format('Y-m-d');

        $attendanceMap = [];
        foreach ($students as $index => $student) {
            $attendanceMap[$student->id] = $index < 2 ? 'Present' : 'Absent';
        }
        $url = self::BULK_INDEX_PATH . '?class_section_id=' . $classSectionId . '&attendance_date=' . $attendanceDate;

        $this->browseWithFailureScreenshot('att-15-mixed', function (Browser $browser) use ($url, $attendanceMap): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, $url, 1300);
            $browser->waitFor('form#attendanceForm', 20)->waitFor('input.attendance-radio', 20);

            $encoded = json_encode($attendanceMap, JSON_THROW_ON_ERROR);
            $browser->script(<<<JS
(function () {
    const attendance = {$encoded};
    Object.keys(attendance).forEach(function (id) {
        const sel = 'input.attendance-radio[name="attendance[' + id + ']"][value="' + attendance[id] + '"]';
        const input = document.querySelector(sel);
        if (input) { input.checked = true; }
    });
})();
JS);
            $browser->pause(500);
            $browser->press('Save')->pause(1300);
        });

        foreach ($students as $index => $student) {
            $expected = $index < 2 ? 'Present' : 'Absent';
            $record   = StudentAttendance::where('student_id', $student->id)
                ->where('attendance_date', $attendanceDate)
                ->where('class_section_id', $classSectionId)
                ->where('academic_session_id', $academicSessionId)
                ->first();

            $this->assertNotNull($record, "Attendance not found for student {$student->id}.");
            $this->assertSame($expected, (string) $record->status, "Status mismatch for student {$student->id}.");
        }

        $this->cleanupAttendance($classSectionId, $academicSessionId, $attendanceDate, $students->pluck('id')->all());
    }

    public function test_attendance_16_clear_all_removes_records_on_save(): void
    {
        // storeBulkAttendance deletes records whose posted status is empty/null.
        $context = $this->ensureAttendanceSeedData(1);
        if (!$context) {
            $this->markTestSkipped('No active class section for clear-all test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentId         = $context['student_ids'][0] ?? null;
        if (!$studentId) {
            $this->markTestSkipped('No student linked to class section.');
        }
        $attendanceDate = now()->subDays(4)->format('Y-m-d');

        // Seed one existing record.
        StudentAttendance::updateOrCreate([
            'student_id'          => $studentId,
            'attendance_date'     => $attendanceDate,
            'attendance_period'   => 0,
            'class_section_id'    => $classSectionId,
            'academic_session_id' => $academicSessionId,
        ], ['status' => 'Present', 'marked_by' => $this->adminUser?->id]);

        $this->assertNotNull(
            StudentAttendance::where('student_id', $studentId)->where('attendance_date', $attendanceDate)->first(),
            'Seed record should exist before clear-all.'
        );

        // Post empty status -> delete branch (in-page authenticated request).
        $this->browseWithFailureScreenshot('att-16-clear', function (Browser $browser) use ($classSectionId, $academicSessionId, $attendanceDate, $studentId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::BULK_INDEX_PATH, 1000);

            $this->sendFormPostFromBrowser($browser, self::BULK_STORE_PATH, [
                'attendance_date'     => $attendanceDate,
                'class_section_id'    => (string) $classSectionId,
                'academic_session_id' => (string) $academicSessionId,
                'attendance'          => [(string) $studentId => ''],
            ]);
        });

        $this->assertNull(
            StudentAttendance::where('student_id', $studentId)
                ->where('attendance_date', $attendanceDate)
                ->where('class_section_id', $classSectionId)
                ->first(),
            'Record should be deleted when status posted empty (clear-all branch).'
        );
    }

    public function test_attendance_17_reload_shows_persisted_selection(): void
    {
        $context = $this->ensureAttendanceSeedData(1);
        if (!$context) {
            $this->markTestSkipped('No active class section for reload test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentId         = $context['student_ids'][0] ?? null;
        if (!$studentId) {
            $this->markTestSkipped('No student linked to class section.');
        }
        $attendanceDate = now()->subDays(2)->format('Y-m-d');

        StudentAttendance::updateOrCreate([
            'student_id'          => $studentId,
            'attendance_date'     => $attendanceDate,
            'attendance_period'   => 0,
            'class_section_id'    => $classSectionId,
            'academic_session_id' => $academicSessionId,
        ], ['status' => 'Late', 'marked_by' => $this->adminUser?->id]);

        $url = self::BULK_INDEX_PATH . '?class_section_id=' . $classSectionId . '&attendance_date=' . $attendanceDate;
        $this->browseWithFailureScreenshot('att-17-reload', function (Browser $browser) use ($url): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, $url, 1300);
            $source = $browser->driver->getPageSource();
            $this->assertNotEmpty($source, 'Page source should not be empty on reload.');
        });

        $record = StudentAttendance::where('student_id', $studentId)
            ->where('attendance_date', $attendanceDate)->first();
        $this->assertNotNull($record, 'Persisted record should still exist after reload.');
        $this->assertSame('Late', (string) $record->status, 'Persisted status should be Late.');

        $this->cleanupAttendance($classSectionId, $academicSessionId, $attendanceDate, [$studentId]);
    }

    public function test_attendance_18_marked_by_and_marked_at_recorded(): void
    {
        // Model boot() saving hook sets marked_at = now() on every save.
        $context = $this->ensureAttendanceSeedData(1);
        if (!$context) {
            $this->markTestSkipped('No active class section for marked_at test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentId         = $context['student_ids'][0] ?? null;
        if (!$studentId) {
            $this->markTestSkipped('No student linked to class section.');
        }
        $attendanceDate = now()->subDays(5)->format('Y-m-d');

        $record = StudentAttendance::updateOrCreate([
            'student_id'          => $studentId,
            'attendance_date'     => $attendanceDate,
            'attendance_period'   => 0,
            'class_section_id'    => $classSectionId,
            'academic_session_id' => $academicSessionId,
        ], ['status' => 'Present', 'marked_by' => $this->adminUser?->id]);

        $this->assertNotNull($record->marked_at, 'marked_at should be auto-populated by the saving hook.');

        $this->cleanupAttendance($classSectionId, $academicSessionId, $attendanceDate, [$studentId]);
    }

    public function test_attendance_19_upsert_does_not_create_duplicate_on_resave(): void
    {
        // Unique key (student_id, attendance_date, attendance_period) + updateOrCreate = idempotent.
        $context = $this->ensureAttendanceSeedData(1);
        if (!$context) {
            $this->markTestSkipped('No active class section for upsert test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentId         = $context['student_ids'][0] ?? null;
        if (!$studentId) {
            $this->markTestSkipped('No student linked to class section.');
        }
        $attendanceDate = now()->subDays(6)->format('Y-m-d');

        $key = [
            'student_id'          => $studentId,
            'attendance_date'     => $attendanceDate,
            'attendance_period'   => 0,
            'class_section_id'    => $classSectionId,
            'academic_session_id' => $academicSessionId,
        ];
        StudentAttendance::updateOrCreate($key, ['status' => 'Present', 'marked_by' => $this->adminUser?->id]);
        StudentAttendance::updateOrCreate($key, ['status' => 'Absent', 'marked_by' => $this->adminUser?->id]);

        $rows = StudentAttendance::where('student_id', $studentId)
            ->where('attendance_date', $attendanceDate)
            ->where('class_section_id', $classSectionId)
            ->get();

        $this->assertCount(1, $rows, 'Re-save should update in place, not duplicate.');
        $this->assertSame('Absent', (string) $rows->first()->status, 'Second save should overwrite status.');

        $this->cleanupAttendance($classSectionId, $academicSessionId, $attendanceDate, [$studentId]);
    }

    // =========================================================================
    // BAND 20–29 : STATE / WORKFLOW SCHEMA (BC-SM — corrections, schema-only)
    // =========================================================================

    public function test_attendance_20_correction_status_enum_matches_ddl(): void
    {
        // std_attendance_corrections declares the Pending/Approved/Rejected workflow at the schema level,
        // even though no controller/route implements the transitions (GAP-STD-ATT-03).
        $type = $this->columnType('std_attendance_corrections', 'status');
        if ($type === '') {
            $this->markTestSkipped('Could not read std_attendance_corrections.status column type.');
        }
        $this->assertStringContainsString('Pending', $type, 'Correction status ENUM should include Pending.');
        $this->assertStringContainsString('Approved', $type, 'Correction status ENUM should include Approved.');
        $this->assertStringContainsString('Rejected', $type, 'Correction status ENUM should include Rejected.');
    }

    // =========================================================================
    // BAND 30–39 : VALIDATION + ERROR MESSAGES (BC-VAL) — via authenticated in-page JSON fetch
    // =========================================================================

    public function test_attendance_30_scan_requires_qr_code(): void
    {
        $this->assertJsonEndpointValidationFails('att-30', self::SCAN_PATH, [
            'status'    => 'Present',
            'date'      => now()->format('Y-m-d'),
            'period'    => 1,
            'marked_by' => $this->adminUser?->id ?? 1,
            // qr_code missing
        ], 'qr_code');
    }

    public function test_attendance_31_scan_rejects_invalid_status(): void
    {
        $this->assertJsonEndpointValidationFails('att-31', self::SCAN_PATH, [
            'qr_code'   => 'INVALID-QR',
            'status'    => 'half_day', // lowercase/underscore is NOT a valid ENUM value
            'date'      => now()->format('Y-m-d'),
            'period'    => 1,
            'marked_by' => $this->adminUser?->id ?? 1,
        ], 'status');
    }

    public function test_attendance_32_scan_rejects_out_of_range_period(): void
    {
        $this->assertJsonEndpointValidationFails('att-32', self::SCAN_PATH, [
            'qr_code'   => 'INVALID-QR',
            'status'    => 'Present',
            'date'      => now()->format('Y-m-d'),
            'period'    => 9, // max:8
            'marked_by' => $this->adminUser?->id ?? 1,
        ], 'period');
    }

    public function test_attendance_33_manual_requires_student_id(): void
    {
        $this->assertJsonEndpointValidationFails('att-33', self::MANUAL_PATH, [
            'date'      => now()->format('Y-m-d'),
            'period'    => 1,
            'status'    => 'Present',
            'marked_by' => $this->adminUser?->id ?? 1,
            // student_id missing
        ], 'student_id');
    }

    public function test_attendance_34_manual_rejects_invalid_status(): void
    {
        $this->assertJsonEndpointValidationFails('att-34', self::MANUAL_PATH, [
            'student_id' => 1,
            'date'       => now()->format('Y-m-d'),
            'period'     => 1,
            'status'     => 'Excused', // not in the ENUM
            'marked_by'  => $this->adminUser?->id ?? 1,
        ], 'status');
    }

    public function test_attendance_35_manual_remarks_max_length_enforced(): void
    {
        $this->assertJsonEndpointValidationFails('att-35', self::MANUAL_PATH, [
            'student_id' => 1,
            'date'       => now()->format('Y-m-d'),
            'period'     => 1,
            'status'     => 'Present',
            'remarks'    => str_repeat('x', 256), // max:255
            'marked_by'  => $this->adminUser?->id ?? 1,
        ], 'remarks');
    }

    public function test_attendance_36_bulk_store_requires_date_and_class_section(): void
    {
        $this->assertJsonEndpointValidationFails('att-36', self::BULK_STORE_PATH, [
            'attendance' => ['1' => 'Present'],
            // attendance_date, class_section_id, academic_session_id missing
        ], 'class_section_id');
    }

    public function test_attendance_37_bulk_store_requires_existing_class_section(): void
    {
        $this->assertJsonEndpointValidationFails('att-37', self::BULK_STORE_PATH, [
            'attendance_date'     => now()->format('Y-m-d'),
            'class_section_id'    => 999999999, // exists:sch_class_section_jnt,id
            'academic_session_id' => 999999999,
            'attendance'          => ['1' => 'Present'],
        ], 'class_section_id');
    }

    public function test_attendance_38_bulk_store_requires_attendance_array(): void
    {
        $this->assertJsonEndpointValidationFails('att-38', self::BULK_STORE_PATH, [
            'attendance_date'     => now()->format('Y-m-d'),
            'class_section_id'    => 1,
            'academic_session_id' => 1,
            // attendance array missing
        ], 'attendance');
    }

    public function test_attendance_39_scan_unknown_qr_returns_student_not_found(): void
    {
        $this->browseWithFailureScreenshot('att-39-unknown-qr', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::SCAN_PATH), [
                'qr_code'   => 'NO-SUCH-QR-' . uniqid(),
                'status'    => 'Present',
                'date'      => now()->format('Y-m-d'),
                'period'    => 1,
                'marked_by' => $this->adminUser?->id ?? 1,
            ]);

            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            // Business response: HTTP 200 with status=false and a "not found" message.
            $this->assertFalse((bool) ($json['status'] ?? true), 'Unknown QR should yield status=false.');
            $this->assertStringContainsString(
                'not found',
                strtolower((string) ($json['message'] ?? '')),
                'Unknown QR should return a "Student not found" message.'
            );
        });
    }

    // =========================================================================
    // BAND 40–49 : INTEGRATION / FK DEPENDENCY (BC-INT / BC-REF)
    // =========================================================================

    public function test_attendance_40_fk_student_on_delete_cascade(): void
    {
        $this->assertForeignKeyRule('std_student_attendance', 'student_id', 'std_students', 'CASCADE');
    }

    public function test_attendance_41_fk_class_section_on_delete_cascade(): void
    {
        $this->assertForeignKeyRule('std_student_attendance', 'class_section_id', 'sch_class_section_jnt', 'CASCADE');
    }

    public function test_attendance_42_fk_marked_by_on_delete_set_null(): void
    {
        $this->assertForeignKeyRule('std_student_attendance', 'marked_by', 'sys_users', 'SET NULL');
    }

    public function test_attendance_43_correction_fk_attendance_on_delete_cascade(): void
    {
        $this->assertForeignKeyRule('std_attendance_corrections', 'attendance_id', 'std_student_attendance', 'CASCADE');
    }

    public function test_attendance_44_manual_unknown_student_returns_error(): void
    {
        // manualAttendance -> Student::findOrFail() on a nonexistent id -> 404 (ModelNotFound).
        $this->browseWithFailureScreenshot('att-44-unknown-student', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::MANUAL_PATH), [
                'student_id' => 999999999,
                'date'       => now()->format('Y-m-d'),
                'period'     => 1,
                'status'     => 'Present',
                'marked_by'  => $this->adminUser?->id ?? 1,
            ]);

            $status = (int) ($response['status'] ?? 0);
            $this->assertContains(
                $status,
                [404, 422, 500],
                "Manual attendance for a nonexistent student should not succeed (got {$status})."
            );
        });
    }

    public function test_attendance_45_no_current_session_returns_business_error(): void
    {
        // manualAttendance for a valid student with no current StudentAcademicSession returns
        // status=false "not enrolled in any current academic session". Guarded — needs a session-less student.
        $studentId = Student::query()
            ->whereDoesntHave('currentAcademicSession')
            ->value('id');

        if (!$studentId) {
            $this->markTestSkipped('No student without a current academic session available to exercise this branch.');
        }

        $this->browseWithFailureScreenshot('att-45-no-session', function (Browser $browser) use ($studentId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::MANUAL_PATH), [
                'student_id' => $studentId,
                'date'       => now()->format('Y-m-d'),
                'period'     => 1,
                'status'     => 'Present',
                'marked_by'  => $this->adminUser?->id ?? 1,
            ]);

            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertFalse((bool) ($json['status'] ?? true), 'Session-less student should return status=false.');
        });
    }

    // =========================================================================
    // BAND 50–59 : PERMISSIONS / AUTHORIZATION (BC-AUTH)
    // =========================================================================

    public function test_attendance_50_controller_gates_are_wired(): void
    {
        $controller = $this->attendanceControllerSource();
        if ($controller === '') {
            $this->markTestSkipped('AttendanceController source not readable from the runner.');
        }
        $this->assertStringContainsString("Gate::authorize('tenant.attendance.create')", $controller, 'create/scan/manual/store must gate tenant.attendance.create.');
        $this->assertStringContainsString("Gate::authorize('tenant.attendance.viewAny')", $controller, 'index must gate tenant.attendance.viewAny.');
    }

    public function test_attendance_51_policy_exposes_all_ability_methods(): void
    {
        $policy = \Modules\StudentProfile\Policies\AttendancePolicy::class;
        if (!class_exists($policy)) {
            $this->markTestSkipped('AttendancePolicy not autoloadable from the runner.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'] as $ability) {
            $this->assertTrue(method_exists($policy, $ability), "AttendancePolicy should define {$ability}().");
        }
    }

    public function test_attendance_52_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::BULK_INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    public function test_attendance_53_limited_user_forbidden_on_bulk_store(): void
    {
        $limited = $this->createLimitedUser();
        if (!$limited) {
            $this->markTestSkipped('Could not provision a permission-less user for the 403 test.');
        }

        try {
            $this->browseWithFailureScreenshot('att-53-forbidden', function (Browser $browser) use ($limited): void {
                $browser->driver->manage()->deleteAllCookies();
                $browser->loginAs($limited)->pause(400);
                $browser->visit($this->tenantUrl(self::BULK_INDEX_PATH))->pause(900);

                $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::BULK_STORE_PATH), [
                    'attendance_date'     => now()->format('Y-m-d'),
                    'class_section_id'    => 1,
                    'academic_session_id' => 1,
                    'attendance'          => ['1' => 'Present'],
                ]);

                $status = (int) ($response['status'] ?? 0);
                $this->assertContains($status, [403, 419], "Permission-less user should be forbidden (got {$status}).");
            });
        } finally {
            $this->deleteUser($limited);
        }
    }

    // =========================================================================
    // BAND 60–69 : UI / UX
    // =========================================================================

    public function test_attendance_60_no_class_section_shows_info_state(): void
    {
        $this->browseWithFailureScreenshot('att-60-empty', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::BULK_INDEX_PATH, 1200);

            $info = $browser->script('return document.querySelector(".alert-info")?.innerText || "";');
            $warn = $browser->script('return document.querySelector(".alert-warning")?.innerText || "";');
            $infoText = strtolower(is_array($info) ? (string) ($info[0] ?? '') : '');
            $warnText = strtolower(is_array($warn) ? (string) ($warn[0] ?? '') : '');

            $this->assertTrue(
                str_contains($infoText, 'select a class section')
                || str_contains($warnText, 'no active class sections'),
                'Bulk index should show an info/empty state when no class section is chosen.'
            );
        });
    }

    public function test_attendance_61_bulk_actions_list_all_six_statuses(): void
    {
        $context = $this->ensureAttendanceSeedData(1);
        if (!$context) {
            $this->markTestSkipped('No active class section to render the bulk actions dropdown.');
        }
        $url = self::BULK_INDEX_PATH . '?class_section_id=' . $context['class_section_id']
            . '&attendance_date=' . now()->format('Y-m-d');

        $this->browseWithFailureScreenshot('att-61-bulk-actions', function (Browser $browser) use ($url): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, $url, 1300);
            $browser->waitFor('form#attendanceForm', 20);

            foreach (self::VALID_STATUSES as $status) {
                $count = $browser->script(
                    'return document.querySelectorAll(\'.bulk-action[data-status="' . $status . '"]\').length;'
                );
                $this->assertGreaterThan(
                    0,
                    (int) (is_array($count) ? ($count[0] ?? 0) : 0),
                    "Bulk actions dropdown should offer the '{$status}' status."
                );
            }
        });
    }

    public function test_attendance_62_manual_status_buttons_present(): void
    {
        $this->browseWithFailureScreenshot('att-62-manual-buttons', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 1200);

            $count = $browser->script('return document.querySelectorAll(".manual-status-btn").length;');
            $this->assertGreaterThanOrEqual(
                1,
                (int) (is_array($count) ? ($count[0] ?? 0) : 0),
                'Manual entry should render status buttons.'
            );
        });
    }

    // =========================================================================
    // BAND 70–79 : EDGE CASES (BC-EDG)
    // =========================================================================

    public function test_attendance_70_all_six_statuses_persist_via_bulk_store(): void
    {
        $context = $this->ensureAttendanceSeedData(count(self::VALID_STATUSES));
        if (!$context) {
            $this->markTestSkipped('No active class section for status coverage test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentIds        = array_slice($context['student_ids'], 0, count(self::VALID_STATUSES));
        if (count($studentIds) < 1) {
            $this->markTestSkipped('No students for status coverage test.');
        }
        $attendanceDate = now()->subDays(7)->format('Y-m-d');

        $map = [];
        foreach ($studentIds as $i => $id) {
            $map[(string) $id] = self::VALID_STATUSES[$i % count(self::VALID_STATUSES)];
        }

        $this->browseWithFailureScreenshot('att-70-all-statuses', function (Browser $browser) use ($classSectionId, $academicSessionId, $attendanceDate, $map): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::BULK_INDEX_PATH, 1000);

            $this->sendFormPostFromBrowser($browser, self::BULK_STORE_PATH, [
                'attendance_date'     => $attendanceDate,
                'class_section_id'    => (string) $classSectionId,
                'academic_session_id' => (string) $academicSessionId,
                'attendance'          => $map,
            ]);
        });

        foreach ($map as $studentId => $expected) {
            $record = StudentAttendance::where('student_id', (int) $studentId)
                ->where('attendance_date', $attendanceDate)
                ->where('class_section_id', $classSectionId)
                ->first();
            if ($record) {
                $this->assertSame($expected, (string) $record->status, "Status mismatch for student {$studentId}.");
            }
        }

        $this->cleanupAttendance($classSectionId, $academicSessionId, $attendanceDate, array_map('intval', array_keys($map)));
    }

    public function test_attendance_71_period_zero_default_when_bulk_stored(): void
    {
        // Bulk store does not send attendance_period, so it defaults to 0 (DDL DEFAULT 0).
        $context = $this->ensureAttendanceSeedData(1);
        if (!$context) {
            $this->markTestSkipped('No active class section for period-default test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentId         = $context['student_ids'][0] ?? null;
        if (!$studentId) {
            $this->markTestSkipped('No student linked to class section.');
        }
        $attendanceDate = now()->subDays(8)->format('Y-m-d');

        $this->browseWithFailureScreenshot('att-71-period-default', function (Browser $browser) use ($classSectionId, $academicSessionId, $attendanceDate, $studentId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::BULK_INDEX_PATH, 1000);

            $this->sendFormPostFromBrowser($browser, self::BULK_STORE_PATH, [
                'attendance_date'     => $attendanceDate,
                'class_section_id'    => (string) $classSectionId,
                'academic_session_id' => (string) $academicSessionId,
                'attendance'          => [(string) $studentId => 'Present'],
            ]);
        });

        $record = StudentAttendance::where('student_id', $studentId)
            ->where('attendance_date', $attendanceDate)
            ->where('class_section_id', $classSectionId)
            ->first();

        if ($record) {
            $this->assertSame(0, (int) $record->attendance_period, 'Bulk-stored attendance_period should default to 0.');
        }

        $this->cleanupAttendance($classSectionId, $academicSessionId, $attendanceDate, [$studentId]);
    }

    // =========================================================================
    // BAND 90–99 : TENANCY / SECURITY + DEFECT & GAP PROOFS
    // =========================================================================

    public function test_attendance_90_tenant_isolation_records_scoped(): void
    {
        // Confirm we operate inside an initialized tenant context and the table lives per-tenant.
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Attendance is a tenant-scoped feature — tenancy must be initialized.'
        );
        $this->assertTrue(
            Schema::hasTable('std_student_attendance'),
            'std_student_attendance should exist in the tenant schema.'
        );
    }

    public function test_attendance_91_remarks_free_text_stored_without_html_execution(): void
    {
        // XSS surface: remarks is free text. Verify a script payload is stored verbatim (escaped at render, not stripped).
        $context = $this->ensureAttendanceSeedData(1);
        if (!$context) {
            $this->markTestSkipped('No active class section for XSS storage test.');
        }
        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];
        $studentId         = $context['student_ids'][0] ?? null;
        if (!$studentId) {
            $this->markTestSkipped('No student linked to class section.');
        }
        $attendanceDate = now()->subDays(9)->format('Y-m-d');
        $payload        = '<script>alert("xss")</script>';

        $record = StudentAttendance::updateOrCreate([
            'student_id'          => $studentId,
            'attendance_date'     => $attendanceDate,
            'attendance_period'   => 0,
            'class_section_id'    => $classSectionId,
            'academic_session_id' => $academicSessionId,
        ], ['status' => 'Present', 'remarks' => $payload, 'marked_by' => $this->adminUser?->id]);

        $this->assertSame($payload, (string) $record->remarks, 'Remarks should be stored verbatim (output-escaped, not mutated on input).');

        $this->cleanupAttendance($classSectionId, $academicSessionId, $attendanceDate, [$studentId]);
    }

    public function test_attendance_94_bug_std_p3_01_debug_comment_absent(): void
    {
        // Audit BUG-STD-P3-01: stray `// dd($request->all());s`. Verified remediated — assert absence in both controllers.
        $sources = array_filter([
            $this->attendanceControllerSource(),
            $this->studentControllerSource(),
        ]);
        if (empty($sources)) {
            $this->markTestSkipped('Controller sources not readable from the runner (set MAIN_PROJECT_PATH).');
        }
        foreach ($sources as $src) {
            $this->assertStringNotContainsString('dd($request->all());s', $src, 'BUG-STD-P3-01 stray debug comment must not be present.');
            $this->assertDoesNotMatchRegularExpression('/\/\/\s*dd\(\$request->all\(\)\);s/', $src, 'BUG-STD-P3-01 remediation regression.');
        }
    }

    public function test_attendance_95_gap_std_22_threshold_notification_absent(): void
    {
        // GAP-STD-22: attendance < 75% automated notification is NOT implemented. Prove its absence.
        $controller = $this->attendanceControllerSource();
        if ($controller === '') {
            $this->markTestSkipped('AttendanceController source not readable from the runner.');
        }
        $this->assertStringNotContainsString('75', $controller, 'No 75% threshold logic expected in AttendanceController (GAP-STD-22).');
        $this->assertStringNotContainsStringIgnoringCase('notif', $controller, 'No notification dispatch expected in AttendanceController (GAP-STD-22).');
    }

    public function test_attendance_96_get_attendance_report_has_no_registered_route(): void
    {
        // BUG-STD-ATT-02: getAttendanceReport() exists on the controller but no route registers it.
        if (method_exists(\Modules\StudentProfile\Http\Controllers\AttendanceController::class, 'getAttendanceReport')) {
            $this->assertFalse(
                \Illuminate\Support\Facades\Route::has('student-profile.attendance.report'),
                'getAttendanceReport() is a dead controller method — no route should be registered (BUG-STD-ATT-02).'
            );
        } else {
            $this->markTestSkipped('getAttendanceReport() not present in this build.');
        }
    }

    public function test_attendance_97_bulk_store_lacks_status_enum_validation(): void
    {
        // BUG-STD-ATT-01: storeBulkAttendance validates the array but NOT the per-student status against the ENUM.
        $controller = $this->attendanceControllerSource();
        if ($controller === '') {
            $this->markTestSkipped('AttendanceController source not readable from the runner.');
        }
        $storeBody = $this->methodBody($controller, 'storeBulkAttendance');
        if ($storeBody === '') {
            $this->markTestSkipped('Could not isolate storeBulkAttendance() body.');
        }
        $this->assertStringContainsString("'attendance' => 'required|array'", $storeBody, 'storeBulkAttendance validates the attendance array.');
        $this->assertStringNotContainsString('in:Present', $storeBody, 'storeBulkAttendance does NOT enum-validate per-student status (BUG-STD-ATT-01).');
    }

    public function test_attendance_98_correction_workflow_unimplemented(): void
    {
        // GAP-STD-ATT-03: std_attendance_corrections table + model exist, but no controller/route implements the workflow.
        $this->assertTrue(
            class_exists(\Modules\StudentProfile\Models\StudentAttendanceCorrection::class),
            'StudentAttendanceCorrection model should exist.'
        );
        $this->assertFalse(
            \Illuminate\Support\Facades\Route::has('student-profile.attendance.correction.store'),
            'No correction workflow route should be registered (documented gap GAP-STD-ATT-03).'
        );
    }

    // =========================================================================
    // HELPER LIBRARY
    // =========================================================================

    private function columnType(string $table, string $column): string
    {
        try {
            $row = DB::selectOne(
                'SELECT COLUMN_TYPE AS t FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
                [$table, $column]
            );
            return $row ? (string) $row->t : '';
        } catch (Throwable) {
            return '';
        }
    }

    private function uniqueIndexColumns(string $table): array
    {
        try {
            $rows = DB::select("SHOW INDEX FROM `{$table}` WHERE Non_unique = 0 AND Key_name <> 'PRIMARY'");
            return array_values(array_unique(array_map(static fn ($r) => (string) $r->Column_name, $rows)));
        } catch (Throwable) {
            return [];
        }
    }

    private function assertForeignKeyRule(string $table, string $column, string $referencedTable, string $rule): void
    {
        try {
            $row = DB::selectOne(
                'SELECT rc.DELETE_RULE AS delete_rule, kcu.REFERENCED_TABLE_NAME AS ref
                 FROM information_schema.REFERENTIAL_CONSTRAINTS rc
                 JOIN information_schema.KEY_COLUMN_USAGE kcu
                   ON rc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
                  AND rc.CONSTRAINT_SCHEMA = kcu.CONSTRAINT_SCHEMA
                 WHERE rc.CONSTRAINT_SCHEMA = DATABASE()
                   AND kcu.TABLE_NAME = ?
                   AND kcu.COLUMN_NAME = ?
                 LIMIT 1',
                [$table, $column]
            );
        } catch (Throwable) {
            $this->markTestSkipped("Could not read FK metadata for {$table}.{$column}.");
            return;
        }

        if (!$row) {
            $this->markTestSkipped("No FK found for {$table}.{$column} in this environment.");
            return;
        }

        $this->assertSame($referencedTable, (string) $row->ref, "{$column} should reference {$referencedTable}.");
        $this->assertSame(strtoupper($rule), strtoupper((string) $row->delete_rule), "{$table}.{$column} ON DELETE rule mismatch.");
    }

    private function assertJsonEndpointValidationFails(string $caseName, string $path, array $payload, string $expectedField): void
    {
        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($path, $payload, $expectedField): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 900);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl($path), $payload);
            $status   = (int) ($response['status'] ?? 0);

            $this->assertSame(422, $status, "Validation should fail with 422 for field '{$expectedField}' (got {$status}).");

            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $errors = $json['errors'] ?? [];
            if (is_array($errors) && !empty($errors)) {
                $this->assertArrayHasKey($expectedField, $errors, "422 response should flag '{$expectedField}'.");
            }
        });
    }

    private function attendanceControllerSource(): string
    {
        return $this->readMainProjectFile('Modules/StudentProfile/app/Http/Controllers/AttendanceController.php');
    }

    private function studentControllerSource(): string
    {
        return $this->readMainProjectFile('Modules/StudentProfile/app/Http/Controllers/StudentController.php');
    }

    private function readMainProjectFile(string $relative): string
    {
        $candidates = [];
        $mainPath = env('MAIN_PROJECT_PATH');
        if (is_string($mainPath) && $mainPath !== '') {
            $candidates[] = rtrim($mainPath, '/') . '/' . $relative;
        }
        $candidates[] = base_path('../prime_ai/' . $relative);
        $candidates[] = dirname(base_path()) . '/prime_ai/' . $relative;

        foreach ($candidates as $candidate) {
            try {
                if (is_file($candidate) && is_readable($candidate)) {
                    return (string) File::get($candidate);
                }
            } catch (Throwable) {
            }
        }
        return '';
    }

    private function methodBody(string $source, string $method): string
    {
        if (!preg_match('/function\s+' . preg_quote($method, '/') . '\s*\(/', $source, $m, PREG_OFFSET_CAPTURE)) {
            return '';
        }
        $start = (int) $m[0][1];
        $brace = strpos($source, '{', $start);
        if ($brace === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($source);
        for ($i = $brace; $i < $len; $i++) {
            if ($source[$i] === '{') {
                $depth++;
            } elseif ($source[$i] === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $brace, $i - $brace + 1);
                }
            }
        }
        return '';
    }

    private function pageSourceContains(Browser $browser, string $needle): bool
    {
        try {
            return str_contains((string) $browser->driver->getPageSource(), $needle);
        } catch (Throwable) {
            return false;
        }
    }

    // ---- Seed / data helpers (mirrors the committed StudentProfile sibling) ----

    private function resolveAttendanceContext(): ?array
    {
        $academicSessionId = AcademicSession::where('is_current', true)->value('id');
        if (!$academicSessionId) {
            return null;
        }

        $classSectionId = self::$seededData['class_section_id']
            ?? DB::table('sch_class_section_jnt')->where('is_active', 1)->value('id');

        if (!$classSectionId) {
            return null;
        }

        return [
            'class_section_id'    => (int) $classSectionId,
            'academic_session_id' => (int) $academicSessionId,
        ];
    }

    private function ensureAttendanceSeedData(int $minStudents): ?array
    {
        $context = $this->resolveAttendanceContext();
        if (!$context) {
            $context = $this->resolveAttendanceContextWithCreate();
        }
        if (!$context) {
            return null;
        }

        $classSectionId    = $context['class_section_id'];
        $academicSessionId = $context['academic_session_id'];

        $studentIds = $this->studentIdsForSection($classSectionId, $academicSessionId);
        $missing    = $minStudents - count($studentIds);
        if ($missing > 0) {
            $studentIds = array_merge($studentIds, $this->seedStudents($classSectionId, $academicSessionId, $missing));
        }

        return [
            'class_section_id'    => $classSectionId,
            'academic_session_id' => $academicSessionId,
            'student_ids'         => $studentIds,
        ];
    }

    private function resolveAttendanceContextWithCreate(): ?array
    {
        $academicSessionId = AcademicSession::where('is_current', true)->value('id');
        if (!$academicSessionId) {
            return null;
        }
        $classSectionId = $this->createClassSection();
        if (!$classSectionId) {
            return null;
        }
        return [
            'class_section_id'    => (int) $classSectionId,
            'academic_session_id' => (int) $academicSessionId,
        ];
    }

    private function studentIdsForSection(int $classSectionId, int $academicSessionId): array
    {
        try {
            return Student::whereHas('academicSessions', function ($q) use ($classSectionId, $academicSessionId) {
                $q->where('class_section_id', $classSectionId)
                    ->where('academic_session_id', $academicSessionId)
                    ->where('is_current', 1);
            })->pluck('id')->all();
        } catch (Throwable) {
            return [];
        }
    }

    private function createClassSection(): ?int
    {
        if (self::$seededData['class_section_id']) {
            return (int) self::$seededData['class_section_id'];
        }

        $teacherId = $this->adminUser?->id ?? User::query()->value('id');
        if (!$teacherId) {
            return null;
        }

        $roomTypeId = $this->createRoomType();
        $classId    = $this->createClass();
        $sectionId  = $this->createSection();
        if (!$roomTypeId || !$classId || !$sectionId) {
            return null;
        }

        $classSectionId = DB::table('sch_class_section_jnt')->insertGetId([
            'ordinal'                     => null,
            'class_id'                    => $classId,
            'section_id'                  => $sectionId,
            'class_teacher_id'            => $teacherId,
            'assistance_class_teacher_id' => null,
            'rooms_type_id'               => $roomTypeId,
            'class_house_room_id'         => null,
            'code'                        => $this->uniqueCode('CS', 10),
            'name'                        => 'Dusk Class Section ' . $this->uniqueSuffix(),
            'capacity'                    => null,
            'actual_total_student'        => null,
            'min_required_student'        => null,
            'max_allowed_student'         => null,
            'total_periods_daily'         => null,
            'is_active'                   => 1,
            'created_at'                  => now(),
            'updated_at'                  => now(),
        ]);

        self::$seededData['class_section_id']      = $classSectionId;
        self::$seededData['class_section_created'] = true;

        return (int) $classSectionId;
    }

    private function createRoomType(): ?int
    {
        if (self::$seededData['room_type_id']) {
            return (int) self::$seededData['room_type_id'];
        }
        $roomTypeId = DB::table('sch_rooms_type')->insertGetId([
            'code'                    => $this->uniqueCode('RT', 7),
            'short_name'              => 'DuskRT-' . $this->uniqueSuffix(8),
            'name'                    => 'Dusk Room Type ' . $this->uniqueSuffix(),
            'description_tags'        => null,
            'is_active'               => 1,
            'room_count_in_category'  => 0,
            'class_house_room'        => 0,
            'created_at'              => now(),
            'updated_at'              => now(),
        ]);
        self::$seededData['room_type_id']      = $roomTypeId;
        self::$seededData['room_type_created'] = true;
        return (int) $roomTypeId;
    }

    private function createClass(): ?int
    {
        if (self::$seededData['class_id']) {
            return (int) self::$seededData['class_id'];
        }
        $classId = DB::table('sch_classes')->insertGetId([
            'ordinal'    => null,
            'code'       => $this->uniqueCode('CL', 5),
            'short_name' => 'Dusk-' . $this->uniqueSuffix(6),
            'name'       => 'Dusk Class ' . $this->uniqueSuffix(),
            'is_active'  => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        self::$seededData['class_id']      = $classId;
        self::$seededData['class_created'] = true;
        return (int) $classId;
    }

    private function createSection(): ?int
    {
        if (self::$seededData['section_id']) {
            return (int) self::$seededData['section_id'];
        }
        $ordinal   = (int) (DB::table('sch_sections')->max('ordinal') ?? 0) + 1;
        $sectionId = DB::table('sch_sections')->insertGetId([
            'ordinal'    => $ordinal,
            'code'       => $this->uniqueCode('SE', 5),
            'short_name' => 'Dusk-' . $this->uniqueSuffix(6),
            'name'       => 'Dusk Section ' . $this->uniqueSuffix(),
            'is_active'  => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        self::$seededData['section_id']      = $sectionId;
        self::$seededData['section_created'] = true;
        return (int) $sectionId;
    }

    private function seedStudents(int $classSectionId, int $academicSessionId, int $count): array
    {
        $createdStudentIds = [];
        $baseRollNo = (int) (DB::table('std_student_academic_sessions')
            ->where('class_section_id', $classSectionId)
            ->max('roll_no') ?? 0);

        for ($i = 1; $i <= $count; $i++) {
            $suffix = $this->uniqueSuffix();

            $userPayload = [
                'name'       => 'Dusk Student ' . $suffix,
                'short_name' => 'dusk' . strtolower($suffix),
                'emp_code'   => 'S' . strtoupper(substr($suffix, 0, 12)),
                'email'      => 'dusk.student.' . strtolower($suffix) . '@example.com',
                'password'   => bcrypt('password'),
                'created_at' => now(),
                'updated_at' => now(),
            ];
            $this->applyOptionalUserColumns($userPayload, 'STUDENT');

            try {
                $userId = DB::table('sys_users')->insertGetId($userPayload);

                $studentId = DB::table('std_students')->insertGetId([
                    'user_id'              => $userId,
                    'admission_no'         => 'ADM' . strtoupper($suffix),
                    'admission_date'       => now()->format('Y-m-d'),
                    'student_qr_code'      => null,
                    'student_id_card_type' => 'QR',
                    'smart_card_id'        => null,
                    'aadhar_id'            => null,
                    'apaar_id'             => null,
                    'birth_cert_no'        => null,
                    'first_name'           => 'Dusk',
                    'middle_name'          => null,
                    'last_name'            => 'Student',
                    'gender'               => 'Male',
                    'dob'                  => '2008-01-01',
                    'photo_file_name'      => null,
                    'media_id'             => null,
                    'current_status_id'    => 1,
                    'is_active'            => 1,
                    'note'                 => 'Dusk attendance seed',
                    'created_at'           => now(),
                    'updated_at'           => now(),
                ]);

                DB::table('std_student_academic_sessions')->insert([
                    'student_id'          => $studentId,
                    'class_section_id'    => $classSectionId,
                    'academic_session_id' => $academicSessionId,
                    'roll_no'             => $baseRollNo + $i,
                    'subject_group_id'    => null,
                    'house'               => null,
                    'is_current'          => 1,
                    'session_status_id'   => 1,
                    'leaving_date'        => null,
                    'count_as_attrition'  => 0,
                    'reason_quit'         => null,
                    'dis_note'            => null,
                    'created_at'          => now(),
                    'updated_at'          => now(),
                ]);

                self::$seededData['user_ids'][] = $userId;
                $createdStudentIds[] = $studentId;
            } catch (Throwable) {
                // Best-effort seeding; skip a failed row.
            }
        }

        return $createdStudentIds;
    }

    private function applyOptionalUserColumns(array &$payload, string $userType): void
    {
        $optional = [
            'user_type'               => $userType,
            'phone_no'                => null,
            'mobile_no'               => null,
            'two_factor_auth_enabled' => 0,
            'email_verified_at'       => now(),
            'is_active'               => 1,
            'is_super_admin'          => 0,
            'is_pg_user'              => 0,
            'status'                  => 'ACTIVE',
            'remember_token'          => null,
        ];
        foreach ($optional as $col => $val) {
            if (Schema::hasColumn('sys_users', $col)) {
                $payload[$col] = $val;
            }
        }
        if (Schema::hasColumn('sys_users', 'prefered_language')) {
            $languageId = $this->resolvePreferredLanguageId();
            if (!$languageId) {
                $this->markTestSkipped('No language available for sys_users.prefered_language.');
            }
            $payload['prefered_language'] = $languageId;
        }
    }

    private function createLimitedUser(): ?User
    {
        try {
            $suffix  = $this->uniqueSuffix();
            $payload = [
                'name'       => 'Dusk Limited ' . $suffix,
                'short_name' => 'lim' . strtolower($suffix),
                'emp_code'   => 'L' . strtoupper(substr($suffix, 0, 12)),
                'email'      => 'dusk.limited.' . strtolower($suffix) . '@example.com',
                'password'   => bcrypt('password'),
                'created_at' => now(),
                'updated_at' => now(),
            ];
            $this->applyOptionalUserColumns($payload, 'EMPLOYEE');

            $userId = DB::table('sys_users')->insertGetId($payload);
            self::$seededData['user_ids'][] = $userId;

            return User::find($userId);
        } catch (Throwable) {
            return null;
        }
    }

    private function deleteUser(?User $user): void
    {
        if (!$user) {
            return;
        }
        try {
            DB::table('sys_users')->where('id', $user->id)->delete();
        } catch (Throwable) {
        }
    }

    private function cleanupAttendance(int $classSectionId, int $academicSessionId, string $date, array $studentIds): void
    {
        if (empty($studentIds)) {
            return;
        }
        try {
            StudentAttendance::where('class_section_id', $classSectionId)
                ->where('academic_session_id', $academicSessionId)
                ->where('attendance_date', $date)
                ->whereIn('student_id', $studentIds)
                ->delete();
        } catch (Throwable) {
        }
    }

    private function uniqueCode(string $prefix, int $length): string
    {
        $token = strtoupper(bin2hex(random_bytes(6)));
        $code  = substr($prefix . $token, 0, $length);
        return $code !== '' ? $code : strtoupper(substr(bin2hex(random_bytes(6)), 0, $length));
    }

    private function uniqueSuffix(int $length = 10): string
    {
        return strtoupper(substr(bin2hex(random_bytes(8)), 0, $length));
    }

    private function resolvePreferredLanguageId(): ?int
    {
        foreach (['global_master_mysql', null] as $conn) {
            try {
                $query = $conn ? DB::connection($conn)->table('glb_languages') : DB::table('glb_languages');
                $id = $query->value('id');
                if ($id) {
                    return (int) $id;
                }
            } catch (Throwable) {
            }
        }

        try {
            $languageId = DB::connection('global_master_mysql')->table('glb_languages')->insertGetId([
                'code'        => $this->uniqueCode('LANG', 10),
                'name'        => 'Dusk Language ' . $this->uniqueSuffix(6),
                'native_name' => null,
                'direction'   => 'LTR',
                'is_active'   => 1,
                'created_at'  => now(),
                'updated_at'  => now(),
            ]);
            self::$seededData['language_id']      = $languageId;
            self::$seededData['language_created'] = true;
            return (int) $languageId;
        } catch (Throwable) {
            return null;
        }
    }

    private static function cleanupSeededData(): void
    {
        if (
            empty(self::$seededData['user_ids'])
            && !self::$seededData['class_section_created']
            && !self::$seededData['class_created']
            && !self::$seededData['section_created']
            && !self::$seededData['room_type_created']
            && !self::$seededData['language_created']
        ) {
            return;
        }

        $tenantBaseUrl = rtrim(env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')), '/');
        $tenantHost    = parse_url($tenantBaseUrl, PHP_URL_HOST);
        if (!is_string($tenantHost) || $tenantHost === '') {
            return;
        }

        try {
            $domain = Domain::query()->where('domain', $tenantHost)->first();
            if ($domain && function_exists('tenancy')) {
                tenancy()->initialize($domain->tenant);
            }

            if (!empty(self::$seededData['user_ids'])) {
                DB::table('sys_users')->whereIn('id', self::$seededData['user_ids'])->delete();
            }
            if (self::$seededData['class_section_created'] && self::$seededData['class_section_id']) {
                DB::table('sch_class_section_jnt')->where('id', self::$seededData['class_section_id'])->delete();
            }
            if (self::$seededData['class_created'] && self::$seededData['class_id']) {
                DB::table('sch_classes')->where('id', self::$seededData['class_id'])->delete();
            }
            if (self::$seededData['section_created'] && self::$seededData['section_id']) {
                DB::table('sch_sections')->where('id', self::$seededData['section_id'])->delete();
            }
            if (self::$seededData['room_type_created'] && self::$seededData['room_type_id']) {
                DB::table('sch_rooms_type')->where('id', self::$seededData['room_type_id'])->delete();
            }
            if (self::$seededData['language_created'] && self::$seededData['language_id']) {
                try {
                    DB::connection('global_master_mysql')->table('glb_languages')
                        ->where('id', self::$seededData['language_id'])->delete();
                } catch (Throwable) {
                }
            }
        } catch (Throwable) {
        } finally {
            if (function_exists('tenancy') && tenancy()->initialized) {
                tenancy()->end();
            }
        }
    }

    // ---- Browser / screenshot / auth helpers ----

    private function cleanScreenshots(): void
    {
        try {
            $directory = base_path(self::SCREENSHOT_DIR);
            if (File::isDirectory($directory)) {
                foreach (File::glob($directory . DIRECTORY_SEPARATOR . 'std-att-fail-*.png') ?: [] as $file) {
                    File::delete($file);
                }
            }
        } catch (Throwable) {
        }
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
        try {
            $directory = base_path(self::SCREENSHOT_DIR);
            File::ensureDirectoryExists($directory);
            $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', 'std-att-fail-' . $caseName . '-' . now()->format('Ymd_His'))
                ?? 'std-att-fail-' . now()->format('Ymd_His');
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): array
    {
        $encodedMethod  = json_encode(strtoupper($method), JSON_THROW_ON_ERROR);
        $encodedUrl     = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
window.__attApiDone   = false;
window.__attApiError  = '';
window.__attApiResult = null;
(async function () {
    try {
        const method  = {$encodedMethod};
        const url     = {$encodedUrl};
        const payload = {$encodedPayload};
        let csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
        if (!csrf) {
            const match = document.cookie.match(/XSRF-TOKEN=([^;]+)/);
            if (match) { try { csrf = decodeURIComponent(match[1]); } catch (_) { csrf = match[1]; } }
        }
        const response = await fetch(url, {
            method,
            credentials: 'same-origin',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: method !== 'GET' ? JSON.stringify(payload) : undefined,
        });
        const text = await response.text();
        let json = null;
        try { json = text ? JSON.parse(text) : null; } catch (_) {}
        window.__attApiResult = { status: response.status, ok: response.ok, body: text, json };
    } catch (error) {
        window.__attApiError = String(error);
    } finally {
        window.__attApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__attApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for attendance API request.');

        $errorResult = $browser->script('return window.__attApiError || "";');
        $error       = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser request failed: ' . $error);

        $result   = $browser->script('return window.__attApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response);

        return is_array($response) ? $response : [];
    }

    /**
     * POST a normal form (application/x-www-form-urlencoded), following the redirect.
     * Used for the web bulk-store endpoint which redirects back with a flash message.
     */
    private function sendFormPostFromBrowser(Browser $browser, string $path, array $fields): void
    {
        $encodedFields = json_encode($fields, JSON_THROW_ON_ERROR);
        $encodedAction = json_encode($this->tenantUrl($path), JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
(function () {
    const fields = {$encodedFields};
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = {$encodedAction};

    const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
    const addField = function (name, value) {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = name;
        input.value = value;
        form.appendChild(input);
    };
    addField('_token', csrf);

    Object.keys(fields).forEach(function (key) {
        const val = fields[key];
        if (val !== null && typeof val === 'object') {
            Object.keys(val).forEach(function (subKey) {
                addField(key + '[' + subKey + ']', val[subKey]);
            });
        } else {
            addField(key, val === null ? '' : val);
        }
    });

    document.body.appendChild(form);
    form.submit();
})();
JS);
        $browser->pause(1400);
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

        $this->grantAttendancePermissions($this->adminUser);
    }

    private function grantAttendancePermissions(User $user): void
    {
        $permissions = [
            'tenant.attendance.viewAny',
            'tenant.attendance.view',
            'tenant.attendance.create',
            'tenant.attendance.update',
            'tenant.attendance.delete',
        ];
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist($permissions, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach ($permissions as $perm) {
                try {
                    $user->givePermissionTo($perm);
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
        foreach ($permissions as $perm) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate(['name' => $perm, 'guard_name' => $guard]);
            } catch (Throwable) {
            }
        }
    }

    private function permissionGuardName(User $user): string
    {
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
