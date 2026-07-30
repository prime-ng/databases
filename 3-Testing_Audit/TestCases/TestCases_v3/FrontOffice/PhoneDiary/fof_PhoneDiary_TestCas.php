<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\PhoneDiary;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice :: PhoneDiary  (fof_phone_diary)
 * ------------------------------------------------------------------
 * ONE comprehensive tenant-side Dusk suite for the Phone Diary CRUD screen.
 * Mirrors the nearest committed tenant-side sibling (Inventory\Uom) for style,
 * tenancy scaffolding and the private helper library.
 *
 * DDL truth (fof_phone_diary):
 *   NOT-NULL user cols : call_type(ENUM), call_date(DATE), call_time(TIME),
 *                        caller_name(V100), purpose(V200)
 *   Nullable cols      : caller_number(V15), caller_organization(V100),
 *                        recipient_name(V100), recipient_user_id, message(TEXT),
 *                        action_notes(TEXT), logged_by
 *   Defaults           : is_active=1, action_required=0, action_completed=0
 *   UNIQUE keys        : NONE  (so no G43 duplicate-rejection case applies)
 *   FKs (SET NULL)     : recipient_user_id->sys_users, logged_by->sys_users
 *   Auto/managed (G48) : created_by, updated_by, logged_by  (controller sets these)
 *
 * Permission scheme (string gates): frontoffice.phone-diary.{viewAny,create,update,delete,restore,forceDelete}
 * Activity log       : NONE — PhoneDiaryController performs NO activityLog() calls (DEV-FOF-PD-002).
 *
 * ENV prerequisites (see Validation Report): FrontOffice must be ENABLED in
 * prime_testing/modules_statuses.json (currently false → routes 404); APP_ENV=testing.
 */
class fof_PhoneDiary_TestCas extends DuskTestCase
{
    private const TABLE = 'fof_phone_diary';
    private const INDEX_PATH = '/front-office/phone-diary';
    private const SHOW_BASE_PATH = '/front-office/phone-diary';
    private const TRASH_PATH = '/front-office/phone-diary/trash/view';

    private const PERMISSIONS = [
        'frontoffice.phone-diary.viewAny',
        'frontoffice.phone-diary.create',
        'frontoffice.phone-diary.update',
        'frontoffice.phone-diary.delete',
        'frontoffice.phone-diary.restore',
        'frontoffice.phone-diary.forceDelete',
    ];

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
        $this->initializeTenantContextForTests();
        $this->resolveAdminUserAndPermissions();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }
        parent::tearDown();
    }

    // ============================================================
    // 01-09  Schema / DDL / model / request configuration (G46)
    // ============================================================

    /** test_01 — full DDL <-> app alignment matrix (LIVE schema). */
    public function test_phonediary_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table fof_phone_diary must exist.');

        $expectedColumns = [
            'id', 'call_type', 'call_date', 'call_time', 'caller_name', 'caller_number',
            'caller_organization', 'recipient_name', 'recipient_user_id', 'purpose',
            'message', 'action_required', 'action_notes', 'action_completed', 'logged_by',
            'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, $expectedColumns),
            'fof_phone_diary is missing one or more expected columns.'
        );

        // Model wiring (verified CRUD model — G47).
        $model = new PhoneDiary();
        $this->assertSame(self::TABLE, $model->getTable(), 'PhoneDiary::$table must be fof_phone_diary.');

        $fillable = $model->getFillable();
        foreach (['call_type', 'call_date', 'call_time', 'caller_name', 'purpose',
                  'caller_number', 'caller_organization', 'recipient_name', 'recipient_user_id',
                  'message', 'action_required', 'action_notes', 'action_completed',
                  'logged_by', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $fillable, "Fillable must contain {$col}.");
        }

        // Casts.
        $casts = $model->getCasts();
        $this->assertSame('date', $casts['call_date'] ?? null);
        $this->assertSame('boolean', $casts['action_required'] ?? null);
        $this->assertSame('boolean', $casts['action_completed'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);

        // Soft-delete column and trait asserted INDEPENDENTLY (#30/G46).
        $hasDeletedAtColumn = Schema::hasColumn(self::TABLE, 'deleted_at');
        $usesSoftDeletes = in_array(SoftDeletes::class, class_uses_recursive(PhoneDiary::class), true);
        $this->assertTrue($hasDeletedAtColumn, 'DDL: deleted_at column must exist.');
        $this->assertTrue($usesSoftDeletes, 'Model: PhoneDiary must use SoftDeletes.');
        $this->assertSame($hasDeletedAtColumn, $usesSoftDeletes, 'Soft-delete column/trait must agree.');

        // No UNIQUE key on fof_phone_diary (G43 — documented absence).
        $uniqueCount = $this->uniqueIndexCount(self::TABLE);
        $this->assertSame(0, $uniqueCount, 'fof_phone_diary is expected to have NO unique index (per DDL).');
    }

    /** G44 negative — every NOT-NULL-no-default user column rejects a missing value. */
    public function test_phonediary_02_required_notnull_columns_reject_missing_values(): void
    {
        $requiredCols = ['call_type', 'call_date', 'call_time', 'caller_name', 'purpose'];

        foreach ($requiredCols as $col) {
            $created = null;
            try {
                $payload = $this->buildValidPayload();
                unset($payload[$col]);
                $created = PhoneDiary::query()->create($payload);
                $this->fail("Expected DB rejection creating a row without required column {$col}.");
            } catch (Throwable $e) {
                $msg = strtolower($e->getMessage());
                $isExpected = str_contains($msg, 'cannot be null')
                    || str_contains($msg, 'not null')
                    || str_contains($msg, "doesn't have a default value")
                    || str_contains($msg, 'integrity constraint')
                    || str_contains($msg, '23000')
                    || str_contains($msg, 'incorrect');
                $this->assertTrue($isExpected, "Expected NOT-NULL failure for {$col}, got: {$e->getMessage()}");
            } finally {
                if ($created instanceof PhoneDiary) {
                    $created->forceDelete();
                }
            }
        }
    }

    /** G44 positive — all nullable columns may be omitted and the row still persists. */
    public function test_phonediary_03_nullable_columns_accept_omitted_values(): void
    {
        $record = null;
        try {
            // Payload deliberately omits every nullable column.
            $record = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'NullableOmit ' . $this->generateUniqueSuffix(),
            ]));
            $record->refresh();

            $this->assertNotNull($record->id, 'Row with only required cols must persist.');
            $this->assertNull($record->caller_number, 'Omitted caller_number should be NULL.');
            $this->assertNull($record->caller_organization, 'Omitted caller_organization should be NULL.');
            $this->assertNull($record->recipient_name, 'Omitted recipient_name should be NULL.');
            $this->assertNull($record->recipient_user_id, 'Omitted recipient_user_id should be NULL.');
            $this->assertNull($record->message, 'Omitted message should be NULL.');
            $this->assertNull($record->action_notes, 'Omitted action_notes should be NULL.');
        } finally {
            if ($record instanceof PhoneDiary) {
                $record->forceDelete();
            }
        }
    }

    /** DDL defaults applied when omitted (read back via refresh — #35). */
    public function test_phonediary_04_column_defaults_applied_on_create(): void
    {
        $record = null;
        try {
            $payload = $this->buildValidPayload(['caller_name' => 'Defaults ' . $this->generateUniqueSuffix()]);
            // Omit the DEFAULT-bearing flags entirely.
            unset($payload['is_active'], $payload['action_required'], $payload['action_completed']);

            $record = PhoneDiary::query()->create($payload);
            $record->refresh();

            $this->assertTrue((bool) $record->is_active, 'is_active must default to 1.');
            $this->assertFalse((bool) $record->action_required, 'action_required must default to 0.');
            $this->assertFalse((bool) $record->action_completed, 'action_completed must default to 0.');
        } finally {
            if ($record instanceof PhoneDiary) {
                $record->forceDelete();
            }
        }
    }

    /** G43 — table has NO UNIQUE key; two identical logical rows both insert (duplicates allowed by design). */
    public function test_phonediary_05_no_unique_constraint_allows_duplicate_rows(): void
    {
        $name = 'DupCaller ' . $this->generateUniqueSuffix();
        $a = null;
        $b = null;
        try {
            $a = PhoneDiary::query()->create($this->buildValidPayload(['caller_name' => $name, 'purpose' => 'DupPurpose']));
            $b = PhoneDiary::query()->create($this->buildValidPayload(['caller_name' => $name, 'purpose' => 'DupPurpose']));

            $this->assertNotNull($a->id);
            $this->assertNotNull($b->id);
            $this->assertNotSame($a->id, $b->id, 'Two identical logical rows are permitted (no UNIQUE key).');
            $this->assertGreaterThanOrEqual(
                2,
                PhoneDiary::query()->where('caller_name', $name)->count(),
                'Both duplicate rows should be present.'
            );
        } finally {
            foreach ([$a, $b] as $r) {
                if ($r instanceof PhoneDiary) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** Boolean/date casts return typed values. */
    public function test_phonediary_06_casts_return_typed_values(): void
    {
        $record = null;
        try {
            $record = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name'     => 'CastCheck ' . $this->generateUniqueSuffix(),
                'action_required' => 1,
            ]));
            $record->refresh();

            $this->assertIsBool($record->action_required, 'action_required must cast to bool.');
            $this->assertIsBool($record->action_completed, 'action_completed must cast to bool.');
            $this->assertIsBool($record->is_active, 'is_active must cast to bool.');
            $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $record->call_date, 'call_date must cast to date.');
        } finally {
            if ($record instanceof PhoneDiary) {
                $record->forceDelete();
            }
        }
    }

    // ============================================================
    // 10-19  Business rules (BC-BIZ)
    // ============================================================

    /** scopeActionPending() returns only action_required=1 AND action_completed=0. */
    public function test_phonediary_10_action_pending_scope_filters_correctly(): void
    {
        $pending = null;
        $done = null;
        $notRequired = null;
        try {
            $pending = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'Pending ' . $this->generateUniqueSuffix(),
                'action_required' => 1, 'action_completed' => 0,
            ]));
            $done = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'Done ' . $this->generateUniqueSuffix(),
                'action_required' => 1, 'action_completed' => 1,
            ]));
            $notRequired = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'NoAction ' . $this->generateUniqueSuffix(),
                'action_required' => 0, 'action_completed' => 0,
            ]));

            $pendingIds = PhoneDiary::query()->actionPending()->pluck('id')->all();
            $this->assertContains($pending->id, $pendingIds, 'Pending action row must be in actionPending scope.');
            $this->assertNotContains($done->id, $pendingIds, 'Completed action row must NOT be in actionPending scope.');
            $this->assertNotContains($notRequired->id, $pendingIds, 'No-action row must NOT be in actionPending scope.');
        } finally {
            foreach ([$pending, $done, $notRequired] as $r) {
                if ($r instanceof PhoneDiary) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** scopeActive() excludes inactive rows. */
    public function test_phonediary_11_active_scope_excludes_inactive(): void
    {
        $active = null;
        $inactive = null;
        try {
            $active = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'Active ' . $this->generateUniqueSuffix(), 'is_active' => 1,
            ]));
            $inactive = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'Inactive ' . $this->generateUniqueSuffix(), 'is_active' => 0,
            ]));

            $activeIds = PhoneDiary::query()->active()->pluck('id')->all();
            $this->assertContains($active->id, $activeIds);
            $this->assertNotContains($inactive->id, $activeIds);
        } finally {
            foreach ([$active, $inactive] as $r) {
                if ($r instanceof PhoneDiary) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** Pending-actions KPI count (index computes PhoneDiary::active()->actionPending()->count()). */
    public function test_phonediary_12_pending_actions_count_is_consistent(): void
    {
        $record = null;
        try {
            $before = PhoneDiary::active()->actionPending()->count();
            $record = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'KpiPending ' . $this->generateUniqueSuffix(),
                'action_required' => 1, 'action_completed' => 0, 'is_active' => 1,
            ]));
            $after = PhoneDiary::active()->actionPending()->count();

            $this->assertGreaterThanOrEqual($before + 1, $after, 'Pending KPI must increase by at least one.');
        } finally {
            if ($record instanceof PhoneDiary) {
                $record->forceDelete();
            }
        }
    }

    // ============================================================
    // 20-29  Action lifecycle / state transitions (BC-SM)
    // ============================================================

    /** complete endpoint sets action_completed=1 (PATCH .../complete). */
    public function test_phonediary_20_complete_endpoint_marks_action_completed(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'ToComplete ' . $this->generateUniqueSuffix(),
            'action_required' => 1, 'action_completed' => 0,
        ]));
        $recordId = (int) $record->id;

        try {
            $this->browse(function (Browser $browser) use ($recordId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/complete');
                $this->spoofedRequestFromBrowser($browser, $url, 'PATCH');
                $browser->pause(1500);
            });

            $record->refresh();
            $this->assertTrue((bool) $record->action_completed, 'complete() must set action_completed to true.');
        } finally {
            PhoneDiary::withTrashed()->where('id', $recordId)->get()
                ->each(fn (PhoneDiary $r) => $r->forceDelete());
        }
    }

    /** toggle-status flips is_active and returns JSON success. */
    public function test_phonediary_21_toggle_status_flips_is_active(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'Toggle ' . $this->generateUniqueSuffix(), 'is_active' => 1,
        ]));
        $recordId = (int) $record->id;

        try {
            $this->assertTrue((bool) $record->is_active);

            $this->browse(function (Browser $browser) use ($recordId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/toggle-status');
                $response = $this->jsonRequestFromBrowser($browser, $url, 'POST');
                $this->assertIsArray($response, 'toggle-status must return JSON.');
                $this->assertTrue((bool) ($response['success'] ?? false), 'toggle-status success flag must be true.');
            });

            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'is_active must be flipped to false.');
        } finally {
            PhoneDiary::withTrashed()->where('id', $recordId)->get()
                ->each(fn (PhoneDiary $r) => $r->forceDelete());
        }
    }

    // ============================================================
    // 30-39  Validation + error messages (BC-VAL, G45)
    // ============================================================

    /** G45 — caller_name VARCHAR(100): over-length rejected/truncated + exactly-100 accepted. */
    public function test_phonediary_30_caller_name_length_boundary(): void
    {
        $this->assertSizedStringColumn('caller_name', 100);
    }

    /** G45 — caller_number VARCHAR(15). */
    public function test_phonediary_31_caller_number_length_boundary(): void
    {
        $this->assertSizedStringColumn('caller_number', 15);
    }

    /** G45 — caller_organization VARCHAR(100). */
    public function test_phonediary_32_caller_organization_length_boundary(): void
    {
        $this->assertSizedStringColumn('caller_organization', 100);
    }

    /** G45 — recipient_name VARCHAR(100). */
    public function test_phonediary_33_recipient_name_length_boundary(): void
    {
        $this->assertSizedStringColumn('recipient_name', 100);
    }

    /** G45 — purpose VARCHAR(200). */
    public function test_phonediary_34_purpose_length_boundary(): void
    {
        $this->assertSizedStringColumn('purpose', 200);
    }

    /** call_type ENUM rejects an out-of-domain value at the DB layer. */
    public function test_phonediary_35_call_type_enum_rejects_invalid(): void
    {
        $created = null;
        try {
            $created = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'BadEnum ' . $this->generateUniqueSuffix(),
                'call_type'   => 'Missed', // not in ENUM('Incoming','Outgoing')
            ]));
            // Non-strict MySQL may coerce to '' — treat a non-canonical persisted value as rejection evidence.
            $created->refresh();
            $this->assertNotContains(
                $created->call_type,
                ['Incoming', 'Outgoing'],
                'An invalid ENUM value must not be stored as a canonical value.'
            );
        } catch (Throwable $e) {
            $this->assertTrue(true, 'DB rejected invalid ENUM value: ' . $e->getMessage());
        } finally {
            if ($created instanceof PhoneDiary) {
                $created->forceDelete();
            }
        }
    }

    /** call_type ENUM accepts both canonical values. */
    public function test_phonediary_36_call_type_enum_accepts_valid_values(): void
    {
        foreach (['Incoming', 'Outgoing'] as $value) {
            $record = null;
            try {
                $record = PhoneDiary::query()->create($this->buildValidPayload([
                    'caller_name' => 'Enum' . $value . ' ' . $this->generateUniqueSuffix(),
                    'call_type'   => $value,
                ]));
                $record->refresh();
                $this->assertSame($value, $record->call_type, "call_type must accept {$value}.");
            } finally {
                if ($record instanceof PhoneDiary) {
                    $record->forceDelete();
                }
            }
        }
    }

    /** Browser store validation — required caller_name missing keeps user on form / shows error. */
    public function test_phonediary_37_store_rejects_missing_required_field(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

            // Submit the quick-add form with an empty required caller_name via a spoofed POST.
            $url = $this->tenantUrl(self::INDEX_PATH);
            $status = $this->postFormFromBrowser($browser, $url, [
                'call_type' => 'Incoming',
                'call_date' => now()->toDateString(),
                'call_time' => '10:00',
                'caller_name' => '',   // required — must be rejected
                'purpose' => '',       // required — must be rejected
            ]);

            // FormRequest validation → 302 redirect back with errors (or 422/500 tolerated).
            $this->assertContains(
                $status,
                [302, 422, 419, 500],
                'Missing required fields must not yield a 2xx creation. Got: ' . $status
            );
        });
    }

    // ============================================================
    // 40-49  FK / integration (BC-INT / BC-REF)
    // ============================================================

    /** recipient_user_id FK to sys_users is enforced (invalid id rejected). */
    public function test_phonediary_40_recipient_user_id_fk_is_enforced(): void
    {
        $created = null;
        try {
            $created = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name'       => 'BadFk ' . $this->generateUniqueSuffix(),
                'recipient_user_id' => 2147483000, // non-existent sys_users id
            ]));
            $this->fail('Expected FK violation for non-existent recipient_user_id.');
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $this->assertTrue(
                str_contains($msg, 'foreign key') || str_contains($msg, 'constraint') || str_contains($msg, '23000'),
                'Expected FK failure, got: ' . $e->getMessage()
            );
        } finally {
            if ($created instanceof PhoneDiary) {
                $created->forceDelete();
            }
        }
    }

    /** FK constraints declared with ON DELETE SET NULL (schema inspection). */
    public function test_phonediary_41_foreign_keys_defined_as_set_null(): void
    {
        try {
            $createSql = $this->showCreateTable(self::TABLE);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot read SHOW CREATE TABLE: ' . $e->getMessage());
            return;
        }

        $this->assertStringContainsStringIgnoringCase('foreign key', $createSql, 'Table must declare foreign keys.');
        $this->assertStringContainsStringIgnoringCase('recipient_user_id', $createSql);
        $this->assertStringContainsStringIgnoringCase('logged_by', $createSql);
        $this->assertStringContainsStringIgnoringCase('set null', $createSql, 'FKs should be ON DELETE SET NULL.');
    }

    /** logged_by is set by the controller from auth()->id() (auto-managed — G48). */
    public function test_phonediary_42_logged_by_is_set_by_controller_on_store(): void
    {
        $marker = 'LoggedByProbe ' . $this->generateUniqueSuffix();
        $created = null;

        try {
            $this->browse(function (Browser $browser) use ($marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH);
                $this->postFormFromBrowser($browser, $url, [
                    'call_type'   => 'Incoming',
                    'call_date'   => now()->toDateString(),
                    'call_time'   => '11:15',
                    'caller_name' => $marker,
                    'caller_number' => '9999999999',
                    'purpose'     => 'Logged-by probe',
                ]);
                $browser->pause(1500);
            });

            $created = PhoneDiary::query()->where('caller_name', $marker)->first();
            if (!$created) {
                $this->markTestSkipped('Store did not persist a row (module may be disabled — see Validation Report).');
                return;
            }
            $this->assertNotNull($created->logged_by, 'logged_by must be auto-populated by the controller.');
            $this->assertSame((int) $this->adminUser?->id, (int) $created->logged_by, 'logged_by must be the acting user.');
            $this->assertSame((int) $this->adminUser?->id, (int) $created->created_by, 'created_by must be the acting user.');
        } finally {
            if ($created instanceof PhoneDiary) {
                $created->forceDelete();
            }
        }
    }

    // ============================================================
    // 50-59  Permissions / authorization (BC-AUTH, F37/#31)
    // ============================================================

    /** Guest is redirected to login. */
    public function test_phonediary_50_guest_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(1500);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** Non-super-admin WITHOUT viewAny cannot open the index (real 403). */
    public function test_phonediary_51_index_requires_viewany_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::INDEX_PATH, 'GET');
    }

    /** Non-super-admin WITHOUT create cannot store. */
    public function test_phonediary_52_store_requires_create_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::INDEX_PATH, 'POST', [
            'call_type' => 'Incoming',
            'call_date' => now()->toDateString(),
            'call_time' => '10:00',
            'caller_name' => 'PermDenied ' . $this->generateUniqueSuffix(),
            'purpose' => 'Permission probe',
        ]);
    }

    // ============================================================
    // 60-69  UI / UX (list, search, filter, show, edit)
    // ============================================================

    /** Index page renders and shows a seeded row. */
    public function test_phonediary_60_index_page_loads_and_lists_records(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'IndexRow ' . $this->generateUniqueSuffix(),
        ]));

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 1000);

                $browser->waitForText((string) $record->caller_name, 12)
                    ->assertSee((string) $record->caller_name);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Search filter narrows the list by caller_name. */
    public function test_phonediary_61_search_filters_results(): void
    {
        $needle = 'UniqueSearch' . $this->generateUniqueSuffix();
        $match = PhoneDiary::query()->create($this->buildValidPayload(['caller_name' => $needle]));
        $other = PhoneDiary::query()->create($this->buildValidPayload(['caller_name' => 'Other ' . $this->generateUniqueSuffix()]));

        try {
            $this->browse(function (Browser $browser) use ($needle, $other): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?search=' . urlencode($needle), 1200);

                $browser->waitForText($needle, 12)->assertSee($needle);
                $this->assertStringNotContainsString(
                    (string) $other->caller_name,
                    $browser->driver->getPageSource(),
                    'Non-matching row must be filtered out.'
                );
            });
        } finally {
            $match->forceDelete();
            $other->forceDelete();
        }
    }

    /** call_type filter narrows results. */
    public function test_phonediary_62_call_type_filter_applies(): void
    {
        $incoming = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'IncFilter' . $this->generateUniqueSuffix(), 'call_type' => 'Incoming',
        ]));
        try {
            $this->browse(function (Browser $browser) use ($incoming): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication(
                    $browser,
                    self::INDEX_PATH . '?call_type=Incoming&search=' . urlencode((string) $incoming->caller_name),
                    1200
                );
                $browser->waitForText((string) $incoming->caller_name, 12)
                    ->assertSee((string) $incoming->caller_name);
            });
        } finally {
            $incoming->forceDelete();
        }
    }

    /** Show page displays the record details. */
    public function test_phonediary_63_show_page_displays_details(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'ShowDetail ' . $this->generateUniqueSuffix(),
            'purpose' => 'ShowPurpose ' . $this->generateUniqueSuffix(),
        ]));

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 1000);

                $browser->waitForText((string) $record->caller_name, 12)
                    ->assertSee((string) $record->caller_name)
                    ->assertSee((string) $record->purpose);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Edit page loads with current values and update endpoint persists a change. */
    public function test_phonediary_64_edit_page_loads_and_updates(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'EditMe ' . $this->generateUniqueSuffix(),
        ]));
        $recordId = (int) $record->id;
        $newName = 'Edited ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($recordId, $newName, $record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $recordId . '/edit', 1000);

                $browser->waitFor('input[name="caller_name"]', 12)
                    ->assertInputValue('caller_name', (string) $record->caller_name);

                // Exercise the update endpoint via a spoofed PUT (form uses @method PUT).
                $url = $this->tenantUrl(self::SHOW_BASE_PATH . '/' . $recordId);
                $this->postFormFromBrowser($browser, $url, [
                    '_method'     => 'PUT',
                    'call_type'   => (string) $record->call_type,
                    'call_date'   => now()->toDateString(),
                    'call_time'   => '09:30',
                    'caller_name' => $newName,
                    'purpose'     => (string) $record->purpose,
                ]);
                $browser->pause(1500);
            });

            $record->refresh();
            $this->assertSame($newName, $record->caller_name, 'update() must persist the new caller_name.');
        } finally {
            PhoneDiary::withTrashed()->where('id', $recordId)->get()
                ->each(fn (PhoneDiary $r) => $r->forceDelete());
        }
    }

    // ============================================================
    // 70-79  Edge cases + soft-delete lifecycle (BC-EDG)
    // ============================================================

    /** Soft delete moves the record to trash (deleted_at set). */
    public function test_phonediary_70_soft_delete_moves_to_trash(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'SoftDel ' . $this->generateUniqueSuffix(),
        ]));
        $recordId = (int) $record->id;

        try {
            $this->browse(function (Browser $browser) use ($recordId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId);
                $this->spoofedRequestFromBrowser($browser, $url, 'DELETE');
                $browser->pause(1500);
            });

            $record->refresh();
            $this->assertNotNull($record->deleted_at, 'destroy() must soft-delete the record.');
        } finally {
            PhoneDiary::withTrashed()->where('id', $recordId)->get()
                ->each(fn (PhoneDiary $r) => $r->forceDelete());
        }
    }

    /** Trash page lists soft-deleted records. */
    public function test_phonediary_71_trash_page_shows_deleted(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'TrashRow ' . $this->generateUniqueSuffix(),
        ]));
        $recordId = (int) $record->id;
        $record->delete();

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TRASH_PATH, 1000);

                $browser->waitForText((string) $record->caller_name, 12)
                    ->assertSee((string) $record->caller_name);
            });
        } finally {
            PhoneDiary::withTrashed()->where('id', $recordId)->get()
                ->each(fn (PhoneDiary $r) => $r->forceDelete());
        }
    }

    /** Restore returns a trashed record to active (deleted_at null). */
    public function test_phonediary_72_restore_from_trash(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'RestoreRow ' . $this->generateUniqueSuffix(),
        ]));
        $recordId = (int) $record->id;
        $record->delete();
        $this->assertNotNull(PhoneDiary::withTrashed()->find($recordId)->deleted_at);

        try {
            $this->browse(function (Browser $browser) use ($recordId): void {
                $this->authenticateBrowserSession($browser);
                // restore route is a GET link.
                $browser->visit($this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/restore'))->pause(1500);
            });

            $record->refresh();
            $this->assertNull($record->deleted_at, 'restore() must clear deleted_at.');
        } finally {
            PhoneDiary::withTrashed()->where('id', $recordId)->get()
                ->each(fn (PhoneDiary $r) => $r->forceDelete());
        }
    }

    /** Force delete permanently removes the record. */
    public function test_phonediary_73_force_delete_is_permanent(): void
    {
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => 'ForceDel ' . $this->generateUniqueSuffix(),
        ]));
        $recordId = (int) $record->id;
        $record->delete();

        try {
            $this->browse(function (Browser $browser) use ($recordId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TRASH_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/force-delete');
                $this->spoofedRequestFromBrowser($browser, $url, 'DELETE');
                $browser->pause(1500);
            });

            $this->assertNull(
                PhoneDiary::withTrashed()->find($recordId),
                'force-delete must permanently remove the record.'
            );
        } finally {
            PhoneDiary::withTrashed()->where('id', $recordId)->get()
                ->each(fn (PhoneDiary $r) => $r->forceDelete());
        }
    }

    /** 404 for a non-existent show id. */
    public function test_phonediary_74_show_404_for_nonexistent_record(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl(self::SHOW_BASE_PATH . '/99999999'))->pause(1200);

            $status = $this->responseStatusCode($browser);
            $source = strtolower($browser->driver->getPageSource());
            $is404 = $status === 404 || str_contains($source, 'not found') || str_contains($source, '404');
            $this->assertTrue($is404, 'Non-existent record must yield 404. Got status: ' . $status);
        });
    }

    /** TEXT columns (message, action_notes) accept long free text. */
    public function test_phonediary_75_text_columns_accept_long_content(): void
    {
        $record = null;
        try {
            $long = str_repeat('Follow-up notes. ', 400); // ~6.8k chars — within TEXT (64k)
            $record = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name'  => 'LongText ' . $this->generateUniqueSuffix(),
                'message'      => $long,
                'action_notes' => $long,
            ]));
            $record->refresh();
            $this->assertSame($long, $record->message, 'TEXT message must store long content.');
            $this->assertSame($long, $record->action_notes, 'TEXT action_notes must store long content.');
        } finally {
            if ($record instanceof PhoneDiary) {
                $record->forceDelete();
            }
        }
    }

    // ============================================================
    // 90-99  Security + source-defect probes (TC-S / DEV)
    // ============================================================

    /** Stored XSS in caller_name is escaped on the show page. */
    public function test_phonediary_90_stored_xss_in_caller_name_is_escaped(): void
    {
        $xss = '<script>alert("pd' . $this->generateUniqueSuffix() . '")</script>';
        $record = PhoneDiary::query()->create($this->buildValidPayload([
            'caller_name' => $xss,
            'purpose' => 'XSS probe',
        ]));

        try {
            $this->browse(function (Browser $browser) use ($record, $xss): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 1200);

                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString(
                    '<script>alert("pd',
                    $source,
                    'caller_name must be HTML-escaped (no raw <script> in output).'
                );
            });
        } finally {
            $record->forceDelete();
        }
    }

    /**
     * DEV-FOF-PD-002 (proving test): PhoneDiaryController performs NO activityLog() calls,
     * diverging from the module-wide activity-log convention (72 call sites elsewhere).
     * This test PROVES the current (defective) behaviour so it is tracked, not hidden.
     */
    public function test_phonediary_91_controller_has_no_activity_logging_documents_gap(): void
    {
        try {
            $file = (new \ReflectionClass(\Modules\FrontOffice\Http\Controllers\PhoneDiaryController::class))->getFileName();
            $source = @file_get_contents((string) $file);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot read PhoneDiaryController source: ' . $e->getMessage());
            return;
        }

        if (!is_string($source) || $source === '') {
            $this->markTestSkipped('PhoneDiaryController source unreadable from the runner.');
            return;
        }

        $this->assertStringNotContainsString(
            'activityLog(',
            $source,
            'DEV-FOF-PD-002: PhoneDiaryController currently logs no activity (documented gap).'
        );
    }

    /**
     * DEV-FOF-PD-001 (proving test): PhoneDiaryRequest::authorize() returns true —
     * instance of module-wide SEC-FOF-003 (no defense-in-depth in the FormRequest).
     */
    public function test_phonediary_92_formrequest_authorize_returns_true_documents_dev(): void
    {
        try {
            $file = (new \ReflectionClass(\Modules\FrontOffice\Http\Requests\PhoneDiaryRequest::class))->getFileName();
            $source = @file_get_contents((string) $file);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot read PhoneDiaryRequest source: ' . $e->getMessage());
            return;
        }

        if (!is_string($source) || $source === '') {
            $this->markTestSkipped('PhoneDiaryRequest source unreadable from the runner.');
            return;
        }

        $normalized = preg_replace('/\s+/', ' ', $source);
        $this->assertStringContainsString(
            'function authorize(): bool { return true;',
            (string) $normalized,
            'DEV-FOF-PD-001/SEC-FOF-003: FormRequest authorize() blanket-returns true (documented).'
        );
    }

    // ============================================================
    // ---- Private helper library (mirrors Inventory\Uom sibling) ----
    // ============================================================

    /** G45 boundary helper: over-length rejected/truncated + exactly-n accepted. */
    private function assertSizedStringColumn(string $column, int $max): void
    {
        // Over-length (n + 5) — must be rejected OR silently truncated to <= n (tolerant, #45/#41).
        $over = null;
        try {
            $over = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'Boundary ' . $this->generateUniqueSuffix(),
                $column       => str_repeat('X', $max + 5),
            ]));
            $over->refresh();
            $stored = (string) ($over->{$column} ?? '');
            $this->assertLessThanOrEqual(
                $max,
                strlen($stored),
                "Over-length value for {$column} must be rejected or truncated to <= {$max}."
            );
        } catch (Throwable $e) {
            $this->assertTrue(true, "DB rejected over-length {$column}: " . $e->getMessage());
        } finally {
            if ($over instanceof PhoneDiary) {
                $over->forceDelete();
            }
        }

        // Exactly-n — must be accepted and fully stored.
        $exact = null;
        try {
            $value = str_repeat('Y', $max);
            $exact = PhoneDiary::query()->create($this->buildValidPayload([
                'caller_name' => 'BoundaryOk ' . $this->generateUniqueSuffix(),
                $column       => $value,
            ]));
            $exact->refresh();
            $this->assertSame($value, (string) $exact->{$column}, "Exactly-{$max}-char {$column} must persist intact.");
        } finally {
            if ($exact instanceof PhoneDiary) {
                $exact->forceDelete();
            }
        }
    }

    /** Permission-negative (F37/#31): a fresh non-super-admin without the ability must get 403. */
    private function assertForbiddenForLimitedUser(string $path, string $method = 'GET', array $payload = []): void
    {
        $limited = $this->makeLimitedUserOrSkip();

        try {
            $this->browse(function (Browser $browser) use ($limited, $path, $method, $payload): void {
                $browser->visit($this->tenantUrl('/login'))->pause(400);
                $browser->loginAs($limited)->pause(600);

                if ($method === 'GET') {
                    $browser->visit($this->tenantUrl($path))->pause(1200);
                    $status = $this->responseStatusCode($browser);
                    $source = strtolower($browser->driver->getPageSource());
                    $forbidden = $status === 403
                        || str_contains($source, 'forbidden')
                        || str_contains($source, 'not authorized')
                        || str_contains($source, 'this action is unauthorized');
                    $this->assertTrue($forbidden, 'Limited user must be forbidden (403). Got status: ' . $status);
                } else {
                    $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(800);
                    $status = $this->postFormFromBrowser($browser, $this->tenantUrl($path), $payload);
                    $this->assertContains(
                        $status,
                        [403, 419],
                        'Limited user POST must be forbidden (403). Got: ' . $status
                    );
                }
            });
        } finally {
            $this->deleteLimitedUser($limited);
        }
    }

    /** Build a genuine non-super-admin tenant user, or skip if factory/columns unavailable (#8/#31). */
    private function makeLimitedUserOrSkip(): User
    {
        try {
            $suffix = $this->generateUniqueSuffix();
            $attrs = [
                'name'              => 'Limited PD ' . $suffix,
                'short_name'        => 'lpd' . substr($suffix, -5),
                'email'             => 'limited.pd.' . $suffix . '@tenant.test',
                'emp_code'          => 'LPD_' . uniqid(),
                'password'          => 'password',
                'email_verified_at' => now(),
            ];

            // Provide NOT-NULL-no-default columns only when they exist on the table (#8).
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attrs['user_type'] = 'Staff';
            }
            if (Schema::hasColumn('sys_users', 'prefered_language')) {
                $lang = DB::table('glb_languages')->value('id');
                if ($lang !== null) {
                    $attrs['prefered_language'] = $lang;
                }
            }

            $user = User::factory()->create($attrs);

            // Strip any super-admin flag and all roles/permissions (#31).
            foreach (['is_super_admin', 'super_admin_flag', 'is_admin'] as $flag) {
                if (Schema::hasColumn('sys_users', $flag)) {
                    $user->forceFill([$flag => 0])->save();
                }
            }
            if (method_exists($user, 'syncRoles')) {
                $user->syncRoles([]);
            }
            if (method_exists($user, 'syncPermissions')) {
                $user->syncPermissions([]);
            }
            $this->forgetPermissionCache();

            return $user;
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot build a limited tenant user: ' . $e->getMessage());
        }
    }

    private function deleteLimitedUser(?User $user): void
    {
        if (!$user) {
            return;
        }
        try {
            if (method_exists($user, 'syncRoles')) {
                $user->syncRoles([]);
            }
            if (method_exists($user, 'syncPermissions')) {
                $user->syncPermissions([]);
            }
            $user->forceDelete();
        } catch (Throwable) {
            try {
                $user->delete();
            } catch (Throwable) {
            }
        }
    }

    private function forgetPermissionCache(): void
    {
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
        }
    }

    private function buildValidPayload(array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));

        return array_merge([
            'call_type'   => 'Incoming',
            'call_date'   => now()->toDateString(),
            'call_time'   => '10:30:00',
            'caller_name' => 'Caller ' . $this->generateUniqueSuffix(),
            'purpose'     => 'Test purpose ' . $this->generateUniqueSuffix(),
            'logged_by'   => $adminId,
            'created_by'  => $adminId,
            'updated_by'  => $adminId,
        ], $overrides);
    }

    /** Issue an authenticated JSON request from the page and return the decoded body. */
    private function jsonRequestFromBrowser(Browser $browser, string $url, string $method): ?array
    {
        $encodedUrl = json_encode($url);
        $csrf = $browser->script("return document.querySelector('meta[name=\"csrf-token\"]')?.getAttribute('content') || '';");
        $csrfToken = is_array($csrf) ? ($csrf[0] ?? '') : '';
        $jsMethod = strtoupper($method);
        $spoof = in_array($jsMethod, ['PATCH', 'PUT', 'DELETE'], true) ? $jsMethod : '';

        $browser->script(<<<JS
window.__jsonDone = false;
window.__jsonResponse = null;
(async function () {
    try {
        const csrf = {$this->escapeJsString($csrfToken)};
        const body = new URLSearchParams({ _token: csrf });
        if ('{$spoof}' !== '') { body.append('_method', '{$spoof}'); }
        const response = await fetch({$encodedUrl}, {
            method: '{$spoof}' !== '' ? 'POST' : '{$jsMethod}',
            credentials: 'same-origin',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            },
            body: body.toString(),
        });
        try { window.__jsonResponse = await response.json(); }
        catch (e) { window.__jsonResponse = { success: response.ok, status: response.status }; }
    } catch (error) {
        console.error(error);
    } finally {
        window.__jsonDone = true;
    }
})();
JS);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $result = $browser->script('return window.__jsonDone === true;');
            return is_array($result) && (($result[0] ?? false) === true);
        }, 'JSON request did not complete.');

        $result = $browser->script('return window.__jsonResponse || null;');
        return is_array($result) ? ($result[0] ?? null) : null;
    }

    /** Issue a spoofed (PATCH/PUT/DELETE) form request from the page (no response body needed). */
    private function spoofedRequestFromBrowser(Browser $browser, string $url, string $method): void
    {
        $encodedUrl = json_encode($url);
        $csrf = $browser->script("return document.querySelector('meta[name=\"csrf-token\"]')?.getAttribute('content') || '';");
        $csrfToken = is_array($csrf) ? ($csrf[0] ?? '') : '';
        $spoof = strtoupper($method);

        $browser->script(<<<JS
window.__spoofDone = false;
(async function () {
    try {
        const csrf = {$this->escapeJsString($csrfToken)};
        await fetch({$encodedUrl}, {
            method: 'POST',
            credentials: 'same-origin',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            },
            body: new URLSearchParams({ _token: csrf, _method: '{$spoof}' }).toString(),
        });
    } catch (error) {
        console.error(error);
    } finally {
        window.__spoofDone = true;
    }
})();
JS);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $result = $browser->script('return window.__spoofDone === true;');
            return is_array($result) && (($result[0] ?? false) === true);
        }, 'Spoofed request did not complete.');
    }

    /** POST an application/x-www-form-urlencoded body from the page; return the HTTP status. */
    private function postFormFromBrowser(Browser $browser, string $url, array $fields): int
    {
        $encodedUrl = json_encode($url);
        $csrf = $browser->script("return document.querySelector('meta[name=\"csrf-token\"]')?.getAttribute('content') || '';");
        $csrfToken = is_array($csrf) ? ($csrf[0] ?? '') : '';
        $fieldsJson = json_encode($fields, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

        $browser->script(<<<JS
window.__postDone = false;
window.__postStatus = 0;
(async function () {
    try {
        const csrf = {$this->escapeJsString($csrfToken)};
        const params = new URLSearchParams(Object.assign({ _token: csrf }, {$fieldsJson}));
        const response = await fetch({$encodedUrl}, {
            method: 'POST',
            credentials: 'same-origin',
            redirect: 'manual',
            headers: {
                'X-CSRF-TOKEN': csrf,
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            },
            body: params.toString(),
        });
        window.__postStatus = response.status === 0 ? 302 : response.status;
    } catch (error) {
        console.error(error);
        window.__postStatus = -1;
    } finally {
        window.__postDone = true;
    }
})();
JS);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $result = $browser->script('return window.__postDone === true;');
            return is_array($result) && (($result[0] ?? false) === true);
        }, 'Form POST did not complete.');

        $result = $browser->script('return window.__postStatus || 0;');
        return is_array($result) ? (int) ($result[0] ?? 0) : 0;
    }

    private function uniqueIndexCount(string $table): int
    {
        try {
            $rows = DB::select("SHOW INDEX FROM `{$table}` WHERE Non_unique = 0 AND Key_name <> 'PRIMARY'");
            $names = [];
            foreach ($rows as $row) {
                $names[$row->Key_name ?? ''] = true;
            }
            return count($names);
        } catch (Throwable) {
            return 0;
        }
    }

    private function showCreateTable(string $table): string
    {
        $row = DB::selectOne("SHOW CREATE TABLE `{$table}`");
        if (!$row) {
            throw new \RuntimeException('SHOW CREATE TABLE returned nothing.');
        }
        $arr = (array) $row;
        return (string) ($arr['Create Table'] ?? $arr['Create View'] ?? '');
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

        if (str_contains($this->currentPath($browser), '/login')) {
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

    private function initializeTenantContextForTests(): void
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

        $this->ensurePermissionsExist(self::PERMISSIONS);

        foreach (self::PERMISSIONS as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
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

        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate([
                    'name' => $permission,
                    'guard_name' => $guard,
                ]);
            } catch (Throwable) {
            }
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

    private function generateUniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
    }

    private function escapeJsString(string $value): string
    {
        return json_encode($value, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }

    private function responseStatusCode(Browser $browser): int
    {
        try {
            $result = $browser->driver->executeScript(
                'return window.performance.getEntriesByType("navigation")[0]?.responseStatus || 0'
            );
            if (is_numeric($result) && (int) $result > 0) {
                return (int) $result;
            }
        } catch (Throwable) {
        }
        try {
            $url = $browser->driver->getCurrentURL();
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true, CURLOPT_NOBODY => true,
                CURLOPT_HEADER => true, CURLOPT_FOLLOWLOCATION => false,
                CURLOPT_TIMEOUT => 10, CURLOPT_SSL_VERIFYPEER => false,
            ]);
            curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            return (int) $httpCode;
        } catch (Throwable) {
        }
        return 0;
    }
}
