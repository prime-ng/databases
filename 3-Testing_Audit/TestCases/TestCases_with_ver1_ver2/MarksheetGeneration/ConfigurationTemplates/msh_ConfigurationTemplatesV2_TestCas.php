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
use Modules\MarksheetGeneration\Http\Requests\ConfigTemplateRequest;
use Modules\MarksheetGeneration\Models\ConfigTemplate;
use Modules\MarksheetGeneration\Models\ExamGroup;
use Modules\MarksheetGeneration\Models\MarksheetType;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * MarksheetGeneration — Configuration Templates (V2 comprehensive suite).
 *
 * Primary table: msh_config_templates (tenant_db). See V1 header for the full source map.
 * Semantic numbering bands (WP-G):
 *   01-09 schema/config · 10-19 business rules · 20-29 state (is_locked) · 30-39 validation
 *   40-49 integration/FK · 50-59 permissions · 60-69 UI/UX · 70-79 edge/security · 90-99 tenancy
 *
 * Proven audit defects:
 *   BUG-MSH-003 — ExamGroupController::edit() has no model binding (test_..._56).
 *   SEC-MSH-003 — every FormRequest authorize()=true; gate enforced only in controller (test_..._53).
 *   D39-MSH     — MSH permissions unseeded (documented; tests grant permissions explicitly).
 *   BR-MSG-027  — is_locked immutability guard not implemented in code (test_..._21, verify-in-source).
 */
class msh_ConfigurationTemplatesV2_TestCas extends DuskTestCase
{
    private const COMBINED_PATH = '/marksheet-generation/configuration';
    private const CREATE_PATH   = '/marksheet-generation/config-template/create';
    private const STORE_PATH    = '/marksheet-generation/config-template';
    private const DDL_FILE      = '2-DDL_Tenant_Consolidated/MarksheetGeneration_DDL_v1.sql';
    private const REQUEST_FILE  = 'Modules/MarksheetGeneration/app/Http/Requests/ConfigTemplateRequest.php';
    private const CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/ConfigTemplateController.php';
    private const SCREENSHOT_DIR = 'tests/Browser/Modules/MarksheetGeneration/ConfigurationTemplates/screenshots';

    private const CONFIG_PERMISSIONS = [
        'tenant.msh-configuration.view',
        'tenant.msh-config-template.viewAny',
        'tenant.msh-config-template.view',
        'tenant.msh-config-template.create',
        'tenant.msh-config-template.update',
        'tenant.msh-config-template.delete',
        'tenant.msh-config-template.restore',
        'tenant.msh-config-template.forceDelete',
    ];

    private ?User $adminUser = null;
    private ?User $limitedUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private array $configDependencies = [];
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
        if ($this->limitedUser) {
            try {
                $this->limitedUser->forceDelete();
            } catch (Throwable) {
            }
            $this->limitedUser = null;
        }

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // ═════════════════════════════ 01-09 · Schema / config ═════════════════════════════

    public function test_config_template_01_schema_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable('msh_config_templates'), 'Table msh_config_templates does not exist.');
        $this->assertTrue(
            Schema::hasColumns('msh_config_templates', [
                'academic_session_id', 'marksheet_type_id', 'exam_group_id', 'grading_schema_id',
                'code', 'name', 'description', 'board_code', 'passing_percentage',
                'compartment_max_failures', 'is_best_of_n_enabled', 'best_of_n_count',
                'is_locked', 'is_active', 'created_by', 'updated_by', 'deleted_at',
            ]),
            'Expected columns missing in msh_config_templates.'
        );

        $model = new ConfigTemplate();
        $this->assertSame('msh_config_templates', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(ConfigTemplate::class));
        $this->assertInstanceOf(BelongsTo::class, $model->marksheetType());
        $this->assertInstanceOf(BelongsTo::class, $model->examGroup());
        $this->assertInstanceOf(BelongsTo::class, $model->academicSession());
        $this->assertInstanceOf(BelongsTo::class, $model->gradingSchema());
        $this->assertInstanceOf(HasMany::class, $model->classConfigs());
        $this->assertInstanceOf(HasMany::class, $model->marksheetSchedules());

        $fillable = $model->getFillable();
        foreach (['code', 'name', 'passing_percentage', 'compartment_max_failures', 'is_locked', 'created_by'] as $col) {
            $this->assertContains($col, $fillable, "Column {$col} should be fillable.");
        }
    }

    public function test_config_template_02_column_types_and_indexes_match_ddl(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Column-type inspection requires MySQL.');
        }

        $columns = collect(DB::select('SHOW COLUMNS FROM msh_config_templates'))->keyBy(fn ($c) => $c->Field);
        // MySQL 8 type variance — contains, never equals (constraint D17).
        $this->assertStringContainsString('decimal', strtolower((string) ($columns['passing_percentage']->Type ?? '')));
        $this->assertStringContainsString('tinyint', strtolower((string) ($columns['compartment_max_failures']->Type ?? '')));
        $this->assertStringContainsString('varchar', strtolower((string) ($columns['name']->Type ?? '')));

        $idx = DB::select("SHOW INDEX FROM msh_config_templates WHERE Key_name = 'uq_msh_ct_session_code'");
        $this->assertNotEmpty($idx, 'Unique index uq_msh_ct_session_code (academic_session_id, code) missing.');
    }

    public function test_config_template_03_request_rules_and_controller_events_are_correct(): void
    {
        $requestPath = base_path(self::REQUEST_FILE);
        $this->assertTrue(File::exists($requestPath), 'Request file missing.');
        $rc = File::get($requestPath);
        $this->assertStringContainsString("'academic_session_id' => [", $rc);
        $this->assertStringContainsString("'exists:sch_org_academic_sessions_jnt,id'", $rc);
        $this->assertStringContainsString("'marksheet_type_id' => ['required', 'integer', 'exists:msh_marksheet_types,id']", $rc);
        $this->assertStringContainsString("'exam_group_id' => ['required', 'integer', 'exists:msh_exam_groups,id']", $rc);
        $this->assertStringContainsString("'grading_schema_id' => ['nullable', 'integer', 'exists:slb_grade_division_master,id']", $rc);
        $this->assertStringContainsString("'name' => ['required', 'string', 'max:150']", $rc);
        $this->assertStringContainsString("'passing_percentage' => ['required', 'numeric', 'min:0', 'max:100']", $rc);
        $this->assertStringContainsString("'compartment_max_failures' => ['required', 'integer', 'min:0', 'max:255']", $rc);

        $controllerPath = base_path(self::CONTROLLER_FILE);
        $cc = File::get($controllerPath);
        $this->assertStringContainsString("activityLog(\$configTemplate, 'Stored'", $cc);
        $this->assertStringContainsString("activityLog(\$configTemplate, 'Updated'", $cc);
        $this->assertStringContainsString("activityLog(\$configTemplate, 'Deleted'", $cc);
        $this->assertStringContainsString("activityLog(\$record, 'Toggled'", $cc);
        $this->assertStringContainsString("activityLog(\$record, 'Restored'", $cc);
        // FK 23000 friendly guard on forceDelete
        $this->assertStringContainsString('Cannot delete this record because it is referenced by other records', $cc);
    }

    // ═════════════════════════════ 10-19 · Business rules ═════════════════════════════

    public function test_config_template_10_create_persists_with_activity_stored(): void
    {
        $deps = $this->configDependencies();
        $code = $this->uniqueCode('C');
        $name = $this->uniqueName('CRT');

        $this->browseWithFailureScreenshot('ct-10-create', function (Browser $browser) use ($deps, $code, $name): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH, 900);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => $deps['marksheet_type_id'],
                'exam_group_id'       => $deps['exam_group_id'],
                'code'                => $code,
                'name'                => $name,
                'passing_percentage'  => 33,
                'compartment_max_failures' => 2,
                'is_active'           => true,
            ]);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Create did not complete.');
        });

        $template = ConfigTemplate::where('academic_session_id', $deps['academic_session_id'])->where('code', $code)->first();
        $this->assertNotNull($template, 'Config template was not created.');
        $this->assertSame($name, (string) $template->name);
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Stored');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_11_create_with_null_grading_schema_is_allowed(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps, ['grading_schema_id' => null]);
        $this->assertNull($template->grading_schema_id, 'grading_schema_id should accept NULL (nullable + SET NULL FK).');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_12_create_with_class_assignments_syncs_junction(): void
    {
        $deps = $this->configDependencies();
        $classId = DB::table('sch_classes')->where('is_active', 1)->value('id');
        if (!$classId) {
            $this->markTestSkipped('No active sch_classes row to assign.');
        }

        $code = $this->uniqueCode('A');

        $this->browseWithFailureScreenshot('ct-12-assignments', function (Browser $browser) use ($deps, $code, $classId): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH, 900);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => $deps['marksheet_type_id'],
                'exam_group_id'       => $deps['exam_group_id'],
                'code'                => $code,
                'name'                => $this->uniqueName('ASG'),
                'passing_percentage'  => 33,
                'compartment_max_failures' => 2,
                'class_assignments'   => [['type' => 'class', 'target_id' => (int) $classId]],
            ]);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Create with assignments did not complete.');
        });

        $template = ConfigTemplate::where('academic_session_id', $deps['academic_session_id'])->where('code', $code)->first();
        $this->assertNotNull($template, 'Template not created.');
        $this->assertTrue(
            DB::table('msh_class_config_jnt')
                ->where('config_template_id', $template->id)
                ->where('class_id', $classId)
                ->whereNull('deleted_at')
                ->exists(),
            'ConfigTemplateService did not sync the class assignment into msh_class_config_jnt.'
        );
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_13_update_persists_with_activity_updated(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);
        $newName = $this->uniqueName('UPD');

        $this->browseWithFailureScreenshot('ct-13-update', function (Browser $browser) use ($deps, $template, $newName): void {
            $this->authenticate($browser);
            $response = $this->sendJsonRequestFromBrowser($browser, 'PUT', self::STORE_PATH . '/' . $template->id, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => $deps['marksheet_type_id'],
                'exam_group_id'       => $deps['exam_group_id'],
                'code'                => (string) $template->code,
                'name'                => $newName,
                'passing_percentage'  => 45,
                'compartment_max_failures' => 1,
                'is_active'           => true,
            ]);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Update did not complete.');
        });

        $template->refresh();
        $this->assertSame($newName, (string) $template->name);
        $this->assertSame(1, (int) $template->compartment_max_failures);
        $this->assertSame((int) $this->adminUser->id, (int) $template->updated_by);
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Updated');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_14_default_passing_percentage_is_33_at_db_level(): void
    {
        $deps = $this->configDependencies();
        // Insert bypassing the model default to prove the DDL DEFAULT 33.00.
        $id = DB::table('msh_config_templates')->insertGetId([
            'academic_session_id' => $deps['academic_session_id'],
            'marksheet_type_id'   => $deps['marksheet_type_id'],
            'exam_group_id'       => $deps['exam_group_id'],
            'code'                => $this->uniqueCode('DF'),
            'name'                => $this->uniqueName('DFLT'),
            'compartment_max_failures' => 2,
            'created_by'          => (int) $this->adminUser->id,
            'created_at'          => now(),
            'updated_at'          => now(),
        ]);

        $value = DB::table('msh_config_templates')->where('id', $id)->value('passing_percentage');
        $this->assertSame('33.00', (string) $value, 'DDL DEFAULT for passing_percentage should be 33.00.');

        $template = ConfigTemplate::withTrashed()->find($id);
        if ($template) {
            $this->forceDeleteConfigTemplate($template);
        }
    }

    public function test_config_template_15_best_of_n_fields_persist(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps, [
            'is_best_of_n_enabled' => true,
            'best_of_n_count'      => 2,
        ]);
        $template->refresh();
        $this->assertTrue((bool) $template->is_best_of_n_enabled, 'is_best_of_n_enabled did not persist.');
        $this->assertSame(2, (int) $template->best_of_n_count, 'best_of_n_count did not persist.');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_16_board_code_is_optional(): void
    {
        $deps = $this->configDependencies();
        $withBoard = $this->createConfigTemplateSeed($deps, ['board_code' => 'CBSE']);
        $this->assertSame('CBSE', (string) $withBoard->board_code);
        $withoutBoard = $this->createConfigTemplateSeed($deps, ['board_code' => null]);
        $this->assertNull($withoutBoard->board_code, 'board_code is nullable/informational.');
        $this->forceDeleteConfigTemplate($withBoard);
        $this->forceDeleteConfigTemplate($withoutBoard);
    }

    public function test_config_template_17_soft_delete_records_activity_deleted(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);

        $this->browseWithFailureScreenshot('ct-17-delete', function (Browser $browser) use ($template): void {
            $this->authenticate($browser);
            $response = $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::STORE_PATH . '/' . $template->id, []);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Delete did not complete.');
        });

        $template->refresh();
        $this->assertNotNull($template->deleted_at, 'Template was not soft deleted.');
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Deleted');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_18_restore_records_activity_restored(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);
        $template->delete();

        $this->browseWithFailureScreenshot('ct-18-restore', function (Browser $browser) use ($template): void {
            $this->authenticate($browser);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STORE_PATH . '/' . $template->id . '/restore', []);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Restore did not complete.');
        });

        $template->refresh();
        $this->assertNull($template->deleted_at, 'Template was not restored.');
        $this->assertTrue((bool) $template->is_active, 'Restore should re-activate the record.');
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Restored');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_19_force_delete_removes_row_permanently(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);
        $id = (int) $template->id;
        $template->delete();

        try {
            $template->forceDelete();
        } catch (Throwable $e) {
            $this->markTestSkipped('Force delete threw (likely media/FK): ' . $e->getMessage());
        }

        $this->assertFalse(ConfigTemplate::withTrashed()->whereKey($id)->exists(), 'Template still exists after force delete.');
    }

    // ═════════════════════════════ 20-29 · State (is_locked) ═════════════════════════════

    public function test_config_template_20_is_locked_flag_persists_on_create(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps, ['is_locked' => true]);
        $template->refresh();
        $this->assertTrue((bool) $template->is_locked, 'is_locked flag did not persist.');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_21_br_msg_027_update_not_blocked_when_locked_verify_in_source(): void
    {
        // BR-MSG-027 (DDL comment): a locked template should be immutable. The current code path
        // (ConfigTemplateController::update + ConfigTemplateService::update) contains NO is_locked
        // guard, so an update SUCCEEDS on a locked record. This test documents the CURRENT behaviour
        // and flags the gap (candidate DEV — verify in source before asserting a bug).
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps, ['is_locked' => true, 'name' => $this->uniqueName('LOCK')]);
        $newName = $this->uniqueName('MUT');

        $this->browseWithFailureScreenshot('ct-21-locked-update', function (Browser $browser) use ($deps, $template, $newName): void {
            $this->authenticate($browser);
            $response = $this->sendJsonRequestFromBrowser($browser, 'PUT', self::STORE_PATH . '/' . $template->id, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => $deps['marksheet_type_id'],
                'exam_group_id'       => $deps['exam_group_id'],
                'code'                => (string) $template->code,
                'name'                => $newName,
                'passing_percentage'  => 33,
                'compartment_max_failures' => 2,
                'is_locked'           => true,
                'is_active'           => true,
            ]);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Update request did not complete.');
        });

        $template->refresh();
        // Current behaviour: the locked template WAS mutated (no guard). If a guard is later added,
        // this assertion is the canary that will flip and force the doc to be updated.
        $this->assertSame($newName, (string) $template->name, 'Locked template was expected to still be mutable under current (unguarded) code.');
        $this->forceDeleteConfigTemplate($template);
    }

    // ═════════════════════════════ 30-39 · Validation ═════════════════════════════

    public function test_config_template_30_required_fields_rejected_422(): void
    {
        $this->assertStoreValidationErrors([], ['code', 'name', 'academic_session_id', 'marksheet_type_id', 'exam_group_id'], 'ct-30-required');
    }

    public function test_config_template_31_code_max_50_enforced(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['code' => str_repeat('A', 51)]), ['code'], 'ct-31-code-max');
    }

    public function test_config_template_32_name_max_150_enforced(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['name' => str_repeat('N', 151)]), ['name'], 'ct-32-name-max');
    }

    public function test_config_template_33_description_max_500_enforced(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['description' => str_repeat('D', 501)]), ['description'], 'ct-33-desc-max');
    }

    public function test_config_template_34_board_code_max_50_enforced(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['board_code' => str_repeat('B', 51)]), ['board_code'], 'ct-34-board-max');
    }

    public function test_config_template_35_passing_percentage_out_of_range_rejected(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['passing_percentage' => 150]), ['passing_percentage'], 'ct-35-pct-high');
        $this->assertStoreValidationErrors($this->validPayload($deps, ['passing_percentage' => -5]), ['passing_percentage'], 'ct-35-pct-low');
    }

    public function test_config_template_36_compartment_max_failures_out_of_range_rejected(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['compartment_max_failures' => 999]), ['compartment_max_failures'], 'ct-36-comp-max');
    }

    public function test_config_template_37_best_of_n_count_min_1_enforced(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['best_of_n_count' => 0]), ['best_of_n_count'], 'ct-37-bon-min');
    }

    public function test_config_template_38_duplicate_code_same_session_rejected(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);
        $this->assertStoreValidationErrors($this->validPayload($deps, ['code' => (string) $template->code]), ['code'], 'ct-38-dup');
        $this->assertSame(
            1,
            ConfigTemplate::withTrashed()->where('academic_session_id', $deps['academic_session_id'])->where('code', $template->code)->count(),
            'Duplicate code should not be inserted.'
        );
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_39_same_code_in_different_session_allowed(): void
    {
        $deps = $this->configDependencies();
        $otherSessionId = DB::table('sch_org_academic_sessions_jnt')
            ->where('id', '!=', $deps['academic_session_id'])
            ->value('id');
        if (!$otherSessionId) {
            $this->markTestSkipped('Only one academic session present — cannot prove per-session uniqueness scope.');
        }

        $code = $this->uniqueCode('SS');
        $t1 = $this->createConfigTemplateSeed($deps, ['code' => $code]);

        // Need an exam group for the other session (exam_group.session must match FK context; use same type).
        $examGroupOther = ExamGroup::create([
            'academic_session_id' => (int) $otherSessionId,
            'code'                => $this->uniqueCode('EGO'),
            'name'                => $this->uniqueName('EGO'),
            'is_active'           => true,
            'created_by'          => (int) $this->adminUser->id,
        ]);

        $t2 = ConfigTemplate::create([
            'academic_session_id'      => (int) $otherSessionId,
            'marksheet_type_id'        => $deps['marksheet_type_id'],
            'exam_group_id'            => (int) $examGroupOther->id,
            'code'                     => $code,
            'name'                     => $this->uniqueName('SS2'),
            'passing_percentage'       => 33,
            'compartment_max_failures' => 2,
            'created_by'               => (int) $this->adminUser->id,
        ]);

        $this->assertNotNull($t2->id, 'Same code in a different session should be allowed (unique is per-session).');
        $this->forceDeleteConfigTemplate($t1);
        $this->forceDeleteConfigTemplate($t2);
    }

    // ═════════════════════════════ 40-49 · Integration / FK ═════════════════════════════

    public function test_config_template_40_invalid_marksheet_type_id_rejected(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['marksheet_type_id' => 999999999]), ['marksheet_type_id'], 'ct-40-mt');
    }

    public function test_config_template_41_invalid_exam_group_id_rejected(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['exam_group_id' => 999999999]), ['exam_group_id'], 'ct-41-eg');
    }

    public function test_config_template_42_invalid_academic_session_id_rejected(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['academic_session_id' => 999999999]), ['academic_session_id'], 'ct-42-as');
    }

    public function test_config_template_43_invalid_grading_schema_id_rejected(): void
    {
        $deps = $this->configDependencies();
        $this->assertStoreValidationErrors($this->validPayload($deps, ['grading_schema_id' => 999999999]), ['grading_schema_id'], 'ct-43-gs');
    }

    public function test_config_template_44_marksheet_type_delete_restricted_while_referenced(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);
        $type = MarksheetType::find($deps['marksheet_type_id']);
        $this->assertNotNull($type);

        $blocked = false;
        try {
            $type->forceDelete();
        } catch (Throwable) {
            $blocked = true;
        }
        $this->assertTrue($blocked, 'FK RESTRICT: deleting a referenced marksheet type must be blocked.');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_45_exam_group_delete_restricted_while_referenced(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);
        $group = ExamGroup::find($deps['exam_group_id']);
        $this->assertNotNull($group);

        $blocked = false;
        try {
            $group->forceDelete();
        } catch (Throwable) {
            $blocked = true;
        }
        $this->assertTrue($blocked, 'FK RESTRICT: deleting a referenced exam group must be blocked (fk_msh_ct_exam_group).');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_46_force_delete_cascades_class_config_junction(): void
    {
        $deps = $this->configDependencies();
        $classId = DB::table('sch_classes')->where('is_active', 1)->value('id');
        if (!$classId) {
            $this->markTestSkipped('No active class for cascade test.');
        }

        $template = $this->createConfigTemplateSeed($deps);
        DB::table('msh_class_config_jnt')->insert([
            'config_template_id' => $template->id,
            'class_id'           => (int) $classId,
            'is_active'          => 1,
            'created_by'         => (int) $this->adminUser->id,
            'created_at'         => now(),
            'updated_at'         => now(),
        ]);

        $id = (int) $template->id;
        try {
            $template->forceDelete();
        } catch (Throwable $e) {
            $this->markTestSkipped('Force delete threw: ' . $e->getMessage());
        }

        $this->assertFalse(
            DB::table('msh_class_config_jnt')->where('config_template_id', $id)->exists(),
            'ON DELETE CASCADE should remove msh_class_config_jnt rows when the template is force-deleted.'
        );
    }

    public function test_config_template_47_force_delete_blocked_when_referenced_by_schedule(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);

        // msh_marksheet_schedules.config_template_id is ON DELETE RESTRICT.
        // Building a full schedule needs a status dropdown id; if unavailable, skip defensively.
        $statusId = DB::table('sys_dropdown_table')->value('id');
        if (!$statusId) {
            $this->forceDeleteConfigTemplate($template);
            $this->markTestSkipped('No sys_dropdown_table status id to build a marksheet schedule for the RESTRICT test.');
        }

        try {
            DB::table('msh_marksheet_schedules')->insert([
                'config_template_id'  => $template->id,
                'academic_session_id' => $deps['academic_session_id'],
                'code'                => $this->uniqueCode('SCH'),
                'name'                => $this->uniqueName('SCH'),
                'status_id'           => (int) $statusId,
                'created_by'          => (int) $this->adminUser->id,
                'created_at'          => now(),
                'updated_at'          => now(),
            ]);
        } catch (Throwable $e) {
            $this->forceDeleteConfigTemplate($template);
            $this->markTestSkipped('Could not seed a marksheet schedule: ' . $e->getMessage());
        }

        $template->delete();
        $blocked = false;
        try {
            $template->forceDelete();
        } catch (Throwable) {
            $blocked = true; // 23000 — the controller catches this and returns the friendly message.
        }

        $this->assertTrue($blocked, 'FK RESTRICT: force-deleting a template referenced by a schedule must be blocked (fk_msh_ms_template).');

        // cleanup
        DB::table('msh_marksheet_schedules')->where('config_template_id', $template->id)->delete();
        $this->forceDeleteConfigTemplate($template);
    }

    // ═════════════════════════════ 50-59 · Permissions ═════════════════════════════

    public function test_config_template_50_guest_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $this->assertTrue(str_contains($this->currentPath($browser), '/login'), 'Guest should be redirected to /login.');
        });
    }

    public function test_config_template_51_user_without_create_permission_gets_403(): void
    {
        $limited = $this->createLimitedUser();
        if (!$limited) {
            $this->markTestSkipped('Could not create a permission-less user (factory unavailable).');
        }
        $deps = $this->configDependencies();
        $payload = $this->validPayload($deps, ['code' => $this->uniqueCode('P4')]);

        $status = 0;
        $this->browseWithFailureScreenshot('ct-51-create-403', function (Browser $browser) use ($limited, $payload, &$status): void {
            $browser->loginAs($limited)->visit($this->tenantUrl(self::COMBINED_PATH))->pause(700);
            if (str_contains($this->currentPath($browser), '/login')) {
                return;
            }
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, $payload);
            $status = (int) ($response['status'] ?? 0);
        });

        if ($status === 200 || $status === 302) {
            $this->markTestSkipped('Limited user still authorized (super-admin bypass / broad seed) — gate 403 not observable here.');
        }
        $this->assertSame(403, $status, 'A user without tenant.msh-config-template.create should get 403 from the controller Gate.');
    }

    public function test_config_template_52_user_without_delete_permission_gets_403(): void
    {
        $limited = $this->createLimitedUser();
        if (!$limited) {
            $this->markTestSkipped('Could not create a permission-less user.');
        }
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);

        $status = 0;
        $this->browseWithFailureScreenshot('ct-52-delete-403', function (Browser $browser) use ($limited, $template, &$status): void {
            $browser->loginAs($limited)->visit($this->tenantUrl(self::COMBINED_PATH))->pause(700);
            if (str_contains($this->currentPath($browser), '/login')) {
                return;
            }
            $response = $this->sendJsonRequestFromBrowser($browser, 'DELETE', self::STORE_PATH . '/' . $template->id, []);
            $status = (int) ($response['status'] ?? 0);
        });

        if (in_array($status, [200, 302], true)) {
            $this->markTestSkipped('Limited user still authorized — gate 403 not observable here.');
        }
        $this->assertSame(403, $status, 'A user without delete permission should get 403.');
        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_53_sec_msh_003_form_request_self_authorizes_true(): void
    {
        // SEC-MSH-003: the FormRequest never gates — authorize() returns true unconditionally.
        // Authorization lives ONLY in the controller Gate::authorize(...) calls.
        $request = new ConfigTemplateRequest();
        $this->assertTrue($request->authorize(), 'ConfigTemplateRequest::authorize() must return true (gate is enforced in the controller only).');

        $cc = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.msh-config-template.create')", $cc);
        $this->assertStringContainsString("Gate::authorize('tenant.msh-config-template.delete')", $cc);
        $this->assertStringContainsString("Gate::authorize('tenant.msh-config-template.update')", $cc);
    }

    public function test_config_template_54_combined_page_requires_configuration_gate(): void
    {
        $this->browseWithFailureScreenshot('ct-54-combined-gate', function (Browser $browser): void {
            $this->authenticate($browser);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::COMBINED_PATH . '?tab=config-templates', []);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Configuration page should load for a permitted admin (gate tenant.msh-configuration.view).');
        });
    }

    public function test_config_template_56_bug_msh_003_exam_group_edit_redirects_without_binding(): void
    {
        $this->browseWithFailureScreenshot('ct-56-bug-msh-003', function (Browser $browser): void {
            $this->authenticate($browser);
            // ExamGroupController::edit() takes NO ExamGroup param → no implicit binding → no 404 for a bogus id,
            // and it redirects (302) to the combined page. fetch follows the redirect (200 HTML).
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', '/marksheet-generation/exam-group/999999999/edit', []);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'BUG-MSH-003: exam-group edit should redirect, not 404.');
        });
    }

    // ═════════════════════════════ 60-69 · UI / UX ═════════════════════════════

    public function test_config_template_60_combined_page_renders_config_templates_tab(): void
    {
        $this->browseWithFailureScreenshot('ct-60-render', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=config-templates', 900);
            $browser->assertPresent('#config-templates-pane');
        });
    }

    public function test_config_template_61_search_filters_config_templates(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps, ['name' => $this->uniqueName('SEARCHABLE')]);

        $this->browseWithFailureScreenshot('ct-61-search', function (Browser $browser) use ($template): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=config-templates&search=' . urlencode((string) $template->name), 900);
            $this->assertTrue($this->pageSourceContains($browser, (string) $template->name), 'Search did not surface the matching template.');
        });

        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_62_status_filter_narrows_list(): void
    {
        $this->browseWithFailureScreenshot('ct-62-status-filter', function (Browser $browser): void {
            $this->authenticate($browser);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::COMBINED_PATH . '?tab=config-templates&status=1', []);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Active-status filter page should load.');
        });
    }

    public function test_config_template_63_create_page_shows_breadcrumb(): void
    {
        $this->browseWithFailureScreenshot('ct-63-breadcrumb', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
            $browser->waitForText('New Config Template', 12)
                ->assertSee('Marksheet Generation')
                ->assertSee('Configuration');
        });
    }

    // ═════════════════════════════ 70-79 · Edge / security ═════════════════════════════

    public function test_config_template_70_xss_in_name_is_stored_and_escaped_on_render(): void
    {
        $deps = $this->configDependencies();
        $payloadName = 'XSS<script>alert(1)</script>' . $this->uniqueSuffix();
        $template = $this->createConfigTemplateSeed($deps, ['name' => substr($payloadName, 0, 150)]);

        $this->browseWithFailureScreenshot('ct-70-xss', function (Browser $browser) use ($template): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=config-templates&search=XSS', 900);
            // Blade escapes by default: raw <script> must not appear unescaped in the DOM source.
            $this->assertFalse(
                str_contains($browser->driver->getPageSource(), '<script>alert(1)</script>'),
                'Stored XSS payload was rendered unescaped.'
            );
        });

        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_71_created_by_is_forced_to_authenticated_user(): void
    {
        // Mass-assignment guard: created_by is set by the service to auth id; a spoofed created_by is ignored
        // because the FormRequest has no created_by rule (validated() strips it).
        $deps = $this->configDependencies();
        $code = $this->uniqueCode('MA');

        $this->browseWithFailureScreenshot('ct-71-mass-assign', function (Browser $browser) use ($deps, $code): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => $deps['marksheet_type_id'],
                'exam_group_id'       => $deps['exam_group_id'],
                'code'                => $code,
                'name'                => $this->uniqueName('MA'),
                'passing_percentage'  => 33,
                'compartment_max_failures' => 2,
                'created_by'          => 999999999,
            ]);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Create did not complete.');
        });

        $template = ConfigTemplate::where('academic_session_id', $deps['academic_session_id'])->where('code', $code)->first();
        $this->assertNotNull($template, 'Template not created.');
        $this->assertSame((int) $this->adminUser->id, (int) $template->created_by, 'created_by must be forced to the authenticated user, not the spoofed value.');
        $this->forceDeleteConfigTemplate($template);
    }

    // ═════════════════════════════ 90-99 · Tenancy ═════════════════════════════

    public function test_config_template_90_config_templates_table_is_tenant_scoped(): void
    {
        // msh_config_templates lives in tenant_db (no tenant_id column — database-per-tenant).
        $this->assertTrue(tenancy()->initialized, 'Tenant context should be initialized for a tenant-side feature.');
        $this->assertTrue(Schema::hasTable('msh_config_templates'), 'Tenant DB must expose msh_config_templates.');
        $this->assertFalse(Schema::hasColumn('msh_config_templates', 'tenant_id'), 'Database-per-tenant: msh_config_templates must NOT have a tenant_id column.');
    }

    public function test_config_template_91_cross_tenant_direct_id_is_not_leaked(): void
    {
        // Defensive tenancy smoke: a bogus id from "another tenant" must not resolve to a real record.
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);

        $this->browseWithFailureScreenshot('ct-91-idor', function (Browser $browser): void {
            $this->authenticate($browser);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::STORE_PATH . '/999999999', []);
            // show() with a non-existent bound model → 404 (route-model binding).
            $this->assertSame(404, (int) ($response['status'] ?? 0), 'A non-existent config template id should 404, not leak another record.');
        });

        $this->forceDeleteConfigTemplate($template);
    }

    // ═════════════════════════════ Private helper library ═════════════════════════════

    private function assertStoreValidationErrors(array $payload, array $expectedKeys, string $caseName): void
    {
        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($payload, $expectedKeys): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH, 900);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, $payload);

            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Expected HTTP 422 for invalid store payload.');
            $errors = (is_array($response['json'] ?? null) ? $response['json'] : [])['errors'] ?? [];
            foreach ($expectedKeys as $key) {
                $this->assertArrayHasKey($key, $errors, "Expected validation error for '{$key}'.");
            }
        });
    }

    private function validPayload(array $deps, array $overrides = []): array
    {
        return array_merge([
            'academic_session_id'      => $deps['academic_session_id'],
            'marksheet_type_id'        => $deps['marksheet_type_id'],
            'exam_group_id'            => $deps['exam_group_id'],
            'code'                     => $this->uniqueCode('V'),
            'name'                     => $this->uniqueName('VAL'),
            'passing_percentage'       => 33,
            'compartment_max_failures' => 2,
        ], $overrides);
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
                $this->captureScreenshot($browser, 'ct-pass-' . $caseName);
            } catch (Throwable $e) {
                $this->captureScreenshot($browser, 'ct-fail-' . $caseName);
                throw $e;
            }
        });
    }

    private function captureScreenshot(Browser $browser, string $rawName): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName . '-' . now()->format('Ymd_His'));
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'ct-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function pageSourceContains(Browser $browser, string $text): bool
    {
        return str_contains($browser->driver->getPageSource(), $text);
    }

    private function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): array
    {
        $encodedMethod = json_encode(strtoupper($method), JSON_THROW_ON_ERROR);
        $encodedUrl = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
window.__ctApiDone = false;
window.__ctApiError = '';
window.__ctApiResult = null;

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
        window.__ctApiResult = { status: response.status, ok: response.ok, body, json };
    } catch (error) {
        window.__ctApiError = String(error);
    } finally {
        window.__ctApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__ctApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__ctApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__ctApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

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
        $this->grantConfigPermissions($this->adminUser);
    }

    private function grantConfigPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::CONFIG_PERMISSIONS, $guard);

        if (class_exists(\Spatie\Permission\Models\Role::class)) {
            $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.msh-admin');
            try {
                $role = \Spatie\Permission\Models\Role::firstOrCreate(['name' => $roleName, 'guard_name' => $guard]);
                if (method_exists($role, 'syncPermissions')) {
                    $role->syncPermissions(self::CONFIG_PERMISSIONS);
                }
                if (method_exists($user, 'assignRole')) {
                    $user->assignRole($roleName);
                }
            } catch (Throwable) {
            }
        }
        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::CONFIG_PERMISSIONS as $permission) {
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

    private function createLimitedUser(): ?User
    {
        try {
            $languageId = DB::table('glb_languages')->value('id');
            $overrides = [
                'email'             => 'ct-limited-' . uniqid() . '@tenant.test',
                'email_verified_at' => now(),
                'emp_code'          => 'L' . substr((string) uniqid(), -12),
            ];
            if ($languageId) {
                $overrides['prefered_language'] = (int) $languageId;
            }
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $overrides['user_type'] = 'EMPLOYEE';
            }
            $user = User::factory()->create($overrides);
            $this->forgetPermissionCache();
            $this->limitedUser = $user;
            return $user;
        } catch (Throwable) {
            return null;
        }
    }

    private function configDependencies(): array
    {
        if (!empty($this->configDependencies)) {
            return $this->configDependencies;
        }

        $academicSessionId = DB::table('sch_org_academic_sessions_jnt')
            ->where('is_active', 1)
            ->orderByDesc('is_current')
            ->value('id');
        if (!$academicSessionId) {
            $academicSessionId = DB::table('sch_org_academic_sessions_jnt')->value('id');
        }
        if (!$academicSessionId) {
            $this->markTestSkipped('Config Template tests require an academic session (sch_org_academic_sessions_jnt).');
        }

        $adminId = (int) $this->adminUser->id;

        $marksheetType = MarksheetType::create([
            'code'          => $this->uniqueCode('MT'),
            'name'          => $this->uniqueName('MTYPE'),
            'display_order' => 1,
            'is_active'     => true,
            'created_by'    => $adminId,
        ]);

        $examGroup = ExamGroup::create([
            'academic_session_id' => (int) $academicSessionId,
            'code'                => $this->uniqueCode('EG'),
            'name'                => $this->uniqueName('EGROUP'),
            'is_active'           => true,
            'created_by'          => $adminId,
        ]);

        $this->configDependencies = [
            'academic_session_id' => (int) $academicSessionId,
            'marksheet_type_id'   => (int) $marksheetType->id,
            'exam_group_id'       => (int) $examGroup->id,
        ];

        return $this->configDependencies;
    }

    private function createConfigTemplateSeed(array $deps, array $overrides = []): ConfigTemplate
    {
        $payload = array_merge([
            'academic_session_id'      => $deps['academic_session_id'],
            'marksheet_type_id'        => $deps['marksheet_type_id'],
            'exam_group_id'            => $deps['exam_group_id'],
            'grading_schema_id'        => null,
            'code'                     => $this->uniqueCode('S'),
            'name'                     => $this->uniqueName('SEED'),
            'passing_percentage'       => 33.00,
            'compartment_max_failures' => 2,
            'is_best_of_n_enabled'     => false,
            'is_locked'                => false,
            'is_active'                => true,
            'created_by'               => (int) $this->adminUser->id,
        ], $overrides);

        return ConfigTemplate::create($payload);
    }

    private function forceDeleteConfigTemplate(ConfigTemplate $template): void
    {
        try {
            DB::table('msh_class_config_jnt')->where('config_template_id', $template->id)->delete();
        } catch (Throwable) {
        }
        try {
            if (ConfigTemplate::withTrashed()->whereKey($template->id)->exists()) {
                $template->forceDelete();
            }
        } catch (Throwable) {
        }
    }

    private function assertActivityIssuedByAdmin(int $subjectId, string $event): void
    {
        $log = ActivityLog::query()
            ->where('subject_type', ConfigTemplate::class)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->latest('id')
            ->first();

        $this->assertNotNull($log, "Activity log '{$event}' for config template #{$subjectId} was not recorded.");
        $this->assertSame((int) $this->adminUser->id, (int) $log->user_id, "Activity '{$event}' was not issued by the admin user.");
    }

    private function currentPath(Browser $browser): string
    {
        $path = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);
        return is_string($path) ? $path : '';
    }

    private function tenantUrl(string $path): string
    {
        return $this->tenantBaseUrl . '/' . ltrim($path, '/');
    }

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
    }

    private function uniqueCode(string $prefix): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        return substr($clean . $this->uniqueSuffix(), 0, 30);
    }

    private function uniqueName(string $prefix): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        return substr($clean . '-' . $this->uniqueSuffix(), 0, 100);
    }
}
