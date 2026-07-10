<?php

/**
 * BehaviouralAssessment › RatingScale — V1 (foundation) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/RatingScale/RatingScaleCrudTest.php
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; tables live in database/migrations/tenant/).
 * TABLES  : ba_rating_scales (+ child ba_rating_levels)  — NOTE the DDL doc uses the stale prefix
 *           "bha_"; the LIVE migrations/models/tables are "ba_" (audit DOC-BA-001). Artifact FILE
 *           names follow the DDL/inventory prefix "bha_"; every schema assertion targets the real
 *           "ba_" tables. Do not "fix" this to bha_ in code — it would break against the real DB.
 *
 * All routes/selectors/permissions/flash strings verified against:
 *   Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php
 *   Modules/BehaviouralAssessment/app/Http/Requests/BaRatingScaleRequest.php
 *   Modules/BehaviouralAssessment/app/Models/{BaRatingScale,BaRatingLevel}.php
 *   Modules/BehaviouralAssessment/routes/web.php
 *   Modules/BehaviouralAssessment/resources/views/rating-scale/{create,edit,show,trash}.blade.php
 *   Modules/BehaviouralAssessment/resources/views/pages/partials/masters/_rating-scales.blade.php
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
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

class bha_RatingScaleV1_TestCas extends DuskTestCase
{
    private const INDEX_PATH        = '/behavioural-assessment/masters';
    private const LISTING_PATH      = '/behavioural-assessment/rating-scales';
    private const CREATE_PATH       = '/behavioural-assessment/rating-scales/create';
    private const SHOW_BASE_PATH    = '/behavioural-assessment/rating-scales';
    private const TRASH_PATH        = '/behavioural-assessment/rating-scales/trash';
    private const SCALES_TABLE      = 'ba_rating_scales';
    private const LEVELS_TABLE      = 'ba_rating_levels';
    private const MIGRATION_SCALES  = 'database/migrations/tenant/2026_06_16_130616_create_ba_rating_scales_table.php';
    private const MIGRATION_LEVELS  = 'database/migrations/tenant/2026_06_16_130622_create_ba_rating_levels_table.php';
    private const CONTROLLER_FILE   = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php';
    private const REQUEST_FILE      = 'Modules/BehaviouralAssessment/app/Http/Requests/BaRatingScaleRequest.php';

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

    /** TC-P01 · BC-DB-01/02 · Source: DDL-ba_rating_scales */
    public function test_rating_scale_01_schema_model_and_softdelete_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::SCALES_TABLE), 'Table ba_rating_scales does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::SCALES_TABLE, [
                'id', 'code', 'name', 'description', 'grade_type',
                'min_rating', 'max_rating', 'is_default', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing from ba_rating_scales.'
        );

        $migrationPath = base_path(self::MIGRATION_SCALES);
        $this->assertTrue(File::exists($migrationPath), 'Migration not found: ' . self::MIGRATION_SCALES);
        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('ba_rating_scales'", $migration);
        $this->assertStringContainsString("\$table->string('code', 30)", $migration);
        $this->assertStringContainsString("\$table->decimal('min_rating', 3, 1)", $migration);
        $this->assertStringContainsString("\$table->decimal('max_rating', 3, 1)", $migration);
        $this->assertStringContainsString("\$table->softDeletes()", $migration);

        $this->assertTrue(File::exists(base_path(self::CONTROLLER_FILE)), 'Controller file missing.');

        $model = new BaRatingScale();
        $this->assertSame('ba_rating_scales', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaRatingScale::class));

        $fillable = $model->getFillable();
        foreach (['name', 'code', 'description', 'grade_type', 'min_rating', 'max_rating', 'is_default', 'is_active'] as $col) {
            $this->assertContains($col, $fillable, "ba_rating_scales fillable should include {$col}.");
        }

        $casts = $model->getCasts();
        $this->assertSame('decimal:1', $casts['min_rating'] ?? null);
        $this->assertSame('decimal:1', $casts['max_rating'] ?? null);
        $this->assertSame('boolean', $casts['is_default'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);

        $this->assertInstanceOf(HasMany::class, $model->levels());
        $this->assertInstanceOf(HasMany::class, $model->configs());
    }

    /** TC-P02 · BC-DB-03 · BC-REF-01 · Source: DDL-ba_rating_levels */
    public function test_rating_scale_02_levels_schema_unique_and_fk_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::LEVELS_TABLE), 'Table ba_rating_levels does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::LEVELS_TABLE, [
                'id', 'rating_scale_id', 'label', 'numeric_value',
                'description', 'sort_order', 'is_active',
                'created_by', 'updated_by', 'deleted_at',
            ]),
            'Expected columns are missing from ba_rating_levels.'
        );

        $migrationPath = base_path(self::MIGRATION_LEVELS);
        $this->assertTrue(File::exists($migrationPath), 'Migration not found: ' . self::MIGRATION_LEVELS);
        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('ba_rating_levels'", $migration);
        $this->assertStringContainsString("constrained('ba_rating_scales')->cascadeOnDelete()", $migration);
        $this->assertStringContainsString("uq_ba_level", $migration);

        $model = new BaRatingLevel();
        $this->assertSame('ba_rating_levels', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaRatingLevel::class));
        $this->assertInstanceOf(BelongsTo::class, $model->scale());
    }

    /** TC-N01 · BC-DB-04 · Source: DDL-ba_rating_scales NOT NULL */
    public function test_rating_scale_03_db_rejects_missing_required_fields(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();

        foreach (['code', 'name', 'grade_type', 'min_rating', 'max_rating'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P03 · BC-DB-05 · Source: DDL description nullable */
    public function test_rating_scale_04_nullable_description_accepts_null(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;

        try {
            $record = $this->createRecordDirectly($dependencies, ['description' => null]);
            $this->assertNotNull($record->id, 'Rating scale with null description did not save.');
            $this->assertNull($record->description);
        } finally {
            if ($record instanceof BaRatingScale) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ──────────────────────────────────────────────
    //  10–19  Core CRUD / business behaviour
    // ──────────────────────────────────────────────

    /** TC-P10 · BC-BIZ-01 · Source: Screen-WF-Create */
    public function test_rating_scale_10_create_page_loads_and_shows_sections(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);

            $browser->waitFor('input[name="code"]', 12)
                ->assertSee('Scale Identity')
                ->assertSee('Score Range & Settings')
                ->assertPresent('select[name="grade_type"]')
                ->assertSee('Save Rating Scale');
        });
    }

    /** TC-P11 · BC-BIZ-02 · Source: Controller@store flash "Rating scale created successfully." */
    public function test_rating_scale_11_create_submission_persists(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V1 Create ' . $this->generateUniqueSuffix();
        $code = 'SCL' . $this->generateUniqueSuffix();
        $saved = null;

        try {
            $this->browse(function (Browser $browser) use ($name, $code): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="code"]', $code)
                    ->type('input[name="name"]', $name)
                    ->select('grade_type', 'letter')
                    ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '1.0')
                    ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '5.0')
                    ->press('Save Rating Scale')
                    ->pause(2500);
            });

            $saved = BaRatingScale::query()->where('name', $name)->latest('id')->first();
            $this->assertNotNull($saved, 'Rating scale was not persisted.');
            $this->assertSame(strtoupper($code), (string) $saved->code, 'Code should be stored upper-cased.');
        } finally {
            if ($saved instanceof BaRatingScale) {
                $this->forceDeleteRecordByIdIfExists((int) $saved->id);
            }
        }
    }

    /** TC-P12 · BC-BIZ-03 · Source: show.blade "Configured Rating Levels" */
    public function test_rating_scale_12_show_page_displays_data(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Show ' . $this->generateUniqueSuffix(),
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);

                $browser->waitForText('Scale Identity', 12)
                    ->assertSee((string) $record->name)
                    ->assertSee((string) $record->code)
                    ->assertSee('Configured Rating Levels');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P13 · BC-BIZ-04 · Source: Controller@update flash "Rating scale updated successfully." */
    public function test_rating_scale_13_edit_update_persists_and_flashes(): void
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

                $browser->waitFor('input[name="name"]', 12)
                    ->clear('input[name="name"]')
                    ->type('input[name="name"]', $updatedName)
                    ->press('Update Rating Scale')
                    ->pause(2200)
                    ->assertSee('Rating scale updated successfully.');
            });

            $record->refresh();
            $this->assertSame($updatedName, (string) $record->name);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P14 · BC-SM-01 · Source: Controller@toggleStatus + status-switch component (.status-toggle) */
    public function test_rating_scale_14_toggle_status_flips_is_active(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Toggle ' . $this->generateUniqueSuffix(),
            'is_active' => true,
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=rating-scales', 900);

                $browser->waitFor('.status-toggle[data-id="' . $record->id . '"]', 12)
                    ->script('document.querySelector(\'.status-toggle[data-id="' . $record->id . '"]\').click();');
                $browser->pause(1800);
            });

            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'is_active should have toggled to false.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D01 (F) · BC-BIZ-05 · Source: Controller destroy/restore/forceDelete */
    public function test_rating_scale_15_soft_delete_restore_force_delete_lifecycle(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Lifecycle ' . $this->generateUniqueSuffix(),
        ]);
        $recordId = (int) $record->id;

        try {
            $record->delete();
            $this->assertNotNull(BaRatingScale::withTrashed()->find($recordId));
            $this->assertNull(BaRatingScale::find($recordId));

            $record->restore();
            $this->assertNotNull(BaRatingScale::find($recordId));

            $record->forceDelete();
            $this->assertNull(BaRatingScale::withTrashed()->find($recordId));
        } finally {
            $this->forceDeleteRecordByIdIfExists($recordId);
        }
    }

    /** TC-P16 · BC-BIZ-06 · Source: edit.blade "Add New Level" form + Controller@storeLevel */
    public function test_rating_scale_16_add_level_via_edit_page_persists(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Levels ' . $this->generateUniqueSuffix(),
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);

                $browser->waitFor('input[name="label"]', 12)
                    ->type('input[name="label"]', 'Excellent')
                    ->type('input[name="numeric_value"]', '5')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', '1')
                    ->press('Add')
                    ->pause(2000)
                    ->assertSee('Level added.');
            });

            $this->assertSame(
                1,
                BaRatingLevel::where('rating_scale_id', $record->id)->where('label', 'Excellent')->count(),
                'Level was not persisted.'
            );
        } finally {
            BaRatingLevel::where('rating_scale_id', $record->id)->forceDelete();
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ──────────────────────────────────────────────
    //  30–39  Validation (negative)
    // ──────────────────────────────────────────────

    /** TC-N10 · BC-VAL-01 · Source: BaRatingScaleRequest unique(code)->whereNull(deleted_at) */
    public function test_rating_scale_17_duplicate_active_code_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $existing = $this->createRecordDirectly($dependencies, [
            'code' => 'DUP' . $this->generateUniqueSuffix(),
            'name' => 'V1 Dup Existing ' . $this->generateUniqueSuffix(),
        ]);
        $before = BaRatingScale::query()->count();

        try {
            $this->browse(function (Browser $browser) use ($existing): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="code"]', 12)
                    ->type('input[name="code"]', (string) $existing->code)
                    ->type('input[name="name"]', 'V1 Dup Attempt ' . $this->generateUniqueSuffix())
                    ->select('grade_type', 'letter')
                    ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '1')
                    ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '5')
                    ->press('Save Rating Scale')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertSame($before, BaRatingScale::query()->count(), 'Duplicate code should not have created a row.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $existing->id);
        }
    }

    /** TC-N11 · BC-VAL-02 · Source: BaRatingScaleRequest grade_type Rule::in(...) */
    public function test_rating_scale_18_invalid_grade_type_is_rejected(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V1 BadGrade ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($name): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                // Inject an out-of-enum option so we can post an illegal value past the <select>.
                $browser->waitFor('select[name="grade_type"]', 12)
                    ->script("(function(){var s=document.querySelector('select[name=\"grade_type\"]');var o=document.createElement('option');o.value='pictorial';o.text='pictorial';s.appendChild(o);s.value='pictorial';})();");
                $browser->type('input[name="code"]', 'GT' . $this->generateUniqueSuffix())
                    ->type('input[name="name"]', $name)
                    ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '1')
                    ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '5')
                    ->press('Save Rating Scale')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertNull(
                BaRatingScale::query()->where('name', $name)->first(),
                'Invalid grade_type should not create a row.'
            );
        } finally {
            BaRatingScale::query()->where('name', $name)->forceDelete();
        }
    }

    /** TC-N12 · BC-VAL-03 · Source: BaRatingScaleRequest max_rating gt:min_rating */
    public function test_rating_scale_19_max_rating_must_exceed_min_rating(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V1 Range ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($name): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="code"]', 12)
                    ->type('input[name="code"]', 'RNG' . $this->generateUniqueSuffix())
                    ->type('input[name="name"]', $name)
                    ->select('grade_type', 'numeric')
                    ->clear('input[name="min_rating"]')->type('input[name="min_rating"]', '5')
                    ->clear('input[name="max_rating"]')->type('input[name="max_rating"]', '5')
                    ->press('Save Rating Scale')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertNull(
                BaRatingScale::query()->where('name', $name)->first(),
                'max_rating == min_rating should be rejected (gt rule).'
            );
        } finally {
            BaRatingScale::query()->where('name', $name)->forceDelete();
        }
    }

    // ──────────────────────────────────────────────
    //  50–59 / 60–69  Auth + UI
    // ──────────────────────────────────────────────

    /** TC-S01 · BC-AUTH-01 · Source: web routes behind auth middleware */
    public function test_rating_scale_20_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    /** TC-P21 · BC-BIZ-07 · Source: Controller@trashed + trash.blade */
    public function test_rating_scale_21_trash_page_lists_soft_deleted_scale(): void
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
                $browser->waitForText('Code', 12)->assertSee((string) $record->code);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ──────────────────────────────────────────────
    //  Helpers (mirror the committed sibling test)
    // ──────────────────────────────────────────────

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
        $payload = array_merge($this->buildValidDirectPayload($dependencies), $overrides);

        return BaRatingScale::query()->create($payload);
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'code'        => 'SCL' . $this->generateUniqueSuffix(),
            'name'        => 'Rating Scale ' . $this->generateUniqueSuffix(),
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

    private function forceDeleteRecordByIdIfExists(int $recordId): void
    {
        BaRatingScale::withTrashed()->where('id', $recordId)->get()
            ->each(function (BaRatingScale $record): void {
                try {
                    $record->levels()->forceDelete();
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

        $permissions = $this->ratingScalePermissions();
        $this->ensurePermissionsExist($permissions);

        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
    }

    private function ratingScalePermissions(): array
    {
        return [
            'tenant.behavioural-assessment.rating-scales.viewAny',
            'tenant.behavioural-assessment.rating-scales.view',
            'tenant.behavioural-assessment.rating-scales.create',
            'tenant.behavioural-assessment.rating-scales.update',
            'tenant.behavioural-assessment.rating-scales.delete',
            'tenant.behavioural-assessment.rating-scales.status',
            'tenant.behavioural-assessment.rating-scales.restore',
            'tenant.behavioural-assessment.rating-scales.forceDelete',
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

    /** Reference to BaRatingScaleRequest to keep the FormRequest import meaningful for static tools. */
    private function requestClassName(): string
    {
        return BaRatingScaleRequest::class;
    }

    /** Reference to DB facade for parity with the sibling helper surface. */
    private function scalesTableName(): string
    {
        return DB::getTablePrefix() . self::SCALES_TABLE;
    }
}
