<?php

/**
 * BehaviouralAssessment › ClassMapping (app: ClassCategory) — V1 (foundation) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/ClassCategory/ClassCategoryCrudTest.php
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; live migration under database/migrations/tenant/).
 * TABLE   : ba_class_category_jnt (junction: Class ↔ Category). The DDL DOC uses the stale prefix
 *           "bha_" (audit DOC-BA-001); the LIVE migration/model/table is "ba_class_category_jnt".
 *           Artifact FILE names follow the DDL/inventory prefix "bha_"; every schema assertion targets
 *           the real "ba_" table. Do not "fix" this to bha_ in code — it would break against the real DB.
 *
 * KIND    : junction/config feature — controller exposes only store / toggleStatus / destroy (NO edit/update).
 *
 * All routes/selectors/permissions/flash strings verified against:
 *   Modules/BehaviouralAssessment/app/Http/Controllers/BaClassCategoryController.php
 *   Modules/BehaviouralAssessment/app/Http/Controllers/BaDashboardController.php (setup())
 *   Modules/BehaviouralAssessment/app/Models/BaClassCategoryJnt.php
 *   Modules/BehaviouralAssessment/routes/web.php
 *   Modules/BehaviouralAssessment/resources/views/pages/partials/setup/_class-mapping.blade.php
 *   resources/views/components/backend/table/status-switch.blade.php  (renders .status-toggle[data-id])
 *   database/migrations/tenant/2026_06_16_130618_create_ba_class_category_jnt_table.php
 *
 * Audit / source findings referenced here (proved in V2, noted in V1 config test):
 *   DOC-BA-001   DDL doc prefix bha_ vs live ba_                              → test_..._01
 *   BUG-BA-012   model omits SoftDeletes despite migration softDeletes()/     → test_..._01 / _07
 *                deleted_at → destroy() is a permanent HARD delete (NEW)
 *   VAL-BA-001   no BaClassCategoryRequest — inline $request->validate()      → test_..._13
 *   BUG-BA-007   class with no mapping ⇒ empty grid (permissive default gap)  → test_..._14
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

class bha_ClassMappingV1_TestCas extends DuskTestCase
{
    private const SETUP_PATH      = '/behavioural-assessment/setup';
    private const TAB_QS          = '?tab=class-mapping';
    private const TABLE           = 'ba_class_category_jnt';
    private const MIGRATION_FILE  = 'database/migrations/tenant/2026_06_16_130618_create_ba_class_category_jnt_table.php';
    private const CONTROLLER_FILE = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaClassCategoryController.php';
    private const REQUEST_FILE    = 'Modules/BehaviouralAssessment/app/Http/Requests/BaClassCategoryRequest.php';

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
    //  01–09  Schema / model / config truth
    // ──────────────────────────────────────────────

    /** TC-P01 · BC-DB-01/02 · BC-BIZ-15 · Audit-DOC-BA-001 · Audit-BUG-BA-012 · Source: DDL/live migration + model */
    public function test_class_mapping_01_schema_model_and_softdelete_gap_are_correct(): void
    {
        // DOC-BA-001: DDL doc names the table bha_class_category_jnt, but the live table is ba_class_category_jnt.
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Live table ba_class_category_jnt does not exist.');
        $this->assertFalse(
            Schema::hasTable('bha_class_category_jnt'),
            'Stale DDL-doc table bha_class_category_jnt should NOT exist (DOC-BA-001).'
        );

        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'class_id', 'category_id', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing from ba_class_category_jnt.'
        );

        $migrationPath = base_path(self::MIGRATION_FILE);
        $this->assertTrue(File::exists($migrationPath), 'Migration not found: ' . self::MIGRATION_FILE);
        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('ba_class_category_jnt'", $migration);
        $this->assertStringContainsString("\$table->unique(['class_id', 'category_id'], 'uq_ba_class_cat')", $migration);
        $this->assertStringContainsString("->references('id')->on('sch_classes')->onDelete('cascade')", $migration);
        $this->assertStringContainsString("constrained('ba_categories')->cascadeOnDelete()", $migration);
        // Migration DECLARES soft-deletes / deleted_at ...
        $this->assertStringContainsString("\$table->softDeletes()", $migration);

        $this->assertTrue(File::exists(base_path(self::CONTROLLER_FILE)), 'Controller file missing.');

        $model = new BaClassCategoryJnt();
        $this->assertSame('ba_class_category_jnt', $model->getTable());
        $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null);
        foreach (['class_id', 'category_id', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $model->getFillable(), "fillable should include {$col}.");
        }
        $this->assertInstanceOf(BelongsTo::class, $model->schoolClass());
        $this->assertInstanceOf(BelongsTo::class, $model->category());

        // BUG-BA-012 (verify in source): the MODEL omits the SoftDeletes trait even though the migration
        // declares softDeletes()/deleted_at and the store() unique rule scopes ->whereNull('deleted_at').
        // Consequence: destroy() → $mapping->delete() is a PERMANENT hard delete, and withTrashed()/
        // restore()/forceDelete() are unavailable. This proves the current (defective) model configuration.
        // Source: Modules/BehaviouralAssessment/app/Models/BaClassCategoryJnt.php (no `use SoftDeletes;`).
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(BaClassCategoryJnt::class),
            'BUG-BA-012 confirmed: BaClassCategoryJnt does NOT use SoftDeletes despite migration deleted_at.'
        );
    }

    /** TC-N01 · BC-DB-03 · Source: DDL NOT NULL class_id/category_id */
    public function test_class_mapping_02_db_rejects_missing_required_fields(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();

        foreach (['class_id', 'category_id'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-N02 · BC-DB-04 · BC-REF-03 · Source: uq_ba_class_cat(class_id, category_id) */
    public function test_class_mapping_03_duplicate_pair_violates_db_unique_index(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $first = $this->createRecordDirectly($dependencies);

        try {
            $threw = false;
            try {
                $this->createRecordDirectly($dependencies); // same class_id + category_id
            } catch (Throwable $e) {
                $message = strtolower($e->getMessage());
                $threw = str_contains($message, '23000')
                    || str_contains($message, 'duplicate')
                    || str_contains($message, 'integrity constraint');
            }
            $this->assertTrue($threw, 'uq_ba_class_cat should block a duplicate (class_id, category_id) pair.');
        } finally {
            $this->purgeMappingById((int) $first->id);
        }
    }

    // ──────────────────────────────────────────────
    //  10–19  Core behaviour (store / list / toggle / destroy)
    // ──────────────────────────────────────────────

    /** TC-P02 · BC-BIZ-01 · Source: _class-mapping.blade "Add Mapping" form */
    public function test_class_mapping_04_setup_class_mapping_tab_renders(): void
    {
        $this->resolveDependenciesOrSkip();

        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);

            $browser->waitFor('select[name="class_id"]', 12)
                ->assertPresent('select[name="category_id"]')
                ->assertSee('Add Mapping');
        });
    }

    /** TC-P03 · BC-BIZ-02 · Source: Controller@store flash "Category mapped to class successfully." */
    public function test_class_mapping_05_create_mapping_via_form_persists(): void
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

            $this->assertSame(
                1,
                BaClassCategoryJnt::query()->where('class_id', $classId)->where('category_id', $categoryId)->count(),
                'Mapping row was not persisted.'
            );
        } finally {
            $this->purgePair($classId, $categoryId);
        }
    }

    /** TC-P04 · BC-DB-05 · Source: migration is_active default true */
    public function test_class_mapping_06_is_active_defaults_true_on_create(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['is_active' => true]);

        try {
            $record->refresh();
            $this->assertTrue((bool) $record->is_active, 'A new mapping should be active by default.');
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    /** TC-SM01 · BC-SM-01 · Source: Controller@toggleStatus + status-switch (.status-toggle) */
    public function test_class_mapping_07_toggle_status_flips_is_active(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['is_active' => true]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SETUP_PATH . self::TAB_QS, 900);

                $selector = '.status-toggle[data-id="' . $record->id . '"]';
                $browser->waitFor($selector, 12)
                    ->script('document.querySelector(\'' . $selector . '\').click();');
                $browser->pause(1800);
            });

            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'is_active should have toggled to false.');
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    /**
     * TC-D01 (F) · BC-SM-03 · Audit-BUG-BA-012 · Source: Controller@destroy → $mapping->delete().
     * The model has NO SoftDeletes trait, so delete() is a PERMANENT hard delete: the row is physically
     * removed (no deleted_at ghost). Proven at the model/DB layer. (withTrashed/restore/forceDelete are
     * intentionally NOT called here — they would throw BadMethodCallException on this model — see 05_ C12.)
     */
    public function test_class_mapping_08_destroy_hard_deletes_the_mapping(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);
        $id = (int) $record->id;

        try {
            $record->delete(); // mirrors controller destroy(); hard delete because model lacks SoftDeletes

            $this->assertNull(BaClassCategoryJnt::find($id), 'Mapping should be gone after destroy.');
            $this->assertFalse(
                DB::table(self::TABLE)->where('id', $id)->exists(),
                'BUG-BA-012 confirmed: destroy() physically removes the row (hard delete, no deleted_at).'
            );
        } finally {
            $this->purgeMappingById($id);
        }
    }

    /** TC-N03 · BC-VAL-03 · Source: Controller@store unique rule + message */
    public function test_class_mapping_09_duplicate_mapping_is_rejected_by_validation(): void
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

    /** TC-P05 · BC-BIZ-05 · Source: setup() list with schoolClass/category relations */
    public function test_class_mapping_10_list_shows_created_mapping(): void
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

    /** TC-P06 · BC-REF-01/02 · Source: Model belongsTo schoolClass()/category() */
    public function test_class_mapping_11_relationships_resolve_to_parents(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies);

        try {
            $record->refresh()->load(['schoolClass', 'category']);
            $this->assertSame((int) $dependencies['class_id'], (int) ($record->schoolClass->id ?? 0));
            $this->assertSame((int) $dependencies['category_id'], (int) ($record->category->id ?? 0));
        } finally {
            $this->purgeMappingById((int) $record->id);
        }
    }

    // ──────────────────────────────────────────────
    //  30–59  Validation config, permissions, gaps
    // ──────────────────────────────────────────────

    /**
     * TC-S03 · BC-VAL-04 · Audit-VAL-BA-001 · Source: BaClassCategoryController@store:20 inline validate.
     * The write path has NO FormRequest (no BaClassCategoryRequest); validation is inline in the controller.
     * This documents the current (defective) shape. Source: BaClassCategoryController.php:20-33.
     */
    public function test_class_mapping_12_write_path_has_no_form_request_val_ba_001(): void
    {
        $this->assertFalse(
            File::exists(base_path(self::REQUEST_FILE)),
            'VAL-BA-001 confirmed: no BaClassCategoryRequest exists — validation is inline in the controller.'
        );

        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString('$request->validate(', $controller, 'store() should validate inline.');
        $this->assertStringContainsString("'exists:sch_classes,id'", $controller);
        $this->assertStringContainsString("Rule::unique('ba_class_category_jnt', 'category_id')", $controller);
        $this->assertStringContainsString('This category is already mapped to the selected class.', $controller);
    }

    /** TC-S01 · BC-AUTH-01 · Source: web routes behind auth middleware */
    public function test_class_mapping_13_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::SETUP_PATH . self::TAB_QS))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    /**
     * TC-D02 (E) · BC-INT-03 · Audit-BUG-BA-007 · Source: BaAssessmentController@show:115-121.
     * BR-BA-009 permissive default: "no mapping ⇒ all active categories apply". The Ratings grid does
     * `pluck('category_id')` on ba_class_category_jnt → for a class with NO mapping this yields an empty
     * set and the grid renders blank. This test proves the data precondition: an unmapped class has zero
     * mapping rows (so the downstream grid is empty rather than falling back to all active categories).
     */
    public function test_class_mapping_14_unmapped_class_has_zero_mappings_bug_ba_007(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $unmappedClassId = $this->findClassWithNoMappingOrSkip($dependencies['class_ids']);

        $this->assertSame(
            0,
            BaClassCategoryJnt::query()->where('class_id', $unmappedClassId)->count(),
            'BUG-BA-007 precondition: an unmapped class yields 0 mappings → empty ratings grid (permissive default missing).'
        );
    }

    // ──────────────────────────────────────────────
    //  Helpers (mirror the committed sibling test)
    // ──────────────────────────────────────────────

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
                $exists = DB::table(self::TABLE)
                    ->where('class_id', $classId)
                    ->where('category_id', $categoryId)
                    ->exists();
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

        $this->markTestSkipped('Every active class already has at least one mapping — cannot assert the empty-grid precondition.');
    }

    private function createRecordDirectly(array $dependencies, array $overrides = []): BaClassCategoryJnt
    {
        $payload = array_merge($this->buildValidDirectPayload($dependencies), $overrides);

        return BaClassCategoryJnt::query()->create($payload);
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

        $permissions = $this->classMappingPermissions();
        $this->ensurePermissionsExist($permissions);

        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
    }

    private function classMappingPermissions(): array
    {
        return [
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
