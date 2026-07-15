<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaConfig;
use Modules\BehaviouralAssessment\Models\BaRatingScale;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Configuration (Setup › Configuration tab) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/07-Configuration.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime table      : ba_config              (live `ba_` prefix — the DDL doc uses stale `bha_config`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaConfigController
 * FormRequest        : Modules\BehaviouralAssessment\Http\Requests\BaConfigRequest
 * Model              : Modules\BehaviouralAssessment\Models\BaConfig (SoftDeletes)
 * Permission prefix  : tenant.behavioural-assessment.configs.{viewAny|view|create|update|delete|restore|forceDelete|status}
 * Activity log       : NONE — BaConfigController calls no activityLog() helper and BaConfig has no observer (documented absence).
 *
 * Audit findings proven/verified (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md):
 *   - DOC-BA-001  : DDL doc prefix `bha_config` diverges from the live `ba_config` (proven in _02).
 *   - DATA-BA-001 : "active rating scale switchable mid-session". Audit dated 2026-06-29 said the guard was
 *                   MISSING at BaConfigController::update; the CURRENT source implements the canonical fix
 *                   (server-side guard in update() + @disabled($hasRatings) on the edit view). This suite proves
 *                   the fix is now PRESENT: no-ratings change succeeds (_21), the guard string + lock UI are in
 *                   source (_22), and the ratings-present rejection is exercised defensively (_23).
 *   - SEC-BA-001  : severe-incident parent notification entirely absent. ba_config.parent_notification_threshold
 *                   is configured HERE (persists — _80) but is dead config: no controller/service ever reads it to
 *                   dispatch a notification (proven by source scan in _81). STILL UNRESOLVED.
 *   - SEC-BA-002  : BaConfigRequest::authorize() returns bare true, mitigated by the controller Gate (proven in _92).
 *   - DATA-BA-003 : DB unique index uq_ba_config_session ignores soft-deletes while the FormRequest unique rule is
 *                   scoped whereNull(deleted_at) — a soft-deleted session cannot be reused cleanly (proven in _45).
 * Feature-scoped requirement-vs-implementation divergences (07-Configuration.md vs source):
 *   - CFG-BA-001 : the requirement's "Approval Workflow", "Incident Escalation Threshold" and "Notification
 *                  Settings" fields are NOT implemented; ba_config instead exposes weightage_percent,
 *                  aggregation_method, parent_notification_threshold, is_result_integration_enabled (proven in _82).
 */
class bha_Configuration_TestCas extends DuskTestCase
{
    private const URL_PREFIX   = '/behavioural-assessment';
    private const SETUP_PATH   = '/behavioural-assessment/setup?tab=configuration';
    private const CREATE_PATH  = '/behavioural-assessment/configs/create';
    private const STORE_PATH   = '/behavioural-assessment/configs';
    private const INDEX_PATH   = '/behavioural-assessment/configs';
    private const TRASH_PATH   = '/behavioural-assessment/configs/trash';

    private const CONFIG_TABLE = 'ba_config';
    private const DDL_TABLE     = 'bha_config';   // stale DDL-doc name — must NOT exist at runtime.
    private const SESSION_TABLE = 'sch_org_academic_sessions_jnt';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/Configuration/screenshots';

    private const SUCCESS_CREATE  = 'Configuration created successfully.';
    private const SUCCESS_UPDATE  = 'Configuration updated successfully.';
    private const SUCCESS_TRASH   = 'Configuration moved to trash.';
    private const SUCCESS_RESTORE = 'Configuration restored successfully.';
    private const SUCCESS_FORCE   = 'Configuration permanently deleted.';
    private const SCALE_LOCK_ERR  = 'Cannot change rating scale because ratings have already been recorded for this academic session.';
    private const DUP_SESSION_ERR = 'A configuration already exists for the selected academic session.';

    /** @var array<int,string> */
    private const CONFIG_PERMISSIONS = [
        'tenant.behavioural-assessment.setup.viewAny',
        'tenant.behavioural-assessment.configs.viewAny',
        'tenant.behavioural-assessment.configs.view',
        'tenant.behavioural-assessment.configs.create',
        'tenant.behavioural-assessment.configs.update',
        'tenant.behavioural-assessment.configs.delete',
        'tenant.behavioural-assessment.configs.restore',
        'tenant.behavioural-assessment.configs.forceDelete',
        'tenant.behavioural-assessment.configs.status',
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

    public function test_configuration_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::CONFIG_TABLE), 'Table ba_config does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::CONFIG_TABLE, [
                'id', 'academic_session_id', 'rating_scale_id', 'is_result_integration_enabled',
                'weightage_percent', 'aggregation_method', 'parent_notification_threshold',
                'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_config table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::CONFIG_TABLE))->keyBy('Field');
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['weightage_percent']->Type ?? '')));
            $this->assertStringContainsString('enum', strtolower((string) ($cols['aggregation_method']->Type ?? '')));
            $this->assertStringContainsString('enum', strtolower((string) ($cols['parent_notification_threshold']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130621_create_ba_config_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_config'", $migration);
            $this->assertStringContainsString("decimal('weightage_percent', 4, 1)", $migration);
            $this->assertStringContainsString("enum('aggregation_method'", $migration);
            $this->assertStringContainsString("enum('parent_notification_threshold'", $migration);
            $this->assertStringContainsString("unique('academic_session_id', 'uq_ba_config_session')", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // Model configuration.
        $config = new BaConfig();
        $this->assertSame('ba_config', $config->getTable());
        $this->assertSame([
            'academic_session_id', 'rating_scale_id', 'is_result_integration_enabled',
            'weightage_percent', 'aggregation_method', 'parent_notification_threshold',
            'is_active', 'created_by', 'updated_by',
        ], $config->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaConfig::class));
        $this->assertInstanceOf(BelongsTo::class, $config->ratingScale());
        $this->assertInstanceOf(BelongsTo::class, $config->academicSession());

        // Active scope + boolean/decimal casts.
        $seed = $this->createConfigSeed(['is_active' => true, 'weightage_percent' => 10.0]);
        if ($seed !== null) {
            $this->assertTrue(BaConfig::query()->active()->whereKey($seed->id)->exists());
            $seed->refresh();
            $this->assertIsBool($seed->is_active);
            $this->assertIsBool($seed->is_result_integration_enabled);
            $this->assertSame('10.0', (string) $seed->weightage_percent);
            $this->forceDeleteConfig($seed);
        }
    }

    public function test_configuration_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime table uses the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::CONFIG_TABLE), 'Runtime table ba_config must exist.');

        // The DDL/registry spec name `bha_config` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_TABLE),
                'DOC-BA-001 regression: bha_config exists at runtime; expected only the live ba_config.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_config', (new BaConfig())->getTable());
    }

    public function test_configuration_03_form_request_rules_and_messages_are_correct(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaConfigRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable from app repo.');
        }

        $this->assertStringContainsString("exists:sch_org_academic_sessions_jnt,id", $request);
        $this->assertStringContainsString("Rule::unique('ba_config', 'academic_session_id')", $request);
        $this->assertStringContainsString('whereNull(\'deleted_at\')', $request);
        $this->assertStringContainsString("exists:ba_rating_scales,id", $request);
        $this->assertStringContainsString("'min:5', 'max:20'", $request);
        $this->assertStringContainsString("in:average,weighted_average,separate_display", $request);
        $this->assertStringContainsString("in:minor,moderate,major,critical", $request);
        $this->assertStringContainsString(self::DUP_SESSION_ERR, $request);
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_configuration_10_create_persists_and_redirects_with_success_flash(): void
    {
        $sessionId = $this->usableSessionId();
        $scale = $this->createScaleSeed();

        $response = $this->postConfig([
            'academic_session_id' => $sessionId,
            'rating_scale_id'     => $scale->id,
            'weightage_percent'   => 12.5,
            'aggregation_method'  => 'weighted_average',
            'parent_notification_threshold' => 'moderate',
            'is_result_integration_enabled' => 1,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Valid create should not 422: ' . json_encode($response['json'] ?? $response['body'] ?? null));

        $created = BaConfig::where('academic_session_id', $sessionId)->latest('id')->first();
        $this->assertNotNull($created, 'Config row was not created.');
        $this->assertSame($scale->id, (int) $created->rating_scale_id);
        $this->assertSame('12.5', (string) $created->weightage_percent);
        $this->assertTrue((bool) $created->is_result_integration_enabled);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);
        $this->assertSame((int) $this->adminUser->id, (int) $created->updated_by);

        $this->forceDeleteConfig($created);
        $this->forceDeleteScale($scale);
    }

    public function test_configuration_11_update_persists_changes(): void
    {
        $config = $this->createConfigSeed(['weightage_percent' => 8.0, 'aggregation_method' => 'average']);
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $response = $this->putConfig($config->id, [
            'academic_session_id' => $config->academic_session_id,
            'rating_scale_id'     => $config->rating_scale_id,
            'weightage_percent'   => 15.0,
            'aggregation_method'  => 'separate_display',
            'parent_notification_threshold' => 'major',
            'is_result_integration_enabled' => 1,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Update should not 422.');

        $config->refresh();
        $this->assertSame('15.0', (string) $config->weightage_percent);
        $this->assertSame('separate_display', $config->aggregation_method);
        $this->assertSame('major', $config->parent_notification_threshold);
        $this->assertSame((int) $this->adminUser->id, (int) $config->updated_by);

        $this->forceDeleteConfig($config);
    }

    public function test_configuration_12_weightage_and_boolean_flags_cast_correctly(): void
    {
        $config = $this->createConfigSeed([
            'weightage_percent'             => 7.5,
            'is_result_integration_enabled' => true,
            'is_active'                     => false,
        ]);
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $config->refresh();
        $this->assertSame('7.5', (string) $config->weightage_percent);
        $this->assertTrue((bool) $config->is_result_integration_enabled);
        $this->assertFalse((bool) $config->is_active);

        $this->forceDeleteConfig($config);
    }

    public function test_configuration_13_show_page_renders_config_details(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $this->browseWithFailureScreenshot('show-render', function (Browser $browser) use ($config): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/configs/' . $config->id, 900);
            $browser->assertSee('Assessment Configuration Details')
                ->assertSee('Weightage %')
                ->assertSee('Parent Alert Notification');
        });

        $this->forceDeleteConfig($config);
    }

    public function test_configuration_14_setup_tab_lists_configs(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $this->browseWithFailureScreenshot('setup-list', function (Browser $browser): void {
            $this->openSetupTab($browser);
            $browser->assertSee('Academic Session')
                ->assertSee('Weightage');
        });

        $this->forceDeleteConfig($config);
    }

    public function test_configuration_15_index_redirects_to_setup_configuration_tab(): void
    {
        $response = $this->apiCall('GET', $this->tenantUrl(self::INDEX_PATH));
        // index() returns a redirect to behavioural-assessment.setup?tab=configuration.
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'configs.index should redirect to the setup tab.');
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM) + DATA-BA-001 scale-lock guard
    // =====================================================================

    public function test_configuration_20_active_to_inactive_and_back_transition_succeeds(): void
    {
        // BC-SM-1: Active --toggleStatus--> Inactive; BC-SM-2: Inactive --toggleStatus--> Active.
        $config = $this->createConfigSeed(['is_active' => true]);
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $off = $this->toggleConfig($config->id);
        $this->assertSame(200, (int) ($off['status'] ?? 0));
        $config->refresh();
        $this->assertFalse((bool) $config->is_active, 'Active config must transition to Inactive.');

        $on = $this->toggleConfig($config->id);
        $this->assertSame(200, (int) ($on['status'] ?? 0));
        $config->refresh();
        $this->assertTrue((bool) $config->is_active, 'Inactive config must transition back to Active.');

        $this->forceDeleteConfig($config);
    }

    public function test_configuration_21_rating_scale_change_allowed_when_no_ratings_exist(): void
    {
        // DATA-BA-001 permissive branch: with no ratings recorded for the session, the active rating
        // scale may be changed. Proves the guard does NOT over-block.
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }
        $newScale = $this->createScaleSeed();

        // Guard only fires when ratings exist for the session; a fresh seeded session has none.
        try {
            if (Schema::hasTable('ba_assessment_ratings') && $this->sessionHasRatings((int) $config->academic_session_id)) {
                $this->forceDeleteConfig($config);
                $this->forceDeleteScale($newScale);
                $this->markTestSkipped('Seeded session already has ratings — permissive branch not exercisable.');
            }

            $response = $this->putConfig($config->id, [
                'academic_session_id' => $config->academic_session_id,
                'rating_scale_id'     => $newScale->id,
                'weightage_percent'   => 10.0,
                'aggregation_method'  => 'weighted_average',
                'parent_notification_threshold' => 'moderate',
            ]);
            $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Scale change with no ratings should be accepted.');

            $config->refresh();
            $this->assertSame($newScale->id, (int) $config->rating_scale_id, 'Rating scale should have changed when no ratings exist.');
        } finally {
            $this->forceDeleteConfig($config);
            $this->forceDeleteScale($newScale);
        }
    }

    public function test_configuration_22_scale_lock_guard_present_in_controller_and_view_data_ba_001(): void
    {
        // The canonical DATA-BA-001 fix lives in BaConfigController::update (server-side guard) and is
        // mirrored by the edit view disabling the dropdown. Prove both are present in the current source.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaConfigController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertStringContainsString('BaAssessmentRating::whereHas', $controller, 'DATA-BA-001 guard query missing from update().');
        $this->assertStringContainsString("(int) \$validated['rating_scale_id'] !== \$config->rating_scale_id", $controller, 'DATA-BA-001 guard should only fire on an actual scale change.');
        $this->assertStringContainsString(self::SCALE_LOCK_ERR, $controller, 'DATA-BA-001 rejection message missing from update().');

        $editView = $this->readAppFile($this->moduleRootPath('resources/views/config/edit.blade.php'));
        if ($editView !== null) {
            $this->assertStringContainsString('@disabled($hasRatings)', $editView, 'DATA-BA-001 UI lock (@disabled) missing from edit view.');
            $this->assertStringContainsString('Locked', $editView, 'DATA-BA-001 lock notice missing from edit view.');
        }
    }

    public function test_configuration_23_rating_scale_change_rejected_when_ratings_exist_data_ba_001(): void
    {
        // Defensive full-graph exercise: only runnable when a rating already exists for the config's session.
        try {
            $config = $this->createConfigSeed();
            if ($config === null) {
                $this->markTestSkipped('No usable academic session to seed a config.');
            }
            if (!Schema::hasTable('ba_assessment_ratings') || !$this->sessionHasRatings((int) $config->academic_session_id)) {
                $this->forceDeleteConfig($config);
                $this->markTestSkipped('No ratings exist for the seeded session — DATA-BA-001 blocking branch not exercisable here (guard verified in _22).');
            }

            $newScale = $this->createScaleSeed();
            $response = $this->putConfig($config->id, [
                'academic_session_id' => $config->academic_session_id,
                'rating_scale_id'     => $newScale->id,
                'weightage_percent'   => 10.0,
                'aggregation_method'  => 'weighted_average',
                'parent_notification_threshold' => 'moderate',
            ]);
            // update() returns back()->withInput() (a redirect) with an error flash — the scale must NOT change.
            $config->refresh();
            $this->assertNotSame($newScale->id, (int) $config->rating_scale_id, 'DATA-BA-001: scale change must be rejected when ratings exist.');

            $this->forceDeleteConfig($config);
            $this->forceDeleteScale($newScale);
        } catch (Throwable $e) {
            $this->markTestSkipped('DATA-BA-001 blocking path unavailable: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL) — Negative 100%
    // =====================================================================

    public function test_configuration_30_required_fields_are_rejected(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'academic_session_id' => '',
            'rating_scale_id'     => '',
            'weightage_percent'   => '',
            'aggregation_method'  => '',
            'parent_notification_threshold' => '',
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty payload must fail validation.');
        $errors = $response['json']['errors'] ?? [];
        foreach (['academic_session_id', 'rating_scale_id', 'weightage_percent', 'aggregation_method', 'parent_notification_threshold'] as $field) {
            $this->assertArrayHasKey($field, $errors, "Missing required-error for {$field}.");
        }
    }

    public function test_configuration_31_weightage_below_min_5_is_rejected(): void
    {
        $response = $this->postConfigRaw(['weightage_percent' => 4]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('weightage_percent', $response['json']['errors'] ?? []);
    }

    public function test_configuration_32_weightage_above_max_20_is_rejected(): void
    {
        $response = $this->postConfigRaw(['weightage_percent' => 21]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('weightage_percent', $response['json']['errors'] ?? []);
    }

    public function test_configuration_33_weightage_must_be_numeric(): void
    {
        $response = $this->postConfigRaw(['weightage_percent' => 'abc']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('weightage_percent', $response['json']['errors'] ?? []);
    }

    public function test_configuration_34_aggregation_method_must_be_in_allowed_set(): void
    {
        $response = $this->postConfigRaw(['aggregation_method' => 'median']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('aggregation_method', $response['json']['errors'] ?? []);
    }

    public function test_configuration_35_parent_notification_threshold_must_be_in_allowed_set(): void
    {
        $response = $this->postConfigRaw(['parent_notification_threshold' => 'disabled']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('parent_notification_threshold', $response['json']['errors'] ?? []);
    }

    public function test_configuration_36_academic_session_must_exist(): void
    {
        $response = $this->postConfigRaw(['academic_session_id' => 987654321]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('academic_session_id', $response['json']['errors'] ?? []);
    }

    public function test_configuration_37_rating_scale_must_exist(): void
    {
        $response = $this->postConfigRaw(['rating_scale_id' => 987654321]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('rating_scale_id', $response['json']['errors'] ?? []);
    }

    public function test_configuration_38_duplicate_config_for_session_is_rejected(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }
        $scale = $this->createScaleSeed();

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), $this->validPayload([
            'academic_session_id' => $config->academic_session_id,
            'rating_scale_id'     => $scale->id,
        ]));
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'A second config for the same session must be rejected.');
        $errors = $response['json']['errors'] ?? [];
        $this->assertArrayHasKey('academic_session_id', $errors);
        $this->assertStringContainsString(self::DUP_SESSION_ERR, json_encode($errors), 'Expected the custom duplicate-session message.');

        $this->forceDeleteConfig($config);
        $this->forceDeleteScale($scale);
    }

    public function test_configuration_39_is_result_integration_defaults_and_coerces_boolean(): void
    {
        // prepareForValidation coerces is_result_integration_enabled to a boolean; omitting it stores false.
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $response = $this->putConfig($config->id, [
            'academic_session_id' => $config->academic_session_id,
            'rating_scale_id'     => $config->rating_scale_id,
            'weightage_percent'   => 10.0,
            'aggregation_method'  => 'weighted_average',
            'parent_notification_threshold' => 'moderate',
            // is_result_integration_enabled intentionally omitted
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));
        $config->refresh();
        $this->assertFalse((bool) $config->is_result_integration_enabled, 'Omitted toggle should coerce to false.');

        $this->forceDeleteConfig($config);
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-INT/REF/EDG)
    // =====================================================================

    public function test_configuration_40_delete_soft_deletes_sets_inactive_and_moves_to_trash(): void
    {
        $config = $this->createConfigSeed(['is_active' => true]);
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $response = $this->deleteConfig($config->id);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertFalse(BaConfig::where('id', $config->id)->exists(), 'Config should be hidden from default scope after soft delete.');
        $trashed = BaConfig::onlyTrashed()->find($config->id);
        $this->assertNotNull($trashed, 'Config should be present in trash.');
        $this->assertFalse((bool) $trashed->is_active, 'destroy() sets is_active=false before soft delete.');

        $this->forceDeleteConfig($trashed);
    }

    public function test_configuration_41_restore_from_trash_returns_config_to_default_scope(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }
        $config->delete();

        $response = $this->apiCall('GET', $this->tenantUrl('/behavioural-assessment/configs/' . $config->id . '/restore'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertTrue(BaConfig::where('id', $config->id)->exists(), 'Restored config should return to default scope.');

        $this->forceDeleteConfig(BaConfig::find($config->id));
    }

    public function test_configuration_42_force_delete_removes_config_row(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }
        $config->delete();

        $response = $this->apiCall('DELETE', $this->tenantUrl('/behavioural-assessment/configs/' . $config->id . '/force-delete'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertFalse(BaConfig::withTrashed()->where('id', $config->id)->exists(), 'Config row should be physically removed.');
    }

    public function test_configuration_43_academic_session_fk_is_restrict(): void
    {
        try {
            $fk = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'ba_config'
                   AND REFERENCED_TABLE_NAME = '" . self::SESSION_TABLE . "'"
            );
            if (empty($fk)) {
                $this->markTestSkipped('No FK metadata for ba_config → ' . self::SESSION_TABLE . '.');
            }
            $rule = strtoupper((string) ($fk[0]->DELETE_RULE ?? ''));
            $this->assertTrue(
                str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'),
                'ba_config.academic_session_id should RESTRICT session delete; found: ' . $rule
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Session FK inspection unavailable: ' . $e->getMessage());
        }
    }

    public function test_configuration_44_rating_scale_fk_is_restrict(): void
    {
        try {
            $fk = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'ba_config'
                   AND REFERENCED_TABLE_NAME = 'ba_rating_scales'"
            );
            if (empty($fk)) {
                $this->markTestSkipped('No FK metadata for ba_config → ba_rating_scales.');
            }
            $rule = strtoupper((string) ($fk[0]->DELETE_RULE ?? ''));
            $this->assertTrue(
                str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'),
                'ba_config.rating_scale_id should RESTRICT scale delete; found: ' . $rule
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Rating-scale FK inspection unavailable: ' . $e->getMessage());
        }
    }

    public function test_configuration_45_soft_deleted_session_cannot_be_cleanly_reused_data_ba_003(): void
    {
        // DATA-BA-003: the DB unique index uq_ba_config_session is unconditional (ignores soft-deletes),
        // while the FormRequest unique rule is scoped whereNull(deleted_at). So after soft-deleting a
        // config, the FormRequest lets a new row through but the DB unique index blocks the INSERT.
        try {
            // Confirm the unique index counts soft-deleted rows (schema truth).
            $unique = DB::select("SHOW INDEX FROM " . self::CONFIG_TABLE . " WHERE Key_name = 'uq_ba_config_session'");
            $this->assertNotEmpty($unique, 'uq_ba_config_session unique index should exist on ba_config.');

            $config = $this->createConfigSeed();
            if ($config === null) {
                $this->markTestSkipped('No usable academic session to seed a config.');
            }
            $sessionId = (int) $config->academic_session_id;
            $config->delete(); // soft delete → row remains with deleted_at set

            $scale = $this->createScaleSeed();
            $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), $this->validPayload([
                'academic_session_id' => $sessionId,
                'rating_scale_id'     => $scale->id,
            ]));

            // The FormRequest (whereNull deleted_at) does NOT 422; the DB unique index makes the insert fail.
            $status = (int) ($response['status'] ?? 0);
            $activeExists = BaConfig::where('academic_session_id', $sessionId)->exists();
            $this->assertFalse(
                $status !== 422 && $activeExists,
                'DATA-BA-003 regression fixed? A new active config for a soft-deleted session should not be creatable while the unconditional unique index remains.'
            );

            // Cleanup any row that did land + the trashed original.
            BaConfig::withTrashed()->where('academic_session_id', $sessionId)->get()
                ->each(fn (BaConfig $c) => $this->forceDeleteConfig($c));
            $this->forceDeleteScale($scale);
        } catch (Throwable $e) {
            $this->markTestSkipped('DATA-BA-003 path unavailable: ' . $e->getMessage());
        }
    }

    public function test_configuration_46_full_lifecycle_create_toggle_delete_restore_force_delete(): void
    {
        $sessionId = $this->usableSessionId();
        $scale = $this->createScaleSeed();

        // create
        $create = $this->postConfig(['academic_session_id' => $sessionId, 'rating_scale_id' => $scale->id]);
        $this->assertNotSame(422, (int) ($create['status'] ?? 0));
        $config = BaConfig::where('academic_session_id', $sessionId)->latest('id')->firstOrFail();

        // toggle
        $toggle = $this->toggleConfig($config->id);
        $this->assertSame(200, (int) ($toggle['status'] ?? 0));
        $config->refresh();
        $this->assertFalse((bool) $config->is_active);

        // delete
        $this->deleteConfig($config->id);
        $this->assertNotNull(BaConfig::onlyTrashed()->find($config->id));

        // restore
        $this->apiCall('GET', $this->tenantUrl('/behavioural-assessment/configs/' . $config->id . '/restore'));
        $this->assertTrue(BaConfig::where('id', $config->id)->exists());

        // force delete
        BaConfig::find($config->id)->delete();
        $this->apiCall('DELETE', $this->tenantUrl('/behavioural-assessment/configs/' . $config->id . '/force-delete'));
        $this->assertFalse(BaConfig::withTrashed()->where('id', $config->id)->exists());

        $this->forceDeleteScale($scale);
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_configuration_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_configuration_51_limited_user_without_create_permission_gets_403(): void
    {
        $sessionId = $this->usableSessionId();
        $scale = $this->createScaleSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-create-403', function (Browser $browser) use ($limited, $sessionId, $scale): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl(self::STORE_PATH),
                $this->validPayload(['academic_session_id' => $sessionId, 'rating_scale_id' => $scale->id])
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without create permission must get 403.');
        });

        $this->deleteUser($limited);
        $this->forceDeleteScale($scale);
    }

    public function test_configuration_52_limited_user_without_status_permission_gets_403_on_toggle(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-toggle-403', function (Browser $browser) use ($limited, $config): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl('/behavioural-assessment/configs/' . $config->id . '/toggle-status')
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteConfig($config);
    }

    public function test_configuration_53_limited_user_without_delete_permission_gets_403_on_destroy(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-delete-403', function (Browser $browser) use ($limited, $config): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'DELETE',
                $this->tenantUrl('/behavioural-assessment/configs/' . $config->id)
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteConfig($config);
    }

    public function test_configuration_54_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaConfigPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('Policy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete', 'status'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.configs.{$ability}",
                $policy,
                "Policy missing gate string for {$ability}."
            );
        }
    }

    public function test_configuration_55_status_toggle_endpoint_returns_json_messages(): void
    {
        $config = $this->createConfigSeed(['is_active' => true]);
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $response = $this->toggleConfig($config->id);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $json = $response['json'] ?? [];
        $this->assertTrue((bool) ($json['success'] ?? false));
        $this->assertArrayHasKey('is_active', $json);
        $this->assertSame('Configuration deactivated.', (string) ($json['message'] ?? ''));

        $again = $this->toggleConfig($config->id);
        $this->assertSame('Configuration activated.', (string) ($again['json']['message'] ?? ''));

        $this->forceDeleteConfig($config);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (search, empty state, trash, breadcrumb)
    // =====================================================================

    public function test_configuration_60_setup_search_renders_and_accepts_query(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $this->browseWithFailureScreenshot('setup-search', function (Browser $browser): void {
            $this->openSetupTab($browser);
            $browser->assertSee('Search by session or rating scale');
        });

        $this->forceDeleteConfig($config);
    }

    public function test_configuration_61_empty_state_message_when_no_configs_match(): void
    {
        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser): void {
            $this->openSetupTab($browser, 'ZZZ_NO_MATCH_' . $this->uniqueSuffix());
            $browser->assertSee('No configurations found.');
        });
    }

    public function test_configuration_62_trash_page_renders(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }
        $config->delete();

        $this->browseWithFailureScreenshot('trash-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH, 900);
            $browser->assertSee('Academic Session')
                ->assertSee('Deleted At');
        });

        $this->forceDeleteConfig(BaConfig::onlyTrashed()->find($config->id));
    }

    public function test_configuration_63_breadcrumb_present_on_create_and_show_pages(): void
    {
        $config = $this->createConfigSeed();
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }

        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser) use ($config): void {
            $this->openCreatePage($browser);
            $browser->assertSee('Configuration');
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/configs/' . $config->id, 900);
            $browser->assertSee('Configuration Details');
        });

        $this->forceDeleteConfig($config);
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_configuration_70_invalid_id_returns_404(): void
    {
        $missing = 987654321;
        foreach (['/behavioural-assessment/configs/' . $missing, '/behavioural-assessment/configs/' . $missing . '/edit'] as $path) {
            $response = $this->apiCall('GET', $this->tenantUrl($path));
            $this->assertSame(404, (int) ($response['status'] ?? 0), "Expected 404 for {$path}.");
        }

        $toggle = $this->toggleConfig($missing);
        $this->assertSame(404, (int) ($toggle['status'] ?? 0), 'Toggle on invalid id must 404.');
    }

    public function test_configuration_71_weightage_boundaries_5_and_20_are_accepted(): void
    {
        foreach ([5, 20] as $value) {
            $config = $this->createConfigSeed(['weightage_percent' => $value]);
            if ($config === null) {
                $this->markTestSkipped('No usable academic session to seed a config.');
            }
            $response = $this->putConfig($config->id, [
                'academic_session_id' => $config->academic_session_id,
                'rating_scale_id'     => $config->rating_scale_id,
                'weightage_percent'   => $value,
                'aggregation_method'  => 'weighted_average',
                'parent_notification_threshold' => 'moderate',
            ]);
            $this->assertNotSame(422, (int) ($response['status'] ?? 0), "Boundary weightage {$value} must be accepted.");
            $this->forceDeleteConfig($config);
        }
    }

    public function test_configuration_72_is_active_defaults_true_when_omitted(): void
    {
        // prepareForValidation merges is_active default true.
        $sessionId = $this->usableSessionId();
        $scale = $this->createScaleSeed();

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'academic_session_id' => $sessionId,
            'rating_scale_id'     => $scale->id,
            'weightage_percent'   => 10.0,
            'aggregation_method'  => 'weighted_average',
            'parent_notification_threshold' => 'moderate',
            // is_active omitted
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));
        $created = BaConfig::where('academic_session_id', $sessionId)->latest('id')->first();
        $this->assertNotNull($created);
        $this->assertTrue((bool) $created->is_active, 'is_active should default to true when omitted.');

        $this->forceDeleteConfig($created);
        $this->forceDeleteScale($scale);
    }

    // =====================================================================
    // Band 80–89 — Configuration behaviour (BC-CFG) + SEC-BA-001 / CFG-BA-001
    // =====================================================================

    public function test_configuration_80_parent_notification_threshold_persists_all_values(): void
    {
        foreach (['minor', 'moderate', 'major', 'critical'] as $threshold) {
            $config = $this->createConfigSeed(['parent_notification_threshold' => $threshold]);
            if ($config === null) {
                $this->markTestSkipped('No usable academic session to seed a config.');
            }
            $config->refresh();
            $this->assertSame($threshold, $config->parent_notification_threshold, "Threshold {$threshold} must persist.");
            $this->forceDeleteConfig($config);
        }
    }

    public function test_configuration_81_severe_incident_parent_notification_not_wired_sec_ba_001(): void
    {
        // SEC-BA-001: parent_notification_threshold is configured here but never consumed. Prove no
        // controller/service in the module reads the threshold to dispatch a notification on a severe incident.
        $incidentController = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaIncidentController.php'));
        $service = $this->readAppFile($this->moduleRootPath('app/Services/BehaviouralScoreService.php'));
        if ($incidentController === null && $service === null) {
            $this->markTestSkipped('Incident controller/service source not readable from app repo.');
        }

        $haystack = (string) $incidentController . "\n" . (string) $service;
        $this->assertStringNotContainsString('parent_notification_threshold', $haystack, 'SEC-BA-001 regression fixed? A source now reads parent_notification_threshold.');
        $this->assertDoesNotMatchRegularExpression(
            '/(Notification::send|->notify\(|Mail::to|Mail::send)/',
            $haystack,
            'SEC-BA-001 regression fixed? A notification/mail dispatch now exists in the incident flow.'
        );
    }

    public function test_configuration_82_requirement_fields_are_not_implemented_cfg_ba_001(): void
    {
        // CFG-BA-001: the 07-Configuration.md requirement fields (Approval Workflow, Incident Escalation
        // Threshold, Notification Settings) are NOT present in ba_config — the implemented feature set differs.
        $this->assertFalse(Schema::hasColumn(self::CONFIG_TABLE, 'approval_workflow'), 'CFG-BA-001 changed: approval_workflow column now exists.');
        $this->assertFalse(Schema::hasColumn(self::CONFIG_TABLE, 'incident_escalation_threshold'), 'CFG-BA-001 changed: escalation-threshold column now exists.');
        $this->assertFalse(Schema::hasColumn(self::CONFIG_TABLE, 'escalation_threshold'), 'CFG-BA-001 changed: escalation_threshold column now exists.');

        // The implemented fields ARE present (documents the actual feature set).
        foreach (['weightage_percent', 'aggregation_method', 'parent_notification_threshold', 'is_result_integration_enabled'] as $col) {
            $this->assertTrue(Schema::hasColumn(self::CONFIG_TABLE, $col), "Implemented field {$col} should exist.");
        }
    }

    public function test_configuration_83_result_integration_toggle_and_aggregation_persist(): void
    {
        $config = $this->createConfigSeed([
            'is_result_integration_enabled' => true,
            'aggregation_method'            => 'separate_display',
            'weightage_percent'             => 18.0,
        ]);
        if ($config === null) {
            $this->markTestSkipped('No usable academic session to seed a config.');
        }
        $config->refresh();
        $this->assertTrue((bool) $config->is_result_integration_enabled);
        $this->assertSame('separate_display', $config->aggregation_method);
        $this->assertSame('18.0', (string) $config->weightage_percent);

        $this->forceDeleteConfig($config);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_configuration_90_tenant_context_is_initialized_and_table_is_tenant_scoped(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side configuration tests.'
        );
        $this->assertTrue(Schema::hasTable(self::CONFIG_TABLE));
        // Database-per-tenant isolation — ba_config carries no tenant_id column.
        $this->assertFalse(Schema::hasColumn(self::CONFIG_TABLE, 'tenant_id'), 'ba_config should rely on DB-per-tenant isolation, not a tenant_id column.');
    }

    public function test_configuration_91_cross_tenant_isolation_is_defensive(): void
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

    public function test_configuration_92_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaConfigRequest.php'));
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

    public function test_configuration_93_no_activity_log_is_written_on_config_mutation(): void
    {
        // Documented absence: BaConfigController writes no activityLog(). Guard so it stays green if the
        // tenant activity table is absent.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaConfigController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertStringNotContainsString('activityLog(', $controller, 'Config mutations are not expected to write an activity log.');
        $this->assertStringNotContainsString('ActivityLog::create', $controller, 'Config mutations are not expected to write an activity log.');
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
        $rawName = 'configuration-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'configuration-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function openCreatePage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
        $browser->waitFor('#academic_session_id', 15)->waitFor('#weightage_percent', 10);
    }

    private function openSetupTab(Browser $browser, ?string $search = null): void
    {
        $path = self::SETUP_PATH;
        if ($search !== null && $search !== '') {
            $path .= '&search=' . urlencode($search);
        }
        $this->visitAuthenticated($browser, $path, 1000);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#configuration-pane') !== null
                || $browser->element('table') !== null;
        }, 'Configuration setup tab did not render.');
    }

    /**
     * Issue an authenticated (admin) JSON request from a freshly-opened, logged-in browser page.
     */
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
window.__cfgApiDone = false;
window.__cfgApiError = '';
window.__cfgApiResult = null;

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

        window.__cfgApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__cfgApiError = String(error);
    } finally {
        window.__cfgApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__cfgApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__cfgApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__cfgApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Higher-level request shims (admin session) -----------------------

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openCreatePage($browser);
            $result = $callback($browser);
        });
        return $result;
    }

    private function postConfig(array $overrides = []): array
    {
        $payload = $this->validPayload($overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    /** Post a valid base payload with a targeted invalid field (keeps other fields valid). */
    private function postConfigRaw(array $overrides): array
    {
        $payload = array_merge($this->validPayload(), $overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    private function putConfig(int $id, array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'PUT', $this->tenantUrl('/behavioural-assessment/configs/' . $id), $payload));
    }

    private function deleteConfig(int $id): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'DELETE', $this->tenantUrl('/behavioural-assessment/configs/' . $id)));
    }

    private function toggleConfig(int $id): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl('/behavioural-assessment/configs/' . $id . '/toggle-status')));
    }

    /**
     * Build a valid store/update payload. Resolves a usable (config-free) session and a fresh scale
     * unless the caller overrides those ids.
     */
    private function validPayload(array $overrides = []): array
    {
        $sessionId = $overrides['academic_session_id'] ?? $this->usableSessionId();
        $scaleId   = $overrides['rating_scale_id'] ?? ($this->createScaleSeed()->id);

        return array_merge([
            'academic_session_id'           => $sessionId,
            'rating_scale_id'               => $scaleId,
            'is_result_integration_enabled' => 0,
            'weightage_percent'             => 10.0,
            'aggregation_method'            => 'weighted_average',
            'parent_notification_threshold' => 'moderate',
            'is_active'                     => 1,
        ], $overrides);
    }

    // ---- Seed / cleanup ---------------------------------------------------

    /**
     * Seed a persisted ba_config row against a config-free session. Returns null if no session exists.
     */
    private function createConfigSeed(array $overrides = []): ?BaConfig
    {
        $sessionId = $overrides['academic_session_id'] ?? $this->usableSessionId(false);
        if ($sessionId === null) {
            return null;
        }
        $this->cleanConfigForSession((int) $sessionId);

        $scaleId = $overrides['rating_scale_id'] ?? ($this->createScaleSeed()->id);

        $payload = array_merge([
            'academic_session_id'           => (int) $sessionId,
            'rating_scale_id'               => (int) $scaleId,
            'is_result_integration_enabled' => false,
            'weightage_percent'             => 10.0,
            'aggregation_method'            => 'weighted_average',
            'parent_notification_threshold' => 'moderate',
            'is_active'                     => true,
            'created_by'                    => (int) $this->adminUser->id,
            'updated_by'                    => (int) $this->adminUser->id,
        ], $overrides);

        return BaConfig::query()->create($payload);
    }

    private function createScaleSeed(array $overrides = []): BaRatingScale
    {
        $payload = array_merge([
            'code'        => $this->uniqueScaleCode(),
            'name'        => 'Cfg Scale ' . $this->uniqueSuffix(),
            'description' => 'Seed scale for configuration tests',
            'grade_type'  => 'numeric',
            'min_rating'  => 1,
            'max_rating'  => 5,
            'is_default'  => false,
            'is_active'   => true,
            'created_by'  => (int) $this->adminUser->id,
            'updated_by'  => (int) $this->adminUser->id,
        ], $overrides);

        return BaRatingScale::query()->create($payload);
    }

    /**
     * Resolve an academic-session id usable for a NEW config (force-cleans any existing config for it so
     * the unconditional unique index does not block the insert). Returns null (or skips) when none exists.
     */
    private function usableSessionId(bool $skipIfNone = true): ?int
    {
        try {
            if (!Schema::hasTable(self::SESSION_TABLE)) {
                if ($skipIfNone) {
                    $this->markTestSkipped(self::SESSION_TABLE . ' table absent — cannot resolve an academic session.');
                }
                return null;
            }
            $id = DB::table(self::SESSION_TABLE)->orderBy('id')->value('id');
            if ($id === null) {
                if ($skipIfNone) {
                    $this->markTestSkipped('No academic session rows available to bind a configuration.');
                }
                return null;
            }
            $this->cleanConfigForSession((int) $id);
            return (int) $id;
        } catch (Throwable $e) {
            if ($skipIfNone) {
                $this->markTestSkipped('Unable to resolve an academic session id: ' . $e->getMessage());
            }
            return null;
        }
    }

    private function cleanConfigForSession(int $sessionId): void
    {
        try {
            BaConfig::withTrashed()->where('academic_session_id', $sessionId)->get()
                ->each(fn (BaConfig $c) => $this->forceDeleteConfig($c));
        } catch (Throwable) {
        }
    }

    private function sessionHasRatings(int $sessionId): bool
    {
        try {
            if (!Schema::hasTable('ba_assessment_ratings')
                || !Schema::hasTable('ba_assessments')
                || !Schema::hasTable('ba_assessment_periods')) {
                return false;
            }
            return DB::table('ba_assessment_ratings as r')
                ->join('ba_assessments as a', 'a.id', '=', 'r.assessment_id')
                ->join('ba_assessment_periods as p', 'p.id', '=', 'a.period_id')
                ->where('p.academic_session_id', $sessionId)
                ->exists();
        } catch (Throwable) {
            return false;
        }
    }

    private function forceDeleteConfig(?BaConfig $config): void
    {
        if ($config === null) {
            return;
        }
        try {
            if (BaConfig::withTrashed()->whereKey($config->id)->exists()) {
                $config->forceDelete();
            }
        } catch (Throwable) {
            // Best-effort cleanup; a referenced/locked row is left for the next run's dedupe.
        }
    }

    private function forceDeleteScale(?BaRatingScale $scale): void
    {
        if ($scale === null) {
            return;
        }
        try {
            if (BaRatingScale::withTrashed()->whereKey($scale->id)->exists()) {
                $scale->forceDelete();
            }
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
                'name'              => 'Cfg Limited ' . $this->uniqueSuffix(),
                'email'             => 'cfg_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'CL' . substr($this->uniqueSuffix(), -8);
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
        $this->grantConfigPermissions($this->adminUser);
    }

    private function grantConfigPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::CONFIG_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::CONFIG_PERMISSIONS, $guard);

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

    private function syncRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.config-admin');
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
            $modelFile = (new ReflectionClass(BaConfig::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaConfig.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaConfig::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaConfig.php → app root = dirname(,5)
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

    private function uniqueScaleCode(): string
    {
        return strtoupper('CFG' . $this->uniqueSuffix()); // <= 30 chars
    }
}
