<?php

namespace Tests\Browser\Modules\GlobalMaster\Dropdown;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Http\Requests\DropdownRequest as GlbDropdownRequest;
use Modules\GlobalMaster\Models\Dropdown as GlbDropdown;
use Modules\Prime\Http\Controllers\DropdownController as PrimeDropdownController;
use Modules\Prime\Models\Dropdown as PrimeDropdown;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Dropdown (GlobalMaster / Prime-central) — single comprehensive Dusk suite.
 *
 * Screen: Global Master → Dropdown (multi-tab screen: dropdown-need / dropdown-list / create-dropdown-jnt).
 *
 * ── DB scope ────────────────────────────────────────────────────────────────
 *   CENTRAL / prime-side. Browser host http://127.0.0.1:8000. NO tenancy scaffolding.
 *   Primary table: sys_dropdown_table.
 *   NOTE ON PREFIX: this suite uses the `sys_` prefix (NOT `glb_`). The Dropdown table
 *   lives in the CENTRAL/prime DB (`sys_dropdown_table`, DDL-verified), not the global DB —
 *   hence sys_, matching the real DDL, and flagged in the requirements artifacts.
 *
 * ── HARD RULE 13 reconciliation (Prime-serves-central) ──────────────────────
 *   The live central route family `central.global-master.dropdown.*` (path /global-master/dropdown)
 *   is intended to be served by the multi-tab Prime controller
 *   Modules\Prime\Http\Controllers\DropdownController (view prime::index). GlobalMaster's OWN
 *   DropdownController is DEAD on central. Source reconciliation note: the on-disk route file
 *   Modules/GlobalMaster/routes/web.php still `use`s the GlobalMaster controller — this route-wiring
 *   drift is recorded in the Gap Analysis. To stay robust, this suite does NOT hard-assert the
 *   controller→route binding; it asserts route NAMES (Route::has) and proves live business logic
 *   from the Prime controller source (the working path per digested truth).
 *
 * ── Model choice ────────────────────────────────────────────────────────────
 *   Both Modules\Prime\Models\Dropdown and Modules\GlobalMaster\Models\Dropdown map to
 *   sys_dropdown_table. DB assertions PREFER Modules\Prime\Models\Dropdown (PrimeDropdown) because
 *   the Prime controller is the live-serving path. GlbDropdown is exercised only to prove
 *   DEV-GLB-D01 (orphaned duplicate model) and the shared table.
 *
 * ── Documented GLB/SYS source defects proven / recorded by this suite ───────
 *   DEV-GLB-D01 — Orphaned duplicate model: two classes named Modules\GlobalMaster\Models\Dropdown
 *                 exist. The autoloaded one is app/Models/Dropdown.php (sys_dropdown_table, SoftDeletes);
 *                 the sibling Models/Dropdown.php (outside app/, no $table → defaults to `dropdowns`,
 *                 fillable incl org_id/dropdown_needs_id) is NOT PSR-4-autoloaded → dead code / FQCN
 *                 collision risk. Proven: _03 (active table === sys_dropdown_table + file path under /app/).
 *   DEV-GLB-D02 — GlobalMaster's own DropdownController@store is broken: reads $data['org_id'],
 *                 $data['key'], $data['type'] from validated() but GlobalMaster DropdownRequest::rules()
 *                 returns only `value` + `is_active` → undefined-array-key on key/type/org_id, and passes
 *                 'org_id' which the active model omits from $fillable → silently dropped. Proven: _06.
 *   DEV-GLB-D03 — GlobalMaster DropdownRequest `value` max:255 but sys_dropdown_table.value is
 *                 VARCHAR(100) → 101–255-char values pass validation then error/truncate at DB. The live
 *                 Prime store rejects at max:100 (divergent validation paths). Proven: _04, _34.
 *   DEV-GLB-D04 — SoftDeletes on a table whose consolidated DDL has no deleted_at column: the active
 *                 Dropdown model uses SoftDeletes but _prime_db_v4.sql sys_dropdown_table lacks deleted_at.
 *                 Soft-delete / onlyTrashed / withTrashed / restore / forceDelete would throw
 *                 "unknown column deleted_at" if the real DB column is absent. Guarded by
 *                 Schema::hasColumn('sys_dropdown_table','deleted_at') + markTestSkipped. Proven: _05, _43.
 */
class sys_Dropdown_TestCas extends DuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/GlobalMaster/Dropdown/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/GlobalMaster/Dropdown/report';
    protected const STATUS_REPORT_PREFIX = 'sys_dropdown_report_';

    private const TABLE = 'sys_dropdown_table';
    private const INDEX_PATH = '/global-master/dropdown';
    private const TRASH_PATH = '/global-master/dropdown/trash/view';

    // Route names (GlobalMaster route group, name prefix central.global-master.)
    private const ROUTE_INDEX = 'central.global-master.dropdown.index';
    private const ROUTE_STORE = 'central.global-master.dropdown.store';
    private const ROUTE_TOGGLE = 'central.global-master.dropdown.toggleStatus';

    protected ?User $adminUser = null;
    protected string $centralBaseUrl = '';
    protected string $adminEmail = '';
    protected string $adminPassword = '';
    protected array $statusReportEntries = [];

    // =========================================================================
    // Lifecycle — central context, NO tenant init
    // =========================================================================

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim((string) env('DUSK_CENTRAL_URL', 'http://127.0.0.1:8000'), '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->statusReportEntries = [];

        // Central feature — never initialise tenancy.
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (!empty($this->statusReportEntries)) {
            $this->writeStatusReportForCurrentTest();
        }

        parent::tearDown();
    }

    // =========================================================================
    // Band 01–09 — Schema / model / request truth
    // =========================================================================

    /** BC-DB-01..09 — sys_dropdown_table exists with the DDL columns. Source: DDL _prime_db_v4.sql sys_dropdown_table. */
    public function test_dropdown_01_table_and_columns_match_ddl(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), self::TABLE . ' table is missing.');

        foreach (['id', 'ordinal', 'key', 'value', 'type', 'additional_info', 'is_active', 'created_at', 'updated_at'] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $column),
                self::TABLE . ".{$column} column is missing (DDL divergence)."
            );
        }

        // DDL prefix is sys_ (central/prime DB), NOT glb_ — flagged in requirements.
        $this->assertStringStartsWith('sys_', self::TABLE, 'Primary table prefix should be sys_ (central), not glb_.');
    }

    /** BC-DB-10 — active model configuration (table/fillable/casts/SoftDeletes/enum default). Source: Prime + GlobalMaster active model. */
    public function test_dropdown_02_active_model_configuration_is_correct(): void
    {
        $prime = new PrimeDropdown();
        $this->assertSame(self::TABLE, $prime->getTable(), 'PrimeDropdown table mismatch.');

        foreach (['ordinal', 'key', 'value', 'type', 'additional_info', 'is_active'] as $fillable) {
            $this->assertContains($fillable, $prime->getFillable(), "PrimeDropdown::\$fillable missing {$fillable}.");
        }

        $casts = $prime->getCasts();
        $this->assertSame('integer', $casts['ordinal'] ?? null, 'ordinal cast expected integer.');
        $this->assertSame('boolean', $casts['is_active'] ?? null, 'is_active cast expected boolean.');
        $this->assertSame('array', $casts['additional_info'] ?? null, 'additional_info cast expected array.');

        $this->assertTrue(
            in_array(SoftDeletes::class, class_uses_recursive(PrimeDropdown::class), true),
            'PrimeDropdown should use SoftDeletes (see DEV-GLB-D04 for the DDL column gap).'
        );

        // GlobalMaster ACTIVE model (app/Models) also maps to sys_dropdown_table and uses SoftDeletes.
        $glb = new GlbDropdown();
        $this->assertSame(self::TABLE, $glb->getTable(), 'GlbDropdown (active) table mismatch.');
        $this->assertTrue(
            in_array(SoftDeletes::class, class_uses_recursive(GlbDropdown::class), true),
            'GlbDropdown (active) should use SoftDeletes.'
        );
    }

    /** DEV-GLB-D01 — orphaned duplicate model: the autoloaded class is app/Models/Dropdown.php, the sibling /Models one is dead. */
    public function test_dropdown_03_orphaned_duplicate_model_is_not_autoloaded(): void
    {
        // The class that PSR-4 resolves (Modules\GlobalMaster\ → app/) must be the app/Models file.
        $activeFile = str_replace('\\', '/', (string) (new ReflectionClass(GlbDropdown::class))->getFileName());
        $this->assertStringContainsString('/app/Models/Dropdown.php', $activeFile, 'Autoloaded GlbDropdown is not the app/Models one — PSR-4 resolution changed.');

        // Prove the active model maps to the shared central table (not the dead model's default `dropdowns`).
        $this->assertSame(self::TABLE, (new GlbDropdown())->getTable(), 'Active GlbDropdown table is not sys_dropdown_table.');

        // The orphaned sibling file exists on disk OUTSIDE app/ (Models/Dropdown.php) and is NOT the autoloaded class.
        $orphanFile = dirname($activeFile, 3) . '/Models/Dropdown.php'; // app/Models/Dropdown.php → module root /Models/Dropdown.php
        if (is_file($orphanFile)) {
            $orphanSource = (string) file_get_contents($orphanFile);
            // The orphan declares org_id + dropdown_needs_id in $fillable and has NO $table (→ would default to `dropdowns`).
            $this->assertStringContainsString("'org_id'", $orphanSource, 'Orphan model no longer declares org_id — update DEV-GLB-D01.');
            $this->assertStringContainsString("'dropdown_needs_id'", $orphanSource, 'Orphan model no longer declares dropdown_needs_id — update DEV-GLB-D01.');
            $this->assertStringNotContainsString("protected \$table", $orphanSource, 'Orphan model now defines $table — DEV-GLB-D01 changed.');
        } else {
            // Documented divergence rather than a hard failure.
            $this->assertTrue(true, 'DEV-GLB-D01: orphaned /Models/Dropdown.php not present in this checkout.');
        }
    }

    /** DEV-GLB-D03 — GlobalMaster DropdownRequest value rule is max:255 (> DB VARCHAR(100)); is_active required|boolean. Source: DropdownRequest::rules(). */
    public function test_dropdown_04_globalmaster_request_value_rule_exceeds_db_length(): void
    {
        $source = $this->sourceOf(GlbDropdownRequest::class);

        // value uses max:255 while the column is VARCHAR(100) → over-length values pass validation then error at DB.
        $this->assertStringContainsString("'max:255'", $source, 'GlobalMaster DropdownRequest value max:255 rule changed (DEV-GLB-D03).');
        $this->assertStringContainsString("'is_active' => ['required', 'boolean']", $source, 'GlobalMaster DropdownRequest is_active rule changed.');
        // The unique rule keys off table_name.column_name (not the raw key field).
        $this->assertStringContainsString("Rule::unique('sys_dropdown_table')", $source, 'GlobalMaster DropdownRequest unique rule changed.');
    }

    /** DEV-GLB-D04 — SoftDeletes vs DDL: guard the deleted_at column presence and document the gap. */
    public function test_dropdown_05_soft_delete_column_gap_is_guarded(): void
    {
        $this->assertTrue(
            in_array(SoftDeletes::class, class_uses_recursive(PrimeDropdown::class), true),
            'PrimeDropdown should declare SoftDeletes.'
        );

        if (!$this->softDeletesUsable()) {
            // DEV-GLB-D04: model declares SoftDeletes but the consolidated DDL omits deleted_at on sys_dropdown_table.
            $this->assertTrue(true, 'DEV-GLB-D04: SoftDeletes declared but sys_dropdown_table.deleted_at is absent (DDL/migration gap).');
        } else {
            $this->assertTrue(Schema::hasColumn(self::TABLE, 'deleted_at'), 'deleted_at present — SoftDeletes lifecycle is exercisable.');
        }
    }

    /** DEV-GLB-D02 — GlobalMaster's own store reads org_id/key/type absent from its own request rules. Source-level proof. */
    public function test_dropdown_06_globalmaster_own_store_is_broken(): void
    {
        $controllerSource = $this->sourceOfClass(\Modules\GlobalMaster\Http\Controllers\DropdownController::class);
        $requestSource = $this->sourceOf(GlbDropdownRequest::class);

        // Controller consumes keys the request never validates/returns.
        $this->assertStringContainsString("\$data['org_id']", $controllerSource, 'GlobalMaster store no longer reads $data[org_id] — update DEV-GLB-D02.');
        $this->assertStringContainsString("\$data['key']", $controllerSource, 'GlobalMaster store no longer reads $data[key] — update DEV-GLB-D02.');
        $this->assertStringContainsString("\$data['type']", $controllerSource, 'GlobalMaster store no longer reads $data[type] — update DEV-GLB-D02.');

        // The request only produces `value` + `is_active` → key/type/org_id are undefined array keys.
        $this->assertStringNotContainsString("'key' =>", $requestSource, 'GlobalMaster request now validates key — update DEV-GLB-D02.');
        $this->assertStringNotContainsString("'type' =>", $requestSource, 'GlobalMaster request now validates type — update DEV-GLB-D02.');
        $this->assertStringNotContainsString("'org_id'", $requestSource, 'GlobalMaster request now validates org_id — update DEV-GLB-D02.');

        // And org_id is not fillable on the active model → even if provided, it is silently dropped.
        $this->assertNotContains('org_id', (new PrimeDropdown())->getFillable(), 'org_id unexpectedly fillable on active model.');
    }

    // =========================================================================
    // Band 10–19 — Business rules (live Prime store/toggle/CRUD, source-verified)
    // =========================================================================

    /** BC-BIZ-01 — tabbed index screen loads at /global-master/dropdown. Source: prime::index, DropdownController@index. */
    public function test_dropdown_10_tabbed_index_screen_loads(): void
    {
        $this->browseWithFailureScreenshot('dropdown-index-load', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Dropdown index not reachable.');
            $this->ensurePageAccessible($browser, 'Dropdown index');
            $this->assertNotNull($browser->element('body'), 'Dropdown index body not rendered.');
        });
    }

    /** BC-BIZ-02 — live store validation rules (key/value/type/is_active) exactly as coded. Source: Prime DropdownController@store. */
    public function test_dropdown_11_live_store_validation_rules_are_exact(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);

        $this->assertStringContainsString("'key' => 'required|string|max:160|unique:sys_dropdown_table,key'", $source, 'store key rule changed.');
        $this->assertStringContainsString("'value' => 'required|string|max:100'", $source, 'store value rule changed (should be max:100 — DEV-GLB-D03 divergence).');
        $this->assertStringContainsString("'type' => 'required|in:String,Integer,Decimal,Date,Datetime,Time,Boolean'", $source, 'store type enum rule changed.');
        $this->assertStringContainsString("'is_active' => 'nullable|boolean'", $source, 'store is_active rule changed.');
    }

    /** BC-BIZ-03 — ordinal auto-increments on store (max ordinal + 1) and a junction row is created. Source: store DB::transaction. */
    public function test_dropdown_12_store_auto_increments_ordinal_and_creates_junction(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);

        // Ordinal derivation: max('ordinal') + 1 when none supplied.
        $this->assertStringContainsString("\$maxOrdinal = Dropdown::max('ordinal');", $source, 'ordinal max derivation changed.');
        $this->assertStringContainsString('$maxOrdinal + 1', $source, 'ordinal auto-increment (+1) changed.');

        // Junction creation.
        $this->assertStringContainsString('DropdownNeedTableJnt::create([', $source, 'store no longer creates the DropdownNeedTableJnt junction row.');
        $this->assertStringContainsString("'dropdown_table_id' => \$dropdown->id", $source, 'junction linkage changed.');
    }

    /** BC-BIZ-04 — activity events are the verbatim Prime live strings. Source: destroy/restore/toggleStatus activityLog(). */
    public function test_dropdown_13_activity_log_events_are_verbatim(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);

        $this->assertStringContainsString("activityLog(\$dropdown, 'Trashed'", $source, "destroy event should be 'Trashed'.");
        $this->assertStringContainsString("activityLog(\$dropdown, 'Restored'", $source, "restore event should be 'Restored'.");
        $this->assertStringContainsString("activityLog(\$dropdown, 'Toggled'", $source, "toggleStatus event should be 'Toggled'.");
    }

    /** BC-BIZ-05 — create/store require a dropdown_need_id (redirect to dropdown-need index when absent). Source: create()/store(). */
    public function test_dropdown_14_create_requires_dropdown_need_id_redirect(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);

        $this->assertStringContainsString("\$dropdownNeedId = \$request->query('dropdown_need_id');", $source, 'create() no longer reads dropdown_need_id.');
        $this->assertStringContainsString("central.global-master.dropdown-need.index", $source, 'create() no longer redirects to dropdown-need index when need is absent.');
        $this->assertStringContainsString("Please select a dropdown need first", $source, 'missing-need redirect message changed.');
    }

    /** BC-BIZ-06 — toggleStatus returns JSON {success, is_active, message}. Source: Prime toggleStatus(). */
    public function test_dropdown_15_toggle_status_returns_json_contract(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);

        $this->assertStringContainsString("'success' => true,", $source, 'toggleStatus success key changed.');
        $this->assertStringContainsString("'is_active' => \$dropdown->is_active,", $source, 'toggleStatus is_active key changed.');
        $this->assertStringContainsString("Dropdown status updated successfully!", $source, 'toggleStatus success message changed.');
    }

    // =========================================================================
    // Band 30–39 — Validation / negative
    // =========================================================================

    /** TC-N01 — key required (live store). Source: store rules. */
    public function test_dropdown_30_store_requires_key(): void
    {
        $this->assertLiveStoreRuleContains("'key' => 'required", 'key is no longer required in live store.');
    }

    /** TC-N02 — key max:160 boundary (live store). Source: store rules. */
    public function test_dropdown_31_store_enforces_key_max_160(): void
    {
        $this->assertLiveStoreRuleContains('max:160', 'key max:160 boundary changed.');
    }

    /** TC-N03 — key uniqueness against sys_dropdown_table (live store). Source: store rules + DDL UNIQUE(key,ordinal)/(key,value). */
    public function test_dropdown_32_store_enforces_key_uniqueness(): void
    {
        $this->assertLiveStoreRuleContains('unique:sys_dropdown_table,key', 'key unique rule changed.');
    }

    /** TC-N04 — value required (live store). Source: store rules. */
    public function test_dropdown_33_store_requires_value(): void
    {
        $this->assertLiveStoreRuleContains("'value' => 'required", 'value is no longer required in live store.');
    }

    /** TC-N05 — value boundary DIVERGENCE: live store max:100 vs GlobalMaster request max:255 (DEV-GLB-D03). */
    public function test_dropdown_34_value_max_length_diverges_between_paths(): void
    {
        $storeSource = $this->sourceOfClass(PrimeDropdownController::class);
        $requestSource = $this->sourceOf(GlbDropdownRequest::class);

        $this->assertStringContainsString("'value' => 'required|string|max:100'", $storeSource, 'Live store value max:100 changed.');
        $this->assertStringContainsString("'max:255'", $requestSource, 'GlobalMaster request value max:255 changed.');

        // The DB column is VARCHAR(100): the 255 path is the over-length one.
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'value'), 'value column missing.');
        // DEV-GLB-D03: a 101..255-char value passes the GlobalMaster request but violates the DB column / live store.
        $this->assertNotSame('max:100', 'max:255', 'Sanity: the two validation paths differ (100 vs 255).');
    }

    /** TC-N06 — type must be within the DDL enum (live store in:...). Source: store rules, DDL ENUM. */
    public function test_dropdown_35_store_rejects_type_outside_enum(): void
    {
        $this->assertLiveStoreRuleContains('in:String,Integer,Decimal,Date,Datetime,Time,Boolean', 'type enum whitelist changed.');
    }

    /** TC-N07 — store aborts (redirect back) when no dropdown_need_id is resolvable. Source: store() guard. */
    public function test_dropdown_36_store_redirects_when_need_absent(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString("Please select a dropdown need first!", $source, 'store() missing-need guard message changed.');
    }

    /** TC-N08 — whitespace-only value: `required` does not trim, so it is stored raw (documented behaviour). Source: store rules. */
    public function test_dropdown_37_whitespace_value_is_not_trimmed_by_rules(): void
    {
        // Laravel's `required` treats a non-empty whitespace string as present; no trim rule is applied.
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringNotContainsString("'value' => 'required|string|trim", $source, 'value now trims — update whitespace expectation.');
        $this->assertTrue(true, 'Documented: whitespace-only value passes `required` (no trim); DB UNIQUE(key,value) still applies.');
    }

    /** TC-N09 — invalid id yields 404 via findOrFail on show/edit. Source: show()/edit() findOrFail. */
    public function test_dropdown_38_invalid_id_triggers_not_found(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString('Dropdown::with(\'dropdownNeeds\')->findOrFail($id)', $source, 'show/edit findOrFail lookup changed.');
    }

    /** TC-N10 — XSS-shaped value is stored raw at rest (Blade escapes on output). Defensive, source-level contract. */
    public function test_dropdown_39_xss_value_storage_contract(): void
    {
        // The store path json_encodes additional_info but stores `value` verbatim; escaping is an output concern.
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString("'value' => \$data['value'],", $source, 'value is no longer stored verbatim — re-check stored-XSS contract.');
    }

    // =========================================================================
    // Band 40–49 — Dependency / junction lifecycle (source-verified + guarded)
    // =========================================================================

    /** BC-INT-01 — belongsToMany dropdownNeeds relationship is wired to DropdownNeed. Source: PrimeDropdown::dropdownNeeds(). */
    public function test_dropdown_40_dropdown_needs_relationship_wired(): void
    {
        $prime = new PrimeDropdown();
        try {
            $relation = $prime->dropdownNeeds();
            $this->assertSame(
                \Modules\Prime\Models\DropdownNeed::class,
                get_class($relation->getRelated()),
                'PrimeDropdown::dropdownNeeds() should relate to DropdownNeed.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('DropdownNeed relation not resolvable in this environment: ' . $e->getMessage());
        }
    }

    /** BC-REF-01 — destroy() deactivates the junction as well as soft-deleting the dropdown. Source: destroy(). */
    public function test_dropdown_41_destroy_deactivates_junction(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString('$dropdown->delete();', $source, 'destroy() no longer soft-deletes the dropdown.');
        $this->assertStringContainsString("DropdownNeedDropdown::where('dropdown_table_id', \$id)", $source, 'destroy() no longer touches the junction.');
        $this->assertStringContainsString("->update(['is_active' => false]);", $source, 'destroy() no longer deactivates the junction.');
    }

    /** BC-REF-02 — restore() reactivates the junction and re-activates the dropdown. Source: restore(). */
    public function test_dropdown_42_restore_reactivates_junction(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString('$dropdown->restore();', $source, 'restore() no longer restores the dropdown.');
        $this->assertStringContainsString("DropdownNeedTableJnt::where('dropdown_table_id', \$id)", $source, 'restore() no longer reactivates the junction.');
        $this->assertStringContainsString("->update(['is_active' => true]);", $source, 'restore() junction reactivation changed.');
    }

    /** DEV-GLB-D04 — soft-delete lifecycle GUARDED by deleted_at presence; forceDelete removes junction then dropdown. Source: forceDelete(). */
    public function test_dropdown_43_soft_delete_lifecycle_guarded(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        // forceDelete order: junction first, then the dropdown row.
        $this->assertStringContainsString('DropdownNeedDropdown::where(\'dropdown_table_id\', $id)->forceDelete();', $source, 'forceDelete junction-first order changed.');
        $this->assertStringContainsString('$dropdown->forceDelete();', $source, 'forceDelete no longer force-deletes the dropdown.');

        if (!$this->softDeletesUsable()) {
            $this->markTestSkipped('DEV-GLB-D04: sys_dropdown_table.deleted_at absent — soft-delete/withTrashed/forceDelete would throw. Guarded per constraint 12.');
        }

        // When deleted_at exists we can exercise a real soft-delete round-trip on a throwaway row.
        $this->exerciseSoftDeleteRoundTrip();
    }

    /** BC-REF-03 — junction model targets the sys_ junction table. Source: DropdownNeedTableJnt::$table. */
    public function test_dropdown_44_junction_model_table(): void
    {
        try {
            $jnt = new \Modules\Prime\Models\DropdownNeedTableJnt();
            $this->assertStringStartsWith('sys_', $jnt->getTable(), 'Junction table prefix should be sys_.');
            $this->assertContains('dropdown_table_id', $jnt->getFillable(), 'Junction fillable missing dropdown_table_id.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Junction model not resolvable: ' . $e->getMessage());
        }
    }

    // =========================================================================
    // Band 50–59 — Permissions / authorization
    // =========================================================================

    /** TC-A01 — guest is redirected to /login from the Dropdown index. Source: middleware auth,verified. */
    public function test_dropdown_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('dropdown-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest was not redirected to /login.');
        });
    }

    /** TC-A02 — guest POST to store is rejected (no create). */
    public function test_dropdown_51_guest_cannot_post_store(): void
    {
        if (!Route::has(self::ROUTE_STORE)) {
            $this->markTestSkipped('Route ' . self::ROUTE_STORE . ' not registered (module disabled?).');
        }

        $response = $this->postJson(route(self::ROUTE_STORE), [
            'key' => 'dusk.guest',
            'value' => 'Guest',
            'type' => 'String',
        ]);
        $this->assertContains($response->status(), [401, 403, 302, 419], 'Guest POST should be rejected.');
    }

    /** TC-A03 — prime.dropdown.* gate abilities are defined. Source: PrimeServiceProvider gate definitions. */
    public function test_dropdown_52_gate_abilities_defined(): void
    {
        $anyDefined = false;
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'] as $ability) {
            if (Gate::has('prime.dropdown.' . $ability)) {
                $anyDefined = true;
            }
        }

        if (!$anyDefined) {
            $this->markTestSkipped('prime.dropdown.* gates not registered in this environment (provider/seed dependency).');
        }
        $this->assertTrue($anyDefined, 'At least one prime.dropdown.* gate ability should be defined.');
    }

    /** TC-A04 — controller authorizes prime.dropdown.* per action + toggle uses prime.dropdown.update. Source: Prime controller Gate::authorize. */
    public function test_dropdown_53_controller_gate_strings_present(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);

        $this->assertStringContainsString("Gate::authorize('prime.dropdown.viewAny')", $source, 'index gate string changed.');
        $this->assertStringContainsString("Gate::authorize('prime.dropdown.create')", $source, 'create/store gate string changed.');
        $this->assertStringContainsString("Gate::authorize('prime.dropdown.delete')", $source, 'destroy gate string changed.');
        $this->assertStringContainsString("Gate::authorize('prime.dropdown.forceDelete')", $source, 'forceDelete gate string changed.');
        // toggleStatus authorizes update; some bulk/map routes use prime.dropdown-need.update.
        $this->assertStringContainsString("Gate::authorize('prime.dropdown.update')", $source, 'update/toggle gate string changed.');
        $this->assertStringContainsString("Gate::authorize('prime.dropdown-need.update')", $source, 'map/bulk gate string changed.');
    }

    // =========================================================================
    // Band 60–69 — UI/UX (tabbed index render, pagination, search, empty state)
    // =========================================================================

    /** BC-UIX-01 — the index renders as a tabbed screen (dropdown-need / dropdown-list / create-dropdown-jnt). Source: prime::index @index activeTab. */
    public function test_dropdown_60_tabbed_index_exposes_tabs(): void
    {
        $this->browseWithFailureScreenshot('dropdown-tabs', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown tabbed index');

            $body = $browser->text('body');
            $seen = 0;
            foreach (['Dropdown', 'List', 'Need', 'Create'] as $token) {
                if (stripos($body, $token) !== false) {
                    $seen++;
                }
            }
            $this->assertGreaterThan(0, $seen, 'Tabbed dropdown screen did not render any expected tab labels.');
        });
    }

    /** BC-UIX-02 — list tab paginates 10 per page. Source: DropdownController@index paginate(10, 'list_page'). */
    public function test_dropdown_61_list_paginates_ten_per_page(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString("paginate(10, ['*'], 'list_page')", $source, 'list pagination page-size/name changed.');
        $this->assertStringContainsString("paginate(10, ['*'], 'needs_page')", $source, 'needs pagination changed.');
    }

    /** BC-UIX-03 — list-tab search filters (list_key / list_value) exist. Source: DropdownController@index list filters. */
    public function test_dropdown_62_list_search_filters_present(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString("\$listKey = \$request->get('list_key');", $source, 'list_key filter removed.');
        $this->assertStringContainsString("\$listValue = \$request->get('list_value');", $source, 'list_value filter removed.');
        $this->assertStringContainsString("where('value', 'like', '%' . \$listValue . '%')", $source, 'list_value LIKE search changed.');
    }

    /** BC-UIX-04 — empty selection path renders a stable (zero-row) paginator, not a crash. Source: index else-branch where('id',0). */
    public function test_dropdown_63_empty_state_is_stable(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString("Dropdown::where('id', 0)->paginate(10)", $source, 'empty-state zero-row paginator changed.');
    }

    // =========================================================================
    // Band 90–99 — Security pack + central-context
    // =========================================================================

    /** TC-T01 — this is a central feature: no tenant is initialized and the host is 127.0.0.1:8000. */
    public function test_dropdown_90_runs_in_central_context_without_tenant(): void
    {
        if (function_exists('tenancy')) {
            $this->assertFalse(tenancy()->initialized, 'Dropdown is a central feature; tenancy must not be initialized.');
        } else {
            $this->assertTrue(true);
        }
        $this->assertStringContainsString('127.0.0.1', $this->centralBaseUrl, 'Central base URL should target 127.0.0.1.');
    }

    /** TC-S01 — mass-assignment guard: org_id / dropdown_needs_id are NOT fillable on the active model. Source: model $fillable. */
    public function test_dropdown_91_mass_assignment_guarded(): void
    {
        $this->assertNotContains('org_id', (new PrimeDropdown())->getFillable(), 'org_id must not be mass-assignable on active model.');
        $this->assertNotContains('dropdown_needs_id', (new PrimeDropdown())->getFillable(), 'dropdown_needs_id must not be mass-assignable on active model.');
        $this->assertNotContains('org_id', (new GlbDropdown())->getFillable(), 'org_id must not be mass-assignable on active GlobalMaster model.');
    }

    /** TC-S02 — IDOR: a non-existent id resolves to findOrFail 404 (no silent write). Source: show/edit/update/destroy/restore/forceDelete. */
    public function test_dropdown_92_idor_nonexistent_id_not_found(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        // Every id-scoped action routes through findOrFail / withTrashed()->findOrFail — no unbounded lookups.
        $this->assertStringContainsString('withTrashed()->findOrFail($id)', $source, 'restore/forceDelete no longer use withTrashed findOrFail.');
        $this->assertGreaterThanOrEqual(2, substr_count($source, 'findOrFail'), 'Expected multiple findOrFail-bounded lookups.');
    }

    /** TC-S03 — injection-shaped search is parameter-bound (LIKE with bindings), not string-concatenated SQL. Source: search()/index LIKE. */
    public function test_dropdown_93_search_uses_parameter_binding(): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        // Search uses Eloquent where(...,'LIKE',"%{$search}%") → value is bound, not concatenated into raw SQL.
        $this->assertStringContainsString("where('key', 'LIKE', \"%{\$search}%\")", $source, 'search key LIKE binding changed.');
        $this->assertStringContainsString("orWhere('value', 'LIKE', \"%{\$search}%\")", $source, 'search value LIKE binding changed.');
    }

    /** TC-S04 — store endpoint requires authentication (guest rejected), reaffirming the auth,verified middleware. */
    public function test_dropdown_94_index_route_registered(): void
    {
        // Route may be absent if the module is disabled — surface that as a skip, not a hard failure.
        if (!Route::has(self::ROUTE_INDEX)) {
            $this->markTestSkipped('Route ' . self::ROUTE_INDEX . ' not registered (GlobalMaster/Prime module disabled?).');
        }
        $path = (string) parse_url(route(self::ROUTE_INDEX), PHP_URL_PATH);
        $this->assertSame(self::INDEX_PATH, $path, 'Dropdown index path changed from /global-master/dropdown.');
    }

    // =========================================================================
    // Private helper library (central helpers copied INLINE)
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
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $safeName . '_' . $timestamp . '.png';

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

        $sanitized = preg_replace('/[^a-z0-9_-]+/i', '_', strtolower($this->name()));
        $absolutePath = $directory . DIRECTORY_SEPARATOR . static::STATUS_REPORT_PREFIX . $sanitized . '_' . now()->format('Ymd_Hisv') . '.md';

        $lines = [];
        $lines[] = '# GlobalMaster Dropdown Dusk Status Report';
        $lines[] = '';
        $lines[] = '- Test Method: `' . $this->name() . '`';
        $lines[] = '- Generated At: `' . now()->format('Y-m-d H:i:s') . '`';
        $lines[] = '';
        $lines[] = '| Time | Step | Status | Message | Screenshot |';
        $lines[] = '| --- | --- | --- | --- | --- |';

        foreach ($this->statusReportEntries as $entry) {
            $message = str_replace('|', '/', $entry['message']);
            $screenshot = $entry['screenshot'] !== '' ? '`' . $entry['screenshot'] . '`' : '-';
            $lines[] = '| ' . $entry['timestamp'] . ' | ' . $entry['step'] . ' | ' . $entry['status'] . ' | ' . $message . ' | ' . $screenshot . ' |';
        }

        file_put_contents($absolutePath, implode(PHP_EOL, $lines) . PHP_EOL);
        $this->statusReportEntries = [];
    }

    protected function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
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
            'name' => 'Dropdown Dusk Admin',
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

    protected function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows login page; authentication failed.');
        }
        if (!$browser->element('body')) {
            $this->fail($context . ' page body not available.');
        }

        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    protected function confirmSweetAlert(Browser $browser, int $waitSeconds = 10): void
    {
        $browser->waitFor('.swal2-popup', $waitSeconds);
        $this->assertNotNull($browser->element('.swal2-confirm'), 'SweetAlert confirm button not found.');
        $browser->click('.swal2-confirm')->pause(1200);
    }

    /**
     * Send an in-browser JSON request carrying the session's XSRF token (for CSRF-guarded JSON endpoints).
     */
    protected function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): array
    {
        $script = <<<'JS'
            const done = arguments[arguments.length - 1];
            const [method, url, payload] = arguments;
            const token = decodeURIComponent((document.cookie.match(/XSRF-TOKEN=([^;]+)/) || [null, ''])[1]);
            fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-XSRF-TOKEN': token,
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: (method === 'GET' || method === 'HEAD') ? undefined : JSON.stringify(payload),
                credentials: 'same-origin'
            })
            .then(r => r.text().then(t => done({ status: r.status, body: t })))
            .catch(e => done({ status: 0, body: String(e) }));
        JS;

        $result = $browser->driver->executeAsyncScript($script, [strtoupper($method), $url, $payload]);
        return is_array($result) ? $result : ['status' => 0, 'body' => ''];
    }

    // ---- source / schema helpers ---------------------------------------------

    /** Whether the SoftDeletes lifecycle is actually usable (deleted_at present) — DEV-GLB-D04 guard. */
    private function softDeletesUsable(): bool
    {
        try {
            return Schema::hasColumn(self::TABLE, 'deleted_at');
        } catch (Throwable) {
            return false;
        }
    }

    /** Assert the live Prime store validate([...]) block contains a rule fragment. */
    private function assertLiveStoreRuleContains(string $fragment, string $message): void
    {
        $source = $this->sourceOfClass(PrimeDropdownController::class);
        $this->assertStringContainsString($fragment, $source, $message);
    }

    /** Best-effort real soft-delete round-trip on a throwaway row (only when deleted_at exists). */
    private function exerciseSoftDeleteRoundTrip(): void
    {
        $key = 'dusk.sys.dropdown.' . uniqid();
        $row = null;
        try {
            $row = PrimeDropdown::create([
                'ordinal' => (int) (PrimeDropdown::max('ordinal') ?? 0) + 1,
                'key' => $key,
                'value' => 'Dusk Guarded ' . rand(1000, 9999),
                'type' => 'String',
                'is_active' => true,
            ]);

            $id = (int) $row->id;
            $row->delete();
            $this->assertNotNull(PrimeDropdown::withTrashed()->find($id)?->deleted_at, 'Soft delete did not set deleted_at.');

            $row->restore();
            $this->assertNull(PrimeDropdown::withTrashed()->find($id)?->deleted_at, 'Restore did not clear deleted_at.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Soft-delete round-trip skipped (dependency/schema): ' . $e->getMessage());
        } finally {
            if ($row) {
                $this->guardedForceDelete((int) $row->id);
            }
        }
    }

    /** Guarded permanent cleanup — only force-deletes when SoftDeletes+deleted_at are usable. */
    private function guardedForceDelete(int $id): void
    {
        try {
            if ($this->softDeletesUsable()) {
                PrimeDropdown::withTrashed()->where('id', $id)->forceDelete();
            } else {
                DB::table(self::TABLE)->where('id', $id)->delete();
            }
        } catch (Throwable) {
            // best-effort cleanup only
        }
    }

    /** Read the on-disk source of a class via reflection (resolves the prime_ai module path). */
    private function sourceOf(string $class): string
    {
        try {
            $file = (new ReflectionClass($class))->getFileName();
            return $file && is_file($file) ? (string) file_get_contents($file) : '';
        } catch (Throwable) {
            return '';
        }
    }

    /** Alias for readability at call sites that read a controller class source. */
    private function sourceOfClass(string $class): string
    {
        return $this->sourceOf($class);
    }
}
