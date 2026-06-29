# Memory Index — Prime-AI AI Brain

> This file is the index of all memory files in `AI_Brain/memory/`.
> **Start every session by reading `AI_Brain/README.md` first.**
> Last Updated: 2026-06-27

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

## Deployment & Operations

- [deployment-config.md](deployment-config.md) — **Deployment configuration reference** (2026-06-25): queue names and workload map, environment variable checklist, Horizon configuration, known deployment risks (incl. confirmed P0s: queue=database vs Horizon=redis mismatch, committed APP_KEY in .env-original, cross-DB FK to sys_roles/sys_dropdowns), storage setup, pre-flight checklist. Used by Technical Auditor (Layer 12) and DevOps agent.

---

## Module Knowledge Files (`AI_Brain/module-knowledge/`)

> Per-module accumulated knowledge — read before any FRD, audit, or code session on that module.
> Seeded by Business Analyst (enhanced: 22-artifact Analysis Mode Catalog — FRD/BRD/SRS/RBS/user-stories/RTM/FSM/data-dictionary/NFR/risk/estimation/reporting/rollout/conditions-catalog); updated after every significant session (FRD, audit, code review). Always verify counts via `ls` — seeded "0% Greenfield" is routinely 50–75% actual.

- [../module-knowledge/BIL_Billing.md](../module-knowledge/BIL_Billing.md) — Billing (BIL): **PRIME module** (prime_db, not tenant). 5 bil_* tables in prime_db_v2.sql (no standalone DDL). 7 controllers, 6 models, 8 policies (**ALL BROKEN** — duplicate registrations), 43 views, ~55% complete. 7 P0 critical issues: silent auth bypass, audit log FK mismatch, open DB transactions, sensitive data in audit JSON, 9 unauth'd controller methods. 0 services (GOD controller). `Tenancy::initialize()/end()` pattern for cross-DB student count. P0 resolution status unverified as of 2026-06-27. FRD not yet generated.
- [../module-knowledge/CMP_Complaint.md](../module-knowledge/CMP_Complaint.md) — Complaint (CMP): ~40% complete, 6 tables, 8 P0 blockers (dd() calls, empty destroy, wrong policy gate, hardcoded IDs), 3 stub controllers, 15 schema mismatches. FRD generated 2026-06-27.
- [../module-knowledge/CAF_Cafeteria.md](../module-knowledge/CAF_Cafeteria.md) — Cafeteria (CAF): 21 tables (DDL v1, 4 layers), 16 controllers, 21 models, 6 services, 19 FormRequests, 14 policies, 95 views, ~60–65%. 1 test only. 0 jobs. SELECT...FOR UPDATE concurrency for meal card deductions. FRD pending.
- [../module-knowledge/CRT_Certificate.md](../module-knowledge/CRT_Certificate.md) — Certificate (CRT): 10 tables (DDL v1, 5 layers) + 2 DDL gaps (crt_verification_logs, crt_id_card_issued). 10 controllers, 10 models, 3 services (CertificateGenerationService, QrVerificationService, **IdCardGenerationService** — DmsService never created), 10 FormRequests, 7 policies, 39 views, 4 seeders, 1 job (BulkGenerateCertificatesJob), ~55–60%. 0 tests (30 proposed). HMAC-SHA256 verification, SELECT...FOR UPDATE serial counter, std_students.tc_issued ALTER needed. FRD pending. — Cafeteria (CAF): 21 tables (DDL v1, 4 layers), 16 controllers, **21 models** (corrected from 17), 6 services, **19 FormRequests** (corrected from 16), 14 policies, **95 views**, ~**60–65%** complete (corrected from 0% Greenfield). 1 test only (critical — concurrency/cutoff/webhook untest'd). 0 jobs (NTF alerts, FSSAI expiry, menu archive all unqueued). SELECT...FOR UPDATE concurrency pattern for meal card deductions. FRD not yet generated.
- [../module-knowledge/ACC_Accounting.md](../module-knowledge/ACC_Accounting.md) — Accounting (ACC): 28 tables (DDL v3, 6 domains), 21 controllers, 25 models, **7 services** (corrected from 10), 17 FormRequests, 19 policies, 141 views, ~**60–70%** complete (revised from 30%). Generic event engine (4 tables, DDL v3) confirmed implemented: ModuleEventController + EventVoucherConfigController + RemoteEntryService. FAC7/FAC8/FAC10 (GST/TDS/YearEnd) not built. Old module code was FAC. FRD not yet generated.
- [../module-knowledge/ADM_Admission.md](../module-knowledge/ADM_Admission.md) — Admission Mgmt. (ADM): 20 tables (DDL v1, 9 layers), 18 controllers, 20 models, 6 services, 24 FormRequests, 13 policies, 84 views, ~**60–65%** complete (corrected from 0% Greenfield). Full pipeline scaffolded: enquiry→application→merit→allotment→enrollment→promotion→TC. 0 tests (critical), PromoteExpiredOffersJob missing, 0 migrations. 5 DDL deviations documented (Aadhar non-unique, not-null created_by, etc.). FRD not yet generated.
- [../module-knowledge/BHA_BehaviouralAssessment.md](../module-knowledge/BHA_BehaviouralAssessment.md) — BehaviouralAssessment (BHA): 16 tables (DDL v2, 6 dep layers), 12 controllers, **1 service** (BehaviouralScoreService only — corrected from 4), 5 FormRequests, 17 policies, 65 views, ~**50–55%** complete. 0 tests (critical — CBSE/ICSE CCE compliance). ComputeSchoolScoresJob missing. 3 FormRequests missing (Assessment, Incident, ClassCategory). No consolidated V2 req — 24 screen files are primary source. FRD not yet generated.
- [../module-knowledge/INV_Inventory.md](../module-knowledge/INV_Inventory.md) — Inventory (INV): 28 tables (DDL v1, tenant_db), 20 ctrl, 28 models, **14 services** (corrected from 7; StockLedgerService + StockValuationService undocumented), 16 policies, 77 views, ~**55–65%** (corrected from 0% Greenfield). 5 cross-module placeholder seeders bypass ACC/VND prereqs. 4 of 8 domain events missing (StockTransferred etc.). 0 Listeners. 0 tests (critical — SELECT...FOR UPDATE on stock_balances). FK constraints for ACC/VND/SCH commented out in DDL. FRD not yet generated.
- [../module-knowledge/FOF_FrontOffice.md](../module-knowledge/FOF_FrontOffice.md) — FrontOffice (FOF): 22 tables (DDL v1, 4 layers), 21 ctrl, 22 models, **4 services** (corrected from 6; FeedbackService + CertificateIssuanceService missing), **13 policies** (corrected from 4 proposed — 3× undercount), 118 views, ~**55–65%** (corrected from 0% Greenfield). `fof:flag-overstay` Artisan command not found. 1 queued Job (EarlyDepartureAttSyncJob). 0 Events, 1 test file. 0 migrations. FRD not yet generated.
- [../module-knowledge/HST_Hostel.md](../module-knowledge/HST_Hostel.md) — Hostel (HST): 36-table DDL (v4/v3.0 internal), 41 migrations deployed. **53 ctrl** (proposed 20), **41 models** (proposed 20; modules-map says 44 — discrepancy of 3 unresolved), **22 services** (proposed 7; 15 are report-specific), **38 FormRequests** (proposed 27), **20 policies** (proposed 12; in module's own Policies/ not app/Policies/), **278 views** (proposed 65), **573 route lines / 337 named routes**, 9 seeders, 7 events, 2 jobs, 1 Artisan command (hst:escalate-complaints — hourly scheduler), 1 middleware (WardenScopeMiddleware ✓ implemented), **0 tests** (15 proposed — critical gap), ~**70–75%** (corrected from 0% Greenfield). Key gaps: 0 Listeners (events dispatch jobs directly), BedType.php+HstBedType.php duplicate models (P1), duplicate controller naming (AuditLogController vs HstAuditLogController). FRD not yet generated. Knowledge: `AI_Brain/module-knowledge/HST_Hostel.md`

---

## Critical Files to Check Before Any Work

| What You're Doing | Files to Read |
|-------------------|--------------|
| **Starting any new feature** | `{PROJECT_DOCS}/10-new-feature-checklist.md` — Prime vs Tenant step-by-step |
| **Creating controllers** | `{PROJECT_DOCS}/06-controller-guide.md` — CRUD template with Gate + validation |
| **Creating views** | `{PROJECT_DOCS}/07-blade-views-guide.md` — Index + Create/Edit patterns |
| **Creating migrations** | `{PROJECT_DOCS}/04-migration-guide.md` — Central vs Tenant paths |
| **Routing** | `{PROJECT_DOCS}/08-routes-guide.md` — web.php vs tenant.php |
| Any tenant-scoped work | `tenancy-map.md` + `AI_Brain/rules/tenancy-rules.md` |
| Adding a new module | `modules-map.md` + `AI_Brain/rules/module-rules.md` |
| DB schema / migrations | `db-schema.md` |
| Security-sensitive code | `AI_Brain/lessons/known-issues.md` (Deep Audit 2026-03-15 section) |
| Authorization / policies | `project-context.md` (Authorization Architecture) |
| SmartTimetable work | `AI_Brain/lessons/known-issues.md` (FET solver sections) |
| Payment/webhook work | `AI_Brain/lessons/known-issues.md` (SEC-PAY-* section) |
| Module reference (all names) | `{PROJECT_DOCS}/11-all-modules-controllers-models.md` |

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

> **Location:** `{PROJECT_PLAN}/`

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
