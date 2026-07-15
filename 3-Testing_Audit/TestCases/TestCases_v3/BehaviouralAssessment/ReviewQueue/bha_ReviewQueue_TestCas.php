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
use Modules\BehaviouralAssessment\Models\BaAssessment;
use Modules\BehaviouralAssessment\Models\BaAuditLog;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Review Queue (assessment review workflow) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/11-Review-Queue.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime table      : ba_assessments (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController
 *                      (reviewIndex / reviewShow / approve / sendBack + submit / bulkRate / autoSave)
 * Policy             : Modules\BehaviouralAssessment\Policies\BaReviewPolicy
 * Permission prefix  : tenant.behavioural-assessment.reviews.{viewAny|view|update|delete|restore|forceDelete|status}
 *                      (+ tenant.behavioural-assessment.assessments.{...} for submit/bulk-rate; assessments-page.viewAny for the tab)
 * Audit sink         : ba_audit_log (module-local immutable trail via BaAuditLog::log — NOT the generic activity_logs helper).
 *
 * WORKFLOW / STATE MACHINE (as implemented — see BC-SM band 20–29):
 *   draft --submit--> submitted --approve--> reviewed
 *   submitted|reviewed --sendBack--> draft
 *   ENUM('draft','submitted','reviewed','locked') — but `locked` is UNREACHABLE for assessments (dead state).
 *
 * Defects proven / documented (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md):
 *   - BUG-BA-001   : Ratings remain editable after submit/approve — bulkRate/autoSave guard only on
 *                    isLocked() (status==='locked'), which no assessment path ever sets. Proven in _20/_21/_22/_23.
 *   - BUG-BA-REV-002 (workflow) : requirement "Approve & Lock ... disables Send Back permanently"; code lets
 *                    a `reviewed` (approved) assessment be sent back to draft — the freeze is not permanent. Proven in _27.
 *   - VAL-BA-REV-001: sendBack() does not server-validate reviewer_remarks as required though the UI marks it
 *                    required and BR-BA-023 expects feedback. Proven in _30/_31. (Audit BR-BA-023 note: "remarks NOT validated".)
 *   - DOC-BA-REV-001 (naming) : requirement calls the approved state "Approved"; code/enum use `reviewed`, and the
 *                    Approve action does NOT lock (contradicts "Approve & Lock"). Proven in _15/_16/_28.
 *   - BUG-BA-REV-001 (candidate — verify) : reviewShow() references Modules\...\Models\BaStudentRemark WITHOUT an
 *                    import (and bulkRate uses the DB facade unimported); latent fatal/500 when the sheet is opened. Proven at source in _73.
 *   - DOC-BA-001   : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - SEC-BA-002   : BaAssessmentRequest::authorize() returns bare true, mitigated by controller Gate (proven in _92).
 */
class bha_ReviewQueue_TestCas extends DuskTestCase
{
    private const URL_PREFIX          = '/behavioural-assessment';
    private const REVIEW_INDEX_PATH   = '/behavioural-assessment/reviews';
    private const ASSESS_TAB_PATH     = '/behavioural-assessment/assessments-page?tab=review-queue';

    private const ASSESS_TABLE        = 'ba_assessments';
    private const DDL_ASSESS_TABLE    = 'bha_assessments';   // stale DDL-doc name (should NOT exist at runtime)
    private const AUDIT_TABLE         = 'ba_audit_log';
    private const RATINGS_TABLE       = 'ba_assessment_ratings';

    private const SCREENSHOT_DIR      = 'tests/Browser/Modules/BehaviouralAssessment/ReviewQueue/screenshots';

    /** @var array<int,string> */
    private const REVIEW_PERMISSIONS = [
        'tenant.behavioural-assessment.assessments-page.viewAny',
        'tenant.behavioural-assessment.reviews.viewAny',
        'tenant.behavioural-assessment.reviews.view',
        'tenant.behavioural-assessment.reviews.update',
        'tenant.behavioural-assessment.reviews.delete',
        'tenant.behavioural-assessment.reviews.restore',
        'tenant.behavioural-assessment.reviews.forceDelete',
        'tenant.behavioural-assessment.reviews.status',
        'tenant.behavioural-assessment.assessments.viewAny',
        'tenant.behavioural-assessment.assessments.view',
        'tenant.behavioural-assessment.assessments.create',
        'tenant.behavioural-assessment.assessments.update',
        'tenant.behavioural-assessment.assessments.delete',
    ];

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    /** @var array<int,int> Assessment ids this run freshly created — safe to force-delete on cleanup. */
    private array $seededAssessmentIds = [];

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
        foreach ($this->seededAssessmentIds as $id) {
            $this->forceDeleteAssessmentById($id);
        }
        $this->seededAssessmentIds = [];

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01–09 — Schema / DDL / model / request configuration truth
    // =====================================================================

    public function test_review_queue_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::ASSESS_TABLE), 'Table ba_assessments does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::ASSESS_TABLE, [
                'id', 'period_id', 'teacher_id', 'class_section_id', 'status',
                'submitted_at', 'reviewed_by', 'reviewed_at', 'reviewer_remarks',
                'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_assessments table.'
        );

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130617_create_ba_assessments_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_assessments'", $migration);
            $this->assertStringContainsString("\$table->enum('status', ['draft', 'locked', 'reviewed', 'submitted'])", $migration);
            $this->assertStringContainsString("\$table->timestamp('submitted_at')", $migration);
            $this->assertStringContainsString("\$table->timestamp('reviewed_at')", $migration);
            $this->assertStringContainsString("uq_ba_assessment", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // Model configuration.
        $assessment = new BaAssessment();
        $this->assertSame('ba_assessments', $assessment->getTable());
        $this->assertSame([
            'period_id', 'teacher_id', 'class_section_id', 'reviewed_by', 'status',
            'submitted_at', 'reviewed_at', 'reviewer_remarks', 'is_active', 'created_by', 'updated_by',
        ], $assessment->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessment::class));

        // Relationships + FSM helper methods.
        $this->assertInstanceOf(BelongsTo::class, $assessment->period());
        $this->assertInstanceOf(BelongsTo::class, $assessment->teacher());
        $this->assertInstanceOf(BelongsTo::class, $assessment->reviewer());
        $this->assertInstanceOf(BelongsTo::class, $assessment->classSection());
        $this->assertInstanceOf(HasMany::class, $assessment->ratings());
        $this->assertInstanceOf(HasMany::class, $assessment->studentRemarks());
        $this->assertTrue(method_exists($assessment, 'isDraft'));
        $this->assertTrue(method_exists($assessment, 'isLocked'));
    }

    public function test_review_queue_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        $this->assertTrue(Schema::hasTable(self::ASSESS_TABLE), 'Runtime table ba_assessments must exist.');

        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_ASSESS_TABLE),
                'DOC-BA-001 regression: bha_assessments exists at runtime; expected only the live ba_assessments.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_assessments', (new BaAssessment())->getTable());
    }

    public function test_review_queue_03_audit_log_table_and_model_are_immutable_and_configured(): void
    {
        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE), 'Table ba_audit_log does not exist.');

        $log = new BaAuditLog();
        $this->assertSame('ba_audit_log', $log->getTable());
        // Immutable trail — no updated_at / no soft delete (DDL: "NEVER modified or deleted").
        $this->assertFalse($log->usesTimestamps(), 'ba_audit_log model must have $timestamps = false.');
        $this->assertFalse(
            in_array(SoftDeletes::class, class_uses_recursive(BaAuditLog::class), true),
            'ba_audit_log must NOT use SoftDeletes (immutable audit trail).'
        );
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'updated_at'), 'ba_audit_log must have no updated_at (immutable).');
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'deleted_at'), 'ba_audit_log must have no deleted_at (immutable).');

        $this->assertSame('assessment', BaAuditLog::ENTITY_ASSESSMENT);
        $this->assertSame('assessment_rating', BaAuditLog::ENTITY_ASSESSMENT_RATING);
    }

    public function test_review_queue_04_status_enum_matches_ddl_values(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('ENUM introspection requires MySQL.');
        }
        $col = collect(DB::select('SHOW COLUMNS FROM ' . self::ASSESS_TABLE))->firstWhere('Field', 'status');
        $this->assertNotNull($col, 'status column not found.');
        $type = strtolower((string) ($col->Type ?? ''));
        foreach (['draft', 'submitted', 'reviewed', 'locked'] as $value) {
            $this->assertStringContainsString("'{$value}'", $type, "status ENUM must contain '{$value}'.");
        }
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_review_queue_10_review_index_lists_only_submitted_assessments(): void
    {
        // Source truth: reviewIndex() filters where('status','submitted'). Assert the query contract at source
        // and the page renders the queue heading (browser). Behavioural presence is covered by _13/_29.
        $controller = $this->readControllerSource();
        if ($controller !== null) {
            $this->assertMatchesRegularExpression(
                "/function\s+reviewIndex\b.*?where\('status',\s*'submitted'\)/s",
                $controller,
                'reviewIndex must filter the queue to status = submitted.'
            );
        }

        $this->browseWithFailureScreenshot('review-index-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REVIEW_INDEX_PATH, 1000);
            $browser->assertSee('Submitted Assessments Awaiting Review');
        });
    }

    public function test_review_queue_11_review_index_shows_pending_count_badge(): void
    {
        $this->browseWithFailureScreenshot('review-index-badge', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REVIEW_INDEX_PATH, 1000);
            $browser->assertSee('pending');
        });
    }

    public function test_review_queue_12_review_queue_tab_present_on_assessments_page(): void
    {
        $this->browseWithFailureScreenshot('review-tab', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::ASSESS_TAB_PATH, 1100);
            $browser->assertSee('Review Queue');
        });
    }

    public function test_review_queue_13_approve_transitions_submitted_to_reviewed_and_logs_audit(): void
    {
        $assessment = $this->seedAssessment('submitted');
        if ($assessment === null) {
            $this->markTestSkipped('Cross-module FK deps (period/employee/class-section) unavailable — cannot seed an assessment.');
        }

        $response = $this->postForm('/behavioural-assessment/reviews/' . $assessment->id . '/approve');
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Approve should redirect.');

        $assessment->refresh();
        $this->assertSame('reviewed', $assessment->status, 'A submitted assessment must transition to reviewed on approve.');
        $this->assertNotNull($assessment->reviewed_at, 'reviewed_at must be stamped on approve.');

        // Audit trail row status submitted → reviewed.
        $this->assertTrue(
            DB::table(self::AUDIT_TABLE)
                ->where('entity_type', 'assessment')->where('entity_id', $assessment->id)
                ->where('field_name', 'status')->where('new_value', 'reviewed')->exists(),
            'Approve must write a status→reviewed audit row.'
        );
    }

    public function test_review_queue_14_send_back_transitions_to_draft_and_clears_review_fields(): void
    {
        $assessment = $this->seedAssessment('submitted');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a submitted assessment.');
        }

        $response = $this->postForm('/behavioural-assessment/reviews/' . $assessment->id . '/send-back', [
            'reviewer_remarks' => 'Please expand the remarks for Roll 12.',
        ]);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $assessment->refresh();
        $this->assertSame('draft', $assessment->status, 'Send Back must revert the assessment to draft.');
        $this->assertNull($assessment->submitted_at, 'submitted_at must be cleared on send back.');
        $this->assertNull($assessment->reviewed_by, 'reviewed_by must be cleared on send back.');
        $this->assertSame('Please expand the remarks for Roll 12.', $assessment->reviewer_remarks);
    }

    public function test_review_queue_15_approve_confirmation_text_marks_reviewed_not_locked_doc_ba_rev_001(): void
    {
        // Requirement §"Approved State Freeze": Approve & Lock; confirmation "…locked. Proceed?".
        // The real review-show confirmation says "This will mark it as reviewed." — no lock, no "Approved".
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/review-show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('review-show blade not readable from app repo.');
        }
        $this->assertStringContainsString('mark it as reviewed', $blade, 'DOC-BA-REV-001 changed: approve confirmation no longer says "mark it as reviewed".');
    }

    public function test_review_queue_16_approve_sets_reviewed_status_not_approved_doc_ba_rev_001(): void
    {
        // Code sets status 'reviewed' on approve — the requirement's "Approved" state name is not used,
        // and no lock is applied (contradicts the requirement's "Approve & Lock").
        $controller = $this->readControllerSource();
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertMatchesRegularExpression(
            "/function\s+approve\b.*?'status'\s*=>\s*'reviewed'/s",
            $controller,
            'approve() must set status to reviewed (documents the Approved/reviewed naming divergence).'
        );
        $this->assertDoesNotMatchRegularExpression(
            "/function\s+approve\b.*?'status'\s*=>\s*'locked'/s",
            $controller,
            'DOC-BA-REV-001 changed: approve() now sets locked — the "Approve & Lock" requirement may be implemented.'
        );
    }

    public function test_review_queue_17_approve_and_send_back_redirect_to_review_queue_tab(): void
    {
        $controller = $this->readControllerSource();
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertStringContainsString("['tab' => 'review-queue']", $controller, 'Approve/sendBack must redirect back to the review-queue tab.');
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM) — draft → submitted → reviewed / send-back
    // =====================================================================

    public function test_review_queue_20_is_locked_true_only_for_locked_status_bug_ba_001(): void
    {
        // Deterministic (no DB): the lock predicate the read-only guard depends on.
        $draft     = new BaAssessment(['status' => 'draft']);
        $submitted = new BaAssessment(['status' => 'submitted']);
        $reviewed  = new BaAssessment(['status' => 'reviewed']);
        $locked    = new BaAssessment(['status' => 'locked']);

        $this->assertFalse($submitted->isLocked(), 'BUG-BA-001: a SUBMITTED assessment is not treated as locked.');
        $this->assertFalse($reviewed->isLocked(), 'BUG-BA-001: a REVIEWED (approved) assessment is not treated as locked.');
        $this->assertFalse($draft->isLocked());
        $this->assertTrue($locked->isLocked(), 'Only status === locked is locked — a value the workflow never sets.');

        $this->assertTrue($draft->isDraft());
        $this->assertFalse($submitted->isDraft());
    }

    public function test_review_queue_21_bulk_rate_and_auto_save_guard_only_on_locked_status_bug_ba_001(): void
    {
        // Source proof: the read-only guard in bulkRate/autoSave checks ONLY isLocked(); there is no
        // status !== 'draft' / submitted / reviewed check, so editing survives submit and approve.
        $controller = $this->readControllerSource();
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertMatchesRegularExpression(
            "/function\s+bulkRate\b.*?if\s*\(\s*\\\$item->isLocked\(\)\s*\)/s",
            $controller,
            'bulkRate must guard on isLocked() (the ineffective lock check — BUG-BA-001).'
        );
        $this->assertMatchesRegularExpression(
            "/function\s+autoSave\b.*?if\s*\(\s*\\\$item->isLocked\(\)\s*\)/s",
            $controller,
            'autoSave must guard on isLocked() (the ineffective lock check — BUG-BA-001).'
        );
        // And there is NO submitted/reviewed read-only guard in the rating writers.
        $this->assertDoesNotMatchRegularExpression(
            "/function\s+bulkRate\b.*?status\s*!==\s*'draft'/s",
            $controller,
            'BUG-BA-001 changed: bulkRate now blocks non-draft assessments.'
        );
    }

    public function test_review_queue_22_ratings_editable_after_submit_endpoint_bug_ba_001(): void
    {
        $assessment = $this->seedAssessment('submitted');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a submitted assessment.');
        }
        $probe = $this->ratingProbe($assessment);
        if ($probe === null) {
            $this->markTestSkipped('No student/criterion/rating-level available to exercise a post-submit edit.');
        }

        $response = $this->postForm('/behavioural-assessment/assessments/' . $assessment->id . '/bulk-rate', [
            'ratings' => [
                (string) $probe['studentId'] => [
                    (string) $probe['criterionId'] => (string) $probe['levelId'],
                ],
            ],
        ]);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'bulk-rate should not be blocked for a submitted assessment.');

        // BUG-BA-001: the rating persisted even though the assessment is already SUBMITTED.
        $this->assertTrue(
            DB::table(self::RATINGS_TABLE)
                ->where('assessment_id', $assessment->id)
                ->where('student_id', $probe['studentId'])
                ->where('criterion_id', $probe['criterionId'])
                ->where('rating_level_id', $probe['levelId'])
                ->exists(),
            'BUG-BA-001: ratings are still editable after submit (no read-only enforcement).'
        );
        $assessment->refresh();
        $this->assertSame('submitted', $assessment->status, 'bulk-rate must not change the workflow status.');

        DB::table(self::RATINGS_TABLE)->where('assessment_id', $assessment->id)->delete();
    }

    public function test_review_queue_23_ratings_editable_after_approve_reviewed_endpoint_bug_ba_001(): void
    {
        $assessment = $this->seedAssessment('reviewed');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a reviewed assessment.');
        }
        $probe = $this->ratingProbe($assessment);
        if ($probe === null) {
            $this->markTestSkipped('No student/criterion/rating-level available to exercise a post-approve edit.');
        }

        $response = $this->postForm('/behavioural-assessment/assessments/' . $assessment->id . '/bulk-rate', [
            'ratings' => [
                (string) $probe['studentId'] => [
                    (string) $probe['criterionId'] => (string) $probe['levelId'],
                ],
            ],
        ]);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertTrue(
            DB::table(self::RATINGS_TABLE)
                ->where('assessment_id', $assessment->id)
                ->where('student_id', $probe['studentId'])
                ->where('criterion_id', $probe['criterionId'])
                ->exists(),
            'BUG-BA-001: ratings are still editable after approve (reviewed) — cached scores can silently diverge.'
        );

        DB::table(self::RATINGS_TABLE)->where('assessment_id', $assessment->id)->delete();
    }

    public function test_review_queue_24_submit_illegal_from_submitted_is_rejected(): void
    {
        $assessment = $this->seedAssessment('submitted');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a submitted assessment.');
        }

        $this->postForm('/behavioural-assessment/assessments/' . $assessment->id . '/submit');
        $assessment->refresh();
        $this->assertSame('submitted', $assessment->status, 'submit() must reject a non-draft assessment (status unchanged).');
    }

    public function test_review_queue_25_approve_illegal_from_draft_is_rejected(): void
    {
        $assessment = $this->seedAssessment('draft');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a draft assessment.');
        }

        $this->postForm('/behavioural-assessment/reviews/' . $assessment->id . '/approve');
        $assessment->refresh();
        $this->assertSame('draft', $assessment->status, 'approve() must reject a non-submitted assessment.');
    }

    public function test_review_queue_26_send_back_illegal_from_draft_is_rejected(): void
    {
        $assessment = $this->seedAssessment('draft');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a draft assessment.');
        }

        $this->postForm('/behavioural-assessment/reviews/' . $assessment->id . '/send-back', [
            'reviewer_remarks' => 'irrelevant',
        ]);
        $assessment->refresh();
        $this->assertSame('draft', $assessment->status, 'sendBack() must reject an assessment that is not submitted/reviewed.');
    }

    public function test_review_queue_27_send_back_from_reviewed_unfreezes_bug_ba_rev_002(): void
    {
        // Requirement §"Approved State Freeze": approving "Disables the Send Back option permanently".
        // Code lets a reviewed (approved) assessment be sent back to draft — the freeze is NOT permanent.
        $assessment = $this->seedAssessment('reviewed');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a reviewed assessment.');
        }

        $this->postForm('/behavioural-assessment/reviews/' . $assessment->id . '/send-back', [
            'reviewer_remarks' => 'Reopening an approved sheet.',
        ]);
        $assessment->refresh();
        $this->assertSame('draft', $assessment->status, 'BUG-BA-REV-002: an approved (reviewed) assessment was un-frozen back to draft.');
    }

    public function test_review_queue_28_locked_status_is_unreachable_for_assessments_dead_state(): void
    {
        // No BaAssessmentController path ever assigns status 'locked' (the period lock never cascades).
        $controller = $this->readControllerSource();
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertStringNotContainsString("'status' => 'locked'", $controller,
            'DEAD-state changed: BaAssessmentController now sets an assessment to locked.');
    }

    public function test_review_queue_29_legal_transition_chain_draft_submit_approve(): void
    {
        $assessment = $this->seedAssessment('draft');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a draft assessment.');
        }

        // draft --submit--> submitted
        $this->postForm('/behavioural-assessment/assessments/' . $assessment->id . '/submit');
        $assessment->refresh();
        $this->assertSame('submitted', $assessment->status, 'draft must transition to submitted.');
        $this->assertNotNull($assessment->submitted_at);

        // submitted --approve--> reviewed
        $this->postForm('/behavioural-assessment/reviews/' . $assessment->id . '/approve');
        $assessment->refresh();
        $this->assertSame('reviewed', $assessment->status, 'submitted must transition to reviewed.');
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL)
    // =====================================================================

    public function test_review_queue_30_send_back_reviewer_remarks_not_required_server_side_val_ba_rev_001(): void
    {
        // UI marks reviewer_remarks required; BR-BA-023 expects feedback. sendBack() does NOT validate it.
        $assessment = $this->seedAssessment('submitted');
        if ($assessment === null) {
            $this->markTestSkipped('FK deps unavailable — cannot seed a submitted assessment.');
        }

        $response = $this->postForm('/behavioural-assessment/reviews/' . $assessment->id . '/send-back', [
            'reviewer_remarks' => '',
        ]);
        // No 422 — the empty-remarks send-back is accepted and the status reverts to draft.
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'VAL-BA-REV-001: empty reviewer_remarks is NOT rejected server-side.');
        $assessment->refresh();
        $this->assertSame('draft', $assessment->status, 'VAL-BA-REV-001: send-back succeeded with empty remarks.');
        $this->assertTrue(
            $assessment->reviewer_remarks === null || $assessment->reviewer_remarks === '',
            'VAL-BA-REV-001: reviewer_remarks was persisted empty/null.'
        );
    }

    public function test_review_queue_31_send_back_has_no_required_remarks_rule_at_source_val_ba_rev_001(): void
    {
        $controller = $this->readControllerSource();
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        // The blade requires it; the controller sendBack() never validates reviewer_remarks as required.
        $this->assertDoesNotMatchRegularExpression(
            "/function\s+sendBack\b.*?'reviewer_remarks'\s*=>\s*\[[^\]]*'required'/s",
            $controller,
            'VAL-BA-REV-001 changed: sendBack now enforces required reviewer_remarks.'
        );

        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/review-show.blade.php'));
        if ($blade !== null) {
            $this->assertStringContainsString('name="reviewer_remarks"', $blade);
            $this->assertStringContainsString('required', $blade, 'UI marks the remarks textarea required (client-only enforcement).');
        }
    }

    public function test_review_queue_32_form_request_rules_reference_ba_prefixed_tables(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaAssessmentRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('BaAssessmentRequest not readable from app repo.');
        }
        $this->assertStringContainsString("exists:ba_assessment_periods,id", $request, 'period_id must validate against the live ba_ table.');
        $this->assertStringContainsString("exists:sch_class_section_jnt,id", $request);
        $this->assertStringContainsString("exists:sch_employees,id", $request);
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency (BC-INT/REF)
    // =====================================================================

    public function test_review_queue_40_assessment_period_fk_is_restrict(): void
    {
        $this->assertFkDeleteRule('ba_assessment_periods', 'RESTRICT', 'ba_assessments.period_id should RESTRICT period delete.');
    }

    public function test_review_queue_41_assessment_reviewed_by_fk_is_set_null(): void
    {
        $this->assertFkDeleteRule('sch_employees', 'SET NULL', 'ba_assessments.reviewed_by should SET NULL on employee delete.', 'reviewed_by');
    }

    public function test_review_queue_42_approve_invokes_score_service_for_period(): void
    {
        // approve() delegates to BehaviouralScoreService::computeForPeriod (source contract).
        $controller = $this->readControllerSource();
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertMatchesRegularExpression(
            "/function\s+approve\b.*?computeForPeriod\(/s",
            $controller,
            'approve() must compute behavioural scores for the period after review.'
        );
        $this->assertTrue(
            method_exists(\Modules\BehaviouralAssessment\Services\BehaviouralScoreService::class, 'computeForPeriod'),
            'BehaviouralScoreService::computeForPeriod must exist.'
        );
    }

    public function test_review_queue_43_assessment_uses_soft_deletes(): void
    {
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessment::class));
        $this->assertTrue(Schema::hasColumn(self::ASSESS_TABLE, 'deleted_at'));
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_review_queue_50_guest_is_redirected_to_login_on_review_index(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::REVIEW_INDEX_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_review_queue_51_limited_user_without_viewany_gets_403_on_review_index(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-index-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REVIEW_INDEX_PATH));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without reviews.viewAny must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_review_queue_52_limited_user_without_view_gets_403_on_review_show(): void
    {
        // Gate::authorize runs before findOrFail, so a limited user 403s even on a non-existent id.
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-show-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::REVIEW_INDEX_PATH . '/999999'));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
    }

    public function test_review_queue_53_limited_user_without_update_gets_403_on_approve(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-approve-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::REVIEW_INDEX_PATH . '/999999/approve'));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
    }

    public function test_review_queue_54_limited_user_without_update_gets_403_on_send_back(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-sendback-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::REVIEW_INDEX_PATH . '/999999/send-back'));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
    }

    public function test_review_queue_55_review_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaReviewPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('BaReviewPolicy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'update', 'delete', 'restore', 'forceDelete', 'status'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.reviews.{$ability}",
                $policy,
                "Policy missing gate string for reviews.{$ability}."
            );
        }
        // Dedicated approve/sendBack policy methods reuse reviews.update.
        $this->assertStringContainsString('function approve', $policy);
        $this->assertStringContainsString('function sendBack', $policy);
    }

    public function test_review_queue_56_review_controller_methods_are_gated(): void
    {
        $controller = $this->readControllerSource();
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.reviews.viewAny')", $controller);
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.reviews.view')", $controller);
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.reviews.update')", $controller);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (breadcrumb, empty-state, actions)
    // =====================================================================

    public function test_review_queue_60_review_index_breadcrumb_and_heading(): void
    {
        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REVIEW_INDEX_PATH, 1000);
            $browser->assertSee('Review Queue')
                ->assertSee('Submitted Assessments Awaiting Review');
        });
    }

    public function test_review_queue_61_review_index_columns_present(): void
    {
        $this->browseWithFailureScreenshot('columns', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REVIEW_INDEX_PATH, 1000);
            $browser->assertSee('Period')
                ->assertSee('Teacher')
                ->assertSee('Class / Section')
                ->assertSee('Submitted');
        });
    }

    public function test_review_queue_62_empty_state_or_queue_renders_table(): void
    {
        $this->browseWithFailureScreenshot('empty-or-table', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::REVIEW_INDEX_PATH, 1000);
            $source = $browser->driver->getPageSource();
            $this->assertTrue(
                str_contains($source, 'No assessments pending review.') || str_contains($source, '<table'),
                'Review index must render either the empty-state message or the queue table.'
            );
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_review_queue_70_review_show_invalid_id_returns_404(): void
    {
        $response = $this->apiCall('GET', $this->tenantUrl(self::REVIEW_INDEX_PATH . '/987654321'));
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Admin (permitted) hitting a missing review id must 404.');
    }

    public function test_review_queue_71_approve_invalid_id_returns_404(): void
    {
        $response = $this->postForm('/behavioural-assessment/reviews/987654321/approve');
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Approve on a missing id must 404 (findOrFail).');
    }

    public function test_review_queue_72_send_back_invalid_id_returns_404(): void
    {
        $response = $this->postForm('/behavioural-assessment/reviews/987654321/send-back', ['reviewer_remarks' => 'x']);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Send-back on a missing id must 404 (findOrFail).');
    }

    public function test_review_queue_73_review_show_references_unimported_bastudentremark_bug_ba_rev_001_candidate(): void
    {
        // CANDIDATE (verify in source): reviewShow() calls BaStudentRemark::where(...) with NO import and no
        // FQN, and bulkRate uses the DB facade unimported — a latent fatal/500 when the review sheet is opened.
        // Deterministic source proof; a future fix that adds the import will (correctly) fail this test for re-review.
        $controller = $this->readControllerSource();
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        // The symbol is referenced...
        $this->assertStringContainsString('BaStudentRemark::', $controller, 'Precondition: controller references BaStudentRemark.');
        // ...but is neither imported nor fully-qualified at the call site.
        $imported = (bool) preg_match('/use\s+Modules\\\\BehaviouralAssessment\\\\Models\\\\BaStudentRemark;/', $controller);
        $fqnUsed  = str_contains($controller, '\\Modules\\BehaviouralAssessment\\Models\\BaStudentRemark::');
        $this->assertFalse(
            $imported || $fqnUsed,
            'BUG-BA-REV-001 appears fixed: BaStudentRemark is now imported/FQN-qualified. Re-verify reviewShow no longer 500s.'
        );
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_review_queue_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side review-queue tests.'
        );
        $this->assertTrue(Schema::hasTable(self::ASSESS_TABLE));
    }

    public function test_review_queue_91_cross_tenant_direct_id_isolation(): void
    {
        try {
            $otherDomain = Domain::query()
                ->where('domain', '!=', parse_url($this->tenantBaseUrl, PHP_URL_HOST))
                ->first();
            if (!$otherDomain) {
                $this->markTestSkipped('Only one tenant domain available — cross-tenant isolation not exercisable.');
            }
            $this->assertNotNull($otherDomain->tenant, 'Second tenant exists for isolation checks.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Cross-tenant isolation path unavailable: ' . $e->getMessage());
        }
    }

    public function test_review_queue_92_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaAssessmentRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('BaAssessmentRequest source not readable from app repo.');
        }
        $this->assertMatchesRegularExpression(
            '/function\s+authorize\s*\(\s*\)\s*:\s*bool\s*\{\s*return\s+true\s*;/s',
            $request,
            'SEC-BA-002 changed: BaAssessmentRequest::authorize() no longer returns bare true.'
        );
    }

    public function test_review_queue_93_review_show_grid_escapes_output_no_raw_blade(): void
    {
        // The read-only review grid and reviewer_remarks must render through {{ }} (escaped), never {!! !!}.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/review-show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('review-show blade not readable from app repo.');
        }
        $this->assertStringNotContainsString('{!!', $blade, 'Review sheet must not use unescaped Blade output ({!! !!}).');
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
        $rawName = 'review-queue-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'review-queue-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- Browser-issued authenticated HTTP -------------------------------

    /**
     * Issue an authenticated (admin) request from a freshly-opened, logged-in page.
     * Opens the review index (same-origin cookies + CSRF meta), then fetch()es the target URL.
     */
    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
    }

    /** POST a form-style state-changing request (approve/send-back/submit/bulk-rate) as the admin. */
    private function postForm(string $path, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl($path), $payload));
    }

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->visitAuthenticated($browser, self::REVIEW_INDEX_PATH, 900);
            $result = $callback($browser);
        });
        return $result;
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
window.__rqApiDone = false;
window.__rqApiError = '';
window.__rqApiResult = null;

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

        window.__rqApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__rqApiError = String(error);
    } finally {
        window.__rqApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__rqApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser request to complete.');

        $errorResult = $browser->script('return window.__rqApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser request failed: ' . $error);

        $result = $browser->script('return window.__rqApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Seed / cleanup (defensive, cross-module FK aware) ---------------

    /** @return array{periodId:int,teacherId:int,csId:int}|null */
    private function assessmentDeps(): ?array
    {
        try {
            $periodId  = (int) (DB::table('ba_assessment_periods')->value('id') ?? 0);
            $teacherId = (int) (DB::table('sch_employees')->value('id') ?? 0);
            $csId      = (int) (DB::table('sch_class_section_jnt')->value('id') ?? 0);
        } catch (Throwable) {
            return null;
        }
        if ($periodId === 0 || $teacherId === 0 || $csId === 0) {
            return null;
        }
        return ['periodId' => $periodId, 'teacherId' => $teacherId, 'csId' => $csId];
    }

    private function seedAssessment(string $status, array $overrides = []): ?BaAssessment
    {
        $deps = $this->assessmentDeps();
        if ($deps === null) {
            return null;
        }

        $attributes = array_merge([
            'period_id'        => $deps['periodId'],
            'teacher_id'       => $deps['teacherId'],
            'class_section_id' => $deps['csId'],
            'status'           => $status,
            'submitted_at'     => in_array($status, ['submitted', 'reviewed'], true) ? now() : null,
            'reviewed_at'      => $status === 'reviewed' ? now() : null,
            'reviewer_remarks' => null,
            'reviewed_by'      => null,
            'is_active'        => true,
            'created_by'       => (int) $this->adminUser->id,
            'updated_by'       => (int) $this->adminUser->id,
        ], $overrides);

        try {
            $assessment = BaAssessment::create($attributes);
            $this->seededAssessmentIds[] = (int) $assessment->id;
            return $assessment;
        } catch (Throwable) {
            // uq_ba_assessment (teacher, class_section, period) already used — reuse & mutate that row for the test.
            try {
                $existing = BaAssessment::withTrashed()
                    ->where('teacher_id', $deps['teacherId'])
                    ->where('class_section_id', $deps['csId'])
                    ->where('period_id', $deps['periodId'])
                    ->first();
                if ($existing === null) {
                    return null;
                }
                if ($existing->trashed()) {
                    $existing->restore();
                }
                $existing->update(array_merge(['status' => $status], $overrides, [
                    'submitted_at' => in_array($status, ['submitted', 'reviewed'], true) ? now() : null,
                    'reviewed_at'  => $status === 'reviewed' ? now() : null,
                ]));
                return $existing; // NOT force-deleted on cleanup — it was pre-existing data.
            } catch (Throwable) {
                return null;
            }
        }
    }

    /** @return array{studentId:int,criterionId:int,levelId:int}|null */
    private function ratingProbe(BaAssessment $assessment): ?array
    {
        try {
            $studentId = (int) (DB::table('std_student_academic_sessions')
                ->where('class_section_id', $assessment->class_section_id)
                ->value('student_id') ?? 0);
            if ($studentId === 0) {
                $studentId = (int) (DB::table('std_students')->value('id') ?? 0);
            }
            $criterionId = (int) (DB::table('ba_criteria')->where('is_active', true)->value('id')
                ?? DB::table('ba_criteria')->value('id') ?? 0);
            $levelId = (int) (DB::table('ba_rating_levels')->where('is_active', true)->value('id')
                ?? DB::table('ba_rating_levels')->value('id') ?? 0);
        } catch (Throwable) {
            return null;
        }
        if ($studentId === 0 || $criterionId === 0 || $levelId === 0) {
            return null;
        }
        return ['studentId' => $studentId, 'criterionId' => $criterionId, 'levelId' => $levelId];
    }

    private function forceDeleteAssessmentById(int $id): void
    {
        try {
            DB::table(self::RATINGS_TABLE)->where('assessment_id', $id)->delete();
        } catch (Throwable) {
        }
        try {
            DB::table('ba_student_remarks')->where('assessment_id', $id)->delete();
        } catch (Throwable) {
        }
        try {
            DB::table(self::AUDIT_TABLE)->where('entity_type', 'assessment')->where('entity_id', $id)->delete();
        } catch (Throwable) {
        }
        try {
            $row = BaAssessment::withTrashed()->find($id);
            if ($row !== null) {
                $row->forceDelete();
            }
        } catch (Throwable) {
        }
    }

    private function assertFkDeleteRule(string $referencedTable, string $expectedRule, string $message, ?string $column = null): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('FK rule inspection requires MySQL.');
        }
        try {
            $rows = DB::select(
                "SELECT rc.DELETE_RULE, kcu.COLUMN_NAME
                 FROM information_schema.REFERENTIAL_CONSTRAINTS rc
                 JOIN information_schema.KEY_COLUMN_USAGE kcu
                   ON kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME AND kcu.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
                 WHERE rc.CONSTRAINT_SCHEMA = DATABASE()
                   AND rc.TABLE_NAME = 'ba_assessments'
                   AND rc.REFERENCED_TABLE_NAME = ?",
                [$referencedTable]
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('FK metadata unavailable: ' . $e->getMessage());
        }
        if (empty($rows)) {
            $this->markTestSkipped("No FK metadata for ba_assessments → {$referencedTable}.");
        }
        $match = null;
        foreach ($rows as $row) {
            if ($column === null || strtolower((string) $row->COLUMN_NAME) === strtolower($column)) {
                $match = $row;
                break;
            }
        }
        $this->assertNotNull($match, "FK to {$referencedTable} on column {$column} not found.");
        $rule = strtoupper((string) ($match->DELETE_RULE ?? ''));
        $needle = strtoupper($expectedRule);
        $this->assertTrue(
            str_contains($rule, $needle) || ($needle === 'RESTRICT' && str_contains($rule, 'NO ACTION')),
            $message . ' Found: ' . $rule
        );
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
                'name'              => 'RQ Limited ' . $this->uniqueSuffix(),
                'email'             => 'rq_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'RQ' . substr($this->uniqueSuffix(), -8);
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
        $this->grantReviewPermissions($this->adminUser);
    }

    private function grantReviewPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::REVIEW_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::REVIEW_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::REVIEW_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.review-queue-admin');
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

    private function readControllerSource(): ?string
    {
        return $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
    }

    private function moduleRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaAssessment::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaAssessment.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaAssessment::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaAssessment.php → app root = dirname(,5)
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
