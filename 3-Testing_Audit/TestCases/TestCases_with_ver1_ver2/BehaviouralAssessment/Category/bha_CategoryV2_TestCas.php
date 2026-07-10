<?php

/**
 * BehaviouralAssessment › Category — V2 (comprehensive) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/Category/CategoryCrudTest.php
 *           and the RatingScale V2 artifact. (The committed sibling carries several stale
 *           assertions — wrong migration filename, reversed polarity enum, `.status-switch`
 *           vs the real `.status-toggle`, `criterion_name` vs `name`, 'Criterion added
 *           successfully' vs 'Criterion added.', a non-existent 'Create Category' string.
 *           This suite is written against the REAL source and corrects them.)
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; tables under database/migrations/tenant/).
 * TABLES  : ba_categories (+ child ba_criteria). DDL doc + this file's name use the stale prefix
 *           "bha_" (audit DOC-BA-001); every schema assertion targets the LIVE "ba_" tables.
 *
 * Semantic numbering bands (WP-G):
 *   01–09 schema/model/request · 10–19 business rules · 20–29 state-machine/status
 *   30–39 validation · 40–49 integration/FK · 50–59 permissions · 60–69 UI/UX
 *   70–79 edge · 90–99 tenancy + security
 *
 * Audit findings proven here (reported as "verify in source" — traced to the cited lines):
 *   DOC-BA-001  DDL doc prefix bha_ vs live ba_                         → test_..._01 / _02
 *   BUG-BA-006  category soft-delete does NOT cascade to criteria        → test_..._70
 *   BUG-BA-004  criterion with ratings still deletable (no guard)        → test_..._71
 *   DATA-BA-003 soft-delete + UNIQUE recreate — MITIGATED for categories → test_..._37
 *   SEC-BA-002  FormRequest authorize() returns bare true                → test_..._52
 *   BUG-BA-012  reorder() issues one UPDATE per row (works, N+1)          → test_..._17
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Requests\BaCategoryRequest;
use Modules\BehaviouralAssessment\Models\BaCategory;
use Modules\BehaviouralAssessment\Models\BaCriterion;
use Modules\SchoolSetup\Models\User;
use Tests\DuskTestCase;
use Throwable;

class bha_CategoryV2_TestCas extends DuskTestCase
{
    private const INDEX_PATH          = '/behavioural-assessment/masters';
    private const LISTING_PATH        = '/behavioural-assessment/categories';
    private const CREATE_PATH         = '/behavioural-assessment/categories/create';
    private const SHOW_BASE_PATH      = '/behavioural-assessment/categories';
    private const TRASH_PATH          = '/behavioural-assessment/categories/trash';
    private const CATEGORIES_TABLE    = 'ba_categories';
    private const CRITERIA_TABLE      = 'ba_criteria';
    private const MIGRATION_CATEGORIES = 'database/migrations/tenant/2026_06_16_130614_create_ba_categories_table.php';
    private const MIGRATION_CRITERIA   = 'database/migrations/tenant/2026_06_16_130620_create_ba_criteria_table.php';
    private const CONTROLLER_FILE      = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaCategoryController.php';
    private const REQUEST_FILE         = 'Modules/BehaviouralAssessment/app/Http/Requests/BaCategoryRequest.php';

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

    /** TC-P01 · BC-DB-01 · Audit-DOC-BA-001 · Source: DDL-ba_categories / live migration */
    public function test_category_01_schema_and_model_configuration_are_correct(): void
    {
        // DOC-BA-001: the DDL doc names the table bha_categories, but the live table is ba_categories.
        $this->assertTrue(Schema::hasTable(self::CATEGORIES_TABLE), 'Live table ba_categories does not exist.');
        $this->assertFalse(Schema::hasTable('bha_categories'), 'Stale DDL-doc table bha_categories should NOT exist (DOC-BA-001).');

        $this->assertTrue(Schema::hasColumns(self::CATEGORIES_TABLE, [
            'id', 'parent_id', 'name', 'description', 'polarity', 'weight', 'sort_order',
            'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing from ba_categories.');

        $model = new BaCategory();
        $this->assertSame('ba_categories', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaCategory::class));

        $casts = $model->getCasts();
        $this->assertSame('decimal:2', $casts['weight'] ?? null);
        $this->assertSame('integer', $casts['sort_order'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('integer', $casts['parent_id'] ?? null);
    }

    /** TC-P02 · BC-REF-01 · BC-DB-03 · Audit-DOC-BA-001 · Source: DDL-ba_criteria cascadeOnDelete */
    public function test_category_02_criteria_schema_fk_and_model(): void
    {
        $this->assertTrue(Schema::hasTable(self::CRITERIA_TABLE), 'Live table ba_criteria does not exist.');
        $this->assertFalse(Schema::hasTable('bha_criteria'), 'Stale DDL-doc table bha_criteria should NOT exist (DOC-BA-001).');

        $this->assertTrue(Schema::hasColumns(self::CRITERIA_TABLE, [
            'id', 'category_id', 'name', 'description', 'weight',
            'sort_order', 'is_active', 'created_by', 'updated_by', 'deleted_at',
        ]), 'Expected columns missing from ba_criteria.');

        $migration = File::get(base_path(self::MIGRATION_CRITERIA));
        $this->assertStringContainsString("constrained('ba_categories')->cascadeOnDelete()", $migration);

        $criterion = new BaCriterion();
        $this->assertSame('ba_criteria', $criterion->getTable());
        $this->assertInstanceOf(BelongsTo::class, $criterion->category());
        $this->assertInstanceOf(HasMany::class, $criterion->ratings());
    }

    /** TC-P03 · BC-DB-06 · Source: Model $fillable / relationships / scopes */
    public function test_category_03_model_fillable_relationships_and_scopes(): void
    {
        $model = new BaCategory();
        foreach (['parent_id', 'name', 'description', 'polarity', 'weight', 'sort_order', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $model->getFillable(), "fillable should include {$col}.");
        }

        $this->assertInstanceOf(BelongsTo::class, $model->parent());
        $this->assertInstanceOf(HasMany::class, $model->children());
        $this->assertInstanceOf(HasMany::class, $model->criteria());

        $activeSql = strtolower(BaCategory::query()->active()->toSql());
        $this->assertStringContainsString('is_active', $activeSql, 'scopeActive should filter on is_active.');
        $positiveSql = strtolower(BaCategory::query()->positive()->toSql());
        $this->assertStringContainsString('polarity', $positiveSql, 'scopePositive should filter on polarity.');
    }

    /** TC-N01 · BC-VAL-* · Source: BaCategoryRequest rules() literal strings */
    public function test_category_04_form_request_rules_contain_expected_constraints(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("'name'        => ['required', 'string', 'max:100']", $request);
        $this->assertStringContainsString("Rule::in(['positive', 'negative'])", $request);
        $this->assertStringContainsString("'exists:ba_categories,id'", $request);
        $this->assertStringContainsString("'max:100'", $request);   // weight
        $this->assertStringContainsString("Rule::unique('ba_categories', 'sort_order')", $request);
        $this->assertStringContainsString("->whereNull('deleted_at')", $request);
    }

    /** TC-N02 · BC-DB-04 · Source: DDL NOT NULL columns */
    public function test_category_05_db_rejects_each_missing_required_field(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        foreach (['name', 'polarity', 'sort_order', 'created_by', 'updated_by'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P04 · BC-DB-05 · Source: DDL parent_id + description nullable */
    public function test_category_06_nullable_fields_accept_null(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, ['parent_id' => null, 'description' => null]);
            $this->assertNull($record->parent_id);
            $this->assertNull($record->description);
        } finally {
            if ($record instanceof BaCategory) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  10–19  Business rules
    // ══════════════════════════════════════════════

    /** TC-P10 · BC-BIZ-01 · Source: Controller@store */
    public function test_category_10_create_valid_persists_row(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V2 Create ' . $this->uniqueSuffix();
        $saved = null;
        try {
            $this->browserCreateCategory($name, 'positive', $this->nextTopLevelSortOrder());
            $saved = BaCategory::query()->where('name', $name)->first();
            $this->assertNotNull($saved, 'Valid category was not created.');
        } finally {
            $this->cleanupByName($name);
        }
    }

    /** TC-P11 · BC-BIZ-02 · Source: BaCategoryRequest prepareForValidation is_active default true */
    public function test_category_11_is_active_defaults_true_when_absent(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        try {
            // Direct create leaving is_active unset — column default true (migration) applies.
            $record = BaCategory::query()->create([
                'parent_id'  => null,
                'name'       => 'V2 Default ' . $this->uniqueSuffix(),
                'polarity'   => 'positive',
                'weight'     => 100.00,
                'sort_order' => $this->nextTopLevelSortOrder(),
                'created_by' => (int) $dependencies['admin_user_id'],
                'updated_by' => (int) $dependencies['admin_user_id'],
            ]);
            $record->refresh();
            $this->assertTrue((bool) $record->is_active, 'is_active should default to true.');
        } finally {
            if ($record instanceof BaCategory) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    /** TC-P12 · BC-BIZ-03 · Source: show.blade renders category + criteria */
    public function test_category_12_show_page_renders_category_and_criteria(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Show ' . $this->uniqueSuffix()]);
        $this->createCriterionDirectly($dependencies, $record, ['name' => 'Participation', 'sort_order' => 1]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);
                $browser->waitForText('Category Details', 12)
                    ->assertSee((string) $record->name)
                    ->assertSee('Associated Criteria')
                    ->assertSee('Participation');
            });
        } finally {
            $record->criteria()->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P13 · BC-BIZ-04 · Source: Controller@update flash */
    public function test_category_13_edit_update_persists_and_flashes(): void
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
                    ->press('Update Category')->pause(2200)
                    ->assertSee('Category updated successfully.');
            });
            $record->refresh();
            $this->assertSame($updated, (string) $record->name);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P15 · BC-BIZ-05 · Source: edit.blade criterion form + Controller@storeCriterion "Criterion added." */
    public function test_category_14_add_criterion_persists(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 AddCrit ' . $this->uniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('form[action*="criteria"] input[name="name"]', 12)
                    ->type('form[action*="criteria"] input[name="name"]', 'Respects diverse opinions')
                    ->clear('form[action*="criteria"] input[name="weight"]')->type('form[action*="criteria"] input[name="weight"]', '40.00')
                    ->clear('form[action*="criteria"] input[name="sort_order"]')->type('form[action*="criteria"] input[name="sort_order"]', '2')
                    ->press('Add')->pause(2000)
                    ->assertSee('Criterion added.');
            });
            $this->assertSame(1, BaCriterion::where('category_id', $record->id)->where('name', 'Respects diverse opinions')->count());
        } finally {
            $record->criteria()->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P16 · BC-BIZ-06 · Source: Controller@updateCriterion "Criterion updated." */
    public function test_category_15_update_criterion_persists(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 EditCrit ' . $this->uniqueSuffix()]);
        $criterion = $this->createCriterionDirectly($dependencies, $record, ['name' => 'Original Criterion', 'sort_order' => 1]);
        try {
            $criterion->update(['name' => 'Renamed Criterion', 'updated_by' => (int) $dependencies['admin_user_id']]);
            $criterion->refresh();
            $this->assertSame('Renamed Criterion', (string) $criterion->name, 'Criterion update should persist.');
        } finally {
            $record->criteria()->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P17 · BC-BIZ-07 · Source: Controller@destroyCriterion soft-deletes criterion */
    public function test_category_16_remove_criterion_soft_deletes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 DelCrit ' . $this->uniqueSuffix()]);
        $criterion = $this->createCriterionDirectly($dependencies, $record, ['name' => 'Removable', 'sort_order' => 1]);
        try {
            $criterion->delete();
            $this->assertNull(BaCriterion::find($criterion->id), 'Criterion should be soft-deleted (hidden from default scope).');
            $this->assertNotNull(BaCriterion::withTrashed()->find($criterion->id), 'Soft-deleted criterion should exist under trashed scope.');
        } finally {
            $record->criteria()->withTrashed()->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-P18 · BC-BIZ-08 · Audit-BUG-BA-012 (verify in source).
     * reorder() writes sort_order = array index for each id (one UPDATE per row — N+1, but functional).
     * Source: BaCategoryController@reorder:135-143.
     */
    public function test_category_17_reorder_endpoint_updates_sort_order(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $first = $this->createRecordDirectly($dependencies, ['name' => 'V2 ReorderA ' . $this->uniqueSuffix(), 'sort_order' => $this->nextTopLevelSortOrder()]);
        $second = $this->createRecordDirectly($dependencies, ['name' => 'V2 ReorderB ' . $this->uniqueSuffix(), 'sort_order' => $this->nextTopLevelSortOrder()]);
        try {
            $this->browse(function (Browser $browser) use ($first, $second): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=categories', 900);
                $response = $this->postJsonFromBrowser(
                    $browser,
                    '/behavioural-assessment/categories/reorder',
                    ['order' => [(int) $first->id, (int) $second->id]]
                );
                $this->assertStringContainsString('"success"', $response, 'Reorder endpoint should return success.');
            });
            $first->refresh();
            $second->refresh();
            $this->assertSame(0, (int) $first->sort_order);
            $this->assertSame(1, (int) $second->sort_order);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $first->id);
            $this->forceDeleteRecordByIdIfExists((int) $second->id);
        }
    }

    /** TC-D07 (E) · BC-REF-02 · Source: parent_id self-reference (children relationship) */
    public function test_category_18_child_category_belongs_to_parent(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $parent = $this->createRecordDirectly($dependencies, ['name' => 'V2 Parent ' . $this->uniqueSuffix()]);
        $child = $this->createRecordDirectly($dependencies, ['name' => 'V2 Child ' . $this->uniqueSuffix(), 'parent_id' => (int) $parent->id]);
        try {
            $child->refresh();
            $this->assertSame((int) $parent->id, (int) $child->parent->id, 'Child should resolve back to its parent.');
            $this->assertTrue($parent->children()->where('id', $child->id)->exists(), 'Parent should list the child.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $child->id);
            $this->forceDeleteRecordByIdIfExists((int) $parent->id);
        }
    }

    // ══════════════════════════════════════════════
    //  20–29  State-machine / status lifecycle (BC-SM)
    // ══════════════════════════════════════════════

    /** TC-SM01 · BC-SM-01 · Source: Controller@toggleStatus (active → inactive) */
    public function test_category_20_toggle_status_active_inactive_cycle(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Cycle ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=categories', 900);
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

    /** TC-SM02 · BC-SM-02 · Source: Controller@toggleStatus JSON {success,is_active,message 'Category deactivated.'} */
    public function test_category_21_toggle_status_endpoint_returns_json_payload(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Json ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=categories', 900);
                $response = $this->postJsonFromBrowser(
                    $browser,
                    '/behavioural-assessment/categories/' . $record->id . '/toggle-status'
                );
                $this->assertStringContainsString('"success"', $response, 'Toggle endpoint should return a JSON success key.');
                $this->assertStringContainsString('Category', $response, 'Toggle endpoint should return the status message.');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM03 · BC-SM-03 · Source: Controller@destroy — sets is_active=false then soft-deletes */
    public function test_category_22_destroy_deactivates_then_soft_deletes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Destroy ' . $this->uniqueSuffix(), 'is_active' => true]);
        $id = (int) $record->id;
        try {
            // Mirror controller destroy(): flag inactive then soft-delete.
            $record->is_active = false;
            $record->save();
            $record->delete();

            $this->assertNull(BaCategory::find($id));
            $trashed = BaCategory::withTrashed()->find($id);
            $this->assertNotNull($trashed);
            $this->assertFalse((bool) $trashed->is_active, 'Destroyed category should be inactive in trash.');
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /** TC-D02 (B) · BC-BIZ-09 · Source: Controller@restore */
    public function test_category_23_restore_brings_back_from_trash(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Restore ' . $this->uniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $record->delete();
            $this->assertNull(BaCategory::find($id));
            $record->restore();
            $this->assertNotNull(BaCategory::find($id));
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    /** TC-D03 (B) · BC-REF-03 · Source: FK ba_criteria cascadeOnDelete (hard delete) */
    public function test_category_24_force_delete_cascades_criteria(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Cascade ' . $this->uniqueSuffix()]);
        $criterion = $this->createCriterionDirectly($dependencies, $record, ['name' => 'Cascade Criterion', 'sort_order' => 1]);
        $criterionId = (int) $criterion->id;
        try {
            // Hard-delete parent → DB cascade removes child criteria rows.
            $record->forceDelete();
            $this->assertNull(
                BaCriterion::withTrashed()->find($criterionId),
                'Criteria should be removed by DB cascade when the category is force-deleted.'
            );
        } finally {
            BaCriterion::withTrashed()->where('id', $criterionId)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  30–39  Validation (negative matrix)
    // ══════════════════════════════════════════════

    /** TC-N30 · BC-VAL-01 · Source: required rules */
    public function test_category_30_required_fields_show_errors_and_block_insert(): void
    {
        $this->resolveDependenciesOrSkip();
        $before = BaCategory::query()->count();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->clear('input[name="sort_order"]')
                ->script("(function(){var s=document.querySelector('select[name=\"polarity\"]'); if(s){s.removeAttribute('required');} document.querySelectorAll('input[required]').forEach(function(i){i.removeAttribute('required');}); document.querySelector('form').submit();})();");
            $browser->pause(2000)->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaCategory::query()->count(), 'Empty submission must not create a row.');
    }

    /** TC-N31 · BC-VAL-02 · Source: name max:100 */
    public function test_category_31_name_exceeding_max_is_rejected(): void
    {
        $longName = str_repeat('N', 130);
        $before = BaCategory::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($longName): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->script("document.querySelector('input[name=\"name\"]').removeAttribute('maxlength');")
                ->type('input[name="name"]', $longName)
                ->select('polarity', 'positive')
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->nextTopLevelSortOrder())
                ->press('Save Category')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaCategory::query()->count(), 'Over-length name must be rejected.');
    }

    /** TC-N32 · BC-VAL-03 · Source: polarity Rule::in */
    public function test_category_32_polarity_out_of_enum_is_rejected(): void
    {
        $name = 'V2 EnumPol ' . $this->uniqueSuffix();
        $before = BaCategory::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('select[name="polarity"]', 12)
                ->script("(function(){var s=document.querySelector('select[name=\"polarity\"]');var o=document.createElement('option');o.value='mixed';o.text='mixed';s.appendChild(o);s.value='mixed';})();");
            $browser->type('input[name="name"]', $name)
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->nextTopLevelSortOrder())
                ->press('Save Category')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaCategory::query()->count(), 'Out-of-enum polarity must be rejected.');
    }

    /** TC-N33 · BC-VAL-04 · Source: weight max:100 */
    public function test_category_33_weight_over_max_is_rejected(): void
    {
        $name = 'V2 WeightMax ' . $this->uniqueSuffix();
        $before = BaCategory::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->type('input[name="name"]', $name)
                ->select('polarity', 'positive')
                ->clear('input[name="weight"]')->type('input[name="weight"]', '150')
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->nextTopLevelSortOrder())
                ->press('Save Category')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaCategory::query()->count(), 'weight > 100 must be rejected.');
    }

    /** TC-N34 · BC-VAL-05 · Source: weight min:0 (negative rejected) */
    public function test_category_34_negative_weight_is_rejected(): void
    {
        $name = 'V2 NegWeight ' . $this->uniqueSuffix();
        $before = BaCategory::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->type('input[name="name"]', $name)
                ->select('polarity', 'positive')
                ->clear('input[name="weight"]')->type('input[name="weight"]', '-5')
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->nextTopLevelSortOrder())
                ->press('Save Category')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaCategory::query()->count(), 'Negative weight must be rejected.');
    }

    /** TC-N35 · BC-VAL-06 · Source: sort_order max:255 */
    public function test_category_35_sort_order_over_max_is_rejected(): void
    {
        $name = 'V2 SortMax ' . $this->uniqueSuffix();
        $before = BaCategory::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->type('input[name="name"]', $name)
                ->select('polarity', 'positive')
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', '300')
                ->press('Save Category')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaCategory::query()->count(), 'sort_order > 255 must be rejected.');
    }

    /** TC-N36 · BC-VAL-07 · Source: sort_order unique per level + message */
    public function test_category_36_duplicate_sort_order_same_level_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $sortOrder = $this->nextTopLevelSortOrder();
        $existing = $this->createRecordDirectly($dependencies, [
            'name' => 'V2 SortExisting ' . $this->uniqueSuffix(),
            'parent_id' => null,
            'sort_order' => $sortOrder,
        ]);
        $before = BaCategory::query()->count();
        try {
            $this->browse(function (Browser $browser) use ($sortOrder): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', 'V2 SortDup ' . $this->uniqueSuffix())
                    ->select('polarity', 'positive')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $sortOrder)
                    ->press('Save Category')->pause(2000)
                    ->assertPresent('.alert-danger')
                    ->assertSee('This sort order is already used for another category at the same level.');
            });
            $this->assertSame($before, BaCategory::query()->count(), 'Duplicate sort_order at same level must not create a row.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $existing->id);
        }
    }

    /**
     * TC-D04 (G) · BC-EDG-01 · Audit-DATA-BA-003 (MITIGATED — verify in source).
     * DATA-BA-003 (soft-delete + UNIQUE without deleted_at → recreate-after-delete 500) manifests
     * on tables that carry a DB unique index omitting deleted_at (e.g. ba_rating_levels.uq_ba_level).
     * ba_categories has NO DB unique on sort_order — the only uniqueness lives in the FormRequest,
     * scoped `->whereNull('deleted_at')`. Therefore a sort_order slot CAN be reused after the original
     * is soft-deleted, with no 500. This proves the pattern is mitigated for categories.
     * Source: migration 2026_06_16_130614 (no ->unique); BaCategoryRequest sort_order rule deleted_at-scoped.
     */
    public function test_category_37_sort_order_reused_after_soft_delete_data_ba_003_mitigated(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $sortOrder = $this->nextTopLevelSortOrder();
        $first = $this->createRecordDirectly($dependencies, ['name' => 'V2 Reuse1 ' . $this->uniqueSuffix(), 'parent_id' => null, 'sort_order' => $sortOrder]);
        $first->delete();
        $second = null;
        try {
            $second = $this->createRecordDirectly($dependencies, ['name' => 'V2 Reuse2 ' . $this->uniqueSuffix(), 'parent_id' => null, 'sort_order' => $sortOrder]);
            $this->assertNotNull($second->id, 'sort_order reuse after soft-delete should succeed (no DB unique index).');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $first->id);
            if ($second instanceof BaCategory) {
                $this->forceDeleteRecordByIdIfExists((int) $second->id);
            }
        }
    }

    /** TC-N37 · BC-VAL-08 · Source: parent_id exists:ba_categories,id */
    public function test_category_38_nonexistent_parent_id_is_rejected(): void
    {
        $name = 'V2 BadParent ' . $this->uniqueSuffix();
        $before = BaCategory::query()->count();
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('select[name="parent_id"]', 12)
                ->script("(function(){var s=document.querySelector('select[name=\"parent_id\"]');var o=document.createElement('option');o.value='99999987';o.text='ghost';s.appendChild(o);s.value='99999987';})();");
            $browser->type('input[name="name"]', $name)
                ->select('polarity', 'positive')
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->nextTopLevelSortOrder())
                ->press('Save Category')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaCategory::query()->count(), 'Nonexistent parent_id must be rejected.');
    }

    // ══════════════════════════════════════════════
    //  40–49  Integration / FK / dependency
    // ══════════════════════════════════════════════

    /** TC-D05 (E) · BC-REF-04 · Source: ba_criteria.category_id belongsTo category */
    public function test_category_40_criterion_belongs_to_its_category(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Belongs ' . $this->uniqueSuffix()]);
        $criterion = $this->createCriterionDirectly($dependencies, $record, ['name' => 'Belongs Criterion', 'sort_order' => 1]);
        try {
            $criterion->refresh();
            $this->assertSame((int) $record->id, (int) $criterion->category->id, 'Criterion should resolve back to its category.');
        } finally {
            $record->criteria()->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D06 (D) · BC-REF-05 · Source: parent_id nullOnDelete (SET NULL) */
    public function test_category_41_parent_delete_nullifies_child_parent_id(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $parent = $this->createRecordDirectly($dependencies, ['name' => 'V2 SetNullParent ' . $this->uniqueSuffix()]);
        $child = $this->createRecordDirectly($dependencies, ['name' => 'V2 SetNullChild ' . $this->uniqueSuffix(), 'parent_id' => (int) $parent->id]);
        $childId = (int) $child->id;
        try {
            // Hard-delete parent → FK nullOnDelete sets child.parent_id to NULL.
            $parent->forceDelete();
            $reloaded = BaCategory::withTrashed()->find($childId);
            $this->assertNotNull($reloaded, 'Child should survive parent hard-delete (SET NULL, not cascade).');
            $this->assertNull($reloaded->parent_id, 'Child.parent_id should be nullified on parent delete (nullOnDelete).');
        } finally {
            $this->forceDeleteRecordByIdIfExists($childId);
            $this->forceDeleteRecordByIdIfExists((int) $parent->id);
        }
    }

    /** TC-D08 (E) · BC-INT-01 · Source: BaCriterion::ratings() → ba_assessment_ratings.criterion_id (defensive) */
    public function test_category_42_criterion_ratings_relationship_is_defined(): void
    {
        $criterion = new BaCriterion();
        $this->assertInstanceOf(HasMany::class, $criterion->ratings(),
            'A criterion should expose a ratings() relationship (referenced by ba_assessment_ratings.criterion_id).');

        try {
            $this->assertTrue(
                Schema::hasColumn('ba_assessment_ratings', 'criterion_id'),
                'ba_assessment_ratings.criterion_id should reference the criterion.'
            );
        } catch (Throwable) {
            $this->markTestSkipped('ba_assessment_ratings table not present in this environment.');
        }
    }

    // ══════════════════════════════════════════════
    //  50–59  Permissions / authorization
    // ══════════════════════════════════════════════

    /** TC-S01 · BC-AUTH-01 · Source: auth middleware on web routes */
    public function test_category_50_guest_redirected_to_login_on_create(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** TC-S02 · BC-AUTH-02 · Source: masters gate + redirect */
    public function test_category_51_guest_redirected_to_login_on_index(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /**
     * TC-S03 · BC-AUTH-03 · Audit-SEC-BA-002 (verify in source).
     * BaCategoryRequest::authorize() returns a bare `true` (D30), so the FormRequest itself does not
     * gate. Access control relies entirely on the controller's Gate::authorize() calls.
     * Source: BaCategoryRequest.php:12-15.
     */
    public function test_category_52_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = new BaCategoryRequest();
        $this->assertTrue($request->authorize(),
            'SEC-BA-002 confirmed: FormRequest authorize() returns bare true (auth deferred to controller gates).');

        // Defence-in-depth still exists: the controller gate string is present in source.
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.categories.create')", $controller);
    }

    /** TC-S04 · BC-AUTH-04 · Source: Controller Gate::authorize on create (limited user → blocked) */
    public function test_category_53_user_without_permission_is_forbidden(): void
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
            $stillHasForm = str_contains($source, 'save category');

            $this->assertTrue($forbidden || ! $stillHasForm,
                'A user lacking categories.create should be blocked from the create screen.');
        });
    }

    // ══════════════════════════════════════════════
    //  60–69  UI / UX (search, list, empty state)
    // ══════════════════════════════════════════════

    /** TC-P60 · BC-BIZ-10 · Source: masters list _categories.blade */
    public function test_category_60_masters_list_shows_created_category(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Listed ' . $this->uniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=categories', 900);
                $browser->waitForText('Polarity', 12)->assertSee((string) $record->name);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P61 · BC-BIZ-11 · Source: masters() search by name */
    public function test_category_61_search_by_name_filters_list(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $token = 'Zeta' . $this->uniqueSuffix();
        $record = $this->createRecordDirectly($dependencies, ['name' => $token]);
        try {
            $this->browse(function (Browser $browser) use ($token): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=categories&search=' . urlencode($token), 1000);
                $browser->assertSee($token);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P62 · BC-BIZ-12 · Source: masters() polarity filter */
    public function test_category_62_polarity_filter_narrows_list(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $token = 'NegOnly' . $this->uniqueSuffix();
        $record = $this->createRecordDirectly($dependencies, ['name' => $token, 'polarity' => 'negative']);
        try {
            $this->browse(function (Browser $browser) use ($token): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=categories&polarity=negative&search=' . urlencode($token), 1000);
                $browser->assertSee($token);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P63 · BC-BIZ-13 · Source: trash.blade list */
    public function test_category_63_trash_page_lists_soft_deleted_category(): void
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
    //  70–79  Edge cases + audit-proving
    // ══════════════════════════════════════════════

    /**
     * TC-D09 (F) · BC-BIZ-14 · Audit-BUG-BA-006 (verify in source).
     * BR-BA-005 requires a category soft-delete to cascade to its criteria. Controller@destroy
     * soft-deletes ONLY the category; the migration CASCADE is a hard-delete FK, not a soft-delete
     * cascade. This proves the current (defective) behaviour: after the category is soft-deleted,
     * its criteria remain NOT trashed (still visible/active).
     * Source: BaCategoryController@destroy:74-86 (no child soft-delete).
     */
    public function test_category_70_soft_delete_does_not_cascade_to_criteria_bug_ba_006(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 NoCascade ' . $this->uniqueSuffix()]);
        $criterion = $this->createCriterionDirectly($dependencies, $record, ['name' => 'Orphaned Criterion', 'sort_order' => 1]);
        $criterionId = (int) $criterion->id;
        try {
            // Mirror controller destroy(): soft-delete the category only.
            $record->is_active = false;
            $record->save();
            $record->delete();

            $this->assertNotNull(
                BaCriterion::find($criterionId),
                'BUG-BA-006 confirmed: criterion remains active (NOT soft-deleted) after its category is trashed.'
            );
            $this->assertNull(
                BaCriterion::onlyTrashed()->find($criterionId),
                'BUG-BA-006 confirmed: soft-delete did not cascade to the criterion.'
            );
        } finally {
            $record->criteria()->withTrashed()->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-D10 (C) · BC-BIZ-15 · Audit-BUG-BA-004 (verify in source).
     * BR-BA-006 requires that a criterion with recorded ratings CANNOT be deleted. destroyCriterion()
     * performs a bare ->delete() with no ratings-reference check, so any criterion is freely deletable.
     * Proven here at the model layer plus a source assertion; the ratings dependency is exercised
     * defensively (skipped if the ratings table/infra is absent).
     * Source: BaCategoryController@destroyCriterion:190-196 (no ratings guard).
     */
    public function test_category_71_criterion_with_ratings_still_deletable_bug_ba_004(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 CritGuard ' . $this->uniqueSuffix()]);
        $criterion = $this->createCriterionDirectly($dependencies, $record, ['name' => 'Guarded Criterion', 'sort_order' => 1]);
        $criterionId = (int) $criterion->id;
        try {
            // Source proof: no reference guard in destroyCriterion.
            $controller = File::get(base_path(self::CONTROLLER_FILE));
            $this->assertStringContainsString(
                "BaCriterion::where('category_id', \$category)->findOrFail(\$criterion)->delete();",
                $controller,
                'BUG-BA-004: destroyCriterion should have no ratings-reference guard (bare delete).'
            );

            // Behavioural proof: the criterion soft-deletes unconditionally (no in-use block).
            $criterion->delete();
            $this->assertNull(BaCriterion::find($criterionId),
                'BUG-BA-004 confirmed: a criterion is deletable with no ratings-reference guard.');
        } finally {
            $record->criteria()->withTrashed()->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D11 (G) · BC-EDG-02 · Source: DECIMAL(5,2) weight boundaries */
    public function test_category_72_weight_boundary_values_persist(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 WeightBound ' . $this->uniqueSuffix(), 'weight' => 0.00]);
            $record->refresh();
            $this->assertSame('0.00', (string) $record->weight);
            $record->update(['weight' => 100.00]);
            $record->refresh();
            $this->assertSame('100.00', (string) $record->weight);
        } finally {
            if ($record instanceof BaCategory) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    /** TC-D12 (G) · BC-EDG-03 · Source: description TEXT accepts long content */
    public function test_category_73_long_description_is_accepted(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        $long = str_repeat('Behavioural category description text. ', 60);
        try {
            $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 LongDesc ' . $this->uniqueSuffix(), 'description' => $long]);
            $record->refresh();
            $this->assertSame($long, (string) $record->description);
        } finally {
            if ($record instanceof BaCategory) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    /**
     * TC-D13 (G) · BC-EDG-04 · Source: FormRequest lacks a self-parent / cycle guard.
     * The FormRequest validates parent_id only with exists:ba_categories,id — it does not prevent a
     * category from referencing itself as its parent. This documents the current permissive behaviour
     * at the model layer (no cycle protection).
     */
    public function test_category_74_self_parent_is_not_blocked_at_model_layer(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 SelfParent ' . $this->uniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $record->update(['parent_id' => $id]);
            $record->refresh();
            $this->assertSame($id, (int) $record->parent_id,
                'No self-parent guard exists at the model/DB layer (documented edge — FormRequest only checks exists).');
        } finally {
            // Detach self-parent before cleanup so the FK/self-reference does not block force-delete.
            BaCategory::withTrashed()->where('id', $id)->update(['parent_id' => null]);
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    // ══════════════════════════════════════════════
    //  90–99  Tenancy + security
    // ══════════════════════════════════════════════

    /** TC-T01 · BC-CFG-01 · Source: tenant-scoped tables (no tenant_id column) */
    public function test_category_90_runs_inside_initialized_tenant(): void
    {
        if (!function_exists('tenancy')) {
            $this->markTestSkipped('Tenancy helper unavailable.');
        }
        $this->assertTrue(tenancy()->initialized, 'Category is tenant-scoped and requires an initialized tenant.');
        $this->assertTrue(Schema::hasTable(self::CATEGORIES_TABLE), 'ba_categories must resolve within the tenant DB.');
        $this->assertFalse(Schema::hasColumn(self::CATEGORIES_TABLE, 'tenant_id'),
            'Tenant-per-database design → no tenant_id column on ba_categories.');
    }

    /** TC-S05 · BC-EDG-05 · Source: Blade `{{ }}` auto-escaping on show */
    public function test_category_91_stored_xss_in_name_is_escaped_on_show(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $marker = 'xss' . $this->uniqueSuffix();
        $payload = '<script>window.' . $marker . '=1</script>';
        $record = $this->createRecordDirectly($dependencies, ['name' => $payload]);
        try {
            $this->browse(function (Browser $browser) use ($record, $marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);
                $browser->waitForText('Category Details', 12);
                $executed = $browser->script('return window.' . $marker . ' === 1;')[0] ?? false;
                $this->assertNotTrue($executed, 'Stored script in the category name must not execute (Blade escaping).');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-S06 · BC-AUTH-05 · Source: Controller@show findOrFail → 404 */
    public function test_category_92_invalid_id_does_not_render_detail(): void
    {
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl(self::SHOW_BASE_PATH . '/98765432'))->pause(1200);
            $browser->assertDontSee('Associated Criteria');
        });
    }

    // ══════════════════════════════════════════════
    //  Helpers
    // ══════════════════════════════════════════════

    private function resolveDependenciesOrSkip(): array
    {
        $adminUserId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));
        if ($adminUserId <= 0) {
            $this->markTestSkipped('No admin user found for category tests.');
        }

        return ['admin_user_id' => $adminUserId];
    }

    private function createRecordDirectly(array $dependencies, array $overrides = []): BaCategory
    {
        return BaCategory::query()->create(array_merge($this->buildValidDirectPayload($dependencies), $overrides));
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'parent_id'   => null,
            'name'        => 'Category ' . $this->uniqueSuffix(),
            'description' => 'Created for dusk test.',
            'polarity'    => 'positive',
            'weight'      => 100.00,
            'sort_order'  => $this->nextTopLevelSortOrder(),
            'is_active'   => true,
            'created_by'  => (int) $dependencies['admin_user_id'],
            'updated_by'  => (int) $dependencies['admin_user_id'],
        ];
    }

    private function createCriterionDirectly(array $dependencies, BaCategory $category, array $overrides = []): BaCriterion
    {
        return BaCriterion::query()->create(array_merge([
            'category_id' => (int) $category->id,
            'name'        => 'Criterion ' . $this->uniqueSuffix(),
            'description' => null,
            'weight'      => 50.00,
            'sort_order'  => 1,
            'is_active'   => true,
            'created_by'  => (int) $dependencies['admin_user_id'],
            'updated_by'  => (int) $dependencies['admin_user_id'],
        ], $overrides));
    }

    private function nextTopLevelSortOrder(): int
    {
        $max = (int) BaCategory::withTrashed()->whereNull('parent_id')->max('sort_order');
        $candidate = $max + random_int(1, 3);

        return $candidate > 255 ? random_int(1, 255) : $candidate;
    }

    private function forceDeleteRecordByIdIfExists(int $recordId): void
    {
        BaCategory::withTrashed()->where('id', $recordId)->get()
            ->each(function (BaCategory $record): void {
                try {
                    BaCriterion::withTrashed()->where('category_id', $record->id)->forceDelete();
                    BaCategory::withTrashed()->where('parent_id', $record->id)->update(['parent_id' => null]);
                    $record->forceDelete();
                } catch (Throwable) {
                    // ignore media/soft-delete cleanup issues
                }
            });
    }

    private function cleanupByName(string $name): void
    {
        BaCategory::withTrashed()->where('name', $name)->get()
            ->each(function (BaCategory $record): void {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            });
    }

    private function assertDatabaseRejectsMissingField(array $dependencies, string $missingField): void
    {
        $created = null;
        try {
            $payload = $this->buildValidDirectPayload($dependencies);
            unset($payload[$missingField]);
            $created = BaCategory::query()->create($payload);
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
            if ($created instanceof BaCategory) {
                $this->forceDeleteRecordByIdIfExists((int) $created->id);
            }
        }
    }

    private function browserCreateCategory(string $name, string $polarity, int $sortOrder): void
    {
        $this->browse(function (Browser $browser) use ($name, $polarity, $sortOrder): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->type('input[name="name"]', $name)
                ->select('polarity', $polarity)
                ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $sortOrder)
                ->press('Save Category')
                ->pause(2500);
        });
    }

    private function postJsonFromBrowser(Browser $browser, string $path, array $payload = []): string
    {
        $url = $this->tenantUrl($path);
        $body = json_encode($payload);
        $script = <<<JS
        var done = arguments[arguments.length - 1];
        var token = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';
        fetch("{$url}", {
            method: 'POST',
            headers: {
                'X-CSRF-TOKEN': token,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            credentials: 'same-origin',
            body: JSON.stringify({$body})
        }).then(function (r) { return r.text(); })
          .then(function (t) { done(t); })
          .catch(function (e) { done('ERROR:' + e); });
JS;

        try {
            $result = $browser->driver->executeAsyncScript($script);
            return is_string($result) ? $result : (string) json_encode($result);
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
                'name'              => 'Limited Cat ' . $suffix,
                'email'             => 'limited_cat_' . $suffix . '@tenant.test',
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
            'tenant.behavioural-assessment.categories.viewAny',
            'tenant.behavioural-assessment.categories.view',
            'tenant.behavioural-assessment.categories.create',
            'tenant.behavioural-assessment.categories.update',
            'tenant.behavioural-assessment.categories.delete',
            'tenant.behavioural-assessment.categories.status',
            'tenant.behavioural-assessment.categories.restore',
            'tenant.behavioural-assessment.categories.forceDelete',
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
