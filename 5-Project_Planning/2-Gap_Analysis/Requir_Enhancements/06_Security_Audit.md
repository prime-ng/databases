# 06 — Security Audit

## Summary

| Severity | Count |
|----------|-------|
| Critical | 4 |
| High | 4 |
| Medium | 4 |
| **Total** | **12** |

**Critical issues requiring immediate attention:** SEC-002, SEC-004, SEC-005, SEC-008

---

## SEC-001: Mass Assignment Vulnerability in TenantController

| Field | Detail |
|-------|--------|
| **Severity** | High |
| **File** | `Modules/Prime/app/Http/Controllers/TenantController.php`, lines 53 and 90 |
| **Method** | `TenantController::store()` and `TenantController::update()` |
| **Problem** | Both methods use `$request->all()` instead of `$request->validated()` even though a `TenantRequest` form request is type-hinted. This means ALL submitted fields are passed to `Tenant::create()` / `$tenant->update()`, bypassing the form request validation rules. An attacker could inject extra fields (e.g., `is_active`, `id`, `tenant_group_id`) that should not be user-controllable. |
| **OWASP** | A03:2021 — Injection |
| **Fix** | Change `$request->all()` to `$request->validated()` on lines 53 and 90. |

---

## SEC-002: Sensitive Fields in User $fillable (Privilege Escalation)

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **File** | `app/Models/User.php`, lines 35-54 |
| **Property** | `User::$fillable` |
| **Problem** | The `$fillable` array includes `is_super_admin`, `super_admin_flag`, `is_active`, `status`, `remember_token`, and `password`. Any controller using `$request->all()` or similar mass assignment could allow a user to escalate privileges by setting `is_super_admin = true` or `super_admin_flag = true`. The `remember_token` being fillable is particularly dangerous as it could allow session hijacking. |
| **OWASP** | A01:2021 — Broken Access Control |
| **Fix** | Remove `is_super_admin`, `super_admin_flag`, `remember_token`, and `password` from `$fillable`. Set these through explicit assignment only. |

---

## SEC-003: Super Admin Gate Bypass

| Field | Detail |
|-------|--------|
| **Severity** | High |
| **File** | `app/Providers/AppServiceProvider.php`, lines 371-375 |
| **Method** | `AppServiceProvider::boot()` |
| **Problem** | `Gate::before()` returns `true` for any user with the "Super Admin" role, bypassing ALL authorization checks including tenant-scoping checks. Combined with SEC-002 (is_super_admin in $fillable), an attacker who can mass-assign `is_super_admin` effectively gains unrestricted access to the entire platform. |
| **OWASP** | A01:2021 — Broken Access Control |
| **Fix** | Tighten the Gate::before callback. Avoid blanket bypasses. |

---

## SEC-004: Payment Webhook Behind Auth Middleware

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **File** | `routes/tenant.php`, line 295 |
| **Problem** | The webhook route `Route::post('/payment/webhook/{gateway}', ...)` is inside a `Route::middleware(['auth', 'verified'])` group. Payment gateway webhooks (e.g., Razorpay) are server-to-server callbacks that cannot authenticate as a user. This means ALL webhook calls from Razorpay will fail with a 401/302 response, and payment status updates will never be processed. |
| **OWASP** | A07:2021 — Identification and Authentication Failures |
| **Fix** | Move the webhook route outside the auth middleware group. Rely on the signature verification already implemented in `handleWebhook()`. |

---

## SEC-005: Webhook Signature Verification Only for Razorpay

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **File** | `Modules/Payment/app/Http/Controllers/PaymentController.php`, lines 74-92 |
| **Method** | `PaymentController::handleWebhook()` |
| **Problem** | Signature verification is only performed when `$gateway === 'razorpay'`. The `{gateway}` route parameter is user-controlled. An attacker can send `POST /payment/webhook/not_razorpay` with a crafted payload to skip signature verification entirely, then inject fake `payment.captured` events to mark arbitrary orders as paid. |
| **OWASP** | A02:2021 — Cryptographic Failures |
| **Fix** | Either verify signatures for ALL gateways or reject unknown gateway values with a whitelist. |

---

## SEC-006: Error Message Leaks Stack Trace

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **File** | `Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php`, line 920 |
| **Problem** | `env('APP_DEBUG')` is used in a controller to conditionally include `$e->getTraceAsString()` in API responses. Using `env()` outside config files can return `null` after config caching, and the stack trace could leak internal paths, database credentials, and class names. |
| **OWASP** | A05:2021 — Security Misconfiguration |
| **Fix** | Use `config('app.debug')` instead of `env('APP_DEBUG')`, and never expose stack traces in production API responses. |

---

## SEC-007: Mass Assignment in MenuController::update()

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **File** | `Modules/SystemConfig/app/Http/Controllers/MenuController.php`, line 127 |
| **Method** | `MenuController::update()` |
| **Problem** | Uses `$menu->update($request->all())` instead of `$request->validated()`, despite having a `MenuRequest` form request. This allows setting any fillable field on the Menu model, potentially including fields controlling navigation visibility, module access, or URL routing. |
| **Fix** | Change to `$menu->update($request->validated())`. |

---

## SEC-008: Unauthenticated Seeder Route Exposed in Tenant Context

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **File** | `routes/tenant.php`, line 2627 |
| **Method** | `SeederController::run()` |
| **Problem** | `Route::get('seeder/run', [SeederController::class, 'run'])` is registered at the tenant route level with NO auth middleware. Anyone who can reach a tenant domain can call `GET /seeder/run` and execute database seeder operations, which inserts/updates records in `sch_class_groups_jnt` with random data. This is a data integrity issue and potential DoS vector. |
| **OWASP** | A01:2021 — Broken Access Control |
| **Fix** | Remove this route entirely, or protect it behind auth and super-admin role checks. |

---

## SEC-009: SmartTimetableController — Zero Authorization

| Field | Detail |
|-------|--------|
| **Severity** | High |
| **File** | `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` |
| **Method** | All 22 public methods |
| **Problem** | This 2,958-line controller has ZERO `Gate::authorize()` or `$this->authorize()` calls. Every method (including `generate()`, `storeTimetable()`, `timetableGeneration()`, `generateWithFET()`, and debug methods) is accessible to any authenticated user without role/permission checks. Any logged-in teacher, student, or staff member can generate, modify, or delete timetables. |
| **OWASP** | A01:2021 — Broken Access Control |
| **Fix** | Add `Gate::authorize()` calls with appropriate permissions to every public method. |

---

## SEC-010: Debug/Test Routes Exposed in Production

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **File** | `routes/tenant.php`, lines 281, 310, 1237, 1733 |
| **Problem** | Multiple test/debug routes are registered in the tenant route file: `GET test-notification` (line 281), `GET /seeder` (line 310, StudentFeeController::seederFunction), `GET test-notification` (line 1237), `GET test-seeder` (line 1733, SmartTimetableController::seederTest). These should not exist in production. |
| **Fix** | Remove all test/debug routes or gate them behind `APP_ENV=local` checks. |

---

## SEC-011: `env()` Used Directly in Route File

| Field | Detail |
|-------|--------|
| **Severity** | High |
| **File** | `routes/web.php`, line 62 |
| **Problem** | `Route::domain(env('APP_DOMAIN'))` uses `env()` directly. After running `php artisan config:cache`, `env()` returns `null` outside config files. This would cause the entire central route group to fail to register, breaking all central admin functionality. |
| **Fix** | Change to `config('app.domain')` and ensure `APP_DOMAIN` is mapped in `config/app.php`. |

---

## SEC-012: Payment Webhook Stores Raw Payload Before Verification

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **File** | `Modules/Payment/app/Http/Controllers/PaymentController.php`, lines 61-65 |
| **Method** | `PaymentController::handleWebhook()` |
| **Problem** | The raw payload is stored in `PaymentWebhook` (lines 61-65) BEFORE signature verification (lines 74-92). An attacker can flood the database with fake webhook records by sending arbitrary POST requests, causing storage exhaustion. |
| **Fix** | Move the `PaymentWebhook::create()` call to after successful signature verification. |

---

## Security Issue Summary Table

| ID | Severity | Category | OWASP | File |
|----|----------|----------|-------|------|
| SEC-001 | High | Mass Assignment | A03 | TenantController.php |
| SEC-002 | Critical | Privilege Escalation | A01 | User.php |
| SEC-003 | High | Auth Bypass | A01 | AppServiceProvider.php |
| SEC-004 | Critical | Broken Webhook | A07 | routes/tenant.php |
| SEC-005 | Critical | Signature Bypass | A02 | PaymentController.php |
| SEC-006 | Medium | Info Leak | A05 | AIQuestionGeneratorController.php |
| SEC-007 | Medium | Mass Assignment | A03 | MenuController.php |
| SEC-008 | Critical | Unauth Seeder | A01 | routes/tenant.php |
| SEC-009 | High | Missing AuthZ | A01 | SmartTimetableController.php |
| SEC-010 | Medium | Debug Routes | A05 | routes/tenant.php |
| SEC-011 | High | Broken Routing | A05 | routes/web.php |
| SEC-012 | Medium | DoS Vector | A04 | PaymentController.php |
