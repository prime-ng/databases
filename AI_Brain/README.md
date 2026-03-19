# AI Brain — Prime-AI Project

> Call this folder **"the brain"** in conversation and I'll know exactly what you mean.
> **Location:** Old database repo (`{AI_BRAIN}/`)

## What This Folder Is
This is the persistent knowledge base and instruction system for AI-assisted development on **Prime-AI**,
a multi-tenant SaaS Academic ERP + LMS + LXP platform for Indian K-12 schools.

## Architecture: Hybrid AI System

```
DATABASE REPO (AI_Brain/)                    LARAVEL REPO
├── memory/         Knowledge base           CLAUDE.md (trimmed, ~50 lines)
├── rules/          Universal rules          .claude/ (gitignored, deployed)
├── agents/         AI role guides             ├── rules/ (path-scoped)
├── templates/      Code boilerplates          │   ├── smart-timetable.md
├── lessons/        Known issues               │   ├── hpc.md
├── state/          Progress & decisions       │   ├── testing.md
├── tasks/          Task tracking              │   └── ...
└── claude-config/  SOURCE for deployment      └── (deployed by setup.sh)
    ├── rules/      Module rules (source)
    ├── skills/     /slash commands           ~/.claude/ (user level)
    ├── agents/     Subagents                   ├── skills/ (deployed)
    └── setup.sh    Deploy script               └── agents/ (deployed)
```

**Why this split?**
- Laravel repo is shared among 3 developers — module-specific AI config shouldn't be committed
- Database repo has a single branch where only the Architect works
- `.claude/rules/` MUST live in the project directory (path-scoped auto-loading)
- Skills and agents work best at `~/.claude/` user level

---

## How to Use This Folder

**Before starting ANY task, read:**
1. `config/paths.md` — **Path configuration** (resolve all `{VARIABLE}` references)
2. `memory/project-context.md` — Full project overview
3. `memory/tenancy-map.md` — Multi-tenancy architecture (CRITICAL)
4. `memory/modules-map.md` — Module inventory and structure
5. `memory/conventions.md` — Naming, patterns, and coding standards
6. `state/progress.md` — What's done, what's in progress
7. Relevant `rules/` files for the task type
8. Relevant `agents/` file for the task role

---

## Folder Structure

```
AI_Brain/
├── README.md              ← YOU ARE HERE — entry point
│
├── memory/                ← Stable project facts (rarely changes)
│   ├── MEMORY.md            Memory index
│   ├── project-context.md   Project overview, tech stack, goals
│   ├── tenancy-map.md       Multi-tenancy architecture reference
│   ├── modules-map.md       All 29 modules, scope, status
│   ├── architecture.md      System architecture, patterns, maturity
│   ├── school-domain.md     School entity map, relationships, roles
│   ├── conventions.md       Naming conventions and code patterns
│   ├── db-schema.md         Canonical DDL paths, table prefixes
│   ├── testing-strategy.md  Pest 4.x testing approach
│   ├── decisions.md         Architectural decisions (D1-D17)
│   ├── progress.md          Module completion tracker
│   └── known-bugs-and-roadmap.md  Bugs, security, performance, roadmap
│
├── state/                 ← Living state (changes as work progresses)
│   ├── progress.md          Module completion tracker
│   └── decisions.md         Architectural decisions log
│
├── rules/                 ← MANDATORY rules — always follow
│   ├── tenancy-rules.md     Tenancy isolation rules (most critical)
│   ├── module-rules.md      Module development rules
│   ├── laravel-rules.md     Laravel conventions
│   ├── security-rules.md    Security requirements
│   ├── code-style.md        PSR-12 and project style
│   └── school-rules.md      School domain business rules
│
├── templates/             ← Boilerplate — use for all new code
│   ├── module-structure.md      New module scaffold
│   ├── module-controller.md     Controller (web + API variants)
│   ├── module-service.md        Service class
│   ├── model.md                 Eloquent model
│   ├── form-request.md          Validation request (Store + Update)
│   ├── policy.md                Authorization policy
│   ├── event-listener.md        Event and Listener pair
│   ├── tenant-migration.md      Tenant DB migration
│   ├── system-migration.md      Central DB migration
│   ├── api-response.md          JSON response format
│   ├── repository.md            Repository pattern (optional)
│   ├── service.md               Central service (non-module)
│   ├── controller.md            Central controller (non-module)
│   ├── test-unit.md             Unit test boilerplate
│   ├── test-feature-central.md  Central feature test boilerplate
│   └── test-feature-tenant.md   Tenant feature test boilerplate
│
├── agents/                ← Role-specific AI instructions
│   ├── developer.md         General Laravel + modular dev guide
│   ├── db-architect.md      Database design specialist
│   ├── module-agent.md      Module creation specialist
│   ├── tenancy-agent.md     Tenancy specialist
│   ├── api-builder.md       REST API builder
│   ├── debugger.md          Debugging specialist
│   ├── school-agent.md      School domain expert
│   └── test-agent.md        Testing specialist (Pest 4.x)
│
├── lessons/               ← Hard-won knowledge, bugs, pitfalls
│   └── known-issues.md      Known bugs, gotchas, and fixes
│
├── tasks/                 ← Task tracking
│   ├── active/              Currently in-progress tasks
│   ├── backlog/             Planned but not started
│   └── completed/           Done tasks (reference archive)
│
└── claude-config/         ← SOURCE files for deployment
    ├── rules/               Path-scoped rules → deploy to .claude/rules/
    │   ├── smart-timetable.md
    │   ├── hpc.md
    │   ├── testing.md
    │   ├── migrations.md
    │   ├── school-setup.md
    │   └── student-fee.md
    ├── skills/              Slash commands → deploy to ~/.claude/skills/
    │   ├── test/SKILL.md
    │   ├── review/SKILL.md
    │   ├── schema/SKILL.md
    │   ├── lint/SKILL.md
    │   └── module-status/SKILL.md
    ├── agents/              Subagents → deploy to ~/.claude/agents/
    │   ├── test-runner/AGENT.md
    │   ├── code-reviewer/AGENT.md
    │   ├── performance-auditor/AGENT.md
    │   └── db-analyzer/AGENT.md
    └── setup.sh             Deployment script
```

---

## Quick Reference

| I need to...                        | Read this                          |
|-------------------------------------|------------------------------------|
| Start any new feature               | memory/ + relevant rules/          |
| Create a new module                 | agents/module-agent.md + templates/module-structure.md |
| Add a DB table                      | agents/db-architect.md + templates/tenant-migration.md |
| Build an API endpoint               | agents/api-builder.md + templates/api-response.md |
| Debug a tenancy issue               | agents/tenancy-agent.md + rules/tenancy-rules.md |
| Write a unit test                   | agents/test-agent.md + templates/test-unit.md |
| Write a tenant feature test         | agents/test-agent.md + templates/test-feature-tenant.md |
| Check what's done / in progress     | state/progress.md                  |
| Understand an architectural choice  | state/decisions.md                 |
| Know school business rules          | agents/school-agent.md + memory/school-domain.md |
| Deploy claude-config to project     | `bash claude-config/setup.sh`      |

---

## Deployment

Run setup.sh to deploy rules/skills/agents to the correct locations:

```bash
cd {AI_BRAIN}
bash claude-config/setup.sh
```

This will:
1. Copy path-scoped rules → `{LARAVEL_CLAUDE}/`
2. Copy skills → `~/.claude/skills/`
3. Copy agents → `~/.claude/agents/`
