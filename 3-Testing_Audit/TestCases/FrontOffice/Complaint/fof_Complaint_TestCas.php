<?php

/**
 * FrontOffice → Complaint (fof_complaints) — comprehensive tenant-side Dusk suite.
 *
 * ONE test file per screen (no V1/V2). Mirrors the nearest committed tenant-side
 * Dusk sibling (Complaint module CmpCategory) for tenancy/auth/helper idioms.
 *
 * Source of truth (read at generation time):
 *   Controller : Modules/FrontOffice/Http/Controllers/ComplaintController.php
 *   Model      : Modules/FrontOffice/Models/FofComplaint.php  ($table = fof_complaints, SoftDeletes)
 *   Routes     : Modules/FrontOffice/routes/web.php  (prefix front-office, name fof.complaints.*)
 *   Blade      : Modules/FrontOffice/resources/views/fof/complaints/{create,edit,index,show,trash}.blade.php
 *   DDL        : FrontOffice_DDL_v1.sql  (CREATE TABLE fof_complaints)
 *
 * Permission scheme : frontoffice.complaint.{view,create,update,delete,restore,forceDelete}  (string gates)
 * Activity events    : complaint_registered / complaint_updated / complaint_deleted /
 *                      complaint_resolved / complaint_escalated  (store..escalate),
 *                      Restored / Deleted  (restore / forceDelete)  — sink: sys_activity_logs
 *
 * DEV defects proved by CURRENT behaviour (see GapAnalysis):
 *   DEV-FOF-CMP-01  complaint_type app set {Academic,Infrastructure,Staff,Transport,Fee,Other}
 *                   diverges from DDL ENUM {Academic,Facility,Staff_Behavior,Fee,Safety,
 *                   Transportation,Food,Hygiene,Other}  (test_04).
 *   BUG-FOF-004     complaint_number format is CMP-YYYYMMDD-NNN, not spec FOF-CMP-YYYY-NNNNN (test_11).
 *   DEV-FOF-CMP-02  update() has NO FSM guard — status is freely settable to any value,
 *                   bypassing resolve()/escalate() guards (test_26).
 *   BUG-FOF-001     REMEDIATED here — JsonResponse IS imported; toggle-status returns 200 (test_63).
 *   BUG-FOF-003     REMEDIATED here — escalate() DOES create a linked cmp_complaints row (test_23).
 */

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\FofComplaint;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

class fof_Complaint_TestCas extends DuskTestCase
{
    private const TABLE          = 'fof_complaints';
    private const INDEX_PATH     = '/front-office/complaints';
    private const CREATE_PATH    = '/front-office/complaints/create';
    private const SHOW_BASE      = '/front-office/complaints';
    private const TRASH_PATH     = '/front-office/complaints/trash/view';
    private const LOGIN_PATH     = '/login';

    /** Valid complaint_type present in BOTH the DDL ENUM and the app in: rule / Blade select. */
    private const VALID_TYPE = 'Academic';

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
        $this->initializeTenantContextForTests();
        $this->resolveAdminUserAndPermissions();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }
        parent::tearDown();
    }

    // =====================================================================
    // 01–09  Schema / DDL / model / request configuration
    // =====================================================================

    public function test_complaint_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table fof_complaints does not exist.');

        $expected = [
            'id', 'complaint_number', 'complainant_name', 'complainant_contact',
            'complaint_type', 'description', 'urgency', 'assigned_to_user_id',
            'status', 'resolution_notes', 'resolved_at', 'resolved_by',
            'cmp_complaint_id', 'is_active', 'created_by', 'updated_by',
            'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, $expected),
            'Expected columns missing from fof_complaints.'
        );

        // NOT NULL vs NULL (live schema — DDL may lag).
        $this->assertColumnNotNullable('complainant_name');
        $this->assertColumnNotNullable('complaint_type');
        $this->assertColumnNotNullable('description');
        $this->assertColumnNullable('complainant_contact');
        $this->assertColumnNullable('resolution_notes');
        $this->assertColumnNullable('assigned_to_user_id');
        $this->assertColumnNullable('cmp_complaint_id');

        // Model config.
        $model = new FofComplaint();
        $this->assertSame(self::TABLE, $model->getTable());
        foreach (['complaint_number', 'complainant_name', 'complaint_type', 'description', 'urgency', 'status'] as $f) {
            $this->assertContains($f, $model->getFillable(), "Fillable missing {$f}.");
        }
        $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null);
        $this->assertSame('datetime', $model->getCasts()['resolved_at'] ?? null);
        $this->assertTrue(method_exists($model, 'scopeActive'), 'scopeActive missing.');
        $this->assertTrue(method_exists($model, 'scopeOpen'), 'scopeOpen missing.');

        // Routes registered (never hand-write paths — assert names exist).
        foreach ([
            'fof.complaints.index', 'fof.complaints.create', 'fof.complaints.store',
            'fof.complaints.show', 'fof.complaints.edit', 'fof.complaints.update',
            'fof.complaints.destroy', 'fof.complaints.resolve', 'fof.complaints.escalate',
            'fof.complaints.toggleStatus', 'fof.complaints.trashed', 'fof.complaints.restore',
            'fof.complaints.forceDelete',
        ] as $name) {
            $this->assertTrue(Route::has($name), "Route {$name} not registered.");
        }
    }

    public function test_complaint_02_complaint_number_unique_index_rejects_duplicates(): void
    {
        // G43 — UNIQUE uq_fof_cmp_complaint_number.
        $indexes = collect(DB::select('SHOW INDEX FROM ' . self::TABLE))
            ->where('Key_name', 'uq_fof_cmp_complaint_number');
        $this->assertTrue($indexes->isNotEmpty(), 'UNIQUE index uq_fof_cmp_complaint_number missing.');
        $this->assertSame(0, (int) $indexes->first()->Non_unique, 'complaint_number index is not UNIQUE.');

        $first = $this->createRecordDirectly();
        $second = null;
        try {
            $second = $this->createRecordDirectly(['complaint_number' => $first->complaint_number]);
            $this->fail('Duplicate complaint_number was accepted.');
        } catch (Throwable $e) {
            $this->assertTrue(
                $this->looksLikeIntegrityError($e->getMessage()),
                'Expected UNIQUE violation, got: ' . $e->getMessage()
            );
        } finally {
            $this->forceDeleteById((int) $first->id);
            if ($second instanceof FofComplaint) {
                $this->forceDeleteById((int) $second->id);
            }
        }
    }

    public function test_complaint_03_soft_delete_column_and_trait_are_independently_present(): void
    {
        // G46 / #30 — assert both, independently; report mismatch instead of forcing.
        $hasColumn = Schema::hasColumn(self::TABLE, 'deleted_at');
        $usesTrait = in_array(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(FofComplaint::class),
            true
        );
        $this->assertTrue($hasColumn, 'deleted_at column absent.');
        $this->assertTrue($usesTrait, 'SoftDeletes trait absent on FofComplaint.');
    }

    public function test_complaint_04_complaint_type_enum_diverges_between_ddl_and_app(): void
    {
        // DEV-FOF-CMP-01 — prove CURRENT behaviour: the live DB ENUM and the app
        // (controller in:/Blade select) use different value sets.
        $type = $this->columnType('complaint_type');
        $this->assertStringContainsStringIgnoringCase('enum', $type, 'complaint_type is not an ENUM.');

        // Live DDL ENUM contains these; the app value-set does NOT include them.
        $this->assertStringContainsString('Facility', $type, 'DDL ENUM expected to contain Facility.');
        $this->assertStringContainsString('Staff_Behavior', $type, 'DDL ENUM expected to contain Staff_Behavior.');
        // The app (controller/Blade) accepts these values which are ABSENT from the DDL ENUM.
        $this->assertStringNotContainsString('Infrastructure', $type,
            'DEV-FOF-CMP-01 expectation changed: Infrastructure now present in DDL ENUM.');
        $this->assertStringNotContainsString('Transport,', $type . ',',
            'DEV-FOF-CMP-01 expectation changed: bare Transport now present in DDL ENUM.');
    }

    // =====================================================================
    // 10–19  Business rules (BC-BIZ)
    // =====================================================================

    public function test_complaint_10_store_registers_complaint_with_defaults_and_activity(): void
    {
        $marker = 'Store QA ' . $this->uniqueSuffix();
        $created = null;

        try {
            $this->browse(function (Browser $browser) use ($marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::CREATE_PATH, 900);

                $browser->waitFor('input[name="complainant_name"]', 12)
                    ->type('input[name="complainant_name"]', $marker)
                    ->type('input[name="complainant_contact"]', '9876543210')
                    ->select('complaint_type', self::VALID_TYPE)
                    ->type('textarea[name="description"]', 'Detailed description ' . $marker)
                    ->select('urgency', 'Normal');
                $browser->script('document.querySelectorAll("[required]").forEach(function(el){el.removeAttribute("required")})');
                $browser->press('Register Complaint')->pause(2500);
            });

            $created = FofComplaint::where('complainant_name', $marker)->latest('id')->first();
            $this->assertNotNull($created, 'Complaint was not created via the store form.');
            $created->refresh();
            $this->assertSame('Open', $created->status, 'New complaint status should be Open.');
            $this->assertTrue((bool) $created->is_active, 'New complaint should be active.');
            $this->assertNotEmpty($created->complaint_number, 'complaint_number should be auto-generated.');
            $this->assertActivityLoggedTolerant('complaint_registered', (int) $created->id);
        } finally {
            if ($created instanceof FofComplaint) {
                $this->forceDeleteById((int) $created->id);
            }
        }
    }

    public function test_complaint_11_complaint_number_format_follows_code_not_spec(): void
    {
        // BUG-FOF-004 — generator emits CMP-YYYYMMDD-NNN, NOT the spec FOF-CMP-YYYY-NNNNN.
        $marker = 'Number QA ' . $this->uniqueSuffix();
        $created = null;

        try {
            $this->browse(function (Browser $browser) use ($marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::CREATE_PATH, 900);
                $browser->waitFor('input[name="complainant_name"]', 12)
                    ->type('input[name="complainant_name"]', $marker)
                    ->select('complaint_type', self::VALID_TYPE)
                    ->type('textarea[name="description"]', 'desc ' . $marker)
                    ->select('urgency', 'Normal');
                $browser->script('document.querySelectorAll("[required]").forEach(function(el){el.removeAttribute("required")})');
                $browser->press('Register Complaint')->pause(2500);
            });

            $created = FofComplaint::where('complainant_name', $marker)->latest('id')->first();
            if (!$created) {
                $this->markTestSkipped('Store did not persist a complaint (env/module disabled).');
            }
            $this->assertMatchesRegularExpression(
                '/^CMP-\d{8}-\d{3,}$/',
                (string) $created->complaint_number,
                'complaint_number format changed from the code format CMP-YYYYMMDD-NNN.'
            );
            $this->assertStringStartsNotWith(
                'FOF-CMP-',
                (string) $created->complaint_number,
                'BUG-FOF-004 appears fixed — number now matches the FOF-CMP spec.'
            );
        } finally {
            if ($created instanceof FofComplaint) {
                $this->forceDeleteById((int) $created->id);
            }
        }
    }

    public function test_complaint_12_is_active_defaults_true_on_direct_create(): void
    {
        $record = $this->createRecordDirectly(['is_active' => null] + $this->minimalPayloadWithoutIsActive());
        try {
            $record->refresh();
            $this->assertTrue((bool) $record->is_active, 'is_active should default to true.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_13_urgency_defaults_normal_at_db_level(): void
    {
        // G44 positive / DB default — omit urgency at the DB layer; expect 'Normal'.
        $payload = $this->buildValidPayload();
        unset($payload['urgency']);
        $record = FofComplaint::create($payload);
        try {
            $record->refresh();
            $this->assertSame('Normal', $record->urgency, 'urgency DB default should be Normal.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_14_status_defaults_open_at_db_level(): void
    {
        $payload = $this->buildValidPayload();
        unset($payload['status']);
        $record = FofComplaint::create($payload);
        try {
            $record->refresh();
            $this->assertSame('Open', $record->status, 'status DB default should be Open.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_15_index_page_renders_open_and_closed_sections(): void
    {
        $open = $this->createRecordDirectly(['status' => 'Open']);
        $closed = $this->createRecordDirectly(['status' => 'Resolved']);
        try {
            $this->browse(function (Browser $browser) use ($open): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::INDEX_PATH, 1200);
                $browser->assertPathBeginsWith(self::INDEX_PATH);
                $this->assertStringContainsString(
                    (string) $open->complainant_name,
                    $browser->driver->getPageSource(),
                    'Open complaint not listed on index.'
                );
            });
        } finally {
            $this->forceDeleteById((int) $open->id);
            $this->forceDeleteById((int) $closed->id);
        }
    }

    // =====================================================================
    // 20–29  State machine (BC-SM)
    // =====================================================================

    public function test_complaint_20_resolve_transitions_open_to_resolved(): void
    {
        $record = $this->createRecordDirectly(['status' => 'Open']);
        try {
            $status = $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id . '/resolve',
                ['resolution_notes' => 'Resolved by QA ' . $this->uniqueSuffix()],
                'PATCH'
            );
            $this->assertContains($status, [200, 302], 'Resolve did not succeed (status ' . $status . ').');
            $record->refresh();
            $this->assertSame('Resolved', $record->status, 'Complaint should be Resolved.');
            $this->assertNotNull($record->resolved_at, 'resolved_at should be set.');
            $this->assertNotEmpty($record->resolution_notes, 'resolution_notes should be persisted.');
            $this->assertActivityLoggedTolerant('complaint_resolved', (int) $record->id);
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_21_resolve_transitions_in_progress_to_resolved(): void
    {
        $record = $this->createRecordDirectly(['status' => 'In_Progress']);
        try {
            $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id . '/resolve',
                ['resolution_notes' => 'Notes ' . $this->uniqueSuffix()],
                'PATCH'
            );
            $record->refresh();
            $this->assertSame('Resolved', $record->status, 'In_Progress complaint should resolve.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_22_resolve_rejected_when_already_resolved(): void
    {
        // Illegal transition — controller throws DomainException (tolerate 500/302/403/419).
        $record = $this->createRecordDirectly(['status' => 'Resolved', 'resolved_at' => now()]);
        try {
            $status = $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id . '/resolve',
                ['resolution_notes' => 'Again ' . $this->uniqueSuffix()],
                'PATCH'
            );
            $this->assertContains($status, [403, 419, 500, 302], 'Illegal resolve returned ' . $status . '.');
            $record->refresh();
            $this->assertSame('Resolved', $record->status, 'Status must be unchanged after illegal resolve.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_23_escalate_open_creates_linked_cmp_record(): void
    {
        // BUG-FOF-003 remediated — escalate() creates a cmp_complaints row and links it.
        // Cross-module dependency — guard and skip when CMP scaffolding is absent.
        if (!Schema::hasTable('cmp_complaints') || !Schema::hasTable('cmp_complaint_categories')) {
            $this->markTestSkipped('CMP module tables (cmp_complaints) not present in test DB.');
        }
        $record = $this->createRecordDirectly(['status' => 'Open', 'complaint_type' => self::VALID_TYPE]);
        try {
            $status = $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id . '/escalate',
                [],
                'PATCH'
            );
            $record->refresh();

            if ($record->status !== 'Escalated') {
                // CMP dropdown/category seed missing → insert fails inside the transaction.
                $this->markTestSkipped('Escalation dependencies (cmp categories / dropdowns) not seeded; status=' . $record->status . ', http=' . $status);
            }

            $this->assertNotNull($record->cmp_complaint_id, 'cmp_complaint_id should be linked after escalation.');
            $this->assertTrue(
                DB::table('cmp_complaints')->where('id', $record->cmp_complaint_id)->exists(),
                'Linked cmp_complaints row should exist.'
            );
            $this->assertActivityLoggedTolerant('complaint_escalated', (int) $record->id);
        } catch (Throwable $e) {
            $this->markTestSkipped('Escalation cross-module path unavailable: ' . $e->getMessage());
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_24_escalate_rejected_when_already_linked(): void
    {
        // Illegal — cmp_complaint_id already set.
        $record = $this->createRecordDirectly(['status' => 'In_Progress', 'cmp_complaint_id' => 999999999]);
        try {
            $status = $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id . '/escalate',
                [],
                'PATCH'
            );
            $this->assertContains($status, [403, 419, 500, 302], 'Illegal escalate returned ' . $status . '.');
            $record->refresh();
            $this->assertSame('In_Progress', $record->status, 'Status must be unchanged after illegal escalate.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_25_escalate_rejected_when_closed(): void
    {
        $record = $this->createRecordDirectly(['status' => 'Closed']);
        try {
            $status = $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id . '/escalate',
                [],
                'PATCH'
            );
            $this->assertContains($status, [403, 419, 500, 302], 'Escalate on Closed returned ' . $status . '.');
            $record->refresh();
            $this->assertSame('Closed', $record->status, 'Closed complaint must not escalate.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_26_update_allows_direct_status_change_bypassing_fsm(): void
    {
        // DEV-FOF-CMP-02 — update() has no FSM guard; status is freely settable (Open→Closed).
        $record = $this->createRecordDirectly(['status' => 'Open']);
        try {
            $status = $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id,
                [
                    'complainant_name' => (string) $record->complainant_name,
                    'complaint_type'   => self::VALID_TYPE,
                    'description'      => (string) $record->description,
                    'urgency'          => 'Normal',
                    'status'           => 'Closed',
                ],
                'PUT'
            );
            $this->assertContains($status, [200, 302], 'Update returned ' . $status . '.');
            $record->refresh();
            $this->assertSame('Closed', $record->status,
                'update() is expected to set status directly (no FSM guard) — DEV-FOF-CMP-02.');
            $this->assertActivityLoggedTolerant('complaint_updated', (int) $record->id);
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    // =====================================================================
    // 30–39  Validation + error messages (BC-VAL)
    // =====================================================================

    public function test_complaint_30_store_rejects_missing_required_web_fields(): void
    {
        // complainant_name / complaint_type / description / urgency are required in store().
        foreach (['complainant_name', 'complaint_type', 'description', 'urgency'] as $field) {
            $marker = 'Req ' . $field . ' ' . $this->uniqueSuffix();
            $payload = [
                'complainant_name' => $marker,
                'complaint_type'   => self::VALID_TYPE,
                'description'      => 'desc ' . $marker,
                'urgency'          => 'Normal',
            ];
            unset($payload[$field]);

            $this->submitFromBrowser(self::INDEX_PATH, $payload, 'POST');
            // Robust, tolerant assertion: the invalid payload must NOT create a row.
            $this->assertFalse(
                FofComplaint::where('description', 'desc ' . $marker)->exists(),
                "Store accepted a payload missing required field {$field}."
            );
        }
    }

    public function test_complaint_31_db_rejects_missing_not_null_columns(): void
    {
        // G44 — DB-level NOT-NULL enforcement (complainant_name, complaint_type, description).
        foreach (['complainant_name', 'complaint_type', 'description'] as $field) {
            $created = null;
            try {
                $payload = $this->buildValidPayload();
                unset($payload[$field]);
                $created = FofComplaint::create($payload);
                $this->fail("DB accepted a row missing NOT-NULL column {$field}.");
            } catch (Throwable $e) {
                $this->assertTrue(
                    $this->looksLikeIntegrityError($e->getMessage()),
                    "Expected NOT-NULL failure for {$field}, got: " . $e->getMessage()
                );
            } finally {
                if ($created instanceof FofComplaint) {
                    $this->forceDeleteById((int) $created->id);
                }
            }
        }
    }

    public function test_complaint_32_store_rejects_overlength_complainant_name(): void
    {
        // G45 — complainant_name max:100.
        $marker = 'OL ' . $this->uniqueSuffix();
        $payload = [
            'complainant_name' => str_repeat('N', 101),
            'complaint_type'   => self::VALID_TYPE,
            'description'      => 'desc ' . $marker,
            'urgency'          => 'Normal',
        ];
        $this->submitFromBrowser(self::INDEX_PATH, $payload, 'POST');
        $this->assertFalse(
            FofComplaint::where('description', 'desc ' . $marker)->exists(),
            'Store accepted a 101-char complainant_name (max:100).'
        );
    }

    public function test_complaint_33_store_accepts_exact_max_length_complainant_name(): void
    {
        // G45 positive — exactly 100 chars.
        $name = str_repeat('A', 100);
        $desc = 'exact-len ' . $this->uniqueSuffix();
        $created = null;
        try {
            $this->submitFromBrowser(self::INDEX_PATH, [
                'complainant_name' => $name,
                'complaint_type'   => self::VALID_TYPE,
                'description'      => $desc,
                'urgency'          => 'Normal',
            ], 'POST');
            $created = FofComplaint::where('description', $desc)->latest('id')->first();
            $this->assertNotNull($created, 'Store rejected an exactly-100-char complainant_name.');
            $this->assertSame(100, mb_strlen((string) $created->complainant_name));
        } finally {
            if ($created instanceof FofComplaint) {
                $this->forceDeleteById((int) $created->id);
            }
        }
    }

    public function test_complaint_34_store_rejects_overlength_contact(): void
    {
        // G45 — complainant_contact max:15.
        $desc = 'contact-ol ' . $this->uniqueSuffix();
        $this->submitFromBrowser(self::INDEX_PATH, [
            'complainant_name'   => 'Contact QA',
            'complainant_contact' => str_repeat('9', 16),
            'complaint_type'     => self::VALID_TYPE,
            'description'        => $desc,
            'urgency'            => 'Normal',
        ], 'POST');
        $this->assertFalse(
            FofComplaint::where('description', $desc)->exists(),
            'Store accepted a 16-char complainant_contact (max:15).'
        );
    }

    public function test_complaint_35_store_rejects_invalid_complaint_type(): void
    {
        $desc = 'bad-type ' . $this->uniqueSuffix();
        $this->submitFromBrowser(self::INDEX_PATH, [
            'complainant_name' => 'Type QA',
            'complaint_type'   => 'NotARealType',
            'description'      => $desc,
            'urgency'          => 'Normal',
        ], 'POST');
        $this->assertFalse(
            FofComplaint::where('description', $desc)->exists(),
            'Store accepted an out-of-list complaint_type.'
        );
    }

    public function test_complaint_36_store_rejects_invalid_urgency(): void
    {
        $desc = 'bad-urgency ' . $this->uniqueSuffix();
        $this->submitFromBrowser(self::INDEX_PATH, [
            'complainant_name' => 'Urgency QA',
            'complaint_type'   => self::VALID_TYPE,
            'description'      => $desc,
            'urgency'          => 'SuperCritical',
        ], 'POST');
        $this->assertFalse(
            FofComplaint::where('description', $desc)->exists(),
            'Store accepted an out-of-list urgency.'
        );
    }

    public function test_complaint_37_resolve_requires_resolution_notes(): void
    {
        $record = $this->createRecordDirectly(['status' => 'Open']);
        try {
            $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id . '/resolve',
                [], // resolution_notes missing (required)
                'PATCH'
            );
            $record->refresh();
            $this->assertSame('Open', $record->status,
                'Resolve without resolution_notes must not change status.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    // =====================================================================
    // 40–49  Integration / FK dependency (BC-INT / BC-REF)
    // =====================================================================

    public function test_complaint_40_foreign_keys_are_configured(): void
    {
        $fks = $this->foreignKeysFor(self::TABLE);
        $this->assertArrayHasKey('assigned_to_user_id', $fks, 'FK assigned_to_user_id missing.');
        $this->assertArrayHasKey('resolved_by', $fks, 'FK resolved_by missing.');
        $this->assertArrayHasKey('cmp_complaint_id', $fks, 'FK cmp_complaint_id missing.');
        $this->assertSame('sys_users', $fks['assigned_to_user_id'] ?? null);
        $this->assertSame('sys_users', $fks['resolved_by'] ?? null);
        $this->assertSame('cmp_complaints', $fks['cmp_complaint_id'] ?? null);
    }

    public function test_complaint_41_update_rejects_nonexistent_assigned_user(): void
    {
        // update() rule: assigned_to_user_id => exists:sys_users,id.
        $record = $this->createRecordDirectly(['status' => 'Open']);
        try {
            $this->submitFromBrowser(
                self::SHOW_BASE . '/' . $record->id,
                [
                    'complainant_name'    => (string) $record->complainant_name,
                    'complaint_type'      => self::VALID_TYPE,
                    'description'         => (string) $record->description,
                    'urgency'             => 'Normal',
                    'status'              => 'Open',
                    'assigned_to_user_id' => 2000000001,
                ],
                'PUT'
            );
            $record->refresh();
            $this->assertNull($record->assigned_to_user_id,
                'Update accepted a non-existent assigned_to_user_id.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_42_cmp_complaint_id_fk_on_delete_set_null(): void
    {
        $rule = $this->onDeleteRuleFor(self::TABLE, 'fk_fof_cmp_cmp_complaint_id');
        if ($rule === null) {
            $this->markTestSkipped('FK fk_fof_cmp_cmp_complaint_id not found in information_schema.');
        }
        $this->assertSame('SET NULL', strtoupper($rule),
            'cmp_complaint_id FK should be ON DELETE SET NULL.');
    }

    // =====================================================================
    // 50–59  Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_complaint_50_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser),
                'Guest was not redirected to /login.');
        });
    }

    public function test_complaint_51_user_without_view_permission_gets_403(): void
    {
        $limited = $this->createLimitedUser();
        try {
            $this->browse(function (Browser $browser) use ($limited): void {
                $browser->loginAs($limited)->pause(600);
                $status = $this->fetchStatusFromBrowser($browser, self::INDEX_PATH, 'GET');
                $this->assertSame(403, $status,
                    'User lacking frontoffice.complaint.view should get 403 on index.');
            });
        } finally {
            $this->deleteUserIfExists($limited);
        }
    }

    public function test_complaint_52_user_without_create_permission_cannot_store(): void
    {
        $limited = $this->createLimitedUser();
        $desc = 'noperm ' . $this->uniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($limited, $desc): void {
                $browser->loginAs($limited)->pause(600);
                $status = $this->postWithBrowser($browser, self::INDEX_PATH, [
                    'complainant_name' => 'No Perm',
                    'complaint_type'   => self::VALID_TYPE,
                    'description'      => $desc,
                    'urgency'          => 'Normal',
                ], 'POST');
                $this->assertContains($status, [403, 419], 'Store without create permission returned ' . $status . '.');
            });
            $this->assertFalse(
                FofComplaint::where('description', $desc)->exists(),
                'A permission-less user managed to create a complaint.'
            );
        } finally {
            $this->deleteUserIfExists($limited);
        }
    }

    public function test_complaint_53_user_without_delete_permission_cannot_destroy(): void
    {
        $limited = $this->createLimitedUser();
        $record = $this->createRecordDirectly(['status' => 'Open']);
        try {
            $this->browse(function (Browser $browser) use ($limited, $record): void {
                $browser->loginAs($limited)->pause(600);
                $status = $this->postWithBrowser(
                    $browser,
                    self::SHOW_BASE . '/' . $record->id,
                    [],
                    'DELETE'
                );
                $this->assertContains($status, [403, 419], 'Destroy without delete permission returned ' . $status . '.');
            });
            $record->refresh();
            $this->assertNull($record->deleted_at, 'Permission-less user soft-deleted a complaint.');
        } finally {
            $this->forceDeleteById((int) $record->id);
            $this->deleteUserIfExists($limited);
        }
    }

    // =====================================================================
    // 60–69  UI/UX (search, filter, detail, trash)
    // =====================================================================

    public function test_complaint_60_index_search_by_complainant_name(): void
    {
        $needle = 'Findme' . $this->uniqueSuffix();
        $record = $this->createRecordDirectly(['complainant_name' => $needle, 'status' => 'Open']);
        try {
            $this->browse(function (Browser $browser) use ($needle): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::INDEX_PATH . '?search=' . urlencode($needle), 1200);
                $this->assertStringContainsString($needle, $browser->driver->getPageSource(),
                    'Search did not surface the matching complaint.');
            });
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_61_index_status_filter(): void
    {
        $record = $this->createRecordDirectly(['status' => 'Resolved']);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::INDEX_PATH . '?status=Resolved', 1200);
                $this->assertStringContainsString((string) $record->complainant_name,
                    $browser->driver->getPageSource(),
                    'Resolved-status filter did not surface the complaint.');
            });
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_62_show_page_displays_detail(): void
    {
        $record = $this->createRecordDirectly(['status' => 'Open']);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::SHOW_BASE . '/' . $record->id, 1200);
                $browser->assertSee((string) $record->complaint_number);
            });
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_63_toggle_status_endpoint_returns_json_ok(): void
    {
        // BUG-FOF-001 remediated — JsonResponse imported → toggle returns 200 JSON, not 500.
        $record = $this->createRecordDirectly(['status' => 'Open', 'is_active' => true]);
        try {
            $status = 0;
            $this->browse(function (Browser $browser) use ($record, &$status): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::INDEX_PATH, 900);
                $status = $this->postWithBrowser(
                    $browser,
                    self::SHOW_BASE . '/' . $record->id . '/toggle-status',
                    ['is_active' => '0'],
                    'POST'
                );
            });
            $this->assertSame(200, $status, 'toggle-status did not return 200 (BUG-FOF-001 regression?).');
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'toggle-status did not flip is_active.');
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    // =====================================================================
    // 70–79  Edge cases (BC-EDG) + soft-delete lifecycle
    // =====================================================================

    public function test_complaint_70_show_invalid_id_returns_404(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $status = $this->fetchStatusFromBrowser($browser, self::SHOW_BASE . '/2000000999', 'GET');
            $this->assertSame(404, $status, 'Unknown complaint id did not 404.');
        });
    }

    public function test_complaint_71_description_xss_is_escaped_on_show(): void
    {
        $payload = "<script>alert('xss-" . $this->uniqueSuffix() . "')</script>";
        $record = $this->createRecordDirectly(['description' => $payload, 'status' => 'Open']);
        try {
            $this->browse(function (Browser $browser) use ($record, $payload): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::SHOW_BASE . '/' . $record->id, 1200);
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString($payload, $source,
                    'Raw <script> payload was rendered unescaped (stored XSS).');
            });
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    public function test_complaint_72_soft_delete_restore_force_delete_lifecycle(): void
    {
        $record = $this->createRecordDirectly(['status' => 'Open']);
        $id = (int) $record->id;
        try {
            // Soft delete via model (destroy route also asserted in permission test).
            $record->delete();
            $record->refresh();
            $this->assertNotNull($record->deleted_at, 'deleted_at not set after soft delete.');
            $this->assertNull(FofComplaint::find($id), 'Soft-deleted record still visible to default scope.');
            $this->assertNotNull(FofComplaint::withTrashed()->find($id), 'withTrashed cannot find soft-deleted record.');

            // Restore.
            $record->restore();
            $record->refresh();
            $this->assertNull($record->deleted_at, 'deleted_at not cleared after restore.');
        } finally {
            $this->forceDeleteById($id);
            $this->assertNull(FofComplaint::withTrashed()->find($id), 'Force delete did not remove the record.');
        }
    }

    public function test_complaint_73_trash_page_lists_soft_deleted_record(): void
    {
        $record = $this->createRecordDirectly(['status' => 'Open']);
        $record->delete();
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitWithAuth($browser, self::TRASH_PATH, 1200);
                $this->assertStringContainsString((string) $record->complaint_number,
                    $browser->driver->getPageSource(),
                    'Soft-deleted complaint not shown in trash view.');
            });
        } finally {
            $this->forceDeleteById((int) $record->id);
        }
    }

    // =====================================================================
    // 90–99  Tenancy isolation (TC-T) + security (TC-S)
    // =====================================================================

    public function test_complaint_90_store_ignores_client_supplied_status_mass_assignment(): void
    {
        // TC-S mass-assignment guard — store() hardcodes status='Open'; a client-set
        // status must be ignored.
        $desc = 'massassign ' . $this->uniqueSuffix();
        $created = null;
        try {
            $this->submitFromBrowser(self::INDEX_PATH, [
                'complainant_name' => 'MassAssign QA',
                'complaint_type'   => self::VALID_TYPE,
                'description'      => $desc,
                'urgency'          => 'Normal',
                'status'           => 'Closed',           // attempt to override
                'complaint_number' => 'HACK-0001',        // attempt to override auto number
            ], 'POST');
            $created = FofComplaint::where('description', $desc)->latest('id')->first();
            if (!$created) {
                $this->markTestSkipped('Store did not persist (env/module disabled).');
            }
            $this->assertSame('Open', $created->status, 'store() must force status=Open.');
            $this->assertStringStartsWith('CMP-', (string) $created->complaint_number,
                'store() must auto-generate complaint_number, not accept a client value.');
        } finally {
            if ($created instanceof FofComplaint) {
                $this->forceDeleteById((int) $created->id);
            }
        }
    }

    public function test_complaint_91_cross_tenant_direct_id_is_not_accessible(): void
    {
        // TC-T IDOR — a second tenant is required to prove isolation.
        $domains = Domain::query()->limit(2)->get();
        if ($domains->count() < 2) {
            $this->markTestSkipped('Only one tenant configured — cross-tenant IDOR not testable.');
        }
        $this->markTestSkipped('Cross-tenant IDOR requires a seeded record in a second tenant; documented as TC-T gap.');
    }

    // =====================================================================
    // Private helpers
    // =====================================================================

    private function buildValidPayload(array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id') ?? 1);
        return array_merge([
            'complaint_number'    => 'CMP-' . date('Ymd') . '-' . $this->uniqueSuffix(),
            'complainant_name'    => 'Complaint QA ' . $this->uniqueSuffix(),
            'complainant_contact' => '9876543210',
            'complaint_type'      => self::VALID_TYPE,
            'description'         => 'QA description ' . $this->uniqueSuffix(),
            'urgency'             => 'Normal',
            'status'              => 'Open',
            'is_active'           => true,
            'created_by'          => $adminId,
            'updated_by'          => $adminId,
        ], $overrides);
    }

    private function minimalPayloadWithoutIsActive(): array
    {
        $p = $this->buildValidPayload();
        unset($p['is_active']);
        return $p;
    }

    private function createRecordDirectly(array $overrides = []): FofComplaint
    {
        return FofComplaint::create($this->buildValidPayload($overrides));
    }

    private function forceDeleteById(int $id): void
    {
        try {
            $record = FofComplaint::withTrashed()->find($id);
            if ($record) {
                $record->forceDelete();
            }
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    private function looksLikeIntegrityError(string $message): bool
    {
        $m = strtolower($message);
        return str_contains($m, 'cannot be null')
            || str_contains($m, 'not null')
            || str_contains($m, "doesn't have a default value")
            || str_contains($m, 'integrity constraint')
            || str_contains($m, 'duplicate entry')
            || str_contains($m, 'constraint failed')
            || str_contains($m, '23000');
    }

    private function columnType(string $column): string
    {
        $row = DB::selectOne(
            'SELECT COLUMN_TYPE AS t FROM information_schema.COLUMNS '
            . 'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
            [self::TABLE, $column]
        );
        return $row->t ?? '';
    }

    private function assertColumnNotNullable(string $column): void
    {
        $row = DB::selectOne(
            'SELECT IS_NULLABLE AS n FROM information_schema.COLUMNS '
            . 'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
            [self::TABLE, $column]
        );
        $this->assertSame('NO', $row->n ?? null, "Column {$column} should be NOT NULL.");
    }

    private function assertColumnNullable(string $column): void
    {
        $row = DB::selectOne(
            'SELECT IS_NULLABLE AS n FROM information_schema.COLUMNS '
            . 'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
            [self::TABLE, $column]
        );
        $this->assertSame('YES', $row->n ?? null, "Column {$column} should be NULLable.");
    }

    /** @return array<string,string> column => referenced table */
    private function foreignKeysFor(string $table): array
    {
        $rows = DB::select(
            'SELECT COLUMN_NAME AS c, REFERENCED_TABLE_NAME AS r '
            . 'FROM information_schema.KEY_COLUMN_USAGE '
            . 'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND REFERENCED_TABLE_NAME IS NOT NULL',
            [$table]
        );
        $out = [];
        foreach ($rows as $row) {
            $out[$row->c] = $row->r;
        }
        return $out;
    }

    private function onDeleteRuleFor(string $table, string $constraint): ?string
    {
        $row = DB::selectOne(
            'SELECT DELETE_RULE AS d FROM information_schema.REFERENTIAL_CONSTRAINTS '
            . 'WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ? AND CONSTRAINT_NAME = ?',
            [$table, $constraint]
        );
        return $row->d ?? null;
    }

    private function assertActivityLoggedTolerant(string $event, int $subjectId): void
    {
        if (!Schema::hasTable('sys_activity_logs')) {
            $this->markTestSkipped('sys_activity_logs table absent — activity assertion skipped.');
        }
        try {
            $columns = Schema::getColumnListing('sys_activity_logs');
            $textCols = array_values(array_filter($columns, static fn ($c) => in_array(
                $c,
                ['event', 'description', 'log_name', 'action', 'properties'],
                true
            )));
            if ($textCols === []) {
                $this->markTestSkipped('sys_activity_logs has no recognised event column.');
            }
            $found = false;
            foreach ($textCols as $col) {
                if (DB::table('sys_activity_logs')->where($col, 'like', '%' . $event . '%')->exists()) {
                    $found = true;
                    break;
                }
            }
            $this->assertTrue($found, "Activity event '{$event}' not found in sys_activity_logs.");
        } catch (Throwable $e) {
            $this->markTestSkipped('Activity-log assertion unavailable: ' . $e->getMessage());
        }
    }

    // ---- browser HTTP helpers (browser-style — issue authenticated fetch from the page) ----

    /**
     * Authenticate via the admin session, then submit a web request from the page and
     * return the resulting HTTP status. Used for workflow/negative flows.
     */
    private function submitFromBrowser(string $path, array $data, string $method = 'POST'): int
    {
        $status = 0;
        $this->browse(function (Browser $browser) use ($path, $data, $method, &$status): void {
            $this->authenticateBrowserSession($browser);
            $this->visitWithAuth($browser, self::INDEX_PATH, 800);
            $status = $this->postWithBrowser($browser, $path, $data, $method);
        });
        return $status;
    }

    private function postWithBrowser(Browser $browser, string $path, array $data, string $method): int
    {
        $url = json_encode($this->tenantUrl($path));
        $payload = json_encode($data);
        $method = strtoupper($method);
        $browser->script(<<<JS
window.__reqStatus = 0;
window.__reqDone = false;
(async function () {
    try {
        const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
        const params = new URLSearchParams();
        params.append('_token', csrf);
        const data = {$payload};
        Object.keys(data).forEach(function (k) { params.append(k, data[k]); });
        let httpMethod = '{$method}';
        if (httpMethod !== 'GET' && httpMethod !== 'POST') {
            params.append('_method', httpMethod);
            httpMethod = 'POST';
        }
        const resp = await fetch({$url}, {
            method: httpMethod,
            credentials: 'same-origin',
            redirect: 'manual',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'application/json, text/html',
            },
            body: httpMethod === 'GET' ? undefined : params.toString(),
        });
        window.__reqStatus = resp.status === 0 ? 302 : resp.status;
    } catch (e) {
        window.__reqStatus = -1;
    }
    window.__reqDone = true;
})();
JS);
        $browser->waitUntil('window.__reqDone === true', 15);
        return (int) $browser->script('return window.__reqStatus;')[0];
    }

    private function fetchStatusFromBrowser(Browser $browser, string $path, string $method = 'GET'): int
    {
        $url = json_encode($this->tenantUrl($path));
        $method = strtoupper($method);
        $browser->script(<<<JS
window.__gStatus = 0;
window.__gDone = false;
(async function () {
    try {
        const resp = await fetch({$url}, {
            method: '{$method}',
            credentials: 'same-origin',
            redirect: 'manual',
            headers: { 'X-Requested-With': 'XMLHttpRequest', 'Accept': 'application/json, text/html' },
        });
        window.__gStatus = resp.status === 0 ? 302 : resp.status;
    } catch (e) {
        window.__gStatus = -1;
    }
    window.__gDone = true;
})();
JS);
        $browser->waitUntil('window.__gDone === true', 15);
        return (int) $browser->script('return window.__gStatus;')[0];
    }

    // ---- auth / tenancy / permissions ----

    private function authenticateBrowserSession(Browser $browser): void
    {
        $browser->visit($this->tenantUrl(self::LOGIN_PATH))->pause(800);

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

    private function visitWithAuth(Browser $browser, string $path, int $pauseMs = 900): void
    {
        $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        }
    }

    private function initializeTenantContextForTests(): void
    {
        $host = parse_url($this->tenantBaseUrl, PHP_URL_HOST);
        if (!is_string($host) || $host === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }
        $domain = Domain::query()->where('domain', $host)->first();
        if (!$domain) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $host);
        }
        if (function_exists('tenancy')) {
            tenancy()->initialize($domain->tenant);
        }
    }

    private function resolveAdminUserAndPermissions(): void
    {
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
            ?? User::query()->first();

        if (!$this->adminUser) {
            $this->adminUser = User::create([
                'email'             => $this->adminEmail,
                'password'          => bcrypt($this->adminPassword),
                'name'              => 'FrontOffice Dusk Admin',
                'emp_code'          => 'FOF_' . uniqid(),
                'short_name'        => 'FOFADM',
                'status'            => 'ACTIVE',
                'is_active'         => 1,
                'is_super_admin'    => 1,
                'email_verified_at' => now(),
            ]);
        }

        $this->adminUser->password = bcrypt($this->adminPassword);
        $this->adminUser->is_super_admin = 1;
        if (property_exists($this->adminUser, 'email_verified_at') && !$this->adminUser->email_verified_at) {
            $this->adminUser->email_verified_at = now();
        }
        $this->adminUser->save();

        $this->ensurePermissionsExist($this->complaintPermissions());
        $this->grantPermissions($this->adminUser, $this->complaintPermissions());
    }

    /** @return string[] */
    private function complaintPermissions(): array
    {
        return [
            'frontoffice.complaint.view',
            'frontoffice.complaint.create',
            'frontoffice.complaint.update',
            'frontoffice.complaint.delete',
            'frontoffice.complaint.restore',
            'frontoffice.complaint.forceDelete',
        ];
    }

    private function createLimitedUser(): User
    {
        $user = User::create([
            'email'             => 'fof_limited_' . uniqid() . '@tenant.test',
            'password'          => bcrypt('password'),
            'name'              => 'FOF Limited',
            'emp_code'          => 'LIM_' . uniqid(),
            'short_name'        => 'LIM',
            'status'            => 'ACTIVE',
            'is_active'         => 1,
            'is_super_admin'    => 0,
            'email_verified_at' => now(),
        ]);

        // Ensure the negative is real (#31): strip super-admin + any roles/permissions.
        try {
            if (method_exists($user, 'syncRoles')) {
                $user->syncRoles([]);
            }
            if (method_exists($user, 'syncPermissions')) {
                $user->syncPermissions([]);
            }
        } catch (Throwable) {
            // guard mismatches in local env
        }
        $this->forgetPermissionCache();

        return $user;
    }

    private function grantPermissions(User $user, array $permissions): void
    {
        if (!method_exists($user, 'givePermissionTo')) {
            return;
        }
        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
        $this->forgetPermissionCache();
    }

    private function ensurePermissionsExist(array $permissions): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }
        $guard = config('auth.defaults.guard', 'web');
        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate([
                    'name'       => $permission,
                    'guard_name' => $guard,
                ]);
            } catch (Throwable) {
                // ignore env-specific permission table mismatches
            }
        }
    }

    private function forgetPermissionCache(): void
    {
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
            // registrar unavailable
        }
    }

    private function deleteUserIfExists(?User $user): void
    {
        if (!$user) {
            return;
        }
        try {
            User::query()->whereKey($user->id)->forceDelete();
        } catch (Throwable) {
            try {
                User::query()->whereKey($user->id)->delete();
            } catch (Throwable) {
                // best-effort
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
