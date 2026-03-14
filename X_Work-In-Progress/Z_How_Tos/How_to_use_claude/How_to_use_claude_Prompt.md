# How to use Claude for the Application 
=======================================

## Prompt
=========

Tasks - 1: I have created an AI Agent (Folder - .ai) but I have few Queries -
- Does this Ai agent works only for Smart Timetable Module or you have created it in such way that it is usefull for all the Modules of the App?
- As per my undertanding different Modules require different ai memory because every module has a unique requirement and doesn't need memory of everything.
- So how can I create a universal AI Agent which will have memory required for every Module but will load only that part of Memory which is required for the Module I am working right now.
- My Idea is - you can generte memory for all the Modules but before starting work ask me which Module I want to work on and then load only the memory required for that module.
- Give me a complete plan how can I create this type of AI Agent.
Task - 2 : I am working on different kind of work like - Requirement Creation/Enhancement, DB Schema Generation, Screen & Report Designing, Development(Frontend, Backend, API etc.), Testing, Code Review, Enhancement etc. Now have few Query -
- What is the best way to use claude capability for different type of work?
- what all different features of claude (e.g. AI Agent, skills etc.) I can use to get better output from claude in less time with consuming less tokans?
- Provide detail of all the features which I should use and why I should use those and also what is way to implement those?

Create a Complete Guide for my project and save it into folder "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/Z_Work-In-Progress/Z_How_Tos/How_to_use_claude"

---

## Answers:
Answers to Your Questions

Task 1: AI Agent Scope
  Q: Does the .ai/ agent work only for SmartTimetable?

  No — the .ai/ brain is designed as a universal project-level knowledge base. The rules, templates, memory, and most agents apply to ALL 29 modules. However, the recent work sessions have been heavily focused on SmartTimetable, so the progress.md and decisions.md have accumulated SmartTimetable-specific entries (D11, D14, D16, D17). The core files (tenancy-rules.md, module-rules.md, conventions.md, etc.) are fully universal.

  Q: How to make it module-aware (load only relevant memory)?

  Your idea is correct. The best approach uses Claude Code's native .claude/rules/ directory with path-scoped rules — this is a built-in feature where rules auto-load ONLY when Claude touches files matching a glob pattern. Combined with a restructured CLAUDE.md that asks which module you're working on, this achieves exactly what you want.

  Task 2: Claude Features for Different Work Types

  Claude Code has 7 key features beyond basic chat that most developers don't use:
  1. .claude/rules/ — Path-scoped rules (auto-load per module)
  2. Custom Skills (/commands) — Reusable workflows
  3. Subagents — Specialized AI workers (test runner, code reviewer, etc.)
  4. Hooks — Auto-format, auto-validate, notifications
  5. MCP Servers — Connect Claude to GitHub, MySQL, Figma, etc.
  6. Git Worktrees — Parallel branch work in isolation
  7. Plan Mode — Safe exploration before making changes

  ---
  Now creating the complete guide. Let me first ensure the target directory exists


  Now let me save a memory about this user's workflow needs.

⏺ Recalled 1 memory, wrote 2 memories (ctrl+o to expand)

⏺ Complete guide created. Here's what was delivered:

  ---
  Summary — 12 Files Created

  Location: databases/Z_Work-In-Progress/Z_How_Tos/How_to_use_claude/

  ┌────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │              File              │                                                                   Content                                                                   │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 00_README.md                   │ Master index + Two AI Systems diagram (.ai/ vs .claude/)                                                                                    │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 01_Current_State_Analysis.md   │ Full audit of your existing .ai/ brain — what's universal vs module-specific                                                                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 02_Module_Aware_AI_Agent.md    │ Complete plan — Uses .claude/rules/ path-scoped auto-loading so Claude loads SmartTimetable context only when touching SmartTimetable files │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 03_Claude_Features_Overview.md │ All 10 features with comparison table                                                                                                       │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 04_CLAUDE_MD_and_Rules.md      │ Deep dive on CLAUDE.md hierarchy + .claude/rules/ format with ready-to-copy templates                                                       │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 05_Custom_Skills.md            │ 6 recommended skills: /test, /migrate, /review, /schema, /module-status, /lint                                                              │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 06_Subagents.md                │ 4 recommended agents: test-runner, code-reviewer, performance-auditor, db-analyzer                                                          │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 07_Hooks.md                    │ 4 hooks: desktop notification, block dangerous commands, auto-format PHP, action logging                                                    │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 08_MCP_Servers.md              │ GitHub, MySQL, Filesystem MCP setup                                                                                                         │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 09_Git_Worktrees.md            │ Your specific 3-branch setup with permanent worktrees                                                                                       │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 10_Work_Type_Playbooks.md      │ Step-by-step playbooks for 7 work types (dev, testing, DB, review, requirements, design, bugs)                                              │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 11_Token_Optimization.md       │ 10 strategies with ~46% cost reduction example                                                                                              │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 12_Implementation_Checklist.md │ Full checklist with commands — can be done in ~2-3 hours                                                                                    │
  └────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  Key Answers:

  1. Your .ai/ brain is already ~80% universal — only state/decisions.md and state/progress.md are SmartTimetable-biased. The rules, templates, and agents work for all modules.
  2. The solution for module-aware loading is .claude/rules/ with globs: frontmatter — Claude's native feature that auto-loads rules only when matching files are touched. Zero user effort per session.
  3. The highest-impact features you're not using yet: .claude/rules/ (module-aware), Custom Skills (/test, /review), Subagents (isolated test running), and Hooks (auto-format + safety guards).

  Want me to start implementing any of these (creating the .claude/rules/, skills, or agents files)?

---

  ❯ Yes, I want you to create whatever is required but Not in '/laravel/.ai' folder because laravel repo is common among 3 developers who is working on different branches for different modules like 'smarttimetable',  
'HPC', 'Library' etc. whereas database is having a single branch, where only I am working as an Architect. So I want you to move .ai folder to database Repo and do all required enhancement over there. Let me know   
if you feel this is not a right approach. If you agree with my aproach then confirm and start working on :                                                                                                             
- Move .ai folder to database Repo                                                                                                                                                                                     
- implement all enhancement required (e.g. creating the .claude/rules/, skills, etc.) 

---

Good question — there's one technical constraint that adjusts your approach slightly.                                                                                                                                
                                                                                                                                                                                                                       
  The Issue with Moving Everything                                                                                                                                                                                     
                                                                                                                                                                                                                       
  .claude/rules/ with path-scoped globs (e.g., Modules/SmartTimetable/**) MUST be in the Laravel repo — Claude Code matches these globs against files in the current working directory. If they're in the database     
  repo, the globs won't find any Laravel files.                                                                                                                                                                        
                                                                                                                                                                                                                       
  Recommended Hybrid Approach                                                                                                                                                                                          

  DATABASE REPO (you own, single branch)         LARAVEL REPO (shared, 3 devs)
  ┌──────────────────────────────────────┐       ┌─────────────────────────────┐
  │  AI_Brain/                           │       │  CLAUDE.md (trimmed, points │
  │  ├── memory/ (moved from .ai/)       │       │    to AI_Brain/ in DB repo) │
  │  ├── rules/                          │       │                             │
  │  ├── agents/                         │       │  .claude/         (NEW,     │
  │  ├── templates/                      │       │  ├── rules/    .gitignored) │
  │  ├── lessons/                        │       │  │  ├── smart-timetable.md  │
  │  ├── state/                          │       │  │  ├── hpc.md              │
  │  └── claude-config/  (NEW)           │       │  │  └── testing.md          │
  │      ├── rules/  (source of truth)   │──────>│  └── (deployed by setup.sh) │
  │      ├── skills/ (source of truth)   │       │                             │
  │      ├── agents/ (source of truth)   │       │  .gitignore += .claude/     │
  │      └── setup.sh (deploys to right  │       └─────────────────────────────┘
  │           places)                    │
  └──────────────────────────────────────┘       ~/.claude/ (your machine only)
                                                 ├── skills/ (deployed by setup.sh)
                                                 └── agents/ (deployed by setup.sh)

  Why this works:
  - Database repo = Single source of truth for ALL AI knowledge + config source files
  - Laravel repo = Only .claude/rules/ (gitignored) + minimal CLAUDE.md — other devs unaffected
  - ~/.claude/ = Skills + agents at user level — personal, works in all projects
  - setup.sh = One command deploys everything to the right places

  Shall I proceed with this approach? It's the only way to make path-scoped rules work while keeping the source of truth in your database repo.

✻ Crunched for 1m 20s

---

