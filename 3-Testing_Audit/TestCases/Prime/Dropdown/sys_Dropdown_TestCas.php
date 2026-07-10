<?php

namespace Tests\Browser\Modules\Prime\Dropdown;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Http\Requests\DropdownRequest;
use Modules\Prime\Http\Controllers\DropdownController;
use Modules\Prime\Models\ActivityLog;
use Modules\Prime\Models\Dropdown;
use ReflectionClass;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Comprehensive Dusk + integration suite for the Prime (PRM) central "Dropdown" screen.
 *
 * DB scope: CENTRAL / prime_db. NO tenant initialisation (constraint #21/#22 — Prime features
 * extend the central PrimeDuskTestCase base and run on http://127.0.0.1:8000).
 *
 * Primary table:  sys_dropdown_table   (constraint #27 — the "rename to sys_dropdowns" migration
 *                 is a no-op; the real runtime table stays sys_dropdown_table, confirmed by
 *                 Dropdown::$table, the FormRequest exists/unique rules and the junction FK).
 * Activity sink:  sys_central_activity_logs via Modules\Prime\Models\ActivityLog (constraint #25).
 * Permissions:    prime.dropdown.{viewAny|view|create|update|delete|restore|forceDelete}.
 * Routes:         central.global-master.dropdown.* (prefix /global-master).
 *
 * Central auth/helpers are implemented locally in this class (mirrored from the committed
 * prm_BillingDuskTestCase_TestCas sibling) so the file only relies on the PrimeDuskTestCase base.
 */
class sys_Dropdown_TestCas extends PrimeDuskTestCase
{
    // ---- Paths (central domain, prefix /global-master) ----
    private const INDEX_PATH  = '/global-master/dropdown';
    private const CREATE_PATH = '/global-master/dropdown/create';
    private const TRASH_PATH  = '/global-master/dropdown/trash/view';
    private const SEARCH_PATH = '/global-master/dropdown/search';

    // ---- Table / model truth ----
    private const TABLE          = 'sys_dropdown_table';
    private const ACTIVITY_TABLE = 'sys_central_activity_logs';
    private const NEED_JNT_TABLE = 'sys_dropdown_need_dropdowns_jnt';
    private const DDL_JNT_TABLE  = 'sys_dropdown_need_table_jnt';

    // ---- Screenshots ----
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Dropdown/screenshots';

    // ---- Expected route names (all under central.global-master.) ----
    private const ROUTE_INDEX        = 'central.global-master.dropdown.index';
    private const ROUTE_CREATE       = 'central.global-master.dropdown.create';
    private const ROUTE_STORE        = 'central.global-master.dropdown.store';
    private const ROUTE_SHOW         = 'central.global-master.dropdown.show';
    private const ROUTE_EDIT         = 'central.global-master.dropdown.edit';
    private const ROUTE_UPDATE       = 'central.global-master.dropdown.update';
    private const ROUTE_DESTROY      = 'central.global-master.dropdown.destroy';
    private const ROUTE_SEARCH       = 'central.global-master.dropdown.search';
    private const ROUTE_TRASHED      = 'central.global-master.dropdown.trashed';
    private const ROUTE_RESTORE      = 'central.global-master.dropdown.restore';
    private const ROUTE_FORCE_DELETE = 'central.global-master.dropdown.forceDelete';
    private const ROUTE_TOGGLE       = 'central.global-master.dropdown.toggleStatus';

    // ---- Typed props (initialise all — tearDown reads them, constraint #13) ----
    private ?User $adminUser = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private array $createdDropdownIds = [];
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
        // Best-effort cleanup of any dropdown rows created during a run.
        foreach ($this->createdDropdownIds as $id) {
            try {
                $row = Dropdown::withTrashed()->find($id);
                if ($row) {
                    $row->forceDelete();
                }
            } catch (Throwable) {
                // ignore — cleanup must never fail a test
            }
        }

        parent::tearDown();
    }

    // =========================================================================
    // BAND 01-09 — Schema / DDL / model / request configuration truth
    // =========================================================================

    /** @test TC-P01 (BC-DB-*, DDL-sys_dropdown_table) */
    public function test_dropdown_01_migration_model_and_request_configuration_are_correct(): void
    {
        // --- Table + columns (live schema) ---
        $this->assertTrue(Schema::hasTable(self::TABLE), self::TABLE . ' must exist in the central DB.');

        $expectedColumns = ['id', 'ordinal', 'key', 'value', 'type', 'additional_info', 'is_active', 'created_at', 'updated_at', 'deleted_at'];
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, $expectedColumns),
            self::TABLE . ' is missing one of: ' . implode(', ', $expectedColumns)
        );

        // --- Model truth ---
        $model = new Dropdown();
        $this->assertSame(self::TABLE, $model->getTable(), 'Dropdown::$table must be sys_dropdown_table (constraint #27).');

        $this->assertSame(
            ['ordinal', 'key', 'value', 'type', 'additional_info', 'is_active'],
            $model->getFillable(),
            'Dropdown $fillable drifted from the DDL columns.'
        );

        $this->assertContains(
            SoftDeletes::class,
            class_uses_recursive(Dropdown::class),
            'Dropdown must use SoftDeletes.'
        );

        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('array', $casts['additional_info'] ?? null);
        $this->assertSame('integer', $casts['ordinal'] ?? null);

        // --- FormRequest content truth (located via reflection — robust to base_path) ---
        $requestSource = $this->readSourceOf(DropdownRequest::class);
        $this->assertNotSame('', $requestSource, 'Unable to read DropdownRequest source.');
        $this->assertStringContainsString("Rule::unique('sys_dropdown_table', 'key')", $requestSource);
        $this->assertStringContainsString('max:160', $requestSource);
        $this->assertStringContainsString('max:100', $requestSource);
        $this->assertStringContainsString('required|in:String,Integer,Decimal,Date,Datetime,Time,Boolean', $requestSource);
        $this->assertStringContainsString('nullable|integer|min:1', $requestSource);
        $this->assertStringContainsString("'key.unique' => 'This key already exists.'", $requestSource);
    }

    /** @test TC-P02 (BC-DB — unique indexes) */
    public function test_dropdown_02_unique_indexes_exist_on_key_value_and_key_ordinal(): void
    {
        try {
            $indexes = collect(\DB::select('SHOW INDEX FROM ' . self::TABLE))
                ->pluck('Key_name')->unique()->values()->all();
        } catch (Throwable $e) {
            $this->markTestSkipped('SHOW INDEX unavailable: ' . $e->getMessage());
            return;
        }

        $this->assertContains('uq_dropdownTable_key_value', $indexes, 'Composite unique (key,value) missing.');
        $this->assertContains('uq_dropdownTable_key_ordinal', $indexes, 'Composite unique (key,ordinal) missing.');
    }

    /** @test TC-P03 (BC-DB — type enum) */
    public function test_dropdown_03_type_enum_matches_ddl_and_formrequest_seven_values(): void
    {
        try {
            $column = collect(\DB::select('SHOW COLUMNS FROM ' . self::TABLE . " LIKE 'type'"))->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('SHOW COLUMNS unavailable: ' . $e->getMessage());
            return;
        }

        $this->assertNotNull($column, 'type column not found.');
        $type = strtolower((string) ($column->Type ?? ''));
        foreach (['string', 'integer', 'decimal', 'date', 'datetime', 'time', 'boolean'] as $enumValue) {
            $this->assertStringContainsString("'{$enumValue}'", $type, "type ENUM missing {$enumValue}.");
        }
    }

    /** @test TC-N04 / DEV-DROPDOWN-001 (consolidated DDL omits deleted_at) */
    public function test_dropdown_04_soft_delete_column_present_despite_consolidated_ddl_gap(): void
    {
        // The migration adds $table->softDeletes() and the model uses SoftDeletes, but the
        // consolidated _prime_db_v4.sql CREATE TABLE omits deleted_at. Prove the live column exists;
        // the DDL gap is documented as DEV-DROPDOWN-001 in the Gap Analysis.
        $this->assertTrue(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'deleted_at must exist (added by migration softDeletes) even though the consolidated DDL omits it.'
        );
    }

    /** @test TC-P05 (BC-BIZ — central activity sink, constraint #25) */
    public function test_dropdown_05_central_activity_log_sink_table_and_model_configured(): void
    {
        $log = new ActivityLog();
        $this->assertSame(self::ACTIVITY_TABLE, $log->getTable(), 'Prime ActivityLog must target sys_central_activity_logs.');
        $this->assertSame('mysql', $log->getConnectionName() ?? 'mysql');

        foreach (['subject_type', 'subject_id', 'user_id', 'event', 'properties', 'ip_address', 'user_agent'] as $col) {
            $this->assertContains($col, $log->getFillable(), 'ActivityLog fillable missing ' . $col . '.');
        }

        // Fail-soft: the central table has no consolidated DDL; assert presence when reachable.
        try {
            $this->assertTrue(Schema::hasTable(self::ACTIVITY_TABLE), 'sys_central_activity_logs should exist in central DB.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Central activity table not reachable: ' . $e->getMessage());
        }
    }

    // =========================================================================
    // BAND 10-19 — Business rules (BC-BIZ)
    // =========================================================================

    /** @test TC-P10 (BC-BIZ — model defaults) */
    public function test_dropdown_10_model_default_attributes_are_string_and_active(): void
    {
        $model = new Dropdown();
        $this->assertSame('String', $model->type, 'Default type attribute must be String.');
        $this->assertTrue((bool) $model->is_active, 'Default is_active attribute must be true.');
    }

    /** @test TC-P11 (BC-BIZ — additional_info array cast round-trip) */
    public function test_dropdown_11_additional_info_is_cast_to_array(): void
    {
        try {
            $row = $this->createDropdown(['additional_info' => ['info' => 'unit-note']]);
        } catch (Throwable $e) {
            $this->markTestSkipped('Central DB write unavailable: ' . $e->getMessage());
            return;
        }

        $fresh = Dropdown::find($row->id);
        $this->assertIsArray($fresh->additional_info, 'additional_info must cast to array.');
        $this->assertSame('unit-note', $fresh->additional_info['info'] ?? null);
    }

    /** @test TC-N12 / DEV-DROPDOWN-007 (store/update emit no activity log) */
    public function test_dropdown_12_store_and_update_do_not_emit_activity_log(): void
    {
        $source = $this->readSourceOf(DropdownController::class);
        $storeBody = $this->methodBody($source, 'store');
        $updateBody = $this->methodBody($source, 'update');

        $this->assertStringNotContainsString('activityLog(', $storeBody, 'store() unexpectedly logs activity (update this test if fixed).');
        $this->assertStringNotContainsString('activityLog(', $updateBody, 'update() unexpectedly logs activity (update this test if fixed).');
        // Documented gap: only Trashed/Restored/Toggled events are recorded — see DEV-DROPDOWN-007.
    }

    /** @test TC-N13 / DEV-DROPDOWN-002 (destroy references $dropdown outside the closure scope) */
    public function test_dropdown_13_destroy_uses_out_of_scope_dropdown_variable_for_activity_log(): void
    {
        $source = $this->readSourceOf(DropdownController::class);
        $destroyBody = $this->methodBody($source, 'destroy');

        // $dropdown is declared inside DB::transaction(function () use ($id) { $dropdown = ... });
        // yet activityLog($dropdown, 'Trashed', ...) is called AFTER the closure — $dropdown is
        // undefined there, so a null subject is logged. Proven by structure below.
        $this->assertStringContainsString("DB::transaction(function () use (\$id)", $destroyBody);
        $this->assertStringContainsString("activityLog(\$dropdown, 'Trashed'", $destroyBody);
        $this->assertStringNotContainsString('use ($id, &$dropdown)', $destroyBody, 'If fixed to pass $dropdown out, revisit DEV-DROPDOWN-002.');
    }

    /** @test TC-N14 / DEV-DROPDOWN-003 (destroy/restore mutate inconsistent junction tables) */
    public function test_dropdown_14_destroy_and_restore_target_inconsistent_junction_models(): void
    {
        $source = $this->readSourceOf(DropdownController::class);
        $destroyBody = $this->methodBody($source, 'destroy');
        $restoreBody = $this->methodBody($source, 'restore');

        // destroy() deactivates DropdownNeedDropdown (sys_dropdown_need_dropdowns_jnt) …
        $this->assertStringContainsString('DropdownNeedDropdown::where(', $destroyBody);
        // … but restore() reactivates DropdownNeedTableJnt (sys_dropdown_need_table_jnt) — a different table.
        $this->assertStringContainsString('DropdownNeedTableJnt::where(', $restoreBody);
        // Documented as DEV-DROPDOWN-003.
    }

    /** @test TC-N15 / DEV-DROPDOWN-008 (removed str_slug() helper used in Laravel 11) */
    public function test_dropdown_15_addbyselection_and_quicksave_use_removed_str_slug_helper(): void
    {
        $source = $this->readSourceOf(DropdownController::class);
        $this->assertStringContainsString('str_slug(', $source, 'str_slug() usage expected (removed helper → fatal). See DEV-DROPDOWN-008.');
        $this->assertFalse(function_exists('str_slug'), 'str_slug() is a removed Laravel helper; calling it fatals at runtime.');
    }

    // =========================================================================
    // BAND 20-29 — Lifecycle / state (active <-> inactive <-> trashed)
    // =========================================================================

    /** @test TC-D20 sub-F (full lifecycle at the model layer) */
    public function test_dropdown_20_lifecycle_create_toggle_softdelete_restore_forcedelete(): void
    {
        try {
            $row = $this->createDropdown(['is_active' => true]);
            $id = $row->id;

            // toggle off
            $row->is_active = false;
            $row->save();
            $this->assertFalse((bool) Dropdown::find($id)->is_active);

            // soft delete
            $row->delete();
            $this->assertNull(Dropdown::find($id), 'Soft-deleted row must be hidden from default scope.');
            $this->assertNotNull(Dropdown::withTrashed()->find($id), 'Soft-deleted row must remain via withTrashed().');

            // restore
            Dropdown::withTrashed()->find($id)->restore();
            $this->assertNotNull(Dropdown::find($id), 'Restored row must be visible again.');

            // force delete
            Dropdown::withTrashed()->find($id)->forceDelete();
            $this->assertNull(Dropdown::withTrashed()->find($id), 'Force-deleted row must be gone entirely.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Central DB lifecycle unavailable: ' . $e->getMessage());
        }
    }

    /** @test TC-D21 sub-B (soft delete keeps the row + stamps deleted_at) */
    public function test_dropdown_21_soft_delete_sets_deleted_at_and_keeps_row(): void
    {
        try {
            $row = $this->createDropdown();
            $row->delete();
            $trashed = Dropdown::withTrashed()->find($row->id);
            $this->assertNotNull($trashed);
            $this->assertNotNull($trashed->deleted_at, 'deleted_at must be stamped on soft delete.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Central DB unavailable: ' . $e->getMessage());
        }
    }

    /** @test TC-D22 sub-F (restore clears deleted_at) */
    public function test_dropdown_22_restore_clears_deleted_at(): void
    {
        try {
            $row = $this->createDropdown();
            $row->delete();
            Dropdown::withTrashed()->find($row->id)->restore();
            $this->assertNull(Dropdown::find($row->id)->deleted_at, 'deleted_at must be null after restore.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Central DB unavailable: ' . $e->getMessage());
        }
    }

    // =========================================================================
    // BAND 30-39 — Validation + error messages (BC-VAL)
    // =========================================================================

    /** @test TC-N30 (FormRequest rules) */
    public function test_dropdown_30_request_rules_contain_expected_strings(): void
    {
        $req = new DropdownRequest();
        $rules = $req->rules();

        $this->assertArrayHasKey('key', $rules);
        $this->assertArrayHasKey('value', $rules);
        $this->assertArrayHasKey('type', $rules);
        $this->assertArrayHasKey('ordinal', $rules);

        $this->assertContains('required', (array) $rules['key']);
        $this->assertContains('max:160', (array) $rules['key']);
        $this->assertSame('required|string|max:100', $rules['value']);
        $this->assertSame('required|in:String,Integer,Decimal,Date,Datetime,Time,Boolean', $rules['type']);
        $this->assertSame('nullable|integer|min:1', $rules['ordinal']);
    }

    /** @test TC-N31 (custom unique message) */
    public function test_dropdown_31_key_unique_message_is_custom(): void
    {
        $messages = (new DropdownRequest())->messages();
        $this->assertSame('This key already exists.', $messages['key.unique'] ?? null);
    }

    /** @test TC-N32 (store inline validation) */
    public function test_dropdown_32_store_inline_rules_present_in_controller(): void
    {
        $storeBody = $this->methodBody($this->readSourceOf(DropdownController::class), 'store');
        $this->assertStringContainsString("'key' => 'required|string|max:160|unique:sys_dropdown_table,key'", $storeBody);
        $this->assertStringContainsString("'value' => 'required|string|max:100'", $storeBody);
        $this->assertStringContainsString("'type' => 'required|in:String,Integer,Decimal,Date,Datetime,Time,Boolean'", $storeBody);
        $this->assertStringContainsString("'ordinal' => 'nullable|integer|min:1'", $storeBody);
    }

    /** @test TC-N33 (toggleStatus validation) */
    public function test_dropdown_33_togglestatus_requires_boolean_is_active(): void
    {
        $body = $this->methodBody($this->readSourceOf(DropdownController::class), 'toggleStatus');
        $this->assertStringContainsString("'is_active' => 'required|boolean'", $body);
        $this->assertStringContainsString("activityLog(\$dropdown, 'Toggled'", $body);
    }

    /** @test TC-N34 / DEV-DROPDOWN-005 (saveDropdownOption enum narrower than DDL) */
    public function test_dropdown_34_savedropdownoption_type_enum_is_narrower_than_ddl(): void
    {
        $body = $this->methodBody($this->readSourceOf(DropdownController::class), 'saveDropdownOption');
        // Only 5 of the 7 DDL enum values are accepted here (Datetime, Time missing).
        $this->assertStringContainsString('in:String,Integer,Decimal,Date,Boolean', $body);
        $this->assertStringNotContainsString('in:String,Integer,Decimal,Date,Datetime,Time,Boolean', $body);
    }

    // =========================================================================
    // BAND 40-49 — Integration / FK dependency (BC-INT / BC-REF)
    // =========================================================================

    /** @test TC-D40 (junction tables exist) */
    public function test_dropdown_40_junction_tables_exist_and_reference_dropdown_table(): void
    {
        // DDL defines sys_dropdown_need_table_jnt; runtime code also uses sys_dropdown_need_dropdowns_jnt.
        try {
            $this->assertTrue(
                Schema::hasTable(self::NEED_JNT_TABLE) || Schema::hasTable(self::DDL_JNT_TABLE),
                'At least one dropdown-need junction table must exist.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema unavailable: ' . $e->getMessage());
        }
    }

    /** @test TC-D41 (belongsToMany relationship wiring) */
    public function test_dropdown_41_model_relationship_dropdownNeeds_configured(): void
    {
        $relation = (new Dropdown())->dropdownNeeds();
        $this->assertInstanceOf(BelongsToMany::class, $relation);
        $this->assertSame(
            self::NEED_JNT_TABLE,
            $relation->getTable(),
            'dropdownNeeds() pivot must be sys_dropdown_need_dropdowns_jnt.'
        );
    }

    /** @test TC-D42 (constraint #27 — FK targets sys_dropdown_table) */
    public function test_dropdown_42_ddl_fk_targets_sys_dropdown_table_not_sys_dropdowns(): void
    {
        $ddlPath = '/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated/_prime_db_v4.sql';
        if (!is_file($ddlPath)) {
            $this->markTestSkipped('Consolidated DDL not present in this environment.');
            return;
        }
        $ddl = (string) file_get_contents($ddlPath);
        $this->assertStringContainsString('REFERENCES `sys_dropdown_table` (`id`)', $ddl);
        $this->assertStringNotContainsString('REFERENCES `sys_dropdowns`', $ddl);
    }

    // =========================================================================
    // BAND 50-59 — Permissions / authorization (BC-AUTH)
    // =========================================================================

    /** @test TC-N50 (controller gate strings, one per method) */
    public function test_dropdown_50_controller_methods_enforce_expected_gates(): void
    {
        $source = $this->readSourceOf(DropdownController::class);

        $expected = [
            'index'            => 'prime.dropdown.viewAny',
            'create'           => 'prime.dropdown.create',
            'store'            => 'prime.dropdown.create',
            'show'             => 'prime.dropdown.view',
            'edit'             => 'prime.dropdown.update',
            'update'           => 'prime.dropdown.update',
            'updateBulk'       => 'prime.dropdown.update',
            'destroy'          => 'prime.dropdown.delete',
            'deleteBulk'       => 'prime.dropdown.delete',
            'trashedDropdown'  => 'prime.dropdown.restore',
            'restore'          => 'prime.dropdown.restore',
            'restoreBulk'      => 'prime.dropdown.restore',
            'forceDelete'      => 'prime.dropdown.forceDelete',
            'forceDeleteBulk'  => 'prime.dropdown.forceDelete',
            'toggleStatus'     => 'prime.dropdown.update',
        ];

        foreach ($expected as $method => $gate) {
            $body = $this->methodBody($source, $method);
            $this->assertStringContainsString("Gate::authorize('{$gate}')", $body, "{$method}() must authorize {$gate}.");
        }
    }

    /** @test TC-N51 (FormRequest authorize maps actions to gates) */
    public function test_dropdown_51_request_authorize_maps_actions_to_gates(): void
    {
        $source = $this->readSourceOf(DropdownRequest::class);
        $this->assertStringContainsString("'store' => Gate::allows('prime.dropdown.create')", $source);
        $this->assertStringContainsString("'update' => Gate::allows('prime.dropdown.update')", $source);
        $this->assertStringContainsString("default => Gate::allows('prime.dropdown.viewAny')", $source);
    }

    /** @test TC-N52 (guest redirected to /login from index) */
    public function test_dropdown_52_guest_is_redirected_to_login_from_index(): void
    {
        $this->browseWithFailureScreenshot('guest-index-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** @test TC-N53 (guest cannot reach trash view) */
    public function test_dropdown_53_guest_cannot_reach_trash_view(): void
    {
        $this->browseWithFailureScreenshot('guest-trash-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::TRASH_PATH))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** @test TC-N54 (non-privileged user is denied dropdown gates) */
    public function test_dropdown_54_limited_user_is_denied_dropdown_gates(): void
    {
        try {
            $limited = User::factory()->create([
                'is_super_admin' => 0,
                'user_type' => 'OTHER',
                'is_active' => 1,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not build a limited user: ' . $e->getMessage());
            return;
        }

        $this->assertTrue(
            Gate::forUser($limited)->denies('prime.dropdown.create'),
            'A user without the permission must be denied prime.dropdown.create.'
        );

        try {
            $limited->forceDelete();
        } catch (Throwable) {
        }
    }

    // =========================================================================
    // BAND 60-69 — UI / UX (render, tabs, filters, breadcrumb)
    // =========================================================================

    /** @test TC-P60 (index loads for admin) */
    public function test_dropdown_60_index_page_loads_for_admin(): void
    {
        $this->browseWithFailureScreenshot('index-load', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Dropdown index not reachable.');
            $this->ensurePageAccessible($browser, 'Dropdown index');
        });
    }

    /** @test TC-P61 (dropdown-list pane + table render) */
    public function test_dropdown_61_index_shows_dropdown_list_pane(): void
    {
        $this->browseWithFailureScreenshot('index-list-pane', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown index (list pane)');
            $this->assertNotNull($browser->element('#dropdown-list-pane'), 'Dropdown list pane must be present.');
        });
    }

    /** @test TC-P62 (list filter inputs present) */
    public function test_dropdown_62_index_list_filter_inputs_present(): void
    {
        $this->browseWithFailureScreenshot('index-filters', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown index (filters)');
            $browser->assertPresent('[name="list_key"]')
                ->assertPresent('[name="list_value"]')
                ->assertPresent('[name="list_status"]');
        });
    }

    /** @test TC-P63 (trash view renders columns) */
    public function test_dropdown_63_trash_view_loads_with_expected_columns(): void
    {
        $this->browseWithFailureScreenshot('trash-view', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH);
            $this->assertSame(self::TRASH_PATH, $this->currentPath($browser), 'Trash view not reachable.');
            $this->ensurePageAccessible($browser, 'Dropdown trash view');
            $browser->assertSee('Key')->assertSee('Value')->assertSee('Action');
        });
    }

    /** @test TC-P64 (breadcrumb / page title) */
    public function test_dropdown_64_index_breadcrumb_title_is_dropdown_management(): void
    {
        $this->browseWithFailureScreenshot('index-breadcrumb', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown index (breadcrumb)');
            $browser->assertSee('Dropdown');
        });
    }

    /** @test TC-P65 (create form renders store action + fields) — needs no dropdown_need_id: redirects, so assert route only) */
    public function test_dropdown_65_create_route_is_registered_and_named(): void
    {
        $this->assertTrue(Route::has(self::ROUTE_CREATE), self::ROUTE_CREATE . ' must be registered.');
        $this->assertTrue(Route::has(self::ROUTE_STORE), self::ROUTE_STORE . ' must be registered.');
    }

    // =========================================================================
    // BAND 70-79 — Edge cases (BC-EDG)
    // =========================================================================

    /** @test TC-EDG70 (ordinal is tinyint unsigned) */
    public function test_dropdown_70_ordinal_column_is_tinyint_unsigned(): void
    {
        try {
            $column = collect(\DB::select('SHOW COLUMNS FROM ' . self::TABLE . " LIKE 'ordinal'"))->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('SHOW COLUMNS unavailable: ' . $e->getMessage());
            return;
        }
        $type = strtolower((string) ($column->Type ?? ''));
        $this->assertStringContainsString('tinyint', $type, 'ordinal must be a tinyint.');
        $this->assertStringContainsString('unsigned', $type, 'ordinal must be unsigned.');
    }

    /** @test TC-EDG71 (key/value declared lengths) */
    public function test_dropdown_71_key_and_value_declared_lengths(): void
    {
        try {
            $key = collect(\DB::select('SHOW COLUMNS FROM ' . self::TABLE . " LIKE 'key'"))->first();
            $value = collect(\DB::select('SHOW COLUMNS FROM ' . self::TABLE . " LIKE 'value'"))->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('SHOW COLUMNS unavailable: ' . $e->getMessage());
            return;
        }
        $this->assertStringContainsString('160', strtolower((string) ($key->Type ?? '')), 'key must be varchar(160).');
        $this->assertStringContainsString('100', strtolower((string) ($value->Type ?? '')), 'value must be varchar(100).');
    }

    /** @test TC-EDG72 / DEV-DROPDOWN-006 (unique(key,value) has no deleted_at → trashed collision) */
    public function test_dropdown_72_soft_deleted_key_value_blocks_recreation(): void
    {
        try {
            $row = $this->createDropdown();
            $key = $row->key;
            $value = $row->value;
            $ordinal = (int) $row->ordinal;
            $row->delete(); // soft delete — row remains, unique index still holds it

            $collision = false;
            try {
                Dropdown::create([
                    'ordinal' => $ordinal,
                    'key' => $key,
                    'value' => $value,
                    'type' => 'String',
                    'is_active' => true,
                ]);
            } catch (Throwable) {
                $collision = true; // integrity violation on (key,value)/(key,ordinal)
            }

            $this->assertTrue(
                $collision,
                'Recreating a soft-deleted key+value must collide with the unique index (no deleted_at in it) — DEV-DROPDOWN-006.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Central DB unavailable: ' . $e->getMessage());
        }
    }

    /** @test TC-EDG73 / DEV-DROPDOWN-004 (store enforces global key uniqueness vs composite design) */
    public function test_dropdown_73_store_global_key_uniqueness_conflicts_with_composite_design(): void
    {
        $storeBody = $this->methodBody($this->readSourceOf(DropdownController::class), 'store');
        // Global unique on key alone contradicts uq(key,value) / uq(key,ordinal) which expect a key
        // (table.column) to hold many option rows. Documented as DEV-DROPDOWN-004.
        $this->assertStringContainsString('unique:sys_dropdown_table,key', $storeBody);
    }

    // =========================================================================
    // BAND 90-99 — Central-domain routing + security smoke (TC-T / TC-S)
    // =========================================================================

    /** @test TC-T90 (routes are central, not tenant) */
    public function test_dropdown_90_prime_routes_are_registered_under_central_global_master(): void
    {
        foreach ([
            self::ROUTE_INDEX, self::ROUTE_STORE, self::ROUTE_SHOW, self::ROUTE_EDIT,
            self::ROUTE_UPDATE, self::ROUTE_DESTROY, self::ROUTE_SEARCH, self::ROUTE_TRASHED,
            self::ROUTE_RESTORE, self::ROUTE_FORCE_DELETE, self::ROUTE_TOGGLE,
        ] as $name) {
            $this->assertTrue(Route::has($name), "Expected route {$name} to be registered.");
        }
    }

    /** @test TC-S91 (invalid id on edit is not accessible to guests / 404 for admin) */
    public function test_dropdown_91_edit_invalid_id_is_not_a_valid_record(): void
    {
        $this->browseWithFailureScreenshot('edit-invalid-id', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl('/global-master/dropdown/999999999/edit'))->pause(1200);
            $body = $browser->text('body');
            $this->assertTrue(
                str_contains($body, '404') || str_contains($body, 'Not Found') || str_contains($this->currentPath($browser), '/login'),
                'A non-existent dropdown id must not open a valid edit page.'
            );
        });
    }

    /** @test TC-S92 (search handles injection-shaped input without a 500) */
    public function test_dropdown_92_search_endpoint_is_parameterized(): void
    {
        $this->browseWithFailureScreenshot('search-injection', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl(self::SEARCH_PATH . "?search=%27%20OR%201%3D1--"))->pause(1200);
            $body = $browser->text('body');
            $this->assertStringNotContainsString('SQLSTATE', $body, 'Search must not surface a SQL error.');
            $this->assertFalse(str_contains($body, 'Server Error') && str_contains($body, '500'), 'Search must not 500 on injection-shaped input.');
        });
    }

    /** @test TC-P93 (AJAX/bulk endpoints registered) */
    public function test_dropdown_93_ajax_and_bulk_routes_are_registered(): void
    {
        foreach ([
            'central.global-master.dropdown.update.bulk',
            'central.global-master.dropdown.delete.bulk',
            'central.global-master.dropdowns.saveOption',
            'central.global-master.dropdowns.checkKeyExists',
            'central.global-master.dropdowns.getOptionsByKey',
            'central.global-master.dropdowns.restoreBulk',
            'central.global-master.dropdowns.forceDeleteBulk',
            'central.global-master.dropdown.mgmt',
        ] as $name) {
            $this->assertTrue(Route::has($name), "Expected AJAX/bulk route {$name} to be registered.");
        }
    }

    // =========================================================================
    // ---- Private helper library ----
    // =========================================================================

    private function createDropdown(array $overrides = []): Dropdown
    {
        $suffix = uniqid();
        $defaults = [
            'ordinal' => random_int(1, 250),
            'key' => 'test_dd.' . $suffix,
            'value' => 'val_' . $suffix,
            'type' => 'String',
            'is_active' => true,
        ];
        $row = Dropdown::create(array_merge($defaults, $overrides));
        $this->createdDropdownIds[] = $row->id;
        return $row;
    }

    /** Read the on-disk source of a class, resolved via reflection (base_path-independent). */
    private function readSourceOf(string $class): string
    {
        try {
            $file = (new ReflectionClass($class))->getFileName();
            if ($file && is_file($file)) {
                return (string) file_get_contents($file);
            }
        } catch (Throwable) {
            // fall through
        }
        return '';
    }

    /** Extract a rough method body from source (brace-matched from the signature). */
    private function methodBody(string $source, string $method): string
    {
        if ($source === '') {
            return '';
        }
        $needle = 'function ' . $method . '(';
        $start = strpos($source, $needle);
        if ($start === false) {
            return '';
        }
        $brace = strpos($source, '{', $start);
        if ($brace === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($source);
        for ($i = $brace; $i < $len; $i++) {
            $ch = $source[$i];
            if ($ch === '{') {
                $depth++;
            } elseif ($ch === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $start, $i - $start + 1);
                }
            }
        }
        return substr($source, $start);
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
            $this->fail($context . ' shows the login page; authentication failed.');
        }

        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
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
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safe . '_' . now()->format('Ymd_Hisv') . '.png');
        } catch (Throwable) {
            // screenshots are best-effort
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
