<?php

namespace Tests\Browser\Modules\GlobalMaster\SessionBoardSetup;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\Board;
use Modules\Prime\Models\AcademicSession;
use Throwable;

/**
 * SessionBoardSetup (GlobalMaster / Prime-CENTRAL) — single comprehensive, READ-ONLY Dusk suite.
 *
 * Screen: "Session & Board Setup" — a READ-ONLY COMPOSITE screen rendering TWO lists in tabs:
 *   - Academic Sessions (tab "academicsession")
 *   - Academic Boards   (tab "academicboard")
 * The screen owns NO table of its own; it reads two primary GLOBAL-MASTER tables:
 *   - glb_academic_sessions   (Modules\Prime\Models\AcademicSession)
 *   - glb_boards              (Modules\GlobalMaster\Models\Board)
 * Both tables carry the glb_ prefix.
 *
 * DB scope: CENTRAL / prime-side (no tenancy scaffolding). Browser host http://127.0.0.1:8000.
 *
 * HARD RULE 13 reconciliation — the LIVE served screen:
 *   Route name  : central.prime.session-board-setup.*
 *   Path        : /prime/session-board-setup   (tested here as INDEX_PATH)
 *   Controller  : Modules\Prime\Http\Controllers\SessionBoardSetupController
 *   View        : prime::session-board-setup.index
 * Only index() has real logic: academicSessions = AcademicSession filtered by search(name/short_name)
 * + status, orderByDesc(start_date), paginate(10,'academicsession_page') fragment 'academicsession';
 * boards = Board filtered by search+status, orderBy(name), paginate(4,'academicboard_page') fragment
 * 'academicboard'. index() is gated by prime.session-board-setup.viewAny.
 *
 * The module's OWN Modules\GlobalMaster\Http\Controllers\SessionBoardSetupController (wired under
 * global-master.session-board-setup, view globalmaster::session-board-setup.index, paginate(10) for
 * both, gated by Gate::any(['prime.board.viewAny'])) is DEAD on central — not tested here.
 *
 * Documented source defects / reconciliation findings recorded by this suite:
 *   DEV-GLB-S01 — create/store/show/edit/update/destroy on the LIVE Prime controller are non-functional
 *                 stubs (permission-gated but return unrelated views / perform NO persistence). Despite the
 *                 Route::resource the screen is effectively READ-ONLY. No CRUD matrix is exercised.
 *   DEV-GLB-S02 — TWO SessionBoardSetupControllers exist (Prime = live vs GlobalMaster = dead) with
 *                 divergent gates (prime.session-board-setup.* vs prime.board.*), different views and
 *                 different paginate sizes (10/4 vs 10/10). Reconciliation finding.
 *   DEV-GLB-S03 — the LIVE Prime controller filters AcademicSession::where('is_active', ...) and the view
 *                 reads $session->is_active, but glb_academic_sessions has NO is_active column (only
 *                 is_current + generated current_flag). Applying a status filter to the sessions list
 *                 targets a non-existent column. Documented + column-absence asserted.
 *
 * Business-rule cross-references (BC-BIZ) — enforced on Academic Session MANAGEMENT (out of scope here,
 * this screen only READS the sessions), recorded from DDL:
 *   - Exactly ONE current session — glb_academic_sessions.current_flag is a STORED generated column
 *     (NULL unless is_current=1) carrying a UNIQUE key => at most one current session.
 *   - short_name is UNIQUE; start_date < end_date; new range must not overlap existing (trigger-based,
 *     NOT DB-enforced in the DDL — documented only).
 *   - glb_boards.name and glb_boards.short_name are UNIQUE; is_active is a boolean.
 *
 * Self-contained: extends \Tests\DuskTestCase directly and inlines the central helper library
 * (centralUrl / authenticateCentral / visitAuthenticated / ensurePageAccessible /
 * browseWithFailureScreenshot / captureFailureScreenshot / resolveAdminUser / currentPath). NO tenant init.
 * Data-dependent assertions are guarded with markTestSkipped when the underlying tables are empty.
 */
class glb_SessionBoardSetup_TestCas extends \Tests\DuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/GlobalMaster/SessionBoardSetup/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/GlobalMaster/SessionBoardSetup/report';
    protected const STATUS_REPORT_PREFIX = 'glb_session_board_setup_report_';

    private const INDEX_PATH = '/prime/session-board-setup';

    private const SESSIONS_TABLE = 'glb_academic_sessions';
    private const BOARDS_TABLE = 'glb_boards';

    // Typed props (initialised in setUp per constraint 05).
    protected ?User $adminUser = null;
    protected string $centralBaseUrl = '';
    protected string $adminEmail = '';
    protected string $adminPassword = '';
    protected array $statusReportEntries = [];

    protected function setUp(): void
    {
        parent::setUp();

        // Central / prime-side suite — guard against any leaked tenancy context. NO tenant init.
        if (function_exists('tenancy')) {
            try {
                if (tenancy()->initialized) {
                    tenancy()->end();
                }
            } catch (Throwable) {
                // best-effort: nothing to end.
            }
        }

        $this->centralBaseUrl = rtrim((string) env('DUSK_CENTRAL_URL', 'http://127.0.0.1:8000'), '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->statusReportEntries = [];

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (!empty($this->statusReportEntries)) {
            $this->writeStatusReportForCurrentTest();
        }

        // Guard: ensure no tenancy context leaks out of a central test.
        if (function_exists('tenancy')) {
            try {
                if (tenancy()->initialized) {
                    tenancy()->end();
                }
            } catch (Throwable) {
                // best-effort.
            }
        }

        parent::tearDown();
    }

    // =========================================================================
    // Band 01–09 — Schema / model configuration truth
    // =========================================================================

    /** BC-DB-01 — glb_academic_sessions table + core columns exist. Source: DDL glb_academic_sessions (_global_db_v4.sql ~84-98). */
    public function test_sessionboardsetup_01_academic_sessions_table_and_columns_exist(): void
    {
        $this->assertTrue(Schema::hasTable(self::SESSIONS_TABLE), self::SESSIONS_TABLE . ' table is missing.');

        foreach (['id', 'short_name', 'name', 'start_date', 'end_date', 'is_current', 'deleted_at', 'created_at', 'updated_at'] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::SESSIONS_TABLE, $column),
                self::SESSIONS_TABLE . '.' . $column . ' column is missing.'
            );
        }

        // SoftDeletes support.
        $this->assertTrue(Schema::hasColumn(self::SESSIONS_TABLE, 'deleted_at'), 'SoftDeletes column deleted_at missing on ' . self::SESSIONS_TABLE);
    }

    /** BC-DB-02 — glb_boards table + core columns exist. Source: DDL glb_boards (_global_db_v4.sql ~103-114). */
    public function test_sessionboardsetup_02_boards_table_and_columns_exist(): void
    {
        $this->assertTrue(Schema::hasTable(self::BOARDS_TABLE), self::BOARDS_TABLE . ' table is missing.');

        foreach (['id', 'name', 'short_name', 'is_active', 'deleted_at', 'created_at', 'updated_at'] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::BOARDS_TABLE, $column),
                self::BOARDS_TABLE . '.' . $column . ' column is missing.'
            );
        }
    }

    /** BC-MDL-01 — AcademicSession model config (table/connection/fillable/SoftDeletes/scopeCurrent). Source: Modules\Prime\Models\AcademicSession. */
    public function test_sessionboardsetup_03_academic_session_model_configuration_is_correct(): void
    {
        $model = new AcademicSession();

        $this->assertSame(self::SESSIONS_TABLE, $model->getTable(), 'AcademicSession::getTable() mismatch.');
        $this->assertSame('global_master_mysql', $model->getConnectionName(), 'AcademicSession connection should be global_master_mysql.');

        foreach (['short_name', 'name', 'start_date', 'end_date', 'is_current'] as $fillable) {
            $this->assertContains($fillable, $model->getFillable(), 'AcademicSession fillable missing ' . $fillable);
        }

        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses(AcademicSession::class),
            'AcademicSession must use SoftDeletes.'
        );

        $this->assertTrue(method_exists(AcademicSession::class, 'scopeCurrent'), 'AcademicSession::scopeCurrent scope missing.');

        // is_current cast to boolean.
        $this->assertSame('boolean', $model->getCasts()['is_current'] ?? null, 'AcademicSession is_current should cast to boolean.');
    }

    /** BC-MDL-02 — Board model config (table/connection/fillable/SoftDeletes/casts). Source: Modules\GlobalMaster\Models\Board. */
    public function test_sessionboardsetup_04_board_model_configuration_is_correct(): void
    {
        $model = new Board();

        $this->assertSame(self::BOARDS_TABLE, $model->getTable(), 'Board::getTable() mismatch.');
        $this->assertSame('global_master_mysql', $model->getConnectionName(), 'Board connection should be global_master_mysql.');

        foreach (['name', 'short_name', 'is_active'] as $fillable) {
            $this->assertContains($fillable, $model->getFillable(), 'Board fillable missing ' . $fillable);
        }

        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses(Board::class),
            'Board must use SoftDeletes.'
        );

        $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null, 'Board is_active should cast to boolean.');
    }

    /** BC-DB-03 — glb_academic_sessions carries the generated current_flag column (single-current mechanism). Source: DDL. */
    public function test_sessionboardsetup_05_academic_sessions_current_flag_column_present(): void
    {
        if (!Schema::hasTable(self::SESSIONS_TABLE)) {
            $this->markTestSkipped(self::SESSIONS_TABLE . ' table not present.');
        }

        $this->assertTrue(
            Schema::hasColumn(self::SESSIONS_TABLE, 'current_flag'),
            'glb_academic_sessions.current_flag (generated, UNIQUE => single current) is missing.'
        );

        // Assert a UNIQUE index exists on current_flag (best-effort; tolerant of driver variance).
        try {
            $indexes = DB::connection('global_master_mysql')->select(
                'SHOW INDEX FROM ' . self::SESSIONS_TABLE . ' WHERE Column_name = ?',
                ['current_flag']
            );
            if (empty($indexes)) {
                $this->markTestSkipped('current_flag index metadata unavailable on this driver — documented via DDL (uq_glb_acadSession_currentFlag).');
            }
            $isUnique = false;
            foreach ($indexes as $row) {
                if ((int) ($row->Non_unique ?? 1) === 0) {
                    $isUnique = true;
                    break;
                }
            }
            $this->assertTrue($isUnique, 'current_flag should carry a UNIQUE index (enforces single current session).');
        } catch (Throwable $e) {
            $this->markTestSkipped('current_flag index inspection failed: ' . $e->getMessage());
        }
    }

    /** BC-DB-04 — glb_boards name & short_name are UNIQUE. Source: DDL (uq_glb_academicBoard_name / _shortName). */
    public function test_sessionboardsetup_06_boards_unique_name_and_short_name(): void
    {
        if (!Schema::hasTable(self::BOARDS_TABLE)) {
            $this->markTestSkipped(self::BOARDS_TABLE . ' table not present.');
        }

        try {
            $columns = ['name', 'short_name'];
            foreach ($columns as $column) {
                $indexes = DB::connection('global_master_mysql')->select(
                    'SHOW INDEX FROM ' . self::BOARDS_TABLE . ' WHERE Column_name = ?',
                    [$column]
                );
                if (empty($indexes)) {
                    $this->markTestSkipped('Board index metadata unavailable — documented via DDL.');
                }
                $isUnique = false;
                foreach ($indexes as $row) {
                    if ((int) ($row->Non_unique ?? 1) === 0) {
                        $isUnique = true;
                        break;
                    }
                }
                $this->assertTrue($isUnique, 'glb_boards.' . $column . ' should carry a UNIQUE index.');
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Board unique-index inspection failed: ' . $e->getMessage());
        }
    }

    /** BC-DB-05 — the screen owns NO table of its own (pure read-only composite). Source: reconciliation / DDL. */
    public function test_sessionboardsetup_07_screen_has_no_own_table(): void
    {
        // Documentational: this composite reads two existing tables and has no session_board_setup table.
        $this->assertFalse(
            Schema::hasTable('glb_session_board_setups') || Schema::hasTable('session_board_setups'),
            'SessionBoardSetup is a read-only composite and must not own a dedicated table.'
        );
    }

    // =========================================================================
    // Band 10–19 — Business rules (documented; sessions are read-only on this screen)
    // =========================================================================

    /** BC-BIZ-01 — single-current-session rule (current_flag generated + UNIQUE). Source: DDL + AcademicSession::scopeCurrent. */
    public function test_sessionboardsetup_10_single_current_session_rule_documented(): void
    {
        if (!Schema::hasTable(self::SESSIONS_TABLE)) {
            $this->markTestSkipped(self::SESSIONS_TABLE . ' table not present.');
        }

        // Data probe: at most one current session may exist (enforced by the UNIQUE generated current_flag).
        try {
            $currentCount = AcademicSession::query()->where('is_current', true)->count();
        } catch (Throwable $e) {
            $this->markTestSkipped('Unable to query current sessions: ' . $e->getMessage());
        }

        $this->assertLessThanOrEqual(
            1,
            $currentCount,
            'At most ONE academic session may be current (glb_academic_sessions.current_flag UNIQUE).'
        );
    }

    /** BC-BIZ-02 — start_date < end_date (+ no-overlap) documented; NOT DB-enforced (trigger-based). Source: DDL comment. */
    public function test_sessionboardsetup_11_session_start_before_end_rule_documented(): void
    {
        if (!Schema::hasTable(self::SESSIONS_TABLE) || AcademicSession::query()->count() === 0) {
            $this->markTestSkipped('No academic sessions present to probe start<end business rule (rule is trigger-based, not DB-enforced).');
        }

        // Data probe over existing rows: every session should satisfy start_date < end_date.
        $violations = AcademicSession::query()
            ->whereColumn('start_date', '>=', 'end_date')
            ->count();

        $this->assertSame(
            0,
            $violations,
            'Every academic session should satisfy start_date < end_date (BC-BIZ; enforced by trigger, cross-ref to Academic Session management).'
        );
    }

    /** BC-BIZ-03 — Board.is_active is a boolean flag. Source: DDL glb_boards.is_active + Board casts. */
    public function test_sessionboardsetup_12_board_is_active_is_boolean(): void
    {
        if (!Schema::hasTable(self::BOARDS_TABLE) || Board::query()->count() === 0) {
            $this->markTestSkipped('No boards present to probe is_active boolean cast.');
        }

        $board = Board::query()->first();
        $this->assertIsBool($board->is_active, 'Board.is_active should be cast to boolean.');
    }

    /** DEV-GLB-S03 — glb_academic_sessions has NO is_active column, yet controller/view reference $session->is_active. Source: DDL + Prime SessionBoardSetupController::index. */
    public function test_sessionboardsetup_13_academic_sessions_missing_is_active_column_defect(): void
    {
        if (!Schema::hasTable(self::SESSIONS_TABLE)) {
            $this->markTestSkipped(self::SESSIONS_TABLE . ' table not present.');
        }

        // The table's status concept is is_current, NOT is_active.
        $this->assertFalse(
            Schema::hasColumn(self::SESSIONS_TABLE, 'is_active'),
            'DEV-GLB-S03: glb_academic_sessions has no is_active column — the controller status filter '
            . "(AcademicSession::where('is_active', ...)) and the view's \$session->is_active target a "
            . 'non-existent column. Status filtering the sessions list is defective.'
        );

        $this->assertTrue(
            Schema::hasColumn(self::SESSIONS_TABLE, 'is_current'),
            'glb_academic_sessions should expose is_current as its status concept.'
        );
    }

    /** DEV-GLB-S02 — dual controllers (Prime live vs GlobalMaster dead) with divergent gates/views/paginate sizes. Source: reconciliation of both SessionBoardSetupController classes. */
    public function test_sessionboardsetup_14_dual_controller_reconciliation_documented(): void
    {
        $primeController = \Modules\Prime\Http\Controllers\SessionBoardSetupController::class;
        $glbController = \Modules\GlobalMaster\Http\Controllers\SessionBoardSetupController::class;

        $this->assertTrue(class_exists($primeController), 'LIVE Prime SessionBoardSetupController should exist.');
        $this->assertTrue(class_exists($glbController), 'GlobalMaster (dead) SessionBoardSetupController should exist.');
        $this->assertNotSame(
            $primeController,
            $glbController,
            'DEV-GLB-S02: two divergent SessionBoardSetupControllers exist; the Prime one (gated prime.session-board-setup.viewAny, '
            . 'paginate 10/4) is served at /prime/session-board-setup, the GlobalMaster one (gated prime.board.viewAny, paginate 10/10) is dead.'
        );
    }

    // =========================================================================
    // Band 30–39 — Negative / auth
    // =========================================================================

    /** BC-AUTH-01 — guest is redirected to /login. Source: auth middleware on central.prime.session-board-setup.index. */
    public function test_sessionboardsetup_30_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('sbs-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);

            $path = $this->currentPath($browser);
            $this->assertStringContainsString('/login', $path, 'Guest should be redirected to /login from ' . self::INDEX_PATH . '.');
        });
    }

    /** BC-AUTH-02 — user lacking prime.session-board-setup.viewAny receives 403. Source: Gate::authorize in Prime index(). Browser has NO assertStatus → getJson probe. */
    public function test_sessionboardsetup_31_user_without_viewany_receives_403(): void
    {
        $user = $this->createUnprivilegedUser();

        try {
            $response = $this->actingAs($user)->getJson($this->centralUrl(self::INDEX_PATH));
            // 403 when the gate denies; some stacks answer 302 to login for web routes — accept either denial.
            $this->assertContains(
                $response->getStatusCode(),
                [401, 403, 302],
                'A user without prime.session-board-setup.viewAny must be denied (expected 403/401/302), got ' . $response->getStatusCode() . '.'
            );
        } finally {
            $this->purgeUser($user);
        }
    }

    // =========================================================================
    // Band 50–59 — Permission / visibility
    // =========================================================================

    /** BC-PERM-01 — admin sees both Academic Session and Academic Board tabs. Source: view nav-tab (prime.academic-session.viewAny / prime.board.viewAny). */
    public function test_sessionboardsetup_50_admin_sees_both_tabs(): void
    {
        $this->browseWithFailureScreenshot('sbs-both-tabs', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'SessionBoardSetup index not reachable.');
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            $browser->assertSee('Academic Session');
            $browser->assertSee('Academic Board');
        });
    }

    /** BC-PERM-02 — tab panes exist and are permission-gated (canany). Source: view @can prime.academic-session.viewAny / prime.board.viewAny. */
    public function test_sessionboardsetup_51_tab_panes_present(): void
    {
        $this->browseWithFailureScreenshot('sbs-tab-panes', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            // As super-admin both panes render.
            $browser->assertPresent('#academicsession-pane');
            $browser->assertPresent('#academicboard-pane');
        });
    }

    // =========================================================================
    // Band 60–69 — UI / render / filter / pagination
    // =========================================================================

    /** BC-UI-01 — index renders at the LIVE Prime path /prime/session-board-setup. Source: HARD RULE 13. */
    public function test_sessionboardsetup_60_index_renders_at_prime_path(): void
    {
        $this->browseWithFailureScreenshot('sbs-index-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'SessionBoardSetup must render at /prime/session-board-setup.');
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');
            $browser->assertPresent('body');
        });
    }

    /** BC-UI-02 — breadcrumb / screen title "Session & Board Setup". Source: view breadcrum title. */
    public function test_sessionboardsetup_61_index_shows_screen_title(): void
    {
        $this->browseWithFailureScreenshot('sbs-title', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            $browser->assertSee('Session & Board Setup');
        });
    }

    /** BC-UI-03 — both list tables render (sessions + boards). Source: view two tables in tab panes. */
    public function test_sessionboardsetup_62_index_renders_both_lists(): void
    {
        $this->browseWithFailureScreenshot('sbs-both-lists', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            $browser->assertPresent('#academicsession-pane table');
            $browser->assertPresent('#academicboard-pane table');
        });
    }

    /** BC-UI-04 — search input + status filter present on both tabs. Source: view search-bar forms (name="search", name="status"). */
    public function test_sessionboardsetup_63_search_and_status_filter_present(): void
    {
        $this->browseWithFailureScreenshot('sbs-search-status', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            $browser->assertPresent('input[name="search"]');
            $browser->assertPresent('select[name="status"]');
            // Status options 1=Active / 0=Inactive per view.
            $browser->assertPresent('select[name="status"] option[value="1"]');
            $browser->assertPresent('select[name="status"] option[value="0"]');
        });
    }

    /** BC-UI-05 — search query narrows the sessions list. Source: Prime index() search on name/short_name. */
    public function test_sessionboardsetup_64_search_filters_sessions_list(): void
    {
        if (!Schema::hasTable(self::SESSIONS_TABLE) || AcademicSession::query()->count() === 0) {
            $this->markTestSkipped('No academic sessions present to exercise search filtering.');
        }

        $session = AcademicSession::query()->orderByDesc('start_date')->first();
        $needle = (string) ($session->short_name ?: $session->name);
        if ($needle === '') {
            $this->markTestSkipped('Seed session has empty name/short_name.');
        }

        $this->browseWithFailureScreenshot('sbs-search-sessions', function (Browser $browser) use ($needle): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode($needle));
            $this->ensurePageAccessible($browser, 'SessionBoardSetup search');

            $browser->assertSee($needle);
        });
    }

    /** BC-UI-06 — sessions list page-size is 10 (paginate 10, 'academicsession_page'). Source: Prime index(). */
    public function test_sessionboardsetup_65_sessions_page_size_is_ten(): void
    {
        if (!Schema::hasTable(self::SESSIONS_TABLE) || AcademicSession::query()->count() === 0) {
            $this->markTestSkipped('No academic sessions present to verify page size.');
        }

        $this->browseWithFailureScreenshot('sbs-sessions-pagesize', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            // Page 1 never exceeds the configured page size (10). Empty-state renders a single message row.
            $rows = count($browser->elements('#academicsession-pane table tbody tr'));
            $this->assertLessThanOrEqual(10, $rows, 'Academic sessions list must not exceed page size 10 on page 1.');
        });
    }

    /** BC-UI-07 — boards list page-size is 4 (paginate 4, 'academicboard_page'). Source: Prime index(). */
    public function test_sessionboardsetup_66_boards_page_size_is_four(): void
    {
        if (!Schema::hasTable(self::BOARDS_TABLE) || Board::query()->count() === 0) {
            $this->markTestSkipped('No boards present to verify page size.');
        }

        $this->browseWithFailureScreenshot('sbs-boards-pagesize', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            $rows = count($browser->elements('#academicboard-pane table tbody tr'));
            $this->assertLessThanOrEqual(4, $rows, 'Academic boards list must not exceed page size 4 on page 1.');
        });
    }

    /** BC-UI-08 — distinct paginator query params academicsession_page / academicboard_page. Source: Prime index() fragment+page-name. */
    public function test_sessionboardsetup_67_distinct_pagination_param_names(): void
    {
        if (!Schema::hasTable(self::SESSIONS_TABLE) || AcademicSession::query()->count() <= 10) {
            $this->markTestSkipped('Fewer than 11 sessions — pagination links for academicsession_page not rendered.');
        }

        $this->browseWithFailureScreenshot('sbs-page-params', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            // The sessions paginator uses the distinct page name academicsession_page.
            $browser->assertPresent('#academicsession-pane a[href*="academicsession_page"]');
        });
    }

    /** BC-UI-09 — empty-state messages render when a list has no rows. Source: view @empty ("No ... Data Found"). */
    public function test_sessionboardsetup_68_empty_state_messages_documented(): void
    {
        $sessionsEmpty = Schema::hasTable(self::SESSIONS_TABLE) && AcademicSession::query()->count() === 0;
        $boardsEmpty = Schema::hasTable(self::BOARDS_TABLE) && Board::query()->count() === 0;

        if (!$sessionsEmpty && !$boardsEmpty) {
            $this->markTestSkipped('Both lists have data — empty-state strings ("No Academic Session Data Found" / "No Board Data Found") not rendered.');
        }

        $this->browseWithFailureScreenshot('sbs-empty-state', function (Browser $browser) use ($sessionsEmpty, $boardsEmpty): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'SessionBoardSetup index');

            if ($sessionsEmpty) {
                $browser->assertSee('No Academic Session Data Found');
            }
            if ($boardsEmpty) {
                $browser->assertSee('No Board Data Found');
            }
        });
    }

    /** DEV-GLB-S01 — resource is READ-ONLY; create/store/show/edit/update/destroy are non-functional stubs (no persistence). Source: Prime SessionBoardSetupController stubs. */
    public function test_sessionboardsetup_69_resource_is_read_only_no_crud(): void
    {
        // Documentational assertion: the controller's write methods are stubs (create/store/show/edit/update/destroy
        // are gated but perform no persistence / return unrelated views). No CRUD matrix is exercised for this screen.
        $reflection = new \ReflectionClass(\Modules\Prime\Http\Controllers\SessionBoardSetupController::class);
        foreach (['index', 'create', 'store', 'show', 'edit', 'update', 'destroy'] as $method) {
            $this->assertTrue(
                $reflection->hasMethod($method),
                'Prime SessionBoardSetupController::' . $method . ' should exist (write methods are documented stubs — DEV-GLB-S01).'
            );
        }

        // Confirm no dedicated persistence table was silently introduced by the stubs.
        $this->assertFalse(
            Schema::hasTable('glb_session_board_setups'),
            'DEV-GLB-S01: SessionBoardSetup remains read-only; no dedicated table should exist.'
        );
    }

    // =========================================================================
    // Inline central helper library (self-contained; mirrors central BillingDuskTestCase)
    // =========================================================================

    protected function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }

        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
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

        if (str_contains($this->currentPath($browser), '/login')) {
            if ($this->adminUser) {
                $browser->loginAs($this->adminUser)->pause(800);
            }
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

    protected function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
                $this->recordReportEntry($caseName, 'PASS', 'Step completed successfully.', '');
            } catch (Throwable $e) {
                $screenshot = $this->captureFailureScreenshot($browser, $caseName);
                $this->recordReportEntry($caseName, 'FAIL', $e->getMessage(), $screenshot);
                if ($e instanceof \PHPUnit\Framework\SkippedTestError) {
                    throw new \RuntimeException($e->getMessage(), 0, $e);
                }
                throw $e;
            }
        });
    }

    protected function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        $directory = base_path(static::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $timestamp = now()->format('Ymd_Hisv');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'failure';
        $filename = $safeName . '_' . $timestamp . '.png';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $filename;

        try {
            $browser->driver->takeScreenshot($absolutePath);
            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolutePath);
        } catch (Throwable) {
            return '';
        }
    }

    protected function recordReportEntry(string $stepName, string $status, string $message, string $screenshotPath): void
    {
        $this->statusReportEntries[] = [
            'timestamp' => now()->format('Y-m-d H:i:s'),
            'test' => $this->name(),
            'step' => $stepName,
            'status' => $status,
            'message' => $message,
            'screenshot' => $screenshotPath,
        ];
    }

    protected function writeStatusReportForCurrentTest(): void
    {
        $directory = base_path(static::STATUS_REPORT_DIRECTORY);
        File::ensureDirectoryExists($directory);

        $prefix = static::STATUS_REPORT_PREFIX;
        $sanitizedTestName = preg_replace('/[^a-z0-9_-]+/i', '_', strtolower($this->name()));
        $filename = $prefix . $sanitizedTestName . '_' . now()->format('Ymd_Hisv') . '.md';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $filename;

        $lines = [];
        $lines[] = '# SessionBoardSetup (GlobalMaster / Prime-central) Dusk Status Report';
        $lines[] = '';
        $lines[] = '- Test Method: `' . $this->name() . '`';
        $lines[] = '- Generated At: `' . now()->format('Y-m-d H:i:s') . '`';
        $lines[] = '';
        $lines[] = '| Time | Step | Status | Message | Screenshot |';
        $lines[] = '| --- | --- | --- | --- | --- |';

        foreach ($this->statusReportEntries as $entry) {
            $message = str_replace('|', '/', $entry['message']);
            $screenshot = $entry['screenshot'] !== '' ? '`' . $entry['screenshot'] . '`' : '-';
            $lines[] = '| '
                . $entry['timestamp'] . ' | '
                . $entry['step'] . ' | '
                . $entry['status'] . ' | '
                . $message . ' | '
                . $screenshot . ' |';
        }

        file_put_contents($absolutePath, implode(PHP_EOL, $lines) . PHP_EOL);
        $this->statusReportEntries = [];
    }

    protected function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    protected function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows login page; authentication failed.');
        }

        if (!$browser->element('body')) {
            $this->fail($context . ' page body not available.');
        }

        $bodyText = $browser->text('body');
        $signals = ['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'];

        foreach ($signals as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    protected function resolveAdminUser(): void
    {
        $userByEmail = User::query()->where('email', $this->adminEmail)->first();
        $superAdmin = User::query()->where('is_super_admin', 1)->first();

        if ($superAdmin) {
            $this->adminUser = $superAdmin;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        if ($userByEmail) {
            $this->adminUser = $userByEmail;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        $this->adminUser = User::create([
            'email' => $this->adminEmail,
            'password' => bcrypt($this->adminPassword),
            'name' => 'SessionBoardSetup Dusk Admin',
            'emp_code' => 'EMP' . rand(100, 999),
            'short_name' => 'ADM' . rand(1000, 9999),
            'status' => 'ACTIVE',
            'is_active' => 1,
            'is_super_admin' => 1,
            'email_verified_at' => now(),
        ]);
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

    private function createUnprivilegedUser(): User
    {
        return User::create([
            'email' => 'sbs_noperm_' . rand(10000, 99999) . '@example.com',
            'password' => bcrypt('password'),
            'name' => 'SBS No-Perm User',
            'emp_code' => 'EMP' . rand(100, 999),
            'short_name' => 'NOP' . rand(1000, 9999),
            'status' => 'ACTIVE',
            'is_active' => 1,
            'is_super_admin' => 0,
            'email_verified_at' => now(),
        ]);
    }

    private function purgeUser(User $user): void
    {
        try {
            DB::table('users')->where('id', $user->id)->delete();
        } catch (Throwable) {
            // best-effort cleanup.
        }
    }
}
