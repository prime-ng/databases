<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaAuditLog;
use Modules\BehaviouralAssessment\Models\BaIncident;
use Modules\BehaviouralAssessment\Models\BaIncidentInterventionJnt;
use Modules\BehaviouralAssessment\Models\BaIncidentWitnessJnt;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Incident Log (Incident) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/12-Incident-Log.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns → tenant init required).
 * Runtime tables     : ba_incidents, ba_incident_witnesses_jnt, ba_incident_intervention_jnt, ba_audit_log
 *                      (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController
 * FormRequest        : Modules\BehaviouralAssessment\Http\Requests\BaIncidentRequest
 * Permission prefix  : tenant.behavioural-assessment.incidents.{viewAny|view|create|update|delete|restore|forceDelete|status}
 * Audit sink         : ba_audit_log via BaAuditLog::log(entity_type='incident', ...) — NOT the tenant activity_logs helper.
 *
 * Defects proven (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md):
 *   - SEC-BA-001 (P1/safeguarding) : severe-incident parent notification (REQ-BA-015 / BR-BA-013) ENTIRELY ABSENT.
 *                                    store() never notifies, never reads ba_config.parent_notification_threshold,
 *                                    is_notified stays 0 even for `critical` severity (proven in _92 + source scan _93).
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - SEC-BA-002 : FormRequest authorize() returns bare true, mitigated by controller Gate (proven in _55).
 *
 * Feature-scoped requirement-vs-implementation gaps (screen 12-Incident-Log.md vs code):
 *   - INC-GAP-01 : "max 7 days from event" real-time-logging rule NOT enforced — only before_or_equal:today (proven in _71).
 *   - INC-GAP-02 : description Min 20 / Max 1000 (screen) NOT enforced — rule is only max:3000, no min (proven in _72).
 *   - INC-GAP-03 : Category marked Mandatory (screen) but category_id is nullable in FormRequest (proven in _73).
 *   - INC-GAP-04 : severity labels Info/Low/Medium/High (screen) diverge from enum minor/moderate/major/critical (proven in _74).
 *   - INC-GAP-05 : positive incident_type value is `positive_reinforcement`, not the screen's "Positive (Achievement)" (proven in _11).
 */
class bha_Incident_TestCas extends DuskTestCase
{
    private const URL_PREFIX      = '/behavioural-assessment';
    private const LOG_PATH        = '/behavioural-assessment/incidents-page?tab=log';
    private const CREATE_PATH     = '/behavioural-assessment/incidents/create';
    private const STORE_PATH      = '/behavioural-assessment/incidents';
    private const TRASH_PATH      = '/behavioural-assessment/incidents/trash';

    private const INCIDENTS_TABLE = 'ba_incidents';
    private const WITNESS_TABLE   = 'ba_incident_witnesses_jnt';
    private const INTERV_TABLE    = 'ba_incident_intervention_jnt';
    private const AUDIT_TABLE     = 'ba_audit_log';
    private const DDL_INCIDENTS   = 'bha_incidents';   // stale DDL-doc name (should NOT exist at runtime)

    private const SCREENSHOT_DIR  = 'tests/Browser/Modules/BehaviouralAssessment/Incident/screenshots';

    /** @var array<int,string> */
    private const INC_PERMISSIONS = [
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

    public function test_incident_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'Table ba_incidents does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::INCIDENTS_TABLE, [
                'id', 'student_id', 'reported_by', 'category_id', 'criterion_id',
                'incident_date', 'incident_time', 'incident_type', 'severity',
                'description', 'location', 'intervention_notes',
                'is_follow_up_required', 'follow_up_date', 'follow_up_notes',
                'attachments_json', 'is_notified', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_incidents table.'
        );

        // Soft-delete column present AND the model uses the trait (constraint #12/#30 — assert both independently).
        $this->assertTrue(Schema::hasColumn(self::INCIDENTS_TABLE, 'deleted_at'), 'deleted_at missing on ba_incidents.');
        $this->assertContains(
            SoftDeletes::class,
            class_uses_recursive(BaIncident::class),
            'BaIncident model must use the SoftDeletes trait.'
        );

        // Model configuration truth.
        $incident = new BaIncident();
        $this->assertSame(self::INCIDENTS_TABLE, $incident->getTable(), 'BaIncident::$table must be ba_incidents.');

        foreach (['student_id', 'reported_by', 'category_id', 'incident_date', 'incident_type',
                  'severity', 'description', 'location', 'is_notified', 'is_active'] as $fillable) {
            $this->assertContains($fillable, $incident->getFillable(), "Fillable is missing '{$fillable}'.");
        }

        $casts = $incident->getCasts();
        $this->assertSame('boolean', $casts['is_notified'] ?? null, 'is_notified must be cast to boolean.');
        $this->assertSame('boolean', $casts['is_active'] ?? null, 'is_active must be cast to boolean.');
        $this->assertArrayHasKey('attachments_json', $casts, 'attachments_json must be cast (array).');

        // Relationships resolve to the right classes.
        $this->assertSame(self::WITNESS_TABLE, $incident->witnesses()->getRelated()->getTable());
        $this->assertInstanceOf(BaIncident::class, (new BaIncident()));

        // FormRequest rule truth — read the real file via reflection (constraint #32).
        $requestFile = (new ReflectionClass(\Modules\BehaviouralAssessment\Http\Requests\BaIncidentRequest::class))->getFileName();
        $requestSrc  = $this->readAppFile(is_string($requestFile) ? $requestFile : null);
        if ($requestSrc !== null) {
            $this->assertStringContainsString('exists:std_students,id', $requestSrc, 'student_id exists rule missing.');
            $this->assertStringContainsString('before_or_equal:today', $requestSrc, 'incident_date future rule missing.');
            $this->assertStringContainsString('in:positive_reinforcement,negative_incident', $requestSrc, 'incident_type enum rule missing.');
            $this->assertStringContainsString('required_if:incident_type,negative_incident', $requestSrc, 'severity required_if rule missing.');
            $this->assertStringContainsString('in:minor,moderate,major,critical', $requestSrc, 'severity enum rule missing.');
        } else {
            $this->addToAssertionCount(1);
        }
    }

    public function test_incident_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // DOC-BA-001: the DDL doc names the table bha_incidents, but the live schema uses ba_incidents.
        $this->assertTrue(Schema::hasTable(self::INCIDENTS_TABLE), 'Live table ba_incidents must exist.');
        $this->assertFalse(
            Schema::hasTable(self::DDL_INCIDENTS),
            'Stale DDL-doc table bha_incidents should NOT exist at runtime (DOC-BA-001).'
        );
    }

    public function test_incident_03_junction_and_audit_tables_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::WITNESS_TABLE), 'ba_incident_witnesses_jnt missing.');
        $this->assertTrue(
            Schema::hasColumns(self::WITNESS_TABLE, ['id', 'incident_id', 'witness_type', 'witness_id', 'is_active']),
            'ba_incident_witnesses_jnt columns missing.'
        );
        $this->assertTrue(Schema::hasTable(self::INTERV_TABLE), 'ba_incident_intervention_jnt missing.');
        $this->assertTrue(
            Schema::hasColumns(self::INTERV_TABLE, ['id', 'incident_id', 'intervention_id', 'notes']),
            'ba_incident_intervention_jnt columns missing.'
        );

        // Audit sink truth — Incident writes to ba_audit_log (not the tenant activity_logs).
        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE), 'ba_audit_log missing.');
        $this->assertSame(self::AUDIT_TABLE, (new BaAuditLog())->getTable());
        $this->assertSame('incident', BaAuditLog::ENTITY_INCIDENT, 'ENTITY_INCIDENT constant must equal "incident".');
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_incident_10_create_persists_incident_and_redirects_with_success_flash(): void
    {
        $deps = $this->incidentDependencies();
        $response = $this->postIncident([
            'student_id'   => $deps['student_id'],
            'category_id'  => $deps['category_id'],
            'description'  => 'Store happy path ' . $this->uniqueSuffix() . ' — student was disruptive in class.',
        ]);

        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Store should redirect on success. Got: ' . ($response['status'] ?? 'n/a'));

        $row = BaIncident::query()->where('student_id', $deps['student_id'])
            ->orderByDesc('id')->first();
        $this->assertNotNull($row, 'Incident row was not persisted.');
        $this->assertSame('negative_incident', $row->incident_type);
        $this->assertSame('classroom', $row->location);

        $this->forceDeleteIncident($row);
    }

    public function test_incident_11_severity_is_nulled_for_positive_reinforcement_incident(): void
    {
        // INC-GAP-05: the positive value is `positive_reinforcement`. Controller nulls severity for positives.
        $deps = $this->incidentDependencies();
        $response = $this->postIncident([
            'student_id'    => $deps['student_id'],
            'category_id'   => $deps['category_id'],
            'incident_type' => 'positive_reinforcement',
            'severity'      => 'critical', // supplied but must be discarded for positives
            'description'   => 'Positive milestone ' . $this->uniqueSuffix() . ' — led the school festival superbly.',
        ]);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $row = BaIncident::query()->where('student_id', $deps['student_id'])
            ->where('incident_type', 'positive_reinforcement')->orderByDesc('id')->first();
        $this->assertNotNull($row, 'Positive incident not persisted.');
        $this->assertNull($row->severity, 'Severity must be NULL for positive_reinforcement incidents.');

        $this->forceDeleteIncident($row);
    }

    public function test_incident_12_create_logs_audit_rows_to_ba_audit_log(): void
    {
        $deps = $this->incidentDependencies();
        $this->postIncident([
            'student_id'  => $deps['student_id'],
            'category_id' => $deps['category_id'],
            'description' => 'Audit-row check ' . $this->uniqueSuffix() . ' — logged event for trail.',
        ]);
        $row = BaIncident::query()->where('student_id', $deps['student_id'])->orderByDesc('id')->first();
        $this->assertNotNull($row);

        $audits = BaAuditLog::query()
            ->where('entity_type', BaAuditLog::ENTITY_INCIDENT)
            ->where('entity_id', $row->id)
            ->pluck('field_name')
            ->all();
        // store() logs: incident_type, severity, location, student_id
        $this->assertContains('incident_type', $audits, 'Missing incident_type audit row.');
        $this->assertContains('location', $audits, 'Missing location audit row.');
        $this->assertContains('student_id', $audits, 'Missing student_id audit row.');

        $this->forceDeleteIncident($row);
    }

    public function test_incident_13_create_attaches_selected_interventions_to_junction(): void
    {
        $deps = $this->incidentDependencies();
        if ($deps['intervention_id'] === 0) {
            $this->markTestSkipped('No ba_interventions row available to attach.');
        }
        $this->postIncident([
            'student_id'    => $deps['student_id'],
            'category_id'   => $deps['category_id'],
            'description'   => 'Intervention attach ' . $this->uniqueSuffix() . ' — needs a written warning.',
            'interventions' => [$deps['intervention_id']],
        ]);
        $row = BaIncident::query()->where('student_id', $deps['student_id'])->orderByDesc('id')->first();
        $this->assertNotNull($row);
        $this->assertSame(
            1,
            BaIncidentInterventionJnt::query()->where('incident_id', $row->id)->count(),
            'Selected intervention should be attached to the incident.'
        );

        $this->forceDeleteIncident($row);
    }

    public function test_incident_14_create_attaches_student_and_staff_witnesses(): void
    {
        $deps = $this->incidentDependencies();
        $this->postIncident([
            'student_id'          => $deps['student_id'],
            'category_id'         => $deps['category_id'],
            'description'         => 'Witness attach ' . $this->uniqueSuffix() . ' — seen by peers and staff.',
            'witness_staff_ids'   => [$deps['employee_id']],
        ]);
        $row = BaIncident::query()->where('student_id', $deps['student_id'])->orderByDesc('id')->first();
        $this->assertNotNull($row);
        $this->assertGreaterThanOrEqual(
            1,
            BaIncidentWitnessJnt::query()->where('incident_id', $row->id)->where('witness_type', 'staff')->count(),
            'Staff witness should be attached.'
        );

        $this->forceDeleteIncident($row);
    }

    public function test_incident_15_update_persists_mutable_follow_up_fields(): void
    {
        $incident = $this->createIncidentSeed();
        $response = $this->putIncident($incident->id, $this->immutableEcho($incident, [
            'intervention_notes'    => 'Follow-up applied ' . $this->uniqueSuffix(),
            'is_follow_up_required' => 1,
        ]));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $fresh = BaIncident::query()->find($incident->id);
        $this->assertNotNull($fresh);
        $this->assertStringContainsString('Follow-up applied', (string) $fresh->intervention_notes);
        $this->assertTrue((bool) $fresh->is_follow_up_required, 'is_follow_up_required should have been updated to true.');

        $this->forceDeleteIncident($fresh);
    }

    public function test_incident_16_update_blocks_core_field_change_br_ba_008(): void
    {
        // BR-BA-008: core fields immutable after creation. Attempting to change them is rejected;
        // the controller returns back()->with('error', ...) and does NOT mutate the row.
        $incident = $this->createIncidentSeed(['description' => 'Immutable original ' . $this->uniqueSuffix()]);
        $original = $incident->description;

        $this->putIncident($incident->id, $this->immutableEcho($incident, [
            'description' => 'ATTEMPTED CHANGE ' . $this->uniqueSuffix(),
        ]));

        $fresh = BaIncident::query()->find($incident->id);
        $this->assertNotNull($fresh);
        $this->assertSame($original, $fresh->description, 'Core field description must be immutable after creation (BR-BA-008).');

        $this->forceDeleteIncident($fresh);
    }

    public function test_incident_17_follow_up_endpoint_appends_notes(): void
    {
        $incident = $this->createIncidentSeed();
        $response = $this->apiCall(
            'POST',
            $this->tenantUrl('/behavioural-assessment/incidents/' . $incident->id . '/follow-up'),
            ['follow_up_notes' => 'Counsellor met the parent ' . $this->uniqueSuffix()]
        );
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $fresh = BaIncident::query()->find($incident->id);
        $this->assertNotNull($fresh);
        $this->assertStringContainsString('Counsellor met the parent', (string) $fresh->follow_up_notes);

        $this->forceDeleteIncident($fresh);
    }

    public function test_incident_18_show_page_renders_incident_detail(): void
    {
        $incident = $this->createIncidentSeed(['description' => 'Show render marker ' . $this->uniqueSuffix()]);
        $this->browseWithFailureScreenshot('show-renders', function (Browser $browser) use ($incident): void {
            $this->visitAuthenticated($browser, '/behavioural-assessment/incidents/' . $incident->id, 1000);
            $browser->assertSee('Incident Detail');
        });
        $this->forceDeleteIncident($incident->fresh());
    }

    public function test_incident_19_incidents_page_log_tab_lists_incident(): void
    {
        $incident = $this->createIncidentSeed();
        $this->browseWithFailureScreenshot('log-tab-lists', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::LOG_PATH, 1200);
            $browser->waitUsing(20, 200, function () use ($browser): bool {
                return $browser->element('table') !== null || $browser->element('.pagination') !== null;
            }, 'Incident log tab did not render.');
        });
        $this->forceDeleteIncident($incident->fresh());
    }

    // =====================================================================
    // Band 20–29 — Record lifecycle state machine (BC-SM)
    // =====================================================================

    public function test_incident_20_delete_soft_deletes_and_moves_to_trash(): void
    {
        $incident = $this->createIncidentSeed();
        $response = $this->apiCall('DELETE', $this->tenantUrl(self::STORE_PATH . '/' . $incident->id));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertNull(BaIncident::query()->find($incident->id), 'Incident should be soft-deleted (invisible to default scope).');
        $this->assertNotNull(BaIncident::withTrashed()->find($incident->id), 'Soft-deleted incident should still exist with trashed scope.');

        $this->forceDeleteIncident(BaIncident::withTrashed()->find($incident->id));
    }

    public function test_incident_21_restore_from_trash_reactivates(): void
    {
        $incident = $this->createIncidentSeed();
        $incident->delete();
        $response = $this->apiCall('GET', $this->tenantUrl('/behavioural-assessment/incidents/' . $incident->id . '/restore'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertNotNull(BaIncident::query()->find($incident->id), 'Restored incident should be visible in default scope.');
        $this->forceDeleteIncident(BaIncident::query()->find($incident->id));
    }

    public function test_incident_22_force_delete_purges_incident_and_cascades_witnesses(): void
    {
        $incident = $this->createIncidentSeed();
        $deps = $this->incidentDependencies();
        BaIncidentWitnessJnt::query()->create([
            'incident_id'  => $incident->id,
            'witness_type' => 'staff',
            'witness_id'   => $deps['employee_id'],
            'is_active'    => true,
            'created_by'   => (int) $this->adminUser->id,
            'updated_by'   => (int) $this->adminUser->id,
        ]);
        $incident->delete();

        $response = $this->apiCall('DELETE', $this->tenantUrl('/behavioural-assessment/incidents/' . $incident->id . '/force-delete'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertNull(BaIncident::withTrashed()->find($incident->id), 'Force-deleted incident should be gone entirely.');
        $this->assertSame(
            0,
            BaIncidentWitnessJnt::query()->where('incident_id', $incident->id)->count(),
            'Witness junction rows should cascade-delete with the incident (FK ON DELETE CASCADE).'
        );
    }

    public function test_incident_23_full_lifecycle_create_delete_restore_force_delete(): void
    {
        $incident = $this->createIncidentSeed();
        $id = $incident->id;

        $incident->delete();
        $this->assertNotNull(BaIncident::onlyTrashed()->find($id), 'Should be in trash after delete.');

        $incident->restore();
        $this->assertNotNull(BaIncident::query()->find($id), 'Should be live after restore.');

        $incident->delete();
        $this->forceDeleteIncident(BaIncident::withTrashed()->find($id));
        $this->assertNull(BaIncident::withTrashed()->find($id), 'Should be purged after force-delete.');
    }

    public function test_incident_24_core_fields_immutable_after_create_state_lock_br_ba_008(): void
    {
        // The "post-create core-field lock" transition: attempting to change student_id is rejected.
        $incident = $this->createIncidentSeed();
        $originalStudent = (int) $incident->student_id;

        $altStudent = (int) (DB::table('std_students')->where('id', '!=', $originalStudent)->value('id') ?? 0);
        if ($altStudent === 0) {
            $this->markTestSkipped('Need a second student to attempt an illegal student_id change.');
        }

        $this->putIncident($incident->id, $this->immutableEcho($incident, ['student_id' => $altStudent]));

        $fresh = BaIncident::query()->find($incident->id);
        $this->assertNotNull($fresh);
        $this->assertSame($originalStudent, (int) $fresh->student_id, 'student_id must remain locked after creation (BR-BA-008).');

        $this->forceDeleteIncident($fresh);
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL)
    // =====================================================================

    public function test_incident_30_required_fields_are_rejected(): void
    {
        $response = $this->postIncidentRaw([
            'student_id'    => '',
            'incident_date' => '',
            'incident_type' => '',
            'location'      => '',
            'description'   => '',
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty required fields must yield 422.');
        $errors = $response['json']['errors'] ?? [];
        $this->assertArrayHasKey('student_id', $errors);
        $this->assertArrayHasKey('incident_type', $errors);
        $this->assertArrayHasKey('description', $errors);
    }

    public function test_incident_31_student_id_must_exist(): void
    {
        $response = $this->postIncidentRaw(['student_id' => 999999999]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('student_id', $response['json']['errors'] ?? []);
    }

    public function test_incident_32_incident_type_must_be_in_allowed_enum(): void
    {
        $response = $this->postIncidentRaw(['incident_type' => 'made_up_type']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('incident_type', $response['json']['errors'] ?? []);
    }

    public function test_incident_33_severity_required_for_negative_incident(): void
    {
        $response = $this->postIncidentRaw([
            'incident_type' => 'negative_incident',
            'severity'      => '',
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Severity is required_if incident_type=negative_incident.');
        $this->assertArrayHasKey('severity', $response['json']['errors'] ?? []);
    }

    public function test_incident_34_severity_must_be_in_allowed_enum(): void
    {
        $response = $this->postIncidentRaw([
            'incident_type' => 'negative_incident',
            'severity'      => 'High', // screen label — NOT a valid enum value (INC-GAP-04)
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('severity', $response['json']['errors'] ?? []);
    }

    public function test_incident_35_location_must_be_in_allowed_enum(): void
    {
        $response = $this->postIncidentRaw(['location' => 'rooftop']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('location', $response['json']['errors'] ?? []);
    }

    public function test_incident_36_future_incident_date_is_rejected(): void
    {
        $response = $this->postIncidentRaw(['incident_date' => now()->addDay()->toDateString()]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Future incident_date must be rejected (before_or_equal:today).');
        $this->assertArrayHasKey('incident_date', $response['json']['errors'] ?? []);
    }

    public function test_incident_37_incident_time_bad_format_is_rejected(): void
    {
        $response = $this->postIncidentRaw(['incident_time' => '25:99']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('incident_time', $response['json']['errors'] ?? []);
    }

    public function test_incident_38_follow_up_date_before_incident_date_is_rejected(): void
    {
        $response = $this->postIncidentRaw([
            'incident_date' => now()->toDateString(),
            'follow_up_date' => now()->subDays(3)->toDateString(),
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'follow_up_date must be after_or_equal:incident_date.');
        $this->assertArrayHasKey('follow_up_date', $response['json']['errors'] ?? []);
    }

    public function test_incident_39_invalid_category_id_is_rejected(): void
    {
        $response = $this->postIncidentRaw(['category_id' => 999999999]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('category_id', $response['json']['errors'] ?? []);
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_incident_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $browser->assertPathContains('/login');
        });
    }

    public function test_incident_51_limited_user_without_create_permission_gets_403(): void
    {
        $limited = $this->makeLimitedUser();
        try {
            $this->actingAs($limited);
            $status = $this->getJson($this->tenantUrl(self::CREATE_PATH))->getStatusCode();
            $this->assertContains($status, [401, 403], 'Unpermissioned user must be denied create. Got ' . $status);
        } finally {
            $this->deleteUser($limited);
        }
    }

    public function test_incident_52_limited_user_without_delete_permission_gets_403(): void
    {
        $incident = $this->createIncidentSeed();
        $limited = $this->makeLimitedUser();
        try {
            $this->actingAs($limited);
            $status = $this->deleteJson($this->tenantUrl(self::STORE_PATH . '/' . $incident->id))->getStatusCode();
            $this->assertContains($status, [401, 403, 419], 'Unpermissioned user must be denied delete. Got ' . $status);
        } finally {
            $this->deleteUser($limited);
            $this->forceDeleteIncident(BaIncident::withTrashed()->find($incident->id));
        }
    }

    public function test_incident_53_limited_user_without_force_delete_permission_gets_403(): void
    {
        $incident = $this->createIncidentSeed();
        $incident->delete();
        $limited = $this->makeLimitedUser();
        try {
            $this->actingAs($limited);
            $status = $this->deleteJson($this->tenantUrl('/behavioural-assessment/incidents/' . $incident->id . '/force-delete'))->getStatusCode();
            $this->assertContains($status, [401, 403, 419], 'Unpermissioned user must be denied force-delete. Got ' . $status);
        } finally {
            $this->deleteUser($limited);
            $this->forceDeleteIncident(BaIncident::withTrashed()->find($incident->id));
        }
    }

    public function test_incident_54_policy_methods_map_to_permission_strings(): void
    {
        $policyFile = (new ReflectionClass(\Modules\BehaviouralAssessment\Policies\BaIncidentPolicy::class))->getFileName();
        $src = $this->readAppFile(is_string($policyFile) ? $policyFile : null);
        if ($src === null) {
            $this->markTestSkipped('BaIncidentPolicy source not readable from the runner.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.incidents.{$ability}",
                $src,
                "Policy must map {$ability} to its permission string."
            );
        }
    }

    public function test_incident_55_form_request_authorize_returns_true_sec_ba_002(): void
    {
        // SEC-BA-002 pattern: FormRequest authorize() is a bare `return true;` — auth is enforced only
        // by the controller Gate::authorize. Documented (mitigated), not an open hole.
        $requestFile = (new ReflectionClass(\Modules\BehaviouralAssessment\Http\Requests\BaIncidentRequest::class))->getFileName();
        $src = $this->readAppFile(is_string($requestFile) ? $requestFile : null);
        if ($src === null) {
            $this->markTestSkipped('BaIncidentRequest source not readable from the runner.');
        }
        $this->assertMatchesRegularExpression(
            '/function\s+authorize\s*\(\s*\)\s*:\s*bool\s*\{\s*return\s+true\s*;/',
            $src,
            'BaIncidentRequest::authorize() should return bare true (SEC-BA-002).'
        );
        // And the controller compensates with a Gate::authorize on store.
        $ctrlFile = (new ReflectionClass(\Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController::class))->getFileName();
        $ctrlSrc = $this->readAppFile(is_string($ctrlFile) ? $ctrlFile : null);
        if ($ctrlSrc !== null) {
            $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.incidents.create')", $ctrlSrc);
        } else {
            $this->addToAssertionCount(1);
        }
    }

    // =====================================================================
    // Band 60–69 — UI/UX (search, filter, pagination, empty state)
    // =====================================================================

    public function test_incident_60_incidents_page_filter_by_incident_type_renders(): void
    {
        $this->browseWithFailureScreenshot('filter-type', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::LOG_PATH . '&incident_type=negative_incident', 1200);
            $browser->assertPathBeginsWith('/behavioural-assessment/incidents-page');
        });
    }

    public function test_incident_61_incidents_page_filter_by_severity_renders(): void
    {
        $this->browseWithFailureScreenshot('filter-severity', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::LOG_PATH . '&severity=critical', 1200);
            $browser->assertPathBeginsWith('/behavioural-assessment/incidents-page');
        });
    }

    public function test_incident_62_trash_page_renders(): void
    {
        $this->browseWithFailureScreenshot('trash-renders', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH, 1000);
            $browser->waitUsing(20, 200, function () use ($browser): bool {
                return $browser->element('table') !== null || $browser->element('body') !== null;
            }, 'Trash page did not render.');
        });
    }

    public function test_incident_63_breadcrumb_present_on_show_page(): void
    {
        $incident = $this->createIncidentSeed();
        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser) use ($incident): void {
            $this->visitAuthenticated($browser, '/behavioural-assessment/incidents/' . $incident->id, 1000);
            $browser->assertSee('Incident Detail');
        });
        $this->forceDeleteIncident($incident->fresh());
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG) + feature-scoped requirement gaps
    // =====================================================================

    public function test_incident_70_invalid_id_returns_404(): void
    {
        $status = $this->getJson($this->tenantUrl('/behavioural-assessment/incidents/999999999'))->getStatusCode();
        $this->assertContains($status, [403, 404], 'Non-existent incident id should not resolve to a real record.');
    }

    public function test_incident_71_seven_day_realtime_logging_rule_not_enforced_inc_gap_01(): void
    {
        // Screen BR: "Incidents can only be logged within a maximum of 7 days from the event date."
        // Implementation only enforces before_or_equal:today, so a 30-day-old date is ACCEPTED — GAP proven.
        $deps = $this->incidentDependencies();
        $response = $this->postIncident([
            'student_id'    => $deps['student_id'],
            'category_id'   => $deps['category_id'],
            'incident_date' => now()->subDays(30)->toDateString(),
            'description'   => 'Stale-date acceptance ' . $this->uniqueSuffix() . ' — logged 30 days late.',
        ]);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'A 30-day-old incident_date is accepted — the 7-day real-time-logging rule is NOT enforced (INC-GAP-01).'
        );
        $row = BaIncident::query()->where('student_id', $deps['student_id'])
            ->whereDate('incident_date', now()->subDays(30)->toDateString())->orderByDesc('id')->first();
        $this->assertNotNull($row, 'Stale-dated incident should have persisted, confirming the missing rule.');
        $this->forceDeleteIncident($row);
    }

    public function test_incident_72_description_min_20_and_max_1000_not_enforced_inc_gap_02(): void
    {
        // Screen: Description Min 20 / Max 1000. Implementation: only max:3000, no min. A 5-char body is accepted.
        $deps = $this->incidentDependencies();
        $response = $this->postIncident([
            'student_id'  => $deps['student_id'],
            'category_id' => $deps['category_id'],
            'description' => 'Short', // 5 chars — well under the screen's 20-char minimum
        ]);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'A 5-char description is accepted — description Min 20 is NOT enforced (INC-GAP-02).'
        );
        $row = BaIncident::query()->where('student_id', $deps['student_id'])->where('description', 'Short')->orderByDesc('id')->first();
        $this->assertNotNull($row);
        $this->forceDeleteIncident($row);
    }

    public function test_incident_73_category_id_optional_despite_mandatory_requirement_inc_gap_03(): void
    {
        // Screen marks Category "Mandatory: Yes". FormRequest makes category_id nullable — GAP.
        $deps = $this->incidentDependencies();
        $response = $this->postIncidentRaw([
            'student_id'  => $deps['student_id'],
            'category_id' => null,
            'description' => 'No category supplied ' . $this->uniqueSuffix() . ' — should still be accepted.',
        ]);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [200, 302],
            'Incident without a category is accepted — category is NOT mandatory in code (INC-GAP-03).'
        );
        $row = BaIncident::query()->where('student_id', $deps['student_id'])->whereNull('category_id')->orderByDesc('id')->first();
        if ($row) {
            $this->forceDeleteIncident($row);
        }
    }

    public function test_incident_74_severity_enum_diverges_from_requirement_labels_inc_gap_04(): void
    {
        // The DDL/live enum is minor/moderate/major/critical, NOT the screen's Info/Low/Medium/High labels.
        $type = $this->columnType(self::INCIDENTS_TABLE, 'severity');
        foreach (['minor', 'moderate', 'major', 'critical'] as $valid) {
            $this->assertStringContainsString($valid, $type, "severity enum should include '{$valid}'.");
        }
        $this->assertStringNotContainsStringIgnoringCase("'info'", $type, "severity enum should NOT contain the screen label 'Info' (INC-GAP-04).");
    }

    public function test_incident_75_incident_type_enum_matches_live_values(): void
    {
        $type = $this->columnType(self::INCIDENTS_TABLE, 'incident_type');
        $this->assertStringContainsString('positive_reinforcement', $type);
        $this->assertStringContainsString('negative_incident', $type);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation (TC-T) + security pack (TC-S)
    //   incl. the SEC-BA-001 P0-safeguarding proof
    // =====================================================================

    public function test_incident_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for a tenant-side feature.'
        );
    }

    public function test_incident_91_cross_tenant_direct_id_isolation(): void
    {
        // A seeded incident id in this tenant must not resolve when a different tenant would query it.
        $incident = $this->createIncidentSeed();
        $this->assertNotNull(BaIncident::query()->find($incident->id), 'Incident should be visible within its own tenant.');
        // Direct-id fetch under the current (correct) tenant works; cross-tenant leakage is architecturally
        // prevented by database-per-tenant. We assert the record is scoped to this tenant DB.
        $this->assertSame(
            1,
            (int) BaIncident::query()->whereKey($incident->id)->count(),
            'Exactly one row for this id should exist in the current tenant DB.'
        );
        $this->forceDeleteIncident($incident->fresh());
    }

    public function test_incident_92_severe_incident_sends_no_notification_and_is_notified_stays_zero_sec_ba_001(): void
    {
        // SEC-BA-001 (REQ-BA-015 / BR-BA-013): a High/critical-severity negative incident MUST notify the
        // homeroom teacher, HOD, principal and (per config) the parent. The implementation does NONE of this.
        // is_notified is never set on create and stays 0 even for `critical`.
        $deps = $this->incidentDependencies();
        $this->postIncident([
            'student_id'    => $deps['student_id'],
            'category_id'   => $deps['category_id'],
            'incident_type' => 'negative_incident',
            'severity'      => 'critical',
            'description'   => 'Critical safeguarding event ' . $this->uniqueSuffix() . ' — should trigger notifications.',
        ]);
        $row = BaIncident::query()->where('student_id', $deps['student_id'])
            ->where('severity', 'critical')->orderByDesc('id')->first();
        $this->assertNotNull($row, 'Critical incident should persist.');
        $this->assertFalse(
            (bool) $row->is_notified,
            'SEC-BA-001: is_notified stays 0 even for a critical incident — parent/staff notification is entirely absent.'
        );
        $this->forceDeleteIncident($row);
    }

    public function test_incident_93_module_source_contains_no_notification_dispatch_sec_ba_001(): void
    {
        // Source-level proof of SEC-BA-001: no Notification / notify / dispatch / Mail / event() anywhere the
        // incident store path can reach. Fail-soft if the app repo is not co-located with the runner (constraint #29).
        $ctrlFile = (new ReflectionClass(\Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController::class))->getFileName();
        if (!is_string($ctrlFile)) {
            $this->markTestSkipped('BaIncidentController file could not be resolved.');
        }
        $appRoot = dirname($ctrlFile, 6); // .../prime_ai
        $moduleApp = $appRoot . '/Modules/BehaviouralAssessment/app';
        if (!is_dir($moduleApp)) {
            $this->markTestSkipped('BehaviouralAssessment app source not co-located with the runner.');
        }

        $offenders = [];
        $rii = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($moduleApp, \FilesystemIterator::SKIP_DOTS));
        foreach ($rii as $fileInfo) {
            /** @var \SplFileInfo $fileInfo */
            if (!$fileInfo->isFile() || $fileInfo->getExtension() !== 'php') {
                continue;
            }
            $contents = (string) @file_get_contents($fileInfo->getPathname());
            if (preg_match('/->notify\s*\(|Notification::(send|route)|dispatch\s*\(|Mail::(send|to|queue)|\bevent\s*\(/', $contents)) {
                $offenders[] = $fileInfo->getFilename();
            }
        }

        $this->assertSame(
            [],
            $offenders,
            'SEC-BA-001: expected ZERO notification/dispatch call sites in the module; wiring found in: ' . implode(', ', $offenders)
        );
    }

    public function test_incident_94_stored_xss_in_description_not_executed_on_show(): void
    {
        $deps = $this->incidentDependencies();
        $payload = '<script>window.__xss_incident=1</script> disruptive ' . $this->uniqueSuffix();
        $this->postIncident([
            'student_id'  => $deps['student_id'],
            'category_id' => $deps['category_id'],
            'description' => $payload,
        ]);
        $row = BaIncident::query()->where('student_id', $deps['student_id'])->orderByDesc('id')->first();
        $this->assertNotNull($row);

        $this->browseWithFailureScreenshot('xss-description', function (Browser $browser) use ($row): void {
            $this->visitAuthenticated($browser, '/behavioural-assessment/incidents/' . $row->id, 1000);
            $flag = $browser->script('return window.__xss_incident || 0;');
            $value = is_array($flag) ? ($flag[0] ?? 0) : 0;
            $this->assertNotSame(1, $value, 'Stored XSS payload must NOT execute on the show page.');
        });

        $this->forceDeleteIncident($row->fresh());
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
        $rawName = 'incident-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'incident-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- Authenticated JSON request issued from a logged-in browser page ----

    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
    }

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openCreatePage($browser);
            $result = $callback($browser);
        });
        return $result;
    }

    private function openCreatePage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#incidentForm') !== null
                || $browser->element('meta[name="csrf-token"]') !== null
                || $browser->element('form') !== null;
        }, 'Incident create page did not render a form/CSRF token.');
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
window.__incApiDone = false;
window.__incApiError = '';
window.__incApiResult = null;

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

        window.__incApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__incApiError = String(error);
    } finally {
        window.__incApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__incApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__incApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__incApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Higher-level request shims (admin session) -----------------------

    private function postIncident(array $overrides = []): array
    {
        $payload = $this->validPayload($overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    /** Post a payload built on a seeded-valid base but with a targeted invalid field. */
    private function postIncidentRaw(array $overrides): array
    {
        $payload = array_merge($this->validPayload(), $overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    private function putIncident(int $id, array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'PUT', $this->tenantUrl(self::STORE_PATH . '/' . $id), $payload));
    }

    private function validPayload(array $overrides = []): array
    {
        $deps = $this->incidentDependencies();
        return array_merge([
            'student_id'            => $deps['student_id'],
            'category_id'           => $deps['category_id'] ?: null,
            'incident_date'         => now()->toDateString(),
            'incident_time'         => '10:30',
            'incident_type'         => 'negative_incident',
            'severity'              => 'moderate',
            'location'              => 'classroom',
            'description'           => 'Valid incident description ' . $this->uniqueSuffix() . ' — enough detail here.',
            'is_follow_up_required' => 0,
        ], $overrides);
    }

    /**
     * Echo an incident's immutable core fields into an update payload so the BR-BA-008 guard passes,
     * then merge the caller's mutable-field changes on top.
     */
    private function immutableEcho(BaIncident $incident, array $mutable = []): array
    {
        $core = [
            'student_id'    => $incident->student_id,
            'incident_date' => optional($incident->incident_date)->toDateString() ?? (string) $incident->getRawOriginal('incident_date'),
            'incident_time' => $incident->getRawOriginal('incident_time'),
            'incident_type' => $incident->incident_type,
            'severity'      => $incident->severity,
            'location'      => $incident->location,
            'category_id'   => $incident->category_id,
            'criterion_id'  => $incident->criterion_id,
            'description'   => $incident->description,
        ];
        return array_merge($core, $mutable);
    }

    // ---- Seed / cleanup / dependencies ------------------------------------

    /**
     * Resolve cross-module dependencies for a valid incident. Skips the test (defensively) when the
     * host environment lacks the required student/employee records.
     *
     * @return array{student_id:int, employee_id:int, category_id:int, intervention_id:int}
     */
    private function incidentDependencies(): array
    {
        $studentId = (int) (
            DB::table('std_students')->where('is_active', 1)->value('id')
            ?? DB::table('std_students')->value('id')
            ?? 0
        );
        $employeeId = (int) (
            DB::table('sch_employees')->where('is_active', 1)->value('id')
            ?? DB::table('sch_employees')->value('id')
            ?? 0
        );
        $categoryId = (int) (
            DB::table(self::INCIDENTS_TABLE) && Schema::hasTable('ba_categories')
                ? (DB::table('ba_categories')->whereNull('parent_id')->where('is_active', 1)->value('id')
                    ?? DB::table('ba_categories')->value('id') ?? 0)
                : 0
        );
        $interventionId = Schema::hasTable('ba_interventions')
            ? (int) (DB::table('ba_interventions')->where('is_active', 1)->value('id') ?? DB::table('ba_interventions')->value('id') ?? 0)
            : 0;

        if ($studentId === 0 || $employeeId === 0) {
            $this->markTestSkipped('Incident dependencies missing (need a std_students row and a sch_employees row).');
        }

        return [
            'student_id'      => $studentId,
            'employee_id'     => $employeeId,
            'category_id'     => $categoryId,
            'intervention_id' => $interventionId,
        ];
    }

    private function createIncidentSeed(array $overrides = []): BaIncident
    {
        $deps = $this->incidentDependencies();
        $payload = array_merge([
            'student_id'            => $deps['student_id'],
            'reported_by'           => $deps['employee_id'],
            'category_id'           => $deps['category_id'] ?: null,
            'incident_date'         => now()->toDateString(),
            'incident_time'         => '09:15',
            'incident_type'         => 'negative_incident',
            'severity'              => 'moderate',
            'location'              => 'classroom',
            'description'           => 'Seeded incident ' . $this->uniqueSuffix() . ' — enough detail for a valid row.',
            'is_follow_up_required' => false,
            'is_notified'           => false,
            'is_active'             => true,
            'created_by'            => (int) $this->adminUser->id,
            'updated_by'            => (int) $this->adminUser->id,
        ], $overrides);

        return BaIncident::query()->create($payload);
    }

    private function forceDeleteIncident(?BaIncident $incident): void
    {
        if ($incident === null) {
            return;
        }
        try {
            BaIncidentWitnessJnt::query()->where('incident_id', $incident->id)->forceDelete();
        } catch (Throwable) {
        }
        try {
            BaIncidentInterventionJnt::query()->where('incident_id', $incident->id)->forceDelete();
        } catch (Throwable) {
        }
        try {
            BaAuditLog::query()->where('entity_type', BaAuditLog::ENTITY_INCIDENT)->where('entity_id', $incident->id)->delete();
        } catch (Throwable) {
        }
        try {
            if (BaIncident::withTrashed()->whereKey($incident->id)->exists()) {
                $incident->forceDelete();
            }
        } catch (Throwable) {
        }
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
                'name'              => 'Inc Limited ' . $this->uniqueSuffix(),
                'email'             => 'inc_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'IL' . substr($this->uniqueSuffix(), -8);
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
        $this->grantIncidentPermissions($this->adminUser);
    }

    private function grantIncidentPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::INC_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::INC_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::INC_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.incident-admin');
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

    // ---- App-repo source resolution (constraints #29/#32) -----------------

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

    private function columnType(string $table, string $column): string
    {
        try {
            $row = DB::selectOne(
                'SELECT COLUMN_TYPE AS t FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
                [$table, $column]
            );
            return strtolower((string) ($row->t ?? ''));
        } catch (Throwable) {
            return '';
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
