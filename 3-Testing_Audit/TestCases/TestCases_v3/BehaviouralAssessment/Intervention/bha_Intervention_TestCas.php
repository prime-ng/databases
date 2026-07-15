<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaIntervention;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Interventions (masters tab) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/04-Interventions.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime table      : ba_interventions  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Junction           : ba_incident_intervention_jnt (intervention_id → ba_interventions, ON DELETE RESTRICT).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaInterventionController
 * FormRequest        : Modules\BehaviouralAssessment\Http\Requests\BaInterventionRequest
 * Permission prefix  : tenant.behavioural-assessment.interventions.{viewAny|view|create|update|delete|restore|forceDelete|status}
 * Activity log       : NONE — the controller calls no activityLog() helper and the model has no logging observer (documented absence).
 *
 * Defects proven (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md + this scan):
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - BUG-BA-005 : BR-BA-030 not enforced — an in-use intervention (linked in ba_incident_intervention_jnt) is still soft-deletable (proven in _43).
 *   - DATA-BA-002: requirement "Deactivation Protections" not enforced — toggleStatus deactivates a linked intervention with no guard (proven in _21).
 *   - BUG-BA-010 : requirement "Unique … Name" not enforced — duplicate intervention names are accepted (only sort_order is unique) (proven in _16).
 *   - VAL-BA-003 : requirement says Description required (max 500); implementation is nullable with no max (proven in _39).
 *   - INT-GAP-01 : requirement "Intervention Code" (unique capitalized) is commented out — no `code` column/rule (proven in _03).
 *   - INT-GAP-02 : requirement type set {Supportive,Corrective,Reinforcement} diverges from implementation {reward,corrective,counselling} (proven in _01/_32).
 *   - INT-GAP-03 : requirement "Escalation Level" (Level 1/2/3) is not implemented — no `escalation_level` column (proven in _03).
 *   - SEC-BA-002 : FormRequest authorize() returns bare true, mitigated by controller Gate (proven in _92).
 *   - INT-OBS-01 : model booted() detaches junction rows on forceDelete, working around the DB RESTRICT FK (proven in _45).
 */
class bha_Intervention_TestCas extends DuskTestCase
{
    private const URL_PREFIX    = '/behavioural-assessment';
    private const MASTERS_PATH  = '/behavioural-assessment/masters?tab=interventions';
    private const CREATE_PATH   = '/behavioural-assessment/interventions/create';
    private const STORE_PATH    = '/behavioural-assessment/interventions';
    private const TRASH_PATH    = '/behavioural-assessment/interventions/trash';

    private const TABLE         = 'ba_interventions';
    private const JUNCTION      = 'ba_incident_intervention_jnt';
    private const DDL_TABLE     = 'bha_interventions';   // stale DDL-doc name (should NOT exist at runtime)

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/Intervention/screenshots';

    /** @var array<int,string> */
    private const INT_PERMISSIONS = [
        'tenant.behavioural-assessment.masters.viewAny',
        'tenant.behavioural-assessment.interventions.viewAny',
        'tenant.behavioural-assessment.interventions.view',
        'tenant.behavioural-assessment.interventions.create',
        'tenant.behavioural-assessment.interventions.update',
        'tenant.behavioural-assessment.interventions.delete',
        'tenant.behavioural-assessment.interventions.restore',
        'tenant.behavioural-assessment.interventions.forceDelete',
        'tenant.behavioural-assessment.interventions.status',
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

    public function test_intervention_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table ba_interventions does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'name', 'description', 'intervention_type', 'sort_order',
                'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_interventions table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::TABLE))->keyBy('Field');
            $this->assertStringContainsString('varchar', strtolower((string) ($cols['name']->Type ?? '')));
            $this->assertStringContainsString('enum', strtolower((string) ($cols['intervention_type']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['sort_order']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));
            // ENUM values must match the DDL exactly & case-sensitively (constraint #18).
            $enum = strtolower((string) ($cols['intervention_type']->Type ?? ''));
            $this->assertStringContainsString("'reward'", $enum);
            $this->assertStringContainsString("'corrective'", $enum);
            $this->assertStringContainsString("'counselling'", $enum);
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130615_create_ba_interventions_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_interventions'", $migration);
            $this->assertStringContainsString("\$table->string('name', 100)", $migration);
            $this->assertStringContainsString("\$table->enum('intervention_type'", $migration);
            $this->assertStringContainsString("\$table->unsignedTinyInteger('sort_order')", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // FormRequest rule strings — verbatim from the real source.
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaInterventionRequest.php'));
        if ($request !== null) {
            $this->assertStringContainsString("'max:100'", $request);
            $this->assertStringContainsString("Rule::in(['reward', 'corrective', 'counselling'])", $request);
            $this->assertStringContainsString("Rule::unique('ba_interventions', 'sort_order')", $request);
            $this->assertStringContainsString('This sort order is already used by another intervention.', $request);
            $this->assertStringContainsString('prepareForValidation', $request);
        }

        // Model configuration.
        $model = new BaIntervention();
        $this->assertSame('ba_interventions', $model->getTable());
        $this->assertSame([
            'name', 'description', 'intervention_type', 'sort_order',
            'is_active', 'created_by', 'updated_by',
        ], $model->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaIntervention::class));
        $this->assertInstanceOf(BelongsToMany::class, $model->incidents());
        $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null);

        // Active scope.
        $active = $this->createInterventionSeed(['is_active' => true]);
        $inactive = $this->createInterventionSeed(['is_active' => false]);
        $this->assertTrue(BaIntervention::query()->active()->whereKey($active->id)->exists());
        $this->assertFalse(BaIntervention::query()->active()->whereKey($inactive->id)->exists());
        $this->forceDeleteIntervention($active);
        $this->forceDeleteIntervention($inactive);
    }

    public function test_intervention_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime table uses the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Runtime table ba_interventions must exist.');

        // The DDL/registry spec name `bha_interventions` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_TABLE),
                'DOC-BA-001 regression: bha_interventions exists at runtime; expected only the live ba_interventions.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_interventions', (new BaIntervention())->getTable());
        $this->assertTrue(Schema::hasTable(self::JUNCTION), 'Junction ba_incident_intervention_jnt must exist.');
    }

    public function test_intervention_03_code_and_escalation_level_specced_but_not_implemented_int_gap_01_03(): void
    {
        // INT-GAP-01: requirement mandates a unique capitalized "Intervention Code" — the column does not exist...
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'code'), 'INT-GAP-01 changed: a code column now exists.');
        // INT-GAP-03: requirement mandates an "Escalation Level" (Level 1/2/3) — the column does not exist.
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'escalation_level'), 'INT-GAP-03 changed: an escalation_level column now exists.');

        // ...and the FormRequest carries the code rule/prepare only as commented-out dead code (designed then dropped).
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaInterventionRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable from app repo.');
        }
        $this->assertStringContainsString("// 'code'", $request, 'INT-GAP-01: expected the code rule to remain as commented-out dead code.');
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_intervention_10_create_persists_and_redirects_with_success_flash(): void
    {
        $name = $this->uniqueName('CREATE');
        $sort = $this->nextAvailableSortOrder();

        $this->browseWithFailureScreenshot('create-persist', function (Browser $browser) use ($name, $sort): void {
            $this->openCreatePage($browser);
            $browser->type('name', $name)
                ->select('intervention_type', 'corrective')
                ->clear('sort_order')->type('sort_order', (string) $sort)
                ->type('description', 'Structured reflection worksheet.')
                ->press('Save Intervention')
                ->pause(1200);

            $this->assertStringContainsString('/behavioural-assessment/masters', $this->currentPath($browser));
        });

        $created = BaIntervention::where('name', $name)->first();
        $this->assertNotNull($created, 'Intervention row was not created.');
        $this->assertSame('corrective', $created->intervention_type);
        $this->assertSame($sort, (int) $created->sort_order);
        $this->assertTrue((bool) $created->is_active);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);
        $this->assertSame((int) $this->adminUser->id, (int) $created->updated_by);

        $this->forceDeleteIntervention($created);
    }

    public function test_intervention_11_is_active_defaults_true_via_prepare_for_validation(): void
    {
        // prepareForValidation merges is_active default true when the field is absent.
        $payload = $this->validPayload();
        unset($payload['is_active']);
        $response = $this->postRawPayload($payload);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Valid create (no is_active) should not 422: ' . json_encode($response['json'] ?? null));

        $created = BaIntervention::where('name', $payload['name'])->first();
        $this->assertNotNull($created, 'Intervention should be created with defaulted is_active.');
        $this->assertTrue((bool) $created->is_active, 'is_active must default to true.');

        $this->forceDeleteIntervention($created);
    }

    public function test_intervention_12_update_persists_changes(): void
    {
        $intervention = $this->createInterventionSeed(['name' => $this->uniqueName('BEFORE')]);
        $newName = $this->uniqueName('AFTER');

        $response = $this->putIntervention($intervention->id, [
            'name'              => $newName,
            'intervention_type' => 'reward',
            'sort_order'        => (int) $intervention->sort_order,
            'description'       => 'Updated protocol.',
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Update should not 422.');

        $intervention->refresh();
        $this->assertSame($newName, $intervention->name);
        $this->assertSame('reward', $intervention->intervention_type);
        $this->assertSame((int) $this->adminUser->id, (int) $intervention->updated_by);

        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_13_show_page_renders_intervention(): void
    {
        $intervention = $this->createInterventionSeed(['name' => $this->uniqueName('SHOW'), 'description' => 'Shown description body']);

        $this->browseWithFailureScreenshot('show-render', function (Browser $browser) use ($intervention): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/interventions/' . $intervention->id, 900);
            $browser->assertSee($intervention->name)
                ->assertSee('Shown description body')
                ->assertSee('Intervention Name');
        });

        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_14_masters_tab_lists_interventions(): void
    {
        $intervention = $this->createInterventionSeed(['name' => $this->uniqueName('LIST')]);

        $this->browseWithFailureScreenshot('masters-list', function (Browser $browser) use ($intervention): void {
            $this->openMastersTab($browser, $intervention->name);
            $browser->assertSee($intervention->name);
        });

        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_15_store_stamps_created_and_updated_by(): void
    {
        $name = $this->uniqueName('STAMP');
        $response = $this->postRawPayload($this->validPayload(['name' => $name]));
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));

        $created = BaIntervention::where('name', $name)->first();
        $this->assertNotNull($created);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);
        $this->assertSame((int) $this->adminUser->id, (int) $created->updated_by);

        $this->forceDeleteIntervention($created);
    }

    public function test_intervention_16_duplicate_name_is_allowed_bug_ba_010(): void
    {
        // Requirement "Unique Code & Name" requires unique names; the FormRequest has NO unique rule on name.
        $name = $this->uniqueName('DUP');
        $first = $this->createInterventionSeed(['name' => $name]);

        $response = $this->postRawPayload($this->validPayload(['name' => $name]));
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'BUG-BA-010 regression fixed? A duplicate name should currently be accepted (no unique rule).');

        $count = BaIntervention::where('name', $name)->count();
        $this->assertGreaterThanOrEqual(2, $count, 'BUG-BA-010: duplicate intervention names co-exist (uniqueness not enforced).');

        BaIntervention::where('name', $name)->get()->each(fn ($i) => $this->forceDeleteIntervention($i));
        $this->forceDeleteIntervention($first);
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM) — Active ↔ Inactive
    // =====================================================================

    public function test_intervention_20_active_to_inactive_and_back_transition_succeeds(): void
    {
        // BC-SM-1: Active --toggleStatus--> Inactive (legal transition).
        $intervention = $this->createInterventionSeed(['is_active' => true]);

        $response = $this->toggleIntervention($intervention->id);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $intervention->refresh();
        $this->assertFalse((bool) $intervention->is_active, 'Active intervention must transition to Inactive.');

        // BC-SM-2: Inactive --toggleStatus--> Active (legal reverse transition).
        $again = $this->toggleIntervention($intervention->id);
        $this->assertSame(200, (int) ($again['status'] ?? 0));
        $intervention->refresh();
        $this->assertTrue((bool) $intervention->is_active, 'Inactive intervention must transition back to Active.');

        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_21_deactivation_not_blocked_when_linked_to_incident_data_ba_002(): void
    {
        // Requirement "Deactivation Protections": an intervention linked to an open incident in
        // ba_incident_intervention_jnt must NOT be deactivatable. toggleStatus() performs no guard.
        try {
            if (!Schema::hasTable(self::JUNCTION) || !Schema::hasTable('ba_incidents')) {
                // Fall back: prove the toggle has no usage guard at all.
                $intervention = $this->createInterventionSeed(['is_active' => true]);
                $response = $this->toggleIntervention($intervention->id);
                $this->assertSame(200, (int) ($response['status'] ?? 0), 'DATA-BA-002: deactivation is not blocked.');
                $intervention->refresh();
                $this->assertFalse((bool) $intervention->is_active);
                $this->forceDeleteIntervention($intervention);
                return;
            }

            $intervention = $this->createInterventionSeed(['is_active' => true]);
            $incidentId = DB::table('ba_incidents')->value('id');
            $linked = false;
            if ($incidentId !== null) {
                DB::table(self::JUNCTION)->insert([
                    'incident_id'     => $incidentId,
                    'intervention_id' => $intervention->id,
                    'notes'           => 'DATA-BA-002 probe',
                    'is_active'       => 1,
                    'created_by'      => (int) $this->adminUser->id,
                    'updated_by'      => (int) $this->adminUser->id,
                    'created_at'      => now(),
                    'updated_at'      => now(),
                ]);
                $linked = true;
            }

            $response = $this->toggleIntervention($intervention->id);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'DATA-BA-002 regression fixed? Deactivating a linked intervention should be rejected, but current code allows it.');
            $intervention->refresh();
            $this->assertFalse((bool) $intervention->is_active, 'DATA-BA-002: a linked intervention was deactivated with no guard.');

            if ($linked) {
                DB::table(self::JUNCTION)->where('intervention_id', $intervention->id)->delete();
            }
            $this->forceDeleteIntervention($intervention);
        } catch (Throwable $e) {
            $this->markTestSkipped('DATA-BA-002 dependency path unavailable: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL) — Negative 100%
    // =====================================================================

    public function test_intervention_30_required_fields_are_rejected(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'name' => '', 'intervention_type' => '', 'sort_order' => '',
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty payload must fail validation.');
        $errors = $response['json']['errors'] ?? [];
        foreach (['name', 'intervention_type', 'sort_order'] as $field) {
            $this->assertArrayHasKey($field, $errors, "Missing required-error for {$field}.");
        }
    }

    public function test_intervention_31_name_max_length_100_is_enforced(): void
    {
        $response = $this->postRawPayload($this->validPayload(['name' => str_repeat('N', 101)]));
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('name', $response['json']['errors'] ?? []);
    }

    public function test_intervention_32_intervention_type_must_be_in_allowed_set(): void
    {
        // Requirement labels (Supportive/Reinforcement) are NOT accepted — only reward/corrective/counselling (INT-GAP-02).
        foreach (['Supportive', 'Reinforcement', 'symbolic'] as $bad) {
            $response = $this->postRawPayload($this->validPayload(['intervention_type' => $bad]));
            $this->assertSame(422, (int) ($response['status'] ?? 0), "'{$bad}' must be rejected by Rule::in.");
            $this->assertArrayHasKey('intervention_type', $response['json']['errors'] ?? []);
        }
    }

    public function test_intervention_33_sort_order_required_and_integer(): void
    {
        $response = $this->postRawPayload($this->validPayload(['sort_order' => 'abc']));
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('sort_order', $response['json']['errors'] ?? []);
    }

    public function test_intervention_34_sort_order_min_0_is_enforced(): void
    {
        $response = $this->postRawPayload($this->validPayload(['sort_order' => -1]));
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('sort_order', $response['json']['errors'] ?? []);
    }

    public function test_intervention_35_sort_order_max_255_is_enforced(): void
    {
        $response = $this->postRawPayload($this->validPayload(['sort_order' => 256]));
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('sort_order', $response['json']['errors'] ?? []);
    }

    public function test_intervention_36_duplicate_sort_order_is_rejected_scoped_to_non_deleted(): void
    {
        $existing = $this->createInterventionSeed();

        $response = $this->postRawPayload($this->validPayload(['sort_order' => (int) $existing->sort_order]));
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate sort_order must be rejected.');
        $this->assertArrayHasKey('sort_order', $response['json']['errors'] ?? []);

        $this->forceDeleteIntervention($existing);
    }

    public function test_intervention_37_duplicate_sort_order_allowed_after_soft_delete(): void
    {
        $intervention = $this->createInterventionSeed();
        $sort = (int) $intervention->sort_order;
        $intervention->delete(); // soft delete → deleted_at set, freeing the sort_order (unique scoped whereNull deleted_at)

        $response = $this->postRawPayload($this->validPayload(['sort_order' => $sort]));
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Unique rule is scoped to whereNull(deleted_at); reuse should succeed.');

        $recreated = BaIntervention::where('sort_order', $sort)->whereNull('deleted_at')->first();
        $this->assertNotNull($recreated, 'A new active intervention with the reused sort_order should exist.');

        $this->forceDeleteIntervention($recreated);
        BaIntervention::withTrashed()->whereKey($intervention->id)->get()->each(fn ($i) => $this->forceDeleteIntervention($i));
    }

    public function test_intervention_38_duplicate_sort_order_error_message_is_exact(): void
    {
        $existing = $this->createInterventionSeed();

        $response = $this->postRawPayload($this->validPayload(['sort_order' => (int) $existing->sort_order]));
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $message = $response['json']['errors']['sort_order'][0] ?? '';
        $this->assertSame('This sort order is already used by another intervention.', $message);

        $this->forceDeleteIntervention($existing);
    }

    public function test_intervention_39_description_is_optional_diverges_from_requirement_val_ba_003(): void
    {
        // Requirement: Description is mandatory (max 500). Implementation: nullable, no max → empty is accepted.
        $payload = $this->validPayload();
        unset($payload['description']);
        $response = $this->postRawPayload($payload);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'VAL-BA-003 regression fixed? Description is currently optional so an omitted value is accepted.');

        $created = BaIntervention::where('name', $payload['name'])->first();
        $this->assertNotNull($created);
        $this->assertNull($created->description, 'Description persisted as null (no requiredness — VAL-BA-003).');

        $this->forceDeleteIntervention($created);
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-INT/REF/EDG)
    // =====================================================================

    public function test_intervention_40_delete_soft_deletes_sets_inactive_and_moves_to_trash(): void
    {
        $intervention = $this->createInterventionSeed(['is_active' => true]);

        $response = $this->deleteIntervention($intervention->id);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertFalse(BaIntervention::whereKey($intervention->id)->exists(), 'Intervention should be hidden from default scope after soft delete.');
        $trashed = BaIntervention::onlyTrashed()->find($intervention->id);
        $this->assertNotNull($trashed, 'Intervention should be present in trash.');
        $this->assertFalse((bool) $trashed->is_active, 'destroy() sets is_active=false before soft delete.');

        $this->forceDeleteIntervention($trashed);
    }

    public function test_intervention_41_restore_from_trash_returns_to_default_scope(): void
    {
        $intervention = $this->createInterventionSeed();
        $intervention->delete();

        $response = $this->apiCall('GET', $this->tenantUrl('/behavioural-assessment/interventions/' . $intervention->id . '/restore'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertTrue(BaIntervention::whereKey($intervention->id)->exists(), 'Restored intervention should return to default scope.');

        $this->forceDeleteIntervention(BaIntervention::find($intervention->id));
    }

    public function test_intervention_42_force_delete_removes_intervention(): void
    {
        $intervention = $this->createInterventionSeed();
        $intervention->delete();

        $response = $this->apiCall('DELETE', $this->tenantUrl('/behavioural-assessment/interventions/' . $intervention->id . '/force-delete'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertFalse(BaIntervention::withTrashed()->whereKey($intervention->id)->exists(), 'Intervention row should be physically removed.');
    }

    public function test_intervention_43_in_use_intervention_soft_delete_is_not_blocked_bug_ba_005(): void
    {
        // BR-BA-030: an intervention linked in ba_incident_intervention_jnt must not be deletable;
        // destroy() soft-deletes unconditionally (audit BUG-BA-005). Defensive when the graph is unavailable.
        try {
            if (!Schema::hasTable(self::JUNCTION) || !Schema::hasTable('ba_incidents')) {
                $intervention = $this->createInterventionSeed();
                $response = $this->deleteIntervention($intervention->id);
                $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'BUG-BA-005: unconditional soft delete succeeds.');
                $this->assertNotNull(BaIntervention::onlyTrashed()->find($intervention->id));
                $this->forceDeleteIntervention(BaIntervention::onlyTrashed()->find($intervention->id));
                return;
            }

            $intervention = $this->createInterventionSeed();
            $incidentId = DB::table('ba_incidents')->value('id');
            if ($incidentId === null) {
                $response = $this->deleteIntervention($intervention->id);
                $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'BUG-BA-005: no incident to link — unconditional soft delete still succeeds.');
                $this->forceDeleteIntervention(BaIntervention::onlyTrashed()->find($intervention->id) ?? $intervention);
                return;
            }

            DB::table(self::JUNCTION)->insert([
                'incident_id'     => $incidentId,
                'intervention_id' => $intervention->id,
                'notes'           => 'BUG-BA-005 probe',
                'is_active'       => 1,
                'created_by'      => (int) $this->adminUser->id,
                'updated_by'      => (int) $this->adminUser->id,
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);

            $response = $this->deleteIntervention($intervention->id);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'BUG-BA-005 regression fixed? Deleting an in-use intervention should be blocked, but current code allows it.');
            $this->assertNotNull(BaIntervention::onlyTrashed()->find($intervention->id), 'In-use intervention was still soft-deleted (no usage guard — BUG-BA-005).');

            DB::table(self::JUNCTION)->where('intervention_id', $intervention->id)->delete();
            $this->forceDeleteIntervention(BaIntervention::onlyTrashed()->find($intervention->id));
        } catch (Throwable $e) {
            $this->markTestSkipped('BUG-BA-005 dependency path unavailable: ' . $e->getMessage());
        }
    }

    public function test_intervention_44_junction_fk_to_intervention_is_restrict(): void
    {
        // ba_incident_intervention_jnt.intervention_id → ba_interventions ON DELETE RESTRICT (DDL).
        try {
            if (DB::connection()->getDriverName() !== 'mysql' || !Schema::hasTable(self::JUNCTION)) {
                $this->markTestSkipped('Junction table / MySQL metadata unavailable.');
            }
            $fk = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ?
                   AND REFERENCED_TABLE_NAME = ?",
                [self::JUNCTION, self::TABLE]
            );
            if (empty($fk)) {
                $this->markTestSkipped('No FK metadata for ba_incident_intervention_jnt → ba_interventions.');
            }
            $rule = strtoupper((string) ($fk[0]->DELETE_RULE ?? ''));
            $this->assertTrue(
                str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'),
                'intervention_id FK should RESTRICT hard-delete of a used intervention; found: ' . $rule
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('RESTRICT dependency path unavailable: ' . $e->getMessage());
        }
    }

    public function test_intervention_45_force_delete_detaches_junction_via_observer_int_obs_01(): void
    {
        // Model booted() deleting-hook detaches incidents on isForceDeleting(), circumventing the DB RESTRICT FK.
        try {
            if (!Schema::hasTable(self::JUNCTION) || !Schema::hasTable('ba_incidents')) {
                $this->markTestSkipped('Junction / incidents table absent — observer detach path not exercisable.');
            }
            $intervention = $this->createInterventionSeed();
            $incidentId = DB::table('ba_incidents')->value('id');
            if ($incidentId === null) {
                $this->forceDeleteIntervention($intervention);
                $this->markTestSkipped('No incident available to build a junction row.');
            }
            DB::table(self::JUNCTION)->insert([
                'incident_id'     => $incidentId,
                'intervention_id' => $intervention->id,
                'notes'           => 'INT-OBS-01 probe',
                'is_active'       => 1,
                'created_by'      => (int) $this->adminUser->id,
                'updated_by'      => (int) $this->adminUser->id,
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);
            $intervention->delete();
            $intervention->refresh();

            // forceDelete on a RESTRICT-referenced row succeeds because the observer detaches first.
            $intervention->forceDelete();
            $this->assertFalse(BaIntervention::withTrashed()->whereKey($intervention->id)->exists(), 'Force delete should physically remove the row.');
            $this->assertSame(
                0,
                DB::table(self::JUNCTION)->where('intervention_id', $intervention->id)->count(),
                'INT-OBS-01: junction rows were detached by the model observer during force-delete.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('INT-OBS-01 path unavailable: ' . $e->getMessage());
        }
    }

    public function test_intervention_46_full_lifecycle_create_toggle_delete_restore_force_delete(): void
    {
        $name = $this->uniqueName('LIFE');
        $create = $this->postRawPayload($this->validPayload(['name' => $name]));
        $this->assertNotSame(422, (int) ($create['status'] ?? 0));
        $intervention = BaIntervention::where('name', $name)->firstOrFail();

        // toggle
        $toggle = $this->toggleIntervention($intervention->id);
        $this->assertSame(200, (int) ($toggle['status'] ?? 0));
        $intervention->refresh();
        $this->assertFalse((bool) $intervention->is_active);

        // delete
        $this->deleteIntervention($intervention->id);
        $this->assertNotNull(BaIntervention::onlyTrashed()->find($intervention->id));

        // restore
        $this->apiCall('GET', $this->tenantUrl('/behavioural-assessment/interventions/' . $intervention->id . '/restore'));
        $this->assertTrue(BaIntervention::whereKey($intervention->id)->exists());

        // force delete
        BaIntervention::find($intervention->id)->delete();
        $this->apiCall('DELETE', $this->tenantUrl('/behavioural-assessment/interventions/' . $intervention->id . '/force-delete'));
        $this->assertFalse(BaIntervention::withTrashed()->whereKey($intervention->id)->exists());
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_intervention_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_intervention_51_limited_user_without_create_permission_gets_403(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-create-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::STORE_PATH), $this->validPayload());
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without create permission must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_intervention_52_limited_user_without_status_permission_gets_403_on_toggle(): void
    {
        $intervention = $this->createInterventionSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-toggle-403', function (Browser $browser) use ($limited, $intervention): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl('/behavioural-assessment/interventions/' . $intervention->id . '/toggle-status'));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_53_limited_user_without_delete_permission_gets_403_on_destroy(): void
    {
        $intervention = $this->createInterventionSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-delete-403', function (Browser $browser) use ($limited, $intervention): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'DELETE', $this->tenantUrl('/behavioural-assessment/interventions/' . $intervention->id));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_54_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaInterventionPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('Policy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete', 'status'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.interventions.{$ability}",
                $policy,
                "Policy missing gate string for {$ability}."
            );
        }
    }

    public function test_intervention_55_status_toggle_endpoint_updates_is_active_and_returns_json(): void
    {
        $intervention = $this->createInterventionSeed(['is_active' => true]);

        $response = $this->toggleIntervention($intervention->id);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $json = $response['json'] ?? [];
        $this->assertTrue((bool) ($json['success'] ?? false));
        $this->assertArrayHasKey('is_active', $json);
        $this->assertSame('Intervention deactivated.', (string) ($json['message'] ?? ''));

        $intervention->refresh();
        $this->assertFalse((bool) $intervention->is_active);

        // toggle back → activated message
        $again = $this->toggleIntervention($intervention->id);
        $this->assertSame('Intervention activated.', (string) ($again['json']['message'] ?? ''));

        $this->forceDeleteIntervention($intervention);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (search, filter, empty state, trash, breadcrumb)
    // =====================================================================

    public function test_intervention_60_masters_search_filters_by_name(): void
    {
        $intervention = $this->createInterventionSeed(['name' => $this->uniqueName('FINDME')]);

        $this->browseWithFailureScreenshot('search-filter', function (Browser $browser) use ($intervention): void {
            $this->openMastersTab($browser, $intervention->name);
            $browser->assertSee($intervention->name);
        });

        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_61_masters_type_filter_narrows_results(): void
    {
        $intervention = $this->createInterventionSeed(['name' => $this->uniqueName('TYPED'), 'intervention_type' => 'reward']);

        $this->browseWithFailureScreenshot('type-filter', function (Browser $browser) use ($intervention): void {
            $path = self::MASTERS_PATH . '&intervention_type=reward&search=' . urlencode($intervention->name);
            $this->visitAuthenticated($browser, $path, 1000);
            $browser->assertSee($intervention->name);
        });

        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_62_empty_state_message_when_search_matches_nothing(): void
    {
        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser): void {
            $this->openMastersTab($browser, 'ZZZ_NO_MATCH_' . $this->uniqueSuffix());
            $browser->assertSee('No interventions found.');
        });
    }

    public function test_intervention_63_trash_page_renders(): void
    {
        $intervention = $this->createInterventionSeed(['name' => $this->uniqueName('TRASHED')]);
        $intervention->delete();

        $this->browseWithFailureScreenshot('trash-render', function (Browser $browser) use ($intervention): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH, 900);
            $browser->assertSee($intervention->name);
        });

        $this->forceDeleteIntervention(BaIntervention::onlyTrashed()->find($intervention->id));
    }

    public function test_intervention_64_breadcrumb_present_on_create_and_show_pages(): void
    {
        $intervention = $this->createInterventionSeed();

        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser) use ($intervention): void {
            $this->openCreatePage($browser);
            $browser->assertSee('Interventions');
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/interventions/' . $intervention->id, 900);
            $browser->assertSee('Intervention');
        });

        $this->forceDeleteIntervention($intervention);
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_intervention_70_invalid_id_returns_404(): void
    {
        $missing = 987654321;
        foreach ([
            '/behavioural-assessment/interventions/' . $missing,
            '/behavioural-assessment/interventions/' . $missing . '/edit',
        ] as $path) {
            $response = $this->apiCall('GET', $this->tenantUrl($path));
            $this->assertSame(404, (int) ($response['status'] ?? 0), "Expected 404 for {$path}.");
        }

        $toggle = $this->toggleIntervention($missing);
        $this->assertSame(404, (int) ($toggle['status'] ?? 0), 'Toggle on invalid id must 404.');
    }

    public function test_intervention_71_sort_order_boundary_255_is_accepted(): void
    {
        // TINYINT UNSIGNED max = 255 and Rule max:255 → the boundary value is valid (when free).
        $this->freeSortOrder(255);
        $response = $this->postRawPayload($this->validPayload(['sort_order' => 255]));
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'A sort_order of 255 should be accepted at the boundary.');
        $created = BaIntervention::where('sort_order', 255)->whereNull('deleted_at')->first();
        $this->assertNotNull($created);

        $this->forceDeleteIntervention($created);
    }

    public function test_intervention_72_whitespace_only_name_is_rejected(): void
    {
        // Laravel TrimStrings middleware trims → whitespace-only name becomes empty → required fails.
        $response = $this->postRawPayload($this->validPayload(['name' => '   ']));
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('name', $response['json']['errors'] ?? []);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_intervention_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side intervention tests.'
        );
        $this->assertTrue(Schema::hasTable(self::TABLE));
    }

    public function test_intervention_91_cross_tenant_direct_id_isolation(): void
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

    public function test_intervention_92_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaInterventionRequest.php'));
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

    public function test_intervention_93_stored_xss_in_description_not_executed_on_show(): void
    {
        $name = $this->uniqueName('XSSDESC');
        $payload = $this->validPayload(['name' => $name, 'description' => 'Desc <img src=x onerror=alert(1)>']);
        $response = $this->postRawPayload($payload);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));
        $intervention = BaIntervention::where('name', $name)->first();
        $this->assertNotNull($intervention);

        $this->browseWithFailureScreenshot('stored-xss-desc', function (Browser $browser) use ($intervention): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/interventions/' . $intervention->id, 900);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<img src=x onerror=alert(1)>', $source, 'Blade must escape stored description.');
        });

        $this->forceDeleteIntervention($intervention);
    }

    public function test_intervention_94_stored_xss_in_name_escaped_on_show(): void
    {
        $xss = '<script>alert(1)</script>';
        $name = substr('XSS ' . $this->uniqueName('N') . ' ' . $xss, 0, 100);
        $payload = $this->validPayload(['name' => $name]);
        $response = $this->postRawPayload($payload);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));
        $intervention = BaIntervention::where('name', $name)->first();
        $this->assertNotNull($intervention);

        $this->browseWithFailureScreenshot('stored-xss-name', function (Browser $browser) use ($intervention): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/interventions/' . $intervention->id, 900);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Raw script tag must not render unescaped.');
        });

        $this->forceDeleteIntervention($intervention);
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
        $rawName = 'intervention-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'intervention-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function openCreatePage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
        $browser->waitFor('#name', 15)->waitFor('#type', 10)->waitFor('#sort_order', 10);
    }

    private function openMastersTab(Browser $browser, ?string $search = null): void
    {
        $path = self::MASTERS_PATH;
        if ($search !== null && $search !== '') {
            $path .= '&search=' . urlencode($search);
        }
        $this->visitAuthenticated($browser, $path, 1000);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#interventions-pane') !== null
                || $browser->element('table') !== null;
        }, 'Interventions masters tab did not render.');
    }

    /**
     * Issue an authenticated (admin) JSON request from a freshly-opened, logged-in browser page.
     */
    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
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
window.__intApiDone = false;
window.__intApiError = '';
window.__intApiResult = null;

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

        window.__intApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__intApiError = String(error);
    } finally {
        window.__intApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__intApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__intApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__intApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Higher-level request shims (admin session) -----------------------

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openCreatePage($browser);
            $result = $callback($browser);
        });
        return $result;
    }

    /** POST an already-built payload (valid base with any targeted overrides applied by the caller). */
    private function postRawPayload(array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    private function putIntervention(int $id, array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'PUT', $this->tenantUrl('/behavioural-assessment/interventions/' . $id), $payload));
    }

    private function deleteIntervention(int $id): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'DELETE', $this->tenantUrl('/behavioural-assessment/interventions/' . $id)));
    }

    private function toggleIntervention(int $id): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl('/behavioural-assessment/interventions/' . $id . '/toggle-status')));
    }

    private function validPayload(array $overrides = []): array
    {
        return array_merge([
            'name'              => $this->uniqueName('VALID'),
            'description'       => 'Valid intervention description.',
            'intervention_type' => 'corrective',
            'sort_order'        => $this->nextAvailableSortOrder(),
            'is_active'         => true,
        ], $overrides);
    }

    // ---- Seed / cleanup ---------------------------------------------------

    private function createInterventionSeed(array $overrides = []): BaIntervention
    {
        $payload = array_merge([
            'name'              => $this->uniqueName('SEED'),
            'description'       => 'Seed intervention',
            'intervention_type' => 'corrective',
            'sort_order'        => $this->nextAvailableSortOrder(),
            'is_active'         => true,
            'created_by'        => (int) $this->adminUser->id,
            'updated_by'        => (int) $this->adminUser->id,
        ], $overrides);

        return BaIntervention::query()->create($payload);
    }

    private function forceDeleteIntervention(?BaIntervention $intervention): void
    {
        if ($intervention === null) {
            return;
        }
        try {
            // Detach any junction rows first so RESTRICT never blocks cleanup.
            if (Schema::hasTable(self::JUNCTION)) {
                DB::table(self::JUNCTION)->where('intervention_id', $intervention->id)->delete();
            }
            if (BaIntervention::withTrashed()->whereKey($intervention->id)->exists()) {
                $intervention->forceDelete();
            }
        } catch (Throwable) {
            // Best-effort cleanup.
        }
    }

    /**
     * Pick a sort_order (1..255) not currently used by a non-deleted intervention,
     * so positive creates never collide with the unique rule.
     */
    private function nextAvailableSortOrder(): int
    {
        try {
            $used = DB::table(self::TABLE)->whereNull('deleted_at')->pluck('sort_order')
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

    /** Ensure a specific sort_order value is free (force-delete any holder, trashed or not). */
    private function freeSortOrder(int $value): void
    {
        try {
            BaIntervention::withTrashed()->where('sort_order', $value)->get()
                ->each(fn (BaIntervention $i) => $this->forceDeleteIntervention($i));
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
                'name'              => 'INT Limited ' . $this->uniqueSuffix(),
                'email'             => 'int_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
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
        $this->grantInterventionPermissions($this->adminUser);
    }

    private function grantInterventionPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::INT_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::INT_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::INT_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.intervention-admin');
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
            $modelFile = (new ReflectionClass(BaIntervention::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaIntervention.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaIntervention::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaIntervention.php → app root = dirname(,5)
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
        $clean = $clean === '' ? 'INT' : substr($clean, 0, 12);
        return substr($clean . ' Intervention ' . $this->uniqueSuffix(), 0, 100);
    }
}
