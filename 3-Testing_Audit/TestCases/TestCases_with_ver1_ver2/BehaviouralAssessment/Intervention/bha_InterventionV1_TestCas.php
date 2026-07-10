<?php

/**
 * BehaviouralAssessment › Intervention — V1 (foundation) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/Intervention/InterventionCrudTest.php.
 * DB SCOPE: tenant-side (migrations live under database/migrations/tenant/; tenant init required).
 * TABLES  : ba_interventions (+ junction ba_incident_intervention_jnt). NOTE the DDL doc + this
 *           file's name use the stale prefix "bha_" (audit DOC-BA-001); the LIVE migrations/models/
 *           tables are "ba_". Every schema assertion targets the real "ba_" tables. Do not "fix"
 *           this to bha_ in code — it would break against the real DB.
 *
 * All routes/selectors/permissions/flash strings verified against:
 *   Modules/BehaviouralAssessment/app/Http/Controllers/BaInterventionController.php
 *   Modules/BehaviouralAssessment/app/Http/Requests/BaInterventionRequest.php
 *   Modules/BehaviouralAssessment/app/Models/BaIntervention.php
 *   Modules/BehaviouralAssessment/app/Policies/BaInterventionPolicy.php
 *   Modules/BehaviouralAssessment/routes/web.php
 *   Modules/BehaviouralAssessment/resources/views/intervention/{create,edit,show,trash}.blade.php
 *   Modules/BehaviouralAssessment/resources/views/pages/partials/masters/_interventions.blade.php
 *   database/migrations/tenant/2026_06_16_130615_create_ba_interventions_table.php
 *   database/migrations/tenant/2026_06_16_130626_create_ba_incident_intervention_jnt_table.php
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Requests\BaInterventionRequest;
use Modules\BehaviouralAssessment\Models\BaIntervention;
use Modules\SchoolSetup\Models\User;
use Tests\DuskTestCase;
use Throwable;

class bha_InterventionV1_TestCas extends DuskTestCase
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

    /** TC-P01 · BC-DB-01/06 · Audit-DOC-BA-001 · Source: DDL-ba_interventions / live migration */
    public function test_intervention_01_schema_model_and_softdelete_are_correct(): void
    {
        // DOC-BA-001: the DDL doc names the table bha_interventions, but the live table is ba_interventions.
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Live table ba_interventions does not exist.');
        $this->assertFalse(Schema::hasTable('bha_interventions'), 'Stale DDL-doc table bha_interventions should NOT exist (DOC-BA-001).');

        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'name', 'description', 'intervention_type', 'sort_order',
                'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing from ba_interventions.'
        );

        $migrationPath = base_path(self::MIGRATION_FILE);
        $this->assertTrue(File::exists($migrationPath), 'Migration not found: ' . self::MIGRATION_FILE);
        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('ba_interventions'", $migration);
        $this->assertStringContainsString("\$table->enum('intervention_type', ['corrective', 'counselling', 'reward'])", $migration);
        $this->assertStringContainsString("\$table->unsignedTinyInteger('sort_order')", $migration);
        $this->assertStringContainsString("\$table->softDeletes()", $migration);

        $this->assertTrue(File::exists(base_path(self::CONTROLLER_FILE)), 'Controller file missing.');

        $model = new BaIntervention();
        $this->assertSame('ba_interventions', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaIntervention::class));

        $fillable = $model->getFillable();
        foreach (['name', 'description', 'intervention_type', 'sort_order', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $fillable, "ba_interventions fillable should include {$col}.");
        }

        $casts = $model->getCasts();
        $this->assertSame('integer', $casts['sort_order'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);

        $this->assertInstanceOf(BelongsToMany::class, $model->incidents());
    }

    /** TC-P02 · BC-REF-01 · BC-DB-07 · Source: DDL-ba_incident_intervention_jnt uq_ba_inc_int + FK RESTRICT */
    public function test_intervention_02_junction_migration_fk_restrict_and_unique(): void
    {
        $this->assertTrue(Schema::hasTable(self::JUNCTION_TABLE), 'Live junction table ba_incident_intervention_jnt does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::JUNCTION_TABLE, [
                'id', 'notes', 'is_active', 'created_by', 'updated_by',
                'incident_id', 'intervention_id', 'deleted_at',
            ]),
            'Expected columns are missing from ba_incident_intervention_jnt.'
        );

        $migrationPath = base_path(self::MIGRATION_JNT);
        $this->assertTrue(File::exists($migrationPath), 'Junction migration not found: ' . self::MIGRATION_JNT);
        $migration = File::get($migrationPath);
        // incident_id cascades (child removed with parent incident); intervention_id is RESTRICT (default — no cascade).
        $this->assertStringContainsString("\$table->foreignId('incident_id')->constrained('ba_incidents')->cascadeOnDelete()", $migration);
        $this->assertStringContainsString("\$table->foreignId('intervention_id')->constrained('ba_interventions')", $migration);
        $this->assertStringNotContainsString("constrained('ba_interventions')->cascadeOnDelete()", $migration);
        $this->assertStringContainsString("uq_ba_inc_int", $migration);
    }

    /** TC-N01 · BC-DB-04 · Source: DDL-ba_interventions NOT NULL */
    public function test_intervention_03_db_rejects_missing_required_fields(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();

        foreach (['name', 'intervention_type', 'sort_order'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P03 · BC-DB-05 · Source: DDL description nullable */
    public function test_intervention_04_nullable_description_accepts_null(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;

        try {
            $record = $this->createRecordDirectly($dependencies, ['description' => null]);
            $this->assertNotNull($record->id, 'Intervention with null description did not save.');
            $this->assertNull($record->description);
        } finally {
            if ($record instanceof BaIntervention) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ──────────────────────────────────────────────
    //  10–19  Core CRUD / business behaviour
    // ──────────────────────────────────────────────

    /** TC-P10 · BC-BIZ-01 · Source: create.blade sections + button */
    public function test_intervention_10_create_page_loads_and_shows_sections(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);

            $browser->waitFor('input[name="name"]', 12)
                ->assertSee('Intervention Details')
                ->assertSee('Additional Information')
                ->assertPresent('select[name="intervention_type"]')
                ->assertPresent('input[name="sort_order"]')
                ->assertSee('Save Intervention');
        });
    }

    /** TC-P11 · BC-BIZ-02 · Source: Controller@store flash "Intervention created successfully." */
    public function test_intervention_11_create_submission_persists(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V1 Create ' . $this->generateUniqueSuffix();
        $sortOrder = $this->freeSortOrder();
        $saved = null;

        try {
            $this->browse(function (Browser $browser) use ($name, $sortOrder): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', $name)
                    ->select('intervention_type', 'reward')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $sortOrder)
                    ->press('Save Intervention')
                    ->pause(2500);
            });

            $saved = BaIntervention::query()->where('name', $name)->latest('id')->first();
            $this->assertNotNull($saved, 'Intervention was not persisted.');
            $this->assertSame('reward', (string) $saved->intervention_type);
        } finally {
            if ($saved instanceof BaIntervention) {
                $this->forceDeleteRecordByIdIfExists((int) $saved->id);
            }
        }
    }

    /** TC-P12 · BC-BIZ-03 · Source: show.blade "Intervention Name" + badge */
    public function test_intervention_12_show_page_displays_data(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Show ' . $this->generateUniqueSuffix(),
            'intervention_type' => 'corrective',
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);

                $browser->waitForText('Intervention Name', 12)
                    ->assertSee((string) $record->name)
                    ->assertSee('Corrective'); // ucfirst($intervention->intervention_type)
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P13 · BC-BIZ-04 · Source: Controller@update flash "Intervention updated successfully." */
    public function test_intervention_13_edit_update_persists_and_flashes(): void
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
                    ->press('Update Intervention')
                    ->pause(2200)
                    ->assertSee('Intervention updated successfully.');
            });

            $record->refresh();
            $this->assertSame($updatedName, (string) $record->name);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P14 · BC-SM-01 · Source: Controller@toggleStatus + status-switch component (.status-switch) */
    public function test_intervention_14_toggle_status_flips_is_active(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Toggle ' . $this->generateUniqueSuffix(),
            'is_active' => true,
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::LISTING_PATH, 900);

                $browser->waitFor('.status-switch[data-id="' . $record->id . '"]', 12)
                    ->script("\$('.status-switch[data-id=\"{$record->id}\"]').click()");
                $browser->pause(1600);
            });

            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'is_active should have toggled to false.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D01 (F) · BC-SM-03 · Source: Controller destroy/restore/forceDelete */
    public function test_intervention_15_soft_delete_restore_force_delete_lifecycle(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Lifecycle ' . $this->generateUniqueSuffix(),
        ]);
        $recordId = (int) $record->id;

        try {
            $record->delete();
            $this->assertNotNull(BaIntervention::withTrashed()->find($recordId));
            $this->assertNull(BaIntervention::find($recordId));

            $record->restore();
            $this->assertNotNull(BaIntervention::find($recordId));

            $record->forceDelete();
            $this->assertNull(BaIntervention::withTrashed()->find($recordId));
        } finally {
            $this->forceDeleteRecordByIdIfExists($recordId);
        }
    }

    // ──────────────────────────────────────────────
    //  30–39  Validation (negative)
    // ──────────────────────────────────────────────

    /** TC-N10 · BC-VAL-04 · Source: BaInterventionRequest sort_order unique whereNull(deleted_at) */
    public function test_intervention_16_duplicate_active_sort_order_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $existing = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 SortDup Existing ' . $this->generateUniqueSuffix(),
            'sort_order' => $this->freeSortOrder(),
        ]);
        $before = BaIntervention::query()->count();

        try {
            $this->browse(function (Browser $browser) use ($existing): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', 'V1 SortDup Attempt ' . $this->generateUniqueSuffix())
                    ->select('intervention_type', 'reward')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $existing->sort_order)
                    ->press('Save Intervention')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertSame($before, BaIntervention::query()->count(), 'Duplicate active sort_order should not create a row.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $existing->id);
        }
    }

    /** TC-N11 · BC-VAL-03 · Source: BaInterventionRequest intervention_type Rule::in(...) */
    public function test_intervention_17_invalid_intervention_type_is_rejected(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V1 BadType ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($name): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                // Inject an out-of-enum option so we can post an illegal value past the <select>.
                $browser->waitFor('select[name="intervention_type"]', 12)
                    ->script("(function(){var s=document.querySelector('select[name=\"intervention_type\"]');var o=document.createElement('option');o.value='detention';o.text='detention';s.appendChild(o);s.value='detention';})();");
                $browser->type('input[name="name"]', $name)
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', (string) $this->freeSortOrder())
                    ->press('Save Intervention')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertNull(
                BaIntervention::query()->where('name', $name)->first(),
                'Invalid intervention_type should not create a row.'
            );
        } finally {
            BaIntervention::query()->where('name', $name)->forceDelete();
        }
    }

    /** TC-N12 · BC-VAL-04 · Source: BaInterventionRequest sort_order min:0 */
    public function test_intervention_18_negative_sort_order_is_rejected(): void
    {
        $this->resolveDependenciesOrSkip();
        $name = 'V1 NegSort ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($name): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="name"]', 12)
                    ->script("document.querySelector('input[name=\"sort_order\"]').removeAttribute('min');")
                    ->type('input[name="name"]', $name)
                    ->select('intervention_type', 'reward')
                    ->clear('input[name="sort_order"]')->type('input[name="sort_order"]', '-4')
                    ->press('Save Intervention')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertNull(
                BaIntervention::query()->where('name', $name)->first(),
                'Negative sort_order should be rejected (min:0).'
            );
        } finally {
            BaIntervention::query()->where('name', $name)->forceDelete();
        }
    }

    // ──────────────────────────────────────────────
    //  50–59 / 60–69  Auth + UI
    // ──────────────────────────────────────────────

    /** TC-S01 · BC-AUTH-01 · Source: web routes behind auth middleware */
    public function test_intervention_19_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    /** TC-P21 · BC-BIZ-07 · Source: Controller@trashed + trash.blade */
    public function test_intervention_20_trash_page_lists_soft_deleted(): void
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

    // ──────────────────────────────────────────────
    //  Helpers (mirror the committed sibling test)
    // ──────────────────────────────────────────────

    private function resolveDependenciesOrSkip(): array
    {
        $adminUserId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));
        if ($adminUserId <= 0) {
            $this->markTestSkipped('No admin user found for intervention tests.');
        }

        return ['admin_user_id' => $adminUserId];
    }

    private function createRecordDirectly(array $dependencies, array $overrides = []): BaIntervention
    {
        $payload = array_merge($this->buildValidDirectPayload($dependencies), $overrides);

        return BaIntervention::query()->create($payload);
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'name'              => 'Intervention ' . $this->generateUniqueSuffix(),
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

        $permissions = $this->interventionPermissions();
        $this->ensurePermissionsExist($permissions);

        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
    }

    private function interventionPermissions(): array
    {
        return [
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

    /** Reference to BaInterventionRequest to keep the FormRequest import meaningful for static tools. */
    private function requestClassName(): string
    {
        return BaInterventionRequest::class;
    }

    /** Reference to DB facade for parity with the sibling helper surface. */
    private function interventionsTableName(): string
    {
        return DB::getTablePrefix() . self::TABLE;
    }
}
