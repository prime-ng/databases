<?php

namespace Tests\Browser\Modules\Prime\Notification;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Prime (PRM) module — Notification feature (central Laravel notifications).
 *
 * Screen type: Laravel database notifications (morph `notifications` table, NOT a
 * domain table). Read/action-focused suite: list (all-notifications) with all/unread/
 * read filters, mark-as-read, mark-all-read, destroy, and the debug test-notification
 * route — plus permission gates, guest redirect, ownership/IDOR scoping, and config truth.
 *
 * DB scope: CENTRAL (prime_db). No tenant initialisation. Host http://127.0.0.1:8000.
 * Extends the committed Prime base (PrimeDuskTestCase); central auth/helpers implemented
 * locally (mirrored from prm_BillingDuskTestCase_TestCas). Constraint #21, #22.
 *
 * All routes/gates/methods/selectors below were read from real source on 2026-Jul-10:
 *   - Modules/Prime/app/Http/Controllers/NotificationController.php
 *   - routes/web.php (central. -> dashboard. group)
 *   - Modules/Prime/resources/views/notification/index.blade.php
 *   - Modules/Notification/app/Policies/PrimeNotificationPolicy.php
 *   - app/Providers/AppServiceProvider.php (Gate::define / Gate::before)
 *   - database/migrations/2025_12_31_045403_create_notifications_table.php
 *   - app/Notifications/TestNotification.php
 *
 * Documented source findings proven by this suite:
 *   - SEC-PRM-002 (brief) is REFUTED: the test-notification route IS environment-guarded
 *     at registration (`if (app()->environment(['local','staging','testing']))`).
 *     Residual defense-in-depth gap: the controller method has no internal env check
 *     (test_80/test_82).
 *   - DEV-PRM-NTF-001: destroy() calls Gate::authorize('prime.notification.delete') but
 *     that ability is never Gate::define'd and the policy has no delete() method — only
 *     the super-admin Gate::before bypass permits deletion (test_52).
 *   - DEV-PRM-NTF-002: TestNotification ignores its constructor $user argument and picks
 *     User::inRandomOrder()->first() for the message body (test_13).
 */
class prm_Notification_TestCas extends PrimeDuskTestCase
{
    // ---- Routes (verified) ----
    private const INDEX_PATH        = '/dashboard/all-notifications';
    private const TEST_NOTIF_PATH   = '/dashboard/test-notification';
    private const MARK_ALL_PATH     = '/dashboard/notifications/mark-all-read';

    private const ROUTE_INDEX       = 'central.dashboard.all-notifications';
    private const ROUTE_MARK_READ   = 'central.dashboard.notification.markAsRead';
    private const ROUTE_MARK_ALL    = 'central.dashboard.notification.markAllAsRead';
    private const ROUTE_DESTROY     = 'central.dashboard.notification.destroy';
    private const ROUTE_TEST_NOTIF  = 'central.dashboard.test-notification';

    // ---- Gates (verified) ----
    private const GATE_VIEW_ANY     = 'prime.notification.viewAny';
    private const GATE_CREATE       = 'prime.notification.create';
    private const GATE_DELETE       = 'prime.notification.delete'; // referenced but NOT defined

    // ---- Source files ----
    private const CONTROLLER_FILE   = 'Modules/Prime/app/Http/Controllers/NotificationController.php';
    private const ROUTES_FILE       = 'routes/web.php';
    private const VIEW_FILE         = 'Modules/Prime/resources/views/notification/index.blade.php';
    private const POLICY_FILE       = 'Modules/Notification/app/Policies/PrimeNotificationPolicy.php';
    private const MIGRATION_FILE    = 'database/migrations/2025_12_31_045403_create_notifications_table.php';
    private const NOTIFICATION_FILE = 'app/Notifications/TestNotification.php';

    private const CONTROLLER_CLASS  = \Modules\Prime\Http\Controllers\NotificationController::class;
    private const POLICY_CLASS      = \Modules\Notification\Policies\PrimeNotificationPolicy::class;

    // ---- Report/screenshot output ----
    protected const SCREENSHOT_DIR        = 'tests/Browser/Modules/Prime/Notification/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Notification/report';
    protected const STATUS_REPORT_PREFIX  = 'prime_notification_report_';

    protected ?User $adminUser = null;
    protected string $centralBaseUrl = '';
    protected string $adminEmail = '';
    protected string $adminPassword = '';
    protected array $statusReportEntries = [];
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp(); // PrimeDuskTestCase asserts host is 127.0.0.1

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->statusReportEntries = [];

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (!empty($this->statusReportEntries)) {
            $this->writeStatusReportForCurrentTest();
        }

        parent::tearDown();
    }

    // ================================================================
    // 01–09  Config / schema / model / policy truth (in-process)
    // ================================================================

    /**
     * test_01 — MASTER config truth: routes, gates, controller methods, and the
     * central `notifications` morph table shape are all as expected.
     * TC-P01 / BC-DB / BC-AUTH / Screen-config.
     */
    public function test_notification_01_routes_gates_methods_and_notifications_table_configuration_are_correct(): void
    {
        // --- Route registration (names) ---
        $this->assertTrue(Route::has(self::ROUTE_INDEX), 'Route ' . self::ROUTE_INDEX . ' is not registered.');
        $this->assertTrue(Route::has(self::ROUTE_MARK_READ), 'Route ' . self::ROUTE_MARK_READ . ' is not registered.');
        $this->assertTrue(Route::has(self::ROUTE_MARK_ALL), 'Route ' . self::ROUTE_MARK_ALL . ' is not registered.');
        $this->assertTrue(Route::has(self::ROUTE_DESTROY), 'Route ' . self::ROUTE_DESTROY . ' is not registered.');
        // test-notification only registered in local/staging/testing — under APP_ENV=testing it exists.
        $this->assertTrue(Route::has(self::ROUTE_TEST_NOTIF), 'Route ' . self::ROUTE_TEST_NOTIF . ' should be registered under the testing environment.');

        // --- Route verbs / URIs ---
        $index = Route::getRoutes()->getByName(self::ROUTE_INDEX);
        $this->assertNotNull($index);
        $this->assertContains('GET', $index->methods());
        $this->assertSame('dashboard/all-notifications', $index->uri());

        $markRead = Route::getRoutes()->getByName(self::ROUTE_MARK_READ);
        $this->assertContains('POST', $markRead->methods());
        $this->assertSame('dashboard/notifications/{id}/read', $markRead->uri());

        $markAll = Route::getRoutes()->getByName(self::ROUTE_MARK_ALL);
        $this->assertContains('POST', $markAll->methods());
        $this->assertSame('dashboard/notifications/mark-all-read', $markAll->uri());

        $destroy = Route::getRoutes()->getByName(self::ROUTE_DESTROY);
        $this->assertContains('DELETE', $destroy->methods());
        $this->assertSame('dashboard/notifications/{id}', $destroy->uri());

        // --- Gates: viewAny + create defined; delete NOT defined (DEV-PRM-NTF-001) ---
        $this->assertTrue(Gate::has(self::GATE_VIEW_ANY), 'Gate ' . self::GATE_VIEW_ANY . ' must be defined.');
        $this->assertTrue(Gate::has(self::GATE_CREATE), 'Gate ' . self::GATE_CREATE . ' must be defined.');
        $this->assertFalse(Gate::has(self::GATE_DELETE), 'Current source: ' . self::GATE_DELETE . ' is referenced by destroy() but NOT defined (DEV-PRM-NTF-001).');

        // --- Controller methods exist ---
        foreach (['allNotifications', 'markAsRead', 'markAllAsRead', 'destroy', 'testNotification'] as $method) {
            $this->assertTrue(method_exists(self::CONTROLLER_CLASS, $method), "Controller missing method {$method}.");
        }

        // --- Central `notifications` morph table shape ---
        $this->assertTrue(Schema::hasTable('notifications'), 'Central notifications table missing.');
        $this->assertTrue(
            Schema::hasColumns('notifications', ['id', 'type', 'notifiable_type', 'notifiable_id', 'data', 'read_at', 'created_at', 'updated_at']),
            'notifications table is missing expected morph/data columns.'
        );
    }

    /** test_02 — Controller method signatures / return types (reflection). BC-BIZ. */
    public function test_notification_02_controller_method_signatures_are_correct(): void
    {
        $ref = new \ReflectionClass(self::CONTROLLER_CLASS);

        $markAsRead = $ref->getMethod('markAsRead');
        $this->assertSame('id', $markAsRead->getParameters()[0]->getName());
        $this->assertSame('Illuminate\\Http\\JsonResponse', (string) $markAsRead->getReturnType());

        $destroy = $ref->getMethod('destroy');
        $this->assertSame('id', $destroy->getParameters()[0]->getName());
        $this->assertSame('Illuminate\\Http\\JsonResponse', (string) $destroy->getReturnType());

        $markAll = $ref->getMethod('markAllAsRead');
        $this->assertSame('Illuminate\\Http\\JsonResponse', (string) $markAll->getReturnType());
    }

    /** test_03 — notifications table column types (UUID PK + morph + text). BC-DB. */
    public function test_notification_03_notifications_table_column_types_are_polymorphic(): void
    {
        $idType = strtolower((string) Schema::getColumnType('notifications', 'id'));
        // MySQL 8 reports char(36); constraint #17 — assert contains, not equals.
        $this->assertTrue(
            str_contains($idType, 'char') || str_contains($idType, 'string') || str_contains($idType, 'uuid'),
            "Expected UUID-style id column, got '{$idType}'."
        );

        $this->assertTrue(Schema::hasColumn('notifications', 'notifiable_type'), 'notifiable_type morph column missing.');
        $this->assertTrue(Schema::hasColumn('notifications', 'notifiable_id'), 'notifiable_id morph column missing.');
    }

    /** test_04 — Migration file defines uuid primary, morphs, text data, nullable read_at. BC-DB. */
    public function test_notification_04_migration_defines_uuid_morph_and_nullable_read_at(): void
    {
        $src = $this->readSource(self::MIGRATION_FILE);
        $this->assertStringContainsString("Schema::create('notifications'", $src);
        $this->assertStringContainsString("uuid('id')->primary()", $src);
        $this->assertStringContainsString("morphs('notifiable')", $src);
        $this->assertStringContainsString("text('data')", $src);
        $this->assertStringContainsString("timestamp('read_at')->nullable()", $src);
    }

    /** test_05 — Policy defines viewAny + create delegating to tenant.notification.* permissions. BC-AUTH. */
    public function test_notification_05_policy_delegates_to_tenant_notification_permissions(): void
    {
        $this->assertTrue(method_exists(self::POLICY_CLASS, 'viewAny'), 'Policy missing viewAny().');
        $this->assertTrue(method_exists(self::POLICY_CLASS, 'create'), 'Policy missing create().');
        // Proven gap for DEV-PRM-NTF-001: policy has NO delete() method.
        $this->assertFalse(method_exists(self::POLICY_CLASS, 'delete'), 'Current source: policy has no delete() method (DEV-PRM-NTF-001).');

        $src = $this->readSource(self::POLICY_FILE);
        $this->assertStringContainsString("can('tenant.notification.viewAny')", $src);
        $this->assertStringContainsString("can('tenant.notification.create')", $src);
    }

    // ================================================================
    // 10–19  Business rules (BC-BIZ)
    // ================================================================

    /** test_10 — allNotifications filters on all/unread/read via the `filter` input. BC-BIZ (Screen-BR). */
    public function test_notification_10_allnotifications_supports_all_unread_read_filters(): void
    {
        $src = $this->readSource(self::CONTROLLER_FILE);
        $this->assertStringContainsString("\$filter = \$request->input('filter', 'all')", $src);
        $this->assertStringContainsString("if (\$filter === 'unread')", $src);
        $this->assertStringContainsString("elseif (\$filter === 'read')", $src);
        $this->assertStringContainsString('unreadNotifications()', $src);
        $this->assertStringContainsString('readNotifications()', $src);
        $this->assertStringContainsString('paginate(20)', $src);
        $this->assertStringContainsString("view('prime::notification.index'", $src);
    }

    /** test_11 — markAsRead/markAllAsRead scope to the authenticated user's own relation. BC-BIZ. */
    public function test_notification_11_mark_read_actions_are_scoped_to_current_user(): void
    {
        $src = $this->readSource(self::CONTROLLER_FILE);
        $this->assertStringContainsString('auth()->user()->notifications()->findOrFail($id)', $src);
        $this->assertStringContainsString('auth()->user()->unreadNotifications->markAsRead()', $src);
        // Both JSON responses return the recomputed unreadCount.
        $this->assertStringContainsString("'unreadCount' => auth()->user()->unreadNotifications()->count()", $src);
    }

    /** test_12 — Blade view references the exact central route names + fetch endpoints. BC-BIZ / BC-REF. */
    public function test_notification_12_view_uses_correct_route_names_and_endpoints(): void
    {
        $src = $this->readSource(self::VIEW_FILE);
        $this->assertStringContainsString("route('central.dashboard.all-notifications'", $src);
        $this->assertStringContainsString("route('central.dashboard.notification.markAllAsRead')", $src);
        $this->assertStringContainsString("url('dashboard/notifications')", $src);
        // Action selectors used by the JS + our browser flows.
        $this->assertStringContainsString('mark-read-btn', $src);
        $this->assertStringContainsString('delete-notif-btn', $src);
        $this->assertStringContainsString('mark-all-read-btn', $src);
    }

    /** test_13 — DEV-PRM-NTF-002: TestNotification ignores its ctor arg, picks a random user. BC-BIZ. */
    public function test_notification_13_test_notification_ignores_constructor_argument(): void
    {
        $src = $this->readSource(self::NOTIFICATION_FILE);
        // The passed-in user is commented out; a random user is chosen instead.
        $this->assertStringContainsString('//$this->user = $user;', $src);
        $this->assertStringContainsString('User::inRandomOrder()->first()', $src);
        $this->assertStringContainsString("'database'", $src); // via() database channel
        $this->assertStringContainsString("route('central.dashboard.all-notifications')", $src);
    }

    // ================================================================
    // 30–39  Validation / negative (auth boundary)
    // ================================================================

    /** test_30 — Guest is redirected to /login from the notifications index. TC-N / BC-AUTH. */
    public function test_notification_30_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);

            $this->assertStringContainsString(
                '/login',
                $this->currentPath($browser),
                'Guest should be redirected to /login from the notifications page.'
            );
        });
    }

    /** test_31 — Every notification route sits behind auth (+ verified) middleware. TC-N / BC-AUTH. */
    public function test_notification_31_all_routes_require_auth_and_verified_middleware(): void
    {
        foreach ([self::ROUTE_INDEX, self::ROUTE_MARK_READ, self::ROUTE_MARK_ALL, self::ROUTE_DESTROY, self::ROUTE_TEST_NOTIF] as $name) {
            $route = Route::getRoutes()->getByName($name);
            $this->assertNotNull($route, "Route {$name} not found.");
            $mw = $route->gatherMiddleware();
            $this->assertContains('auth', $mw, "Route {$name} is missing auth middleware.");
            $this->assertContains('verified', $mw, "Route {$name} is missing verified middleware.");
        }
    }

    // ================================================================
    // 40–49  Integration / polymorphic linkage (BC-INT / BC-REF)
    // ================================================================

    /** test_40 — notifications is a polymorphic sink (morph columns present). BC-REF. */
    public function test_notification_40_notifiable_morph_columns_present(): void
    {
        $this->assertTrue(Schema::hasColumn('notifications', 'notifiable_type'));
        $this->assertTrue(Schema::hasColumn('notifications', 'notifiable_id'));
        $this->assertTrue(Schema::hasColumn('notifications', 'read_at'));
    }

    /** test_41 — The resolved user model exposes Notifiable relations the controller uses. BC-INT. */
    public function test_notification_41_user_model_exposes_notifiable_relations(): void
    {
        $this->assertTrue(method_exists(User::class, 'notifications'), 'User model must expose notifications() (Notifiable).');
        $this->assertTrue(method_exists(User::class, 'unreadNotifications'), 'User model must expose unreadNotifications().');
        $this->assertTrue(method_exists(User::class, 'readNotifications'), 'User model must expose readNotifications().');
    }

    // ================================================================
    // 50–59  Permissions / authorization (BC-AUTH)
    // ================================================================

    /** test_50 — allNotifications is gated prime.notification.viewAny. BC-AUTH (Screen-PM). */
    public function test_notification_50_allnotifications_gated_prime_notification_viewany(): void
    {
        $src = $this->controllerMethodBody('allNotifications');
        $this->assertStringContainsString("Gate::authorize('prime.notification.viewAny')", $src);
    }

    /** test_51 — testNotification is gated prime.notification.create. BC-AUTH (Screen-PM). */
    public function test_notification_51_testnotification_gated_prime_notification_create(): void
    {
        $src = $this->controllerMethodBody('testNotification');
        $this->assertStringContainsString("Gate::authorize('prime.notification.create')", $src);
    }

    /**
     * test_52 — DEV-PRM-NTF-001: destroy() authorizes an UNDEFINED ability.
     * The controller calls Gate::authorize('prime.notification.delete') but that ability
     * is neither Gate::define'd nor backed by a policy method — so only the super-admin
     * Gate::before bypass permits deletion. Proves current behaviour.
     * BC-AUTH / TC-S.
     */
    public function test_notification_52_destroy_references_undefined_delete_ability(): void
    {
        $src = $this->controllerMethodBody('destroy');
        $this->assertStringContainsString("Gate::authorize('prime.notification.delete')", $src);

        // The ability is not registered anywhere -> Gate::has is false.
        $this->assertFalse(Gate::has(self::GATE_DELETE), 'prime.notification.delete unexpectedly defined; DEV-PRM-NTF-001 may be resolved.');
        // ...and no policy delete() backs it.
        $this->assertFalse(method_exists(self::POLICY_CLASS, 'delete'), 'Policy delete() unexpectedly present; DEV-PRM-NTF-001 may be resolved.');
    }

    /** test_53 — Super-admin Gate::before bypass is present (why the undefined gate still lets root delete). BC-AUTH. */
    public function test_notification_53_super_admin_gate_before_bypass_exists(): void
    {
        $src = $this->readSource('app/Providers/AppServiceProvider.php');
        $this->assertStringContainsString('Gate::before(', $src);
        $this->assertStringContainsString('is_super_admin', $src);
        $this->assertStringContainsString('super_admin_flag', $src);
    }

    /** test_54 — markAsRead + markAllAsRead have NO Gate::authorize (ungated; ownership-scoped only). BC-AUTH. */
    public function test_notification_54_mark_read_actions_are_ungated(): void
    {
        $markRead = $this->controllerMethodBody('markAsRead');
        $markAll  = $this->controllerMethodBody('markAllAsRead');
        $this->assertStringNotContainsString('Gate::authorize', $markRead, 'markAsRead should be ungated per current source.');
        $this->assertStringNotContainsString('Gate::authorize', $markAll, 'markAllAsRead should be ungated per current source.');

        // Exactly three Gate::authorize calls in the whole controller (viewAny, create, delete).
        $whole = $this->readSource(self::CONTROLLER_FILE);
        $this->assertSame(3, substr_count($whole, 'Gate::authorize('), 'Expected exactly 3 Gate::authorize calls in NotificationController.');
    }

    // ================================================================
    // 60–69  UI render (browser)
    // ================================================================

    /** test_60 — Notifications index renders for the admin (not login/403). TC-P / UI. */
    public function test_notification_60_all_notifications_page_renders_for_admin(): void
    {
        $this->browseWithFailureScreenshot('index-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Notifications index not reachable.');
            $this->ensurePageAccessible($browser, 'Notifications index');
            $browser->assertSee('Notifications');
        });
    }

    /** test_61 — All / Unread / Read filter buttons are present. TC-P / UI. */
    public function test_notification_61_filter_buttons_present(): void
    {
        $this->browseWithFailureScreenshot('filter-buttons', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Notifications filters');

            $browser->assertSee('All')
                ->assertSee('Unread')
                ->assertSee('Read');
        });
    }

    /** test_62 — Unread filter renders either rows or the "All caught up" empty state. TC-P / UI edge. */
    public function test_notification_62_unread_filter_renders_rows_or_empty_state(): void
    {
        $this->browseWithFailureScreenshot('unread-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?filter=unread');
            $this->ensurePageAccessible($browser, 'Notifications unread filter');

            $hasRows = $browser->element('.notification-row') !== null;
            $body = $browser->text('body');
            $this->assertTrue(
                $hasRows || str_contains($body, 'All caught up') || str_contains($body, 'No unread'),
                'Unread view should show notification rows or the empty state.'
            );
        });
    }

    /** test_63 — Breadcrumb / header shows the Notifications title. TC-P / UI. */
    public function test_notification_63_breadcrumb_shows_notifications_title(): void
    {
        $this->browseWithFailureScreenshot('breadcrumb', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Notifications breadcrumb');
            $browser->assertSee('Notifications');
        });
    }

    // ================================================================
    // 70–79  Action flows (browser + authenticated fetch)
    // ================================================================

    /** test_70 — test-notification route creates a notification and lands on the index. TC-P action. */
    public function test_notification_70_test_notification_route_creates_and_lists_notification(): void
    {
        $this->browseWithFailureScreenshot('create-via-test-route', function (Browser $browser): void {
            $this->authenticateCentral($browser);

            $browser->visit($this->centralUrl(self::TEST_NOTIF_PATH))->pause(1500);
            $this->ensurePageAccessible($browser, 'test-notification route');

            // Redirects to all-notifications with a success message.
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'test-notification should redirect to the index.');

            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertNotNull(
                $browser->element('.notification-row'),
                'A notification row should be present after sending a test notification.'
            );
        });
    }

    /** test_71 — Mark-all-read endpoint returns success JSON and zero unread. TC-P action / API. */
    public function test_notification_71_mark_all_read_returns_success_and_zero_unread(): void
    {
        $this->browseWithFailureScreenshot('mark-all-read', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            // Ensure at least one unread notification exists.
            $browser->visit($this->centralUrl(self::TEST_NOTIF_PATH))->pause(1200);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $this->ensurePageAccessible($browser, 'mark-all-read setup');

            $result = $this->sendJsonRequestFromBrowser($browser, 'POST', self::MARK_ALL_PATH);
            $this->assertContains($result['status'], [200], 'mark-all-read should return HTTP 200. Got ' . $result['status']);
            $payload = json_decode($result['body'], true);
            $this->assertIsArray($payload);
            $this->assertTrue((bool) ($payload['success'] ?? false), 'mark-all-read should return success:true.');
            $this->assertSame(0, (int) ($payload['unreadCount'] ?? -1), 'unreadCount should be 0 after mark-all-read.');
        });
    }

    /** test_72 — Deleting a notification via the DELETE endpoint returns success JSON. TC-P action / API. */
    public function test_notification_72_delete_notification_returns_success_json(): void
    {
        $this->browseWithFailureScreenshot('delete-notification', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl(self::TEST_NOTIF_PATH))->pause(1200);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $this->ensurePageAccessible($browser, 'delete setup');

            $row = $browser->element('.notification-row');
            if ($row === null) {
                $this->fail('No notification row to delete after sending a test notification.');
            }
            $id = $row->getAttribute('data-id');
            $this->assertNotEmpty($id, 'Notification row must expose a data-id.');

            $result = $this->sendJsonRequestFromBrowser($browser, 'DELETE', '/dashboard/notifications/' . $id);
            $this->assertSame(200, $result['status'], 'DELETE should return HTTP 200. Got ' . $result['status']);
            $payload = json_decode($result['body'], true);
            $this->assertTrue((bool) ($payload['success'] ?? false), 'delete should return success:true.');
        });
    }

    /** test_73 — Mark single as read endpoint returns success + recomputed unread count. TC-P action / API. */
    public function test_notification_73_mark_single_read_returns_success_json(): void
    {
        $this->browseWithFailureScreenshot('mark-single-read', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl(self::TEST_NOTIF_PATH))->pause(1200);
            $browser->visit($this->centralUrl(self::INDEX_PATH . '?filter=unread'))->pause(1000);
            $this->ensurePageAccessible($browser, 'mark-single-read setup');

            $row = $browser->element('.notification-row');
            if ($row === null) {
                $this->fail('No unread notification row to mark as read.');
            }
            $id = $row->getAttribute('data-id');

            $result = $this->sendJsonRequestFromBrowser($browser, 'POST', '/dashboard/notifications/' . $id . '/read');
            $this->assertSame(200, $result['status'], 'mark-read should return HTTP 200. Got ' . $result['status']);
            $payload = json_decode($result['body'], true);
            $this->assertTrue((bool) ($payload['success'] ?? false), 'mark-read should return success:true.');
            $this->assertArrayHasKey('unreadCount', $payload, 'mark-read response must include unreadCount.');
        });
    }

    // ================================================================
    // 80–89  Configuration / environment guard (SEC-PRM-002)
    // ================================================================

    /**
     * test_80 — SEC-PRM-002 (REFUTED): the debug test-notification route IS guarded by
     * app()->environment(['local','staging','testing']) at REGISTRATION. Proven from the
     * real routes/web.php source. The brief's "no environment guard" claim does not hold.
     * BC-CFG / TC-S.
     */
    public function test_notification_80_test_notification_route_is_environment_guarded_in_source(): void
    {
        $src = $this->readSource(self::ROUTES_FILE);
        // The registration is wrapped in an environment guard immediately before the route line.
        $this->assertMatchesRegularExpression(
            "/if\s*\(\s*app\(\)->environment\(\s*\[\s*'local'\s*,\s*'staging'\s*,\s*'testing'\s*\]\s*\)\s*\)\s*\{\s*\n\s*Route::get\('test-notification'/",
            $src,
            'SEC-PRM-002 expectation: test-notification must be environment-guarded at registration.'
        );
    }

    /** test_81 — Because APP_ENV=testing, the guarded route IS registered here. BC-CFG. */
    public function test_notification_81_test_notification_route_registered_in_testing_env(): void
    {
        $this->assertTrue(
            in_array(app()->environment(), ['local', 'staging', 'testing'], true),
            'Dusk/central tests are expected to run under a guarded environment.'
        );
        $this->assertTrue(Route::has(self::ROUTE_TEST_NOTIF), 'test-notification route should be registered in the testing environment.');
    }

    /**
     * test_82 — Residual defense-in-depth gap: the controller method itself has NO internal
     * App::environment() check. The only guard is at route registration. Documents current
     * behaviour (not a P1, but noted).
     * BC-CFG / TC-S.
     */
    public function test_notification_82_controller_testnotification_has_no_internal_env_check(): void
    {
        $body = $this->controllerMethodBody('testNotification');
        $this->assertStringNotContainsString('App::environment', $body, 'Current source: no internal env check in testNotification().');
        $this->assertStringNotContainsString('app()->environment', $body, 'Current source: no internal env check in testNotification().');
        // What it does do: authorize + notify + redirect back to the index.
        $this->assertStringContainsString('->notify(new TestNotification', $body);
        $this->assertStringContainsString("route('central.dashboard.all-notifications')", $body);
    }

    // ================================================================
    // 90–99  Security / ownership scoping (TC-S)
    // ================================================================

    /** test_90 — markAsRead is IDOR-safe: scoped through the user's own notifications()->findOrFail. TC-S. */
    public function test_notification_90_markasread_is_ownership_scoped(): void
    {
        $body = $this->controllerMethodBody('markAsRead');
        $this->assertStringContainsString('auth()->user()->notifications()->findOrFail($id)', $body);
    }

    /** test_91 — destroy is IDOR-safe: scoped through the user's own notifications()->findOrFail. TC-S. */
    public function test_notification_91_destroy_is_ownership_scoped(): void
    {
        $body = $this->controllerMethodBody('destroy');
        $this->assertStringContainsString('auth()->user()->notifications()->findOrFail($id)->delete()', $body);
    }

    /** test_92 — All notification routes live under the central. + dashboard. name groups. TC-S / BC-CFG. */
    public function test_notification_92_routes_under_central_dashboard_group(): void
    {
        foreach ([self::ROUTE_INDEX, self::ROUTE_MARK_READ, self::ROUTE_MARK_ALL, self::ROUTE_DESTROY, self::ROUTE_TEST_NOTIF] as $name) {
            $this->assertStringStartsWith('central.dashboard.', $name);
            $this->assertTrue(Route::has($name), "Route {$name} not registered under central.dashboard.");
        }
    }

    /** test_93 — Unauthenticated JSON POST to mark-all-read does not return a success 2xx. TC-S / BC-AUTH. */
    public function test_notification_93_guest_json_request_is_rejected(): void
    {
        $this->browseWithFailureScreenshot('guest-json-rejected', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            // Load a public page so a CSRF meta/token context is available, then fire an XHR.
            $browser->visit($this->centralUrl('/login'))->pause(1000);

            $result = $this->sendJsonRequestFromBrowser($browser, 'POST', self::MARK_ALL_PATH);
            // Guest is redirected (302 -> /login) or blocked (401/403/419) — never an authenticated 200 success payload.
            $this->assertNotContains(
                $result['status'],
                [200],
                'Guest mark-all-read must not succeed. Got ' . $result['status']
            );
        });
    }

    // ================================================================
    // Private helper library
    // ================================================================

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

    private function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            if ($superAdmin) {
                $this->adminUser = $superAdmin;
                return;
            }
            $this->adminUser = User::query()->where('email', $this->adminEmail)->first();
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    private function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl('/login'))->pause(900);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1300);
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
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    /**
     * Issue a same-origin authenticated JSON request from inside the browser page
     * (uses the live session cookie + CSRF meta token). Returns ['status','body'].
     */
    private function sendJsonRequestFromBrowser(Browser $browser, string $method, string $path): array
    {
        $js = <<<JS
var done = arguments[arguments.length - 1];
try {
    var meta = document.querySelector('meta[name="csrf-token"]');
    var token = meta ? meta.content : '';
    var xhr = new XMLHttpRequest();
    xhr.open('{$method}', '{$path}', false);
    xhr.setRequestHeader('X-CSRF-TOKEN', token);
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.setRequestHeader('Accept', 'application/json');
    xhr.send();
    done(JSON.stringify({ status: xhr.status, body: xhr.responseText }));
} catch (e) {
    done(JSON.stringify({ status: 0, body: String(e) }));
}
JS;

        $raw = $browser->driver->executeAsyncScript($js);
        $decoded = is_string($raw) ? json_decode($raw, true) : null;

        if (!is_array($decoded)) {
            return ['status' => 0, 'body' => ''];
        }

        return [
            'status' => (int) ($decoded['status'] ?? 0),
            'body'   => (string) ($decoded['body'] ?? ''),
        ];
    }

    private function readSource(string $relativePath): string
    {
        $abs = base_path($relativePath);
        $this->assertFileExists($abs, "Expected source file not found: {$relativePath}");
        return (string) file_get_contents($abs);
    }

    /** Extract a controller method body from source for precise per-method assertions. */
    private function controllerMethodBody(string $method): string
    {
        $ref = new \ReflectionMethod(self::CONTROLLER_CLASS, $method);
        $file = (string) $ref->getFileName();
        $start = (int) $ref->getStartLine();
        $end = (int) $ref->getEndLine();
        $lines = file($file) ?: [];
        return implode('', array_slice($lines, $start - 1, $end - $start + 1));
    }

    private function cleanScreenshots(): void
    {
        if (!defined('static::SCREENSHOT_DIR')) {
            return;
        }
        $dir = base_path(static::SCREENSHOT_DIR);
        if (is_dir($dir)) {
            foreach ((glob($dir . DIRECTORY_SEPARATOR . '*.png') ?: []) as $file) {
                @unlink($file);
            }
        }
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        if (!defined('static::SCREENSHOT_DIR')) {
            return '';
        }
        $directory = base_path(static::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'failure';
        $filename = $safeName . '_' . now()->format('Ymd_Hisv') . '.png';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $filename;

        try {
            $browser->driver->takeScreenshot($absolutePath);
            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolutePath);
        } catch (Throwable) {
            return '';
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
                $this->recordReportEntry($caseName, 'PASS', 'Step completed successfully.', '');
            } catch (Throwable $e) {
                $screenshot = $this->captureFailureScreenshot($browser, $caseName);
                $this->recordReportEntry($caseName, 'FAIL', $e->getMessage(), $screenshot);
                throw $e;
            }
        });
    }

    private function recordReportEntry(string $stepName, string $status, string $message, string $screenshotPath): void
    {
        $this->statusReportEntries[] = [
            'timestamp'  => now()->format('Y-m-d H:i:s'),
            'test'       => $this->name(),
            'step'       => $stepName,
            'status'     => $status,
            'message'    => $message,
            'screenshot' => $screenshotPath,
        ];
    }

    private function writeStatusReportForCurrentTest(): void
    {
        if (!defined('static::STATUS_REPORT_DIRECTORY')) {
            return;
        }
        $directory = base_path(static::STATUS_REPORT_DIRECTORY);
        File::ensureDirectoryExists($directory);

        $prefix = defined('static::STATUS_REPORT_PREFIX') ? static::STATUS_REPORT_PREFIX : 'prime_notification_report_';
        $sanitized = preg_replace('/[^a-z0-9_-]+/i', '_', strtolower($this->name()));
        $filename = $prefix . $sanitized . '_' . now()->format('Ymd_Hisv') . '.md';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $filename;

        $lines = [
            '# Prime Notification Dusk Status Report',
            '',
            '- Test Method: `' . $this->name() . '`',
            '- Generated At: `' . now()->format('Y-m-d H:i:s') . '`',
            '',
            '| Time | Step | Status | Message | Screenshot |',
            '| --- | --- | --- | --- | --- |',
        ];

        foreach ($this->statusReportEntries as $entry) {
            $message = str_replace('|', '/', $entry['message']);
            $screenshot = $entry['screenshot'] !== '' ? '`' . $entry['screenshot'] . '`' : '-';
            $lines[] = '| ' . $entry['timestamp'] . ' | ' . $entry['step'] . ' | ' . $entry['status'] . ' | ' . $message . ' | ' . $screenshot . ' |';
        }

        file_put_contents($absolutePath, implode(PHP_EOL, $lines) . PHP_EOL);
        $this->statusReportEntries = [];
    }
}
