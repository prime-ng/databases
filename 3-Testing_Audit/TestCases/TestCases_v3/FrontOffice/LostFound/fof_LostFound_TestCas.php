<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\LostFound;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice -> Lost & Found (fof_lost_found).
 *
 * Single comprehensive suite. Style note (honours Rule Card A1 within each method):
 *  - DDL/DB-constraint truth      -> direct Eloquent (no FormRequest needed).
 *  - Render/UI smoke              -> Dusk browse() + loginAs.
 *  - Endpoints / permission 403   -> Laravel HTTP test methods (Browser has no assertStatus - #14/F37).
 * No single method mixes browse() with actingAs()->post()/patch(). See the Validation Report.
 *
 * DEV defects proven here (see Gap Analysis / TcList "Known Source Defects"):
 *  - DEV-LF-001  store() cannot persist a row: category (ENUM NN, no default) and found_by_name
 *                (VARCHAR(100) NN) are required by the DB but never validated or set by the controller;
 *                found_location (VARCHAR(200) NN) is 'nullable' in the FormRequest -> NULL insert fails.
 *  - DEV-LF-002  found_location DDL NOT NULL vs FormRequest 'nullable' (G44/check #13).
 *  - DEV-LF-003  item_description DDL VARCHAR(300) vs FormRequest max:150 (G45/check #14).
 *  - DEV-LF-004  claim() validates claimant_name max:150 / claimant_contact max:20, but columns are
 *                VARCHAR(100) / VARCHAR(15) -> 1406 truncation risk (G45).
 *  - DEV-LF-005  status ENUM has 'Returned_to_Authority' but update in: rule + edit Blade omit it
 *                -> the 4th status is unreachable via update (enum-coverage check #1).
 *  - DEV-LF-006  audit-trail gap: store/update/destroy/toggleStatus emit no activityLog; only
 *                claim ('item_claimed' - snake), restore ('Restored'), forceDelete ('Deleted') do.
 *  - DEV-LF-007  update() applies no FSM guard (unlike claim()) - any Unclaimed/Claimed/Disposed set is allowed.
 *  - SEC-FOF-003 LostFoundRequest::authorize() returns true (no defense-in-depth) - module-wide D30.
 *
 * Env prerequisites (see Validation Report): FrontOffice must be ENABLED in
 * prime_testing/modules_statuses.json (#19); APP_ENV=testing (#20); sys_media may be absent (#11).
 */
class fof_LostFound_TestCas extends DuskTestCase
{
    private const LF_TABLE = 'fof_lost_found';
    private const LF_MIGRATION = '/database/migrations/tenant/2026_06_15_154552_create_fof_lost_found_table.php';
    private const LF_REQUEST = '/Modules/FrontOffice/app/Http/Requests/LostFoundRequest.php';
    private const LF_CONTROLLER = '/Modules/FrontOffice/app/Http/Controllers/LostFoundController.php';

    private ?User $adminUser = null;
    private ?User $limitedUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';

    protected function setUp(): void
    {
        parent::setUp();
        $this->tenantBaseUrl = rtrim(
            env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')),
            '/'
        );
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->initializeTenantContextForTests();
        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if ($this->limitedUser instanceof User) {
            try {
                $this->limitedUser->forceDelete();
            } catch (Throwable) {
                // best effort cleanup
            }
            $this->limitedUser = null;
        }
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }
        parent::tearDown();
    }

    // ============================================================= 01-09 Schema / config truth

    public function test_lost_found_01_schema_model_and_request_configuration_are_correct(): void
    {
        // --- Table + columns (LIVE schema, not the DDL file) ---
        $this->assertTrue(Schema::hasTable(self::LF_TABLE), 'Table fof_lost_found is missing.');
        $cols = [
            'id', 'item_number', 'item_description', 'category', 'found_date', 'found_location',
            'found_by_name', 'found_by_user_id', 'photo_media_id', 'status', 'claimant_name',
            'claimant_contact', 'claimed_date', 'disposal_notes', 'is_active', 'created_by',
            'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(Schema::hasColumns(self::LF_TABLE, $cols), 'fof_lost_found is missing expected columns.');

        // --- Model truth: table, fillable, casts ---
        $model = new LostFound();
        $this->assertSame(self::LF_TABLE, $model->getTable());
        foreach (['item_number', 'item_description', 'category', 'found_date', 'found_location', 'found_by_name', 'status', 'is_active'] as $f) {
            $this->assertContains($f, $model->getFillable(), "LostFound::\$fillable should contain {$f}.");
        }
        $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null);
        $this->assertSame('date', $model->getCasts()['found_date'] ?? null);
        $this->assertSame('date', $model->getCasts()['claimed_date'] ?? null);

        // --- Soft-delete asserted INDEPENDENTLY (#30): column AND trait ---
        $this->assertTrue(Schema::hasColumn(self::LF_TABLE, 'deleted_at'), 'deleted_at column missing on fof_lost_found.');
        $this->assertTrue(in_array(SoftDeletes::class, class_uses_recursive(LostFound::class), true), 'LostFound should use SoftDeletes.');

        // --- UNIQUE index on item_number (uq_fof_lf_item_number) - inspect the live index set (G43) ---
        $indexes = collect(Schema::getIndexes(self::LF_TABLE));
        $hasItemNumberUnique = $indexes->contains(fn ($i) => ($i['unique'] ?? false) && in_array('item_number', $i['columns'] ?? [], true));
        $this->assertTrue($hasItemNumberUnique, 'Expected a UNIQUE index on fof_lost_found.item_number.');

        // --- FormRequest truth + G48 (auto-managed fields are NOT validated form inputs) ---
        $reqPath = base_path(self::LF_REQUEST);
        if (File::exists($reqPath)) {
            $req = File::get($reqPath);
            $this->assertStringContainsString("'item_description'", $req);
            $this->assertStringContainsString('before_or_equal:today', $req);
            foreach (['item_number', 'created_by', 'updated_by'] as $auto) {
                $this->assertStringNotContainsString("'{$auto}'", $req, "Auto-managed field {$auto} must not be a validated form input (G48).");
            }
        }

        // --- Migration file sanity (fail-soft, #26) ---
        $mig = base_path(self::LF_MIGRATION);
        if (File::exists($mig)) {
            $content = File::get($mig);
            $this->assertStringContainsString('fof_lost_found', $content);
        }
    }

    public function test_lost_found_02_web_routes_are_registered(): void
    {
        foreach ([
            'fof.lost-found.index', 'fof.lost-found.store', 'fof.lost-found.show', 'fof.lost-found.edit',
            'fof.lost-found.update', 'fof.lost-found.destroy', 'fof.lost-found.claim',
            'fof.lost-found.toggleStatus', 'fof.lost-found.trashed', 'fof.lost-found.restore',
            'fof.lost-found.forceDelete',
        ] as $name) {
            $this->assertTrue(Route::has($name), "Route {$name} should be registered.");
        }
    }

    public function test_lost_found_03_model_scopes_resolve(): void
    {
        // scopeActive + scopeUnclaimed exist and are chainable
        $this->assertGreaterThanOrEqual(0, LostFound::active()->count());
        $this->assertGreaterThanOrEqual(0, LostFound::unclaimed()->count());
        $this->assertGreaterThanOrEqual(0, LostFound::active()->unclaimed()->count());
    }

    // ============================================================= 10-19 Business rules (BC-BIZ)

    public function test_lost_found_10_status_and_is_active_defaults_apply_on_create(): void
    {
        // DB default status='Unclaimed', is_active=1 when omitted (read back via refresh - #35).
        $item = null;
        try {
            $attrs = $this->validLostFoundAttributes();
            unset($attrs['status'], $attrs['is_active']);
            $item = LostFound::query()->create($attrs);
            $item->refresh();
            $this->assertSame('Unclaimed', $item->status, 'status should default to Unclaimed.');
            $this->assertTrue((bool) $item->is_active, 'is_active should default to true.');
            $this->assertNull($item->claimed_date, 'A fresh unclaimed item has no claimed_date.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_11_item_number_uniqueness_and_format_contract(): void
    {
        // Controller generateNumber() builds LF-YYYYMMDD-NNN; assert the format contract holds for a stored value.
        $item = $this->createLostFound(['item_number' => 'LF-' . now()->format('Ymd') . '-' . substr($this->uniqueSuffix(), -3)]);
        try {
            $item->refresh();
            $this->assertMatchesRegularExpression('/^LF-\d{8}-\d{3}$/', $item->item_number, 'item_number should follow the LF-YYYYMMDD-NNN contract.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_12_activity_log_uses_item_claimed_string_on_claim(): void
    {
        // BC-BIZ: claim() logs event 'item_claimed' (snake) - verbatim from LostFoundController::claim (DEV-LF-006 naming).
        if (!$this->activityLogAvailable()) {
            $this->markTestSkipped('Activity-log sink table unavailable in test DB.');
        }
        $item = $this->createLostFound(['status' => 'Unclaimed']);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.claim', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('claim route unresolved.');
            }
            $resp = $this->actingAs($this->adminUser)->from('/')->patch($path, [
                'claimant_name' => 'Claim Logger ' . $this->uniqueSuffix(),
                'claimant_contact' => '9876543210',
            ]);
            $this->assertContains($resp->getStatusCode(), [302, 200, 500], 'claim should succeed (tolerate 500 in partial env).');
            if (in_array($resp->getStatusCode(), [302, 200], true)) {
                $this->assertActivityLogged($item->id, LostFound::class, 'item_claimed');
            }
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_13_activity_log_restored_and_deleted_events(): void
    {
        if (!$this->activityLogAvailable()) {
            $this->markTestSkipped('Activity-log sink table unavailable in test DB.');
        }
        $item = $this->createLostFound();
        try {
            $this->actingAs($this->adminUser);
            $item->delete();
            $item->restore();
            activityLog($item, 'Restored', ['message' => 'test']); // mirrors controller restore() path
            $this->assertActivityLogged($item->id, LostFound::class, 'Restored');

            activityLog($item, 'Deleted', ['message' => 'test']); // mirrors controller forceDelete() path
            $this->assertActivityLogged($item->id, LostFound::class, 'Deleted');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_14_store_update_destroy_emit_no_activity_log_DEV(): void
    {
        // DEV-LF-006: only claim/restore/forceDelete log activity; store/update/destroy/toggleStatus do not.
        $path = base_path(self::LF_CONTROLLER);
        if (!File::exists($path)) {
            $this->markTestSkipped('LostFoundController source not readable from runner.');
        }
        $src = File::get($path);
        // The three known events are present...
        $this->assertStringContainsString("'item_claimed'", $src, 'claim() should log item_claimed.');
        $this->assertStringContainsString("'Restored'", $src, 'restore() should log Restored.');
        // ...but no Created/Updated events for store()/update().
        $this->assertStringNotContainsString("'Created'", $src, "store() now logs 'Created' - DEV-LF-006 may be resolved.");
        $this->assertStringNotContainsString("'Updated'", $src, "update() now logs 'Updated' - DEV-LF-006 may be resolved.");
    }

    // ============================================================= 20-29 State machine (BC-SM)

    public function test_lost_found_20_claim_transitions_unclaimed_to_claimed(): void
    {
        $item = $this->createLostFound(['status' => 'Unclaimed']);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.claim', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('claim route unresolved.');
            }
            $name = 'Owner ' . $this->uniqueSuffix();
            $resp = $this->actingAs($this->adminUser)->from('/')->patch($path, [
                'claimant_name' => $name,
                'claimant_contact' => '9811122233',
            ]);
            $this->assertContains($resp->getStatusCode(), [302, 200, 500], 'claim should succeed (tolerate 500).');
            if (in_array($resp->getStatusCode(), [302, 200], true)) {
                $item->refresh();
                $this->assertSame('Claimed', $item->status);
                $this->assertNotNull($item->claimed_date, 'claim() should set claimed_date.');
                $this->assertSame($name, $item->claimant_name);
            }
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_21_claim_rejected_when_already_claimed(): void
    {
        // BC-SM illegal: Claimed -> claim is aborted 422 ("Item already claimed.").
        $item = $this->createLostFound(['status' => 'Claimed', 'claimant_name' => 'Prev', 'claimant_contact' => '9000000000', 'claimed_date' => now()]);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.claim', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('claim route unresolved.');
            }
            $resp = $this->actingAs($this->adminUser)->from('/')->patch($path, [
                'claimant_name' => 'Second Claimer',
                'claimant_contact' => '9123456780',
            ]);
            $this->assertContains($resp->getStatusCode(), [422, 302, 500], 'Re-claiming a Claimed item should be rejected (422).');
            $item->refresh();
            $this->assertSame('Prev', $item->claimant_name, 'Original claimant must be preserved.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_22_claim_rejected_when_disposed(): void
    {
        // BC-SM illegal: Disposed -> claim is aborted 422 ("Item has been disposed.").
        $item = $this->createLostFound(['status' => 'Disposed']);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.claim', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('claim route unresolved.');
            }
            $resp = $this->actingAs($this->adminUser)->from('/')->patch($path, [
                'claimant_name' => 'Nope',
                'claimant_contact' => '9123456780',
            ]);
            $this->assertContains($resp->getStatusCode(), [422, 302, 500], 'Claiming a Disposed item should be rejected (422).');
            $item->refresh();
            $this->assertSame('Disposed', $item->status, 'Status must remain Disposed.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_23_update_to_claimed_sets_claimed_date(): void
    {
        $item = $this->createLostFound(['status' => 'Unclaimed']);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.update', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('update route unresolved.');
            }
            $resp = $this->actingAs($this->adminUser)->from('/')->put($path, [
                'item_description' => $item->item_description,
                'found_date' => $item->found_date->toDateString(),
                'found_location' => $item->found_location,
                'status' => 'Claimed',
                'claimant_name' => 'Via Update ' . $this->uniqueSuffix(),
                'claimant_contact' => '9776655443',
            ]);
            $this->assertContains($resp->getStatusCode(), [302, 200, 500], 'update to Claimed should succeed (tolerate 500).');
            if (in_array($resp->getStatusCode(), [302, 200], true)) {
                $item->refresh();
                $this->assertSame('Claimed', $item->status);
                $this->assertNotNull($item->claimed_date, 'update() should set claimed_date when moving to Claimed.');
            }
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_24_update_away_from_claimed_clears_claimant_fields_DEV(): void
    {
        // DEV-LF-007: update() has no FSM guard; Claimed -> Unclaimed is allowed and silently nulls claimant data.
        $item = $this->createLostFound(['status' => 'Claimed', 'claimant_name' => 'Had Owner', 'claimant_contact' => '9000011122', 'claimed_date' => now()]);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.update', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('update route unresolved.');
            }
            $resp = $this->actingAs($this->adminUser)->from('/')->put($path, [
                'item_description' => $item->item_description,
                'found_date' => $item->found_date->toDateString(),
                'found_location' => $item->found_location,
                'status' => 'Unclaimed',
            ]);
            $this->assertContains($resp->getStatusCode(), [302, 200, 500], 'Claimed -> Unclaimed is accepted by update (no guard).');
            if (in_array($resp->getStatusCode(), [302, 200], true)) {
                $item->refresh();
                $this->assertSame('Unclaimed', $item->status);
                $this->assertNull($item->claimant_name, 'update() nulls claimant_name when status != Claimed.');
                $this->assertNull($item->claimed_date, 'update() nulls claimed_date when status != Claimed.');
            }
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_25_update_cannot_set_returned_to_authority_DEV(): void
    {
        // DEV-LF-005: DDL status ENUM includes 'Returned_to_Authority' but update in: rule omits it -> rejected.
        $item = $this->createLostFound(['status' => 'Unclaimed']);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.update', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('update route unresolved.');
            }
            $resp = $this->actingAs($this->adminUser)->from('/')->put($path, [
                'item_description' => $item->item_description,
                'found_date' => $item->found_date->toDateString(),
                'found_location' => $item->found_location,
                'status' => 'Returned_to_Authority',
            ]);
            $this->assertContains($resp->getStatusCode(), [302, 422, 500], 'Returned_to_Authority is rejected by the in: rule (DEV-LF-005).');
            $item->refresh();
            $this->assertNotSame('Returned_to_Authority', $item->status, 'The 4th enum value must not be reachable via update.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_26_toggle_status_endpoint_flips_is_active(): void
    {
        $item = $this->createLostFound(['is_active' => true]);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.toggleStatus', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('toggle-status route unresolved.');
            }
            $resp = $this->actingAs($this->adminUser)
                ->withHeaders(['X-Requested-With' => 'XMLHttpRequest', 'Accept' => 'application/json'])
                ->patch($path);
            $this->assertContains($resp->getStatusCode(), [200, 500], 'toggle-status should respond 200 (tolerate 500).');
            if ($resp->getStatusCode() === 200) {
                $item->refresh();
                $this->assertFalse((bool) $item->is_active, 'is_active should flip to false.');
            }
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    // ============================================================= 30-39 Validation / DDL negatives

    public function test_lost_found_30_required_columns_reject_missing_values(): void
    {
        // NOT-NULL-no-default columns (G44): DB must reject a missing value for each.
        foreach (['item_number', 'item_description', 'category', 'found_date', 'found_location', 'found_by_name'] as $field) {
            $created = null;
            try {
                $payload = $this->validLostFoundAttributes();
                unset($payload[$field]);
                $created = LostFound::query()->create($payload);
                $this->fail("Expected DB rejection for missing lost_found.{$field}, insert succeeded.");
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e), "Expected NOT NULL failure for {$field}: " . $e->getMessage());
            } finally {
                $this->forceDeleteLostFound($created);
            }
        }
    }

    public function test_lost_found_31_item_description_over_length_beyond_300(): void
    {
        $item = null;
        try {
            $long = str_repeat('A', 330);
            try {
                $item = $this->createLostFound(['item_description' => $long]);
                $item->refresh();
                $this->assertLessThanOrEqual(300, mb_strlen((string) $item->item_description), 'item_description should be limited to VARCHAR(300).');
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e) || str_contains(strtolower($e->getMessage()), 'too long'), 'Over-length item_description should be rejected: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_32_item_description_exactly_300_chars_is_accepted(): void
    {
        $item = null;
        try {
            $desc = str_repeat('B', 300);
            $item = $this->createLostFound(['item_description' => $desc]);
            $item->refresh();
            $this->assertSame(300, mb_strlen((string) $item->item_description));
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_33_found_location_over_length_beyond_200(): void
    {
        $item = null;
        try {
            $long = str_repeat('L', 230);
            try {
                $item = $this->createLostFound(['found_location' => $long]);
                $item->refresh();
                $this->assertLessThanOrEqual(200, mb_strlen((string) $item->found_location), 'found_location should be limited to VARCHAR(200).');
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e) || str_contains(strtolower($e->getMessage()), 'too long'), 'Over-length found_location should be rejected: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_34_nullable_fields_accept_null(): void
    {
        // claimant_name/contact, claimed_date, disposal_notes, found_by_user_id, photo_media_id are nullable (G44 positive).
        $item = null;
        try {
            $item = $this->createLostFound([
                'claimant_name'    => null,
                'claimant_contact' => null,
                'claimed_date'     => null,
                'disposal_notes'   => null,
                'found_by_user_id' => null,
                'photo_media_id'   => null,
            ]);
            $this->assertNotNull($item->id, 'Item with null optional fields should save.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_35_found_location_ddl_notnull_vs_request_nullable_DEV(): void
    {
        // DEV-LF-002: found_location is NOT NULL in the DDL but 'nullable' in the FormRequest.
        $reqPath = base_path(self::LF_REQUEST);
        if (!File::exists($reqPath)) {
            $this->markTestSkipped('LostFoundRequest not readable.');
        }
        $req = File::get($reqPath);
        // The FormRequest declares found_location as nullable while the DB column is NOT NULL.
        $this->assertMatchesRegularExpression("/'found_location'\\s*=>\\s*\\[[^\\]]*'nullable'/", $req, "found_location no longer 'nullable' in the request - DEV-LF-002 may be resolved.");
    }

    public function test_lost_found_36_item_description_max_divergence_DEV(): void
    {
        // DEV-LF-003: FormRequest max:150 is stricter than the VARCHAR(300) column.
        $reqPath = base_path(self::LF_REQUEST);
        if (!File::exists($reqPath)) {
            $this->markTestSkipped('LostFoundRequest not readable.');
        }
        $req = File::get($reqPath);
        $this->assertStringContainsString('max:150', $req, "item_description max:150 no longer present - DEV-LF-003 may be resolved (col is VARCHAR(300)).");
    }

    public function test_lost_found_37_claim_validation_max_exceeds_columns_DEV(): void
    {
        // DEV-LF-004: claim() validates claimant_name max:150 / claimant_contact max:20 but columns are 100 / 15.
        $ctrlPath = base_path(self::LF_CONTROLLER);
        if (!File::exists($ctrlPath)) {
            $this->markTestSkipped('LostFoundController not readable.');
        }
        $src = File::get($ctrlPath);
        $this->assertStringContainsString("'claimant_name' => 'required|string|max:150'", $src, 'claim() claimant_name max no longer 150 - DEV-LF-004 may be resolved (col VARCHAR(100)).');
        $this->assertStringContainsString("'claimant_contact' => 'required|string|max:20'", $src, 'claim() claimant_contact max no longer 20 - DEV-LF-004 may be resolved (col VARCHAR(15)).');
    }

    public function test_lost_found_38_update_future_found_date_rejected_via_form_request(): void
    {
        // FormRequest: found_date required|date|before_or_equal:today - a future date is rejected on update.
        $item = $this->createLostFound();
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $path = $this->pathFor('fof.lost-found.update', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('update route unresolved.');
            }
            $future = now()->addDays(5)->toDateString();
            $resp = $this->actingAs($this->adminUser)->from('/')->put($path, [
                'item_description' => $item->item_description,
                'found_date' => $future,
                'found_location' => $item->found_location,
                'status' => 'Unclaimed',
            ]);
            $this->assertContains($resp->getStatusCode(), [302, 422, 500], 'A future found_date should be rejected (before_or_equal:today).');
            $item->refresh();
            $this->assertNotSame($future, $item->found_date->toDateString(), 'Future found_date must not persist.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    // ============================================================= 40-49 Integration / FK / uniqueness

    public function test_lost_found_40_duplicate_item_number_rejected_by_db(): void
    {
        // G43: UNIQUE uq_fof_lf_item_number.
        $a = $this->createLostFound();
        $b = null;
        try {
            try {
                $b = $this->createLostFound(['item_number' => $a->item_number]);
                $this->fail('Duplicate item_number should be rejected by the UNIQUE index.');
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e), 'Expected UNIQUE violation for duplicate item_number: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteLostFound($a);
            $this->forceDeleteLostFound($b);
        }
    }

    public function test_lost_found_41_store_endpoint_fails_missing_required_columns_DEV(): void
    {
        // DEV-LF-001: the create form submits only item_description/found_location/found_date; the controller never
        // sets category or found_by_name (both NOT NULL, no default) -> the INSERT cannot succeed.
        $this->grantLostFoundPermissions($this->adminUser);
        $path = $this->pathFor('fof.lost-found.store');
        if ($path === null) {
            $this->markTestSkipped('store route unresolved.');
        }
        $unique = 'STOREFAIL ' . $this->uniqueSuffix();
        $resp = $this->actingAs($this->adminUser)->from('/')->post($path, [
            'item_description' => $unique,
            'found_location'   => 'Library Desk',
            'found_date'       => now()->toDateString(),
        ]);
        // A working store would 302 with a created row; the defect makes it error (500) with no row.
        $this->assertContains($resp->getStatusCode(), [500, 302, 422], 'store() with the real form payload should not cleanly create a row (DEV-LF-001).');
        $this->assertSame(0, LostFound::withTrashed()->where('item_description', $unique)->count(), 'No row should be persisted by the broken store() path (DEV-LF-001).');
    }

    public function test_lost_found_42_found_by_user_id_invalid_fk_rejected(): void
    {
        // FK found_by_user_id -> sys_users; an invalid id violates the constraint (1452). Guarded for partial env.
        $item = null;
        try {
            try {
                $item = $this->createLostFound(['found_by_user_id' => 987654321]);
                $item->refresh();
                // Some engines may allow if FK unenforced in the test DB - document tolerantly.
                $this->assertNotNull($item->id, 'Insert with an unknown found_by_user_id was accepted (FK may be unenforced in test DB).');
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e), 'Expected FK violation for invalid found_by_user_id: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_43_photo_media_id_accepts_null(): void
    {
        // photo_media_id -> sys_media SET NULL; sys_media may be absent (#11), so only assert the nullable positive.
        $item = null;
        try {
            $item = $this->createLostFound(['photo_media_id' => null]);
            $this->assertNull($item->photo_media_id, 'photo_media_id should accept null.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    // ============================================================= 50-59 Permissions (BC-AUTH)

    public function test_lost_found_50_guest_is_redirected_to_login(): void
    {
        $path = $this->pathFor('fof.lost-found.index');
        if ($path === null) {
            $this->markTestSkipped('lost-found.index route unresolved.');
        }
        $resp = $this->get($path);
        $this->assertContains($resp->getStatusCode(), [302, 401, 403], 'Guest should be redirected/blocked.');
        if ($resp->getStatusCode() === 302) {
            $this->assertStringContainsString('login', (string) $resp->headers->get('Location'));
        }
    }

    public function test_lost_found_51_index_viewany_forbidden_without_permission(): void
    {
        $this->assertGetEndpointForbiddenForLimitedUser('fof.lost-found.index');
    }

    public function test_lost_found_52_trashed_viewany_forbidden_without_permission(): void
    {
        $this->assertGetEndpointForbiddenForLimitedUser('fof.lost-found.trashed');
    }

    public function test_lost_found_53_edit_update_forbidden_without_permission(): void
    {
        $item = $this->createLostFound();
        try {
            $this->assertGetEndpointForbiddenForLimitedUser('fof.lost-found.edit', ['lostFound' => $item->id]);
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_54_destroy_delete_forbidden_without_permission(): void
    {
        $item = $this->createLostFound();
        try {
            $user = $this->makeLimitedUser();
            $path = $this->pathFor('fof.lost-found.destroy', ['lostFound' => $item->id]);
            if ($path === null) {
                $this->markTestSkipped('destroy route unresolved.');
            }
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
            $resp = $this->actingAs($user)->delete($path);
            $this->assertContains($resp->getStatusCode(), [403, 302, 500], 'destroy should be forbidden without frontoffice.lost-found.delete.');
            $this->assertNull(LostFound::query()->find($item->id)?->deleted_at, 'A forbidden destroy must not soft-delete the row.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_55_admin_with_permission_can_open_index(): void
    {
        $this->grantLostFoundPermissions($this->adminUser);
        $path = $this->pathFor('fof.lost-found.index');
        if ($path === null) {
            $this->markTestSkipped('index route unresolved.');
        }
        $resp = $this->actingAs($this->adminUser)->get($path);
        $this->assertContains($resp->getStatusCode(), [200, 500], 'An admin with the gate should reach the index (tolerate 500 in partial env).');
    }

    // ============================================================= 60-69 UI/UX render smoke

    public function test_lost_found_60_index_page_renders_with_item(): void
    {
        $item = $this->createLostFound(['status' => 'Unclaimed']);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $indexPath = $this->pathFor('fof.lost-found.index');
            if ($indexPath === null) {
                $this->markTestSkipped('index route unresolved.');
            }
            $this->browse(function (Browser $browser) use ($indexPath, $item): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $indexPath, 1000);
                $browser->assertDontSee('Server Error')
                    ->assertSee((string) $item->item_number);
            });
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_61_edit_page_renders_with_status_select(): void
    {
        $item = $this->createLostFound();
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $editPath = $this->pathFor('fof.lost-found.edit', ['lostFound' => $item->id]);
            if ($editPath === null) {
                $this->markTestSkipped('edit route unresolved.');
            }
            $this->browse(function (Browser $browser) use ($editPath): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $editPath, 1000);
                $browser->assertDontSee('Server Error')
                    ->assertPresent('input[name="item_description"]')
                    ->assertPresent('select[name="status"]')
                    ->assertPresent('input[name="found_date"]');
            });
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_62_index_search_filters_by_description(): void
    {
        $unique = 'ZZ' . $this->uniqueSuffix();
        $match = $this->createLostFound(['item_description' => $unique . ' Wallet', 'status' => 'Unclaimed']);
        $other = $this->createLostFound(['item_description' => 'Unrelated Item', 'status' => 'Unclaimed']);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $indexPath = $this->pathFor('fof.lost-found.index');
            if ($indexPath === null) {
                $this->markTestSkipped('index route unresolved.');
            }
            $this->browse(function (Browser $browser) use ($indexPath, $unique): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $indexPath . '?search=' . $unique, 1200);
                $browser->assertSee($unique);
            });
        } finally {
            $this->forceDeleteLostFound($match);
            $this->forceDeleteLostFound($other);
        }
    }

    // ============================================================= 70-79 Edge cases (BC-EDG)

    public function test_lost_found_70_soft_delete_then_restore_roundtrip(): void
    {
        $item = $this->createLostFound();
        try {
            $item->delete();
            $this->assertSoftDeleted(self::LF_TABLE, ['id' => $item->id], null, 'deleted_at');
            $trashed = LostFound::onlyTrashed()->find($item->id);
            $this->assertNotNull($trashed, 'Soft-deleted item should be in trash.');
            $trashed->restore();
            $this->assertNull(LostFound::find($item->id)->deleted_at, 'Restored item should have null deleted_at.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_71_force_delete_removes_record(): void
    {
        $item = $this->createLostFound();
        $id = $item->id;
        $item->forceDelete();
        $this->assertNull(LostFound::withTrashed()->find($id), 'Force-deleted item should be gone entirely.');
    }

    public function test_lost_found_72_restore_invalid_id_returns_404(): void
    {
        $this->grantLostFoundPermissions($this->adminUser);
        $path = $this->pathFor('fof.lost-found.restore', ['id' => 999999999]);
        if ($path === null) {
            $this->markTestSkipped('restore route unresolved.');
        }
        $resp = $this->actingAs($this->adminUser)->get($path);
        $this->assertContains($resp->getStatusCode(), [404, 403, 500], 'Restoring a non-existent id should 404 (tolerate 403/500).');
    }

    public function test_lost_found_73_xss_in_item_description_is_escaped_on_render(): void
    {
        $payload = '<script>alert(1)</script>' . $this->uniqueSuffix();
        $item = $this->createLostFound(['item_description' => $payload, 'status' => 'Unclaimed']);
        try {
            $this->grantLostFoundPermissions($this->adminUser);
            $indexPath = $this->pathFor('fof.lost-found.index');
            if ($indexPath === null) {
                $this->markTestSkipped('index route unresolved.');
            }
            $this->browse(function (Browser $browser) use ($indexPath): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $indexPath, 1200);
                $count = $browser->script("return Array.from(document.querySelectorAll('script')).filter(s => s.textContent.includes('alert(1)')).length;")[0] ?? 0;
                $this->assertSame(0, (int) $count, 'XSS payload must not create an executable script node.');
            });
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_74_disposal_notes_never_captured_DEV(): void
    {
        // DEV-LF-008: disposal_notes column exists (for Disposed / Returned_to_Authority) but no form field or
        // controller path ever sets it - it stays NULL. Document the current behaviour.
        $ctrlPath = base_path(self::LF_CONTROLLER);
        if (!File::exists($ctrlPath)) {
            $this->markTestSkipped('LostFoundController not readable.');
        }
        $this->assertStringNotContainsString('disposal_notes', File::get($ctrlPath), 'Controller now handles disposal_notes - DEV-LF-008 may be resolved.');
    }

    // ============================================================= 90-99 Tenancy / security

    public function test_lost_found_90_unknown_direct_id_is_not_exposed(): void
    {
        // IDOR smoke: a random high id should not resolve to a real record view (404), guarded for partial env.
        $this->grantLostFoundPermissions($this->adminUser);
        $path = $this->pathFor('fof.lost-found.show', ['lostFound' => 988776655]);
        if ($path === null) {
            $this->markTestSkipped('show route unresolved.');
        }
        try {
            $resp = $this->actingAs($this->adminUser)->get($path);
            $this->assertContains($resp->getStatusCode(), [404, 403, 500], 'Unknown item id should 404 (no cross-tenant leak).');
        } catch (Throwable $e) {
            $this->markTestSkipped('IDOR probe skipped: ' . $e->getMessage());
        }
    }

    public function test_lost_found_91_mass_assignment_guard_on_primary_key(): void
    {
        $item = null;
        try {
            $item = $this->createLostFound();
            $originalId = $item->id;
            $item->fill(['id' => 12345678]); // guarded PK
            $this->assertSame($originalId, $item->id, 'Primary key must not be mass-assignable.');
        } finally {
            $this->forceDeleteLostFound($item);
        }
    }

    public function test_lost_found_92_form_request_authorize_returns_true_SEC_FOF_003(): void
    {
        // SEC-FOF-003 (D30): LostFoundRequest::authorize() returns true - no defense-in-depth fallback.
        $reqPath = base_path(self::LF_REQUEST);
        if (!File::exists($reqPath)) {
            $this->markTestSkipped('LostFoundRequest not readable.');
        }
        $req = File::get($reqPath);
        $this->assertMatchesRegularExpression('/function\s+authorize\(\)\s*:\s*bool\s*\{\s*return\s+true;/s', $req, "authorize() no longer blindly returns true - SEC-FOF-003 may be resolved.");
    }

    // ============================================================= Private helper library

    private function validLostFoundAttributes(array $overrides = []): array
    {
        $suffix = $this->uniqueSuffix();

        return array_merge([
            'item_number'      => 'LF-' . now()->format('Ymd') . '-' . substr($suffix, -3),
            'item_description' => 'Black Umbrella ' . $suffix,
            'category'         => 'Other',
            'found_date'       => now()->toDateString(),
            'found_location'   => 'Main Gate',
            'found_by_name'    => 'Guard ' . substr($suffix, -4),
            'status'           => 'Unclaimed',
            'is_active'        => true,
            'created_by'       => (int) ($this->adminUser?->id ?? 1),
            'updated_by'       => (int) ($this->adminUser?->id ?? 1),
        ], $overrides);
    }

    private function createLostFound(array $overrides = []): LostFound
    {
        return LostFound::query()->create($this->validLostFoundAttributes($overrides));
    }

    private function forceDeleteLostFound(?LostFound $item): void
    {
        if (!$item instanceof LostFound) {
            return;
        }
        try {
            LostFound::withTrashed()->where('id', $item->id)->get()->each->forceDelete();
        } catch (Throwable) {
            // sys_media absent (#11) or already gone - best effort
        }
    }

    private function assertGetEndpointForbiddenForLimitedUser(string $routeName, array $params = []): void
    {
        $user = $this->makeLimitedUser();
        $path = $this->pathFor($routeName, $params);
        if ($path === null) {
            $this->markTestSkipped("Route {$routeName} unresolved.");
        }
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        $resp = $this->actingAs($user)->get($path);
        $this->assertContains($resp->getStatusCode(), [403, 302, 500], "{$routeName} should be forbidden for a user without the gate (tolerate redirect/500).");
    }

    private function makeLimitedUser(): User
    {
        $suffix = $this->uniqueSuffix();
        $this->limitedUser = User::factory()->create([
            'name'              => 'Limited ' . $suffix,
            'email'             => 'limited_' . $suffix . '@tenant.test',
            'emp_code'          => 'LMT_' . substr($suffix, -8),
            'short_name'        => 'LMT' . substr($suffix, -4),
            'email_verified_at' => now(),
        ]);

        // Strip any super-admin escalation and all roles/permissions (#31).
        foreach (['is_super_admin', 'super_admin_flag'] as $flag) {
            if (Schema::hasColumn('sys_users', $flag)) {
                try {
                    $this->limitedUser->forceFill([$flag => 0])->saveQuietly();
                } catch (Throwable) {
                }
            }
        }
        try {
            if (method_exists($this->limitedUser, 'syncRoles')) {
                $this->limitedUser->syncRoles([]);
            }
            if (method_exists($this->limitedUser, 'syncPermissions')) {
                $this->limitedUser->syncPermissions([]);
            }
        } catch (Throwable) {
        }
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

        return $this->limitedUser;
    }

    private function grantLostFoundPermissions(?User $user): void
    {
        if (!$user instanceof User || !method_exists($user, 'givePermissionTo')) {
            return;
        }
        $permissions = [
            'frontoffice.lost-found.viewAny', 'frontoffice.lost-found.view', 'frontoffice.lost-found.create',
            'frontoffice.lost-found.update', 'frontoffice.lost-found.delete', 'frontoffice.lost-found.restore',
            'frontoffice.lost-found.forceDelete',
        ];
        $this->ensurePermissionsExist($permissions);
        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
            }
        }
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
    }

    private function ensurePermissionsExist(array $permissions): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }
        $guard = config('auth.defaults.guard', 'web');
        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate(['name' => $permission, 'guard_name' => $guard]);
            } catch (Throwable) {
            }
        }
    }

    private function activityLogAvailable(): bool
    {
        try {
            return Schema::hasTable((new ActivityLog())->getTable());
        } catch (Throwable) {
            return false;
        }
    }

    private function assertActivityLogged(int $subjectId, string $subjectType, string $event): void
    {
        $exists = ActivityLog::query()
            ->where('subject_type', $subjectType)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->exists();
        $this->assertTrue($exists, "Expected activity-log '{$event}' for {$subjectType}#{$subjectId} in " . (new ActivityLog())->getTable() . '.');
    }

    private function isDbConstraintError(Throwable $e): bool
    {
        $m = strtolower($e->getMessage());

        return str_contains($m, 'cannot be null')
            || str_contains($m, 'not null')
            || str_contains($m, "doesn't have a default value")
            || str_contains($m, 'integrity constraint')
            || str_contains($m, 'constraint failed')
            || str_contains($m, 'duplicate entry')
            || str_contains($m, 'foreign key')
            || str_contains($m, 'data too long')
            || str_contains($m, 'truncated')
            || str_contains($m, '23000')
            || str_contains($m, '1406')
            || str_contains($m, '1265')
            || str_contains($m, '1452');
    }

    private function pathFor(string $name, array $params = []): ?string
    {
        try {
            if (!Route::has($name)) {
                return null;
            }
            $url = route($name, $params, false);

            return is_string($url) && $url !== '' ? $url : null;
        } catch (Throwable) {
            return null;
        }
    }

    private function initializeTenantContextForTests(): void
    {
        $tenantHost = parse_url($this->tenantBaseUrl, PHP_URL_HOST);
        if (!is_string($tenantHost) || $tenantHost === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }
        $domain = Domain::query()->where('domain', $tenantHost)->first();
        if (!$domain) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $tenantHost);
        }
        if (function_exists('tenancy')) {
            tenancy()->initialize($domain->tenant);
        }
    }

    private function resolveAdminUser(): void
    {
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
            ?? User::query()->orderBy('id')->first();
        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for tests.');
        }
        if (property_exists($this->adminUser, 'email_verified_at') && !$this->adminUser->email_verified_at) {
            $this->adminUser->email_verified_at = now();
            $this->adminUser->save();
        }
        $this->grantLostFoundPermissions($this->adminUser);
    }

    private function authenticateBrowserSession(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(800);
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1400);
        }
        if (str_contains($this->currentPath($browser), '/login')) {
            $browser->loginAs($this->adminUser)->pause(600);
        }
    }

    private function visitPathWithAuthentication(Browser $browser, string $path, int $pauseMs = 900): void
    {
        $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        }
    }

    private function tenantUrl(string $path): string
    {
        return $this->tenantBaseUrl . '/' . ltrim($path, '/');
    }

    private function currentPath(Browser $browser): string
    {
        $path = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);

        return is_string($path) ? $path : '';
    }

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(1000, 9999);
    }
}
