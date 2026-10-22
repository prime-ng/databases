# AGENTS.md — Prime-AI OpenCode Brain

> This file is auto-loaded by OpenCode for any session whose working directory is inside
> `OpenCode_Brain/`. It is the entry point to **the brain** — the persistent knowledge base and
> instruction system for AI-assisted development on **Prime-AI**, a multi-tenant SaaS Academic
> ERP + LMS + LXP platform for Indian K-12 schools.
>
> Call this folder **"the brain"** in conversation. Location: `{OLD_REPO}/OpenCode_Brain/`.

The older Claude-native brain lives at `{OLD_REPO}/AI_Brain/`. This folder is the OpenCode port:
same platform knowledge, expressed in OpenCode's native mechanisms (AGENTS.md, agents, commands,
skills, instructions). **This folder is the source of truth for OpenCode work.**

---

## How OpenCode consumes this brain

| Mechanism | Location | How it is used |
|-----------|----------|----------------|
| Root instructions | `AGENTS.md` (this file) | Auto-loaded every session |
| Role agents | `.opencode/agents/*.md` | `mode: all` — selectable as a primary agent **or** launchable as a subagent |
| Slash commands | `.opencode/commands/*.md` | `/agent`, `/test`, `/review`, `/schema`, `/lint`, `/module-status`, `/frontend` |
| Skills | `.opencode/skills/*/SKILL.md` | Model-invoked knowledge (module rules, project context) |
| Path-scoped rules | `instructions/*.md` | Read the matching file before touching that module |
| Config | `opencode.json` | Skills source, permissions, optional instruction globs |

**Run OpenCode from this folder** (`cd {OLD_REPO}/OpenCode_Brain`) so discovery of `AGENTS.md`,
`.opencode/` and `instructions/` works. `setup.sh` validates the brain and prints optional
deployment steps — nothing is written outside this folder unless you explicitly ask.

---

## Before starting ANY task, read

1. `config/paths.md` — **Path configuration** (resolve every `{VARIABLE}` reference)
2. `memory/project-context.md` — Project overview, tech stack, DB architecture, security posture
3. `memory/tenancy-map.md` — Multi-tenancy architecture (**CRITICAL**)
4. `memory/modules-map.md` — Module inventory, prefixes, completion status
5. `memory/conventions.md` — Naming, patterns, coding standards
6. `state/progress.md` — What is done / in progress
7. The relevant `rules/` file(s) for the task type
8. The relevant `agents/<name>.md` role guide (or select that agent)
9. The relevant `instructions/<name>.md` if the task touches that module

---

## Non-negotiable rules (full text in `rules/`)

1. **Tenancy isolation is the highest-risk class.** Never let a request read/write the wrong
   tenant's data, run tenant queries in central context, or leave tenancy context dangling.
   Read `rules/tenancy-rules.md`.
2. **Validate input; never mass-assign blindly.** Use FormRequests + `$request->validated()`.
   Never `create/update($request->all())`. Keep privilege fields (`is_super_admin`, `password`,
   `role_id`) out of `$fillable`. Read `rules/security-rules.md`.
3. **Authorize every state-changing or sensitive endpoint.** Gates/policies must actually run —
   a FormRequest `authorize()` that returns bare `true` is not authorization.
4. **Soft deletes + standard columns everywhere.** `is_active`, `created_by`, `created_at`,
   `updated_at`, `deleted_at` on all tables. Read `rules/laravel-rules.md`, `rules/code-style.md`.
5. **Migrations are centralized.** Tenant schema → `database/migrations/tenant/`; central →
   `database/migrations/`. Almost every module's own `database/migrations/` is empty.
   Never modify an existing migration — add a new additive one.
6. **Modules follow nwidart/laravel-modules v12.** Read `rules/module-rules.md`.
7. **School domain logic follows K-12 business rules.** Read `rules/school-rules.md`.

---

## Folder structure

```
OpenCode_Brain/
├── AGENTS.md              ← YOU ARE HERE — root instructions (auto-loaded)
├── opencode.json           ← OpenCode config (skills, permissions)
├── README.md               ← Full brain documentation & index
├── Agent_UserGuide.md      ← How to run every agent (interactive + parallel)
├── setup.sh                ← Validate brain / optional deploy (safe by default)
│
├── .opencode/              ← OpenCode-native layer (auto-discovered)
│   ├── agents/             16 role agents (mode: all, no model pin)
│   ├── commands/           Slash commands
│   └── skills/             Model-invoked skills (module rules, project context)
│
├── instructions/           Path-scoped module rules (read before module work)
│
├── memory/                 Stable project facts
├── rules/                  MANDATORY universal rules
├── agents/                 Role guides — single source of truth for each agent
├── templates/              Code boilerplates
├── lessons/                Known issues & pitfalls (known-issues.md)
├── state/                  Living state (progress.md, decisions.md)
├── tasks/                  active/ backlog/ completed/
├── module-knowledge/       Per-module accumulated knowledge (48 files)
└── config/                 paths.md, completion-formula-v2.md
```

---

## Running an agent (two ways, one brain)

Every role has **one** guide at `agents/<name>.md` and **one** OpenCode agent at
`.opencode/agents/<name>.md` (a thin loader that adopts the guide). Because the agent is
`mode: all`, you can use it either way:

- **Interactive (visible, one role at a time):** run `/agent <name>` and describe the task,
  or select the agent as your primary agent. You see every step.
- **Parallel (isolated, several at once):** ask the primary agent to launch the `<name>`
  **subagent** for each unit of work; each returns only a summary. Model is inherited — set the
  session model before launching.

**Roster (16):** `technical-auditor`, `business-analyst`, `testing-architect`, `status-analyzer`,
`db-architect`, `test-agent`, `enterprise-architect`, `backend-developer`, `frontend-developer`,
`api-builder`, `developer`, `debugger`, `tenancy-agent`, `module-agent`, `school-agent`,
`devops-deployer`. Full driving instructions: `Agent_UserGuide.md`.

---

## Quick reference

| I need to... | Read/run this |
|--------------|---------------|
| Start any new feature | `memory/` + relevant `rules/` |
| Run a role | `/agent <name>` or launch the `<name>` subagent |
| Create a new module | `agents/module-agent.md` + `templates/module-structure.md` |
| Add a DB table | `agents/db-architect.md` + `templates/tenant-migration.md` |
| Build an API endpoint | `agents/api-builder.md` + `templates/api-response.md` |
| Debug a tenancy issue | `agents/tenancy-agent.md` + `rules/tenancy-rules.md` |
| Audit a module (12-layer) | `/agent technical-auditor` → "Audit X, Mode A" |
| Review a diff/PR | `/review` or technical-auditor Mode H |
| Generate an FRD / analysis artifact | `agents/business-analyst.md` |
| Write tests | `/test` or `agents/test-agent.md` / `agents/testing-architect.md` |
| Check module completion % | `/module-status` or `agents/status-analyzer.md` |
| Know school business rules | `agents/school-agent.md` + `memory/school-domain.md` |
| Deploy | `agents/devops-deployer.md` + `memory/deployment-config.md` |

---

## Terminology note

This brain was ported from the Claude-native `AI_Brain`. Dated logs, provenance lines, and
real filesystem folder names (e.g. `Claude_Prompt/`, `Claude_Plan/`, `pa-business-analyst`
attributions in `module-knowledge/`) are preserved verbatim so paths and history stay intact.
Everything active uses OpenCode terms: `AGENTS.md`, `.opencode/`, agents, commands, skills.
