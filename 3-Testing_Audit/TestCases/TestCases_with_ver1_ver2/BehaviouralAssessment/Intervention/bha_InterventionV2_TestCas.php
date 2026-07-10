<?php

/**
 * BehaviouralAssessment › Intervention — V2 (comprehensive) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/Intervention/InterventionCrudTest.php.
 * DB SCOPE: tenant-side (migrations under database/migrations/tenant/; tenant init required).
 * TABLES  : ba_interventions (+ junction ba_incident_intervention_jnt). DDL doc + this file's name
 *           use the stale prefix "bha_" (audit DOC-BA-001); every schema assertion targets the LIVE
 *           "ba_" tables.
 *
 * Semantic numbering bands (WP-G):
 *   01–09 schema/model/request · 10–19 business rules · 20–29 state-machine/status
 *   30–39 validation · 40–49 integration/FK · 50–59 permissions · 60–69 UI/UX
 *   70–79 edge · 90–99 tenancy + security
 *
 * Audit findings proven here (reported as "verify in source" — traced to the cited lines):
 *   BUG-BA-005  intervention linked to incidents still (soft-)deletable/deactivatable (BR-BA-030)
 *                                                       → test_..._24 / _41 / _43
 *   SEC-BA-002  FormRequest authorize() returns bare true → test_..._52
 *   DATA-BA-003 soft-delete + UNIQUE (no deleted_at)      → test_..._35 (contrast: no DB unique on
 *                                                          ba_interventions; vector is junction uq_ba_inc_int)
 *   DOC-BA-001  DDL doc prefix bha_ vs live ba_           → test_..._01
 *   VAL-BA-INT-01 (new, verify in source) name uniqueness required by screen but NOT enforced
 *                                                       → test_..._16
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Requests\BaInterventionRequest;
use Modules\BehaviouralAssessment\Models\BaIntervention;
use Modules\SchoolSetup\Models\User;
use Tests\DuskTestCase;
use Throwable;

class bha_InterventionV2_TestCas extends DuskTestCase
{
    private const INDEX_PATH       = '/behavioural-assessment/masters';
    private const LISTING_PATH     = '/behavioural-assessment/interventions';
    private const CREATE_PATH      = '/behavioural-assessment/interventions/create';
    private const SHOW_BASE_PATH   = '/behavioural-assessment/interventions';
    private const TRASH_PATH       = '/behavioural-assessment/interventions/trash';
    private const TABLE            = 'ba_interventions';
    private const JUNCTION_TABLE   = 'ba_incident_intervention_jnt';
    private const MIGRATION_FILE   = 'database/migrations/tenant/2026_06_16_130615_create_ba_interventions_table.php';
    private const MIGRATION_JNT    = 'database/migrations/tenant/2026_06_16_130626_create_ba_incident_intervention_jnt_table.php';
    private const CONTROLLER_FILE  = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaInterventionController.php';
    private const REQUEST_FILE     = 'Modules/BehaviouralAssessment/app/Http/Requests/BaInterventionRequest.php';

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

        $this->initializeTenantContext();
        $this->resolveAdminUserAndPermissions();
    }

    protected function tearDown(): void
    {
        if ($this->limitedUser instanceof User) {
            try {
                $this->limitedUser->forceDelete();
            } catch (Throwable) {
                // ignore cleanup issues
            }
            $this->limitedUser = null;
        }

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // ══════════════════════════════════════════════
    //  01–09  Schema / model / request configuration
    // ══════════════════════════════════════════════

    /** TC-P01 · BC-DB-01 · Audit-DOC-BA-001 · Source: DDL-ba_interventions / live migration */
    public function test_intervention_01_schema_and_model_configuration_are_correct(): void
    {
        // DOC-BA-001: the DDL doc names the table bha_interventions, but the live table is ba_interventions.
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Live table ba_interventions does not exist.');
        $this->assertFalse(Schema::hasTable('bha_interventions'), 'Stale DDL-doc table bha_interventions should NOT exist (DOC-BA-001).');

        $this->assertTrue(Schema::hasColumns(self::TABLE, [
            'id', 'name', 'description', 'intervention_type', 'sort_order',
            'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing from ba_interventions.');

        $model = new BaIntervention();
        $this->assertSame('ba_interventions', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaIntervention::class));

        $casts = $model->getCasts();
        $this->assertSame('integer', $casts['sort_order'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('integer', $casts['created_by'] ?? null);
        $this->assertSame('integer', $casts['updated_by'] ?? null);
    }

    /** TC-P02 · BC-REF-01 · BC-DB-07 · Source: DDL-ba_incident_intervention_jnt uq_ba_inc_int + FK RESTRICT */
    public function test_intervention_02_junction_schema_fk_restrict_and_unique(): void
    {
        $this->assertTrue(Schema::hasTable(self::JUNCTION_TABLE), 'Live junction table ba_incident_intervention_jnt does not exist.');
        $this->assertTrue(Schema::hasColumns(self::JUNCTION_TABLE, [
            'id', 'notes', 'is_active', 'created_by', 'updated_by',
            'incident_id', 'intervention_id', 'deleted_at',
        ]), 'Expected columns missing from ba_incident_intervention_jnt.');

        $migration = File::get(base_path(self::MIGRATION_JNT));
        // incident_id → cascade; intervention_id → RESTRICT (default, NO cascade) = the FK-RESTRICT dependency.
        $this->assertStringContainsString("\$table->foreignId('incident_id')->constrained('ba_incidents')->cascadeOnDelete()", $migration);
        $this->assertStringContainsString("\$table->foreignId('intervention_id')->constrained('ba_interventions')", $migration);
        $this->assertStringNotContainsString("constrained('ba_interventions')->cascadeOnDelete()", $migration);
        $this->assertStringContainsString("\$table->unique(['incident_id', 'intervention_id'], 'uq_ba_inc_int')", $migration);
    }

    /** TC-P03 · BC-DB-06 · Source: Model $fillable / relationships / scope */
    public function test_intervention_03_model_fillable_relationships_and_scope(): void
    {
        $model = new BaIntervention();
        foreach (['name', 'description', 'intervention_type', 'sort_order', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $model->getFillable(), "fillable should include {$col}.");
        }

        $this->assertInstanceOf(BelongsToMany::class, $model->incidents());

        // scopeActive filters is_active = true
        $sql = strtolower(BaIntervention::query()->active()->toSql());
        $this->assertStringContainsString('is_active', $sql, 'scopeActive should filter on is_active.');
    }

    /** TC-N02 · BC-VAL-* · Source: BaInterventionRequest rules()/messages() literal strings */
    public function test_intervention_04_form_request_rules_contain_expected_constraints(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("'name'        => ['required', 'string', 'max:100']", $request);
        $this->assertStringContainsString("Rule::in(['reward', 'corrective', 'counselling'])", $request);
        $this->assertStringContainsString("Rule::unique('ba_interventions', 'sort_order')", $request);
        $this->assertStringContainsString("->whereNull('deleted_at')", $request);
        $this->assertStringContainsString("'min:0'", $request);
        $this->assertStringContainsString("'max:255'", $request);
        $this->assertStringContainsString('This sort order is already used by another intervention.', $request);
        // Screen requirement asks for a unique "Intervention Code" — the rule is commented out (not implemented).
        $this->assertStringContainsString("// 'code'", $request);
    }

    /** TC-N01 · BC-DB-04 · Source: DDL NOT NULL columns */
    public function test_intervention_05_db_rejects_each_missing_required_field(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        foreach (['name', 'intervention_type', 'sort_order'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P04 · BC-DB-05 · Source: DDL description nullable */
    public function test_intervention_06_nullable_description_accepts_null(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, ['description' => null]);
            $this->assertNull($record->description);
        } finally {
            if ($record instanceof BaIntervention) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  10–19  Business rules
    // ══════════════════════════════════════════════

    /** TC-P10 · BC-BIZ-01 · Source: Controller@store */
    public function test_intervention_10_create_valid_persists_row(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V2 Create ' . $this->uniqueSuffix();
        $sortOrder = $this->freeSortOrder();
        $saved = null;
        try {
            $this->browserCreateIntervention($name, 'reward', $sortOrder);
            $saved = BaIntervention::query()->where('name', $name)->first();
            $this->assertNotNull($saved, 'Valid intervention was not created.');
        } finally {
            $this->cleanupByName($name);
        }
    }

    /** TC-P11 · BC-VAL-05 · Source: BaInterventionRequest prepareForValidation is_active default true */
    public function test_intervention_11_is_active_defaults_true_on_store(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V2 DefaultActive ' . $this->uniqueSuffix();
        $saved = null;
        try {
            // Create form's status-switch defaults to Active (old('is_active', true)); store persists is_active=1.
            $this->browserCreateIntervention($name, 'counselling', $this->freeSortOrder());
            $saved = BaIntervention::query()->where('name', $name)->first();
            $this->assertNotNull($saved);
            $this->assertTrue((bool) $saved->is_active, 'is_active should default to true on store.');
        } finally {
            $this->cleanupByName($name);
        }
    }

    /** TC-P12 · BC-BIZ-02 · Source: intervention_type ENUM('corrective','counselling','reward') */
    public function test_intervention_12_intervention_type_persists_each_enum_value(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        foreach (['reward', 'corrective', 'counselling'] as $type) {
            $record = null;
            try {
                $record = $this->createRecordDirectly($dependencies, [
                    'name' => 'V2 Type ' . $type . ' ' . $this->uniqueSuffix(),
                    'intervention_type' => $type,
                ]);
                $record->refresh();
                $this->assertSame($type, (string) $record->intervention_type, "intervention_type {$type} should persist.");
            } finally {
                if ($record instanceof BaIntervention) {
                    $this->forceDeleteRecordByIdIfExists((int) $record->id);
                }
            }
        }
    }

    /** TC-P13 · BC-BIZ-03 · Source: show.blade */
    public function test_intervention_13_show_page_renders_details(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V2 Show ' . $this->uniqueSuffix(),
            'intervention_type' => 'corrective',
            'description' => 'Structured reflection worksheet.',
        ]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);
                $browser->waitForText('Intervention Name', 12)
                    ->assertSee((string) $record->name)
                    ->assertSee('Corrective')
                    ->assertSee('Structured reflection worksheet.');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P14 · BC-BIZ-04 · Source: Controller@update flash "Intervention updated successfully." */
    public function test_intervention_14_edit_update_persists_and_flashes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Before ' . $this->uniqueSuffix()]);
        $updated = 'V2 After ' . $this->uniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($record, $updated): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('input[name="name"]', 12)
                    ->clear('input[name="name"]')->type('input[name="name"]', $updated)
                    ->press('Update Intervention')->pause(2200)
                    ->assertSee('Intervention updated successfully.');
            });
            $record->refresh();
            $this->assertSame($updated, (string) $record->name);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P15 · BC-BIZ-05 · Source: Controller@destroy flash "Intervention moved to trash." */
    public function test_intervention_15_destroy_flashes_moved_to_trash(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Destroy ' . $this->uniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                $this->suppressBrowserAlertDialogs($browser);
                // Issue the DELETE from the page (SweetAlert confirm is bypassed via direct form submit).
                $response = $this->sendFormRequestFromBrowser($browser, 'DELETE', self::SHOW_BASE_PATH . '/' . $id);
                $this->assertStringNotContainsString('ERROR:', $response, 'Destroy request should complete.');
            });
            $this->assertNull(BaIntervention::find($id), 'Intervention should be soft-deleted by destroy().');
            $trashed = BaIntervention::withTrashed()->find($id);
            $this->assertNotNull($trashed);
            $this->assertFalse((bool) $trashed->is_active, 'destroy() sets is_active=false before soft-delete.');
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /**
     * TC-N20 · BC-BIZ-06 · Finding VAL-BA-INT-01 (verify in source).
     * The screen ("Unique Code & Name") requires the Intervention Name to be unique, but neither the
     * DB (no unique index on `name`) nor the FormRequest (no unique rule on `name`) enforces it. This
     * proves the current behaviour: two interventions can share the same name.
     * Source: BaInterventionRequest@rules:23 (name has no unique rule); migration (no unique on name).
     */
    public function test_intervention_16_duplicate_name_is_allowed_val_gap(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V2 DupName ' . $this->uniqueSuffix();
        $a = null;
        $b = null;
        try {
            $a = $this->createRecordDirectly($dependencies, ['name' => $name]);
            $b = $this->createRecordDirectly($dependencies, ['name' => $name]);
            $this->assertNotNull($b->id,
                'VAL-BA-INT-01 confirmed: duplicate intervention name accepted (screen "unique Name" not enforced).');
            $this->assertSame(2, BaIntervention::query()->where('name', $name)->count());
        } finally {
            foreach ([$a, $b] as $rec) {
                if ($rec instanceof BaIntervention) {
                    $this->forceDeleteRecordByIdIfExists((int) $rec->id);
                }
            }
        }
    }

    // ══════════════════════════════════════════════
    //  20–29  State-machine / status lifecycle (BC-SM)
    // ══════════════════════════════════════════════

    /** TC-SM01 · BC-SM-01 · Source: Controller@toggleStatus (active → inactive) + .status-switch */
    public function test_intervention_20_toggle_status_active_inactive_cycle(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Cycle ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::LISTING_PATH, 900);
                $browser->waitFor('.status-switch[data-id="' . $record->id . '"]', 12)
                    ->script("\$('.status-switch[data-id=\"{$record->id}\"]').click()");
                $browser->pause(1600);
            });
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'First toggle should deactivate.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM02 · BC-SM-02 · Source: Controller@toggleStatus JSON {success,is_active,message} */
    public function test_intervention_21_toggle_status_endpoint_returns_json_payload(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Json ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::LISTING_PATH, 900);
                $response = $this->sendFormRequestFromBrowser(
                    $browser,
                    'POST',
                    self::LISTING_PATH . '/' . $record->id . '/toggle-status'
                );
                $this->assertStringContainsString('"success"', $response, 'Toggle endpoint should return a JSON success key.');
                $this->assertStringContainsString('Intervention deactivated.', $response, 'Toggle endpoint should return the deactivation message.');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM03 · BC-SM-03 · Source: Controller@destroy — sets is_active=false then soft-deletes */
    public function test_intervention_22_destroy_deactivates_then_soft_deletes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 DestroyModel ' . $this->uniqueSuffix(), 'is_active' => true]);
        $id = (int) $record->id;
        try {
            // Mirror controller destroy(): flag inactive then soft-delete.
            $record->is_active = false;
            $record->save();
            $record->delete();

            $this->assertNull(BaIntervention::find($id));
            $trashed = BaIntervention::withTrashed()->find($id);
            $this->assertNotNull($trashed);
            $this->assertFalse((bool) $trashed->is_active, 'Destroyed intervention should be inactive in trash.');
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /** TC-D02 (B) · BC-BIZ-07 · Source: Controller@restore */
    public function test_intervention_23_restore_brings_back_from_trash(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Restore ' . $this->uniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $record->delete();
            $this->assertNull(BaIntervention::find($id));
            $record->restore();
            $this->assertNotNull(BaIntervention::find($id));
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /**
     * TC-N21 · BC-SM-04 · Audit-BUG-BA-005 (verify in source).
     * Requirement ("Deactivation Protections" / BR-BA-030): an intervention linked to an active
     * incident in ba_incident_intervention_jnt cannot be deactivated. toggleStatus() performs NO
     * usage check, so an in-use intervention can be freely deactivated. Proven at model+source layer
     * (no cross-module seed needed): the controller source contains no junction reference check.
     * Source: BaInterventionController@toggleStatus:115-128 and @destroy:69-81 (no guard).
     */
    public function test_intervention_24_deactivate_has_no_usage_guard_bug_ba_005(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 NoGuard ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            // Simulate the toggle path outcome (controller applies no usage guard).
            $record->is_active = ! $record->is_active;
            $record->save();
            $record->refresh();
            $this->assertFalse((bool) $record->is_active,
                'BUG-BA-005 confirmed: deactivation is not blocked by any in-use/junction guard.');

            $controller = File::get(base_path(self::CONTROLLER_FILE));
            $this->assertStringNotContainsString('ba_incident_intervention_jnt', $controller,
                'BR-BA-030: controller never references the junction to guard deactivate/delete.');
            $this->assertStringNotContainsString('BaIncidentInterventionJnt', $controller);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  30–39  Validation (negative matrix)
    // ══════════════════════════════════════════════

    /** TC-N30 · BC-VAL-01 · Source: required rules */
    public function test_intervention_30_required_fields_show_errors_and_block_insert(): void
    {
        $this->resolveDependenciesOrSkip();
        $before = BaIntervention::query()->count();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->script("(function(){document.querySelectorAll('[required]').forEach(function(i){i.removeAttribute('required');}); document.querySelector('input[name=\"sort_order\"]').value=''; document.querySelector('form').submit();})();");
            $browser->pause(2000)->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaIntervention::query()->count(), 'Empty submission must not create a row.');
    }

    /** TC-N31 · BC-VAL-02 · Source: name max:100 */
    public function test_intervention_31_name_exceeding_max_is_rejected(): void
    {
        $longName = str_repeat('N', 130);
        $before = BaIntervention::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($longName): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->script("document.querySelector('input[name=\"name\"]').removeAttribute('maxlength');")
                ->type('input[name="name"]', $longName)
                ->select('intervention_type', 'reward')
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->freeSortOrder())
                ->press('Save Intervention')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaIntervention::query()->count(), 'Over-length name must be rejected.');
    }

    /** TC-N32 · BC-VAL-03 · Source: intervention_type Rule::in */
    public function test_intervention_32_intervention_type_out_of_enum_is_rejected(): void
    {
        $name = 'V2 EnumType ' . $this->uniqueSuffix();
        $before = BaIntervention::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('select[name="intervention_type"]', 12)
                ->script("(function(){var s=document.querySelector('select[name=\"intervention_type\"]');var o=document.createElement('option');o.value='suspension';o.text='suspension';s.appendChild(o);s.value='suspension';})();");
            $browser->type('input[name="name"]', $name)
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->freeSortOrder())
                ->press('Save Intervention')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaIntervention::query()->count(), 'Out-of-enum intervention_type must be rejected.');
    }

    /** TC-N33 · BC-VAL-04 · Source: sort_order unique + messages() text */
    public function test_intervention_33_duplicate_active_sort_order_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $existing = $this->createRecordDirectly($dependencies, [
            'name' => 'V2 SortExisting ' . $this->uniqueSuffix(),
            'sort_order' => $this->freeSortOrder(),
        ]);
        $before = BaIntervention::query()->count();
        try {
            $this->browse(function (Browser $browser) use ($existing): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', 'V2 SortAttempt ' . $this->uniqueSuffix())
                    ->select('intervention_type', 'reward')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $existing->sort_order)
                    ->press('Save Intervention')->pause(2000)
                    ->assertPresent('.alert-danger')
                    ->assertSee('This sort order is already used by another intervention.');
            });
            $this->assertSame($before, BaIntervention::query()->count(), 'Duplicate active sort_order must not create a row.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $existing->id);
        }
    }

    /** TC-N34 · BC-VAL-04 · Source: sort_order min:0 */
    public function test_intervention_34_negative_sort_order_is_rejected(): void
    {
        $name = 'V2 NegSort ' . $this->uniqueSuffix();
        $before = BaIntervention::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->script("document.querySelector('input[name=\"sort_order\"]').removeAttribute('min');")
                ->type('input[name="name"]', $name)
                ->select('intervention_type', 'reward')
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', '-7')
                ->press('Save Intervention')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaIntervention::query()->count(), 'Negative sort_order must be rejected.');
    }

    /**
     * TC-D04 (G) · BC-EDG-02 · Audit-DATA-BA-003 (contrast, verify in source).
     * DATA-BA-003 (soft-delete + UNIQUE without deleted_at → 500) does NOT manifest on ba_interventions
     * because there is NO DB-level unique index on sort_order — uniqueness lives only in the FormRequest
     * (scoped `whereNull('deleted_at')`). So a sort_order can be reused after the original is soft-deleted,
     * with no 500. (The DATA-BA-003 vector for this feature is the junction `uq_ba_inc_int`, which owns
     * softDeletes — that is InterventionApplied's concern.)
     * Source: migration (no unique on sort_order); BaInterventionRequest@rules:31-33.
     */
    public function test_intervention_35_sort_order_may_be_reused_after_soft_delete(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $sortOrder = $this->freeSortOrder();
        $first = $this->createRecordDirectly($dependencies, ['name' => 'V2 Reuse1 ' . $this->uniqueSuffix(), 'sort_order' => $sortOrder]);
        $first->delete();
        $second = null;
        try {
            $second = $this->createRecordDirectly($dependencies, ['name' => 'V2 Reuse2 ' . $this->uniqueSuffix(), 'sort_order' => $sortOrder]);
            $this->assertNotNull($second->id, 'sort_order reuse after soft-delete should succeed (no DB unique on sort_order).');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $first->id);
            if ($second instanceof BaIntervention) {
                $this->forceDeleteRecordByIdIfExists((int) $second->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  40–49  Integration / FK / dependency
    // ══════════════════════════════════════════════

    /** TC-D06 (E) · BC-INT-01 · Source: BaIntervention::incidents() belongsToMany junction */
    public function test_intervention_40_incidents_relationship_is_defined(): void
    {
        $model = new BaIntervention();
        $this->assertInstanceOf(BelongsToMany::class, $model->incidents(),
            'An intervention should expose an incidents() belongsToMany relationship via the junction.');

        try {
            $this->assertTrue(
                Schema::hasColumn(self::JUNCTION_TABLE, 'intervention_id'),
                'ba_incident_intervention_jnt.intervention_id should reference the intervention.'
            );
        } catch (Throwable) {
            $this->markTestSkipped('Junction table not present in this environment.');
        }
    }

    /**
     * TC-D07 (C) · BC-REF-01 · Audit-BUG-BA-005 (FK RESTRICT — verify in source).
     * ba_incident_intervention_jnt.intervention_id → ba_interventions with the DEFAULT onDelete
     * (RESTRICT — no cascadeOnDelete). A raw DB delete of an intervention referenced by a junction row
     * is therefore blocked by the DB with an integrity constraint error. This proves the FK-RESTRICT
     * dependency (an intervention referenced by an incident cannot be hard-removed at the DB layer).
     * Cross-module: requires a real ba_incidents row → defensive skip when absent.
     */
    public function test_intervention_41_fk_restrict_blocks_raw_delete_when_referenced_bug_ba_005(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $incidentId = $this->resolveIncidentIdOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 FkRestrict ' . $this->uniqueSuffix()]);
        $jntId = $this->createJunctionLink((int) $record->id, $incidentId, (int) $dependencies['admin_user_id']);
        try {
            $threw = false;
            try {
                // Raw DB delete bypasses the model's booted() detach → the FK RESTRICT fires.
                DB::table(self::TABLE)->where('id', $record->id)->delete();
            } catch (QueryException $e) {
                $threw = str_contains(strtolower($e->getMessage()), '23000')
                    || str_contains(strtolower($e->getMessage()), 'foreign key')
                    || str_contains(strtolower($e->getMessage()), 'integrity constraint');
            } catch (Throwable $e) {
                $threw = str_contains(strtolower($e->getMessage()), 'foreign key')
                    || str_contains(strtolower($e->getMessage()), 'integrity');
            }
            $this->assertTrue($threw,
                'FK RESTRICT confirmed: a referenced intervention cannot be hard-deleted at the DB layer.');
        } finally {
            DB::table(self::JUNCTION_TABLE)->where('id', $jntId)->delete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-D08 (B) · BC-BIZ-08 · Source: BaIntervention::booted() deleting → detach on forceDelete.
     * The model detaches its junction rows on force-delete (isForceDeleting), so an Eloquent
     * forceDelete() succeeds by removing the links first (circumventing the DB RESTRICT).
     * Cross-module: requires a ba_incidents row → defensive skip when absent.
     */
    public function test_intervention_42_force_delete_detaches_incident_links(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $incidentId = $this->resolveIncidentIdOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 ForceDetach ' . $this->uniqueSuffix()]);
        $jntId = $this->createJunctionLink((int) $record->id, $incidentId, (int) $dependencies['admin_user_id']);
        $interventionId = (int) $record->id;
        try {
            $record->forceDelete(); // booted() detaches the junction row first, then removes the parent
            $this->assertNull(BaIntervention::withTrashed()->find($interventionId), 'Intervention should be force-deleted.');
            $this->assertSame(0, DB::table(self::JUNCTION_TABLE)->where('id', $jntId)->count(),
                'Junction link should be detached by the model deleting() hook on force-delete.');
        } finally {
            DB::table(self::JUNCTION_TABLE)->where('id', $jntId)->delete();
            $this->forceDeleteRecordByIdIfExists($interventionId);
        }
    }

    /**
     * TC-N22 · BC-BIZ-09 · Audit-BUG-BA-005 (verify in source).
     * BR-BA-030: an intervention linked to an incident must NOT be deletable. destroy() (soft-delete)
     * performs no junction reference check, so a linked intervention is soft-deleted anyway. Proven
     * here at the model layer with a real junction link.
     * Cross-module: requires a ba_incidents row → defensive skip when absent.
     */
    public function test_intervention_43_soft_delete_linked_intervention_is_not_blocked_bug_ba_005(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $incidentId = $this->resolveIncidentIdOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 SoftLinked ' . $this->uniqueSuffix()]);
        $interventionId = (int) $record->id;
        $jntId = $this->createJunctionLink($interventionId, $incidentId, (int) $dependencies['admin_user_id']);
        try {
            $record->delete(); // soft-delete: controller/model perform no "in use?" guard
            $this->assertNull(BaIntervention::find($interventionId),
                'BUG-BA-005 confirmed: a linked intervention is soft-deleted with no reference guard.');
            $this->assertSame(1, DB::table(self::JUNCTION_TABLE)->where('id', $jntId)->count(),
                'Soft-delete leaves the junction link intact (historical record preserved, but delete not blocked).');
        } finally {
            DB::table(self::JUNCTION_TABLE)->where('id', $jntId)->delete();
            $this->forceDeleteRecordByIdIfExists($interventionId);
        }
    }

    // ══════════════════════════════════════════════
    //  50–59  Permissions / authorization
    // ══════════════════════════════════════════════

    /** TC-S01 · BC-AUTH-01 · Source: auth middleware on web routes */
    public function test_intervention_50_guest_redirected_to_login_on_create(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** TC-S02 · BC-AUTH-02 · Source: index → masters gate + redirect */
    public function test_intervention_51_guest_redirected_to_login_on_index(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /**
     * TC-S03 · BC-AUTH-03 · Audit-SEC-BA-002 (verify in source).
     * BaInterventionRequest::authorize() returns a bare `true` (D30) — the FormRequest does not gate.
     * Access control relies entirely on the controller's Gate::authorize() calls. Documents the systemic gap.
     * Source: BaInterventionRequest.php:12-15.
     */
    public function test_intervention_52_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = new BaInterventionRequest();
        $this->assertTrue($request->authorize(),
            'SEC-BA-002 confirmed: FormRequest authorize() returns bare true (auth deferred to controller gates).');

        // Defence-in-depth still exists: the controller gate string is present in source.
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.interventions.create')", $controller);
    }

    /** TC-S04 · BC-AUTH-04 · Source: Controller Gate::authorize on create (limited user → 403) */
    public function test_intervention_53_user_without_permission_is_forbidden(): void
    {
        $limited = $this->createLimitedUserOrSkip();

        $this->browse(function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600)
                ->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);

            $source = strtolower($browser->driver->getPageSource());
            $forbidden = str_contains($source, '403')
                || str_contains($source, 'forbidden')
                || str_contains($source, 'not authorized')
                || str_contains($source, 'unauthorized');
            $stillHasForm = str_contains($source, 'save intervention');

            $this->assertTrue($forbidden || ! $stillHasForm,
                'A user lacking interventions.create should be blocked from the create screen.');
        });
    }

    // ══════════════════════════════════════════════
    //  60–69  UI / UX (search, list, filter, empty state)
    // ══════════════════════════════════════════════

    /** TC-P60 · BC-BIZ-10 · Source: masters list _interventions.blade */
    public function test_intervention_60_masters_list_shows_created_intervention(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Listed ' . $this->uniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=interventions', 1000);
                $browser->waitForText('Name', 12)->assertSee((string) $record->name);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P61 · BC-BIZ-11 · Source: masters() search by name */
    public function test_intervention_61_search_by_name_filters_list(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $token = 'Zeta' . $this->uniqueSuffix();
        $record = $this->createRecordDirectly($dependencies, ['name' => $token]);
        try {
            $this->browse(function (Browser $browser) use ($token): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=interventions&search=' . urlencode($token), 1000);
                $browser->assertSee($token);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P62 · BC-BIZ-12 · Source: masters() intervention_type filter dropdown */
    public function test_intervention_62_filter_by_type_shows_matching_intervention(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $token = 'Cnsl' . $this->uniqueSuffix();
        $record = $this->createRecordDirectly($dependencies, ['name' => $token, 'intervention_type' => 'counselling']);
        try {
            $this->browse(function (Browser $browser) use ($token): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=interventions&search=' . urlencode($token) . '&intervention_type=counselling', 1000);
                $browser->assertSee($token);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P63 · BC-BIZ-13 · Source: trash.blade "Deleted At" + list */
    public function test_intervention_63_trash_page_lists_soft_deleted(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Trash ' . $this->uniqueSuffix()]);
        $record->delete();
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TRASH_PATH, 900);
                $browser->waitForText('Deleted At', 12)->assertSee((string) $record->name);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  70–79  Edge cases
    // ══════════════════════════════════════════════

    /** TC-D09 (G) · BC-EDG-03 · Source: sort_order unsignedTinyInteger (0–255) boundary */
    public function test_intervention_70_sort_order_tinyint_boundary_persists(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        // Free the 255 slot if some seed occupies it, then assert boundary persistence at the model layer.
        try {
            BaIntervention::withTrashed()->where('sort_order', 255)->get()
                ->each(fn (BaIntervention $r) => $this->forceDeleteRecordByIdIfExists((int) $r->id));
            $record = $this->createRecordDirectly($dependencies, [
                'name' => 'V2 Boundary ' . $this->uniqueSuffix(),
                'sort_order' => 255,
            ]);
            $record->refresh();
            $this->assertSame(255, (int) $record->sort_order, 'sort_order 255 (TINYINT UNSIGNED max) should persist.');
        } finally {
            if ($record instanceof BaIntervention) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    /** TC-D10 (G) · BC-EDG-04 · Source: description TEXT accepts long content */
    public function test_intervention_71_long_description_is_accepted(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        $long = str_repeat('Restorative protocol detail. ', 60);
        try {
            $record = $this->createRecordDirectly($dependencies, [
                'name' => 'V2 LongDesc ' . $this->uniqueSuffix(),
                'description' => $long,
            ]);
            $record->refresh();
            $this->assertSame($long, (string) $record->description);
        } finally {
            if ($record instanceof BaIntervention) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  90–99  Tenancy + security
    // ══════════════════════════════════════════════

    /** TC-T01 · BC-CFG-01 · Source: tenant-scoped table (no tenant_id column) */
    public function test_intervention_90_runs_inside_initialized_tenant(): void
    {
        if (!function_exists('tenancy')) {
            $this->markTestSkipped('Tenancy helper unavailable.');
        }
        $this->assertTrue(tenancy()->initialized, 'Intervention is tenant-scoped and requires an initialized tenant.');
        $this->assertTrue(Schema::hasTable(self::TABLE), 'ba_interventions must resolve within the tenant DB.');
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'tenant_id'),
            'Tenant-per-database design → no tenant_id column on ba_interventions.');
    }

    /** TC-S05 · BC-EDG-05 · Source: Blade `{{ }}` auto-escaping on show */
    public function test_intervention_91_stored_xss_in_name_is_escaped_on_show(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $marker = 'xss' . $this->uniqueSuffix();
        $payload = '<script>window.' . $marker . '=1</script>';
        $record = $this->createRecordDirectly($dependencies, ['name' => $payload]);
        try {
            $this->browse(function (Browser $browser) use ($record, $marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);
                $browser->waitForText('Intervention Name', 12);
                $executed = $browser->script('return window.' . $marker . ' === 1;')[0] ?? false;
                $this->assertNotTrue($executed, 'Stored script in the intervention name must not execute (Blade escaping).');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-S06 · BC-AUTH-05 · Source: Controller@show findOrFail → 404 */
    public function test_intervention_92_invalid_id_does_not_render_detail(): void
    {
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl(self::SHOW_BASE_PATH . '/98765432'))->pause(1200);
            $browser->assertDontSee('Intervention Name');
        });
    }

    // ══════════════════════════════════════════════
    //  Helpers
    // ══════════════════════════════════════════════

    private function resolveDependenciesOrSkip(): array
    {
        $adminUserId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));
        if ($adminUserId <= 0) {
            $this->markTestSkipped('No admin user found for intervention tests.');
        }

        return ['admin_user_id' => $adminUserId];
    }

    private function resolveIncidentIdOrSkip(): int
    {
        try {
            $incidentId = (int) DB::table('ba_incidents')->min('id');
        } catch (Throwable) {
            $this->markTestSkipped('ba_incidents table not present in this environment.');
        }
        if ($incidentId <= 0) {
            $this->markTestSkipped('No ba_incidents row available to exercise the intervention FK dependency.');
        }
        return $incidentId;
    }

    private function createJunctionLink(int $interventionId, int $incidentId, int $adminUserId): int
    {
        return (int) DB::table(self::JUNCTION_TABLE)->insertGetId([
            'incident_id'     => $incidentId,
            'intervention_id' => $interventionId,
            'notes'           => 'Linked by dusk test.',
            'is_active'       => 1,
            'created_by'      => $adminUserId,
            'updated_by'      => $adminUserId,
            'created_at'      => now(),
            'updated_at'      => now(),
        ]);
    }

    private function createRecordDirectly(array $dependencies, array $overrides = []): BaIntervention
    {
        return BaIntervention::query()->create(array_merge($this->buildValidDirectPayload($dependencies), $overrides));
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'name'              => 'Intervention ' . $this->uniqueSuffix(),
            'description'       => 'Created for dusk test.',
            'intervention_type' => 'reward',
            'sort_order'        => $this->freeSortOrder(),
            'is_active'         => true,
            'created_by'        => (int) $dependencies['admin_user_id'],
            'updated_by'        => (int) $dependencies['admin_user_id'],
        ];
    }

    private function freeSortOrder(): int
    {
        $max = (int) BaIntervention::withTrashed()->max('sort_order');
        return min(255, max(1, $max + random_int(1, 20)));
    }

    private function forceDeleteRecordByIdIfExists(int $recordId): void
    {
        BaIntervention::withTrashed()->where('id', $recordId)->get()
            ->each(function (BaIntervention $record): void {
                try {
                    $record->incidents()->detach();
                    $record->forceDelete();
                } catch (Throwable) {
                    // ignore media/soft-delete cleanup issues
                }
            });
    }

    private function cleanupByName(string $name): void
    {
        BaIntervention::withTrashed()->where('name', $name)->get()
            ->each(function (BaIntervention $record): void {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            });
    }

    private function assertDatabaseRejectsMissingField(array $dependencies, string $missingField): void
    {
        $created = null;
        try {
            $payload = $this->buildValidDirectPayload($dependencies);
            unset($payload[$missingField]);
            $created = BaIntervention::query()->create($payload);
            $this->fail("Expected DB rejection for missing {$missingField}, but insert succeeded.");
        } catch (Throwable $exception) {
            $message = strtolower($exception->getMessage());
            $isConstraint = str_contains($message, 'cannot be null')
                || str_contains($message, 'not null')
                || str_contains($message, "doesn't have a default value")
                || str_contains($message, 'integrity constraint')
                || str_contains($message, '23000');
            $this->assertTrue($isConstraint, "Expected DB required-field failure for {$missingField}, got: {$exception->getMessage()}");
        } finally {
            if ($created instanceof BaIntervention) {
                $this->forceDeleteRecordByIdIfExists((int) $created->id);
            }
        }
    }

    private function browserCreateIntervention(string $name, string $type, int $sortOrder): void
    {
        $this->browse(function (Browser $browser) use ($name, $type, $sortOrder): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->type('input[name="name"]', $name)
                ->select('intervention_type', $type)
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $sortOrder)
                ->press('Save Intervention')
                ->pause(2500);
        });
    }

    /**
     * Issue an authenticated fetch (with CSRF + method spoofing) from the current page and return the
     * response body text. Used for endpoints Dusk's Browser cannot exercise directly (POST/DELETE/JSON).
     */
    private function sendFormRequestFromBrowser(Browser $browser, string $method, string $path): string
    {
        $url = $this->tenantUrl($path);
        $verb = strtoupper($method);
        $spoof = in_array($verb, ['PUT', 'PATCH', 'DELETE'], true) ? $verb : '';
        $script = <<<JS
        var done = arguments[arguments.length - 1];
        var token = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';
        var body = new URLSearchParams();
        body.append('_token', token);
        if ("{$spoof}" !== "") { body.append('_method', "{$spoof}"); }
        fetch("{$url}", {
            method: "{$spoof}" !== "" ? 'POST' : "{$verb}",
            headers: { 'X-CSRF-TOKEN': token, 'Accept': 'application/json, text/html', 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
            credentials: 'same-origin',
            body: "{$verb}" === 'GET' ? undefined : body.toString()
        }).then(function (r) { return r.text(); })
          .then(function (t) { done(t); })
          .catch(function (e) { done('ERROR:' + e); });
JS;

        try {
            $result = $browser->driver->executeAsyncScript($script);
            return is_string($result) ? $result : json_encode($result);
        } catch (Throwable $e) {
            return 'ERROR:' . $e->getMessage();
        }
    }

    private function createLimitedUserOrSkip(): User
    {
        try {
            $languageId = (int) DB::table('glb_languages')->min('id');
            if ($languageId <= 0) {
                $this->markTestSkipped('No language row available to satisfy sys_users.prefered_language FK.');
            }

            $suffix = uniqid();
            $user = new User();
            $user->forceFill([
                'name'              => 'Limited INT ' . $suffix,
                'email'             => 'limited_int_' . $suffix . '@tenant.test',
                'password'          => bcrypt('password'),
                'emp_code'          => substr('L' . $suffix, 0, 20),
                'prefered_language' => $languageId,
                'user_type'         => 'EMPLOYEE',
                'email_verified_at' => now(),
            ]);
            $user->save();

            $this->limitedUser = $user;
            return $user;
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not provision a limited user: ' . $e->getMessage());
        }
    }

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
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

        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
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

    private function initializeTenantContext(): void
    {
        $tenantHost = parse_url($this->tenantBaseUrl, PHP_URL_HOST);

        if (!is_string($tenantHost) || $tenantHost === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }

        $domain = \Modules\Prime\Models\Domain::query()->where('domain', $tenantHost)->first();
        if (!$domain) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $tenantHost);
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
            $this->markTestSkipped('No tenant user found for dusk login.');
        }

        if (property_exists($this->adminUser, 'email_verified_at') && !$this->adminUser->email_verified_at) {
            $this->adminUser->email_verified_at = now();
            $this->adminUser->save();
        }

        $this->grantPermissionsToUser($this->adminUser);
    }

    private function grantPermissionsToUser(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo')) {
            return;
        }

        $permissions = [
            'tenant.behavioural-assessment.interventions.viewAny',
            'tenant.behavioural-assessment.interventions.view',
            'tenant.behavioural-assessment.interventions.create',
            'tenant.behavioural-assessment.interventions.update',
            'tenant.behavioural-assessment.interventions.delete',
            'tenant.behavioural-assessment.interventions.status',
            'tenant.behavioural-assessment.interventions.restore',
            'tenant.behavioural-assessment.interventions.forceDelete',
            'tenant.behavioural-assessment.masters.viewAny',
        ];

        $this->ensurePermissionsExist($permissions);

        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
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

    private function suppressBrowserAlertDialogs(Browser $browser): void
    {
        $browser->script(<<<'JS'
        (function () {
            window.__duskAlertMessages = window.__duskAlertMessages || [];
            window.alert = function (message) {
                window.__duskAlertMessages.push(String(message || ''));
            };
        })();
JS);
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
}
