<?php

/**
 * BehaviouralAssessment › Category — V1 (foundation) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/Category/CategoryCrudTest.php
 *           and the RatingScale V1/V2 artifacts. NOTE: the committed CategoryCrudTest carries
 *           several stale assertions (wrong migration filename, polarity enum order reversed,
 *           `.status-switch` vs the real `.status-toggle`, `criterion_name` vs the real `name`
 *           field, 'Criterion added successfully' vs the real 'Criterion added.', 'Create Category'
 *           text that the create view does not render). This suite is written against the REAL
 *           source and intentionally corrects those.
 * DB SCOPE : tenant-side (DDL header "Database: tenant_db"; tables live in database/migrations/tenant/).
 * TABLES   : ba_categories (+ child ba_criteria)  — the DDL doc uses the stale prefix "bha_"; the
 *            LIVE migrations/models/tables are "ba_" (audit DOC-BA-001). Artifact FILE names follow
 *            the DDL/inventory prefix "bha_"; every schema assertion targets the real "ba_" tables.
 *            Do not "fix" this to bha_ in code — it would break against the real DB.
 *
 * All routes/selectors/permissions/flash strings verified against:
 *   Modules/BehaviouralAssessment/app/Http/Controllers/BaCategoryController.php
 *   Modules/BehaviouralAssessment/app/Http/Requests/BaCategoryRequest.php
 *   Modules/BehaviouralAssessment/app/Models/{BaCategory,BaCriterion}.php
 *   Modules/BehaviouralAssessment/app/Policies/BaCategoryPolicy.php
 *   Modules/BehaviouralAssessment/routes/web.php
 *   Modules/BehaviouralAssessment/resources/views/category/{create,edit,show,trash}.blade.php
 *   Modules/BehaviouralAssessment/resources/views/pages/partials/masters/_categories.blade.php
 *   database/migrations/tenant/2026_06_16_130614_create_ba_categories_table.php
 *   database/migrations/tenant/2026_06_16_130620_create_ba_criteria_table.php
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

class bha_CategoryV1_TestCas extends DuskTestCase
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
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // ──────────────────────────────────────────────
    //  01–09  Schema / model / request configuration
    // ──────────────────────────────────────────────

    /** TC-P01 · BC-DB-01/02 · Source: DDL-ba_categories / live migration */
    public function test_category_01_schema_model_and_softdelete_are_correct(): void
    {
        // DOC-BA-001: the DDL doc names the table bha_categories, but the live table is ba_categories.
        $this->assertTrue(Schema::hasTable(self::CATEGORIES_TABLE), 'Table ba_categories does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::CATEGORIES_TABLE, [
                'id', 'parent_id', 'name', 'description', 'polarity',
                'weight', 'sort_order', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing from ba_categories.'
        );

        $migrationPath = base_path(self::MIGRATION_CATEGORIES);
        $this->assertTrue(File::exists($migrationPath), 'Migration not found: ' . self::MIGRATION_CATEGORIES);
        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('ba_categories'", $migration);
        // Real enum ORDER is ['negative', 'positive'] — the committed sibling asserts it reversed.
        $this->assertStringContainsString("\$table->enum('polarity', ['negative', 'positive'])", $migration);
        $this->assertStringContainsString("\$table->decimal('weight', 5, 2)", $migration);
        $this->assertStringContainsString("\$table->unsignedTinyInteger('sort_order')", $migration);
        $this->assertStringContainsString("nullOnDelete()", $migration);
        $this->assertStringContainsString("\$table->softDeletes()", $migration);

        $this->assertTrue(File::exists(base_path(self::CONTROLLER_FILE)), 'Controller file missing.');

        $model = new BaCategory();
        $this->assertSame('ba_categories', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaCategory::class));

        $casts = $model->getCasts();
        $this->assertSame('decimal:2', $casts['weight'] ?? null);
        $this->assertSame('integer', $casts['sort_order'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('integer', $casts['parent_id'] ?? null);

        $this->assertInstanceOf(BelongsTo::class, $model->parent());
        $this->assertInstanceOf(HasMany::class, $model->children());
        $this->assertInstanceOf(HasMany::class, $model->criteria());
    }

    /** TC-P02 · BC-DB-03 · BC-REF-01 · Source: DDL-ba_criteria FK cascadeOnDelete */
    public function test_category_02_criteria_schema_fk_and_model_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::CRITERIA_TABLE), 'Table ba_criteria does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::CRITERIA_TABLE, [
                'id', 'category_id', 'name', 'description', 'weight',
                'sort_order', 'is_active', 'created_by', 'updated_by', 'deleted_at',
            ]),
            'Expected columns are missing from ba_criteria.'
        );

        $migrationPath = base_path(self::MIGRATION_CRITERIA);
        $this->assertTrue(File::exists($migrationPath), 'Migration not found: ' . self::MIGRATION_CRITERIA);
        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('ba_criteria'", $migration);
        $this->assertStringContainsString("constrained('ba_categories')->cascadeOnDelete()", $migration);
        $this->assertStringContainsString("\$table->softDeletes()", $migration);

        $criterion = new BaCriterion();
        $this->assertSame('ba_criteria', $criterion->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaCriterion::class));
        $this->assertInstanceOf(BelongsTo::class, $criterion->category());
        $this->assertInstanceOf(HasMany::class, $criterion->ratings());
    }

    /** TC-N01 · BC-DB-04 · Source: DDL-ba_categories NOT NULL columns */
    public function test_category_03_db_rejects_missing_required_fields(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();

        foreach (['name', 'polarity', 'sort_order'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P03 · BC-DB-05 · Source: DDL parent_id + description nullable */
    public function test_category_04_nullable_fields_accept_null(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;

        try {
            $record = $this->createRecordDirectly($dependencies, [
                'parent_id'   => null,
                'description' => null,
            ]);
            $this->assertNotNull($record->id, 'Category with null parent/description did not save.');
            $this->assertNull($record->parent_id);
            $this->assertNull($record->description);
        } finally {
            if ($record instanceof BaCategory) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ──────────────────────────────────────────────
    //  10–19  Core CRUD / business behaviour
    // ──────────────────────────────────────────────

    /** TC-P10 · BC-BIZ-01 · Source: create.blade sections + Save Category button */
    public function test_category_10_create_page_loads_and_shows_sections(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);

            $browser->waitFor('input[name="name"]', 12)
                ->assertSee('Category Identity')
                ->assertSee('Configuration')
                ->assertPresent('select[name="polarity"]')
                ->assertPresent('input[name="sort_order"]')
                ->assertSee('Save Category');
        });
    }

    /** TC-P11 · BC-BIZ-02 · Source: Controller@store flash "Category created successfully." */
    public function test_category_11_create_submission_persists(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V1 Create ' . $this->generateUniqueSuffix();
        $saved = null;

        try {
            $sortOrder = $this->nextTopLevelSortOrder();
            $this->browse(function (Browser $browser) use ($name, $sortOrder): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', $name)
                    ->select('polarity', 'positive')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $sortOrder)
                    ->press('Save Category')
                    ->pause(2500);
            });

            $saved = BaCategory::query()->where('name', $name)->latest('id')->first();
            $this->assertNotNull($saved, 'Category was not persisted.');
            $this->assertSame('positive', (string) $saved->polarity);
        } finally {
            if ($saved instanceof BaCategory) {
                $this->forceDeleteRecordByIdIfExists((int) $saved->id);
            }
        }
    }

    /** TC-P12 · BC-BIZ-03 · Source: show.blade "Category Details" / "Category Identity" */
    public function test_category_12_show_page_displays_data(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Show ' . $this->generateUniqueSuffix(),
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);

                $browser->waitForText('Category Details', 12)
                    ->assertSee((string) $record->name)
                    ->assertSee('Associated Criteria');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P13 · BC-BIZ-04 · Source: Controller@update flash "Category updated successfully." */
    public function test_category_13_edit_update_persists_and_flashes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Before ' . $this->generateUniqueSuffix(),
        ]);
        $updatedName = 'V1 After ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($record, $updatedName): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);

                // The edit page has two name inputs (category + criterion). The category name is the
                // first input[name="name"] inside the category (non-criteria) form.
                $browser->waitFor('input[name="name"]', 12)
                    ->clear('input[name="name"]')
                    ->type('input[name="name"]', $updatedName)
                    ->press('Update Category')
                    ->pause(2200)
                    ->assertSee('Category updated successfully.');
            });

            $record->refresh();
            $this->assertSame($updatedName, (string) $record->name);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P14 · BC-SM-01 · Source: Controller@toggleStatus + status-switch component (.status-toggle) */
    public function test_category_14_toggle_status_flips_is_active(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name'      => 'V1 Toggle ' . $this->generateUniqueSuffix(),
            'is_active' => true,
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=categories', 900);

                $selector = '.status-toggle[data-id="' . $record->id . '"]';
                $browser->waitFor($selector, 12)
                    ->script('document.querySelector(\'' . $selector . '\').click();');
                $browser->pause(1800);
            });

            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'is_active should have toggled to false.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D01 (F) · BC-BIZ-05 · Source: Controller destroy/restore/forceDelete */
    public function test_category_15_soft_delete_restore_force_delete_lifecycle(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Lifecycle ' . $this->generateUniqueSuffix(),
        ]);
        $recordId = (int) $record->id;

        try {
            $record->delete();
            $this->assertNotNull(BaCategory::withTrashed()->find($recordId));
            $this->assertNull(BaCategory::find($recordId));

            $record->restore();
            $this->assertNotNull(BaCategory::find($recordId));

            $record->forceDelete();
            $this->assertNull(BaCategory::withTrashed()->find($recordId));
        } finally {
            $this->forceDeleteRecordByIdIfExists($recordId);
        }
    }

    /** TC-P16 · BC-BIZ-06 · Source: edit.blade "Add New Criterion" + Controller@storeCriterion flash "Criterion added." */
    public function test_category_16_add_criterion_via_edit_page_persists(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Criteria ' . $this->generateUniqueSuffix(),
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);

                // Scope to the criterion form (its action contains "criteria") to avoid the category name input.
                $browser->waitFor('form[action*="criteria"] input[name="name"]', 12)
                    ->type('form[action*="criteria"] input[name="name"]', 'Completes assignments on time')
                    ->clear('form[action*="criteria"] input[name="weight"]')
                    ->type('form[action*="criteria"] input[name="weight"]', '50.00')
                    ->clear('form[action*="criteria"] input[name="sort_order"]')
                    ->type('form[action*="criteria"] input[name="sort_order"]', '1')
                    ->press('Add')
                    ->pause(2000)
                    ->assertSee('Criterion added.');
            });

            $this->assertSame(
                1,
                BaCriterion::where('category_id', $record->id)->where('name', 'Completes assignments on time')->count(),
                'Criterion was not persisted.'
            );
        } finally {
            $record->criteria()->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ──────────────────────────────────────────────
    //  30–39  Validation (negative)
    // ──────────────────────────────────────────────

    /** TC-N10 · BC-VAL-01 · Source: BaCategoryRequest sort_order unique per level */
    public function test_category_17_duplicate_sort_order_same_level_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $sortOrder = $this->nextTopLevelSortOrder();
        $existing = $this->createRecordDirectly($dependencies, [
            'name'       => 'V1 SortExisting ' . $this->generateUniqueSuffix(),
            'parent_id'  => null,
            'sort_order' => $sortOrder,
        ]);
        $before = BaCategory::query()->count();

        try {
            $this->browse(function (Browser $browser) use ($sortOrder): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', 'V1 SortDup ' . $this->generateUniqueSuffix())
                    ->select('polarity', 'positive')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $sortOrder)
                    ->press('Save Category')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertSame($before, BaCategory::query()->count(), 'Duplicate sort_order at same level must not create a row.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $existing->id);
        }
    }

    /** TC-N11 · BC-VAL-02 · Source: BaCategoryRequest polarity Rule::in(['positive','negative']) */
    public function test_category_18_invalid_polarity_is_rejected(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V1 BadPolarity ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($name): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                // Inject an out-of-enum option so we can post an illegal polarity past the <select>.
                $browser->waitFor('select[name="polarity"]', 12)
                    ->script("(function(){var s=document.querySelector('select[name=\"polarity\"]');var o=document.createElement('option');o.value='neutral';o.text='neutral';s.appendChild(o);s.value='neutral';})();");
                $browser->type('input[name="name"]', $name)
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->nextTopLevelSortOrder())
                    ->press('Save Category')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertNull(
                BaCategory::query()->where('name', $name)->first(),
                'Invalid polarity should not create a row.'
            );
        } finally {
            BaCategory::query()->where('name', $name)->forceDelete();
        }
    }

    // ──────────────────────────────────────────────
    //  50–69  Auth + UI
    // ──────────────────────────────────────────────

    /** TC-S01 · BC-AUTH-01 · Source: web routes behind auth middleware */
    public function test_category_19_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    /** TC-P21 · BC-BIZ-07 · Source: Controller@trashed + trash.blade */
    public function test_category_20_trash_page_lists_soft_deleted_category(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Trash ' . $this->generateUniqueSuffix(),
        ]);
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

    /** TC-P22 · BC-BIZ-08 · Source: Controller@create breadcrumb navigates in same tab */
    public function test_category_21_masters_breadcrumb_navigates_same_tab(): void
    {
        $this->resolveDependenciesOrSkip();

        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $browser->assertSee('Category Identity');

            $windowsBefore = count($browser->driver->getWindowHandles());
            $browser->script(<<<'JS'
            (function () {
                const link = document.querySelector('.breadcrumb a[href*="/behavioural-assessment/masters"]');
                if (link) { link.click(); }
            })();
JS);
            $browser->pause(1200);
            $windowsAfter = count($browser->driver->getWindowHandles());

            $this->assertSame($windowsBefore, $windowsAfter, 'Breadcrumb should navigate in the same tab.');
        });
    }

    /** TC-P23 · BC-BIZ-09 · Source: Controller@reorder JSON {success:true} */
    public function test_category_22_reorder_endpoint_updates_sort_order(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $first = $this->createRecordDirectly($dependencies, [
            'name'       => 'V1 ReorderA ' . $this->generateUniqueSuffix(),
            'sort_order' => $this->nextTopLevelSortOrder(),
        ]);
        $second = $this->createRecordDirectly($dependencies, [
            'name'       => 'V1 ReorderB ' . $this->generateUniqueSuffix(),
            'sort_order' => $this->nextTopLevelSortOrder(),
        ]);

        try {
            $this->browse(function (Browser $browser) use ($first, $second): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=categories', 900);

                // reorder() reads request('order') as an ordered array of ids and sets sort_order = index.
                $response = $this->postJsonFromBrowser(
                    $browser,
                    '/behavioural-assessment/categories/reorder',
                    ['order' => [(int) $second->id, (int) $first->id]]
                );
                $this->assertStringContainsString('"success"', $response, 'Reorder endpoint should return a success key.');
            });

            $second->refresh();
            $first->refresh();
            $this->assertSame(0, (int) $second->sort_order, 'First id in order[] should get sort_order 0.');
            $this->assertSame(1, (int) $first->sort_order, 'Second id in order[] should get sort_order 1.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $first->id);
            $this->forceDeleteRecordByIdIfExists((int) $second->id);
        }
    }

    // ──────────────────────────────────────────────
    //  Helpers (mirror the committed sibling test)
    // ──────────────────────────────────────────────

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
        $payload = array_merge($this->buildValidDirectPayload($dependencies), $overrides);

        return BaCategory::query()->create($payload);
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'parent_id'   => null,
            'name'        => 'Category ' . $this->generateUniqueSuffix(),
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
            'name'        => 'Criterion ' . $this->generateUniqueSuffix(),
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

    private function generateUniqueSuffix(): string
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

        $permissions = $this->categoryPermissions();
        $this->ensurePermissionsExist($permissions);

        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
    }

    private function categoryPermissions(): array
    {
        return [
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

    /** Reference to BaCategoryRequest to keep the FormRequest import meaningful for static tools. */
    private function requestClassName(): string
    {
        return BaCategoryRequest::class;
    }

    /** Reference to DB facade for parity with the sibling helper surface. */
    private function categoriesTableName(): string
    {
        return DB::getTablePrefix() . self::CATEGORIES_TABLE;
    }
}
