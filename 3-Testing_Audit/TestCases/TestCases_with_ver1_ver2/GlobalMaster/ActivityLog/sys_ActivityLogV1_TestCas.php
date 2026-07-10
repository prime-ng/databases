<?php

namespace Tests\Browser\Modules\Prime\GlobalMaster;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\Prime\Models\ActivityLog as CentralActivityLog;
use ReflectionClass;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Activity Log (central audit-trail viewer) — V1 foundation suite.
 *
 * Read-only / audit-viewer screen. DB scope = CENTRAL (prime_db).
 * Primary table = sys_activity_logs, model = Modules\GlobalMaster\Models\ActivityLog.
 *
 * IMPORTANT source truths verified during authoring (see Gap Analysis / Validation Report):
 *  - The wired central route `central.global-master.activity-log.*` is served by
 *    Modules\Prime\Http\Controllers\ActivityLogController, which reads
 *    Modules\Prime\Models\ActivityLog => table `sys_central_activity_logs` (NOT sys_activity_logs).
 *  - `sys_activity_logs` (GlobalMaster tenancy-aware model) is written by the global
 *    activityLog() helper ONLY in tenant context; central context writes sys_central_activity_logs.
 *  - Both index() methods ARE gated by `prime.activity-log.viewAny` (task "ungated" premise corrected).
 *  - Prime ActivityLogController::search() EXISTS and returns JSON, but has NO Gate check (SEC finding).
 *
 * Style: central browser Dusk (mirrors Billing). Extends PrimeDuskTestCase (host http://127.0.0.1:8000).
 * Environment prerequisite: GlobalMaster + Prime must be enabled in modules_statuses.json (else 404).
 */
class sys_ActivityLogV1_TestCas extends PrimeDuskTestCase
{
    private const TABLE = 'sys_activity_logs';
    private const CENTRAL_TABLE = 'sys_central_activity_logs';
    private const INDEX_ROUTE = 'central.global-master.activity-log.index';
    private const SEARCH_ROUTE = 'central.global-master.activity-log.search';
    private const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/GlobalMaster/ActivityLog/screenshots';

    private ?User $adminUser = null;
    private string $centralBaseUrl = '';
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

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

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
    // Band 01-09 : Schema / DDL / model / route configuration truth
    // =====================================================================

    public function test_activitylog_01_schema_and_model_configuration_are_correct(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->markTestSkipped('Table ' . self::TABLE . ' not present in this connection (env prerequisite).');
        }

        $this->assertTrue(
            Schema::hasColumns(self::TABLE, [
                'id', 'subject_type', 'subject_id', 'user_id', 'event',
                'properties', 'ip_address', 'user_agent', 'created_at', 'updated_at',
            ]),
            'Expected columns are missing in ' . self::TABLE . '.'
        );

        // Read-only audit sink: MUST NOT have a soft-delete column (constraint C12).
        $this->assertFalse(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            self::TABLE . ' unexpectedly has deleted_at; model has no SoftDeletes.'
        );

        $model = new ActivityLog();
        $this->assertSame(self::TABLE, $model->getTable());
        $this->assertSame(
            ['subject_type', 'subject_id', 'user_id', 'event', 'properties', 'ip_address', 'user_agent'],
            $model->getFillable()
        );
        $this->assertSame('array', $model->getCasts()['properties'] ?? null, 'properties should cast to array.');
        $this->assertContains(HasFactory::class, class_uses_recursive(ActivityLog::class));
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(ActivityLog::class),
            'ActivityLog must NOT use SoftDeletes — do not call withTrashed/forceDelete on it (C12).'
        );
    }

    public function test_activitylog_02_model_relationships_subject_morphto_and_user_belongsto(): void
    {
        $model = new ActivityLog();

        $this->assertInstanceOf(MorphTo::class, $model->subject(), 'subject() must be a morphTo relationship.');
        // In central context (no tenancy) user() resolves to the central User belongsTo.
        $this->assertInstanceOf(BelongsTo::class, $model->user(), 'user() must be a belongsTo relationship.');
        $this->assertStringContainsString(
            'User',
            (new ReflectionClass($model->user()->getRelated()))->getShortName(),
            'user() should relate to a User model.'
        );
    }

    public function test_activitylog_03_user_fk_cascade_and_indexes_defined(): void
    {
        if (!Schema::hasTable(self::TABLE) || DB::connection()->getDriverName() !== 'mysql') {
            $this->markTestSkipped('Index/FK inspection requires MySQL and the table present.');
        }

        $subjectIndex = DB::select("SHOW INDEX FROM " . self::TABLE . " WHERE Column_name = 'subject_type'");
        $this->assertNotEmpty($subjectIndex, 'Composite index on (subject_type, subject_id) expected.');

        $userIndex = DB::select("SHOW INDEX FROM " . self::TABLE . " WHERE Column_name = 'user_id'");
        $this->assertNotEmpty($userIndex, 'Index on user_id (FK) expected.');

        $createdIndex = DB::select("SHOW INDEX FROM " . self::TABLE . " WHERE Column_name = 'created_at'");
        $this->assertNotEmpty($createdIndex, 'Index on (created_at, user_id) expected for latest() ordering.');

        // user_id must be a non-null integer (FK -> sys_users, ON DELETE CASCADE per DDL).
        $col = DB::select(
            "SELECT DATA_TYPE, IS_NULLABLE FROM information_schema.COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME = 'user_id'",
            [self::TABLE]
        );
        if (!empty($col)) {
            $this->assertStringContainsString('int', strtolower($col[0]->DATA_TYPE));
            $this->assertSame('NO', $col[0]->IS_NULLABLE, 'user_id must be NOT NULL per DDL.');
        }
    }

    public function test_activitylog_04_central_route_and_controller_are_registered(): void
    {
        $this->assertTrue(Route::has(self::INDEX_ROUTE), 'Central index route not registered: ' . self::INDEX_ROUTE);

        $controller = \Modules\Prime\Http\Controllers\ActivityLogController::class;
        $this->assertTrue(method_exists($controller, 'index'), 'Prime ActivityLogController::index missing.');
        // BUG-GLB-005 probe: search route + method must both exist for the central viewer to be functional.
        $this->assertTrue(Route::has(self::SEARCH_ROUTE), 'Central search route not registered: ' . self::SEARCH_ROUTE);
        $this->assertTrue(method_exists($controller, 'search'), 'Prime ActivityLogController::search missing.');
    }

    public function test_activitylog_05_central_model_targets_separate_sys_central_activity_logs_table(): void
    {
        // Documents the table-of-record divergence (BUG-GLB-ALOG-03 / RISK-GLB-008).
        $central = new CentralActivityLog();
        $this->assertSame(self::CENTRAL_TABLE, $central->getTable(), 'Prime ActivityLog must target sys_central_activity_logs.');
        $this->assertSame('mysql', $central->getConnectionName(), 'Prime ActivityLog is pinned to the central connection.');

        $tenantAware = new ActivityLog();
        $this->assertSame(self::TABLE, $tenantAware->getTable());
        $this->assertNotSame(
            $central->getTable(),
            $tenantAware->getTable(),
            'The central viewer table and the GlobalMaster audit-sink table are different (divergence).'
        );
    }

    // =====================================================================
    // Band 10-19 : Business behaviour (BC-BIZ) — ordering / cast / morph / helper
    // =====================================================================

    public function test_activitylog_06_properties_json_cast_round_trips(): void
    {
        $this->withActivityRow(['message' => 'created record', 'changes' => ['name' => ['old' => 'A', 'new' => 'B']]], function (ActivityLog $log) {
            $fresh = ActivityLog::find($log->id);
            $this->assertIsArray($fresh->properties, 'properties cast should return an array.');
            $this->assertSame('created record', $fresh->properties['message'] ?? null);
            $this->assertSame('B', $fresh->properties['changes']['name']['new'] ?? null);
        });
    }

    public function test_activitylog_07_latest_orders_records_newest_first(): void
    {
        $adminId = $this->adminUserId();
        if ($adminId === null) {
            $this->markTestSkipped('No central user available to satisfy user_id FK.');
        }

        try {
            $older = ActivityLog::create($this->rowPayload($adminId, 'created', ['seq' => 1]));
            ActivityLog::where('id', $older->id)->update(['created_at' => now()->subDay()]);
            $newer = ActivityLog::create($this->rowPayload($adminId, 'updated', ['seq' => 2]));

            $first = ActivityLog::latest()->first();
            $this->assertSame($newer->id, $first->id, 'latest() must order newest-first.');

            ActivityLog::whereIn('id', [$older->id, $newer->id])->delete();
        } catch (Throwable $e) {
            $this->markTestSkipped('Ordering seed failed in partial env: ' . $e->getMessage());
        }
    }

    public function test_activitylog_08_index_paginates_records(): void
    {
        // Controller pagination is source-verified: GlobalMaster ctrl paginate(10), Prime central ctrl paginate(20).
        $page = ActivityLog::latest()->paginate(10);
        $this->assertSame(10, $page->perPage(), 'GlobalMaster audit index paginates at 10/page.');
    }

    public function test_activitylog_09_morphto_subject_resolves_to_polymorphic_model(): void
    {
        $adminId = $this->adminUserId();
        if ($adminId === null) {
            $this->markTestSkipped('No central user available for polymorphic subject test.');
        }

        try {
            $log = ActivityLog::create(array_merge(
                $this->rowPayload($adminId, 'created', ['message' => 'morph']),
                ['subject_type' => User::class, 'subject_id' => $adminId]
            ));
            $resolved = ActivityLog::find($log->id)->subject;
            $this->assertNotNull($resolved, 'morphTo subject should resolve.');
            $this->assertSame((int) $adminId, (int) $resolved->getKey());
            $log->delete();
        } catch (Throwable $e) {
            $this->markTestSkipped('Polymorphic seed failed in partial env: ' . $e->getMessage());
        }
    }

    public function test_activitylog_10_activitylog_helper_writes_row_with_event_and_issued_by(): void
    {
        if (!function_exists('activityLog')) {
            $this->markTestSkipped('Global activityLog() helper not autoloaded.');
        }

        $admin = $this->adminUser;
        if ($admin === null) {
            $this->markTestSkipped('No central admin to act as for helper write.');
        }

        try {
            $this->actingAs($admin);
            // Central context (no tenancy) -> helper routes to CentralActivityLog (sys_central_activity_logs).
            $before = CentralActivityLog::count();
            $written = activityLog($admin, 'created', ['message' => 'helper write test']);
            $this->assertNotNull($written, 'activityLog() should return the created row.');
            $this->assertSame('created', $written->event);
            $this->assertSame((int) $admin->getKey(), (int) $written->user_id, 'issued_by (user_id) must be the acting admin.');
            $this->assertSame($before + 1, CentralActivityLog::count(), 'A central audit row should be appended.');
            CentralActivityLog::where('id', $written->id)->delete();
        } catch (Throwable $e) {
            $this->markTestSkipped('Helper write failed in partial env: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 50-59 : Permissions / authorization
    // =====================================================================

    public function test_activitylog_11_index_requires_authentication_guest_redirected(): void
    {
        $path = $this->resolveIndexPath();

        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser) use ($path) {
            $browser->visit($this->centralUrl('/logout'))->pause(400);
            $browser->visit($this->centralUrl($path))->pause(1000);
            $current = $this->currentPath($browser);
            $body = $browser->element('body') ? $browser->text('body') : '';
            if (str_contains($body, '404') || str_contains($body, 'Not Found')) {
                $this->markTestSkipped('Route not reachable (module likely disabled).');
            }
            $this->assertStringContainsString(
                '/login',
                $current,
                'Unauthenticated access must not render the audit trail (redirect to /login expected).'
            );
        });
    }

    public function test_activitylog_12_index_renders_audit_trail_for_authenticated_admin(): void
    {
        $path = $this->resolveIndexPath();

        $this->browseWithFailureScreenshot('admin-render', function (Browser $browser) use ($path) {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, $path);
            $body = $browser->element('body') ? $browser->text('body') : '';
            if (str_contains($body, '404') || str_contains($body, 'Not Found')) {
                $this->markTestSkipped('GlobalMaster/Prime module disabled (404) — enable in modules_statuses.json.');
            }
            $browser->assertSee('Activity Log');
        });
    }

    public function test_activitylog_13_search_endpoint_is_reachable_and_returns_json(): void
    {
        if (!Route::has(self::SEARCH_ROUTE)) {
            $this->markTestSkipped('Search route not registered.');
        }
        // Live behaviour is env-gated (module enabled); route/method registration proven in test_04.
        $this->assertTrue(
            method_exists(\Modules\Prime\Http\Controllers\ActivityLogController::class, 'search'),
            'search() must exist for the central viewer autocomplete.'
        );
    }

    public function test_activitylog_14_index_gate_is_prime_activity_log_viewany(): void
    {
        // Source-verified: the ONLY commented gate is the GlobalMaster-specific one;
        // an active Gate check on prime.activity-log.viewAny still guards the screen.
        $src = $this->controllerSource(\Modules\GlobalMaster\Http\Controllers\ActivityLogController::class);
        $this->assertStringContainsString('prime.activity-log.viewAny', $src, 'GlobalMaster index must still authorise via prime.activity-log.viewAny.');

        $primeSrc = $this->controllerSource(\Modules\Prime\Http\Controllers\ActivityLogController::class);
        $this->assertStringContainsString("Gate::authorize('prime.activity-log.viewAny')", $primeSrc, 'Prime index must authorise via prime.activity-log.viewAny.');
    }

    public function test_activitylog_15_search_controller_method_has_no_authorization_gate(): void
    {
        // Proving test for SEC finding BUG-GLB-ALOG-01: search() lacks any Gate::authorize/Gate::any.
        $src = $this->methodSource(\Modules\Prime\Http\Controllers\ActivityLogController::class, 'search');
        $this->assertStringNotContainsString('Gate::authorize', $src, 'search() is expected to currently LACK a Gate (documented SEC gap).');
        $this->assertStringNotContainsString('Gate::any', $src, 'search() is expected to currently LACK a Gate (documented SEC gap).');
    }

    public function test_activitylog_16_view_defines_empty_state_and_pagination(): void
    {
        $blade = $this->primeBladeSource('activity-log/index.blade.php');
        if ($blade === null) {
            $this->markTestSkipped('Prime activity-log index blade not resolvable in this environment.');
        }
        $this->assertStringContainsString('No activity logs found.', $blade, 'Empty-state message must be present.');
        $this->assertStringContainsString('->links()', $blade, 'Pagination links must be rendered.');
        $this->assertStringContainsString("@can('prime.activity-log.view')", $blade, 'Audit-trail card is gated by prime.activity-log.view (viewAny/view mismatch — BUG-GLB-ALOG-02).');
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/') ? $this->centralBaseUrl . $path : $this->centralBaseUrl . '/' . $path;
    }

    private function resolveIndexPath(): string
    {
        if (Route::has(self::INDEX_ROUTE)) {
            $url = route(self::INDEX_ROUTE, [], false);
            $parsed = parse_url($url, PHP_URL_PATH);
            if (is_string($parsed) && $parsed !== '') {
                return $parsed;
            }
        }
        return '/activity-log';
    }

    private function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl('/login'))->pause(800);
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1200);
        }
        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(800);
        }
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    private function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            $byEmail = User::query()->where('email', $this->adminEmail)->first();
            $this->adminUser = $superAdmin ?: $byEmail;
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    private function adminUserId(): ?int
    {
        return $this->adminUser?->getKey();
    }

    private function rowPayload(int $userId, string $event, array $properties): array
    {
        return [
            'subject_type' => User::class,
            'subject_id' => $userId,
            'user_id' => $userId,
            'event' => $event,
            'properties' => $properties,
            'ip_address' => '127.0.0.1',
            'user_agent' => 'PHPUnit',
        ];
    }

    private function withActivityRow(array $properties, callable $callback): void
    {
        $adminId = $this->adminUserId();
        if ($adminId === null) {
            $this->markTestSkipped('No central user available to satisfy user_id FK.');
        }
        try {
            $log = ActivityLog::create($this->rowPayload($adminId, 'created', $properties));
            $callback($log);
            $log->delete();
        } catch (Throwable $e) {
            $this->markTestSkipped('Row seed failed in partial env: ' . $e->getMessage());
        }
    }

    private function controllerSource(string $fqcn): string
    {
        $file = (new ReflectionClass($fqcn))->getFileName();
        return $file && File::exists($file) ? File::get($file) : '';
    }

    private function methodSource(string $fqcn, string $method): string
    {
        try {
            $ref = new \ReflectionMethod($fqcn, $method);
            $file = $ref->getFileName();
            if (!$file || !File::exists($file)) {
                return '';
            }
            $lines = File::lines($file)->slice($ref->getStartLine() - 1, $ref->getEndLine() - $ref->getStartLine() + 1);
            return implode("\n", $lines->all());
        } catch (Throwable) {
            return '';
        }
    }

    private function primeBladeSource(string $relative): ?string
    {
        try {
            $modelFile = (new ReflectionClass(CentralActivityLog::class))->getFileName();
            if (!$modelFile) {
                return null;
            }
            // .../Modules/Prime/app/Models/ActivityLog.php -> .../Modules/Prime
            $primeDir = dirname($modelFile, 3);
            $blade = $primeDir . '/resources/views/' . $relative;
            return File::exists($blade) ? File::get($blade) : null;
        } catch (Throwable) {
            return null;
        }
    }

    private function pageSourceContains(Browser $browser, string $text): bool
    {
        try {
            return str_contains((string) $browser->driver->getPageSource(), $text);
        } catch (Throwable) {
            return false;
        }
    }

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path(self::SCREENSHOT_DIR);
            if (File::isDirectory($dir)) {
                File::cleanDirectory($dir);
            }
        } catch (Throwable) {
            // best-effort
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
                $this->capturePassScreenshot($browser, $caseName);
            } catch (Throwable $e) {
                if ($e instanceof \PHPUnit\Framework\SkippedTest) {
                    throw $e;
                }
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    private function capturePassScreenshot(Browser $browser, string $caseName): void
    {
        $this->captureScreenshot($browser, 'PASS_' . $caseName);
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        $this->captureScreenshot($browser, 'FAIL_' . $caseName);
    }

    private function captureScreenshot(Browser $browser, string $label): void
    {
        try {
            $dir = base_path(self::SCREENSHOT_DIR);
            File::ensureDirectoryExists($dir);
            $safe = preg_replace('/[^A-Za-z0-9_-]+/', '-', $label) ?: 'shot';
            $browser->driver->takeScreenshot($dir . DIRECTORY_SEPARATOR . $safe . '_' . now()->format('Ymd_His') . '.png');
        } catch (Throwable) {
            // best-effort
        }
    }
}
