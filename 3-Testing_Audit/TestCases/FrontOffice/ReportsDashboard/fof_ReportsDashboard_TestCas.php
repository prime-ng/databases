<?php

declare(strict_types=1);

namespace Tests\Browser\Modules\FrontOffice\ReportsDashboard;

use Illuminate\Support\Facades\Route;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\Domain;
use Modules\SchoolSetup\Models\User;
use Spatie\Permission\Models\Permission;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice ── ReportsDashboard (LIGHT, read-only screen).
 *
 * Screen composed of ONE KPI dashboard + FOUR combined "menu" report pages, all GET-only:
 *   - fof.dashboard                  GET /front-office                 FrontOfficeDashboardController@index   Gate: frontoffice.visitor.view
 *   - fof.menu.visitorManagement     GET /front-office/visitor-management  FofMenuController@visitorManagement Gate: frontoffice.visitor.view
 *   - fof.menu.communication         GET /front-office/communication       FofMenuController@communication     Gate: frontoffice.communication.view
 *   - fof.menu.registers             GET /front-office/registers           FofMenuController@registers         Gate: any([postal-register|dispatch-register|phone-diary|lost-found|key-register].viewAny)
 *   - fof.menu.compliance            GET /front-office/compliance          FofMenuController@compliance        Gate: frontoffice.complaint.view
 *
 * Paths + route-names + gate strings + filter param names + Blade selectors/labels are all
 * DERIVED FROM REAL SOURCE (Modules/FrontOffice/routes/web.php, the two controllers, and
 * resources/views/fof/dashboard/index.blade.php) — never hand-invented (Rule Card F40).
 *
 * Coverage set (light read-only): render / filters / export(=none, proven absent) / permission / empty-state.
 * NO create/edit/delete/duplicate/DDL-alignment matrix — this screen writes nothing (task scope + FactPack §7).
 *
 * Tenancy: TENANT-SIDE Dusk. setUp resolves the tenant via Modules\Prime\Models\Domain and
 * initializes tenancy for the factory writes; tearDown ends it under guard (Rule Card #1-#4).
 * Mirrors the nearest committed read-only siblings: Complaint/CmpDashboard + Vendor/VendorReports.
 *
 * ENV PREREQS (see Validation Report): FrontOffice must be ENABLED in modules_statuses.json
 * (else every /front-office/* route 404s — Rule Card #19); APP_ENV=testing (#20); DUSK_TENANT_URL set.
 */
class fof_ReportsDashboard_TestCas extends DuskTestCase
{
    // ── Derived paths (from route:list / module route prefix 'front-office') ──────
    private const PATH_DASHBOARD      = '/front-office';
    private const PATH_VISITOR_MGMT   = '/front-office/visitor-management';
    private const PATH_COMMUNICATION  = '/front-office/communication';
    private const PATH_REGISTERS      = '/front-office/registers';
    private const PATH_COMPLIANCE     = '/front-office/compliance';
    private const PATH_LOGIN          = '/login';

    // ── Real gate ability strings (grepped per controller method) ────────────────
    private const PERM_DASHBOARD     = 'frontoffice.visitor.view';
    private const PERM_VISITOR_VIEW  = 'frontoffice.visitor.view';
    private const PERM_COMMUNICATION = 'frontoffice.communication.view';
    private const PERM_COMPLAINT     = 'frontoffice.complaint.view';
    private const PERMS_REGISTERS    = [
        'frontoffice.postal-register.viewAny',
        'frontoffice.dispatch-register.viewAny',
        'frontoffice.phone-diary.viewAny',
        'frontoffice.lost-found.viewAny',
        'frontoffice.key-register.viewAny',
    ];

    private string $tenantBaseUrl = '';

    protected function setUp(): void
    {
        parent::setUp();
        $this->tenantBaseUrl = rtrim((string) env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')), '/');
        $this->initializeTenantContextForTests();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }
        parent::tearDown();
    }

    // =====================================================================
    // Helpers (self-contained library — mirrors sibling Vendor/Complaint idioms)
    // =====================================================================

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

    private function ensurePermissions(array $names): void
    {
        if (!class_exists(Permission::class)) {
            return;
        }
        $guard = (string) config('auth.defaults.guard', 'web');
        foreach ($names as $name) {
            try {
                Permission::firstOrCreate(['name' => $name, 'guard_name' => $guard]);
            } catch (Throwable) {
                // permission table may vary between tenants — ignore, grant is best-effort
            }
        }
    }

    /**
     * A fresh factory user granted exactly the given abilities (and nothing else).
     * Returns null when the factory cannot build a user (env not seeded) → caller skips.
     */
    private function userWith(array $permissions): ?User
    {
        try {
            $user = User::factory()->create();
        } catch (Throwable $e) {
            return null;
        }

        $this->ensurePermissions($permissions);
        if (method_exists($user, 'givePermissionTo')) {
            foreach ($permissions as $perm) {
                try {
                    $user->givePermissionTo($perm);
                } catch (Throwable) {
                }
            }
        }
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

        return $user;
    }

    /**
     * A fresh NON-super-admin factory user with NO abilities — for authorization negatives
     * (Rule Card #31: Gate::before grants Super Admin everything, so strip elevation).
     */
    private function restrictedUser(): ?User
    {
        try {
            $user = User::factory()->create();
        } catch (Throwable $e) {
            return null;
        }

        foreach (['is_super_admin', 'super_admin_flag', 'is_admin'] as $flag) {
            if (isset($user->{$flag})) {
                $user->{$flag} = 0;
            }
        }
        try {
            $user->save();
        } catch (Throwable) {
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
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

        return $user;
    }

    private function skipIfNoUser(?User $user): User
    {
        if (!$user) {
            $this->markTestSkipped('Tenant user factory unavailable in this env (sys_users not seeded / factory missing).');
        }
        return $user;
    }

    // =====================================================================
    // A. Structure / route-registration alignment (F40-compliant, no hand URLs)
    // =====================================================================

    public function test_TC_A01_all_report_routes_registered(): void
    {
        $this->assertTrue(Route::has('fof.dashboard'), 'fof.dashboard route must be registered');
        $this->assertTrue(Route::has('fof.menu.visitorManagement'), 'fof.menu.visitorManagement must be registered');
        $this->assertTrue(Route::has('fof.menu.communication'), 'fof.menu.communication must be registered');
        $this->assertTrue(Route::has('fof.menu.registers'), 'fof.menu.registers must be registered');
        $this->assertTrue(Route::has('fof.menu.compliance'), 'fof.menu.compliance must be registered');
    }

    // =====================================================================
    // B. RENDER
    // =====================================================================

    public function test_TC_R01_dashboard_renders_with_kpis(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_DASHBOARD]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_DASHBOARD)
                ->assertPathIs(self::PATH_DASHBOARD)
                ->assertSee('Front Office')
                ->assertSee("Today's Visitors")
                ->assertSee('Gate Passes Pending')
                ->assertSee('Cert Requests Pending')
                ->assertSee('Open Complaints')
                ->assertSee('Overstay Visitors')
                ->assertSee("Today's Appointments");
        });
    }

    public function test_TC_R02_dashboard_charts_and_tables_present(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_DASHBOARD]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_DASHBOARD)
                ->assertSee('Visitors by Purpose (Last 30 Days)')
                ->assertSee('Daily Visitor Trend (Last 7 Days)')
                ->assertPresent('#purposeChart')
                ->assertPresent('#trendChart')
                ->assertSee('Recent Visitors')
                ->assertSee('Upcoming Appointments')
                ->assertSee("Today's Summary");
        });
    }

    public function test_TC_R03_visitor_management_menu_renders(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_VISITOR_VIEW]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_VISITOR_MGMT)
                ->assertPathIs(self::PATH_VISITOR_MGMT)
                ->assertDontSee('403');
        });
    }

    public function test_TC_R04_communication_menu_renders(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_COMMUNICATION]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_COMMUNICATION)
                ->assertPathIs(self::PATH_COMMUNICATION)
                ->assertDontSee('403');
        });
    }

    public function test_TC_R05_registers_menu_renders(): void
    {
        $user = $this->skipIfNoUser($this->userWith(self::PERMS_REGISTERS));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_REGISTERS)
                ->assertPathIs(self::PATH_REGISTERS)
                ->assertDontSee('403');
        });
    }

    public function test_TC_R06_compliance_menu_renders(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_COMPLAINT]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_COMPLIANCE)
                ->assertPathIs(self::PATH_COMPLIANCE)
                ->assertDontSee('403');
        });
    }

    // =====================================================================
    // C. FILTERS (query-string driven; controller reads tab/search/status/channel/call_type)
    // =====================================================================

    public function test_TC_F01_visitor_mgmt_search_filter(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_VISITOR_VIEW]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_VISITOR_MGMT . '?tab=visitors&search=ZZ_no_match_' . uniqid())
                ->assertPathIs(self::PATH_VISITOR_MGMT)
                ->assertQueryStringHas('tab', 'visitors')
                ->assertQueryStringHas('search')
                ->assertDontSee('403');
        });
    }

    public function test_TC_F02_visitor_mgmt_status_filter(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_VISITOR_VIEW]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_VISITOR_MGMT . '?tab=visitors&status=1')
                ->assertPathIs(self::PATH_VISITOR_MGMT)
                ->assertQueryStringHas('status', '1')
                ->assertDontSee('403');
        });
    }

    public function test_TC_F03_visitor_mgmt_tab_switch(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_VISITOR_VIEW]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_VISITOR_MGMT . '?tab=gate-passes')
                ->assertPathIs(self::PATH_VISITOR_MGMT)
                ->assertQueryStringHas('tab', 'gate-passes')
                ->assertDontSee('403');
        });
    }

    public function test_TC_F04_communication_channel_filter(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_COMMUNICATION]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_COMMUNICATION . '?tab=email-sms&channel=Email')
                ->assertPathIs(self::PATH_COMMUNICATION)
                ->assertQueryStringHas('channel', 'Email')
                ->assertDontSee('403');
        });
    }

    public function test_TC_F05_registers_call_type_filter(): void
    {
        $user = $this->skipIfNoUser($this->userWith(self::PERMS_REGISTERS));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_REGISTERS . '?tab=phone-diary&call_type=Incoming')
                ->assertPathIs(self::PATH_REGISTERS)
                ->assertQueryStringHas('call_type', 'Incoming')
                ->assertDontSee('403');
        });
    }

    public function test_TC_F06_compliance_status_filter(): void
    {
        $user = $this->skipIfNoUser($this->userWith([self::PERM_COMPLAINT]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_COMPLIANCE . '?tab=complaints&status=Open')
                ->assertPathIs(self::PATH_COMPLIANCE)
                ->assertQueryStringHas('status', 'Open')
                ->assertDontSee('403');
        });
    }

    // =====================================================================
    // D. EXPORT — proven ABSENT (this screen offers no CSV/PDF/export endpoint)
    // =====================================================================

    public function test_TC_X01_no_export_route_exists(): void
    {
        // The dashboard + menu pages are pure read views. Assert that no export route
        // exists so a future silently-added/renamed export is caught (F40: never invent).
        $this->assertFalse(Route::has('fof.dashboard.export'), 'No export route is expected on the dashboard');
        $this->assertFalse(Route::has('fof.menu.export'), 'No export route is expected on the menu pages');
        $this->assertFalse(Route::has('fof.reports.export'), 'No fof.reports.export route is expected');
    }

    // =====================================================================
    // E. EMPTY-STATE
    // =====================================================================

    public function test_TC_E01_dashboard_chart_empty_state_present(): void
    {
        // Both chart cards always render an empty-state placeholder div (JS reveals the
        // canvas only when data exists). The placeholder markup is a stable structural
        // guarantee independent of whether the tenant currently has visitor data.
        $user = $this->skipIfNoUser($this->userWith([self::PERM_DASHBOARD]));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_DASHBOARD)
                ->assertPresent('#purposeChartEmpty')
                ->assertPresent('#trendChartEmpty')
                ->assertSee('No visitor data available yet');
        });
    }

    public function test_TC_E02_registers_no_match_still_renders(): void
    {
        // A search that matches nothing must still render the page (empty tables), not error.
        $user = $this->skipIfNoUser($this->userWith(self::PERMS_REGISTERS));

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_REGISTERS . '?tab=postal&search=ZZ_none_' . uniqid())
                ->assertPathIs(self::PATH_REGISTERS)
                ->assertQueryStringHas('search')
                ->assertDontSee('403');
        });
    }

    // =====================================================================
    // F. PERMISSION NEGATIVES (non-super-admin, cache flushed → 403) + guest redirect
    // =====================================================================

    public function test_TC_N01_guest_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser) {
            $browser->logout()
                ->visit(self::PATH_DASHBOARD)
                ->assertPathIs(self::PATH_LOGIN);
        });
    }

    public function test_TC_N02_dashboard_403_without_visitor_view(): void
    {
        $user = $this->skipIfNoUser($this->restrictedUser());

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_DASHBOARD)
                ->assertSee('403');
        });
    }

    public function test_TC_N03_communication_403_without_permission(): void
    {
        $user = $this->skipIfNoUser($this->restrictedUser());

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_COMMUNICATION)
                ->assertSee('403');
        });
    }

    public function test_TC_N04_compliance_403_without_permission(): void
    {
        $user = $this->skipIfNoUser($this->restrictedUser());

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_COMPLIANCE)
                ->assertSee('403');
        });
    }

    public function test_TC_N05_registers_403_without_any_view_any(): void
    {
        // registers uses Gate::any([...5 viewAny...]) → a user with none of them is 403.
        $user = $this->skipIfNoUser($this->restrictedUser());

        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit(self::PATH_REGISTERS)
                ->assertSee('403');
        });
    }
}
