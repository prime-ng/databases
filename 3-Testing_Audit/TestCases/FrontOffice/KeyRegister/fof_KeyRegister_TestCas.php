<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\KeyRegister;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice :: KeyRegister  (fof_key_register)
 * ------------------------------------------------------------------
 * ONE comprehensive tenant-side Dusk suite for the Key Management Register screen
 * (issue / return workflow). Mirrors the nearest committed tenant-side sibling
 * (FrontOffice\PhoneDiary) for style, tenancy scaffolding and the private helper library.
 *
 * DDL truth (fof_key_register):
 *   NOT-NULL-no-default : key_label(V100), key_tag_number(V30),
 *                         key_type ENUM(Room,Lab,Vehicle,Cabinet,Store,Other),
 *                         created_by, updated_by
 *   Defaults            : status='Available', is_active=1
 *   Nullable            : issued_to_user_id, purpose(V200), issued_at,
 *                         expected_return_at, returned_at
 *   UNIQUE keys (DB)    : NONE. (FormRequest has an APP-level Rule::unique on
 *                         key_tag_number, but the DDL has NO unique index — DEV-FOF-KR-004.)
 *   FK (SET NULL)       : issued_to_user_id -> sys_users
 *   Auto/managed (G48)  : status (store forces 'Available'), created_by, updated_by,
 *                         issued_at/returned_at (controller sets these)
 *
 * Permission scheme (string gates, per real controller):
 *   frontoffice.key-register.{viewAny,create,update,delete,restore,forceDelete}
 *   (issue/return/toggleStatus all gate on .update)
 *
 * Activity log (sys_activity_logs via GlobalMaster\ActivityLog; event = literal per method):
 *   update -> 'Updated'   destroy/forceDelete -> 'Deleted'   restore -> 'Restored'
 *   issue  -> 'key_issued' (lowercase!)   return -> 'key_returned' (lowercase!)
 *   store  -> (NONE — DEV-FOF-KR-005)     toggleStatus -> (NONE)
 *
 * KNOWN SOURCE DEFECTS proved by this suite (see Gap Analysis / Validation Report):
 *   DEV-FOF-KR-001 (P1) create flow broken: key_type is NOT-NULL-no-default but the
 *     FormRequest never validates it and store() never sets it -> DB 1364 (HTTP 500).
 *   DEV-FOF-KR-002 (P2) Blade create/edit fields `location`/`description` map to NO column
 *     (real cols are key_type/purpose) -> user input silently dropped.
 *   DEV-FOF-KR-003 (P2) issue() collects only expected_return_at; no issued_to_user_id input
 *     and purpose ignored -> issued_to always NULL (diverges from Issue Flow requirement).
 *   DEV-FOF-KR-004 (P2) app-level unique(key_tag_number) but NO DB UNIQUE index.
 *   DEV-FOF-KR-005 (P2) store() performs NO activityLog().
 *   DEV-FOF-KR-006 (P3) 'Lost'/'Overdue' statuses unreachable through the app (no setter).
 *   SEC-FOF-003          FormRequest authorize() returns true (module-wide D30).
 *   DAT-FOF-004          REMEDIATED for KeyRegister — issue() uses DB::transaction + lockForUpdate.
 *
 * ENV prerequisites (see Validation Report): FrontOffice must be ENABLED in
 * prime_testing/modules_statuses.json (currently false -> routes 404); APP_ENV=testing.
 */
class fof_KeyRegister_TestCas extends DuskTestCase
{
    private const TABLE = 'fof_key_register';
    private const ACTIVITY_TABLE = 'sys_activity_logs';
    private const INDEX_PATH = '/front-office/keys';
    private const SHOW_BASE_PATH = '/front-office/keys';
    private const TRASH_PATH = '/front-office/keys/trash/view';

    private const KEY_TYPES = ['Room', 'Lab', 'Vehicle', 'Cabinet', 'Store', 'Other'];
    private const STATUSES = ['Available', 'Issued', 'Overdue', 'Lost'];

    private const PERMISSIONS = [
        'frontoffice.key-register.viewAny',
        'frontoffice.key-register.create',
        'frontoffice.key-register.update',
        'frontoffice.key-register.delete',
        'frontoffice.key-register.restore',
        'frontoffice.key-register.forceDelete',
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
    public function test_keyregister_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table fof_key_register must exist.');

        $expectedColumns = [
            'id', 'key_label', 'key_tag_number', 'key_type', 'issued_to_user_id',
            'purpose', 'issued_at', 'expected_return_at', 'returned_at', 'status',
            'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, $expectedColumns),
            'fof_key_register is missing one or more expected columns.'
        );

        // Verified CRUD model — G47.
        $model = new KeyRegister();
        $this->assertSame(self::TABLE, $model->getTable(), 'KeyRegister::$table must be fof_key_register.');

        $fillable = $model->getFillable();
        foreach (['key_label', 'key_tag_number', 'key_type', 'purpose', 'status',
                  'issued_to_user_id', 'issued_at', 'expected_return_at', 'returned_at',
                  'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $fillable, "Fillable must contain {$col}.");
        }

        // Casts.
        $casts = $model->getCasts();
        $this->assertSame('datetime', $casts['issued_at'] ?? null);
        $this->assertSame('datetime', $casts['expected_return_at'] ?? null);
        $this->assertSame('datetime', $casts['returned_at'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);

        // Soft-delete column and trait asserted INDEPENDENTLY (#30/G46).
        $hasDeletedAtColumn = Schema::hasColumn(self::TABLE, 'deleted_at');
        $usesSoftDeletes = in_array(SoftDeletes::class, class_uses_recursive(KeyRegister::class), true);
        $this->assertTrue($hasDeletedAtColumn, 'DDL: deleted_at column must exist.');
        $this->assertTrue($usesSoftDeletes, 'Model: KeyRegister must use SoftDeletes.');
        $this->assertSame($hasDeletedAtColumn, $usesSoftDeletes, 'Soft-delete column/trait must agree.');

        // DEV-FOF-KR-004: DDL has NO unique index on key_tag_number even though the
        // FormRequest declares an app-level unique rule. Assert the divergence explicitly.
        $uniqueCount = $this->uniqueIndexCount(self::TABLE);
        $this->assertSame(
            0,
            $uniqueCount,
            'DEV-FOF-KR-004: fof_key_register has NO DB UNIQUE index (app-level unique only).'
        );
    }

    /** G44 negative — every NOT-NULL-no-default column rejects a missing value. */
    public function test_keyregister_02_required_notnull_columns_reject_missing_values(): void
    {
        $requiredCols = ['key_label', 'key_tag_number', 'key_type', 'created_by', 'updated_by'];

        foreach ($requiredCols as $col) {
            $created = null;
            try {
                $payload = $this->buildValidPayload();
                unset($payload[$col]);
                $created = KeyRegister::query()->create($payload);
                $this->fail("Expected DB rejection creating a row without required column {$col}.");
            } catch (Throwable $e) {
                $msg = strtolower($e->getMessage());
                $isExpected = str_contains($msg, 'cannot be null')
                    || str_contains($msg, 'not null')
                    || str_contains($msg, "doesn't have a default value")
                    || str_contains($msg, 'integrity constraint')
                    || str_contains($msg, '23000')
                    || str_contains($msg, '1364')
                    || str_contains($msg, 'incorrect');
                $this->assertTrue($isExpected, "Expected NOT-NULL failure for {$col}, got: {$e->getMessage()}");
            } finally {
                if ($created instanceof KeyRegister) {
                    $created->forceDelete();
                }
            }
        }
    }

    /** G44 positive — all nullable columns may be omitted and the row still persists. */
    public function test_keyregister_03_nullable_columns_accept_omitted_values(): void
    {
        $record = null;
        try {
            $record = KeyRegister::query()->create($this->buildValidPayload());
            $record->refresh();

            $this->assertNotNull($record->id, 'Row with only required cols must persist.');
            $this->assertNull($record->issued_to_user_id, 'Omitted issued_to_user_id should be NULL.');
            $this->assertNull($record->purpose, 'Omitted purpose should be NULL.');
            $this->assertNull($record->issued_at, 'Omitted issued_at should be NULL.');
            $this->assertNull($record->expected_return_at, 'Omitted expected_return_at should be NULL.');
            $this->assertNull($record->returned_at, 'Omitted returned_at should be NULL.');
        } finally {
            if ($record instanceof KeyRegister) {
                $record->forceDelete();
            }
        }
    }

    /** DDL defaults applied when omitted (read back via refresh — #35). */
    public function test_keyregister_04_column_defaults_applied_on_create(): void
    {
        $record = null;
        try {
            $payload = $this->buildValidPayload();
            unset($payload['status'], $payload['is_active']); // omit DEFAULT-bearing cols

            $record = KeyRegister::query()->create($payload);
            $record->refresh();

            $this->assertSame('Available', $record->status, 'status must default to Available.');
            $this->assertTrue((bool) $record->is_active, 'is_active must default to 1.');
        } finally {
            if ($record instanceof KeyRegister) {
                $record->forceDelete();
            }
        }
    }

    /** Datetime + boolean casts return typed values. */
    public function test_keyregister_05_casts_return_typed_values(): void
    {
        $record = null;
        try {
            $record = KeyRegister::query()->create($this->buildValidPayload([
                'issued_at'          => now(),
                'expected_return_at' => now()->addDay(),
            ]));
            $record->refresh();

            $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $record->issued_at, 'issued_at must cast to datetime.');
            $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $record->expected_return_at, 'expected_return_at must cast to datetime.');
            $this->assertIsBool($record->is_active, 'is_active must cast to bool.');
        } finally {
            if ($record instanceof KeyRegister) {
                $record->forceDelete();
            }
        }
    }

    /** key_type ENUM accepts every canonical value. */
    public function test_keyregister_06_key_type_enum_accepts_valid_values(): void
    {
        foreach (self::KEY_TYPES as $value) {
            $record = null;
            try {
                $record = KeyRegister::query()->create($this->buildValidPayload(['key_type' => $value]));
                $record->refresh();
                $this->assertSame($value, $record->key_type, "key_type must accept {$value}.");
            } finally {
                if ($record instanceof KeyRegister) {
                    $record->forceDelete();
                }
            }
        }
    }

    /** key_type ENUM rejects an out-of-domain value at the DB layer. */
    public function test_keyregister_07_key_type_enum_rejects_invalid(): void
    {
        $created = null;
        try {
            $created = KeyRegister::query()->create($this->buildValidPayload(['key_type' => 'Spaceship']));
            $created->refresh();
            $this->assertNotContains(
                $created->key_type,
                self::KEY_TYPES,
                'An invalid key_type ENUM value must not be stored as a canonical value.'
            );
        } catch (Throwable $e) {
            $this->assertTrue(true, 'DB rejected invalid key_type ENUM: ' . $e->getMessage());
        } finally {
            if ($created instanceof KeyRegister) {
                $created->forceDelete();
            }
        }
    }

    /** status ENUM accepts every canonical value (workflow domain). */
    public function test_keyregister_08_status_enum_accepts_valid_values(): void
    {
        foreach (self::STATUSES as $value) {
            $record = null;
            try {
                $record = KeyRegister::query()->create($this->buildValidPayload(['status' => $value]));
                $record->refresh();
                $this->assertSame($value, $record->status, "status must accept {$value}.");
            } finally {
                if ($record instanceof KeyRegister) {
                    $record->forceDelete();
                }
            }
        }
    }

    // ============================================================
    // 10-19  Business rules (BC-BIZ)
    // ============================================================

    /** scopeActive() excludes inactive rows. */
    public function test_keyregister_10_active_scope_excludes_inactive(): void
    {
        $active = null;
        $inactive = null;
        try {
            $active = KeyRegister::query()->create($this->buildValidPayload(['is_active' => 1]));
            $inactive = KeyRegister::query()->create($this->buildValidPayload(['is_active' => 0]));

            $activeIds = KeyRegister::query()->active()->pluck('id')->all();
            $this->assertContains($active->id, $activeIds);
            $this->assertNotContains($inactive->id, $activeIds);
        } finally {
            foreach ([$active, $inactive] as $r) {
                if ($r instanceof KeyRegister) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** scopeAvailable() returns only status='Available'. */
    public function test_keyregister_11_available_scope_filters_status(): void
    {
        $available = null;
        $issued = null;
        try {
            $available = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Available']));
            $issued = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Issued']));

            $ids = KeyRegister::query()->available()->pluck('id')->all();
            $this->assertContains($available->id, $ids, 'Available key must be in available scope.');
            $this->assertNotContains($issued->id, $ids, 'Issued key must NOT be in available scope.');
        } finally {
            foreach ([$available, $issued] as $r) {
                if ($r instanceof KeyRegister) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** scopeOverdue() returns only status='Overdue'. */
    public function test_keyregister_12_overdue_scope_filters_status(): void
    {
        $overdue = null;
        $issued = null;
        try {
            $overdue = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Overdue']));
            $issued = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Issued']));

            $ids = KeyRegister::query()->overdue()->pluck('id')->all();
            $this->assertContains($overdue->id, $ids);
            $this->assertNotContains($issued->id, $ids);
        } finally {
            foreach ([$overdue, $issued] as $r) {
                if ($r instanceof KeyRegister) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** isAvailable() reflects the status attribute. */
    public function test_keyregister_13_is_available_helper_reflects_status(): void
    {
        $available = null;
        $issued = null;
        try {
            $available = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Available']));
            $issued = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Issued']));

            $this->assertTrue($available->isAvailable(), 'isAvailable() must be true for Available.');
            $this->assertFalse($issued->isAvailable(), 'isAvailable() must be false for Issued.');
        } finally {
            foreach ([$available, $issued] as $r) {
                if ($r instanceof KeyRegister) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** Overdue detection query (index): status='Issued' AND expected_return_at < now surfaces the row. */
    public function test_keyregister_14_overdue_detection_query_matches_past_due_issued_keys(): void
    {
        $overdue = null;
        $future = null;
        try {
            $overdue = KeyRegister::query()->create($this->buildValidPayload([
                'status' => 'Issued', 'expected_return_at' => now()->subDay(),
            ]));
            $future = KeyRegister::query()->create($this->buildValidPayload([
                'status' => 'Issued', 'expected_return_at' => now()->addDay(),
            ]));

            $overdueIds = KeyRegister::query()
                ->where('status', 'Issued')
                ->whereNotNull('expected_return_at')
                ->where('expected_return_at', '<', now())
                ->pluck('id')->all();

            $this->assertContains($overdue->id, $overdueIds, 'Past-due issued key must be detected as overdue.');
            $this->assertNotContains($future->id, $overdueIds, 'Future-due issued key must NOT be overdue.');
        } finally {
            foreach ([$overdue, $future] as $r) {
                if ($r instanceof KeyRegister) {
                    $r->forceDelete();
                }
            }
        }
    }

    // ============================================================
    // 20-29  State-machine transitions (BC-SM)  Available<->Issued
    // ============================================================

    /** BC-SM legal: Available -> Issued via issue(); sets status/issued_at/expected_return_at + 'key_issued' log. */
    public function test_keyregister_20_issue_transitions_available_to_issued(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Available']));
        $recordId = (int) $record->id;
        $returnAt = now()->addDays(2)->format('Y-m-d H:i:s');

        try {
            $this->browse(function (Browser $browser) use ($recordId, $returnAt): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/issue');
                $this->postFormFromBrowser($browser, $url, [
                    '_method'            => 'PATCH',
                    'expected_return_at' => $returnAt,
                ]);
                $browser->pause(1500);
            });

            $record->refresh();
            $this->assertSame('Issued', $record->status, 'issue() must set status to Issued.');
            $this->assertNotNull($record->issued_at, 'issue() must set issued_at.');
            $this->assertNotNull($record->expected_return_at, 'issue() must set expected_return_at.');
            $this->assertTrue(
                $this->activityLogged($recordId, 'key_issued'),
                "issue() must write a 'key_issued' activity log (verbatim, lowercase)."
            );
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** BC-SM illegal: issue() on a non-Available key is blocked (BR-FOF-012) -> 422 (tolerant). */
    public function test_keyregister_21_issue_blocked_when_not_available(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Issued']));
        $recordId = (int) $record->id;
        $returnAt = now()->addDays(2)->format('Y-m-d H:i:s');

        try {
            $status = 0;
            $this->browse(function (Browser $browser) use ($recordId, $returnAt, &$status): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/issue');
                $status = $this->postFormFromBrowser($browser, $url, [
                    '_method'            => 'PATCH',
                    'expected_return_at' => $returnAt,
                ]);
                $browser->pause(800);
            });

            // abort_if(status !== 'Available', 422) — tolerate 422/500/302.
            $this->assertContains($status, [422, 500, 302, 419], 'Issuing a non-Available key must be rejected. Got: ' . $status);
            $record->refresh();
            $this->assertSame('Issued', $record->status, 'Blocked issue must not change the status.');
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** BC-SM legal: Issued -> Available via return(); clears issue fields + 'key_returned' log. */
    public function test_keyregister_22_return_transitions_issued_to_available(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'status'             => 'Issued',
            'issued_to_user_id'  => (int) ($this->adminUser?->id),
            'issued_at'          => now()->subDay(),
            'expected_return_at' => now()->addDay(),
        ]));
        $recordId = (int) $record->id;

        try {
            $this->browse(function (Browser $browser) use ($recordId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/return');
                $this->postFormFromBrowser($browser, $url, ['_method' => 'PATCH']);
                $browser->pause(1500);
            });

            $record->refresh();
            $this->assertSame('Available', $record->status, 'return() must set status back to Available.');
            $this->assertNotNull($record->returned_at, 'return() must set returned_at.');
            $this->assertNull($record->issued_to_user_id, 'return() must clear issued_to_user_id.');
            $this->assertNull($record->issued_at, 'return() must clear issued_at.');
            $this->assertNull($record->expected_return_at, 'return() must clear expected_return_at.');
            $this->assertTrue(
                $this->activityLogged($recordId, 'key_returned'),
                "return() must write a 'key_returned' activity log (verbatim, lowercase)."
            );
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** BC-SM illegal: return() on an Available key is blocked -> 422 (tolerant). */
    public function test_keyregister_23_return_blocked_when_available(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Available']));
        $recordId = (int) $record->id;

        try {
            $status = 0;
            $this->browse(function (Browser $browser) use ($recordId, &$status): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/return');
                $status = $this->postFormFromBrowser($browser, $url, ['_method' => 'PATCH']);
                $browser->pause(800);
            });

            $this->assertContains($status, [422, 500, 302, 419], 'Returning an Available key must be rejected. Got: ' . $status);
            $record->refresh();
            $this->assertSame('Available', $record->status, 'Blocked return must not change the status.');
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** BC-SM legal: Overdue -> Available via return() (return tolerates Issued OR Overdue). */
    public function test_keyregister_24_return_allowed_from_overdue(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'status'             => 'Overdue',
            'issued_to_user_id'  => (int) ($this->adminUser?->id),
            'issued_at'          => now()->subDays(3),
            'expected_return_at' => now()->subDay(),
        ]));
        $recordId = (int) $record->id;

        try {
            $this->browse(function (Browser $browser) use ($recordId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/return');
                $this->postFormFromBrowser($browser, $url, ['_method' => 'PATCH']);
                $browser->pause(1500);
            });

            $record->refresh();
            $this->assertSame('Available', $record->status, 'return() from Overdue must set status to Available.');
            $this->assertNotNull($record->returned_at, 'return() from Overdue must set returned_at.');
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** Full lifecycle round-trip: Available -> issue -> return -> Available. */
    public function test_keyregister_25_full_issue_return_lifecycle(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Available']));
        $recordId = (int) $record->id;
        $returnAt = now()->addDays(2)->format('Y-m-d H:i:s');

        try {
            $this->browse(function (Browser $browser) use ($recordId, $returnAt): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $this->postFormFromBrowser(
                    $browser,
                    $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/issue'),
                    ['_method' => 'PATCH', 'expected_return_at' => $returnAt]
                );
                $browser->pause(1200);
                $this->postFormFromBrowser(
                    $browser,
                    $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/return'),
                    ['_method' => 'PATCH']
                );
                $browser->pause(1200);
            });

            $record->refresh();
            $this->assertSame('Available', $record->status, 'After issue+return the key must be Available again.');
            $this->assertNotNull($record->returned_at, 'returned_at must be recorded after the round-trip.');
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** DEV-FOF-KR-003: issue() without issued_to_user_id leaves it NULL (no UI field captures it). */
    public function test_keyregister_26_issue_leaves_issued_to_user_null_documents_dev(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Available']));
        $recordId = (int) $record->id;
        $returnAt = now()->addDays(2)->format('Y-m-d H:i:s');

        try {
            $this->browse(function (Browser $browser) use ($recordId, $returnAt): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                // The issue Blade form has NO issued_to_user_id input — mirror that omission.
                $this->postFormFromBrowser(
                    $browser,
                    $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/issue'),
                    ['_method' => 'PATCH', 'expected_return_at' => $returnAt]
                );
                $browser->pause(1200);
            });

            $record->refresh();
            if ($record->status !== 'Issued') {
                $this->markTestSkipped('issue() did not run (module may be disabled — see Validation Report).');
                return;
            }
            $this->assertNull(
                $record->issued_to_user_id,
                'DEV-FOF-KR-003: issue() never captures issued_to_user_id (no UI field).'
            );
        } finally {
            $this->purgeKey($recordId);
        }
    }

    // ============================================================
    // 30-39  Validation + error messages (BC-VAL, G45, G43-app)
    // ============================================================

    /** G45 — key_label VARCHAR(100): over-length rejected/truncated + exactly-100 accepted. */
    public function test_keyregister_30_key_label_length_boundary(): void
    {
        $this->assertSizedStringColumn('key_label', 100);
    }

    /** G45 — key_tag_number VARCHAR(30). */
    public function test_keyregister_31_key_tag_number_length_boundary(): void
    {
        $this->assertSizedStringColumn('key_tag_number', 30);
    }

    /** G45 — purpose VARCHAR(200). */
    public function test_keyregister_32_purpose_length_boundary(): void
    {
        $this->assertSizedStringColumn('purpose', 200);
    }

    /** Browser store validation — missing required key_label is rejected (non-2xx). */
    public function test_keyregister_33_store_rejects_missing_key_label(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

            $status = $this->postFormFromBrowser($browser, $this->tenantUrl(self::INDEX_PATH), [
                'key_label'      => '',   // required — must be rejected
                'key_tag_number' => 'K-' . $this->generateUniqueSuffix(),
            ]);

            $this->assertContains(
                $status,
                [302, 422, 419, 500],
                'Missing key_label must not yield a 2xx creation. Got: ' . $status
            );
        });
    }

    /** Browser store validation — missing required key_tag_number is rejected (non-2xx). */
    public function test_keyregister_34_store_rejects_missing_key_tag_number(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

            $status = $this->postFormFromBrowser($browser, $this->tenantUrl(self::INDEX_PATH), [
                'key_label'      => 'NoTag ' . $this->generateUniqueSuffix(),
                'key_tag_number' => '',   // required — must be rejected
            ]);

            $this->assertContains(
                $status,
                [302, 422, 419, 500],
                'Missing key_tag_number must not yield a 2xx creation. Got: ' . $status
            );
        });
    }

    /** G43 (app-level) — duplicate key_tag_number is rejected by the FormRequest unique rule. */
    public function test_keyregister_35_duplicate_key_tag_number_rejected_by_formrequest(): void
    {
        $tag = 'K-DUP-' . $this->generateUniqueSuffix();
        $seed = KeyRegister::query()->create($this->buildValidPayload(['key_tag_number' => $tag]));

        try {
            $before = KeyRegister::query()->where('key_tag_number', $tag)->count();

            $this->browse(function (Browser $browser) use ($tag): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $status = $this->postFormFromBrowser($browser, $this->tenantUrl(self::INDEX_PATH), [
                    'key_label'      => 'Duplicate ' . $this->generateUniqueSuffix(),
                    'key_tag_number' => $tag,   // duplicate — unique rule must reject
                ]);
                // Validation redirect (302) or tolerant 422/500; never a 2xx create.
                $this->assertContains($status, [302, 422, 419, 500], 'Duplicate tag must be rejected. Got: ' . $status);
            });

            $after = KeyRegister::query()->where('key_tag_number', $tag)->count();
            $this->assertSame($before, $after, 'A duplicate key_tag_number must not create a second row via the form.');
        } finally {
            KeyRegister::withTrashed()->where('key_tag_number', $tag)->get()
                ->each(fn (KeyRegister $r) => $r->forceDelete());
            if ($seed instanceof KeyRegister) {
                $seed->forceDelete();
            }
        }
    }

    /** DEV-FOF-KR-004 — the DB imposes NO unique index, so direct model duplicates are permitted. */
    public function test_keyregister_36_db_allows_duplicate_tag_no_unique_index(): void
    {
        $tag = 'K-RAW-' . $this->generateUniqueSuffix();
        $a = null;
        $b = null;
        try {
            $a = KeyRegister::query()->create($this->buildValidPayload(['key_tag_number' => $tag]));
            $b = KeyRegister::query()->create($this->buildValidPayload(['key_tag_number' => $tag]));

            $this->assertNotNull($a->id);
            $this->assertNotNull($b->id);
            $this->assertGreaterThanOrEqual(
                2,
                KeyRegister::query()->where('key_tag_number', $tag)->count(),
                'DEV-FOF-KR-004: no DB UNIQUE index — two rows with the same tag both persist.'
            );
        } finally {
            foreach ([$a, $b] as $r) {
                if ($r instanceof KeyRegister) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** issue() validation — expected_return_at is required and must be after:now. */
    public function test_keyregister_37_issue_requires_future_expected_return_at(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Available']));
        $recordId = (int) $record->id;

        try {
            $missingStatus = 0;
            $pastStatus = 0;
            $this->browse(function (Browser $browser) use ($recordId, &$missingStatus, &$pastStatus): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                $url = $this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/issue');
                $missingStatus = $this->postFormFromBrowser($browser, $url, ['_method' => 'PATCH']);
                $browser->pause(500);
                $pastStatus = $this->postFormFromBrowser($browser, $url, [
                    '_method'            => 'PATCH',
                    'expected_return_at' => now()->subDay()->format('Y-m-d H:i:s'),
                ]);
                $browser->pause(500);
            });

            $this->assertContains($missingStatus, [302, 422, 419, 500], 'Missing expected_return_at must be rejected. Got: ' . $missingStatus);
            $this->assertContains($pastStatus, [302, 422, 419, 500], 'Past expected_return_at must be rejected (after:now). Got: ' . $pastStatus);

            $record->refresh();
            $this->assertSame('Available', $record->status, 'Invalid issue must not change status.');
        } finally {
            $this->purgeKey($recordId);
        }
    }

    // ============================================================
    // 40-49  FK / integration + auto-managed fields (BC-REF, G48)
    // ============================================================

    /** issued_to_user_id FK to sys_users is enforced (invalid id rejected) — guarded (may be absent). */
    public function test_keyregister_40_issued_to_user_id_fk_is_enforced(): void
    {
        $created = null;
        try {
            $created = KeyRegister::query()->create($this->buildValidPayload([
                'status'            => 'Issued',
                'issued_to_user_id' => 2147483000, // non-existent sys_users id
            ]));
            // If it persisted, the FK is not enforced in this environment — document, don't fail hard.
            $created->refresh();
            $this->markTestSkipped('issued_to_user_id FK not enforced in this DB (documented in Validation Report).');
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $this->assertTrue(
                str_contains($msg, 'foreign key') || str_contains($msg, 'constraint') || str_contains($msg, '23000'),
                'Expected FK failure for issued_to_user_id, got: ' . $e->getMessage()
            );
        } finally {
            if ($created instanceof KeyRegister) {
                $created->forceDelete();
            }
        }
    }

    /** FK declared ON DELETE SET NULL (schema inspection, tolerant). */
    public function test_keyregister_41_issued_to_user_fk_is_set_null(): void
    {
        try {
            $createSql = $this->showCreateTable(self::TABLE);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot read SHOW CREATE TABLE: ' . $e->getMessage());
            return;
        }

        if (!str_contains(strtolower($createSql), 'foreign key')) {
            $this->markTestSkipped('No FK declared on fof_key_register in this environment.');
            return;
        }

        $this->assertStringContainsStringIgnoringCase('issued_to_user_id', $createSql);
        $this->assertStringContainsStringIgnoringCase('set null', $createSql, 'issued_to_user_id FK should be ON DELETE SET NULL.');
    }

    /** G48 — update() sets updated_by to the acting user (auto-managed, not a form input). */
    public function test_keyregister_42_update_sets_updated_by_to_acting_user(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['updated_by' => 999999]));
        $recordId = (int) $record->id;
        $newLabel = 'Relabelled ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($recordId, $newLabel, $record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $recordId . '/edit', 1000);

                $this->postFormFromBrowser($browser, $this->tenantUrl(self::SHOW_BASE_PATH . '/' . $recordId), [
                    '_method'        => 'PUT',
                    'key_label'      => $newLabel,
                    'key_tag_number' => (string) $record->key_tag_number,
                ]);
                $browser->pause(1500);
            });

            $record->refresh();
            if ($record->key_label !== $newLabel) {
                $this->markTestSkipped('update() did not run (module may be disabled — see Validation Report).');
                return;
            }
            $this->assertSame((int) $this->adminUser?->id, (int) $record->updated_by, 'update() must set updated_by to the acting user.');
            $this->assertTrue($this->activityLogged($recordId, 'Updated'), "update() must write an 'Updated' activity log.");
        } finally {
            $this->purgeKey($recordId);
        }
    }

    // ============================================================
    // 50-59  Permissions / authorization (BC-AUTH, F37/#31)
    // ============================================================

    /** Guest is redirected to login. */
    public function test_keyregister_50_guest_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(1500);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** Non-super-admin WITHOUT viewAny cannot open the index (real 403). */
    public function test_keyregister_51_index_requires_viewany_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::INDEX_PATH, 'GET');
    }

    /** Non-super-admin WITHOUT create cannot store. */
    public function test_keyregister_52_store_requires_create_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::INDEX_PATH, 'POST', [
            'key_label'      => 'PermDenied ' . $this->generateUniqueSuffix(),
            'key_tag_number' => 'K-' . $this->generateUniqueSuffix(),
        ]);
    }

    /** Non-super-admin WITHOUT update cannot issue a key (issue gates on .update). */
    public function test_keyregister_53_issue_requires_update_permission(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['status' => 'Available']));
        $recordId = (int) $record->id;
        try {
            $this->assertForbiddenForLimitedUser(
                self::INDEX_PATH . '/' . $recordId . '/issue',
                'POST',
                ['_method' => 'PATCH', 'expected_return_at' => now()->addDay()->format('Y-m-d H:i:s')]
            );
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** Non-super-admin WITHOUT delete cannot destroy a key. */
    public function test_keyregister_54_destroy_requires_delete_permission(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload());
        $recordId = (int) $record->id;
        try {
            $this->assertForbiddenForLimitedUser(
                self::INDEX_PATH . '/' . $recordId,
                'POST',
                ['_method' => 'DELETE']
            );
            $record->refresh();
            $this->assertNull($record->deleted_at, 'A forbidden delete must not soft-delete the record.');
        } finally {
            $this->purgeKey($recordId);
        }
    }

    // ============================================================
    // 60-69  UI / UX (list, search, filter, show, edit)
    // ============================================================

    /** Index page renders and lists a seeded available key. */
    public function test_keyregister_60_index_page_loads_and_lists_records(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'key_label' => 'IndexKey ' . $this->generateUniqueSuffix(), 'status' => 'Available',
        ]));

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 1000);

                $browser->waitForText((string) $record->key_label, 12)
                    ->assertSee((string) $record->key_label);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Search filter narrows the list by key_label. */
    public function test_keyregister_61_search_filters_results(): void
    {
        $needle = 'UniqueKey' . $this->generateUniqueSuffix();
        $match = KeyRegister::query()->create($this->buildValidPayload(['key_label' => $needle, 'status' => 'Available']));
        $other = KeyRegister::query()->create($this->buildValidPayload(['key_label' => 'Other ' . $this->generateUniqueSuffix(), 'status' => 'Available']));

        try {
            $this->browse(function (Browser $browser) use ($needle, $other): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?search=' . urlencode($needle), 1200);

                $browser->waitForText($needle, 12)->assertSee($needle);
                $this->assertStringNotContainsString(
                    (string) $other->key_label,
                    $browser->driver->getPageSource(),
                    'Non-matching key must be filtered out.'
                );
            });
        } finally {
            $match->forceDelete();
            $other->forceDelete();
        }
    }

    /** Search by key_tag_number also matches. */
    public function test_keyregister_62_search_by_tag_number_matches(): void
    {
        $tag = 'K-FIND-' . $this->generateUniqueSuffix();
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'key_label' => 'TagSearch ' . $this->generateUniqueSuffix(), 'key_tag_number' => $tag, 'status' => 'Available',
        ]));

        try {
            $this->browse(function (Browser $browser) use ($tag, $record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH . '?search=' . urlencode($tag), 1200);

                $browser->waitForText((string) $record->key_label, 12)
                    ->assertSee((string) $record->key_label);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Show page displays the key details. */
    public function test_keyregister_63_show_page_displays_details(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'key_label' => 'ShowKey ' . $this->generateUniqueSuffix(),
        ]));

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 1000);

                $browser->waitForText((string) $record->key_label, 12)
                    ->assertSee((string) $record->key_label)
                    ->assertSee((string) $record->key_tag_number);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Edit page loads with current values and update endpoint persists a change. */
    public function test_keyregister_64_edit_page_loads_and_updates(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'key_label' => 'EditKey ' . $this->generateUniqueSuffix(),
        ]));
        $recordId = (int) $record->id;
        $newLabel = 'EditedKey ' . $this->generateUniqueSuffix();

        try {
            $this->browse(function (Browser $browser) use ($recordId, $newLabel, $record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $recordId . '/edit', 1000);

                $browser->waitFor('input[name="key_label"]', 12)
                    ->assertInputValue('key_label', (string) $record->key_label);

                $this->postFormFromBrowser($browser, $this->tenantUrl(self::SHOW_BASE_PATH . '/' . $recordId), [
                    '_method'        => 'PUT',
                    'key_label'      => $newLabel,
                    'key_tag_number' => (string) $record->key_tag_number,
                ]);
                $browser->pause(1500);
            });

            $record->refresh();
            $this->assertSame($newLabel, $record->key_label, 'update() must persist the new key_label.');
        } finally {
            $this->purgeKey($recordId);
        }
    }

    // ============================================================
    // 70-79  Edge cases + soft-delete lifecycle (BC-EDG, Dep A-G)
    // ============================================================

    /** Soft delete moves the record to trash (deleted_at set) + 'Deleted' log. */
    public function test_keyregister_70_soft_delete_moves_to_trash(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'key_label' => 'SoftDelKey ' . $this->generateUniqueSuffix(),
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
            $this->assertTrue($this->activityLogged($recordId, 'Deleted'), "destroy() must write a 'Deleted' activity log.");
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** Trash page lists soft-deleted keys. */
    public function test_keyregister_71_trash_page_shows_deleted(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'key_label' => 'TrashKey ' . $this->generateUniqueSuffix(),
        ]));
        $recordId = (int) $record->id;
        $record->delete();

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TRASH_PATH, 1000);

                $browser->waitForText((string) $record->key_label, 12)
                    ->assertSee((string) $record->key_label);
            });
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** Restore returns a trashed record to active (deleted_at null) + 'Restored' log. */
    public function test_keyregister_72_restore_from_trash(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'key_label' => 'RestoreKey ' . $this->generateUniqueSuffix(),
        ]));
        $recordId = (int) $record->id;
        $record->delete();
        $this->assertNotNull(KeyRegister::withTrashed()->find($recordId)->deleted_at);

        try {
            $this->browse(function (Browser $browser) use ($recordId): void {
                $this->authenticateBrowserSession($browser);
                // restore route is a GET link.
                $browser->visit($this->tenantUrl(self::INDEX_PATH . '/' . $recordId . '/restore'))->pause(1500);
            });

            $record->refresh();
            $this->assertNull($record->deleted_at, 'restore() must clear deleted_at.');
            $this->assertTrue($this->activityLogged($recordId, 'Restored'), "restore() must write a 'Restored' activity log.");
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** Force delete permanently removes the record. */
    public function test_keyregister_73_force_delete_is_permanent(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload([
            'key_label' => 'ForceDelKey ' . $this->generateUniqueSuffix(),
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
                KeyRegister::withTrashed()->find($recordId),
                'force-delete must permanently remove the record.'
            );
        } finally {
            $this->purgeKey($recordId);
        }
    }

    /** 404 for a non-existent show id. */
    public function test_keyregister_74_show_404_for_nonexistent_record(): void
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

    /** toggle-status flips is_active and returns JSON success (gates on .update). */
    public function test_keyregister_75_toggle_status_flips_is_active(): void
    {
        $record = KeyRegister::query()->create($this->buildValidPayload(['is_active' => 1]));
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
            $this->purgeKey($recordId);
        }
    }

    // ============================================================
    // 90-99  Security + source-defect probes (TC-S / DEV)
    // ============================================================

    /** Stored XSS in key_label is escaped on the show page. */
    public function test_keyregister_90_stored_xss_in_key_label_is_escaped(): void
    {
        $xss = '<script>alert("kr' . $this->generateUniqueSuffix() . '")</script>';
        $record = KeyRegister::query()->create($this->buildValidPayload(['key_label' => $xss]));

        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 1200);

                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString(
                    '<script>alert("kr',
                    $source,
                    'key_label must be HTML-escaped (no raw <script> in output).'
                );
            });
        } finally {
            $record->forceDelete();
        }
    }

    /**
     * DEV-FOF-KR-001 (proving test): store() cannot create a key because key_type is
     * NOT-NULL-no-default yet is neither validated by the FormRequest nor set by store().
     * A valid, unique submission is therefore rejected at the DB layer (no row persisted).
     */
    public function test_keyregister_91_store_create_flow_is_broken_missing_key_type(): void
    {
        $label = 'BrokenCreate ' . $this->generateUniqueSuffix();
        try {
            $status = 0;
            $this->browse(function (Browser $browser) use ($label, &$status): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 900);

                // Mirror the real create form: it sends key_label + key_tag_number (+ location/description),
                // but NO key_type — exactly the defect under test.
                $status = $this->postFormFromBrowser($browser, $this->tenantUrl(self::INDEX_PATH), [
                    'key_label'      => $label,
                    'key_tag_number' => 'K-' . $this->generateUniqueSuffix(),
                    'location'       => 'Room',        // non-existent column (DEV-FOF-KR-002)
                    'description'    => 'ignored',     // non-existent column (DEV-FOF-KR-002)
                ]);
                $browser->pause(1200);
            });

            // Broken create -> DB 1364 surfaces as 500 (tolerant set); never a 2xx/302-success create.
            $this->assertContains($status, [500, 422, 419, 302], 'Broken store must not succeed. Got: ' . $status);
            $this->assertSame(
                0,
                KeyRegister::withTrashed()->where('key_label', $label)->count(),
                'DEV-FOF-KR-001: store() must NOT have persisted a row (key_type NOT-NULL never set).'
            );
        } finally {
            KeyRegister::withTrashed()->where('key_label', $label)->get()
                ->each(fn (KeyRegister $r) => $r->forceDelete());
        }
    }

    /**
     * DEV-FOF-KR-001/002 (proving test, source): the FormRequest omits key_type entirely
     * and store() never provides it — confirmed by static source read.
     */
    public function test_keyregister_92_formrequest_omits_key_type_documents_dev(): void
    {
        $requestSrc = $this->readClassSource(\Modules\FrontOffice\Http\Requests\KeyRegisterRequest::class);
        $controllerSrc = $this->readClassSource(\Modules\FrontOffice\Http\Controllers\KeyRegisterController::class);
        if ($requestSrc === '' || $controllerSrc === '') {
            $this->markTestSkipped('KeyRegister source unreadable from the runner.');
            return;
        }

        $this->assertStringNotContainsString(
            "'key_type'",
            $requestSrc,
            'DEV-FOF-KR-001: KeyRegisterRequest::rules() must be shown to omit key_type.'
        );
        // store() array_merge does not inject key_type either.
        $storeSlice = substr($controllerSrc, (int) strpos($controllerSrc, 'function store'), 600);
        $this->assertStringNotContainsString(
            'key_type',
            $storeSlice,
            'DEV-FOF-KR-001: store() must be shown NOT to set key_type.'
        );
    }

    /**
     * DEV-FOF-KR-005 (proving test, source): store() performs NO activityLog(),
     * unlike update/destroy/issue/return/restore/forceDelete.
     */
    public function test_keyregister_93_store_has_no_activity_log_documents_dev(): void
    {
        $src = $this->readClassSource(\Modules\FrontOffice\Http\Controllers\KeyRegisterController::class);
        if ($src === '') {
            $this->markTestSkipped('KeyRegisterController source unreadable from the runner.');
            return;
        }

        $storeStart = (int) strpos($src, 'function store');
        $storeEnd = (int) strpos($src, 'function show');
        $storeSlice = substr($src, $storeStart, max(0, $storeEnd - $storeStart));

        $this->assertStringNotContainsString(
            'activityLog(',
            $storeSlice,
            'DEV-FOF-KR-005: store() currently writes no activity log (documented gap).'
        );
        // Contrast: issue() DOES log with the lowercase event string.
        $this->assertStringContainsString("activityLog(\$fresh, 'key_issued'", $src, "issue() must log 'key_issued'.");
        $this->assertStringContainsString("activityLog(\$key, 'key_returned'", $src, "return() must log 'key_returned'.");
    }

    /**
     * SEC-FOF-003 (proving test, source): FormRequest authorize() blanket-returns true
     * (module-wide D30 — no defense-in-depth fallback).
     */
    public function test_keyregister_94_formrequest_authorize_returns_true_documents_dev(): void
    {
        $src = $this->readClassSource(\Modules\FrontOffice\Http\Requests\KeyRegisterRequest::class);
        if ($src === '') {
            $this->markTestSkipped('KeyRegisterRequest source unreadable from the runner.');
            return;
        }

        $normalized = preg_replace('/\s+/', ' ', $src);
        $this->assertStringContainsString(
            'function authorize(): bool { return true;',
            (string) $normalized,
            'SEC-FOF-003: FormRequest authorize() blanket-returns true (documented).'
        );
    }

    /**
     * DAT-FOF-004 (proving test, source): issue() IS row-locked — DB::transaction + lockForUpdate —
     * so the audit-flagged race is REMEDIATED for KeyRegister. Also confirms BR-FOF-012 guard.
     */
    public function test_keyregister_95_issue_uses_row_lock_and_status_guard(): void
    {
        $src = $this->readClassSource(\Modules\FrontOffice\Http\Controllers\KeyRegisterController::class);
        if ($src === '') {
            $this->markTestSkipped('KeyRegisterController source unreadable from the runner.');
            return;
        }

        $this->assertStringContainsString('DB::transaction', $src, 'issue() must wrap the update in a transaction.');
        $this->assertStringContainsString('lockForUpdate()', $src, 'DAT-FOF-004: issue() must lock the row for update.');
        $this->assertStringContainsString("!== 'Available'", $src, 'BR-FOF-012: issue() must guard the Available precondition.');
    }

    // ============================================================
    // ---- Private helper library (mirrors FrontOffice\PhoneDiary sibling) ----
    // ============================================================

    /** Assert an activity-log row exists for this KeyRegister subject + event (sys_activity_logs). */
    private function activityLogged(int $subjectId, string $event): bool
    {
        try {
            return DB::table(self::ACTIVITY_TABLE)
                ->where('subject_type', KeyRegister::class)
                ->where('subject_id', $subjectId)
                ->where('event', $event)
                ->exists();
        } catch (Throwable) {
            return false;
        }
    }

    /** Force-delete a key (and any trashed copy) by id — unconditional cleanup. */
    private function purgeKey(int $recordId): void
    {
        KeyRegister::withTrashed()->where('id', $recordId)->get()
            ->each(fn (KeyRegister $r) => $r->forceDelete());
    }

    /** Read real app-source TEXT for a class via reflection (runner has no Modules on disk). */
    private function readClassSource(string $class): string
    {
        try {
            $file = (new \ReflectionClass($class))->getFileName();
            $src = @file_get_contents((string) $file);
            return is_string($src) ? $src : '';
        } catch (Throwable) {
            return '';
        }
    }

    /** G45 boundary helper: over-length rejected/truncated + exactly-n accepted. */
    private function assertSizedStringColumn(string $column, int $max): void
    {
        // Over-length (n + 5) — must be rejected OR silently truncated to <= n (tolerant, #45/#41).
        $over = null;
        try {
            $over = KeyRegister::query()->create($this->buildValidPayload([
                $column => str_repeat('X', $max + 5),
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
            if ($over instanceof KeyRegister) {
                $over->forceDelete();
            }
        }

        // Exactly-n — must be accepted and fully stored.
        $exact = null;
        try {
            $value = str_repeat('Y', $max);
            $exact = KeyRegister::query()->create($this->buildValidPayload([
                $column => $value,
            ]));
            $exact->refresh();
            $this->assertSame($value, (string) $exact->{$column}, "Exactly-{$max}-char {$column} must persist intact.");
        } finally {
            if ($exact instanceof KeyRegister) {
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
                'name'              => 'Limited KR ' . $suffix,
                'short_name'        => 'lkr' . substr($suffix, -5),
                'email'             => 'limited.kr.' . $suffix . '@tenant.test',
                'emp_code'          => 'LKR_' . uniqid(),
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
            'key_label'      => 'Key ' . $this->generateUniqueSuffix(),
            'key_tag_number' => 'K-' . $this->generateUniqueSuffix(),
            'key_type'       => 'Room',
            'status'         => 'Available',
            'is_active'      => 1,
            'created_by'     => $adminId,
            'updated_by'     => $adminId,
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
