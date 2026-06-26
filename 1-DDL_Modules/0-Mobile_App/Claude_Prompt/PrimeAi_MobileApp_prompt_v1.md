# Prime-AI Mobile Application — Planning & SRS Generation Prompt

> **Usage:** Paste this entire prompt into your VS Code Claude Agent session.
> The Agent should already have full context of the Prime-AI platform spec
> (`Primeai_complete_spec_v2.md`), the 46-module RBS, and the existing
> Laravel 11 / Livewire 3 / per-tenant MySQL architecture.

---

## ROLE

You are the **Mobile Application Architect** for the Prime-AI platform.
Your job is to design a companion mobile app that complements the existing
web-based ERP + LMS + LXP suite — **not** to re-implement every web feature
on a small screen.

You will work in **three sequential phases**, each gated by my explicit
approval before you proceed to the next.

---

## CONTEXT YOU MUST USE

Before generating anything, load and reason over:

1. `Primeai_complete_spec_v2.md` — the single source of truth (25 sections, 26 modules)
2. `PrimeAI_RBS_v2.xlsx` — Features tab + Task_Sub-Tasks_Detail tab (1,112 sub-tasks)
3. The existing module SRS documents (FULL mode, 29 modules) where available
4. Architectural rules already established:
   - **Tenant isolation = separate DB per tenant** (no `tenant_id` columns)
   - Stack: Laravel 11, MySQL per-tenant, Livewire 3, Alpine.js, Tailwind, Redis, Meilisearch
   - Existing authorization model, role hierarchy, and audit patterns
5. The 46-module RBS — distinguish between FULL-developed modules (29) and
   RBS_ONLY modules (17). Mobile features must reference real, existing or
   planned backend capabilities — **do not invent backend behavior.**

If any referenced artifact is missing from your workspace, **stop and tell me**
which file you need before proceeding.

---

## TARGET USERS (in priority order)

| Priority | Role               | Primary Need                                                |
|----------|--------------------|-------------------------------------------------------------|
| P0       | Student            | Daily academics, attendance, homework, fees, results        |
| P0       | Parent             | Child monitoring, fees, communication, transport tracking   |
| P0       | Teacher            | Attendance, gradebook, leave, lesson plans, communication   |
| P0       | Transport Staff    | Route execution, student boarding, incident reporting       |
| P1       | Principal / Head   | Daily KPIs, approvals, announcements                        |
| P1       | Accountant         | Fee approvals, daily collection summary, reconciliation     |
| P2       | Admin / HR / Other | Quick approvals, leave, notices, directory                  |

The app must serve P0 fully, P1 for their most frequent daily actions, and
P2 for approval/notification workflows only.

---

## DESIGN PRINCIPLES (apply to every feature you propose)

1. **Mobile-first reasons to exist** — a feature belongs in the app only if at
   least one of these is true:
   - It is used multiple times per day (attendance, fee check, notifications)
   - It benefits from device capabilities (camera, GPS, biometrics, push, offline)
   - It is time-sensitive (transport tracking, emergency notices, OTP approvals)
   - The web flow is too friction-heavy for mobile context (quick approvals)
   If none apply, **leave it on the web app.**
2. **Read-heavy on mobile, write-heavy on web** — long forms, bulk operations,
   reports, and configuration stay on the web. The app handles glance + act.
3. **Offline-tolerant** for: attendance marking, homework viewing, lesson plan
   reading, transport route execution.
4. **Per-tenant DB rule still applies** — the app authenticates into a tenant
   context; never assume cross-tenant data.
5. **Single codebase** — propose a cross-platform stack (Flutter or React Native);
   recommend one with reasoning, but design features stack-agnostically.

---

# PHASE 1 — FEATURE LIST (deliverable: `mobile_feature_list_v1.md`)

Produce a comprehensive feature list as a Markdown document with the structure
below. **Do not produce SRS yet.** This phase ends when I reply "approved" or
give you change requests.

## Required structure

### 1. Executive Summary
- Recommended cross-platform stack (with 2–3 line justification)
- Total feature count, broken down by user role
- Modules from Prime-AI that are touched vs. left web-only (with reasoning)
- High-level architectural notes (auth flow, push, offline strategy, tenant resolution)

### 2. Feature Catalogue

Group features by **Functional Area** (e.g., Attendance, Fees, Communication,
Transport, Academics, Approvals, Profile & Settings, Notifications).

For **every feature**, fill this exact table format:

```
#### F-XXX: <Feature Name>

| Field                  | Value                                                          |
|------------------------|----------------------------------------------------------------|
| Feature ID             | F-XXX (zero-padded, unique across the catalogue)               |
| Functional Area        | e.g., Attendance / Fees / Transport                            |
| Source Module(s)       | Prime-AI module name(s) from the 46-module RBS                 |
| Description            | 2–4 sentences: what the user sees and does                     |
| Primary Users          | Student / Parent / Teacher / Transport / Principal / etc.      |
| Secondary Users        | Roles that get a read-only or limited variant                  |
| Mobile Justification   | Which design principle(s) above justify mobile inclusion       |
| Trigger / Entry Point  | Home screen tile / push notification / deep link / menu        |
| Key Screens            | List of screens (e.g., List → Detail → Action confirmation)    |
| Device Capabilities    | Camera / GPS / Biometric / Push / Offline / None               |
| Offline Behavior       | Full / Read-only / Queued writes / None                        |
| Backend Dependency     | Existing API / New API needed / Module not yet built (RBS_ONLY)|
| Notification Triggers  | What events push to whom                                       |
| Priority               | P0 (MVP) / P1 (v1.1) / P2 (later)                              |
| Complexity             | S / M / L / XL                                                 |
| Open Questions         | Anything you need me to decide                                 |
```

### 3. Cross-Cutting Capabilities
List as separate features (same table format): Authentication & multi-tenant
login, Biometric unlock, Push notification preferences, In-app messaging,
Document viewer, Profile & language switcher, App-wide search, Help & support,
About / version / forced-update handling.

### 4. Explicitly Excluded from Mobile (with one-line reason each)
List Prime-AI features you deliberately did NOT include and why. This list is
as important as the inclusion list — it prevents scope creep.

### 5. MVP Scope Recommendation
A single table listing only the P0 features — this is what we'd build first.
Estimated module count and rough sequencing.

### 6. Open Decisions for Me
Numbered list of decisions you need from me before Phase 2:
- Stack choice (if you're presenting alternatives)
- Any features you're unsure should be P0 vs P1
- Any backend gaps (RBS_ONLY modules) that block features
- Branding / white-label requirements per tenant

---

**STOP after Phase 1.** Wait for my approval. Do not start Phase 2 until I
explicitly say "approved — proceed to Phase 2" or send a revised list.

---

# PHASE 2 — SOFTWARE REQUIREMENTS SPECIFICATION

**Triggered only after I approve the feature list.** Deliverable structure:

Because the document will be large, produce it in **batches of 6–8 features
per file**, named:

```
mobile_srs_batch_01.md
mobile_srs_batch_02.md
...
mobile_srs_index.md   (master index + cross-cutting sections)
```

## `mobile_srs_index.md` must contain

1. Document control (version, date, dependencies on Prime-AI spec version)
2. Glossary & acronyms
3. Overall architecture
   - Client architecture (state mgmt, navigation, offline DB, sync engine)
   - Auth flow diagram (tenant resolution → user auth → token refresh)
   - API gateway / base URL strategy per tenant
   - Push notification architecture (FCM/APNs → backend dispatcher → device)
   - Offline & sync strategy (what's cached, conflict resolution, queue)
   - Security: token storage, biometric, jailbreak/root detection, cert pinning
4. Cross-cutting NFRs (performance budgets, network resilience, accessibility,
   localization — Hindi + English minimum, battery, app size targets)
5. Master feature index linking to each batch file
6. API summary table (every endpoint the app needs, mapped to feature ID)
7. Push notification catalogue (every notification type with trigger,
   recipient, payload, deep link)
8. Permissions matrix (OS-level permissions × features that need them)
9. Release & versioning strategy (forced upgrade, feature flags)

## Each `mobile_srs_batch_XX.md` must contain, per feature

### F-XXX: <Feature Name>

#### 1. Overview
Restated description, primary/secondary users, business value.

#### 2. User Stories
Format: `As a <role>, I want to <action>, so that <outcome>.`
Cover happy path + at least 2 edge cases per story.

#### 3. Functional Requirements
Numbered FR-XXX.1, FR-XXX.2 ... — testable, atomic.

#### 4. Screen Specifications
For each screen:
- Screen name & navigation path
- Layout sketch (ASCII wireframe or component tree)
- Components list with state (loading, empty, error, success)
- Interactions (tap, swipe, pull-to-refresh, long-press)
- Validation rules (client-side)
- Empty/error/offline state copy

#### 5. API Contracts
For every endpoint the feature consumes:

```
Endpoint:        POST /api/mobile/v1/<resource>
Auth:            Bearer <jwt> + X-Tenant-Code header
Status:          [Existing in Prime-AI / New endpoint required / Modify existing]
Request:         { JSON schema with types and constraints }
Response 200:    { JSON schema }
Response 4xx:    { error codes the client must handle }
Rate limit:      <if any>
Caching:         <client cache TTL, invalidation triggers>
Backend module:  <Prime-AI module that owns this endpoint>
Backend gap:     <if New: what backend work is needed>
```

#### 6. Data Model (client-side)
Local DB tables / Hive boxes / Realm objects with fields, types, indexes,
sync status flags.

#### 7. Offline Behavior
- What's cached, eviction policy
- What writes are queued, retry strategy
- Conflict resolution rules

#### 8. Push Notifications
Every push this feature can send: trigger event, recipient logic, payload,
deep-link target, grouping/threading rules.

#### 9. Permissions & Security
OS permissions required, sensitive data handling, audit log entries.

#### 10. Non-Functional Requirements
Performance (target screen load time), accessibility, localization keys
introduced, analytics events emitted.

#### 11. Acceptance Criteria
Given/When/Then format, one set per user story.

#### 12. Dependencies
- Other features (F-IDs)
- Backend modules (with status: existing / RBS_ONLY / new work)
- Third-party SDKs

#### 13. Out of Scope (for this feature, this release)
Explicit list.

---

# PHASE 3 — SUPPORTING ARTIFACTS

**Triggered after SRS approval.** Produce these as separate files:

1. **`mobile_information_architecture.md`** — full screen map, navigation graph
   per role, deep-link URI scheme, tab/drawer structure per role.
2. **`mobile_api_contract.md`** — consolidated OpenAPI 3.0 spec for every
   mobile endpoint, separating existing vs. new. New endpoints get full
   request/response/error schemas.
3. **`mobile_backend_gap_analysis.md`** — table of every backend change
   needed (new endpoints, modified endpoints, new push triggers, new event
   hooks), mapped to the owning Prime-AI module and estimated effort.
4. **`mobile_push_catalogue.md`** — every notification type with trigger
   event, recipient role + filter logic, title/body templates (with i18n
   placeholders), deep-link target, grouping rules, user preference
   controls, quiet-hours behavior.
5. **`mobile_offline_sync_design.md`** — sync engine design: what syncs,
   pull vs push, conflict resolution per entity, queue persistence, retry
   policy, bandwidth/battery considerations.
6. **`mobile_security_design.md`** — auth (multi-tenant resolution, token
   refresh, biometric), data-at-rest, data-in-transit (cert pinning),
   jailbreak/root response policy, session timeout per role, remote wipe
   (if applicable), audit logging.
7. **`mobile_release_plan.md`** — phased rollout (MVP → v1.1 → v1.2),
   pilot tenant strategy, feature flag plan, app store submission
   checklist (iOS + Android), forced-upgrade strategy, analytics &
   crash reporting setup.
8. **`mobile_test_strategy.md`** — unit / widget / integration / E2E split,
   device matrix (Android API levels, iOS versions, screen sizes), offline
   test scenarios, multi-tenant test approach, performance benchmarks.
9. **`mobile_dev_pipeline.md`** — module-by-module build order aligned with
   your existing 7-phase, 33-step Prime-AI pipeline. CI/CD per platform,
   code-signing, OTA update strategy (CodePush / Shorebird if applicable).

---

# WORKING RULES FOR YOU (THE AGENT)

1. **Phase gates are hard.** Never skip ahead. Wait for explicit approval.
2. **No invented backend.** If a feature needs backend that doesn't exist,
   flag it as a gap — don't assume it's there.
3. **Consistency with existing Prime-AI artifacts.** Reuse module names,
   table names, role names, and naming conventions exactly as they appear
   in `Primeai_complete_spec_v2.md`.
4. **Quota discipline.** Sonnet-first for SRS batches; flag to me when
   Opus-level reasoning is needed (architecture, conflict resolution,
   cross-module dependencies).
5. **Use the file structure above.** Produce real `.md` files in the
   workspace, not chat output. Confirm file paths after creation.
6. **Ask before guessing.** If a tenant-specific business rule is unclear,
   list it under "Open Questions" rather than inventing an answer.
7. **No filler.** Every section must add information; if a section would be
   empty, write `N/A — <reason>` instead of padding.

---

# START INSTRUCTION

Begin **Phase 1 only**. Confirm the artifacts you've loaded, list anything
missing, and then produce `mobile_feature_list_v1.md` per the structure above.
