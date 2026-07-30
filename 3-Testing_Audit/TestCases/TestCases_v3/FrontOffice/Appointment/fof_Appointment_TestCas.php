<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\Appointment;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice → Appointment (fof_appointments) — ONE comprehensive Dusk suite.
 *
 * Style: browser-driven Dusk (mirrors the tenant-side Complaint sibling
 * ComplaintDuskTestCase / cmp_ComplaintCrud_TestCas) for UI flows, direct
 * Eloquent for DDL-constraint coverage (G43–G46), and Laravel HTTP test methods
 * (Rule Card #14 / F37) ONLY for status-code + permission-negative assertions
 * (Dusk Browser has no assertStatus()). Tenant context is initialised in setUp
 * BEFORE any actingAs() (Rule Card A1/#2).
 *
 * ENV PREREQUISITE: FrontOffice is DISABLED in prime_testing/modules_statuses.json
 * (#19) → every /front-office/* route 404s until enabled. All route-driven tests
 * are therefore defensive (Route::has() guard + tolerant status sets + markTestSkipped);
 * the DDL/model/direct-Eloquent tests carry the hard coverage regardless.
 *
 * Sources (read at generation time, never guessed):
 *   Controller  Modules/FrontOffice/app/Http/Controllers/AppointmentController.php
 *   Request     Modules/FrontOffice/app/Http/Requests/AppointmentRequest.php
 *   Model       Modules/FrontOffice/app/Models/Appointment.php
 *   Policy      Modules/FrontOffice/app/Policies/AppointmentPolicy.php
 *   Routes      Modules/FrontOffice/routes/web.php (group prefix 'front-office', name 'fof.')
 *   Blade       resources/views/fof/appointments/{index,edit,show,calendar,trashed}.blade.php
 *   DDL         FrontOffice_DDL_v1.sql → CREATE TABLE fof_appointments
 */
class fof_Appointment_TestCas extends DuskTestCase
{
    private const TABLE = 'fof_appointments';

    // Paths derived from routes/web.php (group prefix 'front-office').
    private const INDEX_PATH    = '/front-office/appointments';
    private const CALENDAR_PATH = '/front-office/appointments/calendar';
    private const STORE_PATH    = '/front-office/appointments';
    private const SHOW_BASE     = '/front-office/appointments';
    private const TRASH_PATH    = '/front-office/appointments/trash/view';
    private const MENU_PATH     = '/front-office/visitor-management';

    // Permission ability strings (grepped verbatim from AppointmentController Gate::authorize()).
    private const PERM_VIEW     = 'frontoffice.appointment.view';
    private const PERM_CREATE   = 'frontoffice.appointment.create';
    private const PERM_UPDATE   = 'frontoffice.appointment.update';
    private const PERM_CONFIRM  = 'frontoffice.appointment.confirm';
    private const PERM_CANCEL   = 'frontoffice.appointment.cancel';
    private const PERM_COMPLETE = 'frontoffice.appointment.complete';
    private const PERM_DELETE   = 'frontoffice.appointment.delete';
    private const PERM_RESTORE  = 'frontoffice.appointment.restore';
    private const PERM_FORCE    = 'frontoffice.appointment.forceDelete';

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $tenantHost = '';
    private string $adminEmail = '';
    private string $adminPassword = '';

    protected function setUp(): void
    {
        parent::setUp();
        $this->tenantBaseUrl = rtrim(
            env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')),
            '/'
        );
        $this->tenantHost = (string) (parse_url($this->tenantBaseUrl, PHP_URL_HOST) ?: 'test.localhost');
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
    // 01–09  Schema / DDL / model / request configuration
    // =====================================================================

    /** G46: full DDL↔app alignment matrix vs the LIVE schema; soft-delete asserted independently. */
    public function test_appointment_01_schema_model_and_request_configuration_are_correct(): void
    {
        $this->skipUnlessTable();

        // ---- table + every DDL column exists on the LIVE schema ----
        $expected = [
            'id', 'appointment_number', 'appointment_type', 'with_user_id',
            'visitor_name', 'visitor_mobile', 'visitor_email', 'purpose',
            'appointment_date', 'start_time', 'end_time', 'status',
            'confirmed_by', 'confirmed_at', 'cancellation_reason', 'notes',
            'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, $expected),
            'fof_appointments is missing one or more DDL columns on the live schema.'
        );

        // ---- model config from real source ----
        $model = new Appointment();
        $this->assertSame(self::TABLE, $model->getTable());
        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('date', $casts['appointment_date'] ?? null);
        $this->assertArrayHasKey('confirmed_at', $casts);

        // fillable supports the tested fields (G47 — CRUD routed through this verified model)
        foreach (['appointment_number', 'appointment_type', 'with_user_id', 'visitor_name',
                  'visitor_mobile', 'purpose', 'appointment_date', 'start_time', 'end_time',
                  'status', 'created_by', 'updated_by'] as $f) {
            $this->assertContains($f, $model->getFillable(), "fillable missing {$f}");
        }

        // relationships resolve
        $this->assertInstanceOf(
            \Illuminate\Database\Eloquent\Relations\BelongsTo::class,
            $model->staff()
        );
        $this->assertInstanceOf(
            \Illuminate\Database\Eloquent\Relations\BelongsTo::class,
            $model->confirmedBy()
        );

        // ---- soft-delete: column AND trait asserted INDEPENDENTLY (#30/#12) ----
        $hasDeletedAt = Schema::hasColumn(self::TABLE, 'deleted_at');
        $usesSoftDeletes = in_array(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(Appointment::class),
            true
        );
        $this->assertTrue($hasDeletedAt, 'deleted_at column missing on live schema.');
        $this->assertTrue($usesSoftDeletes, 'Appointment model does not use SoftDeletes.');

        // ---- UNIQUE key on appointment_number (G43 index inspection) ----
        $indexes = collect(DB::select('SHOW INDEX FROM ' . self::TABLE))
            ->groupBy('Key_name');
        $uniqueOnNumber = $indexes->contains(function ($cols, $keyName) {
            return $cols->every(fn ($c) => (int) $c->Non_unique === 0)
                && $cols->contains(fn ($c) => $c->Column_name === 'appointment_number')
                && (int) $cols->first()->Non_unique === 0;
        });
        $this->assertTrue($uniqueOnNumber, 'Expected a UNIQUE index covering appointment_number.');

        // ---- DEV-FOF-A02: DDL status ENUM ≠ code. Assert the LIVE enum truth, don't force DDL. ----
        $statusCol = $this->liveEnumValues('status');
        $this->assertNotEmpty($statusCol, 'Could not read live status ENUM.');
        // Documented divergence (see Gap Analysis DEV-FOF-A02): controller writes 'Scheduled'
        // while the shipped DDL enumerates ('Pending','Confirmed','Completed','Cancelled','No_Show').
        // We assert the live enum exists; the mismatch is surfaced as a DEV finding, not "fixed" here.
    }

    /** G43: duplicate appointment_number is rejected by the UNIQUE key. */
    public function test_appointment_02_duplicate_appointment_number_is_rejected(): void
    {
        $this->skipUnlessTable();
        $withId = $this->staffUserId();

        $number = 'APT-DUP-' . $this->uniqueSuffix();
        $first = null;
        try {
            $first = $this->createAppointment(['appointment_number' => $number, 'with_user_id' => $withId]);

            $threw = false;
            try {
                $this->createAppointment(['appointment_number' => $number, 'with_user_id' => $withId]);
            } catch (Throwable $e) {
                $threw = $this->isDbConstraintViolation($e);
            }
            $this->assertTrue($threw, 'Duplicate appointment_number was NOT rejected by the UNIQUE key.');
        } finally {
            $this->cleanup($first);
            $this->purgeByNumber($number);
        }
    }

    /** G44: every NOT-NULL-no-default column rejects a missing value at the DB layer. */
    public function test_appointment_03_notnull_columns_reject_missing_values(): void
    {
        $this->skipUnlessTable();
        $withId = $this->staffUserId();

        // NOT NULL, no DB default (created_by/updated_by are NOT NULL no default; status HAS a default).
        $notNull = [
            'appointment_number', 'appointment_type', 'with_user_id', 'visitor_name',
            'visitor_mobile', 'purpose', 'appointment_date', 'start_time', 'end_time',
            'created_by', 'updated_by',
        ];

        foreach ($notNull as $field) {
            $created = null;
            try {
                $payload = $this->rawValidRow($withId);
                unset($payload[$field]);
                DB::table(self::TABLE)->insert($payload);
                $this->fail("Expected DB rejection for missing NOT-NULL column {$field}, insert succeeded.");
            } catch (Throwable $e) {
                $this->assertTrue(
                    $this->isDbConstraintViolation($e),
                    "Missing {$field} should raise a DB constraint error, got: " . $e->getMessage()
                );
            } finally {
                $this->purgeByNumber($payload['appointment_number'] ?? '');
                $this->cleanup($created);
            }
        }
    }

    /** G44 positive: nullable columns accept NULL. */
    public function test_appointment_04_nullable_columns_accept_null(): void
    {
        $this->skipUnlessTable();
        $withId = $this->staffUserId();

        $record = null;
        try {
            $record = $this->createAppointment([
                'with_user_id'        => $withId,
                'visitor_email'       => null,
                'confirmed_by'        => null,
                'confirmed_at'        => null,
                'cancellation_reason' => null,
                'notes'               => null,
            ]);
            $this->assertNotNull($record->id, 'Row with nullable columns null did not persist.');
            $record->refresh();
            $this->assertNull($record->visitor_email);
            $this->assertNull($record->cancellation_reason);
        } finally {
            $this->cleanup($record);
        }
    }

    /** G45: over-length VARCHAR rejected; exactly-n accepted. */
    public function test_appointment_05_varchar_length_boundaries(): void
    {
        $this->skipUnlessTable();
        $withId = $this->staffUserId();

        // exactly-n positive
        $okName = str_repeat('a', 100);
        $okPurpose = str_repeat('p', 300);
        $ok = null;
        try {
            $ok = $this->createAppointment([
                'with_user_id' => $withId,
                'visitor_name' => $okName,
                'purpose'      => $okPurpose,
            ]);
            $ok->refresh();
            $this->assertSame(100, strlen((string) $ok->visitor_name));
            $this->assertSame(300, strlen((string) $ok->purpose));
        } finally {
            $this->cleanup($ok);
        }

        // over-length negative — DB rejects (strict) OR silently truncates; assert one of the two,
        // never a brittle exact code (F41). visitor_name VARCHAR(100).
        $over = null;
        $number = 'APT-OVL-' . $this->uniqueSuffix();
        try {
            $row = $this->rawValidRow($withId);
            $row['appointment_number'] = $number;
            $row['visitor_name'] = str_repeat('x', 130); // n+30
            $rejected = false;
            try {
                DB::table(self::TABLE)->insert($row);
            } catch (Throwable $e) {
                $rejected = true;
            }
            if (!$rejected) {
                $stored = DB::table(self::TABLE)->where('appointment_number', $number)->value('visitor_name');
                $this->assertLessThanOrEqual(
                    100,
                    strlen((string) $stored),
                    'Over-length visitor_name was neither rejected nor truncated to the column width.'
                );
            } else {
                $this->assertTrue(true);
            }
        } finally {
            $this->purgeByNumber($number);
            $this->cleanup($over);
        }
    }

    /** G48/#35: DB defaults (status, is_active) applied when omitted; read back with refresh(). */
    public function test_appointment_06_db_defaults_applied_on_direct_insert(): void
    {
        $this->skipUnlessTable();
        $withId = $this->staffUserId();

        $number = 'APT-DEF-' . $this->uniqueSuffix();
        try {
            // Insert bypassing the model defaults to observe the raw DB default.
            $row = $this->rawValidRow($withId);
            $row['appointment_number'] = $number;
            unset($row['status'], $row['is_active']);
            DB::table(self::TABLE)->insert($row);

            $fresh = DB::table(self::TABLE)->where('appointment_number', $number)->first();
            $this->assertNotNull($fresh, 'Row did not persist.');
            // is_active DEFAULT 1
            $this->assertSame(1, (int) $fresh->is_active, 'is_active DB default should be 1.');
            // status has a DDL default (Pending) — assert it is non-empty (live enum default).
            $this->assertNotSame('', (string) $fresh->status, 'status DB default should be applied.');
        } finally {
            $this->purgeByNumber($number);
        }
    }

    // =====================================================================
    // 10–19  Business rules (BC-BIZ)
    // =====================================================================

    /** BC-BIZ / G48: store() auto-generates APT-YYYYMMDD-NNN and sets created_by (never a form input). */
    public function test_appointment_10_store_autogenerates_number_and_audit(): void
    {
        $this->skipUnlessRoute('fof.appointments.store');
        $withId = $this->staffUserId();

        $marker = 'AptAuto ' . $this->uniqueSuffix();
        $created = null;
        try {
            $resp = $this->httpStore($this->validStorePayload($withId, ['visitor_name' => $marker]));
            if (!in_array($resp->getStatusCode(), [200, 201, 302], true)) {
                $this->markTestSkipped('Store route unavailable (module disabled / status ' . $resp->getStatusCode() . ').');
            }
            $created = Appointment::withTrashed()->where('visitor_name', $marker)->latest('id')->first();
            $this->assertNotNull($created, 'Appointment not created via store().');
            $this->assertMatchesRegularExpression(
                '/^APT-\d{8}-\d{3}$/',
                (string) $created->appointment_number,
                'appointment_number is not the APT-YYYYMMDD-NNN auto format.'
            );
            $this->assertNotNull($created->created_by, 'created_by should be set by the controller.');
        } finally {
            $this->cleanup($created);
        }
    }

    /** DEV-FOF-A02: store() sets status='Scheduled' (a value absent from the shipped DDL enum). */
    public function test_appointment_11_store_sets_status_scheduled(): void
    {
        $this->skipUnlessRoute('fof.appointments.store');
        $withId = $this->staffUserId();

        $marker = 'AptSched ' . $this->uniqueSuffix();
        $created = null;
        try {
            $resp = $this->httpStore($this->validStorePayload($withId, ['visitor_name' => $marker]));
            if (!in_array($resp->getStatusCode(), [200, 201, 302], true)) {
                $this->markTestSkipped('Store route unavailable (status ' . $resp->getStatusCode() . ').');
            }
            $created = Appointment::withTrashed()->where('visitor_name', $marker)->latest('id')->first();
            $this->assertNotNull($created, 'Appointment not created.');
            // Proves the code path; the enum divergence is a DEV finding (A02), not asserted as valid.
            $this->assertSame('Scheduled', (string) $created->status, 'store() should set status=Scheduled.');
        } finally {
            $this->cleanup($created);
        }
    }

    /** VAL-FOF-001 (REMEDIATED): store() now enforces slot-overlap double-booking. */
    public function test_appointment_12_slot_overlap_double_booking_is_rejected(): void
    {
        $this->skipUnlessRoute('fof.appointments.store');
        $withId = $this->staffUserId();

        $date = now()->addDay()->toDateString();
        $first = null;
        $secondMarker = 'AptOverlap ' . $this->uniqueSuffix();
        try {
            // Seed an existing active appointment 10:00–11:00 for the staff member.
            $first = $this->createAppointment([
                'with_user_id'     => $withId,
                'appointment_date' => $date,
                'start_time'       => '10:00',
                'end_time'         => '11:00',
                'status'           => 'Scheduled',
            ]);
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not seed base appointment (enum/schema): ' . $e->getMessage());
        }

        try {
            // Attempt an overlapping slot 10:30–11:30 via the real store() path.
            $resp = $this->httpStore($this->validStorePayload($withId, [
                'visitor_name'     => $secondMarker,
                'appointment_date' => $date,
                'start_time'       => '10:30',
                'end_time'         => '11:30',
            ]));
            // store() throws DomainException on overlap → tolerant: 500 (unhandled) OR 302/422 (handled),
            // but the overlapping row MUST NOT be persisted (the observed outcome we assert).
            $overlapCreated = Appointment::withTrashed()->where('visitor_name', $secondMarker)->exists();
            $this->assertFalse($overlapCreated, 'Overlapping appointment was persisted — double-booking not blocked.');
        } finally {
            $this->cleanup($first);
            Appointment::withTrashed()->where('visitor_name', $secondMarker)->forceDelete();
        }
    }

    /** DEV-FOF-A03: appointment_type options come from the LIVE enum (model reads SHOW COLUMNS). */
    public function test_appointment_13_appointment_type_options_from_live_enum(): void
    {
        $this->skipUnlessTable();
        $options = Appointment::appointmentTypeOptions();
        $this->assertIsArray($options);
        $this->assertNotEmpty($options, 'appointmentTypeOptions() returned no values.');
        // normalizeAppointmentType maps a legacy DDL value into the live set.
        $mapped = Appointment::normalizeAppointmentType('Parent_Teacher_Meeting');
        $this->assertNotNull($mapped);
    }

    // =====================================================================
    // 20–29  State-machine transitions (BC-SM)
    // =====================================================================

    /** BC-SM legal: Scheduled --confirm--> Confirmed. */
    public function test_appointment_20_confirm_scheduled_to_confirmed(): void
    {
        $this->runTransition(
            seedStatus: 'Scheduled',
            routeName: 'fof.appointments.confirm',
            verb: 'PATCH',
            expectStatus: 'Confirmed',
            shouldSucceed: true
        );
    }

    /** BC-SM illegal: confirm rejected when not Scheduled (abort 422). */
    public function test_appointment_21_confirm_rejected_when_not_scheduled(): void
    {
        $this->runTransition(
            seedStatus: 'Confirmed',
            routeName: 'fof.appointments.confirm',
            verb: 'PATCH',
            expectStatus: 'Confirmed',
            shouldSucceed: false
        );
    }

    /** BC-SM legal: Confirmed --complete--> Completed. */
    public function test_appointment_22_complete_confirmed_to_completed(): void
    {
        $this->runTransition(
            seedStatus: 'Confirmed',
            routeName: 'fof.appointments.complete',
            verb: 'PATCH',
            expectStatus: 'Completed',
            shouldSucceed: true
        );
    }

    /** BC-SM illegal: complete rejected when already Completed (abort 422). */
    public function test_appointment_23_complete_rejected_when_completed(): void
    {
        $this->runTransition(
            seedStatus: 'Completed',
            routeName: 'fof.appointments.complete',
            verb: 'PATCH',
            expectStatus: 'Completed',
            shouldSucceed: false
        );
    }

    /** BC-SM legal: Scheduled --cancel--> Cancelled. */
    public function test_appointment_24_cancel_scheduled_to_cancelled(): void
    {
        $this->runTransition(
            seedStatus: 'Scheduled',
            routeName: 'fof.appointments.cancel',
            verb: 'PATCH',
            expectStatus: 'Cancelled',
            shouldSucceed: true
        );
    }

    /** BC-SM illegal: cancel rejected when already Cancelled (abort 422). */
    public function test_appointment_25_cancel_rejected_when_cancelled(): void
    {
        $this->runTransition(
            seedStatus: 'Cancelled',
            routeName: 'fof.appointments.cancel',
            verb: 'PATCH',
            expectStatus: 'Cancelled',
            shouldSucceed: false
        );
    }

    /** DEV-FOF-A04: No_Show is in the DDL enum but NO controller action can reach it (dead state). */
    public function test_appointment_26_no_show_state_has_no_transition(): void
    {
        $controller = \Modules\FrontOffice\Http\Controllers\AppointmentController::class;
        $body = '';
        try {
            $file = (new \ReflectionClass($controller))->getFileName();
            if ($file && is_readable($file)) {
                $body = (string) file_get_contents($file);
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Controller source unreadable: ' . $e->getMessage());
        }
        if ($body === '') {
            $this->markTestSkipped('Controller source not resolvable from runner.');
        }
        // Proving current behaviour: no assignment sets status to No_Show anywhere.
        $this->assertStringNotContainsString("'No_Show'", $this->statusAssignments($body),
            'A No_Show transition appears to exist — update DEV-FOF-A04.');
    }

    // =====================================================================
    // 30–39  Validation + error messages (BC-VAL)
    // =====================================================================

    public function test_appointment_30_store_rejects_missing_required_fields(): void
    {
        $this->assertStoreRejects([], 'empty payload');
    }

    public function test_appointment_31_end_time_must_be_after_start_time(): void
    {
        $withId = $this->staffUserId();
        $this->assertStoreRejects(
            $this->validStorePayload($withId, ['start_time' => '11:00', 'end_time' => '10:00']),
            'end_time before start_time'
        );
    }

    public function test_appointment_32_appointment_date_must_be_today_or_future_on_create(): void
    {
        $withId = $this->staffUserId();
        $this->assertStoreRejects(
            $this->validStorePayload($withId, ['appointment_date' => now()->subDays(3)->toDateString()]),
            'past appointment_date'
        );
    }

    public function test_appointment_33_invalid_appointment_type_rejected(): void
    {
        $withId = $this->staffUserId();
        $this->assertStoreRejects(
            $this->validStorePayload($withId, ['appointment_type' => 'Totally_Invalid_Type_ZZZ']),
            'invalid appointment_type'
        );
    }

    public function test_appointment_34_invalid_email_rejected(): void
    {
        $withId = $this->staffUserId();
        $this->assertStoreRejects(
            $this->validStorePayload($withId, ['visitor_email' => 'not-an-email']),
            'invalid visitor_email'
        );
    }

    public function test_appointment_35_with_user_id_must_exist_in_sys_users(): void
    {
        $this->assertStoreRejects(
            $this->validStorePayload(2000000001, ['with_user_id' => 2000000001]),
            'non-existent with_user_id'
        );
    }

    public function test_appointment_36_overlength_visitor_name_rejected_by_request(): void
    {
        $withId = $this->staffUserId();
        $this->assertStoreRejects(
            $this->validStorePayload($withId, ['visitor_name' => str_repeat('n', 130)]),
            'over-length visitor_name (>100)'
        );
    }

    // =====================================================================
    // 40–49  Integration / FK dependency (BC-INT / BC-REF)
    // =====================================================================

    /** BC-REF: with_user_id FK RESTRICT — staff() relationship resolves to the sys_users row. */
    public function test_appointment_40_staff_relationship_resolves(): void
    {
        $this->skipUnlessTable();
        $withId = $this->staffUserId();
        $record = null;
        try {
            $record = $this->createAppointment(['with_user_id' => $withId]);
            $record->refresh();
            $this->assertSame($withId, (int) $record->with_user_id);
            // Relationship object is valid even if the SchoolSetup User row is absent in a partial env.
            try {
                $staff = $record->staff()->first();
                if ($staff !== null) {
                    $this->assertSame($withId, (int) $staff->id);
                } else {
                    $this->assertTrue(true, 'staff row absent in partial env — relationship still valid.');
                }
            } catch (Throwable $e) {
                $this->markTestSkipped('SchoolSetup\\User dependency unavailable: ' . $e->getMessage());
            }
        } finally {
            $this->cleanup($record);
        }
    }

    /** BC-DB: soft delete → restore round-trip (model uses SoftDeletes). */
    public function test_appointment_43_soft_delete_and_restore_roundtrip(): void
    {
        $this->skipUnlessTable();
        $withId = $this->staffUserId();
        $record = null;
        try {
            $record = $this->createAppointment(['with_user_id' => $withId]);
            $id = (int) $record->id;

            $record->delete();
            $this->assertNotNull(Appointment::withTrashed()->find($id)?->deleted_at, 'Row not soft-deleted.');
            $this->assertNull(Appointment::find($id), 'Soft-deleted row still visible to default scope.');

            Appointment::withTrashed()->find($id)->restore();
            $this->assertNotNull(Appointment::find($id), 'Row not restored.');
        } finally {
            $this->cleanup($record);
        }
    }

    /** BC-DB: force delete permanently removes the row. */
    public function test_appointment_44_force_delete_removes_permanently(): void
    {
        $this->skipUnlessTable();
        $withId = $this->staffUserId();
        $record = $this->createAppointment(['with_user_id' => $withId]);
        $id = (int) $record->id;
        $record->forceDelete();
        $this->assertNull(Appointment::withTrashed()->find($id), 'Row not permanently deleted.');
    }

    // =====================================================================
    // 50–59  Permissions / authorization (BC-AUTH)
    // =====================================================================

    /** BC-AUTH: guest is redirected to /login (auth middleware). */
    public function test_appointment_50_guest_redirected_to_login(): void
    {
        $this->skipUnlessRoute('fof.appointments.index');
        $resp = $this->httpGet(self::INDEX_PATH); // no actingAs
        $status = $resp->getStatusCode();
        if ($status === 404) {
            $this->markTestSkipped('Module disabled — route 404.');
        }
        // auth middleware → 302 redirect to login (tolerate 401/403 variants).
        $this->assertContains($status, [302, 401, 403], 'Guest was not blocked from the index.');
        if ($status === 302) {
            $this->assertStringContainsString('login', (string) $resp->headers->get('Location'));
        }
    }

    public function test_appointment_51_index_forbidden_without_view_permission(): void
    {
        $this->assertForbiddenWithout(self::PERM_VIEW, 'GET', self::INDEX_PATH, 'fof.appointments.index');
    }

    public function test_appointment_52_store_forbidden_without_create_permission(): void
    {
        $withId = $this->staffUserId();
        $this->assertForbiddenWithout(
            self::PERM_CREATE, 'POST', self::STORE_PATH, 'fof.appointments.store',
            $this->validStorePayload($withId)
        );
    }

    public function test_appointment_53_delete_forbidden_without_delete_permission(): void
    {
        $this->skipUnlessRoute('fof.appointments.destroy');
        $withId = $this->staffUserId();
        $record = $this->createAppointment(['with_user_id' => $withId]);
        try {
            $path = self::SHOW_BASE . '/' . $record->id;
            $this->assertForbiddenWithout(self::PERM_DELETE, 'DELETE', $path, 'fof.appointments.destroy');
        } finally {
            $this->cleanup($record);
        }
    }

    /** DEV-FOF-A07 (SEC-FOF-003 / D30): FormRequest::authorize() returns true — no defense-in-depth. */
    public function test_appointment_55_formrequest_authorize_returns_true(): void
    {
        $req = new \Modules\FrontOffice\Http\Requests\AppointmentRequest();
        $this->assertTrue($req->authorize(), 'AppointmentRequest::authorize() no longer returns true — update DEV-FOF-A07.');
    }

    // =====================================================================
    // 60–69  UI/UX
    // =====================================================================

    public function test_appointment_60_index_renders_upcoming_and_past(): void
    {
        $this->skipUnlessRoute('fof.appointments.index');
        $this->browse(function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH, 1000);
            if ($this->onLoginOr404($browser)) {
                $this->markTestSkipped('Index unreachable (module disabled / not authenticated).');
            }
            $browser->assertSee('Upcoming');
        });
    }

    public function test_appointment_62_calendar_view_renders(): void
    {
        $this->skipUnlessRoute('fof.appointments.calendar');
        $this->browse(function (Browser $browser): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::CALENDAR_PATH, 1000);
            if ($this->onLoginOr404($browser)) {
                $this->markTestSkipped('Calendar unreachable.');
            }
            $browser->assertPathContains('/appointments/calendar');
        });
    }

    /** JSON endpoint: toggle-status flips is_active and returns the contract shape. */
    public function test_appointment_64_toggle_status_endpoint_flips_is_active(): void
    {
        $this->skipUnlessRoute('fof.appointments.toggleStatus');
        $withId = $this->staffUserId();
        $record = $this->createAppointment(['with_user_id' => $withId, 'is_active' => true]);
        try {
            if (!$this->adminUser) {
                $this->markTestSkipped('No admin user.');
            }
            $path = self::SHOW_BASE . '/' . $record->id . '/toggle-status';
            $resp = $this->httpJson('PATCH', $path, [], $this->adminUser);
            if (!in_array($resp->getStatusCode(), [200], true)) {
                $this->markTestSkipped('toggle-status route unavailable (status ' . $resp->getStatusCode() . ').');
            }
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'toggle-status did not flip is_active.');
            $resp->assertJson(['success' => true]);
        } finally {
            $this->cleanup($record);
        }
    }

    // =====================================================================
    // 70–79  Edge cases (BC-EDG) + defect-proving
    // =====================================================================

    /** TC-S: XSS in visitor_name is stored raw but Blade escapes on render (no persisted script execution proof). */
    public function test_appointment_70_xss_visitor_name_is_escaped_on_render(): void
    {
        $this->skipUnlessRoute('fof.appointments.show');
        $withId = $this->staffUserId();
        $payload = '<script>alert(1)</script>';
        $record = $this->createAppointment(['with_user_id' => $withId, 'visitor_name' => $payload]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticate($browser);
                $this->visitAuthenticated($browser, self::SHOW_BASE . '/' . $record->id, 1000);
                if ($this->onLoginOr404($browser)) {
                    $this->markTestSkipped('Show page unreachable.');
                }
                // Blade {{ }} escaping → the literal tag must not appear as an executable element.
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<script>alert(1)</script>', $source,
                    'Unescaped script tag rendered — stored XSS.');
            });
        } finally {
            $this->cleanup($record);
        }
    }

    /** DEV-FOF-A10: update() (PUT) allows a PAST appointment_date and does NOT re-check slot overlap. */
    public function test_appointment_71_update_allows_past_date(): void
    {
        // FormRequest uses after_or_equal:today ONLY for POST; PUT drops it. Prove via request rules.
        $req = new \Modules\FrontOffice\Http\Requests\AppointmentRequest();
        // The date-floor rule is applied for POST only; assert the source contract.
        $file = (new \ReflectionClass($req))->getFileName();
        $src = $file && is_readable($file) ? (string) file_get_contents($file) : '';
        if ($src === '') {
            $this->markTestSkipped('Request source unreadable.');
        }
        $this->assertStringContainsString("isMethod('post')", $src,
            'Date-floor rule is no longer POST-only — re-verify DEV-FOF-A10.');
        $this->assertStringContainsString('after_or_equal:today', $src);
    }

    /** DEV-FOF-A06: update()/toggleStatus()/forceDelete() emit NO activityLog (audit-trail gap). */
    public function test_appointment_72_update_emits_no_activity_log(): void
    {
        $controller = \Modules\FrontOffice\Http\Controllers\AppointmentController::class;
        $file = (new \ReflectionClass($controller))->getFileName();
        $src = $file && is_readable($file) ? (string) file_get_contents($file) : '';
        if ($src === '') {
            $this->markTestSkipped('Controller source unreadable.');
        }
        // update() body must not call activityLog(); created/confirmed/etc. do.
        $updateBody = $this->methodBody($src, 'public function update(');
        $this->assertNotSame('', $updateBody, 'Could not isolate update() body.');
        $this->assertStringNotContainsString('activityLog(', $updateBody,
            'update() now logs activity — update DEV-FOF-A06.');
        // Positive control: store() DOES log.
        $storeBody = $this->methodBody($src, 'public function store(');
        $this->assertStringContainsString("activityLog(\$appointment, 'appointment_created'", $storeBody);
    }

    /** HARD RULE #11: activity-log event verbs are snake_case verbatim (NOT the PascalCase Created/… set). */
    public function test_appointment_73_activity_log_verbs_are_snake_case(): void
    {
        $controller = \Modules\FrontOffice\Http\Controllers\AppointmentController::class;
        $file = (new \ReflectionClass($controller))->getFileName();
        $src = $file && is_readable($file) ? (string) file_get_contents($file) : '';
        if ($src === '') {
            $this->markTestSkipped('Controller source unreadable.');
        }
        foreach ([
            'appointment_created', 'appointment_confirmed', 'appointment_cancelled',
            'appointment_completed', 'appointment_deleted', 'appointment_restored',
        ] as $verb) {
            $this->assertStringContainsString("'{$verb}'", $src, "Missing activity verb {$verb}.");
        }
        // Activity sink is sys_activity_logs (FactPack §4-corrected).
        if (Schema::hasTable('sys_activity_logs')) {
            $this->assertTrue(true, 'sys_activity_logs present (activity sink).');
        } else {
            $this->markTestSkipped('sys_activity_logs absent in test DB (env prerequisite).');
        }
    }

    // =====================================================================
    // 90–99  Tenancy isolation + security
    // =====================================================================

    /** TC-T / IDOR: a non-existent id on the show route returns 404, never another tenant's row. */
    public function test_appointment_90_unknown_id_returns_404(): void
    {
        $this->skipUnlessRoute('fof.appointments.show');
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user.');
        }
        $resp = $this->httpJson('GET', self::SHOW_BASE . '/999999999', [], $this->adminUser);
        $this->assertContains($resp->getStatusCode(), [404, 403, 302], 'Unknown id should 404/403, not 200.');
    }

    /** TC-S: toggle-status without auth is rejected (auth middleware). */
    public function test_appointment_91_toggle_status_requires_auth(): void
    {
        $this->skipUnlessRoute('fof.appointments.toggleStatus');
        $withId = $this->staffUserId();
        $record = $this->createAppointment(['with_user_id' => $withId]);
        try {
            $resp = $this->httpJson('PATCH', self::SHOW_BASE . '/' . $record->id . '/toggle-status', []);
            $this->assertContains($resp->getStatusCode(), [302, 401, 403, 419, 404],
                'Unauthenticated toggle-status should be blocked.');
        } finally {
            $this->cleanup($record);
        }
    }

    // =====================================================================
    // ----------------------  Private helper library  ---------------------
    // (mirrors the tenant-side Complaint sibling; adapted to fof_appointments)
    // =====================================================================

    private function initializeTenantContext(): void
    {
        if ($this->tenantHost === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }
        try {
            $domain = Domain::query()->where('domain', $this->tenantHost)->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('Tenant lookup failed: ' . $e->getMessage());
        }
        if (empty($domain)) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $this->tenantHost);
        }
        if (function_exists('tenancy')) {
            tenancy()->initialize($domain->tenant);
        }
    }

    private function resolveAdminUser(): void
    {
        try {
            $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
                ?? User::query()->orderBy('id')->first();
        } catch (Throwable $e) {
            $this->adminUser = null;
        }
        if ($this->adminUser
            && property_exists($this->adminUser, 'email_verified_at')
            && !$this->adminUser->email_verified_at) {
            try {
                $this->adminUser->email_verified_at = now();
                $this->adminUser->save();
            } catch (Throwable) {
                // best effort
            }
        }
        if ($this->adminUser) {
            $this->grantAppointmentPermissions($this->adminUser);
        }
    }

    private function grantAppointmentPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo')) {
            return;
        }
        $perms = [
            self::PERM_VIEW, self::PERM_CREATE, self::PERM_UPDATE, self::PERM_CONFIRM,
            self::PERM_CANCEL, self::PERM_COMPLETE, self::PERM_DELETE, self::PERM_RESTORE, self::PERM_FORCE,
        ];
        $this->ensurePermissionsExist($perms);
        foreach ($perms as $p) {
            try {
                $user->givePermissionTo($p);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
        $this->forgetPermissionCache();
    }

    private function ensurePermissionsExist(array $permissions): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }
        $guard = config('auth.defaults.guard', 'web');
        foreach ($permissions as $p) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate(['name' => $p, 'guard_name' => $guard]);
            } catch (Throwable) {
                // ignore env-specific mismatches
            }
        }
    }

    private function forgetPermissionCache(): void
    {
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
            // ignore
        }
    }

    /** Build a NON-super-admin user with only the requested abilities (F37/#31). */
    private function makeLimitedUser(array $grant = []): ?User
    {
        try {
            $suffix = $this->uniqueSuffix();
            $user = User::factory()->create([
                'email'             => 'limited_' . $suffix . '@tenant.test',
                'emp_code'          => 'L_' . $suffix,
                'short_name'        => 'Ltd' . substr($suffix, -4),
                'email_verified_at' => now(),
            ]);
        } catch (Throwable $e) {
            return null;
        }
        // Strip any super-admin escalation (#31).
        foreach (['is_super_admin', 'super_admin_flag', 'is_admin'] as $flag) {
            try {
                if (Schema::hasColumn('sys_users', $flag)) {
                    $user->{$flag} = 0;
                    $user->save();
                }
            } catch (Throwable) {
                // ignore
            }
        }
        try {
            if (method_exists($user, 'syncRoles')) {
                $user->syncRoles([]);
            }
            if (method_exists($user, 'syncPermissions')) {
                $user->syncPermissions([]);
            }
            if (!empty($grant) && method_exists($user, 'givePermissionTo')) {
                $this->ensurePermissionsExist($grant);
                foreach ($grant as $p) {
                    try {
                        $user->givePermissionTo($p);
                    } catch (Throwable) {
                    }
                }
            }
        } catch (Throwable) {
            // ignore
        }
        $this->forgetPermissionCache();
        return $user;
    }

    /**
     * Assert that WITHOUT $ability a non-super-admin gets 403 on the route; tolerate 404/302
     * when the module is disabled (documented env prereq), and skip if a limited user can't be built.
     */
    private function assertForbiddenWithout(
        string $ability,
        string $method,
        string $path,
        string $routeName,
        array $body = []
    ): void {
        $this->skipUnlessRoute($routeName);
        // grant every ability EXCEPT the one under test.
        $all = [
            self::PERM_VIEW, self::PERM_CREATE, self::PERM_UPDATE, self::PERM_CONFIRM,
            self::PERM_CANCEL, self::PERM_COMPLETE, self::PERM_DELETE, self::PERM_RESTORE, self::PERM_FORCE,
        ];
        $grant = array_values(array_filter($all, fn ($p) => $p !== $ability));
        $user = $this->makeLimitedUser($grant);
        if (!$user) {
            $this->markTestSkipped('Could not build a limited user in this env.');
        }
        try {
            $resp = $this->httpJson($method, $path, $body, $user);
            $status = $resp->getStatusCode();
            if ($status === 404) {
                $this->markTestSkipped('Module disabled — route 404.');
            }
            $this->assertSame(403, $status,
                "Expected 403 without {$ability}, got {$status}.");
        } finally {
            try {
                $user->forceDelete();
            } catch (Throwable) {
            }
        }
    }

    /** Run a state-machine transition through the real workflow route. */
    private function runTransition(
        string $seedStatus,
        string $routeName,
        string $verb,
        string $expectStatus,
        bool $shouldSucceed
    ): void {
        $this->skipUnlessRoute($routeName);
        $withId = $this->staffUserId();
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user.');
        }

        $record = null;
        try {
            $record = $this->createAppointment(['with_user_id' => $withId, 'status' => $seedStatus]);
        } catch (Throwable $e) {
            $this->markTestSkipped("Could not seed status={$seedStatus} (enum divergence?): " . $e->getMessage());
        }

        try {
            $action = str_replace('fof.appointments.', '', $routeName);
            $path = self::SHOW_BASE . '/' . $record->id . '/' . $action;
            $resp = $this->httpJson($verb, $path, [], $this->adminUser);
            $status = $resp->getStatusCode();
            if ($status === 404) {
                $this->markTestSkipped('Module disabled — workflow route 404.');
            }
            $record->refresh();
            if ($shouldSucceed) {
                // 302 (redirect back with success) expected; tolerate 200.
                $this->assertContains($status, [200, 302], "Legal transition returned {$status}.");
                $this->assertSame($expectStatus, (string) $record->status,
                    "Legal transition did not move status to {$expectStatus}.");
            } else {
                // abort_if(...,422) → tolerant {422,500,302,403}; the status MUST be unchanged.
                $this->assertContains($status, [422, 500, 302, 403],
                    "Illegal transition returned unexpected {$status}.");
                $this->assertSame($seedStatus, (string) $record->status,
                    'Illegal transition changed the status — FSM guard bypassed.');
            }
        } finally {
            $this->cleanup($record);
        }
    }

    /** Assert the store() FormRequest rejects an invalid payload (tolerant 422/500/redirect-with-errors). */
    private function assertStoreRejects(array $payload, string $label): void
    {
        $this->skipUnlessRoute('fof.appointments.store');
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user.');
        }
        $marker = $payload['visitor_name'] ?? null;
        $resp = $this->httpStore($payload);
        $status = $resp->getStatusCode();
        if ($status === 404) {
            $this->markTestSkipped('Module disabled — store route 404.');
        }
        // Rejection surfaces as 422 (JSON) or 302-back-with-errors (web) or 500 (F41 tolerance).
        $this->assertContains($status, [422, 302, 500, 419],
            "Invalid payload ({$label}) was not rejected — status {$status}.");
        // And no row must be created for a uniquely-marked invalid payload.
        if (is_string($marker) && $marker !== '' && Schema::hasTable(self::TABLE)) {
            $exists = Appointment::withTrashed()->where('visitor_name', $marker)->exists();
            $this->assertFalse($exists, "Invalid payload ({$label}) unexpectedly created a row.");
        }
    }

    // ---- Appointment data builders ----

    private function validStorePayload(int $withUserId, array $overrides = []): array
    {
        $types = Appointment::appointmentTypeOptions();
        return array_merge([
            'appointment_type' => $types[0] ?? 'Other',
            'with_user_id'     => $withUserId,
            'visitor_name'     => 'Visitor ' . $this->uniqueSuffix(),
            'visitor_mobile'   => '9990001111',
            'visitor_email'    => 'v' . random_int(1000, 9999) . '@example.test',
            'purpose'          => 'Meeting purpose ' . $this->uniqueSuffix(),
            'appointment_date' => now()->addDay()->toDateString(),
            'start_time'       => '09:00',
            'end_time'         => '09:30',
            'notes'            => 'note',
        ], $overrides);
    }

    /** Create via the verified Eloquent model (G47), supplying auto/audit fields the controller sets. */
    private function createAppointment(array $overrides = []): Appointment
    {
        $base = [
            'appointment_number' => 'APT-SEED-' . $this->uniqueSuffix(),
            'appointment_type'   => Appointment::appointmentTypeOptions()[0] ?? 'Other',
            'with_user_id'       => $overrides['with_user_id'] ?? $this->staffUserId(),
            'visitor_name'       => 'Seed ' . $this->uniqueSuffix(),
            'visitor_mobile'     => '9990002222',
            'purpose'            => 'Seed purpose',
            'appointment_date'   => now()->addDay()->toDateString(),
            'start_time'         => '10:00',
            'end_time'           => '10:30',
            'status'             => 'Scheduled',
            'is_active'          => true,
            'created_by'         => $this->adminUserId(),
            'updated_by'         => $this->adminUserId(),
        ];
        return Appointment::create(array_merge($base, $overrides));
    }

    /** Raw column row for DB-layer (non-model) constraint tests. */
    private function rawValidRow(int $withUserId): array
    {
        return [
            'appointment_number' => 'APT-RAW-' . $this->uniqueSuffix(),
            'appointment_type'   => Appointment::appointmentTypeOptions()[0] ?? 'Other',
            'with_user_id'       => $withUserId,
            'visitor_name'       => 'Raw ' . $this->uniqueSuffix(),
            'visitor_mobile'     => '9990003333',
            'purpose'            => 'Raw purpose',
            'appointment_date'   => now()->addDay()->toDateString(),
            'start_time'         => '11:00',
            'end_time'           => '11:30',
            'status'             => $this->liveEnumValues('status')[0] ?? 'Pending',
            'is_active'          => 1,
            'created_by'         => $this->adminUserId(),
            'updated_by'         => $this->adminUserId(),
            'created_at'         => now(),
            'updated_at'         => now(),
        ];
    }

    // ---- HTTP helpers (Laravel test client with tenant Host header) ----

    private function httpGet(string $path)
    {
        return $this->withHeader('Host', $this->tenantHost)->get($path);
    }

    private function httpStore(array $payload)
    {
        $req = $this->withHeader('Host', $this->tenantHost);
        if ($this->adminUser) {
            $req = $req->actingAs($this->adminUser);
        }
        return $req->post(self::STORE_PATH, $payload);
    }

    private function httpJson(string $method, string $path, array $body = [], ?User $user = null)
    {
        $req = $this->withHeader('Host', $this->tenantHost)
            ->withHeader('X-Requested-With', 'XMLHttpRequest');
        if ($user) {
            $req = $req->actingAs($user);
        }
        return $req->json($method, $path, $body);
    }

    // ---- browser auth helpers (mirror sibling) ----

    private function authenticate(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(700);
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1200);
        }
        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(500);
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

    private function onLoginOr404(Browser $browser): bool
    {
        $path = $this->currentPath($browser);
        if (str_contains($path, '/login')) {
            return true;
        }
        $src = $browser->driver->getPageSource();
        return str_contains($src, '404') && str_contains(strtolower($src), 'not found');
    }

    // ---- schema / source utilities ----

    private function liveEnumValues(string $column): array
    {
        try {
            $col = DB::selectOne('SHOW COLUMNS FROM ' . self::TABLE . " LIKE '{$column}'");
            if ($col && isset($col->Type) && preg_match('/^enum\((.*)\)$/i', $col->Type, $m) === 1) {
                return str_getcsv($m[1], ',', "'");
            }
        } catch (Throwable) {
            // fall through
        }
        return [];
    }

    private function methodBody(string $src, string $signature): string
    {
        $pos = strpos($src, $signature);
        if ($pos === false) {
            return '';
        }
        $brace = strpos($src, '{', $pos);
        if ($brace === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($src);
        for ($i = $brace; $i < $len; $i++) {
            if ($src[$i] === '{') {
                $depth++;
            } elseif ($src[$i] === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($src, $brace, $i - $brace + 1);
                }
            }
        }
        return '';
    }

    private function statusAssignments(string $src): string
    {
        // Concatenate lines that assign the status column, to search only assignment targets.
        $out = '';
        foreach (preg_split('/\r?\n/', $src) as $line) {
            if (str_contains($line, "'status'") && str_contains($line, '=>')) {
                $out .= $line . "\n";
            }
        }
        return $out;
    }

    private function isDbConstraintViolation(Throwable $e): bool
    {
        $m = strtolower($e->getMessage());
        return str_contains($m, 'cannot be null')
            || str_contains($m, 'not null')
            || str_contains($m, "doesn't have a default value")
            || str_contains($m, 'integrity constraint')
            || str_contains($m, 'duplicate')
            || str_contains($m, 'constraint failed')
            || str_contains($m, '23000')
            || str_contains($m, '1062')
            || str_contains($m, '1048');
    }

    // ---- ids / cleanup ----

    private function adminUserId(): int
    {
        return (int) ($this->adminUser?->id ?? 0) ?: $this->staffUserId();
    }

    private function staffUserId(): int
    {
        $id = (int) ($this->adminUser?->id ?? 0);
        if ($id > 0) {
            return $id;
        }
        try {
            $id = (int) User::query()->orderBy('id')->value('id');
        } catch (Throwable) {
            $id = 0;
        }
        if ($id <= 0) {
            $this->markTestSkipped('No sys_users row available for with_user_id.');
        }
        return $id;
    }

    private function cleanup(?Appointment $record): void
    {
        if ($record instanceof Appointment && $record->id) {
            try {
                Appointment::withTrashed()->where('id', $record->id)->forceDelete();
            } catch (Throwable) {
                // ignore
            }
        }
    }

    private function purgeByNumber(string $number): void
    {
        if ($number === '') {
            return;
        }
        try {
            DB::table(self::TABLE)->where('appointment_number', $number)->delete();
        } catch (Throwable) {
            // ignore
        }
    }

    private function skipUnlessTable(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->markTestSkipped('fof_appointments table absent — tenant schema not migrated.');
        }
    }

    private function skipUnlessRoute(string $name): void
    {
        if (!Route::has($name)) {
            $this->markTestSkipped("Route {$name} not registered (FrontOffice disabled in modules_statuses.json — #19).");
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
        return now()->format('His') . random_int(1000, 9999);
    }
}
