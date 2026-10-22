---
description: Switch the session's active role to a named OpenCode_Brain agent
---

# /agent — Switch Active Role

Switch to a named role from `OpenCode_Brain/agents/`.

## Usage

- `/agent technical-auditor` — Switch to Technical Auditor
- `/agent business-analyst` — Switch to Business Analyst
- `/agent testing-architect` — Switch to Testing Architect
- `/agent status-analyzer` — Switch to Status_Analyzer
- `/agent db-architect` — Switch to Database Architect
- `/agent enterprise-architect` — Switch to Enterprise Architect
- `/agent backend-developer` — Switch to Backend Developer
- `/agent frontend-developer` — Switch to Frontend Developer
- `/agent api-builder` — Switch to API Builder
- `/agent developer` — Switch to General Developer
- `/agent debugger` — Switch to Debugger
- `/agent tenancy-agent` — Switch to Tenancy Agent
- `/agent module-agent` — Switch to Module Agent
- `/agent school-agent` — Switch to School Domain Agent
- `/agent test-agent` — Switch to Test Agent
- `/agent devops-deployer` — Switch to DevOps Deployer
- `/agent` — List all available agents

## Steps

1. If no argument (`$ARGUMENTS` empty), list every `.md` in `OpenCode_Brain/agents/` with a one-line description.
2. Otherwise read `OpenCode_Brain/agents/$ARGUMENTS.md`.
3. Adopt the role described in that file — follow its prerequisites/reading order first, and resolve paths via `OpenCode_Brain/config/paths.md`.
4. Confirm with: `Active role: {Agent Name}. Ready. What would you like me to do?`

## Notes

- Agent names are lowercase with hyphens matching the filename (e.g. `enterprise-architect` → `agents/enterprise-architect.md`).
- You can switch roles mid-session by running `/agent` again.
- If the file doesn't exist, list available agents and ask the user to pick one.
- For an **isolated parallel run** instead of an in-session role switch, ask the primary agent to
  launch the `<name>` **subagent** (e.g. "use the technical-auditor subagent on X and Y in parallel").
