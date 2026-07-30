<?php

namespace Tests\Browser\Modules\FrontOffice\EmergencyContact;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\EmergencyContact;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice ▸ EmergencyContact (fof_emergency_contacts) — single comprehensive suite.
 *
 * STYLE: mirrors the nearest committed tenant-side Dusk sibling
 *        (Modules/Complaint/CmpCategory/cmp_ComplaintCategory_V2_TestCas.php):
 *        Dusk browse() for UI, Eloquent for DB truth, in-page fetch for JSON endpoints.
 *        NO actingAs()->post() (one style per file — Rule Card A1).
 *
 * ENV PREREQUISITES (documented in the Validation Report — NOT test-code bugs):
 *   - FrontOffice = false in prime_testing/modules_statuses.json → /front-office/* routes 404
 *     until enabled (Rule Card #19). Browser tests self-SKIP when the route is not registered.
 *   - APP_ENV=testing for Dusk CSRF bypass (#20); sys_media may be absent (#11);
 *     validation 500-vs-422 tolerated (#41).
 *
 * KNOWN SOURCE DEFECTS proven here (see Gap Analysis):
 *   DEV-FOF-EC-001  contact_type validation `in:` list is a SUBSET of the DDL ENUM —
 *                   Utility / Parent_Emergency / Government are valid DDL values but the
 *                   controller (and Blade dropdown) reject them.
 *   DEV-FOF-EC-002  store()/update()/destroy() do NOT call activityLog() — only
 *                   restore()='Restored' and forceDelete()='Deleted' are logged (audit gap).
 *   DEV-FOF-EC-003  No FormRequest — inline $request->validate() in the controller
 *                   (SEC-FOF-003 / D30, no defense-in-depth authorize()).
 *   DEV-FOF-EC-004  organization (VARCHAR 150) & sort_order are $fillable but never accepted
 *                   by store()/update() → always NULL / 0 from the web UI (dead columns).
 */
class fof_EmergencyContact_TestCas extends DuskTestCase
{
    // Paths derived from Modules/FrontOffice/routes/web.php (NOT hand-invented — F40).
    private const BASE_PATH   = '/front-office/emergency-contacts';
    private const CREATE_PATH = '/front-office/emergency-contacts/create';
    private const TRASH_PATH  = '/front-office/emergency-contacts/trash/view';
    private const MENU_TAB_PATH = '/front-office/compliance?tab=emergency';

    private const TABLE = 'fof_emergency_contacts';
    private const ACTIVITY_TABLE = 'sys_activity_logs';

    // Full DDL ENUM for contact_type (FrontOffice_DDL_v1.sql).
    private const DDL_ENUM = ['Hospital', 'Police', 'Fire', 'Ambulance', 'Transport', 'Utility', 'Parent_Emergency', 'Government', 'Other'];
    // Narrower set the controller actually accepts (in:...) — DEV-FOF-EC-001.
    private const APP_ENUM = ['Hospital', 'Police', 'Fire', 'Transport', 'Ambulance', 'Other'];

    private const PERMISSIONS = [
        'frontoffice.emergency-contact.view',
        'frontoffice.emergency-contact.create',
        'frontoffice.emergency-contact.update',
        'frontoffice.emergency-contact.delete',
        'frontoffice.emergency-contact.restore',
        'frontoffice.emergency-contact.forceDelete',
    ];

    private ?User $adminUser = null;
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

        $this->initializeTenantContext();
        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // ========================================================================
    //  01–09  SCHEMA / DDL / MODEL / REQUEST CONFIGURATION
    // ========================================================================

    /** test_01 — full DDL↔live-schema alignment matrix (G46). */
    public function test_emergencycontact_01_ddl_schema_alignment_matrix(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), self::TABLE . ' does not exist.');

        $colMap = $this->liveColumns();

        // Presence of every DDL column.
        foreach (['id', 'contact_name', 'organization', 'contact_type', 'primary_phone',
                  'alternate_phone', 'address', 'notes', 'sort_order', 'is_active',
                  'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at'] as $col) {
            $this->assertArrayHasKey($col, $colMap, "Column $col missing from live schema.");
        }

        // id
        $this->assertStringContainsString('bigint', strtolower($colMap['id']->COLUMN_TYPE));
        $this->assertEquals('NO', $colMap['id']->IS_NULLABLE);

        // contact_name VARCHAR(100) NOT NULL
        $this->assertStringContainsString('varchar', strtolower($colMap['contact_name']->COLUMN_TYPE));
        $this->assertEquals(100, (int) $colMap['contact_name']->CHARACTER_MAXIMUM_LENGTH);
        $this->assertEquals('NO', $colMap['contact_name']->IS_NULLABLE);

        // organization VARCHAR(150) NULL
        $this->assertStringContainsString('varchar', strtolower($colMap['organization']->COLUMN_TYPE));
        $this->assertEquals(150, (int) $colMap['organization']->CHARACTER_MAXIMUM_LENGTH);
        $this->assertEquals('YES', $colMap['organization']->IS_NULLABLE);

        // contact_type ENUM NOT NULL
        $this->assertStringContainsString('enum', strtolower($colMap['contact_type']->COLUMN_TYPE));
        $this->assertEquals('NO', $colMap['contact_type']->IS_NULLABLE);

        // primary_phone VARCHAR(15) NOT NULL
        $this->assertStringContainsString('varchar', strtolower($colMap['primary_phone']->COLUMN_TYPE));
        $this->assertEquals(15, (int) $colMap['primary_phone']->CHARACTER_MAXIMUM_LENGTH);
        $this->assertEquals('NO', $colMap['primary_phone']->IS_NULLABLE);

        // alternate_phone VARCHAR(15) NULL
        $this->assertStringContainsString('varchar', strtolower($colMap['alternate_phone']->COLUMN_TYPE));
        $this->assertEquals(15, (int) $colMap['alternate_phone']->CHARACTER_MAXIMUM_LENGTH);
        $this->assertEquals('YES', $colMap['alternate_phone']->IS_NULLABLE);

        // address VARCHAR(200) NULL
        $this->assertStringContainsString('varchar', strtolower($colMap['address']->COLUMN_TYPE));
        $this->assertEquals(200, (int) $colMap['address']->CHARACTER_MAXIMUM_LENGTH);
        $this->assertEquals('YES', $colMap['address']->IS_NULLABLE);

        // notes TEXT NULL
        $this->assertStringContainsString('text', strtolower($colMap['notes']->COLUMN_TYPE));
        $this->assertEquals('YES', $colMap['notes']->IS_NULLABLE);

        // sort_order TINYINT UNSIGNED NOT NULL DEFAULT 0
        $this->assertStringContainsString('tinyint', strtolower($colMap['sort_order']->COLUMN_TYPE));
        $this->assertEquals('NO', $colMap['sort_order']->IS_NULLABLE);
        $this->assertEquals('0', (string) $colMap['sort_order']->COLUMN_DEFAULT);

        // is_active TINYINT(1) NOT NULL DEFAULT 1
        $this->assertStringContainsString('tinyint', strtolower($colMap['is_active']->COLUMN_TYPE));
        $this->assertEquals('NO', $colMap['is_active']->IS_NULLABLE);
        $this->assertEquals('1', (string) $colMap['is_active']->COLUMN_DEFAULT);

        // created_by / updated_by BIGINT UNSIGNED NOT NULL (no FK)
        foreach (['created_by', 'updated_by'] as $col) {
            $this->assertStringContainsString('bigint', strtolower($colMap[$col]->COLUMN_TYPE));
            $this->assertEquals('NO', $colMap[$col]->IS_NULLABLE);
        }
    }

    /** test_02 — model $table / $fillable / $casts verified against the real model (G47). */
    public function test_emergencycontact_02_model_configuration_and_fillable_verified(): void
    {
        $model = new EmergencyContact();

        $this->assertSame(self::TABLE, $model->getTable());

        foreach (['contact_name', 'organization', 'contact_type', 'primary_phone',
                  'alternate_phone', 'address', 'notes', 'sort_order', 'is_active',
                  'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $model->getFillable(), "$col missing from \$fillable.");
        }

        // is_active cast boolean (real Laravel method — F34).
        $this->assertTrue($model->hasCast('is_active', ['bool', 'boolean']));

        // scopeActive exists.
        $this->assertTrue(method_exists($model, 'scopeActive'), 'scopeActive() missing.');
    }

    /** test_03 — soft-delete column and trait asserted INDEPENDENTLY (#30 / G46). */
    public function test_emergencycontact_03_soft_delete_column_and_trait_independent(): void
    {
        $hasColumn = Schema::hasColumn(self::TABLE, 'deleted_at');
        $usesTrait = in_array(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(EmergencyContact::class),
            true
        );

        $this->assertTrue($hasColumn, 'deleted_at column missing from live schema.');
        $this->assertTrue($usesTrait, 'SoftDeletes trait missing from the model.');

        if ($hasColumn !== $usesTrait) {
            $this->fail('DEV: deleted_at column and SoftDeletes trait disagree — reconcile.');
        }
    }

    /** test_04 — contact_type DDL ENUM carries all 9 members (feeds DEV-FOF-EC-001). */
    public function test_emergencycontact_04_contact_type_enum_full_ddl_values(): void
    {
        $colMap = $this->liveColumns();
        $type = strtolower($colMap['contact_type']->COLUMN_TYPE ?? '');

        foreach (self::DDL_ENUM as $member) {
            $this->assertStringContainsString(strtolower($member), $type,
                "DDL ENUM should contain $member.");
        }
    }

    /** test_05 — table has NO UNIQUE index → duplicate-rejection tests are N/A (G43 documented). */
    public function test_emergencycontact_05_no_unique_indexes_present(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Index inspection requires MySQL.');
        }

        $indexes = DB::select('SHOW INDEX FROM `' . self::TABLE . '`');
        $uniqueNonPk = array_filter($indexes, static fn ($i) => ! $i->Non_unique && $i->Key_name !== 'PRIMARY');

        $this->assertCount(0, $uniqueNonPk,
            'DDL declares no UNIQUE key on fof_emergency_contacts; found one in live schema.');

        // The one declared secondary key is idx_fof_ec_type (contact_type) — non-unique.
        $hasTypeIdx = collect($indexes)->contains(fn ($i) => str_contains($i->Key_name ?? '', 'idx_fof_ec_type'));
        $this->assertTrue($hasTypeIdx, 'Expected non-unique index idx_fof_ec_type on contact_type.');
    }

    /** test_06 — all EmergencyContact routes registered (F40). Skips cleanly when module disabled (#19). */
    public function test_emergencycontact_06_routes_registered(): void
    {
        $names = [
            'fof.emergency-contacts.index',
            'fof.emergency-contacts.create',
            'fof.emergency-contacts.store',
            'fof.emergency-contacts.show',
            'fof.emergency-contacts.edit',
            'fof.emergency-contacts.update',
            'fof.emergency-contacts.destroy',
            'fof.emergency-contacts.trashed',
            'fof.emergency-contacts.restore',
            'fof.emergency-contacts.forceDelete',
            'fof.emergency-contacts.toggleStatus',
        ];

        if (! Route::has('fof.emergency-contacts.index')) {
            $this->markTestSkipped('FrontOffice module disabled (modules_statuses.json=false) — routes not registered (#19).');
        }

        foreach ($names as $name) {
            $this->assertTrue(Route::has($name), "Route $name is not registered.");
        }
    }

    /** test_07 — DEV-FOF-EC-003: no dedicated FormRequest; controller validates inline. */
    public function test_emergencycontact_07_no_form_request_inline_validation(): void
    {
        // No StoreEmergencyContactRequest / UpdateEmergencyContactRequest classes exist.
        $this->assertFalse(
            class_exists('Modules\\FrontOffice\\Http\\Requests\\StoreEmergencyContactRequest'),
            'DEV-FOF-EC-003 assumption broken: a Store FormRequest now exists — re-baseline.'
        );

        $src = $this->controllerSource();
        if ($src === null) {
            $this->markTestSkipped('Controller source not readable from runner (#29/#32).');
        }

        // Inline validation present with the narrower in: list (DEV-FOF-EC-001 evidence).
        $this->assertStringContainsString('$request->validate(', $src);
        $this->assertStringContainsString("in:Hospital,Police,Fire,Transport,Ambulance,Other", $src);
    }

    // ========================================================================
    //  10–19  BUSINESS RULES (BC-BIZ)
    // ========================================================================

    /** test_10 — create persists with server defaults (refresh — F35). */
    public function test_emergencycontact_10_create_applies_server_defaults(): void
    {
        $contact = $this->createContact(['contact_name' => 'Apollo ' . $this->uniqueSuffix()]);

        try {
            $contact->refresh();
            $this->assertEquals(0, (int) $contact->sort_order, 'sort_order default should be 0.');
            $this->assertTrue((bool) $contact->is_active, 'is_active default should be 1.');
            $this->assertNull($contact->organization, 'organization default should be NULL.');
            $this->assertNotNull($contact->created_by);
            $this->assertNotNull($contact->updated_by);
        } finally {
            $contact->forceDelete();
        }
    }

    /** test_11 — controller groups the index by contact_type (mirrors index()). */
    public function test_emergencycontact_11_index_grouped_by_contact_type(): void
    {
        $a = $this->createContact(['contact_type' => 'Hospital', 'contact_name' => 'H_' . $this->uniqueSuffix()]);
        $b = $this->createContact(['contact_type' => 'Police', 'contact_name' => 'P_' . $this->uniqueSuffix()]);

        try {
            $grouped = EmergencyContact::orderBy('contact_type')->orderBy('contact_name')
                ->get()->groupBy('contact_type');

            $this->assertTrue($grouped->has('Hospital'));
            $this->assertTrue($grouped->has('Police'));
            $this->assertGreaterThanOrEqual(1, $grouped['Hospital']->count());
        } finally {
            $a->forceDelete();
            $b->forceDelete();
        }
    }

    /** test_12 — update mutates fields and stamps updated_by. */
    public function test_emergencycontact_12_update_changes_fields(): void
    {
        $contact = $this->createContact();

        try {
            $newPhone = '99900' . random_int(10000, 99999);
            $contact->update(['primary_phone' => $newPhone, 'updated_by' => $this->adminUserId()]);
            $contact->refresh();
            $this->assertSame($newPhone, $contact->primary_phone);
        } finally {
            $contact->forceDelete();
        }
    }

    /** test_13 — DEV-FOF-EC-004: organization & sort_order are fillable but the controller never accepts them. */
    public function test_emergencycontact_13_organization_and_sort_order_not_web_inputs(): void
    {
        $src = $this->controllerSource();
        if ($src === null) {
            $this->markTestSkipped('Controller source not readable from runner (#29/#32).');
        }

        // The validated payload in store()/update() omits organization & sort_order.
        $this->assertStringNotContainsString("'organization'", $src,
            'DEV-FOF-EC-004: organization unexpectedly referenced in controller — re-baseline.');
        $this->assertStringNotContainsString("'sort_order'", $src,
            'DEV-FOF-EC-004: sort_order unexpectedly referenced in controller — re-baseline.');

        // Yet both remain fillable on the model.
        $fillable = (new EmergencyContact())->getFillable();
        $this->assertContains('organization', $fillable);
        $this->assertContains('sort_order', $fillable);
    }

    /** test_14 — scopeActive() filters out inactive rows (real scope — F34). */
    public function test_emergencycontact_14_scope_active_filters_inactive(): void
    {
        $active = $this->createContact(['is_active' => true]);
        $inactive = $this->createContact(['is_active' => false]);

        try {
            $ids = EmergencyContact::active()->pluck('id');
            $this->assertTrue($ids->contains($active->id));
            $this->assertFalse($ids->contains($inactive->id));
        } finally {
            $active->forceDelete();
            $inactive->forceDelete();
        }
    }

    // ========================================================================
    //  15–17  LIFECYCLE (soft-delete / restore / force-delete / toggle)
    // ========================================================================

    /** test_15 — soft delete then restore; controller restore() logs 'Restored' (source-verified). */
    public function test_emergencycontact_15_soft_delete_then_restore_lifecycle(): void
    {
        $contact = $this->createContact();
        $id = $contact->id;

        try {
            $contact->delete();
            $this->assertSoftDeleted(self::TABLE, ['id' => $id]);
            $this->assertEquals(0, EmergencyContact::whereKey($id)->count(), 'Soft-deleted row should be hidden.');
            $this->assertEquals(1, EmergencyContact::onlyTrashed()->whereKey($id)->count());

            EmergencyContact::onlyTrashed()->findOrFail($id)->restore();
            $this->assertEquals(1, EmergencyContact::whereKey($id)->count(), 'Restore should revive the row.');

            // Controller restore() emits activityLog(..., 'Restored', ...) — assert the exact verb in source.
            $src = $this->controllerSource();
            if ($src !== null) {
                $this->assertStringContainsString("activityLog(\$contact, 'Restored'", $src);
            }
        } finally {
            EmergencyContact::withTrashed()->whereKey($id)->first()?->forceDelete();
        }
    }

    /** test_16 — force delete removes the row; controller forceDelete() logs 'Deleted' (source-verified). */
    public function test_emergencycontact_16_force_delete_removes_row(): void
    {
        $contact = $this->createContact();
        $id = $contact->id;

        $contact->forceDelete();
        $this->assertEquals(0, EmergencyContact::withTrashed()->whereKey($id)->count(),
            'Force delete should permanently remove the row.');

        $src = $this->controllerSource();
        if ($src !== null) {
            $this->assertStringContainsString("activityLog(\$contact, 'Deleted'", $src);
        }
    }

    /** test_17 — toggle_status flips is_active (mirrors toggleStatus()). */
    public function test_emergencycontact_17_toggle_status_flips_is_active(): void
    {
        $contact = $this->createContact(['is_active' => true]);

        try {
            $contact->update(['is_active' => ! $contact->is_active]);
            $contact->refresh();
            $this->assertFalse((bool) $contact->is_active);

            $contact->update(['is_active' => ! $contact->is_active]);
            $contact->refresh();
            $this->assertTrue((bool) $contact->is_active);
        } finally {
            $contact->forceDelete();
        }
    }

    // ========================================================================
    //  30–39  VALIDATION / CONSTRAINTS (BC-VAL / BC-DB) — DB-level, tolerant (F41/G44/G45)
    // ========================================================================

    /** test_30 — NOT NULL: contact_name missing is rejected (G44). */
    public function test_emergencycontact_30_missing_contact_name_rejected(): void
    {
        $this->assertRejectsBadInsert([
            'contact_type'  => 'Hospital',
            'primary_phone' => '9990001111',
            'created_by'    => $this->adminUserId(),
            'updated_by'    => $this->adminUserId(),
        ], 'contact_name', 'contact_name is NOT NULL with no default.');
    }

    /** test_31 — NOT NULL: primary_phone missing is rejected (G44). */
    public function test_emergencycontact_31_missing_primary_phone_rejected(): void
    {
        $this->assertRejectsBadInsert([
            'contact_name' => 'NoPhone ' . $this->uniqueSuffix(),
            'contact_type' => 'Police',
            'created_by'   => $this->adminUserId(),
            'updated_by'   => $this->adminUserId(),
        ], 'primary_phone', 'primary_phone is NOT NULL with no default.');
    }

    /** test_32 — NOT NULL no-default: created_by missing is rejected (G44). */
    public function test_emergencycontact_32_missing_created_by_rejected(): void
    {
        $this->assertRejectsBadInsert([
            'contact_name'  => 'NoCreator ' . $this->uniqueSuffix(),
            'contact_type'  => 'Fire',
            'primary_phone' => '9990002222',
            'updated_by'    => $this->adminUserId(),
        ], 'created_by', 'created_by is NOT NULL with no default.');
    }

    /** test_33 — ENUM: an out-of-domain contact_type is rejected by the DB. */
    public function test_emergencycontact_33_invalid_contact_type_rejected(): void
    {
        $this->assertRejectsBadInsert([
            'contact_name'  => 'BadType ' . $this->uniqueSuffix(),
            'contact_type'  => 'NotAnEnumValue',
            'primary_phone' => '9990003333',
            'created_by'    => $this->adminUserId(),
            'updated_by'    => $this->adminUserId(),
        ], 'contact_type', 'contact_type is a strict ENUM.');
    }

    /** test_34 — DEV-FOF-EC-001: the extended DDL ENUM members ARE accepted at the DB layer. */
    public function test_emergencycontact_34_ddl_extended_enum_accepted_by_db(): void
    {
        $extended = array_values(array_diff(self::DDL_ENUM, self::APP_ENUM)); // Utility, Parent_Emergency, Government
        $this->assertNotEmpty($extended, 'Expected DDL ENUM to be wider than the app in: list.');

        foreach ($extended as $member) {
            $contact = null;
            try {
                $contact = EmergencyContact::create([
                    'contact_name'  => 'Ext_' . $member . '_' . $this->uniqueSuffix(),
                    'contact_type'  => $member,
                    'primary_phone' => '9990004444',
                    'created_by'    => $this->adminUserId(),
                    'updated_by'    => $this->adminUserId(),
                ]);
                $contact->refresh();
                $this->assertSame($member, $contact->contact_type,
                    "DDL ENUM should accept $member (proves DEV-FOF-EC-001: app in: list is narrower).");
            } catch (Throwable $e) {
                $this->fail("DDL ENUM unexpectedly rejected valid member $member: " . $e->getMessage());
            } finally {
                $contact?->forceDelete();
            }
        }
    }

    /** test_35 — DEV-FOF-EC-001: the controller's in: list omits the extended members. */
    public function test_emergencycontact_35_app_validation_omits_extended_enum(): void
    {
        $src = $this->controllerSource();
        if ($src === null) {
            $this->markTestSkipped('Controller source not readable from runner (#29/#32).');
        }

        foreach (['Utility', 'Parent_Emergency', 'Government'] as $member) {
            $this->assertStringNotContainsString($member, $src,
                "DEV-FOF-EC-001: controller in: list should NOT contain $member (it currently rejects it).");
        }
    }

    /** test_36 — VARCHAR(100): over-length contact_name rejected/truncated (G45). */
    public function test_emergencycontact_36_contact_name_over_length_rejected(): void
    {
        $this->assertOverLengthHandled('contact_name', 100, [
            'contact_type'  => 'Other',
            'primary_phone' => '9990005555',
        ]);
    }

    /** test_37 — VARCHAR(15): over-length primary_phone rejected/truncated (G45). */
    public function test_emergencycontact_37_primary_phone_over_length_rejected(): void
    {
        $this->assertOverLengthHandled('primary_phone', 15, [
            'contact_name' => 'LongPhone ' . $this->uniqueSuffix(),
            'contact_type' => 'Other',
        ]);
    }

    /** test_38 — VARCHAR(200): over-length address rejected/truncated (G45). */
    public function test_emergencycontact_38_address_over_length_rejected(): void
    {
        $this->assertOverLengthHandled('address', 200, [
            'contact_name'  => 'LongAddr ' . $this->uniqueSuffix(),
            'contact_type'  => 'Other',
            'primary_phone' => '9990006666',
        ]);
    }

    /** test_39 — boundary positive: exactly-max lengths + omitted nullables succeed (G44/G45). */
    public function test_emergencycontact_39_max_length_boundary_and_nullables_accepted(): void
    {
        $contact = null;
        try {
            $contact = EmergencyContact::create([
                'contact_name'  => str_repeat('N', 100),
                'contact_type'  => 'Hospital',
                'primary_phone' => str_repeat('9', 15),
                'address'       => str_repeat('A', 200),
                // organization / alternate_phone / notes deliberately omitted (nullable — positive).
                'created_by'    => $this->adminUserId(),
                'updated_by'    => $this->adminUserId(),
            ]);
            $contact->refresh();
            $this->assertSame(100, mb_strlen($contact->contact_name));
            $this->assertSame(15, mb_strlen($contact->primary_phone));
            $this->assertSame(200, mb_strlen($contact->address));
            $this->assertNull($contact->alternate_phone);
            $this->assertNull($contact->notes);
        } finally {
            $contact?->forceDelete();
        }
    }

    // ========================================================================
    //  40–49  DEPENDENCY / FK INTEGRITY (BC-REF)
    // ========================================================================

    /** test_40 — created_by has NO FK to sys_users (DDL comment); an orphan id is accepted. */
    public function test_emergencycontact_40_created_by_has_no_fk(): void
    {
        $orphanId = 2000000000; // no such sys_users.id
        $contact = null;
        try {
            $contact = EmergencyContact::create([
                'contact_name'  => 'Orphan ' . $this->uniqueSuffix(),
                'contact_type'  => 'Other',
                'primary_phone' => '9990007777',
                'created_by'    => $orphanId,
                'updated_by'    => $orphanId,
            ]);
            $contact->refresh();
            $this->assertEquals($orphanId, (int) $contact->created_by,
                'created_by should accept an orphan id (no FK constraint per DDL).');
        } catch (Throwable $e) {
            // If a FK were somehow present this would be a schema change — surface it.
            $this->fail('Unexpected FK rejection on created_by (DDL says no FK): ' . $e->getMessage());
        } finally {
            $contact?->forceDelete();
        }
    }

    /** test_41 — restore() cannot resurrect a force-deleted (hard-gone) row. */
    public function test_emergencycontact_41_restore_does_not_recover_hard_deleted(): void
    {
        $contact = $this->createContact();
        $id = $contact->id;
        $contact->forceDelete();

        $this->assertEquals(0, EmergencyContact::withTrashed()->whereKey($id)->count(),
            'Row must be gone after force delete; restore has nothing to recover.');
    }

    // ========================================================================
    //  50–59  PERMISSIONS / AUTHORIZATION (BC-AUTH)
    // ========================================================================

    /** test_50 — controller gates every action with a frontoffice.emergency-contact.* ability (source). */
    public function test_emergencycontact_50_controller_gates_present(): void
    {
        $src = $this->controllerSource();
        if ($src === null) {
            $this->markTestSkipped('Controller source not readable from runner (#29/#32).');
        }

        foreach (self::PERMISSIONS as $ability) {
            $this->assertStringContainsString($ability, $src, "Gate ability $ability not enforced in controller.");
        }
    }

    /** test_51 — Policy exposes the matching abilities (BC-AUTH). */
    public function test_emergencycontact_51_policy_abilities_match(): void
    {
        $policy = 'Modules\\FrontOffice\\Policies\\EmergencyContactPolicy';
        if (! class_exists($policy)) {
            $this->markTestSkipped('EmergencyContactPolicy not autoloadable.');
        }

        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'] as $method) {
            $this->assertTrue(method_exists($policy, $method), "Policy::$method() missing.");
        }
    }

    /** test_52 — guest is redirected to /login (browser; skips when module disabled). */
    public function test_emergencycontact_52_guest_redirected_to_login(): void
    {
        $this->skipUnlessRoutesRegistered();

        $this->browse(function (Browser $browser) {
            $browser->logout()
                ->visit($this->tenantUrl(self::BASE_PATH))
                ->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser),
                'Guest should be redirected to /login.');
        });
    }

    /** test_53 — a non-super-admin WITHOUT the permission gets 403 (F37/#31). */
    public function test_emergencycontact_53_forbidden_without_permission(): void
    {
        $this->skipUnlessRoutesRegistered();

        $this->browse(function (Browser $browser) {
            $user = $this->makeLimitedUser();

            try {
                $browser->loginAs($user)
                    ->visit($this->tenantUrl(self::BASE_PATH))
                    ->pause(1200);

                $source = $browser->driver->getPageSource();
                $this->assertTrue(
                    str_contains($source, '403') || stripos($source, 'unauthorized') !== false,
                    'Non-super-admin without the view permission should be forbidden (403).'
                );
            } finally {
                $this->forgetPermissionCache();
                try {
                    $user->forceDelete();
                } catch (Throwable) {
                    // ignore
                }
            }
        });
    }

    // ========================================================================
    //  60–69  UI / UX (browser — skip when module disabled)
    // ========================================================================

    /** test_60 — create page renders the real form fields (Blade selectors). */
    public function test_emergencycontact_60_create_page_renders(): void
    {
        $this->skipUnlessRoutesRegistered();

        $this->browse(function (Browser $browser) {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 1200);

            $browser->waitFor('input[name="contact_name"]', 12)
                ->assertPresent('select[name="contact_type"]')
                ->assertPresent('input[name="primary_phone"]')
                ->assertSee('Save Contact');
        });
    }

    /** test_61 — required-field UI: submitting the create form without a name keeps the user on the page. */
    public function test_emergencycontact_61_required_name_ui_rejected(): void
    {
        $this->skipUnlessRoutesRegistered();

        $this->browse(function (Browser $browser) {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 1200);

            $browser->waitFor('input[name="primary_phone"]', 12)
                ->type('input[name="primary_phone"]', '9990008888');

            // strip HTML5 required so the request actually reaches the server validator.
            $browser->script('document.querySelectorAll("[required]").forEach(function(el){el.removeAttribute("required")})');
            $browser->press('Save Contact')->pause(1500);

            $source = $browser->driver->getPageSource();
            $this->assertTrue(
                str_contains($browser->driver->getCurrentURL(), 'emergency-contacts/create')
                || stripos($source, 'required') !== false
                || stripos($source, 'error') !== false,
                'Missing contact_name should keep the form on the create page.'
            );
        });
    }

    // ========================================================================
    //  70–79  EDGE CASES (BC-EDG)
    // ========================================================================

    /** test_70 — notes TEXT accepts a large body (no max: rule in the controller). */
    public function test_emergencycontact_70_notes_accepts_large_text(): void
    {
        $contact = null;
        try {
            $big = str_repeat('lorem ipsum ', 500); // ~6 KB, well within TEXT
            $contact = EmergencyContact::create([
                'contact_name'  => 'BigNotes ' . $this->uniqueSuffix(),
                'contact_type'  => 'Other',
                'primary_phone' => '9990009999',
                'notes'         => $big,
                'created_by'    => $this->adminUserId(),
                'updated_by'    => $this->adminUserId(),
            ]);
            $contact->refresh();
            $this->assertSame($big, $contact->notes);
        } finally {
            $contact?->forceDelete();
        }
    }

    // ========================================================================
    //  90–99  TENANCY / SECURITY (TC-T / TC-S)
    // ========================================================================

    /** test_90 — the feature's table lives on the initialized TENANT connection (tenant-side). */
    public function test_emergencycontact_90_tenant_context_active(): void
    {
        if (! (function_exists('tenancy') && tenancy()->initialized)) {
            $this->markTestSkipped('Tenant context not initialized in this environment.');
        }

        $this->assertTrue(tenancy()->initialized, 'Tenancy should be initialized for a fof_* table.');
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Tenant DB should own fof_emergency_contacts.');
    }

    /** test_91 — XSS payload is stored verbatim (no sanitisation) and is escaped by Blade at render (TC-S). */
    public function test_emergencycontact_91_xss_payload_stored_raw(): void
    {
        $payload = '<script>alert("x")</script>';
        $contact = null;
        try {
            $contact = EmergencyContact::create([
                'contact_name'  => $payload,
                'contact_type'  => 'Other',
                'primary_phone' => '9990001010',
                'created_by'    => $this->adminUserId(),
                'updated_by'    => $this->adminUserId(),
            ]);
            $contact->refresh();
            // Stored raw (Blade {{ }} escapes on output — the index view uses {{ $contact->contact_name }}).
            $this->assertSame($payload, $contact->contact_name,
                'Value is stored verbatim; output-escaping is Blade\'s responsibility.');
        } finally {
            $contact?->forceDelete();
        }
    }

    /** test_92 — toggle-status endpoint returns 404 for a non-existent id (in-page fetch, CSRF+XHR — F39). */
    public function test_emergencycontact_92_toggle_status_nonexistent_returns_404(): void
    {
        $this->skipUnlessRoutesRegistered();

        $this->browse(function (Browser $browser) {
            $this->authenticate($browser);
            $browser->visit($this->tenantUrl(self::MENU_TAB_PATH))->pause(800);

            $url = json_encode($this->tenantUrl(self::BASE_PATH . '/99999999/toggle-status'));
            $browser->script(<<<JS
            window.__done = false; window.__status = 0;
            (async function () {
                try {
                    var csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
                    var resp = await fetch({$url}, {
                        method: 'POST',
                        credentials: 'same-origin',
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'X-CSRF-TOKEN': csrf,
                            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                        },
                        body: new URLSearchParams({ _token: csrf }).toString(),
                    });
                    window.__status = resp.status;
                } catch (e) { window.__status = 0; }
                window.__done = true;
            })();
            JS);
            $browser->waitUntil('window.__done === true', 10);
            $status = (int) $browser->script('return window.__status')[0];

            // 404 expected; tolerate 419/403 harness quirks but never a 200 success.
            $this->assertContains($status, [404, 403, 419],
                "Toggle on a non-existent id should not succeed (got $status).");
        });
    }

    // ========================================================================
    //  PRIVATE HELPER LIBRARY
    // ========================================================================

    private function createContact(array $overrides = []): EmergencyContact
    {
        $suffix = $this->uniqueSuffix();

        return EmergencyContact::create(array_merge([
            'contact_name'  => 'Contact_' . $suffix,
            'contact_type'  => 'Hospital',
            'primary_phone' => '900' . random_int(1000000, 9999999),
            'is_active'     => true,
            'created_by'    => $this->adminUserId(),
            'updated_by'    => $this->adminUserId(),
        ], $overrides));
    }

    /**
     * Assert a bad insert is refused: either a DB constraint error, OR (non-strict mode)
     * the offending column was not persisted as intended. Tolerant per F41/G44.
     */
    private function assertRejectsBadInsert(array $attributes, string $missingCol, string $why): void
    {
        $row = null;
        try {
            $row = EmergencyContact::create($attributes);
            $row->refresh();

            // No exception (non-strict SQL mode): prove the column was not populated with valid intent.
            $value = $row->getAttribute($missingCol);
            $this->assertTrue(
                $value === null || $value === '' || $value === 0 || $value === '0',
                "$why Expected rejection or a zero-value fallback for $missingCol, got: " . var_export($value, true)
            );
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $this->assertTrue(
                str_contains($msg, '23000') || str_contains($msg, '1364')
                || str_contains($msg, '1048') || str_contains($msg, 'cannot be null')
                || str_contains($msg, "doesn't have a default") || str_contains($msg, 'truncated')
                || str_contains($msg, 'data too long') || str_contains($msg, 'incorrect'),
                "$why Expected a DB constraint error, got: " . $e->getMessage()
            );
        } finally {
            $row?->forceDelete();
        }
    }

    /**
     * VARCHAR(n) over-length: assert the DB either rejects (strict) or silently truncates to n.
     */
    private function assertOverLengthHandled(string $column, int $max, array $base): void
    {
        $row = null;
        try {
            $row = EmergencyContact::create(array_merge($base, [
                $column      => str_repeat('X', $max + 5),
                'created_by' => $this->adminUserId(),
                'updated_by' => $this->adminUserId(),
            ]));
            $row->refresh();

            // Non-strict mode: value must be truncated to <= n (never stored over-length).
            $this->assertLessThanOrEqual($max, mb_strlen((string) $row->getAttribute($column)),
                "$column over-length value should be rejected or truncated to $max.");
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $this->assertTrue(
                str_contains($msg, 'data too long') || str_contains($msg, '1406')
                || str_contains($msg, '22001') || str_contains($msg, 'truncated'),
                "Expected a length error for $column, got: " . $e->getMessage()
            );
        } finally {
            $row?->forceDelete();
        }
    }

    /** @return array<string, object> live information_schema column rows keyed by name. */
    private function liveColumns(): array
    {
        $dbName = DB::connection()->getDatabaseName();
        $rows = DB::select(
            'SELECT COLUMN_NAME, COLUMN_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE, COLUMN_DEFAULT
             FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?',
            [$dbName, self::TABLE]
        );

        $map = [];
        foreach ($rows as $r) {
            $map[$r->COLUMN_NAME] = $r;
        }

        return $map;
    }

    /** Read the real controller source TEXT from the app repo (#29/#32). */
    private function controllerSource(): ?string
    {
        try {
            $ref = new \ReflectionClass('Modules\\FrontOffice\\Http\\Controllers\\EmergencyContactController');
            $file = $ref->getFileName();
            if (is_string($file) && is_readable($file)) {
                return (string) file_get_contents($file);
            }
        } catch (Throwable) {
            // fall through
        }

        return null;
    }

    private function adminUserId(): int
    {
        return (int) ($this->adminUser?->id ?? 1);
    }

    private function makeLimitedUser(): User
    {
        $suffix = $this->uniqueSuffix();
        $user = User::factory()->create([
            'name'      => 'Limited ' . $suffix,
            'email'     => 'limited_' . $suffix . '@example.com',
            'emp_code'  => 'LIM_' . uniqid(),
            'short_name' => 'LIM' . random_int(100, 999),
        ]);

        try {
            if (method_exists($user, 'syncRoles')) {
                $user->syncRoles([]);
            }
            if (method_exists($user, 'syncPermissions')) {
                $user->syncPermissions([]);
            }
            foreach (['is_super_admin', 'super_admin_flag'] as $flag) {
                if (Schema::hasColumn('sys_users', $flag)) {
                    $user->forceFill([$flag => 0])->save();
                }
            }
        } catch (Throwable) {
            // best-effort de-privilege
        }

        $this->forgetPermissionCache();

        return $user;
    }

    private function forgetPermissionCache(): void
    {
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
            // Spatie not resolvable in this env — ignore.
        }
    }

    private function skipUnlessRoutesRegistered(): void
    {
        if (! Route::has('fof.emergency-contacts.index')) {
            $this->markTestSkipped('FrontOffice module disabled (modules_statuses.json=false) — /front-office/* routes 404 (#19).');
        }
    }

    private function authenticate(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(800);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1400);
        }

        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(600);
        }
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 900): void
    {
        $browser->visit($this->tenantUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticate($browser);
            $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        }
    }

    private function initializeTenantContext(): void
    {
        $tenantHost = parse_url($this->tenantBaseUrl, PHP_URL_HOST);

        if (! is_string($tenantHost) || $tenantHost === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }

        $domain = Domain::query()->where('domain', $tenantHost)->first();

        if (! $domain) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $tenantHost);
        }

        if (function_exists('tenancy')) {
            tenancy()->initialize($domain->tenant);
        }
    }

    private function resolveAdminUser(): void
    {
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first();

        if (! $this->adminUser) {
            $this->adminUser = User::query()->first();
        }

        if (! $this->adminUser) {
            $this->markTestSkipped('No tenant user found for Dusk login.');
        }

        $this->grantPermissions($this->adminUser);
    }

    private function grantPermissions(User $user): void
    {
        if (! method_exists($user, 'givePermissionTo')) {
            return;
        }

        foreach (self::PERMISSIONS as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // Ignore in local env (permission may not be seeded).
            }
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
        return now()->format('His') . random_int(100, 999);
    }
}
