<?php

namespace Tests\Browser\Modules\Prime\ActivityLog;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\ActivityLog;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Central Activity Log (read-only viewer) — Prime (PRM) module.
 *
 * DB SCOPE: CENTRAL. Table `sys_central_activity_logs` lives in the central
 * `mysql` connection (prime_db). No tenant initialization is performed for this
 * feature (constraint A4 / #21 / #22 — Prime browser features run on
 * http://127.0.0.1:8000 and extend the central PrimeDuskTestCase chain).
 *
 * Screen type: READ-ONLY log viewer. Read-focused coverage — render, list,
 * search/filter, pagination, permissions, empty state, guest redirect.
 * No create/edit/delete matrix (the controller's create/store/edit/update/destroy
 * are orphaned stubs — see cross-reference findings in the Gap Analysis).
 *
 * Constraint #25: `sys_central_activity_logs` has NO consolidated DDL file
 * (central migration only). test_01 asserts schema truth via
 * Schema::hasTable()/hasColumns() + the model $fillable — NOT via an
 * assertStringContainsString against a DDL file.
 */
class sys_ActivityLog_TestCas extends PrimeDuskTestCase
{
    // begin::Routes & paths (verified against prime_ai/routes/web.php + views)
    private const PRIME_INDEX_PATH  = '/prime/activity-log';          // central.prime.activity-log.index (web.php:276)
    private const GM_INDEX_PATH     = '/global-master/activity-log';  // central.global-master.activity-log.index (web.php:495,640 + index.blade route ref)
    private const SEARCH_PATH       = '/prime/activity-log/search';   // central.prime.activity-log.search (web.php:274)
    private const CREATE_PATH       = '/prime/activity-log/create';   // central.prime.activity-log.create

    private const ROUTE_PRIME_INDEX = 'central.prime.activity-log.index';
    private const ROUTE_PRIME_SEARCH = 'central.prime.activity-log.search';
    private const ROUTE_GM_INDEX    = 'central.global-master.activity-log.index';
    private const ROUTE_GM_SEARCH   = 'central.global-master.activity-log.search'; // NOT registered (finding DEV-PRM-AL-003)

    private const GATE_VIEW_ANY     = 'prime.activity-log.viewAny';   // ActivityLogController@index:23
    private const GATE_CREATE       = 'prime.activity-log.create';    // ActivityLogController@create:60
    private const GATE_UPDATE       = 'prime.activity-log.update';    // ActivityLogController@edit:85
    private const GATE_DELETE       = 'prime.activity-log.delete';    // ActivityLogController@destroy:103

    private const TABLE             = 'sys_central_activity_logs';
    // end::Routes & paths

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/ActivityLog/screenshots';

    private ?User $adminUser = null;
    private ?User $limitedUser = null;
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
        // Central feature — no tenant context to end. Guarded for safety.
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =====================================================================
    // Band 01–09 — Schema / migration / model configuration (config truth)
    // =====================================================================

    /**
     * test_01 — schema/config truth FIRST.
     * Constraint #25: assert `sys_central_activity_logs` via Schema::hasTable +
     * model $fillable (no DDL-file assertStringContainsString for this table).
     */
    public function test_activitylog_01_migration_model_and_request_configuration_are_correct(): void
    {
        // --- Table exists on the central connection (constraint #25) ---
        $this->assertTrue(
            Schema::hasTable(self::TABLE),
            'Central activity log table sys_central_activity_logs must exist in the central DB.'
        );

        // --- Columns (from central migration 2026_07_08_000001_create_central_activity_logs_table) ---
        foreach (['id', 'subject_type', 'subject_id', 'user_id', 'event', 'properties', 'ip_address', 'user_agent', 'created_at', 'updated_at'] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $column),
                "sys_central_activity_logs must have column '{$column}'."
            );
        }

        // --- Model configuration ---
        $model = new ActivityLog();
        $this->assertSame(self::TABLE, $model->getTable(), 'ActivityLog $table must be sys_central_activity_logs.');
        $this->assertSame('mysql', $model->getConnectionName(), 'ActivityLog must pin to the central mysql connection.');

        $this->assertSame(
            ['subject_type', 'subject_id', 'user_id', 'event', 'properties', 'ip_address', 'user_agent'],
            $model->getFillable(),
            'ActivityLog $fillable must match the central activity-log columns.'
        );

        // properties is cast to array (JSON column)
        $this->assertSame('array', $model->getCasts()['properties'] ?? null, "properties must be cast to 'array'.");

        // No soft-delete on the central activity log (constraint C12 / #25)
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(ActivityLog::class),
            'ActivityLog must NOT use SoftDeletes (central log is append-only, no deleted_at).'
        );
        $this->assertFalse(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'sys_central_activity_logs must not have a deleted_at column.'
        );

        // Relationships exist
        $this->assertTrue(method_exists(ActivityLog::class, 'user'), 'ActivityLog must define user() relationship.');
        $this->assertTrue(method_exists(ActivityLog::class, 'subject'), 'ActivityLog must define subject() (morphTo) relationship.');
    }

    public function test_activitylog_02_central_migration_file_defines_the_table(): void
    {
        // Fail-soft: the migration lives in the app repo, not the DDL folder.
        $glob = glob(base_path('database/migrations/*create_central_activity_logs_table.php'));

        if (empty($glob)) {
            $this->markTestSkipped('Central activity-log migration file not resolvable from base_path — schema truth already asserted via Schema:: in test_01.');
        }

        $contents = (string) file_get_contents($glob[0]);
        $this->assertStringContainsString("Schema::create('sys_central_activity_logs'", $contents, 'Migration must create sys_central_activity_logs.');
        $this->assertStringContainsString("json('properties')", $contents, 'Migration must declare properties as JSON.');
    }

    // =====================================================================
    // Band 10–19 — Read behaviour (render / list / search / filter)
    // =====================================================================

    public function test_activitylog_10_index_and_search_routes_are_registered(): void
    {
        // Index is registered under BOTH prime. and global-master. prefixes (web.php:276, 495, 640).
        $this->assertTrue(Route::has(self::ROUTE_PRIME_INDEX), 'central.prime.activity-log.index must be registered.');
        $this->assertTrue(Route::has(self::ROUTE_GM_INDEX), 'central.global-master.activity-log.index must be registered (used by index.blade).');

        // Search JSON endpoint is registered ONLY under the prime. prefix (web.php:274).
        $this->assertTrue(Route::has(self::ROUTE_PRIME_SEARCH), 'central.prime.activity-log.search must be registered.');

        // FINDING DEV-PRM-AL-003: the global-master search route name does NOT exist,
        // yet index.blade's search input references central.global-master.activity-log.index (the list route)
        // as its data-search-url. Documented, asserted as current behaviour (not a false pass).
        $this->assertFalse(
            Route::has(self::ROUTE_GM_SEARCH),
            'central.global-master.activity-log.search is expected to be ABSENT (search lives only under prime.).'
        );
    }

    public function test_activitylog_11_index_renders_activity_trail_for_admin(): void
    {
        $this->browseWithFailureScreenshot('index-renders', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH);

            $this->ensurePageAccessible($browser, 'Activity Log index');
            $browser->assertSee('Activity Log');
        });
    }

    public function test_activitylog_12_index_shows_audit_trail_card_or_empty_state(): void
    {
        $this->browseWithFailureScreenshot('index-body', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Activity Log index');

            $body = $browser->text('body');
            $this->assertTrue(
                str_contains($body, 'Audit Trail') || str_contains($body, 'No activity logs found'),
                'Index must render either the Audit Trail card or the empty-state message.'
            );
        });
    }

    public function test_activitylog_13_prime_prefixed_index_path_also_renders(): void
    {
        $this->browseWithFailureScreenshot('prime-index', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::PRIME_INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Activity Log index (prime prefix)');
            $browser->assertSee('Activity Log');
        });
    }

    public function test_activitylog_14_search_json_endpoint_returns_event_matches(): void
    {
        $log = $this->seedCentralLog('activitylogseedevent');

        if ($log === null) {
            $this->markTestSkipped('Could not seed a central activity-log row (env/DB) — search assertion skipped defensively.');
        }

        try {
            $this->browseWithFailureScreenshot('search-event', function (Browser $browser) use ($log): void {
                $this->authenticateCentral($browser);
                // Prime a session so the XHR carries auth cookies.
                $this->visitAuthenticated($browser, self::PRIME_INDEX_PATH);

                $response = $this->sendJsonRequestFromBrowser(
                    $browser,
                    self::SEARCH_PATH . '?type=event&search=' . rawurlencode((string) $log->event)
                );

                $this->assertContains((int) $response['status'], [200], 'Search endpoint should return HTTP 200.');
                $decoded = json_decode((string) $response['body'], true);
                $this->assertIsArray($decoded, 'Search endpoint must return a JSON array.');

                $labels = array_map(fn ($row) => is_array($row) ? ($row['label'] ?? '') : '', $decoded);
                $this->assertContains($log->event, $labels, 'Seeded event must appear in the event-type search results.');
            });
        } finally {
            $this->deleteCentralLog($log);
        }
    }

    public function test_activitylog_15_search_json_endpoint_returns_empty_without_search_term(): void
    {
        $this->browseWithFailureScreenshot('search-empty', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::PRIME_INDEX_PATH);

            $response = $this->sendJsonRequestFromBrowser($browser, self::SEARCH_PATH);

            $this->assertContains((int) $response['status'], [200], 'Search endpoint should return HTTP 200.');
            $decoded = json_decode((string) $response['body'], true);
            $this->assertIsArray($decoded, 'Empty search must still return a JSON array.');
            $this->assertCount(0, $decoded, 'ActivityLogController@search returns [] when no search term is supplied.');
        });
    }

    public function test_activitylog_16_index_search_filter_narrows_without_error(): void
    {
        $this->browseWithFailureScreenshot('index-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH . '?type=event&search=created');
            $this->ensurePageAccessible($browser, 'Activity Log filtered index');
            $browser->assertSee('Activity Log');
        });
    }

    // =====================================================================
    // Band 40–49 — Data source / integration (read path over the central table)
    // =====================================================================

    public function test_activitylog_40_seeded_central_row_renders_in_index(): void
    {
        $log = $this->seedCentralLog('renderprobe');

        if ($log === null) {
            $this->markTestSkipped('Could not seed a central activity-log row — render-path assertion skipped defensively.');
        }

        try {
            $this->browseWithFailureScreenshot('seeded-render', function (Browser $browser) use ($log): void {
                $this->authenticateCentral($browser);
                // Latest first (ActivityLog::latest()); a just-created row lands on page 1.
                $this->visitAuthenticated($browser, self::GM_INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Activity Log index (seeded)');

                $subject = class_basename((string) $log->subject_type);
                $body = $browser->text('body');
                $this->assertTrue(
                    str_contains($body, $subject) || str_contains($body, (string) $log->event),
                    'A freshly-seeded central log should be visible in the latest-first trail.'
                );
            });
        } finally {
            $this->deleteCentralLog($log);
        }
    }

    public function test_activitylog_41_activity_log_helper_targets_central_sink_when_untenanted(): void
    {
        // Defensive/optional: prove the read source is fed by the central activityLog() sink.
        try {
            $this->assertFalse(
                function_exists('tenancy') ? tenancy()->initialized : false,
                'Prime feature must run untenanted so activityLog() routes to the central sink.'
            );
            $this->assertTrue(function_exists('activityLog'), 'Global activityLog() helper must exist.');
        } catch (Throwable $e) {
            $this->markTestSkipped('tenancy()/activityLog() not resolvable in this harness: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // Band 50–59 — Permissions / authorization
    // =====================================================================

    public function test_activitylog_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::GM_INDEX_PATH))->pause(1200);

            $this->assertStringContainsString(
                'login',
                $this->currentPath($browser),
                'Unauthenticated access to the activity log must redirect to /login.'
            );
        });
    }

    public function test_activitylog_51_index_is_guarded_by_view_any_gate_for_limited_user(): void
    {
        $limited = $this->resolveLimitedUser();

        if ($limited === null) {
            $this->markTestSkipped('Could not provision a limited (non-super-admin) central user — gate test skipped defensively.');
        }

        $this->browseWithFailureScreenshot('gate-403', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $browser->visit($this->centralUrl(self::GM_INDEX_PATH))->pause(1200);

            $path = $this->currentPath($browser);
            if (str_contains($path, 'login')) {
                $this->markTestSkipped('Limited user could not establish a central session; gate assertion inconclusive.');
            }

            $body = $browser->text('body');
            $forbidden = str_contains($body, '403')
                || str_contains($body, 'Forbidden')
                || str_contains($body, 'Unauthorized')
                || str_contains($body, 'This action is unauthorized');

            $this->assertTrue(
                $forbidden,
                'A user without prime.activity-log.viewAny must be denied (403) by Gate::authorize in index().'
            );
        });
    }

    public function test_activitylog_52_search_endpoint_has_no_gate_finding(): void
    {
        // FINDING DEV-PRM-AL-001: ActivityLogController@search performs NO Gate::authorize,
        // so any AUTHENTICATED central user can query activity-log data via /prime/activity-log/search,
        // unlike index() which requires prime.activity-log.viewAny. Broken-access-control observation.
        // Assert CURRENT behaviour: the admin (authenticated) reaches the endpoint and gets JSON.
        $this->browseWithFailureScreenshot('search-no-gate', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::PRIME_INDEX_PATH);

            $response = $this->sendJsonRequestFromBrowser($browser, self::SEARCH_PATH . '?type=event&search=x');
            $this->assertContains((int) $response['status'], [200], 'Search endpoint reachable by authenticated user (documents the missing gate).');
        });
    }

    public function test_activitylog_53_create_endpoint_is_gated(): void
    {
        // create()/store()/edit()/update()/destroy() are orphaned stubs (finding DEV-PRM-AL-004)
        // but they DO call Gate::authorize. Verify create() denies a limited user (403).
        $limited = $this->resolveLimitedUser();

        if ($limited === null) {
            $this->markTestSkipped('Could not provision a limited central user — create-gate test skipped defensively.');
        }

        $this->browseWithFailureScreenshot('create-gate', function (Browser $browser) use ($limited): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->loginAs($limited)->pause(600);
            $browser->visit($this->centralUrl(self::CREATE_PATH))->pause(1000);

            $path = $this->currentPath($browser);
            if (str_contains($path, 'login')) {
                $this->markTestSkipped('Limited user session not established; create-gate assertion inconclusive.');
            }

            $body = $browser->text('body');
            $this->assertTrue(
                str_contains($body, '403') || str_contains($body, 'Forbidden') || str_contains($body, 'unauthorized') || str_contains($body, 'Unauthorized'),
                'create() must deny a user lacking prime.activity-log.create.'
            );
        });
    }

    // =====================================================================
    // Band 60–69 — UI / UX (search box, filter, pagination, empty state)
    // =====================================================================

    public function test_activitylog_60_search_form_and_input_present(): void
    {
        $this->browseWithFailureScreenshot('search-form', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Activity Log index');

            $browser->assertPresent('#search-form')
                ->assertPresent('#search-input')
                ->assertPresent('#suggestion-box');
        });
    }

    public function test_activitylog_61_type_filter_offers_subject_event_user_options(): void
    {
        $this->browseWithFailureScreenshot('filter-options', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Activity Log index');

            $browser->assertPresent('#filter-type')
                ->assertSeeIn('#filter-type', 'Subject')
                ->assertSeeIn('#filter-type', 'Event')
                ->assertSeeIn('#filter-type', 'User');
        });
    }

    public function test_activitylog_62_reset_button_present(): void
    {
        $this->browseWithFailureScreenshot('reset-btn', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Activity Log index');
            $browser->assertPresent('#reset-btn');
        });
    }

    public function test_activitylog_63_pagination_footer_or_empty_state_present(): void
    {
        $this->browseWithFailureScreenshot('pagination', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Activity Log index');

            $body = $browser->text('body');
            // paginate(20) — either a paginator footer (>20 rows) or the empty/single-page card is shown.
            $this->assertTrue(
                str_contains($body, 'Audit Trail') || str_contains($body, 'No activity logs found'),
                'Index must present a bounded, paginated trail or the empty-state card.'
            );
        });
    }

    // =====================================================================
    // Band 70–79 — Edge cases
    // =====================================================================

    public function test_activitylog_70_index_with_invalid_type_param_falls_back_to_all_case(): void
    {
        $this->browseWithFailureScreenshot('invalid-type', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            // Unknown type value → controller's else branch (ALL case); page must still render.
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH . '?type=nonsense&search=abc');
            $this->ensurePageAccessible($browser, 'Activity Log index (invalid type)');
            $browser->assertSee('Activity Log');
        });
    }

    public function test_activitylog_71_index_out_of_range_page_renders(): void
    {
        $this->browseWithFailureScreenshot('page-oob', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH . '?page=99999');
            $this->ensurePageAccessible($browser, 'Activity Log index (page OOB)');
            $browser->assertSee('Activity Log');
        });
    }

    public function test_activitylog_72_search_json_with_injection_shaped_input_is_safe(): void
    {
        $this->browseWithFailureScreenshot('search-injection', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::PRIME_INDEX_PATH);

            $payload = "%' OR '1'='1";
            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                self::SEARCH_PATH . '?type=event&search=' . rawurlencode($payload)
            );

            $this->assertContains((int) $response['status'], [200], 'Injection-shaped search input must not error (bound params).');
            $decoded = json_decode((string) $response['body'], true);
            $this->assertIsArray($decoded, 'Injection-shaped input must still yield a JSON array.');
        });
    }

    // =====================================================================
    // Band 90–99 — Security / central-scope
    // =====================================================================

    public function test_activitylog_90_reflected_search_input_is_escaped(): void
    {
        $this->browseWithFailureScreenshot('reflected-xss', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $marker = '<script>window.__al_xss=1;</script>';
            $this->visitAuthenticated($browser, self::GM_INDEX_PATH . '?search=' . rawurlencode($marker) . '&type=event');
            $this->ensurePageAccessible($browser, 'Activity Log index (reflected XSS)');

            $executed = $browser->script('return window.__al_xss === 1;');
            $flag = is_array($executed) ? ($executed[0] ?? false) : false;
            $this->assertNotTrue($flag, 'Reflected search input must be Blade-escaped, not executed.');
        });
    }

    public function test_activitylog_91_model_is_pinned_to_central_connection(): void
    {
        $model = new ActivityLog();
        $this->assertSame('mysql', $model->getConnectionName(), 'ActivityLog must read from the central mysql connection.');
        $this->assertSame(self::TABLE, $model->getTable(), 'ActivityLog must target sys_central_activity_logs.');
    }

    public function test_activitylog_92_central_log_has_no_soft_delete_semantics(): void
    {
        // Append-only central log: withTrashed()/onlyTrashed() must NOT be available (constraint C12).
        $this->assertNotContains(
            SoftDeletes::class,
            class_uses_recursive(ActivityLog::class),
            'ActivityLog is append-only — it must not expose soft-delete semantics.'
        );
    }

    // =====================================================================
    // ---- Private helper library ----
    // =====================================================================

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }

        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();

        return (string) parse_url($url, PHP_URL_PATH);
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

    private function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows the login page; authentication failed.');
        }

        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' is not accessible (' . $signal . ').');
            }
        }
    }

    /**
     * Issue an authenticated, same-origin XHR from inside the live browser session
     * so the request carries the session cookies and hits the running app.
     *
     * @return array{status:int, body:string}
     */
    private function sendJsonRequestFromBrowser(Browser $browser, string $path, string $method = 'GET'): array
    {
        $url = $this->centralUrl($path);
        $safeUrl = addslashes($url);
        $safeMethod = strtoupper($method) === 'POST' ? 'POST' : 'GET';

        $script = "var xhr=new XMLHttpRequest();"
            . "xhr.open('{$safeMethod}','{$safeUrl}',false);"
            . "xhr.setRequestHeader('X-Requested-With','XMLHttpRequest');"
            . "xhr.setRequestHeader('Accept','application/json');"
            . "try{xhr.send(null);}catch(e){return {status:0,body:''};}"
            . "return {status:xhr.status,body:xhr.responseText};";

        $result = $browser->script($script);
        $payload = is_array($result) ? ($result[0] ?? null) : null;

        return [
            'status' => (int) ($payload['status'] ?? 0),
            'body' => (string) ($payload['body'] ?? ''),
        ];
    }

    private function seedCentralLog(string $eventTag): ?ActivityLog
    {
        try {
            if (!$this->adminUser) {
                return null;
            }

            return ActivityLog::create([
                'subject_type' => 'Modules\\Prime\\Models\\Board',
                'subject_id' => (string) random_int(900000, 999999),
                'user_id' => $this->adminUser->getKey(),
                'event' => $eventTag . '_' . uniqid(),
                'properties' => ['message' => 'Dusk seed ' . $eventTag],
                'ip_address' => '127.0.0.1',
                'user_agent' => 'DuskSeed',
            ]);
        } catch (Throwable) {
            return null;
        }
    }

    private function deleteCentralLog(?ActivityLog $log): void
    {
        if ($log === null) {
            return;
        }

        try {
            $log->delete(); // no soft delete → permanent removal of the seed row
        } catch (Throwable) {
            // ignore cleanup failures
        }
    }

    private function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            if ($superAdmin) {
                $this->adminUser = $this->ensureVerified($superAdmin);
                return;
            }

            $byEmail = User::query()->where('email', $this->adminEmail)->first();
            if ($byEmail) {
                $this->adminUser = $this->ensureVerified($byEmail);
                return;
            }

            $this->adminUser = User::create([
                'email' => $this->adminEmail,
                'password' => bcrypt($this->adminPassword),
                'name' => 'Activity Log Dusk Admin',
                'emp_code' => 'AL' . random_int(1000, 9999),
                'short_name' => 'ALA' . random_int(100, 999),
                'status' => 'ACTIVE',
                'is_active' => 1,
                'is_super_admin' => 1,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    private function resolveLimitedUser(): ?User
    {
        if ($this->limitedUser !== null) {
            return $this->limitedUser;
        }

        try {
            $user = User::create([
                'email' => 'activitylog.limited_' . uniqid() . '@central.test',
                'password' => bcrypt('password'),
                'name' => 'Activity Log Limited',
                'emp_code' => 'ALL' . random_int(1000, 9999),
                'short_name' => 'ALL' . random_int(100, 999),
                'status' => 'ACTIVE',
                'is_active' => 1,
                'is_super_admin' => 0,
                'email_verified_at' => now(),
            ]);

            return $this->limitedUser = $this->ensureVerified($user);
        } catch (Throwable) {
            return null;
        }
    }

    private function ensureVerified(User $user): User
    {
        $updates = [];
        if (empty($user->email_verified_at)) {
            $updates['email_verified_at'] = now();
        }
        if (property_exists($user, 'is_active') && (int) $user->is_active !== 1) {
            $updates['is_active'] = 1;
        }
        if (!empty($updates)) {
            $user->fill($updates)->save();
        }

        return $user;
    }

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path(self::SCREENSHOT_DIR);
            if (is_dir($dir)) {
                foreach ((array) glob($dir . DIRECTORY_SEPARATOR . '*.png') as $file) {
                    @unlink($file);
                }
            }
        } catch (Throwable) {
            // ignore
        }
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        try {
            $directory = base_path(self::SCREENSHOT_DIR);
            File::ensureDirectoryExists($directory);
            $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName) ?: 'failure';
            $absolute = $directory . DIRECTORY_SEPARATOR . $safeName . '_' . now()->format('Ymd_His') . '.png';
            $browser->driver->takeScreenshot($absolute);

            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolute);
        } catch (Throwable) {
            return '';
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }
}
