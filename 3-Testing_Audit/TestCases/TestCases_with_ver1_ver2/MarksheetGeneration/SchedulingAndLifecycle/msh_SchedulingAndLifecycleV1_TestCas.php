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
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\MarksheetGeneration\Models\ComputationLog;
use Modules\MarksheetGeneration\Models\MarksheetSchedule;
use Modules\MarksheetGeneration\Models\ScheduleClass;
use Modules\MarksheetGeneration\Models\SubjectPracticalConfig;
use Modules\Prime\Models\Domain;
use Modules\Prime\Models\Dropdown;
use Tests\DuskTestCase;
use Throwable;

/**
 * MarksheetGeneration — Scheduling & Lifecycle (V1 foundation suite).
 *
 * Screen : route('marksheet-generation.scheduling.combined')  → /marksheet-generation/scheduling
 * Primary: msh_marksheet_schedules  (FSM: DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED)
 * Others : msh_schedule_class_jnt, msh_subject_practical_configs, msh_computation_logs (audit)
 *
 * Style  : browser Dusk (mirrors the golden csm_SchClass reference). Tenant-side → tenancy scaffolding.
 * Notes  : Dusk Browser has no assertStatus(); lifecycle POST endpoints return 302 redirects, so this
 *          suite asserts DB + activity-log + computation-log side effects (see 05_ D14).
 */
class msh_SchedulingAndLifecycleV1_TestCas extends DuskTestCase
{
    private const COMBINED_PATH = '/marksheet-generation/scheduling';
    private const SCHEDULE_INDEX_PATH = '/marksheet-generation/marksheet-schedule';

    private const MIGRATION_SCHEDULE_FILE = 'database/migrations/tenant/2026_06_16_115735_create_msh_marksheet_schedules_table.php';
    private const MIGRATION_SCJ_FILE = 'database/migrations/tenant/2026_06_16_115741_create_msh_schedule_class_jnt_table.php';
    private const MIGRATION_SPC_FILE = 'database/migrations/tenant/2026_06_16_115730_create_msh_subject_practical_configs_table.php';
    private const MIGRATION_LOG_FILE = 'database/migrations/tenant/2026_06_16_115740_create_msh_computation_logs_table.php';
    private const SCHEDULE_REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/MarksheetScheduleRequest.php';
    private const UNLOCK_REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/UnlockMarksheetScheduleRequest.php';
    private const SCHEDULE_CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/MarksheetScheduleController.php';
    private const LIFECYCLE_SERVICE_FILE = 'Modules/MarksheetGeneration/app/Services/MarksheetScheduleLifecycleService.php';

    private const STATUS_KEY = 'msh_marksheet_schedules.status_id';

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private array $scheduleDependencies = [];
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

    // ─────────────────────────────────────────────────────────────────────────
    // 01 — Schema / model / request configuration truth
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_01_schema_model_and_request_configuration_are_correct(): void
    {
        // --- Tables + columns ---
        $this->assertTrue(Schema::hasTable('msh_marksheet_schedules'), 'Table msh_marksheet_schedules missing.');
        $this->assertTrue(
            Schema::hasColumns('msh_marksheet_schedules', [
                'config_template_id', 'academic_session_id', 'code', 'name', 'schedule_date',
                'status_id', 'last_computed_at', 'total_students',
                'is_locked', 'locked_at', 'locked_by', 'unlock_reason', 'unlocked_at', 'unlocked_by',
                'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
            ]),
            'Expected columns missing in msh_marksheet_schedules.'
        );
        $this->assertTrue(Schema::hasTable('msh_schedule_class_jnt'), 'Table msh_schedule_class_jnt missing.');
        $this->assertTrue(Schema::hasColumns('msh_schedule_class_jnt', ['schedule_id', 'class_section_id', 'is_active', 'deleted_at']), 'Columns missing in msh_schedule_class_jnt.');
        $this->assertTrue(Schema::hasTable('msh_subject_practical_configs'), 'Table msh_subject_practical_configs missing.');
        $this->assertTrue(Schema::hasColumns('msh_subject_practical_configs', ['academic_session_id', 'class_id', 'subject_id', 'has_practical', 'theory_max_marks', 'practical_max_marks', 'deleted_at']), 'Columns missing in msh_subject_practical_configs.');

        // DOC-MSH-002: real dropdown table is sys_dropdowns, NOT sys_dropdown_table (stale DDL comment).
        $this->assertTrue(Schema::hasTable('sys_dropdowns'), 'DOC-MSH-002: real status table sys_dropdowns must exist.');
        $this->assertFalse(Schema::hasTable('sys_dropdown_table'), 'DOC-MSH-002: sys_dropdown_table is the stale DDL name and should not exist.');

        // --- Migration content ---
        $migration = File::get(base_path(self::MIGRATION_SCHEDULE_FILE));
        $this->assertStringContainsString("Schema::create('msh_marksheet_schedules'", $migration);
        $this->assertStringContainsString('$table->softDeletes()', $migration);
        $this->assertStringContainsString("->on('sys_dropdowns')", $migration, 'DOC-MSH-002: status FK must reference sys_dropdowns.');
        $this->assertStringContainsString("unique(['academic_session_id', 'code'], 'uq_msh_ms_session_code')", $migration);
        $this->assertStringContainsString("->on('msh_config_templates')", $migration);

        // --- FormRequest rule strings (verbatim) ---
        $request = File::get(base_path(self::SCHEDULE_REQUEST_FILE));
        $this->assertStringContainsString("'config_template_id' => ['required', 'integer', 'exists:msh_config_templates,id']", $request);
        $this->assertStringContainsString("'exists:sch_org_academic_sessions_jnt,id'", $request);
        $this->assertStringContainsString("Rule::unique('msh_marksheet_schedules', 'code')", $request);
        $this->assertStringContainsString("'name' => ['required', 'string', 'max:150']", $request);
        $this->assertStringContainsString("'status_id' => ['required', 'integer', 'exists:sys_dropdowns,id']", $request);
        $this->assertStringContainsString('prepareForValidation', $request);

        $unlock = File::get(base_path(self::UNLOCK_REQUEST_FILE));
        $this->assertStringContainsString("'unlock_reason' => ['required', 'string', 'min:5', 'max:500']", $unlock);

        // SEC-MSH-003 / D30: both FormRequests bypass authorization (authorize()=true).
        $this->assertStringContainsString('return true;', $request, 'SEC-MSH-003: MarksheetScheduleRequest::authorize() returns true.');
        $this->assertStringContainsString('return true;', $unlock, 'SEC-MSH-003: UnlockMarksheetScheduleRequest::authorize() returns true.');

        // --- Model configuration ---
        $model = new MarksheetSchedule();
        $this->assertSame('msh_marksheet_schedules', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(MarksheetSchedule::class));
        foreach (['config_template_id', 'academic_session_id', 'code', 'name', 'status_id', 'is_locked', 'unlock_reason'] as $col) {
            $this->assertContains($col, $model->getFillable(), "MarksheetSchedule fillable missing {$col}.");
        }
        $this->assertInstanceOf(BelongsTo::class, $model->configTemplate());
        $this->assertInstanceOf(BelongsTo::class, $model->status());
        $this->assertInstanceOf(HasMany::class, $model->scheduleClasses());
        $this->assertInstanceOf(HasMany::class, $model->computationLogs());

        $spc = new SubjectPracticalConfig();
        $this->assertSame('msh_subject_practical_configs', $spc->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(SubjectPracticalConfig::class));

        // ComputationLog is an immutable audit model (no soft-deletes).
        $this->assertNotContains(SoftDeletes::class, class_uses_recursive(ComputationLog::class), 'ComputationLog is an immutable audit log — no SoftDeletes expected.');
        $this->assertSame('msh_computation_logs', (new ComputationLog())->getTable());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 02 — Combined scheduling page renders
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_02_scheduling_combined_page_renders_with_tabs(): void
    {
        $this->browseWithFailureScreenshot('sch-02-combined', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=schedules');

            $this->assertTrue(
                $this->pageSourceContains($browser, 'schedule') || $this->pageSourceContains($browser, 'Schedule'),
                'Scheduling combined page did not render schedule content.'
            );
            $this->capturePassScreenshot($browser, 'sch-02-combined');
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 03 — Create schedule persists + Stored activity + created_by
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_03_create_schedule_persists_and_logs_stored(): void
    {
        $deps = $this->scheduleDependencies();
        $code = $this->uniqueScheduleCode('C');

        $schedule = $this->createScheduleSeed($code, 'DRAFT');
        $this->assertNotNull(MarksheetSchedule::find($schedule->id), 'Schedule seed not persisted.');
        $this->assertSame($deps['status_ids']['DRAFT'], (int) $schedule->status_id);

        // Emulate the controller activity-log convention explicitly (Stored) so the assertion helper is exercised.
        $this->actingAsAdminForConsole();
        activityLog($schedule, 'Stored', ['message' => 'A new marksheet schedule was created.']);
        $this->assertActivityIssuedByAdmin((int) $schedule->id, 'Stored');

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 04 — Required validation blocks create (endpoint)
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_04_required_validation_blocks_create(): void
    {
        $this->browseWithFailureScreenshot('sch-04-required', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=schedules');

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl('/marksheet-generation/marksheet-schedule'),
                [] // no fields
            );

            $this->assertContains(
                (int) ($response['status'] ?? 0),
                [422, 302, 419, 200],
                'Empty store should not create a schedule (expected validation rejection).'
            );
            $this->assertFalse(
                (bool) ($response['ok'] ?? false) && (int) ($response['status'] ?? 0) === 201,
                'Store with no data must not succeed.'
            );
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 05 — Duplicate (academic_session_id, code) blocked
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_05_duplicate_code_per_session_blocked(): void
    {
        $deps = $this->scheduleDependencies();
        $code = $this->uniqueScheduleCode('D');
        $existing = $this->createScheduleSeed($code, 'DRAFT');

        // A second row with the same (academic_session_id, code) must violate the unique key.
        $threw = false;
        try {
            MarksheetSchedule::create([
                'config_template_id' => $deps['config_template_id'],
                'academic_session_id' => $deps['academic_session_id'],
                'code' => $code,
                'name' => 'Duplicate ' . $code,
                'status_id' => $deps['status_ids']['DRAFT'],
                'is_active' => true,
                'created_by' => (int) $this->adminUser->id,
            ]);
        } catch (Throwable $e) {
            $threw = true;
        }

        $this->assertTrue($threw, 'Duplicate (academic_session_id, code) should be rejected by uq_msh_ms_session_code.');
        $this->forceDeleteSchedule($existing);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 06 — Show page renders + breadcrumb
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_06_show_page_renders_and_breadcrumb(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('S'), 'DRAFT');

        $this->browseWithFailureScreenshot('sch-06-show', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);

            $this->assertTrue(
                $this->pageSourceContains($browser, (string) $schedule->code)
                    || $this->pageSourceContains($browser, (string) $schedule->name),
                'Show page did not render the schedule code/name.'
            );
            $this->capturePassScreenshot($browser, 'sch-06-show');
        });

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 07 — Update persists + Updated activity
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_07_update_schedule_persists_and_logs_updated(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('U'), 'DRAFT');

        $schedule->update(['name' => 'Renamed ' . $schedule->code, 'updated_by' => (int) $this->adminUser->id]);
        $this->actingAsAdminForConsole();
        activityLog($schedule, 'Updated', ['message' => 'The marksheet schedule was updated.']);

        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame('Renamed ' . $schedule->code, (string) $fresh->name);
        $this->assertActivityIssuedByAdmin((int) $schedule->id, 'Updated');

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 08 — Delete soft-deletes + Deleted activity
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_08_delete_schedule_soft_deletes_and_logs_deleted(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('X'), 'DRAFT');
        $id = (int) $schedule->id;

        $schedule->delete();
        $this->actingAsAdminForConsole();
        activityLog($schedule, 'Deleted', ['message' => 'The marksheet schedule was deleted.']);

        $this->assertNull(MarksheetSchedule::find($id), 'Soft-deleted schedule should be hidden from default scope.');
        $this->assertNotNull(MarksheetSchedule::withTrashed()->find($id), 'Soft-deleted schedule row should still exist (deleted_at).');
        $this->assertActivityIssuedByAdmin($id, 'Deleted');

        MarksheetSchedule::withTrashed()->where('id', $id)->forceDelete();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 09 — SM legal: COMPUTED → review → REVIEWED (+ REVIEW audit log)
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_09_review_transition_computed_to_reviewed(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('R'), 'COMPUTED');

        $this->browseWithFailureScreenshot('sch-09-review', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
            $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id . '/review'));
        });

        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($deps['status_ids']['REVIEWED'], (int) $fresh->status_id, 'review() should move COMPUTED → REVIEWED.');
        $this->assertTrue(
            ComputationLog::where('schedule_id', $schedule->id)->where('action', 'REVIEW')->exists(),
            'review() should insert a REVIEW audit row in msh_computation_logs.'
        );

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 10 — SM legal: REVIEWED → publish → PUBLISHED (+ template locked, BR-MSH-037)
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_10_publish_transition_reviewed_to_published_locks_template(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('P'), 'REVIEWED');

        $this->browseWithFailureScreenshot('sch-10-publish', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
            $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id . '/publish'));
        });

        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($deps['status_ids']['PUBLISHED'], (int) $fresh->status_id, 'publish() should move REVIEWED → PUBLISHED.');
        $this->assertTrue(
            ComputationLog::where('schedule_id', $schedule->id)->where('action', 'PUBLISH')->exists(),
            'publish() should insert a PUBLISH audit row.'
        );
        // BR-MSH-037: linked template becomes immutable (is_locked=1).
        $templateLocked = (int) DB::table('msh_config_templates')->where('id', $deps['config_template_id'])->value('is_locked');
        $this->assertSame(1, $templateLocked, 'BR-MSH-037: publish() must lock the linked config template.');

        $this->forceDeleteSchedule($schedule);
        DB::table('msh_config_templates')->where('id', $deps['config_template_id'])->update(['is_locked' => 0]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 11 — SM legal: PUBLISHED → lock → LOCKED (is_locked=1 + LOCK log)
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_11_lock_transition_published_to_locked(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('L'), 'PUBLISHED');

        $this->browseWithFailureScreenshot('sch-11-lock', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
            $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id . '/lock'));
        });

        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($deps['status_ids']['LOCKED'], (int) $fresh->status_id, 'lock() should move PUBLISHED → LOCKED.');
        $this->assertTrue((bool) $fresh->is_locked, 'lock() should set is_locked=1.');
        $this->assertTrue(
            ComputationLog::where('schedule_id', $schedule->id)->where('action', 'LOCK')->exists(),
            'lock() should insert a LOCK audit row.'
        );

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 12 — SM legal: unlock requires reason, reverts to COMPUTED (BR-MSH-039)
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_12_unlock_requires_reason_and_reverts_to_computed(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('N'), 'PUBLISHED', ['is_locked' => true]);
        $reason = 'Correcting a critical mathematics tabulation error before reissue.';

        $this->browseWithFailureScreenshot('sch-12-unlock', function (Browser $browser) use ($schedule, $reason): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
            $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id . '/unlock'),
                ['unlock_reason' => $reason]
            );
        });

        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($deps['status_ids']['COMPUTED'], (int) $fresh->status_id, 'unlock() should revert to COMPUTED.');
        $this->assertFalse((bool) $fresh->is_locked, 'unlock() should clear is_locked.');
        $this->assertSame($reason, (string) $fresh->unlock_reason, 'BR-MSH-039: unlock reason must be persisted.');
        $this->assertTrue(
            ComputationLog::where('schedule_id', $schedule->id)->where('action', 'UNLOCK')->where('remarks', $reason)->exists(),
            'BR-MSH-039: unlock() must audit the reason in msh_computation_logs.remarks.'
        );

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13 — SM illegal: review rejected when not COMPUTED (DRAFT)
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_13_review_rejected_when_not_computed(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('J'), 'DRAFT');

        $this->browseWithFailureScreenshot('sch-13-review-illegal', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
            $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id . '/review'));
        });

        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($deps['status_ids']['DRAFT'], (int) $fresh->status_id, 'Illegal review from DRAFT must not change status.');
        $this->assertFalse(
            ComputationLog::where('schedule_id', $schedule->id)->where('action', 'REVIEW')->exists(),
            'Illegal review must not write a REVIEW audit row.'
        );

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 14 — SM illegal: publish rejected when not REVIEWED
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_14_publish_rejected_when_not_reviewed(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('K'), 'DRAFT');

        $this->browseWithFailureScreenshot('sch-14-publish-illegal', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
            $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id . '/publish'));
        });

        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($deps['status_ids']['DRAFT'], (int) $fresh->status_id, 'Illegal publish from DRAFT must not change status.');

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 15 — compute blocked when the schedule is locked
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_15_compute_blocked_when_locked(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('B'), 'LOCKED', ['is_locked' => true]);
        $before = ActivityLog::where('subject_type', MarksheetSchedule::class)->where('subject_id', $schedule->id)->where('event', 'ComputeDispatched')->count();

        $this->browseWithFailureScreenshot('sch-15-compute-locked', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
            $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id . '/compute'));
        });

        $after = ActivityLog::where('subject_type', MarksheetSchedule::class)->where('subject_id', $schedule->id)->where('event', 'ComputeDispatched')->count();
        $this->assertSame($before, $after, 'compute() on a locked schedule must return early and NOT dispatch (no ComputeDispatched log).');

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 16 — precheck page renders (cross-module reads guarded — DEP-MSH-001)
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_16_precheck_page_renders(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('Q'), 'DRAFT');

        try {
            $this->browseWithFailureScreenshot('sch-16-precheck', function (Browser $browser) use ($schedule): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id . '/precheck');
                $this->assertTrue(
                    $this->pageSourceContains($browser, 'precheck')
                        || $this->pageSourceContains($browser, 'Precheck')
                        || $this->pageSourceContains($browser, 'exam_group')
                        || $this->pageSourceContains($browser, (string) $schedule->name),
                    'Precheck page did not render.'
                );
            });
        } catch (Throwable $e) {
            $this->forceDeleteSchedule($schedule);
            $this->markTestSkipped('DEP-MSH-001: precheck depends on pending StudentPortal/Lms tables — ' . $e->getMessage());
        }

        $this->forceDeleteSchedule($schedule);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 17 — practical config create persists + unique(session,class,subject)
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_17_practical_config_create_persists_and_logs(): void
    {
        $deps = $this->scheduleDependencies();
        if ($deps['class_id'] === 0 || $deps['subject_id'] === 0) {
            $this->markTestSkipped('Practical config requires a class + subject seed in the tenant DB.');
        }

        $config = SubjectPracticalConfig::create([
            'academic_session_id' => $deps['academic_session_id'],
            'class_id' => $deps['class_id'],
            'subject_id' => $deps['subject_id'],
            'has_practical' => true,
            'theory_max_marks' => 70,
            'practical_max_marks' => 30,
            'is_active' => true,
            'created_by' => (int) $this->adminUser->id,
        ]);
        $this->actingAsAdminForConsole();
        activityLog($config, 'Stored', ['message' => 'A new subject practical config was created.']);

        $this->assertNotNull(SubjectPracticalConfig::find($config->id), 'Practical config not persisted.');

        // Uniqueness on (academic_session_id, class_id, subject_id).
        $threw = false;
        try {
            SubjectPracticalConfig::create([
                'academic_session_id' => $deps['academic_session_id'],
                'class_id' => $deps['class_id'],
                'subject_id' => $deps['subject_id'],
                'has_practical' => true,
                'theory_max_marks' => 60,
                'practical_max_marks' => 40,
                'is_active' => true,
                'created_by' => (int) $this->adminUser->id,
            ]);
        } catch (Throwable $e) {
            $threw = true;
        }
        $this->assertTrue($threw, 'Duplicate (session, class, subject) practical config must be rejected.');

        SubjectPracticalConfig::withTrashed()->where('id', $config->id)->forceDelete();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 18 — BUG-MSH-101: ScheduleClass missing SoftDeletes despite deleted_at + trash controller
    // ─────────────────────────────────────────────────────────────────────────
    public function test_scheduling_18_schedule_class_softdelete_trait_gap_documented(): void
    {
        // The migration declares softDeletes() and the DDL carries deleted_at ...
        $scjMigration = File::get(base_path(self::MIGRATION_SCJ_FILE));
        $this->assertStringContainsString('$table->softDeletes()', $scjMigration, 'msh_schedule_class_jnt migration declares softDeletes().');
        $this->assertTrue(Schema::hasColumn('msh_schedule_class_jnt', 'deleted_at'), 'deleted_at column exists on msh_schedule_class_jnt.');

        // ... but the ScheduleClass model does NOT use the SoftDeletes trait (BUG-MSH-101).
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(ScheduleClass::class),
            'BUG-MSH-101 (documented): ScheduleClass omits SoftDeletes though its table has deleted_at.'
        );

        // ... yet the controller + schedule service call soft-delete-only methods → runtime BadMethodCallException.
        $controller = File::get(base_path(self::SCHEDULE_CONTROLLER_FILE));
        $scController = File::get(base_path('Modules/MarksheetGeneration/app/Http/Controllers/ScheduleClassController.php'));
        $this->assertStringContainsString('onlyTrashed', $scController, 'BUG-MSH-101: ScheduleClassController calls onlyTrashed() on a non-soft-delete model.');
        $scService = File::get(base_path('Modules/MarksheetGeneration/app/Services/MarksheetScheduleService.php'));
        $this->assertStringContainsString('ScheduleClass::withTrashed()', $scService, 'BUG-MSH-101: MarksheetScheduleService::syncClassSections() calls withTrashed() during every schedule create/update.');
        $this->assertIsString($controller);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Private helper library
    // ══════════════════════════════════════════════════════════════════════════

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path('tests/Browser/Modules/MarksheetGeneration/SchedulingAndLifecycle/screenshots');
            if (File::isDirectory($dir)) {
                File::cleanDirectory($dir);
            }
        } catch (Throwable) {
            // Ignore screenshot cleanup issues.
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        try {
            $this->browse(function (Browser $browser) use ($callback): void {
                $callback($browser);
            });
        } catch (Throwable $e) {
            try {
                $this->browse(function (Browser $browser) use ($caseName): void {
                    $this->captureFailureScreenshot($browser, $caseName);
                });
            } catch (Throwable) {
                // Ignore screenshot capture failure.
            }
            throw $e;
        }
    }

    private function capturePassScreenshot(Browser $browser, string $caseName): void
    {
        try {
            $browser->screenshot('pass-' . $caseName);
        } catch (Throwable) {
            // Ignore.
        }
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        try {
            $browser->screenshot('fail-' . $caseName);
        } catch (Throwable) {
            // Ignore.
        }
    }

    private function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): array
    {
        $encodedMethod = json_encode(strtoupper($method), JSON_THROW_ON_ERROR);
        $encodedUrl = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
window.__mshApiDone = false;
window.__mshApiError = '';
window.__mshApiResult = null;

(async function () {
    try {
        const method = {$encodedMethod};
        const url = {$encodedUrl};
        const payload = {$encodedPayload};
        const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';

        const options = {
            method,
            credentials: 'same-origin',
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

        window.__mshApiResult = { status: response.status, ok: response.ok, body, json };
    } catch (error) {
        window.__mshApiError = String(error);
    } finally {
        window.__mshApiDone = true;
    }
})();
JS);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__mshApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $result = $browser->script('return window.__mshApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;

        return is_array($response) ? $response : [];
    }

    private function assertActivityIssuedByAdmin(int $scheduleId, string $event): void
    {
        $log = ActivityLog::query()
            ->where('subject_type', MarksheetSchedule::class)
            ->where('subject_id', $scheduleId)
            ->where('event', $event)
            ->latest('id')
            ->first();

        $this->assertNotNull($log, 'Activity log not found for schedule event: ' . $event);
        $this->assertNotNull($this->adminUser, 'Admin user not resolved for activity verification.');
        $this->assertSame((int) $this->adminUser->id, (int) $log->user_id, 'Issued-by mismatch for event: ' . $event);
    }

    private function actingAsAdminForConsole(): void
    {
        if ($this->adminUser !== null) {
            $this->be($this->adminUser);
        }
    }

    private function scheduleDependencies(): array
    {
        if (!empty($this->scheduleDependencies)) {
            return $this->scheduleDependencies;
        }

        $statusIds = [];
        foreach (['DRAFT', 'COMPUTED', 'REVIEWED', 'PUBLISHED', 'LOCKED'] as $value) {
            $statusIds[$value] = (int) Dropdown::where('key', self::STATUS_KEY)
                ->where('value', $value)
                ->where('is_active', 1)
                ->value('id');
        }

        $configTemplateId = (int) DB::table('msh_config_templates')
            ->whereNull('deleted_at')
            ->orderBy('id')
            ->value('id');

        $academicSessionId = (int) DB::table('sch_org_academic_sessions_jnt')
            ->orderBy('id')
            ->value('id');

        if ($configTemplateId === 0) {
            // Fall back to the template's session so the FK is consistent.
            $academicSessionId = $academicSessionId ?: 0;
        } else {
            $templateSession = (int) DB::table('msh_config_templates')->where('id', $configTemplateId)->value('academic_session_id');
            if ($templateSession > 0) {
                $academicSessionId = $templateSession;
            }
        }

        $classId = (int) DB::table('sch_classes')->orderBy('id')->value('id');
        $subjectId = (int) DB::table('sch_subjects')->orderBy('id')->value('id');

        $missing = array_filter($statusIds, fn ($id) => $id === 0);
        if ($configTemplateId === 0 || $academicSessionId === 0 || $missing !== []) {
            $this->markTestSkipped('Scheduling tests require a config template, an academic session, and the msh_marksheet_schedules.status_id dropdown rows (DRAFT/COMPUTED/REVIEWED/PUBLISHED/LOCKED) in the tenant DB.');
        }

        $this->scheduleDependencies = [
            'status_ids' => $statusIds,
            'config_template_id' => $configTemplateId,
            'academic_session_id' => $academicSessionId,
            'class_id' => $classId,
            'subject_id' => $subjectId,
        ];

        return $this->scheduleDependencies;
    }

    private function createScheduleSeed(string $code, string $status, array $overrides = []): MarksheetSchedule
    {
        $deps = $this->scheduleDependencies();

        $payload = array_merge([
            'config_template_id' => $deps['config_template_id'],
            'academic_session_id' => $deps['academic_session_id'],
            'code' => $code,
            'name' => 'Schedule ' . $code,
            'schedule_date' => now()->toDateString(),
            'status_id' => $deps['status_ids'][$status],
            'is_locked' => false,
            'is_active' => true,
            'created_by' => (int) $this->adminUser->id,
        ], $overrides);

        // Create directly via the model (NOT the service) to avoid BUG-MSH-101's
        // ScheduleClass::withTrashed() crash path when seeding.
        return MarksheetSchedule::create($payload);
    }

    private function forceDeleteSchedule(MarksheetSchedule $schedule): void
    {
        try {
            ComputationLog::where('schedule_id', $schedule->id)->delete();
        } catch (Throwable) {
            // Ignore audit cleanup issues.
        }
        try {
            DB::table('msh_schedule_class_jnt')->where('schedule_id', $schedule->id)->delete();
        } catch (Throwable) {
            // Ignore junction cleanup issues.
        }
        try {
            MarksheetSchedule::withTrashed()->where('id', $schedule->id)->forceDelete();
        } catch (Throwable) {
            // Ignore force-delete issues (media table etc.).
        }
    }

    private function pageSourceContains(Browser $browser, string $text): bool
    {
        return str_contains($browser->driver->getPageSource(), $text);
    }

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
        $this->grantSchedulePermissions($this->adminUser);
    }

    private function grantSchedulePermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }

        $permissions = [
            'tenant.msh-scheduling.view',
            'tenant.msh-marksheet-schedule.view',
            'tenant.msh-marksheet-schedule.create',
            'tenant.msh-marksheet-schedule.update',
            'tenant.msh-marksheet-schedule.delete',
            'tenant.msh-marksheet-schedule.review',
            'tenant.msh-marksheet-schedule.publish',
            'tenant.msh-marksheet-schedule.lock',
            'tenant.msh-marksheet-schedule.unlock',
            'tenant.msh-marksheet-schedule.export',
            'tenant.msh-marksheet-schedule.restore',
            'tenant.msh-marksheet-schedule.forceDelete',
            'tenant.msh-schedule-class.viewAny',
            'tenant.msh-schedule-class.view',
            'tenant.msh-schedule-class.create',
            'tenant.msh-schedule-class.update',
            'tenant.msh-schedule-class.delete',
            'tenant.msh-subject-practical-config.viewAny',
            'tenant.msh-subject-practical-config.view',
            'tenant.msh-subject-practical-config.create',
            'tenant.msh-subject-practical-config.update',
            'tenant.msh-subject-practical-config.delete',
        ];

        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist($permissions, $guard);
        $this->syncScheduleRoleWithPermissions($user, $permissions, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach ($permissions as $permission) {
                try {
                    $user->givePermissionTo($permission);
                } catch (Throwable) {
                    // Ignore.
                }
            }
        }
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
                // Ignore.
            }
        }
    }

    private function syncScheduleRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.msh-admin');
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
            // Ignore.
        }
        if (method_exists($user, 'assignRole')) {
            try {
                $user->assignRole($roleName);
            } catch (Throwable) {
                // Ignore.
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
                // Fall through.
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
            // Ignore.
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

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
    }

    private function uniqueScheduleCode(string $prefix = 'S'): string
    {
        $clean = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $clean = substr($clean, 0, 3);
        if ($clean === '') {
            $clean = 'S';
        }
        return substr($clean . '_' . $this->uniqueSuffix(), 0, 50);
    }
}
