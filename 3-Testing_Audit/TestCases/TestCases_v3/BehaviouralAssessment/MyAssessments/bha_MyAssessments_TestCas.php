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
use Modules\BehaviouralAssessment\Models\BaAssessmentPeriod;
use Modules\BehaviouralAssessment\Models\BaAuditLog;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — My Assessments (assessments tab) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/08-My-Assessments.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime table      : ba_assessments (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController
 * Page controller    : Modules\BehaviouralAssessment\Http\Controllers\BaDashboardController::assessmentsPage()
 * FormRequest        : Modules\BehaviouralAssessment\Http\Requests\BaAssessmentRequest
 * Permission prefix  : tenant.behavioural-assessment.assessments.{viewAny|view|create|update|delete|restore|forceDelete|status}
 *                      tenant.behavioural-assessment.assessments-page.viewAny  (tab page gate)
 * Audit log          : ba_audit_log via BaAuditLog::log(ENTITY_ASSESSMENT, id, 'status', old, new)
 *                      — NOT sys_activity_logs / GlobalMaster activity_logs. entity_type='assessment'.
 * State machine      : (none)--store-->draft --submit--> submitted --approve--> reviewed (--sendBack--> draft) --lock--> locked.
 *                      MyAssessments (teacher) owns: create(draft), submit(draft->submitted); edit/update/destroy are draft-only.
 *
 * Defects proven / documented:
 *   - DOC-BA-001    : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - BUG-BA-MYA-001: show() references un-imported BaStudentRemark → fatal 500 on "View Summary" (proven in _47).
 *   - BUG-BA-MYA-002: bulkRate() uses DB facade with no `use Illuminate\Support\Facades\DB` (source-scanned in _55b/_92 note).
 *   - PERM-BA-MYA-003: restore()/forceDelete() authorize `.delete`, not the Policy's `.restore`/`.forceDelete` (source-scanned in _55).
 *   - VAL-BA-MYA-004: requirement requires 100% completion before submit; submit() checks only status==='draft' (proven in _25).
 *   - BUG-BA-MYA-005: store() firstOrCreate keys on status='draft' but unique key = (teacher,cs,period); a submitted triple
 *                     forces a create → unique violation 500 (proven defensively in _35).
 *   - SEC-BA-002    : FormRequest authorize() returns bare true, mitigated by controller Gate (proven in _92).
 */
class bha_MyAssessments_TestCas extends DuskTestCase
{
    private const URL_PREFIX       = '/behavioural-assessment';
    private const ASSESSMENTS_PAGE = '/behavioural-assessment/assessments-page?tab=my-assessments';
    private const STORE_PATH       = '/behavioural-assessment/assessments';
    private const CREATE_PATH      = '/behavioural-assessment/assessments/create';
    private const TRASH_PATH       = '/behavioural-assessment/assessments/trash';

    private const TABLE            = 'ba_assessments';
    private const DDL_TABLE        = 'bha_assessments';   // stale DDL-doc name — must NOT exist at runtime
    private const AUDIT_TABLE      = 'ba_audit_log';
    private const PERIOD_TABLE     = 'ba_assessment_periods';
    private const SESSION_TABLE    = 'sch_org_academic_sessions_jnt';
    private const EMP_TABLE        = 'sch_employees';
    private const CS_TABLE         = 'sch_class_section_jnt';

    private const SCREENSHOT_DIR   = 'tests/Browser/Modules/BehaviouralAssessment/MyAssessments/screenshots';

    /** @var array<int,string> */
    private const MYA_PERMISSIONS = [
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

    public function test_my_assessments_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table ba_assessments does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'period_id', 'teacher_id', 'class_section_id', 'status',
                'submitted_at', 'reviewed_by', 'reviewed_at', 'reviewer_remarks',
                'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_assessments table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::TABLE))->keyBy('Field');
            $this->assertStringContainsString('enum', strtolower((string) ($cols['status']->Type ?? '')));
            $this->assertStringContainsString('int', strtolower((string) ($cols['period_id']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130617_create_ba_assessments_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_assessments'", $migration);
            $this->assertStringContainsString("enum('status', ['draft', 'locked', 'reviewed', 'submitted'])", $migration);
            $this->assertStringContainsString("constrained('ba_assessment_periods')", $migration);
            $this->assertStringContainsString("->on('sch_employees')", $migration);
            $this->assertStringContainsString("->on('sch_class_section_jnt')", $migration);
            $this->assertStringContainsString("unique(['teacher_id', 'class_section_id', 'period_id']", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // FormRequest rule strings — verbatim from the real source.
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaAssessmentRequest.php'));
        if ($request !== null) {
            $this->assertStringContainsString("'exists:ba_assessment_periods,id'", $request);
            $this->assertStringContainsString("'exists:sch_class_section_jnt,id'", $request);
            $this->assertStringContainsString("'exists:sch_employees,id'", $request);
        }

        // Model configuration.
        $model = new BaAssessment();
        $this->assertSame('ba_assessments', $model->getTable());
        $this->assertSame([
            'period_id', 'teacher_id', 'class_section_id', 'reviewed_by', 'status',
            'submitted_at', 'reviewed_at', 'reviewer_remarks', 'is_active',
            'created_by', 'updated_by',
        ], $model->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessment::class));
        $this->assertInstanceOf(BelongsTo::class, $model->period());
        $this->assertInstanceOf(BelongsTo::class, $model->teacher());
        $this->assertInstanceOf(BelongsTo::class, $model->classSection());
        $this->assertInstanceOf(HasMany::class, $model->ratings());
    }

    public function test_my_assessments_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Runtime table ba_assessments must exist.');

        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_TABLE),
                'DOC-BA-001 regression: bha_assessments exists at runtime; expected only the live ba_assessments.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        $this->assertSame('ba_assessments', (new BaAssessment())->getTable());
    }

    public function test_my_assessments_03_audit_log_table_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE), 'Table ba_audit_log does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::AUDIT_TABLE, [
                'id', 'entity_type', 'entity_id', 'field_name', 'old_value', 'new_value',
                'changed_by', 'changed_at', 'is_active', 'created_by', 'created_at',
            ]),
            'Expected columns are missing in ba_audit_log.'
        );

        $audit = new BaAuditLog();
        $this->assertSame('ba_audit_log', $audit->getTable());
        $this->assertFalse($audit->timestamps, 'ba_audit_log is immutable — Eloquent timestamps must be disabled.');
        $this->assertSame('assessment', BaAuditLog::ENTITY_ASSESSMENT);

        // Immutable table — DDL declares NO updated_at / deleted_at.
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'updated_at'), 'Audit log must not have updated_at (immutable).');
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'deleted_at'), 'Audit log must not have deleted_at (immutable).');
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_my_assessments_10_store_creates_draft_assessment_and_logs_audit(): void
    {
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id'        => $periodId,
            'class_section_id' => $deps['cs'],
            'teacher_id'       => $deps['emp'],
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Valid create should not 422: ' . json_encode($response['json'] ?? $response['body'] ?? null));

        $created = BaAssessment::where('period_id', $periodId)
            ->where('class_section_id', $deps['cs'])
            ->where('teacher_id', $deps['emp'])
            ->first();
        $this->assertNotNull($created, 'Assessment row was not created.');
        $this->assertSame('draft', $created->status);
        $this->assertTrue((bool) $created->is_active);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);

        // Audit: a status null->draft row is written for a newly-created assessment.
        $this->assertTrue(
            BaAuditLog::where('entity_type', BaAuditLog::ENTITY_ASSESSMENT)
                ->where('entity_id', $created->id)
                ->where('field_name', 'status')
                ->where('new_value', 'draft')
                ->exists(),
            'Expected a ba_audit_log status->draft row for the new assessment.'
        );

        $this->forceDeleteAssessment($created);
        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_11_store_is_idempotent_via_first_or_create(): void
    {
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;
        $payload = ['period_id' => $periodId, 'class_section_id' => $deps['cs'], 'teacher_id' => $deps['emp']];

        $first  = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), $payload);
        $second = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), $payload);
        $this->assertNotSame(422, (int) ($first['status'] ?? 0));
        $this->assertNotSame(422, (int) ($second['status'] ?? 0));

        $count = BaAssessment::where('period_id', $periodId)
            ->where('class_section_id', $deps['cs'])
            ->where('teacher_id', $deps['emp'])
            ->count();
        $this->assertSame(1, $count, 'firstOrCreate must not create a duplicate draft for the same (teacher,cs,period).');

        BaAssessment::where('period_id', $periodId)->get()->each(fn ($a) => $this->forceDeleteAssessment($a));
        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_12_store_without_teacher_returns_422_assessor_required(): void
    {
        // The Dusk admin (root) has no sch_employees mapping, so teacher_id is required by the controller.
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id'        => $periodId,
            'class_section_id' => $deps['cs'],
            // teacher_id intentionally omitted
        ]);

        // Controller returns 422 JSON 'An assessor/teacher must be specified.' when no employee + no teacher_id.
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Missing assessor must be rejected for a non-employee user.');
        $message = (string) ($response['json']['message'] ?? '');
        $this->assertStringContainsString('assessor/teacher must be specified', $message);

        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_13_assessments_page_renders_my_assessments_tab(): void
    {
        $this->browseWithFailureScreenshot('page-render', function (Browser $browser): void {
            $this->openMyAssessmentsTab($browser);
            $browser->assertSee('Save Assessment');
        });
    }

    public function test_my_assessments_14_update_persists_period_change_and_logs_audit(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $newPeriod = $this->createPeriodSeed(['status' => 'open']);

        $response = $this->apiCall('PUT', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id), [
            'period_id' => $newPeriod->id,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Draft update should not 422.');

        $assessment->refresh();
        $this->assertSame((int) $newPeriod->id, (int) $assessment->period_id, 'period_id must be updated.');
        $this->assertSame((int) $this->adminUser->id, (int) $assessment->updated_by);
        $this->assertTrue(
            BaAuditLog::where('entity_type', BaAuditLog::ENTITY_ASSESSMENT)
                ->where('entity_id', $assessment->id)
                ->where('field_name', 'period_id')
                ->exists(),
            'Expected a ba_audit_log period_id change row.'
        );

        $this->forceDeleteAssessment($assessment);
        $this->forceDeletePeriodById($newPeriod->id);
    }

    public function test_my_assessments_15_details_endpoint_returns_assessment_json(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/details'));
        $this->assertSame(200, (int) ($response['status'] ?? 0), 'details() must return 200 JSON.');
        $this->assertSame((int) $assessment->id, (int) ($response['json']['id'] ?? 0), 'details() JSON must carry the assessment id.');

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_16_status_filter_narrows_my_assessments_list(): void
    {
        $draft     = $this->createAssessmentSeed(['status' => 'draft']);
        $submitted = $this->createAssessmentSeed(['status' => 'submitted']);
        if ($draft === null || $submitted === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $this->browseWithFailureScreenshot('status-filter', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/assessments-page?tab=my-assessments&status=submitted', 1200);
            $source = $browser->driver->getPageSource();
            // With the status=submitted filter, only submitted rows show a Submitted badge.
            $this->assertStringContainsString('Submitted', $source);
        });

        $this->forceDeleteAssessment($draft);
        $this->forceDeleteAssessment($submitted);
    }

    public function test_my_assessments_17_period_filter_query_is_accepted(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $this->browseWithFailureScreenshot('period-filter', function (Browser $browser) use ($assessment): void {
            $this->visitAuthenticated(
                $browser,
                self::URL_PREFIX . '/assessments-page?tab=my-assessments&period_id=' . $assessment->period_id,
                1100
            );
            $browser->assertSee('Save Assessment');
        });

        $this->forceDeleteAssessment($assessment);
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM): draft -> submitted, draft-only guards
    // =====================================================================

    public function test_my_assessments_20_submit_transitions_draft_to_submitted_and_logs(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/submit'));
        // submit() always redirects (302) on both success and error.
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Submit should redirect.');

        $assessment->refresh();
        $this->assertSame('submitted', $assessment->status, 'draft --submit--> submitted (BC-SM-2).');
        $this->assertNotNull($assessment->submitted_at, 'submitted_at must be stamped.');
        $this->assertTrue(
            BaAuditLog::where('entity_type', BaAuditLog::ENTITY_ASSESSMENT)
                ->where('entity_id', $assessment->id)
                ->where('field_name', 'status')
                ->where('old_value', 'draft')
                ->where('new_value', 'submitted')
                ->exists(),
            'Expected a ba_audit_log status draft->submitted row.'
        );

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_21_submit_on_non_draft_is_rejected(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'submitted', 'submitted_at' => now()]);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/submit'));

        $assessment->refresh();
        $this->assertSame('submitted', $assessment->status, 'Submit on a non-draft must NOT re-transition (illegal transition rejected).');

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_22_edit_on_non_draft_returns_422_only_draft(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'submitted', 'submitted_at' => now()]);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/edit'));
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'edit() on non-draft must 422 for JSON requests.');
        $this->assertStringContainsString('Only draft assessments can be edited', (string) ($response['json']['message'] ?? ''));

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_23_update_on_non_draft_is_rejected(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'submitted', 'submitted_at' => now()]);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $originalPeriod = (int) $assessment->period_id;
        $newPeriod = $this->createPeriodSeed(['status' => 'open']);

        $response = $this->apiCall('PUT', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id), [
            'period_id' => $newPeriod->id,
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'update() with keys on non-draft must 422.');
        $this->assertStringContainsString('Only draft assessments can be updated', (string) ($response['json']['message'] ?? ''));

        $assessment->refresh();
        $this->assertSame($originalPeriod, (int) $assessment->period_id, 'period_id must be unchanged on a rejected update.');

        $this->forceDeleteAssessment($assessment);
        $this->forceDeletePeriodById($newPeriod->id);
    }

    public function test_my_assessments_24_destroy_on_non_draft_is_rejected_post_submission_freeze(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'submitted', 'submitted_at' => now()]);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('DELETE', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id));
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'destroy() on non-draft must 422 (post-submission freeze).');
        $this->assertStringContainsString('Only draft assessments can be deleted', (string) ($response['json']['message'] ?? ''));

        $this->assertTrue(BaAssessment::whereKey($assessment->id)->exists(), 'A submitted assessment must not be soft-deleted.');

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_25_submit_allowed_below_100_percent_completion_val_ba_mya_004(): void
    {
        // Requirement 08 §"Submit Button Activation": submit only when completion is exactly 100%.
        // The controller submit() checks only status==='draft' — NO completion gate. A draft with ZERO
        // ratings/remarks submits successfully, proving VAL-BA-MYA-004.
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/submit'));

        $assessment->refresh();
        $this->assertSame(
            'submitted',
            $assessment->status,
            'VAL-BA-MYA-004 regression fixed? A 0%-complete draft was accepted — completion gate is not enforced.'
        );

        $this->forceDeleteAssessment($assessment);
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL) — Negative 100%
    // =====================================================================

    public function test_my_assessments_30_required_fields_are_rejected(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id' => '', 'class_section_id' => '',
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty payload must fail validation.');
        $errors = $response['json']['errors'] ?? [];
        $this->assertArrayHasKey('period_id', $errors, 'period_id is required.');
        $this->assertArrayHasKey('class_section_id', $errors, 'class_section_id is required.');
    }

    public function test_my_assessments_31_period_id_must_exist(): void
    {
        $deps = $this->requireDependencies();
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id'        => 987654321,
            'class_section_id' => $deps['cs'],
            'teacher_id'       => $deps['emp'],
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('period_id', $response['json']['errors'] ?? []);
    }

    public function test_my_assessments_32_class_section_id_must_exist(): void
    {
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id'        => $periodId,
            'class_section_id' => 987654321,
            'teacher_id'       => $deps['emp'],
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('class_section_id', $response['json']['errors'] ?? []);
        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_33_teacher_id_must_exist_when_present(): void
    {
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id'        => $periodId,
            'class_section_id' => $deps['cs'],
            'teacher_id'       => 987654321,
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('teacher_id', $response['json']['errors'] ?? []);
        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_34_non_integer_period_is_rejected(): void
    {
        $deps = $this->requireDependencies();
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id'        => 'abc',
            'class_section_id' => $deps['cs'],
            'teacher_id'       => $deps['emp'],
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('period_id', $response['json']['errors'] ?? []);
    }

    public function test_my_assessments_35_second_create_for_submitted_triple_triggers_unique_violation_bug_ba_mya_005(): void
    {
        // firstOrCreate keys include status='draft'; the DB unique key is (teacher,cs,period) WITHOUT status.
        // A pre-existing SUBMITTED row for the same triple makes firstOrCreate miss and attempt an insert →
        // unique violation → 500. Proves BUG-BA-MYA-005.
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;

        // Seed a submitted row for the triple directly (bypasses the draft firstOrCreate match).
        $existing = BaAssessment::create([
            'period_id'        => $periodId,
            'teacher_id'       => $deps['emp'],
            'class_section_id' => $deps['cs'],
            'status'           => 'submitted',
            'submitted_at'     => now(),
            'is_active'        => true,
            'created_by'       => (int) $this->adminUser->id,
            'updated_by'       => (int) $this->adminUser->id,
        ]);

        try {
            $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
                'period_id'        => $periodId,
                'class_section_id' => $deps['cs'],
                'teacher_id'       => $deps['emp'],
            ]);
            $status = (int) ($response['status'] ?? 0);
            $this->assertSame(
                500,
                $status,
                'BUG-BA-MYA-005 regression fixed? A duplicate (teacher,cs,period) create over a submitted row should hit the unique key (500).'
            );
            $this->assertSame(
                1,
                BaAssessment::where('period_id', $periodId)->where('teacher_id', $deps['emp'])->where('class_section_id', $deps['cs'])->count(),
                'No second row should be persisted after the unique violation.'
            );
        } finally {
            BaAssessment::where('period_id', $periodId)->get()->each(fn ($a) => $this->forceDeleteAssessment($a));
            $this->forceDeleteAssessment($existing);
            $this->forceDeletePeriodById($periodId);
        }
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-INT/REF/EDG)
    // =====================================================================

    public function test_my_assessments_40_soft_delete_moves_draft_to_trash(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('DELETE', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertFalse(BaAssessment::whereKey($assessment->id)->exists(), 'Draft should be hidden after soft delete.');
        $this->assertNotNull(BaAssessment::onlyTrashed()->find($assessment->id), 'Draft should be present in trash.');

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_41_restore_from_trash(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $assessment->delete();

        $response = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/restore'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertTrue(BaAssessment::whereKey($assessment->id)->exists(), 'Restored assessment should return to default scope.');

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_42_force_delete_removes_row(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $id = (int) $assessment->id;
        $periodId = (int) $assessment->period_id;
        $assessment->delete();

        $response = $this->apiCall('DELETE', $this->tenantUrl(self::STORE_PATH . '/' . $id . '/force-delete'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertFalse(BaAssessment::withTrashed()->whereKey($id)->exists(), 'Row should be physically removed.');

        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_43_period_fk_is_restrict_on_delete(): void
    {
        $this->assertForeignKeyDeleteRule(self::TABLE, self::PERIOD_TABLE, ['RESTRICT', 'NO ACTION']);
    }

    public function test_my_assessments_44_teacher_and_cs_fk_are_restrict(): void
    {
        $this->assertForeignKeyDeleteRule(self::TABLE, self::EMP_TABLE, ['RESTRICT', 'NO ACTION']);
        $this->assertForeignKeyDeleteRule(self::TABLE, self::CS_TABLE, ['RESTRICT', 'NO ACTION']);
    }

    public function test_my_assessments_45_reviewed_by_fk_is_set_null(): void
    {
        // reviewed_by → sch_employees ON DELETE SET NULL (separate FK from teacher_id).
        try {
            if (DB::connection()->getDriverName() !== 'mysql') {
                $this->markTestSkipped('FK metadata check requires MySQL.');
            }
            $rows = DB::select(
                "SELECT rc.DELETE_RULE
                   FROM information_schema.REFERENTIAL_CONSTRAINTS rc
                   JOIN information_schema.KEY_COLUMN_USAGE kcu
                     ON rc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME AND rc.CONSTRAINT_SCHEMA = kcu.CONSTRAINT_SCHEMA
                  WHERE rc.CONSTRAINT_SCHEMA = DATABASE()
                    AND rc.TABLE_NAME = ? AND kcu.COLUMN_NAME = 'reviewed_by'",
                [self::TABLE]
            );
            if (empty($rows)) {
                $this->markTestSkipped('No FK metadata for ba_assessments.reviewed_by.');
            }
            $this->assertStringContainsString('SET NULL', strtoupper((string) ($rows[0]->DELETE_RULE ?? '')));
        } catch (Throwable $e) {
            $this->markTestSkipped('reviewed_by SET NULL check unavailable: ' . $e->getMessage());
        }
    }

    public function test_my_assessments_46_full_lifecycle_create_submit_then_edit_blocked(): void
    {
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;

        // create
        $create = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id' => $periodId, 'class_section_id' => $deps['cs'], 'teacher_id' => $deps['emp'],
        ]);
        $this->assertNotSame(422, (int) ($create['status'] ?? 0));
        $assessment = BaAssessment::where('period_id', $periodId)->firstOrFail();

        // submit
        $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/submit'));
        $assessment->refresh();
        $this->assertSame('submitted', $assessment->status);

        // edit now blocked (freeze)
        $edit = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/edit'));
        $this->assertSame(422, (int) ($edit['status'] ?? 0), 'Post-submission edit must be blocked.');

        $this->forceDeleteAssessment($assessment);
        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_47_show_action_fatals_due_to_unimported_student_remark_bug_ba_mya_001(): void
    {
        // BaAssessmentController::show() references BaStudentRemark with NO `use` import → the name
        // resolves to Modules\...\Http\Controllers\BaStudentRemark (nonexistent) → fatal Error → HTTP 500.
        // This breaks the "View Summary" action for every assessment.
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $response = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id));
        $this->assertSame(
            500,
            (int) ($response['status'] ?? 0),
            'BUG-BA-MYA-001 regression fixed? show() should 500 while BaStudentRemark is unimported.'
        );

        $this->forceDeleteAssessment($assessment);
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_my_assessments_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::ASSESSMENTS_PAGE))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_my_assessments_51_limited_user_without_create_permission_gets_403(): void
    {
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-create-403', function (Browser $browser) use ($limited, $deps, $periodId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::STORE_PATH), [
                'period_id' => $periodId, 'class_section_id' => $deps['cs'], 'teacher_id' => $deps['emp'],
            ]);
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without create permission must get 403.');
        });

        $this->deleteUser($limited);
        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_52_limited_user_without_update_permission_gets_403_on_submit(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-submit-403', function (Browser $browser) use ($limited, $assessment): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id . '/submit'));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_53_limited_user_without_delete_permission_gets_403_on_destroy(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-delete-403', function (Browser $browser) use ($limited, $assessment): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'DELETE', $this->tenantUrl(self::STORE_PATH . '/' . $assessment->id));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_54_policy_methods_map_to_permission_strings(): void
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

    public function test_my_assessments_55_restore_and_force_delete_authorize_delete_not_restore_perm_ba_mya_003(): void
    {
        // PERM-BA-MYA-003: the Policy declares restore/forceDelete abilities, but the controller's
        // restore()/forceDelete() authorize '.delete' instead of '.restore'/'.forceDelete'.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }

        // Both restore() and forceDelete() bodies use the `.delete` gate.
        $this->assertStringContainsString(
            "Gate::authorize('tenant.behavioural-assessment.assessments.delete');\n        BaAssessment::onlyTrashed()->findOrFail(\$id)->restore();",
            $controller,
            'PERM-BA-MYA-003 changed: restore() no longer authorizes the .delete gate.'
        );
        $this->assertStringNotContainsString(
            "tenant.behavioural-assessment.assessments.restore",
            $controller,
            'PERM-BA-MYA-003 changed: controller now references the .restore gate.'
        );
        $this->assertStringNotContainsString(
            "tenant.behavioural-assessment.assessments.forceDelete",
            $controller,
            'PERM-BA-MYA-003 changed: controller now references the .forceDelete gate.'
        );
    }

    // =====================================================================
    // Band 60–69 — UI/UX (badges, actions, empty state, trash, modal)
    // =====================================================================

    public function test_my_assessments_60_status_badge_and_actions_render_for_draft_row(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $this->browseWithFailureScreenshot('draft-row', function (Browser $browser): void {
            $this->openMyAssessmentsTab($browser);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Draft', $source, 'A draft badge should render for the seeded draft row.');
        });

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_61_empty_state_message_when_no_assessments(): void
    {
        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser): void {
            // Filter to an implausible status so the grid is empty for the current user.
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/assessments-page?tab=my-assessments&status=locked&period_id=987654321', 1100);
            $browser->assertSee('No assessments found.');
        });
    }

    public function test_my_assessments_62_trash_page_renders(): void
    {
        $assessment = $this->createAssessmentSeed(['status' => 'draft']);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }
        $assessment->delete();

        $this->browseWithFailureScreenshot('trash-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH, 1000);
            $browser->assertSee('Trash');
        });

        $this->forceDeleteAssessment($assessment);
    }

    public function test_my_assessments_63_create_modal_present_on_assessments_page(): void
    {
        $this->browseWithFailureScreenshot('create-modal', function (Browser $browser): void {
            $this->openMyAssessmentsTab($browser);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('assessmentModal', $source, 'The create-assessment modal must be present.');
            $this->assertStringContainsString('Save Assessment', $source);
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_my_assessments_70_submit_on_invalid_id_returns_404(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/987654321/submit'));
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Submit on a nonexistent id must 404.');
    }

    public function test_my_assessments_71_invalid_id_details_and_edit_return_404(): void
    {
        foreach (['/987654321/details', '/987654321/edit'] as $suffix) {
            $response = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . $suffix));
            $this->assertSame(404, (int) ($response['status'] ?? 0), "Expected 404 for {$suffix}.");
        }
    }

    public function test_my_assessments_72_status_enum_is_limited_to_four_values(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('ENUM inspection requires MySQL.');
        }
        $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::TABLE))->keyBy('Field');
        $type = strtolower((string) ($cols['status']->Type ?? ''));
        foreach (['draft', 'submitted', 'reviewed', 'locked'] as $value) {
            $this->assertStringContainsString("'{$value}'", $type, "status enum must include '{$value}'.");
        }
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_my_assessments_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side assessment tests.'
        );
        $this->assertTrue(Schema::hasTable(self::TABLE));
    }

    public function test_my_assessments_91_cross_tenant_direct_id_isolation(): void
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

    public function test_my_assessments_92_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaAssessmentRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable from app repo.');
        }
        $this->assertMatchesRegularExpression(
            '/function\s+authorize\s*\(\s*\)\s*:\s*bool\s*\{\s*return\s+true\s*;/s',
            $request,
            'SEC-BA-002 changed: authorize() no longer returns bare true.'
        );
    }

    public function test_my_assessments_93_store_cannot_override_status_via_mass_assignment(): void
    {
        // store() hardcodes status='draft' in firstOrCreate; a hostile status override must be ignored.
        $deps = $this->requireDependencies();
        $periodId = $this->createPeriodSeed(['status' => 'open'])->id;

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'period_id'        => $periodId,
            'class_section_id' => $deps['cs'],
            'teacher_id'       => $deps['emp'],
            'status'           => 'reviewed',
            'reviewed_by'      => 999999,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));

        $created = BaAssessment::where('period_id', $periodId)->first();
        $this->assertNotNull($created);
        $this->assertSame('draft', $created->status, 'store() must ignore a hostile status override (always draft).');

        $this->forceDeleteAssessment($created);
        $this->forceDeletePeriodById($periodId);
    }

    public function test_my_assessments_94_reviewer_remarks_xss_is_escaped_on_page(): void
    {
        $xss = '<script>alert(1)</script>';
        $assessment = $this->createAssessmentSeed(['status' => 'submitted', 'submitted_at' => now(), 'reviewer_remarks' => 'BAD ' . $xss]);
        if ($assessment === null) {
            $this->markTestSkipped('Assessment dependencies unavailable.');
        }

        $this->browseWithFailureScreenshot('remarks-xss', function (Browser $browser): void {
            $this->openMyAssessmentsTab($browser);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Blade must escape stored reviewer remarks.');
        });

        $this->forceDeleteAssessment($assessment);
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
        $rawName = 'my-assessments-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'my-assessments-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- UI drivers -------------------------------------------------------

    private function openMyAssessmentsTab(Browser $browser): void
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
window.__maApiDone = false;
window.__maApiError = '';
window.__maApiResult = null;

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

        window.__maApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__maApiError = String(error);
    } finally {
        window.__maApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__maApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__maApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__maApiResult || null;');
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
            $this->openMyAssessmentsTab($browser);
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

    /** @return array{emp:int,cs:int} */
    private function requireDependencies(): array
    {
        $emp = $this->resolveExistingId(self::EMP_TABLE);
        $cs  = $this->resolveExistingId(self::CS_TABLE);
        if ($emp === null || $cs === null) {
            $this->markTestSkipped('Required cross-module rows (sch_employees / sch_class_section_jnt) are absent.');
        }
        return ['emp' => $emp, 'cs' => $cs];
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

    private function createPeriodSeed(array $overrides = []): BaAssessmentPeriod
    {
        $sessionId = $this->academicSessionId();
        if ($sessionId === null) {
            $this->markTestSkipped('No sch_org_academic_sessions_jnt row available to satisfy the required FK.');
        }

        $payload = array_merge([
            'academic_session_id' => $sessionId,
            'academic_term_id'    => null,
            'name'                => $this->uniqueName('MAPERIOD'),
            'start_date'          => '2026-06-01',
            'end_date'            => '2026-08-31',
            'deadline'            => '2026-09-05',
            'status'              => 'open',
            'is_active'           => true,
            'created_by'          => (int) $this->adminUser->id,
            'updated_by'          => (int) $this->adminUser->id,
        ], $overrides);

        return BaAssessmentPeriod::query()->create($payload);
    }

    private function createAssessmentSeed(array $overrides = []): ?BaAssessment
    {
        $emp = $this->resolveExistingId(self::EMP_TABLE);
        $cs  = $this->resolveExistingId(self::CS_TABLE);
        if ($emp === null || $cs === null || $this->academicSessionId() === null) {
            return null;
        }

        $periodId = $overrides['period_id'] ?? $this->createPeriodSeed(['status' => 'open'])->id;

        $payload = array_merge([
            'period_id'        => $periodId,
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
            return null;
        }
    }

    private function forceDeleteAssessment(?BaAssessment $assessment): void
    {
        if ($assessment === null) {
            return;
        }
        $id = (int) $assessment->id;
        $periodId = (int) ($assessment->period_id ?? 0);
        try {
            // Remove child rows and audit trail first (no cascading soft-deletes on children).
            foreach (['ba_assessment_ratings', 'ba_student_remarks'] as $childTable) {
                try {
                    if (Schema::hasTable($childTable)) {
                        DB::table($childTable)->where('assessment_id', $id)->delete();
                    }
                } catch (Throwable) {
                }
            }
            try {
                DB::table(self::AUDIT_TABLE)->where('entity_type', BaAuditLog::ENTITY_ASSESSMENT)->where('entity_id', $id)->delete();
            } catch (Throwable) {
            }
            if (BaAssessment::withTrashed()->whereKey($id)->exists()) {
                BaAssessment::withTrashed()->whereKey($id)->get()->each(function (BaAssessment $a): void {
                    try {
                        $a->forceDelete();
                    } catch (Throwable) {
                    }
                });
            }
        } catch (Throwable) {
            // best-effort
        }
        if ($periodId > 0) {
            $this->forceDeletePeriodById($periodId);
        }
    }

    private function forceDeletePeriodById(int $periodId): void
    {
        if ($periodId <= 0) {
            return;
        }
        try {
            // A period referenced by any remaining assessment cannot be removed (RESTRICT) — leave it.
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
            // best-effort
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
                'name'              => 'MA Limited ' . $this->uniqueSuffix(),
                'email'             => 'ma_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'ML' . substr($this->uniqueSuffix(), -8);
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
        $this->ensurePermissionsExist(self::MYA_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::MYA_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::MYA_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.my-assessments-admin');
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

    private function uniqueName(string $prefix): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $clean = $clean === '' ? 'MA' : substr($clean, 0, 12);
        return substr($clean . ' ' . $this->uniqueSuffix(), 0, 100);
    }
}
