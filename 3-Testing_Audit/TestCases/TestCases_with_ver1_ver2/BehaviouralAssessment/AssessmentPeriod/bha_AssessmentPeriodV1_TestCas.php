<?php

/**
 * BehaviouralAssessment › AssessmentPeriod — V1 (foundation) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/AssessmentPeriod/AssessmentPeriodCrudTest.php.
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; table under database/migrations/tenant/).
 * TABLE   : ba_assessment_periods — the DDL doc names it "bha_assessment_periods" (stale prefix,
 *           audit DOC-BA-001); the LIVE migration/model/table is "ba_assessment_periods". Artifact
 *           FILE names follow the DDL/inventory prefix "bha_"; every schema assertion targets "ba_".
 *
 * Routes/selectors/permissions/flash strings verified against the REAL source:
 *   Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php
 *   Modules/BehaviouralAssessment/app/Http/Requests/BaAssessmentPeriodRequest.php
 *   Modules/BehaviouralAssessment/app/Models/BaAssessmentPeriod.php
 *   Modules/BehaviouralAssessment/routes/web.php
 *   Modules/BehaviouralAssessment/resources/views/assessment-period/{create,edit,trash}.blade.php
 *   Modules/BehaviouralAssessment/resources/views/pages/partials/setup/_periods.blade.php
 *   database/migrations/tenant/2026_06_16_130612_create_ba_assessment_periods_table.php
 *
 * NOTE: the committed sibling contains several STALE expectations (wrong migration path,
 *       'Create/Edit Assessment Period' texts that do not exist, capitalised flash
 *       'Assessment Period updated…', and .lock-btn/.unlock-btn/.status-switch selectors).
 *       This suite uses the REAL strings and drives lock/unlock/toggle via the real endpoints.
 */

namespace Tests\Browser;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Requests\BaAssessmentPeriodRequest;
use Modules\BehaviouralAssessment\Models\BaAssessmentPeriod;
use Modules\SchoolSetup\Models\OrganizationAcademicSession;
use Modules\SchoolSetup\Models\User;
use Modules\TimetableFoundation\Models\AcademicTerm;
use Tests\DuskTestCase;
use Throwable;

class bha_AssessmentPeriodV1_TestCas extends DuskTestCase
{
    private const SETUP_PATH      = '/behavioural-assessment/setup';
    private const PERIODS_TAB     = '/behavioural-assessment/setup?tab=periods';
    private const CREATE_PATH     = '/behavioural-assessment/assessment-periods/create';
    private const SHOW_BASE_PATH  = '/behavioural-assessment/assessment-periods';
    private const TRASH_PATH      = '/behavioural-assessment/assessment-periods/trash';
    private const TABLE           = 'ba_assessment_periods';
    private const MIGRATION_FILE  = 'database/migrations/tenant/2026_06_16_130612_create_ba_assessment_periods_table.php';
    private const CONTROLLER_FILE = 'Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php';
    private const REQUEST_FILE    = 'Modules/BehaviouralAssessment/app/Http/Requests/BaAssessmentPeriodRequest.php';

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

    /** TC-P01 · BC-DB-01/06 · Audit-DOC-BA-001 · Source: DDL-bha_assessment_periods / live migration */
    public function test_assessment_period_01_schema_model_and_softdelete_are_correct(): void
    {
        // DOC-BA-001: DDL doc names the table bha_assessment_periods; the LIVE table is ba_assessment_periods.
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Live table ba_assessment_periods does not exist.');
        $this->assertFalse(Schema::hasTable('bha_assessment_periods'), 'Stale DDL-doc table bha_assessment_periods should NOT exist (DOC-BA-001).');

        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'academic_session_id', 'academic_term_id', 'name',
                'start_date', 'end_date', 'deadline', 'status', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected assessment-period columns are missing from ba_assessment_periods.'
        );

        $migrationPath = base_path(self::MIGRATION_FILE);
        $this->assertTrue(File::exists($migrationPath), 'Migration file not found: ' . self::MIGRATION_FILE);
        $migration = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('ba_assessment_periods'", $migration);
        // Real migration declares the enum in the order ['closed', 'locked', 'open'] with default 'open'.
        $this->assertStringContainsString("\$table->enum('status', ['closed', 'locked', 'open'])", $migration);
        $this->assertStringContainsString("->default('open')", $migration);
        $this->assertStringContainsString("\$table->softDeletes()", $migration);

        $this->assertTrue(File::exists(base_path(self::CONTROLLER_FILE)), 'Controller file missing.');

        $model = new BaAssessmentPeriod();
        $this->assertSame('ba_assessment_periods', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessmentPeriod::class));

        $casts = $model->getCasts();
        $this->assertSame('date', $casts['start_date'] ?? null);
        $this->assertSame('date', $casts['end_date'] ?? null);
        $this->assertSame('date', $casts['deadline'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);

        $this->assertInstanceOf(BelongsTo::class, $model->academicSession());
        $this->assertInstanceOf(BelongsTo::class, $model->academicTerm());
        $this->assertInstanceOf(HasMany::class, $model->assessments());
        $this->assertInstanceOf(HasMany::class, $model->computedScores());
    }

    /** TC-N01 · BC-DB-04 · Source: DDL NOT NULL columns */
    public function test_assessment_period_02_db_rejects_missing_required_fields(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();

        foreach (['academic_session_id', 'name', 'start_date', 'end_date', 'deadline'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P02 · BC-DB-05 · Source: DDL academic_term_id nullable (ON DELETE SET NULL) */
    public function test_assessment_period_03_nullable_academic_term_accepts_null(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;

        try {
            $record = $this->createRecordDirectly($dependencies, ['academic_term_id' => null]);
            $this->assertNotNull($record->id, 'Period with null academic_term did not save.');
            $this->assertNull($record->academic_term_id);
        } finally {
            if ($record instanceof BaAssessmentPeriod) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ──────────────────────────────────────────────
    //  10–19  Core CRUD / business behaviour
    // ──────────────────────────────────────────────

    /** TC-P10 · BC-BIZ-01 · Source: create.blade sections + button "Save Assessment Period" */
    public function test_assessment_period_10_create_page_loads_and_shows_sections(): void
    {
        $this->resolveDependenciesOrSkip();

        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);

            $browser->waitFor('input[name="name"]', 12)
                ->assertSee('Academic Context')
                ->assertSee('Period Details')
                ->assertPresent('select[name="academic_session_id"]')
                ->assertSee('New periods always start as Open.')
                ->assertSee('Save Assessment Period');
        });
    }

    /** TC-P11 · BC-BIZ-02 · BC-SM-09 · Source: Controller@store flash "Assessment period created successfully." (status defaults open) */
    public function test_assessment_period_11_create_submission_persists_as_open(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V1 Create ' . $this->generateUniqueSuffix();
        $saved = null;

        try {
            $this->browse(function (Browser $browser) use ($dependencies, $name): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', $name)
                    ->select('academic_session_id', (string) $dependencies['academic_session_id'])
                    ->type('input[name="start_date"]', now()->format('Y-m-d'))
                    ->type('input[name="end_date"]', now()->addMonth()->format('Y-m-d'))
                    ->type('input[name="deadline"]', now()->addDays(40)->format('Y-m-d'))
                    ->press('Save Assessment Period')
                    ->pause(2500);
            });

            $saved = BaAssessmentPeriod::query()->where('name', $name)->latest('id')->first();
            $this->assertNotNull($saved, 'Assessment period was not created.');
            $this->assertSame('open', (string) $saved->status, 'New period status should default to open.');
        } finally {
            if ($saved instanceof BaAssessmentPeriod) {
                $this->forceDeleteRecordByIdIfExists((int) $saved->id);
            }
        }
    }

    /** TC-P12 · BC-BIZ-03 · Source: Controller@show → redirect to edit; edit.blade "Period Details" */
    public function test_assessment_period_12_show_redirects_to_edit_and_displays_data(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V1 Show ' . $this->generateUniqueSuffix()]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);

                // show() redirects to the edit screen.
                $browser->waitFor('input[name="name"]', 12)
                    ->assertSee('Period Details')
                    ->assertInputValue('input[name="name"]', (string) $record->name);
                $this->assertStringContainsString('/edit', $this->currentPath($browser), 'show() should redirect to the edit screen.');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P13 · BC-BIZ-04 · Source: Controller@update flash "Assessment period updated successfully." */
    public function test_assessment_period_13_edit_update_persists_and_flashes(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V1 Before ' . $this->generateUniqueSuffix()]);
        $updatedName = 'V1 After ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($record, $updatedName): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);

                $browser->waitFor('input[name="name"]', 12)
                    ->clear('input[name="name"]')
                    ->type('input[name="name"]', $updatedName)
                    ->press('Update Assessment Period')
                    ->pause(2200)
                    ->assertSee('Assessment period updated successfully.');
            });

            $record->refresh();
            $this->assertSame($updatedName, (string) $record->name);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ──────────────────────────────────────────────
    //  20–29  State-machine / status lifecycle
    // ──────────────────────────────────────────────

    /** TC-SM-tog · BC-SM-07 · Source: Controller@toggleStatus JSON {success,is_active,message} */
    public function test_assessment_period_20_toggle_status_endpoint_flips_is_active(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Toggle ' . $this->generateUniqueSuffix(),
            'is_active' => true,
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::PERIODS_TAB, 900);

                $response = $this->postJsonFromBrowser(
                    $browser,
                    self::SHOW_BASE_PATH . '/' . $record->id . '/toggle-status'
                );
                $this->assertStringContainsString('"success"', $response, 'toggle-status should return a success key.');
                $this->assertStringContainsString('Assessment period', $response, 'toggle-status should return the status message.');
            });

            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'is_active should have toggled to false.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM-01 · BC-SM-01 (legal) · Source: Controller@lock — open → locked */
    public function test_assessment_period_21_lock_open_period_sets_locked(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Lock ' . $this->generateUniqueSuffix(),
            'status' => 'open',
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::PERIODS_TAB, 900);
                $this->postFormFromBrowser($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/lock');
                $browser->pause(1200);
            });

            $record->refresh();
            $this->assertSame('locked', (string) $record->status, 'Period should transition open → locked.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM-02 · BC-SM-02 (legal) · Source: Controller@unlock — locked → closed (mislabeled "unlock") */
    public function test_assessment_period_22_unlock_locked_period_sets_closed(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, [
            'name' => 'V1 Unlock ' . $this->generateUniqueSuffix(),
            'status' => 'locked',
        ]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::PERIODS_TAB, 900);
                $this->postFormFromBrowser($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/unlock');
                $browser->pause(1200);
            });

            $record->refresh();
            $this->assertSame('closed', (string) $record->status, 'unlock() sets locked → closed (not back to open).');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D01 (F) · BC-SM-05 · Source: Controller destroy/restore/forceDelete */
    public function test_assessment_period_23_soft_delete_restore_force_delete_lifecycle(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V1 Lifecycle ' . $this->generateUniqueSuffix()]);
        $recordId = (int) $record->id;

        try {
            $record->delete();
            $this->assertNotNull(BaAssessmentPeriod::withTrashed()->find($recordId));
            $this->assertNull(BaAssessmentPeriod::find($recordId));

            $record->restore();
            $this->assertNotNull(BaAssessmentPeriod::find($recordId));

            $record->forceDelete();
            $this->assertNull(BaAssessmentPeriod::withTrashed()->find($recordId));
        } finally {
            $this->forceDeleteRecordByIdIfExists($recordId);
        }
    }

    // ──────────────────────────────────────────────
    //  30–39  Validation (negative)
    // ──────────────────────────────────────────────

    /** TC-N02 · BC-VAL-* · Source: BaAssessmentPeriodRequest rules() literal strings */
    public function test_assessment_period_30_form_request_rules_contain_expected_constraints(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("'academic_session_id'", $request);
        $this->assertStringContainsString("exists:sch_org_academic_sessions_jnt,id", $request);
        $this->assertStringContainsString("'after_or_equal:start_date'", $request);
        $this->assertStringContainsString("'gte:end_date'", $request);
        $this->assertStringContainsString("'in:open,closed,locked'", $request);
    }

    /** TC-N10 · BC-VAL-03 · Source: end_date after_or_equal:start_date */
    public function test_assessment_period_31_end_date_before_start_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V1 BadDates ' . $this->generateUniqueSuffix();
        $before = BaAssessmentPeriod::query()->count();

        try {
            $this->browse(function (Browser $browser) use ($dependencies, $name): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);

                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', $name)
                    ->select('academic_session_id', (string) $dependencies['academic_session_id'])
                    ->type('input[name="start_date"]', now()->format('Y-m-d'))
                    ->type('input[name="end_date"]', now()->subDays(5)->format('Y-m-d'))
                    ->type('input[name="deadline"]', now()->addDays(10)->format('Y-m-d'))
                    ->press('Save Assessment Period')
                    ->pause(2000)
                    ->assertPresent('.alert-danger');
            });

            $this->assertSame($before, BaAssessmentPeriod::query()->count(), 'end_date before start_date must be rejected.');
        } finally {
            BaAssessmentPeriod::query()->where('name', $name)->forceDelete();
        }
    }

    // ──────────────────────────────────────────────
    //  50–59 / 60–69 / 90  Auth + UI + tenancy
    // ──────────────────────────────────────────────

    /** TC-S01 · BC-AUTH-01 · Source: web routes behind auth middleware */
    public function test_assessment_period_50_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    /** TC-P20 · BC-BIZ-06 · Source: setup _periods partial table + status badge */
    public function test_assessment_period_60_setup_periods_tab_lists_created_period(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V1 Listed ' . $this->generateUniqueSuffix()]);

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::PERIODS_TAB . '&search=' . urlencode((string) $record->name), 1000);
                $browser->assertSee((string) $record->name);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-T01 · BC-CFG-01 · Source: tenant-per-DB (no tenant_id column) */
    public function test_assessment_period_90_runs_inside_initialized_tenant(): void
    {
        if (!function_exists('tenancy')) {
            $this->markTestSkipped('Tenancy helper unavailable.');
        }
        $this->assertTrue(tenancy()->initialized, 'AssessmentPeriod is tenant-scoped and requires an initialized tenant.');
        $this->assertTrue(Schema::hasTable(self::TABLE), 'ba_assessment_periods must resolve within the tenant DB.');
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'tenant_id'), 'Tenant-per-database design → no tenant_id column.');
    }

    // ──────────────────────────────────────────────
    //  Helpers (mirror the committed sibling test)
    // ──────────────────────────────────────────────

    private function resolveDependenciesOrSkip(): array
    {
        $adminUserId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));
        if ($adminUserId <= 0) {
            $this->markTestSkipped('No admin user found for assessment period tests.');
        }

        $academicSessionId = (int) OrganizationAcademicSession::query()->orderBy('id')->value('id');
        if ($academicSessionId <= 0) {
            $this->markTestSkipped('No academic session found for assessment period tests.');
        }

        $academicTermId = (int) AcademicTerm::query()->orderBy('id')->value('id');

        return [
            'admin_user_id' => $adminUserId,
            'academic_session_id' => $academicSessionId,
            'academic_term_id' => $academicTermId > 0 ? $academicTermId : null,
        ];
    }

    private function createRecordDirectly(array $dependencies, array $overrides = []): BaAssessmentPeriod
    {
        return BaAssessmentPeriod::query()->create(array_merge($this->buildValidDirectPayload($dependencies), $overrides));
    }

    private function buildValidDirectPayload(array $dependencies): array
    {
        return [
            'academic_session_id' => (int) $dependencies['academic_session_id'],
            'academic_term_id' => $dependencies['academic_term_id'],
            'name' => 'Assessment Period ' . $this->generateUniqueSuffix(),
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->addMonth()->format('Y-m-d'),
            'deadline' => now()->addDays(40)->format('Y-m-d'),
            'status' => 'open',
            'is_active' => true,
            'created_by' => (int) $dependencies['admin_user_id'],
            'updated_by' => (int) $dependencies['admin_user_id'],
        ];
    }

    private function forceDeleteRecordByIdIfExists(int $recordId): void
    {
        BaAssessmentPeriod::withTrashed()->where('id', $recordId)->get()
            ->each(function (BaAssessmentPeriod $record): void {
                try {
                    $record->assessments()->forceDelete();
                    $record->forceDelete();
                } catch (Throwable) {
                    // ignore FK/soft-delete cleanup issues
                }
            });
    }

    private function assertDatabaseRejectsMissingField(array $dependencies, string $missingField): void
    {
        $created = null;

        try {
            $payload = $this->buildValidDirectPayload($dependencies);
            unset($payload[$missingField]);

            $created = BaAssessmentPeriod::query()->create($payload);
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
            if ($created instanceof BaAssessmentPeriod) {
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

        $permissions = $this->assessmentPeriodPermissions();
        $this->ensurePermissionsExist($permissions);

        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
    }

    private function assessmentPeriodPermissions(): array
    {
        return [
            'tenant.behavioural-assessment.assessment-periods.viewAny',
            'tenant.behavioural-assessment.assessment-periods.view',
            'tenant.behavioural-assessment.assessment-periods.create',
            'tenant.behavioural-assessment.assessment-periods.update',
            'tenant.behavioural-assessment.assessment-periods.delete',
            'tenant.behavioural-assessment.assessment-periods.status',
            'tenant.behavioural-assessment.assessment-periods.lock',
            'tenant.behavioural-assessment.assessment-periods.unlock',
            'tenant.behavioural-assessment.assessment-periods.restore',
            'tenant.behavioural-assessment.assessment-periods.forceDelete',
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

    private function postJsonFromBrowser(Browser $browser, string $path): string
    {
        return $this->postFromBrowser($browser, $path, 'application/json');
    }

    private function postFormFromBrowser(Browser $browser, string $path): string
    {
        return $this->postFromBrowser($browser, $path, 'text/html');
    }

    private function postFromBrowser(Browser $browser, string $path, string $accept): string
    {
        $url = $this->tenantUrl($path);
        $script = <<<JS
        var done = arguments[arguments.length - 1];
        var token = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';
        fetch("{$url}", {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': token, 'Accept': '{$accept}', 'X-Requested-With': 'XMLHttpRequest' },
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

    private function tenantUrl(string $path): string
    {
        return $this->tenantBaseUrl . '/' . ltrim($path, '/');
    }

    private function currentPath(Browser $browser): string
    {
        $path = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);
        return is_string($path) ? $path : '';
    }

    /** Keeps the FormRequest / DB imports meaningful for static analysis. */
    private function requestClassName(): string
    {
        return BaAssessmentPeriodRequest::class;
    }

    private function tableName(): string
    {
        return DB::getTablePrefix() . self::TABLE;
    }
}
