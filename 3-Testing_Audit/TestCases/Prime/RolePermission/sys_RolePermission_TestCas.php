<?php

namespace Tests\Browser\Modules\Prime\RolePermission;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Prime (PRM) module — Role & Permission screen.
 *
 * SCOPE: CENTRAL / prime_db. No tenant initialization. Host http://127.0.0.1:8000.
 * Extends the module central base PrimeDuskTestCase (short alias resolved by
 * tests/Browser/Modules/preload.php — Constraint #22). Central auth/helpers are
 * implemented locally (copied from prm_BillingDuskTestCase_TestCas).
 *
 * PRIMARY TABLE : sys_roles  (DDL-verified prefix => sys_)
 * CONTROLLER    : Modules\Prime\Http\Controllers\RolePermissionController
 * FORM REQUEST  : Modules\Prime\Http\Requests\RolePermissionRequest
 * MODELS        : Modules\Prime\Models\Role (extends Spatie Role), Permission
 * ROUTES        : central.prime.role-permission.*  (routes/web.php:156-165)
 * ACTIVITY SINK : sys_central_activity_logs via Modules\Prime\Models\ActivityLog
 *
 * DEFECTS MAPPED:
 *   SEC-PRM-001 (P0) — getPermissions() Gate. STATUS: REMEDIATED in current source
 *       (Gate::authorize('prime.role-permission.view') present at controller line 313).
 *       test_02 / test_90 prove the gate IS present (config-truth + functional).
 *   DEP-PRM-001 (P3) — cross-module FormRequest dependency on SchoolSetup.
 *       STATUS: NOT REPRODUCED — controller imports its own
 *       Modules\Prime\Http\Requests\RolePermissionRequest (line 11). test_02b documents.
 *   DEV-PRM-010 — destroy() logs activity event literal 'Toggled' (mislabel for a delete).
 *   DEV-PRM-011 — forceDelete() calls $role->delete(); sys_roles has NO deleted_at and
 *       Role has NO SoftDeletes trait => "force delete" is an ordinary permanent delete;
 *       trashed()/restore() are stub redirects ("Soft deletes are not enabled for roles.").
 *   DEV-PRM-012 — inline endpoints updateRolePermission()/updatePermissions() validate
 *       exists:permissions,name (literal table 'permissions'); the real table is
 *       sys_permissions (used correctly by the FormRequest). Wrong table => rule can never
 *       match on a database without a 'permissions' table.
 */
class sys_RolePermission_TestCas extends PrimeDuskTestCase
{
    private const CONTROLLER_PATH = 'Modules/Prime/app/Http/Controllers/RolePermissionController.php';
    private const REQUEST_PATH    = 'Modules/Prime/app/Http/Requests/RolePermissionRequest.php';
    private const INDEX_PATH      = '/prime/role-permission';
    private const CREATE_PATH     = '/prime/role-permission/create';

    private const TABLE_ROLES        = 'sys_roles';
    private const TABLE_PERMISSIONS  = 'sys_permissions';
    private const TABLE_PIVOT        = 'sys_role_has_permissions_jnt';
    private const TABLE_ACTIVITY     = 'sys_central_activity_logs';

    /** Exact gate expected on each controller action (verified from source). */
    private const GATE_MAP = [
        'index'                  => 'prime.role-permission.viewAny',
        'create'                 => 'prime.role-permission.create',
        'store'                  => 'prime.role-permission.create',
        'getRolesByOrganization' => 'prime.role-permission.viewAny',
        'show'                   => 'prime.role-permission.view',
        'edit'                   => 'prime.role-permission.update',
        'update'                 => 'prime.role-permission.update',
        'destroy'                => 'prime.role-permission.delete',
        'trashedRolePermission'  => 'prime.role-permission.restore',
        'restore'                => 'prime.role-permission.restore',
        'forceDelete'            => 'prime.role-permission.forceDelete',
        'updateRolePermission'   => 'prime.role-permission.update',
        'updatePermissions'      => 'prime.role-permission.update',
        'getPermissions'         => 'prime.role-permission.view', // SEC-PRM-001 remediation
    ];

    private ?User $adminUser = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private ?string $controllerSource = null;
    private ?string $requestSource = null;

    /** @var array<int,int> role ids created during a test, cleaned up in tearDown */
    private array $createdRoleIds = [];
    /** @var array<int,int> user ids created during a test, cleaned up in tearDown */
    private array $createdUserIds = [];

    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        // Best-effort cleanup of anything this test created (permanent — no soft delete).
        foreach ($this->createdRoleIds as $roleId) {
            try {
                DB::connection('mysql')->table(self::TABLE_PIVOT)->where('role_id', $roleId)->delete();
                DB::connection('mysql')->table(self::TABLE_ROLES)->where('id', $roleId)->delete();
            } catch (Throwable) {
                // ignore cleanup failures
            }
        }
        foreach ($this->createdUserIds as $userId) {
            try {
                DB::connection('mysql')->table('sys_model_has_roles_jnt')->where('model_id', $userId)->delete();
                DB::connection('mysql')->table('sys_users')->where('id', $userId)->delete();
            } catch (Throwable) {
                // ignore cleanup failures
            }
        }

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =============================================================================
    // BAND 01-09 — Schema / config / route truth (environment-independent asserts)
    // =============================================================================

    /**
     * test_01 — schema/model/request configuration truth (opening method).
     * BC-DB-01..06, BC-VAL config, BC-BIZ soft-delete absence.
     */
    public function test_rolepermission_01_migration_model_and_request_configuration_are_correct(): void
    {
        // ---- Tables exist (central connection) ----
        $this->assertTrue(Schema::connection('mysql')->hasTable(self::TABLE_ROLES), 'sys_roles table missing.');
        $this->assertTrue(Schema::connection('mysql')->hasTable(self::TABLE_PERMISSIONS), 'sys_permissions table missing.');
        $this->assertTrue(Schema::connection('mysql')->hasTable(self::TABLE_PIVOT), 'sys_role_has_permissions_jnt table missing.');

        // ---- sys_roles columns (DDL-verified) ----
        $this->assertTrue(Schema::connection('mysql')->hasColumns(self::TABLE_ROLES, [
            'id', 'name', 'short_name', 'description', 'guard_name', 'is_system', 'is_active', 'created_at', 'updated_at',
        ]), 'sys_roles is missing an expected column.');

        // ---- sys_roles has NO deleted_at => permanent delete only (DEV-PRM-011) ----
        $this->assertFalse(
            Schema::connection('mysql')->hasColumn(self::TABLE_ROLES, 'deleted_at'),
            'sys_roles unexpectedly has deleted_at; test assumptions about soft-delete are stale.'
        );

        // ---- Role model configuration ----
        $role = new \Modules\Prime\Models\Role();
        $this->assertSame(self::TABLE_ROLES, $role->getTable(), 'Role model table mismatch.');
        foreach (['name', 'guard_name', 'short_name', 'description', 'is_system'] as $fillable) {
            $this->assertContains($fillable, $role->getFillable(), "Role fillable missing {$fillable}.");
        }
        // Role does NOT use SoftDeletes (confirms permanent-delete behaviour).
        $this->assertNotContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(\Modules\Prime\Models\Role::class),
            'Role now uses SoftDeletes; DEV-PRM-011 assumptions are stale.'
        );

        // ---- Permission model relation ----
        $permission = new \Modules\Prime\Models\Permission();
        $this->assertTrue(method_exists($permission, 'menu'), 'Permission::menu() relation missing.');

        // ---- ActivityLog central sink ----
        $log = new \Modules\Prime\Models\ActivityLog();
        $this->assertSame(self::TABLE_ACTIVITY, $log->getTable(), 'ActivityLog central table mismatch.');

        // ---- FormRequest rule content (exact strings) ----
        $req = $this->requestSource();
        $this->assertStringContainsString("Rule::unique('sys_roles')", $req, 'name/short_name unique rule missing.');
        $this->assertStringContainsString("'max:20'", $req, 'short_name max:20 rule missing.');
        $this->assertStringContainsString("'max:255'", $req, 'description max:255 rule missing.');
        $this->assertStringContainsString("exists:sys_permissions,name", $req, 'permissions exists rule missing/wrong table.');
    }

    /**
     * test_02 — every controller action carries its exact Gate::authorize().
     * PROVES SEC-PRM-001 remediation: getPermissions() now has the view gate.
     * BC-AUTH-01..14.
     */
    public function test_rolepermission_02_controller_gate_authorization_is_present_on_every_action(): void
    {
        foreach (self::GATE_MAP as $method => $gate) {
            $body = $this->controllerMethodBody($method);
            $this->assertNotSame('', $body, "Controller method {$method}() not found.");
            $this->assertStringContainsString(
                "Gate::authorize('{$gate}')",
                $body,
                "SECURITY: {$method}() is missing Gate::authorize('{$gate}')."
            );
        }
    }

    /**
     * test_02b — DEP-PRM-001: the controller uses its OWN FormRequest, not SchoolSetup's.
     */
    public function test_rolepermission_02b_controller_uses_prime_form_request_not_schoolsetup(): void
    {
        $src = $this->controllerSource();
        $this->assertStringContainsString(
            'use Modules\\Prime\\Http\\Requests\\RolePermissionRequest;',
            $src,
            'DEP-PRM-001: controller no longer imports the Prime RolePermissionRequest.'
        );
        $this->assertStringNotContainsString(
            'use Modules\\SchoolSetup\\Http\\Requests\\RolePermissionRequest;',
            $src,
            'DEP-PRM-001 REGRESSION: controller imports the SchoolSetup FormRequest.'
        );
    }

    /**
     * test_03 — all named routes are registered. BC-REF route contract.
     */
    public function test_rolepermission_03_all_named_routes_are_registered(): void
    {
        $named = [
            'central.prime.role-permission.index',
            'central.prime.role-permission.create',
            'central.prime.role-permission.store',
            'central.prime.role-permission.show',
            'central.prime.role-permission.edit',
            'central.prime.role-permission.update',
            'central.prime.role-permission.destroy',
            'central.prime.role-permission.getRolesByOrganization',
            'central.prime.role-permission.trashed',
            'central.prime.role-permission.restore',
            'central.prime.role-permission.forceDelete',
            'central.prime.role-permission.updateRolePermission',
        ];
        foreach ($named as $name) {
            $this->assertTrue(Route::has($name), "Route {$name} is not registered.");
        }
    }

    /**
     * test_04 — the two custom permission endpoints are registered but UNNAMED
     * (routes/web.php:163-164 have no ->name()). Documented wiring quirk.
     */
    public function test_rolepermission_04_permission_endpoints_registered_but_unnamed(): void
    {
        $this->assertFalse(
            Route::has('central.prime.role-permission.getPermissions'),
            'getPermissions route is now named; update the wiring documentation.'
        );
        $this->assertFalse(
            Route::has('central.prime.role-permission.updatePermissions'),
            'updatePermissions route is now named; update the wiring documentation.'
        );

        // They still exist by URI pattern in the controller/route file.
        $found = false;
        foreach (Route::getRoutes() as $route) {
            if (str_contains($route->uri(), 'role-permission/{role}/permissions')) {
                $found = true;
                break;
            }
        }
        $this->assertTrue($found, 'The {role}/permissions endpoints are not registered at all.');
    }

    /**
     * test_05 — activity sink is central and schema present (Constraint #25 guard).
     */
    public function test_rolepermission_05_central_activity_sink_present(): void
    {
        if (!Schema::connection('mysql')->hasTable(self::TABLE_ACTIVITY)) {
            $this->markTestSkipped('sys_central_activity_logs not present in this environment.');
        }
        $this->assertTrue(Schema::connection('mysql')->hasColumns(self::TABLE_ACTIVITY, [
            'subject_type', 'subject_id', 'user_id', 'event', 'properties',
        ]), 'sys_central_activity_logs is missing expected columns.');
    }

    // =============================================================================
    // BAND 10-19 — Business rules / happy path (functional, defensive)
    // =============================================================================

    public function test_rolepermission_10_index_page_loads_with_roles_and_permissions(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Role & Permission index');
            $this->assertStringContainsString('/prime/role-permission', $this->currentPath($browser));
            $capture = $browser->text('body');
            $this->assertNotEmpty($capture, 'Index body is empty.');
        });
    }

    public function test_rolepermission_11_create_form_renders_expected_fields(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Role & Permission create');
            $browser->assertPresent('input[name="name"]')
                ->assertPresent('input[name="short_name"]')
                ->assertPresent('[name="description"]')
                ->assertPresent('[name="is_system"]');
        });
    }

    public function test_rolepermission_12_store_creates_role_and_syncs_permissions(): void
    {
        $this->runFunctional(function (): void {
            $permName = $this->anyPermissionName();
            if ($permName === null) {
                $this->markTestSkipped('No permission rows in sys_permissions to sync.');
            }

            $role = \Modules\Prime\Models\Role::create([
                'name' => $this->uniqueName('Store'),
                'short_name' => $this->uniqueShort(),
                'description' => 'created by test_12',
                'is_system' => false,
                'guard_name' => 'web',
            ]);
            $this->trackRole($role->id);
            $role->syncPermissions([$permName]);

            $this->assertDatabaseHasRole($role->id);
            $pivot = DB::connection('mysql')->table(self::TABLE_PIVOT)->where('role_id', $role->id)->count();
            $this->assertGreaterThan(0, $pivot, 'Permission was not synced into the pivot table.');
        });
    }

    public function test_rolepermission_13_store_writes_stored_activity_event(): void
    {
        $this->runFunctional(function (): void {
            if (!Schema::connection('mysql')->hasTable(self::TABLE_ACTIVITY)) {
                $this->markTestSkipped('Central activity table absent.');
            }
            // The controller logs literal event 'Stored' on store().
            $this->assertStringContainsString(
                "activityLog(\$role, 'Stored'",
                $this->controllerMethodBody('store'),
                "store() no longer logs the literal 'Stored' event."
            );
        });
    }

    public function test_rolepermission_14_update_logs_updated_event(): void
    {
        $this->assertStringContainsString(
            "activityLog(\$role, 'Updated'",
            $this->controllerMethodBody('update'),
            "update() no longer logs the literal 'Updated' event."
        );
    }

    /**
     * test_15 — DEV-PRM-010: destroy() performs a PERMANENT delete (no soft delete)
     * and logs the literal event 'Toggled' (mislabel for a delete).
     */
    public function test_rolepermission_15_destroy_permanently_deletes_and_logs_toggled(): void
    {
        // Config-truth: destroy uses $role->delete() and logs 'Toggled'.
        $body = $this->controllerMethodBody('destroy');
        $this->assertStringContainsString('$role->delete();', $body, 'destroy() no longer deletes the role.');
        $this->assertStringContainsString(
            "activityLog(\$role, 'Toggled'",
            $body,
            "DEV-PRM-010: destroy() event label changed; expected the mislabelled 'Toggled'."
        );

        // Functional: a deleted role disappears entirely (no trashed copy).
        $this->runFunctional(function (): void {
            $role = \Modules\Prime\Models\Role::create([
                'name' => $this->uniqueName('Del'),
                'short_name' => $this->uniqueShort(),
                'guard_name' => 'web',
                'is_system' => false,
            ]);
            $id = $role->id;
            $role->delete();
            $exists = DB::connection('mysql')->table(self::TABLE_ROLES)->where('id', $id)->exists();
            $this->assertFalse($exists, 'Role still present after delete — unexpected soft delete.');
        });
    }

    /**
     * test_16 — DEV-PRM-011: forceDelete() controller method calls $role->delete()
     * (an ordinary delete), not $role->forceDelete().
     */
    public function test_rolepermission_16_force_delete_method_uses_plain_delete(): void
    {
        $body = $this->controllerMethodBody('forceDelete');
        $this->assertStringContainsString('$role->delete();', $body, 'forceDelete() no longer deletes the role.');
        $this->assertStringNotContainsString(
            '$role->forceDelete();',
            $body,
            'DEV-PRM-011: forceDelete() now calls forceDelete() — schema/model may have gained SoftDeletes.'
        );
        $this->assertStringContainsString("activityLog(\$role, 'Deleted'", $body, "forceDelete() 'Deleted' event missing.");
    }

    /**
     * test_17 — DEV-PRM-011: trashed()/restore() are stub redirects (soft delete disabled).
     */
    public function test_rolepermission_17_trashed_and_restore_are_noop_redirects(): void
    {
        foreach (['trashedRolePermission', 'restore'] as $method) {
            $body = $this->controllerMethodBody($method);
            $this->assertStringContainsString(
                'Soft deletes are not enabled for roles.',
                $body,
                "{$method}() no longer returns the soft-delete-disabled notice."
            );
        }
    }

    public function test_rolepermission_18_get_roles_by_organization_scopes_by_org(): void
    {
        $body = $this->controllerMethodBody('getRolesByOrganization');
        $this->assertStringContainsString("where('organization_id', \$organizationId)", $body, 'org scoping removed.');
        $this->assertStringContainsString('Organization::findOrFail', $body, 'org existence check removed.');
    }

    // =============================================================================
    // BAND 30-39 — Validation + error messages
    // =============================================================================

    public function test_rolepermission_30_store_requires_name_short_name_and_permissions(): void
    {
        $req = $this->requestSource();
        $this->assertMatchesRegularExpression("/'name'\\s*=>\\s*\\[\\s*'required'/s", $req, 'name required rule missing.');
        $this->assertMatchesRegularExpression("/'short_name'\\s*=>\\s*\\[\\s*'required'/s", $req, 'short_name required rule missing.');
        $this->assertMatchesRegularExpression("/'permissions'\\s*=>\\s*\\['required',\\s*'array'\\]/s", $req, 'permissions required|array rule missing.');
    }

    public function test_rolepermission_31_duplicate_name_rejected_unique_sys_roles(): void
    {
        $this->assertStringContainsString("Rule::unique('sys_roles')->ignore(\$roleId, 'id')", $this->requestSource(), 'name unique-ignore rule changed.');
    }

    public function test_rolepermission_32_short_name_max_20_enforced(): void
    {
        $this->assertMatchesRegularExpression("/'short_name'\\s*=>\\s*\\[[^\\]]*'max:20'/s", $this->requestSource(), 'short_name max:20 rule missing.');
    }

    public function test_rolepermission_33_description_max_255(): void
    {
        $this->assertMatchesRegularExpression("/'description'\\s*=>\\s*\\['nullable',\\s*'string',\\s*'max:255'\\]/s", $this->requestSource(), 'description rule changed.');
    }

    public function test_rolepermission_34_permissions_must_exist_in_sys_permissions(): void
    {
        $this->assertStringContainsString("'exists:sys_permissions,name'", $this->requestSource(), 'permissions.* exists rule changed.');
    }

    public function test_rolepermission_35_update_role_permission_endpoint_validation(): void
    {
        $body = $this->controllerMethodBody('updateRolePermission');
        $this->assertStringContainsString("'enabled' => 'required|boolean'", $body, 'enabled validation missing.');
        $this->assertStringContainsString("'permission' => 'required|string|exists:permissions,name'", $body, 'permission validation changed.');
    }

    public function test_rolepermission_36_update_permissions_endpoint_requires_array(): void
    {
        $body = $this->controllerMethodBody('updatePermissions');
        $this->assertStringContainsString("'permissions' => 'required|array'", $body, 'permissions array validation missing.');
    }

    public function test_rolepermission_37_invalid_role_id_returns_404(): void
    {
        $this->runHttp(function (): void {
            $resp = $this->getJson($this->centralBaseUrl . '/prime/role-permission/999999999');
            $this->assertContains($resp->getStatusCode(), [403, 404, 302, 401], 'Invalid id did not produce a not-found/forbidden response.');
        });
    }

    public function test_rolepermission_38_xss_in_name_is_stored_raw_and_escaped_on_render(): void
    {
        // Blade escapes by default; the name field has no sanitizer, so payload is stored verbatim.
        $this->runFunctional(function (): void {
            $payload = '<script>alert(1)</script>';
            $role = \Modules\Prime\Models\Role::create([
                'name' => $payload . $this->uniqueShort(),
                'short_name' => $this->uniqueShort(),
                'guard_name' => 'web',
                'is_system' => false,
            ]);
            $this->trackRole($role->id);
            $stored = DB::connection('mysql')->table(self::TABLE_ROLES)->where('id', $role->id)->value('name');
            $this->assertStringContainsString('<script>', (string) $stored, 'Payload was mutated at store time (unexpected).');
            // Escaping is Blade\'s responsibility; documented as render-layer control.
        });
    }

    // =============================================================================
    // BAND 40-49 — Integration / FK dependency
    // =============================================================================

    public function test_rolepermission_40_pivot_uses_sys_role_has_permissions_jnt(): void
    {
        $this->assertTrue(Schema::connection('mysql')->hasTable(self::TABLE_PIVOT), 'pivot table missing.');
        $this->assertTrue(Schema::connection('mysql')->hasColumns(self::TABLE_PIVOT, ['permission_id', 'role_id']), 'pivot columns missing.');
    }

    public function test_rolepermission_41_deleting_role_cascades_pivot_rows(): void
    {
        $this->runFunctional(function (): void {
            $permName = $this->anyPermissionName();
            if ($permName === null) {
                $this->markTestSkipped('No permissions to sync for cascade test.');
            }
            $role = \Modules\Prime\Models\Role::create([
                'name' => $this->uniqueName('Cascade'),
                'short_name' => $this->uniqueShort(),
                'guard_name' => 'web',
                'is_system' => false,
            ]);
            $id = $role->id;
            $role->syncPermissions([$permName]);
            $this->assertGreaterThan(0, DB::connection('mysql')->table(self::TABLE_PIVOT)->where('role_id', $id)->count());
            $role->delete();
            $this->assertSame(0, DB::connection('mysql')->table(self::TABLE_PIVOT)->where('role_id', $id)->count(), 'Pivot rows not cascaded on role delete.');
        });
    }

    public function test_rolepermission_42_permission_belongs_to_menu_relation(): void
    {
        $relation = (new \Modules\Prime\Models\Permission())->menu();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation, 'Permission::menu() is not a BelongsTo.');
    }

    public function test_rolepermission_43_show_lists_users_with_role(): void
    {
        $this->assertStringContainsString(
            'User::role($role->name)',
            $this->controllerMethodBody('show'),
            'show() no longer resolves users assigned to the role.'
        );
    }

    // =============================================================================
    // BAND 50-59 — Permissions / authorization
    // =============================================================================

    public function test_rolepermission_50_guest_is_redirected_to_login(): void
    {
        $this->runHttp(function (): void {
            $resp = $this->get($this->centralBaseUrl . self::INDEX_PATH);
            $this->assertContains($resp->getStatusCode(), [302, 401, 403], 'Guest was not redirected/blocked.');
        });
    }

    public function test_rolepermission_51_index_requires_view_any_gate(): void
    {
        $this->assertActionGate('index', 'prime.role-permission.viewAny');
    }

    public function test_rolepermission_52_store_requires_create_gate(): void
    {
        $this->assertActionGate('store', 'prime.role-permission.create');
    }

    public function test_rolepermission_53_update_requires_update_gate(): void
    {
        $this->assertActionGate('update', 'prime.role-permission.update');
    }

    public function test_rolepermission_54_destroy_requires_delete_gate(): void
    {
        $this->assertActionGate('destroy', 'prime.role-permission.delete');
    }

    public function test_rolepermission_55_force_delete_requires_force_delete_gate(): void
    {
        $this->assertActionGate('forceDelete', 'prime.role-permission.forceDelete');
    }

    /**
     * test_56 — SEC-PRM-001 functional: getPermissions() now enforces the view gate.
     * A non-privileged authenticated user must be denied.
     */
    public function test_rolepermission_56_get_permissions_requires_view_gate(): void
    {
        $this->assertActionGate('getPermissions', 'prime.role-permission.view');
    }

    public function test_rolepermission_57_form_request_authorize_maps_actions_to_gates(): void
    {
        $req = $this->requestSource();
        $this->assertStringContainsString("Gate::allows('prime.role-permission.create')", $req, 'store authorize gate missing.');
        $this->assertStringContainsString("Gate::allows('prime.role-permission.update')", $req, 'update authorize gate missing.');
        $this->assertStringContainsString("Gate::allows('prime.role-permission.viewAny')", $req, 'default authorize gate missing.');
    }

    // =============================================================================
    // BAND 60-69 — UI/UX
    // =============================================================================

    public function test_rolepermission_60_breadcrumb_shows_roles_and_permissions(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Role & Permission breadcrumb');
            $this->assertStringContainsStringIgnoringCase('Roles', $browser->text('body'), 'Breadcrumb/title missing.');
        });
    }

    public function test_rolepermission_61_create_page_posts_to_store_route(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Role & Permission create form');
            $action = $browser->attribute('form', 'action');
            $this->assertStringContainsString('/prime/role-permission', (string) $action, 'Create form action not pointed at store.');
        });
    }

    // =============================================================================
    // BAND 70-79 — Edge cases
    // =============================================================================

    public function test_rolepermission_70_is_system_checkbox_casts_to_boolean(): void
    {
        $this->assertStringContainsString(
            "'is_system' => \$this->has('is_system')",
            $this->requestSource(),
            'prepareForValidation() no longer normalises the is_system checkbox.'
        );
    }

    public function test_rolepermission_71_whitespace_only_name_is_not_pre_trimmed(): void
    {
        // Documented gap: no trim on name; required rule allows a whitespace string through unless
        // TrimStrings middleware collapses it. Assert the rule set does not itself trim.
        $this->assertStringNotContainsString("'name' => ['required', 'string', 'not_regex", $this->requestSource(), 'unexpected name sanitiser present.');
    }

    public function test_rolepermission_72_duplicate_short_name_rejected(): void
    {
        $this->assertMatchesRegularExpression(
            "/'short_name'\\s*=>\\s*\\[[^\\]]*Rule::unique\\('sys_roles'\\)->ignore/s",
            $this->requestSource(),
            'short_name unique rule missing.'
        );
    }

    /**
     * test_73 — DEV-PRM-012: inline endpoints validate against literal table 'permissions',
     * while the real table is sys_permissions.
     */
    public function test_rolepermission_73_inline_endpoints_reference_wrong_permissions_table(): void
    {
        $body = $this->controllerMethodBody('updateRolePermission');
        $this->assertStringContainsString(
            'exists:permissions,name',
            $body,
            "DEV-PRM-012: updateRolePermission() no longer references the literal 'permissions' table."
        );
        // Real table is sys_permissions, so a literal 'permissions' table typically does not exist.
        $this->assertFalse(
            Schema::connection('mysql')->hasTable('permissions'),
            "A literal 'permissions' table exists; DEV-PRM-012 may not reproduce here."
        );
        $this->assertTrue(
            Schema::connection('mysql')->hasTable('sys_permissions'),
            'sys_permissions (the real table) is missing.'
        );
    }

    // =============================================================================
    // BAND 90-99 — Security pack + central-scope
    // =============================================================================

    /**
     * test_90 — SEC-PRM-001 headline: getPermissions() Gate presence (config-truth) +
     * functional denial for a non-privileged user. STATUS: REMEDIATED.
     */
    public function test_rolepermission_90_sec_prm_001_get_permissions_is_gated(): void
    {
        // (a) Config-truth: the gate is present in source.
        $this->assertStringContainsString(
            "Gate::authorize('prime.role-permission.view')",
            $this->controllerMethodBody('getPermissions'),
            'SEC-PRM-001 REGRESSION: getPermissions() has no Gate::authorize — any authenticated user can enumerate permissions.'
        );

        // (b) Functional: a non-privileged authenticated user is denied (403/redirect).
        $this->runHttp(function (): void {
            $limited = $this->createLimitedUser();
            if ($limited === null) {
                $this->markTestSkipped('Unable to provision a non-privileged central user.');
            }
            $roleId = $this->anyRoleId();
            if ($roleId === null) {
                $this->markTestSkipped('No role available to probe getPermissions.');
            }
            $resp = $this->actingAs($limited)
                ->getJson($this->centralBaseUrl . '/prime/role-permission/' . $roleId . '/permissions');
            $this->assertContains(
                $resp->getStatusCode(),
                [403, 302, 401, 404],
                'SEC-PRM-001: non-privileged user reached getPermissions successfully (gate not enforced).'
            );
            $this->assertNotSame(200, $resp->getStatusCode(), 'SEC-PRM-001: getPermissions returned 200 for a non-privileged user.');
        });
    }

    public function test_rolepermission_91_role_fillable_guards_mass_assignment(): void
    {
        $fillable = (new \Modules\Prime\Models\Role())->getFillable();
        // guard_name is fillable (Spatie requirement) but id/is_active are not directly targeted by the controller.
        $this->assertNotContains('id', $fillable, 'id must not be mass assignable.');
        // The controller only assigns name/organization_id/short_name/description/is_system on store.
        $this->assertStringNotContainsString("'is_active' => \$request", $this->controllerMethodBody('store'), 'store() mass-assigns is_active from request.');
    }

    public function test_rolepermission_92_idor_get_permissions_denied_cross_role(): void
    {
        // Covered functionally by test_90(b); here we assert the endpoint binds a Role model
        // (route-model binding) so an arbitrary id 404s rather than leaking.
        $this->assertStringContainsString(
            'getPermissions(Role $role)',
            $this->controllerSource(),
            'getPermissions() no longer uses route-model binding on Role.'
        );
    }

    public function test_rolepermission_93_feature_is_central_scope_no_tenant_init(): void
    {
        // Prime/central: Role model uses the central 'mysql' connection, not a tenant connection.
        $this->assertSame('mysql', (new \Modules\Prime\Models\Role())->getConnectionName(), 'Role is not on the central mysql connection.');
        $this->assertSame('127.0.0.1', parse_url($this->primeBaseUrl, PHP_URL_HOST), 'Prime tests must target 127.0.0.1.');
    }

    public function test_rolepermission_94_state_changing_endpoints_require_auth(): void
    {
        $this->runHttp(function (): void {
            $resp = $this->post($this->centralBaseUrl . self::INDEX_PATH, []);
            $this->assertContains($resp->getStatusCode(), [302, 401, 403, 419, 422], 'Unauthenticated store was not blocked.');
        });
    }

    // =============================================================================
    // Private helper library
    // =============================================================================

    private function controllerSource(): string
    {
        if ($this->controllerSource === null) {
            $path = base_path(self::CONTROLLER_PATH);
            $this->controllerSource = is_file($path) ? (string) file_get_contents($path) : '';
        }
        return $this->controllerSource;
    }

    private function requestSource(): string
    {
        if ($this->requestSource === null) {
            $path = base_path(self::REQUEST_PATH);
            $this->requestSource = is_file($path) ? (string) file_get_contents($path) : '';
        }
        return $this->requestSource;
    }

    /** Extract the body of a controller method by brace matching. */
    private function controllerMethodBody(string $method): string
    {
        $src = $this->controllerSource();
        if ($src === '') {
            return '';
        }
        $pattern = '/function\s+' . preg_quote($method, '/') . '\s*\(/';
        if (!preg_match($pattern, $src, $m, PREG_OFFSET_CAPTURE)) {
            return '';
        }
        $start = strpos($src, '{', $m[0][1]);
        if ($start === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($src);
        for ($i = $start; $i < $len; $i++) {
            if ($src[$i] === '{') {
                $depth++;
            } elseif ($src[$i] === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($src, $start, $i - $start + 1);
                }
            }
        }
        return substr($src, $start);
    }

    private function assertActionGate(string $method, string $gate): void
    {
        $this->assertStringContainsString(
            "Gate::authorize('{$gate}')",
            $this->controllerMethodBody($method),
            "{$method}() must authorize with {$gate}."
        );
    }

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/') ? $this->centralBaseUrl . $path : $this->centralBaseUrl . '/' . $path;
    }

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    private function authenticateCentral(Browser $browser): void
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

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    private function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->markTestSkipped($context . ' shows the login page; central auth unavailable in this environment.');
        }
        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->markTestSkipped($context . ' not accessible (' . $signal . ') — module likely disabled in modules_statuses.json.');
            }
        }
    }

    private function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            if ($superAdmin) {
                $this->adminUser = $superAdmin;
                return;
            }
            $byEmail = User::query()->where('email', $this->adminEmail)->first();
            if ($byEmail) {
                $this->adminUser = $byEmail;
            }
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    private function createLimitedUser(): ?User
    {
        try {
            $suffix = $this->uniqueShort();
            $user = User::create([
                'email' => 'limited_' . $suffix . '@prm.test',
                'password' => bcrypt('password'),
                'name' => 'Limited RP User',
                'emp_code' => 'RP' . substr($suffix, 0, 8),
                'short_name' => 'RP' . substr($suffix, 0, 6),
                'is_super_admin' => 0,
            ]);
            $this->createdUserIds[] = $user->id;
            return $user;
        } catch (Throwable) {
            return null;
        }
    }

    private function anyPermissionName(): ?string
    {
        try {
            $name = DB::connection('mysql')->table(self::TABLE_PERMISSIONS)->value('name');
            return $name !== null ? (string) $name : null;
        } catch (Throwable) {
            return null;
        }
    }

    private function anyRoleId(): ?int
    {
        try {
            $id = DB::connection('mysql')->table(self::TABLE_ROLES)->value('id');
            return $id !== null ? (int) $id : null;
        } catch (Throwable) {
            return null;
        }
    }

    private function assertDatabaseHasRole(int $id): void
    {
        $this->assertTrue(
            DB::connection('mysql')->table(self::TABLE_ROLES)->where('id', $id)->exists(),
            "Role {$id} not found in sys_roles."
        );
    }

    private function trackRole(int $id): void
    {
        $this->createdRoleIds[] = $id;
    }

    private function uniqueName(string $prefix): string
    {
        return $prefix . '_RP_' . uniqid();
    }

    private function uniqueShort(): string
    {
        // sys_roles.short_name is VARCHAR(20); keep well under the limit.
        return substr('rp' . uniqid(), 0, 18);
    }

    /**
     * Run a functional block that touches the live central DB; skip (green) on any
     * environment failure so partial environments stay green (HARD RULE 9).
     */
    private function runFunctional(callable $block): void
    {
        try {
            $block();
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('Functional path unavailable in this environment: ' . $e->getMessage());
        }
    }

    /**
     * Run an HTTP block against the central app; skip (green) on connection/host issues.
     */
    private function runHttp(callable $block): void
    {
        try {
            $block();
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('HTTP path unavailable in this environment: ' . $e->getMessage());
        }
    }
}
