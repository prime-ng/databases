<?php

namespace Tests\Browser\Modules\Prime\GlobalMaster;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * V2 (Comprehensive) — GlobalMaster :: Session & Board Setup (composite / read-only hub).
 *
 * DB SCOPE: CENTRAL / prime-side (global_master DB, connection global_master_mysql). NO tenant init.
 * STYLE: browser Dusk CENTRAL pattern, extends prm_PrimeDuskTestCase_TestCas (alias PrimeDuskTestCase),
 * host forced to http://127.0.0.1:8000.
 *
 * This is a READ-FOCUSED, PARTLY-BROKEN hub: no CRUD matrix (store/update/destroy are empty stubs,
 * create/show/edit views are missing). Coverage therefore concentrates on schema truth, model &
 * route/permission config, render, empty-state, and the documented defect set:
 *   BUG-GLB-001  model-resolution reconciliation (audit vs live)
 *   DATA-GLB-002 view reads $session->is_active — absent column
 *   BUG-GLB-003  single-current invariant DB-only (current_flag UNIQUE); store() no-op
 *   BUG-GLB-004  view route-name mismatch (central.global-master.* vs global-master.*)
 *   BUG-GLB-005  dual controller collision (GlobalMaster vs Prime bind session-board-setup)
 *   BUG-GLB-006  missing create/show/edit views + empty write stubs
 *
 * Cross-tenant isolation cases are N/A (CENTRAL / single global_master DB) — see test_92.
 */
class glb_SessionBoardSetupV2_TestCas extends PrimeDuskTestCase
{
    private const INDEX_PATH   = '/global-master/session-board-setup';
    private const INDEX_ROUTE  = 'global-master.session-board-setup.index';
    private const CONNECTION    = 'global_master_mysql';
    private const SESSIONS_TABLE = 'glb_academic_sessions';
    private const BOARDS_TABLE   = 'glb_boards';

    private const ACADEMIC_SESSION_MODEL     = 'Modules\\Prime\\Models\\AcademicSession';
    private const BOARD_MODEL                = 'Modules\\GlobalMaster\\Models\\Board';
    private const GLOBALMASTER_SESSION_MODEL = 'Modules\\GlobalMaster\\Models\\AcademicSession';

    private const GM_CONTROLLER    = 'Modules\\GlobalMaster\\Http\\Controllers\\SessionBoardSetupController';
    private const PRIME_CONTROLLER = 'Modules\\Prime\\Http\\Controllers\\SessionBoardSetupController';

    private const GM_CONTROLLER_REL = '/Modules/GlobalMaster/app/Http/Controllers/SessionBoardSetupController.php';
    private const GM_VIEWS_REL      = '/Modules/GlobalMaster/resources/views';
    private const GM_MIGRATIONS_REL = '/Modules/GlobalMaster/database/migrations';

    private ?User $adminUser = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
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
        parent::tearDown();
    }

    // ===================================================================
    // 01-09 :: Schema / DDL / model / route configuration
    // ===================================================================

    public function test_sessionboardsetup_01_academic_sessions_table_columns(): void
    {
        $schema = $this->schemaOrSkip();
        $this->assertTrue($schema->hasTable(self::SESSIONS_TABLE));
        $this->assertTrue($schema->hasColumns(self::SESSIONS_TABLE, [
            'id', 'short_name', 'name', 'start_date', 'end_date',
            'is_current', 'current_flag', 'deleted_at', 'created_at', 'updated_at',
        ]));
    }

    public function test_sessionboardsetup_02_boards_table_columns(): void
    {
        $schema = $this->schemaOrSkip();
        $this->assertTrue($schema->hasTable(self::BOARDS_TABLE));
        $this->assertTrue($schema->hasColumns(self::BOARDS_TABLE, [
            'id', 'name', 'short_name', 'is_active', 'created_at', 'updated_at', 'deleted_at',
        ]));
    }

    public function test_sessionboardsetup_03_academic_sessions_unique_keys(): void
    {
        $indexes = $this->indexNamesOrSkip(self::SESSIONS_TABLE);
        $this->assertContains('uq_glb_acadsessions_shortname', $indexes, 'Missing unique key on short_name.');
        $this->assertContains('uq_glb_acadsession_currentflag', $indexes, 'Missing unique key on current_flag (single-current invariant).');
    }

    public function test_sessionboardsetup_04_boards_unique_keys(): void
    {
        $indexes = $this->indexNamesOrSkip(self::BOARDS_TABLE);
        $this->assertContains('uq_glb_academicboard_name', $indexes, 'Missing unique key on board name.');
        $this->assertContains('uq_glb_academicboard_shortname', $indexes, 'Missing unique key on board short_name.');
    }

    public function test_sessionboardsetup_05_migration_files_present_and_shaped(): void
    {
        $appRoot = $this->appRootOrSkip();
        $migDir = $appRoot . self::GM_MIGRATIONS_REL;

        $sessions = File::glob($migDir . '/*_create_academic_sessions_table.php');
        $boards = File::glob($migDir . '/*_create_boards_table.php');
        $this->assertNotEmpty($sessions, 'create_academic_sessions_table migration missing.');
        $this->assertNotEmpty($boards, 'create_boards_table migration missing.');

        $sessionsSrc = File::get($sessions[0]);
        $this->assertStringContainsString('short_name', $sessionsSrc);
        $this->assertStringContainsString('is_current', $sessionsSrc);
    }

    public function test_sessionboardsetup_06_academic_session_model_full_config(): void
    {
        $model = $this->modelOrSkip(self::ACADEMIC_SESSION_MODEL);
        $this->assertSame(self::SESSIONS_TABLE, $model->getTable());
        $this->assertSame(self::CONNECTION, $model->getConnectionName());
        $this->assertSame(['short_name', 'name', 'start_date', 'end_date', 'is_current'], array_values($model->getFillable()));
        $casts = $model->getCasts();
        $this->assertSame('date', $casts['start_date'] ?? null);
        $this->assertSame('boolean', $casts['is_current'] ?? null);
        $this->assertTrue($this->usesSoftDeletes(self::ACADEMIC_SESSION_MODEL));
    }

    public function test_sessionboardsetup_07_board_model_full_config(): void
    {
        $model = $this->modelOrSkip(self::BOARD_MODEL);
        $this->assertSame(self::BOARDS_TABLE, $model->getTable());
        $this->assertSame(self::CONNECTION, $model->getConnectionName());
        $this->assertSame(['name', 'short_name', 'is_active'], array_values($model->getFillable()));
        $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null);
        $this->assertTrue($this->usesSoftDeletes(self::BOARD_MODEL));
    }

    public function test_sessionboardsetup_08_hub_route_registered_with_expected_path(): void
    {
        if (!Route::has(self::INDEX_ROUTE)) {
            $this->markTestSkipped('Route not registered — enable GlobalMaster in modules_statuses.json.');
        }
        $uri = Route::getRoutes()->getByName(self::INDEX_ROUTE)?->uri();
        $this->assertSame('global-master/session-board-setup', $uri);
    }

    public function test_sessionboardsetup_09_controller_resource_methods_exist(): void
    {
        $this->assertTrue(class_exists(self::GM_CONTROLLER));
        foreach (['index', 'create', 'store', 'show', 'edit', 'update', 'destroy'] as $m) {
            $this->assertTrue(method_exists(self::GM_CONTROLLER, $m), "Controller missing {$m}().");
        }
    }

    // ===================================================================
    // 10-19 :: Business rules (read-only listing behaviour)
    // ===================================================================

    public function test_sessionboardsetup_10_index_paginates_ten_per_list(): void
    {
        $src = $this->controllerSourceOrSkip();
        $this->assertStringContainsString('AcademicSession::paginate(10)', $src, 'Sessions list should paginate(10).');
        $this->assertStringContainsString('Board::paginate(10)', $src, 'Boards list should paginate(10).');
    }

    public function test_sessionboardsetup_11_index_returns_hub_view_with_both_datasets(): void
    {
        $src = $this->controllerSourceOrSkip();
        $this->assertStringContainsString("compact('academicSessions','boards')", $src);
        $this->assertStringContainsString("globalmaster::session-board-setup.index", $src);
    }

    public function test_sessionboardsetup_12_hub_view_uses_nav_tab_component(): void
    {
        $view = $this->viewSourceOrSkip('/session-board-setup/index.blade.php');
        $this->assertStringContainsString('x-backend.tab.nav-tab', $view, 'Hub should render the nav-tab tabs component.');
        $this->assertStringContainsString("'id' => 'academicsession'", $view);
        $this->assertStringContainsString("'id' => 'academicboard'", $view);
    }

    // ===================================================================
    // 30-39 :: Broken write surface (proving no-op / missing views)
    // ===================================================================

    public function test_sessionboardsetup_30_store_is_empty_stub(): void
    {
        $this->assertMatchesRegularExpression('/public function store\([^)]*\)\s*\{\s*\}/', $this->controllerSourceOrSkip());
    }

    public function test_sessionboardsetup_31_update_is_empty_stub(): void
    {
        $this->assertMatchesRegularExpression('/public function update\([^)]*\)\s*\{\s*\}/', $this->controllerSourceOrSkip());
    }

    public function test_sessionboardsetup_32_destroy_is_empty_stub(): void
    {
        $this->assertMatchesRegularExpression('/public function destroy\([^)]*\)\s*\{\s*\}/', $this->controllerSourceOrSkip());
    }

    public function test_sessionboardsetup_33_create_view_missing(): void
    {
        $src = $this->controllerSourceOrSkip();
        $this->assertStringContainsString("view('globalmaster::create')", $src, 'create() returns globalmaster::create.');
        $appRoot = $this->appRootOrSkip();
        $this->assertFalse(
            File::exists($appRoot . self::GM_VIEWS_REL . '/create.blade.php'),
            'BUG-GLB-006: globalmaster::create view should NOT exist → 500.'
        );
    }

    public function test_sessionboardsetup_34_show_view_missing(): void
    {
        $appRoot = $this->appRootOrSkip();
        $this->assertStringContainsString("view('globalmaster::show')", $this->controllerSourceOrSkip());
        $this->assertFalse(File::exists($appRoot . self::GM_VIEWS_REL . '/show.blade.php'));
    }

    public function test_sessionboardsetup_35_edit_view_missing(): void
    {
        $appRoot = $this->appRootOrSkip();
        $this->assertStringContainsString("view('globalmaster::edit')", $this->controllerSourceOrSkip());
        $this->assertFalse(File::exists($appRoot . self::GM_VIEWS_REL . '/edit.blade.php'));
    }

    // ===================================================================
    // 40-49 :: Integration / relationships (FK / cross-module)
    // ===================================================================

    public function test_sessionboardsetup_40_board_has_organizations_relationship(): void
    {
        $model = $this->modelOrSkip(self::BOARD_MODEL);
        $this->assertTrue(method_exists($model, 'organizations'));
        try {
            $rel = $model->organizations();
            $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsToMany::class, $rel);
        } catch (Throwable $e) {
            $this->markTestSkipped('organizations() relationship requires SchoolSetup module: ' . $e->getMessage());
        }
    }

    public function test_sessionboardsetup_41_academic_session_has_boards_relationship(): void
    {
        $model = $this->modelOrSkip(self::ACADEMIC_SESSION_MODEL);
        $this->assertTrue(method_exists($model, 'boards'), 'AcademicSession should define boards().');
    }

    public function test_sessionboardsetup_42_board_organization_junction_migration_present(): void
    {
        $appRoot = $this->appRootOrSkip();
        $migs = File::glob($appRoot . self::GM_MIGRATIONS_REL . '/*_create_board_organization_table.php');
        $this->assertNotEmpty($migs, 'board_organization junction migration expected.');
    }

    // ===================================================================
    // 50-59 :: Permissions / authorization
    // ===================================================================

    public function test_sessionboardsetup_50_index_gate_is_prime_board_viewany(): void
    {
        $src = $this->controllerSourceOrSkip();
        $this->assertStringContainsString('prime.board.viewAny', $src);
        $this->assertStringContainsString('abort(403)', $src);
    }

    public function test_sessionboardsetup_51_session_tab_gated_by_academic_session_viewany(): void
    {
        $view = $this->viewSourceOrSkip('/session-board-setup/index.blade.php');
        $this->assertStringContainsString("@can('prime.academic-session.viewAny')", $view);
    }

    public function test_sessionboardsetup_52_board_tab_gated_by_board_viewany(): void
    {
        $view = $this->viewSourceOrSkip('/session-board-setup/index.blade.php');
        $this->assertStringContainsString("@can('prime.board.viewAny')", $view);
    }

    public function test_sessionboardsetup_53_board_policy_permission_keys(): void
    {
        $appRoot = $this->appRootOrSkip();
        $policy = $appRoot . '/Modules/GlobalMaster/app/Policies/BoardPolicy.php';
        if (!File::exists($policy)) {
            $this->markTestSkipped('BoardPolicy not present.');
        }
        $src = File::get($policy);
        foreach (['prime.board.viewAny', 'prime.board.view', 'prime.board.update', 'prime.board.delete'] as $perm) {
            $this->assertStringContainsString($perm, $src, "BoardPolicy should reference {$perm}.");
        }
    }

    public function test_sessionboardsetup_54_academic_session_policy_permission_keys(): void
    {
        $appRoot = $this->appRootOrSkip();
        $policy = $appRoot . '/Modules/GlobalMaster/app/Policies/AcademicSessionPolicy.php';
        if (!File::exists($policy)) {
            $this->markTestSkipped('AcademicSessionPolicy not present.');
        }
        $this->assertStringContainsString('prime.academic-session.viewAny', File::get($policy));
    }

    public function test_sessionboardsetup_55_guest_redirected_to_login(): void
    {
        $this->skipUnlessRouteLive();
        $this->browseSafe('guest_redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(500);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    public function test_sessionboardsetup_56_admin_can_open_hub(): void
    {
        $this->skipUnlessRouteLive();
        $this->browseSafe('admin_render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->assertNotSame('/login', $this->currentPath($browser));
        });
    }

    // ===================================================================
    // 60-69 :: UI/UX (tabs, empty state, pagination)
    // ===================================================================

    public function test_sessionboardsetup_60_hub_renders_both_tab_labels(): void
    {
        $this->skipUnlessRouteLive();
        $this->browseSafe('tab_labels', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $body = (string) $browser->text('body');
            $this->assertTrue(
                str_contains($body, 'Academic Session') || str_contains($body, 'Session & Board Setup'),
                'Expected hub tab labels/heading.'
            );
        });
    }

    public function test_sessionboardsetup_61_empty_state_marker_present_in_view(): void
    {
        $view = $this->viewSourceOrSkip('/session-board-setup/index.blade.php');
        // Both tables render the (typo'd) empty-state text — assert the literal string from source.
        $this->assertStringContainsString('Not Data Found', $view, 'Empty-state marker text must match source verbatim.');
        $this->assertStringContainsString('@empty', $view);
    }

    public function test_sessionboardsetup_62_pagination_links_rendered_in_view(): void
    {
        $view = $this->viewSourceOrSkip('/session-board-setup/index.blade.php');
        $this->assertStringContainsString('$academicSessions->links()', $view);
        $this->assertStringContainsString('$boards->links()', $view);
    }

    // ===================================================================
    // 70-79 :: Edge cases / documented defects
    // ===================================================================

    public function test_sessionboardsetup_70_bug_glb_001_model_resolution_reconciliation(): void
    {
        // Reconcile audit BUG-GLB-001 against live source.
        $this->assertTrue(class_exists(self::ACADEMIC_SESSION_MODEL), 'Prime AcademicSession must exist (live import).');
        $this->assertFalse(class_exists(self::GLOBALMASTER_SESSION_MODEL), 'GlobalMaster AcademicSession must NOT exist.');
        $this->assertTrue(class_exists(self::BOARD_MODEL), 'GlobalMaster Board must exist.');
        // Live controller imports the Prime model, so the 500 the audit predicted does NOT reproduce here.
        $this->assertStringContainsString('use Modules\\Prime\\Models\\AcademicSession;', $this->controllerSourceOrSkip());
    }

    public function test_sessionboardsetup_71_data_glb_002_is_active_absent_from_sessions(): void
    {
        $schema = $this->schemaOrSkip();
        $this->assertFalse($schema->hasColumn(self::SESSIONS_TABLE, 'is_active'), 'DATA-GLB-002: is_active must be absent.');
    }

    public function test_sessionboardsetup_72_data_glb_002_view_reads_phantom_is_active(): void
    {
        // The view reads $session->is_active though the column does not exist → silently null (row highlight never applies).
        $view = $this->viewSourceOrSkip('/session-board-setup/index.blade.php');
        $this->assertStringContainsString('$session->is_active', $view, 'View reads a non-existent attribute (phantom is_active).');
    }

    public function test_sessionboardsetup_73_bug_glb_003_single_current_is_db_only(): void
    {
        // Invariant enforced by generated current_flag + UNIQUE index; store() sets nothing.
        $indexes = $this->indexNamesOrSkip(self::SESSIONS_TABLE);
        $this->assertContains('uq_glb_acadsession_currentflag', $indexes);
        $this->assertMatchesRegularExpression('/public function store\([^)]*\)\s*\{\s*\}/', $this->controllerSourceOrSkip());
    }

    public function test_sessionboardsetup_74_bug_glb_004_view_route_name_mismatch(): void
    {
        $view = $this->viewSourceOrSkip('/session-board-setup/index.blade.php');
        // The view mixes 'central.global-master.*' and 'global-master.*' route-name prefixes.
        $this->assertStringContainsString('central.global-master.academic-session', $view);
        $this->assertStringContainsString('global-master.academic-session', $view);
        $this->assertStringContainsString('central.global-master.board', $view);
    }

    public function test_sessionboardsetup_75_bug_glb_005_dual_controller_collision(): void
    {
        $this->assertTrue(class_exists(self::GM_CONTROLLER));
        $this->assertTrue(class_exists(self::PRIME_CONTROLLER));
        // Divergent gates prove they are genuinely different bindings, not a shared handler.
        $primeSrc = $this->fileOrSkip('/Modules/Prime/app/Http/Controllers/SessionBoardSetupController.php');
        $this->assertStringContainsString("Gate::authorize('prime.session-board-setup.viewAny')", $primeSrc);
        $this->assertStringContainsString('prime.board.viewAny', $this->controllerSourceOrSkip());
    }

    public function test_sessionboardsetup_76_bug_glb_004_mismatched_central_route_not_registered(): void
    {
        if (!Route::has(self::INDEX_ROUTE)) {
            $this->markTestSkipped('Routes not loaded — enable GlobalMaster.');
        }
        // The view references central.global-master.academic-session.* which the GlobalMaster
        // module registers under 'global-master.' (no 'central.' prefix) → likely unregistered.
        $this->assertFalse(
            Route::has('central.global-master.academic-session.index'),
            'BUG-GLB-004: view route-name prefix does not match registered route names.'
        );
    }

    // ===================================================================
    // 90-99 :: Security + tenancy pack
    // ===================================================================

    public function test_sessionboardsetup_90_search_query_param_renders_safely(): void
    {
        $this->skipUnlessRouteLive();
        $this->browseSafe('xss_search', function (Browser $browser): void {
            $payload = '<script>alert(1)</script>';
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . rawurlencode($payload));
            $source = (string) $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Reflected search input must be escaped.');
        });
    }

    public function test_sessionboardsetup_91_hub_is_read_only_no_write_endpoints_registered(): void
    {
        if (!Route::has(self::INDEX_ROUTE)) {
            $this->markTestSkipped('Routes not loaded — enable GlobalMaster.');
        }
        // Resource registers store/update/destroy names, but handlers are no-ops.
        // Assert the store route exists (registered) yet the handler is empty (proven at test_30).
        $this->assertTrue(Route::has('global-master.session-board-setup.store'));
    }

    public function test_sessionboardsetup_92_cross_tenant_isolation_not_applicable_central(): void
    {
        // Documented deliberate skip: glb_* tables live in the single central `global_master`
        // database (connection global_master_mysql). There is no per-tenant copy, so cross-tenant
        // invisibility / IDOR-across-tenant assertions do not apply to this feature.
        $model = $this->modelOrSkip(self::BOARD_MODEL);
        $this->assertSame(self::CONNECTION, $model->getConnectionName(), 'Board is bound to the central global_master connection.');
        $this->markTestSkipped('Cross-tenant isolation N/A — Session & Board Setup is a CENTRAL (global_master) feature.');
    }

    // ===================================================================
    // Private helper library
    // ===================================================================

    private function schemaOrSkip(): \Illuminate\Database\Schema\Builder
    {
        try {
            $schema = Schema::connection(self::CONNECTION);
            $schema->hasTable(self::SESSIONS_TABLE);
            return $schema;
        } catch (Throwable $e) {
            $this->markTestSkipped('global_master connection unavailable: ' . $e->getMessage());
        }
    }

    private function indexNamesOrSkip(string $table): array
    {
        try {
            $names = Schema::connection(self::CONNECTION)
                ->getConnection()
                ->getDoctrineSchemaManager()
                ->listTableIndexes($table);
            return array_map('strtolower', array_keys($names));
        } catch (Throwable $e) {
            // Fallback: query information_schema directly (Doctrine may be absent).
            try {
                $rows = Schema::connection(self::CONNECTION)->getConnection()
                    ->select('SHOW INDEX FROM ' . $table);
                return array_values(array_unique(array_map(
                    static fn ($r) => strtolower($r->Key_name),
                    $rows
                )));
            } catch (Throwable $e2) {
                $this->markTestSkipped('Cannot introspect indexes for ' . $table . ': ' . $e2->getMessage());
            }
        }
    }

    private function modelOrSkip(string $class): \Illuminate\Database\Eloquent\Model
    {
        if (!class_exists($class)) {
            $this->markTestSkipped("Model {$class} not autoloadable.");
        }
        return new $class();
    }

    private function usesSoftDeletes(string $class): bool
    {
        if (!class_exists($class)) {
            return false;
        }
        return in_array(\Illuminate\Database\Eloquent\SoftDeletes::class, class_uses_recursive($class), true);
    }

    private function appRootOrSkip(): string
    {
        $candidates = array_filter([
            env('MAIN_PROJECT_PATH'),
            base_path('../prime_ai'),
            '/Users/bkwork/Herd/prime_ai',
        ]);

        foreach ($candidates as $root) {
            if (is_string($root) && is_dir($root . '/Modules/GlobalMaster')) {
                return rtrim($root, '/');
            }
        }
        $this->markTestSkipped('prime_ai app source not locatable (set MAIN_PROJECT_PATH).');
    }

    private function controllerSourceOrSkip(): string
    {
        return $this->fileOrSkip(self::GM_CONTROLLER_REL);
    }

    private function viewSourceOrSkip(string $relativeUnderViews): string
    {
        return $this->fileOrSkip(self::GM_VIEWS_REL . $relativeUnderViews);
    }

    private function fileOrSkip(string $relativeToAppRoot): string
    {
        $appRoot = $this->appRootOrSkip();
        $path = $appRoot . $relativeToAppRoot;
        if (!File::exists($path)) {
            $this->markTestSkipped('Source file not found: ' . $relativeToAppRoot);
        }
        return File::get($path);
    }

    private function skipUnlessRouteLive(): void
    {
        if (!Route::has(self::INDEX_ROUTE)) {
            $this->markTestSkipped('Route ' . self::INDEX_ROUTE . ' not registered — enable GlobalMaster in modules_statuses.json.');
        }
    }

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/') ? $this->centralBaseUrl . $path : $this->centralBaseUrl . '/' . $path;
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
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

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    private function browseSafe(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
            } catch (\PHPUnit\Framework\SkippedTestError $e) {
                throw $e;
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        try {
            $dir = base_path('tests/Browser/screenshots');
            File::ensureDirectoryExists($dir);
            $safe = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName) ?: 'failure';
            $browser->driver->takeScreenshot($dir . DIRECTORY_SEPARATOR . $safe . '_' . now()->format('Ymd_Hisv') . '.png');
        } catch (Throwable) {
            // best-effort only
        }
    }

    private function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            $byEmail = User::query()->where('email', $this->adminEmail)->first();
            $this->adminUser = $superAdmin ?: $byEmail;
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }
}
