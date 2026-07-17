# Laravel Dusk Test — Two Architectures & Authentication Improvement

> **For**: Senior Review  
> **Project**: Prime AI Academic Intelligence Platform  
> **Date**: 2026-07-11

---

## ⚠️ The Core Problem: Prime Side Has NO Login Implementation

### What Tenant Tests Have (works correctly)

```php
// Library / Cafeteria / HPC tests — setUp() initializes tenancy + user
protected function setUp(): void
{
    parent::setUp();
    $this->tenantBaseUrl = rtrim(env('DUSK_TENANT_URL', 'http://test.localhost:8000'), '/');
    $this->initializeTenantContext();          // ← tenancy::init() — binds tenant DB
    $this->adminEmail = 'root@tenant.com';     // ← tenant credentials
    $this->adminPassword = 'password';
    $this->resolveAdminUser();                 // ← finds user in tenant DB (sys_users)
}

// Then in tests — simple one-liner login:
$browser->loginAs($this->adminUser);    // ← DIRECT login, no form fill

**Result**: Tenant tests login in **1 step** — `loginAs()` works because tenancy is initialized and the user is bound to the tenant database (`sys_users` table).

---

### What Prime/Billing Tests Have (BROKEN)

```php
// Prime Billing tests — setUp() has NO tenancy, NO login
protected function setUp(): void
{
    parent::setUp();
    $this->centralBaseUrl = 'http://localhost:8000';   // ← Prime central URL
    $this->adminEmail = 'superadmin@prime.com';         // ← Prime central credentials
    $this->adminPassword = 'password';
    $this->resolveAdminUser();                          // ← finds user in central DB (prime_db)
    // ← NO tenancy::init()
    // ← NO loginAs()
    // ← NO authentication at all in setUp
}

// Then EVERY test method must manually login:
public function test_billing_cycle_10_index_loads(): void
{
    $this->browseWithFailureScreenshot('billing-cycle-index', function (Browser $browser): void {
        $this->authenticateCentral($browser);  // ← ALWAYS visits /login page
        $this->visitAuthenticated($browser, self::INDEX_PATH);
        // ...
    });
}

public function test_billing_cycle_11_create_page_loads(): void
{
    $this->browseWithFailureScreenshot('billing-cycle-create-page', function (Browser $browser): void {
        $this->authenticateCentral($browser);  // ← SAME login again
        $this->visitAuthenticated($browser, self::CREATE_PATH);
        // ...
    });
}
```

**Result**: Prime tests must call `authenticateCentral()` in **every single test method**. This:
1. Visits `/login` page every time (800ms waste)
2. Types email + password every time (1.2s waste)
3. Checks if login failed and falls back to `loginAs()` (another 800ms)
4. **~2-3 seconds added to every test method** just for login

---

### Side-by-Side Comparison

| Aspect | Tenant Tests (Library, etc.) | Prime Tests (Billing, etc.) |
|--------|------------------------------|------------------------------|
| **Login URL** | `http://test.localhost:8000/login` | `http://localhost:8000/login` |
| **Email** | `root@tenant.com` | `superadmin@prime.com` |
| **Password** | `password` | `password` |
| **Database** | Tenant DB (`sys_users` table) | Central DB (`prime_db`) |
| **Login mechanism** | `$browser->loginAs($user)` | `authenticateCentral($browser)` |
| **Where called** | `setUp()` or once per `browse()` | **Every test method** explicitly |
| **Form fill needed?** | ❌ No — direct session login | ✅ Yes — visits `/login`, types, submits |
| **Tenancy init?** | ✅ `tenancy::init()` | ❌ Not needed (central DB) |
| **Session reused?** | ✅ Yes — browser persists across tests | ❌ No — every method re-logins |
| **Time per test** | ~0.1s for login | **~2-3s** for login |
| **Code duplication** | Zero — inherited from base class | **Every test repeats** `authenticateCentral()` |

---

### Why This Design Exists (Historical Reason)

The Prime/Billing tests were originally written for a **central (non-tenant) database** — `prm_billing_cycles` lives in `prime_db`, not in a tenant database. Because `tenancy::init()` is never called, the default Laravel auth guard may not work reliably with `loginAs()`. The original developer chose form-based `authenticateCentral()` as a workaround.

**However**, `authenticateCentral()` was never made smart — it doesn't check if the browser is already logged in. It blindly visits `/login` on every invocation.

---

## Table of Contents

1. [Two Test Architectures](#1-two-test-architectures)
2. [Tenant-Based Tests](#2-tenant-based-tests)
3. [Central/Prime-Based Tests](#3-centralprime-based-tests)
4. [Current Authentication Flow (Prime/Billing)](#4-current-authentication-flow-primebilling)
5. [Problem with Current Approach](#5-problem-with-current-approach)
6. [Proposed Improvement: Smart Authentication](#6-proposed-improvement-smart-authentication)
7. [Implementation Options](#7-implementation-options)
8. [Recommendation](#8-recommendation)

---

## 1. Two Test Architectures

The project has **two distinct Dusk test architectures** that coexist:

| Feature | Tenant Tests | Central/Prime Tests |
|---------|-------------|---------------------|
| **Modules** | Library, Cafeteria, HPC, BehaviouralAssessment, etc. | Prime → Billing, Subscription, Invoicing, etc. |
| **Database** | Per-tenant databases (`sys_users`, `cht_*`, `lib_*`) | Central `prime_db` (`prm_billing_cycles`, `prm_plans`) |
| **URL** | `DUSK_TENANT_URL` → `http://test.localhost:8000` | `http://localhost:8000` (Prime central) |
| **Login page** | `http://test.localhost:8000/login` | `http://localhost:8000/login` |
| **Credentials** | `root@tenant.com` / `password` | `superadmin@prime.com` / `password` |
| **Auth** | `$browser->loginAs($user)` — direct session login | `authenticateCentral()` — visits `/login`, types credentials |
| **Tenancy** | MUST call `tenancy::init()` in setUp | MUST NOT initialize tenancy |

---

## 2. Tenant-Based Tests

### Typical setUp (most modules)

```php
protected function setUp(): void
{
    parent::setUp();

    $this->tenantBaseUrl  = rtrim(env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')), '/');
    $this->adminEmail     = 'root@tenant.com';       // ← Tenant credentials
    $this->adminPassword  = 'password';               // ← Tenant credentials

    $this->initializeTenantContext();                  // Binds tenant DB + domain (tenancy::init())
    $this->resolveAdminUser();                         // Finds/creates user in tenant DB (sys_users)
}

protected function tearDown(): void
{
    if (function_exists('tenancy') && tenancy()->initialized) {
        tenancy()->end();
    }
    parent::tearDown();
}
```

### Authentication in tenant tests

```php
// Tenant authentication — TWO options:

// Option A: Direct login (preferred — no form fill needed)
$browser->loginAs($this->adminUser);

// Option B: Form-based (fallback)
$browser->visit($this->tenantBaseUrl . '/login')
    ->type('email', 'root@tenant.com')     // ← Tenant email
    ->type('password', 'password')          // ← Tenant password
    ->press('Sign In')
    ->pause(1200);
```

Tenant tests can call `$browser->loginAs($user)` because `tenancy::init()` binds the tenant database, and the user record lives in the tenant's `sys_users` table. The session is stored per-tenant.

---

## 3. Central/Prime-Based Tests

### setUp in `prm_BillingDuskTestCase_TestCas.php`

```php
protected function setUp(): void
{
    parent::setUp();

    $this->centralBaseUrl  = 'http://localhost:8000';      // ← Prime central URL
    $this->adminEmail      = 'superadmin@prime.com';        // ← Prime central credentials
    $this->adminPassword   = 'password';                    // ← Prime central credentials

    $this->resolveAdminUser();   // Finds/creates user in central DB (prime_db)
    // NO tenancy::init() — central tables (prm_*) live in prime_db by default
}
```

### Why no `loginAs()`?

In central/prime context, `loginAs()` is unreliable because:
- The central auth guards may use different driver/session configuration than tenant
- No tenancy context → the user object is resolved from the default (central) connection (`prime_db`)
- The form-based login (`authenticateCentral()`) ensures the central auth guard processes the session correctly

### Current `authenticateCentral()` flow

```php
// Credentials used:
//   URL:    http://localhost:8000/login  (Prime central)
//   Email:  superadmin@prime.com
//   Pass:   password

protected function authenticateCentral(Browser $browser): void
{
    // Step 1: Visit Prime central login page
    $browser->visit($this->centralUrl('/login'))->pause(800);

    // Step 2: If login form is present, fill Prime admin credentials
    if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
        $browser->type('email', 'superadmin@prime.com')   // ← Prime credential
            ->type('password', 'password')                  // ← Prime credential
            ->press('Sign In')
            ->pause(1200);
    }

    // Step 3: If still on login page, fallback to loginAs()
    if (str_contains($this->currentPath($browser), '/login')) {
        if ($this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(800);
        }
    }
}
```

---

## 4. Current Authentication Flow (Prime/Billing) — Step-by-Step

```
  test_billing_cycle_10_index_loads()
      │
      ├─► browseWithFailureScreenshot('billing-cycle-index', callback)
      │       │
      │       ├─► authenticateCentral($browser)
      │       │       │
      │       │       ├─► visit http://localhost:8000/login    ← ALWAYS visits Prime login
      │       │       ├─► type 'superadmin@prime.com'          ← Prime email
      │       │       ├─► type 'password'                       ← Prime password
      │       │       ├─► press Sign In
      │       │       └─► check if still on /login              ← fallback
      │       │
      │       ├─► visitAuthenticated($browser, '/billing/billing-cycle')
      │       │       │
      │       │       ├─► visit URL
      │       │       ├─► if redirected to /login:
      │       │       │       ├─► authenticateCentral() again
      │       │       │       └─► visit URL again
      │       │
      │       ├─► assertSame('/billing/billing-cycle', currentPath)
      │       ├─► ensurePageAccessible($browser, ...)
      │       └─► assertSee('Billing Cycles')
      │
      └─► (end browseWithFailureScreenshot)
```

### Key observation

**`authenticateCentral()` is called at the top of EVERY test method**, even if the browser session is already authenticated from a previous test. This is wasteful and fragile.

---

## 5. Problem with Current Approach

| Issue | Description |
|-------|-------------|
| **Redundant login** | Every test calls `authenticateCentral()` regardless of session state |
| **Extra page navigations** | Visiting `/login` when already authenticated adds 800ms-2s per test |
| **Session dependency** | Between-test session state is undefined — Dusk may or may not persist cookies |
| **No "check then act"** | The code always tries to login first, then falls back to `loginAs()`. There is no "is already logged in?" check. |

---

## 6. Proposed Improvement: Smart Authentication

### Concept

```
isAuthenticated($browser)
    │
    ├─► YES ──► skip login, proceed to test
    │
    └─► NO ──► try form-based login
                  │
                  ├─► SUCCESS ──► proceed
                  │
                  └─► FAIL ──► fallback to loginAs()
```

### Two approaches

### Approach A: Cookie-based check

Check if the browser already has a valid session cookie before attempting login.

```php
protected function isAuthenticated(Browser $browser): bool
{
    // Check if a session cookie exists (name varies by config)
    $cookies = $browser->driver->manage()->getCookies();
    foreach ($cookies as $cookie) {
        // Laravel session cookie name is usually 'prime_session' or 'laravel_session'
        if (str_contains($cookie->getName(), 'session')) {
            return true;
        }
    }
    return false;
}
```

**Limitation**: A stale/expired cookie would return false positive.

### Approach B: Page-check after visit

Navigate to the target page and check whether it redirects to login. This is what `visitAuthenticated()` already does internally, but only after the initial `authenticateCentral()` call.

**This is the cleaner approach** because it tests actual page access, not cookie presence.

### Approach C: Check current page path before acting

```php
protected function ensureAuthenticated(Browser $browser): void
{
    // Step 1: Check current page — are we already logged in?
    if (!str_contains($this->currentPath($browser), '/login')) {
        return;  // Already authenticated
    }

    // Step 2: Try form-based login
    $this->fillLoginForm($browser);

    // Step 3: If still on login page, use loginAs() fallback
    if (str_contains($this->currentPath($browser), '/login')) {
        if ($this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(800);
        }
    }
}

protected function fillLoginForm(Browser $browser): void
{
    if (!$browser->element('input[name="email"]')) {
        return;
    }
    // Prime central credentials
    $browser->type('email', 'superadmin@prime.com')   // ← Prime email
        ->type('password', 'password')                 // ← Prime password
        ->press('Sign In')
        ->pause(1200);
}
```

---

## 7. Implementation Options

### Option 1: Refactor `authenticateCentral()` to be idempotent

Rename to `ensureAuthenticatedCentral()` and add a guard at the top:

```php
// Credentials: superadmin@prime.com / password
// URL:         http://localhost:8000/login

protected function ensureAuthenticatedCentral(Browser $browser): void
{
    // Already authenticated — skip
    if ($browser->element('body') && !str_contains($this->currentPath($browser), '/login')) {
        return;
    }

    // Visit Prime central login page
    $browser->visit($this->centralUrl('/login'))->pause(800);

    // Fill form with Prime credentials
    if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
        $browser->type('email', 'superadmin@prime.com')   // ← Prime email
            ->type('password', 'password')                 // ← Prime password
            ->press('Sign In')
            ->pause(1200);
    }

    // Fallback
    if (str_contains($this->currentPath($browser), '/login')) {
        if ($this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(800);
        }
    }
}
```

Then in tests:
```php
$this->browseWithFailureScreenshot('billing-cycle-index', function (Browser $browser): void {
    $this->ensureAuthenticatedCentral($browser);  // Only logs in if needed
    $this->visitAuthenticated($browser, self::INDEX_PATH);
    // ... assertions
});
```

### Option 2: Make `visitAuthenticated()` handle the full flow

This is already partially implemented — `visitAuthenticated()` already checks for login redirect after visiting. The missing piece is that `authenticateCentral()` is called separately first. The improvement would be to merge them:

```php
protected function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
{
    $browser->visit($this->centralUrl($path))->pause($pauseMs);

    if (str_contains($this->currentPath($browser), '/login')) {
        $this->authenticateCentral($browser);          // uses smart check inside
        $browser->visit($this->centralUrl($path))->pause($pauseMs);
    }
}
```

### Option 3: `loginAs()` with central guard

If the central auth guard supports it, skip form login entirely and use `loginAs()` with the correct guard:

```php
// Prime central: superadmin@prime.com / password
protected function authenticateCentral(Browser $browser): void
{
    if ($this->adminUser) {
        $browser->loginAs($this->adminUser);  // try direct login (no guard specified)
    }
}
```

**Risk**: `loginAs()` may not work with the central auth guard because:
- No `tenancy::init()` context → the auth system may resolve against the wrong user provider
- The central guard (`prime`) may require a different session driver than the default `web` guard
- If it fails, the browser stays unauthenticated with no fallback

**Recommendation**: Only use Option 3 after confirming `loginAs()` works with `http://localhost:8000` and `superadmin@prime.com`.

---

## 8. Recommendation

### Short-term fix (current bug)

Fix the `extends` clause in both base classes so the inheritance chain is correct (see separate analysis in `dusk_test_architecture_analysis.md`).

### Medium-term improvement

Adopt **Option 1** — rename `authenticateCentral()` → `ensureAuthenticatedCentral()` with an early-return guard:

```php
// In prm_BillingDuskTestCase_TestCas.php

protected function ensureAuthenticatedCentral(Browser $browser): void
{
    // Guard: already on an authenticated page
    if (!$this->isOnLoginPage($browser)) {
        return;
    }

    $this->authenticateCentral($browser);
}

private function isOnLoginPage(Browser $browser): bool
{
    return str_contains($this->currentPath($browser), '/login')
        || ($browser->element('input[name="email"]')
            && $browser->element('input[name="password"]'));
}
```

Then in test methods, replace:
```php
$this->authenticateCentral($browser);
$this->visitAuthenticated($browser, self::INDEX_PATH);
```
with:
```php
$this->visitAuthenticated($browser, self::INDEX_PATH);
```

And let `visitAuthenticated()` handle the authentication check internally (which it already does after visiting).

### Long-term

Evaluate whether `loginAs()` works reliably with the central auth guard. If it does, the entire form-based flow can be replaced with a one-liner, eliminating page navigations entirely from test setUp.

---

## Appendix: Architecture Decision Matrix

| Approach | Complexity | Reliability | Speed | Session-aware |
|----------|-----------|-------------|-------|---------------|
| Current (`authenticateCentral` first) | Low | High | Slow (always logs in) | ❌ |
| Option 1 (guard + act) | Low | High | Medium (skips if auth'd) | ✅ |
| Option 2 (visitAuthenticated only) | None | High | Medium | ✅ |
| Option 3 (loginAs only) | Low | Unknown | Fast | ✅ |
| Smart (check + form + fallback) | Medium | Very High | Fast | ✅ |

---

*Analysis for senior review — prepared 2026-07-11*
