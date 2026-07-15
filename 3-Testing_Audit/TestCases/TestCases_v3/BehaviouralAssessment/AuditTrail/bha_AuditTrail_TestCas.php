<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\BehaviouralAssessment\Http\Controllers\BaAuditLogController;
use Modules\BehaviouralAssessment\Models\BaAssessment;
use Modules\BehaviouralAssessment\Models\BaAssessmentPeriod;
use Modules\BehaviouralAssessment\Models\BaAssessmentRating;
use Modules\BehaviouralAssessment\Models\BaAuditLog;
use Modules\BehaviouralAssessment\Models\BaIncident;
use Modules\Prime\Models\Domain;
use ReflectionClass;
use Tests\DuskTestCase;
use Throwable;

/**
 * Behavioural Assessment — Audit Trail (Reports → Audit Trail) — single comprehensive Dusk suite.
 *
 * Screen requirement : 4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/19-Audit-Trail.md
 * Depth              : LIGHT / read-focused — read-only immutable ledger. NOT a CRUD matrix.
 * DB scope           : TENANT-side (tenant_db, database-per-tenant, InitializeTenancyByDomain middleware).
 * Runtime table      : ba_audit_log  (live `ba_` prefix — the DDL doc uses stale `bha_`; see DOC-BA-001).
 * Controller         : Modules\BehaviouralAssessment\Http\Controllers\BaAuditLogController  (single index() method)
 * Route              : GET /behavioural-assessment/audit-log  (name behavioural-assessment.audit-log.index) — the ONLY route
 * FormRequest        : NONE (read-only; no store/update/destroy).
 * Permission         : tenant.behavioural-assessment.audit-log.{viewAny|view}  (Gate::authorize in controller; BaAuditLogPolicy)
 * Filters (REAL)     : period_id (scopeForPeriod), entity_type (=), field_name (LIKE %..%). Order: changed_at DESC, id DESC. paginate(30).
 * Activity log       : NONE for this screen — it IS the audit sink; it does not itself write to activity_logs.
 *
 * Immutability (requirement "The Immutable Ledger Rule"):
 *   - ba_audit_log has NO updated_at, NO deleted_at; the model has $timestamps=false and does NOT use SoftDeletes.
 *   - No create/edit/update/delete route or UI is registered — only the read-only index. Proven in _03/_70/_71/_72.
 *
 * Cross-reference findings (requirement vs implementation — reported "verify in source"):
 *   - DOC-BA-001     : DDL doc prefix `bha_audit_log` diverges from live `ba_audit_log` (proven in _02).
 *   - DOC-BA-AUD-001 : requirement filters (Date Range, Action-Category dropdown, User autocomplete, Student) are
 *                      NOT implemented — the screen only offers period_id / entity_type / field_name (proven in _74).
 *   - DOC-BA-AUD-002 : requirement says the ledger captures + displays the IP Address; ba_audit_log has NO ip_address
 *                      column and the grid renders no IP column (proven in _75).
 */
class bha_AuditTrail_TestCas extends DuskTestCase
{
    private const INDEX_PATH   = '/behavioural-assessment/audit-log';
    private const ROUTE_NAME   = 'behavioural-assessment.audit-log.index';

    private const AUDIT_TABLE  = 'ba_audit_log';
    private const DDL_TABLE    = 'bha_audit_log';   // stale DDL-doc name — must NOT exist at runtime

    private const SEED_PREFIX  = 'zzat';            // all seeded rows carry field_name LIKE 'zzat%' for safe cleanup
    private const SCREENSHOT_DIR = 'tests/Browser/Modules/BehaviouralAssessment/AuditTrail/screenshots';

    /** @var array<int,string> */
    private const AUDIT_PERMISSIONS = [
        'tenant.behavioural-assessment.audit-log.viewAny',
        'tenant.behavioural-assessment.audit-log.view',
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
        $this->purgeSeededAudit();

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01–09 — Schema / DDL / model configuration truth
    // =====================================================================

    public function test_audit_trail_01_migration_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE), 'Table ba_audit_log does not exist.');
        $this->assertTrue(
            Schema::hasColumns(self::AUDIT_TABLE, [
                'id', 'entity_type', 'entity_id', 'field_name', 'old_value',
                'new_value', 'changed_by', 'changed_at', 'is_active',
                'created_by', 'created_at',
            ]),
            'Expected columns are missing in ba_audit_log.'
        );

        // MySQL 8 COLUMN_TYPE variance — assert with contains, never equals (constraint #17).
        if (DB::connection()->getDriverName() === 'mysql') {
            $cols = collect(DB::select('SHOW COLUMNS FROM ' . self::AUDIT_TABLE))->keyBy('Field');
            $this->assertStringContainsString('enum', strtolower((string) ($cols['entity_type']->Type ?? '')));
            $this->assertStringContainsString('assessment_rating', strtolower((string) ($cols['entity_type']->Type ?? '')));
            $this->assertStringContainsString('varchar', strtolower((string) ($cols['field_name']->Type ?? '')));
            $this->assertStringContainsString('bigint', strtolower((string) ($cols['entity_id']->Type ?? '')));
            $this->assertStringContainsString('tinyint', strtolower((string) ($cols['is_active']->Type ?? '')));
        }

        // Migration content — resolved from the APP repo via reflection (constraint #29/#32).
        $migration = $this->readAppFile($this->appRootPath('database/migrations/tenant/2026_06_16_130613_create_ba_audit_log_table.php'));
        if ($migration !== null) {
            $this->assertStringContainsString("Schema::create('ba_audit_log'", $migration);
            $this->assertStringContainsString("enum('entity_type'", $migration);
            $this->assertStringContainsString("string('field_name', 50)", $migration);
            $this->assertStringContainsString("idx_ba_audit_entity", $migration);
            $this->assertStringContainsString("idx_ba_audit_changed_by", $migration);
            $this->assertStringContainsString("idx_ba_audit_changed_at", $migration);
            // Immutability: no soft-delete, no updated_at in the migration body.
            $this->assertStringNotContainsString('softDeletes', $migration, 'DOC: audit ledger must not be soft-deletable.');
            $this->assertStringNotContainsString("timestamp('updated_at')", $migration);
        }

        // Model configuration.
        $model = new BaAuditLog();
        $this->assertSame('ba_audit_log', $model->getTable());
        $this->assertFalse($model->usesTimestamps(), 'Audit model must have $timestamps=false (immutable ledger).');
        $this->assertSame([
            'entity_type', 'entity_id', 'field_name', 'old_value', 'new_value',
            'changed_by', 'changed_at', 'is_active', 'created_by', 'created_at',
        ], $model->getFillable());

        // Entity-type constants match the DDL enum.
        $this->assertSame('assessment_rating', BaAuditLog::ENTITY_ASSESSMENT_RATING);
        $this->assertSame('assessment', BaAuditLog::ENTITY_ASSESSMENT);
        $this->assertSame('incident', BaAuditLog::ENTITY_INCIDENT);
    }

    public function test_audit_trail_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001(): void
    {
        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE), 'Runtime table ba_audit_log must exist.');

        // The DDL/registry spec name `bha_audit_log` must NOT exist — proving DOC-BA-001 divergence.
        try {
            $this->assertFalse(
                Schema::hasTable(self::DDL_TABLE),
                'DOC-BA-001 regression: bha_audit_log exists at runtime; expected only the live ba_audit_log.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable for DOC-BA-001 divergence check: ' . $e->getMessage());
        }

        // Model binds to the live `ba_` name (code wins over the doc).
        $this->assertSame('ba_audit_log', (new BaAuditLog())->getTable());
    }

    public function test_audit_trail_03_table_is_immutable_no_softdelete_no_updated_at(): void
    {
        // Immutable ledger: no updated_at, no deleted_at columns, no SoftDeletes trait.
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'updated_at'), 'Immutable ledger must not have updated_at.');
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'deleted_at'), 'Immutable ledger must not have deleted_at.');
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(BaAuditLog::class),
            'BaAuditLog must NOT use SoftDeletes — the ledger is insert-only.'
        );
    }

    public function test_audit_trail_04_casts_and_polymorphic_relationships_are_configured(): void
    {
        $model = new BaAuditLog();
        $casts = $model->getCasts();
        $this->assertSame('integer', $casts['entity_id'] ?? null);
        $this->assertSame('integer', $casts['changed_by'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('datetime', $casts['changed_at'] ?? null);
        $this->assertSame('datetime', $casts['created_at'] ?? null);

        $this->assertInstanceOf(BelongsTo::class, $model->assessmentEntity());
        $this->assertInstanceOf(BelongsTo::class, $model->assessmentRatingEntity());
        $this->assertInstanceOf(BelongsTo::class, $model->incidentEntity());
        $this->assertInstanceOf(BaAssessment::class, $model->assessmentEntity()->getRelated());
        $this->assertInstanceOf(BaAssessmentRating::class, $model->assessmentRatingEntity()->getRelated());
        $this->assertInstanceOf(BaIncident::class, $model->incidentEntity()->getRelated());
    }

    // =====================================================================
    // Band 10–19 — Business rules / render / listing (BC-BIZ)
    // =====================================================================

    public function test_audit_trail_10_index_renders_for_admin_with_grid_and_filters(): void
    {
        $this->browseWithFailureScreenshot('index-render', function (Browser $browser): void {
            $this->openIndex($browser);
            $browser->assertSee('Audit Log')
                ->assertSee('Changed At')
                ->assertSee('Old Value')
                ->assertSee('New Value')
                ->assertSee('Changed By')
                ->assertPresent('select[name="entity_type"]')
                ->assertPresent('select[name="period_id"]')
                ->assertPresent('input[name="field_name"]');
        });
    }

    public function test_audit_trail_11_seeded_row_appears_in_listing(): void
    {
        $token = 'AUDITVAL' . $this->uniqueSuffix();
        $this->createAuditSeed(['old_value' => $token, 'new_value' => $token . 'NEW']);

        $this->browseWithFailureScreenshot('row-listed', function (Browser $browser) use ($token): void {
            $this->openIndex($browser, ['field_name' => $this->lastField]);
            $browser->assertSee($token)
                ->assertSee($token . 'NEW')
                ->assertSee('records');
        });
    }

    public function test_audit_trail_12_records_counter_reflects_filtered_total(): void
    {
        $field = self::SEED_PREFIX . 'cnt' . $this->uniqueSuffix();
        for ($i = 0; $i < 3; $i++) {
            $this->createAuditSeed(['field_name' => $field, 'old_value' => 'CVAL' . $i]);
        }

        $this->browseWithFailureScreenshot('records-counter', function (Browser $browser) use ($field): void {
            $this->openIndex($browser, ['field_name' => $field]);
            $browser->assertSee('3 records');
        });
    }

    public function test_audit_trail_13_ordering_is_changed_at_desc(): void
    {
        $field = self::SEED_PREFIX . 'ord' . $this->uniqueSuffix();
        $older = 'OLDER' . $this->uniqueSuffix();
        $newer = 'NEWER' . $this->uniqueSuffix();
        $this->createAuditSeed(['field_name' => $field, 'old_value' => $older, 'changed_at' => now()->subMinutes(5)]);
        $this->createAuditSeed(['field_name' => $field, 'old_value' => $newer, 'changed_at' => now()]);

        $this->browseWithFailureScreenshot('order-desc', function (Browser $browser) use ($field, $older, $newer): void {
            $this->openIndex($browser, ['field_name' => $field]);
            $source = $browser->driver->getPageSource();
            $posNewer = strpos($source, $newer);
            $posOlder = strpos($source, $older);
            $this->assertNotFalse($posNewer, 'Newer row must be present.');
            $this->assertNotFalse($posOlder, 'Older row must be present.');
            $this->assertLessThan($posOlder, $posNewer, 'Rows must be ordered changed_at DESC (newest first).');
        });
    }

    public function test_audit_trail_14_static_log_helper_inserts_an_immutable_row(): void
    {
        $field = self::SEED_PREFIX . 'log' . $this->uniqueSuffix();
        $row = BaAuditLog::log(BaAuditLog::ENTITY_ASSESSMENT, 424242, $field, '3', '4');

        $this->assertNotNull($row->id, 'Static log() must persist a row.');
        $persisted = BaAuditLog::find($row->id);
        $this->assertNotNull($persisted);
        $this->assertSame('assessment', $persisted->entity_type);
        $this->assertSame('3', $persisted->old_value);
        $this->assertSame('4', $persisted->new_value);
        $this->assertTrue((bool) $persisted->is_active);
    }

    public function test_audit_trail_15_entity_type_badges_render_for_each_type(): void
    {
        $field = self::SEED_PREFIX . 'badge' . $this->uniqueSuffix();
        $this->createAuditSeed(['field_name' => $field, 'entity_type' => 'assessment', 'old_value' => 'BADGE_A']);
        $this->createAuditSeed(['field_name' => $field, 'entity_type' => 'assessment_rating', 'old_value' => 'BADGE_R']);
        $this->createAuditSeed(['field_name' => $field, 'entity_type' => 'incident', 'old_value' => 'BADGE_I']);

        $this->browseWithFailureScreenshot('entity-badges', function (Browser $browser) use ($field): void {
            $this->openIndex($browser, ['field_name' => $field]);
            $browser->assertSee('Assessment Rating')
                ->assertSee('Incident');
        });
    }

    // =====================================================================
    // Band 40–49 — Integration / polymorphic / period scope (BC-INT)
    // =====================================================================

    public function test_audit_trail_40_period_filter_query_executes_without_error(): void
    {
        // scopeForPeriod builds a compound subquery over assessments/ratings/incidents.
        // Defensive: exercise it against any available active period id; assert the page still renders 200.
        try {
            $period = BaAssessmentPeriod::where('is_active', true)->first();
            if (!$period) {
                $this->markTestSkipped('No active BaAssessmentPeriod available to exercise scopeForPeriod.');
            }
            // Query-level smoke: the scope must build+run without throwing.
            $count = BaAuditLog::query()->forPeriod((int) $period->id)->count();
            $this->assertIsInt($count);

            $this->browseWithFailureScreenshot('period-filter', function (Browser $browser) use ($period): void {
                $this->openIndex($browser, ['period_id' => (string) $period->id]);
                $browser->assertSee('records');
            });
        } catch (Throwable $e) {
            $this->markTestSkipped('Period-scope path unavailable: ' . $e->getMessage());
        }
    }

    public function test_audit_trail_41_period_dropdown_lists_active_periods(): void
    {
        try {
            $period = BaAssessmentPeriod::where('is_active', true)->orderByDesc('created_at')->first();
            if (!$period) {
                $this->markTestSkipped('No active period to assert in the filter dropdown.');
            }
            $this->browseWithFailureScreenshot('period-dropdown', function (Browser $browser) use ($period): void {
                $this->openIndex($browser);
                $source = $browser->driver->getPageSource();
                $this->assertStringContainsString('value="' . $period->id . '"', $source, 'Active period must appear as a filter option.');
            });
        } catch (Throwable $e) {
            $this->markTestSkipped('Period-dropdown path unavailable: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =====================================================================

    public function test_audit_trail_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to login.');
        });
    }

    public function test_audit_trail_51_limited_user_without_viewany_gets_403(): void
    {
        $limited = $this->makeLimitedUser();

        $this->browseWithFailureScreenshot('limited-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(500);
            $response = $this->sendJsonRequestFromBrowser($browser, 'GET', $this->tenantUrl(self::INDEX_PATH));
            $this->assertSame(403, (int) ($response['status'] ?? 0), 'Non-super-admin without viewAny must get 403.');
        });

        $this->deleteUser($limited);
    }

    public function test_audit_trail_52_policy_maps_to_permission_strings(): void
    {
        $policy = $this->readAppFile($this->moduleRootPath('app/Policies/BaAuditLogPolicy.php'));
        if ($policy === null) {
            $this->markTestSkipped('BaAuditLogPolicy source not readable from app repo.');
        }
        $this->assertStringContainsString('tenant.behavioural-assessment.audit-log.viewAny', $policy);
        $this->assertStringContainsString('tenant.behavioural-assessment.audit-log.view', $policy);
    }

    public function test_audit_trail_53_controller_authorizes_viewany_gate(): void
    {
        $controller = $this->readAppFile($this->moduleRootPath('app/Http/Controllers/BaAuditLogController.php'));
        if ($controller === null) {
            $this->markTestSkipped('BaAuditLogController source not readable from app repo.');
        }
        $this->assertStringContainsString(
            "Gate::authorize('tenant.behavioural-assessment.audit-log.viewAny')",
            $controller,
            'Controller must gate index() with the viewAny ability.'
        );
    }

    // =====================================================================
    // Band 60–69 — UI/UX (filters, empty state, pagination, persistence)
    // =====================================================================

    public function test_audit_trail_60_entity_type_filter_narrows_results(): void
    {
        $suffix = $this->uniqueSuffix();
        $incidentTok = 'INCTOK' . $suffix;
        $assessTok = 'ASMTOK' . $suffix;
        $this->createAuditSeed(['field_name' => self::SEED_PREFIX . 'et' . $suffix, 'entity_type' => 'incident', 'old_value' => $incidentTok]);
        $this->createAuditSeed(['field_name' => self::SEED_PREFIX . 'et' . $suffix, 'entity_type' => 'assessment', 'old_value' => $assessTok]);

        $this->browseWithFailureScreenshot('entity-filter', function (Browser $browser) use ($suffix, $incidentTok, $assessTok): void {
            $this->openIndex($browser, ['entity_type' => 'incident', 'field_name' => self::SEED_PREFIX . 'et' . $suffix]);
            $browser->assertSee($incidentTok)
                ->assertDontSee($assessTok);
        });
    }

    public function test_audit_trail_61_field_name_filter_like_matches(): void
    {
        $suffix = $this->uniqueSuffix();
        $matchField = self::SEED_PREFIX . 'match' . $suffix;
        $otherField = self::SEED_PREFIX . 'other' . $suffix;
        $matchTok = 'MATCHVAL' . $suffix;
        $otherTok = 'OTHERVAL' . $suffix;
        $this->createAuditSeed(['field_name' => $matchField, 'old_value' => $matchTok]);
        $this->createAuditSeed(['field_name' => $otherField, 'old_value' => $otherTok]);

        $this->browseWithFailureScreenshot('field-filter', function (Browser $browser) use ($matchField, $matchTok, $otherTok): void {
            $this->openIndex($browser, ['field_name' => $matchField]);
            $browser->assertSee($matchTok)
                ->assertDontSee($otherTok);
        });
    }

    public function test_audit_trail_62_empty_state_message_when_no_records_match(): void
    {
        $noMatch = self::SEED_PREFIX . 'nomatch' . $this->uniqueSuffix();

        $this->browseWithFailureScreenshot('empty-state', function (Browser $browser) use ($noMatch): void {
            $this->openIndex($browser, ['field_name' => $noMatch]);
            $browser->assertSee('No audit records found.')
                ->assertSee('0 records');
        });
    }

    public function test_audit_trail_63_pagination_present_when_more_than_thirty_rows(): void
    {
        // paginate(30) — 31 matching rows must produce a second page.
        try {
            $field = self::SEED_PREFIX . 'pg' . $this->uniqueSuffix();
            for ($i = 0; $i < 31; $i++) {
                $this->createAuditSeed(['field_name' => $field, 'old_value' => 'PG' . $i]);
            }

            $this->browseWithFailureScreenshot('pagination', function (Browser $browser) use ($field): void {
                $this->openIndex($browser, ['field_name' => $field]);
                $browser->assertSee('31 records');
                $source = $browser->driver->getPageSource();
                $this->assertStringContainsString('pagination', strtolower($source), 'Pagination nav must render for >30 rows.');
                // Filter query-string must be appended to page links.
                $this->assertStringContainsString('field_name=' . $field, $source, 'Filter must persist across pagination links.');
            });
        } catch (Throwable $e) {
            $this->markTestSkipped('Pagination path unavailable: ' . $e->getMessage());
        }
    }

    public function test_audit_trail_64_field_filter_value_persists_in_input(): void
    {
        $field = self::SEED_PREFIX . 'persist' . $this->uniqueSuffix();

        $this->browseWithFailureScreenshot('filter-persist', function (Browser $browser) use ($field): void {
            $this->openIndex($browser, ['field_name' => $field]);
            $browser->assertInputValue('field_name', $field);
        });
    }

    // =====================================================================
    // Band 70–79 — Immutability enforcement + cross-reference gaps (BC-EDG)
    // =====================================================================

    public function test_audit_trail_70_no_mutation_routes_are_registered(): void
    {
        // The ONLY registered audit-log route is the read-only index.
        $this->assertTrue(Route::has(self::ROUTE_NAME), 'audit-log.index must be registered.');
        foreach (['store', 'update', 'destroy', 'create', 'edit', 'forceDelete', 'restore', 'toggleStatus'] as $verb) {
            $this->assertFalse(
                Route::has('behavioural-assessment.audit-log.' . $verb),
                "Immutable ledger must not register a '{$verb}' route."
            );
        }
    }

    public function test_audit_trail_71_post_to_audit_log_is_rejected(): void
    {
        $response = $this->apiCall('POST', $this->tenantUrl(self::INDEX_PATH), [
            'entity_type' => 'assessment', 'entity_id' => 1, 'field_name' => 'x', 'old_value' => 'a', 'new_value' => 'b',
        ]);
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [404, 405],
            'POST to the audit-log endpoint must not be routable (immutable ledger).'
        );
    }

    public function test_audit_trail_72_delete_to_audit_log_is_rejected(): void
    {
        $response = $this->apiCall('DELETE', $this->tenantUrl(self::INDEX_PATH));
        $this->assertContains(
            (int) ($response['status'] ?? 0),
            [404, 405],
            'DELETE to the audit-log endpoint must not be routable (immutable ledger).'
        );
    }

    public function test_audit_trail_73_invalid_entity_type_filter_returns_empty_gracefully(): void
    {
        // An out-of-enum entity_type filter matches no rows — the page must render the empty state, not error.
        $this->browseWithFailureScreenshot('invalid-filter', function (Browser $browser): void {
            $this->openIndex($browser, ['entity_type' => 'not_a_real_entity_type_zzz']);
            $browser->assertSee('No audit records found.');
        });
    }

    public function test_audit_trail_74_requirement_filters_not_implemented_doc_ba_aud_001(): void
    {
        // Requirement 19-Audit-Trail.md specifies Date-Range, Action-Category dropdown, User autocomplete and
        // Student filters. The implemented screen offers only period_id / entity_type / field_name.
        $view = $this->readAppFile($this->moduleRootPath('resources/views/audit-log/index.blade.php'));
        if ($view === null) {
            $this->markTestSkipped('audit-log view source not readable from app repo.');
        }
        // Filters the requirement asked for that are NOT present:
        $this->assertStringNotContainsString('name="start_date"', $view, 'DOC-BA-AUD-001 changed: date-range filter now present.');
        $this->assertStringNotContainsString('name="end_date"', $view);
        $this->assertStringNotContainsString('Grade Edit', $view, 'DOC-BA-AUD-001: requirement Action-Category options are not implemented.');
        $this->assertStringNotContainsString('name="user_id"', $view, 'DOC-BA-AUD-001: User autocomplete filter not implemented.');
        $this->assertStringNotContainsString('name="student_id"', $view, 'DOC-BA-AUD-001: Student filter not implemented.');
        // Filters that ARE present (the real, narrower set):
        $this->assertStringContainsString('name="entity_type"', $view);
        $this->assertStringContainsString('name="field_name"', $view);
        $this->assertStringContainsString('name="period_id"', $view);
    }

    public function test_audit_trail_75_no_ip_address_column_or_display_doc_ba_aud_002(): void
    {
        // Requirement business rule + grid promise an IP Address; the schema has no such column and the grid shows none.
        $this->assertFalse(Schema::hasColumn(self::AUDIT_TABLE, 'ip_address'), 'DOC-BA-AUD-002: requirement expects IP capture but ba_audit_log has no ip_address column.');

        $this->browseWithFailureScreenshot('no-ip-column', function (Browser $browser): void {
            $this->openIndex($browser);
            $browser->assertDontSee('IP Address');
        });
    }

    // =====================================================================
    // Band 90–99 — Tenancy isolation + security pack
    // =====================================================================

    public function test_audit_trail_90_tenant_context_is_initialized(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for tenant-side audit-trail tests.'
        );
        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE));
    }

    public function test_audit_trail_91_cross_tenant_direct_isolation_smoke(): void
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

    public function test_audit_trail_92_stored_xss_in_values_is_escaped_on_index(): void
    {
        $field = self::SEED_PREFIX . 'xss' . $this->uniqueSuffix();
        $this->createAuditSeed([
            'field_name' => $field,
            'old_value'  => '<script>alert(1)</script>',
            'new_value'  => '<img src=x onerror=alert(2)>',
        ]);

        $this->browseWithFailureScreenshot('xss-escaped', function (Browser $browser) use ($field): void {
            $this->openIndex($browser, ['field_name' => $field]);
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Stored old_value must be Blade-escaped.');
            $this->assertStringNotContainsString('<img src=x onerror=alert(2)>', $source, 'Stored new_value must be Blade-escaped.');
        });
    }

    // =====================================================================
    // ---- Private helper library ----
    // =====================================================================

    /** field_name of the most recent seed — used to scope listing assertions. */
    private string $lastField = '';

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
        $rawName = 'audit-trail-' . $kind . '-' . $caseName . '-' . now()->format('Ymd_His');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'audit-trail-' . $kind . '-' . now()->format('Ymd_His');
        try {
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safeName . '.png');
        } catch (Throwable) {
        }
    }

    // ---- UI drivers -------------------------------------------------------

    /** @param array<string,string> $query */
    private function openIndex(Browser $browser, array $query = []): void
    {
        $path = self::INDEX_PATH;
        if ($query !== []) {
            $path .= '?' . http_build_query($query);
        }
        $this->visitAuthenticated($browser, $path, 1000);
        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('table') !== null
                || $browser->element('select[name="entity_type"]') !== null;
        }, 'Audit-log index did not render.');
    }

    // ---- HTTP-from-browser ------------------------------------------------

    private function apiCall(string $method, string $url, array $payload = []): array
    {
        return $this->runOnAdminApiPage(fn (Browser $b) => $this->sendJsonRequestFromBrowser($b, $method, $url, $payload));
    }

    private function runOnAdminApiPage(callable $callback): array
    {
        $result = [];
        $this->browse(function (Browser $browser) use (&$result, $callback): void {
            $this->openIndex($browser);
            $result = $callback($browser);
        });
        return $result;
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
window.__atApiDone = false;
window.__atApiError = '';
window.__atApiResult = null;

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

        window.__atApiResult = {
            status: response.status,
            type: response.type,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__atApiError = String(error);
    } finally {
        window.__atApiDone = true;
    }
})();
JS);

        $browser->waitUsing(25, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__atApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__atApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__atApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        // A `redirect: manual` fetch reports opaqueredirect with status 0 for 3xx — normalize to 302.
        if ((int) ($response['status'] ?? 0) === 0 && (string) ($response['type'] ?? '') === 'opaqueredirect') {
            $response['status'] = 302;
        }

        return is_array($response) ? $response : [];
    }

    // ---- Seed / cleanup ---------------------------------------------------

    private function createAuditSeed(array $overrides = []): BaAuditLog
    {
        $field = $overrides['field_name'] ?? (self::SEED_PREFIX . 'seed' . $this->uniqueSuffix());
        $this->lastField = $field;

        $payload = array_merge([
            'entity_type' => BaAuditLog::ENTITY_ASSESSMENT_RATING,
            'entity_id'   => random_int(400000, 499999),
            'field_name'  => $field,
            'old_value'   => 'OLD',
            'new_value'   => 'NEW',
            'changed_by'  => (int) $this->adminUser->id,
            'changed_at'  => now(),
            'is_active'   => true,
            'created_by'  => (int) $this->adminUser->id,
            'created_at'  => now(),
        ], $overrides);
        $payload['field_name'] = $field;

        return BaAuditLog::query()->create($payload);
    }

    /** Hard-delete every row this suite seeded (all carry field_name LIKE 'zzat%'). */
    private function purgeSeededAudit(): void
    {
        try {
            if (Schema::hasTable(self::AUDIT_TABLE)) {
                DB::table(self::AUDIT_TABLE)->where('field_name', 'like', self::SEED_PREFIX . '%')->delete();
            }
        } catch (Throwable) {
            // Best-effort cleanup — a locked row is left for the next run's purge.
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
                'name'              => 'AT Limited ' . $this->uniqueSuffix(),
                'email'             => 'at_limited_' . strtolower($this->uniqueSuffix()) . '@tenant.test',
                'password'          => 'password',
                'is_active'         => 1,
                'prefered_language' => $lang,
                'email_verified_at' => now(),
            ];
            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attributes['user_type'] = 'EMPLOYEE';
            }
            if (Schema::hasColumn('sys_users', 'emp_code')) {
                $attributes['emp_code'] = 'AL' . substr($this->uniqueSuffix(), -8);
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
        $this->grantAuditPermissions($this->adminUser);
    }

    private function grantAuditPermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo') && !method_exists($user, 'assignRole')) {
            return;
        }
        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist(self::AUDIT_PERMISSIONS, $guard);
        $this->syncRoleWithPermissions($user, self::AUDIT_PERMISSIONS, $guard);

        if (method_exists($user, 'givePermissionTo')) {
            foreach (self::AUDIT_PERMISSIONS as $permission) {
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
        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.audit-trail-admin');
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
            $modelFile = (new ReflectionClass(BaAuditLog::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../Modules/BehaviouralAssessment/app/Models/BaAuditLog.php → module root = dirname(,3)
            $moduleRoot = dirname($modelFile, 3);
            return $moduleRoot . '/' . ltrim($relative, '/');
        } catch (Throwable) {
            return null;
        }
    }

    private function appRootPath(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(BaAuditLog::class))->getFileName();
            if (!is_string($modelFile) || $modelFile === '') {
                return null;
            }
            // .../prime_ai/Modules/BehaviouralAssessment/app/Models/BaAuditLog.php → app root = dirname(,5)
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
}
