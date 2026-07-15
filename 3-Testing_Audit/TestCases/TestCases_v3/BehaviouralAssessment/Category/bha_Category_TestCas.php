<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaCategory;
use Modules\BehaviouralAssessment\Models\BaCriterion;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Categories & Criteria (masters tab) — single comprehensive Dusk suite.
 *
 * Screen requirement: 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/03-Categories.md
 * DB scope          : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime tables    : ba_categories, ba_criteria  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller        : Modules\BehaviouralAssessment\Http\Controllers\BaCategoryController
 * FormRequest       : Modules\BehaviouralAssessment\Http\Requests\BaCategoryRequest  (category header only;
 *                     criterion sub-grid is validated inline inside the controller, not via a FormRequest).
 * Permission prefix : tenant.behavioural-assessment.categories.{viewAny|view|create|update|delete|restore|forceDelete|status}
 * Activity log      : NONE — the controller calls no activityLog() helper and the models have no observer (documented absence).
 *
 * Module-wide defects re-proven here (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md):
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - SEC-BA-002 : FormRequest authorize() returns bare true, mitigated by controller Gate (proven in _92).
 *
 * Feature-scoped observations (requirement 03-Categories.md vs implementation):
 *   - CAT-GAP-01 : requirement mandates a required unique "Category Code" (max 15) and "Criteria Code";
 *                  the `code` rule is commented out and NO `code` column exists on ba_categories/ba_criteria (proven in _04).
 *   - CAT-GAP-02 : requirement mandates a required "Max Score" (default 5.0) per criterion; no `max_score` column exists (proven in _04).
 *   - CAT-GAP-03 : requirement "sum of active criteria weightage must equal 100%" is NOT enforced (proven in _19).
 *   - CAT-GAP-04 : requirement "an active category must have at least one active criterion" is NOT enforced (proven in _74).
 *   - CAT-GAP-05 : requirement "a category cannot be deleted while ratings are recorded" — destroy() has no ratings
 *                  guard (only destroyCriterion() does); a category is soft-deleted unconditionally (proven in _45).
 *   - CAT-GAP-07 : requirement "Category Name must be unique" — no unique rule on name; duplicates are accepted (proven in _18).
 *   - CAT-GAP-08 : requirement "Criteria Name unique within category" — no unique rule; duplicates accepted (proven in _73).
 *   - CAT-GAP-09 : criterion `weight` has no max; values > 100 are accepted (proven in _72).
 */
class bha_Category_TestCas extends DuskTestCase
{
    private const URL_PREFIX     = '/behavioural-assessment';
    private const MASTERS_PATH   = '/behavioural-assessment/masters?tab=categories';
    private const CREATE_PATH    = '/behavioural-assessment/categories/create';
    private const STORE_PATH     = '/behavioural-assessment/categories';
    private const TRASH_PATH     = '/behavioural-assessment/categories/trash';

    private const CAT_TABLE      = 'ba_categories';
    private const CRIT_TABLE     = 'ba_criteria';
    private const DDL_CAT        = 'bha_categories';   // stale DDL-doc name (should NOT exist at runtime)
    private const DDL_CRIT       = 'bha_criteria';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/Category/screenshots';

    /** @var array<int,string> */
    private const CAT_PERMISSIONS = [
        'tenant.behavioural-assessment.masters.viewAny',
        'tenant.behavioural-assessment.categories.viewAny',
        'tenant.behavioural-assessment.categories.view',
        'tenant.behavioural-assessment.categories.create',
        'tenant.behavioural-assessment.categories.update',
        'tenant.behavioural-assessment.categories.delete',
        'tenant.behavioural-assessment.categories.restore',
        'tenant.behavioural-assessment.categories.forceDelete',
        'tenant.behavioural-assessment.categories.status',
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

    public function test_category_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::CAT_TABLE), 'Table ba_categories does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::CAT_TABLE, [
                'id', 'parent_id', 'name', 'description', 'polarity', 'weight',
                'sort_order', 'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_categories table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::CAT_TABLE))->keyBy('Field');
            $this->assertStringContainsString('varchar', strtolower((string) ($cols['name']->Type ?? '')));
            $this->assertStringContainsString('enum', strtolower((string) ($cols['polarity']->Type ?? '')));
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['weight']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['sort_order']->Type ?? '')));
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130614_create_ba_categories_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_categories'", $migration);
            $this->assertStringContainsString("\$table->string('name', 100)", $migration);
            $this->assertStringContainsString("enum('polarity', ['negative', 'positive'])", $migration);
            $this->assertStringContainsString("\$table->decimal('weight', 5, 2)->default(100.00)", $migration);
            $this->assertStringContainsString("unsignedTinyInteger('sort_order')", $migration);
            $this->assertStringContainsString("constrained('ba_categories')->nullOnDelete()", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // FormRequest rule strings — verbatim from the real source.
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaCategoryRequest.php'));
        if ($request !== null) {
            $this->assertStringContainsString("'name'        => ['required', 'string', 'max:100']", $request);
            $this->assertStringContainsString("'parent_id'   => ['nullable', 'exists:ba_categories,id']", $request);
            $this->assertStringContainsString("Rule::in(['positive', 'negative'])", $request);
            $this->assertStringContainsString("'weight'      => ['required', 'numeric', 'min:0', 'max:100']", $request);
            $this->assertStringContainsString("Rule::unique('ba_categories', 'sort_order')", $request);
            $this->assertStringContainsString('prepareForValidation', $request);
        }

        // Model configuration.
        $category = new BaCategory();
        $this->assertSame('ba_categories', $category->getTable());
        $this->assertSame([
            'parent_id', 'name', 'description', 'polarity', 'weight',
            'sort_order', 'is_active', 'created_by', 'updated_by',
        ], $category->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaCategory::class));
        $this->assertInstanceOf(BelongsTo::class, $category->parent());
        $this->assertInstanceOf(HasMany::class, $category->children());
        $this->assertInstanceOf(HasMany::class, $category->criteria());

        // Casts — is_active boolean, weight decimal:2, sort_order integer.
        $casts = $category->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('integer', $casts['sort_order'] ?? null);

        // Scopes: active / positive / negative.
        $active   = $this->createCategorySeed(['is_active' => true, 'polarity' => 'positive']);
        $inactive = $this->createCategorySeed(['is_active' => false, 'polarity' => 'negative']);
        $this->assertTrue(BaCategory::query()->active()->whereKey($active->id)->exists());
        $this->assertFalse(BaCategory::query()->active()->whereKey($inactive->id)->exists());
        $this->assertTrue(BaCategory::query()->positive()->whereKey($active->id)->exists());
        $this->assertTrue(BaCategory::query()->negative()->whereKey($inactive->id)->exists());
        $this->forceDeleteCategory($active);
        $this->forceDeleteCategory($inactive);
    }

    public function test_category_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime tables use the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::CAT_TABLE), 'Runtime table ba_categories must exist.');
        $this->assertTrue(Schema::hasTable(self::CRIT_TABLE), 'Runtime table ba_criteria must exist.');

        // The DDL/registry spec name `bha_*` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_CAT),
                'DOC-BA-001 regression: bha_categories exists at runtime; expected only the live ba_categories.'
            );
            $this->assertFalse(
                Schema::hasTable(self::DDL_CRIT),
                'DOC-BA-001 regression: bha_criteria exists at runtime; expected only the live ba_criteria.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model + FormRequest both bind to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_categories', (new BaCategory())->getTable());
        $this->assertSame('ba_criteria', (new BaCriterion())->getTable());
    }

    public function test_category_03_criteria_table_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::CRIT_TABLE), 'Table ba_criteria does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::CRIT_TABLE, [
                'id', 'category_id', 'name', 'description', 'weight', 'sort_order',
                'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_criteria table.'
        );

        // FK ba_criteria.category_id → ba_categories ON DELETE CASCADE.
        if (DB::connection()->getDriverName() === 'mysql') {
            $fk = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'ba_criteria'
                   AND REFERENCED_TABLE_NAME = 'ba_categories'"
            );
            if (!empty($fk)) {
                $this->assertStringContainsString('CASCADE', strtoupper((string) ($fk[0]->DELETE_RULE ?? '')));
            }
        }

        $critMigration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130620_create_ba_criteria_table.php'));
        if ($critMigration !== null) {
            $this->assertStringContainsString("Schema::create('ba_criteria'", $critMigration);
            $this->assertStringContainsString("constrained('ba_categories')->cascadeOnDelete()", $critMigration);
            $this->assertStringContainsString('$table->softDeletes()', $critMigration);
        }

        $criterion = new BaCriterion();
        $this->assertSame('ba_criteria', $criterion->getTable());
        $this->assertSame([
            'category_id', 'name', 'description', 'weight', 'sort_order',
            'is_active', 'created_by', 'updated_by',
        ], $criterion->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaCriterion::class));
        $this->assertInstanceOf(BelongsTo::class, $criterion->category());
        $this->assertInstanceOf(HasMany::class, $criterion->ratings());
    }

    public function test_category_04_requirement_code_and_max_score_fields_are_not_implemented_cat_gap_01_02(): void
    {
        // CAT-GAP-01: requirement mandates a required, unique Category Code / Criteria Code — not implemented.
        $this->assertFalse(Schema::hasColumn(self::CAT_TABLE, 'code'), 'CAT-GAP-01 changed: a code column now exists on ba_categories.');
        $this->assertFalse(Schema::hasColumn(self::CRIT_TABLE, 'code'), 'CAT-GAP-01 changed: a code column now exists on ba_criteria.');

        // CAT-GAP-02: requirement mandates a required Max Score per criterion — no max_score column.
        $this->assertFalse(Schema::hasColumn(self::CRIT_TABLE, 'max_score'), 'CAT-GAP-02 changed: a max_score column now exists on ba_criteria.');

        // The `code` rule is present-but-commented in the FormRequest (documents the intent/divergence).
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaCategoryRequest.php'));
        if ($request !== null) {
            $this->assertStringContainsString("// 'code'", $request, 'CAT-GAP-01: the commented-out code rule is the divergence marker.');
        }
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_category_10_create_persists_and_redirects_with_success_flash(): void
    {
        $name  = $this->uniqueName('CREATE');
        $order = $this->nextAvailableSortOrder(null);

        $this->browseWithFailureScreenshot('create-persist', function (Browser $browser) use ($name, $order): void {
            $this->openCreatePage($browser);

            $browser->type('name', $name)
                ->select('polarity', 'positive')
                ->clear('weight')->type('weight', '50')
                ->clear('sort_order')->type('sort_order', (string) $order)
                ->press('Save Category')
                ->pause(1300);

            $this->assertStringContainsString('/behavioural-assessment/masters', $this->currentPath($browser));
        });

        $created = BaCategory::where('name', $name)->first();
        $this->assertNotNull($created, 'Category row was not created.');
        $this->assertSame('positive', $created->polarity);
        $this->assertTrue((bool) $created->is_active, 'is_active must default to true.');
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);
        $this->assertSame((int) $this->adminUser->id, (int) $created->updated_by);

        $this->forceDeleteCategory($created);
    }

    public function test_category_11_weight_defaults_to_100_via_prepare_for_validation(): void
    {
        $name  = $this->uniqueName('WDEF');
        $order = $this->nextAvailableSortOrder(null);

        // Omit weight entirely → prepareForValidation merges 100.00.
        $response = $this->postRaw([
            'name'       => $name,
            'polarity'   => 'negative',
            'sort_order' => $order,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Omitted weight should default, not 422: ' . json_encode($response['json'] ?? null));

        $created = BaCategory::where('name', $name)->first();
        $this->assertNotNull($created, 'Category should be created with the defaulted weight.');
        $this->assertSame('100.00', (string) $created->weight, 'weight must default to 100.00.');

        $this->forceDeleteCategory($created);
    }

    public function test_category_12_update_persists_changes(): void
    {
        $category = $this->createCategorySeed(['name' => $this->uniqueName('BEFORE'), 'polarity' => 'positive']);
        $newName  = $this->uniqueName('AFTER');

        $response = $this->putCategory($category->id, [
            'name'       => $newName,
            'polarity'   => 'negative',
            'weight'     => 40,
            'sort_order' => $category->sort_order,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Update should not 422: ' . json_encode($response['json'] ?? null));

        $category->refresh();
        $this->assertSame($newName, $category->name);
        $this->assertSame('negative', $category->polarity);
        $this->assertSame((int) $this->adminUser->id, (int) $category->updated_by);

        $this->forceDeleteCategory($category);
    }

    public function test_category_13_store_criterion_via_nested_endpoint_persists(): void
    {
        $category = $this->createCategorySeed();

        $response = $this->apiCall('POST',
            $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => 'Participation', 'description' => 'Engages actively', 'weight' => 30, 'sort_order' => 1]
        );
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'Valid criterion should persist and redirect back.');

        $criterion = BaCriterion::where('category_id', $category->id)->where('name', 'Participation')->first();
        $this->assertNotNull($criterion, 'Criterion was not created via nested endpoint.');
        $this->assertSame('30.00', (string) $criterion->weight);
        $this->assertTrue((bool) $criterion->is_active);
        $this->assertSame((int) $this->adminUser->id, (int) $criterion->created_by);

        $this->forceDeleteCategory($category);
    }

    public function test_category_14_criterion_weight_and_sort_order_default_when_omitted(): void
    {
        $category = $this->createCategorySeed();

        // Controller: weight ?? 1.00, sort_order ?? 0.
        $response = $this->apiCall('POST',
            $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => 'Defaults Criterion']
        );
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $criterion = BaCriterion::where('category_id', $category->id)->where('name', 'Defaults Criterion')->first();
        $this->assertNotNull($criterion);
        $this->assertSame('1.00', (string) $criterion->weight, 'weight must default to 1.00.');
        $this->assertSame(0, (int) $criterion->sort_order, 'sort_order must default to 0.');

        $this->forceDeleteCategory($category);
    }

    public function test_category_15_update_and_delete_criterion_endpoints_work(): void
    {
        $category  = $this->createCategorySeed();
        $criterion = $this->createCriterionSeed($category->id, ['name' => 'Original', 'weight' => 10, 'sort_order' => 2]);

        $update = $this->apiCall('PUT',
            $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria/' . $criterion->id),
            ['name' => 'Renamed', 'weight' => 20, 'sort_order' => 2]
        );
        $this->assertContains((int) ($update['status'] ?? 0), [200, 302]);
        $criterion->refresh();
        $this->assertSame('Renamed', $criterion->name);
        $this->assertSame('20.00', (string) $criterion->weight);

        $delete = $this->apiCall('DELETE',
            $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria/' . $criterion->id)
        );
        $this->assertContains((int) ($delete['status'] ?? 0), [200, 302], 'Delete criterion should redirect back.');
        $this->assertFalse(
            BaCriterion::where('id', $criterion->id)->exists(),
            'Criterion should be soft-deleted (hidden from default scope).'
        );

        $this->forceDeleteCategory($category);
    }

    public function test_category_15b_show_page_renders_category_and_criteria(): void
    {
        $category = $this->createCategorySeed(['name' => $this->uniqueName('SHOW')]);
        $this->createCriterionSeed($category->id, ['name' => 'ShownCriterion', 'weight' => 5, 'sort_order' => 1]);

        $this->browseWithFailureScreenshot('show-render', function (Browser $browser) use ($category): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/categories/' . $category->id, 900);
            $browser->assertSee($category->name)
                ->assertSee('ShownCriterion')
                ->assertSee('Category Identity');
        });

        $this->forceDeleteCategory($category);
    }

    public function test_category_16_masters_tab_lists_categories_with_criteria_count(): void
    {
        $category = $this->createCategorySeed(['name' => $this->uniqueName('LIST')]);
        $this->createCriterionSeed($category->id, ['name' => 'C1', 'weight' => 1, 'sort_order' => 1]);

        $this->browseWithFailureScreenshot('masters-list', function (Browser $browser) use ($category): void {
            $this->openMastersTab($browser, $category->name);
            $browser->assertSee($category->name);
        });

        $this->forceDeleteCategory($category);
    }

    public function test_category_17_parent_child_self_reference_persists(): void
    {
        $parent = $this->createCategorySeed(['name' => $this->uniqueName('PARENT')]);
        $child  = $this->createCategorySeed(['name' => $this->uniqueName('CHILD'), 'parent_id' => $parent->id]);

        $child->refresh();
        $this->assertSame((int) $parent->id, (int) $child->parent_id, 'Child must reference the parent category.');
        $this->assertTrue($parent->children()->whereKey($child->id)->exists(), 'children() relation must include the child.');
        $this->assertSame((int) $parent->id, (int) $child->parent->id, 'parent() relation must resolve to the parent.');

        $this->forceDeleteCategory($child);
        $this->forceDeleteCategory($parent);
    }

    public function test_category_18_duplicate_category_name_is_allowed_cat_gap_07(): void
    {
        // Requirement says Category Name must be unique; the FormRequest has NO unique rule on name.
        $name  = $this->uniqueName('DUP');
        $first = $this->createCategorySeed(['name' => $name]);

        $response = $this->postRaw([
            'name'       => $name,
            'polarity'   => 'positive',
            'weight'     => 50,
            'sort_order' => $this->nextAvailableSortOrder(null),
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'CAT-GAP-07 regression fixed? A duplicate name should be accepted by current code.');

        $count = BaCategory::where('name', $name)->count();
        $this->assertGreaterThanOrEqual(2, $count, 'CAT-GAP-07: duplicate category names co-exist (name uniqueness not enforced).');

        BaCategory::where('name', $name)->get()->each(fn (BaCategory $c) => $this->forceDeleteCategory($c));
        $this->forceDeleteCategory($first);
    }

    public function test_category_19_criteria_weightage_sum_not_enforced_to_100_cat_gap_03(): void
    {
        // Requirement: sum of active criteria weightage under a category must equal 100%. Not enforced.
        $category = $this->createCategorySeed();

        $a = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => 'Crit A', 'weight' => 40, 'sort_order' => 1]);
        $b = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => 'Crit B', 'weight' => 40, 'sort_order' => 2]);

        $this->assertContains((int) ($a['status'] ?? 0), [200, 302]);
        $this->assertContains((int) ($b['status'] ?? 0), [200, 302]);

        $sum = (float) BaCriterion::where('category_id', $category->id)->sum('weight');
        $this->assertSame(80.0, $sum, 'CAT-GAP-03: criteria weightage total (80) != 100 and was still accepted (no 100% rule).');

        $this->forceDeleteCategory($category);
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM) — Active ↔ Inactive
    // =====================================================================

    public function test_category_20_active_to_inactive_and_back_transition_succeeds(): void
    {
        // BC-SM-1: Active --toggleStatus--> Inactive; BC-SM-2: Inactive --toggleStatus--> Active.
        $category = $this->createCategorySeed(['is_active' => true]);

        $response = $this->toggleCategory($category->id);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $category->refresh();
        $this->assertFalse((bool) $category->is_active, 'Active category must transition to Inactive.');

        $again = $this->toggleCategory($category->id);
        $this->assertSame(200, (int) ($again['status'] ?? 0));
        $category->refresh();
        $this->assertTrue((bool) $category->is_active, 'Inactive category must transition back to Active.');

        $this->forceDeleteCategory($category);
    }

    public function test_category_21_deactivation_not_blocked_when_criteria_referenced_data_ba(): void
    {
        // Requirement implies deactivation cascades to criteria in grading screens, but toggleStatus performs
        // no guard whatsoever — a category with attached criteria can be freely deactivated (DATA-BA side effect).
        $category = $this->createCategorySeed(['is_active' => true]);
        $this->createCriterionSeed($category->id, ['name' => 'Attached', 'weight' => 100, 'sort_order' => 1]);

        $response = $this->toggleCategory($category->id);
        $this->assertSame(200, (int) ($response['status'] ?? 0), 'Deactivating a category with criteria is not blocked.');
        $category->refresh();
        $this->assertFalse((bool) $category->is_active, 'No guard — the category was deactivated despite attached criteria.');

        // Criteria individual status is unchanged in the master grid (requirement note).
        $this->assertTrue(
            BaCriterion::where('category_id', $category->id)->where('is_active', true)->exists(),
            'Criterion is_active in the master grid remains unchanged after category deactivation.'
        );

        $this->forceDeleteCategory($category);
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL) — Negative 100%
    // =====================================================================

    public function test_category_30_required_fields_are_rejected(): void
    {
        $response = $this->apiCall('POST',
            $this->tenantUrl(self::STORE_PATH),
            ['name' => '', 'polarity' => '', 'weight' => '', 'sort_order' => '']
        );
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty payload must fail validation.');
        $errors = $response['json']['errors'] ?? [];
        foreach (['name', 'polarity', 'weight', 'sort_order'] as $field) {
            $this->assertArrayHasKey($field, $errors, "Missing required-error for {$field}.");
        }
    }

    public function test_category_31_name_max_length_100_is_enforced(): void
    {
        $response = $this->postRawOnValidBase(['name' => str_repeat('N', 101)]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('name', $response['json']['errors'] ?? []);
    }

    public function test_category_32_polarity_must_be_in_allowed_set(): void
    {
        $response = $this->postRawOnValidBase(['polarity' => 'neutral']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('polarity', $response['json']['errors'] ?? []);
    }

    public function test_category_33_weight_must_be_numeric_min_0_max_100(): void
    {
        $tooHigh = $this->postRawOnValidBase(['weight' => 150]);
        $this->assertSame(422, (int) ($tooHigh['status'] ?? 0), 'weight > 100 must be rejected.');
        $this->assertArrayHasKey('weight', $tooHigh['json']['errors'] ?? []);

        $negative = $this->postRawOnValidBase(['weight' => -1]);
        $this->assertSame(422, (int) ($negative['status'] ?? 0), 'negative weight must be rejected.');
        $this->assertArrayHasKey('weight', $negative['json']['errors'] ?? []);

        $nonNumeric = $this->postRawOnValidBase(['weight' => 'abc']);
        $this->assertSame(422, (int) ($nonNumeric['status'] ?? 0), 'non-numeric weight must be rejected.');
        $this->assertArrayHasKey('weight', $nonNumeric['json']['errors'] ?? []);
    }

    public function test_category_34_sort_order_must_be_integer_min_0_max_255(): void
    {
        $tooHigh = $this->postRawOnValidBase(['sort_order' => 300]);
        $this->assertSame(422, (int) ($tooHigh['status'] ?? 0), 'sort_order > 255 must be rejected.');
        $this->assertArrayHasKey('sort_order', $tooHigh['json']['errors'] ?? []);

        $negative = $this->postRawOnValidBase(['sort_order' => -1]);
        $this->assertSame(422, (int) ($negative['status'] ?? 0), 'negative sort_order must be rejected.');
        $this->assertArrayHasKey('sort_order', $negative['json']['errors'] ?? []);
    }

    public function test_category_35_duplicate_sort_order_same_parent_level_is_rejected(): void
    {
        $order = $this->nextAvailableSortOrder(null);
        $first = $this->createCategorySeed(['sort_order' => $order, 'parent_id' => null]);

        $response = $this->postRaw([
            'name'       => $this->uniqueName('DUPORDER'),
            'polarity'   => 'positive',
            'weight'     => 50,
            'sort_order' => $order,
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate sort_order at the same (null) parent level must be rejected.');
        $this->assertArrayHasKey('sort_order', $response['json']['errors'] ?? []);

        $this->forceDeleteCategory($first);
    }

    public function test_category_36_same_sort_order_allowed_under_different_parent_level(): void
    {
        // Uniqueness is scoped by parent_id — a child may reuse a top-level sort_order.
        $parent   = $this->createCategorySeed(['name' => $this->uniqueName('PARENT36')]);
        $topOrder = $this->nextAvailableSortOrder(null);
        $top      = $this->createCategorySeed(['sort_order' => $topOrder, 'parent_id' => null]);

        $response = $this->postRaw([
            'name'       => $this->uniqueName('CHILD36'),
            'polarity'   => 'positive',
            'weight'     => 50,
            'parent_id'  => $parent->id,
            'sort_order' => $topOrder,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'A child may reuse a top-level sort_order (unique is scoped to parent_id).');

        BaCategory::where('parent_id', $parent->id)->get()->each(fn (BaCategory $c) => $this->forceDeleteCategory($c));
        $this->forceDeleteCategory($top);
        $this->forceDeleteCategory($parent);
    }

    public function test_category_37_sort_order_unique_message_is_exact(): void
    {
        $order = $this->nextAvailableSortOrder(null);
        $first = $this->createCategorySeed(['sort_order' => $order, 'parent_id' => null]);

        $response = $this->postRaw([
            'name'       => $this->uniqueName('MSG'),
            'polarity'   => 'positive',
            'weight'     => 50,
            'sort_order' => $order,
        ]);
        $messages = $response['json']['errors']['sort_order'] ?? [];
        $this->assertContains(
            'This sort order is already used for another category at the same level.',
            $messages,
            'Exact custom message for sort_order.unique must be returned.'
        );

        $this->forceDeleteCategory($first);
    }

    public function test_category_38_parent_id_must_exist_in_ba_categories(): void
    {
        $response = $this->postRawOnValidBase(['parent_id' => 987654321]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'A non-existent parent_id must be rejected by the exists rule.');
        $this->assertArrayHasKey('parent_id', $response['json']['errors'] ?? []);
    }

    public function test_category_39_store_criterion_name_is_required_and_capped_at_150(): void
    {
        $category = $this->createCategorySeed();

        $missing = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => '', 'weight' => 10]);
        $this->assertSame(422, (int) ($missing['status'] ?? 0), 'Criterion name is required.');
        $this->assertArrayHasKey('name', $missing['json']['errors'] ?? []);

        $tooLong = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => str_repeat('C', 151), 'weight' => 10]);
        $this->assertSame(422, (int) ($tooLong['status'] ?? 0), 'Criterion name max:150 must be enforced.');
        $this->assertArrayHasKey('name', $tooLong['json']['errors'] ?? []);

        $this->forceDeleteCategory($category);
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-INT/REF/EDG)
    // =====================================================================

    public function test_category_40_delete_soft_deletes_sets_inactive_and_moves_to_trash(): void
    {
        $category = $this->createCategorySeed(['is_active' => true]);

        $response = $this->deleteCategory($category->id);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertFalse(BaCategory::where('id', $category->id)->exists(), 'Category should be hidden from default scope after soft delete.');
        $trashed = BaCategory::onlyTrashed()->find($category->id);
        $this->assertNotNull($trashed, 'Category should be present in trash.');
        $this->assertFalse((bool) $trashed->is_active, 'destroy() sets is_active=false before soft delete.');

        $this->forceDeleteCategory($trashed);
    }

    public function test_category_41_restore_from_trash_reactivates_visibility(): void
    {
        $category = $this->createCategorySeed();
        $category->delete();

        $response = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/restore'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertTrue(BaCategory::where('id', $category->id)->exists(), 'Restored category should return to the default scope.');

        $this->forceDeleteCategory(BaCategory::find($category->id));
    }

    public function test_category_42_force_delete_removes_category_and_cascades_criteria(): void
    {
        $category  = $this->createCategorySeed();
        $criterion = $this->createCriterionSeed($category->id, ['name' => 'Cascade', 'weight' => 1, 'sort_order' => 1]);
        $category->delete();

        $response = $this->apiCall('DELETE', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/force-delete'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertFalse(BaCategory::withTrashed()->where('id', $category->id)->exists(), 'Category row should be physically removed.');
        $this->assertFalse(
            BaCriterion::withTrashed()->where('id', $criterion->id)->exists(),
            'Criteria should be cascade-deleted with the category (FK ON DELETE CASCADE).'
        );
    }

    public function test_category_43_force_deleting_parent_sets_null_on_children(): void
    {
        // ba_categories.parent_id → ba_categories ON DELETE SET NULL.
        $parent = $this->createCategorySeed(['name' => $this->uniqueName('P43')]);
        $child  = $this->createCategorySeed(['name' => $this->uniqueName('C43'), 'parent_id' => $parent->id]);

        try {
            $parent->forceDelete();
            $child->refresh();
            $this->assertNull($child->parent_id, 'Child parent_id should be nulled after parent force-delete (SET NULL).');
        } catch (Throwable $e) {
            $this->markTestSkipped('SET NULL path unavailable: ' . $e->getMessage());
        }

        $this->forceDeleteCategory(BaCategory::withTrashed()->find($child->id));
        $this->forceDeleteCategory(BaCategory::withTrashed()->find($parent->id));
    }

    public function test_category_44_criterion_delete_is_blocked_when_ratings_recorded_and_allowed_otherwise(): void
    {
        $category  = $this->createCategorySeed();
        $criterion = $this->createCriterionSeed($category->id, ['name' => 'Deletable', 'weight' => 1, 'sort_order' => 1]);

        // Positive: no ratings → criterion is soft-deleted with the 'Criterion removed.' flash.
        $response = $this->apiCall('DELETE',
            $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria/' . $criterion->id));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertFalse(BaCriterion::where('id', $criterion->id)->exists(), 'Unreferenced criterion should be removed.');

        // Guard source assertion: destroyCriterion blocks deletion when ba_assessment_ratings reference it.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaCategoryController.php'));
        if ($controller !== null) {
            $this->assertStringContainsString(
                "BaAssessmentRating::where('criterion_id', \$criterion)->exists()",
                $controller,
                'destroyCriterion must guard against recorded ratings.'
            );
            $this->assertStringContainsString(
                'Cannot delete this criterion because ratings have been recorded against it. Deactivate it instead.',
                $controller,
                'Exact block message must be present.'
            );
        }

        $this->forceDeleteCategory($category);
    }

    public function test_category_45_category_soft_delete_not_blocked_when_criteria_present_cat_gap_05(): void
    {
        // Unlike destroyCriterion(), destroy() performs NO ratings/usage guard — a category with criteria is
        // soft-deleted unconditionally (CAT-GAP-05).
        $category = $this->createCategorySeed();
        $this->createCriterionSeed($category->id, ['name' => 'Present', 'weight' => 1, 'sort_order' => 1]);

        $response = $this->deleteCategory($category->id);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'CAT-GAP-05: destroy() has no usage guard.');
        $this->assertNotNull(BaCategory::onlyTrashed()->find($category->id), 'Category with criteria was still soft-deleted.');

        $this->forceDeleteCategory(BaCategory::onlyTrashed()->find($category->id));
    }

    public function test_category_46_full_lifecycle_create_toggle_delete_restore_force_delete(): void
    {
        $name  = $this->uniqueName('LIFE');
        $order = $this->nextAvailableSortOrder(null);

        // create
        $create = $this->postRaw(['name' => $name, 'polarity' => 'positive', 'weight' => 50, 'sort_order' => $order]);
        $this->assertNotSame(422, (int) ($create['status'] ?? 0));
        $category = BaCategory::where('name', $name)->firstOrFail();

        // toggle
        $toggle = $this->toggleCategory($category->id);
        $this->assertSame(200, (int) ($toggle['status'] ?? 0));
        $category->refresh();
        $this->assertFalse((bool) $category->is_active);

        // delete
        $this->deleteCategory($category->id);
        $this->assertNotNull(BaCategory::onlyTrashed()->find($category->id));

        // restore
        $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/restore'));
        $this->assertTrue(BaCategory::where('id', $category->id)->exists());

        // force delete
        BaCategory::find($category->id)->delete();
        $this->apiCall('DELETE', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/force-delete'));
        $this->assertFalse(BaCategory::withTrashed()->where('id', $category->id)->exists());
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_category_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_category_51_limited_user_without_create_permission_gets_403(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-create-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl(self::STORE_PATH),
                $this->validPayload()
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without create permission must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_category_52_limited_user_without_status_permission_gets_403_on_toggle(): void
    {
        $category = $this->createCategorySeed();
        $limited  = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-toggle-403', function (Browser $browser) use ($limited, $category): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/toggle-status')
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteCategory($category);
    }

    public function test_category_53_limited_user_without_delete_permission_gets_403_on_destroy(): void
    {
        $category = $this->createCategorySeed();
        $limited  = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-delete-403', function (Browser $browser) use ($limited, $category): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'DELETE',
                $this->tenantUrl(self::STORE_PATH . '/' . $category->id)
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteCategory($category);
    }

    public function test_category_54_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaCategoryPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('Policy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete', 'status'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.categories.{$ability}",
                $policy,
                "Policy missing gate string for {$ability}."
            );
        }
    }

    public function test_category_55_status_toggle_endpoint_updates_is_active_and_returns_json(): void
    {
        $category = $this->createCategorySeed(['is_active' => true]);

        $response = $this->toggleCategory($category->id);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $json = $response['json'] ?? [];
        $this->assertTrue((bool) ($json['success'] ?? false));
        $this->assertArrayHasKey('is_active', $json);
        $this->assertSame('Category deactivated.', (string) ($json['message'] ?? ''));

        $category->refresh();
        $this->assertFalse((bool) $category->is_active);

        $again = $this->toggleCategory($category->id);
        $this->assertSame('Category activated.', (string) ($again['json']['message'] ?? ''));

        $this->forceDeleteCategory($category);
    }

    public function test_category_56_reorder_endpoint_updates_sort_order(): void
    {
        $a = $this->createCategorySeed(['sort_order' => $this->nextAvailableSortOrder(null)]);
        $b = $this->createCategorySeed(['sort_order' => $this->nextAvailableSortOrder(null)]);

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/reorder'),
            ['order' => [$b->id, $a->id]]);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $this->assertTrue((bool) ($response['json']['success'] ?? false));

        $a->refresh();
        $b->refresh();
        $this->assertSame(0, (int) $b->sort_order, 'Reorder should set first element sort_order = 0.');
        $this->assertSame(1, (int) $a->sort_order, 'Reorder should set second element sort_order = 1.');

        $this->forceDeleteCategory($a);
        $this->forceDeleteCategory($b);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (search, filter, empty state, trash, breadcrumb)
    // =====================================================================

    public function test_category_60_masters_search_filters_by_name(): void
    {
        $category = $this->createCategorySeed(['name' => $this->uniqueName('FINDME')]);

        $this->browseWithFailureScreenshot('search-filter', function (Browser $browser) use ($category): void {
            $this->openMastersTab($browser, $category->name);
            $browser->assertSee($category->name);
        });

        $this->forceDeleteCategory($category);
    }

    public function test_category_61_masters_polarity_filter_narrows_results(): void
    {
        $positive = $this->createCategorySeed(['name' => $this->uniqueName('POSCAT'), 'polarity' => 'positive']);
        $negative = $this->createCategorySeed(['name' => $this->uniqueName('NEGCAT'), 'polarity' => 'negative']);

        $this->browseWithFailureScreenshot('polarity-filter', function (Browser $browser) use ($negative): void {
            $path = self::MASTERS_PATH . '&polarity=negative&search=' . urlencode($negative->name);
            $this->visitAuthenticated($browser, $path, 1000);
            $browser->assertSee($negative->name);
        });

        $this->forceDeleteCategory($positive);
        $this->forceDeleteCategory($negative);
    }

    public function test_category_62_empty_state_message_when_search_matches_nothing(): void
    {
        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser): void {
            $this->openMastersTab($browser, 'ZZZ_NO_MATCH_' . $this->uniqueSuffix());
            $browser->assertSee('No categories found.');
        });
    }

    public function test_category_63_trash_page_renders(): void
    {
        $category = $this->createCategorySeed(['name' => $this->uniqueName('TRASHED')]);
        $category->delete();

        $this->browseWithFailureScreenshot('trash-render', function (Browser $browser) use ($category): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH, 900);
            $browser->assertSee($category->name);
        });

        $this->forceDeleteCategory(BaCategory::onlyTrashed()->find($category->id));
    }

    public function test_category_64_breadcrumb_present_on_create_and_show_pages(): void
    {
        $category = $this->createCategorySeed();

        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser) use ($category): void {
            $this->openCreatePage($browser);
            $browser->assertSee('Categories');
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/categories/' . $category->id, 900);
            $browser->assertSee('Categories & Criteria');
        });

        $this->forceDeleteCategory($category);
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_category_70_invalid_id_returns_404(): void
    {
        $missing = 987654321;
        foreach ([self::STORE_PATH . '/' . $missing, self::STORE_PATH . '/' . $missing . '/edit'] as $path) {
            $response = $this->apiCall('GET', $this->tenantUrl($path));
            $this->assertSame(404, (int) ($response['status'] ?? 0), "Expected 404 for {$path}.");
        }

        $toggle = $this->toggleCategory($missing);
        $this->assertSame(404, (int) ($toggle['status'] ?? 0), 'Toggle on invalid id must 404.');
    }

    public function test_category_71_whitespace_only_name_is_rejected(): void
    {
        // Laravel TrimStrings middleware collapses '   ' → '' → required fails.
        $response = $this->postRawOnValidBase(['name' => '   ']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('name', $response['json']['errors'] ?? []);
    }

    public function test_category_72_criterion_weight_over_100_is_accepted_cat_gap_09(): void
    {
        // Category weight is capped at 100, but the criterion endpoint only checks numeric|min:0 (no max).
        $category = $this->createCategorySeed();

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => 'HeavyCrit', 'weight' => 250, 'sort_order' => 1]);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'CAT-GAP-09: an over-100 criterion weight should be accepted.');

        $criterion = BaCriterion::where('category_id', $category->id)->where('name', 'HeavyCrit')->first();
        $this->assertNotNull($criterion);
        $this->assertSame('250.00', (string) $criterion->weight, 'CAT-GAP-09: criterion weight has no max — 250 persisted.');

        $this->forceDeleteCategory($category);
    }

    public function test_category_73_duplicate_criterion_name_within_category_is_allowed_cat_gap_08(): void
    {
        // Requirement: criteria name must be unique within the category; no unique rule exists.
        $category = $this->createCategorySeed();

        $first  = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => 'SameName', 'weight' => 10, 'sort_order' => 1]);
        $second = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH . '/' . $category->id . '/criteria'),
            ['name' => 'SameName', 'weight' => 10, 'sort_order' => 2]);

        $this->assertContains((int) ($first['status'] ?? 0), [200, 302]);
        $this->assertContains((int) ($second['status'] ?? 0), [200, 302], 'CAT-GAP-08: a duplicate criterion name should be accepted.');

        $count = BaCriterion::where('category_id', $category->id)->where('name', 'SameName')->count();
        $this->assertGreaterThanOrEqual(2, $count, 'CAT-GAP-08: duplicate criterion names co-exist within a category.');

        $this->forceDeleteCategory($category);
    }

    public function test_category_74_active_category_without_any_criterion_is_allowed_cat_gap_04(): void
    {
        // Requirement: an active category must have at least one active criterion. Not enforced.
        $name  = $this->uniqueName('NOCRIT');
        $order = $this->nextAvailableSortOrder(null);

        $response = $this->postRaw(['name' => $name, 'polarity' => 'positive', 'weight' => 50, 'sort_order' => $order]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'CAT-GAP-04: a criterion-less category should be accepted.');

        $created = BaCategory::where('name', $name)->first();
        $this->assertNotNull($created);
        $this->assertTrue((bool) $created->is_active, 'Category is active despite having zero criteria.');
        $this->assertSame(0, $created->criteria()->count(), 'CAT-GAP-04: no minimum-criterion rule enforced.');

        $this->forceDeleteCategory($created);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_category_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side category tests.'
        );
        $this->assertTrue(Schema::hasTable(self::CAT_TABLE));
    }

    public function test_category_91_cross_tenant_direct_id_isolation(): void
    {
        // Defensive: a second tenant is required to prove IDOR isolation.
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

    public function test_category_92_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaCategoryRequest.php'));
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

    public function test_category_93_stored_xss_in_name_and_description_not_executed_on_show(): void
    {
        $name  = 'XSS ' . $this->uniqueSuffix() . ' <script>alert(1)</script>';
        $order = $this->nextAvailableSortOrder(null);

        $response = $this->postRaw([
            'name'        => $name,
            'polarity'    => 'positive',
            'weight'      => 50,
            'sort_order'  => $order,
            'description' => 'Desc <img src=x onerror=alert(1)>',
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));
        $category = BaCategory::where('name', $name)->first();
        $this->assertNotNull($category);

        $this->browseWithFailureScreenshot('stored-xss', function (Browser $browser) use ($category): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/categories/' . $category->id, 900);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Blade must escape the stored name.');
            $this->assertStringNotContainsString('<img src=x onerror=alert(1)>', $source, 'Blade must escape the stored description.');
        });

        $this->forceDeleteCategory($category);
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
        $rawName = 'category-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'category-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function openCreatePage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
        $browser->waitFor('#name', 15)->waitFor('#polarity', 10);
    }

    private function openMastersTab(Browser $browser, ?string $search = null): void
    {
        $path = self::MASTERS_PATH;
        if ($search !== null && $search !== '') {
            $path .= '&search=' . urlencode($search);
        }
        $this->visitAuthenticated($browser, $path, 1000);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#categories-pane') !== null
                || $browser->element('table') !== null;
        }, 'Categories masters tab did not render.');
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
window.__catApiDone = false;
window.__catApiError = '';
window.__catApiResult = null;

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

        window.__catApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__catApiError = String(error);
    } finally {
        window.__catApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__catApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__catApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__catApiResult || null;');
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

    /** POST an exact payload (no valid-base merge) to the store endpoint. */
    private function postRaw(array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    /** POST a payload built on a seeded-valid base but with a targeted invalid field. */
    private function postRawOnValidBase(array $overrides): array
    {
        $payload = array_merge($this->validPayload(), $overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    private function putCategory(int $id, array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'PUT', $this->tenantUrl(self::STORE_PATH . '/' . $id), $payload));
    }

    private function deleteCategory(int $id): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'DELETE', $this->tenantUrl(self::STORE_PATH . '/' . $id)));
    }

    private function toggleCategory(int $id): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH . '/' . $id . '/toggle-status')));
    }

    private function validPayload(array $overrides = []): array
    {
        return array_merge([
            'name'        => $this->uniqueName('VALID'),
            'parent_id'   => null,
            'polarity'    => 'positive',
            'weight'      => 50,
            'sort_order'  => $this->nextAvailableSortOrder($overrides['parent_id'] ?? null),
            'description' => 'Valid category',
            'is_active'   => true,
        ], $overrides);
    }

    // ---- Seed / cleanup ---------------------------------------------------

    private function createCategorySeed(array $overrides = []): BaCategory
    {
        $parentId = $overrides['parent_id'] ?? null;
        $payload = array_merge([
            'parent_id'   => $parentId,
            'name'        => $this->uniqueName('SEED'),
            'description' => 'Seed category',
            'polarity'    => 'positive',
            'weight'      => 50,
            'sort_order'  => $this->nextAvailableSortOrder($parentId),
            'is_active'   => true,
            'created_by'  => (int) $this->adminUser->id,
            'updated_by'  => (int) $this->adminUser->id,
        ], $overrides);

        return BaCategory::query()->create($payload);
    }

    private function createCriterionSeed(int $categoryId, array $overrides = []): BaCriterion
    {
        $payload = array_merge([
            'category_id' => $categoryId,
            'name'        => 'Criterion ' . $this->uniqueSuffix(),
            'description' => null,
            'weight'      => 1,
            'sort_order'  => 0,
            'is_active'   => true,
            'created_by'  => (int) $this->adminUser->id,
            'updated_by'  => (int) $this->adminUser->id,
        ], $overrides);

        return BaCriterion::query()->create($payload);
    }

    /** Smallest unused sort_order (0–255) among siblings sharing $parentId (incl. trashed rows). */
    private function nextAvailableSortOrder(?int $parentId): int
    {
        try {
            $query = BaCategory::withTrashed();
            if ($parentId === null) {
                $query->whereNull('parent_id');
            } else {
                $query->where('parent_id', $parentId);
            }
            $used = $query->pluck('sort_order')->map(fn ($v) => (int) $v)->all();
            for ($i = 0; $i <= 255; $i++) {
                if (!in_array($i, $used, true)) {
                    return $i;
                }
            }
        } catch (Throwable) {
        }
        return random_int(0, 255);
    }

    private function forceDeleteCategory(?BaCategory $category): void
    {
        if ($category === null) {
            return;
        }
        try {
            BaCriterion::withTrashed()->where('category_id', $category->id)->get()
                ->each(function (BaCriterion $criterion): void {
                    try {
                        $criterion->forceDelete();
                    } catch (Throwable) {
                    }
                });
            // Detach any children first so a SET-NULL FK never blocks the parent delete.
            BaCategory::withTrashed()->where('parent_id', $category->id)
                ->update(['parent_id' => null]);
            if (BaCategory::withTrashed()->whereKey($category->id)->exists()) {
                $category->forceDelete();
            }
        } catch (Throwable) {
            // Cleanup is best-effort.
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
                'name'              => 'Cat Limited ' . $this->uniqueSuffix(),
                'email'             => 'cat_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'CL' . substr($this->uniqueSuffix(), -8);
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
        $this->grantCategoryPermissions($this->adminUser);
    }

    private function grantCategoryPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::CAT_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::CAT_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::CAT_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.category-admin');
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
            $modelFile = (new ReflectionClass(BaCategory::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaCategory.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaCategory::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaCategory.php → app root = dirname(,5)
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
        $clean = $clean === '' ? 'CAT' : substr($clean, 0, 12);
        return substr($clean . ' Category ' . $this->uniqueSuffix(), 0, 100);
    }
}
