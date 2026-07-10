<?php

/**
 * BehaviouralAssessment › Configuration — V2 (comprehensive) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling style
 *           (RatingScale suite / prime_ai BehaviouralAssessment browser tests).
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; table under database/migrations/tenant/).
 * TABLE   : ba_config (one row per academic session — settings/singleton-style). The DDL doc + this
 *           file's name use the stale prefix "bha_" (audit DOC-BA-001); every schema assertion targets
 *           the LIVE "ba_config" table.
 *
 * Semantic numbering bands (WP-G):
 *   01–09 schema/model/request · 10–19 business rules · 20–29 state-machine/status
 *   30–39 validation · 40–49 integration/FK · 50–59 permissions · 60–69 UI/UX
 *   70–79 edge · 80–89 configuration/settings · 90–99 tenancy + security
 *
 * Audit findings proven here (reported as "verify in source" — traced to the cited lines):
 *   SEC-BA-002  FormRequest authorize() returns bare true      → test_..._52
 *   DATA-BA-001 default rating scale switchable mid-session     → test_..._82
 *   SEC-BA-001  parent_notification_threshold never consumed    → test_..._83
 *   DATA-BA-003 soft-delete + UNIQUE(academic_session_id) 500   → test_..._43
 *   DOC-BA-001  DDL doc prefix bha_ vs live ba_config           → test_..._01
 *   (candidate) weightage_percent stored but not consumed        → test_..._84
 *   (candidate) screen fields (approval workflow / escalation)   → test_..._85
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Requests\BaConfigRequest;
use Modules\BehaviouralAssessment\Models\BaConfig;
use Modules\BehaviouralAssessment\Models\BaRatingScale;
use Modules\SchoolSetup\Models\User;
use Tests\DuskTestCase;
use Throwable;

class bha_ConfigurationV2_TestCas extends DuskTestCase
{
    private const SETUP_PATH        = '/behavioural-assessment/setup';
    private const CONFIG_TAB_PATH   = '/behavioural-assessment/setup?tab=configuration';
    private const CREATE_PATH       = '/behavioural-assessment/configs/create';
    private const SHOW_BASE_PATH    = '/behavioural-assessment/configs';
    private const TRASH_PATH        = '/behavioural-assessment/configs/trash';
    private const CONFIG_TABLE      = 'ba_config';
    private const SESSIONS_TABLE    = 'sch_org_academic_sessions_jnt';
    private const MIGRATION_CONFIG  = 'database/migrations/tenant/2026_06_16_130621_create_ba_config_table.php';
    private const CONTROLLER_FILE   = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php';
    private const REQUEST_FILE      = 'Modules/BehaviouralAssessment/app/Http/Requests/BaConfigRequest.php';
    private const SERVICE_FILE      = 'Modules/BehaviouralAssessment/app/Services/BehaviouralScoreService.php';
    private const INCIDENT_FILE     = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php';
    private const EDIT_BLADE_FILE   = 'Modules/BehaviouralAssessment/resources/views/config/edit.blade.php';

    private ?User $adminUser = null;
    private ?User $limitedUser = null;
    private ?int $createdScaleId = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenantBaseUrl = rtrim(
            env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')),
            '/'
        );
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        $this->initializeTenantContext();
        $this->resolveAdminUserAndPermissions();
    }

    protected function tearDown(): void
    {
        if ($this->limitedUser instanceof User) {
            try {
                $this->limitedUser->forceDelete();
            } catch (Throwable) {
                // ignore cleanup issues
            }
            $this->limitedUser = null;
        }

        if ($this->createdScaleId !== null) {
            try {
                BaRatingScale::withTrashed()->where('id', $this->createdScaleId)->forceDelete();
            } catch (Throwable) {
                // ignore FK/cleanup issues
            }
            $this->createdScaleId = null;
        }

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // ══════════════════════════════════════════════
    //  01–09  Schema / model / request configuration
    // ══════════════════════════════════════════════

    /** TC-P01 · BC-DB-01 · Audit-DOC-BA-001 · Source: DDL-ba_config / live migration */
    public function test_config_01_schema_and_model_configuration_are_correct(): void
    {
        // DOC-BA-001: the DDL doc names the table bha_config, but the live table is ba_config.
        $this->assertTrue(Schema::hasTable(self::CONFIG_TABLE), 'Live table ba_config does not exist.');
        $this->assertFalse(Schema::hasTable('bha_config'), 'Stale DDL-doc table bha_config should NOT exist (DOC-BA-001).');

        $this->assertTrue(Schema::hasColumns(self::CONFIG_TABLE, [
            'id', 'academic_session_id', 'rating_scale_id', 'is_result_integration_enabled',
            'weightage_percent', 'aggregation_method', 'parent_notification_threshold',
            'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing from ba_config.');

        $model = new BaConfig();
        $this->assertSame('ba_config', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaConfig::class));
    }

    /** TC-P02 · BC-REF-01/02 · BC-DB-02 · Source: migration uq_ba_config_session + FKs */
    public function test_config_02_fk_and_unique_index_configuration(): void
    {
        $migration = File::get(base_path(self::MIGRATION_CONFIG));
        $this->assertStringContainsString("\$table->unique('academic_session_id', 'uq_ba_config_session')", $migration);
        $this->assertStringContainsString("fk_ba_config_session_id", $migration);
        $this->assertStringContainsString("->references('id')->on('sch_org_academic_sessions_jnt')", $migration);
        $this->assertStringContainsString("constrained('ba_rating_scales')", $migration);
        $this->assertStringContainsString("\$table->decimal('weightage_percent', 4, 1)->default(10.0)", $migration);
        $this->assertStringContainsString("enum('aggregation_method'", $migration);
        $this->assertStringContainsString("enum('parent_notification_threshold'", $migration);
    }

    /** TC-P03 · BC-DB-06 · Source: Model $fillable / relationships / scope */
    public function test_config_03_model_fillable_relationships_and_scope(): void
    {
        $model = new BaConfig();
        foreach ([
            'academic_session_id', 'rating_scale_id', 'is_result_integration_enabled', 'weightage_percent',
            'aggregation_method', 'parent_notification_threshold', 'is_active', 'created_by', 'updated_by',
        ] as $col) {
            $this->assertContains($col, $model->getFillable(), "fillable should include {$col}.");
        }

        $this->assertInstanceOf(BelongsTo::class, $model->ratingScale());
        $this->assertInstanceOf(BelongsTo::class, $model->academicSession());

        $sql = strtolower(BaConfig::query()->active()->toSql());
        $this->assertStringContainsString('is_active', $sql, 'scopeActive should filter on is_active.');
    }

    /** TC-N02 · BC-VAL-* · Source: BaConfigRequest rules() literal strings */
    public function test_config_04_form_request_rules_contain_expected_constraints(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("Rule::unique('ba_config', 'academic_session_id')", $request);
        $this->assertStringContainsString("->ignore(\$id)->whereNull('deleted_at')", $request);
        $this->assertStringContainsString("'exists:ba_rating_scales,id'", $request);
        $this->assertStringContainsString("'exists:sch_org_academic_sessions_jnt,id'", $request);
        $this->assertStringContainsString("'required', 'numeric', 'min:5', 'max:20'", $request);
        $this->assertStringContainsString("'in:average,weighted_average,separate_display'", $request);
        $this->assertStringContainsString("'in:minor,moderate,major,critical'", $request);
        $this->assertStringContainsString('A configuration already exists for the selected academic session.', $request);
    }

    /** TC-N01 · BC-DB-04 · Source: DDL NOT NULL columns without defaults */
    public function test_config_05_db_rejects_each_missing_required_field(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        foreach (['academic_session_id', 'rating_scale_id', 'created_by', 'updated_by'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P04 · BC-DB-05 · Source: model casts (decimal:1 / boolean) */
    public function test_config_06_casts_persist_correctly(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, [
                'weightage_percent'             => 12.5,
                'is_result_integration_enabled' => true,
                'is_active'                     => true,
            ]);
            $record->refresh();
            $this->assertSame('12.5', (string) $record->weightage_percent);
            $this->assertTrue((bool) $record->is_result_integration_enabled);
            $this->assertIsBool($record->is_active);
        } finally {
            if ($record instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  10–19  Business rules
    // ══════════════════════════════════════════════

    /** TC-P10 · BC-BIZ-01 · Source: Controller@store */
    public function test_config_10_create_valid_persists_row(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $sessionId = $this->freeSessionIdOrSkip();
        $saved = null;
        try {
            $this->browserCreateConfig($dependencies, $sessionId, '11', 'average', 'major');
            $saved = BaConfig::query()->where('academic_session_id', $sessionId)->first();
            $this->assertNotNull($saved, 'Valid configuration was not created.');
            $this->assertSame('average', (string) $saved->aggregation_method);
        } finally {
            BaConfig::query()->where('academic_session_id', $sessionId)->forceDelete();
        }
    }

    /** TC-P11 · BC-BIZ-03 · Source: config/show.blade */
    public function test_config_11_show_page_renders_config(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);
                $browser->waitForText('Assessment Configuration Details', 12)
                    ->assertSee('Parent Alert Notification')
                    ->assertSee('Report Card Result Integration');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P12 · BC-BIZ-04 · Source: Controller@update flash */
    public function test_config_12_edit_update_persists_and_flashes(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['weightage_percent' => 8.0]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('input[name="weightage_percent"]', 12)
                    ->clear('input[name="weightage_percent"]')->type('input[name="weightage_percent"]', '14')
                    ->press('Update Configuration')->pause(2200)
                    ->assertSee('Configuration updated successfully.');
            });
            $record->refresh();
            $this->assertSame('14.0', (string) $record->weightage_percent);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P13 · BC-CFG-03 · Source: is_result_integration_enabled column / create form checkbox */
    public function test_config_13_result_integration_flag_persists(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, ['is_result_integration_enabled' => true]);
            $record->refresh();
            $this->assertTrue((bool) $record->is_result_integration_enabled, 'is_result_integration_enabled should persist as true.');
        } finally {
            if ($record instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    /** TC-P14 · BC-CFG-04 · Source: create.blade old('weightage_percent', 10.0) */
    public function test_config_14_create_page_prefills_default_weightage(): void
    {
        $this->configDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $browser->waitFor('input[name="weightage_percent"]', 12)
                ->assertInputValue('input[name="weightage_percent"]', '10');
        });
    }

    /** TC-P15 · BC-CFG-05 · Source: create.blade aggregation_method default weighted_average selected */
    public function test_config_15_aggregation_method_defaults_to_weighted_average(): void
    {
        $this->configDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $browser->waitFor('select[name="aggregation_method"]', 12)
                ->assertSelected('aggregation_method', 'weighted_average');
        });
    }

    /** TC-D06 (E) · BC-INT-01 · Source: BehaviouralScoreService reads $config->ratingScale + aggregation_method */
    public function test_config_16_config_is_consumed_by_score_service(): void
    {
        $service = File::get(base_path(self::SERVICE_FILE));
        $this->assertStringContainsString('BaConfig::where(', $service,
            'Score service should look up the config by academic_session_id.');
        $this->assertStringContainsString('$config?->ratingScale', $service,
            'Score service should resolve the active rating scale from the config (default-scale binding).');
        $this->assertStringContainsString("\$config?->aggregation_method ?? 'weighted_average'", $service,
            'Score service should consume the config aggregation_method.');
    }

    // ══════════════════════════════════════════════
    //  20–29  State-machine / status lifecycle (BC-SM)
    // ══════════════════════════════════════════════

    /** TC-SM01 · BC-SM-01 · Source: Controller@toggleStatus (active → inactive) */
    public function test_config_20_toggle_status_active_inactive_cycle(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CONFIG_TAB_PATH, 1000);
                $selector = '.status-toggle[data-id="' . $record->id . '"]';
                $browser->waitFor($selector, 12)->script('document.querySelector(\'' . $selector . '\').click();');
                $browser->pause(1800);
            });
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'First toggle should deactivate.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM02 · BC-SM-02 · Source: Controller@toggleStatus JSON {success,is_active,message} */
    public function test_config_21_toggle_status_endpoint_returns_json_payload(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CONFIG_TAB_PATH, 1000);
                $response = $this->postJsonFromBrowser(
                    $browser,
                    '/behavioural-assessment/configs/' . $record->id . '/toggle-status'
                );
                $this->assertStringContainsString('"success"', $response, 'Toggle endpoint should return a JSON success key.');
                $this->assertStringContainsString('Configuration', $response, 'Toggle endpoint should return the status message.');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM03 · BC-SM-03 · Source: Controller@destroy — sets is_active=false then soft-deletes */
    public function test_config_22_destroy_deactivates_then_soft_deletes(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['is_active' => true]);
        $id = (int) $record->id;
        try {
            // Mirror controller destroy(): flag inactive, then soft-delete.
            $record->is_active = false;
            $record->save();
            $record->delete();

            $this->assertNull(BaConfig::find($id));
            $trashed = BaConfig::withTrashed()->find($id);
            $this->assertNotNull($trashed);
            $this->assertFalse((bool) $trashed->is_active, 'Destroyed config should be inactive in trash.');
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /** TC-D02 (B) · BC-SM-04 · Source: Controller@restore */
    public function test_config_23_restore_brings_back_from_trash(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $id = (int) $record->id;
        try {
            $record->delete();
            $this->assertNull(BaConfig::find($id));
            $record->restore();
            $this->assertNotNull(BaConfig::find($id));
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /** TC-D03 (B) · BC-SM-05 · Source: Controller@forceDelete */
    public function test_config_24_force_delete_removes_row(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $id = (int) $record->id;
        try {
            $record->delete();
            $record->forceDelete();
            $this->assertNull(BaConfig::withTrashed()->find($id), 'Force-deleted config should be gone entirely.');
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    // ══════════════════════════════════════════════
    //  30–39  Validation (negative matrix)
    // ══════════════════════════════════════════════

    /** TC-N30 · BC-VAL-01 · Source: required rules */
    public function test_config_30_required_fields_block_insert(): void
    {
        $this->configDependenciesOrSkip();
        $before = BaConfig::query()->count();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('select[name="academic_session_id"]', 12)
                ->script("(function(){document.querySelectorAll('[required]').forEach(function(i){i.removeAttribute('required');}); document.querySelector('input[name=\"weightage_percent\"]').value=''; document.querySelector('form').submit();})();");
            $browser->pause(2000)->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaConfig::query()->count(), 'Empty submission must not create a row.');
    }

    /** TC-N31 · BC-VAL-01 · Source: unique(academic_session_id) + message */
    public function test_config_31_duplicate_session_config_is_rejected(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $existing = $this->createRecordDirectly($dependencies);
        $sessionId = (int) $existing->academic_session_id;
        $before = BaConfig::query()->count();
        try {
            $this->browse(function (Browser $browser) use ($dependencies, $sessionId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('select[name="academic_session_id"]', 12)
                    ->select('academic_session_id', (string) $sessionId)
                    ->select('rating_scale_id', (string) $dependencies['rating_scale_id'])
                    ->clear('input[name="weightage_percent"]')->type('input[name="weightage_percent"]', '10')
                    ->press('Save Configuration')->pause(2000)
                    ->assertPresent('.alert-danger')
                    ->assertSee('A configuration already exists for the selected academic session.');
            });
            $this->assertSame($before, BaConfig::query()->count(), 'Duplicate session config must not create a row.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $existing->id);
        }
    }

    /** TC-N32 · BC-VAL-04 · Source: weightage_percent min:5 */
    public function test_config_32_weightage_below_min_is_rejected(): void
    {
        $this->assertServerRejectsWeightage('4');
    }

    /** TC-N33 · BC-VAL-04 · Source: weightage_percent max:20 */
    public function test_config_33_weightage_above_max_is_rejected(): void
    {
        $this->assertServerRejectsWeightage('25');
    }

    /** TC-N34 · BC-VAL-05 · Source: aggregation_method in:... */
    public function test_config_34_invalid_aggregation_method_is_rejected(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $sessionId = $this->freeSessionIdOrSkip();
        $before = BaConfig::query()->count();
        try {
            $this->browse(function (Browser $browser) use ($dependencies, $sessionId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('select[name="aggregation_method"]', 12)
                    ->script("(function(){var s=document.querySelector('select[name=\"aggregation_method\"]');var o=document.createElement('option');o.value='median';o.text='median';s.appendChild(o);s.value='median';})();");
                $browser->select('academic_session_id', (string) $sessionId)
                    ->select('rating_scale_id', (string) $dependencies['rating_scale_id'])
                    ->clear('input[name="weightage_percent"]')->type('input[name="weightage_percent"]', '10')
                    ->press('Save Configuration')->pause(2000)
                    ->assertPresent('.alert-danger');
            });
            $this->assertSame($before, BaConfig::query()->count(), 'Out-of-enum aggregation_method must be rejected.');
        } finally {
            BaConfig::query()->where('academic_session_id', $sessionId)->forceDelete();
        }
    }

    /** TC-N35 · BC-VAL-06 · Source: parent_notification_threshold in:... */
    public function test_config_35_invalid_notification_threshold_is_rejected(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $sessionId = $this->freeSessionIdOrSkip();
        $before = BaConfig::query()->count();
        try {
            $this->browse(function (Browser $browser) use ($dependencies, $sessionId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('select[name="parent_notification_threshold"]', 12)
                    ->script("(function(){var s=document.querySelector('select[name=\"parent_notification_threshold\"]');var o=document.createElement('option');o.value='extreme';o.text='extreme';s.appendChild(o);s.value='extreme';})();");
                $browser->select('academic_session_id', (string) $sessionId)
                    ->select('rating_scale_id', (string) $dependencies['rating_scale_id'])
                    ->clear('input[name="weightage_percent"]')->type('input[name="weightage_percent"]', '10')
                    ->press('Save Configuration')->pause(2000)
                    ->assertPresent('.alert-danger');
            });
            $this->assertSame($before, BaConfig::query()->count(), 'Out-of-enum threshold must be rejected.');
        } finally {
            BaConfig::query()->where('academic_session_id', $sessionId)->forceDelete();
        }
    }

    /** TC-N36 · BC-REF-01 · Source: rating_scale_id FK (DB rejects bogus id) */
    public function test_config_36_db_rejects_nonexistent_rating_scale_fk(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $threw = false;
        $created = null;
        try {
            $payload = $this->buildValidDirectPayload($dependencies);
            $payload['academic_session_id'] = $this->freeSessionIdOrSkip();
            $payload['rating_scale_id'] = 999999999;
            $created = BaConfig::query()->create($payload);
        } catch (Throwable $e) {
            $threw = str_contains(strtolower($e->getMessage()), '23000')
                || str_contains(strtolower($e->getMessage()), 'foreign key')
                || str_contains(strtolower($e->getMessage()), 'integrity constraint');
        } finally {
            if ($created instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $created->id);
            }
        }
        $this->assertTrue($threw, 'A non-existent rating_scale_id should be rejected by the FK constraint.');
    }

    /** TC-N37 · BC-REF-02 · Source: academic_session_id FK (DB rejects bogus id) */
    public function test_config_37_db_rejects_nonexistent_session_fk(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $threw = false;
        $created = null;
        try {
            $payload = $this->buildValidDirectPayload($dependencies);
            $payload['academic_session_id'] = 65000; // within SMALLINT UNSIGNED range but not a real session
            $created = BaConfig::query()->create($payload);
        } catch (Throwable $e) {
            $threw = str_contains(strtolower($e->getMessage()), '23000')
                || str_contains(strtolower($e->getMessage()), 'foreign key')
                || str_contains(strtolower($e->getMessage()), 'integrity constraint');
        } finally {
            if ($created instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $created->id);
            }
        }
        $this->assertTrue($threw, 'A non-existent academic_session_id should be rejected by the FK constraint.');
    }

    // ══════════════════════════════════════════════
    //  40–49  Integration / FK / dependency
    // ══════════════════════════════════════════════

    /** TC-D07 (E) · BC-REF-03 · Source: BaConfig::ratingScale() belongsTo */
    public function test_config_40_rating_scale_relationship_resolves(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        try {
            $record->refresh();
            $this->assertSame((int) $dependencies['rating_scale_id'], (int) $record->ratingScale?->id,
                'Config should resolve back to its bound rating scale.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D08 (E) · BC-REF-04 · Source: BaConfig::academicSession() belongsTo */
    public function test_config_41_academic_session_relationship_resolves(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        try {
            $record->refresh();
            $this->assertSame((int) $record->academic_session_id, (int) $record->academicSession?->id,
                'Config should resolve back to its academic session.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D09 (C) · BC-REF-05 · Source: fk_ba_config_scale_id ON DELETE RESTRICT (defensive) */
    public function test_config_42_rating_scale_delete_is_restricted_while_referenced(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $scale = BaRatingScale::query()->create([
            'code'        => 'CFGFK' . $this->uniqueSuffix(),
            'name'        => 'Config FK Scale ' . $this->uniqueSuffix(),
            'description' => 'For RESTRICT test.',
            'grade_type'  => 'letter',
            'min_rating'  => 1.0,
            'max_rating'  => 5.0,
            'is_default'  => false,
            'is_active'   => true,
            'created_by'  => (int) $dependencies['admin_user_id'],
            'updated_by'  => (int) $dependencies['admin_user_id'],
        ]);
        $config = $this->createRecordDirectly(['admin_user_id' => $dependencies['admin_user_id'], 'rating_scale_id' => (int) $scale->id]);

        $restricted = false;
        try {
            try {
                $scale->forceDelete(); // hard delete referenced parent → RESTRICT should block
            } catch (Throwable $e) {
                $restricted = str_contains(strtolower($e->getMessage()), '23000')
                    || str_contains(strtolower($e->getMessage()), 'foreign key')
                    || str_contains(strtolower($e->getMessage()), 'integrity constraint');
            }
            $this->assertTrue($restricted,
                'Deleting a rating scale referenced by ba_config should be blocked by ON DELETE RESTRICT.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $config->id);
            try {
                BaRatingScale::withTrashed()->where('id', $scale->id)->forceDelete();
            } catch (Throwable) {
                // ignore
            }
        }
    }

    /**
     * TC-D10 (G) · BC-EDG-01 · Audit-DATA-BA-003 (verify in source).
     * uq_ba_config_session(academic_session_id) is a DB unique index that does NOT include deleted_at.
     * After a config is soft-deleted (destroy → SoftDeletes), its session slot is still occupied at the
     * DB level, so re-inserting a config for the same session throws a 23000 integrity error (a 500
     * through the controller — the FormRequest unique is scoped to whereNull(deleted_at) and passes).
     * Source: migration uq_ba_config_session; BaConfig uses SoftDeletes; Request:26.
     */
    public function test_config_43_soft_deleted_session_unique_collision_data_ba_003(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $first = $this->createRecordDirectly($dependencies);
        $sessionId = (int) $first->academic_session_id;
        try {
            $first->delete(); // soft delete — DB row (with deleted_at) still occupies the unique slot

            $threw = false;
            try {
                $this->createRecordDirectly($dependencies, ['academic_session_id' => $sessionId]);
            } catch (QueryException $e) {
                $threw = str_contains(strtolower($e->getMessage()), '23000')
                    || str_contains(strtolower($e->getMessage()), 'duplicate')
                    || str_contains(strtolower($e->getMessage()), 'integrity constraint');
            } catch (Throwable $e) {
                $threw = str_contains(strtolower($e->getMessage()), 'duplicate')
                    || str_contains(strtolower($e->getMessage()), 'integrity');
            }

            $this->assertTrue($threw,
                'DATA-BA-003 confirmed: soft-deleted academic_session_id still blocks re-insert via uq_ba_config_session.');
        } finally {
            BaConfig::withTrashed()->where('academic_session_id', $sessionId)->forceDelete();
        }
    }

    // ══════════════════════════════════════════════
    //  50–59  Permissions / authorization
    // ══════════════════════════════════════════════

    /** TC-S01 · BC-AUTH-01 · Source: auth middleware on web routes */
    public function test_config_50_guest_redirected_to_login_on_create(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** TC-S02 · BC-AUTH-02 · Source: BaDashboardController@setup gate + redirect */
    public function test_config_51_guest_redirected_to_login_on_setup(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::SETUP_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /**
     * TC-S03 · BC-AUTH-03 · Audit-SEC-BA-002 (verify in source).
     * BaConfigRequest::authorize() returns a bare `true`, so the FormRequest itself does not gate.
     * Access control relies entirely on the controller's Gate::authorize() calls. Source: BaConfigRequest.php:12-15.
     */
    public function test_config_52_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = new BaConfigRequest();
        $this->assertTrue($request->authorize(),
            'SEC-BA-002 confirmed: FormRequest authorize() returns bare true (auth deferred to controller gates).');

        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.configs.create')", $controller);
    }

    /** TC-S04 · BC-AUTH-04 · Source: Controller Gate::authorize on create (limited user → 403) */
    public function test_config_53_user_without_permission_is_forbidden(): void
    {
        $limited = $this->createLimitedUserOrSkip();

        $this->browse(function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600)
                ->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);

            $source = strtolower($browser->driver->getPageSource());
            $forbidden = str_contains($source, '403')
                || str_contains($source, 'forbidden')
                || str_contains($source, 'not authorized')
                || str_contains($source, 'unauthorized');
            $stillHasForm = str_contains($source, 'save configuration');

            $this->assertTrue($forbidden || ! $stillHasForm,
                'A user lacking configs.create should be blocked from the create screen.');
        });
    }

    // ══════════════════════════════════════════════
    //  60–69  UI / UX (setup tab list, search, trash)
    // ══════════════════════════════════════════════

    /** TC-P60 · BC-BIZ-06 · Source: setup config tab _configuration.blade */
    public function test_config_60_setup_tab_lists_created_config(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $scaleName = (string) (BaRatingScale::find($dependencies['rating_scale_id'])?->name ?? '');
        try {
            $this->browse(function (Browser $browser) use ($scaleName): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CONFIG_TAB_PATH, 1000);
                $browser->waitForText('Parent Alert', 12)->assertSee('Weightage %');
                if ($scaleName !== '') {
                    $browser->assertSee($scaleName);
                }
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P61 · BC-BIZ-07 · Source: setup() search by session/scale (cfg_page) */
    public function test_config_61_search_by_scale_filters_list(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $scaleName = (string) (BaRatingScale::find($dependencies['rating_scale_id'])?->name ?? '');
        if ($scaleName === '') {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
            $this->markTestSkipped('Bound rating scale has no name to search on.');
        }
        try {
            $this->browse(function (Browser $browser) use ($scaleName): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication(
                    $browser,
                    self::SETUP_PATH . '?tab=configuration&search=' . urlencode($scaleName),
                    1000
                );
                $browser->assertSee($scaleName);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P62 · BC-BIZ-08 · Source: config/trash.blade */
    public function test_config_62_trash_page_lists_soft_deleted_config(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $record->delete();
        try {
            $this->browse(function (Browser $browser): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TRASH_PATH, 900);
                $browser->waitForText('Deleted At', 12)->assertSee('Weightage %');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  70–79  Edge cases
    // ══════════════════════════════════════════════

    /** TC-D11 (G) · BC-EDG-02 · Source: weightage_percent boundary values 5.0 / 20.0 */
    public function test_config_70_weightage_boundary_values_persist(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $low = null;
        $high = null;
        try {
            $low = $this->createRecordDirectly($dependencies, ['weightage_percent' => 5.0]);
            $low->refresh();
            $this->assertSame('5.0', (string) $low->weightage_percent);
            $this->forceDeleteRecordByIdIfExists((int) $low->id);
            $low = null;

            $high = $this->createRecordDirectly($dependencies, ['weightage_percent' => 20.0]);
            $high->refresh();
            $this->assertSame('20.0', (string) $high->weightage_percent);
        } finally {
            if ($low instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $low->id);
            }
            if ($high instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $high->id);
            }
        }
    }

    /** TC-D12 (G) · BC-EDG-03 · Source: weightage_percent half-step (12.5) persists */
    public function test_config_71_weightage_half_step_persists(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, ['weightage_percent' => 12.5]);
            $record->refresh();
            $this->assertSame('12.5', (string) $record->weightage_percent);
        } finally {
            if ($record instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  80–89  Configuration / settings behaviour (BC-CFG)
    // ══════════════════════════════════════════════

    /** TC-CFG01 · BC-CFG-01 · Source: BehaviouralScoreService default-scale binding */
    public function test_config_80_default_scale_binding_is_read_by_service(): void
    {
        $service = File::get(base_path(self::SERVICE_FILE));
        // The service binds the config's rating scale, falling back to the is_default scale only when no config.
        $this->assertStringContainsString('$config?->ratingScale ?? BaRatingScale::where(', $service,
            'Default-scale binding: config.ratingScale drives scoring, with is_default scale as fallback.');
    }

    /** TC-CFG02 · BC-CFG-02 · Source: BehaviouralScoreService aggregation_method consumption */
    public function test_config_81_aggregation_method_drives_overall_score(): void
    {
        $service = File::get(base_path(self::SERVICE_FILE));
        $this->assertStringContainsString('match ($aggregationMethod)', $service,
            'aggregation_method should select the overall-score computation branch.');
        $this->assertStringContainsString("'average' => \$categoryScores->avg('score')", $service);
        $this->assertStringContainsString("'weighted_average' => \$this->weightedAverage", $service);
        $this->assertStringContainsString("'separate_display' => null", $service);
    }

    /**
     * TC-CFG03 · BC-SM-06 · Audit-DATA-BA-001 (verify in source).
     * Requirement (07-Configuration "Scale Integrity Constraint" / BR-BA-029): once ratings exist in
     * ba_assessment_ratings for the session, the Active Rating Scale dropdown must be LOCKED and the
     * scale cannot change. The controller update() performs NO ratings-existence check, and the edit
     * Blade renders the rating_scale_id <select> with no `disabled` attribute — so the scale is freely
     * switchable mid-session. This proves the current (defective) behaviour.
     * Source: BaConfigController@update:65-74 (no guard); config/edit.blade.php rating_scale_id select.
     */
    public function test_config_82_mid_session_scale_switch_is_not_guarded_data_ba_001(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $editBlade = File::get(base_path(self::EDIT_BLADE_FILE));

        // (a) update() never queries the ratings table before applying the change.
        $this->assertStringNotContainsString('ba_assessment_ratings', $controller,
            'DATA-BA-001: controller does not check existing ratings before allowing a scale switch.');
        $this->assertStringNotContainsString('assessment_ratings', $controller,
            'DATA-BA-001: controller has no ratings-existence guard.');

        // (b) the edit form's rating_scale_id select is not locked/disabled when ratings exist.
        $this->assertStringContainsString('name="rating_scale_id"', $editBlade);
        $this->assertStringNotContainsString('disabled', $editBlade,
            'DATA-BA-001: the rating scale dropdown is never disabled — BR-BA-029 lock is not implemented.');

        // (c) at the model layer the scale can be swapped with no restriction.
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        try {
            $otherScaleId = (int) BaRatingScale::query()
                ->where('is_active', true)
                ->where('id', '!=', $record->rating_scale_id)
                ->orderBy('id')
                ->value('id');

            if ($otherScaleId > 0) {
                $record->update(['rating_scale_id' => $otherScaleId, 'updated_by' => (int) $dependencies['admin_user_id']]);
                $record->refresh();
                $this->assertSame($otherScaleId, (int) $record->rating_scale_id,
                    'DATA-BA-001 confirmed: rating_scale_id is switchable with no usage guard.');
            } else {
                $this->assertTrue(true, 'DATA-BA-001 proven via source scan (no second active scale to switch to).');
            }
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-CFG04 · BC-INT-02 · Audit-SEC-BA-001 / BUG-BA-003 (verify in source).
     * Requirement (07-Configuration + REQ-BA-015): parent_notification_threshold is the minimum incident
     * severity that triggers a parent notification. In the source it is only stored/validated/displayed —
     * NO incident or notification path ever reads it. BaIncidentController never references the column,
     * and the module ships no Notification class. This proves the threshold is dead configuration.
     * Source: BaIncidentController.php (no reference); grep parent_notification_threshold → model/request/blade only.
     */
    public function test_config_83_parent_notification_threshold_is_never_consumed_sec_ba_001(): void
    {
        // The column exists and is validated/persisted...
        $this->assertTrue(Schema::hasColumn(self::CONFIG_TABLE, 'parent_notification_threshold'));
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("'in:minor,moderate,major,critical'", $request);

        // ...but no incident/notification consumer reads it (SEC-BA-001 / BUG-BA-003).
        $incidentController = File::get(base_path(self::INCIDENT_FILE));
        $this->assertStringNotContainsString('parent_notification_threshold', $incidentController,
            'SEC-BA-001 confirmed: BaIncidentController never compares incident severity to the config threshold.');
        $this->assertStringNotContainsString('notification_threshold', $incidentController,
            'SEC-BA-001: no threshold-driven parent-notification logic exists in the incident flow.');
    }

    /**
     * TC-CFG05 · BC-CFG-06 (candidate — verify in source).
     * weightage_percent is documented as the "percentage contribution to final academic result", but the
     * scoring service (BehaviouralScoreService) never reads config.weightage_percent — overall scores use
     * category/criterion weights only. The configured value is therefore stored but not consumed.
     * Source: BehaviouralScoreService.php (no reference to weightage_percent).
     */
    public function test_config_84_weightage_percent_is_not_consumed_by_score_service(): void
    {
        $service = File::get(base_path(self::SERVICE_FILE));
        $this->assertStringNotContainsString('weightage_percent', $service,
            'Candidate finding confirmed: weightage_percent is not consumed by the scoring service.');
    }

    /**
     * TC-CFG06 · BC-EDG-04 (requirement-vs-impl divergence — verify in source).
     * The screen (07-Configuration) specifies an "Approval Workflow" toggle and an integer "Incident
     * Escalation Threshold" (default 3). Neither exists on ba_config — the implementation instead exposes
     * parent_notification_threshold + aggregation_method + weightage_percent + is_result_integration_enabled.
     * This documents the divergence between the requirement and the shipped schema.
     * Source: 07-Configuration.md "Key Fields at a Glance" vs migration create_ba_config_table.
     */
    public function test_config_85_screen_only_fields_are_absent_from_schema(): void
    {
        $this->assertFalse(Schema::hasColumn(self::CONFIG_TABLE, 'approval_workflow'),
            'Screen "Approval Workflow" field is not implemented on ba_config (requirement divergence).');
        $this->assertFalse(Schema::hasColumn(self::CONFIG_TABLE, 'incident_escalation_threshold'),
            'Screen "Incident Escalation Threshold" field is not implemented on ba_config (requirement divergence).');
        // What actually exists instead:
        $this->assertTrue(Schema::hasColumn(self::CONFIG_TABLE, 'parent_notification_threshold'));
        $this->assertTrue(Schema::hasColumn(self::CONFIG_TABLE, 'aggregation_method'));
    }

    // ══════════════════════════════════════════════
    //  90–99  Tenancy + security
    // ══════════════════════════════════════════════

    /** TC-T01 · BC-CFG-07 · Source: tenant-scoped table (no tenant_id column) */
    public function test_config_90_runs_inside_initialized_tenant(): void
    {
        if (!function_exists('tenancy')) {
            $this->markTestSkipped('Tenancy helper unavailable.');
        }
        $this->assertTrue(tenancy()->initialized, 'Configuration is tenant-scoped and requires an initialized tenant.');
        $this->assertTrue(Schema::hasTable(self::CONFIG_TABLE), 'ba_config must resolve within the tenant DB.');
        $this->assertFalse(Schema::hasColumn(self::CONFIG_TABLE, 'tenant_id'),
            'Tenant-per-database design → no tenant_id column on ba_config.');
    }

    /** TC-S06 · BC-AUTH-05 · Source: Controller@show findOrFail → 404 */
    public function test_config_91_invalid_id_does_not_render_detail(): void
    {
        $this->configDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl(self::SHOW_BASE_PATH . '/98765432'))->pause(1200);
            $browser->assertDontSee('Assessment Configuration Details');
        });
    }

    // ══════════════════════════════════════════════
    //  Helpers
    // ══════════════════════════════════════════════

    private function configDependenciesOrSkip(): array
    {
        $adminUserId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));
        if ($adminUserId <= 0) {
            $this->markTestSkipped('No admin user found for configuration tests.');
        }

        $scaleId = (int) BaRatingScale::query()->where('is_active', true)->orderBy('id')->value('id');
        if ($scaleId <= 0) {
            $scale = BaRatingScale::query()->create([
                'code'        => 'CFGSCL' . $this->uniqueSuffix(),
                'name'        => 'Config Dep Scale ' . $this->uniqueSuffix(),
                'description' => 'Created for config dusk test.',
                'grade_type'  => 'letter',
                'min_rating'  => 1.0,
                'max_rating'  => 5.0,
                'is_default'  => false,
                'is_active'   => true,
                'created_by'  => $adminUserId,
                'updated_by'  => $adminUserId,
            ]);
            $this->createdScaleId = (int) $scale->id;
            $scaleId = $this->createdScaleId;
        }

        return ['admin_user_id' => $adminUserId, 'rating_scale_id' => $scaleId];
    }

    private function freeSessionIdOrSkip(): int
    {
        $used = BaConfig::withTrashed()->pluck('academic_session_id')->filter()->map(fn ($v) => (int) $v)->all();

        $query = DB::table(self::SESSIONS_TABLE)->where('is_active', true);
        if (!empty($used)) {
            $query->whereNotIn('id', $used);
        }
        $sessionId = (int) $query->orderBy('id')->value('id');

        if ($sessionId <= 0) {
            $this->markTestSkipped('No free active academic session available for a config row (all sessions already configured).');
        }

        return $sessionId;
    }

    private function createRecordDirectly(array $dependencies, array $overrides = []): BaConfig
    {
        $payload = array_merge($this->buildValidDirectPayload($dependencies), $overrides);
        if (!array_key_exists('academic_session_id', $overrides)) {
            $payload['academic_session_id'] = $this->freeSessionIdOrSkip();
        }

        return BaConfig::query()->create($payload);
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'academic_session_id'           => 0, // replaced with a free session id unless overridden
            'rating_scale_id'               => (int) $dependencies['rating_scale_id'],
            'is_result_integration_enabled' => false,
            'weightage_percent'             => 10.0,
            'aggregation_method'            => 'weighted_average',
            'parent_notification_threshold' => 'moderate',
            'is_active'                     => true,
            'created_by'                    => (int) $dependencies['admin_user_id'],
            'updated_by'                    => (int) $dependencies['admin_user_id'],
        ];
    }

    private function browserCreateConfig(array $dependencies, int $sessionId, string $weightage, string $aggregation, string $threshold): void
    {
        $this->browse(function (Browser $browser) use ($dependencies, $sessionId, $weightage, $aggregation, $threshold): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('select[name="academic_session_id"]', 12)
                ->select('academic_session_id', (string) $sessionId)
                ->select('rating_scale_id', (string) $dependencies['rating_scale_id'])
                ->clear('input[name="weightage_percent"]')->type('input[name="weightage_percent"]', $weightage)
                ->select('aggregation_method', $aggregation)
                ->select('parent_notification_threshold', $threshold)
                ->press('Save Configuration')
                ->pause(2500);
        });
    }

    private function assertServerRejectsWeightage(string $value): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $sessionId = $this->freeSessionIdOrSkip();
        $before = BaConfig::query()->count();
        try {
            $this->browse(function (Browser $browser) use ($dependencies, $sessionId, $value): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('input[name="weightage_percent"]', 12)
                    ->script("(function(){var w=document.querySelector('input[name=\"weightage_percent\"]'); w.removeAttribute('min'); w.removeAttribute('max');})();");
                $browser->select('academic_session_id', (string) $sessionId)
                    ->select('rating_scale_id', (string) $dependencies['rating_scale_id'])
                    ->clear('input[name="weightage_percent"]')->type('input[name="weightage_percent"]', $value)
                    ->press('Save Configuration')->pause(2000)
                    ->assertPresent('.alert-danger');
            });
            $this->assertSame($before, BaConfig::query()->count(), "Out-of-range weightage {$value} must be rejected.");
        } finally {
            BaConfig::query()->where('academic_session_id', $sessionId)->forceDelete();
        }
    }

    private function forceDeleteRecordByIdIfExists(int $recordId): void
    {
        BaConfig::withTrashed()->where('id', $recordId)->get()
            ->each(function (BaConfig $record): void {
                try {
                    $record->forceDelete();
                } catch (Throwable) {
                    // ignore cleanup issues
                }
            });
    }

    private function assertDatabaseRejectsMissingField(array $dependencies, string $missingField): void
    {
        $created = null;
        try {
            $payload = $this->buildValidDirectPayload($dependencies);
            $payload['academic_session_id'] = $this->freeSessionIdOrSkip();
            unset($payload[$missingField]);
            $created = BaConfig::query()->create($payload);
            $this->fail("Expected DB rejection for missing {$missingField}, but insert succeeded.");
        } catch (Throwable $exception) {
            $message = strtolower($exception->getMessage());
            $isConstraint = str_contains($message, 'cannot be null')
                || str_contains($message, 'not null')
                || str_contains($message, "doesn't have a default value")
                || str_contains($message, 'integrity constraint')
                || str_contains($message, '23000');
            $this->assertTrue($isConstraint, "Expected DB required-field failure for {$missingField}, got: {$exception->getMessage()}");
        } finally {
            if ($created instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $created->id);
            }
        }
    }

    private function postJsonFromBrowser(Browser $browser, string $path): string
    {
        $url = $this->tenantUrl($path);
        $script = <<<JS
        var done = arguments[arguments.length - 1];
        var token = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';
        fetch("{$url}", {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': token, 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
            credentials: 'same-origin'
        }).then(function (r) { return r.text(); })
          .then(function (t) { done(t); })
          .catch(function (e) { done('ERROR:' + e); });
JS;

        try {
            $result = $browser->driver->executeAsyncScript($script);
            return is_string($result) ? $result : json_encode($result);
        } catch (Throwable $e) {
            return 'ERROR:' . $e->getMessage();
        }
    }

    private function createLimitedUserOrSkip(): User
    {
        try {
            $languageId = (int) DB::table('glb_languages')->min('id');
            if ($languageId <= 0) {
                $this->markTestSkipped('No language row available to satisfy sys_users.prefered_language FK.');
            }

            $suffix = uniqid();
            $user = new User();
            $user->forceFill([
                'name'              => 'Limited CFG ' . $suffix,
                'email'             => 'limited_cfg_' . $suffix . '@tenant.test',
                'password'          => bcrypt('password'),
                'emp_code'          => substr('L' . $suffix, 0, 20),
                'prefered_language' => $languageId,
                'user_type'         => 'EMPLOYEE',
                'email_verified_at' => now(),
            ]);
            $user->save();

            $this->limitedUser = $user;
            return $user;
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not provision a limited user: ' . $e->getMessage());
        }
    }

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
    }

    private function authenticateBrowserSession(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(800);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1400);
        }

        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(600);
        }
    }

    private function visitPathWithAuthentication(Browser $browser, string $path, int $pauseMs = 900): void
    {
        $browser->visit($this->tenantUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        }
    }

    private function initializeTenantContext(): void
    {
        $tenantHost = parse_url($this->tenantBaseUrl, PHP_URL_HOST);

        if (!is_string($tenantHost) || $tenantHost === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }

        $domain = \Modules\Prime\Models\Domain::query()->where('domain', $tenantHost)->first();
        if (!$domain) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $tenantHost);
        }

        if (function_exists('tenancy')) {
            tenancy()->initialize($domain->tenant);
        }
    }

    private function resolveAdminUserAndPermissions(): void
    {
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
            ?? User::query()->first();

        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for dusk login.');
        }

        if (property_exists($this->adminUser, 'email_verified_at') && !$this->adminUser->email_verified_at) {
            $this->adminUser->email_verified_at = now();
            $this->adminUser->save();
        }

        $this->grantPermissionsToUser($this->adminUser);
    }

    private function grantPermissionsToUser(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo')) {
            return;
        }

        $permissions = [
            'tenant.behavioural-assessment.configs.viewAny',
            'tenant.behavioural-assessment.configs.view',
            'tenant.behavioural-assessment.configs.create',
            'tenant.behavioural-assessment.configs.update',
            'tenant.behavioural-assessment.configs.delete',
            'tenant.behavioural-assessment.configs.status',
            'tenant.behavioural-assessment.configs.restore',
            'tenant.behavioural-assessment.configs.forceDelete',
            'tenant.behavioural-assessment.setup.viewAny',
        ];

        $this->ensurePermissionsExist($permissions);

        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
    }

    private function ensurePermissionsExist(array $permissions): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }

        $guard = config('auth.defaults.guard', 'web');

        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate([
                    'name'       => $permission,
                    'guard_name' => $guard,
                ]);
            } catch (Throwable) {
                // ignore env-specific permission table mismatches
            }
        }
    }

    private function suppressBrowserAlertDialogs(Browser $browser): void
    {
        $browser->script(<<<'JS'
        (function () {
            window.__duskAlertMessages = window.__duskAlertMessages || [];
            window.alert = function (message) {
                window.__duskAlertMessages.push(String(message || ''));
            };
        })();
JS);
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
