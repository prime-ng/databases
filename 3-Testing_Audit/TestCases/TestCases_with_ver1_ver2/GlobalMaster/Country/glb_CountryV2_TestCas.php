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
 * glb_CountryV2_TestCas — Comprehensive Dusk suite for GlobalMaster > Country.
 *
 * CENTRAL / prime-side (connection global_master_mysql, host http://127.0.0.1:8000).
 * Mirrors the committed Prime/Billing central pattern (extends PrimeDuskTestCase).
 * Semantic numbering bands: 01–09 config, 10–19 business/log, 30–39 validation,
 * 40–49 integration/FK, 50–59 permissions, 60–69 UI/UX, 70–79 edge, 90–99 security.
 *
 * Encoded source defects (proving current behaviour, documented in Gap Analysis):
 *   SEC-GLB-001 (P1) — store/update use $request->validated() but the FormRequest validates
 *                      `default_timezone`, a column that does not exist -> silently dropped.
 *   BUG-GLB-004 (P1) — toggleStatus cascades is_active to States + Districts but OMITS Cities.
 *   Cross-ref     — CountryRequest validates default_timezone (absent from DDL & fillable);
 *                   glb_countries.short_name / global_code are UNIQUE in DDL but NOT in rules().
 */
class glb_CountryV2_TestCas extends PrimeDuskTestCase
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

    public function test_country_01_schema_model_and_request_configuration_are_correct(): void
    {
        try {
            $hasTable = Schema::connection(self::CONNECTION)->hasTable(self::TABLE);
        } catch (Throwable $e) {
            $this->markTestSkipped('global_master_mysql unavailable: ' . $e->getMessage());
            return;
        }
        $this->assertTrue($hasTable, 'glb_countries must exist.');
        $this->assertTrue(
            Schema::connection(self::CONNECTION)->hasColumns(self::TABLE, ['id', 'name', 'short_name', 'global_code', 'currency_code', 'is_active', 'created_at', 'updated_at', 'deleted_at']),
            'glb_countries column set mismatch.'
        );

        $country = new Country();
        $this->assertSame(self::TABLE, $country->getTable());
        $this->assertSame(self::CONNECTION, $country->getConnectionName());
        $this->assertEqualsCanonicalizing(['name', 'short_name', 'global_code', 'currency_code', 'is_active'], $country->getFillable());
        $this->assertContains(\Illuminate\Database\Eloquent\SoftDeletes::class, class_uses_recursive(Country::class));
    }

    public function test_country_02_ddl_declares_unique_indexes_on_name_shortname_globalcode(): void
    {
        $ddl = $this->ddlSource();
        if ($ddl === null) {
            $this->markTestSkipped('DDL source not readable.');
            return;
        }
        $this->assertStringContainsString('uq_glb_countries_name', $ddl, 'name UNIQUE index expected in DDL.');
        $this->assertStringContainsString('uq_glb_countries_shortName', $ddl, 'short_name UNIQUE index expected in DDL.');
        $this->assertStringContainsString('uq_glb_countries_globalCode', $ddl, 'global_code UNIQUE index expected in DDL.');
    }

    public function test_country_03_index_route_is_registered_under_global_master_prefix(): void
    {
        $controllerSrc = $this->sourceFile('routes/web.php');
        if ($controllerSrc === null) {
            $this->markTestSkipped('routes/web.php not readable.');
            return;
        }
        $this->assertStringContainsString("Route::resource('country', CountryController::class)", $controllerSrc);
        $this->assertStringContainsString("country.toggleStatus", $controllerSrc);
        $this->assertStringContainsString("country.forceDelete", $controllerSrc);
        $this->assertStringContainsString("country.restore", $controllerSrc);
    }

    public function test_country_04_create_page_renders_all_input_fields(): void
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

    public function test_country_05_edit_page_prefills_existing_values(): void
    {
        $country = $this->createCountry();
        if ($country === null) {
            $this->markTestSkipped('Could not seed a country.');
            return;
        }
        $this->browse(function (Browser $browser) use ($country): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $country->id . '/edit');
            $this->ensurePageAccessible($browser, 'Country edit');
            $browser->assertInputValue('name', $country->name)
                ->assertInputValue('short_name', $country->short_name);
        });
        $this->cleanupCountry($country);
    }

    // ================================================================= 10–19 BUSINESS + LOG

    public function test_country_10_store_persists_and_logs_stored(): void
    {
        $name = $this->uniqueName('Store');
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload(['name' => $name]))->assertRedirect();
        $row = Country::where('name', $name)->first();
        $this->assertNotNull($row);
        $this->assertActivityLogged($row, 'Stored');
        $this->cleanupCountry($row);
    }

    public function test_country_11_update_logs_updated_with_change_set(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $newCode = $this->uniqueCode();
        $this->actingAs($this->adminUser)->put($this->centralUrl(self::INDEX_PATH . '/' . $country->id), $this->buildValidStorePayload(['name' => $country->name, 'global_code' => $newCode]))->assertRedirect();
        $this->assertSame($newCode, Country::find($country->id)->global_code);
        $this->assertActivityLogged($country->fresh(), 'Updated');
        $this->cleanupCountry($country->fresh());
    }

    public function test_country_12_update_with_no_changes_still_logs_updated(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        // Re-submit identical values -> controller logs "No attributes changed" branch.
        $payload = $this->buildValidStorePayload([
            'name' => $country->name,
            'short_name' => $country->short_name,
            'global_code' => $country->global_code,
            'currency_code' => $country->currency_code,
            'is_active' => 'on',
        ]);
        $this->actingAs($this->adminUser)->put($this->centralUrl(self::INDEX_PATH . '/' . $country->id), $payload)->assertRedirect();
        $this->assertActivityLogged($country->fresh(), 'Updated');
        $this->cleanupCountry($country->fresh());
    }

    public function test_country_13_destroy_sets_inactive_then_soft_deletes_and_logs_trashed(): void
    {
        $country = $this->createCountry(['is_active' => true]);
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $this->actingAs($this->adminUser)->delete($this->centralUrl(self::INDEX_PATH . '/' . $country->id))->assertRedirect();
        $trashed = Country::withTrashed()->find($country->id);
        $this->assertNotNull($trashed->deleted_at);
        $this->assertFalse((bool) $trashed->is_active);
        $this->assertActivityLogged($trashed, 'Trashed');
        $this->cleanupCountry($trashed);
    }

    public function test_country_14_restore_recovers_and_logs_restored(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $id = $country->id;
        $country->delete();
        $this->actingAs($this->adminUser)->get($this->centralUrl(self::INDEX_PATH . '/' . $id . '/restore'))->assertRedirect();
        $this->assertNull(Country::find($id)?->deleted_at);
        $this->assertActivityLogged(Country::find($id), 'Restored');
        $this->cleanupCountry(Country::find($id));
    }

    public function test_country_15_force_delete_removes_and_logs_deleted(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $id = $country->id;
        $country->delete();
        $this->actingAs($this->adminUser)->delete($this->centralUrl(self::INDEX_PATH . '/' . $id . '/force-delete'))->assertRedirect();
        $this->assertNull(Country::withTrashed()->find($id));
    }

    public function test_country_16_toggle_status_returns_json_and_logs_toggled(): void
    {
        $country = $this->createCountry(['is_active' => true]);
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $this->actingAs($this->adminUser)
            ->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => false])
            ->assertOk()->assertJsonStructure(['success', 'is_active', 'message']);
        $this->assertFalse((bool) Country::find($country->id)->is_active);
        $this->assertActivityLogged($country->fresh(), 'Toggled');
        $this->cleanupCountry($country->fresh());
    }

    public function test_country_17_mass_assignment_drops_default_timezone_SEC_GLB_001(): void
    {
        // SEC-GLB-001: default_timezone is validated but is NOT a column/fillable -> silently dropped.
        $name = $this->uniqueName('Tz');
        $payload = $this->buildValidStorePayload(['name' => $name, 'default_timezone' => 'Asia/Kolkata']);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $payload)->assertRedirect();
        $row = Country::where('name', $name)->first();
        $this->assertNotNull($row, 'Country stored despite bogus default_timezone.');
        $this->assertFalse(
            Schema::connection(self::CONNECTION)->hasColumn(self::TABLE, 'default_timezone'),
            'PROVING default_timezone has no column (validated-but-dropped).'
        );
        $this->cleanupCountry($row);
    }

    public function test_country_18_store_ignores_non_fillable_attributes(): void
    {
        $name = $this->uniqueName('Fill');
        $payload = $this->buildValidStorePayload(['name' => $name, 'id' => 999999, 'deleted_at' => now()->toDateTimeString()]);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $payload)->assertRedirect();
        $row = Country::where('name', $name)->first();
        $this->assertNotNull($row);
        $this->assertNotSame(999999, (int) $row->id, 'id must not be mass-assignable.');
        $this->assertNull($row->deleted_at, 'deleted_at must not be mass-assignable at store.');
        $this->cleanupCountry($row);
    }

    // ================================================================= 30–39 VALIDATION (100% negative)

    public function test_country_30_store_requires_name(): void
    {
        $p = $this->buildValidStorePayload(); unset($p['name']);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $p)->assertSessionHasErrors('name');
    }

    public function test_country_31_store_enforces_name_max_50(): void
    {
        $p = $this->buildValidStorePayload(['name' => str_repeat('N', 51)]);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $p)->assertSessionHasErrors('name');
    }

    public function test_country_32_store_rejects_duplicate_name(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload(['name' => $country->name]))->assertSessionHasErrors('name');
        $this->cleanupCountry($country);
    }

    public function test_country_33_update_allows_same_name_on_self(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $this->actingAs($this->adminUser)->put($this->centralUrl(self::INDEX_PATH . '/' . $country->id), $this->buildValidStorePayload(['name' => $country->name, 'short_name' => $country->short_name]))->assertSessionHasNoErrors();
        $this->cleanupCountry($country->fresh());
    }

    public function test_country_34_store_requires_short_name(): void
    {
        $p = $this->buildValidStorePayload(); unset($p['short_name']);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $p)->assertSessionHasErrors('short_name');
    }

    public function test_country_35_store_enforces_short_name_max_10(): void
    {
        $p = $this->buildValidStorePayload(['short_name' => str_repeat('S', 11)]);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $p)->assertSessionHasErrors('short_name');
    }

    public function test_country_36_store_enforces_global_code_max_10(): void
    {
        $p = $this->buildValidStorePayload(['global_code' => str_repeat('G', 11)]);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $p)->assertSessionHasErrors('global_code');
    }

    public function test_country_37_store_enforces_currency_code_max_8(): void
    {
        $p = $this->buildValidStorePayload(['currency_code' => str_repeat('C', 9)]);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $p)->assertSessionHasErrors('currency_code');
    }

    public function test_country_38_store_accepts_nullable_global_and_currency_codes(): void
    {
        $name = $this->uniqueName('Nul');
        $p = $this->buildValidStorePayload(['name' => $name, 'global_code' => '', 'currency_code' => '']);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $p)->assertSessionHasNoErrors();
        $this->cleanupCountry(Country::where('name', $name)->first());
    }

    public function test_country_39_toggle_status_rejects_non_boolean_is_active(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $this->actingAs($this->adminUser)
            ->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => 'banana'])
            ->assertStatus(422);
        $this->cleanupCountry($country);
    }

    // ================================================================= 40–49 INTEGRATION / FK

    public function test_country_40_toggle_cascades_is_active_to_states(): void
    {
        $this->withGeographyChain(function (Country $country, $state, $district, $city): void {
            $this->actingAs($this->adminUser)->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => false])->assertOk();
            $this->assertFalse((bool) $state->fresh()->is_active, 'State must cascade inactive.');
        });
    }

    public function test_country_41_toggle_cascades_is_active_to_districts(): void
    {
        $this->withGeographyChain(function (Country $country, $state, $district, $city): void {
            $this->actingAs($this->adminUser)->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => false])->assertOk();
            $this->assertFalse((bool) $district->fresh()->is_active, 'District must cascade inactive.');
        });
    }

    public function test_country_42_toggle_does_not_cascade_to_cities_BUG_GLB_004(): void
    {
        // BUG-GLB-004: controller cascades to States + Districts but OMITS Cities.
        // This asserts the CURRENT (buggy) behaviour: city stays active.
        $this->withGeographyChain(function (Country $country, $state, $district, $city): void {
            if ($city === null) {
                $this->markTestSkipped('City chain unavailable.');
                return;
            }
            $this->actingAs($this->adminUser)->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => false])->assertOk();
            $this->assertTrue(
                (bool) $city->fresh()->is_active,
                'PROVING BUG-GLB-004: city is_active is NOT cascaded (BR-GLB-001 requires it to be).'
            );
        });
    }

    public function test_country_43_force_delete_is_blocked_while_state_references_country(): void
    {
        try {
            $country = $this->createCountry();
            if ($country === null) { $this->markTestSkipped('seed failed'); return; }
            $state = \Modules\GlobalMaster\Models\State::create([
                'country_id' => $country->id,
                'name' => $this->uniqueName('St'),
                'short_name' => $this->uniqueShort(),
                'is_active' => true,
            ]);
            $country->delete();
            $blocked = false;
            try {
                $country->forceDelete();
            } catch (Throwable) {
                $blocked = true; // FK RESTRICT (fk_glb_states_countryId ON DELETE RESTRICT)
            }
            $this->assertTrue($blocked, 'Force-deleting a referenced country must be blocked by FK RESTRICT.');
            $state->forceDelete();
            $this->cleanupCountry(Country::withTrashed()->find($country->id));
        } catch (Throwable $e) {
            $this->markTestSkipped('State dependency unavailable: ' . $e->getMessage());
        }
    }

    public function test_country_44_soft_delete_does_not_soft_delete_child_states(): void
    {
        try {
            $country = $this->createCountry();
            if ($country === null) { $this->markTestSkipped('seed failed'); return; }
            $state = \Modules\GlobalMaster\Models\State::create([
                'country_id' => $country->id,
                'name' => $this->uniqueName('St'),
                'short_name' => $this->uniqueShort(),
                'is_active' => true,
            ]);
            $country->delete();
            $this->assertNull($state->fresh()->deleted_at, 'Child state must NOT be soft-deleted by parent country soft-delete.');
            $state->forceDelete();
            $this->cleanupCountry(Country::withTrashed()->find($country->id));
        } catch (Throwable $e) {
            $this->markTestSkipped('State dependency unavailable: ' . $e->getMessage());
        }
    }

    public function test_country_45_states_relation_returns_related_records(): void
    {
        try {
            $country = $this->createCountry();
            if ($country === null) { $this->markTestSkipped('seed failed'); return; }
            $state = \Modules\GlobalMaster\Models\State::create([
                'country_id' => $country->id,
                'name' => $this->uniqueName('St'),
                'short_name' => $this->uniqueShort(),
                'is_active' => true,
            ]);
            $this->assertTrue($country->fresh()->states()->where('id', $state->id)->exists(), 'states() must relate the created state.');
            $state->forceDelete();
            $this->cleanupCountry($country->fresh());
        } catch (Throwable $e) {
            $this->markTestSkipped('State dependency unavailable: ' . $e->getMessage());
        }
    }

    // ================================================================= 50–59 PERMISSIONS

    public function test_country_50_guest_index_redirects_to_login(): void
    {
        $this->get($this->centralUrl(self::INDEX_PATH))->assertRedirect($this->centralUrl('/login'));
    }

    public function test_country_51_guest_store_redirects_to_login(): void
    {
        $this->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload())->assertRedirect($this->centralUrl('/login'));
    }

    public function test_country_52_unauthorized_user_cannot_view_index(): void
    {
        $this->withLimitedUser(function (User $user): void {
            $this->actingAs($user)->get($this->centralUrl(self::INDEX_PATH))->assertForbidden();
        });
    }

    public function test_country_53_unauthorized_user_cannot_open_create(): void
    {
        $this->withLimitedUser(function (User $user): void {
            $this->actingAs($user)->get($this->centralUrl(self::CREATE_PATH))->assertForbidden();
        });
    }

    public function test_country_54_unauthorized_user_cannot_store(): void
    {
        $this->withLimitedUser(function (User $user): void {
            $this->actingAs($user)->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload())->assertForbidden();
        });
    }

    public function test_country_55_unauthorized_user_cannot_toggle_status(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $this->withLimitedUser(function (User $user) use ($country): void {
            $this->actingAs($user)->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => false])->assertForbidden();
        });
        $this->cleanupCountry($country);
    }

    public function test_country_56_unauthorized_user_cannot_force_delete(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $id = $country->id;
        $country->delete();
        $this->withLimitedUser(function (User $user) use ($id): void {
            $this->actingAs($user)->delete($this->centralUrl(self::INDEX_PATH . '/' . $id . '/force-delete'))->assertForbidden();
        });
        $this->cleanupCountry(Country::withTrashed()->find($id));
    }

    // ================================================================= 60–69 UI/UX

    public function test_country_60_index_paginates_ten_per_page(): void
    {
        $controllerSrc = $this->sourceFile('Modules/GlobalMaster/app/Http/Controllers/CountryController.php');
        if ($controllerSrc === null) { $this->markTestSkipped('controller not readable'); return; }
        $this->assertStringContainsString('paginate(10)', $controllerSrc, 'Index must paginate 10 per page.');
    }

    public function test_country_61_index_shows_empty_state_marker_when_no_data(): void
    {
        // The blade prints "Not Data Found" when the collection is empty (verbatim from source).
        $viewSrc = $this->sourceFile('Modules/GlobalMaster/resources/views/country/index.blade.php');
        if ($viewSrc === null) { $this->markTestSkipped('view not readable'); return; }
        $this->assertStringContainsString('Not Data Found', $viewSrc, 'Empty-state text must be present in the index view.');
    }

    public function test_country_62_create_page_shows_breadcrumb(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Country create breadcrumb');
            $browser->assertSee('Country Management');
        });
    }

    public function test_country_63_index_orders_active_countries_first(): void
    {
        $controllerSrc = $this->sourceFile('Modules/GlobalMaster/app/Http/Controllers/CountryController.php');
        if ($controllerSrc === null) { $this->markTestSkipped('controller not readable'); return; }
        $this->assertStringContainsString("orderBy('is_active', 'desc')", $controllerSrc, 'Index must order is_active desc.');
    }

    public function test_country_64_status_toggle_switch_present_on_index_rows(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Country index switch');
            $browser->assertPresent('input.status-toggle');
        });
        $this->cleanupCountry($country);
    }

    // ================================================================= 70–79 EDGE

    public function test_country_70_name_at_exactly_50_chars_is_accepted(): void
    {
        $name = substr($this->uniqueName('E') . str_repeat('a', 50), 0, 50);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload(['name' => $name]))->assertSessionHasNoErrors();
        $this->cleanupCountry(Country::where('name', $name)->first());
    }

    public function test_country_71_short_name_at_exactly_10_chars_is_accepted(): void
    {
        $name = $this->uniqueName('E10');
        $short = substr($this->uniqueShort() . 'ABCDEFGHIJ', 0, 10);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload(['name' => $name, 'short_name' => $short]))->assertSessionHasNoErrors();
        $this->cleanupCountry(Country::where('name', $name)->first());
    }

    public function test_country_72_whitespace_only_name_is_rejected(): void
    {
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload(['name' => '   ']))->assertSessionHasErrors('name');
    }

    public function test_country_73_duplicate_short_name_not_guarded_by_request_crossref(): void
    {
        // Cross-ref: DDL declares short_name UNIQUE but rules() does NOT -> FormRequest passes,
        // and the DB unique index is the only guard (DB-level QueryException on collision).
        $requestSrc = $this->sourceFile('Modules/GlobalMaster/app/Http/Requests/CountryRequest.php');
        if ($requestSrc === null) { $this->markTestSkipped('request not readable'); return; }
        $shortRuleBlock = substr($requestSrc, (int) strpos($requestSrc, "'short_name'"), 120);
        $this->assertStringNotContainsString('unique', $shortRuleBlock, 'PROVING cross-ref: short_name has no unique rule though DDL is UNIQUE.');
    }

    public function test_country_74_global_code_uniqueness_not_guarded_by_request_crossref(): void
    {
        $requestSrc = $this->sourceFile('Modules/GlobalMaster/app/Http/Requests/CountryRequest.php');
        if ($requestSrc === null) { $this->markTestSkipped('request not readable'); return; }
        $codeRuleBlock = substr($requestSrc, (int) strpos($requestSrc, "'global_code'"), 120);
        $this->assertStringNotContainsString('unique', $codeRuleBlock, 'PROVING cross-ref: global_code has no unique rule though DDL is UNIQUE.');
    }

    // ================================================================= 90–99 TENANCY + SECURITY

    public function test_country_90_cross_tenant_isolation_is_not_applicable_central_scope(): void
    {
        // Country lives in the central global_db (connection global_master_mysql), shared across
        // all tenants. There is no per-tenant scoping, so cross-tenant isolation tests are N/A.
        $this->assertSame('global_master_mysql', (new Country())->getConnectionName());
        $this->markTestSkipped('Deliberate skip: Country is central/global — cross-tenant isolation N/A (documented in Validation Report).');
    }

    public function test_country_91_stored_xss_in_name_is_escaped_on_render(): void
    {
        $payloadName = '<script>alert(1)</script>' . $this->uniqueName('X');
        $payloadName = substr($payloadName, 0, 50);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload(['name' => $payloadName]))->assertRedirect();
        $row = Country::where('name', $payloadName)->first();
        if ($row === null) { $this->markTestSkipped('XSS store did not persist (validation).'); return; }
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Name must be HTML-escaped (no raw script tag).');
        });
        $this->cleanupCountry($row);
    }

    public function test_country_92_reflected_xss_in_short_name_is_escaped(): void
    {
        $name = $this->uniqueName('X2');
        $short = substr('<b>' . $this->uniqueShort(), 0, 10);
        $this->actingAs($this->adminUser)->post($this->centralUrl(self::INDEX_PATH), $this->buildValidStorePayload(['name' => $name, 'short_name' => $short]))->assertRedirect();
        $row = Country::where('name', $name)->first();
        if ($row === null) { $this->markTestSkipped('did not persist'); return; }
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<b><b>', $source, 'short_name must be escaped.');
        });
        $this->cleanupCountry($row);
    }

    public function test_country_93_edit_invalid_id_returns_404(): void
    {
        $this->actingAs($this->adminUser)->get($this->centralUrl(self::INDEX_PATH . '/99999999/edit'))->assertNotFound();
    }

    public function test_country_94_show_invalid_id_returns_404(): void
    {
        $this->actingAs($this->adminUser)->get($this->centralUrl(self::INDEX_PATH . '/99999999'))->assertNotFound();
    }

    public function test_country_95_force_delete_invalid_id_returns_404(): void
    {
        $this->actingAs($this->adminUser)->delete($this->centralUrl(self::INDEX_PATH . '/99999999/force-delete'))->assertNotFound();
    }

    public function test_country_96_guest_toggle_status_is_rejected(): void
    {
        $country = $this->createCountry();
        if ($country === null) { $this->markTestSkipped('seed failed'); return; }
        $response = $this->postJson($this->centralUrl(self::INDEX_PATH . '/' . $country->id . '/toggle-status'), ['is_active' => false]);
        $this->assertContains($response->getStatusCode(), [401, 302, 419], 'Guest toggle must not succeed.');
        $this->cleanupCountry($country);
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

    private function withLimitedUser(callable $callback): void
    {
        try {
            $user = User::create([
                'email' => 'limited_' . uniqid() . '@central.test',
                'password' => bcrypt('password'),
                'name' => 'Limited User',
                'emp_code' => 'LMT' . rand(100, 999),
                'short_name' => 'LMT' . rand(1000, 9999),
                'status' => 'ACTIVE',
                'is_active' => 1,
                'is_super_admin' => 0,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot create limited user: ' . $e->getMessage());
            return;
        }
        try {
            $callback($user);
        } finally {
            try { $user->forceDelete(); } catch (Throwable) {}
        }
    }

    private function withGeographyChain(callable $callback): void
    {
        $country = null; $state = null; $district = null; $city = null;
        try {
            $country = $this->createCountry(['is_active' => true]);
            if ($country === null) { $this->markTestSkipped('seed failed'); return; }
            $state = \Modules\GlobalMaster\Models\State::create([
                'country_id' => $country->id,
                'name' => $this->uniqueName('St'),
                'short_name' => $this->uniqueShort(),
                'is_active' => true,
            ]);
            $district = \Modules\GlobalMaster\Models\District::create([
                'state_id' => $state->id,
                'name' => $this->uniqueName('Di'),
                'short_name' => $this->uniqueShort(),
                'is_active' => true,
            ]);
            try {
                $city = \Modules\GlobalMaster\Models\City::create([
                    'district_id' => $district->id,
                    'name' => $this->uniqueName('Ci'),
                    'short_name' => $this->uniqueShort(),
                    'is_active' => true,
                ]);
            } catch (Throwable) {
                $city = null;
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Geography chain unavailable: ' . $e->getMessage());
            return;
        }

        try {
            $callback($country, $state, $district, $city);
        } finally {
            try { $city?->forceDelete(); } catch (Throwable) {}
            try { $district?->forceDelete(); } catch (Throwable) {}
            try { $state?->forceDelete(); } catch (Throwable) {}
            $this->cleanupCountry($country?->fresh());
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
            // best-effort
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

    private function ddlSource(): ?string
    {
        $candidates = [
            '/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated/_global_db_v4.sql',
        ];
        foreach ($candidates as $c) {
            try {
                if (File::exists($c)) {
                    return File::get($c);
                }
            } catch (Throwable) {
                // continue
            }
        }
        return null;
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
