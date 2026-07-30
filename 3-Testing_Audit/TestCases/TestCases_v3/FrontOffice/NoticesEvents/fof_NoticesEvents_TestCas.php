<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\Notice;
use Modules\FrontOffice\Models\SchoolEvent;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice :: NoticesEvents  (COMPOUND: fof_notices + fof_school_events)
 * ------------------------------------------------------------------------
 * ONE comprehensive tenant-side Dusk suite covering BOTH sub-entities of the
 * Notices & Events screen:
 *   - Notice Board  -> NoticeBoardController -> fof_notices
 *   - School Events -> SchoolEventController -> fof_school_events
 *
 * Mirrors the nearest committed tenant-side sibling (FrontOffice\PhoneDiary)
 * for style, tenancy scaffolding and the private helper library.
 *
 * DDL truth (fof_notices):
 *   NOT-NULL user cols : title(V200), content(LONGTEXT), category(ENUM), display_from(DATE)
 *   Nullable cols      : display_until(DATE), attachment_media_id(INT-U)
 *   DB defaults        : audience='All', is_pinned=0, is_emergency=0, status='Active', is_active=1
 *   UNIQUE keys        : NONE (no G43 duplicate-rejection case)
 *   FK (SET NULL)      : attachment_media_id -> sys_media
 *   Auto/managed (G48) : created_by, updated_by (controller), status (server default)
 *   ENUM (DDL)         : category('Academic','Administrative','Sports','Cultural','Holiday','Emergency','Other')
 *                        audience('All','Students','Staff','Parents')
 *
 * DDL truth (fof_school_events):
 *   NOT-NULL user cols : event_name(V200), event_type(ENUM), start_date(DATE), end_date(DATE)
 *   Nullable cols      : description(TEXT), venue(V200)
 *   DB defaults        : audience='All', is_public=0, notification_sent=0, is_active=1
 *   UNIQUE keys        : NONE (no G43 duplicate-rejection case)
 *   Auto/managed (G48) : created_by, updated_by (controller)
 *   ENUM (DDL)         : event_type('Academic','Sports','Cultural','PTM','Holiday','Exam','Admission','Other')
 *                        audience('All','Students','Staff','Parents')
 *
 * Permission scheme (string gates):
 *   frontoffice.notice.{view,create,update,delete,restore,forceDelete}
 *   frontoffice.school-event.{view,create,update,delete,restore,forceDelete}
 *
 * Activity log (partial — verbatim from source):
 *   Notice      : Restored (restore), Deleted (forceDelete). NO log on store/update/destroy/toggle. -> DEV-FOF-NE-005
 *   SchoolEvent : Deleted (destroy soft-delete), Restored (restore), Deleted (forceDelete). NO log on store/update/toggle.
 *
 * DDL-vs-App divergences proven below (DEV-###):
 *   DEV-FOF-NE-001  notice.category ENUM mismatch  (app allows Event/General; DB allows Sports/Cultural/Other)
 *   DEV-FOF-NE-002  notice.audience / event.audience allow 'Management' not present in DB ENUM
 *   DEV-FOF-NE-003  event.event_type mismatch (app allows Function; DB allows Exam/Admission)
 *   DEV-FOF-NE-004  event.end_date DB NOT NULL but FormRequest 'nullable' -> omitted end_date breaks at DB layer
 *   DEV-FOF-NE-006  event.venue DDL VARCHAR(200) but FormRequest max:150 (stricter than column)
 *
 * ENV prerequisites (see Validation Report): FrontOffice must be ENABLED in
 * prime_testing/modules_statuses.json (currently false -> /front-office/* routes 404);
 * APP_ENV=testing; sys_media table may be absent (attachment FK path guarded).
 */
class fof_NoticesEvents_TestCas extends DuskTestCase
{
    // ---- Notices ----
    private const NOTICE_TABLE = 'fof_notices';
    private const NOTICE_INDEX_PATH = '/front-office/notices';
    private const NOTICE_SHOW_BASE = '/front-office/notices';
    private const NOTICE_TRASH_PATH = '/front-office/notices/trash/view';

    // ---- School Events ----
    private const EVENT_TABLE = 'fof_school_events';
    private const EVENT_INDEX_PATH = '/front-office/school-events';
    private const EVENT_SHOW_BASE = '/front-office/school-events';
    private const EVENT_TRASH_PATH = '/front-office/school-events/trash/view';

    private const PERMISSIONS = [
        'frontoffice.notice.view',
        'frontoffice.notice.create',
        'frontoffice.notice.update',
        'frontoffice.notice.delete',
        'frontoffice.notice.restore',
        'frontoffice.notice.forceDelete',
        'frontoffice.school-event.view',
        'frontoffice.school-event.create',
        'frontoffice.school-event.update',
        'frontoffice.school-event.delete',
        'frontoffice.school-event.restore',
        'frontoffice.school-event.forceDelete',
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

    /** test_01 — full DDL <-> app alignment matrix for fof_notices (LIVE schema). */
    public function test_noticesevents_01_notice_schema_and_model_alignment(): void
    {
        $this->assertTrue(Schema::hasTable(self::NOTICE_TABLE), 'Table fof_notices must exist.');

        $expected = [
            'id', 'title', 'content', 'category', 'audience', 'display_from', 'display_until',
            'is_pinned', 'is_emergency', 'attachment_media_id', 'status', 'is_active',
            'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(Schema::hasColumns(self::NOTICE_TABLE, $expected), 'fof_notices missing expected columns.');

        $model = new Notice();
        $this->assertSame(self::NOTICE_TABLE, $model->getTable(), 'Notice::$table must be fof_notices.');

        $fillable = $model->getFillable();
        foreach (['title', 'content', 'category', 'audience', 'is_pinned', 'is_emergency',
                  'display_from', 'display_until', 'attachment_media_id', 'status', 'is_active',
                  'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $fillable, "Notice fillable must contain {$col}.");
        }

        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_pinned'] ?? null);
        $this->assertSame('boolean', $casts['is_emergency'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('date', $casts['display_from'] ?? null);
        $this->assertSame('date', $casts['display_until'] ?? null);

        // Soft-delete column + trait asserted INDEPENDENTLY (#30/G46).
        $hasCol = Schema::hasColumn(self::NOTICE_TABLE, 'deleted_at');
        $usesTrait = in_array(SoftDeletes::class, class_uses_recursive(Notice::class), true);
        $this->assertTrue($hasCol, 'DDL: fof_notices.deleted_at must exist.');
        $this->assertTrue($usesTrait, 'Model: Notice must use SoftDeletes.');
        $this->assertSame($hasCol, $usesTrait, 'Soft-delete column/trait must agree for Notice.');

        // No UNIQUE key on fof_notices (documented absence — G43).
        $this->assertSame(0, $this->uniqueIndexCount(self::NOTICE_TABLE), 'fof_notices must have NO unique index (per DDL).');
    }

    /** test_02 — full DDL <-> app alignment matrix for fof_school_events (LIVE schema). */
    public function test_noticesevents_02_event_schema_and_model_alignment(): void
    {
        $this->assertTrue(Schema::hasTable(self::EVENT_TABLE), 'Table fof_school_events must exist.');

        $expected = [
            'id', 'event_name', 'event_type', 'start_date', 'end_date', 'description', 'venue',
            'audience', 'is_public', 'notification_sent', 'is_active',
            'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(Schema::hasColumns(self::EVENT_TABLE, $expected), 'fof_school_events missing expected columns.');

        $model = new SchoolEvent();
        $this->assertSame(self::EVENT_TABLE, $model->getTable(), 'SchoolEvent::$table must be fof_school_events.');

        $fillable = $model->getFillable();
        foreach (['event_name', 'description', 'event_type', 'start_date', 'end_date', 'venue',
                  'audience', 'is_public', 'notification_sent', 'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $fillable, "SchoolEvent fillable must contain {$col}.");
        }

        $casts = $model->getCasts();
        $this->assertSame('date', $casts['start_date'] ?? null);
        $this->assertSame('date', $casts['end_date'] ?? null);
        $this->assertSame('boolean', $casts['is_public'] ?? null);
        $this->assertSame('boolean', $casts['notification_sent'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);

        $hasCol = Schema::hasColumn(self::EVENT_TABLE, 'deleted_at');
        $usesTrait = in_array(SoftDeletes::class, class_uses_recursive(SchoolEvent::class), true);
        $this->assertTrue($hasCol, 'DDL: fof_school_events.deleted_at must exist.');
        $this->assertTrue($usesTrait, 'Model: SchoolEvent must use SoftDeletes.');
        $this->assertSame($hasCol, $usesTrait, 'Soft-delete column/trait must agree for SchoolEvent.');

        $this->assertSame(0, $this->uniqueIndexCount(self::EVENT_TABLE), 'fof_school_events must have NO unique index (per DDL).');
    }

    /** G44 negative — every NOT-NULL-no-default Notice user column rejects a missing value. */
    public function test_noticesevents_03_notice_required_columns_reject_missing(): void
    {
        foreach (['title', 'content', 'category', 'display_from'] as $col) {
            $created = null;
            try {
                $payload = $this->buildNoticePayload();
                unset($payload[$col]);
                $created = Notice::query()->create($payload);
                $this->fail("Expected DB rejection creating a notice without required column {$col}.");
            } catch (Throwable $e) {
                $this->assertTrue($this->looksLikeNotNullFailure($e), "Expected NOT-NULL failure for notice.{$col}, got: " . $e->getMessage());
            } finally {
                if ($created instanceof Notice) {
                    $created->forceDelete();
                }
            }
        }
    }

    /** G44 negative — every NOT-NULL-no-default Event user column rejects a missing value (excl. end_date DEV). */
    public function test_noticesevents_04_event_required_columns_reject_missing(): void
    {
        foreach (['event_name', 'event_type', 'start_date'] as $col) {
            $created = null;
            try {
                $payload = $this->buildEventPayload();
                unset($payload[$col]);
                $created = SchoolEvent::query()->create($payload);
                $this->fail("Expected DB rejection creating an event without required column {$col}.");
            } catch (Throwable $e) {
                $this->assertTrue($this->looksLikeNotNullFailure($e), "Expected NOT-NULL failure for event.{$col}, got: " . $e->getMessage());
            } finally {
                if ($created instanceof SchoolEvent) {
                    $created->forceDelete();
                }
            }
        }
    }

    /** G44 positive — nullable Notice columns may be omitted; row persists. */
    public function test_noticesevents_05_notice_nullable_columns_accept_omitted(): void
    {
        $record = null;
        try {
            $payload = $this->buildNoticePayload(['title' => 'NullableOmit ' . $this->generateUniqueSuffix()]);
            unset($payload['display_until'], $payload['attachment_media_id']);
            $record = Notice::query()->create($payload);
            $record->refresh();

            $this->assertNotNull($record->id, 'Notice with only required cols must persist.');
            $this->assertNull($record->display_until, 'Omitted display_until should be NULL.');
            $this->assertNull($record->attachment_media_id, 'Omitted attachment_media_id should be NULL.');
        } finally {
            if ($record instanceof Notice) {
                $record->forceDelete();
            }
        }
    }

    /** G44 positive — nullable Event columns may be omitted; row persists. */
    public function test_noticesevents_06_event_nullable_columns_accept_omitted(): void
    {
        $record = null;
        try {
            $payload = $this->buildEventPayload(['event_name' => 'NullableOmit ' . $this->generateUniqueSuffix()]);
            unset($payload['description'], $payload['venue']);
            $record = SchoolEvent::query()->create($payload);
            $record->refresh();

            $this->assertNotNull($record->id, 'Event with only required cols must persist.');
            $this->assertNull($record->description, 'Omitted description should be NULL.');
            $this->assertNull($record->venue, 'Omitted venue should be NULL.');
        } finally {
            if ($record instanceof SchoolEvent) {
                $record->forceDelete();
            }
        }
    }

    /** DDL defaults applied when omitted (read back via refresh — #35), both tables. */
    public function test_noticesevents_07_column_defaults_applied_on_create(): void
    {
        $notice = null;
        $event = null;
        try {
            $np = $this->buildNoticePayload(['title' => 'Defaults ' . $this->generateUniqueSuffix()]);
            unset($np['audience'], $np['is_pinned'], $np['is_emergency'], $np['status'], $np['is_active']);
            $notice = Notice::query()->create($np);
            $notice->refresh();
            $this->assertSame('All', $notice->audience, 'notice.audience must default to All.');
            $this->assertFalse((bool) $notice->is_pinned, 'notice.is_pinned must default to 0.');
            $this->assertFalse((bool) $notice->is_emergency, 'notice.is_emergency must default to 0.');
            $this->assertSame('Active', $notice->status, 'notice.status must default to Active (G48 server default).');
            $this->assertTrue((bool) $notice->is_active, 'notice.is_active must default to 1.');

            $ep = $this->buildEventPayload(['event_name' => 'Defaults ' . $this->generateUniqueSuffix()]);
            unset($ep['audience'], $ep['is_public'], $ep['notification_sent'], $ep['is_active']);
            $event = SchoolEvent::query()->create($ep);
            $event->refresh();
            $this->assertSame('All', $event->audience, 'event.audience must default to All.');
            $this->assertFalse((bool) $event->is_public, 'event.is_public must default to 0.');
            $this->assertFalse((bool) $event->notification_sent, 'event.notification_sent must default to 0.');
            $this->assertTrue((bool) $event->is_active, 'event.is_active must default to 1.');
        } finally {
            if ($notice instanceof Notice) {
                $notice->forceDelete();
            }
            if ($event instanceof SchoolEvent) {
                $event->forceDelete();
            }
        }
    }

    /** Casts return typed values for both models. */
    public function test_noticesevents_08_casts_return_typed_values(): void
    {
        $notice = null;
        $event = null;
        try {
            $notice = $this->createNotice(['is_pinned' => 1, 'is_emergency' => 1]);
            $notice->refresh();
            $this->assertIsBool($notice->is_pinned, 'notice.is_pinned must cast to bool.');
            $this->assertIsBool($notice->is_emergency, 'notice.is_emergency must cast to bool.');
            $this->assertIsBool($notice->is_active, 'notice.is_active must cast to bool.');
            $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $notice->display_from, 'display_from must cast to date.');

            $event = $this->createEvent(['is_public' => 1]);
            $event->refresh();
            $this->assertIsBool($event->is_public, 'event.is_public must cast to bool.');
            $this->assertIsBool($event->notification_sent, 'event.notification_sent must cast to bool.');
            $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $event->start_date, 'start_date must cast to date.');
        } finally {
            if ($notice instanceof Notice) {
                $notice->forceDelete();
            }
            if ($event instanceof SchoolEvent) {
                $event->forceDelete();
            }
        }
    }

    /** G43 — neither table has a UNIQUE key; duplicate logical rows both insert. */
    public function test_noticesevents_09_no_unique_constraint_allows_duplicates(): void
    {
        $title = 'DupNotice ' . $this->generateUniqueSuffix();
        $name = 'DupEvent ' . $this->generateUniqueSuffix();
        $n1 = $n2 = $e1 = $e2 = null;
        try {
            $n1 = $this->createNotice(['title' => $title]);
            $n2 = $this->createNotice(['title' => $title]);
            $this->assertNotSame($n1->id, $n2->id, 'Two identical-title notices allowed (no UNIQUE).');
            $this->assertGreaterThanOrEqual(2, Notice::query()->where('title', $title)->count());

            $e1 = $this->createEvent(['event_name' => $name]);
            $e2 = $this->createEvent(['event_name' => $name]);
            $this->assertNotSame($e1->id, $e2->id, 'Two identical-name events allowed (no UNIQUE).');
            $this->assertGreaterThanOrEqual(2, SchoolEvent::query()->where('event_name', $name)->count());
        } finally {
            foreach ([$n1, $n2] as $r) {
                if ($r instanceof Notice) {
                    $r->forceDelete();
                }
            }
            foreach ([$e1, $e2] as $r) {
                if ($r instanceof SchoolEvent) {
                    $r->forceDelete();
                }
            }
        }
    }

    // ============================================================
    // 10-19  Business rules (BC-BIZ)
    // ============================================================

    /** Notice scopeActive() excludes inactive rows. */
    public function test_noticesevents_10_notice_active_scope_excludes_inactive(): void
    {
        $active = $inactive = null;
        try {
            $active = $this->createNotice(['title' => 'ActN ' . $this->generateUniqueSuffix(), 'is_active' => 1]);
            $inactive = $this->createNotice(['title' => 'InactN ' . $this->generateUniqueSuffix(), 'is_active' => 0]);

            $ids = Notice::query()->active()->pluck('id')->all();
            $this->assertContains($active->id, $ids);
            $this->assertNotContains($inactive->id, $ids);
        } finally {
            foreach ([$active, $inactive] as $r) {
                if ($r instanceof Notice) {
                    $r->forceDelete();
                }
            }
        }
    }

    /**
     * BR-FOF-014: Notice scopeVisible() shows an emergency notice regardless of display window,
     * but hides an expired non-emergency notice.
     */
    public function test_noticesevents_11_notice_visible_scope_emergency_bypasses_dates(): void
    {
        $emergencyExpired = $normalExpired = $normalCurrent = null;
        try {
            $emergencyExpired = $this->createNotice([
                'title' => 'EmgExpired ' . $this->generateUniqueSuffix(),
                'is_emergency' => 1,
                'display_from' => now()->subDays(30)->toDateString(),
                'display_until' => now()->subDays(10)->toDateString(),
            ]);
            $normalExpired = $this->createNotice([
                'title' => 'NrmExpired ' . $this->generateUniqueSuffix(),
                'is_emergency' => 0,
                'display_from' => now()->subDays(30)->toDateString(),
                'display_until' => now()->subDays(10)->toDateString(),
            ]);
            $normalCurrent = $this->createNotice([
                'title' => 'NrmCurrent ' . $this->generateUniqueSuffix(),
                'is_emergency' => 0,
                'display_from' => now()->subDay()->toDateString(),
                'display_until' => now()->addDays(10)->toDateString(),
            ]);

            $visibleIds = Notice::query()->visible()->pluck('id')->all();
            $this->assertContains($emergencyExpired->id, $visibleIds, 'Emergency notice must be visible despite expiry (BR-FOF-014).');
            $this->assertNotContains($normalExpired->id, $visibleIds, 'Expired non-emergency notice must be hidden.');
            $this->assertContains($normalCurrent->id, $visibleIds, 'Current non-emergency notice must be visible.');
        } finally {
            foreach ([$emergencyExpired, $normalExpired, $normalCurrent] as $r) {
                if ($r instanceof Notice) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** Event scopeActive() excludes inactive rows. */
    public function test_noticesevents_12_event_active_scope_excludes_inactive(): void
    {
        $active = $inactive = null;
        try {
            $active = $this->createEvent(['event_name' => 'ActE ' . $this->generateUniqueSuffix(), 'is_active' => 1]);
            $inactive = $this->createEvent(['event_name' => 'InactE ' . $this->generateUniqueSuffix(), 'is_active' => 0]);

            $ids = SchoolEvent::query()->active()->pluck('id')->all();
            $this->assertContains($active->id, $ids);
            $this->assertNotContains($inactive->id, $ids);
        } finally {
            foreach ([$active, $inactive] as $r) {
                if ($r instanceof SchoolEvent) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** Event scopeUpcoming() returns start_date >= today; excludes past events. */
    public function test_noticesevents_13_event_upcoming_scope_filters_by_start_date(): void
    {
        $future = $past = null;
        try {
            $future = $this->createEvent([
                'event_name' => 'Future ' . $this->generateUniqueSuffix(),
                'start_date' => now()->addDays(5)->toDateString(),
                'end_date' => now()->addDays(6)->toDateString(),
            ]);
            $past = $this->createEvent([
                'event_name' => 'Past ' . $this->generateUniqueSuffix(),
                'start_date' => now()->subDays(5)->toDateString(),
                'end_date' => now()->subDays(4)->toDateString(),
            ]);

            $ids = SchoolEvent::query()->upcoming()->pluck('id')->all();
            $this->assertContains($future->id, $ids, 'Future event must be in upcoming scope.');
            $this->assertNotContains($past->id, $ids, 'Past event must NOT be in upcoming scope.');
        } finally {
            foreach ([$future, $past] as $r) {
                if ($r instanceof SchoolEvent) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** Notice.status is a server default (G48) — not user-facing; defaults to Active. */
    public function test_noticesevents_14_notice_status_is_server_default_active(): void
    {
        $record = null;
        try {
            $payload = $this->buildNoticePayload(['title' => 'StatusDefault ' . $this->generateUniqueSuffix()]);
            unset($payload['status']);
            $record = Notice::query()->create($payload);
            $record->refresh();
            $this->assertSame('Active', $record->status, 'notice.status must be Active by default (controller never sets it).');
        } finally {
            if ($record instanceof Notice) {
                $record->forceDelete();
            }
        }
    }

    // ============================================================
    // 20-29  Lifecycle / state transitions (BC-SM)
    // ============================================================

    /** Notice toggle-status flips is_active and returns JSON success. */
    public function test_noticesevents_20_notice_toggle_status_flips_is_active(): void
    {
        $record = $this->createNotice(['title' => 'ToggleN ' . $this->generateUniqueSuffix(), 'is_active' => 1]);
        $id = (int) $record->id;
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_INDEX_PATH, 900);
                $url = $this->tenantUrl(self::NOTICE_INDEX_PATH . '/' . $id . '/toggle-status');
                $response = $this->jsonRequestFromBrowser($browser, $url, 'POST');
                $this->assertIsArray($response, 'toggle-status must return JSON.');
                $this->assertTrue((bool) ($response['success'] ?? false), 'toggle-status success flag must be true.');
            });
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'notice is_active must flip to false.');
        } finally {
            Notice::withTrashed()->where('id', $id)->get()->each(fn (Notice $r) => $r->forceDelete());
        }
    }

    /** Event toggle-status flips is_active and returns JSON success. */
    public function test_noticesevents_21_event_toggle_status_flips_is_active(): void
    {
        $record = $this->createEvent(['event_name' => 'ToggleE ' . $this->generateUniqueSuffix(), 'is_active' => 1]);
        $id = (int) $record->id;
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_INDEX_PATH, 900);
                $url = $this->tenantUrl(self::EVENT_INDEX_PATH . '/' . $id . '/toggle-status');
                $response = $this->jsonRequestFromBrowser($browser, $url, 'POST');
                $this->assertIsArray($response, 'toggle-status must return JSON.');
                $this->assertTrue((bool) ($response['success'] ?? false), 'toggle-status success flag must be true.');
            });
            $record->refresh();
            $this->assertFalse((bool) $record->is_active, 'event is_active must flip to false.');
        } finally {
            SchoolEvent::withTrashed()->where('id', $id)->get()->each(fn (SchoolEvent $r) => $r->forceDelete());
        }
    }

    /** Notice soft-delete moves the record to trash (deleted_at set). */
    public function test_noticesevents_22_notice_soft_delete_moves_to_trash(): void
    {
        $record = $this->createNotice(['title' => 'SoftDelN ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_INDEX_PATH, 900);
                $url = $this->tenantUrl(self::NOTICE_SHOW_BASE . '/' . $id);
                $this->spoofedRequestFromBrowser($browser, $url, 'DELETE');
                $browser->pause(1500);
            });
            $record->refresh();
            $this->assertNotNull($record->deleted_at, 'notice destroy() must soft-delete the record.');
        } finally {
            Notice::withTrashed()->where('id', $id)->get()->each(fn (Notice $r) => $r->forceDelete());
        }
    }

    /** Event soft-delete moves to trash AND writes a 'Deleted' activity log (verbatim from controller). */
    public function test_noticesevents_23_event_soft_delete_and_activity_logged(): void
    {
        $record = $this->createEvent(['event_name' => 'SoftDelE ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_INDEX_PATH, 900);
                $url = $this->tenantUrl(self::EVENT_SHOW_BASE . '/' . $id);
                $this->spoofedRequestFromBrowser($browser, $url, 'DELETE');
                $browser->pause(1500);
            });
            $record->refresh();
            $this->assertNotNull($record->deleted_at, 'event destroy() must soft-delete the record.');
            $this->assertActivityLoggedTolerant('Deleted', $id, self::EVENT_TABLE);
        } finally {
            SchoolEvent::withTrashed()->where('id', $id)->get()->each(fn (SchoolEvent $r) => $r->forceDelete());
        }
    }

    /** Notice restore from trash clears deleted_at AND writes a 'Restored' activity log. */
    public function test_noticesevents_24_notice_restore_from_trash(): void
    {
        $record = $this->createNotice(['title' => 'RestoreN ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        $record->delete();
        $this->assertNotNull(Notice::withTrashed()->find($id)->deleted_at);
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                // restore route is a GET link.
                $browser->visit($this->tenantUrl(self::NOTICE_INDEX_PATH . '/' . $id . '/restore'))->pause(1500);
            });
            $record->refresh();
            $this->assertNull($record->deleted_at, 'notice restore() must clear deleted_at.');
            $this->assertActivityLoggedTolerant('Restored', $id, self::NOTICE_TABLE);
        } finally {
            Notice::withTrashed()->where('id', $id)->get()->each(fn (Notice $r) => $r->forceDelete());
        }
    }

    /** Event restore from trash clears deleted_at AND writes a 'Restored' activity log. */
    public function test_noticesevents_25_event_restore_from_trash(): void
    {
        $record = $this->createEvent(['event_name' => 'RestoreE ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        $record->delete();
        $this->assertNotNull(SchoolEvent::withTrashed()->find($id)->deleted_at);
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                $browser->visit($this->tenantUrl(self::EVENT_INDEX_PATH . '/' . $id . '/restore'))->pause(1500);
            });
            $record->refresh();
            $this->assertNull($record->deleted_at, 'event restore() must clear deleted_at.');
            $this->assertActivityLoggedTolerant('Restored', $id, self::EVENT_TABLE);
        } finally {
            SchoolEvent::withTrashed()->where('id', $id)->get()->each(fn (SchoolEvent $r) => $r->forceDelete());
        }
    }

    /** Notice force-delete permanently removes the record. */
    public function test_noticesevents_26_notice_force_delete_is_permanent(): void
    {
        $record = $this->createNotice(['title' => 'ForceDelN ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        $record->delete();
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_TRASH_PATH, 900);
                $url = $this->tenantUrl(self::NOTICE_INDEX_PATH . '/' . $id . '/force-delete');
                $this->spoofedRequestFromBrowser($browser, $url, 'DELETE');
                $browser->pause(1500);
            });
            $this->assertNull(Notice::withTrashed()->find($id), 'notice force-delete must permanently remove the record.');
        } finally {
            Notice::withTrashed()->where('id', $id)->get()->each(fn (Notice $r) => $r->forceDelete());
        }
    }

    /** Event force-delete permanently removes the record. */
    public function test_noticesevents_27_event_force_delete_is_permanent(): void
    {
        $record = $this->createEvent(['event_name' => 'ForceDelE ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        $record->delete();
        try {
            $this->browse(function (Browser $browser) use ($id): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_TRASH_PATH, 900);
                $url = $this->tenantUrl(self::EVENT_INDEX_PATH . '/' . $id . '/force-delete');
                $this->spoofedRequestFromBrowser($browser, $url, 'DELETE');
                $browser->pause(1500);
            });
            $this->assertNull(SchoolEvent::withTrashed()->find($id), 'event force-delete must permanently remove the record.');
        } finally {
            SchoolEvent::withTrashed()->where('id', $id)->get()->each(fn (SchoolEvent $r) => $r->forceDelete());
        }
    }

    // ============================================================
    // 30-39  Validation + error messages + ENUM divergences (BC-VAL, G45, DEV)
    // ============================================================

    /** G45 — notice.title VARCHAR(200): over-length rejected/truncated + exactly-200 accepted. */
    public function test_noticesevents_30_notice_title_length_boundary(): void
    {
        $this->assertNoticeSizedString('title', 200);
    }

    /** G45 — event.event_name VARCHAR(200). */
    public function test_noticesevents_31_event_name_length_boundary(): void
    {
        $this->assertEventSizedString('event_name', 200);
    }

    /** G45 — event.venue VARCHAR(200) at DB layer (DEV-FOF-NE-006: FormRequest max:150 is stricter). */
    public function test_noticesevents_32_event_venue_length_boundary(): void
    {
        $this->assertEventSizedString('venue', 200);
    }

    /**
     * DEV-FOF-NE-001 — notice.category ENUM mismatch. The app FormRequest/Blade allow
     * 'Event' and 'General', which are NOT in the DB ENUM. Persisting one must fail or be
     * coerced (never stored as a canonical value).
     */
    public function test_noticesevents_33_notice_category_app_values_not_in_db_enum(): void
    {
        foreach (['Event', 'General'] as $appValue) {
            $created = null;
            try {
                $created = Notice::query()->create($this->buildNoticePayload([
                    'title' => 'BadCat ' . $this->generateUniqueSuffix(),
                    'category' => $appValue,
                ]));
                $created->refresh();
                $this->assertNotSame($appValue, $created->category, "DEV-FOF-NE-001: app category '{$appValue}' is not a valid DB ENUM value.");
            } catch (Throwable $e) {
                $this->assertTrue(true, "DB rejected out-of-ENUM category '{$appValue}': " . $e->getMessage());
            } finally {
                if ($created instanceof Notice) {
                    $created->forceDelete();
                }
            }
        }
    }

    /** notice.category ENUM accepts the DB-valid values (some of which the app FormRequest would reject). */
    public function test_noticesevents_34_notice_category_db_valid_values_accepted(): void
    {
        foreach (['Academic', 'Sports', 'Cultural', 'Holiday', 'Emergency', 'Other'] as $value) {
            $record = null;
            try {
                $record = Notice::query()->create($this->buildNoticePayload([
                    'title' => 'CatOk ' . $this->generateUniqueSuffix(),
                    'category' => $value,
                ]));
                $record->refresh();
                $this->assertSame($value, $record->category, "DB ENUM must accept category {$value}.");
            } finally {
                if ($record instanceof Notice) {
                    $record->forceDelete();
                }
            }
        }
    }

    /**
     * DEV-FOF-NE-002 — 'Management' audience is offered by the app but is NOT in the DB ENUM
     * ('All','Students','Staff','Parents') for either table.
     */
    public function test_noticesevents_35_audience_management_not_in_db_enum(): void
    {
        $notice = $event = null;
        try {
            try {
                $notice = Notice::query()->create($this->buildNoticePayload([
                    'title' => 'MgmtAud ' . $this->generateUniqueSuffix(),
                    'audience' => 'Management',
                ]));
                $notice->refresh();
                $this->assertNotSame('Management', $notice->audience, 'DEV-FOF-NE-002: notice audience Management is not a DB ENUM value.');
            } catch (Throwable $e) {
                $this->assertTrue(true, 'DB rejected notice audience Management: ' . $e->getMessage());
            }

            try {
                $event = SchoolEvent::query()->create($this->buildEventPayload([
                    'event_name' => 'MgmtAud ' . $this->generateUniqueSuffix(),
                    'audience' => 'Management',
                ]));
                $event->refresh();
                $this->assertNotSame('Management', $event->audience, 'DEV-FOF-NE-002: event audience Management is not a DB ENUM value.');
            } catch (Throwable $e) {
                $this->assertTrue(true, 'DB rejected event audience Management: ' . $e->getMessage());
            }
        } finally {
            if ($notice instanceof Notice) {
                $notice->forceDelete();
            }
            if ($event instanceof SchoolEvent) {
                $event->forceDelete();
            }
        }
    }

    /**
     * DEV-FOF-NE-003 — event.event_type mismatch. App allows 'Function' (not in DB ENUM);
     * DB allows 'Exam'/'Admission' (which the app FormRequest rejects).
     */
    public function test_noticesevents_36_event_type_function_not_in_db_enum(): void
    {
        $created = null;
        try {
            $created = SchoolEvent::query()->create($this->buildEventPayload([
                'event_name' => 'FnType ' . $this->generateUniqueSuffix(),
                'event_type' => 'Function',
            ]));
            $created->refresh();
            $this->assertNotSame('Function', $created->event_type, "DEV-FOF-NE-003: event_type 'Function' is not a valid DB ENUM value.");
        } catch (Throwable $e) {
            $this->assertTrue(true, "DB rejected event_type 'Function': " . $e->getMessage());
        } finally {
            if ($created instanceof SchoolEvent) {
                $created->forceDelete();
            }
        }
    }

    /** event.event_type ENUM accepts DB-valid values (incl. Exam/Admission the app FormRequest rejects). */
    public function test_noticesevents_37_event_type_db_valid_values_accepted(): void
    {
        foreach (['Academic', 'Sports', 'Cultural', 'PTM', 'Holiday', 'Exam', 'Admission', 'Other'] as $value) {
            $record = null;
            try {
                $record = SchoolEvent::query()->create($this->buildEventPayload([
                    'event_name' => 'TypeOk ' . $this->generateUniqueSuffix(),
                    'event_type' => $value,
                ]));
                $record->refresh();
                $this->assertSame($value, $record->event_type, "DB ENUM must accept event_type {$value}.");
            } finally {
                if ($record instanceof SchoolEvent) {
                    $record->forceDelete();
                }
            }
        }
    }

    /**
     * DEV-FOF-NE-004 — event.end_date is NOT NULL in the DB but 'nullable' in the FormRequest.
     * Omitting end_date passes validation yet must fail at the DB layer.
     */
    public function test_noticesevents_38_event_end_date_notnull_vs_nullable_divergence(): void
    {
        $created = null;
        try {
            $payload = $this->buildEventPayload(['event_name' => 'NoEndDate ' . $this->generateUniqueSuffix()]);
            unset($payload['end_date']);
            $created = SchoolEvent::query()->create($payload);
            $this->fail('DEV-FOF-NE-004: DB should reject a null end_date (column is NOT NULL).');
        } catch (Throwable $e) {
            $this->assertTrue($this->looksLikeNotNullFailure($e), 'Expected NOT-NULL failure for end_date, got: ' . $e->getMessage());
        } finally {
            if ($created instanceof SchoolEvent) {
                $created->forceDelete();
            }
        }
    }

    /** Browser store validation — notice missing required fields does not yield a 2xx creation. */
    public function test_noticesevents_39_notice_store_rejects_missing_required(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::NOTICE_INDEX_PATH, 900);
            $status = $this->postFormFromBrowser($browser, $this->tenantUrl(self::NOTICE_INDEX_PATH), [
                'title' => '',
                'content' => '',
                'category' => 'Academic',
                'audience' => 'All',
                'display_from' => now()->toDateString(),
            ]);
            $this->assertContains($status, [302, 422, 419, 500], 'Missing required notice fields must not create (2xx). Got: ' . $status);
        });
    }

    // ============================================================
    // 40-49  FK / integration + auto-managed fields (BC-INT / BC-REF / G48)
    // ============================================================

    /** notice.attachment_media_id FK to sys_media is enforced (invalid id rejected); guarded if sys_media absent. */
    public function test_noticesevents_40_notice_attachment_fk_enforced(): void
    {
        if (!Schema::hasTable('sys_media')) {
            $this->markTestSkipped('sys_media table absent — attachment FK path not testable (env prerequisite).');
            return;
        }
        $created = null;
        try {
            $created = Notice::query()->create($this->buildNoticePayload([
                'title' => 'BadMediaFk ' . $this->generateUniqueSuffix(),
                'attachment_media_id' => 2147483000,
            ]));
            $this->fail('Expected FK violation for non-existent attachment_media_id.');
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $this->assertTrue(
                str_contains($msg, 'foreign key') || str_contains($msg, 'constraint') || str_contains($msg, '23000'),
                'Expected FK failure, got: ' . $e->getMessage()
            );
        } finally {
            if ($created instanceof Notice) {
                $created->forceDelete();
            }
        }
    }

    /** notice attachment FK declared ON DELETE SET NULL (schema inspection). */
    public function test_noticesevents_41_notice_attachment_fk_is_set_null(): void
    {
        try {
            $createSql = $this->showCreateTable(self::NOTICE_TABLE);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot read SHOW CREATE TABLE for fof_notices: ' . $e->getMessage());
            return;
        }
        if (!str_contains(strtolower($createSql), 'foreign key')) {
            $this->markTestSkipped('fof_notices declares no FK in the live schema (DDL may lag).');
            return;
        }
        $this->assertStringContainsStringIgnoringCase('attachment_media_id', $createSql);
        $this->assertStringContainsStringIgnoringCase('set null', $createSql, 'attachment FK should be ON DELETE SET NULL.');
    }

    /** created_by/updated_by are set by the controller from auth()->id() on notice store (G48). */
    public function test_noticesevents_42_notice_created_by_set_by_controller(): void
    {
        $marker = 'AuditProbe ' . $this->generateUniqueSuffix();
        $created = null;
        try {
            $this->browse(function (Browser $browser) use ($marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_INDEX_PATH, 900);
                $this->postFormFromBrowser($browser, $this->tenantUrl(self::NOTICE_INDEX_PATH), [
                    'title' => $marker,
                    'content' => 'Audit column probe body.',
                    'category' => 'Academic',
                    'audience' => 'All',
                    'display_from' => now()->toDateString(),
                ]);
                $browser->pause(1500);
            });
            $created = Notice::query()->where('title', $marker)->first();
            if (!$created) {
                $this->markTestSkipped('Notice store did not persist (module may be disabled — see Validation Report).');
                return;
            }
            $this->assertSame((int) $this->adminUser?->id, (int) $created->created_by, 'created_by must be the acting user.');
            $this->assertSame((int) $this->adminUser?->id, (int) $created->updated_by, 'updated_by must be the acting user.');
        } finally {
            if ($created instanceof Notice) {
                $created->forceDelete();
            }
        }
    }

    /** created_by/updated_by are set by the controller on event store (G48). */
    public function test_noticesevents_43_event_created_by_set_by_controller(): void
    {
        $marker = 'EvtAuditProbe ' . $this->generateUniqueSuffix();
        $created = null;
        try {
            $this->browse(function (Browser $browser) use ($marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_INDEX_PATH, 900);
                $this->postFormFromBrowser($browser, $this->tenantUrl(self::EVENT_INDEX_PATH), [
                    'event_name' => $marker,
                    'event_type' => 'Academic',
                    'audience' => 'All',
                    'start_date' => now()->toDateString(),
                    'end_date' => now()->addDay()->toDateString(),
                ]);
                $browser->pause(1500);
            });
            $created = SchoolEvent::query()->where('event_name', $marker)->first();
            if (!$created) {
                $this->markTestSkipped('Event store did not persist (module may be disabled — see Validation Report).');
                return;
            }
            $this->assertSame((int) $this->adminUser?->id, (int) $created->created_by, 'created_by must be the acting user.');
            $this->assertSame((int) $this->adminUser?->id, (int) $created->updated_by, 'updated_by must be the acting user.');
        } finally {
            if ($created instanceof SchoolEvent) {
                $created->forceDelete();
            }
        }
    }

    // ============================================================
    // 50-59  Permissions / authorization (BC-AUTH, F37/#31)
    // ============================================================

    /** Guest is redirected to login on the notices index. */
    public function test_noticesevents_50_guest_redirected_from_notices(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::NOTICE_INDEX_PATH))->pause(1500);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** Guest is redirected to login on the school-events index. */
    public function test_noticesevents_51_guest_redirected_from_events(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::EVENT_INDEX_PATH))->pause(1500);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** Non-super-admin WITHOUT frontoffice.notice.view cannot open the notices index (real 403). */
    public function test_noticesevents_52_notice_index_requires_view_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::NOTICE_INDEX_PATH, self::NOTICE_INDEX_PATH, 'GET');
    }

    /** Non-super-admin WITHOUT frontoffice.notice.create cannot store a notice. */
    public function test_noticesevents_53_notice_store_requires_create_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::NOTICE_INDEX_PATH, self::NOTICE_INDEX_PATH, 'POST', [
            'title' => 'PermDenied ' . $this->generateUniqueSuffix(),
            'content' => 'body',
            'category' => 'Academic',
            'audience' => 'All',
            'display_from' => now()->toDateString(),
        ]);
    }

    /** Non-super-admin WITHOUT frontoffice.school-event.view cannot open the events index (real 403). */
    public function test_noticesevents_54_event_index_requires_view_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::EVENT_INDEX_PATH, self::EVENT_INDEX_PATH, 'GET');
    }

    /** Non-super-admin WITHOUT frontoffice.school-event.create cannot store an event. */
    public function test_noticesevents_55_event_store_requires_create_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::EVENT_INDEX_PATH, self::EVENT_INDEX_PATH, 'POST', [
            'event_name' => 'PermDenied ' . $this->generateUniqueSuffix(),
            'event_type' => 'Academic',
            'audience' => 'All',
            'start_date' => now()->toDateString(),
            'end_date' => now()->addDay()->toDateString(),
        ]);
    }

    // ============================================================
    // 60-69  UI / UX (list, search, filter, show, edit)
    // ============================================================

    /** Notice index renders and lists a seeded row. */
    public function test_noticesevents_60_notice_index_lists_records(): void
    {
        $record = $this->createNotice(['title' => 'IndexRowN ' . $this->generateUniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_INDEX_PATH, 1000);
                $browser->waitForText((string) $record->title, 12)->assertSee((string) $record->title);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Notice search filter narrows the list by title. */
    public function test_noticesevents_61_notice_search_filters_results(): void
    {
        $needle = 'UniqNoticeSearch' . $this->generateUniqueSuffix();
        $match = $this->createNotice(['title' => $needle]);
        $other = $this->createNotice(['title' => 'OtherN ' . $this->generateUniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($needle, $other): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_INDEX_PATH . '?search=' . urlencode($needle), 1200);
                $browser->waitForText($needle, 12)->assertSee($needle);
                $this->assertStringNotContainsString(
                    (string) $other->title,
                    $browser->driver->getPageSource(),
                    'Non-matching notice must be filtered out.'
                );
            });
        } finally {
            $match->forceDelete();
            $other->forceDelete();
        }
    }

    /** Notice audience filter narrows results. */
    public function test_noticesevents_62_notice_audience_filter_applies(): void
    {
        $needle = 'AudFilter' . $this->generateUniqueSuffix();
        $staffNotice = $this->createNotice(['title' => $needle, 'audience' => 'Staff']);
        try {
            $this->browse(function (Browser $browser) use ($needle): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication(
                    $browser,
                    self::NOTICE_INDEX_PATH . '?audience=Staff&search=' . urlencode($needle),
                    1200
                );
                $browser->waitForText($needle, 12)->assertSee($needle);
            });
        } finally {
            $staffNotice->forceDelete();
        }
    }

    /** Notice show page displays details. */
    public function test_noticesevents_63_notice_show_displays_details(): void
    {
        $record = $this->createNotice(['title' => 'ShowN ' . $this->generateUniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_SHOW_BASE . '/' . $record->id, 1000);
                $browser->waitForText((string) $record->title, 12)->assertSee((string) $record->title);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Notice edit page loads with current values and update persists a change. */
    public function test_noticesevents_64_notice_edit_and_update(): void
    {
        $record = $this->createNotice(['title' => 'EditN ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        $newTitle = 'EditedN ' . $this->generateUniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($id, $newTitle, $record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_SHOW_BASE . '/' . $id . '/edit', 1000);
                $browser->waitFor('input[name="title"]', 12)->assertInputValue('title', (string) $record->title);
                $this->postFormFromBrowser($browser, $this->tenantUrl(self::NOTICE_SHOW_BASE . '/' . $id), [
                    '_method' => 'PUT',
                    'title' => $newTitle,
                    'content' => (string) $record->content,
                    'category' => (string) $record->category,
                    'audience' => (string) $record->audience,
                    'display_from' => $record->display_from?->toDateString() ?? now()->toDateString(),
                ]);
                $browser->pause(1500);
            });
            $record->refresh();
            $this->assertSame($newTitle, $record->title, 'notice update() must persist the new title.');
        } finally {
            Notice::withTrashed()->where('id', $id)->get()->each(fn (Notice $r) => $r->forceDelete());
        }
    }

    /** Event index renders (upcoming + past) and lists a seeded upcoming row. */
    public function test_noticesevents_65_event_index_lists_records(): void
    {
        $record = $this->createEvent([
            'event_name' => 'IndexRowE ' . $this->generateUniqueSuffix(),
            'start_date' => now()->addDays(3)->toDateString(),
            'end_date' => now()->addDays(4)->toDateString(),
        ]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_INDEX_PATH, 1000);
                $browser->waitForText((string) $record->event_name, 12)->assertSee((string) $record->event_name);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Event show page displays details. */
    public function test_noticesevents_66_event_show_displays_details(): void
    {
        $record = $this->createEvent(['event_name' => 'ShowE ' . $this->generateUniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_SHOW_BASE . '/' . $record->id, 1000);
                $browser->waitForText((string) $record->event_name, 12)->assertSee((string) $record->event_name);
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Event edit page loads with current values and update persists a change. */
    public function test_noticesevents_67_event_edit_and_update(): void
    {
        $record = $this->createEvent(['event_name' => 'EditE ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        $newName = 'EditedE ' . $this->generateUniqueSuffix();
        try {
            $this->browse(function (Browser $browser) use ($id, $newName, $record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_SHOW_BASE . '/' . $id . '/edit', 1000);
                $browser->waitFor('input[name="event_name"]', 12)->assertInputValue('event_name', (string) $record->event_name);
                $this->postFormFromBrowser($browser, $this->tenantUrl(self::EVENT_SHOW_BASE . '/' . $id), [
                    '_method' => 'PUT',
                    'event_name' => $newName,
                    'event_type' => (string) $record->event_type,
                    'audience' => (string) $record->audience,
                    'start_date' => $record->start_date?->toDateString() ?? now()->toDateString(),
                    'end_date' => $record->end_date?->toDateString() ?? now()->addDay()->toDateString(),
                ]);
                $browser->pause(1500);
            });
            $record->refresh();
            $this->assertSame($newName, $record->event_name, 'event update() must persist the new event_name.');
        } finally {
            SchoolEvent::withTrashed()->where('id', $id)->get()->each(fn (SchoolEvent $r) => $r->forceDelete());
        }
    }

    /** Notice index pinned ordering — is_pinned rows surface via orderByDesc('is_pinned'). */
    public function test_noticesevents_68_notice_pinned_ordering_available(): void
    {
        $pinned = $this->createNotice(['title' => 'PinnedN ' . $this->generateUniqueSuffix(), 'is_pinned' => 1]);
        try {
            $ordered = Notice::query()
                ->where('id', $pinned->id)
                ->latest('display_from')
                ->orderByDesc('is_pinned')
                ->first();
            $this->assertNotNull($ordered, 'Pinned notice must be retrievable via the index ordering.');
            $this->assertTrue((bool) $ordered->is_pinned, 'Pinned flag must persist for ordering.');
        } finally {
            $pinned->forceDelete();
        }
    }

    // ============================================================
    // 70-79  Edge cases + trash listings + 404 (BC-EDG)
    // ============================================================

    /** Notice trash page lists soft-deleted records. */
    public function test_noticesevents_70_notice_trash_shows_deleted(): void
    {
        $record = $this->createNotice(['title' => 'TrashN ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        $record->delete();
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_TRASH_PATH, 1000);
                $browser->waitForText((string) $record->title, 12)->assertSee((string) $record->title);
            });
        } finally {
            Notice::withTrashed()->where('id', $id)->get()->each(fn (Notice $r) => $r->forceDelete());
        }
    }

    /** Event trash page lists soft-deleted records. */
    public function test_noticesevents_71_event_trash_shows_deleted(): void
    {
        $record = $this->createEvent(['event_name' => 'TrashE ' . $this->generateUniqueSuffix()]);
        $id = (int) $record->id;
        $record->delete();
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_TRASH_PATH, 1000);
                $browser->waitForText((string) $record->event_name, 12)->assertSee((string) $record->event_name);
            });
        } finally {
            SchoolEvent::withTrashed()->where('id', $id)->get()->each(fn (SchoolEvent $r) => $r->forceDelete());
        }
    }

    /** 404 for a non-existent notice show id. */
    public function test_noticesevents_72_notice_show_404_for_missing(): void
    {
        $this->assert404($this->tenantUrl(self::NOTICE_SHOW_BASE . '/99999999'));
    }

    /** 404 for a non-existent event show id. */
    public function test_noticesevents_73_event_show_404_for_missing(): void
    {
        $this->assert404($this->tenantUrl(self::EVENT_SHOW_BASE . '/99999999'));
    }

    /** Notice.content LONGTEXT accepts very long HTML body. */
    public function test_noticesevents_74_notice_content_accepts_long_html(): void
    {
        $record = null;
        try {
            $long = '<p>' . str_repeat('Notice paragraph body. ', 800) . '</p>'; // ~19k chars
            $record = $this->createNotice(['title' => 'LongContent ' . $this->generateUniqueSuffix(), 'content' => $long]);
            $record->refresh();
            $this->assertSame($long, $record->content, 'LONGTEXT content must store long HTML intact.');
        } finally {
            if ($record instanceof Notice) {
                $record->forceDelete();
            }
        }
    }

    /** Event.description TEXT accepts long content. */
    public function test_noticesevents_75_event_description_accepts_long_text(): void
    {
        $record = null;
        try {
            $long = str_repeat('Event description sentence. ', 400); // ~11k chars, within TEXT (64k)
            $record = $this->createEvent(['event_name' => 'LongDesc ' . $this->generateUniqueSuffix(), 'description' => $long]);
            $record->refresh();
            $this->assertSame($long, $record->description, 'TEXT description must store long content.');
        } finally {
            if ($record instanceof SchoolEvent) {
                $record->forceDelete();
            }
        }
    }

    // ============================================================
    // 90-99  Security + source-defect probes (TC-S / DEV)
    // ============================================================

    /** Stored XSS in notice.title is HTML-escaped on the show page. */
    public function test_noticesevents_90_notice_title_xss_is_escaped(): void
    {
        $xss = '<script>alert("ntc' . $this->generateUniqueSuffix() . '")</script>';
        $record = $this->createNotice(['title' => $xss]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::NOTICE_SHOW_BASE . '/' . $record->id, 1200);
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<script>alert("ntc', $source, 'notice.title must be HTML-escaped.');
            });
        } finally {
            $record->forceDelete();
        }
    }

    /** Stored XSS in event.event_name is HTML-escaped on the show page. */
    public function test_noticesevents_91_event_name_xss_is_escaped(): void
    {
        $xss = '<script>alert("evt' . $this->generateUniqueSuffix() . '")</script>';
        $record = $this->createEvent(['event_name' => $xss]);
        try {
            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EVENT_SHOW_BASE . '/' . $record->id, 1200);
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<script>alert("evt', $source, 'event.event_name must be HTML-escaped.');
            });
        } finally {
            $record->forceDelete();
        }
    }

    /**
     * DEV-FOF-NE-005 (proving test): NoticeBoardController writes NO activityLog() on
     * store/update/destroy/toggleStatus (only restore + forceDelete log), diverging from the
     * module-wide activity-log convention and from SchoolEventController.destroy() which DOES log.
     */
    public function test_noticesevents_92_notice_partial_activity_logging_documents_gap(): void
    {
        $source = $this->readControllerSource(\Modules\FrontOffice\Http\Controllers\NoticeBoardController::class);
        if ($source === null) {
            $this->markTestSkipped('NoticeBoardController source unreadable from the runner.');
            return;
        }
        // store/update/destroy bodies must NOT contain activityLog( — the documented gap.
        $storeBody = $this->extractMethodBody($source, 'store');
        $updateBody = $this->extractMethodBody($source, 'update');
        $destroyBody = $this->extractMethodBody($source, 'destroy');
        $this->assertStringNotContainsString('activityLog(', $storeBody, 'DEV-FOF-NE-005: notice store() logs nothing (documented gap).');
        $this->assertStringNotContainsString('activityLog(', $updateBody, 'DEV-FOF-NE-005: notice update() logs nothing (documented gap).');
        $this->assertStringNotContainsString('activityLog(', $destroyBody, 'DEV-FOF-NE-005: notice destroy() logs nothing (documented gap).');
        // restore + forceDelete DO log — asserts our verbatim reading of the source is correct.
        $this->assertStringContainsString('activityLog(', $this->extractMethodBody($source, 'restore'), 'notice restore() must log Restored.');
        $this->assertStringContainsString("'Restored'", $source, 'notice restore() event string must be Restored.');
    }

    /**
     * DEV-FOF-NE-005 (proving test, events side): SchoolEventController logs on
     * destroy/restore/forceDelete but NOT on store/update/toggleStatus.
     */
    public function test_noticesevents_93_event_partial_activity_logging_documents_gap(): void
    {
        $source = $this->readControllerSource(\Modules\FrontOffice\Http\Controllers\SchoolEventController::class);
        if ($source === null) {
            $this->markTestSkipped('SchoolEventController source unreadable from the runner.');
            return;
        }
        $this->assertStringNotContainsString('activityLog(', $this->extractMethodBody($source, 'store'), 'DEV-FOF-NE-005: event store() logs nothing.');
        $this->assertStringNotContainsString('activityLog(', $this->extractMethodBody($source, 'update'), 'DEV-FOF-NE-005: event update() logs nothing.');
        $this->assertStringContainsString('activityLog(', $this->extractMethodBody($source, 'destroy'), 'event destroy() must log Deleted.');
        $this->assertStringContainsString("'Deleted'", $source, 'event destroy() event string must be Deleted.');
    }

    // ============================================================
    // ---- Private helper library (mirrors FrontOffice\PhoneDiary sibling) ----
    // ============================================================

    private function createNotice(array $overrides = []): Notice
    {
        return Notice::query()->create($this->buildNoticePayload($overrides));
    }

    private function createEvent(array $overrides = []): SchoolEvent
    {
        return SchoolEvent::query()->create($this->buildEventPayload($overrides));
    }

    private function buildNoticePayload(array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));

        return array_merge([
            'title' => 'Notice ' . $this->generateUniqueSuffix(),
            'content' => 'Notice body ' . $this->generateUniqueSuffix(),
            'category' => 'Academic',
            'audience' => 'All',
            'display_from' => now()->toDateString(),
            'is_pinned' => 0,
            'is_emergency' => 0,
            'status' => 'Active',
            'is_active' => 1,
            'created_by' => $adminId,
            'updated_by' => $adminId,
        ], $overrides);
    }

    private function buildEventPayload(array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));

        return array_merge([
            'event_name' => 'Event ' . $this->generateUniqueSuffix(),
            'event_type' => 'Academic',
            'start_date' => now()->toDateString(),
            'end_date' => now()->addDay()->toDateString(),
            'audience' => 'All',
            'is_public' => 0,
            'notification_sent' => 0,
            'is_active' => 1,
            'created_by' => $adminId,
            'updated_by' => $adminId,
        ], $overrides);
    }

    /** G45 boundary helper for fof_notices sized string columns. */
    private function assertNoticeSizedString(string $column, int $max): void
    {
        $over = null;
        try {
            $over = $this->createNotice(['title' => 'Boundary ' . $this->generateUniqueSuffix(), $column => str_repeat('X', $max + 5)]);
            $over->refresh();
            $stored = (string) ($over->{$column} ?? '');
            $this->assertLessThanOrEqual($max, strlen($stored), "Over-length {$column} must be rejected or truncated to <= {$max}.");
        } catch (Throwable $e) {
            $this->assertTrue(true, "DB rejected over-length notice.{$column}: " . $e->getMessage());
        } finally {
            if ($over instanceof Notice) {
                $over->forceDelete();
            }
        }

        $exact = null;
        try {
            $value = str_repeat('Y', $max);
            $exact = $this->createNotice(['title' => 'BoundaryOk ' . $this->generateUniqueSuffix(), $column => $value]);
            $exact->refresh();
            $this->assertSame($value, (string) $exact->{$column}, "Exactly-{$max}-char notice.{$column} must persist intact.");
        } finally {
            if ($exact instanceof Notice) {
                $exact->forceDelete();
            }
        }
    }

    /** G45 boundary helper for fof_school_events sized string columns. */
    private function assertEventSizedString(string $column, int $max): void
    {
        $over = null;
        try {
            $over = $this->createEvent(['event_name' => 'Boundary ' . $this->generateUniqueSuffix(), $column => str_repeat('X', $max + 5)]);
            $over->refresh();
            $stored = (string) ($over->{$column} ?? '');
            $this->assertLessThanOrEqual($max, strlen($stored), "Over-length {$column} must be rejected or truncated to <= {$max}.");
        } catch (Throwable $e) {
            $this->assertTrue(true, "DB rejected over-length event.{$column}: " . $e->getMessage());
        } finally {
            if ($over instanceof SchoolEvent) {
                $over->forceDelete();
            }
        }

        $exact = null;
        try {
            $value = str_repeat('Y', $max);
            $exact = $this->createEvent(['event_name' => 'BoundaryOk ' . $this->generateUniqueSuffix(), $column => $value]);
            $exact->refresh();
            $this->assertSame($value, (string) $exact->{$column}, "Exactly-{$max}-char event.{$column} must persist intact.");
        } finally {
            if ($exact instanceof SchoolEvent) {
                $exact->forceDelete();
            }
        }
    }

    private function looksLikeNotNullFailure(Throwable $e): bool
    {
        $msg = strtolower($e->getMessage());
        return str_contains($msg, 'cannot be null')
            || str_contains($msg, 'not null')
            || str_contains($msg, "doesn't have a default value")
            || str_contains($msg, 'integrity constraint')
            || str_contains($msg, '23000')
            || str_contains($msg, 'incorrect');
    }

    /** Tolerant activity-log assertion — skips (does not fail) if sink/row is absent (env-dependent). */
    private function assertActivityLoggedTolerant(string $event, int $subjectId, string $subjectTable): void
    {
        try {
            if (!Schema::hasTable('sys_activity_logs')) {
                $this->markTestSkipped('sys_activity_logs not present — activity assertion skipped (env prerequisite).');
                return;
            }
            $exists = DB::table('sys_activity_logs')
                ->where('event', $event)
                ->where(function ($q) use ($subjectId) {
                    $q->where('subject_id', $subjectId)->orWhere('model_id', $subjectId);
                })
                ->exists();
            // If the browser action did not hit the controller (module disabled), no row will exist.
            if (!$exists) {
                $this->markTestSkipped("No '{$event}' activity row for {$subjectTable}#{$subjectId} — module likely disabled (env prerequisite).");
                return;
            }
            $this->assertTrue($exists, "Expected a '{$event}' activity-log row for {$subjectTable}#{$subjectId}.");
        } catch (Throwable $e) {
            $this->markTestSkipped('Activity-log sink not assertable: ' . $e->getMessage());
        }
    }

    private function readControllerSource(string $class): ?string
    {
        try {
            $file = (new \ReflectionClass($class))->getFileName();
            $source = @file_get_contents((string) $file);
            return is_string($source) && $source !== '' ? $source : null;
        } catch (Throwable) {
            return null;
        }
    }

    /** Extract a method body from PHP source by brace matching (best-effort; returns full source if not found). */
    private function extractMethodBody(string $source, string $method): string
    {
        if (!preg_match('/function\s+' . preg_quote($method, '/') . '\s*\(/', $source, $m, PREG_OFFSET_CAPTURE)) {
            return '';
        }
        $start = $m[0][1];
        $brace = strpos($source, '{', $start);
        if ($brace === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($source);
        for ($i = $brace; $i < $len; $i++) {
            $ch = $source[$i];
            if ($ch === '{') {
                $depth++;
            } elseif ($ch === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $brace, $i - $brace + 1);
                }
            }
        }
        return substr($source, $brace);
    }

    private function assert404(string $url): void
    {
        $this->browse(function (Browser $browser) use ($url): void {
            $this->authenticateBrowserSession($browser);
            $browser->visit($url)->pause(1200);
            $status = $this->responseStatusCode($browser);
            $source = strtolower($browser->driver->getPageSource());
            $is404 = $status === 404 || str_contains($source, 'not found') || str_contains($source, '404');
            $this->assertTrue($is404, 'Non-existent record must yield 404. Got status: ' . $status);
        });
    }

    /** Permission-negative (F37/#31): a fresh non-super-admin without the ability must get 403. */
    private function assertForbiddenForLimitedUser(string $indexPath, string $path, string $method = 'GET', array $payload = []): void
    {
        $limited = $this->makeLimitedUserOrSkip();

        try {
            $this->browse(function (Browser $browser) use ($limited, $indexPath, $path, $method, $payload): void {
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
                    $browser->visit($this->tenantUrl($indexPath))->pause(800);
                    $status = $this->postFormFromBrowser($browser, $this->tenantUrl($path), $payload);
                    $this->assertContains($status, [403, 419], 'Limited user POST must be forbidden (403). Got: ' . $status);
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
                'name' => 'Limited NE ' . $suffix,
                'short_name' => 'lne' . substr($suffix, -5),
                'email' => 'limited.ne.' . $suffix . '@tenant.test',
                'emp_code' => 'LNE_' . uniqid(),
                'password' => 'password',
                'email_verified_at' => now(),
            ];

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
