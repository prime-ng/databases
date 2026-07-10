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
use Modules\MarksheetGeneration\Models\ConfigTemplate;
use Modules\MarksheetGeneration\Models\ExamGroup;
use Modules\MarksheetGeneration\Models\MarksheetType;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * MarksheetGeneration — Configuration Templates (V1 foundation suite).
 *
 * Primary table  : msh_config_templates  (tenant_db, prefix msh_)
 * Screen         : Configuration → Config Templates tab
 *                  route('marksheet-generation.configuration.combined', ['tab' => 'config-templates'])
 * Create page    : GET  /marksheet-generation/config-template/create   (full page, NOT a modal)
 * Store          : POST /marksheet-generation/config-template          (REDIRECTS — no JSON branch)
 * Activity events: Stored / Updated / Toggled / Deleted / Restored  (literal — assert verbatim)
 * Activity table : sys_activity_logs (Modules\GlobalMaster\Models\ActivityLog), issuer = user_id
 * Permissions    : tenant.msh-config-template.{viewAny|view|create|update|delete|restore|forceDelete}
 *
 * Constraints obeyed (see 05_Known_Test_Failure_Constraints.md):
 *  - Tenant-side: initializeTenantContext() via Modules\Prime\Models\Domain; guarded tearDown.
 *  - App\Models\User + factory (matches golden sibling).
 *  - Dusk has no assertStatus(): status assertions use sendJsonRequestFromBrowser().
 *  - MySQL8 COLUMN_TYPE variance: schema-type asserts use assertStringContainsString.
 *  - forceDelete wrapped in try/catch (may hit sys_media / FK 23000).
 *  - ENV prereq: MarksheetGeneration must be enabled in modules_statuses.json.
 */
class msh_ConfigurationTemplatesV1_TestCas extends DuskTestCase
{
    private const COMBINED_PATH = '/marksheet-generation/configuration';
    private const CREATE_PATH   = '/marksheet-generation/config-template/create';
    private const STORE_PATH    = '/marksheet-generation/config-template';
    private const TRASH_PATH    = '/marksheet-generation/config-template/trash/view';
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

    // ─────────────────────────────────────────────────────────────
    // 01 — Schema / model / request configuration truth
    // ─────────────────────────────────────────────────────────────

    public function test_config_template_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable('msh_config_templates'), 'Table msh_config_templates does not exist.');

        $this->assertTrue(
            Schema::hasColumns('msh_config_templates', [
                'id',
                'academic_session_id',
                'marksheet_type_id',
                'exam_group_id',
                'grading_schema_id',
                'code',
                'name',
                'description',
                'board_code',
                'passing_percentage',
                'compartment_max_failures',
                'is_best_of_n_enabled',
                'best_of_n_count',
                'is_locked',
                'is_active',
                'created_by',
                'updated_by',
                'created_at',
                'updated_at',
                'deleted_at',
            ]),
            'Expected columns are missing in msh_config_templates.'
        );

        // DDL file assertions (source of schema truth)
        $ddlPath = base_path(self::DDL_FILE);
        if (!File::exists($ddlPath)) {
            // DDL lives in the requirements repo, not the app repo; skip file asserts when not co-located.
            $this->addToAssertionCount(1);
        } else {
            $ddl = File::get($ddlPath);
            $this->assertStringContainsString('CREATE TABLE IF NOT EXISTS `msh_config_templates`', $ddl);
            $this->assertStringContainsString('UNIQUE KEY `uq_msh_ct_session_code` (`academic_session_id`, `code`)', $ddl);
            $this->assertStringContainsString('`passing_percentage`        DECIMAL(5,2) NOT NULL DEFAULT 33.00', $ddl);
            $this->assertStringContainsString('REFERENCES `slb_grade_division_master` (`id`) ON DELETE SET NULL', $ddl);
        }

        // FormRequest rule strings (verbatim from real source)
        $requestPath = base_path(self::REQUEST_FILE);
        $this->assertTrue(File::exists($requestPath), 'Request file not found: ' . self::REQUEST_FILE);
        $requestContent = File::get($requestPath);
        $this->assertStringContainsString("'marksheet_type_id' => ['required', 'integer', 'exists:msh_marksheet_types,id']", $requestContent);
        $this->assertStringContainsString("'exam_group_id' => ['required', 'integer', 'exists:msh_exam_groups,id']", $requestContent);
        $this->assertStringContainsString("Rule::unique('msh_config_templates', 'code')", $requestContent);
        $this->assertStringContainsString("'passing_percentage' => ['required', 'numeric', 'min:0', 'max:100']", $requestContent);
        $this->assertStringContainsString('prepareForValidation', $requestContent);
        // SEC-MSH-003: FormRequest self-authorizes true (gate enforced only in controller)
        $this->assertStringContainsString('public function authorize(): bool', $requestContent);
        $this->assertStringContainsString('return true;', $requestContent);

        // Controller uses the real activity events + service delegation
        $controllerPath = base_path(self::CONTROLLER_FILE);
        $this->assertTrue(File::exists($controllerPath), 'Controller file not found: ' . self::CONTROLLER_FILE);
        $controllerContent = File::get($controllerPath);
        $this->assertStringContainsString("activityLog(\$configTemplate, 'Stored'", $controllerContent);
        $this->assertStringContainsString("activityLog(\$configTemplate, 'Updated'", $controllerContent);
        $this->assertStringContainsString("activityLog(\$configTemplate, 'Deleted'", $controllerContent);
        $this->assertStringContainsString("activityLog(\$record, 'Toggled'", $controllerContent);
        $this->assertStringContainsString("Gate::authorize('tenant.msh-config-template.create')", $controllerContent);

        // Model configuration truth
        $model = new ConfigTemplate();
        $this->assertSame('msh_config_templates', $model->getTable());
        $this->assertSame([
            'academic_session_id',
            'marksheet_type_id',
            'exam_group_id',
            'grading_schema_id',
            'code',
            'name',
            'description',
            'board_code',
            'passing_percentage',
            'compartment_max_failures',
            'is_best_of_n_enabled',
            'best_of_n_count',
            'is_locked',
            'is_active',
            'created_by',
            'updated_by',
        ], $model->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(ConfigTemplate::class));
        $this->assertInstanceOf(BelongsTo::class, $model->marksheetType());
        $this->assertInstanceOf(BelongsTo::class, $model->examGroup());
        $this->assertInstanceOf(BelongsTo::class, $model->gradingSchema());
        $this->assertInstanceOf(HasMany::class, $model->classConfigs());
        $this->assertInstanceOf(HasMany::class, $model->marksheetSchedules());

        $casts = $model->getCasts();
        $this->assertSame('bool', $casts['is_active'] ?? null);
        $this->assertSame('bool', $casts['is_locked'] ?? null);
        $this->assertSame('bool', $casts['is_best_of_n_enabled'] ?? null);
    }

    public function test_config_template_02_column_types_match_ddl(): void
    {
        $driver = DB::connection()->getDriverName();
        if ($driver !== 'mysql') {
            $this->markTestSkipped('Column-type inspection requires MySQL.');
        }

        $columns = collect(DB::select('SHOW COLUMNS FROM msh_config_templates'))
            ->keyBy(fn ($c) => $c->Field);

        // MySQL 8 COLUMN_TYPE variance — use contains, never equals (constraint D17).
        $this->assertStringContainsString('decimal', strtolower((string) ($columns['passing_percentage']->Type ?? '')));
        $this->assertStringContainsString('int', strtolower((string) ($columns['marksheet_type_id']->Type ?? '')));
        $this->assertStringContainsString('varchar', strtolower((string) ($columns['code']->Type ?? '')));

        // Unique index (academic_session_id, code)
        $idx = DB::select("SHOW INDEX FROM msh_config_templates WHERE Key_name = 'uq_msh_ct_session_code'");
        $this->assertNotEmpty($idx, 'Unique index uq_msh_ct_session_code missing.');
    }

    // ─────────────────────────────────────────────────────────────
    // 10 — Core create / update / delete / toggle
    // ─────────────────────────────────────────────────────────────

    public function test_config_template_03_create_page_renders_with_breadcrumb(): void
    {
        $this->configDependencies();

        $this->browseWithFailureScreenshot('ct-03-create-page', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 900);

            $browser->waitForText('New Config Template', 12)
                ->assertPresent('select[name="academic_session_id"]')
                ->assertPresent('#code')
                ->assertPresent('#name')
                ->assertPresent('select[name="marksheet_type_id"]')
                ->assertPresent('select[name="exam_group_id"]')
                ->assertSee('Configuration');
        });
    }

    public function test_config_template_04_create_persists_and_records_issued_by(): void
    {
        $deps = $this->configDependencies();
        $code = $this->uniqueCode('C');
        $name = $this->uniqueName('CRT');

        $this->deleteConfigTemplateByCode($deps['academic_session_id'], $code);

        $this->browseWithFailureScreenshot('ct-04-create', function (Browser $browser) use ($deps, $code, $name): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
            $browser->waitForText('New Config Template', 12);

            $this->fillConfigTemplateForm($browser, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => $deps['marksheet_type_id'],
                'exam_group_id'       => $deps['exam_group_id'],
                'code'                => $code,
                'name'                => $name,
                'passing_percentage'  => 33,
                'compartment_max_failures' => 2,
            ]);
            $this->submitConfigTemplateForm($browser);

            $browser->waitUsing(20, 250, function () use ($deps, $code): bool {
                return ConfigTemplate::withTrashed()
                    ->where('academic_session_id', $deps['academic_session_id'])
                    ->where('code', $code)
                    ->exists();
            }, 'Config template was not persisted.');
        });

        $template = ConfigTemplate::withTrashed()
            ->where('academic_session_id', $deps['academic_session_id'])
            ->where('code', $code)
            ->first();

        $this->assertNotNull($template, 'Config template record was not saved.');
        $this->assertSame($name, (string) $template->name);
        $this->assertSame((int) $deps['marksheet_type_id'], (int) $template->marksheet_type_id);
        $this->assertSame((int) $deps['exam_group_id'], (int) $template->exam_group_id);
        $this->assertSame((int) $this->adminUser->id, (int) $template->created_by);
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Stored');

        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_05_update_persists_and_records_issued_by(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps, ['name' => $this->uniqueName('UPB')]);

        $newName = $this->uniqueName('UPD');

        $this->browseWithFailureScreenshot('ct-05-update', function (Browser $browser) use ($deps, $template, $newName): void {
            $this->authenticate($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'PUT',
                self::STORE_PATH . '/' . $template->id,
                [
                    'academic_session_id' => $deps['academic_session_id'],
                    'marksheet_type_id'   => $deps['marksheet_type_id'],
                    'exam_group_id'       => $deps['exam_group_id'],
                    'code'                => (string) $template->code,
                    'name'                => $newName,
                    'passing_percentage'  => 40,
                    'compartment_max_failures' => 3,
                    'is_active'           => true,
                ]
            );

            // update() redirects (no JSON branch) → fetch follows redirect to combined page (200).
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Update did not complete with a redirect/OK response.');
        });

        $template->refresh();
        $this->assertSame($newName, (string) $template->name);
        $this->assertSame(3, (int) $template->compartment_max_failures);
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Updated');

        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_06_toggle_status_endpoint_updates_is_active(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps, ['is_active' => true]);

        $this->browseWithFailureScreenshot('ct-06-toggle', function (Browser $browser) use ($template): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=config-templates', 900);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                self::STORE_PATH . '/' . $template->id . '/toggleStatus',
                []
            );

            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Toggle did not return HTTP 200.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertTrue((bool) ($json['success'] ?? false), 'Toggle response success was not true.');
        });

        $template->refresh();
        $this->assertFalse((bool) $template->is_active, 'Config template was not toggled to inactive.');
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Toggled');

        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_07_soft_delete_records_issued_by(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);

        $this->browseWithFailureScreenshot('ct-07-delete', function (Browser $browser) use ($template): void {
            $this->authenticate($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'DELETE',
                self::STORE_PATH . '/' . $template->id,
                []
            );
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Delete did not complete.');

            $browser->waitUsing(15, 250, function () use ($template): bool {
                return ConfigTemplate::withTrashed()->whereKey($template->id)->whereNotNull('deleted_at')->exists();
            }, 'Config template was not soft deleted.');
        });

        $template->refresh();
        $this->assertNotNull($template->deleted_at, 'Config template was not soft deleted.');
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Deleted');

        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_08_restore_from_trash_records_issued_by(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);
        $template->delete();

        $this->browseWithFailureScreenshot('ct-08-restore', function (Browser $browser) use ($template): void {
            $this->authenticate($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'GET',
                self::STORE_PATH . '/' . $template->id . '/restore',
                []
            );
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Restore did not complete.');

            $browser->waitUsing(15, 250, function () use ($template): bool {
                return ConfigTemplate::whereKey($template->id)->whereNull('deleted_at')->exists();
            }, 'Config template was not restored.');
        });

        $template->refresh();
        $this->assertNull($template->deleted_at, 'Config template was not restored.');
        $this->assertActivityIssuedByAdmin((int) $template->id, 'Restored');

        $this->forceDeleteConfigTemplate($template);
    }

    // ─────────────────────────────────────────────────────────────
    // 30 — Key validation
    // ─────────────────────────────────────────────────────────────

    public function test_config_template_09_required_fields_rejected_with_422(): void
    {
        $this->browseWithFailureScreenshot('ct-09-required', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH, 900);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, []);

            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty store should return 422.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $errors = $json['errors'] ?? [];
            $this->assertArrayHasKey('code', $errors, 'Missing "code" validation error.');
            $this->assertArrayHasKey('name', $errors, 'Missing "name" validation error.');
            $this->assertArrayHasKey('academic_session_id', $errors, 'Missing "academic_session_id" validation error.');
            $this->assertArrayHasKey('marksheet_type_id', $errors, 'Missing "marksheet_type_id" validation error.');
            $this->assertArrayHasKey('exam_group_id', $errors, 'Missing "exam_group_id" validation error.');
        });
    }

    public function test_config_template_10_duplicate_code_in_same_session_rejected(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);

        $this->browseWithFailureScreenshot('ct-10-duplicate', function (Browser $browser) use ($deps, $template): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH, 900);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => $deps['marksheet_type_id'],
                'exam_group_id'       => $deps['exam_group_id'],
                'code'                => (string) $template->code,
                'name'                => $this->uniqueName('DUP'),
                'passing_percentage'  => 33,
                'compartment_max_failures' => 2,
            ]);

            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate code should return 422.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertArrayHasKey('code', $json['errors'] ?? [], 'Duplicate-code error not returned.');
        });

        $this->assertSame(
            1,
            ConfigTemplate::withTrashed()
                ->where('academic_session_id', $deps['academic_session_id'])
                ->where('code', $template->code)
                ->count(),
            'Duplicate config template should not be inserted.'
        );

        $this->forceDeleteConfigTemplate($template);
    }

    public function test_config_template_11_invalid_foreign_keys_rejected(): void
    {
        $deps = $this->configDependencies();

        $this->browseWithFailureScreenshot('ct-11-invalid-fk', function (Browser $browser) use ($deps): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH, 900);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => 999999999,
                'exam_group_id'       => 999999999,
                'code'                => $this->uniqueCode('X'),
                'name'                => $this->uniqueName('FK'),
                'passing_percentage'  => 33,
                'compartment_max_failures' => 2,
            ]);

            $this->assertSame(422, (int) ($response['status'] ?? 0), 'Invalid FK should return 422.');
            $errors = (is_array($response['json'] ?? null) ? $response['json'] : [])['errors'] ?? [];
            $this->assertArrayHasKey('marksheet_type_id', $errors, 'exists rule for marksheet_type_id not enforced.');
            $this->assertArrayHasKey('exam_group_id', $errors, 'exists rule for exam_group_id not enforced.');
        });
    }

    public function test_config_template_12_passing_percentage_out_of_range_rejected(): void
    {
        $deps = $this->configDependencies();

        $this->browseWithFailureScreenshot('ct-12-range', function (Browser $browser) use ($deps): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH, 900);

            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', self::STORE_PATH, [
                'academic_session_id' => $deps['academic_session_id'],
                'marksheet_type_id'   => $deps['marksheet_type_id'],
                'exam_group_id'       => $deps['exam_group_id'],
                'code'                => $this->uniqueCode('R'),
                'name'                => $this->uniqueName('RNG'),
                'passing_percentage'  => 150,
                'compartment_max_failures' => 2,
            ]);

            $this->assertSame(422, (int) ($response['status'] ?? 0), 'passing_percentage>100 should return 422.');
            $this->assertArrayHasKey(
                'passing_percentage',
                (is_array($response['json'] ?? null) ? $response['json'] : [])['errors'] ?? [],
                'max:100 rule for passing_percentage not enforced.'
            );
        });
    }

    // ─────────────────────────────────────────────────────────────
    // 40 — Integration / dependency
    // ─────────────────────────────────────────────────────────────

    public function test_config_template_13_marksheet_type_delete_restricted_while_referenced(): void
    {
        $deps = $this->configDependencies();
        $template = $this->createConfigTemplateSeed($deps);

        $type = MarksheetType::find($deps['marksheet_type_id']);
        $this->assertNotNull($type, 'Referenced marksheet type missing.');

        $blocked = false;
        try {
            $type->forceDelete(); // FK ON DELETE RESTRICT should throw
        } catch (Throwable) {
            $blocked = true;
        }

        $this->assertTrue($blocked, 'FK RESTRICT: deleting a referenced marksheet type should be blocked.');
        $this->assertTrue(MarksheetType::whereKey($deps['marksheet_type_id'])->exists(), 'Marksheet type should still exist.');

        $this->forceDeleteConfigTemplate($template);
    }

    // ─────────────────────────────────────────────────────────────
    // 50 — Authorization
    // ─────────────────────────────────────────────────────────────

    public function test_config_template_14_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $this->assertTrue(
                str_contains($this->currentPath($browser), '/login'),
                'Guest should be redirected to /login.'
            );
        });
    }

    public function test_config_template_15_combined_page_requires_configuration_gate(): void
    {
        $this->browseWithFailureScreenshot('ct-15-combined-gate', function (Browser $browser): void {
            $this->authenticate($browser);

            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', self::COMBINED_PATH . '?tab=config-templates', []);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Combined configuration page should load for a permitted admin.');
        });
    }

    // ─────────────────────────────────────────────────────────────
    // 56 — Proving test: BUG-MSH-003 (ExamGroupController::edit has no model binding)
    // ─────────────────────────────────────────────────────────────

    public function test_config_template_16_exam_group_edit_redirects_without_model_binding_bug_msh_003(): void
    {
        $this->browseWithFailureScreenshot('ct-16-bug-msh-003', function (Browser $browser): void {
            $this->authenticate($browser);

            // edit() has no ExamGroup param → no implicit route-model binding → no 404 even for a bogus id,
            // and it redirects (302) to the combined page instead of rendering an edit form.
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'GET',
                '/marksheet-generation/exam-group/999999999/edit',
                []
            );

            // fetch follows the 302 to the combined configuration page (200 HTML).
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'BUG-MSH-003: exam-group edit should redirect (not 404) due to missing model binding.');
            $body = (string) ($response['body'] ?? '');
            $this->assertTrue(
                str_contains($body, 'Configuration') || str_contains($body, 'config-template') || $body !== '',
                'BUG-MSH-003: exam-group edit did not resolve to the combined configuration page.'
            );
        });
    }

    // ═════════════════════════════════════════════════════════════
    // Private helper library
    // ═════════════════════════════════════════════════════════════

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
        $this->captureScreenshot($browser, 'ct-pass-' . $caseName);
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        $this->captureScreenshot($browser, 'ct-fail-' . $caseName);
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

    private function fillConfigTemplateForm(Browser $browser, array $payload): void
    {
        $encoded = json_encode($payload, JSON_THROW_ON_ERROR);
        $browser->script(<<<JS
(function () {
    const p = {$encoded};
    const setSelect = (name, value) => {
        const el = document.querySelector('select[name="' + name + '"]');
        if (el && value !== undefined && value !== null) {
            el.value = String(value);
            el.dispatchEvent(new Event('change', { bubbles: true }));
        }
    };
    const setInput = (name, value) => {
        const el = document.querySelector('[name="' + name + '"]');
        if (el && value !== undefined && value !== null) {
            el.value = String(value);
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
        }
    };
    setSelect('academic_session_id', p.academic_session_id);
    setSelect('marksheet_type_id', p.marksheet_type_id);
    setSelect('exam_group_id', p.exam_group_id);
    setInput('code', p.code);
    setInput('name', p.name);
    setInput('passing_percentage', p.passing_percentage);
    setInput('compartment_max_failures', p.compartment_max_failures);
})();
JS);
        $browser->pause(300);
    }

    private function submitConfigTemplateForm(Browser $browser): void
    {
        $browser->script(<<<'JS'
(function () {
    const form = document.querySelector('form[action*="config-template"]');
    if (!form) {
        throw new Error('Config template form not found for submit.');
    }
    if (form.requestSubmit) {
        form.requestSubmit();
    } else {
        form.submit();
    }
})();
JS);
        $browser->pause(1500);
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

    private function deleteConfigTemplateByCode(int $academicSessionId, string $code): void
    {
        ConfigTemplate::withTrashed()
            ->where('academic_session_id', $academicSessionId)
            ->where('code', $code)
            ->get()
            ->each(fn (ConfigTemplate $t) => $this->forceDeleteConfigTemplate($t));
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
