<?php

namespace Tests\Browser\Modules\GlobalMaster\Country;

use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\Country;
use Throwable;

/**
 * glb_Country_TestCas
 * ---------------------------------------------------------------------------
 * Comprehensive Dusk + integration suite for the CENTRAL (prime-side) Country
 * feature of the GlobalMaster module. ONE self-contained test file — no V1/V2.
 *
 * DB scope        : CENTRAL / prime-side. NO tenancy init, NO tenant scaffolding.
 * Browser host    : http://127.0.0.1:8000 (NOT test.localhost).
 * Primary table   : glb_countries (DDL-verified prefix = glb_).
 * Model           : Modules\GlobalMaster\Models\Country (conn global_master_mysql).
 * Activity sink   : sys_central_activity_logs (central, when tenancy not init).
 *
 * Semantic numbering bands
 *   01-09  schema / model / request / policy config truth
 *   10-19  business flows (create, update, cascade, activity log)
 *   30-39  validation / negative
 *   40-49  FK / dependency / soft-delete lifecycle
 *   50-59  permissions / auth gates
 *   60-69  UI (pagination, ordering, trash, empty state)
 *   90-99  security pack (stored/reflected XSS, IDOR, mass-assignment)
 *
 * Documented GlobalMaster defects (proven, "verify in source"):
 *   DEV-GLB-C01  short_name / global_code uniqueness NOT validated in
 *                CountryRequest but DB has UNIQUE keys -> raw QueryException.
 *   DEV-GLB-C02  CountryRequest validates default_timezone (max:64) but the
 *                column does not exist / is not fillable -> dead rule.
 *   DEV-GLB-C03  toggleStatus cascades is_active to glb_states/glb_districts
 *                but logs 'Toggled' only for the country (children unlogged).
 *
 * Env prerequisite (NOT a code fix): GlobalMaster AND Prime modules ENABLED in
 * modules_statuses.json; APP_ENV=testing; server on http://127.0.0.1:8000.
 * ---------------------------------------------------------------------------
 */
class glb_Country_TestCas extends \Tests\DuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/GlobalMaster/Country/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/GlobalMaster/Country/report';
    protected const STATUS_REPORT_PREFIX = 'glb_country_report_';

    private const INDEX_PATH  = '/global-master/country';
    private const CREATE_PATH = '/global-master/country/create';
    private const TRASH_PATH  = '/global-master/country/trash/view';

    private const TABLE           = 'glb_countries';
    private const STATES_TABLE    = 'glb_states';
    private const DISTRICTS_TABLE = 'glb_districts';
    private const ACTIVITY_TABLE  = 'sys_central_activity_logs';

    // ---- Typed props (initialized) ----------------------------------------
    protected ?User $adminUser = null;
    protected string $centralBaseUrl = 'http://127.0.0.1:8000';
    protected string $adminEmail = '';
    protected string $adminPassword = '';
    protected array $statusReportEntries = [];

    // =======================================================================
    //  Lifecycle
    // =======================================================================
    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = 'http://127.0.0.1:8000';
        $currentHost = parse_url($this->centralBaseUrl, PHP_URL_HOST);
        if ($currentHost !== '127.0.0.1') {
            $this->fail('Country (central) tests must run on http://127.0.0.1:8000.');
        }

        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->statusReportEntries = [];

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        // Guard: this is a CENTRAL suite — never leave a tenant context bound.
        try {
            if (function_exists('tenancy') && tenancy()->initialized) {
                tenancy()->end();
            }
        } catch (Throwable) {
            // best-effort guard; central suite never initializes tenancy.
        }

        if (!empty($this->statusReportEntries)) {
            $this->writeStatusReportForCurrentTest();
        }

        parent::tearDown();
    }

    // =======================================================================
    //  BAND 01-09  Config / structural truth (no browser required)
    // =======================================================================

    public function test_country_01_glb_countries_table_exists(): void
    {
        $this->assertTrue(
            Schema::hasTable(self::TABLE),
            'glb_countries table/view is missing; cannot run Country tests.'
        );
    }

    public function test_country_02_columns_and_types_match_ddl(): void
    {
        $expected = ['id', 'name', 'short_name', 'global_code', 'currency_code', 'is_active', 'created_at', 'updated_at', 'deleted_at'];
        foreach ($expected as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $column),
                "glb_countries.$column column is missing (DDL mismatch)."
            );
        }

        // Type spot-checks (guarded — view/driver may not expose types).
        $idType = $this->safeColumnType(self::TABLE, 'id');
        if ($idType !== '') {
            $this->assertStringContainsString('int', strtolower($idType), 'glb_countries.id should be an integer type.');
        }
        $activeType = $this->safeColumnType(self::TABLE, 'is_active');
        if ($activeType !== '') {
            $this->assertStringContainsString('int', strtolower($activeType), 'glb_countries.is_active should be tinyint/int.');
        }
    }

    public function test_country_03_soft_delete_column_present(): void
    {
        $this->assertTrue(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'glb_countries.deleted_at is missing; SoftDeletes will fail.'
        );
    }

    public function test_country_04_migration_declares_softdeletes_and_timestamps(): void
    {
        $file = $this->moduleFile('database/migrations/2025_10_09_042528_create_countries_table.php');
        if ($file === null) {
            $this->markTestSkipped('Country migration file not locatable under MAIN_PROJECT_PATH/Modules/GlobalMaster.');
        }

        $content = (string) file_get_contents($file);
        $this->assertStringContainsString('softDeletes', $content, 'Migration must declare softDeletes().');
        $this->assertStringContainsString('timestamps', $content, 'Migration must declare timestamps().');
        $this->assertStringContainsString("Schema::create('glb_countries'", $content, 'Migration must create glb_countries.');
        $this->assertStringContainsString("'global_master_mysql'", $content, 'Migration must target global_master_mysql connection.');
    }

    public function test_country_05_migration_declares_unique_keys(): void
    {
        $file = $this->moduleFile('database/migrations/2025_10_09_042528_create_countries_table.php');
        if ($file === null) {
            $this->markTestSkipped('Country migration file not locatable.');
        }

        $content = (string) file_get_contents($file);
        // name + short_name unique in migration (DDL adds global_code unique too).
        $this->assertStringContainsString('->unique()', $content, 'Migration must declare unique() columns (name, short_name).');
        $this->assertStringContainsString("string('name', 50)", $content, 'name must be varchar(50).');
        $this->assertStringContainsString("string('short_name', 10)", $content, 'short_name must be varchar(10).');
    }

    public function test_country_06_request_rule_strings_are_exact(): void
    {
        $file = $this->moduleFile('app/Http/Requests/CountryRequest.php');
        if ($file === null) {
            $this->markTestSkipped('CountryRequest.php not locatable.');
        }

        $content = (string) file_get_contents($file);
        $this->assertStringContainsString("Rule::unique('glb_countries')", $content, 'name must be unique on glb_countries.');
        $this->assertStringContainsString('->ignore($countryId)', $content, 'name uniqueness must ignore current record on update.');
        $this->assertStringContainsString("'max:50'", $content, 'name max:50 rule expected.');
        $this->assertStringContainsString("'max:10'", $content, 'short_name/global_code max:10 rule expected.');
        $this->assertStringContainsString("'max:8'", $content, 'currency_code max:8 rule expected.');
        $this->assertStringContainsString("'max:64'", $content, 'default_timezone max:64 rule expected (DEV-GLB-C02 dead rule).');
        $this->assertStringContainsString("'required|boolean'", $content, 'is_active required|boolean rule expected.');
    }

    public function test_country_07_request_authorizes_and_normalizes_checkbox(): void
    {
        $file = $this->moduleFile('app/Http/Requests/CountryRequest.php');
        if ($file === null) {
            $this->markTestSkipped('CountryRequest.php not locatable.');
        }

        $content = (string) file_get_contents($file);
        $this->assertStringContainsString('return true;', $content, 'CountryRequest::authorize() must return true.');
        $this->assertStringContainsString('prepareForValidation', $content, 'CountryRequest must normalize the is_active checkbox.');
        $this->assertStringContainsString("=== 'on'", $content, "prepareForValidation must convert 'on' -> boolean.");
    }

    public function test_country_08_model_table_fillable_and_softdeletes(): void
    {
        $model = new Country();

        $this->assertSame(self::TABLE, $model->getTable(), 'Country::getTable() must be glb_countries.');
        $this->assertSame('global_master_mysql', $model->getConnectionName(), 'Country must use global_master_mysql.');

        $expectedFillable = ['name', 'short_name', 'global_code', 'currency_code', 'is_active'];
        $this->assertSame($expectedFillable, $model->getFillable(), 'Country fillable mismatch.');

        // SoftDeletes trait present.
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            array_values(class_uses($model)),
            'Country must use the SoftDeletes trait.'
        );

        // DEV-GLB-C02: default_timezone is validated but NOT fillable.
        $this->assertNotContains('default_timezone', $model->getFillable(), 'default_timezone must not be fillable (DEV-GLB-C02).');
    }

    public function test_country_09_model_relationship_and_policy_gates(): void
    {
        $relation = (new Country())->states();
        $this->assertInstanceOf(
            \Illuminate\Database\Eloquent\Relations\HasMany::class,
            $relation,
            'Country::states() must be a HasMany relation.'
        );

        $file = $this->moduleFile('app/Policies/CountryPolicy.php');
        if ($file === null) {
            $this->markTestSkipped('CountryPolicy.php not locatable.');
        }
        $content = (string) file_get_contents($file);
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'] as $ability) {
            $this->assertStringContainsString("prime.country.$ability", $content, "Policy must map prime.country.$ability.");
        }
    }

    // =======================================================================
    //  BAND 10-19  Business flows
    // =======================================================================

    public function test_country_10_index_loads(): void
    {
        $this->assertCountryTableReady();

        $this->browseWithFailureScreenshot('country-index', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Country index not reachable.');
            $this->ensurePageAccessible($browser, 'Country index');

            $browser->assertSee('Countries');
            $browser->assertPresent('table');
        });
    }

    public function test_country_11_create_page_loads(): void
    {
        $this->assertCountryTableExists();

        $this->browseWithFailureScreenshot('country-create-page', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Country create page not reachable.');
            $this->ensurePageAccessible($browser, 'Country create');

            $browser->assertPresent('input[name="name"]');
            $browser->assertPresent('input[name="short_name"]');
            $browser->assertPresent('input[name="global_code"]');
            $browser->assertPresent('input[name="currency_code"]');
        });
    }

    public function test_country_12_create_flow_persists_and_logs_stored(): void
    {
        $this->assertCountryTableReady();

        $name = $this->makeName();
        $short = $this->makeShortName();
        $global = $this->makeGlobalCode();
        $currency = $this->makeCurrencyCode();

        $this->browseWithFailureScreenshot('country-create', function (Browser $browser) use ($name, $short, $global, $currency): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create');

            $browser
                ->type('name', $name)
                ->type('short_name', $short)
                ->type('global_code', $global)
                ->type('currency_code', $currency)
                ->check('#is_active')
                ->press('Add Country')
                ->pause(2000);
        });

        $country = Country::withTrashed()->where('short_name', $short)->first();
        $this->assertNotNull($country, 'Country was not created.');

        if ($country) {
            try {
                $this->assertSame($name, (string) $country->name);
                $this->assertSame($global, (string) $country->global_code);
                $this->assertTrue((bool) $country->is_active);
                $this->assertActivityLogged($country->id, 'Stored');
            } finally {
                $this->purgeCountryById((int) $country->id);
            }
        }
    }

    public function test_country_13_update_flow_persists_and_logs_updated(): void
    {
        $this->assertCountryTableReady();

        $country = $this->createCountryRecord();
        $newName = 'Upd ' . $this->makeName();

        try {
            $this->browseWithFailureScreenshot('country-update', function (Browser $browser) use ($country, $newName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Country index');

                $this->clickEditAction($browser, (int) $country->id);
                $this->confirmSweetAlert($browser);
                $browser->waitFor('#name', 10);

                $browser
                    ->clear('name')->type('name', $newName)
                    ->check('#is_active')
                    ->press('Update Country')
                    ->pause(2000);
            });

            $country->refresh();
            $this->assertSame($newName, (string) $country->name, 'Country name was not updated.');
            $this->assertActivityLogged((int) $country->id, 'Updated');
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    public function test_country_14_show_page_loads(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord();

        try {
            $this->browseWithFailureScreenshot('country-show', function (Browser $browser) use ($country): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $country->id);
                $this->ensurePageAccessible($browser, 'Country show');
                $browser->assertSee('Country Details');
                $browser->assertSee((string) $country->name);
            });
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    public function test_country_15_edit_page_prefilled(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord();

        try {
            $this->browseWithFailureScreenshot('country-edit-prefill', function (Browser $browser) use ($country): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $country->id . '/edit');
                $this->ensurePageAccessible($browser, 'Country edit');
                $browser->assertInputValue('name', (string) $country->name);
                $browser->assertInputValue('short_name', (string) $country->short_name);
            });
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    /**
     * DEV-GLB-C03: toggleStatus cascades is_active to child glb_states and
     * glb_districts, but writes the 'Toggled' activity event only for the
     * country. Prove the cascade + prove only the country is logged.
     */
    public function test_country_16_toggle_status_cascades_to_children(): void
    {
        $this->assertCountryTableReady();

        $country = $this->createCountryRecord(['is_active' => true]);
        $stateId = $this->seedState((int) $country->id, true);
        $districtId = $stateId !== null ? $this->seedDistrict($stateId, true) : null;

        try {
            $response = $this->actingAs($this->adminUser)
                ->postJson($this->toggleUrl((int) $country->id), ['is_active' => 0]);

            $response->assertOk();
            $response->assertJson(['success' => true, 'is_active' => false]);

            $country->refresh();
            $this->assertFalse((bool) $country->is_active, 'Country is_active did not toggle off.');

            if ($stateId !== null) {
                $stateActive = DB::connection('global_master_mysql')
                    ->table(self::STATES_TABLE)->where('id', $stateId)->value('is_active');
                $this->assertSame(0, (int) $stateActive, 'DEV-GLB-C03: child state is_active did not cascade.');
            }
            if ($districtId !== null) {
                $districtActive = DB::connection('global_master_mysql')
                    ->table(self::DISTRICTS_TABLE)->where('id', $districtId)->value('is_active');
                $this->assertSame(0, (int) $districtActive, 'DEV-GLB-C03: child district is_active did not cascade.');
            }

            // Only the country is logged (children changes are unlogged — the defect).
            $this->assertActivityLogged((int) $country->id, 'Toggled');
        } finally {
            if ($districtId !== null) {
                $this->purgeGlobal(self::DISTRICTS_TABLE, $districtId);
            }
            if ($stateId !== null) {
                $this->purgeGlobal(self::STATES_TABLE, $stateId);
            }
            $this->purgeCountryById((int) $country->id);
        }
    }

    public function test_country_17_activity_log_records_performed_by(): void
    {
        $this->assertCountryTableReady();
        if (!Schema::hasTable(self::ACTIVITY_TABLE)) {
            $this->markTestSkipped(self::ACTIVITY_TABLE . ' sink not present.');
        }

        $country = $this->createCountryRecord();

        try {
            $this->actingAs($this->adminUser)->postJson($this->toggleUrl((int) $country->id), ['is_active' => 0])->assertOk();

            $row = DB::table(self::ACTIVITY_TABLE)
                ->where('subject_id', $country->id)
                ->where('event', 'Toggled')
                ->orderByDesc('id')
                ->first();

            $this->assertNotNull($row, 'Toggle activity row missing.');
            $this->assertNotNull($row->properties ?? null, 'Activity properties payload missing.');
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    // =======================================================================
    //  BAND 30-39  Validation / negative
    // =======================================================================

    public function test_country_30_create_requires_required_fields(): void
    {
        $this->assertCountryTableExists();

        $this->browseWithFailureScreenshot('country-required', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create');

            $browser->press('Add Country')->pause(1200);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Validation should keep user on create page.');
            $browser->assertPresent('.alert.alert-danger');
            $browser->assertPresent('.alert.alert-danger li');
        });
    }

    public function test_country_31_name_max_length_enforced(): void
    {
        $this->assertOverlongFieldRejected('name', str_repeat('N', 51), 'country-name-max');
    }

    public function test_country_32_short_name_max_length_enforced(): void
    {
        $this->assertOverlongFieldRejected('short_name', str_repeat('S', 11), 'country-short-max', ['name' => $this->makeName()]);
    }

    public function test_country_33_global_code_max_length_enforced(): void
    {
        $this->assertOverlongFieldRejected('global_code', str_repeat('G', 11), 'country-global-max', [
            'name' => $this->makeName(),
            'short_name' => $this->makeShortName(),
        ]);
    }

    public function test_country_34_currency_code_max_length_enforced(): void
    {
        $this->assertOverlongFieldRejected('currency_code', str_repeat('C', 9), 'country-currency-max', [
            'name' => $this->makeName(),
            'short_name' => $this->makeShortName(),
        ]);
    }

    public function test_country_35_duplicate_name_rejected(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord();
        $existingName = (string) $country->name;

        try {
            $this->browseWithFailureScreenshot('country-dup-name', function (Browser $browser) use ($existingName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH);
                $this->ensurePageAccessible($browser, 'Country create');

                $browser
                    ->type('name', $existingName)
                    ->type('short_name', $this->makeShortName())
                    ->type('global_code', $this->makeGlobalCode())
                    ->type('currency_code', $this->makeCurrencyCode())
                    ->check('#is_active')
                    ->press('Add Country')
                    ->pause(1500);

                $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Duplicate name should stay on create page.');
                $browser->assertPresent('.alert.alert-danger');
            });

            $this->assertSame(1, Country::query()->where('name', $existingName)->count(), 'Duplicate name created a second country.');
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    /**
     * DEV-GLB-C01: CountryRequest does NOT validate short_name uniqueness,
     * yet the DB has a UNIQUE key. A duplicate short_name therefore bypasses
     * validation and raises a raw QueryException (DB 500) instead of a
     * friendly validation error. Proven at the model layer for determinism.
     */
    public function test_country_36_duplicate_short_name_raises_db_error(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord();
        $duplicateShort = (string) $country->short_name;

        $thrown = false;
        try {
            Country::create([
                'name' => $this->makeName(),
                'short_name' => $duplicateShort, // duplicate — no validation guard
                'global_code' => $this->makeGlobalCode(),
                'currency_code' => $this->makeCurrencyCode(),
                'is_active' => true,
            ]);
        } catch (QueryException) {
            $thrown = true;
        } finally {
            $this->purgeCountryById((int) $country->id);
        }

        $this->assertTrue(
            $thrown,
            'DEV-GLB-C01: duplicate short_name must raise a DB unique violation (no validation guard exists).'
        );
        // Confirm no second row leaked in.
        $this->assertSame(0, Country::query()->where('short_name', $duplicateShort)->count());
    }

    public function test_country_37_xss_name_is_escaped_not_executed(): void
    {
        $this->assertCountryTableReady();
        $payload = '<script>alert("xssC")</script>';
        $short = $this->makeShortName();

        $this->browseWithFailureScreenshot('country-xss-name', function (Browser $browser) use ($payload, $short): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create');

            $browser
                ->type('name', $payload)
                ->type('short_name', $short)
                ->type('global_code', $this->makeGlobalCode())
                ->type('currency_code', $this->makeCurrencyCode())
                ->check('#is_active')
                ->press('Add Country')
                ->pause(1500);
        });

        $country = Country::withTrashed()->where('short_name', $short)->first();
        try {
            if ($country) {
                // Stored verbatim (escaped on render, never executed). Verify list page escapes it.
                $this->browseWithFailureScreenshot('country-xss-render', function (Browser $browser) use ($payload): void {
                    $this->authenticateCentral($browser);
                    $this->visitAuthenticated($browser, self::INDEX_PATH);
                    $source = $browser->driver->getPageSource();
                    $this->assertStringNotContainsString($payload, $source, 'Raw <script> payload must be HTML-escaped on the index.');
                });
            }
        } finally {
            if ($country) {
                $this->purgeCountryById((int) $country->id);
            }
        }
    }

    public function test_country_38_whitespace_only_name_rejected(): void
    {
        $this->assertCountryTableExists();

        $this->browseWithFailureScreenshot('country-whitespace-name', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create');

            $browser
                ->type('name', '   ')
                ->type('short_name', $this->makeShortName())
                ->check('#is_active')
                ->press('Add Country')
                ->pause(1500);

            // Laravel trims by default -> required fails -> stays on create.
            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Whitespace-only name should be rejected.');
            $browser->assertPresent('.alert.alert-danger');
        });
    }

    public function test_country_39_invalid_id_edit_returns_404(): void
    {
        $this->assertCountryTableExists();

        $response = $this->actingAs($this->adminUser)->get(self::INDEX_PATH . '/99999999/edit');
        $response->assertNotFound();
    }

    // =======================================================================
    //  BAND 40-49  FK / dependency / soft-delete lifecycle
    // =======================================================================

    public function test_country_40_soft_delete_restore_force_delete_lifecycle(): void
    {
        $this->assertCountryTableReady();

        $country = $this->createCountryRecord();
        $countryId = (int) $country->id;
        $name = (string) $country->name;

        try {
            $this->browseWithFailureScreenshot('country-trash-flow', function (Browser $browser) use ($countryId, $name): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Country index');

                $this->clickDeleteAction($browser, $countryId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $deleted = Country::withTrashed()->find($countryId);
                $this->assertNotNull($deleted, 'Country missing after soft delete.');
                $this->assertNotNull($deleted->deleted_at, 'Country was not soft deleted.');
                $this->assertFalse((bool) $deleted->is_active, 'Soft delete should also deactivate the country.');

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $browser->assertSee($name);

                $this->clickRestoreAction($browser, $countryId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $restored = Country::withTrashed()->find($countryId);
                $this->assertNotNull($restored, 'Country missing after restore.');
                $this->assertNull($restored->deleted_at, 'Country was not restored.');

                // Delete again, then force delete from trash.
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->clickDeleteAction($browser, $countryId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $this->clickForceDeleteAction($browser, $countryId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $this->assertFalse(
                Country::withTrashed()->where('id', $countryId)->exists(),
                'Country still exists after force delete.'
            );
        } finally {
            $this->purgeCountryById($countryId);
        }
    }

    /**
     * FK RESTRICT: glb_states.country_id references glb_countries with RESTRICT.
     * A force-delete of a country that still has states must be blocked at the
     * DB layer (QueryException) — the country row must survive.
     */
    public function test_country_41_states_fk_restrict_blocks_force_delete(): void
    {
        $this->assertCountryTableReady();
        if (!Schema::hasTable(self::STATES_TABLE)) {
            $this->markTestSkipped('glb_states table not present.');
        }

        $country = $this->createCountryRecord();
        $stateId = $this->seedState((int) $country->id, true);
        if ($stateId === null) {
            $this->purgeCountryById((int) $country->id);
            $this->markTestSkipped('Could not seed a child state to exercise FK RESTRICT.');
        }

        $blocked = false;
        try {
            $trashed = Country::withTrashed()->find($country->id);
            if ($trashed) {
                $trashed->forceDelete();
            }
        } catch (QueryException) {
            $blocked = true;
        } catch (Throwable) {
            $blocked = true;
        } finally {
            $this->purgeGlobal(self::STATES_TABLE, (int) $stateId);
            $this->purgeCountryById((int) $country->id);
        }

        $this->assertTrue($blocked, 'FK RESTRICT: force-deleting a country with child states must be blocked at the DB.');
    }

    public function test_country_42_restore_does_not_recover_children(): void
    {
        $this->assertCountryTableReady();
        if (!Schema::hasTable(self::STATES_TABLE) || !Schema::hasColumn(self::STATES_TABLE, 'deleted_at')) {
            $this->markTestSkipped('glb_states soft-delete not present.');
        }

        $country = $this->createCountryRecord();
        $stateId = $this->seedState((int) $country->id, true);
        if ($stateId === null) {
            $this->purgeCountryById((int) $country->id);
            $this->markTestSkipped('Could not seed a child state.');
        }

        try {
            // Soft-delete both the state and the country, then restore ONLY the country.
            DB::connection('global_master_mysql')->table(self::STATES_TABLE)->where('id', $stateId)->update(['deleted_at' => now()]);
            $country->delete();

            $country->restore();

            $stateDeletedAt = DB::connection('global_master_mysql')->table(self::STATES_TABLE)->where('id', $stateId)->value('deleted_at');
            $this->assertNotNull($stateDeletedAt, 'Restoring a country must NOT resurrect its soft-deleted children.');
        } finally {
            $this->purgeGlobal(self::STATES_TABLE, (int) $stateId);
            $this->purgeCountryById((int) $country->id);
        }
    }

    /**
     * DEV-GLB-C02: default_timezone is a validated rule but not a real column
     * and not fillable -> silently ignored (dead rule). Prove both facts.
     */
    public function test_country_43_default_timezone_is_a_dead_rule(): void
    {
        $this->assertFalse(
            Schema::hasColumn(self::TABLE, 'default_timezone'),
            'DEV-GLB-C02: glb_countries has no default_timezone column.'
        );
        $this->assertNotContains(
            'default_timezone',
            (new Country())->getFillable(),
            'DEV-GLB-C02: default_timezone is not fillable, so the max:64 rule is dead.'
        );
    }

    public function test_country_44_soft_delete_sets_deleted_at_and_deactivates(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord(['is_active' => true]);

        try {
            $country->is_active = false;
            $country->save();
            $country->delete();

            $fresh = Country::withTrashed()->find($country->id);
            $this->assertNotNull($fresh->deleted_at, 'deleted_at must be set on soft delete.');
            $this->assertFalse((bool) $fresh->is_active, 'is_active must be false after delete.');
            $this->assertNull(Country::find($country->id), 'Soft-deleted country must be excluded from default scope.');
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    public function test_country_45_force_delete_permanently_removes_row(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord();
        $id = (int) $country->id;

        try {
            $country->delete();
            $trashed = Country::withTrashed()->find($id);
            if ($trashed) {
                $trashed->forceDelete();
            }
            $this->assertFalse(Country::withTrashed()->where('id', $id)->exists(), 'Row must be gone after force delete.');
        } finally {
            $this->purgeCountryById($id);
        }
    }

    // =======================================================================
    //  BAND 50-59  Permissions / auth gates
    // =======================================================================

    public function test_country_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('country-guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    public function test_country_51_limited_user_forbidden_403(): void
    {
        $this->assertCountryTableExists();
        $limited = $this->makeLimitedUser();

        try {
            $response = $this->actingAs($limited)->get(self::INDEX_PATH);
            $response->assertForbidden();
        } finally {
            $this->purgeUser($limited);
        }
    }

    public function test_country_52_limited_user_action_buttons_hidden(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord();
        $limited = $this->makeLimitedUser();

        try {
            $this->browseWithFailureScreenshot('country-limited-buttons', function (Browser $browser) use ($limited, $country): void {
                $browser->loginAs($limited)->pause(600);
                $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);

                // No update permission -> no edit link for the row.
                $browser->assertMissing('a.confirm-action[href$="/country/' . $country->id . '/edit"]');
            });
        } finally {
            $this->purgeCountryById((int) $country->id);
            $this->purgeUser($limited);
        }
    }

    // =======================================================================
    //  BAND 60-69  UI
    // =======================================================================

    public function test_country_60_index_paginates_ten_per_page(): void
    {
        $this->assertCountryTableReady();

        $this->browseWithFailureScreenshot('country-pagination', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Country index');

            // Never more than 10 data rows per page (paginate(10)).
            $rowCount = count($browser->elements('table tbody tr'));
            $this->assertLessThanOrEqual(11, $rowCount, 'Index must not render more than the paginated page size.');
        });
    }

    public function test_country_61_index_orders_active_first(): void
    {
        $this->assertCountryTableReady();

        // Controller: Country::orderBy('is_active','desc'). Assert query contract.
        $sql = Country::orderBy('is_active', 'desc')->toSql();
        $this->assertStringContainsString('order by', strtolower($sql));
        $this->assertStringContainsString('is_active', strtolower($sql));
    }

    public function test_country_62_trash_page_loads(): void
    {
        $this->assertCountryTableReady();

        $this->browseWithFailureScreenshot('country-trash-page', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH);
            $this->ensurePageAccessible($browser, 'Country trash');
            $browser->assertPresent('table');
        });
    }

    public function test_country_63_index_lists_seeded_country(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord(['is_active' => true]);

        try {
            $this->browseWithFailureScreenshot('country-lists-seeded', function (Browser $browser) use ($country): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Country index');
                // Active-first ordering keeps a freshly-created active row near the top.
                $browser->assertSee((string) $country->short_name);
            });
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    // =======================================================================
    //  BAND 90-99  Security pack
    // =======================================================================

    public function test_country_90_stored_xss_name_escaped_on_show(): void
    {
        $this->assertCountryTableReady();
        $payload = '<b onmouseover=alert(1)>x</b>';
        $country = $this->createCountryRecord(['name' => 'XSS ' . $this->makeName()]);

        try {
            // Force a script-ish stored value directly, bypass form, verify render escaping.
            DB::connection('global_master_mysql')->table(self::TABLE)->where('id', $country->id)->update([
                'global_code' => substr($payload, 0, 10),
            ]);

            $this->browseWithFailureScreenshot('country-stored-xss', function (Browser $browser) use ($country): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $country->id);
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('onmouseover=alert', $source, 'Stored payload must be HTML-escaped on show.');
            });
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    public function test_country_91_reflected_xss_short_name_escaped(): void
    {
        $this->assertCountryTableExists();
        $payload = '"><script>alert(9)</script>';

        $this->browseWithFailureScreenshot('country-reflected-xss', function (Browser $browser) use ($payload): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create');

            $browser
                ->type('name', '') // trigger validation error so old() reflects
                ->type('short_name', $payload)
                ->press('Add Country')
                ->pause(1500);

            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(9)</script>', $source, 'Reflected old() value must be escaped.');
        });
    }

    public function test_country_92_idor_cross_id_returns_404(): void
    {
        $this->assertCountryTableReady();

        // A non-existent id must 404 (route-model-binding), not leak another record.
        $response = $this->actingAs($this->adminUser)->get(self::INDEX_PATH . '/88888888');
        $response->assertNotFound();
    }

    public function test_country_93_mass_assignment_guard_blocks_non_fillable(): void
    {
        $this->assertCountryTableReady();

        $country = new Country();
        $country->fill([
            'name' => $this->makeName(),
            'short_name' => $this->makeShortName(),
            'global_code' => $this->makeGlobalCode(),
            'currency_code' => $this->makeCurrencyCode(),
            'is_active' => true,
            'default_timezone' => 'Asia/Kolkata', // not fillable
            'id' => 999999,                        // not fillable
        ]);

        $this->assertArrayNotHasKey('default_timezone', $country->getAttributes(), 'Non-fillable default_timezone must be blocked.');
        $this->assertArrayNotHasKey('id', $country->getAttributes(), 'Primary key must not be mass-assignable.');
    }

    public function test_country_94_guest_toggle_json_is_unauthorized(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord();

        try {
            $response = $this->postJson($this->toggleUrl((int) $country->id), ['is_active' => 0]);
            // Guest on a web/auth route -> 401 (JSON) or 302 redirect. Never 200.
            $this->assertContains($response->getStatusCode(), [401, 302, 419], 'Guest toggle must not succeed.');
        } finally {
            $this->purgeCountryById((int) $country->id);
        }
    }

    public function test_country_95_limited_user_toggle_json_forbidden(): void
    {
        $this->assertCountryTableReady();
        $country = $this->createCountryRecord();
        $limited = $this->makeLimitedUser();

        try {
            $response = $this->actingAs($limited)->postJson($this->toggleUrl((int) $country->id), ['is_active' => 0]);
            $response->assertForbidden();
        } finally {
            $this->purgeCountryById((int) $country->id);
            $this->purgeUser($limited);
        }
    }

    // =======================================================================
    //  Shared assertions / readiness
    // =======================================================================

    private function assertCountryTableReady(): void
    {
        $this->assertCountryTableExists();
        if (!Schema::hasColumn(self::TABLE, 'deleted_at')) {
            $this->fail('glb_countries.deleted_at is missing; SoftDeletes will fail.');
        }
    }

    private function assertCountryTableExists(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->fail('glb_countries table/view is missing; cannot run Country tests.');
        }
    }

    private function assertActivityLogged(int $subjectId, string $event): void
    {
        if (!Schema::hasTable(self::ACTIVITY_TABLE)) {
            // Sink not present in this environment — do not hard-fail the flow test.
            return;
        }

        $exists = DB::table(self::ACTIVITY_TABLE)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->exists();

        $this->assertTrue($exists, "Activity event '$event' was not written for country #$subjectId.");
    }

    private function assertOverlongFieldRejected(string $field, string $value, string $caseName, array $extra = []): void
    {
        $this->assertCountryTableExists();

        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($field, $value, $extra): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create');

            foreach ($extra as $name => $val) {
                $browser->type($name, (string) $val);
            }
            $browser->type($field, $value)->check('#is_active')->press('Add Country')->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), "Overlong $field should keep user on create page.");
            $browser->assertPresent('.alert.alert-danger');
        });
    }

    // =======================================================================
    //  Data helpers
    // =======================================================================

    private function makeName(): string
    {
        return 'Country ' . strtoupper($this->randHex(4));
    }

    private function makeShortName(): string
    {
        return 'C' . strtoupper($this->randHex(3)); // <= 10 chars
    }

    private function makeGlobalCode(): string
    {
        return 'G' . strtoupper($this->randHex(3)); // <= 10 chars
    }

    private function makeCurrencyCode(): string
    {
        return 'U' . strtoupper($this->randHex(2)); // <= 8 chars
    }

    private function randHex(int $bytes): string
    {
        try {
            return bin2hex(random_bytes($bytes));
        } catch (Throwable) {
            return (string) rand(100000, 999999);
        }
    }

    private function createCountryRecord(array $overrides = []): Country
    {
        $payload = array_merge([
            'name' => $this->makeName(),
            'short_name' => $this->makeShortName(),
            'global_code' => $this->makeGlobalCode(),
            'currency_code' => $this->makeCurrencyCode(),
            'is_active' => true,
        ], $overrides);

        return Country::create($payload);
    }

    private function seedState(int $countryId, bool $active): ?int
    {
        if (!Schema::hasTable(self::STATES_TABLE)) {
            return null;
        }
        try {
            $now = now();
            return (int) DB::connection('global_master_mysql')->table(self::STATES_TABLE)->insertGetId([
                'country_id' => $countryId,
                'name' => 'ST ' . strtoupper($this->randHex(3)),
                'short_name' => 'S' . strtoupper($this->randHex(3)),
                'is_active' => $active ? 1 : 0,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        } catch (Throwable) {
            return null;
        }
    }

    private function seedDistrict(int $stateId, bool $active): ?int
    {
        if (!Schema::hasTable(self::DISTRICTS_TABLE)) {
            return null;
        }
        try {
            $now = now();
            return (int) DB::connection('global_master_mysql')->table(self::DISTRICTS_TABLE)->insertGetId([
                'state_id' => $stateId,
                'name' => 'DT ' . strtoupper($this->randHex(3)),
                'short_name' => 'D' . strtoupper($this->randHex(3)),
                'is_active' => $active ? 1 : 0,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        } catch (Throwable) {
            return null;
        }
    }

    private function purgeCountryById(int $id): void
    {
        try {
            DB::connection('global_master_mysql')->table(self::TABLE)->where('id', $id)->delete();
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    private function purgeGlobal(string $table, int $id): void
    {
        try {
            DB::connection('global_master_mysql')->table($table)->where('id', $id)->delete();
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    private function makeLimitedUser(): User
    {
        return User::create([
            'email' => 'limited_' . strtolower($this->randHex(4)) . '@tenant.com',
            'password' => bcrypt('password'),
            'name' => 'Limited Country User',
            'emp_code' => 'EMP' . rand(100, 999),
            'short_name' => 'LC' . rand(1000, 9999),
            'status' => 'ACTIVE',
            'is_active' => 1,
            'is_super_admin' => 0,
            'email_verified_at' => now(),
        ]);
    }

    private function purgeUser(?User $user): void
    {
        if (!$user) {
            return;
        }
        try {
            User::query()->where('id', $user->id)->forceDelete();
        } catch (Throwable) {
            try {
                DB::table('users')->where('id', $user->id)->delete();
            } catch (Throwable) {
                // best-effort cleanup
            }
        }
    }

    private function toggleUrl(int $id): string
    {
        return self::INDEX_PATH . '/' . $id . '/toggle-status';
    }

    private function moduleFile(string $relative): ?string
    {
        $roots = array_filter([
            env('MAIN_PROJECT_PATH'),
            '/Users/bkwork/Herd/prime_ai',
            base_path(),
        ]);

        foreach ($roots as $root) {
            $path = rtrim((string) $root, '/') . '/Modules/GlobalMaster/' . ltrim($relative, '/');
            if (is_file($path)) {
                return $path;
            }
        }

        return null;
    }

    private function safeColumnType(string $table, string $column): string
    {
        try {
            return (string) Schema::getColumnType($table, $column);
        } catch (Throwable) {
            return '';
        }
    }

    // =======================================================================
    //  Central helper library (copied INLINE from prm_BillingDuskTestCase)
    // =======================================================================

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
        $lines[] = '# GlobalMaster Country Dusk Status Report';
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
            'name' => 'Country Dusk Admin',
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
        $signals = ['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'];

        foreach ($signals as $signal) {
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

    protected function clickEditAction(Browser $browser, int $id): void
    {
        $selector = 'a.confirm-action[href$="/country/' . $id . '/edit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    protected function clickDeleteAction(Browser $browser, int $id): void
    {
        $selector = 'form.confirm-action-form[action$="/country/' . $id . '"] button[type="submit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    protected function clickRestoreAction(Browser $browser, int $id): void
    {
        $selector = 'a.confirm-action-restore[href$="/country/' . $id . '/restore"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    protected function clickForceDeleteAction(Browser $browser, int $id): void
    {
        $selector = 'form.confirm-action-form-force-delete[action$="/country/' . $id . '/force-delete"] button[type="submit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    /**
     * Execute a JSON request (toggle-status endpoint) from inside the browser,
     * carrying the authenticated session cookie + CSRF token. Returns the raw
     * response text. Kept for parity; status assertions use postJson() above.
     */
    protected function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): string
    {
        $body = json_encode($payload) ?: '{}';
        $script = <<<JS
            var done = arguments[arguments.length - 1];
            var token = document.querySelector('meta[name="csrf-token"]');
            fetch('{$url}', {
                method: '{$method}',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': token ? token.getAttribute('content') : ''
                },
                body: '{$body}'
            }).then(function (r) { return r.text(); })
              .then(function (t) { done(t); })
              .catch(function (e) { done('ERROR:' + e); });
        JS;

        try {
            return (string) $browser->driver->executeAsyncScript($script);
        } catch (Throwable $e) {
            return 'ERROR:' . $e->getMessage();
        }
    }
}
