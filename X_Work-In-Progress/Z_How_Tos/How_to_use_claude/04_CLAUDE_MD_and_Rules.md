# 04 — CLAUDE.md and `.claude/rules/` Deep Dive

---

## CLAUDE.md — How It Works

### Loading Hierarchy (Priority Order)

```
1. Managed Policy (org-wide, enforced, cannot exclude)
   macOS: /Library/Application Support/ClaudeCode/CLAUDE.md

2. Project Instructions (team-shared, git-committed)
   ./CLAUDE.md  OR  ./.claude/CLAUDE.md  (same priority)

3. User Instructions (personal, all projects)
   ~/.claude/CLAUDE.md

4. Nested CLAUDE.md (on-demand, per subdirectory)
   ./Modules/SmartTimetable/CLAUDE.md  (loads when Claude accesses this dir)
```

### Key Behaviors
- **Always loaded:** Root CLAUDE.md loads at session start
- **Nested:** Subdirectory CLAUDE.md loads on-demand when files in that dir are accessed
- **@imports:** Use `@path/to/file.md` to include other files inline
- **Length:** Keep under 200 lines — longer files reduce adherence
- **Format:** Markdown with headers and bullet points

### @import Syntax
```markdown
# In CLAUDE.md:
## Tenancy Rules
@.ai/rules/tenancy-rules.md

## Module Rules
@.ai/rules/module-rules.md
```

This includes the content of those files directly into the CLAUDE.md context.

---

## `.claude/rules/` — Path-Scoped Auto-Loading Rules

### What It Is
A directory of markdown files with `globs:` frontmatter. Rules load ONLY when Claude reads/edits files matching the glob patterns. This is the **key feature** for module-aware AI.

### File Format
```yaml
---
description: Short description of what this rule covers
globs:
  - "Modules/SmartTimetable/**"
  - "database/migrations/tenant/*timetable*"
---

# Rule content here (markdown)
Your instructions, context, patterns, etc.
```

### Glob Pattern Examples

| Pattern | Matches |
|---------|---------|
| `Modules/SmartTimetable/**` | All files in SmartTimetable module |
| `Modules/SmartTimetable/**/*.php` | Only PHP files |
| `database/migrations/tenant/**` | All tenant migrations |
| `tests/**` | All test files |
| `routes/*.php` | All route files |
| `**/*.blade.php` | All Blade templates anywhere |
| `**/Controllers/**` | All controller files |
| `app/Policies/**` | All policy files |

### Full Module Rules Structure for Prime-AI

```
.claude/rules/
├── smart-timetable.md           # SmartTimetable: FET solver, constraints, tt_*
├── hpc.md                       # HPC: DomPDF, merged templates, hpc_*
├── student-profile.md           # StudentProfile: tabs, medical, std_*
├── school-setup.md              # SchoolSetup: classes, sections, sch_*
├── student-fee.md               # StudentFee: invoices, Razorpay, fin_*
├── transport.md                 # Transport: vehicles, routes, tpt_*
├── syllabus.md                  # Syllabus: curriculum, Bloom, slb_*
├── question-bank.md             # QuestionBank: questions, tags, qns_*
├── lms-exam.md                  # LmsExam: exam system, exm_*
├── lms-quiz.md                  # LmsQuiz: assessments, quz_*
├── lms-homework.md              # LmsHomework: assignments
├── notification.md              # Notification: multi-channel, ntf_*
├── complaint.md                 # Complaint: SLA, AI insights, cmp_*
├── vendor.md                    # Vendor: agreements, vnd_*
├── recommendation.md            # Recommendation: AI rules, rec_*
├── prime.md                     # Prime: tenants, billing, prm_*
├── global-master.md             # GlobalMaster: countries, boards, glb_*
├── testing.md                   # Testing: Pest 4.x patterns
├── migrations.md                # Migrations: tenant vs central patterns
├── api-routes.md                # API: response format, auth
├── blade-views.md               # Views: Bootstrap 5, components
└── policies.md                  # Policies: authorization patterns
```

### Template for Creating Module Rules

```yaml
---
description: {ModuleName} module context and rules
globs:
  - "Modules/{ModuleName}/**"
  - "database/migrations/tenant/*{prefix}*"
---

# {ModuleName} Module Context

## Overview
{One-paragraph description of what this module does}

## Table Prefix
- `{prefix}_*` for all module tables

## Key Models
- {Model1} — {table_name} — {purpose}
- {Model2} — {table_name} — {purpose}

## Architecture Patterns
- {Key pattern 1}
- {Key pattern 2}

## Business Rules
- {Domain rule 1}
- {Domain rule 2}

## Current Status
- Completion: {percentage}
- Recent work: {what was done recently}
- Pending: {what's next}

## Related Modules
- {Module1} — {how it relates}
- {Module2} — {how it relates}
```

---

## Recommended CLAUDE.md Restructure

Your current CLAUDE.md is ~130 lines and includes everything. Here's an optimized version:

```markdown
# Prime-AI: Academic Intelligence Platform

## Tech Stack
PHP 8.2+ / Laravel 12 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12

## Critical Rules
- **NEVER mix central and tenant scoped code**
- Read `.ai/README.md` before starting ANY task
- Follow all rules in `.ai/rules/` without exception
- Use templates in `.ai/templates/` for all new code
- Update `.ai/state/progress.md` after every completed task

## Multi-Tenancy (3-Layer)
| Layer | DB | Tables | Prefix |
|-------|-----|--------|--------|
| Global | global_db | 12 | glb_* |
| Prime | prime_db | 27 | prm_*, bil_*, sys_* |
| Tenant | tenant_db | 368 | tt_*, std_*, sch_*, etc. |

## Key Paths
- **App:** `/Users/bkwork/Herd/laravel`
- **DDLs (v2 ONLY):** `prime-ai_db/databases/1-master_dbs/1-DDLs/{global,prime,tenant}_db_v2.sql`
- **Brain:** `.ai/` — Start with `.ai/README.md`

## Module Context
Module-specific rules auto-load via `.claude/rules/` when touching module files.
For manual context: `.ai/memory/modules/{module-name}.md`

## Core Rules (Always Active)
@.ai/rules/tenancy-rules.md
@.ai/rules/module-rules.md
@.ai/rules/security-rules.md
```

This is ~35 lines — concise, always loaded, and defers module-specific context to `.claude/rules/`.

---

## Nested CLAUDE.md (Alternative Approach)

You CAN also place `CLAUDE.md` in each module directory:

```
Modules/SmartTimetable/CLAUDE.md    # Loads when Claude accesses SmartTimetable
Modules/Hpc/CLAUDE.md              # Loads when Claude accesses HPC
```

**Pros:** Simple, no `.claude/rules/` setup needed
**Cons:** Only loads when Claude enters that exact directory (not parent), adds files to module folders

**Recommendation:** Use `.claude/rules/` instead — it's more flexible (supports multiple glob patterns) and keeps module directories clean.
