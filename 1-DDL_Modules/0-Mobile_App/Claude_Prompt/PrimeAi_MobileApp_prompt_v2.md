# Prime-AI Mobile Application — Requirements Generation Prompt (v2)

> **Supersedes:** `PrimeAi_MobileApp_prompt_v1.md` (which referenced external artifacts `Primeai_complete_spec_v2.md` and
> `PrimeAI_RBS_v2.xlsx`). This v2 is grounded in the **AI_Brain knowledge base** and the actual files present in this repository.
>
> **Where to run:** Inside this repo (working dir `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db`) so the agent can resolve
> `{VARIABLE}` paths from `AI_Brain/config/paths.md`.

---

## 0. ROLE

You are acting as **Business Analyst + Mobile Application Architect** for the
Prime-AI Academic Intelligence Platform (Indian K-12 SaaS — ERP + LMS + LXP).

You do **two** things:

1. **Translate platform capabilities → mobile features** (BA work — RBS-aligned, role-driven, screen-level specs)
2. **Design the mobile architecture** (offline-first, multi-tenant, push, sync, security) so engineering can build without re-deciding fundamentals

You operate in **three sequential, gated phases**. Do not skip ahead.

---

## 1. CONTEXT YOU MUST LOAD BEFORE WRITING ANYTHING

Resolve all `{VARIABLE}` paths from `{AI_BRAIN}/config/paths.md`. Then read, in this order, and **state at the start of your reply 
which files you have read and which (if any) are missing**:

### 1.1 Project foundation
- `{AI_BRAIN}/README.md`
- `{AI_BRAIN}/memory/MEMORY.md` (memory index — start here)
- `{AI_BRAIN}/memory/project-context.md` (purpose, stack, 3-layer DB)
- `{AI_BRAIN}/memory/modules-map.md` (37 modules, controllers, models, route counts)
- `{AI_BRAIN}/memory/architecture.md` (request flow, dependency graph, maturity)
- `{AI_BRAIN}/memory/school-domain.md` (entity relationships)
- `{AI_BRAIN}/memory/conventions.md` (table prefixes, naming)
- `{AI_BRAIN}/memory/db-schema.md` (canonical DDL paths, table counts)
- `{AI_BRAIN}/memory/tenancy-map.md` (stancl/tenancy, domain-based routing, bootstrappers)

### 1.2 Module-specific deep dives (mobile is heavily consumer-facing)
- `{AI_BRAIN}/memory/student-parent-portal.md` (Student 35 screens, Parent 23 screens — these are your **primary mobile reference**, not greenfield)
- `{AI_BRAIN}/memory/lms-modules.md` (Syllabus, LmsQuiz, LmsQuests, LmsExam, LmsHomework, QuestionBank — what's real vs planned)
- `{AI_BRAIN}/memory/known-bugs-and-roadmap.md` (security/perf issues that mobile clients MUST NOT replicate)

### 1.3 Decisions, rules, conventions
- `{AI_BRAIN}/state/decisions.md` (D1–D14 architectural decisions)
- `{AI_BRAIN}/state/progress.md` (current module completion)
- `{AI_BRAIN}/rules/tenancy-rules.md`
- `{AI_BRAIN}/rules/security-rules.md`
- `{AI_BRAIN}/rules/module-rules.md`
- `{AI_BRAIN}/rules/school-rules.md`

### 1.4 Project planning artifacts
- `{RBS_MAPPING}` (RBS — Functions / Tasks / Sub-tasks; the format your mobile features must align to)
- `{GAP_ANALYSIS_PROJECT_FILE}` (current platform gaps — bounds what mobile can call)
- `{PROJECT_DOCS}/01-project-overview.md` (module list + table prefixes)
- `{PROJECT_DOCS}/11-all-modules-controllers-models.md` (every controller/model)
- `{PROJECT_DOCS}/10-new-feature-checklist.md`
- `{LIFECYCLE_BLUEPRINT}` (9-phase, 17-prompt module build process)

### 1.5 Canonical schema (read-only reference)
- `{TENANT_DDL}` — 370 tables, all `prefix_*` tables the mobile API will surface
- `{PRIME_DDL}` — central tenant/plan/billing
- `{GLOBAL_DDL}` — shared reference data (countries, boards, languages)

### 1.6 Mobile-app folder (your output destination)
Inspect what exists at `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/`:
- `Claude_Prompt/` — prompts (this file lives here)
- `Claude_Context/` — your working notes (read/index files, summaries)
- `Requirement/` — Phase 1 + 2 deliverables go here
- `Design/` — Phase 3 architecture/design artifacts go here

If any required file from §1.1–1.5 is missing or empty, **STOP** and list
exactly which files you need before producing any deliverable.

---

## 2. NON-NEGOTIABLE GROUND TRUTH (do not contradict)

These are pulled from `AI_Brain/state/decisions.md` and the memory files.
**Mobile design must respect every one of these.**

| # | Rule | Source |
|---|------|--------|
| 1 | **Database-per-tenant** isolation (stancl/tenancy v3.9). No `tenant_id` columns in tenant tables. Mobile must resolve a tenant context per session. | D1, tenancy-map.md |
| 2 | **3-layer DB:** `global_db` (shared ref), `prime_db` (SaaS mgmt), `tenant_db` (per-school). Mobile API hits tenant_db scoped to the resolved tenant. | D3, project-context.md |
| 3 | **Tenant identification = domain-based.** Mobile clients must send a tenant code/host header — define exactly how. | tenancy-map.md |
| 4 | **Stack is fixed:** Laravel 11, MySQL, Livewire 3, Alpine, Tailwind, AdminLTE 4. Mobile is a **separate cross-platform client** that talks to a **new dedicated `/api/mobile/v1/*` surface** layered on existing controllers/services. | project-context.md |
| 5 | **UUIDs** for tenant IDs (not auto-increment). | D5 |
| 6 | **Auth model:** Laravel Sanctum is the assumed token mechanism; Student/Parent Portal already has login flows — mobile should reuse, not invent. | student-parent-portal.md |
| 7 | **Module system:** nwidart/laravel-modules v12 — all backend code lives in `Modules/<Name>/`. Any new mobile-only endpoint goes inside the relevant module, never in a generic `Mobile` module. | modules-map.md |
| 8 | **Soft deletes everywhere** (D7) — mobile lists must filter, sync engine must respect. |
| 9 | **27/37 modules — verify which are FULL vs RBS_ONLY** before assuming a feature has backend. Cite module status from `modules-map.md` for every feature. |
| 10 | **Critical security issues exist** (see `known-bugs-and-roadmap.md` — SEC-PLATFORM-004, SEC-PAY-001, SEC-HPC-001, etc.). Mobile features that touch these areas must call out the dependency on the underlying fix. |

---

## 3. TARGET USERS (in priority order)

| Priority | Role | Primary Need | Existing Web Surface |
|----------|------|-------------|-----------------------|
| P0 | Student | Daily academics, attendance, homework, fees, results | Student Portal — 35 screens, ~55% complete |
| P0 | Parent | Child monitoring, fees, communication, transport tracking | Parent Portal — 23 screens, ~5% complete |
| P0 | Teacher | Attendance, gradebook, leave, lesson plans, communication | Multiple controllers across SchoolSetup/Attendance/LMS |
| P0 | Transport Staff | Route execution, student boarding, incident reporting | `tpt_*` tables, Transport module |
| P1 | Principal / Head | Daily KPIs, approvals, announcements | HPC, Notifications, Reports |
| P1 | Accountant | Fee approvals, daily collection, reconciliation | Finance/Fee module |
| P2 | Admin / HR / Other | Quick approvals, leave, notices, directory | Various |

App must serve P0 fully, P1 for daily quick actions, P2 for approvals/notifications only.

---

## 4. MOBILE INCLUSION CRITERIA (apply to every feature you propose)

A feature belongs in the mobile app **only if** at least one is true:

1. **Frequency** — used multiple times per day (attendance check, fee balance, push)
2. **Device capability** — needs camera / GPS / biometric / push / offline
3. **Time-sensitive** — transport tracking, emergency notices, OTP approvals
4. **Friction** — web flow is too heavy for mobile context (quick approvals, glance metrics)

If none apply, **leave it on the web app** and list it under Section "Explicitly Excluded".

Other principles:
- **Read-heavy on mobile, write-heavy on web.** Long forms, bulk ops, configuration stay on web.
- **Offline-tolerant** for: attendance marking, homework viewing, lesson plans, transport route execution, downloaded results/timetable.
- **Per-tenant isolation always.** Never assume cross-tenant data is reachable.
- **Single codebase** — recommend Flutter or React Native with reasoning. Design features stack-agnostically.

---

# PHASE 1 — FEATURE LIST

**Deliverable:** `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Requirement/01_mobile_feature_list_v1.md`

Also produce a working-notes index at:
`{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Claude_Context/00_context_index.md`
listing every AI_Brain/RBS file you actually consumed and a 1-line summary of what you took from it.

**Stop after Phase 1.** Wait for explicit `approved — proceed to Phase 2`.

## 1.A Required structure for `01_mobile_feature_list_v1.md`

### Section 1 — Executive Summary
- Recommended cross-platform stack (Flutter vs React Native) — 3-line justification grounded in this project's constraints (Laravel API, AdminLTE web, team skills if known)
- Total feature count broken down by user role (P0/P1/P2 split)
- Modules from the 37-module map that are touched vs left web-only — cite each module's status (FULL / RBS_ONLY / Stub) from `modules-map.md`
- High-level architectural notes:
  - Auth flow (tenant resolution → user login → token → refresh)
  - Push strategy (FCM + APNs → backend dispatcher)
  - Offline strategy (what's cached, what's queued)
  - Tenant resolution (how the app knows which tenant DB to hit)

### Section 2 — Feature Catalogue

Group by Functional Area. Suggested areas (refine based on what you find):
Authentication, Dashboard, Attendance, Academics (Timetable/Syllabus/Homework),
Assessments (Quiz/Quest/Exam/Results), Fees & Payments, Transport,
Communication & Notifications, HPC / Progress Card, Approvals & Leave,
Library, Hostel, Profile & Settings.

For **every feature**, fill this exact table:

```
#### F-XXX: <Feature Name>

| Field | Value |
|-------|-------|
| Feature ID | F-XXX (zero-padded, unique across catalogue) |
| Functional Area | e.g., Attendance |
| Source Module(s) | Exact module name from modules-map.md (e.g., StudentAttendance, Transport, Hpc) |
| Module Status | FULL / RBS_ONLY / Stub — cite modules-map.md |
| Existing Web Surface | Route(s) / controller(s) on web that already implement this (or "none") |
| Source Tables | Table names with prefix (e.g., std_attendance, fin_invoices) — cite db-schema.md / TENANT_DDL |
| Description | 2–4 sentences: what the user sees and does |
| Primary Users | Student / Parent / Teacher / Transport / Principal / etc. |
| Secondary Users | Roles with read-only or limited variant |
| Mobile Justification | Which §4 criteria justify mobile inclusion (cite 1–4) |
| Trigger / Entry Point | Home tile / push / deep link / menu |
| Key Screens | List (e.g., List → Detail → Action confirmation) |
| Device Capabilities | Camera / GPS / Biometric / Push / Offline / None |
| Offline Behavior | Full / Read-only / Queued writes / None |
| Backend Dependency | Existing API in Modules/<Name>/ / New API needed / Module not yet built |
| RBS Mapping | Functionality (F.X.X) and Task IDs from RBS_MAPPING this feature satisfies |
| Notification Triggers | Events that push, and to whom |
| Priority | P0 (MVP) / P1 / P2 |
| Complexity | S / M / L / XL |
| Security Risks Inherited | Cite any open SEC-* / BUG-* IDs from known-bugs-and-roadmap.md that this feature depends on being fixed |
| Open Questions | Things you need decided |
```

### Section 3 — Cross-Cutting Capabilities
Same table format for: Multi-tenant login, Biometric unlock, Push preferences,
In-app messaging, Document/PDF viewer (for HPC, invoices, ID cards), Profile &
language switcher (Hindi + English minimum), App-wide search, Help & support,
About / version / forced-update.

### Section 4 — Explicitly Excluded from Mobile
List Prime-AI features deliberately **not** included with one-line reasons.
Examples likely to land here: SmartTimetable generation, FET solver config,
bulk fee structure setup, bulk student import, plan/billing admin, school
onboarding, tenant management, Vendor module deep flows, full Question Bank
authoring. **This list prevents scope creep — make it thorough.**

### Section 5 — MVP Scope
A single table of P0-only features = what we build first. Include rough
sequencing aligned with the 9-phase `{LIFECYCLE_BLUEPRINT}` so dev work
slots into the existing pipeline.

### Section 6 — Backend Gap Summary
Table of every backend change required (new endpoint / modified endpoint /
new push trigger / new event hook / new table) with:
- Owning module
- Effort estimate (S/M/L)
- Whether the module is FULL or RBS_ONLY (RBS_ONLY = blocks the mobile feature)
- Linked Feature IDs

### Section 7 — Open Decisions for Me
Numbered list. Cover at minimum:
- Final stack choice (if you're presenting alternatives)
- P0 vs P1 borderline calls
- RBS_ONLY modules that block desired features (which to fast-track vs defer)
- Branding / white-label per tenant (logo, color, app name)
- iOS dev account / Android Play console ownership (per-tenant or platform-level)
- Localization scope beyond Hindi + English

---

# PHASE 2 — SOFTWARE REQUIREMENTS SPECIFICATION

**Triggered only after Phase 1 is approved.**

**Output location:** `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Requirement/`

Because the document is large, produce it in **batches of 6–8 features**:

```
02_mobile_srs_index.md          (master index + cross-cutting sections)
02_mobile_srs_batch_01.md       (features 1–8)
02_mobile_srs_batch_02.md       (features 9–16)
...
```

## 2.A `02_mobile_srs_index.md` must contain

1. **Document control** — version, date, dependencies on AI_Brain memory file versions (cite `Last Updated` dates), Prime-AI module-map audit date
2. **Glossary & acronyms**
3. **Overall mobile architecture**
   - Client architecture (state mgmt, navigation, offline DB e.g. Drift/Realm/SQLite, sync engine)
   - Auth flow diagram (tenant resolution → Sanctum login → token refresh)
   - API gateway / base URL strategy per tenant (subdomain? tenant code header?)
   - Push notification architecture (FCM/APNs → backend dispatcher → device)
   - Offline & sync strategy (what's cached, conflict resolution, queue persistence)
   - Security: Sanctum token storage, biometric unlock, jailbreak/root detection, cert pinning
4. **Cross-cutting NFRs** — performance budgets, network resilience, accessibility, localization (Hindi + English minimum), battery, app-size targets
5. **Master feature index** linking every batch file
6. **API summary table** — every endpoint mapped to Feature ID, status (existing/new/modified), owning Laravel module
7. **Push notification catalogue** — every push type with trigger, recipient logic, payload, deep link
8. **Permissions matrix** — OS permissions × features that need them
9. **Release & versioning strategy** — forced upgrade, feature flags

## 2.B Each batch file — per feature

```
### F-XXX: <Feature Name>

#### 1. Overview
Restated description, primary/secondary users, business value.

#### 2. User Stories
Format: As a <role>, I want <action>, so that <outcome>.
Cover happy path + at least 2 edge cases per story.

#### 3. Functional Requirements
FR-XXX.1, FR-XXX.2, ... — testable, atomic.

#### 4. Screen Specifications
For each screen:
- Screen name & navigation path (deep-link URI)
- Layout sketch (ASCII wireframe or component tree)
- Components list with state (loading, empty, error, success, offline)
- Interactions (tap, swipe, pull-to-refresh, long-press)
- Validation rules (client-side)
- Empty/error/offline state copy

#### 5. API Contracts
For every endpoint:
Endpoint:        POST /api/mobile/v1/<resource>
Auth:            Bearer <Sanctum token> + X-Tenant header (per §1.6 of index)
Status:          Existing in Modules/<Name>/ | New endpoint required | Modify existing
Request:         { JSON schema with types and constraints }
Response 200:    { JSON schema }
Response 4xx:    { error codes the client must handle }
Rate limit:      <if any>
Caching:         <client cache TTL, invalidation triggers>
Backend module:  <Modules/<Name>/, controller, service, table(s)>
Backend gap:     <if New: scope, effort S/M/L, owning agent (BA → DB Architect → Backend Developer)>

#### 6. Data Model (client-side)
Local DB tables / Hive boxes / Realm objects with fields, types, indexes, sync status flags.
Map each client field to the backend column it mirrors (cite tenant_db prefix).

#### 7. Offline Behavior
- What's cached, eviction policy
- What writes are queued, retry strategy
- Conflict resolution rules (last-write-wins / manual / merge)

#### 8. Push Notifications
Every push: trigger event, recipient logic, payload, deep-link target, grouping/threading.

#### 9. Permissions & Security
- OS permissions required
- Sensitive data handling (tokens, child PII, fee/payment data)
- Audit log entries (which existing sys_activity_logs / module-specific tables to write to)
- Reference applicable security-rules.md item

#### 10. Non-Functional Requirements
- Performance (target screen load time over 3G/4G/wifi)
- Accessibility (TalkBack/VoiceOver, contrast, font scaling)
- Localization keys introduced
- Analytics events emitted

#### 11. Acceptance Criteria
Given/When/Then format, one set per user story.

#### 12. Dependencies
- Other features (F-IDs)
- Backend modules (with status: FULL / RBS_ONLY / new work)
- Third-party SDKs

#### 13. Out of Scope (this feature, this release)
Explicit list.
```

---

# PHASE 3 — SUPPORTING ARTIFACTS

**Triggered only after Phase 2 is approved.**

**Output location:** `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Design/`

Produce as separate files:

| # | File | Content |
|---|------|---------|
| 1 | `01_mobile_information_architecture.md` | Full screen map, navigation graph per role, deep-link URI scheme, tab/drawer structure per role |
| 2 | `02_mobile_api_contract.md` | Consolidated **OpenAPI 3.0** spec for every mobile endpoint, separating existing vs new. New endpoints get full request/response/error schemas. Group by owning Laravel module. |
| 3 | `03_mobile_backend_gap_analysis.md` | Table of every backend change: new endpoints, modified endpoints, new push triggers, new event hooks, new tables. Each row cites owning module + effort + which RBS sub-task it implements. Cross-link to `{GAP_ANALYSIS_PROJECT_FILE}`. |
| 4 | `04_mobile_push_catalogue.md` | Every notification: trigger event, recipient role + filter logic, title/body templates (with i18n placeholders), deep-link target, grouping rules, user preference controls, quiet-hours behavior |
| 5 | `05_mobile_offline_sync_design.md` | Sync engine design: pull vs push, conflict resolution per entity, queue persistence, retry policy, bandwidth/battery, soft-delete handling (per D7) |
| 6 | `06_mobile_security_design.md` | Auth (multi-tenant resolution, Sanctum token refresh, biometric), data-at-rest (secure storage), data-in-transit (cert pinning), jailbreak/root response, session timeout per role, remote wipe, audit logging. Cross-reference `{AI_BRAIN}/rules/security-rules.md` and known-bugs-and-roadmap.md SEC-* items. |
| 7 | `07_mobile_release_plan.md` | Phased rollout (MVP → v1.1 → v1.2), pilot tenant strategy, feature flag plan, app store submission checklist (iOS + Android), forced-upgrade strategy, analytics & crash reporting setup |
| 8 | `08_mobile_test_strategy.md` | Unit / widget / integration / E2E split, device matrix (Android API levels, iOS versions, screen sizes), offline test scenarios, multi-tenant test approach, performance benchmarks. Align with `{AI_BRAIN}/memory/testing-strategy.md` (Pest 4) for backend-side tests. |
| 9 | `09_mobile_dev_pipeline.md` | Module-by-module build order aligned with the 9-phase, 17-prompt `{LIFECYCLE_BLUEPRINT}`. CI/CD per platform, code-signing, OTA strategy (CodePush / Shorebird if applicable). |

---

# WORKING RULES FOR THE AGENT

1. **Phase gates are hard.** Never skip ahead. Wait for explicit approval ("approved — proceed to Phase N").
2. **No invented backend.** If a feature needs a backend that doesn't exist, flag it as a gap with the exact module + new endpoint(s) needed. Do not assume an endpoint exists — verify against `{PROJECT_DOCS}/11-all-modules-controllers-models.md` or grep `Modules/<Name>/`.
3. **Cite sources.** Every factual claim about modules, tables, routes, or security issues must cite the AI_Brain file and section. Use the `{VARIABLE}` syntax verbatim — don't hard-code paths.
4. **Reuse, don't reinvent.** Student Portal (35 screens) and Parent Portal (23 screens) already exist on web. Mobile features for Student/Parent should be a **mobile lens on those flows**, not a re-design. Only diverge with explicit reasoning.
5. **Naming conventions.** Use exact module names from `modules-map.md`, exact table names with prefixes from `conventions.md` / `db-schema.md`, exact role names from `school-domain.md`. No paraphrasing.
6. **Security awareness.** Before approving a feature touching auth/payment/HPC, scan `known-bugs-and-roadmap.md` for open SEC-* items in that area and surface them under the feature's "Security Risks Inherited" field.
7. **Output is files, not chat.** Write real `.md` files at the paths specified above. After writing, confirm exact paths created.
8. **Empty sections.** If a section would be empty, write `N/A — <reason>` rather than padding.
9. **Ask before guessing.** Anything tenant-specific you can't verify → "Open Questions", not invented answer.
10. **Update the working index.** Each phase, append to `Claude_Context/00_context_index.md` so the next session can resume without re-reading everything.

---

# START INSTRUCTION

Begin **Phase 1 only**. Your first reply must:

1. Confirm the AI_Brain files you successfully read (with their `Last Updated` dates where present).
2. List any required file from §1.1–1.5 that is missing or empty.
3. Confirm the four output folders under `0-Mobile_App/` exist (or that you'll create them).
4. State the stack you will recommend (Flutter or React Native) and one-line reasoning, so I can flag concerns before you build the catalogue.
5. Then produce `01_mobile_feature_list_v1.md` per §1.A and the working notes at `Claude_Context/00_context_index.md`.

**Stop after Phase 1. Wait for "approved — proceed to Phase 2".**
