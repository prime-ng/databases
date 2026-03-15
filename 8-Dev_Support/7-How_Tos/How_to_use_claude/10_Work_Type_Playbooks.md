# 10 — Work Type Playbooks

> Step-by-step guides for each type of work you do with Claude.

---

## Playbook 1: Feature Development (Frontend + Backend)

**Example:** "Build constraint management CRUD for SmartTimetable"

### Steps:

```
1. START SESSION
   claude
   "I want to work on SmartTimetable — building constraint CRUD"

2. PLAN FIRST (Use Plan Mode)
   Press Shift+Tab to enter Plan Mode
   - Claude explores existing code, reads relevant models
   - Produces implementation plan
   - You review and approve

3. IMPLEMENT (Switch to Normal Mode)
   Press Shift+Tab to exit Plan Mode
   - Claude creates/modifies files
   - Follow the plan step by step
   - Review each change

4. TEST (Delegate to Subagent)
   "Run the test-runner agent on SmartTimetable"
   - Subagent runs Pest tests in isolated context
   - Returns only failures
   - Fix issues

5. UPDATE MEMORY
   "Update your memory and .ai/state/progress.md"

6. COMMIT
   /commit
```

### Token Optimization:
- Use Plan Mode for exploration (no edits = fewer tokens)
- Delegate testing to subagent (verbose output stays isolated)
- `/compact` between major phases
- `/clear` when switching modules

---

## Playbook 2: Testing & Test Scripts

**Example:** "Write Dusk browser tests for StudentProfile"

### Steps:

```
1. START SESSION
   claude
   "I want to write browser tests for StudentProfile"

2. UNDERSTAND EXISTING TESTS
   "Show me the test structure for this module"
   - Claude reads existing test files
   - Understands patterns and base classes

3. READ THE TEMPLATES
   Claude reads .ai/templates/test-feature-tenant.md
   Claude reads .ai/agents/test-agent.md (Pest patterns)

4. GENERATE TESTS
   - Claude writes test files following templates
   - Uses correct test namespace, base classes, traits
   - Follows Pest 4.x `it()` syntax

5. RUN TESTS
   /test tests/Browser/Modules/StudentProfile/
   - Or: "Run these tests with the test-runner agent"

6. FIX FAILURES
   - Claude analyzes failures
   - Fixes source code or test code
   - Re-runs until green

7. COMMIT
   /commit
```

### Skills to Use:
- `/test` — Run specific test file
- `/lint` — Quick syntax check before running

---

## Playbook 3: Database Schema Design

**Example:** "Design tables for a new Hostel module"

### Steps:

```
1. START SESSION
   claude
   "I need to design the database schema for the Hostel module"

2. RESEARCH EXISTING PATTERNS
   "Read the tenant_db_v2.sql to understand table conventions"
   Claude reads .ai/memory/db-schema.md
   Claude reads .ai/rules/tenancy-rules.md

3. PLAN THE SCHEMA
   Use Plan Mode (Shift+Tab)
   - List required entities (hostel, rooms, allocations, fees)
   - Define relationships
   - Choose table prefix: hos_*
   - Identify foreign keys

4. GENERATE DDL
   Claude produces SQL CREATE TABLE statements following conventions:
   - Table prefix: hos_*
   - Columns: id, uuid, is_active, created_by, updated_by, timestamps, soft deletes
   - Indexes on all FK columns
   - Comments on columns

5. GENERATE MIGRATIONS
   Claude creates Laravel migration files following .ai/templates/tenant-migration.md
   Places them in database/migrations/tenant/

6. GENERATE MODELS
   Claude creates Eloquent models following .ai/templates/model.md
   Places them in Modules/Hostel/app/Models/

7. VERIFY
   Use db-analyzer agent: "Check schema-model alignment for Hostel"

8. UPDATE DDL
   Add new tables to tenant_db_v2.sql
   Update CHANGELOG.md
```

### Skills/Agents to Use:
- `/schema Hostel` — Generate schema
- `db-analyzer` subagent — Verify alignment

---

## Playbook 4: Requirement Creation / Enhancement

**Example:** "Analyze the current StudentFee module and create enhancement requirements"

### Steps:

```
1. START SESSION (Plan Mode)
   claude --permission-mode plan
   "Analyze the StudentFee module and identify gaps"

2. COMPREHENSIVE ANALYSIS
   Claude reads:
   - All StudentFee models, controllers, views
   - Route definitions
   - Existing tests
   - .ai/memory/modules-map.md for status
   - .ai/memory/known-bugs-and-roadmap.md for known issues

3. GENERATE REQUIREMENTS
   Claude produces:
   - Current state analysis
   - Feature gaps vs industry standard
   - Enhancement proposals with priority
   - Technical feasibility notes

4. SAVE OUTPUT
   Claude writes requirements to:
   databases/Requir_Enhancements/ or a designated location

5. REVIEW AND REFINE
   Discuss with Claude in plan mode
   - Ask clarifying questions
   - Prioritize features
   - Add technical constraints
```

### Token Optimization:
- Plan Mode throughout (read-only, no edits)
- Use Explore agent for codebase search (faster, cheaper)

---

## Playbook 5: Code Review

**Example:** "Review the SmartTimetable changes before merging"

### Steps:

```
1. USE THE /review SKILL
   /review                          # Review staged changes
   /review 123                      # Review PR #123
   /review Modules/SmartTimetable/  # Review specific directory changes

2. CLAUDE ANALYZES
   - Security: SQL injection, XSS, mass assignment
   - Tenancy: Cross-tenant leakage, wrong DB context
   - Performance: N+1 queries, missing indexes
   - Style: PSR-12, naming conventions
   - Logic: Business rule violations

3. REVIEW OUTPUT
   Claude produces structured review:
   - Critical issues (must fix)
   - Suggestions (should fix)
   - Good patterns (keep doing)

4. FIX ISSUES
   Address critical issues first
   Re-run review to verify
```

### Alternative: Use code-reviewer Subagent
```
"Have the code-reviewer agent review my staged changes"
```
This keeps verbose review output out of main context.

---

## Playbook 6: Screen & Report Design

**Example:** "Design the HPC report card view"

### Steps:

```
1. START SESSION
   claude
   "I need to design the HPC report card screen"

2. USE FRONTEND-DESIGN SKILL
   /frontend-design
   - Claude generates production-grade HTML/CSS/Blade
   - Uses Bootstrap 5 (your stack)
   - Follows existing component patterns

3. FOR PDF REPORTS (DomPDF)
   Read .ai/state/decisions.md D13 for DomPDF rules:
   - No flexbox/grid — use <table> for layout
   - No Blade components — inline everything
   - No Bootstrap classes — use inline styles
   - Single merged file per template

4. ITERATE ON DESIGN
   - Share feedback
   - Claude refines
   - Preview in browser

5. INTEGRATE
   - Place Blade files in correct module directory
   - Add routes and controller methods
   - Test rendering
```

---

## Playbook 7: Bug Fixing / Enhancement

**Example:** "Fix the N+1 query in ConstraintController"

### Steps:

```
1. DESCRIBE THE BUG
   claude
   "There's an N+1 query issue in ConstraintController@constraintManagement"

2. CLAUDE INVESTIGATES
   - Reads the controller method
   - Traces relationship chains
   - Identifies missing eager loads

3. FIX
   Claude adds `->with([...])` or restructures query

4. VERIFY
   "Run the performance-auditor agent on ConstraintController"

5. TEST
   "Run the test-runner on SmartTimetable tests"

6. COMMIT
   /commit
```

---

## Quick Reference: Best Features per Work Type

| Work Type | Start With | Key Skills/Agents | Model |
|-----------|-----------|-------------------|-------|
| **Feature Dev** | Plan Mode → Normal | `/test`, test-runner | Opus for complex, Sonnet for CRUD |
| **Testing** | Normal | `/test`, `/lint` | Sonnet |
| **DB Schema** | Plan Mode | `/schema`, db-analyzer | Opus |
| **Requirements** | Plan Mode | Explore agent | Opus |
| **Code Review** | Normal | `/review`, code-reviewer | Opus |
| **Screen Design** | Normal | `/frontend-design` | Sonnet |
| **Bug Fixing** | Normal | Explore, performance-auditor | Sonnet |
| **Enhancement** | Plan Mode → Normal | `/review`, test-runner | Sonnet |
