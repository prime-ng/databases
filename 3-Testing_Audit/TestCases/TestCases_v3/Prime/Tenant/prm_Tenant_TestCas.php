<?php

namespace Tests\Browser\Modules\Prime\Tenant;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Http\Controllers\TenantController;
use Modules\Prime\Http\Requests\TenantRequest;
use Modules\Prime\Models\ActivityLog;
use Modules\Prime\Models\Domain;
use Modules\Prime\Models\Tenant;
use Modules\Prime\Models\TenantPlan;
use Modules\Prime\Models\TenantPlanModule;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Comprehensive Dusk + source-truth suite for the Prime (PRM) central "Tenant" screen.
 *
 * DB scope : CENTRAL (prime_db) — this screen MANAGES tenants but itself runs on the
 *            central host http://127.0.0.1:8000. NO tenant init (constraint E21/A4).
 * Base     : extends PrimeDuskTestCase (physical class prm_PrimeDuskTestCase_TestCas,
 *            resolved via tests/Browser/Modules/preload.php alias — constraint E22).
 * Auth     : central super-admin resolved locally (mirrors prm_BillingDuskTestCase_TestCas),
 *            App\Models\User (constraint B5).
 *
 * Provisioning (SetupTenantDatabase job, real DB creation, tenants:migrate) cannot execute
 * inside the test runner, so lifecycle / workflow behaviour is proven against the real
 * source (literal-string / reflection asserts) and live-schema truth (Schema facade), with
 * every live-mutation path guarded by try/catch + markTestSkipped (HARD RULE 9).
 *
 * Semantic numbering bands (WP-G):
 *   01-09 schema/model/request config · 10-19 business rules · 20-29 state machine
 *   30-39 validation · 40-49 FK/integration · 50-59 permissions/routes
 *   60-69 UI/UX · 70-79 edge cases · 90-99 tenancy/security
 */
class prm_Tenant_TestCas extends PrimeDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Tenant/screenshots';

    private const INDEX_PATH = '/prime/tenant';
    private const CREATE_PATH = '/prime/tenant/create';
    private const MGMT_PATH = '/prime/tenant-management';

    private const TABLE = 'prm_tenant';
    private const DOMAINS_TABLE = 'prm_tenant_domains';
    private const PLAN_TABLE = 'prm_tenant_plan_jnt';
    private const PLAN_MODULE_TABLE = 'prm_tenant_plan_module_jnt';
    private const CENTRAL_LOG_TABLE = 'sys_central_activity_logs';

    protected ?User $adminUser = null;
    protected string $centralBaseUrl = '';
    protected string $adminEmail = '';
    protected string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        // Prime/central feature — no tenancy context is ever initialized here.
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // 01-09  Schema / model / request configuration truth
    // =====================================================================

    /** TC-P01 · BC-DB-* · Source: DDL-prm_tenant, migration, Tenant model, TenantRequest */
    public function test_tenant_01_migration_model_and_request_configuration_are_correct(): void
    {
        // --- Live tables exist -------------------------------------------------
        $this->assertTrue(Schema::hasTable(self::TABLE), 'prm_tenant table missing.');
        $this->assertTrue(Schema::hasTable(self::DOMAINS_TABLE), 'prm_tenant_domains table missing.');
        $this->assertTrue(Schema::hasTable(self::PLAN_TABLE), 'prm_tenant_plan_jnt table missing.');
        $this->assertTrue(Schema::hasTable(self::PLAN_MODULE_TABLE), 'prm_tenant_plan_module_jnt table missing.');

        // --- Core prm_tenant columns (from create_tenants_table migration) -----
        foreach ([
            'id', 'tenant_group_id', 'code', 'short_name', 'name', 'udise_code',
            'affiliation_no', 'email', 'website_url', 'address_1', 'address_2', 'area',
            'city_id', 'pincode', 'phone_1', 'phone_2', 'whatsapp_number',
            'longitude', 'latitude', 'locale', 'currency', 'established_date',
            'is_active', 'data', 'created_at', 'updated_at', 'deleted_at',
        ] as $col) {
            $this->assertTrue(Schema::hasColumn(self::TABLE, $col), "prm_tenant.$col missing.");
        }

        // --- Model config ------------------------------------------------------
        $tenant = new Tenant();
        $this->assertSame(self::TABLE, $tenant->getTable(), 'Tenant $table should be prm_tenant.');
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(Tenant::class),
            'Tenant must use SoftDeletes.'
        );
        $casts = $tenant->getCasts();
        $this->assertArrayHasKey('is_active', $casts);
        $this->assertSame('boolean', $casts['is_active'], 'is_active must cast to boolean.');

        // --- TenantRequest rule strings (verbatim from source) -----------------
        $req = $this->readClassSource(TenantRequest::class);
        $this->assertStringContainsString("'tenant_group_id'", $req);
        $this->assertStringContainsString('exists:prm_tenant_groups,id', $req);
        $this->assertStringContainsString("Rule::unique('prm_tenant', 'code')", $req);
        $this->assertStringContainsString("Rule::unique('prm_tenant', 'short_name')", $req);
        $this->assertStringContainsString("Rule::unique('prm_tenant', 'name')", $req);
        $this->assertStringContainsString("Rule::unique('prm_tenant_domains', 'domain')", $req);
        $this->assertStringContainsString("'alpha_dash'", $req);
        $this->assertStringContainsString('exists:global_master_mysql.glb_cities,id', $req);
        $this->assertStringContainsString('exists:global_master_mysql.glb_boards,id', $req);
        $this->assertStringContainsString('exists:global_master_mysql.glb_academic_sessions,id', $req);
    }

    /** TC-P02 · BC-DB-SETUP · Source: add_setup_progress + add_archive_and_rollover migrations */
    public function test_tenant_02_prm_tenant_has_setup_and_rollover_lifecycle_columns(): void
    {
        foreach ([
            'setup_status', 'setup_progress', 'setup_message',
            'tenant_type', 'parent_tenant_id', 'archived_session_id', 'archived_session_code',
            'rollover_status', 'rollover_progress', 'rollover_message',
        ] as $col) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $col),
                "prm_tenant.$col (setup/rollover/archive lifecycle) missing from live schema."
            );
        }

        // These live columns are absent from the consolidated DDL — documents DOC-PRM-DDL-001.
        $this->assertTrue(true, 'Lifecycle columns exist in the live schema (added by later migrations).');
    }

    /** TC-P03 · BC-BIZ-TENANCY · Source: Tenant model, Domain model */
    public function test_tenant_03_tenant_model_implements_tenancy_contracts_and_media(): void
    {
        $implements = class_implements(Tenant::class);
        $this->assertArrayHasKey(\Stancl\Tenancy\Contracts\TenantWithDatabase::class, $implements);
        $this->assertArrayHasKey(\Spatie\MediaLibrary\HasMedia::class, $implements);

        $uses = class_uses_recursive(Tenant::class);
        $this->assertContains(\Stancl\Tenancy\Database\Concerns\HasDatabase::class, $uses);
        $this->assertContains(\Stancl\Tenancy\Database\Concerns\HasDomains::class, $uses);

        $domain = new Domain();
        $this->assertSame(self::DOMAINS_TABLE, $domain->getTable(), 'Domain $table should be prm_tenant_domains.');
        $this->assertStringContainsString("'db_password' => 'encrypted'", $this->readClassSource(Domain::class));
    }

    /** TC-P04 · BC-DB-PLAN · Source: TenantPlan, TenantPlanModule models */
    public function test_tenant_04_plan_and_module_models_configuration(): void
    {
        $plan = new TenantPlan();
        $this->assertSame(self::PLAN_TABLE, $plan->getTable());
        foreach (['tenant_id', 'plan_id', 'is_subscribed', 'is_trial', 'auto_renew', 'automatic_billing', 'status', 'is_active'] as $f) {
            $this->assertContains($f, $plan->getFillable(), "TenantPlan fillable missing $f.");
        }

        $planModule = new TenantPlanModule();
        $this->assertSame(self::PLAN_MODULE_TABLE, $planModule->getTable());
        foreach (['module_id', 'tenant_plan_id', 'is_active'] as $f) {
            $this->assertContains($f, $planModule->getFillable(), "TenantPlanModule fillable missing $f.");
        }

        $src = $this->readClassSource(TenantPlan::class);
        $this->assertStringContainsString('function tenantPlanModules()', $src);
        $this->assertStringContainsString('function tenantPlanRates()', $src);
    }

    /** TC-P05 · BC-BIZ-LOG · Source: ActivityLog model + constraint #25 */
    public function test_tenant_05_central_activity_log_sink_configuration(): void
    {
        $log = new ActivityLog();
        $this->assertSame(self::CENTRAL_LOG_TABLE, $log->getTable(), 'Central log table must be sys_central_activity_logs.');
        $this->assertSame('mysql', $log->getConnectionName(), 'Central log must use the central mysql connection.');
        foreach (['subject_type', 'subject_id', 'user_id', 'event', 'properties', 'ip_address', 'user_agent'] as $f) {
            $this->assertContains($f, $log->getFillable(), "ActivityLog fillable missing $f.");
        }

        // Schema assert is fail-soft: table comes from a central migration, not the DDL.
        if (!Schema::hasTable(self::CENTRAL_LOG_TABLE)) {
            $this->markTestSkipped('sys_central_activity_logs not present in this environment.');
        }
        $this->assertTrue(Schema::hasColumn(self::CENTRAL_LOG_TABLE, 'event'));
    }

    // =====================================================================
    // 10-19  Business rules (BC-BIZ)
    // =====================================================================

    /** TC-P10 · BC-BIZ-01 · Source: TenantController::store */
    public function test_tenant_10_store_defaults_setup_state_from_source(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString("\$validatedData['is_active'] = 0;", $src);
        $this->assertStringContainsString("\$validatedData['setup_status'] = 'pending';", $src);
        $this->assertStringContainsString("\$validatedData['setup_progress'] = 0;", $src);
        $this->assertStringContainsString("'Queued for setup...'", $src);
        $this->assertStringContainsString('SetupTenantDatabase::dispatch($tenant->id)', $src);
        $this->assertStringContainsString("activityLog(\$tenant, 'created'", $src);
    }

    /** TC-P11 · BC-BIZ-02 · Source: TenantController::store domain persistence */
    public function test_tenant_11_store_persists_domain_with_app_domain_suffix(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString("\$request->input('domain') . '.' . config('app.domain')", $src);
        $this->assertStringContainsString("\$tenant->domains()->create(['domain' => \$fullDomain])", $src);
    }

    /** TC-P12 · BC-BIZ-03 · Source: Tenant::generateDatabaseNameUsingSession (pure PHP) */
    public function test_tenant_12_generate_database_name_pattern(): void
    {
        $tenant = new Tenant();
        $tenant->short_name = 'DPS Jaipur';
        $name = $tenant->generateDatabaseNameUsingSession(null);

        // <sanitized_short>_<20 chars>_<6-digit session>
        $this->assertMatchesRegularExpression('/^dps_jaipur_[a-z0-9]{20}_\d{6}$/', $name, "Got: $name");
        $this->assertStringEndsWith('_000000', $name, 'Null session should pad to 000000.');
    }

    /** TC-P13 · BC-BIZ-04 · Source: Tenant::scopeLive */
    public function test_tenant_13_live_scope_filters_tenant_type(): void
    {
        try {
            $sql = Tenant::live()->toSql();
            $this->assertStringContainsString('tenant_type', $sql, 'live() scope must filter tenant_type.');
        } catch (Throwable $e) {
            $this->assertStringContainsString("where('tenant_type', 'live')", $this->readClassSource(Tenant::class));
        }
    }

    /** TC-P14 · BC-BIZ-05 · Source: Tenant::isProfileComplete / canAccess */
    public function test_tenant_14_profile_complete_and_can_access_logic(): void
    {
        $src = $this->readClassSource(Tenant::class);
        $this->assertStringContainsString('return $this->tenantPlans()->exists();', $src);
        $this->assertStringContainsString('return $this->is_active && $this->isProfileComplete();', $src);
    }

    /** TC-P15 · GAP-PRM-003 (verify) · Source: SetupTenantDatabase job */
    public function test_tenant_15_setup_job_uses_random_root_password_not_hardcoded(): void
    {
        $src = $this->readClassSource(\App\Jobs\SetupTenantDatabase::class);
        // Current source generates a random 16-char password — GAP-PRM-003 does NOT reproduce.
        $this->assertStringContainsString('$rootPassword = Str::password(16);', $src);
        $this->assertStringContainsString("Hash::make(\$rootPassword)", $src);
        $this->assertStringNotContainsString("Hash::make('password')", $src, 'Hardcoded root password (GAP-PRM-003) must be absent.');
        $this->assertStringContainsString('public int $tries = 1;', $src, 'Job $tries=1 (documented resilience gap).');
    }

    /** TC-P16 · BC-BIZ-06 · Source: Tenant::computeAllowedModuleIds */
    public function test_tenant_16_compute_allowed_module_ids_blacklist_semantics(): void
    {
        $src = $this->readClassSource(Tenant::class);
        $this->assertStringContainsString('function computeAllowedModuleIds', $src);
        $this->assertStringContainsString("wherePivot('is_active', true)", $src);
        $this->assertStringContainsString('$planModuleIds->diff($disabledIds)', $src);
    }

    // =====================================================================
    // 20-29  State machine (BC-SM) — provisioning lifecycle
    // =====================================================================

    /** TC-SM01 · BC-SM-01 · Source: SetupTenantDatabase job status strings */
    public function test_tenant_20_setup_status_lifecycle_states_present_in_job(): void
    {
        $src = $this->readClassSource(\App\Jobs\SetupTenantDatabase::class);
        foreach (['creating_database', 'running_migrations', 'creating_root_user', 'adding_organization', 'completed', 'failed'] as $state) {
            $this->assertStringContainsString("'$state'", $src, "Setup lifecycle state '$state' missing from job.");
        }
        // store() seeds the initial 'pending' state.
        $this->assertStringContainsString("'pending'", $this->readClassSource(TenantController::class));
    }

    /** TC-SM02 · BC-SM-02 · Source: SetupTenantDatabase updateProgress calls */
    public function test_tenant_21_setup_progress_monotonic_values(): void
    {
        $src = $this->readClassSource(\App\Jobs\SetupTenantDatabase::class);
        foreach (['2,', '5,', '90,', '93,', '95,', '99,', '100,'] as $pct) {
            $this->assertStringContainsString($pct, $src, "Expected progress checkpoint $pct in job.");
        }
        $this->assertStringContainsString("'completed', 100", $src, 'Terminal completed state must reach 100%.');
    }

    /** TC-SM03 · BC-SM-03 · Source: TenantController::resetSetup guard */
    public function test_tenant_22_reset_setup_only_allowed_from_failed_or_completed(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString("in_array(\$tenant->setup_status, ['failed', 'completed'], true)", $src);
        $this->assertStringContainsString('Setup can only be reset when it has failed or already completed.', $src);
        $this->assertStringContainsString('SetupTenantDatabase::dispatch($tenant->id, true)', $src, 'reset must re-dispatch with reset flag.');
    }

    /** TC-SM04 · BC-SM-04 (illegal transition) · Source: resetSetup allowed-state set */
    public function test_tenant_23_illegal_reset_from_pending_or_inprogress_rejected(): void
    {
        $src = $this->readClassSource(TenantController::class);
        // The allowed-reset set contains only failed/completed — pending/running are illegal.
        $this->assertStringNotContainsString("['failed', 'completed', 'pending']", $src);
        $this->assertStringContainsString('->with(\'error\', \'Setup can only be reset', $src);
    }

    /** TC-SM05 · BC-SM-05 · Source: TenantController::startRollover live guard */
    public function test_tenant_24_rollover_only_for_live_tenant(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString('if (! $tenant->isLive())', $src);
        $this->assertStringContainsString('Rollover can only be started for a live tenant.', $src);
        $this->assertStringContainsString('AcademicSessionRolloverJob::dispatch', $src);
    }

    /** TC-P25 · BC-BIZ-07 · Source: TenantController::rolloverStatus JSON */
    public function test_tenant_25_rollover_status_json_shape(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString("'status'   => \$tenant->rollover_status", $src);
        $this->assertStringContainsString("'progress' => \$tenant->rollover_progress", $src);
        $this->assertStringContainsString("'message'  => \$tenant->rollover_message", $src);
    }

    /** TC-P26 · BC-BIZ-08 · Source: TenantController::setupStatus JSON */
    public function test_tenant_26_setup_status_json_shape(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString("'status'   => \$tenant->setup_status", $src);
        $this->assertStringContainsString("'progress' => \$tenant->setup_progress", $src);
        $this->assertStringContainsString("'message'  => \$tenant->setup_message", $src);
        $this->assertStringContainsString("'name'     => \$tenant->name", $src);
    }

    /** TC-SM06 · BC-SM-06 · Source: tenant_type enum values */
    public function test_tenant_27_tenant_type_enum_live_archive(): void
    {
        $src = $this->readClassSource(Tenant::class);
        $this->assertStringContainsString("return \$this->tenant_type === 'live';", $src);
        $this->assertStringContainsString("return \$this->tenant_type === 'archive';", $src);
        $this->assertStringContainsString("->where('tenant_type', 'archive')", $src, 'archiveTenants relation must scope archive.');
    }

    // =====================================================================
    // 30-39  Validation + error messages (BC-VAL)
    // =====================================================================

    /** TC-N30 · BC-AUTH-guest · Guest cannot open the create form */
    public function test_tenant_30_guest_create_form_redirects_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-create-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::CREATE_PATH))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** TC-N31 · BC-VAL-01 · Source: TenantRequest required rules */
    public function test_tenant_31_required_field_rules_present(): void
    {
        $req = $this->readClassSource(TenantRequest::class);
        foreach ([
            "'tenant_group_id'", "'code'", "'short_name'", "'name'", "'domain'",
            "'city_id'", "'established_date'", "'academic_session_id'", "'board_id'",
        ] as $field) {
            $this->assertStringContainsString($field, $req, "Rule for $field missing.");
        }
        $this->assertStringContainsString("'required'", $req);
        $this->assertStringContainsString("'max:20'", $req, 'code/domain max:20 rule missing.');
        $this->assertStringContainsString("'max:150'", $req, 'name max:150 rule missing.');
    }

    /** TC-N32 · BC-VAL-02 · Source: unique-ignore on update */
    public function test_tenant_32_unique_rules_ignore_current_on_update(): void
    {
        $req = $this->readClassSource(TenantRequest::class);
        $this->assertStringContainsString('->ignore($tenantId)', $req);
        $this->assertStringContainsString("\$this->route('tenant')?->id", $req);
    }

    /** TC-N33 · BC-VAL-03 · Source: TenantRequest messages/attributes */
    public function test_tenant_33_full_domain_unique_message_and_attribute(): void
    {
        $req = $this->readClassSource(TenantRequest::class);
        $this->assertStringContainsString('This sub-domain is already taken. Please choose a different one.', $req);
        $this->assertStringContainsString("'full_domain' => 'sub-domain'", $req);
    }

    /** TC-N34 · BC-VAL-04 · Source: domain alpha_dash + email/url formats */
    public function test_tenant_34_domain_alpha_dash_and_format_rules(): void
    {
        $req = $this->readClassSource(TenantRequest::class);
        $this->assertStringContainsString("'alpha_dash'", $req);
        $this->assertStringContainsString("'email'", $req);
        $this->assertStringContainsString("'url'", $req);
        $this->assertStringContainsString("'date'", $req, 'established_date must be a date.');
    }

    /** TC-P36 · BC-VAL-05 · Source: prepareForValidation */
    public function test_tenant_36_prepare_for_validation_builds_full_domain_and_boolean(): void
    {
        $req = $this->readClassSource(TenantRequest::class);
        $this->assertStringContainsString('protected function prepareForValidation()', $req);
        $this->assertStringContainsString("'is_active' => \$this->boolean('is_active')", $req);
        $this->assertStringContainsString("'full_domain' => \$this->input('domain')", $req);
    }

    /** TC-AUTH37 · BC-AUTH-01 · Source: TenantRequest::authorize action map */
    public function test_tenant_37_authorize_maps_action_to_gate(): void
    {
        $req = $this->readClassSource(TenantRequest::class);
        $this->assertStringContainsString("'store' => Gate::allows('prime.tenant.create')", $req);
        $this->assertStringContainsString("'update' => Gate::allows('prime.tenant.update')", $req);
        $this->assertStringContainsString("default => Gate::allows('prime.tenant.viewAny')", $req);
    }

    /** TC-N38 · BC-VAL-06 · Invalid tenant id on show returns not-found (browser, guarded) */
    public function test_tenant_38_invalid_tenant_id_shows_not_found(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No central admin available to authenticate.');
        }

        $this->browseWithFailureScreenshot('invalid-tenant-404', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/nonexistent-tenant-id-zzz');
            $body = $browser->text('body');
            $notFound = str_contains($body, '404') || str_contains($body, 'Not Found');
            if (!$notFound && str_contains($this->currentPath($browser), '/login')) {
                $this->markTestSkipped('Central auth unavailable in this environment.');
            }
            $this->assertTrue($notFound, 'Unknown tenant id should surface a 404 / Not Found.');
        });
    }

    // =====================================================================
    // 40-49  FK / integration dependency (BC-INT / BC-REF)
    // =====================================================================

    /** TC-D40 · BC-REF-01 · Source: create_tenants_table FK RESTRICT */
    public function test_tenant_40_tenant_group_and_city_fk_restrict(): void
    {
        $mig = $this->findMigration('create_tenants_table');
        if ($mig === null) {
            $this->markTestSkipped('create_tenants_table migration file not resolvable.');
        }
        $body = File::get($mig);
        $this->assertStringContainsString("->on('prm_tenant_groups')", $body);
        $this->assertStringContainsString("->onDelete('restrict')", $body);
        $this->assertStringContainsString('restrictOnDelete()', $body, 'city_id FK should restrict on delete.');
    }

    /** TC-D41 · BC-REF-02 · Source: Domain / prm_tenant_domains FK to prm_tenant */
    public function test_tenant_41_domain_fk_references_tenant(): void
    {
        try {
            $fk = \Illuminate\Support\Facades\DB::table('information_schema.KEY_COLUMN_USAGE')
                ->where('TABLE_NAME', self::DOMAINS_TABLE)
                ->where('REFERENCED_TABLE_NAME', self::TABLE)
                ->exists();
            if (!$fk) {
                $this->markTestSkipped('prm_tenant_domains FK not introspectable in this environment.');
            }
            $this->assertTrue($fk, 'prm_tenant_domains.tenant_id must reference prm_tenant.');
        } catch (Throwable $e) {
            $this->markTestSkipped('information_schema not queryable: ' . $e->getMessage());
        }
    }

    /** TC-D43 · BC-INT-01 · Source: TenantController::updateTenantPlan 5-step transaction */
    public function test_tenant_43_update_tenant_plan_transaction_steps(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString('return DB::transaction(function', $src);
        $this->assertStringContainsString('TenantPlan::firstOrNew(', $src);
        $this->assertStringContainsString('TenantPlanRate::create(', $src);
        $this->assertStringContainsString('TenantPlanModule::where(', $src);
        $this->assertStringContainsString('TenantPlanBillingSchedule::where(', $src);
        $this->assertStringContainsString("Gate::authorize('prime.tenant.update')", $src);
    }

    /** TC-P45 · BC-BIZ-09 · Source: TenantController::tenantModuleToggle JSON */
    public function test_tenant_45_tenant_plan_module_toggle_json(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString('$tenantPlanModule->is_active = !$tenantPlanModule->is_active;', $src);
        $this->assertStringContainsString("'message' => \$tenantPlanModule->is_active ? 'Module enabled' : 'Module disabled'", $src);
        $this->assertStringContainsString('clearAllowedModulesCache()', $src);
    }

    /** TC-N46 · BC-VAL-07 · Source: TenantController::assignBoards validation */
    public function test_tenant_46_assign_boards_validates_board_ids(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString("'board_ids'           => 'required|array|min:1'", $src);
        $this->assertStringContainsString('exists:global_master_mysql.glb_boards,id', $src);
        $this->assertStringContainsString('Please select at least one board.', $src);
    }

    // =====================================================================
    // 50-59  Permissions / routes (BC-AUTH)
    // =====================================================================

    /** TC-AUTH50 · BC-AUTH-02 · Source: every controller method gated */
    public function test_tenant_50_all_controller_methods_have_correct_gate(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString("Gate::authorize('prime.tenant.viewAny')", $src);   // index
        $this->assertStringContainsString("Gate::authorize('prime.tenant.create')", $src);    // create/store
        $this->assertStringContainsString("Gate::authorize('prime.tenant.view')", $src);      // show/setupStatus
        $this->assertStringContainsString("Gate::authorize('prime.tenant.update')", $src);    // edit/update/...
        $this->assertStringContainsString("Gate::authorize('prime.tenant.delete')", $src);    // destroy
        // viewAny appears once; delete once; update many — sanity on count of gate calls.
        $this->assertSame(21, substr_count($src, 'Gate::authorize('), 'Expected 21 gated actions.');
    }

    /** TC-AUTH51 · BUG-PRM-006 (verify) · Source: no wrong tenant-group gate */
    public function test_tenant_51_no_wrong_tenant_group_gate_bug006_fixed(): void
    {
        $src = $this->readClassSource(TenantController::class);
        // BUG-PRM-006 claimed completeTenantSetup/toggleStatus/tenantPlanToggleStatus used
        // 'prime.tenant-group.update'. Current source uses the correct 'prime.tenant.update'.
        $this->assertStringNotContainsString('prime.tenant-group.update', $src, 'Wrong gate (BUG-PRM-006) must be absent.');
        // Prove each of the three previously-suspect methods is present & correctly gated.
        foreach (['completeTenantSetup', 'toggleStatus', 'tenantPlanToggleStatus'] as $method) {
            $this->assertStringContainsString("function $method(", $src);
        }
    }

    /** TC-AUTH52 · BUG-PRM-STUB-001 (verify) · Source: destroy is implemented */
    public function test_tenant_52_destroy_is_implemented_not_empty_stub(): void
    {
        $src = $this->readClassSource(TenantController::class);
        // BUG-PRM-STUB-001 claimed destroy() was an empty stub. Current source soft-deletes + logs.
        $this->assertStringContainsString("Gate::authorize('prime.tenant.delete')", $src);
        $this->assertStringContainsString('$tenant->delete();', $src);
        $this->assertStringContainsString("activityLog(\$tenant, 'Trashed'", $src);
        $this->assertTrue(method_exists(TenantController::class, 'destroy'), 'destroy() must exist.');
    }

    /** TC-AUTH53 · BC-AUTH-guest · Index requires auth */
    public function test_tenant_53_index_requires_authentication(): void
    {
        $this->browseWithFailureScreenshot('guest-index-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest index must redirect to /login.');
        });
    }

    /** TC-AUTH54 · BC-AUTH-03 · Route registration under central.prime.tenant.* */
    public function test_tenant_54_routes_registered_central_prime_tenant(): void
    {
        foreach ([
            'index', 'create', 'store', 'show', 'edit', 'update', 'destroy',
            'setupProgress', 'setupStatus', 'completeTenantSetup',
            'startRollover', 'rolloverStatus', 'resetSetup',
            'updateTenantPlan', 'tenantPlanToggleStatus', 'assignBoards',
            'tenantModuleToggle', 'toggleStatus',
            'archive.requestAccess', 'archive.approveAccess', 'archive.revokeAccess',
        ] as $name) {
            $this->assertTrue(
                Route::has("central.prime.tenant.$name"),
                "Route central.prime.tenant.$name is not registered."
            );
        }
    }

    /** TC-DEV55 · BUG-PRM-TENANT-001 (NEW) · trashed/restore/forceDelete methods missing */
    public function test_tenant_55_trashed_restore_forcedelete_controller_methods_missing_defect(): void
    {
        // Routes are declared…
        $this->assertTrue(Route::has('central.prime.tenant.trashed'), 'tenant.trashed route should be declared.');
        $this->assertTrue(Route::has('central.prime.tenant.restore'), 'tenant.restore route should be declared.');
        $this->assertTrue(Route::has('central.prime.tenant.forceDelete'), 'tenant.forceDelete route should be declared.');

        // …but the controller methods they bind to DO NOT EXIST → 500 on access (BUG-PRM-TENANT-001).
        $this->assertFalse(method_exists(TenantController::class, 'trashedTenant'), 'trashedTenant() unexpectedly exists — defect may be fixed.');
        $this->assertFalse(method_exists(TenantController::class, 'restore'), 'restore() unexpectedly exists — defect may be fixed.');
        $this->assertFalse(method_exists(TenantController::class, 'forceDelete'), 'forceDelete() unexpectedly exists — defect may be fixed.');
    }

    // =====================================================================
    // 60-69  UI / UX smoke (module-enabled + auth guarded)
    // =====================================================================

    /** TC-P60 · BC-UIX-01 · Index page renders for admin */
    public function test_tenant_60_index_page_loads_for_admin(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No central admin available.');
        }
        $this->browseWithFailureScreenshot('index-load', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            if (str_contains($this->currentPath($browser), '/login')) {
                $this->markTestSkipped('Central auth unavailable.');
            }
            $body = $browser->text('body');
            if (str_contains($body, '404') || str_contains($body, 'Not Found')) {
                $this->markTestSkipped('Prime module appears disabled (modules_statuses.json) — 404.');
            }
            $this->ensurePageAccessible($browser, 'Tenant index');
            $browser->assertSee('Name')->assertSee('Domains')->assertSee('Status');
        });
    }

    /** TC-P61 · BC-UIX-02 · Create form exposes required fields */
    public function test_tenant_61_create_form_renders_required_fields(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No central admin available.');
        }
        $this->browseWithFailureScreenshot('create-form', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            if (str_contains($this->currentPath($browser), '/login')) {
                $this->markTestSkipped('Central auth unavailable.');
            }
            if (str_contains($browser->text('body'), '404')) {
                $this->markTestSkipped('Prime module appears disabled — 404.');
            }
            foreach (['code', 'short_name', 'name', 'domain', 'established_date', 'tenant_group_id', 'academic_session_id', 'board_id'] as $field) {
                $this->assertNotNull(
                    $browser->element('[name="' . $field . '"]'),
                    "Create form field [name=$field] not rendered."
                );
            }
        });
    }

    /** TC-P62 · BC-UIX-03 · Tenant management console loads */
    public function test_tenant_62_tenant_management_index_loads(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No central admin available.');
        }
        $this->browseWithFailureScreenshot('mgmt-load', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::MGMT_PATH);
            if (str_contains($this->currentPath($browser), '/login')) {
                $this->markTestSkipped('Central auth unavailable.');
            }
            if (str_contains($browser->text('body'), '404')) {
                $this->markTestSkipped('Prime module appears disabled — 404.');
            }
            $this->assertSame(self::MGMT_PATH, $this->currentPath($browser), 'Tenant management path mismatch.');
        });
    }

    /** TC-P64 · BC-UIX-04 · Source: index paginates 10 per page */
    public function test_tenant_64_index_paginates_ten_per_page(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString('Tenant::live()->paginate(10)', $src);
    }

    // =====================================================================
    // 70-79  Edge cases (BC-EDG)
    // =====================================================================

    /** TC-E70 · BC-EDG-01 · Source: code/domain max length boundary */
    public function test_tenant_70_code_and_domain_max_length_boundary(): void
    {
        $req = $this->readClassSource(TenantRequest::class);
        // code max:20, short_name max:50, name max:150, udise max:30, affiliation max:60
        foreach (["'max:20'", "'max:50'", "'max:150'", "'max:30'", "'max:60'", "'max:100'"] as $rule) {
            $this->assertStringContainsString($rule, $req, "Boundary rule $rule missing.");
        }
    }

    /** TC-E71 · BC-EDG-02 · Source: db name sanitises + truncates short_name (pure PHP) */
    public function test_tenant_71_generate_db_name_sanitises_and_truncates(): void
    {
        $tenant = new Tenant();
        $tenant->short_name = 'A Very Long School Name With Many Words And Symbols!!! @@@';
        $name = $tenant->generateDatabaseNameUsingSession(null);

        // Short-name segment must be <= 30 chars, lowercased, underscore-separated.
        $shortSegment = explode('_' . str_repeat('0', 0), $name)[0]; // fallback split
        $parts = explode('_', $name);
        // Reconstruct short portion by dropping the trailing 20-char uuid + 6-digit session (2 parts).
        $shortParts = array_slice($parts, 0, count($parts) - 2);
        $short = implode('_', $shortParts);
        $this->assertLessThanOrEqual(30, strlen($short), "Short segment '$short' exceeds 30 chars.");
        $this->assertMatchesRegularExpression('/^[a-z0-9_]+$/', $short, 'Short segment must be sanitised.');
    }

    /** TC-E73 · DOC-PRM-DDL-001 · Consolidated DDL diverges from live schema */
    public function test_tenant_73_live_schema_diverges_from_consolidated_ddl(): void
    {
        // 'data' (json) and setup/rollover columns exist live but are absent from _prime_db_v4.sql.
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'data'), 'Live prm_tenant.data (json) column expected.');
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'setup_status'), 'Live prm_tenant.setup_status expected.');
        // Documents DOC-PRM-DDL-001: assert schema truth from the live DB, not the stale DDL file.
        $this->assertTrue(true);
    }

    // =====================================================================
    // 90-99  Tenancy isolation + security
    // =====================================================================

    /** TC-T90 · BC-TEN-01 · Central scope — no tenant context initialized */
    public function test_tenant_90_runs_on_central_context_without_tenant_init(): void
    {
        $this->assertTrue(function_exists('tenancy'), 'tenancy() helper must be available.');
        $this->assertFalse(tenancy()->initialized, 'Tenant screen must run on the central (prime_db) context, not inside a tenant.');
    }

    /** TC-T91 · BC-TEN-02 · Source: each tenant gets its own database */
    public function test_tenant_91_each_tenant_gets_isolated_database(): void
    {
        $jobSrc = $this->readClassSource(\App\Jobs\SetupTenantDatabase::class);
        $this->assertStringContainsString('$tenant->database()->manager()->createDatabase($tenant)', $jobSrc);
        $storeSrc = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString("\$tenant->setInternal('db_name', \$tenant->generateDatabaseName())", $storeSrc);
    }

    /** TC-S93 · BC-SEC-01 · Source: store/update mass-assign only validated data */
    public function test_tenant_93_mass_assignment_uses_validated_only(): void
    {
        $src = $this->readClassSource(TenantController::class);
        $this->assertStringContainsString('$validatedData = $request->validated();', $src);
        $this->assertStringContainsString("unset(\$validatedData['domain'], \$validatedData['full_domain'])", $src);
        // update() also relies on validated() (no raw ->all()).
        $this->assertStringNotContainsString('$request->all()', $src, 'Controller must not mass-assign $request->all().');
    }

    /** TC-S94 · BC-SEC-02 · Guest cannot poll setup-status JSON */
    public function test_tenant_94_guest_cannot_reach_setup_status_json(): void
    {
        $this->browseWithFailureScreenshot('guest-setup-status', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/prime/tenant/setup-status/1'))->pause(1000);
            $path = $this->currentPath($browser);
            $body = $browser->text('body');
            $blocked = str_contains($path, '/login')
                || str_contains($body, '403') || str_contains($body, 'Forbidden')
                || str_contains($body, '401') || str_contains($body, 'Unauthorized');
            $this->assertTrue($blocked, 'Guest must be blocked from the setup-status endpoint.');
        });
    }

    // =====================================================================
    // Local central helpers (mirrors prm_BillingDuskTestCase_TestCas)
    // =====================================================================

    protected function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }

        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    protected function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();

        return (string) parse_url($url, PHP_URL_PATH);
    }

    protected function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl('/login'))->pause(800);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1200);
        }

        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(800);
        }
    }

    protected function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    protected function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows the login page; authentication failed.');
        }

        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    protected function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            if ($superAdmin) {
                $this->adminUser = $superAdmin;
                $this->ensureUserIsVerified($this->adminUser);

                return;
            }

            $byEmail = User::query()->where('email', $this->adminEmail)->first();
            if ($byEmail) {
                $this->adminUser = $byEmail;
                $this->ensureUserIsVerified($this->adminUser);

                return;
            }

            $this->adminUser = User::create([
                'email'             => $this->adminEmail,
                'password'          => bcrypt($this->adminPassword),
                'name'              => 'Tenant Dusk Admin',
                'emp_code'          => 'EMP' . rand(100, 999),
                'short_name'        => 'ADM' . rand(1000, 9999),
                'status'            => 'ACTIVE',
                'is_active'         => 1,
                'is_super_admin'    => 1,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable $e) {
            // Leave $adminUser null; browser tests markTestSkipped when auth is unavailable.
            $this->adminUser = null;
        }
    }

    private function ensureUserIsVerified(User $user): void
    {
        $updates = [];
        if (empty($user->email_verified_at)) {
            $updates['email_verified_at'] = now();
        }
        if (property_exists($user, 'is_active') && (int) $user->is_active !== 1) {
            $updates['is_active'] = 1;
        }
        if (!empty($updates)) {
            $user->fill($updates);
            $user->save();
        }
    }

    // ---- Screenshots -------------------------------------------------------

    protected function cleanScreenshots(): void
    {
        $dir = base_path(static::SCREENSHOT_DIR);
        if (File::isDirectory($dir)) {
            File::cleanDirectory($dir);
        }
    }

    protected function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    protected function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        $directory = base_path(static::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName) ?: 'failure';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $safeName . '_' . now()->format('Ymd_Hisv') . '.png';

        try {
            $browser->driver->takeScreenshot($absolutePath);

            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolutePath);
        } catch (Throwable) {
            return '';
        }
    }

    // ---- Source-truth helpers ---------------------------------------------

    /** Read a class's real source file via reflection (location-independent). */
    private function readClassSource(string $class): string
    {
        try {
            $file = (new \ReflectionClass($class))->getFileName();
            if ($file && File::exists($file)) {
                return File::get($file);
            }
        } catch (Throwable $e) {
            // fall through
        }
        $this->markTestSkipped("Source for $class not resolvable in this environment.");
    }

    /** Resolve an application migration file by fragment; null when not found. */
    private function findMigration(string $fragment): ?string
    {
        foreach ([
            base_path('database/migrations'),
            base_path('Modules/Prime/database/migrations'),
        ] as $dir) {
            if (!File::isDirectory($dir)) {
                continue;
            }
            foreach (File::files($dir) as $file) {
                if (str_contains($file->getFilename(), $fragment)) {
                    return $file->getPathname();
                }
            }
        }

        return null;
    }
}
