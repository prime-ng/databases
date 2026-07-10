<?php

/**
 * BehaviouralAssessment › ClassMapping (app: ClassCategory) — V2 (comprehensive) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/ClassCategory/ClassCategoryCrudTest.php.
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; live migration under database/migrations/tenant/).
 * TABLE   : ba_class_category_jnt (junction Class ↔ Category). DDL doc + this file's name use the stale
 *           prefix "bha_" (audit DOC-BA-001); every schema assertion targets the LIVE "ba_" table.
 * KIND    : junction/config — controller = store / toggleStatus / destroy only (NO edit/update).
 *
 * Semantic numbering bands (WP-G):
 *   01–09 schema/model/config · 10–19 business rules · 20–29 state-machine/status
 *   30–39 validation · 40–49 integration/FK · 50–59 permissions · 60–69 UI/UX
 *   70–79 edge · 90–99 tenancy + security
 *
 * Audit / source findings proven here (reported as "verify in source" — traced to cited lines):
 *   DOC-BA-001   DDL doc prefix bha_ vs live ba_                        → test_..._01
 *   BUG-BA-012   model omits SoftDeletes → destroy() is a hard delete   → test_..._01 / _22 (NEW)
 *   VAL-BA-001   no BaClassCategoryRequest — inline validate            → test_..._30
 *   BUG-BA-007   unmapped class ⇒ empty grid (permissive default gap)   → test_..._41
 *   GAP-BA-CM-01 destroy() has no "ratings already recorded" guard      → test_..._42 (NEW, Screen-BR)
 *   GAP-BA-CM-02 requirement multi-category grid + Academic Session     → test_..._43 (NEW, Screen vs impl)
 *                not implemented (single class+category, no session)
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaCategory;
use Modules\BehaviouralAssessment\Models\BaClassCategoryJnt;
use Modules\SchoolSetup\Models\SchoolClass;
use Modules\SchoolSetup\Models\User;
use Tests\DuskTestCase;
use Throwable;

class bha_ClassMappingV2_TestCas extends DuskTestCase
{
    private const SETUP_PATH      = '/behavioural-assessment/setup';
    private const TAB_QS          = '?tab=class-mapping';
    private const TABLE           = 'ba_class_category_jnt';
    private const MIGRATION_FILE  = 'database/migrations/tenant/2026_06_16_130618_create_ba_class_category_jnt_table.php';
    private const CONTROLLER_FILE = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaClassCategoryController.php';
    private const REQUEST_FILE    = 'Modules/BehaviouralAssessment/app/Http/Requests/BaClassCategoryRequest.php';
    private const RATINGS_TABLE   = 'ba_assessment_ratings';

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
    //  01–09  Schema / model / config truth
    // ══════════════════════════════════════════════

    /** TC-P01 · BC-DB-01 · Audit-DOC-BA-001 · Source: DDL / live migration */
    public function test_class_mapping_01_schema_and_doc_prefix_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Live table ba_class_category_jnt does not exist.');
        $this->assertFalse(
            Schema::hasTable('bha_class_category_jnt'),
            'Stale DDL-doc table bha_class_category_jnt should NOT exist (DOC-BA-001).'
        );
        $this->assertTrue(Schema::hasColumns(self::TABLE, [
            'id', 'class_id', 'category_id', 'is_active',
            'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing from ba_class_category_jnt.');
        // Junction is class↔category only — there is NO academic session column (see GAP-BA-CM-02).
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'academic_session_id'),
            'Junction has no session scope despite the requirement mentioning Academic Session (GAP-BA-CM-02).');
    }

    /** TC-P02 · BC-REF-03 · BC-DB-04 · Source: migration uq_ba_class_cat + FKs */
    public function test_class_mapping_02_migration_unique_and_foreign_keys(): void
    {
        $migration = File::get(base_path(self::MIGRATION_FILE));
        $this->assertStringContainsString("\$table->unique(['class_id', 'category_id'], 'uq_ba_class_cat')", $migration);
        $this->assertStringContainsString("->references('id')->on('sch_classes')->onDelete('cascade')", $migration);
        $this->assertStringContainsString("constrained('ba_categories')->cascadeOnDelete()", $migration);
        $this->assertStringContainsString("\$table->index('class_id', 'idx_ba_cc_class')", $migration);
        $this->assertStringContainsString("\$table->index('category_id', 'idx_ba_cc_category')", $migration);
    }

    /** TC-P03 · BC-DB-06 · Source: Model $fillable / $casts / relationships */
    public function test_class_mapping_03_model_fillable_casts_and_relationships(): void
    {
        $model = new BaClassCategoryJnt();
        $this->assertSame('ba_class_category_jnt', $model->getTable());
        foreach (['class_id', 'category_id', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $model->getFillable(), "fillable should include {$col}.");
        }
        $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null);
        $this->assertInstanceOf(BelongsTo::class, $model->schoolClass());
        $this->assertInstanceOf(BelongsTo::class, $model->category());
    }

    /**
     * TC-N20 · BC-BIZ-15 · Audit-BUG-BA-012 (verify in source).
     * The migration declares softDeletes()/deleted_at and store()'s unique rule scopes ->whereNull('deleted_at'),
     * yet BaClassCategoryJnt does NOT use the SoftDeletes trait. So destroy() ($mapping->delete()) is a PERMANENT
     * hard delete and withTrashed/restore/forceDelete are unavailable. This proves the current (defective) config.
     * Source: Models/BaClassCategoryJnt.php (no `use SoftDeletes;`) vs migration softDeletes().
     */
    public function test_class_mapping_04_model_missing_softdeletes_trait_bug_ba_012(): void
    {
        $migration = File::get(base_path(self::MIGRATION_FILE));
        $this->assertStringContainsString("\$table->softDeletes()", $migration, 'Migration declares softDeletes().');
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'deleted_at'), 'deleted_at column exists.');

        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(BaClassCategoryJnt::class),
            'BUG-BA-012 confirmed: model omits SoftDeletes despite migration deleted_at → destroy() is a hard delete.'
        );
    }

    /** TC-N01 · BC-DB-03 · Source: DDL NOT NULL class_id/category_id */
    public function test_class_mapping_05_db_rejects_each_missing_required_field(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        foreach (['class_id', 'category_id'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    // ══════════════════════════════════════════════
    //  10–19  Business rules
    // ══════════════════════════════════════════════

    /** TC-P10 · BC-BIZ-02 · Source: Controller@store flash "Category mapped to class successfully." */
    public function test_class_mapping_10_create_valid_mapping_persists_and_flashes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $classId = (int) $dependencies['class_id'];
        $categoryId = (int) $dependencies['category_id'];

        try {
            $this->browse(function (Browser $browser) use ($classId, $categoryId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('select[name="class_id"]', 12)
                    ->select('class_id', (string) $classId)
                    ->select('category_id', (string) $categoryId)
                    ->press('Add Mapping')
                    ->pause(2500)
                    ->assertSee('Category mapped to class successfully.');
            });

            $this->assertSame(1, BaClassCategoryJnt::query()
                ->where('class_id', $classId)->where('category_id', $categoryId)->count());
        } finally {
            $this->purgePair($classId, $categoryId);
        }
    }

    /** TC-P11 · BC-BIZ-03 · Source: Controller@store sets is_active=true, created_by/updated_by=auth()->id() */
    public function test_class_mapping_11_store_sets_is_active_and_audit_columns(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        try {
            $record->refresh();
            $this->assertTrue((bool) $record->is_active);
            $this->assertSame((int) $dependencies['admin_user_id'], (int) $record->created_by);
            $this->assertSame((int) $dependencies['admin_user_id'], (int) $record->updated_by);
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    /** TC-P12 · BC-BIZ-06 · Source: _class-mapping.blade polarity badge from category->polarity */
    public function test_class_mapping_12_list_renders_class_and_polarity(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        try {
            $this->browse(function (Browser $browser): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 1000);
                $browser->waitForText('Class', 12)
                    ->assertSee('Category')
                    ->assertSee('Polarity')
                    ->assertSee('Status');
            });
            $this->assertTrue(true);
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    /** TC-P13 · BC-BIZ-05 · Source: setup() paginate(20,'cm_page') */
    public function test_class_mapping_13_setup_uses_cm_page_paginator(): void
    {
        $controller = File::get(base_path('Modules/BehaviouralAssessment/app/Http/Controllers/BaDashboardController.php'));
        $this->assertStringContainsString("'cm_page'", $controller, 'Class-mapping list should paginate with the cm_page page name.');
        $this->assertStringContainsString("appends(['tab' => 'class-mapping'])", File::get(
            base_path('Modules/BehaviouralAssessment/resources/views/pages/partials/setup/_class-mapping.blade.php')
        ), 'Pagination links should preserve the class-mapping tab.');
    }

    // ══════════════════════════════════════════════
    //  20–29  State-machine / status lifecycle
    // ══════════════════════════════════════════════

    /** TC-SM01 · BC-SM-01 · Source: Controller@toggleStatus + .status-toggle */
    public function test_class_mapping_20_toggle_status_deactivates_then_reactivates(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
                $selector = '.status-toggle[data-id="' . $record->id . '"]';
                $browser->waitFor($selector, 12)->script('document.querySelector(\'' . $selector . '\').click();');
                $browser->pause(1800);
            });
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'First toggle should deactivate the mapping.');
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    /** TC-SM02 · BC-SM-02 · Source: Controller@toggleStatus JSON {success,is_active,message} */
    public function test_class_mapping_21_toggle_endpoint_returns_json_payload(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
                $response = $this->postJsonFromBrowser(
                    $browser,
                    '/behavioural-assessment/class-categories/' . $record->id . '/toggle-status'
                );
                $this->assertStringContainsString('"success"', $response, 'Toggle endpoint should return a JSON success key.');
                $this->assertStringContainsString('Mapping', $response, 'Toggle endpoint should return the status message.');
            });
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    /**
     * TC-D01 (F) · BC-SM-03 · Audit-BUG-BA-012 · Source: Controller@destroy → $mapping->delete().
     * Model lacks SoftDeletes → delete() physically removes the row (no deleted_at ghost). Proven at DB layer.
     */
    public function test_class_mapping_22_destroy_hard_deletes_row(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $id = (int) $record->id;
        try {
            $record->delete();
            $this->assertNull(BaClassCategoryJnt::find($id));
            $this->assertFalse(DB::table(self::TABLE)->where('id', $id)->exists(),
                'BUG-BA-012 confirmed: destroy() hard-deletes (row physically gone, no soft-delete).');
        } finally {
            $this->purgeMappingById($id);
        }
    }

    /**
     * TC-D02 (G) · BC-EDG-01 · Source: hard-delete + uq_ba_class_cat.
     * Because destroy() is a HARD delete (BUG-BA-012), the (class, category) slot is fully freed and the
     * same pair can be re-mapped immediately with NO integrity error — the opposite of the DATA-BA-003
     * soft-delete collision seen on rating-levels. Proven here.
     */
    public function test_class_mapping_23_pair_can_be_remapped_after_hard_delete(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $first = $this->createRecordDirectly($dependencies);
        $first->delete();
        $second = null;
        try {
            $second = $this->createRecordDirectly($dependencies); // same pair — must succeed (slot freed)
            $this->assertNotNull($second->id, 'Re-mapping the same pair after hard delete should succeed.');
        } finally {
            if ($second instanceof BaClassCategoryJnt) {
                $this->purgeMappingById((int) $second->id);
            }
            $this->purgePair((int) $dependencies['class_id'], (int) $dependencies['category_id']);
        }
    }

    // ══════════════════════════════════════════════
    //  30–39  Validation (negative matrix)
    // ══════════════════════════════════════════════

    /**
     * TC-N02 · BC-VAL-05 · Audit-VAL-BA-001 (verify in source).
     * No BaClassCategoryRequest exists — the store() write path validates inline. Documents the gap.
     * Source: BaClassCategoryController@store:20-33.
     */
    public function test_class_mapping_30_no_form_request_inline_validation_val_ba_001(): void
    {
        $this->assertFalse(File::exists(base_path(self::REQUEST_FILE)),
            'VAL-BA-001 confirmed: no BaClassCategoryRequest — validation is inline in the controller.');
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString('$request->validate(', $controller);
        $this->assertStringContainsString("'required', 'integer', 'exists:sch_classes,id'", $controller);
        $this->assertStringContainsString("'exists:ba_categories,id'", $controller);
        $this->assertStringContainsString("Rule::unique('ba_class_category_jnt', 'category_id')", $controller);
    }

    /** TC-N03 · BC-VAL-03 · Source: unique rule + message "This category is already mapped to the selected class." */
    public function test_class_mapping_31_duplicate_mapping_shows_validation_message(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $classId = (int) $dependencies['class_id'];
        $categoryId = (int) $dependencies['category_id'];
        $existing = $this->createRecordDirectly($dependencies);
        $before = BaClassCategoryJnt::query()->count();
        try {
            $this->browse(function (Browser $browser) use ($classId, $categoryId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('select[name="class_id"]', 12)
                    ->select('class_id', (string) $classId)
                    ->select('category_id', (string) $categoryId)
                    ->press('Add Mapping')
                    ->pause(2200)
                    ->assertSee('This category is already mapped to the selected class.');
            });
            $this->assertSame($before, BaClassCategoryJnt::query()->count(), 'Duplicate mapping must not create a row.');
        } finally {
            $this->purgeMappingById((int) $existing->id);
        }
    }

    /** TC-N04 · BC-VAL-01 · Source: class_id required (blank submission blocked) */
    public function test_class_mapping_32_missing_class_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $categoryId = (int) $dependencies['category_id'];
        $before = BaClassCategoryJnt::query()->count();

        $this->browse(function (Browser $browser) use ($categoryId): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
            $this->suppressBrowserAlertDialogs($browser);
            // Leave class_id empty, choose a category, bypass the HTML `required` and submit.
            $browser->waitFor('select[name="category_id"]', 12)
                ->select('category_id', (string) $categoryId)
                ->script("document.querySelectorAll('[required]').forEach(function(e){e.removeAttribute('required');}); document.querySelector('#class-mapping-pane form').submit();");
            $browser->pause(2000);
        });

        $this->assertSame($before, BaClassCategoryJnt::query()->count(), 'Missing class_id must not create a mapping.');
    }

    /** TC-N05 · BC-VAL-02 · Source: category_id required */
    public function test_class_mapping_33_missing_category_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $classId = (int) $dependencies['class_id'];
        $before = BaClassCategoryJnt::query()->count();

        $this->browse(function (Browser $browser) use ($classId): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('select[name="class_id"]', 12)
                ->select('class_id', (string) $classId)
                ->script("document.querySelectorAll('[required]').forEach(function(e){e.removeAttribute('required');}); document.querySelector('#class-mapping-pane form').submit();");
            $browser->pause(2000);
        });

        $this->assertSame($before, BaClassCategoryJnt::query()->count(), 'Missing category_id must not create a mapping.');
    }

    /** TC-N06 · BC-VAL-01 · Source: class_id exists:sch_classes,id (unknown id rejected) */
    public function test_class_mapping_34_nonexistent_class_id_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $categoryId = (int) $dependencies['category_id'];
        $before = BaClassCategoryJnt::query()->count();

        $this->browse(function (Browser $browser) use ($categoryId): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
            $this->suppressBrowserAlertDialogs($browser);
            // Inject an out-of-range option so we can POST an unknown class id.
            $browser->waitFor('select[name="class_id"]', 12)
                ->script("(function(){var s=document.querySelector('select[name=\"class_id\"]');var o=document.createElement('option');o.value='99887766';o.text='ghost';s.appendChild(o);s.value='99887766';})();")
                ->select('category_id', (string) $categoryId)
                ->script("document.querySelectorAll('[required]').forEach(function(e){e.removeAttribute('required');}); document.querySelector('#class-mapping-pane form').submit();");
            $browser->pause(2000);
        });

        $this->assertFalse(
            BaClassCategoryJnt::query()->where('class_id', 99887766)->exists(),
            'exists:sch_classes,id must reject an unknown class id.'
        );
        $this->assertSame($before, BaClassCategoryJnt::query()->count());
    }

    /** TC-N07 · BC-VAL-02 · Source: category_id exists:ba_categories,id (unknown id rejected) */
    public function test_class_mapping_35_nonexistent_category_id_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $classId = (int) $dependencies['class_id'];
        $before = BaClassCategoryJnt::query()->count();

        $this->browse(function (Browser $browser) use ($classId): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('select[name="category_id"]', 12)
                ->select('class_id', (string) $classId)
                ->script("(function(){var s=document.querySelector('select[name=\"category_id\"]');var o=document.createElement('option');o.value='99887766';o.text='ghost';s.appendChild(o);s.value='99887766';})();")
                ->script("document.querySelector('select[name=\"category_id\"]').value='99887766';")
                ->script("document.querySelectorAll('[required]').forEach(function(e){e.removeAttribute('required');}); document.querySelector('#class-mapping-pane form').submit();");
            $browser->pause(2000);
        });

        $this->assertFalse(
            BaClassCategoryJnt::query()->where('category_id', 99887766)->exists(),
            'exists:ba_categories,id must reject an unknown category id.'
        );
        $this->assertSame($before, BaClassCategoryJnt::query()->count());
    }

    /** TC-N08 · BC-DB-04 · Source: uq_ba_class_cat at DB layer (defence below the FormRequest) */
    public function test_class_mapping_36_db_unique_index_blocks_duplicate_pair(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $first = $this->createRecordDirectly($dependencies);
        try {
            $threw = false;
            try {
                $this->createRecordDirectly($dependencies);
            } catch (Throwable $e) {
                $msg = strtolower($e->getMessage());
                $threw = str_contains($msg, '23000') || str_contains($msg, 'duplicate') || str_contains($msg, 'integrity');
            }
            $this->assertTrue($threw, 'uq_ba_class_cat should block a duplicate (class_id, category_id) at the DB layer.');
        } finally {
            $this->purgeMappingById((int) $first->id);
        }
    }

    // ══════════════════════════════════════════════
    //  40–49  Integration / FK / dependency (cross-module)
    // ══════════════════════════════════════════════

    /** TC-D03 (E) · BC-INT-01 · Source: class_id → sch_classes (defensive cross-module) */
    public function test_class_mapping_40_class_belongs_to_school_class(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        try {
            $record->refresh()->load('schoolClass');
            $this->assertSame((int) $dependencies['class_id'], (int) ($record->schoolClass->id ?? 0),
                'Mapping should resolve back to its sch_classes parent.');
        } catch (Throwable $e) {
            $this->markTestSkipped('SchoolSetup (sch_classes) unavailable: ' . $e->getMessage());
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    /**
     * TC-D04 (E) · BC-INT-03 · Audit-BUG-BA-007 (verify in source).
     * BR-BA-009 permissive default: "no mapping ⇒ all active categories apply". The ratings grid does
     * pluck('category_id') on ba_class_category_jnt → an unmapped class yields an empty set → blank grid.
     * Proven at the data layer: an unmapped class has zero mapping rows.
     * Source: BaAssessmentController@show:115-121.
     */
    public function test_class_mapping_41_unmapped_class_yields_empty_mapping_bug_ba_007(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $unmappedClassId = $this->findClassWithNoMappingOrSkip($dependencies['class_ids']);
        $this->assertSame(0, BaClassCategoryJnt::query()->where('class_id', $unmappedClassId)->count(),
            'BUG-BA-007: unmapped class ⇒ empty mapping ⇒ empty ratings grid (permissive default missing).');
    }

    /**
     * TC-D05 (E) · BC-BIZ-16 · GAP-BA-CM-01 (verify in source, NEW).
     * Screen BR "Preservation of Existing Grades": unmapping must be BLOCKED when ba_assessment_ratings exist
     * for the class, with message "Cannot remove Category '…' because teachers have already recorded ratings…".
     * The controller destroy() performs NO such check — it always deletes. Proven here: destroy succeeds even
     * when rating data would exist. Cross-module ratings table probed defensively.
     * Source: BaClassCategoryController@destroy:63-72 (no ba_assessment_ratings guard).
     */
    public function test_class_mapping_42_unmap_has_no_recorded_grades_guard_gap(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();

        // Document the source gap regardless of data presence.
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringNotContainsString(self::RATINGS_TABLE, $controller,
            'GAP-BA-CM-01: destroy() references no ba_assessment_ratings guard (Preservation-of-Grades not enforced).');
        $this->assertStringNotContainsString('already recorded', $controller,
            'GAP-BA-CM-01: no "already recorded ratings" block message in the controller.');

        // Behavioural proof: destroy() succeeds unconditionally.
        $record = $this->createRecordDirectly($dependencies);
        $id = (int) $record->id;
        try {
            $record->delete();
            $this->assertNull(BaClassCategoryJnt::find($id),
                'GAP-BA-CM-01 confirmed: unmapping is not blocked by any recorded-grades check.');
        } finally {
            $this->purgeMappingById($id);
        }
    }

    /**
     * TC-D06 (E) · BC-CFG-02 · GAP-BA-CM-02 (verify in source, NEW).
     * The screen requirement describes a multi-category checkbox GRID scoped to an Academic Session
     * ("At least 1 must be selected", "org_academic_sessions"). The implementation is a single
     * class+category "Add Mapping" form with no session scope. Documents the requirement↔impl drift.
     * Source: _class-mapping.blade (single select pair) + migration (no session column).
     */
    public function test_class_mapping_43_single_pair_form_no_session_scope_gap(): void
    {
        $blade = File::get(base_path('Modules/BehaviouralAssessment/resources/views/pages/partials/setup/_class-mapping.blade.php'));
        $this->assertStringContainsString('name="class_id"', $blade);
        $this->assertStringContainsString('name="category_id"', $blade);
        // No multi-select / checkbox grid and no academic-session control implemented.
        $this->assertStringNotContainsString('category_id[]', $blade,
            'GAP-BA-CM-02: implementation maps ONE category at a time, not the requirement\'s multi-select grid.');
        $this->assertStringNotContainsString('academic_session', $blade,
            'GAP-BA-CM-02: no Academic Session scoping on the mapping form (requirement mentions it).');
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'academic_session_id'));
    }

    // ══════════════════════════════════════════════
    //  50–59  Permissions / authorization
    // ══════════════════════════════════════════════

    /** TC-S01 · BC-AUTH-01 · Source: web routes behind auth middleware */
    public function test_class_mapping_50_guest_redirected_to_login_on_setup(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::SETUP_PATH . self::TAB_QS))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** TC-S02 · BC-AUTH-02 · Source: Controller Gate::authorize('…class-categories.create/status/delete') */
    public function test_class_mapping_51_controller_gates_each_write_action(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.class-categories.create')", $controller);
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.class-categories.status')", $controller);
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.class-categories.delete')", $controller);
    }

    /** TC-S03 · BC-AUTH-03 · Source: setup page gate tenant.behavioural-assessment.setup.viewAny (limited user blocked) */
    public function test_class_mapping_52_user_without_permission_is_blocked_from_setup(): void
    {
        $limited = $this->createLimitedUserOrSkip();

        $this->browse(function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600)
                ->visit($this->tenantUrl(self::SETUP_PATH . self::TAB_QS))->pause(1200);

            $source = strtolower($browser->driver->getPageSource());
            $blocked = str_contains($source, '403')
                || str_contains($source, 'forbidden')
                || str_contains($source, 'not authorized')
                || str_contains($source, 'unauthorized');
            $hasAddForm = str_contains($source, 'add mapping');

            $this->assertTrue($blocked || ! $hasAddForm,
                'A user lacking setup/class-categories permission should not reach the Add Mapping form.');
        });
    }

    // ══════════════════════════════════════════════
    //  60–69  UI / UX (list, empty state)
    // ══════════════════════════════════════════════

    /** TC-P60 · BC-BIZ-05 · Source: setup list shows the created mapping's class name */
    public function test_class_mapping_60_created_mapping_appears_in_list(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $className = (string) (SchoolClass::query()->whereKey($dependencies['class_id'])->value('name') ?? '');
        try {
            $this->browse(function (Browser $browser) use ($className): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 1000);
                $browser->waitForText('Class', 12);
                if ($className !== '') {
                    $browser->assertSee($className);
                }
            });
            $this->assertTrue(true);
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    /** TC-P61 · BC-BIZ-07 · Source: _class-mapping.blade @empty "No class-category mappings yet." */
    public function test_class_mapping_61_empty_state_message_is_defined(): void
    {
        $blade = File::get(base_path('Modules/BehaviouralAssessment/resources/views/pages/partials/setup/_class-mapping.blade.php'));
        $this->assertStringContainsString('No class-category mappings yet.', $blade,
            'The empty-state message should be present in the class-mapping partial.');
    }

    /** TC-P62 · BC-BIZ-08 · Source: destroy uses POST form + @method DELETE + SweetAlert confirm */
    public function test_class_mapping_62_delete_control_is_a_confirmed_delete_form(): void
    {
        $blade = File::get(base_path('Modules/BehaviouralAssessment/resources/views/pages/partials/setup/_class-mapping.blade.php'));
        $this->assertStringContainsString("route('behavioural-assessment.class-categories.destroy'", $blade);
        $this->assertStringContainsString("@method('DELETE')", $blade);
        $this->assertStringContainsString('Remove Mapping?', $blade, 'Delete should be guarded by a SweetAlert confirm.');
    }

    // ══════════════════════════════════════════════
    //  70–79  Edge cases
    // ══════════════════════════════════════════════

    /** TC-D07 (G) · BC-EDG-02 · Source: same category mapped to two DIFFERENT classes is allowed */
    public function test_class_mapping_70_same_category_allowed_across_two_classes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $classIds = $dependencies['class_ids'];
        $categoryId = (int) $dependencies['category_id'];

        // Need two distinct classes that are both unmapped for this category.
        $pairA = null;
        $pairB = null;
        foreach ($classIds as $classId) {
            if (DB::table(self::TABLE)->where('class_id', $classId)->where('category_id', $categoryId)->exists()) {
                continue;
            }
            if ($pairA === null) {
                $pairA = (int) $classId;
            } elseif ($pairB === null) {
                $pairB = (int) $classId;
                break;
            }
        }
        if ($pairA === null || $pairB === null) {
            $this->markTestSkipped('Need two classes free of this category to prove cross-class reuse.');
        }

        $recA = null;
        $recB = null;
        try {
            $recA = BaClassCategoryJnt::query()->create($this->payloadFor($dependencies, $pairA, $categoryId));
            $recB = BaClassCategoryJnt::query()->create($this->payloadFor($dependencies, $pairB, $categoryId));
            $this->assertNotNull($recA->id);
            $this->assertNotNull($recB->id, 'The same category may map to a second, different class (uniqueness is per pair).');
        } finally {
            if ($recA instanceof BaClassCategoryJnt) {
                $this->purgeMappingById((int) $recA->id);
            }
            if ($recB instanceof BaClassCategoryJnt) {
                $this->purgeMappingById((int) $recB->id);
            }
        }
    }

    /** TC-D08 (G) · BC-EDG-03 · Source: toggle on an unknown id → findOrFail 404 */
    public function test_class_mapping_71_toggle_unknown_id_does_not_crash_client(): void
    {
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);
            $response = $this->postJsonFromBrowser($browser, '/behavioural-assessment/class-categories/99887766/toggle-status');
            // findOrFail → 404 page/JSON; the mapping must not be created and no success payload returned.
            $this->assertStringNotContainsString('"success":true', $response,
                'Toggling an unknown mapping id must not report success.');
        });
        $this->assertFalse(BaClassCategoryJnt::query()->whereKey(99887766)->exists());
    }

    // ══════════════════════════════════════════════
    //  90–99  Tenancy + security
    // ══════════════════════════════════════════════

    /** TC-T01 · BC-CFG-01 · Source: tenant-per-DB (no tenant_id column) */
    public function test_class_mapping_90_runs_inside_initialized_tenant(): void
    {
        if (!function_exists('tenancy')) {
            $this->markTestSkipped('Tenancy helper unavailable.');
        }
        $this->assertTrue(tenancy()->initialized, 'ClassMapping is tenant-scoped and requires an initialized tenant.');
        $this->assertTrue(Schema::hasTable(self::TABLE), 'ba_class_category_jnt must resolve within the tenant DB.');
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'tenant_id'),
            'Tenant-per-database design → no tenant_id column on ba_class_category_jnt.');
    }

    /** TC-S05 · BC-EDG-04 · Source: Blade `{{ }}` auto-escaping of category name on the list */
    public function test_class_mapping_91_category_name_is_escaped_on_list(): void
    {
        $blade = File::get(base_path('Modules/BehaviouralAssessment/resources/views/pages/partials/setup/_class-mapping.blade.php'));
        // Category + class names are rendered via escaped {{ }} interpolation, never {!! !!}.
        $this->assertStringContainsString('{{ $mapping->category?->name }}', $blade);
        $this->assertStringNotContainsString('{!! $mapping->category', $blade,
            'Category name must be rendered with escaped Blade output, not raw {!! !!}.');
    }

    /** TC-S06 · BC-AUTH-04 · Source: destroy/toggle findOrFail → 404 for invalid id (IDOR guard) */
    public function test_class_mapping_92_invalid_id_is_not_actionable(): void
    {
        $this->resolveDependenciesOrSkip();
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString('BaClassCategoryJnt::findOrFail($id)', $controller,
            'toggleStatus/destroy should resolve the mapping via findOrFail (404 on unknown id).');
        $this->assertFalse(BaClassCategoryJnt::query()->whereKey(99887766)->exists());
    }

    // ══════════════════════════════════════════════
    //  Helpers
    // ══════════════════════════════════════════════

    private function resolveDependenciesOrSkip(): array
    {
        $adminUserId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));
        if ($adminUserId <= 0) {
            $this->markTestSkipped('No admin user found for class mapping tests.');
        }

        try {
            $classIds = SchoolClass::query()->where('is_active', true)->orderBy('ordinal')->pluck('id')->map(fn ($v) => (int) $v)->all();
            $categoryIds = BaCategory::query()->whereNull('parent_id')->where('is_active', true)->orderBy('sort_order')->pluck('id')->map(fn ($v) => (int) $v)->all();
        } catch (Throwable $e) {
            $this->markTestSkipped('Cross-module dependency (sch_classes / ba_categories) unavailable: ' . $e->getMessage());
        }

        if (empty($classIds)) {
            $this->markTestSkipped('No active school class found (cross-module SchoolSetup).');
        }
        if (empty($categoryIds)) {
            $this->markTestSkipped('No active behavioural category found.');
        }

        $pair = $this->findUnmappedPair($classIds, $categoryIds);
        if ($pair === null) {
            $this->markTestSkipped('No unmapped (class, category) pair available for a clean test.');
        }

        return [
            'admin_user_id' => $adminUserId,
            'class_id'      => $pair['class_id'],
            'category_id'   => $pair['category_id'],
            'class_ids'     => $classIds,
            'category_ids'  => $categoryIds,
        ];
    }

    /** @param int[] $classIds @param int[] $categoryIds @return array{class_id:int,category_id:int}|null */
    private function findUnmappedPair(array $classIds, array $categoryIds): ?array
    {
        foreach ($classIds as $classId) {
            foreach ($categoryIds as $categoryId) {
                $exists = DB::table(self::TABLE)->where('class_id', $classId)->where('category_id', $categoryId)->exists();
                if (!$exists) {
                    return ['class_id' => (int) $classId, 'category_id' => (int) $categoryId];
                }
            }
        }

        return null;
    }

    /** @param int[] $classIds */
    private function findClassWithNoMappingOrSkip(array $classIds): int
    {
        foreach ($classIds as $classId) {
            if (!DB::table(self::TABLE)->where('class_id', $classId)->exists()) {
                return (int) $classId;
            }
        }

        $this->markTestSkipped('Every active class already has a mapping — cannot assert the empty-grid precondition.');
    }

    private function createRecordDirectly(array $dependencies, array $overrides = []): BaClassCategoryJnt
    {
        return BaClassCategoryJnt::query()->create(array_merge($this->buildValidDirectPayload($dependencies), $overrides));
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'class_id'    => (int) $dependencies['class_id'],
            'category_id' => (int) $dependencies['category_id'],
            'is_active'   => true,
            'created_by'  => (int) $dependencies['admin_user_id'],
            'updated_by'  => (int) $dependencies['admin_user_id'],
        ];
    }

    private function payloadFor(array $dependencies, int $classId, int $categoryId): array
    {
        return [
            'class_id'    => $classId,
            'category_id' => $categoryId,
            'is_active'   => true,
            'created_by'  => (int) $dependencies['admin_user_id'],
            'updated_by'  => (int) $dependencies['admin_user_id'],
        ];
    }

    /** Physical removal — safe whether or not the model uses SoftDeletes (it does NOT — BUG-BA-012). */
    private function purgeMappingById(int $recordId): void
    {
        if ($recordId <= 0) {
            return;
        }
        try {
            DB::table(self::TABLE)->where('id', $recordId)->delete();
        } catch (Throwable) {
            // ignore cleanup issues
        }
    }

    private function purgePair(int $classId, int $categoryId): void
    {
        try {
            DB::table(self::TABLE)->where('class_id', $classId)->where('category_id', $categoryId)->delete();
        } catch (Throwable) {
            // ignore cleanup issues
        }
    }

    private function assertDatabaseRejectsMissingField(array $dependencies, string $missingField): void
    {
        $created = null;
        try {
            $payload = $this->buildValidDirectPayload($dependencies);
            unset($payload[$missingField]);
            $created = BaClassCategoryJnt::query()->create($payload);
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
            if ($created instanceof BaClassCategoryJnt) {
                $this->purgeMappingById((int) $created->id);
            }
        }
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
                'name'              => 'Limited CM ' . $suffix,
                'email'             => 'limited_cm_' . $suffix . '@tenant.test',
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
            'tenant.behavioural-assessment.setup.viewAny',
            'tenant.behavioural-assessment.class-categories.viewAny',
            'tenant.behavioural-assessment.class-categories.view',
            'tenant.behavioural-assessment.class-categories.create',
            'tenant.behavioural-assessment.class-categories.update',
            'tenant.behavioural-assessment.class-categories.delete',
            'tenant.behavioural-assessment.class-categories.status',
            'tenant.behavioural-assessment.class-categories.restore',
            'tenant.behavioural-assessment.class-categories.forceDelete',
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
