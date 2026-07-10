# Prime-AI — Production Readiness Report (Gap Register)
**Date:** 2026-07-02 · **Method:** 12-domain evidence-anchored audit (Phase A baseline + 9 parallel domain agents + P0 verification pass) · **Scope:** `/Users/bkwork/Herd/prime_ai` (45 modules), tenant/master DDLs, `prime_testing` · **Mode:** read-only

> Every finding cites a file/line or a count. Full per-domain detail in the sibling files `A_Baseline.md` and `D1…D12_*.md` in this folder.

---

## Executive Summary

**Overall verdict: 🔴 NOT PRODUCTION READY — NO-GO.**

The application does not build, deploy, provision a tenant, back up its data, or pass its own test suite. Every one of the 12 domains returned NOT-READY / NO-GO / FAIL. This is a functional-but-unhardened codebase (structural completeness ~82%) sitting on top of a **non-existent production operational layer**: no CI, no working backups, no error tracking, secrets in git, debug mode on, and two syntax errors that make `artisan optimize`/`route:cache` fatal.

| Metric | Value |
|---|---|
| Domains audited | 12 |
| Domains READY | **0** |
| Distinct P0 blockers (deduped) | **~20** |
| P1 critical findings | **~68** |
| P2 / P3 | ~40 / ~15 |
| Deployable today? | **No** — app won't `route:cache`; fresh tenant can't be migrated or seeded |
| Distance to production | **~5–7 calendar months** (≈20–30 focused engineer-weeks for P0+P1) with a small team |

### The 10 riskiest gaps (fix-first)
1. **Fresh-tenant provisioning is fatally broken** — `tenants:migrate` dies on 17 FKs → `sys_roles` (no create-migration exists); nothing calls `tenants:seed`; tenant seeder references 8 phantom classes. A new school cannot be onboarded at all. *(D2-001/002/003/004)*
2. **50 unauthenticated `SeederController` routes** at `routes/tenant.php:319+` — any anonymous visitor on a tenant domain can trigger destructive/bulk seeding; controller has zero guards. *(D4-002)*
3. **Payment can be forged** — Razorpay callback verifies the HMAC but never checks the returned order-id/amount against the stored order; a valid signature from a ₹10 payment confirms any large invoice. *(D5-001)*
4. **Payment double-credit race** — no lock, no status-transition guard, no unique constraint on payment reference; replayed/concurrent callbacks credit an invoice twice. *(D5-002)*
5. **Sensitive PII stored in plaintext** — Aadhaar (students/employees/applicants), PAN + bank account (employee/vendor), and special-category data (health, caste, religion, income) with no encryption; a DB dump = mass DPDPA breach. *(D11-001/002/003)*
6. **Secrets committed to git** — `.env-original` (live `APP_KEY`, `REDIS_PASSWORD`, `MAIL_PASSWORD`), `TENANT_ADMIN_CREDENTIALS.md` (plaintext admin login), `.env.dusk.local`. *(D4-001/D8-003/D12-001)*
7. **No tenant-data backup** — Spatie backs up only `prime_db`; per-tenant DBs are never backed up for new schools; backups write to local disk on the same server as MySQL and go to a queue no worker consumes. *(D10-001/002/004)*
8. **Two PHP parse errors make the app un-optimizable** — `RolePermissionController.php` (stray `r` before `<?php`) and `app/View/Components/hpc-form/PerformanceCard.php` (hyphen in namespace); `route:list`/`route:cache`/`optimize` exit 255. *(D8-001/002)*
9. **Cross-DB tenancy breaches** — 189 tenant-scoped files import central `Prime\*`/`GlobalMaster\*`/`Billing\*` models; 103 `Dropdown` sites are not connection-pinned → silent wrong-DB reads under tenant context. *(D3-001/002)*
10. **Quality gate is non-functional** — `php artisan test` cannot complete (silent death); tests are pinned to the **live** `prime_db` by a stale config cache; feature suite 0/26; no CI. *(D6-P0-1, D6-P1-1/2)*

---

## Readiness Scorecard (per domain)

| Dim | Domain | Verdict | P0 | P1 | Confidence | Headline |
|-----|--------|:---:|:--:|:--:|:---:|---|
| D1 | Functional Completeness | 🔴 NOT-READY | 1 | 10 | High | 97/3,447 routed refs dead (18 modules); 231 missing views |
| D2 | Database & Schema | 🔴 NOT-READY | 4 | 7 | High | fresh-tenant migrate+seed fatal chain; DDL documents 32/664 tables |
| D3 | Multi-Tenancy Isolation | 🔴 NOT-READY | 3 | 3 | High | 189 central-model imports; 103 unpinned dropdowns; cache bleed |
| D4 | Security & Authorization | 🔴 NO-GO | 3 | 6 | High | 50 open seeder routes; live APP_KEY in git; latent god-mode |
| D5 | Payments & Financial | 🔴 NOT-READY | 2 | 5 | High | forgeable payment confirmation; double-credit race |
| D6 | Test Coverage / Gates | 🔴 FAIL | 1 | 4 | High | suite can't complete; tests hit live DB; 25 modules zero coverage |
| D7 | Performance & Scale | 🔴 NOT-READY | 3 | 10 | High | solver/report/PDF run inline in HTTP (timeout/OOM); 25% no pagination |
| D8 | Deployment / CI-CD | 🔴 NOT DEPLOYABLE | 3 | 10 | High | parse errors block optimize; no CI/IaC; config:cache breaks env() |
| D9 | Observability / Ops | 🔴 NOT-READY | 0 | 3 | High | no error tracking; logging not tenant-aware; no runbooks |
| D10 | Backup & Recovery | 🔴 FAIL | 2 | 4 | High | no all-tenant backup; local-disk dest; no restore procedure |
| D11 | Compliance (DPDPA/K-12) | 🔴 NO-GO | 3 | 5 | High | plaintext Aadhaar/PAN/health; no PII audit trail; no consent |
| D12 | Documentation / Handover | 🔴 NOT-READY | 1 | 1 | Med | secrets+creds committed; no deploy runbook; stock README |
| | **TOTAL** | **🔴 NO-GO** | **~20*** | **~68*** | | *deduped across overlapping domains |

\* Raw P0 count across domains is 26; deduped to ~20 distinct blockers (the `.env-original` secret appears in D4/D8/D12; the StudentPortal demo-payment guard in D1/D5; the sys_roles chain spans D2-001/004).

---

## Module Heatmap (launch disposition)

Based on functional completeness (D1) + module-specific blockers. Platform-wide P0s (tenancy, payments, backup, PII, deploy) gate **all** modules regardless of row color.

| Disposition | Modules |
|---|---|
| **HOLD from v1** (scaffold / core workflows broken) | Scheduler (scaffold, 2/9 REQs), TimetableFoundation (`generateAllActivities` dead, 9 missing views), MarksheetGeneration (24 missing views), StudentPortal (demo payment guards removed) |
| **SHIP-WITH-FLAGS** (works but has broken sub-flows to fix) | Hostel (approval verbs missing), SchoolSetup (academic-session/staff-onboarding no-ops), Hpc (wizard steps 2–4 dead + PDF OOM), SmartTimetable (solver timeout), LmsQuiz (report timeout), Transport (report N+1), Vendor (plaintext PII), Library (perf + unwired history), StudentProfile (dead attendance/parent-login routes) |
| **Candidate SHIP** (functionally honest, once platform P0s fixed) | Billing (90, honest), Ptm (88), Feedback (functionally complete — only D4 sec), Accounting, Documentation, Cafeteria, Inventory, HrStaff, Admission, QuestionBank, FrontOffice, Certificate, Notification, GlobalMaster, LmsExam, Complaint, StudentFee, Syllabus, SyllabusBooks, BehaviouralAssessment, EventEngine, CommonChat, LmsHomework, LmsQuests, Recommendation, Template, StandardTimetable, PaymentGateway, Prime, SystemConfig, Dashboard |

> No module can actually ship until the platform-level Phase-0 blockers (provisioning, payments, tenancy, PII, backup, deploy) are cleared.

---

## Baseline corrections (things the June baseline over/under-stated — verified 2026-07-02)
These matter because they change where effort goes:
- ✅ **Authorization is NOT dead platform-wide.** 562/573 (98%) write methods are guarded via `Gate::authorize()`. The real risk narrowed to duplicate `Gate::policy()` registration (QNS/Transport/Billing/TTF) + 3 unguarded controllers. *(D4)*
- ✅ **No SQL injection.** All 48 raw-SQL-with-variable sites are static/bound/internal — 0 injectable. *(D4)*
- ✅ **No cross-tenant IDOR.** Database-per-tenant + tenancy-first middleware make user-supplied IDs structurally safe (10 controllers sampled). *(D3)*
- ✅ **Queued jobs are tenancy-safe.** `QueueTenancyBootstrapper` is active; the "jobs lose tenant context" P0 is downgraded. *(D3)*
- ✅ **Parent-portal child scoping is correct** — no "parent sees other children" leak. *(D11)*
- ✅ **`sys_dropdowns` cross-DB FK P0 was a false positive** — the tenant migration creates the table locally; residual issue is it's never seeded. *(D2)*
- ⚠️ **But two problems were far bigger than baselined:** cross-layer central-model imports (baseline "3 controllers" → **189 files**), and the fresh-tenant provisioning chain is fully fatal, not partial.

---

## Complete Gap Register

> Severity: **P0** blocks go-live · **P1** go-live only with explicit sign-off · **P2** first release cycle · **P3** backlog. Effort: S(<1d) · M(1–3d) · L(1–2wk) · XL(>2wk).

### D1 — Functional Completeness
| ID | Sev | Module | Description | Evidence | Effort |
|----|-----|--------|-------------|----------|--------|
| GAP-D1-001 | P0 | StudentPortal | Fee `initiate()` ships with demo guards removed ("TODO: restore before go-live") — orders on paid/cancelled invoices | `FeePaymentController.php:44-45` | S |
| GAP-D1-002 | P1 | Hostel | 8 routed workflow verbs have no method (mess opt-out approve/reject, bill publish, reservation confirm/cancel) → 500 | `routes/web.php:457,469,477` | M |
| GAP-D1-003 | P1 | SchoolSetup | `organization-academic-session` resource → controller with 6 empty bodies (silent no-op writes) | `web.php:219` | M |
| GAP-D1-004 | P1 | SchoolSetup | 16 dead routes incl. staff onboarding `addProfile`/`addTeacherProfile`, `TeacherController@assignSubjects` | `web.php:117-118` | M |
| GAP-D1-005 | P1 | SchoolSetup | `class-subject-management` + `infrasetup` routed with empty store/update/destroy | `web.php` | M |
| GAP-D1-006 | P1 | TimetableFoundation | 20/150 routed refs dead incl. core `generateAllActivities` | `web.php:95` | L |
| GAP-D1-007 | P1 | TimetableFoundation | 9 routed views missing (`timetable.edit`, `working-day.show/edit`) → 500 | routed refs | M |
| GAP-D1-008 | P1 | Scheduler | Whole module is scaffold — 2/9 FRD REQs usable; hold from v1 | module scan | L |
| GAP-D1-009 | P1 | MarksheetGeneration | 24 missing views — every resource index/create URL 500s | routed refs | L |
| GAP-D1-010 | P1 | StudentProfile | Attendance landing + `createParentLogin` routed with no methods; 9 dead routes | `web.php:57,140` | M |
| GAP-D1-011 | P1 | Hpc | Form wizard steps 2–4 routed with no controller methods | `web.php:32-34` | M |

### D2 — Database & Schema
| ID | Sev | Area | Description | Evidence | Effort |
|----|-----|------|-------------|----------|--------|
| GAP-D2-001 | P0 | Tenant migrate | 17 tenant FKs → `sys_roles`, which has **no create-migration**; `tenants:migrate` fails errno 150/1824 | first fail `..._create_lib_digital_resource_access_restrictions_table.php` | L |
| GAP-D2-002 | P0 | Provisioning | `SetupTenantDatabase.php` runs `tenants:migrate` only; nothing calls `tenants:seed` → tenants get no roles/menus/settings | `app/Jobs/SetupTenantDatabase.php` | M |
| GAP-D2-003 | P0 | Seeders | `TenantDatabaseSeeder` references 8 phantom classes (SchoolDaySeeder … + `SettingSeeder` vs actual `SettingsSeeder`) → class-not-found | `TenantDatabaseSeeder` | M |
| GAP-D2-004 | P0 | Seeders | `RolePermissionSeeder` writes `sys_roles` via spatie → dies on missing tenant table (resolved with 001) | tenant seed pipeline | S |
| GAP-D2-005 | P1 | DDL drift | `tenant_db_v4.sql` documents 32/664 live tables (98.8% undocumented) | DDL vs migrations | L |
| GAP-D2-006 | P1 | Naming drift | DDL↔migration name drift; `sch_categories`/`sch_disable_reasons` have no migration | grep | M |
| GAP-D2-007 | P1 | Migrations | 49 module migrations run on central `migrate` via `loadMigrationsFrom` — intent decision needed | module providers | S |
| GAP-D2-008 | P1 | Migrations | 3 duplicate migration basenames with different contents (Prime vs GlobalMaster) silently shadow | migration dirs | M |
| GAP-D2-009 | P1 | Seeders | `sys_dropdowns` created but never seeded in tenant pipeline (stays empty) | tenant seed | M |
| GAP-D2-010 | P2 | Typing | `->increments('id')` signed INT PK on 429/660 tables (FK typing + 2.1B cap) | grep | XL |
| GAP-D2-011 | P1 | Models | `$fillable` lists columns migrations lack — 66-model baseline (carried) | known-issues D17 | L |
| GAP-D2-012 | P2 | Indexes | 77/875 FK columns unindexed in top-10 modules (tt_ worst, 39) | schema scan | M |

### D3 — Multi-Tenancy Isolation
| ID | Sev | Area | Description | Evidence | Effort |
|----|-----|------|-------------|----------|--------|
| GAP-D3-001 | P0 | Cross-layer | 189 tenant-module files import central `Prime\*`/`GlobalMaster\*`/`Billing\*` models | platform grep | XL |
| GAP-D3-002 | P0 | Wrong-DB | `Prime\Dropdown` (60) + `GlobalMaster\Dropdown` (43) not connection-pinned → resolve against tenant DB | `Prime/app/Models/Dropdown.php` (no `$connection`) | L |
| GAP-D3-003 | P0 | Context leak | `tenancy()->initialize()` with no `->end()` | `Prime/DropdownNeedController.php:479,641` | S |
| GAP-D3-004 | P1 | Module gating | `EnsureTenantHasModule` on ~4–6 sites; ~39 modules lack it (plan-bypass) | routes/providers | L |
| GAP-D3-005 | P1 | Provisioning | Master-data seeding not part of unattended tenant provisioning (compounds D3-002) | `SetupTenantDatabase.php` | M |
| GAP-D3-006 | P1 | Cache bleed | `CacheTenancyBootstrapper` disabled + un-prefixed keys (`lms_exam_class_section_list`) | `config/tenancy.php:33` | M |
| GAP-D3-007 | P2 | Storage | Verify per-tenant file/storage path isolation | `config/filesystems.php` | M |
| GAP-D3-008 | P2 | Lifecycle | No tenant offboarding — `TenantController::destroy()` empty stub | `TenantController` | M |

### D4 — Security & Authorization
| ID | Sev | Area | Description | Evidence | Effort |
|----|-----|------|-------------|----------|--------|
| GAP-D4-001 | P0 | Secrets | Committed `.env-original` with live `APP_KEY` | repo root (git-tracked) | S |
| GAP-D4-002 | P0 | Open routes | 50 `SeederController` routes outside `auth`; controller has 0 guards | `routes/tenant.php:319+` | S |
| GAP-D4-003 | P0 | Priv-esc | `is_super_admin`/`super_admin_flag` in `$fillable` + `Gate::before` grants all → latent god-mode | `SchoolSetup/User.php`, `Prime/User.php`, `AppServiceProvider.php:65` | M |
| GAP-D4-004 | P1 | Auth | Duplicate `Gate::policy()` (last wins): QNS/Transport/Billing dead; TTF 5/23 registered | providers | M |
| GAP-D4-005 | P1 | Auth | Unguarded write controllers: Syllabus/CompetencieController, StudentProfile/StudentProfile+StudentReport | controllers | M |
| GAP-D4-006 | P1 | Validation | FormRequest `authorize(){return true;}` 405/485 (83%) | grep | L |
| GAP-D4-007 | P1 | Secrets | `TENANT_ADMIN_CREDENTIALS.md` committed (root@tenant.com/password) | repo root | S |
| GAP-D4-008 | P1 | Secrets | Hardcoded Razorpay test key | `StudentFee/PaymentGatewaySeeder.php:22,52` | S |
| GAP-D4-009 | P1 | XSS | ~30–45 raw `{!! $model->richText !!}` (complaint/homework/consent/article/question) | blade grep | M |
| GAP-D4-010 | P2 | Config | 8 `env()` calls outside config/ (also breaks config:cache) | grep | S |

### D5 — Payments & Financial
| ID | Sev | Module | Description | Evidence | Effort |
|----|-----|--------|-------------|----------|--------|
| GAP-D5-001 | P0 | ParentPortal/StudentFee | Callback verifies HMAC but never checks returned order-id/amount vs stored order → cross-order confirmation | `ParentFeePaymentController.php:91-122`, `RazorpayGateway.php:74-91` | M |
| GAP-D5-002 | P0 | Payment | Double-credit: `isPaid()` outside tx, no `lockForUpdate`, no status guard, no unique on `gateway_payment_id`/`payment_reference` | payment write path | M |
| GAP-D5-003 | P1 | StudentPortal | "DEMO … restore guards before go-live" — pay Draft/Cancelled invoices | `FeePaymentController.php:44-46` | S |
| GAP-D5-004 | P1 | Payment | `payment.captured` webhook updates only `pmt_payments`; `PaymentSucceeded` has 0 listeners → money never reaches ledger if browser callback lost | EventServiceProviders `$listen=[]` | M |
| GAP-D5-005 | P1 | Student/Mobile portal | Callbacks use `updatePayment()` only: no FeeTransaction/receipt → inconsistent books | portal callbacks | M |
| GAP-D5-006 | P1 | StudentFee | `fee_invoices.balance_amount` NOT NULL but never written (comment falsely claims GENERATED); defaulter report sorts on it | migration + service | M |
| GAP-D5-007 | P1 | StudentFee | Fee money mutations lack activity/audit log (only pmt_ side audited) | `recordPayment`/`updatePayment` | M |
| GAP-D5-008 | P2 | Payment | Refund path exists only as unreachable skeleton | code | L |
| GAP-D5-009 | P2 | Payment | Reconciliation exists only as seeded data | code | L |

### D6 — Test Coverage & Quality Gates
| ID | Sev | Description | Evidence | Effort |
|----|-----|-------------|----------|--------|
| GAP-D6-001 | P0 | `php artisan test` can't complete (silent exit 2 after 10 tests) — `ControllerAuthTest.php` kills process; `Library…GapFixesTest` extends non-existent `Tests\TenantTestCase` | run log | M |
| GAP-D6-002 | P1 | Tests pinned to **live** `prime_db`/`global_master` via stale `bootstrap/cache/config.php` (2026-05-21) overriding phpunit.xml; only a down MySQL prevented live-data hits | empirical run | S |
| GAP-D6-003 | P1 | Feature suite 0 passed / 26 failed (100%); effective executed feature coverage = 0 | run log | — |
| GAP-D6-004 | P1 | Tenant creation/onboarding has no test of any kind | repo scan | M |
| GAP-D6-005 | P1 | Payment tests exist (11 unit+2 feat) but module not registered in phpunit.xml → never run | phpunit.xml | S |
| GAP-D6-006 | P2 | 25/45 modules zero PHPUnit-runnable tests; 4 (Dashboard, EventEngine, Hostel, Notification) zero of any kind | count table | XL |
| GAP-D6-007 | P2 | No PHPStan/Larastan; no CI pipeline | repo scan | M |

### D7 — Performance & Scale
| ID | Sev | Module | Description | Evidence | Effort |
|----|-----|--------|-------------|----------|--------|
| GAP-D7-001 | P0 | SmartTimetable | 4,447-line solver runs synchronously in HTTP POST w/ 5-min lock; web path bypasses existing `GenerateTimetableJob` | `SmartTimetableController.php:2542/2649/2787` | L |
| GAP-D7-002 | P0 | LmsQuiz | Report index self-declares 5-min runtime + 23 unbounded gets on hot teacher path | `LmsQuizReportController.php:40` | M |
| GAP-D7-003 | P0 | Hpc | Inline dompdf raises mem 512MB/300s, invoked from parent-portal request → OOM under load | `HpcReportService.php:844`, `ParentHpcFormController.php:104` | M |
| GAP-D7-004..011 | P1 | Transport/QuestionBank/StudentProfile/Complaint/Library | N+1 + unbounded fetches in reports/dashboards/dropdowns (per-row queries, 17-table `show()`, etc.) | see D7 report | M–L |
| GAP-D7-012 | P1 | Platform | 90 unpaginated index() / 159 unpaginated list-report methods; 367 unbounded fetches (25.5%) | grep census | L |
| GAP-D7-013 | P1 | TimetableFoundation | `generateActivities()` hard-deletes+regenerates inline under 300s → truncation on timeout | code | M |
| GAP-D7-014 | P2 | Platform | session/cache/queue all = database; 23 request-path `Schema::` introspection sites | `.env`, grep | M |

### D8 — Deployment / Infra / CI-CD
| ID | Sev | Description | Evidence | Effort |
|----|-----|-------------|----------|--------|
| GAP-D8-001 | P0 | `route:list` exits 255 — stray `r` before `<?php` in `Modules/Prime/…/RolePermissionController.php`; blocks route:cache/optimize | `od -c` first bytes `r < ? p h p` | S |
| GAP-D8-002 | P0 | Parse error `app/View/Components/hpc-form/PerformanceCard.php` — hyphen in namespace | `namespace App\View\Components\hpc-form;` | S |
| GAP-D8-003 | P0 | Live secrets tracked in git: `.env-original`, `TENANT_ADMIN_CREDENTIALS.md`, `.env.dusk.local` — rotate + purge history | repo root | M |
| GAP-D8-004 | P1 | 9 `env()` outside config/ (tenant auth guard, LMS_DISK×4, AI keys) → config:cache silently breaks them | grep | S |
| GAP-D8-005 | P1 | 3 closure routes block route:cache | `web.php:997`, `tenant.php:307`, +1 | S |
| GAP-D8-006 | P1 | Zero CI/CD + zero infra-as-code | repo scan | L |
| GAP-D8-007 | P1 | `config/queue.php` hardcodes `database` (env lookup commented) → Horizon(redis) dead; `backup` queue unwatched | `config/queue.php` | S |
| GAP-D8-008 | P1 | Nothing supervises workers/scheduler → jobs, releases, backups silently stop | infra | M |
| GAP-D8-009 | P1 | Web-reachable unauthenticated ops scripts `public/run_dusk.php`, `public/_opcache_reset.php` | public/ | S |
| GAP-D8-010 | P1 | `npm run build` covers only core; 45 module vite configs orphaned (exports commented) | `vite.config.js` | M |
| GAP-D8-011 | P1 | No deploy runbook/strategy for 713 tenant migrations × N DBs (serial, hours, lock-prone) | docs absent | M |
| GAP-D8-012 | P1 | `.env.example` missing 30 keys (DB_*, GLOBAL_DB_*, RAZORPAY_*, TENANCY_CENTRAL_DOMAINS…) | diff | S |
| GAP-D8-013 | P2 | `.env` is dev profile (APP_ENV=local, APP_DEBUG=true) + habit of committing env files | `.env` | S |

### D9 — Observability / Ops
| ID | Sev | Description | Evidence | Effort |
|----|-----|-------------|----------|--------|
| GAP-D9-001 | P1 | No error tracking (no sentry/flare/bugsnag) | composer | M |
| GAP-D9-002 | P1 | Empty exception handler in `bootstrap/app.php` + debug-leak risk | bootstrap | S |
| GAP-D9-003 | P1 | Logging not tenant-aware; single non-rotating shared `laravel.log` | `config/logging.php` | M |
| GAP-D9-004 | P2 | No metrics / slow-query log / queue-depth alerting | config | M |
| GAP-D9-005 | P2 | No ops runbooks (deploy, rollback, tenant-create failure, queue backlog, restore) | docs absent | M |

### D10 — Backup & Recovery
| ID | Sev | Description | Evidence | Effort |
|----|-----|-------------|----------|--------|
| GAP-D10-001 | P0 | No all-tenant backup — Spatie backs up only `prime_db`; tenant DBs need manual `sys_backup_schedules` rows that never include new schools | `config/backup.php` | L |
| GAP-D10-002 | P0 | Backup destination = `local` disk (`storage/app/private`) on same server as MySQL → single loss destroys both | `config/backup.php` | M |
| GAP-D10-003 | P1 | Uploaded files/media never backed up (`--only-db`) | schedule | M |
| GAP-D10-004 | P1 | Backup jobs → `backup` queue with no worker; triple silent no-op (no cron, silent catch, no worker) | queue/schedule | S |
| GAP-D10-005 | P1 | Backup-failure notifications disabled (`notifications: []`) | `config/backup.php` | S |
| GAP-D10-006 | P1 | No restore procedure / no restore testing; RPO/RTO undefined | docs absent | M |
| GAP-D10-007 | P2 | Destructive-migration + down()-coverage audit needed for rollback | migrations | M |

### D11 — Compliance (DPDPA / K-12)
| ID | Sev | Description | Evidence | Effort |
|----|-----|-------------|----------|--------|
| GAP-D11-001 | P0 | Aadhaar plaintext (students/employees/applicants) w/ plain unique index; migration comment falsely claims "encrypted at app layer" | `std_students.aadhar_id`, `Employee.php` (no cast) | L |
| GAP-D11-002 | P0 | Employee + vendor PAN/bank account plaintext | `Vendor.php` casts only `is_active` | L |
| GAP-D11-003 | P0 | Special-category data plaintext (health, medical narratives, caste, religion, EWS, income) | StudentProfile/health models | L |
| GAP-D11-004 | P1 | No audit trail on PII reads/writes (StudentController `activityLog()` calls commented out; ParentPortal 0) | controllers | M |
| GAP-D11-005 | P1 | Any staff with `tenant.student.view` reads any student incl. health — `StudentPolicy::view()` ignores `$student` | `StudentPolicy` | M |
| GAP-D11-006 | P1 | No data lifecycle (retention/erasure/DSAR export/archival) | code | L |
| GAP-D11-007 | P1 | No verifiable parental consent / privacy acceptance (privacy link is dead `href="#"`) | admission flow | M |
| GAP-D11-008 | P1 | Notification opt-in fields exist but delivery pipeline never checks them | `NotificationService` | M |

### D12 — Documentation / Handover
| ID | Sev | Description | Evidence | Effort |
|----|-----|-------------|----------|--------|
| GAP-D12-001 | P0 | `.env-original` git-tracked with APP_KEY/REDIS/MAIL secrets (see D4-001/D8-003) | repo root | S |
| GAP-D12-002 | P1 | `TENANT_ADMIN_CREDENTIALS.md` committed with plaintext admin login | repo root | S |
| GAP-D12-003 | P2 | No admin onboarding/deploy docs; README is stock Laravel | docs | M |
| GAP-D12-004 | P2 | Internal docs in production artifact (`CLAUDE.md`, `TIMETABLE_GENERATOR_EXPLAINED.md`) should move out | repo root | S |
| GAP-D12-005 | P3 | Stray files at repo root (`origin)`, `user`, `.tmp_cols.php`, `perfect_timetable_demo.*`, `web_12_01_2026.php`) | repo root | S |

---
*Report produced by the Production Readiness audit defined in `2026-07-02_Production_Readiness_Gap_Analysis_Prompt.md`. Remediation sequencing in the sibling file `01_Production_Readiness_Plan.md`.*
