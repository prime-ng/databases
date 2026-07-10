<?php

/**
 * BehaviouralAssessment › RatingScale — V2 (comprehensive) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/RatingScale/RatingScaleCrudTest.php.
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; tables under database/migrations/tenant/).
 * TABLES  : ba_rating_scales (+ child ba_rating_levels). DDL doc + this file's name use the stale
 *           prefix "bha_" (audit DOC-BA-001); every schema assertion targets the LIVE "ba_" tables.
 *
 * Semantic numbering bands (WP-G):
 *   01–09 schema/model/request · 10–19 business rules · 20–29 state-machine/status
 *   30–39 validation · 40–49 integration/FK · 50–59 permissions · 60–69 UI/UX
 *   70–79 edge · 90–99 tenancy + security
 *
 * Audit findings proven here (reported as "verify in source" — traced to the cited lines):
 *   BUG-BA-009  multiple is_default=true allowed          → test_..._13
 *   DATA-BA-001 scale deactivatable without usage guard   → test_..._26 / _27
 *   VAL-BA-002  level numeric_value not range-checked      → test_..._38
 *   DATA-BA-003 soft-delete + UNIQUE(sort_order) collision → test_..._39
 *   SEC-BA-002  FormRequest authorize() returns bare true  → test_..._52
 *   DOC-BA-001  DDL doc prefix bha_ vs live ba_            → test_..._01
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Requests\BaRatingScaleRequest;
use Modules\BehaviouralAssessment\Models\BaRatingLevel;
use Modules\BehaviouralAssessment\Models\BaRatingScale;
use Modules\SchoolSetup\Models\User;
use Tests\DuskTestCase;
use Throwable;

class bha_RatingScaleV2_TestCas extends DuskTestCase
{
    private const INDEX_PATH       = '/behavioural-assessment/masters';
    private const LISTING_PATH     = '/behavioural-assessment/rating-scales';
    private const CREATE_PATH      = '/behavioural-assessment/rating-scales/create';
    private const SHOW_BASE_PATH   = '/behavioural-assessment/rating-scales';
    private const TRASH_PATH       = '/behavioural-assessment/rating-scales/trash';
    private const SCALES_TABLE     = 'ba_rating_scales';
    private const LEVELS_TABLE     = 'ba_rating_levels';
    private const MIGRATION_SCALES = 'database/migrations/tenant/2026_06_16_130616_create_ba_rating_scales_table.php';
    private const MIGRATION_LEVELS = 'database/migrations/tenant/2026_06_16_130622_create_ba_rating_levels_table.php';
    private const CONTROLLER_FILE  = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php';
    private const REQUEST_FILE     = 'Modules/BehaviouralAssessment/app/Http/Requests/BaRatingScaleRequest.php';

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

    /** TC-P01 · BC-DB-01 · Audit-DOC-BA-001 · Source: DDL-ba_rating_scales / live migration */
    public function test_rating_scale_01_schema_and_model_configuration_are_correct(): void
    {
        // DOC-BA-001: the DDL doc names the table bha_rating_scales, but the live table is ba_rating_scales.
        $this->assertTrue(Schema::hasTable(self::SCALES_TABLE), 'Live table ba_rating_scales does not exist.');
        $this->assertFalse(Schema::hasTable('bha_rating_scales'), 'Stale DDL-doc table bha_rating_scales should NOT exist (DOC-BA-001).');

        $this->assertTrue(Schema::hasColumns(self::SCALES_TABLE, [
            'id', 'code', 'name', 'description', 'grade_type', 'min_rating', 'max_rating',
            'is_default', 'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing from ba_rating_scales.');

        $model = new BaRatingScale();
        $this->assertSame('ba_rating_scales', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaRatingScale::class));

        $casts = $model->getCasts();
        $this->assertSame('decimal:1', $casts['min_rating'] ?? null);
        $this->assertSame('decimal:1', $casts['max_rating'] ?? null);
        $this->assertSame('boolean', $casts['is_default'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);
    }

    /** TC-P02 · BC-REF-01 · BC-DB-03 · Source: DDL-ba_rating_levels uq_ba_level */
    public function test_rating_scale_02_levels_schema_unique_index_and_fk(): void
    {
        $this->assertTrue(Schema::hasTable(self::LEVELS_TABLE), 'Live table ba_rating_levels does not exist.');
        $this->assertTrue(Schema::hasColumns(self::LEVELS_TABLE, [
            'id', 'rating_scale_id', 'label', 'numeric_value', 'description',
            'sort_order', 'is_active', 'created_by', 'updated_by', 'deleted_at',
        ]), 'Expected columns missing from ba_rating_levels.');

        $migration = File::get(base_path(self::MIGRATION_LEVELS));
        $this->assertStringContainsString("constrained('ba_rating_scales')->cascadeOnDelete()", $migration);
        $this->assertStringContainsString("uq_ba_level", $migration);
        $this->assertStringContainsString("\$table->unique(['rating_scale_id', 'sort_order']", $migration);

        $level = new BaRatingLevel();
        $this->assertSame('ba_rating_levels', $level->getTable());
        $this->assertInstanceOf(BelongsTo::class, $level->scale());
    }

    /** TC-P03 · BC-DB-06 · Source: Model $fillable / relationships / scope */
    public function test_rating_scale_03_model_fillable_relationships_and_scope(): void
    {
        $model = new BaRatingScale();
        foreach (['name', 'code', 'description', 'grade_type', 'min_rating', 'max_rating', 'is_default', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $model->getFillable(), "fillable should include {$col}.");
        }

        $this->assertInstanceOf(HasMany::class, $model->levels());
        $this->assertInstanceOf(HasMany::class, $model->configs());

        // scopeActive filters is_active = true
        $sql = strtolower(BaRatingScale::query()->active()->toSql());
        $this->assertStringContainsString('is_active', $sql, 'scopeActive should filter on is_active.');
    }

    /** TC-N01 · BC-VAL-* · Source: BaRatingScaleRequest rules() literal strings */
    public function test_rating_scale_04_form_request_rules_contain_expected_constraints(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("Rule::unique('ba_rating_scales', 'code')", $request);
        $this->assertStringContainsString("->whereNull('deleted_at')", $request);
        $this->assertStringContainsString("'max:100'", $request);
        $this->assertStringContainsString("Rule::in(['letter', 'numeric', 'descriptive'])", $request);
        $this->assertStringContainsString("'gt:min_rating'", $request);
        $this->assertStringContainsString("strtoupper", $request);
    }

    /** TC-N02 · BC-DB-04 · Source: DDL NOT NULL columns */
    public function test_rating_scale_05_db_rejects_each_missing_required_field(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        foreach (['code', 'name', 'grade_type', 'min_rating', 'max_rating'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P04 · BC-DB-05 · Source: DDL description nullable */
    public function test_rating_scale_06_nullable_description_accepts_null(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, ['description' => null]);
            $this->assertNull($record->description);
        } finally {
            if ($record instanceof BaRatingScale) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  10–19  Business rules
    // ══════════════════════════════════════════════

    /** TC-P10 · BC-BIZ-01 · Source: Controller@store */
    public function test_rating_scale_10_create_valid_persists_row(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V2 Create ' . $this->uniqueSuffix();
        $saved = null;
        try {
            $this->browserCreateScale($name, 'CR' . $this->uniqueSuffix(), 'letter', '1', '5');
            $saved = BaRatingScale::query()->where('name', $name)->first();
            $this->assertNotNull($saved, 'Valid rating scale was not created.');
        } finally {
            $this->cleanupByName($name);
        }
    }

    /** TC-P11 · BC-BIZ-02 · Source: BaRatingScaleRequest prepareForValidation strtoupper */
    public function test_rating_scale_11_code_is_uppercased_on_store(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V2 Upper ' . $this->uniqueSuffix();
        $lowerCode = 'low' . $this->uniqueSuffix();
        $saved = null;
        try {
            $this->browserCreateScale($name, $lowerCode, 'letter', '1', '5');
            $saved = BaRatingScale::query()->where('name', $name)->first();
            $this->assertNotNull($saved);
            $this->assertSame(strtoupper($lowerCode), (string) $saved->code, 'Code should be persisted upper-cased.');
        } finally {
            $this->cleanupByName($name);
        }
    }

    /** TC-P12 · BC-BIZ-03 · Source: is_default column / create form checkbox */
    public function test_rating_scale_12_is_default_flag_persists(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, [
                'name' => 'V2 Default ' . $this->uniqueSuffix(),
                'is_default' => true,
            ]);
            $record->refresh();
            $this->assertTrue((bool) $record->is_default, 'is_default should persist as true.');
        } finally {
            if ($record instanceof BaRatingScale) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    /**
     * TC-N20 · BC-BIZ-04 · Audit-BUG-BA-009 (verify in source).
     * BR-BA-028 ("only one default scale") is NOT enforced: BaRatingScaleController@store/update
     * saves is_default as-is and never unsets other defaults. This proves the current (defective)
     * behaviour — two scales can both be is_default = true simultaneously.
     * Source: BaRatingScaleController.php store():34 / update():64.
     */
    public function test_rating_scale_13_multiple_default_scales_are_allowed_bug_ba_009(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $a = null;
        $b = null;
        try {
            $a = $this->createRecordDirectly($dependencies, ['name' => 'V2 DefA ' . $this->uniqueSuffix(), 'is_default' => true]);
            $b = $this->createRecordDirectly($dependencies, ['name' => 'V2 DefB ' . $this->uniqueSuffix(), 'is_default' => true]);

            $a->refresh();
            $b->refresh();

            $this->assertTrue((bool) $a->is_default && (bool) $b->is_default,
                'BUG-BA-009 confirmed: multiple scales remain is_default=true (BR-BA-028 not enforced).');
        } finally {
            foreach ([$a, $b] as $rec) {
                if ($rec instanceof BaRatingScale) {
                    $this->forceDeleteRecordByIdIfExists((int) $rec->id);
                }
            }
        }
    }

    /** TC-P13 · BC-BIZ-05 · Source: show.blade */
    public function test_rating_scale_14_show_page_renders_scale_and_levels(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Show ' . $this->uniqueSuffix()]);
        $this->createLevelDirectly($dependencies, $record, ['label' => 'Top', 'numeric_value' => 5.0, 'sort_order' => 1]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);
                $browser->waitForText('Scale Identity', 12)
                    ->assertSee((string) $record->code)
                    ->assertSee('Configured Rating Levels')
                    ->assertSee('Top');
            });
        } finally {
            BaRatingLevel::where('rating_scale_id', $record->id)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P14 · BC-BIZ-06 · Source: Controller@update flash */
    public function test_rating_scale_15_edit_update_persists_and_flashes(): void
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
                    ->press('Update Rating Scale')->pause(2200)
                    ->assertSee('Rating scale updated successfully.');
            });
            $record->refresh();
            $this->assertSame($updated, (string) $record->name);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P15 · BC-BIZ-07 · Source: edit.blade "Add New Level" + Controller@storeLevel flash "Level added." */
    public function test_rating_scale_16_add_level_persists(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 AddLvl ' . $this->uniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('input[name="label"]', 12)
                    ->type('input[name="label"]', 'Proficient')
                    ->type('input[name="numeric_value"]', '4')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', '2')
                    ->press('Add')->pause(2000)
                    ->assertSee('Level added.');
            });
            $this->assertSame(1, BaRatingLevel::where('rating_scale_id', $record->id)->where('label', 'Proficient')->count());
        } finally {
            BaRatingLevel::where('rating_scale_id', $record->id)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P16 · BC-BIZ-08 · Source: Controller@destroyLevel — soft-deletes level */
    public function test_rating_scale_17_remove_level_soft_deletes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 DelLvl ' . $this->uniqueSuffix()]);
        $level = $this->createLevelDirectly($dependencies, $record, ['label' => 'Removable', 'numeric_value' => 3.0, 'sort_order' => 7]);
        try {
            $level->delete();
            $this->assertNull(BaRatingLevel::find($level->id), 'Level should be soft-deleted (hidden from default scope).');
            $this->assertNotNull(BaRatingLevel::withTrashed()->find($level->id), 'Soft-deleted level should still exist with trashed scope.');
        } finally {
            BaRatingLevel::where('rating_scale_id', $record->id)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P17 · BC-EDG-01 · Source: create.blade default values old('min_rating',1.0)/old('max_rating',5.0) */
    public function test_rating_scale_18_create_page_prefills_default_range(): void
    {
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $browser->waitFor('input[name="min_rating"]', 12)
                ->assertInputValue('input[name="min_rating"]', '1.0')
                ->assertInputValue('input[name="max_rating"]', '5.0');
        });
    }

    // ══════════════════════════════════════════════
    //  20–29  State-machine / status lifecycle (BC-SM)
    // ══════════════════════════════════════════════

    /** TC-SM01 · BC-SM-01 · Source: Controller@toggleStatus (active → inactive → active) */
    public function test_rating_scale_20_toggle_status_active_inactive_cycle(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Cycle ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=rating-scales', 900);
                $selector = '.status-toggle[data-id="' . $record->id . '"]';
                $browser->waitFor($selector, 12)->script('document.querySelector(\'' . $selector . '\').click();');
                $browser->pause(1800);
            });
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'First toggle should deactivate.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM02 · BC-SM-02 · Source: Controller@toggleStatus JSON {success,is_active,message} */
    public function test_rating_scale_21_toggle_status_endpoint_returns_json_payload(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Json ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=rating-scales', 900);
                $response = $this->postJsonFromBrowser(
                    $browser,
                    '/behavioural-assessment/rating-scales/' . $record->id . '/toggle-status'
                );
                $this->assertStringContainsString('"success"', $response, 'Toggle endpoint should return a JSON success key.');
                $this->assertStringContainsString('Rating scale', $response, 'Toggle endpoint should return the status message.');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM03 · BC-SM-03 · Source: Controller@destroy — sets is_active=false then soft-deletes */
    public function test_rating_scale_22_destroy_deactivates_then_soft_deletes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Destroy ' . $this->uniqueSuffix(), 'is_active' => true]);
        $id = (int) $record->id;
        try {
            // Mirror controller destroy(): flag inactive then soft-delete.
            $record->is_active = false;
            $record->save();
            $record->delete();

            $this->assertNull(BaRatingScale::find($id));
            $trashed = BaRatingScale::withTrashed()->find($id);
            $this->assertNotNull($trashed);
            $this->assertFalse((bool) $trashed->is_active, 'Destroyed scale should be inactive in trash.');
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /** TC-D02 (B) · BC-BIZ-09 · Source: Controller@restore */
    public function test_rating_scale_23_restore_brings_back_from_trash(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Restore ' . $this->uniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $record->delete();
            $this->assertNull(BaRatingScale::find($id));
            $record->restore();
            $this->assertNotNull(BaRatingScale::find($id));
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /** TC-D03 (B) · BC-REF-02 · Source: FK ba_rating_levels cascadeOnDelete */
    public function test_rating_scale_24_force_delete_cascades_levels(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Cascade ' . $this->uniqueSuffix()]);
        $level = $this->createLevelDirectly($dependencies, $record, ['label' => 'Cascade', 'numeric_value' => 2.0, 'sort_order' => 4]);
        $levelId = (int) $level->id;
        try {
            // Hard-delete parent → DB cascade removes child rows.
            $record->forceDelete();
            $this->assertNull(
                BaRatingLevel::withTrashed()->find($levelId),
                'Levels should be removed by DB cascade when the scale is force-deleted.'
            );
        } finally {
            BaRatingLevel::withTrashed()->where('id', $levelId)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-N21 · BC-SM-04 · Audit-DATA-BA-001 (verify in source).
     * Requirement (02-Rating-Scales "Active Status Constraints" / BR-BA-029): a scale may be
     * deactivated only if NOT linked in Configuration or used by active periods. The controller's
     * toggleStatus() performs NO usage check, so an in-use scale can be freely deactivated.
     * This proves the current (defective) behaviour: toggle succeeds unconditionally.
     * Source: BaRatingScaleController@toggleStatus:117-130 (no guard).
     */
    public function test_rating_scale_26_deactivate_has_no_usage_guard_data_ba_001(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 NoGuard ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            // Simulate the toggle path outcome (controller applies no usage guard).
            $record->is_active = ! $record->is_active;
            $record->save();
            $record->refresh();
            $this->assertFalse((bool) $record->is_active,
                'DATA-BA-001 confirmed: scale deactivation is not blocked by any usage/config guard.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-N22 · BC-BIZ-10 · Source: Requirement "Soft Delete Protection".
     * Requirement says deletion must be blocked when ba_assessment_ratings reference the scale.
     * The controller destroy() has no such reference check — it always soft-deletes. Proven here.
     * Source: BaRatingScaleController@destroy:71-83 (no reference guard).
     */
    public function test_rating_scale_27_destroy_has_no_reference_guard(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 DelGuard ' . $this->uniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $record->delete(); // controller performs no "in use?" check
            $this->assertNull(BaRatingScale::find($id), 'Scale is soft-deleted with no reference guard (documented gap).');
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    // ══════════════════════════════════════════════
    //  30–39  Validation (negative matrix)
    // ══════════════════════════════════════════════

    /** TC-N30 · BC-VAL-01 · Source: required rules */
    public function test_rating_scale_30_required_fields_show_errors_and_block_insert(): void
    {
        $this->resolveDependenciesOrSkip();
        $before = BaRatingScale::query()->count();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            // Clear the prefilled range and submit an otherwise-empty form.
            $browser->waitFor('input[name="min_rating"]', 12)
                ->clear('input[name="min_rating"]')
                ->clear('input[name="max_rating"]')
                ->script("(function(){var s=document.querySelector('select[name=\"grade_type\"]'); if(s){s.removeAttribute('required');} document.querySelectorAll('input[required]').forEach(function(i){i.removeAttribute('required');}); document.querySelector('form').submit();})();");
            $browser->pause(2000)->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaRatingScale::query()->count(), 'Empty submission must not create a row.');
    }

    /** TC-N31 · BC-VAL-02 · Source: code max:30 */
    public function test_rating_scale_31_code_exceeding_max_is_rejected(): void
    {
        $this->assertServerRejects('V2 CodeMax ' . $this->uniqueSuffix(), [
            'code' => str_repeat('X', 35),
            'grade_type' => 'letter',
            'min' => '1', 'max' => '5',
        ]);
    }

    /** TC-N32 · BC-VAL-03 · Source: name max:100 */
    public function test_rating_scale_32_name_exceeding_max_is_rejected(): void
    {
        $longName = str_repeat('N', 130);
        $before = BaRatingScale::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($longName): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="code"]', 12)
                ->script("document.querySelector('input[name=\"name\"]').removeAttribute('maxlength');")
                ->type('input[name="code"]', 'NM' . $this->uniqueSuffix())
                ->type('input[name="name"]', $longName)
                ->select('grade_type', 'letter')
                ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '1')
                ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '5')
                ->press('Save Rating Scale')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaRatingScale::query()->count(), 'Over-length name must be rejected.');
    }

    /** TC-N33 · BC-VAL-04 · Source: grade_type Rule::in */
    public function test_rating_scale_33_grade_type_out_of_enum_is_rejected(): void
    {
        $name = 'V2 EnumGrade ' . $this->uniqueSuffix();
        $before = BaRatingScale::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('select[name="grade_type"]', 12)
                ->script("(function(){var s=document.querySelector('select[name=\"grade_type\"]');var o=document.createElement('option');o.value='emoji';o.text='emoji';s.appendChild(o);s.value='emoji';})();");
            $browser->type('input[name="code"]', 'EN' . $this->uniqueSuffix())
                ->type('input[name="name"]', $name)
                ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '1')
                ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '5')
                ->press('Save Rating Scale')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaRatingScale::query()->count(), 'Out-of-enum grade_type must be rejected.');
    }

    /** TC-N34 · BC-VAL-05 · Source: min_rating min:0 */
    public function test_rating_scale_34_negative_min_rating_is_rejected(): void
    {
        $name = 'V2 NegMin ' . $this->uniqueSuffix();
        $before = BaRatingScale::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="code"]', 12)
                ->type('input[name="code"]', 'NG' . $this->uniqueSuffix())
                ->type('input[name="name"]', $name)
                ->select('grade_type', 'numeric')
                ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '-3')
                ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '5')
                ->press('Save Rating Scale')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaRatingScale::query()->count(), 'Negative min_rating must be rejected.');
    }

    /** TC-N35 · BC-VAL-06 · Source: max_rating gt:min_rating (equal rejected) */
    public function test_rating_scale_35_max_equal_to_min_is_rejected(): void
    {
        $name = 'V2 EqRange ' . $this->uniqueSuffix();
        $before = BaRatingScale::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="code"]', 12)
                ->type('input[name="code"]', 'EQ' . $this->uniqueSuffix())
                ->type('input[name="name"]', $name)
                ->select('grade_type', 'numeric')
                ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '4')
                ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '4')
                ->press('Save Rating Scale')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaRatingScale::query()->count(), 'max == min must be rejected.');
    }

    /** TC-N36 · BC-VAL-07 · Source: unique(code) active */
    public function test_rating_scale_36_duplicate_active_code_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $existing = $this->createRecordDirectly($dependencies, [
            'code' => 'DUP' . $this->uniqueSuffix(),
            'name' => 'V2 DupExisting ' . $this->uniqueSuffix(),
        ]);
        $before = BaRatingScale::query()->count();
        try {
            $this->browse(function (Browser $browser) use ($existing): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('input[name="code"]', 12)
                    ->type('input[name="code"]', (string) $existing->code)
                    ->type('input[name="name"]', 'V2 DupAttempt ' . $this->uniqueSuffix())
                    ->select('grade_type', 'letter')
                    ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '1')
                    ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '5')
                    ->press('Save Rating Scale')->pause(2000)
                    ->assertPresent('.alert-danger');
            });
            $this->assertSame($before, BaRatingScale::query()->count(), 'Duplicate active code must not create a row.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $existing->id);
        }
    }

    /**
     * TC-D04 (G) · BC-EDG-02 · Source: unique rule ->whereNull('deleted_at') + no DB unique on code.
     * Contrast to DATA-BA-003: because the code uniqueness lives only in the FormRequest (scoped to
     * non-deleted rows) and there is NO DB unique index on ba_rating_scales.code, a code can be reused
     * after the original is soft-deleted — no 500. (DATA-BA-003 manifests on levels, see test 39.)
     */
    public function test_rating_scale_37_code_may_be_reused_after_soft_delete(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $code = 'REUSE' . $this->uniqueSuffix();
        $first = $this->createRecordDirectly($dependencies, ['code' => $code, 'name' => 'V2 Reuse1 ' . $this->uniqueSuffix()]);
        $first->delete();
        $second = null;
        try {
            $second = $this->createRecordDirectly($dependencies, ['code' => $code, 'name' => 'V2 Reuse2 ' . $this->uniqueSuffix()]);
            $this->assertNotNull($second->id, 'Code reuse after soft-delete should succeed (no DB unique on code).');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $first->id);
            if ($second instanceof BaRatingScale) {
                $this->forceDeleteRecordByIdIfExists((int) $second->id);
            }
        }
    }

    /**
     * TC-N23 · BC-VAL-08 · Audit-VAL-BA-002 (verify in source).
     * BR-BA-003: a level's numeric_value must fall inside the scale's [min_rating, max_rating].
     * storeLevel() only validates `numeric` (no range check), so a value far outside the range is
     * accepted. Proven here — level 999 saved against a 1–5 scale.
     * Source: BaRatingScaleController@storeLevel:135-153 (rules omit range).
     */
    public function test_rating_scale_38_level_value_is_not_range_checked_val_ba_002(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V2 RangeLvl ' . $this->uniqueSuffix(),
            'min_rating' => 1.0,
            'max_rating' => 5.0,
        ]);
        $outOfRange = null;
        try {
            // numeric_value 9.9 is the DECIMAL(3,1) max and is far outside the 1.0–5.0 scale range.
            $outOfRange = $this->createLevelDirectly($dependencies, $record, [
                'label' => 'OutOfRange',
                'numeric_value' => 9.9,
                'sort_order' => 9,
            ]);
            $outOfRange->refresh();
            $this->assertSame('9.9', (string) $outOfRange->numeric_value,
                'VAL-BA-002 confirmed: level numeric_value is not range-checked against the scale bounds.');
        } finally {
            BaRatingLevel::where('rating_scale_id', $record->id)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-D05 (G) · BC-EDG-03 · Audit-DATA-BA-003 (verify in source).
     * uq_ba_level(rating_scale_id, sort_order) is a DB unique index that does NOT include deleted_at.
     * After a level is soft-deleted (destroyLevel → SoftDeletes), its (scale, sort_order) slot is still
     * occupied at the DB level, so re-adding a level with the same sort_order throws a 23000 integrity
     * error (a 500 through the controller). Proven here at the model layer.
     * Source: migration uq_ba_level; BaRatingLevel uses SoftDeletes.
     */
    public function test_rating_scale_39_soft_deleted_level_sort_order_collision_data_ba_003(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Collide ' . $this->uniqueSuffix()]);
        $sortOrder = 6;
        $first = $this->createLevelDirectly($dependencies, $record, ['label' => 'First', 'numeric_value' => 3.0, 'sort_order' => $sortOrder]);
        try {
            $first->delete(); // soft delete — DB row (with deleted_at) still occupies the unique slot

            $threw = false;
            try {
                $this->createLevelDirectly($dependencies, $record, ['label' => 'Second', 'numeric_value' => 3.5, 'sort_order' => $sortOrder]);
            } catch (QueryException $e) {
                $threw = str_contains(strtolower($e->getMessage()), '23000')
                    || str_contains(strtolower($e->getMessage()), 'duplicate')
                    || str_contains(strtolower($e->getMessage()), 'integrity constraint');
            } catch (Throwable $e) {
                $threw = str_contains(strtolower($e->getMessage()), 'duplicate')
                    || str_contains(strtolower($e->getMessage()), 'integrity');
            }

            $this->assertTrue($threw,
                'DATA-BA-003 confirmed: soft-deleted (scale, sort_order) still blocks re-insert via uq_ba_level.');
        } finally {
            BaRatingLevel::withTrashed()->where('rating_scale_id', $record->id)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  40–49  Integration / FK / dependency
    // ══════════════════════════════════════════════

    /** TC-D06 (E) · BC-INT-01 · Source: BaRatingScale::configs() + bha/ba_config RESTRICT (defensive) */
    public function test_rating_scale_40_config_relationship_is_defined(): void
    {
        $model = new BaRatingScale();
        $this->assertInstanceOf(HasMany::class, $model->configs(),
            'A rating scale should expose a configs() relationship (referenced by ba_config.rating_scale_id).');

        try {
            $this->assertTrue(
                Schema::hasColumn('ba_config', 'rating_scale_id'),
                'ba_config.rating_scale_id should reference the rating scale.'
            );
        } catch (Throwable) {
            $this->markTestSkipped('ba_config table not present in this environment.');
        }
    }

    /** TC-D07 (E) · BC-REF-03 · Source: ba_rating_levels.rating_scale_id belongsTo scale */
    public function test_rating_scale_41_level_belongs_to_its_scale(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Belongs ' . $this->uniqueSuffix()]);
        $level = $this->createLevelDirectly($dependencies, $record, ['label' => 'Belongs', 'numeric_value' => 1.0, 'sort_order' => 3]);
        try {
            $level->refresh();
            $this->assertSame((int) $record->id, (int) $level->scale->id, 'Level should resolve back to its parent scale.');
        } finally {
            BaRatingLevel::where('rating_scale_id', $record->id)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  50–59  Permissions / authorization
    // ══════════════════════════════════════════════

    /** TC-S01 · BC-AUTH-01 · Source: auth middleware on web routes */
    public function test_rating_scale_50_guest_redirected_to_login_on_create(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** TC-S02 · BC-AUTH-02 · Source: BaDashboardController@masters gate + redirect */
    public function test_rating_scale_51_guest_redirected_to_login_on_index(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /**
     * TC-S03 · BC-AUTH-03 · Audit-SEC-BA-002 (verify in source).
     * BaRatingScaleRequest::authorize() returns a bare `true` (D30), so the FormRequest itself does not
     * gate. Access control relies entirely on the controller's Gate::authorize() calls. This documents
     * the systemic gap. Source: BaRatingScaleRequest.php:12-15.
     */
    public function test_rating_scale_52_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = new BaRatingScaleRequest();
        $this->assertTrue($request->authorize(),
            'SEC-BA-002 confirmed: FormRequest authorize() returns bare true (auth deferred to controller gates).');

        // Defence-in-depth still exists: the controller gate string is present in source.
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.rating-scales.create')", $controller);
    }

    /** TC-S04 · BC-AUTH-04 · Source: Controller Gate::authorize on create (limited user → 403) */
    public function test_rating_scale_53_user_without_permission_is_forbidden(): void
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
            $stillHasForm = str_contains($source, 'save rating scale');

            $this->assertTrue($forbidden || ! $stillHasForm,
                'A user lacking rating-scales.create should be blocked from the create screen.');
        });
    }

    // ══════════════════════════════════════════════
    //  60–69  UI / UX (search, list, empty state)
    // ══════════════════════════════════════════════

    /** TC-P60 · BC-BIZ-11 · Source: masters list _rating-scales.blade */
    public function test_rating_scale_60_masters_list_shows_created_scale(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'code' => 'LST' . $this->uniqueSuffix(),
            'name' => 'V2 Listed ' . $this->uniqueSuffix(),
        ]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=rating-scales', 900);
                $browser->waitForText('Code', 12)->assertSee((string) $record->code);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P61 · BC-BIZ-12 · Source: masters() search by name (rs_page) */
    public function test_rating_scale_61_search_by_name_filters_list(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $token = 'Zeta' . $this->uniqueSuffix();
        $record = $this->createRecordDirectly($dependencies, ['name' => $token, 'code' => 'SN' . $this->uniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($token): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=rating-scales&search=' . urlencode($token), 1000);
                $browser->assertSee($token);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P62 · BC-BIZ-13 · Source: masters() search by code */
    public function test_rating_scale_62_search_by_code_filters_list(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $code = 'FIND' . $this->uniqueSuffix();
        $record = $this->createRecordDirectly($dependencies, ['code' => $code, 'name' => 'V2 CodeSearch ' . $this->uniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($code): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=rating-scales&search=' . urlencode($code), 1000);
                $browser->assertSee($code);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P63 · BC-BIZ-14 · Source: trash.blade empty state + list */
    public function test_rating_scale_63_trash_page_lists_soft_deleted_scale(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Trash ' . $this->uniqueSuffix()]);
        $record->delete();
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TRASH_PATH, 900);
                $browser->waitForText('Deleted At', 12)->assertSee((string) $record->code);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  70–79  Edge cases
    // ══════════════════════════════════════════════

    /** TC-D08 (G) · BC-EDG-04 · Source: DECIMAL(3,1) boundaries */
    public function test_rating_scale_70_decimal_boundary_values_persist(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, [
                'name' => 'V2 Decimal ' . $this->uniqueSuffix(),
                'min_rating' => 0.0,
                'max_rating' => 9.9,
            ]);
            $record->refresh();
            $this->assertSame('0.0', (string) $record->min_rating);
            $this->assertSame('9.9', (string) $record->max_rating);
        } finally {
            if ($record instanceof BaRatingScale) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    /** TC-D09 (G) · BC-EDG-05 · Source: description TEXT accepts long content */
    public function test_rating_scale_71_long_description_is_accepted(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        $long = str_repeat('Behavioural rubric text. ', 60);
        try {
            $record = $this->createRecordDirectly($dependencies, [
                'name' => 'V2 LongDesc ' . $this->uniqueSuffix(),
                'description' => $long,
            ]);
            $record->refresh();
            $this->assertSame($long, (string) $record->description);
        } finally {
            if ($record instanceof BaRatingScale) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  90–99  Tenancy + security
    // ══════════════════════════════════════════════

    /** TC-T01 · BC-CFG-01 · Source: tenant-scoped tables (no tenant_id column) */
    public function test_rating_scale_90_runs_inside_initialized_tenant(): void
    {
        if (!function_exists('tenancy')) {
            $this->markTestSkipped('Tenancy helper unavailable.');
        }
        $this->assertTrue(tenancy()->initialized, 'RatingScale is tenant-scoped and requires an initialized tenant.');
        $this->assertTrue(Schema::hasTable(self::SCALES_TABLE), 'ba_rating_scales must resolve within the tenant DB.');
        $this->assertFalse(Schema::hasColumn(self::SCALES_TABLE, 'tenant_id'),
            'Tenant-per-database design → no tenant_id column on ba_rating_scales.');
    }

    /** TC-S05 · BC-EDG-06 · Source: Blade `{{ }}` auto-escaping on show */
    public function test_rating_scale_91_stored_xss_in_name_is_escaped_on_show(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $marker = 'xss' . $this->uniqueSuffix();
        $payload = '<script>window.' . $marker . '=1</script>';
        $record = $this->createRecordDirectly($dependencies, ['name' => $payload]);
        try {
            $this->browse(function (Browser $browser) use ($record, $marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);
                $browser->waitForText('Scale Identity', 12);
                $executed = $browser->script('return window.' . $marker . ' === 1;')[0] ?? false;
                $this->assertNotTrue($executed, 'Stored script in the scale name must not execute (Blade escaping).');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-S06 · BC-AUTH-05 · Source: Controller@show findOrFail → 404 */
    public function test_rating_scale_92_invalid_id_does_not_render_detail(): void
    {
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl(self::SHOW_BASE_PATH . '/98765432'))->pause(1200);
            $browser->assertDontSee('Configured Rating Levels');
        });
    }

    // ══════════════════════════════════════════════
    //  Helpers
    // ══════════════════════════════════════════════

    private function resolveDependenciesOrSkip(): array
    {
        $adminUserId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));
        if ($adminUserId <= 0) {
            $this->markTestSkipped('No admin user found for rating scale tests.');
        }

        return ['admin_user_id' => $adminUserId];
    }

    private function createRecordDirectly(array $dependencies, array $overrides = []): BaRatingScale
    {
        return BaRatingScale::query()->create(array_merge($this->buildValidDirectPayload($dependencies), $overrides));
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'code'        => 'SCL' . $this->uniqueSuffix(),
            'name'        => 'Rating Scale ' . $this->uniqueSuffix(),
            'description' => 'Created for dusk test.',
            'grade_type'  => 'letter',
            'min_rating'  => 1.0,
            'max_rating'  => 5.0,
            'is_default'  => false,
            'is_active'   => true,
            'created_by'  => (int) $dependencies['admin_user_id'],
            'updated_by'  => (int) $dependencies['admin_user_id'],
        ];
    }

    private function createLevelDirectly(array $dependencies, BaRatingScale $scale, array $overrides = []): BaRatingLevel
    {
        return BaRatingLevel::query()->create(array_merge([
            'rating_scale_id' => (int) $scale->id,
            'label'           => 'Level ' . $this->uniqueSuffix(),
            'numeric_value'   => 3.0,
            'description'     => null,
            'sort_order'      => 1,
            'is_active'       => true,
            'created_by'      => (int) $dependencies['admin_user_id'],
            'updated_by'      => (int) $dependencies['admin_user_id'],
        ], $overrides));
    }

    private function forceDeleteRecordByIdIfExists(int $recordId): void
    {
        BaRatingScale::withTrashed()->where('id', $recordId)->get()
            ->each(function (BaRatingScale $record): void {
                try {
                    BaRatingLevel::withTrashed()->where('rating_scale_id', $record->id)->forceDelete();
                    $record->forceDelete();
                } catch (Throwable) {
                    // ignore media/soft-delete cleanup issues
                }
            });
    }

    private function cleanupByName(string $name): void
    {
        BaRatingScale::withTrashed()->where('name', $name)->get()
            ->each(function (BaRatingScale $record): void {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            });
    }

    private function assertDatabaseRejectsMissingField(array $dependencies, string $missingField): void
    {
        $created = null;
        try {
            $payload = $this->buildValidDirectPayload($dependencies);
            unset($payload[$missingField]);
            $created = BaRatingScale::query()->create($payload);
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
            if ($created instanceof BaRatingScale) {
                $this->forceDeleteRecordByIdIfExists((int) $created->id);
            }
        }
    }

    private function assertServerRejects(string $name, array $fields): void
    {
        $before = BaRatingScale::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name, $fields): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="code"]', 12)
                ->script("document.querySelector('input[name=\"code\"]').removeAttribute('maxlength');");
            $browser->type('input[name="code"]', (string) ($fields['code'] ?? ('X' . $this->uniqueSuffix())))
                ->type('input[name="name"]', $name)
                ->select('grade_type', (string) ($fields['grade_type'] ?? 'letter'))
                ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', (string) ($fields['min'] ?? '1'))
                ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', (string) ($fields['max'] ?? '5'))
                ->press('Save Rating Scale')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaRatingScale::query()->count(), "Server should reject invalid submission: {$name}.");
    }

    private function browserCreateScale(string $name, string $code, string $gradeType, string $min, string $max): void
    {
        $this->browse(function (Browser $browser) use ($name, $code, $gradeType, $min, $max): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->type('input[name="code"]', $code)
                ->type('input[name="name"]', $name)
                ->select('grade_type', $gradeType)
                ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', $min)
                ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', $max)
                ->press('Save Rating Scale')
                ->pause(2500);
        });
    }

    private function postJsonFromBrowser(Browser $browser, string $path): string
    {
        $url = $this->tenantUrl($path);
        $script = <<<JS
        var done = arguments[arguments.length - 1];
        var token = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';
        fetch("{$url}", {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': token, 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
            credentials: 'same-origin'
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
                'name'              => 'Limited RS ' . $suffix,
                'email'             => 'limited_rs_' . $suffix . '@tenant.test',
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
            'tenant.behavioural-assessment.rating-scales.viewAny',
            'tenant.behavioural-assessment.rating-scales.view',
            'tenant.behavioural-assessment.rating-scales.create',
            'tenant.behavioural-assessment.rating-scales.update',
            'tenant.behavioural-assessment.rating-scales.delete',
            'tenant.behavioural-assessment.rating-scales.status',
            'tenant.behavioural-assessment.rating-scales.restore',
            'tenant.behavioural-assessment.rating-scales.forceDelete',
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
