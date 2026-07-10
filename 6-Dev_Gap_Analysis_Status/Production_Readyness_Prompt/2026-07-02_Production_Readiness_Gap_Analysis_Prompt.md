# Prime-AI — Production Readiness Gap Analysis & Remediation Plan (Master Prompt)

**Created:** 2026-07-02
**Purpose:** Paste this prompt into a fresh Fable (Claude Code) session to perform a complete, evidence-anchored gap analysis of the entire Prime-AI application — code, database, requirements, tests, security, tenancy, infrastructure — and produce a phased plan to make the application Production Deployment Ready.
**Expected runtime:** Long (multi-phase). Run with a capable model (Fable 5 / Opus). Can be split into phases across sessions — each phase writes its output to disk so the next session can resume.

---

## ═══════════════ THE PROMPT (copy everything below this line) ═══════════════

You are the **Production Readiness Auditor** for Prime-AI, a multi-tenant K-12 School Management SaaS (Laravel + laravel-modules + stancl/tenancy, PostgreSQL, Blade/Alpine.js/AdminLTE). Your mission:

> **Find EVERY gap — anywhere in the system — that blocks or risks a production deployment, then produce a complete, prioritized, phased remediation plan to make the application Production Ready.**

This is a READ-ONLY audit followed by a PLAN. Do not modify application code during this task. All output files are written to the report folder defined below.

---

## 1. Source-of-Truth Locations (do not fuzzy-match; resolve everything through these)

```
APP_CODE          = /Users/bkwork/Herd/prime_ai                       (Laravel app — the deployable artifact)
MODULES           = /Users/bkwork/Herd/prime_ai/Modules/{FOLDER_NAME} (45 modules)
MIGRATIONS        = /Users/bkwork/Herd/prime_ai/database/migrations   (centralized; tenant migrations under /tenant)
TEST_REPO         = /Users/bkwork/Herd/prime_testing/tests/Browser/Modules/{FOLDER_NAME}

WORK_REPO         = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db     (docs/DDL/requirements — NOT deployed)
MODULE_LIST       = {WORK_REPO}/0-Prime_Ai_Detail/module_list.md      (⭐ authoritative module→CODE→PREFIX→FOLDER→DDL map)
PATHS_CONFIG      = {WORK_REPO}/AI_Brain/config/paths.md
DEV_DDL_MASTERS   = {WORK_REPO}/0-DDL_Masters                         (global_db_v4 / prime_db_v4 / tenant_db_v4 — v4 only)
MODULE_DDLS       = {WORK_REPO}/2-DDL_Tenant_Consolidated             (per-module v2 DDLs — use v2 only, never module-subfolder DDLs)
FRD_DIR           = {WORK_REPO}/4-Requirement_Module_wise/0-FRD_Documents
REQ_V1_DIR        = {WORK_REPO}/4-Requirement_Module_wise/2-Module_Requirement_V1
KNOWN_ISSUES      = {WORK_REPO}/AI_Brain/lessons/known-issues.md
CONVENTIONS       = {WORK_REPO}/AI_Brain/memory/conventions.md
PROGRESS_STATE    = {WORK_REPO}/AI_Brain/state/progress.md
COMPLETION_FORMULA= {WORK_REPO}/AI_Brain/config/completion-formula-v2.md (scoring rules & evidence discipline)
PRIOR_STATUS      = {WORK_REPO}/6-Dev_Gap_Analysis_Status/Progress_Status (latest all-module status report)

REPORT_DIR        = {WORK_REPO}/6-Dev_Gap_Analysis_Status/Production_Readyness_Prompt/Reports/{YYYY-MM-DD}/
```

**Before starting:** read `MODULE_LIST`, `PATHS_CONFIG`, `COMPLETION_FORMULA` (sections 0–2), `CONVENTIONS`, `KNOWN_ISSUES`, and the most recent report in `PRIOR_STATUS`. Create `REPORT_DIR`.

---

## 2. Evidence Discipline (non-negotiable — inherited from completion-formula-v2)

1. **Every claim must cite evidence** — a file path (+ line where relevant), a command output, or a count (numerator/denominator). No gap may be reported from memory, assumption, or a prior report.
2. **If you cannot verify something, report it as `⚠️ UNVERIFIED` with what you'd need to verify it** — never guess in either direction.
3. **Same inputs → same findings.** Deterministic, re-runnable.
4. **Prior reports are input for delta-comparison only, never anchors.** Re-derive everything from the current filesystem.
5. Distinguish **"missing"** (not built) from **"broken"** (built but wrong) from **"unproven"** (built, no evidence it works).

---

## 3. Severity Model (use everywhere)

| Level | Meaning | Production impact |
|-------|---------|-------------------|
| **P0 — Blocker** | Deployment fails, data loss/corruption, tenant data leakage, auth bypass, plaintext PII, payment errors | Cannot go live |
| **P1 — Critical** | Core feature broken/missing, no backup/rollback, unguarded write routes, crashes under normal use | Go-live only with explicit sign-off |
| **P2 — Major** | Degraded UX, performance risks (N+1, unbounded queries), missing tests on critical flows, ops gaps | Fix within first release cycle |
| **P3 — Minor** | Code style, dead code, doc gaps, nice-to-have monitoring | Backlog |

---

## 4. Audit Scope — the 12 Gap Domains

Sweep ALL of these. For each domain produce a findings file `REPORT_DIR/D{n}_{domain}.md` containing: findings table (ID, severity, module/area, description, evidence, remediation), counts, and a domain verdict (READY / READY-WITH-RISK / NOT-READY).

### Domain 1 — Functional Completeness (per module)
For each of the 45 modules in `MODULE_LIST`: build/refresh the requirement-vs-implementation register (FRD feature functions vs actual routes+controllers+views with real logic). Identify: unimplemented features, stub methods (empty bodies, `return true`, hardcoded/dummy data, `TODO`), features with routes but no working backend, and features with backend but no UI. Use the latest `PRIOR_STATUS` report as a starting map but **re-verify every module scored below 100% and spot-check 5 modules scored high**.

### Domain 2 — Database & Schema Integrity
- v4 master DDLs vs actual migrations: every table in DDL has a migration; every migration table exists in DDL (flag drift both ways).
- Missing FKs, missing indexes on FK/tenant/hot-query columns, wrong prefixes (per `MODULE_LIST` PREFIX column), nullable columns that business rules require NOT NULL.
- Migration health: do `php artisan migrate:fresh` (central) and tenant migrations run clean on an empty database? Any migration ordering/dependency errors? Any raw SQL in migrations that breaks on PostgreSQL versions?
- Seeders: does a fresh install produce a usable system (config tables, roles, menu, lookup data)? List every seeder required for first boot and whether it exists and runs.

### Domain 3 — Multi-Tenancy Isolation (HIGHEST RISK AREA)
- Every tenant-data query scoped to tenant DB — hunt for models/queries touching `prime_db` that should be `tenant_db` and vice versa.
- Central-vs-tenant route separation; tenancy middleware present on every tenant route group; no route accessible across tenants by ID-guessing (IDOR across tenants).
- File storage, cache, queue, session isolation per tenant.
- Tenant lifecycle: create-tenant → migrate → seed → module registration works unattended end-to-end. Tenant deletion/offboarding path exists.

### Domain 4 — Security & Authorization
- Route inventory: every write route + sensitive-read route behind auth middleware AND an authorization check (policy/gate actually invoked — registration alone doesn't count). Produce counts: guarded/total per module.
- Input validation: controllers using FormRequests vs raw `$request->all()` mass-assignment; `$guarded = []` / overly-wide `$fillable` on models.
- Injection surfaces: raw DB expressions with user input, `whereRaw`, unescaped Blade `{!! !!}`.
- Secrets: scan for hardcoded credentials/API keys in code and config; `.env.example` completeness; APP_DEBUG/APP_ENV handling.
- PII (student/parent/staff data): plaintext storage of sensitive fields, PII in logs, exposure in API responses beyond need.
- Session/auth hardening: password policy, rate limiting on login, CSRF coverage, remember-token handling, file-upload validation (type/size/path traversal).

### Domain 5 — Payments & Financial Integrity (StudentFee, Billing, Accounting, Payment)
- Payment flows: idempotency, double-payment protection, webhook signature verification, reconciliation, refund path, transaction wrapping around fee-ledger writes.
- Money handling: decimal types (never float), rounding rules, currency handling, audit trail on every financial mutation.

### Domain 6 — Test Coverage & Quality Gates
- Count Pest/Browser tests per module (`TEST_REPO` + any module `tests/`); identify modules with zero tests, and critical flows (auth, fee payment, exam marks, promotion, tenant creation) without any test.
- **Run the test suites** and report actual pass/fail counts — a failing suite is itself a P1 finding.
- Static analysis: run `php -l` sweep; if PHPStan/Larastan configured, run it; report error counts.

### Domain 7 — Performance & Scale
- N+1 patterns in hot paths (lists, dashboards, reports), unbounded `Model::all()` on request paths, missing pagination, missing eager loading, queries inside loops, schema introspection at request time.
- Cache strategy: what's cached, what must be (menus, config, permissions); queue usage for slow work (notifications, report generation, imports).
- Expected load sanity: an average school = ~1–2k students; flag anything that degrades at 50 concurrent tenants.

### Domain 8 — Deployment, Infrastructure & CI/CD
- Deployable artifact health: `composer install --no-dev` clean? `npm run build` clean? Any dev-only packages required at runtime? `config:cache`/`route:cache` compatible (no closures in routes)?
- Environment: full inventory of required env vars vs `.env.example`; per-environment config gaps (mail, queue driver, cache driver, filesystem, DB).
- Missing production scaffolding: Dockerfile/server provisioning docs, deployment runbook, zero-downtime strategy, queue workers + scheduler (`schedule:run`) supervision, storage symlink, HTTPS/proxy config.
- CI/CD: does any pipeline exist (lint → test → build → deploy)? If not, that's a P1 gap — specify the minimum pipeline.
- Also flag repo hygiene issues in APP_CODE that suggest deployment risk (e.g. stray files like `origin)`, demo scripts, `log_bug.sh` in repo root).

### Domain 9 — Observability & Operations
- Logging: structured? Tenant-tagged? Error tracking (Sentry/Flare or equivalent) configured? PII kept out of logs?
- Health checks/uptime endpoint, metrics, slow-query logging, disk/queue depth alerts.
- Runbooks: what does on-call do when X fails? (none existing = P2 gap, list required runbooks).

### Domain 10 — Backup, Recovery & Data Safety
- Backup strategy for central + per-tenant DBs and uploaded files; restore procedure ever tested?
- Rollback plan for a bad deploy (code + migrations); destructive-migration audit (drops/renames without backfill).
- Data retention & archival policy for academic-year rollover.

### Domain 11 — Compliance & Legal (K-12 context)
- Student-data protection posture (consent, access control by role, parent access boundaries), audit logging of who-viewed/edited-what for sensitive records, account deletion/data-export capability, terms/privacy hooks.

### Domain 12 — Documentation & Handover
- Admin/onboarding docs (create a school end-to-end), API docs if any external API, upgrade/migration notes, and accuracy of README/CLAUDE.md against reality.

---

## 5. Execution Plan (how to run this audit)

**Phase A — Baseline (fast):** Read the context files (§1), run the cheap global sweeps (route inventory, test counts, `php -l`, env-var inventory, grep sweeps for `dd(`, `TODO`, `->all()`, `whereRaw`, hardcoded keys). Write `REPORT_DIR/A_Baseline.md`.

**Phase B — Domain audits:** Execute Domains 1–12. Parallelize with subagents where available (suggested mapping: `pa-technical-auditor` → D1/D4/D7, `pa-tenancy-agent` → D3, `pa-db-architect` → D2, `pa-devops-deployer` → D8/D9/D10, `pa-testing-architect` → D6, `pa-status-analyzer` → cross-checking against prior status). Each domain writes its own findings file. For the 45-module domains (D1, D4), process modules in batches and persist after each batch so the run is resumable.

**Phase C — Verification pass:** For every P0 and P1 finding, re-verify adversarially (open the actual file/run the actual command; try to refute the finding). Downgrade or delete anything that doesn't survive. Mark surviving findings `CONFIRMED`.

**Phase D — Synthesis & Plan:** Produce the two master deliverables (§6).

---

## 6. Deliverables (all in `REPORT_DIR`)

### 6.1 `00_Production_Readiness_Report.md` — the Gap Register
- **Executive summary:** overall verdict (NOT-READY / READY-WITH-RISK / READY), total gaps by severity (P0/P1/P2/P3 counts), top-10 riskiest gaps, estimated distance to production in effort-weeks.
- **Readiness scorecard:** one row per domain (D1–D12): score 0–100 (count-derived), verdict, #P0, #P1, evidence-confidence (High/Med/Low).
- **Module heatmap:** 45 modules × (functional %, security verdict, test count, deploy-blocking issues) — mark each module SHIP / SHIP-WITH-FLAGS / HOLD.
- **Complete gap register:** every finding with ID (`GAP-{DOMAIN}-{NNN}`), severity, module/area, description, evidence citation, remediation summary, effort estimate (S/M/L/XL).

### 6.2 `01_Production_Readiness_Plan.md` — the Remediation Plan
A phased, dependency-ordered plan:
- **Phase 0 — Go-Live Blockers (all P0):** each with concrete tasks, owner-role (backend/db/devops/test), effort, and acceptance criteria ("done when …" — must be verifiable).
- **Phase 1 — Critical (P1):** same structure.
- **Phase 2 — Hardening (P2)** and **Phase 3 — Backlog (P3):** grouped by theme.
- **Launch strategy recommendation:** which modules to ship in v1 vs feature-flag off vs defer, based on the heatmap.
- **Go-Live Checklist:** the final pre-deploy checklist (env, migrations, seeds, backups verified, monitoring live, rollback rehearsed, smoke tests green).
- **Definition of "Production Ready"** for this app: the explicit, checkable exit criteria this plan drives toward.

### 6.3 Update `AI_Brain/state/progress.md` with a one-paragraph pointer to the report (date + REPORT_DIR + verdict). Do not rewrite prior history.

---

## 7. Ground Rules

- Read-only on `APP_CODE` and DDLs. You may RUN non-mutating commands (`php artisan route:list`, `php -l`, test suites, `composer validate`); anything that mutates a real database requires an isolated/scratch database — otherwise mark `⚠️ UNVERIFIED (needs sandbox run)`.
- v4 master DDLs and v2 module DDLs only (per repo Key Rules). Tenant data lives in `tenant_db`, never `prime_db`.
- When a domain can't be fully assessed from the repo (e.g., backups, hosting), don't skip it — report it as a gap: "no evidence of X exists in the repo" is itself a finding.
- Be exhaustive but honest: an inflated 500-item register of P3 noise is worse than a tight register where every P0/P1 is confirmed and actionable.

**Begin with Phase A now.**

## ═══════════════════════════ END OF PROMPT ═══════════════════════════

---

## Usage Notes (for me, not part of the prompt)

1. **Fresh session recommended** — this audit needs maximum context budget; don't run it at the tail of a long chat.
2. **Multi-session mode:** if context runs out, start a new session and say: *"Resume the Production Readiness audit — read REPORT_DIR/{date}/ for completed phases and continue from the next incomplete domain."* All phase outputs are on disk, so resume is cheap.
3. **Scoping down:** to audit one domain only, paste §1–§3 + that single domain + §6 adapted.
4. **After the report:** feed `01_Production_Readiness_Plan.md` Phase 0 items to the appropriate `pa-*` agents as implementation tasks, one gap ID per task.
