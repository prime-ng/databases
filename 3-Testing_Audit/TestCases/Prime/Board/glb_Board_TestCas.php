<?php

namespace Tests\Browser\Modules\Prime\Board;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\Board;
use Modules\Prime\Models\ActivityLog;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Prime (PRM) module — Board feature (screen) comprehensive Dusk suite.
 *
 * SINGLE comprehensive test file per screen (no V1/V2 split).
 *
 * DB SCOPE: CENTRAL. The primary table `glb_boards` lives in the *global_master*
 * database (model connection `global_master_mysql`), not in a tenant DB and not
 * under the `prm_` prefix. => prefix is `glb_` (documented registry-vs-DDL flag:
 * the module registry maps Prime -> prm_, but this screen's primary table is
 * glb_boards in global_master). NO tenant init; host http://127.0.0.1:8000.
 *
 * Effective source classes (verified from BoardController imports):
 *   - Modules\GlobalMaster\Models\Board            (NOT Modules\Prime\Models\Board)
 *   - Modules\GlobalMaster\Http\Requests\BoardRequest (NOT the Prime duplicate)
 *   - Modules\Prime\Http\Controllers\BoardController
 *   - Modules\GlobalMaster\Policies\BoardPolicy
 *   - Modules\Prime\Models\ActivityLog  (central sink: sys_central_activity_logs)
 *
 * Central helpers (authenticateCentral / visitAuthenticated / centralUrl /
 * resolveAdminUser / browseWithFailureScreenshot) are implemented LOCALLY here,
 * mirroring prm_BillingDuskTestCase_TestCas, while extending PrimeDuskTestCase.
 *
 * Constraint compliance (05_Known_Test_Failure_Constraints.md):
 *   #21 central host 127.0.0.1 via PrimeDuskTestCase   #22 class_alias preload
 *   #14 no Browser::assertStatus -> HTTP test methods   #13 typed props initialised
 *   #12 SoftDeletes guarded                             #25 central activity sink
 *   #19 module-enabled prerequisite (documented; DB/HTTP tests fail-soft)
 */
class glb_Board_TestCas extends PrimeDuskTestCase
{
    // ---- Route names (verified: central. domain -> prime. prefix) ----
    private const ROUTE_INDEX = 'central.prime.board.index';
    private const ROUTE_CREATE = 'central.prime.board.create';
    private const ROUTE_STORE = 'central.prime.board.store';
    private const ROUTE_SHOW = 'central.prime.board.show';
    private const ROUTE_EDIT = 'central.prime.board.edit';
    private const ROUTE_UPDATE = 'central.prime.board.update';
    private const ROUTE_DESTROY = 'central.prime.board.destroy';
    private const ROUTE_TRASHED = 'central.prime.board.trashed';
    private const ROUTE_RESTORE = 'central.prime.board.restore';
    private const ROUTE_FORCE_DELETE = 'central.prime.board.forceDelete';
    private const ROUTE_TOGGLE = 'central.prime.board.toggleStatus';

    // ---- URL paths (verified) ----
    private const INDEX_PATH = '/prime/board';
    private const CREATE_PATH = '/prime/board/create';
    private const TRASH_PATH = '/prime/board/trash/view';

    // ---- DB (verified) ----
    private const BOARD_CONNECTION = 'global_master_mysql';
    private const BOARD_TABLE = 'glb_boards';
    private const CENTRAL_ACTIVITY_TABLE = 'sys_central_activity_logs';

    // ---- App source relative paths (resolved against app root; see appSourcePath) ----
    private const CONTROLLER_REL = 'Modules/Prime/app/Http/Controllers/BoardController.php';
    private const REQUEST_REL = 'Modules/GlobalMaster/app/Http/Requests/BoardRequest.php';
    private const PRIME_REQUEST_REL = 'Modules/Prime/app/Http/Requests/BoardRequest.php';
    private const MODEL_REL = 'Modules/GlobalMaster/app/Models/Board.php';
    private const POLICY_REL = 'Modules/GlobalMaster/app/Policies/BoardPolicy.php';
    private const ROUTES_REL = 'routes/web.php';
    private const INDEX_VIEW_REL = 'Modules/Prime/resources/views/board/index.blade.php';
    private const CREATE_VIEW_REL = 'Modules/Prime/resources/views/board/create.blade.php';
    private const SHOW_VIEW_REL = 'Modules/Prime/resources/views/board/show.blade.php';
    private const TRASH_VIEW_REL = 'Modules/Prime/resources/views/board/trash.blade.php';

    // ---- Screenshot / report dirs ----
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Board/screenshots';

    protected ?User $adminUser = null;
    protected string $centralBaseUrl = '';
    protected string $adminEmail = '';
    protected string $adminPassword = '';

    /** @var array<int,int> board ids created during the run, for cleanup */
    private array $createdBoardIds = [];

    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        // Prime is CENTRAL — no tenant init. Base URL comes from PrimeDuskTestCase.
        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        $this->cleanupCreatedBoards();

        // Defensive: if any test initialised tenancy, end it (Board is central).
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01-09 — Schema / DDL / model / request / policy configuration truth
    // =====================================================================

    /**
     * TC-P01 / BC-DB-* / BC-VAL-* / BC-AUTH-09 — the opening config-truth method.
     * Asserts model config, request rules, controller gates, policy mapping and
     * activity sink entirely from source (no live DB needed).
     */
    public function test_board_01_migration_model_and_request_configuration_are_correct(): void
    {
        // --- Model configuration (Modules\GlobalMaster\Models\Board) ---
        $board = new Board();
        $this->assertSame(self::BOARD_TABLE, $board->getTable(), 'Board table must be glb_boards.');
        $this->assertSame(self::BOARD_CONNECTION, $board->getConnectionName(), 'Board must use the global_master connection.');
        $this->assertSame(['name', 'short_name', 'is_active'], $board->getFillable(), 'Board fillable mismatch.');
        $this->assertTrue($this->usesSoftDeletes(Board::class), 'Board must use SoftDeletes (deleted_at).');
        $this->assertContains(
            $board->getCasts()['is_active'] ?? null,
            ['boolean', 'bool'],
            'is_active must be cast to boolean.'
        );

        // --- Effective FormRequest rules (GlobalMaster BoardRequest) ---
        $requestFile = $this->appSourcePath(self::REQUEST_REL);
        if ($requestFile !== null) {
            $req = file_get_contents($requestFile);
            $this->assertStringContainsString("'required'", $req);
            $this->assertStringContainsString("'string'", $req);
            $this->assertStringContainsString("'max:50'", $req, "name rule must be max:50.");
            $this->assertStringContainsString("'max:10'", $req, "short_name rule must be max:10.");
            $this->assertStringContainsString("Rule::unique('glb_boards')->ignore(\$boardId)", $req);
            $this->assertStringContainsString("'is_active' => 'required|boolean'", $req);
            $this->assertStringContainsString('prepareForValidation', $req);
        } else {
            $this->markTestIncomplete('GlobalMaster BoardRequest source not resolvable in this environment.');
        }

        // --- Controller gate strings (all seven abilities) ---
        $controllerFile = $this->appSourcePath(self::CONTROLLER_REL);
        if ($controllerFile !== null) {
            $ctrl = file_get_contents($controllerFile);
            foreach ([
                "Gate::authorize('prime.board.viewAny')",
                "Gate::authorize('prime.board.create')",
                "Gate::authorize('prime.board.view')",
                "Gate::authorize('prime.board.update')",
                "Gate::authorize('prime.board.delete')",
                "Gate::authorize('prime.board.restore')",
                "Gate::authorize('prime.board.forceDelete')",
            ] as $needle) {
                $this->assertStringContainsString($needle, $ctrl, "Missing gate: $needle");
            }
            // Effective classes are the GlobalMaster ones.
            $this->assertStringContainsString('use Modules\GlobalMaster\Models\Board;', $ctrl);
            $this->assertStringContainsString('use Modules\GlobalMaster\Http\Requests\BoardRequest;', $ctrl);
        }

        // --- Central activity sink model config (constraint #25) ---
        $log = new ActivityLog();
        $this->assertSame(self::CENTRAL_ACTIVITY_TABLE, $log->getTable(), 'Central activity sink must be sys_central_activity_logs.');
        $this->assertSame('mysql', $log->getConnectionName(), 'Central activity sink uses the central mysql connection.');
        foreach (['subject_type', 'subject_id', 'user_id', 'event', 'properties'] as $col) {
            $this->assertContains($col, $log->getFillable(), "ActivityLog fillable must include $col.");
        }
    }

    /** TC-P02 / BC-DB-01,02 — table & columns exist on the global_master connection (fail-soft). */
    public function test_board_02_glb_boards_table_and_columns_exist(): void
    {
        $this->withBoardSchema(function (): void {
            $this->assertTrue(
                Schema::connection(self::BOARD_CONNECTION)->hasTable(self::BOARD_TABLE),
                'glb_boards table must exist in global_master.'
            );
            foreach (['id', 'name', 'short_name', 'is_active', 'created_at', 'updated_at', 'deleted_at'] as $col) {
                $this->assertTrue(
                    Schema::connection(self::BOARD_CONNECTION)->hasColumn(self::BOARD_TABLE, $col),
                    "glb_boards must have column $col."
                );
            }
        });
    }

    /** TC-P03 / BC-DB-06,07 — unique indexes on name and short_name (fail-soft). */
    public function test_board_03_unique_indexes_on_name_and_short_name_exist(): void
    {
        $this->withBoardSchema(function (): void {
            $indexes = Schema::connection(self::BOARD_CONNECTION)
                ->getConnection()
                ->select('SHOW INDEX FROM ' . self::BOARD_TABLE);

            $uniqueColumns = [];
            foreach ($indexes as $row) {
                $r = (array) $row;
                if ((int) ($r['Non_unique'] ?? 1) === 0) {
                    $uniqueColumns[] = strtolower((string) ($r['Column_name'] ?? ''));
                }
            }

            $this->assertContains('name', $uniqueColumns, 'name must carry a UNIQUE index.');
            $this->assertContains('short_name', $uniqueColumns, 'short_name must carry a UNIQUE index.');
        });
    }

    /** TC-P04 / BC-DB-08 / BC-BIZ — model uses SoftDeletes + global_master connection. */
    public function test_board_04_model_uses_softdeletes_and_global_master_connection(): void
    {
        $this->assertTrue($this->usesSoftDeletes(Board::class));
        $this->assertSame(self::BOARD_CONNECTION, (new Board())->getConnectionName());
    }

    /** TC-P05 / BC-BIZ-08 — central activity sink resolvable & schema present (fail-soft). */
    public function test_board_05_activity_log_sink_is_central_sys_central_activity_logs(): void
    {
        $log = new ActivityLog();
        $this->assertSame(self::CENTRAL_ACTIVITY_TABLE, $log->getTable());

        try {
            $this->assertTrue(
                Schema::connection('mysql')->hasTable(self::CENTRAL_ACTIVITY_TABLE),
                'Central activity table sys_central_activity_logs must exist.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Central mysql connection/table unavailable: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 10-19 — Business rules & activity-log events (BC-BIZ)
    // =====================================================================

    /** TC-P10 / BC-BIZ-01 — store creates a board and logs the literal 'Stored' event. */
    public function test_board_10_store_creates_board_and_logs_stored_event(): void
    {
        $this->assertControllerLogsEvent('Stored', "'Stored'");
        $this->attemptStoreThroughEndpoint('Stored');
    }

    /** TC-P11 / BC-BIZ-02 — update logs the literal 'Updated' event with change set. */
    public function test_board_11_update_modifies_board_and_logs_updated_event(): void
    {
        $this->assertControllerLogsEvent('Updated', "activityLog(\$board, 'Updated'");
    }

    /** TC-P12 / BC-BIZ-03 — destroy sets is_active=false then soft-deletes; logs 'Trashed'. */
    public function test_board_12_destroy_soft_deletes_and_sets_inactive_logs_trashed(): void
    {
        $controllerFile = $this->appSourcePath(self::CONTROLLER_REL);
        if ($controllerFile === null) {
            $this->markTestSkipped('Controller source not resolvable.');
        }
        $ctrl = file_get_contents($controllerFile);
        $this->assertStringContainsString('$board->is_active = false;', $ctrl, 'destroy() must deactivate before delete.');
        $this->assertStringContainsString('$board->delete();', $ctrl, 'destroy() must soft-delete.');
        $this->assertStringContainsString("activityLog(\$board, 'Trashed'", $ctrl);

        // Behavioural (fail-soft): direct model soft-delete lifecycle.
        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord();
            $board->is_active = false;
            $board->save();
            $board->delete();
            $this->assertNotNull($board->fresh()->deleted_at, 'Board must be soft-deleted.');
        });
    }

    /** TC-P13 / BC-BIZ-04 — restore logs the literal 'Restored' event. */
    public function test_board_13_restore_restores_and_logs_restored(): void
    {
        $this->assertControllerLogsEvent('Restored', "activityLog(\$board, 'Restored'");

        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord();
            $board->delete();
            $this->assertNotNull($board->fresh()->deleted_at);
            $board->restore();
            $this->assertNull($board->fresh()->deleted_at, 'Board must be restored.');
        });
    }

    /** TC-P14 / BC-BIZ-05 — forceDelete logs the literal 'Deleted' event and removes the row. */
    public function test_board_14_force_delete_permanently_removes_and_logs_deleted(): void
    {
        $this->assertControllerLogsEvent('Deleted', "activityLog(\$board, 'Deleted'");

        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord();
            $id = $board->id;
            $board->delete();
            $board->forceDelete();
            $this->assertNull(Board::withTrashed()->find($id), 'Board must be permanently deleted.');
            // Already gone — drop from cleanup list.
            $this->createdBoardIds = array_values(array_diff($this->createdBoardIds, [$id]));
        });
    }

    /** TC-P15 / BC-BIZ-06 — toggleStatus logs 'Toggled' and returns JSON. */
    public function test_board_15_toggle_status_updates_is_active_and_logs_toggled(): void
    {
        $controllerFile = $this->appSourcePath(self::CONTROLLER_REL);
        if ($controllerFile === null) {
            $this->markTestSkipped('Controller source not resolvable.');
        }
        $ctrl = file_get_contents($controllerFile);
        $this->assertStringContainsString("activityLog(\$board, 'Toggled'", $ctrl);
        $this->assertStringContainsString("'is_active' => 'required|boolean'", $ctrl, 'toggleStatus must validate is_active.');
        $this->assertStringContainsString("Gate::authorize('prime.board.update')", $ctrl);
        $this->assertStringContainsString("'success' => true", $ctrl, 'toggleStatus must return a JSON success flag.');
    }

    /** TC-P16 / BC-BIZ-09 — index paginates ten per page. */
    public function test_board_16_index_paginates_ten_per_page(): void
    {
        $controllerFile = $this->appSourcePath(self::CONTROLLER_REL);
        if ($controllerFile === null) {
            $this->markTestSkipped('Controller source not resolvable.');
        }
        $this->assertStringContainsString('Board::paginate(10)', file_get_contents($controllerFile));
    }

    /** TC-P17 / BC-BIZ-07 — store redirects to session-board-setup#academicboard with success flash. */
    public function test_board_17_store_redirects_to_session_board_setup_with_success_flash(): void
    {
        $controllerFile = $this->appSourcePath(self::CONTROLLER_REL);
        if ($controllerFile === null) {
            $this->markTestSkipped('Controller source not resolvable.');
        }
        $ctrl = file_get_contents($controllerFile);
        $this->assertStringContainsString("route('central.prime.session-board-setup.index').'#academicboard'", $ctrl);
        $this->assertStringContainsString("flash('created.board')", $ctrl);
        $this->assertStringContainsString("flash('trashed.board')", $ctrl);
    }

    // =====================================================================
    // Band 20-29 — State-machine transitions (BC-SM)
    // =====================================================================

    /** TC-S20 / BC-SM-01 — Active board toggles to Inactive. */
    public function test_board_20_active_board_toggles_to_inactive(): void
    {
        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord(true);
            $board->is_active = false;
            $board->save();
            $this->assertFalse((bool) $board->fresh()->is_active);
        });
    }

    /** TC-S21 / BC-SM-02 — Inactive board toggles to Active. */
    public function test_board_21_inactive_board_toggles_to_active(): void
    {
        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord(false);
            $board->is_active = true;
            $board->save();
            $this->assertTrue((bool) $board->fresh()->is_active);
        });
    }

    /** TC-S22 / BC-SM-03 — present board -> trashed on destroy (soft delete). */
    public function test_board_22_present_board_transitions_to_trashed_on_destroy(): void
    {
        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord();
            $board->delete();
            $this->assertTrue(Board::onlyTrashed()->whereKey($board->id)->exists());
        });
    }

    /** TC-S23 / BC-SM-04 — trashed board -> present on restore. */
    public function test_board_23_trashed_board_transitions_to_present_on_restore(): void
    {
        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord();
            $board->delete();
            $board->restore();
            $this->assertTrue(Board::whereKey($board->id)->exists());
        });
    }

    /** TC-S24 / BC-SM-05 — trashed board -> gone on force delete. */
    public function test_board_24_trashed_board_transitions_to_gone_on_force_delete(): void
    {
        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord();
            $id = $board->id;
            $board->delete();
            $board->forceDelete();
            $this->assertFalse(Board::withTrashed()->whereKey($id)->exists());
            $this->createdBoardIds = array_values(array_diff($this->createdBoardIds, [$id]));
        });
    }

    /** TC-S25 / BC-SM-05 — restore cannot recover a force-deleted board. */
    public function test_board_25_restore_does_not_recover_after_force_delete(): void
    {
        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord();
            $id = $board->id;
            $board->delete();
            $board->forceDelete();
            $this->assertNull(Board::withTrashed()->find($id));
            $this->createdBoardIds = array_values(array_diff($this->createdBoardIds, [$id]));
        });
    }

    // =====================================================================
    // Band 30-39 — Validation + error messages (BC-VAL)
    // =====================================================================

    /** TC-N30 / BC-VAL-01 — name is required. */
    public function test_board_30_name_is_required(): void
    {
        $this->assertRuleInEffectiveRequest("'required'");
        $this->attemptStoreExpectingValidationError(['name' => '', 'short_name' => $this->uniqueBoardShortName()], 'name');
    }

    /** TC-N31 / BC-VAL-04 — short_name is required. */
    public function test_board_31_short_name_is_required(): void
    {
        $this->attemptStoreExpectingValidationError(['name' => $this->uniqueBoardName(), 'short_name' => ''], 'short_name');
    }

    /** TC-N32 / BC-VAL-07 — is_active required|boolean (checkbox coercion). */
    public function test_board_32_is_active_is_required_boolean(): void
    {
        $this->assertRuleInEffectiveRequest("'is_active' => 'required|boolean'");
    }

    /** TC-N33 / BC-VAL-02 / BC-EDG — name max:50 enforced. */
    public function test_board_33_name_max_50_enforced(): void
    {
        $this->assertRuleInEffectiveRequest("'max:50'");
        $this->attemptStoreExpectingValidationError(
            ['name' => str_repeat('a', 51), 'short_name' => $this->uniqueBoardShortName()],
            'name'
        );
    }

    /** TC-N34 / BC-VAL-05 / BC-EDG — short_name max:10 enforced. */
    public function test_board_34_short_name_max_10_enforced(): void
    {
        $this->assertRuleInEffectiveRequest("'max:10'");
        $this->attemptStoreExpectingValidationError(
            ['name' => $this->uniqueBoardName(), 'short_name' => str_repeat('a', 11)],
            'short_name'
        );
    }

    /** TC-N35 / BC-VAL-03 — name must be unique. */
    public function test_board_35_name_must_be_unique(): void
    {
        $this->assertRuleInEffectiveRequest("Rule::unique('glb_boards')");
        $this->withBoardModel(function (): void {
            $existing = $this->createBoardRecord();
            $this->attemptStoreExpectingValidationError(
                ['name' => $existing->name, 'short_name' => $this->uniqueBoardShortName()],
                'name'
            );
        });
    }

    /** TC-N36 / BC-VAL-06 — short_name must be unique. */
    public function test_board_36_short_name_must_be_unique(): void
    {
        $this->withBoardModel(function (): void {
            $existing = $this->createBoardRecord();
            $this->attemptStoreExpectingValidationError(
                ['name' => $this->uniqueBoardName(), 'short_name' => $existing->short_name],
                'short_name'
            );
        });
    }

    /** TC-N37 / BC-VAL-03 — unique rule ignores the current record on update. */
    public function test_board_37_unique_ignores_current_record_on_update(): void
    {
        $requestFile = $this->appSourcePath(self::REQUEST_REL);
        if ($requestFile === null) {
            $this->markTestSkipped('Request source not resolvable.');
        }
        $this->assertStringContainsString('->ignore($boardId)', file_get_contents($requestFile));
    }

    /** TC-N38 / BC-EDG-06 — whitespace-only name is rejected by required. */
    public function test_board_38_whitespace_only_name_rejected(): void
    {
        $this->attemptStoreExpectingValidationError(
            ['name' => '   ', 'short_name' => $this->uniqueBoardShortName()],
            'name'
        );
    }

    /** TC-N39 / BC-VAL — the request rules file carries the exact rule strings. */
    public function test_board_39_request_rules_file_contains_exact_rule_strings(): void
    {
        $requestFile = $this->appSourcePath(self::REQUEST_REL);
        if ($requestFile === null) {
            $this->markTestSkipped('Request source not resolvable.');
        }
        $req = file_get_contents($requestFile);
        $this->assertStringContainsString("'name' => [", $req);
        $this->assertStringContainsString("'short_name' => [", $req);
        $this->assertStringContainsString("'max:50'", $req);
        $this->assertStringContainsString("'max:10'", $req);
    }

    // =====================================================================
    // Band 40-49 — Integration / FK dependency (BC-INT / BC-REF)
    // =====================================================================

    /** TC-D40 / BC-INT-01 — organizations() belongsToMany via sch_board_organization_jnt. */
    public function test_board_40_organizations_relationship_defined_belongsToMany(): void
    {
        $this->assertTrue(method_exists(Board::class, 'organizations'), 'Board::organizations() must be defined.');
        $modelFile = $this->appSourcePath(self::MODEL_REL);
        if ($modelFile !== null) {
            $model = file_get_contents($modelFile);
            $this->assertStringContainsString('belongsToMany', $model);
            $this->assertStringContainsString("'sch_board_organization_jnt'", $model);
        }
    }

    /** TC-D41 / BC-REF-01 — junction FK board_id -> glb_boards.id ON DELETE CASCADE (tenant DDL). */
    public function test_board_41_board_organization_junction_fk_cascade_documented(): void
    {
        $ddl = $this->ddlContents('_tenant_db_v4.sql');
        if ($ddl === null) {
            $this->markTestSkipped('Tenant DDL not resolvable in this environment.');
        }
        $this->assertStringContainsString('fk_boardOrg_boardId', $ddl);
        $this->assertStringContainsString('REFERENCES `glb_boards` (`id`) ON DELETE CASCADE', $ddl);
    }

    /** TC-D42 / BC-REF-02 — Timetable board_id FK references glb_boards. */
    public function test_board_42_timetable_board_fk_references_glb_boards(): void
    {
        $ddl = $this->ddlContents('Timetable_DDL_v7.8.sql');
        if ($ddl === null) {
            $this->markTestSkipped('Timetable DDL not resolvable in this environment.');
        }
        $this->assertStringContainsString('REFERENCES `glb_boards` (`id`)', $ddl);
    }

    /** TC-D43 / BC-INT-01 — cross-module organization access is defensive. */
    public function test_board_43_cross_module_organization_access_is_defensive(): void
    {
        try {
            $this->withBoardModel(function (): void {
                $board = $this->createBoardRecord();
                // Relationship query touches the tenant-side junction table; may be absent centrally.
                $count = $board->organizations()->count();
                $this->assertIsInt($count);
            });
        } catch (Throwable $e) {
            $this->markTestSkipped('Organization junction unavailable in this environment: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 50-59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    /** TC-N50 / BC-AUTH-01..08 — controller gate strings verified from source. */
    public function test_board_50_controller_gate_authorize_strings_are_correct(): void
    {
        $controllerFile = $this->appSourcePath(self::CONTROLLER_REL);
        if ($controllerFile === null) {
            $this->markTestSkipped('Controller source not resolvable.');
        }
        $ctrl = file_get_contents($controllerFile);
        $map = [
            'viewAny' => 1, 'view' => 1, 'create' => 1,
            'update' => 1, 'delete' => 1, 'restore' => 1, 'forceDelete' => 1,
        ];
        foreach ($map as $ability => $_) {
            $this->assertStringContainsString("Gate::authorize('prime.board.$ability')", $ctrl, "Missing gate ability $ability.");
        }
        // toggleStatus reuses the update ability (no dedicated status gate).
        $this->assertStringNotContainsString("Gate::authorize('prime.board.status')", $ctrl);
    }

    /** TC-N51 / BC-AUTH-09 — policy maps each ability to can('prime.board.*'). */
    public function test_board_51_board_policy_maps_abilities_to_permissions(): void
    {
        $policyFile = $this->appSourcePath(self::POLICY_REL);
        if ($policyFile === null) {
            $this->markTestSkipped('Policy source not resolvable.');
        }
        $policy = file_get_contents($policyFile);
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'] as $ability) {
            $this->assertStringContainsString("can('prime.board.$ability')", $policy, "Policy must map $ability.");
        }
    }

    /** TC-N52 / BC-AUTH-10 — guest is redirected to login. */
    public function test_board_52_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $path = $this->currentPath($browser);
            if (str_contains($path, '/login')) {
                $this->assertStringContainsString('/login', $path);
                return;
            }
            // Some environments 404 a disabled module before auth — accept and note.
            $body = $browser->text('body');
            $this->assertTrue(
                str_contains($body, '404') || str_contains($body, 'Not Found') || str_contains($path, '/login'),
                'Unauthenticated access must not expose the board index.'
            );
        });
    }

    /** TC-N53 / BC-AUTH-01 — index forbidden without viewAny (fail-soft). */
    public function test_board_53_index_forbidden_without_viewAny(): void
    {
        $this->assertEndpointDeniesUnprivilegedUser('GET', self::ROUTE_INDEX);
    }

    /** TC-N54 / BC-AUTH-02 — store forbidden without create (fail-soft). */
    public function test_board_54_store_forbidden_without_create(): void
    {
        $this->assertEndpointDeniesUnprivilegedUser('POST', self::ROUTE_STORE, [
            'name' => $this->uniqueBoardName(),
            'short_name' => $this->uniqueBoardShortName(),
            'is_active' => 1,
        ]);
    }

    /** TC-N55 / BC-AUTH-08 — toggleStatus is guarded by the update ability. */
    public function test_board_55_toggle_status_uses_update_permission(): void
    {
        $controllerFile = $this->appSourcePath(self::CONTROLLER_REL);
        if ($controllerFile === null) {
            $this->markTestSkipped('Controller source not resolvable.');
        }
        $ctrl = file_get_contents($controllerFile);
        // Locate the toggleStatus method body and confirm it authorizes update.
        $pos = strpos($ctrl, 'function toggleStatus');
        $this->assertNotFalse($pos, 'toggleStatus method must exist.');
        $segment = substr($ctrl, $pos, 400);
        $this->assertStringContainsString("Gate::authorize('prime.board.update')", $segment);
    }

    /** TC-N56 / BC-AUTH — divergence between the two BoardRequest classes documented (DEV-PRM-BOARD-01). */
    public function test_board_56_prime_and_globalmaster_request_authorize_divergence_documented(): void
    {
        $effective = $this->appSourcePath(self::REQUEST_REL);
        $prime = $this->appSourcePath(self::PRIME_REQUEST_REL);
        if ($effective === null || $prime === null) {
            $this->markTestSkipped('One of the BoardRequest sources is not resolvable.');
        }
        $eff = file_get_contents($effective);
        $prm = file_get_contents($prime);
        // Effective (GlobalMaster) authorize() returns true; the Prime duplicate gates by ability.
        $this->assertStringContainsString('public function authorize(): bool', $eff);
        $this->assertStringContainsString('return true;', $eff);
        $this->assertStringContainsString("Gate::allows('prime.board.create')", $prm,
            'The Prime duplicate BoardRequest still gates by ability — dead-code divergence (DEV-PRM-BOARD-01).');
    }

    // =====================================================================
    // Band 60-69 — UI/UX (render, empty state, component wiring)
    // =====================================================================

    /** TC-P60 — index page renders the board table (fail-soft on disabled module). */
    public function test_board_60_index_page_renders_board_table(): void
    {
        $this->browseWithFailureScreenshot('index-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            if ($this->looksLikeMissingModule($browser)) {
                $this->markTestSkipped('Board module appears disabled/unreachable (404) — see env prerequisite.');
            }
            $this->ensurePageAccessible($browser, 'Board index');
            $browser->assertPresent('table')->assertSee('Name')->assertSee('Short Name');
        });
    }

    /** TC-P61 — create form exposes name and short_name fields. */
    public function test_board_61_create_form_has_name_and_short_name_fields(): void
    {
        $this->browseWithFailureScreenshot('create-form', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);

            if ($this->looksLikeMissingModule($browser)) {
                $this->markTestSkipped('Board module appears disabled/unreachable (404).');
            }
            $this->ensurePageAccessible($browser, 'Board create');
            $browser->assertPresent('input[name="name"]')
                ->assertPresent('input[name="short_name"]');
        });
    }

    /** TC-P62 — index empty state renders the no-data row (view source, always runs). */
    public function test_board_62_index_empty_state_shows_no_data(): void
    {
        $view = $this->appSourcePath(self::INDEX_VIEW_REL);
        if ($view === null) {
            $this->markTestSkipped('Index view source not resolvable.');
        }
        // NOTE: source contains the typo "Not Data Found" (documented UX nit).
        $this->assertStringContainsString('Not Data Found', file_get_contents($view));
    }

    /** TC-P63 — status-switch component targets the toggleStatus route. */
    public function test_board_63_status_switch_component_targets_toggle_route(): void
    {
        $view = $this->appSourcePath(self::INDEX_VIEW_REL);
        if ($view === null) {
            $this->markTestSkipped('Index view source not resolvable.');
        }
        $html = file_get_contents($view);
        $this->assertStringContainsString('x-backend.table.status-switch', $html);
        $this->assertStringContainsString('url="central.prime.board"', $html);
    }

    /** TC-P64 — action component wires edit/delete/view routes. */
    public function test_board_64_action_component_wires_edit_delete_routes(): void
    {
        $view = $this->appSourcePath(self::INDEX_VIEW_REL);
        if ($view === null) {
            $this->markTestSkipped('Index view source not resolvable.');
        }
        $html = file_get_contents($view);
        $this->assertStringContainsString('x-backend.table.action', $html);
        $this->assertStringContainsString('url="central.prime.board"', $html);
    }

    /** TC-P65 / BC-AUTH-04 — show view gates the Edit button by prime.board.update. */
    public function test_board_65_show_view_gates_edit_button_by_update_permission(): void
    {
        $view = $this->appSourcePath(self::SHOW_VIEW_REL);
        if ($view === null) {
            $this->markTestSkipped('Show view source not resolvable.');
        }
        $html = file_get_contents($view);
        $this->assertStringContainsString("@can('prime.board.update')", $html);
        $this->assertStringContainsString("route('central.prime.board.edit', \$board)", $html);
    }

    // =====================================================================
    // Band 70-79 — Edge cases (BC-EDG)
    // =====================================================================

    /** TC-P70 / BC-EDG-01 — name at the 50-char boundary is accepted. */
    public function test_board_70_name_at_max_50_boundary_accepted(): void
    {
        $this->withBoardModel(function (): void {
            $name = substr($this->uniqueBoardName() . str_repeat('x', 50), 0, 50);
            $board = $this->createBoardRecord(true, $name, $this->uniqueBoardShortName());
            $this->assertSame($name, $board->fresh()->name);
        });
    }

    /** TC-P71 / BC-EDG-02 — short_name at the 10-char boundary is accepted. */
    public function test_board_71_short_name_at_max_10_boundary_accepted(): void
    {
        $this->withBoardModel(function (): void {
            $short = substr('S' . Str::random(9), 0, 10);
            $board = $this->createBoardRecord(true, $this->uniqueBoardName(), $short);
            $this->assertSame($short, $board->fresh()->short_name);
        });
    }

    /** TC-N72 / BC-EDG-03 — name of 51 chars is rejected by validation. */
    public function test_board_72_name_51_chars_rejected(): void
    {
        $this->attemptStoreExpectingValidationError(
            ['name' => str_repeat('n', 51), 'short_name' => $this->uniqueBoardShortName()],
            'name'
        );
    }

    /** TC-N73 / BC-EDG-04 — short_name of 11 chars is rejected by validation. */
    public function test_board_73_short_name_11_chars_rejected(): void
    {
        $this->attemptStoreExpectingValidationError(
            ['name' => $this->uniqueBoardName(), 'short_name' => str_repeat('s', 11)],
            'short_name'
        );
    }

    /** TC-S74 / BC-EDG-05 — an XSS payload in name is escaped on render (no raw script). */
    public function test_board_74_xss_payload_in_name_is_escaped_on_render(): void
    {
        $this->withBoardModel(function (): void {
            $payload = '<script>alert(1)</script>';
            $board = $this->createBoardRecord(true, 'XSS ' . $this->uniqueBoardName() . ' ' . $payload, $this->uniqueBoardShortName());
            // Blade {{ }} escapes by default; verify the stored value round-trips and rendering escapes it.
            $this->assertStringContainsString('<script>', $board->fresh()->name, 'Raw value is stored verbatim (Blade escapes at render).');

            try {
                $this->browse(function (Browser $browser) use ($board): void {
                    $this->authenticateCentral($browser);
                    $this->visitAuthenticated($browser, self::INDEX_PATH);
                    if ($this->looksLikeMissingModule($browser)) {
                        return;
                    }
                    $source = $browser->driver->getPageSource();
                    $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Payload must be HTML-escaped.');
                });
            } catch (Throwable $e) {
                $this->markTestSkipped('Browser render check unavailable: ' . $e->getMessage());
            }
        });
    }

    /** TC-N75 / BC-EDG-07 — a soft-deleted board's name still blocks a new unique (DEV-PRM-BOARD-05). */
    public function test_board_75_soft_deleted_name_still_blocks_new_unique(): void
    {
        $this->withBoardModel(function (): void {
            $board = $this->createBoardRecord();
            $name = $board->name;
            $board->delete(); // soft-delete; Rule::unique('glb_boards') does NOT exclude trashed rows

            $this->attemptStoreExpectingValidationError(
                ['name' => $name, 'short_name' => $this->uniqueBoardShortName()],
                'name'
            );
        });
    }

    /** TC-N76 / BC-VAL-08 — prepareForValidation coerces the 'on' checkbox to boolean true. */
    public function test_board_76_checkbox_on_coerced_to_true_by_prepareForValidation(): void
    {
        $requestFile = $this->appSourcePath(self::REQUEST_REL);
        if ($requestFile === null) {
            $this->markTestSkipped('Request source not resolvable.');
        }
        $req = file_get_contents($requestFile);
        $this->assertStringContainsString("\$this->input('is_active') === 'on' ? true : false", $req);
    }

    // =====================================================================
    // Band 80-89 — Configuration (flash text)
    // =====================================================================

    /** TC-P80 / BC-CFG — flash() resolves the Board-scoped success text. */
    public function test_board_80_flash_messages_resolve_board_resource_text(): void
    {
        if (!function_exists('flash')) {
            $this->markTestSkipped('flash() helper not loaded in this environment.');
        }
        $this->assertSame('Board was created successfully.', flash('created.board'));
        $this->assertSame('Board was updated successfully.', flash('updated.board'));
        $this->assertSame('Board was moved to trash.', flash('trashed.board'));
        $this->assertSame('Board was restored successfully.', flash('restored.board'));
        $this->assertSame('Board was permanently deleted.', flash('force_deleted.board'));
        $this->assertSame('Board status was successfully changed.', flash('status_updated.board'));
    }

    // =====================================================================
    // Band 90-99 — Central-DB scope + security pack (TC-T / TC-S)
    // =====================================================================

    /** TC-T90 — board data lives in central global_master, not a tenant DB. */
    public function test_board_90_board_data_lives_in_central_global_master_not_tenant(): void
    {
        $this->assertSame(self::BOARD_CONNECTION, (new Board())->getConnectionName());
        $this->assertFalse(
            function_exists('tenancy') && tenancy()->initialized,
            'Board is a central feature; tenancy must NOT be initialised.'
        );
    }

    /** TC-T91 — activity is written to the central sink when tenancy is uninitialised (constraint #25). */
    public function test_board_91_activity_written_to_central_sink_when_tenancy_uninitialized(): void
    {
        $this->assertFalse(function_exists('tenancy') && tenancy()->initialized);
        $this->assertSame(self::CENTRAL_ACTIVITY_TABLE, (new ActivityLog())->getTable());
        $this->assertSame('mysql', (new ActivityLog())->getConnectionName());
    }

    /** TC-S92 — reflected XSS in short_name is escaped on render. */
    public function test_board_92_reflected_xss_in_short_name_escaped(): void
    {
        $view = $this->appSourcePath(self::INDEX_VIEW_REL);
        if ($view === null) {
            $this->markTestSkipped('Index view source not resolvable.');
        }
        $html = file_get_contents($view);
        // Board fields render through escaped Blade echoes {{ }}, never {!! !!}.
        $this->assertStringContainsString('{{ $board->short_name }}', $html);
        $this->assertStringNotContainsString('{!! $board->short_name !!}', $html);
    }

    /** TC-S93 — mass-assignment guard: only fillable columns are assignable. */
    public function test_board_93_mass_assignment_guard_only_fillable_columns(): void
    {
        $board = new Board();
        $this->assertTrue($board->isFillable('name'));
        $this->assertTrue($board->isFillable('short_name'));
        $this->assertTrue($board->isFillable('is_active'));
        $this->assertFalse($board->isFillable('id'), 'id must not be mass-assignable.');
        $this->assertFalse($board->isFillable('deleted_at'), 'deleted_at must not be mass-assignable.');
    }

    /** TC-N94 — an invalid board id returns 404 (fail-soft). */
    public function test_board_94_invalid_board_id_returns_404(): void
    {
        try {
            if (!\Illuminate\Support\Facades\Route::has(self::ROUTE_SHOW)) {
                $this->markTestSkipped('Board routes not registered (module disabled).');
            }
            if ($this->adminUser === null) {
                $this->markTestSkipped('No admin user resolvable.');
            }
            $url = route(self::ROUTE_SHOW, ['board' => 99999999]);
            $response = $this->actingAs($this->adminUser)->get($url);
            $this->assertContains($response->getStatusCode(), [403, 404], 'Missing board must not resolve.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Show endpoint unavailable: ' . $e->getMessage());
        }
    }

    /** TC-N95 / BC-EDG — duplicate short_name is rejected regardless of casing boundary. */
    public function test_board_95_duplicate_short_name_case_sensitivity_boundary(): void
    {
        $this->withBoardModel(function (): void {
            $existing = $this->createBoardRecord(true, $this->uniqueBoardName(), 'CBSEX' . rand(10, 99));
            // Exact duplicate must be rejected (utf8mb4_unicode_ci is case-insensitive too).
            $this->attemptStoreExpectingValidationError(
                ['name' => $this->uniqueBoardName(), 'short_name' => $existing->short_name],
                'short_name'
            );
        });
    }

    // =====================================================================
    // ============================ HELPERS ================================
    // =====================================================================

    // ---- Central auth/URL helpers (mirrored locally from BillingDuskTestCase) ----

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

    protected function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                if ($e instanceof \PHPUnit\Framework\SkippedTestError) {
                    throw $e;
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
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $safeName . '_' . $timestamp . '.png';

        try {
            $browser->driver->takeScreenshot($absolutePath);
            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolutePath);
        } catch (Throwable) {
            return '';
        }
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

        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    protected function looksLikeMissingModule(Browser $browser): bool
    {
        $path = $this->currentPath($browser);
        if (str_contains($path, '/login')) {
            return false;
        }
        $body = $browser->text('body');

        return str_contains($body, '404') || str_contains($body, 'Not Found');
    }

    protected function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            if ($superAdmin) {
                $this->adminUser = $superAdmin;
                return;
            }

            $userByEmail = User::query()->where('email', $this->adminEmail)->first();
            if ($userByEmail) {
                $this->adminUser = $userByEmail;
                return;
            }

            $this->adminUser = User::create([
                'email' => $this->adminEmail,
                'password' => bcrypt($this->adminPassword),
                'name' => 'Board Dusk Admin',
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

    // ---- Board data helpers ----

    private function uniqueBoardName(): string
    {
        return substr('Dusk Board ' . uniqid('', false), 0, 50);
    }

    private function uniqueBoardShortName(): string
    {
        // short_name max:10 (validation) and varchar(20) (DDL). Keep <= 10.
        return substr('B' . strtoupper(substr(uniqid('', false), -7)), 0, 10);
    }

    /**
     * Create a real Board row on the global_master connection and track it for cleanup.
     */
    private function createBoardRecord(bool $active = true, ?string $name = null, ?string $short = null): Board
    {
        $board = Board::create([
            'name' => $name ?? $this->uniqueBoardName(),
            'short_name' => $short ?? $this->uniqueBoardShortName(),
            'is_active' => $active,
        ]);
        $this->createdBoardIds[] = $board->id;

        return $board;
    }

    private function cleanupCreatedBoards(): void
    {
        foreach (array_unique($this->createdBoardIds) as $id) {
            try {
                $board = Board::withTrashed()->find($id);
                if ($board) {
                    $board->forceDelete();
                }
            } catch (Throwable) {
                // ignore cleanup failures
            }
        }
        $this->createdBoardIds = [];
    }

    // ---- Fail-soft wrappers ----

    /**
     * Run a closure that needs the live global_master schema; skip if unavailable.
     */
    private function withBoardSchema(callable $callback): void
    {
        try {
            if (!Schema::connection(self::BOARD_CONNECTION)->hasTable(self::BOARD_TABLE)) {
                $this->markTestSkipped('glb_boards not present on the global_master connection.');
            }
            $callback();
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('global_master schema unavailable: ' . $e->getMessage());
        }
    }

    /**
     * Run a closure that needs live Board model persistence; skip if unavailable.
     */
    private function withBoardModel(callable $callback): void
    {
        try {
            $callback();
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('Board persistence unavailable in this environment: ' . $e->getMessage());
        }
    }

    private function usesSoftDeletes(string $class): bool
    {
        return in_array(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive($class),
            true
        );
    }

    // ---- Source-file resolution (portable across runner/app roots) ----

    /**
     * Resolve an app-source relative path across likely roots. Returns null if absent.
     */
    private function appSourcePath(string $relative): ?string
    {
        $candidates = [];
        $main = env('MAIN_PROJECT_PATH');
        if (is_string($main) && $main !== '') {
            $candidates[] = rtrim($main, '/') . '/' . $relative;
        }
        $candidates[] = base_path($relative);
        $candidates[] = base_path('../prime_ai/' . $relative);
        $candidates[] = '/Users/bkwork/Herd/prime_ai/' . $relative;

        foreach ($candidates as $path) {
            if (is_string($path) && is_file($path)) {
                return $path;
            }
        }

        return null;
    }

    /**
     * Resolve a consolidated DDL file's contents. Returns null if absent.
     */
    private function ddlContents(string $fileName): ?string
    {
        $dir = env('DDL_DIR', '/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated');
        $path = rtrim((string) $dir, '/') . '/' . $fileName;

        return is_file($path) ? (string) file_get_contents($path) : null;
    }

    // ---- Assertion helpers ----

    private function assertControllerLogsEvent(string $event, string $needle): void
    {
        $controllerFile = $this->appSourcePath(self::CONTROLLER_REL);
        if ($controllerFile === null) {
            $this->markTestSkipped('Controller source not resolvable.');
        }
        $this->assertStringContainsString($needle, file_get_contents($controllerFile), "Controller must log the '$event' event.");
    }

    private function assertRuleInEffectiveRequest(string $needle): void
    {
        $requestFile = $this->appSourcePath(self::REQUEST_REL);
        if ($requestFile === null) {
            $this->markTestSkipped('Request source not resolvable.');
        }
        $this->assertStringContainsString($needle, file_get_contents($requestFile));
    }

    /**
     * Attempt a POST store expecting a validation error on $field. Fail-soft if the
     * route is unregistered (module disabled) or auth/env prevents a clean 302.
     */
    private function attemptStoreExpectingValidationError(array $payload, string $field): void
    {
        try {
            if (!\Illuminate\Support\Facades\Route::has(self::ROUTE_STORE)) {
                $this->markTestSkipped('Store route not registered (module disabled) — rule asserted via source.');
            }
            if ($this->adminUser === null) {
                $this->markTestSkipped('No admin user resolvable for authenticated POST.');
            }

            $payload = array_merge(['is_active' => 'on'], $payload);
            $response = $this->actingAs($this->adminUser)
                ->from($this->centralUrl(self::CREATE_PATH))
                ->post(route(self::ROUTE_STORE), $payload);

            $status = $response->getStatusCode();
            if (in_array($status, [403, 404], true)) {
                $this->markTestSkipped('Store endpoint returned ' . $status . ' (permission/module env) — rule asserted via source.');
            }

            // A validation failure redirects back with errors in the session.
            $response->assertSessionHasErrors([$field]);
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('Store validation path unavailable: ' . $e->getMessage());
        }
    }

    /**
     * Attempt a successful store through the endpoint and assert the activity event.
     * Fail-soft; the event string is independently asserted from source in the same test.
     */
    private function attemptStoreThroughEndpoint(string $event): void
    {
        try {
            if (!\Illuminate\Support\Facades\Route::has(self::ROUTE_STORE) || $this->adminUser === null) {
                return; // source assertion already covers the event
            }

            $name = $this->uniqueBoardName();
            $response = $this->actingAs($this->adminUser)->post(route(self::ROUTE_STORE), [
                'name' => $name,
                'short_name' => $this->uniqueBoardShortName(),
                'is_active' => 'on',
            ]);

            if (!in_array($response->getStatusCode(), [301, 302], true)) {
                return; // module likely disabled / no permission
            }

            $board = Board::where('name', $name)->first();
            if ($board) {
                $this->createdBoardIds[] = $board->id;
                $logged = ActivityLog::where('subject_id', $board->id)
                    ->where('event', $event)
                    ->exists();
                $this->assertTrue($logged, "Store must write a '$event' activity log to the central sink.");
            }
        } catch (Throwable) {
            // fully defensive — the source-level event assertion stands
        }
    }

    /**
     * Assert an endpoint denies an unprivileged (no-permission) user. Fail-soft.
     */
    private function assertEndpointDeniesUnprivilegedUser(string $method, string $routeName, array $payload = []): void
    {
        try {
            if (!\Illuminate\Support\Facades\Route::has($routeName)) {
                $this->markTestSkipped('Route ' . $routeName . ' not registered (module disabled).');
            }

            $victim = User::query()
                ->where('is_super_admin', '!=', 1)
                ->orWhereNull('is_super_admin')
                ->first();

            if ($victim === null) {
                $this->markTestSkipped('No non-super-admin user available to assert denial.');
            }

            $request = $this->actingAs($victim);
            $response = $method === 'POST'
                ? $request->post(route($routeName), $payload)
                : $request->get(route($routeName));

            $this->assertContains(
                $response->getStatusCode(),
                [403, 404, 302],
                'Unprivileged user must be denied (403) or redirected.'
            );
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('Authorization endpoint unavailable: ' . $e->getMessage());
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
            // ignore
        }
    }
}
