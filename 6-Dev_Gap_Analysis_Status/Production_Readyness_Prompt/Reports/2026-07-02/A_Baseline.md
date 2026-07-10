# Phase A — Baseline Sweeps
**Date:** 2026-07-02 · **Scope:** `/Users/bkwork/Herd/prime_ai` (APP_CODE) · Read-only

## Environment
- PHP 8.4.16 CLI · Composer 2.9.5 · Laravel (framework in `require`)
- `.env`: `APP_ENV=local`, `APP_DEBUG=true`, `DB_CONNECTION=mysql`, `QUEUE_CONNECTION=database`, `CACHE_STORE=database`, `SESSION_DRIVER=database`, `FILESYSTEM_DISK=local`, `MAIL_MAILER=smtp`
- `.env.example` has **44** keys vs `.env` **74** keys → **30 env keys undocumented** for a fresh deploy.

## Global counts (evidence: grep/find sweeps, this date)
| Sweep | Count | Notes |
|---|---:|---|
| PHP parse errors (full `php -l`, Modules+app) | **1** | `app/View/Components/hpc-form/PerformanceCard.php:3` — class name contains `-`, invalid PHP. Any autoload scan touching it fatals. |
| Live `dd(` in Modules | 10 | includes known BUG-LMS-001 pattern |
| `create/update/fill($request->all())` | 21 | mass-assignment sites |
| `whereRaw`/`DB::raw` containing `$` variable | 48 | injection-risk surface to triage |
| Unescaped Blade `{!! !!}` (excl. json/csrf) | 497 | XSS surface to triage |
| `env()` outside config/ | 8 | breaks `config:cache` |
| TODO/FIXME/HACK | 25 | |
| Controllers (Modules) | 732 | 590 contain some `authorize(`/`Gate::` token (registration≠enforcement — see D4) |
| FormRequests | 500 | authorize() posture verified in D4 |
| `EnsureTenantHasModule` usages (routes+providers) | **6** | up from 1 (2026-06-30 baseline) — still absent from vast majority of 45 modules |
| Central migrations / tenant migrations / module-level migrations | 13 / 713 / **49** | 49 module-level migrations contradict "centralized migrations" convention — verify they run on `tenants:migrate` |
| Seeders | 40 | |
| Tests: Browser repo / module tests / app tests | 319 / 112 / 437 files | pass/fail measured in D6 |
| Queued jobs (Modules) | 13 | tenancy-init posture in D3 |
| Scheduler entries (`routes/console.php`) | 5 | |

## Deploy-hygiene red flags (repo root)
- **`TENANT_ADMIN_CREDENTIALS.md` committed** (contains credentials by name) — P0 candidate.
- **`.env-original` committed** — known issue DEPLOY-ENV-02 (live APP_KEY; rotate).
- Stray files: `origin)`, `user`, `.tmp_cols.php`, `perfect_timetable_demo.php/.sql`, `log_bug.sh`, `query.sh`, `run_lda_learn.sh`, `web_12_01_2026.php` (stale route backup, 371 lines), `.codex`.
- **No CI/CD** (no .github/workflows, no GitLab/Jenkins/Envoy/Deployer files).
- **No container/provisioning config** (no Dockerfile/docker-compose).
- `laravel/telescope` and `laravel/horizon` in **production `require`** (telescope must be dev-only or gated); **Horizon requires redis but `QUEUE_CONNECTION=database`** — known issue DEPLOY-HRZ-01.
- `spatie/laravel-backup` present in require (good — configuration/verification in D10).
- Payment gateway: `razorpay/razorpay` in require (D5 scope).

## Route files
`routes/web.php` 1001 lines · `routes/tenant.php` 382 lines · stale `web_12_01_2026.php` 371 lines · `console.php` 58.

## Carried-in platform baseline (from `AI_Brain/lessons/known-issues.md`, verified 2026-06-30)
Systemic P0s to re-verify in Phase B/C, not re-discover: `EnsureTenantHasModule` absent (13/13 sampled), dead `Gate::policy()` registrations, FormRequest `authorize(){return true}` 437/485, VND plaintext PII, cross-layer `AcademicSession` imports (SLK), `is_super_admin` in `$fillable` (SCH+STD), tenant FKs → central tables (52), FKs → `sys_roles` with no migration (17), `tenancy()->initialize()` without `end()` (Prime DropdownNeedController), jobs without tenancy re-init (VND/INV/FOF/HST), seeder routes outside auth (SEC-RTG-001), committed `.env-original`.

**Phase A verdict: NOT-READY signals already present** — 1 fatal parse error, debug env defaults, credentials in repo, no CI, queue/Horizon mismatch. Domain audits follow.
