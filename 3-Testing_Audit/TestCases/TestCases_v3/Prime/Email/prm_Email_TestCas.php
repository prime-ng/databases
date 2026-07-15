<?php

namespace Tests\Browser\Modules\Prime\Email;

use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * prm_Email_TestCas
 * -----------------------------------------------------------------------------
 * Feature: Prime (PRM) central "Email" debug/preview tooling.
 * Screen type: TABLELESS ACTION screen — there is NO domain table, so there is
 * NO schema CRUD matrix. This is an action/read-focused suite covering:
 *   - route existence + registration (env-guarded debug routes)
 *   - permission gates (Gate::authorize) + policy mapping
 *   - action behaviour (test-email preview render, send-test-email response)
 *   - guest redirect
 *   - SEC-PRM-002 current-behaviour proof
 *
 * DB scope: Prime = CENTRAL (prime_db). NO tenant initialization. Host is
 * http://127.0.0.1:8000 (enforced by PrimeDuskTestCase). Central auth/helpers
 * are implemented LOCALLY in this file (mirroring BillingDuskTestCase) so this
 * suite does not depend on the Billing namespace. (Constraints E21, E22.)
 *
 * Real source of truth (read before authoring — HARD RULE 1):
 *   - Modules/Prime/app/Http/Controllers/EmailController.php  (testEmail, sendTestEmail)
 *   - Modules/Prime/app/Policies/PrimeEmailPolicy.php          (viewAny, create)
 *   - Modules/Prime/app/Providers/PrimeServiceProvider.php:88-89 (Gate::define)
 *   - Modules/Prime/app/Emails/LoginMail.php
 *   - Modules/Prime/resources/views/email/test-email.blade.php
 *   - routes/web.php:99-102 (central.dashboard.test-email / send-test-email, env-guarded)
 *
 * SEC-PRM-002 note (verified against source): the original audit claim was
 * "debug routes registered as production routes with NO environment guard".
 * The REAL source (routes/web.php:99) wraps both routes in
 *   if (app()->environment(['local', 'staging', 'testing'])) { ... }
 * so the "no env guard / registered in production" part of the claim is REFUTED
 * by source. Residual, still-valid smells proven here:
 *   (a) sendTestEmail() sends real mail to a HARDCODED address
 *       'primegurukul@yopmail.com' (EmailController.php:73,116);
 *   (b) send-test-email is a GET route that triggers a side-effecting mail send;
 *   (c) 'staging' is inside the allowed-environments list.
 * These tests prove CURRENT behaviour (HARD RULE 10), not the desired behaviour.
 */
class prm_Email_TestCas extends PrimeDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Email/screenshots';

    private const TEST_EMAIL_PATH = '/dashboard/test-email';
    private const SEND_TEST_EMAIL_PATH = '/dashboard/send-test-email';

    private const ROUTE_TEST_EMAIL = 'central.dashboard.test-email';
    private const ROUTE_SEND_TEST_EMAIL = 'central.dashboard.send-test-email';

    private const GATE_VIEW_ANY = 'prime.email.viewAny';
    private const GATE_CREATE = 'prime.email.create';

    private const HARDCODED_RECIPIENT = 'primegurukul@yopmail.com';

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
        // Prime/central feature — no tenant context is ever initialized here.
        parent::tearDown();
    }

    // =========================================================================
    // 01-09  CONFIGURATION TRUTH (tableless — routes/gates/methods, not schema)
    // =========================================================================

    /**
     * test_01 = config truth. For a tableless action screen this asserts the
     * ROUTE + GATE + CONTROLLER + POLICY + MAILABLE + VIEW wiring instead of a
     * DDL schema, plus the central activity-log sink table existence (fail-soft).
     * BC-CFG-01..07 / Source: routes/web.php, PrimeServiceProvider, EmailController.
     */
    public function test_email_01_routes_gates_controller_and_policy_configuration_are_correct(): void
    {
        // --- Routes registered (under APP_ENV=testing the env guard permits them) ---
        $this->assertTrue(
            Route::has(self::ROUTE_TEST_EMAIL),
            'Route ' . self::ROUTE_TEST_EMAIL . ' is not registered.'
        );
        $this->assertTrue(
            Route::has(self::ROUTE_SEND_TEST_EMAIL),
            'Route ' . self::ROUTE_SEND_TEST_EMAIL . ' is not registered.'
        );

        // --- Route URIs match the documented central/dashboard paths ---
        $testRoute = Route::getRoutes()->getByName(self::ROUTE_TEST_EMAIL);
        $sendRoute = Route::getRoutes()->getByName(self::ROUTE_SEND_TEST_EMAIL);
        $this->assertNotNull($testRoute, 'test-email route object missing.');
        $this->assertNotNull($sendRoute, 'send-test-email route object missing.');
        $this->assertStringContainsString('dashboard/test-email', (string) $testRoute->uri());
        $this->assertStringContainsString('dashboard/send-test-email', (string) $sendRoute->uri());

        // --- Controller + methods exist ---
        $controller = 'Modules\\Prime\\Http\\Controllers\\EmailController';
        $this->assertTrue(class_exists($controller), 'EmailController class missing.');
        $this->assertTrue(method_exists($controller, 'testEmail'), 'testEmail() missing.');
        $this->assertTrue(method_exists($controller, 'sendTestEmail'), 'sendTestEmail() missing.');

        // --- Gates defined (PrimeServiceProvider::boot) ---
        $this->assertTrue(Gate::has(self::GATE_VIEW_ANY), 'Gate ' . self::GATE_VIEW_ANY . ' not defined.');
        $this->assertTrue(Gate::has(self::GATE_CREATE), 'Gate ' . self::GATE_CREATE . ' not defined.');

        // --- Policy + methods exist ---
        $policy = 'Modules\\Prime\\Policies\\PrimeEmailPolicy';
        $this->assertTrue(class_exists($policy), 'PrimeEmailPolicy class missing.');
        $this->assertTrue(method_exists($policy, 'viewAny'), 'PrimeEmailPolicy::viewAny() missing.');
        $this->assertTrue(method_exists($policy, 'create'), 'PrimeEmailPolicy::create() missing.');

        // --- Mailable exists ---
        $this->assertTrue(
            class_exists('Modules\\Prime\\Emails\\LoginMail'),
            'LoginMail mailable missing.'
        );

        // --- Central activity-log sink table (fail-soft: constraint #24/#25) ---
        // Prime/central features log to sys_central_activity_logs when tenancy is
        // NOT initialized. The email debug controller does NOT write an activity
        // log, but we confirm the sink exists so the assumption is documented.
        if (Schema::hasTable('sys_central_activity_logs')) {
            $this->assertTrue(
                Schema::hasColumn('sys_central_activity_logs', 'event'),
                'sys_central_activity_logs.event column missing.'
            );
        }
    }

    /**
     * The email debug view template and its component exist (render dependency).
     * Source: resources/views/email/test-email.blade.php + LoginMail::build().
     */
    public function test_email_02_email_preview_view_source_is_present(): void
    {
        $view = $this->readAppSource('Modules/Prime/resources/views/email/test-email.blade.php');

        if ($view === null) {
            $this->markTestSkipped('App source not reachable (MAIN_PROJECT_PATH unset); view asserted at runtime instead.');
        }

        $this->assertStringContainsString('x-backend.email.template', $view, 'Email template component not referenced.');
        $this->assertStringContainsString('$title', $view, 'Template does not render $title.');
        $this->assertStringContainsString('$content', $view, 'Template does not render $content.');
    }

    // =========================================================================
    // 10-19  ACTION BEHAVIOUR (BC-BIZ)
    // =========================================================================

    /**
     * testEmail() renders the HTML email preview for an authorized user.
     * BC-BIZ-01 / Source: EmailController::testEmail() returns prime::email.test-email.
     */
    public function test_email_10_test_email_route_renders_preview_for_authorized_user(): void
    {
        $this->browseWithFailureScreenshot('email-preview-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TEST_EMAIL_PATH);

            $this->assertSame(
                self::TEST_EMAIL_PATH,
                $this->currentPath($browser),
                'test-email preview not reachable for authorized user.'
            );

            $this->ensurePageAccessible($browser, 'Email preview');

            // Title + context label + info fields are server-set in the controller.
            $browser->assertSee('New Login Detected');
        });
    }

    /**
     * The rendered preview contains the controller-supplied context + info block.
     * BC-BIZ-02 / Source: EmailController::testEmail() payload (context label, info).
     */
    public function test_email_11_preview_contains_context_and_info_sections(): void
    {
        $this->browseWithFailureScreenshot('email-preview-sections', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TEST_EMAIL_PATH);

            $this->ensurePageAccessible($browser, 'Email preview sections');

            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Security Alert', $source, 'Context badge label missing from preview.');
            $this->assertStringContainsString('Login Details', $source, 'Info block heading missing from preview.');
        });
    }

    /**
     * sendTestEmail() responds with the literal "Email Sent" string.
     * BC-BIZ-03 / Source: EmailController::sendTestEmail() returns "Email Sent".
     * NOTE: Dusk cannot assert the mail was actually queued/sent (no Mail::fake in
     * a real browser). This test proves the HTTP response only; the send side-effect
     * is proven at source level in test_email_14.
     */
    public function test_email_12_send_test_email_route_returns_email_sent(): void
    {
        $this->browseWithFailureScreenshot('email-send-response', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SEND_TEST_EMAIL_PATH);

            $this->assertSame(
                self::SEND_TEST_EMAIL_PATH,
                $this->currentPath($browser),
                'send-test-email route not reachable for authorized user.'
            );

            $source = $browser->driver->getPageSource();
            $this->assertStringContainsString('Email Sent', $source, 'send-test-email did not return "Email Sent".');
        });
    }

    /**
     * The send-test-email route is registered as a GET verb (see SEC-PRM-002).
     * A state-/side-effecting mail send behind a GET is a REST/CSRF smell.
     * BC-BIZ-04 / Source: routes/web.php:101 Route::get('send-test-email', ...).
     */
    public function test_email_13_send_test_email_is_registered_as_get_verb(): void
    {
        $route = Route::getRoutes()->getByName(self::ROUTE_SEND_TEST_EMAIL);
        $this->assertNotNull($route, 'send-test-email route missing.');

        $methods = $route->methods();
        $this->assertContains('GET', $methods, 'send-test-email is expected (current behaviour) to be a GET route.');
        // Documented smell: a GET should be safe/idempotent, but this one sends mail.
    }

    /**
     * Source-level proof that sendTestEmail() actually dispatches a real mail
     * (Dusk cannot assert this at runtime). BC-BIZ-05 / Source: EmailController:116.
     */
    public function test_email_14_send_test_email_source_dispatches_login_mail(): void
    {
        $controller = $this->readAppSource('Modules/Prime/app/Http/Controllers/EmailController.php');

        if ($controller === null) {
            $this->markTestSkipped('App source not reachable (MAIN_PROJECT_PATH unset); send verified via HTTP response in test_12.');
        }

        $this->assertStringContainsString('Mail::to', $controller, 'sendTestEmail does not call Mail::to().');
        $this->assertStringContainsString('new LoginMail(', $controller, 'sendTestEmail does not build a LoginMail.');
    }

    // =========================================================================
    // 50-59  PERMISSIONS / AUTHORIZATION (BC-AUTH)
    // =========================================================================

    /**
     * testEmail() is gated by EXACTLY prime.email.viewAny.
     * BC-AUTH-01 / Source: EmailController::testEmail() Gate::authorize('prime.email.viewAny').
     */
    public function test_email_50_test_email_is_gated_by_view_any(): void
    {
        $this->assertTrue(Gate::has(self::GATE_VIEW_ANY), 'prime.email.viewAny gate not registered.');

        $controller = $this->readAppSource('Modules/Prime/app/Http/Controllers/EmailController.php');
        if ($controller === null) {
            $this->markTestSkipped('App source not reachable; gate registration asserted via Gate::has above.');
        }

        $this->assertStringContainsString(
            "Gate::authorize('prime.email.viewAny')",
            $controller,
            'testEmail() is not gated by prime.email.viewAny.'
        );
    }

    /**
     * sendTestEmail() is gated by EXACTLY prime.email.create.
     * BC-AUTH-02 / Source: EmailController::sendTestEmail() Gate::authorize('prime.email.create').
     */
    public function test_email_51_send_test_email_is_gated_by_create(): void
    {
        $this->assertTrue(Gate::has(self::GATE_CREATE), 'prime.email.create gate not registered.');

        $controller = $this->readAppSource('Modules/Prime/app/Http/Controllers/EmailController.php');
        if ($controller === null) {
            $this->markTestSkipped('App source not reachable; gate registration asserted via Gate::has above.');
        }

        $this->assertStringContainsString(
            "Gate::authorize('prime.email.create')",
            $controller,
            'sendTestEmail() is not gated by prime.email.create.'
        );
    }

    /**
     * Policy methods map to the gate abilities (viewAny -> can viewAny, create -> can create).
     * BC-AUTH-03 / Source: PrimeEmailPolicy.php + PrimeServiceProvider Gate::define bindings.
     */
    public function test_email_52_policy_methods_map_to_gate_abilities(): void
    {
        $policy = $this->readAppSource('Modules/Prime/app/Policies/PrimeEmailPolicy.php');
        if ($policy === null) {
            $this->markTestSkipped('App source not reachable; policy existence asserted in test_01.');
        }

        $this->assertStringContainsString("can('prime.email.viewAny')", $policy, 'viewAny policy does not check the ability.');
        $this->assertStringContainsString("can('prime.email.create')", $policy, 'create policy does not check the ability.');
    }

    /**
     * Guest is redirected to /login when hitting the email preview route
     * (route sits behind auth+verified middleware).
     * BC-AUTH-04 / TC-N / Source: routes/web.php:83 middleware(['auth','verified']).
     */
    public function test_email_53_guest_is_redirected_from_test_email(): void
    {
        $this->browseWithFailureScreenshot('email-preview-guest', function (Browser $browser): void {
            $this->logoutBrowser($browser);
            $browser->visit($this->centralUrl(self::TEST_EMAIL_PATH))->pause(1200);

            $this->assertStringContainsString(
                '/login',
                $this->currentPath($browser),
                'Guest was NOT redirected to /login from test-email.'
            );
        });
    }

    /**
     * Guest is redirected to /login when hitting the send-test-email route.
     * BC-AUTH-05 / TC-N / Source: routes/web.php:83 middleware(['auth','verified']).
     */
    public function test_email_54_guest_is_redirected_from_send_test_email(): void
    {
        $this->browseWithFailureScreenshot('email-send-guest', function (Browser $browser): void {
            $this->logoutBrowser($browser);
            $browser->visit($this->centralUrl(self::SEND_TEST_EMAIL_PATH))->pause(1200);

            $this->assertStringContainsString(
                '/login',
                $this->currentPath($browser),
                'Guest was NOT redirected to /login from send-test-email.'
            );
        });
    }

    // =========================================================================
    // 90-99  SECURITY PACK (TC-S) — SEC-PRM-002 current-behaviour proof
    // =========================================================================

    /**
     * SEC-PRM-002 (P1) — CURRENT BEHAVIOUR PROOF.
     * The audit claimed the debug routes have "NO environment guard". Source
     * REFUTES this: routes/web.php:99 wraps both email routes in
     *   if (app()->environment(['local', 'staging', 'testing'])) { ... }
     * This test proves the guard is present in source AND that the running
     * environment (APP_ENV=testing for Dusk) is inside the allowed set, which is
     * why Route::has() succeeds here. In production the routes are NOT registered.
     * Source: routes/web.php:98-103.
     */
    public function test_email_90_debug_routes_have_environment_guard_present(): void
    {
        // Under the Dusk runner APP_ENV=testing, which IS in the guard's allow-list.
        $this->assertTrue(
            app()->environment(['local', 'staging', 'testing']),
            'Expected the test runner to run in an env inside the route guard allow-list.'
        );

        // Because we ARE in an allowed env, the guarded routes are registered.
        $this->assertTrue(Route::has(self::ROUTE_TEST_EMAIL), 'Guarded test-email route not registered in an allowed env.');
        $this->assertTrue(Route::has(self::ROUTE_SEND_TEST_EMAIL), 'Guarded send-test-email route not registered in an allowed env.');

        // Source proof that the guard exists (REFUTES "no environment guard").
        $routes = $this->readAppSource('routes/web.php');
        if ($routes === null) {
            $this->markTestSkipped('App routes/web.php not reachable; env-guard proven behaviourally above.');
        }

        $this->assertMatchesRegularExpression(
            "/app\\(\\)->environment\\(\\[[^\\]]*'testing'[^\\]]*\\]\\)[\\s\\S]{0,400}send-test-email/",
            $routes,
            'Email debug routes are NOT wrapped by an app()->environment([...]) guard (audit claim would then hold).'
        );
    }

    /**
     * SEC-PRM-002 residual (a): sendTestEmail() sends to a HARDCODED recipient.
     * TC-S / Source: EmailController.php:73,116 'primegurukul@yopmail.com'.
     */
    public function test_email_91_send_test_email_uses_hardcoded_recipient(): void
    {
        $controller = $this->readAppSource('Modules/Prime/app/Http/Controllers/EmailController.php');
        if ($controller === null) {
            $this->markTestSkipped('App source not reachable; hardcoded recipient documented in Gap Analysis.');
        }

        $this->assertStringContainsString(
            self::HARDCODED_RECIPIENT,
            $controller,
            'Expected hardcoded recipient not found (behaviour changed — re-verify SEC-PRM-002).'
        );
    }

    /**
     * SEC-PRM-002 residual (b): the send route is a GET that triggers a side effect
     * and takes no CSRF token — reflected here as a documented current-behaviour smell.
     * TC-S / Source: routes/web.php:101 + EmailController::sendTestEmail().
     */
    public function test_email_92_send_route_is_side_effecting_get_without_csrf(): void
    {
        $route = Route::getRoutes()->getByName(self::ROUTE_SEND_TEST_EMAIL);
        $this->assertNotNull($route, 'send-test-email route missing.');
        $this->assertContains('GET', $route->methods(), 'send-test-email is expected to be GET (current behaviour).');

        // GET routes carry no CSRF protection by design; combined with a mail send
        // this is the documented residual smell. Assert absence of a mutating verb.
        $this->assertNotContains('POST', $route->methods(), 'send-test-email unexpectedly also accepts POST.');
    }

    /**
     * Preview output smoke: an injected query string is NOT reflected into the page
     * (the preview content is entirely server-set in the controller, so there is no
     * user-controlled reflected-XSS surface). Documented no-reflection smoke.
     * TC-S / Source: EmailController::testEmail() payload is static server-side.
     */
    public function test_email_93_preview_does_not_reflect_injected_query_input(): void
    {
        $marker = 'zzxss' . substr(md5((string) mt_rand()), 0, 6);
        $payload = '<script>' . $marker . '</script>';

        $this->browseWithFailureScreenshot('email-preview-xss-smoke', function (Browser $browser) use ($payload, $marker): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated(
                $browser,
                self::TEST_EMAIL_PATH . '?q=' . rawurlencode($payload)
            );

            $this->ensurePageAccessible($browser, 'Email preview XSS smoke');

            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString(
                '<script>' . $marker . '</script>',
                $source,
                'Injected query input was reflected unescaped into the preview.'
            );
        });
    }

    // =========================================================================
    // Private helper library (central auth + screenshots + source access)
    // Implemented locally (mirrors BillingDuskTestCase) — no Billing dependency.
    // =========================================================================

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
        $superAdmin = User::query()->where('is_super_admin', 1)->first();
        if ($superAdmin) {
            $this->adminUser = $superAdmin;
            $this->ensureUserIsVerified($this->adminUser);

            return;
        }

        $userByEmail = User::query()->where('email', $this->adminEmail)->first();
        if ($userByEmail) {
            $this->adminUser = $userByEmail;
            $this->ensureUserIsVerified($this->adminUser);

            return;
        }

        $this->adminUser = User::create([
            'email' => $this->adminEmail,
            'password' => bcrypt($this->adminPassword),
            'name' => 'Email Dusk Admin',
            'emp_code' => 'EMP' . rand(100, 999),
            'short_name' => 'ADM' . rand(1000, 9999),
            'status' => 'ACTIVE',
            'is_active' => 1,
            'is_super_admin' => 1,
            'email_verified_at' => now(),
        ]);
    }

    private function ensureUserIsVerified(User $user): void
    {
        $updates = [];

        if (empty($user->email_verified_at)) {
            $updates['email_verified_at'] = now();
        }

        if (property_exists($user, 'is_active') && (int) $user->is_active !== 1) {
            $updates['is_active'] = 1;
        }

        if (!empty($updates)) {
            $user->fill($updates);
            $user->save();
        }
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

        if (str_contains($this->currentPath($browser), '/login')) {
            if ($this->adminUser) {
                $browser->loginAs($this->adminUser)->pause(800);
            }
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

    private function logoutBrowser(Browser $browser): void
    {
        try {
            $browser->visit($this->centralUrl('/'))->pause(300);
            $browser->driver->manage()->deleteAllCookies();
        } catch (Throwable) {
            // best-effort: fall through to a cookie-less visit
        }
    }

    private function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows login page; authentication failed.');
        }

        $bodyText = $browser->element('body') ? $browser->text('body') : '';
        $signals = ['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419'];

        foreach ($signals as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
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

    private function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'failure';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $safeName . '_' . now()->format('Ymd_His') . '.png';

        try {
            $browser->driver->takeScreenshot($absolutePath);

            return $absolutePath;
        } catch (Throwable) {
            return '';
        }
    }

    private function cleanScreenshots(): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);

        try {
            if (File::isDirectory($directory)) {
                File::cleanDirectory($directory);
            }
        } catch (Throwable) {
            // non-fatal
        }
    }

    /**
     * Read a source file from the APP repo (prime_ai). The Dusk runner's
     * base_path() points at the runner, so app source lives under
     * MAIN_PROJECT_PATH. Returns null (fail-soft) when unreachable, so
     * source-content asserts degrade to markTestSkipped rather than false-fail.
     */
    private function readAppSource(string $relativePath): ?string
    {
        $roots = array_filter([
            env('MAIN_PROJECT_PATH'),
            base_path(),
        ]);

        foreach ($roots as $root) {
            $candidate = rtrim((string) $root, '/') . '/' . ltrim($relativePath, '/');
            try {
                if (File::exists($candidate)) {
                    return (string) File::get($candidate);
                }
            } catch (Throwable) {
                continue;
            }
        }

        return null;
    }
}
