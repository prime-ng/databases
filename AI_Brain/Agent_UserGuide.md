# Prime-AI — Agent & Sub-Agent User Guide

> How to run every AI_Brain agent, in both **interactive** and **parallel** mode, with all
> their built-in modes. Knowledge for every agent lives in ONE place: `AI_Brain/agents/<name>.md`.
> Last updated: 2026-06-29.

---

## 1. The two ways to run any agent

Every role exists in **two forms that share the same brain** (the AI_Brain doc):

| Form | How you call it | Where it runs | Use when |
|------|-----------------|---------------|----------|
| **AI_Brain agent** (interactive) | `/agent <name>` | In the **main chat** — you see every step | One role at a time; you want to watch, collaborate, iterate |
| **`pa-` sub-agent** (parallel) | "use the **pa-`<name>`** sub-agent" | In an **isolated context**; returns only a summary | Run several roles **in parallel**, or keep heavy file-reading out of the main chat |

**Single source of truth:** the `pa-*` sub-agents are thin *loaders* — they read the same
`AI_Brain/agents/<name>.md` and adopt that role. Edit behaviour in **one place** (the AI_Brain
doc) and both forms update automatically. Never edit knowledge inside a `pa-*` wrapper.

### Picking between them — rule of thumb
- **Designing / analysing / debugging interactively, one thing at a time** → `/agent <name>`
- **"Audit these 5 modules" / "write tests for 3 modules at once" / big fan-out** → multiple `pa-*` in parallel
- **Want the main conversation to stay clean** (the role reads 40 files) → `pa-*` (its tokens stay in its own context; you get back a summary)

---

## 2. Choosing the model

Neither form is pinned to a model — both **inherit your current session model**. Set it *before*
you launch:

- `/model opus` → deep reasoning: audits, FRDs, architecture, gap analysis (recommended for these)
- `/model sonnet` → routine dev, test writing, mechanical edits (cheaper/faster)

For a parallel run, set the model once; all `pa-*` you launch in that turn inherit it.

---

## 3. Running agents in parallel (the `pa-` superpower)

Ask for several `pa-*` sub-agents in one message and they run **at the same time**, each in its own
context, then report back. Examples:

- *"Use **pa-technical-auditor** on StudentFee, LmsExam, and Transport in parallel — Mode A each."*
- *"Run **pa-business-analyst** to draft the FRD for Library while **pa-db-architect** designs the schema for Hostel."*
- *"Fan out **pa-status-analyzer** across all Pending modules and give me one combined status."*

> After adding/removing agents, **restart the session** so the Agent tool list refreshes.

---

## 4. Agent roster (all 16)

| Agent (`<name>`) | What it does | Has modes? |
|------------------|--------------|:----------:|
| **technical-auditor** | Read-only 12-layer audit; security/tenancy/perf/quality; FRD gap & business-rule checks; **diff/PR review** | ✅ A–H |
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

---

## 5. Agents with built-in modes (how to drive them)

### 5.1 `technical-auditor` — pick an audit mode

When you name a module it confirms the module, then offers:

| Mode | Name | What it does | Trigger phrase |
|:----:|------|--------------|----------------|
| **A** | Standard Deep Audit | Full 12-layer scan | *"audit X"* (default) |
| **B** | FRD-driven Gap Analysis | FRD requirements vs DDL + code + tests (needs FRD) | *"gap analysis for X"* |
| **C** | Business-Rule Enforcement | Verify each `BR-` from the FRD is enforced in code (needs FRD) | *"check business rules in X"* |
| **D** | Platform Systemic Sweep | Cross-module hunt for known systemic patterns (D23–D30…) | *"find systemic issues across the platform"* |
| **E** | Combined | A + B + C for one module, unified report | *"full combined audit of X"* |
| **F** | Specific layer(s) | Only the layers you name | *"tenancy + deployment audit of X"* / *"performance only"* |
| **G** | Pre-deployment gate | Layers 6, 8, 10, 12 + secrets + cache safety | *"is X safe to deploy?"* |
| **H** | **Diff/PR-scoped review** | Review ONLY changed code in a diff / staged / a PR | *"review this diff / staged changes / PR #N / my changes"* |

**The 12 layers** (used by Modes A/F/G): 1 DDL Integrity · 2 Migration↔Model↔DDL · 3 ORM Correctness ·
4 Code Quality/Dead Code · 5 Authorization · 6 Multi-Tenancy ·  7 Input Validation/Mass-Assignment ·
8 Data Integrity/Transactions · 9 Performance · 10 Queue/Job/Scheduler · 11 Blade/Output Safety ·
12 Deployment Readiness.

> **Mode F replaces the old `performance-auditor`** → say *"audit X, performance only"* (Layer 9).
> **Mode H replaces the old `code-reviewer`** → say *"review this PR"*.
> Layers 1–3 replace the old `db-analyzer` (schema↔model alignment).

**Examples**
- `/agent technical-auditor` → *"Audit StudentFee, Mode A."*
- *"Use **pa-technical-auditor**: Mode G pre-deploy gate on Transport, and Mode H on PR #214 — in parallel."*

---

### 5.2 `business-analyst` — pick an artifact from the catalog

First it asks **scope** (whole module / one feature / one screen), then produce any of these
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

**Examples**
- `/agent business-analyst` → *"FRD for the Library module."*
- *"Use **pa-business-analyst**: produce the RTM (#15) for LmsExam and the FSM Catalog (#10) for StudentFee in parallel."*

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
Great for parallel fan-out: *"Run **pa-status-analyzer** on all Pending modules, then a combined summary."*

---

### 5.5 `db-architect` — first decides the DB layer

Routes every table to the right layer before designing:

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

These have one clear job; state the task directly. In `/agent` for interactive work, or `pa-*` to
parallelise.

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
# Interactive (one role, fully visible, in this chat)
/agent technical-auditor      → "Audit StudentFee, Mode A"
/agent business-analyst       → "FRD for Library"
/agent enterprise-architect   → "Design Fees↔Accounting integration"
/agent                        → (no name) lists all available roles

# Parallel (isolated, multiple at once) — say the pa- name
"Use pa-technical-auditor on StudentFee, LmsExam, Transport — Mode A, in parallel"
"Run pa-business-analyst (FRD, Library) and pa-db-architect (schema, Hostel) together"

# Set model first for quality-critical runs
/model opus                   → audits, FRDs, architecture, gap analysis
/model sonnet                 → routine dev / test writing
```

---

## 8. Tips & gotchas

1. **Edit knowledge in ONE place** — `AI_Brain/agents/<name>.md`. Both `/agent` and `pa-*` read it live.
2. **Restart the session** after adding/removing agents so the Agent tool list refreshes.
3. **Set the model before launching** — both forms inherit the session model (no pin).
4. **Parallel runs only return summaries** — for deep back-and-forth, use the interactive `/agent` form.
5. **Mode defaults:** technical-auditor defaults to **Mode A**; "deploy?" → **G**; "review my diff/PR" → **H**; "systemic" → **D**.
6. **Order for new modules:** business-analyst (FRD) → db-architect (schema) → backend/frontend/api → testing-architect → technical-auditor → status-analyzer.
7. **Retired sub-agents** (capabilities folded into AI_Brain): `code-reviewer` → auditor **Mode H**; `performance-auditor` → auditor **Mode F / Layer 9**; `db-analyzer` → auditor **Layers 1–3**; `test-runner` → test-agent / testing-architect run in isolation via `pa-*`.
```
---

What's in the guide

8 sections, written to be a practical desk reference:

1. The two ways to run any agent — /agent <name> (interactive, in-chat) vs pa-<name> (parallel, isolated), with the single-source-of-truth note and a pick-between rule of thumb
2. Choosing the model — both inherit the session model; set /model first
3. Running in parallel — the pa-* superpower, with concrete fan-out examples
4. Full roster — all 16 agents in one table, flagged for which have modes
5. The agents with modes — how to drive each:
  - technical-auditor → Modes A–H table with trigger phrases (incl. your new Mode H diff/PR review)
  - business-analyst → the full 24-artifact catalog
  - testing-architect → Domains 1–4
  - status-analyzer (Steps 1–6), db-architect (DB-layer routing), test-agent (test types), developer (scope)
6. Single-role agents — one example task each
7. Quick reference — copy-paste command block
8. Tips & gotchas — incl. the build order for new modules and a "retired sub-agents → where the capability went" map

It explicitly documents that the old code-reviewer/performance-auditor/db-analyzer/test-runner capabilities now live as auditor Mode H / Mode F / Layers 1–3, and that test-runner's isolation is now any pa-* run — so anyone reading the guide knows where everything went.

You're all set: 16 symmetric agents, one source of truth, and a guide to drive them. Want me to drop a pointer to this guide in GUIDE.md/README.md so it's discoverable at session start?

