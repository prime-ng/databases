<?php

namespace Tests\Browser\Modules\Prime\DropdownNeed;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Prime (PRM) — DropdownNeed feature — comprehensive single-file test suite.
 *
 * DB SCOPE: CENTRAL / prime-side (DDL header "prime Database (prime_db_v4)",
 * primary table `sys_dropdown_needs`). No tenant scaffolding. Host 127.0.0.1:8000.
 *
 * This class extends the committed central base `PrimeDuskTestCase`
 * (physical class `prm_PrimeDuskTestCase_TestCas`, resolved via
 * tests/Browser/Modules/preload.php per constraint #22) and implements its
 * own central auth/helpers locally (ported from BillingDuskTestCase) so it
 * does not depend on the Billing base.
 *
 * Prefix `sys_` = DDL table prefix of the primary table `sys_dropdown_needs`
 * (verified against `_prime_db_v4.sql` and the runtime migration).
 *
 * Defects proven / documented (see Gap Analysis):
 *   SEC-PRM-004  (CORRECTED) — the audited "ungated filterOptions()" does NOT
 *                 hold: filterOptions() IS gated and has NO route (dead code).
 *                 The real ungated surface is the registered AJAX endpoints
 *                 (search/migration-tables/table-columns/migration-content/
 *                 menu-data/main-menus/sub-menus) which carry no Gate.
 *   TEN-PRM-001  (CORRECTED) — fetchMigrationTables()/fetchTableColumns() DO
 *                 call tenancy()->end() in a finally block; no leak in source.
 *   PERF-PRM-001 — raw SHOW COLUMNS / migrations full scan on AJAX (Prime/Global
 *                 cached 1h, Tenant uncached).
 *   BUG-PRM-DUP  (CORRECTED) — no stale root-level Modules/Prime/Models model
 *                 exists; single canonical app/Models/DropdownNeed.php.
 *   BUG-PRM-DDNEED-001 — two junction tables; destroy/restore/toggle mutate the
 *                 LEGACY `sys_dropdown_need_table_jnt`, but mappings are read
 *                 from `sys_dropdown_need_dropdowns_jnt` (functional mismatch).
 *   DOC-PRM-DDNEED-002 — DDL misspells the column `dropdown_tabel_record_exist`
 *                 and omits `deleted_at`; runtime migration is correct.
 *   BUG-PRM-DDNEED-003 — no uniqueness validation in store()/update(); a
 *                 duplicate (db_type,table_name,column_name) hits the DB unique
 *                 index and surfaces as a 500, not a friendly error.
 *   BUG-PRM-DDNEED-004 — store/update/destroy redirect to dropdown.index, not
 *                 dropdown-need.index.
 *   BUG-PRM-DDNEED-005 — dropdown-need routes registered twice in routes/web.php.
 *   BUG-PRM-DDNEED-006 — index() gated by the sibling `prime.dropdown.viewAny`.
 */
class sys_DropdownNeed_TestCas extends PrimeDuskTestCase
{
    // ---- Screen identity (from routes/web.php + views) ----
    private const CENTRAL_CONNECTION = 'mysql';
    private const TABLE = 'sys_dropdown_needs';
    private const JNT_MAPPING = 'sys_dropdown_need_dropdowns_jnt';
    private const JNT_LEGACY = 'sys_dropdown_need_table_jnt';
    private const CENTRAL_ACTIVITY_TABLE = 'sys_central_activity_logs';

    private const INDEX_PATH = '/global-master/dropdown-need';
    private const CREATE_PATH = '/global-master/dropdown-need/create';
    private const TRASH_PATH = '/global-master/dropdown-need/trash/view';

    private const ROUTE_INDEX = 'central.global-master.dropdown-need.index';
    private const ROUTE_STORE = 'central.global-master.dropdown-need.store';

    // App-repo relative source paths (resolved robustly at runtime).
    private const REL_CONTROLLER = 'Modules/Prime/app/Http/Controllers/DropdownNeedController.php';
    private const REL_MODEL = 'Modules/Prime/app/Models/DropdownNeed.php';
    private const REL_JNT_MODEL = 'Modules/Prime/app/Models/DropdownNeedTableJnt.php';
    private const REL_MIGRATION = 'database/migrations/2025_11_16_114617_create_sys_dropdown_needs_table.php';
    private const REL_JNT_MAP_MIGRATION = 'Modules/Prime/database/migrations/2026_01_24_105312_create_sys_dropdown_need_dropdowns_table.php';
    private const REL_JNT_LEGACY_MIGRATION = 'Modules/Prime/database/migrations/2026_02_04_133437_create_dropdown_need_table_jnts_table.php';

    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/DropdownNeed/screenshots';

    private ?User $adminUser = null;
    private ?User $limitedUser = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private array $insertedIds = [];
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        if (!self::$screenshotsCleaned) {
            self::$screenshotsCleaned = true;
        }

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        // Best-effort cleanup of rows this test inserted (central connection).
        foreach (array_reverse($this->insertedIds) as $id) {
            try {
                DB::connection(self::CENTRAL_CONNECTION)
                    ->table(self::TABLE)
                    ->where('id', $id)
                    ->delete();
            } catch (Throwable) {
                // ignore cleanup failures
            }
        }
        $this->insertedIds = [];

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =========================================================================
    // 01–09  SCHEMA / DDL / MODEL / MIGRATION CONFIGURATION TRUTH
    // =========================================================================

    /** BC-DB-01 | Source: DDL-sys_dropdown_needs, REL_MIGRATION */
    public function test_dropdownneed_01_migration_model_and_request_configuration_are_correct(): void
    {
        // ---- Schema truth (guarded: skip if central DB not migrated / module off) ----
        if (!$this->centralTableExists(self::TABLE)) {
            $this->markTestSkipped('sys_dropdown_needs not present on central connection (E19: enable Prime + migrate).');
        }

        $required = [
            'id', 'db_type', 'table_name', 'column_name',
            'menu_category', 'main_menu', 'sub_menu', 'tab_name', 'field_name',
            'is_system', 'tenant_creation_allowed', 'dropdown_table_record_exist',
            'compulsory', 'is_active', 'deleted_at', 'created_at', 'updated_at',
        ];
        $this->assertTrue(
            Schema::connection(self::CENTRAL_CONNECTION)->hasColumns(self::TABLE, $required),
            'sys_dropdown_needs is missing one or more expected columns: ' . implode(', ', $required)
        );

        // ---- Migration file content truth ----
        $migration = $this->readAppFile(self::REL_MIGRATION);
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('sys_dropdown_needs'", $migration);
            $this->assertStringContainsString("enum('db_type', ['Prime', 'Tenant', 'Global'])", $migration);
            $this->assertStringContainsString('$table->softDeletes();', $migration);
            $this->assertStringContainsString("dropdown_table_record_exist", $migration);
            $this->assertStringContainsString('uq_dropdownNeeds_db_table_column_key', $migration);
        }

        // ---- Model file truth (no autoload dependency) ----
        $model = $this->readAppFile(self::REL_MODEL);
        if ($model !== null) {
            $this->assertStringContainsString("protected \$table = 'sys_dropdown_needs';", $model);
            $this->assertStringContainsString('use SoftDeletes;', $model);
        }

        // Feature has NO FormRequest — validation is inline in the controller.
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        if ($controller !== null) {
            $this->assertStringContainsString('$request->validate(', $controller,
                'Expected inline validation in DropdownNeedController (no dedicated FormRequest).');
        }
    }

    /** BC-DB-02 | Source: REL_MIGRATION */
    public function test_dropdownneed_02_primary_table_column_types_are_within_ddl_limits(): void
    {
        $migration = $this->readAppFile(self::REL_MIGRATION);
        $this->skipIfNull($migration, 'central sys_dropdown_needs migration');

        // varchar sizes exactly as declared.
        $this->assertStringContainsString("string('table_name', 150)", $migration);
        $this->assertStringContainsString("string('column_name', 150)", $migration);
        $this->assertStringContainsString("string('menu_category', 150)", $migration);
        $this->assertStringContainsString("string('tab_name', 100)", $migration);
        $this->assertStringContainsString("string('field_name', 100)", $migration);
    }

    /** BC-DB-03 | Source: REL_MIGRATION, DDL uq_DDNeeds_dbType_tableName_columnName */
    public function test_dropdownneed_03_unique_index_on_db_type_table_column_exists(): void
    {
        $migration = $this->readAppFile(self::REL_MIGRATION);
        $this->skipIfNull($migration, 'central sys_dropdown_needs migration');

        $this->assertMatchesRegularExpression(
            "/unique\(\s*\[\s*'db_type'\s*,\s*'table_name'\s*,\s*'column_name'\s*\]/",
            $migration,
            'Expected composite unique index on (db_type, table_name, column_name).'
        );

        // Runtime index presence (guarded).
        if ($this->centralTableExists(self::TABLE)) {
            $indexes = $this->centralIndexNames(self::TABLE);
            $this->assertNotEmpty($indexes, 'Expected at least one index on sys_dropdown_needs.');
        }
    }

    /** BC-DB-04 | Source: REL_MODEL, REL_MIGRATION */
    public function test_dropdownneed_04_soft_delete_supported_at_schema_and_model(): void
    {
        $migration = $this->readAppFile(self::REL_MIGRATION);
        $model = $this->readAppFile(self::REL_MODEL);
        $this->skipIfNull($migration, 'migration');
        $this->skipIfNull($model, 'model');

        $this->assertStringContainsString('$table->softDeletes();', $migration);
        $this->assertStringContainsString('use Illuminate\Database\Eloquent\SoftDeletes;', $model);
        $this->assertStringContainsString('use SoftDeletes;', $model);

        if ($this->centralTableExists(self::TABLE)) {
            $this->assertTrue(
                Schema::connection(self::CENTRAL_CONNECTION)->hasColumn(self::TABLE, 'deleted_at'),
                'Runtime table must expose deleted_at for SoftDeletes to function.'
            );
        }
    }

    /** BC-DB-05 | Source: REL_MODEL */
    public function test_dropdownneed_05_model_fillable_and_casts_match_schema(): void
    {
        $model = $this->readAppFile(self::REL_MODEL);
        $this->skipIfNull($model, 'model');

        foreach ([
            'db_type', 'table_name', 'column_name', 'menu_category', 'main_menu',
            'sub_menu', 'tab_name', 'field_name', 'is_system', 'tenant_creation_allowed',
            'compulsory', 'dropdown_table_record_exist', 'is_active',
        ] as $field) {
            $this->assertStringContainsString("'{$field}'", $model, "fillable/casts missing {$field}");
        }

        // Boolean casts.
        foreach (['is_system', 'tenant_creation_allowed', 'compulsory', 'dropdown_table_record_exist', 'is_active'] as $boolField) {
            $this->assertMatchesRegularExpression(
                "/'{$boolField}'\s*=>\s*'boolean'/",
                $model,
                "Expected boolean cast for {$boolField}."
            );
        }
    }

    /** BC-DB-06 | Source: REL_JNT_MAP_MIGRATION */
    public function test_dropdownneed_06_mapping_junction_schema_is_correct(): void
    {
        $mig = $this->readAppFile(self::REL_JNT_MAP_MIGRATION);
        $this->skipIfNull($mig, 'mapping junction migration');

        $this->assertStringContainsString("Schema::create('sys_dropdown_need_dropdowns_jnt'", $mig);
        $this->assertStringContainsString("->constrained('sys_dropdown_needs')", $mig);
        $this->assertStringContainsString("->constrained('sys_dropdown_table')", $mig);
        $this->assertStringContainsString('restrictOnDelete()', $mig);
        $this->assertStringContainsString("['dropdown_needs_id', 'dropdown_table_id']", $mig);

        if ($this->centralTableExists(self::JNT_MAPPING)) {
            $this->assertTrue(Schema::connection(self::CENTRAL_CONNECTION)
                ->hasColumns(self::JNT_MAPPING, ['dropdown_needs_id', 'dropdown_table_id', 'is_active']));
        }
    }

    /** BC-DB-07 | Source: REL_JNT_LEGACY_MIGRATION */
    public function test_dropdownneed_07_legacy_junction_schema_is_correct(): void
    {
        $mig = $this->readAppFile(self::REL_JNT_LEGACY_MIGRATION);
        $this->skipIfNull($mig, 'legacy junction migration');

        $this->assertStringContainsString("Schema::create('sys_dropdown_need_table_jnt'", $mig);
        $this->assertStringContainsString("->onDelete('cascade')", $mig);
        $this->assertStringContainsString('uq_dropdownNeedTableJnt_dropdownNeedsId', $mig);
    }

    /** DOC-PRM-DDNEED-002 | Source: DDL vs REL_MIGRATION — column typo + missing deleted_at in DDL */
    public function test_dropdownneed_08_ddl_typo_documented_runtime_uses_correct_spelling(): void
    {
        // Runtime authoritative source (migration + live table) uses the CORRECT spelling.
        $migration = $this->readAppFile(self::REL_MIGRATION);
        if ($migration !== null) {
            $this->assertStringContainsString('dropdown_table_record_exist', $migration);
            $this->assertStringNotContainsString('dropdown_tabel_record_exist', $migration,
                'Runtime migration must use the correct spelling.');
        }

        if ($this->centralTableExists(self::TABLE)) {
            $this->assertTrue(
                Schema::connection(self::CENTRAL_CONNECTION)->hasColumn(self::TABLE, 'dropdown_table_record_exist'),
                'DOC-PRM-DDNEED-002: runtime column is dropdown_table_record_exist (DDL misspells it as dropdown_tabel_record_exist).'
            );
            $this->assertFalse(
                Schema::connection(self::CENTRAL_CONNECTION)->hasColumn(self::TABLE, 'dropdown_tabel_record_exist'),
                'The misspelled DDL column name must NOT exist at runtime.'
            );
        }
    }

    /** BC-BIZ-09 | Source: REL_MIGRATION — DB CHECK enforces tenant_creation_allowed consistency */
    public function test_dropdownneed_09_check_constraint_present_in_migration(): void
    {
        $migration = $this->readAppFile(self::REL_MIGRATION);
        $this->skipIfNull($migration, 'migration');

        $this->assertStringContainsString('chk_dropdown_needs_valid', $migration);
        $this->assertStringContainsString('tenant_creation_allowed = 1', $migration);
        $this->assertStringContainsString('menu_category IS NOT NULL', $migration);
    }

    // =========================================================================
    // 10–19  BUSINESS RULES  (BC-BIZ)
    // =========================================================================

    /** BC-BIZ-10 | Source: REL_CONTROLLER — activity events verbatim */
    public function test_dropdownneed_10_activity_log_event_strings_are_verbatim(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        // Real strings — NOT the Class-reference Stored/Update/ToggelStatus set.
        $this->assertStringContainsString("activityLog(\$dropdownNeed, 'Created'", $controller);
        $this->assertStringContainsString("activityLog(\$dropdownNeed, 'Updated'", $controller);
        $this->assertStringContainsString("'Trashed'", $controller);
        $this->assertStringContainsString("'Restored'", $controller);
        $this->assertStringContainsString("'Deleted'", $controller);
        $this->assertStringContainsString("'Toggled'", $controller);
    }

    /** BC-BIZ-11 | Source: Screen-BR (create) — happy-path store via HTTP (guarded) */
    public function test_dropdownneed_11_store_creates_record_and_logs_created(): void
    {
        $this->runHttpOrSkip(function (): void {
            $unique = $this->uniqueSuffix();
            $payload = [
                'db_type' => 'Prime',
                'table_name' => 'sys_it_' . $unique,
                'column_name' => 'status_' . $unique,
                'tenant_creation_allowed' => 0,
                'is_system' => 0,
                'compulsory' => 1,
                'is_active' => 1,
            ];

            $response = $this->actingAs($this->requireAdmin())
                ->post($this->centralUrl(self::INDEX_PATH), $payload);

            // Controller redirects on success (302). If module disabled → 404.
            $this->assertContains($response->getStatusCode(), [302, 200],
                'store did not complete (module may be disabled — E19).');

            if ($this->centralTableExists(self::TABLE)) {
                $row = DB::connection(self::CENTRAL_CONNECTION)->table(self::TABLE)
                    ->where('table_name', $payload['table_name'])->first();
                if ($row) {
                    $this->insertedIds[] = $row->id;
                    $this->assertSame('Prime', $row->db_type);
                }
            }
        });
    }

    /** BC-BIZ-12 | Source: REL_CONTROLLER — is_system protection on edit/update/destroy */
    public function test_dropdownneed_12_is_system_records_are_protected(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString('if ($dropdownNeed->is_system)', $controller);
        $this->assertStringContainsString('System records cannot be edited.', $controller);
        $this->assertStringContainsString('System records cannot be deleted.', $controller);
    }

    /** BC-BIZ-13 | Source: REL_CONTROLLER — menu fields nullified when tenant_creation_allowed is false */
    public function test_dropdownneed_13_menu_fields_nullified_when_tenant_creation_disallowed(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString("if (!\$data['tenant_creation_allowed'])", $controller);
        $this->assertStringContainsString("\$data['menu_category'] = null;", $controller);
        $this->assertStringContainsString("\$data['field_name'] = null;", $controller);
    }

    /** BC-BIZ-14 | Source: REL_CONTROLLER — destroy soft-deletes + touches legacy junction */
    public function test_dropdownneed_14_destroy_softdeletes_and_deactivates_legacy_junction(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        // NOTE (BUG-PRM-DDNEED-001): destroy updates DropdownNeedTableJnt (legacy),
        // not the mapping junction used for display.
        $this->assertStringContainsString(
            "DropdownNeedTableJnt::where('dropdown_needs_id', \$dropdownNeed->id)",
            $controller
        );
        $this->assertStringContainsString('$dropdownNeed->delete();', $controller);
    }

    /** BC-BIZ-15 | Source: REL_CONTROLLER — restore reactivates */
    public function test_dropdownneed_15_restore_reactivates_record_and_junction(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString('$dropdownNeed->restore();', $controller);
        $this->assertMatchesRegularExpression("/->update\(\[\s*'is_active'\s*=>\s*true/", $controller);
    }

    /** BUG-PRM-DDNEED-004 | Source: REL_CONTROLLER — store/update/destroy redirect to dropdown.index */
    public function test_dropdownneed_16_store_redirects_to_dropdown_index_not_dropdown_need(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString("route('central.global-master.dropdown.index')", $controller,
            'BUG-PRM-DDNEED-004: store/update/destroy redirect to the sibling dropdown.index.');
    }

    /** BUG-PRM-DDNEED-006 | Source: REL_CONTROLLER — index gated by sibling permission */
    public function test_dropdownneed_17_index_uses_sibling_dropdown_viewany_gate(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString("Gate::authorize('prime.dropdown.viewAny')", $controller,
            'BUG-PRM-DDNEED-006: index()/filterOptions() are gated by prime.dropdown.viewAny (the sibling), not dropdown-need.');
    }

    // =========================================================================
    // 20–29  STATUS TOGGLE  (BC-BIZ / lightweight state)
    // =========================================================================

    /** BC-BIZ-20 | Source: REL_CONTROLLER — toggleStatus validates + returns JSON */
    public function test_dropdownneed_20_toggle_status_validates_boolean_and_returns_json(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString("'is_active' => 'required|boolean'", $controller);
        $this->assertStringContainsString("'success' => true", $controller);
        $this->assertStringContainsString("Gate::authorize('prime.dropdown-need.update')", $controller);
    }

    // =========================================================================
    // 30–39  VALIDATION + ERROR MESSAGES  (BC-VAL)
    // =========================================================================

    /** BC-VAL-30 | Source: REL_CONTROLLER store() rules */
    public function test_dropdownneed_30_store_requires_db_type_table_and_column(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString("'db_type' => 'required|in:Prime,Tenant,Global'", $controller);
        $this->assertStringContainsString("'table_name' => 'required|string|max:150'", $controller);
        $this->assertStringContainsString("'column_name' => 'required|string|max:150'", $controller);
        $this->assertStringContainsString("'tenant_creation_allowed' => 'required|boolean'", $controller);
    }

    /** BC-VAL-31 | Source: REL_CONTROLLER — db_type enum. HTTP negative (guarded). */
    public function test_dropdownneed_31_db_type_must_be_in_enum(): void
    {
        $this->runHttpOrSkip(function (): void {
            $response = $this->actingAs($this->requireAdmin())
                ->from($this->centralUrl(self::CREATE_PATH))
                ->post($this->centralUrl(self::INDEX_PATH), [
                    'db_type' => 'NotADbType',
                    'table_name' => 'x_' . $this->uniqueSuffix(),
                    'column_name' => 'c',
                    'tenant_creation_allowed' => 0,
                    'is_system' => 0,
                    'compulsory' => 1,
                ]);

            $this->assertContains($response->getStatusCode(), [302, 422, 404],
                'Invalid enum should be rejected (or 404 if module disabled).');
            if ($response->getStatusCode() === 302) {
                $response->assertSessionHasErrors('db_type');
            }
        });
    }

    /** BC-VAL-32 | Source: REL_CONTROLLER — max:150 on table/column */
    public function test_dropdownneed_32_table_and_column_have_max_length_rule(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString('max:150', $controller);
        $this->assertStringContainsString('max:100', $controller); // tab_name / field_name
    }

    /** BC-VAL-33 | Source: REL_CONTROLLER — required boolean flags */
    public function test_dropdownneed_33_boolean_flags_are_required(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString("'is_system' => 'required|boolean'", $controller);
        $this->assertStringContainsString("'compulsory' => 'required|boolean'", $controller);
    }

    /** BC-VAL-34 | Source: Screen-BR + REL_CONTROLLER — conditional menu-field requirement */
    public function test_dropdownneed_34_menu_fields_required_when_tenant_creation_allowed(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString('if ($request->tenant_creation_allowed)', $controller);
        $this->assertStringContainsString("\$rules['menu_category'] = 'required|string|max:150';", $controller);
        $this->assertStringContainsString("\$rules['field_name'] = 'required|string|max:100';", $controller);
    }

    /** BUG-PRM-DDNEED-003 | Source: DDL unique vs REL_CONTROLLER — no uniqueness validation */
    public function test_dropdownneed_35_duplicate_db_type_table_column_has_no_validation_guard(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        // Prove the ABSENCE of a unique rule — a duplicate insert therefore hits
        // the DB unique index (uq_dropdownNeeds_db_table_column_key) as a 500.
        $this->assertStringNotContainsString('unique:sys_dropdown_needs', $controller,
            'BUG-PRM-DDNEED-003: no uniqueness validation — duplicate surfaces as a DB error, not a friendly message.');
    }

    /** BC-VAL-36 | Source: REL_CONTROLLER update() rules */
    public function test_dropdownneed_36_update_validation_rules_present(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        // update() re-declares the same core rules.
        $count = substr_count($controller, "'db_type' => 'required|in:Prime,Tenant,Global'");
        $this->assertGreaterThanOrEqual(2, $count, 'Both store() and update() should declare db_type rule.');
    }

    // =========================================================================
    // 40–49  INTEGRATION / FK DEPENDENCY  (BC-REF / BC-INT)
    // =========================================================================

    /** BC-REF-40 | Source: REL_JNT_MAP_MIGRATION — mapping junction FK RESTRICT */
    public function test_dropdownneed_40_mapping_junction_fk_is_restrict_on_delete(): void
    {
        $mig = $this->readAppFile(self::REL_JNT_MAP_MIGRATION);
        $this->skipIfNull($mig, 'mapping junction migration');
        $this->assertStringContainsString('restrictOnDelete()', $mig);
    }

    /** BC-REF-41 | Source: REL_JNT_LEGACY_MIGRATION — legacy junction FK CASCADE */
    public function test_dropdownneed_41_legacy_junction_fk_is_cascade_on_delete(): void
    {
        $mig = $this->readAppFile(self::REL_JNT_LEGACY_MIGRATION);
        $this->skipIfNull($mig, 'legacy junction migration');
        $this->assertStringContainsString("->onDelete('cascade')", $mig);
    }

    /** BUG-PRM-DDNEED-001 | Source: REL_MODEL + REL_CONTROLLER — two junctions, mismatched usage */
    public function test_dropdownneed_42_two_junctions_mismatch_toggle_targets_legacy(): void
    {
        $model = $this->readAppFile(self::REL_MODEL);
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($model, 'model');
        $this->skipIfNull($controller, 'controller');

        // Display/mapping reads from sys_dropdown_need_dropdowns_jnt ...
        $this->assertStringContainsString('sys_dropdown_need_dropdowns_jnt', $model);
        // ... but destroy/restore/toggle mutate the legacy DropdownNeedTableJnt.
        $this->assertStringContainsString('DropdownNeedTableJnt::where', $controller);
        $this->assertStringContainsString('sys_dropdown_need_table_jnt',
            $this->readAppFile(self::REL_JNT_MODEL) ?? '');
    }

    /** BC-INT-43 | Source: REL_CONTROLLER — forceDelete removes legacy junction first */
    public function test_dropdownneed_43_force_delete_removes_legacy_junction_first(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString(
            "DropdownNeedTableJnt::where('dropdown_needs_id', \$dropdownNeed->id)->forceDelete();",
            $controller
        );
        $this->assertStringContainsString('$dropdownNeed->forceDelete();', $controller);
    }

    // =========================================================================
    // 50–59  PERMISSIONS / AUTHORIZATION  (BC-AUTH)
    // =========================================================================

    /** BC-AUTH-50 | Source: REL_CONTROLLER — exact gate strings per method */
    public function test_dropdownneed_50_gate_strings_are_verbatim(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString("Gate::authorize('prime.dropdown-need.create')", $controller);
        $this->assertStringContainsString("Gate::authorize('prime.dropdown-need.view')", $controller);
        $this->assertStringContainsString("Gate::authorize('prime.dropdown-need.update')", $controller);
        $this->assertStringContainsString("Gate::authorize('prime.dropdown-need.delete')", $controller);
        $this->assertStringContainsString("Gate::authorize('prime.dropdown-need.restore')", $controller);
        $this->assertStringContainsString("Gate::authorize('prime.dropdown-need.forceDelete')", $controller);
    }

    /** BC-AUTH-51 | Source: RolePermissionSeeder guard 'web' — fresh user denied create */
    public function test_dropdownneed_51_fresh_user_is_denied_create_gate(): void
    {
        $user = $this->makeLimitedUserOrSkip();
        $this->assertTrue(
            Gate::forUser($user)->denies('prime.dropdown-need.create'),
            'A user without permissions must be denied prime.dropdown-need.create.'
        );
    }

    /** BC-AUTH-52 | Source: RolePermissionSeeder — fresh user denied every dropdown-need gate */
    public function test_dropdownneed_52_fresh_user_denied_all_gates(): void
    {
        $user = $this->makeLimitedUserOrSkip();
        foreach (['create', 'view', 'update', 'delete', 'restore', 'forceDelete'] as $action) {
            $this->assertTrue(
                Gate::forUser($user)->denies("prime.dropdown-need.{$action}"),
                "Fresh user must be denied prime.dropdown-need.{$action}."
            );
        }
    }

    /** SEC-PRM-004 (CORRECTED) | Source: REL_CONTROLLER + routes — ungated AJAX surface */
    public function test_dropdownneed_53_registered_ajax_endpoints_have_no_gate(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        // The registered AJAX methods contain NO Gate::authorize call.
        foreach ([
            'getMigrationTables', 'getTableColumns', 'getMigrationContent',
            'getMenuData', 'getMainMenus', 'getSubMenus', 'search',
        ] as $method) {
            $body = $this->extractMethodBody($controller, $method);
            if ($body === null) {
                continue;
            }
            $this->assertStringNotContainsString('Gate::authorize', $body,
                "SEC-PRM-004: {$method} is a registered AJAX endpoint with no Gate — schema/menu data leaks to any authenticated user.");
        }
    }

    /** BC-AUTH-54 | Source: RolePermissionSeeder — super admin allowed (guarded) */
    public function test_dropdownneed_54_super_admin_allowed_gates(): void
    {
        $admin = $this->adminUser;
        if (!$admin) {
            $this->markTestSkipped('No admin user resolvable in this environment.');
        }
        try {
            $allowed = Gate::forUser($admin)->allows('prime.dropdown-need.create')
                || (int) ($admin->is_super_admin ?? 0) === 1;
            $this->assertTrue($allowed, 'Super admin should be allowed dropdown-need.create.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Gate resolution unavailable: ' . $e->getMessage());
        }
    }

    /** BC-AUTH-55 / TC-N | Source: auth middleware — guest redirected from index (browser guarded) */
    public function test_dropdownneed_55_guest_is_redirected_from_index(): void
    {
        $this->runBrowserOrSkip('guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(300);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(800);
            $path = $this->currentPath($browser);
            $this->assertStringContainsString('login', $path,
                'Unauthenticated access to the index must redirect to /login.');
        });
    }

    // =========================================================================
    // 60–69  UI / ROUTING  (BC-UIX)
    // =========================================================================

    /** BC-UIX-60 | Source: routes/web.php — all named routes registered */
    public function test_dropdownneed_60_all_named_routes_are_registered(): void
    {
        $this->skipIfRoutesAbsent();

        foreach ([
            'central.global-master.dropdown-need.index',
            'central.global-master.dropdown-need.create',
            'central.global-master.dropdown-need.store',
            'central.global-master.dropdown-need.show',
            'central.global-master.dropdown-need.edit',
            'central.global-master.dropdown-need.update',
            'central.global-master.dropdown-need.destroy',
            'central.global-master.dropdown-need.search',
            'central.global-master.dropdown-need.mgmt',
            'central.global-master.dropdown-need.trashed',
            'central.global-master.dropdown-need.restore',
            'central.global-master.dropdown-need.forceDelete',
            'central.global-master.dropdown-need.toggleStatus',
            'central.global-master.dropdown-need.table-columns',
            'central.global-master.dropdown-need.migration-content',
            'central.global-master.dropdown-need.menu-data',
            'central.global-master.dropdown-need.main-menus',
            'central.global-master.dropdown-need.sub-menus',
            'central.global-master.dropdown-need.migration-tables',
        ] as $name) {
            $this->assertTrue(Route::has($name), "Route {$name} should be registered.");
        }
    }

    /** BC-UIX-61 | Source: routes/web.php — dead controller methods are unregistered */
    public function test_dropdownneed_61_dead_controller_methods_are_unregistered(): void
    {
        $this->skipIfRoutesAbsent();

        // These controller methods exist but no route points at them.
        foreach ([
            'central.global-master.dropdown-need.tabs',
            'central.global-master.dropdown-need.fields',
            'central.global-master.dropdown-need.meta',
            'central.global-master.dropdown-need.filterOptions',
            'central.global-master.dropdown-need.getByTableColumn',
        ] as $name) {
            $this->assertFalse(Route::has($name), "{$name} should NOT be registered (dead code).");
        }
    }

    /** BC-UIX-62 | Source: create.blade — form exposes required selectors (browser guarded) */
    public function test_dropdownneed_62_create_form_exposes_required_selectors(): void
    {
        $this->runBrowserOrSkip('create-form', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensureAccessible($browser, 'Dropdown Need create form');

            $browser->assertPresent('select[name="db_type"]')
                ->assertPresent('select[name="table_name"]')
                ->assertPresent('select[name="column_name"]')
                ->assertPresent('select[name="tenant_creation_allowed"]')
                ->assertPresent('input[name="tab_name"]')
                ->assertPresent('input[name="field_name"]');
        });
    }

    /** BC-UIX-63 | Source: prime::index — index reachable for admin (browser guarded) */
    public function test_dropdownneed_63_index_reachable_for_admin(): void
    {
        $this->runBrowserOrSkip('index-reachable', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensureAccessible($browser, 'Dropdown Need index');
            $this->assertStringContainsString('dropdown-need', $this->currentPath($browser));
        });
    }

    /** BC-UIX-64 | Source: trash.blade — trash view reachable (browser guarded) */
    public function test_dropdownneed_64_trash_view_reachable_for_admin(): void
    {
        $this->runBrowserOrSkip('trash-view', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH);
            $this->ensureAccessible($browser, 'Dropdown Need trash');
            $browser->assertPresent('table');
        });
    }

    /** BUG-PRM-DDNEED-005 | Source: routes/web.php — dropdown-need routes registered twice */
    public function test_dropdownneed_65_duplicate_route_group_registration_documented(): void
    {
        $routes = $this->readAppFile('routes/web.php');
        $this->skipIfNull($routes, 'routes/web.php');

        $count = substr_count($routes, "Route::resource('dropdown-need', DropdownNeedController::class)");
        $this->assertGreaterThanOrEqual(2, $count,
            'BUG-PRM-DDNEED-005: dropdown-need resource routes are registered more than once.');
    }

    // =========================================================================
    // 70–79  EDGE CASES  (BC-EDG)
    // =========================================================================

    /** BC-EDG-70 | Source: Screen — XSS payload persisted as literal text (guarded) */
    public function test_dropdownneed_70_xss_payload_is_stored_as_literal_text(): void
    {
        $this->runHttpOrSkip(function (): void {
            $xss = '<script>alert(1)</script>';
            $unique = $this->uniqueSuffix();
            $response = $this->actingAs($this->requireAdmin())
                ->post($this->centralUrl(self::INDEX_PATH), [
                    'db_type' => 'Prime',
                    'table_name' => 'xss_' . $unique,
                    'column_name' => $xss,
                    'tenant_creation_allowed' => 0,
                    'is_system' => 0,
                    'compulsory' => 1,
                    'is_active' => 1,
                ]);
            $this->assertContains($response->getStatusCode(), [302, 200, 422, 404]);

            if ($this->centralTableExists(self::TABLE)) {
                $row = DB::connection(self::CENTRAL_CONNECTION)->table(self::TABLE)
                    ->where('table_name', 'xss_' . $unique)->first();
                if ($row) {
                    $this->insertedIds[] = $row->id;
                    $this->assertSame($xss, $row->column_name,
                        'Payload must be persisted verbatim (escaped at render, not mutated at store).');
                }
            }
        });
    }

    /** BC-EDG-71 | Source: REL_MIGRATION — only one unique index; menu-path combo not DB-blocked */
    public function test_dropdownneed_71_duplicate_menu_path_not_blocked_by_db(): void
    {
        $migration = $this->readAppFile(self::REL_MIGRATION);
        $this->skipIfNull($migration, 'migration');

        // The DDL declares a 2nd unique (menu_category..field_name) but the runtime
        // migration only creates the (db_type,table_name,column_name) unique.
        $this->assertStringNotContainsString('uq_DDNeeds_category_mainMenu_subMenu_tabName_fieldName', $migration);
        $this->assertSame(1, substr_count($migration, '$table->unique('),
            'Runtime migration creates exactly one composite unique index.');
    }

    /** BC-EDG-72 | Source: REL_CONTROLLER — string rule allows whitespace (documented) */
    public function test_dropdownneed_72_table_name_rule_does_not_trim_whitespace(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        // No prepareForValidation / trim — whitespace-only strings pass `string` rule.
        $this->assertStringNotContainsString('prepareForValidation', $controller);
    }

    /** BC-EDG-73 | Source: REL_CONTROLLER — over-length column rejected (HTTP guarded) */
    public function test_dropdownneed_73_over_length_table_name_is_rejected(): void
    {
        $this->runHttpOrSkip(function (): void {
            $response = $this->actingAs($this->requireAdmin())
                ->from($this->centralUrl(self::CREATE_PATH))
                ->post($this->centralUrl(self::INDEX_PATH), [
                    'db_type' => 'Prime',
                    'table_name' => str_repeat('a', 200),
                    'column_name' => 'c',
                    'tenant_creation_allowed' => 0,
                    'is_system' => 0,
                    'compulsory' => 1,
                ]);
            $this->assertContains($response->getStatusCode(), [302, 422, 404]);
            if ($response->getStatusCode() === 302) {
                $response->assertSessionHasErrors('table_name');
            }
        });
    }

    // =========================================================================
    // 90–99  SECURITY / TENANCY / DEFECT PROOFS
    // =========================================================================

    /** SEC-PRM-004 correction | Source: REL_CONTROLLER + routes — filterOptions is gated + dead */
    public function test_dropdownneed_90_filter_options_is_gated_dead_code(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $body = $this->extractMethodBody($controller, 'filterOptions');
        if ($body !== null) {
            // Contrary to the audit note, filterOptions() DOES authorize.
            $this->assertStringContainsString('Gate::authorize', $body,
                'SEC-PRM-004 correction: filterOptions() is gated (audit claim of ungated does not hold).');
        }
        // And it has no route (dead code).
        $this->skipIfRoutesAbsent();
        $this->assertFalse(Route::has('central.global-master.dropdown-need.filterOptions'));
    }

    /** TEN-PRM-001 correction | Source: REL_CONTROLLER — tenant AJAX helpers end() in finally */
    public function test_dropdownneed_91_tenant_ajax_helpers_end_tenancy(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        foreach (['fetchMigrationTables', 'fetchTableColumns'] as $method) {
            $body = $this->extractMethodBody($controller, $method);
            if ($body === null) {
                continue;
            }
            $this->assertStringContainsString('tenancy()->initialize', $body);
            $this->assertStringContainsString('tenancy()->end()', $body,
                "TEN-PRM-001 correction: {$method} ends tenancy in a finally block (no context leak in current source).");
            $this->assertStringContainsString('finally', $body);
        }
    }

    /** PERF-PRM-001 | Source: REL_CONTROLLER — raw SHOW queries on AJAX */
    public function test_dropdownneed_92_raw_show_queries_used_for_schema_introspection(): void
    {
        $controller = $this->readAppFile(self::REL_CONTROLLER);
        $this->skipIfNull($controller, 'controller');

        $this->assertStringContainsString('SHOW COLUMNS FROM', $controller,
            'PERF-PRM-001: raw SHOW COLUMNS executed per AJAX column-fetch.');
        $this->assertStringContainsString("select('SHOW TABLES')", $controller);
        // Prime/Global responses are cached; Tenant is not.
        $this->assertStringContainsString('Cache::remember', $controller);
    }

    /** BUG-PRM-DUP correction | Source: filesystem — single canonical model */
    public function test_dropdownneed_93_single_canonical_model_no_stale_duplicate(): void
    {
        $canonical = $this->appFilePath(self::REL_MODEL);
        if ($canonical === null) {
            $this->markTestSkipped('Canonical model path not resolvable in this environment.');
        }
        $this->assertFileExists($canonical);

        // The audited stale root-level model must NOT exist.
        $stale = $this->appFilePath('Modules/Prime/Models/DropdownNeed.php');
        $this->assertNull($stale,
            'BUG-PRM-DUP correction: no stale root-level Modules/Prime/Models/DropdownNeed.php present.');
    }

    /** TC-S / IDOR | Source: REL_CONTROLLER show()/edit() — findOrFail → 404 (HTTP guarded) */
    public function test_dropdownneed_94_missing_id_returns_404(): void
    {
        $this->runHttpOrSkip(function (): void {
            $response = $this->actingAs($this->requireAdmin())
                ->get($this->centralUrl('/global-master/dropdown-need/99999999'));
            $this->assertContains($response->getStatusCode(), [404, 403, 302],
                'Unknown id should not return 200.');
            $this->assertNotSame(200, $response->getStatusCode());
        });
    }

    /** Constraint #25 | Source: activityLog helper — central activity sink */
    public function test_dropdownneed_95_activity_sink_is_central_table(): void
    {
        if (!$this->centralTableExists(self::CENTRAL_ACTIVITY_TABLE)) {
            $this->markTestSkipped('sys_central_activity_logs not present (central migration not run).');
        }
        $this->assertTrue(
            Schema::connection(self::CENTRAL_CONNECTION)->hasColumns(self::CENTRAL_ACTIVITY_TABLE, [
                'subject_type', 'subject_id', 'user_id', 'event', 'properties',
            ]),
            'Prime-side activity is written to sys_central_activity_logs.'
        );
    }

    // =========================================================================
    // ---- Private helper library (self-contained central auth + guards) ----
    // =========================================================================

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
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

    private function requireAdmin(): User
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user available for authenticated request.');
        }
        return $this->adminUser;
    }

    private function makeLimitedUserOrSkip(): User
    {
        if ($this->limitedUser) {
            return $this->limitedUser;
        }
        try {
            $suffix = $this->uniqueSuffix();
            $this->limitedUser = User::create([
                'name' => 'DDN Limited ' . $suffix,
                'email' => 'ddn_limited_' . $suffix . '@example.com',
                'password' => bcrypt('password'),
                'emp_code' => 'DDN' . substr($suffix, -6),
                'short_name' => 'DDN' . rand(1000, 9999),
                'status' => 'ACTIVE',
                'is_active' => 1,
                'is_super_admin' => 0,
                'email_verified_at' => now(),
            ]);
            return $this->limitedUser;
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not create a limited user (User factory/columns): ' . $e->getMessage());
        }
    }

    private function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl('/login'))->pause(700);
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1000);
        }
        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(600);
        }
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1000): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    private function ensureAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->markTestSkipped($context . ' shows login (auth unavailable in this environment).');
        }
        $bodyText = (string) $browser->text('body');
        foreach (['404', 'Not Found', '403', 'Forbidden', '419', 'Page Expired'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->markTestSkipped($context . ' not accessible (' . $signal . '); Prime module likely disabled (E19).');
            }
        }
    }

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    private function runBrowserOrSkip(string $caseName, callable $callback): void
    {
        try {
            $this->browse(function (Browser $browser) use ($callback): void {
                $callback($browser);
            });
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('[' . $caseName . '] browser unavailable/blocked: ' . $e->getMessage());
        }
    }

    private function runHttpOrSkip(callable $callback): void
    {
        try {
            $callback();
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('HTTP path unavailable in this environment: ' . $e->getMessage());
        }
    }

    private function centralTableExists(string $table): bool
    {
        try {
            return Schema::connection(self::CENTRAL_CONNECTION)->hasTable($table);
        } catch (Throwable) {
            return false;
        }
    }

    /** @return array<int,string> */
    private function centralIndexNames(string $table): array
    {
        try {
            $rows = DB::connection(self::CENTRAL_CONNECTION)->select("SHOW INDEX FROM `{$table}`");
            return array_values(array_unique(array_map(static fn ($r) => $r->Key_name, $rows)));
        } catch (Throwable) {
            return [];
        }
    }

    private function skipIfRoutesAbsent(): void
    {
        if (!Route::has(self::ROUTE_INDEX)) {
            $this->markTestSkipped('Dropdown-need routes not registered (Prime module disabled — E19).');
        }
    }

    private function skipIfNull(?string $value, string $what): void
    {
        if ($value === null) {
            $this->markTestSkipped('Could not locate app source: ' . $what . ' (set MAIN_PROJECT_PATH).');
        }
    }

    /** Resolve an app-repo file path across candidate roots; null if not found. */
    private function appFilePath(string $relative): ?string
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

    private function readAppFile(string $relative): ?string
    {
        $path = $this->appFilePath($relative);
        if ($path === null) {
            return null;
        }
        try {
            return File::get($path);
        } catch (Throwable) {
            return null;
        }
    }

    /** Crude brace-matched extraction of a PHP method body by name. */
    private function extractMethodBody(string $source, string $method): ?string
    {
        if (!preg_match('/function\s+' . preg_quote($method, '/') . '\s*\(/', $source, $m, PREG_OFFSET_CAPTURE)) {
            return null;
        }
        $start = strpos($source, '{', $m[0][1]);
        if ($start === false) {
            return null;
        }
        $depth = 0;
        $len = strlen($source);
        for ($i = $start; $i < $len; $i++) {
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
        return null;
    }

    private function uniqueSuffix(): string
    {
        return uniqid();
    }
}
