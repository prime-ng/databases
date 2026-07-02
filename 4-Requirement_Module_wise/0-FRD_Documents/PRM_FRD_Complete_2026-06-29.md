# Prime (PRM) — Complete Analysis Pack
**Date:** 2026-06-29 | **Agent:** pa-business-analyst | **Mode:** Complete Analysis Pack
**Sources:** PRM_Prime_Requirement.md (V2, 2026-03-26) · prime_db_v4.sql · Modules/Prime/ live code audit (2026-06-29) · modules-map.md · tenancy-map.md
**Module Knowledge:** `AI_Brain/module-knowledge/PRM_Prime.md`

---

## Table of Contents

- [Section 1 — FRD (Functional Requirements Document)](#section-1)
  - [1.1 Module Overview](#11-module-overview)
  - [1.2 User Roles and Access](#12-user-roles-and-access)
  - [1.3 Functional Requirements (REQ-PRM-001 to REQ-PRM-012)](#13-functional-requirements)
  - [1.4 Business Rules Register (BR-PRM-001 to BR-PRM-013)](#14-business-rules-register)
  - [1.5 Data Requirements](#15-data-requirements)
  - [1.6 Workflows](#16-workflows)
  - [1.7 Reporting and Analytics (RPT-PRM-001 to RPT-PRM-005)](#17-reporting-and-analytics)
  - [1.8 Future Enhancement Log (ENH-PRM-001 to ENH-PRM-008)](#18-future-enhancement-log)
  - [1.9 Non-Functional Requirements](#19-non-functional-requirements)
  - [1.10 Gap Analysis Readiness Index](#110-gap-analysis-readiness-index)
- [Section 2 — Requirements Traceability Matrix (RTM)](#section-2)
- [Section 3 — Business Rules + Conditions + Validation Catalog](#section-3)
- [Section 4 — Process Flows + FSM Catalog](#section-4)
- [Section 5 — Data Dictionary + Cross-Module Dependency Map](#section-5)
- [Section 6 — NFR Catalog + Risk Register](#section-6)
- [Section 7 — Prioritization + Effort Estimation](#section-7)
- [Section 8 — User Stories + Reporting KPI Spec](#section-8)

---

<a id="section-1"></a>
## Section 1 — Functional Requirements Document (FRD)

**Module:** Prime | **Code:** PRM | **Type:** Central Platform Administration
**Database:** prime_db (owns prm_* and bil_* schemas); reads global_db
**Not tenant-scoped:** This module runs exclusively on the central management domain and has no tenant database context.

---

### 1.1 Module Overview

#### 1.1.1 Purpose

The Prime module is the SaaS operations console for PrimeGurukul (the software company). It governs the complete lifecycle of school customers on the platform: onboarding a new school, provisioning its isolated database, assigning subscription plans, controlling which application modules the school can access, generating billing schedules, managing platform staff, and maintaining the reference data that every school module consumes. No school module can function without the foundation that Prime lays.

#### 1.1.2 Business Value

| Value Driver | Outcome |
|-------------|---------|
| Automated School Onboarding | A new school's fully isolated database, with all migrations and an initial admin user, is provisioned without manual DBA intervention |
| Module Licensing Control | Schools access only the modules they have subscribed to; oversubscription is structurally prevented |
| Billing Accuracy | Pre-scheduled billing entries eliminate missed invoices and manual billing calendar management |
| Security Isolation | Central domain routing ensures school staff can never access the PrimeGurukul management console |
| Centralised Reference Data | Boards, academic sessions, and dropdown values managed once flow to all schools immediately |

#### 1.1.3 Scope

**In Scope:**
- School (tenant) onboarding, database provisioning, and domain management
- Subscription plan catalogue with module licensing
- Billing schedule generation feeding the Billing module
- Central platform staff management (users, roles, permissions)
- Global reference data: education boards, languages, academic sessions, dropdown definitions, menus, platform settings
- Platform monitoring dashboard and activity audit logs
- Platform authentication (PrimeGurukul staff login on central domain)

**Out of Scope:**
- School-level user and teacher management (SchoolSetup module)
- Fee collection and payment gateway processing (StudentFee and Payment modules)
- Invoice payment recording and collection follow-up (Billing module)
- Any feature accessible on a school's subdomain
- Student data, academic records, or curriculum content

#### 1.1.4 Terminology

| Business Term | Meaning |
|---------------|---------|
| School / Tenant | An educational institution subscribing to Prime-AI as a separate, isolated customer |
| School Group | A managing trust, chain, or committee that owns one or more schools |
| Subscription Plan | A pricing tier defining which application modules the school can access and at what price |
| Billing Cycle | The recurrence period for charges: Monthly, Quarterly, Yearly, or One-Time |
| Billing Schedule | A calendar of pre-calculated future invoice generation dates for a school's subscription |
| Academic Session | A school year period (e.g., April 2025 to March 2026); gates all plan and billing operations |
| Platform Staff | PrimeGurukul employees who manage the platform (not school-level staff) |
| Central Domain | The PrimeGurukul management website domain (e.g., primeai.app) — separate from all school subdomains |
| School Domain | A school's specific subdomain (e.g., greenwood.primeai.app) — cannot access Prime features |
| Database Provisioning | The automated creation of an isolated MySQL database for a new school, including running all application migrations |
| Root User | The first administrator user auto-created inside a new school's database during provisioning |
| Super Admin | A PrimeGurukul platform user with full, unconditional access to all Prime features |
| Allowed Module List | The set of application modules a school may access, derived from their current active subscription |
| Plan Version | An immutable snapshot of a subscription plan; edits create a new version rather than overwriting history |

---

### 1.2 User Roles and Access

#### 1.2.1 Actors

| Actor | Type | Description |
|-------|------|-------------|
| Platform Super Admin | Internal | Full access to all Prime features; set only via database direct operation |
| Platform Manager | Internal | Manages school onboarding, plan assignments, and tenant group records |
| Platform Finance | Internal | Views billing schedules and invoice status; does not modify plans |
| Platform IT / Ops | Internal | Manages settings, menus, dropdowns, reference data |
| Queue Worker | System | Automated process that executes the school database provisioning job |
| School Admin (Tenant) | External | Has no access to Prime; routes at their own subdomain only |

#### 1.2.2 Role-Feature Access Matrix

| Feature | Super Admin | Platform Manager | Platform Finance | Platform IT/Ops |
|---------|:-----------:|:----------------:|:----------------:|:---------------:|
| School Group CRUD | Full | Full | View only | No |
| School Tenant CRUD + Onboarding | Full | Full | View only | No |
| Plan Management | Full | Full | View only | No |
| Plan Assignment to School | Full | Full | No | No |
| Billing Schedule View | Full | Full | Full | No |
| Platform User CRUD | Full | No | No | No |
| Role and Permission Management | Full | No | No | No |
| Global Reference Data (Boards, Sessions, Dropdowns) | Full | Full | No | Full |
| Platform Settings | Full | No | No | Full |
| Platform Dashboard | Full | Full | Full | View only |
| Activity Log View | Full | Full | No | No |

---

### 1.3 Functional Requirements

---

#### REQ-PRM-001 — School Tenant Registration and Automated Database Provisioning
**Priority:** Core (P0) | **Tags:** [WORKFLOW][DATA_ENTRY][INTEGRATION]

**Description:** A Platform Manager registers a new school by completing a tenant profile form. The system immediately creates the school record and asynchronously provisions a fully isolated database, runs all application migrations (~600 files), seeds an initial administrator user and a basic organisation record, then notifies the relevant parties on completion or failure.

**Actors:** Initiates: Platform Manager / Super Admin | Processes: Queue Worker (System) | Views: Platform Manager, Super Admin

**Business Rules:** BR-PRM-001, BR-PRM-006, BR-PRM-009, BR-PRM-010

**Acceptance Criteria:**
- AC-001-01: Given a completed school registration form, the system creates the school record with setup status "Pending" and active status "Inactive", creates the school domain record, dispatches the database provisioning task, sends a welcome email to the school's email address, and redirects the admin to the setup progress view. All of this happens within one web request. (YES/NO)
- AC-001-02: Given the provisioning task completes all four stages successfully, the school's database exists, setup status shows "Completed", setup progress shows 100%, a root administrator user exists in the school's database, and an initial organisation record exists in the school's database. (YES/NO)
- AC-001-03: Given the provisioning task fails at any stage, setup status shows "Failed", setup progress is frozen at the last completed percentage, and a failure notification is sent to all Super Admins. (YES/NO)
- AC-001-04: Given a school is fully provisioned, the setup progress view is accessible by polling the status endpoint, and a Platform Manager can see the current stage and percentage without refreshing the page. (YES/NO)
- AC-001-05: Given the school domain is changed after creation, the platform's routing resolves the new domain for all future school requests. (YES/NO)
- AC-001-06: Given a Platform Manager without the "Manage Tenants" permission attempts to create a school, the system returns a 403 Access Denied response. (YES/NO)

**Integration:** GlobalMaster (city lookup), stancl/tenancy (database creation), Laravel Mail (welcome email), Laravel Queue (provisioning job)

**Enhancement Notes:** ENH-PRM-001 (re-trigger failed setup), ENH-PRM-002 (secure root password), ENH-PRM-007 (explicit activation gate)

---

#### REQ-PRM-002 — School Group Management
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY]

**Description:** Schools are organised into groups representing chains, trusts, or managing committees. Platform Managers create and maintain these groups. Every school must belong to exactly one group. Groups can be deactivated or soft-deleted but may not be deleted while they have active school records.

**Actors:** Initiates: Platform Manager / Super Admin | Views: Platform Manager, Super Admin

**Business Rules:** BR-PRM-014

**Acceptance Criteria:**
- AC-002-01: Given a valid group form, the system creates the group, sends a notification to the group's email address, and records the action in the activity log. (YES/NO)
- AC-002-02: Given a group that has at least one associated school, a delete attempt returns a business-language validation message ("This group has active schools and cannot be deleted") rather than a database exception. (YES/NO)
- AC-002-03: Given a group is deactivated, the status change is immediately reflected and the group can be reactivated. (YES/NO)
- AC-002-04: Given a soft-deleted group, it appears in the Deleted Groups list and can be permanently deleted or restored. (YES/NO)
- AC-002-05: Given a user without "Manage School Groups" permission, all write actions return 403. (YES/NO)

**Integration:** GlobalMaster (city lookup), Laravel Mail (group creation email)

---

#### REQ-PRM-003 — Subscription Plan Catalogue Management
**Priority:** Core (P0) | **Tags:** [CONFIGURATION][DATA_ENTRY]

**Description:** Platform admins define the pricing tier catalogue. Each plan specifies which application modules are included and provides pricing at three recurrence points (monthly, quarterly, yearly). Plans are versioned so that editing a plan does not retroactively change what existing subscribers were quoted.

**Actors:** Initiates: Platform Manager / Super Admin | Views: Platform Manager, Super Admin, Platform Finance

**Business Rules:** BR-PRM-012, BR-PRM-015

**Acceptance Criteria:**
- AC-003-01: Given a new plan is created with a billing cycle and module selections, the system creates the plan at version 0 and records the associated module list. (YES/NO)
- AC-003-02: Given an existing plan is edited, the system creates a new version row rather than overwriting the existing row, and marks the previous version inactive. Existing school subscriptions retain their reference to the original version. (YES/NO)
- AC-003-03: Given a module is removed from a plan, schools already subscribed to that plan version retain access until they are re-assigned to the new version. (YES/NO)
- AC-003-04: Given a plan is deactivated, it can no longer be selected for new school assignments but existing subscriptions are unaffected. (YES/NO)
- AC-003-05: Given a user without "Manage Plans" permission, all write actions return 403. (YES/NO)

**Integration:** GlobalMaster (module registry)

---

#### REQ-PRM-004 — Tenant Plan Subscription and Billing Schedule Generation
**Priority:** Core (P0) | **Tags:** [WORKFLOW][DATA_ENTRY][INTEGRATION]

**Description:** A Platform Manager assigns a plan to a school and sets the subscription terms (start date, end date, billing cycle, pricing, taxes, discounts, credit days). The system executes a five-step transactional process: recording the subscription, saving the rate card, updating the licensed module list, and generating a complete billing calendar for the subscription period. The entire operation succeeds or rolls back completely.

**Actors:** Initiates: Platform Manager / Super Admin | Processes: System (transaction) | Views: Platform Manager, Platform Finance

**Business Rules:** BR-PRM-002, BR-PRM-003, BR-PRM-004, BR-PRM-005

**Acceptance Criteria:**
- AC-004-01: Given a monthly billing subscription from April 2025 to March 2026 within an active academic session, the system generates exactly 12 billing schedule entries, one per month. (YES/NO)
- AC-004-02: Given a subscription date range that falls entirely outside the current academic session, the system returns a warning and creates no billing schedule entries. (YES/NO)
- AC-004-03: Given a failure at any of the five steps within the transaction, all steps are rolled back and no partial subscription data remains. (YES/NO)
- AC-004-04: Given a plan re-assignment (a second call for the same school), previously active module entries are set to "inactive" and new module entries are added; old billing schedule entries are soft-deactivated and a new schedule is generated. (YES/NO)
- AC-004-05: Given no active academic session exists, the plan assignment is blocked with a clear business-language error message. (YES/NO)
- AC-004-06: Given a user without the correct permission for plan assignment, the system returns 403. (YES/NO)

**Integration:** GlobalMaster (academic session), Billing module (billing schedule entries consumed downstream)

---

#### REQ-PRM-005 — Billing Schedule to Invoice Pipeline
**Priority:** Standard (P1) | **Tags:** [SCHEDULED][WORKFLOW][INTEGRATION]

**Description:** A scheduled command runs daily and processes all billing schedule entries that have reached their generation date and have not yet produced an invoice. For each qualifying entry, the system creates a platform invoice with a full financial breakdown (sub-total, discount, taxes, extra charges, net payable amount), marks the entry as invoiced, and links the generated invoice back to the schedule entry.

**Actors:** Initiates: System (scheduled command) | Views: Platform Finance, Super Admin

**Business Rules:** BR-PRM-016, BR-PRM-017

**Acceptance Criteria:**
- AC-005-01: Given the scheduled command runs on a given date, all billing schedule entries where the generation date is on or before that date and no invoice has been generated are processed and an invoice is created for each. (YES/NO)
- AC-005-02: Given an invoice is created, the net payable amount equals: base amount minus discount plus extra charges plus the sum of all applicable tax amounts. (YES/NO)
- AC-005-03: Given an invoice is created, the invoice number is unique across the platform and the payment due date is the invoice date plus the credit days from the rate card. (YES/NO)
- AC-005-04: Given an invoice's payment due date has passed and its status is not "Paid", it appears in the Overdue Invoices list on the platform dashboard. (YES/NO)
- AC-005-05: Given the scheduled command fails for a specific entry, it logs the error and continues processing remaining entries rather than aborting the entire batch. (YES/NO)

**Integration:** Billing module (invoice records), Platform Dashboard (overdue invoice display)

**Enhancement Notes:** ENH-PRM-004 (create the GenerateInvoicesCommand — currently missing)

---

#### REQ-PRM-006 — Central Platform Authentication
**Priority:** Core (P0) | **Tags:** [WORKFLOW]

**Description:** Platform staff (PrimeGurukul employees) log in via the central management domain using their email and password. Authentication is strictly domain-scoped: school staff logging into their subdomain never reach Prime authentication. Test and debug routes must not be accessible in production.

**Actors:** Initiates: Platform Staff | Processes: System

**Business Rules:** BR-PRM-018

**Acceptance Criteria:**
- AC-006-01: Given valid credentials on the central domain, the system establishes a session and redirects to the platform dashboard. (YES/NO)
- AC-006-02: Given valid school-staff credentials on a school subdomain, the system routes to the school's login page and does not access any Prime routes. (YES/NO)
- AC-006-03: Given an unauthenticated request to a protected Prime route, the system redirects to the Prime login page. (YES/NO)
- AC-006-04: Given a production environment, test and debug email/notification routes are not registered or return 404. (YES/NO)
- AC-006-05: Given an authenticated user logs out, the session is destroyed and the user is redirected to the login page. (YES/NO)

---

#### REQ-PRM-007 — Central Staff User Management
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY]

**Description:** Super Admins manage PrimeGurukul platform staff accounts: create users, assign roles, deactivate, soft-delete, restore. New users receive their login credentials by email. The "Super Admin" flag on a user account can only be set through a protected operation (never via a web form or API request).

**Actors:** Initiates: Super Admin | Views: Super Admin

**Business Rules:** BR-PRM-007, BR-PRM-019

**Acceptance Criteria:**
- AC-007-01: Given a new platform user is created, the system sends a login email with credentials and the user can log in immediately. (YES/NO)
- AC-007-02: Given any web form or API request that includes a "Super Admin" field, the system ignores that field entirely — the flag cannot be set via the web interface. (YES/NO)
- AC-007-03: Given a user is soft-deleted, they cannot log in but their historical records (activity logs, audit trails) remain intact. (YES/NO)
- AC-007-04: Given "Find Users by Role" is requested, only users who hold that specific role are returned. (YES/NO)
- AC-007-05: Given a user without "Manage Users" permission, all write actions return 403. (YES/NO)

---

#### REQ-PRM-008 — Role and Permission Management
**Priority:** Core (P0) | **Tags:** [CONFIGURATION]

**Description:** Super Admins create and manage central platform roles. Each role receives a set of permissions following the pattern "module.feature.action" (e.g., "prime.tenant.create"). Permissions can be toggled individually or synced in bulk. Roles can be assigned to platform users.

**Actors:** Initiates: Super Admin | Views: Super Admin

**Business Rules:** BR-PRM-020

**Acceptance Criteria:**
- AC-008-01: Given a role's permission is toggled off, users assigned that role immediately lose access to the associated action on the next request. (YES/NO)
- AC-008-02: Given a request to retrieve a role's permission list, only authenticated users with the "View Role Permissions" permission receive the data. (YES/NO)
- AC-008-03: Given a role delete action, the role is soft-removed and all users assigned that role lose those permissions. (YES/NO)
- AC-008-04: Given a user without "Manage Roles" permission attempts any write action on roles, the system returns 403. (YES/NO)

---

#### REQ-PRM-009 — Global Reference Data Management
**Priority:** Core (P0) | **Tags:** [CONFIGURATION][DATA_ENTRY]

**Description:** The Prime module owns and maintains the reference data that all school modules consume: education boards (CBSE, ICSE, State), languages, academic sessions (with the current-session flag), dropdown value definitions, and navigation menus. Changes here propagate to all schools immediately.

**Actors:** Initiates: Platform IT/Ops, Platform Manager, Super Admin | Views: All internal actors

**Business Rules:** BR-PRM-003, BR-PRM-021

**Acceptance Criteria:**
- AC-009-01: Given no active academic session is marked, the plan assignment feature is blocked across the entire platform until one is set. (YES/NO)
- AC-009-02: Given a board is deactivated, it no longer appears in school setup dropdowns for any school. (YES/NO)
- AC-009-03: Given a dropdown value is added or modified, it appears in the relevant school-module dropdowns immediately. (YES/NO)
- AC-009-04: Given the menu structure is updated, schools' navigation menus reflect the change on their next page load. (YES/NO)
- AC-009-05: Given a user without "Manage Reference Data" permission, all write actions return 403. (YES/NO)

**Integration:** All tenant modules (consume boards, sessions, dropdowns), SystemConfig module (shared dropdown and settings tables)

---

#### REQ-PRM-010 — Platform Settings
**Priority:** Core (P0) | **Tags:** [CONFIGURATION]

**Description:** Platform IT/Ops manages key-value platform settings: outgoing mail configuration, SMS provider credentials, and other platform-wide options. Settings are stored centrally and consumed by all platform services.

**Actors:** Initiates: Platform IT/Ops, Super Admin | Views: Platform IT/Ops, Super Admin

**Business Rules:** BR-PRM-022

**Acceptance Criteria:**
- AC-010-01: Given a setting is updated, the new value is applied to all subsequent platform operations (e.g., outgoing mail uses the new SMTP credentials). (YES/NO)
- AC-010-02: Given a search request on settings, only authenticated users with the "View Settings" permission receive results. (YES/NO)
- AC-010-03: Given a user without "Manage Settings" permission, all write actions return 403. (YES/NO)

---

#### REQ-PRM-011 — Platform Dashboard and Analytics
**Priority:** Standard (P1) | **Tags:** [DASHBOARD][REPORT]

**Description:** The platform dashboard gives Prime staff an at-a-glance view of platform health: school count (active/inactive), revenue totals (billed/collected/outstanding/overdue), subscription distribution (active/trial/auto-renew), chart data for 12-month revenue trend and school registration trend, recent activity logs, and the top overdue invoices.

**Actors:** Initiates: All internal actors | Views: All internal actors

**Business Rules:** (no blocking business rules; display-only)

**Acceptance Criteria:**
- AC-011-01: Given the dashboard loads, all metric cards show the current accurate count or monetary total without error. (YES/NO)
- AC-011-02: Given a new school is registered, the school registration trend chart updates on the next dashboard load. (YES/NO)
- AC-011-03: Given an invoice becomes overdue, it appears in the overdue invoice list on the next dashboard load. (YES/NO)
- AC-011-04: Given a user without "View Dashboard" permission, the dashboard returns 403. (YES/NO)

**Reports:** RPT-PRM-001, RPT-PRM-002, RPT-PRM-003

**Enhancement Notes:** ENH-PRM-006 (dashboard query caching for performance)

---

#### REQ-PRM-012 — Activity Log and Monitoring
**Priority:** Standard (P1) | **Tags:** [REPORT]

**Description:** All significant state-changing operations in Prime (school creation, plan assignment, status changes, user modifications) are recorded in the activity log with the actor, timestamp, and action description. Platform staff with the appropriate permission can view and filter this log.

**Actors:** Initiates: System (automatic) | Views: Platform Manager, Super Admin

**Business Rules:** BR-PRM-023

**Acceptance Criteria:**
- AC-012-01: Given a school is created, an activity log entry is created with the acting user, timestamp, and school name. (YES/NO)
- AC-012-02: Given a plan is assigned to a school, an activity log entry is recorded. (YES/NO)
- AC-012-03: Given a request to view the activity log, only users with the "View Activity Log" permission can access it. (YES/NO)

**Reports:** RPT-PRM-005

---

### 1.4 Business Rules Register

| BR ID | Rule | Type | Trigger | Enforcement Point | Priority |
|-------|------|------|---------|-------------------|----------|
| BR-PRM-001 | A school can only be accessed via its subdomain if it has active status AND at least one active plan subscription. | Permission | Every school web request | `Tenant::canAccess()` method | P0 |
| BR-PRM-002 | Only one plan subscription can be active per school per plan at any time. Duplicate active subscriptions for the same plan are structurally prevented. | Validation | Plan assignment | Database generated column + unique constraint | P0 |
| BR-PRM-003 | An active academic session must exist before any plan can be assigned to a school. The system blocks assignment if no current session is found. | Validation | Plan assignment initiation | Plan Assignment Service | P0 |
| BR-PRM-004 | The billing schedule window is clamped to the active academic session bounds: the window starts on whichever date is later (subscription start or session start) and ends on whichever is earlier (subscription end or session end). If the clamped window produces no billing dates, a warning is returned and no schedule entries are created. | Calculation | Billing schedule generation | Plan Assignment workflow Step 5 | P0 |
| BR-PRM-005 | When a school's plan is re-assigned, existing licensed module entries are soft-deactivated (never deleted) to preserve billing and audit history. New module entries are created for the new assignment. | Workflow | Plan re-assignment | Plan Assignment Service Step 4 | P0 |
| BR-PRM-006 | The school's database connection password must be stored in encrypted form at rest. Storing database credentials in plaintext in the platform database is a critical security exposure. | Validation | Record creation and update | Domain record model | P0 |
| BR-PRM-007 | The "Super Admin" flag on a platform user account may not be set via any web form, API request, or URL parameter. Only a protected database-level operation or a dedicated artisan command with explicit confirmation may set it. | Permission | Any user create or update request | User model (guarded field) | P0 |
| BR-PRM-008 | The school database provisioning task runs exactly once per dispatch. A failed provisioning must be manually re-triggered by a Platform Manager — the system does not auto-retry. | Workflow | Provisioning job failure | Job configuration ($tries=1) | P1 |
| BR-PRM-009 | The initial administrator account created inside a new school's database during provisioning must receive a randomly generated secure password. Hardcoded or predictable default passwords are not permitted. The password must be delivered to the school's registered email address on successful setup completion. | Validation | Root user creation stage | Provisioning Job Stage 3 | P0 |
| BR-PRM-010 | The Tenant model must implement the TenantWithDatabase, HasDatabase, and HasDomains interfaces from the tenancy package. These interfaces are required for database isolation and domain-based routing to function. | Validation | Tenant model definition | Model class declaration | P0 |
| BR-PRM-011 | The set of modules a school may access is derived by intersecting three conditions: the school's active plan subscription, the active module entries on that plan, and the module being registered in the global module registry. A module must pass all three to appear in the school's allowed module list. | Calculation | Every tenant web request requiring a module | `Tenant::allowedModuleIds()` | P0 |
| BR-PRM-012 | When a subscription plan definition is modified (pricing, module list, or terms), a new version of the plan must be created rather than overwriting the existing row. Existing school subscriptions retain their reference to the original version for billing accuracy. | Workflow | Plan edit action | Plan management controller / service | P1 |
| BR-PRM-013 | Completing a school's setup (assigning a plan for the first time) requires the "Manage Tenant" permission, not the "Manage Tenant Group" permission. | Permission | completeTenantSetup action | Authorization gate check | P1 |
| BR-PRM-014 | A School Group may not be deleted or force-deleted while it has active school records associated with it. A business-language error must be shown to the admin — the database constraint error must not propagate to the user interface. | Validation | School Group delete action | Controller soft-delete logic | P1 |
| BR-PRM-015 | A plan's billing cycle determines the recurrence of billing schedule entries. ONE_TIME plans generate a single schedule entry regardless of the date range. Recurring plans (MONTHLY, QUARTERLY, YEARLY) generate one entry per recurrence period within the clamped billing window. | Calculation | Billing schedule generation | Plan Assignment Service Step 5 | P0 |
| BR-PRM-016 | A billing schedule entry generates an invoice only once. The "invoice generated" flag is set to true immediately after invoice creation. The scheduled command skips entries where this flag is already true. | Validation | Invoice generation command | Scheduled command | P1 |
| BR-PRM-017 | The invoice payment due date is calculated as the invoice date plus the credit days from the subscription rate card. The invoice date is the day after the billing period end date. | Calculation | Invoice creation | Invoice generation logic | P1 |
| BR-PRM-018 | Test and debug routes (test email, send test email, test notification) must not be accessible on a production environment. They must be removed from production route registration or gated to local/staging environments only. | Permission | Production deployment | Route file / environment gate | P1 |
| BR-PRM-019 | A new platform user account must receive an automated email containing their login credentials upon account creation. | Workflow | Platform user creation | UserController store action | P0 |
| BR-PRM-020 | Permission data for a role may only be returned to authenticated users who hold the "View Role Permissions" permission. The endpoint must not return data to unauthenticated or unauthorised requests. | Permission | getPermissions API call | Role management controller | P0 |
| BR-PRM-021 | Exactly one academic session may be marked as the current session at any time. Marking a new session as current automatically removes the current flag from the previous session. | Validation | Academic session update | AcademicSession model / controller | P0 |
| BR-PRM-022 | Platform settings search results must only be returned to authenticated users who hold the appropriate "View Settings" permission. | Permission | Settings search request | Settings controller | P2 |
| BR-PRM-023 | All state-changing operations in Prime (school create, update, plan assignment, status change, user create/delete, role assignment) must produce an activity log entry recording: the acting user, the target record, the action type, and the timestamp. | Workflow | Any state-changing action | activityLog() helper call in each action | P1 |

---

### 1.5 Data Requirements

#### 1.5.1 School Group

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| Group Code | Short unique identifier for the group | Short text | Yes | Internal |
| Short Name | Abbreviated name (must be unique platform-wide) | Short text | Yes | Internal |
| Full Name | Complete legal name of the group | Text | Yes | Internal |
| City | City where the group is headquartered | Lookup | Yes | Internal |
| Address Line 1 / 2 | Street address | Text | No | Internal |
| Postal Code | Postcode | Short text | No | Internal |
| Website | Group website URL | URL | No | Public |
| Email | Contact email for group-level notifications | Email | No | Confidential |
| Active Status | Whether the group is currently operational | Toggle | Yes | Internal |

#### 1.5.2 School (Tenant)

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| School Group | The managing group this school belongs to | Lookup | Yes | Internal |
| School Code | Unique short identifier | Short text | Yes | Internal |
| Short Name | Abbreviated school name | Short text | Yes | Internal |
| Full Name | Complete official school name | Text | Yes | Public |
| UDISE Code | Government UDISE identification number | Short text | No | Internal |
| Affiliation Number | Board affiliation reference | Short text | No | Internal |
| Email | School contact email | Email | No | Confidential |
| Phone Numbers | Up to two landlines | Phone | No | Internal |
| WhatsApp Number | WhatsApp contact | Phone | No | Confidential |
| Address | Full postal address with city and pincode | Composite | Partial | Public |
| Location (GPS) | Latitude and longitude | Decimal pair | No | Public |
| Instruction Language | Primary language of instruction (config-driven) | Lookup | No | Internal |
| Locale | Regional locale for number/date formatting | Selection | Yes | Internal |
| Currency | Billing currency (default INR) | Selection | Yes | Internal |
| Established Date | Date school was founded | Date | No | Public |
| Active Status | Whether the school can be accessed by its staff | Toggle | Auto | Internal |
| Setup Status | Provisioning stage: Pending / Creating Database / Running Migrations / Creating Root User / Adding Organisation / Completed / Failed | System | Auto | Internal |
| Setup Progress | Percentage completion of provisioning (0–100) | Number | Auto | Internal |
| School Logo | School logo image (with small/medium/large variants) | Image | No | Public |

#### 1.5.3 Subscription Plan

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| Plan Code | Unique code (combined with version for uniqueness) | Short text | Yes | Internal |
| Plan Version | Incremental version number (0 = original) | Number | Yes | Internal |
| Plan Name | Human-readable name | Text | Yes | Internal |
| Description | Plan description for sales purposes | Text | No | Internal |
| Billing Cycle | Default recurrence: Monthly / Quarterly / Yearly / One-Time | Lookup | Yes | Internal |
| Monthly Price | Per-month price | Currency | No | Confidential |
| Quarterly Price | Per-quarter price | Currency | No | Confidential |
| Yearly Price | Annual price | Currency | No | Confidential |
| Currency | Price currency | Selection | Yes | Internal |
| Trial Days | Number of free trial days | Number | Yes | Internal |
| Included Modules | List of application modules included in this plan | Multi-select | Yes | Internal |
| Active Status | Whether the plan is available for new assignments | Toggle | Yes | Internal |

#### 1.5.4 Subscription Rate Card (per school-plan)

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| Start Date | Subscription validity start | Date | Yes | Internal |
| End Date | Subscription validity end | Date | Yes | Internal |
| Billing Cycle | Recurrence for this subscription | Lookup | Yes | Internal |
| Monthly Rate | Base monthly charge | Currency | Yes | Confidential |
| Rate Per Cycle | Charge per billing period | Currency | Yes | Confidential |
| Minimum Billing Quantity | Minimum chargeable licences | Number | Yes | Internal |
| Discount Percentage / Amount | Negotiated discount | Decimal / Currency | No | Confidential |
| Discount Remark | Reason for discount | Short text | No | Internal |
| Extra Charges / Remark | Any additional charges and their reason | Currency / text | No | Confidential |
| Tax 1–4 Percentage / Remark | Up to four configurable tax types (e.g., GST, IGST) with rates | Decimal / text | No | Internal |
| Credit Days | Days from invoice date before payment is due | Number | Yes | Internal |

#### 1.5.5 Billing Schedule Entry

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| School | Which school this schedule belongs to | Reference | Yes | Internal |
| Billing Period Start | Start of the billed period | Date | Yes | Internal |
| Billing Period End | End of the billed period | Date | Yes | Internal |
| Invoice Generation Date | Date the invoice should be created | Date | Yes | Internal |
| Invoice Generated | Whether an invoice has been produced for this entry | Boolean | Yes | Internal |
| Generated Invoice | Reference to the invoice once created | Reference | No | Internal |
| Active Status | Whether this schedule entry is current (soft-deactivated on re-assignment) | Toggle | Yes | Internal |

#### 1.5.6 Platform Invoice

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| Invoice Number | Unique invoice reference | Auto-generated | Yes | Confidential |
| School | School this invoice is for | Reference | Yes | Internal |
| Invoice Date | Date invoice was generated | Date | Yes | Internal |
| Payment Due Date | Invoice date + credit days from rate card | Computed | Yes | Internal |
| Sub-total | Base amount before adjustments | Currency | Yes | Confidential |
| Discount Amount | Applied discount | Currency | Yes | Confidential |
| Extra Charges | Any additional fees | Currency | Yes | Confidential |
| Tax Amounts (1–4) | Applicable tax breakdowns | Currency | Yes | Confidential |
| Net Payable Amount | Sub-total − discount + extra charges + taxes | Computed | Yes | Confidential |
| Status | Payment status: Pending / Paid / Overdue / Cancelled | Workflow | Yes | Internal |
| Modules Billed | List of modules active during this billing period | List | Yes | Internal |

#### 1.5.7 Platform User

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| Full Name | Platform staff member's name | Text | Yes | Internal |
| Email Address | Login email (unique) | Email | Yes | Confidential |
| Employee Code | Internal HR identifier | Short text | No | Internal |
| Phone / Mobile | Contact numbers | Phone | No | Internal |
| Short Name | Abbreviated name for display | Short text | No | Internal |
| Active Status | Whether the user can log in | Toggle | Yes | Internal |
| Assigned Roles | Platform RBAC roles held by this user | Multi-select | No | Internal |
| Two-Factor Auth Enabled | Whether 2FA is required for this user | Toggle | Yes | Internal |

#### 1.5.8 Academic Session

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| Session Name | Human-readable name (e.g., "2025–2026") | Text | Yes | Public |
| Start Date | Session start date | Date | Yes | Internal |
| End Date | Session end date | Date | Yes | Internal |
| Current Session | Whether this is the active session platform-wide | Boolean (one only) | Yes | Internal |

---

### 1.6 Workflows

#### Workflow 1 — School Onboarding and Database Provisioning

**Trigger:** Platform Manager submits the Create School form.
**End States:** Setup Completed (school ready for plan assignment) | Setup Failed (manual re-trigger required)
**Actors / Swimlanes:** Platform Manager | System (web) | Queue Worker | Laravel Mail

| Step | Actor | Action / System Response |
|------|-------|--------------------------|
| 1 | Platform Manager | Fills and submits the Create School form |
| 2 | System | Validates form data against business rules |
| 3 | System | Creates school record (status: Pending, active: Inactive) and school domain record |
| 4 | System | Dispatches Database Provisioning task to the queue |
| 5 | System | Sends welcome email to school's registered email address |
| 6 | System | Sends "New School Registered" notification to all Super Admins |
| 7 | System | Writes activity log entry; redirects admin to Setup Progress view |
| 8 | Queue Worker | Stage 1 — Creates isolated school database (0%→5%) |
| 9 | Queue Worker | Stage 2 — Runs all application migrations in school database (5%→88%, progress updated per migration) |
| 10 | Queue Worker | Stage 3 — Creates root administrator user in school database (88%→93%) |
| 11 | Queue Worker | Stage 4 — Creates initial organisation record in school database (93%→99%) |
| 12 | Queue Worker | Sets progress to 100%, status to Completed; sends "Setup Completed" notification to Super Admins |
| 13 | Platform Manager | (Monitoring): Setup Progress view polls the status endpoint; on "Completed" the admin proceeds to plan assignment |

**Exception Paths:**
- At any stage (8–12): if an error occurs, status is set to Failed, progress is frozen at the last percentage, and a "Setup Failed" notification is sent to Super Admins. A re-trigger option must be provided (currently missing — ENH-PRM-001).
- If the queue worker is offline: task remains queued; progress stays at 0% until the worker processes it.

**Notifications Triggered:**

| Step | Recipient | Channel | Content |
|------|-----------|---------|---------|
| 5 | School email address | Email | Welcome to Prime-AI; your school is being set up |
| 6 | All Super Admins | In-app notification | New school registered: [School Name] |
| 12 | All Super Admins | In-app notification | School [Name] setup completed |
| Exception | All Super Admins | In-app notification | School [Name] setup failed at stage [N] |

---

#### Workflow 2 — Plan Subscription and Billing Schedule

**Trigger:** Platform Manager opens the Complete Setup / Plan Assignment screen and submits the plan assignment form.
**End States:** Plan Assigned and Billing Schedule Generated | Error (full rollback, no partial state)
**Actors / Swimlanes:** Platform Manager | System

| Step | Actor | Action / System Response |
|------|-------|--------------------------|
| 1 | Platform Manager | Selects plan, billing cycle, subscription period, rate card, taxes, discount, modules, credit days |
| 2 | System | Validates form; resolves the current active academic session |
| 3 | System | Clamps the billing window to the academic session bounds |
| 4 | System | Begins database transaction — Step 1: records or updates the plan subscription link |
| 5 | System | Step 2: creates the rate card with pricing, discounts, and taxes |
| 6 | System | Step 3: soft-deactivates existing module entries; creates new active module entries |
| 7 | System | Step 4: soft-deactivates existing billing schedule entries; generates new schedule |
| 8 | System | Commits transaction; redirects with success message |

**Exception Path:** If any step (4–7) fails, the transaction rolls back. The school's subscription state is fully restored to its pre-submission condition.

---

#### Workflow 3 — Automated Invoice Generation

**Trigger:** Scheduled command runs (intended: daily).
**End States:** All qualifying billing schedule entries have produced invoices | No qualifying entries found (no action)

| Step | Actor | Action |
|------|-------|--------|
| 1 | System (scheduler) | Queries all billing schedule entries where generation date ≤ today AND invoice not yet generated AND entry is active |
| 2 | System | For each qualifying entry: computes invoice amounts (sub-total, taxes, discount, net payable) |
| 3 | System | Creates platform invoice record; records which modules were active during the billing period |
| 4 | System | Marks the billing schedule entry as "invoice generated" and links the invoice |
| 5 | System | Logs outcome; continues to next entry on individual error |

**Exception Path:** If the command has never been created, step 1 never runs and invoices are never generated — this is the current state (ENH-PRM-004).

---

#### Workflow 4 — Platform Role Permission Assignment

**Trigger:** Super Admin saves role with updated permission selections.
**End States:** Role's permission set updated; users with that role immediately reflect new permissions

| Step | Actor | Action |
|------|-------|--------|
| 1 | Super Admin | Opens role edit screen; selects or deselects permissions (individually or in bulk) |
| 2 | System | Calls permission sync operation on the role |
| 3 | System | Replaces role's full permission set with the new selection |
| 4 | System | All subsequent requests from users holding this role reflect the new permission set |

---

### 1.7 Reporting and Analytics

| Report ID | Name | Purpose | Audience | Frequency | Filters | Export |
|-----------|------|---------|---------|-----------|---------|--------|
| RPT-PRM-001 | Monthly Revenue Trend | Show invoiced vs collected revenue for the last 12 months as a bar chart | Platform Finance, Super Admin | On dashboard load | None (fixed 12-month window) | No (chart only) |
| RPT-PRM-002 | School Registration Trend | Show count of new schools registered per month for the last 12 months | Super Admin, Platform Manager | On dashboard load | None | No (chart only) |
| RPT-PRM-003 | Overdue Invoice List | List invoices whose payment due date has passed and which are not yet paid, sorted by overdue age | Platform Finance, Super Admin | On dashboard load (top 10) | None at dashboard; full list available in Billing module | No (dashboard widget) |
| RPT-PRM-004 | Tenant Onboarding Status Report | List all schools with their current setup status and progress percentage | Platform Manager, Super Admin | On demand | Setup status, School Group | No |
| RPT-PRM-005 | Activity Audit Log | Filterable log of all state-changing actions across the Prime module with actor, timestamp, target, and action description | Super Admin, Platform Manager | On demand | Date range, action type, user | No (planned) |

---

### 1.8 Future Enhancement Log

| ENH ID | Enhancement | Rationale | Prerequisite |
|--------|-------------|-----------|--------------|
| ENH-PRM-001 | Re-trigger Failed Setup: add a "Re-trigger Database Setup" button on the Setup Progress view when setup status is "Failed"; dispatches a new provisioning task after resetting status to "Pending" | Currently admins have no self-service recovery from a failed provisioning; manual DB intervention is required | REQ-PRM-001 (core flow working) |
| ENH-PRM-002 | Secure Root Password Generation: replace hardcoded default password in provisioning Stage 3 with a randomly generated 16-character password; email it to the school's address on setup completion | A hardcoded default password is a critical security risk — all provisioned schools share the same initial password | REQ-PRM-001 |
| ENH-PRM-003 | Plan Version Management UX: when a plan is edited, present a choice between "Update Current Version" (for minor corrections) and "Create New Version" (for pricing or module changes) | BR-PRM-012 requires new versions on meaningful edits; currently no enforcement exists | REQ-PRM-003 |
| ENH-PRM-004 | Invoice Generation Scheduled Command: create the `prime:generate-invoices` artisan command; schedule it to run daily via the scheduler | REQ-PRM-005 cannot function until this command is built — currently the billing schedule entries never produce invoices | REQ-PRM-005 |
| ENH-PRM-005 | Two-Factor Authentication: implement the full 2FA flow for platform users using the existing `two_factor_auth_enabled` flag | Current state: flag exists in schema and user model but 2FA logic is not built | REQ-PRM-006 |
| ENH-PRM-006 | Dashboard Query Caching: cache the revenue totals, monthly trend, and school registration trend with a 15-minute TTL; invalidate on invoice creation or plan assignment | Dashboard currently executes ~15 inline queries; at scale this creates significant page-load latency | REQ-PRM-011 |
| ENH-PRM-007 | Explicit Tenant Activation Gate: after setup completes AND plan is assigned, require an explicit "Activate School" step that sends a welcome email with the school's subdomain URL and root credentials, then sets active status to true | Currently `is_active` can be set manually without verifying that both setup and plan assignment are complete | REQ-PRM-001, REQ-PRM-004 |
| ENH-PRM-008 | Tenant Creation Service Refactoring: extract school creation logic from `TenantController::store()` into a dedicated `TenantCreationService`; consolidate duplicate billing logic from `updateTenantPlan()` into `TenantPlanAssigner::assign()` | Two parallel implementations of the same logic diverge over time, creating maintenance risk and blocking unit testing | REQ-PRM-001, REQ-PRM-004 |

---

### 1.9 Non-Functional Requirements

#### 1.9.1 Performance

- The platform dashboard must load within 3 seconds under normal load. Cache aggregate queries (revenue totals, trend data) with at minimum a 15-minute TTL. (Current state: all ~15 queries execute inline — P2 enhancement.)
- The setup status polling endpoint must respond within 500 ms as it only performs a single database read.
- The database provisioning task must be allocated a 600-second timeout; the queue worker must have at least 512 MB available memory to run ~600 tenant migrations.

#### 1.9.2 Security

- **P0:** Database credentials in the school domain record must be encrypted at rest using Laravel's encrypted cast. All existing records must be re-encrypted on deployment.
- **P0:** The "Super Admin" flag must not be settable via any web interface or API; only via a protected artisan command with an explicit `--confirm` flag and activity log entry.
- **P0:** The `getPermissions()` endpoint must require authentication and the "View Role Permissions" permission before returning any data.
- **P1:** All state-changing controller actions must use `$request->validated()`, not `$request->all()`, to prevent mass assignment attacks.
- **P1:** Test and debug routes must be removed from production or gated to local/staging environments.
- **P1:** The complete tenant setup action must use the correct "Manage Tenant" permission gate, not "Manage Tenant Group".
- Platform routes are accessible only on the central management domain; school subdomain requests never reach Prime routes.
- All sensitive credential values in settings (SMTP passwords, SMS keys) must not be returned in plain text to the browser.

#### 1.9.3 Usability

- Setup progress view must provide real-time feedback (polling interval ≤ 5 seconds) so a Platform Manager does not need to manually refresh the page.
- When a delete action is blocked by an active dependency (e.g., School Group with schools), the error message must be in plain business language; database constraint messages must not be shown to the user.
- All form validation errors must be shown adjacent to the field that failed.

---

### 1.10 Gap Analysis Readiness Index

#### 1.10.1 Requirement Coverage Table

| REQ ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|--------|---------|---------|------|:-----------------:|:-------------:|:----------:|:-------------------:|:----------------:|
| REQ-PRM-001 | School Registration and Provisioning | P0 | WORKFLOW, DATA_ENTRY, INTEGRATION | Yes (prm_tenant, prm_tenant_domains) | Yes | Yes (setup-status polling) | Yes (3 notifications) | Yes |
| REQ-PRM-002 | School Group Management | P0 | DATA_ENTRY | Yes (prm_tenant_groups) | Yes | No | Yes (group created email) | Yes |
| REQ-PRM-003 | Subscription Plan Catalogue | P0 | CONFIGURATION, DATA_ENTRY | Yes (prm_plans, prm_module_plan_jnt, prm_billing_cycles) | Yes | No | No | Yes |
| REQ-PRM-004 | Plan Assignment and Billing Schedule | P0 | WORKFLOW, DATA_ENTRY, INTEGRATION | Yes (prm_tenant_plan_jnt, prm_tenant_plan_rates, prm_tenant_plan_module_jnt, prm_tenant_plan_billing_schedule) | Yes | No | No | Yes |
| REQ-PRM-005 | Billing Invoice Pipeline | P1 | SCHEDULED, WORKFLOW, INTEGRATION | Yes (bil_tenant_invoices, bil_tenant_invoicing_modules_jnt) | No | No | No | Yes |
| REQ-PRM-006 | Central Platform Authentication | P0 | WORKFLOW | No | Yes | No | No | Yes |
| REQ-PRM-007 | Central Staff User Management | P0 | DATA_ENTRY | Yes (sys_users) | Yes | No | Yes (login email) | Yes |
| REQ-PRM-008 | Role and Permission Management | P0 | CONFIGURATION | Yes (sys_roles, sys_permissions) | Yes | Yes (permission toggle endpoints) | No | Yes |
| REQ-PRM-009 | Global Reference Data Management | P0 | CONFIGURATION, DATA_ENTRY | Yes (sys_dropdown_table, sys_dropdown_needs, glb_boards, sys_academic_sessions) | Yes | No | No | Yes |
| REQ-PRM-010 | Platform Settings | P0 | CONFIGURATION | Yes (sys_settings) | Yes | No | No | Yes |
| REQ-PRM-011 | Platform Dashboard and Analytics | P1 | DASHBOARD, REPORT | No (reads existing) | Yes | No | No | Yes |
| REQ-PRM-012 | Activity Log and Monitoring | P1 | REPORT | Yes (sys_activity_logs) | Yes | No | No | Yes |

#### 1.10.2 Business Rule Coverage

| BR ID | Rule Summary | Enforced in Code | Gap |
|-------|-------------|:----------------:|-----|
| BR-PRM-001 | School access: active + plan | Yes | None |
| BR-PRM-002 | One active subscription per school-plan | Yes (DB constraint) | None |
| BR-PRM-003 | Active session required for plan assignment | Yes | None |
| BR-PRM-004 | Billing window clamped to session | Partial (controller only, not service) | Gap: not enforced in TenantPlanAssigner |
| BR-PRM-005 | Soft-deactivate modules on re-assignment | Yes | None |
| BR-PRM-006 | Database password encrypted at rest | NOT ENFORCED | P0 gap |
| BR-PRM-007 | Super Admin flag not via web form | NOT ENFORCED | P0 gap |
| BR-PRM-008 | Setup task runs once | Yes ($tries=1) | Re-trigger UI missing |
| BR-PRM-009 | Secure root password | NOT ENFORCED | P0 gap (hardcoded) |
| BR-PRM-010 | Tenant model interfaces | Yes | None |
| BR-PRM-011 | Allowed module list via intersection | Yes | None |
| BR-PRM-012 | Plan edit creates new version | NOT ENFORCED | P1 gap |
| BR-PRM-013 | Correct permission gate for setup completion | INCORRECT | P1 bug |
| BR-PRM-014 | Group delete blocked by active schools | Partial (DB RESTRICT; no friendly message) | P1 gap |
| BR-PRM-015 | Billing cycle determines schedule entries | Yes | None |
| BR-PRM-016 | Invoice generated flag prevents duplicates | Partially (logic exists, command missing) | P1 — command not built |
| BR-PRM-017 | Payment due date = invoice date + credit days | Yes (DDL computed) | None |
| BR-PRM-018 | Test routes removed in production | NOT ENFORCED | P1 gap |
| BR-PRM-019 | Login email on user creation | Yes | None |
| BR-PRM-020 | getPermissions requires auth | NOT ENFORCED | P0 gap |
| BR-PRM-021 | One current academic session | Partial | Verify toggle logic is atomic |
| BR-PRM-022 | Settings search requires permission | NOT ENFORCED | P2 gap |
| BR-PRM-023 | Activity log for all state-changing actions | Partial (create only) | P1 gap for update/delete/plan-change |

#### 1.10.3 Report Coverage

| RPT ID | Report | Implemented |
|--------|--------|:-----------:|
| RPT-PRM-001 | Monthly Revenue Trend | Yes (dashboard) |
| RPT-PRM-002 | School Registration Trend | Yes (dashboard) |
| RPT-PRM-003 | Overdue Invoice List | Yes (dashboard top-10) |
| RPT-PRM-004 | Tenant Onboarding Status Report | Partial (list + status visible; no export) |
| RPT-PRM-005 | Activity Audit Log | Yes (filter view) |

#### 1.10.4 Summary Totals

| Metric | Count |
|--------|------:|
| Functional Requirements | 12 |
| Core (P0) | 9 |
| Standard (P1) | 3 |
| Enhanced (P2) | 0 |
| Business Rules | 23 |
| Reports (RPT) | 5 |
| Enhancements (ENH) | 8 |
| Workflows | 4 |
| FSMs | 3 |
| User Stories | 12 |

---

<a id="section-2"></a>
## Section 2 — Requirements Traceability Matrix (RTM)

| REQ ID | Feature | BR Refs | Key Screens | Workflow | Reports | Code Status | Gap |
|--------|---------|---------|-------------|---------|---------|-------------|-----|
| REQ-PRM-001 | School Registration and Provisioning | BR-001,006,009,010 | Create Tenant, Setup Progress | WF-1 | RPT-004 | PARTIAL (P0 security bugs open) | db_password plaintext; hardcoded root password; no re-trigger |
| REQ-PRM-002 | School Group Management | BR-014 | Tenant Group list, create, edit | — | — | DONE | Friendly error message on delete with active schools missing |
| REQ-PRM-003 | Subscription Plan Catalogue | BR-012,015 | Plans & Modules list | — | — | PARTIAL | Plan versioning not enforced |
| REQ-PRM-004 | Plan Assignment and Billing Schedule | BR-002,003,004,005,013 | Complete Setup, Assign Plan | WF-2 | — | PARTIAL | Billing window clamping only in controller, not in service; wrong Gate on completeTenantSetup |
| REQ-PRM-005 | Billing Invoice Pipeline | BR-016,017 | (Dashboard – display only) | WF-3 | RPT-001,003 | NOT STARTED | GenerateInvoicesCommand does not exist |
| REQ-PRM-006 | Central Platform Authentication | BR-018 | Login, Logout | — | — | PARTIAL | Test routes accessible in production |
| REQ-PRM-007 | Central Staff User Management | BR-007,019 | User list, create, edit | — | — | PARTIAL | is_super_admin in $fillable; usersByRole stub |
| REQ-PRM-008 | Role and Permission Management | BR-020 | Role list, create, edit | WF-4 | — | PARTIAL | getPermissions has no auth gate; destroy() calls save() not delete |
| REQ-PRM-009 | Global Reference Data Management | BR-003,021 | Boards, Sessions, Dropdowns, Menus | — | — | DONE | Duplicate route registrations (RT-01) |
| REQ-PRM-010 | Platform Settings | BR-022 | Settings list, create, edit | — | — | PARTIAL | Search endpoint has no auth gate |
| REQ-PRM-011 | Platform Dashboard | — | Dashboard | — | RPT-001,002,003 | DONE (with stubs) | ~15 inline queries; sub-dashboards are stubs |
| REQ-PRM-012 | Activity Log and Monitoring | BR-023 | Activity log list | — | RPT-005 | PARTIAL | Not all state-changing operations log activity |

---

<a id="section-3"></a>
## Section 3 — Business Rules Register + Requirement Conditions + Validation Catalog

### 3.1 Standalone Business Rules Register

See Section 1.4 for the full BR-PRM-001 through BR-PRM-023 register with type, trigger, and enforcement details.

### 3.2 Requirement Conditions Catalog

*(Conditions derived from business rules; keyed to BR IDs)*

| Condition ID | Entity / Field | Condition (business statement) | Type | Trigger | On-Violation Behaviour |
|-------------|----------------|-------------------------------|------|---------|------------------------|
| BR-PRM-001 | School record | School must be active AND have at least one active plan subscription | Permission | Every school subdomain request | Request blocked; tenant access denied |
| BR-PRM-002 | Plan subscription | Only one active subscription per school per plan allowed | Validation | Plan assignment | Duplicate prevented via database constraint; business-language error shown |
| BR-PRM-003 | Academic session | One active academic session must be marked as current | Validation | Plan assignment initiation | Plan assignment blocked; error: "No active academic session found" |
| BR-PRM-004 | Billing window | Billing start and end must overlap with the active academic session | Calculation | Schedule generation | If no overlap: warning returned; no schedule entries created |
| BR-PRM-005 | Module entries | On plan re-assignment, old module entries must be set inactive before new ones are added | Workflow | Plan re-assignment | Old entries soft-deactivated; new entries created |
| BR-PRM-006 | db_password field | Database password field must be stored in encrypted form | Validation | Record create / update | Plaintext storage blocked (currently NOT enforced — P0 gap) |
| BR-PRM-007 | is_super_admin field | Super Admin flag must not be in web form or API request payload | Permission | Any user create or update | Field ignored / blocked; never persisted via web |
| BR-PRM-009 | Root user password | Provisioning must not use a hardcoded default password for the root user | Validation | Provisioning Stage 3 | Hardcoded password blocked; random password generated (currently NOT enforced — P0 gap) |
| BR-PRM-012 | Plan version | Plan edits must create a new version row, not overwrite | Validation | Plan update action | Overwrite blocked; new version row created (currently NOT enforced — P1 gap) |
| BR-PRM-014 | School Group delete | Group cannot be deleted while it has associated schools | Validation | Group delete action | Delete blocked; business-language message shown |
| BR-PRM-020 | getPermissions endpoint | Must authenticate and authorise before returning permission data | Permission | Role permissions API call | 403 returned if unauthenticated or unauthorised (currently NOT enforced — P0 gap) |
| BR-PRM-021 | Academic session current flag | Only one session may be current at a time | Validation | Session current-flag update | Previous session's flag cleared atomically |
| BR-PRM-023 | Activity log entry | All state-changing operations must produce a log entry | Workflow | Create / update / delete / plan assignment / status change | Log entry created; action proceeds regardless of log success |

### 3.3 Validation and Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|-------------|---------------|-----------------|----------|-------------|------------------|--------------------|
| School Code | "GRN" | Duplicate code "GRN" | 20-char max | Empty — blocked | Two admins create same code simultaneously | Unique constraint: second save fails with validation error |
| School Group Short Name | "GRN-TRUST" | Duplicate "GRN-TRUST" | 50-char max | Empty — blocked | Two admins create same short name | Unique constraint: second save fails |
| db_password storage | Encrypted cipher text | Plaintext "mysecret" | N/A | Not null — required | N/A | Model cast must produce encrypted value before persist |
| Plan Assignment transaction | All 5 steps succeed | Failure at Step 3 | N/A | N/A | Two admins assign plans to same school simultaneously | Transaction rollback on failure; DB constraint prevents duplicate active subscription |
| Billing window clamp | Window overlaps session: valid entries generated | Window entirely outside session | Window start = session end date (zero entries) | N/A | N/A | Empty window: warning shown, no entries created |
| is_super_admin in form | Field absent from form | Form includes is_super_admin=1 | N/A | Field absent | N/A | Field ignored; not persisted from web request |
| Current academic session | Exactly one marked current | Two marked current | One session with same start+end as existing | No current session | Two admins mark different sessions current simultaneously | Atomic update; one succeeds, other fails or is overwritten |
| getPermissions endpoint | Authenticated user with permission | Unauthenticated request | N/A | N/A | N/A | 401/403 response; no data returned |
| Root user creation | Random 16-char password generated | Hardcoded "password" string | N/A | N/A | N/A | Provisioning fails if default password pattern detected (currently not enforced) |
| Plan version on edit | New row version=1 created | Overwrite of version=0 row | Version field = MAX(existing)+1 | N/A | Two admins edit same plan simultaneously | Last writer creates new version; both new versions exist (no loss) |
| Invoice generation date | Date ≤ today, invoice not yet generated | Date in the future | Generation date = today | No qualifying entries | Two command runs overlap | Idempotent: "invoice generated" flag prevents double invoicing |

---

<a id="section-4"></a>
## Section 4 — Process Flows + FSM Catalog

### 4.1 Process Flows

See Section 1.6 for the four detailed workflow definitions:
- Workflow 1: School Onboarding and Database Provisioning
- Workflow 2: Plan Subscription and Billing Schedule
- Workflow 3: Automated Invoice Generation
- Workflow 4: Platform Role Permission Assignment

### 4.2 FSM Catalog

#### FSM-PRM-001 — School (Tenant) Setup Status

**Entity:** School Setup Status | **Driven by:** `setup_status` field on School record

| From State | Event / Action | Guard Condition | To State | Side Effects |
|-----------|----------------|-----------------|----------|--------------|
| (New record) | Admin submits Create School form | Form validated | Pending | Domain record created; provisioning task dispatched; welcome email sent |
| Pending | Provisioning task begins Stage 1 | Task dequeued by worker | Creating Database | Progress: 0%→5% |
| Creating Database | Stage 1 complete | Database created successfully | Running Migrations | Progress advances per migration |
| Running Migrations | All migrations complete | ~600 migrations succeeded | Creating Root User | Progress: 88% |
| Creating Root User | Root user created | User created in school DB | Adding Organisation | Progress: 93% |
| Adding Organisation | Organisation record created | Org record created in school DB | Completed | Progress: 100%; Super Admin notified |
| Any intermediate state | Unhandled exception in task | Error thrown | Failed | Progress frozen; failure notification sent |
| Failed | Admin re-triggers setup | Admin action on re-trigger UI (ENH-PRM-001) | Pending | Status reset; new task dispatched |
| Completed | Admin assigns plan and activates | Plan assigned AND is_active set | (School becomes Accessible) | School can be accessed on its subdomain |
| Accessible | Admin deactivates school | Admin toggle action | Inactive | School subdomain returns 403 |
| Inactive | Admin reactivates | Admin toggle action | Accessible | Subdomain resumes serving |

**Terminal states:** Failed (until re-triggered), Completed (setup complete, awaiting plan)
**Illegal transitions:** Jumping from Pending directly to Completed without running all stages; setting is_active=true while setup_status ≠ 'completed'

---

#### FSM-PRM-002 — Plan Subscription Status

**Entity:** Plan Subscription | **Driven by:** `status` field on Plan Subscription record

| From State | Event / Action | Guard | To State | Side Effects |
|-----------|----------------|-------|----------|--------------|
| (New) | Plan assigned to school | Transaction commits | Active | Module list activated; billing schedule generated |
| Active | Admin suspends school | Admin action | Suspended | School loses module access |
| Active | Plan end date reached or cancelled | Date check or admin action | Expired / Cancelled | Module access removed |
| Suspended | Admin reinstates | Admin action + valid plan | Active | Module access restored |
| Expired / Cancelled | New plan assigned | Plan assignment transaction | Active (new subscription) | New module list and billing schedule |

**Terminal states:** Cancelled (permanent unless re-subscribed)
**Illegal transitions:** Jumping from Cancelled to Active without a new plan assignment

---

#### FSM-PRM-003 — Billing Schedule Entry Status

**Entity:** Billing Schedule Entry | **Driven by:** `bill_generated` flag and `is_active` flag

| From State | Event / Action | Guard | To State | Side Effects |
|-----------|----------------|-------|----------|--------------|
| Active / Not Generated | Scheduled command runs; generation date reached | `generation_date ≤ today AND bill_generated = false AND is_active = true` | Active / Generated | Invoice created; entry linked to invoice |
| Active / Not Generated | Plan re-assigned | Plan assignment transaction | Inactive | Soft-deactivated; new schedule created |
| Active / Generated | Invoice paid | Payment recorded via Billing module | (no change to schedule; change on invoice) | Invoice status → Paid |

**Terminal states:** Active/Generated + Associated invoice paid; or Inactive (soft-deactivated)

---

<a id="section-5"></a>
## Section 5 — Data Dictionary + Cross-Module Dependency Map

### 5.1 Data Dictionary (Business View)

See Section 1.5 for the full business-view data dictionary covering all eight key entities:
- 1.5.1 School Group
- 1.5.2 School (Tenant)
- 1.5.3 Subscription Plan
- 1.5.4 Subscription Rate Card
- 1.5.5 Billing Schedule Entry
- 1.5.6 Platform Invoice
- 1.5.7 Platform User
- 1.5.8 Academic Session

**Privacy Classification Summary:**

| Classification | Entities |
|---------------|---------|
| Public | School full name, established date, website, GPS location |
| Internal | Setup status, plan details, billing cycle, module lists, role assignments, academic sessions |
| Confidential | School email, school phone, database credentials, pricing, invoice amounts, tax details, user email |
| Sensitive (PII) | Platform user email, user phone number (internal staff PII) |

### 5.2 Technical Data Reference (Technical Artifact)

| Business Entity | Table(s) | DB Layer | Key Columns |
|----------------|---------|---------|-------------|
| School Group | `prm_tenant_groups` | prime_db | short_name (UNIQUE), city_id → glb_cities |
| School | `prm_tenant` | prime_db | code (UNIQUE), tenant_group_id → prm_tenant_groups, setup_status, setup_progress |
| School Domain | `prm_tenant_domains` | prime_db | domain, db_name, db_password (PLAINTEXT BUG), tenant_id → prm_tenant |
| Billing Cycle | `prm_billing_cycles` | prime_db | short_name (UNIQUE), months_count |
| Subscription Plan | `prm_plans` | prime_db | (plan_code, version) UNIQUE, billing_cycle_id |
| Plan-Module Map | `prm_module_plan_jnt` | prime_db | plan_id → prm_plans, module_id → glb_modules (VIEW — FK issue) |
| Plan Subscription | `prm_tenant_plan_jnt` | prime_db | current_flag (GENERATED STORED), UNIQUE(current_flag, plan_id) |
| Rate Card | `prm_tenant_plan_rates` | prime_db | tenant_plan_id → prm_tenant_plan_jnt, start_date, end_date |
| Licensed Modules | `prm_tenant_plan_module_jnt` | prime_db | module_id, tenant_plan_id, is_active |
| Billing Schedule | `prm_tenant_plan_billing_schedule` | prime_db | schedule_billing_date, bill_generated, generated_invoice_id → bil_tenant_invoices |
| Platform Invoice | `bil_tenant_invoices` | prime_db | invoice_number (UNIQUE), status, net_payable_amount |
| Invoice Modules | `bil_tenant_invoicing_modules_jnt` | prime_db | invoice_id, module_id |
| Invoice Payment | `bil_tenant_invoicing_payments` | prime_db | invoice_id, payment_date, amount |
| Platform User | `sys_users` | prime_db | email (UNIQUE), is_super_admin (guarded) |
| Platform Role | `sys_roles` | prime_db | Spatie Permission roles table |
| Permission | `sys_permissions` | prime_db | Spatie Permission permissions table |
| Dropdown Value | `sys_dropdown_table` | prime_db | dropdown_need_id → sys_dropdown_needs |
| Settings | `sys_settings` | prime_db | key, value key-value store |
| Activity Log | `sys_activity_logs` | prime_db | user_id, subject_type, subject_id, action |
| Academic Session | `sys_academic_sessions` | prime_db | start_date, end_date, is_current |

### 5.3 Cross-Module Dependency Map

**Inbound — Prime reads from / depends on:**

| Source | Entity | Why |
|--------|--------|-----|
| GlobalMaster | `glb_cities` | City FK for school and school group records |
| GlobalMaster | `glb_modules` | Module registry for plan-module mapping (NOTE: glb_modules is a VIEW — FK not reliably enforced) |
| GlobalMaster | `glb_boards` | Board management (Prime writes to this table via BoardController) |
| GlobalMaster | `glb_languages` | Language management (Prime writes) |
| GlobalMaster | `glb_menus` | Menu management (Prime writes) |
| stancl/tenancy v3.9 | Tenant infrastructure | Database isolation, domain routing, HasDatabase / HasDomains interfaces |
| Spatie Permission v6.21 | RBAC infrastructure | Role and permission management on sys_roles / sys_permissions |
| spatie/laravel-medialibrary | Media storage | School logo upload with size conversions |
| Laravel Queue | Job queue | SetupTenantDatabase async job dispatching |
| Laravel Mail | Mail | TenantRegisteredMail, TenantGroupCreatedMail, LoginMail |
| SchoolSetup module | RolePermissionRequest | RolePermissionController borrows this FormRequest — cross-module dependency to resolve (FRQ-01) |

**Outbound — Prime produces for other modules / consumers:**

| Target | Mechanism | What Is Provided |
|--------|-----------|-----------------|
| Billing module | Shared `bil_tenant_invoices` table | Billing schedule entries trigger invoice creation; Billing module records payment against these invoices |
| All 40+ tenant modules | Database provisioning job | Tenant database is created with all module migrations applied; root user and organisation seeded |
| All tenant modules | `prm_tenant_plan_module_jnt` | Controls which modules a school can access via `Tenant::allowedModuleIds()` |
| SystemConfig module | Shared tables (`sys_settings`, `sys_dropdown_table`, `sys_media`, `sys_activity_logs`) | Prime creates and manages these; SystemConfig reads them for platform configuration |
| All tenant modules | `sys_dropdown_table` | Dropdown value definitions shared across all school modules |
| All tenant modules | `sys_academic_sessions` | Current academic session consumed by plan assignment and many school features |

---

<a id="section-6"></a>
## Section 6 — NFR Catalog + Risk Register

### 6.1 NFR Catalog

| NFR ID | Category | Requirement | Acceptance Threshold | Priority |
|--------|----------|-------------|----------------------|---------|
| NFR-PRM-001 | Security | Database credentials in the School Domain record must be encrypted at rest using the encrypted cast | All records: db_password is cipher text, never plaintext; verified by model test | P0 |
| NFR-PRM-002 | Security | The "Super Admin" flag must not be settable via any web form or API request | Verified by penetration test: POST with is_super_admin=1 does not set the flag | P0 |
| NFR-PRM-003 | Security | Role permission endpoint must require authentication and authorisation before returning data | Verified: unauthenticated request returns 401; unauthorised returns 403 | P0 |
| NFR-PRM-004 | Security | All state-changing controller actions must use validated() not request->all() | Zero instances of request->all() used in model updates across the module | P1 |
| NFR-PRM-005 | Security | Test and debug routes must not be reachable in production | Verified: test-email, send-test-email, test-notification return 404 on production env | P1 |
| NFR-PRM-006 | Security | Completing tenant setup must require the correct "Manage Tenant" permission | Verified: request without prime.tenant.update returns 403 | P1 |
| NFR-PRM-007 | Security | All sensitive credential values stored in settings (SMTP password, API keys) must not be returned in plain text in responses | SMTP password field masked in view output | P1 |
| NFR-PRM-008 | Performance | Platform dashboard page load time | < 3 seconds on production with ≤ 500 school tenants | P2 |
| NFR-PRM-009 | Performance | Setup status polling endpoint response time | < 500 ms; single DB read only | P1 |
| NFR-PRM-010 | Scalability | Database provisioning job memory and timeout | Queue worker: ≥ 512 MB RAM; job timeout: 600 seconds | P1 |
| NFR-PRM-011 | Reliability | Invoice generation command must be idempotent | Running the command twice for the same date produces no duplicate invoices | P1 |
| NFR-PRM-012 | Isolation | Central domain routes must be inaccessible from any school subdomain | Verified: request from school subdomain to /dashboard returns 404 or redirect | P0 |
| NFR-PRM-013 | Audit | All state-changing operations must be recorded in the activity log | Activity log entry created within 1 second of each state-changing action | P1 |
| NFR-PRM-014 | Code Quality | Billing logic must exist in one canonical location (TenantPlanAssigner service) | Zero duplicate billing logic between controller and service | P2 |
| NFR-PRM-015 | Code Quality | Billing model ownership must be consolidated to the Billing module | TenantInvoice model used in Prime imports from Billing module | P1 |
| NFR-PRM-016 | Usability | Setup progress view provides real-time feedback without manual page refresh | Polling interval ≤ 5 seconds; progress percentage visible while provisioning runs | P1 |
| NFR-PRM-017 | Usability | Delete blocked by dependency shows business-language error | No database exception message is ever shown to the end user | P1 |

### 6.2 Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---------|------|---------|:----------:|:------:|------------|-------|
| RISK-PRM-001 | Database credentials (db_password) exposed via SQL dump, log leak, or application error output — giving attacker access to all school databases | Security | High | Critical | Encrypt immediately via Domain model encrypted cast; re-encrypt existing records; ensure credentials never appear in logs | Platform IT/Ops |
| RISK-PRM-002 | Super Admin flag set via mass assignment attack — attacker gains unconditional platform access | Security | Medium | Critical | Remove is_super_admin from $fillable; add model test to assert it is guarded | Platform IT/Ops |
| RISK-PRM-003 | Role permission endpoint leaks all role-permission assignments to any requester without authentication | Security | High | High | Add Gate::authorize() to getPermissions() immediately | Platform IT/Ops |
| RISK-PRM-004 | Test email and notification routes used to probe or spam in production | Security | Medium | Medium | Remove or gate to non-production environments | Platform Developer |
| RISK-PRM-005 | Invoice generation never runs — billing schedules accumulate without producing invoices; revenue is not invoiced | Business | High | High | Build GenerateInvoicesCommand and register in scheduler before go-live | Platform Manager |
| RISK-PRM-006 | Hardcoded root password on new school provisioning — every school shares the same initial admin password | Security | High | High | Replace with Str::password() in provisioning job before first production school onboarding | Platform Developer |
| RISK-PRM-007 | Failed tenant setup with no re-trigger UI — Platform Manager must use database-level intervention to recover a failed provisioning | Operations | Medium | Medium | Build re-trigger route and UI button (ENH-PRM-001) | Platform Developer |
| RISK-PRM-008 | Plan versioning not enforced — editing an existing plan overwrites historical subscription terms; billing accuracy undermined | Business | Medium | Medium | Implement version-on-edit logic in plan management controller | Platform Developer |
| RISK-PRM-009 | Duplicate billing logic in controller and service diverges — plan assignment behaviour differs depending on which code path is used | Architecture | Low | Medium | Refactor controller to delegate entirely to TenantPlanAssigner service | Platform Architect |
| RISK-PRM-010 | Route caching breaks after config:cache — env() in route domain definition causes all central routes to 404 | Operations | Medium | High | Ensure route domain uses config() not env(); run config:cache in CI pipeline to verify | DevOps |

---

<a id="section-7"></a>
## Section 7 — Prioritization + Effort Estimation

### 7.1 MoSCoW Prioritization

**Must Have (P0 — blockers for production):**

| Item | Rationale |
|------|-----------|
| REQ-PRM-001: School Registration and Provisioning | Core business operation; no school can be onboarded without it |
| REQ-PRM-002: School Group Management | Prerequisite for tenant creation |
| REQ-PRM-003: Subscription Plan Catalogue | Plans must exist before assignment |
| REQ-PRM-004: Plan Assignment and Billing Schedule | Revenue model depends on this |
| REQ-PRM-006: Central Platform Authentication | Platform unusable without authentication |
| REQ-PRM-007: Central Staff User Management | Needed to manage platform operators |
| REQ-PRM-008: Role and Permission Management | Access control for platform staff |
| REQ-PRM-009: Global Reference Data | All school modules depend on this data |
| REQ-PRM-010: Platform Settings | Email and communication services |
| BR-PRM-006 fix: Encrypt db_password | Security P0 — critical exposure |
| BR-PRM-007 fix: Guard is_super_admin | Security P0 — privilege escalation risk |
| BR-PRM-009 fix: Secure root password | Security P0 — all schools share default password |
| BR-PRM-020 fix: Auth on getPermissions | Security P0 — information disclosure |

**Should Have (P1 — needed before first customer billing):**

| Item | Rationale |
|------|-----------|
| REQ-PRM-005: Billing Invoice Pipeline | Revenue only flows when invoices are generated |
| REQ-PRM-011: Platform Dashboard | Operations visibility for Platform Manager |
| REQ-PRM-012: Activity Log | Audit compliance |
| ENH-PRM-004: GenerateInvoicesCommand | REQ-PRM-005 cannot work without it |
| ENH-PRM-001: Re-trigger failed setup | Ops recovery without DBA involvement |
| ENH-PRM-002: Secure root password delivery | P0 security hardening |
| BR-PRM-013 fix: Correct Gate on completeTenantSetup | Wrong permission gate — causes auth bypass for plan assignment |
| BR-PRM-018 fix: Remove test routes from production | Security hygiene |

**Could Have (P2 — enhancements):**

| Item | Rationale |
|------|-----------|
| ENH-PRM-006: Dashboard query caching | Performance improvement, not a blocker |
| ENH-PRM-003: Plan version management UX | Important for billing accuracy at scale |
| ENH-PRM-005: Two-factor authentication | Security enhancement |
| ENH-PRM-008: TenantCreationService refactoring | Architecture cleanup |
| ENH-PRM-007: Explicit activation gate | Better UX/process control |

**Won't Have This Release:**
- API-first school onboarding (no current requirement for external integrations)
- Automated plan renewal / dunning workflow (out of scope for V1)
- Self-service plan upgrade by school admin (only PrimeGurukul staff assign plans)

### 7.2 Effort Estimation and Sprint Task Breakdown

**Assumptions:** DDL largely exists. Migrations need DDL fixes. Backend work assumes Laravel 12, module structure already scaffolded.

| # | Task | Type | Effort (hours) | Depends On | Sprint |
|---|------|------|:--------------:|-----------|--------|
| 1 | Encrypt db_password: add encrypted cast to Domain model + expand DDL column to VARCHAR(500) + write one-time re-encryption migration | Security / Schema | 4 | — | S1 |
| 2 | Guard is_super_admin: remove from $fillable in User model + add model-level guarded protection + write unit test | Security / Backend | 3 | — | S1 |
| 3 | Create PromoteSuperAdmin artisan command with --confirm flag and activity log | Backend | 4 | Task 2 | S1 |
| 4 | Add Gate::authorize() to RolePermissionController::getPermissions() | Security / Backend | 2 | — | S1 |
| 5 | Gate test/debug routes to local/staging environments only | Security / Backend | 2 | — | S1 |
| 6 | Fix completeTenantSetup() Gate: change prime.tenant-group.update to prime.tenant.update | Bug Fix | 1 | — | S1 |
| 7 | Implement GenerateInvoicesCommand artisan command with idempotency | Backend | 8 | — | S1 |
| 8 | Register GenerateInvoicesCommand in scheduler (daily) | Backend | 1 | Task 7 | S1 |
| 9 | Replace hardcoded root password in SetupTenantDatabase with Str::password(16) | Security / Backend | 3 | — | S1 |
| 10 | Send setup-completed email to school with generated root credentials | Backend / Email | 3 | Task 9 | S1 |
| 11 | Add re-trigger route, controller action, and UI button for failed setup | Backend / Frontend | 6 | — | S2 |
| 12 | Implement plan versioning in plan management controller (new version row on edit) | Backend | 6 | — | S2 |
| 13 | Refactor TenantController::updateTenantPlan() to delegate entirely to TenantPlanAssigner | Refactoring | 5 | — | S2 |
| 14 | Move billing window clamp logic from controller into TenantPlanAssigner::assign() | Refactoring | 3 | Task 13 | S2 |
| 15 | Resolve RolePermissionController::destroy() stub — implement soft-delete properly | Bug Fix | 2 | — | S2 |
| 16 | Fix UserController::usersByRole() to actually filter by role | Bug Fix | 2 | — | S2 |
| 17 | Replace stub data in UserController::index() with real queries | Bug Fix | 2 | — | S2 |
| 18 | Remove stale duplicate Model file (Modules/Prime/Models/DropdownNeed.php) | Clean-up | 1 | — | S2 |
| 19 | Fix duplicate route registrations (RT-01): remove board/session/dropdown from prime. prefix, use global-master. | Routing | 3 | — | S2 |
| 20 | Fix DB-02: change prm_plans.billing_cycle_id to SMALLINT UNSIGNED | Schema / Migration | 2 | — | S2 |
| 21 | Fix DB-03: add deleted_at to prm_billing_cycles DDL | Schema / Migration | 1 | — | S2 |
| 22 | Fix DB-04: add is_active and created_by to prm_tenant_plan_rates | Schema / Migration | 2 | — | S2 |
| 23 | Fix DB-07: add created_by to prm_tenant_groups | Schema / Migration | 1 | — | S2 |
| 24 | Write feature test: TenantOnboardingTest — full create → job → progress → complete flow | Testing | 8 | — | S3 |
| 25 | Write feature test: SetupTenantDatabaseJobTest — 4 stages + failure at each | Testing | 8 | — | S3 |
| 26 | Write unit test: DomainEncryptionTest — verify db_password is stored encrypted | Testing | 3 | Task 1 | S3 |
| 27 | Write unit test: SuperAdminProtectionTest — is_super_admin not mass-assignable | Testing | 2 | Task 2 | S3 |
| 28 | Write feature test: TenantPlanAssignerTest — all 5 steps + rollback | Testing | 6 | Task 13 | S3 |
| 29 | Write unit test: BillingScheduleGenerationTest — date cursor and academic session clamping | Testing | 4 | Task 14 | S3 |
| 30 | Implement dashboard query caching with 15-minute TTL (ENH-PRM-006) | Performance | 4 | — | S4 |
| 31 | Consolidate TenantInvoice model ownership to Billing module | Architecture | 4 | — | S4 |
| 32 | Create TenantCreationService (extract from TenantController::store()) | Architecture | 5 | — | S4 |
| 33 | Implement 2FA flow for platform users (ENH-PRM-005) | Backend / Frontend | 16 | — | S5 |

**Total estimated effort:** ~130 hours across 5 sprints
**S1 — Security critical (P0 fixes):** ~31 hours
**S2 — Feature gaps and refactoring:** ~34 hours
**S3 — Test coverage:** ~31 hours
**S4 — Architecture cleanup:** ~13 hours
**S5 — Enhancements:** ~16+ hours

---

<a id="section-8"></a>
## Section 8 — User Stories + Acceptance Criteria + Reporting KPI Spec

### 8.1 User Stories

---

**US-PRM-001** | Priority: P0 | REQ ref: REQ-PRM-001

*As a Platform Manager, I want to register a new school and have its database automatically set up so that the school's IT team can start configuring their school without waiting for manual DBA work.*

Acceptance Criteria:
```
Scenario: Successful school registration and provisioning
  Given I am a Platform Manager with "Manage Tenants" permission
  When I submit a valid Create School form with all required fields
  Then the system creates the school record with Inactive status
  And dispatches the database provisioning task to the queue
  And sends a welcome email to the school's registered email address
  And redirects me to the Setup Progress view

Scenario: Provisioning completes successfully
  Given the provisioning task is processing a new school
  When all four stages complete without error
  Then the setup status shows "Completed" and progress shows 100%
  And a root administrator account exists in the school's database
  And all Super Admins receive a "Setup Completed" notification

Scenario: Provisioning fails at a stage
  Given the provisioning task encounters an error at Stage 2 (migrations)
  Then the setup status shows "Failed" and progress is frozen at last completed percentage
  And all Super Admins receive a "Setup Failed" notification
  And I see the setup progress frozen on the progress view

Scenario: Unauthorised access
  Given a user without "Manage Tenants" permission
  When they attempt to access the Create School form
  Then the system returns a 403 Access Denied response

Definition of Done:
  - School record created with correct initial status
  - Provisioning task dispatched to queue
  - Welcome email sent
  - Activity log entry created
  - All four provisioning stages implemented
  - Failure notification implemented
  - Progress polling endpoint returns correct status
```

---

**US-PRM-002** | Priority: P0 | REQ ref: REQ-PRM-002

*As a Platform Manager, I want to organise schools into groups so that I can manage school chains and trusts as a unit.*

Acceptance Criteria:
```
Scenario: Successful group creation
  Given I am a Platform Manager with "Manage School Groups" permission
  When I submit a valid Create Group form
  Then the group is created and a notification email is sent to the group's email address

Scenario: Delete blocked by active schools
  Given a group has at least one active school record
  When I attempt to delete that group
  Then the system shows a message: "This group has active schools and cannot be deleted"
  And no database error message is shown to me

Scenario: Unauthorised access
  Given a user without "Manage School Groups" permission
  When they attempt to create or edit a group
  Then the system returns 403
```

---

**US-PRM-003** | Priority: P0 | REQ ref: REQ-PRM-003

*As a Platform Manager, I want to define subscription plans with included modules and pricing so that I can offer the right tier to each school.*

Acceptance Criteria:
```
Scenario: New plan created
  Given I create a plan with billing cycle, pricing, and selected modules
  Then the plan is created at version 0 and the selected modules are recorded

Scenario: Plan edit creates new version
  Given an existing plan has schools subscribed to it
  When I edit the plan's pricing or module list
  Then a new version of the plan is created and the original version remains unchanged
  And existing school subscriptions still reference the original version

Scenario: Unauthorised access
  Given a user without "Manage Plans" permission
  When they attempt to create or edit a plan
  Then the system returns 403
```

---

**US-PRM-004** | Priority: P0 | REQ ref: REQ-PRM-004

*As a Platform Manager, I want to assign a subscription plan to a school so that the school gets access to their licensed modules and I can track their billing calendar.*

Acceptance Criteria:
```
Scenario: Successful plan assignment
  Given a school with completed setup and an active academic session
  When I assign a monthly plan from April 2025 to March 2026
  Then the system creates 12 billing schedule entries
  And the school's licensed module list is updated to match the plan
  And the transaction commits fully with no partial state

Scenario: Transaction rollback on failure
  Given a failure occurs during the plan assignment process
  Then all changes are rolled back and the school's subscription state is unchanged

Scenario: No active academic session
  Given no academic session is marked as current
  When I attempt to assign a plan
  Then the system shows: "No active academic session found" and blocks the assignment

Scenario: Billing window outside session
  Given the subscription period does not overlap with the academic session
  When I submit the plan assignment
  Then the system shows a warning and creates no billing schedule entries
```

---

**US-PRM-005** | Priority: P1 | REQ ref: REQ-PRM-005

*As a Platform Finance user, I want billing schedule entries to automatically generate invoices so that schools are invoiced without manual effort.*

Acceptance Criteria:
```
Scenario: Scheduled invoice generation
  Given billing schedule entries with generation dates on or before today
  When the invoice generation command runs
  Then an invoice is created for each qualifying entry
  And the entry is marked as "invoice generated"
  And the net payable amount equals sub-total minus discount plus extra charges plus taxes

Scenario: Idempotent run
  Given a billing schedule entry was already invoiced yesterday
  When the command runs again today
  Then no duplicate invoice is created for that entry

Scenario: Command does not exist
  Given the invoice generation command has not been built
  Then no invoices are ever automatically generated (current state — ENH-PRM-004 needed)
```

---

**US-PRM-006** | Priority: P0 | REQ ref: REQ-PRM-006

*As a Platform staff member, I want to log in securely to the central management console so that I can manage schools and platform settings.*

Acceptance Criteria:
```
Scenario: Successful login on central domain
  Given valid credentials on the central management website
  When I submit the login form
  Then I am authenticated and redirected to the platform dashboard

Scenario: School subdomain cannot access Prime login
  Given I am on a school subdomain (e.g., greenwood.primeai.app)
  When I try to access the Prime login page
  Then I reach the school's own login page, not Prime's

Scenario: Test routes inaccessible in production
  Given the platform is running in production environment
  When a request is made to the test email or test notification URLs
  Then the server returns 404 (routes not registered)
```

---

**US-PRM-007** | Priority: P0 | REQ ref: REQ-PRM-007

*As a Super Admin, I want to manage platform staff accounts so that only authorised PrimeGurukul employees can access the management console.*

Acceptance Criteria:
```
Scenario: New staff user created
  Given I create a new platform user
  Then the user receives an email with their login credentials
  And the user can log in immediately using those credentials

Scenario: Super Admin flag cannot be set via web form
  Given a form submission that includes is_super_admin=1
  When the request is processed
  Then the Super Admin flag is not set; the field value is ignored entirely

Scenario: Deleted user cannot log in
  Given a user has been soft-deleted
  When they attempt to log in
  Then authentication is rejected
  And their historical activity log entries remain intact
```

---

**US-PRM-008** | Priority: P0 | REQ ref: REQ-PRM-008

*As a Super Admin, I want to manage platform roles and their permission assignments so that I can control what each staff member can do on the platform.*

Acceptance Criteria:
```
Scenario: Permission toggled off for a role
  Given I remove the "Create Tenant" permission from a role
  Then users with that role can no longer access the Create School screen

Scenario: Role permission endpoint is secured
  Given an unauthenticated request to retrieve a role's permissions
  Then the system returns 401 or 403 — no permission data is returned

Scenario: Role deletion
  Given I delete a role
  Then the role is soft-removed and users who held it lose those permissions immediately
```

---

**US-PRM-009** | Priority: P0 | REQ ref: REQ-PRM-009

*As Platform IT/Ops, I want to manage boards, academic sessions, dropdowns, and menus so that all school modules have up-to-date reference data.*

Acceptance Criteria:
```
Scenario: Board deactivated
  Given I deactivate the "State Board" entry
  Then it no longer appears in school configuration dropdowns in any school

Scenario: New academic session marked current
  Given I mark 2025-26 as the current session
  Then any previous current-session flag is cleared
  And plan assignments can now proceed against the 2025-26 session

Scenario: Dropdown value added
  Given I add a new instruction language dropdown value
  Then it appears immediately in all school-level language dropdowns
```

---

**US-PRM-010** | Priority: P0 | REQ ref: REQ-PRM-010

*As Platform IT/Ops, I want to update platform settings so that email delivery and other integrations use the correct credentials.*

Acceptance Criteria:
```
Scenario: SMTP settings updated
  Given I update the SMTP host and credentials in settings
  Then the next outgoing email uses the new SMTP configuration

Scenario: Settings search is secured
  Given an unauthenticated request to the settings search endpoint
  Then the system returns 401 or 403
```

---

**US-PRM-011** | Priority: P1 | REQ ref: REQ-PRM-011

*As a Platform Manager, I want to see a dashboard with platform-wide statistics so that I can monitor the health of the business and identify issues quickly.*

Acceptance Criteria:
```
Scenario: Dashboard loads with accurate data
  Given I navigate to the platform dashboard
  Then all metric cards show current, accurate counts and monetary totals
  And no stub or hardcoded values appear in any card

Scenario: New school registration reflected in trend
  Given a new school was registered today
  When I view the dashboard
  Then the school registration trend chart shows one additional entry for today's month

Scenario: Overdue invoice appears in list
  Given an invoice's payment due date has passed and its status is not Paid
  When I view the dashboard
  Then that invoice appears in the Overdue Invoices list
```

---

**US-PRM-012** | Priority: P1 | REQ ref: REQ-PRM-012

*As a Super Admin, I want to view the activity log so that I can audit all significant actions taken by platform staff.*

Acceptance Criteria:
```
Scenario: Activity log entry created on school creation
  Given a Platform Manager creates a new school
  Then an activity log entry is recorded with: the acting user, the timestamp, and the school name

Scenario: Activity log access is secured
  Given a user without "View Activity Log" permission
  When they attempt to access the activity log
  Then the system returns 403
```

---

### 8.2 Reporting and KPI Spec

| KPI | Definition (business terms) | Source Data | Target | Cadence |
|-----|---------------------------|-------------|--------|---------|
| Total Active Schools | Count of school records with active status = true | School records | Growing month-over-month | Monthly |
| Monthly Recurring Revenue (MRR) | Sum of active subscription monthly rates across all active school subscriptions | Rate card records | Management target | Monthly |
| Invoice Collection Rate | (Total Paid invoice amount ÷ Total Invoiced amount) × 100 | Invoice records | ≥ 95% | Monthly |
| Overdue Invoice Value | Sum of net payable amount for all invoices with payment due date < today and status ≠ Paid | Invoice records | < 5% of MRR | Weekly |
| Setup Success Rate | (Schools with setup_status = 'completed' ÷ All schools ever created) × 100 | School records | ≥ 99% | Monthly |
| Average Provisioning Time | Mean time from school creation to setup_status = 'completed' | Setup progress timestamps | < 10 minutes | Monthly |
| Active Module Distribution | Count of schools per module access (which modules are most subscribed) | Licensed module records | Informational | Quarterly |

---

*End of Prime (PRM) Complete Analysis Pack*
*File: PRM_FRD_Complete_2026-06-29.md*
*Module Knowledge updated: AI_Brain/module-knowledge/PRM_Prime.md*
*Total: 12 REQ | 23 BR | 5 RPT | 8 ENH | 4 Workflows | 3 FSMs | 12 User Stories*
