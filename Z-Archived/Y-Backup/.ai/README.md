# AI Brain — Prime-AI Project

> Call this folder **"the brain"** in conversation and I'll know exactly what you mean.

## What This Folder Is
This is the persistent knowledge base and instruction system for AI-assisted development on **Prime-AI**,
a multi-tenant SaaS Academic ERP + LMS + LXP platform for Indian K-12 schools.

---

## How to Use This Folder

**Before starting ANY task, read:**
1. `memory/project-context.md` — Full project overview
2. `memory/tenancy-map.md` — Multi-tenancy architecture (CRITICAL)
3. `memory/modules-map.md` — Module inventory and structure
4. `memory/conventions.md` — Naming, patterns, and coding standards
5. `state/progress.md` — What's done, what's in progress
6. Relevant `rules/` files for the task type
7. Relevant `agents/` file for the task role

---

## Folder Structure

```
.ai/
├── README.md              ← YOU ARE HERE — entry point
│
├── memory/                ← Stable project facts (rarely changes)
│   ├── project-context.md   Project overview, tech stack, goals
│   ├── tenancy-map.md       Multi-tenancy architecture reference
│   ├── modules-map.md       All 29 modules, scope, status
│   ├── school-domain.md     School entity map, relationships, roles
│   └── conventions.md       Naming conventions and code patterns
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
└── tasks/                 ← Task tracking
    ├── active/              Currently in-progress tasks
    ├── backlog/             Planned but not started
    └── completed/           Done tasks (reference archive)
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
| Write a central feature test        | agents/test-agent.md + templates/test-feature-central.md |
| Write a tenant feature test         | agents/test-agent.md + templates/test-feature-tenant.md |
| Understand the testing strategy     | memory/testing-strategy.md        |
| Check what's done / in progress     | state/progress.md                  |
| Understand an architectural choice  | state/decisions.md                 |
| Know school business rules          | agents/school-agent.md + memory/school-domain.md |
