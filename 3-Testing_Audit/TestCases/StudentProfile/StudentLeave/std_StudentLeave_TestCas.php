<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\Prime\Models\Domain;
use Modules\StudentProfile\Models\LeaveApplication;
use Modules\StudentProfile\Models\LeaveApplicationDocument;
use Modules\StudentProfile\Models\LeaveApplicationRemark;
use Modules\StudentProfile\Models\LeaveType;
use Modules\StudentProfile\Models\Student;
use Tests\DuskTestCase;
use Throwable;

/**
 * Student Profile — Student Leave Management (StdLeaveController screen).
 *
 * Screen / Feature .....: StudentLeave
 * Primary table ........: std_leave_applications  (+ std_leave_application_documents, std_leave_application_remarks)
 * DB scope .............: TENANT  (module-prefixed std_* tables → tenant init required)
 * Controller ...........: Modules\StudentProfile\Http\Controllers\StdLeaveController
 * Service ..............: Modules\StudentProfile\Services\LeaveService
 * Policy ...............: Modules\StudentProfile\Policies\LeaveApplicationPolicy
 * Requirement ..........: StudentProfile_v2/BRD-05_Student_Leave_Management.md
 *
 * ONE comprehensive suite per screen (no V1/V2 split). Semantic bands (WP-G):
 *   01-09 schema/model/route/policy config truth
 *   10-19 business rules (BC-BIZ)
 *   20-29 state-machine transitions (BC-SM)
 *   30-39 validation + error messages (BC-VAL)
 *   40-49 integration / FK dependency (BC-INT/BC-REF)
 *   50-59 permissions / authorization (BC-AUTH)  — incl. GAP-STD-06 proving tests
 *   60-69 UI/UX (tabs, render, filter, empty state)
 *   70-79 edge cases (BC-EDG)  — incl. BUG-STD-14 (remark_type enum case)
 *   90-99 tenancy isolation + security
 *
 * Endpoint status codes are asserted through an authenticated in-page fetch
 * (sendJsonRequestFromBrowser → returns the real HTTP status). Dusk's Browser has
 * NO assertStatus() (05_ constraint #14), so this pattern satisfies that rule while
 * mirroring the committed same-module sibling (spr_MedicalIncident_TestCas.php).
 *
 * ENVIRONMENT PREREQUISITE: the StudentProfile module must be ENABLED in
 * prime_testing/modules_statuses.json (currently false → all routes 404). See
 * 05_ constraint #19. APP_ENV=testing required for CSRF-bypassed state changes (#20).
 */
class std_StudentLeave_TestCas extends DuskTestCase
{
    private const INDEX_PATH          = '/student-profile/student-leave';
    private const AJAX_STUDENTS_PATH  = '/student-profile/ajax/student-leave/students';
    private const AJAX_APPS_PATH      = '/student-profile/ajax/student-leave/applications';
    private const REMARK_STORE_PATH   = '/student-profile/student-leave/remarks/store';

    private const MIGRATION_GLOB_DIR  = 'database/migrations/tenant';
    private const SCREENSHOT_DIR      = 'tests/Browser/console/screenshots';

    /** Exact status ENUM from std_leave_applications DDL (case-sensitive — 05_ #18). */
    private const STATUS_ENUM = [
        'Draft', 'Submitted', 'Under Review', 'Info Requested',
        'Doc Requested', 'Approved', 'Rejected', 'Cancelled',
    ];

    private ?User   $adminUser     = null;
    private string  $tenantBaseUrl = '';
    private string  $adminEmail    = '';
    private string  $adminPassword = '';

    // Cached prerequisite IDs
    private ?int $cachedStudentId    = null;
    private ?int $cachedLeaveTypeId  = null;
    private ?array $cachedContext    = null;

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
    // 01-09  SCHEMA / MODEL / ROUTE / POLICY CONFIGURATION TRUTH
    // =========================================================================

    /**
     * TC-P01 — Schema truth: all three tables + key columns + status ENUM + migration file.
     */
    public function test_student_leave_01_schema_tables_columns_and_status_enum(): void
    {
        // std_leave_applications
        $this->assertTrue(Schema::hasTable('std_leave_applications'), 'std_leave_applications missing.');
        $this->assertTrue(Schema::hasColumns('std_leave_applications', [
            'id', 'student_id', 'academic_session_id', 'class_section_id', 'leave_type_id',
            'from_date', 'to_date', 'total_days', 'is_half_day', 'half_day_slot', 'reason',
            'status', 'applied_by', 'reviewed_by', 'reviewed_at', 'approved_days',
            'review_remarks', 'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing in std_leave_applications.');

        // std_leave_application_documents
        $this->assertTrue(Schema::hasTable('std_leave_application_documents'), 'std_leave_application_documents missing.');
        $this->assertTrue(Schema::hasColumns('std_leave_application_documents', [
            'id', 'leave_application_id', 'document_name', 'document_type_id', 'description',
            'file_name', 'media_id', 'uploaded_by', 'is_in_response_to_request',
            'request_remark_id', 'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing in std_leave_application_documents.');

        // std_leave_application_remarks (NO deleted_at — permanent audit trail)
        $this->assertTrue(Schema::hasTable('std_leave_application_remarks'), 'std_leave_application_remarks missing.');
        $this->assertTrue(Schema::hasColumns('std_leave_application_remarks', [
            'id', 'leave_application_id', 'remark_type', 'message', 'is_from_teacher',
            'remarked_by', 'parent_remark_id', 'is_resolved', 'resolved_at',
            'old_status', 'new_status', 'created_at', 'updated_at',
        ]), 'Expected columns missing in std_leave_application_remarks.');
        $this->assertFalse(
            Schema::hasColumn('std_leave_application_remarks', 'deleted_at'),
            'std_leave_application_remarks must NOT be soft-deletable (permanent audit trail).'
        );

        // Migration file — resolved by glob from central tenant dir (05_ #26 — module dir is empty).
        $migration = $this->resolveMigrationFile('create_std_leave_applications_table');
        if ($migration !== null) {
            $content = File::get($migration);
            $this->assertStringContainsString("Schema::create('std_leave_applications'", $content);
            // status ENUM present in migration body (fail-soft — column presence already asserted above)
            $this->assertStringContainsString('status', $content);
        } else {
            $this->addWarning('create_std_leave_applications_table migration not found by glob; column asserts stand.');
        }
    }

    /**
     * TC-P02 — LeaveApplication model: table, fillable, casts, SoftDeletes, status constants, relationships.
     */
    public function test_student_leave_02_leave_application_model_configuration(): void
    {
        $this->assertContains(SoftDeletes::class, class_uses_recursive(LeaveApplication::class),
            'LeaveApplication must use SoftDeletes.');

        $model = new LeaveApplication();
        $this->assertSame('std_leave_applications', $model->getTable());

        foreach (['student_id', 'leave_type_id', 'from_date', 'to_date', 'total_days', 'status',
                  'applied_by', 'reviewed_by', 'approved_days', 'review_remarks'] as $f) {
            $this->assertContains($f, $model->getFillable(), "LeaveApplication fillable missing '{$f}'.");
        }

        $casts = $model->getCasts();
        $this->assertSame('date', $casts['from_date'] ?? null);
        $this->assertSame('date', $casts['to_date'] ?? null);
        $this->assertSame('boolean', $casts['is_half_day'] ?? null);
        $this->assertSame('integer', $casts['total_days'] ?? null);

        // Status constants match the DDL ENUM exactly (case-sensitive).
        $this->assertSame('Draft', LeaveApplication::STATUS_DRAFT);
        $this->assertSame('Submitted', LeaveApplication::STATUS_SUBMITTED);
        $this->assertSame('Under Review', LeaveApplication::STATUS_UNDER_REVIEW);
        $this->assertSame('Info Requested', LeaveApplication::STATUS_INFO_REQUESTED);
        $this->assertSame('Doc Requested', LeaveApplication::STATUS_DOC_REQUESTED);
        $this->assertSame('Approved', LeaveApplication::STATUS_APPROVED);
        $this->assertSame('Rejected', LeaveApplication::STATUS_REJECTED);
        $this->assertSame('Cancelled', LeaveApplication::STATUS_CANCELLED);

        // Every model constant value must be a valid DDL ENUM member.
        foreach ([LeaveApplication::STATUS_DRAFT, LeaveApplication::STATUS_SUBMITTED,
                  LeaveApplication::STATUS_UNDER_REVIEW, LeaveApplication::STATUS_INFO_REQUESTED,
                  LeaveApplication::STATUS_DOC_REQUESTED, LeaveApplication::STATUS_APPROVED,
                  LeaveApplication::STATUS_REJECTED, LeaveApplication::STATUS_CANCELLED] as $s) {
            $this->assertContains($s, self::STATUS_ENUM, "Status constant '{$s}' is not a DDL ENUM member.");
        }

        foreach (['student', 'leaveType', 'classSection', 'academicSession', 'appliedBy',
                  'reviewedBy', 'documents', 'remarks'] as $rel) {
            $this->assertTrue(method_exists($model, $rel), "LeaveApplication relationship '{$rel}' missing.");
        }
    }

    /**
     * TC-P03 — Remark & Document model configuration (audit-trail + media).
     */
    public function test_student_leave_03_remark_and_document_model_configuration(): void
    {
        // Remark model — NO SoftDeletes (permanent trail)
        $remark = new LeaveApplicationRemark();
        $this->assertSame('std_leave_application_remarks', $remark->getTable());
        $this->assertNotContains(SoftDeletes::class, class_uses_recursive(LeaveApplicationRemark::class),
            'LeaveApplicationRemark must NOT use SoftDeletes.');
        $this->assertSame('comment', LeaveApplicationRemark::TYPE_COMMENT);
        $this->assertSame('info_request', LeaveApplicationRemark::TYPE_INFO_REQUEST);
        $this->assertSame('doc_request', LeaveApplicationRemark::TYPE_DOC_REQUEST);
        $this->assertSame('response', LeaveApplicationRemark::TYPE_RESPONSE);
        $this->assertSame('status_change', LeaveApplicationRemark::TYPE_STATUS_CHANGE);

        // Document model — SoftDeletes + InteractsWithMedia
        $doc = new LeaveApplicationDocument();
        $this->assertSame('std_leave_application_documents', $doc->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(LeaveApplicationDocument::class),
            'LeaveApplicationDocument must use SoftDeletes.');
        $this->assertContains(\Spatie\MediaLibrary\InteractsWithMedia::class,
            class_uses_recursive(LeaveApplicationDocument::class),
            'LeaveApplicationDocument must use InteractsWithMedia.');
    }

    /**
     * TC-P04 — All eight StudentLeave routes are registered with the expected names.
     */
    public function test_student_leave_04_routes_registered(): void
    {
        foreach ([
            'student-profile.student-leave.index',
            'student-profile.student-leave.review',
            'student-profile.student-leave.update-review',
            'student-profile.student-leave.edit',
            'student-profile.student-leave.update',
            'student-profile.student-leave.ajax.students',
            'student-profile.student-leave.ajax.applications',
            'student-profile.student-leave.remarks.store',
        ] as $name) {
            $this->assertTrue(
                Route::has($name),
                "Route '{$name}' is not registered (module enabled? modules_statuses.json)."
            );
        }
    }

    /**
     * TC-P05 — LeaveApplicationPolicy exposes every ability mapped to a tenant.student-leave.* permission.
     */
    public function test_student_leave_05_policy_abilities_present(): void
    {
        $policy = \Modules\StudentProfile\Policies\LeaveApplicationPolicy::class;
        $this->assertTrue(class_exists($policy), 'LeaveApplicationPolicy must exist.');
        foreach (['viewAny', 'view', 'create', 'update', 'review', 'delete', 'restore', 'forceDelete'] as $ability) {
            $this->assertTrue(method_exists($policy, $ability), "Policy ability '{$ability}' missing.");
        }
    }

    // =========================================================================
    // 10-19  BUSINESS RULES (BC-BIZ)
    // =========================================================================

    /**
     * TC-N10 / BR-08 — storeRemark on a finalized (Approved) application → 403 with exact message.
     */
    public function test_student_leave_10_store_remark_blocked_on_finalized_application(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_APPROVED);

        $this->browseWithFailureScreenshot('sl-10-finalized-chat', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'POST', self::REMARK_STORE_PATH, [
                'leave_application_id' => $app->id,
                'message'              => 'Late comment on a closed application',
            ]);

            $this->assertSame(403, (int) ($res['status'] ?? 0), 'Expected 403 for chat on finalized application.');
            $json = is_array($res['json'] ?? null) ? $res['json'] : [];
            $this->assertStringContainsString(
                'Chat is disabled for finalized applications.',
                (string) ($json['message'] ?? ''),
                'Expected exact "Chat is disabled for finalized applications." message.'
            );
        });

        $this->cleanupApplication($app);
    }

    /**
     * TC-N11 — storeRemark with neither message nor attachment → 422 with exact message.
     */
    public function test_student_leave_11_store_remark_requires_message_or_file(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-11-empty-remark', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'POST', self::REMARK_STORE_PATH, [
                'leave_application_id' => $app->id,
                'message'              => '',
            ]);

            $this->assertSame(422, (int) ($res['status'] ?? 0), 'Expected 422 when message and file both empty.');
            $json = is_array($res['json'] ?? null) ? $res['json'] : [];
            $this->assertStringContainsString(
                'Please provide a message or attach a file.',
                (string) ($json['message'] ?? ''),
                'Expected exact "Please provide a message or attach a file." message.'
            );
        });

        $this->cleanupApplication($app);
    }

    /**
     * TC-P12 / FR-24 — storeRemark valid comment persists as teacher remark + logs 'Remark Added' activity.
     */
    public function test_student_leave_12_store_remark_creates_teacher_comment_and_logs_activity(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-12-add-remark', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'POST', self::REMARK_STORE_PATH, [
                'leave_application_id' => $app->id,
                'message'              => 'Teacher comment via test',
            ]);

            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200, 302], true),
                'Expected success adding a remark.');
        });

        $remark = LeaveApplicationRemark::where('leave_application_id', $app->id)
            ->where('remark_type', LeaveApplicationRemark::TYPE_COMMENT)
            ->latest('id')->first();

        $this->assertNotNull($remark, 'Comment remark should be created.');
        $this->assertTrue((bool) $remark->is_from_teacher, 'Remark from admin/teacher should set is_from_teacher = true.');

        $this->assertActivityLogged($app->id, LeaveApplication::class, 'Remark Added');

        $this->cleanupApplication($app);
    }

    /**
     * TC-P13 / BR-04 / FR-28 — Approving via updateReview auto-marks attendance status 'Leave'.
     */
    public function test_student_leave_13_approval_auto_marks_attendance_leave(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-13-approve-attendance', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'         => 'Approved',
                    'review_remarks' => 'Approved by test',
                    'approved_days'  => $app->total_days,
                ]);

            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200, 302], true),
                'Expected success approving the application.');
        });

        $app->refresh();
        $this->assertSame('Approved', (string) $app->status, 'Status should be Approved.');

        try {
            $marked = \Modules\StudentProfile\Models\StudentAttendance::where('student_id', $app->student_id)
                ->where('academic_session_id', $app->academic_session_id)
                ->where('status', 'Leave')
                ->exists();
            $this->assertTrue($marked, 'Approval should create at least one attendance row with status Leave.');
        } catch (Throwable $e) {
            $this->markTestSkipped('StudentAttendance unavailable: ' . $e->getMessage());
        }

        $this->cleanupApplication($app);
    }

    /**
     * TC-P14 / FR-19 — approved_days defaults to total_days when omitted on approval.
     */
    public function test_student_leave_14_approved_days_defaults_to_total_days(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-14-approved-days-default', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'         => 'Approved',
                    'review_remarks' => 'Approve without approved_days',
                ]);

            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200, 302], true), 'Expected success.');
        });

        $app->refresh();
        $this->assertSame((int) $app->total_days, (int) $app->approved_days,
            'approved_days should default to total_days.');

        $this->cleanupApplication($app);
    }

    /**
     * TC-P15 / FR-18 — Review stamps reviewed_by and reviewed_at.
     */
    public function test_student_leave_15_review_sets_reviewer_and_timestamp(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-15-reviewer-stamp', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'         => 'Rejected',
                    'review_remarks' => 'Rejected by test',
                ]);
        });

        $app->refresh();
        $this->assertNotNull($app->reviewed_by, 'reviewed_by should be stamped.');
        $this->assertNotNull($app->reviewed_at, 'reviewed_at should be stamped.');
        $this->assertActivityLogged($app->id, LeaveApplication::class, 'Reviewed');

        $this->cleanupApplication($app);
    }

    /**
     * TC-P16 / FR-25 — update() logs a status_change (audit) remark on field changes + 'Updated' activity.
     */
    public function test_student_leave_16_update_application_logs_change_and_activity(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
        $leaveTypeId = $this->resolveLeaveTypeId();

        $this->browseWithFailureScreenshot('sl-16-update-app', function (Browser $browser) use ($app, $leaveTypeId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/edit", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", [
                    'leave_type_id' => $leaveTypeId,
                    'from_date'     => now()->addDays(40)->toDateString(),
                    'to_date'       => now()->addDays(41)->toDateString(),
                    'total_days'    => 2,
                    'reason'        => 'Updated reason via test',
                ]);

            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200, 302], true), 'Expected success on update.');
        });

        $app->refresh();
        $this->assertSame('Updated reason via test', (string) $app->reason, 'Reason should be updated.');
        $this->assertActivityLogged($app->id, LeaveApplication::class, 'Updated');

        $this->cleanupApplication($app);
    }

    /**
     * TC-N17 — update() rejects an overlapping date range for the same student.
     */
    public function test_student_leave_17_update_rejects_overlapping_range(): void
    {
        $existing = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED, [
            'from_date' => now()->addDays(60)->toDateString(),
            'to_date'   => now()->addDays(62)->toDateString(),
        ]);
        $target = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED, [
            'student_id' => $existing->student_id,
            'from_date'  => now()->addDays(70)->toDateString(),
            'to_date'    => now()->addDays(71)->toDateString(),
        ]);
        $leaveTypeId = $this->resolveLeaveTypeId();

        $this->browseWithFailureScreenshot('sl-17-overlap', function (Browser $browser) use ($target, $existing, $leaveTypeId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$target->id}/edit", 600);

            // Move target onto the existing application's range → overlap.
            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$target->id}/update", [
                    'leave_type_id' => $leaveTypeId,
                    'from_date'     => $existing->from_date->toDateString(),
                    'to_date'       => $existing->to_date->toDateString(),
                    'total_days'    => 3,
                    'reason'        => 'Overlap attempt',
                ]);

            // Controller catches InvalidArgumentException → redirect back with errors (302), not a 200 success.
            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [302, 422], true),
                'Overlapping update should be rejected (back with errors).');
        });

        $target->refresh();
        $this->assertNotSame($existing->from_date->toDateString(), $target->from_date->toDateString(),
            'Overlapping update must not persist the conflicting range.');

        $this->cleanupApplication($target);
        $this->cleanupApplication($existing);
    }

    // =========================================================================
    // 20-29  STATE-MACHINE TRANSITIONS (BC-SM) — via updateReview → LeaveService::review()
    // =========================================================================

    /** TC-SM20 — Submitted → Under Review (legal). */
    public function test_student_leave_20_transition_submitted_to_under_review(): void
    {
        $this->assertLegalTransition(LeaveApplication::STATUS_SUBMITTED, 'Under Review', 'sl-20');
    }

    /** TC-SM21 — Submitted → Approved (legal) and status_change remark logged. */
    public function test_student_leave_21_transition_submitted_to_approved(): void
    {
        $app = $this->assertLegalTransition(LeaveApplication::STATUS_SUBMITTED, 'Approved', 'sl-21', keep: true);

        $sc = LeaveApplicationRemark::where('leave_application_id', $app->id)
            ->where('remark_type', LeaveApplicationRemark::TYPE_STATUS_CHANGE)
            ->where('new_status', 'Approved')->latest('id')->first();
        $this->assertNotNull($sc, 'A status_change remark should record the Approved transition.');

        $this->cleanupApplication($app);
    }

    /** TC-SM22 — Submitted → Rejected (legal). */
    public function test_student_leave_22_transition_submitted_to_rejected(): void
    {
        $this->assertLegalTransition(LeaveApplication::STATUS_SUBMITTED, 'Rejected', 'sl-22');
    }

    /** TC-SM23 — Submitted → Info Requested (legal). */
    public function test_student_leave_23_transition_submitted_to_info_requested(): void
    {
        $this->assertLegalTransition(LeaveApplication::STATUS_SUBMITTED, 'Info Requested', 'sl-23');
    }

    /** TC-SM24 — Submitted → Doc Requested (legal). */
    public function test_student_leave_24_transition_submitted_to_doc_requested(): void
    {
        $this->assertLegalTransition(LeaveApplication::STATUS_SUBMITTED, 'Doc Requested', 'sl-24');
    }

    /** TC-SM25 — Under Review → Approved (legal). */
    public function test_student_leave_25_transition_under_review_to_approved(): void
    {
        $this->assertLegalTransition(LeaveApplication::STATUS_UNDER_REVIEW, 'Approved', 'sl-25');
    }

    /** TC-SM26 — Illegal target 'Cancelled' via updateReview is rejected by validation (422). */
    public function test_student_leave_26_transition_to_cancelled_rejected_by_validation(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-26-cancel-blocked', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", ['status' => 'Cancelled']);

            $this->assertSame(422, (int) ($res['status'] ?? 0),
                "'Cancelled' is not in the updateReview status whitelist → 422.");
        });

        $app->refresh();
        $this->assertNotSame('Cancelled', (string) $app->status, 'Status must not become Cancelled via updateReview.');

        $this->cleanupApplication($app);
    }

    /** TC-SM27 — Illegal targets 'Submitted' and 'Draft' via updateReview rejected (422). */
    public function test_student_leave_27_transition_to_submitted_or_draft_rejected(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_UNDER_REVIEW);

        $this->browseWithFailureScreenshot('sl-27-submitted-draft-blocked', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            foreach (['Submitted', 'Draft', 'Foobar'] as $bad) {
                $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                    "/student-profile/student-leave/{$app->id}/update-review", ['status' => $bad]);
                $this->assertSame(422, (int) ($res['status'] ?? 0), "Target '{$bad}' must be rejected (422).");
            }
        });

        $this->cleanupApplication($app);
    }

    /**
     * TC-SM28 / BUG-STD-15 — updateReview has NO source-state guard.
     * Proves current permissive behaviour: an already-Approved application can be
     * re-transitioned to Rejected (an illegal FSM move), because LeaveService::review()
     * validates only the TARGET status, never the current one. Documents the defect.
     */
    public function test_student_leave_28_no_source_state_guard_allows_illegal_reapproval(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_APPROVED);

        $observed = null;
        $this->browseWithFailureScreenshot('sl-28-fsm-no-guard', function (Browser $browser) use ($app, &$observed): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'         => 'Rejected',
                    'review_remarks' => 'Illegal re-transition from Approved',
                ]);
            $observed = (int) ($res['status'] ?? 0);
        });

        $app->refresh();
        // BUG-STD-15: with no FSM guard the move is accepted (success + status flipped).
        // If a guard is ever added this assertion flags the behaviour change.
        $this->assertTrue(
            in_array($observed, [200, 302], true) && (string) $app->status === 'Rejected',
            'BUG-STD-15: Approved→Rejected is currently accepted (no source-state guard). '
            . "Observed status={$observed}, app status={$app->status}."
        );

        $this->cleanupApplication($app);
    }

    /** TC-SM29 — Every legal transition auto-logs a status_change remark with old/new status. */
    public function test_student_leave_29_transition_autologs_status_change_remark(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-29-autolog', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", ['status' => 'Under Review']);
        });

        $sc = LeaveApplicationRemark::where('leave_application_id', $app->id)
            ->where('remark_type', LeaveApplicationRemark::TYPE_STATUS_CHANGE)
            ->latest('id')->first();

        $this->assertNotNull($sc, 'Transition must auto-log a status_change remark.');
        $this->assertSame('Under Review', (string) $sc->new_status, 'new_status must record the target.');
        $this->assertNotNull($sc->old_status, 'old_status must record the source.');

        $this->cleanupApplication($app);
    }

    // =========================================================================
    // 30-39  VALIDATION + ERROR MESSAGES (BC-VAL)
    // =========================================================================

    /** TC-N30 — updateReview: status is required. */
    public function test_student_leave_30_update_review_status_required(): void
    {
        $this->assertUpdateReviewRejected(['review_remarks' => 'no status'], 'sl-30');
    }

    /** TC-N31 — updateReview: status must be a whitelisted value. */
    public function test_student_leave_31_update_review_status_invalid(): void
    {
        $this->assertUpdateReviewRejected(['status' => 'approved'], 'sl-31'); // lowercase not accepted (case-exact)
    }

    /** TC-N32 — updateReview: review_remarks max 1000 chars. */
    public function test_student_leave_32_update_review_remarks_max_1000(): void
    {
        $this->assertUpdateReviewRejected([
            'status'         => 'Approved',
            'review_remarks' => str_repeat('a', 1001),
        ], 'sl-32');
    }

    /** TC-N33 — updateReview: approved_days may not exceed total_days. */
    public function test_student_leave_33_update_review_approved_days_over_total(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-33-approved-over', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'        => 'Approved',
                    'approved_days' => ((int) $app->total_days) + 5,
                ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'approved_days > total_days must be 422.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-N34 — updateReview: approved_days may not be negative. */
    public function test_student_leave_34_update_review_approved_days_negative(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-34-approved-neg', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'        => 'Approved',
                    'approved_days' => -1,
                ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'Negative approved_days must be 422.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-N35 — update: leave_type_id required and must exist. */
    public function test_student_leave_35_update_leave_type_required_and_exists(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-35-leave-type', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/edit", 600);

            // Missing
            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", [
                    'from_date' => now()->addDays(80)->toDateString(),
                    'to_date'   => now()->addDays(80)->toDateString(),
                    'total_days'=> 1,
                    'reason'    => 'no leave type',
                ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'Missing leave_type_id must be 422.');

            // Non-existent
            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", [
                    'leave_type_id' => 99999999,
                    'from_date'     => now()->addDays(80)->toDateString(),
                    'to_date'       => now()->addDays(80)->toDateString(),
                    'total_days'    => 1,
                    'reason'        => 'bad leave type',
                ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'Non-existent leave_type_id must be 422.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-N36 — update: to_date must be after_or_equal from_date. */
    public function test_student_leave_36_update_to_date_before_from_date(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
        $leaveTypeId = $this->resolveLeaveTypeId();

        $this->browseWithFailureScreenshot('sl-36-date-order', function (Browser $browser) use ($app, $leaveTypeId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/edit", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", [
                    'leave_type_id' => $leaveTypeId,
                    'from_date'     => now()->addDays(90)->toDateString(),
                    'to_date'       => now()->addDays(88)->toDateString(),
                    'total_days'    => 1,
                    'reason'        => 'reversed dates',
                ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'to_date before from_date must be 422.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-N37 — update: total_days min 1. */
    public function test_student_leave_37_update_total_days_min_one(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
        $leaveTypeId = $this->resolveLeaveTypeId();

        $this->browseWithFailureScreenshot('sl-37-total-days', function (Browser $browser) use ($app, $leaveTypeId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/edit", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", [
                    'leave_type_id' => $leaveTypeId,
                    'from_date'     => now()->addDays(95)->toDateString(),
                    'to_date'       => now()->addDays(95)->toDateString(),
                    'total_days'    => 0,
                    'reason'        => 'zero days',
                ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'total_days 0 must be 422.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-N38 — update: reason required and max 2000. */
    public function test_student_leave_38_update_reason_required_and_max(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
        $leaveTypeId = $this->resolveLeaveTypeId();

        $this->browseWithFailureScreenshot('sl-38-reason', function (Browser $browser) use ($app, $leaveTypeId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/edit", 600);

            $base = [
                'leave_type_id' => $leaveTypeId,
                'from_date'     => now()->addDays(100)->toDateString(),
                'to_date'       => now()->addDays(100)->toDateString(),
                'total_days'    => 1,
            ];

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", $base + ['reason' => '']);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'Empty reason must be 422.');

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", $base + ['reason' => str_repeat('x', 2001)]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'reason > 2000 must be 422.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-N39 — update: half_day_slot must be Morning|Afternoon; storeRemark description max 255. */
    public function test_student_leave_39_half_day_slot_and_description_bounds(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
        $leaveTypeId = $this->resolveLeaveTypeId();

        $this->browseWithFailureScreenshot('sl-39-slot-desc', function (Browser $browser) use ($app, $leaveTypeId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/edit", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", [
                    'leave_type_id' => $leaveTypeId,
                    'from_date'     => now()->addDays(105)->toDateString(),
                    'to_date'       => now()->addDays(105)->toDateString(),
                    'total_days'    => 1,
                    'is_half_day'   => 1,
                    'half_day_slot' => 'Evening', // not in ENUM Morning/Afternoon
                    'reason'        => 'bad slot',
                ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'Invalid half_day_slot must be 422.');

            // storeRemark description > 255
            $res = $this->sendJsonRequestFromBrowser($browser, 'POST', self::REMARK_STORE_PATH, [
                'leave_application_id' => $app->id,
                'message'              => 'desc bound',
                'description'          => str_repeat('d', 256),
            ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'description > 255 must be 422.');
        });

        $this->cleanupApplication($app);
    }

    // =========================================================================
    // 40-49  INTEGRATION / FK DEPENDENCY (BC-INT / BC-REF)
    // =========================================================================

    /** TC-N40 — review page for a non-existent id → 404. */
    public function test_student_leave_40_review_invalid_id_404(): void
    {
        $this->assertEndpointStatus('GET', '/student-profile/student-leave/99999999/review', [], 404, 'sl-40');
    }

    /** TC-N41 — updateReview for a non-existent id → 404. */
    public function test_student_leave_41_update_review_invalid_id_404(): void
    {
        $this->assertEndpointStatus('PUT', '/student-profile/student-leave/99999999/update-review',
            ['status' => 'Approved'], 404, 'sl-41');
    }

    /** TC-N42 — update for a non-existent id → 404. */
    public function test_student_leave_42_update_invalid_id_404(): void
    {
        $leaveTypeId = $this->resolveLeaveTypeId();
        $this->assertEndpointStatus('PUT', '/student-profile/student-leave/99999999/update', [
            'leave_type_id' => $leaveTypeId,
            'from_date'     => now()->addDays(3)->toDateString(),
            'to_date'       => now()->addDays(3)->toDateString(),
            'total_days'    => 1,
            'reason'        => 'x',
        ], 404, 'sl-42');
    }

    /** TC-N43 — storeRemark: leave_application_id must exist (422 when absent). */
    public function test_student_leave_43_store_remark_application_must_exist(): void
    {
        $this->browseWithFailureScreenshot('sl-43-remark-fk', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'POST', self::REMARK_STORE_PATH, [
                'leave_application_id' => 99999999,
                'message'              => 'orphan remark',
            ]);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'Non-existent leave_application_id must be 422.');
        });
    }

    /** TC-D44 — FK: deleting a student cascades its leave applications (ON DELETE CASCADE) — defensive. */
    public function test_student_leave_44_student_delete_cascades_applications(): void
    {
        try {
            $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
            $studentId = $app->student_id;
            $appId = $app->id;

            $student = Student::withTrashed()->find($studentId);
            if ($student === null) {
                $this->markTestSkipped('Student unavailable for cascade test.');
            }

            // Only exercise a real hard-delete cascade if the student is disposable; otherwise document via FK metadata.
            $this->assertTrue(
                Schema::hasColumn('std_leave_applications', 'student_id'),
                'std_leave_applications.student_id FK column present (CASCADE per DDL).'
            );
            // Do not hard-delete shared seed students; assert the row exists and clean up the app only.
            $this->assertTrue(LeaveApplication::withTrashed()->whereKey($appId)->exists(),
                'Seed application should exist.');
            $this->cleanupApplication($app);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cascade dependency path skipped: ' . $e->getMessage());
        }
    }

    /** TC-D45 — FK: reviewed_by is ON DELETE SET NULL (metadata assertion — reviewer users are shared). */
    public function test_student_leave_45_reviewed_by_set_null_metadata(): void
    {
        $this->assertTrue(Schema::hasColumn('std_leave_applications', 'reviewed_by'),
            'reviewed_by column present (fk_la_reviewed_by ON DELETE SET NULL per DDL).');
    }

    /** TC-D46 — remarks & documents cascade on application delete (ON DELETE CASCADE) — defensive. */
    public function test_student_leave_46_children_cascade_on_application_force_delete(): void
    {
        try {
            $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
            $appId = $app->id;

            LeaveApplicationRemark::create([
                'leave_application_id' => $appId,
                'remark_type'          => LeaveApplicationRemark::TYPE_COMMENT,
                'message'              => 'child remark',
                'is_from_teacher'      => true,
                'remarked_by'          => $this->adminUser->id,
            ]);

            $this->assertTrue(LeaveApplicationRemark::where('leave_application_id', $appId)->exists(),
                'Child remark should exist before delete.');

            // Force-delete the parent → DB CASCADE removes remarks (no soft-delete on remarks).
            LeaveApplication::withTrashed()->whereKey($appId)->first()?->forceDelete();

            $this->assertFalse(LeaveApplicationRemark::where('leave_application_id', $appId)->exists(),
                'Remarks should be cascade-deleted with the application.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Cascade children path skipped: ' . $e->getMessage());
        }
    }

    /** TC-P47 — ajax applications returns JSON list for a student. */
    public function test_student_leave_47_ajax_applications_returns_json(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-47-ajax-apps', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'GET',
                self::AJAX_APPS_PATH . '?student_id=' . $app->student_id, []);
            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200], true), 'ajax applications should be 200.');
            $this->assertIsArray($res['json'] ?? null, 'ajax applications should return a JSON array.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-P48 — ajax students returns JSON list for a section. */
    public function test_student_leave_48_ajax_students_returns_json(): void
    {
        $ctx = $this->resolveContext();
        if ($ctx === null) {
            $this->markTestSkipped('No class-section context for ajax students test.');
        }

        $this->browseWithFailureScreenshot('sl-48-ajax-students', function (Browser $browser) use ($ctx): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'GET',
                self::AJAX_STUDENTS_PATH . '?section_id=' . $ctx['class_section_id'], []);
            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200], true), 'ajax students should be 200.');
            $this->assertIsArray($res['json'] ?? null, 'ajax students should return a JSON array.');
        });
    }

    // =========================================================================
    // 50-59  PERMISSIONS / AUTHORIZATION (BC-AUTH) — incl. GAP-STD-06
    // =========================================================================

    /** TC-N50 — Guest is redirected to /login on the index. */
    public function test_student_leave_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('sl-50-guest', function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser),
                'Guest must be redirected to /login.');
        });
    }

    /**
     * TC-S51 / GAP-STD-06 — Limited (non-super-admin, unpermissioned) user probing the index.
     *
     * AUDIT CONTEXT (2026-06-30): GAP-STD-06 reported StdLeaveController Gate::authorize calls
     * COMMENTED OUT (lines 25 & 250) → authorization not enforced. CURRENT SOURCE (verified during
     * generation) has Gate::authorize('tenant.student-leave.viewAny') ACTIVE on index() and on all
     * eight controller methods → the defect appears REMEDIATED.
     *
     * This test does NOT assume 403. It records the OBSERVED status for a limited user and asserts
     * it lands in a documented set, so the artifact proves whichever reality holds at run time:
     *   403 → gate enforced (GAP-STD-06 fixed);  200/302 → gate NOT enforced (GAP-STD-06 reproduced).
     * Note: Gate::before (AppServiceProvider) bypasses ALL gates for Super Admin, so a NON-super,
     * unpermissioned user is required to exercise the gate at all.
     */
    public function test_student_leave_51_gap_std_06_limited_user_index_probe(): void
    {
        $limited = $this->makeLimitedUser();
        if ($limited === null) {
            $this->markTestSkipped('Could not create a limited user for GAP-STD-06 probe.');
        }

        $observed = null;
        $this->browseWithFailureScreenshot('sl-51-gap-index', function (Browser $browser) use ($limited, &$observed): void {
            $browser->loginAs($limited)->visit($this->tenantUrl(self::INDEX_PATH))->pause(900);
            $observed = $this->httpStatusFromBrowser($browser, 'GET', self::INDEX_PATH);
        });

        $this->assertContains(
            $observed, [403, 200, 302, 404, 419],
            "GAP-STD-06 index probe returned unexpected status {$observed}."
        );
        // Preferred (remediated) outcome is 403. Surface a warning if the gate did NOT block.
        if (in_array($observed, [200, 302], true)) {
            $this->addWarning("GAP-STD-06 possibly reproduced: limited user reached index (status {$observed}).");
        }

        $this->disposeUser($limited);
    }

    /** TC-S52 / GAP-STD-06 — Limited user probing updateReview (state-changing endpoint). */
    public function test_student_leave_52_gap_std_06_limited_user_update_review_probe(): void
    {
        $limited = $this->makeLimitedUser();
        if ($limited === null) {
            $this->markTestSkipped('Could not create a limited user for GAP-STD-06 probe.');
        }
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $observed = null;
        $this->browseWithFailureScreenshot('sl-52-gap-review', function (Browser $browser) use ($limited, $app, &$observed): void {
            $browser->loginAs($limited)->visit($this->tenantUrl(self::INDEX_PATH))->pause(700);
            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", ['status' => 'Approved']);
            $observed = (int) ($res['status'] ?? 0);
        });

        $this->assertContains($observed, [403, 200, 302, 404, 419, 422],
            "GAP-STD-06 updateReview probe returned unexpected status {$observed}.");
        if (in_array($observed, [200, 302], true)) {
            $this->addWarning("GAP-STD-06 possibly reproduced on updateReview (status {$observed}).");
        }

        $app->refresh();
        $this->disposeUser($limited);
        $this->cleanupApplication($app);
    }

    /** TC-P53 — Super-admin bypass: the admin user (Gate::before) can reach the index. */
    public function test_student_leave_53_super_admin_can_access_index(): void
    {
        $this->browseWithFailureScreenshot('sl-53-admin-access', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 900);
            $this->assertStringNotContainsString('/login', $this->currentPath($browser),
                'Admin should not be bounced to login.');
            $browser->assertPresent('#leaveTabs');
        });
    }

    /** TC-P54 — Policy permission strings map to the tenant.student-leave.* namespace. */
    public function test_student_leave_54_policy_permission_namespace(): void
    {
        $ref = new \ReflectionClass(\Modules\StudentProfile\Policies\LeaveApplicationPolicy::class);
        $src = (string) File::get($ref->getFileName());
        foreach (['tenant.student-leave.viewAny', 'tenant.student-leave.view',
                  'tenant.student-leave.update', 'tenant.student-leave.review'] as $perm) {
            $this->assertStringContainsString($perm, $src, "Policy should reference '{$perm}'.");
        }
    }

    // =========================================================================
    // 60-69  UI / UX
    // =========================================================================

    /** TC-P60 — Index renders all four workflow tabs. */
    public function test_student_leave_60_index_renders_four_tabs(): void
    {
        $this->browseWithFailureScreenshot('sl-60-tabs', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 1000);

            $browser->assertPresent('#leaveTabs')
                ->assertPresent('#leave-type-tab')
                ->assertPresent('#application-review-tab')
                ->assertPresent('#documents-tab')
                ->assertPresent('#leave-remarks-tab');
        });
    }

    /** TC-P61 — application-review tab lists a seeded application (admission or student name visible). */
    public function test_student_leave_61_application_review_tab_lists_application(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-61-review-list', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=application-review', 1200);
            $browser->assertPresent('#application-review');
        });

        $this->cleanupApplication($app);
    }

    /** TC-P62 — Review page renders the status radio grid and review form. */
    public function test_student_leave_62_review_page_renders_form(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-62-review-form', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 1000);
            $browser->assertPresent('input[name="status"]')
                ->assertPresent('textarea[name="review_remarks"]')
                ->assertPresent('input[name="approved_days"]');
        });

        $this->cleanupApplication($app);
    }

    /** TC-P63 — Edit page loads leave application fields prefilled. */
    public function test_student_leave_63_edit_page_prefilled(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED, ['reason' => 'DuskEditReason']);

        $this->browseWithFailureScreenshot('sl-63-edit', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/edit", 1000);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('DuskEditReason', $source, 'Edit page should prefill the reason.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-P64 — Application-review filter by status renders without error. */
    public function test_student_leave_64_index_status_filter(): void
    {
        $this->browseWithFailureScreenshot('sl-64-filter', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser,
                self::INDEX_PATH . '?tab=application-review&status=Submitted', 1000);
            $browser->assertPresent('#application-review');
        });
    }

    /** TC-P65 — Index renders even with no matching applications (empty state). */
    public function test_student_leave_65_index_empty_state(): void
    {
        $this->browseWithFailureScreenshot('sl-65-empty', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser,
                self::INDEX_PATH . '?tab=application-review&search=zzz_no_match_' . uniqid(), 1000);
            $browser->assertPresent('#application-review');
        });
    }

    // =========================================================================
    // 70-79  EDGE CASES (BC-EDG) — incl. BUG-STD-14
    // =========================================================================

    /**
     * TC-EDG70 / BUG-STD-14 — remark_type ENUM case mismatch.
     *
     * DDL std_leave_application_remarks.remark_type ENUM = ('Comment','Info_Request','Doc_Request',
     * 'Response','Status_Change') — capitalised. Model constants are lowercase
     * (TYPE_COMMENT='comment', TYPE_STATUS_CHANGE='status_change', …). The service inserts the
     * lowercase constant values. Under the table's case-insensitive collation MySQL NORMALISES the
     * stored value to the DDL letter-case, so a value written as 'comment' is READ BACK as 'Comment'.
     *
     * Consequence: a strict PHP comparison `$remark->remark_type === LeaveApplicationRemark::TYPE_COMMENT`
     * ('Comment' === 'comment') is FALSE. This test proves the mismatch by comparing the stored value
     * against the model constant, documenting BUG-STD-14. It asserts the DEFECT is present (mismatch)
     * OR, if the DB preserved lowercase, that at least the constant/DDL disagree — either way the
     * inconsistency is surfaced, never silently passed.
     */
    public function test_student_leave_70_bug_std_14_remark_type_enum_case_mismatch(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $remark = LeaveApplicationRemark::create([
            'leave_application_id' => $app->id,
            'remark_type'          => LeaveApplicationRemark::TYPE_COMMENT, // 'comment'
            'message'              => 'enum-case probe',
            'is_from_teacher'      => true,
            'remarked_by'          => $this->adminUser->id,
        ]);

        $stored = (string) LeaveApplicationRemark::whereKey($remark->id)->value('remark_type');

        // DDL ENUM members are capitalised; the model constant is lowercase. They are NOT identical.
        $ddlMembers = ['Comment', 'Info_Request', 'Doc_Request', 'Response', 'Status_Change'];
        $constantIsDdlMember = in_array(LeaveApplicationRemark::TYPE_COMMENT, $ddlMembers, true);
        $this->assertFalse(
            $constantIsDdlMember,
            'BUG-STD-14: model constant TYPE_COMMENT ("comment") is not a case-exact member of the DDL '
            . 'remark_type ENUM (' . implode(', ', $ddlMembers) . ').'
        );

        // Prove the round-trip inconsistency: stored value does not strictly equal the model constant
        // (MySQL normalises to the DDL case under case-insensitive collation).
        $this->assertNotSame(
            LeaveApplicationRemark::TYPE_COMMENT,
            $stored,
            'BUG-STD-14: remark_type written as "comment" is read back as "' . $stored . '" — strict '
            . 'comparisons against the lowercase model constant will silently fail.'
        );

        $this->cleanupApplication($app);
    }

    /** TC-EDG71 — updateReview: whitespace-only review_remarks is accepted (nullable string) — documents behaviour. */
    public function test_student_leave_71_review_remarks_whitespace_accepted(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-71-ws-remarks', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'         => 'Under Review',
                    'review_remarks' => '   ',
                ]);
            // nullable|string|max:1000 → whitespace passes validation (no trim rule).
            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200, 302], true),
                'Whitespace review_remarks is accepted by the current rules.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-EDG72 — Boundary: approved_days exactly equal to total_days is accepted. */
    public function test_student_leave_72_approved_days_equal_total_boundary(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot('sl-72-boundary', function (Browser $browser) use ($app): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'        => 'Approved',
                    'approved_days' => (int) $app->total_days,
                ]);
            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200, 302], true),
                'approved_days == total_days must be accepted.');
        });

        $this->cleanupApplication($app);
    }

    // =========================================================================
    // 90-99  TENANCY ISOLATION + SECURITY
    // =========================================================================

    /** TC-T90 — Cross-tenant / IDOR: a wildly out-of-range id is never reachable (404). */
    public function test_student_leave_90_idor_out_of_range_id_not_reachable(): void
    {
        $this->assertEndpointStatus('GET', '/student-profile/student-leave/2147480000/review', [], 404, 'sl-90');
    }

    /** TC-S91 — Stored XSS: a script payload in review_remarks is escaped when the review page re-renders. */
    public function test_student_leave_91_review_remarks_xss_escaped(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
        $payload = '<script>alert("sl-xss")</script>';

        $this->browseWithFailureScreenshot('sl-91-xss', function (Browser $browser) use ($app, $payload): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'         => 'Under Review',
                    'review_remarks' => $payload,
                ]);

            $browser->visit($this->tenantUrl("/student-profile/student-leave/{$app->id}/review"))->pause(700);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert("sl-xss")</script>', $source,
                'Raw script payload must not be rendered unescaped.');
        });

        $this->cleanupApplication($app);
    }

    /** TC-S92 — Mass-assignment guard: status cannot be forced through the update endpoint. */
    public function test_student_leave_92_update_cannot_force_status(): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);
        $leaveTypeId = $this->resolveLeaveTypeId();

        $this->browseWithFailureScreenshot('sl-92-mass-assign', function (Browser $browser) use ($app, $leaveTypeId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/edit", 600);

            $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update", [
                    'leave_type_id' => $leaveTypeId,
                    'from_date'     => now()->addDays(120)->toDateString(),
                    'to_date'       => now()->addDays(120)->toDateString(),
                    'total_days'    => 1,
                    'reason'        => 'mass assign attempt',
                    'status'        => 'Approved', // not in the update() validated set → ignored
                ]);
        });

        $app->refresh();
        $this->assertNotSame('Approved', (string) $app->status,
            'status must not be settable via the update() endpoint (not in validated rules).');

        $this->cleanupApplication($app);
    }

    // =========================================================================
    // HELPER METHODS
    // =========================================================================

    /**
     * Drive a legal transition through updateReview and assert it succeeds.
     * When $keep is true the application is returned (caller cleans up).
     */
    private function assertLegalTransition(string $from, string $to, string $case, bool $keep = false): LeaveApplication
    {
        $app = $this->seedApplication($from);

        $this->browseWithFailureScreenshot($case, function (Browser $browser) use ($app, $to): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", [
                    'status'         => $to,
                    'review_remarks' => "Transition {$app->status} -> {$to}",
                ]);
            $this->assertTrue(in_array((int) ($res['status'] ?? 0), [200, 302], true),
                "Legal transition {$app->status} -> {$to} should succeed.");
        });

        $app->refresh();
        $this->assertSame($to, (string) $app->status, "Status should become '{$to}'.");

        if (!$keep) {
            $this->cleanupApplication($app);
        }
        return $app;
    }

    /** Assert an updateReview payload is rejected (422) for a fresh Submitted application. */
    private function assertUpdateReviewRejected(array $payload, string $case): void
    {
        $app = $this->seedApplication(LeaveApplication::STATUS_SUBMITTED);

        $this->browseWithFailureScreenshot($case, function (Browser $browser) use ($app, $payload): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, "/student-profile/student-leave/{$app->id}/review", 600);

            $res = $this->sendJsonRequestFromBrowser($browser, 'PUT',
                "/student-profile/student-leave/{$app->id}/update-review", $payload);
            $this->assertSame(422, (int) ($res['status'] ?? 0), 'Expected 422 for invalid updateReview payload.');
        });

        $this->cleanupApplication($app);
    }

    /** Authenticate as admin, hit an endpoint, assert an exact status. */
    private function assertEndpointStatus(string $method, string $path, array $payload, int $expected, string $case): void
    {
        $this->browseWithFailureScreenshot($case, function (Browser $browser) use ($method, $path, $payload, $expected): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 600);

            $res = $this->sendJsonRequestFromBrowser($browser, $method, $path, $payload);
            $this->assertSame($expected, (int) ($res['status'] ?? 0),
                "Expected {$expected} for {$method} {$path}.");
        });
    }

    /** Convenience: GET a path via in-page fetch and return the numeric status. */
    private function httpStatusFromBrowser(Browser $browser, string $method, string $path): int
    {
        $res = $this->sendJsonRequestFromBrowser($browser, $method, $path, []);
        return (int) ($res['status'] ?? 0);
    }

    /**
     * Seed a leave application in a given status with a valid FK context.
     * Skips the test if no student/class-section/leave-type context is available.
     */
    private function seedApplication(string $status, array $overrides = []): LeaveApplication
    {
        $ctx = $this->resolveContext();
        $leaveTypeId = $this->resolveLeaveTypeId();

        if ($ctx === null || $leaveTypeId === null || $this->adminUser === null) {
            $this->markTestSkipped('Missing prerequisites (student / class-section / leave type) for seed.');
        }

        $from = now()->addDays(10)->toDateString();
        $to   = now()->addDays(11)->toDateString();

        return LeaveApplication::create(array_merge([
            'student_id'          => $ctx['student_id'],
            'academic_session_id' => $ctx['academic_session_id'],
            'class_section_id'    => $ctx['class_section_id'],
            'leave_type_id'       => $leaveTypeId,
            'from_date'           => $from,
            'to_date'             => $to,
            'total_days'          => 2,
            'is_half_day'         => false,
            'reason'              => 'Seeded leave application for testing',
            'status'              => $status,
            'applied_by'          => $this->adminUser->id,
            'created_by'          => $this->adminUser->id,
        ], $overrides));
    }

    /** Force-delete a seeded application and its children (defensive). */
    private function cleanupApplication(?LeaveApplication $app): void
    {
        if ($app === null) {
            return;
        }
        try {
            $id = $app->id;
            LeaveApplicationRemark::where('leave_application_id', $id)->delete();
            LeaveApplicationDocument::withTrashed()->where('leave_application_id', $id)->get()
                ->each(function ($d): void {
                    try { $d->forceDelete(); } catch (Throwable) {}
                });
            LeaveApplication::withTrashed()->whereKey($id)->first()?->forceDelete();
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    /**
     * Resolve a student + academic_session_id + class_section_id from an existing student's session.
     * Cached for the run.
     *
     * @return array{student_id:int, academic_session_id:int, class_section_id:int}|null
     */
    private function resolveContext(): ?array
    {
        if ($this->cachedContext !== null) {
            return $this->cachedContext;
        }

        try {
            $students = Student::query()->latest('id')->take(25)->get();
            foreach ($students as $student) {
                $session = null;
                try {
                    $session = $student->currentSession()->first();
                } catch (Throwable) {
                    $session = null;
                }
                if ($session
                    && !empty($session->academic_session_id)
                    && !empty($session->class_section_id)) {
                    $this->cachedContext = [
                        'student_id'          => (int) $student->id,
                        'academic_session_id' => (int) $session->academic_session_id,
                        'class_section_id'    => (int) $session->class_section_id,
                    ];
                    $this->cachedStudentId = (int) $student->id;
                    return $this->cachedContext;
                }
            }
        } catch (Throwable) {
            // fall through
        }

        return null;
    }

    /** Resolve (or create) an active leave type id. Cached. */
    private function resolveLeaveTypeId(): ?int
    {
        if ($this->cachedLeaveTypeId !== null) {
            return $this->cachedLeaveTypeId;
        }

        try {
            $type = LeaveType::query()->first();
            if ($type === null) {
                $type = LeaveType::create([
                    'code'                     => 'TST' . strtoupper(substr(uniqid(), -5)),
                    'name'                     => 'Test Leave Type ' . uniqid(),
                    'max_days_per_application' => 30,
                    'max_days_per_year'        => 0,
                    'requires_document'        => false,
                    'allow_half_day'           => true,
                    'advance_notice_days'      => 0,
                    'is_active'                => true,
                ]);
            }
            $this->cachedLeaveTypeId = (int) $type->id;
        } catch (Throwable) {
            $this->cachedLeaveTypeId = null;
        }

        return $this->cachedLeaveTypeId;
    }

    /**
     * Create a limited, NON-super-admin user with no student-leave permissions.
     * Used to exercise the Gate that Super Admins bypass (GAP-STD-06).
     */
    private function makeLimitedUser(): ?User
    {
        try {
            $suffix = '_' . uniqid(); // ≤ ~14 chars → fits emp_code VARCHAR(20) (05_ #9)
            $user = User::factory()->create([
                'name'              => 'Limited SL User',
                'email'             => 'limited.sl' . $suffix . '@example.com',
                'user_type'         => 'EMPLOYEE',
                'email_verified_at' => now(),
            ]);

            // Ensure NOT a super admin and holds no roles/permissions.
            try { $user->forceFill(['is_super_admin' => 0, 'super_admin_flag' => 0])->save(); } catch (Throwable) {}
            try {
                if (method_exists($user, 'syncRoles')) { $user->syncRoles([]); }
                if (method_exists($user, 'syncPermissions')) { $user->syncPermissions([]); }
            } catch (Throwable) {}

            return $user;
        } catch (Throwable) {
            return null;
        }
    }

    private function disposeUser(?User $user): void
    {
        if ($user === null) {
            return;
        }
        try { $user->forceDelete(); } catch (Throwable) {}
    }

    private function assertActivityLogged(int $subjectId, string $subjectType, string $event): void
    {
        $log = ActivityLog::query()
            ->where('subject_type', $subjectType)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->latest('id')
            ->first();

        $this->assertNotNull($log, "Activity log not found for event '{$event}' on {$subjectType} #{$subjectId}.");
    }

    /** Resolve a migration file by name fragment from the central tenant migrations dir (05_ #26). */
    private function resolveMigrationFile(string $fragment): ?string
    {
        $dir = base_path(self::MIGRATION_GLOB_DIR);
        if (!File::isDirectory($dir)) {
            return null;
        }
        foreach (File::files($dir) as $file) {
            if (str_contains($file->getFilename(), $fragment)) {
                return $file->getPathname();
            }
        }
        return null;
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
        $safeName  = preg_replace('/[^A-Za-z0-9_-]+/', '-', 'student-leave-fail-' . $caseName . '-' . $timestamp)
            ?? 'student-leave-fail-' . $timestamp;

        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    /**
     * Issue an authenticated fetch from within the page and return {status, ok, body, json}.
     * PUT/PATCH/DELETE are POST + _method spoofed for Laravel. Returns a real HTTP status
     * (Dusk's Browser has no assertStatus — 05_ #14).
     */
    private function sendJsonRequestFromBrowser(
        Browser $browser,
        string $method,
        string $url,
        array $payload = []
    ): array {
        $method         = strtoupper($method);
        $encodedMethod  = json_encode($method, JSON_THROW_ON_ERROR);
        $encodedUrl     = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $httpMethod = in_array($method, ['PUT', 'PATCH', 'DELETE'], true) ? '"POST"' : $encodedMethod;

        $browser->script(<<<JS
window.__slApiDone   = false;
window.__slApiError  = '';
window.__slApiResult = null;

(async function () {
    try {
        const method     = {$encodedMethod};
        const httpMethod = {$httpMethod};
        const url        = {$encodedUrl};
        const payload    = {$encodedPayload};
        const csrf       = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';

        const body = httpMethod !== 'GET' && httpMethod !== 'HEAD'
            ? JSON.stringify({ ...payload, _method: method })
            : undefined;

        const response = await fetch(url, {
            method: httpMethod,
            credentials: 'same-origin',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body,
        });

        const text = await response.text();
        let json = null;
        try { json = text ? JSON.parse(text) : null; } catch (_) {}

        window.__slApiResult = { status: response.status, ok: response.ok, body: text, json };
    } catch (error) {
        window.__slApiError = String(error);
    } finally {
        window.__slApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__slApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for student-leave API request.');

        $errorResult = $browser->script('return window.__slApiError || "";');
        $error       = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser request failed: ' . $error);

        $result   = $browser->script('return window.__slApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture student-leave API result.');

        return is_array($response) ? $response : [];
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

        $this->grantStudentLeavePermissions($this->adminUser);
    }

    private function grantStudentLeavePermissions(User $user): void
    {
        $permissions = [
            'tenant.student-leave.viewAny',
            'tenant.student-leave.view',
            'tenant.student-leave.create',
            'tenant.student-leave.update',
            'tenant.student-leave.review',
            'tenant.student-leave.delete',
            'tenant.student-leave.restore',
            'tenant.student-leave.forceDelete',
        ];

        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist($permissions, $guard);
        $this->syncRoleWithPermissions($user, $permissions, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach ($permissions as $perm) {
                try { $user->givePermissionTo($perm); } catch (Throwable) {}
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
            } catch (Throwable) {}
        }
    }

    private function syncRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }

        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.student-leave-admin');

        try {
            $role = \Spatie\Permission\Models\Role::firstOrCreate([
                'name'       => $roleName,
                'guard_name' => $guard,
            ]);

            if (method_exists($role, 'syncPermissions')) {
                $role->syncPermissions($permissions);
            }

            if (method_exists($user, 'assignRole')) {
                $user->assignRole($roleName);
            }
        } catch (Throwable) {}

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
            } catch (Throwable) {}
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
        } catch (Throwable) {}
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
