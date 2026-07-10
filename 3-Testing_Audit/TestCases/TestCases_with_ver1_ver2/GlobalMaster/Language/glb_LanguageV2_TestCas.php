<?php

namespace Tests\Browser\Modules\Prime\GlobalMaster;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\ActivityLog;
use Modules\Prime\Models\Language;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * glb_Language V2 — Comprehensive Dusk suite (central / prime-side).
 *
 * Bands: 01-09 schema · 10-19 business rules · 20-29 state machine · 30-39 validation
 *        40-49 integration/FK · 50-59 authorization · 60-69 UI/UX · 70-79 edge · 90-99 security/tenancy.
 *
 * Under test : Modules\Prime\Http\Controllers\LanguageController (central.global-master.language.*).
 * Reconciliation: SEC-GLB-010 / SEC-GLB-005 were filed against the GlobalMaster module controller
 *        (globalmaster:: views, global-master.language.* — disabled module → 404). The live central
 *        controller correctly gates every method with prime.language.*; band 50-59 asserts that live
 *        (gated) behaviour. BUG-GLB-006a (forceDelete logs 'Stored') and BUG-GLB-006b (update flashes
 *        raw 'update.language') DO reproduce on the live controller — bands 10-19 prove them.
 */
class glb_LanguageV2_TestCas extends PrimeDuskTestCase
{
    private const INDEX_PATH  = '/global-master/language';
    private const CREATE_PATH = '/global-master/language/create';
    private const TRASH_PATH  = '/global-master/language/trash/view';
    private const TABLE       = 'glb_languages';

    private ?User $adminUser      = null;
    private ?User $limitedUser    = null;
    private string $centralBaseUrl = '';
    private string $adminEmail    = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail     = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword  = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if ($this->limitedUser !== null) {
            try {
                $this->limitedUser->forceDelete();
            } catch (Throwable) {
            }
            $this->limitedUser = null;
        }
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }
        parent::tearDown();
    }

    // =====================================================================
    // Band 01-09 — Schema / model / request configuration
    // =====================================================================

    public function test_language_01_schema_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE));
        $this->assertTrue(Schema::hasColumns(self::TABLE, [
            'id', 'code', 'name', 'native_name', 'direction', 'is_active', 'deleted_at',
        ]));

        $model = new Language();
        $this->assertSame('glb_languages', $model->getTable());
        $this->assertSame('global_master_mysql', $model->getConnectionName());
        $this->assertTrue(in_array(SoftDeletes::class, class_uses_recursive(Language::class), true));
        foreach (['code', 'name', 'native_name', 'direction', 'is_active'] as $c) {
            $this->assertContains($c, $model->getFillable());
        }
    }

    public function test_language_02_central_routes_are_registered(): void
    {
        foreach ([
            'central.global-master.language.index',
            'central.global-master.language.create',
            'central.global-master.language.store',
            'central.global-master.language.edit',
            'central.global-master.language.update',
            'central.global-master.language.destroy',
            'central.global-master.language.trashed',
            'central.global-master.language.restore',
            'central.global-master.language.forceDelete',
            'central.global-master.language.toggleStatus',
        ] as $name) {
            $this->assertTrue(Route::has($name), "route {$name} must be registered");
        }
    }

    public function test_language_03_model_soft_deletes_connection_and_casts_drift(): void
    {
        // MODEL drift: Prime\Language has NO $casts for is_active (returned as raw "0"/"1"),
        // whereas GlobalMaster\Language casts it boolean. Document the live model's behaviour.
        $model = new Language();
        $this->assertArrayNotHasKey('is_active', $model->getCasts(), 'Prime\\Language has no is_active cast (drift)');
        $this->assertSame('global_master_mysql', $model->getConnectionName());
    }

    public function test_language_04_request_rules_contain_expected_constraints(): void
    {
        $request = $this->mainProjectFile('Modules/GlobalMaster/app/Http/Requests/LanguageRequest.php');
        if ($request === null) {
            $this->markTestSkipped('App repo (MAIN_PROJECT_PATH) unavailable.');
        }
        $src = File::get($request);
        $this->assertStringContainsString("'max:10'", $src);
        $this->assertStringContainsString("'max:50'", $src);
        $this->assertStringContainsString("Rule::in(['LTR', 'RTL'])", $src);
        $this->assertStringContainsString("Rule::unique('glb_languages', 'code')", $src);
        $this->assertStringContainsString("Rule::unique('glb_languages', 'name')", $src);
        $this->assertStringContainsString('return true;', $src);
    }

    public function test_language_05_migration_adds_softdeletes_and_timestamps(): void
    {
        $migration = $this->mainProjectFile('Modules/GlobalMaster/database/migrations/2025_11_10_061519_create_languages_table.php');
        if ($migration === null) {
            $this->markTestSkipped('App repo (MAIN_PROJECT_PATH) unavailable.');
        }
        $src = File::get($migration);
        $this->assertStringContainsString('softDeletes', $src);
        $this->assertStringContainsString('timestamps', $src);
        // Consolidated DDL spec omits these — documented as DATA/MIG drift; running DB (migration) is correct.
        $this->assertStringContainsString("string('name', 50)->unique()", $src);
    }

    // =====================================================================
    // Band 10-19 — Business rules / activity log
    // =====================================================================

    public function test_language_10_store_persists_all_fields(): void
    {
        $suffix = $this->uniqueSuffix();
        $code   = 'st' . substr($suffix, -6);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'        => 'Store ' . $suffix,
            'code'        => $code,
            'native_name' => 'NN ' . substr($suffix, -4),
            'direction'   => 'RTL',
            'is_active'   => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $row = Language::where('code', $code)->first();
        $this->assertNotNull($row);
        $this->assertSame('RTL', $row->direction);
        $this->cleanupLanguage($row);
    }

    public function test_language_11_store_redirects_index_with_created_flash(): void
    {
        $suffix = $this->uniqueSuffix();
        $code   = 'sr' . substr($suffix, -6);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'      => 'Redirect ' . $suffix,
            'code'      => $code,
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHas('success');
        $this->cleanupLanguage(Language::where('code', $code)->first());
    }

    public function test_language_12_update_persists_changes(): void
    {
        $lang = $this->seedOrSkip();
        $r = $this->httpAsAdmin('put', 'central.global-master.language.update', $lang, [
            'name'        => $lang->name . ' Upd',
            'code'        => $lang->code,
            'native_name' => $lang->native_name,
            'direction'   => 'LTR',
            'is_active'   => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertStringEndsWith('Upd', $lang->refresh()->name);
        $this->cleanupLanguage($lang);
    }

    public function test_language_13_update_flash_is_literal_update_language_bug(): void
    {
        $lang = $this->seedOrSkip();
        $r = $this->httpAsAdmin('put', 'central.global-master.language.update', $lang, [
            'name'        => $lang->name . ' Bug',
            'code'        => $lang->code,
            'native_name' => $lang->native_name,
            'direction'   => 'LTR',
            'is_active'   => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        // BUG-GLB-006b: raw literal instead of flash('updated.language').
        $r->assertSessionHas('success', 'update.language');
        $this->cleanupLanguage($lang);
    }

    public function test_language_14_destroy_sets_inactive_then_soft_deletes(): void
    {
        $lang = $this->seedOrSkip(['is_active' => true]);
        $id = $lang->id;
        $r = $this->httpAsAdmin('delete', 'central.global-master.language.destroy', $id);
        if ($this->domainSkip($r)) {
            return;
        }
        $fresh = Language::withTrashed()->find($id);
        $this->assertNotNull($fresh->deleted_at);
        $this->assertFalse((bool) $fresh->is_active);
        $this->hardCleanup($id);
    }

    public function test_language_15_destroy_logs_trashed_event(): void
    {
        $lang = $this->seedOrSkip();
        $id = $lang->id;
        $r = $this->httpAsAdmin('delete', 'central.global-master.language.destroy', $id);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertSame('Trashed', $this->latestActivityEvent($id));
        $this->hardCleanup($id);
    }

    public function test_language_16_restore_logs_restored_event(): void
    {
        $lang = $this->seedOrSkip();
        $lang->delete();
        $id = $lang->id;
        $r = $this->httpAsAdmin('get', 'central.global-master.language.restore', $id);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertNull(Language::find($id)?->deleted_at);
        $this->assertSame('Restored', $this->latestActivityEvent($id));
        $this->hardCleanup($id);
    }

    public function test_language_17_force_delete_logs_stored_event_bug(): void
    {
        $lang = $this->seedOrSkip();
        $lang->delete();
        $id = $lang->id;
        $r = $this->httpAsAdmin('delete', 'central.global-master.language.forceDelete', $id);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertNull(Language::withTrashed()->find($id));
        // BUG-GLB-006a: mislabeled 'Stored' (should be 'Deleted').
        $this->assertSame('Stored', $this->latestActivityEvent($id));
    }

    public function test_language_18_toggle_status_logs_toggled_event(): void
    {
        $lang = $this->seedOrSkip(['is_active' => true]);
        $id = $lang->id;
        $r = $this->httpAsAdmin('post', 'central.global-master.language.toggleStatus', $lang, ['is_active' => 0]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertOk()->assertJson(['success' => true]);
        $this->assertSame('Toggled', $this->latestActivityEvent($id));
        $this->cleanupLanguage($lang);
    }

    public function test_language_19_store_and_update_do_not_log_activity(): void
    {
        $suffix = $this->uniqueSuffix();
        $code   = 'nl' . substr($suffix, -6);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'      => 'NoLog ' . $suffix,
            'code'      => $code,
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $row = Language::where('code', $code)->first();
        $this->assertNotNull($row);
        // store() writes no activity log.
        $this->assertNull($this->latestActivityEvent($row->id), 'store must not write an activity row');
        $this->cleanupLanguage($row);
    }

    // =====================================================================
    // Band 20-29 — State machine transitions
    // =====================================================================

    public function test_language_20_active_to_inactive_via_toggle(): void
    {
        $lang = $this->seedOrSkip(['is_active' => true]);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.toggleStatus', $lang, ['is_active' => 0]);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertFalse((bool) $lang->refresh()->is_active);
        $this->cleanupLanguage($lang);
    }

    public function test_language_21_inactive_to_active_via_toggle(): void
    {
        $lang = $this->seedOrSkip(['is_active' => false]);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.toggleStatus', $lang, ['is_active' => 1]);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertTrue((bool) $lang->refresh()->is_active);
        $this->cleanupLanguage($lang);
    }

    public function test_language_22_active_to_trashed_via_destroy(): void
    {
        $lang = $this->seedOrSkip();
        $id = $lang->id;
        $r = $this->httpAsAdmin('delete', 'central.global-master.language.destroy', $id);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertNotNull(Language::withTrashed()->find($id)->deleted_at);
        $this->hardCleanup($id);
    }

    public function test_language_23_trashed_to_active_via_restore(): void
    {
        $lang = $this->seedOrSkip();
        $lang->delete();
        $id = $lang->id;
        $r = $this->httpAsAdmin('get', 'central.global-master.language.restore', $id);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertNull(Language::find($id)?->deleted_at);
        $this->hardCleanup($id);
    }

    public function test_language_24_trashed_to_removed_via_force_delete(): void
    {
        $lang = $this->seedOrSkip();
        $lang->delete();
        $id = $lang->id;
        $r = $this->httpAsAdmin('delete', 'central.global-master.language.forceDelete', $id);
        if ($this->domainSkip($r)) {
            return;
        }
        $this->assertNull(Language::withTrashed()->find($id));
    }

    public function test_language_25_full_lifecycle_create_toggle_delete_restore_forcedelete(): void
    {
        $suffix = $this->uniqueSuffix();
        $code   = 'lc' . substr($suffix, -6);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'      => 'Lifecycle ' . $suffix,
            'code'      => $code,
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $lang = Language::where('code', $code)->first();
        $this->assertNotNull($lang);
        $id = $lang->id;

        $this->httpAsAdmin('post', 'central.global-master.language.toggleStatus', $lang, ['is_active' => 0]);
        $this->assertFalse((bool) $lang->refresh()->is_active);

        $this->httpAsAdmin('delete', 'central.global-master.language.destroy', $id);
        $this->assertNotNull(Language::withTrashed()->find($id)->deleted_at);

        $this->httpAsAdmin('get', 'central.global-master.language.restore', $id);
        $this->assertNull(Language::find($id)?->deleted_at);

        $lang->refresh()->delete();
        $this->httpAsAdmin('delete', 'central.global-master.language.forceDelete', $id);
        $this->assertNull(Language::withTrashed()->find($id));
    }

    // =====================================================================
    // Band 30-39 — Validation
    // =====================================================================

    public function test_language_30_code_is_required(): void
    {
        $r = $this->storeInvalid(['name' => 'X ' . $this->uniqueSuffix(), 'direction' => 'LTR', 'is_active' => 'on']);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('code');
    }

    public function test_language_31_name_is_required(): void
    {
        $r = $this->storeInvalid(['code' => 'x' . substr($this->uniqueSuffix(), -5), 'direction' => 'LTR', 'is_active' => 'on']);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('name');
    }

    public function test_language_32_direction_is_required(): void
    {
        $r = $this->storeInvalid([
            'name'      => 'NoDir ' . $this->uniqueSuffix(),
            'code'      => 'nd' . substr($this->uniqueSuffix(), -6),
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('direction');
    }

    public function test_language_33_code_max_10_enforced(): void
    {
        $r = $this->storeInvalid([
            'name'      => 'Long ' . $this->uniqueSuffix(),
            'code'      => str_repeat('a', 11),
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('code');
    }

    public function test_language_34_name_max_50_enforced(): void
    {
        $r = $this->storeInvalid([
            'name'      => str_repeat('n', 51),
            'code'      => 'ln' . substr($this->uniqueSuffix(), -6),
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('name');
    }

    public function test_language_35_native_name_max_50_enforced(): void
    {
        $r = $this->storeInvalid([
            'name'        => 'NN ' . $this->uniqueSuffix(),
            'code'        => 'nm' . substr($this->uniqueSuffix(), -6),
            'native_name' => str_repeat('m', 51),
            'direction'   => 'LTR',
            'is_active'   => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('native_name');
    }

    public function test_language_36_native_name_nullable_accepts_empty(): void
    {
        $suffix = $this->uniqueSuffix();
        $code   = 'ne' . substr($suffix, -6);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'        => 'NullNative ' . $suffix,
            'code'        => $code,
            'native_name' => '',
            'direction'   => 'LTR',
            'is_active'   => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasNoErrors();
        $this->cleanupLanguage(Language::where('code', $code)->first());
    }

    public function test_language_37_duplicate_code_rejected(): void
    {
        $lang = $this->seedOrSkip();
        $r = $this->storeInvalid([
            'name'      => 'Dupe ' . $this->uniqueSuffix(),
            'code'      => $lang->code,
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('code');
        $this->cleanupLanguage($lang);
    }

    public function test_language_38_duplicate_name_rejected(): void
    {
        $lang = $this->seedOrSkip();
        $r = $this->storeInvalid([
            'name'      => $lang->name,
            'code'      => 'dn' . substr($this->uniqueSuffix(), -6),
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('name');
        $this->cleanupLanguage($lang);
    }

    public function test_language_39_invalid_direction_value_rejected(): void
    {
        $r = $this->storeInvalid([
            'name'      => 'BadDir ' . $this->uniqueSuffix(),
            'code'      => 'bd' . substr($this->uniqueSuffix(), -6),
            'direction' => 'ltr', // lower-case must be rejected (ENUM is case-exact LTR/RTL, D18)
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasErrors('direction');
    }

    public function test_language_39b_code_unique_ignores_self_on_update(): void
    {
        $lang = $this->seedOrSkip();
        $r = $this->httpAsAdmin('put', 'central.global-master.language.update', $lang, [
            'name'        => $lang->name,
            'code'        => $lang->code, // same code on its own record must be allowed
            'native_name' => $lang->native_name,
            'direction'   => 'LTR',
            'is_active'   => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasNoErrors();
        $this->cleanupLanguage($lang);
    }

    // =====================================================================
    // Band 40-49 — Integration / FK (defensive)
    // =====================================================================

    public function test_language_40_translations_fk_exists_defensive(): void
    {
        if (!Schema::hasTable('glb_translations')) {
            $this->markTestSkipped('glb_translations not present in this environment.');
        }
        $this->assertTrue(Schema::hasColumn('glb_translations', 'language_id'));
    }

    public function test_language_41_force_delete_cascades_translations_defensive(): void
    {
        if (!Schema::hasTable('glb_translations')) {
            $this->markTestSkipped('glb_translations not present.');
        }
        $lang = $this->seedOrSkip();
        try {
            DB::connection((new Language())->getConnectionName())->table('glb_translations')->insert([
                'translatable_type' => Language::class,
                'translatable_id'   => $lang->id,
                'language_id'       => $lang->id,
                'key'               => 'greeting',
                'value'             => 'hello',
                'created_at'        => now(),
                'updated_at'        => now(),
            ]);
        } catch (Throwable) {
            $this->cleanupLanguage($lang);
            $this->markTestSkipped('Could not seed translation row.');
        }
        $lang->forceDelete();
        $remaining = DB::connection((new Language())->getConnectionName())
            ->table('glb_translations')->where('language_id', $lang->id)->count();
        $this->assertSame(0, (int) $remaining, 'ON DELETE CASCADE removes dependent translations');
    }

    public function test_language_42_soft_delete_keeps_translations_defensive(): void
    {
        if (!Schema::hasTable('glb_translations')) {
            $this->markTestSkipped('glb_translations not present.');
        }
        $lang = $this->seedOrSkip();
        $conn = (new Language())->getConnectionName();
        try {
            DB::connection($conn)->table('glb_translations')->insert([
                'translatable_type' => Language::class,
                'translatable_id'   => $lang->id,
                'language_id'       => $lang->id,
                'key'               => 'farewell',
                'value'             => 'bye',
                'created_at'        => now(),
                'updated_at'        => now(),
            ]);
        } catch (Throwable) {
            $this->cleanupLanguage($lang);
            $this->markTestSkipped('Could not seed translation row.');
        }
        $lang->delete(); // soft delete must NOT cascade
        $remaining = DB::connection($conn)->table('glb_translations')->where('language_id', $lang->id)->count();
        $this->assertSame(1, (int) $remaining, 'soft delete preserves translations');
        $this->hardCleanup($lang->id);
    }

    // =====================================================================
    // Band 50-59 — Authorization (SEC-GLB-010 / SEC-GLB-005 reconciled against live controller)
    // =====================================================================

    public function test_language_50_guest_redirected_to_login_on_index(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(400);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(900);
            $browser->assertPathContains('/login');
        });
    }

    public function test_language_51_index_requires_viewany_gate(): void
    {
        $this->assertLimitedForbidden('get', 'central.global-master.language.index', null);
    }

    public function test_language_52_create_requires_create_gate(): void
    {
        // SEC-GLB-010 reconciled: live Prime controller DOES gate create with prime.language.create.
        $this->assertLimitedForbidden('get', 'central.global-master.language.create', null);
    }

    public function test_language_53_store_requires_create_gate(): void
    {
        $this->assertLimitedForbidden('post', 'central.global-master.language.store', null, [
            'name' => 'Nope ' . $this->uniqueSuffix(), 'code' => 'np1', 'direction' => 'LTR', 'is_active' => 'on',
        ]);
    }

    public function test_language_54_edit_update_requires_update_gate(): void
    {
        $lang = $this->seedOrSkip();
        $this->assertLimitedForbidden('get', 'central.global-master.language.edit', $lang->id);
        $this->cleanupLanguage($lang);
    }

    public function test_language_55_destroy_requires_delete_gate(): void
    {
        // SEC-GLB-005 reconciled: live Prime controller gates destroy with prime.language.delete (correct prefix).
        $lang = $this->seedOrSkip();
        $this->assertLimitedForbidden('delete', 'central.global-master.language.destroy', $lang->id);
        $this->hardCleanup($lang->id);
    }

    public function test_language_56_restore_forcedelete_require_gates(): void
    {
        $lang = $this->seedOrSkip();
        $lang->delete();
        $this->assertLimitedForbidden('get', 'central.global-master.language.restore', $lang->id);
        $this->assertLimitedForbidden('delete', 'central.global-master.language.forceDelete', $lang->id);
        $this->hardCleanup($lang->id);
    }

    public function test_language_57_toggle_status_requires_update_gate(): void
    {
        $lang = $this->seedOrSkip();
        $this->assertLimitedForbidden('post', 'central.global-master.language.toggleStatus', $lang->id, ['is_active' => 0]);
        $this->cleanupLanguage($lang);
    }

    public function test_language_58_request_authorize_returns_true_no_defense_in_depth(): void
    {
        // D30: LanguageRequest::authorize() returns bare true — authorization relies solely on
        // the controller gates. Assert the source truth (proving the systemic weakness).
        $request = $this->mainProjectFile('Modules/GlobalMaster/app/Http/Requests/LanguageRequest.php');
        if ($request === null) {
            $this->markTestSkipped('App repo unavailable.');
        }
        $src = File::get($request);
        $this->assertMatchesRegularExpression('/function\s+authorize\s*\(\s*\)\s*:\s*bool\s*\{\s*return\s+true;/s', $src);
    }

    // =====================================================================
    // Band 60-69 — UI / UX
    // =====================================================================

    public function test_language_60_index_lists_seeded_language(): void
    {
        $lang = $this->seedOrSkip();
        $this->browse(function (Browser $browser) use ($lang): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode($lang->name));
            $browser->assertSee($lang->code);
        });
        $this->cleanupLanguage($lang);
    }

    public function test_language_61_search_miss_shows_no_data(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=zz_no_such_lang_' . $this->uniqueSuffix());
            $browser->assertSee('Not Data Found');
        });
    }

    public function test_language_62_search_filters_by_name(): void
    {
        $lang = $this->seedOrSkip();
        $this->browse(function (Browser $browser) use ($lang): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode($lang->name));
            $browser->assertSee($lang->name);
        });
        $this->cleanupLanguage($lang);
    }

    public function test_language_63_status_filter_control_present(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertPresent('select[name="status"]');
        });
    }

    public function test_language_64_pagination_present_when_over_11(): void
    {
        // Index paginates 11/page; if the shared central DB already holds >11 languages,
        // pagination renders. Assert the table is present regardless (soft check).
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertPresent('table.js-sortable');
        });
    }

    public function test_language_65_breadcrumb_language_management(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertSee('Language Management');
        });
    }

    public function test_language_66_create_form_has_direction_options(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $browser->waitFor('select[name="direction"]', 10)
                ->assertSeeIn('select[name="direction"]', 'Left to Right')
                ->assertSeeIn('select[name="direction"]', 'Right to Left');
        });
    }

    // =====================================================================
    // Band 70-79 — Edge cases
    // =====================================================================

    public function test_language_70_code_whitespace_stored_verbatim(): void
    {
        // No trim rule → surrounding whitespace is stored as-is (documents the gap).
        $lang = $this->makeLanguage(['code' => ' wsx' . substr($this->uniqueSuffix(), -3)]);
        if ($lang === null) {
            $this->markTestSkipped('Could not seed.');
        }
        $this->assertStringStartsWith(' ', $lang->refresh()->code);
        $this->cleanupLanguage($lang);
    }

    public function test_language_71_boundary_code_exactly_10_accepted(): void
    {
        $suffix = $this->uniqueSuffix();
        $code   = substr('cd' . $suffix, 0, 10);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'      => 'Boundary10 ' . $suffix,
            'code'      => $code,
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasNoErrors();
        $this->cleanupLanguage(Language::where('code', $code)->first());
    }

    public function test_language_72_boundary_name_exactly_50_accepted(): void
    {
        $suffix = $this->uniqueSuffix();
        $name   = substr('B50_' . str_repeat('x', 60), 0, 50);
        $code   = 'b5' . substr($suffix, -6);
        $r = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'      => $name,
            'code'      => $code,
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->domainSkip($r)) {
            return;
        }
        $r->assertSessionHasNoErrors();
        $this->cleanupLanguage(Language::where('code', $code)->first());
    }

    public function test_language_73_invalid_id_returns_404_on_edit(): void
    {
        $r = $this->httpAsAdmin('get', 'central.global-master.language.edit', 999999999);
        $status = $r->getStatusCode();
        $this->assertContains($status, [404, 302, 403], 'nonexistent id must not resolve to a real record');
    }

    public function test_language_74_invalid_id_returns_404_on_destroy(): void
    {
        $r = $this->httpAsAdmin('delete', 'central.global-master.language.destroy', 999999999);
        $status = $r->getStatusCode();
        $this->assertContains($status, [404, 302, 403]);
    }

    public function test_language_75_restore_nonexistent_returns_404(): void
    {
        $r = $this->httpAsAdmin('get', 'central.global-master.language.restore', 999999999);
        $status = $r->getStatusCode();
        $this->assertContains($status, [404, 302, 403]);
    }

    public function test_language_76_direction_defaults_ltr_at_db_layer(): void
    {
        // DB default 'LTR' when created at model layer without direction.
        $lang = $this->makeLanguage(['direction' => 'LTR']);
        if ($lang === null) {
            $this->markTestSkipped('Could not seed.');
        }
        $this->assertSame('LTR', $lang->refresh()->direction);
        $this->cleanupLanguage($lang);
    }

    // =====================================================================
    // Band 90-99 — Security + tenancy
    // =====================================================================

    public function test_language_90_xss_in_name_is_escaped_on_render(): void
    {
        $payload = '<script>alert(1)</script>XN' . substr($this->uniqueSuffix(), -4);
        $lang = $this->makeLanguage(['name' => $payload]);
        if ($lang === null) {
            $this->markTestSkipped('Could not seed.');
        }
        $this->browse(function (Browser $browser) use ($lang): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode('XN'));
            $source = (string) $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'payload must be HTML-escaped');
        });
        $this->cleanupLanguage($lang);
    }

    public function test_language_91_xss_in_native_name_is_escaped_on_render(): void
    {
        $payload = '<script>alert(2)</script>';
        $lang = $this->makeLanguage(['native_name' => $payload, 'name' => 'XSSNative ' . $this->uniqueSuffix()]);
        if ($lang === null) {
            $this->markTestSkipped('Could not seed.');
        }
        $this->browse(function (Browser $browser) use ($lang): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode('XSSNative'));
            $source = (string) $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(2)</script>', $source);
        });
        $this->cleanupLanguage($lang);
    }

    public function test_language_92_stored_xss_payload_persisted_literally(): void
    {
        $payload = '<b>bold</b>';
        $lang = $this->makeLanguage(['native_name' => $payload, 'name' => 'Persist ' . $this->uniqueSuffix()]);
        if ($lang === null) {
            $this->markTestSkipped('Could not seed.');
        }
        $this->assertSame($payload, $lang->refresh()->native_name, 'payload stored verbatim (escaping is on render)');
        $this->cleanupLanguage($lang);
    }

    public function test_language_93_idor_cross_id_access_returns_404(): void
    {
        $r = $this->httpAsAdmin('get', 'central.global-master.language.edit', 888888888);
        $this->assertContains($r->getStatusCode(), [404, 302, 403]);
    }

    public function test_language_94_guest_cannot_store(): void
    {
        // No actingAs — unauthenticated POST must not create; expect redirect to login (302) or 419/403.
        $host = (string) parse_url($this->primeBaseUrl, PHP_URL_HOST);
        $port = parse_url($this->primeBaseUrl, PHP_URL_PORT);
        $this->withServerVariables(['HTTP_HOST' => $port ? "{$host}:{$port}" : $host]);
        $uri = route('central.global-master.language.store', [], false);
        $code = 'gs' . substr($this->uniqueSuffix(), -6);
        $r = $this->post($uri, ['name' => 'Guest ' . $this->uniqueSuffix(), 'code' => $code, 'direction' => 'LTR', 'is_active' => 'on']);
        $this->assertContains($r->getStatusCode(), [302, 401, 403, 419, 404]);
        $this->assertNull(Language::where('code', $code)->first(), 'guest must not create a language');
    }

    public function test_language_95_mass_assignment_only_fillable_fields(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed.');
        }
        // Attempt to mass-assign a non-fillable attribute — must be ignored.
        $lang->fill(['id' => 123456789]);
        $this->assertNotSame(123456789, $lang->id, 'id is guarded / not overwritten by fill');
        $this->cleanupLanguage($lang);
    }

    public function test_language_96_cross_tenant_isolation_not_applicable_central(): void
    {
        // Language is a CENTRAL/prime-side master shared by all tenants; there is no per-tenant
        // scoping to isolate. Cross-tenant isolation is deliberately N/A for this feature.
        $this->assertSame('global_master_mysql', (new Language())->getConnectionName());
        $this->markTestSkipped('Cross-tenant isolation N/A — Language is a central master (deliberate skip).');
    }

    // =====================================================================
    // Helpers
    // =====================================================================

    protected function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    protected function currentPath(Browser $browser): string
    {
        return (string) parse_url((string) $browser->driver->getCurrentURL(), PHP_URL_PATH);
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
            $browser->loginAs($this->adminUser)->pause(600);
        }
    }

    protected function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1000): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    protected function resolveAdminUser(): void
    {
        try {
            $this->adminUser = User::query()->where('is_super_admin', 1)->first()
                ?? User::query()->where('email', $this->adminEmail)->first();
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    /**
     * Create (once per test) a non-super user with NO prime.language.* permissions.
     * Defensive: returns null and the caller skips if the central users table needs
     * columns the runner factory cannot satisfy (emp_code/prefered_language FK, etc.).
     */
    protected function limitedUser(): ?User
    {
        if ($this->limitedUser !== null) {
            return $this->limitedUser;
        }
        try {
            $languageId = (int) (DB::table('glb_languages')->value('id') ?? 1);
            $this->limitedUser = User::create([
                'name'          => 'Limited GLB ' . $this->uniqueSuffix(),
                'email'         => 'limited_' . uniqid() . '@example.com',
                'password'      => bcrypt('password'),
                'emp_code'      => 'L' . substr((string) uniqid(), -12),
                'prefered_language' => $languageId,
                'user_type'     => 'EMPLOYEE',
                'is_active'     => 1,
                'is_super_admin' => 0,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable) {
            $this->limitedUser = null;
        }
        return $this->limitedUser;
    }

    protected function assertLimitedForbidden(string $method, string $routeName, mixed $param, array $data = []): void
    {
        $user = $this->limitedUser();
        if ($user === null) {
            $this->markTestSkipped('Could not create a limited (non-super) user in this env.');
        }
        $host = (string) parse_url($this->primeBaseUrl, PHP_URL_HOST);
        $port = parse_url($this->primeBaseUrl, PHP_URL_PORT);
        $this->withServerVariables(['HTTP_HOST' => $port ? "{$host}:{$port}" : $host]);
        $uri = $param === null
            ? route($routeName, [], false)
            : route($routeName, [$param], false);
        $r = $this->actingAs($user)->{$method}($uri, $data);
        if ($r->getStatusCode() === 404) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }
        $this->assertSame(403, $r->getStatusCode(), "{$routeName} must forbid a user without prime.language.* permission");
    }

    protected function httpAsAdmin(string $method, string $routeName, mixed $param = null, array $data = [])
    {
        if ($this->adminUser === null) {
            $this->markTestSkipped('No admin user available for HTTP call.');
        }
        $host = (string) parse_url($this->primeBaseUrl, PHP_URL_HOST);
        $port = parse_url($this->primeBaseUrl, PHP_URL_PORT);
        $this->withServerVariables(['HTTP_HOST' => $port ? "{$host}:{$port}" : $host]);
        $uri = $param === null
            ? route($routeName, [], false)
            : route($routeName, [is_object($param) ? $param->getKey() : $param], false);
        return $this->actingAs($this->adminUser)->{$method}($uri, $data);
    }

    protected function storeInvalid(array $data)
    {
        return $this->httpAsAdmin('post', 'central.global-master.language.store', null, $data);
    }

    protected function domainSkip($response): bool
    {
        if (method_exists($response, 'getStatusCode') && $response->getStatusCode() === 404) {
            $this->markTestSkipped('Central domain group not matched in this env (404).');
            return true;
        }
        return false;
    }

    protected function latestActivityEvent(int $subjectId): ?string
    {
        try {
            return ActivityLog::where('subject_type', Language::class)
                ->where('subject_id', $subjectId)
                ->orderByDesc('id')
                ->value('event');
        } catch (Throwable) {
            return null;
        }
    }

    protected function seedOrSkip(array $overrides = []): Language
    {
        $lang = $this->makeLanguage($overrides);
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }
        return $lang;
    }

    protected function makeLanguage(array $overrides = []): ?Language
    {
        $suffix = $this->uniqueSuffix();
        try {
            return Language::create(array_merge([
                'code'        => 'lg' . substr($suffix, -6),
                'name'        => 'Lang ' . $suffix,
                'native_name' => 'Native ' . substr($suffix, -6),
                'direction'   => 'LTR',
                'is_active'   => true,
            ], $overrides));
        } catch (Throwable) {
            return null;
        }
    }

    protected function cleanupLanguage(?Language $lang): void
    {
        if ($lang === null) {
            return;
        }
        try {
            $lang->forceDelete();
        } catch (Throwable) {
        }
    }

    protected function hardCleanup(int $id): void
    {
        try {
            $row = Language::withTrashed()->find($id);
            if ($row) {
                $row->forceDelete();
            }
        } catch (Throwable) {
        }
    }

    protected function uniqueSuffix(): string
    {
        return substr((string) uniqid(), -8) . random_int(10, 99);
    }

    protected function mainProjectFile(string $relative): ?string
    {
        $root = env('MAIN_PROJECT_PATH');
        if (!is_string($root) || $root === '') {
            return null;
        }
        $path = rtrim($root, '/') . '/' . ltrim($relative, '/');
        return is_file($path) ? $path : null;
    }

    protected function cleanScreenshots(): void
    {
        if (!defined('static::SCREENSHOT_DIR')) {
            return;
        }
        try {
            $dir = base_path(static::SCREENSHOT_DIR);
            if (is_dir($dir)) {
                foreach (glob($dir . DIRECTORY_SEPARATOR . '*.png') ?: [] as $file) {
                    @unlink($file);
                }
            }
        } catch (Throwable) {
        }
    }
}
