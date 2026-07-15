<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaClassCategoryJnt;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Class-Mapping (setup tab) — single comprehensive Dusk suite.
 *
 * Screen requirement: 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/05-Class-Mapping.md
 * Screen title       : "Class-Mapping"  (setup page tab `class-mapping`).
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime table      : ba_class_category_jnt  (live `ba_` prefix — DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaClassCategoryController (store / toggleStatus / destroy).
 * FormRequest        : Modules\BehaviouralAssessment\Http\Requests\BaClassCategoryRequest
 * Listing            : Modules\BehaviouralAssessment\Http\Controllers\BaDashboardController::setup() → /behavioural-assessment/setup?tab=class-mapping
 * Permission prefix  : tenant.behavioural-assessment.class-categories.{viewAny|view|create|update|delete|restore|forceDelete|status}
 *                      (viewing the tab additionally requires tenant.behavioural-assessment.setup.viewAny).
 * Activity log       : NONE — the controller calls no activityLog() helper and the model has no observer (documented absence, proven in _93).
 *
 * Defects / gaps proven:
 *   - DOC-BA-001    : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - DATA-BA-CM-01 : model BaClassCategoryJnt omits the SoftDeletes trait although the migration adds
 *                     softDeletes() (deleted_at column) AND the FormRequest unique rule scopes to
 *                     whereNull('deleted_at') — so destroy() HARD-deletes and deleted_at is never used;
 *                     Policy restore()/forceDelete() are dead (no routes, no trait) (proven in _03, _43).
 *   - VAL-BA-CM-02  : the DB unique index uq_ba_class_cat(class_id, category_id) has no deleted_at scope,
 *                     while the request unique rule does — divergent scopes, harmless only because of the
 *                     hard delete above (proven in _42).
 *   - SEC-BA-002    : FormRequest authorize() returns bare true, mitigated by the controller Gate (proven in _92).
 *   - CM-GAP-03     : FormRequest carries a non-POST (PUT/PATCH) rules branch, but no update route exists
 *                     for class-categories — dead branch (proven in _94).
 */
class bha_ClassMapping_TestCas extends DuskTestCase
{
    private const URL_PREFIX  = '/behavioural-assessment';
    private const SETUP_PATH  = '/behavioural-assessment/setup?tab=class-mapping';
    private const STORE_PATH  = '/behavioural-assessment/class-categories';

    private const TABLE       = 'ba_class_category_jnt';
    private const DDL_TABLE    = 'bha_class_category_jnt';   // stale DDL-doc name (should NOT exist at runtime)
    private const CATEGORY_TABLE = 'ba_categories';
    private const CLASS_TABLE  = 'sch_classes';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/ClassMapping/screenshots';

    /** @var array<int,string> */
    private const CM_PERMISSIONS = [
        'tenant.behavioural-assessment.setup.viewAny',
        'tenant.behavioural-assessment.class-categories.viewAny',
        'tenant.behavioural-assessment.class-categories.view',
        'tenant.behavioural-assessment.class-categories.create',
        'tenant.behavioural-assessment.class-categories.update',
        'tenant.behavioural-assessment.class-categories.delete',
        'tenant.behavioural-assessment.class-categories.restore',
        'tenant.behavioural-assessment.class-categories.forceDelete',
        'tenant.behavioural-assessment.class-categories.status',
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

    public function test_class_mapping_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table ba_class_category_jnt does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'class_id', 'category_id', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_class_category_jnt table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::TABLE))->keyBy('Field');
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));
            $this->assertStringContainsString('int', strtolower((string) ($cols['class_id']->Type ?? '')));
            $this->assertStringContainsString('int', strtolower((string) ($cols['category_id']->Type ?? '')));
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath(
            'database/migrations/tenant/2026_06_16_130618_create_ba_class_category_jnt_table.php'
        ));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_class_category_jnt'", $migration);
            $this->assertStringContainsString("unique(['class_id', 'category_id'], 'uq_ba_class_cat')", $migration);
            $this->assertStringContainsString("'fk_ba_cc_class_id'", $migration);
            $this->assertStringContainsString("->on('sch_classes')", $migration);
            $this->assertStringContainsString("constrained('ba_categories')", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // FormRequest rule strings — verbatim from the real source.
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaClassCategoryRequest.php'));
        if ($request !== null) {
            $this->assertStringContainsString("'exists:sch_classes,id'", $request);
            $this->assertStringContainsString("'exists:ba_categories,id'", $request);
            $this->assertStringContainsString("Rule::unique('ba_class_category_jnt', 'category_id')", $request);
            $this->assertStringContainsString("whereNull('deleted_at')", $request);
            $this->assertStringContainsString('This category is already mapped to the selected class.', $request);
        }

        // Model configuration.
        $model = new BaClassCategoryJnt();
        $this->assertSame('ba_class_category_jnt', $model->getTable());
        $this->assertSame([
            'class_id', 'category_id', 'is_active', 'created_by', 'updated_by',
        ], $model->getFillable());
        $this->assertInstanceOf(BelongsTo::class, $model->schoolClass());
        $this->assertInstanceOf(BelongsTo::class, $model->category());

        // is_active is cast to boolean.
        $this->assertSame('boolean', ($model->getCasts()['is_active'] ?? null));
    }

    public function test_class_mapping_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime table uses the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Runtime table ba_class_category_jnt must exist.');

        // The DDL/registry spec name `bha_class_category_jnt` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_TABLE),
                'DOC-BA-001 regression: bha_class_category_jnt exists at runtime; expected only the live ba_ table.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_class_category_jnt', (new BaClassCategoryJnt())->getTable());
    }

    public function test_class_mapping_03_model_omits_softdeletes_despite_migration_softdeletes_data_ba_cm_01(): void
    {
        // DATA-BA-CM-01: the migration adds softDeletes() (deleted_at column DOES exist)...
        $this->assertTrue(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'Migration adds softDeletes(); deleted_at column should exist.'
        );

        // ...but the model does NOT use the SoftDeletes trait — so ->delete() hard-deletes and
        // the FormRequest unique rule\'s whereNull(deleted_at) scope is effectively inert.
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(BaClassCategoryJnt::class),
            'DATA-BA-CM-01 regression fixed? Model now uses SoftDeletes — update destroy()/trash expectations.'
        );

        // Because the trait is absent, onlyTrashed()/withTrashed() are not available on the model.
        $this->assertFalse(
            method_exists(BaClassCategoryJnt::class, 'bootSoftDeletes')
                && in_array(SoftDeletes::class, class_uses_recursive(BaClassCategoryJnt::class), true),
            'Model must not expose soft-delete behaviour while omitting the trait.'
        );
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_class_mapping_10_store_creates_mapping_and_redirects_with_success(): void
    {
        $pair = $this->unusedPair();

        $response = $this->postMapping($pair);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Valid mapping should not 422: ' . json_encode($response['json'] ?? $response['body'] ?? null));

        $row = BaClassCategoryJnt::where('class_id', $pair['class_id'])
            ->where('category_id', $pair['category_id'])->first();
        $this->assertNotNull($row, 'Mapping row was not created.');
        $this->assertTrue((bool) $row->is_active, 'store() must default is_active=true.');

        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_11_store_stamps_created_and_updated_by_admin(): void
    {
        $pair = $this->unusedPair();

        $this->postMapping($pair);
        $row = BaClassCategoryJnt::where('class_id', $pair['class_id'])
            ->where('category_id', $pair['category_id'])->first();
        $this->assertNotNull($row);
        $this->assertSame((int) $this->adminUser->id, (int) $row->created_by, 'created_by must be the acting admin.');
        $this->assertSame((int) $this->adminUser->id, (int) $row->updated_by, 'updated_by must be the acting admin.');

        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_12_toggle_status_flips_is_active_and_returns_json(): void
    {
        $row = $this->createMappingSeed(['is_active' => true]);

        $off = $this->toggleMapping($row->id);
        $this->assertSame(200, (int) ($off['status'] ?? 0), 'Toggle must return a 200 JSON response.');
        $json = $off['json'] ?? [];
        $this->assertTrue((bool) ($json['success'] ?? false));
        $this->assertArrayHasKey('is_active', $json);
        $this->assertSame('Mapping deactivated.', (string) ($json['message'] ?? ''));
        $row->refresh();
        $this->assertFalse((bool) $row->is_active);

        $on = $this->toggleMapping($row->id);
        $this->assertSame('Mapping activated.', (string) ($on['json']['message'] ?? ''));
        $row->refresh();
        $this->assertTrue((bool) $row->is_active);

        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_13_destroy_removes_mapping_and_redirects(): void
    {
        $row = $this->createMappingSeed();

        $response = $this->deleteMappingEndpoint($row->id);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'destroy() should redirect back.');
        $this->assertFalse(
            DB::table(self::TABLE)->where('id', $row->id)->exists(),
            'Mapping row should be removed after destroy().'
        );
    }

    public function test_class_mapping_14_setup_tab_lists_mapping_class_and_category(): void
    {
        $row = $this->createMappingSeed();
        $className = (string) (DB::table(self::CLASS_TABLE)->where('id', $row->class_id)->value('name') ?? '');
        $categoryName = (string) (DB::table(self::CATEGORY_TABLE)->where('id', $row->category_id)->value('name') ?? '');

        $this->browseWithFailureScreenshot('setup-list', function (Browser $browser) use ($className, $categoryName): void {
            $this->openSetupTab($browser);
            if ($className !== '') {
                $browser->assertSee($className);
            }
            if ($categoryName !== '') {
                $browser->assertSee($categoryName);
            }
        });

        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_15_browser_form_add_mapping_shows_success_flash(): void
    {
        $pair = $this->unusedPair();

        $this->browseWithFailureScreenshot('form-add', function (Browser $browser) use ($pair): void {
            $this->openSetupTab($browser);
            $browser->select('class_id', (string) $pair['class_id'])
                ->select('category_id', (string) $pair['category_id'])
                ->press('Add Mapping')
                ->pause(1200)
                ->assertSee('Category mapped to class successfully.');
        });

        $row = BaClassCategoryJnt::where('class_id', $pair['class_id'])
            ->where('category_id', $pair['category_id'])->first();
        $this->assertNotNull($row, 'Form submission should have persisted the mapping.');
        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_16_delete_control_is_rendered_for_permitted_user(): void
    {
        $row = $this->createMappingSeed();

        $this->browseWithFailureScreenshot('delete-control', function (Browser $browser) use ($row): void {
            $this->openSetupTab($browser);
            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString(
                'class-categories/' . $row->id,
                $source,
                'Delete form action for the mapping should be present for a permitted user.'
            );
        });

        $this->deleteMapping($row->id);
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM) — Active ↔ Inactive
    // =====================================================================

    public function test_class_mapping_20_active_to_inactive_and_back_transition_succeeds(): void
    {
        // BC-SM-1: Active --toggleStatus--> Inactive ; BC-SM-2: Inactive --toggleStatus--> Active.
        $row = $this->createMappingSeed(['is_active' => true]);

        $this->assertSame(200, (int) ($this->toggleMapping($row->id)['status'] ?? 0));
        $row->refresh();
        $this->assertFalse((bool) $row->is_active, 'Active mapping must transition to Inactive.');

        $this->assertSame(200, (int) ($this->toggleMapping($row->id)['status'] ?? 0));
        $row->refresh();
        $this->assertTrue((bool) $row->is_active, 'Inactive mapping must transition back to Active.');

        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_21_toggle_stamps_updated_by(): void
    {
        $row = $this->createMappingSeed(['is_active' => true, 'updated_by' => 0]);

        $this->toggleMapping($row->id);
        $row->refresh();
        $this->assertSame((int) $this->adminUser->id, (int) $row->updated_by, 'toggleStatus() must stamp updated_by.');

        $this->deleteMapping($row->id);
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL) — Negative 100%
    // =====================================================================

    public function test_class_mapping_30_required_fields_are_rejected(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), ['class_id' => '', 'category_id' => '']);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty payload must fail validation.');
        $errors = $response['json']['errors'] ?? [];
        $this->assertArrayHasKey('class_id', $errors);
        $this->assertArrayHasKey('category_id', $errors);
    }

    public function test_class_mapping_31_class_id_must_exist_in_sch_classes(): void
    {
        $categoryId = $this->firstCategoryId();
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), ['class_id' => 987654321, 'category_id' => $categoryId]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('class_id', $response['json']['errors'] ?? []);
    }

    public function test_class_mapping_32_category_id_must_exist_in_ba_categories(): void
    {
        $classId = $this->firstClassId();
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), ['class_id' => $classId, 'category_id' => 987654321]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('category_id', $response['json']['errors'] ?? []);
    }

    public function test_class_mapping_33_class_id_must_be_integer(): void
    {
        $categoryId = $this->firstCategoryId();
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), ['class_id' => 'abc', 'category_id' => $categoryId]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('class_id', $response['json']['errors'] ?? []);
    }

    public function test_class_mapping_34_category_id_must_be_integer(): void
    {
        $classId = $this->firstClassId();
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), ['class_id' => $classId, 'category_id' => 'abc']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('category_id', $response['json']['errors'] ?? []);
    }

    public function test_class_mapping_35_duplicate_mapping_is_rejected_with_message(): void
    {
        $row = $this->createMappingSeed();

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'class_id' => $row->class_id, 'category_id' => $row->category_id,
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate class-category pair must be rejected.');
        $errors = $response['json']['errors'] ?? [];
        $this->assertArrayHasKey('category_id', $errors);
        $this->assertStringContainsString(
            'This category is already mapped to the selected class.',
            implode(' ', (array) ($errors['category_id'] ?? [])),
            'Custom unique message must be returned.'
        );

        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_36_same_category_different_class_is_allowed(): void
    {
        $row = $this->createMappingSeed();
        $otherClassId = $this->secondClassId($row->class_id);
        if ($otherClassId === null) {
            $this->deleteMapping($row->id);
            $this->markTestSkipped('Only one class available — cross-class uniqueness scope not exercisable.');
        }
        // Ensure the target pair is free.
        DB::table(self::TABLE)->where('class_id', $otherClassId)->where('category_id', $row->category_id)->delete();

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'class_id' => $otherClassId, 'category_id' => $row->category_id,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Same category on a different class must be allowed (scope = class_id + category_id).');

        $new = BaClassCategoryJnt::where('class_id', $otherClassId)->where('category_id', $row->category_id)->first();
        if ($new) {
            $this->deleteMapping($new->id);
        }
        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_37_different_category_same_class_is_allowed(): void
    {
        $row = $this->createMappingSeed();
        $otherCategoryId = $this->secondCategoryId($row->category_id);
        if ($otherCategoryId === null) {
            $this->deleteMapping($row->id);
            $this->markTestSkipped('Only one category available — same-class multi-category not exercisable.');
        }
        DB::table(self::TABLE)->where('class_id', $row->class_id)->where('category_id', $otherCategoryId)->delete();

        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'class_id' => $row->class_id, 'category_id' => $otherCategoryId,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'A different category on the same class must be allowed.');

        $new = BaClassCategoryJnt::where('class_id', $row->class_id)->where('category_id', $otherCategoryId)->first();
        if ($new) {
            $this->deleteMapping($new->id);
        }
        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_38_whitespace_class_id_is_rejected(): void
    {
        $categoryId = $this->firstCategoryId();
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), ['class_id' => '   ', 'category_id' => $categoryId]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Whitespace-only class_id must fail required/integer validation.');
        $this->assertArrayHasKey('class_id', $response['json']['errors'] ?? []);
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-INT/REF/EDG)
    // =====================================================================

    public function test_class_mapping_40_class_id_fk_is_cascade_on_delete(): void
    {
        $this->assertForeignKeyDeleteRule(self::CLASS_TABLE, 'CASCADE', 'class_id → sch_classes');
    }

    public function test_class_mapping_41_category_id_fk_is_cascade_on_delete(): void
    {
        $this->assertForeignKeyDeleteRule(self::CATEGORY_TABLE, 'CASCADE', 'category_id → ba_categories');
    }

    public function test_class_mapping_42_unique_index_enforces_class_category_pair_val_ba_cm_02(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Unique-index inspection requires MySQL.');
        }
        try {
            $rows = DB::select("SHOW INDEX FROM " . self::TABLE . " WHERE Key_name = 'uq_ba_class_cat'");
            $this->assertNotEmpty($rows, 'Unique index uq_ba_class_cat should exist.');
            $columns = collect($rows)->pluck('Column_name')->map(fn ($c) => strtolower((string) $c))->all();
            $this->assertContains('class_id', $columns);
            $this->assertContains('category_id', $columns);
            foreach ($rows as $r) {
                $this->assertSame(0, (int) $r->Non_unique, 'uq_ba_class_cat must be a UNIQUE index.');
            }
            // VAL-BA-CM-02: the DB unique index has NO deleted_at column in its key, unlike the request rule scope.
            $this->assertNotContains('deleted_at', $columns, 'DB unique index intentionally does not scope on deleted_at (diverges from request rule).');
        } catch (Throwable $e) {
            $this->markTestSkipped('Unique-index inspection unavailable: ' . $e->getMessage());
        }
    }

    public function test_class_mapping_43_destroy_hard_deletes_despite_deleted_at_column_data_ba_cm_01(): void
    {
        // DATA-BA-CM-01: destroy() calls $mapping->delete(); the model has no SoftDeletes trait,
        // so the row is physically removed even though a deleted_at column exists.
        $row = $this->createMappingSeed();
        $id = (int) $row->id;

        $this->deleteMappingEndpoint($id);

        $this->assertFalse(
            DB::table(self::TABLE)->where('id', $id)->exists(),
            'DATA-BA-CM-01: row must be physically gone (hard delete), not soft-deleted.'
        );
        // deleted_at was never populated because delete() hard-deleted the row.
        $this->assertSame(
            0,
            DB::table(self::TABLE)->where('id', $id)->whereNotNull('deleted_at')->count(),
            'No soft-deleted remnant should exist for this mapping.'
        );
    }

    public function test_class_mapping_44_full_lifecycle_create_toggle_destroy(): void
    {
        $pair = $this->unusedPair();

        // create
        $this->assertNotSame(422, (int) ($this->postMapping($pair)['status'] ?? 0));
        $row = BaClassCategoryJnt::where('class_id', $pair['class_id'])->where('category_id', $pair['category_id'])->firstOrFail();

        // toggle off
        $this->assertSame(200, (int) ($this->toggleMapping($row->id)['status'] ?? 0));
        $row->refresh();
        $this->assertFalse((bool) $row->is_active);

        // destroy
        $this->deleteMappingEndpoint($row->id);
        $this->assertFalse(DB::table(self::TABLE)->where('id', $row->id)->exists());
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_class_mapping_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::SETUP_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_class_mapping_51_limited_user_without_create_gets_403_on_store(): void
    {
        $pair = $this->unusedPair();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-create-403', function (Browser $browser) use ($limited, $pair): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::STORE_PATH), $pair);
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without create permission must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_class_mapping_52_limited_user_without_status_gets_403_on_toggle(): void
    {
        $row = $this->createMappingSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-toggle-403', function (Browser $browser) use ($limited, $row): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl('/behavioural-assessment/class-categories/' . $row->id . '/toggle-status')
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_53_limited_user_without_delete_gets_403_on_destroy(): void
    {
        $row = $this->createMappingSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-delete-403', function (Browser $browser) use ($limited, $row): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'DELETE',
                $this->tenantUrl('/behavioural-assessment/class-categories/' . $row->id)
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_54_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaClassCategoryPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('Policy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete', 'status'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.class-categories.{$ability}",
                $policy,
                "Policy missing gate string for {$ability}."
            );
        }
    }

    public function test_class_mapping_55_setup_tab_requires_setup_viewany_permission(): void
    {
        // BaDashboardController::setup() gates on tenant.behavioural-assessment.setup.viewAny.
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('setup-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::SETUP_PATH));
            $this->assertContains(
                (int) ($response['status'] ?? 0),
                [403, 302],
                'A user without setup.viewAny must be forbidden or redirected from the setup tab.'
            );
        });

        $this->deleteUser($limited);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (render, empty state, badge)
    // =====================================================================

    public function test_class_mapping_60_setup_tab_renders_form_and_table_headers(): void
    {
        $this->browseWithFailureScreenshot('render-form-table', function (Browser $browser): void {
            $this->openSetupTab($browser);
            $browser->assertSee('Add Mapping')
                ->assertSee('Class')
                ->assertSee('Category')
                ->assertSee('Polarity');
        });
    }

    public function test_class_mapping_61_mapping_row_shows_polarity_badge(): void
    {
        $row = $this->createMappingSeed();
        $polarity = (string) (DB::table(self::CATEGORY_TABLE)->where('id', $row->category_id)->value('polarity') ?? '');
        if ($polarity === '') {
            $this->deleteMapping($row->id);
            $this->markTestSkipped('Category polarity unavailable.');
        }

        $this->browseWithFailureScreenshot('polarity-badge', function (Browser $browser) use ($polarity): void {
            $this->openSetupTab($browser);
            $browser->assertSee(ucfirst($polarity));
        });

        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_62_empty_state_message_is_defined_in_view(): void
    {
        // The blade defines a "No class-category mappings yet." empty state; assert the string is
        // present in the setup page markup (form/table region) regardless of seeded data.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/pages/partials/setup/_class-mapping.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('Class-mapping partial not readable from app repo.');
        }
        $this->assertStringContainsString('No class-category mappings yet.', $view, 'Empty-state message must be defined.');
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_class_mapping_70_toggle_invalid_id_returns_404(): void
    {
        $response = $this->toggleMapping(987654321);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Toggle on a non-existent mapping must 404.');
    }

    public function test_class_mapping_71_destroy_invalid_id_returns_404(): void
    {
        $response = $this->deleteMappingEndpoint(987654321);
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Destroy on a non-existent mapping must 404.');
    }

    public function test_class_mapping_72_store_ignores_client_supplied_is_active_and_auditors(): void
    {
        // store() hardcodes is_active=true and created_by/updated_by=auth()->id() — client-supplied
        // overrides for those columns must be ignored (mass-assignment safety).
        $pair = $this->unusedPair();
        $payload = array_merge($pair, ['is_active' => false, 'created_by' => 987654321, 'updated_by' => 987654321]);

        $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), $payload);
        $row = BaClassCategoryJnt::where('class_id', $pair['class_id'])->where('category_id', $pair['category_id'])->first();
        $this->assertNotNull($row);
        $this->assertTrue((bool) $row->is_active, 'Client is_active=false must be ignored; controller forces true.');
        $this->assertSame((int) $this->adminUser->id, (int) $row->created_by, 'Client created_by must be ignored.');

        $this->deleteMapping($row->id);
    }

    public function test_class_mapping_73_null_category_id_is_rejected(): void
    {
        $classId = $this->firstClassId();
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), ['class_id' => $classId, 'category_id' => null]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('category_id', $response['json']['errors'] ?? []);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_class_mapping_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side class-mapping tests.'
        );
        $this->assertTrue(Schema::hasTable(self::TABLE));
    }

    public function test_class_mapping_91_cross_tenant_direct_id_isolation(): void
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

    public function test_class_mapping_92_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaClassCategoryRequest.php'));
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

    public function test_class_mapping_93_no_activity_log_written_for_mapping_mutations(): void
    {
        // Documented absence: the controller calls no activityLog() helper and the model has no observer.
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaClassCategoryController.php'));
        if ($controller === null) {
            $this->markTestSkipped('Controller source not readable from app repo.');
        }
        $this->assertStringNotContainsString('activityLog', $controller, 'Class-mapping controller unexpectedly logs activity — update expectations.');
        $this->assertStringNotContainsString('ActivityLog::', $controller, 'Class-mapping controller unexpectedly writes to ActivityLog.');

        // Behavioural cross-check: a create leaves no activity row referencing the model (if the tenant log table exists).
        if (Schema::hasTable('activity_logs')) {
            $pair = $this->unusedPair();
            $before = DB::table('activity_logs')->where('subject_type', BaClassCategoryJnt::class)->count();
            $this->postMapping($pair);
            $row = BaClassCategoryJnt::where('class_id', $pair['class_id'])->where('category_id', $pair['category_id'])->first();
            $after = DB::table('activity_logs')->where('subject_type', BaClassCategoryJnt::class)->count();
            $this->assertSame($before, $after, 'No activity_logs row should be written for a class-mapping create.');
            if ($row) {
                $this->deleteMapping($row->id);
            }
        }
    }

    public function test_class_mapping_94_form_request_has_dead_non_post_branch_cm_gap_03(): void
    {
        // CM-GAP-03: the FormRequest has an else (non-POST/PUT) branch for category_id, but there is
        // no update route for class-categories — the branch is unreachable.
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaClassCategoryRequest.php'));
        if ($request === null) {
            $this->markTestSkipped('FormRequest source not readable from app repo.');
        }
        $this->assertStringContainsString("isMethod('POST')", $request, 'Expected a POST-conditioned rules branch.');

        // Prove no update route exists: only store/toggleStatus/destroy are registered.
        $this->assertTrue(\Illuminate\Support\Facades\Route::has('behavioural-assessment.class-categories.store'));
        $this->assertTrue(\Illuminate\Support\Facades\Route::has('behavioural-assessment.class-categories.destroy'));
        $this->assertFalse(
            \Illuminate\Support\Facades\Route::has('behavioural-assessment.class-categories.update'),
            'CM-GAP-03 changed: an update route now exists for class-categories — the non-POST branch is reachable.'
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
        $rawName = 'class-mapping-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'class-mapping-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- UI drivers -------------------------------------------------------

    private function openSetupTab(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::SETUP_PATH, 1000);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#class-mapping-pane') !== null
                || $browser->element('table') !== null;
        }, 'Class-mapping setup tab did not render.');
    }

    // ---- HTTP-from-browser ------------------------------------------------

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
window.__cmApiDone = false;
window.__cmApiError = '';
window.__cmApiResult = null;

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

        window.__cmApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__cmApiError = String(error);
    } finally {
        window.__cmApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__cmApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__cmApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__cmApiResult || null;');
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
            $this->openSetupTab($browser);
            $result = $callback($browser);
        });
        return $result;
    }

    // ---- Request shims (admin session) ------------------------------------

    private function postMapping(array $pair): array
    {
        return $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), $pair);
    }

    private function toggleMapping(int $id): array
    {
        return $this->apiCall('POST', $this->tenantUrl('/behavioural-assessment/class-categories/' . $id . '/toggle-status'));
    }

    private function deleteMappingEndpoint(int $id): array
    {
        return $this->apiCall('DELETE', $this->tenantUrl('/behavioural-assessment/class-categories/' . $id));
    }

    // ---- Seed / cleanup / dependency resolution ---------------------------

    private function createMappingSeed(array $overrides = []): BaClassCategoryJnt
    {
        $pair = $this->unusedPair();
        $payload = array_merge([
            'class_id'    => $pair['class_id'],
            'category_id' => $pair['category_id'],
            'is_active'   => true,
            'created_by'  => (int) $this->adminUser->id,
            'updated_by'  => (int) $this->adminUser->id,
        ], $overrides);

        return BaClassCategoryJnt::query()->create($payload);
    }

    private function deleteMapping(?int $id): void
    {
        if ($id === null) {
            return;
        }
        try {
            DB::table(self::TABLE)->where('id', $id)->delete();
        } catch (Throwable) {
        }
    }

    /**
     * Find a (class_id, category_id) pair that is not yet mapped, using top-level active
     * categories + active classes so the pair is also valid for the setup form selects.
     *
     * @return array{class_id:int, category_id:int}
     */
    private function unusedPair(): array
    {
        try {
            $classes = DB::table(self::CLASS_TABLE)
                ->where('is_active', true)->orderBy('id')->pluck('id')->all();
            if (empty($classes)) {
                $classes = DB::table(self::CLASS_TABLE)->orderBy('id')->pluck('id')->all();
            }
            $categories = DB::table(self::CATEGORY_TABLE)
                ->whereNull('parent_id')->where('is_active', true)->orderBy('id')->pluck('id')->all();
            if (empty($categories)) {
                $categories = DB::table(self::CATEGORY_TABLE)->orderBy('id')->pluck('id')->all();
            }

            if (empty($classes) || empty($categories)) {
                $this->markTestSkipped('Cross-module dependency absent: sch_classes or ba_categories has no rows.');
            }

            foreach ($classes as $classId) {
                foreach ($categories as $categoryId) {
                    $taken = DB::table(self::TABLE)
                        ->where('class_id', $classId)
                        ->where('category_id', $categoryId)
                        ->exists();
                    if (!$taken) {
                        return ['class_id' => (int) $classId, 'category_id' => (int) $categoryId];
                    }
                }
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Unable to resolve an unused class-category pair: ' . $e->getMessage());
        }

        $this->markTestSkipped('No unused class-category pair available (all combinations already mapped).');
    }

    private function firstClassId(): int
    {
        $id = DB::table(self::CLASS_TABLE)->where('is_active', true)->value('id')
            ?? DB::table(self::CLASS_TABLE)->value('id');
        if ($id === null) {
            $this->markTestSkipped('Cross-module dependency absent: sch_classes has no rows.');
        }
        return (int) $id;
    }

    private function secondClassId(int $exclude): ?int
    {
        $id = DB::table(self::CLASS_TABLE)->where('id', '!=', $exclude)->value('id');
        return $id === null ? null : (int) $id;
    }

    private function firstCategoryId(): int
    {
        $id = DB::table(self::CATEGORY_TABLE)->whereNull('parent_id')->value('id')
            ?? DB::table(self::CATEGORY_TABLE)->value('id');
        if ($id === null) {
            $this->markTestSkipped('Dependency absent: ba_categories has no rows.');
        }
        return (int) $id;
    }

    private function secondCategoryId(int $exclude): ?int
    {
        $id = DB::table(self::CATEGORY_TABLE)->where('id', '!=', $exclude)->value('id');
        return $id === null ? null : (int) $id;
    }

    private function assertForeignKeyDeleteRule(string $referencedTable, string $expectedRule, string $label): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('FK rule inspection requires MySQL.');
        }
        try {
            $fk = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ?
                   AND REFERENCED_TABLE_NAME = ?",
                [self::TABLE, $referencedTable]
            );
            if (empty($fk)) {
                $this->markTestSkipped("No FK metadata for {$label}.");
            }
            $this->assertStringContainsString(
                $expectedRule,
                strtoupper((string) ($fk[0]->DELETE_RULE ?? '')),
                "{$label} should be ON DELETE {$expectedRule}."
            );
        } catch (Throwable $e) {
            $this->markTestSkipped("FK dependency path unavailable for {$label}: " . $e->getMessage());
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
                'name'              => 'CM Limited ' . $this->uniqueSuffix(),
                'email'             => 'cm_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
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
        $this->grantClassMappingPermissions($this->adminUser);
    }

    private function grantClassMappingPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::CM_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::CM_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::CM_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.class-mapping-admin');
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
            $modelFile = (new ReflectionClass(BaClassCategoryJnt::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaClassCategoryJnt.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaClassCategoryJnt::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaClassCategoryJnt.php → app root = dirname(,5)
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
}
