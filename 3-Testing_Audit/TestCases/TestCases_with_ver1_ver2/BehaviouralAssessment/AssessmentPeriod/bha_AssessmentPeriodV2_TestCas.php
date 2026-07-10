<?php

/**
 * BehaviouralAssessment › AssessmentPeriod — V2 (comprehensive) Dusk suite.
 *
 * STYLE   : browser Dusk (extends DuskTestCase) — mirrors the module's committed sibling
 *           prime_ai/tests/Browser/Modules/BehaviouralAssessment/AssessmentPeriod/AssessmentPeriodCrudTest.php.
 * DB SCOPE: tenant-side (DDL header "Database: tenant_db"; table under database/migrations/tenant/).
 * TABLE   : ba_assessment_periods. DDL doc + this file's name use the stale prefix "bha_"
 *           (audit DOC-BA-001); every schema assertion targets the LIVE "ba_" table.
 *
 * This is a WORKFLOW / FSM-heavy feature. The status enum is ('open','closed','locked').
 * Real transition surface (verified against BaAssessmentPeriodController):
 *   • store()   → always defaults status='open'.
 *   • lock()    → {open,closed} → locked   (guard blocks only when already 'locked').
 *   • unlock()  → locked → 'closed'         (mislabeled: does NOT return to 'open').
 *   • update()  → writes status from the edit-form <select> with NO FSM guard (back-door).
 *   • toggleStatus() → flips is_active only (orthogonal enable/disable, not a status transition).
 *   There is NO close() action → open→closed is unreachable via any lifecycle action.
 *
 * Semantic numbering bands (WP-G):
 *   01–09 schema/model/request · 10–19 business · 20–29 STATE-MACHINE (FSM)
 *   30–39 validation · 40–49 integration/FK · 50–59 permissions · 60–69 UI/UX
 *   70–79 edge · 90–99 tenancy + security
 *
 * Audit findings proven here (reported as "verify in source" — traced to the cited lines):
 *   BUG-BA-002  illegal transitions / open→closed unreachable  → _25 _26 _27 _28
 *   BUG-BA-001  period lock never freezes assessments/ratings  → _29 (source) + _41 (data, defensive)
 *   SEC-BA-002  FormRequest authorize() returns bare true      → _52
 *   VAL-BA-AP-01 non-overlapping-period rule not enforced      → _71 (new candidate)
 *   DOC-BA-001  DDL doc prefix bha_ vs live ba_                → _01
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
use Modules\BehaviouralAssessment\Models\BaAssessment;
use Modules\BehaviouralAssessment\Models\BaAssessmentPeriod;
use Modules\SchoolSetup\Models\OrganizationAcademicSession;
use Modules\SchoolSetup\Models\User;
use Modules\TimetableFoundation\Models\AcademicTerm;
use Tests\DuskTestCase;
use Throwable;

class bha_AssessmentPeriodV2_TestCas extends DuskTestCase
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

    /** TC-P01 · BC-DB-01 · Audit-DOC-BA-001 · Source: DDL / live migration */
    public function test_assessment_period_01_schema_and_model_configuration_are_correct(): void
    {
        // DOC-BA-001: DDL doc names the table bha_assessment_periods; the live table is ba_assessment_periods.
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Live table ba_assessment_periods does not exist.');
        $this->assertFalse(Schema::hasTable('bha_assessment_periods'), 'Stale DDL-doc table bha_assessment_periods should NOT exist (DOC-BA-001).');

        $this->assertTrue(Schema::hasColumns(self::TABLE, [
            'id', 'academic_session_id', 'academic_term_id', 'name',
            'start_date', 'end_date', 'deadline', 'status', 'is_active',
            'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing from ba_assessment_periods.');

        $model = new BaAssessmentPeriod();
        $this->assertSame('ba_assessment_periods', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessmentPeriod::class));

        $casts = $model->getCasts();
        $this->assertSame('date', $casts['start_date'] ?? null);
        $this->assertSame('date', $casts['end_date'] ?? null);
        $this->assertSame('date', $casts['deadline'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);
    }

    /** TC-P02 · BC-REF-01/02 · Source: live migration enum/softdelete/FK names */
    public function test_assessment_period_02_migration_defines_enum_softdelete_and_fks(): void
    {
        $migration = File::get(base_path(self::MIGRATION_FILE));
        $this->assertStringContainsString("Schema::create('ba_assessment_periods'", $migration);
        $this->assertStringContainsString("\$table->enum('status', ['closed', 'locked', 'open'])", $migration);
        $this->assertStringContainsString("->default('open')", $migration);
        $this->assertStringContainsString("\$table->softDeletes()", $migration);
        $this->assertStringContainsString("'fk_ba_period_session_id'", $migration);
        $this->assertStringContainsString("'fk_ba_period_term_id'", $migration);
        $this->assertStringContainsString("->onDelete('set null')", $migration);
    }

    /** TC-P03 · BC-DB-06 · Source: Model fillable / casts / relationships / scopes */
    public function test_assessment_period_03_model_fillable_relationships_and_scopes(): void
    {
        $model = new BaAssessmentPeriod();
        foreach (['academic_session_id', 'academic_term_id', 'name', 'start_date', 'end_date', 'deadline', 'status', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $model->getFillable(), "fillable should include {$col}.");
        }

        $this->assertInstanceOf(BelongsTo::class, $model->academicSession());
        $this->assertInstanceOf(BelongsTo::class, $model->academicTerm());
        $this->assertInstanceOf(HasMany::class, $model->assessments());
        $this->assertInstanceOf(HasMany::class, $model->computedScores());

        $openSql = strtolower(BaAssessmentPeriod::query()->open()->toSql());
        $this->assertStringContainsString('status', $openSql, 'scopeOpen should filter on status.');
        $activeSql = strtolower(BaAssessmentPeriod::query()->active()->toSql());
        $this->assertStringContainsString('is_active', $activeSql, 'scopeActive should filter on is_active.');
    }

    /** TC-N02 · BC-VAL-* · Source: BaAssessmentPeriodRequest rules() literal strings */
    public function test_assessment_period_04_form_request_rules_contain_expected_constraints(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("exists:sch_org_academic_sessions_jnt,id", $request);
        $this->assertStringContainsString("exists:sch_academic_term,id", $request);
        $this->assertStringContainsString("'max:100'", $request);
        $this->assertStringContainsString("'after_or_equal:start_date'", $request);
        $this->assertStringContainsString("'gte:end_date'", $request);
        $this->assertStringContainsString("'in:open,closed,locked'", $request);
    }

    /** TC-N01 · BC-DB-04 · Source: DDL NOT NULL columns */
    public function test_assessment_period_05_db_rejects_each_missing_required_field(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        foreach (['academic_session_id', 'name', 'start_date', 'end_date', 'deadline'] as $field) {
            $this->assertDatabaseRejectsMissingField($dependencies, $field);
        }
    }

    /** TC-P04 · BC-DB-05 · Source: academic_term_id nullable */
    public function test_assessment_period_06_nullable_academic_term_accepts_null(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = null;
        try {
            $record = $this->createRecordDirectly($dependencies, ['academic_term_id' => null]);
            $this->assertNull($record->academic_term_id);
        } finally {
            if ($record instanceof BaAssessmentPeriod) {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
            }
        }
    }

    // ══════════════════════════════════════════════
    //  10–19  Business rules
    // ══════════════════════════════════════════════

    /** TC-P10 · BC-BIZ-02 · Source: Controller@store */
    public function test_assessment_period_10_create_valid_persists_row(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V2 Create ' . $this->uniqueSuffix();
        $saved = null;
        try {
            $this->browserCreatePeriod($dependencies, $name);
            $saved = BaAssessmentPeriod::query()->where('name', $name)->first();
            $this->assertNotNull($saved, 'Valid assessment period was not created.');
        } finally {
            $this->cleanupByName($name);
        }
    }

    /** TC-P11 · BC-BIZ-01 · Source: create.blade sections + open note */
    public function test_assessment_period_11_create_page_shows_sections_and_open_note(): void
    {
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $browser->waitFor('input[name="name"]', 12)
                ->assertSee('Academic Context')
                ->assertSee('Period Details')
                ->assertSee('New periods always start as Open.')
                ->assertSee('Save Assessment Period');
        });
    }

    /** TC-P12 · BC-SM-09 · Source: Controller@store forces status='open' */
    public function test_assessment_period_12_store_defaults_status_to_open(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V2 OpenDefault ' . $this->uniqueSuffix();
        $saved = null;
        try {
            $this->browserCreatePeriod($dependencies, $name);
            $saved = BaAssessmentPeriod::query()->where('name', $name)->first();
            $this->assertNotNull($saved);
            $this->assertSame('open', (string) $saved->status, 'A new period must start in the open state.');
        } finally {
            $this->cleanupByName($name);
        }
    }

    /** TC-P13 · BC-BIZ-03 · Source: Controller@show → redirect edit */
    public function test_assessment_period_13_show_redirects_to_edit(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Show ' . $this->uniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 900);
                $browser->waitFor('input[name="name"]', 12);
                $this->assertStringContainsString('/edit', $this->currentPath($browser), 'show() should redirect to edit.');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P14 · BC-BIZ-04 · Source: Controller@update flash "Assessment period updated successfully." */
    public function test_assessment_period_14_edit_update_persists_and_flashes(): void
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
                    ->press('Update Assessment Period')->pause(2200)
                    ->assertSee('Assessment period updated successfully.');
            });
            $record->refresh();
            $this->assertSame($updated, (string) $record->name);
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P15 · BC-BIZ-05 · Source: edit.blade prefills existing values */
    public function test_assessment_period_15_edit_page_prefills_existing_values(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Prefill ' . $this->uniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('input[name="name"]', 12)
                    ->assertInputValue('input[name="name"]', (string) $record->name)
                    ->assertPresent('select[name="status"]');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  20–29  STATE-MACHINE (FSM)  ── the core of this feature
    // ══════════════════════════════════════════════

    /** TC-SM-tog · BC-SM-07 · Source: Controller@toggleStatus JSON payload */
    public function test_assessment_period_20_toggle_status_endpoint_returns_json_and_flips(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Toggle ' . $this->uniqueSuffix(), 'is_active' => true]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::PERIODS_TAB, 900);
                $response = $this->postJsonFromBrowser($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/toggle-status');
                $this->assertStringContainsString('"success"', $response, 'toggle-status must return a success key.');
                $this->assertStringContainsString('Assessment period deactivated.', $response, 'toggle-status must return the deactivation message.');
            });
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'toggle-status should flip is_active to false.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM-01 · BC-SM-01 (LEGAL) · Source: Controller@lock — open → locked */
    public function test_assessment_period_21_lock_open_period_transitions_to_locked(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 LockOpen ' . $this->uniqueSuffix(), 'status' => 'open']);
        try {
            $this->driveEndpoint(self::SHOW_BASE_PATH . '/' . $record->id . '/lock');
            $record->refresh();
            $this->assertSame('locked', (string) $record->status, 'open → locked must succeed via lock().');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM-02 · BC-SM-02 (LEGAL, mislabeled) · Source: Controller@unlock — locked → closed */
    public function test_assessment_period_22_unlock_locked_period_transitions_to_closed(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Unlock ' . $this->uniqueSuffix(), 'status' => 'locked']);
        try {
            $this->driveEndpoint(self::SHOW_BASE_PATH . '/' . $record->id . '/unlock');
            $record->refresh();
            $this->assertSame('closed', (string) $record->status, 'unlock() maps locked → closed (does NOT return to open).');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM-04 · BC-SM-04 (GUARD) · Source: Controller@lock "Period is already locked." */
    public function test_assessment_period_23_lock_already_locked_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 ReLock ' . $this->uniqueSuffix(), 'status' => 'locked']);
        try {
            $this->driveEndpoint(self::SHOW_BASE_PATH . '/' . $record->id . '/lock');
            $record->refresh();
            $this->assertSame('locked', (string) $record->status, 'Locking an already-locked period should be a no-op guard.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-SM-05 · BC-SM-05 (GUARD) · Source: Controller@unlock "Period is not locked." */
    public function test_assessment_period_24_unlock_non_locked_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 UnlockOpen ' . $this->uniqueSuffix(), 'status' => 'open']);
        try {
            $this->driveEndpoint(self::SHOW_BASE_PATH . '/' . $record->id . '/unlock');
            $record->refresh();
            $this->assertSame('open', (string) $record->status, 'Unlocking a non-locked period must be rejected (stays open).');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-N20 · BC-SM-03 · Audit-BUG-BA-002 (verify in source).
     * FRD FSM-2 makes 'locked' terminal and forbids re-locking a closed period. But lock() only blocks
     * when status === 'locked', so a CLOSED period can be locked again (closed → locked). Proven here.
     * Source: BaAssessmentPeriodController@lock:147-161 (guard only checks 'locked').
     */
    public function test_assessment_period_25_closed_period_can_be_relocked_bug_ba_002(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 ClosedRelock ' . $this->uniqueSuffix(), 'status' => 'closed']);
        try {
            $this->driveEndpoint(self::SHOW_BASE_PATH . '/' . $record->id . '/lock');
            $record->refresh();
            $this->assertSame('locked', (string) $record->status,
                'BUG-BA-002 confirmed: a closed period can be re-locked (closed → locked is not blocked).');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-N21 · BC-SM-08 · Audit-BUG-BA-002 (verify in source).
     * There is NO close() action/route, and unlock() only fires from 'locked'. From an OPEN period,
     * unlock() is rejected ("Period is not locked.") and lock() jumps straight to 'locked'. So a direct
     * open → closed transition is UNREACHABLE through any lifecycle action. Proven here.
     * Source: routes/web.php (no assessment-periods/{id}/close); Controller@unlock:163-177.
     */
    public function test_assessment_period_26_open_to_closed_unreachable_via_lifecycle_actions_bug_ba_002(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 NoClose ' . $this->uniqueSuffix(), 'status' => 'open']);
        try {
            // Attempting to "unlock" an open period is the only close-like action — it is rejected.
            $this->driveEndpoint(self::SHOW_BASE_PATH . '/' . $record->id . '/unlock');
            $record->refresh();
            $this->assertNotSame('closed', (string) $record->status,
                'BUG-BA-002 confirmed: no lifecycle action moves open → closed (locked jumps skip closed).');
            $this->assertSame('open', (string) $record->status, 'Open period remains open — no close() action exists.');

            // Corroborate at the source layer: no close route/method is registered.
            $routes = File::get(base_path('Modules/BehaviouralAssessment/routes/web.php'));
            $this->assertStringNotContainsString("assessment-periods/{period}/close", $routes,
                'No open→closed close() route should exist (BUG-BA-002).');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-N22 · BC-SM-06 · Audit-BUG-BA-002 (verify in source).
     * The edit form exposes a free status <select> and update() writes it with NO FSM validation, a
     * back-door around lock()/unlock(). Here a CLOSED period is reopened to 'open' straight from the
     * edit form — an illegal transition the FSM should forbid.
     * Source: assessment-period/edit.blade status <select>; Controller@update:64-73 (no guard).
     */
    public function test_assessment_period_27_edit_form_allows_illegal_status_transition_bug_ba_002(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Backdoor ' . $this->uniqueSuffix(), 'status' => 'closed']);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('select[name="status"]', 12)
                    ->select('status', 'open')
                    ->press('Update Assessment Period')->pause(2200);
            });
            $record->refresh();
            $this->assertSame('open', (string) $record->status,
                'BUG-BA-002 confirmed: edit form back-door allows closed → open with no FSM guard.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-N23 · BC-SM-06 · Audit-BUG-BA-002 (verify in source).
     * Reaching 'closed' from 'open' is ONLY possible through the uncontrolled edit-form back-door,
     * never through a lifecycle action. Here an OPEN period is set to 'closed' via the edit form,
     * confirming both the back-door and the missing lifecycle path.
     * Source: edit.blade status <select>; Controller@update (no FSM guard).
     */
    public function test_assessment_period_28_open_to_closed_only_via_edit_backdoor_bug_ba_002(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 OpenToClosed ' . $this->uniqueSuffix(), 'status' => 'open']);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('select[name="status"]', 12)
                    ->select('status', 'closed')
                    ->press('Update Assessment Period')->pause(2200);
            });
            $record->refresh();
            $this->assertSame('closed', (string) $record->status,
                'BUG-BA-002 confirmed: open → closed happens only via the edit back-door, never a lifecycle action.');
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-N24 · BC-SM-10 · Audit-BUG-BA-001 (verify in source).
     * Locking a PERIOD only sets period.status='locked'. It does NOT cascade to freeze the period's
     * assessments/ratings (no assessment status change, no read-only flag). Proven by source scan of
     * lock(): it updates only the period status and never references assessments.
     * Source: BaAssessmentPeriodController@lock:147-161.
     */
    public function test_assessment_period_29_lock_does_not_cascade_freeze_to_assessments_bug_ba_001(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $lockStart = strpos($controller, 'public function lock(');
        $unlockStart = strpos($controller, 'public function unlock(');
        $this->assertNotFalse($lockStart, 'lock() method not found.');
        $this->assertNotFalse($unlockStart, 'unlock() method not found.');

        $lockBody = substr($controller, (int) $lockStart, (int) $unlockStart - (int) $lockStart);
        $this->assertStringContainsString("'status' => 'locked'", $lockBody, 'lock() should set the period status to locked.');
        $this->assertStringNotContainsString('assessments', $lockBody,
            'BUG-BA-001 confirmed: lock() does NOT cascade to freeze assessments/ratings.');
        $this->assertStringNotContainsString('ratings', $lockBody,
            'BUG-BA-001 confirmed: lock() never touches ratings.');
    }

    // ══════════════════════════════════════════════
    //  30–39  Validation (negative matrix)
    // ══════════════════════════════════════════════

    /** TC-N30 · BC-VAL-01 · Source: required rules */
    public function test_assessment_period_30_required_fields_block_insert(): void
    {
        $this->resolveDependenciesOrSkip();
        $before = BaAssessmentPeriod::query()->count();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->script("(function(){document.querySelectorAll('[required]').forEach(function(i){i.removeAttribute('required');}); document.querySelector('form').submit();})();");
            $browser->pause(2000)->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaAssessmentPeriod::query()->count(), 'Empty submission must not create a row.');
    }

    /** TC-N31 · BC-VAL-03 · Source: end_date after_or_equal:start_date */
    public function test_assessment_period_31_end_date_before_start_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V2 EndBeforeStart ' . $this->uniqueSuffix();
        $before = BaAssessmentPeriod::query()->count();
        try {
            $this->submitPeriodForm($dependencies, $name, now()->format('Y-m-d'), now()->subDays(3)->format('Y-m-d'), now()->addDays(10)->format('Y-m-d'));
            $this->assertSame($before, BaAssessmentPeriod::query()->count(), 'end_date before start_date must be rejected.');
        } finally {
            BaAssessmentPeriod::query()->where('name', $name)->forceDelete();
        }
    }

    /** TC-N32 · BC-VAL-04 · Source: deadline gte:end_date */
    public function test_assessment_period_32_deadline_before_end_date_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V2 DeadlineEarly ' . $this->uniqueSuffix();
        $before = BaAssessmentPeriod::query()->count();
        try {
            $this->submitPeriodForm($dependencies, $name, now()->format('Y-m-d'), now()->addMonth()->format('Y-m-d'), now()->addDays(5)->format('Y-m-d'));
            $this->assertSame($before, BaAssessmentPeriod::query()->count(), 'deadline before end_date must be rejected (gte).');
        } finally {
            BaAssessmentPeriod::query()->where('name', $name)->forceDelete();
        }
    }

    /** TC-N33 · BC-VAL-02 · Source: name max:100 */
    public function test_assessment_period_33_name_exceeding_max_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $longName = str_repeat('N', 130);
        $before = BaAssessmentPeriod::query()->count();
        $this->browse(function (Browser $browser) use ($dependencies, $longName): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->script("document.querySelector('input[name=\"name\"]').removeAttribute('maxlength');")
                ->type('input[name="name"]', $longName)
                ->select('academic_session_id', (string) $dependencies['academic_session_id'])
                ->type('input[name="start_date"]', now()->format('Y-m-d'))
                ->type('input[name="end_date"]', now()->addMonth()->format('Y-m-d'))
                ->type('input[name="deadline"]', now()->addDays(40)->format('Y-m-d'))
                ->press('Save Assessment Period')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaAssessmentPeriod::query()->count(), 'Over-length name must be rejected.');
    }

    /** TC-N34 · BC-VAL-05 · Source: academic_session_id exists:sch_org_academic_sessions_jnt,id */
    public function test_assessment_period_34_invalid_academic_session_is_rejected(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V2 BadSession ' . $this->uniqueSuffix();
        $before = BaAssessmentPeriod::query()->count();
        $this->browse(function (Browser $browser) use ($name): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            // Inject a non-existent session option to post an id that fails the exists rule.
            $browser->waitFor('select[name="academic_session_id"]', 12)
                ->script("(function(){var s=document.querySelector('select[name=\"academic_session_id\"]');var o=document.createElement('option');o.value='987654';o.text='ghost';s.appendChild(o);s.value='987654';})();");
            $browser->type('input[name="name"]', $name)
                ->type('input[name="start_date"]', now()->format('Y-m-d'))
                ->type('input[name="end_date"]', now()->addMonth()->format('Y-m-d'))
                ->type('input[name="deadline"]', now()->addDays(40)->format('Y-m-d'))
                ->press('Save Assessment Period')->pause(2000)
                ->assertPresent('.alert-danger');
        });
        $this->assertSame($before, BaAssessmentPeriod::query()->count(), 'Non-existent academic session must be rejected.');
    }

    // ══════════════════════════════════════════════
    //  40–49  Integration / FK / dependency
    // ══════════════════════════════════════════════

    /**
     * TC-D02 (C) · BC-INT-01 · Source: Controller@destroy reference guard (RESTRICT-like).
     * destroy() blocks deletion when the period has assessments or computed scores. Verified here by
     * creating a real assessment against the period, then confirming the model's guard predicate is true.
     * Defensive: skips if cross-module Employee/ClassSection FK targets are absent.
     */
    public function test_assessment_period_40_destroy_is_blocked_when_assessments_exist(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 DestroyGuard ' . $this->uniqueSuffix()]);
        $assessment = $this->createAssessmentOrSkip($dependencies, $record);
        try {
            $this->assertTrue($record->assessments()->exists(),
                'Period should report existing assessments (destroy() guard predicate).');
            // Controller destroy() would return the block flash; the guard predicate is what we assert.
        } finally {
            if ($assessment instanceof BaAssessment) {
                try { $assessment->forceDelete(); } catch (Throwable) {}
            }
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /**
     * TC-N25 · BC-SM-10 · Audit-BUG-BA-001 (verify in source, data layer).
     * With the PERIOD locked, its assessments are NOT frozen — a submitted assessment against a locked
     * period is still writable. Proven by creating an assessment under a locked period and mutating it.
     * Defensive: skips when cross-module Employee/ClassSection rows are unavailable.
     * Source: lock() sets period.status only; no cascade to ba_assessments.status.
     */
    public function test_assessment_period_41_locked_period_assessment_still_writable_bug_ba_001(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 LockFreeze ' . $this->uniqueSuffix(), 'status' => 'locked']);
        $assessment = $this->createAssessmentOrSkip($dependencies, $record, ['status' => 'submitted']);
        try {
            $this->assertNotNull($assessment->id, 'Assessment saved against a locked period (no freeze).');
            // Mutate the assessment while its period is locked → still succeeds (BUG-BA-001).
            $assessment->reviewer_remarks = 'Edited while period locked ' . $this->uniqueSuffix();
            $assessment->save();
            $assessment->refresh();
            $this->assertStringContainsString('Edited while period locked', (string) $assessment->reviewer_remarks,
                'BUG-BA-001 confirmed: assessments remain editable while their period is locked.');
        } finally {
            if ($assessment instanceof BaAssessment) {
                try { $assessment->forceDelete(); } catch (Throwable) {}
            }
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D03 (E) · BC-REF-03 · Source: BaAssessmentPeriod::academicSession() belongsTo */
    public function test_assessment_period_42_belongs_to_academic_session(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Belongs ' . $this->uniqueSuffix()]);
        try {
            $record->refresh();
            $this->assertSame((int) $dependencies['academic_session_id'], (int) $record->academic_session_id,
                'Period should reference its academic session.');
            try {
                $this->assertNotNull($record->academicSession, 'academicSession() should resolve the parent session.');
            } catch (Throwable) {
                $this->markTestSkipped('Academic session model/table unavailable in this environment.');
            }
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-D04 (B) · BC-SM-05 · Source: restore + forceDelete guard */
    public function test_assessment_period_43_restore_and_force_delete_when_unreferenced(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 RestoreForce ' . $this->uniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $record->delete();
            $this->assertNull(BaAssessmentPeriod::find($id));
            $record->restore();
            $this->assertNotNull(BaAssessmentPeriod::find($id));
            $record->forceDelete();
            $this->assertNull(BaAssessmentPeriod::withTrashed()->find($id), 'Unreferenced period force-deletes cleanly.');
        } finally {
            $this->forceDeleteRecordByIdIfExists($id);
        }
    }

    // ══════════════════════════════════════════════
    //  50–59  Permissions / authorization
    // ══════════════════════════════════════════════

    /** TC-S01 · BC-AUTH-01 · Source: auth middleware on web routes */
    public function test_assessment_period_50_guest_redirected_to_login_on_create(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** TC-S02 · BC-AUTH-01 · Source: setup route behind auth */
    public function test_assessment_period_51_guest_redirected_to_login_on_setup(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::SETUP_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /**
     * TC-S03 · BC-AUTH-03 · Audit-SEC-BA-002 (verify in source).
     * BaAssessmentPeriodRequest::authorize() returns a bare `true`, so the FormRequest does not gate.
     * Access control depends entirely on the controller Gate::authorize() calls. Documents the gap.
     * Source: BaAssessmentPeriodRequest.php:11-14.
     */
    public function test_assessment_period_52_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = new BaAssessmentPeriodRequest();
        $this->assertTrue($request->authorize(),
            'SEC-BA-002 confirmed: FormRequest authorize() returns bare true (auth deferred to controller gates).');

        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.assessment-periods.create')", $controller);
        $this->assertStringContainsString("Gate::authorize('tenant.behavioural-assessment.assessment-periods.lock')", $controller);
    }

    /** TC-S04 · BC-AUTH-04 · Source: Controller@create Gate::authorize (limited user → blocked) */
    public function test_assessment_period_53_user_without_permission_is_forbidden(): void
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
            $stillHasForm = str_contains($source, 'save assessment period');

            $this->assertTrue($forbidden || ! $stillHasForm,
                'A user lacking assessment-periods.create should be blocked from the create screen.');
        });
    }

    // ══════════════════════════════════════════════
    //  60–69  UI / UX (list, filter, trash, locked-edit)
    // ══════════════════════════════════════════════

    /** TC-P20 · BC-BIZ-06 · Source: setup _periods partial */
    public function test_assessment_period_60_setup_periods_tab_lists_created_period(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Listed ' . $this->uniqueSuffix()]);
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

    /** TC-P21 · BC-BIZ-07 · Source: _periods status filter select */
    public function test_assessment_period_61_setup_periods_status_filter(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 StatusFilter ' . $this->uniqueSuffix(), 'status' => 'open']);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::PERIODS_TAB . '&status=open&search=' . urlencode((string) $record->name), 1000);
                $browser->assertSee((string) $record->name)->assertSee('Open');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P22 · BC-BIZ-08 · Source: trash.blade "Status at Deletion" / "Deleted At" */
    public function test_assessment_period_62_trash_page_lists_soft_deleted_period(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 Trash ' . $this->uniqueSuffix()]);
        $record->delete();
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TRASH_PATH, 900);
                $browser->waitForText('Deleted At', 12)
                    ->assertSee('Status at Deletion')
                    ->assertSee((string) $record->name);
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-P23 · BC-BIZ-09 · Source: edit.blade locked banner + hidden Update button */
    public function test_assessment_period_63_locked_period_edit_form_hides_update_button(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $record = $this->createRecordDirectly($dependencies, ['name' => 'V2 LockedEdit ' . $this->uniqueSuffix(), 'status' => 'locked']);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('input[name="name"]', 12)
                    ->assertSee('This period is locked.')
                    ->assertDontSee('Update Assessment Period');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    // ══════════════════════════════════════════════
    //  70–79  Edge cases
    // ══════════════════════════════════════════════

    /** TC-D08 (G) · BC-EDG-01 · Source: after_or_equal / gte allow equality */
    public function test_assessment_period_70_equal_start_end_deadline_dates_are_accepted(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $name = 'V2 EqualDates ' . $this->uniqueSuffix();
        $day = now()->format('Y-m-d');
        $saved = null;
        try {
            $this->browse(function (Browser $browser) use ($dependencies, $name, $day): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
                $this->suppressBrowserAlertDialogs($browser);
                $browser->waitFor('input[name="name"]', 12)
                    ->type('input[name="name"]', $name)
                    ->select('academic_session_id', (string) $dependencies['academic_session_id'])
                    ->type('input[name="start_date"]', $day)
                    ->type('input[name="end_date"]', $day)
                    ->type('input[name="deadline"]', $day)
                    ->press('Save Assessment Period')->pause(2400);
            });
            $saved = BaAssessmentPeriod::query()->where('name', $name)->first();
            $this->assertNotNull($saved, 'Equal start=end=deadline should be accepted (after_or_equal / gte).');
        } finally {
            $this->cleanupByName($name);
        }
    }

    /**
     * TC-N26 · BC-EDG-02 · VAL-BA-AP-01 (new candidate, verify in source).
     * The screen's "Chronological Non-Overlapping Rule" (no two active periods in the same session may
     * overlap) is NOT enforced anywhere in the controller/FormRequest. Two overlapping periods in the
     * same session both persist. Proven here.
     * Source: BaAssessmentPeriodController@store (no overlap check); BaAssessmentPeriodRequest (no rule).
     */
    public function test_assessment_period_71_overlapping_periods_in_same_session_are_allowed_val_ba_ap_01(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $a = null;
        $b = null;
        try {
            $a = $this->createRecordDirectly($dependencies, [
                'name' => 'V2 OverlapA ' . $this->uniqueSuffix(),
                'start_date' => now()->format('Y-m-d'),
                'end_date' => now()->addMonth()->format('Y-m-d'),
                'deadline' => now()->addDays(40)->format('Y-m-d'),
            ]);
            $b = $this->createRecordDirectly($dependencies, [
                'name' => 'V2 OverlapB ' . $this->uniqueSuffix(),
                'start_date' => now()->addDays(10)->format('Y-m-d'),  // overlaps A
                'end_date' => now()->addDays(50)->format('Y-m-d'),
                'deadline' => now()->addDays(55)->format('Y-m-d'),
            ]);
            $this->assertNotNull($a->id);
            $this->assertNotNull($b->id,
                'VAL-BA-AP-01: overlapping periods in the same session both persist (non-overlap rule not enforced).');
        } finally {
            foreach ([$a, $b] as $rec) {
                if ($rec instanceof BaAssessmentPeriod) {
                    $this->forceDeleteRecordByIdIfExists((int) $rec->id);
                }
            }
        }
    }

    // ══════════════════════════════════════════════
    //  90–99  Tenancy + security
    // ══════════════════════════════════════════════

    /** TC-T01 · BC-CFG-01 · Source: tenant-per-DB (no tenant_id column) */
    public function test_assessment_period_90_runs_inside_initialized_tenant(): void
    {
        if (!function_exists('tenancy')) {
            $this->markTestSkipped('Tenancy helper unavailable.');
        }
        $this->assertTrue(tenancy()->initialized, 'AssessmentPeriod is tenant-scoped and requires an initialized tenant.');
        $this->assertTrue(Schema::hasTable(self::TABLE), 'ba_assessment_periods must resolve within the tenant DB.');
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'tenant_id'),
            'Tenant-per-database design → no tenant_id column on ba_assessment_periods.');
    }

    /** TC-S05 · BC-EDG-03 · Source: Blade `{{ }}` auto-escaping on the period name */
    public function test_assessment_period_91_stored_xss_in_name_is_escaped(): void
    {
        $dependencies = $this->resolveDependenciesOrSkip();
        $marker = 'xss' . $this->uniqueSuffix();
        $payload = '<script>window.' . $marker . '=1</script>';
        $record = $this->createRecordDirectly($dependencies, ['name' => $payload]);
        try {
            $this->browse(function (Browser $browser) use ($record, $marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 900);
                $browser->waitFor('input[name="name"]', 12);
                $executed = $browser->script('return window.' . $marker . ' === 1;')[0] ?? false;
                $this->assertNotTrue($executed, 'Stored script in the period name must not execute (Blade escaping).');
            });
        } finally {
            $this->forceDeleteRecordByIdIfExists((int) $record->id);
        }
    }

    /** TC-S06 · BC-AUTH-05 · Source: Controller@edit findOrFail → 404 */
    public function test_assessment_period_92_invalid_id_does_not_render_edit(): void
    {
        $this->resolveDependenciesOrSkip();
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl(self::SHOW_BASE_PATH . '/98765432/edit'))->pause(1200);
            $browser->assertDontSee('Update Assessment Period');
        });
    }

    // ══════════════════════════════════════════════
    //  Helpers
    // ══════════════════════════════════════════════

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
            'name' => 'Assessment Period ' . $this->uniqueSuffix(),
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->addMonth()->format('Y-m-d'),
            'deadline' => now()->addDays(40)->format('Y-m-d'),
            'status' => 'open',
            'is_active' => true,
            'created_by' => (int) $dependencies['admin_user_id'],
            'updated_by' => (int) $dependencies['admin_user_id'],
        ];
    }

    /** Creates a real assessment against a period; skips when cross-module FK targets are unavailable. */
    private function createAssessmentOrSkip(array $dependencies, BaAssessmentPeriod $period, array $overrides = []): BaAssessment
    {
        try {
            $teacherId = (int) DB::table('sch_employees')->min('id');
            $classSectionId = (int) DB::table('sch_class_section_jnt')->min('id');
            if ($teacherId <= 0 || $classSectionId <= 0) {
                $this->markTestSkipped('No sch_employees / sch_class_section_jnt rows to satisfy ba_assessments FKs.');
            }

            return BaAssessment::query()->create(array_merge([
                'period_id' => (int) $period->id,
                'teacher_id' => $teacherId,
                'class_section_id' => $classSectionId,
                'status' => 'draft',
                'is_active' => true,
                'created_by' => (int) $dependencies['admin_user_id'],
                'updated_by' => (int) $dependencies['admin_user_id'],
            ], $overrides));
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not provision a cross-module assessment: ' . $e->getMessage());
        }
    }

    private function forceDeleteRecordByIdIfExists(int $recordId): void
    {
        BaAssessmentPeriod::withTrashed()->where('id', $recordId)->get()
            ->each(function (BaAssessmentPeriod $record): void {
                try {
                    $record->assessments()->forceDelete();
                    $record->forceDelete();
                } catch (Throwable) {
                    // ignore FK / soft-delete cleanup issues
                }
            });
    }

    private function cleanupByName(string $name): void
    {
        BaAssessmentPeriod::withTrashed()->where('name', $name)->get()
            ->each(function (BaAssessmentPeriod $record): void {
                $this->forceDeleteRecordByIdIfExists((int) $record->id);
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

    private function browserCreatePeriod(array $dependencies, string $name): void
    {
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
    }

    private function submitPeriodForm(array $dependencies, string $name, string $start, string $end, string $deadline): void
    {
        $this->browse(function (Browser $browser) use ($dependencies, $name, $start, $end, $deadline): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 900);
            $this->suppressBrowserAlertDialogs($browser);
            $browser->waitFor('input[name="name"]', 12)
                ->type('input[name="name"]', $name)
                ->select('academic_session_id', (string) $dependencies['academic_session_id'])
                ->type('input[name="start_date"]', $start)
                ->type('input[name="end_date"]', $end)
                ->type('input[name="deadline"]', $deadline)
                ->press('Save Assessment Period')
                ->pause(2000)
                ->assertPresent('.alert-danger');
        });
    }

    /** Drives a POST lifecycle endpoint (lock/unlock) via an authenticated fetch from the browser. */
    private function driveEndpoint(string $path): void
    {
        $this->browse(function (Browser $browser) use ($path): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::PERIODS_TAB, 900);
            $this->postFormFromBrowser($browser, $path);
            $browser->pause(1200);
        });
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
                'name'              => 'Limited AP ' . $suffix,
                'email'             => 'limited_ap_' . $suffix . '@tenant.test',
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
}
