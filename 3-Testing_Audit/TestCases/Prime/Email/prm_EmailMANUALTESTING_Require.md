# prm_Email — Manual Testing Specification

**Module:** Prime (PRM) · CENTRAL (`prime_db`) · no tenant context
**Feature:** Email debug/preview + send-test (tableless action screen)
**Base URL:** `http://127.0.0.1:8000`

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Prime (central) |
| Feature | Email (debug/preview) |
| Preview URL | `GET /dashboard/test-email` (route `central.dashboard.test-email`) |
| Send URL | `GET /dashboard/send-test-email` (route `central.dashboard.send-test-email`) |
| Controller | `Modules\Prime\Http\Controllers\EmailController` (`testEmail`, `sendTestEmail`) |
| Policy / Gates | `PrimeEmailPolicy` → `prime.email.viewAny`, `prime.email.create` |
| Mailable | `Modules\Prime\Emails\LoginMail` (implements `ShouldQueue`) |
| View | `prime::email.test-email` |
| Models | none (no domain table) |
| Validation | none (both actions are parameterless GET) |
| Migrations | none for this feature |
| CRUD Type | **Action / read only** (no create/edit/delete) |
| Soft Delete | N/A |
| Pagination | N/A |
| Activity Log | none written by this controller |
| Route guard | `app()->environment(['local','staging','testing'])` — **not registered in production** |
| Middleware | `auth`, `verified` |
| Prereq | Prime module enabled in `modules_statuses.json`; `APP_ENV=testing`; super-admin / verified central user |

---

## 2. Business Conditions (detailed)

- **Preview (`testEmail`)** — authorizes `prime.email.viewAny`, then renders `prime::email.test-email` with a fixed payload: subject "Prime Email – Full Feature Preview", title "New Login Detected", a "Security Alert" context badge, a "Login Details" info block, and two CTA links. All values are server-set; there is **no request input**.
- **Send (`sendTestEmail`)** — authorizes `prime.email.create`, builds a `LoginMail` with the same static payload, calls `Mail::to('primegurukul@yopmail.com')->send(...)`, and returns the plain string `"Email Sent"`. The recipient is **hardcoded**; the queued-dispatch variants are commented out.
- **Authorization** — both routes sit inside the central `dashboard` group behind `auth` + `verified`. A guest is redirected to `/login`. A super-admin passes gates via the global Gate::before bypass.
- **Environment guard** — both `Route::get(...)` calls are inside `if (app()->environment(['local','staging','testing']))`, so in `production` the routes are never registered (a hit returns 404).

### SEC-PRM-002 — corrected statement
Audit text: *"testEmail()/sendTestEmail() are debug/test routes registered as production routes with NO environment guard."* — **The `NO environment guard` / `production` part is FALSE against current source** (routes/web.php:99 has the guard). Residual valid concerns: hardcoded recipient; side-effecting GET; `staging` is inside the allow-list.

---

## 3. Manual Test Cases

### MT-01 — Config truth (routes/gates/methods)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Boot app with `APP_ENV=testing` | App loads |
| 2 | Inspect route list (`php artisan route:list --name=email`) | `central.dashboard.test-email` (GET) and `central.dashboard.send-test-email` (GET) both present |
| 3 | Check gates | `prime.email.viewAny` + `prime.email.create` defined |
| 4 | Check classes | `EmailController::testEmail/sendTestEmail`, `PrimeEmailPolicy::viewAny/create`, `LoginMail` all exist |
| 5 | DB check | `SELECT` on `sys_central_activity_logs` — table exists (sink for central logs), though this controller writes none |

### MT-02 — Preview renders (authorized)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as super-admin | Dashboard visible |
| 2 | Visit `/dashboard/test-email` | HTTP 200 |
| 3 | Observe page | Shows "New Login Detected", "Security Alert" badge, "Login Details" info block |
| 4 | DB check | No new `sys_central_activity_logs` row (preview writes no log) |

### MT-03 — Send returns "Email Sent"
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as super-admin | Dashboard visible |
| 2 | Visit `/dashboard/send-test-email` | HTTP 200, body is exactly `Email Sent` |
| 3 | Mail check (dev inbox / yopmail) | A `LoginMail` is dispatched to `primegurukul@yopmail.com` (queue driver dependent) |

> Automation note: Dusk cannot assert `Mail::fake()` in a real browser. MT-03 step 3 is proven at **source level** (test_email_14) — the browser test only asserts the "Email Sent" response.

### MT-04 — Send route is a side-effecting GET
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect route verb | `send-test-email` = **GET** only (no POST) |
| 2 | Note | A GET that sends mail is a documented REST/CSRF smell (BC-SEC-03) |

### MT-05 — Preview gated by viewAny
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read controller | `Gate::authorize('prime.email.viewAny')` at method start |
| 2 | (If a limited user is available) hit `/dashboard/test-email` without the ability | 403 Forbidden |

### MT-06 — Send gated by create
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read controller | `Gate::authorize('prime.email.create')` at method start |
| 2 | (If a limited user is available) hit `/dashboard/send-test-email` without the ability | 403 Forbidden |

### MT-07 — Guest redirect (preview)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies / open incognito | No session |
| 2 | Visit `/dashboard/test-email` | Redirect to `/login` |

### MT-08 — Guest redirect (send)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies / open incognito | No session |
| 2 | Visit `/dashboard/send-test-email` | Redirect to `/login` |

### MT-09 — Environment guard present (SEC-PRM-002)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Grep `routes/web.php` around the email routes | `if (app()->environment(['local','staging','testing']))` wraps both `Route::get(...)` |
| 2 | Simulate `APP_ENV=production` and rebuild route cache | `route:list` shows NO `test-email`/`send-test-email` routes; a hit returns 404 |
| 3 | Conclusion | Audit "no env guard / production route" claim is **refuted**; residual smells (hardcoded recipient, GET, staging) remain |

### MT-10 — Hardcoded recipient (SEC-PRM-002 residual)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `EmailController::sendTestEmail()` | Recipient literal `primegurukul@yopmail.com` (line 73); `Mail::to($to)->send(...)` (line 116) |
| 2 | Note | No request parameter controls the recipient — DEV-PRM-EMAIL-001 |

### MT-11 — No reflected XSS from query input
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/dashboard/test-email?q=<script>zz</script>` (authorized) | Page renders normally |
| 2 | View source | The injected `<script>` is NOT reflected (preview content is server-set) |
