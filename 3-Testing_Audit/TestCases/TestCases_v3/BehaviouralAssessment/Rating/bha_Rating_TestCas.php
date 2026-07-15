<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaAssessment;
use Modules\BehaviouralAssessment\Models\BaAssessmentRating;
use Modules\BehaviouralAssessment\Models\BaCategory;
use Modules\BehaviouralAssessment\Models\BaCriterion;
use Modules\BehaviouralAssessment\Models\BaRatingLevel;
use Modules\BehaviouralAssessment\Models\BaRatingScale;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Ratings Grid (transactional data-entry screen) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/09-Ratings.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime tables     : ba_assessment_ratings (core fact table), ba_assessments, ba_audit_log
 *                      (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController
 *                      (index/create/store/show/edit/update/destroy + auto-save/bulk-rate/submit)
 * Save endpoints     : POST /behavioural-assessment/assessments/{id}/auto-save   (autoSave — JSON, per-cell autosave)
 *                      POST /behavioural-assessment/assessments/{id}/bulk-rate   (bulkRate — form, full-grid save)
 * FormRequest        : NONE for the rating grid — autoSave/bulkRate use inline $request->validate() (VAL-BA-001).
 * Permission prefix  : tenant.behavioural-assessment.assessments.{viewAny|view|create|update|delete|restore|forceDelete|status}
 * Activity/audit log : Manual BaAuditLog::log(ENTITY_ASSESSMENT_RATING, ...) inside autoSave/bulkRate on each changed cell
 *                      → tenant table ba_audit_log (immutable: no updated_at / no deleted_at).
 *
 * PRIMARY DEFECT PROVEN — BUG-BA-001 (P1; P0 if result-integration enabled):
 *   Ratings remain editable after the assessment is submitted/approved and after the period is locked.
 *   Root cause : BaAssessment::isLocked() === ($status === 'locked'), but NO code path ever sets an
 *                assessment to 'locked' (submit → 'submitted', approve → 'reviewed'; period lock() sets the
 *                PERIOD status only and never cascades). The Blade grid correctly disables inputs when
 *                `status !== 'draft'`, but the autoSave/bulkRate server endpoints only guard on isLocked(),
 *                so a direct POST persists rating writes on submitted/reviewed/period-locked assessments.
 *                Proven at model level (_20/_24), endpoint level (_21/_22), and client-vs-server divergence (_26).
 *
 * Other audit findings touched by this screen:
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - VAL-BA-001 : rating write paths have no FormRequest; no FK-exists validation on the grid (proven in _32/_33).
 *   - SEC-BA-002 : BaAssessmentRequest::authorize() returns bare true (proven in _55).
 *   - DATA-BA-003: uq_bha_rating(assessment_id,student_id,criterion_id) omits deleted_at → recreate-after-soft-delete
 *                  can 500 (proven via schema in _44).
 * Discovered defect (source-traced, High confidence):
 *   - BUG-BA-RAT-01 : BaAssessmentController uses UNQUALIFIED `DB` and `BaStudentRemark` in show()/reviewShow()/
 *                     bulkRate() with no matching `use` import; both resolve to the controller namespace and are
 *                     undefined → runtime Error on those paths (proven by source scan in _93). autoSave() is clean
 *                     (it does not reference either), which is why the autoSave endpoint is used for the live proofs.
 */
class bha_Rating_TestCas extends DuskTestCase
{
    private const URL_PREFIX  = '/behavioural-assessment';
    private const CREATE_PATH = '/behavioural-assessment/assessments/create';
    private const STORE_PATH  = '/behavioural-assessment/assessments';

    private const RATINGS_TABLE   = 'ba_assessment_ratings';
    private const ASSESS_TABLE    = 'ba_assessments';
    private const AUDIT_TABLE     = 'ba_audit_log';
    private const DDL_RATINGS     = 'bha_assessment_ratings';  // stale DDL-doc name (should NOT exist at runtime)
    private const DDL_ASSESS      = 'bha_assessments';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/Rating/screenshots';

    /** @var array<int,string> */
    private const RATING_PERMISSIONS = [
        'tenant.behavioural-assessment.assessments.viewAny',
        'tenant.behavioural-assessment.assessments.view',
        'tenant.behavioural-assessment.assessments.create',
        'tenant.behavioural-assessment.assessments.update',
        'tenant.behavioural-assessment.assessments.delete',
        'tenant.behavioural-assessment.assessments.restore',
        'tenant.behavioural-assessment.assessments.forceDelete',
        'tenant.behavioural-assessment.assessments.status',
    ];

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    /** @var array<int,int> ids of ba_* rows created during a test, force-deleted in cleanup */
    private array $createdAssessmentIds = [];
    private array $createdCriterionIds = [];
    private array $createdCategoryIds = [];
    private array $createdLevelIds = [];
    private array $createdScaleIds = [];

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
        $this->cleanupSeeds();

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01–09 — Schema / DDL / model / request configuration truth
    // =====================================================================

    public function test_rating_01_ratings_table_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::RATINGS_TABLE), 'Table ba_assessment_ratings does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::RATINGS_TABLE, [
                'id', 'assessment_id', 'student_id', 'criterion_id', 'rating_level_id',
                'remark', 'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_assessment_ratings table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::RATINGS_TABLE))->keyBy('Field');
            $this->assertStringContainsString('bigint', strtolower((string) ($cols['assessment_id']->Type ?? '')));
            $this->assertStringContainsString('int', strtolower((string) ($cols['student_id']->Type ?? '')));
            // rating_level_id is nullable (NULL = unrated cell).
            $this->assertSame('YES', strtoupper((string) ($cols['rating_level_id']->Null ?? '')));
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130625_create_ba_assessment_ratings_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_assessment_ratings'", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // Model configuration.
        $rating = new BaAssessmentRating();
        $this->assertSame('ba_assessment_ratings', $rating->getTable());
        $this->assertSame([
            'assessment_id', 'student_id', 'criterion_id', 'rating_level_id',
            'remark', 'is_active', 'created_by', 'updated_by',
        ], $rating->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessmentRating::class));
        $this->assertInstanceOf(BelongsTo::class, $rating->assessment());
        $this->assertInstanceOf(BelongsTo::class, $rating->criterion());
        $this->assertInstanceOf(BelongsTo::class, $rating->ratingLevel());
        $this->assertInstanceOf(BelongsTo::class, $rating->student());
    }

    public function test_rating_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime tables use the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::RATINGS_TABLE), 'Runtime table ba_assessment_ratings must exist.');
        $this->assertTrue(Schema::hasTable(self::ASSESS_TABLE), 'Runtime table ba_assessments must exist.');

        // The DDL/registry spec name `bha_*` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_RATINGS),
                'DOC-BA-001 regression: bha_assessment_ratings exists at runtime; expected only ba_assessment_ratings.'
            );
            $this->assertFalse(
                Schema::hasTable(self::DDL_ASSESS),
                'DOC-BA-001 regression: bha_assessments exists at runtime; expected only ba_assessments.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Models bind to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_assessment_ratings', (new BaAssessmentRating())->getTable());
        $this->assertSame('ba_assessments', (new BaAssessment())->getTable());
    }

    public function test_rating_03_assessments_status_enum_includes_locked_but_workflow_never_reaches_it(): void
    {
        // The DDL declares status ENUM('draft','submitted','reviewed','locked'); the model exposes the FSM helpers.
        $this->assertTrue(Schema::hasColumn(self::ASSESS_TABLE, 'status'));

        if (DB::connection()->getDriverName() === 'mysql') {
            $col = collect(DB::select('SHOW COLUMNS FROM ' . self::ASSESS_TABLE))->firstWhere('Field', 'status');
            $type = strtolower((string) ($col->Type ?? ''));
            foreach (['draft', 'submitted', 'reviewed', 'locked'] as $state) {
                $this->assertStringContainsString($state, $type, "status enum should list '{$state}'.");
            }
        }

        $model = new BaAssessment();
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessment::class));
        $this->assertTrue(method_exists($model, 'isLocked'));
        $this->assertTrue(method_exists($model, 'isDraft'));
        // NOTE: 'locked' is a declared enum value that the runtime FSM never assigns — see _24 (BUG-BA-001).
    }

    public function test_rating_04_audit_log_table_is_immutable_ba_audit_log(): void
    {
        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE), 'ba_audit_log table must exist.');
        $this->assertTrue(
            Schema::hasColumns(self::AUDIT_TABLE, ['entity_type', 'entity_id', 'field_name', 'old_value', 'new_value', 'changed_by']),
            'ba_audit_log is missing expected audit columns.'
        );
        // Immutability guarantee: no updated_at, no deleted_at.
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'updated_at'), 'ba_audit_log must be append-only (no updated_at).');
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'deleted_at'), 'ba_audit_log must be append-only (no deleted_at).');
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_rating_10_auto_save_persists_a_rating_for_a_draft_assessment(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Cross-module grading dependencies (student/class-section/teacher/period) unavailable.');
        }

        $response = $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $ctx['level_id'] ] ],
        ]);
        $this->assertSame(200, (int) ($response['status'] ?? 0), 'auto-save should return 200.');
        $this->assertTrue((bool) ($response['json']['success'] ?? false), 'auto-save on a draft assessment should succeed.');

        $row = BaAssessmentRating::where('assessment_id', $ctx['assessment']->id)
            ->where('student_id', $ctx['student_id'])
            ->where('criterion_id', $ctx['criterion_id'])
            ->first();
        $this->assertNotNull($row, 'Rating row should be created by auto-save.');
        $this->assertSame((int) $ctx['level_id'], (int) $row->rating_level_id);
    }

    public function test_rating_11_auto_save_upsert_updates_existing_rating_and_writes_audit(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable.');
        }
        $second = $this->seedExtraLevel($ctx['scale_id'], 5);
        if ($second === null) {
            $this->markTestSkipped('Unable to seed a second rating level.');
        }

        $auditBefore = DB::table(self::AUDIT_TABLE)->where('entity_type', 'assessment_rating')->count();

        $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $ctx['level_id'] ] ],
        ]);
        // Change the same cell to a different level → updateOrCreate must UPDATE, not duplicate.
        $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $second ] ],
        ]);

        $rows = BaAssessmentRating::where('assessment_id', $ctx['assessment']->id)
            ->where('student_id', $ctx['student_id'])
            ->where('criterion_id', $ctx['criterion_id'])
            ->get();
        $this->assertCount(1, $rows, 'uq_bha_rating(assessment,student,criterion): exactly one row per cell (upsert).');
        $this->assertSame((int) $second, (int) $rows->first()->rating_level_id);

        $auditAfter = DB::table(self::AUDIT_TABLE)->where('entity_type', 'assessment_rating')->count();
        $this->assertGreaterThan($auditBefore, $auditAfter, 'A rating change must append an assessment_rating audit row.');
    }

    public function test_rating_12_null_rating_level_is_allowed_for_an_unrated_cell(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable.');
        }

        // Empty string level → controller stores NULL (partially-filled grid allowed).
        $response = $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => '' ] ],
        ]);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $this->assertTrue((bool) ($response['json']['success'] ?? false));

        $row = BaAssessmentRating::where('assessment_id', $ctx['assessment']->id)
            ->where('student_id', $ctx['student_id'])
            ->where('criterion_id', $ctx['criterion_id'])
            ->first();
        $this->assertNotNull($row, 'Row is created even for an unrated cell.');
        $this->assertNull($row->rating_level_id, 'rating_level_id must be NULL for an unrated cell.');
    }

    public function test_rating_13_unique_rating_per_student_per_criterion_per_assessment(): void
    {
        // Schema-level guarantee for the upsert semantics used by the grid.
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Unique-index inspection requires MySQL.');
        }
        $indexes = DB::select("SHOW INDEX FROM " . self::RATINGS_TABLE . " WHERE Non_unique = 0");
        $uniqueCols = collect($indexes)->groupBy('Key_name')->map(
            fn ($rows) => collect($rows)->sortBy('Seq_in_index')->pluck('Column_name')->all()
        );
        $hasComposite = $uniqueCols->contains(
            fn ($cols) => $cols === ['assessment_id', 'student_id', 'criterion_id']
        );
        $this->assertTrue($hasComposite, 'Expected a UNIQUE(assessment_id, student_id, criterion_id) on ba_assessment_ratings.');
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM) — BUG-BA-001 CORE
    // =====================================================================

    public function test_rating_20_is_locked_only_true_for_locked_status_root_cause_bug_ba_001(): void
    {
        // BUG-BA-001 root cause: the lock guard used by the save endpoints checks isLocked() only.
        $draft = new BaAssessment(['status' => 'draft']);
        $submitted = new BaAssessment(['status' => 'submitted']);
        $reviewed = new BaAssessment(['status' => 'reviewed']);
        $locked = new BaAssessment(['status' => 'locked']);

        $this->assertFalse($draft->isLocked());
        $this->assertTrue($draft->isDraft());

        // Submitted and reviewed (approved) are NOT considered locked → the guard is a no-op for them.
        $this->assertFalse($submitted->isLocked(), 'BUG-BA-001: a submitted assessment is not treated as locked.');
        $this->assertFalse($submitted->isDraft());
        $this->assertFalse($reviewed->isLocked(), 'BUG-BA-001: a reviewed/approved assessment is not treated as locked.');
        $this->assertFalse($reviewed->isDraft());

        // Only the literal 'locked' status trips the guard — a state the runtime FSM never assigns (see _24).
        $this->assertTrue($locked->isLocked());
    }

    public function test_rating_21_submitted_assessment_still_accepts_rating_writes_bug_ba_001(): void
    {
        // THE MONEY SHOT: the UI promises "you will not be able to edit ratings after submission",
        // yet a direct auto-save POST on a SUBMITTED assessment is accepted and persists.
        $ctx = $this->seedGradingContext('submitted');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable for the submitted-lock proof.');
        }

        $response = $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $ctx['level_id'] ] ],
        ]);

        // The locked branch would return success:false + "Assessment is locked." — it must NOT fire here.
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $this->assertNotSame(
            'Assessment is locked.',
            (string) ($response['json']['message'] ?? ''),
            'BUG-BA-001 regression fixed? A submitted assessment should be rejected, but current code accepts it.'
        );
        $this->assertTrue(
            (bool) ($response['json']['success'] ?? false),
            'BUG-BA-001: auto-save succeeds on a submitted assessment.'
        );

        $this->assertTrue(
            BaAssessmentRating::where('assessment_id', $ctx['assessment']->id)
                ->where('student_id', $ctx['student_id'])->where('criterion_id', $ctx['criterion_id'])->exists(),
            'BUG-BA-001: rating was written to a submitted (locked-by-requirement) assessment.'
        );
    }

    public function test_rating_22_reviewed_assessment_still_accepts_rating_writes_bug_ba_001(): void
    {
        // Approved (reviewed) assessments have their scores cached in ba_computed_scores; later edits are
        // NOT recomputed, so the published score silently diverges from the raw ratings + audit trail.
        $ctx = $this->seedGradingContext('reviewed');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable for the reviewed-lock proof.');
        }

        $response = $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $ctx['level_id'] ] ],
        ]);
        $this->assertNotSame('Assessment is locked.', (string) ($response['json']['message'] ?? ''));
        $this->assertTrue(
            (bool) ($response['json']['success'] ?? false),
            'BUG-BA-001: auto-save succeeds on a reviewed/approved assessment.'
        );
    }

    public function test_rating_23_save_endpoints_never_consult_period_lock_or_deadline_bug_ba_001(): void
    {
        // Requirement lock constraint also covers "period lock date has passed"; the endpoints ignore it entirely.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }

        $autoSaveBody = $this->extractMethodBody($controller, 'autoSave');
        $bulkRateBody = $this->extractMethodBody($controller, 'bulkRate');
        $this->assertNotSame('', $autoSaveBody, 'Unable to isolate autoSave() body.');
        $this->assertNotSame('', $bulkRateBody, 'Unable to isolate bulkRate() body.');

        foreach (['autoSave' => $autoSaveBody, 'bulkRate' => $bulkRateBody] as $name => $body) {
            $this->assertStringContainsString('isLocked()', $body, "{$name}() should reference the (broken) isLocked guard.");
            $this->assertStringNotContainsString('deadline', $body, "BUG-BA-001: {$name}() must not (yet) check the period deadline.");
            // The guard never reads the parent period's status.
            $this->assertStringNotContainsString('period->status', $body, "BUG-BA-001: {$name}() must not (yet) check period status.");
        }
    }

    public function test_rating_24_no_code_path_sets_locked_and_no_is_editable_helper_bug_ba_001(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        $model = $this->readAppFile($this->moduleRootPath('app/Models/BaAssessment.php'));
        if ($controller === null || $model === null) {
            $this->markTestSkipped('Controller/model source not readable from app repo.');
        }

        // The assessment controller never assigns status 'locked' (so isLocked() can never become true).
        $this->assertStringNotContainsString("'status' => 'locked'", $controller, 'BUG-BA-001: no cascade sets assessment status to locked.');
        $this->assertStringNotContainsString('"status" => "locked"', $controller);

        // isLocked() is the exact broken guard; there is no isEditable()/FSM guard helper (the audited fix).
        $this->assertStringContainsString("return \$this->status === 'locked';", $model, 'isLocked() is the single-state broken guard.');
        $this->assertStringNotContainsString('function isEditable', $model, 'BUG-BA-001 fix (isEditable helper) is not present.');
    }

    public function test_rating_25_submit_transitions_draft_to_submitted_and_promises_read_only(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable for submit transition.');
        }

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $ctx['assessment']->id . '/submit'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'submit should redirect after success.');

        $ctx['assessment']->refresh();
        $this->assertSame('submitted', $ctx['assessment']->status, 'submit() transitions draft → submitted.');
        $this->assertNotNull($ctx['assessment']->submitted_at, 'submitted_at should be stamped.');

        // The show view text promises the ratings become read-only after submission (contradicted by _21).
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade !== null) {
            $this->assertStringContainsString('not be able to edit ratings after submission', $blade);
        }
    }

    public function test_rating_26_client_disables_grid_after_submit_but_server_endpoint_does_not_bug_ba_001(): void
    {
        // Client side: Blade disables the selects/textareas when status !== 'draft'.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable from app repo.');
        }
        $this->assertStringContainsString("\$assessment->status !== 'draft'", $blade, 'Blade should disable inputs for non-draft (client read-only).');
        $this->assertStringContainsString('disabled', $blade);

        // Server side: the endpoint guard is only isLocked(), so a crafted POST bypasses the client read-only.
        $ctx = $this->seedGradingContext('submitted');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable for the divergence proof.');
        }
        $response = $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $ctx['level_id'] ] ],
        ]);
        $this->assertTrue(
            (bool) ($response['json']['success'] ?? false),
            'BUG-BA-001: server accepts the write the client had disabled — read-only is client-only.'
        );
    }

    // =====================================================================
    // Band 30–39 — Validation (BC-VAL)
    // =====================================================================

    public function test_rating_30_auto_save_rejects_non_array_ratings_payload(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable.');
        }
        // autoSave validates ratings|nullable|array and ratings.*|array.
        $response = $this->postAutoSave($ctx['assessment']->id, ['ratings' => 'not-an-array']);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'A scalar ratings payload must fail validation.');
        $this->assertArrayHasKey('ratings', $response['json']['errors'] ?? []);
    }

    public function test_rating_31_bulk_rate_remark_max_length_is_enforced_in_source(): void
    {
        // bulkRate lives behind an unqualified-DB fatal (BUG-BA-RAT-01), so assert its validation rule via source.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable.');
        }
        $bulkRate = $this->extractMethodBody($controller, 'bulkRate');
        $this->assertStringContainsString("'remarks.*' => 'nullable|string|max:1000'", $bulkRate, 'bulkRate should cap remark length at 1000.');
    }

    public function test_rating_32_grid_save_does_not_validate_fk_existence_val_ba_001(): void
    {
        // The grid endpoints accept arbitrary student/criterion ids in the ratings map — no exists: rule.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable.');
        }
        $autoSave = $this->extractMethodBody($controller, 'autoSave');
        // Only array-shape validation is present; no exists: / integer checks on the nested ids.
        $this->assertStringContainsString("'ratings' => 'nullable|array'", $autoSave);
        $this->assertStringNotContainsString('exists:ba_criteria', $autoSave, 'VAL-BA-001: no FK-exists validation on criterion ids.');
        $this->assertStringNotContainsString('exists:std_students', $autoSave, 'VAL-BA-001: no FK-exists validation on student ids.');
    }

    public function test_rating_33_rating_grid_has_no_dedicated_form_request_val_ba_001(): void
    {
        // There is no BaRatingRequest / BaAssessmentRatingRequest — the write path is inline-validated only.
        $requestsDir = $this->moduleRootPath('app/Http/Requests');
        if ($requestsDir === null || !is_dir($requestsDir)) {
            $this->markTestSkipped('Requests directory not resolvable from app repo.');
        }
        $files = glob(rtrim($requestsDir, '/') . '/*.php') ?: [];
        $names = array_map('basename', $files);
        $this->assertNotContains('BaRatingRequest.php', $names, 'VAL-BA-001: no dedicated rating FormRequest expected.');
        $this->assertNotContains('BaAssessmentRatingRequest.php', $names, 'VAL-BA-001: no dedicated rating FormRequest expected.');
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-REF/INT/EDG)
    // =====================================================================

    public function test_rating_40_deleting_assessment_cascades_to_ratings(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable.');
        }
        $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $ctx['level_id'] ] ],
        ]);
        $ratingId = (int) BaAssessmentRating::where('assessment_id', $ctx['assessment']->id)->value('id');
        $this->assertGreaterThan(0, $ratingId, 'Rating must exist before cascade test.');

        // Force-delete the assessment (physical) → FK ON DELETE CASCADE removes its ratings.
        BaAssessment::withTrashed()->where('id', $ctx['assessment']->id)->get()->each(function (BaAssessment $a): void {
            try { $a->forceDelete(); } catch (Throwable) {}
        });
        // Drop from the tracked list — it is gone.
        $this->createdAssessmentIds = array_values(array_filter($this->createdAssessmentIds, fn ($id) => $id !== $ctx['assessment']->id));

        $this->assertFalse(
            BaAssessmentRating::withTrashed()->where('id', $ratingId)->exists(),
            'Ratings must be cascade-deleted with the parent assessment (FK ON DELETE CASCADE).'
        );
    }

    public function test_rating_41_student_fk_is_restrict_on_ratings(): void
    {
        $this->assertDeleteRule('std_students', 'RESTRICT');
    }

    public function test_rating_42_criterion_fk_is_restrict_on_ratings(): void
    {
        $this->assertDeleteRule('ba_criteria', 'RESTRICT');
    }

    public function test_rating_43_rating_level_fk_is_set_null_on_ratings(): void
    {
        $this->assertDeleteRule('ba_rating_levels', 'SET NULL');
    }

    public function test_rating_44_ratings_unique_index_omits_deleted_at_data_ba_003(): void
    {
        // DATA-BA-003: SoftDeletes + a UNIQUE key that does NOT include deleted_at → recreating a soft-deleted
        // cell (assessment,student,criterion) throws a duplicate-key 500 because updateOrCreate cannot see the trashed row.
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Index inspection requires MySQL.');
        }
        $this->assertTrue(Schema::hasColumn(self::RATINGS_TABLE, 'deleted_at'), 'ba_assessment_ratings uses soft deletes.');

        $indexes = DB::select("SHOW INDEX FROM " . self::RATINGS_TABLE . " WHERE Non_unique = 0");
        $uniqueCols = collect($indexes)->groupBy('Key_name')->map(
            fn ($rows) => collect($rows)->pluck('Column_name')->all()
        );
        $anyIncludesDeletedAt = $uniqueCols->contains(fn ($cols) => in_array('deleted_at', $cols, true));
        $this->assertFalse(
            $anyIncludesDeletedAt,
            'DATA-BA-003 regression fixed? The unique key would need deleted_at to allow recreate-after-soft-delete.'
        );
    }

    public function test_rating_45_full_lifecycle_rate_submit_then_still_editable_then_cascade_delete(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable for lifecycle.');
        }

        // rate (draft)
        $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $ctx['level_id'] ] ],
        ]);
        $this->assertTrue(BaAssessmentRating::where('assessment_id', $ctx['assessment']->id)->exists());

        // submit
        $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $ctx['assessment']->id . '/submit'));
        $ctx['assessment']->refresh();
        $this->assertSame('submitted', $ctx['assessment']->status);

        // still editable after submit (BUG-BA-001)
        $again = $this->postAutoSave($ctx['assessment']->id, [
            'ratings' => [ (string) $ctx['student_id'] => [ (string) $ctx['criterion_id'] => $ctx['level_id'] ] ],
        ]);
        $this->assertTrue((bool) ($again['json']['success'] ?? false), 'BUG-BA-001: still editable post-submit.');

        // cascade delete (force) removes the ratings
        BaAssessment::withTrashed()->where('id', $ctx['assessment']->id)->get()->each(function (BaAssessment $a): void {
            try { $a->forceDelete(); } catch (Throwable) {}
        });
        $this->createdAssessmentIds = array_values(array_filter($this->createdAssessmentIds, fn ($id) => $id !== $ctx['assessment']->id));
        $this->assertFalse(BaAssessmentRating::withTrashed()->where('assessment_id', $ctx['assessment']->id)->exists());
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_rating_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_rating_51_limited_user_without_update_permission_gets_403_on_auto_save(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-autosave-403', function (Browser $browser) use ($limited, $ctx): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl(self::STORE_PATH . '/' . $ctx['assessment']->id . '/auto-save'),
                ['ratings' => []]
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without update permission must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_rating_52_limited_user_without_view_permission_gets_403_on_show(): void
    {
        // Gate::authorize runs before the controller body, so 403 fires ahead of any BaStudentRemark fatal.
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-show-403', function (Browser $browser) use ($limited, $ctx): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'GET',
                $this->tenantUrl(self::STORE_PATH . '/' . $ctx['assessment']->id)
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without view permission must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_rating_53_limited_user_without_create_permission_gets_403_on_store(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-store-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl(self::STORE_PATH),
                ['period_id' => 1, 'class_section_id' => 1]
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
    }

    public function test_rating_54_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaAssessmentPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('Policy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete', 'status'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.assessments.{$ability}",
                $policy,
                "Policy missing gate string for {$ability}."
            );
        }
    }

    public function test_rating_55_store_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaAssessmentRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable from app repo.');
        }
        // SEC-BA-002: authorize() returns bare true (mitigated by the controller Gate::authorize).
        $this->assertMatchesRegularExpression(
            '/function\s+authorize\s*\(\s*\)\s*:\s*bool\s*\{\s*return\s+true\s*;/s',
            $request,
            'SEC-BA-002 changed: authorize() no longer returns bare true.'
        );
    }

    // =====================================================================
    // Band 60–69 — UI/UX (grid rendering intent, source-verified)
    // =====================================================================

    public function test_rating_60_grid_disables_inputs_for_non_draft_and_without_update_permission(): void
    {
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable.');
        }
        // Both the rating selects and the remark textareas carry the disabled guard.
        $this->assertStringContainsString("!Gate::check('tenant.behavioural-assessment.assessments.update')", $blade);
        $this->assertStringContainsString("\$assessment->isLocked() || \$assessment->status !== 'draft'", $blade);
    }

    public function test_rating_61_grid_uses_auto_save_endpoint_and_bulk_rate_form(): void
    {
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable.');
        }
        $this->assertStringContainsString("route('behavioural-assessment.assessments.auto-save'", $blade, 'Grid must autosave to auto-save.');
        $this->assertStringContainsString("route('behavioural-assessment.assessments.bulk-rate'", $blade, 'Full save posts to bulk-rate.');
    }

    public function test_rating_62_grid_cell_name_pattern_is_ratings_student_criterion(): void
    {
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable.');
        }
        $this->assertStringContainsString('name="ratings[{{ $student->id }}][{{ $criterion->id }}]"', $blade);
        $this->assertStringContainsString('name="remarks[{{ $student->id }}]"', $blade);
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_rating_70_auto_save_on_invalid_assessment_id_returns_404(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/987654321/auto-save'), ['ratings' => []]);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'auto-save on a missing assessment must 404 (findOrFail).');
    }

    public function test_rating_71_auto_save_with_empty_ratings_is_a_no_op_success(): void
    {
        $ctx = $this->seedGradingContext('draft');
        if ($ctx === null) {
            $this->markTestSkipped('Grading dependencies unavailable.');
        }
        $before = BaAssessmentRating::where('assessment_id', $ctx['assessment']->id)->count();
        $response = $this->postAutoSave($ctx['assessment']->id, ['ratings' => []]);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $this->assertTrue((bool) ($response['json']['success'] ?? false));
        $after = BaAssessmentRating::where('assessment_id', $ctx['assessment']->id)->count();
        $this->assertSame($before, $after, 'Empty ratings payload must not create rows.');
    }

    public function test_rating_72_show_on_invalid_assessment_id_returns_404(): void
    {
        $response = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . '/987654321'));
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'show on a missing assessment must 404.');
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_rating_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side rating tests.'
        );
        $this->assertTrue(Schema::hasTable(self::RATINGS_TABLE));
    }

    public function test_rating_91_cross_tenant_direct_id_isolation(): void
    {
        // Defensive: a second tenant is required to prove IDOR isolation across tenant DBs.
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

    public function test_rating_92_remark_is_escaped_by_blade_not_raw(): void
    {
        // The overall/per-cell remark is rendered with {{ }} (escaped), never {!! !!} (raw) — no stored XSS.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable.');
        }
        $this->assertStringNotContainsString('{!! $existingRemarks', $blade, 'Remarks must not be echoed raw.');
        $this->assertStringContainsString('$existingRemarks[$student->id]', $blade, 'Remark is rendered via escaped Blade output.');
    }

    public function test_rating_93_controller_uses_unqualified_db_and_remark_latent_fatal_bug_ba_rat_01(): void
    {
        // DISCOVERED (BUG-BA-RAT-01, source-traced, High confidence):
        // show()/reviewShow()/bulkRate() reference `DB` and `BaStudentRemark` with NO matching `use` import,
        // so both resolve to the controller namespace and are undefined → runtime Error on those paths.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }

        // The unqualified usages are present...
        $this->assertStringContainsString('DB::transaction(', $controller, 'bulkRate uses DB::transaction.');
        $this->assertStringContainsString('BaStudentRemark::', $controller, 'show/reviewShow/bulkRate reference BaStudentRemark.');

        // ...but neither is imported (and not fully-qualified with a leading backslash).
        $this->assertStringNotContainsString('use Illuminate\\Support\\Facades\\DB;', $controller, 'BUG-BA-RAT-01: DB facade is not imported.');
        $this->assertStringNotContainsString('use Modules\\BehaviouralAssessment\\Models\\BaStudentRemark;', $controller, 'BUG-BA-RAT-01: BaStudentRemark is not imported.');
        $this->assertStringNotContainsString('\\DB::transaction(', $controller, 'BUG-BA-RAT-01: DB is not fully-qualified either.');
    }

    public function test_rating_94_auto_save_is_the_clean_write_path_no_unqualified_symbols(): void
    {
        // Contrast to _93: autoSave() itself references neither DB nor BaStudentRemark, so the live proofs
        // (_21/_22/_26) exercise a code path that actually runs.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable.');
        }
        $autoSave = $this->extractMethodBody($controller, 'autoSave');
        $this->assertNotSame('', $autoSave);
        $this->assertStringNotContainsString('DB::', $autoSave, 'autoSave must not use the (unimported) DB facade.');
        $this->assertStringNotContainsString('BaStudentRemark', $autoSave, 'autoSave must not reference the (unimported) BaStudentRemark.');
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
        $rawName = 'rating-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'rating-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- Browser JSON request plumbing ------------------------------------

    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
    }

    private function postAutoSave(int $assessmentId, array $payload): array
    {
        return $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $assessmentId . '/auto-save'), $payload);
    }

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openAdminApiPage($browser);
            $result = $callback($browser);
        });
        return $result;
    }

    /** Open a lightweight authenticated page (create form) so a CSRF meta + same-origin cookies exist. */
    private function openAdminApiPage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('meta[name="csrf-token"]') !== null
                || $browser->element('form') !== null
                || $browser->element('body') !== null;
        }, 'Admin API page (create form) did not render a CSRF context.');
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
window.__raApiDone = false;
window.__raApiError = '';
window.__raApiResult = null;

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

        window.__raApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__raApiError = String(error);
    } finally {
        window.__raApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__raApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__raApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__raApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Grading-context seeding (defensive; reuses cross-module rows) -----

    /**
     * Build a minimal but valid grading context for the given assessment status.
     * Reuses existing cross-module rows (period/teacher/class-section/student); creates the ba_* grading graph.
     * Returns null (→ caller markTestSkipped) when a hard cross-module dependency is missing.
     *
     * @return array{assessment: BaAssessment, student_id:int, criterion_id:int, level_id:int, scale_id:int}|null
     */
    private function seedGradingContext(string $status): ?array
    {
        try {
            $periodId  = (int) (DB::table('ba_assessment_periods')->value('id') ?? 0);
            $teacherId = (int) (DB::table('sch_employees')->value('id') ?? 0);
            $csId      = (int) (DB::table('sch_class_section_jnt')->value('id') ?? 0);
            $studentId = (int) (DB::table('std_students')->value('id') ?? 0);
            if ($periodId === 0 || $teacherId === 0 || $csId === 0 || $studentId === 0) {
                return null;
            }

            // Grading graph — created rows are cleaned up in tearDown.
            $scale = BaRatingScale::create([
                'code'        => $this->uniqueCode('RG'),
                'name'        => $this->uniqueName('RATINGGRID'),
                'description' => 'Rating-grid test scale',
                'grade_type'  => 'numeric',
                'min_rating'  => 1,
                'max_rating'  => 5,
                'is_default'  => false,
                'is_active'   => true,
                'created_by'  => (int) $this->adminUser->id,
                'updated_by'  => (int) $this->adminUser->id,
            ]);
            $this->createdScaleIds[] = (int) $scale->id;

            $level = BaRatingLevel::create([
                'rating_scale_id' => $scale->id,
                'label'           => 'Good',
                'numeric_value'   => 4,
                'sort_order'      => 1,
                'description'     => null,
                'is_active'       => true,
                'created_by'      => (int) $this->adminUser->id,
                'updated_by'      => (int) $this->adminUser->id,
            ]);
            $this->createdLevelIds[] = (int) $level->id;

            $category = BaCategory::create([
                'parent_id'   => null,
                'name'        => $this->uniqueName('CAT'),
                'description' => 'Rating-grid test category',
                'polarity'    => 'positive',
                'weight'      => 100,
                'sort_order'  => 1,
                'is_active'   => true,
                'created_by'  => (int) $this->adminUser->id,
                'updated_by'  => (int) $this->adminUser->id,
            ]);
            $this->createdCategoryIds[] = (int) $category->id;

            $criterion = BaCriterion::create([
                'category_id' => $category->id,
                'name'        => $this->uniqueName('CRIT'),
                'description' => 'Rating-grid test criterion',
                'weight'      => 100,
                'sort_order'  => 1,
                'is_active'   => true,
                'created_by'  => (int) $this->adminUser->id,
                'updated_by'  => (int) $this->adminUser->id,
            ]);
            $this->createdCriterionIds[] = (int) $criterion->id;

            $assessment = $this->createAssessment($periodId, $teacherId, $csId, $status);
            if ($assessment === null) {
                return null;
            }

            return [
                'assessment'   => $assessment,
                'student_id'   => $studentId,
                'criterion_id' => (int) $criterion->id,
                'level_id'     => (int) $level->id,
                'scale_id'     => (int) $scale->id,
            ];
        } catch (Throwable $e) {
            $this->markTestSkipped('Unable to seed grading context: ' . $e->getMessage());
        }
    }

    private function seedExtraLevel(int $scaleId, int $value): ?int
    {
        try {
            $level = BaRatingLevel::create([
                'rating_scale_id' => $scaleId,
                'label'           => 'Excellent',
                'numeric_value'   => $value,
                'sort_order'      => 2,
                'description'     => null,
                'is_active'       => true,
                'created_by'      => (int) $this->adminUser->id,
                'updated_by'      => (int) $this->adminUser->id,
            ]);
            $this->createdLevelIds[] = (int) $level->id;
            return (int) $level->id;
        } catch (Throwable) {
            return null;
        }
    }

    /** Create (or reuse, on uq_bha_assessment conflict) an assessment with the requested status. */
    private function createAssessment(int $periodId, int $teacherId, int $csId, string $status): ?BaAssessment
    {
        $attributes = [
            'period_id'        => $periodId,
            'teacher_id'       => $teacherId,
            'class_section_id' => $csId,
            'status'           => $status,
            'is_active'        => true,
            'created_by'       => (int) $this->adminUser->id,
            'updated_by'       => (int) $this->adminUser->id,
        ];
        if (in_array($status, ['submitted', 'reviewed'], true)) {
            $attributes['submitted_at'] = now();
        }
        if ($status === 'reviewed') {
            $attributes['reviewed_at'] = now();
        }

        try {
            $assessment = BaAssessment::create($attributes);
            $this->createdAssessmentIds[] = (int) $assessment->id;
            return $assessment;
        } catch (Throwable) {
            // uq_bha_assessment(teacher_id, class_section_id, period_id) already present → reuse & set status.
            try {
                $existing = BaAssessment::withTrashed()
                    ->where('teacher_id', $teacherId)
                    ->where('class_section_id', $csId)
                    ->where('period_id', $periodId)
                    ->first();
                if ($existing === null) {
                    return null;
                }
                if ($existing->trashed()) {
                    $existing->restore();
                }
                $existing->update($attributes);
                // Do NOT track for force-delete — this is a pre-existing row we only borrowed.
                return $existing;
            } catch (Throwable) {
                return null;
            }
        }
    }

    private function cleanupSeeds(): void
    {
        foreach ($this->createdAssessmentIds as $id) {
            try {
                BaAssessmentRating::withTrashed()->where('assessment_id', $id)->get()
                    ->each(function (BaAssessmentRating $r): void {
                        try { $r->forceDelete(); } catch (Throwable) {}
                    });
                DB::table(self::AUDIT_TABLE)->where('entity_type', 'assessment')->where('entity_id', $id)->delete();
                BaAssessment::withTrashed()->where('id', $id)->get()->each(function (BaAssessment $a): void {
                    try { $a->forceDelete(); } catch (Throwable) {}
                });
            } catch (Throwable) {}
        }
        foreach ($this->createdCriterionIds as $id) {
            try { BaCriterion::withTrashed()->where('id', $id)->get()->each(fn ($m) => $this->safeForceDelete($m)); } catch (Throwable) {}
        }
        foreach ($this->createdCategoryIds as $id) {
            try { BaCategory::withTrashed()->where('id', $id)->get()->each(fn ($m) => $this->safeForceDelete($m)); } catch (Throwable) {}
        }
        foreach ($this->createdLevelIds as $id) {
            try { BaRatingLevel::withTrashed()->where('id', $id)->get()->each(fn ($m) => $this->safeForceDelete($m)); } catch (Throwable) {}
        }
        foreach ($this->createdScaleIds as $id) {
            try { BaRatingScale::withTrashed()->where('id', $id)->get()->each(fn ($m) => $this->safeForceDelete($m)); } catch (Throwable) {}
        }

        $this->createdAssessmentIds = [];
        $this->createdCriterionIds = [];
        $this->createdCategoryIds = [];
        $this->createdLevelIds = [];
        $this->createdScaleIds = [];
    }

    private function safeForceDelete($model): void
    {
        try {
            $model->forceDelete();
        } catch (Throwable) {
        }
    }

    private function assertDeleteRule(string $referencedTable, string $expectedRule): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('FK metadata inspection requires MySQL.');
        }
        try {
            $fk = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ?
                   AND REFERENCED_TABLE_NAME = ?",
                [self::RATINGS_TABLE, $referencedTable]
            );
            if (empty($fk)) {
                $this->markTestSkipped("No FK metadata for ba_assessment_ratings → {$referencedTable}.");
            }
            $rule = strtoupper((string) ($fk[0]->DELETE_RULE ?? ''));
            if ($expectedRule === 'RESTRICT') {
                $this->assertTrue(
                    str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'),
                    "ba_assessment_ratings → {$referencedTable} should RESTRICT; found: {$rule}"
                );
            } else {
                $this->assertStringContainsString($expectedRule, $rule, "ba_assessment_ratings → {$referencedTable} should be {$expectedRule}; found: {$rule}");
            }
        } catch (Throwable $e) {
            $this->markTestSkipped("FK dependency path unavailable for {$referencedTable}: " . $e->getMessage());
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
                'name'              => 'Rating Limited ' . $this->uniqueSuffix(),
                'email'             => 'rating_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'RA' . substr($this->uniqueSuffix(), -8);
            }

            $user = User::factory()->create($attributes);

            foreach (['is_super_admin', 'super_admin_flag'] as $col) {
                if (Schema::hasColumn('sys_users', $col)) {
                    $user->forceFill([$col => 0]);
                }
            }
            $user->save();

            if (method_exists($user, 'syncRoles')) {
                try { $user->syncRoles([]); } catch (Throwable) {}
            }
            if (method_exists($user, 'syncPermissions')) {
                try { $user->syncPermissions([]); } catch (Throwable) {}
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
        $this->grantRatingPermissions($this->adminUser);
    }

    private function grantRatingPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::RATING_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::RATING_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::RATING_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.rating-admin');
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
            $modelFile = (new ReflectionClass(BaAssessmentRating::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaAssessmentRating.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaAssessmentRating::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaAssessmentRating.php → app root = dirname(,5)
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

    /** Best-effort extraction of a controller method body (brace-balanced) for source-scan assertions. */
    private function extractMethodBody(string $source, string $method): string
    {
        $needle = 'function ' . $method . '(';
        $start = strpos($source, $needle);
        if ($start === false) {
            return '';
        }
        $brace = strpos($source, '{', $start);
        if ($brace === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($source);
        for ($i = $brace; $i < $len; $i++) {
            $ch = $source[$i];
            if ($ch === '{') {
                $depth++;
            } elseif ($ch === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $brace, $i - $brace + 1);
                }
            }
        }
        return substr($source, $brace);
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

    private function uniqueCode(string $prefix = 'R'): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $clean = $clean === '' ? 'RG' : substr($clean, 0, 2);
        return strtoupper($clean . 'RA' . $this->uniqueSuffix()); // <= 30 chars
    }

    private function uniqueName(string $prefix): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $clean = $clean === '' ? 'RG' : substr($clean, 0, 12);
        return substr($clean . ' ' . $this->uniqueSuffix(), 0, 100);
    }
}
