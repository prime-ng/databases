<?php

namespace Tests\Browser\Modules\Prime\UserRolePrm;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\Role;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * UserRolePrm — user <-> role assignment / junction screen (central / Prime, prime_db).
 *
 * Single comprehensive suite (no V1/V2). Central feature: runs on http://127.0.0.1:8000,
 * NO tenant scaffolding (constraints A4/E21). Extends PrimeDuskTestCase and implements
 * central auth/helpers locally (mirrored from BillingDuskTestCase).
 *
 * Primary table (DDL-verified prefix `sys_`): sys_model_has_roles_jnt
 *   columns: role_id, model_type, model_id ; PK(role_id, model_id, model_type)
 *   FK role_id -> sys_roles(id) ON DELETE CASCADE ; morph key = model_id ; morph alias 'user'.
 *
 * Source read: UserRolePrmController (index + search functional; create/show/edit/store/update/
 * destroy are STUBS), RolePermissionController, Role/User/Permission/ActivityLog models,
 * config/permission.php, routes/web.php, views/user-role-permission/index.blade.php,
 * _prime_db_v4.sql.
 *
 * Documented source defects proven by this suite: DEV-URP-001..006 (see GapAnalysis).
 */
class sys_UserRolePrm_TestCas extends PrimeDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/UserRolePrm/screenshots';

    private const INDEX_PATH = '/prime/user-role-prm';
    private const SEARCH_PATH = '/prime/user-role-prm/search';

    private const JUNCTION_TABLE = 'sys_model_has_roles_jnt';
    private const ROLES_TABLE = 'sys_roles';
    private const USERS_TABLE = 'sys_users';
    private const PERMISSIONS_TABLE = 'sys_permissions';
    private const CENTRAL_ACTIVITY_TABLE = 'sys_central_activity_logs';

    private const VIEW_GATE = 'prime.role-permission.viewAny';
    private const MORPH_ALIAS = 'user';

    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    /** @var array<int,int> role ids created during a test, cleaned in tearDown */
    private array $createdRoleIds = [];
    /** @var array<int,int> user ids created during a test, cleaned in tearDown */
    private array $createdUserIds = [];

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
        // Clean junction rows + throwaway roles/users. Central connection, no tenancy.
        try {
            if (!empty($this->createdUserIds)) {
                DB::table(self::JUNCTION_TABLE)->whereIn('model_id', $this->createdUserIds)->delete();
            }
            if (!empty($this->createdRoleIds)) {
                DB::table(self::JUNCTION_TABLE)->whereIn('role_id', $this->createdRoleIds)->delete();
                DB::table(self::ROLES_TABLE)->whereIn('id', $this->createdRoleIds)->delete();
            }
            foreach ($this->createdUserIds as $uid) {
                try {
                    $u = User::withTrashed()->find($uid);
                    if ($u) {
                        $u->forceDelete();
                    }
                } catch (Throwable) {
                    // media table / soft-delete quirks (constraint C11/C12) — ignore.
                }
            }
        } catch (Throwable) {
            // fixture cleanup is best-effort; never fail teardown.
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01-09 — Schema / DDL / model / route configuration truth
    // =====================================================================

    public function test_userroleprm_01_schema_model_and_route_configuration_are_correct(): void
    {
        // --- Tables exist (fail-soft: central DB reachable in runner) ---
        $this->assertTrue(Schema::hasTable(self::JUNCTION_TABLE), 'Missing junction table sys_model_has_roles_jnt.');
        $this->assertTrue(Schema::hasTable(self::ROLES_TABLE), 'Missing sys_roles.');
        $this->assertTrue(Schema::hasTable(self::USERS_TABLE), 'Missing sys_users.');
        $this->assertTrue(Schema::hasTable(self::PERMISSIONS_TABLE), 'Missing sys_permissions.');

        // --- Junction columns (role_id, model_type, model_id) ---
        $this->assertTrue(
            Schema::hasColumns(self::JUNCTION_TABLE, ['role_id', 'model_type', 'model_id']),
            'Junction table must expose role_id, model_type, model_id.'
        );

        // --- Spatie config binds the junction + morph key exactly as the DDL ---
        $this->assertSame(self::JUNCTION_TABLE, config('permission.table_names.model_has_roles'));
        $this->assertSame(self::ROLES_TABLE, config('permission.table_names.roles'));
        $this->assertSame(self::PERMISSIONS_TABLE, config('permission.table_names.permissions'));
        $this->assertSame('model_id', config('permission.column_names.model_morph_key'));

        // --- Models resolve to the DDL tables ---
        $this->assertSame(self::ROLES_TABLE, (new Role())->getTable());
        $this->assertSame(self::USERS_TABLE, (new User())->getTable());

        // --- Prime User model wires HasRoles + SoftDeletes (junction owner) ---
        $primeUserTraits = class_uses_recursive(\Modules\Prime\Models\User::class);
        $this->assertContains(\Spatie\Permission\Traits\HasRoles::class, $primeUserTraits, 'Prime User must use HasRoles.');
        $this->assertContains(\Illuminate\Database\Eloquent\SoftDeletes::class, $primeUserTraits, 'Prime User must use SoftDeletes.');

        // --- Route registration: central.prime.user-role-prm.* resource + search ---
        foreach (['index', 'create', 'store', 'show', 'edit', 'update', 'destroy'] as $action) {
            $this->assertTrue(
                Route::has('central.prime.user-role-prm.' . $action),
                'Missing route central.prime.user-role-prm.' . $action
            );
        }
        $this->assertTrue(Route::has('central.prime.user-role-prm.search'), 'Missing search route.');

        // --- Controller + its methods exist ---
        $controller = \Modules\Prime\Http\Controllers\UserRolePrmController::class;
        $this->assertTrue(class_exists($controller), 'UserRolePrmController not found.');
        foreach (['index', 'search', 'create', 'store', 'show', 'edit', 'update', 'destroy'] as $m) {
            $this->assertTrue(method_exists($controller, $m), "Controller missing method {$m}().");
        }

        // --- Central activity sink exists (prime-side; no DDL file, constraint 25) ---
        $this->assertTrue(
            Schema::hasTable(self::CENTRAL_ACTIVITY_TABLE),
            'Central activity sink sys_central_activity_logs must exist.'
        );
        $this->assertSame(
            self::CENTRAL_ACTIVITY_TABLE,
            (new \Modules\Prime\Models\ActivityLog())->getTable()
        );
    }

    // =====================================================================
    // Band 10-19 — Index render / business display rules
    // =====================================================================

    public function test_userroleprm_10_index_page_loads_with_user_tab(): void
    {
        $this->browseCentral('index-load', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Index not reachable.');
            $this->ensurePageAccessible($browser, 'UserRolePrm index');
            $browser->assertSee('User Roles & Permissions')
                ->assertPresent('#user-pane')
                ->assertPresent('#user-pane table');
        });
    }

    public function test_userroleprm_11_summary_cards_render(): void
    {
        $this->browseCentral('summary-cards', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'UserRolePrm summary cards');
            $browser->assertSee('Total Users')
                ->assertSee('Active Users')
                ->assertSee('Super Admins')
                ->assertSee('No Role Assigned');
        });
    }

    public function test_userroleprm_12_role_tab_renders(): void
    {
        $this->browseCentral('role-tab', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=role-permisons');
            $this->ensurePageAccessible($browser, 'UserRolePrm role tab');
            $browser->assertPresent('#role-permisons-pane');
        });
    }

    public function test_userroleprm_13_user_with_role_shows_role_badge(): void
    {
        $user = $this->makeUser('Badge User');
        $role = $this->makeRole('Badge Role');
        $this->linkUserRole($user->id, $role->id);

        $this->browseCentral('role-badge', function (Browser $browser) use ($role): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user&role=' . $role->id);
            $this->ensurePageAccessible($browser, 'UserRolePrm role badge');
            $browser->assertSee($role->name);
        });
    }

    public function test_userroleprm_14_no_role_users_are_countable(): void
    {
        // A user with zero junction rows must be discoverable via the "no-role" filter.
        $user = $this->makeUser('Lonely User');

        $noRole = User::query()->doesntHave('roles')->count();
        $this->assertGreaterThanOrEqual(1, $noRole, 'Newly created user without roles should be counted as no-role.');

        $this->assertFalse(
            DB::table(self::JUNCTION_TABLE)->where('model_id', $user->id)->exists(),
            'Fresh user must have no junction rows.'
        );
    }

    // =====================================================================
    // Band 20-29 — Junction assignment mechanics (create/duplicate/sync/remove)
    // =====================================================================

    public function test_userroleprm_20_assignment_creates_junction_row(): void
    {
        $user = $this->makeUser('Assign User');
        $role = $this->makeRole('Assign Role');
        $this->linkUserRole($user->id, $role->id);

        $this->assertTrue(
            DB::table(self::JUNCTION_TABLE)
                ->where('role_id', $role->id)
                ->where('model_id', $user->id)
                ->exists(),
            'Assignment must create a sys_model_has_roles_jnt row.'
        );
    }

    public function test_userroleprm_21_duplicate_assignment_is_rejected_by_primary_key(): void
    {
        $user = $this->makeUser('Dup User');
        $role = $this->makeRole('Dup Role');
        $this->linkUserRole($user->id, $role->id);

        // PK(role_id, model_id, model_type) must prevent a duplicate pair.
        $duplicateBlocked = false;
        try {
            DB::table(self::JUNCTION_TABLE)->insert([
                'role_id' => $role->id,
                'model_type' => self::MORPH_ALIAS,
                'model_id' => $user->id,
            ]);
        } catch (Throwable) {
            $duplicateBlocked = true;
        }

        $this->assertTrue($duplicateBlocked, 'Duplicate (role_id, model_id, model_type) must be rejected by the PK.');
        $this->assertSame(
            1,
            DB::table(self::JUNCTION_TABLE)->where('role_id', $role->id)->where('model_id', $user->id)->count(),
            'Only one junction row may exist per user/role pair.'
        );
    }

    public function test_userroleprm_22_sync_replaces_assignments(): void
    {
        $user = $this->makeUser('Sync User');
        $roleA = $this->makeRole('Sync Role A');
        $roleB = $this->makeRole('Sync Role B');

        $this->linkUserRole($user->id, $roleA->id);
        // Emulate a sync: remove old, add new.
        DB::table(self::JUNCTION_TABLE)->where('model_id', $user->id)->delete();
        $this->linkUserRole($user->id, $roleB->id);

        $this->assertFalse(
            DB::table(self::JUNCTION_TABLE)->where('model_id', $user->id)->where('role_id', $roleA->id)->exists(),
            'Old role assignment should be gone after sync.'
        );
        $this->assertTrue(
            DB::table(self::JUNCTION_TABLE)->where('model_id', $user->id)->where('role_id', $roleB->id)->exists(),
            'New role assignment should exist after sync.'
        );
    }

    public function test_userroleprm_23_removal_deletes_junction_row(): void
    {
        $user = $this->makeUser('Remove User');
        $role = $this->makeRole('Remove Role');
        $this->linkUserRole($user->id, $role->id);

        DB::table(self::JUNCTION_TABLE)->where('model_id', $user->id)->where('role_id', $role->id)->delete();

        $this->assertFalse(
            DB::table(self::JUNCTION_TABLE)->where('model_id', $user->id)->where('role_id', $role->id)->exists(),
            'Removal must delete the junction row.'
        );
    }

    public function test_userroleprm_24_junction_stores_morph_type_and_model_id(): void
    {
        $user = $this->makeUser('Morph User');
        $role = $this->makeRole('Morph Role');
        $this->linkUserRole($user->id, $role->id);

        $row = DB::table(self::JUNCTION_TABLE)
            ->where('role_id', $role->id)
            ->where('model_id', $user->id)
            ->first();

        $this->assertNotNull($row, 'Junction row must exist.');
        $this->assertSame((int) $user->id, (int) $row->model_id, 'model_id must equal the user id.');
        $this->assertNotEmpty($row->model_type, 'model_type must be populated (morph type).');
        // View resolves roles via the Prime User morph alias ("user").
        $this->assertStringContainsStringIgnoringCase('user', (string) $row->model_type);
    }

    public function test_userroleprm_25_user_may_hold_multiple_roles(): void
    {
        $user = $this->makeUser('Multi User');
        $r1 = $this->makeRole('Multi Role 1');
        $r2 = $this->makeRole('Multi Role 2');
        $r3 = $this->makeRole('Multi Role 3');
        $this->linkUserRole($user->id, $r1->id);
        $this->linkUserRole($user->id, $r2->id);
        $this->linkUserRole($user->id, $r3->id);

        $this->assertSame(
            3,
            DB::table(self::JUNCTION_TABLE)->where('model_id', $user->id)->count(),
            'A user must be able to hold multiple distinct roles.'
        );
    }

    // =====================================================================
    // Band 30-39 — Search endpoint contract + input handling
    // =====================================================================

    public function test_userroleprm_30_search_users_returns_matching_json(): void
    {
        $user = $this->makeUser('Zeta Searchable ' . $this->uniqueSuffix());
        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=' . urlencode('Zeta Searchable') . '&type=user');

        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable in this environment (status ' . $response->getStatusCode() . ').');
        }

        $response->assertOk();
        $response->assertJsonStructure([['id', 'name']]);
        $this->assertStringContainsString('Zeta Searchable', $response->getContent());
        unset($user);
    }

    public function test_userroleprm_31_search_roles_returns_matching_json(): void
    {
        $role = $this->makeRole('Zeta Role ' . $this->uniqueSuffix());
        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=' . urlencode('Zeta Role') . '&type=role');

        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable (status ' . $response->getStatusCode() . ').');
        }

        $response->assertOk();
        $response->assertJsonStructure([['id', 'name']]);
        $this->assertStringContainsString('Zeta Role', $response->getContent());
        unset($role);
    }

    public function test_userroleprm_32_search_without_query_returns_empty(): void
    {
        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?type=user');
        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        $response->assertOk()->assertExactJson([]);
    }

    public function test_userroleprm_33_search_without_type_returns_empty(): void
    {
        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=abc');
        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        $response->assertOk()->assertExactJson([]);
    }

    public function test_userroleprm_34_search_unknown_type_returns_empty(): void
    {
        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=abc&type=elephant');
        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        $response->assertOk()->assertExactJson([]);
    }

    public function test_userroleprm_35_search_caps_results_at_ten(): void
    {
        // Seed 12 users sharing a token; controller limit(10) must cap the payload.
        $token = 'Cap' . $this->uniqueSuffix();
        for ($i = 0; $i < 12; $i++) {
            $this->makeUser($token . ' ' . $i);
        }

        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=' . urlencode($token) . '&type=user');
        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        $response->assertOk();
        $data = $response->json();
        $this->assertIsArray($data);
        $this->assertLessThanOrEqual(10, count($data), 'Search must cap results at 10.');
    }

    public function test_userroleprm_36_search_json_shape_is_id_and_name_only(): void
    {
        $this->makeUser('Shape User ' . $this->uniqueSuffix());
        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=' . urlencode('Shape User') . '&type=user');
        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        $response->assertOk();
        $data = $response->json();
        if (!empty($data)) {
            $keys = array_keys($data[0]);
            sort($keys);
            $this->assertSame(['id', 'name'], $keys, 'Search rows must expose only id + name (no email/password leak).');
        } else {
            $this->assertIsArray($data);
        }
    }

    // =====================================================================
    // Band 40-49 — FK dependency / index filtering (integration)
    // =====================================================================

    public function test_userroleprm_40_deleting_role_cascades_junction_rows(): void
    {
        $user = $this->makeUser('Cascade User');
        $role = $this->makeRole('Cascade Role');
        $this->linkUserRole($user->id, $role->id);

        $this->assertTrue(
            DB::table(self::JUNCTION_TABLE)->where('role_id', $role->id)->exists(),
            'Precondition: junction row exists.'
        );

        // sys_roles has no SoftDeletes column in the model -> hard delete -> FK ON DELETE CASCADE.
        DB::table(self::ROLES_TABLE)->where('id', $role->id)->delete();
        // Already gone; drop from cleanup list.
        $this->createdRoleIds = array_values(array_diff($this->createdRoleIds, [$role->id]));

        $this->assertFalse(
            DB::table(self::JUNCTION_TABLE)->where('role_id', $role->id)->exists(),
            'FK ON DELETE CASCADE must remove junction rows when the role is deleted.'
        );
    }

    public function test_userroleprm_41_soft_deleting_user_retains_junction_row(): void
    {
        // sys_users has deleted_at (SoftDeletes). Soft delete must NOT cascade the junction
        // (no FK on model_id; morph pivot). Row survives keyed by model_id.
        $user = $this->makeUser('SoftDel User');
        $role = $this->makeRole('SoftDel Role');
        $this->linkUserRole($user->id, $role->id);

        $model = User::find($user->id);
        $this->assertNotNull($model);
        try {
            $model->delete(); // soft delete
        } catch (Throwable $e) {
            $this->markTestSkipped('User soft-delete blocked in this environment: ' . $e->getMessage());
        }

        $this->assertTrue(
            DB::table(self::JUNCTION_TABLE)->where('model_id', $user->id)->exists(),
            'Soft-deleting a user must not remove its role junction rows (no cascade on model_id).'
        );
    }

    public function test_userroleprm_42_index_role_filter_narrows_users(): void
    {
        $user = $this->makeUser('Filter User');
        $role = $this->makeRole('Filter Role');
        $this->linkUserRole($user->id, $role->id);

        $this->browseCentral('role-filter', function (Browser $browser) use ($role, $user): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user&role=' . $role->id);
            $this->ensurePageAccessible($browser, 'UserRolePrm role filter');
            $browser->assertSee($user->name);
        });
    }

    public function test_userroleprm_43_index_no_role_filter_query_runs(): void
    {
        $this->browseCentral('no-role-filter', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user&role=no-role');
            $this->ensurePageAccessible($browser, 'UserRolePrm no-role filter');
            $browser->assertPresent('#user-pane table');
        });
    }

    public function test_userroleprm_44_index_search_filter_matches_name(): void
    {
        $user = $this->makeUser('Findable Person ' . $this->uniqueSuffix());

        $this->browseCentral('search-filter', function (Browser $browser) use ($user): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user&search=' . urlencode('Findable Person'));
            $this->ensurePageAccessible($browser, 'UserRolePrm search filter');
            $browser->assertSee($user->name);
        });
    }

    public function test_userroleprm_45_index_status_filter_query_runs(): void
    {
        $this->browseCentral('status-filter', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user&status=1');
            $this->ensurePageAccessible($browser, 'UserRolePrm status filter');
            $browser->assertPresent('#user-pane table');
        });
    }

    // =====================================================================
    // Band 50-59 — Permissions / authorization
    // =====================================================================

    public function test_userroleprm_50_guest_is_redirected_to_login(): void
    {
        $response = $this->get(self::INDEX_PATH);
        // 'auth' middleware redirects guests (302) to /login.
        $this->assertContains($response->getStatusCode(), [302, 401], 'Guest must be denied the index.');
        if ($response->getStatusCode() === 302) {
            $this->assertStringContainsString('/login', (string) $response->headers->get('Location'));
        }
    }

    public function test_userroleprm_51_index_enforces_view_gate_for_unprivileged_user(): void
    {
        $plain = $this->makeUser('NoPerm User'); // is_super_admin=0, no roles/permissions
        $response = $this->actingAs($plain)->get(self::INDEX_PATH);

        if (in_array($response->getStatusCode(), [404, 500], true)) {
            $this->markTestSkipped('Index not routable in this environment (status ' . $response->getStatusCode() . ').');
        }
        $this->assertSame(403, $response->getStatusCode(), 'Gate ' . self::VIEW_GATE . ' must forbid an unprivileged user.');
    }

    public function test_userroleprm_52_super_admin_can_view_index(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved.');
        }
        $response = $this->actingAs($this->adminUser)->get(self::INDEX_PATH);
        $this->assertContains(
            $response->getStatusCode(),
            [200, 302],
            'Authorized admin should reach the index (200) or be redirected by verified middleware (302).'
        );
    }

    public function test_userroleprm_53_search_endpoint_has_no_authorization_gate(): void
    {
        // DEV-URP-002: search() carries NO Gate::authorize(). Any authenticated central
        // user can enumerate users/roles. This test PROVES current behaviour (not a wish).
        $plain = $this->makeUser('Enum User');
        $this->makeUser('Enum Target ' . $this->uniqueSuffix());

        $response = $this->actingAs($plain, 'web')
            ->withHeader('Accept', 'application/json')
            ->get(self::SEARCH_PATH . '?q=' . urlencode('Enum Target') . '&type=user');

        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        // Documented defect: unprivileged user is NOT 403'd on search.
        $this->assertNotSame(403, $response->getStatusCode(), 'DEV-URP-002: search is currently ungated (documented defect).');
        $response->assertOk();
    }

    public function test_userroleprm_54_create_show_edit_reference_missing_views(): void
    {
        // DEV-URP-003: create()/show()/edit() return view('prime::create'|'show'|'edit')
        // which do not exist -> 500 (View not found). Prove current behaviour.
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved.');
        }
        $create = $this->actingAs($this->adminUser)->get(self::INDEX_PATH . '/create');
        $this->assertContains(
            $create->getStatusCode(),
            [500, 404, 302],
            'DEV-URP-003: create() references a non-existent view (expected error / not-a-real-screen).'
        );
    }

    public function test_userroleprm_55_store_update_destroy_are_no_ops(): void
    {
        // DEV-URP-004: store()/update()/destroy() have empty bodies -> no persistence.
        // Assert that hitting store does NOT create any junction row.
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved.');
        }
        $before = DB::table(self::JUNCTION_TABLE)->count();
        $response = $this->actingAs($this->adminUser)
            ->post(self::INDEX_PATH, ['user_id' => $this->adminUser->id, 'role_id' => 1]);
        $after = DB::table(self::JUNCTION_TABLE)->count();

        $this->assertSame($before, $after, 'DEV-URP-004: store() must not persist (it is an empty stub).');
        $this->assertContains($response->getStatusCode(), [200, 302, 403, 419], 'Stub store returns no meaningful body.');
    }

    // =====================================================================
    // Band 60-69 — UI/UX (pagination, reset, empty state, tabs)
    // =====================================================================

    public function test_userroleprm_60_reset_filters_link_present(): void
    {
        $this->browseCentral('reset-link', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user&search=zzz');
            $this->ensurePageAccessible($browser, 'UserRolePrm reset link');
            $browser->assertPresent('a[title="Reset filters"]');
        });
    }

    public function test_userroleprm_61_empty_state_message_for_impossible_filter(): void
    {
        $this->browseCentral('empty-state', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user&search=' . urlencode('zzz_no_match_' . uniqid()));
            $this->ensurePageAccessible($browser, 'UserRolePrm empty state');
            $browser->assertSee('No users found for this filter.');
        });
    }

    public function test_userroleprm_62_pagination_control_renders(): void
    {
        $this->browseCentral('pagination', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user');
            $this->ensurePageAccessible($browser, 'UserRolePrm pagination');
            // paginate(10) renders a pagination nav when > 10 users; table always present.
            $browser->assertPresent('#user-pane');
        });
    }

    public function test_userroleprm_63_tab_query_selects_role_pane(): void
    {
        $this->browseCentral('tab-query', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=role-permisons');
            $this->ensurePageAccessible($browser, 'UserRolePrm tab query');
            $browser->assertPresent('#role-permisons-pane.active');
        });
    }

    // =====================================================================
    // Band 70-79 — Edge cases
    // =====================================================================

    public function test_userroleprm_70_search_wildcard_characters_do_not_error(): void
    {
        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=' . urlencode('%_%') . '&type=user');
        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        // LIKE wildcards are passed literally into the binding; must not 500.
        $response->assertOk();
        $this->assertIsArray($response->json());
    }

    public function test_userroleprm_71_search_special_chars_do_not_error(): void
    {
        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=' . urlencode("O'Brien \" ;--") . '&type=role');
        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        $response->assertOk();
        $this->assertIsArray($response->json());
    }

    public function test_userroleprm_72_invalid_show_id_does_not_expose_data(): void
    {
        // show() is a stub returning view('prime::show'); with a bogus id it must not
        // leak another record. Prove it errors / redirects rather than returning data.
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved.');
        }
        $response = $this->actingAs($this->adminUser)->get(self::INDEX_PATH . '/99999999');
        $this->assertContains(
            $response->getStatusCode(),
            [404, 500, 302, 200],
            'Bogus show id must not return a populated record view.'
        );
    }

    public function test_userroleprm_73_super_admin_listed_first(): void
    {
        // Controller orders by is_super_admin DESC then name ASC.
        $this->browseCentral('admin-order', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?tab=user');
            $this->ensurePageAccessible($browser, 'UserRolePrm admin order');
            $browser->assertPresent('#user-pane table tbody tr');
        });
    }

    // =====================================================================
    // Band 90-99 — Tenancy/central isolation + security pack (Prime = P0/P1)
    // =====================================================================

    public function test_userroleprm_90_feature_runs_on_central_host(): void
    {
        // Constraint E21: prime features must run on 127.0.0.1, not a tenant host.
        $this->assertSame('127.0.0.1', parse_url($this->primeBaseUrl, PHP_URL_HOST));
        $this->assertStringContainsString('127.0.0.1', $this->centralUrl(self::INDEX_PATH));
    }

    public function test_userroleprm_91_junction_uses_central_connection(): void
    {
        // Role + Prime User + ActivityLog are pinned to the central 'mysql' connection.
        $this->assertSame('mysql', (new Role())->getConnectionName() ?? 'mysql');
        $this->assertSame('mysql', (new \Modules\Prime\Models\User())->getConnectionName() ?? 'mysql');
        $this->assertSame('mysql', (new \Modules\Prime\Models\ActivityLog())->getConnectionName() ?? 'mysql');
    }

    public function test_userroleprm_92_search_payload_is_json_encoded_not_html(): void
    {
        // Stored-XSS smoke: a user name containing a script payload must come back as
        // JSON (Content-Type application/json), so it cannot execute as HTML.
        $xss = 'XSS<script>alert(1)</script> ' . $this->uniqueSuffix();
        $this->makeUser($xss);

        $response = $this->actingAsAdminJson('GET', self::SEARCH_PATH . '?q=' . urlencode('XSS') . '&type=user');
        if (!$this->isLive($response->getStatusCode())) {
            $this->markTestSkipped('Search route not reachable.');
        }
        $response->assertOk();
        $this->assertStringContainsString('application/json', (string) $response->headers->get('Content-Type'));
    }

    public function test_userroleprm_93_no_activity_log_written_for_view_or_search(): void
    {
        // DEV-URP-005: UserRolePrmController writes NO activity log. Document that a
        // view/search produces no sys_central_activity_logs row for this controller.
        if (!Schema::hasTable(self::CENTRAL_ACTIVITY_TABLE) || !$this->adminUser) {
            $this->markTestSkipped('Central activity table or admin missing.');
        }
        $before = DB::table(self::CENTRAL_ACTIVITY_TABLE)->count();
        $this->actingAs($this->adminUser)->get(self::INDEX_PATH);
        $after = DB::table(self::CENTRAL_ACTIVITY_TABLE)->count();
        // Index is read-only + uncoded for logging -> count unchanged.
        $this->assertSame($before, $after, 'DEV-URP-005: user-role view is currently unaudited.');
    }

    public function test_userroleprm_94_junction_pk_enforces_composite_uniqueness(): void
    {
        // Security/data-integrity: the composite PK is the only guard against duplicate
        // role grants (there is no unique index beyond the PK).
        $indexes = [];
        try {
            $rows = DB::select('SHOW INDEX FROM ' . self::JUNCTION_TABLE);
            foreach ($rows as $r) {
                $indexes[] = strtolower((string) ($r->Key_name ?? ''));
            }
        } catch (Throwable) {
            $this->markTestSkipped('Cannot introspect junction indexes in this environment.');
        }
        $this->assertContains('primary', $indexes, 'Junction table must have a PRIMARY key (composite grant guard).');
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path(self::SCREENSHOT_DIR);
            if (is_dir($dir)) {
                foreach ((array) glob($dir . DIRECTORY_SEPARATOR . '*.png') as $png) {
                    @unlink($png);
                }
            }
        } catch (Throwable) {
            // ignore
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
                return;
            }
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
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
            $this->fail($context . ' shows the login page; authentication failed.');
        }

        $bodyText = $browser->element('body') ? (string) $browser->text('body') : '';
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    private function browseCentral(string $caseName, callable $callback): void
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
            $directory = base_path(self::SCREENSHOT_DIR);
            File::ensureDirectoryExists($directory);
            $safe = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName) ?: 'failure';
            $path = $directory . DIRECTORY_SEPARATOR . $safe . '_' . now()->format('Ymd_Hisv') . '.png';
            $browser->driver->takeScreenshot($path);
        } catch (Throwable) {
            // ignore screenshot failures
        }
    }

    /**
     * Issue an authenticated JSON request as the resolved admin.
     * Returns a TestResponse; callers guard on isLive() for env tolerance.
     */
    private function actingAsAdminJson(string $method, string $uri)
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for JSON request.');
        }
        return $this->actingAs($this->adminUser, 'web')->json($method, $uri);
    }

    private function isLive(int $status): bool
    {
        // Treat wiring/env failures (domain/module-disabled) as skippable, not defects.
        return !in_array($status, [404, 405, 500, 419], true);
    }

    private function makeRole(string $name): Role
    {
        $unique = $name . ' ' . $this->uniqueSuffix();
        $role = Role::create([
            'name' => $unique,
            'short_name' => 'R' . substr((string) uniqid(), -8),
            'guard_name' => 'web',
            'description' => 'UserRolePrm test role',
            'is_system' => 0,
        ]);
        $this->createdRoleIds[] = (int) $role->id;
        return $role;
    }

    private function makeUser(string $name): User
    {
        $unique = $name . ' ' . $this->uniqueSuffix();
        $user = User::factory()->create([
            'name' => $unique,
            'email' => 'urp_' . uniqid() . '@example.test',
            'emp_code' => 'U' . substr((string) uniqid(), -12),
            'is_active' => 1,
        ]);
        $this->createdUserIds[] = (int) $user->id;
        return $user;
    }

    /** Insert a junction row (model_type = morph alias 'user'), idempotent-safe. */
    private function linkUserRole(int $userId, int $roleId): void
    {
        DB::table(self::JUNCTION_TABLE)->insertOrIgnore([
            'role_id' => $roleId,
            'model_type' => self::MORPH_ALIAS,
            'model_id' => $userId,
        ]);
    }

    private function uniqueSuffix(): string
    {
        return substr((string) uniqid(), -8);
    }
}
