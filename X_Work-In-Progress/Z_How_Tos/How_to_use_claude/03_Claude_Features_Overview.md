# 03 — Claude Code Features Overview

> **Purpose:** Complete map of every Claude Code feature, what it does, when to use it, and why.

---

## Feature Landscape

```
┌─────────────────────────────────────────────────────────┐
│                   CLAUDE CODE FEATURES                   │
├─────────────┬──────────────┬───────────────┬────────────┤
│  KNOWLEDGE  │  AUTOMATION  │  EXECUTION    │  WORKFLOW  │
├─────────────┼──────────────┼───────────────┼────────────┤
│ CLAUDE.md   │ Hooks        │ Subagents     │ Plan Mode  │
│ .claude/    │ Skills       │ Git Worktrees │ /commands  │
│   rules/    │ MCP Servers  │ Bash tool     │ /compact   │
│ Auto Memory │              │ IDE plugins   │ /clear     │
│ .ai/ brain  │              │               │ /context   │
└─────────────┴──────────────┴───────────────┴────────────┘
```

---

## Feature Comparison Table

| Feature | What It Does | When to Use | Token Cost | Setup Effort |
|---------|-------------|-------------|------------|--------------|
| **CLAUDE.md** | Persistent project instructions | Always — core foundation | Low (loaded once) | 10 min |
| **`.claude/rules/`** | Path-scoped auto-loading rules | Per-module context | Very Low (only relevant rules load) | 30 min |
| **Auto Memory** | Claude remembers across sessions | Ongoing — automatic | Low (200-line index) | None (built-in) |
| **Custom Skills** | Reusable `/slash-commands` | Repetitive workflows | Varies | 15 min per skill |
| **Subagents** | Specialized AI workers | Verbose ops (tests, review) | Medium (isolated context) | 20 min per agent |
| **Hooks** | Auto-run scripts on events | Format, validate, notify | Zero (shell scripts) | 30 min |
| **MCP Servers** | External tool integration | GitHub, MySQL, APIs | Low-Medium | 15 min per server |
| **Git Worktrees** | Parallel branch work | Multiple features at once | Zero (git feature) | 5 min |
| **Plan Mode** | Safe read-only exploration | Complex tasks, architecture | Low (no edits) | Built-in |
| **`.ai/` brain** | Project knowledge base | All work — domain context | Medium (read on demand) | Already done |

---

## Feature Details

### 1. CLAUDE.md — Project Instructions
**What:** Markdown file that gives Claude persistent instructions across all sessions.
**Where:** Project root (`/CLAUDE.md`) — loaded every session.
**Best for:** Core project rules, tech stack, critical paths, non-negotiable conventions.
**Limit:** Keep under 200 lines for best adherence.
**Your current:** Already have a comprehensive CLAUDE.md. See `04_CLAUDE_MD_and_Rules.md` for optimization.

### 2. `.claude/rules/` — Path-Scoped Rules (KEY FEATURE)
**What:** Rules that auto-load ONLY when Claude touches files matching a glob pattern.
**Where:** `.claude/rules/*.md` with `globs:` frontmatter.
**Best for:** Module-specific context, work-type rules, file-pattern conventions.
**Why it matters:** This is the KEY to making Claude module-aware without wasting tokens.
**See:** `02_Module_Aware_AI_Agent.md` and `04_CLAUDE_MD_and_Rules.md`

### 3. Auto Memory — Cross-Session Learning
**What:** Claude automatically saves learnings (debugging patterns, preferences, project facts) to `~/.claude/projects/{project}/memory/`.
**Where:** Stored locally per project, first 200 lines of `MEMORY.md` loaded per session.
**Best for:** Accumulating knowledge over time without manual effort.
**Control:** `/memory` to view/edit/toggle. Ask Claude to "remember" or "forget" things.
**Your current:** Already active with several memory files.

### 4. Custom Skills — `/slash-commands`
**What:** Reusable workflows triggered by `/skill-name` or auto-invoked when Claude detects a match.
**Where:** `.claude/skills/{name}/SKILL.md` (project) or `~/.claude/skills/` (personal).
**Best for:** Running tests, code review, DB migrations, deployment, repeated analysis.
**See:** `05_Custom_Skills.md` for complete setup guide.

### 5. Subagents — Specialized AI Workers
**What:** Isolated AI assistants with specific tools, models, and permissions.
**Where:** `.claude/agents/{name}/AGENT.md` or via Claude's Agent tool.
**Best for:** Test running (verbose output stays in subagent), code review, codebase exploration.
**Models:** Can use cheaper/faster models (Haiku for exploration, Sonnet for most work, Opus for complex).
**See:** `06_Subagents.md` for complete setup guide.

### 6. Hooks — Automation Scripts
**What:** Shell commands that run automatically at lifecycle events (before/after tool use, on errors, etc.).
**Where:** `.claude/settings.json` or `~/.claude/settings.json`.
**Best for:** Auto-formatting PHP, blocking dangerous commands, desktop notifications.
**See:** `07_Hooks.md` for complete setup guide.

### 7. MCP Servers — External Integrations
**What:** Connect Claude to external tools via the Model Context Protocol standard.
**Where:** `.mcp.json` (project) or `~/.claude.json` (personal).
**Best for:** GitHub PRs/issues, direct MySQL queries, Figma designs, Slack.
**See:** `08_MCP_Servers.md` for complete setup guide.

### 8. Git Worktrees — Parallel Branch Work
**What:** Separate working directories for different branches, all sharing the same git history.
**Where:** `.claude/worktrees/` (auto-managed).
**Best for:** Working on SmartTimetable, HPC, and Tests simultaneously.
**See:** `09_Git_Worktrees.md` for your specific setup.

### 9. Plan Mode — Safe Exploration
**What:** Read-only mode where Claude can explore and analyze but not modify files.
**How:** `Shift+Tab` to toggle, or start with `claude --permission-mode plan`.
**Best for:** Understanding a new module before making changes, architecture planning.
**Token savings:** Prevents accidental edits that need reverting.

### 10. Session Management
**Commands:**
- `/clear` — Reset context (keeps history)
- `/compact` — Compress conversation to save tokens
- `/context` — See what's consuming context window
- `/cost` — Current session cost
- `/rename {name}` — Name session for future `/resume`
- `claude --continue` — Resume most recent session
- `claude --resume {name}` — Resume named session

---

## Decision Matrix: Which Feature for Which Work Type

| Work Type | Primary Features | Why |
|-----------|-----------------|-----|
| **Development** | `.claude/rules/` + Plan Mode + Subagents | Module context + safe planning + isolated testing |
| **Testing** | Custom Skills + Subagents + Hooks | `/test` command + test runner agent + auto-format |
| **DB Schema** | `.claude/rules/` + MCP (MySQL) | Schema context + direct DB queries |
| **Code Review** | Subagents + Custom Skills | Isolated review + `/review` command |
| **Requirements** | Plan Mode + Auto Memory | Safe exploration + remember decisions |
| **Bug Fixing** | Subagents (Explore) + Hooks | Fast search + safety guards |
| **Screen Design** | Custom Skills (`/frontend-design`) | Consistent UI generation |
| **Enhancement** | `.claude/rules/` + Plan Mode | Module context + architecture planning |
