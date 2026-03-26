---
name: agent
description: Switch Claude's active role to a named AI_Brain agent
user_invocable: true
---

# /agent — Switch Active Role

Switch to a named agent from `AI_Brain/agents/`.

## Usage

- `/agent enterprise-architect` — Switch to Enterprise Architect
- `/agent business-analyst` — Switch to Business Analyst
- `/agent db-architect` — Switch to Database Architect
- `/agent developer` — Switch to General Developer
- `/agent backend-developer` — Switch to Backend Developer
- `/agent frontend-developer` — Switch to Frontend Developer
- `/agent api-builder` — Switch to API Builder
- `/agent debugger` — Switch to Debugger
- `/agent tenancy-agent` — Switch to Tenancy Agent
- `/agent module-agent` — Switch to Module Agent
- `/agent school-agent` — Switch to School Domain Agent
- `/agent test-agent` — Switch to Test Agent
- `/agent devops-deployer` — Switch to DevOps Deployer
- `/agent` — List all available agents

## Steps

1. If no argument given, list all `.md` files in `AI_Brain/agents/` with one-line descriptions
2. If argument given, read `AI_Brain/agents/{argument}.md`
3. Adopt the role described in that file — follow its Prerequisites section first
4. Confirm with: `Active role: {Agent Name}. Ready. What would you like me to do?`

## Notes

- Agent names are lowercase with hyphens matching the filename (e.g., `enterprise-architect` → `enterprise-architect.md`)
- You can switch roles mid-conversation by running `/agent` again
- If the file doesn't exist, list available agents and ask the user to pick one
