# Prime-AI — Production Readiness Remediation Plan
**Date:** 2026-07-02 · **Companion to:** `00_Production_Readiness_Report.md` (gap register with evidence) · **Basis:** 12-domain audit, ~20 P0 blockers, ~68 P1s

This plan is **dependency-ordered**: each phase unblocks the next. Do not start Phase 1 hardening while Phase 0 blockers stand — several Phase-1 items (tests, perf tuning) are unverifiable until the app boots, provisions a tenant, and runs its suite.

**Owner-role key:** BE=backend · DB=db-architect · SEC=security · DEVOPS=devops · QA=testing · FE=frontend.
**Effort:** S(<1d) · M(1–3d) · L(1–2wk) · XL(>2wk).

---

## Definition of "Production Ready" (exit criteria this plan drives to)
The app is production-ready when ALL of these are verifiably true:
1. `composer install --no-dev && php artisan optimize` completes with **zero** errors (no parse errors, config:cache + route:cache succeed).
2. A brand-new tenant can be created **unattended** — migrate + seed (roles, menus, dropdowns, settings, admin user) — and its user can log in and use core modules.
3. No secret is present in git history; `.env` is production-profiled (`APP_ENV=production`, `APP_DEBUG=false`); all keys rotated.
4. Payments cannot be forged or double-credited; every financial mutation is transactional and audit-logged; verified by tests.
5. All sensitive PII (Aadhaar, PAN, bank, health, caste/religion/income) is encrypted at rest; PII reads/writes are audit-logged; a staff member can only see students they're authorized for.
6. Automated backups of **prime_db + every tenant DB + uploaded files** run to off-server storage, alert on failure, and a **restore has been rehearsed**.
7. `php artisan test` completes green against an isolated `_test` database; a CI gate (lint + static analysis + tests) blocks merges.
8. Error tracking is live and tenant-tagged; a deploy + rollback runbook exists and has been dry-run.
9. No hot-path request can time out or OOM on a realistic school (1–2k students): heavy work (solver, reports, PDFs, imports) is queued.
10. Every registered route resolves to an existing controller method + view (0 dead routes on launched modules).

---

## Phase 0 — Go-Live Blockers (all P0) — target ~8–12 engineer-weeks

Grouped into 8 workstreams. Items within a workstream are ordered.

### WS-0.1 — Make the app build & deploy (DEVOPS/BE) — ~3–4 days
- **T0.1.1** Fix parse error `Modules/Prime/…/RolePermissionController.php` — remove stray `r` before `<?php`. *(GAP-D8-001, S)*
- **T0.1.2** Fix parse error `app/View/Components/hpc-form/PerformanceCard.php` — rename dir/namespace to valid PHP (`HpcForm`), update references. *(GAP-D8-002, S)*
- **T0.1.3** `php artisan optimize:clear`; then confirm `route:list`, `config:cache`, `route:cache`, `view:cache` all exit 0. *(gates all deploy)*
- **T0.1.4** Move 8–9 `env()` calls out of runtime code into `config/*.php`; replace closure routes (3) with controller actions so `route:cache` holds. *(GAP-D8-004/005/D4-010, S)*
- **T0.1.5** Fix `config/queue.php` to read `QUEUE_CONNECTION`; decide redis+Horizon vs database and make them consistent. *(GAP-D8-007, S)*
- **Acceptance:** `php artisan optimize` clean; `route:list` prints; chosen queue driver consistent end-to-end.

### WS-0.2 — Purge & rotate secrets (SEC/DEVOPS) — ~2 days
- **T0.2.1** `git rm --cached` `.env-original`, `TENANT_ADMIN_CREDENTIALS.md`, `.env.dusk.local`; add to `.gitignore`; **purge from history** (git-filter-repo/BFG); force-push; notify collaborators. *(GAP-D4-001/007, D8-003, D12-001/002)*
- **T0.2.2** Rotate `APP_KEY`, DB passwords, `REDIS_PASSWORD`, `MAIL_PASSWORD`, Razorpay keys. (Note: rotating APP_KEY requires re-encrypting any already-encrypted columns — sequence with WS-0.7.)
- **T0.2.3** Remove hardcoded Razorpay test key from `PaymentGatewaySeeder.php`; source from env. *(GAP-D4-008)*
- **T0.2.4** Delete web-reachable ops scripts `public/run_dusk.php`, `public/_opcache_reset.php`. *(GAP-D8-009)*
- **Acceptance:** no secret in `git log -p`; all credentials rotated; no plaintext creds in repo.

### WS-0.3 — Close the open attack surface (SEC/BE) — ~2 days
- **T0.3.1** Move all 50 `SeederController` routes behind `auth` + a super-admin gate **and** `app()->environment('local','staging')`; or remove from `routes/tenant.php` entirely for prod. *(GAP-D4-002)*
- **T0.3.2** Remove `is_super_admin`/`super_admin_flag`/`password` from `$fillable` on `SchoolSetup/User.php` + `Prime/User.php`; review the `Gate::before` god-mode grant. *(GAP-D4-003)*
- **Acceptance:** anonymous request to `/seeder*` on a tenant domain → 403/404; no privilege field is mass-assignable.

### WS-0.4 — Fix fresh-tenant provisioning (DB/BE) — ~1.5 weeks
- **T0.4.1** Create the missing `sys_roles` (+ related spatie permission tables) tenant migration so the 17 FKs resolve; verify `tenants:migrate` runs clean on an empty DB. *(GAP-D2-001/004)*
- **T0.4.2** Add `tenants:seed` to `SetupTenantDatabase.php` provisioning after migrate. *(GAP-D2-002, D3-005)*
- **T0.4.3** Fix `TenantDatabaseSeeder` — create/rename the 8 phantom seeders (`SettingSeeder`→`SettingsSeeder`, etc.); seed roles, menus, **dropdowns** (D2-009), settings, root user. *(GAP-D2-003, D2-009)*
- **T0.4.4** End-to-end test: provision a new tenant from scratch on a scratch DB → migrate + seed succeed → root user logs in → core module loads.
- **Acceptance:** unattended tenant creation works start to finish (criterion #2).

### WS-0.5 — Secure the money path (BE/SEC) — ~1.5–2 weeks
- **T0.5.1** In the Razorpay callback, verify the returned `razorpay_order_id` **equals the stored `gateway_order_id`** for that payment AND the captured amount equals the invoice amount, before marking success. *(GAP-D5-001)*
- **T0.5.2** Wrap payment confirmation in a DB transaction with `lockForUpdate`; add a status-transition guard (only pending→success); add a **unique constraint** on `pmt_payments.gateway_payment_id` and `fee_transactions.payment_reference`. *(GAP-D5-002)*
- **T0.5.3** Restore the removed StudentPortal guards — block initiation on Draft/Cancelled/paid invoices. *(GAP-D5-003, D1-001)*
- **T0.5.4** Wire `payment.captured` webhook → ledger listener so gateway-captured money reaches `fee_transactions` even if the browser callback is lost. *(GAP-D5-004)*
- **T0.5.5** Unify portal callbacks to always write FeeTransaction + receipt + audit log. *(GAP-D5-005/007)*
- **Acceptance:** replay/cross-order/concurrent tests (added in Phase 1 QA) cannot double-credit or forge; every payment produces a ledger row + audit entry.

### WS-0.6 — Tenancy isolation (BE/tenancy) — ~2–3 weeks (largest)
- **T0.6.1** Pin central models to the central connection: add `protected $connection='...central...'` to `Prime\Dropdown`, `GlobalMaster\Dropdown` and peers (103 call sites become safe at once). *(GAP-D3-002)*
- **T0.6.2** Replace the 189 cross-layer central-model imports in tenant code with tenant-DB models (e.g. `OrganizationAcademicSession` instead of `Prime\AcademicSession`); triage by risk (session/dropdown reads first). *(GAP-D3-001)*
- **T0.6.3** Add `->end()` to the two `tenancy()->initialize()` leaks in `Prime/DropdownNeedController.php`. *(GAP-D3-003)*
- **T0.6.4** Re-enable `CacheTenancyBootstrapper` (or tenant-prefix every cache key) and fix the un-prefixed keys. *(GAP-D3-006)*
- **Acceptance:** a query run under Tenant A's context can never read Tenant B's or central data it shouldn't; cache keys are tenant-scoped.

### WS-0.7 — Encrypt sensitive PII (SEC/DB) — ~1.5 weeks
- **T0.7.1** Add `encrypted` casts to Aadhaar, PAN, bank account, IFSC, and special-category fields (health, caste, religion, income) across StudentProfile/Employee/Vendor/Admission models. *(GAP-D11-001/002/003)*
- **T0.7.2** Replace plain UNIQUE indexes on now-encrypted columns with a blind-index/hash column for lookups (encrypted values aren't uniquely indexable).
- **T0.7.3** One-time data-migration job to encrypt existing plaintext values; store only last-4 for display. Sequence **after** APP_KEY rotation (WS-0.2) is finalized.
- **Acceptance:** a raw DB dump shows no plaintext Aadhaar/PAN/bank/health; display still works via accessors.

### WS-0.8 — Backups that actually protect tenant data (DEVOPS/DB) — ~1 week
- **T0.8.1** Configure backups to enumerate **all tenant DBs dynamically** (not static `sys_backup_schedules` rows) + `prime_db` + `global_master`. *(GAP-D10-001)*
- **T0.8.2** Point the backup destination at **off-server storage** (S3/GCS), not local disk. *(GAP-D10-002)*
- **T0.8.3** Run a worker on the `backup` queue (or run backups synchronously via cron), include uploaded files/media, re-enable failure notifications. *(GAP-D10-003/004/005)*
- **T0.8.4** Write and **rehearse** a restore procedure for one tenant + the central DB; record RPO/RTO. *(GAP-D10-006)*
- **Acceptance:** a scheduled run backs up every tenant + files to off-server storage, alerts on failure, and a test restore succeeds.

---

## Phase 1 — Critical (P1) — target ~10–16 engineer-weeks

Grouped by theme; start once Phase 0 is green.

### 1A — Fix broken/dead functionality (BE/FE) *(D1)*
Implement the 97 dead routes / 231 missing views on modules intended for v1: SchoolSetup academic-session + staff onboarding (D1-003/004/005), Hostel approval workflows (D1-002), TimetableFoundation generate + edit views (D1-006/007), Hpc wizard steps 2–4 (D1-011), StudentProfile attendance/parent-login (D1-010), MarksheetGeneration views (D1-009). Add a **route-integrity CI check** (every route action + view must exist) so this can't regress.

### 1B — Quality gate & tests (QA) *(D6)*
Unblock the suite (create `Tests\TenantTestCase`, quarantine `ControllerAuthTest` crasher); add a bootstrap guard that hard-fails any run where `DB_DATABASE` doesn't end in `_test`; delete stale config cache; register all module test dirs (incl. Payment); author the missing tenant-onboarding + payment-forgery/double-credit tests; add Larastan L1 + Pint + MySQL-service **CI pipeline** blocking merges. *(GAP-D6-001..007, D8-006)*

### 1C — Performance: queue the heavy work (BE) *(D7)*
Route SmartTimetable solver through the existing `GenerateTimetableJob` (D7-001); queue LmsQuiz report + HPC PDF generation and return async/download-when-ready (D7-002/003); add pagination to the 90 unpaginated index methods on hot paths; fix the worst N+1s (Transport/QuestionBank/StudentProfile/Complaint/Library). Move session/cache/queue off `database` to redis. *(GAP-D7-004..014)*

### 1D — AuthZ hardening (SEC) *(D4/D3/D11)*
Fix duplicate `Gate::policy()` registrations (D4-004); guard the 3 unguarded write controllers (D4-005); implement real `authorize()` in FormRequests where the controller is the only gate (D4-006); add `EnsureTenantHasModule` to the ~39 module route groups (D3-004); scope `StudentPolicy::view()` to authorized students (D11-005); escape/ sanitize the ~30–45 raw rich-text Blade outputs (D4-009).

### 1E — Compliance controls (SEC/BE) *(D11)*
Turn on PII read/write audit logging (D11-004); implement data lifecycle — retention, erasure, DSAR export, student archival (D11-006); add verifiable parental consent + working privacy policy in admission (D11-007); enforce notification opt-in/out in the delivery pipeline (D11-008).

### 1F — Observability & deploy ops (DEVOPS) *(D8/D9/D10)*
Add error tracking (Sentry/Flare) tenant-tagged (D9-001); implement the exception handler + ensure no debug leak (D9-002); tenant-aware log channels with rotation (D9-003); supervise workers + scheduler (D8-008); fix module asset build so all 45 modules' assets compile (D8-010); complete `.env.example` (30 keys, D8-012); write the deploy + tenant-migration rollout runbook for 713 migrations × N DBs (D8-011); destructive-migration/rollback audit (D10-007).

### 1G — Schema integrity (DB) *(D2)*
Reconcile DDL↔migration drift and create the 2 missing tables (D2-005/006); resolve the 3 duplicate-basename shadowing migrations (D2-008); decide/relocate the 49 module migrations (D2-007); fix the 66 `$fillable`-vs-migration mismatches (D2-011); index the 77 unindexed FK columns (D2-012).

---

## Phase 2 — Hardening (P2) — first release cycle
- `->increments('id')` → `bigIncrements` / unsigned across 429 tables (D2-010, XL — plan as data migration).
- Refund + reconciliation flows made real (D5-008/009).
- Backfill tests for the 25 zero-coverage modules, starting money/tenancy-adjacent (D6-006).
- Metrics, slow-query log, queue-depth alerts (D9-004); ops runbooks (D9-005).
- Storage isolation verification + tenant offboarding path (D3-007/008).
- Move internal docs out of the production artifact; clean stray root files (D12-003/004/005).
- 23 request-path `Schema::` introspection sites removed (D7-014).

## Phase 3 — Backlog (P3)
- 3 failing DB-independent unit tests; deprecation warnings; browser-suite naming (`*_TestCas.php`→`*Test.php`) so it's CI-discoverable (D6-P3-1/2).
- Remaining low-risk cosmetic items.

---

## Launch Strategy Recommendation
1. **Do not attempt a big-bang launch.** Clear Phase 0 first — the app cannot deploy, provision, bill, protect data, or recover today.
2. **Ship a reduced module set.** Launch the "Candidate SHIP" list once platform P0s are fixed; **feature-flag OFF** Scheduler, TimetableFoundation, MarksheetGeneration, and StudentPortal payments until their D1 blockers are done.
3. **Pilot with 1–2 friendly tenants** on the full backup+restore+monitoring stack before general availability — this validates provisioning, backups, and payments against real usage at low blast radius.
4. **Gate GA on the Go-Live Checklist below.**

---

## Go-Live Checklist (final pre-deploy gate)
- [ ] `php artisan optimize` clean; no parse errors; `route:cache`/`config:cache` succeed
- [ ] `APP_ENV=production`, `APP_DEBUG=false`; Telescope/Debugbar disabled in prod
- [ ] No secret in git history; all credentials rotated; `.env.example` complete
- [ ] New-tenant provisioning (migrate+seed+admin) verified unattended on a clean DB
- [ ] Payment forgery + double-credit + webhook-loss tests pass; every payment writes ledger + audit
- [ ] All sensitive PII encrypted at rest; PII access audit-logged; student-view scoping enforced
- [ ] Automated backups of prime + all tenant DBs + files to off-server storage; failure alerts on; **restore rehearsed**
- [ ] `php artisan test` green on isolated `_test` DB; CI gate active on merges
- [ ] Error tracking live + tenant-tagged; deploy + rollback runbook dry-run
- [ ] No dead routes on launched modules (route-integrity check green)
- [ ] Heavy operations (solver, reports, PDFs, imports) run on queues with workers supervised
- [ ] Queue/cache/session on redis; workers + scheduler supervised (systemd/supervisor)

---
*Sequencing derived from the 12 domain reports in this folder. Re-run the audit prompt after Phase 0 to confirm blockers are cleared before opening Phase 1 sign-off.*
