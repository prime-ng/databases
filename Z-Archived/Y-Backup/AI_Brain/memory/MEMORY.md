# Memory Index — Prime-AI AI Brain

> This file is the index of all memory files in `AI_Brain/memory/`.
> **Start every session by reading `AI_Brain/README.md` first.**
> Last Updated: 2026-03-12

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

- [known-bugs-and-roadmap.md](known-bugs-and-roadmap.md) — **Comprehensive issues file**: 8 bugs (2 critical), 12 security issues (4 critical), 11 performance anti-patterns, 13 N+1 issues, 4-phase improvement roadmap, missing features list

---

## Critical Files to Check Before Any Work

| What You're Doing | Files to Read |
|-------------------|--------------|
| Any tenant-scoped work | `tenancy-map.md` + `AI_Brain/rules/tenancy-rules.md` |
| Adding a new module | `modules-map.md` + `AI_Brain/rules/module-rules.md` |
| DB schema / migrations | `db-schema.md` |
| Security-sensitive code | `known-bugs-and-roadmap.md` (SEC-* section) |
| Performance-critical code | `known-bugs-and-roadmap.md` (PERF-* section) |
| Authorization / policies | `project-context.md` (Authorization Architecture) |
| SmartTimetable work | `AI_Brain/lessons/known-issues.md` (FET solver sections) |
| Payment/webhook work | `known-bugs-and-roadmap.md` (SEC-004, SEC-005) |

---

## Quick Reference: Canonical DDL Paths

```
global_db: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDLs/global_db_v2.sql
prime_db:  /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDLs/prime_db_v2.sql
tenant_db: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDLs/tenant_db_v2.sql
```
**NEVER use non-v2 DDL files or files from subfolders.**

---

## Quick Reference: Active Critical Bugs

| ID | Severity | One-Line Summary |
|----|----------|-----------------|
| BUG-002 | CRITICAL | Duplicate Gate::policy() registrations — VehiclePolicy, QuestionBankPolicy, SectionPolicy silently lost |
| BUG-004 | HIGH | Tenant migration pipeline commented out — new tenants get empty databases |
| SEC-002 | CRITICAL | is_super_admin in User $fillable — privilege escalation via mass assignment |
| SEC-004 | CRITICAL | Payment webhook behind auth middleware — ALL Razorpay payments fail |
| SEC-005 | CRITICAL | Gateway whitelist bypass — fake payment events possible |
| SEC-008 | CRITICAL | Unauthenticated seeder/run route — data corruption risk |
| SEC-011 | HIGH | env() in routes/web.php — breaks ALL central routes after config:cache |
| SEC-009 | HIGH | SmartTimetableController has ZERO authorization checks |
