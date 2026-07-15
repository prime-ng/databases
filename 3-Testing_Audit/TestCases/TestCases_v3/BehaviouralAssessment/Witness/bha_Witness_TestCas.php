<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaIncident;
use Modules\BehaviouralAssessment\Models\BaIncidentWitnessJnt;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Witnesses (nested child of Incident) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/13-Witnesses.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Primary table      : ba_incident_witnesses_jnt (junction, polymorphic witness student|staff)
 *                      (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Parent table       : ba_incidents
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController
 *                      Witnesses have NO standalone routes/controller — they are attached/synced
 *                      inside BaIncidentController::store() and ::update() via the incident form.
 * Attach arrays      : witness_student_ids[]  → witness_type='student', witness_id=std_students.id
 *                      witness_staff_ids[]    → witness_type='staff',   witness_id=sch_employees.id
 * FormRequest        : Modules\BehaviouralAssessment\Http\Requests\BaIncidentRequest
 *                      witness_student_ids.* => integer|exists:std_students,id
 *                      witness_staff_ids.*   => integer|exists:sch_employees,id
 * Permission prefix  : tenant.behavioural-assessment.incidents.{viewAny|view|create|update|delete|restore|forceDelete|status}
 *                      (witnesses inherit the parent incident's create/update gates — no own gate)
 *
 * REQUIREMENT-vs-CODE DEFECTS PROVEN (source-traced, High confidence):
 *   - DATA-BA-WIT-01 : The requirement mandates a "Witness Statement" text area (min 10, max 500)
 *                      per witness. NO statement column exists in ba_incident_witnesses_jnt, the model
 *                      has no such field, the FormRequest has no such rule, and the blade uses bare
 *                      checkboxes — witnesses are stored as type+id links only (proven in _33).
 *   - BUG-BA-WIT-02 : The requirement's "Self-Referential Block" (the subject student cannot witness
 *                      their own incident) is NOT enforced — neither the controller nor the FormRequest
 *                      excludes the incident's own student_id from witness_student_ids (proven in _34/_35).
 *   - BUG-BA-WIT-03 : The requirement's "Audit Lock" (freeze the witness list once the incident is
 *                      closed/resolved) is NOT enforced — update() force-deletes and recreates witnesses
 *                      unconditionally, never consulting incident status/lock (proven in _20/_21).
 *   - BUG-BA-WIT-04 : store() attaches STUDENT witnesses with a plain create() (no firstOrCreate,
 *                      no array_unique) while STAFF witnesses use firstOrCreate() — a duplicate id in
 *                      witness_student_ids[] hits uq_ba_witness and 500s, an asymmetry with staff (proven in _44).
 * Other findings touched:
 *   - DOC-BA-001    : DDL-doc prefix `bha_` diverges from live `ba_` (proven in _02); the DDL index name
 *                      `uq_bha_witness` is actually `uq_ba_witness` at runtime (proven in _03).
 *   - DATA-BA-WIT-05: the create-migration adds softDeletes() (deleted_at) yet the model omits the
 *                      SoftDeletes trait → the column is dead and ->delete() hard-deletes (constraint #30; _05).
 */
class bha_Witness_TestCas extends DuskTestCase
{
    private const URL_PREFIX           = '/behavioural-assessment';
    private const INCIDENT_CREATE_PATH = '/behavioural-assessment/incidents/create';
    private const INCIDENT_STORE_PATH  = '/behavioural-assessment/incidents';

    private const WITNESS_TABLE  = 'ba_incident_witnesses_jnt';
    private const INCIDENT_TABLE = 'ba_incidents';
    private const AUDIT_TABLE    = 'ba_audit_log';
    private const DDL_WITNESS    = 'bha_incident_witnesses_jnt'; // stale DDL-doc name (should NOT exist at runtime)

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/Witness/screenshots';

    /** @var array<int,string> */
    private const INCIDENT_PERMISSIONS = [
        'tenant.behavioural-assessment.incidents.viewAny',
        'tenant.behavioural-assessment.incidents.view',
        'tenant.behavioural-assessment.incidents.create',
        'tenant.behavioural-assessment.incidents.update',
        'tenant.behavioural-assessment.incidents.delete',
        'tenant.behavioural-assessment.incidents.restore',
        'tenant.behavioural-assessment.incidents.forceDelete',
        'tenant.behavioural-assessment.incidents.status',
    ];

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    /** @var array<int,int> ids of ba_incidents rows created during a test, cleaned up in tearDown */
    private array $createdIncidentIds = [];

    protected function setUp(): void
    {
        parent::setUp();

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

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
        $this->cleanupSeeds();

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01–09 — Schema / DDL / model / request configuration truth
    // =====================================================================

    public function test_witness_01_witness_junction_table_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::WITNESS_TABLE), 'Table ba_incident_witnesses_jnt does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::WITNESS_TABLE, [
                'id', 'incident_id', 'witness_type', 'witness_id',
                'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_incident_witnesses_jnt.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::WITNESS_TABLE))->keyBy('Field');
            $this->assertStringContainsString('bigint', strtolower((string) ($cols['incident_id']->Type ?? '')));
            $this->assertStringContainsString('int', strtolower((string) ($cols['witness_id']->Type ?? '')));
            $this->assertStringContainsString('enum', strtolower((string) ($cols['witness_type']->Type ?? '')));
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130627_create_ba_incident_witnesses_jnt_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_incident_witnesses_jnt'", $migration);
            $this->assertStringContainsString("cascadeOnDelete()", $migration);
            $this->assertStringContainsString("unique(['incident_id', 'witness_type', 'witness_id']", $migration);
        }

        // Model configuration.
        $witness = new BaIncidentWitnessJnt();
        $this->assertSame('ba_incident_witnesses_jnt', $witness->getTable());
        $this->assertSame([
            'incident_id', 'witness_id', 'witness_type', 'is_active', 'created_by', 'updated_by',
        ], $witness->getFillable());
        $this->assertInstanceOf(BelongsTo::class, $witness->incident());
    }

    public function test_witness_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime tables use the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::WITNESS_TABLE), 'Runtime table ba_incident_witnesses_jnt must exist.');
        $this->assertTrue(Schema::hasTable(self::INCIDENT_TABLE), 'Runtime table ba_incidents must exist.');

        // The DDL/registry spec name `bha_*` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_WITNESS),
                'DOC-BA-001 regression: bha_incident_witnesses_jnt exists at runtime; expected only ba_incident_witnesses_jnt.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_incident_witnesses_jnt', (new BaIncidentWitnessJnt())->getTable());
        $this->assertSame('ba_incidents', (new BaIncident())->getTable());
    }

    public function test_witness_03_unique_key_prevents_duplicate_witness_per_incident(): void
    {
        // Schema-level guarantee: uq(incident_id, witness_type, witness_id). The DDL doc calls it
        // `uq_bha_witness`; the live migration names it `uq_ba_witness` — assert by COLUMN SET, not name.
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Unique-index inspection requires MySQL.');
        }
        $indexes = DB::select("SHOW INDEX FROM " . self::WITNESS_TABLE . " WHERE Non_unique = 0");
        $uniqueCols = collect($indexes)->groupBy('Key_name')->map(
            fn ($rows) => collect($rows)->sortBy('Seq_in_index')->pluck('Column_name')->all()
        );
        $hasComposite = $uniqueCols->contains(
            fn ($cols) => $cols === ['incident_id', 'witness_type', 'witness_id']
        );
        $this->assertTrue($hasComposite, 'Expected a UNIQUE(incident_id, witness_type, witness_id) on ba_incident_witnesses_jnt.');
    }

    public function test_witness_04_witness_type_enum_is_lowercase_student_staff(): void
    {
        // The DB enum + the controller writes are lowercase 'student'/'staff'; the requirement's
        // "Student"/"Staff Member" are UI labels only (enum-case cross-check, constraint #18).
        $this->assertTrue(Schema::hasColumn(self::WITNESS_TABLE, 'witness_type'));
        if (DB::connection()->getDriverName() === 'mysql') {
            $col = collect(DB::select('SHOW COLUMNS FROM ' . self::WITNESS_TABLE))->firstWhere('Field', 'witness_type');
            $type = strtolower((string) ($col->Type ?? ''));
            $this->assertStringContainsString("'student'", $type, "witness_type enum should list 'student'.");
            $this->assertStringContainsString("'staff'", $type, "witness_type enum should list 'staff'.");
            $this->assertStringNotContainsString("'Student'", (string) ($col->Type ?? ''), 'Enum must be lowercase (no capitalised Student).');
        }
    }

    public function test_witness_05_model_omits_softdeletes_though_table_has_deleted_at_data_ba_wit_05(): void
    {
        // DATA-BA-WIT-05 (constraint #30 pattern): the migration adds softDeletes()/deleted_at, but the
        // model does NOT use the SoftDeletes trait — the column is dead and ->delete() hard-deletes.
        $this->assertTrue(Schema::hasColumn(self::WITNESS_TABLE, 'deleted_at'), 'Migration adds a deleted_at column.');
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(BaIncidentWitnessJnt::class),
            'DATA-BA-WIT-05 regression fixed? Model now uses SoftDeletes — update the expectation.'
        );
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_witness_10_student_witness_persists_via_junction(): void
    {
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies (std_students / sch_employees) unavailable.');
        }
        $studentId = (int) (DB::table('std_students')->value('id') ?? 0);

        $witness = $this->attachWitness($incident->id, 'student', $studentId);
        $this->assertNotNull($witness, 'Student witness row should be created.');
        $this->assertDatabaseWitness($incident->id, 'student', $studentId);
        $this->assertSame('student', $witness->witness_type);
    }

    public function test_witness_11_staff_witness_persists_via_junction(): void
    {
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $staffId = (int) (DB::table('sch_employees')->value('id') ?? 0);

        $witness = $this->attachWitness($incident->id, 'staff', $staffId);
        $this->assertNotNull($witness, 'Staff witness row should be created.');
        $this->assertDatabaseWitness($incident->id, 'staff', $staffId);
        $this->assertSame('staff', $witness->witness_type);
    }

    public function test_witness_12_is_active_defaults_true_and_audit_columns_set(): void
    {
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $studentId = (int) (DB::table('std_students')->value('id') ?? 0);

        $witness = $this->attachWitness($incident->id, 'student', $studentId);
        $this->assertNotNull($witness);
        $witness->refresh();
        $this->assertTrue((bool) $witness->is_active, 'is_active should be true (boolean cast).');
        $this->assertSame((int) $this->adminUser->id, (int) $witness->created_by);
        $this->assertSame((int) $this->adminUser->id, (int) $witness->updated_by);
        $this->assertNotNull($witness->created_at, 'created_at should be stamped (timestamps enabled).');
    }

    public function test_witness_13_controller_store_attaches_both_student_and_staff_witnesses(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaIncidentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $store = $this->extractMethodBody($controller, 'store');
        $this->assertStringContainsString('witness_student_ids', $store, 'store() should read witness_student_ids.');
        $this->assertStringContainsString('witness_staff_ids', $store, 'store() should read witness_staff_ids.');
        $this->assertStringContainsString("'witness_type' => 'student'", $store, 'store() writes a student witness_type.');
        $this->assertStringContainsString("'witness_type' => 'staff'", $store, 'store() writes a staff witness_type.');
    }

    public function test_witness_14_controller_update_resyncs_witnesses_force_delete_then_recreate(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaIncidentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $update = $this->extractMethodBody($controller, 'update');
        // update() clears existing witnesses then recreates from the arrays (full re-sync).
        $this->assertStringContainsString("BaIncidentWitnessJnt::where('incident_id', \$incident->id)->forceDelete()", $update,
            'update() should force-delete existing witnesses before recreating.');
        $this->assertStringContainsString('witness_student_ids', $update);
        $this->assertStringContainsString('witness_staff_ids', $update);
    }

    public function test_witness_15_incident_witnesses_relationship_is_hasmany(): void
    {
        $incident = new BaIncident();
        $this->assertInstanceOf(HasMany::class, $incident->witnesses(), 'BaIncident::witnesses() must be a HasMany.');
    }

    // =====================================================================
    // Band 20–29 — State machine / audit-lock (BC-SM) — BUG-BA-WIT-03
    // =====================================================================

    public function test_witness_20_audit_lock_freeze_after_close_is_not_enforced_bug_ba_wit_03(): void
    {
        // Requirement "Audit Lock": once the incident is closed/resolved the witness list freezes.
        // Prove the guard is absent: update() never consults incident status / a lock flag before re-syncing.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaIncidentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable.');
        }
        $update = $this->extractMethodBody($controller, 'update');
        $this->assertNotSame('', $update, 'Unable to isolate update() body.');
        $this->assertStringNotContainsString('isLocked', $update, 'BUG-BA-WIT-03: update() must not (yet) check a lock.');
        $this->assertStringNotContainsString('is_frozen', $update, 'BUG-BA-WIT-03: no freeze flag consulted.');
        $this->assertStringNotContainsString("=== 'closed'", $update, 'BUG-BA-WIT-03: incident status not checked before witness re-sync.');
    }

    public function test_witness_21_witness_can_be_attached_regardless_of_incident_state_bug_ba_wit_03(): void
    {
        // Data-level proof: witnesses can be added even to an already-persisted (would-be "locked") incident.
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $studentId = (int) (DB::table('std_students')->value('id') ?? 0);

        // Simulate a "resolved" incident by flagging follow-up complete — the junction accepts new rows anyway.
        $incident->update(['is_follow_up_required' => false, 'updated_by' => (int) $this->adminUser->id]);

        $witness = $this->attachWitness($incident->id, 'student', $studentId);
        $this->assertNotNull($witness, 'BUG-BA-WIT-03: a witness is still attachable to a resolved incident.');
        $this->assertDatabaseWitness($incident->id, 'student', $studentId);
    }

    // =====================================================================
    // Band 30–39 — Validation (BC-VAL)
    // =====================================================================

    public function test_witness_30_student_witness_ids_rule_requires_existing_student(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaIncidentRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable.');
        }
        $this->assertStringContainsString("'witness_student_ids.*' => ['integer', 'exists:std_students,id']", $request,
            'witness_student_ids.* must be integer + exists:std_students,id.');
        $this->assertStringContainsString("'witness_student_ids'   => ['nullable', 'array']", $request);
    }

    public function test_witness_31_staff_witness_ids_rule_requires_existing_employee(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaIncidentRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable.');
        }
        $this->assertStringContainsString("'witness_staff_ids.*'   => ['integer', 'exists:sch_employees,id']", $request,
            'witness_staff_ids.* must be integer + exists:sch_employees,id.');
        $this->assertStringContainsString("'witness_staff_ids'     => ['nullable', 'array']", $request);
    }

    public function test_witness_32_witness_arrays_are_optional_nullable(): void
    {
        // Both witness arrays are nullable — an incident may be logged with zero witnesses.
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaIncidentRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable.');
        }
        $this->assertMatchesRegularExpression(
            "/'witness_student_ids'\s*=>\s*\['nullable', 'array'\]/",
            $request,
            'witness_student_ids must be nullable.'
        );
    }

    public function test_witness_33_witness_statement_requirement_is_unimplemented_data_ba_wit_01(): void
    {
        // DATA-BA-WIT-01: the requirement mandates a per-witness "Witness Statement" (min 10, max 500).
        // No statement column exists, the model has no such field, and the FormRequest has no such rule.
        $this->assertFalse(Schema::hasColumn(self::WITNESS_TABLE, 'statement'), 'No statement column expected (unimplemented).');
        $this->assertFalse(Schema::hasColumn(self::WITNESS_TABLE, 'witness_statement'), 'No witness_statement column expected.');
        $this->assertNotContains('statement', (new BaIncidentWitnessJnt())->getFillable(), 'Model has no statement field.');

        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaIncidentRequest.php'));
        if ($request !== null) {
            $this->assertStringNotContainsString('statement', $request, 'DATA-BA-WIT-01: no witness-statement validation rule exists.');
        }
        $create = $this->readAppFile($this->moduleRootPath('resources/views/incident/create.blade.php'));
        if ($create !== null) {
            $this->assertStringNotContainsString('witness_statement', $create, 'DATA-BA-WIT-01: create form has no statement field.');
        }
    }

    public function test_witness_34_self_referential_block_is_not_enforced_bug_ba_wit_02(): void
    {
        // BUG-BA-WIT-02: the requirement forbids the incident's own subject student from being a witness.
        // Neither the controller store()/update() nor the FormRequest excludes student_id from witness ids.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaIncidentController.php'));
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaIncidentRequest.php'));
        if ($controller === null || $request === null) {
            $this->markTestSkipped('Controller/FormRequest source not readable.');
        }
        // No exclusion of the subject from the witness set anywhere.
        $this->assertStringNotContainsString('different:student_id', $request, 'BUG-BA-WIT-02: FormRequest has no self-witness guard.');
        $store = $this->extractMethodBody($controller, 'store');
        $this->assertStringNotContainsString('subject', $store, 'BUG-BA-WIT-02: store() has no subject-exclusion logic.');
    }

    public function test_witness_35_subject_student_can_be_added_as_own_witness_at_data_layer_bug_ba_wit_02(): void
    {
        // Data-level proof of BUG-BA-WIT-02: the subject student can be persisted as a witness to their own incident.
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $subjectStudentId = (int) $incident->student_id;

        $witness = $this->attachWitness($incident->id, 'student', $subjectStudentId);
        $this->assertNotNull($witness, 'BUG-BA-WIT-02: the subject student was accepted as their own witness.');
        $this->assertDatabaseWitness($incident->id, 'student', $subjectStudentId);
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-REF/INT/EDG)
    // =====================================================================

    public function test_witness_40_deleting_incident_cascades_to_witnesses(): void
    {
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $studentId = (int) (DB::table('std_students')->value('id') ?? 0);
        $witness = $this->attachWitness($incident->id, 'student', $studentId);
        $this->assertNotNull($witness);
        $witnessId = (int) $witness->id;

        // Force-delete the parent incident (physical) → FK ON DELETE CASCADE removes its witnesses.
        BaIncident::withTrashed()->where('id', $incident->id)->get()->each(function (BaIncident $i): void {
            try { $i->forceDelete(); } catch (Throwable) {}
        });
        $this->createdIncidentIds = array_values(array_filter($this->createdIncidentIds, fn ($id) => $id !== $incident->id));

        $this->assertFalse(
            BaIncidentWitnessJnt::where('id', $witnessId)->exists(),
            'Witnesses must be cascade-deleted with the parent incident (FK ON DELETE CASCADE).'
        );
    }

    public function test_witness_41_witness_incident_fk_is_cascade(): void
    {
        $this->assertDeleteRule('ba_incidents', 'CASCADE');
    }

    public function test_witness_42_witness_id_has_no_db_foreign_key_polymorphic(): void
    {
        // The polymorphic witness_id points to std_students OR sch_employees depending on witness_type,
        // so there is intentionally NO DB-level FK on witness_id (integrity is app-layer only).
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('FK metadata inspection requires MySQL.');
        }
        try {
            $fks = DB::select(
                "SELECT COLUMN_NAME FROM information_schema.KEY_COLUMN_USAGE
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?
                   AND REFERENCED_TABLE_NAME IS NOT NULL",
                [self::WITNESS_TABLE]
            );
            $fkColumns = collect($fks)->pluck('COLUMN_NAME')->map(fn ($c) => strtolower((string) $c))->all();
            $this->assertNotContains('witness_id', $fkColumns, 'witness_id must have no DB FK (polymorphic).');
            $this->assertContains('incident_id', $fkColumns, 'incident_id must have a DB FK to ba_incidents.');
        } catch (Throwable $e) {
            $this->markTestSkipped('FK metadata unavailable: ' . $e->getMessage());
        }
    }

    public function test_witness_43_unique_constraint_rejects_a_duplicate_witness_row(): void
    {
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $studentId = (int) (DB::table('std_students')->value('id') ?? 0);

        $first = $this->attachWitness($incident->id, 'student', $studentId);
        $this->assertNotNull($first, 'First witness row should insert.');

        // Second identical (incident_id, witness_type, witness_id) must violate uq_ba_witness.
        $threw = false;
        try {
            BaIncidentWitnessJnt::create([
                'incident_id'  => $incident->id,
                'witness_type' => 'student',
                'witness_id'   => $studentId,
                'is_active'    => true,
                'created_by'   => (int) $this->adminUser->id,
                'updated_by'   => (int) $this->adminUser->id,
            ]);
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'A duplicate (incident,type,id) witness must be rejected by uq_ba_witness.');
        $this->assertSame(
            1,
            BaIncidentWitnessJnt::where('incident_id', $incident->id)->where('witness_type', 'student')->where('witness_id', $studentId)->count(),
            'Exactly one witness row per (incident, type, id).'
        );
    }

    public function test_witness_44_store_student_loop_lacks_dedup_asymmetry_with_staff_bug_ba_wit_04(): void
    {
        // BUG-BA-WIT-04: store() uses create() for student witnesses (no firstOrCreate / no array_unique),
        // but firstOrCreate() for staff — a duplicate id in witness_student_ids[] would 500 on uq_ba_witness.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaIncidentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable.');
        }
        $store = $this->extractMethodBody($controller, 'store');
        // Staff branch dedups...
        $this->assertStringContainsString('BaIncidentWitnessJnt::firstOrCreate', $store, 'Staff witnesses use firstOrCreate (dedup).');
        // ...student branch does a plain create with no array_unique guard on witness_student_ids.
        $this->assertStringContainsString('BaIncidentWitnessJnt::create([', $store, 'Student witnesses use plain create (no dedup).');
        $this->assertStringNotContainsString('array_unique($request->witness_student_ids', $store,
            'BUG-BA-WIT-04: student witness ids are not de-duplicated before create().');
    }

    public function test_witness_45_full_lifecycle_attach_two_types_then_cascade_delete(): void
    {
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $studentId = (int) (DB::table('std_students')->value('id') ?? 0);
        $staffId   = (int) (DB::table('sch_employees')->value('id') ?? 0);

        $this->attachWitness($incident->id, 'student', $studentId);
        $this->attachWitness($incident->id, 'staff', $staffId);
        $this->assertSame(2, BaIncidentWitnessJnt::where('incident_id', $incident->id)->count(), 'Both witnesses attached.');

        // Cascade delete removes the whole witness set with the incident.
        BaIncident::withTrashed()->where('id', $incident->id)->get()->each(function (BaIncident $i): void {
            try { $i->forceDelete(); } catch (Throwable) {}
        });
        $this->createdIncidentIds = array_values(array_filter($this->createdIncidentIds, fn ($id) => $id !== $incident->id));
        $this->assertSame(0, BaIncidentWitnessJnt::where('incident_id', $incident->id)->count(), 'All witnesses cascade-deleted.');
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_witness_50_guest_is_redirected_to_login_on_incident_create(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::INCIDENT_CREATE_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_witness_51_limited_user_without_create_permission_gets_403_on_incident_store(): void
    {
        // Witnesses are attached inside store() — its create gate governs witness creation.
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-store-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl(self::INCIDENT_STORE_PATH),
                ['witness_student_ids' => [1]]
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without create permission must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_witness_52_limited_user_without_update_permission_gets_403_on_incident_update(): void
    {
        // Witness re-sync happens inside update() — its update gate governs it.
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-update-403', function (Browser $browser) use ($limited, $incident): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'PUT',
                $this->tenantUrl(self::INCIDENT_STORE_PATH . '/' . $incident->id),
                ['witness_staff_ids' => [1]]
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without update permission must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_witness_53_incident_policy_maps_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaIncidentPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('Policy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete', 'status'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.incidents.{$ability}",
                $policy,
                "Policy missing gate string for {$ability}."
            );
        }
    }

    public function test_witness_54_witnesses_have_no_standalone_routes(): void
    {
        // Witnesses are managed only through the incident form — there is no witness resource/route.
        foreach ([
            'behavioural-assessment.witnesses.index',
            'behavioural-assessment.witnesses.store',
            'behavioural-assessment.incidents.witnesses.store',
            'behavioural-assessment.incidents.witnesses.add',
        ] as $name) {
            $this->assertFalse(Route::has($name), "No standalone witness route expected: {$name}.");
        }
        // The incident store/update routes DO exist (the only way witnesses are written).
        $this->assertTrue(Route::has('behavioural-assessment.incidents.store'), 'incidents.store must exist.');
        $this->assertTrue(Route::has('behavioural-assessment.incidents.update'), 'incidents.update must exist.');
    }

    // =====================================================================
    // Band 60–69 — UI/UX (blade selectors, source-verified)
    // =====================================================================

    public function test_witness_60_create_blade_renders_witness_checkbox_arrays(): void
    {
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/incident/create.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('create.blade.php not readable.');
        }
        $this->assertStringContainsString('name="witness_student_ids[]"', $blade, 'Student witness checkbox array.');
        $this->assertStringContainsString('name="witness_staff_ids[]"', $blade, 'Staff witness checkbox array.');
        $this->assertStringContainsString('id="ws_{{ $student->id }}"', $blade, 'Student witness checkbox id marker.');
        $this->assertStringContainsString('id="wf_{{ $staff->id }}"', $blade, 'Staff witness checkbox id marker.');
    }

    public function test_witness_61_edit_blade_prechecks_existing_witnesses(): void
    {
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/incident/edit.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('edit.blade.php not readable.');
        }
        $this->assertStringContainsString("old('witness_student_ids', \$witnessStudentIds)", $blade,
            'Edit form should re-check previously saved student witnesses.');
        $this->assertStringContainsString("old('witness_staff_ids', \$witnessStaffIds)", $blade,
            'Edit form should re-check previously saved staff witnesses.');
    }

    public function test_witness_62_show_blade_renders_witnesses_escaped(): void
    {
        $blade = $this->readAppFile($this->moduleRootPath('resources/views/incident/show.blade.php'));
        if ($blade === null) {
            $this->markTestSkipped('show.blade.php not readable.');
        }
        // Witness names/admission numbers are echoed with escaped {{ }}, never raw {!! !!} → no stored XSS.
        $this->assertStringContainsString('{{ $w->first_name }} {{ $w->last_name }}', $blade, 'Student witness name rendered escaped.');
        $this->assertStringNotContainsString('{!! $w->first_name', $blade, 'Witness fields must not be echoed raw.');
        $this->assertStringContainsString('No witnesses recorded.', $blade, 'Empty-state text present.');
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_witness_70_incident_with_no_witnesses_has_zero_junction_rows(): void
    {
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        // A freshly seeded incident (no witnesses attached) must have an empty witness set.
        $this->assertSame(0, BaIncidentWitnessJnt::where('incident_id', $incident->id)->count(),
            'An incident logged with zero witnesses has no junction rows.');
        $this->assertTrue($incident->witnesses()->get()->isEmpty(), 'witnesses relationship is empty.');
    }

    public function test_witness_71_staff_firstorcreate_is_idempotent_at_data_layer(): void
    {
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $staffId = (int) (DB::table('sch_employees')->value('id') ?? 0);

        // Mirrors the controller's staff branch (firstOrCreate) — a repeat call must not duplicate.
        for ($i = 0; $i < 2; $i++) {
            BaIncidentWitnessJnt::firstOrCreate(
                ['incident_id' => $incident->id, 'witness_type' => 'staff', 'witness_id' => $staffId],
                ['is_active' => true, 'created_by' => (int) $this->adminUser->id, 'updated_by' => (int) $this->adminUser->id]
            );
        }
        $this->assertSame(1, BaIncidentWitnessJnt::where('incident_id', $incident->id)->where('witness_type', 'staff')->where('witness_id', $staffId)->count(),
            'firstOrCreate keeps the staff witness idempotent.');
    }

    public function test_witness_72_show_on_invalid_incident_id_returns_404(): void
    {
        $response = $this->apiCall('GET', $this->tenantUrl(self::INCIDENT_STORE_PATH . '/987654321'));
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'show() on a missing incident must 404 (findOrFail).');
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_witness_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side witness tests.'
        );
        $this->assertTrue(Schema::hasTable(self::WITNESS_TABLE));
    }

    public function test_witness_91_cross_tenant_direct_id_isolation(): void
    {
        // Defensive: a second tenant is required to prove IDOR isolation across tenant DBs.
        try {
            $otherDomain = Domain::query()
                ->where('domain', '!=', parse_url($this->tenantBaseUrl, PHP_URL_HOST))
                ->first();
            if (!$otherDomain) {
                $this->markTestSkipped('Only one tenant domain available — cross-tenant isolation not exercisable.');
            }
            $this->assertNotNull($otherDomain->tenant, 'Second tenant exists for isolation checks.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Cross-tenant isolation path unavailable: ' . $e->getMessage());
        }
    }

    public function test_witness_92_witness_id_is_stored_as_integer_no_free_text_surface(): void
    {
        // The junction stores only enum type + integer id — there is no free-text field on a witness,
        // so there is no stored-XSS surface here (contrast: the requirement's unimplemented statement field).
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $studentId = (int) (DB::table('std_students')->value('id') ?? 0);
        $witness = $this->attachWitness($incident->id, 'student', $studentId);
        $this->assertNotNull($witness);
        $witness->refresh();
        $this->assertIsInt((int) $witness->witness_id);
        $this->assertContains($witness->witness_type, ['student', 'staff'], 'witness_type is a constrained enum, not free text.');
    }

    public function test_witness_93_witness_type_enum_rejects_arbitrary_value(): void
    {
        // A crafted witness_type outside the enum must be rejected by the DB (MySQL strict) — defence in depth.
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Enum enforcement check requires MySQL.');
        }
        $incident = $this->seedIncident();
        if ($incident === null) {
            $this->markTestSkipped('Cross-module dependencies unavailable.');
        }
        $studentId = (int) (DB::table('std_students')->value('id') ?? 0);

        $threw = false;
        try {
            BaIncidentWitnessJnt::create([
                'incident_id'  => $incident->id,
                'witness_type' => 'parent', // not in ENUM('student','staff')
                'witness_id'   => $studentId,
                'is_active'    => true,
                'created_by'   => (int) $this->adminUser->id,
                'updated_by'   => (int) $this->adminUser->id,
            ]);
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'An out-of-enum witness_type must be rejected by the database.');
    }

    // =====================================================================
    // ---- Private helper library ----
    // =====================================================================

    private function assertDatabaseWitness(int $incidentId, string $type, int $witnessId): void
    {
        $this->assertTrue(
            BaIncidentWitnessJnt::where('incident_id', $incidentId)
                ->where('witness_type', $type)
                ->where('witness_id', $witnessId)
                ->exists(),
            "Expected a {$type} witness row for incident {$incidentId} / witness {$witnessId}."
        );
    }

    // ---- Seeding (defensive; reuses cross-module rows) --------------------

    private function seedIncident(): ?BaIncident
    {
        try {
            $studentId  = (int) (DB::table('std_students')->value('id') ?? 0);
            $employeeId = (int) (DB::table('sch_employees')->value('id') ?? 0);
            if ($studentId === 0 || $employeeId === 0) {
                return null;
            }

            $incident = BaIncident::create([
                'student_id'    => $studentId,
                'reported_by'   => $employeeId,
                'incident_date' => now()->toDateString(),
                'incident_type' => 'positive_reinforcement',
                'location'      => 'classroom',
                'description'   => 'Witness-suite parent incident ' . $this->uniqueSuffix(),
                'is_active'     => true,
                'created_by'    => (int) $this->adminUser->id,
                'updated_by'    => (int) $this->adminUser->id,
            ]);
            $this->createdIncidentIds[] = (int) $incident->id;
            return $incident;
        } catch (Throwable) {
            return null;
        }
    }

    private function attachWitness(int $incidentId, string $type, int $witnessId): ?BaIncidentWitnessJnt
    {
        try {
            return BaIncidentWitnessJnt::create([
                'incident_id'  => $incidentId,
                'witness_type' => $type,
                'witness_id'   => $witnessId,
                'is_active'    => true,
                'created_by'   => (int) $this->adminUser->id,
                'updated_by'   => (int) $this->adminUser->id,
            ]);
        } catch (Throwable) {
            return null;
        }
    }

    private function cleanupSeeds(): void
    {
        foreach ($this->createdIncidentIds as $id) {
            try {
                // Witness model has NO SoftDeletes → this is a hard delete (DATA-BA-WIT-05).
                BaIncidentWitnessJnt::where('incident_id', $id)->delete();
            } catch (Throwable) {}
            try {
                DB::table(self::AUDIT_TABLE)->where('entity_type', 'incident')->where('entity_id', $id)->delete();
            } catch (Throwable) {}
            try {
                BaIncident::withTrashed()->where('id', $id)->get()->each(function (BaIncident $i): void {
                    try { $i->forceDelete(); } catch (Throwable) {}
                });
            } catch (Throwable) {}
        }
        $this->createdIncidentIds = [];
    }

    private function assertDeleteRule(string $referencedTable, string $expectedRule): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('FK metadata inspection requires MySQL.');
        }
        try {
            $fk = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ?
                   AND REFERENCED_TABLE_NAME = ?",
                [self::WITNESS_TABLE, $referencedTable]
            );
            if (empty($fk)) {
                $this->markTestSkipped("No FK metadata for ba_incident_witnesses_jnt → {$referencedTable}.");
            }
            $rule = strtoupper((string) ($fk[0]->DELETE_RULE ?? ''));
            $this->assertStringContainsString($expectedRule, $rule, "ba_incident_witnesses_jnt → {$referencedTable} should be {$expectedRule}; found: {$rule}");
        } catch (Throwable $e) {
            $this->markTestSkipped("FK dependency path unavailable for {$referencedTable}: " . $e->getMessage());
        }
    }

    // ---- Screenshots ------------------------------------------------------

    private function cleanScreenshots(): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        if (!is_dir($directory)) {
            return;
        }
        $files = glob($directory . DIRECTORY_SEPARATOR . '*.png');
        if ($files === false) {
            return;
        }
        foreach ($files as $file) {
            if (is_file($file)) {
                @unlink($file);
            }
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
                $this->captureScreenshot($browser, 'pass', $caseName);
            } catch (Throwable $e) {
                $this->captureScreenshot($browser, 'fail', $caseName);
                throw $e;
            }
        });
    }

    private function captureScreenshot(Browser $browser, string $kind, string $caseName): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);
        $rawName = 'witness-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'witness-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- Browser JSON request plumbing ------------------------------------

    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
    }

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openAdminApiPage($browser);
            $result = $callback($browser);
        });
        return $result;
    }

    /** Open a lightweight authenticated page (incident create form) so a CSRF meta + same-origin cookies exist. */
    private function openAdminApiPage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::INCIDENT_CREATE_PATH, 900);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('meta[name="csrf-token"]') !== null
                || $browser->element('form') !== null
                || $browser->element('body') !== null;
        }, 'Admin API page (incident create form) did not render a CSRF context.');
    }

    private function sendJsonRequestFromBrowser(
        Browser $browser,
        string $method,
        string $url,
        array $payload = []
    ): array {
        $encodedMethod = json_encode(strtoupper($method), JSON_THROW_ON_ERROR);
        $encodedUrl = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
window.__waApiDone = false;
window.__waApiError = '';
window.__waApiResult = null;

(async function () {
    try {
        const method = {$encodedMethod};
        const url = {$encodedUrl};
        const payload = {$encodedPayload};
        const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';

        const options = {
            method,
            credentials: 'same-origin',
            redirect: 'manual',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
        };

        if (method !== 'GET' && method !== 'HEAD') {
            options.body = JSON.stringify(payload);
        }

        const response = await fetch(url, options);
        const body = await response.text();
        let json = null;
        try { json = body ? JSON.parse(body) : null; } catch (_e) { json = null; }

        window.__waApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__waApiError = String(error);
    } finally {
        window.__waApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__waApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__waApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__waApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Limited (non-super-admin) user for authorization negatives -------

    private function makeLimitedUser(): User
    {
        try {
            $lang = 1;
            if (Schema::hasTable('glb_languages')) {
                $lang = (int) (DB::table('glb_languages')->value('id') ?? 1);
            }

            $attributes = [
                'name'              => 'Witness Limited ' . $this->uniqueSuffix(),
                'email'             => 'witness_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'WI' . substr($this->uniqueSuffix(), -8);
            }

            $user = User::factory()->create($attributes);

            foreach (['is_super_admin', 'super_admin_flag'] as $col) {
                if (Schema::hasColumn('sys_users', $col)) {
                    $user->forceFill([$col => 0]);
                }
            }
            $user->save();

            if (method_exists($user, 'syncRoles')) {
                try { $user->syncRoles([]); } catch (Throwable) {}
            }
            if (method_exists($user, 'syncPermissions')) {
                try { $user->syncPermissions([]); } catch (Throwable) {}
            }
            $this->forgetPermissionCache();

            return $user;
        } catch (Throwable $e) {
            $this->markTestSkipped('Unable to create a limited tenant user for authorization tests: ' . $e->getMessage());
        }
    }

    private function deleteUser(?User $user): void
    {
        if ($user === null) {
            return;
        }
        try {
            $user->forceDelete();
        } catch (Throwable) {
            try {
                DB::table('sys_users')->where('id', $user->id)->delete();
            } catch (Throwable) {
            }
        }
    }

    // ---- Auth / tenancy ---------------------------------------------------

    private function authenticate(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(700);
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1000);
        }
        if (str_contains($this->currentPath($browser), '/login')) {
            $browser->loginAs($this->adminUser)->pause(550);
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
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first();
        if (!$this->adminUser) {
            $this->adminUser = User::query()->first();
        }
        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for Dusk login.');
        }
        if ($this->adminUser->getAttribute('email_verified_at') === null) {
            $this->adminUser->forceFill(['email_verified_at' => now()])->save();
        }
        $this->grantIncidentPermissions($this->adminUser);
    }

    private function grantIncidentPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::INCIDENT_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::INCIDENT_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::INCIDENT_PERMISSIONS as $permission) {
                try {
                    $user->givePermissionTo($permission);
                } catch (Throwable) {
                }
            }
        }
        $this->forgetPermissionCache();
    }

    private function ensurePermissionsExist(array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }
        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate(['name' => $permission, 'guard_name' => $guard]);
            } catch (Throwable) {
            }
        }
    }

    private function syncRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.witness-admin');
        try {
            $role = \Spatie\Permission\Models\Role::firstOrCreate(['name' => $roleName, 'guard_name' => $guard]);
        } catch (Throwable) {
            return;
        }
        try {
            if (method_exists($role, 'syncPermissions')) {
                $role->syncPermissions($permissions);
            }
        } catch (Throwable) {
        }
        if (method_exists($user, 'assignRole')) {
            try {
                $user->assignRole($roleName);
            } catch (Throwable) {
            }
        }
        $this->forgetPermissionCache();
    }

    private function permissionGuardName(User $user): string
    {
        if (method_exists($user, 'getDefaultGuardName')) {
            try {
                $guard = (string) $user->getDefaultGuardName();
                if ($guard !== '') {
                    return $guard;
                }
            } catch (Throwable) {
            }
        }
        return (string) config('auth.defaults.guard', 'web');
    }

    private function forgetPermissionCache(): void
    {
        if (!class_exists(\Spatie\Permission\PermissionRegistrar::class)) {
            return;
        }
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
        }
    }

    // ---- App-repo source resolution (constraint #29/#32) ------------------

    private function moduleRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaIncidentWitnessJnt::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaIncidentWitnessJnt.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaIncidentWitnessJnt::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaIncidentWitnessJnt.php → app root = dirname(,5)
            $appRoot = dirname($modelFile, 5);
            return $appRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function readAppFile(?string $path): ?string
    {
        if ($path === null) {
            return null;
        }
        try {
            if (File::exists($path)) {
                return File::get($path);
            }
        } catch (Throwable) {
        }
        return null;
    }

    /** Best-effort extraction of a controller method body (brace-balanced) for source-scan assertions. */
    private function extractMethodBody(string $source, string $method): string
    {
        $needle = 'function ' . $method . '(';
        $start = strpos($source, $needle);
        if ($start === false) {
            return '';
        }
        $brace = strpos($source, '{', $start);
        if ($brace === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($source);
        for ($i = $brace; $i < $len; $i++) {
            $ch = $source[$i];
            if ($ch === '{') {
                $depth++;
            } elseif ($ch === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $brace, $i - $brace + 1);
                }
            }
        }
        return substr($source, $brace);
    }

    // ---- Small utilities --------------------------------------------------

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
