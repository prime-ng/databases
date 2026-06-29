# Dashboard (DSH) — Complete Analysis Pack | 2026-06-29
**Module:** Dashboard | **Code:** DSH | **Prefix:** `dsh_` (none exist — schema-less module)
**Sources read:** Live code tree `Modules/Dashboard/` (26 controllers, 85 views, 25 routes); cross-referenced DDL `0-DDL_Masters/tenant_db_v4.sql` for source-table existence. No V2/V1 requirement docs exist for this module — this FRD is **evidence-grounded from code only**; inferred items marked `[inferred]`.
**Register:** Business language in narrative sections (1–9); technical register confined to the Data Dictionary technical view, Dependency Map, and code-status columns.

> **Single source of truth.** This file assigns the canonical `REQ-/BR-/RPT-/ENH-` IDs that the downstream audit, RTM, and gap analyses reuse. Do not renumber.

---

## Section 0 — Index

1. Module Overview
2. User Roles & Access
3. Functional Requirements (REQ-DSH-001…012)
4. Business Rules Register (BR-DSH-001…024)
5. Data Requirements & Data Dictionary (incl. technical view)
6. Workflows
7. Reporting & Analytics (RPT-DSH-001…011)
8. Future Enhancement Log (ENH-DSH-001…008)
9. Non-Functional Requirements (NFR-DSH)
10. Gap Analysis Readiness Index (coverage contract)
11. Requirements Traceability Matrix (RTM)
12. Requirement Conditions Catalog
13. Validation & Edge-Case Catalog
14. State / Routing Model
15. Cross-Module Dependency Map
16. Risk Register
17. Prioritization (MoSCoW)
18. Effort Estimation & Sprint Tasks
19. User Stories (Gherkin)
20. KPI Catalog

---

## Section 1 — Module Overview

### 1.1 Purpose
The Dashboard provides every staff member with a single, role-appropriate landing screen that summarises the school's current state — student and staff headcounts, fee collection, academic activity, operations, and alerts — drawn together from across the entire platform. It is a **read-only overview**: it shows numbers and trends and links out to the modules where work is actually done; it never creates, edits, or deletes any record itself.

### 1.2 Business Value
- Gives a Principal or Administrator a 30-second situational picture without opening a dozen modules.
- Routes each role to a view scoped to what they need (a Teacher sees their classes; an Accountant sees collections; a Platform Operator sees tenant health).
- Acts as the navigation hub — module cards link to every functional area of the school system.

### 1.3 Scope

**In scope**
- A main School Admin landing dashboard with headline counts, charts, and module navigation cards.
- Fifteen functional-area "hub" dashboards (Core Configuration, Foundational Setup, Admission & Student, School Setup, Operations, Support, Communication, Staff, Finance, LMS, Academics, Exams & Assessment, Timetable, Front Desk, Portal).
- Three Foundational-Setup detail pages (School Profile, Session & Board, Billing).
- Eight role-specific dashboards (Principal, Teacher, Accounts, Inventory, Transport, Library, Management, Platform Operator).
- A consolidated notifications view.
- Automatic redirect of Students and Parents to their own portal.

**Out of scope**
- Any data entry, editing, approval, or deletion (all delegated to source modules).
- Persisting dashboard state, user-customised layouts, or saved filters (no dashboard tables exist).
- Real-time/push updates — all figures are computed on page load.
- Cross-school (cross-tenant) comparison for school users (each school sees only its own data).
- Scheduled export or emailing of dashboard snapshots.

### 1.4 Terminology
- **Hub dashboard** — a functional-area overview screen grouping related KPI tiles for one domain (e.g. Finance).
- **Role dashboard** — a screen gated to a single role (e.g. Principal) presenting that role's priorities.
- **KPI tile** — a single headline number (e.g. "Total Students: 1,240").
- **Aggregation** — a count or sum computed across a source module's records at render time.
- **Resilient read** — a source query that returns zero instead of failing if the underlying table is unavailable.
- **Platform Operator (Super Admin)** — the SaaS-level operator who monitors tenants, billing, and system health (not a school user).

---

## Section 2 — User Roles & Access

### 2.1 Actors
| Actor | Description |
|-------|-------------|
| School Administrator | Sees the main landing dashboard and all functional-area hubs. |
| Principal | Sees the Principal role dashboard (school-wide overview). |
| Teacher | Sees the Teacher role dashboard (own classes, schedule, students). |
| Accountant | Sees the Accounts role dashboard (collections, dues). |
| Transport Manager | Sees the Transport role dashboard (fleet, routes, fees). |
| Librarian | Sees the Library role dashboard (catalog, circulation, fines). |
| Management | Sees the Management role dashboard (cross-area summary). |
| Platform Operator (Super Admin) | Sees the platform-health dashboard (tenants, billing, system, security). |
| Student / Parent | Not served here — redirected to the Student Portal. |

### 2.2 Role–Feature Matrix
| Feature | School Admin | Principal | Teacher | Accountant | Transport | Librarian | Management | Platform Operator |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Main landing dashboard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| Functional-area hubs (15) | ✓ | ✓* | ✓* | ✓* | ✓* | ✓* | ✓* | — |
| Principal dashboard | — | ✓ | — | — | — | — | — | — |
| Teacher dashboard | — | — | ✓ | — | — | — | — | — |
| Accounts dashboard | — | — | — | ✓ | — | — | — | — |
| Transport dashboard | — | — | — | — | ✓ | — | — | — |
| Library dashboard | — | — | — | — | — | ✓ | — | — |
| Management dashboard | — | — | — | — | — | — | ✓ | — |
| Platform-health dashboard | — | — | — | — | — | — | — | ✓ |
| Consolidated notifications | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — |

\* Area hubs are gated by a single platform permission ("view dashboards"), so any holder of that permission can open them. **Anomaly:** that permission is not currently created by any seeder (see Section 16, RISK-DSH-001).

---

## Section 3 — Functional Requirements

### REQ-DSH-001 — Main School Admin Landing Dashboard
- **Priority:** Core (P0) · **Tags:** [DASHBOARD][REPORT]
- **Description:** On opening the application, a staff member sees a landing dashboard with headline counts (students, teachers, staff, users, classes, sections, subjects, rooms, timetable activities, complaints, notifications, admissions, progress cards, and live LMS exam/quiz/quest/homework counts plus pending evaluations and open grievances), a students-per-class bar chart, a staff and infrastructure breakdown, and a timetable-readiness progress indicator. Module navigation cards group every functional area.
- **Actors:** Initiates — School Admin; Views — all staff roles.
- **Acceptance Criteria:**
  - Landing page loads showing each headline count as a tile.
  - Students-per-class chart reflects active sections only.
  - Each module card links to the correct module landing route.
  - A Student or Parent who reaches this route is redirected to the Student Portal.

### REQ-DSH-002 — Functional-Area Hub Dashboards (15)
- **Priority:** Core (P0) · **Tags:** [DASHBOARD][REPORT]
- **Description:** Fifteen domain hubs each present read-only KPI tiles and recent-record summaries for their area: Core Configuration, Foundational Setup, Admission & Student, School Setup, Operations, Support, Communication, Staff, Finance, LMS, Academics, Exams & Assessment, Timetable, Front Desk, Portal.
- **Actors:** Views — any holder of the "view dashboards" permission.
- **Acceptance Criteria:**
  - Each hub renders without error even if one or more source areas have no data (tiles show zero).
  - Each tile's number matches the corresponding source-module count for the current school.

### REQ-DSH-003 — Foundational Setup Detail Pages
- **Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT][CONFIGURATION]
- **Description:** From the Foundational Setup hub, three detail pages are available: **School Profile** (organisation details, city, current plan), **Session & Board** (global vs school-linked academic sessions and boards), and **Billing** (current plan, recent invoices, next billing schedule).
- **Actors:** Views — School Admin.
- **Acceptance Criteria:**
  - School Profile shows the school's organisation record and resolved city name.
  - Billing lists recent invoices and the next scheduled bill for the active plan.
  - If the school's subscription context is unavailable, the page still renders with empty sections.

### REQ-DSH-004 — Role-Specific Dashboards
- **Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT][APPROVAL]
- **Description:** Dedicated dashboards for Principal, Teacher, Accountant, Transport Manager, Librarian, and Management present role-prioritised summaries (e.g. Principal: attendance, finance, staff, operations, timetable tabs).
- **Actors:** Views — the matching role only.
- **Acceptance Criteria:**
  - A user without the required role receives an access-refused response (403).
  - Each role dashboard renders its full tab/section set.
  - **Known limitation:** these dashboards currently present representative (placeholder) figures; live data wiring is a tracked follow-up (see ENH-DSH-001).

### REQ-DSH-005 — Platform Health Dashboard (Platform Operator)
- **Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT][INTEGRATION]
- **Description:** The Platform Operator sees system status, tenant inventory, database/migration status, application metrics, error log, billing/MRR, module health, and security (failed logins, sessions, roles). This is a SaaS-operations view, not a school view.
- **Actors:** Views — Platform Operator only.
- **Acceptance Criteria:**
  - Access is refused to any non–Platform-Operator.
  - All eight sections render.
  - **Known limitation:** figures are placeholders pending central-context wiring (see ENH-DSH-002).

### REQ-DSH-006 — Student / Parent Redirect
- **Priority:** Core (P0) · **Tags:** [WORKFLOW]
- **Description:** A Student or Parent who lands on the main dashboard is automatically redirected to the Student Portal dashboard.
- **Actors:** Initiates — System.
- **Acceptance Criteria:**
  - A logged-in Student is redirected to the Student Portal.
  - A logged-in Parent is redirected to the Student Portal.
  - A staff user is not redirected.

### REQ-DSH-007 — Consolidated Notifications View
- **Priority:** Standard (P1) · **Tags:** [DASHBOARD][NOTIFICATION]
- **Description:** A single screen lists all of the user's notifications, reusing the platform notification service.
- **Actors:** Views — all staff roles.
- **Acceptance Criteria:**
  - The view lists notifications relevant to the current user/school.
  - The view renders with an empty state when there are none.

### REQ-DSH-008 — Resilient Read Aggregation
- **Priority:** Core (P0) · **Tags:** [DASHBOARD][INTEGRATION]
- **Description:** Every figure on every dashboard is computed by safely counting or summing source-module records, excluding archived (soft-deleted) records, and degrading gracefully (showing zero) if a source is unavailable — so a single broken source never breaks the whole page.
- **Actors:** Initiates — System.
- **Acceptance Criteria:**
  - A tile whose source table is missing/renamed shows zero, not an error.
  - Archived records are excluded from all counts and sums.

### REQ-DSH-009 — Role & Permission Access Enforcement
- **Priority:** Core (P0) · **Tags:** [CONFIGURATION]
- **Description:** Area hubs require the "view dashboards" permission; role dashboards require the matching role. All dashboards require an authenticated, verified user within an active school tenancy.
- **Actors:** Initiates — System.
- **Acceptance Criteria:**
  - An unauthenticated user cannot reach any dashboard.
  - A user lacking the dashboard permission cannot open the area hubs.
  - A user lacking a role cannot open that role's dashboard.

### REQ-DSH-010 — Timetable Readiness Indicator
- **Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT]
- **Description:** The main dashboard shows a timetable-generation pipeline progress percentage based on how many setup stages (requirement groups, consolidations, teacher availability, activities, slot requirements, generated timetables) have data.
- **Actors:** Views — School Admin.
- **Acceptance Criteria:**
  - The percentage equals completed stages ÷ total stages.
  - When no stage has data, the indicator reads 0%.

### REQ-DSH-011 — Cross-Layer Subscription & Billing Read
- **Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT][INTEGRATION]
- **Description:** The Foundational Setup pages read the school's organisation, plan, and invoice data from the platform (Prime/Billing) and global master layers, in addition to its own tenant data.
- **Actors:** Views — School Admin.
- **Acceptance Criteria:**
  - The active plan and recent invoices for the current school display correctly.
  - If the platform-layer context is unavailable, the page still renders.

### REQ-DSH-012 — Dashboard Data API (Scaffold) `[inferred]`
- **Priority:** Could (P2) · **Tags:** [INTEGRATION]
- **Description:** A versioned API endpoint set for dashboard data is registered for future programmatic/mobile consumption.
- **Actors:** Initiates — external client.
- **Acceptance Criteria:**
  - The API namespace is reachable under authenticated token access.
  - **Known limitation:** only listing is implemented; create/update/delete are not applicable to a read-only module and are not exposed (see ENH-DSH-007).

---

## Section 4 — Business Rules Register

| BR ID | Rule (business statement) | Type | Trigger | Enforcement point |
|-------|---------------------------|------|---------|-------------------|
| BR-DSH-001 | Dashboards are read-only; no dashboard action creates, edits, or deletes any record. | Workflow | Any dashboard load | All controllers (no write paths) |
| BR-DSH-002 | All figures are computed for the current school only; no cross-school data is shown to school users. | Permission | Aggregation | Tenant DB connection |
| BR-DSH-003 | Archived (soft-deleted) records are excluded from every count and sum. | Calculation | Aggregation | Resilient read helper |
| BR-DSH-004 | If a source table is unavailable, the affected figure shows zero rather than failing the page. | Workflow | Aggregation failure | Resilient read helper |
| BR-DSH-005 | A Student or Parent reaching the main dashboard is redirected to the Student Portal. | Workflow | Main dashboard load | Main controller |
| BR-DSH-006 | Area-hub dashboards require the "view dashboards" permission. | Permission | Hub load | Gate authorization |
| BR-DSH-007 | A role dashboard is accessible only to the matching role; others are refused (403). | Permission | Role dashboard load | Role check |
| BR-DSH-008 | All dashboards require an authenticated, email-verified user. | Permission | Any load | Auth + verified middleware |
| BR-DSH-009 | All dashboards require an active school tenancy; central-domain access is prevented. | Permission | Any load | Tenancy middleware |
| BR-DSH-010 | The students-per-class chart counts active sections only. | Calculation | Main dashboard load | Main controller |
| BR-DSH-011 | The "Other Staff" figure is total staff minus teachers, floored at zero. | Calculation | Main dashboard load | Main controller |
| BR-DSH-012 | Timetable readiness % = stages-with-data ÷ total stages, rounded. | Calculation | Main dashboard load | Main controller |
| BR-DSH-013 | "Current session" figures count only the session flagged current. | Calculation | Foundational hub load | Foundational controller |
| BR-DSH-014 | Active-user counts include only users flagged active. | Calculation | Foundational hub load | Foundational controller |
| BR-DSH-015 | Recent-record lists are capped (e.g. latest 5 sessions, latest 8 invoices) and ordered newest-first. | Validation | Detail page load | Foundational controller |
| BR-DSH-016 | City name on the School Profile is resolved from the global master layer by the school's city reference. | Calculation | School Profile load | Foundational controller |
| BR-DSH-017 | Billing reads use the current school's subscription identity; if it cannot be resolved, billing sections render empty. | Workflow | Billing page load | Foundational controller |
| BR-DSH-018 | The active plan is the school's subscribed, non-cancelled plan. | Validation | Billing/profile load | Foundational controller |
| BR-DSH-019 | The "next bill" is the earliest future, ungenerated, active billing schedule for the active plan. | Calculation | Billing page load | Foundational controller |
| BR-DSH-020 | Active LMS exam/quiz/quest/homework counts include only items flagged active. | Calculation | Main dashboard load | Main controller |
| BR-DSH-021 | Pending-evaluation and open-grievance counts reflect only the corresponding open statuses. | Calculation | Main dashboard load | Main controller |
| BR-DSH-022 | The consolidated notifications view shows only the current user's notifications. | Permission | Notifications load | Notification service |
| BR-DSH-023 | Module navigation cards link only to routes the platform exposes; a card must not point to a non-existent route. | Validation | Main dashboard render | Main controller card config |
| BR-DSH-024 | Dashboard figures are point-in-time at page load; no caching or real-time refresh is guaranteed. | Workflow | Any load | All controllers |

---

## Section 5 — Data Requirements & Data Dictionary

### 5.1 Business View
The Dashboard **stores no data of its own**. It presents borrowed figures. The "entities" below are the *business concepts surfaced*, each sourced from another module.

| Business concept surfaced | Meaning | Source area | Privacy |
|---------------------------|---------|-------------|---------|
| Student headcount | Count of enrolled students | Student records | Internal |
| Staff headcount | Teachers + other employees | School setup / HR | Internal |
| Academic infrastructure | Classes, sections, subjects, rooms | School setup | Public (within school) |
| Fee position | Collected, outstanding, defaulters | Fees / Accounting | Confidential |
| Academic activity | Exams, quizzes, quests, homework, grievances | LMS | Internal |
| Progress cards | Published vs total holistic progress cards | HPC | Confidential |
| Operations | Transport, complaints, notifications, front-office | Multiple ops modules | Internal |
| Subscription & billing | Plan, invoices, next bill | Platform/Billing layer | Confidential |
| Platform health | Tenants, system, errors, security | Platform layer | Sensitive (operator-only) |

### 5.2 Technical View (technical register)
- **Owned tables:** none. No `dsh_*` tables exist (confirmed against `tenant_db_v4.sql`). No migrations, no models.
- **Read connections:** default tenant connection for `sch_/std_/tt_/lms_/fin_/...`; `global_master_mysql` for `glb_*`; `mysql` (prime) for `prm_*`/`bil_*`.
- **Read pattern:** `BaseDashboardController::safeCount(table, where[])` and `safeSum(table, column, where[])` — try/catch guarded, auto-append `whereNull('deleted_at')` when the column exists.
- **~80 source tables** across ~28 modules — full inventory in Section 15.

---

## Section 6 — Workflows

### Workflow 1 — Render Aggregate Dashboard
- **Trigger:** staff user opens a dashboard route. **End state:** rendered page.
- **Steps:** 1. System verifies auth + verified + active tenancy. 2. System authorizes (permission or role). 3. System runs resilient reads against source tables. 4. System composes tiles/charts. 5. Page renders.
- **Exception paths:** unauthorized → 403; a source read fails → that tile shows zero and rendering continues.
- **Notifications:** none.

### Workflow 2 — Role Routing & Student/Parent Redirect
- **Trigger:** user opens main dashboard. **End states:** staff dashboard rendered OR redirect to Student Portal.
- **Steps:** 1. System reads the user's role. 2. Decision: Student/Parent → redirect to Student Portal; else → render staff dashboard.
- **Exception paths:** role dashboard accessed by wrong role → 403.
- **Notifications:** none.

### Workflow 3 — Resilient Degradation
- **Trigger:** a source table is missing/renamed/empty during aggregation. **End state:** page renders with affected figures at zero.
- **Steps:** 1. Read attempt throws. 2. System catches and substitutes zero. 3. Soft-deleted rows already excluded. 4. Render continues.
- **Exception paths:** *(gap)* failure is not logged, so silent data-source breakage is possible (see RISK-DSH-004).
- **Notifications:** none.

---

## Section 7 — Reporting & Analytics

Every dashboard view is itself an analytical report. Canonical report IDs:

| RPT ID | Report / view | Audience | Frequency | Contents | Export |
|--------|---------------|----------|-----------|----------|--------|
| RPT-DSH-001 | Main School Overview | School Admin | On demand | 21 headline counts, students/class chart, staff & infra breakdown, timetable readiness | None (screen) |
| RPT-DSH-002 | Finance Hub | School Admin | On demand | Fee invoices, receipts, concessions, structures | None |
| RPT-DSH-003 | LMS Hub | School Admin | On demand | Exams, quizzes, quests, homework, attempts, grievances | None |
| RPT-DSH-004 | Admission & Student Hub | School Admin | On demand | Applications, cycles, enquiries, student counts | None |
| RPT-DSH-005 | Staff Hub | School Admin | On demand | Teachers, employees, departments, designations, leave | None |
| RPT-DSH-006 | Operations / Front Desk / Support Hubs | School Admin | On demand | Transport, complaints, visitors, calls, lost & found, postal | None |
| RPT-DSH-007 | Foundational Setup — Billing | School Admin | On demand | Plan, recent invoices, next bill | None |
| RPT-DSH-008 | Principal Dashboard | Principal | On demand | Attendance, students, finance, staff, operations, timetable, academics | None |
| RPT-DSH-009 | Teacher Dashboard | Teacher | On demand | Schedule, classes, students, attendance, leave | None |
| RPT-DSH-010 | Accounts / Transport / Library / Management Dashboards | Respective role | On demand | Role-area KPIs | None |
| RPT-DSH-011 | Platform Health Dashboard | Platform Operator | On demand | Tenants, system, DB/migrations, app metrics, errors, billing/MRR, module health, security | None |

---

## Section 8 — Future Enhancement Log

| ENH ID | Enhancement | Rationale |
|--------|-------------|-----------|
| ENH-DSH-001 | Wire the 6 role dashboards (Principal, Teacher, Accounts, Transport, Library, Management) to live data | Currently placeholder figures |
| ENH-DSH-002 | Wire the Platform Health dashboard to real central-context metrics | Currently placeholder figures |
| ENH-DSH-003 | Add academic-year/session scoping filter to all aggregations | Counts are tenant-wide, not session-scoped |
| ENH-DSH-004 | Log (and optionally alert on) caught aggregation failures | Silent zeros hide broken source tables |
| ENH-DSH-005 | Add caching/refresh strategy for expensive cross-module aggregation | Page recomputes ~80 reads each load |
| ENH-DSH-006 | User-customisable tile layout / saved views | Personalisation; would need new persistence |
| ENH-DSH-007 | Either implement or remove the dashboard data API resource stub | Resource declared but only listing applies |
| ENH-DSH-008 | Snapshot export / scheduled email of key dashboards | Stakeholder reporting |

---

## Section 9 — Non-Functional Requirements

| NFR ID | Category | Requirement | Threshold |
|--------|----------|-------------|-----------|
| NFR-DSH-001 | Performance | Dashboards aggregate ~80 reads per load; main dashboard should render within an acceptable interactive time. | ≤ 2s typical [inferred] |
| NFR-DSH-002 | Security | Each school sees only its own data; platform-health data is operator-only. | Enforced by tenancy + role |
| NFR-DSH-003 | Security | All routes require authenticated, verified users behind tenancy middleware. | No anonymous access |
| NFR-DSH-004 | Reliability | A failing source must not break the page (graceful zero). | 0 page-level failures from one bad source |
| NFR-DSH-005 | Usability | Empty states must render cleanly (zeros, "no records"). | All tiles/lists handle empty |
| NFR-DSH-006 | Scalability | Aggregation must remain responsive for large tenants (thousands of students). | Indexed source reads [inferred] |
| NFR-DSH-007 | Maintainability | Adding a tile must not require schema changes (read-only design). | No DDL impact |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Coverage Table (downstream contract)
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---|---|---|---|---|---|---|---|---|
| REQ-DSH-001 | Main landing dashboard | P0 | DASHBOARD,REPORT | No | Yes | No | No | Yes |
| REQ-DSH-002 | 15 area hubs | P0 | DASHBOARD,REPORT | No | Yes | No | No | Yes |
| REQ-DSH-003 | Foundational detail pages | P1 | DASHBOARD,CONFIG | No | Yes | No | No | Yes |
| REQ-DSH-004 | Role dashboards | P1 | DASHBOARD,APPROVAL | No | Yes | No | No | Yes |
| REQ-DSH-005 | Platform health | P1 | DASHBOARD,INTEGRATION | No | Yes | No | No | Yes |
| REQ-DSH-006 | Student/Parent redirect | P0 | WORKFLOW | No | No | No | No | Yes |
| REQ-DSH-007 | Consolidated notifications | P1 | DASHBOARD,NOTIFICATION | No | Yes | No | No | Yes |
| REQ-DSH-008 | Resilient aggregation | P0 | DASHBOARD,INTEGRATION | No | No | No | No | Yes |
| REQ-DSH-009 | Access enforcement | P0 | CONFIGURATION | No | No | No | No | Yes |
| REQ-DSH-010 | Timetable readiness | P1 | DASHBOARD,REPORT | No | Yes | No | No | Yes |
| REQ-DSH-011 | Cross-layer billing read | P1 | DASHBOARD,INTEGRATION | No | Yes | No | No | Yes |
| REQ-DSH-012 | Dashboard data API (scaffold) | P2 | INTEGRATION | No | No | Yes | No | Yes |

> **DDL note:** No `dsh_*` entity is needed for any REQ — Dashboard owns no schema. Downstream DDL gap analysis for DSH instead = "verify all ~80 source tables exist" (Section 15).

### 10.2 BR Coverage
24 business rules (BR-DSH-001…024). Types: Permission ×6, Calculation ×9, Workflow ×6, Validation ×3.

### 10.3 Report Coverage
11 analytical views (RPT-DSH-001…011), none with export today (export = ENH-DSH-008).

### 10.4 Totals
- **Functional Requirements:** 12 (P0 = 5 · P1 = 5 · P2 = 2)
- **Business Rules:** 24
- **Workflows:** 3
- **Reports/Views:** 11
- **Enhancements:** 8
- **NFRs:** 7

---

## Section 11 — Requirements Traceability Matrix

| REQ-ID | BR refs | Screen(s) | Workflow | Report | Test ref | Code status |
|--------|---------|-----------|----------|--------|----------|-------------|
| REQ-DSH-001 | BR-001,002,003,004,010,011,012,020,021,023,024 | main landing | WF1 | RPT-001 | TC-001 | DONE (live) |
| REQ-DSH-002 | BR-001,002,003,004,006 | 15 hubs | WF1 | RPT-002..006 | TC-002 | DONE (live) |
| REQ-DSH-003 | BR-015,016,017,018,019 | profile/session/billing | WF1 | RPT-007 | TC-003 | DONE (live) |
| REQ-DSH-004 | BR-007 | 6 role dashboards | WF2 | RPT-008..010 | TC-004 | PARTIAL (dummy data) |
| REQ-DSH-005 | BR-007 | platform health | WF1 | RPT-011 | TC-005 | PARTIAL (dummy data) |
| REQ-DSH-006 | BR-005 | — | WF2 | — | TC-006 | DONE |
| REQ-DSH-007 | BR-022 | all-notifications | WF1 | — | TC-007 | DONE (delegated) |
| REQ-DSH-008 | BR-003,004 | — | WF3 | — | TC-008 | DONE |
| REQ-DSH-009 | BR-006,007,008,009 | — | WF1 | — | TC-009 | PARTIAL (permission unseeded) |
| REQ-DSH-010 | BR-012 | main landing | WF1 | RPT-001 | TC-010 | DONE (live) |
| REQ-DSH-011 | BR-017,018,019 | billing/profile | WF1 | RPT-007 | TC-011 | DONE (live) |
| REQ-DSH-012 | BR-001 | — | — | — | TC-012 | NOT STARTED (stub only) |

---

## Section 12 — Requirement Conditions Catalog

| Condition ID (=BR) | Entity/Field | Condition | Type | Trigger | On-violation behaviour |
|---|---|---|---|---|---|
| BR-DSH-003 | any count/sum | exclude soft-deleted | Calculation | aggregation | record omitted |
| BR-DSH-004 | any tile | source unavailable | Workflow | read failure | tile = 0, page continues |
| BR-DSH-005 | user role | Student/Parent | Workflow | main load | redirect to portal |
| BR-DSH-006 | permission | "view dashboards" absent | Permission | hub load | 403 |
| BR-DSH-007 | role | wrong role | Permission | role dashboard load | 403 |
| BR-DSH-008 | session | unauthenticated/unverified | Permission | any load | redirect to login |
| BR-DSH-010 | sections | not active | Calculation | chart build | excluded |
| BR-DSH-018 | plan | not subscribed/cancelled | Validation | billing load | not shown as active |
| BR-DSH-019 | schedule | past or already-generated | Calculation | billing load | excluded from "next bill" |
| BR-DSH-023 | module card | route missing | Validation | render | card must be removed/fixed |

*(Canonical copy also belongs in `5-Requirement_Conditions/Dashboard_Conditions.md` — points back to this file.)*

---

## Section 13 — Validation & Edge-Case Catalog

| Field/Rule | Valid | Invalid/Boundary | Empty/null | Concurrency | Expected |
|---|---|---|---|---|---|
| Student count | school has students | source table renamed | no students | new student added mid-load | shows current count or 0 on failure; no error |
| Timetable readiness % | some stages have data | all stages empty | — | stage populated during load | 0–100%; 0 when none |
| Role gate | matching role | mismatched role | no role assigned | role revoked mid-session | 403 for non-matching |
| Student/Parent redirect | Student logs in | staff with extra Student role `[inferred]` ambiguity | — | — | Student/Parent always redirected |
| Billing context | school subscribed | unresolved tenant identity | no invoices | invoice created mid-load | empty sections render cleanly |
| Notifications | user has notices | — | none | new notice arrives | empty state or current list |

---

## Section 14 — State / Routing Model

Dashboard has **no entity state machine** (no persisted records). Its only "state" is **routing/access state** per request:

| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Anonymous | open any dashboard | not authenticated | → Login | none |
| Authenticated staff | open main | role ∈ {Student,Parent} | → Student Portal | redirect |
| Authenticated staff | open area hub | has "view dashboards" | Hub rendered | resilient reads |
| Authenticated staff | open area hub | lacks permission | → 403 | none |
| Authenticated user | open role dashboard | hasRole(match) | Role dashboard rendered | none |
| Authenticated user | open role dashboard | role mismatch | → 403 | none |

---

## Section 15 — Cross-Module Dependency Map (technical register)

**Inbound — Dashboard reads from (~80 tables, ~28 modules, 3 DB layers):**

| Source module | Tables |
|---|---|
| SchoolSetup `sch_` | classes, class_section_jnt, subjects, subject_groups, rooms, room_types, buildings, teachers, employees, departments, designations, academic_term, org_academic_sessions_jnt, organizations, board_organization_jnt |
| StudentProfile `std_` | students |
| SmartTimetable `tt_` | activities, timetables, class_requirement_groups, requirement_consolidations, teacher_availabilities, slot_requirements, period_sets, generation_runs, teacher_workloads, timetable_cells |
| Admission `adm_` | applications, cycles, enquiries |
| Complaint `cmp_` | complaints |
| Notification `ntf_` | notifications |
| Hpc `hpc_` | reports |
| LMS `lms_` | exams, quizzes, quests, homeworks, exam_attempts, exam_grievances |
| Accounting `acc_` | financial_years, ledgers, vouchers |
| StudentFee `fin_` | fee_invoices, fee_receipts, fee_structure_masters, fee_concession_types |
| Certificate `crt_` | issued_certificates, requests, templates |
| Behaviour `beh_` | assessments |
| Library/Books `bok_` | books |
| Cafeteria `caf_` | orders, meal_cards, menu_items |
| Feedback `fbk_` | cycles, responses, templates |
| FrontOffice `fof_` | visitors, enquiries, call_logs, lost_found_items, postal_registers |
| HrStaff `hrs_` | leave_applications, leave_types |
| Inventory `inv_` | purchase_orders, stock_items |
| Marksheet `msg_` | marksheet_schedules |
| Payroll `pay_` | salary_structures |
| PTM `ptm_` | events, assignments, slots, slot_bookings, blockouts, batches_template, event_class_section_jnt |
| QuestionBank `qns_` | questions |
| Recommendation `rec_` | recommendations |
| Syllabus `slb_` | syllabuses |
| Transport `tpt_` | routes, vehicles |
| Vendor `vnd_` | vendors |
| System `sys_` | users, activity_logs, dropdowns, settings + roles, permissions |
| Global (`global_master_mysql`) | glb_cities, glb_academic_sessions, glb_boards |
| Prime/Billing (`mysql`) | prm_tenant, prm_plans, prm_tenant_plan_jnt, prm_billing_cycles, prm_tenant_plan_billing_schedules, bil_tenant_invoices |

**Outbound — Dashboard feeds:** none (no events, no shared tables, no services).
**Direct reuse:** consolidated notifications delegates to GlobalMaster's NotificationController.
**Redirect:** main dashboard → StudentPortal `student-portal.dashboard`.

---

## Section 16 — Risk Register

| Risk ID | Risk | Cat | L | I | Mitigation | Trigger |
|---|---|---|---|---|---|---|
| RISK-DSH-001 | "view dashboards" permission not seeded → all area hubs 403 | Security/Config | M | H | Seed `tenant.dashboard.viewAny`, or confirm super-admin Gate bypass | Any non-admin opens a hub |
| RISK-DSH-002 | 8 dashboards show dummy data mistaken for real | Data/Trust | H | H | Wire to live data (ENH-001/002); label as demo until then | Stakeholder reads placeholder as fact |
| RISK-DSH-003 | No session/year scoping → cross-session over-counting | Data accuracy | M | M | Add year filter (ENH-003) | Multi-year tenant |
| RISK-DSH-004 | Silent zeros hide broken source tables | Reliability | M | M | Log caught failures (ENH-004) | Source table renamed |
| RISK-DSH-005 | ~80 reads/load → latency on large tenants | Performance | M | M | Cache/batch (ENH-005); index source reads | Large tenant |
| RISK-DSH-006 | Tight coupling to 28 modules' table names | Maintainability | H | M | Centralise table refs; integration tests | Any source rename |
| RISK-DSH-007 | API resource stub may 500 on non-index verbs | Integration | L | L | Implement or remove (ENH-007) | Client calls store/show |

---

## Section 17 — Prioritization (MoSCoW)

- **Must (P0):** REQ-001, 002, 006, 008, 009.
- **Should (P1):** REQ-003, 004, 005, 007, 010, 011.
- **Could (P2):** REQ-012.
- **Won't (this release):** layout personalisation (ENH-006), snapshot export (ENH-008).

---

## Section 18 — Effort Estimation & Sprint Tasks

| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|-----------|------------|--------|
| 1 | Seed/verify `tenant.dashboard.viewAny` permission + role grants | Backend | 3 | — | 1 |
| 2 | Wire Principal/Teacher/Accounts/Transport/Library/Management dashboards to live data | Backend | 40 | source modules | 1–2 |
| 3 | Wire Platform Health dashboard to central metrics | Backend | 24 | central context | 2 |
| 4 | Add academic-session scoping filter across aggregations | Backend | 16 | — | 2 |
| 5 | Add logging on caught aggregation failures | Backend | 4 | — | 1 |
| 6 | Resolve API resource stub (implement read endpoints or remove) | Backend | 6 | — | 3 |
| 7 | Test suite: role gates, redirect, resilient zero, tile counts | Testing | 24 | tasks 1–4 | 2–3 |
| 8 | Optional: cache layer for expensive reads | Backend | 12 | task 4 | 3 |

> Estimation basis: gauged against similar read-heavy modules; assumes source-module tables/queries already exist.

---

## Section 19 — User Stories (Gherkin) — P0/P1

**US-DSH-001 (REQ-001) P0** — As a School Admin, I want a landing overview so that I grasp the school's status at a glance.
- Given I am a logged-in admin, When I open the dashboard, Then I see headline counts and charts for my school.
- Given a source area has no data, When the page loads, Then that tile shows zero and the page still renders.
- Given I am a Student, When I open the dashboard, Then I am redirected to the Student Portal.

**US-DSH-002 (REQ-002) P0** — As a permitted staff member, I want functional-area hubs so that I can review one domain at a time.
- Given I hold the dashboard permission, When I open the Finance hub, Then I see finance KPIs for my school.
- Given I lack the dashboard permission, When I open a hub, Then access is refused.

**US-DSH-004 (REQ-004) P1** — As a Principal, I want a Principal dashboard so that I see school-wide priorities.
- Given I have the Principal role, When I open it, Then all tabs render.
- Given I am a Teacher, When I open the Principal dashboard, Then access is refused.

**US-DSH-005 (REQ-005) P1** — As a Platform Operator, I want a platform-health view so that I can monitor tenants and billing.
- Given I am the operator, When I open it, Then I see tenant, system, and billing sections.
- Given I am a school user, When I open it, Then access is refused.

**US-DSH-006 (REQ-006) P0** — As a Parent, I want to land on my portal so that I am not shown staff screens.
- Given I am a Parent, When I open the dashboard, Then I am redirected to the Student Portal.

**US-DSH-008 (REQ-008) P0** — As any user, I want dashboards to stay up even when a source breaks.
- Given a source table is unavailable, When I open a dashboard, Then affected tiles read zero and the page renders.

**US-DSH-009 (REQ-009) P0** — As a security owner, I want enforced access so that data stays scoped.
- Given an unauthenticated request, When it hits any dashboard, Then it is redirected to login.

**US-DSH-010 (REQ-010) P1** — As a School Admin, I want a timetable-readiness indicator so that I track setup progress.
- Given no setup stages have data, When I view the main dashboard, Then readiness reads 0%.

**US-DSH-011 (REQ-011) P1** — As a School Admin, I want my plan and invoices so that I track subscription status.
- Given my school is subscribed, When I open Billing, Then I see the active plan, recent invoices, and next bill.

---

## Section 20 — KPI Catalog

| KPI | Definition (business) | Source | Cadence |
|-----|-----------------------|--------|---------|
| Total Students | Active enrolled student count | Student records | On load |
| Fee Collection Rate | Collected ÷ invoiced for current school | Fees | On load |
| Pending Evaluations | Exam attempts awaiting grading | LMS | On load |
| Open Grievances | Exam grievances in open status | LMS | On load |
| Timetable Readiness | Setup stages complete ÷ total | Timetable | On load |
| Active Plan / Next Bill | Current subscription + earliest future bill | Billing layer | On load |
| Open Complaints | Complaints not yet resolved | Complaints | On load |
| MRR (operator) | Monthly recurring revenue across tenants `[inferred/placeholder]` | Billing layer | On load |

---

*End of Complete Analysis Pack — DSH. IDs are canonical; downstream audits reuse REQ-/BR-/RPT-/ENH- as numbered here.*
