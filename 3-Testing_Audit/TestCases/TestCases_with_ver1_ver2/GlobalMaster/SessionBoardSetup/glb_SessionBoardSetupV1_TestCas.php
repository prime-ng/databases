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
 * V1 (Foundation) — GlobalMaster :: Session & Board Setup (composite / read-only hub).
 *
 * DB SCOPE: CENTRAL / prime-side (glb_academic_sessions + glb_boards live in the
 * `global_master` database, connection `global_master_mysql`). NO tenant init.
 *
 * STYLE: browser Dusk CENTRAL pattern. Extends the physical central base
 * `prm_PrimeDuskTestCase_TestCas` (aliased to `PrimeDuskTestCase` by
 * tests/Browser/Modules/preload.php), which forces http://127.0.0.1:8000 and
 * fails setUp() if the host is not 127.0.0.1. Central helpers (auth, admin
 * resolve, failure screenshots) are mirrored locally from the Billing base.
 *
 * This screen is READ-ONLY + PARTLY BROKEN: store()/update()/destroy() are empty
 * stubs and create()/show()/edit() return views that do not exist — so there is
 * intentionally NO create/edit/delete matrix. The deterministic assertions
 * (schema truth, model config, route/class registration) are the load-bearing
 * part of this suite; the browser render cases are defensive and self-skip when
 * the module is disabled (modules_statuses.json → 404).
 *
 * Encoded audit-equivalent defects (see Gap Analysis / TcList):
 *   BUG-GLB-001  model-resolution reconciliation (audit claim vs live source)
 *   DATA-GLB-002 view reads $session->is_active — column absent from glb_academic_sessions
 *   BUG-GLB-003  single-current invariant enforced only by DB (current_flag UNIQUE); store() no-op
 *   BUG-GLB-004  view route-name mismatch (central.global-master.* vs global-master.*)
 *   BUG-GLB-005  dual controller collision (GlobalMaster vs Prime bind session-board-setup)
 *   BUG-GLB-006  create/show/edit views missing; store/update/destroy empty stubs
 */
class glb_SessionBoardSetupV1_TestCas extends PrimeDuskTestCase
{
    private const INDEX_PATH   = '/global-master/session-board-setup';
    private const INDEX_ROUTE  = 'global-master.session-board-setup.index';
    private const CONNECTION    = 'global_master_mysql';
    private const SESSIONS_TABLE = 'glb_academic_sessions';
    private const BOARDS_TABLE   = 'glb_boards';

    private const ACADEMIC_SESSION_MODEL = 'Modules\\Prime\\Models\\AcademicSession';
    private const BOARD_MODEL            = 'Modules\\GlobalMaster\\Models\\Board';
    private const GLOBALMASTER_SESSION_MODEL = 'Modules\\GlobalMaster\\Models\\AcademicSession';

    private const GM_CONTROLLER    = 'Modules\\GlobalMaster\\Http\\Controllers\\SessionBoardSetupController';
    private const PRIME_CONTROLLER = 'Modules\\Prime\\Http\\Controllers\\SessionBoardSetupController';

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
    // 01-09 :: Schema / DDL / model / route configuration (config truth)
    // ===================================================================

    /** test_01 — schema truth for both hub tables + primary route registration. */
    public function test_sessionboardsetup_01_schema_and_route_configuration_are_correct(): void
    {
        $schema = $this->schemaOrSkip();

        // glb_academic_sessions
        $this->assertTrue($schema->hasTable(self::SESSIONS_TABLE), 'glb_academic_sessions table missing.');
        $this->assertTrue($schema->hasColumns(self::SESSIONS_TABLE, [
            'id', 'short_name', 'name', 'start_date', 'end_date',
            'is_current', 'current_flag', 'deleted_at', 'created_at', 'updated_at',
        ]), 'glb_academic_sessions is missing one or more DDL columns.');

        // glb_boards
        $this->assertTrue($schema->hasTable(self::BOARDS_TABLE), 'glb_boards table missing.');
        $this->assertTrue($schema->hasColumns(self::BOARDS_TABLE, [
            'id', 'name', 'short_name', 'is_active', 'created_at', 'updated_at', 'deleted_at',
        ]), 'glb_boards is missing one or more DDL columns.');

        // Route registered for the GlobalMaster hub.
        $this->assertTrue(
            Route::has(self::INDEX_ROUTE),
            'Expected route ' . self::INDEX_ROUTE . ' to be registered (module GlobalMaster must be enabled).'
        );
    }

    /** test_02 — column types (MySQL 8 variance tolerant, constraint C17). */
    public function test_sessionboardsetup_02_column_types_match_ddl(): void
    {
        $schema = $this->schemaOrSkip();

        $sessionShort = strtolower($schema->getColumnType(self::SESSIONS_TABLE, 'short_name'));
        $this->assertStringContainsString('char', $sessionShort, 'short_name should be a (var)char type.');

        $isCurrent = strtolower($schema->getColumnType(self::SESSIONS_TABLE, 'is_current'));
        $this->assertTrue(
            str_contains($isCurrent, 'int') || str_contains($isCurrent, 'bool') || str_contains($isCurrent, 'tiny'),
            'is_current should be a tinyint/boolean type; got ' . $isCurrent
        );

        $boardActive = strtolower($schema->getColumnType(self::BOARDS_TABLE, 'is_active'));
        $this->assertTrue(
            str_contains($boardActive, 'int') || str_contains($boardActive, 'bool') || str_contains($boardActive, 'tiny'),
            'glb_boards.is_active should be tinyint/boolean; got ' . $boardActive
        );
    }

    /** test_03 — AcademicSession model config (Prime model, global_master connection). */
    public function test_sessionboardsetup_03_academic_session_model_configuration(): void
    {
        $model = $this->modelOrSkip(self::ACADEMIC_SESSION_MODEL);

        $this->assertSame(self::SESSIONS_TABLE, $model->getTable());
        $this->assertSame(self::CONNECTION, $model->getConnectionName());
        foreach (['short_name', 'name', 'start_date', 'end_date', 'is_current'] as $f) {
            $this->assertContains($f, $model->getFillable(), "AcademicSession fillable should contain {$f}.");
        }
        $this->assertTrue($this->usesSoftDeletes(self::ACADEMIC_SESSION_MODEL), 'AcademicSession should use SoftDeletes.');
        $this->assertTrue(method_exists($model, 'scopeCurrent'), 'AcademicSession should define scopeCurrent().');
    }

    /** test_04 — Board model config (GlobalMaster model, global_master connection). */
    public function test_sessionboardsetup_04_board_model_configuration(): void
    {
        $model = $this->modelOrSkip(self::BOARD_MODEL);

        $this->assertSame(self::BOARDS_TABLE, $model->getTable());
        $this->assertSame(self::CONNECTION, $model->getConnectionName());
        foreach (['name', 'short_name', 'is_active'] as $f) {
            $this->assertContains($f, $model->getFillable(), "Board fillable should contain {$f}.");
        }
        $this->assertArrayHasKey('is_active', $model->getCasts());
        $this->assertTrue($this->usesSoftDeletes(self::BOARD_MODEL), 'Board should use SoftDeletes.');
        $this->assertTrue(method_exists($model, 'organizations'), 'Board should define organizations() relationship.');
    }

    /** test_05 — DATA-GLB-002: glb_academic_sessions has NO is_active column. */
    public function test_sessionboardsetup_05_academic_sessions_has_no_is_active_column(): void
    {
        $schema = $this->schemaOrSkip();

        $this->assertFalse(
            $schema->hasColumn(self::SESSIONS_TABLE, 'is_active'),
            'DATA-GLB-002: glb_academic_sessions must NOT have an is_active column; the hub view reads $session->is_active which resolves to null.'
        );
        // The Prime AcademicSession model must not claim is_active as fillable either.
        $model = $this->modelOrSkip(self::ACADEMIC_SESSION_MODEL);
        $this->assertNotContains('is_active', $model->getFillable(), 'AcademicSession fillable unexpectedly contains is_active.');
    }

    /** test_06 — BUG-GLB-003: single-current invariant lives on the generated current_flag column. */
    public function test_sessionboardsetup_06_current_flag_generated_column_present(): void
    {
        $schema = $this->schemaOrSkip();

        $this->assertTrue(
            $schema->hasColumn(self::SESSIONS_TABLE, 'current_flag'),
            'BUG-GLB-003: current_flag generated column (DB-enforced single-current invariant) is missing.'
        );
        $this->assertFalse(
            $this->modelOrSkip(self::ACADEMIC_SESSION_MODEL)->getConnection() === null,
            'AcademicSession connection unresolved.'
        );
    }

    /** test_07 — BUG-GLB-001 reconciliation: which AcademicSession class actually resolves. */
    public function test_sessionboardsetup_07_academic_session_model_resolution_reconciliation(): void
    {
        // Audit BUG-GLB-001 claimed the controller referenced a NON-existent
        // Modules\GlobalMaster\Models\AcademicSession → 500. Reconcile vs live source.
        $this->assertTrue(
            class_exists(self::ACADEMIC_SESSION_MODEL),
            'Modules\\Prime\\Models\\AcademicSession must exist (this is what the live controller imports).'
        );
        $this->assertFalse(
            class_exists(self::GLOBALMASTER_SESSION_MODEL),
            'BUG-GLB-001: Modules\\GlobalMaster\\Models\\AcademicSession must NOT exist — any code importing it 500s.'
        );
        $this->assertTrue(
            class_exists(self::BOARD_MODEL),
            'Modules\\GlobalMaster\\Models\\Board must exist for the hub to resolve.'
        );
    }

    /** test_08 — BUG-GLB-005: dual controller collision on session-board-setup. */
    public function test_sessionboardsetup_08_dual_controller_collision_documented(): void
    {
        $this->assertTrue(class_exists(self::GM_CONTROLLER), 'GlobalMaster SessionBoardSetupController missing.');
        $this->assertTrue(class_exists(self::PRIME_CONTROLLER), 'Prime SessionBoardSetupController missing (twin binding).');
        // Both expose index() but with divergent gates/logic — the collision is real.
        $this->assertTrue(method_exists(self::GM_CONTROLLER, 'index'));
        $this->assertTrue(method_exists(self::PRIME_CONTROLLER, 'index'));
    }

    /** test_09 — BUG-GLB-006: create/show/edit views missing; store/update/destroy are stubs. */
    public function test_sessionboardsetup_09_broken_write_surface_source_shape(): void
    {
        $appRoot = $this->appRootOrSkip();
        $viewsRoot = $appRoot . '/Modules/GlobalMaster/resources/views';

        // The hub index view DOES exist.
        $this->assertTrue(
            File::exists($viewsRoot . '/session-board-setup/index.blade.php'),
            'globalmaster::session-board-setup.index view should exist.'
        );
        // create()/show()/edit() return globalmaster::create|show|edit which do NOT exist.
        foreach (['create', 'show', 'edit'] as $stub) {
            $this->assertFalse(
                File::exists($viewsRoot . '/' . $stub . '.blade.php'),
                "BUG-GLB-006: globalmaster::{$stub} view unexpectedly exists — expected missing (500)."
            );
        }
    }

    // ===================================================================
    // 50-59 :: Permissions / authorization (source truth)
    // ===================================================================

    /** test_50 — index gate is prime.board.viewAny (Gate::any || abort(403)). */
    public function test_sessionboardsetup_50_index_gate_is_prime_board_viewany(): void
    {
        $appRoot = $this->appRootOrSkip();
        $controller = File::get($appRoot . '/Modules/GlobalMaster/app/Http/Controllers/SessionBoardSetupController.php');

        $this->assertStringContainsString('prime.board.viewAny', $controller, 'index() gate must be prime.board.viewAny.');
        $this->assertStringContainsString('abort(403)', $controller, 'index() must abort(403) when gate denies.');
        $this->assertStringContainsString("view('globalmaster::session-board-setup.index'", $controller, 'index() must return the hub view.');
    }

    // ===================================================================
    // 10-19 / 60-69 :: Render + read-only behaviour (browser, defensive)
    // ===================================================================

    /** test_10 — guest hitting the hub is redirected to /login (auth middleware). */
    public function test_sessionboardsetup_10_guest_redirected_to_login(): void
    {
        $this->skipUnlessRouteLive();

        $this->browseSafe('guest_redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(500);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be bounced to /login.');
        });
    }

    /** test_11 — authenticated admin can open the hub; page body renders. */
    public function test_sessionboardsetup_11_hub_renders_for_admin(): void
    {
        $this->skipUnlessRouteLive();

        $this->browseSafe('hub_render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->assertNotSame('/login', $this->currentPath($browser), 'Admin should not be on /login.');
            $this->assertTrue((bool) $browser->element('body'), 'Hub body should render.');
        });
    }

    /** test_12 — hub exposes both tabs (Academic Session + Academic Board). */
    public function test_sessionboardsetup_12_hub_shows_both_tabs(): void
    {
        $this->skipUnlessRouteLive();

        $this->browseSafe('hub_tabs', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $body = (string) $browser->text('body');
            $this->assertTrue(
                str_contains($body, 'Academic Session') || str_contains($body, 'Session & Board Setup'),
                'Expected the Session & Board Setup hub heading / tab labels.'
            );
        });
    }

    // ===================================================================
    // 30-39 :: Broken write surface (proving no-op, source-level)
    // ===================================================================

    /** test_30 — store() is an empty stub: source contains no persistence. */
    public function test_sessionboardsetup_30_store_is_empty_noop_stub(): void
    {
        $appRoot = $this->appRootOrSkip();
        $controller = File::get($appRoot . '/Modules/GlobalMaster/app/Http/Controllers/SessionBoardSetupController.php');

        // Confirm the empty-brace stub shape for store/update/destroy.
        $this->assertMatchesRegularExpression(
            '/public function store\([^)]*\)\s*\{\s*\}/',
            $controller,
            'BUG-GLB-006: store() must be an empty {} stub (no persistence).'
        );
        $this->assertMatchesRegularExpression('/public function update\([^)]*\)\s*\{\s*\}/', $controller, 'update() must be an empty stub.');
        $this->assertMatchesRegularExpression('/public function destroy\([^)]*\)\s*\{\s*\}/', $controller, 'destroy() must be an empty stub.');
    }

    // ===================================================================
    // Private helper library
    // ===================================================================

    private function schemaOrSkip(): \Illuminate\Database\Schema\Builder
    {
        try {
            $schema = Schema::connection(self::CONNECTION);
            // Force a connection check.
            $schema->hasTable(self::SESSIONS_TABLE);
            return $schema;
        } catch (Throwable $e) {
            $this->markTestSkipped('global_master connection unavailable in this environment: ' . $e->getMessage());
        }
    }

    private function modelOrSkip(string $class): \Illuminate\Database\Eloquent\Model
    {
        if (!class_exists($class)) {
            $this->markTestSkipped("Model {$class} not autoloadable in this environment.");
        }
        return new $class();
    }

    private function usesSoftDeletes(string $class): bool
    {
        if (!class_exists($class)) {
            return false;
        }
        return in_array(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive($class),
            true
        );
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
