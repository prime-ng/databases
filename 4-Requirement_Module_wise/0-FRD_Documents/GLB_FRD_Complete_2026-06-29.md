# GlobalMaster (GLB) — Complete Analysis Pack
# Prime-AI Academic Intelligence Platform

| Field | Value |
|-------|-------|
| **Module Name** | GlobalMaster |
| **Module Code** | GLB |
| **Table Prefix** | `glb_` (also owns `prm_plans`, `media`; consumes `sys_dropdowns`, `sys_activity_logs`) |
| **Platform Layer** | **CENTRAL — Global DB** (`global_db` via `global_master_mysql` + `prime_db` via default `mysql`) |
| **Document Version** | 1.0 |
| **Date** | 2026-06-29 |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI |
| **Sources Read** | Live code (`Modules/GlobalMaster/` — migrations, models, controllers, routes, tests); V2 Requirement `GLB_GlobalMaster_Requirement.md` (2026-03-26); `global_db_v4.sql`; AI_Brain memory (conventions, project-context, modules-map) |

> **This is the consolidated Complete Analysis Pack.** It is FRD-first: Sections A–J below open with the full FRD (Section A) whose `REQ-/BR-/RPT-/ENH-` IDs are the single source of truth; every later section references those IDs without renumbering. Business-language register is used throughout except in the explicitly technical sections (Data Dictionary technical view, Dependency Map).

## Table of Contents
- **Section A — Functional Requirements Document (FRD)** — A1 Overview · A2 Roles · A3 Functional Requirements (REQ-) · A4 Business Rules Register (BR-) · A5 Data Requirements · A6 Workflows · A7 Reporting (RPT-) · A8 Enhancements (ENH-) · A9 NFRs · A10 Gap-Analysis Readiness Index
- **Section B — Requirements Traceability Matrix (RTM)**
- **Section C — Requirement Conditions Catalog + Validation & Edge-Case Catalog**
- **Section D — Process Flows + State Machine (FSM) Catalog**
- **Section E — Data Dictionary (business + technical view)**
- **Section F — Cross-Module Dependency Map**
- **Section G — NFR Catalog + Risk Register**
- **Section H — Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks**
- **Section I — User Stories (Gherkin) + Reporting & KPI Spec**
- **Section J — Feature Specification (screen-by-screen)**
- **Section K — Module Knowledge update note**

---

# Section A — Functional Requirements Document (FRD)

## A1 — Module Overview

### 1.1 Business Purpose
GlobalMaster is the platform's **central reference-data control room**. It is the one place where the Prime-AI operations team defines the shared "facts of the world" that every school on the platform relies on — the list of countries, states, districts and cities used in addresses; the educational boards (CBSE, ICSE, IB…); the academic years; the supported languages; the catalog of product modules; the subscription plans sold to schools; and the platform-wide dropdown/lookup values. Without this module, each school would have to re-enter the same reference data, and the sales/onboarding team would have no catalog of plans or modules to sell. Because this data is owned centrally and shared by all schools, it lives outside any single school's database.

### 1.2 Business Value
- **One source of truth** for geography, boards, academic years and languages — eliminates duplicate, inconsistent reference data across hundreds of schools.
- **Sales & onboarding enablement** — a clean catalog of subscription plans and the modules each plan includes, ready for the tenant-onboarding wizard and billing.
- **Consistent dropdowns everywhere** — platform-wide lookup lists (status, severity, priority, type) are configured once and consumed by every school module.
- **Governance & auditability** — a read-only activity log gives the operations team a tamper-evident record of every change to platform reference data.
- **Internationalisation foundation** — language and translation registries prepare the platform for multilingual content.

### 1.3 Scope

#### In Scope
1. Full lifecycle management (create, edit, deactivate/reactivate, archive, restore, permanently remove) of the geographic hierarchy: Countries → States → Districts → Cities.
2. A unified Geography Setup workspace with tab-aware search and per-tab paging.
3. Management of Educational Boards.
4. Management of Academic Sessions (academic years), including enforcement that exactly one session is the "current" one.
5. Management of supported Languages and (future) their Translations.
6. Management of the platform Module Registry, including which menus a module exposes and which permission types it supports.
7. Management of Subscription Plans, including the set of modules each plan bundles and its pricing/billing cycle.
8. Management of platform-wide Dropdown / Lookup values.
9. A read-only Activity Log viewer (platform audit trail).
10. A combined Session-Board setup hub for onboarding reference.
11. A reference-data API for schools' apps to read this data (future).

#### Out of Scope
1. School-specific customisation of reference data — handled by **SchoolSetup**.
2. Invoicing and payment collection beyond defining a plan's price — handled by **Billing** and **Payment**.
3. Tenant user/role administration — handled by the central **Prime** / auth modules.
4. **Menu CRUD authoring** — owned by **SystemConfig**; GlobalMaster only *links* existing menus to modules.
5. Rendering of menus inside school apps — done by tenant-side middleware.
6. Any per-school operational data (students, fees, timetables, etc.).

### 1.4 Key Terminology
| Business Term | Meaning |
|---------------|---------|
| Reference Data | Shared "facts of the world" owned centrally and read by all schools (countries, boards, languages, etc.). |
| Geographic Hierarchy | The four-level chain Country → State → District → City; each child belongs to one parent. |
| Educational Board | An examination/curriculum authority a school is affiliated with (CBSE, ICSE, IB, IGCSE, NIOS, State boards). |
| Academic Session | A defined academic year (e.g. "2025-26", 1 Apr → 31 Mar) used as a reference by every school. |
| Current Session | The one academic session marked active platform-wide; only one may be current at a time. |
| Module Registry | The master catalog of product modules that exist in Prime-AI, with their permission options and menu links. |
| Subscription Plan | A sellable package (price + billing cycle + bundled modules) assigned to a school. |
| Dropdown / Lookup Value | A platform-wide configurable list item (e.g. complaint severity, status) keyed by name and consumed across modules. |
| Activity Log | The read-only audit trail recording who changed what reference data and when. |
| Deactivate vs Archive vs Remove | Deactivate = hide via status flag; Archive = soft-delete to trash (restorable); Remove = permanent delete from trash. |
| Cascade | When deactivating a parent (e.g. a country) automatically deactivates its descendants. |

---

## A2 — User Roles & Access

### 2.1 Actor Definitions
| Role | Who They Are | Their Relationship to This Module |
|------|-------------|----------------------------------|
| Platform Super Admin | Prime-AI platform operator | Full control over all reference data, including permanent removal. |
| Platform Manager | Senior reference-data steward | Create/edit/deactivate/archive/restore; not permanent removal. |
| Support Staff | Read-only operations viewer | View lists and the activity log only. |
| Consuming Modules / School Apps | SchoolSetup, Prime onboarding, Billing, StudentProfile, all tenant modules | Read reference data (geography, boards, sessions, dropdowns, plans) — never edit it. |

### 2.2 Role-Feature Access Matrix
| Feature | Super Admin | Platform Manager | Support Staff |
|---------|-------------|------------------|---------------|
| Geography (Country/State/District/City) | Full + Remove | Full (no Remove) | View Only |
| Geography Setup workspace | Full | Full | View Only |
| Educational Boards | Full + Remove | Full (no Remove) | View Only |
| Academic Sessions | Full + Remove | Full (no Remove) | View Only |
| Languages | Full + Remove | Full (no Remove) | View Only |
| Translations (future) | Full | Full | View Only |
| Module Registry | Full + Remove | Full (no Remove) | View Only |
| Subscription Plans | Full + Remove | Full (no Remove) | View Only |
| Dropdown / Lookup Values | Full + Remove | Full (no Remove) | View Only |
| Activity Log Viewer | View Only | View Only | View Only |
| Reference Data API (future) | Read (token) | Read (token) | Read (token) |

---

## A3 — Functional Requirements

### 3.1 Country Management
**Requirement ID:** REQ-GLB-001 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** The operations team maintains the master list of countries used wherever an address or nationality is captured. Each country carries a name, a short code, an optional international code and a currency code, and an active/inactive status. Countries can be archived to trash, restored, or permanently removed when no states depend on them. Deactivating a country cascades down its geographic descendants.
**Actors:** Initiates — Platform Manager/Super Admin · Processes — System (cascade, audit) · Views — Support Staff, consuming modules.
**Business Rules:** BR-GLB-001, BR-GLB-002, BR-GLB-003, BR-GLB-005, BR-GLB-022.
**Acceptance Criteria:**
1. A user with the create permission can add a country with a unique name and short code; duplicates are rejected with a clear message.
2. Editing enforces uniqueness while ignoring the record being edited.
3. Deactivating a country also deactivates its states, districts AND cities within one all-or-nothing transaction.
4. Archiving a country first deactivates it, then moves it to trash; it can be restored.
5. Permanent removal is blocked with a friendly message when dependent states exist (no orphan/crash).
6. Every create/edit/deactivate/archive/restore/remove writes an activity-log entry only after the action succeeds.
**Integration:** Sends to SchoolSetup, StudentProfile (address geography). Receives from None.
**Enhancement Notes:** Bulk CSV import (ENH-GLB-001); caching for tenant forms (ENH-GLB-008).

### 3.2 State Management
**Requirement ID:** REQ-GLB-002 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** States belong to a country. The team manages states scoped to their parent country, with the state name unique within that country. A dependent-dropdown helper returns the states for a chosen country so downstream forms can offer cascading selectors.
**Actors:** Initiates — Platform Manager/Super Admin · Processes — System · Views — Support Staff, consuming forms.
**Business Rules:** BR-GLB-002, BR-GLB-003, BR-GLB-004, BR-GLB-005, BR-GLB-022.
**Acceptance Criteria:**
1. A state can only be created against an existing country; the (country, state-name) pair must be unique.
2. A state cannot be reactivated while its parent country is inactive.
3. A "states by country" lookup returns only the relevant states for use in dependent dropdowns.
4. Full archive/restore/remove lifecycle works; remove is blocked when districts depend on the state.
5. Each successful change writes exactly one activity-log entry (no duplicates).
**Integration:** Sends to SchoolSetup, StudentProfile. Receives from REQ-GLB-001 (parent country).
**Enhancement Notes:** Cache "states by country" responses (ENH-GLB-008).

### 3.3 District Management
**Requirement ID:** REQ-GLB-003 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** Districts belong to a state; the district name is unique within its state. Districts follow the same active/archive/restore/remove lifecycle and parent-status rules as states.
**Actors:** Initiates — Platform Manager/Super Admin · Processes — System · Views — Support Staff.
**Business Rules:** BR-GLB-002, BR-GLB-003, BR-GLB-021.
**Acceptance Criteria:**
1. A district can only be created against an existing state; the (state, district-name) pair must be unique.
2. A district cannot be reactivated while its parent state is inactive.
3. Permanent removal uses the dedicated remove permission and is blocked when cities depend on the district.
4. The list presents districts grouped by their country → state hierarchy.
**Integration:** Sends to SchoolSetup, StudentProfile. Receives from REQ-GLB-002.
**Enhancement Notes:** None.

### 3.4 City Management
**Requirement ID:** REQ-GLB-004 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** Cities belong to a district and optionally carry a default time-zone. They are consumed by student and organisation address capture. Cities follow the standard lifecycle; a city should not be reactivated while its parent district is inactive.
**Actors:** Initiates — Platform Manager/Super Admin · Processes — System · Views — Support Staff, StudentProfile.
**Business Rules:** BR-GLB-002, BR-GLB-003, BR-GLB-022.
**Acceptance Criteria:**
1. A city can only be created against an existing district.
2. A city carries an optional default time-zone.
3. A city cannot be reactivated while its parent district is inactive.
4. Full archive/restore/remove lifecycle works; the list is paginated rather than loading every city at once.
**Integration:** Sends to StudentProfile (student city), SchoolSetup. Receives from REQ-GLB-003.
**Enhancement Notes:** Optimise the four-level address listing (performance).

### 3.5 Geography Setup Workspace
**Requirement ID:** REQ-GLB-005 **Priority:** Standard (P1) **Tags:** [DASHBOARD] [DATA_ENTRY]
**Business Description:** A single tabbed workspace lets the team browse and search Countries, States, Districts and Cities side-by-side. Each tab searches only its own entity, pages independently, and offers a quick type-ahead search. Access is granted if the user may view any one of the four geography entities.
**Actors:** Initiates — Support Staff / Manager · Processes — System · Views — all geography viewers.
**Business Rules:** BR-GLB-023, BR-GLB-024.
**Acceptance Criteria:**
1. Four tabs (Country/State/District/City) appear on one screen, each independently paged.
2. Searching within a tab filters only that tab's entity.
3. A type-ahead search endpoint returns matching names for the active tab.
4. The workspace opens for any user holding at least one geography "view" permission.
**Integration:** Reads REQ-GLB-001…004. Receives from None.
**Enhancement Notes:** Geographic hierarchy tree/map visualisation (ENH-GLB-003).

### 3.6 Educational Board Management
**Requirement ID:** REQ-GLB-006 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** The team maintains the list of educational boards a school can be affiliated with (CBSE, ICSE/ISC, IGCSE, IB, NIOS, State boards). A board carries a unique name and short code and a status. Boards are linked to school organisations through onboarding and so cannot be removed while affiliations exist.
**Actors:** Initiates — Platform Manager/Super Admin · Processes — System · Views — SchoolSetup.
**Business Rules:** BR-GLB-013, BR-GLB-014, BR-GLB-003.
**Acceptance Criteria:**
1. A board can be created with a unique name and unique short code.
2. Editing enforces uniqueness ignoring the current record.
3. Boards appear in the Session-Board setup hub.
4. A board affiliated with one or more school organisations cannot be permanently removed.
**Integration:** Sends to SchoolSetup (board affiliation). Receives from None.
**Enhancement Notes:** Dedicated board trash/restore screens; board translations.

### 3.7 Academic Session Management
**Requirement ID:** REQ-GLB-007 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION] [WORKFLOW]
**Business Description:** The team defines the academic years (e.g. "2025-26", running 1 April → 31 March) used as a platform reference. Exactly one session is marked "current" at any time; marking a new one current automatically un-marks the previous one. The current/active session cannot be archived.
**Actors:** Initiates — Platform Manager/Super Admin · Processes — System (single-current enforcement) · Views — Prime onboarding, all schools.
**Business Rules:** BR-GLB-007, BR-GLB-008, BR-GLB-009, BR-GLB-010, BR-GLB-019.
**Acceptance Criteria:**
1. A session is created with a unique name and short code, a start date and an end date.
2. The start date must be before the end date.
3. Setting a session as current automatically clears the "current" flag on all other sessions; the platform never has two current sessions.
4. The currently-active session cannot be archived/deleted.
5. All academic-session screens load without error (the underlying record type must exist).
**Integration:** Sends to Prime (tenant onboarding), all academic modules. Receives from None.
**Enhancement Notes:** Automated session rollover (ENH-GLB-006).

### 3.8 Language Management
**Requirement ID:** REQ-GLB-008 **Priority:** Standard (P1) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** The team maintains the list of languages the platform supports for multilingual content, each with an ISO code, an English name, an optional native-script name and a text direction (left-to-right or right-to-left). Only authorised users may create or edit languages.
**Actors:** Initiates — Platform Manager/Super Admin · Processes — System · Views — i18n-aware modules.
**Business Rules:** BR-GLB-016, BR-GLB-020, BR-GLB-021, BR-GLB-022.
**Acceptance Criteria:**
1. A language is created with a unique ISO code and a direction of LTR or RTL.
2. Only users with the create/edit permission may create or edit a language (no unauthenticated or under-permissioned access).
3. Full archive/restore/remove lifecycle works and each action logs the correct event.
4. Right-to-left languages (e.g. Urdu/Arabic) are supported via the direction setting.
**Integration:** Sends to Translation registry (REQ-GLB-014), i18n-aware modules. Receives from None.
**Enhancement Notes:** None.

### 3.9 Module Registry Management
**Requirement ID:** REQ-GLB-009 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** The Module Registry is the master catalog of product modules in Prime-AI. Each entry records the module name, version, whether it is a core (always-included) module or optional, which permission types it supports (view/add/edit/delete/export/import/print), default visibility, and which menus it exposes. Modules can be nested as sub-modules under a parent. The registry drives what can be bundled into plans and how permissions/menus render.
**Actors:** Initiates — Super Admin/Platform Manager · Processes — System (menu sync) · Views — Plan management, permission/menu rendering.
**Business Rules:** BR-GLB-011, BR-GLB-012, BR-GLB-017, BR-GLB-018, BR-GLB-022.
**Acceptance Criteria:**
1. A module can be created with a name, version, core/optional flag, the seven permission-availability flags, and at least one linked menu.
2. A module may be defined as a sub-module of a parent module.
3. Editing a module replaces its full set of menu links.
4. Module identity is unique on the parent + name + version combination; a new version is a new entry, not an overwrite.
5. Viewing a module's detail uses a view permission and shows a read-only detail screen.
**Integration:** Sends to Plan management (REQ-GLB-010), permission/menu rendering. Receives from SystemConfig (menus).
**Enhancement Notes:** Module dependency graph (ENH-GLB-004); sub-module parent selector in the form.

### 3.10 Subscription Plan Management
**Requirement ID:** REQ-GLB-010 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION] [INTEGRATION]
**Business Description:** Plans are the packages sold to schools. Each plan has a code, name, version, description, a billing cycle (monthly/quarterly/yearly/one-time), monthly and yearly prices, a currency, a trial period, and a set of bundled modules (at least one). Plan details can be fetched for a quick on-screen summary during onboarding.
**Actors:** Initiates — Super Admin/Platform Manager · Processes — System (module sync) · Views — Prime onboarding, Billing, sales.
**Business Rules:** BR-GLB-011, BR-GLB-015, BR-GLB-022, BR-GLB-025.
**Acceptance Criteria:**
1. A plan is created with a unique (code, version) and at least one bundled module.
2. The billing cycle is chosen from the maintained billing-cycle list.
3. Editing a plan replaces its full set of bundled modules.
4. A plan's detail (with its modules and pricing) can be viewed only by a user with the plan-view permission.
5. Full archive/restore/remove lifecycle works.
**Integration:** Sends to Prime onboarding, Billing (plan → invoices). Receives from REQ-GLB-009 (modules), billing-cycle list.
**Enhancement Notes:** Plan comparison matrix (ENH-GLB-005); add a quarterly price point; drive billing cycles fully from the maintained list.

### 3.11 Dropdown / Lookup Value Management
**Requirement ID:** REQ-GLB-011 **Priority:** Core (P0) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** Many modules use configurable lookup lists (e.g. complaint severity, priority, status, types). This feature lets the team define those values centrally: a key groups related values, each value has a display label, a data type and a sort order. Values can be bulk-created from a comma-separated list and follow the standard active/archive/restore/remove lifecycle.
**Actors:** Initiates — Super Admin/Platform Manager · Processes — System · Views — every consuming module.
**Business Rules:** BR-GLB-026, BR-GLB-027, BR-GLB-028, BR-GLB-029.
**Acceptance Criteria:**
1. A user can create one or many values under a key (comma-separated input creates multiple, de-duplicated, values).
2. The key is normalised to a consistent slug form.
3. Each value carries a data type from the allowed set (Text, Whole Number, Decimal, Date, Date-Time, Time, Yes/No).
4. The list groups values by key and pages without running one query per key.
5. Full archive/restore/remove lifecycle works.
**Integration:** Sends to Complaint and all modules that read lookup lists. Receives from None.
**Enhancement Notes:** None.

### 3.12 Activity Log Viewer
**Requirement ID:** REQ-GLB-012 **Priority:** Standard (P1) **Tags:** [REPORT] [DASHBOARD]
**Business Description:** A read-only viewer shows the platform audit trail: who did what to which reference record and when, captured automatically whenever reference data changes. It is strictly view-only — entries can never be edited or deleted from the interface.
**Actors:** Initiates — System (auto-capture) · Views — Super Admin, Platform Manager, Support Staff.
**Business Rules:** BR-GLB-005, BR-GLB-030, BR-GLB-031.
**Acceptance Criteria:**
1. The log lists entries in reverse-chronological order, paginated.
2. No create/edit/delete action is offered anywhere in the interface.
3. Each entry shows the actor, the event type, the affected record, and the timestamp.
4. (Target) The log can be filtered by user, date range, event type and record type, and exported.
**Integration:** Reads the platform-wide audit trail written by every module via the shared logging helper. Receives from All modules.
**Enhancement Notes:** Filters + CSV export (RPT-GLB-001 enhancement).

### 3.13 Session-Board Setup Hub
**Requirement ID:** REQ-GLB-013 **Priority:** Standard (P1) **Tags:** [DASHBOARD]
**Business Description:** A combined onboarding-reference screen shows Academic Sessions and Educational Boards side-by-side, each paginated, so the team can review both at a glance during tenant setup.
**Actors:** Initiates — Support Staff/Manager · Views — onboarding team.
**Business Rules:** BR-GLB-007, BR-GLB-013.
**Acceptance Criteria:**
1. The hub shows academic sessions and boards on one screen, each independently paged.
2. The hub opens for users with the board-view permission.
**Integration:** Reads REQ-GLB-006, REQ-GLB-007. Receives from None.
**Enhancement Notes:** None.

### 3.14 Translation Management
**Requirement ID:** REQ-GLB-014 **Priority:** Enhanced (P2) **Tags:** [DATA_ENTRY] [CONFIGURATION]
**Business Description:** A planned feature to manage translated values for any reference-data field in any supported language — for example, board or country names in regional languages. A translation ties a specific record's field to a language and a translated value, with one value per field per language per record.
**Actors:** Initiates — Platform Manager · Processes — System · Views — i18n-aware modules.
**Business Rules:** BR-GLB-032, BR-GLB-033, BR-GLB-034.
**Acceptance Criteria:**
1. A translation can be recorded for a chosen record, field, language and value.
2. The same field cannot be translated twice into the same language for the same record.
3. Removing a language removes its translations.
**Integration:** Reads REQ-GLB-008 (languages). Receives from None.
**Enhancement Notes:** Translation management dashboard (ENH-GLB-002). *Status: not started — no record type, screen or logic exists yet.*

### 3.15 Reference Data API (Tenant Consumption)
**Requirement ID:** REQ-GLB-015 **Priority:** Standard (P1) **Tags:** [INTEGRATION] [REPORT]
**Business Description:** A planned read-only programmatic interface so schools' apps can fetch reference data (active countries, dependent states/districts/cities, boards, academic sessions including the current one, languages, dropdown values by key, modules). Today only an empty placeholder interface exists.
**Actors:** Initiates — School apps (token-authenticated) · Processes — System · Views — consuming apps.
**Business Rules:** BR-GLB-002, BR-GLB-007, BR-GLB-024.
**Acceptance Criteria:**
1. A token-authenticated caller can list active countries and drill down to states/districts/cities.
2. A caller can fetch the current academic session in one call.
3. A caller can fetch dropdown values by key, and the list of boards and languages.
4. Responses follow the platform's standard success/error envelope.
**Integration:** Read by all tenant apps. Receives from REQ-GLB-001…011.
**Enhancement Notes:** API usage/rate-limit dashboard (ENH-GLB-007). *Status: not started — placeholder only.*

---

## A4 — Business Rules Register
| Rule ID | Description (business) | Feature | Type | Priority |
|---------|------------------------|---------|------|----------|
| BR-GLB-001 | Deactivating a country must cascade to all its states, districts AND cities in one all-or-nothing transaction; reactivating a country does not auto-reactivate descendants. | REQ-GLB-001 | Workflow/Calculation | P0 |
| BR-GLB-002 | A child cannot be reactivated while its parent is inactive (state←country, district←state, city←district). | 001-004,015 | Validation | P0 |
| BR-GLB-003 | A reference record that has dependent children cannot be permanently removed; the attempt is blocked with a friendly message (no orphan, no crash). | 001-004,006 | Validation | P0 |
| BR-GLB-004 | A state's name must be unique within its parent country; a district's within its state. | 002,003 | Validation | P0 |
| BR-GLB-005 | An activity-log entry is written only after all guards pass and the action succeeds — a failed/blocked action must not log as success. | 001-004,007,012 | Workflow | P1 |
| BR-GLB-006 | Every reference entity follows the soft-delete lifecycle: deactivate sets the status flag, archive soft-deletes (restorable from trash), and permanent removal is only available from trash. | 001-004,006,008,009,010,011 | Workflow | P1 |
| BR-GLB-007 | Exactly one academic session may be "current" at any time, enforced at the data layer. | 007,013,015 | Concurrency | P0 |
| BR-GLB-008 | Marking a session current automatically clears the current flag on all other sessions. | 007 | Workflow | P0 |
| BR-GLB-009 | The currently-active session cannot be archived/removed. | 007 | Validation | P0 |
| BR-GLB-010 | A session's start date must be before its end date (cross-field). | 007 | Validation | P1 |
| BR-GLB-011 | A subscription plan must bundle at least one module; a core module is included by default and cannot be removed. | 009,010 | Validation | P0 |
| BR-GLB-012 | A sub-module must have a parent module; a top-level module must not. | 009 | Validation | P1 |
| BR-GLB-013 | Standard pre-seeded boards include CBSE, ICSE/ISC, IGCSE, IB, NIOS and state boards. | 006,013 | Configuration | P2 |
| BR-GLB-014 | A board affiliated with one or more school organisations cannot be permanently removed. | 006 | Validation | P1 |
| BR-GLB-015 | Currency is a 3-letter ISO code (default INR); trial period is 1–30 days. | 010 | Validation | P1 |
| BR-GLB-016 | A language has a direction of either left-to-right or right-to-left. | 008 | Validation | P1 |
| BR-GLB-017 | Module identity is unique on (parent, name, version); a new version is a new record. | 009 | Validation | P1 |
| BR-GLB-018 | A module's permission-availability flags define which permission types appear for it in role management. | 009 | Configuration | P1 |
| BR-GLB-019 | The academic-session record type must exist so its screens load (no runtime failure). | 007 | Validation | P0 |
| BR-GLB-020 | Only users holding the relevant create/edit permission may create or edit a language. | 008 | Permission | P0 |
| BR-GLB-021 | Permanent removal must use the dedicated "remove" permission, never the "deactivate/archive" permission. | 003,008 | Permission | P1 |
| BR-GLB-022 | Saving a record must persist only validated fields (no blanket accept-all of submitted data). | 001-004,007,009,010 | Validation/Security | P0 |
| BR-GLB-023 | Search text used in list filters must be sanitised so crafted patterns cannot degrade the service. | 005 | Security | P2 |
| BR-GLB-024 | Public search/lookup endpoints must be rate-limited per user. | 005,015 | Security | P2 |
| BR-GLB-025 | A plan's billing cycle must be chosen from the maintained billing-cycle list (not a fixed in-code list). | 010 | Validation | P2 |
| BR-GLB-026 | A dropdown key is normalised to a consistent slug form on save. | 011 | Calculation | P1 |
| BR-GLB-027 | Comma-separated values create multiple lookup values, de-duplicated before saving. | 011 | Calculation | P1 |
| BR-GLB-028 | A lookup value's sort order is maintained within its key group. | 011 | Calculation | P1 |
| BR-GLB-029 | A lookup value's data type must be one of: Text, Whole Number, Decimal, Date, Date-Time, Time, Yes/No. | 011 | Validation | P1 |
| BR-GLB-030 | The activity log is append-only from the interface — no edit or delete is ever offered. | 012 | Permission | P1 |
| BR-GLB-031 | Each activity-log entry records the affected record, the event type, the actor and the timestamp. | 012 | Workflow | P1 |
| BR-GLB-032 | A polymorphic translation ties a record + field + language to a translated value. | 014 | Configuration | P2 |
| BR-GLB-033 | The same field cannot be translated twice into the same language for the same record. | 014 | Validation | P2 |
| BR-GLB-034 | Removing a language removes all of its translations. | 014 | Workflow | P2 |

---

## A5 — Data Requirements
*(Business view; privacy classification per entity. Technical column mapping is in Section E.)*

### 5.1 Country / State / District / City (Geographic Hierarchy)
**Represents:** the four-level address hierarchy shared platform-wide.
**Key information:** name; short code; international code (optional); currency code (country only); default time-zone (city only); active status; parent reference (state→country, district→state, city→district).
**Relationships:** Country contains States; State contains Districts; District contains Cities. Each child belongs to exactly one parent.
**Data Retention:** Soft-deleted (archived) and restorable; permanent removal blocked while children exist.
**Privacy:** Open (public reference data).

### 5.2 Educational Board
**Represents:** an examination/curriculum authority. **Key info:** name (unique), short code (unique), active status. **Relationships:** affiliated to school organisations (many-to-many, with the academic session of affiliation). **Retention:** soft-delete; cannot remove while affiliated. **Privacy:** Open.

### 5.3 Academic Session
**Represents:** a platform academic year. **Key info:** short code (unique), name, start date, end date, "current" indicator. **Relationships:** referenced by tenant onboarding and organisation sessions. **Retention:** soft-delete; the current session cannot be removed. **Privacy:** Open.

### 5.4 Language / Translation
**Language key info:** ISO code (unique), English name (unique), native name (optional), direction (LTR/RTL), active status. **Translation key info:** target record type + id, language, field key, translated value (one per field/language/record). **Relationships:** a translation belongs to a language; removing a language removes its translations. **Retention:** language soft-deletes; translations are hard-deleted/cascade. **Privacy:** Open.

### 5.5 Module Registry Entry
**Represents:** a product module in the catalog. **Key info:** name, version, optional parent (for sub-modules), core/optional flag, default visibility, seven permission-availability flags, description, active status, linked menus. **Relationships:** self-referential (parent/children); linked to menus and to plans (many-to-many). **Retention:** soft-delete. **Privacy:** Internal.

### 5.6 Subscription Plan
**Represents:** a sellable package. **Key info:** code, version (unique pair), name, description, billing cycle, monthly price, yearly price, currency, trial days, active status, bundled modules. **Relationships:** bundles modules (many-to-many); referenced by tenant plans/invoices; belongs to a billing cycle. **Retention:** soft-delete. **Privacy:** Internal (pricing is commercially sensitive).

### 5.7 Dropdown / Lookup Value
**Represents:** a platform-wide configurable list item. **Key info:** key (slug), value/label, data type, sort order, additional metadata, active status. **Relationships:** consumed by many modules (e.g. Complaint severity/priority/status). **Retention:** soft-delete. **Privacy:** Open.

### 5.8 Activity Log Entry
**Represents:** one audited change. **Key info:** affected record (type + id), event, actor (user), captured properties (old/new), IP, user-agent, timestamp. **Relationships:** polymorphic to any record; belongs to a user. **Retention:** append-only; retained for audit. **Privacy:** Confidential (operational audit).

---

## A6 — Workflows

### 6.1 Geographic Cascade Deactivation (Country)
**Trigger:** A user deactivates a country. **End State:** the country and all its descendants are inactive, or nothing changed.
**Steps:** 1. User toggles a country to inactive. 2. System opens a single transaction. 3. System deactivates the country, then all its states, then all their districts, then all their cities. 4. System commits and writes one activity-log entry.
**Exception Paths:** If any step fails, the whole transaction rolls back and the user sees an error; no partial cascade and no success log.
**Notifications:** None to end-users (operational); audit entry recorded.

### 6.2 Set Current Academic Session
**Trigger:** A user marks a session "current". **End State:** exactly one current session.
**Steps:** 1. User sets session X as current. 2. System clears the current flag on every other session. 3. System sets X current (data-layer uniqueness guarantees only one). 4. Audit entry recorded.
**Exception Paths:** If the uniqueness guard would be violated, the change is rejected. The current/active session cannot be archived (blocked earlier).
**Notifications:** None; audit recorded.

### 6.3 Create Plan with Modules
**Trigger:** A user creates/edits a plan. **End State:** plan saved with its bundled modules.
**Steps:** 1. User enters plan details, picks a billing cycle, selects ≥1 module. 2. System validates (≥1 module, currency, trial range). 3. System saves the plan and synchronises its module links (edit replaces the full set). 4. Audit entry recorded.
**Exception Paths:** Zero modules → rejected; invalid billing cycle/currency → rejected.
**Notifications:** None; audit recorded.

### 6.4 Map Menus to a Module
**Trigger:** A user creates/edits a module. **End State:** module saved with its menu links.
**Steps:** 1. User enters module details + selects ≥1 menu. 2. System validates uniqueness (parent+name+version) and sub-module/parent rule. 3. System saves and re-syncs menu links. 4. Audit entry recorded.
**Exception Paths:** Duplicate (parent,name,version) → rejected; sub-module without parent → rejected.
**Notifications:** None; audit recorded.

### 6.5 Bulk-Create Dropdown Values
**Trigger:** A user submits a key with comma-separated values. **End State:** multiple de-duplicated values saved under the key.
**Steps:** 1. User enters a key + comma-separated values + type. 2. System slugifies the key, splits and de-duplicates values, assigns sort orders. 3. System saves all values. 4. Audit entry recorded.
**Exception Paths:** Empty key/value or invalid type → rejected.
**Notifications:** None; audit recorded.

---

## A7 — Reporting & Analytics Requirements

### 7.1 Platform Activity Log (Audit) Report
**Report ID:** RPT-GLB-001 **Purpose:** show who changed which reference data and when. **Audience:** Super Admin, Platform Manager, Support. **Frequency:** As-needed.
**Contents:** timestamp · actor · event type · affected record type · affected record. **Filters (target):** user, date range, event type, record type. **Export (target):** CSV. **Rules:** read-only; reverse-chronological; append-only (BR-GLB-030/031).

### 7.2 Plan & Module Catalog
**Report ID:** RPT-GLB-002 **Purpose:** list all plans with their bundled modules and pricing for sales/onboarding. **Audience:** Sales, Onboarding, Super Admin. **Frequency:** As-needed.
**Contents:** plan code/name · billing cycle · monthly/yearly price · currency · trial days · bundled module list · active status. **Filters:** active status, billing cycle. **Export:** PDF/Excel. **Rules:** plan-view permission required.

### 7.3 Geographic Reference Listing
**Report ID:** RPT-GLB-003 **Purpose:** export the country→state→district→city hierarchy for reference. **Audience:** Support. **Frequency:** As-needed.
**Contents:** country · state · district · city · active flags. **Filters:** by country/state, active only. **Export:** Excel/CSV. **Rules:** geography-view permission.

---

## A8 — Future Enhancement Log
| Enhancement ID | Requested Feature | Business Value | Priority | Status |
|----------------|------------------|----------------|----------|--------|
| ENH-GLB-001 | Bulk CSV import for countries/states/districts/cities/boards/languages | Faster seeding of new geographies | P2 | Backlog |
| ENH-GLB-002 | Translation management dashboard | Regional-language reference content | P2 | Backlog |
| ENH-GLB-003 | Geographic hierarchy tree/map visualisation | Easier support navigation | P3 | Backlog |
| ENH-GLB-004 | Module dependency graph | Clearer plan configuration | P3 | Backlog |
| ENH-GLB-005 | Plan comparison matrix | Sales enablement | P2 | Backlog |
| ENH-GLB-006 | Automated academic-session rollover | Removes a manual yearly step | P2 | Backlog |
| ENH-GLB-007 | API usage / rate-limit dashboard | Detect abuse of reference APIs | P3 | Backlog |
| ENH-GLB-008 | Reference-data caching (countries/states/sessions/modules/plans/boards) | Reduced DB load for tenant forms | P2 | Backlog |

---

## A9 — Non-Functional Requirements

### 9.1 Performance
| Requirement | Standard |
|-------------|----------|
| Reference list load | Geography/board/language/module/plan lists load within 3s; lists are paginated, never loading the whole table. |
| Dependent dropdown lookup | "States by country" (and similar) respond within ~200ms. |
| Dropdown list | Listing dropdown values must not run one query per key (no N+1). |
| Caching | Static reference data (countries, states, current session, modules, plans, boards) should be cached with invalidation on change (ENH-GLB-008). |

### 9.2 Security (business language)
| Requirement | Rule |
|-------------|------|
| Access control | Every screen and action checks the user's permission first; no zero-auth screens. |
| Least privilege | Permanent removal needs the dedicated "remove" permission; viewing pricing needs the plan-view permission. |
| Safe saves | Only validated fields are saved (BR-GLB-022). |
| Search safety | Search text is sanitised and search endpoints are rate-limited (BR-GLB-023/024). |
| Central isolation | This is central reference data; no school's operational data is mixed in. |
| Audit trail | Every change records who and when; the log is append-only. |

### 9.3 Usability
| Requirement | Standard |
|-------------|----------|
| Consistent lifecycle | Every entity offers the same create/edit/deactivate/archive/restore/remove pattern. |
| Dependent selectors | Geography forms cascade (choose country → states load, etc.). |
| Language | English UI; regional languages a future enhancement. |
| Read-only clarity | The activity log clearly offers no edit/delete affordances. |

---

## A10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Summary
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|----------------|---------|----------|------|-------------------|---------------|-----------|---------------------|------------------|
| REQ-GLB-001 | Country Management | P0 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-002 | State Management | P0 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-003 | District Management | P0 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-004 | City Management | P0 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-005 | Geography Setup Workspace | P1 | DASHBOARD,DATA_ENTRY | No | Yes | No | No | Yes |
| REQ-GLB-006 | Educational Board Mgmt | P0 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-007 | Academic Session Mgmt | P0 | DATA_ENTRY,CONFIGURATION,WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-GLB-008 | Language Management | P1 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-009 | Module Registry Mgmt | P0 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-010 | Subscription Plan Mgmt | P0 | DATA_ENTRY,CONFIGURATION,INTEGRATION | Yes | Yes | No | No | Yes |
| REQ-GLB-011 | Dropdown/Lookup Mgmt | P0 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-012 | Activity Log Viewer | P1 | REPORT,DASHBOARD | Yes | Yes | No | No | Yes |
| REQ-GLB-013 | Session-Board Hub | P1 | DASHBOARD | No | Yes | No | No | No |
| REQ-GLB-014 | Translation Management | P2 | DATA_ENTRY,CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-GLB-015 | Reference Data API | P1 | INTEGRATION,REPORT | No | No | No | No | Yes |

### 10.2 Business Rules Coverage Summary
| Rule ID | Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|---------|-------------|---------------------|---------------------|---------------|
| BR-GLB-001 | Country deactivation cascades to cities | REQ-GLB-001 | No | Yes | Yes |
| BR-GLB-002 | No reactivation while parent inactive | 001-004,015 | Yes | Yes | Yes |
| BR-GLB-003 | No remove while children exist | 001-004,006 | Yes | Yes | Yes |
| BR-GLB-004 | Name unique within parent | 002,003 | Yes | Yes | No |
| BR-GLB-005 | Log only after success | 001-004,007,012 | No | No | Yes |
| BR-GLB-006 | Soft-delete lifecycle (deactivate→archive→remove-from-trash) | 001-004,006,008-011 | No | No | Yes |
| BR-GLB-007 | One current session | 007,013,015 | Yes | Yes | Yes |
| BR-GLB-008 | Setting current clears others | 007 | No | Yes | Yes |
| BR-GLB-009 | Current session not removable | 007 | Yes | Yes | Yes |
| BR-GLB-010 | Start before end date | 007 | Yes | No | No |
| BR-GLB-011 | Plan ≥1 module, core auto-included | 009,010 | Yes | Yes | Yes |
| BR-GLB-012 | Sub-module needs parent | 009 | Yes | Yes | No |
| BR-GLB-013 | Standard boards seeded | 006,013 | No | No | No |
| BR-GLB-014 | Affiliated board not removable | 006 | Yes | Yes | Yes |
| BR-GLB-015 | Currency ISO, trial 1–30 | 010 | Yes | No | No |
| BR-GLB-016 | Language direction LTR/RTL | 008 | Yes | No | No |
| BR-GLB-017 | Module unique (parent,name,version) | 009 | Yes | Yes | No |
| BR-GLB-018 | Permission-availability flags | 009 | No | No | No |
| BR-GLB-019 | Session record type must exist | 007 | Yes | Yes | Yes |
| BR-GLB-020 | Language create/edit needs permission | 008 | No | No | Yes |
| BR-GLB-021 | Remove uses remove permission | 003,008 | No | No | Yes |
| BR-GLB-022 | Save only validated fields | 001-004,007,009,010 | Yes | No | Yes |
| BR-GLB-023 | Sanitise search text | 005 | Yes | No | Yes |
| BR-GLB-024 | Rate-limit search/lookup | 005,015 | No | No | Yes |
| BR-GLB-025 | Billing cycle from list | 010 | Yes | Yes | No |
| BR-GLB-026 | Slugify dropdown key | 011 | No | No | Yes |
| BR-GLB-027 | Comma values de-duplicated | 011 | Yes | No | Yes |
| BR-GLB-028 | Maintain sort order in key | 011 | No | No | Yes |
| BR-GLB-029 | Dropdown type in allowed set | 011 | Yes | No | No |
| BR-GLB-030 | Log append-only in UI | 012 | No | No | Yes |
| BR-GLB-031 | Log captures actor/event/record/time | 012 | No | No | Yes |
| BR-GLB-032 | Translation = record+field+language+value | 014 | Yes | No | No |
| BR-GLB-033 | One translation per field/language/record | 014 | Yes | Yes | No |
| BR-GLB-034 | Language delete removes translations | 014 | No | Yes | Yes |

### 10.3 Report Coverage Summary
| Report ID | Report Name | Priority | Filters Count | Export Needed |
|-----------|-------------|----------|---------------|---------------|
| RPT-GLB-001 | Platform Activity Log (Audit) | P1 | 4 | Yes |
| RPT-GLB-002 | Plan & Module Catalog | P1 | 2 | Yes |
| RPT-GLB-003 | Geographic Reference Listing | P2 | 2 | Yes |

### 10.4 Total Scope Numbers
| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 15 |
| Total Business Rules (BR-) | 34 |
| Total Workflows defined | 5 |
| Total Reports required | 3 |
| Total Enhancements logged | 8 |
| Total P0 (Core) Requirements | 9 (REQ-001,002,003,004,006,007,009,010,011) |
| Total P1 (Standard) Requirements | 5 (REQ-005,008,012,013,015) |
| Total P2 (Enhanced) Requirements | 1 (REQ-014) |

---

# Section B — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | Test ref | Code Status (BA view) |
|--------|---------|---------|-----------|----------|-----------|----------|------------------------|
| REQ-GLB-001 | Country | BR-001,002,003,005,022 | country/index,create,edit,trash,show | WF6.1 | RPT-003 | US-GLB-001 | PARTIAL — `$request->all()`, cascade omits cities |
| REQ-GLB-002 | State | BR-002,003,004,005,022 | state/index,create,edit,trash,show | — | RPT-003 | US-GLB-002 | PARTIAL — `$request->all()`, dup log, verify getStatesByCountry |
| REQ-GLB-003 | District | BR-002,003,021 | district/index,create,edit,trash,show | — | RPT-003 | US-GLB-003 | PARTIAL — forceDelete uses wrong permission |
| REQ-GLB-004 | City | BR-002,003,022 | city/index,create,edit,trash,show | — | RPT-003 | US-GLB-004 | PARTIAL — `$request->all()`, no parent check, raw findOrFail |
| REQ-GLB-005 | Geography Workspace | BR-023,024 | location-management/index | — | — | US-GLB-005 | PARTIAL — hub works; CRUD stubs unauthed, unbounded, search risk |
| REQ-GLB-006 | Board | BR-013,014,003 | board/index,create,edit,trash | WF6.4(n/a) | RPT-002(n/a) | US-GLB-006 | PARTIAL — board CRUD via Prime controller; dedicated trash routes missing |
| REQ-GLB-007 | Academic Session | BR-007,008,009,010,019 | academic-session/index,create,edit,trash | WF6.2 | — | US-GLB-007 | BROKEN — missing AcademicSession model (runtime 500); inverted destroy guard; missing date validation |
| REQ-GLB-008 | Language | BR-016,020,021,022 | language/index,create,edit,trash,show | — | — | US-GLB-008 | PARTIAL — 4 unauthed methods, wrong model import, wrong log event |
| REQ-GLB-009 | Module Registry | BR-011,012,017,018,022 | module/index,create,edit,trash,show | WF6.4 | RPT-002 | US-GLB-009 | PARTIAL — `$request->all()`, wrong show perm/view, dup log, is_sub_module type |
| REQ-GLB-010 | Plan | BR-011,015,022,025 | plan/index,create,edit,trash,show | WF6.3 | RPT-002 | US-GLB-010 | PARTIAL — `$request->all()`, planDetails unauthed, show stub, no quarterly price |
| REQ-GLB-011 | Dropdown | BR-026,027,028,029 | dropdown/index,create,edit,trash | WF6.5 | — | US-GLB-011 | PARTIAL — N+1, key/type/org_id unvalidated, org_id semantics |
| REQ-GLB-012 | Activity Log | BR-005,030,031 | activity-log/index | — | RPT-001 | US-GLB-012 | PARTIAL — list works; filters/export pending; stub CRUD methods |
| REQ-GLB-013 | Session-Board Hub | BR-007,013 | session-board-setup/index | — | — | — | PARTIAL — hub works; CRUD stubs unauthed |
| REQ-GLB-014 | Translation | BR-032,033,034 | (none) | — | — | — | NOT STARTED — no model/controller/views |
| REQ-GLB-015 | Reference API | BR-002,007,024 | (none) | — | RPT(n/a) | — | NOT STARTED — empty placeholder only |

> RTM reconciles to FRD §10.4: 15 REQ / 34 BR / 3 RPT.

---

# Section C — Requirement Conditions Catalog + Validation & Edge-Case Catalog
*(Reuses BR- IDs; canonical copy also belongs in `5-Requirement_Conditions/GlobalMaster_Conditions.md`.)*

### C.1 Conditions Catalog
| Condition (=BR-) | Entity/Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|------------------|--------------|----------------------|------|---------|------------------------|
| BR-GLB-002 | child active flag | parent must be active to reactivate child | Validation | toggle status | block + message |
| BR-GLB-003 | any parent record | no children may exist to remove | Validation | force remove | block + friendly message |
| BR-GLB-004 | state/district name | unique within parent | Validation | create/edit | reject + message |
| BR-GLB-007 | session current flag | only one current | Concurrency | set current | data-layer rejects 2nd |
| BR-GLB-009 | session active | current session not removable | Validation | archive/remove | block |
| BR-GLB-010 | session dates | start < end | Validation | create/edit | reject |
| BR-GLB-011 | plan modules | ≥1, core auto | Validation | create/edit | reject |
| BR-GLB-012 | module parent | sub-module needs parent | Validation | create/edit | reject |
| BR-GLB-015 | plan currency/trial | ISO-3, trial 1–30 | Validation | create/edit | reject |
| BR-GLB-016 | language direction | LTR/RTL only | Validation | create/edit | reject |
| BR-GLB-020 | language access | permission required | Permission | create/edit | 403 |
| BR-GLB-022 | all saves | validated-only fields | Validation/Security | save | drop unknown fields |
| BR-GLB-029 | dropdown type | allowed set only | Validation | create | reject |
| BR-GLB-033 | translation key | one per field/language/record | Validation | create | reject duplicate |

### C.2 Validation & Edge-Case Catalog (selected)
| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency | Expected |
|------------|-------|---------|----------|------------|-------------|----------|
| Country name | "India" | "India" again | 50 chars | blank | two creates same name | reject duplicate/blank |
| State (country,name) | (India, Goa) | (India, Goa) dup | — | missing country | — | reject |
| Session current | mark 2025-26 | — | — | — | two users mark different sessions current | data layer keeps one |
| Session dates | 01-Apr→31-Mar | end before start | same day | missing date | — | reject |
| Plan modules | 2 modules | 0 modules | exactly 1 | none selected | — | reject if 0 |
| Dropdown bulk values | "a,b,c" | "a,a,b" | 1 value | empty string | — | de-dup to a,b,c |
| Language direction | RTL | "diagonal" | — | blank | — | reject |
| Force remove country | no states | has states | — | — | concurrent child create | block + message |

---

# Section D — Process Flows + State Machine (FSM) Catalog

### D.1 Process Flows
See FRD §A6 (WF6.1 geographic cascade; WF6.2 set-current session; WF6.3 plan+modules; WF6.4 module+menus; WF6.5 dropdown bulk-create). Each has its exception path defined; none triggers end-user notifications (operational module) but all write the audit trail.

### D.2 FSM Catalog
**Entity: Reference Record (Country/State/District/City/Board/Language/Module/Plan/Dropdown)** — generic lifecycle:
| From | Event | Guard | To | Side-Effects |
|------|-------|-------|----|--------------|
| (new) | Create | unique + parent valid | Active | audit |
| Active | Deactivate | (country) cascade descendants | Inactive | cascade + audit |
| Inactive | Reactivate | parent active (BR-002) | Active | audit |
| Active/Inactive | Archive | — | Trashed | deactivate-then-soft-delete + audit |
| Trashed | Restore | — | Inactive/Active | audit |
| Trashed | Remove | no children (BR-003), remove permission (BR-021) | (deleted) | audit |
Illegal: Active→Removed directly (must archive first); Reactivate while parent inactive.

**Entity: Academic Session** — adds:
| From | Event | Guard | To | Side-Effects |
|------|-------|-------|----|--------------|
| Not-current | Set Current | single-current (BR-007) | Current | clears others' current flag |
| Current | Archive/Remove | blocked (BR-009) | — | rejected |

---

# Section E — Data Dictionary (business + technical view)
*(Technical register — table/column names exposed intentionally. Schema truth = live migrations, three-way reconciled with models and `global_db_v4.sql`.)*

### E.1 Connection / placement model
- **`global_master_mysql` → `global_db`** physically holds: `glb_countries, glb_states, glb_districts, glb_cities, glb_boards, glb_menus, glb_academic_sessions, glb_modules, glb_languages, glb_translations, glb_menu_module_jnt`. Each is mirrored as a **`CREATE OR REPLACE VIEW`** of the same name in `prime_db` so default-connection code/FKs can read it.
- **default `mysql` → `prime_db`** holds: `media`, `prm_plans`, `glb_module_plan_jnt`, `activity_logs`.
- **Consumed but owned elsewhere:** `sys_dropdowns`, `sys_dropdown_needs`, `sys_dropdown_need_table_jnt`, `sys_activity_logs` (central/SystemConfig); `sch_organizations`, `sch_board_organization_jnt`, `organization_academic_sessions` (tenant/SchoolSetup-adjacent — the last two are defined inside the GLB module, a boundary anomaly).

### E.2 Selected column maps (business field → table.column)
| Business Field | Table.Column | Notes |
|----------------|--------------|-------|
| Country name / short code | `glb_countries.name` (VARCHAR50 UNIQUE) / `.short_name` (VARCHAR10 UNIQUE) | UNSIGNED INT PK |
| Currency code | `glb_countries.currency_code` (VARCHAR8 NULL) | |
| State→Country link | `glb_states.country_id` → `glb_countries.id` RESTRICT | UNIQUE (country_id,name) |
| City time-zone | `glb_cities.default_timezone` (VARCHAR64 NULL) | |
| Session current | `glb_academic_sessions.is_current` + generated `current_flag` BIGINT + UNIQUE `uq_acadSessions_currentFlag` | enforces single-current; **no `is_active` column** (DBM-003) |
| Module permission flags | `glb_modules.available_perm_{view,add,edit,delete,export,import,print}` (BOOL ×7) | |
| Module↔Menu | `glb_menu_module_jnt(menu_id,module_id,sort_order)` | ⚠ DDL master names it `glb_menu_model_jnt` (INC-07) |
| Plan price | `prm_plans.price_monthly`, `.price_yearly` (DECIMAL12,2) | ⚠ no `price_quarterly` despite V2 |
| Plan↔Module | `glb_module_plan_jnt(plan_id→prm_plans, module_id→{global_db}.glb_modules, is_active)` | ⚠ V2 calls it `prm_module_plan_jnt` |
| Dropdown value | `sys_dropdowns(key,value,type,ordinal,additional_info,is_active)` | ⚠ V2 calls it `sys_dropdown_table`; model maps `sys_dropdowns` |
| Audit entry | `sys_activity_logs(subject_*,user_id,event,properties,ip_address,user_agent)` | ⚠ a separate `activity_logs` migration exists but the model targets `sys_activity_logs` |

### E.3 Schema anomalies (for DB Architect)
1. `glb_menu_module_jnt` (code/migration) vs `glb_menu_model_jnt` (DDL master) — reconcile name.
2. `glb_academic_sessions` lacks `is_active` (controller references it).
3. `prm_plans` lacks `price_quarterly` (proposed, unbuilt).
4. Dead/duplicate `activity_logs` migration vs `sys_activity_logs` model target.
5. Un-prefixed `organization_academic_sessions` and `sch_board_organization_jnt` defined inside GLB.
6. `glb_languages` already carries timestamps + `deleted_at` (V2 DBM-002 stale/resolved).
7. Connection-property inconsistency across geography models (Country/District unset).

---

# Section F — Cross-Module Dependency Map
*(Technical register.)*

**Outbound (GLB is read by):**
| Target Module | Mechanism | What |
|---------------|-----------|------|
| SchoolSetup | direct FK / `sch_board_organization_jnt` | geography for org addresses; board affiliation |
| StudentProfile | FK `std_*.city_id` → `glb_cities` | student city |
| Prime (onboarding) | FK references | `glb_academic_sessions`, `prm_plans`, `glb_modules` in tenant-creation wizard |
| Billing | `prm_plans` → `prm_tenant_plan_jnt` → invoices | plan pricing/cycle |
| All tenant modules | query by key on `sys_dropdowns` | platform lookup lists (Complaint severity/priority/status, etc.) |
| Auth / menu rendering | `glb_modules`, `glb_menus`, `glb_menu_module_jnt` | permission + menu rendering |
| i18n-aware modules (future) | `glb_translations` + `glb_languages` | polymorphic translation lookup |
| All modules | `activityLog()` helper → `sys_activity_logs` (imports GLB `ActivityLog`) | audit write (hard coupling) |

**Inbound (GLB reads):** `sys_users` (audit actor, creator), `prm_billing_cycles` (plan cycle), `sch_organizations` (board/session junctions).

**Key coupling risk:** `app/Helpers/activityLog.php` imports `Modules\GlobalMaster\Models\ActivityLog`; the whole platform's auditing depends on this class staying present and stable.

---

# Section G — NFR Catalog + Risk Register

### G.1 NFR Catalog
| NFR-ID | Category | Requirement (measurable) | Threshold |
|--------|----------|--------------------------|-----------|
| NFR-GLB-001 | Performance | Reference lists paginated, never full-table load | All list screens |
| NFR-GLB-002 | Performance | Dependent-dropdown lookup responds fast | ~200ms |
| NFR-GLB-003 | Performance | No N+1 in dropdown listing | 0 per-key queries |
| NFR-GLB-004 | Performance | Cache static reference data with invalidation | 1-hour TTL (ENH-GLB-008) |
| NFR-GLB-005 | Security | Every controller method authorises before logic | 100% methods |
| NFR-GLB-006 | Security | Saves use validated data only | 0 accept-all saves |
| NFR-GLB-007 | Security | Search sanitised + rate-limited | throttle 60/min |
| NFR-GLB-008 | Integrity | All FKs RESTRICT; cascades transactional | no orphans |
| NFR-GLB-009 | Integrity | Single-current session at data layer | DB-enforced |
| NFR-GLB-010 | Auditability | All changes logged after success; append-only | 100% mutations |
| NFR-GLB-011 | Architecture | Reusable logic in services; routes in module | target state |

### G.2 Risk Register
| Risk ID | Risk | Cat | Likelihood | Impact | Mitigation | Owner |
|---------|------|-----|------------|--------|------------|-------|
| RISK-GLB-001 | Academic-session screens crash (missing model) | Defect | H | H | Create/repair the session record type | Backend |
| RISK-GLB-002 | Mass-assignment via accept-all saves | Security | M | H | Switch all saves to validated-only | Backend |
| RISK-GLB-003 | Unauthorised language create/edit | Security | M | M | Add permission checks | Backend |
| RISK-GLB-004 | Active session deletable (inverted guard) | Data integrity | M | H | Fix guard condition | Backend |
| RISK-GLB-005 | Country deactivation leaves active cities | Data integrity | M | M | Extend cascade to cities | Backend |
| RISK-GLB-006 | Zero-auth stub controllers exposed | Security | M | M | Secure or remove stubs | Backend |
| RISK-GLB-007 | Schema name drift (`glb_menu_module/model_jnt`) | Integrity | M | M | Reconcile DDL/code | DB Architect |
| RISK-GLB-008 | Audit coupling (whole platform depends on GLB ActivityLog) | Architecture | L | H | Keep model stable; consider interface | Architect |

---

# Section H — Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks

### H.1 MoSCoW
- **Must (P0):** REQ-001,002,003,004,006,007,009,010,011 — plus the defect-class fixes (missing session model, validated-only saves, language auth, inverted guard, cascade-to-cities).
- **Should (P1):** REQ-005,008,012,013,015; service layer; route consolidation; caching.
- **Could (P2):** REQ-014 (Translations); dropdown validation hardening; billing-cycle-from-list; quarterly price.
- **Won't (this release):** ENH-003/004/007 (visualisations, dependency graph, API dashboard).

### H.2 Sprint Tasks
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|------------|------------|--------|
| 1 | Create/repair AcademicSession record type so its screens load | Backend | 2 | — | 1 |
| 2 | Replace accept-all saves with validated-only (6 controllers) | Backend | 1 | — | 1 |
| 3 | Add permission checks to Language create/edit; fix model import | Backend | 2 | — | 1 |
| 4 | Fix inverted active-session delete guard + add date validation | Backend | 1.5 | 1 | 1 |
| 5 | Extend country deactivation cascade to cities (transactional) | Backend | 1.5 | — | 1 |
| 6 | Secure/remove zero-auth stub controllers + planDetails check | Backend | 2 | — | 1 |
| 7 | Fix forceDelete permission + duplicate audit-log calls | Backend | 1 | — | 2 |
| 8 | Reconcile menu-junction table name; add session is_active | Schema | 2 | — | 2 |
| 9 | Dropdown: validate key/type, fix N+1, fix org scoping | Backend | 3 | — | 2 |
| 10 | Extract GeographyService / ModulePlanService / DropdownService | Backend | 4 | — | 3 |
| 11 | Consolidate routes into module web.php | Backend | 2 | — | 3 |
| 12 | Reference-data caching with invalidation | Backend | 2 | 10 | 3 |
| 13 | Translation record type + screens (REQ-014) | Full-stack | 8 | — | 4 |
| 14 | Reference-data read API (REQ-015) | API | 6 | — | 4 |
| 15 | Test suite (feature + unit + request) | Testing | 16 | 1-9 | 2-4 |

> Estimation basis: gauged against similarly-sized central modules; assumes DDL exists (+time if migrations needed for schema anomalies). Roughly matches V2's ~40h estimate to reach ~90%.

---

# Section I — User Stories (Gherkin) + Reporting & KPI Spec

### I.1 User Stories (one per P0/P1 REQ)
**US-GLB-001 (REQ-GLB-001, P0)** — As a Platform Manager, I want to deactivate a country and have its states, districts and cities deactivate too, so reference data stays consistent.
- Given an active country with descendants, When I deactivate it, Then all descendants become inactive in one transaction and one audit entry is written.
- Given a country with states, When I try to permanently remove it, Then removal is blocked with a friendly message.
- Given a user without the remove permission, When they attempt removal, Then access is refused.

**US-GLB-002 (REQ-GLB-002, P0)** — As a Manager, I want states scoped to a country so dependent dropdowns work.
- Given a country, When I request its states, Then only that country's states return.
- Given an inactive parent country, When I reactivate a state, Then it is blocked.

**US-GLB-003 (REQ-GLB-003, P0)** — As a Manager, I want districts unique within their state.
- Given a state with district "X", When I add another "X" to it, Then it is rejected.

**US-GLB-004 (REQ-GLB-004, P0)** — As a Manager, I want cities under districts with a time-zone.
- Given a district, When I add a city with a time-zone, Then it saves; When I reactivate it under an inactive district, Then it is blocked.

**US-GLB-005 (REQ-GLB-005, P1)** — As Support, I want one workspace to browse all geography.
- Given the workspace, When I search in the City tab, Then only cities filter and only the City tab pages.

**US-GLB-006 (REQ-GLB-006, P0)** — As a Manager, I want to maintain educational boards.
- Given board "CBSE" exists, When I add "CBSE" again, Then it is rejected; When the board is affiliated to a school, Then it cannot be removed.

**US-GLB-007 (REQ-GLB-007, P0)** — As a Manager, I want exactly one current academic session.
- Given session A is current, When I set B current, Then A is no longer current and only B is.
- Given the current session, When I try to archive it, Then it is blocked.
- Given a session form, When start date is after end date, Then it is rejected.

**US-GLB-008 (REQ-GLB-008, P1)** — As a Super Admin, I want only authorised users to manage languages.
- Given a user without the language-create permission, When they open the create screen, Then access is refused.
- Given a new RTL language, When I save it, Then its direction is stored as right-to-left.

**US-GLB-009 (REQ-GLB-009, P0)** — As a Super Admin, I want a module registry with menu links.
- Given a module form, When I save with ≥1 menu and a unique (parent,name,version), Then it saves and links the menus.
- Given a sub-module without a parent, When I save, Then it is rejected.

**US-GLB-010 (REQ-GLB-010, P0)** — As a Super Admin, I want plans that bundle modules.
- Given a plan form, When I select 0 modules, Then it is rejected; When I view plan details, Then only a plan-view user can see pricing.

**US-GLB-011 (REQ-GLB-011, P0)** — As a Super Admin, I want to bulk-create dropdown values.
- Given key "severity" and "low,medium,high,low", When I save, Then values low/medium/high are created (de-duplicated) under a slugified key.

**US-GLB-012 (REQ-GLB-012, P1)** — As Support, I want a read-only audit trail.
- Given the activity log, When I open it, Then entries list newest-first and no edit/delete action is shown.

**US-GLB-015 (REQ-GLB-015, P1)** — As a school app, I want to fetch the current academic session in one call.
- Given a valid token, When I call for the current session, Then exactly one current session returns in the standard envelope.

### I.2 KPI / Metrics
| KPI | Definition (business) | Source | Target | Cadence |
|-----|-----------------------|--------|--------|---------|
| Reference data completeness | % of expected countries/states/districts/cities/boards seeded | geography tables | 100% for India | One-off + on expansion |
| Plan catalog freshness | # active plans with ≥1 module | plans + junction | all plans valid | Monthly |
| Audit coverage | % of reference mutations with a matching log entry | activity log | 100% | Continuous |
| Dropdown reuse | # modules consuming each key | dropdown usage | n/a (monitor) | Quarterly |

---

# Section J — Feature Specification (screen-by-screen, condensed)

All entity screens follow a uniform pattern: **index** (paginated list + search + status toggle + row actions), **create**, **edit**, **trash** (archived list + restore + permanent remove), and (for some) **show**. Standard actions: Create / Edit / Deactivate-Reactivate / Archive / Restore / Remove. Filters: by active status and name search. Empty state: "No records yet" with a Create call-to-action. Permissions: `prime.{entity}.{action}`.

| Screen group | Views present | Distinctive fields/actions |
|--------------|---------------|----------------------------|
| Country | index, create, edit, trash, show | name, short code, intl code, currency, status; cascade on deactivate |
| State | index, create, edit, trash, show | parent country selector; states-by-country lookup |
| District | index, create, edit, trash, show | parent state selector; grouped list |
| City | index, create, edit, trash, show | parent district selector; default time-zone |
| Geography Workspace | location-management/index | 4 tabs; per-tab search + paging; type-ahead |
| Board | index, create, edit, trash | name, short code; shown in Session-Board hub |
| Academic Session | index, create, edit, trash | start/end dates, "current" toggle (single-current) |
| Language | index, create, edit, trash, show | ISO code, native name, direction LTR/RTL |
| Module | index, create, edit, trash, show | version, core flag, 7 permission flags, menu multi-select, parent (sub-module) |
| Plan | index, create, edit, trash, show | code, billing cycle, prices, currency, trial, module multi-select; details modal |
| Dropdown | index, create, edit, trash | key, comma-separated values, type, sort order |
| Activity Log | index | read-only list; (target) filters + export |
| Session-Board Hub | session-board-setup/index | sessions + boards side-by-side |

Acceptance criteria per screen = the relevant REQ acceptance criteria in §A3.

---

# Section K — Module Knowledge Update Note
This pack was produced alongside a freshly seeded module-knowledge file:
`AI_Brain/module-knowledge/GLB_GlobalMaster.md` (seeded 2026-06-29 from live code + V2, all counts filesystem-verified, stale V2 claims corrected). The FRD IDs above (`REQ-/BR-/RPT-/ENH-`) are the canonical contract for the downstream DDL gap, code gap, business-rule enforcement, completion-scoring and test-coverage analyses.

---

## Document Control
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-29 | Initial FRD + Complete Analysis Pack from live-code + V2 synthesis. | Business Analysis — Prime-AI |

*This is the single source of truth for GlobalMaster requirements. All gap analyses, completion scoring, and test coverage must reference this document. Technical implementation details live in the live migrations/models and `global_db_v4.sql`.*
