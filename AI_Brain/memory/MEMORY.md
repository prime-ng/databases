# Memory Index — Prime-AI AI Brain

> This file is the index of all memory files in `AI_Brain/memory/`.
> **Start every session by reading `AI_Brain/README.md` first.**
> Last Updated: 2026-03-21

---

## Path Configuration (READ FIRST)

- [../config/paths.md](../config/paths.md) — **Single source of truth** for all file/folder locations. All `{VARIABLE}` references in AI_Brain files resolve from here. Change paths here, then propagate.

---

## LMS Modules (Dedicated)

- [lms-modules.md](lms-modules.md) — **LMS 6 modules deep knowledge** (2026-03-21): Syllabus, LmsQuiz, LmsQuests, LmsExam, LmsHomework, QuestionBank — tables, key fields, confirmed schema facts, model relationships, critical bugs, cross-module dependencies

## Student & Parent Portal

- [student-parent-portal.md](student-parent-portal.md) — **Portal architecture reference** (2026-03-21): Student Portal 27 screens (S1-S27), Parent Portal 23 screens (P1-P23), 5-layer security, multi-child context, 16 new tables needed, dependencies on LMS/Fee/Transport/Notification modules

---

## Core Project Knowledge

- [project-context.md](project-context.md) — Full project context: purpose, tech stack, database architecture, business workflows, key statistics, external services, authorization architecture
- [modules-map.md](modules-map.md) — All 29 modules: scope, status %, controllers, models, services, route prefixes, completion details, missing modules
- [tenancy-map.md](tenancy-map.md) — Multi-tenancy architecture: stancl/tenancy config, bootstrappers, tenant/central model lists, onboarding workflow, middleware stack, route separation, known pitfalls
- [architecture.md](architecture.md) — System architecture: request flow, module dependency graph, service layer state, key patterns (CRUD, authorization, event-driven, FET solver, payment), configuration issues, maturity matrix
- [school-domain.md](school-domain.md) — School entity relationships and domain concepts
- [conventions.md](conventions.md) — Naming and coding standards
- [testing-strategy.md](testing-strategy.md) — Pest 4.x testing approach

## Database Schema

- [db-schema.md](db-schema.md) — **CANONICAL DB schema reference**: DDL file paths (v2 only), table counts, all table prefixes, key table descriptions per layer, CHANGELOG summary, remaining DDL issues

## State & Decisions

- [decisions.md](decisions.md) — Architectural decision log (D1-D14): tenancy, modules, 3-layer DB, RBAC, UUID, domain routing, soft deletes, PDF, Razorpay, FET solver, HPC PDF pattern, parallel periods
- [progress.md](progress.md) — Module completion tracker

## Issues & Roadmap

- [known-bugs-and-roadmap.md](known-bugs-and-roadmap.md) — **Comprehensive issues file**: 8 bugs (2 critical), 12 security issues (4 critical), 11 performance anti-patterns, 13 N+1 issues, 4-phase improvement roadmap, missing features list, **HPC 20-issue section (2026-03-16)**

---

## Critical Files to Check Before Any Work

| What You're Doing | Files to Read |
|-------------------|--------------|
| **Starting any new feature** | `project_docs/10-new-feature-checklist.md` — Prime vs Tenant step-by-step |
| **Creating controllers** | `project_docs/06-controller-guide.md` — CRUD template with Gate + validation |
| **Creating views** | `project_docs/07-blade-views-guide.md` — Index + Create/Edit patterns |
| **Creating migrations** | `project_docs/04-migration-guide.md` — Central vs Tenant paths |
| **Routing** | `project_docs/08-routes-guide.md` — web.php vs tenant.php |
| Any tenant-scoped work | `tenancy-map.md` + `AI_Brain/rules/tenancy-rules.md` |
| Adding a new module | `modules-map.md` + `AI_Brain/rules/module-rules.md` |
| DB schema / migrations | `db-schema.md` |
| Security-sensitive code | `AI_Brain/lessons/known-issues.md` (Deep Audit 2026-03-15 section) |
| Authorization / policies | `project-context.md` (Authorization Architecture) |
| SmartTimetable work | `AI_Brain/lessons/known-issues.md` (FET solver sections) |
| Payment/webhook work | `AI_Brain/lessons/known-issues.md` (SEC-PAY-* section) |
| Module reference (all names) | `project_docs/11-all-modules-controllers-models.md` |

---

## Project Documentation (created 2026-03-15)

> **Location:** `{PROJECT_DOCS}/` (12 files)
> These contain verified codebase patterns — use before writing any new code.

| File | What It Answers |
|------|----------------|
| `01-project-overview.md` | What is this project? What modules exist? What DB prefixes? |
| `02-prime-side-structure.md` | How is the central/admin side organized? |
| `03-tenant-side-structure.md` | How is the school/tenant side organized? |
| `04-migration-guide.md` | Where do migrations go? What columns are required? |
| `05-model-guide.md` | How to create a model? What must be in $fillable? |
| `06-controller-guide.md` | CRUD template with Gate, validation, activityLog |
| `07-blade-views-guide.md` | Index + Create/Edit Blade patterns, shared components |
| `08-routes-guide.md` | Prime routes vs Tenant routes — where to register |
| `09-artisan-commands-reference.md` | All module/migration/test/cache commands |
| `10-new-feature-checklist.md` | Step-by-step: Prime feature vs Tenant feature |
| `11-all-modules-controllers-models.md` | Every controller and model name across all 27 modules |

## Project Planning Documents

> **Location:** `{PROJECT_PLAN}/` (also `2-Project_Planning/`)

| Folder | Contents |
|--------|----------|
| `1-RBS/` | Requirements Breakdown Structure — 1112 sub-tasks, 27 RBS modules |
| `2-Gap_Analysis/` | Detailed gap analysis — what's pending per module |
| `{HPC_GAP_ANALYSIS}` | Complete 8-dimension HPC gap analysis (2026-03-16): 138-page PDF fidelity, data provider mapping, blueprint vs code, schema alignment, security audit, route health, data flow, multi-actor status. **20 issues found, all OPEN.** |
| `9-Work_Status/` | Work status (31% overall) + Development estimation (13 months with 3 devs + Claude) |

## Development Lifecycle Blueprint

> **Location:** `{LIFECYCLE_BLUEPRINT}`
> 9-phase process with 17 ready-to-use prompts for building any module from scratch.

---

## Quick Reference: Canonical DDL Paths

```
global_db: {GLOBAL_DDL}
prime_db:  {PRIME_DDL}
tenant_db: {TENANT_DDL}
```
**NEVER use non-v2 DDL files or files from subfolders.**

---

## Quick Reference: Active Critical Bugs (updated 2026-03-16)

| ID | Severity | One-Line Summary |
|----|----------|-----------------|
| SEC-QNS-002 | **REVOKE NOW** | OpenAI + Gemini API keys hardcoded in QuestionBank/AIQuestionGeneratorController |
| SEC-PAY-001 | **REVOKE NOW** | Razorpay test keys hardcoded in Payment/PaymentController copy.php |
| SEC-PLATFORM-001 | CRITICAL | Only 1 EnsureTenantHasModule usage across entire 2715-line tenant.php |
| SEC-PLATFORM-004 | CRITICAL | is_super_admin in $fillable on BOTH User models + writable from student login form |
| SEC-PLATFORM-002 | CRITICAL | env('APP_DOMAIN') in routes/web.php — ALL central routes 404 after config:cache |
| SEC-004 | CRITICAL | Payment webhook behind auth middleware — ALL Razorpay payments fail |
| BUG-VND-001 | CRITICAL | 6 of 7 Vendor controllers NOT registered in routes — unreachable |
| SEC-NTF-006 | CRITICAL | ALL Notification routes commented out in web.php — module inaccessible |
| BUG-CMP-001 | CRITICAL | dd($e) in Complaint store() catch block — exposes stack traces in production |
| SEC-HPC-001 | CRITICAL | 13/15 HpcController methods zero auth — any user can view/edit/generate any HPC |
| SEC-009 | HIGH | 200+ issues found across ALL "100% complete" modules — see known-issues.md |

> **Full details:** `AI_Brain/lessons/known-issues.md` — "Deep Audit" section (2026-03-15)
