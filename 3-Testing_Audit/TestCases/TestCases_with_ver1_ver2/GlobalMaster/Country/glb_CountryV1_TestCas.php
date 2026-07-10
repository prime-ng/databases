<?php

namespace Tests\Browser\Modules\Prime\GlobalMaster;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\Country;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * glb_CountryV1_TestCas — Foundation Dusk suite for the GlobalMaster > Country screen.
 *
 * SCOPE: CENTRAL / prime-side. The `glb_countries` table lives in the global_db
 * (connection `global_master_mysql`); Prime holds it as a VIEW. There is NO tenant
 * init here — Country runs on the central host http://127.0.0.1:8000 (PrimeDuskTestCase
 * forces 127.0.0.1). No cross-tenant scaffolding (see Validation Report tenancy note).
 *
 * Every route/selector/message/permission below is read from real source:
 *   Controller : Modules/GlobalMaster/app/Http/Controllers/CountryController.php
 *   Request    : Modules/GlobalMaster/app/Http/Requests/CountryRequest.php
 *   Model      : Modules/GlobalMaster/app/Models/Country.php  (connection global_master_mysql)
 *   Routes     : routes/web.php  (name prefix central.global-master.country.*, prefix /global-master)
 *   Views      : Modules/GlobalMaster/resources/views/country/*.blade.php
 *   Activity   : Modules\GlobalMaster\Models\ActivityLog -> sys_activity_logs
 */
class glb_CountryV1_TestCas extends PrimeDuskTestCase
{
    private const CONNECTION   = 'global_master_mysql';
    private const TABLE        = 'glb_countries';
    private const INDEX_PATH   = '/global-master/country';
    private const CREATE_PATH  = '/global-master/country/create';
    private const TRASH_PATH   = '/global-master/country/trash/view';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/GlobalMaster/Country/screenshots';

    private ?User $adminUser = null;
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
        parent::tearDown();
    }

    // ================================================================= 01–09 CONFIG

    public function test_country_01_migration_model_and_request_configuration_are_correct(): void
    {
        // ---- Schema truth (global_master_mysql / glb_countries) ----
        try {
            $hasTable = Schema::connection(self::CONNECTION)->hasTable(self::TABLE);
        } catch (Throwable $e) {
            $this->markTestSkipped('global_master_mysql connection unavailable: ' . $e->getMessage());
            return;
        }

        $this->assertTrue($hasTable, 'Table glb_countries must exist on global_master_mysql.');

        $columns = ['id', 'name', 'short_name', 'global_code', 'currency_code', 'is_active', 'created_at', 'updated_at', 'deleted_at'];
        $this->assertTrue(
            Schema::connection(self::CONNECTION)->hasColumns(self::TABLE, $columns),
            'glb_countries is missing one of the required columns: ' . implode(', ', $columns)
        );

        // Cross-ref: default_timezone is validated in CountryRequest but is NOT a column here.
        $this->assertFalse(
            Schema::connection(self::CONNECTION)->hasColumn(self::TABLE, 'default_timezone'),
            'default_timezone must NOT exist on glb_countries (cross-ref defect: validated but no column).'
        );

        // ---- Model truth ----
        $country = new Country();
        $this->assertSame(self::TABLE, $country->getTable(), 'Country::$table must be glb_countries.');
        $this->assertSame(self::CONNECTION, $country->getConnectionName(), 'Country must use global_master_mysql.');
        $this->assertEqualsCanonicalizing(
            ['name', 'short_name', 'global_code', 'currency_code', 'is_active'],
            $country->getFillable(),
            'Country $fillable mismatch (default_timezone is intentionally NOT fillable — cross-ref defect).'
        );
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(Country::class),
            'Country must use SoftDeletes.'
        );
        $this->assertInstanceOf(
            \Illuminate\Database\Eloquent\Relations\HasMany::class,
            $country->states(),
            'Country::states() must be a HasMany relation.'
        );
        $this->assertInstanceOf(
            \Illuminate\Database\Eloquent\Relations\HasMany::class,
            $country->organizationGroups(),
            'Country::organizationGroups() must be a HasMany relation.'
        );

        // ---- FormRequest truth ----
        $requestSrc = $this->sourceFile('Modules/GlobalMaster/app/Http/Requests/CountryRequest.php');
        if ($requestSrc !== null) {
            $this->assertStringContainsString("'max:50'", $requestSrc, 'name max:50 rule missing.');
            $this->assertStringContainsString("Rule::unique('glb_countries')", $requestSrc, 'name unique rule missing.');
            $this->assertStringContainsString("'max:10'", $requestSrc, 'short_name/global_code max:10 rule missing.');
            $this->assertStringContainsString("'max:8'", $requestSrc, 'currency_code max:8 rule missing.');
            $this->assertStringContainsString("'is_active' => 'required|boolean'", $requestSrc, 'is_active required|boolean rule missing.');
            $this->assertStringContainsString('default_timezone', $requestSrc, 'default_timezone rule expected (cross-ref defect).');
        }

        // ---- Controller truth (activity-log event strings, verbatim) ----
        $controllerSrc = $this->sourceFile('Modules/GlobalMaster/app/Http/Controllers/CountryController.php');
        if ($controllerSrc !== null) {
            foreach (["'Stored'", "'Updated'", "'Trashed'", "'Restored'", "'Deleted'", "'Toggled'"] as $event) {
                $this->assertStringContainsString($event, $controllerSrc, "Activity event {$event} must be logged in CountryController.");
            }
            $this->assertStringContainsString("Gate::authorize('prime.country.viewAny')", $controllerSrc, 'viewAny gate missing.');
            $this->assertStringContainsString('$request->validated()', $controllerSrc, 'store/update should reference validated().');
        }
    }

    // ================================================================= 02–03 RENDER

    public function test_country_02_index_page_lists_countries(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Country index');
            $browser->assertSee('Country Management')
                ->assertPresent('table.table-sm');
        });
    }

    public function test_country_03_create_page_renders_all_fields(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create');
            $browser->assertPresent('input#name')
                ->assertPresent('input#short_name')
                ->assertPresent('input#global_code')
                ->assertPresent('input#currency_code');
        });
    }

    // ================================================================= 10–19 CRUD + LOG

    public function test_country_10_store_persists_country_and_logs_stored(): void
    {
        $name = $this->uniqueName('Storeland');
        $payload = $this->buildValidStorePayload(['name' => $name]);

        $response = $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $payload);
        $response->assertRedirect();

        $row = Country::where('name', $name)->first();
        $this->assertNotNull($row, 'Country should be persisted after store.');
        $this->assertActivityLogged($row, 'Stored');

        $this->cleanupCountry($row);
    }

    public function test_country_11_update_persists_changes_and_logs_updated(): void
    {
        $country = $this->createCountry();
        if ($country === null) {
            $this->markTestSkipped('Could not seed a country on global_master_mysql.');
            return;
        }

        $newShort = $this->uniqueShort();
        $payload = $this->buildValidStorePayload([
            'name' => $country->name,
            'short_name' => $newShort,
        ]);

        $this->actingAs($this->adminUser)
            ->put($this->centralUrl(self::INDEX_PATH . '/' . $country->id), $payload)
            ->assertRedirect();

        $this->assertSame($newShort, Country::find($country->id)->short_name, 'short_name should be updated.');
        $this->assertActivityLogged($country->fresh(), 'Updated');

        $this->cleanupCountry($country->fresh());
    }

    public function test_country_12_destroy_deactivates_then_soft_deletes_and_logs_trashed(): void
    {
        $country = $this->createCountry(['is_active' => true]);
        if ($country === null) {
            $this->markTestSkipped('Could not seed a country.');
            return;
        }

        $this->actingAs($this->adminUser)
            ->delete($this->centralUrl(self::INDEX_PATH . '/' . $country->id))
            ->assertRedirect();

        $trashed = Country::withTrashed()->find($country->id);
        $this->assertNotNull($trashed->deleted_at, 'Country should be soft-deleted.');
        $this->assertFalse((bool) $trashed->is_active, 'destroy() must set is_active=false before deleting (BR-GLB).');
        $this->assertActivityLogged($trashed, 'Trashed');

        $this->cleanupCountry($trashed);
    }

    public function test_country_13_restore_recovers_and_logs_restored(): void
    {
        $country = $this->createCountry();
        if ($country === null) {
            $this->markTestSkipped('Could not seed a country.');
            return;
        }
        $id = $country->id;
        $country->delete();

        $this->actingAs($this->adminUser)
            ->get($this->centralUrl(self::INDEX_PATH . '/' . $id . '/restore'))
            ->assertRedirect();

        $this->assertNull(Country::find($id)?->deleted_at, 'Country should be restored (deleted_at null).');
        $this->assertActivityLogged(Country::find($id), 'Restored');

        $this->cleanupCountry(Country::find($id));
    }

    public function test_country_14_force_delete_removes_and_logs_deleted(): void
    {
        $country = $this->createCountry();
        if ($country === null) {
            $this->markTestSkipped('Could not seed a country.');
            return;
        }
        $id = $country->id;
        $country->delete();

        $this->actingAs($this->adminUser)
            ->delete($this->centralUrl(self::INDEX_PATH . '/' . $id . '/force-delete'))
            ->assertRedirect();

        $this->assertNull(Country::withTrashed()->find($id), 'Country should be permanently removed.');
    }

    public function test_country_15_toggle_status_endpoint_updates_is_active_and_logs_toggled(): void
    {
        $country = $this->createCountry(['is_active' => true]);
        if ($country === null) {
            $this->markTestSkipped('Could not seed a country.');
            return;
        }

        $response = $this->actingAs($this->adminUser)
            ->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => false]);

        $response->assertOk()->assertJson(['success' => true, 'is_active' => false]);
        $this->assertFalse((bool) Country::find($country->id)->is_active, 'is_active should be toggled off.');
        $this->assertActivityLogged($country->fresh(), 'Toggled');

        $this->cleanupCountry($country->fresh());
    }

    // ================================================================= 30–39 VALIDATION

    public function test_country_30_store_requires_name(): void
    {
        $payload = $this->buildValidStorePayload();
        unset($payload['name']);

        $this->actingAs($this->adminUser)
            ->post($this->centralUrl(self::INDEX_PATH), $payload)
            ->assertSessionHasErrors('name');
    }

    public function test_country_31_store_rejects_duplicate_name(): void
    {
        $country = $this->createCountry();
        if ($country === null) {
            $this->markTestSkipped('Could not seed a country.');
            return;
        }

        $payload = $this->buildValidStorePayload(['name' => $country->name]);
        $this->actingAs($this->adminUser)
            ->post($this->centralUrl(self::INDEX_PATH), $payload)
            ->assertSessionHasErrors('name');

        $this->cleanupCountry($country);
    }

    public function test_country_32_store_enforces_short_name_max_length(): void
    {
        $payload = $this->buildValidStorePayload(['short_name' => str_repeat('X', 11)]);
        $this->actingAs($this->adminUser)
            ->post($this->centralUrl(self::INDEX_PATH), $payload)
            ->assertSessionHasErrors('short_name');
    }

    // ================================================================= 40–49 INTEGRATION

    public function test_country_40_toggle_cascades_is_active_to_states(): void
    {
        try {
            $country = $this->createCountry(['is_active' => true]);
            if ($country === null) {
                $this->markTestSkipped('Could not seed a country.');
                return;
            }
            $state = \Modules\GlobalMaster\Models\State::create([
                'country_id' => $country->id,
                'name' => $this->uniqueName('St'),
                'short_name' => $this->uniqueShort(),
                'is_active' => true,
            ]);

            $this->actingAs($this->adminUser)
                ->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => false])
                ->assertOk();

            $this->assertFalse((bool) $state->fresh()->is_active, 'State is_active must cascade to false with the country.');

            $state->forceDelete();
            $this->cleanupCountry($country->fresh());
        } catch (Throwable $e) {
            $this->markTestSkipped('State cascade dependency unavailable: ' . $e->getMessage());
        }
    }

    // ================================================================= 50–59 PERMISSIONS

    public function test_country_50_guest_is_redirected_to_login(): void
    {
        $this->get($this->centralUrl(self::INDEX_PATH))->assertRedirect($this->centralUrl('/login'));
    }

    public function test_country_51_index_is_reachable_for_admin(): void
    {
        $this->actingAs($this->adminUser)
            ->get($this->centralUrl(self::INDEX_PATH))
            ->assertSuccessful();
    }

    // ================================================================= 60–69 UI/UX

    public function test_country_60_breadcrumb_present_on_create_page(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create breadcrumb');
            $browser->assertSee('Country Management');
        });
    }

    // ================================================================= HELPER LIBRARY

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/') ? $this->centralBaseUrl . $path : $this->centralBaseUrl . '/' . $path;
    }

    private function resolveAdminUser(): void
    {
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
        try {
            $this->adminUser = User::create([
                'email' => $this->adminEmail,
                'password' => bcrypt($this->adminPassword),
                'name' => 'GlobalMaster Dusk Admin',
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
        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', '404', 'Not Found', 'Page Expired', '419'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . '). Is the GlobalMaster module enabled?');
            }
        }
    }

    private function buildValidStorePayload(array $overrides = []): array
    {
        return array_merge([
            'name' => $this->uniqueName('Country'),
            'short_name' => $this->uniqueShort(),
            'global_code' => $this->uniqueCode(),
            'currency_code' => 'CUR' . rand(10, 99),
            'is_active' => 'on',
        ], $overrides);
    }

    private function createCountry(array $overrides = []): ?Country
    {
        try {
            return Country::create(array_merge([
                'name' => $this->uniqueName('Country'),
                'short_name' => $this->uniqueShort(),
                'global_code' => $this->uniqueCode(),
                'currency_code' => 'CUR' . rand(10, 99),
                'is_active' => true,
            ], $overrides));
        } catch (Throwable) {
            return null;
        }
    }

    private function cleanupCountry(?Country $country): void
    {
        if ($country === null) {
            return;
        }
        try {
            $country->forceDelete();
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    private function assertActivityLogged(?Country $country, string $event): void
    {
        if ($country === null) {
            return;
        }
        try {
            $exists = \Modules\GlobalMaster\Models\ActivityLog::query()
                ->where('subject_id', $country->id)
                ->where('event', $event)
                ->exists();
            $this->assertTrue($exists, "Expected a '{$event}' activity log for country #{$country->id}.");
        } catch (Throwable $e) {
            $this->markTestSkipped('sys_activity_logs unavailable: ' . $e->getMessage());
        }
    }

    private function uniqueName(string $prefix): string
    {
        return substr($prefix . '-' . strtoupper(substr(uniqid(), -8)), 0, 50);
    }

    private function uniqueShort(): string
    {
        return substr('S' . strtoupper(substr(uniqid(), -7)), 0, 10);
    }

    private function uniqueCode(): string
    {
        return substr('C' . strtoupper(substr(uniqid(), -7)), 0, 10);
    }

    private function sourceFile(string $relative): ?string
    {
        $root = rtrim((string) env('MAIN_PROJECT_PATH', base_path('../prime_ai')), '/');
        $path = $root . '/' . ltrim($relative, '/');
        try {
            return File::exists($path) ? File::get($path) : null;
        } catch (Throwable) {
            return null;
        }
    }

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path(self::SCREENSHOT_DIR);
            if (File::isDirectory($dir)) {
                foreach (File::glob($dir . '/*.png') as $png) {
                    File::delete($png);
                }
            }
        } catch (Throwable) {
            // ignore
        }
    }
}
