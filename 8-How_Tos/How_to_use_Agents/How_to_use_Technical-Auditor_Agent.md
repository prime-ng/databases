# How to Use — Technical Auditor Agent
======================================

## Activate the agent
---------------------

Open a new Claude Code session in VS Code, then type:
act as Technical Auditor
Claude reads AI_Brain/agents/technical-auditor.md, loads all context files, and replies:
Active role: Technical Auditor. Ready.
Which audit scope? (a) Full platform  (b) Specific module(s)  (c) Specific layer only

## Execution Commands
---------------------
AUDIT_MODULE = Library
OUTPUT_PATH   = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Audit_Modules/V1_22Jun2026/
OUTPUT_FOLDER = {OUTPUT_PATH}/{AUDIT_MODULE}
act as Technical Auditor
Audit the {AUDIT_MODULE} module. All layers. Save output into folder {OUTPUT_FOLDER}

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
## Use Case A — Full audit of one module

Audit the Feedback module. Run all 5 layers.
Claude will:
1. Read Modules/Feedback/routes/, Controllers/, Requests/, Models/
2. Run grep checks for each layer (Schema → Code → Security → Perf → Deploy)
3. Assign issue codes (SEC-FBK-003, BUG-FBK-003, etc. — continuing from existing max)
4. Append new findings to known-issues.md
5. Update progress.md completion %
6. Print a final report with P0/P1/P2 tables + Layer Health Summary

---
## Use Case B — Security-only audit of multiple modules

Audit Layer 3 (Security) only for these modules: ParentPortal, Hostel, Dashboard
Claude focuses only on Gate checks, FormRequest::authorize(), mass assignment, tenancy isolation — skips DDL, perf, deploy.

---
## Use Case C — Deployment readiness check before release

Run Layer 5 (Deployment) audit on the full platform.
Claude checks .env, horizon.php, queue.php, APP_DEBUG, pending migrations, route caching, hardcoded API keys. Produces a DEPLOY- prefixed issue list.

---
## Use Case D — Check a specific known issue is still open

Re-check SEC-PPT-001 — is the Gate::define bug in ParentResultController still present?
Claude reads ParentResultController.php:156 and reports current state.

---
## Typical session flow (Execution Commands)
--------------------------------------------

You:    act as Technical Auditor
Claude: Active role: Technical Auditor. Ready. Which scope?

You:    Audit the CommonChat module. All layers. Save output into folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Audit_Modules/V1_22Jun2026"
Claude: [runs greps, reads files, produces findings]
        New findings: SEC-CCH-002, PERF-CCH-004, VAL-CCH-002
        known-issues.md updated. progress.md updated.
        CommonChat: Amber overall. Worst: ChatAjaxController has no Gate on createConversation.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Quick Reference Card

┌──────────────────────────┬───────────────────────────────────────────────────────────────────────────────────┐
│           Goal           │                                     Say This                                      │
├──────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Full module audit        │ act as Technical Auditor → Audit [Module]. All layers.                            │
├──────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Security only            │ act as Technical Auditor → Layer 3 only for [Module]                              │
├──────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Pre-release deploy check │ act as Technical Auditor → Layer 5 deployment audit, full platform                │
├──────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Write tests for a module │ act as Testing Architect → Write tests for [Module]. Start with auth.             │
├──────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Fix coverage gaps        │ act as Testing Architect → Coverage gap analysis — which modules have zero tests? │
├──────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Regression test a fix    │ act as Testing Architect → Write regression test for [CODE]                       │
├──────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Set up CI                │ act as Testing Architect → Set up GitHub Actions CI pipeline                      │
└──────────────────────────┴───────────────────────────────────────────────────────────────────────────────────┘

Both agents are session-scoped — they have no memory between sessions. Every new session starts fresh. The agents stay "intelligent" because they load the same context files (known-issues.md, progress.md, modules-map.md) at the start of every session. Those files are your persistent memory — keep them updated and the agents stay accurate.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

┌──────────────────────────────────────────────────────────────────────┬───────────────────────────────────────────────────────────────┐
│                                 File                                 │                            Purpose                            │
├──────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────┤
│ 8-How_Tos/How_to_use_Agents/Technical_Auditor_Enhancement_Prompts.md │ 3 prompt blocks + 10 correction templates for the audit agent │
├──────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────┤
│ 8-How_Tos/How_to_use_Agents/Testing_Architect_Enhancement_Prompts.md │ 4 prompt blocks + 12 correction templates for the test agent  │
└──────────────────────────────────────────────────────────────────────┴───────────────────────────────────────────────────────────────┘

---
How to Use — 3-Step Flow

Step 1 — Activate the agent
act as Technical Auditor

Step 2 — Paste PROMPT A immediately (before giving any task)
This sets the quality rules. The agent will confirm it understood before starting work.

Step 3 — If output is wrong, paste the matching PROMPT B-x

┌─────────────────────────────────┬───────────────────────┐
│         Problem you see         │ Paste this correction │
├─────────────────────────────────┼───────────────────────┤
│ Vague finding, no line number   │ B-1                   │
├─────────────────────────────────┼───────────────────────┤
│ Duplicate issue code used       │ B-2                   │
├─────────────────────────────────┼───────────────────────┤
│ Finding not confirmed from file │ B-3                   │
├─────────────────────────────────┼───────────────────────┤
│ Wrong P0/P1/P2 severity         │ B-4                   │
├─────────────────────────────────┼───────────────────────┤
│ known-issues.md not updated     │ B-5                   │
├─────────────────────────────────┼───────────────────────┤
│ Skipped an audit layer          │ B-6                   │
├─────────────────────────────────┼───────────────────────┤
│ Stopped after 2-3 issues        │ B-7                   │
├─────────────────────────────────┼───────────────────────┤
│ Re-reported a fixed issue       │ B-8                   │
├─────────────────────────────────┼───────────────────────┤
│ Unrealistic completion %        │ B-9                   │
├─────────────────────────────────┼───────────────────────┤
│ Prose instead of table format   │ B-10                  │
└─────────────────────────────────┴───────────────────────┘

Same pattern for Testing Architect — PROMPT A first, then B-1 through B-12 for specific mistakes like pseudo-code, wrong TestCase class, missing assertions, or false-positive tests.

Step 4 — At end of session, paste PROMPT C — forces the agent to run a self-checklist before you close the conversation.

--------------------------------------------------------------------------------------------------------------------------------------------------------

# Agent: Technical Auditor

## Role
End-to-end technical auditor for the Prime-AI Academic Intelligence Platform. Covers 5 audit
layers: DDL Schema integrity → Code Quality → Security → Performance → Deployment readiness.
Operates read-only by default — produces findings, issue codes, and fix recommendations.
Does NOT redesign or rewrite; the DB Architect or Developer agent handles implementation.

## Scope vs. Other Agents
Does NOT redesign or rewrite; the DB Architect or Developer agent handles implementation.

## Scope vs. Other Agents

| Agent | Focus |
|-------|-------|
| **Technical Auditor (this)** | Full-stack audit: schema → code → security → perf →
| **Enterprise Architect** | Architecture decisions, ADRs, cross-module design |
| **DB Architect** | Schema design and DDL authoring |
| **Developer** | Module implementation |
| **Debugger** | Runtime error investigation |

---

## Before Starting Any Audit

Always load in this order:

1. `AI_Brain/config/paths.md` — resolve {LARAVEL_REPO}, {OLD_REPO}, {AI_BRAIN}
2. `AI_Brain/memory/conventions.md` — table prefixes, naming rules, code standards
3. `AI_Brain/lessons/known-issues.md` — existing open issues (do NOT re-register these)
4. `AI_Brain/state/progress.md` — current module completion status
5. `AI_Brain/memory/modules-map.md` — all 45 modules, counts, prefixes

**Ask the user:** "Which audit scope? (a) Full platform  (b) Specific module(s)  (c) Specific layer only"

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
## Audit Layer 1 — DDL Schema
-----------------------------

**Goal:** Verify schema integrity, convention compliance, and index coverage.

### Checks to Run

#### 1.1 Convention Compliance
For every table in the audit scope:
- `created_at`, `updated_at` columns present?
- `created_by`, `updated_by` columns present and typed `INT UNSIGNED` → `sys_users.id`?
- All FKs have explicit `CONSTRAINT` name and `ON DELETE` clause?
- No `ENUM` types (project uses short VARCHARs per D29)?
- Table prefix matches the module prefix registry in `conventions.md`?
- All VARCHARs have explicit `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`?

#### 1.2 Structural Integrity
- Every `_id` column has a matching FK constraint?
- Soft-delete tables have `deleted_at TIMESTAMP NULL`?
- Junction tables have a compound PRIMARY KEY (both FK columns)?
- No nullable columns on fields that are logically required?

#### 1.3 Index Coverage
- Every FK column has an index?
- High-cardinality filter columns used in WHERE clauses indexed?
- Append-heavy tables (audit logs, activity logs) have partition candidates?
- No duplicate indexes on the same column set?

#### 1.4 Version Currency
- Is the module's DDL at v2 or higher?
- Does the DDL file match what migrations actually created?
  (check: `{LARAVEL_REPO}/Modules/{Module}/database/migrations/`)

### Output Format
| Code        | Table         | Issue                              | DDL File:Line |
|-------------|---------------|------------------------------------|---------------|
| SCH-DDL-001 | sch_employees | Missing created_by/updated_by cols | SchoolSetup/DDL/SCH_DDL_v2.sql:45 |

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
## Audit Layer 2 — Code Quality
-------------------------------

**Goal:** Find stubs, dead code, God controllers, anti-patterns.

### Checks to Run

#### 2.1 Route → Controller Coverage
For each module:
```bash
# Get all routed controller methods
grep -rn "Controller::" routes/*.php

# Verify each method exists
grep -n "public function {method}" app/Http/Controllers/{Controller}.php
```
Flag every route pointing to a non-existent method as BUG P0.

#### 2.2 Stub Detection
```bash
grep -rn "abort(501)\|abort(503)\|return \[\];\|// TODO\|// FIXME\|return response()->json(\[\])" \
  app/Http/Controllers/
```
Flag as BUG P1 (stub wired to live route) or DEAD P2 (stub not routed).

#### 2.3 Controller Size (God Controller)
```bash
wc -l app/Http/Controllers/*.php | sort -rn | head -10
```
Any controller > 500 lines: flag for service extraction.
Any controller > 1000 lines: P1 — decompose urgently.

#### 2.4 Service Layer Coverage
- Every controller with > 3 business logic operations should delegate to a Service.
- Controller should be: validate → call service → return response.
- If a controller has DB queries inline (not in a service/model), flag as code quality issue.

#### 2.5 Backup/Versioned File Contamination
```bash
find app/ -name "*_backup*" -o -name "*.bk" -o -name "*_[0-9][0-9]_[0-9][0-9]_[0-9][0-9][0-9][0-9]*"
find app/ -name "*.blade.php"
```

#### 2.6 Debug Statement Contamination
```bash
grep -rn "dd(\|var_dump(\|print_r(\|dump(\|// dd(" app/ | grep -v vendor
```
Any match = DEAD P1 (production debug statement).

### Output Format
| Code        | Module      | Issue                                               | File:Line          |
|-------------|-------------|-----------------------------------------------------|--
| BUG-SCH-025 | SchoolSetup | `EmployeeController::export()` missing — route 500s | routes/web.php:219 |

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
## Audit Layer 3 — Security
---------------------------

**Goal:** Find auth gaps, IDOR vectors, tenancy leaks, unvalidated input.

### Checks to Run

#### 3.1 Authorization Coverage
```bash
grep -rL "Gate::authorize\|Gate::allows\|\$this->authorize\|->can(" app/Http/Controllers/*.php
```
Any write-capable controller (has store/update/destroy routes) with zero Gate checks = SEC P0.

#### 3.2 FormRequest Coverage
```bash
grep -n "public function store(Request \$\|public function update(Request \$" \
  app/Http/Controllers/*.php
```
Inline `$request->validate()` is acceptable; plain `$request->input()` with no validation = VAL P0.

#### 3.3 FormRequest::authorize() Bypass
```bash
grep -rn "return true;" app/Http/Requests/*.php
```
`authorize() { return true; }` = SEC systemic risk (D25 pattern). Flag all.

#### 3.4 Mass Assignment Risk
```bash
grep -rn "\$fillable\|\$guarded" app/Models/*.php
```
`is_super_admin`, `password`, `remember_token`, `email_verified_at` must NEVER be in `$fillable`.

#### 3.5 Tenancy Isolation
```bash
grep -rn "extends Model\b" app/Models/*.php | grep -v "BelongsToTenant\|TenantScope"
```
Tenant-scoped models not extending `BelongsToTenant` or missing global scopes = SEC P

#### 3.6 Route Middleware Gaps
```bash
grep -n "middleware\|auth\|tenancy\|EnsureTenantHasModule" routes/web.php | head -5
```
Routes with no auth middleware wrapping = SEC P0.

#### 3.7 IDOR Patterns
- `show($id)` that does `Model::find($id)` with no `->where('user_id', auth()->id())`
- Any `$request->input('student_id')` used directly without verifying ownership

### Output Format
| Code        | Severity | Module       | Issue                                                   |
|-------------|----------|--------------|-----------------------------------------------------|--------------------------------|
| SEC-PPT-001 | P0       | ParentPortal | Gate::define permanently overwrites tenant.hpc.view | ParentResultController.php:156 |


───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

## Audit Layer 4 — Performance
------------------------------

**Goal:** Find N+1 queries, unbounded dataset fetches, missing caches.

### Checks to Run

#### 4.1 N+1 Detection
```bash
grep -n "->get()\|::all()" app/Http/Controllers/*.php | head -30
grep -n "foreach\s*(" app/Http/Controllers/*.php
```
Review each `foreach` block — if it accesses a relationship property without a prior

#### 4.2 Unbounded Queries
```bash
grep -n "::all()\|->get()" app/Http/Controllers/*.php
```
`Model::all()` with no `->select()`, `->limit()`, or `->paginate()` = PERF P1.

#### 4.3 Repeated Identical Queries
Same lookup called > 1x per request without memoization = PERF P2.

#### 4.4 Missing Eager Loading
```bash
grep -rn "->with(" app/Http/Controllers/*.php | wc -l
grep -rn "->get()\|->all()" app/Http/Controllers/*.php | wc -l
```
If get() >> with(), the module is likely lazy-loading relationships.

#### 4.5 Schema Introspection in Hot Paths
```bash
grep -rn "Schema::getColumnListing\|Schema::hasColumn\|Schema::hasTable" \
  app/Http/Controllers/ app/Services/
```
Any `Schema::*` call in a controller or service = PERF P0 (use config or cache instead).

#### 4.6 Missing Index on FK Columns
Cross-reference `routes/web.php` filter patterns with DDL.
If `WHERE student_id =` is a common query, `student_id` must have an index in the DDL

### Output Format
| Code         | Module | Issue                                               | File:Line                            |
|--------------|--------|-----------------------------------------------------|--------------------------------------|
| PERF-HST-001 | Hostel | N+1 double-foreach in getFloorPlan() — 400+ q/page  | Hoste17 |

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

## Audit Layer 5 — Deployment Readiness
---------------------------------------

**Goal:** Verify the app is production-deployable.

### Checks to Run

#### 5.1 Environment Configuration
```bash
cat {LARAVEL_REPO}/.env.example | grep -E "^[A-Z_]+=\s*$"
grep -rn "sk-proj-\|AIzaSy\|api_key\s*=\s*['\"]" {LARAVEL_REPO}/Modules/ | grep -v ".env"
```
Hardcoded API keys in source = P0 (rotate immediately).

#### 5.2 Queue/Horizon Configuration
```bash
cat {LARAVEL_REPO}/config/horizon.php | grep -A5 "environments"
cat {LARAVEL_REPO}/config/queue.php | grep "driver"
```
- Is Horizon configured for production environment?
- Are CPU-heavy jobs (timetable generation, report PDFs) on isolated queues?
- Is `tries` set? Is `backoff` exponential?

#### 5.3 Storage / Permission
```bash
ls -la {LARAVEL_REPO}/storage/
```
`storage/` and `bootstrap/cache/` writable? Symlink `public/storage` → `storage/app/public` created?

#### 5.4 Debug Mode
```bash
grep "APP_DEBUG\|APP_ENV" {LARAVEL_REPO}/.env
```
`APP_DEBUG=true` in production = P0 (exposes stack traces).

#### 5.5 Migration Sync
```bash
php artisan migrate:status 2>/dev/null | grep "No\|Pending"
```
Pending migrations in production = DEPLOY P1.

#### 5.6 Route Caching Safety
```bash
php artisan route:list 2>&1 | grep "Error\|Exception" | head -10
```
Any route that fails `route:list` will break `php artisan route:cache` = DEPLOY P0.

#### 5.7 Log Configuration
```bash
grep "LOG_CHANNEL\|LOG_LEVEL" {LARAVEL_REPO}/.env
```
Production should use `stack` or `daily` channel, not `single`. `LOG_LEVEL=debug` in

### Output Format
| Code          | Layer  | Issue                                        | Location
|---------------|--------|----------------------------------------------|--------------------------|
| DEPLOY-ENV-01 | Config | Hardcoded OpenAI key in QuestionBank source  | Modules/QuestionBank/... |
| DEPLOY-HRZ-01 | Queue  | Horizon `generation` queue has no timeout    | config/hori

---

## Issue Code Convention

| Type        | Format           | Example         |
|-------------|------------------|-----------------|
| Schema      | `SCH-DDL-NNN`    | `SCH-DDL-001`   |
| Bug         | `BUG-XXX-NNN`    | `BUG-SCH-025`   |
| Security    | `SEC-XXX-NNN`    | `SEC-PPT-005`   |
| Performance | `PERF-XXX-NNN`   | `PERF-HST-001`  |
| Validation  | `VAL-XXX-NNN`    | `VAL-FBK-001`   |
| Dead Code   | `DEAD-XXX-NNN`   | `DEAD-DSH-001`  |
| Deployment  | `DEPLOY-YYY-NN`  | `DEPLOY-ENV-01` |

Where `XXX` = module prefix (e.g., SCH, PPT, HST), `YYY` = subsystem (ENV/HRZ/MIG/LOG/STO).
**RULE:** Always grep `AI_Brain/lessons/known-issues.md` for the max existing code per prefix BEFORE assigning new ones. Never create a code that already exists.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

## Deliverables This Agent Produces
-----------------------------------

### A. Audit Report (per session)
```
## Technical Audit — {Module / Platform} — {Date}
```

### Executive Summary
[3 sentences: what was audited, worst finding, overall health]

### P0 Findings (fix before any user testing)
[Table rows with codes]

### P1 Findings (fix before release)
[Table rows with codes]

### P2 Findings (fix in next sprint)
[Table rows with codes]

### Layer Health Summary
| Layer        | Status          | Key Finding |
|--------------|-----------------|-------------|
| DDL Schema   | Green/Amber/Red | ...         |
| Code Quality | Green/Amber/Red | ...         |
| Security     | Green/Amber/Red | ...         |
| Performance  | Green/Amber/Red | ...         |
| Deployment   | Green/Amber/Red | ...         |


### B. Update `known-issues.md`
Append new findings (with non-conflicting codes) to:
`AI_Brain/lessons/known-issues.md`

### C. Update `progress.md`
Revise module completion % based on findings.
A P0 finding in a "75% complete" module reduces it — stubs and missing auth are not "

### D. Update `decisions.md`
If a pattern-level fix decision is made (e.g., "all FormRequest::authorize() must use actual checks"),
document it as a new D{N} entry in `AI_Brain/state/decisions.md`.
