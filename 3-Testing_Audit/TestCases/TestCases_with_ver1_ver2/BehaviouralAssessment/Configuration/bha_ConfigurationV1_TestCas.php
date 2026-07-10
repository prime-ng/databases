<?php

/**
 * BehaviouralAssessment › Configuration — V1 (foundation) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling style
 *           (RatingScale suite / prime_ai BehaviouralAssessment browser tests).
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; table lives in database/migrations/tenant/).
 * TABLE   : ba_config  (singleton-style, one row per academic session). NOTE the DDL doc uses the
 *           stale prefix "bha_config"; the LIVE migration/model/table is "ba_config" (audit
 *           DOC-BA-001). Artifact FILE names follow the DDL/inventory prefix "bha_"; every schema
 *           assertion targets the real "ba_" table. Do not "fix" this to bha_ in code.
 *
 * All routes/selectors/permissions/flash strings verified against:
 *   Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php
 *   Modules/BehaviouralAssessment/app/Http/Requests/BaConfigRequest.php
 *   Modules/BehaviouralAssessment/app/Models/BaConfig.php
 *   Modules/BehaviouralAssessment/routes/web.php
 *   Modules/BehaviouralAssessment/resources/views/config/{create,edit,show,trash}.blade.php
 *   Modules/BehaviouralAssessment/resources/views/pages/partials/setup/_configuration.blade.php
 *   database/migrations/tenant/2026_06_16_130621_create_ba_config_table.php
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
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

class bha_ConfigurationV1_TestCas extends DuskTestCase
{
    private const SETUP_PATH       = '/behavioural-assessment/setup';
    private const CONFIG_TAB_PATH  = '/behavioural-assessment/setup?tab=configuration';
    private const CREATE_PATH      = '/behavioural-assessment/configs/create';
    private const SHOW_BASE_PATH   = '/behavioural-assessment/configs';
    private const TRASH_PATH       = '/behavioural-assessment/configs/trash';
    private const CONFIG_TABLE     = 'ba_config';
    private const SESSIONS_TABLE   = 'sch_org_academic_sessions_jnt';
    private const MIGRATION_CONFIG = 'database/migrations/tenant/2026_06_16_130621_create_ba_config_table.php';
    private const CONTROLLER_FILE  = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php';
    private const REQUEST_FILE     = 'Modules/BehaviouralAssessment/app/Http/Requests/BaConfigRequest.php';

    private ?User $adminUser = null;
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

    // ──────────────────────────────────────────────
    //  01–09  Schema / model / request configuration
    // ──────────────────────────────────────────────

    /** TC-P01 · BC-DB-01/06 · Audit-DOC-BA-001 · Source: DDL-ba_config / live migration */
    public function test_config_01_schema_model_and_softdelete_are_correct(): void
    {
        // DOC-BA-001: the DDL doc names the table bha_config; the live table is ba_config.
        $this->assertTrue(Schema::hasTable(self::CONFIG_TABLE), 'Live table ba_config does not exist.');
        $this->assertFalse(Schema::hasTable('bha_config'), 'Stale DDL-doc table bha_config should NOT exist (DOC-BA-001).');

        $this->assertTrue(
            Schema::hasColumns(self::CONFIG_TABLE, [
                'id', 'academic_session_id', 'rating_scale_id', 'is_result_integration_enabled',
                'weightage_percent', 'aggregation_method', 'parent_notification_threshold',
                'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing from ba_config.'
        );

        $migrationPath = base_path(self::MIGRATION_CONFIG);
        $this->assertTrue(File::exists($migrationPath), 'Migration not found: ' . self::MIGRATION_CONFIG);
        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('ba_config'", $migration);
        $this->assertStringContainsString("\$table->decimal('weightage_percent', 4, 1)", $migration);
        $this->assertStringContainsString("\$table->unique('academic_session_id', 'uq_ba_config_session')", $migration);
        $this->assertStringContainsString("\$table->softDeletes()", $migration);

        $this->assertTrue(File::exists(base_path(self::CONTROLLER_FILE)), 'Controller file missing.');

        $model = new BaConfig();
        $this->assertSame('ba_config', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaConfig::class));

        $fillable = $model->getFillable();
        foreach ([
            'academic_session_id', 'rating_scale_id', 'is_result_integration_enabled',
            'weightage_percent', 'aggregation_method', 'parent_notification_threshold', 'is_active',
        ] as $col) {
            $this->assertContains($col, $fillable, "ba_config fillable should include {$col}.");
        }

        $casts = $model->getCasts();
        $this->assertSame('decimal:1', $casts['weightage_percent'] ?? null);
        $this->assertSame('boolean', $casts['is_result_integration_enabled'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);

        $this->assertInstanceOf(BelongsTo::class, $model->ratingScale());
        $this->assertInstanceOf(BelongsTo::class, $model->academicSession());
    }

    /** TC-N02 · BC-VAL-* · Source: BaConfigRequest rules() literal strings */
    public function test_config_02_form_request_rules_contain_expected_constraints(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("Rule::unique('ba_config', 'academic_session_id')", $request);
        $this->assertStringContainsString("->whereNull('deleted_at')", $request);
        $this->assertStringContainsString("'exists:ba_rating_scales,id'", $request);
        $this->assertStringContainsString("'exists:sch_org_academic_sessions_jnt,id'", $request);
        $this->assertStringContainsString("'min:5', 'max:20'", $request);
        $this->assertStringContainsString("'in:average,weighted_average,separate_display'", $request);
        $this->assertStringContainsString("'in:minor,moderate,major,critical'", $request);
        $this->assertStringContainsString('A configuration already exists for the selected academic session.', $request);
    }

    /** TC-N01 · BC-DB-04 · Source: DDL NOT NULL columns without defaults */
    public function test_config_03_db_rejects_missing_required_fields(): void
    {
        $dependencies = $this->configDependenciesOrSkip();

        foreach (['academic_session_id', 'rating_scale_id', 'created_by', 'updated_by'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    // ──────────────────────────────────────────────
    //  10–19  Core CRUD / business behaviour
    // ──────────────────────────────────────────────

    /** TC-P10 · BC-BIZ-01 · Source: config/create.blade sections + Save Configuration */
    public function test_config_04_create_page_loads_and_shows_sections(): void
    {
        $this->configDependenciesOrSkip();

        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);

            $browser->waitFor('select[name="academic_session_id"]', 12)
                ->assertSee('Academic Context')
                ->assertSee('Rules')
                ->assertPresent('select[name="rating_scale_id"]')
                ->assertPresent('input[name="weightage_percent"]')
                ->assertSee('Save Configuration');
        });
    }

    /** TC-P11 · BC-BIZ-02 · Source: Controller@store flash "Configuration created successfully." */
    public function test_config_05_create_submission_persists(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $sessionId = $this->freeSessionIdOrSkip();
        $saved = null;

        try {
            $this->browse(function (Browser $browser) use ($dependencies, $sessionId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('select[name="academic_session_id"]', 12)
                    ->select('academic_session_id', (string) $sessionId)
                    ->select('rating_scale_id', (string) $dependencies['rating_scale_id'])
                    ->clear('input[name="weightage_percent"]')->type('input[name="weightage_percent"]', '12')
                    ->select('aggregation_method', 'average')
                    ->select('parent_notification_threshold', 'major')
                    ->press('Save Configuration')
                    ->pause(2500);
            });

            $saved = BaConfig::query()->where('academic_session_id', $sessionId)->latest('id')->first();
            $this->assertNotNull($saved, 'Configuration was not persisted.');
            $this->assertSame((int) $dependencies['rating_scale_id'], (int) $saved->rating_scale_id);
        } finally {
            if ($saved instanceof BaConfig) {
                $this->forceDeleteRecordByIdIfExists((int) $saved->id);
            }
        }
    }

    /** TC-P12 · BC-BIZ-03 · Source: config/show.blade "Assessment Configuration Details" */
    public function test_config_06_show_page_displays_data(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $scaleName = (string) (BaRatingScale::find($dependencies['rating_scale_id'])?->name ?? '');

        try {
            $this->browse(function (Browser $browser) use ($record, $scaleName): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);

                $browser->waitForText('Assessment Configuration Details', 12)
                    ->assertSee('Weightage %')
                    ->assertSee('Aggregation Method');
                if ($scaleName !== '') {
                    $browser->assertSee($scaleName);
                }
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P13 · BC-BIZ-04 · Source: Controller@update flash "Configuration updated successfully." */
    public function test_config_07_edit_update_persists_and_flashes(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['weightage_percent' => 10.0]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);

                $browser->waitFor('input[name="weightage_percent"]', 12)
                    ->clear('input[name="weightage_percent"]')
                    ->type('input[name="weightage_percent"]', '15')
                    ->press('Update Configuration')
                    ->pause(2200)
                    ->assertSee('Configuration updated successfully.');
            });

            $record->refresh();
            $this->assertSame('15.0', (string) $record->weightage_percent);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM01 · BC-SM-01 · Source: Controller@toggleStatus + status-switch component (.status-toggle) */
    public function test_config_08_toggle_status_flips_is_active(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['is_active' => true]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CONFIG_TAB_PATH, 1000);

                $selector = '.status-toggle[data-id="' . $record->id . '"]';
                $browser->waitFor($selector, 12)
                    ->script('document.querySelector(\'' . $selector . '\').click();');
                $browser->pause(1800);
            });

            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'is_active should have toggled to false.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D01 (F) · BC-BIZ-05 · Source: Controller destroy/restore/forceDelete */
    public function test_config_09_soft_delete_restore_force_delete_lifecycle(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $recordId = (int) $record->id;

        try {
            $record->delete();
            $this->assertNotNull(BaConfig::withTrashed()->find($recordId));
            $this->assertNull(BaConfig::find($recordId));

            $record->restore();
            $this->assertNotNull(BaConfig::find($recordId));

            $record->forceDelete();
            $this->assertNull(BaConfig::withTrashed()->find($recordId));
        } finally {
            $this->forceDeleteRecordByIdIfExists($recordId);
        }
    }

    // ──────────────────────────────────────────────
    //  30–39  Validation (negative)
    // ──────────────────────────────────────────────

    /** TC-N10 · BC-VAL-01 · Source: BaConfigRequest unique(academic_session_id) + message */
    public function test_config_10_duplicate_session_config_is_rejected(): void
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
                    ->press('Save Configuration')
                    ->pause(2000)
                    ->assertPresent('.alert-danger')
                    ->assertSee('A configuration already exists for the selected academic session.');
            });

            $this->assertSame($before, BaConfig::query()->count(), 'Duplicate session config should not create a row.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $existing->id);
        }
    }

    /** TC-N11 · BC-VAL-04 · Source: BaConfigRequest weightage_percent min:5 max:20 */
    public function test_config_11_weightage_out_of_range_is_rejected(): void
    {
        $dependencies = $this->configDependenciesOrSkip();
        $sessionId = $this->freeSessionIdOrSkip();
        $before = BaConfig::query()->count();

        try {
            $this->browse(function (Browser $browser) use ($dependencies, $sessionId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="weightage_percent"]', 12)
                    ->script("(function(){var w=document.querySelector('input[name=\"weightage_percent\"]'); w.removeAttribute('min'); w.removeAttribute('max');})();");
                $browser->select('academic_session_id', (string) $sessionId)
                    ->select('rating_scale_id', (string) $dependencies['rating_scale_id'])
                    ->clear('input[name="weightage_percent"]')->type('input[name="weightage_percent"]', '25')
                    ->press('Save Configuration')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertSame($before, BaConfig::query()->count(), 'Out-of-range weightage should be rejected.');
        } finally {
            BaConfig::query()->where('academic_session_id', $sessionId)->forceDelete();
        }
    }

    /** TC-N12 · BC-VAL-05 · Source: BaConfigRequest aggregation_method in:... */
    public function test_config_12_invalid_aggregation_method_is_rejected(): void
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
                    ->press('Save Configuration')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertSame($before, BaConfig::query()->count(), 'Out-of-enum aggregation_method should be rejected.');
        } finally {
            BaConfig::query()->where('academic_session_id', $sessionId)->forceDelete();
        }
    }

    // ──────────────────────────────────────────────
    //  50–59 / 60–69  Auth + UI
    // ──────────────────────────────────────────────

    /** TC-S01 · BC-AUTH-01 · Source: web routes behind auth middleware */
    public function test_config_13_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    /** TC-P21 · BC-BIZ-07 · Source: Controller@trashed + config/trash.blade */
    public function test_config_14_trash_page_lists_soft_deleted_config(): void
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

    /**
     * TC-S03 · BC-AUTH-03 · Audit-SEC-BA-002 (verify in source).
     * BaConfigRequest::authorize() returns a bare `true`, so the FormRequest itself does not gate;
     * access control relies entirely on the controller's Gate::authorize() calls.
     * Source: BaConfigRequest.php:12-15.
     */
    public function test_config_15_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = new BaConfigRequest();
        $this->assertTrue($request->authorize(),
            'SEC-BA-002 confirmed: FormRequest authorize() returns bare true (auth deferred to controller gates).');

        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.configs.create')", $controller);
    }

    // ──────────────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────────────

    private function configDependenciesOrSkip(): array
    {
        $adminUserId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));
        if ($adminUserId <= 0) {
            $this->markTestSkipped('No admin user found for configuration tests.');
        }

        $scaleId = (int) BaRatingScale::query()->where('is_active', true)->orderBy('id')->value('id');
        if ($scaleId <= 0) {
            $scale = BaRatingScale::query()->create([
                'code'        => 'CFGSCL' . $this->generateUniqueSuffix(),
                'name'        => 'Config Dep Scale ' . $this->generateUniqueSuffix(),
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
            'academic_session_id'           => 0, // replaced by createRecordDirectly with a free session id
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

    private function generateUniqueSuffix(): string
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

        $permissions = $this->configPermissions();
        $this->ensurePermissionsExist($permissions);

        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
    }

    private function configPermissions(): array
    {
        return [
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

    /** Reference to BaConfigRequest to keep the FormRequest import meaningful for static tools. */
    private function requestClassName(): string
    {
        return BaConfigRequest::class;
    }

    /** Reference to the config table name (prefixed) for parity with the sibling helper surface. */
    private function configTableName(): string
    {
        return DB::getTablePrefix() . self::CONFIG_TABLE;
    }
}
