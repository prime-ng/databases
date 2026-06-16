# How to Use AI-Brain

> **Full User Manual:** See [Claude_User_Mannual.md](./Claude_User_Mannual.md) for the complete guide.

---

## Quick Start (Every Morning)

```bash
cd /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain && \
git pull && bash claude-config/setup.sh && \
cd /Users/bkwork/Herd/laravel && claude
```

This deploys **6 rules, 6 skills, 4 agents** from AI Brain to the correct locations.

---

## What Gets Deployed

| What | Count | From (Source) | To (Target) |
|------|-------|---------------|-------------|
| Path-scoped rules | 6 | `AI_Brain/claude-config/rules/` | `/Users/bkwork/Herd/laravel/.claude/rules/` |
| Slash commands | 6 | `AI_Brain/claude-config/skills/` | `~/.claude/skills/` |
| Subagents | 4 | `AI_Brain/claude-config/agents/` | `~/.claude/agents/` |

---

## Available Slash Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `/test` | Run Pest tests | `/test SmartTimetable` |
| `/review` | Code review (security, tenancy, performance) | `/review Modules/Hpc/` |
| `/schema` | Generate or validate DB schema | `/schema validate SmartTimetable` |
| `/lint` | PHP syntax + PSR-12 style check | `/lint Modules/Transport/` |
| `/module-status` | Module status report | `/module-status SmartTimetable` |
| `/frontend` | Build Blade views, forms, tables, charts | `/frontend form SmartTimetable Constraint` |

---

## Available Subagents

| Agent | Model | Purpose |
|-------|-------|---------|
| test-runner | Haiku | Run tests, return summary |
| code-reviewer | Sonnet | Security, tenancy, performance review |
| performance-auditor | Sonnet | N+1 queries, missing indexes |
| db-analyzer | Sonnet | Schema-model alignment |

---

## Path-Scoped Rules (Auto-Load)

These rules load **automatically** when Claude touches matching files — no action needed:

| Rule | Triggers On |
|------|------------|
| `smart-timetable.md` | `Modules/SmartTimetable/**`, timetable/constraint/parallel migrations |
| `hpc.md` | `Modules/Hpc/**`, HPC migrations |
| `testing.md` | `tests/**`, `phpunit.xml`, module tests |
| `migrations.md` | `database/migrations/**` |
| `school-setup.md` | `Modules/SchoolSetup/**`, school/class/section/subject/teacher/room migrations |
| `student-fee.md` | `Modules/StudentFee/**`, fee/fin migrations |

---

## Key Precautions

1. **Never mix central and tenant code** — know your context before writing any query
2. **Only use `*_v2.sql` DDL files** — non-v2 files are outdated
3. **Run `setup.sh` after AI Brain updates** — otherwise Claude uses stale config
4. **Don't commit `.claude/`** to Laravel repo — it's gitignored for a reason
5. **Update AI Brain state** — progress, decisions, and known issues after each task

---

## Architecture Diagram

```
DATABASE REPO (AI_Brain/)              LARAVEL REPO
├── memory/       Knowledge base       CLAUDE.md (~60 lines, entry point)
├── rules/        Universal rules      .claude/rules/ (6 files, gitignored)
├── agents/       AI role guides         ├── smart-timetable.md
├── templates/    Code boilerplates      ├── hpc.md
├── lessons/      Known issues           ├── testing.md
├── state/        Progress & decisions   ├── migrations.md
├── tasks/        Task tracking          ├── school-setup.md
└── claude-config/  SOURCE               └── student-fee.md
    ├── rules/    → .claude/rules/
    ├── skills/   → ~/.claude/skills/  USER HOME (~/.claude/)
    ├── agents/   → ~/.claude/agents/  ├── skills/ (6 slash commands)
    └── setup.sh  Deployment script    └── agents/ (4 subagents)
```

---

## Related Documentation

- **Full User Manual:** [Claude_User_Mannual.md](./Claude_User_Mannual.md)
- **AI Brain Architecture:** [9-Working_With_Claude/Creating_AI-Brain.md](./9-Working_With_Claude/Creating_AI-Brain.md)
- **AI Brain README:** `/databases/AI_Brain/README.md`
