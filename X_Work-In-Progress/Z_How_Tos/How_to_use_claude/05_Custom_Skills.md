# 05 — Custom Skills (Slash Commands)

---

## What Are Skills?

Skills are reusable workflows triggered by `/skill-name`. They are markdown files that tell Claude exactly what to do, with what tools, and in what order. Think of them as saved prompts with superpowers.

---

## Where Skills Live

```
Project-level (shared with team via git):
  .claude/skills/{skill-name}/SKILL.md

User-level (personal, all projects):
  ~/.claude/skills/{skill-name}/SKILL.md
```

---

## SKILL.md Format

```yaml
---
name: skill-name                    # Lowercase, hyphens only
description: What this skill does   # Claude uses this to auto-detect when to invoke
tools: Bash, Read, Edit, Grep       # Which tools the skill can use
model: sonnet                       # sonnet | opus | haiku | inherit
disable-model-invocation: false     # true = only manual /invoke, never auto
context: fork                       # fork = run in subagent (isolated context)
agent: general-purpose              # Which subagent type (if context: fork)
---

# Instructions for Claude

Step-by-step instructions go here.
Use $ARGUMENTS for user-provided arguments.

Example:
1. Run `./vendor/bin/pest $ARGUMENTS --no-ansi`
2. Parse output for failures
3. Fix root causes
4. Re-run tests
```

---

## Recommended Skills for Prime-AI

### Skill 1: `/test` — Run Tests

File: `.claude/skills/test/SKILL.md`
```yaml
---
name: test
description: Run Pest tests, analyze failures, and fix issues. Use proactively after code changes.
tools: Bash, Read, Edit, Grep
model: sonnet
---

Run the Laravel test suite with Pest:

1. If $ARGUMENTS provided, run: `./vendor/bin/pest $ARGUMENTS --no-ansi`
   Otherwise run: `./vendor/bin/pest --no-ansi`

2. Parse output for:
   - Total tests, passed, failed, errors
   - Failure messages and stack traces
   - Which files and line numbers failed

3. For each failure:
   - Read the test file to understand intent
   - Read the source code being tested
   - Identify root cause
   - Fix the source code (not the test, unless test is wrong)

4. Re-run failed tests to verify fixes

5. Report summary: what failed, why, what you fixed
```

### Skill 2: `/migrate` — Run Migrations Safely

File: `.claude/skills/migrate/SKILL.md`
```yaml
---
name: migrate
description: Run Laravel migrations safely with status check and rollback awareness
tools: Bash, Read
model: sonnet
disable-model-invocation: true
---

Run Laravel migrations safely:

1. First check migration status:
   `php artisan migrate:status`

2. Show pending migrations to user and get confirmation

3. If user confirms, run:
   - Central: `php artisan migrate`
   - Tenant: `php artisan tenants:migrate`

4. Verify success with `php artisan migrate:status`

5. If errors occur, show the error and suggest:
   - Check if table already exists
   - Check for FK constraint issues
   - Suggest rollback command if needed

NEVER run `migrate:fresh` or `migrate:reset` without explicit user permission.
```

### Skill 3: `/review` — Code Review

File: `.claude/skills/review/SKILL.md`
```yaml
---
name: review
description: Review code changes for quality, security, and conventions
tools: Bash, Read, Grep
model: opus
context: fork
---

Perform a thorough code review:

1. Get the diff to review:
   - If $ARGUMENTS is a PR number: `gh pr diff $ARGUMENTS`
   - If $ARGUMENTS is a file: `git diff -- $ARGUMENTS`
   - If empty: `git diff --staged` (staged changes)

2. Analyze each changed file for:
   - **Security:** SQL injection, XSS, mass assignment, env() in routes
   - **Tenancy:** Mixed central/tenant context, missing tenant scoping
   - **Performance:** N+1 queries, missing indexes, unnecessary eager loading
   - **Style:** PSR-12 compliance, naming conventions
   - **Logic:** Business rule violations, edge cases, error handling
   - **Tests:** Are changes covered by tests?

3. Check against project rules:
   - Read `.ai/rules/tenancy-rules.md` for tenancy violations
   - Read `.ai/rules/security-rules.md` for security issues
   - Read `.ai/rules/code-style.md` for style issues

4. Output a structured review:
   ```
   ## Review Summary
   - Files changed: X
   - Issues found: Y (Z critical)

   ## Critical Issues
   ...

   ## Suggestions
   ...

   ## Good Patterns
   ...
   ```
```

### Skill 4: `/schema` — Generate/Review DB Schema

File: `.claude/skills/schema/SKILL.md`
```yaml
---
name: schema
description: Generate or review database schema for a module
tools: Bash, Read, Grep, Edit
model: opus
---

Database schema work:

If generating new schema:
1. Ask: Which module? Which tables?
2. Read `.ai/memory/db-schema.md` for conventions
3. Read the v2 DDL file for the target layer (tenant_db_v2.sql for tenant tables)
4. Generate migration following `.ai/templates/tenant-migration.md`
5. Use correct table prefix from CLAUDE.md conventions
6. Include: indexes, FKs, soft deletes, timestamps, is_active, created_by

If reviewing existing schema for $ARGUMENTS:
1. Read the relevant DDL file
2. Check for: missing indexes, broken FKs, naming inconsistencies
3. Compare model fillable/casts with actual DB columns
4. Report mismatches

Always check `.ai/rules/tenancy-rules.md` — tenant tables go in tenant migrations only.
```

### Skill 5: `/module-status` — Check Module Status

File: `.claude/skills/module-status/SKILL.md`
```yaml
---
name: module-status
description: Show current status of a module including models, controllers, routes, tests
tools: Bash, Read, Grep, Glob
model: haiku
context: fork
---

Generate a status report for module $ARGUMENTS:

1. Count files:
   - Models: `Modules/$ARGUMENTS/app/Models/*.php`
   - Controllers: `Modules/$ARGUMENTS/app/Http/Controllers/*.php`
   - Views: `Modules/$ARGUMENTS/resources/views/**/*.blade.php`
   - Tests: `tests/*/$ARGUMENTS/**/*.php`
   - Migrations: count tenant migrations with module prefix

2. Check route registration:
   - Search `routes/tenant.php` for module routes
   - Count GET/POST/PUT/DELETE endpoints

3. Read `.ai/state/progress.md` for module status

4. Output:
   ```
   ## Module: {name}
   - Models: X
   - Controllers: Y
   - Views: Z
   - Tests: W
   - Routes: N
   - Status: {from progress.md}
   - Recent changes: {from git log}
   ```
```

### Skill 6: `/lint` — Quick PHP Lint Check

File: `.claude/skills/lint/SKILL.md`
```yaml
---
name: lint
description: Run PHP syntax check on recently modified files
tools: Bash
model: haiku
---

Quick PHP lint check:

1. Find recently modified PHP files:
   `git diff --name-only --diff-filter=AM HEAD | grep '\.php$'`

2. Run PHP syntax check on each:
   `php -l {file}`

3. Report any syntax errors with file and line number

4. If no errors, confirm all files are clean
```

---

## How to Create a Skill

```bash
# Create directory
mkdir -p .claude/skills/my-skill

# Create SKILL.md
cat > .claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What it does
tools: Bash, Read
model: sonnet
---

Instructions here...
EOF
```

Or use `/skills` command inside Claude Code to manage them interactively.

---

## Invoking Skills

```
/test                              # Run all tests
/test tests/Unit/SmartTimetable/   # Run specific tests (passed as $ARGUMENTS)
/review 123                        # Review PR #123
/schema StudentFee                 # Generate schema for StudentFee module
/module-status SmartTimetable      # Status report
/lint                              # Quick syntax check
```

---

## Skills vs Subagents — When to Use Which

| Use Skill When... | Use Subagent When... |
|-------------------|---------------------|
| Task is repeatable and well-defined | Task is one-off or exploratory |
| You want a `/command` shortcut | You want Claude to delegate internally |
| Output should come back to main chat | Output is verbose and should stay isolated |
| User triggers it manually | Claude decides to delegate automatically |
