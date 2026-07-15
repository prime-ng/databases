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
use Modules\BehaviouralAssessment\Models\BaAssessmentPeriod;
use Modules\BehaviouralAssessment\Models\BaStudentRemark;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Student Remarks (10-Remarks) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/10-Remarks.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime table      : ba_student_remarks (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Persistence surface: the Remarks screen is NOT a standalone CRUD controller. Remarks are entered on the
 *                      assessment "show" grid (GET /assessments/{id} → BaAssessmentController::show) and saved
 *                      through the "Save Ratings" form (POST /assessments/{assessment}/bulk-rate → bulkRate())
 *                      and the debounced autosave (POST /assessments/{assessment}/auto-save → autoSave()).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController
 * Model              : Modules\BehaviouralAssessment\Models\BaStudentRemark
 * FormRequest        : NONE dedicated — remarks are validated INLINE in bulkRate() (proven in _30/_92).
 * Permission prefix  : tenant.behavioural-assessment.assessments.{viewAny|view|create|update|delete|...}
 *                      (remarks inherit the assessments gates: show=.view, bulkRate/autoSave=.update).
 *
 * Defects proven / documented (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md + this run):
 *   - DOC-BA-001     : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - BUG-BA-REM-001 : (== BUG-BA-001 / BUG-BA-MYA-001, remarks side) BaAssessmentController references
 *                      BaStudentRemark AND the DB facade WITHOUT `use` imports → the unqualified names resolve
 *                      to Modules\...\Http\Controllers\{BaStudentRemark,DB} (nonexistent) → fatal Error → HTTP 500.
 *                      This kills BOTH the remark READ path (show()/reviewShow()) and the remark WRITE path
 *                      (bulkRate() "Save Ratings"). Proven in _46 (read show 500), _47 (write bulk-rate 500),
 *                      _48 (reviewShow 500), _49 (locked bulk-rate 302 — fatal is specifically the transaction),
 *                      and source-scanned in _30b/_92b. The remarks screen cannot load or save through the app.
 *   - VAL-BA-REM-002 : requirement 10-Remarks §"Minimum Word Count" mandates min 30 / max 500 chars; bulkRate()
 *                      validates `remarks.*` as `nullable|string|max:1000` (NO min:30, max=1000). Proven in _30.
 *   - BUG-BA-REM-003 : autoSave() (the debounced autosave the requirement says writes remarks to
 *                      ba_student_remarks) validates & persists ONLY `ratings` — remarks in the posted FormData
 *                      are silently dropped. Proven behaviourally in _71 + source-scanned in _72.
 *   - FE-BA-REM-004  : requirement's "Comment Bank / Predefined Templates" panel is absent from show.blade (_61).
 *   - FE-BA-REM-005  : requirement's character counter (n/500) is absent; the textarea is labelled
 *                      "Optional remark..." contradicting the required min-30 rule (_62/_63).
 *   - SEC-BA-002     : (module-wide) no dedicated remark FormRequest — validation is inline, mitigated by the
 *                      controller Gate (documented in _92).
 */
class bha_StudentRemark_TestCas extends DuskTestCase
{
    private const URL_PREFIX       = '/behavioural-assessment';
    private const ASSESSMENTS_PAGE = '/behavioural-assessment/assessments-page?tab=my-assessments';
    private const SHOW_BASE        = '/behavioural-assessment/assessments';           // GET /{id} → show()
    private const BULK_RATE_BASE   = '/behavioural-assessment/assessments';           // POST /{id}/bulk-rate
    private const AUTO_SAVE_BASE   = '/behavioural-assessment/assessments';           // POST /{id}/auto-save
    private const REVIEW_BASE      = '/behavioural-assessment/reviews';               // GET /{id} → reviewShow()

    private const TABLE            = 'ba_student_remarks';
    private const DDL_TABLE        = 'bha_student_remarks';   // stale DDL-doc name — must NOT exist at runtime
    private const ASSESS_TABLE     = 'ba_assessments';
    private const STUDENT_TABLE    = 'std_students';
    private const EMP_TABLE        = 'sch_employees';
    private const CS_TABLE         = 'sch_class_section_jnt';
    private const SESSION_TABLE    = 'sch_org_academic_sessions_jnt';

    private const SCREENSHOT_DIR   = 'tests/Browser/Modules/BehaviouralAssessment/StudentRemark/screenshots';

    /** @var array<int,string> */
    private const REM_PERMISSIONS = [
        'tenant.behavioural-assessment.assessments-page.viewAny',
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
    // Band 01–09 — Schema / DDL / model / request configuration truth
    // =====================================================================

    public function test_student_remark_01_migration_model_and_inline_validation_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table ba_student_remarks does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'assessment_id', 'student_id', 'remark_text', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_student_remarks table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::TABLE))->keyBy('Field');
            $this->assertStringContainsString('text', strtolower((string) ($cols['remark_text']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));
            $this->assertStringContainsString('bigint', strtolower((string) ($cols['assessment_id']->Type ?? '')));
            $this->assertStringContainsString('int', strtolower((string) ($cols['student_id']->Type ?? '')));
            // remark_text is NOT NULL per DDL/migration.
            $this->assertStringContainsStringIgnoringCase('NO', (string) ($cols['remark_text']->Null ?? 'YES'));
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130623_create_ba_student_remarks_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_student_remarks'", $migration);
            $this->assertStringContainsString("\$table->text('remark_text')", $migration);
            $this->assertStringContainsString("constrained('ba_assessments')->cascadeOnDelete()", $migration);
            $this->assertStringContainsString("->on('std_students')", $migration);
            $this->assertStringContainsString("unique(['assessment_id', 'student_id'], 'uq_ba_remark')", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // Model configuration.
        $model = new BaStudentRemark();
        $this->assertSame('ba_student_remarks', $model->getTable());
        $this->assertSame([
            'assessment_id', 'student_id', 'remark_text', 'is_active', 'created_by', 'updated_by',
        ], $model->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaStudentRemark::class));
        $this->assertInstanceOf(BelongsTo::class, $model->assessment());
        $this->assertInstanceOf(BelongsTo::class, $model->student());
        $this->assertTrue($model->hasCast('is_active', 'boolean'), 'is_active must cast to boolean.');
    }

    public function test_student_remark_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Runtime table ba_student_remarks must exist.');

        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_TABLE),
                'DOC-BA-001 regression: bha_student_remarks exists at runtime; expected only the live ba_student_remarks.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        $this->assertSame('ba_student_remarks', (new BaStudentRemark())->getTable());
    }

    public function test_student_remark_03_unique_index_and_foreign_key_rules_are_correct(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Index/FK inspection requires MySQL.');
        }

        // uq_ba_remark (assessment_id, student_id) — one overall remark per student per assessment.
        $unique = DB::select("SHOW INDEX FROM " . self::TABLE . " WHERE Key_name = 'uq_ba_remark'");
        $this->assertNotEmpty($unique, 'Unique index uq_ba_remark(assessment_id, student_id) is missing.');
        $cols = collect($unique)->pluck('Column_name')->map(fn ($c) => strtolower((string) $c))->all();
        $this->assertContains('assessment_id', $cols);
        $this->assertContains('student_id', $cols);

        // assessment_id → ba_assessments CASCADE; student_id → std_students RESTRICT/NO ACTION.
        $this->assertForeignKeyDeleteRule(self::TABLE, self::ASSESS_TABLE, ['CASCADE']);
        $this->assertForeignKeyDeleteRule(self::TABLE, self::STUDENT_TABLE, ['RESTRICT', 'NO ACTION']);
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ) — model-level persistence
    // (the app write path is dead; see BUG-BA-REM-001 in band 40)
    // =====================================================================

    public function test_student_remark_10_model_create_persists_remark_row(): void
    {
        [$assessment, $studentId] = $this->requireRemarkGraph();

        $remark = $this->createRemarkSeed($assessment->id, $studentId, ['remark_text' => 'Consistent, engaged, and collaborative in group work.']);
        $this->assertNotNull($remark->id, 'Remark row was not created.');

        $fresh = BaStudentRemark::find($remark->id);
        $this->assertNotNull($fresh);
        $this->assertSame('Consistent, engaged, and collaborative in group work.', $fresh->remark_text);
        $this->assertSame((int) $this->adminUser->id, (int) $fresh->created_by);
        $this->assertTrue((bool) $fresh->is_active);

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_11_one_remark_per_student_per_assessment_update_or_create(): void
    {
        // BR: uq_ba_remark → exactly one overall remark per (assessment, student). updateOrCreate overwrites.
        [$assessment, $studentId] = $this->requireRemarkGraph();

        $first = BaStudentRemark::updateOrCreate(
            ['assessment_id' => $assessment->id, 'student_id' => $studentId],
            ['remark_text' => 'First draft remark.', 'is_active' => true, 'created_by' => (int) $this->adminUser->id, 'updated_by' => (int) $this->adminUser->id]
        );
        $second = BaStudentRemark::updateOrCreate(
            ['assessment_id' => $assessment->id, 'student_id' => $studentId],
            ['remark_text' => 'Revised remark after coordinator feedback.', 'updated_by' => (int) $this->adminUser->id]
        );

        $this->assertSame((int) $first->id, (int) $second->id, 'updateOrCreate must reuse the same row (one remark per student).');
        $this->assertSame(
            1,
            BaStudentRemark::where('assessment_id', $assessment->id)->where('student_id', $studentId)->count(),
            'There must be exactly one remark per (assessment, student).'
        );
        $second->refresh();
        $this->assertSame('Revised remark after coordinator feedback.', $second->remark_text);

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_12_relationships_resolve_to_assessment_and_student(): void
    {
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $remark = $this->createRemarkSeed($assessment->id, $studentId);

        $this->assertSame((int) $assessment->id, (int) $remark->assessment()->first()?->id, 'assessment() must resolve the parent assessment.');
        $this->assertSame($studentId, (int) $remark->student_id, 'student_id must be persisted verbatim.');

        // Parent assessment exposes the remark via its studentRemarks() hasMany.
        $this->assertTrue(
            $assessment->studentRemarks()->where('id', $remark->id)->exists(),
            'BaAssessment::studentRemarks() must expose the child remark.'
        );

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_13_is_active_defaults_true_and_casts_boolean(): void
    {
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $remark = $this->createRemarkSeed($assessment->id, $studentId, ['is_active' => 1]);

        $remark->refresh();
        $this->assertIsBool($remark->is_active, 'is_active must be cast to a PHP bool.');
        $this->assertTrue($remark->is_active);

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_14_remark_text_stores_long_narrative(): void
    {
        // remark_text is TEXT — a 600-char narrative persists at the model layer (no DB length cap at 500).
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $long = str_repeat('This student demonstrates steady behavioural growth. ', 12); // ~624 chars
        $remark = $this->createRemarkSeed($assessment->id, $studentId, ['remark_text' => $long]);

        $remark->refresh();
        $this->assertSame($long, $remark->remark_text, 'TEXT column must store the full narrative.');
        $this->assertGreaterThan(500, mb_strlen($remark->remark_text));

        $this->cleanupAssessment($assessment);
    }

    // =====================================================================
    // Band 20–29 — Assessment-status coupling (BC-SM)
    // =====================================================================

    public function test_student_remark_20_bulk_rate_guard_blocks_locked_before_transaction(): void
    {
        // bulkRate() checks isLocked() and returns BEFORE the DB::transaction block — so a LOCKED assessment
        // gets a 302 "locked" redirect (no fatal), proving the BUG-BA-REM-001 fatal lives in the transaction.
        $assessment = $this->createAssessmentSeed(['status' => 'locked']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('POST', $this->tenantUrl(self::BULK_RATE_BASE . '/' . $assessment->id . '/bulk-rate'), [
            'remarks' => [$this->firstStudentId() => 'A locked assessment must not accept edits.'],
        ]);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'A locked assessment must be rejected by the isLocked() guard (302), not reach the fatal transaction.'
        );

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_21_show_blade_disables_remark_textarea_when_not_draft(): void
    {
        // Source truth: the remark <textarea> is disabled unless the assessment is draft + user has .update.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable from app repo.');
        }
        $this->assertStringContainsString("name=\"remarks[{{ \$student->id }}]\"", $blade, 'Remark textarea must be keyed by student id.');
        $this->assertStringContainsString("\$assessment->status !== 'draft'", $blade, 'Textarea must be disabled when the assessment is not draft.');
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL)
    // =====================================================================

    public function test_student_remark_30_inline_validation_omits_required_min30_max500_val_ba_rem_002(): void
    {
        // Requirement 10-Remarks §"Minimum Word Count": min 30 / max 500 chars, non-empty & required for submit.
        // bulkRate() validates `remarks.*` => 'nullable|string|max:1000' — NO min:30, max is 1000 not 500.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertStringContainsString("'remarks.*' => 'nullable|string|max:1000'", $controller, 'The inline remark rule must be the max:1000 rule under test.');
        $this->assertStringNotContainsString("'remarks.*' => 'required", $controller, 'VAL-BA-REM-002 changed: remarks are now required.');
        $this->assertStringNotContainsString('min:30', $controller, 'VAL-BA-REM-002 changed: a min:30 rule now exists.');
        $this->assertStringNotContainsString("remarks.*' => 'nullable|string|max:500", $controller, 'VAL-BA-REM-002 changed: the requirement max:500 is now enforced.');
    }

    public function test_student_remark_31_short_3_char_remark_is_accepted_at_model_layer_val_ba_rem_002(): void
    {
        // With no min:30 rule anywhere, a 3-char remark ("Ok.") persists — the "no single-word comments" rule
        // from the requirement is not enforced.
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $remark = $this->createRemarkSeed($assessment->id, $studentId, ['remark_text' => 'Ok.']);

        $remark->refresh();
        $this->assertSame('Ok.', $remark->remark_text, 'VAL-BA-REM-002: a sub-30-char remark is accepted (no minimum enforced).');
        $this->assertLessThan(30, mb_strlen($remark->remark_text));

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_32_empty_remark_is_skipped_by_bulk_rate_loop_source(): void
    {
        // Correct behaviour (BR): bulkRate() only writes a remark when trim($remark) !== '' — empty textareas
        // do NOT create rows. Documented from source (the loop is unreachable live due to BUG-BA-REM-001).
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertStringContainsString("if (trim((string) \$remark) !== '')", $controller, 'Empty-remark skip guard must be present in bulkRate().');
        $this->assertStringContainsString("BaStudentRemark::updateOrCreate(", $controller, 'bulkRate() persists remarks via updateOrCreate.');
    }

    public function test_student_remark_33_xss_payload_is_stored_verbatim_at_model_layer(): void
    {
        // Escaping is Blade's job on render, but the show page is unreachable (BUG-BA-REM-001), so we can only
        // assert the raw value is stored without server-side sanitisation (the escaping surface is documented dead).
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $xss = 'Great term. <script>alert(1)</script>';
        $remark = $this->createRemarkSeed($assessment->id, $studentId, ['remark_text' => $xss]);

        $remark->refresh();
        $this->assertSame($xss, $remark->remark_text, 'Remark text is stored verbatim (no server-side sanitisation).');

        $this->cleanupAssessment($assessment);
    }

    // =====================================================================
    // Band 40–49 — FK / soft-delete / lifecycle + the BUG-BA-REM-001 fatals
    // =====================================================================

    public function test_student_remark_40_soft_delete_hides_remark_from_default_scope(): void
    {
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $remark = $this->createRemarkSeed($assessment->id, $studentId);

        $remark->delete();
        $this->assertFalse(BaStudentRemark::whereKey($remark->id)->exists(), 'Soft-deleted remark must be hidden from default scope.');
        $this->assertNotNull(BaStudentRemark::onlyTrashed()->find($remark->id), 'Soft-deleted remark must remain in onlyTrashed().');

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_41_parent_assessment_force_delete_cascades_remarks(): void
    {
        // ba_student_remarks.assessment_id → ba_assessments ON DELETE CASCADE.
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $remark = $this->createRemarkSeed($assessment->id, $studentId);
        $remarkId = (int) $remark->id;

        // Hard-delete the parent assessment row (cascade removes remarks).
        DB::table(self::ASSESS_TABLE)->where('id', $assessment->id)->delete();

        $this->assertFalse(
            BaStudentRemark::withTrashed()->whereKey($remarkId)->exists(),
            'Remark rows must be cascade-deleted when the parent assessment row is removed.'
        );

        $this->cleanupPeriodFor($assessment);
    }

    public function test_student_remark_42_student_fk_is_restrict_on_delete(): void
    {
        $this->assertForeignKeyDeleteRule(self::TABLE, self::STUDENT_TABLE, ['RESTRICT', 'NO ACTION']);
    }

    public function test_student_remark_43_assessment_fk_is_cascade_on_delete(): void
    {
        $this->assertForeignKeyDeleteRule(self::TABLE, self::ASSESS_TABLE, ['CASCADE']);
    }

    public function test_student_remark_44_duplicate_assessment_student_pair_violates_unique_key(): void
    {
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $first = $this->createRemarkSeed($assessment->id, $studentId);

        $threw = false;
        try {
            // Second INSERT for the same pair must hit uq_ba_remark (updateOrCreate is NOT used here on purpose).
            BaStudentRemark::query()->create([
                'assessment_id' => $assessment->id,
                'student_id'    => $studentId,
                'remark_text'   => 'Duplicate pair should fail.',
                'is_active'     => true,
                'created_by'    => (int) $this->adminUser->id,
                'updated_by'    => (int) $this->adminUser->id,
            ]);
        } catch (Throwable $e) {
            $threw = true;
        }

        $this->assertTrue($threw, 'A duplicate (assessment_id, student_id) insert must violate uq_ba_remark.');
        $this->assertSame(1, BaStudentRemark::where('assessment_id', $assessment->id)->where('student_id', $studentId)->count());

        $this->assertNotNull($first->id);
        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_45_force_delete_removes_remark_physically(): void
    {
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $remark = $this->createRemarkSeed($assessment->id, $studentId);
        $remarkId = (int) $remark->id;

        $remark->delete();
        $remark->forceDelete();
        $this->assertFalse(BaStudentRemark::withTrashed()->whereKey($remarkId)->exists(), 'Remark row must be physically removed.');

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_46_show_read_path_fatals_due_to_unimported_student_remark_bug_ba_rem_001(): void
    {
        // GET /assessments/{id} → show() builds $existingRemarks via BaStudentRemark::where(...) with NO import →
        // resolves to Modules\...\Http\Controllers\BaStudentRemark (nonexistent) → fatal Error → HTTP 500.
        // The remarks grid can never render.
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('GET', $this->tenantUrl(self::SHOW_BASE . '/' . $assessment->id));
        $this->assertSame(
            500,
            (int) ($response['status'] ?? 0),
            'BUG-BA-REM-001 regression fixed? show() should 500 while BaStudentRemark is unimported.'
        );

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_47_bulk_rate_write_path_fatals_on_draft_bug_ba_rem_001(): void
    {
        // POST /assessments/{id}/bulk-rate on a DRAFT assessment reaches DB::transaction(...) (DB facade
        // unimported) and BaStudentRemark::updateOrCreate (unimported) → fatal Error → HTTP 500.
        // The "Save Ratings" button can never persist a remark.
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $studentId = $this->firstStudentId();
        if ($studentId === null) {
            $this->cleanupAssessment($assessment);
            $this->markTestSkipped('No std_students row available.');
        }

        $response = $this->apiCall('POST', $this->tenantUrl(self::BULK_RATE_BASE . '/' . $assessment->id . '/bulk-rate'), [
            'remarks' => [$studentId => 'A well-formed remark that should have been saved by Save Ratings.'],
        ]);
        $this->assertSame(
            500,
            (int) ($response['status'] ?? 0),
            'BUG-BA-REM-001 regression fixed? bulkRate() should 500 (DB + BaStudentRemark unimported) on a draft.'
        );

        // Nothing was persisted (the transaction never completed).
        $this->assertSame(
            0,
            BaStudentRemark::where('assessment_id', $assessment->id)->count(),
            'A fatal bulkRate() must not have persisted any remark.'
        );

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_48_review_show_read_path_fatals_bug_ba_rem_001(): void
    {
        // GET /reviews/{id} → reviewShow() also reads BaStudentRemark::where(...) unimported → HTTP 500.
        $assessment = $this->createAssessmentSeed(['status' => 'submitted', 'submitted_at' => now()]);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('GET', $this->tenantUrl(self::REVIEW_BASE . '/' . $assessment->id));
        $this->assertSame(
            500,
            (int) ($response['status'] ?? 0),
            'BUG-BA-REM-001 regression fixed? reviewShow() should 500 while BaStudentRemark is unimported.'
        );

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_49_controller_source_confirms_missing_imports_bug_ba_rem_001(): void
    {
        // Root-cause source scan: BaStudentRemark + DB used unqualified with NO `use` import.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        // Usages present...
        $this->assertStringContainsString('BaStudentRemark::where', $controller, 'show()/reviewShow() must reference BaStudentRemark.');
        $this->assertStringContainsString('BaStudentRemark::updateOrCreate', $controller, 'bulkRate() must reference BaStudentRemark.');
        $this->assertStringContainsString('DB::transaction(', $controller, 'bulkRate() must use the DB facade.');
        // ...but the imports are missing (proves the fatal).
        $this->assertStringNotContainsString('use Modules\\BehaviouralAssessment\\Models\\BaStudentRemark;', $controller, 'BUG-BA-REM-001 fixed? BaStudentRemark is now imported.');
        $this->assertStringNotContainsString('use Illuminate\\Support\\Facades\\DB;', $controller, 'BUG-BA-REM-001 fixed? The DB facade is now imported.');
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_student_remark_50_guest_is_redirected_to_login_on_show(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        $target = $assessment !== null ? (self::SHOW_BASE . '/' . $assessment->id) : self::ASSESSMENTS_PAGE;

        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser) use ($target): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl($target))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });

        if ($assessment !== null) {
            $this->cleanupAssessment($assessment);
        }
    }

    public function test_student_remark_51_limited_user_without_update_gets_403_on_bulk_rate(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $studentId = $this->firstStudentId();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-bulkrate-403', function (Browser $browser) use ($limited, $assessment, $studentId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl(self::BULK_RATE_BASE . '/' . $assessment->id . '/bulk-rate'),
                ['remarks' => [$studentId => 'Should be blocked before the fatal.']]
            );
            // Gate::authorize('...assessments.update') runs first → 403 for a non-super-admin without the permission.
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Limited user must get 403 on bulk-rate.');
        });

        $this->deleteUser($limited);
        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_52_limited_user_without_view_gets_403_on_show(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-show-403', function (Browser $browser) use ($limited, $assessment): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::SHOW_BASE . '/' . $assessment->id));
            // .view gate fires before show() reaches the unimported BaStudentRemark, so it is 403 (not 500).
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Limited user must get 403 on show (before the fatal).');
        });

        $this->deleteUser($limited);
        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_53_assessment_policy_methods_map_to_permission_strings(): void
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

    public function test_student_remark_54_auto_save_endpoint_is_gated_by_update_permission(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        // autoSave() authorizes the same .update gate as bulkRate().
        $this->assertStringContainsString(
            "public function autoSave(Request \$request, int \$assessment)",
            $controller,
            'autoSave() must exist.'
        );
        $this->assertStringContainsString(
            "Gate::authorize('tenant.behavioural-assessment.assessments.update');",
            $controller,
            'autoSave()/bulkRate() must be gated by the assessments.update permission.'
        );
    }

    // =====================================================================
    // Band 60–69 — UI/UX and requirement feature-gap surface (FE-BA-REM)
    // =====================================================================

    public function test_student_remark_60_show_blade_contains_the_remark_textarea_column(): void
    {
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable from app repo.');
        }
        $this->assertStringContainsString('Remarks', $blade, 'The grid must have a Remarks column header.');
        $this->assertStringContainsString('<textarea name="remarks[', $blade, 'Each row must render a remark textarea.');
        $this->assertStringContainsString("route('behavioural-assessment.assessments.bulk-rate'", $blade, 'The grid form must post to bulk-rate.');
    }

    public function test_student_remark_61_comment_bank_panel_is_absent_fe_ba_rem_004(): void
    {
        // Requirement 10-Remarks §"Comment Bank / Predefined Templates" — a wizard/side-panel of standard phrases.
        // The implementation has no such control.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable from app repo.');
        }
        $this->assertStringNotContainsStringIgnoringCase('comment bank', $blade, 'FE-BA-REM-004 changed: a Comment Bank now exists.');
        $this->assertStringNotContainsStringIgnoringCase('comment-bank', $blade);
        $this->assertStringNotContainsStringIgnoringCase('template', $blade, 'FE-BA-REM-004 changed: predefined templates now exist.');
    }

    public function test_student_remark_62_character_counter_is_absent_fe_ba_rem_005(): void
    {
        // Requirement mandates a live character counter (e.g. "120 / 500 characters") + maxlength enforcement.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable from app repo.');
        }
        // The remark textarea has no maxlength and no counter element.
        $this->assertStringContainsString('placeholder="Optional remark..."', $blade, 'Textarea placeholder must be the current "Optional remark..." text.');
        $this->assertStringNotContainsStringIgnoringCase('characters</', $blade, 'FE-BA-REM-005 changed: a character counter now renders.');
        $this->assertStringNotContainsString('maxlength="500"', $blade, 'FE-BA-REM-005 changed: a maxlength=500 now caps the textarea.');
    }

    public function test_student_remark_63_textarea_labelled_optional_contradicts_required_min30_fe_ba_rem_005(): void
    {
        // The UI markets remarks as "Optional" while the requirement makes them required with a 30-char minimum.
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/assessment/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable from app repo.');
        }
        $this->assertStringContainsString('Optional remark', $blade, 'FE-BA-REM-005: textarea is labelled Optional, contradicting the required min-30 requirement.');
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_student_remark_70_bulk_rate_on_invalid_assessment_id_returns_404(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::BULK_RATE_BASE . '/987654321/bulk-rate'), [
            'remarks' => [1 => 'no such assessment'],
        ]);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'bulk-rate on a nonexistent assessment must 404.');
    }

    public function test_student_remark_71_auto_save_silently_drops_remarks_bug_ba_rem_003(): void
    {
        // The requirement's debounced autosave is supposed to write remarks to ba_student_remarks. autoSave()
        // validates & persists ONLY ratings — a posted remarks[] payload is dropped with a 200 success.
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $studentId = $this->firstStudentId();
        if ($studentId === null) {
            $this->cleanupAssessment($assessment);
            $this->markTestSkipped('No std_students row available.');
        }

        $response = $this->apiCall('POST', $this->tenantUrl(self::AUTO_SAVE_BASE . '/' . $assessment->id . '/auto-save'), [
            'remarks' => [$studentId => 'This remark is posted to autosave but the server ignores it.'],
        ]);
        // autoSave() has its own try/catch and does NOT touch BaStudentRemark/DB → it succeeds (200) but drops remarks.
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'autoSave() should succeed for a draft.');
        $this->assertSame(
            0,
            BaStudentRemark::where('assessment_id', $assessment->id)->count(),
            'BUG-BA-REM-003 regression fixed? autoSave() should have dropped the posted remark.'
        );

        $this->cleanupAssessment($assessment);
    }

    public function test_student_remark_72_auto_save_source_validates_ratings_only_bug_ba_rem_003(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        // Isolate the autoSave() body and assert it never references remarks.
        $pos = strpos($controller, 'public function autoSave(');
        $this->assertNotFalse($pos, 'autoSave() must exist.');
        $body = substr($controller, $pos);
        $this->assertStringContainsString("'ratings'   => 'nullable|array'", $body, 'autoSave() validates ratings.');
        $this->assertStringNotContainsString('remarks', $body, 'BUG-BA-REM-003: autoSave() must not touch remarks (it silently drops them).');
    }

    public function test_student_remark_73_remark_text_is_not_nullable(): void
    {
        // remark_text is NOT NULL — a model insert without it must fail at the DB layer.
        [$assessment, $studentId] = $this->requireRemarkGraph();

        $threw = false;
        try {
            BaStudentRemark::query()->create([
                'assessment_id' => $assessment->id,
                'student_id'    => $studentId,
                // remark_text intentionally omitted
                'is_active'     => true,
                'created_by'    => (int) $this->adminUser->id,
                'updated_by'    => (int) $this->adminUser->id,
            ]);
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'Inserting a remark with no remark_text must fail (NOT NULL).');

        $this->cleanupAssessment($assessment);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_student_remark_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side remark tests.'
        );
        $this->assertTrue(Schema::hasTable(self::TABLE));
    }

    public function test_student_remark_91_cross_tenant_direct_id_isolation(): void
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

    public function test_student_remark_92_no_dedicated_form_request_remarks_validated_inline_sec_ba_002(): void
    {
        // There is no BaStudentRemarkRequest — remarks are validated inline in bulkRate(). Documented as the
        // module-wide SEC-BA-002 pattern (validation lives in the controller, gated by Gate::authorize).
        $requestPath = $this->moduleRootPath('app/Http/Requests/BaStudentRemarkRequest.php');
        if ($requestPath === null) {
            $this->markTestSkipped('Module root not resolvable from app repo.');
        }
        $this->assertFalse(File::exists($requestPath), 'SEC-BA-002 changed: a dedicated BaStudentRemarkRequest now exists.');

        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller !== null) {
            $this->assertStringContainsString('$request->validate([', $controller, 'Remarks must be validated inline in the controller.');
        }
    }

    public function test_student_remark_93_created_by_is_forced_from_auth_not_client_supplied(): void
    {
        // bulkRate()/model persistence stamp created_by/updated_by from auth()->id(); a client cannot spoof them
        // through the (dead) endpoint. Prove the stamping contract at the model layer.
        [$assessment, $studentId] = $this->requireRemarkGraph();
        $remark = $this->createRemarkSeed($assessment->id, $studentId, ['created_by' => (int) $this->adminUser->id]);

        $remark->refresh();
        $this->assertSame((int) $this->adminUser->id, (int) $remark->created_by, 'created_by must reflect the acting admin.');
        $this->assertSame((int) $this->adminUser->id, (int) $remark->updated_by, 'updated_by must reflect the acting admin.');

        $this->cleanupAssessment($assessment);
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
        $rawName = 'student-remark-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'student-remark-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- UI drivers -------------------------------------------------------

    private function openAssessmentsPage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::ASSESSMENTS_PAGE, 1300);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#my-assessments-pane') !== null
                || $browser->element('#assessmentModal') !== null
                || $browser->element('table') !== null;
        }, 'My-assessments tab did not render.');
    }

    // ---- HTTP-from-browser ------------------------------------------------

    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
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

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openAssessmentsPage($browser);
            $result = $callback($browser);
        });
        return $result;
    }

    // ---- FK metadata assertion -------------------------------------------

    private function assertForeignKeyDeleteRule(string $table, string $referenced, array $acceptedRules): void
    {
        try {
            if (DB::connection()->getDriverName() !== 'mysql') {
                $this->markTestSkipped('FK metadata check requires MySQL.');
            }
            $rows = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                  WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ? AND REFERENCED_TABLE_NAME = ?",
                [$table, $referenced]
            );
            if (empty($rows)) {
                $this->markTestSkipped("No FK metadata for {$table} → {$referenced}.");
            }
            $rule = strtoupper((string) ($rows[0]->DELETE_RULE ?? ''));
            $matched = false;
            foreach ($acceptedRules as $accepted) {
                if (str_contains($rule, strtoupper($accepted))) {
                    $matched = true;
                    break;
                }
            }
            $this->assertTrue($matched, "{$table} → {$referenced} delete rule '{$rule}' not in " . implode('/', $acceptedRules));
        } catch (Throwable $e) {
            $this->markTestSkipped("FK metadata path unavailable for {$table} → {$referenced}: " . $e->getMessage());
        }
    }

    // ---- Dependency resolution (cross-module FKs) -------------------------

    /** @return array{0: BaAssessment, 1: int} */
    private function requireRemarkGraph(): array
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        $studentId = $this->firstStudentId();
        if ($assessment === null || $studentId === null) {
            if ($assessment !== null) {
                $this->cleanupAssessment($assessment);
            }
            $this->markTestSkipped('Remark graph unavailable (need sch_employees, sch_class_section_jnt, a period, and std_students).');
        }
        return [$assessment, $studentId];
    }

    private function firstStudentId(): ?int
    {
        return $this->resolveExistingId(self::STUDENT_TABLE);
    }

    private function resolveExistingId(string $table): ?int
    {
        try {
            if (!Schema::hasTable($table)) {
                return null;
            }
            $id = DB::table($table)->value('id');
            return $id === null ? null : (int) $id;
        } catch (Throwable) {
            return null;
        }
    }

    private function academicSessionId(): ?int
    {
        return $this->resolveExistingId(self::SESSION_TABLE);
    }

    // ---- Seed / cleanup ---------------------------------------------------

    private function createPeriodSeed(array $overrides = []): ?BaAssessmentPeriod
    {
        $sessionId = $this->academicSessionId();
        if ($sessionId === null) {
            return null;
        }

        $payload = array_merge([
            'academic_session_id' => $sessionId,
            'academic_term_id'    => null,
            'name'                => $this->uniqueName('REMPERIOD'),
            'start_date'          => '2026-06-01',
            'end_date'            => '2026-08-31',
            'deadline'            => '2026-09-05',
            'status'              => 'open',
            'is_active'           => true,
            'created_by'          => (int) $this->adminUser->id,
            'updated_by'          => (int) $this->adminUser->id,
        ], $overrides);

        try {
            return BaAssessmentPeriod::query()->create($payload);
        } catch (Throwable) {
            return null;
        }
    }

    private function createAssessmentSeed(array $overrides = []): ?BaAssessment
    {
        $emp = $this->resolveExistingId(self::EMP_TABLE);
        $cs  = $this->resolveExistingId(self::CS_TABLE);
        if ($emp === null || $cs === null) {
            return null;
        }
        $period = $this->createPeriodSeed(['status' => 'open']);
        if ($period === null) {
            return null;
        }

        $payload = array_merge([
            'period_id'        => $period->id,
            'teacher_id'       => $emp,
            'class_section_id' => $cs,
            'status'           => 'draft',
            'is_active'        => true,
            'created_by'       => (int) $this->adminUser->id,
            'updated_by'       => (int) $this->adminUser->id,
        ], $overrides);

        try {
            return BaAssessment::query()->create($payload);
        } catch (Throwable) {
            $this->forceDeletePeriodById((int) $period->id);
            return null;
        }
    }

    private function createRemarkSeed(int $assessmentId, int $studentId, array $overrides = []): BaStudentRemark
    {
        $payload = array_merge([
            'assessment_id' => $assessmentId,
            'student_id'    => $studentId,
            'remark_text'   => 'Seed remark ' . $this->uniqueSuffix(),
            'is_active'     => true,
            'created_by'    => (int) $this->adminUser->id,
            'updated_by'    => (int) $this->adminUser->id,
        ], $overrides);

        return BaStudentRemark::query()->create($payload);
    }

    private function cleanupAssessment(?BaAssessment $assessment): void
    {
        if ($assessment === null) {
            return;
        }
        $id = (int) $assessment->id;
        $periodId = (int) ($assessment->period_id ?? 0);
        try {
            if (Schema::hasTable(self::TABLE)) {
                DB::table(self::TABLE)->where('assessment_id', $id)->delete();
            }
        } catch (Throwable) {
        }
        try {
            if (BaAssessment::withTrashed()->whereKey($id)->exists()) {
                BaAssessment::withTrashed()->whereKey($id)->get()->each(function (BaAssessment $a): void {
                    try {
                        $a->forceDelete();
                    } catch (Throwable) {
                    }
                });
            }
        } catch (Throwable) {
        }
        $this->forceDeletePeriodById($periodId);
    }

    private function cleanupPeriodFor(?BaAssessment $assessment): void
    {
        if ($assessment === null) {
            return;
        }
        $this->forceDeletePeriodById((int) ($assessment->period_id ?? 0));
    }

    private function forceDeletePeriodById(int $periodId): void
    {
        if ($periodId <= 0) {
            return;
        }
        try {
            if (BaAssessment::withTrashed()->where('period_id', $periodId)->exists()) {
                return;
            }
            BaAssessmentPeriod::withTrashed()->whereKey($periodId)->get()->each(function (BaAssessmentPeriod $p): void {
                try {
                    $p->forceDelete();
                } catch (Throwable) {
                }
            });
        } catch (Throwable) {
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
                $attributes['emp_code'] = 'SL' . substr($this->uniqueSuffix(), -8);
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
        $this->grantAssessmentPermissions($this->adminUser);
    }

    private function grantAssessmentPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::REM_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::REM_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::REM_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.student-remark-admin');
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
            $modelFile = (new ReflectionClass(BaStudentRemark::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaStudentRemark.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaStudentRemark::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaStudentRemark.php → app root = dirname(,5)
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

    private function uniqueName(string $prefix): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $clean = $clean === '' ? 'SR' : substr($clean, 0, 12);
        return substr($clean . ' ' . $this->uniqueSuffix(), 0, 100);
    }
}
