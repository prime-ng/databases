# Prime-AI — Agent & Sub-Agent User Guide (OpenCode)

> How to run every OpenCode_Brain role, in both **interactive** and **parallel** mode, with all
> their built-in modes. Knowledge for every role lives in ONE place: `OpenCode_Brain/agents/<name>.md`.
> Each role is exposed as an OpenCode agent at `.opencode/agents/<name>.md` (a thin loader).
> Last updated: 2026-06-29 (ported to OpenCode).

---

## 1. The two ways to run any agent

Every role exists as **one OpenCode agent** (`mode: all`) that can run two ways:

| Form | How you call it | Where it runs | Use when |
|------|-----------------|---------------|----------|
| **Interactive** | `/agent <name>` then describe the task, or select the agent as your primary agent | In the **main session** — you see every step | One role at a time; you want to watch, collaborate, iterate |
| **Parallel (subagent)** | Ask the primary agent to launch the **`<name>` subagent** | In an **isolated child session**; returns only a summary | Run several roles **in parallel**, or keep heavy file-reading out of the main chat |

**Single source of truth:** the `.opencode/agents/<name>.md` files are thin *loaders* — they read
`OpenCode_Brain/agents/<name>.md` and adopt that role. Edit behaviour in **one place** (the
`agents/<name>.md` guide) and both forms update automatically. Never edit knowledge inside the
`.opencode/agents/` wrapper.

### Picking between them — rule of thumb
- **Designing / analysing / debugging interactively, one thing at a time** → `/agent <name>`
- **"Audit these 5 modules" / "write tests for 3 modules at once" / big fan-out** → launch several subagents
- **Want the main conversation to stay clean** (the role reads 40 files) → subagent form

---

## 2. Choosing the model

Agents are **not** pinned to a model — they inherit your session model. Set it *before* you launch:

- Select a strong reasoning model for audits, FRDs, architecture, gap analysis (recommended for these).
- Select a faster/cheaper model for routine dev, test writing, mechanical edits.

For a parallel run, set the model once; all subagents launched in that turn inherit it. (An agent
or command can also pin a model — this brain deliberately does not, so you stay in control.)

---

## 3. Running agents in parallel (the subagent superpower)

Ask for several subagents in one message and they run **at the same time**, each in its own
context, then report back. Examples:

- *"Use the **technical-auditor** subagent on StudentFee, LmsExam, and Transport in parallel — Mode A each."*
- *"Run the **business-analyst** subagent to draft the FRD for Library while the **db-architect** subagent designs the schema for Hostel."*
- *"Fan out the **status-analyzer** subagent across all Pending modules and give me one combined status."*

> After adding/removing agents, **start a new session** (or restart OpenCode) so the agent list refreshes.

---

## 4. Agent roster (all 17)

| Agent (`<name>`) | What it does | Has modes? |
|------------------|--------------|:----------:|
| **technical-auditor** | Read-only 12-layer audit; security/tenancy/perf/quality; FRD gap & business-rule checks; **diff/PR review** | ✅ A–X |
| **code-auditor** | Module-level Final Audit: per-controller `01-report.md` + `02-fix-plan.md`, `00-INDEX.md`, `00-SUMMARY.md`, plus a read-only `00-STATUS.md` re-check | ✅ Audit / Status |
| **business-analyst** | FRDs and 24 other analysis artifacts (BRD, SRS, RTM, user stories, FSM, NFR, etc.) | ✅ Catalog of 24 |
| **testing-architect** | Test strategy, test writing, coverage-gap analysis, CI automation | ✅ Domains 1–4 |
| **status-analyzer** | Development-completeness / gap status reports per module | ✅ Steps 1–6 |
| **db-architect** | Schema, migrations, DDL, indexing across the 3 DB layers | ✅ DB-layer decision |
| **test-agent** | Quick Pest 4.x test writing (Unit / Central Feature / Tenant Feature) | ✅ Test-type decision |
| **enterprise-architect** | System-wide architecture, cross-module integration, ADRs, roadmaps | — single role |
| **backend-developer** | Controllers, models, services, FormRequests, routes, migrations, policies | — single role |
| **frontend-developer** | Blade / Alpine.js / AdminLTE v4 + Bootstrap 5 views & components | — single role |
| **api-builder** | RESTful API endpoints inside the correct module | — single role |
| **developer** | General full-stack feature development | ✅ Scope decision |
| **debugger** | Root-cause runtime errors across the multi-tenant stack | — single role |
| **tenancy-agent** | stancl/tenancy v3.9 tasks; tenant isolation correctness | — single role |
| **module-agent** | nwidart/laravel-modules v12 module creation/structure/registration | — single role |
| **school-agent** | K-12 school-domain business rules and logic | — single role |
| **devops-deployer** | CI/CD, provisioning, containers, SSL, domains, production ops | — single role |

**Module-level Final Audit (`code-auditor`):** give it exactly two parameters plus the mode:

```text
Code Auditor, Audit,  BehaviouralAssessment, tarun
Code Auditor, Status, BehaviouralAssessment, tarun
```

`Audit` writes per-controller `01-report.md` + `02-fix-plan.md` and the module index/summary.
`Status` is a read-only re-check of every plan item and writes a module-wide `00-STATUS.md`.
No keyword → it asks. Full guide: `agents/code-auditor.md`.

---

## 5. Agents with built-in modes (how to drive them)

### 5.1 `technical-auditor` — pick an audit mode

When you name a module it confirms the module, then offers:

| Mode | Name | What it does | Trigger phrase |
|:----:|------|--------------|----------------|
| **A** | Standard Deep Audit | Full 12-layer scan | *"audit X"* (default) |
| **B** | FRD-driven Gap Analysis | FRD requirements vs DDL + code + tests (needs FRD) | *"gap analysis for X"* |
| **C** | Business-Rule Enforcement | Verify each `BR-` from the FRD is enforced in code (needs FRD) | *"check business rules in X"* |
| **D** | Platform Systemic Sweep | Cross-module hunt for known systemic patterns (D23–D36…) | *"find systemic issues across the platform"* |
| **E** | Combined | A + B + C for one module, unified report | *"full combined audit of X"* |
| **F** | Specific layer(s) | Only the layers you name | *"tenancy + deployment audit of X"* / *"performance only"* |
| **G** | Pre-deployment gate | Layers 6, 8, 10, 12 + secrets + cache safety | *"is X safe to deploy?"* |
| **H** | Diff/PR-scoped review | Review ONLY changed code in a diff / staged / a PR | *"review this diff / staged changes / PR #N / my changes"* |
| **X** | Complete "Everything" Audit | A + B + C + G + module-scoped D, one unified report | *"everything / the works / full audit of X"* |

**The 12 layers** (used by Modes A/F/G): 1 DDL Integrity · 2 Migration↔Model↔DDL · 3 ORM Correctness ·
4 Code Quality/Dead Code · 5 Authorization · 6 Multi-Tenancy · 7 Input Validation/Mass-Assignment ·
8 Data Integrity/Transactions · 9 Performance · 10 Queue/Job/Scheduler · 11 Blade/Output Safety ·
12 Deployment Readiness.

> **Mode F replaces the old `performance-auditor`** → say *"audit X, performance only"* (Layer 9).
> **Mode H replaces the old `code-reviewer`** → say *"review this PR"*.
> Layers 1–3 replace the old `db-analyzer` (schema↔model alignment).

---

### 5.2 `business-analyst` — pick an artifact from the catalog

First it asks **scope** (whole module / one feature / one screen), then produces any of these
**24 artifact types** (name the one you want; or describe the need and it proposes the best fit):

| # | Artifact | # | Artifact |
|--:|----------|--:|----------|
| 1 | **FRD** (10-section, business language) | 13 | Cross-Module Dependency Map |
| 2 | BRD (vision, objectives, metrics) | 14 | Integration Contract |
| 3 | SRS (IEEE-830) | 15 | **RTM** (Requirements Traceability Matrix) |
| 4 | Feature Specification (screen-by-screen) | 16 | NFR Catalog |
| 5 | RBS Entry (Category→Menu→Screen→F/T/ST) | 17 | Validation & Edge-Case Catalog |
| 6 | User Stories + Acceptance Criteria (Gherkin) | 18 | Risk Register |
| 7 | Requirement Conditions Catalog | 19 | Prioritization (MoSCoW / RICE) |
| 8 | Business Rules Register (`BR-`) | 20 | Effort Estimation & Sprint Breakdown |
| 9 | Process Flow / Workflow | 21 | Reporting & Analytics + KPI Catalog |
| 10 | State Machine (FSM) Catalog | 22 | Rollout / Change-Management Plan |
| 11 | Data Dictionary | 23 | Requirements-vs-Code Gap Analysis |
| 12 | Entity-Relationship narrative | 24 | Module Knowledge Seed / Update |

> The FRD's machine-readable Section 10 coverage flags are the **contract** consumed downstream by
> db-architect, technical-auditor, status-analyzer, and testing-architect — so generate the FRD first.

---

### 5.3 `testing-architect` — pick a domain

| Domain | Focus | Trigger phrase |
|:------:|-------|----------------|
| **1** | Test Strategy (what to test, risk-based) | *"test strategy for X"* |
| **2** | Test Writing (Feature/Unit/Authorization tests) | *"write tests for X"* |
| **3** | Coverage Gap Analysis | *"where are X's test gaps?"* |
| **4** | Test Automation (CI pipeline, GitHub Actions) | *"set up CI for tests"* |

> Use **test-agent** for a quick single test; use **testing-architect** for strategy/coverage/CI.

---

### 5.4 `status-analyzer` — completeness reporting (Steps 1–6)

Runs a fixed pipeline: (1) load prerequisites → (2) gather inputs → (3) per-module analysis →
(4) status report → (5) multi-module summary → (6) save outputs & update state.
Just name the module(s): *"status report for StudentPortal and Library."*

---

### 5.5 `db-architect` — first decides the DB layer

| Question | → Database | Migrations path |
|----------|-----------|-----------------|
| Shared reference data? | `global_db` (`glb_*`) | `database/migrations/` |
| SaaS mgmt (tenants, billing, plans)? | `prime_db` (`prm_*`/`bil_*`/`sys_*`) | `database/migrations/` |
| School-specific data? | `tenant_db` (`tt_*`,`std_*`,`fin_*`…) | `database/migrations/tenant/` |

Example: *"Design the schema for the Hostel module."*

---

### 5.6 `test-agent` — first decides the test type

| Type | Base class |
|------|-----------|
| Unit Test | (plain) |
| Central Feature Test | `Tests\TestCase` |
| Tenant Feature Test | `Tests\TenantTestCase` |

Example: *"Write a tenant feature test for fee invoice generation."*

---

### 5.7 `developer` — first decides scope

Asks whether the work is a single file, a feature slice, or a full module, then implements
following project patterns. Example: *"Add a bulk-promote students feature to StudentProfile."*

---

## 6. Single-role agents (no menu — just ask)

These have one clear job; state the task directly.

- **enterprise-architect** — *"Design the cross-module event flow between Fees and Accounting."*
- **backend-developer** — *"Build the controller + service + FormRequest for hostel allocation."*
- **frontend-developer** — *"Create the AdminLTE fee-collection screen Blade view."*
- **api-builder** — *"Add REST endpoints for the Complaint module."*
- **debugger** — *"Students list 500s on tenant X — find the root cause."*
- **tenancy-agent** — *"Verify queue jobs in Notification keep tenant context."*
- **module-agent** — *"Scaffold a new `Library` module."*
- **school-agent** — *"Encode the attendance-eligibility rule for exams."*
- **devops-deployer** — *"Write the GitHub Actions deploy pipeline for staging."*

---

## 7. Quick reference

```
# Interactive (one role, fully visible, in this session)
/agent technical-auditor      → "Audit StudentFee, Mode A"
/agent business-analyst       → "FRD for Library"
/agent enterprise-architect   → "Design Fees↔Accounting integration"
/agent                        → (no name) lists all available roles

# Parallel (isolated, multiple at once) — ask for the <name> subagent
"Use the technical-auditor subagent on StudentFee, LmsExam, Transport — Mode A, in parallel"
"Run the business-analyst (FRD, Library) and db-architect (schema, Hostel) subagents together"

# Commands
/test            → run Pest tests
/review          → review staged diff for security/tenancy/perf
/schema          → generate or validate schema
/lint            → PHP syntax + Pint style check
/module-status   → module completion report
/frontend        → Blade/Alpine/AdminLTE work

# Set a strong reasoning model first for quality-critical runs
```

---

## 8. Tips & gotchas

1. **Edit knowledge in ONE place** — `OpenCode_Brain/agents/<name>.md`. Both interactive and
   subagent use read it live.
2. **Start a new session** after adding/removing agents so the agent list refreshes.
3. **Set the model before launching** — agents inherit the session model (no pin).
4. **Parallel runs only return summaries** — for deep back-and-forth, use the interactive form.
5. **Mode defaults:** technical-auditor defaults to **Mode A**; "deploy?" → **G**; "review my diff/PR" → **H**; "systemic" → **D**; "everything" → **X**.
6. **Order for new modules:** business-analyst (FRD) → db-architect (schema) → backend/frontend/api → testing-architect → technical-auditor → status-analyzer.
7. **Retired Claude sub-agent wrappers** (capabilities folded into the brain): `code-reviewer` → auditor **Mode H**; `performance-auditor` → auditor **Mode F / Layer 9**; `db-analyzer` → auditor **Layers 1–3**; `test-runner` → any subagent run of `test-agent` / `testing-architect`.
8. **Read-only roles are enforced, not just documented:** `technical-auditor` and `status-analyzer` are
   deployed with `edit` **denied** (status-analyzer may still write its own reports and
   `state/progress.md`). They keep `shell`/`read`/`grep` because their detectors need bash. If a
   read-only agent tries to change application code, OpenCode blocks it.
