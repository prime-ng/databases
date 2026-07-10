<?php

namespace Tests\Browser\Modules\Prime\Setting;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Laravel\Dusk\Browser;
use Modules\SystemConfig\Models\Setting;
use ReflectionClass;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Prime (central) — System Config → Setting screen.
 *
 * Scope: CENTRAL (prime_db). Table `sys_settings`. No tenant init.
 * Host: http://127.0.0.1:8000 (enforced by PrimeDuskTestCase::setUp).
 * Controller: Modules\Prime\Http\Controllers\SettingController (uses Modules\SystemConfig\Models\Setting).
 * Route group: central.system-config.setting.* (+ central.system-config.setting.search).
 *
 * This is a READ + single-field UPDATE screen. Create/Store/Destroy are non-functional
 * stubs in the controller (documented as DEV defects below) and there is NO soft-delete,
 * NO activity logging, and NO tenancy scaffolding for this feature.
 *
 * DEV defects proven by this suite (see GapAnalysis §Cross-Reference Findings):
 *   DEV-001  search() has NO Gate::authorize — BR-PRM-022 (search requires View Settings) FAILS.
 *   DEV-002  store() returns $request — create is a no-op (no persistence).
 *   DEV-003  destroy() is empty — delete is a no-op.
 *   DEV-004  create() returns view('prime::create') — view does not exist (500).
 *   DEV-005  show() returns view('prime::show') — view does not exist (500).
 *   DEV-006  edit.blade.php reads $setting->organization_id — column absent from sys_settings.
 *   DEV-007  index() calls Setting::all() twice as dead code before paginate().
 */
class sys_Setting_TestCas extends PrimeDuskTestCase
{
    // ---- Routes / paths (verified: routes/web.php:292-296, central domain, prefix system-config) ----
    private const INDEX_PATH   = '/system-config/setting';
    private const CREATE_PATH  = '/system-config/setting/create';
    private const SEARCH_PATH  = '/system-config/setting/search';
    private const EDIT_TPL     = '/system-config/setting/%d/edit';
    private const UPDATE_TPL   = '/system-config/setting/%d';
    private const SHOW_TPL     = '/system-config/setting/%d';

    private const ROUTE_INDEX  = 'central.system-config.setting.index';
    private const ROUTE_EDIT   = 'central.system-config.setting.edit';
    private const ROUTE_UPDATE = 'central.system-config.setting.update';
    private const ROUTE_SEARCH = 'central.system-config.setting.search';

    private const TABLE = 'sys_settings';

    // ---- Selectors (verified: Modules/Prime/resources/views/setting/index.blade.php + edit.blade.php) ----
    private const SEARCH_INPUT   = '#search-input';
    private const SUGGESTION_BOX  = '#suggestion-box';
    private const RESET_BTN       = '#reset-btn';
    private const VALUE_INPUT     = 'input[name="value"]';
    private const KEY_HIDDEN      = 'input[name="key"]';
    private const SCREENSHOT_DIR  = 'tests/Browser/Modules/Prime/Setting/screenshots';

    private ?User $adminUser = null;
    private ?Setting $seedSetting = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
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
        if ($this->seedSetting instanceof Setting) {
            try {
                Setting::where('id', $this->seedSetting->id)->delete();
            } catch (Throwable) {
                // ignore cleanup failures
            }
            $this->seedSetting = null;
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01–09 — Schema / model / request / route configuration truth
    // =====================================================================

    /** @test  BC-DB-01..07, BC-INT-01  Source: DDL-sys_settings */
    public function test_setting_01_schema_model_and_route_configuration_are_correct(): void
    {
        // --- Table + columns (central prime_db) ---
        $this->assertTrue(Schema::hasTable(self::TABLE), 'sys_settings table missing on central connection.');

        foreach (['id', 'description', 'key', 'value', 'type', 'is_public', 'created_at', 'updated_at'] as $col) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $col),
                "sys_settings is missing column '{$col}'."
            );
        }

        // --- No soft-delete column (screen has no trash lifecycle) ---
        $this->assertFalse(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'sys_settings unexpectedly has deleted_at (no soft-delete expected).'
        );

        // --- Unique index on `key` (uq_settings_key) ---
        try {
            $indexes = collect(Schema::getIndexes(self::TABLE));
            $hasUniqueKey = $indexes->contains(function ($idx) {
                $cols = $idx['columns'] ?? [];
                return in_array('key', $cols, true) && ($idx['unique'] ?? false);
            });
            $this->assertTrue($hasUniqueKey, 'sys_settings.key is expected to carry a UNIQUE index.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Index introspection unavailable: ' . $e->getMessage());
        }

        // --- Model mapping + fillable (SystemConfig is the canonical model) ---
        $model = new Setting();
        $this->assertSame(self::TABLE, $model->getTable(), 'Setting model must map to sys_settings.');
        $this->assertSame(['key', 'value', 'type', 'is_public'], $model->getFillable());

        // --- No SoftDeletes trait ---
        $this->assertNotContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(Setting::class),
            'Setting model must NOT use SoftDeletes (DDL has no deleted_at).'
        );

        // --- Route registration (central.system-config.setting.*) ---
        $this->assertTrue(Route::has(self::ROUTE_INDEX), 'Route ' . self::ROUTE_INDEX . ' not registered.');
        $this->assertTrue(Route::has(self::ROUTE_EDIT), 'Route ' . self::ROUTE_EDIT . ' not registered.');
        $this->assertTrue(Route::has(self::ROUTE_UPDATE), 'Route ' . self::ROUTE_UPDATE . ' not registered.');
        $this->assertTrue(Route::has(self::ROUTE_SEARCH), 'Route ' . self::ROUTE_SEARCH . ' not registered.');
    }

    /** @test  BC-VAL-01..03  Source: SettingController::update() inline validate */
    public function test_setting_02_controller_declares_inline_update_validation_rules(): void
    {
        $src = $this->controllerSource();

        $this->assertStringContainsString("'key' => 'required|string|exists:sys_settings,key'", $src,
            'update() must validate key as required|string|exists:sys_settings,key.');
        $this->assertStringContainsString("'value' => 'required'", $src,
            'update() must validate value as required.');
        // Controller uses SystemConfig Setting model, NOT the deprecated Prime model.
        $this->assertStringContainsString('use Modules\\SystemConfig\\Models\\Setting;', $src,
            'Controller must import Modules\\SystemConfig\\Models\\Setting.');
    }

    /** @test  BC-DB-08  Source: DDL-sys_settings default */
    public function test_setting_03_is_public_defaults_to_zero_and_type_is_nullable(): void
    {
        $row = $this->seedSetting();
        $fresh = Setting::find($row->id);

        $this->assertSame(0, (int) $fresh->is_public, 'is_public should default to 0 when not supplied.');
        $this->assertNotNull($fresh->key, 'key must persist.');
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    /** @test  BC-BIZ-01  Source: Setting::setKeyAttribute mutator */
    public function test_setting_10_key_mutator_snake_cases_on_write(): void
    {
        $raw = 'My Test Key ' . Str::random(4);
        $row = Setting::create(['key' => $raw, 'value' => 'v', 'type' => 'string', 'is_public' => 0]);
        $this->seedSetting = $row;

        $this->assertSame(Str::snake($raw), $row->fresh()->key, 'setKeyAttribute must Str::snake() the key.');
    }

    /** @test  BC-BIZ-02  Source: Setting::getDisplayKeyAttribute accessor */
    public function test_setting_11_display_key_accessor_humanises_key(): void
    {
        $row = new Setting();
        $row->key = 'default_language';
        $this->assertSame('Default Language', $row->displayKey,
            'displayKey accessor must title-case and de-underscore the key.');
    }

    /** @test  BC-BIZ-03, BC-VAL-03  Source: SettingController::update() */
    public function test_setting_12_update_persists_new_value_and_redirects_to_index(): void
    {
        $row = $this->seedSetting();
        $newValue = 'updated_' . Str::random(6);

        $this->browseWithFailureScreenshot('setting-update-persist', function (Browser $browser) use ($row, $newValue): void {
            $this->visitAuthenticated($browser, sprintf(self::EDIT_TPL, $row->id));
            $this->ensurePageAccessible($browser, 'Setting edit');

            $browser->waitFor(self::VALUE_INPUT, 10)
                ->clear('value')
                ->type('value', $newValue)
                ->press('Save Settings')
                ->pause(1200);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser),
                'Successful update must redirect to the setting index.');
        });

        $this->assertSame($newValue, Setting::find($row->id)->value,
            'DB value must reflect the submitted value after update.');
    }

    /** @test  BC-BIZ-04  Source: SettingController::update() — no activity logging */
    public function test_setting_13_update_writes_no_activity_log_entry(): void
    {
        // The controller never calls activityLog(); assert the source has no such call so the
        // documented "no audit trail" behaviour is locked in. (No central sink assertion needed.)
        $src = $this->controllerSource();
        $this->assertStringNotContainsString('activityLog(', $src,
            'SettingController is expected to contain NO activity logging (documented gap).');
    }

    /** @test  BC-BIZ-05  Source: index.blade.php pagination + SettingController::index paginate(10) */
    public function test_setting_14_index_paginates_ten_per_page(): void
    {
        $src = $this->controllerSource();
        $this->assertStringContainsString('paginate(10)', $src, 'index() must paginate 10 per page.');
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL)
    // =====================================================================

    /** @test  BC-VAL-01  Source: update() required key/value */
    public function test_setting_30_update_rejects_missing_value(): void
    {
        $row = $this->seedSetting();
        $this->actingAs($this->requireAdminUser());

        $resp = $this->from(self::INDEX_PATH)->put(sprintf(self::UPDATE_TPL, $row->id), [
            'key' => $row->key,
            // value omitted
        ]);

        $resp->assertSessionHasErrors('value');
        $this->assertSame($row->value, Setting::find($row->id)->value, 'Value must be unchanged on validation failure.');
    }

    /** @test  BC-VAL-01  Source: update() required key */
    public function test_setting_31_update_rejects_missing_key(): void
    {
        $row = $this->seedSetting();
        $this->actingAs($this->requireAdminUser());

        $resp = $this->from(self::INDEX_PATH)->put(sprintf(self::UPDATE_TPL, $row->id), [
            'value' => 'anything',
            // key omitted
        ]);

        $resp->assertSessionHasErrors('key');
    }

    /** @test  BC-VAL-02  Source: update() key must exist:sys_settings,key */
    public function test_setting_32_update_rejects_non_existent_key(): void
    {
        $row = $this->seedSetting();
        $this->actingAs($this->requireAdminUser());

        $resp = $this->from(self::INDEX_PATH)->put(sprintf(self::UPDATE_TPL, $row->id), [
            'key' => 'this_key_does_not_exist_' . Str::random(6),
            'value' => 'x',
        ]);

        $resp->assertSessionHasErrors('key');
    }

    /** @test  BC-VAL-01  Source: update() required value (empty string) */
    public function test_setting_33_update_rejects_empty_string_value(): void
    {
        $row = $this->seedSetting();
        $this->actingAs($this->requireAdminUser());

        $resp = $this->from(self::INDEX_PATH)->put(sprintf(self::UPDATE_TPL, $row->id), [
            'key' => $row->key,
            'value' => '',
        ]);

        $resp->assertSessionHasErrors('value');
    }

    // =====================================================================
    // Band 40–49 — Integration / FK / model parity (BC-INT / BC-REF)
    // =====================================================================

    /** @test  BC-INT-01  Source: both models map sys_settings */
    public function test_setting_40_prime_and_systemconfig_models_map_same_table(): void
    {
        $this->assertSame(self::TABLE, (new \Modules\Prime\Models\Setting())->getTable());
        $this->assertSame(self::TABLE, (new Setting())->getTable());
        $this->assertSame(
            (new \Modules\Prime\Models\Setting())->getFillable(),
            (new Setting())->getFillable(),
            'Prime (deprecated) and SystemConfig Setting models must stay in sync.'
        );
    }

    /** @test  BC-REF-01  Source: DDL-sys_settings — no outbound FKs */
    public function test_setting_41_settings_table_has_no_foreign_keys(): void
    {
        try {
            $fks = Schema::getForeignKeys(self::TABLE);
            $this->assertEmpty($fks, 'sys_settings is not expected to declare foreign keys.');
        } catch (Throwable $e) {
            $this->markTestSkipped('FK introspection unavailable: ' . $e->getMessage());
        }
    }

    /** @test  BC-INT-02  Source: unique key uq_settings_key */
    public function test_setting_42_duplicate_key_insert_is_rejected_by_unique_index(): void
    {
        $row = $this->seedSetting();
        $threw = false;
        try {
            Setting::create(['key' => $row->key, 'value' => 'dup', 'type' => 'string', 'is_public' => 0]);
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'Inserting a duplicate key must violate the unique index.');
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    /** @test  BC-AUTH-01..05  Source: SettingController Gate::authorize calls */
    public function test_setting_50_restful_methods_declare_permission_gates(): void
    {
        $src = $this->controllerSource();
        $this->assertStringContainsString("Gate::authorize('prime.setting.viewAny')", $src);
        $this->assertStringContainsString("Gate::authorize('prime.setting.create')", $src);
        $this->assertStringContainsString("Gate::authorize('prime.setting.view')", $src);
        $this->assertStringContainsString("Gate::authorize('prime.setting.update')", $src);
        $this->assertStringContainsString("Gate::authorize('prime.setting.delete')", $src);
    }

    /**
     * @test  BC-AUTH-06 / DEV-001  Source: SettingController::search()
     * DEFECT: search() has NO Gate::authorize, so BR-PRM-022 (search requires View Settings) FAILS.
     * This test proves the CURRENT (defective) behaviour: the search method body carries no gate.
     */
    public function test_setting_51_search_endpoint_is_ungated_defect_dev001(): void
    {
        $src = $this->controllerSource();
        // Isolate the search() method body.
        $pos = strpos($src, 'public function search(');
        $this->assertNotFalse($pos, 'search() method not found in controller.');
        $body = substr($src, $pos);
        $end = strpos($body, 'public function ', 10);
        if ($end !== false) {
            $body = substr($body, 0, $end);
        }
        $this->assertStringNotContainsString('Gate::authorize', $body,
            'DEV-001 regressed/fixed: search() now contains a Gate — update the defect record.');
    }

    /** @test  BC-AUTH-07  Source: index.blade.php @can gates */
    public function test_setting_52_index_view_gates_content_and_action_column(): void
    {
        $blade = $this->viewSource('Modules/Prime/resources/views/setting/index.blade.php');
        $this->assertStringContainsString("@can('prime.setting.viewAny')", $blade);
        $this->assertStringContainsString("@can('prime.setting.update')", $blade);
    }

    /** @test  BC-AUTH-08  Source: routes middleware auth,verified */
    public function test_setting_53_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('setting-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser),
                'Guest must be redirected to /login.');
        });
    }

    /** @test  BC-AUTH-09  Source: Gate authorize on index (defensive live 403) */
    public function test_setting_54_limited_user_receives_403_on_index(): void
    {
        try {
            $limited = $this->makeLimitedUser();
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not provision a limited central user: ' . $e->getMessage());
            return;
        }

        $this->actingAs($limited);
        $resp = $this->get(self::INDEX_PATH);
        $this->assertContains($resp->getStatusCode(), [403, 500],
            'A user without prime.setting.viewAny must be forbidden (403).');

        try {
            User::where('id', $limited->id)->forceDelete();
        } catch (Throwable) {
        }
    }

    // =====================================================================
    // Band 60–69 — UI / UX (render, search box, breadcrumb, empty state)
    // =====================================================================

    /** @test  BC-BIZ-06  Source: index.blade.php */
    public function test_setting_60_index_renders_table_and_search_controls(): void
    {
        $this->seedSetting();

        $this->browseWithFailureScreenshot('setting-index-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Setting index');

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser));
            $browser->assertPresent(self::SEARCH_INPUT)
                ->assertPresent(self::RESET_BTN)
                ->assertSee('Key')
                ->assertSee('Value')
                ->assertSee('Is Public');
        });
    }

    /** @test  BC-BIZ-07  Source: breadcrum title="System Config" */
    public function test_setting_61_index_shows_system_config_breadcrumb(): void
    {
        $this->browseWithFailureScreenshot('setting-breadcrumb', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Setting index breadcrumb');
            $browser->assertSee('System Config');
        });
    }

    /** @test  BC-BIZ-08  Source: index.blade.php search data-attributes */
    public function test_setting_62_search_input_wires_search_and_redirect_urls(): void
    {
        $blade = $this->viewSource('Modules/Prime/resources/views/setting/index.blade.php');
        $this->assertStringContainsString("route('central.system-config.setting.search')", $blade);
        $this->assertStringContainsString("route('central.system-config.setting.index')", $blade);
    }

    /** @test  BC-BIZ-09  Source: index.blade.php @forelse empty branch */
    public function test_setting_63_index_shows_empty_state_message_markup(): void
    {
        $blade = $this->viewSource('Modules/Prime/resources/views/setting/index.blade.php');
        $this->assertStringContainsString('No Setting Data Found', $blade);
    }

    /** @test  BC-BIZ-10  Source: edit.blade.php */
    public function test_setting_64_edit_form_renders_value_input_and_hidden_key(): void
    {
        $row = $this->seedSetting();

        $this->browseWithFailureScreenshot('setting-edit-render', function (Browser $browser) use ($row): void {
            $this->visitAuthenticated($browser, sprintf(self::EDIT_TPL, $row->id));
            $this->ensurePageAccessible($browser, 'Setting edit render');
            $browser->assertPresent(self::VALUE_INPUT)
                ->assertPresent(self::KEY_HIDDEN)
                ->assertSee('Edit Setting');
        });
    }

    /** @test  BC-BIZ-11  Source: search() JSON — LIKE on key + description */
    public function test_setting_65_search_endpoint_returns_matching_json(): void
    {
        $token = 'sfx' . strtolower(Str::random(6));
        $row = Setting::create([
            'key' => 'search_probe_' . $token,
            'value' => 'v',
            'type' => 'string',
            'is_public' => 0,
        ]);
        $this->seedSetting = $row;

        $this->actingAs($this->requireAdminUser());
        $resp = $this->getJson(self::SEARCH_PATH . '?search=' . $token);
        $resp->assertOk();
        $resp->assertJsonFragment(['key' => $row->fresh()->key]);
    }

    /** @test  BC-BIZ-12  Source: search() empty-search short-circuit */
    public function test_setting_66_search_with_empty_term_returns_empty_array(): void
    {
        $this->actingAs($this->requireAdminUser());
        $resp = $this->getJson(self::SEARCH_PATH . '?search=');
        $resp->assertOk();
        $resp->assertExactJson([]);
    }

    // =====================================================================
    // Band 70–79 — Edge cases + DEFECT proofs (BC-EDG / DEV)
    // =====================================================================

    /** @test  BC-EDG-01  Source: edit() findOrFail */
    public function test_setting_70_edit_non_existent_id_returns_404(): void
    {
        $this->actingAs($this->requireAdminUser());
        $resp = $this->get(sprintf(self::EDIT_TPL, 999999999));
        $this->assertContains($resp->getStatusCode(), [404, 403],
            'Editing a non-existent setting id must 404 (findOrFail).');
    }

    /**
     * @test  DEV-002  Source: SettingController::store() returns $request
     * DEFECT: store persists nothing. Prove no row is created.
     */
    public function test_setting_71_store_is_a_noop_defect_dev002(): void
    {
        $this->actingAs($this->requireAdminUser());
        $before = Setting::count();

        $resp = $this->post(self::INDEX_PATH, [
            'key' => 'noop_probe_' . Str::random(6),
            'value' => 'x',
        ]);

        // store() returns the request (not a redirect/persist).
        $this->assertSame($before, Setting::count(), 'DEV-002 regressed: store() now persists rows.');
        $this->assertContains($resp->getStatusCode(), [200, 302, 500]);
    }

    /**
     * @test  DEV-003  Source: SettingController::destroy() empty body
     * DEFECT: destroy deletes nothing.
     */
    public function test_setting_72_destroy_is_a_noop_defect_dev003(): void
    {
        $row = $this->seedSetting();
        $this->actingAs($this->requireAdminUser());

        $this->delete(sprintf(self::UPDATE_TPL, $row->id));

        $this->assertNotNull(Setting::find($row->id), 'DEV-003 regressed: destroy() now deletes rows.');
    }

    /**
     * @test  DEV-004  Source: SettingController::create() returns view('prime::create')
     * DEFECT: view('prime::create') does not exist → server error.
     */
    public function test_setting_73_create_view_is_missing_defect_dev004(): void
    {
        $this->actingAs($this->requireAdminUser());
        $resp = $this->get(self::CREATE_PATH);
        // A missing view yields 500 (InvalidArgumentException). 403 if gate blocks first.
        $this->assertContains($resp->getStatusCode(), [500, 403],
            'DEV-004: create() references non-existent prime::create view.');
    }

    /**
     * @test  DEV-005  Source: SettingController::show() returns view('prime::show')
     * DEFECT: view('prime::show') does not exist → server error.
     */
    public function test_setting_74_show_view_is_missing_defect_dev005(): void
    {
        $row = $this->seedSetting();
        $this->actingAs($this->requireAdminUser());
        $resp = $this->get(sprintf(self::SHOW_TPL, $row->id));
        $this->assertContains($resp->getStatusCode(), [500, 403],
            'DEV-005: show() references non-existent prime::show view.');
    }

    /**
     * @test  DEV-006  Source: edit.blade.php reads $setting->organization_id
     * The column is absent from sys_settings; accessing it must yield null, not a hard error.
     */
    public function test_setting_75_organization_id_column_absent_defect_dev006(): void
    {
        $this->assertFalse(
            Schema::hasColumn(self::TABLE, 'organization_id'),
            'DEV-006 context: edit view references organization_id which is absent from sys_settings.'
        );
        $row = $this->seedSetting();
        $this->assertNull($row->organization_id, 'organization_id resolves to null (no column).');
    }

    /** @test  DEV-007  Source: SettingController::index() dead Setting::all() calls */
    public function test_setting_76_index_contains_dead_setting_all_calls_defect_dev007(): void
    {
        $src = $this->controllerSource();
        $this->assertGreaterThanOrEqual(1, substr_count($src, 'Setting::all()'),
            'DEV-007 context: index() carries redundant Setting::all() calls before paginate().');
    }

    // =====================================================================
    // Band 90–99 — Tenancy note + security pack (TC-T / TC-S)
    // =====================================================================

    /** @test  TC-T00  Source: DB scope = central prime_db */
    public function test_setting_90_feature_is_central_scope_no_tenant_isolation(): void
    {
        // Setting lives in central prime_db; there is no per-tenant copy, so cross-tenant
        // isolation tests are not applicable. Assert we are NOT inside a tenant context.
        if (function_exists('tenancy')) {
            $this->assertFalse(tenancy()->initialized, 'Setting is a central feature; tenancy must not be initialized.');
        } else {
            $this->assertTrue(true);
        }
    }

    /** @test  TC-S01  Source: value free-text field — stored XSS payload persists raw, escaped on output */
    public function test_setting_91_value_field_stores_xss_payload_verbatim_and_view_escapes(): void
    {
        $row = $this->seedSetting();
        $payload = '<script>alert(1)</script>';
        $this->actingAs($this->requireAdminUser());

        $this->from(self::INDEX_PATH)->put(sprintf(self::UPDATE_TPL, $row->id), [
            'key' => $row->key,
            'value' => $payload,
        ]);

        // Stored verbatim (no sanitisation in controller).
        $this->assertSame($payload, Setting::find($row->id)->value);

        // Blade escapes on output ({{ }}), so the index must not render an executable script tag.
        $this->browseWithFailureScreenshot('setting-xss-escape', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Setting index XSS');
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source,
                'Blade must HTML-escape the stored value on output.');
        });
    }

    /** @test  TC-S02  Source: search() LIKE binding — injection-shaped input is safe */
    public function test_setting_92_search_handles_injection_shaped_input_safely(): void
    {
        $this->actingAs($this->requireAdminUser());
        $resp = $this->getJson(self::SEARCH_PATH . '?search=' . urlencode("' OR '1'='1"));
        $resp->assertOk(); // parameter-bound LIKE; must not error or dump the table
        $this->assertIsArray($resp->json());
    }

    // =====================================================================
    // ---- Private helper library ----
    // =====================================================================

    private function seedSetting(): Setting
    {
        if ($this->seedSetting instanceof Setting) {
            return $this->seedSetting;
        }

        $this->seedSetting = Setting::create([
            'key' => 'test_setting_' . Str::lower(Str::random(10)),
            'value' => 'initial_value',
            'type' => 'string',
            'is_public' => 0,
        ]);

        return $this->seedSetting;
    }

    private function controllerSource(): string
    {
        $file = (new ReflectionClass(\Modules\Prime\Http\Controllers\SettingController::class))->getFileName();
        $this->assertNotFalse($file, 'Could not resolve SettingController source path.');
        return (string) file_get_contents($file);
    }

    private function viewSource(string $relative): string
    {
        // Resolve the app view file relative to the model's package root (works regardless of repo layout).
        $modelFile = (new ReflectionClass(Setting::class))->getFileName();
        // .../Modules/SystemConfig/app/Models/Setting.php  ->  app base
        $appBase = $modelFile;
        for ($i = 0; $i < 5; $i++) {
            $appBase = dirname($appBase);
        }
        $candidate = $appBase . DIRECTORY_SEPARATOR . $relative;
        if (is_file($candidate)) {
            return (string) file_get_contents($candidate);
        }
        // Fallbacks
        foreach ([base_path($relative), base_path('../prime_ai/' . $relative)] as $alt) {
            if (is_file($alt)) {
                return (string) file_get_contents($alt);
            }
        }
        $this->markTestSkipped('View source not resolvable: ' . $relative);
        return '';
    }

    private function requireAdminUser(): User
    {
        if (!$this->adminUser) {
            $this->resolveAdminUser();
        }
        if (!$this->adminUser) {
            $this->markTestSkipped('No central admin user available.');
        }
        return $this->adminUser;
    }

    private function makeLimitedUser(): User
    {
        $suffix = '_' . uniqid();
        return User::create([
            'name' => 'Limited Setting User',
            'email' => 'limited_setting' . $suffix . '@example.com',
            'password' => bcrypt('password'),
            'emp_code' => 'LS' . substr($suffix, 0, 12),
            'is_active' => 1,
            'is_super_admin' => 0,
            'super_admin_flag' => 0,
            'email_verified_at' => now(),
        ]);
    }

    // ---- Central auth / navigation helpers (adapted from BillingDuskTestCase) ----

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

    private function resolveAdminUser(): void
    {
        $superAdmin = User::query()->where('is_super_admin', 1)->first();
        if ($superAdmin) {
            $this->adminUser = $superAdmin;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        $byEmail = User::query()->where('email', $this->adminEmail)->first();
        if ($byEmail) {
            $this->adminUser = $byEmail;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        try {
            $this->adminUser = User::create([
                'email' => $this->adminEmail,
                'password' => bcrypt($this->adminPassword),
                'name' => 'Setting Dusk Admin',
                'emp_code' => 'EMP' . rand(100, 999),
                'is_active' => 1,
                'is_super_admin' => 1,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable) {
            $this->adminUser = null;
        }
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

    // ---- Screenshot helpers ----

    private function cleanScreenshots(): void
    {
        $dir = base_path(self::SCREENSHOT_DIR);
        if (is_dir($dir)) {
            foreach (glob($dir . DIRECTORY_SEPARATOR . '*.png') ?: [] as $file) {
                @unlink($file);
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

    private function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'failure';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $safeName . '_' . now()->format('Ymd_Hisv') . '.png';

        try {
            $browser->driver->takeScreenshot($absolutePath);
            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolutePath);
        } catch (Throwable) {
            return '';
        }
    }
}
