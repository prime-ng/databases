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
 * MarksheetGeneration — Components & Weightages (V1 foundation suite).
 *
 * Screen: Components & Weightages (combined tabbed page, four entities).
 *   Route : GET /marksheet-generation/components  (marksheet-generation.components.combined)
 *   Ctrl  : MarksheetGenerationController::components()  (Gate tenant.msh-components.view)
 *
 * Entities exercised (all tenant-side, prefix msh_):
 *   - template-scholastic-component  (PRIMARY, msh_template_scholastic_components, BR-MSG-002 sum=100)
 *   - template-exam-weightage        (msh_template_exam_weightages, BR-MSG-003 sum=100)
 *   - template-ia-component          (msh_template_ia_components)
 *   - template-coscholastic-component(msh_template_coscholastic_components)
 *
 * Style: browser Dusk (golden Class reference). No committed MSH sibling exists.
 * Obeys 05_Known_Test_Failure_Constraints.md (tenant init, App\Models\User factory,
 * SoftDeletes guarded, forceDelete wrapped, typed props initialised, no Dusk assertStatus).
 */
class msh_ComponentsAndWeightagesV1_TestCas extends DuskTestCase
{
    private const COMPONENTS_PATH = '/marksheet-generation/components';

    private const SCHOLASTIC_BASE = '/marksheet-generation/template-scholastic-component';
    private const EXAM_BASE        = '/marksheet-generation/template-exam-weightage';
    private const IA_BASE          = '/marksheet-generation/template-ia-component';
    private const COSCHOLASTIC_BASE = '/marksheet-generation/template-coscholastic-component';

    private const MIGRATION_FILE = 'database/migrations/tenant/2026_06_16_115739_create_msh_template_scholastic_components_table.php';
    private const REQUEST_FILE   = 'Modules/MarksheetGeneration/app/Http/Requests/TemplateScholasticComponentRequest.php';
    private const SERVICE_FILE   = 'Modules/MarksheetGeneration/app/Services/TemplateScholasticComponentService.php';
    private const CONFIG_SERVICE_FILE = 'Modules/MarksheetGeneration/app/Services/MarksheetConfigService.php';
    private const CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/TemplateScholasticComponentController.php';

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

    // ── Band 01-09: schema / model / request configuration ──────────────────

    public function test_components_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(
            Schema::hasTable('msh_template_scholastic_components'),
            'Table msh_template_scholastic_components does not exist.'
        );
        $this->assertTrue(
            Schema::hasColumns('msh_template_scholastic_components', [
                'id',
                'config_template_id',
                'source_component_id',
                'weightage_percent',
                'max_marks',
                'is_active',
                'created_by',
                'updated_by',
                'created_at',
                'updated_at',
                'deleted_at',
            ]),
            'Expected columns missing in msh_template_scholastic_components.'
        );

        $migrationPath = base_path(self::MIGRATION_FILE);
        $this->assertTrue(File::exists($migrationPath), 'Migration file not found: ' . self::MIGRATION_FILE);

        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('msh_template_scholastic_components'", $migration);
        $this->assertStringContainsString("\$table->decimal('weightage_percent', 5, 2)", $migration);
        $this->assertStringContainsString("\$table->decimal('max_marks', 8, 2)->nullable()", $migration);
        $this->assertStringContainsString("->onDelete('cascade')", $migration);
        $this->assertStringContainsString("unique(['config_template_id', 'source_component_id']", $migration);
        $this->assertStringContainsString('$table->softDeletes()', $migration);

        $driver = DB::connection()->getDriverName();
        if ($driver === 'mysql') {
            $uniqueComposite = DB::select(
                "SHOW INDEX FROM msh_template_scholastic_components WHERE Key_name = 'uq_msh_tsc_template_component'"
            );
            $this->assertNotEmpty($uniqueComposite, 'Composite unique index uq_msh_tsc_template_component missing.');
        }

        $requestPath = base_path(self::REQUEST_FILE);
        $this->assertTrue(File::exists($requestPath), 'Request file not found: ' . self::REQUEST_FILE);
        $request = File::get($requestPath);
        $this->assertStringContainsString("'exists:msh_config_templates,id'", $request);
        $this->assertStringContainsString("'exists:msh_source_components,id'", $request);
        $this->assertStringContainsString("'max:100'", $request);
        $this->assertStringContainsString("'regex:/^\\d+(\\.\\d{1,2})?$/'", $request);
        $this->assertStringContainsString('The source component id has already been taken.', $request);
        // SEC-MSH-003: FormRequest authorize() returns true (no request-layer authz).
        $this->assertStringContainsString('public function authorize(): bool', $request);
        $this->assertStringContainsString('return true;', $request);

        $model = new TemplateScholasticComponent();
        $this->assertSame('msh_template_scholastic_components', $model->getTable());
        $this->assertSame(
            [
                'config_template_id',
                'source_component_id',
                'weightage_percent',
                'max_marks',
                'is_active',
                'created_by',
                'updated_by',
            ],
            $model->getFillable()
        );
        $this->assertContains(SoftDeletes::class, class_uses_recursive(TemplateScholasticComponent::class));
        $this->assertInstanceOf(BelongsTo::class, $model->configTemplate());
        $this->assertInstanceOf(BelongsTo::class, $model->sourceComponent());
    }

    public function test_components_02_secondary_component_tables_and_models_are_configured(): void
    {
        // Exam weightage
        $this->assertTrue(Schema::hasTable('msh_template_exam_weightages'));
        $this->assertTrue(Schema::hasColumns('msh_template_exam_weightages', [
            'config_template_id', 'exam_type_id', 'weightage_percent', 'max_marks', 'is_active', 'deleted_at',
        ]));
        $exam = new TemplateExamWeightage();
        $this->assertSame('msh_template_exam_weightages', $exam->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(TemplateExamWeightage::class));
        $this->assertInstanceOf(BelongsTo::class, $exam->examType());

        // IA component
        $this->assertTrue(Schema::hasTable('msh_template_ia_components'));
        $this->assertTrue(Schema::hasColumns('msh_template_ia_components', [
            'config_template_id', 'ia_component_type_id', 'max_marks', 'display_order', 'is_active', 'deleted_at',
        ]));
        $ia = new TemplateIaComponent();
        $this->assertSame('msh_template_ia_components', $ia->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(TemplateIaComponent::class));

        // Co-scholastic
        $this->assertTrue(Schema::hasTable('msh_template_coscholastic_components'));
        $this->assertTrue(Schema::hasColumns('msh_template_coscholastic_components', [
            'config_template_id', 'name', 'code', 'grading_scale', 'is_ba_linked', 'display_order', 'is_active', 'deleted_at',
        ]));
        $cosc = new TemplateCoscholasticComponent();
        $this->assertSame('msh_template_coscholastic_components', $cosc->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(TemplateCoscholasticComponent::class));
    }

    // ── Band 10-19: create + activity log ───────────────────────────────────

    public function test_components_10_create_scholastic_component_persists_and_logs_stored(): void
    {
        $templateId = $this->configTemplateId();
        $sourceId = $this->createSourceComponentSeed()->id;

        $created = null;
        $this->browseWithFailureScreenshot('c10-create-scholastic', function (Browser $browser) use ($templateId, $sourceId, &$created): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId,
                'source_component_id' => $sourceId,
                'weightage_percent' => 100,
                'max_marks' => 80,
                'is_active' => 1,
            ]);

            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Scholastic store did not return HTTP 200.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertTrue((bool) ($json['status'] ?? false), 'Scholastic store status not true.');

            $created = TemplateScholasticComponent::where('config_template_id', $templateId)
                ->where('source_component_id', $sourceId)->first();
        });

        $this->assertNotNull($created, 'Scholastic component was not persisted.');
        $this->assertSame('100.00', (string) $created->weightage_percent);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $created->id, 'Stored');

        $this->forceDeleteModel($created);
    }

    public function test_components_11_scholastic_sum_not_validated_on_create_defect(): void
    {
        // BUG-MSH-C01 (BR-MSG-002): controller store() bypasses the weightage-sum
        // service; two components summing to 80 (!= 100) are accepted on create.
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceA = $this->createSourceComponentSeed()->id;
        $sourceB = $this->createSourceComponentSeed()->id;

        $this->browseWithFailureScreenshot('c11-sum-not-validated', function (Browser $browser) use ($templateId, $sourceA, $sourceB): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $r1 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceA, 'weightage_percent' => 40, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r1['status'] ?? 0), 'First scholastic row (40%) was rejected — unexpected.');

            $r2 = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceB, 'weightage_percent' => 40, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($r2['status'] ?? 0), 'Second scholastic row (40%) rejected — create IS validating sum (defect fixed?).');
        });

        $sum = (float) TemplateScholasticComponent::where('config_template_id', $templateId)->sum('weightage_percent');
        $this->assertEqualsWithDelta(80.0, $sum, 0.01, 'BUG-MSH-C01: expected non-100 sum to persist on create.');
        $this->assertSame(2, TemplateScholasticComponent::where('config_template_id', $templateId)->count());

        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_12_create_exam_weightage_persists_and_logs_stored(): void
    {
        $templateId = $this->configTemplateId();
        $examTypeId = $this->resolveExamTypeId();

        $created = null;
        $this->browseWithFailureScreenshot('c12-create-exam-weightage', function (Browser $browser) use ($templateId, $examTypeId, &$created): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser, 'exam-weightages');

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::EXAM_BASE, [
                'config_template_id' => $templateId,
                'exam_type_id' => $examTypeId,
                'weightage_percent' => 100,
                'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Exam weightage store did not return HTTP 200.');

            $created = TemplateExamWeightage::where('config_template_id', $templateId)
                ->where('exam_type_id', $examTypeId)->first();
        });

        $this->assertNotNull($created, 'Exam weightage was not persisted.');
        $this->assertActivityIssuedByAdmin(TemplateExamWeightage::class, (int) $created->id, 'Stored');

        $this->forceDeleteModel($created);
    }

    public function test_components_13_create_ia_component_persists_and_logs_stored(): void
    {
        $templateId = $this->configTemplateId();
        $iaTypeId = $this->createIaComponentTypeSeed()->id;

        $created = null;
        $this->browseWithFailureScreenshot('c13-create-ia-component', function (Browser $browser) use ($templateId, $iaTypeId, &$created): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser, 'ia-components');

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::IA_BASE, [
                'config_template_id' => $templateId,
                'ia_component_type_id' => $iaTypeId,
                'max_marks' => 5,
                'display_order' => 1,
                'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'IA component store did not return HTTP 200.');

            $created = TemplateIaComponent::where('config_template_id', $templateId)
                ->where('ia_component_type_id', $iaTypeId)->first();
        });

        $this->assertNotNull($created, 'IA component was not persisted.');
        $this->assertSame('5.00', (string) $created->max_marks);
        $this->assertActivityIssuedByAdmin(TemplateIaComponent::class, (int) $created->id, 'Stored');

        $this->forceDeleteModel($created);
    }

    public function test_components_14_create_coscholastic_component_persists_and_logs_stored(): void
    {
        $templateId = $this->configTemplateId();
        $code = 'CO' . substr($this->uniqueSuffix(), -4);

        $created = null;
        $this->browseWithFailureScreenshot('c14-create-coscholastic', function (Browser $browser) use ($templateId, $code, &$created): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser, 'coscholastic-components');

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::COSCHOLASTIC_BASE, [
                'config_template_id' => $templateId,
                'name' => 'Work Education ' . $code,
                'code' => $code,
                'grading_scale' => '3_POINT',
                'is_ba_linked' => 0,
                'display_order' => 1,
                'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Co-scholastic store did not return HTTP 200.');

            $created = TemplateCoscholasticComponent::where('config_template_id', $templateId)
                ->where('code', $code)->first();
        });

        $this->assertNotNull($created, 'Co-scholastic component was not persisted.');
        $this->assertSame('3_POINT', (string) $created->grading_scale);
        $this->assertActivityIssuedByAdmin(TemplateCoscholasticComponent::class, (int) $created->id, 'Stored');

        $this->forceDeleteModel($created);
    }

    // ── Band 30-39: validation ──────────────────────────────────────────────

    public function test_components_30_scholastic_required_fields_are_rejected(): void
    {
        $this->browseWithFailureScreenshot('c30-required', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, []);

            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty scholastic store should return HTTP 422.');
            $errors = $this->validationErrors($response);
            $this->assertArrayHasKey('config_template_id', $errors);
            $this->assertArrayHasKey('source_component_id', $errors);
            $this->assertArrayHasKey('weightage_percent', $errors);
        });
    }

    public function test_components_31_scholastic_weightage_over_100_is_rejected(): void
    {
        $templateId = $this->configTemplateId();
        $sourceId = $this->createSourceComponentSeed()->id;

        $this->browseWithFailureScreenshot('c31-weightage-over-100', function (Browser $browser) use ($templateId, $sourceId): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 150, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'weightage_percent 150 should be rejected (max:100).');
            $this->assertArrayHasKey('weightage_percent', $this->validationErrors($response));
        });

        $this->assertFalse(
            TemplateScholasticComponent::where('config_template_id', $templateId)->where('source_component_id', $sourceId)->exists(),
            'Out-of-range scholastic component should not persist.'
        );
    }

    public function test_components_32_scholastic_duplicate_component_is_rejected(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 50]);

        $this->browseWithFailureScreenshot('c32-duplicate', function (Browser $browser) use ($templateId, $sourceId): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 20, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate (template, source) should return HTTP 422.');
            $body = (string) ($response['body'] ?? '');
            $this->assertTrue(
                str_contains($body, 'The source component id has already been taken.'),
                'Expected exact duplicate message not found.'
            );
        });

        $this->assertSame(1, TemplateScholasticComponent::where('config_template_id', $templateId)->where('source_component_id', $sourceId)->count());
        $this->forceDeleteConfigTemplate($templateId);
    }

    // ── Band 40-49: integration / FK ────────────────────────────────────────

    public function test_components_40_scholastic_invalid_config_template_is_rejected(): void
    {
        $sourceId = $this->createSourceComponentSeed()->id;

        $this->browseWithFailureScreenshot('c40-invalid-template', function (Browser $browser) use ($sourceId): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => 999999999, 'source_component_id' => $sourceId, 'weightage_percent' => 10, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Invalid config_template_id should return HTTP 422 (exists rule).');
            $this->assertArrayHasKey('config_template_id', $this->validationErrors($response));
        });
    }

    public function test_components_41_scholastic_invalid_source_component_is_rejected(): void
    {
        $templateId = $this->configTemplateId();

        $this->browseWithFailureScreenshot('c41-invalid-source', function (Browser $browser) use ($templateId): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => 999999999, 'weightage_percent' => 10, 'is_active' => 1,
            ]);
            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Invalid source_component_id should return HTTP 422 (exists rule).');
            $this->assertArrayHasKey('source_component_id', $this->validationErrors($response));
        });
    }

    // ── Band 50-59: authorization ───────────────────────────────────────────

    public function test_components_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('c50-guest', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::COMPONENTS_PATH))->pause(1200);

            $this->assertTrue(
                str_contains($this->currentPath($browser), '/login'),
                'Guest was not redirected to /login from the components page.'
            );
        });
    }

    // ── Band 60-69: UI/UX ───────────────────────────────────────────────────

    public function test_components_60_components_page_renders_four_tabs(): void
    {
        $this->browseWithFailureScreenshot('c60-render-tabs', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $source = $browser->driver->getPageSource();
            $this->assertTrue(str_contains($source, 'scholastic-components'), 'Scholastic tab pane not rendered.');
            $this->assertTrue(str_contains($source, 'exam-weightages'), 'Exam-weightages tab pane not rendered.');
            $this->assertTrue(str_contains($source, 'ia-components'), 'IA-components tab pane not rendered.');
            $this->assertTrue(str_contains($source, 'coscholastic-components'), 'Co-scholastic tab pane not rendered.');
        });
    }

    // ── Band 70-79: edge cases ──────────────────────────────────────────────

    public function test_components_70_scholastic_zero_weightage_boundary_is_accepted(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;

        $this->browseWithFailureScreenshot('c70-zero-weightage', function (Browser $browser) use ($templateId, $sourceId): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::SCHOLASTIC_BASE, [
                'config_template_id' => $templateId, 'source_component_id' => $sourceId, 'weightage_percent' => 0, 'is_active' => 1,
            ]);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'weightage_percent 0 (min boundary) should be accepted.');
        });

        $this->assertTrue(
            TemplateScholasticComponent::where('config_template_id', $templateId)->where('source_component_id', $sourceId)->exists()
        );
        $this->forceDeleteConfigTemplate($templateId);
    }

    // ── Band 80-89: config rule (weightage sum) ─────────────────────────────

    public function test_components_80_scholastic_update_to_non_100_sum_is_rejected_by_service(): void
    {
        // Update path routes through TemplateScholasticComponentService, which
        // validates the sum. A single 100% component updated to 50% breaks the
        // sum → DomainException. BUG-MSH-C03: this surfaces as HTTP 500, not 422,
        // and the transaction rolls the change back.
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100]);

        $this->browseWithFailureScreenshot('c80-update-breaks-sum', function (Browser $browser) use ($row): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'PUT',
                self::SCHOLASTIC_BASE . '/' . $row->id,
                [
                    'config_template_id' => (int) $row->config_template_id,
                    'source_component_id' => (int) $row->source_component_id,
                    'weightage_percent' => 50,
                    'is_active' => 1,
                ]
            );
            $this->assertSame(500, (int) ($response['status'] ?? 0), 'BUG-MSH-C03: sum violation on update should surface as HTTP 500 (uncaught DomainException).');
        });

        $row->refresh();
        $this->assertSame('100.00', (string) $row->weightage_percent, 'Transaction should have rolled back the weightage change.');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_81_scholastic_update_keeping_sum_logs_updated(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100, 'max_marks' => 80]);

        $this->browseWithFailureScreenshot('c81-update-ok', function (Browser $browser) use ($row): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'PUT',
                self::SCHOLASTIC_BASE . '/' . $row->id,
                [
                    'config_template_id' => (int) $row->config_template_id,
                    'source_component_id' => (int) $row->source_component_id,
                    'weightage_percent' => 100,
                    'max_marks' => 90,
                    'is_active' => 1,
                ]
            );
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Valid update (sum stays 100) should return HTTP 200.');
        });

        $row->refresh();
        $this->assertSame('90.00', (string) $row->max_marks, 'max_marks was not updated.');
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $row->id, 'Updated');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_82_scholastic_toggle_status_endpoint_updates_is_active(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100, 'is_active' => true]);

        $this->browseWithFailureScreenshot('c82-toggle', function (Browser $browser) use ($row): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                self::SCHOLASTIC_BASE . '/' . $row->id . '/toggleStatus',
                []
            );
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Toggle endpoint should return HTTP 200.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertTrue((bool) ($json['success'] ?? false), 'Toggle response success not true.');
        });

        $row->refresh();
        $this->assertFalse((bool) $row->is_active, 'Status was not toggled to inactive.');
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $row->id, 'Toggled');
        $this->forceDeleteConfigTemplate($templateId);
    }

    public function test_components_83_scholastic_delete_restore_force_delete_flow(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100]);

        // Soft delete
        $this->browseWithFailureScreenshot('c83-delete', function (Browser $browser) use ($row): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);
            $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::SCHOLASTIC_BASE . '/' . $row->id, []);
        });
        $this->assertNotNull(
            TemplateScholasticComponent::withTrashed()->whereKey($row->id)->first()?->deleted_at,
            'Scholastic component was not soft deleted.'
        );
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $row->id, 'Deleted');

        // Restore
        $this->browseWithFailureScreenshot('c83-restore', function (Browser $browser) use ($row): void {
            $this->authenticate($browser);
            $this->sendJsonRequestFromBrowser($browser, 'GET', self::SCHOLASTIC_BASE . '/' . $row->id . '/restore', []);
        });
        $this->assertNull(
            TemplateScholasticComponent::withTrashed()->whereKey($row->id)->first()?->deleted_at,
            'Scholastic component was not restored.'
        );
        $this->assertActivityIssuedByAdmin(TemplateScholasticComponent::class, (int) $row->id, 'Restored');

        // Force delete
        $this->browseWithFailureScreenshot('c83-force-delete', function (Browser $browser) use ($row): void {
            $this->authenticate($browser);
            $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::SCHOLASTIC_BASE . '/' . $row->id . '/force-delete', []);
        });
        $this->assertFalse(
            TemplateScholasticComponent::withTrashed()->whereKey($row->id)->exists(),
            'Scholastic component still exists after force delete.'
        );

        $this->forceDeleteConfigTemplate($templateId);
    }

    // ── Band 90-99: activity issued_by ──────────────────────────────────────

    public function test_components_90_show_endpoint_returns_scholastic_component(): void
    {
        $templateId = $this->createConfigTemplateSeed()->id;
        $sourceId = $this->createSourceComponentSeed()->id;
        $row = $this->createScholasticSeed($templateId, $sourceId, ['weightage_percent' => 100]);

        $this->browseWithFailureScreenshot('c90-show', function (Browser $browser) use ($row): void {
            $this->authenticate($browser);
            $this->openComponentsPage($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::SCHOLASTIC_BASE . '/' . $row->id, []);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Show endpoint should return HTTP 200.');
        });

        $this->browseWithFailureScreenshot('c90-show-404', function (Browser $browser): void {
            $this->authenticate($browser);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::SCHOLASTIC_BASE . '/999999999', []);
            $this->assertSame(404, (int) ($response['status'] ?? 0), 'Invalid scholastic id should return HTTP 404.');
        });

        $this->forceDeleteConfigTemplate($templateId);
    }

    // ========================================================================
    // Private helper library
    // ========================================================================

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
        $this->assertSame(
            (int) $this->adminUser->id,
            (int) $log->user_id,
            'Issued-by user_id mismatch for activity event: ' . $event
        );
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
            $this->markTestSkipped('No academic session (sch_org_academic_sessions_jnt) available for config template seed.');
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
                'display_order' => 1,
                'is_active' => 1,
                'created_by' => (int) $this->adminUser->id,
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
                'is_active' => 1,
                'created_by' => (int) $this->adminUser->id,
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

    private function createSourceComponentSeed(): SourceComponent
    {
        return SourceComponent::create([
            'code' => 'SRC' . substr($this->uniqueSuffix(), -6),
            'name' => 'Source ' . substr($this->uniqueSuffix(), -4),
            'is_mandatory' => 0,
            'display_order' => 1,
            'is_active' => 1,
            'created_by' => (int) $this->adminUser->id,
        ]);
    }

    private function createIaComponentTypeSeed(): IaComponentType
    {
        return IaComponentType::create([
            'code' => 'IAT' . substr($this->uniqueSuffix(), -6),
            'name' => 'IA Type ' . substr($this->uniqueSuffix(), -4),
            'display_order' => 1,
            'is_active' => 1,
            'created_by' => (int) $this->adminUser->id,
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
        // Children are ON DELETE CASCADE at DB level; hard-deleting the template
        // removes scholastic/exam/ia/coscholastic rows regardless of soft-delete state.
        try {
            TemplateScholasticComponent::withTrashed()->where('config_template_id', $templateId)->forceDelete();
            TemplateExamWeightage::withTrashed()->where('config_template_id', $templateId)->forceDelete();
            TemplateIaComponent::withTrashed()->where('config_template_id', $templateId)->forceDelete();
            TemplateCoscholasticComponent::withTrashed()->where('config_template_id', $templateId)->forceDelete();
        } catch (Throwable) {
        }

        if ($this->sharedTemplateId === $templateId) {
            return; // shared template may be a pre-existing row; leave it in place.
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
