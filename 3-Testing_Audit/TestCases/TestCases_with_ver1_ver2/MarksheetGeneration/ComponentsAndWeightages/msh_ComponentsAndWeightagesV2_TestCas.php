<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\MarksheetGeneration\Models\ConfigTemplate;
use Modules\MarksheetGeneration\Models\ExamGroup;
use Modules\MarksheetGeneration\Models\IaComponentType;
use Modules\MarksheetGeneration\Models\MarksheetType;
use Modules\MarksheetGeneration\Models\OrgAcademicSession;
use Modules\MarksheetGeneration\Models\SourceComponent;
use Modules\MarksheetGeneration\Models\TemplateCoscholasticComponent;
use Modules\MarksheetGeneration\Models\TemplateExamWeightage;
use Modules\MarksheetGeneration\Models\TemplateIaComponent;
use Modules\MarksheetGeneration\Models\TemplateScholasticComponent;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * MarksheetGeneration — Components & Weightages (V2 comprehensive suite).
 *
 * Covers every TC (positive/negative/dependency/edge/security/config) for the
 * four component entities of the combined Components page. V2 method count
 * (>= 2x V1) is enforced by the Validation Report.
 *
 * Traced source defects proven here (see Gap Analysis):
 *   BUG-MSH-C01 — scholastic weightage-sum (BR-MSG-002) NOT validated on create
 *                 (controller store() bypasses TemplateScholasticComponentService).
 *   BUG-MSH-C02 — exam weightage-sum (BR-MSG-003) validator is dead code
 *                 (MarksheetConfigService::validateExamWeightageSum has no caller).
 *   BUG-MSH-C03 — sum violation on scholastic update surfaces as HTTP 500
 *                 (uncaught DomainException), not a 422 validation error.
 *   BUG-MSH-C04 — coscholastic grading_scale has no enum (`in:`) constraint.
 *   SEC-MSH-003 — all four FormRequests authorize() return true.
 *   D39-MSH     — component permissions are unseeded (env prerequisite).
 *
 * Style: browser Dusk (golden Class reference). Obeys 05_Known_Test_Failure_Constraints.md.
 */
class msh_ComponentsAndWeightagesV2_TestCas extends DuskTestCase
{
    private const COMPONENTS_PATH = '/marksheet-generation/components';

    private const SCHOLASTIC_BASE  = '/marksheet-generation/template-scholastic-component';
    private const EXAM_BASE         = '/marksheet-generation/template-exam-weightage';
    private const IA_BASE           = '/marksheet-generation/template-ia-component';
    private const COSCHOLASTIC_BASE = '/marksheet-generation/template-coscholastic-component';

    private const MIGRATION_FILE = 'database/migrations/tenant/2026_06_16_115739_create_msh_template_scholastic_components_table.php';
    private const SCHOLASTIC_REQUEST_FILE   = 'Modules/MarksheetGeneration/app/Http/Requests/TemplateScholasticComponentRequest.php';
    private const EXAM_REQUEST_FILE         = 'Modules/MarksheetGeneration/app/Http/Requests/TemplateExamWeightageRequest.php';
    private const IA_REQUEST_FILE           = 'Modules/MarksheetGeneration/app/Http/Requests/TemplateIaComponentRequest.php';
    private const COSCHOLASTIC_REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/TemplateCoscholasticComponentRequest.php';
    private const EXAM_SERVICE_FILE    = 'Modules/MarksheetGeneration/app/Services/TemplateExamWeightageService.php';
    private const EXAM_CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/TemplateExamWeightageController.php';
    private const SCHOLASTIC_CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/TemplateScholasticComponentController.php';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/MarksheetGeneration/ComponentsAndWeightages/screenshots';

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private ?int $sharedTemplateId = null;
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

    // ════════════════════════════════════════════════════════════════════════
    // Band 01-09 — schema / model / request configuration
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_01_scholastic_schema_and_model_configuration(): void
    {
        $this->assertTrue(Schema::hasTable('msh_template_scholastic_components'));
        $this->assertTrue(Schema::hasColumns('msh_template_scholastic_components', [
            'id', 'config_template_id', 'source_component_id', 'weightage_percent',
            'max_marks', 'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]));

        $migration = File::get(base_path(self::MIGRATION_FILE));
        $this->assertStringContainsString("Schema::create('msh_template_scholastic_components'", $migration);
        $this->assertStringContainsString("\$table->decimal('weightage_percent', 5, 2)", $migration);
        $this->assertStringContainsString("->onDelete('cascade')", $migration);
        $this->assertStringContainsString("unique(['config_template_id', 'source_component_id']", $migration);
        $this->assertStringContainsString('$table->softDeletes()', $migration);

        if (DB::connection()->getDriverName() === 'mysql') {
            $this->assertNotEmpty(
                DB::select("SHOW INDEX FROM msh_template_scholastic_components WHERE Key_name = 'uq_msh_tsc_template_component'"),
                'Composite unique index missing.'
            );
        }

        $model = new TemplateScholasticComponent();
        $this->assertSame('msh_template_scholastic_components', $model->getTable());
        $this->assertSame(
            ['config_template_id', 'source_component_id', 'weightage_percent', 'max_marks', 'is_active', 'created_by', 'updated_by'],
            $model->getFillable()
        );
        $this->assertContains(SoftDeletes::class, class_uses_recursive(TemplateScholasticComponent::class));
        $this->assertInstanceOf(BelongsTo::class, $model->configTemplate());
        $this->assertInstanceOf(BelongsTo::class, $model->sourceComponent());
    }

    public function test_components_02_exam_weightage_schema_and_unique_index(): void
    {
        $this->assertTrue(Schema::hasTable('msh_template_exam_weightages'));
        $this->assertTrue(Schema::hasColumns('msh_template_exam_weightages', [
            'config_template_id', 'exam_type_id', 'weightage_percent', 'max_marks', 'is_active', 'deleted_at',
        ]));
        if (DB::connection()->getDriverName() === 'mysql') {
            $this->assertNotEmpty(
                DB::select("SHOW INDEX FROM msh_template_exam_weightages WHERE Key_name = 'uq_msh_tew_template_exam'"),
                'Composite unique index uq_msh_tew_template_exam missing.'
            );
        }
        $model = new TemplateExamWeightage();
        $this->assertSame('msh_template_exam_weightages', $model->getTable());
        $this->assertInstanceOf(BelongsTo::class, $model->examType());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(TemplateExamWeightage::class));
    }

    public function test_components_03_ia_component_schema_and_unique_index(): void
    {
        $this->assertTrue(Schema::hasTable('msh_template_ia_components'));
        $this->assertTrue(Schema::hasColumns('msh_template_ia_components', [
            'config_template_id', 'ia_component_type_id', 'max_marks', 'display_order', 'is_active', 'deleted_at',
        ]));
        if (DB::connection()->getDriverName() === 'mysql') {
            $this->assertNotEmpty(
                DB::select("SHOW INDEX FROM msh_template_ia_components WHERE Key_name = 'uq_msh_tiac_template_type'"),
                'Composite unique index uq_msh_tiac_template_type missing.'
            );
        }
        $model = new TemplateIaComponent();
        $this->assertSame('msh_template_ia_components', $model->getTable());
        $this->assertInstanceOf(BelongsTo::class, $model->iaComponentType());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(TemplateIaComponent::class));
    }

    public function test_components_04_coscholastic_schema_and_unique_index(): void
    {
        $this->assertTrue(Schema::hasTable('msh_template_coscholastic_components'));
        $this->assertTrue(Schema::hasColumns('msh_template_coscholastic_components', [
            'config_template_id', 'name', 'code', 'grading_scale', 'is_ba_linked', 'display_order', 'is_active', 'deleted_at',
        ]));
        if (DB::connection()->getDriverName() === 'mysql') {
            $this->assertNotEmpty(
                DB::select("SHOW INDEX FROM msh_template_coscholastic_components WHERE Key_name = 'uq_msh_tcsc_template_code'"),
                'Composite unique index uq_msh_tcsc_template_code missing.'
            );
        }
        $model = new TemplateCoscholasticComponent();
        $this->assertSame('msh_template_coscholastic_components', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(TemplateCoscholasticComponent::class));
    }

    public function test_components_05_model_casts_are_correct(): void
    {
        $this->assertSame('bool', (new TemplateScholasticComponent())->getCasts()['is_active'] ?? null);
        $this->assertSame('decimal:2', (new TemplateScholasticComponent())->getCasts()['weightage_percent'] ?? null);
        $this->assertSame('bool', (new TemplateExamWeightage())->getCasts()['is_active'] ?? null);
        $this->assertSame('integer', (new TemplateIaComponent())->getCasts()['display_order'] ?? null);
        $this->assertSame('bool', (new TemplateCoscholasticComponent())->getCasts()['is_ba_linked'] ?? null);
    }

    public function test_components_06_request_rules_config_truth_and_sec_msh_003(): void
    {
        $sch = File::get(base_path(self::SCHOLASTIC_REQUEST_FILE));
        $this->assertStringContainsString("'exists:msh_config_templates,id'", $sch);
        $this->assertStringContainsString("'exists:msh_source_components,id'", $sch);
        $this->assertStringContainsString("'max:100'", $sch);
        $this->assertStringContainsString('The source component id has already been taken.', $sch);

        $exam = File::get(base_path(self::EXAM_REQUEST_FILE));
        $this->assertStringContainsString("'exists:lms_exam_types,id'", $exam);
        $this->assertStringContainsString('msh_template_exam_weightages', $exam);

        $ia = File::get(base_path(self::IA_REQUEST_FILE));
        $this->assertStringContainsString("'exists:msh_ia_component_types,id'", $ia);

        $cosc = File::get(base_path(self::COSCHOLASTIC_REQUEST_FILE));
        $this->assertStringContainsString('msh_template_coscholastic_components', $cosc);

        // SEC-MSH-003: every FormRequest authorize() returns true.
        foreach ([$sch, $exam, $ia, $cosc] as $content) {
            $this->assertMatchesRegularExpression(
                '/public function authorize\(\): bool\s*\{\s*return true;/',
                $content,
                'SEC-MSH-003: expected authorize() to return true.'
            );
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Band 10-19 — create + activity log
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_10_create_scholastic_persists_and_logs_stored(): void
    {
        $templateId = $this->configTemplateId();
        $sourceId = $this->createSourceComponentSeed()->id;

        $created = null;
        $this->run(function (Browser $browser) use ($templateId, $sourceId, &$created): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId,
                'weightage_percent' => 100, 'max_marks' => 80, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0));
            $created = TemplateScholasticComponent::where('config_template_id', $templateId)->where('source_component_id', $sourceId)->first();
        }, 'c10');

        $this->assertNotNull($created);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $created->id, 'Stored');
        $this->forceDeleteModel($created);
    }

    public function test_components_11_create_exam_weightage_persists_and_logs_stored(): void
    {
        $templateId = $this->configTemplateId();
        $examTypeId = $this->resolveExamTypeId();

        $created = null;
        $this->run(function (Browser $browser) use ($templateId, $examTypeId, &$created): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::EXAM_BASE, [
                'config_template_id' => $templateId, 'exam_type_id' => $examTypeId, 'weightage_percent' => 100, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0));
            $created = TemplateExamWeightage::where('config_template_id', $templateId)->where('exam_type_id', $examTypeId)->first();
        }, 'c11', 'exam-weightages');

        $this->assertNotNull($created);
        $this->assertActivityIssuedByAdmin(TemplateExamWeightage::class, (int) $created->id, 'Stored');
        $this->forceDeleteModel($created);
    }

    public function test_components_12_create_ia_component_persists_and_logs_stored(): void
    {
        $templateId = $this->configTemplateId();
        $iaTypeId = $this->createIaComponentTypeSeed()->id;

        $created = null;
        $this->run(function (Browser $browser) use ($templateId, $iaTypeId, &$created): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::IA_BASE, [
                'config_template_id' => $templateId, 'ia_component_type_id' => $iaTypeId,
                'max_marks' => 5, 'display_order' => 2, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0));
            $created = TemplateIaComponent::where('config_template_id', $templateId)->where('ia_component_type_id', $iaTypeId)->first();
        }, 'c12', 'ia-components');

        $this->assertNotNull($created);
        $this->assertSame(2, (int) $created->display_order);
        $this->assertActivityIssuedByAdmin(TemplateIaComponent::class, (int) $created->id, 'Stored');
        $this->forceDeleteModel($created);
    }

    public function test_components_13_create_coscholastic_persists_grading_and_logs_stored(): void
    {
        $templateId = $this->configTemplateId();
        $code = 'CO' . substr($this->uniqueSuffix(), -4);

        $created = null;
        $this->run(function (Browser $browser) use ($templateId, $code, &$created): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::COSCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'name' => 'Art Education ' . $code, 'code' => $code,
                'grading_scale' => '5_POINT', 'is_ba_linked' => 1, 'display_order' => 1, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0));
            $created = TemplateCoscholasticComponent::where('config_template_id', $templateId)->where('code', $code)->first();
        }, 'c13', 'coscholastic-components');

        $this->assertNotNull($created);
        $this->assertSame('5_POINT', (string) $created->grading_scale);
        $this->assertTrue((bool) $created->is_ba_linked, 'is_ba_linked flag was not persisted.');
        $this->assertActivityIssuedByAdmin(TemplateCoscholasticComponent::class, (int) $created->id, 'Stored');
        $this->forceDeleteModel($created);
    }

    public function test_components_14_scholastic_max_marks_nullable_is_accepted(): void
    {
        $templateId = $this->configTemplateId();
        $sourceId = $this->createSourceComponentSeed()->id;

        $this->run(function (Browser $browser) use ($templateId, $sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 100, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0), 'Scholastic create without max_marks should be accepted (nullable).');
        }, 'c14');

        $row = TemplateScholasticComponent::where('config_template_id', $templateId)->where('source_component_id', $sourceId)->first();
        $this->assertNotNull($row);
        $this->assertNull($row->max_marks);
        $this->forceDeleteModel($row);
    }

    public function test_components_15_coscholastic_defaults_ba_linked_false(): void
    {
        $templateId = $this->configTemplateId();
        $code = 'CB' . substr($this->uniqueSuffix(), -4);

        $this->run(function (Browser $browser) use ($templateId, $code): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::COSCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'name' => 'Discipline ' . $code, 'code' => $code,
                'grading_scale' => '3_POINT', 'display_order' => 1, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0));
        }, 'c15', 'coscholastic-components');

        $row = TemplateCoscholasticComponent::where('config_template_id', $templateId)->where('code', $code)->first();
        $this->assertNotNull($row);
        $this->assertFalse((bool) $row->is_ba_linked, 'is_ba_linked should default to false when omitted.');
        $this->forceDeleteModel($row);
    }

    // ════════════════════════════════════════════════════════════════════════
    // Band 30-39 — validation (negative)
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_30_scholastic_required_fields_rejected(): void
    {
        $this->run(function (Browser $browser): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, []);
            $this->assertSame(422, (int) ($r['status'] ?? 0));
            $errors = $this->validationErrors($r);
            $this->assertArrayHasKey('config_template_id', $errors);
            $this->assertArrayHasKey('source_component_id', $errors);
            $this->assertArrayHasKey('weightage_percent', $errors);
        }, 'c30');
    }

    public function test_components_31_scholastic_weightage_over_100_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->run(function (Browser $browser) use ($templateId, $sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 150, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0));
            $this->assertArrayHasKey('weightage_percent', $this->validationErrors($r));
        }, 'c31');
    }

    public function test_components_32_scholastic_negative_weightage_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->run(function (Browser $browser) use ($templateId, $sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => -5, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0), 'Negative weightage_percent should be rejected (min:0).');
            $this->assertArrayHasKey('weightage_percent', $this->validationErrors($r));
        }, 'c32');
    }

    public function test_components_33_scholastic_non_numeric_weightage_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->run(function (Browser $browser) use ($templateId, $sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 'abc', 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0), 'Non-numeric weightage_percent should be rejected.');
            $this->assertArrayHasKey('weightage_percent', $this->validationErrors($r));
        }, 'c33');
    }

    public function test_components_34_scholastic_weightage_more_than_two_decimals_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->run(function (Browser $browser) use ($templateId, $sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 12.345, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0), 'weightage_percent with 3 decimals should be rejected (regex 2dp).');
            $this->assertArrayHasKey('weightage_percent', $this->validationErrors($r));
        }, 'c34');
    }

    public function test_components_35_scholastic_duplicate_component_rejected_with_message(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 40]);

        $this->run(function (Browser $browser) use ($templateId, $sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 30, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0));
            $this->assertTrue(
                str_contains((string) ($r['body'] ?? ''), 'The source component id has already been taken.'),
                'Expected exact duplicate message not found.'
            );
        }, 'c35');

        $this->assertSame(1, TemplateScholasticComponent::where('config_template_id', $templateId)->where('source_component_id', $sourceId)->count());
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_36_exam_weightage_required_duplicate_and_range(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $examTypeId = $this->resolveExamTypeId();
        $this->createExamWeightageSeed($templateId, $examTypeId, ['weightage_percent' => 50]);

        $this->run(function (Browser $browser) use ($templateId, $examTypeId): void {
            // required
            $r1 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::EXAM_BASE, []);
            $this->assertSame(422, (int) ($r1['status'] ?? 0));
            $this->assertArrayHasKey('config_template_id', $this->validationErrors($r1));

            // duplicate exam_type within template
            $r2 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::EXAM_BASE, [
                'config_template_id' => $templateId, 'exam_type_id' => $examTypeId, 'weightage_percent' => 20, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r2['status'] ?? 0), 'Duplicate exam_type in template should be rejected.');
            $this->assertArrayHasKey('exam_type_id', $this->validationErrors($r2));

            // over 100
            $r3 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::EXAM_BASE, [
                'config_template_id' => $templateId, 'exam_type_id' => $examTypeId, 'weightage_percent' => 130, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r3['status'] ?? 0), 'weightage_percent > 100 should be rejected.');
        }, 'c36', 'exam-weightages');

        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_37_ia_component_required_and_display_order_min(): void
    {
        $templateId = $this->configTemplateId();
        $iaTypeId = $this->createIaComponentTypeSeed()->id;

        $this->run(function (Browser $browser) use ($templateId, $iaTypeId): void {
            $r1 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::IA_BASE, []);
            $this->assertSame(422, (int) ($r1['status'] ?? 0));
            $errors = $this->validationErrors($r1);
            $this->assertArrayHasKey('ia_component_type_id', $errors);
            $this->assertArrayHasKey('max_marks', $errors);

            // display_order min:1 (0 -> prepareForValidation coerces falsy to 1, so send explicit -1)
            $r2 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::IA_BASE, [
                'config_template_id' => $templateId, 'ia_component_type_id' => $iaTypeId, 'max_marks' => 5, 'display_order' => -1, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r2['status'] ?? 0), 'display_order below 1 should be rejected.');
            $this->assertArrayHasKey('display_order', $this->validationErrors($r2));
        }, 'c37', 'ia-components');
    }

    public function test_components_38_coscholastic_required_fields_rejected(): void
    {
        $this->run(function (Browser $browser): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::COSCHOLASTIC_BASE, []);
            $this->assertSame(422, (int) ($r['status'] ?? 0));
            $errors = $this->validationErrors($r);
            $this->assertArrayHasKey('config_template_id', $errors);
            $this->assertArrayHasKey('name', $errors);
            $this->assertArrayHasKey('code', $errors);
        }, 'c38', 'coscholastic-components');
    }

    public function test_components_39_coscholastic_duplicate_code_rejected(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $code = 'DUP' . substr($this->uniqueSuffix(), -4);
        $this->createCoscholasticSeed($templateId, $code);

        $this->run(function (Browser $browser) use ($templateId, $code): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::COSCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'name' => 'Another ' . $code, 'code' => $code,
                'grading_scale' => '3_POINT', 'display_order' => 1, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0), 'Duplicate coscholastic code within template should be rejected.');
            $this->assertArrayHasKey('code', $this->validationErrors($r));
        }, 'c39', 'coscholastic-components');

        $this->assertSame(1, TemplateCoscholasticComponent::where('config_template_id', $templateId)->where('code', $code)->count());
        $this->forceDeleteConfigTemplate($templateId);
    }

    // ════════════════════════════════════════════════════════════════════════
    // Band 40-49 — integration / FK
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_40_scholastic_invalid_config_template_rejected(): void
    {
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->run(function (Browser $browser) use ($sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => 999999999, 'source_component_id' => $sourceId, 'weightage_percent' => 10, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0));
            $this->assertArrayHasKey('config_template_id', $this->validationErrors($r));
        }, 'c40');
    }

    public function test_components_41_scholastic_invalid_source_component_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $this->run(function (Browser $browser) use ($templateId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => 999999999, 'weightage_percent' => 10, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0));
            $this->assertArrayHasKey('source_component_id', $this->validationErrors($r));
        }, 'c41');
    }

    public function test_components_42_exam_invalid_exam_type_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $this->run(function (Browser $browser) use ($templateId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::EXAM_BASE, [
                'config_template_id' => $templateId, 'exam_type_id' => 999999999, 'weightage_percent' => 10, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0));
            $this->assertArrayHasKey('exam_type_id', $this->validationErrors($r));
        }, 'c42', 'exam-weightages');
    }

    public function test_components_43_ia_invalid_component_type_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $this->run(function (Browser $browser) use ($templateId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::IA_BASE, [
                'config_template_id' => $templateId, 'ia_component_type_id' => 999999999, 'max_marks' => 5, 'display_order' => 1, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0));
            $this->assertArrayHasKey('ia_component_type_id', $this->validationErrors($r));
        }, 'c43', 'ia-components');
    }

    public function test_components_44_config_template_cascade_removes_children(): void
    {
        // BC-REF: FK config_template_id ON DELETE CASCADE — hard-deleting the
        // parent template removes its scholastic component rows.
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100]);
        $rowId = (int) $row->id;

        try {
            ConfigTemplate::withTrashed()->whereKey($templateId)->forceDelete();
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not hard-delete config template for cascade test: ' . $e->getMessage());
        }

        $this->assertFalse(
            TemplateScholasticComponent::withTrashed()->whereKey($rowId)->exists(),
            'BC-REF CASCADE: scholastic child row should be removed when its template is hard-deleted.'
        );
    }

    public function test_components_45_source_component_restrict_blocks_delete_while_referenced(): void
    {
        // BC-REF: FK source_component_id ON DELETE RESTRICT — a source component
        // referenced by a scholastic row cannot be hard-deleted.
        $templateId = $this->createConfigTemplateSeed()->id;
        $source = $this->createSourceComponentSeed();
        $this->createScholasticSeed($templateId, (int) $source->id, ['weightage_percent' => 100]);

        $blocked = false;
        try {
            $source->forceDelete();
        } catch (\Illuminate\Database\QueryException $e) {
            $blocked = true;
        } catch (Throwable) {
            $blocked = true;
        }

        $this->assertTrue($blocked, 'RESTRICT: deleting a referenced source component should be blocked by the FK.');
        $this->forceDeleteConfigTemplate($templateId);
    }

    // ════════════════════════════════════════════════════════════════════════
    // Band 50-59 — authorization / security
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('c50-guest', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::COMPONENTS_PATH))->pause(1200);
            $this->assertTrue(
                str_contains($this->currentPath($browser), '/login'),
                'Guest was not redirected to /login.'
            );
        });
    }

    public function test_components_51_sec_msh_003_all_requests_authorize_true(): void
    {
        foreach ([
            self::SCHOLASTIC_REQUEST_FILE,
            self::EXAM_REQUEST_FILE,
            self::IA_REQUEST_FILE,
            self::COSCHOLASTIC_REQUEST_FILE,
        ] as $file) {
            $content = File::get(base_path($file));
            $this->assertMatchesRegularExpression(
                '/public function authorize\(\): bool\s*\{\s*return true;/',
                $content,
                'SEC-MSH-003: ' . $file . ' should have authorize() returning true.'
            );
        }
    }

    public function test_components_52_controller_enforces_gate_on_store(): void
    {
        // Authorization is enforced only in the controller (Gate::authorize),
        // not the FormRequest. Confirm the create gate string is present.
        $controller = File::get(base_path(self::SCHOLASTIC_CONTROLLER_FILE));
        $this->assertStringContainsString(
            "Gate::authorize('tenant.msh-template-scholastic-component.create')",
            $controller,
            'Store gate string missing from controller.'
        );
        $this->assertStringContainsString(
            "Gate::authorize('tenant.msh-template-scholastic-component.update')",
            $controller
        );
    }

    // ════════════════════════════════════════════════════════════════════════
    // Band 60-69 — UI / UX
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_60_page_renders_four_tabs(): void
    {
        $this->run(function (Browser $browser): void {
            $source = $browser->driver->getPageSource();
            foreach (['scholastic-components', 'exam-weightages', 'ia-components', 'coscholastic-components'] as $tab) {
                $this->assertTrue(str_contains($source, $tab), "Tab pane {$tab} not rendered.");
            }
        }, 'c60');
    }

    public function test_components_61_created_scholastic_row_is_listed(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $source = $this->createSourceComponentSeed();
        $this->createScholasticSeed($templateId, (int) $source->id, ['weightage_percent' => 100]);

        $this->browseWithFailureScreenshot('c61-listed', function (Browser $browser) use ($source): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser, 'scholastic-components');
            $this->assertTrue(
                str_contains($browser->driver->getPageSource(), (string) $source->name),
                'Newly created scholastic component (via its source name) is not listed.'
            );
        });

        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_62_coscholastic_search_filter_matches_code(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $code = 'SR' . substr($this->uniqueSuffix(), -4);
        $this->createCoscholasticSeed($templateId, $code, 'Health And PE ' . $code);

        $this->browseWithFailureScreenshot('c62-search', function (Browser $browser) use ($code): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMPONENTS_PATH . '?tab=coscholastic-components&search=' . urlencode($code), 1000);
            $this->assertTrue(
                str_contains($browser->driver->getPageSource(), $code),
                'Co-scholastic search by code did not return the matching row.'
            );
        });

        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_63_component_lists_use_independent_page_params(): void
    {
        // The combined controller paginates each tab with a distinct page name.
        $controller = File::get(base_path('Modules/MarksheetGeneration/app/Http/Controllers/MarksheetGenerationController.php'));
        foreach (['sc_page', 'ew_page', 'ia_page', 'cc_page'] as $param) {
            $this->assertStringContainsString("'{$param}'", $controller, "Pagination page param {$param} missing from components().");
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Band 70-79 — edge cases / security
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_70_scholastic_zero_weightage_boundary_accepted(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->run(function (Browser $browser) use ($templateId, $sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 0, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0), 'weightage 0 (min boundary) should be accepted.');
        }, 'c70');
        $this->assertTrue(TemplateScholasticComponent::where('config_template_id', $templateId)->where('source_component_id', $sourceId)->exists());
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_71_scholastic_exactly_100_boundary_accepted(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->run(function (Browser $browser) use ($templateId, $sourceId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 100, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0), 'weightage 100 (max boundary) should be accepted.');
        }, 'c71');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_72_coscholastic_arbitrary_grading_scale_accepted_defect(): void
    {
        // BUG-MSH-C04: grading_scale has no `in:` enum rule (only string|max:50),
        // so an out-of-spec value ("NONSENSE_SCALE") is accepted and persisted,
        // even though the DDL only documents 3_POINT / 5_POINT.
        $templateId = $this->createConfigTemplateSeed()->id;
        $code = 'GS' . substr($this->uniqueSuffix(), -4);

        $this->run(function (Browser $browser) use ($templateId, $code): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::COSCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'name' => 'Odd Scale ' . $code, 'code' => $code,
                'grading_scale' => 'NONSENSE_SCALE', 'display_order' => 1, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0), 'BUG-MSH-C04: arbitrary grading_scale should currently be accepted.');
        }, 'c72', 'coscholastic-components');

        $row = TemplateCoscholasticComponent::where('config_template_id', $templateId)->where('code', $code)->first();
        $this->assertNotNull($row);
        $this->assertSame('NONSENSE_SCALE', (string) $row->grading_scale, 'Arbitrary grading_scale was not persisted (defect may be fixed).');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_73_coscholastic_xss_payload_is_escaped_in_listing(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $code = 'XS' . substr($this->uniqueSuffix(), -4);
        $xssName = "<script>alert('msh-xss')</script>" . $code;

        $this->run(function (Browser $browser) use ($templateId, $code, $xssName): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::COSCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'name' => $xssName, 'code' => $code,
                'grading_scale' => '3_POINT', 'display_order' => 1, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0));

            $this->openComponentsPage($browser, 'coscholastic-components');
            $source = $browser->driver->getPageSource();
            $this->assertFalse(
                str_contains($source, "<script>alert('msh-xss')</script>"),
                'Stored XSS: raw <script> payload should be HTML-escaped in the listing.'
            );
        }, 'c73', 'coscholastic-components');

        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_74_scholastic_show_invalid_id_returns_404(): void
    {
        $this->run(function (Browser $browser): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'GET', self::SCHOLASTIC_BASE . '/999999999', []);
            $this->assertSame(404, (int) ($r['status'] ?? 0));
        }, 'c74');
    }

    public function test_components_75_coscholastic_code_length_over_30_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $this->run(function (Browser $browser) use ($templateId): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::COSCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'name' => 'Long Code', 'code' => str_repeat('X', 31),
                'grading_scale' => '3_POINT', 'display_order' => 1, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($r['status'] ?? 0), 'code longer than 30 chars should be rejected (max:30).');
            $this->assertArrayHasKey('code', $this->validationErrors($r));
        }, 'c75', 'coscholastic-components');
    }

    // ════════════════════════════════════════════════════════════════════════
    // Band 80-89 — configuration rule (weightage sum) + defects
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_80_scholastic_sum_not_validated_on_create_defect(): void
    {
        // BUG-MSH-C01 / BR-MSG-002.
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceA = $this->createSourceComponentSeed()->id;
        $sourceB = $this->createSourceComponentSeed()->id;

        $this->run(function (Browser $browser) use ($templateId, $sourceA, $sourceB): void {
            $r1 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceA, 'weightage_percent' => 40, 'is_active' => 1,
            ]);
            $r2 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceB, 'weightage_percent' => 40, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r1['status'] ?? 0));
            $this->assertSame(200, (int) ($r2['status'] ?? 0), 'BUG-MSH-C01: create must not validate the 100% sum.');
        }, 'c80');

        $sum = (float) TemplateScholasticComponent::where('config_template_id', $templateId)->sum('weightage_percent');
        $this->assertEqualsWithDelta(80.0, $sum, 0.01, 'Expected a non-100 sum (80) to persist — proving create is unvalidated.');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_81_scholastic_update_breaking_sum_returns_500_and_rolls_back(): void
    {
        // BUG-MSH-C03: sum enforced on update via service, but surfaces as 500.
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100]);

        $this->run(function (Browser $browser) use ($row): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'PUT', self::SCHOLASTIC_BASE . '/' . $row->id, [
                'config_template_id' => (int) $row->config_template_id,
                'source_component_id' => (int) $row->source_component_id,
                'weightage_percent' => 55, 'is_active' => 1,
            ]);
            $this->assertSame(500, (int) ($r['status'] ?? 0), 'BUG-MSH-C03: sum violation on update should surface as HTTP 500, not 422.');
        }, 'c81');

        $row->refresh();
        $this->assertSame('100.00', (string) $row->weightage_percent, 'Transaction should have rolled back the invalid update.');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_82_exam_weightage_sum_never_enforced_defect(): void
    {
        // BUG-MSH-C02 / BR-MSG-003: exam weightage sum validation is dead code —
        // create AND update accept a non-100 sum.
        $templateId = $this->createConfigTemplateSeed()->id;
        $examTypeId = $this->resolveExamTypeId();
        $second = $this->secondExamTypeId($examTypeId);

        $this->run(function (Browser $browser) use ($templateId, $examTypeId, $second): void {
            $r1 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::EXAM_BASE, [
                'config_template_id' => $templateId, 'exam_type_id' => $examTypeId, 'weightage_percent' => 30, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r1['status'] ?? 0));

            if ($second !== null) {
                $r2 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::EXAM_BASE, [
                    'config_template_id' => $templateId, 'exam_type_id' => $second, 'weightage_percent' => 30, 'is_active' => 1,
                ]);
                $this->assertSame(200, (int) ($r2['status'] ?? 0), 'BUG-MSH-C02: exam weightage sum must not be validated.');
            }
        }, 'c82', 'exam-weightages');

        $sum = (float) TemplateExamWeightage::where('config_template_id', $templateId)->sum('weightage_percent');
        $this->assertLessThan(100.0, $sum, 'Expected a non-100 exam-weightage sum to persist (validation never runs).');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_83_exam_weightage_validator_has_no_caller_defect(): void
    {
        // Static proof of BUG-MSH-C02: validateExamWeightageSum() is never wired
        // into the exam-weightage service or controller.
        $service = File::get(base_path(self::EXAM_SERVICE_FILE));
        $controller = File::get(base_path(self::EXAM_CONTROLLER_FILE));
        $this->assertStringNotContainsString('validateExamWeightageSum', $service, 'Exam service unexpectedly calls the sum validator.');
        $this->assertStringNotContainsString('validateExamWeightageSum', $controller, 'Exam controller unexpectedly calls the sum validator.');
    }

    public function test_components_84_scholastic_update_keeping_sum_logs_updated(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100, 'max_marks' => 70]);

        $this->run(function (Browser $browser) use ($row): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'PUT', self::SCHOLASTIC_BASE . '/' . $row->id, [
                'config_template_id' => (int) $row->config_template_id,
                'source_component_id' => (int) $row->source_component_id,
                'weightage_percent' => 100, 'max_marks' => 95, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0));
        }, 'c84');

        $row->refresh();
        $this->assertSame('95.00', (string) $row->max_marks);
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $row->id, 'Updated');
        $this->forceDeleteConfigTemplate($templateId);
    }

    // ════════════════════════════════════════════════════════════════════════
    // Band 90-99 — lifecycle & activity log
    // ════════════════════════════════════════════════════════════════════════

    public function test_components_90_scholastic_toggle_logs_toggled(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100, 'is_active' => true]);

        $this->run(function (Browser $browser) use ($row): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE . '/' . $row->id . '/toggleStatus', []);
            $this->assertSame(200, (int) ($r['status'] ?? 0));
            $json = is_array($r['json'] ?? null) ? $r['json'] : [];
            $this->assertTrue((bool) ($json['success'] ?? false));
        }, 'c90');

        $row->refresh();
        $this->assertFalse((bool) $row->is_active);
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $row->id, 'Toggled');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_91_scholastic_delete_restore_force_delete_lifecycle(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100]);

        $this->run(function (Browser $browser) use ($row): void {
            $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::SCHOLASTIC_BASE . '/' . $row->id, []);
        }, 'c91-delete');
        $this->assertNotNull(TemplateScholasticComponent::withTrashed()->whereKey($row->id)->first()?->deleted_at, 'Not soft-deleted.');
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $row->id, 'Deleted');

        $this->run(function (Browser $browser) use ($row): void {
            $this->sendJsonRequestFromBrowser($browser, 'GET', self::SCHOLASTIC_BASE . '/' . $row->id . '/restore', []);
        }, 'c91-restore');
        $this->assertNull(TemplateScholasticComponent::withTrashed()->whereKey($row->id)->first()?->deleted_at, 'Not restored.');
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $row->id, 'Restored');

        $this->run(function (Browser $browser) use ($row): void {
            $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::SCHOLASTIC_BASE . '/' . $row->id . '/force-delete', []);
        }, 'c91-force');
        $this->assertFalse(TemplateScholasticComponent::withTrashed()->whereKey($row->id)->exists(), 'Still present after force delete.');

        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_92_exam_weightage_delete_logs_deleted(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $examTypeId = $this->resolveExamTypeId();
        $row = $this->createExamWeightageSeed($templateId, $examTypeId, ['weightage_percent' => 100]);

        $this->run(function (Browser $browser) use ($row): void {
            $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::EXAM_BASE . '/' . $row->id, []);
        }, 'c92', 'exam-weightages');

        $this->assertNotNull(TemplateExamWeightage::withTrashed()->whereKey($row->id)->first()?->deleted_at, 'Exam weightage not soft-deleted.');
        $this->assertActivityIssuedByAdmin(TemplateExamWeightage::class, (int) $row->id, 'Deleted');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_93_coscholastic_update_logs_updated(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $code = 'UP' . substr($this->uniqueSuffix(), -4);
        $row = $this->createCoscholasticSeed($templateId, $code, 'Original ' . $code);

        $this->run(function (Browser $browser) use ($row, $code): void {
            $r = $this->sendJsonRequestFromBrowser($browser, 'PUT', self::COSCHOLASTIC_BASE . '/' . $row->id, [
                'config_template_id' => (int) $row->config_template_id,
                'name' => 'Renamed ' . $code, 'code' => $code,
                'grading_scale' => '5_POINT', 'display_order' => 2, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r['status'] ?? 0));
        }, 'c93', 'coscholastic-components');

        $row->refresh();
        $this->assertSame('Renamed ' . $code, (string) $row->name);
        $this->assertSame('5_POINT', (string) $row->grading_scale);
        $this->assertActivityIssuedByAdmin(TemplateCoscholasticComponent::class, (int) $row->id, 'Updated');
        $this->forceDeleteConfigTemplate($templateId);
    }

    // ========================================================================
    // Private helper library
    // ========================================================================

    /** Convenience wrapper: authenticate, open the components page, run assertions. */
    private function run(callable $callback, string $caseName, ?string $tab = null): void
    {
        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($callback, $tab): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser, $tab);
            $callback($browser);
        });
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
        $rawName = 'components-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'components-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function openComponentsPage(Browser $browser, ?string $tab = null): void
    {
        $path = self::COMPONENTS_PATH;
        if ($tab !== null && $tab !== '') {
            $path .= '?tab=' . urlencode($tab);
        }
        $this->visitAuthenticated($browser, $path, 900);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return str_contains($browser->driver->getPageSource(), 'scholastic-components')
                || $browser->element('form.ajax-form') !== null;
        }, 'Components page did not load.');
    }

    private function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): array
    {
        $encodedMethod = json_encode(strtoupper($method), JSON_THROW_ON_ERROR);
        $encodedUrl = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
window.__mshApiDone = false;
window.__mshApiError = '';
window.__mshApiResult = null;

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
        try {
            json = body ? JSON.parse(body) : null;
        } catch (_error) {
            json = null;
        }

        window.__mshApiResult = { status: response.status, ok: response.ok, body, json };
    } catch (error) {
        window.__mshApiError = String(error);
    } finally {
        window.__mshApiDone = true;
    }
})();
JS);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__mshApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__mshApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__mshApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        return is_array($response) ? $response : [];
    }

    private function validationErrors(array $response): array
    {
        $json = is_array($response['json'] ?? null) ? $response['json'] : [];
        $errors = $json['errors'] ?? [];
        return is_array($errors) ? $errors : [];
    }

    private function assertActivityIssuedByAdmin(string $subjectClass, int $subjectId, string $event): void
    {
        $log = ActivityLog::query()
            ->where('subject_type', $subjectClass)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->latest('id')
            ->first();

        $this->assertNotNull($log, 'Activity log not found for event: ' . $event . ' on ' . $subjectClass);
        $this->assertNotNull($this->adminUser, 'Admin user is not resolved for activity verification.');
        $this->assertSame((int) $this->adminUser->id, (int) $log->user_id, 'Issued-by user_id mismatch for event: ' . $event);
    }

    // ---- dependency resolution ------------------------------------------------

    private function configTemplateId(): int
    {
        if ($this->sharedTemplateId !== null) {
            return $this->sharedTemplateId;
        }
        $existing = ConfigTemplate::where('is_active', 1)->orderBy('id')->value('id');
        if ($existing !== null) {
            return $this->sharedTemplateId = (int) $existing;
        }
        return $this->sharedTemplateId = (int) $this->createConfigTemplateSeed()->id;
    }

    private function createConfigTemplateSeed(): ConfigTemplate
    {
        $sessionId = $this->resolveAcademicSessionId();
        $marksheetTypeId = $this->resolveMarksheetTypeId();
        $examGroupId = $this->resolveExamGroupId($sessionId);
        $suffix = substr($this->uniqueSuffix(), -6);

        try {
            return ConfigTemplate::create([
                'academic_session_id' => $sessionId,
                'marksheet_type_id' => $marksheetTypeId,
                'exam_group_id' => $examGroupId,
                'grading_schema_id' => null,
                'code' => 'CFGT' . $suffix,
                'name' => 'Test Config Template ' . $suffix,
                'passing_percentage' => 33.00,
                'compartment_max_failures' => 2,
                'is_locked' => 0,
                'is_active' => 1,
                'created_by' => (int) $this->adminUser->id,
            ]);
        } catch (Throwable $e) {
            $this->markTestSkipped('Unable to seed a config template (FK deps unavailable): ' . $e->getMessage());
        }
    }

    private function resolveAcademicSessionId(): int
    {
        $id = OrgAcademicSession::current()?->id
            ?? OrgAcademicSession::query()->value('id')
            ?? DB::table('sch_org_academic_sessions_jnt')->value('id');
        if ($id === null) {
            $this->markTestSkipped('No academic session available for config template seed.');
        }
        return (int) $id;
    }

    private function resolveMarksheetTypeId(): int
    {
        $id = MarksheetType::query()->value('id');
        if ($id !== null) {
            return (int) $id;
        }
        try {
            return (int) MarksheetType::create([
                'code' => 'MT' . substr($this->uniqueSuffix(), -5),
                'name' => 'Test Marksheet Type ' . substr($this->uniqueSuffix(), -4),
                'display_order' => 1, 'is_active' => 1, 'created_by' => (int) $this->adminUser->id,
            ])->id;
        } catch (Throwable $e) {
            $this->markTestSkipped('Unable to resolve/seed marksheet type: ' . $e->getMessage());
        }
    }

    private function resolveExamGroupId(int $sessionId): int
    {
        $id = ExamGroup::query()->where('academic_session_id', $sessionId)->value('id')
            ?? ExamGroup::query()->value('id');
        if ($id !== null) {
            return (int) $id;
        }
        try {
            return (int) ExamGroup::create([
                'academic_session_id' => $sessionId,
                'code' => 'EG' . substr($this->uniqueSuffix(), -5),
                'name' => 'Test Exam Group ' . substr($this->uniqueSuffix(), -4),
                'is_active' => 1, 'created_by' => (int) $this->adminUser->id,
            ])->id;
        } catch (Throwable $e) {
            $this->markTestSkipped('Unable to resolve/seed exam group: ' . $e->getMessage());
        }
    }

    private function resolveExamTypeId(): int
    {
        try {
            $id = DB::table('lms_exam_types')->where('is_active', 1)->value('id')
                ?? DB::table('lms_exam_types')->value('id');
        } catch (Throwable) {
            $id = null;
        }
        if ($id === null) {
            $this->markTestSkipped('No lms_exam_types row available for exam-weightage tests.');
        }
        return (int) $id;
    }

    private function secondExamTypeId(int $exclude): ?int
    {
        try {
            $id = DB::table('lms_exam_types')->where('id', '!=', $exclude)->value('id');
        } catch (Throwable) {
            $id = null;
        }
        return $id === null ? null : (int) $id;
    }

    private function createSourceComponentSeed(): SourceComponent
    {
        return SourceComponent::create([
            'code' => 'SRC' . substr($this->uniqueSuffix(), -6),
            'name' => 'Source ' . substr($this->uniqueSuffix(), -4),
            'is_mandatory' => 0, 'display_order' => 1, 'is_active' => 1,
            'created_by' => (int) $this->adminUser->id,
        ]);
    }

    private function createIaComponentTypeSeed(): IaComponentType
    {
        return IaComponentType::create([
            'code' => 'IAT' . substr($this->uniqueSuffix(), -6),
            'name' => 'IA Type ' . substr($this->uniqueSuffix(), -4),
            'display_order' => 1, 'is_active' => 1, 'created_by' => (int) $this->adminUser->id,
        ]);
    }

    private function createScholasticSeed(int $templateId, int $sourceId, array $overrides = []): TemplateScholasticComponent
    {
        return TemplateScholasticComponent::create(array_merge([
            'config_template_id' => $templateId,
            'source_component_id' => $sourceId,
            'weightage_percent' => 100,
            'max_marks' => 80,
            'is_active' => true,
            'created_by' => (int) $this->adminUser->id,
        ], $overrides));
    }

    private function createExamWeightageSeed(int $templateId, int $examTypeId, array $overrides = []): TemplateExamWeightage
    {
        return TemplateExamWeightage::create(array_merge([
            'config_template_id' => $templateId,
            'exam_type_id' => $examTypeId,
            'weightage_percent' => 100,
            'is_active' => true,
            'created_by' => (int) $this->adminUser->id,
        ], $overrides));
    }

    private function createCoscholasticSeed(int $templateId, string $code, ?string $name = null): TemplateCoscholasticComponent
    {
        return TemplateCoscholasticComponent::create([
            'config_template_id' => $templateId,
            'name' => $name ?? ('Co-scholastic ' . $code),
            'code' => $code,
            'grading_scale' => '3_POINT',
            'is_ba_linked' => false,
            'display_order' => 1,
            'is_active' => true,
            'created_by' => (int) $this->adminUser->id,
        ]);
    }

    private function forceDeleteModel(?object $model): void
    {
        if (!$model) {
            return;
        }
        try {
            $model->forceDelete();
        } catch (Throwable) {
        }
    }

    private function forceDeleteConfigTemplate(int $templateId): void
    {
        try {
            TemplateScholasticComponent::withTrashed()->where('config_template_id', $templateId)->forceDelete();
            TemplateExamWeightage::withTrashed()->where('config_template_id', $templateId)->forceDelete();
            TemplateIaComponent::withTrashed()->where('config_template_id', $templateId)->forceDelete();
            TemplateCoscholasticComponent::withTrashed()->where('config_template_id', $templateId)->forceDelete();
        } catch (Throwable) {
        }

        if ($this->sharedTemplateId === $templateId) {
            return;
        }

        try {
            ConfigTemplate::withTrashed()->whereKey($templateId)->forceDelete();
        } catch (Throwable) {
        }
    }

    // ---- auth / tenancy / permissions ----------------------------------------

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
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
            ?? User::query()->first();

        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for Dusk login.');
        }

        if ($this->adminUser->getAttribute('email_verified_at') === null) {
            $this->adminUser->forceFill(['email_verified_at' => now()])->save();
        }

        $this->grantComponentPermissions($this->adminUser);
    }

    private function grantComponentPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }

        $entities = [
            'template-scholastic-component',
            'template-exam-weightage',
            'template-ia-component',
            'template-coscholastic-component',
        ];
        $abilities = ['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'];

        $permissions = ['tenant.msh-components.view', 'tenant.msh-configuration.view', 'tenant.msh-dashboard.view'];
        foreach ($entities as $entity) {
            foreach ($abilities as $ability) {
                $permissions[] = "tenant.msh-{$entity}.{$ability}";
            }
        }

        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist($permissions, $guard);
        $this->syncComponentRoleWithPermissions($user, $permissions, $guard);

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

    private function syncComponentRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.msh-components-admin');
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

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(1000, 9999);
    }
}
