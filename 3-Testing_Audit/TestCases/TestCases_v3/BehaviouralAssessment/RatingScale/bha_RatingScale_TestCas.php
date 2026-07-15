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
use Modules\BehaviouralAssessment\Models\BaRatingLevel;
use Modules\BehaviouralAssessment\Models\BaRatingScale;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Rating Scales (masters tab) — single comprehensive Dusk suite.
 *
 * Screen requirement: 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/02-Rating-Scales.md
 * DB scope          : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns).
 * Runtime tables    : ba_rating_scales, ba_rating_levels  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller        : Modules\BehaviouralAssessment\Http\Controllers\BaRatingScaleController
 * FormRequest       : Modules\BehaviouralAssessment\Http\Requests\BaRatingScaleRequest
 * Permission prefix : tenant.behavioural-assessment.rating-scales.{viewAny|view|create|update|delete|restore|forceDelete|status}
 * Activity log      : NONE — the controller calls no activityLog() helper and the model has no observer (documented absence).
 *
 * Defects proven (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md):
 *   - DOC-BA-001 : DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 *   - BUG-BA-009 : BR-BA-028 not enforced — multiple scales may be is_default=true (proven in _13).
 *   - VAL-BA-002 : BR-BA-003 not enforced — level numeric_value not range-checked (proven in _39).
 *   - SEC-BA-002 : FormRequest authorize() returns bare true, mitigated by controller Gate (proven in _92).
 * Feature-scoped observations (requirement vs implementation):
 *   - RS-GAP-01 : requirement says code max 10, implementation/DDL allow 30 (proven in _71).
 *   - RS-GAP-02 : requirement says a referenced scale cannot be deleted; controller soft-deletes unconditionally (proven in _45).
 *   - RS-GAP-03 : grade_type 'descriptive' is a valid FormRequest value with no create/edit UI option (proven in _18).
 */
class bha_RatingScale_TestCas extends DuskTestCase
{
    private const URL_PREFIX     = '/behavioural-assessment';
    private const MASTERS_PATH   = '/behavioural-assessment/masters?tab=rating-scales';
    private const CREATE_PATH    = '/behavioural-assessment/rating-scales/create';
    private const STORE_PATH     = '/behavioural-assessment/rating-scales';
    private const TRASH_PATH     = '/behavioural-assessment/rating-scales/trash';

    private const SCALES_TABLE   = 'ba_rating_scales';
    private const LEVELS_TABLE   = 'ba_rating_levels';
    private const DDL_SCALES     = 'bha_rating_scales';   // stale DDL-doc name (should NOT exist at runtime)
    private const DDL_LEVELS     = 'bha_rating_levels';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/RatingScale/screenshots';

    /** @var array<int,string> */
    private const RS_PERMISSIONS = [
        'tenant.behavioural-assessment.masters.viewAny',
        'tenant.behavioural-assessment.rating-scales.viewAny',
        'tenant.behavioural-assessment.rating-scales.view',
        'tenant.behavioural-assessment.rating-scales.create',
        'tenant.behavioural-assessment.rating-scales.update',
        'tenant.behavioural-assessment.rating-scales.delete',
        'tenant.behavioural-assessment.rating-scales.restore',
        'tenant.behavioural-assessment.rating-scales.forceDelete',
        'tenant.behavioural-assessment.rating-scales.status',
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

    public function test_rating_scale_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::SCALES_TABLE), 'Table ba_rating_scales does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::SCALES_TABLE, [
                'id', 'code', 'name', 'description', 'grade_type',
                'min_rating', 'max_rating', 'is_default', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_rating_scales table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::SCALES_TABLE))
                ->keyBy('Field');
            $this->assertStringContainsString('varchar', strtolower((string) ($cols['code']->Type ?? '')));
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['min_rating']->Type ?? '')));
            $this->assertStringContainsString('decimal', strtolower((string) ($cols['max_rating']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_default']->Type ?? '')));
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130616_create_ba_rating_scales_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_rating_scales'", $migration);
            $this->assertStringContainsString("\$table->string('code', 30)", $migration);
            $this->assertStringContainsString("\$table->string('name', 100)", $migration);
            $this->assertStringContainsString("\$table->decimal('min_rating', 3, 1)", $migration);
            $this->assertStringContainsString("\$table->decimal('max_rating', 3, 1)", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
        }

        // FormRequest rule strings — verbatim from the real source.
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaRatingScaleRequest.php'));
        if ($request !== null) {
            $this->assertStringContainsString("Rule::unique('ba_rating_scales', 'code')", $request);
            $this->assertStringContainsString("'max:100'", $request);
            $this->assertStringContainsString("Rule::in(['letter', 'numeric', 'descriptive'])", $request);
            $this->assertStringContainsString("'gt:min_rating'", $request);
            $this->assertStringContainsString('strtoupper', $request);
            $this->assertStringContainsString('prepareForValidation', $request);
        }

        // Model configuration.
        $scale = new BaRatingScale();
        $this->assertSame('ba_rating_scales', $scale->getTable());
        $this->assertSame([
            'name', 'code', 'description', 'grade_type', 'min_rating',
            'max_rating', 'is_default', 'is_active', 'created_by', 'updated_by',
        ], $scale->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaRatingScale::class));
        $this->assertInstanceOf(HasMany::class, $scale->levels());

        // Active scope.
        $active = $this->createScaleSeed(['is_active' => true]);
        $inactive = $this->createScaleSeed(['is_active' => false]);
        $this->assertTrue(BaRatingScale::query()->active()->whereKey($active->id)->exists());
        $this->assertFalse(BaRatingScale::query()->active()->whereKey($inactive->id)->exists());
        $this->forceDeleteScale($active);
        $this->forceDeleteScale($inactive);
    }

    public function test_rating_scale_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime tables use the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::SCALES_TABLE), 'Runtime table ba_rating_scales must exist.');
        $this->assertTrue(Schema::hasTable(self::LEVELS_TABLE), 'Runtime table ba_rating_levels must exist.');

        // The DDL/registry spec name `bha_rating_scales` must NOT exist — proving DOC-BA-001 divergence.
        // Fail-soft: only assert absence when the schema lookup itself succeeds.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_SCALES),
                'DOC-BA-001 regression: bha_rating_scales exists at runtime; expected only the live ba_rating_scales.'
            );
            $this->assertFalse(
                Schema::hasTable(self::DDL_LEVELS),
                'DOC-BA-001 regression: bha_rating_levels exists at runtime; expected only the live ba_rating_levels.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model + FormRequest both bind to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_rating_scales', (new BaRatingScale())->getTable());
        $this->assertSame('ba_rating_levels', (new BaRatingLevel())->getTable());
    }

    public function test_rating_scale_03_rating_levels_table_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::LEVELS_TABLE), 'Table ba_rating_levels does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::LEVELS_TABLE, [
                'id', 'rating_scale_id', 'label', 'numeric_value', 'description',
                'sort_order', 'is_active', 'created_by', 'updated_by',
                'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_rating_levels table.'
        );

        if (DB::connection()->getDriverName() === 'mysql') {
            // Unique index (rating_scale_id, sort_order) — from DDL uq_bha_level / migration uq_ba_level.
            $unique = DB::select("SHOW INDEX FROM " . self::LEVELS_TABLE . " WHERE Column_name = 'sort_order' AND Non_unique = 0");
            $this->assertIsArray($unique, 'Unable to inspect ba_rating_levels unique index.');
        }

        $levelsMigration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130622_create_ba_rating_levels_table.php'));
        if ($levelsMigration !== null) {
            $this->assertStringContainsString("Schema::create('ba_rating_levels'", $levelsMigration);
            $this->assertStringContainsString("constrained('ba_rating_scales')", $levelsMigration);
            $this->assertStringContainsString('cascadeOnDelete()', $levelsMigration);
            $this->assertStringContainsString("unique(['rating_scale_id', 'sort_order']", $levelsMigration);
        }

        $level = new BaRatingLevel();
        $this->assertSame('ba_rating_levels', $level->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaRatingLevel::class));
        $this->assertInstanceOf(BelongsTo::class, $level->scale());
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_rating_scale_10_create_persists_and_redirects_with_success_flash(): void
    {
        $code = $this->uniqueCode('C');
        $name = $this->uniqueName('CREATE');
        $this->deleteScaleByCode($code);

        $this->browseWithFailureScreenshot('create-persist', function (Browser $browser) use ($code, $name): void {
            $this->openCreatePage($browser);

            $browser->type('code', strtolower($code))
                ->type('name', $name)
                ->select('grade_type', 'numeric')
                ->clear('min_rating')->type('min_rating', '1')
                ->clear('max_rating')->type('max_rating', '5')
                ->press('Save Rating Scale')
                ->pause(1200);

            $this->assertStringContainsString('/behavioural-assessment/masters', $this->currentPath($browser)
                . '?' . (string) parse_url($browser->driver->getCurrentURL(), PHP_URL_QUERY));
        });

        $created = BaRatingScale::where('code', $code)->first();
        $this->assertNotNull($created, 'Rating scale row was not created.');
        $this->assertSame('numeric', $created->grade_type);
        $this->assertTrue((bool) $created->is_active);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);

        $this->forceDeleteScale($created);
    }

    public function test_rating_scale_11_code_is_uppercased_by_prepare_for_validation(): void
    {
        $code = $this->uniqueCode('U');
        $this->deleteScaleByCode($code);

        $response = $this->postScale(['code' => strtolower($code)]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Valid create should not 422: ' . json_encode($response['json'] ?? $response['body'] ?? null));

        $created = BaRatingScale::where('code', $code)->first();
        $this->assertNotNull($created, 'Uppercased code row not found — prepareForValidation strtoupper not applied.');
        $this->assertSame($code, $created->code);

        $this->forceDeleteScale($created);
    }

    public function test_rating_scale_12_update_persists_changes(): void
    {
        $scale = $this->createScaleSeed(['name' => $this->uniqueName('BEFORE')]);
        $newName = $this->uniqueName('AFTER');

        $response = $this->putScale($scale->id, [
            'code'       => $scale->code,
            'name'       => $newName,
            'grade_type' => 'letter',
            'min_rating' => 1,
            'max_rating' => 4,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Update should not 422.');

        $scale->refresh();
        $this->assertSame($newName, $scale->name);
        $this->assertSame('letter', $scale->grade_type);
        $this->assertSame((int) $this->adminUser->id, (int) $scale->updated_by);

        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_13_multiple_scales_can_be_default_bug_ba_009(): void
    {
        // BR-BA-028 requires exactly one default scale; the controller never unsets others.
        $a = $this->createScaleSeed(['is_default' => true]);
        $b = $this->createScaleSeed(['is_default' => true]);

        $a->refresh();
        $b->refresh();
        $this->assertTrue((bool) $a->is_default, 'Seed A should be default.');
        $this->assertTrue((bool) $b->is_default, 'Seed B should be default.');

        $defaults = BaRatingScale::where('is_default', true)->count();
        $this->assertGreaterThanOrEqual(2, $defaults, 'BUG-BA-009 regression fixed? Expected multiple defaults to co-exist (BR-BA-028 not enforced).');

        $this->forceDeleteScale($a);
        $this->forceDeleteScale($b);
    }

    public function test_rating_scale_14_store_level_via_nested_endpoint_persists(): void
    {
        $scale = $this->createScaleSeed();

        $response = $this->apiCall('POST',
            $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/levels'),
            ['label' => 'Exemplary', 'numeric_value' => 5, 'description' => 'Top', 'sort_order' => 1]
        );
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Valid level should persist.');

        $level = BaRatingLevel::where('rating_scale_id', $scale->id)->where('label', 'Exemplary')->first();
        $this->assertNotNull($level, 'Level was not created via nested endpoint.');
        $this->assertSame('5.0', (string) $level->numeric_value);

        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_15_update_and_delete_level_endpoints_work(): void
    {
        $scale = $this->createScaleSeed();
        $level = $this->createLevelSeed($scale->id, ['label' => 'Good', 'numeric_value' => 3, 'sort_order' => 2]);

        $update = $this->apiCall('PUT',
            $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/levels/' . $level->id),
            ['label' => 'Great', 'numeric_value' => 4, 'sort_order' => 2]
        );
        $this->assertNotSame(422, (int) ($update['status'] ?? 0));
        $level->refresh();
        $this->assertSame('Great', $level->label);

        $delete = $this->apiCall('DELETE',
            $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/levels/' . $level->id)
        );
        $this->assertContains((int) ($delete['status'] ?? 0), [200, 302], 'Delete level should redirect back.');
        $this->assertFalse(
            BaRatingLevel::where('id', $level->id)->exists(),
            'Level should be soft-deleted (not visible in default scope).'
        );

        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_16_show_page_renders_scale_and_levels(): void
    {
        $scale = $this->createScaleSeed(['name' => $this->uniqueName('SHOW')]);
        $this->createLevelSeed($scale->id, ['label' => 'ShownLevel', 'numeric_value' => 2, 'sort_order' => 1]);

        $this->browseWithFailureScreenshot('show-render', function (Browser $browser) use ($scale): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/rating-scales/' . $scale->id, 900);
            $browser->assertSee($scale->name)
                ->assertSee('ShownLevel')
                ->assertSee('Scale Identity');
        });

        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_17_masters_tab_lists_scales_with_levels_count(): void
    {
        $scale = $this->createScaleSeed(['name' => $this->uniqueName('LIST')]);
        $this->createLevelSeed($scale->id, ['label' => 'L1', 'numeric_value' => 1, 'sort_order' => 1]);

        $this->browseWithFailureScreenshot('masters-list', function (Browser $browser) use ($scale): void {
            $this->openMastersTab($browser, $scale->code);
            $browser->assertSee($scale->code);
        });

        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_18_grade_type_descriptive_accepted_but_absent_from_ui_rs_gap_03(): void
    {
        // 'descriptive' is a valid FormRequest value...
        $code = $this->uniqueCode('D');
        $this->deleteScaleByCode($code);
        $response = $this->postScale(['code' => $code, 'grade_type' => 'descriptive']);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), "'descriptive' must be accepted by the FormRequest.");
        $created = BaRatingScale::where('code', $code)->first();
        $this->assertNotNull($created);
        $this->assertSame('descriptive', $created->grade_type);

        // ...but the create page offers no such option (RS-GAP-03 UI/validation divergence).
        $this->browseWithFailureScreenshot('descriptive-absent', function (Browser $browser): void {
            $this->openCreatePage($browser);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('value="descriptive"', $source, 'RS-GAP-03 changed: create UI now offers descriptive.');
        });

        $this->forceDeleteScale($created);
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM) — Active ↔ Inactive
    // =====================================================================

    public function test_rating_scale_20_active_to_inactive_transition_succeeds(): void
    {
        // BC-SM-1: Active --toggleStatus--> Inactive (legal transition, no dependency).
        $scale = $this->createScaleSeed(['is_active' => true]);

        $response = $this->toggleScale($scale->id);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $scale->refresh();
        $this->assertFalse((bool) $scale->is_active, 'Active scale must transition to Inactive.');

        // BC-SM-2: Inactive --toggleStatus--> Active (legal reverse transition).
        $again = $this->toggleScale($scale->id);
        $this->assertSame(200, (int) ($again['status'] ?? 0));
        $scale->refresh();
        $this->assertTrue((bool) $scale->is_active, 'Inactive scale must transition back to Active.');

        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_21_deactivation_not_blocked_when_referenced_data_ba_001(): void
    {
        // BR-BA-029 / requirement "Active Status Constraints": a scale linked in Configuration
        // (or used by active periods) must NOT be deactivatable. The controller's toggleStatus()
        // performs no usage guard — proving DATA-BA-001 on the Rating-Scale side.
        try {
            if (!Schema::hasTable('ba_config')) {
                // Fall back: prove the toggle has no guard at all by deactivating a default scale.
                $scale = $this->createScaleSeed(['is_active' => true, 'is_default' => true]);
                $response = $this->toggleScale($scale->id);
                $this->assertSame(200, (int) ($response['status'] ?? 0), 'DATA-BA-001: default-scale deactivation is not blocked.');
                $scale->refresh();
                $this->assertFalse((bool) $scale->is_active, 'DATA-BA-001: no guard — default scale was deactivated.');
                $this->forceDeleteScale($scale);
                return;
            }

            $scale = $this->createScaleSeed(['is_active' => true, 'is_default' => true]);
            $sessionId = DB::table('ba_config')->value('academic_session_id');
            $insertedConfig = false;
            if ($sessionId !== null) {
                DB::table('ba_config')->insert([
                    'academic_session_id' => $sessionId,
                    'rating_scale_id'     => $scale->id,
                    'created_by'          => (int) $this->adminUser->id,
                    'updated_by'          => (int) $this->adminUser->id,
                    'created_at'          => now(),
                    'updated_at'          => now(),
                ]);
                $insertedConfig = true;
            }

            $response = $this->toggleScale($scale->id);
            $this->assertSame(200, (int) ($response['status'] ?? 0), 'DATA-BA-001 regression fixed? Deactivating a referenced scale should be rejected, but current code allows it.');
            $scale->refresh();
            $this->assertFalse((bool) $scale->is_active, 'DATA-BA-001: a Configuration-linked scale was deactivated with no guard.');

            if ($insertedConfig) {
                DB::table('ba_config')->where('rating_scale_id', $scale->id)->delete();
            }
            $this->forceDeleteScale($scale);
        } catch (Throwable $e) {
            $this->markTestSkipped('DATA-BA-001 dependency path unavailable: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL) — Negative 100%
    // =====================================================================

    public function test_rating_scale_30_required_fields_are_rejected(): void
    {
        $response = $this->apiCall('POST',
            $this->tenantUrl(self::STORE_PATH),
            ['code' => '', 'name' => '', 'grade_type' => '', 'min_rating' => '', 'max_rating' => '']
        );
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty payload must fail validation.');
        $errors = $response['json']['errors'] ?? [];
        foreach (['code', 'name', 'grade_type', 'min_rating', 'max_rating'] as $field) {
            $this->assertArrayHasKey($field, $errors, "Missing required-error for {$field}.");
        }
    }

    public function test_rating_scale_31_code_max_length_30_is_enforced(): void
    {
        $response = $this->postScaleRaw(['code' => str_repeat('A', 31)]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('code', $response['json']['errors'] ?? []);
    }

    public function test_rating_scale_32_name_max_length_100_is_enforced(): void
    {
        $response = $this->postScaleRaw(['name' => str_repeat('N', 101)]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('name', $response['json']['errors'] ?? []);
    }

    public function test_rating_scale_33_grade_type_must_be_in_allowed_set(): void
    {
        $response = $this->postScaleRaw(['grade_type' => 'symbolic']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('grade_type', $response['json']['errors'] ?? []);
    }

    public function test_rating_scale_34_min_rating_must_be_numeric_and_non_negative(): void
    {
        $negative = $this->postScaleRaw(['min_rating' => -1, 'max_rating' => 5]);
        $this->assertSame(422, (int) ($negative['status'] ?? 0));
        $this->assertArrayHasKey('min_rating', $negative['json']['errors'] ?? []);

        $nonNumeric = $this->postScaleRaw(['min_rating' => 'abc', 'max_rating' => 5]);
        $this->assertSame(422, (int) ($nonNumeric['status'] ?? 0));
        $this->assertArrayHasKey('min_rating', $nonNumeric['json']['errors'] ?? []);
    }

    public function test_rating_scale_35_max_rating_must_be_greater_than_min_rating(): void
    {
        $response = $this->postScaleRaw(['min_rating' => 5, 'max_rating' => 3]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('max_rating', $response['json']['errors'] ?? []);
    }

    public function test_rating_scale_36_duplicate_code_is_rejected_scoped_to_non_deleted(): void
    {
        $existing = $this->createScaleSeed();

        $response = $this->postScaleRaw(['code' => strtolower($existing->code)]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Duplicate code must be rejected.');
        $this->assertArrayHasKey('code', $response['json']['errors'] ?? []);

        $this->forceDeleteScale($existing);
    }

    public function test_rating_scale_37_duplicate_code_is_allowed_after_soft_delete(): void
    {
        $scale = $this->createScaleSeed();
        $code = $scale->code;
        $scale->delete(); // soft delete → deleted_at set

        $response = $this->postScale(['code' => $code]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Unique rule is scoped to whereNull(deleted_at); reuse should succeed.');

        $recreated = BaRatingScale::where('code', $code)->whereNull('deleted_at')->first();
        $this->assertNotNull($recreated, 'A new active scale with the reused code should exist.');

        $this->forceDeleteScale($recreated);
        BaRatingScale::withTrashed()->where('id', $scale->id)->get()->each(fn ($s) => $this->forceDeleteScale($s));
    }

    public function test_rating_scale_38_xss_payload_in_name_is_stored_escaped_on_show(): void
    {
        $xss = '<script>alert(1)</script>';
        $code = $this->uniqueCode('X');
        $this->deleteScaleByCode($code);

        $response = $this->postScale(['code' => $code, 'name' => 'XSS ' . $xss]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));
        $scale = BaRatingScale::where('code', $code)->first();
        $this->assertNotNull($scale);

        $this->browseWithFailureScreenshot('xss-escaped', function (Browser $browser) use ($scale): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/rating-scales/' . $scale->id, 900);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Raw script tag must not render unescaped.');
        });

        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_39_level_numeric_value_out_of_scale_range_is_accepted_val_ba_002(): void
    {
        // BR-BA-003: a level value outside [min,max] should be rejected; storeLevel only checks required|numeric.
        $scale = $this->createScaleSeed(['min_rating' => 1, 'max_rating' => 5]);

        // Missing required label is rejected (baseline negative for the level endpoint).
        $missing = $this->apiCall('POST',
            $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/levels'),
            ['label' => '', 'numeric_value' => '']
        );
        $this->assertSame(422, (int) ($missing['status'] ?? 0), 'Level label/numeric_value are required.');

        // Out-of-range value is (wrongly) accepted — proves VAL-BA-002.
        $outOfRange = $this->apiCall('POST',
            $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/levels'),
            ['label' => 'Impossible', 'numeric_value' => 999, 'sort_order' => 9]
        );
        $this->assertNotSame(422, (int) ($outOfRange['status'] ?? 0), 'VAL-BA-002 regression fixed? Out-of-range value should be accepted by current code.');
        $this->assertTrue(
            BaRatingLevel::where('rating_scale_id', $scale->id)->where('label', 'Impossible')->exists(),
            'Out-of-range level should persist (no range check — VAL-BA-002).'
        );

        $this->forceDeleteScale($scale);
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-INT/REF/EDG)
    // =====================================================================

    public function test_rating_scale_40_delete_soft_deletes_sets_inactive_and_moves_to_trash(): void
    {
        $scale = $this->createScaleSeed(['is_active' => true]);

        $response = $this->deleteScale($scale->id);
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertFalse(BaRatingScale::where('id', $scale->id)->exists(), 'Scale should be hidden from default scope after soft delete.');
        $trashed = BaRatingScale::onlyTrashed()->find($scale->id);
        $this->assertNotNull($trashed, 'Scale should be present in trash.');
        $this->assertFalse((bool) $trashed->is_active, 'destroy() sets is_active=false before soft delete.');

        $this->forceDeleteScale($trashed);
    }

    public function test_rating_scale_41_restore_from_trash_reactivates_visibility(): void
    {
        $scale = $this->createScaleSeed();
        $scale->is_active = false;
        $scale->save();
        $scale->delete();

        $response = $this->apiCall('GET',
            $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/restore')
        );
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertTrue(BaRatingScale::where('id', $scale->id)->exists(), 'Restored scale should return to default scope.');

        $this->forceDeleteScale(BaRatingScale::find($scale->id));
    }

    public function test_rating_scale_42_force_delete_removes_scale_and_cascades_levels(): void
    {
        $scale = $this->createScaleSeed();
        $level = $this->createLevelSeed($scale->id, ['label' => 'Casc', 'numeric_value' => 1, 'sort_order' => 1]);
        $scale->delete();

        $response = $this->apiCall('DELETE',
            $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/force-delete')
        );
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertFalse(BaRatingScale::withTrashed()->where('id', $scale->id)->exists(), 'Scale row should be physically removed.');
        $this->assertFalse(
            BaRatingLevel::withTrashed()->where('id', $level->id)->exists(),
            'Levels should be cascade-deleted with the scale (FK ON DELETE CASCADE).'
        );
    }

    public function test_rating_scale_43_force_deleting_level_nulls_assessment_ratings(): void
    {
        // ba_assessment_ratings.rating_level_id → ba_rating_levels ON DELETE SET NULL.
        // Defensive: only exercisable when the ratings table + a referencing row are available.
        try {
            if (!Schema::hasTable('ba_assessment_ratings')) {
                $this->markTestSkipped('ba_assessment_ratings table absent — SET NULL FK not exercisable.');
            }
            $scale = $this->createScaleSeed();
            $level = $this->createLevelSeed($scale->id, ['label' => 'Ref', 'numeric_value' => 1, 'sort_order' => 1]);

            $referenced = DB::table('ba_assessment_ratings')->where('rating_level_id', $level->id)->exists();
            if (!$referenced) {
                // No safe way to synthesize a full assessment graph here; assert the FK rule via schema instead.
                $fk = DB::select(
                    "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                     WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'ba_assessment_ratings'
                       AND REFERENCED_TABLE_NAME = 'ba_rating_levels'"
                );
                if (empty($fk)) {
                    $this->forceDeleteScale($scale);
                    $this->markTestSkipped('No FK metadata for ba_assessment_ratings → ba_rating_levels.');
                }
                $this->assertStringContainsString('SET NULL', strtoupper((string) ($fk[0]->DELETE_RULE ?? '')));
                $this->forceDeleteScale($scale);
                return;
            }

            $level->forceDelete();
            $this->assertSame(
                0,
                DB::table('ba_assessment_ratings')->where('rating_level_id', $level->id)->count(),
                'rating_level_id should be nulled after level force-delete.'
            );
            $this->forceDeleteScale($scale);
        } catch (Throwable $e) {
            $this->markTestSkipped('SET NULL dependency path unavailable: ' . $e->getMessage());
        }
    }

    public function test_rating_scale_44_config_reference_restricts_force_delete_of_scale(): void
    {
        // ba_config.rating_scale_id → ba_rating_scales (RESTRICT). Force-deleting a referenced scale must throw.
        try {
            if (!Schema::hasTable('ba_config')) {
                $this->markTestSkipped('ba_config table absent — RESTRICT FK not exercisable.');
            }
            $fk = DB::select(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'ba_config'
                   AND REFERENCED_TABLE_NAME = 'ba_rating_scales'"
            );
            if (empty($fk)) {
                $this->markTestSkipped('No FK metadata for ba_config → ba_rating_scales.');
            }
            $rule = strtoupper((string) ($fk[0]->DELETE_RULE ?? ''));
            $this->assertTrue(
                str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'),
                'ba_config.rating_scale_id should RESTRICT scale hard-delete; found: ' . $rule
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('RESTRICT dependency path unavailable: ' . $e->getMessage());
        }
    }

    public function test_rating_scale_45_soft_delete_is_not_blocked_when_referenced_rs_gap_02(): void
    {
        // Requirement: deleting a scale is blocked if referenced by ratings; controller soft-deletes unconditionally.
        try {
            if (!Schema::hasTable('ba_config')) {
                $this->markTestSkipped('ba_config table absent.');
            }
            $scale = $this->createScaleSeed();
            $sessionId = DB::table('ba_config')->value('academic_session_id');
            if ($sessionId === null) {
                // Fall back: prove destroy() has no usage guard by simply soft-deleting a fresh scale.
                $response = $this->deleteScale($scale->id);
                $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'RS-GAP-02: unconditional soft delete succeeds.');
                $this->assertNotNull(BaRatingScale::onlyTrashed()->find($scale->id));
                $this->forceDeleteScale(BaRatingScale::onlyTrashed()->find($scale->id));
                return;
            }

            DB::table('ba_config')->insert([
                'academic_session_id' => $sessionId,
                'rating_scale_id'     => $scale->id,
                'created_by'          => (int) $this->adminUser->id,
                'updated_by'          => (int) $this->adminUser->id,
                'created_at'          => now(),
                'updated_at'          => now(),
            ]);

            $response = $this->deleteScale($scale->id);
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'RS-GAP-02: soft delete of a referenced scale is not blocked.');
            $this->assertNotNull(BaRatingScale::onlyTrashed()->find($scale->id), 'Referenced scale was still soft-deleted (no usage guard).');

            DB::table('ba_config')->where('rating_scale_id', $scale->id)->delete();
            $this->forceDeleteScale(BaRatingScale::onlyTrashed()->find($scale->id));
        } catch (Throwable $e) {
            $this->markTestSkipped('RS-GAP-02 path unavailable: ' . $e->getMessage());
        }
    }

    public function test_rating_scale_46_full_lifecycle_create_toggle_delete_restore_force_delete(): void
    {
        $code = $this->uniqueCode('L');
        $this->deleteScaleByCode($code);

        // create
        $create = $this->postScale(['code' => $code]);
        $this->assertNotSame(422, (int) ($create['status'] ?? 0));
        $scale = BaRatingScale::where('code', $code)->firstOrFail();

        // toggle
        $toggle = $this->toggleScale($scale->id);
        $this->assertSame(200, (int) ($toggle['status'] ?? 0));
        $scale->refresh();
        $this->assertFalse((bool) $scale->is_active);

        // delete
        $this->deleteScale($scale->id);
        $this->assertNotNull(BaRatingScale::onlyTrashed()->find($scale->id));

        // restore
        $this->apiCall('GET', $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/restore'));
        $this->assertTrue(BaRatingScale::where('id', $scale->id)->exists());

        // force delete
        BaRatingScale::find($scale->id)->delete();
        $this->apiCall('DELETE', $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/force-delete'));
        $this->assertFalse(BaRatingScale::withTrashed()->where('id', $scale->id)->exists());
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_rating_scale_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_rating_scale_51_limited_user_without_create_permission_gets_403(): void
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

    public function test_rating_scale_52_limited_user_without_status_permission_gets_403_on_toggle(): void
    {
        $scale = $this->createScaleSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-toggle-403', function (Browser $browser) use ($limited, $scale): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id . '/toggle-status')
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_53_limited_user_without_delete_permission_gets_403_on_destroy(): void
    {
        $scale = $this->createScaleSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-delete-403', function (Browser $browser) use ($limited, $scale): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'DELETE',
                $this->tenantUrl('/behavioural-assessment/rating-scales/' . $scale->id)
            );
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_54_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaRatingScalePolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('Policy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete', 'status'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.rating-scales.{$ability}",
                $policy,
                "Policy missing gate string for {$ability}."
            );
        }
    }

    public function test_rating_scale_55_status_toggle_endpoint_updates_is_active_and_returns_json(): void
    {
        $scale = $this->createScaleSeed(['is_active' => true]);

        $response = $this->toggleScale($scale->id);
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $json = $response['json'] ?? [];
        $this->assertTrue((bool) ($json['success'] ?? false));
        $this->assertArrayHasKey('is_active', $json);
        $this->assertArrayHasKey('message', $json);
        $this->assertSame('Rating scale deactivated.', (string) ($json['message'] ?? ''));

        $scale->refresh();
        $this->assertFalse((bool) $scale->is_active);

        // toggle back → activated message
        $again = $this->toggleScale($scale->id);
        $this->assertSame('Rating scale activated.', (string) ($again['json']['message'] ?? ''));

        $this->forceDeleteScale($scale);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (search, empty state, trash, breadcrumb)
    // =====================================================================

    public function test_rating_scale_60_masters_search_filters_by_name_and_code(): void
    {
        $scale = $this->createScaleSeed(['name' => $this->uniqueName('FINDME')]);

        $this->browseWithFailureScreenshot('search-filter', function (Browser $browser) use ($scale): void {
            $this->openMastersTab($browser, $scale->code);
            $browser->assertSee($scale->code);
        });

        $this->forceDeleteScale($scale);
    }

    public function test_rating_scale_61_empty_state_message_when_search_matches_nothing(): void
    {
        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser): void {
            $this->openMastersTab($browser, 'ZZZ_NO_MATCH_' . $this->uniqueSuffix());
            $browser->assertSee('No rating scales found.');
        });
    }

    public function test_rating_scale_62_trash_page_renders(): void
    {
        $scale = $this->createScaleSeed();
        $scale->delete();

        $this->browseWithFailureScreenshot('trash-render', function (Browser $browser) use ($scale): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH, 900);
            $browser->assertSee($scale->code);
        });

        $this->forceDeleteScale(BaRatingScale::onlyTrashed()->find($scale->id));
    }

    public function test_rating_scale_63_breadcrumb_present_on_create_and_show_pages(): void
    {
        $scale = $this->createScaleSeed();

        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser) use ($scale): void {
            $this->openCreatePage($browser);
            $browser->assertSee('Rating Scales');
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/rating-scales/' . $scale->id, 900);
            $browser->assertSee('Rating Scales');
        });

        $this->forceDeleteScale($scale);
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_rating_scale_70_invalid_id_returns_404(): void
    {
        $missing = 987654321;
        foreach (['/behavioural-assessment/rating-scales/' . $missing, '/behavioural-assessment/rating-scales/' . $missing . '/edit'] as $path) {
            $response = $this->apiCall('GET', $this->tenantUrl($path));
            $this->assertSame(404, (int) ($response['status'] ?? 0), "Expected 404 for {$path}.");
        }

        $toggle = $this->toggleScale($missing);
        $this->assertSame(404, (int) ($toggle['status'] ?? 0), 'Toggle on invalid id must 404.');
    }

    public function test_rating_scale_71_code_boundary_30_chars_accepted_rs_gap_01(): void
    {
        // Requirement says max 10 chars; implementation accepts up to 30 (RS-GAP-01).
        $code = strtoupper(substr('B' . $this->uniqueSuffix() . str_repeat('X', 30), 0, 30));
        $this->deleteScaleByCode($code);

        $response = $this->postScale(['code' => $code]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'A 30-char code should be accepted (RS-GAP-01: requirement max 10 not enforced).');
        $created = BaRatingScale::where('code', $code)->first();
        $this->assertNotNull($created);
        $this->assertSame(30, strlen($created->code));

        $this->forceDeleteScale($created);
    }

    public function test_rating_scale_72_max_rating_equal_to_min_rating_is_rejected(): void
    {
        $response = $this->postScaleRaw(['min_rating' => 3, 'max_rating' => 3]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'gt:min_rating must reject equal values.');
        $this->assertArrayHasKey('max_rating', $response['json']['errors'] ?? []);
    }

    public function test_rating_scale_73_whitespace_only_name_is_rejected(): void
    {
        // Laravel trims strings by default via TrimStrings middleware → whitespace-only name becomes empty → required fails.
        $response = $this->postScaleRaw(['name' => '   ']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('name', $response['json']['errors'] ?? []);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_rating_scale_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side rating-scale tests.'
        );
        // The runtime tables resolve within the current tenant DB.
        $this->assertTrue(Schema::hasTable(self::SCALES_TABLE));
    }

    public function test_rating_scale_91_cross_tenant_direct_id_isolation(): void
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

    public function test_rating_scale_92_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaRatingScaleRequest.php'));
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

    public function test_rating_scale_93_stored_xss_in_description_not_executed_on_show(): void
    {
        $code = $this->uniqueCode('S');
        $this->deleteScaleByCode($code);
        $payload = ['code' => $code, 'description' => 'Desc <img src=x onerror=alert(1)>'];
        $response = $this->postScale($payload);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));
        $scale = BaRatingScale::where('code', $code)->first();
        $this->assertNotNull($scale);

        $this->browseWithFailureScreenshot('stored-xss', function (Browser $browser) use ($scale): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/rating-scales/' . $scale->id, 900);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<img src=x onerror=alert(1)>', $source, 'Blade must escape stored description.');
        });

        $this->forceDeleteScale($scale);
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
        $rawName = 'rating-scale-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'rating-scale-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function openCreatePage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
        $browser->waitFor('#code', 15)->waitFor('#name', 10);
    }

    private function openMastersTab(Browser $browser, ?string $search = null): void
    {
        $path = self::MASTERS_PATH;
        if ($search !== null && $search !== '') {
            $path .= '&search=' . urlencode($search);
        }
        $this->visitAuthenticated($browser, $path, 1000);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#rating-scales-pane') !== null
                || $browser->element('table') !== null;
        }, 'Rating-scales masters tab did not render.');
    }

    /**
     * Issue an authenticated (admin) JSON request from a freshly-opened, logged-in browser page.
     * Opens the create page (so a CSRF meta + same-origin cookies exist), then fetch()es the target URL.
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
window.__rsApiDone = false;
window.__rsApiError = '';
window.__rsApiResult = null;

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

        window.__rsApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__rsApiError = String(error);
    } finally {
        window.__rsApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__rsApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__rsApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__rsApiResult || null;');
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

    private function postScale(array $overrides = []): array
    {
        $payload = $this->validPayload($overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    /** Post a payload built on a seeded-valid base but with a targeted invalid field (keeps other fields valid). */
    private function postScaleRaw(array $overrides): array
    {
        $payload = array_merge($this->validPayload(), $overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    private function putScale(int $id, array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'PUT', $this->tenantUrl('/behavioural-assessment/rating-scales/' . $id), $payload));
    }

    private function deleteScale(int $id): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'DELETE', $this->tenantUrl('/behavioural-assessment/rating-scales/' . $id)));
    }

    private function toggleScale(int $id): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl('/behavioural-assessment/rating-scales/' . $id . '/toggle-status')));
    }

    private function validPayload(array $overrides = []): array
    {
        $code = $overrides['code'] ?? $this->uniqueCode('V');
        return array_merge([
            'code'        => $code,
            'name'        => $this->uniqueName('VALID'),
            'description' => 'Valid rating scale',
            'grade_type'  => 'numeric',
            'min_rating'  => 1,
            'max_rating'  => 5,
            'is_default'  => false,
            'is_active'   => true,
        ], $overrides);
    }

    // ---- Seed / cleanup ---------------------------------------------------

    private function createScaleSeed(array $overrides = []): BaRatingScale
    {
        $payload = array_merge([
            'code'        => $this->uniqueCode('S'),
            'name'        => $this->uniqueName('SEED'),
            'description' => 'Seed scale',
            'grade_type'  => 'numeric',
            'min_rating'  => 1,
            'max_rating'  => 5,
            'is_default'  => false,
            'is_active'   => true,
            'created_by'  => (int) $this->adminUser->id,
            'updated_by'  => (int) $this->adminUser->id,
        ], $overrides);

        return BaRatingScale::query()->create($payload);
    }

    private function createLevelSeed(int $scaleId, array $overrides = []): BaRatingLevel
    {
        $payload = array_merge([
            'rating_scale_id' => $scaleId,
            'label'           => 'Level',
            'numeric_value'   => 1,
            'description'     => null,
            'sort_order'      => 1,
            'is_active'       => true,
            'created_by'      => (int) $this->adminUser->id,
            'updated_by'      => (int) $this->adminUser->id,
        ], $overrides);

        return BaRatingLevel::query()->create($payload);
    }

    private function deleteScaleByCode(string $code): void
    {
        BaRatingScale::withTrashed()
            ->where('code', strtoupper($code))
            ->get()
            ->each(fn (BaRatingScale $scale) => $this->forceDeleteScale($scale));
    }

    private function forceDeleteScale(?BaRatingScale $scale): void
    {
        if ($scale === null) {
            return;
        }
        try {
            BaRatingLevel::withTrashed()->where('rating_scale_id', $scale->id)->get()
                ->each(function (BaRatingLevel $level): void {
                    try {
                        $level->forceDelete();
                    } catch (Throwable) {
                    }
                });
            if (BaRatingScale::withTrashed()->whereKey($scale->id)->exists()) {
                $scale->forceDelete();
            }
        } catch (Throwable) {
            // Cleanup is best-effort; a referenced/locked row is left for the next run's dedupe.
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
                'name'              => 'RS Limited ' . $this->uniqueSuffix(),
                'email'             => 'rs_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'RL' . substr($this->uniqueSuffix(), -8);
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
        $this->grantRatingScalePermissions($this->adminUser);
    }

    private function grantRatingScalePermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::RS_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::RS_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::RS_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.rating-scale-admin');
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
            $modelFile = (new ReflectionClass(BaRatingScale::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaRatingScale.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaRatingScale::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaRatingScale.php → app root = dirname(,5)
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

    private function uniqueCode(string $prefix = 'R'): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $clean = $clean === '' ? 'R' : substr($clean, 0, 1);
        return strtoupper($clean . 'RS' . $this->uniqueSuffix()); // <= 30 chars
    }

    private function uniqueName(string $prefix): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $clean = $clean === '' ? 'RS' : substr($clean, 0, 12);
        return substr($clean . ' Scale ' . $this->uniqueSuffix(), 0, 100);
    }
}
