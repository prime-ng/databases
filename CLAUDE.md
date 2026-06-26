# Prime-AI Databases Repo — Claude Instructions

## Agent Switching

All agent role guides live in `AI_Brain/agents/`.

**When the user says any of the following, read the corresponding file and adopt that role:**

| User Says | Read File |
|-----------|-----------|
| "act as Enterprise Architect" | `AI_Brain/agents/enterprise-architect.md` |
| "act as Business Analyst" | `AI_Brain/agents/business-analyst.md` |
| "act as DB Architect" | `AI_Brain/agents/db-architect.md` |
| "act as Developer" | `AI_Brain/agents/developer.md` |
| "act as Backend Developer" | `AI_Brain/agents/backend-developer.md` |
| "act as Frontend Developer" | `AI_Brain/agents/frontend-developer.md` |
| "act as API Builder" | `AI_Brain/agents/api-builder.md` |
| "act as Debugger" | `AI_Brain/agents/debugger.md` |
| "act as Tenancy Agent" | `AI_Brain/agents/tenancy-agent.md` |
| "act as Module Agent" | `AI_Brain/agents/module-agent.md` |
| "act as School Agent" | `AI_Brain/agents/school-agent.md` |
| "act as Test Agent" | `AI_Brain/agents/test-agent.md` |
| "act as DevOps" | `AI_Brain/agents/devops-deployer.md` |
| "act as Technical Auditor" | `AI_Brain/agents/technical-auditor.md` |
| "act as Testing Architect" | `AI_Brain/agents/testing-architect.md` |
| "act as Status Analyzer" | `AI_Brain/agents/status-analyzer.md` |

You can also use `/agent {name}` — the skill does the same thing.

After reading the file, confirm: `Active role: {Agent Name}. Ready.`

## Path Variables

All path variables are defined in `AI_Brain/config/paths.md`.
Always resolve `{AI_BRAIN}`, `{TENANT_DDL}`, `{LARAVEL_REPO}`, etc. from that file.

## Utility Commands

**When the user says any of the following, execute the corresponding action:**

| User Says | Action |
|-----------|--------|
| "save context" | Read and execute `7-CLAUDE_Prompts/0-Important_Prompts/Save_Context.md` |
| "update module knowledge for {MODULE}" | Follow the Module Knowledge Update process in `AI_Brain/agents/business-analyst.md` — update `AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md` with learnings from this session |
| "seed module knowledge for {MODULE}" | Follow the Module Knowledge Seeding process in `AI_Brain/agents/business-analyst.md` — read DDL + V2 requirement docs and create `AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md` from scratch |

## Key Rules

- Always use v2 DDL files only — never reference non-v2 or module subfolder DDLs
- Tenant data = `tenant_db` (never store school data in `prime_db`)
- All table prefixes defined in `AI_Brain/memory/conventions.md`
