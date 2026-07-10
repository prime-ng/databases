# D4 — Security & Authorization Audit (READ-ONLY)

- **Target:** `/Users/bkwork/Herd/prime_ai` (Prime-AI, Laravel 12 / stancl-tenancy / laravel-modules)
- **Date:** 2026-07-02
- **Auditor:** Technical Auditor (parallel worker)
- **Baseline:** `AI_Brain/lessons/known-issues.md` → Platform-Wide Systemic Patterns (2026-06-27/06-30). Re-verified today.
- **Scope:** Authorization enforcement, mass-assignment, SQL injection, XSS, secrets, auth hardening, seeder/debug routes.

---

## VERDICT: NO-GO (production)

Two live P0s (committed `APP_KEY`; unauthenticated destructive seeder routes) plus a latent privilege-escalation vector block production. **However, the authorization posture has materially improved since the 2026-06-30 baseline** — the "authorization is a no-op, 13/13 modules" claim is **now stale**: controllers guard ~98% of write actions with `Gate::authorize()` string abilities. The remaining risk is concentrated (duplicate policy registrations, a few unguarded controllers, XSS on rich-text fields) rather than platform-wide.

**Counts:** P0 = 3 · P1 = 6 · P2 = 6 · P3 = 1

---

## Findings

| ID | Sev | Module/Area | Description | Evidence | Remediation | Effort |
|----|-----|-------------|-------------|----------|-------------|--------|
| GAP-D4-001 | P0 | Deploy / repo root | Committed `.env-original` contains a **live `APP_KEY=base64:...`** (signs URLs, decrypts cookies + `Encrypted` columns). Git-tracked. | `git ls-files` → `.env-original`; `APP_KEY=base64:[present]`, `APP_ENV=local` at repo root | Remove from VCS, purge history, **rotate `APP_KEY`**, add `.env*` (except `.env.example`) to `.gitignore` | S |
| GAP-D4-002 | P0 | routes/tenant.php + SeederController | **SEC-RTG-001 STILL LIVE.** 50 `SeederController` routes at `routes/tenant.php:319+` are **outside** the `auth` group (both the `guest` group and `auth` group close before line 319; seeder routes sit at top-level indent). `SeederController` has **0** env/guard checks. Any anonymous visitor on a tenant domain can trigger destructive demo-data seeding (`seeder/run`, `seeder/sync`, `seeder/dropdowns`, …). | `tenant.php:319` `Route::get('seeder',[SeederController::class,'panel'])` … 50 routes; `grep -c "environment(|abort(403|isProduction|abort_unless" SeederController.php` = **0** | Move all seeder routes inside `auth`+admin gate; add `abort_unless(app()->environment('local'), 403)` at top of every `SeederController` action | M |
| GAP-D4-003 | P0 | SchoolSetup + Prime (User models) | **Privilege-escalation vector.** `SchoolSetup/app/Models/User.php` `$fillable` includes `is_super_admin, super_admin_flag, password, user_type` (Prime/User.php identical). `AppServiceProvider.php:65` `Gate::before` grants **every** ability when `is_super_admin && super_admin_flag` are set. Any mass-assign path (`$request->all()`/`->fill()`) that reaches a User write = instant god-mode. No current `$request->all()` site targets User, so this is **latent, not yet exploited** — downgrade to P1 only after fillable is locked down. | `SchoolSetup/User.php:55-74` fillable; `AppServiceProvider.php:65-73` `if ($user->is_super_admin && $user->super_admin_flag) return true;` | Remove `is_super_admin`/`super_admin_flag`/`user_type` from `$fillable` on both User models; set these only via explicit guarded assignment; audit every User create/update to use `->validated()` | S |
| GAP-D4-004 | P1 | QuestionBank / Transport / Billing | **Duplicate `Gate::policy()` — last registration wins, earlier policies dead (SEC-PLATFORM-008 still live).** QNS: `QuestionBankPolicy` (SP:69) overwritten by `AiQuestionGeneratorPolicy` (SP:75), plus `AppServiceProvider:142` registers a 3rd (`AIQuestionPolicy`) for `QuestionBank::class`. Transport: `Vehicle::class` registered 5×, `TptTrip::class` 4×, `PickupPoint::class` 4×. Billing: `InvoicingPayment::class` 4×. Blast radius reduced because controllers mostly use string abilities, but any model-based `$this->authorize('x', $model)` uses the wrong policy. | `QuestionBankServiceProvider.php:69,75` + `AppServiceProvider.php:142`; `TransportServiceProvider.php:113,115,116,120,134-163`; `BillingServiceProvider.php:67-70` | One `Gate::policy()` per model; use ability-string permissions or model methods to distinguish sub-features; remove duplicates | M |
| GAP-D4-005 | P1 | Syllabus / StudentProfile | **Write controllers with no authorization primitive.** `Syllabus/CompetencieController` (also mass-assigns `$request->all()` at :142,151), `StudentProfile/StudentProfileController`, `StudentProfile/StudentReportController` — real-body store/update/destroy with no `authorize()`/`Gate`/`->can()`. | `Syllabus/CompetencieController.php:142,151`; `StudentProfile/StudentProfileController.php`; `StudentProfile/StudentReportController.php` | Add `Gate::authorize('module.entity.action')` to each write action | S |
| GAP-D4-006 | P1 | Platform (FormRequests) | **`authorize(){return true;}` systemic (D30).** 405 / 485 (83%) return hardcoded `true`; 73 implement real checks (Recommendation, Transport, Notification, Payment, LmsExam, Hpc); 5 have no `authorize()`; 2 conditional. Improved from baseline 437. Defense-in-depth gap where the consuming controller is also ungated. | PHP scan of all `extends FormRequest`: `return_true=405 real_check=73` | Make `authorize()` return `Gate::allows('module.entity.action')`; prioritise requests whose controller action lacks a gate (cross-ref GAP-D4-005) | L |
| GAP-D4-007 | P1 | repo root | **Committed plaintext credentials.** `TENANT_ADMIN_CREDENTIALS.md` (git-tracked) ships tenant admin login `root@tenant.com` / `password` — the file even carries a "do not commit" warning it violates. | `git ls-files` → `TENANT_ADMIN_CREDENTIALS.md`; contents show plaintext email+password | Remove from VCS, purge history, rotate the seeded admin password, move to a local-only note | S |
| GAP-D4-008 | P1 | StudentFee | **Hardcoded Razorpay test key in seeder source.** `rzp_test_SJz4k2znpMUorc` committed. | `StudentFee/database/seeders/PaymentGatewaySeeder.php:22,52` | Read from `config('services.razorpay.key')`/env; never literal-embed gateway keys | S |
| GAP-D4-009 | P1 | Platform (Blade) | **XSS surface on raw rich-text output.** Of 600 `{!! !!}` uses (255 files): ~196 are `json_encode`/`->render()`/`->links()`/`csrf` (safe/P2), 30 `nl2br(e(...))` (escaped — safe). ~30-45 emit **raw user/teacher-authored content**: `question->question_content`, `question->teacher_explanation`, `article/selectedArticle->content`, `template->body`, `complaint->description`, `homework->description`, `consentForm->content`, `category->description`, `option->option_text`, `material->content_text`. Injectable fraction ≈ 5-8%. Free-text fields (e.g. `complaint->description`) are clear stored-XSS; WYSIWYG fields need server-side sanitisation not escaping. | e.g. `{!! $complaint->description !!}`, `{!! $question->question_content !!}`, `{!! $template->body !!}` (grep of `Modules/*/resources/views`) | Run all rich-text through HTMLPurifier on render (or on save); escape plain free-text fields with `{{ }}`/`e()` | M |
| GAP-D4-010 | P2 | Platform (mass-assign, D25) | **21 live `create/update($request->all())` sites** (GlobalMaster heaviest: Country/State/City/Module/Plan/Board/AcademicSession; Prime: AcademicSession/Board/Menu/TenantGroup; Syllabus: Competencie; SystemConfig: Menu). None of these target privilege-bearing models, so P2 (would be P0 if pointed at User — see GAP-D4-003). | `GlobalMaster/*Controller.php:39-88`; `Prime/*Controller.php:42-162`; `Syllabus/CompetencieController.php:142,151`; `SystemConfig/MenuController.php:127` | Replace with `$request->validated()` | M |
| GAP-D4-011 | P2 | Config (session) | Session cookie hardening weak defaults: `SESSION_SECURE_COOKIE` has **no default** (null → cookies sent over HTTP), `SESSION_ENCRYPT` default `false`, `same_site=lax`. | `config/session.php:172 'secure'=>env('SESSION_SECURE_COOKIE')`, `:50 'encrypt'=>env(...,false)` | Force `secure=true` in prod, enable `SESSION_ENCRYPT=true`, consider `same_site=strict` for admin | S |
| GAP-D4-012 | P2 | Certificate (uploads) | File-upload actions with **no `mimes`/`max` validation** — unrestricted upload type/size. | `Certificate/CertificateRequestController.php` rules=0; `Certificate/CertificateIssuedController.php` rules=0 (vs CommonChat/Accounting which validate) | Add `mimes:pdf,jpg,png|max:5120` (or per-need) + store in tenant path | S |
| GAP-D4-013 | P2 | Auth (password rules) | Inconsistent password policy: web auth uses `Password::defaults()` (good) but `SchoolSetup/UserRequest`, `Prime/UserRequest`, `StudentProfile/StudentController` use bare `min:8` with no complexity. | `SchoolSetup/UserRequest.php:22`; `StudentProfile/StudentController.php:606,689` | Standardise on `Password::defaults()` (mixedCase + numbers + uncompromised) everywhere | S |
| GAP-D4-014 | P2 | Mobile API | Mobile login `POST auth/login` has **no `throttle` middleware** (web login IS rate-limited via Breeze `LoginRequest::ensureIsNotRateLimited`, 5 attempts — not a finding). | `routes/api.php:16` (no throttle); vs `app/Http/Requests/Auth/LoginRequest.php:42,68-76` (web protected) | Add `throttle:5,1` to the mobile login route + per-account limiter | S |
| GAP-D4-015 | P2 | QuestionBank | `env()` outside config: `env('CHATGPT_API_KEY')` / `env('GEMINI_API_KEY')` in a controller → returns `null` after `config:cache` (AI silently breaks) and reads secrets directly. Not a hardcoded secret (baseline "QNS secrets in source" is stale). | `QuestionBank/AIQuestionGeneratorController.php:531,578` | Move to `config('services.*')`; never call `env()` outside `config/` | S |
| GAP-D4-016 | P3 | Auth (Gate::before design) | `Gate::before` super-admin bypass is correct but total: a mis-set flag or over-broad "Super Admin" role grants everything. Note for review, not a defect. | `AppServiceProvider.php:65-73` | Keep, but ensure flags/role are never user-settable (ties to GAP-D4-003) | — |

---

## Task-by-task results & counts

### 1. Authorization enforcement — BASELINE CORRECTION
Controllers now guard the overwhelming majority of write actions with `Gate::authorize('module.entity.action')` string abilities. **Guarded / total write methods (real-body store/update/destroy) per sampled module:**

| Module | Guarded / Total writes | Policy classes | Live `Gate::policy` | Controller authorize() calls |
|--------|-----------------------|----------------|---------------------|------------------------------|
| SchoolSetup | 131 / 137 | 44 | 39 | 527 |
| StudentProfile | 8 / 9 | 2 | 2 | 70 |
| QuestionBank | 18 / 18 | 10 | 9 | 84 |
| TimetableFoundation | 73 / 73 | 23 | **5** (18 dead) | 290 |
| Syllabus | 39 / 42 | 18 | 16 | 156 |
| StudentFee | 34 / 34 | 15 | 14 | 137 |
| Vendor | 17 / 17 | 7 | 7 | 62 |
| Library | 95 / 95 | 31 | 31 | 414 |
| Hostel | 106 / 107 | 20 | 20 | 184 |
| Inventory | 41 / 41 | 16 | 16 | 184 |
| **Total (10)** | **562 / 573 (98%)** | — | — | — |

Nuance: authorize calls are **string-ability** based (e.g. `Gate::authorize('timetable-foundation.period-config.create')`), which depend on Spatie permissions + role seeding + no typos (D24 risk) rather than on the `Gate::policy(Model,Policy)` map. Model-based policy registration is where the live defects remain (GAP-D4-004): TTF has 23 policy classes but only 5 registered (18 dead); QNS/Transport/Billing have duplicate registrations. Unguarded remainder → GAP-D4-005.

### 2. FormRequest `authorize()`
485 FormRequests: **405 return `true` (83%)**, 73 real checks, 5 no `authorize()` method, 2 conditional. (Baseline 437/485.) → GAP-D4-006.

### 3. Mass assignment
21 live `$request->all()` write sites (GAP-D4-010). Privilege-field models re-verified today: `SchoolSetup/User.php` **CONFIRMED** (`is_super_admin, super_admin_flag, password, user_type` fillable); `Prime/User.php` identical. **`StudentProfile/User.php` does NOT exist** (baseline stale — StudentProfile has no User model). None of the 21 `$request->all()` sites target a User model, so the priv-esc vector is latent (GAP-D4-003), and the 21 sites themselves are P2.

### 4. SQL injection
48+ raw-SQL-with-variable sites triaged. **Injectable count: 0.** All are safe: static SQL (`whereRaw('0=1')`, `'1 = 0'`), internal table-name interpolation (`PeriodSetPeriod` `{$cfgTable}`/`{$jntTable}`), `(float)`-cast values (`VoucherService:108 $delta`), `int`-typed params (`Hpc/PeerAssignmentService:30,31 {$classSectionId}` — method sig `int`), internal ID maps (`Hostel/HostelAttendanceReportService {$map[...]}` from `getStatusCodeToIdMap()`), and `->toSql()` subqueries. No user input reaches a raw string. Strong negative finding.

### 5. XSS
600 `{!! !!}` matches across 255 files: ~196 `json_encode`/`render`/`links`/`csrf` (safe or P2), 30 `nl2br(e(...))` (escaped, safe), ~30-45 raw model rich-text/free-text outputs = the real surface. Estimated injectable fraction **≈ 5-8%**. → GAP-D4-009.

### 6. Secrets
- `.env-original` committed with live `APP_KEY` → P0 (GAP-D4-001). CONFIRMED.
- `TENANT_ADMIN_CREDENTIALS.md` committed, plaintext admin creds → P1 (GAP-D4-007). CONFIRMED.
- `StudentFee/PaymentGatewaySeeder.php` `rzp_test_...` → P1 (GAP-D4-008).
- **QuestionBank hardcoded secrets: NOT present today** (baseline stale); only `env()`-outside-config (GAP-D4-015).
- `.env.dusk.local` git-tracked (Dusk test env) — review for stray secrets (low risk).

### 7. Auth hardening
- Login rate limiting: **PRESENT** (web, Breeze `LoginRequest`, 5 attempts) — not a finding. Mobile API login unthrottled → P2 (GAP-D4-014).
- Password rules: mixed (GAP-D4-013, P2).
- Session config: weak cookie defaults (GAP-D4-011, P2).
- **CSRF exemptions: none found** (no `VerifyCsrfToken $except`) — GOOD.
- File-upload validation: inconsistent, Certificate controllers unvalidated (GAP-D4-012, P2).

### 8. Seeder/debug routes
- SEC-RTG-001 **STILL LIVE** — 50 unauthenticated destructive seeder routes, SeederController 0 guards → P0 (GAP-D4-002). CONFIRMED.
- `test-runner` routes (`tenant.php:372`) are inside an `auth` group — OK.
- Route closures in `routes/*.php` (break `route:cache`) are a D12/deployment concern, out of D4 core scope — noted for the deployment auditor.

---

## Deviations from baseline (re-verified today)
1. **"Authorization is a no-op, 13/13 modules" — OUTDATED.** Controllers now guard ~98% of writes. Real remaining auth defects are duplicate/dead policy registrations (GAP-D4-004) and a few unguarded controllers (GAP-D4-005).
2. **FormRequest `true` count dropped** 437 → 405; 73 now implement real checks.
3. **`StudentProfile/User.php` does not exist** — baseline privilege-field claim applies to `SchoolSetup/User.php` + `Prime/User.php`.
4. **QuestionBank hardcoded secrets gone** — now only `env()`-outside-config.
5. **No injectable SQL** despite 48 raw sites.
