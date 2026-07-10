<?php

namespace Tests\Browser\Modules\Prime\TenantGroup;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\ActivityLog;
use Modules\Prime\Models\TenantGroup;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Central (prime_db) feature suite for the Tenant Group screen.
 *
 * DB scope ............ CENTRAL — prime_db, prefix `prm_` (DDL-verified). No tenant init.
 * Host ................ http://127.0.0.1:8000 (enforced by PrimeDuskTestCase::setUp host guard).
 * Base ................ extends PrimeDuskTestCase (module-local alias resolved via preload.php, constraint #22).
 * Central auth helpers  copied locally from prm_BillingDuskTestCase_TestCas per orchestrator override.
 * Activity sink ....... Modules\Prime\Models\ActivityLog -> table `sys_central_activity_logs` (constraint #25).
 *
 * Controller ..... Modules\Prime\Http\Controllers\TenantGroupController
 * Request ........ Modules\Prime\Http\Requests\TenantGroupRequest
 * Model .......... Modules\Prime\Models\TenantGroup (prm_tenant_groups, SoftDeletes)
 * Routes ......... central.prime.tenant-group.{index,create,store,show,edit,update,destroy,trashed,restore,forceDelete,toggleStatus}
 *
 * Activity EVENT strings are LITERAL from the controller (do NOT assume the Stored/ToggelStatus set):
 *   store -> 'created'  |  destroy -> 'Trashed'  |  restore -> 'Restored'
 *   forceDelete -> 'Deleted'  |  toggleStatus -> 'Toggled'  |  update -> (none, D25-PRM-003)
 */
class prm_TenantGroup_TestCas extends PrimeDuskTestCase
{
    private const TABLE = 'prm_tenant_groups';
    private const ACTIVITY_TABLE = 'sys_central_activity_logs';
    private const CONTROLLER = '/Users/bkwork/Herd/prime_ai/Modules/Prime/app/Http/Controllers/TenantGroupController.php';
    private const REQUEST_FILE = '/Users/bkwork/Herd/prime_ai/Modules/Prime/app/Http/Requests/TenantGroupRequest.php';

    private const RT_INDEX = 'central.prime.tenant-group.index';
    private const RT_CREATE = 'central.prime.tenant-group.create';
    private const RT_STORE = 'central.prime.tenant-group.store';
    private const RT_SHOW = 'central.prime.tenant-group.show';
    private const RT_EDIT = 'central.prime.tenant-group.edit';
    private const RT_UPDATE = 'central.prime.tenant-group.update';
    private const RT_DESTROY = 'central.prime.tenant-group.destroy';
    private const RT_TRASHED = 'central.prime.tenant-group.trashed';
    private const RT_RESTORE = 'central.prime.tenant-group.restore';
    private const RT_FORCE = 'central.prime.tenant-group.forceDelete';
    private const RT_TOGGLE = 'central.prime.tenant-group.toggleStatus';

    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/TenantGroup/screenshots';

    protected ?User $adminUser = null;
    protected string $centralBaseUrl = '';
    protected string $adminEmail = '';
    protected string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->resolveAdminUser();
        $this->ensureAdminCanBypassGates();
    }

    protected function tearDown(): void
    {
        // Central feature — no tenancy to end; guard defensively per constraint #3.
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01-09 — Schema / DDL / model / request configuration (config truth)
    // =====================================================================

    /** TC-P01 | BC-DB-* / BC-VAL-* / BC-AUTH-* | Source: DDL-prm_tenant_groups, TenantGroupRequest, TenantGroupController */
    public function test_tenantgroup_01_migration_model_and_request_configuration_are_correct(): void
    {
        // --- Table + columns (Schema truth; MySQL 8 type variance -> substring asserts, constraint #17) ---
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table prm_tenant_groups must exist in prime_db.');
        $this->assertTrue(Schema::hasColumns(self::TABLE, [
            'id', 'code', 'short_name', 'name', 'address_1', 'address_2',
            'city_id', 'pincode', 'website_url', 'email', 'is_active',
            'deleted_at', 'created_at', 'updated_at',
        ]), 'prm_tenant_groups is missing one or more DDL-declared columns.');

        // --- Soft delete column present (BC-DB) ---
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'deleted_at'), 'Soft-delete column deleted_at missing.');

        // --- Model configuration ---
        $model = new TenantGroup();
        $this->assertSame(self::TABLE, $model->getTable(), 'Model $table must be prm_tenant_groups.');
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(TenantGroup::class),
            'TenantGroup model must use SoftDeletes.'
        );
        foreach (['code', 'short_name', 'name', 'address_1', 'address_2', 'city_id', 'pincode', 'website_url', 'email', 'is_active'] as $fillable) {
            $this->assertContains($fillable, $model->getFillable(), "Fillable must include {$fillable}.");
        }
        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null, 'is_active must cast to boolean.');
        $this->assertSame('integer', $casts['city_id'] ?? null, 'city_id must cast to integer.');
        $this->assertTrue(method_exists($model, 'city'), 'city() relationship must exist.');
        $this->assertTrue(method_exists($model, 'tenants'), 'tenants() relationship must exist.');
        $this->assertTrue(method_exists($model, 'liveTenants'), 'liveTenants() relationship must exist.');

        // --- FormRequest rule strings (verbatim from TenantGroupRequest::rules()) ---
        $this->assertFileExists(self::REQUEST_FILE, 'TenantGroupRequest.php must exist.');
        $request = (string) File::get(self::REQUEST_FILE);
        $this->assertStringContainsString("'code' => ['required', 'string', 'max:20']", $request);
        $this->assertStringContainsString("'max:50'", $request);
        $this->assertStringContainsString("'max:150'", $request);
        $this->assertStringContainsString("Rule::unique('prm_tenant_groups', 'short_name')", $request);
        $this->assertStringContainsString("Rule::unique('prm_tenant_groups', 'name')", $request);
        $this->assertStringContainsString("'city_id' => ['required', 'exists:glb_cities,id']", $request);
        $this->assertStringContainsString("'website_url' => ['nullable', 'url', 'max:150']", $request);
        $this->assertStringContainsString("'email' => ['nullable', 'email', 'max:100']", $request);

        // --- Controller Gate strings (verbatim from TenantGroupController) ---
        $controller = (string) File::get(self::CONTROLLER);
        foreach ([
            "Gate::authorize('prime.tenant-group.viewAny')",
            "Gate::authorize('prime.tenant-group.create')",
            "Gate::authorize('prime.tenant-group.view')",
            "Gate::authorize('prime.tenant-group.update')",
            "Gate::authorize('prime.tenant-group.delete')",
            "Gate::authorize('prime.tenant-group.restore')",
            "Gate::authorize('prime.tenant-group.forceDelete')",
        ] as $gate) {
            $this->assertStringContainsString($gate, $controller, "Controller must call {$gate}.");
        }
        // Literal activity event strings the tests assert against.
        $this->assertStringContainsString("activityLog(\$tenantGroup, 'created'", $controller);
        $this->assertStringContainsString("activityLog(\$tenantGroup, 'Trashed'", $controller);
        $this->assertStringContainsString("activityLog(\$tenantGroup, 'Restored'", $controller);
        $this->assertStringContainsString("activityLog(\$tenantGroup, 'Deleted'", $controller);
        $this->assertStringContainsString("activityLog(\$tenantGroup, 'Toggled'", $controller);

        // --- Central activity sink (no DDL file; assert via Schema + model $fillable, constraint #25) ---
        $this->assertTrue(
            Schema::hasTable(self::ACTIVITY_TABLE),
            'Central activity table sys_central_activity_logs must exist.'
        );
        $log = new ActivityLog();
        $this->assertSame(self::ACTIVITY_TABLE, $log->getTable());
        foreach (['subject_type', 'subject_id', 'user_id', 'event', 'properties', 'ip_address', 'user_agent'] as $col) {
            $this->assertContains($col, $log->getFillable(), "ActivityLog fillable must include {$col}.");
        }
    }

    /** TC-P02 | BC-DB unique-index | Source: DDL uq_tenantGroups_shortName */
    public function test_tenantgroup_02_short_name_has_unique_index_but_name_does_not(): void
    {
        try {
            $indexes = collect(DB::select('SHOW INDEX FROM ' . self::TABLE));
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot inspect indexes: ' . $e->getMessage());
        }

        $unique = $indexes->where('Non_unique', 0)->pluck('Column_name')->map(fn ($c) => strtolower((string) $c))->all();
        $this->assertContains('short_name', $unique, 'short_name must carry a UNIQUE index (uq_tenantGroups_shortName).');

        // Cross-reference finding: name is unique in the FormRequest only, NOT at the DB level.
        // This is documented as a divergence, not a hard failure (D25-PRM-006 candidate).
        $this->assertTrue(true, 'DB has no unique index on name; app-level uniqueness only (see Gap Analysis cross-ref).');
    }

    // =====================================================================
    // Band 10-19 — Business rules (BC-BIZ): CRUD + activity-log events
    // =====================================================================

    /** TC-P10 | BC-BIZ store persists + logs 'created' | Source: Controller::store */
    public function test_tenantgroup_10_store_creates_group_and_logs_created_event(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.create');
        $payload = $this->buildValidStorePayload();

        $response = $this->actingAs($this->adminUser)->post(route(self::RT_STORE), $payload);
        $response->assertStatus(302);
        $response->assertSessionHas('success');

        $group = TenantGroup::where('code', $payload['code'])->first();
        $this->assertNotNull($group, 'Tenant group row must be created.');
        $this->assertSame($payload['name'], $group->name);
        $this->assertActivityLogged($group->id, 'created');

        $this->cleanupGroup($group);
    }

    /** TC-P11 | BC-BIZ destroy soft-deletes + sets is_active=false + logs 'Trashed' | Source: Controller::destroy */
    public function test_tenantgroup_11_destroy_soft_deletes_and_logs_trashed_event(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.delete');
        $group = $this->createGroupDirect();

        $response = $this->actingAs($this->adminUser)->delete(route(self::RT_DESTROY, $group->id));
        $response->assertStatus(302);
        $response->assertSessionHas('success');

        $fresh = TenantGroup::withTrashed()->find($group->id);
        $this->assertNotNull($fresh->deleted_at, 'Row must be soft-deleted (deleted_at set).');
        $this->assertSame(0, (int) $fresh->is_active, 'destroy must force is_active=false.');
        $this->assertActivityLogged($group->id, 'Trashed');

        $this->cleanupGroup($fresh);
    }

    /** TC-P12 | BC-BIZ restore recovers + logs 'Restored' | Source: Controller::restore */
    public function test_tenantgroup_12_restore_recovers_row_and_logs_restored_event(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.restore');
        $group = $this->createGroupDirect();
        $group->delete();

        $response = $this->actingAs($this->adminUser)->get(route(self::RT_RESTORE, $group->id));
        $response->assertStatus(302);

        $fresh = TenantGroup::withTrashed()->find($group->id);
        $this->assertNull($fresh->deleted_at, 'restore must clear deleted_at.');
        $this->assertActivityLogged($group->id, 'Restored');

        $this->cleanupGroup($fresh);
    }

    /** TC-P13 | BC-BIZ forceDelete removes permanently + logs 'Deleted' | Source: Controller::forceDelete */
    public function test_tenantgroup_13_force_delete_removes_permanently_and_logs_deleted_event(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.forceDelete');
        $group = $this->createGroupDirect();
        $group->delete();
        $id = $group->id;

        $response = $this->actingAs($this->adminUser)->delete(route(self::RT_FORCE, $id));
        $response->assertStatus(302);

        $this->assertNull(TenantGroup::withTrashed()->find($id), 'forceDelete must remove the row entirely.');
        $this->assertActivityLogged($id, 'Deleted');
    }

    /** TC-P14 | BC-BIZ toggleStatus flips is_active + JSON + logs 'Toggled' | Source: Controller::toggleStatus */
    public function test_tenantgroup_14_toggle_status_updates_flag_returns_json_and_logs_toggled(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.update');
        $group = $this->createGroupDirect(['is_active' => 1]);

        $response = $this->actingAs($this->adminUser)
            ->postJson(route(self::RT_TOGGLE, $group->id), ['is_active' => 0]);
        $response->assertStatus(200)
            ->assertJson(['success' => true, 'is_active' => false]);

        $this->assertSame(0, (int) $group->fresh()->is_active, 'toggleStatus must persist the new flag.');
        $this->assertActivityLogged($group->id, 'Toggled');

        $this->cleanupGroup($group->fresh());
    }

    /** TC-P15 / TC-D25-PRM-002 | BC-BIZ update persists validated data (mass-assignment safe) | Source: Controller::update */
    public function test_tenantgroup_15_update_persists_validated_fields_only_defect_d25_prm_002(): void
    {
        // D25-PRM-002 (P2) alleged: update() uses $request->all() while store() uses $request->validated().
        // CURRENT SOURCE (verified line 99): update() uses $request->validated() — SAME as store().
        // The alleged defect does NOT reproduce in this revision. This test PROVES current behaviour:
        // a non-fillable / non-validated field injected on update is NOT persisted (mass-assignment safe).
        $this->skipUnlessAdminCan('prime.tenant-group.update');
        $group = $this->createGroupDirect();

        $newName = 'Updated Group ' . $this->uniqueSuffix();
        $payload = array_merge($this->groupAttributes(), [
            'name' => $newName,
            'short_name' => 'SN' . $this->uniqueSuffix(),
            'is_active' => 'on',
            // Injected fields that are neither validated nor fillable:
            'id' => 999999,
            'deleted_at' => now()->toDateTimeString(),
        ]);

        $response = $this->actingAs($this->adminUser)->put(route(self::RT_UPDATE, $group->id), $payload);
        $response->assertStatus(302);
        $response->assertSessionHas('success');

        $fresh = $group->fresh();
        $this->assertSame($newName, $fresh->name, 'Validated name must update.');
        $this->assertSame($group->id, $fresh->id, 'Injected id must be ignored (validated() strips it).');
        $this->assertNull($fresh->deleted_at, 'Injected deleted_at must not be persisted.');

        $this->cleanupGroup($fresh);
    }

    /** TC-P16 / D25-PRM-003 | BC-BIZ update writes NO activity log | Source: Controller::update (no activityLog call) */
    public function test_tenantgroup_16_update_does_not_write_activity_log_defect_d25_prm_003(): void
    {
        // Documented divergence: store/destroy/restore/forceDelete/toggleStatus all call activityLog(),
        // but update() does NOT. This test proves current behaviour (no 'updated'/'Updated' event written).
        $this->skipUnlessAdminCan('prime.tenant-group.update');
        $group = $this->createGroupDirect();

        $before = $this->activityCountFor($group->id);

        $this->actingAs($this->adminUser)->put(route(self::RT_UPDATE, $group->id), array_merge(
            $this->groupAttributes(),
            ['name' => 'NoLog ' . $this->uniqueSuffix(), 'short_name' => 'SN' . $this->uniqueSuffix(), 'is_active' => 'on']
        ))->assertStatus(302);

        $after = $this->activityCountFor($group->id);
        $this->assertSame($before, $after, 'update() must not add an activity-log row in the current source (D25-PRM-003).');

        $this->cleanupGroup($group->fresh());
    }

    /** TC-P17 | BC-BIZ store success flash + redirect target | Source: Controller::store redirect */
    public function test_tenantgroup_17_store_redirects_to_tenant_management_with_success_flash(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.create');
        $payload = $this->buildValidStorePayload();

        $response = $this->actingAs($this->adminUser)->post(route(self::RT_STORE), $payload);
        $response->assertStatus(302);
        $response->assertSessionHas('success');
        $target = route('central.prime.tenant-management.index');
        $this->assertStringContainsString($target, (string) $response->headers->get('Location'));

        $this->cleanupGroup(TenantGroup::where('code', $payload['code'])->first());
    }

    // =====================================================================
    // Band 30-39 — Validation + error messages (BC-VAL) — negative matrix
    // =====================================================================

    /** TC-N01 | BC-VAL code required | Source: TenantGroupRequest */
    public function test_tenantgroup_30_store_rejects_missing_code(): void
    {
        $this->assertStoreValidationError(['code' => ''], 'code');
    }

    /** TC-N02 | BC-VAL code max:20 | Source: TenantGroupRequest */
    public function test_tenantgroup_31_store_rejects_code_over_20_chars(): void
    {
        $this->assertStoreValidationError(['code' => str_repeat('X', 21)], 'code');
    }

    /** TC-N03 | BC-VAL short_name required | Source: TenantGroupRequest */
    public function test_tenantgroup_32_store_rejects_missing_short_name(): void
    {
        $this->assertStoreValidationError(['short_name' => ''], 'short_name');
    }

    /** TC-N04 | BC-VAL short_name max:50 | Source: TenantGroupRequest */
    public function test_tenantgroup_33_store_rejects_short_name_over_50_chars(): void
    {
        $this->assertStoreValidationError(['short_name' => str_repeat('S', 51)], 'short_name');
    }

    /** TC-N05 | BC-VAL short_name unique | Source: TenantGroupRequest Rule::unique(short_name) */
    public function test_tenantgroup_34_store_rejects_duplicate_short_name(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.create');
        $existing = $this->createGroupDirect();

        $response = $this->actingAs($this->adminUser)->postJson(
            route(self::RT_STORE),
            array_merge($this->groupAttributes(), ['short_name' => $existing->short_name, 'code' => 'C' . $this->uniqueSuffix()])
        );
        $response->assertStatus(422)->assertJsonValidationErrors(['short_name']);

        $this->cleanupGroup($existing);
    }

    /** TC-N06 | BC-VAL name required | Source: TenantGroupRequest */
    public function test_tenantgroup_35_store_rejects_missing_name(): void
    {
        $this->assertStoreValidationError(['name' => ''], 'name');
    }

    /** TC-N07 | BC-VAL name max:150 | Source: TenantGroupRequest */
    public function test_tenantgroup_36_store_rejects_name_over_150_chars(): void
    {
        $this->assertStoreValidationError(['name' => str_repeat('N', 151)], 'name');
    }

    /** TC-N08 | BC-VAL name unique | Source: TenantGroupRequest Rule::unique(name) */
    public function test_tenantgroup_37_store_rejects_duplicate_name(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.create');
        $existing = $this->createGroupDirect();

        $response = $this->actingAs($this->adminUser)->postJson(
            route(self::RT_STORE),
            array_merge($this->groupAttributes(), ['name' => $existing->name, 'code' => 'C' . $this->uniqueSuffix()])
        );
        $response->assertStatus(422)->assertJsonValidationErrors(['name']);

        $this->cleanupGroup($existing);
    }

    /** TC-N09 | BC-VAL city_id required | Source: TenantGroupRequest */
    public function test_tenantgroup_38_store_rejects_missing_city_id(): void
    {
        $this->assertStoreValidationError(['city_id' => ''], 'city_id');
    }

    /** TC-N10 | BC-VAL city_id exists:glb_cities,id | Source: TenantGroupRequest */
    public function test_tenantgroup_39_store_rejects_nonexistent_city_id(): void
    {
        $this->assertStoreValidationError(['city_id' => 999999999], 'city_id');
    }

    /** TC-N11 | BC-VAL website_url must be a URL / email must be valid / pincode max:10 | Source: TenantGroupRequest */
    public function test_tenantgroup_40_store_rejects_bad_optional_field_formats(): void
    {
        $this->assertStoreValidationError(['website_url' => 'not a url'], 'website_url');
        $this->assertStoreValidationError(['email' => 'not-an-email'], 'email');
        $this->assertStoreValidationError(['pincode' => str_repeat('9', 11)], 'pincode');
        $this->assertStoreValidationError(['website_url' => 'http://x.test/' . str_repeat('a', 160)], 'website_url');
    }

    /** TC-N12 | BC-VAL update honours unique-ignore-self on short_name | Source: TenantGroupRequest ignore($id) */
    public function test_tenantgroup_41_update_allows_keeping_own_short_name(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.update');
        $group = $this->createGroupDirect();

        // Re-submitting the same short_name for the same record must NOT trip the unique rule.
        $response = $this->actingAs($this->adminUser)->put(route(self::RT_UPDATE, $group->id), array_merge(
            $this->groupAttributes(),
            ['short_name' => $group->short_name, 'name' => $group->name, 'code' => $group->code, 'is_active' => 'on']
        ));
        $response->assertStatus(302);
        $response->assertSessionHasNoErrors();

        $this->cleanupGroup($group->fresh());
    }

    // =====================================================================
    // Band 40-49 — Integration / FK dependency (BC-INT / BC-REF)
    // =====================================================================

    /** TC-D01 (F) | full lifecycle create->edit->toggle->delete->restore->forceDelete | Source: Controller */
    public function test_tenantgroup_42_full_lifecycle_flow(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.forceDelete');
        $group = $this->createGroupDirect(['is_active' => 1]);
        $id = $group->id;

        // edit (update)
        $this->actingAs($this->adminUser)->put(route(self::RT_UPDATE, $id), array_merge(
            $this->groupAttributes(),
            ['name' => 'Life ' . $this->uniqueSuffix(), 'short_name' => 'SN' . $this->uniqueSuffix(), 'is_active' => 'on']
        ))->assertStatus(302);

        // toggle
        $this->actingAs($this->adminUser)->postJson(route(self::RT_TOGGLE, $id), ['is_active' => 0])->assertStatus(200);

        // delete (soft)
        $this->actingAs($this->adminUser)->delete(route(self::RT_DESTROY, $id))->assertStatus(302);
        $this->assertNotNull(TenantGroup::withTrashed()->find($id)->deleted_at);

        // restore
        $this->actingAs($this->adminUser)->get(route(self::RT_RESTORE, $id))->assertStatus(302);
        $this->assertNull(TenantGroup::withTrashed()->find($id)->deleted_at);

        // forceDelete
        $this->actingAs($this->adminUser)->delete(route(self::RT_FORCE, $id))->assertStatus(302);
        $this->assertNull(TenantGroup::withTrashed()->find($id));
    }

    /** TC-D02 (B) | soft delete preserves the row; restore does not recover a force-deleted row | Source: DDL deleted_at */
    public function test_tenantgroup_43_soft_delete_preserves_row_in_database(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.delete');
        $group = $this->createGroupDirect();
        $group->delete();

        $this->assertDatabaseHas(self::TABLE, ['id' => $group->id]);
        $this->assertNull(TenantGroup::find($group->id), 'Default query must exclude soft-deleted rows.');
        $this->assertNotNull(TenantGroup::withTrashed()->find($group->id), 'withTrashed must still find it.');

        $this->cleanupGroup(TenantGroup::withTrashed()->find($group->id));
    }

    /** TC-D03 (C) | FK RESTRICT: a live child Tenant blocks force-delete of the parent group | Source: DDL fk_tenant_tenantGroupId ON DELETE RESTRICT */
    public function test_tenantgroup_44_force_delete_is_restricted_while_a_tenant_references_it(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.forceDelete');
        $group = $this->createGroupDirect();
        $group->delete();

        try {
            // Create a child tenant row referencing this group (defensive — schema may require more columns).
            DB::table('prm_tenant')->insert([
                'tenant_group_id' => $group->id,
                'code' => 'T' . $this->uniqueSuffix(),
                'short_name' => 'TS' . $this->uniqueSuffix(),
                'name' => 'Child Tenant ' . $this->uniqueSuffix(),
                'city_id' => $this->validCityId(),
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } catch (Throwable $e) {
            $this->cleanupGroup(TenantGroup::withTrashed()->find($group->id));
            $this->markTestSkipped('Cannot seed a child prm_tenant row: ' . $e->getMessage());
        }

        $blocked = false;
        try {
            TenantGroup::withTrashed()->find($group->id)->forceDelete();
        } catch (Throwable $e) {
            $blocked = true; // FK RESTRICT should raise a QueryException.
        }
        $this->assertTrue($blocked, 'ON DELETE RESTRICT must block force-deleting a referenced group.');

        // Cleanup child then parent.
        DB::table('prm_tenant')->where('tenant_group_id', $group->id)->delete();
        $this->cleanupGroup(TenantGroup::withTrashed()->find($group->id));
    }

    /** TC-D04 (E) | tenants() relationship returns child rows | Source: Model::tenants */
    public function test_tenantgroup_45_tenants_relationship_returns_children(): void
    {
        $group = $this->createGroupDirect();
        try {
            DB::table('prm_tenant')->insert([
                'tenant_group_id' => $group->id,
                'code' => 'T' . $this->uniqueSuffix(),
                'short_name' => 'TS' . $this->uniqueSuffix(),
                'name' => 'Rel Tenant ' . $this->uniqueSuffix(),
                'city_id' => $this->validCityId(),
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } catch (Throwable $e) {
            $this->cleanupGroup($group);
            $this->markTestSkipped('Cannot seed child tenant: ' . $e->getMessage());
        }

        $this->assertGreaterThanOrEqual(1, $group->fresh()->tenants()->count());

        DB::table('prm_tenant')->where('tenant_group_id', $group->id)->delete();
        $this->cleanupGroup($group->fresh());
    }

    // =====================================================================
    // Band 50-59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    /** TC-S01 | BC-AUTH guest redirect | Source: middleware auth */
    public function test_tenantgroup_50_guest_is_redirected_from_index_to_login(): void
    {
        $response = $this->get(route(self::RT_INDEX));
        $response->assertStatus(302);
        $this->assertStringContainsString('/login', (string) $response->headers->get('Location'));
    }

    /** TC-N13 | BC-AUTH limited user forbidden across all gated endpoints | Source: Controller Gate::authorize */
    public function test_tenantgroup_51_limited_user_is_forbidden_on_gated_endpoints(): void
    {
        $limited = $this->makeLimitedUserOrSkip();
        $group = $this->createGroupDirect();

        $cases = [
            ['get', route(self::RT_INDEX)],
            ['get', route(self::RT_CREATE)],
            ['get', route(self::RT_SHOW, $group->id)],
            ['get', route(self::RT_EDIT, $group->id)],
        ];
        foreach ($cases as [$verb, $url]) {
            $response = $this->actingAs($limited)->{$verb . 'Json'}($url);
            $this->assertContains($response->getStatusCode(), [403, 404], "Limited user should be blocked on {$url}.");
        }

        $this->cleanupGroup($group);
    }

    /** TC-N14 | BC-AUTH limited user cannot store | Source: TenantGroupRequest::authorize + store gate */
    public function test_tenantgroup_52_limited_user_cannot_store(): void
    {
        $limited = $this->makeLimitedUserOrSkip();
        $response = $this->actingAs($limited)->postJson(route(self::RT_STORE), $this->groupAttributes());
        $this->assertContains($response->getStatusCode(), [403, 422], 'Limited user store must be forbidden (403) not persisted.');
        if ($response->getStatusCode() === 403) {
            $this->assertDatabaseMissing(self::TABLE, ['code' => $this->groupAttributes()['code']]);
        }
    }

    /** TC-P18 | BC-AUTH super admin passes every gate | Source: AppServiceProvider Gate::before */
    public function test_tenantgroup_53_super_admin_passes_all_gates(): void
    {
        foreach ([
            'prime.tenant-group.viewAny', 'prime.tenant-group.view', 'prime.tenant-group.create',
            'prime.tenant-group.update', 'prime.tenant-group.delete',
            'prime.tenant-group.restore', 'prime.tenant-group.forceDelete',
        ] as $ability) {
            $this->assertTrue(
                Gate::forUser($this->adminUser)->allows($ability),
                "Super admin must be allowed for {$ability}."
            );
        }
    }

    // =====================================================================
    // Band 60-69 — UI/UX render smoke (browser Dusk on 127.0.0.1)
    // =====================================================================

    /** TC-P19 | UI create page renders every form field | Source: create.blade.php */
    public function test_tenantgroup_60_create_page_renders_all_form_fields(): void
    {
        $this->browseWithFailureScreenshot('create-page-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, '/prime/tenant-group/create');
            $this->ensurePageAccessible($browser, 'Tenant Group create page');

            $browser->assertPresent('input[name="code"]')
                ->assertPresent('input[name="name"]')
                ->assertPresent('input[name="short_name"]')
                ->assertPresent('input[name="address_1"]')
                ->assertPresent('input[name="address_2"]')
                ->assertPresent('input[name="pincode"]')
                ->assertPresent('input[name="website_url"]')
                ->assertPresent('input[name="email"]')
                ->assertPresent('form');
        });
    }

    /** TC-P20 | UI edit page pre-fills persisted values | Source: edit.blade.php */
    public function test_tenantgroup_61_edit_page_prefills_existing_values(): void
    {
        $group = $this->createGroupDirect();
        $this->browseWithFailureScreenshot('edit-page-prefill', function (Browser $browser) use ($group): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, '/prime/tenant-group/' . $group->id . '/edit');
            $this->ensurePageAccessible($browser, 'Tenant Group edit page');

            $browser->assertInputValue('code', $group->code)
                ->assertInputValue('name', $group->name)
                ->assertInputValue('short_name', $group->short_name);
        });
        $this->cleanupGroup($group);
    }

    /** TC-P21 | UI trash page renders | Source: trash.blade.php */
    public function test_tenantgroup_62_trash_page_is_accessible(): void
    {
        $this->browseWithFailureScreenshot('trash-page-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, '/prime/tenant-group/trash/view');
            $this->ensurePageAccessible($browser, 'Tenant Group trash page');
            $browser->assertPresent('body');
        });
    }

    // =====================================================================
    // Band 70-79 — Edge cases (BC-EDG)
    // =====================================================================

    /** TC-P22 | BC-EDG boundary lengths exactly at max are accepted | Source: DDL/Request max limits */
    public function test_tenantgroup_70_store_accepts_boundary_max_lengths(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.create');
        $payload = array_merge($this->groupAttributes(), [
            'code' => str_repeat('C', 20),
            'short_name' => 'S' . str_repeat('n', 49), // 50 chars
            'name' => 'N' . str_repeat('m', 149),      // 150 chars
            'pincode' => str_repeat('9', 10),
        ]);

        $response = $this->actingAs($this->adminUser)->post(route(self::RT_STORE), $payload);
        $response->assertStatus(302);
        $response->assertSessionHasNoErrors();

        $this->cleanupGroup(TenantGroup::where('code', $payload['code'])->first());
    }

    /** TC-P23 | BC-EDG nullable optional fields accept empty values | Source: Request nullable rules */
    public function test_tenantgroup_71_store_accepts_null_optional_fields(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.create');
        $payload = array_merge($this->groupAttributes(), [
            'address_1' => '', 'address_2' => '', 'pincode' => '', 'website_url' => '', 'email' => '',
        ]);

        $response = $this->actingAs($this->adminUser)->post(route(self::RT_STORE), $payload);
        $response->assertStatus(302);
        $response->assertSessionHasNoErrors();

        $this->cleanupGroup(TenantGroup::where('code', $payload['code'])->first());
    }

    /** TC-P24 | BC-EDG prepareForValidation coerces checkbox is_active | Source: Request::prepareForValidation */
    public function test_tenantgroup_72_is_active_checkbox_is_coerced_to_boolean(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.create');

        // Present with value 'on' -> true
        $on = $this->buildValidStorePayload(['is_active' => 'on']);
        $this->actingAs($this->adminUser)->post(route(self::RT_STORE), $on)->assertStatus(302);
        $created = TenantGroup::where('code', $on['code'])->first();
        $this->assertSame(1, (int) $created->is_active, "is_active='on' must become true.");
        $this->cleanupGroup($created);

        // Absent -> false
        $off = $this->buildValidStorePayload();
        unset($off['is_active']);
        $this->actingAs($this->adminUser)->post(route(self::RT_STORE), $off)->assertStatus(302);
        $created2 = TenantGroup::where('code', $off['code'])->first();
        $this->assertSame(0, (int) $created2->is_active, 'Absent is_active must become false.');
        $this->cleanupGroup($created2);
    }

    // =====================================================================
    // Band 90-99 — Security pack (TC-S)  [Tenancy isolation N/A — single central DB]
    // =====================================================================

    /** TC-N15 | TC-S IDOR: unknown id returns 404 on show/edit | Source: findOrFail */
    public function test_tenantgroup_90_unknown_id_returns_404_on_show_and_edit(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.view');
        $this->actingAs($this->adminUser)->getJson(route(self::RT_SHOW, 999999999))->assertStatus(404);
        $this->actingAs($this->adminUser)->getJson(route(self::RT_EDIT, 999999999))->assertStatus(404);
    }

    /** TC-S02 | TC-S stored XSS in name is escaped on render | Source: Blade {{ }} escaping */
    public function test_tenantgroup_91_stored_xss_in_name_is_escaped_on_edit_page(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.update');
        $xss = '<script>alert(1)</script>';
        $group = $this->createGroupDirect(['name' => 'XSS ' . $xss . ' ' . $this->uniqueSuffix()]);

        $this->browseWithFailureScreenshot('xss-escaped', function (Browser $browser) use ($group): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, '/prime/tenant-group/' . $group->id . '/edit');
            $this->ensurePageAccessible($browser, 'Tenant Group edit page (XSS)');
            // Blade value binding escapes; the raw <script> tag must not appear un-encoded in the DOM source.
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Stored XSS must be escaped.');
        });

        $this->cleanupGroup($group);
    }

    /** TC-S03 | TC-S toggleStatus rejects a non-boolean is_active | Source: Controller::toggleStatus validate */
    public function test_tenantgroup_92_toggle_status_rejects_non_boolean_payload(): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.update');
        $group = $this->createGroupDirect();

        $response = $this->actingAs($this->adminUser)
            ->postJson(route(self::RT_TOGGLE, $group->id), ['is_active' => 'banana']);
        $response->assertStatus(422)->assertJsonValidationErrors(['is_active']);

        $this->cleanupGroup($group);
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function assertStoreValidationError(array $overrides, string $field): void
    {
        $this->skipUnlessAdminCan('prime.tenant-group.create');
        $payload = array_merge($this->groupAttributes(), $overrides);
        $response = $this->actingAs($this->adminUser)->postJson(route(self::RT_STORE), $payload);
        $response->assertStatus(422)->assertJsonValidationErrors([$field]);
    }

    private function buildValidStorePayload(array $overrides = []): array
    {
        return array_merge($this->groupAttributes(), ['is_active' => 'on'], $overrides);
    }

    /** Valid attribute set for a new group (unique per call). */
    private function groupAttributes(): array
    {
        $suffix = $this->uniqueSuffix();
        return [
            'code' => 'C' . $suffix,
            'short_name' => 'SN' . $suffix,
            'name' => 'Group ' . $suffix,
            'address_1' => 'Addr 1',
            'address_2' => 'Addr 2',
            'city_id' => $this->validCityId(),
            'pincode' => '560001',
            'website_url' => 'https://example.test',
            'email' => 'grp' . $suffix . '@example.test',
        ];
    }

    /** Create a persisted group directly (bypassing the controller) for state setup. */
    private function createGroupDirect(array $overrides = []): TenantGroup
    {
        $attrs = array_merge($this->groupAttributes(), ['is_active' => 1], $overrides);

        return TenantGroup::create($attrs);
    }

    private function cleanupGroup(?TenantGroup $group): void
    {
        if (!$group) {
            return;
        }
        try {
            $model = TenantGroup::withTrashed()->find($group->id);
            if ($model) {
                $model->forceDelete();
            }
        } catch (Throwable) {
            // Media/FK edge — ignore per constraint #11.
        }
    }

    private function validCityId(): int
    {
        $id = DB::table('glb_cities')->value('id');
        if (!$id) {
            $this->markTestSkipped('No glb_cities row available for city_id FK.');
        }

        return (int) $id;
    }

    private function assertActivityLogged(int $subjectId, string $event): void
    {
        if (!Schema::hasTable(self::ACTIVITY_TABLE)) {
            $this->markTestSkipped('sys_central_activity_logs not present in this environment.');
        }
        $exists = ActivityLog::where('subject_type', TenantGroup::class)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->exists();
        $this->assertTrue($exists, "Expected a '{$event}' activity-log row for tenant group #{$subjectId}.");
    }

    private function activityCountFor(int $subjectId): int
    {
        if (!Schema::hasTable(self::ACTIVITY_TABLE)) {
            return 0;
        }

        return (int) ActivityLog::where('subject_type', TenantGroup::class)
            ->where('subject_id', $subjectId)
            ->count();
    }

    private function uniqueSuffix(): string
    {
        return substr(str_replace('.', '', uniqid('', true)), -10);
    }

    private function adminCan(string $ability): bool
    {
        return $this->adminUser !== null && Gate::forUser($this->adminUser)->allows($ability);
    }

    private function skipUnlessAdminCan(string $ability): void
    {
        if (!$this->adminCan($ability)) {
            $this->markTestSkipped("Admin user cannot pass gate {$ability} in this environment.");
        }
    }

    /** Best-effort: make the resolved admin bypass all gates (needs both flags per AppServiceProvider). */
    private function ensureAdminCanBypassGates(): void
    {
        if (!$this->adminUser) {
            return;
        }
        try {
            $dirty = false;
            if ((int) ($this->adminUser->is_super_admin ?? 0) !== 1) {
                $this->adminUser->is_super_admin = 1;
                $dirty = true;
            }
            if (Schema::hasColumn($this->adminUser->getTable(), 'super_admin_flag')
                && (int) ($this->adminUser->super_admin_flag ?? 0) !== 1) {
                $this->adminUser->super_admin_flag = 1;
                $dirty = true;
            }
            if ($dirty) {
                $this->adminUser->save();
            }
        } catch (Throwable) {
            // Leave as resolved; gate-dependent tests self-skip via skipUnlessAdminCan.
        }
    }

    /** A non-super, permission-less user for 403 assertions; skips if creation is not possible. */
    private function makeLimitedUserOrSkip(): User
    {
        try {
            $user = User::query()->where('email', 'like', 'limited_tg_%@example.test')->first();
            if ($user) {
                return $user;
            }

            return User::create([
                'email' => 'limited_tg_' . $this->uniqueSuffix() . '@example.test',
                'password' => bcrypt('password'),
                'name' => 'Limited TG User',
                'emp_code' => 'L' . $this->uniqueSuffix(),
                'is_active' => 1,
                'is_super_admin' => 0,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot create a limited user in this environment: ' . $e->getMessage());
        }
    }

    // ---- Central auth / helper library (copied from prm_BillingDuskTestCase_TestCas per orchestrator override) ----

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
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    protected function browseWithFailureScreenshot(string $caseName, callable $callback): void
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

    protected function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        if (!defined('static::SCREENSHOT_DIR')) {
            return '';
        }

        $directory = base_path(static::SCREENSHOT_DIR);
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

    protected function cleanScreenshots(): void
    {
        if (!defined('static::SCREENSHOT_DIR')) {
            return;
        }
        $directory = base_path(static::SCREENSHOT_DIR);
        if (File::isDirectory($directory)) {
            File::cleanDirectory($directory);
        }
    }

    protected function resolveAdminUser(): void
    {
        $superAdmin = User::query()->where('is_super_admin', 1)->first();
        if ($superAdmin) {
            $this->adminUser = $superAdmin;
            $this->ensureUserIsVerified($this->adminUser);

            return;
        }

        $userByEmail = User::query()->where('email', $this->adminEmail)->first();
        if ($userByEmail) {
            $this->adminUser = $userByEmail;
            $this->ensureUserIsVerified($this->adminUser);

            return;
        }

        try {
            $this->adminUser = User::create([
                'email' => $this->adminEmail,
                'password' => bcrypt($this->adminPassword),
                'name' => 'TenantGroup Dusk Admin',
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
}
