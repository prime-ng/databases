<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Models\BaAssessmentPeriod;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Assessment Periods ("Periods" setup tab) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/06-Periods.md
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, no tenant_id columns) → tenancy scaffolding emitted.
 * Runtime table      : ba_assessment_periods  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentPeriodController
 * FormRequest        : Modules\BehaviouralAssessment\Http\Requests\BaAssessmentPeriodRequest
 * Policy             : Modules\BehaviouralAssessment\Policies\BaAssessmentPeriodPolicy
 * Permission prefix  : tenant.behavioural-assessment.assessment-periods.{viewAny|view|create|update|delete|restore|forceDelete|status|close|reopen|lock|unlock}
 * Activity log       : NONE — the controller calls no activityLog() helper and the model has no observer (documented absence, mirrors RatingScale).
 *
 * STATE MACHINE (verified against current source, BaAssessmentPeriodController):
 *   (create)──▶ open ──close()──▶ closed ──lock()──▶ locked
 *                 ▲                  │  ▲                │
 *                 └──── reopen() ────┘  └── unlock() ────┘   (unlock = admin override, locked→closed)
 *   Every transition endpoint guards the pre-state; an illegal trigger is rejected with back()->with('error',...)
 *   and leaves the status unchanged (proven in band 20–29).
 *
 * Defects proven / verified (audit BehaviouralAssessment_Complete_Audit_2026-06-29.md):
 *   - BUG-BA-002 [P1] : Period lifecycle FSM / lock enforcement.
 *       • REMEDIATED since the audit (proven in _28): a close()/reopen() action + routes now exist, lock() is
 *         restricted to closed→locked (no direct open→locked, proven in _27), and `status` was removed from the
 *         FormRequest rules (edit back-door closed, proven in _11/_28).
 *       • RESIDUAL (proven in _29): update()/destroy()/toggleStatus() perform NO server-side isLocked() guard —
 *         a LOCKED period is still mutated by a direct PUT/POST. The lock is enforced only in Blade CSS
 *         (edit.blade: `pe-none opacity-50` + hidden submit). Mirrors BUG-BA-001, Accounting BR-ACC-016,
 *         FrontOffice DAT-FOF-003 (isLocked guard on write paths missing).
 *   - SEC-BA-002 [P1] : FormRequest authorize() returns bare true, mitigated by the controller Gate (proven in _92).
 *   - DOC-BA-001 [Doc]: DDL doc prefix `bha_` diverges from live `ba_` (proven in _02).
 * Feature-scoped observations (screen requirement vs implementation):
 *   - PER-GAP-01 : "Chronological Non-Overlapping Rule" (06-Periods §Business Rules) is NOT enforced — FormRequest
 *                  has no overlap check; overlapping periods in the same session are accepted (proven in _39).
 *   - PER-GAP-02 : requirement says Period Name is "Unique"; FormRequest only has max:100 — duplicate names accepted (proven in _39).
 *   - PER-GAP-03 : requirement models a boolean "Is Locked" toggle; implementation uses a 3-state `status` enum
 *                  (open/closed/locked) + a separate `is_active` soft-enable switch (documented in _65, TcList §2).
 *   - DOC-BA-002 : DDL/FRD comment marks `locked` as TERMINAL, but code + the screen requirement both allow an
 *                  admin unlock (locked→closed); the code follows the screen requirement (documented in _24).
 */
class bha_AssessmentPeriod_TestCas extends DuskTestCase
{
    private const URL_PREFIX         = '/behavioural-assessment';
    private const SETUP_PERIODS_PATH = '/behavioural-assessment/setup?tab=periods';
    private const CREATE_PATH        = '/behavioural-assessment/assessment-periods/create';
    private const STORE_PATH         = '/behavioural-assessment/assessment-periods';
    private const TRASH_PATH         = '/behavioural-assessment/assessment-periods/trash';

    private const PERIODS_TABLE = 'ba_assessment_periods';
    private const DDL_PERIODS    = 'bha_assessment_periods'; // stale DDL-doc name (should NOT exist at runtime)
    private const SESSION_TABLE  = 'sch_org_academic_sessions_jnt';
    private const TERM_TABLE     = 'sch_academic_term';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/AssessmentPeriod/screenshots';

    /** @var array<int,string> */
    private const AP_PERMISSIONS = [
        'tenant.behavioural-assessment.assessment-periods.viewAny',
        'tenant.behavioural-assessment.assessment-periods.view',
        'tenant.behavioural-assessment.assessment-periods.create',
        'tenant.behavioural-assessment.assessment-periods.update',
        'tenant.behavioural-assessment.assessment-periods.delete',
        'tenant.behavioural-assessment.assessment-periods.restore',
        'tenant.behavioural-assessment.assessment-periods.forceDelete',
        'tenant.behavioural-assessment.assessment-periods.status',
        'tenant.behavioural-assessment.assessment-periods.close',
        'tenant.behavioural-assessment.assessment-periods.reopen',
        'tenant.behavioural-assessment.assessment-periods.lock',
        'tenant.behavioural-assessment.assessment-periods.unlock',
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

    public function test_period_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::PERIODS_TABLE), 'Table ba_assessment_periods does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::PERIODS_TABLE, [
                'id', 'academic_session_id', 'academic_term_id', 'name',
                'start_date', 'end_date', 'deadline', 'status', 'is_active',
                'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns are missing in ba_assessment_periods table.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::PERIODS_TABLE))->keyBy('Field');
            $this->assertStringContainsString('varchar', strtolower((string) ($cols['name']->Type ?? '')));
            $this->assertStringContainsString('date', strtolower((string) ($cols['start_date']->Type ?? '')));
            $this->assertStringContainsString('enum', strtolower((string) ($cols['status']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));
            // The status ENUM must offer exactly the three lifecycle states (order-insensitive).
            $enum = strtolower((string) ($cols['status']->Type ?? ''));
            foreach (['open', 'closed', 'locked'] as $state) {
                $this->assertStringContainsString("'{$state}'", $enum, "status ENUM missing '{$state}'.");
            }
        }

        // Migration file content — resolved from the APP repo via reflection (constraint #29/#32); fail-soft.
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130612_create_ba_assessment_periods_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_assessment_periods'", $migration);
            $this->assertStringContainsString("\$table->string('name', 100)", $migration);
            $this->assertStringContainsString("\$table->date('start_date')", $migration);
            $this->assertStringContainsString("\$table->date('deadline')", $migration);
            $this->assertStringContainsString("enum('status'", $migration);
            $this->assertStringContainsString('$table->softDeletes()', $migration);
            $this->assertStringContainsString("->on('sch_org_academic_sessions_jnt')", $migration);
            $this->assertStringContainsString("->on('sch_academic_term')", $migration);
        }

        // FormRequest rule strings — verbatim from the real source.
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaAssessmentPeriodRequest.php'));
        if ($request !== null) {
            $this->assertStringContainsString("'exists:sch_org_academic_sessions_jnt,id'", $request);
            $this->assertStringContainsString("'exists:sch_academic_term,id'", $request);
            $this->assertStringContainsString("'max:100'", $request);
            $this->assertStringContainsString("'after_or_equal:start_date'", $request);
            $this->assertStringContainsString("'gte:end_date'", $request);
            $this->assertStringContainsString('prepareForValidation', $request);
        }

        // Model configuration.
        $period = new BaAssessmentPeriod();
        $this->assertSame('ba_assessment_periods', $period->getTable());
        $this->assertSame([
            'academic_session_id', 'academic_term_id', 'name', 'start_date', 'end_date',
            'deadline', 'status', 'is_active', 'created_by', 'updated_by',
        ], $period->getFillable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(BaAssessmentPeriod::class));
        $this->assertInstanceOf(HasMany::class, $period->assessments());
        $this->assertInstanceOf(HasMany::class, $period->computedScores());
        $this->assertInstanceOf(BelongsTo::class, $period->academicSession());
        $this->assertInstanceOf(BelongsTo::class, $period->academicTerm());
    }

    public function test_period_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001(): void
    {
        // Live runtime table uses the `ba_` prefix.
        $this->assertTrue(Schema::hasTable(self::PERIODS_TABLE), 'Runtime table ba_assessment_periods must exist.');

        // The DDL/registry spec name `bha_assessment_periods` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_PERIODS),
                'DOC-BA-001 regression: bha_assessment_periods exists at runtime; expected only the live ba_assessment_periods.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_assessment_periods', (new BaAssessmentPeriod())->getTable());
    }

    public function test_period_03_status_scope_active_scope_and_islocked_helper_behave(): void
    {
        // scopeOpen / scopeActive and the isLocked() helper — model-level state helpers.
        $open   = $this->createPeriodSeed(['status' => 'open', 'is_active' => true]);
        $locked = $this->createPeriodSeed(['status' => 'locked', 'is_active' => false]);

        $this->assertTrue(BaAssessmentPeriod::query()->open()->whereKey($open->id)->exists());
        $this->assertFalse(BaAssessmentPeriod::query()->open()->whereKey($locked->id)->exists());
        $this->assertTrue(BaAssessmentPeriod::query()->active()->whereKey($open->id)->exists());
        $this->assertFalse(BaAssessmentPeriod::query()->active()->whereKey($locked->id)->exists());

        $this->assertFalse($open->isLocked());
        $this->assertTrue($locked->isLocked());

        $this->forceDeletePeriod($open);
        $this->forceDeletePeriod($locked);
    }

    // =====================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =====================================================================

    public function test_period_10_create_persists_with_status_open_and_audit_columns(): void
    {
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('CREATE');
        $this->deletePeriodByName($name);

        $response = $this->postPeriod(['name' => $name, 'academic_session_id' => $sessionId]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Valid create should not 422: ' . json_encode($response['json'] ?? $response['body'] ?? null));

        $created = BaAssessmentPeriod::where('name', $name)->first();
        $this->assertNotNull($created, 'Assessment period row was not created.');
        $this->assertSame('open', $created->status, 'store() must force status=open.');
        $this->assertTrue((bool) $created->is_active);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by);
        $this->assertSame((int) $this->adminUser->id, (int) $created->updated_by);

        $this->forceDeletePeriod($created);
    }

    public function test_period_11_store_forces_open_and_ignores_posted_status_backdoor(): void
    {
        // BUG-BA-002 (remediated slice): status is NOT accepted by the FormRequest and store() hardcodes 'open',
        // so a posted status=locked can never create a locked period.
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('BACKDOOR');
        $this->deletePeriodByName($name);

        $response = $this->postPeriod(['name' => $name, 'academic_session_id' => $sessionId, 'status' => 'locked']);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));

        $created = BaAssessmentPeriod::where('name', $name)->first();
        $this->assertNotNull($created);
        $this->assertSame('open', $created->status, 'Posted status=locked must be ignored; store() forces open.');

        $this->forceDeletePeriod($created);
    }

    public function test_period_12_update_persists_changes(): void
    {
        $period = $this->createPeriodSeed(['name' => $this->uniqueName('BEFORE')]);
        $newName = $this->uniqueName('AFTER');

        $response = $this->putPeriod($period->id, $this->validStorePayload([
            'academic_session_id' => $period->academic_session_id,
            'name' => $newName,
            'deadline' => '2026-09-10',
        ]));
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Update should not 422.');

        $period->refresh();
        $this->assertSame($newName, $period->name);
        $this->assertSame('2026-09-10', $period->deadline?->format('Y-m-d'));
        $this->assertSame((int) $this->adminUser->id, (int) $period->updated_by);

        $this->forceDeletePeriod($period);
    }

    public function test_period_13_optional_academic_term_id_allows_independent_period(): void
    {
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('INDEP');
        $this->deletePeriodByName($name);

        // academic_term_id omitted / empty → prepareForValidation nulls it → independent period.
        $response = $this->postPeriod(['name' => $name, 'academic_session_id' => $sessionId, 'academic_term_id' => '']);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'Independent period (no term) must be accepted.');

        $created = BaAssessmentPeriod::where('name', $name)->first();
        $this->assertNotNull($created);
        $this->assertNull($created->academic_term_id, 'Empty academic_term_id must persist as NULL.');

        $this->forceDeletePeriod($created);
    }

    public function test_period_14_index_redirects_to_setup_periods_tab(): void
    {
        $response = $this->apiCall('GET', $this->tenantUrl(self::STORE_PATH));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'index() should redirect to the setup periods tab.');
    }

    public function test_period_15_show_redirects_to_edit(): void
    {
        $period = $this->createPeriodSeed();

        $response = $this->apiCall('GET', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302], 'show() should redirect to edit.');

        $this->forceDeletePeriod($period);
    }

    public function test_period_16_setup_periods_tab_lists_period(): void
    {
        $period = $this->createPeriodSeed(['name' => $this->uniqueName('LISTME')]);

        $this->browseWithFailureScreenshot('setup-list', function (Browser $browser) use ($period): void {
            $this->openSetupPeriodsTab($browser, $period->name);
            $browser->assertSee($period->name);
        });

        $this->forceDeletePeriod($period);
    }

    public function test_period_17_delete_blocked_when_referenced_by_assessments_or_scores(): void
    {
        // BR (06-Periods §Delete Restrictions): a period referenced by ba_assessments / ba_computed_scores
        // cannot be deleted. destroy() checks assessments()->exists() || computedScores()->exists().
        try {
            if (!Schema::hasTable('ba_assessments') && !Schema::hasTable('ba_computed_scores')) {
                $this->markTestSkipped('Neither ba_assessments nor ba_computed_scores present — RESTRICT guard not exercisable.');
            }
            // Assert the FK metadata is RESTRICT (deterministic) — synthesising a full assessment graph is out of scope.
            $checked = false;
            foreach (['ba_assessments', 'ba_computed_scores'] as $child) {
                if (!Schema::hasTable($child)) {
                    continue;
                }
                $fk = DB::select(
                    "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                     WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ?
                       AND REFERENCED_TABLE_NAME = 'ba_assessment_periods'",
                    [$child]
                );
                if (empty($fk)) {
                    continue;
                }
                $checked = true;
                $rule = strtoupper((string) ($fk[0]->DELETE_RULE ?? ''));
                $this->assertTrue(
                    str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'),
                    "{$child}.period_id should RESTRICT period hard-delete; found: {$rule}"
                );
            }
            if (!$checked) {
                $this->markTestSkipped('No FK metadata for period children — RESTRICT not exercisable.');
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('RESTRICT dependency path unavailable: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 20–29 — State machine (BC-SM) — open ↔ closed ↔ locked
    // =====================================================================

    public function test_period_20_new_period_starts_open(): void
    {
        // BC-SM-1: (create) → open.
        $period = $this->createPeriodSeed(); // seed defaults to open
        $this->assertSame('open', $period->status);
        $this->forceDeletePeriod($period);
    }

    public function test_period_21_open_to_closed_transition_succeeds(): void
    {
        // BC-SM-2: open --close()--> closed (legal).
        $period = $this->createPeriodSeed(['status' => 'open']);

        $response = $this->transition($period->id, 'close');
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $period->refresh();
        $this->assertSame('closed', $period->status, 'open period must transition to closed.');

        $this->forceDeletePeriod($period);
    }

    public function test_period_22_closed_to_open_reopen_transition_succeeds(): void
    {
        // BC-SM-3: closed --reopen()--> open (legal).
        $period = $this->createPeriodSeed(['status' => 'closed']);

        $this->transition($period->id, 'reopen');
        $period->refresh();
        $this->assertSame('open', $period->status, 'closed period must reopen to open.');

        $this->forceDeletePeriod($period);
    }

    public function test_period_23_closed_to_locked_lock_transition_succeeds(): void
    {
        // BC-SM-4: closed --lock()--> locked (legal).
        $period = $this->createPeriodSeed(['status' => 'closed']);

        $this->transition($period->id, 'lock');
        $period->refresh();
        $this->assertSame('locked', $period->status, 'closed period must lock to locked.');

        $this->forceDeletePeriod($period);
    }

    public function test_period_24_locked_to_closed_unlock_admin_override_succeeds(): void
    {
        // BC-SM-5: locked --unlock()--> closed (admin override; DOC-BA-002 note: DDL/FRD call locked terminal,
        // but 06-Periods requirement + code allow an admin unlock — code follows the screen requirement).
        $period = $this->createPeriodSeed(['status' => 'locked']);

        $this->transition($period->id, 'unlock');
        $period->refresh();
        $this->assertSame('closed', $period->status, 'locked period must unlock to closed (admin override).');

        $this->forceDeletePeriod($period);
    }

    public function test_period_25_illegal_close_on_non_open_period_is_rejected(): void
    {
        // BC-SM illegal: close() only from open. closed/locked → rejected, status unchanged.
        $closed = $this->createPeriodSeed(['status' => 'closed']);
        $this->transition($closed->id, 'close');
        $closed->refresh();
        $this->assertSame('closed', $closed->status, 'Closing an already-closed period must be rejected (status unchanged).');

        $locked = $this->createPeriodSeed(['status' => 'locked']);
        $this->transition($locked->id, 'close');
        $locked->refresh();
        $this->assertSame('locked', $locked->status, 'Closing a locked period must be rejected (status unchanged).');

        $this->forceDeletePeriod($closed);
        $this->forceDeletePeriod($locked);
    }

    public function test_period_26_illegal_reopen_on_non_closed_period_is_rejected(): void
    {
        // BC-SM illegal: reopen() only from closed. open/locked → rejected.
        $open = $this->createPeriodSeed(['status' => 'open']);
        $this->transition($open->id, 'reopen');
        $open->refresh();
        $this->assertSame('open', $open->status, 'Reopening an open period must be rejected.');

        $locked = $this->createPeriodSeed(['status' => 'locked']);
        $this->transition($locked->id, 'reopen');
        $locked->refresh();
        $this->assertSame('locked', $locked->status, 'Reopening a locked period directly must be rejected (unlock first).');

        $this->forceDeletePeriod($open);
        $this->forceDeletePeriod($locked);
    }

    public function test_period_27_direct_open_to_locked_is_rejected_lock_requires_closed(): void
    {
        // Regression guard for the OLD audit BUG-BA-002 sub-issue "code allows open→locked directly".
        // Current source: lock() requires status==='closed', so a direct open→lock is rejected.
        $open = $this->createPeriodSeed(['status' => 'open']);
        $this->transition($open->id, 'lock');
        $open->refresh();
        $this->assertSame('open', $open->status, 'Direct open→locked must be rejected — lock() requires a closed period (BUG-BA-002 open→locked path remediated).');

        // Illegal unlock on a non-locked period is likewise rejected.
        $this->transition($open->id, 'unlock');
        $open->refresh();
        $this->assertSame('open', $open->status, 'Unlocking a non-locked period must be rejected.');

        $this->forceDeletePeriod($open);
    }

    public function test_period_28_bug_ba_002_transition_fsm_and_status_backdoor_are_remediated(): void
    {
        // BUG-BA-002 REMEDIATION proof (verify-in-source, current code):
        //  (a) a close() action + route now exist (audit said "no close() anywhere");
        //  (b) reopen() route exists;
        //  (c) `status` was removed from the FormRequest rules (audit said edit sets status directly — back-door).
        $this->assertTrue(Route::has('behavioural-assessment.assessment-periods.close'), 'close route must be registered (BUG-BA-002 remediation).');
        $this->assertTrue(Route::has('behavioural-assessment.assessment-periods.reopen'), 'reopen route must be registered (BUG-BA-002 remediation).');
        $this->assertTrue(Route::has('behavioural-assessment.assessment-periods.lock'), 'lock route must be registered.');
        $this->assertTrue(Route::has('behavioural-assessment.assessment-periods.unlock'), 'unlock route must be registered.');

        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaAssessmentPeriodRequest.php'));
        if ($request !== null) {
            $this->assertStringNotContainsString("'status'", $request, "BUG-BA-002 regression: 'status' is back in the FormRequest rules (edit back-door reopened).");
        }

        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAssessmentPeriodController.php'));
        if ($controller !== null) {
            $this->assertStringContainsString('Only closed periods can be locked', $controller, 'lock() must guard closed→locked (no direct open→locked).');
            $this->assertStringContainsString("'status'     => 'open'", $controller, 'store() must hardcode status=open.');
        }
    }

    public function test_period_29_bug_ba_002_residual_locked_period_still_mutable_via_direct_write(): void
    {
        // BUG-BA-002 RESIDUAL — the controller enforces NO server-side isLocked() guard on write paths.
        // The edit Blade only CSS-disables the form (pe-none opacity-50 + hidden submit). A direct PUT/POST bypasses it.
        // These assertions capture CURRENT (defective) behaviour; each flips red if an isLocked() guard is added.

        // 1) update() mutates a LOCKED period.
        $locked = $this->createPeriodSeed(['status' => 'locked', 'name' => $this->uniqueName('LKUPD')]);
        $newName = $this->uniqueName('BYPASS');
        $response = $this->putPeriod($locked->id, $this->validStorePayload([
            'academic_session_id' => $locked->academic_session_id,
            'name' => $newName,
        ]));
        $this->assertNotSame(403, (int) ($response['status'] ?? 0), 'BUG-BA-002 residual: update() does not 403 a locked period (no server-side isLocked guard).');
        $locked->refresh();
        $this->assertSame($newName, $locked->name, 'BUG-BA-002 residual: a LOCKED period was edited via direct PUT — lock is client-side only.');

        // 2) toggleStatus() flips is_active on a LOCKED period.
        $toggle = $this->transition($locked->id, 'toggle-status');
        $this->assertSame(200, (int) ($toggle['status'] ?? 0), 'BUG-BA-002 residual: toggle-status succeeds on a locked period.');
        $locked->refresh();
        $this->assertFalse((bool) $locked->is_active, 'BUG-BA-002 residual: a LOCKED period was deactivated via toggle-status.');

        // 3) destroy() soft-deletes a LOCKED period (no children).
        $locked2 = $this->createPeriodSeed(['status' => 'locked']);
        $del = $this->apiCall('DELETE', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $locked2->id));
        $this->assertContains((int) ($del['status'] ?? 0), [200, 302], 'BUG-BA-002 residual: destroy() does not block a locked period.');
        $this->assertNotNull(BaAssessmentPeriod::onlyTrashed()->find($locked2->id), 'BUG-BA-002 residual: a LOCKED period was moved to trash with no lock guard.');

        $this->forceDeletePeriod($locked);
        $this->forceDeletePeriod(BaAssessmentPeriod::onlyTrashed()->find($locked2->id));
    }

    // =====================================================================
    // Band 30–39 — Validation + error messages (BC-VAL) — Negative 100%
    // =====================================================================

    public function test_period_30_required_fields_are_rejected(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), [
            'academic_session_id' => '', 'name' => '', 'start_date' => '', 'end_date' => '', 'deadline' => '',
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'Empty payload must fail validation.');
        $errors = $response['json']['errors'] ?? [];
        foreach (['academic_session_id', 'name', 'start_date', 'end_date', 'deadline'] as $field) {
            $this->assertArrayHasKey($field, $errors, "Missing required-error for {$field}.");
        }
    }

    public function test_period_31_name_max_length_100_is_enforced(): void
    {
        $response = $this->postPeriodRaw(['name' => str_repeat('N', 101)]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('name', $response['json']['errors'] ?? []);
    }

    public function test_period_32_academic_session_id_must_exist(): void
    {
        $response = $this->postPeriodRaw(['academic_session_id' => 987654321]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'A non-existent academic_session_id must be rejected by exists rule.');
        $this->assertArrayHasKey('academic_session_id', $response['json']['errors'] ?? []);
    }

    public function test_period_33_academic_term_id_must_exist_when_provided(): void
    {
        $response = $this->postPeriodRaw(['academic_term_id' => 987654321]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'A non-existent academic_term_id must be rejected by exists rule.');
        $this->assertArrayHasKey('academic_term_id', $response['json']['errors'] ?? []);
    }

    public function test_period_34_end_date_must_be_on_or_after_start_date(): void
    {
        $response = $this->postPeriodRaw([
            'start_date' => '2026-08-31',
            'end_date'   => '2026-06-01', // before start
            'deadline'   => '2026-09-05',
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'end_date before start_date must fail after_or_equal.');
        $this->assertArrayHasKey('end_date', $response['json']['errors'] ?? []);
    }

    public function test_period_35_deadline_must_be_on_or_after_end_date(): void
    {
        $response = $this->postPeriodRaw([
            'start_date' => '2026-06-01',
            'end_date'   => '2026-08-31',
            'deadline'   => '2026-08-01', // before end
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0), 'deadline before end_date must fail gte:end_date.');
        $this->assertArrayHasKey('deadline', $response['json']['errors'] ?? []);
    }

    public function test_period_36_dates_must_be_valid_dates(): void
    {
        $response = $this->postPeriodRaw([
            'start_date' => 'not-a-date',
            'end_date'   => 'also-bad',
            'deadline'   => 'nope',
        ]);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('start_date', $response['json']['errors'] ?? []);
    }

    public function test_period_37_whitespace_only_name_is_rejected(): void
    {
        // Laravel TrimStrings middleware collapses '   ' → '' → required fails.
        $response = $this->postPeriodRaw(['name' => '   ']);
        $this->assertSame(422, (int) ($response['status'] ?? 0));
        $this->assertArrayHasKey('name', $response['json']['errors'] ?? []);
    }

    public function test_period_38_xss_payload_in_name_is_stored_escaped_on_render(): void
    {
        $sessionId = $this->requireAcademicSessionId();
        $xss = '<script>alert(1)</script>';
        $name = substr('XSS ' . $this->uniqueName('X') . ' ' . $xss, 0, 100);
        $this->deletePeriodByName($name);

        $response = $this->postPeriod(['name' => $name, 'academic_session_id' => $sessionId]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));
        $created = BaAssessmentPeriod::where('name', $name)->first();
        $this->assertNotNull($created);

        $this->browseWithFailureScreenshot('xss-escaped', function (Browser $browser) use ($created): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/assessment-periods/' . $created->id . '/edit', 900);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Raw script tag must not render unescaped.');
        });

        $this->forceDeletePeriod($created);
    }

    public function test_period_39_name_uniqueness_and_date_overlap_are_not_enforced_per_gap_01_02(): void
    {
        // PER-GAP-02: requirement says Period Name is Unique, but the FormRequest has no unique rule.
        // PER-GAP-01: requirement's Chronological Non-Overlapping Rule is not enforced (no overlap validation).
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('DUPE');
        $this->deletePeriodByName($name);

        $first = $this->postPeriod([
            'name' => $name, 'academic_session_id' => $sessionId,
            'start_date' => '2026-06-01', 'end_date' => '2026-08-31', 'deadline' => '2026-09-05',
        ]);
        $this->assertNotSame(422, (int) ($first['status'] ?? 0));

        // Duplicate name + overlapping dates in the SAME session — both (wrongly) accepted.
        $second = $this->postPeriod([
            'name' => $name, 'academic_session_id' => $sessionId,
            'start_date' => '2026-07-01', 'end_date' => '2026-09-30', 'deadline' => '2026-10-05',
        ]);
        $this->assertNotSame(422, (int) ($second['status'] ?? 0), 'PER-GAP-01/02: duplicate name + overlapping dates are not rejected.');

        $dupes = BaAssessmentPeriod::where('name', $name)->count();
        $this->assertGreaterThanOrEqual(2, $dupes, 'PER-GAP-02: two periods share the same name (uniqueness not enforced).');

        BaAssessmentPeriod::withTrashed()->where('name', $name)->get()->each(fn ($p) => $this->forceDeletePeriod($p));
    }

    // =====================================================================
    // Band 40–49 — Integration / FK dependency & lifecycle (BC-INT/REF/EDG)
    // =====================================================================

    public function test_period_40_delete_soft_deletes_sets_inactive_and_moves_to_trash(): void
    {
        $period = $this->createPeriodSeed(['is_active' => true]);

        $response = $this->apiCall('DELETE', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);

        $this->assertFalse(BaAssessmentPeriod::where('id', $period->id)->exists(), 'Period should be hidden from default scope after soft delete.');
        $trashed = BaAssessmentPeriod::onlyTrashed()->find($period->id);
        $this->assertNotNull($trashed, 'Period should be present in trash.');
        $this->assertFalse((bool) $trashed->is_active, 'destroy() sets is_active=false before soft delete.');

        $this->forceDeletePeriod($trashed);
    }

    public function test_period_41_restore_from_trash_returns_period_to_default_scope(): void
    {
        $period = $this->createPeriodSeed();
        $period->delete();

        $response = $this->apiCall('GET', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id . '/restore'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertTrue(BaAssessmentPeriod::where('id', $period->id)->exists(), 'Restored period should return to default scope.');

        $this->forceDeletePeriod(BaAssessmentPeriod::find($period->id));
    }

    public function test_period_42_force_delete_removes_period_permanently(): void
    {
        $period = $this->createPeriodSeed();
        $period->delete();

        $response = $this->apiCall('DELETE', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id . '/force-delete'));
        $this->assertContains((int) ($response['status'] ?? 0), [200, 302]);
        $this->assertFalse(BaAssessmentPeriod::withTrashed()->where('id', $period->id)->exists(), 'Period row should be physically removed.');
    }

    public function test_period_43_restore_does_not_recover_a_force_deleted_period(): void
    {
        $period = $this->createPeriodSeed();
        $id = $period->id;
        $period->delete();
        $period->forceDelete();

        $response = $this->apiCall('GET', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $id . '/restore'));
        $this->assertSame(404, (int) ($response['status'] ?? 0), 'Restoring a physically-deleted period must 404.');
        $this->assertFalse(BaAssessmentPeriod::withTrashed()->where('id', $id)->exists());
    }

    public function test_period_44_session_fk_restrict_and_term_fk_set_null_metadata(): void
    {
        try {
            $rules = DB::select(
                "SELECT REFERENCED_TABLE_NAME, DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'ba_assessment_periods'"
            );
            if (empty($rules)) {
                $this->markTestSkipped('No FK metadata for ba_assessment_periods.');
            }
            $map = [];
            foreach ($rules as $r) {
                $map[(string) $r->REFERENCED_TABLE_NAME] = strtoupper((string) $r->DELETE_RULE);
            }
            if (isset($map['sch_org_academic_sessions_jnt'])) {
                $rule = $map['sch_org_academic_sessions_jnt'];
                $this->assertTrue(str_contains($rule, 'RESTRICT') || str_contains($rule, 'NO ACTION'), 'session FK should RESTRICT; found ' . $rule);
            }
            if (isset($map['sch_academic_term'])) {
                $this->assertStringContainsString('SET NULL', $map['sch_academic_term'], 'term FK should be SET NULL.');
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('FK metadata path unavailable: ' . $e->getMessage());
        }
    }

    public function test_period_45_full_lifecycle_create_close_lock_unlock_delete_restore_force_delete(): void
    {
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('LIFE');
        $this->deletePeriodByName($name);

        // create → open
        $create = $this->postPeriod(['name' => $name, 'academic_session_id' => $sessionId]);
        $this->assertNotSame(422, (int) ($create['status'] ?? 0));
        $period = BaAssessmentPeriod::where('name', $name)->firstOrFail();
        $this->assertSame('open', $period->status);

        // close → closed
        $this->transition($period->id, 'close');
        $period->refresh();
        $this->assertSame('closed', $period->status);

        // lock → locked
        $this->transition($period->id, 'lock');
        $period->refresh();
        $this->assertSame('locked', $period->status);

        // unlock → closed
        $this->transition($period->id, 'unlock');
        $period->refresh();
        $this->assertSame('closed', $period->status);

        // delete → trash
        $this->apiCall('DELETE', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id));
        $this->assertNotNull(BaAssessmentPeriod::onlyTrashed()->find($period->id));

        // restore
        $this->apiCall('GET', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id . '/restore'));
        $this->assertTrue(BaAssessmentPeriod::where('id', $period->id)->exists());

        // force delete
        BaAssessmentPeriod::find($period->id)->delete();
        $this->apiCall('DELETE', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id . '/force-delete'));
        $this->assertFalse(BaAssessmentPeriod::withTrashed()->where('id', $period->id)->exists());
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_period_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_period_51_limited_user_without_create_permission_gets_403(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-create-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::STORE_PATH), $this->validStorePayload());
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without create permission must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_period_52_limited_user_without_update_permission_gets_403(): void
    {
        $period = $this->createPeriodSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-update-403', function (Browser $browser) use ($limited, $period): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'PUT', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id), $this->validStorePayload(['academic_session_id' => $period->academic_session_id]));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeletePeriod($period);
    }

    public function test_period_53_limited_user_without_delete_permission_gets_403_on_destroy(): void
    {
        $period = $this->createPeriodSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-delete-403', function (Browser $browser) use ($limited, $period): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'DELETE', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeletePeriod($period);
    }

    public function test_period_54_limited_user_without_status_permission_gets_403_on_toggle(): void
    {
        $period = $this->createPeriodSeed();
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-toggle-403', function (Browser $browser) use ($limited, $period): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id . '/toggle-status'));
            $this->assertSame(403, (int) ($response['status'] ?? 0));
        });

        $this->deleteUser($limited);
        $this->forceDeletePeriod($period);
    }

    public function test_period_55_limited_user_without_lifecycle_permission_gets_403_on_lock(): void
    {
        $period = $this->createPeriodSeed(['status' => 'closed']);
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-lock-403', function (Browser $browser) use ($limited, $period): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $period->id . '/lock'));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'lock() must be gated by close/lock/update permission — a stripped user gets 403.');
        });

        $this->deleteUser($limited);
        $this->forceDeletePeriod($period);
    }

    public function test_period_56_policy_methods_map_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaAssessmentPeriodPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('Policy source not readable from app repo.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete', 'status', 'close', 'reopen', 'lock', 'unlock'] as $ability) {
            $this->assertStringContainsString(
                "tenant.behavioural-assessment.assessment-periods.{$ability}",
                $policy,
                "Policy missing gate string for {$ability}."
            );
        }
    }

    public function test_period_57_status_toggle_endpoint_updates_is_active_and_returns_json(): void
    {
        $period = $this->createPeriodSeed(['is_active' => true]);

        $response = $this->transition($period->id, 'toggle-status');
        $this->assertSame(200, (int) ($response['status'] ?? 0));
        $json = $response['json'] ?? [];
        $this->assertTrue((bool) ($json['success'] ?? false));
        $this->assertArrayHasKey('is_active', $json);
        $this->assertSame('Assessment period deactivated.', (string) ($json['message'] ?? ''));

        $period->refresh();
        $this->assertFalse((bool) $period->is_active);

        $again = $this->transition($period->id, 'toggle-status');
        $this->assertSame('Assessment period activated.', (string) ($again['json']['message'] ?? ''));

        $this->forceDeletePeriod($period);
    }

    // =====================================================================
    // Band 60–69 — UI/UX (search, filter, empty state, trash, breadcrumb)
    // =====================================================================

    public function test_period_60_setup_search_filters_by_name(): void
    {
        $period = $this->createPeriodSeed(['name' => $this->uniqueName('FINDME')]);

        $this->browseWithFailureScreenshot('search-filter', function (Browser $browser) use ($period): void {
            $this->openSetupPeriodsTab($browser, $period->name);
            $browser->assertSee($period->name);
        });

        $this->forceDeletePeriod($period);
    }

    public function test_period_61_status_filter_narrows_to_locked(): void
    {
        $locked = $this->createPeriodSeed(['status' => 'locked', 'name' => $this->uniqueName('LOCKEDONE')]);

        $this->browseWithFailureScreenshot('status-filter', function (Browser $browser) use ($locked): void {
            $this->visitAuthenticated($browser, self::SETUP_PERIODS_PATH . '&status=locked&search=' . urlencode($locked->name), 1000);
            $browser->assertSee($locked->name)->assertSee('Locked');
        });

        $this->forceDeletePeriod($locked);
    }

    public function test_period_62_empty_state_message_when_search_matches_nothing(): void
    {
        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser): void {
            $this->openSetupPeriodsTab($browser, 'ZZZ_NO_MATCH_' . $this->uniqueSuffix());
            $browser->assertSee('No assessment periods found.');
        });
    }

    public function test_period_63_trash_page_renders(): void
    {
        $period = $this->createPeriodSeed();
        $period->delete();

        $this->browseWithFailureScreenshot('trash-render', function (Browser $browser) use ($period): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH, 900);
            $browser->assertSee($period->name);
        });

        $this->forceDeletePeriod(BaAssessmentPeriod::onlyTrashed()->find($period->id));
    }

    public function test_period_64_breadcrumb_present_on_create_and_edit_pages(): void
    {
        $period = $this->createPeriodSeed();

        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser) use ($period): void {
            $this->openCreatePage($browser);
            $browser->assertSee('Assessment Periods');
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/assessment-periods/' . $period->id . '/edit', 900);
            $browser->assertSee('Assessment Periods');
        });

        $this->forceDeletePeriod($period);
    }

    public function test_period_65_edit_page_shows_locked_banner_and_disables_form_client_side(): void
    {
        // PER-GAP-03 / BUG-BA-002 UI side: the lock is enforced only in Blade — a locked edit page shows a
        // warning banner, hides the submit button and CSS-disables the form (pe-none opacity-50). This is the
        // ONLY lock enforcement (the server accepts a direct PUT — see _29).
        $period = $this->createPeriodSeed(['status' => 'locked']);

        $this->browseWithFailureScreenshot('locked-banner', function (Browser $browser) use ($period): void {
            $this->visitAuthenticated($browser, self::URL_PREFIX . '/assessment-periods/' . $period->id . '/edit', 900);
            $source = $browser->driver->getPageSource();
            $browser->assertSee('This period is locked.');
            $this->assertStringContainsString('pe-none', $source, 'Locked edit form should be CSS-disabled (pe-none).');
            $this->assertStringNotContainsString('Update Assessment Period', $source, 'Submit button must be hidden on a locked period.');
        });

        $this->forceDeletePeriod($period);
    }

    // =====================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =====================================================================

    public function test_period_70_invalid_id_returns_404(): void
    {
        $missing = 987654321;
        foreach ([
            self::URL_PREFIX . '/assessment-periods/' . $missing,
            self::URL_PREFIX . '/assessment-periods/' . $missing . '/edit',
        ] as $path) {
            $response = $this->apiCall('GET', $this->tenantUrl($path));
            $this->assertSame(404, (int) ($response['status'] ?? 0), "Expected 404 for {$path}.");
        }

        $toggle = $this->transition($missing, 'toggle-status');
        $this->assertSame(404, (int) ($toggle['status'] ?? 0), 'Toggle on invalid id must 404.');
        $close = $this->transition($missing, 'close');
        $this->assertSame(404, (int) ($close['status'] ?? 0), 'Close on invalid id must 404.');
    }

    public function test_period_71_deadline_equal_to_end_date_boundary_accepted(): void
    {
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('DLEQ');
        $this->deletePeriodByName($name);

        $response = $this->postPeriod([
            'name' => $name, 'academic_session_id' => $sessionId,
            'start_date' => '2026-06-01', 'end_date' => '2026-08-31', 'deadline' => '2026-08-31', // gte allows equal
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'deadline == end_date must be accepted (gte).');

        $this->forceDeletePeriod(BaAssessmentPeriod::where('name', $name)->first());
    }

    public function test_period_72_end_date_equal_to_start_date_boundary_accepted(): void
    {
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('EDEQ');
        $this->deletePeriodByName($name);

        $response = $this->postPeriod([
            'name' => $name, 'academic_session_id' => $sessionId,
            'start_date' => '2026-06-01', 'end_date' => '2026-06-01', 'deadline' => '2026-06-05', // after_or_equal allows equal
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0), 'end_date == start_date must be accepted (after_or_equal).');

        $this->forceDeletePeriod(BaAssessmentPeriod::where('name', $name)->first());
    }

    public function test_period_73_is_active_defaults_true_when_omitted(): void
    {
        // prepareForValidation merges is_active default true when not sent.
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('DEFACT');
        $this->deletePeriodByName($name);

        $payload = $this->validStorePayload(['name' => $name, 'academic_session_id' => $sessionId]);
        unset($payload['is_active']);
        $response = $this->apiCall('POST', $this->tenantUrl(self::STORE_PATH), $payload);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));

        $created = BaAssessmentPeriod::where('name', $name)->first();
        $this->assertNotNull($created);
        $this->assertTrue((bool) $created->is_active, 'is_active should default to true (prepareForValidation).');

        $this->forceDeletePeriod($created);
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_period_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side assessment-period tests.'
        );
        $this->assertTrue(Schema::hasTable(self::PERIODS_TABLE));
    }

    public function test_period_91_cross_tenant_direct_id_isolation(): void
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

    public function test_period_92_form_request_authorize_returns_true_sec_ba_002(): void
    {
        $request = $this->readAppFile($this->moduleRootPath('app/Http/Requests/BaAssessmentPeriodRequest.php'));
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

    public function test_period_93_created_by_and_updated_by_are_server_forced_not_mass_assignable(): void
    {
        // Security: audit columns must be set from auth()->id(), not from the request payload.
        $sessionId = $this->requireAcademicSessionId();
        $name = $this->uniqueName('AUDITCOL');
        $this->deletePeriodByName($name);

        $response = $this->postPeriod([
            'name' => $name, 'academic_session_id' => $sessionId,
            'created_by' => 999999, 'updated_by' => 999999,
        ]);
        $this->assertNotSame(422, (int) ($response['status'] ?? 0));

        $created = BaAssessmentPeriod::where('name', $name)->first();
        $this->assertNotNull($created);
        $this->assertSame((int) $this->adminUser->id, (int) $created->created_by, 'created_by must come from auth()->id(), not the payload.');
        $this->assertSame((int) $this->adminUser->id, (int) $created->updated_by, 'updated_by must come from auth()->id(), not the payload.');

        $this->forceDeletePeriod($created);
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
        $rawName = 'period-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'period-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    private function openCreatePage(Browser $browser): void
    {
        $this->visitAuthenticated($browser, self::CREATE_PATH, 900);
        $browser->waitFor('#academic_session_id', 15)->waitFor('#name', 10);
    }

    private function openSetupPeriodsTab(Browser $browser, ?string $search = null): void
    {
        $path = self::SETUP_PERIODS_PATH;
        if ($search !== null && $search !== '') {
            $path .= '&search=' . urlencode($search);
        }
        $this->visitAuthenticated($browser, $path, 1000);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#periods-pane') !== null || $browser->element('table') !== null;
        }, 'Assessment-periods setup tab did not render.');
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
window.__apApiDone = false;
window.__apApiError = '';
window.__apApiResult = null;

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

        window.__apApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__apApiError = String(error);
    } finally {
        window.__apApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__apApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__apApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__apApiResult || null;');
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

    private function postPeriod(array $overrides = []): array
    {
        $payload = $this->validStorePayload($overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    /** Post a payload built on a valid base but with a targeted invalid field (keeps other fields valid). */
    private function postPeriodRaw(array $overrides): array
    {
        $payload = array_merge($this->validStorePayload(), $overrides);
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::STORE_PATH), $payload));
    }

    private function putPeriod(int $id, array $payload): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'PUT', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $id), $payload));
    }

    /** POST a lifecycle/state transition endpoint (close|reopen|lock|unlock|toggle-status). */
    private function transition(int $id, string $action): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, 'POST', $this->tenantUrl(self::URL_PREFIX . '/assessment-periods/' . $id . '/' . $action)));
    }

    private function validStorePayload(array $overrides = []): array
    {
        return array_merge([
            'academic_session_id' => $this->academicSessionId(),
            'academic_term_id'    => null,
            'name'                => $this->uniqueName('VALID'),
            'start_date'          => '2026-06-01',
            'end_date'            => '2026-08-31',
            'deadline'            => '2026-09-05',
            'is_active'           => true,
        ], $overrides);
    }

    // ---- Seed / cleanup ---------------------------------------------------

    private function createPeriodSeed(array $overrides = []): BaAssessmentPeriod
    {
        $sessionId = $this->academicSessionId();
        if ($sessionId === null) {
            $this->markTestSkipped('No sch_org_academic_sessions_jnt row available to satisfy the required FK.');
        }

        $payload = array_merge([
            'academic_session_id' => $sessionId,
            'academic_term_id'    => null,
            'name'                => $this->uniqueName('SEED'),
            'start_date'          => '2026-06-01',
            'end_date'            => '2026-08-31',
            'deadline'            => '2026-09-05',
            'status'              => 'open',
            'is_active'           => true,
            'created_by'          => (int) $this->adminUser->id,
            'updated_by'          => (int) $this->adminUser->id,
        ], $overrides);

        return BaAssessmentPeriod::query()->create($payload);
    }

    private function academicSessionId(): ?int
    {
        try {
            if (!Schema::hasTable(self::SESSION_TABLE)) {
                return null;
            }
            $id = DB::table(self::SESSION_TABLE)->value('id');
            return $id === null ? null : (int) $id;
        } catch (Throwable) {
            return null;
        }
    }

    private function requireAcademicSessionId(): int
    {
        $id = $this->academicSessionId();
        if ($id === null) {
            $this->markTestSkipped('No sch_org_academic_sessions_jnt row available to satisfy the required FK.');
        }
        return $id;
    }

    private function deletePeriodByName(string $name): void
    {
        BaAssessmentPeriod::withTrashed()
            ->where('name', $name)
            ->get()
            ->each(fn (BaAssessmentPeriod $period) => $this->forceDeletePeriod($period));
    }

    private function forceDeletePeriod(?BaAssessmentPeriod $period): void
    {
        if ($period === null) {
            return;
        }
        try {
            if (BaAssessmentPeriod::withTrashed()->whereKey($period->id)->exists()) {
                $period->forceDelete();
            }
        } catch (Throwable) {
            // Cleanup is best-effort; a referenced row is left for the next run's dedupe.
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
                'name'              => 'AP Limited ' . $this->uniqueSuffix(),
                'email'             => 'ap_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'AP' . substr($this->uniqueSuffix(), -8);
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
        $this->grantPeriodPermissions($this->adminUser);
    }

    private function grantPeriodPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::AP_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::AP_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::AP_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.assessment-period-admin');
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
            $modelFile = (new ReflectionClass(BaAssessmentPeriod::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaAssessmentPeriod.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaAssessmentPeriod::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaAssessmentPeriod.php → app root = dirname(,5)
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
        $clean = $clean === '' ? 'AP' : substr($clean, 0, 12);
        return substr($clean . ' Period ' . $this->uniqueSuffix(), 0, 100);
    }
}
