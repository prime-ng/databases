# Claude Code — Complete Guide for Prime-AI Project

> **Created:** 2026-03-13
> **For:** Prime-AI ERP + LMS + LXP (Laravel 12, 29 Modules, Multi-Tenant)
> **Purpose:** Master guide for using Claude Code across ALL work types

---

## Guide Index

| # | File | What It Covers |
|---|------|----------------|
| 01 | `01_Current_State_Analysis.md` | What exists today in `.ai/`, what's universal vs module-specific |
| 02 | `02_Module_Aware_AI_Agent.md` | **Complete plan** to make AI agent module-aware (auto-load per module) |
| 03 | `03_Claude_Features_Overview.md` | All Claude Code features with when/why to use each |
| 04 | `04_CLAUDE_MD_and_Rules.md` | CLAUDE.md best practices, `.claude/rules/` path-scoped rules |
| 05 | `05_Custom_Skills.md` | Create reusable `/slash-commands` for common workflows |
| 06 | `06_Subagents.md` | Specialized AI workers (test runner, code reviewer, etc.) |
| 07 | `07_Hooks.md` | Auto-format, auto-validate, desktop notifications |
| 08 | `08_MCP_Servers.md` | Connect Claude to GitHub, MySQL, Figma, external tools |
| 09 | `09_Git_Worktrees.md` | Parallel branch work (SmartTimetable + HPC + Tests) |
| 10 | `10_Work_Type_Playbooks.md` | Step-by-step playbooks per work type (Dev, Testing, DB, etc.) |
| 11 | `11_Token_Optimization.md` | Reduce cost, manage context, session strategies |
| 12 | `12_Implementation_Checklist.md` | Step-by-step checklist to implement everything |

---

## Quick Start

1. Read `02_Module_Aware_AI_Agent.md` first — this answers your main question
2. Read `03_Claude_Features_Overview.md` for the feature landscape
3. Follow `12_Implementation_Checklist.md` to set everything up
4. Use `10_Work_Type_Playbooks.md` daily for your specific work type

---

## Key Concept: Two AI Systems Working Together

```
+-----------------------------------------+
|  .ai/ (The Brain — Git-Committed)       |  <-- Project knowledge base
|  Rules, Templates, Memory, Agents       |  <-- Shared with team
|  Module maps, Architecture, Decisions   |  <-- Read by Claude at start
+-----------------------------------------+
              |
              v
+-----------------------------------------+
|  .claude/ (Claude Config — Partially    |  <-- Claude Code configuration
|  Git-Committed)                         |
|  settings.json — Team permissions       |  <-- Git-committed
|  settings.local.json — Personal prefs   |  <-- .gitignore'd
|  rules/ — Path-scoped auto-load rules   |  <-- Git-committed
|  agents/ — Custom subagents             |  <-- Git-committed
|  skills/ — /slash commands              |  <-- Git-committed
|  hooks/ — Automation scripts            |  <-- Git-committed
+-----------------------------------------+
              |
              v
+-----------------------------------------+
|  ~/.claude/ (User-Level — Not in Git)   |  <-- Personal across ALL projects
|  settings.json — Global permissions     |
|  CLAUDE.md — Personal instructions      |
|  projects/{project}/memory/ — Auto      |  <-- Claude's own memory
+-----------------------------------------+
```

The `.ai/` brain provides **domain knowledge** (what Prime-AI is, how it works).
The `.claude/` config provides **operational instructions** (what tools to use, what to auto-approve).
Together they make Claude module-aware, work-type-aware, and efficient.
