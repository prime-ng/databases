# prm_Email — Test Case List & Business Conditions

**Module:** Prime (PRM) · central / `prime_db` · Host `http://127.0.0.1:8000`
**Feature (screen):** Email — debug/preview + send-test tooling (TABLELESS ACTION screen)
**Primary source:** `Modules/Prime/app/Http/Controllers/EmailController.php`
**Prefix:** `prm_` (Prime central; no domain table for this feature)
**Test file:** `prm_Email_TestCas.php` (single comprehensive suite — no V1/V2)
**Screen type:** Tableless action/read screen → **no schema CRUD matrix**; coverage is route/gate/action/security-focused.

---

## 0. Screen Facts (verified from source)

| Fact | Value | Source |
|------|-------|--------|
| Preview route | `central.dashboard.test-email` → `GET /dashboard/test-email` | routes/web.php:100 |
| Send route | `central.dashboard.send-test-email` → `GET /dashboard/send-test-email` | routes/web.php:101 |
| Route guard | `if (app()->environment(['local','staging','testing']))` | routes/web.php:99 |
| Group middleware | `auth`, `verified` | routes/web.php:83 |
| Preview gate | `prime.email.viewAny` (`Gate::authorize`) | EmailController.php:15 |
| Send gate | `prime.email.create` (`Gate::authorize`) | EmailController.php:71 |
| Gate definitions | `Gate::define('prime.email.viewAny'/'create', PrimeEmailPolicy::…)` | PrimeServiceProvider.php:88-89 |
| Policy | `PrimeEmailPolicy::viewAny/create` → `$user->can(...)` | PrimeEmailPolicy.php:12-23 |
| Mailable | `Modules\Prime\Emails\LoginMail` (implements `ShouldQueue`) | LoginMail.php:10 |
| View | `prime::email.test-email` (`x-backend.email.template`) | test-email.blade.php:1 |
| Send recipient | **hardcoded** `primegurukul@yopmail.com` | EmailController.php:73,116 |
| Send response | literal string `"Email Sent"` | EmailController.php:128 |
| Activity log | none written by this controller | EmailController.php (no `activityLog()` call) |

---

## 1. Business Conditions

### BC-CFG (configuration / wiring)

| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | `central.dashboard.test-email` route is registered (in an allowed env) | routes/web.php:100 |
| BC-CFG-02 | `central.dashboard.send-test-email` route is registered (in an allowed env) | routes/web.php:101 |
| BC-CFG-03 | `EmailController::testEmail()` and `sendTestEmail()` methods exist | EmailController.php:13,69 |
| BC-CFG-04 | Gates `prime.email.viewAny` and `prime.email.create` are defined | PrimeServiceProvider.php:88-89 |
| BC-CFG-05 | `PrimeEmailPolicy::viewAny/create` methods exist | PrimeEmailPolicy.php:12,20 |
| BC-CFG-06 | `LoginMail` mailable class exists | LoginMail.php:10 |
| BC-CFG-07 | `test-email` view references `x-backend.email.template` + `$title`/`$content` | test-email.blade.php |

### BC-BIZ (action behaviour)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `testEmail()` renders the HTML email preview (title "New Login Detected") | EmailController.php:17-66 |
| BC-BIZ-02 | Preview includes context badge "Security Alert" + "Login Details" info block | EmailController.php:23-53 |
| BC-BIZ-03 | `sendTestEmail()` returns the literal `"Email Sent"` | EmailController.php:128 |
| BC-BIZ-04 | `send-test-email` is registered as a **GET** verb | routes/web.php:101 |
| BC-BIZ-05 | `sendTestEmail()` dispatches a real `LoginMail` via `Mail::to()->send()` | EmailController.php:116 |

### BC-AUTH (authorization)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `testEmail()` authorizes `prime.email.viewAny` | EmailController.php:15 |
| BC-AUTH-02 | `sendTestEmail()` authorizes `prime.email.create` | EmailController.php:71 |
| BC-AUTH-03 | Policy methods delegate to `$user->can('prime.email.…')` | PrimeEmailPolicy.php:14,22 |
| BC-AUTH-04 | Guest hitting `test-email` is redirected to `/login` | routes/web.php:83 (`auth`) |
| BC-AUTH-05 | Guest hitting `send-test-email` is redirected to `/login` | routes/web.php:83 (`auth`) |

### BC-SEC (security — SEC-PRM-002 pack)

| ID | Condition | Source |
|----|-----------|--------|
| BC-SEC-01 | Both debug routes are wrapped by an `app()->environment([...])` guard → NOT registered in production (**refutes audit "no env guard"**) | routes/web.php:99 |
| BC-SEC-02 | `sendTestEmail()` sends mail to a **hardcoded** address | EmailController.php:73,116 |
| BC-SEC-03 | Send route is a side-effecting GET without CSRF (GET carries no token) | routes/web.php:101 |
| BC-SEC-04 | Preview content is entirely server-set → no user-controlled reflected-XSS surface | EmailController.php:17-66 |

> **State machine (BC-SM):** none — this feature has no status/workflow lifecycle.

---

## 2. Test Case List

### Positive / Config (TC-P)

| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-P01 | Config | BC-CFG-01..07 | routes/PSP/policy | Routes, gates, controller, policy, mailable wired | All present | `test_email_01…` | ✅ |
| TC-P02 | Config | BC-CFG-07 | blade | Preview view source present | Template + vars | `test_email_02…` | ✅ |
| TC-P03 | Action | BC-BIZ-01 | controller | Preview renders for authorized user | 200 + title | `test_email_10…` | ✅ |
| TC-P04 | Action | BC-BIZ-02 | controller | Preview has context + info sections | Both present | `test_email_11…` | ✅ |
| TC-P05 | Action | BC-BIZ-03 | controller | Send returns "Email Sent" | String shown | `test_email_12…` | ✅ |
| TC-P06 | Action | BC-BIZ-04 | routes | Send route is GET | GET verb | `test_email_13…` | ✅ |
| TC-P07 | Action | BC-BIZ-05 | controller | Send dispatches LoginMail (source) | Mail::to+LoginMail | `test_email_14…` | ✅ |

### Negative / Auth (TC-N)

| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-N01 | Auth | BC-AUTH-01 | controller | Preview gated by viewAny | Gate + source | `test_email_50…` | ✅ |
| TC-N02 | Auth | BC-AUTH-02 | controller | Send gated by create | Gate + source | `test_email_51…` | ✅ |
| TC-N03 | Auth | BC-AUTH-03 | policy | Policy maps to abilities | `can(...)` | `test_email_52…` | ✅ |
| TC-N04 | Auth | BC-AUTH-04 | routes | Guest redirected from preview | `/login` | `test_email_53…` | ✅ |
| TC-N05 | Auth | BC-AUTH-05 | routes | Guest redirected from send | `/login` | `test_email_54…` | ✅ |

### Security (TC-S) — SEC-PRM-002

| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-S01 | Security | BC-SEC-01 | routes | Env guard present (refutes audit) | Guard wraps routes | `test_email_90…` | ✅ |
| TC-S02 | Security | BC-SEC-02 | controller | Hardcoded recipient | address in source | `test_email_91…` | ✅ |
| TC-S03 | Security | BC-SEC-03 | routes | Side-effecting GET, no CSRF | GET only | `test_email_92…` | ✅ |
| TC-S04 | Security | BC-SEC-04 | controller | No reflected XSS from query | Not reflected | `test_email_93…` | ✅ |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_email_01_routes_gates_controller_and_policy_configuration_are_correct` | TC-P01 | Config | 01-09 |
| 2 | `test_email_02_email_preview_view_source_is_present` | TC-P02 | Config | 01-09 |
| 3 | `test_email_10_test_email_route_renders_preview_for_authorized_user` | TC-P03 | Action | 10-19 |
| 4 | `test_email_11_preview_contains_context_and_info_sections` | TC-P04 | Action | 10-19 |
| 5 | `test_email_12_send_test_email_route_returns_email_sent` | TC-P05 | Action | 10-19 |
| 6 | `test_email_13_send_test_email_is_registered_as_get_verb` | TC-P06 | Action | 10-19 |
| 7 | `test_email_14_send_test_email_source_dispatches_login_mail` | TC-P07 | Action | 10-19 |
| 8 | `test_email_50_test_email_is_gated_by_view_any` | TC-N01 | Auth | 50-59 |
| 9 | `test_email_51_send_test_email_is_gated_by_create` | TC-N02 | Auth | 50-59 |
| 10 | `test_email_52_policy_methods_map_to_gate_abilities` | TC-N03 | Auth | 50-59 |
| 11 | `test_email_53_guest_is_redirected_from_test_email` | TC-N04 | Auth | 50-59 |
| 12 | `test_email_54_guest_is_redirected_from_send_test_email` | TC-N05 | Auth | 50-59 |
| 13 | `test_email_90_debug_routes_have_environment_guard_present` | TC-S01 | Security | 90-99 |
| 14 | `test_email_91_send_test_email_uses_hardcoded_recipient` | TC-S02 | Security | 90-99 |
| 15 | `test_email_92_send_route_is_side_effecting_get_without_csrf` | TC-S03 | Security | 90-99 |
| 16 | `test_email_93_preview_does_not_reflect_injected_query_input` | TC-S04 | Security | 90-99 |

**Total: 16 test methods.**

---

## 4. Known Source Defects (DEV / audit-equivalent)

| ID | Severity | Title | Proving test | Status |
|----|----------|-------|--------------|--------|
| SEC-PRM-002 | P1 → **downgraded** | Debug email routes exposed. Audit claim "NO environment guard" is **REFUTED by source** — an `app()->environment(['local','staging','testing'])` guard IS present (routes/web.php:99), so routes are absent in production. Residual valid smells: hardcoded recipient, side-effecting GET, `staging` allowed. | `test_email_90/91/92` | Documented (current behaviour) |
| DEV-PRM-EMAIL-001 | P2 | `sendTestEmail()` sends real mail to a hardcoded `primegurukul@yopmail.com` with no request input | `test_email_91` | Documented |
| DEV-PRM-EMAIL-002 | P3 | `PrimeEmailPolicy` type-hints `Modules\Prime\Models\User` while the central guard authenticates `App\Models\User`; a non-super-admin request could TypeError on `Gate::authorize`. **Candidate — verify in source at runtime.** | (cross-ref only) | Verify in source |
| BR-PRM-018 | — | "Debug/test routes must not reach production." **Passes** for production (env guard); residual risk on `staging`. | `test_email_90` | Documented |
