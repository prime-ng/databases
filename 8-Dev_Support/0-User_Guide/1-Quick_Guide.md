# Claude Code — Quick Guide

> Daily-use commands for working with Claude Code + AI Brain on Prime-AI
> **Full Manual:** [Claude_User_Mannual.md](./Claude_User_Mannual.md)

---
Here's what it covers:

```
┌─────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────┐
│         Section         │                                           Content                                            │
├─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. Quick Start          │ Morning one-liner + resume yesterday's work                                                  │
├─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. New Module           │ Create from scratch + start on existing module                                               │
├─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. Module Switching     │ Same-session switch, /clear for fresh, /compact to free space, /resume for past sessions     │
├─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 4. Work Type Switching  │ Dev → Testing, Dev → Design, Dev → Review, Dev → Frontend + Shift+Tab for Plan Mode          │
├─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 5. Update AI Brain      │ setup.sh re-deploy + asking Claude to update progress/decisions/issues                       │
├─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 6. Git Commands         │ Commit, push, pull, fetch, create PR, /diff viewer                                           │
├─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 7. Daily Commands       │ Session management, info/status, model/mode switches, keyboard shortcuts, all slash commands │
├─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 8. Copy-Paste Workflows │ Ready-to-use prompts for morning → development → test → review → commit → end of day         │
└─────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────┘
```
Plus a quick lookup table at the bottom — "I want to... → Do this" format for instant reference.

---------------------------------------------------------------------------------------------------------------------------------------------------

## 1. Quick Start (Every Morning)

### One-Liner — Run This First (When start work after closing VS-Code)
======================================================================

```bash
cd /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain && \
git pull && bash claude-config/setup.sh && \
cd /Users/bkwork/Herd/laravel && claude
```

### What It Does

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `cd AI_Brain/` | Navigate to AI Brain source |
| 2 | `git pull` | Get latest AI Brain updates |
| 3 | `bash claude-config/setup.sh` | Deploy 6 rules + 6 skills + 4 agents |
| 4 | `cd /Users/bkwork/Herd/laravel` | Navigate to Laravel project |
| 5 | `claude` | Start a fresh Claude session |


---------------------------------------------------------------------------------------------------------------------------------------------------

### Resume Yesterday's Work Instead
===================================
```bash
# Continue most recent session
claude --continue

# Pick a specific past session from list
claude --resume
```

---------------------------------------------------------------------------------------------------------------------------------------------------

## 2. Starting Work on a New Module
===================================

### From Scratch (New Module Creation)
--------------------------------------

```
> Create a new module called {ModuleName} — follow the module-agent guide
```

Claude will read `AI_Brain/agents/module-agent.md` and `AI_Brain/templates/module-structure.md` to scaffold:
- Module directory structure under `Modules/{ModuleName}/`
- Models, Controllers, Services, Routes, Migrations
- Config, Providers, and module.json

### Example — Start Working on Library Module (New)

```
> Create the Library module from scratch. It's a tenant-scoped module for managing
> school library books, borrowing, returns, and fines. Table prefix: lib_
```


---------------------------------------------------------------------------------------------------------------------------------------------------

### Starting Development on an Existing Module
----------------------------------------------

```
> I'm starting work on the {ModuleName} module. Read the AI Brain context for this module first.
```

Claude reads the relevant memory, rules, templates, and known issues before you begin.



### Example — Start Working on SmartTimetable (Existing)

```
> I'm working on SmartTimetable module. Read AI Brain context, known issues,
> and current progress before we begin.
```

---------------------------------------------------------------------------------------------------------------------------------------------------

## 3. Switching Between Modules

### Switch Module Context (Same Session)

Simply tell Claude you're switching. No special command needed:

```
> I'm done with HPC. Now switching to SmartTimetable module. Read AI Brain context for SmartTimetable before we continue.
```

Claude will:
- Load SmartTimetable-specific path-scoped rules automatically (when you touch files)
- Read relevant memory files for the new module
- Carry forward awareness of what you did in HPC (in case of cross-module dependencies)

---------------------------------------------------------------------------------------------------------------------------------------------------

### Switch Module Context (Fresh Session — Recommended for Long Work)

If the session is getting long or you want a clean context:

```
/clear
```

Then start fresh:
```
> I'm working on SmartTimetable module. Read AI Brain context and resume from where we left off — check AI_Brain/state/progress.md for current status.
```

---------------------------------------------------------------------------------------------------------------------------------------------------

### Compact Context (Keep History but Free Space)

If you don't want to lose history but need to free context:

```
/compact Focus on SmartTimetable module going forward
```

This summarizes the conversation and keeps the SmartTimetable focus.

---------------------------------------------------------------------------------------------------------------------------------------------------

### Resume a Previous Module Session

```bash
# From terminal — pick from session list
claude --resume

# Inside Claude — search past sessions
/resume
```

Use the session picker:
- **Arrow keys** to navigate sessions
- **P** to preview a session before resuming
- **/** to search/filter sessions
- **B** to filter by current git branch
- **Enter** to resume selected session


=========================================================================================================================================================

## 4. Switching Work Types

### Development → Testing

```
> Switch to testing mode for {ModuleName}. Read AI Brain test templates
> and testing strategy. Let's write tests for what we just built.
```

Or directly use the test skill:

```
/test {ModuleName}
```

### Testing → Development

```
> Tests are done. Back to development on {ModuleName}.
> {describe next feature or fix}
```

### Development → Module Design / Architecture

```
> Let's switch to architecture mode. I need to design the database schema
> and module structure for {feature/module}. Read AI_Brain/agents/db-architect.md
```

Or use Plan Mode for safe read-only exploration:

```
Shift+Tab    (cycle until you see "Plan" mode in the status bar)
```

In Plan Mode, Claude:
- Only reads files — won't write or execute anything
- Analyzes architecture and proposes a plan
- Press `Shift+Tab` again to return to normal mode to execute

### Development → Code Review

```
/review
```

Or for a deep review:
```
> Review the {ModuleName} module — use code-reviewer agent for full audit
```

### Development → Frontend / UI Work

```
/frontend page {ModuleName} index
/frontend form {ModuleName} {ModelName}
```

### Quick Reference — Work Type Switches

| Switching To | Command / Prompt |
|-------------|-----------------|
| **Testing** | `/test ModuleName` or ask to write tests |
| **Code Review** | `/review` or `/review Modules/ModuleName/` |
| **Schema Design** | `/schema ModuleName` |
| **Frontend / UI** | `/frontend page ModuleName index` |
| **Architecture Planning** | `Shift+Tab` (Plan Mode) |
| **Linting / Code Style** | `/lint` or `/lint Modules/ModuleName/` |
| **Module Status Check** | `/module-status ModuleName` |
| **Debugging** | Paste error + "Debug this in {ModuleName}" |

=========================================================================================================================================================

## 5. Updating AI Brain

### After Making Changes to AI Brain Files

```bash
# Navigate to AI Brain
cd /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain

# Re-deploy rules, skills, agents
bash claude-config/setup.sh
```

Then **restart Claude** (exit with `Ctrl+D`, then `claude`) for changes to take effect.

### Ask Claude to Update AI Brain State

```
> Update AI Brain progress — SmartTimetable constraint CRUD completed
> Save decision to AI Brain — D18: {decision description}
> Add to AI Brain known issues — {bug description and fix}
```

### What Gets Updated Where

| What to Update | AI Brain File | Prompt |
|---------------|---------------|--------|
| Module completion | `state/progress.md` | "Update progress — {module} {what's done}" |
| Design decisions | `state/decisions.md` | "Save decision — {D-number}: {description}" |
| Bugs / Gotchas | `lessons/known-issues.md` | "Add known issue — {description}" |
| Project context | `memory/*.md` | "Update AI Brain memory — {what changed}" |

---

## 6. Git Commands

### Commit Changes

```
> Commit my changes
```

Claude will:
1. Run `git status` and `git diff`
2. Draft a commit message based on the changes
3. Stage and commit (after your approval)

Or be specific:
```
> Commit the SmartTimetable constraint changes with message "Add constraint CRUD"
```

### Push to Remote

```
> Push to remote
> Push to origin Brijesh_SmartTimetable_2026Mar10
```

### Pull / Fetch from Remote

```
> Pull latest changes from remote
> Fetch and merge from origin multi-tenancy-2
```

Or directly in terminal:
```bash
git pull origin Brijesh_SmartTimetable_2026Mar10
git fetch origin
```

### Create a Pull Request

```
> Create a PR from current branch to multi-tenancy-2
```

Claude uses `gh pr create` and drafts a title + description from your commits.

### Check PR Status

```
> Check PR status for my branch
> Show comments on PR #123
```

### View Changes Before Committing

```
/diff
```

Opens an interactive diff viewer showing all uncommitted changes.

---

## 7. Other Daily-Use Commands

### Session Management

| Command | What It Does |
|---------|-------------|
| `/clear` | Clear conversation, start fresh (keeps files) |
| `/compact` | Summarize conversation to free context space |
| `/compact Focus on {topic}` | Summarize with specific focus |
| `/resume` | Browse and resume past sessions |
| `/fork feature-x` | Branch current session into a new one |
| `/rename timetable-crud` | Name the current session for easy resume later |
| `/export session.txt` | Export conversation as text file |

### Information & Status

| Command | What It Does |
|---------|-------------|
| `/context` | Show context usage (how much space is left) |
| `/cost` | Show token usage and cost for this session |
| `/status` | Show version, model, account info |
| `/module-status` | Show all modules status from AI Brain |
| `/module-status SmartTimetable` | Detailed status for one module |
| `/help` | Show all available commands |

### Model & Mode

| Command | What It Does |
|---------|-------------|
| `Shift+Tab` | Cycle modes: Normal → Auto-Accept → Plan |
| `/model sonnet` | Switch to Sonnet (faster, cheaper) |
| `/model opus` | Switch to Opus (most capable) |
| `/fast on` | Enable fast mode (same model, faster output) |
| `/fast off` | Disable fast mode |
| `Option+P` (Mac) | Switch model without clearing prompt |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+C` | Cancel current generation |
| `Ctrl+D` | Exit Claude Code |
| `Ctrl+L` | Clear terminal screen |
| `Ctrl+O` | Toggle verbose output (see tool details) |
| `Shift+Tab` | Cycle permission modes |
| `Option+Enter` | New line in prompt (multiline input) |
| `Esc+Esc` | Rewind to previous checkpoint |
| `\` + `Enter` | Quick multiline escape |

### AI Brain Slash Commands

| Command | What It Does |
|---------|-------------|
| `/test ModuleName` | Run Pest tests |
| `/review` | Code review (security, tenancy, performance) |
| `/schema ModuleName` | Generate or validate DB schema |
| `/lint` | PHP syntax + PSR-12 check |
| `/module-status` | Module status report |
| `/frontend page Module index` | Create Blade page |
| `/frontend form Module Model` | Generate CRUD forms |
| `/frontend audit Module` | Audit frontend for issues |

---

## 8. Common Workflows (Copy-Paste Ready)

### Morning Startup
```bash
cd /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain && \
git pull && bash claude-config/setup.sh && \
cd /Users/bkwork/Herd/laravel && claude
```

### Start Feature Development
```
> I'm working on {ModuleName} module — adding {feature description}.
> Read AI Brain context first.
```

### Switch Module Mid-Session
```
> Switching to {ModuleName}. Read AI Brain context for this module.
```

### Run Tests After Development
```
/test {ModuleName}
```

### Review Before Commit
```
/review
```

### Commit + Push
```
> Commit my changes
> Push to remote
```

### End of Day — Save Progress
```
> Update AI Brain progress — {ModuleName} {what was completed today}
```

### Name Session for Tomorrow
```
/rename {descriptive-name}
```

Then tomorrow, resume with:
```bash
claude --resume {descriptive-name}
```

---

## Quick Lookup Table

| I want to... | Do this |
|-------------|---------|
| Start fresh morning session | Run the one-liner from Section 1 |
| Resume yesterday's work | `claude --resume` |
| Switch to another module | Tell Claude: "Switching to {Module}" |
| Switch to testing | `/test ModuleName` |
| Switch to code review | `/review` |
| Switch to frontend work | `/frontend page Module index` |
| Design database schema | `/schema ModuleName` |
| Check module status | `/module-status ModuleName` |
| Free up context space | `/compact` |
| Start completely fresh | `/clear` |
| Enter safe exploration mode | `Shift+Tab` (Plan mode) |
| Commit my work | "Commit my changes" |
| Push to remote | "Push to remote" |
| Create a PR | "Create PR to multi-tenancy-2" |
| Save today's progress | "Update AI Brain progress" |
| Name session for later | `/rename my-session-name` |
| See what's using context | `/context` |
| Check session cost | `/cost` |
| Export conversation | `/export filename.txt` |
| See session logs | `ls ~/.claude/projects/-Users-bkwork-Herd-laravel/*.jsonl` |
