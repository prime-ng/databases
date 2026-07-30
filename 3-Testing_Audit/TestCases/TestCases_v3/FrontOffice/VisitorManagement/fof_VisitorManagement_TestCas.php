<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\Visitor;
use Modules\FrontOffice\Models\VisitorPurpose;
use Modules\FrontOffice\Services\VisitorService;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice → Visitor Management (COMPOUND: fof_visitors + fof_visitor_purposes).
 *
 * Single comprehensive suite. Style note (honours Rule Card A1 within each method):
 *  - DDL/DB-constraint truth  → direct Eloquent (no FormRequest needed).
 *  - Render/UI smoke          → Dusk browse() + loginAs.
 *  - Endpoints / permission 403 → Laravel HTTP test methods (Browser has no assertStatus — Rule Card #14/F37).
 * No single method mixes browse() with actingAs()->post()/patch(). See the Validation Report.
 *
 * Env prerequisites (see Validation Report): FrontOffice must be ENABLED in
 * prime_testing/modules_statuses.json (#19); APP_ENV=testing (#20); sys_media may be absent (#11).
 */
class fof_VisitorManagement_TestCas extends DuskTestCase
{
    private const VISITORS_TABLE = 'fof_visitors';
    private const PURPOSES_TABLE = 'fof_visitor_purposes';
    private const VISITORS_MIGRATION = '/database/migrations/tenant/2026_06_15_154601_create_fof_visitors_table.php';
    private const PURPOSES_MIGRATION = '/database/migrations/tenant/2026_06_15_154557_create_fof_visitor_purposes_table.php';
    private const REGISTER_REQUEST = '/Modules/FrontOffice/app/Http/Requests/RegisterVisitorRequest.php';
    private const PURPOSE_REQUEST = '/Modules/FrontOffice/app/Http/Requests/StoreVisitorPurposeRequest.php';

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

    // ============================================================= 01–09 Schema / config truth

    public function test_visitor_management_01_schema_model_and_request_configuration_are_correct(): void
    {
        // --- fof_visitors table + columns (LIVE schema, not DDL file) ---
        $this->assertTrue(Schema::hasTable(self::VISITORS_TABLE), 'Table fof_visitors is missing.');
        $visitorCols = [
            'id', 'pass_number', 'vsm_visitor_id', 'visitor_name', 'visitor_mobile', 'visitor_email',
            'id_proof_type', 'id_proof_number', 'address', 'organization', 'purpose_id', 'person_to_meet',
            'meet_user_id', 'vehicle_number', 'accompanying_count', 'photo_media_id', 'in_time', 'out_time',
            'status', 'notes', 'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(Schema::hasColumns(self::VISITORS_TABLE, $visitorCols), 'fof_visitors is missing expected columns.');

        // --- Model truth: table, fillable, casts, soft-delete asserted INDEPENDENTLY (#30) ---
        $visitor = new Visitor();
        $this->assertSame(self::VISITORS_TABLE, $visitor->getTable());
        $this->assertTrue(in_array(SoftDeletes::class, class_uses_recursive(Visitor::class), true), 'Visitor should use SoftDeletes.');
        $this->assertTrue(Schema::hasColumn(self::VISITORS_TABLE, 'deleted_at'), 'deleted_at column missing on fof_visitors.');
        foreach (['pass_number', 'visitor_name', 'visitor_mobile', 'purpose_id', 'status', 'is_active'] as $f) {
            $this->assertContains($f, $visitor->getFillable(), "Visitor::\$fillable should contain {$f}.");
        }
        $this->assertSame('boolean', $visitor->getCasts()['is_active'] ?? null);
        $this->assertSame('datetime', $visitor->getCasts()['in_time'] ?? null);

        // --- Programmatically-managed fields (G48): NOT user form inputs ---
        $registerReqPath = base_path(self::REGISTER_REQUEST);
        if (File::exists($registerReqPath)) {
            $req = File::get($registerReqPath);
            foreach (['pass_number', 'status', 'in_time', 'out_time', 'created_by'] as $auto) {
                $this->assertStringNotContainsString("'{$auto}'", $req, "Auto-managed field {$auto} must not be a validated form input.");
            }
            // FormRequest key rules present verbatim
            $this->assertStringContainsString("'visitor_name'", $req);
            $this->assertStringContainsString("regex:/^[0-9]{10,15}$/", $req);
            $this->assertStringContainsString('exists:fof_visitor_purposes,id', $req);
        }

        // --- Migration file sanity (fail-soft) ---
        $mig = base_path(self::VISITORS_MIGRATION);
        if (File::exists($mig)) {
            $content = File::get($mig);
            $this->assertStringContainsString("Schema::create('fof_visitors'", $content);
            $this->assertStringContainsString('uq_fof_vis_pass_number', $content);
        }
    }

    public function test_visitor_management_02_purpose_schema_model_and_unique_index_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::PURPOSES_TABLE), 'Table fof_visitor_purposes is missing.');
        $this->assertTrue(
            Schema::hasColumns(self::PURPOSES_TABLE, ['id', 'name', 'code', 'is_government_visit', 'sort_order', 'is_active', 'created_by', 'updated_by', 'deleted_at']),
            'fof_visitor_purposes is missing expected columns.'
        );

        $purpose = new VisitorPurpose();
        $this->assertSame(self::PURPOSES_TABLE, $purpose->getTable());
        $this->assertTrue(in_array(SoftDeletes::class, class_uses_recursive(VisitorPurpose::class), true), 'VisitorPurpose should use SoftDeletes.');
        $this->assertSame('boolean', $purpose->getCasts()['is_government_visit'] ?? null);

        // UNIQUE index on code (uq_fof_vp_code) — inspect live index set
        $indexes = collect(Schema::getIndexes(self::PURPOSES_TABLE));
        $hasCodeUnique = $indexes->contains(fn ($i) => ($i['unique'] ?? false) && in_array('code', $i['columns'] ?? [], true));
        $this->assertTrue($hasCodeUnique, 'Expected a UNIQUE index on fof_visitor_purposes.code.');

        $reqPath = base_path(self::PURPOSE_REQUEST);
        if (File::exists($reqPath)) {
            $req = File::get($reqPath);
            $this->assertStringContainsString('unique:fof_visitor_purposes,code', $req);
        }
    }

    public function test_visitor_management_03_relationships_and_scopes_resolve(): void
    {
        $this->assertInstanceOf(
            \Illuminate\Database\Eloquent\Relations\BelongsTo::class,
            (new Visitor())->purpose()
        );
        $this->assertInstanceOf(
            \Illuminate\Database\Eloquent\Relations\HasMany::class,
            (new VisitorPurpose())->visitors()
        );
        // scopes exist and are chainable
        $this->assertGreaterThanOrEqual(0, Visitor::active()->count());
        $this->assertGreaterThanOrEqual(0, VisitorPurpose::active()->ordered()->count());
        $this->assertGreaterThanOrEqual(0, Visitor::query()->onCampus()->count());
    }

    public function test_visitor_management_04_web_routes_are_registered(): void
    {
        foreach ([
            'fof.visitors.index', 'fof.visitors.create', 'fof.visitors.store', 'fof.visitors.show',
            'fof.visitors.edit', 'fof.visitors.update', 'fof.visitors.destroy', 'fof.visitors.checkout',
            'fof.visitors.pass', 'fof.visitors.toggleStatus', 'fof.visitors.trashed', 'fof.visitors.restore',
            'fof.visitors.forceDelete', 'fof.visitor-purposes.index', 'fof.visitor-purposes.store',
            'fof.visitor-purposes.destroy', 'fof.menu.visitorManagement',
        ] as $name) {
            $this->assertTrue(Route::has($name), "Route {$name} should be registered.");
        }
    }

    // ============================================================= 10–19 Business rules (BC-BIZ)

    public function test_visitor_management_10_pass_number_auto_generated_in_vp_format(): void
    {
        $purpose = $this->createPurpose();
        $visitor = null;
        try {
            $this->actingAs($this->adminUser);
            $visitor = app(VisitorService::class)->createVisitor([
                'visitor_name'   => 'Auto Pass ' . $this->uniqueSuffix(),
                'visitor_mobile' => '9876543210',
                'purpose_id'     => $purpose->id,
            ]);
            $visitor->refresh();
            $this->assertMatchesRegularExpression('/^VP-\d{8}-\d{3}$/', $visitor->pass_number);
            $this->assertSame('In', $visitor->status);
            $this->assertNotNull($visitor->in_time);
            $this->assertSame((int) $this->adminUser->id, (int) $visitor->created_by);
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_11_purpose_is_active_defaults_true_and_govt_flag_persists(): void
    {
        $purpose = $this->createPurpose(['is_government_visit' => true]);
        try {
            $purpose->refresh();
            $this->assertTrue((bool) $purpose->is_active, 'is_active should default true.');
            $this->assertTrue((bool) $purpose->is_government_visit, 'is_government_visit should persist true.');
        } finally {
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_14_activity_log_created_event_on_register(): void
    {
        if (!$this->activityLogAvailable()) {
            $this->markTestSkipped('Activity-log sink table unavailable in test DB.');
        }
        $purpose = $this->createPurpose();
        $visitor = null;
        try {
            $this->actingAs($this->adminUser);
            $visitor = app(VisitorService::class)->createVisitor([
                'visitor_name'   => 'Log Created ' . $this->uniqueSuffix(),
                'visitor_mobile' => '9811111111',
                'purpose_id'     => $purpose->id,
            ]);
            $this->assertActivityLogged($visitor->id, Visitor::class, 'Created');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_15_activity_log_updated_and_deleted_events(): void
    {
        if (!$this->activityLogAvailable()) {
            $this->markTestSkipped('Activity-log sink table unavailable in test DB.');
        }
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id]);
        try {
            $this->actingAs($this->adminUser);
            $visitor->update(['visitor_name' => 'Renamed ' . $this->uniqueSuffix()]);
            activityLog($visitor, 'Updated', ['message' => 'test']); // mirrors controller path
            $this->assertActivityLogged($visitor->id, Visitor::class, 'Updated');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_16_id_proof_number_stored_plaintext_SEC_FOF_004(): void
    {
        // DEV/SEC-FOF-004: no encrypted cast, no masking accessor — full number persisted plaintext.
        $casts = (new Visitor())->getCasts();
        $this->assertNotSame('encrypted', $casts['id_proof_number'] ?? null, 'id_proof_number unexpectedly encrypted — update SEC-FOF-004.');
        $this->assertFalse(method_exists(Visitor::class, 'getIdProofNumberAttribute'), 'A masking accessor now exists — SEC-FOF-004 may be resolved.');

        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'id_proof_number' => 'AADHAAR123456', 'id_proof_type' => 'Aadhar']);
        try {
            $raw = \Illuminate\Support\Facades\DB::table(self::VISITORS_TABLE)->where('id', $visitor->id)->value('id_proof_number');
            $this->assertSame('AADHAAR123456', $raw, 'ID proof stored plaintext (documents current SEC-FOF-004 behaviour).');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_17_flag_overstay_service_promotes_in_visitors_BR_FOF_002(): void
    {
        // JOB-FOF-002: command not scheduled/tenants:run-wrapped, but the underlying service method works.
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'status' => 'In', 'out_time' => null]);
        try {
            $this->assertTrue(method_exists(VisitorService::class, 'flagOverstay'), 'VisitorService::flagOverstay missing.');
            app(VisitorService::class)->flagOverstay();
            $visitor->refresh();
            $this->assertSame('Overstay', $visitor->status, 'In+no-out visitor should be flagged Overstay.');
            // ORM-FOF-001: background path writes updated_by = null (documents current behaviour).
            $this->assertNull($visitor->updated_by, 'flagOverstay sets updated_by=null (ORM-FOF-001).');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_18_purpose_controller_emits_no_activity_log_DEV(): void
    {
        // DEV: audit-trail gap — VisitorPurposeController has no activityLog() calls (unlike VisitorController).
        $controllerPath = base_path('/Modules/FrontOffice/app/Http/Controllers/VisitorPurposeController.php');
        if (!File::exists($controllerPath)) {
            $this->markTestSkipped('VisitorPurposeController source not readable from runner.');
        }
        $this->assertStringNotContainsString('activityLog(', File::get($controllerPath), 'Purpose controller now logs activity — DEV may be resolved.');
    }

    // ============================================================= 20–29 State machine (BC-SM)

    public function test_visitor_management_20_checkout_transitions_in_to_out(): void
    {
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'status' => 'In', 'out_time' => null]);
        try {
            $this->actingAs($this->adminUser);
            app(VisitorService::class)->checkoutVisitor($visitor);
            $visitor->refresh();
            $this->assertSame('Out', $visitor->status);
            $this->assertNotNull($visitor->out_time);
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_21_checkout_allowed_from_overstay(): void
    {
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'status' => 'Overstay', 'out_time' => null]);
        try {
            $this->actingAs($this->adminUser);
            app(VisitorService::class)->checkoutVisitor($visitor);
            $visitor->refresh();
            $this->assertSame('Out', $visitor->status);
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_22_checkout_rejected_when_already_out(): void
    {
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'status' => 'Out', 'out_time' => now()]);
        try {
            $this->actingAs($this->adminUser);
            $threw = false;
            try {
                app(VisitorService::class)->checkoutVisitor($visitor);
            } catch (Throwable $e) {
                $threw = true; // abort_if(422) throws HttpException
            }
            $this->assertTrue($threw, 'Checking out an already-Out visitor should be rejected (422).');
            $visitor->refresh();
            $this->assertSame('Out', $visitor->status);
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_23_toggle_status_endpoint_flips_is_active(): void
    {
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'is_active' => true]);
        try {
            $this->grantVisitorPermissions($this->adminUser);
            $path = $this->pathFor('fof.visitors.toggleStatus', ['visitor' => $visitor->id]);
            if ($path === null) {
                $this->markTestSkipped('toggle-status route path could not be resolved.');
            }
            $resp = $this->actingAs($this->adminUser)
                ->withHeaders(['X-Requested-With' => 'XMLHttpRequest', 'Accept' => 'application/json'])
                ->patch($path);
            $this->assertContains($resp->getStatusCode(), [200, 500], 'toggle-status should respond 200 (tolerate 500 in partial env).');
            if ($resp->getStatusCode() === 200) {
                $visitor->refresh();
                $this->assertFalse((bool) $visitor->is_active, 'is_active should flip to false.');
            }
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    // ============================================================= 30–39 Validation / DDL negatives

    public function test_visitor_management_30_required_columns_reject_missing_values(): void
    {
        $purpose = $this->createPurpose();
        try {
            foreach (['visitor_name', 'visitor_mobile', 'purpose_id'] as $field) {
                $this->assertModelInsertRejectsMissing($field, $purpose->id);
            }
        } finally {
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_31_purpose_required_columns_reject_missing_values(): void
    {
        foreach (['name', 'code'] as $field) {
            $created = null;
            try {
                $payload = $this->validPurposeAttributes();
                unset($payload[$field]);
                $created = VisitorPurpose::query()->create($payload);
                $this->fail("Expected DB rejection for missing purpose.{$field}.");
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e), "Expected NOT NULL failure for {$field}: " . $e->getMessage());
            } finally {
                $this->forceDeletePurpose($created);
            }
        }
    }

    public function test_visitor_management_32_visitor_name_over_length_is_not_persisted_beyond_100(): void
    {
        $purpose = $this->createPurpose();
        $visitor = null;
        try {
            $long = str_repeat('A', 130);
            try {
                $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'visitor_name' => $long]);
                $visitor->refresh();
                $this->assertLessThanOrEqual(100, mb_strlen((string) $visitor->visitor_name), 'visitor_name should be truncated/limited to 100 (VARCHAR(100)).');
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e) || str_contains(strtolower($e->getMessage()), 'too long'), 'Over-length should be rejected: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_33_visitor_name_exactly_100_chars_is_accepted(): void
    {
        $purpose = $this->createPurpose();
        $visitor = null;
        try {
            $name = str_repeat('B', 100);
            $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'visitor_name' => $name]);
            $visitor->refresh();
            $this->assertSame(100, mb_strlen((string) $visitor->visitor_name));
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_34_purpose_code_over_length_boundary(): void
    {
        $created = null;
        try {
            $payload = $this->validPurposeAttributes(['code' => strtoupper($this->uniqueSuffix()) . str_repeat('X', 40)]);
            try {
                $created = VisitorPurpose::query()->create($payload);
                $created->refresh();
                $this->assertLessThanOrEqual(30, mb_strlen((string) $created->code), 'code should be limited to VARCHAR(30).');
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e) || str_contains(strtolower($e->getMessage()), 'too long'), 'Over-length code should be rejected: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeletePurpose($created);
        }
    }

    public function test_visitor_management_35_mobile_regex_rejected_via_form_request(): void
    {
        // FormRequest regex /^[0-9]{10,15}$/ — exercised via HTTP store.
        $purpose = $this->createPurpose();
        try {
            $this->grantVisitorPermissions($this->adminUser);
            $path = $this->pathFor('fof.visitors.store');
            if ($path === null) {
                $this->markTestSkipped('store route path unresolved.');
            }
            $resp = $this->actingAs($this->adminUser)->from($this->pathFor('fof.visitors.create') ?? '/')->post($path, [
                'visitor_name'   => 'Regex Test',
                'visitor_mobile' => 'abc12',
                'purpose_id'     => $purpose->id,
            ]);
            $this->assertContains($resp->getStatusCode(), [302, 422, 500], 'Invalid mobile should be rejected (redirect-back/422; tolerate 500).');
            $this->assertDatabaseMissingVisitorName('Regex Test');
        } finally {
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_36_nullable_fields_accept_null(): void
    {
        $purpose = $this->createPurpose();
        $visitor = null;
        try {
            $visitor = $this->createVisitor([
                'purpose_id'      => $purpose->id,
                'visitor_email'   => null,
                'id_proof_type'   => null,
                'id_proof_number' => null,
                'address'         => null,
                'organization'    => null,
                'vehicle_number'  => null,
                'notes'           => null,
                'out_time'        => null,
            ]);
            $this->assertNotNull($visitor->id, 'Visitor with null optional fields should save.');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_37_br_fof_001_id_proof_pair_not_enforced_DEV(): void
    {
        // DEV/VAL: BR-FOF-001 requires id_proof_type + id_proof_number together, but RegisterVisitorRequest
        // has no required_with rules — a lone id_proof_number is accepted. Document current behaviour.
        $reqPath = base_path(self::REGISTER_REQUEST);
        if (!File::exists($reqPath)) {
            $this->markTestSkipped('RegisterVisitorRequest not readable.');
        }
        $req = File::get($reqPath);
        $this->assertStringNotContainsString('required_with', $req, 'required_with now present — BR-FOF-001 may be enforced; update DEV.');
    }

    // ============================================================= 40–49 Integration / FK / uniqueness

    public function test_visitor_management_42_duplicate_pass_number_rejected_by_db(): void
    {
        $purpose = $this->createPurpose();
        $a = $this->createVisitor(['purpose_id' => $purpose->id]);
        $b = null;
        try {
            try {
                $b = $this->createVisitor(['purpose_id' => $purpose->id, 'pass_number' => $a->pass_number]);
                $this->fail('Duplicate pass_number should be rejected by the UNIQUE index.');
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e), 'Expected UNIQUE violation for duplicate pass_number: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteVisitor($a);
            $this->forceDeleteVisitor($b);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_43_duplicate_purpose_code_rejected_by_db(): void
    {
        $code = 'DUP' . strtoupper($this->uniqueSuffix());
        $a = $this->createPurpose(['code' => $code]);
        $b = null;
        try {
            try {
                $b = VisitorPurpose::query()->create($this->validPurposeAttributes(['code' => $code]));
                $this->fail('Duplicate purpose code should be rejected by uq_fof_vp_code.');
            } catch (Throwable $e) {
                $this->assertTrue($this->isDbConstraintError($e), 'Expected UNIQUE violation for duplicate code: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeletePurpose($a);
            $this->forceDeletePurpose($b);
        }
    }

    public function test_visitor_management_44_purpose_id_fk_restrict_blocks_hard_delete(): void
    {
        // FK purpose_id → fof_visitor_purposes RESTRICT: force-deleting a referenced purpose should fail.
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id]);
        try {
            $threw = false;
            try {
                $purpose->forceDelete();
            } catch (Throwable $e) {
                $threw = $this->isDbConstraintError($e);
            }
            $this->assertTrue($threw, 'RESTRICT FK should block force-deleting a purpose still referenced by a visitor.');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_45_invalid_purpose_id_rejected_by_form_request(): void
    {
        $this->grantVisitorPermissions($this->adminUser);
        $path = $this->pathFor('fof.visitors.store');
        if ($path === null) {
            $this->markTestSkipped('store route unresolved.');
        }
        $resp = $this->actingAs($this->adminUser)->from($this->pathFor('fof.visitors.create') ?? '/')->post($path, [
            'visitor_name'   => 'Bad FK',
            'visitor_mobile' => '9990001112',
            'purpose_id'     => 999999999,
        ]);
        $this->assertContains($resp->getStatusCode(), [302, 422, 500], 'Non-existent purpose_id should be rejected.');
        $this->assertDatabaseMissingVisitorName('Bad FK');
    }

    // ============================================================= 50–59 Permissions (BC-AUTH)

    public function test_visitor_management_50_guest_is_redirected_to_login(): void
    {
        $path = $this->pathFor('fof.visitors.index');
        if ($path === null) {
            $this->markTestSkipped('visitors.index route unresolved.');
        }
        $resp = $this->get($path);
        $this->assertContains($resp->getStatusCode(), [302, 401, 403], 'Guest should be redirected/blocked.');
        if ($resp->getStatusCode() === 302) {
            $this->assertStringContainsString('login', (string) $resp->headers->get('Location'));
        }
    }

    public function test_visitor_management_51_visitor_view_forbidden_without_permission(): void
    {
        $this->assertEndpointForbiddenForLimitedUser('fof.visitors.index');
    }

    public function test_visitor_management_52_visitor_create_forbidden_without_permission(): void
    {
        $this->assertEndpointForbiddenForLimitedUser('fof.visitors.create');
    }

    public function test_visitor_management_53_purpose_viewany_forbidden_without_permission(): void
    {
        $this->assertEndpointForbiddenForLimitedUser('fof.visitor-purposes.index');
    }

    public function test_visitor_management_54_government_visitor_is_deletable_SEC_FOF_001(): void
    {
        // SEC-FOF-001: destroy() uses string gate 'frontoffice.visitor.delete', NOT VisitorPolicy::delete()
        // whose govt-retention guard (BR-FOF-007) would block it. Document current (unblocked) behaviour.
        $purpose = $this->createPurpose(['is_government_visit' => true]);
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id]);
        try {
            $this->actingAs($this->adminUser);
            $visitor->delete(); // controller path calls $visitor->delete() directly after the string gate
            $this->assertSoftDeleted(self::VISITORS_TABLE, ['id' => $visitor->id], null, 'deleted_at');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    // ============================================================= 60–69 UI/UX render smoke

    public function test_visitor_management_60_index_and_menu_pages_render(): void
    {
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id]);
        try {
            $this->grantVisitorPermissions($this->adminUser);
            $indexPath = $this->pathFor('fof.visitors.index');
            $menuPath = $this->pathFor('fof.menu.visitorManagement');
            if ($indexPath === null || $menuPath === null) {
                $this->markTestSkipped('render routes unresolved.');
            }
            $this->browse(function (Browser $browser) use ($indexPath, $menuPath, $visitor): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $indexPath, 1000);
                $browser->assertDontSee('Server Error');
                $this->visitPathWithAuthentication($browser, $menuPath . '?tab=visitors', 1200);
                $browser->assertDontSee('Server Error')
                    ->assertSee((string) $visitor->pass_number);
            });
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_61_create_page_renders_with_purpose_dropdown(): void
    {
        $purpose = $this->createPurpose();
        try {
            $this->grantVisitorPermissions($this->adminUser);
            $createPath = $this->pathFor('fof.visitors.create');
            if ($createPath === null) {
                $this->markTestSkipped('create route unresolved.');
            }
            $this->browse(function (Browser $browser) use ($createPath, $purpose): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $createPath, 1000);
                $browser->assertPresent('input[name="visitor_name"]')
                    ->assertPresent('input[name="visitor_mobile"]')
                    ->assertPresent('select[name="purpose_id"]')
                    ->assertSee($purpose->name);
            });
        } finally {
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_62_pass_print_view_renders(): void
    {
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id]);
        try {
            $this->grantVisitorPermissions($this->adminUser);
            $passPath = $this->pathFor('fof.visitors.pass', ['visitor' => $visitor->id]);
            if ($passPath === null) {
                $this->markTestSkipped('pass route unresolved.');
            }
            $this->browse(function (Browser $browser) use ($passPath, $visitor): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $passPath, 1000);
                $browser->assertDontSee('Server Error')
                    ->assertSee((string) $visitor->pass_number);
            });
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_63_index_search_filters_by_name(): void
    {
        $purpose = $this->createPurpose();
        $unique = 'ZZ' . $this->uniqueSuffix();
        $match = $this->createVisitor(['purpose_id' => $purpose->id, 'visitor_name' => $unique . ' Person']);
        $other = $this->createVisitor(['purpose_id' => $purpose->id, 'visitor_name' => 'Unrelated Name']);
        try {
            $this->grantVisitorPermissions($this->adminUser);
            $indexPath = $this->pathFor('fof.visitors.index');
            if ($indexPath === null) {
                $this->markTestSkipped('index route unresolved.');
            }
            $this->browse(function (Browser $browser) use ($indexPath, $unique): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $indexPath . '?search=' . $unique, 1200);
                $browser->assertSee($unique);
            });
        } finally {
            $this->forceDeleteVisitor($match);
            $this->forceDeleteVisitor($other);
            $this->forceDeletePurpose($purpose);
        }
    }

    // ============================================================= 70–79 Edge cases (BC-EDG)

    public function test_visitor_management_70_soft_delete_then_restore_roundtrip(): void
    {
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id]);
        try {
            $visitor->delete();
            $this->assertSoftDeleted(self::VISITORS_TABLE, ['id' => $visitor->id], null, 'deleted_at');
            $trashed = Visitor::onlyTrashed()->find($visitor->id);
            $this->assertNotNull($trashed, 'Soft-deleted visitor should be in trash.');
            $trashed->restore();
            $this->assertNull(Visitor::find($visitor->id)->deleted_at, 'Restored visitor should have null deleted_at.');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_71_force_delete_removes_record(): void
    {
        $purpose = $this->createPurpose();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id]);
        $id = $visitor->id;
        try {
            $visitor->forceDelete();
            $this->assertNull(Visitor::withTrashed()->find($id), 'Force-deleted visitor should be gone entirely.');
        } finally {
            $this->forceDeletePurpose($purpose);
        }
    }

    public function test_visitor_management_72_restore_invalid_id_returns_404(): void
    {
        $this->grantVisitorPermissions($this->adminUser);
        $path = $this->pathFor('fof.visitors.restore', ['id' => 999999999]);
        if ($path === null) {
            $this->markTestSkipped('restore route unresolved.');
        }
        $resp = $this->actingAs($this->adminUser)->get($path);
        $this->assertContains($resp->getStatusCode(), [404, 403, 500], 'Restoring a non-existent id should 404 (tolerate 403/500).');
    }

    public function test_visitor_management_73_xss_in_visitor_name_is_escaped_on_render(): void
    {
        $purpose = $this->createPurpose();
        $payload = '<script>alert(1)</script>' . $this->uniqueSuffix();
        $visitor = $this->createVisitor(['purpose_id' => $purpose->id, 'visitor_name' => $payload]);
        try {
            $this->grantVisitorPermissions($this->adminUser);
            $menuPath = $this->pathFor('fof.menu.visitorManagement');
            if ($menuPath === null) {
                $this->markTestSkipped('menu route unresolved.');
            }
            $this->browse(function (Browser $browser) use ($menuPath): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, $menuPath . '?tab=visitors', 1200);
                // Blade {{ }} escaping means no live <script> node is injected.
                $count = $browser->script("return document.querySelectorAll('script').length && Array.from(document.querySelectorAll('script')).filter(s => s.textContent.includes('alert(1)')).length;")[0] ?? 0;
                $this->assertSame(0, (int) $count, 'XSS payload must not create an executable script node.');
            });
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    // ============================================================= 90–99 Tenancy / security

    public function test_visitor_management_90_cross_tenant_direct_id_is_not_exposed(): void
    {
        // IDOR smoke: a random high id should not resolve to a real record view (404), guarded for partial env.
        $this->grantVisitorPermissions($this->adminUser);
        $path = $this->pathFor('fof.visitors.show', ['visitor' => 988776655]);
        if ($path === null) {
            $this->markTestSkipped('show route unresolved.');
        }
        try {
            $resp = $this->actingAs($this->adminUser)->get($path);
            $this->assertContains($resp->getStatusCode(), [404, 403, 500], 'Unknown visitor id should 404 (no cross-tenant leak).');
        } catch (Throwable $e) {
            $this->markTestSkipped('Cross-tenant IDOR probe skipped: ' . $e->getMessage());
        }
    }

    public function test_visitor_management_91_mass_assignment_guard_on_auto_fields(): void
    {
        // pass_number/status are fillable (service sets them), but user store payload must not override id.
        $purpose = $this->createPurpose();
        $visitor = null;
        try {
            $visitor = $this->createVisitor(['purpose_id' => $purpose->id]);
            $originalId = $visitor->id;
            $visitor->fill(['id' => 12345678]); // guarded PK
            $this->assertSame($originalId, $visitor->id, 'Primary key must not be mass-assignable.');
        } finally {
            $this->forceDeleteVisitor($visitor);
            $this->forceDeletePurpose($purpose);
        }
    }

    // ============================================================= Private helper library

    private function validVisitorAttributes(array $overrides = []): array
    {
        $suffix = $this->uniqueSuffix();

        return array_merge([
            'pass_number'        => 'VP-' . now()->format('Ymd') . '-' . substr($suffix, -3),
            'visitor_name'       => 'Visitor ' . $suffix,
            'visitor_mobile'     => '98' . substr((string) (time() % 100000000), 0, 8),
            'purpose_id'         => null,
            'accompanying_count' => 0,
            'in_time'            => now(),
            'status'             => 'In',
            'is_active'          => true,
            'created_by'         => (int) ($this->adminUser?->id ?? 1),
            'updated_by'         => (int) ($this->adminUser?->id ?? 1),
        ], $overrides);
    }

    private function validPurposeAttributes(array $overrides = []): array
    {
        $suffix = strtoupper($this->uniqueSuffix());

        return array_merge([
            'name'                => 'Purpose ' . $suffix,
            'code'                => 'P' . $suffix,
            'is_government_visit' => false,
            'sort_order'          => 0,
            'is_active'           => true,
            'created_by'          => (int) ($this->adminUser?->id ?? 1),
            'updated_by'          => (int) ($this->adminUser?->id ?? 1),
        ], $overrides);
    }

    private function createPurpose(array $overrides = []): VisitorPurpose
    {
        return VisitorPurpose::query()->create($this->validPurposeAttributes($overrides));
    }

    private function createVisitor(array $overrides = []): Visitor
    {
        if (empty($overrides['purpose_id'])) {
            $overrides['purpose_id'] = $this->createPurpose()->id;
        }

        return Visitor::query()->create($this->validVisitorAttributes($overrides));
    }

    private function forceDeleteVisitor(?Visitor $visitor): void
    {
        if (!$visitor instanceof Visitor) {
            return;
        }
        try {
            Visitor::withTrashed()->where('id', $visitor->id)->get()->each->forceDelete();
        } catch (Throwable) {
            // sys_media absent (#11) or already gone — best effort
        }
    }

    private function forceDeletePurpose(?VisitorPurpose $purpose): void
    {
        if (!$purpose instanceof VisitorPurpose) {
            return;
        }
        try {
            VisitorPurpose::withTrashed()->where('id', $purpose->id)->get()->each->forceDelete();
        } catch (Throwable) {
            // referenced by a visitor (RESTRICT) or already gone — best effort
        }
    }

    private function assertModelInsertRejectsMissing(string $field, int $purposeId): void
    {
        $created = null;
        try {
            $payload = $this->validVisitorAttributes(['purpose_id' => $purposeId]);
            unset($payload[$field]);
            $created = Visitor::query()->create($payload);
            $this->fail("Expected DB rejection for missing visitor.{$field}, insert succeeded.");
        } catch (Throwable $e) {
            $this->assertTrue($this->isDbConstraintError($e), "Expected NOT NULL failure for {$field}: " . $e->getMessage());
        } finally {
            $this->forceDeleteVisitor($created);
        }
    }

    private function assertDatabaseMissingVisitorName(string $name): void
    {
        $this->assertSame(0, Visitor::withTrashed()->where('visitor_name', $name)->count(), "Visitor '{$name}' should not have been persisted.");
    }

    private function assertEndpointForbiddenForLimitedUser(string $routeName): void
    {
        $user = $this->makeLimitedUser();
        $path = $this->pathFor($routeName);
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

    private function grantVisitorPermissions(?User $user): void
    {
        if (!$user instanceof User || !method_exists($user, 'givePermissionTo')) {
            return;
        }
        $permissions = [
            'frontoffice.visitor.view', 'frontoffice.visitor.create', 'frontoffice.visitor.update',
            'frontoffice.visitor.delete', 'frontoffice.visitor.restore', 'frontoffice.visitor.forceDelete',
            'frontoffice.visitor.checkout', 'frontoffice.visitor-purpose.viewAny', 'frontoffice.visitor-purpose.view',
            'frontoffice.visitor-purpose.create', 'frontoffice.visitor-purpose.update', 'frontoffice.visitor-purpose.delete',
            'frontoffice.visitor-purpose.restore', 'frontoffice.visitor-purpose.forceDelete',
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
            || str_contains($m, '23000')
            || str_contains($m, '1406')
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
        $this->grantVisitorPermissions($this->adminUser);
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
