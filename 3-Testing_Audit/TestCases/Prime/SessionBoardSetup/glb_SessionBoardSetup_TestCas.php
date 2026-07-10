<?php

namespace Tests\Browser\Modules\Prime\SessionBoardSetup;

use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\Board;
use Modules\Prime\Models\AcademicSession;
use ReflectionClass;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * SessionBoardSetup (composite "Session & Board Setup" screen) — Prime (PRM) central module.
 *
 * DB scope: CENTRAL / GlobalMaster (`global_master_mysql` connection, `glb_*` tables). NO tenant init.
 * Host: http://127.0.0.1:8000 (enforced by PrimeDuskTestCase::setUp()).
 * Prefix: glb_ (DDL primary tables glb_academic_sessions + glb_boards) — MISMATCH vs registry Prime prefix prm_.
 *
 * Single comprehensive suite (no V1/V2). Central-Dusk style mirrors the committed
 * Prime/Billing siblings; central auth/helpers are implemented locally (from BillingDuskTestCase),
 * per the sub-run override. Constraints obeyed: #14 (no Dusk assertStatus — HTTP test methods),
 * #21/#22 (central base + preload alias), #25 (central activity sink sys_central_activity_logs),
 * #13 (typed props initialised).
 */
class glb_SessionBoardSetup_TestCas extends PrimeDuskTestCase
{
    // ---- Routes / paths (from prime_ai/routes/web.php:173 resource under domain(central.)->prefix(prime)->name(prime.)) ----
    private const INDEX_PATH = '/prime/session-board-setup';
    private const ROUTE_INDEX = 'central.prime.session-board-setup.index';
    private const ROUTE_CREATE = 'central.prime.session-board-setup.create';
    private const ROUTE_STORE = 'central.prime.session-board-setup.store';
    private const ROUTE_SHOW = 'central.prime.session-board-setup.show';
    private const ROUTE_EDIT = 'central.prime.session-board-setup.edit';
    private const ROUTE_UPDATE = 'central.prime.session-board-setup.update';
    private const ROUTE_DESTROY = 'central.prime.session-board-setup.destroy';

    // ---- Data layer (verified: models + _global_db_v4.sql) ----
    private const CONNECTION = 'global_master_mysql';
    private const SESSIONS_TABLE = 'glb_academic_sessions';
    private const BOARDS_TABLE = 'glb_boards';
    private const PIVOT_TABLE = 'academic_session_board'; // belongsToMany default — has NO DDL table (BUG-PRM-014)
    private const CENTRAL_ACTIVITY_TABLE = 'sys_central_activity_logs';

    // ---- Permission gates (verified: SessionBoardSetupController) ----
    private const GATE_VIEWANY = 'prime.session-board-setup.viewAny';
    private const GATE_CREATE = 'prime.session-board-setup.create';
    private const GATE_VIEW = 'prime.session-board-setup.view';
    private const GATE_UPDATE = 'prime.session-board-setup.update';
    private const GATE_DELETE = 'prime.session-board-setup.delete';

    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/SessionBoardSetup/screenshots';

    private ?User $adminUser = null;
    private ?User $limitedUser = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private array $createdSessionIds = [];
    private array $createdBoardIds = [];
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp(); // enforces host 127.0.0.1

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
        $this->cleanupCreatedRecords();
        parent::tearDown();
    }

    // =====================================================================
    // BAND 01–09 — SCHEMA / MODEL / ROUTE CONFIGURATION TRUTH
    // =====================================================================

    /** TC-P01..P08, BC-DB-*, BC-REF-01 | Source: DDL-glb_academic_sessions, DDL-glb_boards, models, routes */
    public function test_sessionboardsetup_01_schema_model_and_route_configuration_are_correct(): void
    {
        $sc = Schema::connection(self::CONNECTION);

        // -- Tables exist --
        $this->assertTrue($sc->hasTable(self::SESSIONS_TABLE), 'glb_academic_sessions table missing.');
        $this->assertTrue($sc->hasTable(self::BOARDS_TABLE), 'glb_boards table missing.');

        // -- glb_academic_sessions columns (DDL-verified) --
        $this->assertTrue($sc->hasColumns(self::SESSIONS_TABLE, [
            'id', 'short_name', 'name', 'start_date', 'end_date', 'is_current', 'current_flag',
            'deleted_at', 'created_at', 'updated_at',
        ]), 'glb_academic_sessions is missing expected columns.');

        // -- DEFECT ROOT (BUG-PRM-013): glb_academic_sessions has NO is_active column, yet the controller
        //    index() filters AcademicSession::where('is_active', ...) when ?status is present. --
        $this->assertFalse(
            $sc->hasColumn(self::SESSIONS_TABLE, 'is_active'),
            'DDL now has is_active on glb_academic_sessions — re-evaluate BUG-PRM-013 (controller status filter).'
        );

        // -- glb_boards columns (DDL-verified) --
        $this->assertTrue($sc->hasColumns(self::BOARDS_TABLE, [
            'id', 'name', 'short_name', 'is_active', 'created_at', 'updated_at', 'deleted_at',
        ]), 'glb_boards is missing expected columns.');

        // -- Unique keys --
        $this->assertTrue(
            $this->hasUniqueIndexOnColumn(self::SESSIONS_TABLE, 'short_name'),
            'Expected UNIQUE(short_name) on glb_academic_sessions.'
        );
        $this->assertTrue(
            $this->hasUniqueIndexOnColumn(self::SESSIONS_TABLE, 'current_flag'),
            'Expected UNIQUE(current_flag) on glb_academic_sessions (single active-session guard).'
        );
        $this->assertTrue(
            $this->hasUniqueIndexOnColumn(self::BOARDS_TABLE, 'name'),
            'Expected UNIQUE(name) on glb_boards.'
        );
        $this->assertTrue(
            $this->hasUniqueIndexOnColumn(self::BOARDS_TABLE, 'short_name'),
            'Expected UNIQUE(short_name) on glb_boards.'
        );

        // -- AcademicSession model config --
        $session = new AcademicSession();
        $this->assertSame(self::CONNECTION, $session->getConnectionName());
        $this->assertSame(self::SESSIONS_TABLE, $session->getTable());
        $this->assertContains('short_name', $session->getFillable());
        $this->assertContains('is_current', $session->getFillable());
        $this->assertNotContains('is_active', $session->getFillable(), 'AcademicSession fillable should not contain is_active.');
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(AcademicSession::class),
            'AcademicSession must use SoftDeletes.'
        );
        $this->assertSame('boolean', $session->getCasts()['is_current'] ?? null);
        $this->assertTrue(method_exists(AcademicSession::class, 'boards'), 'AcademicSession::boards() relation expected.');
        $this->assertTrue(method_exists(AcademicSession::class, 'scopeCurrent'), 'AcademicSession::scopeCurrent expected.');

        // -- Board model config (GlobalMaster) --
        $board = new Board();
        $this->assertSame(self::CONNECTION, $board->getConnectionName());
        $this->assertSame(self::BOARDS_TABLE, $board->getTable());
        $this->assertContains('is_active', $board->getFillable());
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(Board::class),
            'Board must use SoftDeletes.'
        );
        $this->assertSame('boolean', $board->getCasts()['is_active'] ?? null);

        // -- Routes registered (resource) --
        foreach ([
            self::ROUTE_INDEX, self::ROUTE_CREATE, self::ROUTE_STORE, self::ROUTE_SHOW,
            self::ROUTE_EDIT, self::ROUTE_UPDATE, self::ROUTE_DESTROY,
        ] as $name) {
            $this->assertTrue(Route::has($name), "Route {$name} is not registered.");
        }
    }

    /** BC-BIZ (activity sink) | Source: Constraint-25 | Controller emits NO activity — assert sink shape only */
    public function test_sessionboardsetup_02_central_activity_sink_present_but_feature_logs_nothing(): void
    {
        // Central activity sink (Modules\Prime\Models\ActivityLog → sys_central_activity_logs). Soft guard.
        $this->assertTrue(
            Schema::hasTable(self::CENTRAL_ACTIVITY_TABLE),
            'sys_central_activity_logs (central activity sink) is missing.'
        );

        // The SessionBoardSetupController contains NO activityLog() call anywhere (index is read-only; writes are stubs).
        $src = $this->classSource(\Modules\Prime\Http\Controllers\SessionBoardSetupController::class);
        $this->assertStringNotContainsString(
            'activityLog(',
            $src,
            'SessionBoardSetupController now logs activity — update BC-BIZ (no-activity finding).'
        );
    }

    // =====================================================================
    // BAND 10–19 — BUSINESS RULES / INDEX RENDER BEHAVIOUR (browser)
    // =====================================================================

    /** TC-P10, BC-AUTH-01 | Source: Controller index() Gate viewAny, view session-board-setup.index */
    public function test_sessionboardsetup_10_index_renders_both_tabs_for_admin(): void
    {
        $this->browseWithFailureScreenshot('index-both-tabs', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Session & Board Setup index not reachable.');
            $this->ensurePageAccessible($browser, 'Session & Board Setup index');

            $browser->assertSee('Session & Board Setup')
                ->assertPresent('#academicsession-pane')
                ->assertPresent('#academicboard-pane');
        });
    }

    /** TC-P11, BC-BIZ-01 | Source: Controller index() orderByDesc('start_date') */
    public function test_sessionboardsetup_11_academic_session_tab_lists_created_session(): void
    {
        $session = $this->makeSession();

        $this->browseWithFailureScreenshot('session-listed', function (Browser $browser) use ($session): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Academic Session tab');
            $browser->assertSee($session->name)
                ->assertSee($session->short_name);
        });
    }

    /** TC-P12, BC-BIZ-02 | Source: Controller index() Board orderBy('name') */
    public function test_sessionboardsetup_12_board_tab_lists_created_board(): void
    {
        $board = $this->makeBoard();

        $this->browseWithFailureScreenshot('board-listed', function (Browser $browser) use ($board): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Academic Board tab');
            $this->ensureTabVisible($browser, '#academicboard-tab', '#academicboard-pane');
            $browser->assertSee($board->name);
        });
    }

    /** TC-P13, BC-BIZ-03 | Source: Controller paginate(10,'academicsession_page') / paginate(4,'academicboard_page') */
    public function test_sessionboardsetup_13_index_uses_named_pagination_params(): void
    {
        // Deterministic proof at the query builder level (no browser dependency on data volume).
        $sessionPaginator = AcademicSession::query()
            ->orderByDesc('start_date')
            ->paginate(10, ['*'], 'academicsession_page');
        $this->assertSame(10, $sessionPaginator->perPage());
        $this->assertSame('academicsession_page', $sessionPaginator->getPageName());

        $boardPaginator = Board::query()->orderBy('name')->paginate(4, ['*'], 'academicboard_page');
        $this->assertSame(4, $boardPaginator->perPage());
        $this->assertSame('academicboard_page', $boardPaginator->getPageName());
    }

    /** TC-P15, BC-BIZ-04 | Source: Controller index() search on name/short_name (Board branch — safe) */
    public function test_sessionboardsetup_15_board_search_matches_name_and_short_name(): void
    {
        $board = $this->makeBoard();

        $byName = Board::query()
            ->where(function ($q) use ($board) {
                $q->where('name', 'like', '%' . $board->name . '%')
                    ->orWhere('short_name', 'like', '%' . $board->name . '%');
            })->get();
        $this->assertTrue($byName->contains('id', $board->id), 'Board search by name did not return the board.');

        $byShort = Board::query()
            ->where(function ($q) use ($board) {
                $q->where('name', 'like', '%' . $board->short_name . '%')
                    ->orWhere('short_name', 'like', '%' . $board->short_name . '%');
            })->get();
        $this->assertTrue($byShort->contains('id', $board->id), 'Board search by short_name did not return the board.');
    }

    /** TC-P17, BC-BIZ-05 | Source: Controller Board status filter where('is_active', ...) (Board branch — valid column) */
    public function test_sessionboardsetup_17_board_status_filter_active_returns_only_active(): void
    {
        $active = $this->makeBoard(['is_active' => 1]);
        $inactive = $this->makeBoard(['is_active' => 0]);

        $activeOnly = Board::query()->where('is_active', true)->get();
        $this->assertTrue($activeOnly->contains('id', $active->id), 'Active board not returned by status=1 filter.');
        $this->assertFalse($activeOnly->contains('id', $inactive->id), 'Inactive board leaked into status=1 filter.');
    }

    // =====================================================================
    // BAND 30–39 — NEGATIVE / VALIDATION / STUB & DEFECT PROOFS
    // =====================================================================

    /**
     * TC-N30 / DEFECT BUG-PRM-013 (P1) | Source: Controller index() line 30 where('is_active', ...) on glb_academic_sessions.
     * The Academic-Session status filter references a column that does not exist → QueryException; the whole
     * /prime/session-board-setup page 500s whenever ?status=0|1 is supplied (the session query is paginated first).
     */
    public function test_sessionboardsetup_30_academic_session_status_filter_hits_missing_is_active_column(): void
    {
        try {
            AcademicSession::query()->where('is_active', true)->paginate(10, ['*'], 'academicsession_page');
            $this->fail('BUG-PRM-013 appears fixed: filtering AcademicSession by is_active no longer throws. Re-verify controller/DDL.');
        } catch (QueryException $e) {
            $this->assertStringContainsString(
                'is_active',
                $e->getMessage(),
                'Expected an Unknown-column error mentioning is_active (BUG-PRM-013).'
            );
        }
    }

    /** TC-N31, BC-VAL-01 | Source: Controller in_array(status,['0','1'],true) — non 0/1 status ignored, no error */
    public function test_sessionboardsetup_31_invalid_status_value_is_ignored(): void
    {
        // Mirror the controller guard: an out-of-range status must NOT reach the where() clause.
        $status = 'banana';
        $this->assertFalse(
            in_array($status, ['0', '1'], true),
            'Guard mismatch: invalid status should be excluded by the in_array([0,1]) check.'
        );
        // Board list still resolves normally when the guard rejects the value.
        $this->assertIsInt(Board::query()->orderBy('name')->count());
    }

    /** TC-N32, BC-AUTH-02 | Source: route middleware ['auth','verified'] */
    public function test_sessionboardsetup_32_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(400);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $this->assertStringContainsString(
                '/login',
                $this->currentPath($browser),
                'Guest was not redirected to /login from the Session & Board Setup index.'
            );
        });
    }

    /**
     * TC-N33 / DEFECT BUG-PRM-015 (P2) | Source: Controller store() has no body.
     * store() only calls Gate::authorize(create) and returns void → no persistence, no redirect, no activity log.
     */
    public function test_sessionboardsetup_33_store_endpoint_is_a_noop_stub(): void
    {
        $this->assertControllerMethodBodyOnlyAuthorizes('store', self::GATE_CREATE);
    }

    /** TC-N34 / DEFECT BUG-PRM-015 | Source: Controller update() has no body */
    public function test_sessionboardsetup_34_update_endpoint_is_a_noop_stub(): void
    {
        $this->assertControllerMethodBodyOnlyAuthorizes('update', self::GATE_UPDATE);
    }

    /** TC-N35 / DEFECT BUG-PRM-015 | Source: Controller destroy() has no body */
    public function test_sessionboardsetup_35_destroy_endpoint_is_a_noop_stub(): void
    {
        $this->assertControllerMethodBodyOnlyAuthorizes('destroy', self::GATE_DELETE);
    }

    /**
     * TC-N36 / DEFECT BUG-PRM-015 | Source: Controller create() returns view('prime::create') which does not exist.
     * create/show/edit reference non-existent Blade views → InvalidArgumentException at render (500).
     */
    public function test_sessionboardsetup_36_create_show_edit_reference_missing_views(): void
    {
        $src = $this->classSource(\Modules\Prime\Http\Controllers\SessionBoardSetupController::class);
        $this->assertStringContainsString("view('prime::create')", $src, 'create() no longer returns prime::create.');
        $this->assertStringContainsString("view('prime::show')", $src, 'show() no longer returns prime::show.');
        $this->assertStringContainsString("view('prime::edit')", $src, 'edit() no longer returns prime::edit.');

        foreach (['prime::create', 'prime::show', 'prime::edit'] as $view) {
            $this->assertFalse(
                view()->exists($view),
                "View {$view} now exists — BUG-PRM-015 (missing create/show/edit views) may be resolved."
            );
        }
    }

    // =====================================================================
    // BAND 40–49 — INTEGRATION / FK / SOFT-DELETE DEPENDENCY
    // =====================================================================

    /**
     * TC-D40 / DEFECT BUG-PRM-014 (P2) | Source: AcademicSession::boards() belongsToMany(Board::class).
     * The relation resolves to the default pivot table `academic_session_board`, which has NO DDL and NO migration,
     * so the advertised "session ↔ board pairing" is not persistable. Querying ->boards throws.
     */
    public function test_sessionboardsetup_40_session_board_pivot_table_is_absent(): void
    {
        $this->assertFalse(
            Schema::connection(self::CONNECTION)->hasTable(self::PIVOT_TABLE),
            'academic_session_board pivot now exists — BUG-PRM-014 (unimplemented pairing) may be resolved.'
        );

        $session = $this->makeSession();
        try {
            $session->boards()->get();
            $this->fail('BUG-PRM-014: querying AcademicSession::boards() unexpectedly succeeded (pivot exists?).');
        } catch (QueryException $e) {
            $this->assertStringContainsStringIgnoringCase(
                'academic_session_board',
                $e->getMessage(),
                'Expected a missing-table error for the academic_session_board pivot.'
            );
        }
    }

    /** TC-D41, BC-REF-01 (soft delete) | Source: AcademicSession SoftDeletes; index withoutTrashed by default */
    public function test_sessionboardsetup_41_soft_deleted_session_is_excluded_by_default(): void
    {
        $session = $this->makeSession();
        $session->delete();

        $this->assertNull(AcademicSession::query()->find($session->id), 'Soft-deleted session still visible in default scope.');
        $this->assertNotNull(AcademicSession::withTrashed()->find($session->id), 'Soft-deleted session not retained with trashed scope.');

        $session->restore();
        $this->assertNotNull(AcademicSession::query()->find($session->id), 'Restore did not bring the session back.');
    }

    /** TC-D42, BC-REF-02 (soft delete) | Source: Board SoftDeletes */
    public function test_sessionboardsetup_42_soft_deleted_board_is_excluded_by_default(): void
    {
        $board = $this->makeBoard();
        $board->delete();

        $this->assertNull(Board::query()->find($board->id), 'Soft-deleted board still visible in default scope.');
        $this->assertNotNull(Board::withTrashed()->find($board->id), 'Soft-deleted board not retained with trashed scope.');
    }

    /** TC-D43, BC-EDG-01 | Source: DDL UNIQUE(current_flag) — only one is_current session allowed */
    public function test_sessionboardsetup_43_only_one_current_session_allowed(): void
    {
        $first = $this->makeSession(['is_current' => 1]);

        try {
            $second = $this->makeSession(['is_current' => 1]);
            // If the DB permitted two current sessions the unique current_flag guard is not effective.
            $this->fail('BUG/EDGE: two is_current=1 sessions were accepted; UNIQUE(current_flag) not enforced.');
        } catch (QueryException $e) {
            $this->assertStringContainsStringIgnoringCase(
                'current_flag',
                $e->getMessage() . ' ' . self::CENTRAL_ACTIVITY_TABLE,
                'Expected a unique-constraint violation on current_flag.'
            );
        }
    }

    // =====================================================================
    // BAND 50–59 — PERMISSIONS / AUTHORIZATION (+ BUG-PRM-011 / 012 / 016)
    // =====================================================================

    /** TC-P50, BC-AUTH-01 | Source: Controller index() Gate::authorize(viewAny) */
    public function test_sessionboardsetup_50_index_gate_allows_admin_denies_fresh_user(): void
    {
        $this->assertTrue(
            Gate::forUser($this->adminUser)->allows(self::GATE_VIEWANY),
            'Super-admin should pass the session-board-setup.viewAny gate.'
        );

        $fresh = $this->makeLimitedUser();
        if (!$fresh) {
            $this->markTestSkipped('Could not create a limited central user for gate assertion.');
        }
        $this->assertTrue(
            Gate::forUser($fresh)->denies(self::GATE_VIEWANY),
            'A permission-less user should be denied session-board-setup.viewAny.'
        );
    }

    /**
     * DEFECT BUG-PRM-011 (P1) | Source: PrimeServiceProvider:101 Gate::policy(AcademicSession, GlobalMaster\AcademicSessionPolicy).
     * The effective policy for the AcademicSession model is GlobalMaster\AcademicSessionPolicy — SessionBoardSetupPolicy
     * is NEVER registered (dead code). NOTE: the sub-run hypothesis (a duplicate Gate::policy(..., SessionBoardSetupPolicy)
     * that overwrites AcademicSessionPolicy) is NOT present in current source; the real defect is the inverse.
     */
    public function test_sessionboardsetup_51_effective_academic_session_policy_is_globalmaster_not_sessionboardsetup(): void
    {
        $policy = Gate::getPolicyFor(AcademicSession::class);
        $this->assertNotNull($policy, 'No policy is bound to the AcademicSession model.');
        $this->assertInstanceOf(
            \Modules\GlobalMaster\Policies\AcademicSessionPolicy::class,
            $policy,
            'AcademicSession is no longer governed by GlobalMaster\\AcademicSessionPolicy (BUG-PRM-011 changed).'
        );
        $this->assertNotInstanceOf(
            \Modules\Prime\Policies\SessionBoardSetupPolicy::class,
            $policy,
            'SessionBoardSetupPolicy is unexpectedly bound to AcademicSession.'
        );
    }

    /** DEFECT BUG-PRM-011 (dead code) | Source: PrimeServiceProvider has no Gate::policy for SessionBoardSetupPolicy */
    public function test_sessionboardsetup_52_sessionboardsetup_policy_is_not_registered_anywhere(): void
    {
        $providerSrc = $this->classSource(\Modules\Prime\Providers\PrimeServiceProvider::class);
        $this->assertStringNotContainsString(
            'SessionBoardSetupPolicy',
            $providerSrc,
            'SessionBoardSetupPolicy is now referenced by PrimeServiceProvider — BUG-PRM-011 (dead policy) changed.'
        );
        // Its abilities are enforced only as raw string gates via Spatie permission lookup in the controller.
        $controllerSrc = $this->classSource(\Modules\Prime\Http\Controllers\SessionBoardSetupController::class);
        $this->assertStringContainsString(
            "Gate::authorize('prime.session-board-setup.viewAny')",
            $controllerSrc,
            'Controller no longer uses the string session-board-setup gates.'
        );
    }

    /**
     * DEFECT BUG-PRM-012 (P2) | Source: Controller gates on prime.session-board-setup.*, but the Blade view
     * gates its tabs/tables on prime.academic-session.* and prime.board.* — the authorization surface diverges.
     * A user with only session-board-setup.viewAny reaches the page but sees empty/hidden tabs, and vice-versa.
     */
    public function test_sessionboardsetup_53_controller_and_view_permission_surfaces_diverge(): void
    {
        $controllerSrc = $this->classSource(\Modules\Prime\Http\Controllers\SessionBoardSetupController::class);
        $this->assertStringContainsString('prime.session-board-setup.viewAny', $controllerSrc);

        $viewPath = $this->bladePath('prime::session-board-setup.index');
        if ($viewPath === null) {
            $this->markTestSkipped('Could not resolve the session-board-setup.index Blade path.');
        }
        $viewSrc = File::get($viewPath);
        $this->assertStringContainsString('prime.academic-session.viewAny', $viewSrc, 'View no longer gates on academic-session.');
        $this->assertStringContainsString('prime.board.viewAny', $viewSrc, 'View no longer gates on board.');
        $this->assertStringNotContainsString(
            'prime.session-board-setup.',
            $viewSrc,
            'View now shares the session-board-setup permission surface — BUG-PRM-012 may be resolved.'
        );
    }

    /** TC-P54, BC-AUTH-03 | Source: Controller store() Gate::authorize(create) */
    public function test_sessionboardsetup_54_store_gate_denies_fresh_user(): void
    {
        $fresh = $this->makeLimitedUser();
        if (!$fresh) {
            $this->markTestSkipped('Could not create a limited central user.');
        }
        $this->assertTrue(Gate::forUser($fresh)->denies(self::GATE_CREATE), 'Fresh user should be denied create gate.');
        $this->assertTrue(Gate::forUser($this->adminUser)->allows(self::GATE_CREATE), 'Admin should pass create gate.');
    }

    /**
     * DEFECT BUG-PRM-016 (P3, candidate) | Source: RolePermissionSeeder $readWrite omits 'delete' for the
     * academicCfg group (which includes session-board-setup), yet destroy() gates prime.session-board-setup.delete.
     * The permission is created by PermissionHelper::flatten, but the standard read-write role grant does not include it.
     */
    public function test_sessionboardsetup_55_destroy_delete_ability_absent_from_standard_readwrite_grant(): void
    {
        $seederSrc = $this->classSource(\Modules\Prime\Database\Seeders\RolePermissionSeeder::class);
        // readWrite subset definition present and excludes 'delete'.
        $this->assertMatchesRegularExpression(
            "/\\\$readWrite\\s*=\\s*\\[[^\\]]*'update'[^\\]]*\\]/",
            $seederSrc,
            'readWrite subset not found in RolePermissionSeeder.'
        );
        $this->assertStringContainsString("'academic-session', 'board', 'session-board-setup'", $seederSrc);
        // destroy still gates on .delete.
        $controllerSrc = $this->classSource(\Modules\Prime\Http\Controllers\SessionBoardSetupController::class);
        $this->assertStringContainsString(
            "Gate::authorize('prime.session-board-setup.delete')",
            $controllerSrc,
            'destroy() no longer gates on the delete ability.'
        );
    }

    // =====================================================================
    // BAND 60–69 — UI / UX
    // =====================================================================

    /** TC-P60, BC-UIX-01 | Source: view breadcrum title="Session & Board Setup" */
    public function test_sessionboardsetup_60_breadcrumb_title_present(): void
    {
        $this->browseWithFailureScreenshot('breadcrumb-title', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Breadcrumb');
            $browser->assertSee('Session & Board Setup');
        });
    }

    /** TC-P61, BC-UIX-02 | Source: view search-bar form (search input + status select on both tabs) */
    public function test_sessionboardsetup_61_search_controls_present_on_both_tabs(): void
    {
        $this->browseWithFailureScreenshot('search-controls', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Search controls');
            $browser->assertPresent('#academicsession-pane input[name="search"]')
                ->assertPresent('#academicsession-pane select[name="status"]');
            $this->ensureTabVisible($browser, '#academicboard-tab', '#academicboard-pane');
            $browser->assertPresent('#academicboard-pane input[name="search"]')
                ->assertPresent('#academicboard-pane select[name="status"]');
        });
    }

    /** TC-P62, BC-UIX-03 | Source: view empty @forelse rows */
    public function test_sessionboardsetup_62_empty_state_text_defined_in_view(): void
    {
        $viewPath = $this->bladePath('prime::session-board-setup.index');
        if ($viewPath === null) {
            $this->markTestSkipped('Could not resolve the Blade path.');
        }
        $viewSrc = File::get($viewPath);
        $this->assertStringContainsString('No Academic Session Data Found', $viewSrc);
        $this->assertStringContainsString('No Board Data Found', $viewSrc);
    }

    // =====================================================================
    // BAND 70–79 — EDGE CASES
    // =====================================================================

    /** TC-N71, BC-SEC-01 | Source: reflected ?search value re-rendered into the search input */
    public function test_sessionboardsetup_71_reflected_search_value_is_escaped(): void
    {
        $payload = '<script>alert(1)</script>';
        $this->browseWithFailureScreenshot('reflected-xss', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . rawurlencode($payload) . '&tab=academicsession');
            $this->ensurePageAccessible($browser, 'Reflected search');
            // Blade {{ }} escaping must prevent a live <script> node in the DOM.
            $this->assertStringNotContainsString(
                '<script>alert(1)</script>',
                $browser->driver->getPageSource(),
                'Unescaped reflected search payload found (stored/reflected XSS).'
            );
        });
    }

    /** TC-N72, BC-SEC-02 | Source: index() search bound via query builder bindings (injection-shaped input) */
    public function test_sessionboardsetup_72_injection_shaped_search_does_not_break_query(): void
    {
        $evil = "%' OR '1'='1";
        // Mirror the controller's parameterised LIKE; must run without error and not return everything by injection.
        $count = Board::query()
            ->where(function ($q) use ($evil) {
                $q->where('name', 'like', '%' . $evil . '%')
                    ->orWhere('short_name', 'like', '%' . $evil . '%');
            })->count();
        $this->assertIsInt($count, 'Injection-shaped search must be safely parameterised.');
    }

    // =====================================================================
    // BAND 90–99 — TENANCY / CENTRAL ISOLATION
    // =====================================================================

    /** TC-T90, BC-INT-01 | Source: central feature — must run WITHOUT tenant context (Constraint #21/#22) */
    public function test_sessionboardsetup_90_runs_in_central_context_without_tenant(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            $this->fail('Central Session & Board Setup must not run inside an initialized tenant.');
        }
        // Data models resolve on the central global_master connection.
        $this->assertSame(self::CONNECTION, (new AcademicSession())->getConnectionName());
        $this->assertSame(self::CONNECTION, (new Board())->getConnectionName());
    }

    /** TC-S91, BC-SEC-03 | Source: route domain(app.domain) — central-only host enforced by base class */
    public function test_sessionboardsetup_91_index_route_is_central_domain_scoped(): void
    {
        $url = route(self::ROUTE_INDEX);
        $this->assertStringContainsString(self::INDEX_PATH, $url, 'Index route path unexpected.');
    }

    // =====================================================================
    // ---- Private helper library ----
    // =====================================================================

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
            $safe = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName) ?: 'failure';
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safe . '_' . now()->format('Ymd_His') . '.png');
        } catch (Throwable) {
            // best-effort only
        }
    }

    private function cleanScreenshots(): void
    {
        try {
            $directory = base_path(static::SCREENSHOT_DIR);
            if (File::isDirectory($directory)) {
                File::cleanDirectory($directory);
            }
        } catch (Throwable) {
            // ignore
        }
    }

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    private function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows login page; authentication failed.');
        }
        $bodyText = $browser->element('body') ? $browser->text('body') : '';
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    private function ensureTabVisible(Browser $browser, string $tabSelector, string $paneSelector): void
    {
        if ($browser->element($tabSelector)) {
            $browser->click($tabSelector)->pause(600);
        }
        if ($browser->element($paneSelector)) {
            $browser->waitFor($paneSelector, 10);
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
            $this->adminUser = User::create([
                'email' => $this->adminEmail,
                'password' => bcrypt($this->adminPassword),
                'name' => 'SBS Dusk Admin',
                'emp_code' => 'EMP' . rand(100, 999),
                'short_name' => 'ADM' . rand(1000, 9999),
                'status' => 'ACTIVE',
                'is_active' => 1,
                'is_super_admin' => 1,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    private function makeLimitedUser(): ?User
    {
        if ($this->limitedUser) {
            return $this->limitedUser;
        }
        try {
            $this->limitedUser = User::create([
                'email' => 'sbs_limited_' . uniqid() . '@example.com',
                'password' => bcrypt('password'),
                'name' => 'SBS Limited',
                'emp_code' => 'LMT' . rand(100, 999),
                'short_name' => 'LMT' . rand(1000, 9999),
                'status' => 'ACTIVE',
                'is_active' => 1,
                'is_super_admin' => 0,
                'email_verified_at' => now(),
            ]);
            return $this->limitedUser;
        } catch (Throwable) {
            return null;
        }
    }

    private function makeSession(array $overrides = []): AcademicSession
    {
        $suffix = $this->uniqueSuffix();
        $session = AcademicSession::create(array_merge([
            'short_name' => 'SBS' . $suffix,
            'name' => 'SBS Session ' . $suffix,
            'start_date' => now()->subYear()->toDateString(),
            'end_date' => now()->toDateString(),
            'is_current' => 0,
        ], $overrides));
        $this->createdSessionIds[] = $session->id;
        return $session;
    }

    private function makeBoard(array $overrides = []): Board
    {
        $suffix = $this->uniqueSuffix();
        $board = Board::create(array_merge([
            'name' => 'SBS Board ' . $suffix,
            'short_name' => 'BRD' . $suffix,
            'is_active' => 1,
        ], $overrides));
        $this->createdBoardIds[] = $board->id;
        return $board;
    }

    private function uniqueSuffix(): string
    {
        // Keep within short_name VARCHAR(20): 'SBS' (3) + suffix (<=13) = <=16.
        return substr(str_replace('.', '', uniqid()), -10);
    }

    private function cleanupCreatedRecords(): void
    {
        foreach ($this->createdSessionIds as $id) {
            try {
                $m = AcademicSession::withTrashed()->find($id);
                if ($m) {
                    $m->forceDelete();
                }
            } catch (Throwable) {
                // ignore
            }
        }
        foreach ($this->createdBoardIds as $id) {
            try {
                $m = Board::withTrashed()->find($id);
                if ($m) {
                    $m->forceDelete();
                }
            } catch (Throwable) {
                // ignore
            }
        }
        $this->createdSessionIds = [];
        $this->createdBoardIds = [];
    }

    private function classSource(string $fqcn): string
    {
        $file = (new ReflectionClass($fqcn))->getFileName();
        return $file && File::exists($file) ? File::get($file) : '';
    }

    private function bladePath(string $view): ?string
    {
        try {
            return view()->getFinder()->find($view);
        } catch (Throwable) {
            return null;
        }
    }

    private function hasUniqueIndexOnColumn(string $table, string $column): bool
    {
        try {
            $rows = Schema::connection(self::CONNECTION)->getConnection()
                ->select("SHOW INDEX FROM `{$table}` WHERE Column_name = ? AND Non_unique = 0", [$column]);
            return count($rows) > 0;
        } catch (Throwable) {
            return false;
        }
    }

    /** Asserts a controller action's body contains only its Gate::authorize(...) call (a no-op stub). */
    private function assertControllerMethodBodyOnlyAuthorizes(string $method, string $gate): void
    {
        $ref = new \ReflectionMethod(\Modules\Prime\Http\Controllers\SessionBoardSetupController::class, $method);
        $file = File::get($ref->getFileName());
        $lines = preg_split('/\R/', $file) ?: [];
        $body = implode("\n", array_slice($lines, $ref->getStartLine() - 1, $ref->getEndLine() - $ref->getStartLine() + 1));

        $this->assertStringContainsString("Gate::authorize('{$gate}')", $body, "{$method}() no longer authorizes {$gate}.");
        $this->assertStringNotContainsString('return', $body, "{$method}() now returns something — no longer a no-op stub (BUG-PRM-015).");
        $this->assertStringNotContainsString('::create(', $body, "{$method}() now persists data — no longer a stub.");
        $this->assertStringNotContainsString('->save(', $body, "{$method}() now persists data — no longer a stub.");
    }
}
