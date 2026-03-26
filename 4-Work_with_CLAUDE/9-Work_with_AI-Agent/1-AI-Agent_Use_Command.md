# AI Agent — How to Switch Roles

## Method 1: Natural Language (Easiest)

Just say it — CLAUDE.md maps the phrase to the agent file automatically.

```
act as Enterprise Architect
act as Business Analyst
act as DB Architect
act as Developer
act as Backend Developer
act as Frontend Developer
act as API Builder
act as Debugger
act as Tenancy Agent
act as Module Agent
act as School Agent
act as Test Agent
act as DevOps
```

## Method 2: Slash Command

```
/agent enterprise-architect
/agent business-analyst
/agent db-architect
/agent developer
/agent backend-developer
/agent frontend-developer
/agent api-builder
/agent debugger
/agent tenancy-agent
/agent module-agent
/agent school-agent
/agent test-agent
/agent devops-deployer
```

Run `/agent` with no argument to list all available agents.

## Method 3: For Multi-Phase Prompts (e.g., Inventory)

When running a lifecycle prompt (Feature Spec → DDL → Dev Plan), specify both agents upfront:

```
act as Enterprise Architect and DB Architect.
Start Phase 1.
```

OR

```
act as Business Analyst and DB Architect.
Start Phase 1.
```

Claude will use Enterprise Architect for Phases 1 & 3, and DB Architect rules for Phase 2.

## Agent → Task Mapping

| Task | Best Agent |
|------|-----------|
| New module end-to-end lifecycle | Enterprise Architect |
| Feature spec, RBS, sprint plan | Business Analyst |
| Schema design, DDL, migrations | DB Architect |
| Controller, service, model code | Developer / Backend Developer |
| Blade views, Alpine.js, AdminLTE | Frontend Developer |
| REST API endpoints | API Builder |
| Bug investigation | Debugger |
| Tenancy isolation issues | Tenancy Agent |
| New module scaffolding | Module Agent |
| School domain / business rules | School Agent |
| Pest tests | Test Agent |
| Infrastructure, CI/CD | DevOps |

## Agent Files Location

All agent guides: `AI_Brain/agents/`
Claude Code subagents: `AI_Brain/claude-config/agents/` → deployed to `~/.claude/agents/`
