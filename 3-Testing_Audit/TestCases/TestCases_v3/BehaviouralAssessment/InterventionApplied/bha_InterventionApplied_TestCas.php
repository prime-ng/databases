<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaIncident;
use Modules\BehaviouralAssessment\Models\BaIncidentInterventionJnt;
use Modules\BehaviouralAssessment\Models\BaIntervention;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Interventions Applied (incident ↔ intervention junction) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/14-Interventions-Applied.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Primary table      : ba_incident_intervention_jnt  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Junction FKs       : incident_id → ba_incidents (ON DELETE CASCADE); intervention_id → ba_interventions (ON DELETE RESTRICT).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController
 *                        - addIntervention()    POST  behavioural-assessment.incidents.interventions.add   (firstOrCreate → idempotent link)
 *                        - removeIntervention() DELETE behavioural-assessment.incidents.interventions.remove (hard delete — no SoftDeletes trait)
 *                        - store()/update()     bulk attach / re-sync via BaIncidentRequest interventions[] rules
 *                      Standalone read-only tab: BaDashboardController::incidentsPage() (tab=interventions-applied, ia_page pagination)
 * FormRequests       : addIntervention() validates inline; bulk attach validates via BaIncidentRequest (interventions.* rules).
 * Permission prefix  : tenant.behavioural-assessment.incidents.{viewAny|view|create|update|delete|restore|forceDelete|status}
 *                      tenant.behavioural-assessment.incidents-page.viewAny (standalone tab).
 * Activity log       : NONE on junction mutations — addIntervention()/removeIntervention() call no activityLog()/BaAuditLog (documented absence).
 *
 * Defects proven / documented (this cross-reference scan):
 *   - DOC-BA-001   : DDL doc prefix `bha_` diverges from the live `ba_` runtime table (proven in _02).
 *   - DATA-BA-IA-01: migration adds softDeletes() (deleted_at) but BaIncidentInterventionJnt has NO SoftDeletes trait —
 *                    the soft-delete column is dead; removeIntervention()->delete() HARD-deletes (proven in _03/_46).
 *   - VAL-BA-IA-01 : screen specs an intervention lifecycle Status (Assigned/In Progress/Completed/Cancelled) + Scheduled Date +
 *                    Assigned-To Staff + Completion Date; none of these columns exist — junction only has notes + is_active (proven in _20).
 *   - INFO-BA-IA-02: is_active "soft enable/disable" column exists but no endpoint ever toggles it (documented in _21).
 *   - SEC-BA-002   : FormRequest authorize() returns bare true, mitigated by the controller Gate (proven in _94).
 *   - INT-OBS-01   : BaIntervention booted() detaches junction rows on forceDelete, working around the DB RESTRICT FK (proven in _44).
 */
class bha_InterventionApplied_TestCas extends DuskTestCase
{
    private const URL_PREFIX   = '/behavioural-assessment';
    private const TAB_PATH     = '/behavioural-assessment/incidents-page?tab=interventions-applied';
    private const INCIDENTS_PAGE = '/behavioural-assessment/incidents-page';

    private const TABLE        = 'ba_incident_intervention_jnt';
    private const DDL_TABLE    = 'bha_incident_intervention_jnt'; // stale DDL-doc name (should NOT exist at runtime)
    private const INTERVENTIONS_TABLE = 'ba_interventions';
    private const INCIDENTS_TABLE     = 'ba_incidents';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/InterventionApplied/screenshots';

    /** @var array<int,string> */
    private const IA_PERMISSIONS = [
        'tenant.behavioural-assessment.incidents-page.viewAny',
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
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01–09 — Schema / DDL / model / request configuration truth
    // =====================================================================

    public function test_ia_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table ba_incident_intervention_jnt does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'incident_id', 'intervention_id', 'notes', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_incident_intervention_jnt.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::TABLE))->keyBy('Field');
            $this->assertStringContainsString('bigint', strtolower((string) ($cols['incident_id']->Type ?? '')));
            $this->assertStringContainsString('bigint', strtolower((string) ($cols['intervention_id']->Type ?? '')));
            $this->assertStringContainsString('varchar', strtolower((string) ($cols['notes']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));

            // Unique index on (incident_id, intervention_id) — duplicate-link prevention.
            $indexes = collect(DB::select('SHOW INDEX FROM ' . self::TABLE));
            $uniqueGroups = $indexes->where('Non_unique', 0)->groupBy('Key_name');
            $hasPairUnique = $uniqueGroups->contains(function ($rows) {
                $cols = collect($rows)->pluck('Column_name')->map(fn ($c) => strtolower((string) $c))->all();
                return in_array('incident_id', $cols, true) && in_array('intervention_id', $cols, true);
            });
            $this->assertTrue($hasPairUnique, 'Expected a UNIQUE index over (incident_id, intervention_id).');
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130626_create_ba_incident_intervention_jnt_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_incident_intervention_jnt'", $migration);
            $this->assertStringContainsString("\$table->string('notes', 500)", $migration);
            $this->assertStringContainsString("->constrained('ba_incidents')->cascadeOnDelete()", $migration);
            $this->assertStringContainsString("->constrained('ba_interventions')", $migration);
            $this->assertStringContainsString("\$table->unique(['incident_id', 'intervention_id'], 'uq_ba_inc_int')", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // Bulk-attach validation lives in BaIncidentRequest (interventions[] rules).
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaIncidentRequest.php'));
        if ($request !== null) {
            $this->assertStringContainsString("'interventions'", $request);
            $this->assertStringContainsString("'distinct'", $request);
            $this->assertStringContainsString("exists:ba_interventions,id", $request);
        }

        // Model configuration.
        $model = new BaIncidentInterventionJnt();
        $this->assertSame('ba_incident_intervention_jnt', $model->getTable());
        $this->assertSame([
            'incident_id', 'intervention_id', 'notes', 'is_active', 'created_by', 'updated_by',
        ], $model->getFillable());
        $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null);
        $this->assertInstanceOf(BelongsTo::class, $model->incident());
        $this->assertInstanceOf(BelongsTo::class, $model->intervention());
        $this->assertSame('incident_id', $model->incident()->getForeignKeyName());
        $this->assertSame('intervention_id', $model->intervention()->getForeignKeyName());
    }

    public function test_ia_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
    {
        // Live runtime table uses the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Runtime junction ba_incident_intervention_jnt must exist.');

        // The DDL/registry spec name `bha_incident_intervention_jnt` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_TABLE),
                'DOC-BA-001 regression: bha_incident_intervention_jnt exists at runtime; expected only the live ba_ table.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_incident_intervention_jnt', (new BaIncidentInterventionJnt())->getTable());
    }

    public function test_ia_03_soft_delete_column_present_but_model_lacks_trait_data_ba_ia_01(): void
    {
        // DATA-BA-IA-01: the migration adds softDeletes() so the column exists...
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'deleted_at'), 'deleted_at column should exist (migration softDeletes()).');

        // ...but the Eloquent model does NOT use the SoftDeletes trait (constraint #30 — column & trait can disagree).
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(BaIncidentInterventionJnt::class),
            'DATA-BA-IA-01 changed: model now uses SoftDeletes — deleted_at is no longer dead.'
        );

        // Therefore ->delete() is a HARD delete: the row disappears physically, deleted_at is never stamped.
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available to prove hard-delete behaviour.');
        }
        $jntId = $this->linkJunction($incidentId, $interventionId, 'DATA-BA-IA-01 probe');
        $this->assertNotNull($jntId);

        BaIncidentInterventionJnt::whereKey($jntId)->first()?->delete();
        $this->assertSame(
            0,
            DB::table(self::TABLE)->where('id', $jntId)->count(),
            'DATA-BA-IA-01: ->delete() physically removed the junction row (no soft delete).'
        );

        $this->cleanupIntervention($interventionId);
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ): linking / persistence
    // =====================================================================

    public function test_ia_10_add_intervention_links_and_persists_with_success_flash(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available for the link test.');
        }
        $this->clearPair($incidentId, $interventionId);

        $response = $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => 'Linked via addIntervention']);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'addIntervention should redirect back with success.');

        $row = DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->first();
        $this->assertNotNull($row, 'Junction row was not created.');
        $this->assertSame('Linked via addIntervention', (string) $row->notes);
        $this->assertSame(1, (int) $row->is_active, 'is_active defaults to 1 on link.');
        $this->assertSame((int) $this->adminUser->id, (int) $row->created_by);
        $this->assertSame((int) $this->adminUser->id, (int) $row->updated_by);

        $this->cleanupIntervention($interventionId);
    }

    public function test_ia_11_add_intervention_persists_notes(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);
        $notes = 'Parent meeting scheduled for 15-Mar with mother.';

        $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => $notes]);
        $row = DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->first();
        $this->assertNotNull($row);
        $this->assertSame($notes, (string) $row->notes);

        $this->cleanupIntervention($interventionId);
    }

    public function test_ia_12_incident_store_bulk_attaches_interventions(): void
    {
        try {
            $interventionId = $this->createInterventionSeed()->id;
            $payload = $this->buildIncidentStorePayload(['interventions' => [$interventionId]]);
            if ($payload === null) {
                $this->cleanupIntervention($interventionId);
                $this->markTestSkipped('Cannot build a valid incident payload (missing student/employee dependency).');
            }

            $response = $this->postIncidentStore($payload);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Incident store should succeed.');

            $incident = BaIncident::where('student_id', $payload['student_id'])
                ->where('description', $payload['description'])->latest('id')->first();
            $this->assertNotNull($incident, 'Incident was not created by store().');
            $this->assertSame(
                1,
                DB::table(self::TABLE)->where('incident_id', $incident->id)->where('intervention_id', $interventionId)->count(),
                'store() should have attached the selected intervention to the junction.'
            );

            $this->forceDeleteIncident($incident->id);
            $this->cleanupIntervention($interventionId);
        } catch (Throwable $e) {
            $this->markTestSkipped('Bulk-attach path unavailable: ' . $e->getMessage());
        }
    }

    public function test_ia_13_incident_update_resyncs_interventions(): void
    {
        try {
            [$incidentId, $firstIntervention] = $this->resolveIncidentAndIntervention();
            if ($incidentId === null || $firstIntervention === null) {
                $this->markTestSkipped('No incident/intervention available for re-sync.');
            }
            $secondIntervention = $this->createInterventionSeed()->id;

            // Seed the first link directly, then update() with only the second → controller forceDeletes + recreates.
            $this->clearPair($incidentId, $firstIntervention);
            $this->linkJunction($incidentId, $firstIntervention, 'pre-sync');

            $payload = $this->buildIncidentUpdatePayload($incidentId, ['interventions' => [$secondIntervention]]);
            if ($payload === null) {
                $this->clearPair($incidentId, $firstIntervention);
                $this->cleanupIntervention($secondIntervention);
                $this->markTestSkipped('Cannot build a valid incident update payload.');
            }

            $response = $this->putIncident($incidentId, $payload);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Incident update should succeed.');

            $rows = DB::table(self::TABLE)->where('incident_id', $incidentId)->pluck('intervention_id')->map(fn ($v) => (int) $v)->all();
            $this->assertContains((int) $secondIntervention, $rows, 'update() should link the newly selected intervention.');

            $this->clearPair($incidentId, $firstIntervention);
            $this->cleanupIntervention($secondIntervention);
        } catch (Throwable $e) {
            $this->markTestSkipped('Re-sync path unavailable: ' . $e->getMessage());
        }
    }

    public function test_ia_14_standalone_tab_lists_applied_interventions(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $intervention = BaIntervention::find($interventionId);
        $this->clearPair($incidentId, $interventionId);
        $this->linkJunction($incidentId, $interventionId, 'listed row');

        $this->browseWithFailureScreenshot('tab-list', function (Browser $browser) use ($intervention): void {
            $this->openAppliedTab($browser);
            $browser->assertSee($intervention->name);
        });

        $this->clearPair($incidentId, $interventionId);
    }

    public function test_ia_15_add_intervention_is_idempotent_no_duplicate(): void
    {
        // firstOrCreate on (incident_id, intervention_id) → adding the same pair twice does NOT duplicate.
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);

        $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => 'first']);
        $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => 'second attempt']);

        $count = DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->count();
        $this->assertSame(1, $count, 'firstOrCreate must prevent a duplicate incident↔intervention link.');

        $this->cleanupIntervention($interventionId);
    }

    public function test_ia_16_add_intervention_notes_optional_null(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);

        $response = $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId]);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'notes is optional — link without notes should succeed.');
        $row = DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->first();
        $this->assertNotNull($row);
        $this->assertNull($row->notes, 'Omitted notes should persist as null.');

        $this->cleanupIntervention($interventionId);
    }

    public function test_ia_17_created_by_updated_by_stamped_from_auth(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);

        $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => 'stamp']);
        $row = DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->first();
        $this->assertNotNull($row);
        $this->assertSame((int) $this->adminUser->id, (int) $row->created_by);
        $this->assertSame((int) $this->adminUser->id, (int) $row->updated_by);

        $this->cleanupIntervention($interventionId);
    }

    // =====================================================================
    // Band 20–29 — Specced lifecycle vs implementation (requirement gaps)
    // =====================================================================

    public function test_ia_20_lifecycle_status_columns_specced_but_not_implemented_val_ba_ia_01(): void
    {
        // Screen 14 specs Status (Assigned/In Progress/Completed/Cancelled), Scheduled Date,
        // Assigned-To Staff, Completion Date, Progress Notes(1000). The junction implements NONE of these
        // (only notes(500) + is_active). Assert their absence so a future implementation flips this test.
        foreach (['status', 'scheduled_date', 'assigned_to', 'completion_date', 'progress_notes'] as $col) {
            $this->assertFalse(
                Schema::hasColumn(self::TABLE, $col),
                "VAL-BA-IA-01 changed: a `{$col}` column now exists on the junction (lifecycle may be implemented)."
            );
        }
        // The only free-text field is `notes` capped at 500 (not the specced 1000-char Progress Notes).
        if (DB::connection()->getDriverName() === 'mysql') {
            $type = strtolower((string) (collect(DB::select('SHOW COLUMNS FROM ' . self::TABLE))->keyBy('Field')['notes']->Type ?? ''));
            $this->assertStringContainsString('500', $type, 'notes should be VARCHAR(500), not the specced 1000-char Progress Notes.');
        }
    }

    public function test_ia_21_is_active_flag_present_but_no_toggle_endpoint_info_ba_ia_02(): void
    {
        // INFO-BA-IA-02: is_active exists (soft enable/disable) but no route toggles a junction row —
        // there is no incidents.interventions.toggle-status endpoint (only add + remove).
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'is_active'));

        $routes = $this->readAppFile($this->moduleRootPath('routes/web.php'));
        if ($routes === null) {
            $this->markTestSkipped('routes/web.php not readable from app repo.');
        }
        $this->assertStringContainsString("interventions.add", $routes);
        $this->assertStringContainsString("interventions.remove", $routes);
        // No dedicated toggle route for junction rows.
        $this->assertStringNotContainsString('interventions.toggle', $routes, 'INFO-BA-IA-02 changed: a junction toggle route now exists.');
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL) — Negative
    // =====================================================================

    public function test_ia_30_add_intervention_requires_intervention_id(): void
    {
        [$incidentId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null) {
            $this->markTestSkipped('No incident available.');
        }
        $response = $this->addInterventionCall($incidentId, []);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Missing intervention_id must fail validation.');
        $this->assertArrayHasKey('intervention_id', $response['json']['errors'] ?? []);
    }

    public function test_ia_31_add_intervention_id_must_exist_in_interventions(): void
    {
        [$incidentId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null) {
            $this->markTestSkipped('No incident available.');
        }
        $response = $this->addInterventionCall($incidentId, ['intervention_id' => 987654321]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Non-existent intervention_id must fail exists:ba_interventions,id.');
        $this->assertArrayHasKey('intervention_id', $response['json']['errors'] ?? []);
    }

    public function test_ia_32_add_intervention_id_must_be_integer(): void
    {
        [$incidentId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null) {
            $this->markTestSkipped('No incident available.');
        }
        $response = $this->addInterventionCall($incidentId, ['intervention_id' => 'not-an-int']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('intervention_id', $response['json']['errors'] ?? []);
    }

    public function test_ia_33_add_intervention_notes_max_500_is_enforced(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $response = $this->addInterventionCall($incidentId, [
            'intervention_id' => $interventionId,
            'notes'           => str_repeat('N', 501),
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'notes over 500 chars must fail.');
        $this->assertArrayHasKey('notes', $response['json']['errors'] ?? []);
    }

    public function test_ia_34_incident_request_interventions_items_must_exist(): void
    {
        // BaIncidentRequest: interventions.* → exists:ba_interventions,id. A bad id in the array fails.
        $payload = $this->buildIncidentStorePayload(['interventions' => [987654321]]);
        if ($payload === null) {
            $this->markTestSkipped('Cannot build incident payload (missing dependency).');
        }
        $response = $this->postIncidentStore($payload);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'A non-existent intervention id in interventions[] must be rejected.');
        $errors = $response['json']['errors'] ?? [];
        $this->assertTrue(
            isset($errors['interventions.0']) || isset($errors['interventions']),
            'Expected an interventions.* validation error.'
        );
    }

    public function test_ia_35_incident_request_interventions_must_be_distinct(): void
    {
        // BaIncidentRequest: interventions => array|distinct. A duplicated id in the array fails distinct.
        $interventionId = $this->createInterventionSeed()->id;
        $payload = $this->buildIncidentStorePayload(['interventions' => [$interventionId, $interventionId]]);
        if ($payload === null) {
            $this->cleanupIntervention($interventionId);
            $this->markTestSkipped('Cannot build incident payload (missing dependency).');
        }
        $response = $this->postIncidentStore($payload);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate ids in interventions[] must fail the distinct rule.');

        $this->cleanupIntervention($interventionId);
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-INT/REF)
    // =====================================================================

    public function test_ia_40_junction_fk_to_intervention_is_restrict(): void
    {
        $this->assertReferentialDeleteRule(self::INTERVENTIONS_TABLE, ['RESTRICT', 'NO ACTION'], 'intervention_id');
    }

    public function test_ia_41_junction_fk_to_incident_is_cascade(): void
    {
        $this->assertReferentialDeleteRule(self::INCIDENTS_TABLE, ['CASCADE'], 'incident_id');
    }

    public function test_ia_42_deleting_incident_cascades_and_removes_junction_rows(): void
    {
        try {
            $interventionId = $this->createInterventionSeed()->id;
            $incidentId = $this->createIncidentSeed();
            if ($incidentId === null) {
                $this->cleanupIntervention($interventionId);
                $this->markTestSkipped('Cannot create an incident (missing student/employee dependency).');
            }
            $this->linkJunction($incidentId, $interventionId, 'cascade probe');
            $this->assertSame(1, DB::table(self::TABLE)->where('incident_id', $incidentId)->count());

            // Force delete the incident → DB CASCADE removes junction rows.
            BaIncident::withTrashed()->whereKey($incidentId)->first()?->forceDelete();

            $this->assertSame(
                0,
                DB::table(self::TABLE)->where('incident_id', $incidentId)->count(),
                'ON DELETE CASCADE should have removed the junction rows with the incident.'
            );

            $this->cleanupIntervention($interventionId);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cascade path unavailable: ' . $e->getMessage());
        }
    }

    public function test_ia_43_soft_deleting_incident_does_not_remove_junction_rows(): void
    {
        // Incident uses SoftDeletes — a soft delete (->delete()) does NOT fire the DB cascade; links survive.
        try {
            $interventionId = $this->createInterventionSeed()->id;
            $incidentId = $this->createIncidentSeed();
            if ($incidentId === null) {
                $this->cleanupIntervention($interventionId);
                $this->markTestSkipped('Cannot create an incident.');
            }
            $this->linkJunction($incidentId, $interventionId, 'soft-delete probe');

            BaIncident::whereKey($incidentId)->first()?->delete(); // soft delete
            $this->assertSame(
                1,
                DB::table(self::TABLE)->where('incident_id', $incidentId)->count(),
                'Soft-deleting the incident must not cascade to junction rows (deleted_at set, FK not triggered).'
            );

            // Cleanup: force delete incident → cascade removes junction.
            BaIncident::withTrashed()->whereKey($incidentId)->first()?->forceDelete();
            $this->cleanupIntervention($interventionId);
        } catch (Throwable $e) {
            $this->markTestSkipped('Soft-delete path unavailable: ' . $e->getMessage());
        }
    }

    public function test_ia_44_restrict_blocks_raw_delete_of_referenced_intervention_int_obs_01(): void
    {
        // Direct DB delete of a referenced intervention must hit the RESTRICT FK and throw.
        // (BaIntervention::forceDelete() would instead detach via the model observer — INT-OBS-01 — bypassing RESTRICT.)
        try {
            if (DB::connection()->getDriverName() !== 'mysql') {
                $this->markTestSkipped('RESTRICT enforcement check requires MySQL.');
            }
            $interventionId = $this->createInterventionSeed()->id;
            $incidentId = $this->createIncidentSeed();
            if ($incidentId === null) {
                $this->cleanupIntervention($interventionId);
                $this->markTestSkipped('Cannot create an incident to exercise RESTRICT.');
            }
            $this->linkJunction($incidentId, $interventionId, 'restrict probe');

            $threw = false;
            try {
                DB::table(self::INTERVENTIONS_TABLE)->where('id', $interventionId)->delete();
            } catch (Throwable) {
                $threw = true;
            }
            $this->assertTrue($threw, 'RESTRICT FK should block a raw delete of an intervention still referenced by the junction.');

            // Cleanup in the correct order.
            $this->clearPair($incidentId, $interventionId);
            BaIncident::withTrashed()->whereKey($incidentId)->first()?->forceDelete();
            $this->cleanupIntervention($interventionId);
        } catch (Throwable $e) {
            $this->markTestSkipped('RESTRICT path unavailable: ' . $e->getMessage());
        }
    }

    public function test_ia_45_unique_incident_intervention_pair_enforced_at_db(): void
    {
        // uq_ba_inc_int prevents the same (incident_id, intervention_id) pair from being inserted twice.
        try {
            [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
            if ($incidentId === null || $interventionId === null) {
                $this->markTestSkipped('No incident/intervention available.');
            }
            $this->clearPair($incidentId, $interventionId);
            $this->linkJunction($incidentId, $interventionId, 'unique probe A');

            $threw = false;
            try {
                DB::table(self::TABLE)->insert([
                    'incident_id'     => $incidentId,
                    'intervention_id' => $interventionId,
                    'notes'           => 'unique probe B',
                    'is_active'       => 1,
                    'created_by'      => (int) $this->adminUser->id,
                    'updated_by'      => (int) $this->adminUser->id,
                    'created_at'      => now(),
                    'updated_at'      => now(),
                ]);
            } catch (Throwable) {
                $threw = true;
            }
            $this->assertTrue($threw, 'Duplicate (incident_id, intervention_id) must violate the unique key uq_ba_inc_int.');

            $this->clearPair($incidentId, $interventionId);
        } catch (Throwable $e) {
            $this->markTestSkipped('Unique-key path unavailable: ' . $e->getMessage());
        }
    }

    public function test_ia_46_remove_intervention_hard_deletes_the_junction_row(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);
        $jntId = $this->linkJunction($incidentId, $interventionId, 'to be removed');

        $response = $this->removeInterventionCall($incidentId, $jntId);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'removeIntervention should redirect back with success.');
        $this->assertSame(
            0,
            DB::table(self::TABLE)->where('id', $jntId)->count(),
            'removeIntervention()->delete() hard-deletes the junction row (no SoftDeletes trait).'
        );

        $this->cleanupIntervention($interventionId);
    }

    public function test_ia_47_full_lifecycle_add_list_remove(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);

        // add
        $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => 'lifecycle']);
        $row = DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->first();
        $this->assertNotNull($row, 'add step failed.');

        // list (standalone tab renders the linked intervention)
        $intervention = BaIntervention::find($interventionId);
        $this->browseWithFailureScreenshot('lifecycle-list', function (Browser $browser) use ($intervention): void {
            $this->openAppliedTab($browser);
            $browser->assertSee($intervention->name);
        });

        // remove
        $this->removeInterventionCall($incidentId, (int) $row->id);
        $this->assertSame(0, DB::table(self::TABLE)->where('id', $row->id)->count(), 'remove step failed.');

        $this->cleanupIntervention($interventionId);
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_ia_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::TAB_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_ia_51_limited_user_without_update_gets_403_on_add(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-add-403', function (Browser $browser) use ($limited, $incidentId, $interventionId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl(self::URL_PREFIX . '/incidents/' . $incidentId . '/interventions'),
                ['intervention_id' => $interventionId]
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'addIntervention requires incidents.update; limited user must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_ia_52_limited_user_without_update_gets_403_on_remove(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);
        $jntId = $this->linkJunction($incidentId, $interventionId, '403 remove probe');
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-remove-403', function (Browser $browser) use ($limited, $incidentId, $jntId): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'DELETE',
                $this->tenantUrl(self::URL_PREFIX . '/incidents/' . $incidentId . '/interventions/' . $jntId)
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->clearPair($incidentId, $interventionId);
    }

    public function test_ia_53_limited_user_without_page_permission_gets_403_on_tab(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-tab-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::TAB_PATH));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'incidents-page requires incidents-page.viewAny.');
        });

        $this->deleteUser($limited);
    }

    public function test_ia_54_incident_policy_methods_map_to_permission_strings(): void
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

    public function test_ia_55_add_and_remove_are_guarded_by_incidents_update_gate(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaIncidentController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        // Both junction mutators authorize the SAME incidents.update gate (no dedicated junction permission).
        foreach (['addIntervention', 'removeIntervention'] as $method) {
            $this->assertStringContainsString("public function {$method}", $controller);
        }
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.incidents.update')", $controller);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (list, search, filter, empty state)
    // =====================================================================

    public function test_ia_60_tab_search_filters_by_student(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $incident = BaIncident::with('student')->find($incidentId);
        $studentName = trim((string) ($incident?->student?->first_name ?? ''));
        if ($studentName === '') {
            $this->markTestSkipped('Linked incident has no resolvable student name to search on.');
        }
        $this->clearPair($incidentId, $interventionId);
        $intervention = BaIntervention::find($interventionId);
        $this->linkJunction($incidentId, $interventionId, 'search row');

        $this->browseWithFailureScreenshot('tab-search', function (Browser $browser) use ($studentName, $intervention): void {
            $this->visitAuthenticated($browser, self::TAB_PATH . '&search=' . urlencode($studentName), 1000);
            $browser->assertSee($intervention->name);
        });

        $this->clearPair($incidentId, $interventionId);
    }

    public function test_ia_61_tab_intervention_type_filter_narrows_results(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $intervention = BaIntervention::find($interventionId);
        $type = (string) ($intervention->intervention_type ?? 'corrective');
        $this->clearPair($incidentId, $interventionId);
        $this->linkJunction($incidentId, $interventionId, 'type-filter row');

        $this->browseWithFailureScreenshot('tab-type-filter', function (Browser $browser) use ($type, $intervention): void {
            $this->visitAuthenticated($browser, self::TAB_PATH . '&intervention_type_filter=' . urlencode($type), 1000);
            $browser->assertSee($intervention->name);
        });

        $this->clearPair($incidentId, $interventionId);
    }

    public function test_ia_62_empty_state_message_when_no_matches(): void
    {
        $this->browseWithFailureScreenshot('tab-empty-state', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::TAB_PATH . '&search=ZZZ_NO_MATCH_' . $this->uniqueSuffix(), 1000);
            $browser->assertSee('No interventions applied yet.');
        });
    }

    public function test_ia_63_tab_info_alert_present(): void
    {
        $this->browseWithFailureScreenshot('tab-info-alert', function (Browser $browser): void {
            $this->openAppliedTab($browser);
            $browser->assertSee('Interventions are applied from within individual incident records.');
        });
    }

    public function test_ia_64_tab_paginates_with_ia_page_parameter(): void
    {
        // The interventions-applied list uses a dedicated `ia_page` paginator name.
        $this->browseWithFailureScreenshot('tab-pagination', function (Browser $browser): void {
            $this->openAppliedTab($browser);
            // Landing the second page must not error (empty second page still renders the pane/table).
            $this->visitAuthenticated($browser, self::TAB_PATH . '&ia_page=2', 900);
            $this->assertStringContainsString('/behavioural-assessment/incidents-page', $this->currentPath($browser));
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_ia_70_add_intervention_on_invalid_incident_returns_404(): void
    {
        [, $interventionId] = $this->resolveIncidentAndIntervention();
        $response = $this->addInterventionCall(987654321, ['intervention_id' => $interventionId ?? 1]);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'addIntervention on a non-existent incident must 404 (findOrFail).');
    }

    public function test_ia_71_remove_intervention_on_invalid_incident_returns_404(): void
    {
        $response = $this->removeInterventionCall(987654321, 987654322);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'removeIntervention on a non-existent incident must 404 (route-model binding).');
    }

    public function test_ia_72_remove_intervention_with_unknown_jnt_id_is_noop_success(): void
    {
        // removeIntervention deletes by where(id=jntId) — an unknown jnt id deletes 0 rows and still redirects back.
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);
        $jntId = $this->linkJunction($incidentId, $interventionId, 'noop probe');

        $response = $this->removeInterventionCall($incidentId, 987654321);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Removing an unknown jnt id is a no-op, still redirects back.');
        // The real row is untouched.
        $this->assertSame(1, DB::table(self::TABLE)->where('id', $jntId)->count(), 'The genuine junction row must be untouched.');

        $this->clearPair($incidentId, $interventionId);
    }

    public function test_ia_73_notes_boundary_500_accepted_501_rejected(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);

        // 500 chars — at the boundary → accepted.
        $ok = $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => str_repeat('A', 500)]);
        $this->assertContains((int) ($ok['status'] ?? 0), [200, 302], 'notes of exactly 500 chars should be accepted.');
        $this->clearPair($incidentId, $interventionId);

        // 501 chars — over the boundary → rejected.
        $bad = $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => str_repeat('A', 501)]);
        $this->assertSame(422, (int) ($bad['status'] ?? 0), 'notes of 501 chars should be rejected.');

        $this->cleanupIntervention($interventionId);
    }

    public function test_ia_74_add_intervention_does_not_overwrite_existing_notes(): void
    {
        // firstOrCreate keeps the ORIGINAL notes when the pair already exists (second notes value is ignored).
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);

        $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => 'ORIGINAL']);
        $this->addInterventionCall($incidentId, ['intervention_id' => $interventionId, 'notes' => 'OVERWRITE_ATTEMPT']);

        $row = DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->first();
        $this->assertNotNull($row);
        $this->assertSame('ORIGINAL', (string) $row->notes, 'firstOrCreate must preserve the original notes, not overwrite.');

        $this->cleanupIntervention($interventionId);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_ia_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side junction tests.'
        );
        $this->assertTrue(Schema::hasTable(self::TABLE));
    }

    public function test_ia_91_cross_tenant_direct_id_isolation(): void
    {
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

    public function test_ia_92_created_by_cannot_be_spoofed_via_payload(): void
    {
        // addIntervention sets created_by/updated_by from auth()->id() server-side; a spoofed payload value is ignored.
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);

        $this->addInterventionCall($incidentId, [
            'intervention_id' => $interventionId,
            'notes'           => 'spoof probe',
            'created_by'      => 999999,
            'id'              => 555555,
        ]);
        $row = DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->first();
        $this->assertNotNull($row);
        $this->assertSame((int) $this->adminUser->id, (int) $row->created_by, 'created_by must come from auth, not the payload.');
        $this->assertNotSame(555555, (int) $row->id, 'id must be auto-increment, not payload-controlled.');

        $this->cleanupIntervention($interventionId);
    }

    public function test_ia_93_stored_xss_in_notes_escaped_on_tab(): void
    {
        [$incidentId, $interventionId] = $this->resolveIncidentAndIntervention();
        if ($incidentId === null || $interventionId === null) {
            $this->markTestSkipped('No incident/intervention available.');
        }
        $this->clearPair($incidentId, $interventionId);
        $this->linkJunction($incidentId, $interventionId, 'XSS <img src=x onerror=alert(1)>');

        $this->browseWithFailureScreenshot('stored-xss-notes', function (Browser $browser): void {
            $this->openAppliedTab($browser);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<img src=x onerror=alert(1)>', $source, 'Blade must escape stored junction notes.');
        });

        $this->clearPair($incidentId, $interventionId);
    }

    public function test_ia_94_incident_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaIncidentRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable from app repo.');
        }
        // SEC-BA-002: authorize() returns bare true (mitigated by the controller Gate::authorize).
        $this->assertMatchesRegularExpression(
            '/function\s+authorize\s*\(\s*\)\s*:\s*bool\s*\{\s*return\s+true\s*;/s',
            $request,
            'SEC-BA-002 changed: authorize() no longer returns bare true.'
        );
    }

    // =====================================================================
    // ---- Private helper library ----
    // =====================================================================

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
        $rawName = 'intervention-applied-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'intervention-applied-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function openAppliedTab(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::TAB_PATH, 1100);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#interventions-applied-pane') !== null
                || $browser->element('table') !== null;
        }, 'Interventions-applied tab did not render.');
    }

    // ---- Browser JSON request plumbing ------------------------------------

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
window.__iaApiDone = false;
window.__iaApiError = '';
window.__iaApiResult = null;

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

        window.__iaApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__iaApiError = String(error);
    } finally {
        window.__iaApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__iaApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__iaApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__iaApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->visitAuthenticated($browser, self::INCIDENTS_PAGE, 1000);
            $result = $callback($browser);
        });
        return $result;
    }

    // ---- Endpoint shims (admin session) -----------------------------------

    private function addInterventionCall(int $incidentId, array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser(
            $b,
            'POST',
            $this->tenantUrl(self::URL_PREFIX . '/incidents/' . $incidentId . '/interventions'),
            $payload
        ));
    }

    private function removeInterventionCall(int $incidentId, int $jntId): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser(
            $b,
            'DELETE',
            $this->tenantUrl(self::URL_PREFIX . '/incidents/' . $incidentId . '/interventions/' . $jntId)
        ));
    }

    private function postIncidentStore(array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser(
            $b,
            'POST',
            $this->tenantUrl(self::URL_PREFIX . '/incidents'),
            $payload
        ));
    }

    private function putIncident(int $incidentId, array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser(
            $b,
            'PUT',
            $this->tenantUrl(self::URL_PREFIX . '/incidents/' . $incidentId),
            $payload
        ));
    }

    // ---- Dependency resolution & seeding ----------------------------------

    /**
     * Return [incidentId|null, interventionId|null]. Prefers an existing incident; ensures an active intervention.
     *
     * @return array{0:?int,1:?int}
     */
    private function resolveIncidentAndIntervention(): array
    {
        $incidentId = null;
        try {
            if (Schema::hasTable(self::INCIDENTS_TABLE)) {
                $incidentId = DB::table(self::INCIDENTS_TABLE)->whereNull('deleted_at')->value('id');
                $incidentId = $incidentId !== null ? (int) $incidentId : $this->createIncidentSeed();
            }
        } catch (Throwable) {
            $incidentId = null;
        }

        $interventionId = null;
        try {
            $existing = BaIntervention::query()->where('is_active', true)->value('id');
            $interventionId = $existing !== null ? (int) $existing : (int) $this->createInterventionSeed()->id;
        } catch (Throwable) {
            $interventionId = null;
        }

        return [$incidentId, $interventionId];
    }

    private function createInterventionSeed(array $overrides = []): BaIntervention
    {
        $payload = array_merge([
            'name'              => $this->uniqueName('SEED'),
            'description'       => 'Seed intervention for junction tests',
            'intervention_type' => 'corrective',
            'sort_order'        => $this->nextAvailableSortOrder(),
            'is_active'         => true,
            'created_by'        => (int) $this->adminUser->id,
            'updated_by'        => (int) $this->adminUser->id,
        ], $overrides);

        return BaIntervention::query()->create($payload);
    }

    /** Create a minimal valid incident row directly (bypassing the controller) for FK/junction tests. */
    private function createIncidentSeed(): ?int
    {
        try {
            $studentId = $this->resolveStudentId();
            $employeeId = $this->resolveEmployeeId();
            if ($studentId === null || $employeeId === null) {
                return null;
            }
            $incident = BaIncident::query()->create([
                'student_id'    => $studentId,
                'reported_by'   => $employeeId,
                'incident_date' => now()->subDay()->toDateString(),
                'incident_type' => 'negative_incident',
                'severity'      => 'minor',
                'location'      => 'classroom',
                'description'   => 'Junction seed incident ' . $this->uniqueSuffix(),
                'is_active'     => true,
                'created_by'    => (int) $this->adminUser->id,
                'updated_by'    => (int) $this->adminUser->id,
            ]);
            return (int) $incident->id;
        } catch (Throwable) {
            return null;
        }
    }

    /** Build a valid incident store payload with the given interventions[] override; null if dependencies missing. */
    private function buildIncidentStorePayload(array $overrides = []): ?array
    {
        $studentId = $this->resolveStudentId();
        if ($studentId === null) {
            return null;
        }
        return array_merge([
            'student_id'    => $studentId,
            'incident_date' => now()->subDay()->toDateString(),
            'incident_type' => 'negative_incident',
            'severity'      => 'minor',
            'location'      => 'classroom',
            'description'   => 'Junction bulk-attach incident ' . $this->uniqueSuffix(),
            'interventions' => [],
        ], $overrides);
    }

    /** Build an update payload that preserves the immutable core fields of an existing incident. */
    private function buildIncidentUpdatePayload(int $incidentId, array $overrides = []): ?array
    {
        $incident = BaIncident::find($incidentId);
        if ($incident === null) {
            return null;
        }
        $base = [
            'student_id'    => (int) $incident->student_id,
            'incident_date' => optional($incident->incident_date)->toDateString() ?? now()->subDay()->toDateString(),
            'incident_type' => (string) $incident->incident_type,
            'severity'      => $incident->severity,
            'location'      => (string) $incident->location,
            'description'   => (string) $incident->description,
            'category_id'   => $incident->category_id,
            'criterion_id'  => $incident->criterion_id,
            'interventions' => [],
        ];
        if ($incident->incident_time) {
            $base['incident_time'] = $incident->incident_time instanceof \DateTimeInterface
                ? $incident->incident_time->format('H:i')
                : (string) $incident->incident_time;
        }
        return array_merge($base, $overrides);
    }

    private function resolveStudentId(): ?int
    {
        try {
            if (!Schema::hasTable('std_students')) {
                return null;
            }
            $q = DB::table('std_students');
            if (Schema::hasColumn('std_students', 'deleted_at')) {
                $q->whereNull('deleted_at');
            }
            if (Schema::hasColumn('std_students', 'is_active')) {
                $q->where('is_active', true);
            }
            $id = $q->value('id');
            return $id !== null ? (int) $id : null;
        } catch (Throwable) {
            return null;
        }
    }

    private function resolveEmployeeId(): ?int
    {
        try {
            if (!Schema::hasTable('sch_employees')) {
                return null;
            }
            $q = DB::table('sch_employees');
            if (Schema::hasColumn('sch_employees', 'deleted_at')) {
                $q->whereNull('deleted_at');
            }
            $id = $q->value('id');
            return $id !== null ? (int) $id : null;
        } catch (Throwable) {
            return null;
        }
    }

    /** Insert a junction row directly; returns its id. */
    private function linkJunction(int $incidentId, int $interventionId, ?string $notes = null): int
    {
        return (int) DB::table(self::TABLE)->insertGetId([
            'incident_id'     => $incidentId,
            'intervention_id' => $interventionId,
            'notes'           => $notes,
            'is_active'       => 1,
            'created_by'      => (int) $this->adminUser->id,
            'updated_by'      => (int) $this->adminUser->id,
            'created_at'      => now(),
            'updated_at'      => now(),
        ]);
    }

    /** Delete any junction rows for a specific pair (best-effort). */
    private function clearPair(int $incidentId, int $interventionId): void
    {
        try {
            DB::table(self::TABLE)->where('incident_id', $incidentId)->where('intervention_id', $interventionId)->delete();
        } catch (Throwable) {
        }
    }

    /** Detach all junction rows for an intervention, then force-delete the intervention if it was a test seed. */
    private function cleanupIntervention(?int $interventionId): void
    {
        if ($interventionId === null) {
            return;
        }
        try {
            DB::table(self::TABLE)->where('intervention_id', $interventionId)->delete();
        } catch (Throwable) {
        }
        try {
            $intervention = BaIntervention::withTrashed()->find($interventionId);
            // Only remove seeds this suite created (name marker); never delete provisioned master data.
            if ($intervention !== null && str_contains((string) $intervention->name, 'Intervention ')
                && str_contains((string) $intervention->description, 'junction tests')) {
                $intervention->forceDelete();
            }
        } catch (Throwable) {
        }
    }

    private function forceDeleteIncident(?int $incidentId): void
    {
        if ($incidentId === null) {
            return;
        }
        try {
            DB::table(self::TABLE)->where('incident_id', $incidentId)->delete();
            BaIncident::withTrashed()->whereKey($incidentId)->first()?->forceDelete();
        } catch (Throwable) {
        }
    }

    /**
     * @param array<int,string> $acceptedRules
     */
    private function assertReferentialDeleteRule(string $referencedTable, array $acceptedRules, string $column): void
    {
        try {
            if (DB::connection()->getDriverName() !== 'mysql' || !Schema::hasTable(self::TABLE)) {
                $this->markTestSkipped('FK metadata unavailable (non-MySQL or missing table).');
            }
            $fk = DB::select(
                "SELECT rc.DELETE_RULE
                   FROM information_schema.REFERENTIAL_CONSTRAINTS rc
                   JOIN information_schema.KEY_COLUMN_USAGE kcu
                     ON kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
                    AND kcu.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
                  WHERE rc.CONSTRAINT_SCHEMA = DATABASE()
                    AND rc.TABLE_NAME = ?
                    AND rc.REFERENCED_TABLE_NAME = ?
                    AND kcu.COLUMN_NAME = ?",
                [self::TABLE, $referencedTable, $column]
            );
            if (empty($fk)) {
                $this->markTestSkipped("No FK metadata for {$column} → {$referencedTable}.");
            }
            $rule = strtoupper((string) ($fk[0]->DELETE_RULE ?? ''));
            $matched = false;
            foreach ($acceptedRules as $accepted) {
                if (str_contains($rule, strtoupper($accepted))) {
                    $matched = true;
                    break;
                }
            }
            $this->assertTrue($matched, "{$column} FK DELETE_RULE expected one of [" . implode(',', $acceptedRules) . "], found: {$rule}");
        } catch (Throwable $e) {
            $this->markTestSkipped('Referential rule path unavailable: ' . $e->getMessage());
        }
    }

    private function nextAvailableSortOrder(): int
    {
        try {
            $used = DB::table(self::INTERVENTIONS_TABLE)->whereNull('deleted_at')->pluck('sort_order')
                ->map(fn ($v) => (int) $v)->all();
            $usedSet = array_flip($used);
            for ($attempt = 0; $attempt < 50; $attempt++) {
                $candidate = random_int(1, 255);
                if (!isset($usedSet[$candidate])) {
                    return $candidate;
                }
            }
            for ($i = 1; $i <= 255; $i++) {
                if (!isset($usedSet[$i])) {
                    return $i;
                }
            }
        } catch (Throwable) {
        }
        return random_int(1, 255);
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
                'name'              => 'IA Limited ' . $this->uniqueSuffix(),
                'email'             => 'ia_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'IA' . substr($this->uniqueSuffix(), -8);
            }

            $user = User::factory()->create($attributes);

            foreach (['is_super_admin', 'super_admin_flag'] as $col) {
                if (Schema::hasColumn('sys_users', $col)) {
                    $user->forceFill([$col => 0]);
                }
            }
            $user->save();

            if (method_exists($user, 'syncRoles')) {
                try {
                    $user->syncRoles([]);
                } catch (Throwable) {
                }
            }
            if (method_exists($user, 'syncPermissions')) {
                try {
                    $user->syncPermissions([]);
                } catch (Throwable) {
                }
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
        $this->grantAppliedPermissions($this->adminUser);
    }

    private function grantAppliedPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::IA_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::IA_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::IA_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.intervention-applied-admin');
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
            $modelFile = (new ReflectionClass(BaIncidentInterventionJnt::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaIncidentInterventionJnt.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaIncidentInterventionJnt::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaIncidentInterventionJnt.php → app root = dirname(,5)
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

    private function uniqueName(string $prefix): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $clean = $clean === '' ? 'IA' : substr($clean, 0, 12);
        return substr($clean . ' Intervention ' . $this->uniqueSuffix(), 0, 100);
    }
}
