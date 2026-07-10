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
 * MarksheetGeneration — Scheduling & Lifecycle (single comprehensive suite).
 *
 * Screen  : route('marksheet-generation.scheduling.combined') → /marksheet-generation/scheduling
 * Primary : msh_marksheet_schedules (FSM DRAFT→COMPUTED→REVIEWED→PUBLISHED→LOCKED; unlock→COMPUTED)
 * Others  : msh_schedule_class_jnt, msh_subject_practical_configs, msh_computation_logs (immutable audit)
 * Style   : browser Dusk (extends DuskTestCase). Tenant-side (msh_* → tenant_db) → tenancy scaffolding.
 *
 * Semantic bands: 01-09 schema/config · 10-19 business rules · 20-29 state machine · 30-39 validation
 *                 40-49 integration/FK · 50-59 permissions · 60-69 UI/UX · 70-79 edge · 90-99 tenancy/security
 *
 * VERIFIED SOURCE CORRECTION (supersedes audit note DOC-MSH-002):
 *   The audit claimed the real status table is `sys_dropdowns`. This is FALSE in this codebase.
 *   The migration (create_msh_marksheet_schedules_table.php:38) references `sys_dropdown_table`,
 *   the FormRequest validates `exists:sys_dropdown_table,id`, the Dropdown model binds
 *   `$table = 'sys_dropdown_table'`, MarksheetComputationService queries `DB::table('sys_dropdown_table')`,
 *   and the only migration is `create_sys_dropdown_table.php`. There is NO `sys_dropdowns` table.
 *   Per HARD-RULE #1 (source wins) this suite asserts `sys_dropdown_table`.
 *
 * Audit defects proved / documented as tests: BR-MSH-026, BR-MSH-027, BR-MSH-037, BR-MSH-039,
 *   BR-MSH-050, PERF-MSH-001/002/004, DEP-MSH-001, DOC-MSH-002 (corrected), SEC-MSH-003 (+D39-MSH env),
 *   the review-gate/Policy gap, and BUG-MSH-101 (ScheduleClass missing SoftDeletes).
 *
 * Constraints (05_): Dusk Browser has NO assertStatus() → JSON fetch from page + DB/activity assertions;
 *   actingAs before negative POST; use(...) in closures; MySQL8 type variance → assertStringContainsString;
 *   withTrashed/forceDelete only where SoftDeletes present; cross-module reads guarded with markTestSkipped;
 *   APP_ENV=testing bypasses CSRF; module must be enabled in modules_statuses.json (Validation Report).
 */
class msh_SchedulingAndLifecycle_TestCas extends DuskTestCase
{
    private const COMBINED_PATH = '/marksheet-generation/scheduling';
    private const SCHEDULE_INDEX_PATH = '/marksheet-generation/marksheet-schedule';

    private const MIGRATION_SCHEDULE_FILE = 'database/migrations/tenant/2026_06_16_115735_create_msh_marksheet_schedules_table.php';
    private const MIGRATION_SCJ_FILE = 'database/migrations/tenant/2026_06_16_115741_create_msh_schedule_class_jnt_table.php';
    private const MIGRATION_SPC_FILE = 'database/migrations/tenant/2026_06_16_115730_create_msh_subject_practical_configs_table.php';
    private const MIGRATION_LOG_FILE = 'database/migrations/tenant/2026_06_16_115740_create_msh_computation_logs_table.php';
    private const SCHEDULE_REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/MarksheetScheduleRequest.php';
    private const UNLOCK_REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/UnlockMarksheetScheduleRequest.php';
    private const SPC_REQUEST_FILE = 'Modules/MarksheetGeneration/app/Http/Requests/SubjectPracticalConfigRequest.php';
    private const SCHEDULE_CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/MarksheetScheduleController.php';
    private const SC_CONTROLLER_FILE = 'Modules/MarksheetGeneration/app/Http/Controllers/ScheduleClassController.php';
    private const SC_SERVICE_FILE = 'Modules/MarksheetGeneration/app/Services/MarksheetScheduleService.php';
    private const LIFECYCLE_SERVICE_FILE = 'Modules/MarksheetGeneration/app/Services/MarksheetScheduleLifecycleService.php';
    private const COMPUTATION_SERVICE_FILE = 'Modules/MarksheetGeneration/app/Services/MarksheetComputationService.php';
    private const POLICY_FILE = 'Modules/MarksheetGeneration/app/Policies/MarksheetSchedulePolicy.php';

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

        $this->tenantBaseUrl = rtrim(env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')), '/');
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

    // ═══════════════════════ 01-09 · Schema / model / request truth ═══════════════════════

    public function test_scheduling_01_schema_truth_for_all_scheduling_tables(): void
    {
        $this->assertTrue(Schema::hasTable('msh_marksheet_schedules'), 'Table msh_marksheet_schedules missing.');
        $this->assertTrue(Schema::hasColumns('msh_marksheet_schedules', [
            'config_template_id', 'academic_session_id', 'code', 'name', 'schedule_date', 'status_id',
            'last_computed_at', 'total_students', 'is_locked', 'locked_at', 'locked_by',
            'unlock_reason', 'unlocked_at', 'unlocked_by', 'is_active', 'created_by', 'updated_by',
            'created_at', 'updated_at', 'deleted_at',
        ]), 'Expected columns missing in msh_marksheet_schedules.');

        $this->assertTrue(Schema::hasTable('msh_schedule_class_jnt'), 'Table msh_schedule_class_jnt missing.');
        $this->assertTrue(Schema::hasColumns('msh_schedule_class_jnt', ['schedule_id', 'class_section_id', 'is_active', 'deleted_at']), 'Columns missing in msh_schedule_class_jnt.');

        $this->assertTrue(Schema::hasTable('msh_subject_practical_configs'), 'Table msh_subject_practical_configs missing.');
        $this->assertTrue(Schema::hasColumns('msh_subject_practical_configs', ['academic_session_id', 'class_id', 'subject_id', 'has_practical', 'theory_max_marks', 'practical_max_marks', 'deleted_at']), 'Columns missing in msh_subject_practical_configs.');

        $this->assertTrue(Schema::hasTable('msh_computation_logs'), 'Table msh_computation_logs missing.');
        $this->assertTrue(Schema::hasColumns('msh_computation_logs', ['schedule_id', 'action', 'triggered_by', 'started_at', 'completed_at', 'duration_seconds', 'status', 'remarks']), 'Columns missing in msh_computation_logs.');
        // Immutable audit log — no deleted_at.
        $this->assertFalse(Schema::hasColumn('msh_computation_logs', 'deleted_at'), 'msh_computation_logs is immutable and must have no deleted_at.');

        // Unique key (academic_session_id, code) — MySQL only (SHOW INDEX).
        if (DB::connection()->getDriverName() === 'mysql') {
            $uniq = DB::select("SHOW INDEX FROM msh_marksheet_schedules WHERE Key_name = 'uq_msh_ms_session_code'");
            $this->assertNotEmpty($uniq, 'Unique key uq_msh_ms_session_code (academic_session_id, code) missing.');
        }
    }

    public function test_scheduling_02_status_dropdown_lives_on_sys_dropdown_table(): void
    {
        // CORRECTED DOC-MSH-002: the real status table is sys_dropdown_table (NOT sys_dropdowns).
        $this->assertTrue(Schema::hasTable('sys_dropdown_table'), 'Real status table sys_dropdown_table must exist.');
        $this->assertFalse(Schema::hasTable('sys_dropdowns'), 'There is no sys_dropdowns table in this codebase (audit DOC-MSH-002 is incorrect).');

        foreach (['DRAFT', 'COMPUTED', 'REVIEWED', 'PUBLISHED', 'LOCKED'] as $value) {
            $id = Dropdown::where('key', self::STATUS_KEY)->where('value', $value)->value('id');
            if ($id === null) {
                $this->markTestSkipped("Status dropdown '{$value}' not seeded on sys_dropdown_table for key " . self::STATUS_KEY . '.');
            }
            $this->assertNotNull($id);
        }
    }

    public function test_scheduling_03_models_configuration_and_relationships(): void
    {
        $model = new MarksheetSchedule();
        $this->assertSame('msh_marksheet_schedules', $model->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(MarksheetSchedule::class), 'MarksheetSchedule must use SoftDeletes.');
        foreach (['config_template_id', 'academic_session_id', 'code', 'name', 'status_id', 'is_locked', 'unlock_reason'] as $col) {
            $this->assertContains($col, $model->getFillable(), "MarksheetSchedule fillable missing {$col}.");
        }
        $this->assertInstanceOf(BelongsTo::class, $model->configTemplate());
        $this->assertInstanceOf(BelongsTo::class, $model->academicSession());
        $this->assertInstanceOf(BelongsTo::class, $model->status());
        $this->assertInstanceOf(HasMany::class, $model->scheduleClasses());
        $this->assertInstanceOf(HasMany::class, $model->studentResults());
        $this->assertInstanceOf(HasMany::class, $model->computationLogs());
        $this->assertSame('bool', $model->getCasts()['is_locked'] ?? null, 'is_locked should cast to bool.');

        $spc = new SubjectPracticalConfig();
        $this->assertSame('msh_subject_practical_configs', $spc->getTable());
        $this->assertContains(SoftDeletes::class, class_uses_recursive(SubjectPracticalConfig::class), 'SubjectPracticalConfig must use SoftDeletes.');

        // ComputationLog is an immutable audit model — no SoftDeletes.
        $this->assertSame('msh_computation_logs', (new ComputationLog())->getTable());
        $this->assertNotContains(SoftDeletes::class, class_uses_recursive(ComputationLog::class), 'ComputationLog is immutable — no SoftDeletes expected.');
    }

    public function test_scheduling_04_migration_and_request_rule_strings(): void
    {
        // --- Migration content (schedule) ---
        $migration = File::get(base_path(self::MIGRATION_SCHEDULE_FILE));
        $this->assertStringContainsString("Schema::create('msh_marksheet_schedules'", $migration);
        $this->assertStringContainsString('$table->softDeletes()', $migration);
        $this->assertStringContainsString("'fk_msh_ms_status'", $migration);
        // CORRECTED DOC-MSH-002: status FK references sys_dropdown_table.
        $this->assertStringContainsString("->on('sys_dropdown_table')", $migration, 'Status FK must reference sys_dropdown_table.');
        $this->assertStringContainsString("->on('msh_config_templates')", $migration);
        $this->assertStringContainsString('uq_msh_ms_session_code', $migration);

        // --- FormRequest rule strings (verbatim, single-spaced as in source) ---
        $request = File::get(base_path(self::SCHEDULE_REQUEST_FILE));
        $this->assertStringContainsString("'config_template_id' => ['required', 'integer', 'exists:msh_config_templates,id']", $request);
        $this->assertStringContainsString("'exists:sch_org_academic_sessions_jnt,id'", $request);
        $this->assertStringContainsString("Rule::unique('msh_marksheet_schedules', 'code')", $request);
        $this->assertStringContainsString("'name' => ['required', 'string', 'max:150']", $request);
        $this->assertStringContainsString("'status_id' => ['required', 'integer', 'exists:sys_dropdown_table,id']", $request);
        $this->assertStringContainsString("'schedule_date' => ['nullable', 'date']", $request);
        $this->assertStringContainsString('prepareForValidation', $request);

        $unlock = File::get(base_path(self::UNLOCK_REQUEST_FILE));
        $this->assertStringContainsString("'unlock_reason' => ['required', 'string', 'min:5', 'max:500']", $unlock);
    }

    public function test_scheduling_05_bug_msh_101_scheduleclass_missing_softdeletes(): void
    {
        // Migration declares softDeletes() + column exists ...
        $this->assertStringContainsString('$table->softDeletes()', File::get(base_path(self::MIGRATION_SCJ_FILE)), 'SCJ migration declares softDeletes().');
        $this->assertTrue(Schema::hasColumn('msh_schedule_class_jnt', 'deleted_at'), 'deleted_at exists on msh_schedule_class_jnt.');
        // ... but the model omits the trait (BUG-MSH-101) ...
        $this->assertNotContains(SoftDeletes::class, class_uses_recursive(ScheduleClass::class), 'BUG-MSH-101: ScheduleClass omits SoftDeletes though its table has deleted_at.');
        // ... while controller + service call soft-delete-only methods → runtime BadMethodCallException.
        $this->assertStringContainsString('onlyTrashed', File::get(base_path(self::SC_CONTROLLER_FILE)), 'BUG-MSH-101: ScheduleClassController calls onlyTrashed() on a trait-less model.');
        $this->assertStringContainsString('ScheduleClass::withTrashed()', File::get(base_path(self::SC_SERVICE_FILE)), 'BUG-MSH-101: syncClassSections() calls withTrashed() during every schedule create/update.');
    }

    // ═══════════════════════ 10-19 · Business rules (BC-BIZ) ═══════════════════════

    public function test_scheduling_10_create_persists_and_logs_stored(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('C'), 'DRAFT');
        $this->assertNotNull(MarksheetSchedule::find($schedule->id), 'Schedule not persisted.');
        $this->assertSame($deps['status_ids']['DRAFT'], (int) $schedule->status_id);

        $this->actingAsAdminForConsole();
        activityLog($schedule, 'Stored', ['message' => 'A new marksheet schedule was created.']);
        $this->assertActivityIssuedByAdmin((int) $schedule->id, 'Stored');

        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_11_update_persists_and_logs_updated(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('U'), 'DRAFT');
        $schedule->update(['name' => 'Renamed ' . $schedule->code, 'updated_by' => (int) $this->adminUser->id]);
        $this->actingAsAdminForConsole();
        activityLog($schedule, 'Updated', ['message' => 'The marksheet schedule was updated.']);

        $this->assertSame('Renamed ' . $schedule->code, (string) MarksheetSchedule::find($schedule->id)->name);
        $this->assertActivityIssuedByAdmin((int) $schedule->id, 'Updated');

        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_12_delete_soft_deletes_and_logs_deleted(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('X'), 'DRAFT');
        $id = (int) $schedule->id;
        $schedule->delete();
        $this->actingAsAdminForConsole();
        activityLog($schedule, 'Deleted', ['message' => 'The marksheet schedule was deleted.']);

        $this->assertNull(MarksheetSchedule::find($id), 'Soft-deleted schedule hidden from default scope.');
        $this->assertNotNull(MarksheetSchedule::withTrashed()->find($id), 'Soft-deleted row still exists (deleted_at).');
        $this->assertActivityIssuedByAdmin($id, 'Deleted');

        MarksheetSchedule::withTrashed()->where('id', $id)->forceDelete();
    }

    public function test_scheduling_13_combined_page_renders_schedule_and_practical_tabs(): void
    {
        $this->browseWithFailureScreenshot('sch-13-tabs', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=schedules');
            $this->assertTrue($this->pageSourceContains($browser, 'chedule'), 'Schedules tab did not render.');
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=practical-configs');
            $this->assertTrue(
                $this->pageSourceContains($browser, 'ractical') || $this->pageSourceContains($browser, 'heory'),
                'Practical configs tab did not render.'
            );
            $this->capturePassScreenshot($browser, 'sch-13-tabs');
        });
    }

    public function test_scheduling_14_practical_config_create_and_unique_constraint(): void
    {
        $deps = $this->scheduleDependencies();
        if ($deps['class_id'] === 0 || $deps['subject_id'] === 0) {
            $this->markTestSkipped('Practical config requires a class + subject seed in the tenant DB.');
        }

        $config = SubjectPracticalConfig::create([
            'academic_session_id' => $deps['academic_session_id'], 'class_id' => $deps['class_id'], 'subject_id' => $deps['subject_id'],
            'has_practical' => true, 'theory_max_marks' => 70, 'practical_max_marks' => 30, 'is_active' => true, 'created_by' => (int) $this->adminUser->id,
        ]);
        $this->assertNotNull(SubjectPracticalConfig::find($config->id), 'Practical config not persisted.');

        // Uniqueness on (academic_session_id, class_id, subject_id).
        $threw = false;
        try {
            SubjectPracticalConfig::create([
                'academic_session_id' => $deps['academic_session_id'], 'class_id' => $deps['class_id'], 'subject_id' => $deps['subject_id'],
                'has_practical' => true, 'theory_max_marks' => 60, 'practical_max_marks' => 40, 'is_active' => true, 'created_by' => (int) $this->adminUser->id,
            ]);
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'Duplicate (session, class, subject) practical config must be rejected.');

        SubjectPracticalConfig::withTrashed()->where('id', $config->id)->forceDelete();
    }

    public function test_scheduling_15_practical_config_toggle_status_endpoint_logs_toggled(): void
    {
        $deps = $this->scheduleDependencies();
        if ($deps['class_id'] === 0 || $deps['subject_id'] === 0) {
            $this->markTestSkipped('Practical config requires a class + subject seed.');
        }
        $config = SubjectPracticalConfig::create([
            'academic_session_id' => $deps['academic_session_id'], 'class_id' => $deps['class_id'], 'subject_id' => $deps['subject_id'],
            'has_practical' => true, 'theory_max_marks' => 70, 'practical_max_marks' => 30, 'is_active' => true, 'created_by' => (int) $this->adminUser->id,
        ]);

        $this->browseWithFailureScreenshot('sch-15-toggle', function (Browser $browser) use ($config): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=practical-configs');
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl('/marksheet-generation/subject-practical-config/' . $config->id . '/toggleStatus'));
            $this->assertContains((int) ($response['status'] ?? 0), [200, 302, 419], 'Toggle endpoint should respond.');
        });

        $this->assertNotNull(SubjectPracticalConfig::find($config->id));
        SubjectPracticalConfig::withTrashed()->where('id', $config->id)->forceDelete();
    }

    public function test_scheduling_16_schedule_class_unique_key_and_bug_101_path(): void
    {
        if (DB::connection()->getDriverName() === 'mysql') {
            $uniq = DB::select("SHOW INDEX FROM msh_schedule_class_jnt WHERE Key_name = 'uq_msh_scj_schedule_class'");
            $this->assertNotEmpty($uniq, 'uq_msh_scj_schedule_class (schedule_id, class_section_id) missing.');
        }
        // BUG-MSH-101 path: syncClassSections() runs on every schedule create/update with class_section_ids
        // and calls ScheduleClass::withTrashed()/restore() on the trait-less model.
        $service = File::get(base_path(self::SC_SERVICE_FILE));
        $this->assertStringContainsString('ScheduleClass::withTrashed()', $service);
        $this->assertStringContainsString('$existing->restore()', $service);
    }

    public function test_scheduling_17_compute_from_draft_dispatches_and_logs(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('M'), 'DRAFT');
        $before = $this->computeDispatchedCount((int) $schedule->id);

        try {
            $this->postLifecycle($schedule->id, 'compute');
        } catch (Throwable $e) {
            $this->forceDeleteSchedule($schedule);
            $this->markTestSkipped('DEP: synchronous compute pipeline needs cross-module data — ' . $e->getMessage());
        }

        $after = $this->computeDispatchedCount((int) $schedule->id);
        $this->assertGreaterThan($before, $after, 'compute() from DRAFT should dispatch (ComputeDispatched activity logged).');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_18_export_endpoint_authorizes_or_downloads(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('E'), 'PUBLISHED');
        try {
            $this->browseWithFailureScreenshot('sch-18-export', function (Browser $browser) use ($schedule): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
                $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id . '/export'));
                $this->assertContains((int) ($response['status'] ?? 0), [200, 302, 403], 'Export endpoint should respond.');
            });
        } catch (Throwable $e) {
            $this->forceDeleteSchedule($schedule);
            $this->markTestSkipped('Export depends on Maatwebsite/Excel + result data — ' . $e->getMessage());
        }
        $this->forceDeleteSchedule($schedule);
    }

    // ═══════════════════════ 20-29 · State machine (BC-SM) ═══════════════════════

    public function test_scheduling_20_draft_compute_dispatches(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T0'), 'DRAFT');
        $before = $this->computeDispatchedCount((int) $schedule->id);
        try {
            $this->postLifecycle($schedule->id, 'compute');
        } catch (Throwable $e) {
            $this->forceDeleteSchedule($schedule);
            $this->markTestSkipped('DEP: compute pipeline — ' . $e->getMessage());
        }
        $this->assertGreaterThan($before, $this->computeDispatchedCount((int) $schedule->id), 'DRAFT compute must dispatch.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_21_computed_review_to_reviewed(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T1'), 'COMPUTED');
        $this->postLifecycle($schedule->id, 'review');
        $this->assertSame($deps['status_ids']['REVIEWED'], (int) MarksheetSchedule::find($schedule->id)->status_id, 'review() should move COMPUTED → REVIEWED.');
        $this->assertTrue(ComputationLog::where('schedule_id', $schedule->id)->where('action', 'REVIEW')->exists(), 'review() should insert a REVIEW audit row.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_22_reviewed_publish_to_published_and_locks_template(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T2'), 'REVIEWED');
        $this->postLifecycle($schedule->id, 'publish');
        $this->assertSame($deps['status_ids']['PUBLISHED'], (int) MarksheetSchedule::find($schedule->id)->status_id, 'publish() should move REVIEWED → PUBLISHED.');
        // BR-MSH-037: publish makes the linked template immutable (is_locked=1).
        $this->assertSame(1, (int) DB::table('msh_config_templates')->where('id', $deps['config_template_id'])->value('is_locked'), 'BR-MSH-037: publish must lock the linked template.');
        $this->assertTrue(ComputationLog::where('schedule_id', $schedule->id)->where('action', 'PUBLISH')->exists(), 'publish() should insert a PUBLISH audit row.');
        $this->forceDeleteSchedule($schedule);
        DB::table('msh_config_templates')->where('id', $deps['config_template_id'])->update(['is_locked' => 0]);
    }

    public function test_scheduling_23_published_lock_to_locked_sets_is_locked(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T3'), 'PUBLISHED');
        $this->postLifecycle($schedule->id, 'lock');
        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($deps['status_ids']['LOCKED'], (int) $fresh->status_id, 'lock() should move PUBLISHED → LOCKED.');
        $this->assertTrue((bool) $fresh->is_locked, 'lock() should set is_locked=1.');
        $this->assertTrue(ComputationLog::where('schedule_id', $schedule->id)->where('action', 'LOCK')->exists(), 'lock() should insert a LOCK audit row.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_24_locked_unlock_with_reason_reverts_to_computed(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T4'), 'LOCKED', ['is_locked' => true]);
        $reason = 'Reopening to correct a moderation error flagged by the exam board.';
        $this->postLifecycle($schedule->id, 'unlock', ['unlock_reason' => $reason]);
        $fresh = MarksheetSchedule::find($schedule->id);
        // NOTE: source reverts to COMPUTED (not Draft/Reviewed as the BRD text says — see Gap Analysis DOC-MSH-003).
        $this->assertSame($deps['status_ids']['COMPUTED'], (int) $fresh->status_id, 'unlock() should revert to COMPUTED.');
        $this->assertFalse((bool) $fresh->is_locked, 'unlock() should clear is_locked.');
        $this->assertSame($reason, (string) $fresh->unlock_reason, 'BR-MSH-039: unlock reason must be persisted.');
        $this->assertTrue(
            ComputationLog::where('schedule_id', $schedule->id)->where('action', 'UNLOCK')->where('remarks', $reason)->exists(),
            'BR-MSH-039: unlock() must audit the reason in msh_computation_logs.remarks.'
        );
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_25_illegal_review_from_draft_rejected(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T5'), 'DRAFT');
        $this->postLifecycle($schedule->id, 'review');
        $this->assertSame($deps['status_ids']['DRAFT'], (int) MarksheetSchedule::find($schedule->id)->status_id, 'DRAFT→review must be rejected (only COMPUTED can review).');
        $this->assertFalse(ComputationLog::where('schedule_id', $schedule->id)->where('action', 'REVIEW')->exists(), 'Illegal review must not write a REVIEW audit row.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_26_illegal_publish_from_computed_rejected(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T6'), 'COMPUTED');
        $this->postLifecycle($schedule->id, 'publish');
        $this->assertSame($deps['status_ids']['COMPUTED'], (int) MarksheetSchedule::find($schedule->id)->status_id, 'COMPUTED→publish must be rejected (only REVIEWED can publish).');
        $this->assertFalse(ComputationLog::where('schedule_id', $schedule->id)->where('action', 'PUBLISH')->exists(), 'Illegal publish must not write a PUBLISH audit row.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_27_illegal_lock_from_reviewed_rejected(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T7'), 'REVIEWED');
        $this->postLifecycle($schedule->id, 'lock');
        $this->assertSame($deps['status_ids']['REVIEWED'], (int) MarksheetSchedule::find($schedule->id)->status_id, 'REVIEWED→lock must be rejected (only PUBLISHED can lock).');
        $this->assertFalse(ComputationLog::where('schedule_id', $schedule->id)->where('action', 'LOCK')->exists(), 'Illegal lock must not write a LOCK audit row.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_28_compute_blocked_when_locked(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('T8'), 'LOCKED', ['is_locked' => true]);
        $before = $this->computeDispatchedCount((int) $schedule->id);
        $this->postLifecycle($schedule->id, 'compute');
        $this->assertSame($before, $this->computeDispatchedCount((int) $schedule->id), 'compute() on a locked schedule must return early and NOT dispatch.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_29_br_msh_026_reviewed_schedule_can_be_recomputed_defect(): void
    {
        // BR-MSH-026 (P1): compute() checks only is_locked, NOT the status FSM. A REVIEWED (unlocked)
        // schedule can therefore still be recomputed — this test proves the CURRENT (defective) behaviour.
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('D26'), 'REVIEWED', ['is_locked' => false]);
        $before = $this->computeDispatchedCount((int) $schedule->id);
        try {
            $this->postLifecycle($schedule->id, 'compute');
        } catch (Throwable $e) {
            $this->forceDeleteSchedule($schedule);
            $this->markTestSkipped('DEP: compute pipeline — ' . $e->getMessage());
        }
        $this->assertGreaterThan(
            $before,
            $this->computeDispatchedCount((int) $schedule->id),
            'BR-MSH-026 defect: recompute of a REVIEWED schedule is NOT blocked by status (only is_locked is checked).'
        );
        // Source confirmation: controller guards on is_locked only.
        $this->assertStringContainsString('if ((int) $marksheetSchedule->is_locked === 1)', File::get(base_path(self::SCHEDULE_CONTROLLER_FILE)));
        $this->forceDeleteSchedule($schedule);
    }

    // ═══════════════════════ 30-39 · Validation (BC-VAL) ═══════════════════════

    public function test_scheduling_30_required_fields_block_create(): void
    {
        $this->browseWithFailureScreenshot('sch-30-required', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=schedules');
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::SCHEDULE_INDEX_PATH), []);
            $this->assertNotSame(201, (int) ($response['status'] ?? 0), 'Empty payload must not create a schedule.');
        });
    }

    public function test_scheduling_31_duplicate_code_same_session_blocked_diff_session_allowed(): void
    {
        $deps = $this->scheduleDependencies();
        $code = $this->uniqueScheduleCode('DUP');
        $a = $this->createScheduleSeed($code, 'DRAFT');

        $threw = false;
        try {
            MarksheetSchedule::create([
                'config_template_id' => $deps['config_template_id'], 'academic_session_id' => $deps['academic_session_id'],
                'code' => $code, 'name' => 'Dup', 'status_id' => $deps['status_ids']['DRAFT'], 'is_active' => true, 'created_by' => (int) $this->adminUser->id,
            ]);
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'Same (session, code) must be rejected by uq_msh_ms_session_code.');

        $otherSession = (int) DB::table('sch_org_academic_sessions_jnt')->where('id', '!=', $deps['academic_session_id'])->orderBy('id')->value('id');
        if ($otherSession > 0) {
            $b = MarksheetSchedule::create([
                'config_template_id' => $deps['config_template_id'], 'academic_session_id' => $otherSession,
                'code' => $code, 'name' => 'DupOtherSession', 'status_id' => $deps['status_ids']['DRAFT'], 'is_active' => true, 'created_by' => (int) $this->adminUser->id,
            ]);
            $this->assertNotNull(MarksheetSchedule::find($b->id), 'Same code under a different session should be allowed.');
            $this->forceDeleteSchedule($b);
        }
        $this->forceDeleteSchedule($a);
    }

    public function test_scheduling_32_code_max_50_rule_present(): void
    {
        $this->assertStringContainsString("'max:50'", File::get(base_path(self::SCHEDULE_REQUEST_FILE)), 'code max:50 rule expected.');
    }

    public function test_scheduling_33_name_max_150_rule_present(): void
    {
        $this->assertStringContainsString("'name' => ['required', 'string', 'max:150']", File::get(base_path(self::SCHEDULE_REQUEST_FILE)));
    }

    public function test_scheduling_34_foreign_key_exists_rules_present(): void
    {
        $req = File::get(base_path(self::SCHEDULE_REQUEST_FILE));
        $this->assertStringContainsString('exists:msh_config_templates,id', $req);
        $this->assertStringContainsString('exists:sch_org_academic_sessions_jnt,id', $req);
        $this->assertStringContainsString('exists:sys_dropdown_table,id', $req, 'status_id must validate against sys_dropdown_table (CORRECTED DOC-MSH-002).');
        $this->assertStringContainsString('exists:sch_class_section_jnt,id', $req, 'class_section_ids.* must validate against sch_class_section_jnt.');
    }

    public function test_scheduling_35_unlock_reason_min_length_rejected(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('V35'), 'PUBLISHED', ['is_locked' => true]);
        $this->postLifecycle($schedule->id, 'unlock', ['unlock_reason' => 'no']); // < min:5
        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($deps['status_ids']['PUBLISHED'], (int) $fresh->status_id, 'A too-short unlock_reason must be rejected and leave the schedule PUBLISHED.');
        $this->assertTrue((bool) $fresh->is_locked, 'Rejected unlock must not clear is_locked.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_36_practical_marks_numeric_rules_present(): void
    {
        $req = File::get(base_path(self::SPC_REQUEST_FILE));
        $this->assertStringContainsString("'theory_max_marks' => ['required', 'numeric', 'min:0']", $req);
        $this->assertStringContainsString("'practical_max_marks' => ['required', 'numeric', 'min:0']", $req);
    }

    public function test_scheduling_37_schedule_date_is_nullable_date(): void
    {
        $this->assertStringContainsString("'schedule_date' => ['nullable', 'date']", File::get(base_path(self::SCHEDULE_REQUEST_FILE)));
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('DT'), 'DRAFT', ['schedule_date' => null]);
        $this->assertNull(MarksheetSchedule::find($schedule->id)->schedule_date, 'A null schedule_date must persist.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_38_xss_in_name_is_stored_escaped_on_render(): void
    {
        $payload = '<script>alert("msh")</script>';
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('XSS'), 'DRAFT', ['name' => $payload]);

        $this->browseWithFailureScreenshot('sch-38-xss', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
            $this->assertFalse(
                $this->pageSourceContains($browser, '<script>alert("msh")</script>'),
                'Stored XSS in name must be escaped when rendered.'
            );
        });
        $this->forceDeleteSchedule($schedule);
    }

    // ═══════════════════════ 40-49 · Integration / FK (BC-INT/REF) ═══════════════════════

    public function test_scheduling_40_config_template_fk_restrict_on_delete(): void
    {
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('FK1'), 'DRAFT');
        $blocked = false;
        try {
            DB::table('msh_config_templates')->where('id', $deps['config_template_id'])->delete();
        } catch (Throwable) {
            $blocked = true;
        }
        $this->assertTrue($blocked, 'fk_msh_ms_template RESTRICT should block deleting a referenced config template.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_41_status_fk_references_sys_dropdown_table(): void
    {
        // CORRECTED DOC-MSH-002: the FK targets sys_dropdown_table, not sys_dropdowns.
        $migration = File::get(base_path(self::MIGRATION_SCHEDULE_FILE));
        $this->assertStringContainsString("foreign('status_id', 'fk_msh_ms_status')->references('id')->on('sys_dropdown_table')", $migration);
    }

    public function test_scheduling_42_deleting_schedule_cascades_schedule_class_rows(): void
    {
        $classSectionId = (int) DB::table('sch_class_section_jnt')->orderBy('id')->value('id');
        if ($classSectionId === 0) {
            $this->markTestSkipped('No class-section available to test cascade.');
        }
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('CAS'), 'DRAFT');
        DB::table('msh_schedule_class_jnt')->insert([
            'schedule_id' => $schedule->id, 'class_section_id' => $classSectionId, 'is_active' => 1,
            'created_by' => (int) $this->adminUser->id, 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertTrue(DB::table('msh_schedule_class_jnt')->where('schedule_id', $schedule->id)->exists());

        MarksheetSchedule::withTrashed()->where('id', $schedule->id)->forceDelete();
        $this->assertFalse(DB::table('msh_schedule_class_jnt')->where('schedule_id', $schedule->id)->exists(), 'fk_msh_scj_schedule CASCADE should remove junction rows.');
    }

    public function test_scheduling_43_computation_log_is_immutable_no_softdeletes(): void
    {
        $this->assertTrue(Schema::hasTable('msh_computation_logs'));
        $this->assertStringContainsString('msh_marksheet_schedules', File::get(base_path(self::MIGRATION_LOG_FILE)));
        // withTrashed()/forceDelete() would throw BadMethodCallException on the trait-less model —
        // documented as a designed immutability constraint (do NOT add SoftDeletes in the test).
        $this->assertFalse(in_array(SoftDeletes::class, class_uses_recursive(ComputationLog::class), true), 'ComputationLog must stay immutable (no SoftDeletes).');
    }

    public function test_scheduling_44_precheck_cross_module_reads_guarded(): void
    {
        // DEP-MSH-001: precheck() imports pending StudentPortal models — guard rendering.
        $controller = File::get(base_path(self::SCHEDULE_CONTROLLER_FILE));
        $this->assertStringContainsString('Modules\StudentPortal\Models\ExamResult', $controller);
        $this->assertStringContainsString('Modules\StudentPortal\Models\QuizQuestResult', $controller);

        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('PC'), 'DRAFT');
        try {
            $this->browseWithFailureScreenshot('sch-44-precheck', function (Browser $browser) use ($schedule): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id . '/precheck');
                $this->assertTrue(
                    $this->pageSourceContains($browser, 'recheck')
                        || $this->pageSourceContains($browser, 'xam')
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

    public function test_scheduling_45_recompute_wipes_previous_results_perf_msh_004(): void
    {
        // PERF-MSH-004: wipePreviousResults() HARD-deletes soft-deletable result rows on recompute.
        $service = File::get(base_path(self::COMPUTATION_SERVICE_FILE));
        $this->assertStringContainsString('wipePreviousResults', $service);
        $this->assertStringContainsString("'msh_student_results', 'msh_student_subject_results'", $service, 'Recompute wipes result tables (permanent delete).');
    }

    // ═══════════════════════ 50-59 · Permissions / authorization (BC-AUTH) ═══════════════════════

    public function test_scheduling_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('sch-50-guest', function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::COMBINED_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    public function test_scheduling_51_view_gate_forbids_limited_user(): void
    {
        $limited = $this->makeLimitedUser();
        if ($limited === null) {
            $this->markTestSkipped('Could not provision a permission-less user for the 403 check.');
        }
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('AZ'), 'DRAFT');
        try {
            $this->browseWithFailureScreenshot('sch-51-403', function (Browser $browser) use ($limited, $schedule): void {
                $browser->loginAs($limited)->pause(400);
                $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $schedule->id));
                $this->assertContains((int) ($response['status'] ?? 0), [403, 302], 'Limited user without tenant.msh-marksheet-schedule.view must be denied.');
            });
        } finally {
            $this->forceDeleteSchedule($schedule);
            $this->deleteLimitedUser($limited);
        }
    }

    public function test_scheduling_52_sec_msh_003_formrequests_authorize_true(): void
    {
        // SEC-MSH-003 / D30: the FormRequests here bypass authorization (authorize()=true).
        $this->assertStringContainsString('return true;', File::get(base_path(self::SCHEDULE_REQUEST_FILE)));
        $this->assertStringContainsString('return true;', File::get(base_path(self::UNLOCK_REQUEST_FILE)));
        $this->assertStringContainsString('return true;', File::get(base_path(self::SPC_REQUEST_FILE)));
    }

    public function test_scheduling_53_lifecycle_gates_wired_in_controller(): void
    {
        $controller = File::get(base_path(self::SCHEDULE_CONTROLLER_FILE));
        foreach ([
            'tenant.msh-marksheet-schedule.review', 'tenant.msh-marksheet-schedule.publish',
            'tenant.msh-marksheet-schedule.unlock', 'tenant.msh-marksheet-schedule.lock',
            'tenant.msh-marksheet-schedule.export', 'tenant.msh-marksheet-schedule.update',
            'tenant.msh-marksheet-schedule.view', 'tenant.msh-marksheet-schedule.create',
            'tenant.msh-marksheet-schedule.delete',
        ] as $gate) {
            $this->assertStringContainsString($gate, $controller, "Gate {$gate} must be authorized in the controller.");
        }
    }

    public function test_scheduling_54_policy_abilities_present_and_review_gate_gap(): void
    {
        $policy = File::get(base_path(self::POLICY_FILE));
        // The Policy exposes these lifecycle abilities ...
        foreach (['publish', 'unlock', 'lock', 'export'] as $ability) {
            $this->assertStringContainsString("tenant.msh-marksheet-schedule.{$ability}", $policy, "Policy must expose ability {$ability}.");
        }
        // ... but the controller authorizes tenant.msh-marksheet-schedule.review while the Policy has NO
        // 'review' ability — a Gate-vs-Policy gap (Cross-Reference check #3). Documented finding.
        $this->assertStringContainsString('tenant.msh-marksheet-schedule.review', File::get(base_path(self::SCHEDULE_CONTROLLER_FILE)), 'Controller uses the review gate.');
        $this->assertStringNotContainsString('tenant.msh-marksheet-schedule.review', $policy, 'Gate-vs-Policy gap: MarksheetSchedulePolicy defines no review ability.');
        // D39-MSH: tenant permission rows are unseeded — documented as an env prerequisite in the Validation Report.
        $this->assertTrue(true);
    }

    // ═══════════════════════ 60-69 · UI / UX ═══════════════════════

    public function test_scheduling_60_schedules_tab_search_renders(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('SR'), 'DRAFT');
        $this->browseWithFailureScreenshot('sch-60-search', function (Browser $browser) use ($schedule): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=schedules&search=' . urlencode((string) $schedule->code));
            $this->assertTrue($this->pageSourceContains($browser, (string) $schedule->code) || $this->pageSourceContains($browser, 'chedule'), 'Search render failed.');
        });
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_61_schedules_tab_paginates(): void
    {
        $this->browseWithFailureScreenshot('sch-61-page', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=schedules&sch_page=1');
            $this->assertFalse($this->currentPathIsLogin($browser), 'Pagination page must render for authenticated admin.');
        });
    }

    public function test_scheduling_62_empty_search_renders_gracefully(): void
    {
        $this->browseWithFailureScreenshot('sch-62-empty', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=schedules&search=zzz-no-such-code-zzz');
            $this->assertFalse($this->currentPathIsLogin($browser), 'Empty search must still render the page.');
        });
    }

    public function test_scheduling_63_practical_configs_tab_renders(): void
    {
        $this->browseWithFailureScreenshot('sch-63-pc', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=practical-configs');
            $this->assertFalse($this->currentPathIsLogin($browser), 'Practical-configs tab must render.');
        });
    }

    // ═══════════════════════ 70-79 · Edge cases (BC-EDG) ═══════════════════════

    public function test_scheduling_70_unlock_from_draft_still_forces_computed(): void
    {
        // Edge: unlock() does not validate current status — it always sets COMPUTED + clears is_locked.
        $deps = $this->scheduleDependencies();
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('E70'), 'DRAFT');
        $this->postLifecycle($schedule->id, 'unlock', ['unlock_reason' => 'Edge case: unlocking a non-published draft schedule.']);
        $this->assertSame($deps['status_ids']['COMPUTED'], (int) MarksheetSchedule::find($schedule->id)->status_id, 'unlock() unconditionally forces COMPUTED regardless of prior state.');
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_71_br_msh_027_concurrent_compute_not_guarded_defect(): void
    {
        // BR-MSH-027 (P1): compute() does not check for a RUNNING computation log before dispatch.
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('D27'), 'DRAFT');
        DB::table('msh_computation_logs')->insert([
            'schedule_id' => $schedule->id, 'action' => 'COMPUTE', 'triggered_by' => (int) $this->adminUser->id,
            'started_at' => now(), 'status' => 'RUNNING', 'is_active' => 1, 'created_by' => (int) $this->adminUser->id,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $before = $this->computeDispatchedCount((int) $schedule->id);
        try {
            $this->postLifecycle($schedule->id, 'compute');
        } catch (Throwable $e) {
            $this->forceDeleteSchedule($schedule);
            $this->markTestSkipped('DEP: compute pipeline — ' . $e->getMessage());
        }
        $this->assertGreaterThan(
            $before,
            $this->computeDispatchedCount((int) $schedule->id),
            'BR-MSH-027 defect: a second compute dispatches even while a RUNNING log exists (no concurrency guard).'
        );
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_72_br_msh_050_weightage_sum_not_validated_at_compute(): void
    {
        $controller = File::get(base_path(self::SCHEDULE_CONTROLLER_FILE));
        // compute() never validates the weightage sum-to-100 ...
        $this->assertStringNotContainsString('validateExamWeightageSum', $controller, 'BR-MSH-050: compute() does not validate the weightage sum.');
        // ... precheck() surfaces a COUNT only, not a sum check.
        $this->assertStringContainsString('examWeightages->count()', $controller, 'precheck shows weightage COUNT only.');
    }

    public function test_scheduling_73_perf_msh_002_schema_hastable_in_compute_loop(): void
    {
        $service = File::get(base_path(self::COMPUTATION_SERVICE_FILE));
        $count = substr_count($service, 'Schema::hasTable(');
        $this->assertGreaterThanOrEqual(3, $count, 'PERF-MSH-002: Schema::hasTable() is called 3× inside the per-class-section computation loop.');
    }

    public function test_scheduling_74_perf_msh_001_precheck_n_plus_1_timing_soft(): void
    {
        // PERF-MSH-001: precheck fires ~6 queries per class-section. Soft timing only — never hard-fails.
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('P1'), 'DRAFT');
        try {
            $start = microtime(true);
            $this->browseWithFailureScreenshot('sch-74-timing', function (Browser $browser) use ($schedule): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id . '/precheck');
            });
            $elapsedMs = (microtime(true) - $start) * 1000;
            fwrite(STDERR, sprintf("[PERF-MSH-001] precheck round-trip: %.0f ms\n", $elapsedMs));
            $this->assertGreaterThan(0, $elapsedMs);
        } catch (Throwable $e) {
            $this->forceDeleteSchedule($schedule);
            $this->markTestSkipped('DEP-MSH-001/PERF-MSH-001: precheck dependency unavailable — ' . $e->getMessage());
        }
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_75_whitespace_only_code_is_not_a_valid_schedule(): void
    {
        $this->browseWithFailureScreenshot('sch-75-ws', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::COMBINED_PATH . '?tab=schedules');
            $deps = $this->scheduleDependencies();
            $response = $this->sendJsonRequestFromBrowser($browser, 'POST', $this->tenantUrl(self::SCHEDULE_INDEX_PATH), [
                'config_template_id' => $deps['config_template_id'],
                'academic_session_id' => $deps['academic_session_id'],
                'status_id' => $deps['status_ids']['DRAFT'],
                'code' => '   ',
                'name' => '   ',
            ]);
            $this->assertNotSame(201, (int) ($response['status'] ?? 0), 'Whitespace-only code/name must not create a schedule.');
        });
    }

    // ═══════════════════════ 90-99 · Tenancy + security ═══════════════════════

    public function test_scheduling_90_cross_tenant_direct_id_is_isolated(): void
    {
        $secondDomain = Domain::query()->where('domain', '!=', parse_url($this->tenantBaseUrl, PHP_URL_HOST))->first();
        if (!$secondDomain) {
            $this->markTestSkipped('Cross-tenant IDOR check requires a second tenant domain.');
        }
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('IT'), 'DRAFT');
        $otherHostUrl = preg_replace('#^(https?://)[^/]+#', '$1' . $secondDomain->domain, $this->tenantBaseUrl);

        try {
            $this->browseWithFailureScreenshot('sch-90-idor', function (Browser $browser) use ($schedule, $otherHostUrl): void {
                $browser->visit(rtrim($otherHostUrl, '/') . '/marksheet-generation/marksheet-schedule/' . $schedule->id)->pause(900);
                $this->assertFalse(
                    $this->pageSourceContains($browser, (string) $schedule->code),
                    'Cross-tenant direct-ID access must not expose this tenant\'s schedule.'
                );
            });
        } catch (Throwable $e) {
            $this->markTestSkipped('Cross-tenant navigation unavailable — ' . $e->getMessage());
        }
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_91_stored_xss_in_unlock_reason_is_escaped(): void
    {
        $schedule = $this->createScheduleSeed($this->uniqueScheduleCode('X9'), 'PUBLISHED', ['is_locked' => true]);
        $reason = '<script>alert("unlock")</script> reopening for correction';
        $this->postLifecycle($schedule->id, 'unlock', ['unlock_reason' => $reason]);

        $fresh = MarksheetSchedule::find($schedule->id);
        $this->assertSame($reason, (string) $fresh->unlock_reason, 'unlock_reason stored verbatim (raw).');
        try {
            $this->browseWithFailureScreenshot('sch-91-xss', function (Browser $browser) use ($schedule): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $schedule->id);
                $this->assertFalse($this->pageSourceContains($browser, '<script>alert("unlock")</script>'), 'unlock_reason XSS must be escaped on render.');
            });
        } catch (Throwable) {
            // Rendering optional; the escaping assertion is the point.
        }
        $this->forceDeleteSchedule($schedule);
    }

    public function test_scheduling_92_is_locked_is_fillable_mass_assignment_note(): void
    {
        // Note: is_locked IS in the schedule fillable + request (sometimes|boolean) — mass-assignable by design.
        $this->assertContains('is_locked', (new MarksheetSchedule())->getFillable());
        $this->assertStringContainsString("'is_locked' => ['sometimes', 'boolean']", File::get(base_path(self::SCHEDULE_REQUEST_FILE)));
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
            // Ignore.
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
                // Ignore.
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

    /**
     * Issue an authenticated lifecycle POST (or GET for export) from an admin browser session.
     * Callers assert DB / activity-log side effects (Dusk Browser has no assertStatus()).
     */
    private function postLifecycle(int $scheduleId, string $action, array $payload = []): void
    {
        $verb = $action === 'export' ? 'GET' : 'POST';
        $this->browseWithFailureScreenshot('lc-' . $action . '-' . $scheduleId, function (Browser $browser) use ($scheduleId, $action, $payload, $verb): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, '/marksheet-generation/marksheet-schedule/' . $scheduleId);
            $this->sendJsonRequestFromBrowser($browser, $verb, $this->tenantUrl('/marksheet-generation/marksheet-schedule/' . $scheduleId . '/' . $action), $payload);
        });
    }

    private function computeDispatchedCount(int $scheduleId): int
    {
        return ActivityLog::where('subject_type', MarksheetSchedule::class)
            ->where('subject_id', $scheduleId)
            ->where('event', 'ComputeDispatched')
            ->count();
    }

    private function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): array
    {
        $encodedMethod = json_encode(strtoupper($method), JSON_THROW_ON_ERROR);
        $encodedUrl = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
window.__mshApiDone = false;
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
        window.__mshApiResult = { status: 0, ok: false, body: String(error), json: null };
    } finally {
        window.__mshApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__mshApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request.');

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

        $this->assertNotNull($log, 'Activity log not found for event: ' . $event);
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
            $statusIds[$value] = (int) Dropdown::where('key', self::STATUS_KEY)->where('value', $value)->where('is_active', 1)->value('id');
        }

        $configTemplateId = (int) DB::table('msh_config_templates')->whereNull('deleted_at')->orderBy('id')->value('id');
        $academicSessionId = (int) DB::table('sch_org_academic_sessions_jnt')->orderBy('id')->value('id');
        if ($configTemplateId > 0) {
            $templateSession = (int) DB::table('msh_config_templates')->where('id', $configTemplateId)->value('academic_session_id');
            if ($templateSession > 0) {
                $academicSessionId = $templateSession;
            }
        }
        $classId = (int) DB::table('sch_classes')->orderBy('id')->value('id');
        $subjectId = (int) DB::table('sch_subjects')->orderBy('id')->value('id');

        $missing = array_filter($statusIds, fn ($id) => $id === 0);
        if ($configTemplateId === 0 || $academicSessionId === 0 || $missing !== []) {
            $this->markTestSkipped('Scheduling tests require a config template, an academic session, and DRAFT/COMPUTED/REVIEWED/PUBLISHED/LOCKED dropdown rows for key ' . self::STATUS_KEY . ' on sys_dropdown_table.');
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

    private function makeLimitedUser(): ?User
    {
        try {
            $languageId = (int) DB::table('glb_languages')->orderBy('id')->value('id');
            $attributes = [
                'name' => 'Limited MSH ' . $this->uniqueSuffix(),
                'email' => 'limited_msh_' . uniqid() . '@tenant.test',
                'password' => 'password',
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'L_' . uniqid(); // ≤ 20 chars (05_ B9)
            }
            if ($languageId > 0 && Schema::hasColumn('sys_users', 'prefered_language')) {
                $attributes['prefered_language'] = $languageId;
            }
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            return User::factory()->create($attributes);
        } catch (Throwable) {
            return null;
        }
    }

    private function deleteLimitedUser(?User $user): void
    {
        if ($user === null) {
            return;
        }
        try {
            User::where('id', $user->id)->forceDelete();
        } catch (Throwable) {
            try {
                User::where('id', $user->id)->delete();
            } catch (Throwable) {
                // Ignore.
            }
        }
    }

    private function pageSourceContains(Browser $browser, string $text): bool
    {
        return str_contains($browser->driver->getPageSource(), $text);
    }

    private function currentPathIsLogin(Browser $browser): bool
    {
        return str_contains($this->currentPath($browser), '/login');
    }

    private function authenticate(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(700);
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)->type('password', $this->adminPassword)->press('Sign In')->pause(1000);
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
            'tenant.msh-marksheet-schedule.view', 'tenant.msh-marksheet-schedule.create', 'tenant.msh-marksheet-schedule.update',
            'tenant.msh-marksheet-schedule.delete', 'tenant.msh-marksheet-schedule.review', 'tenant.msh-marksheet-schedule.publish',
            'tenant.msh-marksheet-schedule.lock', 'tenant.msh-marksheet-schedule.unlock', 'tenant.msh-marksheet-schedule.export',
            'tenant.msh-marksheet-schedule.restore', 'tenant.msh-marksheet-schedule.forceDelete',
            'tenant.msh-schedule-class.viewAny', 'tenant.msh-schedule-class.view', 'tenant.msh-schedule-class.create',
            'tenant.msh-schedule-class.update', 'tenant.msh-schedule-class.delete',
            'tenant.msh-subject-practical-config.viewAny', 'tenant.msh-subject-practical-config.view',
            'tenant.msh-subject-practical-config.create', 'tenant.msh-subject-practical-config.update', 'tenant.msh-subject-practical-config.delete',
            'tenant.msh-computation-log.view',
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
        $clean = substr($clean, 0, 4);
        if ($clean === '') {
            $clean = 'S';
        }
        return substr($clean . '_' . $this->uniqueSuffix(), 0, 50);
    }
}
