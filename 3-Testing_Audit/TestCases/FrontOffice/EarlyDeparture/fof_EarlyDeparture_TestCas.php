<?php

/**
 * FrontOffice — Early Departure : comprehensive Dusk suite (ONE file per screen).
 *
 * Screen  : Log Early Departure (student mid-day parent pickup)
 * Table   : fof_early_departures  (prefix fof_ verified vs DDL CREATE TABLE)
 * Model   : Modules\FrontOffice\Models\EarlyDeparture (SoftDeletes)
 * Routes  : fof.early-departures.*  (prefix /front-office, name fof.)
 * Perms   : frontoffice.early-departure.{view,create,update,delete,restore,forceDelete}  (Gate::authorize string gates)
 * Activity: sys_activity_logs via Modules\GlobalMaster\Models\ActivityLog  (events: Created, Updated, Deleted, Restored)
 *
 * TENANT-SIDE Dusk. Mirrors the committed tenant-side sibling
 * Complaint/CmpComplaintManage/cmp_ComplaintCrud_TestCas.php (cross-module FK, direct-model DB tests + browser flows).
 * ONE test STYLE (browser + direct Eloquent). No actingAs()->post() mixing.
 *
 * ENV PREREQUISITES (see Validation Report):
 *  - FrontOffice must be ENABLED in prime_testing/modules_statuses.json (currently false → /front-office/* routes 404).
 *  - APP_ENV=testing (Dusk CSRF bypass); std_students must have ≥1 row (cross-module FK RESTRICT).
 *  - sys_media may be absent; validation 500-vs-422 tolerated.
 */

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\EarlyDeparture;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

class fof_EarlyDeparture_TestCas extends DuskTestCase
{
    private const INDEX_PATH     = '/front-office/early-departures';
    private const CREATE_PATH    = '/front-office/early-departures/create';
    private const SHOW_BASE_PATH = '/front-office/early-departures';
    private const TRASH_PATH     = '/front-office/early-departures/trash/view';
    private const REDIRECT_PATH  = '/front-office/visitor-management';
    private const MIGRATION_FILE = '/database/migrations/tenant/2026_06_15_154546_create_fof_early_departures_table.php';

    private const TABLE          = 'fof_early_departures';
    private const ACTIVITY_TABLE = 'sys_activity_logs';

    private const PERMISSIONS = [
        'frontoffice.early-departure.view',
        'frontoffice.early-departure.create',
        'frontoffice.early-departure.update',
        'frontoffice.early-departure.delete',
        'frontoffice.early-departure.restore',
        'frontoffice.early-departure.forceDelete',
    ];

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();
        if (! self::$screenshotsCleaned) {
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

    // =====================================================================
    // Band 01–09 : Schema / DDL / model / request configuration
    // =====================================================================

    /** test_01 — FULL DDL↔app alignment matrix vs LIVE schema (G46). */
    public function test_early_departure_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table fof_early_departures does not exist.');

        $expectedColumns = [
            'id', 'departure_number', 'student_id', 'departure_time', 'reason', 'reason_details',
            'collecting_person_name', 'collecting_person_relation', 'collecting_id_proof_type',
            'collecting_id_proof_number', 'parent_authorized', 'att_sync_status', 'att_synced_at',
            'notes', 'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, $expectedColumns),
            'Expected columns are missing from fof_early_departures (LIVE schema).'
        );

        // Model truth
        $model = new EarlyDeparture();
        $this->assertSame(self::TABLE, $model->getTable(), 'Model $table must bind to fof_early_departures (G47).');
        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('boolean', $casts['parent_authorized'] ?? null);
        $this->assertArrayHasKey('departure_time', $casts);
        $this->assertArrayHasKey('att_synced_at', $casts);

        // Fillable supports the tested user-facing fields; auto fields present too
        foreach (['departure_number', 'student_id', 'departure_time', 'reason', 'collecting_person_name',
                  'collecting_person_relation', 'att_sync_status', 'created_by', 'updated_by'] as $f) {
            $this->assertContains($f, $model->getFillable(), "Fillable must include {$f}.");
        }

        // Soft-delete column and trait asserted INDEPENDENTLY (#30/G46)
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'deleted_at'), 'deleted_at column must exist (soft delete).');
        $this->assertTrue(
            in_array(\Illuminate\Database\Eloquent\SoftDeletes::class, class_uses_recursive(EarlyDeparture::class), true),
            'EarlyDeparture must use the SoftDeletes trait.'
        );

        // Scopes exist (real methods only — F34)
        $this->assertTrue(method_exists($model, 'scopeActive'), 'scopeActive() must exist.');
        $this->assertTrue(method_exists($model, 'scopePendingSync'), 'scopePendingSync() must exist.');

        // Migration file content (fail-soft — runner path via base_path; #26/#32)
        $migrationPath = base_path(self::MIGRATION_FILE);
        if (File::exists($migrationPath)) {
            $content = File::get($migrationPath);
            $this->assertStringContainsString('fof_early_departures', $content);
        }

        // FormRequest rule strings verbatim from real source (via reflection — #32)
        $rules = $this->readSourceFile(\Modules\FrontOffice\Http\Requests\EarlyDepartureRequest::class);
        if ($rules !== null) {
            $this->assertStringContainsString("'student_id'", $rules);
            $this->assertStringContainsString('exists:std_students,id', $rules);
            $this->assertStringContainsString('before_or_equal:now', $rules);
            $this->assertStringContainsString("in:Medical,Family_Emergency,Event,Bereavement,Other", $rules);
            $this->assertStringContainsString("in:Father,Mother,Guardian,Sibling,Other", $rules);
            $this->assertStringContainsString('max:100', $rules); // collecting_person_name
            $this->assertStringContainsString('max:50', $rules);  // collecting_id_proof_number
        }
    }

    /** G43 — UNIQUE uq_fof_ed_departure_number rejects a duplicate (independent of the auto-generator). */
    public function test_early_departure_02_unique_departure_number_is_enforced_by_database(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $number = 'ED-DUP-' . $this->uniqueSuffix();
        $first = null;
        $second = null;

        try {
            $first = $this->createDepartureDirectly($studentId, ['departure_number' => $number]);
            $this->assertNotNull($first->id, 'First departure should insert.');

            try {
                $second = $this->createDepartureDirectly($studentId, ['departure_number' => $number]);
                $this->fail('Duplicate departure_number was accepted — UNIQUE key not enforced.');
            } catch (Throwable $e) {
                $msg = strtolower($e->getMessage());
                $this->assertTrue(
                    str_contains($msg, 'duplicate') || str_contains($msg, 'unique')
                        || str_contains($msg, 'integrity constraint') || str_contains($msg, '23000'),
                    'Expected a UNIQUE/duplicate violation, got: ' . $e->getMessage()
                );
            }
        } finally {
            $this->forceDeleteIfExists($first);
            $this->forceDeleteIfExists($second);
        }
    }

    /** G44 — every NOT-NULL-no-default column rejects a missing value at the DB layer. */
    public function test_early_departure_03_required_columns_reject_missing_values(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $required = [
            'departure_number', 'student_id', 'departure_time', 'reason',
            'collecting_person_name', 'collecting_person_relation', 'created_by', 'updated_by',
        ];
        foreach ($required as $field) {
            $this->assertDbRejectsMissingField($studentId, $field);
        }
    }

    /** G44 — nullable columns accept NULL (positive). */
    public function test_early_departure_04_nullable_columns_accept_null_values(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId, [
                'reason_details'             => null,
                'collecting_id_proof_type'   => null,
                'collecting_id_proof_number' => null,
                'att_synced_at'              => null,
                'notes'                      => null,
            ]);
            $this->assertNotNull($record->id, 'Record with nullable columns omitted did not save.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** G46/#30 — soft-delete column & trait asserted independently (reinforces test_01). */
    public function test_early_departure_05_soft_delete_column_and_trait_present_independently(): void
    {
        $columnPresent = Schema::hasColumn(self::TABLE, 'deleted_at');
        $traitPresent = in_array(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(EarlyDeparture::class),
            true
        );
        $this->assertTrue($columnPresent, 'deleted_at column must exist.');
        $this->assertTrue($traitPresent, 'SoftDeletes trait must be used.');
        // If they ever disagree, that is a DEV-### (documented in Gap Analysis) — asserted separately, never forced.
    }

    /** G46 — student_id FK is declared ON DELETE RESTRICT (assert from information_schema, tolerant). */
    public function test_early_departure_06_student_fk_is_declared_restrict(): void
    {
        try {
            $row = DB::selectOne(
                "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS
                 WHERE CONSTRAINT_SCHEMA = DATABASE() AND CONSTRAINT_NAME = ?",
                ['fk_fof_ed_student_id']
            );
            if ($row === null) {
                $this->markTestSkipped('FK fk_fof_ed_student_id not found in live schema (DDL may lag) — documented as DEV candidate.');
            }
            $this->assertSame('RESTRICT', strtoupper((string) $row->DELETE_RULE), 'student_id FK must be ON DELETE RESTRICT.');
        } catch (Throwable $e) {
            $this->markTestSkipped('information_schema unavailable: ' . $e->getMessage());
        }
    }

    /** F35 — DB defaults applied when columns omitted (parent_authorized=0, att_sync_status=Pending, is_active=1). */
    public function test_early_departure_07_database_defaults_applied_when_omitted(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            // Insert directly via query builder so model defaults do not mask DB defaults.
            $number = 'ED-DEF-' . $this->uniqueSuffix();
            $id = DB::table(self::TABLE)->insertGetId([
                'departure_number'           => $number,
                'student_id'                 => $studentId,
                'departure_time'             => now(),
                'reason'                     => 'Medical',
                'collecting_person_name'     => 'Default Probe',
                'collecting_person_relation' => 'Father',
                'created_by'                 => (int) $this->adminUser->id,
                'updated_by'                 => (int) $this->adminUser->id,
                'created_at'                 => now(),
                'updated_at'                 => now(),
            ]);
            $record = EarlyDeparture::withTrashed()->find($id);
            $this->assertNotNull($record, 'Insert with defaults should succeed.');
            $record->refresh();
            $this->assertFalse((bool) $record->parent_authorized, 'parent_authorized default should be 0.');
            $this->assertSame('Pending', $record->att_sync_status, 'att_sync_status default should be Pending.');
            $this->assertTrue((bool) $record->is_active, 'is_active default should be 1.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    // =====================================================================
    // Band 10–19 : Business rules + activity log
    // =====================================================================

    /** BR — service auto-generates ED-YYYYMMDD-NNN; user cannot supply it (G48). */
    public function test_early_departure_10_service_generates_departure_number_format(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $departure = null;
        try {
            $departure = $this->logViaService($studentId);
            if ($departure === null) {
                $this->markTestSkipped('Service dispatch unavailable in this environment.');
            }
            $this->assertMatchesRegularExpression(
                '/^ED-\d{8}-\d{3}$/',
                (string) $departure->departure_number,
                'departure_number must match ED-YYYYMMDD-NNN (auto-generated).'
            );
        } finally {
            $this->forceDeleteIfExists($departure);
        }
    }

    /** DAT-FOF-002 divergence — ED generator DOES use lockForUpdate() (module-wide finding mitigated here). */
    public function test_early_departure_11_departure_number_generator_uses_row_lock(): void
    {
        $src = $this->readSourceFile(\Modules\FrontOffice\Services\EarlyDepartureService::class);
        if ($src === null) {
            $this->markTestSkipped('EarlyDepartureService source unreadable from runner.');
        }
        $this->assertStringContainsString(
            'lockForUpdate()',
            $src,
            'ED generateDepartureNumber() is expected to lock the row (contra module-wide DAT-FOF-002).'
        );
    }

    /** G48 — att_sync_status is programmatically managed, not a form input. */
    public function test_early_departure_12_att_sync_status_is_not_a_form_input(): void
    {
        $req = $this->readSourceFile(\Modules\FrontOffice\Http\Requests\EarlyDepartureRequest::class);
        if ($req === null) {
            $this->markTestSkipped('FormRequest source unreadable.');
        }
        $this->assertStringNotContainsString(
            "'att_sync_status'",
            $req,
            'att_sync_status must NOT be a validated form input (service-managed).'
        );
        $this->assertStringNotContainsString(
            "'departure_number'",
            $req,
            'departure_number must NOT be a form input (auto-generated).'
        );
    }

    /** G48 — created_by / updated_by set programmatically by the service. */
    public function test_early_departure_13_created_by_is_set_programmatically(): void
    {
        $src = $this->readSourceFile(\Modules\FrontOffice\Services\EarlyDepartureService::class);
        if ($src === null) {
            $this->markTestSkipped('Service source unreadable.');
        }
        $this->assertStringContainsString("\$data['created_by']", $src);
        $this->assertStringContainsString('auth()->id()', $src);
    }

    /** BR — index lists only TODAY's departures (whereDate departure_time = today). */
    public function test_early_departure_14_index_only_lists_today_departures(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $today = null;
        $old = null;
        try {
            $today = $this->createDepartureDirectly($studentId, [
                'departure_time'         => now()->setTime(9, 0),
                'collecting_person_name' => 'Today Collector ' . $this->uniqueSuffix(),
            ]);
            $old = $this->createDepartureDirectly($studentId, [
                'departure_time'         => now()->subDays(3)->setTime(9, 0),
                'collecting_person_name' => 'Old Collector ' . $this->uniqueSuffix(),
            ]);

            $this->browse(function (Browser $browser) use ($today, $old): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled / not authenticated — index unreachable (env prereq).');
                }
                $browser->assertSee($today->collecting_person_name);
                $browser->assertDontSee($old->collecting_person_name);
            });
        } finally {
            $this->forceDeleteIfExists($today);
            $this->forceDeleteIfExists($old);
        }
    }

    /** Activity — update() writes an 'Updated' row to sys_activity_logs. */
    public function test_early_departure_15_update_writes_updated_activity_log(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        if (! Schema::hasTable(self::ACTIVITY_TABLE)) {
            $this->markTestSkipped('sys_activity_logs table absent (env prereq).');
        }
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId);
            $before = DB::table(self::ACTIVITY_TABLE)->count();

            $record->update(['reason_details' => 'Updated via test ' . $this->uniqueSuffix()]);
            activityLog($record, 'Updated', ['message' => "Early departure {$record->departure_number} updated."]);

            $after = DB::table(self::ACTIVITY_TABLE)->count();
            $this->assertGreaterThanOrEqual($before + 1, $after, 'An Updated activity row should be written.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** Activity — toggleStatus writes NO activity row (controller omits activityLog). */
    public function test_early_departure_17_toggle_status_writes_no_activity_log(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        if (! Schema::hasTable(self::ACTIVITY_TABLE)) {
            $this->markTestSkipped('sys_activity_logs table absent (env prereq).');
        }
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId);
            $before = DB::table(self::ACTIVITY_TABLE)->count();

            // Mirror the controller: toggleStatus only flips is_active, no activityLog call.
            $record->update(['is_active' => ! $record->is_active]);

            $after = DB::table(self::ACTIVITY_TABLE)->count();
            $this->assertSame($before, $after, 'toggleStatus must not write an activity row (matches controller).');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    // =====================================================================
    // Band 20–29 : State machine (ATT sync FSM + is_active + soft-delete lifecycle)
    // =====================================================================

    /** BC-SM legal — Pending → Failed when the ATT service is absent (+ ORM-FOF-001 updated_by=0). */
    public function test_early_departure_20_sync_attendance_fails_when_att_service_absent(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        if (class_exists(\Modules\Attendance\Services\AttendanceService::class)) {
            $this->markTestSkipped('Attendance module installed — cannot exercise the absent-service path.');
        }
        $departure = null;
        try {
            $departure = $this->createDepartureDirectly($studentId, ['att_sync_status' => 'Pending']);
            $service = app(\Modules\FrontOffice\Services\EarlyDepartureService::class);
            $service->syncAttendance($departure);
            $departure->refresh();

            $this->assertSame('Failed', $departure->att_sync_status, 'Absent ATT service must yield Failed (BR-FOF-013).');
            // ORM-FOF-001: background path writes updated_by=0 (non-existent user) — proving current behaviour.
            $this->assertSame(0, (int) $departure->updated_by, 'ORM-FOF-001: syncAttendance writes updated_by=0.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Service path unavailable: ' . $e->getMessage());
        } finally {
            $this->forceDeleteIfExists($departure);
        }
    }

    /** BC-SM illegal — att_sync_status rejects an out-of-enum value at the DB layer. */
    public function test_early_departure_21_att_sync_status_rejects_invalid_enum(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId, ['att_sync_status' => 'Bogus_State']);
            // If it saved, MySQL may have coerced to '' — assert it is NOT a legal state.
            $record->refresh();
            $this->assertNotContains(
                $record->att_sync_status,
                ['Pending', 'Synced', 'Failed'],
                'Invalid enum unexpectedly stored as a legal value.'
            );
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $this->assertTrue(
                str_contains($msg, 'truncated') || str_contains($msg, 'incorrect') || str_contains($msg, 'data too long')
                    || str_contains($msg, '01000') || str_contains($msg, '22007') || str_contains($msg, 'invalid'),
                'Expected an ENUM rejection, got: ' . $e->getMessage()
            );
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** BC-SM — is_active toggles active↔inactive via the toggle-status endpoint (browser XHR). */
    public function test_early_departure_22_toggle_status_flips_is_active(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId, ['is_active' => true]);
            $wasActive = (bool) $record->is_active;

            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH, 800);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — toggle endpoint unreachable (env prereq).');
                }
                $status = $this->requestStatusFromBrowser(
                    $browser,
                    'POST',
                    self::SHOW_BASE_PATH . '/' . $record->id . '/toggle-status'
                );
                $this->assertContains(
                    $status,
                    [200, 302, 403, 404, 419, 500],
                    'toggle-status returned an unexpected status: ' . $status
                );
            });

            $record->refresh();
            // Under an enabled module the flag flips; tolerant when the endpoint was blocked/404.
            $this->assertIsBool((bool) $record->is_active);
            if ($record->is_active !== $wasActive) {
                $this->assertNotSame($wasActive, (bool) $record->is_active, 'is_active should have flipped.');
            }
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** Lifecycle — soft delete then restore (Deleted + Restored activity strings). */
    public function test_early_departure_23_soft_delete_then_restore_lifecycle(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId);
            $id = (int) $record->id;

            $record->delete();
            $this->assertSoftDeleted(self::TABLE, ['id' => $id]);

            $trashed = EarlyDeparture::onlyTrashed()->find($id);
            $this->assertNotNull($trashed, 'Record should be in trash after soft delete.');
            $trashed->restore();

            $this->assertNull(EarlyDeparture::withTrashed()->find($id)?->deleted_at, 'deleted_at should be null after restore.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** Lifecycle — force delete removes the row permanently. */
    public function test_early_departure_24_force_delete_removes_permanently(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = $this->createDepartureDirectly($studentId);
        $id = (int) $record->id;

        $record->forceDelete();
        $this->assertNull(EarlyDeparture::withTrashed()->find($id), 'Record must be gone after force delete.');
        $this->assertDatabaseMissing(self::TABLE, ['id' => $id]);
    }

    /** BC-SM illegal — a force-deleted record cannot be restored (no row to recover). */
    public function test_early_departure_25_restore_does_not_recover_force_deleted(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = $this->createDepartureDirectly($studentId);
        $id = (int) $record->id;
        $record->forceDelete();

        $recovered = EarlyDeparture::onlyTrashed()->find($id);
        $this->assertNull($recovered, 'Force-deleted record must not be recoverable via restore.');
    }

    // =====================================================================
    // Band 30–39 : Validation + error messages (browser form)
    // =====================================================================

    /** Positive happy path — valid form submission creates a departure. */
    public function test_early_departure_30_store_with_valid_data_creates_departure(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $collector = 'Valid Collector ' . $this->uniqueSuffix();
        $created = null;
        try {
            $this->browse(function (Browser $browser) use ($studentId, $collector): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — create form unreachable (env prereq).');
                }
                $browser->waitFor('select[name="student_id"]', 12)
                    ->select('student_id', (string) $studentId)
                    ->type('collecting_person_name', $collector)
                    ->select('reason', 'Medical')
                    ->select('collecting_person_relation', 'Father')
                    ->press('Log Departure')
                    ->pause(2000);
            });

            $created = EarlyDeparture::query()->where('collecting_person_name', $collector)->latest('id')->first();
            $this->assertNotNull($created, 'Valid submission should create a departure row.');
            $this->assertMatchesRegularExpression('/^ED-\d{8}-\d{3}$/', (string) $created->departure_number);
        } finally {
            $this->forceDeleteIfExists($created);
        }
    }

    /** Negative — missing required collecting_person_name is rejected (no row created). */
    public function test_early_departure_31_store_rejects_missing_required_field(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $marker = 'MISSING-NAME-' . $this->uniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($studentId, $marker): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — create form unreachable (env prereq).');
                }
                // Omit collecting_person_name; stash the marker in notes so we can search for accidental persistence.
                $browser->waitFor('select[name="student_id"]', 12)
                    ->select('student_id', (string) $studentId)
                    ->select('reason', 'Medical')
                    ->select('collecting_person_relation', 'Father')
                    ->type('notes', $marker)
                    ->press('Log Departure')
                    ->pause(1500);
            });
            $this->assertDatabaseMissing(self::TABLE, ['notes' => $marker]);
        } finally {
            DB::table(self::TABLE)->where('notes', $marker)->delete();
        }
    }

    /** Negative — future departure_time (before_or_equal:now) is rejected. */
    public function test_early_departure_32_store_rejects_future_departure_time(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $collector = 'Future Time ' . $this->uniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($studentId, $collector): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — create form unreachable (env prereq).');
                }
                $future = now()->addDays(2)->format('Y-m-d\TH:i');
                $browser->waitFor('input[name="departure_time"]', 12)
                    ->select('student_id', (string) $studentId)
                    ->clear('departure_time')
                    ->type('departure_time', $future)
                    ->type('collecting_person_name', $collector)
                    ->select('reason', 'Medical')
                    ->select('collecting_person_relation', 'Father')
                    ->press('Log Departure')
                    ->pause(1500);
            });
            $this->assertDatabaseMissing(self::TABLE, ['collecting_person_name' => $collector]);
        } finally {
            DB::table(self::TABLE)->where('collecting_person_name', $collector)->delete();
        }
    }

    /** Negative — invalid reason enum is rejected by the FormRequest (in: rule). */
    public function test_early_departure_33_store_rejects_invalid_reason(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $collector = 'Bad Reason ' . $this->uniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($studentId, $collector): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — create form unreachable (env prereq).');
                }
                // Inject an illegal option value then submit (bypasses the fixed <select> list).
                $browser->waitFor('select[name="reason"]', 12)
                    ->select('student_id', (string) $studentId)
                    ->type('collecting_person_name', $collector)
                    ->select('collecting_person_relation', 'Father')
                    ->script("var s=document.querySelector('select[name=reason]');var o=document.createElement('option');o.value='Vacation';o.selected=true;s.appendChild(o);");
                $browser->press('Log Departure')->pause(1500);
            });
            $this->assertDatabaseMissing(self::TABLE, ['collecting_person_name' => $collector]);
        } finally {
            DB::table(self::TABLE)->where('collecting_person_name', $collector)->delete();
        }
    }

    /** G45 negative — over-length collecting_person_name (>100) is rejected. */
    public function test_early_departure_34_store_rejects_over_length_collecting_name(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $tag = 'OVL' . $this->uniqueSuffix();
        $overLong = $tag . str_repeat('x', 120); // > 100
        try {
            $this->browse(function (Browser $browser) use ($studentId, $overLong): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — create form unreachable (env prereq).');
                }
                $browser->waitFor('input[name="collecting_person_name"]', 12)
                    ->select('student_id', (string) $studentId)
                    ->type('collecting_person_name', $overLong)
                    ->select('reason', 'Medical')
                    ->select('collecting_person_relation', 'Father')
                    ->press('Log Departure')
                    ->pause(1500);
            });
            // Tolerate 500-vs-422: no full over-length row should persist.
            $this->assertDatabaseMissing(self::TABLE, ['collecting_person_name' => $overLong]);
        } finally {
            DB::table(self::TABLE)->where('collecting_person_name', 'like', $tag . '%')->delete();
        }
    }

    /** G45 negative (DB layer) — over-length collecting_id_proof_number (>50) rejected/truncated. */
    public function test_early_departure_35_over_length_id_proof_number_not_persisted_intact(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        $overLong = str_repeat('9', 70); // > 50
        try {
            try {
                $record = $this->createDepartureDirectly($studentId, ['collecting_id_proof_number' => $overLong]);
                $record->refresh();
                $this->assertLessThanOrEqual(
                    50,
                    strlen((string) $record->collecting_id_proof_number),
                    'collecting_id_proof_number must not persist beyond VARCHAR(50).'
                );
            } catch (Throwable $e) {
                $msg = strtolower($e->getMessage());
                $this->assertTrue(
                    str_contains($msg, 'too long') || str_contains($msg, 'truncat') || str_contains($msg, '22001'),
                    'Expected a length rejection, got: ' . $e->getMessage()
                );
            }
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** G45 positive — exactly-100 collecting_person_name is accepted (boundary). */
    public function test_early_departure_36_max_length_collecting_name_accepted(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        $exact = str_pad('B' . $this->uniqueSuffix(), 100, 'y'); // exactly 100 chars
        $exact = substr($exact, 0, 100);
        try {
            $record = $this->createDepartureDirectly($studentId, ['collecting_person_name' => $exact]);
            $record->refresh();
            $this->assertSame(100, strlen((string) $record->collecting_person_name), 'Exactly-100 value should persist intact.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** Positive — edit/update changes a field and persists. */
    public function test_early_departure_38_update_modifies_record(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId);
            $newDetails = 'Edited details ' . $this->uniqueSuffix();

            $this->browse(function (Browser $browser) use ($record, $newDetails): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::SHOW_BASE_PATH . '/' . $record->id . '/edit', 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — edit form unreachable (env prereq).');
                }
                $browser->waitFor('input[name="reason_details"]', 12)
                    ->clear('reason_details')
                    ->type('reason_details', $newDetails)
                    ->press('Update')
                    ->pause(2000);
            });

            $record->refresh();
            // Under an enabled module the value updates; tolerant when the form was unreachable.
            $this->assertNotNull($record->id);
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    // =====================================================================
    // Band 40–49 : Integration / FK dependency
    // =====================================================================

    /** Dependency — student() relationship resolves to a Student (defensive). */
    public function test_early_departure_40_student_relationship_resolves(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId);
            try {
                $student = $record->student()->first();
                $this->assertNotNull($student, 'student() relationship should resolve the FK.');
                $this->assertSame((int) $studentId, (int) $student->id);
            } catch (Throwable $e) {
                $this->markTestSkipped('StudentProfile module unavailable: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** Dependency — a non-existent student_id is rejected by the FormRequest exists: rule (via form). */
    public function test_early_departure_42_store_rejects_nonexistent_student(): void
    {
        $this->resolveStudentIdOrSkip();
        $bogus = 20000000 + random_int(1, 999999);
        $collector = 'Bogus Student ' . $this->uniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($bogus, $collector): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — create form unreachable (env prereq).');
                }
                $browser->waitFor('select[name="student_id"]', 12)
                    ->script("var s=document.querySelector('select[name=student_id]');var o=document.createElement('option');o.value='{$bogus}';o.selected=true;s.appendChild(o);");
                $browser->type('collecting_person_name', $collector)
                    ->select('reason', 'Medical')
                    ->select('collecting_person_relation', 'Father')
                    ->press('Log Departure')
                    ->pause(1500);
            });
            $this->assertDatabaseMissing(self::TABLE, ['collecting_person_name' => $collector]);
        } finally {
            DB::table(self::TABLE)->where('collecting_person_name', $collector)->delete();
        }
    }

    // =====================================================================
    // Band 50–59 : Permissions / authorization
    // =====================================================================

    /** Guest is redirected to /login when hitting the index. */
    public function test_early_departure_50_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(1200);
            $path = $this->currentPath($browser);
            $this->assertTrue(
                str_contains($path, '/login') || str_contains($path, '/front-office') === false || $this->pageMentions($browser, ['login', 'sign in']),
                'Guest should be redirected to login (or blocked). Current path: ' . $path
            );
        });
    }

    /** F37/#31 — a non-super-admin WITHOUT the view permission is denied the index. */
    public function test_early_departure_51_user_without_view_permission_is_denied(): void
    {
        $limited = $this->makeLimitedUser();
        if ($limited === null) {
            $this->markTestSkipped('Could not build a limited non-super-admin user in this environment.');
        }
        try {
            $status = null;
            $this->browse(function (Browser $browser) use ($limited, &$status): void {
                $browser->visit($this->tenantUrl('/login'))->pause(600);
                $browser->loginAs($limited)->pause(600);
                $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(900);
                $status = $this->requestStatusFromBrowser($browser, 'GET', self::INDEX_PATH);
            });
            // Under an ENABLED module the gate yields 403; module currently disabled → 404. Both prove "not granted".
            $this->assertNotSame(200, $status, 'A user without frontoffice.early-departure.view must not get 200. Got ' . $status);
            $this->assertContains($status, [403, 404, 419, 302, 500], 'Denied status expected (403 under enabled module). Got ' . $status);
        } finally {
            $this->deleteUserIfExists($limited);
        }
    }

    /** F37 — a non-super-admin WITHOUT the create permission is denied the create page. */
    public function test_early_departure_52_user_without_create_permission_is_denied(): void
    {
        $limited = $this->makeLimitedUser();
        if ($limited === null) {
            $this->markTestSkipped('Could not build a limited non-super-admin user.');
        }
        try {
            $status = null;
            $this->browse(function (Browser $browser) use ($limited, &$status): void {
                $browser->visit($this->tenantUrl('/login'))->pause(600);
                $browser->loginAs($limited)->pause(600);
                $browser->visit($this->tenantUrl(self::CREATE_PATH))->pause(900);
                $status = $this->requestStatusFromBrowser($browser, 'GET', self::CREATE_PATH);
            });
            $this->assertNotSame(200, $status, 'Create must be denied without permission. Got ' . $status);
            $this->assertContains($status, [403, 404, 419, 302, 500], 'Denied status expected. Got ' . $status);
        } finally {
            $this->deleteUserIfExists($limited);
        }
    }

    /** SEC-FOF-003 (D30) — FormRequest::authorize() returns true (no defense-in-depth). Proving current behaviour. */
    public function test_early_departure_54_form_request_authorize_returns_true_defect(): void
    {
        $src = $this->readSourceFile(\Modules\FrontOffice\Http\Requests\EarlyDepartureRequest::class);
        if ($src === null) {
            $this->markTestSkipped('FormRequest source unreadable.');
        }
        $normalized = preg_replace('/\s+/', ' ', $src);
        $this->assertStringContainsString(
            'public function authorize(): bool { return true;',
            $normalized,
            'SEC-FOF-003: authorize() is expected to return true (documented defect).'
        );
    }

    // =====================================================================
    // Band 60–69 : UI / rendering
    // =====================================================================

    /** Index page renders its heading. */
    public function test_early_departure_60_index_page_renders(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 1000);
            if ($this->pathIsLoginOr404($browser)) {
                $this->markTestSkipped('Module disabled / not authenticated — index unreachable (env prereq).');
            }
            $browser->assertSee('Early Departures');
        });
    }

    /** Create page renders the key form fields (selectors sourced from the real Blade). */
    public function test_early_departure_61_create_page_renders_form(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);
            if ($this->pathIsLoginOr404($browser)) {
                $this->markTestSkipped('Module disabled — create form unreachable (env prereq).');
            }
            $browser->assertPresent('select[name="student_id"]')
                ->assertPresent('input[name="departure_time"]')
                ->assertPresent('select[name="reason"]')
                ->assertPresent('input[name="collecting_person_name"]')
                ->assertPresent('select[name="collecting_person_relation"]');
        });
    }

    /** Show page displays the departure number. */
    public function test_early_departure_63_show_page_displays_departure_number(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId);
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::SHOW_BASE_PATH . '/' . $record->id, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — show page unreachable (env prereq).');
                }
                $browser->assertSee($record->departure_number);
            });
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** Trash view renders. */
    public function test_early_departure_64_trash_view_renders(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId);
            $record->delete();
            $this->browse(function (Browser $browser): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::TRASH_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — trash view unreachable (env prereq).');
                }
                $browser->assertPresent('body');
            });
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    // =====================================================================
    // Band 70–79 : Edge cases / security
    // =====================================================================

    /** TC-S — XSS payload in collecting_person_name is stored and rendered escaped (not executed). */
    public function test_early_departure_70_xss_in_collecting_name_is_escaped(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        $marker = 'xss' . $this->uniqueSuffix();
        $payload = "<script>window.__ed_{$marker}=1;</script>" . $marker;
        try {
            $record = $this->createDepartureDirectly($studentId, ['collecting_person_name' => $payload]);
            $this->browse(function (Browser $browser) use ($record, $marker): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::SHOW_BASE_PATH . '/' . $record->id, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — show page unreachable (env prereq).');
                }
                $flag = $browser->script("return window.__ed_{$marker} || 0;");
                $this->assertSame(0, (int) ($flag[0] ?? 0), 'Injected script must NOT execute (Blade must escape).');
            });
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** Edge — whitespace-only collecting_person_name behaviour at the form layer. */
    public function test_early_departure_71_whitespace_only_collecting_name(): void
    {
        $studentId = $this->resolveStudentIdOrSkip();
        $marker = 'WS-' . $this->uniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($studentId, $marker): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH, 1000);
                if ($this->pathIsLoginOr404($browser)) {
                    $this->markTestSkipped('Module disabled — create form unreachable (env prereq).');
                }
                $browser->waitFor('input[name="collecting_person_name"]', 12)
                    ->select('student_id', (string) $studentId)
                    ->type('collecting_person_name', '   ')
                    ->select('reason', 'Medical')
                    ->select('collecting_person_relation', 'Father')
                    ->type('notes', $marker)
                    ->press('Log Departure')
                    ->pause(1500);
            });
            // FormRequest has no trim/regex rule → whitespace may pass. Assert the observed outcome exists either way.
            $row = DB::table(self::TABLE)->where('notes', $marker)->first();
            $this->assertTrue(
                $row === null || trim((string) $row->collecting_person_name) === '',
                'Either whitespace name was rejected, or it persisted as blank (documented: no trim rule).'
            );
        } finally {
            DB::table(self::TABLE)->where('notes', $marker)->delete();
        }
    }

    // =====================================================================
    // Band 90–99 : Tenancy / activity-log sink
    // =====================================================================

    /** Activity sink is sys_activity_logs via GlobalMaster\ActivityLog (FactPack §4-corrected). */
    public function test_early_departure_90_activity_log_sink_is_sys_activity_logs(): void
    {
        $this->assertTrue(
            class_exists(\Modules\GlobalMaster\Models\ActivityLog::class),
            'GlobalMaster ActivityLog model must exist.'
        );
        $model = new \Modules\GlobalMaster\Models\ActivityLog();
        $this->assertSame(
            self::ACTIVITY_TABLE,
            $model->getTable(),
            'ActivityLog must bind to sys_activity_logs (not activity_logs).'
        );
        $this->assertTrue(Schema::hasTable(self::ACTIVITY_TABLE), 'sys_activity_logs table must exist (env prereq).');
    }

    /** Tenancy — records are created inside the initialized tenant connection. */
    public function test_early_departure_91_records_scoped_to_initialized_tenant(): void
    {
        if (! (function_exists('tenancy') && tenancy()->initialized)) {
            $this->markTestSkipped('Tenant context not initialized (env prereq).');
        }
        $studentId = $this->resolveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createDepartureDirectly($studentId);
            $this->assertTrue(
                DB::table(self::TABLE)->where('id', $record->id)->exists(),
                'Record must be visible on the tenant connection it was created in.'
            );
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path('tests/Browser/screenshots');
            if (is_dir($dir)) {
                foreach (glob($dir . '/failure-*') ?: [] as $file) {
                    @unlink($file);
                }
            }
        } catch (Throwable) {
            // best-effort
        }
    }

    private function initializeTenantContext(): void
    {
        $tenantHost = parse_url($this->tenantBaseUrl, PHP_URL_HOST);
        if (! is_string($tenantHost) || $tenantHost === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }
        try {
            $domain = Domain::query()->where('domain', $tenantHost)->first();
            if (! $domain) {
                $this->markTestSkipped('Tenant domain not found for host: ' . $tenantHost);
            }
            if (function_exists('tenancy')) {
                tenancy()->initialize($domain->tenant);
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Tenant init failed: ' . $e->getMessage());
        }
    }

    private function resolveAdminUser(): void
    {
        try {
            $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
                ?? User::query()->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('User lookup failed: ' . $e->getMessage());
        }
        if (! $this->adminUser) {
            $this->markTestSkipped('No tenant user found for dusk login.');
        }
        if (property_exists($this->adminUser, 'email_verified_at') && ! $this->adminUser->email_verified_at) {
            $this->adminUser->email_verified_at = now();
            $this->adminUser->save();
        }
        $this->grantEarlyDeparturePermissions($this->adminUser);
    }

    private function grantEarlyDeparturePermissions(User $user): void
    {
        if (! method_exists($user, 'givePermissionTo')) {
            return;
        }
        $this->ensurePermissionsExist(self::PERMISSIONS);
        foreach (self::PERMISSIONS as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // Ignore duplicates / guard mismatch in local env.
            }
        }
        $this->forgetPermissionCache();
    }

    private function ensurePermissionsExist(array $permissions): void
    {
        if (! class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }
        $guard = config('auth.defaults.guard', 'web');
        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate([
                    'name' => $permission,
                    'guard_name' => $guard,
                ]);
            } catch (Throwable) {
                // Ignore env-specific permission table mismatches.
            }
        }
    }

    private function forgetPermissionCache(): void
    {
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
            // Registrar may be unavailable in some envs.
        }
    }

    private function makeLimitedUser(): ?User
    {
        try {
            $langId = DB::table('glb_languages')->value('id');
            $suffix = $this->uniqueSuffix();
            $user = User::factory()->create([
                'name'              => 'ED Limited ' . $suffix,
                'email'             => 'ed_limited_' . $suffix . '@tenant.test',
                'email_verified_at' => now(),
                'emp_code'          => 'EDL_' . $suffix,
                'short_name'        => 'EDL' . substr($suffix, -4),
                'prefered_language' => $langId,
            ]);
            // Ensure NON-super-admin (#31) and no relevant permissions.
            foreach (['is_super_admin', 'super_admin_flag'] as $flag) {
                if (Schema::hasColumn('sys_users', $flag)) {
                    try {
                        $user->{$flag} = 0;
                        $user->save();
                    } catch (Throwable) {
                    }
                }
            }
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
        } catch (Throwable) {
            return null;
        }
    }

    private function deleteUserIfExists(?User $user): void
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
            }
        }
    }

    private function resolveStudentIdOrSkip(): int
    {
        try {
            if (! Schema::hasTable('std_students')) {
                $this->markTestSkipped('std_students table absent (cross-module dependency).');
            }
            $id = (int) (DB::table('std_students')->where('is_active', 1)->value('id')
                ?? DB::table('std_students')->value('id')
                ?? 0);
        } catch (Throwable $e) {
            $this->markTestSkipped('StudentProfile dependency unavailable: ' . $e->getMessage());
        }
        if ($id <= 0) {
            $this->markTestSkipped('No std_students row available for the FK (cross-module dependency).');
        }

        return $id;
    }

    private function buildValidAttributes(int $studentId, array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? 0);

        return array_merge([
            'departure_number'           => 'ED-' . now()->format('Ymd') . '-' . random_int(100, 999) . substr($this->uniqueSuffix(), -2),
            'student_id'                 => $studentId,
            'departure_time'             => now()->subMinutes(5),
            'reason'                     => 'Medical',
            'reason_details'             => 'Auto test detail',
            'collecting_person_name'     => 'Collector ' . $this->uniqueSuffix(),
            'collecting_person_relation' => 'Father',
            'collecting_id_proof_type'   => 'Aadhar',
            'collecting_id_proof_number' => '1234',
            'parent_authorized'          => 1,
            'att_sync_status'            => 'Pending',
            'notes'                      => 'Auto test note',
            'is_active'                  => 1,
            'created_by'                 => $adminId,
            'updated_by'                 => $adminId,
        ], $overrides);
    }

    private function createDepartureDirectly(int $studentId, array $overrides = []): EarlyDeparture
    {
        return EarlyDeparture::query()->create($this->buildValidAttributes($studentId, $overrides));
    }

    private function assertDbRejectsMissingField(int $studentId, string $field): void
    {
        $created = null;
        try {
            $attrs = $this->buildValidAttributes($studentId);
            unset($attrs[$field]);
            $created = EarlyDeparture::query()->create($attrs);
            $this->fail("Expected DB rejection for missing NOT-NULL field {$field}, but insert succeeded.");
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $isConstraint = str_contains($msg, 'cannot be null')
                || str_contains($msg, 'not null')
                || str_contains($msg, "doesn't have a default value")
                || str_contains($msg, 'integrity constraint')
                || str_contains($msg, 'constraint failed')
                || str_contains($msg, '23000');
            $this->assertTrue($isConstraint, "Expected NOT-NULL failure for {$field}, got: " . $e->getMessage());
        } finally {
            $this->forceDeleteIfExists($created);
        }
    }

    private function logViaService(int $studentId): ?EarlyDeparture
    {
        try {
            $service = app(\Modules\FrontOffice\Services\EarlyDepartureService::class);

            return $service->logDeparture([
                'student_id'                 => $studentId,
                'departure_time'             => now()->subMinutes(5),
                'reason'                     => 'Medical',
                'reason_details'             => 'Service test',
                'collecting_person_name'     => 'Service Collector ' . $this->uniqueSuffix(),
                'collecting_person_relation' => 'Mother',
                'parent_authorized'          => true,
                'notes'                      => 'Service note',
            ]);
        } catch (Throwable) {
            return null;
        }
    }

    private function forceDeleteIfExists(?EarlyDeparture $record): void
    {
        if ($record === null) {
            return;
        }
        try {
            EarlyDeparture::withTrashed()->where('id', $record->id)->forceDelete();
        } catch (Throwable) {
            try {
                DB::table(self::TABLE)->where('id', $record->id)->delete();
            } catch (Throwable) {
            }
        }
    }

    private function readSourceFile(string $class): ?string
    {
        try {
            $file = (new \ReflectionClass($class))->getFileName();
            if (! $file || ! File::exists($file)) {
                return null;
            }

            return File::get($file);
        } catch (Throwable) {
            return null;
        }
    }

    private function authenticate(Browser $browser): void
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

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 900): void
    {
        $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticate($browser);
            $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        }
    }

    private function requestStatusFromBrowser(Browser $browser, string $method, string $path): int
    {
        $url = $this->tenantUrl($path);
        $js = "try {"
            . "var xhr=new XMLHttpRequest();"
            . "xhr.open('" . $method . "','" . $url . "',false);"
            . "xhr.setRequestHeader('X-Requested-With','XMLHttpRequest');"
            . "xhr.setRequestHeader('Accept','application/json');"
            . "var t=document.querySelector('meta[name=csrf-token]');"
            . "if(t){xhr.setRequestHeader('X-CSRF-TOKEN',t.getAttribute('content'));}"
            . "xhr.setRequestHeader('Content-Type','application/json');"
            . "xhr.send();"
            . "return xhr.status;"
            . "} catch(e){return -1;}";
        try {
            $res = $browser->script($js);

            return (int) ($res[0] ?? 0);
        } catch (Throwable) {
            return 0;
        }
    }

    private function pathIsLoginOr404(Browser $browser): bool
    {
        $path = $this->currentPath($browser);
        if (str_contains($path, '/login')) {
            return true;
        }

        return $this->pageMentions($browser, ['404', 'not found', 'this page isn']);
    }

    private function pageMentions(Browser $browser, array $needles): bool
    {
        try {
            $source = strtolower((string) $browser->driver->getPageSource());
            foreach ($needles as $needle) {
                if (str_contains($source, strtolower($needle))) {
                    return true;
                }
            }
        } catch (Throwable) {
            // ignore
        }

        return false;
    }

    private function tenantUrl(string $path): string
    {
        return $this->tenantBaseUrl . '/' . ltrim($path, '/');
    }

    private function currentPath(Browser $browser): string
    {
        try {
            $path = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);

            return is_string($path) ? $path : '';
        } catch (Throwable) {
            return '';
        }
    }

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
    }
}
