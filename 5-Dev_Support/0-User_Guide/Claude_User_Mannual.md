# Claude AI Brain — User Manual

> **Version:** 1.1 | **Date:** 2026-03-13 | **Author:** Brijesh (Architect)
> **Audience:** Any developer working on the Prime-AI project with Claude Code CLI

---

## Table of Contents

1. [What is AI Brain?](#1-what-is-ai-brain)
2. [Architecture Overview](#2-architecture-overview)
3. [Daily Startup Procedure](#3-daily-startup-procedure)
4. [Day-to-Day Workflows](#4-day-to-day-workflows)
   - 4.1 [Development Workflow](#41-development-workflow)
   - 4.2 [Testing Workflow](#42-testing-workflow)
   - 4.3 [Database Design Workflow](#43-database-design-workflow)
   - 4.4 [Frontend Development Workflow](#44-frontend-development-workflow)
   - 4.5 [Code Review Workflow](#45-code-review-workflow)
   - 4.6 [Debugging Workflow](#46-debugging-workflow)
5. [Module-Specific Guidance](#5-module-specific-guidance)
6. [Slash Commands Reference](#6-slash-commands-reference)
7. [Subagents Reference](#7-subagents-reference)
8. [Path-Scoped Rules (Auto-Loading)](#8-path-scoped-rules-auto-loading)
9. [Precautions](#9-precautions)
10. [Troubleshooting](#10-troubleshooting)
11. [Maintenance & Updates](#11-maintenance--updates)
12. [Quick Reference Card](#12-quick-reference-card)

---

## 1. What is AI Brain?

AI Brain is the project's centralized knowledge base that gives Claude Code deep context about Prime-AI's architecture, conventions, known issues, and development rules. Without it, Claude starts every session with zero knowledge of the project. With it, Claude understands:

- Multi-tenancy architecture (3-layer database, 368+ tables)
- All 29 modules, their scope, and current status
- Table prefix conventions, naming patterns
- Known bugs and security issues to avoid
- Templates for consistent code generation
- Module-specific rules that auto-load when you touch related files

**Location:** `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/`

---

## 2. Architecture Overview

AI Brain uses a **hybrid architecture** — files are stored in one place but deployed to three locations:

```
+---------------------------------------------+
|          DATABASE REPO (Source of Truth)      |
|          prime-ai_db/databases/AI_Brain/      |
|                                               |
|  memory/     - Project knowledge base         |
|  rules/      - Universal development rules    |
|  agents/     - Role-specific AI guides        |
|  templates/  - Code boilerplates              |
|  lessons/    - Known issues & fixes           |
|  state/      - Progress & decisions           |
|  tasks/      - Task tracking                  |
|  claude-config/  - Deployable config          |
|    ├── rules/    - Path-scoped module rules   |
|    ├── skills/   - Slash commands             |
|    ├── agents/   - Subagents                  |
|    └── setup.sh  - Deployment script          |
+---------------------------------------------+
           |
           | bash setup.sh deploys to:
           |
    +------+--------+------------------+
    |               |                  |
    v               v                  v
LARAVEL REPO    LARAVEL REPO      USER HOME
CLAUDE.md       .claude/rules/    ~/.claude/skills/
(~60 lines,     (auto-load when   ~/.claude/agents/
 entry point)    you touch files)  (global tools)
```

### Why This Split?

| Location | What Lives There | Why |
|----------|-----------------|-----|
| `AI_Brain/` (DB repo) | Knowledge base, source config | Single branch, only Architect edits — no conflicts |
| `CLAUDE.md` (Laravel repo) | Minimal entry point | Committed to Git, all 3 developers see it |
| `.claude/rules/` (Laravel repo) | Path-scoped rules | Must be in project dir for auto-loading; gitignored |
| `~/.claude/skills/` (Home) | Slash commands | User-level, available in any project |
| `~/.claude/agents/` (Home) | Subagents | User-level, available in any project |

---

## 3. Daily Startup Procedure

### After System Restart / New Day

Every time you start your system or begin a new work session, follow these steps **in order**:

#### Step 1: Open Terminal and Navigate to AI Brain

```bash
cd /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
```

#### Step 2: Pull Latest Changes (if using Git)

```bash
git pull origin Brijesh_SmartTimetable_2026Mar10
```

This ensures you have the latest AI Brain updates (rules, memory, known issues).

#### Step 3: Run the Deployment Script

```bash
bash claude-config/setup.sh
```

**This is the most important step.** It deploys:
- 6 path-scoped rules to `/Users/bkwork/Herd/laravel/.claude/rules/`
- 6 slash commands (skills) to `~/.claude/skills/`
- 4 subagents to `~/.claude/agents/`

You should see output like:
```
==========================================
  AI Brain — Deployment Script
==========================================

── Step 1: Deploying path-scoped rules ──
   Copied 6 rule files to /Users/bkwork/Herd/laravel/.claude/rules/
── Step 2: Checking .gitignore ──
   .claude/ already in .gitignore
── Step 3: Deploying skills ──
   Deployed 6 skills to /Users/bkwork/.claude/skills/
── Step 4: Deploying agents ──
   Deployed 4 agents to /Users/bkwork/.claude/agents/

==========================================
  Deployment Complete!
==========================================
```

#### Step 4: Start Claude Code in the Laravel Project

```bash
cd /Users/bkwork/Herd/laravel
claude
```

#### Step 5: Verify Claude Has Context

When Claude starts, it automatically reads `CLAUDE.md` which points to the AI Brain. You can verify by asking:

```
> What is the AI Brain location?
> How many modules does this project have?
```

If Claude answers correctly (AI Brain at database repo, 29 modules), you're good to go.

### Quick Start (Copy-Paste)

```bash
# Run this every morning
cd /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain && \
git pull && \
bash claude-config/setup.sh && \
cd /Users/bkwork/Herd/laravel && \
claude
```

---

## 4. Day-to-Day Workflows

### 4.1 Development Workflow

#### Starting a New Feature in a Module

1. **Tell Claude which module you're working on:**
   ```
   > I need to add a new feature to the SmartTimetable module — {describe feature}
   ```

2. **Claude will automatically:**
   - Read `AI_Brain/README.md` and relevant memory files
   - Load path-scoped rules when you touch module files (e.g., SmartTimetable rules auto-load when editing `Modules/SmartTimetable/**`)
   - Follow templates for new controllers, services, models, migrations

3. **Ask Claude to use templates:**
   ```
   > Create a new service class for {feature} — use the AI Brain template
   ```
   Claude references `AI_Brain/templates/module-service.md` for consistent structure.

4. **After completing the feature:**
   ```
   > Update the progress in AI Brain
   ```
   Claude updates `AI_Brain/state/progress.md`.

#### Creating a New Module

```
> Create a new module called {ModuleName} — follow the module-agent guide
```

Claude reads `AI_Brain/agents/module-agent.md` and `AI_Brain/templates/module-structure.md` to scaffold the complete module structure.

#### Adding a New Database Table

```
> I need a new table for {purpose} in the {Module} module — design the schema
```

Or use the slash command:
```
> /schema ModuleName
```

Claude reads `AI_Brain/agents/db-architect.md`, uses v2 DDL files as reference, and follows naming conventions (prefix, required columns).

#### Writing API Endpoints

```
> Create REST API endpoints for {resource} in {Module}
```

Claude reads `AI_Brain/agents/api-builder.md` and `AI_Brain/templates/api-response.md` for consistent JSON response format.

---

### 4.2 Testing Workflow

#### Running Tests

Use the slash command:
```
> /test                           # Run all tests
> /test SmartTimetable            # Run module tests
> /test tests/Feature/MyTest.php  # Run specific file
> /test --filter="can create"     # Run matching tests
```

#### Writing New Tests

```
> Write tests for the {ClassName} — follow AI Brain test templates
```

Claude uses:
- `AI_Brain/templates/test-unit.md` for unit tests
- `AI_Brain/templates/test-feature-central.md` for central feature tests
- `AI_Brain/templates/test-feature-tenant.md` for tenant feature tests
- `AI_Brain/agents/test-agent.md` for testing strategy

**Key rules Claude follows automatically:**
- Uses Pest 4.x syntax (not PHPUnit class-based)
- 3 test types: unit, central feature, tenant feature
- Tenant tests include proper tenancy initialization

#### Running Tests in Background (Subagent)

For large test suites, Claude can use the **test-runner** subagent which runs tests in isolation (keeps main conversation clean):
```
> Run the full test suite using the test-runner agent
```

---

### 4.3 Database Design Workflow

#### Designing Schema

```
> Design the database schema for {feature description}
```

Claude reads `AI_Brain/agents/db-architect.md` and ensures:
- Correct table prefix (e.g., `tt_` for timetable, `std_` for student)
- Required columns: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- Foreign keys with indexes
- Proper data types matching the convention

#### Validating Schema-Model Alignment

Use the slash command:
```
> /schema validate SmartTimetable
```

Or use the **db-analyzer** subagent:
```
> Check schema-model alignment for the SmartTimetable module
```

This verifies:
- Every `$fillable` field exists in migration/DDL
- `$casts` types match DB column types
- Relationships have matching FK columns
- No orphan tables or models

#### Creating Migrations

```
> /schema migrate SmartTimetable
```

Claude generates migrations in the correct path:
- Central tables: `database/migrations/`
- Tenant tables: `database/migrations/tenant/`

---

### 4.4 Frontend Development Workflow

The project uses **Blade templates + Alpine.js + AdminLTE 4** — no SPA frameworks. A rich library of 40+ reusable Blade components exists at `resources/views/components/backend/`.

#### Creating a New Page

Use the slash command:
```
> /frontend page SmartTimetable index       # Index page with data table
> /frontend page SmartTimetable create      # Create form
> /frontend page SmartTimetable edit        # Edit form
> /frontend page SmartTimetable show        # Detail view
```

Claude will:
- Extend the correct AdminLTE layout
- Reuse existing Blade components (`<x-backend.form.input-text>`, `<x-backend.form.select-dropdown>`, etc.)
- Add Alpine.js for interactivity (show/hide, toggles, tabs)
- Place the file in `resources/views/backend/v1/{module-name}/`

#### Generating CRUD Forms

```
> /frontend form SmartTimetable TimetableConstraint
```

Claude reads the model's `$fillable`, the FormRequest validation rules, and auto-maps fields to the correct Blade components (text inputs, dropdowns, checkboxes, date pickers).

#### Building Data Tables

```
> /frontend table SchoolSetup ClassSection
```

Generates an index page with sortable columns, action buttons, status toggles, pagination, and search.

#### Adding Charts (Dashboard)

```
> /frontend chart bar          # Bar chart
> /frontend chart line         # Line chart
> /frontend chart pie          # Pie chart
> /frontend chart donut        # Donut chart
```

Uses ApexCharts with Alpine.js initialization pattern.

#### Auditing Frontend Code

```
> /frontend audit SmartTimetable
```

Checks for security issues (`{!! !!}`), missing CSRF, accessibility gaps, raw HTML where components should be used, and jQuery-vs-Alpine consistency.

#### Key Frontend Rules Claude Follows

- **Never writes raw HTML form elements** — always uses existing Blade components
- **Always includes `@csrf`** on forms, `@method('PUT/DELETE')` for non-POST
- **Uses `{{ }}` (escaped)** — never `{!! !!}` unless rendering trusted HTML
- **Prefers Alpine.js** for new interactivity, jQuery only for Select2/FullCalendar integration
- **Uses Axios** for new AJAX calls, jQuery $.ajax only for legacy code

---

### 4.5 Code Review Workflow

#### Quick Review

```
> /review                           # Review staged changes
> /review Modules/SmartTimetable/   # Review a module
> /review path/to/file.php          # Review specific file
```

#### Deep Review (Subagent)

For comprehensive review, use the **code-reviewer** subagent:
```
> Review the SmartTimetable module for security and tenancy issues
```

The review checks:
- **Security:** `$request->all()`, sensitive `$fillable`, raw SQL, XSS, CSRF
- **Tenancy:** Cross-tenant queries, missing tenant context, wrong migration path
- **Performance:** N+1 queries, unbounded queries, missing caching
- **Code Quality:** Business logic in controllers, inline validation, PSR-12

#### Performance Audit (Subagent)

```
> Audit the SmartTimetable controllers for performance issues
```

Uses **performance-auditor** subagent to find:
- N+1 queries (relationships in loops without eager loading)
- `Model::all()` (unbounded queries)
- `updateOrCreate` in loops (should use `DB::upsert()`)
- Missing indexes on filtered/sorted columns

---

### 4.6 Debugging Workflow

```
> Debug this error: {paste error message}
> I'm getting {describe issue} in {Module}
```

Claude reads `AI_Brain/agents/debugger.md` and `AI_Brain/lessons/known-issues.md` to:
- Check if this is a known issue (many are documented with fixes)
- Apply tenancy-aware debugging (most common source of bugs)
- Suggest fixes based on project patterns

---

## 5. Module-Specific Guidance

### Modules with Path-Scoped Rules (Auto-Loading)

These modules have dedicated rules that **automatically load** when Claude touches their files:

| Module | Rule File | Auto-Loads When Touching |
|--------|-----------|--------------------------|
| SmartTimetable | `smart-timetable.md` | `Modules/SmartTimetable/**`, `*timetable*`, `*constraint*`, `*parallel*` migrations |
| Hpc | `hpc.md` | `Modules/Hpc/**`, `*hpc*` migrations |
| SchoolSetup | `school-setup.md` | `Modules/SchoolSetup/**`, `*school*`, `*class*`, `*section*`, `*subject*`, `*teacher*`, `*room*` migrations |
| StudentFee | `student-fee.md` | `Modules/StudentFee/**`, `*fee*`, `*fin_*` migrations |

### SmartTimetable Module (Special Notes)

This is the most complex module (84 models). Key decisions Claude knows:
- **D11:** FET solver integration for timetable generation
- **D14:** Parallel periods handling
- **D16:** Constraint CRUD management
- **D17:** Model/migration fixes

### HPC Module (Special Notes)

- **D13:** PDF templates must use `<table>` layout — no Blade components, no Bootstrap, no flexbox (DomPDF limitation)

### Modules Without Path-Scoped Rules

For modules without dedicated rules (e.g., Transport, Syllabus, QuestionBank), Claude still uses:
- Universal rules from `AI_Brain/rules/` (tenancy, module conventions, security)
- Module information from `AI_Brain/memory/modules-map.md`
- Templates from `AI_Brain/templates/`

To work on any module:
```
> I'm working on the {ModuleName} module — {describe task}
```

Claude will read the relevant context from AI Brain automatically.

---

## 6. Slash Commands Reference

These are available after running `setup.sh`. Type them directly in Claude:

| Command | Purpose | Example |
|---------|---------|---------|
| `/test` | Run Pest tests | `/test SmartTimetable` |
| `/review` | Code review (security, tenancy, performance) | `/review Modules/Hpc/` |
| `/schema` | Generate or validate DB schema | `/schema validate SmartTimetable` |
| `/lint` | PHP syntax + PSR-12 style check | `/lint Modules/Transport/` |
| `/module-status` | Module status report | `/module-status SmartTimetable` |
| `/frontend` | Build Blade views, forms, tables, charts | `/frontend form SmartTimetable Constraint` |

### Detailed Usage

#### /test
```
/test                              # All tests
/test SmartTimetable               # Module tests
/test tests/Feature/MyTest.php     # Specific file
/test --filter="can create"        # Filter by name
```

#### /review
```
/review                            # Staged git changes
/review path/to/file.php           # Specific file
/review Modules/ModuleName/        # Entire module
```

#### /schema
```
/schema ModuleName                 # Generate schema for new module
/schema validate ModuleName        # Validate schema-model alignment
/schema migrate ModuleName         # Generate new migration
```

#### /lint
```
/lint                              # All changed files
/lint path/to/file.php             # Specific file
/lint Modules/ModuleName/          # Entire module
```

#### /module-status
```
/module-status                     # All modules overview
/module-status SmartTimetable      # Detailed report for one module
```

#### /frontend
```
/frontend page ModuleName index    # Create index page with data table
/frontend page ModuleName create   # Create form page
/frontend form ModuleName Model    # Generate CRUD forms from model
/frontend table ModuleName Model   # Generate index with data table
/frontend component CompName       # Create a reusable Blade component
/frontend chart bar                # Add ApexCharts chart (bar/line/pie/donut)
/frontend modal ModalName          # Create a reusable modal
/frontend audit ModuleName         # Audit views for issues
```

---

## 7. Subagents Reference

Subagents are specialized Claude instances that run in isolation. They handle heavy tasks without cluttering your main conversation.

| Agent | Model | Purpose | When to Use |
|-------|-------|---------|-------------|
| **test-runner** | Haiku (fast) | Run tests, return summary | Large test suites, background testing |
| **code-reviewer** | Sonnet (balanced) | Structured code review | Comprehensive security/tenancy audit |
| **performance-auditor** | Sonnet (balanced) | Find N+1, missing indexes | Before PR, after major changes |
| **db-analyzer** | Sonnet (balanced) | Schema-model alignment | After migration changes, new tables |

### How to Invoke Subagents

You don't invoke subagents directly — Claude decides when to use them. But you can request them:

```
> Use the code-reviewer agent to review my staged changes
> Run the performance-auditor on the SmartTimetable controllers
> Check schema alignment using the db-analyzer for SchoolSetup
> Run tests in background using test-runner
```

### Subagent vs Slash Command

| Use Slash Command When... | Use Subagent When... |
|---------------------------|----------------------|
| Quick, focused task | Deep, comprehensive analysis |
| Want results inline | Want heavy output isolated |
| Simple test run | Full test suite with analysis |
| Spot-check a file | Audit entire module |

---

## 8. Path-Scoped Rules (Auto-Loading)

This is one of the most powerful features. When Claude reads or edits a file that matches a rule's `globs` pattern, that rule **automatically loads into context**.

### How It Works

1. Each rule file in `.claude/rules/` has a `globs:` header
2. When Claude touches a file matching that glob, the rule loads
3. No manual action needed — it's automatic

### Currently Deployed Rules

| Rule | Globs (Triggers) | What It Enforces |
|------|-------------------|-----------------|
| `smart-timetable.md` | `Modules/SmartTimetable/**`, timetable/constraint/parallel migrations | D11 FET solver, D14 parallel periods, D16 constraint CRUD, D17 fixes |
| `hpc.md` | `Modules/Hpc/**`, HPC migrations | D13 DomPDF table-only templates |
| `testing.md` | `tests/**`, `phpunit.xml`, module tests | Pest 4.x syntax, 3 test types, tenant test setup |
| `migrations.md` | `database/migrations/**` | Central vs tenant paths, additive only, naming conventions |
| `school-setup.md` | `Modules/SchoolSetup/**`, school/class/section/subject/teacher/room migrations | SchoolSetup-specific patterns |
| `student-fee.md` | `Modules/StudentFee/**`, fee/fin migrations | StudentFee-specific patterns |

### You Don't Need to Do Anything

Just work normally. If you edit a timetable controller, Claude automatically loads SmartTimetable rules. If you create a migration, migration rules load. This is completely transparent.

---

## 9. Precautions

### CRITICAL — Must Follow

1. **Never Mix Central and Tenant Code**
   - Know whether you're working in central context (Prime, GlobalMaster, Billing) or tenant context (SchoolSetup, SmartTimetable, etc.)
   - Central models use `prime_db`, tenant models use `tenant_db`
   - Cross-tenant queries are a data breach — never query another tenant's database

2. **Never Use Non-v2 DDL Files**
   - ONLY use these 3 files for schema reference:
     - `databases/1-master_dbs/1-DDLs/global_db_v2.sql`
     - `databases/1-master_dbs/1-DDLs/prime_db_v2.sql`
     - `databases/1-master_dbs/1-DDLs/tenant_db_v2.sql`
   - Files without `_v2` suffix are **outdated and incorrect**
   - Files in `2-Prime_Modules/`, `2-Tenant_Modules/`, `Old_DDLs/` are **deprecated**

3. **Run `setup.sh` After Every AI Brain Update**
   - If you (or anyone) update files in `AI_Brain/claude-config/`, run the deployment script
   - Otherwise Claude will use stale rules/skills/agents

4. **Don't Commit `.claude/` to Laravel Repo**
   - `.claude/` is in `.gitignore` — keep it that way
   - It contains local deployment from AI Brain, not shared config
   - If Git asks to track `.claude/`, something went wrong — check `.gitignore`

### HIGH — Should Follow

5. **Always Read AI Brain Before Major Tasks**
   - For new features, ask Claude to read the relevant agent file first
   - Example: `Read AI_Brain/agents/db-architect.md before designing this schema`

6. **Update Progress After Completing Tasks**
   - Tell Claude: `Update AI Brain progress — {module} {what was completed}`
   - This keeps `state/progress.md` current for future sessions

7. **Save Architectural Decisions**
   - When making design choices, tell Claude: `Save this decision to AI Brain — {decision description}`
   - This goes to `state/decisions.md` with a D-number

8. **Record New Bugs/Issues**
   - When discovering non-obvious bugs, tell Claude: `Add this to AI Brain known issues — {bug description}`
   - This goes to `lessons/known-issues.md`

### MODERATE — Good Practice

9. **Use Slash Commands Instead of Verbose Prompts**
   - Instead of: "Can you run the pest tests for the SmartTimetable module and tell me the results?"
   - Just type: `/test SmartTimetable`

10. **Use Subagents for Heavy Analysis**
    - Code review of entire module? Use code-reviewer subagent
    - Performance audit? Use performance-auditor subagent
    - This keeps your main conversation context clean and focused

11. **Be Specific About Module Context**
    - Bad: "Fix the controller"
    - Good: "Fix the TimetableConstraintController in SmartTimetable — the store method isn't validating correctly"

---

## 10. Troubleshooting

### Claude doesn't know about the project

**Symptom:** Claude asks basic questions about the tech stack, doesn't know module names.
**Cause:** `CLAUDE.md` not found or AI Brain not referenced.
**Fix:**
```bash
# Verify CLAUDE.md exists and points to AI Brain
cat /Users/bkwork/Herd/laravel/CLAUDE.md | head -20
```
If missing, check that you're in the correct directory.

### Slash commands not working

**Symptom:** Claude says it doesn't know `/test`, `/review`, etc.
**Cause:** Skills not deployed to `~/.claude/skills/`.
**Fix:**
```bash
cd /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
bash claude-config/setup.sh
```
Then **restart Claude** (exit and re-enter `claude`).

### Path-scoped rules not loading

**Symptom:** Claude doesn't follow module-specific rules when editing files.
**Cause:** Rule files not in `.claude/rules/` or globs don't match.
**Fix:**
```bash
# Check rules are deployed
ls -la /Users/bkwork/Herd/laravel/.claude/rules/

# Should show:
# smart-timetable.md, hpc.md, testing.md, migrations.md, school-setup.md, student-fee.md
```
If empty, run `setup.sh`. If files exist but rules don't load, check the `globs:` patterns in the rule file.

### Claude uses old/wrong DDL files

**Symptom:** Claude references tables or columns that don't exist, or uses wrong schema.
**Cause:** Claude picked up a non-v2 DDL file.
**Fix:** Tell Claude explicitly:
```
> STOP. Only use v2 DDL files: global_db_v2.sql, prime_db_v2.sql, tenant_db_v2.sql.
> Never use files without _v2 suffix.
```

### Subagents not found

**Symptom:** Claude can't find test-runner, code-reviewer, etc.
**Cause:** Agents not deployed to `~/.claude/agents/`.
**Fix:**
```bash
ls -la ~/.claude/agents/
# Should show: test-runner/, code-reviewer/, performance-auditor/, db-analyzer/

# If missing:
bash /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/claude-config/setup.sh
```

### `.claude/` showing in git status

**Symptom:** `git status` shows `.claude/` as untracked.
**Cause:** `.gitignore` entry missing.
**Fix:**
```bash
echo ".claude/" >> /Users/bkwork/Herd/laravel/.gitignore
```
Or run `setup.sh` which checks and adds this automatically.

---

## 11. Maintenance & Updates

### Adding a New Path-Scoped Rule

When a module needs its own Claude rules:

1. Create the rule file in AI Brain source:
   ```
   AI_Brain/claude-config/rules/{module-name}.md
   ```

2. Add the frontmatter with globs:
   ```markdown
   ---
   globs: ["Modules/{ModuleName}/**", "database/migrations/tenant/*{prefix}*"]
   alwaysApply: false
   ---

   # {ModuleName} Module Rules
   {content}
   ```

3. Run deployment:
   ```bash
   bash AI_Brain/claude-config/setup.sh
   ```

### Adding a New Slash Command (Skill)

1. Create the skill directory and file:
   ```
   AI_Brain/claude-config/skills/{skill-name}/SKILL.md
   ```

2. Add required frontmatter:
   ```markdown
   ---
   name: {skill-name}
   description: What it does
   user_invocable: true
   ---

   # /{skill-name} — Title
   {instructions}
   ```

3. Run deployment.

### Adding a New Subagent

1. Create the agent directory and file:
   ```
   AI_Brain/claude-config/agents/{agent-name}/AGENT.md
   ```

2. Add required frontmatter:
   ```markdown
   ---
   name: {agent-name}
   description: What it does
   model: sonnet  # or haiku, opus
   ---

   # {Agent Name}
   {instructions}
   ```

3. Run deployment.

### Updating Existing Files

1. Edit the source file in `AI_Brain/claude-config/`
2. Run `bash AI_Brain/claude-config/setup.sh`
3. Restart Claude session for changes to take effect

### Keeping AI Brain Current

| What | When | How |
|------|------|-----|
| `state/progress.md` | After every completed task | Tell Claude: "Update progress" |
| `state/decisions.md` | After any design decision | Tell Claude: "Save decision D{N}" |
| `lessons/known-issues.md` | When discovering non-obvious bugs | Tell Claude: "Add known issue" |
| `memory/*.md` | When project context changes | Edit directly or tell Claude |
| `claude-config/rules/*.md` | When module patterns are established | Create/edit + run setup.sh |

---

## 12. Quick Reference Card

### Morning Startup
```bash
cd /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain && \
git pull && bash claude-config/setup.sh && \
cd /Users/bkwork/Herd/laravel && claude
```

### Slash Commands
| Command | What It Does |
|---------|-------------|
| `/test SmartTimetable` | Run module tests |
| `/review` | Review staged changes |
| `/schema validate Module` | Check schema-model alignment |
| `/lint` | PHP syntax + style check |
| `/module-status Module` | Module status report |
| `/frontend form Module Model` | Generate CRUD forms from model |
| `/frontend page Module index` | Create a Blade page |

### Common Prompts

**Feature Development:**
```
> I'm adding {feature} to the {Module} module. Read the relevant AI Brain context first.
```

**Schema Design:**
```
> Design the database schema for {table purpose} in {Module}. Use v2 DDLs as reference.
```

**Code Review:**
```
> /review Modules/{ModuleName}/
```

**Frontend Page:**
```
> /frontend form SmartTimetable TimetableConstraint
> /frontend table SchoolSetup ClassSection
> /frontend audit Hpc
```

**Test Writing:**
```
> Write tenant feature tests for {Controller} — use AI Brain test template.
```

**Performance Check:**
```
> Audit {Module} controllers for N+1 queries and performance issues.
```

**Bug Investigation:**
```
> Check AI Brain known issues for {error description}. If not found, debug and add the fix.
```

**Decision Recording:**
```
> Save decision: {description of what was decided and why}
```

### File Locations

| Purpose | Path |
|---------|------|
| AI Brain (source) | `prime-ai_db/databases/AI_Brain/` |
| CLAUDE.md (entry point) | `/Users/bkwork/Herd/laravel/CLAUDE.md` |
| Deployed rules | `/Users/bkwork/Herd/laravel/.claude/rules/` |
| Deployed skills | `~/.claude/skills/` |
| Deployed agents | `~/.claude/agents/` |
| Setup script | `AI_Brain/claude-config/setup.sh` |
| v2 DDLs (schema) | `databases/1-master_dbs/1-DDLs/*_v2.sql` |
| Laravel project | `/Users/bkwork/Herd/laravel/` |

### Key Rules (Always Remember)

1. Never mix central and tenant code
2. Only use `*_v2.sql` DDL files
3. Run `setup.sh` after AI Brain updates
4. Don't commit `.claude/` to Laravel repo
5. Update progress and decisions in AI Brain
6. Use slash commands for common tasks
7. Use subagents for heavy analysis

---

> **Need Help?** Ask Claude: `What does AI Brain know about {topic}?` — Claude will search the knowledge base and give you the answer.
