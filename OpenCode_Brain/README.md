# OpenCode Brain — Prime-AI Project

> Call this folder **"the brain"** in conversation and the agent will know exactly what you mean.
> **Location:** `{OLD_REPO}/OpenCode_Brain/`
> **Entry point:** `AGENTS.md` (auto-loaded by OpenCode).

This is the persistent knowledge base and instruction system for AI-assisted development on
**Prime-AI** — a multi-tenant SaaS Academic ERP + LMS + LXP platform for Indian K-12 schools —
expressed in OpenCode's native mechanisms.

It is the OpenCode port of the Claude-native `AI_Brain/`. Same platform knowledge; the
instruction mechanics now use `AGENTS.md`, `.opencode/agents`, `.opencode/commands`,
`.opencode/skills`, and `instructions/`.

---

## Architecture (OpenCode)

```
OpenCode_Brain/
├── AGENTS.md              Root instructions — auto-loaded every session
├── opencode.json          Config (skills source, permissions)
├── Agent_UserGuide.md     How to run every agent (interactive + parallel)
├── setup.sh               Validate brain / optional deploy (writes nothing by default)
│
├── .opencode/             OpenCode-native layer, auto-discovered when cwd = OpenCode_Brain
│   ├── agents/             16 role agents (mode: all, inherit model)
│   ├── commands/           Slash commands (/agent /test /review /schema /lint /module-status /frontend)
│   └── skills/             Model-invoked skills (6 module rules + prime-context)
│
├── instructions/          Path-scoped module rules (read the matching file before module work)
├── memory/                Stable project facts (rarely changes)
├── rules/                 MANDATORY universal rules — always follow
├── agents/                Role guides — SINGLE SOURCE OF TRUTH for each agent
├── templates/             Code boilerplates — use for all new code
├── lessons/               Hard-won knowledge, bugs, pitfalls
├── state/                 Living state (progress, decisions)
├── tasks/                 Task tracking (active/ backlog/ completed/)
├── module-knowledge/      Per-module accumulated knowledge (48 files)
└── config/                paths.md (path variables), completion-formula-v2.md
```

**Single source of truth:** each role's behaviour lives in `agents/<name>.md`. The OpenCode agent
at `.opencode/agents/<name>.md` is a thin loader that reads that file and adopts the role. Edit
behaviour in ONE place (`agents/<name>.md`) and both interactive and subagent use update.

**Why this shape?**
- `AGENTS.md` + `.opencode/` are discovered only when OpenCode runs inside this folder, keeping
  the config self-contained and out of the shared Laravel repo.
- Module-scoped rules live in `instructions/` and are surfaced as **skills**, so they load on
  demand (the OpenCode analog of Claude's path-scoped auto-loading).
- Knowledge folders (`memory/`, `module-knowledge/`, …) stay as plain Markdown so any agent can
  read them.

---

## How to use this brain

**Run OpenCode from this folder:**

```bash
cd {OLD_REPO}/OpenCode_Brain
opencode
```

**Before starting ANY task, read:**
1. `config/paths.md` — Path configuration (resolve all `{VARIABLE}` references)
2. `memory/project-context.md` — Full project overview
3. `memory/tenancy-map.md` — Multi-tenancy architecture (CRITICAL)
4. `memory/modules-map.md` — Module inventory and structure
5. `memory/conventions.md` — Naming, patterns, and coding standards
6. `state/progress.md` — What's done, what's in progress
7. Relevant `rules/` file(s) for the task type
8. Relevant `agents/<name>.md` guide (or select that agent)
9. Relevant `instructions/<name>.md` if working on a specific module

---

## Running an agent

Each role is one OpenCode agent (`mode: all`, no model pin — it inherits the session model):

- **Interactive:** `/agent <name>` then describe the task, or select the agent as primary.
- **Parallel:** ask the primary agent to launch the `<name>` **subagent** per unit of work.

| Agent | What it does |
|-------|--------------|
| `technical-auditor` | Read-only 12-layer audit; security/tenancy/perf/quality; FRD gap & business rules; diff/PR review (Modes A–X) |
| `business-analyst` | FRDs and 24 other analysis artifacts (BRD, SRS, RTM, user stories, FSM, NFR, …) |
| `testing-architect` | Test strategy, test writing, coverage-gap analysis, CI automation (Domains 1–4) |
| `status-analyzer` | Development-completeness / gap status reports (10-Dimension v2) |
| `db-architect` | Schema, migrations, DDL, indexing across the 3 DB layers |
| `test-agent` | Quick Pest 4.x test writing (Unit / Central Feature / Tenant Feature) |
| `enterprise-architect` | System-wide architecture, cross-module integration, ADRs, roadmaps |
| `backend-developer` | Controllers, models, services, FormRequests, routes, migrations, policies |
| `frontend-developer` | Blade / Alpine.js / AdminLTE v4 + Bootstrap 5 views & components |
| `api-builder` | RESTful API endpoints inside the correct module |
| `developer` | General full-stack feature development |
| `debugger` | Root-cause runtime errors across the multi-tenant stack |
| `tenancy-agent` | stancl/tenancy v3.9 tasks; tenant isolation correctness |
| `module-agent` | nwidart/laravel-modules v12 module creation/structure/registration |
| `school-agent` | K-12 school-domain business rules and logic |
| `devops-deployer` | CI/CD, provisioning, containers, SSL, domains, production ops |

Full driving instructions (modes, trigger phrases, parallel fan-out, model guidance):
**`Agent_UserGuide.md`**.

---

## Quick reference

| I need to... | Read/run this |
|--------------|---------------|
| Start any new feature | `memory/` + relevant `rules/` |
| Create a new module | `agents/module-agent.md` + `templates/module-structure.md` |
| Add a DB table | `agents/db-architect.md` + `templates/tenant-migration.md` |
| Build an API endpoint | `agents/api-builder.md` + `templates/api-response.md` |
| Debug a tenancy issue | `agents/tenancy-agent.md` + `rules/tenancy-rules.md` |
| Produce ANY analysis artifact | `agents/business-analyst.md` |
| Write a unit test | `agents/test-agent.md` + `templates/test-unit.md` |
| Full test strategy + CI | `agents/testing-architect.md` |
| Audit a module (12-layer) | `agents/technical-auditor.md` |
| Check module completion % | `/module-status` + `config/completion-formula-v2.md` |
| Know school business rules | `agents/school-agent.md` + `memory/school-domain.md` |
| Understand an architectural choice | `state/decisions.md` |
| Validate this brain | `bash setup.sh` |

---

## OpenCode specifics

- **Agents:** `.opencode/agents/<name>.md` — frontmatter `description` + `mode: all`; body is a
  thin loader that reads `agents/<name>.md`. No model is pinned, so they inherit the session model.
  The **read-only** roles (`technical-auditor`, `status-analyzer`) additionally deny `edit` in their
  frontmatter so they cannot change application code.
- **Commands:** `.opencode/commands/<name>.md` — `/agent`, `/test`, `/review`, `/schema`, `/lint`,
  `/module-status`, `/frontend`. Commands use `$ARGUMENTS` / `$1`.
- **Skills:** `.opencode/skills/<id>/SKILL.md` — module rules (`smart-timetable`, `hpc`,
  `migrations`, `testing`, `school-setup`, `student-fee`) and `prime-context` (loads the core
  project context). The model loads them on demand.
- **Path-scoped rules:** `instructions/<name>.md` hold the full module rules. Read the matching
  file before working on that module (the skills point at them).

### Optional: force-load specific instructions
To always load a doc in every session, add it to `instructions` in `opencode.json`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": ["./.opencode/skills"],
  "instructions": ["instructions/smart-timetable.md", "memory/tenancy-map.md"]
}
```

---

## Deployment

`setup.sh` is **safe by default** — it only validates the brain and prints how to use it. To copy
the OpenCode layer into the Laravel repo or your global OpenCode config, pass an explicit flag:

```bash
bash setup.sh                       # validate + print instructions (writes nothing)
bash setup.sh --deploy project      # copy AGENTS.md/opencode.json/.opencode into {LARAVEL_REPO}
bash setup.sh --deploy global       # copy agents/commands/skills into ~/.config/opencode
```

Nothing is written outside `OpenCode_Brain/` unless you run one of the `--deploy` forms.

---

## Terminology & provenance

Ported from the Claude-native `AI_Brain`. Active names use OpenCode terms (`AGENTS.md`,
`.opencode/`, agents, commands, skills). Historical/dated content is preserved verbatim:

- `pa-<agent>` attributions in `module-knowledge/` and dated logs = the prior Claude parallel
  sub-agents (now just "the `<agent>` subagent").
- Real filesystem folder names such as `Claude_Prompt/`, `Claude_Plan/`, `Claude_Context/` are
  unchanged because they exist on disk under `{OLD_REPO}`.
