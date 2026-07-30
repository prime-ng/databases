# Prime (PRM) — Dashboard & Authentication Requirement Document

## 1. Module / Feature

| Attribute | Value |
|-----------|-------|
| **Module** | Prime (PRM) |
| **Feature** | Prime Dashboard & Central Authentication |
| **Sub-Features** | Platform Dashboard (`PrimeController`), User Authentication (`PrimeAuthController`) |
| **Prefix** | `prm_` |
| **DB Layer** | prime_db |
| **Tenant Scope** | Central domain only |

## 2. Controller(s) & Route(s)

### 2.1 PrimeController

| Method | Route | Name | Middleware | Gate | Description |
|--------|-------|------|-----------|------|-------------|
| `index()` | `GET /` | `central.prime.index` | None (public) | None | Landing page — redirects to dashboard if authenticated |
| `dashboard()` | `GET /dashboard` | `central.prime.dashboard` | auth, verified, 2fa | `prime.dashboard.viewAny` | Main platform dashboard with all KPIs |
| `coreConfiguration()` | `GET /dashboard/core-configuration` | `central.dashboard.core-configuration` | auth, verified | `prime.dashboard.viewAny` | Core configuration sub-dashboard (menus, settings, languages, boards, sessions, dropdowns, roles, permissions) |
| `foundationSetup()` | `GET /dashboard/foundational-setup` | `central.dashboard.foundational-setup` | auth, verified | `prime.dashboard.viewAny` | Foundational setup sub-dashboard (roles, permissions, users, boards, sessions, plans, geography) |
| `subscriptionBilling()` | `GET /dashboard/subscription-billing` | `central.dashboard.subscription-billing` | auth, verified | `prime.dashboard.viewAny` | Subscription & billing sub-dashboard (tenants, plans, invoices, revenue) |
| `schoolSetup()` | `GET /dashboard/school-setup` | (inferred) | auth, verified | `prime.dashboard.viewAny` | School setup sub-dashboard — stub view |
| `operationManagement()` | `GET /dashboard/operation-management` | (inferred) | auth, verified | `prime.dashboard.viewAny` | Operations management sub-dashboard — stub view |

### 2.2 PrimeAuthController

| Method | Route | Name | Middleware | Gate | Description |
|--------|-------|------|-----------|------|-------------|
| `index()` | `GET /login` | — | guest | None | Display login view; redirects to dashboard if already authenticated |
| `login()` | `POST /login` | `central.prime.login` | guest | None | Handle login request: authenticate, check active, check verified email, initiate 2FA if enabled |
| `otpChallenge()` | `GET /otp-challenge` | `central.prime.otp.challenge` | — (session-based) | None | Show OTP challenge page for 2FA |
| `sendLoginOtp()` | `POST /otp-challenge/send` | `central.prime.otp.send` | — (session-based) | None | Send OTP to user's registered mobile |
| `verifyLoginOtp()` | `POST /otp-challenge/verify` | `central.prime.otp.verify` | — (session-based) | None | Verify OTP and complete login |
| `logout()` | `POST /logout` | `central.prime.logout` | auth | None | Destroy authenticated session |

### 2.3 Route Definitions (from Module routes)

```php
// Public
Route::get('/', [PrimeController::class, 'index'])->name('prime.index');

// Guest
Route::middleware('guest')->name('prime.')->group(function () {
    Route::get('login', [PrimeAuthController::class, 'index']);
    Route::post('login', [PrimeAuthController::class, 'login'])->name('login');
});

// OTP (session-based, no explicit middleware)
Route::name('prime.')->group(function () {
    Route::get('otp-challenge', [PrimeAuthController::class, 'otpChallenge'])->name('otp.challenge');
    Route::post('otp-challenge/send', [PrimeAuthController::class, 'sendLoginOtp'])->name('otp.send');
    Route::post('otp-challenge/verify', [PrimeAuthController::class, 'verifyLoginOtp'])->name('otp.verify');
});

// Authenticated
Route::middleware('auth')->name('prime.')->group(function () {
    Route::post('logout', [PrimeAuthController::class, 'logout'])->name('logout');
});
Route::get('/dashboard', [PrimeController::class, 'dashboard'])->middleware(['auth', 'verified', '2fa'])->name('prime.dashboard');
```

## 3. Business Rules (REQ-PRM-001, REQ-PRM-006, REQ-PRM-011, REQ-PRM-012)

| BR ID | Rule | Enforcement |
|-------|------|-------------|
| BR-PRM-018 | Test and debug routes (test email, test notification) must not be accessible on production — gated to local/staging | Route file environment check |
| BR-PRM-023 | All state-changing operations must produce an activity log entry | activityLog() helper |

## 4. Technical Implementation Details

### 4.1 Dashboard (`PrimeController::dashboard()`)

Aggregates comprehensive platform statistics in a single view:

| Data Point | Source | Details |
|-----------|--------|---------|
| Total Tenants | `Tenant::live()->count()` | Only live tenant records |
| Active Tenants | `Tenant::live()->where('is_active', true)->count()` | Tenants with is_active = true |
| Total Users | `User::count()` | All platform users |
| Active Users | `User::where('is_active', true)->count()` | Active platform users |
| Super Admins | `User::where('is_super_admin', true)->count()` | Count of super admins |
| Total Revenue | `TenantInvoice::sum('net_payable_amount')` | Sum of all invoice net amounts |
| Total Paid | `TenantInvoice::sum('paid_amount')` | Sum of all paid amounts |
| Overdue Invoices | `TenantInvoice::where('status', '!=', 'paid')->where('payment_due_date', '<', now())->count()` | Count of overdue |
| Active Plans | `TenantPlan::where('is_active', true)->count()` | Active plan subscriptions |
| Trial Plans | `TenantPlan::where('is_trial', true)->where('is_active', true)->count()` | Active trial plans |
| Auto-Renew Plans | `TenantPlan::where('auto_renew', true)->where('is_active', true)->count()` | Auto-renew enabled |
| Recent Tenants | `Tenant::live()->with('tenantGroup')->latest()->take(10)->get()` | Last 10 registered |
| Tenant Groups | `TenantGroup::withCount('liveTenants')->where('is_active', true)->orderByDesc(...)->get()` | Active groups with counts |
| Recent Invoices | `TenantInvoice::with('tenant')->latest('invoice_date')->take(10)->get()` | Last 10 invoices |
| Monthly Revenue (12m) | `TenantInvoice::selectRaw("DATE_FORMAT(invoice_date, '%Y-%m') as month, SUM(...)")->groupBy(...)->get()` | 12-month trend |
| Tenant Registration Trend (12m) | `Tenant::selectRaw("DATE_FORMAT(created_at, '%Y-%m') as month, COUNT(*)")->groupBy(...)->get()` | Registration trend |
| Recent Activities | `ActivityLog::with('user')->latest()->take(15)->get()` | Last 15 actions |
| Invoice Status Distribution | `TenantInvoice::selectRaw("status, COUNT(*)")->groupBy('status')->get()` | Pie chart data |
| Plan Distribution | `TenantPlan::select('plan_id', DB::raw('COUNT(*)'))->groupBy('plan_id')->get()` | Plan usage |
| User Role Distribution | `Role::withCount('users')->get()` | Role breakdown |
| Recent Payments | `TenantInvoice::with('tenant')->where('status', 'paid')->latest('invoice_date')->take(10)->get()` | Last 10 payments |
| Module Count | `collect(\Module::all())->count()` vs enabled | Module registry stats |
| Monthly Collection Rate | Computed percentage per month from monthlyRevenue | Collection efficiency |
| Notifications | `auth()->user()->notifications()->take(10)->get()` | Current user notifications |
| Unread Count | `auth()->user()->unreadNotifications()->count()` | Unread badge |

### 4.2 Authentication Flow

**Login flow (PrimeAuthController):**

1. `index()` — If already authenticated, redirect to dashboard; else show login view
2. `login()` — 
   - Uses `LoginRequest` (standard Laravel login request) for authentication
   - After Auth::attempt, checks `is_active` — if false, logout and redirect with error "Your account has been deactivated"
   - Checks `hasVerifiedEmail()` — if false, logout and redirect with error "Please verify your email address before logging in"
   - Checks `two_factor_auth_enabled` — if true:
     - Store `2fa:user_id` and `2fa:pending` in session
     - Auto-send OTP via `TwoFactorService::generateAndSendOtp()`
     - Redirect to OTP challenge page
   - If no 2FA: regenerate session and redirect to dashboard
   - Sends LoginNotification email + SMS via SendSmsJob

**OTP 2FA flow:**

1. `otpChallenge()` — Check session for `2fa:user_id`; if missing redirect to login
2. `sendLoginOtp()` — Validate user exists and has mobile; send OTP via TwoFactorService
3. `verifyLoginOtp()` — Validate OTP string (required, size:6); verify via TwoFactorService; on success: `Auth::loginUsingId()`, clear 2FA session keys, regenerate session, send login notification, redirect to dashboard

**Logout:** `Auth::guard('web')->logout()`, invalidate session, regenerate token, redirect to `/login`

**Error messages:**

| Scenario | Message |
|----------|---------|
| Account deactivated | "Your account has been deactivated. Please contact your administrator." |
| Email not verified | "Please verify your email address before logging in. Check your inbox for the verification link." |
| OTP session expired | "Session expired. Please log in again." |
| No mobile for 2FA | "No mobile number registered for 2FA. Contact administrator." |
| OTP send failure | "Failed to send OTP. Please try again." |
| Invalid/expired OTP | "Invalid or expired OTP. Please try again." |

### 4.3 Sub-Dashboards

| Dashboard View | Data Loaded |
|----------------|-------------|
| `coreConfiguration()` | Total/active/prime/tenant menus, menu categories, settings, languages, boards, sessions, dropdowns, roles, permissions, countries/states/districts/cities, recent activity |
| `foundationSetup()` | Roles, permissions, users (total/active), boards, sessions (total/current), plans (total/active/trial), geography, dropdowns, recent activity |
| `subscriptionBilling()` | Tenants (total/active), plans (total/active), tenant plans (total/active/trial/auto-renew), billing cycles, invoices (total/revenue/paid/outstanding/overdue), status distribution, recent invoices, recent activity |

### 4.4 Models Used

| Model | Table | Key Usage |
|-------|-------|-----------|
| `Modules\Prime\Models\User` | `sys_users` | Platform user authentication |
| `Modules\Prime\Models\Tenant` | `prm_tenant` | School tenant records |
| `Modules\Prime\Models\TenantGroup` | `prm_tenant_groups` | School groups |
| `Modules\Prime\Models\TenantInvoice` | `bil_tenant_invoices` | Invoice records |
| `Modules\Prime\Models\TenantPlan` | `prm_tenant_plan_jnt` | Tenant plan subscriptions |
| `Modules\Prime\Models\ActivityLog` | `sys_activity_logs` | Activity audit log |
| `Modules\Prime\Models\Menu` | `glb_menus` | Menu configuration |
| `Modules\Prime\Models\Setting` | `sys_settings` | Platform settings |
| `Modules\Prime\Models\Language` | `glb_languages` | Language records |
| `Modules\GlobalMaster\Models\Board` | `glb_boards` | Education boards |
| `Modules\Prime\Models\AcademicSession` | `sys_academic_sessions` | Academic sessions |
| `Modules\Prime\Models\Dropdown` | `sys_dropdown_table` | Dropdown values |
| `Modules\Prime\Models\Role` | `sys_roles` | Platform roles |
| `Modules\Prime\Models\Permission` | `sys_permissions` | Permissions |
| `Modules\GlobalMaster\Models\Plan` | `prm_plans` | Subscription plans |
| `Modules\Billing\Models\BillingCycle` | `prm_billing_cycles` | Billing cycles |

## 5. Feature Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `LoginRequest` | FormRequest | Standard email/password authentication validation |
| `TwoFactorService` | Service | OTP generation, sending, and verification for 2FA |
| `SendSmsJob` | Job | SMS dispatch for login notification |
| `LoginNotification` | Notification | Email notification on successful login |
| `Spatie Permission` | Package | Role-permission system used in dashboard distribution |
| `Module` facade | Laravel | Module registry count for system status |
| `User` model | Model | Notification relationship for bell icon |

## 6. Permissions

| Permission | Used In |
|-----------|---------|
| `prime.dashboard.viewAny` | All dashboard views (coreConfiguration, foundationSetup, subscriptionBilling, schoolSetup, operationManagement, dashboard) |

## 7. Validation Rules (Auth)

| Field | Rule | Comment |
|-------|------|---------|
| email | Required, valid email | Via LoginRequest |
| password | Required, string | Via LoginRequest |
| otp (verify) | Required, string, size:6 | Via inline validation in `verifyLoginOtp()` |

## 8. Notifications & Mails

| Type | Trigger | Recipient | Content |
|------|---------|-----------|---------|
| `LoginNotification` | Successful authentication (non-2FA path) | User email | IP address + user agent + timestamp |
| SMS notification | Successful authentication (non-2FA path) | User mobile | IP address + timestamp + security warning |
| OTP SMS | 2FA flow initiation | User mobile | OTP code for login verification |

## 9. Workflow (Authentication)

| Step | Actor | Action / System Response |
|------|-------|--------------------------|
| 1 | User | Navigates to central domain login page |
| 2 | System | Shows login form (GET /login) |
| 3 | User | Submits email + password (POST /login) |
| 4 | System | Validates credentials via LoginRequest |
| 5 | System | Checks `is_active` flag — rejects if inactive |
| 6 | System | Checks `hasVerifiedEmail()` — rejects if unverified |
| 7 | System | If `two_factor_auth_enabled`: stores session vars, auto-sends OTP, redirects to challenge page |
| 8 | User | Enters OTP on challenge page (POST /otp-challenge/verify) |
| 9 | System | Verifies OTP via TwoFactorService; logs in user |
| 10 | System | Sends login notification (email + SMS) |
| 11 | System | Redirects to platform dashboard |
| 12 | User | Logs out (POST /logout) |
| 13 | System | Destroys session, regenerates token, redirects to /login |

## 10. Acceptance Criteria (REQ-PRM-006 & REQ-PRM-011)

| AC ID | Criteria |
|-------|----------|
| AC-006-01 | Given valid credentials on the central domain, the system establishes a session and redirects to the platform dashboard |
| AC-006-02 | Given valid school-staff credentials on a school subdomain, the system routes to the school's login page and does not access any Prime routes |
| AC-006-03 | Given an unauthenticated request to a protected Prime route, the system redirects to the Prime login page |
| AC-006-04 | Given a production environment, test and debug email/notification routes are not registered or return 404 |
| AC-006-05 | Given an authenticated user logs out, the session is destroyed and the user is redirected to the login page |
| AC-006-06 | Given a user with 2FA enabled submits valid credentials, the system displays the OTP challenge page and sends an OTP to the registered mobile number |
| AC-006-07 | Given a user submits a valid OTP on the challenge page, the system authenticates the user and redirects to the dashboard |
| AC-006-08 | Given a user submits an invalid/expired OTP, the system shows an error message and remains on the challenge page |
| AC-006-09 | Given a session expires during OTP challenge, the system redirects to login with "Session expired" error |
| AC-006-10 | Given a deactivated user attempts login, the system rejects with "Your account has been deactivated" |
| AC-006-11 | Given a user whose email is not verified attempts login, the system rejects with "Please verify your email address" |
| AC-006-12 | Given a user with 2FA enabled clicks "Resend OTP", the system sends a new OTP to the registered mobile |
| AC-011-01 | Given the dashboard loads, all metric cards show the current accurate count or monetary total without error |
| AC-011-02 | Given a new school is registered, the school registration trend chart updates on the next dashboard load |
| AC-011-03 | Given an invoice becomes overdue, it appears in the overdue invoice list on the next dashboard load |
| AC-011-04 | Given a user without "View Dashboard" permission, the dashboard returns 403 |

## 11. Edge Cases & Error Handling

| Scenario | Expected Behaviour |
|----------|-------------------|
| User already authenticated visits /login | Redirect to dashboard (PrimeAuthController.index) |
| 2FA user id not in session (session expired) during OTP challenge | Redirect to login with "Session expired" error |
| User has 2FA enabled but no mobile number | OTP send fails gracefully with log; user can manually request resend |
| TwoFactorService throws exception during auto-send | Error logged; user still redirected to OTP challenge page with "OTP sent" flash (auto-send failure is non-blocking) |
| Login notification email/SMS fails | Warning logged; login proceeds (non-blocking) |
| Dashboard query fails | Inline queries may throw; no special error handling — view may break |
| Multiple rapid OTP requests | Handled by TwoFactorService (rate limiting assumed) |

## 12. Future Enhancements (Auth & Dashboard)

| ENH ID | Enhancement | Details |
|--------|-------------|---------|
| ENH-PRM-005 | Full 2FA implementation | TwoFactorService exists but complete flow with backup codes, recovery, and admin reset needed |
| ENH-PRM-006 | Dashboard Query Caching | Cache revenue totals, monthly trend, and registration trend with 15-min TTL |
