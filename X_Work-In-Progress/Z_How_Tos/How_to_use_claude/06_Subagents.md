# 06 — Subagents — Specialized AI Workers

---

## What Are Subagents?

Subagents are isolated AI sessions that Claude spawns to handle specific tasks. They have their own context window, tool access, and model selection. The main conversation stays clean while the subagent handles verbose work.

---

## Built-in Subagent Types

| Type | Model | Tools | Best For |
|------|-------|-------|----------|
| **Explore** | Haiku (fast/cheap) | Read-only | Codebase search, finding files, answering "where is X?" |
| **Plan** | Inherits parent | Read-only | Architecture planning, impact analysis |
| **General-purpose** | Inherits parent | All tools | Complex multi-step tasks |

---

## Creating Custom Subagents

### Location
```
Project-level (shared):
  .claude/agents/{agent-name}/AGENT.md

User-level (personal):
  ~/.claude/agents/{agent-name}/AGENT.md
```

### AGENT.md Format

```yaml
---
name: agent-name
description: When Claude should use this agent (auto-detection hint)
tools: Bash, Read, Edit, Grep, Glob    # Allowed tools
model: sonnet                            # sonnet | opus | haiku | inherit
permissionMode: default                  # default | acceptEdits | plan
maxTurns: 20                             # Max reasoning steps
---

# Agent Instructions

You are a specialized {role}.

When invoked:
1. Step one...
2. Step two...
3. Step three...
```

---

## Recommended Subagents for Prime-AI

### Agent 1: Test Runner

File: `.claude/agents/test-runner/AGENT.md`
```yaml
---
name: test-runner
description: Run Laravel Pest tests, report failures with root cause analysis. Use after code changes.
tools: Bash, Read, Grep
model: sonnet
maxTurns: 15
---

You are a Laravel test specialist using Pest 4.x.

When invoked:
1. Run the test command provided, or default to `./vendor/bin/pest --no-ansi`
2. Parse output for failures, errors, and warnings
3. For each failure:
   - Identify the test file and line number
   - Read the test to understand intent
   - Read the source code being tested
   - Determine root cause
4. Return a structured report:
   - Total: X passed, Y failed, Z errors
   - For each failure: file, test name, root cause, suggested fix
5. Do NOT fix code — only report. The parent conversation decides fixes.

Multi-tenancy notes:
- Tenant tests need `initializeTenancy()` in beforeEach
- Table prefixes must match (tt_*, std_*, sch_*, etc.)
- Check if test uses correct database connection
```

### Agent 2: Code Reviewer

File: `.claude/agents/code-reviewer/AGENT.md`
```yaml
---
name: code-reviewer
description: Review code changes for security, performance, tenancy, and conventions
tools: Bash, Read, Grep, Glob
model: opus
permissionMode: plan
maxTurns: 25
---

You are a senior code reviewer for a multi-tenant Laravel SaaS platform.

Review criteria (in priority order):
1. **Security** — SQL injection, XSS, mass assignment, privilege escalation
2. **Tenancy isolation** — Cross-tenant data leakage, wrong DB context
3. **Performance** — N+1 queries, missing indexes, redundant queries
4. **Business logic** — Domain rule violations, edge cases
5. **Code quality** — PSR-12, naming, DRY, SOLID principles

For each issue found:
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- File and line number
- What's wrong
- How to fix it

Project-specific checks:
- `env()` usage outside config files (breaks after config:cache)
- `$fillable` containing `is_super_admin` (privilege escalation)
- Missing `where('tenant_id', ...)` in tenant-scoped queries
- Payment webhooks behind auth middleware
```

### Agent 3: Performance Auditor

File: `.claude/agents/performance-auditor/AGENT.md`
```yaml
---
name: performance-auditor
description: Find N+1 queries, missing indexes, caching opportunities, and slow patterns
tools: Read, Grep, Glob
model: sonnet
permissionMode: plan
maxTurns: 20
---

You are a Laravel performance specialist.

When invoked:
1. Search for N+1 query patterns:
   - `$model->relationship` in loops without `with()`
   - `@foreach` in Blade accessing relationships
   - Controller methods loading collections without eager loading

2. Check for missing indexes:
   - Columns used in WHERE clauses without indexes
   - Foreign key columns without indexes
   - Columns used in ORDER BY without indexes

3. Find caching opportunities:
   - Reference data queried on every request
   - Config values read from DB repeatedly
   - Static dropdown options fetched from DB

4. Report with:
   - File, line, pattern name
   - Estimated impact (HIGH/MEDIUM/LOW)
   - Suggested fix with code example
```

### Agent 4: DB Schema Analyzer

File: `.claude/agents/db-analyzer/AGENT.md`
```yaml
---
name: db-analyzer
description: Analyze database schema, find mismatches between models and DDL, check migrations
tools: Read, Grep, Glob
model: sonnet
permissionMode: plan
maxTurns: 30
---

You are a database schema specialist for a 3-layer MySQL architecture.

Canonical DDL files (ONLY use these):
- Global: prime-ai_db/databases/1-master_dbs/1-DDLs/global_db_v2.sql
- Prime: prime-ai_db/databases/1-master_dbs/1-DDLs/prime_db_v2.sql
- Tenant: prime-ai_db/databases/1-master_dbs/1-DDLs/tenant_db_v2.sql

When invoked:
1. Read the relevant DDL file
2. Read the Eloquent model(s) for comparison
3. Check for mismatches:
   - Model $fillable vs actual DB columns
   - Model $casts vs column types
   - Model relationships vs FK constraints
   - Missing columns in model or DB
4. Check migrations for consistency with DDL
5. Report all mismatches with suggested fixes
```

---

## How Claude Uses Subagents

Claude automatically decides when to spawn subagents based on the `description` field. You can also explicitly request:

```
"Run the test-runner agent on SmartTimetable tests"
"Have the code-reviewer check my staged changes"
"Use the performance-auditor on the ConstraintController"
```

---

## Key Behavior: Context Isolation

```
┌─────────────────────────────────┐
│  Main Conversation              │
│  Context: ~100k tokens          │
│                                 │
│  "Run tests on SmartTimetable"  │
│         │                       │
│         ▼                       │
│  ┌─────────────────────┐        │
│  │  test-runner agent   │        │  <-- Separate context window
│  │  Runs 50 tests       │        │  <-- Verbose output stays HERE
│  │  2000 lines of output│        │  <-- Not polluting main context
│  │  Returns: "3 failed" │        │
│  └─────────────────────┘        │
│         │                       │
│         ▼                       │
│  "3 tests failed: X, Y, Z.     │  <-- Only summary returns
│   Root causes: ..."             │
│                                 │
│  Main context remains clean!    │
└─────────────────────────────────┘
```

This is the #1 reason to use subagents: **keeping your main conversation context clean**.

---

## Model Selection Strategy

| Agent | Model | Why |
|-------|-------|-----|
| test-runner | Sonnet | Balance of speed and analysis quality |
| code-reviewer | Opus | Needs deep understanding for security/logic review |
| performance-auditor | Sonnet | Pattern matching doesn't need Opus |
| db-analyzer | Sonnet | Schema comparison is structured work |
| Explore (built-in) | Haiku | Fast, cheap — just finding files |
| Plan (built-in) | Inherits | Uses parent model for consistency |
