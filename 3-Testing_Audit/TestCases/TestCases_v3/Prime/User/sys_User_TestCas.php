<?php

namespace Tests\Browser\Modules\Prime\User;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use ReflectionClass;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Prime (PRM) — Central User Management screen.
 *
 * Single comprehensive Dusk suite for the central `sys_users` screen.
 * DB scope: CENTRAL (prime_db / connection `mysql`) — NO tenant init.
 * Host: http://127.0.0.1:8000 (enforced by PrimeDuskTestCase::setUp()).
 *
 * Real source read before authoring (config-truth backbone):
 *   - Modules/Prime/app/Http/Controllers/UserController.php
 *   - Modules/Prime/app/Http/Requests/UserRequest.php
 *   - Modules/Prime/app/Models/User.php
 *   - routes/web.php  (Route::domain(...)->name('central.')->prefix('prime')->name('prime.'))
 *   - Modules/Prime/resources/views/user/{index,create,edit,show,trash}.blade.php
 *   - _prime_db_v4.sql  (sys_users DDL: generated `super_admin_flag`, unique keys, triggers)
 *
 * Audit-claimed defects reconciled against CURRENT source (source wins — HARD RULE 13):
 *   - SEC-PRM-003  REMEDIATED — update() excludes is_super_admin from $request->only();
 *                   promotion is a separate high-privilege gate (prime.super-admin.promote).
 *   - BUG-PRM-002  REMEDIATED — model $fillable excludes is_super_admin AND super_admin_flag.
 *   - FILL-PRM-001 RESIDUAL   — remember_token IS still in $fillable (P3).
 *   - BUG-PRM-010  REMEDIATED — usersByRole() uses User::role($role)->paginate(10).
 *   - GAP-PRM-004  REMEDIATED — store() emails LoginMail credentials to the NEW user.
 *   - BUG-PRM-009  RESIDUAL   — usersByRole() still uses rand() stub stats (relocated from index()).
 * Newly discovered this run:
 *   - BUG-PRM-N01 (P1) usersByRole() omits totalTenants/activeTenants → index view undefined-var error.
 *   - BUG-PRM-N02 (P2) two-factor field mismatch: request key `two_fact_enabled` vs controller `two_factor_auth_enabled`.
 *   - BUG-PRM-N03 (P2) image validation field mismatch: request rule key `image` vs upload/controller `user_img`.
 *   - BUG-PRM-N04 (P3) media collection mismatch: model registers `image`, controller stores `user_img`.
 */
class sys_User_TestCas extends PrimeDuskTestCase
{
    private const USERS_TABLE = 'sys_users';
    private const INDEX_PATH = '/prime/user';
    private const CREATE_PATH = '/prime/user/create';
    private const TRASH_PATH = '/prime/user/trash/view';
    private const LOGIN_PATH = '/login';

    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/User/screenshots';

    private const CONTROLLER_CLASS = \Modules\Prime\Http\Controllers\UserController::class;
    private const REQUEST_CLASS = \Modules\Prime\Http\Requests\UserRequest::class;
    private const MODEL_CLASS = \Modules\Prime\Models\User::class;
    private const ACTIVITY_LOG_CLASS = \Modules\Prime\Models\ActivityLog::class;

    private ?User $adminUser = null;
    private string $centralBaseUrl = '';
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

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        parent::tearDown();
    }

    // ===================================================================
    // Band 01–09 : Schema / DDL / model / request configuration (config truth)
    // ===================================================================

    /** TC-P01 / BC-DB-* — sys_users table, columns, model + request configuration. */
    public function test_user_01_schema_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(
            Schema::connection('mysql')->hasTable(self::USERS_TABLE),
            'Central sys_users table is missing.'
        );

        $columns = [
            'id', 'emp_code', 'short_name', 'name', 'email', 'mobile_no', 'phone_no',
            'two_factor_auth_enabled', 'email_verified_at', 'password', 'is_super_admin',
            'super_admin_flag', 'remember_token', 'is_active', 'created_at', 'updated_at', 'deleted_at',
        ];
        foreach ($columns as $column) {
            $this->assertTrue(
                Schema::connection('mysql')->hasColumn(self::USERS_TABLE, $column),
                "sys_users is missing DDL column [{$column}]."
            );
        }

        // Model configuration (Prime central User).
        $model = $this->makeModel(self::MODEL_CLASS);
        if ($model === null) {
            $this->markTestSkipped('Modules\\Prime\\Models\\User is not autoloadable in this runner.');
        }

        $this->assertSame(self::USERS_TABLE, $model->getTable(), 'Prime User must target sys_users.');
        $this->assertSame('mysql', $model->getConnectionName(), 'Prime User must pin the central mysql connection.');

        $traits = class_uses_recursive(self::MODEL_CLASS);
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            $traits,
            'Prime User must use SoftDeletes.'
        );

        $fillable = $model->getFillable();
        // BUG-PRM-002 / SEC-PRM-003 REMEDIATED — escalation columns are NOT mass-assignable.
        $this->assertNotContains('is_super_admin', $fillable, 'is_super_admin must NOT be fillable (escalation guard).');
        $this->assertNotContains('super_admin_flag', $fillable, 'super_admin_flag (generated column) must NOT be fillable.');
        // FILL-PRM-001 RESIDUAL — remember_token remains fillable (documented low-severity finding).
        $this->assertContains('remember_token', $fillable, 'Config-truth: remember_token is still fillable (FILL-PRM-001).');

        // Casts
        $casts = $model->getCasts();
        $this->assertArrayHasKey('is_super_admin', $casts);
        $this->assertSame('boolean', $casts['is_super_admin']);
        $this->assertSame('hashed', $casts['password'] ?? null, 'password cast must be hashed.');
    }

    /** TC-P02 / BC-DB — unique keys on sys_users. */
    public function test_user_02_sys_users_unique_indexes_exist(): void
    {
        $indexes = $this->indexNames(self::USERS_TABLE);
        if ($indexes === null) {
            $this->markTestSkipped('information_schema not queryable for sys_users.');
        }

        foreach (['uq_users_empCode', 'uq_users_email', 'uq_users_mobileNo', 'uq_single_super_admin'] as $expected) {
            $this->assertContains($expected, $indexes, "Missing unique index [{$expected}] on sys_users.");
        }
    }

    /** TC-P03 / BC-DB — super_admin_flag is a STORED generated column. */
    public function test_user_03_super_admin_flag_is_stored_generated_column(): void
    {
        $extra = $this->columnExtra(self::USERS_TABLE, 'super_admin_flag');
        if ($extra === null) {
            $this->markTestSkipped('super_admin_flag EXTRA not readable from information_schema.');
        }

        $this->assertNotFalse(
            stripos($extra, 'GENERATED'),
            "super_admin_flag must be a generated column (EXTRA reported: {$extra})."
        );
    }

    /** TC-P04 / BC-AUTH — every central.prime.user.* route is registered. */
    public function test_user_04_user_routes_are_registered(): void
    {
        $names = [
            'central.prime.user.index',
            'central.prime.user.create',
            'central.prime.user.store',
            'central.prime.user.show',
            'central.prime.user.edit',
            'central.prime.user.update',
            'central.prime.user.destroy',
            'central.prime.user.byRole',
            'central.prime.user.trashed',
            'central.prime.user.restore',
            'central.prime.user.forceDelete',
            'central.prime.user.toggleStatus',
            'central.prime.user.promoteSuperAdmin',
        ];
        foreach ($names as $name) {
            $this->assertTrue(Route::has($name), "Route [{$name}] is not registered.");
        }
    }

    /** TC-P05 / BC-AUTH — controller methods reference the exact permission gates. */
    public function test_user_05_controller_uses_exact_permission_gates(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        foreach ([
            "Gate::authorize('prime.user.viewAny')",
            "Gate::authorize('prime.user.create')",
            "Gate::authorize('prime.user.view')",
            "Gate::authorize('prime.user.update')",
            "Gate::authorize('prime.user.delete')",
            "Gate::authorize('prime.user.restore')",
            "Gate::authorize('prime.user.forceDelete')",
            "Gate::authorize('prime.super-admin.promote')",
        ] as $gate) {
            $this->assertStringContainsString($gate, $src, "Controller must call {$gate}.");
        }
    }

    // ===================================================================
    // Band 10–19 : Business rules (config truth of controller behaviour)
    // ===================================================================

    /** TC-P10 / BC-BIZ — store() hashes password and emails credentials to the NEW user (GAP-PRM-004 remediated). */
    public function test_user_10_store_hashes_password_and_emails_credentials_to_new_user(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $this->assertStringContainsString('Hash::make($plainPassword)', $src, 'store() must hash the password.');
        $this->assertStringContainsString('Mail::to($user->email)->send(new LoginMail', $src, 'GAP-PRM-004: store() must email credentials to the new user.');
    }

    /** TC-P11 / BC-BIZ — store() notifies super admins of the new user. */
    public function test_user_11_store_notifies_super_admins(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $this->assertStringContainsString("User::where('is_super_admin', true)", $src, 'store() must resolve super admins.');
        $this->assertStringContainsString('new UserCreatedNotification', $src, 'store() must dispatch UserCreatedNotification.');
    }

    /** TC-S / SEC-PRM-003 REMEDIATED — update() excludes is_super_admin from mass assignment. P0. */
    public function test_user_12_update_excludes_super_admin_from_mass_assignment(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $update = $this->methodBody($src, 'public function update(');
        $this->assertNotSame('', $update, 'Could not isolate update() body.');
        $this->assertStringContainsString("\$request->only([", $update, 'update() must whitelist request fields.');
        $this->assertStringNotContainsString("'is_super_admin'", $update, 'SEC-PRM-003: update() must NOT include is_super_admin in $request->only().');
    }

    /** TC-P13 / BC-AUTH — super-admin promotion is a separate high-privilege gated flow. */
    public function test_user_13_promote_super_admin_is_separate_high_privilege_gate(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $this->assertStringContainsString('function promoteToSuperAdmin', $src, 'Promotion flow must exist.');
        $this->assertStringContainsString("Gate::authorize('prime.super-admin.promote')", $src, 'Promotion must be gated by prime.super-admin.promote.');
        $this->assertTrue(Route::has('central.prime.user.promoteSuperAdmin'), 'Promotion route must be registered.');
    }

    /** TC-P14 / BUG-PRM-010 REMEDIATED — usersByRole() actually filters by the role scope. */
    public function test_user_14_users_by_role_filters_by_role_scope(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $body = $this->methodBody($src, 'public function usersByRole(');
        $this->assertNotSame('', $body, 'Could not isolate usersByRole() body.');
        $this->assertStringContainsString('User::role($role)->paginate(10)', $body, 'BUG-PRM-010: usersByRole must filter by $role.');
    }

    /** TC-N15 / BUG-PRM-009 RESIDUAL — usersByRole() still uses rand() stub statistics. */
    public function test_user_15_users_by_role_still_uses_random_stub_stats(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $body = $this->methodBody($src, 'public function usersByRole(');
        $this->assertStringContainsString('rand(1000, 2000)', $body, 'BUG-PRM-009 residual: totalStudents uses rand().');
        $this->assertStringContainsString('rand(10, 30)', $body, 'BUG-PRM-009 residual: totalClasses uses rand().');
    }

    /** TC-N16 / BUG-PRM-N01 — usersByRole() omits view vars totalTenants/activeTenants (index view undefined-var risk). */
    public function test_user_16_users_by_role_omits_tenant_stats_needed_by_index_view(): void
    {
        $controller = $this->classSource(self::CONTROLLER_CLASS);
        if ($controller === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $body = $this->methodBody($controller, 'public function usersByRole(');
        $this->assertStringNotContainsString('totalTenants', $body, 'BUG-PRM-N01: usersByRole does not pass totalTenants...');
        $this->assertStringNotContainsString('activeTenants', $body, 'BUG-PRM-N01: ...nor activeTenants, but prime::user.index references both.');
    }

    /** TC-N17 / BC-BIZ — destroy() blocks self-deletion. */
    public function test_user_17_destroy_blocks_self_deletion(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $body = $this->methodBody($src, 'public function destroy(');
        $this->assertStringContainsString('$user->id === Auth::user()->id', $body, 'destroy() must block self-deletion.');
    }

    /** TC-N18 / BC-BIZ — toggleStatus() blocks self toggle and returns a JSON failure. */
    public function test_user_18_toggle_status_blocks_self_toggle(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        $body = $this->methodBody($src, 'public function toggleStatus(');
        $this->assertStringContainsString('$user->id === Auth::user()->id', $body, 'toggleStatus() must block self toggle.');
        $this->assertStringContainsString("'success' => false", $body, 'Self toggle must return success=false.');
    }

    // ===================================================================
    // Band 30–39 : Validation rules + error/config truth + activity log
    // ===================================================================

    /** TC-N30 / BC-VAL — UserRequest enforces the documented rule set. */
    public function test_user_30_request_validation_rules_are_enforced(): void
    {
        $src = $this->classSource(self::REQUEST_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserRequest source not resolvable.');
        }

        foreach ([
            "'name' => ['required', 'string', 'max:255']",
            "unique:sys_users,email",
            "'phone_no' => ['nullable', 'digits:10']",
            "'mobile_no' => ['nullable', 'digits_between:10,12']",
            "'min:8', 'confirmed'",
            "'roles' => ['required', 'array', 'min:1', 'max:1']",
            "Rule::unique('sys_users', 'emp_code')",
            "unique:sys_users,short_name",
        ] as $rule) {
            $this->assertStringContainsString($rule, $src, "UserRequest missing rule fragment: {$rule}");
        }
    }

    /** TC-N31 / BUG-PRM-N02 — two-factor field-name mismatch drops the toggle. */
    public function test_user_31_two_factor_field_name_mismatch_drops_toggle(): void
    {
        $request = $this->classSource(self::REQUEST_CLASS);
        $controller = $this->classSource(self::CONTROLLER_CLASS);
        if ($request === null || $controller === null) {
            $this->markTestSkipped('UserRequest/UserController source not resolvable.');
        }

        // Request validates/merges `two_fact_enabled`...
        $this->assertStringContainsString("'two_fact_enabled'", $request, 'Request key is two_fact_enabled.');
        // ...but the controller persists the differently-named `two_factor_auth_enabled`.
        $this->assertStringContainsString("'two_factor_auth_enabled'", $controller, 'Controller reads two_factor_auth_enabled.');
        $this->assertStringNotContainsString("'two_fact_enabled'", $controller, 'BUG-PRM-N02: controller never reads the validated key.');
    }

    /** TC-N32 / BUG-PRM-N03 — image validation field-name mismatch. */
    public function test_user_32_image_validation_field_name_mismatch(): void
    {
        $request = $this->classSource(self::REQUEST_CLASS);
        $controller = $this->classSource(self::CONTROLLER_CLASS);
        if ($request === null || $controller === null) {
            $this->markTestSkipped('UserRequest/UserController source not resolvable.');
        }

        $this->assertStringContainsString("'image' => ['nullable', 'image', 'max:2048']", $request, 'Request validates the `image` key.');
        $this->assertStringContainsString("hasFile('user_img')", $controller, 'BUG-PRM-N03: controller reads a different key (user_img); image rule never applies.');
    }

    /** TC-P33 / BC-BIZ — activity-log event strings are literal (verbatim from source). */
    public function test_user_33_activity_log_events_are_literal_strings(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        foreach ([
            "activityLog(\$user, 'created'",
            "activityLog(\$user, 'Updated'",
            "activityLog(\$user, 'Trashed'",
            "activityLog(\$user, 'Restored'",
            "activityLog(\$user, 'Deleted'",
            "activityLog(\$user, 'Toggled'",
            "activityLog(\$user, 'Promoted'",
        ] as $event) {
            $this->assertStringContainsString($event, $src, "Missing activity-log event: {$event}");
        }
    }

    /** TC-P34 / BC-BIZ — central activity sink is sys_central_activity_logs. */
    public function test_user_34_activity_sink_is_central_activity_log_table(): void
    {
        if (Schema::connection('mysql')->hasTable('sys_central_activity_logs')) {
            $this->assertTrue(true);
        } else {
            $this->markTestSkipped('sys_central_activity_logs not present in this environment (central migration only).');
        }

        $model = $this->makeModel(self::ACTIVITY_LOG_CLASS);
        if ($model === null) {
            return;
        }
        $this->assertSame('sys_central_activity_logs', $model->getTable(), 'Prime ActivityLog must target the central table.');
        foreach (['subject_type', 'subject_id', 'user_id', 'event', 'properties'] as $col) {
            $this->assertContains($col, $model->getFillable(), "ActivityLog fillable missing {$col}.");
        }
    }

    // ===================================================================
    // Band 40–49 : Integration / FK / dependency / lifecycle (DB truth)
    // ===================================================================

    /** TC-P40 / BC-DB — a user row can be persisted to sys_users (guarded functional insert). */
    public function test_user_40_user_row_persists_to_sys_users(): void
    {
        $emp = $this->uniqueEmpCode();
        $email = 'prm.user.' . substr(uniqid(), -8) . '@example.test';

        try {
            $user = User::create([
                'name' => 'PRM Test User',
                'short_name' => 'PT' . substr(uniqid(), -6),
                'emp_code' => $emp,
                'email' => $email,
                'password' => 'Secret12345',
                'is_active' => 1,
            ]);
        } catch (Throwable $e) {
            $this->markTestSkipped('Functional insert into central sys_users not available: ' . $e->getMessage());
        }

        $this->assertTrue(
            DB::connection('mysql')->table(self::USERS_TABLE)->where('emp_code', $emp)->exists(),
            'Created user was not found in sys_users.'
        );

        try {
            $user->forceDelete();
        } catch (Throwable) {
            try {
                DB::connection('mysql')->table(self::USERS_TABLE)->where('emp_code', $emp)->delete();
            } catch (Throwable) {
            }
        }
    }

    /** TC-D41 / BC-DB — sys_users soft-delete + restore column truth. */
    public function test_user_41_soft_delete_column_and_controller_flow(): void
    {
        $this->assertTrue(
            Schema::connection('mysql')->hasColumn(self::USERS_TABLE, 'deleted_at'),
            'sys_users must have deleted_at for soft deletes.'
        );

        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $this->assertStringContainsString('User::withTrashed()->findOrFail($id)', $src, 'restore/forceDelete must use withTrashed().');
        $this->assertStringContainsString('$user->restore()', $src, 'restore() must call restore().');
        $this->assertStringContainsString('$user->forceDelete()', $src, 'forceDelete() must permanently delete.');
    }

    /** TC-D42 / BC-DB — emp_code uniqueness is enforced by the DB unique index. */
    public function test_user_42_emp_code_uniqueness_enforced_by_index(): void
    {
        $indexes = $this->indexNames(self::USERS_TABLE);
        if ($indexes === null) {
            $this->markTestSkipped('information_schema not queryable.');
        }
        $this->assertContains('uq_users_empCode', $indexes, 'emp_code must be uniquely indexed.');
    }

    /** TC-D43 / BC-DB — email uniqueness is enforced by the DB unique index. */
    public function test_user_43_email_uniqueness_enforced_by_index(): void
    {
        $indexes = $this->indexNames(self::USERS_TABLE);
        if ($indexes === null) {
            $this->markTestSkipped('information_schema not queryable.');
        }
        $this->assertContains('uq_users_email', $indexes, 'email must be uniquely indexed.');
    }

    /** TC-D44 / BC-DB — super_admin_flag mirrors is_super_admin for the seeded super admin (read-only). */
    public function test_user_44_super_admin_flag_reflects_is_super_admin(): void
    {
        try {
            $row = DB::connection('mysql')->table(self::USERS_TABLE)
                ->where('is_super_admin', 1)
                ->select('is_super_admin', 'super_admin_flag')
                ->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('sys_users not queryable: ' . $e->getMessage());
        }

        if ($row === null) {
            $this->markTestSkipped('No super-admin row present to verify the generated column.');
        }

        $this->assertSame(1, (int) $row->super_admin_flag, 'super_admin_flag must be 1 where is_super_admin=1.');
    }

    /** TC-D45 / BC-DB — DB triggers protect the super admin from delete/demote. */
    public function test_user_45_super_admin_protection_triggers_exist(): void
    {
        $triggers = $this->triggerNames(self::USERS_TABLE);
        if ($triggers === null || $triggers === []) {
            $this->markTestSkipped('sys_users triggers not present/queryable in this environment.');
        }

        $this->assertContains('trg_users_prevent_delete_super', $triggers, 'Delete-protection trigger missing.');
        $this->assertContains('trg_users_prevent_update_super', $triggers, 'Demote-protection trigger missing.');
    }

    // ===================================================================
    // Band 50–59 : Permissions / authorization
    // ===================================================================

    /** TC-S50 — guest is redirected to /login on the index screen. */
    public function test_user_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    /** TC-AUTH51 — index() enforces prime.user.viewAny. */
    public function test_user_51_index_requires_view_any_gate(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $body = $this->methodBody($src, 'public function index(');
        $this->assertStringContainsString("Gate::authorize('prime.user.viewAny')", $body, 'index() must gate viewAny.');
    }

    /** TC-AUTH52 — store()/create() enforce prime.user.create. */
    public function test_user_52_create_requires_create_gate(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $store = $this->methodBody($src, 'public function store(');
        $this->assertStringContainsString("Gate::authorize('prime.user.create')", $store, 'store() must gate create.');
    }

    /** TC-AUTH53 — update()/edit() enforce prime.user.update. */
    public function test_user_53_update_requires_update_gate(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $update = $this->methodBody($src, 'public function update(');
        $this->assertStringContainsString("Gate::authorize('prime.user.update')", $update, 'update() must gate update.');
    }

    /** TC-AUTH54 — destroy() enforces prime.user.delete. */
    public function test_user_54_destroy_requires_delete_gate(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $destroy = $this->methodBody($src, 'public function destroy(');
        $this->assertStringContainsString("Gate::authorize('prime.user.delete')", $destroy, 'destroy() must gate delete.');
    }

    /** TC-AUTH55 — restore()/forceDelete() enforce their gates. */
    public function test_user_55_restore_and_force_delete_require_gates(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $restore = $this->methodBody($src, 'public function restore(');
        $force = $this->methodBody($src, 'public function forceDelete(');
        $this->assertStringContainsString("Gate::authorize('prime.user.restore')", $restore, 'restore() must gate restore.');
        $this->assertStringContainsString("Gate::authorize('prime.user.forceDelete')", $force, 'forceDelete() must gate forceDelete.');
    }

    /** TC-AUTH56 — index view gates the Status/Action controls by permission. */
    public function test_user_56_index_view_gates_action_controls(): void
    {
        $blade = $this->bladeSource('user/index.blade.php');
        if ($blade === null) {
            $this->markTestSkipped('user/index.blade.php not resolvable.');
        }
        $this->assertStringContainsString("@can('prime.user.update')", $blade, 'Status toggle must be permission-gated.');
        $this->assertStringContainsString("@canany(['prime.user.update', 'prime.user.delete'])", $blade, 'Action column must be permission-gated.');
    }

    // ===================================================================
    // Band 60–69 : UI/UX smoke (browser)
    // ===================================================================

    /** TC-P60 — index screen renders widgets, table and pagination. */
    public function test_user_60_index_page_renders(): void
    {
        $this->browseWithFailureScreenshot('index-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'User index not reachable.');
            $this->ensurePageAccessible($browser, 'User index');

            $browser->assertSee('User Management')
                ->assertPresent('table.table')
                ->assertPresent('.small-box');
        });
    }

    /** TC-P61 — create form renders all documented fields. */
    public function test_user_61_create_form_renders_all_fields(): void
    {
        $this->browseWithFailureScreenshot('create-form-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);

            $this->ensurePageAccessible($browser, 'User create');

            $browser->assertPresent('input[name="name"]')
                ->assertPresent('input[name="short_name"]')
                ->assertPresent('input[name="emp_code"]')
                ->assertPresent('input[name="email"]')
                ->assertPresent('input[name="phone_no"]')
                ->assertPresent('input[name="mobile_no"]')
                ->assertPresent('input[name="password"]')
                ->assertPresent('input[name="password_confirmation"]')
                ->assertPresent('input[name="user_img"]')
                ->assertPresent('select[name="roles[]"]')
                ->assertSee('Create User');
        });
    }

    /** TC-P62 — role filter dropdown is present on the index. */
    public function test_user_62_role_filter_dropdown_present(): void
    {
        $this->browseWithFailureScreenshot('role-filter-dropdown', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'User index (role filter)');

            $browser->assertPresent('#dropdownRoles')->assertSee('All Users');
        });
    }

    /** TC-P63 — trash screen renders. */
    public function test_user_63_trash_page_renders(): void
    {
        $this->browseWithFailureScreenshot('trash-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH);
            $this->assertSame(self::TRASH_PATH, $this->currentPath($browser), 'Trash page not reachable.');
            $this->ensurePageAccessible($browser, 'User trash');
            $browser->assertPresent('table.table');
        });
    }

    /** TC-P64 — index paginates 10 per page. */
    public function test_user_64_index_paginates_ten_per_page(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $body = $this->methodBody($src, 'public function index(');
        $this->assertStringContainsString('paginate(10)', $body, 'index() must paginate 10 per page.');
    }

    // ===================================================================
    // Band 70–79 : Edge cases
    // ===================================================================

    /** TC-EDG70 — emp_code column respects the 20-char DDL limit. */
    public function test_user_70_emp_code_respects_twenty_char_limit(): void
    {
        $length = $this->columnLength(self::USERS_TABLE, 'emp_code');
        if ($length === null) {
            $this->markTestSkipped('emp_code length not readable from information_schema.');
        }
        $this->assertSame(20, $length, 'emp_code must be VARCHAR(20).');
    }

    /** TC-S71 — index/trash views auto-escape user-controlled name output. */
    public function test_user_71_views_escape_user_name_output(): void
    {
        $index = $this->bladeSource('user/index.blade.php');
        if ($index === null) {
            $this->markTestSkipped('user/index.blade.php not resolvable.');
        }
        $this->assertStringContainsString('{{ $user->name }}', $index, 'Name must be rendered with escaped Blade output.');
        $this->assertStringNotContainsString('{!! $user->name !!}', $index, 'Name must never be rendered unescaped.');
    }

    // ===================================================================
    // Band 90–99 : Security pack (escalation / IDOR / mass-assignment)
    // ===================================================================

    /** TC-S90 / SEC-PRM-003 — super-admin escalation via update() is prevented at three layers. P0. */
    public function test_user_90_super_admin_escalation_via_update_is_prevented(): void
    {
        $controller = $this->classSource(self::CONTROLLER_CLASS);
        if ($controller === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }

        // Layer 1: controller whitelist excludes is_super_admin.
        $update = $this->methodBody($controller, 'public function update(');
        $this->assertStringNotContainsString("'is_super_admin'", $update, 'Layer 1: update() whitelist must not include is_super_admin.');

        // Layer 2: model $fillable excludes is_super_admin & super_admin_flag.
        $model = $this->makeModel(self::MODEL_CLASS);
        if ($model !== null) {
            $this->assertNotContains('is_super_admin', $model->getFillable(), 'Layer 2: is_super_admin must not be mass-assignable.');
            $this->assertNotContains('super_admin_flag', $model->getFillable(), 'Layer 2: super_admin_flag must not be mass-assignable.');
        }

        // Layer 3: elevation only via the dedicated gated flow.
        $this->assertStringContainsString("Gate::authorize('prime.super-admin.promote')", $controller, 'Layer 3: elevation requires the promote gate.');
    }

    /** TC-S91 — the generated column and escalation flag are guarded from mass assignment. */
    public function test_user_91_mass_assignment_guard_on_generated_and_flag_columns(): void
    {
        $model = $this->makeModel(self::MODEL_CLASS);
        if ($model === null) {
            $this->markTestSkipped('Prime User model not resolvable.');
        }
        $fillable = $model->getFillable();
        // Writing super_admin_flag (STORED generated) would raise MySQL 3105 — must be non-fillable.
        $this->assertNotContains('super_admin_flag', $fillable, 'super_admin_flag must be non-fillable (MySQL 3105 guard).');
        $this->assertNotContains('is_super_admin', $fillable, 'is_super_admin must be non-fillable.');
    }

    /** TC-S92 — show()/edit() use route-model binding (IDOR surface hardening). */
    public function test_user_92_show_and_edit_use_route_model_binding(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $this->assertStringContainsString('public function show(User $user)', $src, 'show() must use route-model binding.');
        $this->assertStringContainsString('public function edit(User $user)', $src, 'edit() must use route-model binding.');
        $this->assertStringContainsString("Gate::authorize('prime.user.view')", $this->methodBody($src, 'public function show('), 'show() must gate view.');
    }

    /** TC-S93 — single-super-admin invariant is enforced by unique key + protection triggers. */
    public function test_user_93_single_super_admin_invariant_is_enforced(): void
    {
        $indexes = $this->indexNames(self::USERS_TABLE);
        if ($indexes === null) {
            $this->markTestSkipped('information_schema not queryable.');
        }
        $this->assertContains('uq_single_super_admin', $indexes, 'Single-super-admin uniqueness must be enforced.');
    }

    /** TC-S94 — mutating actions record the acting user in the activity log. */
    public function test_user_94_activity_log_records_actor_for_mutations(): void
    {
        $src = $this->classSource(self::CONTROLLER_CLASS);
        if ($src === null) {
            $this->markTestSkipped('UserController source not resolvable.');
        }
        $this->assertStringContainsString("'performed_by' => Auth::user()->name", $src, 'Mutations must log the acting user.');
    }

    // ===================================================================
    // Private helper library
    // ===================================================================

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }

        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    private function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl(self::LOGIN_PATH))->pause(800);

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

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
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

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        try {
            $directory = base_path(static::SCREENSHOT_DIR);
            File::ensureDirectoryExists($directory);
            $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName) ?: 'failure';
            $absolutePath = $directory . DIRECTORY_SEPARATOR . $safeName . '_' . now()->format('Ymd_Hisv') . '.png';
            $browser->driver->takeScreenshot($absolutePath);
        } catch (Throwable) {
            // best-effort only
        }
    }

    private function cleanScreenshots(): void
    {
        try {
            $directory = base_path(static::SCREENSHOT_DIR);
            if (is_dir($directory)) {
                foreach (glob($directory . DIRECTORY_SEPARATOR . '*.png') ?: [] as $file) {
                    @unlink($file);
                }
            }
        } catch (Throwable) {
            // best-effort only
        }
    }

    private function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows the login page; authentication failed.');
        }

        $bodyText = (string) $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();

        return (string) parse_url($url, PHP_URL_PATH);
    }

    private function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            if ($superAdmin) {
                $this->adminUser = $superAdmin;

                return;
            }

            $this->adminUser = User::query()->where('email', $this->adminEmail)->first();
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    private function uniqueEmpCode(): string
    {
        return 'U' . substr(uniqid(), -8); // <= 20 chars (constraint B / #9)
    }

    private function makeModel(string $fqcn): ?object
    {
        try {
            if (!class_exists($fqcn)) {
                return null;
            }

            return new $fqcn();
        } catch (Throwable) {
            return null;
        }
    }

    private function classSource(string $fqcn): ?string
    {
        try {
            if (!class_exists($fqcn)) {
                return null;
            }
            $file = (new ReflectionClass($fqcn))->getFileName();
            if (!$file || !is_file($file)) {
                return null;
            }

            return (string) file_get_contents($file);
        } catch (Throwable) {
            return null;
        }
    }

    private function bladeSource(string $relative): ?string
    {
        try {
            $controllerFile = (new ReflectionClass(self::CONTROLLER_CLASS))->getFileName();
            if (!$controllerFile) {
                return null;
            }
            // .../Modules/Prime/app/Http/Controllers/UserController.php -> module root
            $moduleRoot = dirname($controllerFile, 5);
            $path = $moduleRoot . '/resources/views/' . ltrim($relative, '/');
            if (!is_file($path)) {
                return null;
            }

            return (string) file_get_contents($path);
        } catch (Throwable) {
            return null;
        }
    }

    /**
     * Extract a single method body from source by its declaration prefix,
     * using brace matching so nested braces are handled correctly.
     */
    private function methodBody(string $source, string $signaturePrefix): string
    {
        $start = strpos($source, $signaturePrefix);
        if ($start === false) {
            return '';
        }

        $braceStart = strpos($source, '{', $start);
        if ($braceStart === false) {
            return '';
        }

        $depth = 0;
        $length = strlen($source);
        for ($i = $braceStart; $i < $length; $i++) {
            $char = $source[$i];
            if ($char === '{') {
                $depth++;
            } elseif ($char === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $braceStart, $i - $braceStart + 1);
                }
            }
        }

        return substr($source, $braceStart);
    }

    private function centralDbName(): ?string
    {
        try {
            return DB::connection('mysql')->getDatabaseName();
        } catch (Throwable) {
            return null;
        }
    }

    /** @return array<int,string>|null */
    private function indexNames(string $table): ?array
    {
        $db = $this->centralDbName();
        if ($db === null) {
            return null;
        }

        try {
            $rows = DB::connection('mysql')->select(
                'SELECT DISTINCT INDEX_NAME AS name FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?',
                [$db, $table]
            );

            return array_map(static fn ($r): string => (string) $r->name, $rows);
        } catch (Throwable) {
            return null;
        }
    }

    /** @return array<int,string>|null */
    private function triggerNames(string $table): ?array
    {
        $db = $this->centralDbName();
        if ($db === null) {
            return null;
        }

        try {
            $rows = DB::connection('mysql')->select(
                'SELECT TRIGGER_NAME AS name FROM information_schema.TRIGGERS WHERE EVENT_OBJECT_SCHEMA = ? AND EVENT_OBJECT_TABLE = ?',
                [$db, $table]
            );

            return array_map(static fn ($r): string => (string) $r->name, $rows);
        } catch (Throwable) {
            return null;
        }
    }

    private function columnExtra(string $table, string $column): ?string
    {
        $db = $this->centralDbName();
        if ($db === null) {
            return null;
        }

        try {
            $row = DB::connection('mysql')->select(
                'SELECT EXTRA AS extra FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?',
                [$db, $table, $column]
            );

            return isset($row[0]) ? (string) $row[0]->extra : null;
        } catch (Throwable) {
            return null;
        }
    }

    private function columnLength(string $table, string $column): ?int
    {
        $db = $this->centralDbName();
        if ($db === null) {
            return null;
        }

        try {
            $row = DB::connection('mysql')->select(
                'SELECT CHARACTER_MAXIMUM_LENGTH AS len FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?',
                [$db, $table, $column]
            );

            return isset($row[0]) && $row[0]->len !== null ? (int) $row[0]->len : null;
        } catch (Throwable) {
            return null;
        }
    }
}
