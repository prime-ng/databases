# 02 — Complete Plan: Module-Aware AI Agent

> **Goal:** Claude auto-loads ONLY the memory/rules relevant to the module you're working on.
> **Approach:** Use Claude Code's native `.claude/rules/` path-scoped rules + restructured CLAUDE.md

---

## Architecture Overview

```
CLAUDE.md (root)
  └── "Which module are you working on?" prompt
  └── @.ai/rules/tenancy-rules.md  (always loaded)
  └── @.ai/rules/module-rules.md   (always loaded)

.claude/rules/                       <-- PATH-SCOPED AUTO-LOAD
  ├── smart-timetable.md             <-- Loads when touching Modules/SmartTimetable/**
  ├── hpc.md                         <-- Loads when touching Modules/Hpc/**
  ├── student-profile.md             <-- Loads when touching Modules/StudentProfile/**
  ├── school-setup.md                <-- Loads when touching Modules/SchoolSetup/**
  ├── lms-exam.md                    <-- Loads when touching Modules/LmsExam/**
  ├── ...                            <-- One per module
  ├── testing.md                     <-- Loads when touching tests/**
  ├── migrations.md                  <-- Loads when touching database/migrations/**
  └── api.md                         <-- Loads when touching **/routes/api.php

.ai/memory/modules/                  <-- MODULE-SPECIFIC MEMORY (new)
  ├── smart-timetable.md             <-- SmartTimetable-specific decisions, patterns
  ├── hpc.md                         <-- HPC-specific decisions, patterns
  ├── student-profile.md             <-- StudentProfile-specific patterns
  └── ...
```

---

## Step-by-Step Implementation Plan

### Step 1: Create `.claude/rules/` Directory with Path-Scoped Rules

This is **Claude Code's native feature**. When you add `paths:` frontmatter to a rule file, Claude loads that rule ONLY when it reads/edits files matching those paths.

**Create the directory:**
```bash
mkdir -p /Users/bkwork/Herd/laravel/.claude/rules
```

**Example — SmartTimetable rule file:**

File: `.claude/rules/smart-timetable.md`
```yaml
---
description: SmartTimetable module rules and context
globs:
  - "Modules/SmartTimetable/**"
  - "database/migrations/tenant/*timetable*"
  - "database/migrations/tenant/*constraint*"
  - "database/migrations/tenant/*activity*"
  - "database/migrations/tenant/*parallel*"
---

# SmartTimetable Module Context

## Architecture
- FET-inspired solver (CSP backtracking + greedy fallback + rescue pass)
- Activity-based scheduling: subjects become Activities with teachers, rooms, time slots
- All constraints write to ONE table `tt_constraints`, differentiated by `constraintType.category.code`
- Parallel periods: anchor-based solver pattern (see D14 in .ai/state/decisions.md)

## Key Models (84 total)
- Activity, Constraint, ConstraintType, ConstraintCategory, ConstraintScope
- ParallelGroup, ParallelGroupActivity
- SchoolDay, PeriodSet, PeriodSetPeriod, Shift, SchoolTimingProfile

## Table Prefix
- `tt_*` for all timetable tables
- Junction tables: `*_jnt`

## Current Decisions
- D11: FET-inspired solver
- D14: Parallel periods anchor pattern
- D16: Constraint Management CRUD (category-specific views)
- D17: Model/Migration mismatch fixes (additive only)

## Key Patterns
- `ConstraintCategory` and `ConstraintScope` share table `tt_constraint_category_scope` via global scopes
- `Constraint::TARGET_TYPES = ['TEACHER', 'CLASS', 'ROOM', 'GLOBAL', 'ACTIVITY', 'INTER_ACTIVITY']`
- Category-specific create/edit views resolved via `match($categoryCode)` in ConstraintController
- Redirect anchors after store/update: `#teacher-constraints-pane`, `#class-constraints-pane`, etc.

## Before Working on This Module
1. Read `.ai/state/decisions.md` entries D11, D14, D16, D17
2. Check `.ai/state/progress.md` for recent changes
3. Check known issues: parallel period steps 4-9 are still pending
```

**Example — HPC rule file:**

File: `.claude/rules/hpc.md`
```yaml
---
description: HPC (Holistic Progress Card) module rules
globs:
  - "Modules/Hpc/**"
  - "database/migrations/tenant/*hpc*"
---

# HPC Module Context

## Architecture
- Holistic Progress Card: multi-page PDF report cards for K-12
- Uses DomPDF — NO flexbox, NO grid, NO Bootstrap in PDF views
- Single merged `*_pdf.blade.php` per template form (D13)

## Key Pattern: DomPDF Merged Template
- One file per grade range: `first_pdf` (Grades 3-5), `second_pdf` (variant), `third_pdf` (Grades 6-8)
- Contains: `$css` array, helper closures, full `<!DOCTYPE html>` document
- Use `<table>` for ALL multi-column layouts
- Emojis: `asset('emoji/happy.png')` etc. — local public folder files

## Table Prefix
- `hpc_*` for HPC tables

## Current Status
- ~95% complete — all 3 PDF templates done
- Components: activity-tab, student-self-reflection, peer-feedback, etc.
- Located: `resources/views/components/hpc-form/`

## Before Working on This Module
1. Read D13 in `.ai/state/decisions.md`
2. NEVER use Blade components in PDF views — DomPDF can't resolve them
3. Always test PDF output with `php artisan dompdf:test` or browser preview
```

**Example — Testing rule file:**

File: `.claude/rules/testing.md`
```yaml
---
description: Testing conventions and patterns
globs:
  - "tests/**"
  - "phpunit.xml"
---

# Testing Rules

## Framework
- Pest 4.x (NOT PHPUnit syntax)
- Config: `phpunit.xml` has 16 module test suites

## Test Types
1. **Unit tests** — Pure logic, no DB: `tests/Unit/`
2. **Feature tests (Central)** — Central DB routes/controllers: `tests/Feature/Central/`
3. **Feature tests (Tenant)** — Tenant-scoped: `tests/Feature/Tenant/`
4. **Browser tests (Dusk)** — UI: `tests/Browser/`

## Patterns
- Use `it('does something', function() { ... })` syntax
- Tenant tests need `initializeTenancy()` in `beforeEach`
- Use factories, not manual DB inserts
- Check `.ai/templates/test-unit.md`, `test-feature-central.md`, `test-feature-tenant.md`

## Run Commands
- All tests: `./vendor/bin/pest`
- Single file: `./vendor/bin/pest tests/Unit/SmartTimetable/ActivityModelTest.php`
- Single test: `./vendor/bin/pest --filter="test name"`
- With coverage: `./vendor/bin/pest --coverage`
```

---

### Step 2: Create Per-Module Memory Files

Move module-specific decisions/patterns out of the shared `decisions.md` and into per-module files.

**Create directory:**
```bash
mkdir -p /Users/bkwork/Herd/laravel/.ai/memory/modules
```

**Files to create:**
```
.ai/memory/modules/
├── smart-timetable.md        # D11, D14, D16, D17 + solver patterns + constraint CRUD
├── hpc.md                    # D13 + DomPDF patterns + template structure
├── student-profile.md        # Dusk tests, profile tabs, medical incidents
├── school-setup.md           # Classes, sections, subjects, rooms, teachers
├── student-fee.md            # Fee management, Razorpay, concessions
├── transport.md              # Vehicles, routes, trips, GPS
├── syllabus.md               # Curriculum, lessons, topics, Bloom taxonomy
├── question-bank.md          # Questions, tags, AI generation
├── lms-exam.md               # Examination system
├── lms-quiz.md               # Quiz/assessment
├── lms-homework.md           # Homework management
├── notification.md           # Multi-channel notifications
├── complaint.md              # Issue tracking, SLA, AI insights
├── vendor.md                 # Vendor management, agreements
├── recommendation.md         # AI recommendations, trigger events
├── prime.md                  # Tenant management, billing, plans
└── global-master.md          # Countries, states, boards, languages
```

Each file contains:
```markdown
# {Module Name} — Module Memory

## Architecture Decisions
(Move relevant D## entries from state/decisions.md here)

## Key Models & Tables
(List primary models and their table prefixes)

## Known Patterns
(Module-specific coding patterns)

## Known Issues
(Module-specific bugs or gotchas)

## Current Status
(What's done, what's pending)
```

---

### Step 3: Update CLAUDE.md to Ask for Module Context

Add to your root `CLAUDE.md`:

```markdown
## Session Start Protocol

When I start a new conversation:
1. Read `.ai/README.md` for orientation
2. Check which files I'm editing to auto-load the right `.claude/rules/` file
3. If the user hasn't specified a module, ask: "Which module are you working on today?"
4. Load the corresponding `.ai/memory/modules/{module}.md` for module-specific context
5. Check `.ai/state/progress.md` for recent changes to that module
```

---

### Step 4: Create Module-Specific `.claude/rules/` Files for All Active Modules

Priority order (create these first):

| Priority | Module | Glob Pattern | Status |
|----------|--------|-------------|--------|
| 1 | SmartTimetable | `Modules/SmartTimetable/**` | Active development |
| 2 | Hpc | `Modules/Hpc/**` | Active development |
| 3 | StudentProfile | `Modules/StudentProfile/**` | Active testing |
| 4 | SchoolSetup | `Modules/SchoolSetup/**` | 100% but referenced often |
| 5 | StudentFee | `Modules/StudentFee/**` | ~80%, upcoming work |
| 6 | Testing | `tests/**` | Active |

Lower priority (create later):
- LmsExam, LmsQuiz, LmsHomework, Transport, Syllabus, QuestionBank, etc.

---

### Step 5: Reference Pattern — How It All Connects

**Scenario: You start a new Claude session and say "I want to work on SmartTimetable constraints"**

```
1. CLAUDE.md loads (always)
   ├── Core rules: tenancy, module, security (always loaded)
   └── "Read .ai/README.md" instruction

2. Claude reads .ai/README.md
   └── Understands project structure

3. You mention SmartTimetable OR touch a file in Modules/SmartTimetable/
   └── .claude/rules/smart-timetable.md AUTO-LOADS (path-scoped)
   └── Claude now knows: FET solver, constraint patterns, tt_* prefix

4. Claude reads .ai/memory/modules/smart-timetable.md
   └── Module-specific decisions, patterns, current status

5. Claude checks .ai/state/progress.md
   └── Sees recent Phase 3 CRUD completion

6. Claude is now FULLY CONTEXT-AWARE for SmartTimetable
   └── Knows architecture, patterns, what's done, what's pending
   └── Did NOT load HPC DomPDF patterns (irrelevant)
   └── Did NOT load Transport GPS patterns (irrelevant)
```

**Scenario: You switch to HPC work**

```
1. CLAUDE.md still loaded (always)
2. You say "Now let's work on HPC" or touch Modules/Hpc/ files
3. .claude/rules/hpc.md AUTO-LOADS (replaces SmartTimetable rules)
4. Claude reads .ai/memory/modules/hpc.md
5. Claude now knows: DomPDF, merged templates, table layouts
6. SmartTimetable context is NOT loaded — clean context
```

---

## Why This Approach is Best

| Alternative | Problem |
|------------|---------|
| One giant CLAUDE.md with everything | Too long (>200 lines loses adherence), wastes tokens |
| Ask Claude to read specific files manually | Requires user effort every session, easy to forget |
| Separate CLAUDE.md per module subdirectory | Module CLAUDE.md files load only when entering that exact directory |
| `.claude/rules/` with path globs | **Winner** — Auto-loads per file path, native Claude feature, zero effort |

The `.claude/rules/` approach is the **only one that auto-loads without any user action** — as soon as Claude touches a file in `Modules/SmartTimetable/`, the SmartTimetable rules appear automatically.

---

## Implementation Time Estimate

| Step | Effort | Files |
|------|--------|-------|
| Step 1: `.claude/rules/` for top 6 modules | ~30 min | 6 files |
| Step 2: Per-module memory files | ~45 min | 6-8 files |
| Step 3: Update CLAUDE.md | ~10 min | 1 file |
| Step 4: Remaining modules | ~1 hour | 10-12 files |
| **Total** | **~2.5 hours** | **23-27 files** |

You can ask Claude to generate all these files — it has full knowledge of every module from `.ai/memory/modules-map.md`.
